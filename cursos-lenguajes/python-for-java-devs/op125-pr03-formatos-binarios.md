# 🧱 pr03 — Los formatos binarios

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los eventos de citas de la agenda (`db14`) viajan como JSON: legibles, universales, y grandes. Alguien propone pasarlos a un formato
binario "porque es más rápido", y la discusión se llena de opiniones. Este track pide números, y esta sección los pone: los mismos diez
mil eventos en **JSON** (la biblioteca estándar y `orjson`), **`msgspec`**, **MessagePack**, **CBOR**, **Protobuf** y **Avro**, con el
tamaño, el tiempo de codificar y decodificar, y lo que cada uno hace con una fecha.

La conclusión adelantada, para que se lea el resto con ella en mente: **casi siempre, la mayor ganancia no está en cambiar de formato
sino en cambiar de biblioteca**. Un JSON con `orjson` o `msgspec` está en el mismo orden que los binarios; los binarios ganan en tamaño,
y Protobuf y Avro ganan además lo que no es velocidad: un esquema que evoluciona (`pr01`).

---

## 🧠 2. El modelo

| Formato | Biblioteca | Versión | ¿Esquema? | Una fecha | Para qué |
|---|---|---|---|---|---|
| JSON | `json` (estándar) | — | No | No tiene: texto | Todo lo que se lee o se depura |
| JSON | `orjson` | 3.12.0 | No | Texto ISO, automático | JSON rápido |
| JSON / MessagePack | `msgspec` | 0.22.0 | **Sí, con tipos** (`Struct`) | Texto ISO o extensión | Validación y velocidad en una pieza |
| MessagePack | `msgpack` | 1.2.3 | No | No sin extensión | JSON binario |
| CBOR | `cbor2` | 6.1.5 | No | **Sí** (etiqueta estándar) | JSON binario estandarizado (RFC 8949) |
| Protobuf | `protobuf` | 7.36.2 | Sí, IDL | `Timestamp` | Contratos entre servicios |
| Avro | `fastavro` | 1.12.2 | Sí, IDL | `timestamp-millis` | Kafka, lagos de datos (`jv01`) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, Jackson es rápido y el instinto dice que "JSON es lento" es un mito de otros lenguajes. En Python, el `json` de la biblioteca estándar sí
es lento comparado con las alternativas en C o Rust, y el instinto que viene de Java aplica: antes de cambiar el formato del contrato, se cambia la
biblioteca que lo codifica.

---

## 💻 3. El ejemplo que corre

```bash
uv add orjson msgspec msgpack cbor2 protobuf grpcio-tools fastavro
```

`evento.proto`:

```protobuf
syntax = "proto3";
package aurea.eventos;
message Evento { int64 cita = 1; string sede = 2; string tipo = 3; int64 momento_ms = 4; int64 valor = 5; }
message Lote { repeated Evento eventos = 1; }
```

```bash
python -m grpc_tools.protoc -I . --python_out=. evento.proto
```

`formatos.py`:

