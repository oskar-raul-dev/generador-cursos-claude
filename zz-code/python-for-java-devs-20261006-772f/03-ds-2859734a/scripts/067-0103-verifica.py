# rescatado de la sesión 2859734a, 2026-09-14T01:03:48Z · Render the dashboard in the three libraries
from pathlib import Path
from dashboard import *
print(as_table()); print()
for name, fn in (("matplotlib", as_matplotlib), ("plotly", as_plotly), ("altair", as_altair)):
    ext = ".png" if name=="matplotlib" else ".html"
    p = fn(target=Path("salida")/f"{name}{ext}")
    print(f"{name:<12}{p} · {p.stat().st_size/1024:.1f} KB")
