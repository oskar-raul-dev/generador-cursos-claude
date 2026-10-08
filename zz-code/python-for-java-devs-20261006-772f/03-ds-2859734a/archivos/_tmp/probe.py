import subprocess, sys, time, statistics
code = 'from pathlib import Path\nfrom consolidation import consolidate_duckdb_parquet\nrows = consolidate_duckdb_parquet(Path("data/mes/parquet"))\nassert rows\n'
t=[]
for _ in range(5):
    s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
t.sort(); print(f"  pared mediana {statistics.median(t):7.1f} ms")
