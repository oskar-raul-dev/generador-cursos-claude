# gi04 — Ráster y teledetección

Código de la sección [`op160-gi04-raster.md`](../../op160-gi04-raster.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `raster.py` | Ráster con rasterio y rioxarray: un modelo de elevación sintético, la altura de cada sede, el NDVI y la reproyección |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add rasterio==1.5.2 rioxarray==0.23.0 xarray==2026.9.0 pyproj==3.8.0 numpy==2.5.3

uv run raster.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
