# db09 — Grafo: Neo4j

Código de la sección [`op085-db09-neo4j.md`](../../op085-db09-neo4j.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `derivaciones.py` | Neo4j desde Python: las derivaciones entre sedes, el índice que hace barato el recorrido, y los tipos |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add neo4j

docker run -d --name aurea-neo4j -e NEO4J_AUTH=neo4j/aurea-local-2026 -p 7687:7687 neo4j:2026.09.0-community
AUREA_NEO4J=neo4j://localhost:7687 python3 derivaciones.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
