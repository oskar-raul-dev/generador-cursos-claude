"""Punto de entrada de la herramienta."""
import argparse
from pathlib import Path

from aur import __version__
from aur.reading import read_rows
from aur.summary import summarize


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(prog="aur", description="Cierre de mes de la red Áurea.")
    parser.add_argument("--version", action="version", version=f"aur {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)
    resumen = sub.add_parser("resumen", help="Resumen del mes de una sede.")
    resumen.add_argument("archivo", type=Path)
    args = parser.parse_args(argv)
    s = summarize(read_rows(args.archivo))
    print(f"procedimientos: {s['procedimientos']} · pacientes: {s['pacientes']} · total: ${s['total']:,.0f}")
    return 0
