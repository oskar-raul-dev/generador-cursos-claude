# rescatado de la sesión 2859734a, 2026-09-13T20:26:06Z · Compare str vs object dtype memory in pandas 3
import pandas as pd, sys
from pathlib import Path
d=Path("data")
s=pd.read_csv(d/"cuotas.csv")["plan_id"]
o=pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"object"})["plan_id"]
print("str:", s.dtype, s.memory_usage(deep=True)/1e6, type(s.iloc[0]))
print("obj:", o.dtype, o.memory_usage(deep=True)/1e6, type(o.iloc[0]))
print("infer_string option:", pd.get_option("future.infer_string") if "future.infer_string" in [k for k in pd._config.config._registered_options] else "n/a")
