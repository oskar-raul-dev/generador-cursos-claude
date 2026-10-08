# rescatado de la sesión 2859734a, 2026-09-13T21:55:10Z · Compare cold start in the four-package environment
import subprocess, sys, time, statistics
print("ejecutable:", sys.executable)
for label, code in [("solo pass","pass"),("import duckdb","import duckdb"),("import pandas","import pandas")]:
    t=[]
    for _ in range(5):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
    t.sort(); print(f"{label:<16}{statistics.median(t):7.1f} ms")
