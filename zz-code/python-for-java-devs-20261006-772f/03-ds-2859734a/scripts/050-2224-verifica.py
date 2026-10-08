# rescatado de la sesión 2859734a, 2026-09-13T22:24:30Z · Recompute with a coherent window
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); cutoff=date(2026,3,31); limit=cutoff-MATURITY
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d)
mature=mature_leads(created,cutoff)
spend_all=load_spend(d); spend_mature=load_spend(d, until=limit)
print(f"ventana madura: hasta {limit} · gasto total {sum(spend_all.values()):,} → {sum(spend_mature.values()):,}")
print("\n=== CAC por modelo, ventana coherente ===")
print(f"{'canal':<12}" + "".join(f"{m:>16}" for m in MODELS))
cac={m: cost_per_acquisition(spend_mature, credit_by_channel(journeys,acq,f,mature)) for m,f in MODELS.items()}
for c in sorted(spend_mature):
    print(f"{c:<12}" + "".join(f"{cac[m][c]:>15,.0f} " for m in MODELS))
print("\n=== el efecto del filtro de madurez (último toque) ===")
a=cost_per_acquisition(spend_all, credit_by_channel(journeys,acq,credit_last,None))
b=cost_per_acquisition(spend_mature, credit_by_channel(journeys,acq,credit_last,mature))
for c in sorted(a): print(f"  {c:<10} sin filtro {a[c]:>12,.0f} → maduros {b[c]:>12,.0f}  ({(b[c]/a[c]-1)*100:+.1f}%)")
print("\n=== suma de créditos: ¿cuántos pacientes reparte cada modelo? ===")
for m,f in MODELS.items(): print(f"  {m:<14}{sanity_check(journeys,acq,f,mature):>10.1f}  (adquiridos maduros: {len(set(acq)&mature)})")
