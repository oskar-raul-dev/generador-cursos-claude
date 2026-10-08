import warnings, pandas as pd
from pathlib import Path
d=Path("data")
plans = pd.read_csv(d/"planes_de_tratamiento.csv")
# 1) asignación encadenada bajo Copy-on-Write
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    sub = plans[plans["interes"]=="estetica"]
    sub["valor_total_cop"] = 0
    print("¿cambió el original?", (plans["valor_total_cop"]==0).any(), "· avisos:", [type(x.message).__name__ for x in w])
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    try:
        plans[plans["interes"]=="estetica"]["valor_total_cop"] = 0
    except Exception as e:
        print("encadenada lanzó:", type(e).__name__, e)
    print("avisos encadenada:", [(type(x.message).__name__, str(x.message)[:80]) for x in w])
    print("¿cambió el original?", (plans["valor_total_cop"]==0).any())
# 2) merge m:m
etapas = pd.read_csv(d/"etapas.csv"); toques = pd.read_csv(d/"toques.csv")
print("\netapas", len(etapas), "toques", len(toques))
m = etapas.merge(toques, on="lead_id")
print("merge sin validate ->", len(m), "filas")
try:
    etapas.merge(toques, on="lead_id", validate="1:1")
except Exception as e:
    print("validate='1:1' ->", type(e).__name__, ":", e)
