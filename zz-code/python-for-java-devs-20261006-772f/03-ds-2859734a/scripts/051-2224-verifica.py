# rescatado de la sesión 2859734a, 2026-09-13T22:24:56Z · Compute bootstrap intervals and the partner network figures
import csv, random
from collections import defaultdict
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); cutoff=date(2026,3,31); limit=cutoff-MATURITY
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d)
mature=mature_leads(created,cutoff); spend=load_spend(d, until=limit)
pool=[l for l in acq if l in mature]

def cac_of(sample, model, channel):
    tot=0.0
    for lead in sample:
        tot += model(journeys[lead]).get(channel, 0.0)
    return spend[channel]/tot if tot else float("nan")

rng=random.Random(20260913)
print("=== intervalo bootstrap 95% (200 remuestreos) ===")
for name,model in MODELS.items():
    row=f"{name:<14}"
    for ch in ("google","instagram","tiktok"):
        point=cac_of(pool,model,ch)
        sims=sorted(cac_of([pool[rng.randrange(len(pool))] for _ in pool],model,ch) for _ in range(200))
        row+=f"{ch[:3]} {point/1e6:.2f}M [{sims[4]/1e6:.2f}–{sims[194]/1e6:.2f}]  "
    print(row)

print("\n=== aliados: comisión contra pacientes que volvieron ===")
partners={r["aliado_id"]: r for r in csv.DictReader(open(d/"aliados.csv",encoding="utf-8"))}
ref=list(csv.DictReader(open(d/"remisiones.csv",encoding="utf-8")))
by=defaultdict(lambda: [0,0,0])
for r in ref:
    b=by[r["aliado_id"]]; b[0]+=1; b[1]+=int(r["volvio"]); b[2]+=int(r["comision_cop"])
rows=[(a, v[0], v[1]/v[0], v[2], v[2]/max(v[1],1)) for a,v in by.items() if v[0]>=30]
rows.sort(key=lambda r: r[4])
print(f"remisiones {len(ref):,} · aliados con ≥30 remisiones: {len(rows)}")
for a,n,rate,fee,per in rows[:3]+rows[-3:]:
    p=partners[a]
    print(f"  {a} {p['especialidad']:<16}{p['zona']:<10} n={n:>3} volvieron {rate:5.1%} comisión {fee:>12,} → {per:>11,.0f}/paciente")
tot_fee=sum(int(r["comision_cop"]) for r in ref); tot_ret=sum(int(r["volvio"]) for r in ref)
print(f"  TOTAL: {tot_fee:,} COP de comisiones · {tot_ret:,} de {len(ref):,} volvieron ({tot_ret/len(ref):.1%}) → {tot_fee/tot_ret:,.0f} por paciente que volvió")
