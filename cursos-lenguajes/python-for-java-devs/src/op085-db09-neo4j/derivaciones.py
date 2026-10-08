"""Neo4j desde Python: las derivaciones entre sedes, el índice que hace barato el recorrido, y los tipos."""

import os
import random
import time

from neo4j import GraphDatabase
from neo4j.exceptions import ServiceUnavailable

URI = os.environ.get("AUREA_NEO4J", "neo4j://neo4j:7687")
driver = GraphDatabase.driver(URI, auth=("neo4j", "aurea-local-2026"))
for _ in range(60):
    try:
        driver.verify_connectivity()
        break
    except ServiceUnavailable:
        time.sleep(2)

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
DERIVA = {"Suba": "Centro", "Zipaquirá": "Suba", "Soacha": "Kennedy"}           # quién deriva la fase 3 a quién
random.seed(3)
plans = []
for i in range(20_000):
    start = random.choice(SEDES)
    plans.append({"codigo": f"PL-{i:05d}", "inicia": start, "continua": DERIVA.get(start) if i % 2 else None})

driver.execute_query("MATCH (n) DETACH DELETE n")
driver.execute_query("UNWIND $sedes AS nombre CREATE (:Sede {nombre: nombre})", sedes=SEDES)
driver.execute_query("""
    UNWIND $plans AS p
    MATCH (i:Sede {nombre: p.inicia})
    CREATE (pl:Plan {codigo: p.codigo, creado: datetime('2026-09-01T10:00:00-05:00')})-[:INICIA_EN]->(i)
    WITH pl, p WHERE p.continua IS NOT NULL
    MATCH (c:Sede {nombre: p.continua})
    CREATE (pl)-[:CONTINUA_EN]->(c)
""", plans=plans)

# La pregunta de la liquidación: ¿a dónde deriva Suba, y cuántos planes?
records, summary, keys = driver.execute_query("""
    MATCH (:Sede {nombre: $sede})<-[:INICIA_EN]-(p:Plan)-[:CONTINUA_EN]->(d:Sede)
    RETURN d.nombre AS destino, count(p) AS planes
""", sede="Suba")
print("derivaciones de Suba:", [r.data() for r in records], f"en {summary.result_available_after} ms")

# El recorrido que empieza en un plan: sin índice, buscarlo examina todos.
LOOKUP = "PROFILE MATCH (p:Plan {codigo: $codigo})-[:INICIA_EN|CONTINUA_EN]->(s) RETURN s.nombre"


def db_hits(plan) -> int:
    return plan["dbHits"] + sum(db_hits(child) for child in plan.get("children", []))


_, before, _ = driver.execute_query(LOOKUP, codigo="PL-12345")
driver.execute_query("CREATE INDEX plan_codigo IF NOT EXISTS FOR (p:Plan) ON (p.codigo)")
driver.execute_query("CALL db.awaitIndexes()")
records, after, _ = driver.execute_query(LOOKUP, codigo="PL-12345")
print("sedes de PL-12345:", [r["s.nombre"] for r in records])
print("accesos a la base: sin índice", db_hits(before.profile), "· con índice", db_hits(after.profile))

# Los tipos: la fecha no es un datetime.
created = driver.execute_query("MATCH (p:Plan {codigo: 'PL-00001'}) RETURN p.creado AS c").records[0]["c"]
print("tipo de la fecha:", type(created).__module__ + "." + type(created).__name__, "→", repr(created.to_native()))
driver.close()
