# rescatado de la sesión 2859734a, 2026-09-13T21:40:50Z · Cap all events at the dataset's declared end date
import csv, json
from pathlib import Path
d=Path("/tmp/fix")
for name,col in [("etapas.csv","fecha_hora"),("planes_de_tratamiento.csv","fecha_aceptacion"),("cuotas.csv","fecha_pago"),("toques.csv","fecha_hora")]:
    vals=[r[col][:10] for r in csv.DictReader(open(d/name,encoding="utf-8")) if r[col]]
    print(f"{name:28s} {col:18s} max={max(vals)}")
print(json.load(open(d/"manifiesto.json"))["filas"])
