"""La misma consulta en seis bibliotecas sobre la misma base: sentencias, tiempo y líneas."""

import inspect
import random
import sqlite3
import time

DB = "aurea.db"
setup = sqlite3.connect(DB)
setup.executescript("""
    DROP TABLE IF EXISTS fase; DROP TABLE IF EXISTS plan;
    CREATE TABLE plan (id INTEGER PRIMARY KEY, codigo TEXT, sede TEXT);
    CREATE TABLE fase (id INTEGER PRIMARY KEY, plan_id INTEGER REFERENCES plan(id), valor INTEGER, estado TEXT);
""")
random.seed(2)
for i in range(60):
    pid = setup.execute("INSERT INTO plan (codigo, sede) VALUES (?, ?)",
                        (f"PL-{i:03d}", random.choice(["Suba", "Centro", "Kennedy"]))).lastrowid
    for _ in range(4):
        setup.execute("INSERT INTO fase (plan_id, valor, estado) VALUES (?, ?, ?)",
                      (pid, random.randrange(200_000, 3_000_000, 50_000), random.choice(["pagada", "pendiente"])))
setup.commit()
setup.close()

traced: list[str] = []
trace = traced.append

# ------------------------------------------------- 1. sqlite3: SQL a mano
raw = sqlite3.connect(DB)
raw.set_trace_callback(trace)


def with_sqlite3():
    return raw.execute("""SELECT p.codigo, SUM(f.valor) AS saldo FROM plan p JOIN fase f ON f.plan_id = p.id
                          WHERE p.sede = ? AND f.estado = 'pendiente'
                          GROUP BY p.codigo ORDER BY saldo DESC LIMIT 3""", ("Suba",)).fetchall()


# ------------------------------------------------- 2. aiosql: el mismo SQL, en un "archivo"
import aiosql  # noqa: E402

queries = aiosql.from_str("""-- name: saldos(sede)
SELECT p.codigo, SUM(f.valor) AS saldo FROM plan p JOIN fase f ON f.plan_id = p.id
WHERE p.sede = :sede AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC LIMIT 3;""", "sqlite3")


def with_aiosql():
    return list(queries.saldos(raw, sede="Suba"))


# ------------------------------------------------- 3. SQLAlchemy
from sqlalchemy import ForeignKey, create_engine, event, func, select  # noqa: E402
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship  # noqa: E402


class Base(DeclarativeBase):
    pass


class SaPlan(Base):
    __tablename__ = "plan"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    sede: Mapped[str]
    fases: Mapped[list["SaFase"]] = relationship()


class SaFase(Base):
    __tablename__ = "fase"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("plan.id"))
    valor: Mapped[int]
    estado: Mapped[str]


engine = create_engine(f"sqlite:///{DB}")
event.listen(engine, "connect", lambda dbapi_conn, _: dbapi_conn.set_trace_callback(trace))


def with_sqlalchemy_navigating():
    with Session(engine) as s:
        owed = {p.codigo: sum(f.valor for f in p.fases if f.estado == "pendiente")
                for p in s.scalars(select(SaPlan).where(SaPlan.sede == "Suba"))}
        return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_sqlalchemy_aggregating():
    with Session(engine) as s:
        return s.execute(select(SaPlan.codigo, func.sum(SaFase.valor).label("saldo")).join(SaPlan.fases)
                         .where(SaPlan.sede == "Suba", SaFase.estado == "pendiente").group_by(SaPlan.codigo)
                         .order_by(func.sum(SaFase.valor).desc()).limit(3)).all()


# ------------------------------------------------- 4. Peewee
import peewee  # noqa: E402

pw_db = peewee.SqliteDatabase(DB)


class PwPlan(peewee.Model):
    codigo = peewee.CharField()
    sede = peewee.CharField()

    class Meta:
        database, table_name = pw_db, "plan"


class PwFase(peewee.Model):
    plan = peewee.ForeignKeyField(PwPlan, backref="fases", column_name="plan_id")
    valor = peewee.IntegerField()
    estado = peewee.CharField()

    class Meta:
        database, table_name = pw_db, "fase"


