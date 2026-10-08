# db08 — Columnar ancho: Cassandra y ScyllaDB

Código de la sección [`op084-db08-cassandra.md`](../../op084-db08-cassandra.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `mensajeria.py` | Cassandra desde Python: la tabla diseñada para una consulta, y las consultas que no acepta |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add cassandra-driver

docker run -d --name aurea-cassandra -e MAX_HEAP_SIZE=512M -e HEAP_NEWSIZE=128M -p 9042:9042 cassandra:5.0
AUREA_CASSANDRA=127.0.0.1 python3 mensajeria.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
