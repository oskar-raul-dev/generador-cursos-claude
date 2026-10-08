# rescatado de la sesión 2859734a, 2026-09-13T21:47:44Z · Add the Parquet variant and verify all five agree
from pathlib import Path
from consolidation import ENGINES, write_parquet
write_parquet(Path("data"), Path("data/parquet"))
ref=None
for name, fn in ENGINES.items():
    src = Path("data/parquet") if "parquet" in name else Path("data")
    rows = fn(src)
    if ref is None: ref=rows; print(f"{name:18s} {len(rows)} filas · referencia")
    else: print(f"{name:18s} {len(rows)} filas · == bucle: {rows==ref}")
