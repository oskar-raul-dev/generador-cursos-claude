# 🗄️ Fase 11 — Persistencia

> Python para desarrolladores Java senior · Fase 11 de 18 · Bloque C
> Depende de: Fase 10 · Habilita: Fase 12
> Registro de esta fase: **aplicación**
> Proyecto que avanza: AgendaAPI · **y entra el dominio duro de Áurea**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Poner el dominio más difícil de Áurea contra una base de datos real, y desmontar de paso una
expectativa que este perfil trae entera: que el ORM de Python es Hibernate con otro nombre.

No lo es, y la diferencia no es de calidad: es de **modelo mental**. SQLAlchemy tiene dos
herramientas —Core y ORM— que no son dos niveles de abstracción sino dos formas distintas de
trabajar, y elegir mal entre ellas es el error más común de quien llega de la JPA. Y no hay carga
perezosa automática de relaciones, lo cual al principio se siente como una carencia y termina
siendo lo mejor de la biblioteca.

Y el dominio que entra es el que sostiene el negocio: **el plan de Arquitectura de Sonrisa**, con
sus cinco fases, su responsable y su sede por fase, su consentimiento por fase, y su plan de pagos
corriendo en paralelo.

---

## ✅ 2. Qué queda listo al terminar

- [ ] AgendaAPI persiste en Postgres y las reservas sobreviven a un reinicio.
- [ ] Puedes explicar la diferencia entre Core y ORM sin usar las palabras "más" o "menos
      abstracto".
- [ ] Reconoces un N+1 al leerlo, sabes provocarlo a propósito y sabes las dos formas de
      arreglarlo.
- [ ] Tienes migraciones con Alembic, y una que agrega una columna con datos ya cargados.
- [ ] Sabes por qué abrir una conexión cuesta más que la consulta, con el número delante.
- [ ] El modelo aguanta la pregunta *"¿qué planes llevan más de noventa días quietos en la fase
      2?"* en **una** consulta.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Otros motores** —MySQL, MongoDB, Redis— → track `db`. Nombrarlos aquí abre una puerta que la
  fase no puede cerrar, y el eje del curso es el registro, no el catálogo de productos.
- **La concurrencia de verdad** → Fase 14. El caso de las dos auxiliares reservando las 3:40 **se
  planta aquí** —con la restricción que lo hace imposible— y se resuelve allá, con bloqueo
  optimista y su medición.
- **Permisos por fila y auditoría de accesos** → Fase 12, donde son requisito legal y donde el
  back-office los necesita en cada pantalla.
- **Rendimiento y perfilado de consultas en serio** → Fase 16, con la regla de *primero SQL,
  después Python*.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *"cargo la entidad y navego las relaciones"*.

```java
// Once años de esto
TreatmentPlan plan = repository.findById(id);
for (PlanPhase phase : plan.getPhases()) {     // Hibernate va a la base aquí, solo
    System.out.println(phase.getDentist().getName());   // y aquí otra vez
}
```

En Hibernate eso funciona: la colección es perezosa, y cuando la tocas se carga sola. Es cómodo, y
es también la razón de que exista una industria entera de artículos sobre el N+1 y sobre
`LazyInitializationException`.

Traído aquí, produce esto:

```python
# ❌ El reflejo, y en SQLAlchemy tiene dos formas de fallar
with Session(engine) as session:
    plans = session.scalars(select(TreatmentPlan).limit(200)).all()

total = sum(len(plan.phases) for plan in plans)
# DetachedInstanceError: la sesión ya se cerró y esto no se puede cargar
```

O, dentro de la sesión, **sí funciona** — y ahí está el problema:

```python
with Session(engine) as session:
    plans = session.scalars(select(TreatmentPlan).limit(200)).all()
    total = sum(len(plan.phases) for plan in plans)   # ← 200 consultas, en silencio
```

**201 consultas y 42.7 ms** donde debían ser 2 consultas y 9.4 ms. Los números son de la sección 6
y son de Postgres real.

**Qué se escribe en su lugar:** decir qué necesitas **al pedirlo**.

```python
# ✅ Se declara la carga: 2 consultas, y el objeto sirve fuera de la sesión
with Session(engine) as session:
    plans = session.scalars(
        select(TreatmentPlan)
        .options(selectinload(TreatmentPlan.phases))
        .limit(200)
    ).all()

total = sum(len(plan.phases) for plan in plans)   # ya está cargado: cero consultas
```

**Y aquí está la parte que cuesta admitir:** ese `DetachedInstanceError` que parece una molestia
es en realidad la mejor característica de la biblioteca. Te obliga a decidir qué datos necesitas
**en el momento de la consulta**, que es cuando tienes la información para decidirlo. Hibernate te
deja postergar esa decisión hasta el momento de usarlos, y por eso el N+1 aparece en producción
en vez de en la revisión de código.

> 🧭 **La regla, y vale para los dos ecosistemas:** cargar es una decisión, no un efecto
> secundario. Lo único que cambia es que aquí el lenguaje te obliga a tomarla.

### Core y ORM no son dos niveles: son dos herramientas

Esta es la distinción que más confusión produce, porque la documentación vieja y medio internet la
presentan como una escalera de abstracción. No lo es.

**Core** es un constructor de consultas. Trabajas con tablas, columnas y filas; el resultado son
tuplas con nombre. Es SQL escrito en Python, con la ventaja de que se compone —puedes armar un
`WHERE` a pedazos— y de que el dialecto lo pone la biblioteca.

**ORM** es un mapa entre objetos y filas, con **identidad** y **unidad de trabajo**: la sesión
recuerda qué objetos cargó, detecta qué cambió, y decide qué escribir y en qué orden al hacer
`commit`. Eso es lo que Core no tiene y lo que de verdad lo distingue.

| | Core | ORM |
|---|---|---|
| Con qué trabajas | tablas y columnas | clases y atributos |
| Qué devuelve | filas | objetos con identidad |
| Quién decide qué se escribe | tú, con un `INSERT`/`UPDATE` | la sesión, comparando estados |
| Para qué es bueno | reportes, cargas masivas, consultas complejas | dominio con ciclo de vida y reglas |
| Costo | 0.51 ms en la consulta de §6 | 0.74 ms — el 45% más |

