# 🛠️ or02 — SQLAlchemy a fondo

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 2 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El camino base usó SQLAlchemy para lo básico: modelos declarativos, sesión, consultas con `select`. En un proyecto real aparecen tres
necesidades más que el básico no cubre, y las tres le pasaron a Áurea en el primer mes con los planes de tratamiento: el tablero de
cartera manda cientos de consultas porque navega relaciones (el N+1 de `or01`); el "saldo pendiente" de un plan se calcula en Python en
un lugar y en SQL en otro, y los dos números no coinciden; y los montos, que en la base son enteros en pesos, llegan al código como
`int` y alguien termina dividiéndolos como `float`.

SQLAlchemy tiene una herramienta para cada una: **estrategias de carga** (`selectinload`, `joinedload`, `raiseload`) para el N+1,
**`hybrid_property`** para que una misma definición funcione en Python y en SQL, y **tipos personalizados** (`TypeDecorator`) para que
los montos entren y salgan como `Decimal` sin que nadie se acuerde. Esta sección las arma sobre el mismo modelo de `or01`, con
SQLAlchemy 2.1, la versión que salió este año.

---

## 🧠 2. El modelo

| Estrategia de carga | Qué manda | Cuándo |
|---|---|---|
| `lazyload` (por defecto) | Una consulta por cada relación al tocarla | Casi nunca, conscientemente |
| `selectinload` | Una consulta más con `IN (…)` para todos los padres | **El defecto razonable** para colecciones |
| `joinedload` | Un `JOIN` en la misma consulta | Relaciones a uno; colecciones chicas |
| `raiseload` | **Nada: lanza un error** si se toca la relación | En pruebas y en código donde un N+1 sería un error |

| Herramienta | Problema que resuelve |
|---|---|
| `hybrid_property` | Una propiedad que es Python en el objeto y SQL en la consulta |
| `TypeDecorator` | Convertir al entrar y al salir de la base (montos, fechas, cifrado) |
| Eventos (`before_flush`, `before_update`…) | Validar o completar datos al guardar |

### Tu instinto de Java dice… y esta vez se equivoca

En Hibernate, la estrategia de carga se fija en la anotación (`FetchType.LAZY`) y se corrige con `JOIN FETCH` o *entity graphs* en la
consulta. En SQLAlchemy se puede fijar en la relación, pero la costumbre buena es decidirla **en cada consulta** con `options(...)`,
porque la misma relación se usa de formas distintas. Y `raiseload` no tiene equivalente directo en Hibernate: convierte el N+1 en un
error que la prueba atrapa.

---

## 💻 3. El ejemplo que corre

```bash
uv add sqlalchemy
```

`a_fondo.py`:

```python
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
```

```bash
python3 a_fondo.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
lazy (por defecto)   21 sentencias · saldo de Suba $56,100,000
selectinload          2 sentencias · saldo de Suba $56,100,000
joinedload            1 sentencias · saldo de Suba $56,100,000
raiseload             1 sentencias · InvalidRequestError: 'Plan.fases' is not available due to lazy='raise'…
hybrid en SQL         1 sentencia  · [('PL-033', Decimal('6350000')), ('PL-024', Decimal('5400000')), ('PL-051', Decimal('4750000'))]
```

El mismo saldo de Suba con 21, 2 o 1 sentencias según una línea de `options`. Con `raiseload`, la consulta de los planes se manda y el primer
`p.fases` lanza el error: en una prueba, ese error es el N+1 atrapado antes de producción. Y el `hybrid_property` calculado en SQL da los mismos
tres planes que `or01`, con un detalle que vale la pena notar: los saldos llegan como `Decimal` también desde la subconsulta, porque SQLAlchemy
propaga el tipo `Pesos` a través de `sum` y `coalesce`.

**Detalles con intención**

- **`options(selectinload(Plan.fases))` en la consulta**, no en la relación: la misma relación puede cargarse distinto en el tablero y en el
  detalle de un plan.
- **`.unique()`** es obligatorio con `joinedload` sobre colecciones en SQLAlchemy 2: el `JOIN` repite el plan una vez por fase, y `unique()`
  los junta. Con las otras estrategias no cambia nada.
- **`hybrid_property` con `inplace.expression`**: la versión Python recorre `self.fases`; la versión SQL es una subconsulta. Las dos están en la
  misma clase, una al lado de la otra, que es lo que evita que difieran.
- **`Pesos`** guarda enteros y entrega `Decimal`. `cache_ok = True` le dice a SQLAlchemy que el tipo es seguro para el caché de sentencias, sin
  el cual avisa en cada uso.

---

## ⚠️ 4. Lo que se rompe

**`joinedload` en dos colecciones a la vez.** Un plan con 4 fases y 3 pagos, con `joinedload` en las dos, trae 12 filas por plan (el producto
cartesiano). Para colecciones, `selectinload`.