```python
"""Diez mil eventos en siete codificaciones: tamaño, tiempo de ida y vuelta, y qué pasa con una fecha."""

import datetime as dt
import io
import json
import random
import time

import cbor2
import fastavro
import msgpack
import msgspec
import orjson

import evento_pb2 as pb

random.seed(5)
BASE = dt.datetime(2026, 10, 5, 7, tzinfo=dt.UTC)
SEDES = ["Centro", "Chapinero", "Suba", "Kennedy"]
events = [{"cita": 100_000 + i, "sede": random.choice(SEDES), "tipo": random.choice(["confirmada", "cancelada"]),
           "momento_ms": int((BASE + dt.timedelta(minutes=i)).timestamp() * 1000), "valor": random.randrange(50_000, 900_000)}
          for i in range(10_000)]


class Evento(msgspec.Struct):
    cita: int
    sede: str
    tipo: str
    momento_ms: int
    valor: int


AVRO = fastavro.parse_schema({"type": "record", "name": "Evento", "fields": [
    {"name": "cita", "type": "long"}, {"name": "sede", "type": "string"}, {"name": "tipo", "type": "string"},
    {"name": "momento_ms", "type": "long"}, {"name": "valor", "type": "long"}]})
msgspec_json = msgspec.json.Decoder(list[Evento])
msgspec_mp = msgspec.msgpack.Decoder(list[Evento])


def avro_encode(rows):
    buf = io.BytesIO()
    fastavro.writer(buf, AVRO, rows)
    return buf.getvalue()


CODECS = {
    "json (estándar)": (lambda r: json.dumps(r).encode(), json.loads),
    "orjson": (orjson.dumps, orjson.loads),
    "msgspec json": (msgspec.json.encode, msgspec_json.decode),
    "msgspec msgpack": (msgspec.msgpack.encode, msgspec_mp.decode),
    "msgpack": (msgpack.packb, msgpack.unpackb),
    "cbor2": (cbor2.dumps, cbor2.loads),
    "protobuf": (lambda r: pb.Lote(eventos=[pb.Evento(**e) for e in r]).SerializeToString(),
                 lambda b: pb.Lote.FromString(b).eventos),
    "avro (fastavro)": (avro_encode, lambda b: list(fastavro.reader(io.BytesIO(b)))),
}

print(f"{'formato':<17}{'bytes':>9}{'ida y vuelta':>15}")
for name, (encode, decode) in CODECS.items():
    data = [msgspec.convert(e, Evento) for e in events] if name.startswith("msgspec") else events
    best = float("inf")
    for _ in range(3):
        start = time.perf_counter()
        blob = encode(data)
        decode(blob)
        best = min(best, time.perf_counter() - start)
    print(f"{name:<17}{len(blob):>9,}{best * 1000:>12.1f} ms")

moment = BASE
for name, fn in [("json", lambda: json.dumps({"m": moment})), ("orjson", lambda: orjson.dumps({"m": moment})),
                 ("cbor2", lambda: cbor2.loads(cbor2.dumps({"m": moment}))["m"])]:
    try:
        print(f"una fecha en {name:<7}→", repr(fn()))
    except TypeError as e:
        print(f"una fecha en {name:<7}→ TypeError: {e}")
```