**El criterio para elegir, que es lo que te llevas:** ¿este dato tiene **ciclo de vida** —se crea,
se modifica, se valida, se guarda— o solo lo estás **leyendo para mostrarlo**? El plan de
tratamiento tiene ciclo de vida: ORM. El reporte de inasistencia por sede es una lectura: Core, o
SQL directo.

Y las dos conviven en el mismo proyecto y en la misma sesión, sin ceremonia. No hay que elegir una
para todo.

### Esto sí funciona igual

Aquí transfiere prácticamente todo, y es la fase donde tu experiencia más rinde:

**SQL es SQL.** Modelado, normalización, claves, índices, planes de ejecución, `EXPLAIN`. Nada de
eso cambia y vale más que cualquier truco de la biblioteca.

**Las transacciones y los niveles de aislamiento** son los de siempre, con los mismos problemas:
lecturas no repetibles, fantasmas, y el hecho de que `READ COMMITTED` —el valor por defecto de
Postgres— no te protege de una actualización perdida.

**El N+1 es el N+1.** Lo conoces, lo has arreglado, y sabes olerlo. Lo único distinto es que aquí
se provoca explícitamente en vez de aparecer solo.

**Las migraciones son migraciones.** Alembic es Flyway o Liquibase con otra sintaxis: versiones
ordenadas, `upgrade` y `downgrade`, y la misma disciplina de no editar una migración ya aplicada.

**Y el *pool* de conexiones existe y por la misma razón**, que la sección 6 mide: abrir una
conexión a Postgres cuesta 3.4 ms y la consulta 0.06 ms. Cincuenta y seis veces más.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| JDBC | DB-API 2.0 (`psycopg`) | Misma idea; la especificación es el PEP 249 |
| Hibernate / JPA | SQLAlchemy ORM | **Sin carga perezosa automática de relaciones** |
| jOOQ / Criteria API | SQLAlchemy Core | Core es más usado que el ORM en muchos proyectos, y no es una degradación |
| `@Entity` | clase con `DeclarativeBase` y `Mapped[...]` | Los tipos de las columnas salen de las anotaciones |
| `EntityManager` | `Session` | Unidad de trabajo igual; **el alcance lo defines tú** |
| `@Transactional` | `with session.begin():` o `Depends` | **Explícito.** No hay proxy que abra la transacción por ti |
| `session.merge()` | `session.merge()` | Igual, y con la misma capacidad de confundir |
| `@OneToMany(fetch = LAZY)` | `relationship()` + `options(selectinload(...))` | Lo perezoso es **por consulta**, no por mapeo |
| `LazyInitializationException` | `DetachedInstanceError` | Mismo síntoma; aquí llega antes y por eso duele menos |
| `JOIN FETCH` | `joinedload` / `selectinload` | Dos estrategias distintas, y elegir mal cuesta (§5.4) |
| Flyway / Liquibase | Alembic | Igual; genera el esqueleto comparando modelos contra la base |
| HikariCP | el *pool* del `Engine` | Viene incluido, y `create_engine` ya lo trae encendido |
| `BigDecimal` en la columna | `Numeric` → `Decimal` | Igual, y hay que declararlo: si usas `Float`, perdiste |

> 📝 **Nota de ecosistema — SQLAlchemy 1.x y 2.0 se escriben distinto.** La 2.0, de 2023, unificó
> Core y ORM alrededor de `select()` y enterró la API vieja de `session.query(Model).filter(...)`.
> Esa API sigue funcionando y está en **todo** lo que encuentres escrito antes de 2023, incluidos
> los tutoriales más citados. El curso fija **SQLAlchemy 2.0.52** y usa solo el estilo nuevo; si
> copias un ejemplo con `session.query(...)`, funciona, pero estás aprendiendo la forma que la
> biblioteca ya dejó atrás.

### El dominio duro: el plan de Arquitectura de Sonrisa

Antes de modelar, hay que leer el negocio, porque **el modelo obvio no lo soporta**:

- Un plan tiene **cinco fases** en orden, y cada una puede estar en una **sede distinta** y con un
  **responsable distinto**. Édgar hace la fase 1 en Suba y deriva la fase 3 al Centro.
- **La fase 2 ocurre fuera de Áurea**, donde un aliado. Mientras tanto el plan está quieto y nadie
  sabe qué está pasando.
- Cada fase tiene su **consentimiento informado**, firmado por separado y con su fecha.
- El **plan de pagos corre en paralelo** y no coincide con el trabajo: el paciente paga en 24
  cuotas mientras las fases ocurren cuando ocurren.
- Y el plan **es uno solo** aunque lo trabajen tres profesionales de dos sedes, porque lo que se
  le vendió al paciente fue un precio único.

De ahí salen tres decisiones de modelado que el diseño ingenuo no toma:

**La fase es una entidad, no un estado del plan.** Tiene su sede, su responsable, su fecha de
consentimiento y su fecha de último movimiento. Un `status` en la tabla de planes no puede
representar "la fase 1 terminó en Suba y la 3 está esperando en el Centro".

**El dinero del plan y el trabajo del plan son dos líneas de tiempo.** Van en tablas distintas y
se relacionan por el plan, no por la fase. Meter la cuota en la fase obliga a inventar a qué fase
pertenece un pago que se hizo antes de empezar.

**Y hay que poder responder cuándo se movió cada fase por última vez**, porque la pregunta que
Julián hace todos los meses es *"¿qué planes están quietos?"*. Esa columna no aparece en ningún
diseño que no haya oído la pregunta — y es la trampa del miniproyecto.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Los modelos

