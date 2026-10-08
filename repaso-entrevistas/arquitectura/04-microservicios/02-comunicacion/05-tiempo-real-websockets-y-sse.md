# 05 — Tiempo real: WebSockets, SSE y los demás

> Cuando el servidor tiene algo que decir y el cliente no está preguntando: polling, SSE, WebSocket,
> webhooks y streaming de gRPC. Y el problema transversal de todos ellos, que es que **la conexión
> tiene estado**. Asume leídos [`01`](01-estilos-de-comunicacion.md) y [`03`](03-grpc.md).
>
> **Este capítulo no lleva bloque de código de Java** (§5.3 de la guía): su soporte es completo y se
> parece mucho al de las demás, y lo que enseña de verdad es el contraste entre el modelo de Node y
> el de Go. La fila de Java está en la tabla de §7.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

El pedido `ORD-00042` cambia de estado cuatro veces en diez minutos: confirmado, reservado, pagado,
enviado. El usuario tiene la pantalla abierta. ¿Cómo se entera?

HTTP tiene un supuesto incrustado: **el cliente pregunta y el servidor responde**. Aquí es al revés,
y todas las soluciones son formas de rodear ese supuesto:

```text
Preguntar cada pocos segundos     → simple, pero N clientes × M consultas inútiles
Preguntar y que el servidor       → menos consultas inútiles, conexiones ocupadas
  retenga la respuesta
Dejar un canal abierto            → eficiente, pero ahora hay estado en el servidor
```

Y la decisión importante no es cuál eliges: es darte cuenta de que **entre servicios internos casi
nunca necesitas ninguno de estos**. Para eso están los eventos ([`06`](06-mensajeria-y-eventos.md)).
Estos mecanismos son casi siempre para el tramo **servidor → cliente final**, y ahí la pregunta
correcta es cuánta latencia tolera el usuario.

---

## 2. 🧱 Polling y long polling

**Qué es.** El cliente pregunta cada cierto tiempo (*polling*), o pregunta y el servidor retiene la
respuesta hasta que haya novedad o expire un plazo (*long polling*).

**Cómo va.** El polling simple se dimensiona con una cuenta que conviene saber hacer en voz alta:

```text
10 000 usuarios × 1 consulta cada 5 s  =  2 000 consultas/s
  …de las cuales el 99 % responden "no hay nada nuevo"
```

**Con qué.** Nada especial: es HTTP normal, con caché y `ETag` para abaratar las respuestas vacías.
Esa es justamente su gracia.

**Cuánto.** Cuesta tráfico inútil y latencia media de medio intervalo. A cambio no cuesta **nada** de
infraestructura: sin estado, sin conexiones largas, sin afinidad, y el despliegue no lo nota.

**Cuándo sí.** Cuando la latencia tolerable es de segundos y el número de clientes es moderado.
Sigue siendo la respuesta correcta muchas más veces de las que se admite.

**Cuándo no.** Con muchos clientes o cuando la novedad debe llegar en menos de un segundo. Y el long
polling, casi nunca hoy: ocupa conexiones como un canal abierto y tiene peor ergonomía que SSE.

> **Veredicto:** el polling es la opción aburrida que casi siempre funciona. Antes de montar un canal
> persistente, haz la cuenta: si son cien usuarios y cinco segundos de latencia, la infraestructura
> que te ahorras vale más que la elegancia que pierdes.

---

## 3. 🧱 SSE (Server-Sent Events)

**Qué es.** Un flujo de texto unidireccional sobre una respuesta HTTP que no termina. El servidor
escribe eventos; el cliente los recibe según llegan.

**Cómo va.** Es HTTP corriente, con un tipo de contenido específico y un formato de línea muy simple:

```text
GET /orders/ORD-00042/events
Accept: text/event-stream

→ respuesta que no termina:

id: 17
event: status
data: {"status":"CONFIRMED"}

id: 18
event: status
data: {"status":"PAID"}
```

- El campo `id` es la clave: el navegador lo recuerda y, si la conexión se corta, **reconecta solo**
  enviando el último identificador recibido. La reanudación viene de serie, y el servidor solo tiene
  que saber reenviar desde ahí.
