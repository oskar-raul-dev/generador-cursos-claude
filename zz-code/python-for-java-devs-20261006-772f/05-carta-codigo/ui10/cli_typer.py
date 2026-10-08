"""mora SALDO DIAS [--json], con Typer: las anotaciones son la declaración."""

import json
from typing import Annotated

import typer


def main(saldo: int, dias: int, as_json: Annotated[bool, typer.Option("--json")] = False):
    """Interés de mora de un saldo."""
    value = round(saldo * 15 * dias / (1000 * 30))
    print(json.dumps({"saldo": saldo, "dias": dias, "mora": value}) if as_json else f"${value:,}".replace(",", "."))


if __name__ == "__main__":
    typer.run(main)
