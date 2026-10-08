# 07 — Event sourcing

> Guardar los hechos en vez del estado. Qué compra de verdad, qué cuesta —y cuesta mucho—,
> cómo se versionan los eventos cuando el negocio cambia, y por qué el veredicto honesto es
> "casi nunca".
> Asume leído [`06` — Outbox y CDC](06-outbox-y-cdc.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Una cuenta tiene saldo 1.000. Alguien pregunta por qué. Miras la tabla:

```text
cuentas
 id    saldo    actualizado_en
 4711  1000.00  2026-09-15 14:22
```

No lo sabes. La fila anterior se sobrescribió, y con ella la historia: no sabes si hubo un
ingreso de 1.000, o diez de 100, o un ingreso de 5.000 y cuatro reintegros. **Guardaste el
resultado y tiraste los hechos.**

Y eso produce tres problemas concretos:

- **Auditoría imposible sin un log paralelo** que alguien tiene que acordarse de escribir.
- **Preguntas nuevas sin respuesta retroactiva.** Si mañana negocio quiere saber el saldo
  medio de agosto, esa información ya no existe.
- **Bugs irreparables.** Si el cálculo del saldo tenía un error, no puedes recalcular:
  no tienes de dónde.

> **Regla:** un `UPDATE` es una pérdida de información deliberada. La mayoría de las veces
> es la decisión correcta, y conviene saber que la estás tomando.

---

## 2. 📜 Qué es event sourcing

**Qué es.** El estado no se guarda: se **deriva**. Lo que se persiste es la secuencia
inmutable de eventos, y el estado actual es el resultado de aplicarlos en orden.

```text
Tradicional:  UPDATE cuentas SET saldo = 1000 WHERE id = 4711

Event sourcing:
  INSERT Depositado{cuenta:4711, importe:1500, v:1}
  INSERT Retirado  {cuenta:4711, importe: 700, v:2}
  INSERT Depositado{cuenta:4711, importe: 200, v:3}

  saldo = fold(eventos)  →  1500 - 700 + 200 = 1000
```

- **El log es la fuente de verdad.** La tabla de saldos, si existe, es una proyección
  derivada que se puede borrar y reconstruir.
- **Los eventos son inmutables.** Corregir no es editar: es añadir un evento de corrección.
  Es la misma lógica que el asiento contable.
- `v:1, v:2, v:3` es la **versión del agregado**: da orden, y da bloqueo optimista al
  insertar (si ya existe la versión 3, alguien te ganó).

**Lo que hay que distinguir de inmediato**, porque es la confusión más frecuente:

```text
Publicar eventos al broker  ≠  event sourcing
```

Publicar eventos es integración: tu estado sigue en una tabla y además avisas. Event
sourcing es **persistencia**: no hay tabla de estado que valga. Casi todos los sistemas que
dicen hacer event sourcing hacen lo primero, y está bien — pero no es lo mismo.

> **Veredicto:** event sourcing responde "¿cómo llegamos aquí?", no "¿dónde estamos?". Si
> nadie hace la primera pregunta, estás pagando por una respuesta que nadie quiere.

---

## 3. 📸 Snapshots

**Qué es.** Reconstruir un agregado con 200.000 eventos leyéndolos todos es inviable. El
snapshot es una foto del estado en una versión concreta; se carga la foto y se aplican
solo los eventos posteriores.

```text
cargar(4711):
   snapshot v:150.000  →  aplicar eventos 150.001..150.037  →  estado actual
```

- El snapshot es **caché, no fuente de verdad**: se puede borrar y regenerar desde los
  eventos. Si alguna vez no se puede, el diseño está roto.
- La frecuencia se calibra: cada N eventos o cada cierto tiempo, según cuánto tarde el
  `fold`.
- **Los snapshots también se versionan.** Si cambia la forma del estado, los viejos dejan
  de poder deserializarse y hay que regenerarlos.

**Cuándo sí.** Cuando los agregados acumulan cientos o miles de eventos.

**Cuándo no.** Cuando un agregado tiene veinte eventos en toda su vida: el `fold` es
instantáneo y el snapshot es complejidad gratuita.

> **Veredicto:** el snapshot es la primera grieta en la elegancia del patrón. Llega pronto,
> y con él una caché que mantener, invalidar y versionar.

---

## 4. 🔄 Versionado de eventos: el problema que hunde proyectos

**Qué es.** El evento que escribiste en 2021 sigue ahí en 2026, y tu código de hoy tiene
que poder leerlo. **Los eventos son para siempre**, y esa frase es toda la dificultad del
patrón.

Las estrategias, de menos a más invasiva:

**1. Solo cambios compatibles.** Añadir campos opcionales, nunca quitar ni renombrar. Es lo
que se intenta primero y aguanta menos de lo que parece.

**2. Upcasting.** Una función que convierte `PedidoCreadoV1` en `V2` al leer. El evento
almacenado no se toca; se traduce en memoria.

```java
// El evento v1 no tenía moneda; asumimos EUR, que era lo único que había en 2021
PedidoCreadoV2 upcast(PedidoCreadoV1 v1) {
    return new PedidoCreadoV2(v1.id(), v1.importe(), "EUR");
}
```

- Funciona bien y **se acumula**: al cabo de tres años tienes cadenas `V1→V2→V3→V4` que
  nadie entiende y nadie se atreve a borrar.
- El valor por defecto que inventas —`"EUR"`— es una decisión de negocio escondida en
  código de infraestructura. Hay que documentarla.

**3. Reescribir el log (copy-transform).** Se crea un log nuevo transformando el viejo. Es
la opción limpia y **rompe la inmutabilidad**, que era media gracia del patrón. Además, si
otros sistemas guardaron referencias a versiones concretas, se rompen.

> ⚠️ **Advertencia.** Esta sección es la pregunta de seguimiento que hunde a quien recitó
> el patrón: *"¿y cuando el negocio cambia el significado de un evento?"*. La respuesta
> honesta es que no hay salida barata, y decirlo vale más que improvisar una.

> **Veredicto:** el versionado de eventos es la deuda que el patrón te obliga a asumir el
> primer día y a pagar durante años. Es la razón número uno por la que los proyectos de
> event sourcing se abandonan.

---

## 5. 🔍 Consultar: por qué arrastra a CQRS

**Qué es.** El log responde muy bien a *"dame el agregado 4711"* y fatal a cualquier otra
cosa. *"Todas las cuentas con saldo negativo"* obliga a reconstruir todas las cuentas.

Por eso event sourcing **siempre** viene con proyecciones: consumidores del log que
mantienen vistas de lectura en la forma que cada consulta necesita.

```text
log de eventos (verdad) ──► proyección "saldos"        (tabla SQL)
                       ├──► proyección "movimientos"   (índice de búsqueda)
                       └──► proyección "analítica"     (almacén columnar)
```

Y con las proyecciones llegan sus propios problemas:

- **Consistencia eventual visible.** Depositas y tu saldo no cambia todavía. Hay que
  decidir qué ve el usuario en esa ventana — y decidirlo con negocio.
- **Reconstruir tarda.** Rehacer una proyección de 500 millones de eventos son horas. Hay
  que diseñar cómo se hace sin parar el sistema: proyección nueva en paralelo y cambio
  atómico al terminar.
- **Cada consulta nueva puede exigir una proyección nueva**, con su código, su despliegue
  y su reconstrucción.

Esto se desarrolla en [`08` — Proyecciones y streaming](08-proyecciones-y-streaming.md) y
en [`03-datos/06` — CQRS](../03-datos/).

> **Veredicto:** event sourcing sin CQRS no funciona. Cuando evalúes el coste del patrón,
> suma el de CQRS entero: no son dos decisiones, es una.

---

## 6. ⚖️ Qué compra y qué cuesta

**Lo que compra**, y hay que reconocer que cuando aplica, no hay sustituto:

```text
Auditoría perfecta por construcción   → cada cambio es un hecho con su causa y su momento
Viaje en el tiempo                    → el estado en cualquier instante del pasado
Preguntas retroactivas                → una proyección nueva responde sobre todo el histórico
Depuración real                       → reproduces la secuencia exacta que produjo el bug
Modelo alineado con el negocio        → en contabilidad y trading, el hecho ES el dominio
```

**Lo que cuesta:**

```text
Versionado de eventos para siempre    → §4, y es el que mata proyectos
Snapshots                             → caché que mantener, invalidar y versionar
CQRS obligatorio                      → §5, con sus proyecciones y su reconstrucción
Consistencia eventual visible         → decisión de negocio en cada pantalla
Borrado imposible                     → el log es inmutable, y el RGPD exige poder borrar
Curva de entrada brutal               → cada persona nueva tarda semanas
Tooling escaso                        → no hay equivalente a Spring Data para esto
```

> ⚠️ **Advertencia.** El **derecho de supresión** del RGPD contra un log inmutable es un
> conflicto real y hay que tener la respuesta: cifrado por sujeto y destrucción de la clave
> —*crypto-shredding*—, que deja el evento ilegible sin borrarlo. Mencionarlo en una
> entrevista de banca es de las cosas que más impresionan.

---

## 7. 🧭 Cómo se elige

```text
¿El negocio piensa en hechos, no en estado? (contabilidad, trading, seguros, expedientes)
    → Candidato real. En estos dominios el patrón no se impone: se descubre.

¿Alguien paga por saber CÓMO se llegó al estado actual?
    ¿Hay una obligación regulatoria de trazabilidad? → sí, candidato
    ¿Solo "estaría bien tenerlo"?                    → no. Un log de auditoría basta.

¿Puedes asumir el coste completo?
    versionado para siempre + CQRS + consistencia eventual + curva de entrada
    Si dudas en alguno → no.

¿Y si solo necesito auditoría?
    → Tabla de auditoría, o CDC, o eventos publicados con outbox. El 95 % de los casos.

¿Y si solo necesito lecturas rápidas?
    → CQRS sin event sourcing. Son separables, y casi siempre conviene separarlos.
```

> **Regla de entrevista:** *"lo aplicaría al agregado `Cuenta`, que es núcleo y tiene
> obligación regulatoria de trazabilidad, y dejaría el resto del sistema en CRUD"*. Event
> sourcing selectivo, por agregado, es la respuesta madura. Todo o nada es la respuesta de
> quien no lo ha mantenido.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Publicamos eventos, hacemos event sourcing" | Eso es integración; event sourcing es que el log **sea** la fuente de verdad |
| "Event sourcing da auditoría gratis" | La da, y a cambio de versionado eterno, CQRS y consistencia eventual |
| "El snapshot es la fuente de verdad" | Es caché: debe poder borrarse y regenerarse desde los eventos |
| "Corrijo el evento mal escrito" | Son inmutables: se añade un evento de corrección |
| "Con event sourcing consulto más rápido" | Consulta **peor**: por eso arrastra CQRS obligatoriamente |
| "El RGPD no aplica a un log interno" | Sí aplica; la salida es crypto-shredding, no borrar |
| "Es todo o nada" | Se aplica por agregado; lo maduro es usarlo solo donde se paga |

---

## 📚 Para profundizar

- **Libro** — Vaughn Vernon, *Implementing Domain-Driven Design* (Addison-Wesley, 2013).
  Apéndice A: event sourcing aplicado a agregados, con el problema del versionado.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 6
  completo: event sourcing, snapshots, versionado y su relación obligada con CQRS. **Es el
  más aplicable de los tres.**
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11: por qué un log inmutable es una fuente de verdad superior, y qué cuesta.
- Martin Fowler — [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html): la
  ficha original, con la distinción frente a publicar eventos.
- [microservices.io — Event sourcing](https://microservices.io/patterns/data/event-sourcing.html):
  las fuerzas y los contras enfrentados, incluido el problema del esquema.
- [microservices.io — CQRS](https://microservices.io/patterns/data/cqrs.html): por qué
  event sourcing lo exige.
- **Video** — GOTO Conferences y Domain-Driven Design Europe, charlas de Greg Young sobre
  event sourcing —es quien acuñó el término— y las de quienes lo han retirado de
  producción, que son las más útiles. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es event sourcing? 🟢
2. ¿Qué es un snapshot y qué relación tiene con el log? 🟢
3. ¿Qué es el upcasting de eventos? 🟢
4. Nombra tres cosas que compra event sourcing. 🟢
5. ¿Qué diferencia hay entre publicar eventos y hacer event sourcing? 🟡
6. ¿Cómo se corrige un evento escrito con un dato mal? 🟡
7. ¿Para qué sirve la versión del agregado en cada evento? 🟡
8. ¿Por qué event sourcing arrastra CQRS obligatoriamente? 🟡
9. ¿Qué tres estrategias hay para versionar eventos? 🟡
10. ¿Por qué el snapshot no puede ser la fuente de verdad? 🟡
11. ¿Qué problema tiene el derecho de supresión del RGPD aquí? 🟠
12. ¿Qué es crypto-shredding y qué problema resuelve? 🟠
13. ¿Por qué el upcasting se degrada con los años? 🟠
14. ¿Qué peligro tiene reescribir el log para versionar? 🟠
15. ¿Qué pasa cuando hay que reconstruir una proyección de 500 millones de
    eventos? 🟠
16. ¿Por qué "un `UPDATE` es una pérdida de información deliberada"? 🟠
17. ¿En qué dominios el patrón se descubre en vez de imponerse, y por qué? 🟠
18. ¿Cuándo basta con un log de auditoría en vez de event sourcing? 🟠
19. ¿Qué significa aplicar event sourcing "selectivamente" y por qué es la
    respuesta madura? 🟠
20. Diseña el agregado `Cuenta` con event sourcing: eventos, reconstrucción,
    snapshots, concurrencia y proyecciones. 🔴
21. Negocio cambia el significado de un evento que lleva tres años escribiéndose.
    Describe las opciones y elige una. 🔴
22. Te proponen event sourcing para todo un sistema nuevo. ¿Qué preguntas y qué
    recomiendas? 🔴
23. Un cliente ejerce su derecho de supresión sobre datos que están en 40.000
    eventos inmutables. ¿Qué haces? 🔴

---

**Anterior:** [`06` — Outbox y CDC](06-outbox-y-cdc.md) ·
**Siguiente:** [`08` — Proyecciones y streaming](08-proyecciones-y-streaming.md) ·
**Relacionado:** [`03-datos`](../03-datos/)
