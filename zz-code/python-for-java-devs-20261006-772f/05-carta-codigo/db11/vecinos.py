"""Buscar vecinos en pgvector y Qdrant: exacto contra aproximado, y el recall de cada uno."""

import os
import time

import numpy as np
import psycopg
from pgvector.psycopg import register_vector
from qdrant_client import QdrantClient, models

N, DIM, K = 50_000, 64, 10
rng = np.random.default_rng(42)
vectors = rng.normal(size=(N, DIM)).astype(np.float32)
queries = rng.normal(size=(50, DIM)).astype(np.float32)


def recall(found: list[list[int]], truth: list[list[int]]) -> float:
    return sum(len(set(f) & set(t)) for f, t in zip(found, truth)) / (K * len(truth))


# ------------------------------------------------- pgvector
dsn = os.environ.get("AUREA_PGV", "host=pgv dbname=postgres user=postgres password=aurea-local")
for _ in range(60):
    try:
        pg = psycopg.connect(dsn, autocommit=True)
        break
    except psycopg.OperationalError:
        time.sleep(1)
pg.execute("CREATE EXTENSION IF NOT EXISTS vector")
register_vector(pg)
pg.execute("DROP TABLE IF EXISTS respuesta")
pg.execute(f"CREATE TABLE respuesta (id int PRIMARY KEY, embedding vector({DIM}))")
with pg.cursor().copy("COPY respuesta (id, embedding) FROM STDIN WITH (FORMAT BINARY)") as copy:
    copy.set_types(["int4", "vector"])
    for i, v in enumerate(vectors):
        copy.write_row((i, v))


def pg_search(label: str) -> list[list[int]]:
    start = time.perf_counter()
    found = [[r[0] for r in pg.execute("SELECT id FROM respuesta ORDER BY embedding <-> %s LIMIT %s", (q, K))]
             for q in queries]
    print(f"  pgvector {label:<24} {(time.perf_counter() - start) / len(queries) * 1000:6.2f} ms por consulta", end="")
    return found


exact = pg_search("exacto (sin índice)")
print()
pg.execute("CREATE INDEX ON respuesta USING hnsw (embedding vector_l2_ops)")
for ef in (10, 40, 200):
    pg.execute(f"SET hnsw.ef_search = {ef}")
    print(f" · recall@{K} {recall(pg_search(f'HNSW, ef_search={ef}'), exact):.2f}")

# ------------------------------------------------- Qdrant
qd = QdrantClient(url=os.environ.get("AUREA_QDRANT", "http://qdrant:6333"), timeout=60)
if qd.collection_exists("respuesta"):
    qd.delete_collection("respuesta")
qd.create_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID),
                     optimizers_config=models.OptimizersConfigDiff(         # ver el detalle: sin esto, no hay HNSW que medir
                         indexing_threshold=1_000, default_segment_number=1, max_segment_size=1_000_000))
qd.upload_collection("respuesta", vectors=vectors, ids=range(N), batch_size=2_000)
while (info := qd.get_collection("respuesta")).status != models.CollectionStatus.GREEN or info.indexed_vectors_count < N:
    time.sleep(0.5)
print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "· segmentos:", info.segments_count)


def qd_search(label: str, **params) -> list[list[int]]:
    start = time.perf_counter()
    found = [[p.id for p in qd.query_points("respuesta", query=q, limit=K, search_params=models.SearchParams(**params)).points]
             for q in queries]
    print(f"  Qdrant   {label:<24} {(time.perf_counter() - start) / len(queries) * 1000:6.2f} ms por consulta", end="")
    return found


print(f" · recall@{K} {recall(qd_search('exacto', exact=True), exact):.2f}")
for ef in (10, 40, 200):
    print(f" · recall@{K} {recall(qd_search(f'HNSW, hnsw_ef={ef}', hnsw_ef=ef), exact):.2f}")
