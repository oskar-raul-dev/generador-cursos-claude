"""mora SALDO DIAS [--json], con cyclopts."""

import json
from typing import Annotated

from cyclopts import App, Parameter

app = App(name="mora", help="Interés de mora de un saldo.")


@app.default
def main(saldo: int, dias: int, *, as_json: Annotated[bool, Parameter(name="--json")] = False):
    value = round(saldo * 15 * dias / (1000 * 30))
    print(json.dumps({"saldo": saldo, "dias": dias, "mora": value}) if as_json else f"${value:,}".replace(",", "."))


if __name__ == "__main__":
    app()
