# 04 — Observabilidad y trazas

> Cómo se diagnostica una latencia que solo pasa en producción: trazas, métricas y logs
> correlacionados, y sobre todo **dónde se pierde el contexto** en cada plataforma. Asume leídos
> [`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)
> y [`03`](03-resiliencia-en-la-practica.md).
>
> **Este capítulo no lleva bloque de código de Java** (§5.3 de la guía): su caso —el contexto que no
> cruza a un pool de hilos— se cuenta en prosa y en su fila de la tabla, y lo que enseña de verdad es
> el contraste entre Node y Go.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

Un cliente dice que la confirmación de pedidos "va lenta a veces". En el monolito, esto se
diagnosticaba con un perfilador y un stack trace. Ahora:

```text
· la petición pasó por 4 servicios y 2 colas
· el log de cada uno está en un sitio distinto, con formato distinto
· la media de latencia de todos ellos está bien
· no se reproduce en pruebas
```

El problema no es la falta de datos: es que **los datos de cada servicio no se pueden unir**. Sin una
forma de decir "todo esto pertenece a la misma petición", tienes cuatro historias inconexas y
ninguna respuesta.

Eso es lo que resuelve la observabilidad distribuida, y su pieza central no son las herramientas: es
**la propagación del contexto**. Todo lo demás se compra hecho; esto hay que asegurarlo servicio a
servicio, y es donde falla.

---

## 2. 🧱 Los tres pilares, y qué pregunta responde cada uno

**Qué es.** Trazas, métricas y logs. Se recitan siempre juntos y casi nunca se dice para qué sirve
cada uno, que es la parte útil:

| Pilar | Pregunta que responde | Coste |
|---|---|---|
| **Métricas** | ¿Hay un problema, y desde cuándo? | Barato: valores agregados |
| **Trazas** | ¿Dónde está el problema, en qué servicio y en qué llamada? | Caro: un registro por petición, y por eso se muestrea |
| **Logs** | ¿Qué pasó exactamente en ese punto concreto? | Muy caro en volumen, y el que más se descontrola |

**Cómo va.** El flujo de diagnóstico va en ese orden: la alerta salta por una métrica, la traza dice
dónde, y el log dice qué. Si los tres no comparten el identificador de correlación, ese flujo se
rompe y cada paso es una búsqueda a ciegas.

**Cuánto.** La observabilidad es de las partidas más caras de un sistema distribuido, y crece con el
tráfico. La decisión importante no es qué herramienta usar: es **cuánto muestrear** y **cuánto
retener**.

> **🧠 Modelo mental:** métricas para saber **que** pasa algo, trazas para saber **dónde**, logs para
> saber **qué**. Si tu respuesta a "¿cómo diagnosticarías esto?" empieza por los logs, te va a costar
> el doble.

---

## 3. 🧱 Traza, span y contexto

**Qué es.** Una **traza** es el recorrido completo de una petición; un **span** es cada tramo con su
duración; el **contexto** es lo que viaja para que los spans de servicios distintos se unan.

```text
traza abc123
├── span: POST /orders             orders       120 ms
│   ├── span: reserve              inventory     40 ms
│   │   └── span: SELECT stock     (base)        12 ms
│   └── span: charge               payments      60 ms
│       └── span: POST pasarela    (externo)     55 ms  ← aquí está el tiempo
```

**Cómo va.** El contexto viaja en un encabezado estándar —`traceparent`, de W3C— que lleva el
identificador de traza, el del span padre y las banderas de muestreo. Cada servicio lo lee, crea sus
spans como hijos, y lo propaga a sus llamadas salientes.

**Con qué.** OpenTelemetry: una API para instrumentar, un SDK por plataforma, y un **colector** que
recibe y exporta. La ventaja del colector es que desacopla del proveedor: cambiar de destino es
cambiar la configuración del colector, no la de cincuenta servicios.

**Cuánto.** La instrumentación automática cubre lo habitual —servidor, clientes, base de datos— con
poco esfuerzo. Lo que cuesta es instrumentar lo propio y, sobre todo, **no perder el contexto**.

> **💡 Truco:** el identificador de traza es también el mejor "código de incidencia" que puedes darle
> a un usuario. Con él, cualquiera puede abrir la traza completa de su petición fallida sin buscar
> nada.

---

## 4. 🩺 Dónde se pierde el contexto

Es el contenido más valioso del capítulo, porque es lo que la instrumentación automática **no**
cubre. Cuatro sitios:

| Se pierde en | Por qué | Cómo se arregla |
|---|---|---|
| **Al cruzar a un pool de hilos** | El contexto viaja atado al hilo; otro hilo no lo tiene | Propagarlo explícitamente al enviar la tarea |
| **Al publicar en un broker** | El mensaje no lleva encabezados salvo que se los pongas | Inyectar el contexto en los encabezados del mensaje y extraerlo al consumir |
| **En código asíncrono sin el mecanismo de la plataforma** | Cada runtime tiene el suyo, y hay que usarlo | `AsyncLocalStorage`, `context.Context`, `contextvars`, según §6 |
| **En un cliente HTTP manual** | Si no está instrumentado, no añade el encabezado | Añadirlo en el chassis, no en cada llamada |

El segundo es el más común y el más dañino: **la traza se corta justo en el salto asíncrono**, que es
donde más falta hace. El resultado es una traza del productor y otra del consumidor, sin relación, y
la pregunta "¿por qué este pedido no se reservó?" vuelve a ser artesanal.

> **⚠️ Advertencia:** si al publicar un evento no inyectas el contexto en los encabezados del mensaje,
> toda la parte asíncrona de tu sistema —que suele ser donde están los problemas difíciles— queda
> fuera de las trazas. Es el agujero número uno de la observabilidad en microservicios.

---

## 5. 🧱 Métricas, logs y muestreo

**Métricas: RED y USE.** Dos conjuntos que cubren casi todo:

```text
RED (para servicios)        Rate · Errors · Duration
USE (para recursos)         Utilization · Saturation · Errors
```

Para un servicio: peticiones por segundo, tasa de error y distribución de latencia. Para un recurso
—CPU, pool, cola—: cuánto se usa, cuánto se encola y cuántos fallos da. Y **siempre percentiles, nunca
medias**: con una latencia media de 100 ms, el p99 puede ser de cinco segundos y ser el único número
que importa.

**Logs estructurados.** En JSON, con campos fijos y con el identificador de traza en cada línea. El
texto plano ya no sirve: no se puede filtrar, no se puede correlacionar y multiplica el coste de
almacenamiento sin aportar nada.

**Muestreo.** No se guardan todas las trazas:

| Tipo | Cómo | A favor / en contra |
|---|---|---|
| **Por cabeza** | Se decide al empezar la traza, con probabilidad fija | Simple y barato; pierde justo las trazas de los errores raros |
| **Por cola** | Se decide al terminar, sabiendo si hubo error o latencia alta | Guarda lo interesante; exige retener las trazas en el colector hasta decidir |

Lo habitual y razonable: **muestreo bajo para lo normal y garantizado para errores y latencias
altas**. Y la regla de oro: la decisión de muestreo se propaga en el contexto, así que o se guarda la
traza entera o no se guarda ninguna parte — una traza a medias no sirve para nada.

---

## 6. 🧰 En las cuatro plataformas

Lo que se compara es **el mecanismo de propagación de contexto de cada runtime**, que es donde está
la diferencia real.

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Agente que instrumenta sin tocar el código: servidor, clientes, base de datos y brokers habituales | El contexto va atado al hilo, así que **no cruza a un pool** ni a tareas asíncronas si no se propaga explícitamente. Con hilos virtuales mejora, pero el patrón sigue |
| **Node/TS** | Instrumentación automática de los marcos habituales; `AsyncLocalStorage` propaga el contexto a través de `await` | Que el contexto sobreviva a callbacks antiguos, a colas propias y a `worker_threads`, donde no viaja solo |
| **Go** | `context.Context` **es** el mecanismo: se pasa por la firma y no hay magia | Pasarlo por toda la cadena; si una función lo olvida, la traza se corta ahí y en silencio |
| **Python** | `contextvars` funciona con el modelo asíncrono; instrumentación automática de los marcos habituales | Que no se pierda al cambiar de hilo o de proceso trabajador, y en código bloqueante ejecutado aparte |

En Node/TS, el caso que mejor enseña: propagar el contexto **al publicar un mensaje**.

```ts
// Inyectar el contexto en los encabezados del mensaje: sin esto, la traza se corta aquí.
const headers: Record<string, string> = {};
propagation.inject(context.active(), headers);       // escribe traceparent

await broker.publish('orders.placed', {
  key: order.id,
  value: JSON.stringify(event),
  headers,                                            // viajan con el mensaje
});
```

- `context.active()` es el contexto de la petición actual, que `AsyncLocalStorage` ha mantenido vivo
  a través de todos los `await` intermedios.
- Del lado del consumidor hay que hacer lo simétrico: `propagation.extract` sobre los encabezados y
  crear el span como hijo. Si solo se hace la mitad, no sirve de nada.

Y en Go, donde el contexto es explícito y por eso se ve cuándo se pierde:

```go
// El ctx lleva el span activo. Si una función no lo recibe, su trabajo queda fuera de la traza.
func (s *Service) Place(ctx context.Context, id OrderID) error {
    ctx, span := tracer.Start(ctx, "place-order")  // hijo del span que venía en ctx
    defer span.End()

    if err := s.inventory.Reserve(ctx, id); err != nil {   // ctx SIEMPRE se pasa
        span.RecordError(err)                                // el error queda en la traza
        span.SetStatus(codes.Error, "reservation rejected")
        return err
    }
    go s.notify(ctx, id)     // ⚠️ el ctx se propaga, pero si el padre termina y lo cancela,
                             //    esta goroutine muere: para trabajo en segundo plano,
                             //    hay que separar la cancelación del contexto de traza
    return nil
}
```

- `tracer.Start` devuelve un `ctx` nuevo: **el que hay que pasar hacia abajo es ese**, no el original.
  Pasar el viejo es el error más común y produce spans huérfanos.
- La línea del `go` señala la trampa específica de Go: el contexto lleva a la vez la traza y la
  cancelación, y para trabajo en segundo plano quieres lo primero sin lo segundo.

> **🧰 Plataforma:** en Java el contexto es invisible y por eso se pierde sin que nadie se entere; en
> Go es explícito y por eso se ve dónde falta. Son dos formas opuestas del mismo problema, y explican
> por qué las trazas incompletas son tan frecuentes: la instrumentación automática cubre el 80 % y el
> 20 % restante es justo el que importa.

---

## 7. 🔭 SLI, SLO y presupuesto de error

Lo justo para hablarlo en una entrevista sin convertirlo en otro capítulo:

```text
SLI  lo que mides:    % de peticiones con latencia < 500 ms y sin error
SLO  lo que prometes: 99,5 % en 30 días
Presupuesto de error: el 0,5 % restante ≈ 3,6 horas al mes
```

La idea útil es la del presupuesto: si te sobra, puedes arriesgar —desplegar más, experimentar—; si
te lo has gastado, toca estabilizar. Convierte una discusión de sensaciones en una de números.

Y el error clásico: definir el SLO sobre lo que es fácil de medir —disponibilidad del servidor— en
vez de sobre lo que el usuario percibe. Un servicio que responde `200` en cinco segundos está
disponible y es inútil.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con logs centralizados ya tienes observabilidad" | Tienes el tercer pilar y el más caro. Sin métricas no sabes que pasa algo, y sin trazas no sabes dónde |
| "El tracing lo pone el agente solo" | Cubre lo habitual. El contexto se pierde en pools, en brokers y en código asíncrono propio, que es donde más falta hace |
| "Medimos la latencia media" | La media esconde la cola. Se miden percentiles, y el que duele es el p99 |
| "Muestreamos al 1 % y vemos todo igual" | Al 1 % pierdes casi todos los errores raros. Se garantiza el muestreo de errores y de latencias altas |
| "El log lleva el identificador de petición" | Tiene que llevar el de **traza**, y el mismo que usan métricas y trazas. Si cada uno tiene el suyo, no se correlacionan |
| "Instrumentamos todo por si acaso" | La observabilidad es de las partidas más caras. Se decide qué se guarda, cuánto se muestrea y cuánto se retiene |
| "El SLO es 99,9 % de disponibilidad" | ¿Disponibilidad de qué? Un `200` en cinco segundos cuenta como disponible y el usuario ya se fue |

---

## 📚 Para profundizar

1. **Libro** — Charity Majors, Liz Fong-Jones y George Miranda, *Observability Engineering*,
   O'Reilly, 2022. Capítulos 1–3: por qué la observabilidad distribuida es distinta de la
   monitorización clásica. **La referencia moderna del tema.**
2. **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021. Capítulo 10, "From
   Monitoring to Observability", con el enfoque práctico para microservicios.
3. **Documentación** — OpenTelemetry, conceptos de trazas: traza, span, atributos y eventos:
   [opentelemetry.io/docs/concepts/signals/traces/](https://opentelemetry.io/docs/concepts/signals/traces/).
4. **Documentación** — OpenTelemetry, propagación de contexto, que es el tema de §4:
   [opentelemetry.io/docs/concepts/context-propagation/](https://opentelemetry.io/docs/concepts/context-propagation/).
5. **Especificación** — W3C Trace Context, el formato de `traceparent`:
   [w3.org/TR/trace-context/](https://www.w3.org/TR/trace-context/).
6. **Material de referencia** — Google SRE Book, «Service Level Objectives», la base de §7:
   [sre.google/sre-book/service-level-objectives/](https://sre.google/sre-book/service-level-objectives/).
7. **Fuente primaria** — Brendan Gregg, «The USE Method», para las métricas de recursos:
   [brendangregg.com/usemethod.html](https://www.brendangregg.com/usemethod.html).
8. **Charla** — GOTO Conferences, «Observability: The Hard Parts». Útil por la parte de coste y
   muestreo, que casi nunca se trata.

---

## 🧠 Preguntas

1. ¿Qué pregunta responde cada uno de los tres pilares? 🟢
2. Define traza, span y contexto. 🟢
3. ¿Qué encabezado propaga el contexto de traza y qué lleva dentro? 🟢
4. Enumera los cuatro sitios donde se pierde el contexto. 🟢
5. ¿Qué son RED y USE? 🟢
6. Diferencia entre muestreo por cabeza y por cola. 🟢
7. ¿Qué es el presupuesto de error y para qué se usa? 🟢
8. ¿Por qué el colector de OpenTelemetry desacopla del proveedor? 🟡
9. ¿Por qué la media de latencia es una métrica engañosa? 🟡
10. ¿Por qué una traza muestreada a medias no sirve de nada? 🟡
11. ¿Por qué el contexto no cruza a un pool de hilos, y qué se hace? 🟡
12. ¿Qué diferencia hay entre el contexto de traza y la cancelación en Go, y por qué importa? 🟡
13. ¿Qué campos fijos pondrías en el log estructurado del chassis? 🟡
14. ¿Qué mecanismo de propagación de contexto usa cada plataforma y dónde se pierde en cada una? 🟡
15. La traza se corta al publicar un evento. Explica la causa y la corrección, en ambos lados. 🟠
16. ¿Qué muestreo configurarías en un sistema con mucho tráfico y pocos errores? 🟠
17. ¿Cómo darías a un usuario un "código de incidencia" útil? 🟠
18. Los costes de observabilidad se han multiplicado por tres. ¿Qué revisas y en qué orden? 🟠
19. Define un SLI y un SLO para la confirmación de pedidos, y justifica los números. 🟠
20. ¿Cómo instrumentarías un consumidor de eventos para que su trabajo aparezca en la traza del
    productor? 🟠
21. ¿Qué métricas de los mecanismos de resiliencia añadirías a los paneles? 🟠
22. Diseña la observabilidad completa de la confirmación de pedido: qué se mide, qué se traza, qué
    se registra y qué alertas hay. 🔴
23. Diagnostica: el p99 de una ruta sube, todas las dependencias reportan latencia normal, y las
    trazas muestran un hueco de 400 ms sin span. Da tres hipótesis. 🔴
24. Diseña la política de muestreo y retención del sistema, con su justificación de coste. 🔴
25. Un equipo tiene logs excelentes y ninguna traza. Escribe el plan de adopción de trazas en seis
    semanas, con el orden y el criterio. 🔴

---

**Anterior:** [`03` — Resiliencia en la práctica](03-resiliencia-en-la-practica.md) · **Siguiente:**
[`05` — Service mesh y sidecar](05-service-mesh-y-sidecar.md) · **Relacionado:**
[`02-comunicacion/06`](../02-comunicacion/06-mensajeria-y-eventos.md) ·
[`01-fundamentos-y-descomposicion/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md)

**Taller, opcional:** [`06/07` — Observabilidad de extremo a extremo](../06-talleres/07-observabilidad-de-extremo-a-extremo.md).