```python
"""El modelo de persistencia de AgendaAPI."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import ForeignKey, Index, Numeric, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    """Base declarativa del proyecto."""


class TreatmentPlan(Base):
    """Un plan de Arquitectura de Sonrisa: un precio, cinco fases, varios responsables."""

    __tablename__ = "treatment_plans"

    id: Mapped[int] = mapped_column(primary_key=True)
    patient_id: Mapped[int] = mapped_column(ForeignKey("patients.id"), index=True)
    opened_on: Mapped[date]
    # Numeric, NUNCA Float. Es la misma regla del Decimal de la Fase 01, en la columna.
    total_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))

    phases: Mapped[list["PlanPhase"]] = relationship(
        back_populates="plan",
        cascade="all, delete-orphan",
        order_by="PlanPhase.sequence",
    )


class PlanPhase(Base):
    """Una fase del plan. Es una entidad, no un estado: tiene sede y responsable propios."""

    __tablename__ = "plan_phases"
    __table_args__ = (
        # Una fase de cada clase por plan. La regla de negocio, en la tabla.
        UniqueConstraint("plan_id", "kind", name="uq_phase_por_plan"),
        # El índice que hace que la pregunta de Julián cueste una consulta.
        Index("ix_phase_status_moved", "status", "last_moved_on"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("treatment_plans.id"), index=True)
    sequence: Mapped[int]
    kind: Mapped[str]
    branch_id: Mapped[int] = mapped_column(ForeignKey("branches.id"))
    # Nulable a propósito: la fase 2 la ejecuta un aliado externo y no tiene
    # odontólogo de Áurea. `None` significa "afuera", no "todavía no se asignó".
    dentist_id: Mapped[int | None] = mapped_column(ForeignKey("dentists.id"))
    status: Mapped[str]
    consent_signed_on: Mapped[date | None]
    # La columna que no aparece en ningún diseño que no haya oído la pregunta.
    last_moved_on: Mapped[date]

    plan: Mapped[TreatmentPlan] = relationship(back_populates="phases")
```

**Detalles con intención**

- **`Numeric(14, 2)` y no `Float`.** Es la misma decisión de la Fase 01 llevada a la columna, y
  aquí importa más: `psycopg` devuelve `Decimal` desde `Numeric` y `float` desde `Double`. Un
  `Float` en la columna del total arruina el invariante del reparto que la Fase 08 blindó.
  En `sqlite3` la Fase 06 guardó el dinero como `TEXT`, porque SQLite no tiene `DECIMAL`; es la
  misma decisión con otra herramienta, y las dos convierten a `Decimal` al leer.
- **`Numeric` redondea distinto que `Decimal`.** Si llega un valor con más decimales de los que
  la columna admite, Postgres lo redondea **alejándose del cero**, y el `quantize` de Python, por
  defecto, **al par** (`ROUND_HALF_EVEN`). Comprobado con Postgres 18.6: `150000.005` se guarda
  como `150000.01`, y `Decimal("150000.005").quantize(Decimal("0.01"))` da `150000.00`. Es la
  diferencia que la Fase 08 dejó anotada entre `ROUND_HALF_UP` y `ROUND_HALF_EVEN`, y vale plata:
  el redondeo se hace en Python, con la regla escrita —`quantize(..., rounding=ROUND_HALF_UP)` si
  es la que pide la liquidación—, y a la columna llega el valor ya redondeado.
- **`dentist_id` nulable con su significado escrito.** `None` significa *"esta fase la hace un
  aliado externo"*, que es un estado real del dominio. Es la regla de la Fase 08: un `| None` que
  no se puede explicar en una frase del negocio es un caso sin decidir.
- **La restricción de unicidad está en la tabla**, no solo en el código. Es más barata y más
  confiable — y sigue funcionando cuando alguien inserte por otra puerta, que es la lección de la
  Fase 10.
  Es el mismo invariante que la regla 6 del miniproyecto de la Fase 04 —el procedimiento
  duplicado— detectaba en Python, mirando el lote entero: allá costaba un diccionario y una pasada;
  aquí lo impone la base, siempre, y la detección en el código queda para reportar bien el error.
- **`cascade="all, delete-orphan"`** para las fases: no existen sin su plan. Es una decisión de
  dominio y por eso está declarada.

### 5.2 La sesión, y su alcance

```python
"""Conexión y sesión. Una decisión, no un detalle."""

from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

# El pool viene encendido. pool_size es cuántas conexiones se mantienen abiertas,
# y la sección 6 explica por qué eso importa tanto: abrir una cuesta 56 veces
# más que la consulta que vas a hacer con ella.
engine = create_engine(
    settings.database_url,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,   # comprueba la conexión antes de usarla: la red se cae
    echo=False,           # True imprime todo el SQL. Útil una tarde, insoportable dos.
)

SessionFactory = sessionmaker(engine, expire_on_commit=False)


def get_session() -> Iterator[Session]:
    """Dependencia de FastAPI: una sesión por petición, con su transacción.

    Es el equivalente de @Transactional, con la diferencia de que se ve en la
    firma del endpoint y de que el alcance lo decides tú, no una anotación.
    """
    with SessionFactory() as session:
        with session.begin():      # commit al salir bien, rollback si algo lanza
            yield session
```

```python
@app.post("/bookings", response_model=BookingResponse, status_code=201)
def create_booking(
    request: BookingRequest,
    session: Annotated[Session, Depends(get_session)],
) -> Booking:
    ...
```

**Detalles con intención**

- **Una sesión por petición.** Es el alcance correcto para una API y el que evita el 90% de los
  problemas: la sesión es la unidad de trabajo, y la petición es la unidad de trabajo del sistema.
- **Dos `with`, dos trabajos.** El de afuera cierra la sesión y devuelve la conexión al *pool*; el
  de adentro confirma o deshace. Es la trampa de la Fase 06 al revés: allá `with connection:`
  confirmaba y **no** cerraba. Aquí, una sesión que no se cierra se queda con una de las quince
  conexiones del *pool* (`pool_size=5` más `max_overflow=10`), y la petición dieciséis espera
  `pool_timeout` —30 segundos por defecto— antes de fallar.
- **`expire_on_commit=False`.** Por defecto, después de un `commit` SQLAlchemy marca los objetos
  como caducados y **vuelve a consultarlos** al tocar cualquier atributo — lo cual, después de que
  la sesión se cerró, es un `DetachedInstanceError`. Desactivarlo es lo correcto en una API que
  serializa el objeto después del commit. Es el ajuste que más veces se descubre tarde.
- **`pool_pre_ping=True`** porque las conexiones se caen: un cortafuegos que cierra las inactivas,
  un reinicio de la base. Sin esto, la primera petición después de una caída falla siempre.
- **Y la transacción es explícita.** No hay proxy, no hay anotación, no hay sorpresas sobre si
  este método está dentro o fuera de una.

### 5.3 La misma consulta, en las tres formas

