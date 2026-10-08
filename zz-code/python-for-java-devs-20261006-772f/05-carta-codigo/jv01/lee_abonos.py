"""Leer en Python lo que Java escribió en Avro, y leerlo con un esquema que evolucionó."""

import json

import fastavro

with open("abonos.avro", "rb") as f:
    reader = fastavro.reader(f)
    print("esquema del archivo:", reader.writer_schema["name"], "· códec:", reader.codec)
    for record in reader:
        print(" ", record["sede"], repr(record["valor"]), repr(record["momento"]))

# El servicio Java aún no agrega 'canal'; el consumidor Python ya lo espera, con valor por defecto.
reader_schema = json.load(open("abono.avsc"))
reader_schema["fields"].append({"name": "canal", "type": ["null", "string"], "default": None})
with open("abonos.avro", "rb") as f:
    first = next(fastavro.reader(f, reader_schema=fastavro.parse_schema(reader_schema)))
print("con el esquema nuevo:", {k: first[k] for k in ("sede", "canal")})
