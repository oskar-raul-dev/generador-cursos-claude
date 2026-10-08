# 05 — Réplicas y lag

> Cómo se escalan las lecturas sin partir los datos: replicación síncrona contra asíncrona, el
> lag y lo que rompe, el enrutamiento de lecturas, y la conmutación por error con su pérdida de
> datos asociada.
> Asume leído [`04` — Sharding y particionado](04-sharding-y-particionado.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

El sistema lee mucho más de lo que escribe —la proporción típica es de 10 a 1 o peor— y la base
de datos va justa. La solución obvia es añadir réplicas de lectura, y funciona. Pero introduce
un problema que no existía:

```text
t=0  el usuario actualiza su perfil   → escribe en el PRIMARIO
t=1  el usuario recarga la página     → lee de una RÉPLICA
t=1  la réplica todavía no recibió el cambio
     → el usuario ve su nombre viejo y piensa que no se guardó
```

No es un bug de código: es el comportamiento correcto de un sistema replicado. Y la solución no
es "quitar las réplicas", es **decidir qué lecturas pueden ir a una réplica**.

> **Regla:** replicar es gratis para el 90 % de las lecturas y veneno para el 10 % restante. Todo
> el capítulo es cómo separar los dos grupos.

---

## 2. ⚙️ Síncrona contra asíncrona

**Qué es.** Cuándo el primario considera confirmada una escritura.

```text
Asíncrona  → el primario confirma al cliente y replica después.
             Rápido. Si el primario cae ahora, esa escritura SE PIERDE.

Síncrona   → el primario espera a que la réplica confirme antes de responder.
             Sin pérdida. Cada escritura paga una ida y vuelta de red.

Semisíncrona → espera a UNA réplica de N. El compromiso habitual.
```

- **La asíncrona es el valor por defecto** en Postgres, MySQL y la mayoría de los motores, y casi
  nadie lo comprueba.
- **Es también la letra pequeña de la D de ACID** de [`02` §2](02-transacciones-y-bloqueo.md#2--acid-con-precisión):
  un commit confirmado puede perderse si el primario muere antes de replicar.
- La síncrona entre zonas de disponibilidad cuesta ~1 ms y suele ser asumible. Entre regiones
  cuesta decenas de milisegundos **en cada escritura** y casi nunca lo es.

**Cuándo sí síncrona.** Cuando el RPO debe ser cero: dinero, contabilidad, registro legal.

**Cuándo no.** Entre regiones lejanas, y en cualquier sistema donde la latencia de escritura sea
un requisito. Ahí, asíncrona y RPO declarado en segundos.

> **Veredicto:** la elección síncrona/asíncrona **es** la elección de RPO de
> [`01-bases/10`](../01-bases/10-alta-disponibilidad-y-escalado.md), expresada en la
> configuración del motor. Y casi nadie sabe cuál tiene su sistema.

---

## 3. ⏱️ El lag y lo que rompe

**Qué es.** El retraso de una réplica respecto del primario. Se mide en segundos o en bytes de
log pendientes, y **no es constante**: sube con la carga de escritura, con una migración de
esquema, con un backup, o si la réplica tiene menos recursos que el primario.

Lo que rompe, en orden de frecuencia:

```text
Read-your-writes     → escribes y no lo ves. El caso del §1 y el que más se nota.
Monotonic reads      → dos lecturas seguidas van a réplicas distintas y el tiempo
                       parece ir hacia atrás: el dato aparece y desaparece.
Writes-follow-reads  → lees un estado, decides sobre él, y escribes basándote en algo obsoleto.
```

- **La segunda es la más desconcertante para el usuario** y la más difícil de reproducir: solo
  pasa si el balanceador reparte entre réplicas con lag distinto.
- Son exactamente las garantías de sesión de
  [`01` §4](01-cap-y-consistencia.md#4--modelos-de-consistencia), y aquí es donde se rompen en la
  práctica.

> 🩺 **Diagnóstico.** El lag se vigila con dos métricas: la del propio motor —bytes o segundos
> pendientes— y una **sonda sintética** que escribe un valor con marca de tiempo y lo lee de cada
> réplica hasta verlo. La segunda es la que da el número que llevas a negocio.

> **Veredicto:** el lag no es un fallo, es una propiedad. Lo que sí es un fallo es no medirlo, no
> alertar sobre él y no haber decidido qué lecturas lo toleran.

---

## 4. 🚦 Enrutar las lecturas

**Qué es.** El mecanismo que decide si una consulta va al primario o a una réplica. Es la
decisión de diseño real del capítulo.

Las estrategias, de más simple a más precisa:

**1. Por tipo de operación.** Escrituras al primario, lecturas a réplica. Simple y **rompe
read-your-writes**, así que por sí sola no basta.

**2. Por criticidad declarada.** El desarrollador marca la consulta: `@Transactional(readOnly =
true)` va a réplica, el resto al primario. En Spring se implementa con un `DataSource` que enruta
según ese flag.

- Es el más usado y el que mejor relación coste/beneficio tiene.
- Su riesgo: `readOnly = true` se pone por costumbre y acaba en consultas que no lo toleran.

**3. Pegajosa tras escribir.** Durante N segundos después de que un usuario escriba, sus lecturas
van al primario. Resuelve read-your-writes con muy poco esfuerzo.

- Se implementa con una marca en la sesión o en el token. Es la solución práctica más común.

**4. Por token de versión.** La escritura devuelve una posición del log; la lectura la lleva y se
enruta a una réplica que ya la haya alcanzado, o al primario.

- Es la única con garantía real, y la más cara de implementar.

> 💡 **Truco.** La combinación que resuelve el 95 % de los casos y casi nadie propone junta:
> **`readOnly` para enrutar, más pegajosa al primario durante unos segundos tras escribir**. Es
> barata, cubre read-your-writes y no requiere propagar tokens.

> **Veredicto:** enrutar no es un detalle de infraestructura: es la decisión que determina qué garantías
> ve el usuario. Y la combinación barata —`readOnly` más pegajosa— cubre casi todo.

---
## 5. 🔁 Conmutación por error

**Qué es.** Promover una réplica a primario cuando este cae. Y es donde aparecen los problemas
que nadie ensaya.

```text
1. Detectar la caída        → ¿es una caída o una partición de red? No siempre se distingue.
2. Elegir la nueva primaria → la que menos lag tenga. Con consenso, no a dedo.
3. Reconfigurar el resto    → las demás réplicas deben seguir a la nueva.
4. Redirigir a los clientes → DNS, proxy o el driver. Es el paso que más tarda.
```

Los tres problemas clásicos:

- **Pérdida de datos.** Con replicación asíncrona, lo que el primario confirmó y no replicó **se
  pierde**. Ese es tu RPO real, y hay que saber su número.
- **Cerebro dividido (split-brain).** Si el primario no estaba muerto sino aislado, hay dos
  primarios aceptando escrituras. Se evita con quórum y con *fencing*: el viejo primario debe ser
  incapaz de seguir escribiendo.
- **El tiempo de conmutación.** Detectar tarda, promover tarda, y redirigir clientes tarda más de
  lo que la gente cree —la caché DNS es el sospechoso habitual—. Ese total es tu RTO real.

> ⚠️ **Advertencia.** La pregunta que desmonta cualquier plan: *"¿cuándo fue la última vez que
> ensayaron una conmutación?"*. Un mecanismo de failover que nunca se ha ejecutado no está
> verificado, exactamente igual que un backup que nunca se restauró.

> **Veredicto:** la conmutación automática cambia caídas largas por incidentes raros y confusos.
> Es la decisión correcta por encima de cierto RTO, y exige ensayo periódico para serlo.

---

## 6. 🌍 Multi-primario

**Qué es.** Más de un nodo acepta escrituras. Suena a la solución a todo y es la fuente de los
peores problemas de datos.

**El problema no es la infraestructura, es el conflicto.** Si dos primarios aceptan una escritura
sobre el mismo registro, alguien tiene que decidir cuál gana:

```text
Última escritura gana (LWW)  → simple, y PIERDE datos en silencio. Además depende
                               de relojes que no están sincronizados entre máquinas.
Resolución por aplicación    → guardas ambas versiones y el dominio decide. Correcto y caro.
CRDT                         → estructuras que convergen por construcción. Solo para
                               contadores, conjuntos y pocos casos más.
```

- **En dominios con dinero no hay política aceptable**: "gana la última" significa perder un
  movimiento.
- La salida en banca es **particionar por entidad**: cada cuenta tiene una región dueña que
  acepta sus escrituras, y la otra sirve lecturas. Es activo-activo a nivel de plataforma y
  activo-pasivo a nivel de registro, y elimina el conflicto por diseño.

**Cuándo sí.** Escrituras naturalmente separadas por región o por tenant, donde el mismo registro
nunca se escribe desde dos sitios.

**Cuándo no.** Cuando el mismo dato puede escribirse desde dos primarios. Ahí el conflicto es
inevitable y ninguna política lo resuelve sin perder información.

> **Veredicto:** multi-primario no es una decisión de infraestructura, es una decisión sobre qué
> hacer cuando dos verdades se contradicen. Si no tienes respuesta a eso, no tienes diseño.

---

## 7. 🧭 Cómo se elige

```text
¿El cuello es de lectura?
    → Réplicas. Es la respuesta y es barata. (Si es de escritura, cap. 04.)

¿Qué RPO necesitas?
    Cero, y es dinero        → replicación síncrona o semisíncrona dentro de la región
    Segundos son aceptables  → asíncrona, y DECLARA el número
    Entre regiones           → asíncrona casi siempre; síncrona cuesta latencia en cada escritura

¿Cómo enruto las lecturas?
    → readOnly para enrutar
    + pegajosa al primario unos segundos tras escribir (cubre read-your-writes)
    + al primario siempre las consultas que deciden sobre dinero
    + token de versión SOLO en el flujo donde la garantía sea un requisito

¿Conmutación automática?
    ¿RTO en minutos es aceptable? → manual, con procedimiento escrito y ensayado
    ¿RTO en segundos?             → automática, con quórum y fencing, y ENSÁYALA

¿Multi-primario?
    → Solo si el mismo registro nunca se escribe desde dos sitios.
      Si puede pasar, particiona por entidad y da una región dueña a cada una.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Añadimos réplicas y escalamos" | Escalas **lecturas**; las escrituras siguen yendo a un nodo |
| "Los datos están replicados, no se pierden" | Con réplica asíncrona, lo no replicado se pierde al caer el primario |
| "El lag es constante" | Sube con la carga, con migraciones y con backups |
| "`readOnly = true` es seguro" | Enruta a réplica: si esa consulta no tolera lag, has introducido un bug |
| "Multi-primario da alta disponibilidad" | Y un problema de conflictos que la infraestructura no resuelve |
| "Tenemos failover automático" | ¿Cuándo lo ensayaron? Sin ensayo, no está verificado |
| "El failover no pierde datos" | Solo con replicación síncrona; con asíncrona ese es tu RPO |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 5 completo: replicación, lag, garantías de sesión, multi-primario y resolución de
  conflictos. **El de este capítulo, y probablemente el mejor del libro.**
- **Libro** — Alex Petrov, *Database Internals* (O'Reilly, 2019). Parte II: replicación y
  consenso por dentro, incluido el fencing.
- **Libro** — Betsy Beyer et al., *Site Reliability Engineering* (O'Reilly, 2016). Capítulos
  sobre gestión de incidentes y ensayo de procedimientos: por qué un failover no ensayado no
  cuenta.
- [PostgreSQL — High Availability, Load Balancing, and Replication](https://www.postgresql.org/docs/current/high-availability.html):
  los modos de replicación con sus garantías exactas.
- [Jepsen — Consistency Models](https://jepsen.io/consistency): dónde encajan las garantías de
  sesión que el lag rompe.
- [Google SRE Book — Embracing Risk](https://sre.google/sre-book/embracing-risk/): el marco para
  decidir el RPO y el RTO con números en vez de con opiniones.
- **Tutorial** — Baeldung, «Spring Boot Multiple Databases»: cómo se implementa el enrutamiento
  de lecturas con varios `DataSource`.
- **Video** — GOTO Conferences, charlas de Martin Kleppmann sobre replicación y conflictos.
  Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué diferencia hay entre replicación síncrona y asíncrona? 🟢
2. ¿Qué es el lag de replicación? 🟢
3. ¿Qué es la replicación semisíncrona? 🟢
4. Nombra cuatro estrategias para enrutar lecturas. 🟢
5. ¿Qué es el cerebro dividido? 🟢
6. ¿Qué garantía de sesión rompe el lag más visiblemente? 🟡
7. ¿Por qué el lag no es constante? 🟡
8. ¿Qué relación hay entre replicación asíncrona y la D de ACID? 🟡
9. ¿Qué es la lectura pegajosa al primario y qué resuelve? 🟡
10. ¿Por qué `readOnly = true` puede introducir un bug? 🟡
11. ¿Qué son los CRDT y para qué sirven? 🟡
12. ¿Cómo se mide el lag de forma que sirva para hablar con negocio? 🟡
13. ¿Qué se pierde exactamente en una conmutación con réplica asíncrona? 🟠
14. ¿Cómo se evita el cerebro dividido? 🟠
15. ¿Por qué monotonic reads es la rotura más desconcertante? 🟠
16. ¿Cuál es el paso más lento de una conmutación y por qué? 🟠
17. ¿Por qué "gana la última escritura" pierde datos en silencio? 🟠
18. ¿Cuál es la salida al multi-primario en banca? 🟠
19. ¿Qué combinación de enrutamiento resuelve el 95 % de los casos? 🟠
20. ¿Qué pregunta desmonta un plan de conmutación por error? 🟠
21. Diseña el enrutamiento de lecturas de un e-commerce: qué va al primario,
    qué a réplica, y cómo garantizas read-your-writes. 🔴
22. Tras añadir réplicas, los usuarios reportan que sus cambios "a veces no se
    guardan". Diagnostica y propón dos soluciones con su coste. 🔴
23. Te piden multi-primario entre dos regiones para una app de mensajería.
    ¿Funciona aquí? Justifica y di qué cambiarías si fuera un banco. 🔴

---

**Anterior:** [`04` — Sharding y particionado](04-sharding-y-particionado.md) ·
**Siguiente:** [`06` — CQRS](06-cqrs.md) ·
**Relacionado:** [`01` — CAP y consistencia](01-cap-y-consistencia.md)
