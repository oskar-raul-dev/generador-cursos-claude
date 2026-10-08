# rescatado de la sesión 2859734a, 2026-09-13T21:40:13Z · Check date ranges beyond the declared window
import csv
from pathlib import Path
d=Path("data")
for name,col in [("etapas.csv","fecha_hora"),("planes_de_tratamiento.csv","fecha_aceptacion"),("cuotas.csv","fecha_pago"),("cuotas.csv","fecha_programada"),("toques.csv","fecha_hora"),("leads.csv","creado")]:
    vals=[r[col][:10] for r in csv.DictReader(open(d/name,encoding="utf-8")) if r[col]]
    print(f"{name:28s} {col:18s} max={max(vals)} min={min(vals)}")
