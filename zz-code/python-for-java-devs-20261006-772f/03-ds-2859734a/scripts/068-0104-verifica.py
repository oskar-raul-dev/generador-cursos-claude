# rescatado de la sesión 2859734a, 2026-09-14T01:04:37Z · Run the render benchmark in isolated environments
from pathlib import Path
import plotly.graph_objects as go
from dashboard import AUREA_CAC, BRAND
ch=sorted(AUREA_CAC, key=lambda c:-AUREA_CAC[c][1])
f=go.Figure(go.Bar(x=[AUREA_CAC[c][1] for c in ch], y=ch, orientation="h"))
p=Path("salida/plotly-offline.html"); f.write_html(p, include_plotlyjs=True)
print(f"  {p.stat().st_size/1024/1024:.2f} MB")
