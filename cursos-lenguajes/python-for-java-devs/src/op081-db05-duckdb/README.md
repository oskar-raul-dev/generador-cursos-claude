# db05 — DuckDB

Código de la sección [`op081-db05-duckdb.md`](../../op081-db05-duckdb.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `abonos.py` | DuckDB: generar un millón de abonos, consultarlos en CSV y en Parquet, y el bloqueo del archivo |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add duckdb

python3 abonos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
