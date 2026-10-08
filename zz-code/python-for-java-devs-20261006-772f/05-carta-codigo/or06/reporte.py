"""El reporte desde SQL en archivos (aiosql) y el mismo SQL analizado y traducido (sqlglot)."""

import random
import sqlite3

import aiosql
import sqlglot
from sqlglot import exp

queries = aiosql.from_path("cartera.sql", "sqlite3")
conn = sqlite3.connect(":memory:")
queries.crear_tablas(conn)

random.seed(2)
for i in range(60):
    plan_id = queries.nuevo_plan(conn, codigo=f"PL-{i:03d}", sede=random.choice(["Suba", "Centro", "Kennedy"]))
    for _ in range(4):
        queries.nueva_fase(conn, plan_id=plan_id, valor=random.randrange(200_000, 3_000_000, 50_000),
                           estado=random.choice(["pagada", "pendiente"]))
conn.commit()

print("funciones generadas:", [q for q in queries.available_queries if not q.endswith("_cursor")][:4])
print("los tres con más saldo:", list(queries.saldos_por_sede(conn, sede="Suba", n=3)))   # aiosql 15: un generador

sql = queries.saldos_por_sede.sql
tree = sqlglot.parse_one(sql.replace(":sede", "'Suba'").replace(":n", "3"), read="sqlite")
print("tablas que toca:", sorted({t.name for t in tree.find_all(exp.Table)}))
for dialect in ("postgres", "tsql"):
    print(f"en {dialect}:", sqlglot.transpile(tree.sql("sqlite"), read="sqlite", write=dialect)[0])
