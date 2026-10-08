# 📡 pr02 — gRPC y Protobuf

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 2 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El operador de la agenda en línea expone su API en gRPC: es un equipo Java, con servicios internos en gRPC desde hace años, y no
piensa agregar un REST para Áurea. El servicio tiene dos operaciones: consultar la disponibilidad de una sede (una pregunta, una
respuesta) y suscribirse a los eventos de citas de una sede (una pregunta, un flujo de respuestas que no termina). Áurea tiene que
hablarle desde Python, y probarlo con un servidor propio.

gRPC es el terreno donde el equipo Java ya vive, y en Python se usa con **`grpcio`** y el código que genera **`grpcio-tools`** desde el
`.proto`. Lo que este perfil ya sabe de gRPC en Java vale igual; lo que la sección agrega es cómo se ve en Python, y las dos cosas que
más cuestan en producción: **los plazos** (*deadlines*), sin los cuales una llamada a un servidor lento espera para siempre, y **los
códigos de estado**, que reemplazan a los de HTTP.

---

## 🧠 2. El modelo

| Tipo de llamada | En el `.proto` | En Python (cliente) | Ejemplo |
|---|---|---|---|
| Unaria | `rpc X(Req) returns (Resp)` | `stub.X(req, timeout=…)` | Disponibilidad de una sede |
| *Streaming* del servidor | `rpc X(Req) returns (stream Resp)` | `for r in stub.X(req): …` | Eventos de citas |
| *Streaming* del cliente | `rpc X(stream Req) returns (Resp)` | `stub.X(iter(reqs))` | Subir un lote |
| Bidireccional | `rpc X(stream Req) returns (stream Resp)` | Iteradores en los dos sentidos | Chat, sincronización |

| Biblioteca | Versión | Nota |
|---|---|---|
| `grpcio` | 1.84.0 | El *runtime* oficial |
| `grpcio-tools` | 1.84.0 | `protoc` y el generador de código para Python |
| `protobuf` | 7.36.2 | Los mensajes |
| `betterproto` | 1.2.5 💤 | Generador alternativo con *dataclasses*; la versión estable es de 2020 y la 2.0 sigue en beta |

### Esto sí funciona igual

El `.proto` es el mismo archivo para Java y Python; los números de campo, las reglas de compatibilidad (`pr01`), los códigos de estado
(`DEADLINE_EXCEEDED`, `UNAVAILABLE`, `NOT_FOUND`) y la semántica de los plazos son del protocolo. Un cliente Python habla con un servidor Java
sin saber que es Java.

---

## 💻 3. El ejemplo que corre

```bash
uv add grpcio grpcio-tools
```

`agenda.proto`:

```protobuf
syntax = "proto3";
package aurea.agenda;

message SedeRequest { string sede = 1; int32 demora_ms = 2; }
message Disponibilidad { string sede = 1; repeated string horas = 2; }
message EventoCita { string sede = 1; string tipo = 2; int32 secuencia = 3; }

service Agenda {
  rpc ConsultarDisponibilidad (SedeRequest) returns (Disponibilidad);
  rpc EventosDeSede (SedeRequest) returns (stream EventoCita);
}
```

```bash
python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. agenda.proto
```

`agenda.py` levanta un servidor de prueba y lo llama:

```python
"""Un servicio gRPC de prueba y su cliente: llamada unaria, streaming del servidor, plazos y su costo."""

import time
from concurrent import futures

import grpc

import agenda_pb2 as pb
import agenda_pb2_grpc as rpc


class Agenda(rpc.AgendaServicer):
    def ConsultarDisponibilidad(self, request, context):
        time.sleep(request.demora_ms / 1000)                       # para simular un servidor lento
        return pb.Disponibilidad(sede=request.sede, horas=["08:00", "08:20", "10:40"])

    def EventosDeSede(self, request, context):
        for i, kind in enumerate(["confirmada", "reprogramada", "cancelada"], start=1):
            yield pb.EventoCita(sede=request.sede, tipo=kind, secuencia=i)


server = grpc.server(futures.ThreadPoolExecutor(max_workers=8))
rpc.add_AgendaServicer_to_server(Agenda(), server)
port = server.add_insecure_port("127.0.0.1:0")
server.start()

with grpc.insecure_channel(f"127.0.0.1:{port}") as channel:
    stub = rpc.AgendaStub(channel)

    answer = stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba"), timeout=1)
    print("unaria:", answer.sede, list(answer.horas))

    print("streaming:", [(e.secuencia, e.tipo) for e in stub.EventosDeSede(pb.SedeRequest(sede="Suba"), timeout=2)])

    try:
        stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba", demora_ms=500), timeout=0.2)
    except grpc.RpcError as e:
        print("plazo de 0,2 s contra un servidor de 0,5 s:", e.code().name)

    start = time.perf_counter()
    for _ in range(500):
        stub.ConsultarDisponibilidad(pb.SedeRequest(sede="Suba"), timeout=1)
    print(f"500 llamadas unarias: {(time.perf_counter() - start) / 500 * 1000:.2f} ms por llamada")

server.stop(grace=None)
```

```bash
python3 agenda.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
unaria: Suba ['08:00', '08:20', '10:40']
streaming: [(1, 'confirmada'), (2, 'reprogramada'), (3, 'cancelada')]
plazo de 0,2 s contra un servidor de 0,5 s: DEADLINE_EXCEEDED
500 llamadas unarias: 0.53 ms por llamada
```

**Detalles con intención**

