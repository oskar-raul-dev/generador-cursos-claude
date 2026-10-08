# rescatado de la sesión 2859734a, 2026-09-13T21:51:41Z · Measure interpreter startup plus import cost per engine
import subprocess, sys, time, statistics
code = "import ${m}" if "${m}" else "pass"
t=[]
for _ in range(7):
    s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True); t.append((time.perf_counter()-s)*1000)
t.sort(); print(f"{statistics.median(t):7.1f} ms de arranque (proceso + import)")
