# ed03 — Notebooks para explicar

Código de la sección [`op174-ed03-notebooks-para-explicar.md`](../../op174-ed03-notebooks-para-explicar.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `estado_oculto.py` | El estado oculto de un notebook: se fabrica, se detecta, se reejecuta de arriba abajo, y se compara con marimo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add nbformat==5.11.1 nbclient==0.11.0 ipykernel==7.4.0 jupytext==1.19.6 marimo==0.25.1

uv run estado_oculto.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