- **`timeout=` en cada llamada** es el plazo de gRPC: si la respuesta no llega a tiempo, la llamada termina con `DEADLINE_EXCEEDED` y el servidor
  se entera de que el cliente ya no espera (`context.is_active()`). Sin `timeout`, una llamada a un servidor colgado espera para siempre.
- **El *streaming* del servidor es un iterador**: el `for` recibe cada evento cuando llega. Un flujo que no termina se lee igual, en un hilo propio.
- **`add_insecure_port("127.0.0.1:0")`** pide un puerto libre y lo devuelve; sin TLS, solo para la prueba. Entre servicios, `grpc.ssl_channel_credentials`
  con la CA interna (`se06`).
- **El código generado son dos módulos**: `agenda_pb2` (los mensajes) y `agenda_pb2_grpc` (el servicio y el *stub*). Se generan en el CI, no se editan.

---

## ⚠️ 4. Lo que se rompe

**Llamadas sin plazo.** El error más caro de gRPC en producción: un servicio lento hace que todos sus clientes acumulen llamadas colgadas, y la caída se
propaga. Todo `stub.X(...)` lleva `timeout`.

**`grpcio` con `fork`.** El *runtime* de gRPC tiene hilos propios, y un proceso hijo creado con `fork` después de crear un canal hereda un estado roto. Con
`multiprocessing`, los canales se crean en cada proceso, después de arrancarlo (y en Python 3.14, el `forkserver` por defecto ayuda, `sy04`).

**Los mensajes de error que no cruzan.** Una excepción de Python en el servidor llega al cliente como `UNKNOWN` sin detalle. El servidor usa
`context.abort(grpc.StatusCode.NOT_FOUND, "sede inexistente")` para devolver un código y un mensaje útiles.

**El *proxy* que no habla HTTP/2.** gRPC usa HTTP/2; un balanceador o *proxy* viejo que solo entiende HTTP/1.1 corta las llamadas. Se verifica antes de
desplegar.

---

## ⚖️ 5. Cuándo NO usarlo

**Hacia el navegador.** Los navegadores no hablan gRPC directamente; hace falta gRPC-Web y un *proxy*. Para la interfaz de Patricia, REST.

**Si el otro lado no lo usa ya.** Introducir gRPC en un sistema sin servicios gRPC por una sola integración trae la generación de código, HTTP/2 y una
herramienta de depuración más (`grpcurl`), para una ventaja de rendimiento que en el volumen de Áurea no se nota.

**Para depurar a ojo.** Un mensaje binario no se lee con `curl`. Cuando ver los mensajes importa más que el rendimiento, JSON.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas el `DEADLINE_EXCEEDED` y el costo por llamada.
2. Haz que el servidor devuelva `NOT_FOUND` para una sede que no existe con `context.abort`. **Criterio:** el cliente recibe el código y el mensaje.
3. Llama sin `timeout` a un servidor con 3 segundos de demora. **Criterio:** describes cuánto espera el cliente.

**🟡 Intermedio (4–6)**

4. Agrega un *streaming* del cliente que suba un lote de citas. **Criterio:** el servidor responde con cuántas recibió.
5. En el servidor, revisa `context.is_active()` durante la demora y deja de trabajar si el cliente se fue. **Criterio:** una bitácora muestra que paró.
6. Usa `grpcurl` contra el servidor de prueba (con reflexión, `grpcio-reflection`). **Criterio:** listas los servicios y llamas uno desde la consola.

**🟠 Difícil (7–9)**

7. Haz el servidor en Java (o usa uno existente) y llámalo desde este cliente. **Criterio:** la misma salida.
8. Agrega TLS con la CA interna de `se06`. **Criterio:** el cliente sin la CA falla; con ella, funciona.
9. Mide el costo por llamada de gRPC contra un endpoint FastAPI equivalente con `httpx`. **Criterio:** la tabla, en la misma máquina.

**🔴 Muy difícil (10)**

10. Diseña la integración de Áurea con la agenda gRPC del operador. **Criterio:** una página. *Rúbrica:* (a) qué llamadas, con qué plazos; (b) qué pasa con
    cada código de estado; (c) cómo se consume el flujo de eventos sin perder ninguno (reconexión, secuencia); (d) dónde vive el `.proto` y quién lo
    actualiza.

---

## 📚 7. Referencias

**Documentación oficial**

- gRPC en Python, lo básico: https://grpc.io/docs/languages/python/basics/
- gRPC, plazos: https://grpc.io/docs/guides/deadlines/
- gRPC, códigos de estado: https://grpc.io/docs/guides/status-codes/

**Orden de lectura sugerido:** la guía de plazos (la que evita la caída en cascada); después la de lo básico en Python.

---

## 🚀 8. Cierre

Desde Python, gRPC es `grpcio` y el código que genera `grpcio-tools` desde el mismo `.proto` que usa el equipo Java. Llamadas unarias y flujos se escriben como
funciones e iteradores; todo lleva plazo; y los errores viajan como códigos de estado, no como excepciones. Es la forma de hablarle a un sistema que ya vive
en gRPC, no una razón para adoptarlo.

**La señal de que quedó bien:** *"La agenda del operador se cayó una mañana y nuestros procesos dieron `DEADLINE_EXCEEDED` en un segundo, en vez de colgarse."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-02 -m "op pr02 cerrada: gRPC desde Python, con flujos, plazos y códigos de estado"
> ```
>
> Los commits llevan su prefijo (`op pr02: …`) y los de ejercicio su número
> (`op pr02 ej07: …`).
