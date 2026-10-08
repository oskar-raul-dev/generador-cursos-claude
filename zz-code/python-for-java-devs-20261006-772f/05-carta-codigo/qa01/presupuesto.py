"""Lee el reporte JUnit de pytest y vigila el presupuesto: total, las más lentas y por archivo."""

import sys
import xml.etree.ElementTree as ET
from collections import defaultdict

BUDGET_SECONDS = 10.0            # la suite rápida de qa01


def summarize(path: str) -> int:
    root = ET.parse(path).getroot()
    cases = root.iter("testcase")
    rows = [(c.get("classname", ""), c.get("name", ""), float(c.get("time", 0))) for c in cases]
    total = sum(t for *_, t in rows)
    by_file: dict[str, float] = defaultdict(float)
    for classname, _, seconds in rows:
        by_file[classname.split(".")[0]] += seconds

    print(f"{len(rows)} pruebas en {total:.2f} s (presupuesto {BUDGET_SECONDS:.0f} s)")
    print("las tres más lentas:")
    for classname, name, seconds in sorted(rows, key=lambda r: r[2], reverse=True)[:3]:
        print(f"  {seconds:6.2f} s  {classname}::{name}")
    print("por archivo:", {k: round(v, 2) for k, v in sorted(by_file.items(), key=lambda kv: -kv[1])})
    return 0 if total <= BUDGET_SECONDS else 1


if __name__ == "__main__":
    sys.exit(summarize(sys.argv[1]))