```python
# SQL directo: cuando la consulta es el producto y no hay dominio de por medio
SQL_DISPONIBILIDAD = text("""
    SELECT a.starts_at, a.minutes
    FROM appointments a
    JOIN branches b ON b.id = a.branch_id
    WHERE b.name = :branch
      AND a.starts_at >= :day_start
      AND a.starts_at < :day_end
      AND a.status <> 'no_show'
    ORDER BY a.starts_at
""")

with engine.connect() as connection:
    rows = connection.execute(
        SQL_DISPONIBILIDAD, {"branch": "Centro", "day_start": day, "day_end": day + ONE_DAY}
    ).all()
```

```python
# Core: lo mismo, componible y con el dialecto puesto por la biblioteca
stmt = (
    select(appointments.c.starts_at, appointments.c.minutes)
    .join(branches, branches.c.id == appointments.c.branch_id)
    .where(
        branches.c.name == "Centro",
        appointments.c.starts_at >= day,
        appointments.c.starts_at < day + ONE_DAY,
        appointments.c.status != "no_show",
    )
    .order_by(appointments.c.starts_at)
)
```

```python
# ORM: objetos con identidad. Vale la pena cuando lo que sigue es modificarlos.
stmt = (
    select(Appointment)
    .join(Branch, Branch.id == Appointment.branch_id)
    .where(Branch.name == "Centro", Appointment.starts_at >= day, ...)
    .order_by(Appointment.starts_at)
)
appointments = session.scalars(stmt).all()
```

Fíjate en lo que **no** cambia: los tres son la misma consulta, con el mismo `JOIN` y el mismo
`WHERE`. Core no es "SQL más fácil" y el ORM no es "Core más fácil": **los tres exigen que sepas
la consulta que quieres**. Lo que cambia es qué te devuelven y qué puedes hacer con ello.

### 5.4 El N+1, y sus dos arreglos

```python
# ❌ 201 consultas, 42.7 ms
plans = session.scalars(select(TreatmentPlan).limit(200)).all()
total = sum(len(plan.phases) for plan in plans)

# ✅ 2 consultas, 9.4 ms
plans = session.scalars(
    select(TreatmentPlan).options(selectinload(TreatmentPlan.phases)).limit(200)
).all()
```

Y hay **dos** estrategias, que no son intercambiables:

**`selectinload`** emite una segunda consulta con `WHERE plan_id IN (...)`. Dos consultas, cada
fila una vez. Es la correcta para una colección (`one-to-many`).

**`joinedload`** hace un `LEFT JOIN` y trae todo en una consulta. Es la correcta para un
`many-to-one` —el odontólogo de una fase— y es **una mala idea para colecciones**: con 200 planes
de 5 fases, el `JOIN` devuelve 1.000 filas con los datos del plan repetidos cinco veces cada uno.
Una consulta, sí, pero cinco veces más datos por la red.

> 🧭 **La regla corta:** `selectinload` para colecciones, `joinedload` para referencias a uno. Y
> la comprobación que no falla: **cuenta las consultas**. Si no sabes cuántas emite tu endpoint, no
> sabes lo que cuesta.

Y así se cuentan, que es una herramienta de diagnóstico que vale para todo el curso:

```python
from sqlalchemy import event

queries = 0


@event.listens_for(engine, "before_cursor_execute")
def _count(conn, cursor, statement, parameters, context, executemany):
    global queries
    queries += 1
```

### 5.5 Migraciones

```bash
uv run alembic init -t generic migrations
uv run alembic revision --autogenerate -m "plan de tratamiento y fases"
uv run alembic upgrade head
```

`--autogenerate` compara tus modelos contra la base y escribe el esqueleto. **Escribe el
esqueleto, no la migración**: hay que leerlo siempre, porque no detecta bien los renombrados —ve
una columna borrada y otra creada, que sobre una tabla con datos es pérdida total— ni los cambios
de tipo que requieren conversión.

Y la migración que importa en una base con datos: **agregar una columna obligatoria**. Se hace en
tres pasos y no en uno, que es la misma disciplina que ya conoces:

```python
def upgrade() -> None:
    """Agrega last_moved_on, que hasta ahora no existía.

    Tres pasos, porque la tabla ya tiene 3.500 filas y una columna NOT NULL
    sin valor por defecto sobre datos existentes falla.
    """
    # 1. Nulable, para que la tabla existente la acepte.
    op.add_column("plan_phases", sa.Column("last_moved_on", sa.Date(), nullable=True))

    # 2. Se rellena con el mejor dato disponible. Aquí, la fecha de consentimiento
    #    o la de apertura del plan: es una decisión de dominio y va comentada.
    op.execute("""
        UPDATE plan_phases ph
        SET last_moved_on = COALESCE(ph.consent_signed_on, p.opened_on)
        FROM treatment_plans p
        WHERE p.id = ph.plan_id AND ph.last_moved_on IS NULL
    """)

    # 3. Y ahora sí, obligatoria.
    op.alter_column("plan_phases", "last_moved_on", nullable=False)
```

**Prueba de fuego**

```bash
uv run alembic upgrade head
uv run alembic downgrade -1
uv run alembic upgrade head
```

Ida, vuelta y vuelta a ir. Si el `downgrade` falla o pierde datos, la migración no está terminada —
y vas a descubrirlo un martes a las once de la noche en vez de ahora.

Y la mentira que te va a contar la salida si miras el lugar equivocado: `alembic upgrade head`
dice `OK` aunque la migración haya dejado la tabla en un estado que tu código no espera. Lo que
comprueba de verdad es correr las pruebas de la Fase 08 **después** de migrar.

### 5.6 El caso de las 3:40, plantado

Dos auxiliares, en dos sedes, reservan el mismo espacio con dos segundos de diferencia. Es el
incidente más común de Áurea y hoy no lo resolvemos: **lo hacemos imposible en la tabla**.

```python
__table_args__ = (
    # Dos citas no pueden empezar a la misma hora en la misma sede.
    # Es una defensa incompleta —no cubre el solapamiento parcial— y es
    # deliberadamente simple: el problema completo es la Fase 14.
    UniqueConstraint("branch_id", "starts_at", name="uq_cita_por_sede_y_hora"),
)
```

Con eso, la segunda reserva falla con un `IntegrityError` en vez de crear un duplicado. Lo que
falta —cómo se convierte ese error en una respuesta útil, qué pasa con el solapamiento parcial de
una fase de 90 minutos, y cómo se hace todo esto sin que dos transacciones se bloqueen entre sí—
es la **Fase 14**, y ahí se mide.

