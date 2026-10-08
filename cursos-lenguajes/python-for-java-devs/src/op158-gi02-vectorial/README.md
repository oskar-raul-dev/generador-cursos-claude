# gi02 — Vectorial: shapely, geopandas, pyproj

Código de la sección [`op158-gi02-vectorial.md`](../../op158-gi02-vectorial.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `vectorial.py` | Pacientes sintéticos contra las diez sedes con geopandas: la sede más cercana, el radio de 5 km y el CRS que viaja o no |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add geopandas==1.2.0 pyogrio==0.13.0 shapely==2.1.2 pyproj==3.8.0

uv run vectorial.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
