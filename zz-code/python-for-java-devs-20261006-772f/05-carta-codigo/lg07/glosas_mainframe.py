"""Lee el archivo de glosas de ancho fijo, en EBCDIC y con decimal empaquetado."""

import datetime as dt
import struct
from dataclasses import dataclass
from decimal import Decimal
from collections.abc import Iterator
from pathlib import Path

CODEC = "cp037"  # EBCDIC de EE. UU./Canadá; la aseguradora lo declara en su manual

# El copybook, transcrito a datos: nombre, posición, largo y tipo. Si la aseguradora cambia el
# formato, esta tabla es lo único que se toca.
FIELDS: tuple[tuple[str, int, int, str], ...] = (
    ("record_type", 0, 2, "text"),
    ("provider_nit", 2, 10, "digits"),
    ("invoice_number", 12, 12, "text"),
    ("notified_on", 24, 8, "date"),
    ("objection_code", 32, 4, "text"),
    ("objected_amount", 36, 7, "packed2"),  # S9(11)V99 COMP-3: dos decimales implícitos
    ("note", 43, 40, "text"),
)
RECORD_LENGTH = 83


@dataclass(frozen=True, slots=True)
class ClaimObjection:
    record_type: str
    provider_nit: str
    invoice_number: str
    notified_on: dt.date
    objection_code: str
    objected_amount: Decimal
    note: str


def unpack_packed(raw: bytes, scale: int) -> Decimal:
    """Decodifica un COMP-3: dos dígitos por byte y el signo en el último medio byte."""
    nibbles = []
    for byte in raw:
        nibbles.append(byte >> 4)
        nibbles.append(byte & 0x0F)
    sign_nibble = nibbles.pop()
    if any(n > 9 for n in nibbles):
        raise ValueError(f"decimal empaquetado inválido: {raw.hex()}")
    if sign_nibble not in (0x0C, 0x0D, 0x0F):
        raise ValueError(f"signo de decimal empaquetado desconocido: {sign_nibble:X}")
    sign = 1 if sign_nibble == 0x0D else 0
    # Decimal se arma desde los dígitos y el exponente: nunca pasa por float.
    return Decimal((sign, tuple(nibbles), -scale))


def pack_packed(value: Decimal, length: int, scale: int) -> bytes:
    """La operación inversa, para fabricar archivos de prueba."""
    sign, digits, exponent = value.quantize(Decimal(1).scaleb(-scale)).as_tuple()
    width = length * 2 - 1
    padded = (0,) * (width - len(digits)) + tuple(digits)
    nibbles = (*padded, 0x0D if sign else 0x0C)
    return bytes((nibbles[i] << 4) | nibbles[i + 1] for i in range(0, len(nibbles), 2))


def decode_field(raw: bytes, kind: str) -> object:
    if kind == "packed2":
        return unpack_packed(raw, scale=2)
    text = raw.decode(CODEC).rstrip()
    if kind == "digits" and not text.isdigit():
        raise ValueError(f"se esperaban dígitos y llegó {text!r}")
    if kind == "date":
        return dt.datetime.strptime(text, "%Y%m%d").date()
    return text


def parse_record(record: bytes) -> ClaimObjection:
    if len(record) != RECORD_LENGTH:
        raise ValueError(f"registro de {len(record)} bytes; el copybook dice {RECORD_LENGTH}")
    values = {name: decode_field(record[start:start + size], kind)
              for name, start, size, kind in FIELDS}
    return ClaimObjection(**values)


def read_fixed(path: Path) -> Iterator[ClaimObjection]:
    """Registros fijos pegados, sin saltos de línea: se leen de a RECORD_LENGTH bytes."""
    with path.open("rb") as stream:
        position = 0
        while chunk := stream.read(RECORD_LENGTH):
            if len(chunk) < RECORD_LENGTH:
                raise ValueError(f"el archivo termina con un registro truncado en el byte {position}")
            try:
                yield parse_record(chunk)
            except ValueError as error:
                # El byte de inicio es lo único que la aseguradora entiende cuando se le reclama.
                raise ValueError(f"registro en el byte {position}: {error}") from error
            position += RECORD_LENGTH


def read_variable(path: Path) -> Iterator[bytes]:
    """Registros variables con RDW: dos bytes de largo (incluido el RDW) y dos en cero."""
    data = path.read_bytes()
    position = 0
    while position < len(data):
        length, reserved = struct.unpack_from(">HH", data, position)
        if reserved != 0 or length < 4:
            raise ValueError(f"RDW inválido en el byte {position}: {data[position:position + 4].hex()}")
        yield data[position + 4:position + length]
        position += length


def encode_record(objection: ClaimObjection) -> bytes:
    """Fabrica un registro con el mismo formato, para pruebas."""
    parts = []
    for name, _, size, kind in FIELDS:
        value = getattr(objection, name)
        if kind == "packed2":
            parts.append(pack_packed(value, size, scale=2))
        elif kind == "date":
            parts.append(value.strftime("%Y%m%d").encode(CODEC))
        else:
            parts.append(str(value).ljust(size)[:size].encode(CODEC))
    return b"".join(parts)


if __name__ == "__main__":
    sample = [
        ClaimObjection("GL", "9001234567", "FE-000123", dt.date(2026, 9, 28), "1102",
                       Decimal("185000.00"), "SOPORTE DE RADIOGRAFIA FALTANTE"),
        ClaimObjection("GL", "9001234567", "FE-000131", dt.date(2026, 9, 29), "2301",
                       Decimal("-12500.50"), "AJUSTE A FAVOR DEL PRESTADOR"),
    ]
    path = Path("glosas.dat")
    path.write_bytes(b"".join(encode_record(item) for item in sample))
    print(path.read_bytes()[:16].hex(" "))
    for objection in read_fixed(path):
        print(objection.invoice_number, objection.objection_code, objection.objected_amount)
