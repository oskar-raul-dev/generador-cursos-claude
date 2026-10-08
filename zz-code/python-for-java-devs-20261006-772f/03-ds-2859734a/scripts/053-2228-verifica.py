# rescatado de la sesión 2859734a, 2026-09-13T22:28:44Z · Decorrelate zone from specialty and recompute partners
from pathlib import Path
from partners import *
vals=load_partner_values(Path("data")); s=network_summary(vals); r=ranked(vals)
print(f"{s['aliados']:.0f} aliados · {s['remisiones']:,.0f} remisiones · {s['volvieron']:,.0f} volvieron ({s['tasa_retorno']:.1%}) · comisiones {s['comisiones_cop']:,.0f} → {s['costo_por_retenido']:,.0f}/retenido")
print(f"mejor {r[0].partner_id} {r[0].specialty} {r[0].zone} {r[0].cost_per_returned:,.0f} · peor {r[-1].partner_id} {r[-1].specialty} {r[-1].zone} {r[-1].cost_per_returned:,.0f} ({r[-1].cost_per_returned/r[0].cost_per_returned:.2f}×)")
print("especialidad:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"specialty").items()})
print("zona:        ", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"zone").items()})
