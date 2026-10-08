"""Lectura de los exports de las sedes."""
import csv
from pathlib import Path

def read_rows(path: Path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        yield from csv.DictReader(f)
