# pr05 — Tiempo real: WebSocket y SSE

Código de la sección [`op127-pr05-tiempo-real.md`](../../op127-pr05-tiempo-real.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `tiempo_real.py` | SSE con reanudación por Last-Event-ID, y un WebSocket donde tomar un turno avisa a todos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add fastapi uvicorn sse-starlette websockets httpx

python3 tiempo_real.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