- Al ser HTTP normal, atraviesa proxies, balanceadores y WAF sin configuración especial, y se
  autentica igual que cualquier otra petición.

**Con qué.** Soporte nativo en el navegador y en las cuatro plataformas del servidor; no hace falta
librería.

**Cuánto.** Cuesta una conexión abierta por cliente —igual que WebSocket— y no sirve para enviar
datos del cliente al servidor: para eso se usa una petición HTTP normal, que suele ser exactamente lo
que quieres.

**Cuándo sí.** Notificaciones, progreso de un proceso, actualizaciones de estado, respuestas que se
producen poco a poco. Cubre la mayoría de las necesidades reales de "tiempo real".

**Cuándo no.** Cuando de verdad hace falta un canal de vuelta de baja latencia —edición colaborativa,
juegos, voz—, o cuando el volumen por cliente es tan alto que el formato de texto pesa.

> **Veredicto:** SSE es la respuesta por defecto para empujar datos al navegador. Si eliges WebSocket
> sin necesitar el canal de vuelta, estás pagando reconexión, protocolo y compatibilidad a cambio de
> nada.

---

## 4. 🧱 WebSocket

**Qué es.** Un canal bidireccional sobre una conexión TCP que empieza como HTTP y se **actualiza** a
otro protocolo.

**Cómo va.** El cliente pide la actualización con un `Upgrade`; a partir de ahí el tráfico ya no es
HTTP, son marcos de WebSocket. Y eso tiene una consecuencia que hay que decir en voz alta: **el
protocolo no trae semántica**. No hay métodos, no hay códigos de estado, no hay reintento, no hay
reconexión. El protocolo de mensajes te lo inventas tú, y con él la versión, el formato de error y la
recuperación.

**Con qué.** Librerías en las cuatro plataformas, y capas por encima que añaden lo que falta
—reconexión, reintento, salas, confirmaciones—. Elegir una capa así es una decisión de arquitectura,
no un detalle.

**Cuánto.** Cuesta todo lo de una conexión larga —§6— más el protocolo propio. Y cuesta compatibilidad
con infraestructura intermedia que a veces corta conexiones ociosas, lo que obliga a latidos
periódicos.

**Cuándo sí.** Cuando hay tráfico frecuente en **ambos** sentidos: colaboración en vivo, chat,
interacción con baja latencia.

**Cuándo no.** Para notificar. Es el error más común del capítulo: se monta WebSocket para mandar
actualizaciones que SSE resolvería con reconexión incluida.

> **⚠️ Advertencia:** al no haber semántica, cada equipo reinventa su protocolo de mensajes: los
> tipos, los errores, el versionado y las confirmaciones. Ese protocolo es un contrato como
> cualquier otro y hay que versionarlo ([`07`](07-contratos-y-versionado.md)); la diferencia es que
> aquí nadie te lo recuerda.

---

## 5. 🧱 Webhooks

**Qué es.** El empuje entre sistemas: tú registras una URL y el otro sistema te llama cuando pasa
algo. Es una llamada HTTP normal, en sentido contrario al habitual.

**Cómo va.** Es la forma estándar de integrarse con terceros —pasarelas de pago, proveedores— y lo
que hay que diseñar es siempre lo mismo:

| Pieza | Por qué |
|---|---|
| **Firma** | Cualquiera puede llamar a tu URL: hay que verificar que el mensaje viene de quien dice |
| **Idempotencia** | Reintentarán. El mismo evento llegará dos veces, y a veces desordenado |
| **Respuesta rápida** | Se acepta y se encola; procesar dentro de la petición provoca reintentos por timeout |
| **Reintentos y DLQ** | Si eres tú quien emite, necesitas política de reintento y un sitio donde acaben los fallos |

**Cuánto.** Cuesta una superficie pública más que proteger, y el trabajo de deduplicar. A cambio
elimina el polling contra el tercero.

**Cuándo sí.** Integración con sistemas externos, en cualquiera de los dos sentidos.

**Cuándo no.** Entre tus propios servicios: ahí tienes un broker, que da orden, reintentos, DLQ y
observabilidad sin inventar nada ([`06`](06-mensajeria-y-eventos.md)).

