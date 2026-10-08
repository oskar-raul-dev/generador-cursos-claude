"""El cambio del viernes en los tres escalones: JSON implícito, esquema de Pydantic y Protobuf."""

import importlib.util
import json

from pydantic import BaseModel, ValidationError


def load(path: str):
    spec = importlib.util.spec_from_file_location(path.replace("/", "_"), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# El productor ya está en la versión 2.
new_json = json.dumps({"sede_id": 3, "hora": "09:00"})

# ------------------------------------------------- 1. contrato implícito
try:
    message = json.loads(new_json)
    print("implícito:", f"recordatorio para la sede {message['sede']}")
except KeyError as e:
    print(f"implícito: KeyError {e} — en producción, en cada mensaje")


# ------------------------------------------------- 2. esquema compartido
class CitaConfirmada(BaseModel):
    sede: str
    hora: str


try:
    CitaConfirmada.model_validate_json(new_json)
except ValidationError as e:
    error = e.errors()[0]
    print(f"esquema:   rechazado en la frontera · campo {error['loc']} · {error['msg']}")

# ------------------------------------------------- 3. IDL con números de campo
v1, v2 = load("v1/cita_pb2.py"), load("v2/cita_pb2.py")
wire = v2.CitaConfirmada(sede_nombre="Suba", hora="09:00", sede_id=3).SerializeToString()
old_reader = v1.CitaConfirmada.FromString(wire)
print(f"protobuf:  el lector v1 lee sede={old_reader.sede!r}, hora={old_reader.hora!r} · {len(wire)} bytes en el cable")
print("           el campo nuevo, para el lector v1:", "ignorado y conservado" if old_reader.SerializeToString() == wire else "perdido")
