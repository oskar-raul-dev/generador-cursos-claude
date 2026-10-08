# 🌙 Fase 15 — El proceso nocturno

> Python para desarrolladores Java senior · Fase 15 de 18 · Bloque C
> Depende de: Fase 14 · Habilita: Fase 16
> Registro de esta fase: **aplicación**
> Proyecto que avanza: **nace Cartera**, el cierre nocturno · **y el batch importa el CLI**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Escribir el proceso que corre solo a las dos de la mañana y que alguien tiene que poder **auditar
ocho meses después**.

Son dos exigencias distintas y las dos son de esta fase. La primera es operativa: nadie lo está
mirando, así que tiene que sobrevivir a que algo falle a mitad de camino. La segunda es
contable: cuando Édgar impugne su liquidación del trimestre pasado —y lo va a hacer, lo ha hecho
tres veces— hay que poder reconstruir **cómo se llegó a ese número** con la tasa, la regla y la
fecha que se usaron entonces.

Y aquí se cierra el arco del curso: **el proceso nocturno importa el CLI de Patricia como
biblioteca**. La misma validación que ella corre a mano el día tres es la que corre desatendida a
las dos de la mañana sobre las diez sedes. Ese es el día en que se cobra, en uso real, todo lo que
hiciste bien en la Fase 07.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El cierre es **reanudable**: si cae en la hora cinco, retoma donde iba.
- [ ] El cierre es **idempotente**: correrlo dos veces produce el mismo resultado, no el doble.
- [ ] `from aur.summary import summarize` funciona desde el batch, y entiendes por qué eso es la
      Fase 07 cobrada.
- [ ] Sabes qué es el patrón *outbox* y por qué la cola **no sustituye a la transacción**.
- [ ] Elegiste una herramienta de colas con criterio y **escribiste el costo de la elegida**.
- [ ] Puedes reproducir un número de hace ocho meses con la tasa y la regla de entonces.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Observabilidad** → Fase 16. Hoy el proceso deja rastro en su tabla de auditoría; que alguien
  **se entere** cuando falla es otro problema y tiene su propia fase.
- **Perfilado y optimización** → Fase 16 también. Aquí el cierre se hace correcto; hacerlo rápido
  es el miniproyecto de la siguiente.
- **Orquestadores de flujos** —Airflow, Prefect, Dagster—. Se nombran y se cierran en §5.6: son la
  respuesta cuando hay decenas de trabajos con dependencias entre ellos, y Áurea tiene tres.
- **Contenedores y despliegue** → Fase 17, y solo lo justo para medir.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *el job que arranca de cero cuando falla*.

Es lo que hace casi todo lo que has escrito, y en tu mundo suele estar bien: un trabajo de cinco
minutos que falla se vuelve a lanzar y listo. El problema aparece cuando la ventana es de seis
horas y el fallo llega en la hora cinco.

```python
# ❌ El cierre de todo o nada
def cerrar_mes(mes: str) -> None:
    total = Decimal("0")
    for fila in leer_todas_las_ventas(mes):     # 1.200.000 filas
        total += liquidar(fila)
    guardar_liquidacion(mes, total)              # ← y todo depende de llegar aquí
```

Si eso se cae en la fila 960.000, **no se perdió una hora: se perdió el cierre**. A las dos de la
mañana no hay nadie para relanzarlo, y a las siete Patricia tiene un cierre sin terminar y un día
de trabajo manual por delante.

Y hay algo peor que el reflejo no ve: **relanzarlo puede ser incorrecto**. Si el cierre ya escribió
la mitad de las liquidaciones antes de caer, volver a correrlo desde cero las escribe otra vez. Es
el problema de la Fase 13 —la idempotencia— dentro de tu propio sistema.

**Qué se escribe en su lugar**, y son dos propiedades que van juntas:

**Reanudable**: el trabajo se parte en lotes, y cada lote confirma **su avance y su resultado en la
misma transacción**. Si el proceso muere, el siguiente arranque lee dónde se quedó y sigue.

**Idempotente**: correrlo dos veces produce lo mismo que correrlo una. Eso se consigue con una
clave natural por unidad de trabajo —`(mes, franquiciado)`— y una restricción de unicidad, que es
exactamente lo mismo que hiciste en la Fase 14 con las 3:40.

> 🧭 **Las dos juntas, y no una:** reanudable sin idempotente se corrompe cuando alguien relanza
> desde cero; idempotente sin reanudable funciona pero desperdicia cinco horas. El cierre de Áurea
> necesita las dos.

Y el número, de §6: con punto de control, un fallo al 80% cuesta **0.31 s de recuperación** y cero
filas perdidas; sin él, **1.45 s** y 960.000 filas rehechas. Escalado a la ventana real de seis
horas, la diferencia entre perder cinco horas y perder unos minutos.

### El *outbox*, y por qué la cola no sustituye a la transacción

Este es el concepto que más gente usa mal, y el error es sutil:

```python
# ❌ Parece correcto y tiene una ventana de inconsistencia
def liquidar_franquiciado(session, mes, franquiciado):
    liquidacion = calcular(mes, franquiciado)
    session.add(liquidacion)
    session.commit()                       # ← la base ya tiene el dato
    cola.enviar("notificar-franquiciado", liquidacion.id)   # ← y si esto falla…
```

Si el proceso muere entre el `commit` y el `enviar`, la liquidación existe y **nadie se entera
nunca**. Y si se invierte el orden, el mensaje sale para una liquidación que no llegó a
guardarse. **No hay orden correcto**, porque son dos sistemas distintos y no hay transacción que
los abarque.

El *outbox* resuelve eso con una idea simple: **el mensaje se escribe en tu propia base de datos,
en la misma transacción que el dato**, y un proceso aparte lo publica después.

