"""Un módulo con un defecto para cada herramienta de la cadena."""

import json
import os                                   # ruff: importado y no usado
import subprocess
from decimal import Decimal

import requests                             # deptry: importado y no declarado en pyproject.toml


def total(amounts: list[Decimal]) -> Decimal:
    return sum(amounts)                     # mypy: sum de una lista vacía es int, no Decimal


def export(path: str, rows: list[dict]) -> None:
    subprocess.run(f"gzip {path}", shell=True)   # bandit: shell=True con un valor de afuera
    with open(path, "w") as f:
        json.dump(rows, f)


def old_report() -> None:                   # vulture: nadie la llama
    print(requests.__version__)
