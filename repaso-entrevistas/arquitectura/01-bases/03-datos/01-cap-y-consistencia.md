# 01 — CAP, PACELC y consistencia

> Qué dice de verdad el teorema CAP y qué se le hace decir, por qué PACELC lo completa, y el
> vocabulario de modelos de consistencia que permite responder con precisión en vez de con
> "eventualmente consistente".
> Asume leído [`01-bases/08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Te preguntan *"¿qué base de datos elegirías?"* y respondes con nombres. La pregunta de
seguimiento llega sola: *"¿y qué pasa cuando se parte la red entre tus dos centros de datos?"*.

Ahí es donde se separa quien ha leído el titular de CAP de quien entiende el problema. Porque
el titular —"elige dos de tres"— es **falso**, y repetirlo te descalifica.

```text
Lo que se dice:  "CAP: elige dos de Consistencia, Disponibilidad y Tolerancia a particiones"
Lo que dice CAP: "cuando hay una partición, elige entre C y A. Sin partición, no eliges nada."
```

La tolerancia a particiones no es una opción: las redes se parten. Lo que eliges es **qué haces
cuando pasa**.

> **Regla importante:** CAP no es un menú de tres platos del que escoges dos. Es una pregunta
> que solo se activa durante una partición, y el resto del tiempo no aplica.

---

## 2. ⚖️ CAP, con precisión

**Qué es.** El teorema de Brewer, formalizado por Gilbert y Lynch: un sistema distribuido no
puede garantizar simultáneamente **consistencia** y **disponibilidad** cuando hay una
**partición** de red.

Las tres letras, con la definición que importa:

```text
C  Consistencia (linealizabilidad) → toda lectura ve la escritura más reciente confirmada.
                                     NO es la C de ACID, que es otra cosa.
A  Disponibilidad                  → toda petición a un nodo vivo recibe respuesta
                                     no errónea. No dice nada sobre latencia.
P  Tolerancia a particiones        → el sistema sigue funcionando aunque los mensajes
                                     entre nodos se pierdan.
```

- **La C de CAP no es la C de ACID.** En ACID, consistencia significa que las restricciones de
  integridad se respetan. En CAP significa linealizabilidad: que el sistema se comporta como si
  hubiera una sola copia del dato. Confundirlas es el error más frecuente y el entrevistador lo
  busca.
- **La A de CAP es binaria y muy estricta**: responder lento sigue siendo "disponible". Por eso
  CAP, por sí solo, no dice nada útil sobre latencia — y de ahí PACELC.

**La elección durante una partición**, que es de lo que trata todo:

```text
CP → ante la partición, rechazo la petición para no dar un dato incorrecto.
     El sistema deja de responder en la parte minoritaria.
AP → ante la partición, respondo con lo que tengo, aunque sea viejo.
     El sistema sigue respondiendo y luego reconcilia.
```

**Cuándo sí razonar en CAP.** Cuando diseñas un sistema con réplicas en más de una zona o
región, o cuando eliges una base de datos distribuida.

**Cuándo no.** En un sistema con una sola base de datos y sin réplicas no hay partición que
razonar, y citar CAP es ruido.

> **Veredicto:** CAP se cita mal el 90 % de las veces. Decir *"la P no se elige; lo que eliges
> es C o A durante la partición"* es de las frases que más rápido te sitúan por encima de la
> media.

---

## 3. 🧱 PACELC: lo que CAP no dice

**Qué es.** La extensión de Daniel Abadi, y es la que de verdad sirve para decidir, porque
cubre el caso normal: cuando **no** hay partición.

```text
if (P) then (A or C)   ← durante una partición: disponibilidad o consistencia
else    (L or C)       ← el resto del tiempo:   latencia o consistencia
```

- **La segunda mitad es la importante**, porque las particiones son raras y el "resto del
  tiempo" es el 99,9 % de la vida del sistema.
- El razonamiento es simple: para que una lectura vea siempre la última escritura, esa escritura
  tuvo que confirmarse en varias réplicas antes de responder. Eso es una ida y vuelta de red **en
  cada escritura**. Consistencia cuesta latencia, siempre, haya partición o no.

Cómo se clasifican los sistemas que se preguntan:

| Sistema | Partición | Normal | Lectura |
|---|---|---|---|
| **Postgres/MySQL** con réplica síncrona | PC | EC | Prioriza consistencia siempre |
| **Postgres/MySQL** con réplica asíncrona | PC | EL | Consistente si se parte; rápido si no |
| **DynamoDB** (por defecto) | PA | EL | Disponible y rápido; lecturas eventuales |
| **DynamoDB** (lectura fuertemente consistente) | PC | EC | Disponible a costa de latencia y coste |
| **Cassandra** (ajustable por consulta) | PA | EL | Configurable con quórums |
| **MongoDB** (por defecto) | PC | EC | Escribe en el primario |

- La fila de DynamoDB aparece dos veces a propósito: **la consistencia no es una propiedad del
  producto, es un parámetro de la consulta**. Saber eso vale más que memorizar la tabla.

> 🧠 **Modelo mental.** CAP responde "¿qué haces si se rompe la red?". PACELC responde "¿qué
> pagas todos los días?". La segunda es la pregunta que de verdad decide tu diseño.

> **Veredicto:** si solo vas a citar un acrónimo, cita PACELC. Demuestra que sabes que la
> consistencia se paga con latencia incluso cuando todo va bien.

---

## 4. 📏 Modelos de consistencia

**Qué es.** El vocabulario preciso para no decir solo "fuerte" o "eventual". De más fuerte a
más débil:

**Linealizabilidad (consistencia fuerte).** El sistema se comporta como si hubiera una sola
copia: toda lectura ve la última escritura confirmada. Es la C de CAP. Cara: exige coordinación
en cada operación.

**Consistencia secuencial.** Todas las operaciones se ven en el mismo orden por todos, pero ese
orden puede no coincidir con el tiempo real.

**Consistencia causal.** Si A causó B, todos ven A antes que B. Las operaciones no relacionadas
pueden verse en cualquier orden. Es el punto dulce de muchos sistemas: barata y suficiente.

**Consistencia eventual.** Si dejan de llegar escrituras, todas las réplicas convergen. No dice
**cuándo**, y esa es la letra pequeña.

Y las cuatro **garantías de sesión**, que son las que de verdad importan para la experiencia de
usuario:

```text
Read-your-writes      → ves tus propias escrituras. Sin esto, creas algo y no aparece.
Monotonic reads       → no ves el tiempo ir hacia atrás entre dos lecturas.
Monotonic writes      → tus escrituras se aplican en el orden en que las hiciste.
Writes-follow-reads   → lo que escribes después de leer se ordena después de lo leído.
```

- **Casi siempre el requisito real es una garantía de sesión, no consistencia fuerte.** El
  usuario no necesita que todo el mundo vea su pedido al instante: necesita verlo **él**.
- Detectar eso convierte un requisito carísimo en uno barato, y es la jugada más rentable del
  capítulo.

> **Veredicto:** "consistencia eventual" sin plazo es una respuesta incompleta. La buena
> incluye el número: *"eventual, con una ventana medida de menos de dos segundos en el p99"*.

---

## 5. ⏱️ El número que falta

**Qué es.** La consistencia eventual no es una propiedad cualitativa: es una **ventana medible**,
y tratarla como tal es lo que separa el diseño del eslogan.

Lo que hay que saber medir y declarar:

| Métrica | Qué es | Dónde se mira |
|---|---|---|
| Lag de replicación | Retraso de la réplica respecto del primario | Métricas del motor |
| Lag del consumidor | Retraso de una proyección respecto del log | Offset contra cabeza |
| Ventana p99 | Cuánto tarda el 99 % de los casos en converger | Medición sintética |

- **Se mide con una sonda sintética**: escribir un valor con marca de tiempo y leerlo desde la
  réplica hasta que aparezca. Ese número es el que llevas a negocio.
- Sin número, la conversación es religiosa. Con número, es una decisión: *"la ventana es de 800
  ms en el p99; ¿el negocio puede vivir con eso en este flujo?"*.

> 🩺 **Diagnóstico.** Ante "los datos no están actualizados", lo primero es distinguir **lag**
> —el sistema funciona, va retrasado— de **divergencia** —el sistema está roto y no converge—.
> La primera se resuelve escalando o esperando; la segunda es un incidente de corrupción.

> **Veredicto:** la ventana de inconsistencia es un número que se mide, se alerta y se acuerda
> con negocio. Quien no la ha medido no sabe si su sistema es eventualmente consistente o
> simplemente está roto.

---

## 6. 🗳️ Quórums

**Qué es.** El mecanismo con el que un sistema replicado ajusta su posición en el espectro sin
cambiar de producto. Con `N` réplicas, `W` confirmaciones para escribir y `R` para leer:

```text
Si W + R > N  → toda lectura solapa con la última escritura → consistencia fuerte
Si W + R ≤ N  → puede que no solapen              → consistencia eventual
```

Los tres ajustes que se preguntan, con `N = 3`:

```text
W=3, R=1  → escritura lenta, lectura rápida y consistente. Bueno si lees mucho más de lo que escribes.
W=1, R=3  → escritura rápida, lectura lenta. Raro.
W=2, R=2  → equilibrio. El quórum clásico.
W=1, R=1  → máxima velocidad y disponibilidad, consistencia eventual.
```

- Es lo que hace Cassandra configurable **por consulta**: la misma tabla puede servir una lectura
  crítica con quórum y una analítica con `R=1`.
- DynamoDB expone la misma idea con un interruptor: lectura eventual (barata, rápida) contra
  fuertemente consistente (el doble de coste y más latencia).

**Cuándo sí.** Cuando el sistema lo permite y distintos flujos tienen requisitos distintos.

**Cuándo no.** Cuando se configura una vez para todo el sistema: ahí pierdes la ventaja y solo
te queda el coste del peor caso.

> **Veredicto:** el quórum convierte la consistencia en un dial por consulta en vez de una
> propiedad del sistema. Responder *"depende de la consulta, no de la base de datos"* es la
> respuesta madura.

---

## 7. 🧭 Cómo se elige

```text
¿Qué pasa si esta lectura devuelve un dato de hace 2 segundos?
    Nada grave (catálogo, recomendaciones, historial) → eventual. Mide la ventana y alerta.
    El usuario ve mal SU dato                          → read-your-writes, no consistencia fuerte
    Se toma una decisión de dinero                     → fuerte, y asume la latencia

¿Es un requisito de sesión o de sistema?
    "que yo vea lo mío"           → garantía de sesión. Barato.
    "que TODOS lo vean a la vez"  → linealizabilidad. Caro, y casi nunca es el requisito real.

¿El motor permite ajustar por consulta?
    Sí  → quórum o flag de consistencia, distinto por flujo
    No  → la elección es del sistema entero y hay que declararla

Y en cualquier caso:
    → mide la ventana p99 y llévala a negocio. Sin número no hay decisión, hay opinión.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "CAP: elige dos de tres" | La P no se elige; eliges entre C y A **durante** la partición |
| "La C de CAP es la C de ACID" | CAP es linealizabilidad; ACID es integridad de restricciones |
| "Somos AP" o "somos CP" | Depende de la consulta y de la configuración, no del producto |
| "Eventualmente consistente" | ¿En cuánto tiempo? Sin número es un eslogan |
| "Necesitamos consistencia fuerte" | Casi siempre el requisito real es read-your-writes |
| "NoSQL es AP y SQL es CP" | Postgres con réplica asíncrona sirve lecturas obsoletas; DynamoDB tiene lectura fuerte |
| "La A de CAP incluye responder rápido" | No: responder lento sigue siendo disponible. Por eso existe PACELC |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 5 (replicación), capítulo 9 (consistencia y consenso) y la sección "The Unhelpful CAP
  Theorem". **Es el libro de todo este bloque**; si solo lees uno, este.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). Capítulo 14:
  cómo se traduce la elección de consistencia a fronteras de agregado y de servicio.
- **Libro** — Alex Petrov, *Database Internals* (O'Reilly, 2019). Parte II: replicación, quórums
  y consenso, con el detalle de cómo lo implementan los motores.
- [Jepsen — Consistency Models](https://jepsen.io/consistency): el mapa de modelos de
  consistencia con sus relaciones, y la referencia que usa la industria.
- [DynamoDB — Read consistency](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html):
  el ejemplo canónico de consistencia como parámetro de la consulta, con su coste.
- [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html):
  el contraste con la C de ACID, que se desarrolla en [`02`](02-transacciones-y-bloqueo.md).
- **Video** — GOTO Conferences y Devoxx, charlas de Martin Kleppmann sobre CAP y modelos de
  consistencia. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué significan las tres letras de CAP? 🟢
2. ¿Qué añade PACELC a CAP? 🟢
3. Nombra las cuatro garantías de sesión. 🟢
4. ¿Qué es la consistencia causal? 🟢
5. ¿Qué es un quórum y qué condición da consistencia fuerte? 🟢
6. ¿Por qué "elige dos de tres" es una lectura incorrecta de CAP? 🟡
7. ¿En qué se diferencia la C de CAP de la C de ACID? 🟡
8. ¿Qué significa exactamente la A de CAP? 🟡
9. ¿Por qué la consistencia cuesta latencia aunque no haya partición? 🟡
10. ¿Qué es read-your-writes y por qué suele ser el requisito real? 🟡
11. ¿Qué diferencia hay entre lag y divergencia? 🟡
12. ¿Por qué "somos AP" es una afirmación imprecisa? 🟠
13. Con `N=3`, ¿qué combinaciones de `W` y `R` dan consistencia fuerte? 🟠
14. ¿Por qué DynamoDB aparece dos veces en una tabla de clasificación PACELC? 🟠
15. ¿Cómo se mide la ventana de consistencia eventual? 🟠
16. ¿Por qué "eventualmente consistente" sin plazo es una respuesta incompleta? 🟠
17. ¿Cuándo citar CAP es ruido? 🟠
18. ¿Qué preguntas para decidir si una lectura puede ser eventual? 🟠
19. ¿Por qué el quórum es mejor entendido como un dial por consulta? 🟠
20. Te dicen "necesitamos consistencia fuerte en todo el sistema". ¿Qué
    preguntas y qué propones? 🔴
21. Diseña la estrategia de consistencia de un e-commerce: catálogo, carrito,
    stock, pedido y pago. Justifica cada elección. 🔴
22. "Los datos no están actualizados." Describe cómo investigas y qué te dice
    cada hallazgo. 🔴
23. Un banco pide que el saldo sea siempre exacto y que la app nunca falle.
    Explica el conflicto y propón una salida. 🔴

---

**Siguiente:** [`02` — Transacciones y bloqueo](02-transacciones-y-bloqueo.md) ·
**Relacionado:** [`05` — Réplicas y lag](05-replicas-y-lag.md)
