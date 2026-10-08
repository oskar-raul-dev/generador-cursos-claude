# rescatado de la sesión 2859734a, 2026-09-13T20:17:22Z · Verify per-channel figures quoted in the chapter
import sys, numpy as np
from pathlib import Path
from acquisition import *
rows = read_spend_rows(Path("data/pauta.csv"))
sp = arrays_from_rows(rows)
acq = read_acquisitions(Path("data/leads.csv"), Path("data/etapas.csv"))
r = cost_per_acquisition_loop(rows, acq)
for k in sorted(r, key=lambda k:-r[k]): print(f"{k:10s} {r[k]:>15,.0f}  (adq {acq[k]})")
print("getsizeof lista:", sys.getsizeof(list(range(1_000_000)))/1e6, "MB")
print("nbytes array:", np.arange(1_000_000, dtype=np.int64).nbytes/1e6, "MB")
print("int32 demo:", np.array([2_000_000_000,2_000_000_000],dtype=np.int32).sum())
