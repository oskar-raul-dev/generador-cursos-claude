# 02 — HTTP entre servicios

> En qué se diferencia una API interna de una pública, y cómo se configura el cliente que la consume
> para que un servicio lento no se lleve por delante al que llama. Asume leído
> [`01`](01-estilos-de-comunicacion.md). La semántica del protocolo —métodos, códigos, idempotencia
> según el RFC— es de
> [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/), que la estudia a fondo; aquí se
> resume lo que hace falta entre servicios —qué se reintenta y qué significa cada código para el
> cliente— y no hace falta haberlo leído.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

El diseño de API que aprendiste está pensado para una API pública: consumidores desconocidos,
versiones que viven para siempre, documentación como contrato, hipermedia para que el cliente
descubra. Entre servicios internos, **casi todas esas premisas son falsas**: sabes quién te consume,
puedes negociar un cambio en una reunión, y el cliente lo genera el pipeline.

Pero hay algo que sí cambia a peor, y es lo que produce los incidentes:

```text
API pública   → el cliente es un navegador o un tercero, y si tarda, espera o se rinde
API interna   → el cliente es otro servicio, con hilos finitos, que a su vez tiene
                clientes esperando. Tu lentitud sube por la cadena y tumba a otros.
```

Por eso este capítulo dedica más espacio al **cliente** que al servidor. La mayoría de los desastres
con HTTP entre servicios no vienen del diseño del endpoint: vienen de un cliente con la
configuración por defecto.

---

## 2. 🧱 Qué cambia en una API interna

**Qué es.** Las mismas reglas del protocolo, con otras prioridades de diseño.

| Aspecto | API pública | API interna |
|---|---|---|
| Consumidores | Desconocidos, muchos | Conocidos, pocos, con nombre y equipo |
| Versionado | Vive años, se mantiene todo | Se negocia y se retira; compatibilidad hacia atrás durante la transición |
| Documentación | Es el contrato | El contrato es el esquema, y se verifica en CI ([`07`](07-contratos-y-versionado.md)) |
| Hipermedia | A veces útil | Casi nunca: el consumidor conoce el flujo |
| Granularidad | Genérica | Ajustada a los casos de uso reales del consumidor |
| Errores | Mensaje para humanos | Código estable para decidir si reintentar |

**Cómo va.** La consecuencia más práctica es la granularidad: en una API interna puedes —y debes—
añadir el endpoint que tu consumidor necesita, en vez de obligarle a componer cinco llamadas. Si
`orders` necesita quince productos, `catalog` expone una consulta por lote; eso no es "ensuciar la
API", es evitar el `N+1` distribuido de §5.

**Con qué.** Se sirve igual en las cuatro plataformas y el detalle del framework no es de este corpus.
Lo que sí es de aquí: el contrato se publica como esquema y el cliente se genera, no se escribe a
mano ([`07`](07-contratos-y-versionado.md)).

**Cuánto.** Ajustar la API a cada consumidor cuesta endpoints que solo usa uno, y el riesgo de acabar
con una API que es la unión de todos los casos de uso. Se acota versionando y retirando lo que ya no
se llama — con métricas de uso, no con suposiciones.

**Cuándo sí.** Siempre que el consumidor sea conocido.

**Cuándo no.** En cuanto el endpoint pueda salir al exterior: ahí vuelven a mandar las reglas de una
API pública, y eso se resuelve en el gateway o en un BFF
([`04-operacion-y-resiliencia/02`](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md)).

> **Veredicto:** una API interna se diseña para sus consumidores reales, no para los hipotéticos. Si
> te sorprendes diseñando "por si alguien la usa", estás pagando generalidad que nadie compra.

---

## 3. 🧱 El cliente HTTP es una decisión de arquitectura

**Qué es.** El conjunto de parámetros del cliente que deciden cómo se comporta tu servicio cuando el
otro va mal. No son ajustes: son diseño.

```text
timeout de conexión    cuánto espero a que me acepten la conexión
timeout de lectura     cuánto espero la respuesta una vez conectado
pool de conexiones     cuántas mantengo abiertas, y cuánto vive cada una
límite de concurrencia cuántas llamadas simultáneas permito a ESE destino
reintentos             cuántos, con qué espera, y solo si es idempotente
```

**Cómo va.** Los dos timeouts se calculan, no se inventan: el de lectura sale del p99 del servicio
destino más margen, y siempre **menor** que el presupuesto de la petición que lo contiene. Si tu
endpoint promete responder en un segundo y llamas a otro con timeout de dos, has roto tu propia
promesa.

El pool importa más de lo que parece: sin `keep-alive`, cada llamada abre conexión y, en HTTPS,
repite el saludo TLS. Es de los arreglos con mejor relación entre esfuerzo y efecto que existen.

