# ⚡ pr05 — Tiempo real: WebSocket y SSE

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

En la recepción de cada sede hay una pantalla con la agenda del día. Hoy se refresca cada treinta segundos, y entre refresco y refresco dos recepcionistas
pueden ofrecerle el mismo turno a dos pacientes distintos, una por WhatsApp y otra en persona. Lo que se quiere es que la pantalla se entere **en el
momento** en que un turno se toma.

Hay tres formas de que el servidor le avise al navegador, y la pregunta honesta de esta sección es cuál se necesita de verdad. **SSE** (*Server-Sent
Events*): una respuesta HTTP que no termina, por la que el servidor manda eventos; solo de servidor a cliente, y con reconexión y reanudación incluidas.
**WebSocket**: un canal en los dos sentidos. **Sondeo largo**: el cliente pregunta y el servidor demora la respuesta hasta tener algo. Para la pantalla de
la agenda, que casi solo escucha, la respuesta suele ser la más simple.

---

## 🧠 2. El modelo

| | SSE | WebSocket | Sondeo largo |
|---|---|---|---|
| Sentido | Servidor → cliente | **Los dos** | Servidor → cliente |
| Sobre | HTTP normal | Protocolo propio (`ws://`), tras un *upgrade* de HTTP | HTTP normal |
| Reconexión | **Automática en el navegador**, con `Last-Event-ID` | A mano | A mano |
| *Proxies* y balanceadores | Funciona como HTTP (con *buffering* apagado) | Necesitan soportar el *upgrade* | Funciona |
| En Python | `sse-starlette` 3.5.0 con FastAPI | `websockets` 17.2, o FastAPI | Cualquier framework |
| Para | Tableros, notificaciones, progreso | Chat, edición colaborativa, juegos | Cuando nada de lo anterior está disponible |

### Tu instinto de Java dice… y esta vez se equivoca

Con Spring, el instinto para "tiempo real" es WebSocket con STOMP, y este perfil lo usó para cosas que solo necesitaban avisos del servidor. Un WebSocket es
un canal bidireccional con su propio protocolo, su propia reconexión (que hay que escribir) y su propia configuración en cada *proxy*. Si el cliente no
necesita mandar nada por ese canal, SSE da lo mismo con HTTP normal y la reconexión hecha.

---

## 💻 3. El ejemplo que corre

```bash
uv add fastapi uvicorn sse-starlette websockets httpx
```

`tiempo_real.py`:

```python
"""SSE con reanudación por Last-Event-ID, y un WebSocket donde tomar un turno avisa a todos."""

import asyncio
import json

import httpx
import uvicorn
import websockets
from fastapi import FastAPI, Request
from sse_starlette.sse import EventSourceResponse

EVENTS = [{"id": i, "turno": f"{8 + i // 3:02d}:{(i % 3) * 20:02d}", "estado": "ocupado"} for i in range(1, 7)]
app = FastAPI()


@app.get("/agenda/eventos")
async def agenda_events(request: Request):
    last = int(request.headers.get("last-event-id", 0))           # reanudar donde quedó el cliente

    async def stream():
        for event in EVENTS:
            if event["id"] > last:
                yield {"id": str(event["id"]), "event": "turno", "data": json.dumps(event)}
                await asyncio.sleep(0.01)

    return EventSourceResponse(stream())


async def read_sse(client: httpx.AsyncClient, last_id: int | None, stop_after: int) -> list[str]:
    headers = {"Last-Event-ID": str(last_id)} if last_id else {}
    seen = []
    async with client.stream("GET", "/agenda/eventos", headers=headers) as response:
        async for line in response.aiter_lines():
            if line.startswith("id:"):
                seen.append(line.split(":", 1)[1].strip())
                if len(seen) == stop_after:
                    break                                          # se corta la conexión, como un Wi-Fi que falla
    return seen


# ------------------------------------------------- WebSocket: dos recepciones, un turno
connected = set()


async def reception(ws):
    connected.add(ws)
    try:
        async for message in ws:
            websockets.broadcast(connected, f"turno {message.split()[-1]} ocupado")
    finally:
        connected.discard(ws)


async def main():
    server = uvicorn.Server(uvicorn.Config(app, host="127.0.0.1", port=8131, log_level="error"))
    task = asyncio.create_task(server.serve())
    while not server.started:
        await asyncio.sleep(0.05)
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8131") as client:
        first = await read_sse(client, None, stop_after=3)
        print("SSE, primera conexión (cortada):", first)
        print("SSE, reconexión con Last-Event-ID:", await read_sse(client, int(first[-1]), stop_after=99))
    server.should_exit = True
    await task

    async with websockets.serve(reception, "127.0.0.1", 8132):
        async with websockets.connect("ws://127.0.0.1:8132") as centro, websockets.connect("ws://127.0.0.1:8132") as chapinero:
            await centro.send("tomar 09:00")
            print("WebSocket, recepción Centro recibe:   ", await centro.recv())
            print("WebSocket, recepción Chapinero recibe:", await chapinero.recv())


asyncio.run(main())
```

```bash
python3 tiempo_real.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
SSE, primera conexión (cortada): ['1', '2', '3']
SSE, reconexión con Last-Event-ID: ['4', '5', '6']
WebSocket, recepción Centro recibe:    turno 09:00 ocupado
WebSocket, recepción Chapinero recibe: turno 09:00 ocupado
```

**Detalles con intención**

