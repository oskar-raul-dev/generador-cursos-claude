# rescatado de la sesión 2859734a, 2026-09-13T22:34:23Z · Find a real three-touch journey for the chapter
import csv
from pathlib import Path
from attribution import *
d=Path("data")
j=load_journeys(d); a=load_acquisitions(d)
camp={}
for r in csv.DictReader(open(d/"toques.csv",encoding="utf-8")):
    camp[(r["lead_id"], r["fecha_hora"])] = r["campana"]
plans={r["lead_id"]: r for r in csv.DictReader(open(d/"planes_de_tratamiento.csv",encoding="utf-8"))}
for lead, t in j.items():
    if lead in a and len(t)==3 and [c for _,c in t]==["tiktok","instagram","google"]:
        print("lead", lead, "· plan", plans[lead]["valor_total_cop"], "· sede", plans[lead]["sede"])
        for when,ch in t: print(f"  {when.isoformat(sep=' ',timespec='minutes')}  {ch:<10} ({camp[(lead,when.isoformat(timespec='seconds'))]})")
        print(f"  {a[lead]}  plan_aceptado")
        break
else: print("no hay un recorrido tiktok→instagram→google; busco cualquiera de 3 toques distintos")
spend=load_spend(d)
print("\ngasto tiktok/mes:", f"{spend['tiktok']/27:,.0f}", "· instagram:", f"{spend['instagram']/27:,.0f}", "· google:", f"{spend['google']/27:,.0f}")
