# gi06 — Mapas como entregable

Código de la sección [`op162-gi06-mapas-como-entregable.md`](../../op162-gi06-mapas-como-entregable.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `mapa.py` | El mapa como entregable: agregar en hexágonos H3, suprimir las celdas chicas y entregar un HTML con folium |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add folium==0.20.0 h3==4.5.0 numpy==2.5.3

uv run mapa.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
