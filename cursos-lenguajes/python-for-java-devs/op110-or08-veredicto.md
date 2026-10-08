# ⚖️ or08 — Veredicto: la misma consulta en seis bibliotecas

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el eje del acceso a datos ([`or01`](op103-or01-el-eje.md)), SQLAlchemy a fondo
([`or02`](op104-or02-sqlalchemy-a-fondo.md)), los ORM *Active Record* ([`or03`](op105-or03-active-record.md)), Pony
([`or04`](op106-or04-pony.md)), los asíncronos ([`or05`](op107-or05-los-asincronos.md)), el SQL en archivos
([`or06`](op108-or06-sin-orm.md)) y las migraciones ([`or07`](op109-or07-migraciones.md)). Siempre con la misma consulta: los tres
planes de Suba con más saldo pendiente.

El veredicto no puede ser una opinión: la tesis del track es que cada biblioteca compra algo y lo paga con algo, y eso se mide. Esta
sección pone la misma consulta en seis bibliotecas sobre **la misma base**, y cuenta lo que importa: **cuántas sentencias llegan a la
base**, **cuánto tarda**, y **cuántas líneas hubo que escribir**. Y cada biblioteca se mide dos veces cuando tiene dos formas naturales
de escribirla: la que se escribe primero (navegando objetos) y la que se escribe cuando se sabe (agregando en la consulta).

---

## 🧠 2. El modelo

| Biblioteca | Punto del eje (`or01`) | Patrón | Escrita "navegando" | Escrita "agregando" |
|---|---|---|---|---|
| `sqlite3` | SQL | — | — | `SELECT … SUM … GROUP BY` |
| `aiosql` | SQL en archivos | — | — | La misma consulta, en un `.sql` |
| SQLAlchemy | Constructor y ORM | Data Mapper | `plan.fases` | `select(..., func.sum(...))` |
| Peewee | ORM | Active Record | `plan.fases` | `fn.SUM` con `group_by` |
| Django ORM | ORM | Active Record | Fases de cada plan | `values(...).annotate(Sum(...))` |
| Pony | ORM | Generadores → SQL | — | `sum(f.valor for f in p.fases ...)` |

**El contador universal**: todas usan el módulo `sqlite3` por debajo, y `Connection.set_trace_callback` registra cada sentencia que
llega a SQLite, venga de la biblioteca que venga. Es la misma vara para todas.

---

## 💻 3. El ejemplo que corre

```bash
uv add sqlalchemy peewee django pony aiosql
```

`seis.py` es largo porque son seis bibliotecas; cada una ocupa unas pocas líneas, que es parte de lo que se mide.

```python
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
```

