# rescatado de la sesión 2859734a, 2026-09-13T21:56:09Z · Test whether DuckDB teardown dominates the wall clock
import subprocess, sys, time, statistics
code_full = '''
import time
t0=time.perf_counter()
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
rows = consolidate_duckdb_parquet(Path("data/mes/parquet"))
print(f"INTERNO {1000*(time.perf_counter()-t0):.1f}")
'''
code_exit = code_full + "\nimport os; os._exit(0)\n"
for label, code in [("normal", code_full), ("os._exit(0)", code_exit)]:
    t=[]; out=None
    for _ in range(5):
        s=time.perf_counter(); r=subprocess.run([sys.executable,"-c",code],check=True,capture_output=True,text=True); t.append((time.perf_counter()-s)*1000); out=r.stdout.strip()
    t.sort(); print(f"{label:<12} pared {statistics.median(t):7.1f} ms · {out}")