```python
# ✅ Outbox: una sola transacción, dos filas
def liquidar_franquiciado(session, mes, franquiciado):
    liquidacion = calcular(mes, franquiciado)
    session.add(liquidacion)
    session.add(OutboxMessage(                    # misma transacción
        topic="notificar-franquiciado",
        payload={"liquidacion_id": liquidacion.id, "mes": mes},
        key=f"liq-{mes}-{franquiciado}",          # clave de idempotencia (Fase 13)
    ))
    session.commit()      # o las dos filas, o ninguna


def publicar_pendientes(session, cola):
    """Proceso aparte: lee lo pendiente y lo publica. Al menos una vez."""
    for mensaje in session.scalars(select(OutboxMessage).where(OutboxMessage.sent_at.is_(None))):
        cola.enviar(mensaje.topic, mensaje.payload, key=mensaje.key)
        mensaje.sent_at = now()
        session.commit()
```

El publicador puede mandar un mensaje dos veces —si muere entre el envío y el `commit`— y por eso
**el receptor tiene que ser idempotente**. Es "al menos una vez" otra vez, dentro de casa.

> 🧭 **La regla:** si un cambio en tu base de datos tiene que producir un efecto fuera de ella, esos
> dos hechos no pueden estar en sistemas distintos sin una fila de por medio. El *outbox* es esa
> fila.

### La auditoría línea por línea, que es requisito y no adorno

Édgar impugna su liquidación cada trimestre y **en dos ocasiones ha tenido razón**. La pregunta que
hay que poder contestar ocho meses después no es *"¿cuánto le pagamos?"* — eso está en la tabla—
sino **"¿por qué ese número?"**.

Contestarla exige guardar, por cada línea del cálculo: **qué se sumó, con qué tasa, bajo qué
cláusula, y en qué fecha**. Y lo que casi nadie guarda —y es la trampa del miniproyecto— es **la
tasa**: se lee de la tabla de tarifas en el momento del cálculo, y esa tabla cambia. Ocho meses
después, recalcular da otro número, y no porque el cálculo esté mal.

```python
@dataclass(frozen=True, slots=True)
class SettlementLine:
    """Una línea de la liquidación. Lo que permite defender el número."""

    settlement_id: int
    concept: str              # 'regalía sobre facturación', 'comisión por derivación'
    source_reference: str     # de dónde salió: la factura, el plan, la derivación
    base_amount: Decimal      # sobre cuánto se calculó
    rate: Decimal             # LA TASA QUE SE USÓ, no la que está vigente hoy
    rule_version: str         # la versión de la regla: 'convenio-2025-11'
    computed_amount: Decimal
    computed_at: datetime     # con zona
```

> ⚠️ **Guardar el identificador de la tarifa no alcanza.** Si la fila de tarifas se actualiza en
> sitio, el identificador apunta al valor nuevo y la auditoría miente con total tranquilidad. Hay
> dos salidas: **copiar el valor** en la línea —que es lo que hace el código de arriba— o hacer que
> la tabla de tarifas sea **histórica**, con vigencias, y no se actualice nunca. La segunda es más
> elegante; la primera es la que sobrevive a que alguien haga un `UPDATE` a mano un viernes.

### Esto sí funciona igual

**Todo lo que sabes de procesamiento por lotes se transfiere entero**: puntos de control, ventanas
de ejecución, reintentos, cola de mensajes fallidos, particionar el trabajo, y la disciplina de
que un trabajo nocturno no puede depender de que alguien esté despierto.

**Las colas son colas.** Productor, consumidor, reconocimiento, reintento, cola de fallidos. Si
trabajaste con JMS, RabbitMQ o Kafka, el modelo mental no cambia.

**Y el criterio sobre transacciones es el mismo**, con el mismo problema clásico —la doble
escritura entre la base y la cola— y la misma solución, que allá se llama igual: *transactional
outbox*.

Lo que cambia es que **aquí no hay un Spring Batch**. No existe un framework de referencia con
lectores, procesadores, escritores, puntos de control y reintentos ya resueltos. Se arma con
piezas, y eso es más trabajo y más control.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| Spring Batch | **no hay equivalente** | Se arma con `sqlite3`/Postgres y un bucle. Más trabajo, más control |
| `@Scheduled` | `cron` del sistema, o un planificador de la cola | **Fuera del proceso**, y eso es una ventaja: §5.6 |
| Quartz | APScheduler, o `cron` | Para tres trabajos, `cron` gana |
| JMS / RabbitMQ | Celery, RQ, `arq` | Celery trae su propio protocolo encima del *broker* |
| `@Transactional` en el job | `with session.begin():` por lote | Explícito, y el límite del lote **es** el límite de la transacción |
| *Chunk-oriented processing* | el bucle con su punto de control | Se escribe a mano, y por eso se entiende |
| `JobRepository` | tu propia tabla de avance | Cinco columnas |
| *Transactional outbox* | *transactional outbox* | Idéntico, y en los dos hay que escribirlo |
| `ItemReader` / `ItemWriter` | un generador y una función | Fase 02: el generador **es** el lector |

> 📝 **Nota de ecosistema — Celery, RQ y `arq`.** Celery es el veterano, hace de todo, y trae una
> complejidad proporcional: *broker* más *backend* de resultados, su propio protocolo, y una
> configuración que hay que entender antes de confiar en ella. RQ es mucho más simple y solo habla
> con Redis. `arq` es el hermano asíncrono de RQ, pensado para código `async`. **Ninguno de los
> tres es "el correcto"**: la pregunta es cuánta operación puedes sostener tú solo, y esa pregunta
> tiene una respuesta distinta en una empresa con equipo de plataforma que en Áurea.

### El batch importa el CLI

