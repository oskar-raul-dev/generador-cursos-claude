# db01 — El panorama y el DB-API 2.0

Código de la sección [`op077-db01-el-db-api.md`](../../op077-db01-el-db-api.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `dbapi.py` | El mismo DB-API contra sqlite3 y psycopg: marcadores, tipos devueltos y lo que hace el 'with' |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add "psycopg[binary]"

docker run -d --name aurea-pg -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 postgres:18.6
AUREA_PG="host=localhost dbname=postgres user=postgres password=aurea-local" python3 dbapi.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
