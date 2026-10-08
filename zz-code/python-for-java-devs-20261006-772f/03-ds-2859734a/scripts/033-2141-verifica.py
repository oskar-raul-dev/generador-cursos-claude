# rescatado de la sesión 2859734a, 2026-09-13T21:41:41Z · Regenerate data and recompute ds01 figures
import numpy as np
from pathlib import Path
from acquisition import *
rows=read_spend_rows(Path("data/pauta.csv")); sp=arrays_from_rows(rows)
acq=read_acquisitions(Path("data/leads.csv"), Path("data/etapas.csv"))
r=cost_per_acquisition_loop(rows,acq)
for k in sorted(r,key=lambda k:-r[k]): print(f"{k:10s} {r[k]:>15,.0f}  (adq {acq[k]})")
print("total int64:", f"{total_spend_with_dtype(sp,np.int64):,}", "· int32:", f"{total_spend_with_dtype(sp,np.int32):,}")
run=np.cumsum(sp.cost); print("desborda int32 en fila:", int(np.argmax(run>2**31-1)), "de", len(sp))
import csv
plans=list(csv.DictReader(open("data/planes_de_tratamiento.csv",encoding="utf-8")))
cuotas=sum(1 for _ in csv.DictReader(open("data/cuotas.csv",encoding="utf-8")))
val=sum(int(p["valor_total_cop"]) for p in plans); sp_tot=total_spend_with_dtype(sp,np.int64)
print(f"planes {len(plans):,} · cuotas {cuotas:,} · valor {val:,} · pauta/valor {sp_tot/val:.1%} · CAC global {sp_tot/len(plans):,.0f} · plan medio {val/len(plans):,.0f}")