**Con qué.** La tabla de §6, con el detalle que importa: **varios clientes populares no traen timeout
de lectura por defecto**, así que "usar los valores por defecto" significa, con frecuencia, "esperar
indefinidamente".

**Cuánto.** Cuesta pensar un número por dependencia y revisarlo cuando cambie el rendimiento del
otro. Lo que compra es que la lentitud ajena no se convierta en agotamiento de recursos propio, que
es el mecanismo del incidente de
[`01-fundamentos-y-descomposicion/04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md).

**Cuándo sí.** En toda llamada saliente, sin excepción.

**Cuándo no.** No hay excepción. Si una llamada legítimamente puede tardar minutos —un informe—, no
va en la ruta síncrona: va a una cola.

> **⚠️ Advertencia:** el timeout no es una medida de paciencia, es una medida de protección **del que
> llama**. Se elige por cuánto puedes permitirte esperar sin quedarte sin recursos, no por cuánto
> tarda el otro en su peor día.

---

## 4. 🧱 Errores y reintentos entre servicios

**Qué es.** Un contrato de error que permita al que llama **decidir sin adivinar**: ¿reintento, me
rindo, o degrado?

**Cómo va.** La forma del cuerpo de error debe ser la misma en todos tus servicios —eso es del
chassis— y debe llevar un código estable, propio del dominio, además del código de estado HTTP. El
mensaje es para humanos; la decisión se toma con el código.

```text
Respuesta          El que llama debería…
─────────────────  ────────────────────────────────────────────────
408, 429, 503, 504 reintentar con backoff; respetar Retry-After si viene
500                reintentar como mucho una vez, y solo si es idempotente
400, 404, 422      no reintentar nunca: el resultado será el mismo
409                no reintentar sin cambiar algo: hay conflicto de estado
```

**Con qué.** El reintento se configura en el cliente o en una librería de resiliencia, y su detalle
—backoff, jitter, presupuesto— es de
[`04-operacion-y-resiliencia/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md). Lo que pertenece a este capítulo es
la regla de entrada: **solo se reintenta lo idempotente**, y si la operación no lo es, se hace
idempotente con una clave de idempotencia antes de pensar en reintentar.

**Cuánto.** Los reintentos multiplican la carga justo cuando el otro está peor. Sin presupuesto y sin
jitter, un reintento ciego convierte una degradación en una caída.

**Cuándo sí.** Para lecturas siempre, y para escrituras cuando hay clave de idempotencia.

**Cuándo no.** Cuando no sabes si la operación se ejecutó. Ahí el reintento es una apuesta, y en
`payments` es una apuesta con el dinero de alguien.

> **Veredicto:** un error sin código estable obliga al que llama a adivinar, y adivinar significa
> reintentar lo que no debía. El contrato de error es parte del contrato, no un detalle de
> presentación.

---

## 5. 🧱 El `N+1` distribuido

**Qué es.** Pedir una lista y luego hacer una llamada por elemento. En una base de datos es un
problema de rendimiento; entre servicios es un incidente esperando.

```text
GET /orders/ORD-00042            → 15 líneas
GET /products/SKU-001            ┐
GET /products/SKU-002            │ 15 llamadas más, cada una con su latencia,
...                              │ su posibilidad de fallo y su conexión
GET /products/SKU-015            ┘
```

Con 40 ms por llamada, la pantalla pasa de 40 ms a 640 ms, y la probabilidad de que **alguna** falle
sube con cada una.

**Cómo va.** Dos salidas, y la elección depende de si el dato cambia:

- **Consulta por lote**: `catalog` expone una consulta que acepta varios identificadores. Simple,
  inmediato, y el límite de tamaño hay que fijarlo en el contrato.
- **Copia local por eventos**: `orders` mantiene los datos de producto que necesita, actualizados
  por eventos. Elimina la llamada, cuesta consistencia eventual y un consumidor
  ([`03-datos-y-consistencia/02`](../03-datos-y-consistencia/02-consultas-entre-servicios.md)).

**Cuánto.** El lote cuesta un endpoint más y un límite que vigilar; la copia cuesta un almacén más y
un proceso que mantener. La primera se hace en una tarde; la segunda es un diseño.

**Cuándo sí y cuándo no.** Lote cuando el dato tiene que ser fresco; copia cuando el dato cambia poco
y se consulta mucho — que es exactamente el caso del catálogo.

> **💡 Truco:** el `N+1` distribuido casi nunca aparece en pruebas, porque en pruebas la lista tiene
> tres elementos y el servicio está al lado. Aparece el día que un cliente pide cien líneas. Si ves
> un bucle con una llamada dentro, ya lo has encontrado.

---

