# rescatado de la sesión 2859734a, 2026-09-13T22:23:53Z · Compute the attribution figures
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data")
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d); spend=load_spend(d)
cutoff=date(2026,3,31)
mature=mature_leads(created,cutoff)
print(f"leads {len(created):,} · maduros {len(mature):,} · adquiridos {len(acq):,} · adquiridos maduros {len(set(acq)&mature):,}")
print("\n=== reparto del crédito (%) sobre leads maduros ===")
print(f"{'canal':<12}" + "".join(f"{m:>15}" for m in MODELS))
share={m: share_of_credit(credit_by_channel(journeys,acq,f,mature)) for m,f in MODELS.items()}
for c in sorted(share["primer toque"]):
    print(f"{c:<12}" + "".join(f"{share[m].get(c,0):>14.1f}%" for m in MODELS))
print("\n=== costo por paciente adquirido (COP) ===")
print(f"{'canal':<12}" + "".join(f"{m:>15}" for m in MODELS))
for c in sorted(spend):
    row=""
    for m,f in MODELS.items():
        cac=cost_per_acquisition(spend, credit_by_channel(journeys,acq,f,mature))
        row+=f"{cac.get(c,float('nan')):>14,.0f} "
    print(f"{c:<12}{row}")
print("\n=== efecto de la madurez: último toque, con y sin filtro ===")
for label, elig in (("sin filtro", None), ("maduros", mature)):
    cac=cost_per_acquisition(spend, credit_by_channel(journeys,acq,credit_last,elig))
    print(f"{label:<12}" + "".join(f"{c}={cac[c]:,.0f}  " for c in sorted(cac)))
