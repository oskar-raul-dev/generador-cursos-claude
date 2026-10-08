# rescatado de la sesión 2859734a, 2026-09-13T22:28:09Z · Collect funnel, seasonality and partner figures
from datetime import date
from pathlib import Path
from attribution import *
from funnel import *
from partners import *
d=Path("data"); CUT=date(2026,3,31)
created=load_lead_created(d); acq=load_acquisitions(d); interest=load_lead_interest(d)
print("=== embudo completo ===")
for stage,n,pct_total,pct_step in stage_rates(load_stage_reach(d), len(created)):
    print(f"  {stage:<22}{n:>7,}  {pct_total:>6.1f}% del total  {pct_step:>6.1f}% del paso anterior")
print("\n=== cohortes: las tres últimas maduras y las tres inmaduras ===")
co=cohort_conversion(created,set(acq),CUT,MATURITY)
items=list(co.items())
for m,(t,w,r,mat) in items[-8:]:
    print(f"  {m}  {t:>5} leads · {w:>4} aceptaron · {r:>5.1f}%  {'maduro' if mat else '⚠️ INMADURO'}")
print("\n=== estacionalidad (índice, 1.0 = promedio) ===")
for label, only in (("ortodoncia","ortodoncia"),("estetica","estetica")):
    idx=seasonal_index(leads_by_month(created,interest,only))
    print(f"  {label:<11}" + " ".join(f"{m:02d}:{v:.2f}" for m,v in idx.items()))
print("\n=== Semana Santa 2025 (Pascua 20/04) ===")
ins,out=holy_week_drop(created,2025,date(2025,4,20))
print(f"  dentro {ins:.1f} leads/día · fuera {out:.1f} leads/día · {ins/out:.0%} del ritmo normal")
print("\n=== red de aliados ===")
vals=load_partner_values(d); s=network_summary(vals)
print(f"  {s['aliados']:.0f} aliados · {s['remisiones']:,.0f} remisiones · {s['volvieron']:,.0f} volvieron ({s['tasa_retorno']:.1%})")
print(f"  comisiones {s['comisiones_cop']:,.0f} COP → {s['costo_por_retenido']:,.0f} por paciente retenido")
r=ranked(vals)
print(f"  mejor: {r[0].partner_id} {r[0].specialty} {r[0].zone} {r[0].cost_per_returned:,.0f} · peor: {r[-1].partner_id} {r[-1].specialty} {r[-1].zone} {r[-1].cost_per_returned:,.0f} ({r[-1].cost_per_returned/r[0].cost_per_returned:.2f}×)")
print("  por especialidad:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"specialty").items()})
print("  por zona:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"zone").items()})