Y aquí está el momento del curso que conviene no dejar pasar de largo:

```python
"""El cierre nocturno de Áurea."""

from aur.reading import read_rows          # ← el CLI de la Fase 07
from aur.summary import summarize          # ← como biblioteca
from aur.validation import validate_batch
```

```text
el batch importa el CLI como biblioteca:
  procedimientos 598 · pacientes 299 · total $146,175,000
  aur 0.7.0 desde /.../src/aur/__init__.py
```

**Esto es la tesis del curso, ejecutada.** En la Fase 01, `aur_cli.py` era un archivo con el
trabajo colgando de `if __name__ == "__main__":`; importarlo habría ejecutado el trabajo. La Fase
07 lo convirtió en paquete —con módulos con una responsabilidad cada uno y una `main()` que
devuelve un entero en vez de matar el proceso— y la Fase 08 le puso tipos y pruebas.

Nada de eso se hizo pensando en hoy. Y hoy, la misma validación que Patricia corre a mano el día
tres corre desatendida a las dos de la mañana sobre las diez sedes, **sin duplicar una sola línea
de lógica**. Si el CLI hubiera seguido siendo un script, aquí habría dos implementaciones de la
validación — y en seis meses, dos implementaciones distintas.

> 🧭 **La señal de que el Bloque B valió la pena** no es que el código esté bonito: es que la
> pregunta *"¿y cómo hago para que el batch valide igual que el CLI?"* tenga por respuesta un
> `import`.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El lote reanudable

```python
"""El cierre nocturno: reanudable por diseño."""

import hashlib
from decimal import Decimal
from pathlib import Path

from sqlalchemy.orm import Session

BATCH_SIZE = 20_000


def run_closing(session: Session, month: str, source: Path) -> ClosingResult:
    """Procesa el cierre del mes, retomando donde haya quedado.

    El punto de control guarda el DESPLAZAMIENTO EN BYTES, no el número de
    filas: con el número habría que releer y descartar lo ya hecho, que
    convierte la reanudación en cuadrática sobre un archivo grande.
    """
    checkpoint = session.get(ClosingCheckpoint, month) or ClosingCheckpoint(month=month)

    with source.open(encoding="utf-8") as file:
        if checkpoint.offset:
            file.seek(checkpoint.offset)
        else:
            file.readline()          # el encabezado

        while True:
            lines = read_batch(file, BATCH_SIZE)
            if not lines:
                break

            lines_done, amount = process_batch(session, lines, month)

            # El avance y el resultado, en la MISMA transacción: o se confirman
            # los dos o ninguno. Aquí es donde la reanudación se vuelve correcta.
            checkpoint.offset = file.tell()
            checkpoint.rows_done += lines_done
            checkpoint.total += amount
            session.add(checkpoint)
            session.commit()

    checkpoint.finished_at = now()
    session.commit()
    return ClosingResult(month, checkpoint.rows_done, checkpoint.total)


def read_batch(file, size: int) -> list[str]:
    """Lee hasta `size` líneas.

    readline() y no `for line in file`: el iterador de archivo lee por
    adelantado y eso DESHABILITA tell(), que es justo lo que el punto de
    control necesita. El síntoma es un OSError que no explica nada:
    'telling position disabled by next() call'.
    """
    lines = []
    while len(lines) < size:
        line = file.readline()
        if not line:
            break
        lines.append(line)
    return lines
```

**Detalles con intención**

- **El desplazamiento en bytes, no el número de filas.** Es la diferencia entre una reanudación
  constante y una cuadrática, y se descubre midiendo — al escribir esta fase, la primera versión
  usaba el número de filas y el sobrecosto se disparó al 319%. Con desplazamiento, **9%**.
- **`readline()` y no el iterador**, por la razón del docstring. Es un detalle real del lenguaje
  que solo aparece cuando mezclas iteración con `tell()`, y el mensaje de error no ayuda.
- **El tamaño del lote es una decisión con dos costos:** lotes pequeños confirman más seguido
  —menos trabajo perdido— y pagan más transacciones; lotes grandes al revés. Veinte mil filas es
  el punto donde el sobrecosto cae por debajo del 10% en la medición de §6, y **hay que
  recalcularlo si el trabajo por fila cambia**.
- **Y `commit()` explícito por lote**, no autocommit: el lote **es** la unidad de recuperación.

### 5.2 La idempotencia del cierre

Reanudar resuelve el fallo; no resuelve que alguien relance el cierre completo:

```python
class Settlement(Base):
    """La liquidación de un franquiciado en un mes."""

    __tablename__ = "settlements"
    __table_args__ = (
        # La clave natural: un franquiciado, un mes, una liquidación.
        # Correr el cierre dos veces no puede producir dos.
        UniqueConstraint("month", "franchisee_id", name="uq_liquidacion"),
    )
    ...


def settle(session: Session, month: str, franchisee_id: int) -> Settlement:
    """Liquida, o devuelve la liquidación que ya existía.

    Es el mismo patrón de la Fase 13: consultar, y si no está, crear — con la
    restricción de la tabla detrás para cerrar la carrera.
    """
    existing = session.scalar(
        select(Settlement).where(Settlement.month == month,
                                 Settlement.franchisee_id == franchisee_id)
    )
    if existing is not None:
        return existing

    settlement = compute_settlement(session, month, franchisee_id)
    session.add(settlement)
    try:
        session.flush()
    except IntegrityError:
        session.rollback()
        # Otro proceso la creó mientras calculábamos. La suya vale.
        return session.scalar(select(Settlement).where(...))
    return settlement
```

### 5.3 La auditoría que permite defender el número

