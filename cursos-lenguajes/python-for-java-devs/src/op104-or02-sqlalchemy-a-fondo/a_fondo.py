"""SQLAlchemy 2.1: estrategias de carga contadas, hybrid_property en Python y en SQL, y un tipo Pesos."""

import random
from decimal import Decimal

from sqlalchemy import ForeignKey, Integer, create_engine, event, func, select
from sqlalchemy.exc import InvalidRequestError
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import (DeclarativeBase, Mapped, Session, joinedload, mapped_column, raiseload,
                            relationship, selectinload)
from sqlalchemy.types import TypeDecorator


class Pesos(TypeDecorator):
    """Entero en la base, Decimal en Python: nadie divide montos como float."""
    impl = Integer
    cache_ok = True

    def process_bind_param(self, value, dialect):
        return None if value is None else int(value)

    def process_result_value(self, value, dialect):
        return None if value is None else Decimal(value)


class Base(DeclarativeBase):
    pass


class Plan(Base):
    __tablename__ = "plan"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    sede: Mapped[str]
    fases: Mapped[list["Fase"]] = relationship(back_populates="plan")

    @hybrid_property
    def saldo(self) -> Decimal:                       # en Python, sobre el objeto
        return sum((f.valor for f in self.fases if f.estado == "pendiente"), Decimal(0))

    @saldo.inplace.expression
    @classmethod
    def _saldo_sql(cls):                              # en SQL, como subconsulta correlacionada
        return (select(func.coalesce(func.sum(Fase.valor), 0))
                .where(Fase.plan_id == cls.id, Fase.estado == "pendiente").scalar_subquery())


class Fase(Base):
    __tablename__ = "fase"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("plan.id"))
    valor: Mapped[Decimal] = mapped_column(Pesos)
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

for label, option in [("lazy (por defecto)", None), ("selectinload", selectinload(Plan.fases)),
                      ("joinedload", joinedload(Plan.fases)), ("raiseload", raiseload(Plan.fases))]:
    statements.clear()
    with Session(engine) as s:
        q = select(Plan).where(Plan.sede == "Suba")
        q = q.options(option) if option is not None else q
        try:
            total = sum(p.saldo for p in s.scalars(q).unique())
            print(f"{label:<20} {len(statements):>2} sentencias · saldo de Suba ${total:,}")
        except InvalidRequestError as e:
            print(f"{label:<20} {len(statements):>2} sentencias · {type(e).__name__}: {str(e)[:60]}…")

statements.clear()
with Session(engine) as s:                            # la misma regla, ahora en SQL
    top = s.execute(select(Plan.codigo, Plan.saldo).where(Plan.sede == "Suba").order_by(Plan.saldo.desc()).limit(3)).all()
print(f"hybrid en SQL        {len(statements):>2} sentencia  · {top}")
