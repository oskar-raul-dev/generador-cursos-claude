"""La relación que en síncrono se toca y en asíncrono se espera: SQLAlchemy AsyncSession y Tortoise ORM."""

import asyncio

from sqlalchemy import ForeignKey, select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, selectinload
from tortoise import Tortoise, fields
from tortoise.models import Model


# ------------------------------------------------- SQLAlchemy asíncrono
class Base(DeclarativeBase):
    pass


class Plan(Base):
    __tablename__ = "plan"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    fases: Mapped[list["Fase"]] = relationship()


class Fase(Base):
    __tablename__ = "fase"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("plan.id"))
    valor: Mapped[int]


async def sqlalchemy_demo():
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine) as s:
        s.add(Plan(codigo="PL-001", fases=[Fase(valor=1_250_000), Fase(valor=800_000)]))
        await s.commit()
    async with AsyncSession(engine) as s:
        plan = (await s.scalars(select(Plan))).one()
        try:
            print("SQLAlchemy, perezoso:", sum(f.valor for f in plan.fases))
        except Exception as e:
            print(f"SQLAlchemy, perezoso: {type(e).__name__}: {str(e)[:70]}…")
    async with AsyncSession(engine) as s:
        plan = (await s.scalars(select(Plan).options(selectinload(Plan.fases)))).one()
        print("SQLAlchemy, selectinload:", sum(f.valor for f in plan.fases))
    await engine.dispose()


# ------------------------------------------------- Tortoise ORM
class TPlan(Model):
    codigo = fields.CharField(max_length=10)

    class Meta:
        table = "tplan"


class TFase(Model):
    plan = fields.ForeignKeyField("models.TPlan", related_name="fases")
    valor = fields.IntField()

    class Meta:
        table = "tfase"


async def tortoise_demo():
    await Tortoise.init(db_url="sqlite://:memory:", modules={"models": ["__main__"]})
    await Tortoise.generate_schemas()
    plan = await TPlan.create(codigo="PL-001")
    await TFase.create(plan=plan, valor=1_250_000)
    await TFase.create(plan=plan, valor=800_000)
    loaded = await TPlan.get(codigo="PL-001")
    print("Tortoise, relación sin esperar:", type(loaded.fases).__name__)
    print("Tortoise, await .all():", sum(f.valor for f in await loaded.fases.all()))
    prefetched = await TPlan.get(codigo="PL-001").prefetch_related("fases")
    print("Tortoise, prefetch_related:", sum(f.valor for f in prefetched.fases))
    await Tortoise.close_connections()


asyncio.run(sqlalchemy_demo())
asyncio.run(tortoise_demo())
