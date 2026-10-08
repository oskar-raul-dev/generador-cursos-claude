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
