# 08 — Proyecciones y streaming

> Cómo se construye y se mantiene una vista de lectura alimentada por eventos, cómo se
> reconstruye sin parar el sistema, y qué aporta el procesamiento de flujos frente a un
> consumidor normal. Cierra el bloque uniendo lo de los siete capítulos anteriores.
> Asume leído [`07` — Event sourcing](07-event-sourcing.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tienes el log de eventos y alguien pide: *"lista de pedidos del cliente, con el nombre del
producto, el estado del envío y si la factura está pagada"*. Esos datos viven en cuatro
servicios distintos y ninguno tiene la consulta entera.

Las salidas obvias fallan las dos:

- **Composición de API**: el gateway llama a los cuatro y junta. Funciona con pocos
  elementos y se derrumba al paginar u ordenar por un campo de otro servicio — no puedes
  ordenar sin traerlo todo.
- **Consultar el log**: el log responde por agregado, no por criterio. Buscar "todos los
  pedidos pendientes" obliga a reconstruirlos todos.

La respuesta es una **proyección**: un consumidor que mantiene una tabla con exactamente la
forma que esa consulta necesita.

> **Regla:** en un sistema por eventos, las lecturas no se resuelven consultando: se
> resuelven **manteniendo la respuesta ya calculada**.

---

## 2. 🪞 Qué es una proyección

**Qué es.** Un consumidor de eventos que mantiene una vista derivada, optimizada para una
consulta concreta. No tiene lógica de negocio: **traduce eventos en filas**.

```java
@KafkaListener(topics = "pedidos")
void alRecibir(PedidoConfirmado e) {
    vista.upsert(new FilaPedido(e.pedidoId(), e.clienteId(), "CONFIRMADO", e.total()));
}
```

- Es un `upsert`, no un `insert`: la entrega es at-least-once y el mismo evento llegará dos
  veces. **Escribir el estado final en vez de incrementar** hace la proyección idempotente
  casi gratis.
- No valida ni decide: si la proyección tiene un `if` de negocio, esa regla está duplicada
  y divergirá del agregado.

**Las tres propiedades que la definen:**

```text
Derivada    → se puede borrar entera y reconstruir desde los eventos
Desechable  → no es fuente de verdad; si diverge, se rehace
Especializada → una por consulta. Duplicar datos entre proyecciones es lo normal.
```

- La tercera choca con el instinto relacional. Aquí **la normalización no es virtud**: cada
  proyección guarda lo suyo, aunque se repita.

**Cuándo sí.** Consultas frecuentes que cruzan agregados o contextos, o que necesitan una
forma que el modelo de escritura no da.

**Cuándo no.** Consultas raras sobre un solo agregado: componer o consultar directo es más
barato que mantener una proyección viva.

> **Veredicto:** una proyección es una caché con contrato. Lo que la distingue de una caché
> normal es que sabes **exactamente** cómo regenerarla, y eso cambia todo lo demás.

---

## 3. ⏳ Consistencia eventual: lo que ve el usuario

**Qué es.** Entre que el comando se acepta y la proyección se actualiza pasa tiempo:
milisegundos normalmente, minutos si hay lag. Y el usuario que acaba de crear algo hace
`GET` y no lo encuentra.

Es el problema práctico número uno de este patrón, y las salidas son cuatro:

```text
1. Devolver el resultado en la respuesta del comando
   → el POST devuelve el objeto creado; la UI lo pinta sin consultar. La más simple.

2. Leer del modelo de escritura para "lo mío"
   → mis propios datos recién creados se leen del agregado, no de la proyección.

3. Token de versión
   → el comando devuelve una versión; la consulta espera a que la proyección la alcance.
     Correcto y el más caro de implementar.

4. Decírselo al usuario
   → "procesando, te avisamos". Honesto, y a veces lo que el negocio prefiere.
```

- La 1 resuelve el 80 % de los casos y casi nadie la propone primero.
- La 3 es la única que da garantía real de *read-your-writes*, y requiere que la proyección
  exponga por dónde va.

> ⚠️ **Advertencia.** La ventana de inconsistencia **no es un detalle técnico**: es una
> decisión de producto. Llevarla a negocio y volver con la respuesta —"aquí sí se puede
> esperar, aquí no"— es lo que se espera de un arquitecto.

> **Veredicto:** la pregunta no es "¿cómo elimino la ventana?" sino "¿qué ve el usuario
> dentro de ella?". Quien responde lo primero acaba reinventando una transacción.

---

## 4. 🔁 Reconstruir una proyección

**Qué es.** Borrarla y rehacerla desde el principio del log. Es la operación que justifica
todo el patrón y la que hay que saber describir paso a paso.

**Por qué se reconstruye:** un bug en la proyección, un campo nuevo, un cambio de forma, o
una divergencia detectada.

**Cómo se hace sin parar el sistema:**

```text
1. Crear la proyección nueva VACÍA, al lado de la vieja. Nadie la lee todavía.
2. Un consumidor aparte la alimenta desde el offset 0.
3. Cuando alcanza la cabeza del log, sigue consumiendo en vivo.
4. Verificar: comparar conteos y muestras contra la vieja.
5. Cambiar las lecturas a la nueva, atómicamente (un alias, una feature flag).
6. Borrar la vieja pasado un margen.
```

- **Nunca se borra y se rehace en el sitio**: durante la reconstrucción no habría vista, y
  eso es una caída.
- El paso 4 es el que la gente se salta y el que evita cambiar a una vista peor que la
  anterior.
- El paso 5 con *feature flag* permite volver atrás en segundos si algo falla.

**Lo que hace falta para que esto sea posible**, y conviene decirlo porque limita:

- **El log tiene que conservar el histórico.** Con retención de siete días solo puedes
  reconstruir siete días. Para reconstrucción total hace falta retención infinita, log
  compactado, o event sourcing de verdad.
- **Los consumidores tienen que tolerar el reproceso.** Una proyección sí; un consumidor
  que manda correos, no — y por eso **una proyección nunca tiene efectos externos**.

> ⚠️ **Advertencia.** El accidente clásico: reconstruir una proyección y descubrir que el
> mismo consumidor enviaba correos. 400.000 clientes reciben "tu pedido se confirmó" de
> pedidos de hace dos años. Separar proyección de efecto no es purismo.

> **Veredicto:** si no puedes reconstruir la proyección, no tienes una proyección: tienes
> una base de datos alimentada por eventos, con todos los costes y ninguna de las ventajas.

---

## 5. 🌊 Procesamiento de flujos

**Qué es.** Un escalón por encima del consumidor simple: operaciones sobre el flujo entero
—filtrar, agrupar, unir, agregar por ventana— con estado gestionado por el framework. En el
mundo Java: Kafka Streams, y Flink cuando la cosa crece.

**Lo que aporta frente a un `@KafkaListener` con una tabla:**

- **Estado local gestionado y tolerante a fallos.** El framework guarda el estado en disco
  local y lo respalda en un topic compactado; si el proceso muere, se restaura solo.
- **Ventanas temporales.** "Cuántos pedidos rechazados por cliente en los últimos 5
  minutos" es una línea, no un `cron` con una tabla.
- **Uniones de flujos.** Cruzar `pedidos` con `clientes` sin llamar a nadie.
- **Tiempo de evento contra tiempo de proceso.** Esta es la distinción que se pregunta.

```text
Tiempo de evento   → cuándo OCURRIÓ, según la marca del propio evento
Tiempo de proceso  → cuándo lo LEÍSTE

Si agrupas "ventas por minuto" por tiempo de proceso, un consumidor lento
mueve las ventas de minuto. El resultado depende de tu infraestructura,
no de lo que pasó. Casi siempre es un bug.
```

- Por eso los frameworks serios agrupan por tiempo de evento y manejan los **eventos
  tardíos** con marcas de agua: hasta cuándo esperas a un rezagado antes de cerrar la
  ventana.

**Cuándo sí.** Agregaciones con ventana, uniones de flujos, detección de patrones, cuando
el estado intermedio es grande.

**Cuándo no.** Casi siempre. La mayoría de las proyecciones son "evento entra, fila sale", y
para eso un consumidor con una tabla es más simple, más depurable y lo entiende cualquiera.

> **Veredicto:** Kafka Streams se gana el sitio cuando necesitas **ventanas o uniones**.
> Para mantener una vista de lectura, un consumidor normal con SQL le gana en todo lo que
> importa: legibilidad, operación y gente que lo sepa mantener.

---

## 6. 🏛️ Lambda y Kappa

**Qué es.** Dos arquitecturas de datos que aparecen como pregunta de vocabulario. Vale con
saber qué problema resolvía cada una.

**Lambda.** Dos caminos en paralelo: una capa **batch** que recalcula todo periódicamente y
es exacta, y una capa de **velocidad** que da resultados aproximados en tiempo real. Las
consultas combinan ambas.

- El problema: **mantienes la misma lógica dos veces**, en dos tecnologías, y tienen que dar
  el mismo resultado. Es su crítica fundamental y la razón de que exista Kappa.

**Kappa.** Un solo camino: todo es *streaming*. El "recálculo batch" es simplemente
reprocesar el flujo desde el principio.

- Requiere un log con retención suficiente —lo de §4— y un motor capaz de reprocesar rápido.
- Es la que se impuso, y es exactamente el mecanismo de "reconstruir una proyección"
  elevado a arquitectura.

**Cuándo sí.** Es vocabulario: se nombra, no se implementa en una entrevista de backend.

**Cuándo no.** No diseñes Lambda hoy en un sistema nuevo salvo que tengas una razón muy
concreta para la capa batch.

> **Veredicto:** Kappa ganó porque Lambda obligaba a escribir la lógica dos veces. Esa
> frase, con esas palabras, es toda la respuesta que hace falta.

---

## 7. 🧭 Cómo se elige

```text
¿La consulta cruza agregados o contextos, y es frecuente?
    → Proyección. Una por consulta, sin miedo a duplicar datos.
¿Es rara y sobre un solo agregado?
    → Consulta directa o composición de API. No mantengas una vista para eso.

¿Necesitas ventanas temporales, uniones de flujos o estado grande?
    → Kafka Streams.
¿Es "evento entra, fila sale"?
    → Consumidor + SQL. Más simple, más depurable, más gente que lo mantiene.

¿Agrupas por tiempo?
    → Por tiempo de EVENTO, siempre. Por tiempo de proceso solo si mides tu infraestructura.

¿El usuario acaba de escribir y va a leer?
    → Decide QUÉ VE en la ventana. Devolver el resultado en la respuesta resuelve casi todo.

Y la regla que no se negocia:
    → Una proyección NUNCA tiene efectos externos. Se va a reprocesar.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La proyección es la fuente de verdad" | Es derivada y desechable; si diverge, se rehace |
| "Normalizo las proyecciones" | Se duplican datos a propósito: una vista por consulta |
| "Borro y rehago la proyección" | Se construye una nueva al lado y se cambia al terminar |
| "El consumidor proyecta y manda el correo" | Al reprocesar, mandas 400.000 correos viejos |
| "Agrupo por ventana de 5 minutos" | ¿De tiempo de evento o de proceso? Por proceso suele ser un bug |
| "Kafka Streams para las vistas de lectura" | Para ventanas y uniones; una vista simple es consumidor + SQL |
| "Elimino la ventana de inconsistencia" | No se elimina: se decide qué ve el usuario dentro de ella |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11 completo, y en especial "Processing Streams": tiempo de evento contra tiempo
  de proceso, ventanas y uniones. **Es el libro de este capítulo.**
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulos 7 a 10: microservicios que procesan flujos, con estado y sin él.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 7:
  consultas en una arquitectura de microservicios, con composición de API contra CQRS.
- [Kafka Streams — Documentation](https://kafka.apache.org/documentation/streams/): el
  modelo de estado local, las ventanas y el manejo de eventos tardíos.
- [microservices.io — API composition](https://microservices.io/patterns/data/api-composition.html):
  la alternativa a la proyección, con sus límites de paginación y ordenación.
- [microservices.io — CQRS](https://microservices.io/patterns/data/cqrs.html): la
  proyección vista como el lado de lectura.
- **Video** — Confluent y GOTO Conferences, charlas sobre Kafka Streams y sobre semántica
  de tiempo en procesamiento de flujos. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es una proyección? 🟢
2. ¿Cuáles son las tres propiedades que definen una proyección? 🟢
3. ¿Qué diferencia hay entre tiempo de evento y tiempo de proceso? 🟢
4. ¿Qué problema resolvía la arquitectura Lambda y por qué se abandonó? 🟢
5. ¿Por qué una proyección usa `upsert` y no `insert`? 🟡
6. ¿Por qué no se normalizan las proyecciones? 🟡
7. ¿Por qué una proyección no debe tener lógica de negocio? 🟡
8. ¿Qué es la composición de API y dónde falla? 🟡
9. ¿Qué aporta Kafka Streams frente a un consumidor con una tabla? 🟡
10. ¿Qué es una marca de agua y para qué sirve? 🟡
11. ¿Qué es la arquitectura Kappa? 🟡
12. Nombra cuatro formas de manejar la ventana de inconsistencia de cara al
    usuario. 🟠
13. ¿Por qué una proyección nunca debe tener efectos externos? 🟠
14. Describe el procedimiento de reconstrucción sin parar el sistema. 🟠
15. ¿Qué hace falta en el log para poder reconstruir una proyección entera? 🟠
16. ¿Por qué agrupar por tiempo de proceso suele ser un bug? 🟠
17. ¿Cuándo NO usarías Kafka Streams? 🟠
18. ¿Qué garantiza read-your-writes y qué cuesta? 🟠
19. ¿Por qué una proyección es "una caché con contrato"? 🟠
20. Diseña la proyección de "pedidos del cliente con estado de envío y factura":
    qué eventos consume, qué tabla mantiene y cómo se reconstruye. 🔴
21. Al reconstruir una proyección se enviaron 400.000 correos antiguos.
    Reconstruye el error de diseño y cómo se evita. 🔴
22. El usuario crea un pedido y no lo ve en su lista. Da cuatro soluciones,
    con su coste, y elige una justificándola. 🔴
23. Necesitas "pedidos rechazados por cliente en los últimos 15 minutos" en
    tiempo real. ¿Consumidor con tabla o Kafka Streams? Justifica. 🔴

---

**Anterior:** [`07` — Event sourcing](07-event-sourcing.md) ·
**Siguiente:** [`09` — Simulación de entrevista](09-simulacion-de-entrevista.md) ·
**Relacionado:** [`03-datos`](../03-datos/)
