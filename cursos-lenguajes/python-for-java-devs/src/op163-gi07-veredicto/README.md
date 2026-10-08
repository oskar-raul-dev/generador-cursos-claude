# gi07 — Veredicto: cuándo basta con lat y lon

Código de la sección [`op163-gi07-veredicto.md`](../../op163-gi07-veredicto.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `veredicto.py` | La misma pregunta en cuatro pilas: la sede más cercana y su distancia para 200.000 domicilios sintéticos |
| `pesos.sh` | Cuánto pesa instalar cada pila, en un directorio vacío por pila |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add numpy==2.5.3 geopandas==1.2.0 pyogrio==0.13.0 shapely==2.1.2 pyproj==3.8.0 duckdb==1.5.6 pandas==3.0.6

uv run veredicto.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
