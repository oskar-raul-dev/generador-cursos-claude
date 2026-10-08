import subprocess, time, shutil, os, sys, pathlib
ROOT = pathlib.Path("/tmp/claude-501/mgr")
UV = str(ROOT/".tool-uv/bin/uv")
PY = "/opt/homebrew/bin/python3.14"
def run(cmd, env=None, check=True):
    t0=time.perf_counter()
    r=subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=ROOT, env={**os.environ, **(env or {})})
    dt=time.perf_counter()-t0
    if check and r.returncode!=0:
        print("FALLO:",cmd,"\n",r.stdout[-1500:],r.stderr[-1500:]); sys.exit(1)
    return dt
def size(p):
    p=pathlib.Path(p)
    return sum(f.stat().st_size for f in p.rglob("*") if f.is_file())/1e6 if p.exists() else 0

cache = ROOT/"cache-uv"
for d in (".venv-uv",".venv-uv2","cache-uv"): shutil.rmtree(ROOT/d, ignore_errors=True)
(ROOT/"reqs-uv.txt").unlink(missing_ok=True)
env={"UV_CACHE_DIR":str(cache)}

t_venv = run(f"{UV} venv --python {PY} .venv-uv", env)
t_compile_cold = run(f"{UV} pip compile -q --python .venv-uv/bin/python -o reqs-uv.txt reqs.in", env)
t_sync_cold = run(f"{UV} pip sync -q --python .venv-uv/bin/python reqs-uv.txt", env)
size_env = size(ROOT/".venv-uv")
t_compile_warm = run(f"{UV} pip compile -q --python .venv-uv/bin/python -o reqs-uv.txt reqs.in", env)
shutil.rmtree(ROOT/".venv-uv2", ignore_errors=True)
t_recreate_warm = run(f"{UV} venv --python {PY} .venv-uv2 && {UV} pip sync -q --python .venv-uv2/bin/python reqs-uv.txt", env)
n = sum(1 for l in (ROOT/"reqs-uv.txt").read_text().splitlines() if "==" in l and not l.startswith("#"))
print(f"uv | venv {t_venv:.1f}s | compile frío {t_compile_cold:.1f}s | install frío {t_sync_cold:.1f}s")
print(f"   | compile caliente {t_compile_warm:.1f}s | recrear entorno caliente {t_recreate_warm:.1f}s")
print(f"   | entorno {size_env:.0f} MB | caché {size(cache):.0f} MB | {n} paquetes en el lock")
