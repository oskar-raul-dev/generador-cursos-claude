# gi05 — Rutas y direcciones

Código de la sección [`op161-gi05-rutas-y-direcciones.md`](../../op161-gi05-rutas-y-direcciones.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `rutas.py` | Distancia recta contra distancia por la red: un barrio sintético con un río, un solo puente y dos calles de un sentido |
| `geocodificar.py` | Geocodificar con Nominatim respetando su política: un agente propio, una petición por segundo y caché |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add osmnx==2.1.1 networkx==3.7 pyproj==3.8.0 scipy==1.18.1 geopy==2.5.0

uv run rutas.py

uv run geocodificar.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
