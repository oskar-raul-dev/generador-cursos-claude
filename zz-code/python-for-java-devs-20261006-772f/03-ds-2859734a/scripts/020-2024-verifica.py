# rescatado de la sesión 2859734a, 2026-09-13T20:24:40Z · Compute catastrophic join size and final table
import pandas as pd
from pathlib import Path
d=Path("data")
p=pd.read_csv(d/"pauta.csv"); l=pd.read_csv(d/"leads.csv")
a=p.groupby("canal").size(); b=l.groupby("canal_ultimo_toque").size()
tot=sum(int(a[c])*int(b[c]) for c in a.index if c in b.index)
print("pauta", len(p), "leads", len(l))
print({c:(int(a[c]),int(b.get(c,0))) for c in a.index})
print("filas del merge por canal:", f"{tot:,}")
print("memoria estimada a 60 bytes/fila:", f"{tot*60/1e9:.1f} GB")