## 6. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Cliente HTTP en la librería estándar y clientes del framework; declarativos que generan el cliente desde una interfaz; integración directa con métricas y resiliencia | **Poner los timeouts**: sin configurarlos, varias combinaciones esperan indefinidamente. Y vigilar el pool, que suele ser global y no por destino |
| **Node/TS** | `fetch` sobre un motor con pool propio, y clientes con interceptores; en NestJS, el módulo de HTTP con inyección | Un timeout total propio: los que trae el motor cubren fases concretas, no la petición entera. Y cancelar de verdad con `AbortSignal` |
| **Go** | `net/http` con `Transport` y pool configurable; `context` con deadline en cada petición | Todo explícito: el `http.Client` sin campos no tiene timeout. A cambio, el deadline del `context` se propaga a toda la cadena |
| **Python** | Clientes síncronos y asíncronos con API casi idéntica; límites de conexiones configurables | Recordar que el cliente clásico **no aplica timeout por defecto**, y no mezclar un cliente bloqueante dentro de código asíncrono |

Lo que hay que llevarse de la tabla no es la lista de librerías: es que **en tres de las cuatro, no
configurar nada significa esperar para siempre**. En Java, el cliente moderno con un timeout de
petición explícito:

```java
// El timeout de la PETICIÓN, no solo el de conexión: es el que evita el hilo colgado.
HttpRequest request = HttpRequest.newBuilder(URI.create(url))
        .timeout(Duration.ofMillis(800))   // menor que el presupuesto de mi endpoint
        .header("traceparent", context.traceparent())  // el contexto viaja conmigo
        .GET().build();
```

- El plazo va en la **petición**, no solo en el cliente: cada dependencia merece el suyo, calculado
  desde su p99.
- El encabezado de traza se propaga a mano si no hay instrumentación automática. Si se pierde aquí,
  la traza distribuida se corta justo donde empieza a ser útil
  ([`04-operacion-y-resiliencia/04`](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md)).

Lo mismo en Go, donde el plazo se propaga por el `context` y llega a todos los saltos:

```go
// El deadline vive en el contexto: lo heredan la llamada, sus reintentos y lo que venga después.
ctx, cancel := context.WithTimeout(ctx, 800*time.Millisecond)
defer cancel() // sin esto, se fuga el temporizador y, con él, la goroutine

req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
resp, err := client.Do(req) // err si expira el plazo o si el padre se canceló
```

- `WithTimeout` se compone: si quien te llamó ya tenía 500 ms, tu plazo efectivo es el menor de los
  dos. Eso es el presupuesto de latencia funcionando solo, y es el mejor argumento de Go para
  cadenas de llamadas.
- `defer cancel()` no es ceremonia: sin él se acumulan temporizadores y goroutines, que es la fuga
  más habitual del ecosistema.

> **🧰 Plataforma:** la diferencia real entre las cuatro no es la calidad del cliente, es **qué pasa
> si no configuras nada**. En Java y en Python el silencio significa esperar; en Go, el
> `http.Client{}` desnudo tampoco tiene plazo. El único valor por defecto seguro es el que tú
> escribiste.

---

## 7. 🧭 Cómo se elige el tamaño del endpoint

```text
¿El consumidor necesita varios recursos para una sola pantalla o decisión?
│
├─ sí ─► ¿los datos cambian poco y se consultan mucho?
│        ├─ sí ─► copia local por eventos, y deja de llamar
│        └─ no ─► endpoint por lote, con límite declarado en el contrato
│
└─ no ─► endpoint por recurso, y punto
```

Y la frase para decirlo:

> "Prefiero un endpoint por lote diseñado a propósito que quince llamadas en un bucle. Y si el dato
> cambia poco, prefiero no llamar: lo replico por eventos y asumo la consistencia eventual."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El cliente HTTP ya trae timeout por defecto" | Varios clientes populares no traen timeout de lectura. No configurarlo es esperar indefinidamente |
| "Una API interna se diseña igual que una pública" | Los consumidores son conocidos y negociables: la granularidad se ajusta a ellos y el contrato se verifica en CI |
| "Si falla, reintentamos" | Solo si es idempotente. Y con backoff, jitter y presupuesto, o el reintento tumba al que ya iba mal |
| "Devolvemos 500 y el mensaje explica el error" | El que llama decide con un código estable, no con un texto. El mensaje es para humanos |
| "Para no hacer N llamadas montamos un endpoint que devuelve todo" | Un lote con límite declarado, no un endpoint sin frenos: un consumidor pedirá diez mil |
| "El p99 del otro servicio es de 2 s, pongo timeout de 3 s" | El timeout sale de lo que tú puedes esperar sin quedarte sin recursos, y debe ser menor que tu propio presupuesto |
| "La traza se propaga sola" | Solo si hay instrumentación automática **y** el cliente la respeta. En clientes manuales, el encabezado lo pones tú |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 5,
   "Implementing Microservice Communication", con el tratamiento de clientes y de granularidad.
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3, sección de
   comunicación síncrona y sus problemas de disponibilidad. **El mejor argumento escrito sobre por
   qué el cliente importa más que el endpoint.**
