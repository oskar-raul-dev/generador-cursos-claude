"""La misma consulta en los tres puntos del eje: SQL, constructor (PyPika, SQLAlchemy Core) y ORM."""

import random

from pypika import Order, Query, Table
from pypika import functions as fn
from sqlalchemy import ForeignKey, create_engine, event, func, select, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class Plan(Base):
    __tablename__ = "plan"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    sede: Mapped[str]
    fases: Mapped[list["Fase"]] = relationship(back_populates="plan")


class Fase(Base):
    __tablename__ = "fase"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("plan.id"))
    valor: Mapped[int]
    estado: Mapped[str]
    plan: Mapped[Plan] = relationship(back_populates="fases")


engine = create_engine("sqlite://")
Base.metadata.create_all(engine)
random.seed(2)
with Session(engine) as s:
    for i in range(60):
        plan = Plan(codigo=f"PL-{i:03d}", sede=random.choice(["Suba", "Centro", "Kennedy"]))
        plan.fases = [Fase(valor=random.randrange(200_000, 3_000_000, 50_000),
                           estado=random.choice(["pagada", "pendiente"])) for _ in range(4)]
        s.add(plan)
    s.commit()

statements = []
event.listen(engine, "before_cursor_execute", lambda *a: statements.append(a[2]))


def run(label, fn_):
    statements.clear()
    result = fn_()
    print(f"{label:<22} {len(statements):>2} sentencias → {result}")


# 1. SQL con parámetros
SQL = """SELECT p.codigo, sum(f.valor) AS saldo FROM plan p JOIN fase f ON f.plan_id = p.id
         WHERE p.sede = :sede AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC LIMIT 3"""
run("SQL", lambda: engine.connect().execute(text(SQL), {"sede": "Suba"}).all())

# 2. Constructor: PyPika arma el texto; SQLAlchemy Core arma y ejecuta
p, f = Table("plan"), Table("fase")
pypika_sql = (Query.from_(p).join(f).on(f.plan_id == p.id).select(p.codigo, fn.Sum(f.valor).as_("saldo"))
              .where((p.sede == "Suba") & (f.estado == "pendiente")).groupby(p.codigo)
              .orderby(fn.Sum(f.valor), order=Order.desc).limit(3))
print("PyPika genera:", str(pypika_sql)[:95], "…")
core = (select(Plan.codigo, func.sum(Fase.valor).label("saldo")).join(Fase)
        .where(Plan.sede == "Suba", Fase.estado == "pendiente")
        .group_by(Plan.codigo).order_by(func.sum(Fase.valor).desc()).limit(3))
run("SQLAlchemy Core", lambda: engine.connect().execute(core).all())


# 3. ORM: objetos con relaciones navegables
def orm():
    with Session(engine) as s:
        plans = s.scalars(select(Plan).where(Plan.sede == "Suba")).all()
        owed = {pl.codigo: sum(x.valor for x in pl.fases if x.estado == "pendiente") for pl in plans}
        return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


run("ORM, navegando", orm)
