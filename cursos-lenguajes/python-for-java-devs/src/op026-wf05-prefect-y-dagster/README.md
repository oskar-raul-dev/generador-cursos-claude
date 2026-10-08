# wf05 — Prefect, Dagster y el *asset*

Código de la sección [`op026-wf05-prefect-y-dagster.md`](../../op026-wf05-prefect-y-dagster.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `noche_prefect.py` | La noche de Áurea en Prefect: funciones con decorador, reintentos y concurrencia |
| `noche_dagster.py` | La noche de Áurea en Dagster: assets que dependen de los assets que reciben |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add prefect dagster

python3 noche_prefect.py

python3 noche_dagster.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
