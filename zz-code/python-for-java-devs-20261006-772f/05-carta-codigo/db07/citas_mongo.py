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