pw_db.connect()
pw_db.connection().set_trace_callback(trace)


def with_peewee_navigating():
    owed = {p.codigo: sum(f.valor for f in p.fases if f.estado == "pendiente")
            for p in PwPlan.select().where(PwPlan.sede == "Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_peewee_aggregating():
    total = peewee.fn.SUM(PwFase.valor)
    q = (PwPlan.select(PwPlan.codigo, total.alias("saldo")).join(PwFase)
         .where((PwPlan.sede == "Suba") & (PwFase.estado == "pendiente"))
         .group_by(PwPlan.codigo).order_by(total.desc()).limit(3))
    return [(r.codigo, r.saldo) for r in q]


# ------------------------------------------------- 5. Django
import django  # noqa: E402
from django.conf import settings  # noqa: E402

settings.configure(DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": DB}}, INSTALLED_APPS=[])
django.setup()
from django.db import connection, models  # noqa: E402
from django.db.models import Sum  # noqa: E402


class DjPlan(models.Model):
    codigo = models.CharField(max_length=10)
    sede = models.CharField(max_length=20)

    class Meta:
        app_label, db_table, managed = "aurea", "plan", False


class DjFase(models.Model):
    plan = models.ForeignKey(DjPlan, related_name="fases", on_delete=models.CASCADE)
    valor = models.IntegerField()
    estado = models.CharField(max_length=10)

    class Meta:
        app_label, db_table, managed = "aurea", "fase", False


connection.ensure_connection()
connection.connection.set_trace_callback(trace)


def with_django_navigating():
    owed = {p.codigo: sum(f.valor for f in DjFase.objects.filter(plan=p) if f.estado == "pendiente")
            for p in DjPlan.objects.filter(sede="Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_django_aggregating():
    q = (DjFase.objects.filter(plan__sede="Suba", estado="pendiente").values("plan__codigo")
         .annotate(saldo=Sum("valor")).order_by("-saldo").values_list("plan__codigo", "saldo")[:3])
    return list(q)


# ------------------------------------------------- 6. Pony
from pony import orm  # noqa: E402

pony_db = orm.Database()


class PoPlan(pony_db.Entity):
    _table_ = "plan"
    codigo = orm.Required(str)
    sede = orm.Required(str)
    fases = orm.Set("PoFase")


class PoFase(pony_db.Entity):
    _table_ = "fase"
    plan = orm.Required(PoPlan, column="plan_id")
    valor = orm.Required(int)
    estado = orm.Required(str)


pony_db.bind(provider="sqlite", filename=DB)
pony_db.generate_mapping(check_tables=False)


@orm.db_session
def with_pony():
    pony_db.get_connection().set_trace_callback(trace)
    return orm.select((p.codigo, orm.sum(f.valor for f in p.fases if f.estado == "pendiente"))
                      for p in PoPlan if p.sede == "Suba").order_by(orm.desc(2))[:3]


# ------------------------------------------------- la medición
CASES = [with_sqlite3, with_aiosql, with_sqlalchemy_navigating, with_sqlalchemy_aggregating, with_peewee_navigating,
         with_peewee_aggregating, with_django_navigating, with_django_aggregating, with_pony]
expected = with_sqlite3()
print(f"{'versión':<29}{'sentencias':>11}{'ms':>8}{'líneas':>8}  ¿mismo resultado?")
for case in CASES:
    traced.clear()
    result = [tuple(r) for r in case()]
    statements = len([s for s in traced if s.lstrip().upper().startswith("SELECT")])
    start = time.perf_counter()
    for _ in range(50):
        case()
    ms = (time.perf_counter() - start) / 50 * 1000
    lines = len([l for l in inspect.getsource(case).splitlines()[1:] if l.strip()])
    print(f"{case.__name__.removeprefix('with_'):<29}{statements:>11}{ms:>8.2f}{lines:>8}  {result == expected}")
