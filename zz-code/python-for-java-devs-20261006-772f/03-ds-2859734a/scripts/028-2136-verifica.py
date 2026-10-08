# rescatado de la sesión 2859734a, 2026-09-13T21:36:32Z · Measure the loop at real size and check business coherence
import csv, json
from pathlib import Path
rows=list(csv.DictReader(open("data/pauta.csv",encoding="utf-8")))
plans=list(csv.DictReader(open("data/planes_de_tratamiento.csv",encoding="utf-8")))
spend=sum(int(r["costo_cop"]) for r in rows)
value=sum(int(p["valor_total_cop"]) for p in plans)
print(f"pauta total {spend:,} COP · valor contratado {value:,} COP · pauta/contratado {spend/value:.1%}")
print(f"CAC global {spend/len(plans):,.0f} COP sobre un plan medio de {value/len(plans):,.0f}")
