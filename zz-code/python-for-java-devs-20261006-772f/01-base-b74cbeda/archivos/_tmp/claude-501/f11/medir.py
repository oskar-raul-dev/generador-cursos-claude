"""La misma consulta en SQL directo, Core y ORM. Y el N+1 provocado."""
import statistics, time
from datetime import date, datetime, timedelta, timezone

import psycopg
from sqlalchemy import create_engine, event, func, select, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, selectinload

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
URL = "postgresql+psycopg://aurea@/agenda?host=/tmp/claude-501&port=55432"
BOGOTA = timezone(timedelta(hours=-5))
DAY = datetime(2026, 8, 12, tzinfo=BOGOTA)

engine = create_engine(URL)

queries = {"n": 0}
@event.listens_for(engine, "before_cursor_execute")
def count(conn, cursor, statement, params, context, executemany):
    queries["n"] += 1

class Base(DeclarativeBase): pass

class Branch(Base):
    __tablename__ = "branches"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str]

class TreatmentPlan(Base):
    __tablename__ = "treatment_plans"
    id: Mapped[int] = mapped_column(primary_key=True)
    patient_id: Mapped[int]
    opened_on: Mapped[date]
    phases: Mapped[list["PlanPhase"]] = relationship(back_populates="plan")

class PlanPhase(Base):
    __tablename__ = "plan_phases"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(__import__("sqlalchemy").ForeignKey("treatment_plans.id"))
    kind: Mapped[str]
    status: Mapped[str]
    last_moved_on: Mapped[date]
    plan: Mapped[TreatmentPlan] = relationship(back_populates="phases")

SQL = """
SELECT a.starts_at, a.minutes FROM appointments a
JOIN branches b ON b.id = a.branch_id
WHERE b.name = %s AND a.starts_at >= %s AND a.starts_at < %s AND a.status <> 'no_show'
ORDER BY a.starts_at
"""

def raw_sql():
    with psycopg.connect(DSN) as con, con.cursor() as cur:
        cur.execute(SQL, ("Centro", DAY, DAY + timedelta(days=1)))
        return cur.fetchall()

conn_raw = psycopg.connect(DSN)
def raw_sql_reused():
    with conn_raw.cursor() as cur:
        cur.execute(SQL, ("Centro", DAY, DAY + timedelta(days=1)))
        return cur.fetchall()

appointments = Base.metadata.tables.get("appointments")
from sqlalchemy import Table, MetaData
md = MetaData(); appt = Table("appointments", md, autoload_with=engine); br = Table("branches", md, autoload_with=engine)

def core():
    stmt = (select(appt.c.starts_at, appt.c.minutes).join(br, br.c.id == appt.c.branch_id)
            .where(br.c.name == "Centro", appt.c.starts_at >= DAY,
                   appt.c.starts_at < DAY + timedelta(days=1), appt.c.status != "no_show")
            .order_by(appt.c.starts_at))
    with engine.connect() as conn:
        return conn.execute(stmt).all()

class Appointment(Base):
    __tablename__ = "appointments"
    id: Mapped[int] = mapped_column(primary_key=True)
    branch_id: Mapped[int] = mapped_column(__import__("sqlalchemy").ForeignKey("branches.id"))
    starts_at: Mapped[datetime]
    minutes: Mapped[int]
    status: Mapped[str]
    patient_id: Mapped[int]

def orm():
    with Session(engine) as s:
        stmt = (select(Appointment).join(Branch, Branch.id == Appointment.branch_id)
                .where(Branch.name == "Centro", Appointment.starts_at >= DAY,
                       Appointment.starts_at < DAY + timedelta(days=1), Appointment.status != "no_show")
                .order_by(Appointment.starts_at))
        return s.scalars(stmt).all()

def bench(fn, reps=40):
    fn(); fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], len(r)

print("=== la misma consulta de disponibilidad ===")
for name, fn in [("SQL directo (conexión nueva)", raw_sql), ("SQL directo (conexión reusada)", raw_sql_reused),
                 ("SQLAlchemy Core", core), ("SQLAlchemy ORM", orm)]:
    m,p,n = bench(fn)
    print(f"{name:32s} mediana {m:7.2f} ms  p95 {p:7.2f} ms  filas {n}")

print()
print("=== el N+1, provocado ===")
def n_plus_one():
    queries["n"]=0
    with Session(engine) as s:
        plans = s.scalars(select(TreatmentPlan).limit(200)).all()
        total = sum(len(p.phases) for p in plans)   # ← aquí se disparan 200 consultas
    return queries["n"], total

def eager():
    queries["n"]=0
    with Session(engine) as s:
        plans = s.scalars(select(TreatmentPlan).options(selectinload(TreatmentPlan.phases)).limit(200)).all()
        total = sum(len(p.phases) for p in plans)
    return queries["n"], total

for name, fn in [("navegando (N+1)", n_plus_one), ("con selectinload", eager)]:
    fn()
    xs=[]
    for _ in range(20):
        t0=time.perf_counter(); q,total=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    print(f"{name:24s} mediana {statistics.median(xs):7.1f} ms  consultas {q:4d}  fases {total}")