```python
def compute_settlement(session: Session, month: str, franchisee_id: int) -> Settlement:
    """Calcula la liquidación y deja una línea por cada cosa que se sumó."""
    settlement = Settlement(month=month, franchisee_id=franchisee_id,
                            total=Decimal("0"), computed_at=now())

    # La tarifa se lee UNA vez y se COPIA en cada línea. Leerla otra vez dentro
    # del bucle abriría la puerta a que cambie a mitad del cálculo, y guardar
    # solo su identificador haría que la auditoría mienta si alguien la edita.
    rate = current_royalty_rate(session, franchisee_id, on=month_end(month))

    for invoice in invoices_of(session, month, franchisee_id):
        amount = (invoice.total * rate.value).quantize(CENTAVOS, rounding=ROUND_HALF_UP)
        settlement.lines.append(SettlementLine(
            concept="regalía sobre facturación",
            source_reference=f"factura:{invoice.number}",
            base_amount=invoice.total,
            rate=rate.value,                  # el valor, no el identificador
            rule_version=rate.version,        # 'convenio-2025-11'
            computed_amount=amount,
            computed_at=now(),
        ))
        settlement.total += amount

    return settlement
```

**Prueba de fuego**, y es la pregunta de Édgar:

```sql
SELECT concept, source_reference, base_amount, rate, rule_version, computed_amount
FROM settlement_lines
WHERE settlement_id = (SELECT id FROM settlements
                       WHERE month = '2026-01' AND franchisee_id = 3)
ORDER BY source_reference;
```

Si esa consulta permite reconstruir el total a mano, con una calculadora, la auditoría está bien
hecha. Si hay que volver a correr el cálculo para explicar el número, no lo está — y esa es la
diferencia entre defender una liquidación y pedirle a Édgar que confíe.

Y la mentira que te va a contar la salida si miras el lugar equivocado: **que los totales cuadren
hoy no significa que se puedan reproducir**. Cambia una tarifa en la tabla, vuelve a correr la
consulta, y mira si la auditoría sigue diciendo lo mismo. Si cambió, guardaste el identificador en
vez del valor.

### 5.4 El *outbox*, en su sitio

```python
class OutboxMessage(Base):
    """Un efecto que tiene que ocurrir fuera, escrito dentro de la transacción."""

    __tablename__ = "outbox"
    __table_args__ = (UniqueConstraint("key", name="uq_outbox_key"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    topic: Mapped[str]
    payload: Mapped[dict] = mapped_column(JSON)
    key: Mapped[str]                       # la clave de idempotencia de la Fase 13
    created_at: Mapped[datetime]
    sent_at: Mapped[datetime | None] = mapped_column(index=True)
    attempts: Mapped[int] = mapped_column(default=0)
    last_error: Mapped[str | None]
```

**Detalles con intención**

- **`sent_at` indexado y nulable**, porque la consulta del publicador es *"dame lo que no se ha
  enviado"* y va a correr cada pocos segundos para siempre.
- **`attempts` y `last_error`** para que el mensaje que no sale nunca se pueda encontrar. Sin eso,
  un mensaje envenenado se reintenta por siempre y nadie lo ve.
- **Y la clave de idempotencia viaja con el mensaje**, que es lo que hace que el receptor pueda
  ser idempotente. Es la Fase 13 conectada con esta.

### 5.5 El planificador: `cron` y por qué

Áurea tiene tres trabajos nocturnos. La respuesta es `cron`:

```cron
# Cierre de facturación: todos los días a las 2:00, hora de Bogotá.
0 2 * * *  cd /opt/aurea && .venv/bin/python -m cartera.cierre --mes $(date +\%Y-\%m) >> /var/log/aurea/cierre.log 2>&1

# Publicador del outbox: cada cinco minutos.
*/5 * * * * cd /opt/aurea && .venv/bin/flock -n /tmp/outbox.lock .venv/bin/python -m cartera.outbox
```

**Detalles con intención**

- **`flock -n`** para que dos ejecuciones no se solapen. Sin eso, un publicador lento produce dos
  publicadores, y ahí se duplica. Es el `Lock` de la Fase 14 puesto donde sí sirve: **en el sistema
  operativo, entre procesos**.
- **La salida redirigida a un archivo**, porque `cron` manda por correo lo que el proceso imprima y
  nadie lee ese correo. La Fase 16 lo convierte en registro de verdad.
- **`--mes` explícito y no calculado adentro**: poder relanzar el cierre de enero en marzo es
  exactamente lo que hace falta cuando algo salió mal, y un proceso que siempre calcula "el mes
  actual" no lo permite.
- **Y el planificador vive FUERA del proceso**, que es la ventaja que este perfil no espera: si el
  proceso muere, `cron` sigue vivo; si hay que cambiar la hora, no se despliega nada. Un
  `@Scheduled` dentro de la aplicación acopla las dos cosas.

### 5.6 Cuándo esto deja de alcanzar

`cron` más una tabla de avance resuelve el cierre de Áurea, y conviene decir cuándo dejaría de
hacerlo:

- **Cuando haya dependencias entre trabajos** —*este corre si aquel terminó bien*—. `cron` no sabe
  de eso, y la lógica termina siendo un archivo de banderas. Ahí entran Airflow, Prefect o Dagster.
- **Cuando los trabajos sean muchos y con reintentos diferidos.** Diez trabajos con reintento,
  prioridad y cola de fallidos ya es una cola de verdad: Celery, RQ o `arq`.
- **Y cuando haya que verlo.** Un panel con qué corrió, qué falló y cuánto tardó es la razón más
  común y más legítima para adoptar un orquestador — y es de operación, no de programación.

> ⚖️ **La elección de Áurea, con su costo escrito:** `cron` más tabla de avance. Gana porque son
> tres trabajos sin dependencias entre ellos, porque no hay equipo de plataforma que mantenga un
> Airflow, y porque el único ingeniero prefiere un `crontab` de cuatro líneas que una pieza más
> que puede caerse. **El costo: no hay panel, no hay reintento automático diferido, y la
> visibilidad depende de lo que la Fase 16 construya.** Es una decisión de tamaño de empresa, no
> de calidad de herramienta.

