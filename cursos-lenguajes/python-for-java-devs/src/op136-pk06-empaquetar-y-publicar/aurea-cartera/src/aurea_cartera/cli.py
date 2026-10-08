import sys

from aurea_cartera import mora


def main() -> None:
    saldo, dias = map(int, sys.argv[1:3])
    print(f"${mora(saldo, dias):,}".replace(",", "."))
