# 🍃 db07 — Documental: MongoDB

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 7 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El operador de la agenda en línea que Áurea evalúa guarda cada cita como un documento de MongoDB: la sede, la hora, el
motivo general (control, limpieza, valoración), los recordatorios enviados con sus estados, y lo que cada sede quiso agregar
con los años. Para integrarse, el ingeniero de Áurea va a leer y escribir esa colección desde Python.

MongoDB se usa desde Python con **`pymongo`** —el *driver* oficial, que ahora incluye también la versión asíncrona— y
opcionalmente con **Beanie**, un ODM sobre Pydantic. Los documentos son diccionarios de Python, y eso hace que el primer día
sea agradable. Las trampas aparecen con datos reales: **la consulta sin índice** que recorre toda la colección sin que nadie
lo note, **el documento que crece** hasta el límite de 16 MB, y **los tipos que BSON no tiene**, empezando por el `Decimal`
de los montos.

---

## 🧠 2. El modelo

| Python | BSON (lo que guarda MongoDB) | La trampa |
|---|---|---|
| `dict` | Documento | Hasta **16 MB** por documento |
| `str`, `int`, `float`, `bool`, `None`, `list` | Sus equivalentes | — |
| `datetime.datetime` | Fecha en UTC, con milisegundos | Vuelve **sin zona horaria** y truncada a milisegundos |
| `datetime.date` | **No existe** | `InvalidDocument` |
| `decimal.Decimal` | **No se codifica directamente** | `InvalidDocument`; se usa `bson.Decimal128` |
| — | `ObjectId` como `_id` por defecto | Se genera en el cliente |

| Cliente | Versión | Para qué |
|---|---|---|
| `pymongo` | 4.18.2 | El *driver*: síncrono y asíncrono (`AsyncMongoClient`) |
| Beanie | 2.2.0 | ODM con Pydantic, asíncrono; modelos con validación |

### Tu instinto de Java dice… y esta vez se equivoca

Con Spring Data MongoDB, los `@Document` se mapean solos y `BigDecimal` se guarda como `Decimal128` o como texto según la
configuración. El instinto espera que `pymongo` haga lo mismo con `Decimal`. No lo hace: `pymongo` no tiene mapeo de objetos
y rechaza lo que BSON no sabe codificar. La conversión es explícita, o la hace Beanie.

---

## 💻 3. El ejemplo que corre

```bash
uv add pymongo
```

`citas_mongo.py`:

```python
"""MongoDB desde Python: la consulta sin índice, el documento de 16 MB y el Decimal que BSON no codifica."""

import datetime as dt
import os
import random
from decimal import Decimal

from bson import Decimal128
from bson.errors import InvalidDocument
from pymongo import ASCENDING, MongoClient
from pymongo.errors import DocumentTooLarge

client = MongoClient(os.environ.get("AUREA_MONGO", "mongodb://mongo:27017"), serverSelectionTimeoutMS=30_000)
print("servidor:", client.server_info()["version"])
db = client.agenda
db.cita.drop()

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
random.seed(7)
base = dt.datetime(2026, 1, 1, 7, tzinfo=dt.UTC)
db.cita.insert_many([{"sede": random.choice(SEDES), "inicio": base + dt.timedelta(minutes=30 * i),
                      "motivo": random.choice(["control", "limpieza", "valoración"])} for i in range(200_000)])


def plan(query: dict) -> str:
    stats = db.cita.find(query).explain()["executionStats"]
    stage = stats["executionStages"]
    while "inputStage" in stage:
        stage = stage["inputStage"]
    return f"{stage['stage']}, {stats['totalDocsExamined']} documentos examinados para {stats['nReturned']}"


q = {"sede": "Suba", "inicio": {"$gte": dt.datetime(2026, 9, 1, tzinfo=dt.UTC)}}
print("sin índice:", plan(q))
db.cita.create_index([("sede", ASCENDING), ("inicio", ASCENDING)])
print("con índice:", plan(q))

# El documento que crece: todos los recordatorios de una sede en un solo documento.
reminders = [{"cita": i, "canal": "whatsapp", "estado": "entregado", "texto": "x" * 200} for i in range(80_000)]
try:
    db.sede.insert_one({"_id": "Suba", "recordatorios": reminders})
except DocumentTooLarge as e:
    print("documento de la sede:", str(e)[:90])

# Los montos: Decimal no se codifica; Decimal128 sí.
try:
    db.abono.insert_one({"sede": "Suba", "valor": Decimal("1250000.10")})
except InvalidDocument as e:
    print("Decimal:", e)
db.abono.insert_one({"sede": "Suba", "valor": Decimal128(Decimal("1250000.10"))})
stored = db.abono.find_one({"sede": "Suba"})["valor"]
print("Decimal128:", repr(stored), "→", repr(stored.to_decimal()))

when = db.cita.find_one({}, sort=[("inicio", ASCENDING)])["inicio"]
print("fecha leída:", repr(when))
```

```bash
docker run -d --name aurea-mongo -p 27017:27017 mongo:8.0.20
AUREA_MONGO=mongodb://localhost:27017 python3 citas_mongo.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
servidor: 8.0.20
sin índice: COLLSCAN, 200000 documentos examinados para 18722
con índice: IXSCAN, 18722 documentos examinados para 18722
documento de la sede: BSON document too large (22069027 bytes) - the connected server supports BSON document siz
Decimal: Invalid document: cannot encode object: Decimal('1250000.10'), of type: <class 'decimal.Decimal'>
Decimal128: Decimal128('1250000.10') → Decimal('1250000.10')
fecha leída: datetime.datetime(2026, 1, 1, 7, 0)
```

