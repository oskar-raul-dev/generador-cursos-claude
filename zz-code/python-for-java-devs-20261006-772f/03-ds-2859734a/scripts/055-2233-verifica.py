# rescatado de la sesión 2859734a, 2026-09-13T22:33:53Z · Compute the exact autopsy figures
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); CUT=date(2026,3,31)
j=load_journeys(d); a=load_acquisitions(d); c=load_lead_created(d)
m=mature_leads(c,CUT); pool={l for l in a if l in m}
cred={n: credit_by_channel(j,a,f,m) for n,f in MODELS.items()}
print("pacientes maduros:", len(pool))
for ch in ("instagram","tiktok","google"):
    best=max(cred, key=lambda n: cred[n].get(ch,0))
    print(f"  {ch:<10} mejor modelo: {best:<14} se acredita {cred[best][ch]:>8.0f}")
tot=sum(max(cred[n].get(ch,0) for n in cred) for ch in ("instagram","tiktok","google"))
print(f"  suma de los tres, cada uno con su mejor modelo: {tot:,.0f}")
paid_last=sum(cred["último toque"].get(ch,0) for ch in ("instagram","tiktok","google"))
print(f"  con último toque, los tres pagos suman: {paid_last:,.0f}")
