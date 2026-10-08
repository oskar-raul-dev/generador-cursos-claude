# ⚡ or05 — Los ORM asíncronos

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La API de la agenda está en FastAPI con funciones `async`, y la primera consulta asíncrona a la base se ve igual que la síncrona con
un `await` delante. La segunda —recorrer las fases de un plan— falla con un error que no se parece a nada conocido:
`MissingGreenlet: greenlet_spawn has not been called; can't call await_only() here`. Es el momento en que este perfil descubre que el
ORM asíncrono no es el ORM de siempre con `await`.

El problema de fondo es la carga perezosa (`or01`, `or02`). En un ORM síncrono, tocar `plan.fases` dispara una consulta escondida; en
uno asíncrono, esa consulta tendría que ser un `await`, y un atributo no puede esperar. Cada ORM asíncrono lo resuelve a su manera:
**SQLAlchemy** prohíbe la carga perezosa y obliga a decidir la carga en la consulta; **Tortoise ORM** hace que la relación sea algo que
se espera explícitamente; **SQLModel** y **Ormar** se apoyan en SQLAlchemy. La pregunta que esta sección deja planteada es la más
importante: **¿hacía falta asíncrono?**

---

## 🧠 2. El modelo

| Biblioteca | Versión | Sobre qué | Relaciones en asíncrono |
|---|---|---|---|
| SQLAlchemy (`AsyncSession`) | 2.1.3 | Su propio núcleo + `greenlet` | **Prohíbe la carga perezosa**: `selectinload` o `AsyncAttrs` |
| Tortoise ORM | 1.1.8 | Propio, al estilo Django | `await plan.fases.all()` o `prefetch_related` |
| SQLModel | 0.0.47 ⚠️ | SQLAlchemy + Pydantic | Las de SQLAlchemy; sigue en `0.0.x` |
| Ormar | 0.26.0 | SQLAlchemy Core + Pydantic | Propias, asíncronas |
| *Drivers* | `asyncpg` 0.31.0, `aiosqlite` 0.22.1 | — | — |

**Lo que compra el asíncrono**: atender muchas peticiones concurrentes que pasan el tiempo esperando a la base o a la red, con un solo
proceso. **Lo que no compra**: que una consulta sea más rápida. Una consulta tarda lo mismo con `await` que sin él.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, lo reactivo (R2DBC, Spring WebFlux) es una decisión grande y explícita, y Hibernate Reactive es un producto aparte. El instinto espera
que en Python el asíncrono sea igual de pesado, o al revés, que sea "el mismo ORM con `await`". Está en el medio: es el mismo SQLAlchemy, con
una sesión distinta y una regla nueva —nada de carga perezosa— que rompe código que en síncrono funcionaba.

---

## 💻 3. El ejemplo que corre

```bash
uv add "sqlalchemy[asyncio]" aiosqlite tortoise-orm
```

`asincronos.py`:

```python
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
```

```bash
python3 asincronos.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
SQLAlchemy, perezoso: StatementError: (sqlalchemy.exc.MissingGreenlet) greenlet_spawn has not been called; c…
SQLAlchemy, selectinload: 2050000
Tortoise, relación sin esperar: ReverseRelation
Tortoise, await .all(): 2050000
Tortoise, prefetch_related: 2050000
```

Y al terminar, en la salida de error:

```text
RuntimeWarning: coroutine 'Connection.cursor' was never awaited
```

La misma relación, tres comportamientos. En SQLAlchemy, tocarla sin cargarla falla —con `MissingGreenlet` envuelto en un `StatementError`, que
es lo que hay que buscar en una bitácora—, y con `selectinload` funciona. En Tortoise, `loaded.fases` es una `ReverseRelation`, un objeto que
se espera: no hay forma de tocarla por accidente. Y el aviso final es un efecto secundario del intento fallido: SQLAlchemy alcanzó a pedir un
cursor al *driver* asíncrono antes de fallar, y esa corrutina quedó sin esperar. Aparece lejos del error, al cerrar el programa, y es una pista
más de que en algún lado se tocó una relación sin cargar.

**Detalles con intención**

- **`MissingGreenlet`** (dentro de un `StatementError`) es el error de tocar una relación no cargada en una `AsyncSession`: la carga perezosa necesitaría una consulta, y el
  atributo no puede esperarla. El mensaje habla de `greenlet` porque SQLAlchemy usa esa biblioteca por dentro para unir el mundo síncrono y el
  asíncrono.
- **`selectinload` en la consulta** es la solución en SQLAlchemy, y es la misma que en síncrono se recomendaba por rendimiento (`or02`): el
  asíncrono convierte una buena práctica en una obligación.
- **En Tortoise, `plan.fases` es un objeto que se espera**: `await plan.fases.all()`. No hay acceso escondido; cada consulta tiene su `await`
  visible, que es más honesto y más verboso.