Para devolver 18 722 citas de Suba, la consulta sin índice examinó las 200 000 de la colección; con el índice, exactamente las
18 722. Nada en el resultado dice cuál de las dos pasó: solo `explain()`. El documento de la sede con sus 80 000 recordatorios
pesaba 22 MB y el cliente lo rechazó antes de mandarlo. El `Decimal` no se pudo guardar hasta envolverlo en `Decimal128`, y la
fecha guardada en UTC volvió sin zona.

**Detalles con intención**

- **`explain()`** dice si la consulta usó un índice (`IXSCAN`) o recorrió la colección (`COLLSCAN`), y cuántos documentos
  examinó para devolver los que devolvió. Es la única forma de saberlo: MongoDB no avisa.
- **El índice compuesto `(sede, inicio)`** sigue la regla de igualdad primero, rango después: la sede se compara por igualdad y
  la fecha por rango.
- **`DocumentTooLarge` lo lanza el cliente** antes de mandar nada: `pymongo` conoce el límite del servidor.
- **La fecha vuelve sin zona** aunque se guardó con UTC: MongoDB guarda UTC y `pymongo` devuelve `datetime` ingenuos por defecto.
  `MongoClient(..., tz_aware=True)` las devuelve con zona.

---

## ⚠️ 4. Lo que se rompe

**El índice que creías que existía.** En desarrollo hay cien documentos y todo es rápido; en producción hay millones y la
consulta del tablero recorre la colección entera. Los índices se crean en el código de despliegue, y las consultas importantes
tienen una prueba con `explain()`.

**Incrustar lo que crece sin límite.** Incrustar los recordatorios dentro de la cita está bien (son pocos); incrustarlos dentro de
la sede no, porque crecen para siempre. La regla: se incrusta lo que tiene un tamaño acotado y se lee junto.

**Los *joins*.** `$lookup` existe y funciona, pero no es un *join* con índices como el de Postgres, y en colecciones grandes es
lento. Si el modelo necesita muchos *joins*, el modelo es relacional.

**Escribir sin *write concern* adecuado.** Por defecto, `pymongo` espera la confirmación de la mayoría del conjunto de réplicas
(`w="majority"`, en versiones recientes). Bajarlo para "ir más rápido" es aceptar perder escrituras confirmadas si cae el primario.

---

## ⚖️ 5. Cuándo NO usarlo

**Para los abonos y la cartera.** Son datos relacionales con totales que tienen que cuadrar: Postgres.

**Porque "no hay que definir un esquema".** El esquema existe igual, en el código que lee; sin validación en la base, cada
documento viejo es una excepción en producción. MongoDB tiene validación con JSON Schema y conviene usarla.

**Para algo nuevo en Áurea si Postgres con `jsonb` alcanza.** Un documento flexible dentro de una tabla de Postgres da casi todo
lo que da MongoDB para este volumen.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** los documentos examinados sin y con índice, y la razón entre ellos.
2. Conecta con `tz_aware=True` y lee la fecha. **Criterio:** vuelve con `tzinfo=UTC`.
3. Intenta guardar un `datetime.date`. **Criterio:** el error exacto, y cómo lo guardarías.

**🟡 Intermedio (4–6)**

4. Crea el índice al revés, `(inicio, sede)`, y compara `explain()`. **Criterio:** los documentos examinados en cada caso.
5. Escribe el modelo de la cita con Beanie y un campo `valor: Decimal`. **Criterio:** se guarda y se lee como `Decimal` sin código
   de conversión tuyo.
6. Agrega validación con `$jsonSchema` a la colección: `sede` obligatoria y de la lista. **Criterio:** una cita de una sede que no
   existe se rechaza en la base.

**🟠 Difícil (7–9)**

7. Rediseña los recordatorios en su propia colección con índice por sede y fecha. **Criterio:** la consulta "recordatorios de Suba de
   ayer" usa `IXSCAN`.
8. Usa `AsyncMongoClient` para insertar 200 000 citas en lotes concurrentes. **Criterio:** el tiempo contra el cliente síncrono.
9. Escribe una prueba de CI que falle si una consulta registrada usa `COLLSCAN`. **Criterio:** borrar el índice hace fallar la prueba.

**🔴 Muy difícil (10)**

10. Diseña la integración con la agenda del operador. **Criterio:** una página. *Rúbrica:* (a) qué se lee y qué se escribe; (b) los
    índices que se le piden al operador, con su `explain()`; (c) cómo se convierten fechas y montos; (d) qué pasa si el esquema
    del operador cambia.

---

## 📚 7. Referencias

**Documentación oficial**

- `pymongo`: https://pymongo.readthedocs.io/en/stable/
- MongoDB, `explain`: https://www.mongodb.com/docs/manual/reference/explain-results/
- MongoDB, índices compuestos (igualdad, orden, rango): https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/
- Beanie: https://beanie-odm.dev/

**Orden de lectura sugerido:** la guía de igualdad, orden y rango para índices compuestos; después la de resultados de `explain`.

---

## 🚀 8. Cierre

`pymongo` convierte documentos en diccionarios y no mapea nada más: `Decimal` se guarda como `Decimal128`, las fechas vuelven sin
zona salvo que se pida, y lo que BSON no tiene se rechaza. Las consultas se verifican con `explain()` porque MongoDB no avisa de un
recorrido completo, y se incrusta solo lo que tiene tamaño acotado.

**La señal de que quedó bien:** *"La consulta de citas de Suba examina los documentos que devuelve, ni uno más, y los montos llegan
como `Decimal`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-07 -m "op db07 cerrada: explain, el límite de 16 MB y Decimal128"
> ```
>
> Los commits llevan su prefijo (`op db07: …`) y los de ejercicio su número
> (`op db07 ej07: …`).