```bash
python3 seis.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil, 50 repeticiones):

```text
versión                       sentencias      ms  líneas  ¿mismo resultado?
sqlite3                                1    0.09       3  True
aiosql                                 1    0.09       1  True
sqlalchemy_navigating                 21    3.94       4  True
sqlalchemy_aggregating                 1    0.30       4  True
peewee_navigating                     21    1.66       3  True
peewee_aggregating                     1    0.22       5  True
django_navigating                     21    4.14       3  True
django_aggregating                     1    0.35       3  True
pony                                   1    0.29       4  True
```

Nueve versiones, el mismo resultado, y tres conclusiones que salen de las columnas y no de la preferencia. Primera: **la forma de escribir
la consulta pesa más que la biblioteca**. Las tres versiones "navegando" mandan 21 sentencias y tardan entre 18 y 46 veces lo que el SQL a mano;
las mismas tres bibliotecas, "agregando", mandan una. Segunda: **el ORM cuesta, pero poco**: la versión agregada de SQLAlchemy, Peewee, Django o
Pony tarda entre 0,22 y 0,35 ms contra 0,09 del SQL, dos a cuatro veces, que es la maquinaria de cada biblioteca y en una consulta real contra
una base en red queda en el ruido. Tercera: **las líneas no distinguen** —todas entre 1 y 5—, y la de `aiosql` engaña: su línea es la llamada, y el
SQL vive en el archivo.

**Detalles con intención**

- **La misma base para todas**, creada con SQL a mano; cada biblioteca se mapea a las tablas existentes (`managed = False` en Django,
  `check_tables=False` en Pony, `table_name` en Peewee). Nadie mide con su propio esquema.
- **Django se escribe desde `DjFase`**: en un *script* sin aplicación instalada, Django no registra las relaciones inversas (`plan.fases`) y la
  primera corrida falló con `Cannot resolve keyword 'fases'`. En un proyecto Django normal, las dos direcciones funcionan; la medición no
  cambia.
- **Solo se cuentan los `SELECT`**: algunas bibliotecas mandan `BEGIN` o consultas de configuración al conectarse, que no son parte de la
  consulta.
- **Las líneas** son las de la función de cada versión, sin contar la definición de los modelos, que en las ORM se escribe una vez para
  muchas consultas.
- **"¿Mismo resultado?"** compara con la versión en SQL: una medición de rendimiento de algo que da otro resultado no vale.

---

## ⚠️ 4. Lo que se rompe

**Medir solo la versión elegante.** La versión "navegando" es la que se escribe primero en cualquier ORM, y es la que el contador castiga.
Comparar bibliotecas con su versión ideal esconde lo que pasa en el código real.

**Medir con 60 planes.** Con pocos datos, las diferencias de tiempo son de milisegundos y cualquier versión parece aceptable. La que manda
veintiuna sentencias con 20 planes manda dos mil una con dos mil (ejercicio 3).

**Concluir por las líneas.** La versión más corta no es la mejor si manda veinte veces más sentencias. Las tres columnas se leen juntas.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Para un CRUD.** La consulta del track es un agregado, el terreno donde el SQL gana. Para crear, editar y borrar entidades con relaciones, el
ORM gana en líneas y en errores evitados, y esta medición no lo muestra.

**Si el equipo ya eligió.** Cambiar de biblioteca por una tabla como esta cuesta más que aprender a escribir la versión "agregando" en la que ya
se usa.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre el ejemplo. **Criterio:** la tabla, y cuáles versiones mandan más de una sentencia y por qué.
2. Agrega la versión con PyPika (`or01`) ejecutada con `sqlite3`. **Criterio:** una fila más en la tabla.

**🟡 Intermedio (3–4)**

3. Sube los planes a 2 000. **Criterio:** la tabla nueva, y cómo crecen las sentencias y el tiempo de las versiones "navegando".
4. Arregla las versiones "navegando" con la carga anticipada de cada ORM (`selectinload`, `prefetch`, `prefetch_related`). **Criterio:** cuántas
   sentencias mandan ahora.

**🟠 Difícil (5–6)**

5. Agrega una tabla de pagos y cambia la consulta a "saldo pendiente menos pagos parciales". **Criterio:** cuántas líneas cambió cada versión.
6. Repite la medición contra Postgres (`db01`). **Criterio:** la tabla, y si el orden de las bibliotecas cambia.

**🔴 Muy difícil (7–8)**

7. Escribe la recomendación de acceso a datos para Áurea. **Criterio:** una página. *Rúbrica:* (a) qué biblioteca para el CRUD y cuál para los
   reportes; (b) los números de esta medición que la apoyan; (c) la regla para evitar las versiones "navegando" en código de reportes; (d) cómo se
   vigila con el contador en las pruebas.
8. Haz la misma medición sobre un proyecto tuyo con su consulta más usada. **Criterio:** una tabla. *Rúbrica:* (a) la consulta y las versiones; (b)
   sentencias, tiempo y líneas; (c) cuál está en producción hoy; (d) si cambiarías algo y por qué.

---

## 📚 7. Referencias

- `sqlite3`, `set_trace_callback`: https://docs.python.org/3/library/sqlite3.html#sqlite3.Connection.set_trace_callback

**Orden de lectura sugerido:** la página de `set_trace_callback` (el contador universal); el resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

La misma consulta en seis bibliotecas muestra lo que el track sostuvo: el SQL y los constructores mandan una sentencia; los ORM mandan una si
se escribe agregando y veintiuna si se escribe navegando; Pony manda una escribiendo Python. La biblioteca importa menos que la forma de
escribir la consulta, y el contador de sentencias es lo que lo dice.

**La señal de que quedó bien:** *"Elegimos el ORM para el CRUD y SQL en archivos para los reportes, y la prueba con el contador impide que una
versión navegando llegue a producción."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-08 -m "op or08 cerrada: la misma consulta en seis bibliotecas, medida"
> ```
>
> Los commits llevan su prefijo (`op or08: …`) y los de ejercicio su número
> (`op or08 ej07: …`).