> ⚠️ **Lo que NO resuelve el problema**, y es donde el instinto de Java manda primero: un `lock` en
> el proceso de Python. `threading.Lock` protege un proceso; AgendaAPI corre con varios procesos
> (la Fase 17 lo mide) y en dos máquinas. **El estado compartido está en Postgres, así que el
> bloqueo tiene que estar en Postgres.** Fase 14.

**El patrón a memorizar**

> Una regla que tiene que cumplirse siempre va en la tabla, no en el código. El código la
> comprueba para dar un mensaje bonito; la tabla la garantiza aunque alguien inserte por otra
> puerta.

---

## 📏 6. Medición — SQL directo, Core y ORM, y el N+1

**Hipótesis.** La diferencia entre SQL directo, Core y ORM es real pero pequeña, y queda enterrada
bajo dos costos mucho mayores: abrir la conexión, y el N+1.

**Condiciones.** **PostgreSQL 18.0** local sobre socket Unix · CPython 3.14.5 · SQLAlchemy 2.0.52
· psycopg 3.3.5 · macOS 26.6 · Apple Silicon · datos: 10 sedes, 34 odontólogos, 2.800 pacientes,
700 planes con 3.500 fases y **23.141 citas** de tres meses, generados con semilla `2026` · la
consulta de disponibilidad devuelve **16 filas** · 40 repeticiones, mediana y p95 · el conteo de
consultas se hace con el *listener* de §5.4.

**Competidores.** La misma consulta escrita de cuatro formas. El SQL directo se mide **dos veces**
—abriendo conexión y reutilizándola— precisamente porque la diferencia entre esas dos es el
hallazgo principal, y presentar solo la versión que abre conexión sería sabotear al SQL directo.

**Resultado — la misma consulta de disponibilidad:**

| Forma | Mediana | p95 | Filas |
|---|---|---|---|
| SQL directo, conexión nueva cada vez | 3.39 ms | 4.38 ms | 16 |
| SQL directo, conexión reutilizada | **0.06 ms** | 0.12 ms | 16 |
| SQLAlchemy Core | 0.51 ms | 1.10 ms | 16 |
| SQLAlchemy ORM | 0.74 ms | 1.50 ms | 16 |

**Resultado — el N+1 sobre 200 planes con sus 1.000 fases:**

| Forma | Mediana | Consultas |
|---|---|---|
| Navegando la relación | 42.7 ms | **201** |
| Con `selectinload` | **9.4 ms** | **2** |

**Y la pregunta de Julián** —*"¿qué planes llevan más de 90 días quietos en la fase periodontal?"*—
escrita de las dos formas:

| Forma | Mediana | Consultas | Planes hallados |
|---|---|---|---|
| Una consulta por plan | 18.6 ms | 701 | 90 |
| Un `JOIN`, una consulta | **0.23 ms** | **1** | 90 |

> ⚖️ **Veredicto. El costo que domina no es el ORM: es la conexión.** Abrirla cuesta **3.39 ms** y
> la consulta **0.06 ms** — **cincuenta y seis veces más**. Cualquier discusión sobre si el ORM
> cuesta 0.23 ms más que Core es irrelevante al lado de eso, y por eso el *pool* no es una
> optimización: es lo que hace que el número tenga sentido. Viniendo de HikariCP esto no te
> sorprende; lo que sí sorprende es cuánta gente compara ORM contra SQL directo abriendo conexión
> en el segundo y sacando conclusiones.
>
> **El ORM cuesta un 45% más que Core** —0.74 contra 0.51 ms— y ese 45% son 0.23 milisegundos que
> compran identidad de objetos, detección de cambios y un dominio que se puede modificar. Para la
> consulta de disponibilidad, que solo se lee y se serializa, **ese gasto no compra nada**: ahí
> Core es la respuesta. Para el plan de tratamiento, que se modifica fase por fase, el ORM se paga
> solo.
>
> **Y el N+1 es de otra magnitud: 4.5× en tiempo y 100× en consultas.** Ese es el problema que de
> verdad hay que vigilar, y la razón por la que la ausencia de carga perezosa automática es una
> virtud: los 201 accesos a la base **los pediste tú**, línea por línea, y se ven en el código.
>
> **El umbral, que es el criterio operativo:** cuando el resultado se lee y se muestra —un reporte,
> una lista, un endpoint de consulta— usa Core o SQL directo. Cuando el resultado se **modifica**,
> usa el ORM. Y cuando dudes, cuenta las consultas: un endpoint que emite más de tres para
> responder una pregunta está mal escrito, independientemente de la herramienta.

**Lo que no se midió, y se declara:** todo esto es sobre un socket Unix local, sin red. En
producción, con la base en otra máquina, cada ida y vuelta cuesta entre 0.3 y 2 ms de red — lo que
**multiplica el castigo del N+1** y hace todavía más irrelevante la diferencia entre Core y ORM.
Tampoco se midió bajo concurrencia (Fase 14), ni con la base fría, ni el comportamiento del *pool*
agotado. Y los 23.141 registros de citas son el volumen de tres meses de Áurea: con diez años de
historia los planes cambian, y el ejercicio 25 lo pide.

---

## 🧱 7. Miniproyecto — *El plan de tratamiento*

**El encargo**

Julián, con el Excel de Patricia abierto: *"Esto es lo que tengo: una fila por paciente, las fases
en columnas, y el estado escrito a mano — 'ok', 'ya pasó a Marce', 'está donde el Dr. Neira'. Yo
lo que necesito saber cada mes es cuáles planes están quietos, dónde están quietos, y desde
cuándo. Porque un plan quieto en la fase 2 son tres millones que no hemos facturado y un paciente
que se nos está enfriando."*

Modela el plan de Arquitectura de Sonrisa completo y responde esa pregunta **en una consulta**.

**Por qué duele**

Porque el modelo obvio —un plan con un estado y cinco fechas— contesta mal casi todo: no sabe que
cada fase tiene su sede, no sabe que la fase 2 ocurre afuera, no puede decir desde cuándo está
quieta, y convierte la pregunta de Julián en un recorrido por todos los planes.

