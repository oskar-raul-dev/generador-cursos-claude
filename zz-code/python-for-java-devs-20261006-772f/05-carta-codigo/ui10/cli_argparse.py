"""mora SALDO DIAS [--json], con argparse."""

import argparse
import json


def mora(saldo: int, dias: int) -> int:
    return round(saldo * 15 * dias / (1000 * 30))


parser = argparse.ArgumentParser(prog="mora", description="Interés de mora de un saldo.")
parser.add_argument("saldo", type=int, help="saldo en pesos, sin puntos")
parser.add_argument("dias", type=int, help="días de mora")
parser.add_argument("--json", action="store_true", help="salida en JSON para otro programa")
args = parser.parse_args()
value = mora(args.saldo, args.dias)
print(json.dumps({"saldo": args.saldo, "dias": args.dias, "mora": value}) if args.json else f"${value:,}".replace(",", "."))
