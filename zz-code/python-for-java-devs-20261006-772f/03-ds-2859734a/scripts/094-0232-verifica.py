# rescatado de la sesión 2859734a, 2026-09-14T02:32:25Z · Confirm the cold-start figures are stable
import subprocess, sys, time, statistics
for label, code in [("fastapi+uvicorn","import fastapi, uvicorn"),
                    ("+ sklearn","import fastapi, uvicorn, sklearn.linear_model"),
                    ("+ onnxruntime","import fastapi, uvicorn, onnxruntime")]:
    t=[]
    for _ in range(3):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append(time.perf_counter()-s)
    t.sort(); print(f"  {label:<20}{statistics.median(t):.2f} s")
