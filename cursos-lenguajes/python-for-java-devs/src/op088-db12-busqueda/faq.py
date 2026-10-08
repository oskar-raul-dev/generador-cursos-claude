"""Las respuestas de WhatsApp en OpenSearch y Meilisearch: el analizador, el tipeo y la visibilidad."""

import os
import time

import meilisearch
from opensearchpy import OpenSearch

FAQ = [
    {"id": 1, "texto": "La limpieza dura unos cuarenta minutos y no duele."},
    {"id": 2, "texto": "Los controles de ortodoncia son cada cuatro semanas."},
    {"id": 3, "texto": "Puedes pagar el tratamiento a cuotas sin interés hasta en doce meses."},
    {"id": 4, "texto": "Las limpiezas se recomiendan cada seis meses."},
    {"id": 5, "texto": "Si se despega un bracket, escríbenos y te damos cita de urgencia."},
]

# ------------------------------------------------- OpenSearch
os_client = OpenSearch(hosts=[{"host": os.environ.get("AUREA_OPENSEARCH", "search"), "port": 9200}], use_ssl=False)
for _ in range(120):
    try:
        if os_client.cluster.health(wait_for_status="yellow", timeout="1s"):
            break
    except Exception:
        time.sleep(2)
print("OpenSearch", os_client.info()["version"]["number"])

for analyzer in ("standard", "spanish"):
    tokens = os_client.indices.analyze(body={"analyzer": analyzer, "text": "Las limpiezas no duelen"})["tokens"]
    print(f"  analizador {analyzer:<8} →", [t["token"] for t in tokens])

os_client.indices.delete(index="faq", ignore_unavailable=True)
os_client.indices.create(index="faq", body={"mappings": {"properties": {
    "texto": {"type": "text", "analyzer": "spanish", "fields": {"std": {"type": "text", "analyzer": "standard"}}}}}})
for doc in FAQ:
    os_client.index(index="faq", id=doc["id"], body=doc)


def hits(field: str, text: str, **extra) -> list[int]:
    query = {"match": {field: {"query": text, **extra}}}
    return [int(h["_id"]) for h in os_client.search(index="faq", body={"query": query})["hits"]["hits"]]


print("  recién indexado, 'limpieza':", hits("texto", "limpieza"))
os_client.indices.refresh(index="faq")
print("  después del refresh:        ", hits("texto", "limpieza"))
print("  'limpiezas' con standard:   ", hits("texto.std", "limpiezas"))
print("  'limpiesa' sin fuzziness:   ", hits("texto", "limpiesa"))
print("  'limpiesa' con fuzziness:   ", hits("texto", "limpiesa", fuzziness="AUTO"))

# ------------------------------------------------- Meilisearch
meili = meilisearch.Client(os.environ.get("AUREA_MEILI", "http://meili:7700"))
for _ in range(60):
    try:
        meili.health()
        break
    except Exception:
        time.sleep(1)
print("Meilisearch", meili.get_version()["pkgVersion"])
index = meili.index("faq")
task = index.add_documents(FAQ, primary_key="id")
print("  tarea encolada:", task.status, "· resultados ya:", [h["id"] for h in index.search("limpieza")["hits"]])
meili.wait_for_task(task.task_uid)
print("  tras la tarea, 'limpiesa':  ", [h["id"] for h in index.search("limpiesa")["hits"]])
print("  'cuotas sin interes':       ", [h["id"] for h in index.search("cuotas sin interes")["hits"]])