Y porque hay una tensión real entre dos diseños defendibles —la fase como entidad o como columnas
del plan— y la diferencia solo se ve cuando llega la pregunta.

**Datos de entrada**

El esquema que necesitas cubrir, con las reglas del dominio:

1. **Plan**: paciente, fecha de apertura, valor total, y el estado general.
2. **Cinco fases por plan**, en orden: `diagnosis`, `orthodontic`, `periodontal`, `restorative`,
   `retention`. Cada una con **su sede**, **su responsable** —que puede ser `None` si la ejecuta un
   aliado externo—, su estado, y **desde cuándo no se mueve**.
3. **Consentimiento por fase**, con su fecha de firma. Una fase sin consentimiento firmado no se
   puede ejecutar.
4. **Plan de pagos en paralelo**: cuotas con su fecha de vencimiento y su fecha de pago. No se
   relacionan con las fases.
5. **Y la regla que hace interesante el modelo**: la fase 3 no puede empezar si la 1 no terminó.
   Es el argumento clínico de Áurea y el que sostiene el producto.

Los datos de prueba los genera este script, que carga 700 planes con sus 3.500 fases:

```python
"""Carga el dominio de planes de Áurea para trabajar la Fase 11.

Uso:  python cargar_planes.py
Requiere la base creada y las migraciones aplicadas.
"""

import random
from datetime import date, timedelta

from sqlalchemy.orm import Session

from agenda.db import engine
from agenda.models import PlanPhase, TreatmentPlan

PHASES = ["diagnosis", "orthodontic", "periodontal", "restorative", "retention"]
TODAY = date(2026, 9, 12)


def main() -> None:
    rng = random.Random(2026)
    with Session(engine) as session, session.begin():
        for _ in range(700):
            plan = TreatmentPlan(
                patient_id=rng.randint(1, 2800),
                opened_on=date(2025, 1, 1) + timedelta(days=rng.randint(0, 500)),
                total_amount=rng.choice([8_000_000, 12_000_000, 16_000_000, 22_000_000]),
            )
            for sequence, kind in enumerate(PHASES, start=1):
                status = rng.choice(["done", "done", "in_progress", "pending"])
                plan.phases.append(PlanPhase(
                    sequence=sequence,
                    kind=kind,
                    branch_id=rng.randint(1, 10),
                    # La fase periodontal la hace un aliado: sin odontólogo de Áurea.
                    dentist_id=None if kind == "periodontal" else rng.randint(1, 34),
                    status=status,
                    consent_signed_on=date(2025, 6, 1) if status != "pending" else None,
                    last_moved_on=TODAY - timedelta(days=rng.randint(0, 200)),
                ))
            session.add(plan)
    print("700 planes con 3.500 fases cargados")


if __name__ == "__main__":
    main()
```

**Criterios de aceptación**

- [ ] El esquema completo, creado con **migraciones de Alembic**, no con `create_all`. Y una de
      las migraciones agrega una columna obligatoria sobre datos ya cargados, en tres pasos.
- [ ] Las reglas 3 y 5 están **en la base de datos** además de en el código: una fase sin
      consentimiento no se puede marcar `in_progress`, y la fase 3 no puede empezar antes de que
      la 1 termine. Elige el mecanismo —restricción, disparador, o comprobación en la transacción—
      y **justifica por qué ese y no otro**.
- [ ] La pregunta de Julián —planes quietos más de 90 días, con su fase y su sede— se responde en
      **una consulta**, y lo demuestras con el contador de §5.4.
- [ ] Un endpoint `GET /plans/{id}` devuelve el plan con sus cinco fases **en dos consultas como
      máximo**. Demuéstralo.
- [ ] El endpoint de reserva de la Fase 10 ahora persiste, y la restricción de unicidad de §5.6
      impide dos citas en el mismo espacio.
- [ ] **Medición:** tiempo y número de consultas de la pregunta de Julián, en tu implementación y
      en la versión ingenua. Y el tiempo del endpoint del plan. Esos números van en el tag.

**Restricciones de registro**

> Esto es una **aplicación**. Migraciones versionadas, tipos verificados, pruebas contra una base
> de verdad —no un doble—, y transacciones explícitas. Y una restricción propia de esta fase:
> **no escribas un repositorio genérico**. `Repository[T]` con `find_all`, `find_by_id` y `save`
> es la ceremonia de la Fase 03 con ropa de persistencia: la sesión de SQLAlchemy **ya es** el
> repositorio, y envolverla solo agrega una capa que tienes que mantener.

**La trampa**

Vas a modelar las fases como columnas del plan —`phase1_status`, `phase1_branch`,
`phase2_status`…— porque son exactamente cinco y nunca van a ser seis. Es un diseño defendible,
más simple, y con menos `JOIN`.

Y la pregunta de Julián lo destruye: *"¿cuáles planes están quietos y en qué fase?"* sobre columnas
obliga a un `WHERE` con cinco ramas y un `CASE` para decir cuál fase es, y el índice no sirve.
Peor: el día que Áurea agregue una fase de blanqueamiento —que es lo que Marcela quiere desde hace
un año— hay que migrar la tabla y reescribir todas las consultas.

La segunda trampa es más sutil: **`last_moved_on` no existe en ningún diseño que no haya oído la
pregunta**. Si modelas sin esa columna, la respuesta a *"desde cuándo"* hay que deducirla de la
fecha de la última cita, o del historial de cambios que no guardaste. Modelar para las preguntas
que van a hacer, y no solo para los datos que hay, es la diferencia entre este ejercicio y un
CRUD.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Escribe **primero las consultas** que tienes que responder, en SQL, a mano, sobre un esquema que
todavía no existe. Son tres o cuatro. El esquema que las hace fáciles es el esquema correcto.

