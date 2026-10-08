# rescatado de la sesión 2859734a, 2026-09-13T21:54:56Z · Instrument the cold DuckDB run
import subprocess, sys
code = '''
import time
t0=time.perf_counter()
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
t1=time.perf_counter()
import duckdb
t2=time.perf_counter()
rows = consolidate_duckdb_parquet(Path("data/mes/parquet"))
t3=time.perf_counter()
print(f"import consolidation {1000*(t1-t0):6.1f} · import duckdb {1000*(t2-t1):6.1f} · consulta {1000*(t3-t2):6.1f}")
'''
subprocess.run([sys.executable,"-c",code],check=True)
