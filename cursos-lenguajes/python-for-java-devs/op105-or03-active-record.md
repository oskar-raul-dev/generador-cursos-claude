# 💾 or03 — Active Record: Django ORM, Peewee, Piccolo

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La herramienta interna de la franquicia de Zipaquirá está en Django, y un script viejo de Áurea usa Peewee. Los dos son ORM, y los dos
se sienten parecidos a SQLAlchemy los primeros días. La diferencia aparece el día que dos procesos tocan el mismo plan: la recepción le
cambia la sede y el sistema de cobro le cambia el estado, y uno de los dos cambios desaparece sin error.

La razón es el patrón. **Django ORM, Peewee y Piccolo son *Active Record***: cada objeto sabe guardarse a sí mismo (`plan.save()`), y al
guardarse escribe todos sus campos. **SQLAlchemy es *Data Mapper*** —como Hibernate—: una sesión lleva la cuenta de qué objetos cambiaron
y de qué campos, mantiene un objeto por fila (el *identity map*) y escribe solo lo que cambió. Este perfil viene de Hibernate y espera el
segundo comportamiento; la sección muestra lo que pasa con el primero.

---

## 🧠 2. El modelo

| | *Active Record* (Django, Peewee, Piccolo) | *Data Mapper* (SQLAlchemy, Hibernate) |
|---|---|---|
| Quién guarda | El objeto: `plan.save()` | La sesión: `session.commit()` |
| Mismo registro leído dos veces | **Dos objetos distintos** | El mismo objeto (*identity map*) |
| Qué escribe al guardar | Por defecto, **todos los campos** | Solo los campos que cambiaron |
| Separación dominio / persistencia | El modelo hereda de la base | El modelo puede ser casi independiente |
| Simplicidad | Mucha: una clase y un método | Menos: hay que entender la sesión |

| Biblioteca | Versión | Nota |
|---|---|---|
| Django ORM | con Django 6.1.1 | El más usado; inseparable de Django en la práctica |
| Peewee | 4.5.2 | Pequeño y estable; SQLite, Postgres, MySQL |
| Piccolo | 1.36.0 | Asíncrono, constructor de consultas y ORM; migraciones propias |

### Tu instinto de Java dice… y esta vez se equivoca

En Hibernate, cargar la misma entidad dos veces en una sesión da el mismo objeto, y el *flush* actualiza solo las columnas sucias (o todas,
según la configuración, pero dentro de una unidad de trabajo). El instinto da por hecho ese contrato en cualquier ORM. En *Active Record* no
existe: cada consulta crea un objeto nuevo, y cada `save()` es un `UPDATE` de toda la fila con los valores que ese objeto tenía.

---

## 💻 3. El ejemplo que corre

```bash
uv add peewee django sqlalchemy
```

`perdida.py`:

```python
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
```

```bash
python3 perdida.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Peewee:     mismo objeto: False · {'id': 1, 'codigo': 'PL-001', 'sede': 'Suba', 'estado': 'pagado'}
Django:     mismo objeto: False · {'codigo': 'PL-001', 'sede': 'Suba', 'estado': 'pagado'}
SQLAlchemy: mismo objeto en una sesión: True · {'codigo': 'PL-001', 'sede': 'Centro', 'estado': 'pagado'}
```

**Detalles con intención**

- **La pérdida es silenciosa**: el `save()` del cobro escribió `sede='Suba'`, el valor que su objeto tenía cuando se leyó, y borró el traslado
  de la recepción. Ninguna excepción, ningún aviso.
- **SQLAlchemy no pierde nada**, aunque las dos sesiones sean independientes, porque cada una escribe solo la columna que cambió:
  `UPDATE plan SET sede=?` y `UPDATE plan SET estado=?`. No es una transacción más fuerte; es escribir menos.
- **Django se configura en el mismo script** con `settings.configure` y un modelo con `app_label`: útil para el ejemplo y para scripts que leen
  una base de Django; en un proyecto, el modelo vive en una aplicación.

---

## ⚠️ 4. Lo que se rompe

**`save()` sin `update_fields`.** Es la causa de la pérdida. En Django, `billing.save(update_fields=["estado"])` escribe solo esa columna; en
Peewee, `billing.save(only=[PwPlan.estado])`. En código donde dos procesos tocan las mismas filas, es la forma por defecto.

