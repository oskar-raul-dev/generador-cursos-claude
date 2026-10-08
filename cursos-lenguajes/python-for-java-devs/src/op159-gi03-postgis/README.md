# gi03 — PostGIS desde Python

Código de la sección [`op159-gi03-postgis.md`](../../op159-gi03-postgis.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `compose.yaml` | Configuración del ejemplo |
| `vecindad.py` | PostGIS desde Python: los pacientes a menos de 5 km de cada sede, cuatro maneras, con su plan y su tiempo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
docker compose up -d
uv add "psycopg[binary]==3.3.6" shapely==2.1.2 pyproj==3.8.0

uv run vecindad.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
