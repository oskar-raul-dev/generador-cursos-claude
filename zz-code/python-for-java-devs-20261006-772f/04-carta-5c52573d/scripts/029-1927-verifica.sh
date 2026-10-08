# rescatado de la sesión 5c52573d, 2026-10-05T19:27:52Z · Probe Pony ORM on Python 3.14
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore pony==0.7.20 >/dev/null 2>&1; python -c "
from pony.orm import *
db = Database(); 
class Plan(db.Entity):
    codigo = Required(str); sede = Required(str); fases = Set(\"Fase\")
class Fase(db.Entity):
    plan = Required(Plan); valor = Required(int); estado = Required(str)
db.bind(provider=\"sqlite\", filename=\":memory:\"); db.generate_mapping(create_tables=True)
with db_session:
    p = Plan(codigo=\"PL-1\", sede=\"Suba\"); Fase(plan=p, valor=5_000_000, estado=\"pendiente\")
    q = select(p for p in Plan if p.sede == \"Suba\" and sum(f.valor for f in p.fases if f.estado == \"pendiente\") > 4_000_000)
    print(q[:]); print(q.get_sql())
" 2>&1 | tail -8'