3. **Fuente primaria** — Chris Richardson, «Pattern: Remote Procedure Invocation»:
   [microservices.io/patterns/communication-style/rpi.html](https://microservices.io/patterns/communication-style/rpi.html).
4. **Material de referencia** — Amazon Builders' Library, «Timeouts, retries, and backoff with
   jitter», que es la fuente canónica del cálculo de §3 y §4:
   [builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter](https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter).
5. **Documentación** — Go, `net/http` y su `Transport`, para ver qué se configura y qué no:
   [pkg.go.dev/net/http](https://pkg.go.dev/net/http).
6. **Especificación** — OpenAPI, para publicar el contrato de la API interna:
   [spec.openapis.org/oas/latest.html](https://spec.openapis.org/oas/latest.html).
7. **Tutorial** — Baeldung, «Guide to the Java HttpClient». Para la configuración concreta en Java,
   incluidos los plazos por petición.
8. **Charla** — GOTO Conferences, «Stop Rate Limiting! Capacity Management Done Right». La mejor
   exposición de por qué reintentar sin presupuesto empeora el incidente.

---

## 🧠 Preguntas

1. Nombra tres diferencias entre una API interna y una pública. 🟢
2. ¿Qué cinco parámetros del cliente HTTP son decisiones de arquitectura? 🟢
3. ¿Qué códigos de estado invitan a reintentar y cuáles no? 🟢
4. ¿Qué es el `N+1` distribuido? 🟢
5. ¿Por qué el contrato de error necesita un código estable además del código HTTP? 🟢
6. ¿Qué pasa si no configuras timeout de lectura en un cliente que no lo trae por defecto? 🟡
7. ¿Qué diferencia hay entre timeout de conexión y de lectura, y cuál falla primero cuando cae la
   red? 🟡
8. ¿Por qué el `keep-alive` importa especialmente en HTTPS? 🟡
9. ¿En qué se diferencia reintentar una lectura de reintentar una escritura? 🟡
10. ¿Por qué un endpoint por lote necesita un límite declarado en el contrato? 🟡
11. ¿Qué gana Go al llevar el plazo en el `context` en lugar de en el cliente? 🟡
12. ¿Por qué el timeout se elige desde lo que tú puedes esperar y no desde lo que tarda el otro? 🟠
13. Tu endpoint promete responder en 1 s y llama a dos servicios. ¿Cómo repartes los plazos? 🟠
14. `orders` hace quince llamadas a `catalog` por pantalla. Da dos soluciones y elige. 🟠
15. Un consumidor reintenta tres veces sin backoff y el servicio destino está degradado. Explica qué
    pasa y corrige. 🟠
16. ¿Cómo harías idempotente un `POST /payments` para poder reintentarlo con seguridad? 🟠
17. Diseña el cuerpo de error común de tus servicios: qué campos lleva y por qué cada uno. 🟠
18. El p99 de una dependencia se dobla tras un despliegue suyo. ¿Qué pasa en tu servicio y qué
    mecanismos lo contienen? 🟠
19. ¿Cuándo sacarías una llamada HTTP de la ruta síncrona, y a dónde la moverías? 🟠
20. ¿Qué encabezados propagas en toda llamada saliente y qué pasa si se pierde cada uno? 🟠
21. ¿Qué traen por defecto los clientes HTTP de las cuatro plataformas en cuanto a plazos? 🟠
22. Diseña el contrato de la API que `catalog` expone a `orders`: endpoints, tamaño de lote,
    errores, y qué se versiona. 🔴
23. Diagnostica: p99 de `orders` sube a 4 s, `catalog` responde en 60 ms, y el número de
    conexiones nuevas por segundo se ha multiplicado por diez. Da tres hipótesis ordenadas. 🔴
24. Escribe la configuración de cliente HTTP que le darías al chassis del equipo, con los valores
    que dependen de cada dependencia y los que no. 🔴
25. Un servicio tuyo es llamado por otros cuatro equipos y uno de ellos te satura con reintentos. Da
    tu respuesta técnica y la conversación que tienes con ellos. 🔴

---

**Anterior:** [`01` — Estilos de comunicación](01-estilos-de-comunicacion.md) · **Siguiente:**
[`03` — gRPC](03-grpc.md) · **Relacionado:** [`04` — HTTP contra gRPC](04-http-contra-grpc.md) ·
[`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/)

**Taller, opcional:** [`06/03` — HTTP entre servicios](../06-talleres/03-http-entre-servicios.md).
