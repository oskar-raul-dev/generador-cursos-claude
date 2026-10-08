"""El portal de franquiciados en GraphQL con Strawberry: el N+1 contado, y el DataLoader que lo corrige."""

import asyncio
import random
import sqlite3

import strawberry
from strawberry.dataloader import DataLoader

db = sqlite3.connect(":memory:")
db.executescript("""CREATE TABLE plan (id INTEGER PRIMARY KEY, codigo TEXT, sede TEXT);
                    CREATE TABLE fase (id INTEGER PRIMARY KEY, plan_id INTEGER, valor INTEGER);""")
random.seed(2)
for i in range(30):
    pid = db.execute("INSERT INTO plan (codigo, sede) VALUES (?, ?)",
                     (f"PL-{i:03d}", random.choice(["Suba", "Zipaquirá"]))).lastrowid
    db.executemany("INSERT INTO fase (plan_id, valor) VALUES (?, ?)",
                   [(pid, random.randrange(200_000, 3_000_000, 50_000)) for _ in range(4)])
queries: list[str] = []
db.set_trace_callback(queries.append)


async def load_phases(plan_ids: list[int]) -> list[list["Fase"]]:
    marks = ",".join("?" * len(plan_ids))
    rows = db.execute(f"SELECT plan_id, valor FROM fase WHERE plan_id IN ({marks})", plan_ids).fetchall()
    by_plan = {pid: [] for pid in plan_ids}
    for pid, valor in rows:
        by_plan[pid].append(Fase(valor=valor))
    return [by_plan[pid] for pid in plan_ids]


@strawberry.type
class Fase:
    valor: int


@strawberry.type
class Plan:
    id: strawberry.Private[int]
    codigo: str

    @strawberry.field
    async def fases(self, info: strawberry.Info) -> list[Fase]:
        if info.context["batch"]:
            return await info.context["phases"].load(self.id)
        return [Fase(valor=v) for (v,) in db.execute("SELECT valor FROM fase WHERE plan_id = ?", (self.id,))]


@strawberry.type
class Sede:
    nombre: str

    @strawberry.field
    def planes(self) -> list[Plan]:
        return [Plan(id=i, codigo=c) for i, c in db.execute("SELECT id, codigo FROM plan WHERE sede = ?", (self.nombre,))]


@strawberry.type
class Query:
    @strawberry.field
    def sedes(self) -> list[Sede]:
        return [Sede(nombre=n) for (n,) in db.execute("SELECT DISTINCT sede FROM plan ORDER BY sede")]


schema = strawberry.Schema(query=Query)
QUERY = "{ sedes { nombre planes { codigo fases { valor } } } }"


async def run(batch: bool):
    queries.clear()
    result = await schema.execute(QUERY, context_value={"batch": batch, "phases": DataLoader(load_fn=load_phases)})
    sedes = result.data["sedes"]
    total = sum(f["valor"] for s in sedes for p in s["planes"] for f in p["fases"])
    print(f"{'con' if batch else 'sin'} DataLoader: {len(queries):>2} consultas a la base · "
          f"{len(sedes)} sedes, {sum(len(s['planes']) for s in sedes)} planes · total ${total:,}")


asyncio.run(run(batch=False))
asyncio.run(run(batch=True))
print(schema.as_str().splitlines()[0:3])
