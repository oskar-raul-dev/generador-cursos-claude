"""Lee un plano hostil: encoding por línea, reparación con certeza, cuarentena y conciliación."""

import csv
import io
from collections import Counter
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
from pathlib import Path

import ftfy
from charset_normalizer import from_bytes

EXPECTED_COLUMNS = 6  # sede;documento;paciente;codigo;fecha;valor


@dataclass
class Result:
    rows: list[dict[str, str]] = field(default_factory=list)
    quarantine: list[tuple[int, str, str]] = field(default_factory=list)  # (línea, razón, texto)
    encodings: Counter = field(default_factory=Counter)
    repaired: int = 0


def decode_line(raw: bytes) -> tuple[str, str]:
    """UTF-8 estricto primero; si falla, Windows-1252. Devuelve el texto y el encoding usado."""
    try:
        return raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace"), "cp1252"


def split_lines(data: bytes) -> list[bytes]:
    """Normaliza los tres finales de línea (\\r\\n, \\n y \\r solo) y quita los bytes nulos."""
    data = data.replace(b"\x00", b"").replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]
    return data.split(b"\n")


def read_hostile(path: Path) -> Result:
    data = path.read_bytes()
    # Una sola opinión sobre el archivo entero, para el informe. La decisión es por línea.
    guess = from_bytes(data).best()
    print("charset-normalizer dice:", guess.encoding if guess else "no sabe")

    result = Result()
    lines = split_lines(data)
    header = None
    for number, raw in enumerate(lines, start=1):
        if not raw.strip():
            continue
        text, encoding = decode_line(raw)
        result.encodings[encoding] += 1
        fixed = ftfy.fix_text(text)  # deshace la doble codificación; no inventa nada
        if fixed != text:
            result.repaired += 1
        fields = next(csv.reader(io.StringIO(fixed), delimiter=";"))
        if header is None:
            header = [f.strip().lower() for f in fields]
            continue
        if len(fields) != EXPECTED_COLUMNS:
            result.quarantine.append((number, f"{len(fields)} columnas", fixed))
            continue
        row = dict(zip(header, (f.strip() for f in fields), strict=True))
        try:
            Decimal(row["valor"].replace(".", "").replace(",", "."))
        except InvalidOperation:
            result.quarantine.append((number, "valor no numérico", fixed))
            continue
        result.rows.append(row)
    return result


def reconcile(result: Result, expected_rows: int, expected_total: Decimal) -> str:
    clean_total = sum(Decimal(r["valor"].replace(".", "").replace(",", ".")) for r in result.rows)
    accounted = len(result.rows) + len(result.quarantine)
    if accounted != expected_rows:
        return f"FALTAN FILAS: {accounted} contadas de {expected_rows}"
    return (f"{len(result.rows)} limpias suman {clean_total}; {len(result.quarantine)} en "
            f"cuarentena; esperado {expected_total}")


def write_sample(path: Path) -> None:
    """Un plano hostil de muestra: dos encodings, mojibake, una fila rota, nulos y \\r suelto."""
    utf8_part = (
        "sede;documento;paciente;codigo;fecha;valor\r\n"
        "SUBA;1023456789;Rodríguez Peña Ana;D0120;2026-09-02;185.000,00\r\n"
        "SUBA;52987654;RodrÃ­guez Mora Luis;D1110;2026-09-03;95.000,00\r\n"
    ).encode("utf-8")
    cp1252_part = (
        "SUBA;80123456;Muñoz Óscar;D2391;2026-09-04;210.000,00\r"
        "SUBA;1019876543;Ibáñez Sofía;D0150;2026-09-05;60.000,00;nota con ; suelto\n"
    ).encode("cp1252")
    path.write_bytes(utf8_part + cp1252_part + b"\x00\x00")


if __name__ == "__main__":
    path = Path("suba-septiembre.csv")
    write_sample(path)
    result = read_hostile(path)
    print("encodings por línea:", dict(result.encodings))
    print("reparadas:", result.repaired)
    for row in result.rows:
        print("  ok", row["documento"], row["paciente"], row["valor"])
    for number, reason, text in result.quarantine:
        print(f"  cuarentena línea {number}: {reason}")
    print(reconcile(result, expected_rows=4, expected_total=Decimal("550000.00")))