- **`id:` en cada evento SSE** es lo que hace posible la reanudación: el navegador recuerda el último y, al reconectarse solo, lo manda en `Last-Event-ID`. El
  servidor sigue desde ahí y no se pierde ningún turno durante el corte. En el ejemplo, el cliente de Python lo hace a mano para mostrarlo.
- **`websockets.broadcast`** manda el mismo mensaje a todas las conexiones: la recepción que tomó el turno y las demás se enteran a la vez.
- **El WebSocket se usa porque el cliente manda algo** ("tomar 09:00"). Si las recepciones tomaran los turnos con un `POST` normal y solo escucharan cambios,
  SSE alcanzaría.
- **Los puertos 8131 y 8132** son locales de la prueba; en la casa, los dos protocolos pasan por el *proxy* inverso, que tiene que tener el *buffering*
  apagado para SSE y el *upgrade* habilitado para WebSocket.

---

## ⚠️ 4. Lo que se rompe

**El *proxy* que guarda la respuesta.** Nginx, por defecto, guarda en *buffer* la respuesta del servidor antes de mandarla: los eventos SSE llegan todos
juntos, tarde. Se apaga con `X-Accel-Buffering: no` (que `sse-starlette` manda) o en la configuración del *proxy*.

**El WebSocket sin reconexión.** Cuando el Wi-Fi de la recepción se corta, el WebSocket se cierra y nadie lo vuelve a abrir. La reconexión, con espera creciente
y sin perder lo que pasó mientras tanto, se escribe a mano: es el trabajo que SSE trae hecho.

**Un evento por conexión, para cien pantallas.** Cada pantalla es una conexión abierta permanente al servidor. Con un proceso asíncrono, miles de conexiones
están bien; con un servidor síncrono de un hilo por petición, cien pantallas son cien hilos ocupados para siempre.

**El estado solo en memoria.** El conjunto `connected` vive en un proceso. Con dos procesos detrás de un balanceador, una recepción conectada al proceso A no se
entera de lo que pasa en el B. El aviso pasa por algo compartido (Valkey pub/sub, `db06`; NATS, `db14`).

---

## ⚖️ 5. Cuándo NO usarlo

**WebSocket para un tablero.** Por todo lo de arriba: SSE, o un sondeo cada pocos segundos si la demora importa poco.

**Tiempo real cuando nadie lo nota.** Si la agenda cambia diez veces por hora, un refresco cada diez segundos es tiempo real para una persona, y no necesita
conexiones abiertas.

**SSE desde el navegador con muchos dominios en HTTP/1.1.** Los navegadores limitan las conexiones por dominio en HTTP/1.1 (seis); muchas pestañas con SSE las
agotan. Con HTTP/2 desaparece el problema.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas cómo el servidor supo desde dónde seguir.
2. Abre `/agenda/eventos` en un navegador con `EventSource` (diez líneas de JavaScript). **Criterio:** los eventos aparecen, y al cortar la red se reconecta solo.
3. Conecta una tercera recepción al WebSocket. **Criterio:** también recibe el aviso.

**🟡 Intermedio (4–6)**

4. Haz que SSE mande un evento `ping` cada 15 segundos. **Criterio:** explicas para qué sirve frente a un *proxy* con tiempo de inactividad.
5. Escribe la reconexión del cliente WebSocket con espera creciente. **Criterio:** reiniciar el servidor no deja al cliente desconectado.
6. Reemplaza el WebSocket por un `POST /turnos` y el aviso por SSE. **Criterio:** el mismo resultado, y cuántas líneas cambiaron.

**🟠 Difícil (7–9)**

7. Corre dos procesos del servidor y pasa los avisos por Valkey pub/sub (`db06`). **Criterio:** una recepción en cada proceso recibe el aviso.
8. Pon Nginx delante y comprueba el *buffering* de SSE con y sin `X-Accel-Buffering`. **Criterio:** la diferencia en el tiempo de llegada de los eventos.
9. Mide cuántas conexiones SSE abiertas aguanta un proceso de Uvicorn en tu máquina. **Criterio:** el número y qué se agota primero.

**🔴 Muy difícil (10)**

10. Diseña la pantalla de agenda en tiempo real de las sedes. **Criterio:** una página. *Rúbrica:* (a) SSE, WebSocket o sondeo, con su razón; (b) qué pasa cuando
    se corta la red; (c) cómo funciona con varios procesos; (d) cuántas pantallas y conexiones hay en el peor caso.

---

## 📚 7. Referencias

**Documentación oficial**

- SSE, la especificación (WHATWG): https://html.spec.whatwg.org/multipage/server-sent-events.html
- `websockets`: https://websockets.readthedocs.io/en/stable/
- `sse-starlette`: https://github.com/sysid/sse-starlette

**Orden de lectura sugerido:** la sección de SSE de la especificación de HTML (corta, y explica `Last-Event-ID`); después la guía de `websockets`.

---

## 🚀 8. Cierre

Para avisar del servidor al cliente, SSE es HTTP normal con reconexión y reanudación incluidas; WebSocket es para cuando el cliente también habla por el mismo
canal, y su reconexión se escribe a mano. Los dos necesitan un *proxy* configurado y, con varios procesos, un canal compartido para los avisos.

**La señal de que quedó bien:** *"Dos recepciones intentaron dar el turno de las 9:00 al mismo tiempo, y la segunda lo vio ocupado antes de terminar de
escribir."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-05 -m "op pr05 cerrada: SSE con reanudación y WebSocket con difusión"
> ```
>
> Los commits llevan su prefijo (`op pr05: …`) y los de ejercicio su número
> (`op pr05 ej07: …`).
