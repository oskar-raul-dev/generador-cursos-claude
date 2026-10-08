# db11 — Vectorial: pgvector y Qdrant

Código de la sección [`op087-db11-vectorial.md`](../../op087-db11-vectorial.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `vecinos.py` | Buscar vecinos en pgvector y Qdrant: exacto contra aproximado, y el recall de cada uno |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add "psycopg[binary]" pgvector qdrant-client numpy

docker run -d --name aurea-pgv -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 pgvector/pgvector:0.8.6-pg18
docker run -d --name aurea-qdrant -p 6333:6333 qdrant/qdrant:v1.19.1
AUREA_PGV="host=localhost dbname=postgres user=postgres password=aurea-local" \
AUREA_QDRANT=http://localhost:6333 python3 vecinos.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