> 📝 **La reconciliación contra el socio que miente** (Fase 13, §5.4) tiene aquí su sitio: sería un
> cuarto trabajo nocturno, con la misma forma que los otros tres —lote reanudable, idempotente por
> día y socio, con líneas de auditoría de cada diferencia— y sin dependencia con ellos, así que
> no cambia la elección de `cron`. Esta fase no lo construye; el ejercicio 25 de la Fase 13 es su
> diseño.

---

## 📏 6. Medición — el fallo de la hora cinco

**Hipótesis.** El punto de control cuesta algo en la corrida normal, y ese costo es despreciable
comparado con lo que ahorra la primera vez que algo falla.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon · el archivo de ventas del trimestre:
**1.200.000 filas**, semilla `2026` · trabajo por fila: un hash de control y una multiplicación en
`Decimal`, que es lo que hace el cierre de verdad · lotes de **20.000 filas** · punto de control en
`sqlite3`, con el desplazamiento en bytes · **fallo inyectado al 80% del trabajo**, que es la hora
cinco de una ventana de seis.

**Competidores.** El cierre de todo o nada de §4 —que es lo que se escribe solo y lo que Áurea
tenía— contra el cierre por lotes con punto de control. **El mismo cálculo en los dos**, verificado
antes de medir.

**Resultado — la corrida normal, sin fallos:**

| | Tiempo | Sobrecosto |
|---|---|---|
| Sin punto de control | 1.35 s | — |
| Con punto de control | 1.47 s | **+9%** |

**Resultado — con el fallo en la hora cinco:**

| | Hasta el fallo | Recuperación | **Total** | **Trabajo perdido** |
|---|---|---|---|---|
| Sin punto de control | 1.15 s | 1.45 s (desde cero) | 2.60 s | **960.000 filas** |
| Con punto de control | 1.25 s | **0.31 s** (reanudando) | **1.56 s** | **0 filas** |

> ⚖️ **Veredicto. El punto de control cuesta un 9% en la corrida buena y ahorra el 100% del
> trabajo en la corrida mala.** Es una de las decisiones de ingeniería más fáciles que vas a
> tomar, y la razón por la que casi nadie la toma es que **el costo se paga todos los días y el
> beneficio llega una vez cada varios meses**.
>
> **Escalado a la ventana real de Áurea**, que es donde el número significa algo: seis horas de
> cierre con un 9% de sobrecosto son unos **32 minutos más**. Un fallo en la hora cinco sin punto
> de control cuesta **cinco horas rehechas** —y, peor, cinco horas que ya no caben en la ventana
> nocturna, así que el cierre no sale y Patricia se entera a las siete. Con punto de control
> cuesta lo que llevaba el lote en curso: **veinte mil filas, segundos**.
>
> **Dónde pierde el punto de control, y hay que decirlo:** ese 9% no es cero, y con un trabajo por
> fila más barato sería proporcionalmente mayor —el punto de control cuesta lo mismo, y el trabajo
> cuesta menos—. Si tu lote procesa cien filas en total, esto es ceremonia. Y el tamaño del lote es
> un parámetro real que hay que elegir: con lotes de 1.000 filas el sobrecosto se dispara, con
> lotes de 200.000 se pierde más trabajo en cada caída.
>
> **Y el hallazgo de método, que vale más que la tabla:** la primera versión de esta medición
> guardaba el **número de filas** procesadas en vez del desplazamiento en bytes, y el sobrecosto
> subía al **319%** — porque reanudar obligaba a releer y descartar todo lo hecho, y eso es
> cuadrático. El punto de control no es *"guardar por dónde voy"*: es **guardar por dónde voy de
> forma que retomar sea constante**. Esa distinción es la fase entera en una línea.
>
> **El umbral:** por debajo de unos pocos minutos de trabajo, el punto de control sobra. Por
> encima de la ventana en la que alguien está despierto para relanzarlo, es obligatorio. En el
> medio decide cuánto duele repetir.

**Lo que no se midió:** el costo con la base de datos remota en vez de `sqlite3` local —donde cada
`commit` de punto de control es una ida y vuelta por red y el sobrecosto sube—, el
comportamiento con lotes de otros tamaños (ejercicio 17), y el cierre corriendo a la vez que la
API atiende usuarios, que es lo que pasa de verdad.

---

## 🧱 7. Miniproyecto — *La liquidación que se puede defender*

**El encargo**

Julián, después de la reunión trimestral: *"Édgar volvió a impugnar. Esta vez le mostré la tabla y
me dijo 'sí, pero ¿de dónde sale ese número?', y no supe qué contestarle. Le dije que lo
calculaba el sistema. Necesito que cuando vuelva a pasar —y va a volver a pasar— yo pueda
sentarme con él y mostrarle línea por línea de dónde salió cada peso. Y que si me lo pregunta el
año entrante sobre un trimestre viejo, la respuesta sea la misma que le di entonces."*

Liquida las regalías de los seis franquiciados y las comisiones de los treinta y cuatro
contratistas: reanudable, idempotente, y **reproducible a ocho meses**.

**Por qué duele**

Porque reproducir un número viejo exige haber guardado cosas que en el momento del cálculo parecen
obvias y que nadie guarda: **la tasa que estaba vigente ese día**, la versión de la regla, y el
soporte de cada línea. Y porque nadie descubre que le faltan hasta que alguien impugna — momento
en el que ya no se pueden recuperar.

**Datos de entrada**