> **Veredicto:** un webhook es una llamada HTTP con todas las obligaciones de un consumidor de
> eventos: firma, idempotencia y encolado. Tratarlo como "un aviso" es cómo se duplican cobros.

---

## 6. 🧱 El problema común: la conexión tiene estado

**Qué es.** SSE, WebSocket y el streaming de gRPC comparten el mismo precio: una conexión abierta
asociada a **una instancia concreta**. Y eso choca con todo lo que hace un sistema elástico.

```text
Escalado      una instancia nueva no recibe conexiones existentes: solo las futuras
Despliegue    al reemplazar instancias, TODAS sus conexiones se cortan a la vez
Balanceo      si el usuario reconecta, puede caer en otra instancia sin su contexto
Emisión       el evento nace en un servicio que no tiene la conexión del usuario
Autenticación el token caduca a mitad de la conexión, y no hay petición donde renovarlo
```

**Cómo va.** Las respuestas son tres y conviene conocerlas por nombre:

- **Reconexión con reanudación.** Es la de SSE y sale gratis: el cliente vuelve con el último
  identificador y el servidor reenvía desde ahí. Convierte el corte en un hueco de milisegundos.
- **Backplane.** Las instancias se suscriben a un canal común —un broker— y cualquiera puede empujar
  a las conexiones que tiene. Es lo que resuelve el problema de "el evento nace en otro servicio".
- **Capa de conexiones aparte.** Un servicio dedicado que solo mantiene conexiones y traduce eventos
  del broker a empujes. El resto del sistema deja de saber que existe el tiempo real.

**Cuánto.** La reconexión es gratis y limitada; el backplane cuesta un broker en el camino y latencia
extra; la capa dedicada cuesta un servicio más, y es lo que se acaba montando cuando hay muchos
clientes.

> **🧠 Modelo mental:** un canal abierto convierte a tu servicio en algo con estado. Todo lo que
> sabes sobre servicios sin estado —escalar, desplegar, balancear sin pensar— deja de aplicarse en
> ese tramo, y hay que diseñarlo a propósito.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Soporte de WebSocket y SSE en el marco web, en modelo bloqueante y reactivo; el reactivo encaja mejor con muchas conexiones ociosas | Elegir el modelo: con hilo por conexión, mil conexiones son mil hilos. Y montar el backplane |
| **Node/TS** | Su terreno natural: el bucle de eventos aguanta muchas conexiones ociosas con poca memoria; librerías maduras con reconexión y salas | Que ninguna operación de CPU se cuele en el bucle: con conexiones abiertas, bloquear el hilo congela a todos los conectados a la vez |
| **Go** | Goroutines baratas: una por conexión es un modelo natural y se lee bien; `context` para cancelar | Escribir los latidos, la reconexión y el protocolo de mensajes. Y cerrar bien: una goroutine por conexión que no termina es la fuga clásica |
| **Python** | WebSocket y SSE en el marco ASGI, con la misma API asíncrona del resto | No mezclar código bloqueante: con conexiones abiertas, bloquear el bucle afecta a todos. Y contar con el modelo de procesos al escalar |

SSE en Node/TS, donde se ve que no hace falta librería —es una respuesta HTTP que no termina—:

```ts
// SSE es HTTP normal: encabezados, y luego escribir sin cerrar.
res.writeHead(200, {
  'Content-Type': 'text/event-stream',
  'Cache-Control': 'no-cache',   // sin esto, un proxy puede almacenar y no entregar nada
  Connection: 'keep-alive',
});

const send = (id: number, status: string) =>
  res.write(`id: ${id}\nevent: status\ndata: ${JSON.stringify({ status })}\n\n`);

// Latido: mantiene viva la conexión frente a proxies que cortan lo ocioso.
const heartbeat = setInterval(() => res.write(': ping\n\n'), 15_000);
req.on('close', () => clearInterval(heartbeat));  // sin esto, se fuga un temporizador por cliente
```

- Los dos saltos de línea al final de cada evento son el separador del formato: sin ellos, el cliente
  no entrega nada y parece que "no llega".
