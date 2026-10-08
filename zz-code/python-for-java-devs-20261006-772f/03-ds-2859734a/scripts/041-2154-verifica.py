# rescatado de la sesión 2859734a, 2026-09-13T21:54:37Z · Decompose cold-start cost per engine
import subprocess, sys, time, statistics
def cold(code, n=5):
    t=[]
    for _ in range(n):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
    t.sort(); return statistics.median(t)
cases = {
 "intérprete solo": "pass",
 "import duckdb": "import duckdb",
 "import duckdb + connect": "import duckdb; duckdb.connect()",
 "import duckdb + connect + query trivial": "import duckdb; duckdb.connect().execute('select 42').fetchall()",
 "import polars": "import polars",
 "import polars + lazy trivial": "import polars as pl; pl.LazyFrame({'a':[1]}).collect()",
 "import pandas": "import pandas",
 "import pandas + frame trivial": "import pandas as pd; pd.DataFrame({'a':[1]}).groupby('a').size()",
}
for k,v in cases.items(): print(f"{k:<42} {cold(v):7.1f} ms")
