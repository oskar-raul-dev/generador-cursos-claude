# wf03 — Programación en proceso

Código de la sección [`op024-wf03-programacion-en-proceso.md`](../../op024-wf03-programacion-en-proceso.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `agenda_cache.py` | Dos réplicas con planificador propio: un trabajo por réplica y otro una sola vez en total |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add apscheduler

python3 agenda_cache.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
