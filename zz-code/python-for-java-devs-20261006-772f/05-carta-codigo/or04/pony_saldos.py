"""La consulta del track escrita como un generador de Python, el SQL que genera, y lo que no se puede traducir."""

import random

from pony.orm import Database, Required, Set, db_session, desc, select, sum as pony_sum

db = Database()


class Plan(db.Entity):
    codigo = Required(str)
    sede = Required(str)
    fases = Set("Fase")


class Fase(db.Entity):
    plan = Required(Plan)
    valor = Required(int)
    estado = Required(str)


db.bind(provider="sqlite", filename=":memory:")
db.generate_mapping(create_tables=True)

random.seed(2)
with db_session:
    for i in range(60):
        plan = Plan(codigo=f"PL-{i:03d}", sede=random.choice(["Suba", "Centro", "Kennedy"]))
        for _ in range(4):
            Fase(plan=plan, valor=random.randrange(200_000, 3_000_000, 50_000),
                 estado=random.choice(["pagada", "pendiente"]))

with db_session:
    query = select(
        (p.codigo, pony_sum(f.valor for f in p.fases if f.estado == "pendiente"))
        for p in Plan if p.sede == "Suba"
    ).order_by(desc(2))
    print("los tres con más saldo:", query[:3])
    print(query.get_sql())


def ends_in_3(code: str) -> bool:                      # simple: Pony la descompila y la mete en el SQL
    return code.endswith("3")


def has_a_3(code: str) -> bool:                         # con un bucle: no hay SQL que la represente
    for ch in code:
        if ch == "3":
            return True
    return False


with db_session:
    for check in (ends_in_3, has_a_3):
        try:
            q = select(p for p in Plan if check(p.codigo))
            print(f"\n{check.__name__}: {len(q[:])} planes ·", q.get_sql().splitlines()[-1])
        except Exception as e:
            print(f"\n{check.__name__}: {type(e).__name__}: {e}")