- **`run_sync(Base.metadata.create_all)`**: crear las tablas es síncrono en SQLAlchemy; dentro del motor asíncrono se corre con `run_sync`.

---

## ⚠️ 4. Lo que se rompe

**Mezclar código síncrono y asíncrono.** Una función síncrona que recibe un objeto cargado en una `AsyncSession` y toca una relación falla con
`MissingGreenlet` lejos del lugar donde se cargó. Los objetos que salen de una sesión asíncrona salen con todo lo que se va a usar ya cargado.

**Una sesión compartida entre tareas.** Una `AsyncSession` no se puede usar desde dos corrutinas a la vez. En FastAPI, una sesión por petición
(una dependencia), nunca una global.

**Asíncrono con SQLite para medir.** SQLite no tiene concurrencia de escritura (`db04`) y `aiosqlite` corre las consultas en un hilo aparte: el
asíncrono no gana nada ahí. El beneficio se mide con Postgres y muchas peticiones concurrentes.

**SQLModel en `0.0.x`.** Lleva años en `0.0.x` con cambios entre versiones menores; se fija la versión exacta y se leen las notas al subir.

---

## ⚖️ 5. Cuándo NO usarlo

**Si la aplicación no tiene concurrencia que aprovechar.** Un proceso nocturno, un script, un panel con diez usuarios: el asíncrono agrega
complejidad sin beneficio medible.

**Si el resto del código es síncrono.** FastAPI acepta funciones síncronas (las corre en un *pool* de hilos); un ORM síncrono detrás de ellas es
más simple y suele bastar.

**Tortoise o Ormar si la casa ya usa SQLAlchemy.** El asíncrono de SQLAlchemy está maduro; un ORM más no se justifica por el `await`.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas el error de SQLAlchemy y por qué `selectinload` lo resuelve.
2. Usa `AsyncAttrs` en el modelo y accede con `await plan.awaitable_attrs.fases`. **Criterio:** funciona sin `selectinload`.
3. Imprime qué devuelve `loaded.fases` en Tortoise antes de esperar. **Criterio:** el tipo, y qué pasa si lo recorres sin `await`.

**🟡 Intermedio (4–6)**

4. Haz una ruta de FastAPI que devuelva un plan con sus fases usando `AsyncSession` como dependencia. **Criterio:** una sesión por petición.
5. Escribe la misma ruta con un ORM síncrono y una función `def` (no `async def`). **Criterio:** las dos funcionan; cuentas las líneas de cada una.
6. Usa `raiseload` en la sesión asíncrona. **Criterio:** el error que aparece en vez de `MissingGreenlet`, y cuál prefieres en una prueba.

**🟠 Difícil (7–9)**

7. Mide las dos rutas del ejercicio 4 y 5 contra Postgres (`db01`) con 200 peticiones concurrentes (`qa`, Locust). **Criterio:** la tabla de
   latencias; si el asíncrono no gana, explica por qué.
8. Escribe el mismo modelo en Ormar o SQLModel. **Criterio:** las relaciones asíncronas funcionando, y qué te dio que no te dio SQLAlchemy.
9. Provoca el uso de una `AsyncSession` desde dos tareas a la vez. **Criterio:** el error exacto.

**🔴 Muy difícil (10)**

10. Decide si la API de la agenda de Áurea debe ser asíncrona hasta la base. **Criterio:** una página. *Rúbrica:* (a) la concurrencia real
    medida; (b) la medición del ejercicio 7; (c) el costo en complejidad (errores, pruebas, bibliotecas); (d) la decisión y la señal que la
    cambiaría.

---

## 📚 7. Referencias

**Documentación oficial**

- SQLAlchemy, extensión asyncio: https://docs.sqlalchemy.org/en/21/orm/extensions/asyncio.html
- Tortoise ORM: https://tortoise.github.io/
- SQLModel: https://sqlmodel.tiangolo.com/
- Ormar: https://collerek.github.io/ormar/latest/

**Orden de lectura sugerido:** la página de asyncio de SQLAlchemy, en especial la sección sobre evitar la carga perezosa; después la de Tortoise
para ver el otro estilo.

---

## 🚀 8. Cierre

Los ORM asíncronos no son el ORM de siempre con `await`: la carga perezosa no puede existir, y cada uno lo resuelve obligando a cargar en la
consulta (SQLAlchemy) o a esperar la relación explícitamente (Tortoise). El asíncrono atiende más peticiones concurrentes; no hace más rápida
ninguna consulta. Antes de adoptarlo, se mide si hay concurrencia que aprovechar.

**La señal de que quedó bien:** *"La API de la agenda decidió entre síncrono y asíncrono con una medición, y nadie volvió a ver un
`MissingGreenlet` en producción."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-05 -m "op or05 cerrada: la relación que se espera, en SQLAlchemy y en Tortoise"
> ```
>
> Los commits llevan su prefijo (`op or05: …`) y los de ejercicio su número
> (`op or05 ej07: …`).
