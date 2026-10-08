"""Los dos escalones baratos: un CSV que el Excel en español abre bien, y un HTML sin servidor."""

import csv
import html
import pathlib

ROWS = [("Centro", 187_450_000, 3_100_000), ("Suba", 142_900_000, 9_800_000),
        ("Kennedy", 98_300_000, 1_200_000), ("Zipaquirá", 61_750_000, 4_450_000)]
HEADER = ("Sede", "Facturado", "Mora más de 90 días")

# ------------------------------------------------- 1. el CSV "normal", y el que Excel en español abre bien
with open("cartera_ingenuo.csv", "w", newline="", encoding="utf-8") as f:
    csv.writer(f).writerows([HEADER, *ROWS])

with open("cartera_excel.csv", "w", newline="", encoding="utf-8-sig") as f:      # con BOM
    csv.writer(f, delimiter=";").writerows([HEADER, *ROWS])                     # ; para Excel es-CO

# ------------------------------------------------- 2. un HTML que se abre sin servidor
def pesos(v: int) -> str:
    return "$" + f"{v:,}".replace(",", ".")


cells = "\n".join(
    f"<tr><td>{html.escape(s)}</td><td>{pesos(f)}</td>"
    f"<td{' class=alerta' if m > 4_000_000 else ''}>{pesos(m)}</td></tr>" for s, f, m in ROWS)
pathlib.Path("cartera.html").write_text(f"""<!doctype html><meta charset="utf-8">
<title>Cartera por sede</title>
<style>td{{padding:4px 12px}} .alerta{{color:#b00020;font-weight:bold}}</style>
<h1>Cartera por sede · septiembre de 2026</h1>
<table><tr>{''.join(f'<th>{h}</th>' for h in HEADER)}</tr>
{cells}
</table>""", encoding="utf-8")

for name in ("cartera_ingenuo.csv", "cartera_excel.csv", "cartera.html"):
    raw = pathlib.Path(name).read_bytes()
    print(f"{name:<20} {len(raw):>4} bytes  empieza con {raw[:12]!r}")
