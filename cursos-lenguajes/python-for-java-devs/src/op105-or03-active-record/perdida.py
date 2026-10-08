"""Dos objetos del mismo plan, dos cambios distintos: Peewee y Django pierden uno; SQLAlchemy no."""

import django
from django.conf import settings

settings.configure(DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}},
                   INSTALLED_APPS=[], DEFAULT_AUTO_FIELD="django.db.models.AutoField")
django.setup()

import peewee  # noqa: E402
from django.db import connection, models  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column  # noqa: E402

# ------------------------------------------------- Peewee
pw_db = peewee.SqliteDatabase(":memory:")


class PwPlan(peewee.Model):
    codigo = peewee.CharField()
    sede = peewee.CharField()
    estado = peewee.CharField()

    class Meta:
        database = pw_db


pw_db.create_tables([PwPlan])
PwPlan.create(codigo="PL-001", sede="Suba", estado="activo")
reception, billing = PwPlan.get(codigo="PL-001"), PwPlan.get(codigo="PL-001")
reception.sede = "Centro"  # la recepción lo traslada
reception.save()
billing.estado = "pagado"  # el cobro lo marca pagado
billing.save()
print("Peewee:     mismo objeto:", reception is billing, "·", PwPlan.get(codigo="PL-001").__data__)


# ------------------------------------------------- Django
class DjPlan(models.Model):
    codigo = models.CharField(max_length=10)
    sede = models.CharField(max_length=20)
    estado = models.CharField(max_length=10)

    class Meta:
        app_label = "aurea"


with connection.schema_editor() as editor:
    editor.create_model(DjPlan)
DjPlan.objects.create(codigo="PL-001", sede="Suba", estado="activo")
reception, billing = DjPlan.objects.get(codigo="PL-001"), DjPlan.objects.get(codigo="PL-001")
reception.sede = "Centro"
reception.save()
billing.estado = "pagado"
billing.save()
final = DjPlan.objects.values("codigo", "sede", "estado").get(codigo="PL-001")
print("Django:     mismo objeto:", reception is billing, "·", final)


# ------------------------------------------------- SQLAlchemy (Data Mapper)
class Base(DeclarativeBase):
    pass


class SaPlan(Base):
    __tablename__ = "plan"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    sede: Mapped[str]
    estado: Mapped[str]


engine = create_engine("sqlite://")
Base.metadata.create_all(engine)
with Session(engine) as s:
    s.add(SaPlan(codigo="PL-001", sede="Suba", estado="activo"))
    s.commit()
with Session(engine) as reception_s, Session(engine) as billing_s:   # dos procesos, dos sesiones
    reception = reception_s.query(SaPlan).filter_by(codigo="PL-001").one()
    billing = billing_s.query(SaPlan).filter_by(codigo="PL-001").one()
    reception.sede = "Centro"
    reception_s.commit()
    billing.estado = "pagado"
    billing_s.commit()
with Session(engine) as s:
    same = s.get(SaPlan, 1) is s.get(SaPlan, 1)
    p = s.get(SaPlan, 1)
    print("SQLAlchemy: mismo objeto en una sesión:", same, "·", {"codigo": p.codigo, "sede": p.sede, "estado": p.estado})