```bash
python3 formatos.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil, el mejor de tres):

```text
formato              bytes   ida y vuelta
json (estándar)  1,039,069        12.8 ms
orjson             939,070         4.8 ms
msgspec json       939,070         2.9 ms
msgspec msgpack    699,308         2.6 ms
msgpack            699,308         7.2 ms
cbor2              699,308        16.8 ms
protobuf           369,681         8.7 ms
avro (fastavro)    300,361        24.0 ms
una fecha en json   → TypeError: Object of type datetime is not JSON serializable
una fecha en orjson → b'{"m":"2026-10-05T07:00:00+00:00"}'
una fecha en cbor2  → datetime.datetime(2026, 10, 5, 7, 0, tzinfo=datetime.timezone.utc)
```

La tabla confirma la conclusión adelantada y agrega una sorpresa. Pasar de `json` a `orjson` divide el tiempo por 2,7 sin cambiar un byte del contrato, y
`msgspec` lo divide por 4,4 —y además valida—. Los binarios sin esquema ahorran un tercio del tamaño; con esquema, Protobuf y Avro ocupan entre un tercio y
algo menos de un tercio de lo que ocupa JSON. La sorpresa es el tiempo: **Protobuf en Python es más lento que `orjson`** (8,7 contra 4,8 ms), porque construir
diez mil objetos de mensaje desde diccionarios cuesta, y Avro, el más compacto, es el más lento de todos. En Python, los formatos con esquema se eligen por
el contrato y el tamaño, no por la velocidad.

**Detalles con intención**

- **Ida y vuelta** (codificar y decodificar) es lo que paga cada mensaje en un sistema real; medir solo la codificación favorece a los formatos que
  pagan al leer.
- **`msgspec` decodifica a `Struct`** (objetos con tipos) y valida al mismo tiempo; los demás devuelven diccionarios sin validar. No es la misma tarea, y
  por eso se lista aparte.
- **La fecha viaja como milisegundos** en el lote del ejemplo, para que todos los formatos codifiquen lo mismo. Las tres líneas finales muestran qué hace
  cada uno con un `datetime` de verdad: el `json` estándar no sabe, `orjson` lo convierte a texto ISO, y CBOR lo conserva como fecha con su etiqueta.
- **Protobuf y Avro necesitan el esquema** para leer; los demás llevan los nombres de campo en cada mensaje, que es parte de su tamaño.

---

## ⚠️ 4. Lo que se rompe

**Cambiar de formato por velocidad sin medir la biblioteca.** Lo que la tabla muestra: el salto grande está entre `json` y `orjson`/`msgspec`, no entre
JSON y binario.

**Medir con un mensaje.** El costo fijo de cada biblioteca (crear objetos, el esquema) pesa distinto en un mensaje que en diez mil. Se mide con el tamaño
de lote real.

**Binarios en la bitácora.** Un evento en MessagePack en un archivo de bitácora no se lee con `grep`. Si alguien tiene que leer los mensajes, el ahorro en
bytes se paga en horas de depuración.

**La precisión de los números.** JSON no distingue entero de decimal en el cable, y algunos lectores (JavaScript) pierden precisión con enteros de más de
2⁵³. Los montos en Protobuf o Avro van con tipo explícito (`int64`, `decimal`).

---

## ⚖️ 5. Cuándo NO usarlo

**Para el volumen de Áurea.** Diez mil eventos al día codificados con `orjson` cuestan milisegundos. El formato binario se justifica por el contrato (Protobuf,
Avro) o por el volumen, no por costumbre.

**Hacia afuera.** Para aliados, navegadores y personas, JSON.

**MessagePack o CBOR como contrato.** No tienen esquema: son JSON más chico, con los mismos problemas de evolución que el contrato implícito (`pr01`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** la tabla, y cuánto gana `orjson` sobre `json` y cuánto Protobuf sobre `orjson`.
2. Comprime cada salida con `gzip` y compara tamaños. **Criterio:** cuánto se achica la diferencia entre JSON y los binarios.
3. Mide con un solo evento en vez de diez mil. **Criterio:** cómo cambia el orden de la tabla.

**🟡 Intermedio (4–6)**

4. Agrega un campo `Decimal` con el valor y codifícalo en cada formato. **Criterio:** qué formatos lo conservan exacto y cómo.
5. Usa `msgspec` para validar los eventos al decodificar y rechazar uno con `valor` como texto. **Criterio:** el error y cuánto cuesta la validación.
6. Agrega `zstandard` al lote de `orjson`. **Criterio:** el tamaño y el tiempo de ida y vuelta con compresión.

**🟠 Difícil (7–9)**

7. Haz la medición con eventos de 50 campos. **Criterio:** si el orden de la tabla se mantiene.
8. Mide el uso de memoria de cada decodificación (`tracemalloc`, `ob05`). **Criterio:** la tabla de memoria.
9. Publica los eventos en Kafka (`db14`) en `orjson` y en Avro con registro de esquemas. **Criterio:** el tamaño del tema después de 100 000 eventos.

**🔴 Muy difícil (10)**

10. Decide el formato de los eventos de Áurea. **Criterio:** una página. *Rúbrica:* (a) volumen real y costo medido de cada opción; (b) quién lee los mensajes
    (programas, personas, aliados); (c) cómo evoluciona el contrato; (d) la decisión y la cifra que la cambiaría.

---

## 📚 7. Referencias

**Documentación oficial**

- `msgspec`, comparación de rendimiento: https://msgspec.dev/benchmarks
- `orjson`: https://github.com/ijl/orjson
- CBOR, RFC 8949: https://www.rfc-editor.org/rfc/rfc8949
- MessagePack: https://msgpack.org/

**Orden de lectura sugerido:** la página de rendimiento de `msgspec` —con la advertencia de que la escribió el autor de una de las bibliotecas—; después el
RFC de CBOR, sección de etiquetas.

---

## 🚀 8. Cierre

Medidos con los mismos datos, la ganancia grande está en cambiar la biblioteca de JSON (`orjson`, `msgspec`) antes que el formato. Los binarios ganan en tamaño,
y Protobuf y Avro ganan además un esquema que evoluciona; MessagePack y CBOR son JSON más chico sin contrato. Para lo que leen personas, JSON.

**La señal de que quedó bien:** *"Cambiamos `json` por `orjson` en los eventos y el problema de rendimiento desapareció sin tocar el contrato."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-03 -m "op pr03 cerrada: siete codificaciones medidas con los mismos datos"
> ```
>
> Los commits llevan su prefijo (`op pr03: …`) y los de ejercicio su número
> (`op pr03 ej07: …`).
