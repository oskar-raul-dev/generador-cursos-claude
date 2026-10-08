# rescatado de la sesión 2859734a, 2026-09-13T21:42:57Z · Collect remaining figures for both chapters
import pandas as pd
from pathlib import Path
from collections_report import *
d=Path("data")
e=pd.read_csv(d/"etapas.csv"); t=pd.read_csv(d/"toques.csv")
print("etapas", len(e), "toques", len(t), "merge:", len(e.merge(t,on="lead_id")))
for f,label in [("cuotas.csv","cuotas"),("planes_de_tratamiento.csv","planes")]:
    raw=pd.read_csv(d/f); print(f"{label} crudo {raw.memory_usage(deep=True).sum()/1e6:.2f} MB · filas {len(raw):,}")
lean_c=pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"category","fecha_pago":"string"})
lean_p=pd.read_csv(d/"planes_de_tratamiento.csv", dtype={"sede":"category","interes":"category"})
print(f"cuotas category {lean_c.memory_usage(deep=True).sum()/1e6:.2f} MB · planes category {lean_p.memory_usage(deep=True).sum()/1e6:.2f} MB")
p=pd.read_csv(d/"pauta.csv"); l=pd.read_csv(d/"leads.csv")
a=p.groupby("canal").size(); b=l.groupby("canal_ultimo_toque").size()
tot=sum(int(a[c])*int(b[c]) for c in a.index)
print("merge catastrófico:", f"{tot:,}", "filas ·", f"{tot*60/1e9:.1f} GB", "· google:", int(a["google"]), "×", int(b["google"]))