- La facturación del trimestre: el histórico en `sqlite3` de la Fase 06 y las tablas de la Fase 11.
- Las derivaciones a aliados de la Fase 03 (`generar_derivaciones.py`).
- Las tarifas en `tarifas.toml` (Fase 06) **con su fecha de vigencia**, y una segunda versión del
  archivo con tarifas distintas, fechada tres meses después. Las dos tienen que convivir.

Y las reglas del dominio, que son las de Áurea y no son simples:

1. **Regalía de franquicia**: un porcentaje sobre la facturación del mes de la sede.
2. **Comisión de contratista**: por procedimiento ejecutado, según su especialidad.
3. **Comisión por derivación a aliado**: el motor de la Fase 03, con sus tres reglas especiales.
   El tope mensual hace que el resultado dependa del orden (la Fase 03 lo dejó anotado), así que
   el lote se procesa **por (aliado, mes) completo y en orden de fecha**: nunca se corta a la mitad
   de un aliado-mes, o la reanudación cambia la comisión.
4. **Y la que hace daño**: cuando un plan integral se reparte entre dos sedes —Édgar hace la fase 1
   en Suba y deriva la 3 al Centro— **la regalía de ese caso se reparte**, y la regla nunca se
   escribió. Tú la vas a escribir, y por eso tiene que quedar versionada.

**Criterios de aceptación**

- [ ] El cierre procesa el trimestre completo, por lotes, con punto de control, y **reanuda**
      donde quedó. Demuéstralo matando el proceso a la mitad y relanzándolo.
- [ ] Es **idempotente**: correrlo dos veces produce las mismas liquidaciones, no el doble.
      Demuéstralo.
- [ ] **Importa el CLI como biblioteca** —`from aur...`— para validar los datos de entrada, sin
      duplicar la lógica de validación.
- [ ] Cada liquidación tiene sus **líneas de auditoría** con concepto, soporte, base, **tasa**,
      versión de la regla y fecha.
- [ ] **La prueba de los ocho meses, y es bloqueante:** cambia las tarifas a la versión nueva,
      vuelve a consultar la liquidación vieja, y demuestra que **el número y su explicación no
      cambiaron**. Si cambian, guardaste una referencia en vez de un valor.
- [ ] Hay un *outbox*: la notificación al franquiciado se escribe en la misma transacción que la
      liquidación, y un proceso aparte la publica.
- [ ] **Medición:** tiempo del cierre completo, sobrecosto del punto de control, y trabajo perdido
      ante un fallo inyectado al 80%. Esos tres números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación**, y hereda todo lo del Bloque C: tipos, pruebas, migraciones,
> transacciones explícitas. La restricción propia de la fase: **no dupliques la validación**. Si
> te descubres copiando una función del CLI al batch, para — eso es exactamente lo que la Fase 07
> vino a evitar, y la respuesta es un `import`.

**La trampa**

Vas a calcular la liquidación leyendo la tarifa de `tarifas.toml` y guardando el total. Va a
funcionar, los números van a cuadrar, y Édgar va a quedar conforme este trimestre.

Y en noviembre, cuando cambien las tarifas y él impugne la liquidación de marzo, vas a volver a
correr el cálculo para explicárselo y **te va a dar otro número**. En ese momento vas a tener dos
problemas: el de marzo, y el de haber perdido la credibilidad que necesitabas para resolverlo.

La segunda trampa está en la regla 4, la del caso compartido entre sedes: es una regla que **no
existe todavía** —nadie la escribió, se negocia cada vez— y tú la vas a escribir. En cuanto la
escribas en código sin versionarla, el día que se renegocie vas a tener liquidaciones viejas
calculadas con una regla que ya no está en ninguna parte.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Empieza por el final: escribe la **consulta de auditoría** que le vas a mostrar a Édgar, con las
columnas que necesitas para explicar el número sin recalcular nada. Esa consulta define tu tabla
de líneas, y tu tabla de líneas define qué tienes que guardar durante el cálculo.

Es el mismo orden de la Fase 11 —las preguntas antes que las tablas— y aquí la pregunta te la hizo
Édgar literalmente.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- `Decimal.quantize` con `ROUND_HALF_UP` (Fase 08): el redondeo de la contabilidad colombiana **no**
  es el que Python usa por defecto.
- `file.seek()` y `file.tell()` para el punto de control, con la advertencia de §5.1 sobre el
  iterador.