- El `Cache-Control` no es decorativo: un intermediario que almacene la respuesta rompe el flujo
  entero y el síntoma es desconcertante —funciona en local y no en producción—.
- El `close` es obligatorio: cada cliente desconectado deja un temporizador vivo si no lo limpias.

Lo mismo en Go, donde el modelo es una goroutine por conexión y el fin llega por `context`:

```go
// Una goroutine por conexión; el contexto de la petición manda cuándo termina.
func events(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/event-stream")
    flusher, ok := w.(http.Flusher) // sin Flush, la respuesta se acumula y no sale
    if !ok { http.Error(w, "streaming not supported", http.StatusInternalServerError); return }

    for {
        select {
        case <-r.Context().Done(): // el cliente se fue o el servidor se apaga
            return
        case ev := <-eventsCh:
            fmt.Fprintf(w, "id: %d\nevent: status\ndata: %s\n\n", ev.ID, ev.JSON)
            flusher.Flush() // entrega ya; si no, el cliente no ve nada hasta llenar el búfer
        }
    }
}
```

- El `select` con `r.Context().Done()` es el patrón: la conexión muere cuando muere el contexto, y
  eso incluye el apagado ordenado
  ([`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)).
- El `Flush` explícito es el detalle que más tiempo hace perder: sin él, todo funciona salvo que no
  llega nada hasta que se llena el búfer.

> **🧰 Plataforma:** la diferencia real no es el soporte —lo tienen las cuatro— sino **cuánto cuesta
> una conexión ociosa**. En Node y en Go, casi nada. En Java con hilo por conexión, un hilo; con el
> modelo reactivo, casi nada. En Python, depende del modelo de despliegue por procesos. Esa cuenta
> decide si mil conexiones son un detalle o un problema.

---

## 8. 🧭 Cómo se elige

```text
¿Es entre dos servicios internos?
├─ sí ─► casi nunca es esto: usa eventos (06). Y si de verdad es un flujo
│        continuo entre servicios, streaming de gRPC (03).
└─ no (es hacia el cliente final)
   │
   ├─ ¿Tolera segundos de retraso y hay pocos clientes? ─► polling. En serio.
   │
   ├─ ¿Solo va del servidor al cliente? ─────────────────► SSE (reconexión incluida)
   │
   └─ ¿Hay tráfico frecuente en los dos sentidos? ───────► WebSocket, y diseña
                                                           su protocolo de mensajes
```

Y la frase, que es de las que mejor distinguen a un candidato:

> "Para notificar al navegador uso SSE, porque me da reconexión y reanudación de serie y pasa por
> cualquier proxy. WebSocket lo dejo para cuando de verdad necesito el canal de vuelta, porque
> entonces tengo que inventarme el protocolo entero."

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Para tiempo real, WebSocket" | Si solo empujas datos, SSE da lo mismo con reconexión y reanudación incluidas, y sin protocolo propio |
| "SSE es lo mismo pero peor" | Es unidireccional, y eso es una ventaja: HTTP normal, atraviesa proxies, se autentica igual y reconecta solo |
| "El WebSocket escala igual que un endpoint HTTP" | Tiene estado: la conexión vive en una instancia. Escalado, despliegue y balanceo dejan de ser transparentes |
| "Los webhooks son fire and forget" | El emisor reintenta: el receptor necesita firma, idempotencia y encolado, como cualquier consumidor de eventos |
| "El polling es una mala práctica" | Con pocos clientes y latencia tolerable de segundos es la opción más barata y la que menos se rompe |
| "Usamos WebSocket entre servicios para que sea rápido" | Entre servicios tienes eventos o streaming de gRPC, con orden, reintentos y observabilidad resueltos |
| "La autenticación del canal se hace al abrir y ya" | El token caduca a mitad de conexión. Hay que decidir si se renueva por el propio canal o si se corta y se reconecta |

---

## 📚 Para profundizar

1. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 4, para situar
   el empuje al cliente dentro de los estilos de comunicación.
2. **Especificación** — WHATWG HTML, «Server-sent events», con el formato exacto y la semántica de
   `Last-Event-ID`:
   [html.spec.whatwg.org/multipage/server-sent-events.html](https://html.spec.whatwg.org/multipage/server-sent-events.html).
   **La fuente para todo lo de SSE.**
3. **Especificación** — RFC 6455, «The WebSocket Protocol», para el `Upgrade` y los marcos:
   [rfc-editor.org/rfc/rfc6455](https://www.rfc-editor.org/rfc/rfc6455).
4. **Documentación** — MDN, «Using server-sent events», la traducción práctica de la especificación:
   [developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events).
5. **Documentación** — MDN, «The WebSocket API», con el ciclo de vida del lado del cliente:
   [developer.mozilla.org/en-US/docs/Web/API/WebSockets_API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API).
6. **Documentación** — gRPC, conceptos de streaming, para el caso entre servicios:
   [grpc.io/docs/what-is-grpc/core-concepts/](https://grpc.io/docs/what-is-grpc/core-concepts/).
7. **Charla** — GOTO Conferences, «Scaling WebSockets». Es donde mejor se explica el backplane y el
   coste real de las conexiones con estado.

---

## 🧠 Preguntas

1. ¿Qué problema resuelven SSE, WebSocket y el polling? 🟢
2. ¿Qué campo de SSE permite reanudar tras un corte, y cómo funciona? 🟢
3. ¿Qué significa que WebSocket "no trae semántica"? 🟢
4. Enumera las cuatro piezas que hay que diseñar al recibir webhooks. 🟢
5. ¿Por qué se dice que una conexión abierta convierte al servicio en algo con estado? 🟢
6. ¿Qué mecanismo usarías entre dos servicios internos para notificar un cambio? 🟢
7. ¿Por qué SSE atraviesa proxies y balanceadores mejor que WebSocket? 🟡
8. Diferencia entre polling, long polling y SSE en consumo de conexiones. 🟡
9. ¿Qué es un backplane y qué problema concreto resuelve? 🟡
10. ¿Por qué el despliegue es especialmente molesto con conexiones largas? 🟡
11. ¿Qué pasa con la autenticación cuando el token caduca a mitad de una conexión? 🟡
12. ¿Por qué en Node una operación de CPU es más grave con conexiones abiertas que sin ellas? 🟡
13. ¿Qué latidos y qué timeouts configuras en un canal persistente, y por qué? 🟡
14. ¿Cuánto cuesta una conexión ociosa en cada plataforma, y por qué eso decide el diseño? 🟡
15. Tienes 200 usuarios y una latencia tolerable de 10 s. ¿Qué eliges y cómo lo defiendes? 🟠
16. El equipo propone WebSocket para mostrar el estado del pedido. Argumenta. 🟠
17. Un evento nace en `payments` y hay que empujarlo al navegador, que está conectado a `orders`.
    Diseña el camino. 🟠
18. ¿Cómo evitas que un despliegue corte todas las conexiones a la vez? 🟠
19. Recibes webhooks de una pasarela de pago. Diseña el endpoint, paso a paso. 🟠
20. ¿Cuándo montarías una capa de conexiones aparte en vez de mantenerlas en el servicio? 🟠
21. Funciona en local y en producción no llega nada por SSE. Da tres hipótesis ordenadas. 🟠
22. Diseña el seguimiento en vivo del estado de un pedido para web y móvil, con reconexión,
    autenticación y escalado, y di qué mecanismo usas en cada tramo. 🟠
23. Escribe el protocolo de mensajes de un WebSocket de chat: tipos, versionado, errores y
    confirmaciones. 🔴
24. Tu servicio mantiene 50 000 conexiones y hay que desplegar dos veces al día sin que el usuario
    lo note. Diseña la solución completa. 🔴
25. Diseña la recepción de webhooks de tres proveedores distintos con un solo mecanismo interno,
    incluyendo firma, deduplicación y reproceso. 🔴

---

**Anterior:** [`04` — HTTP contra gRPC](04-http-contra-grpc.md) · **Siguiente:**
[`06` — Mensajería y eventos](06-mensajeria-y-eventos.md) · **Relacionado:**
[`03` — gRPC](03-grpc.md) ·
[`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)

**Taller, opcional:** [`06/11` — Consultas entre servicios y tiempo real](../06-talleres/11-consultas-y-tiempo-real.md).
