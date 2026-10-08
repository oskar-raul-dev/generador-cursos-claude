"""Genera el archivo de ventas del trimestre para conciliar."""
import random
from pathlib import Path

def main() -> None:
    rng = random.Random(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "ventas-2026-Q1.csv"
    with target.open("w", encoding="utf-8") as f:
        f.write("documento,codigo,valor\n")
        for _ in range(1_200_000):
            f.write(f"{rng.randint(10_000_000, 1_299_999_999)},"
                    f"{rng.choice(['D8010','D8020','D2740','D7140','D1110','D8670'])},"
                    f"{rng.choice([75000,95000,120000,180000,210000,890000])}\n")
    print(f"{target}: 1.200.000 filas · {target.stat().st_size/1e6:.1f} MB")

if __name__ == "__main__":
    main()