**La propiedad Python y la SQL que se separan.** Si alguien cambia la versión Python del `hybrid` (por ejemplo, excluye las fases anuladas) y
no la SQL, el tablero y el detalle vuelven a mostrar números distintos. Una prueba que compare las dos sobre los mismos datos (ejercicio 6) lo
evita.

**`baked queries` en código viejo.** Era la forma de cachear consultas en SQLAlchemy 1.x; en 2.x el caché de sentencias es automático y las
`baked queries` son una extensión heredada. Se migran a consultas normales.

**Pasar de 2.0 a 2.1 sin leer la guía.** La 2.1 es compatible en lo general, pero cambia avisos y valores por defecto en algunos rincones; se
corre la suite con avisos como errores (`-W error::DeprecationWarning`) antes de subir.

---

## ⚖️ 5. Cuándo NO usarlo

**`hybrid_property` para lógica complicada.** Si la regla del saldo tiene diez casos, mantener la versión Python y la SQL idénticas es caro; se
calcula en un solo lugar (la base, con una vista) y se lee de ahí.

**`TypeDecorator` para formatear.** El tipo convierte entre la base y Python; el formato `$1.234.567` es de la presentación (`tx02`), no del tipo.

**Eventos para lógica de negocio.** Un `before_flush` que calcula comisiones es lógica escondida que nadie encuentra. Los eventos sirven para
lo transversal: auditoría, marcas de tiempo, validaciones simples.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas las cuatro cifras de sentencias.
2. Imprime el SQL de la consulta con `selectinload` (los dos textos). **Criterio:** encuentras el `IN (…)`.
3. Guarda una fase con `valor=Decimal("1250000.50")`. **Criterio:** qué queda en la base y qué vuelve, y si es lo que querías.

**🟡 Intermedio (4–6)**

4. Pon `lazy="raise"` en la relación y arregla cada consulta que falle. **Criterio:** ninguna consulta del ejemplo hace N+1.
5. Agrega un evento `before_update` que registre en una tabla de auditoría el cambio de estado de una fase. **Criterio:** pagar una fase deja
   una fila de auditoría.
6. Escribe la prueba que compara `plan.saldo` en Python con `Plan.saldo` en SQL para todos los planes. **Criterio:** pasa, y falla si cambias
   solo una de las dos.

**🟠 Difícil (7–9)**

7. Agrega una tabla de pagos y carga fases y pagos con `joinedload` y con `selectinload`. **Criterio:** filas traídas en cada caso.
8. Usa herencia de tablas (`plan` → `plan_ortodoncia`, `plan_rehabilitacion`) con `polymorphic_on`. **Criterio:** una consulta trae los dos
   tipos como subclases.
9. Escribe un `TypeDecorator` que cifre un campo con Fernet (`se02`). **Criterio:** en la base hay texto cifrado; en Python, el texto claro.

**🔴 Muy difícil (10)**

10. Audita el acceso a datos de un proyecto con SQLAlchemy. **Criterio:** una página. *Rúbrica:* (a) cuántas sentencias manda cada pantalla o
    proceso, medido; (b) la estrategia de carga de cada relación y si es la correcta; (c) dónde hay reglas duplicadas en Python y SQL; (d) qué
    tipos personalizados faltan.

---

## 📚 7. Referencias

**Documentación oficial**

- SQLAlchemy 2.1, técnicas de carga de relaciones: https://docs.sqlalchemy.org/en/21/orm/queryguide/relationships.html
- SQLAlchemy 2.1, `hybrid_property`: https://docs.sqlalchemy.org/en/21/orm/extensions/hybrid.html
- SQLAlchemy 2.1, tipos personalizados: https://docs.sqlalchemy.org/en/21/core/custom_types.html
- SQLAlchemy, novedades de la 2.1: https://docs.sqlalchemy.org/en/21/changelog/whatsnew_21.html

**Orden de lectura sugerido:** la página de técnicas de carga de relaciones (es la que más rendimiento devuelve); después la de novedades de
la 2.1.

---

## 🚀 8. Cierre

El N+1 se corrige consulta por consulta con `selectinload` y se previene con `raiseload`; una regla que vive en Python y en SQL se escribe una
vez como `hybrid_property`; y los montos entran y salen como `Decimal` con un tipo propio. Todo se verifica con el contador de sentencias.

**La señal de que quedó bien:** *"El tablero de cartera manda dos consultas, y la prueba falla si alguien agrega una relación sin decir cómo se
carga."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-02 -m "op or02 cerrada: estrategias de carga, hybrid_property y el tipo Pesos"
> ```
>
> Los commits llevan su prefijo (`op or02: …`) y los de ejercicio su número
> (`op or02 ej07: …`).
