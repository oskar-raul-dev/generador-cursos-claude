from pathlib import Path
import sys
sys.path.insert(0, ".")
from collections_report import *
d = Path("data")
for lean in (False, True):
    plans = read_plans(d/"planes_de_tratamiento.csv", lean=lean)
    inst = read_installments(d/"cuotas.csv", lean=lean)
    print("lean" if lean else "crudo", f"planes {frame_memory_mb(plans):.2f} MB · cuotas {frame_memory_mb(inst):.2f} MB · filas {len(inst):,}")
plans = read_plans(d/"planes_de_tratamiento.csv"); inst = read_installments(d/"cuotas.csv")
a = collected_naive(plans, inst); b = collected_vectorized(plans, inst); c = collected_lean(plans, inst)
import pandas as pd
print(a.head())
print("iguales a==b:", a.equals(b), "· a==c:", a.astype(float).round(1).equals(c.astype(float).round(1)))