**Actualizar con el objeto cuando se puede actualizar con la consulta.** `DjPlan.objects.filter(codigo="PL-001").update(estado="pagado")` manda un
`UPDATE` directo, sin leer antes; no hay objeto viejo que pise nada.

**Suponer que el control de concurrencia está.** Ni *Active Record* ni *Data Mapper* evitan que dos procesos cambien **el mismo campo**. Para eso
hace falta bloqueo optimista (una columna de versión, `version_id_col` en SQLAlchemy) o pesimista (`select_for_update` en Django).

---

## ⚖️ 5. Cuándo NO usarlo

**Django ORM fuera de Django.** Funciona, como muestra el ejemplo, pero arrastra la configuración de Django. Para un script que no es parte de un
proyecto Django, Peewee o SQLAlchemy.

**Peewee para un sistema grande con muchos procesos concurrentes.** Su simplicidad es su virtud; la unidad de trabajo de SQLAlchemy existe para el
otro caso.

**Piccolo si el resto del proyecto no es asíncrono.** Su API está pensada para `async`; en código síncrono es un rodeo.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas por qué la sede final es Suba en dos de los tres.
2. Arregla la pérdida en Peewee con `only=` y en Django con `update_fields`. **Criterio:** la sede final es Centro en los tres.
3. Activa el registro de SQL de SQLAlchemy (`echo=True`) y mira los dos `UPDATE`. **Criterio:** cada uno tiene una sola columna.

**🟡 Intermedio (4–6)**

4. Reemplaza los dos `save()` de Django por `filter(...).update(...)`. **Criterio:** sin pérdida, y cuántas sentencias se mandan.
5. Haz que la recepción y el cobro cambien **el mismo campo** en SQLAlchemy. **Criterio:** gana el último; explicas por qué ni el *Data Mapper*
   lo evita.
6. Agrega una columna de versión en SQLAlchemy (`version_id_col`). **Criterio:** el segundo `commit` del ejercicio 5 falla con `StaleDataError`.

**🟠 Difícil (7–9)**

7. Escribe el mismo modelo en Piccolo y repite el experimento con su API asíncrona. **Criterio:** qué comportamiento tiene al guardar.
8. Usa `select_for_update` en Django con Postgres (`db01`) en dos transacciones concurrentes. **Criterio:** la segunda espera a la primera.
9. Mide las sentencias que manda Django para listar 20 planes con sus fases, con y sin `prefetch_related`. **Criterio:** los dos números.

**🔴 Muy difícil (10)**

10. Revisa la herramienta de la franquicia (o un proyecto Django tuyo) en busca de pérdidas de actualización. **Criterio:** una página. *Rúbrica:*
    (a) qué modelos se tocan desde más de un proceso; (b) qué `save()` escriben todos los campos; (c) el arreglo de cada uno; (d) dónde hace
    falta control de concurrencia de verdad.

---

## 📚 7. Referencias

**Documentación oficial**

- Django, `save()` y `update_fields`: https://docs.djangoproject.com/en/stable/ref/models/instances/#saving-objects
- Peewee: https://docs.peewee-orm.com/en/latest/
- Piccolo: https://piccolo-orm.readthedocs.io/en/latest/
- SQLAlchemy, la sesión y la unidad de trabajo: https://docs.sqlalchemy.org/en/21/orm/session_basics.html

**Orden de lectura sugerido:** la sección de guardar objetos de Django (la de `update_fields`); después la de fundamentos de la sesión de SQLAlchemy,
para ver el otro patrón.

---

## 🚀 8. Cierre

Django ORM, Peewee y Piccolo son *Active Record*: el objeto se guarda solo y escribe todos sus campos, y dos objetos del mismo registro se pisan sin
avisar. SQLAlchemy es *Data Mapper*, como Hibernate: un objeto por fila en la sesión y solo los campos sucios. En *Active Record* se guarda con
`update_fields` o se actualiza con la consulta; en los dos, el mismo campo tocado por dos procesos necesita control de concurrencia.

**La señal de que quedó bien:** *"El cobro y la recepción tocan el mismo plan todos los días, y ningún traslado de sede se volvió a perder."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-03 -m "op or03 cerrada: Active Record contra Data Mapper y la actualización perdida"
> ```
>
> Los commits llevan su prefijo (`op or03: …`) y los de ejercicio su número
> (`op or03 ej07: …`).
