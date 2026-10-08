# vz02 — La gramática: Altair, plotnine, Great Tables

Código de la sección [`op112-vz02-la-gramatica.md`](../../op112-vz02-la-gramatica.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `gramatica.py` | El mismo recaudo en la gramática: Altair (una palabra cambia la marca), plotnine, y la tabla con Great Tables |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add altair vl-convert-python plotnine great-tables pandas

python3 gramatica.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