- [`select ... for update`](https://docs.sqlalchemy.org/en/20/orm/queryguide/dml.html) si decides
  bloquear en vez de confiar en la restricción.
- Y para las tarifas con vigencia, una tabla con `valid_from` / `valid_to` y una consulta *"la
  vigente en esta fecha"*. Es un patrón clásico y vale la pena buscarlo por su nombre: *slowly
  changing dimension*.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def run_closing(session, month, source) -> ClosingResult:
    """Por lotes, con punto de control por desplazamiento."""

def settle_franchisee(session, month, franchisee_id) -> Settlement:
    """Idempotente por (mes, franquiciado)."""

def rate_in_effect(session, franchisee_id, on: date) -> Rate:
    """La tasa VIGENTE en esa fecha, no la de hoy."""

def audit_lines(settlement) -> list[SettlementLine]:
    """Una línea por cada peso, con su tasa copiada."""
```
</details>

**Cómo se entrega**

```bash
uv run alembic upgrade head
uv run python -m cartera.cierre --mes 2026-01
uv run python -m cartera.cierre --mes 2026-01      # otra vez: no duplica
uv run python -m cartera.outbox                     # publica lo pendiente
uv run pytest -q
```

```bash
git add src/cartera migrations/ tests/
git commit -m "fase 15 mini: liquidación reanudable, idempotente y auditable"
git tag -a mini-15 -m "Mini F15: liquidación · cierre <N> s, sobrecosto <P>%, perdidas 0 filas ante fallo al 80%"
```

> 📝 **La regla de la Fase 12 vale aquí:** una sola aplicación es dueña de cada tabla. Las del
> cierre —liquidaciones, líneas de auditoría, *outbox*— van en su propio esquema de Postgres, y
> `alembic upgrade head` migra solo ese esquema. Las tablas de Consultorio las sigue migrando Django;
> el cierre las lee sin generarlas, y si necesita un cambio en ellas, el cambio se hace allá.

<details><summary>💡 Solución de referencia — las tres decisiones</summary>

**La decisión de diseño que se tomó.** La tasa se **copia** en cada línea de auditoría, y además
la tabla de tarifas es histórica —con `valid_from` y `valid_to`— y nunca se actualiza en sitio.
Las dos cosas, que es redundante a propósito: la tabla histórica es la fuente correcta, y la copia
en la línea es lo que sobrevive a que alguien haga un `UPDATE` a mano un viernes por la tarde. En
una empresa con control de cambios sobraría la segunda; en Áurea, donde el único ingeniero eres tú
y a veces arreglas datos a mano, no sobra.

**La regla que no existía**, que es la parte del encargo que no es técnica: la regla 4 —el reparto
de la regalía de un caso compartido entre dos sedes— **hay que escribirla y hay que versionarla**.
La solución de referencia la nombra `convenio-2026-01` y la guarda en cada línea que la usa. Y
hace algo más importante: **la escribe en una frase que Julián pueda leerle a Édgar**. Una regla
de reparto que solo existe como código es una regla que nadie puede discutir, y por lo tanto una
que nadie puede aceptar.

**La trampa, entera.** Guardar el identificador de la tarifa en vez del valor produce una auditoría
que **cambia sola**. Es especialmente insidiosa porque todas las pruebas pasan: el número es
correcto hoy, la consulta funciona, y el fallo solo aparece cuando cambia la tarifa —que es
precisamente el momento en que alguien va a mirar la liquidación vieja—. La prueba de aceptación
bloqueante existe por eso, y es la única forma de detectarlo antes de tiempo.

**Qué se habría hecho distinto si el registro fuera otro.** Como script, esto sería lo que Áurea
tenía: una hoja de cálculo con las fórmulas adentro, que Patricia copia cada mes y que **no se
puede auditar** porque la fórmula de marzo se sobrescribió en abril. Como herramienta, sería un
comando del CLI que produce un archivo —y ahí la auditoría sería el archivo, que es defendible y
más frágil—. El registro *aplicación* compra exactamente una cosa aquí, y es la que Julián pidió:
**que la respuesta de hoy sea la misma que la de dentro de ocho meses.**
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe el bucle por lotes con punto de control y mátalo a la mitad con `Ctrl-C`. Relánzalo y
   comprueba que retoma.
2. Provoca el `OSError: telling position disabled by next() call` mezclando `for line in f` con
   `f.tell()`. Copia el mensaje.
3. Corre el cierre dos veces sin idempotencia y muestra las liquidaciones duplicadas. Después
   agrega la restricción y repite.
4. Escribe la tabla del *outbox* y un publicador mínimo. Mata el publicador entre el envío y el
   `commit` y explica qué pasó.
5. Configura una entrada de `cron` con `flock` y demuestra que dos ejecuciones no se solapan.
6. Guarda la tasa en una línea de auditoría, cambia la tarifa vigente, y comprueba que la línea
   vieja no cambió.

**🟡 Intermedio (7–14)**

7. Importa el CLI desde el batch y valida con él un archivo de entrada. Demuestra con
   `aur.__file__` que estás usando el paquete instalado y no una copia.
8. Implementa la cola de mensajes fallidos: después de N intentos, el mensaje del *outbox* se marca
   y deja de reintentarse. Decide N y justifícalo.
9. Haz que el cierre acepte `--desde` y `--hasta` para reprocesar un rango. Explica qué cuidado
   extra hace falta con la idempotencia.
10. Escribe la consulta de auditoría que reconstruye el total de una liquidación sumando sus
    líneas. Compárala con el total guardado y haz que la prueba falle si difieren.
11. Averigua qué hace `ON CONFLICT DO UPDATE` en Postgres y reescribe el punto de control con él en
    vez de con consultar-y-decidir.
12. Implementa la tabla de tarifas con vigencias y la consulta *"la vigente en esta fecha"*.
    Pruébala con una fecha anterior a la primera vigencia.
13. Mide cuánto tarda el cierre con lotes de 1.000, 20.000 y 200.000 filas. Encuentra tu punto.
14. Monta RQ o `arq` con Redis y encola el publicador del *outbox*. Compara con el `cron` de §5.5 en
    complejidad y en lo que ganas.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El cierre terminó "bien" y faltan liquidaciones. Hay tres causas plausibles
    —una es el punto de control confirmado fuera de la transacción del trabajo—. Reprodúcelas.
16. **Diagnóstico.** Un mensaje del *outbox* se envió dos veces. Reproduce el escenario exacto
    —matar el publicador en el momento justo— y explica por qué el receptor idempotente es la
    única defensa.
17. **Medición.** Reproduce la tabla de §6 con tres tamaños de lote y encuentra el punto donde el
    sobrecosto cae por debajo del 5%. Reporta con el arnés.
18. **Medición.** Repite la medición con el punto de control en **Postgres remoto** en vez de
    `sqlite3` local. La diferencia es la latencia de red multiplicada por el número de lotes:
    calcúlala antes de medirla y compara tu estimación con el resultado.
19. **Medición.** Mide cuánto cuesta escribir las líneas de auditoría: el cierre con y sin ellas.
    Decide si el costo es aceptable y qué harías si no lo fuera.
20. **De registro.** Julián quiere "ver el avance del cierre mientras corre". Decide qué registro
    es eso, qué hace falta, y si vale la pena. Conecta con la Fase 16.
21. **De registro.** El cierre tarda seis horas y la ventana nocturna es de seis. Decide qué harías
    **sin** optimizar nada: partir el trabajo, adelantarlo, cambiar la ventana. Hay al menos tres
    respuestas no técnicas.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Corrompe el cierre: consigue que el punto de control diga que se procesaron
    filas que no se procesaron. Hay al menos dos formas y las dos tienen que ver con el límite de
    la transacción. Ciérralas.
23. **Adversarial y contable.** Construye el escenario de Édgar: liquida un trimestre, cambia las
    tarifas, y demuestra que **con tu implementación** la auditoría sigue diciendo lo mismo.
    Después rómpela a propósito —guardando la referencia en vez del valor— y cuantifica la
    diferencia en pesos sobre el trimestre.
24. **Defiende una decisión.** El curso eligió `cron` y una tabla de avance sobre Celery o Airflow.
    Escribe el argumento más fuerte a favor de adoptar un orquestador —existe, y en cuanto Áurea
    crezca va a ganar— y responde con el costo de operarlo. Termina con la condición concreta que
    te haría cambiar.
25. **Diseño.** El cierre y la API comparten la base de datos y corren a la vez. Diseña cómo evitar
    que el cierre bloquee a los usuarios: tamaño de transacción, nivel de aislamiento, orden de
    acceso a las tablas, y qué pasa si un usuario modifica un dato que el cierre ya procesó.
    Conecta con la Fase 14 y con la 11.

**🔥 Opcionales**

- Investiga el patrón *saga* y decide si Áurea lo necesita. La respuesta probablemente es que no, y
  el ejercicio es saber decir por qué.
- Lee sobre *slowly changing dimensions* y compara con tu tabla de tarifas con vigencias. Es el
  mismo problema con nombre de almacén de datos.
- Monta Airflow con los tres trabajos de Áurea y anota cuánto tardaste y cuántas piezas nuevas hay
  que operar. Es la forma honesta de evaluar el veredicto de §5.6.

---

## 📚 9. Referencias

**Documentación oficial**

- [`sqlite3`](https://docs.python.org/3.14/library/sqlite3.html) y
  [SQLAlchemy — transacciones](https://docs.sqlalchemy.org/en/20/orm/session_transaction.html) —
  el límite de la transacción **es** el límite del lote.
- [Métodos de archivo: `seek` y `tell`](https://docs.python.org/3.14/library/io.html) — y la
  advertencia sobre la iteración.
- [Celery](https://docs.celeryq.dev/), [RQ](https://python-rq.org/) y
  [`arq`](https://arq-docs.helpmanual.io/) — los tres, para poder elegir con criterio.
- [`crontab(5)`](https://man7.org/linux/man-pages/man5/crontab.5.html) y `flock(1)` — dos páginas
  de manual que resuelven más de lo que parece.

**Artículos**

- El patrón *transactional outbox* está descrito en los catálogos de patrones de microservicios;
  busca por ese nombre. La descripción canónica explica bien por qué no hay orden correcto entre
  el `commit` y el envío.

**Orden de lectura sugerido.** Antes de escribir: la sección de transacciones de SQLAlchemy, para
tener claro dónde empieza y termina cada lote. Durante: la documentación de la cola que elijas.
Después: el patrón *outbox*, que se entiende mejor cuando ya te pasó el fallo entre el `commit` y
el envío.

> ⚠️ URLs y contenidos cambian; verifica antes de citar.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Áurea tiene su cierre nocturno, y tiene dos propiedades que el anterior no tenía: **retoma donde
quedó** y **se puede defender línea por línea ocho meses después**. La primera cuesta un 9% y
ahorra cinco horas; la segunda no cuesta casi nada y es la diferencia entre discutir con Édgar con
datos o pedirle que confíe.

Y se cerró el arco del curso. El CLI que nació como cuarenta líneas con `split(",")` en la Fase 01
—que se volvió paquete en la 07, que se tipó y se probó en la 08, que se entregó en la 09— hoy lo
**importa el proceso nocturno como biblioteca**. Nada de eso se hizo pensando en este momento, y
ese es precisamente el punto: la estructura que se gana cuando el código la pide sirve para cosas
que no habías previsto. Un script habría obligado a duplicar la validación, y seis meses después
habría dos validaciones distintas.

La **Fase 16** hace operable todo lo que construiste, y trae **dos oficios en una fase**: que
alguien se entere cuando algo falla —registro, trazas, métricas, configuración y secretos— y
optimizar con evidencia en vez de con intuición. Su regla es corta y va contra el instinto:
**primero SQL, después Python**. Y su miniproyecto es bajar el cierre de seis horas, con una
condición que no se negocia: **no se aprueba si optimizas antes de perfilar**.

> **La señal de que quedó bien:** cuando escribas un proceso largo, la pregunta *"¿y si se cae a
> la mitad?"* va a aparecer antes de la primera línea, no después del primer incidente.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-15 -m "F15 cerrada:
> - el cierre es reanudable por desplazamiento, y el punto de control va en la transacción del trabajo
> - es idempotente por (mes, franquiciado), con su restricción en la tabla
> - el batch importa el CLI como biblioteca: una sola validación, dos usos
> - outbox: el efecto externo se escribe dentro de la transacción
> - auditoría línea por línea con la tasa copiada, reproducible a ocho meses
> - medido: +9% de sobrecosto, y 0 filas perdidas ante el fallo del 80%"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 15: …`), los de ejercicio su número
> (`fase 15 ej12: …`) y el miniproyecto el suyo (`fase 15 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-15`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