Ese orden —preguntas primero, tablas después— es lo contrario de lo que produce el reflejo de
mapear el Excel de Patricia a una tabla.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [Declaración de modelos con `Mapped`](https://docs.sqlalchemy.org/en/20/orm/declarative_tables.html)
  y [`relationship`](https://docs.sqlalchemy.org/en/20/orm/basic_relationships.html).
- [Estrategias de carga](https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html) —
  `selectinload` y `joinedload`, con el criterio de §5.4.
- [`CheckConstraint`](https://docs.sqlalchemy.org/en/20/core/constraints.html) para la regla 3, y
  la documentación de Postgres sobre **restricciones de exclusión**, que son la respuesta elegante
  al solapamiento de horarios y que el curso no usa todavía.
- [Alembic — operaciones](https://alembic.sqlalchemy.org/en/latest/ops.html) para la migración en
  tres pasos.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
class TreatmentPlan(Base): ...
class PlanPhase(Base): ...
class Consent(Base): ...          # ¿o es una columna de la fase? decídelo y justifícalo
class Installment(Base): ...      # el plan de pagos, que no cuelga de la fase

def stalled_phases(session: Session, days: int = 90) -> Sequence[StalledPhase]:
    """Una consulta. Con su índice detrás."""

def plan_with_phases(session: Session, plan_id: int) -> TreatmentPlan | None:
    """Dos consultas como máximo."""
```
</details>

**Cómo se entrega**

```bash
uv run alembic upgrade head
uv run python cargar_planes.py
uv run pytest -q
uv run uvicorn agenda.api:app
```

```bash
git add src/agenda migrations/ tests/
git commit -m "fase 11 mini: el plan de tratamiento con sus cinco fases"
git tag -a mini-11 -m "Mini F11: plan de tratamiento · planes quietos en <N> ms y 1 consulta (ingenuo: <M> ms, <Q> consultas)"
```

<details><summary>💡 Solución de referencia — las tres decisiones</summary>

**La decisión de diseño que se tomó.** La fase es una **entidad**, con su fila. El otro camino
—cinco juegos de columnas en el plan— es defendible y más simple mientras las preguntas sean sobre
un plan concreto; se descarta en cuanto las preguntas son **sobre el conjunto de fases**, que es
justo lo que Julián pregunta todos los meses. La prueba está en el número: con la fase como
entidad, "planes quietos" es un `JOIN` con índice y **0.23 ms**; recorriendo plan por plan, 18.6
ms y 701 consultas — **ochenta veces más**.

Y el consentimiento se modeló como **columna de la fase** (`consent_signed_on`) y no como tabla
propia. Es discutible: si algún día hay que guardar el documento firmado, quién lo tomó y por qué
canal, será una tabla. Hoy es una fecha, y una tabla de una columna es ceremonia.

**La trampa, entera.** Las dos mitades son la misma lección: **se modela para las preguntas, no
para los datos**. Las columnas por fase modelan bien el Excel de Patricia —que es una fila por
paciente con las fases al lado— y modelan mal el negocio, porque el negocio pregunta por fases,
no por planes. Y `last_moved_on` es la columna que solo aparece si escuchaste la pregunta
completa: *"cuáles están quietos, dónde, **y desde cuándo**"*.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —el CLI del Bloque
A— esto sería `sqlite3` con el mismo esquema, y funcionaría: la Fase 06 ya demostró que aguanta
cientos de miles de filas. Lo que `sqlite3` no aguanta es **dos procesos escribiendo a la vez**, y
AgendaAPI tiene diez sedes reservando al mismo tiempo — que es exactamente la frontera entre "base
de datos local de un script" y "base de datos de una aplicación", y la razón por la que esta fase
existe. Como script, la pregunta de Julián se contestaría releyendo un CSV cada vez, que es lo que
la Fase 06 midió en 70 ms y lo que dejaría de servir el día que alguien la quiera responder desde
una pantalla.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Cuenta las consultas de un endpoint con el *listener* de §5.4 y repórtalas en la respuesta
   durante el desarrollo. Quítalo después y explica por qué no se deja en producción.
2. Provoca un `DetachedInstanceError` a propósito, léelo, y arréglalo de las dos formas:
   `selectinload` y `expire_on_commit=False`. Explica cuándo cada una.
3. Escribe la consulta de disponibilidad en Core y en ORM y comprueba que emiten el mismo SQL con
   `echo=True`. Compara los dos.
4. Agrega una columna con Alembic, aplica la migración, y haz `downgrade`. Comprueba que la tabla
   volvió a su estado anterior.
5. Cambia `Numeric(14, 2)` por `Float` en el total del plan, carga un valor, y demuestra la
   diferencia al leerlo. Devuélvelo a `Numeric`.
6. Usa `EXPLAIN ANALYZE` sobre la consulta de planes quietos, con y sin el índice. Copia las dos
   salidas.

**🟡 Intermedio (7–14)**

7. Provoca un N+1 de tres niveles —plan → fases → odontólogo— y cuenta las consultas. Arréglalo y
   vuelve a contar.
8. Compara `selectinload` contra `joinedload` para las fases de 200 planes: mide tiempo y cuenta
   las **filas** que devuelve cada uno. Explica la diferencia.
9. Escribe una consulta con agregación —total facturado por sede y mes— en Core, y compárala con
   hacerlo en Python después de traer las filas. Mide las dos.
10. Averigua qué hace `session.flush()` y en qué se diferencia de `commit()`. Construye un caso
    donde necesites el primero.
11. Usa `pool_size=1` y `max_overflow=0`, lanza dos peticiones concurrentes, y observa qué pasa.
    Explica el mensaje.
12. Escribe una prueba de integración que use una transacción con `rollback` al final, de forma
    que la base quede igual. Compárala con recrear el esquema en cada prueba: mide las dos.
13. Consulta la documentación sobre restricciones de exclusión de Postgres (`EXCLUDE USING gist`) y
    escribe la que impediría **el solapamiento parcial** de dos citas. Aplícala y pruébala.
14. Haz que Alembic detecte un renombrado de columna. No va a poder: documenta qué genera y qué
    habrías perdido si lo aplicas sin leerlo.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un endpoint tarda 400 ms en producción y 20 ms en tu máquina. Enumera las
    cuatro causas más probables —dos están en esta fase— y el comando o la consulta que confirma
    cada una.
16. **Diagnóstico.** Los totales del reporte no cuadran con los de la Fase 06 por unos pesos.
    Reprodúcelo con una columna `Float`, cuantifica la diferencia sobre los 700 planes, y explica
    por qué es siempre en la misma dirección.
17. **Medición.** Reproduce la tabla de §6 en tu máquina, incluyendo la versión con conexión nueva
    y con conexión del *pool*. Encuentra **tu** relación entre abrir la conexión y consultar.
18. **Medición.** Mide el N+1 con la base en `localhost` y después con 1 ms de latencia añadida
    (puedes simularla con un `sleep` en un *listener* de eventos). Extrapola qué pasaría con la
    base en otra región.
19. **Medición.** Compara `session.add()` en un bucle contra `session.add_all()` contra
    `insert().values([...])` de Core, para 10.000 filas. Reporta tiempo y consultas.
20. **De registro.** El reporte de planes quietos lo quiere Julián "en el celular, actualizado".
    Decide el registro y qué parte del problema es de persistencia. Conecta con la Fase 12.
21. **De registro.** Patricia pregunta si el histórico del CLI (Fase 06, `sqlite3`) debería
    "mudarse a la base grande". Decide, con el criterio de la solución de referencia, y di qué
    tendría que cambiar para que la respuesta fuera sí.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Rompe el invariante del plan: consigue dejar una fase 3 `in_progress` con la
    fase 1 sin terminar. Hazlo por las tres puertas —el ORM, un `UPDATE` directo, y una migración
    mal escrita— y después ciérralas todas. Documenta cuál mecanismo cierra cuál puerta.
23. **Adversarial y de concurrencia.** Lanza dos procesos que reserven el mismo espacio a la vez y
    documenta exactamente qué pasa con la restricción de §5.6 puesta y sin ella. **No lo
    resuelvas**: es la Fase 14. Describe con precisión el fallo, que es lo que esa fase va a
    arreglar.
24. **Defiende una decisión.** El curso eligió el ORM para el plan y Core para los reportes. Un
    colega dice que mezclar dos estilos en un proyecto es peor que elegir uno. Escribe las dos
    caras con los números de §6, e implementa el reporte de planes quietos con el ORM para poder
    comparar de verdad.
25. **Diseño y medición.** Áurea lleva tres meses de citas (23.141 filas) y crece 20% al año.
    Genera diez años de datos, corre la consulta de disponibilidad y la de planes quietos, y
    encuentra cuál se degrada primero y por qué. Propón el cambio —índice, partición, archivado— y
    mídelo.

**🔥 Opcionales**

- Investiga las restricciones de exclusión de Postgres a fondo y decide si deberían reemplazar la
  `UniqueConstraint` de §5.6. Es la respuesta correcta al solapamiento y casi nadie la conoce.
- Averigua qué es `session.no_autoflush` y construye el caso donde su ausencia produce un error
  desconcertante.
- Lee el SQL que genera el ORM para una consulta con tres `selectinload` anidados. Es la mejor
  forma de entender qué está haciendo por ti.

---

## 📚 9. Referencias

**Documentación oficial**

- [SQLAlchemy 2.0 — Tutorial unificado](https://docs.sqlalchemy.org/en/20/tutorial/) — Core y ORM
  juntos, que es como se entiende la diferencia. Es largo y vale cada minuto.
- [Guía de consultas del ORM](https://docs.sqlalchemy.org/en/20/orm/queryguide/) — en particular
  las estrategias de carga.
- [Alembic](https://alembic.sqlalchemy.org/) — *Auto Generating Migrations* y sus límites, que es
  la sección que más gente no lee.
- [psycopg 3](https://www.psycopg.org/psycopg3/docs/) — adaptación de tipos, y cómo trata
  `Decimal` y `datetime` con zona.
- [PostgreSQL — Índices y `EXPLAIN`](https://www.postgresql.org/docs/18/using-explain.html) — tu
  experiencia de Java transfiere entera aquí.

**PEPs**

- [PEP 249](https://peps.python.org/pep-0249/) — la API de bases de datos que hay debajo de todo
  esto. La Fase 06 ya la nombró con `sqlite3`.

**Orden de lectura sugerido.** Antes de escribir: el tutorial unificado hasta la sección de ORM.
Durante: la guía de estrategias de carga, que es donde está el N+1. Después: los límites de
`--autogenerate` de Alembic, que se entienden mejor después de que te genere una migración
equivocada.

> ⚠️ URLs y contenidos cambian. Y desconfía de cualquier ejemplo de SQLAlchemy con
> `session.query(...)`: es de la 1.x.

---

## 🚀 10. Cierre y conexión con la siguiente fase

AgendaAPI persiste, y el dominio más difícil de Áurea está modelado: cinco fases con su sede, su
responsable y su consentimiento, un plan de pagos que corre por su lado, y la pregunta de Julián
respondida en una consulta y **0.23 ms** en vez de 701 consultas y 18.6 ms.

Lo que te llevas no es SQLAlchemy: es el criterio de **Core para leer, ORM para modificar**, la
costumbre de **contar las consultas**, y la certeza de que la ausencia de carga perezosa
automática —que hoy te pareció una carencia— es lo que hace que el N+1 se vea en la revisión en
vez de en producción.

Y queda plantado el caso que la Fase 14 resuelve: dos auxiliares reservando las 3:40. Hoy la
restricción de la tabla lo hace imposible; falta convertir ese `IntegrityError` en una respuesta
útil, cubrir el solapamiento parcial, y hacerlo sin que las transacciones se bloqueen entre sí.

La **Fase 12** cambia de registro dentro del mismo bloque: nace **el back-office**, con Django y
sus baterías. Y trae el ⚖️ veredicto del curso sobre los dos registros web, con un criterio que
conviene adelantar: **son dos registros, no dos calidades.** Ahí entran los permisos por sede
—Édgar ve Suba y nada más— y la auditoría de accesos, que en el dominio de Áurea no es una mejora
sino un requisito legal.

> **La señal de que quedó bien:** cuando leas un `for` sobre objetos de una consulta, vas a
> preguntarte cuántas consultas emite ese bucle antes de preguntarte qué hace.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-11 -m "F11 cerrada:
> - AgendaAPI persiste en Postgres, con el pool y la sesión por petición
> - Core y ORM distinguidos por criterio, no por nivel de abstracción
> - el N+1 provocado, contado (201 consultas) y arreglado (2)
> - migraciones con Alembic, incluida una columna obligatoria en tres pasos
> - el plan de Arquitectura de Sonrisa modelado con sus cinco fases
> - la pregunta de los planes quietos, en una consulta con su índice"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 11: …`), los de ejercicio su número
> (`fase 11 ej12: …`) y el miniproyecto el suyo (`fase 11 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-11`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
