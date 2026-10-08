"""aur — la caja de herramientas de Patricia.

Estado al cerrar el Bloque A (Fase 06): un archivo, stdlib pura, cero dependencias.
"""

import argparse
import csv
import re
import sqlite3
import sys
import tomllib
from dataclasses import dataclass
from decimal import Decimal, InvalidOperation
from pathlib import Path

VALID_BRANCHES = frozenset({
    "Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
    "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira",
})
NOTE = re.compile(r"\s*\(.*\)\s*$")


class AurError(Exception):
    """Error del dominio de Áurea."""


class InvalidRow(AurError):
    """Una fila que no se puede facturar."""

    def __init__(self, line_number, field, reason):
        self.line_number = line_number
        self.field = field
        self.reason = reason
        super().__init__(f"fila {line_number}, campo '{field}': {reason}")


@dataclass(frozen=True, slots=True)
class Row:
    """Una fila del export, normalizada."""

    document: str
    patient: str
    branch: str
    date: str
    code: str
    description: str
    amount: Decimal


def parse_amount(raw):
    """Convierte el valor a Decimal aceptando las formas de las tres sedes."""
    cleaned = NOTE.sub("", raw).strip()
    if cleaned.count(".") == 1 and len(cleaned.rsplit(".", 1)[1]) == 3:
        cleaned = cleaned.replace(".", "")
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        raise InvalidRow(0, "valor", f"no es un número: {raw!r}") from None


def read_rows(path, encoding="utf-8-sig", delimiter=","):
    """Lee un export y produce filas normalizadas."""
    with path.open(encoding=encoding, newline="") as file:
        for record in csv.DictReader(file, delimiter=delimiter):
            yield Row(
                document=record["documento"].strip(),
                patient=record["paciente"].strip(),
                branch=record["sede"].strip(),
                date=record["fecha"].strip(),
                code=record["codigo"].strip(),
                description=record.get("descripcion", "").strip(),
                amount=parse_amount(record["valor"]),
            )


def summarize(rows):
    """Resumen del mes: procedimientos, pacientes distintos y total."""
    total = Decimal("0")
    patients = set()
    by_code = {}
    count = 0
    for row in rows:
        count += 1
        total += row.amount
        patients.add(row.document)
        by_code[row.code] = by_code.get(row.code, Decimal("0")) + row.amount
    return {
        "procedimientos": count,
        "pacientes": len(patients),
        "total": total,
        "por_codigo": by_code,
    }


def render(summary, path):
    """La salida que ve Patricia."""
    lines = [
        f"Resumen de {path}",
        f"  procedimientos: {summary['procedimientos']}",
        f"  pacientes distintos: {summary['pacientes']}",
        f"  facturado: ${summary['total']:,.0f}",
    ]
    for code, amount in sorted(summary["por_codigo"].items()):
        lines.append(f"    {code}  ${amount:>12,.0f}")
    return "\n".join(lines)


def validate_row(row, line_number):
    """Comprueba una fila."""
    if not row.document.strip().isdigit():
        raise InvalidRow(line_number, "documento", f"no es numérico: {row.document!r}")
    if row.branch not in VALID_BRANCHES:
        raise InvalidRow(line_number, "sede", f"no es una sede de la red: {row.branch!r}")
    if row.amount <= 0:
        raise InvalidRow(line_number, "valor", f"debe ser positivo: {row.amount}")


def validate_batch(rows):
    """Valida el lote completo y levanta un ExceptionGroup con todo lo que falló."""
    problems = []
    for line_number, row in enumerate(rows, start=2):
        try:
            validate_row(row, line_number)
        except AurError as error:
            problems.append(error)
    if problems:
        raise ExceptionGroup(f"{len(problems)} filas no se pueden facturar", problems)


SPECIAL_RULES = {}


def rule_for(partner_id):
    """Registra la regla especial de un aliado."""
    def register(function):
        SPECIAL_RULES[partner_id] = function
        return function
    return register


@rule_for("P004")
def minimum_per_case(value, specialty, month_to_date, rate):
    """Neira cobra un mínimo por caso."""
    return max(value * rate, Decimal("150000"))


@rule_for("P005")
def monthly_cap(value, specialty, month_to_date, rate):
    """Buitrago negoció un tope mensual."""
    return min(value * rate, max(Decimal("2000000") - month_to_date, Decimal("0")))


def load_rates(path=Path("tarifas.toml")):
    """Lee las tarifas del archivo de configuración."""
    with path.open("rb") as file:
        config = tomllib.load(file)
    return {partner: Decimal(str(rate)) for partner, rate in config["aliados"].items()}


def referral_fee(partner_id, value, rates, specialty="", month_to_date=Decimal("0")):
    """La comisión de un caso derivado."""
    rate = rates[partner_id]
    rule = SPECIAL_RULES.get(partner_id)
    return rule(value, specialty, month_to_date, rate) if rule else value * rate


SCHEMA = """
CREATE TABLE IF NOT EXISTS billed (
    document TEXT NOT NULL, code TEXT NOT NULL, date TEXT NOT NULL,
    branch TEXT NOT NULL, amount TEXT NOT NULL, batch TEXT NOT NULL,
    PRIMARY KEY (document, code, date)
);
"""


def open_history(path=Path("data/historico.sqlite3")):
    """Abre el histórico, creándolo si no existe."""
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    return connection


def already_billed(connection, document, code, date):
    """¿Este procedimiento ya se facturó?"""
    row = connection.execute(
        "SELECT batch FROM billed WHERE document = ? AND code = ? AND date = ?",
        (document, code, date),
    ).fetchone()
    return row is not None


def record_batch(connection, rows, batch):
    """Registra el cierre completo."""
    with connection:
        cursor = connection.executemany(
            "INSERT OR IGNORE INTO billed VALUES (?, ?, ?, ?, ?, ?)",
            ((r.document, r.code, r.date, r.branch, str(r.amount), batch) for r in rows),
        )
        return cursor.rowcount


COMMANDS = {}


def command(name):
    """Registra un comando del CLI."""
    def register(function):
        COMMANDS[name] = function
        return function
    return register


@command("resumen")
def summary_command(args):
    """Resumen del mes de una sede."""
    path = args.datos / f"{args.sede.lower()}-{args.mes}.csv"
    print(render(summarize(read_rows(path)), path))
    return 0


@command("validar")
def validate_command(args):
    """Valida un lote antes de facturar."""
    try:
        validate_batch(read_rows(args.archivo))
    except* InvalidRow as group:
        for error in group.exceptions:
            print(f"  línea {error.line_number}: {error.reason}", file=sys.stderr)
        return 1
    return 0


def build_parser():
    """La interfaz del CLI."""
    parser = argparse.ArgumentParser(prog="aur", description="Cierre de mes de la red Áurea.")
    commands = parser.add_subparsers(dest="command", required=True)

    summary = commands.add_parser("resumen")
    summary.add_argument("--sede", required=True, choices=sorted(VALID_BRANCHES))
    summary.add_argument("--mes", required=True)
    summary.add_argument("--datos", type=Path, default=Path("data"))

    validate = commands.add_parser("validar")
    validate.add_argument("archivo", type=Path)
    return parser


if __name__ == "__main__":
    parsed = build_parser().parse_args()
    sys.exit(COMMANDS[parsed.command](parsed))
