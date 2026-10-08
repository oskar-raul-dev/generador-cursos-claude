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
