"""El mismo recaudo en la gramática: Altair (una palabra cambia la marca), plotnine, y la tabla con Great Tables."""

import json
import random
import re

import altair as alt
import pandas as pd
from great_tables import GT
from plotnine import aes, geom_col, ggplot, labs

random.seed(9)
SEDES = ["Centro", "Chapinero", "Suba", "Kennedy"]
df = pd.DataFrame([{"semana": w, "sede": s, "recaudo": random.randint(20, 60) * 1_000_000}
                   for w in range(1, 5) for s in SEDES])

base = alt.Chart(df).encode(x="semana:O", y=alt.Y("recaudo:Q", title="Recaudo (pesos)"), color="sede:N")
bars, lines = base.mark_bar(), base.mark_line(point=True)
panels = base.mark_bar().facet("sede:N", columns=2)
for name, chart in [("barras", bars), ("lineas", lines), ("paneles", panels)]:
    chart.save(f"recaudo-{name}.png")
spec_bars, spec_lines = bars.to_dict(), lines.to_dict()
changed = [k for k in spec_bars if spec_bars[k] != spec_lines.get(k)]
print("Altair: lo que cambia entre barras y líneas en la especificación:", changed, "→",
      spec_bars["mark"], "/", spec_lines["mark"])
print("Altair: tamaño de la especificación:", len(json.dumps(spec_bars)), "bytes")

(ggplot(df, aes(x="semana", y="recaudo", fill="sede")) + geom_col(position="dodge")
 + labs(title="Recaudo semanal por sede")).save("recaudo-plotnine.png", width=8, height=3, dpi=100, verbose=False)
print("plotnine: recaudo-plotnine.png")

table = (df.pivot_table(index="sede", columns="semana", values="recaudo", aggfunc="sum").reset_index())
table.columns = ["sede"] + [f"sem {c}" for c in table.columns[1:]]
html = (GT(table, rowname_col="sede").tab_header(title="Recaudo de septiembre de 2026")
        .fmt_currency(columns=[c for c in table.columns if c != "sede"], currency="COP", decimals=0, locale="es")
        .tab_source_note("Fuente: cierre nocturno.").as_raw_html())
print("Great Tables: HTML de", len(html), "bytes; primera cifra:", re.search(r"\$\s?[\d.]+", html).group())

big = pd.DataFrame({"x": range(6_000), "y": range(6_000)})
try:
    alt.Chart(big).mark_point().encode(x="x", y="y").to_dict()
except Exception as e:
    print(f"Altair con 6 000 filas: {type(e).__name__}: {str(e).splitlines()[0][:80]}")
