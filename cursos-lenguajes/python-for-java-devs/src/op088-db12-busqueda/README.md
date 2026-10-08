# db12 — Búsqueda: OpenSearch y Meilisearch

Código de la sección [`op088-db12-busqueda.md`](../../op088-db12-busqueda.md), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.

| Archivo | Qué es |
|---|---|
| `faq.py` | Las respuestas de WhatsApp en OpenSearch y Meilisearch: el analizador, el tipeo y la visibilidad |

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
uv add opensearch-py meilisearch

docker run -d --name aurea-search -e discovery.type=single-node -e DISABLE_SECURITY_PLUGIN=true \
    -e DISABLE_INSTALL_DEMO_CONFIG=true -e OPENSEARCH_JAVA_OPTS="-Xms512m -Xmx512m" -p 9200:9200 \
    opensearchproject/opensearch:3.8.0
docker run -d --name aurea-meili -p 7700:7700 getmeili/meilisearch:v1.54.3
AUREA_OPENSEARCH=localhost AUREA_MEILI=http://localhost:7700 python3 faq.py
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
