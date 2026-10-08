# wf02 — Colas de tareas

Código de la sección [`op023-wf02-colas-de-tareas.md`](../../op023-wf02-colas-de-tareas.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `tareas.py` | La tarea: generar el PDF de la liquidación de una sede. Idempotente por diseño |
| `encolar_rq.py` | Encola las liquidaciones en RQ, con reintentos, y espera los resultados |
| `cola_huey.py` | La misma tarea en Huey, con SQLite como broker: un archivo, ningún servidor |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add rq huey

docker run -d --name valkey -p 6379:6379 valkey/valkey:9.0.6-alpine
rq worker liquidaciones --url redis://127.0.0.1:6379 --with-scheduler &   # el planificador hace los reintentos con espera
python3 encolar_rq.py

huey_consumer cola_huey.huey --workers 2 &
python3 -c "
from cola_huey import build_settlement_pdf
results = [build_settlement_pdf(s, '2026T4') for s in ('Suba', 'Zipaquirá')]
print([r.get(blocking=True, timeout=30) for r in results])"
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
