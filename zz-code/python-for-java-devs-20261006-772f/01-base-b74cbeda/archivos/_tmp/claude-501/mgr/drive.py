import subprocess, time, shutil, os, sys, pathlib

ROOT = pathlib.Path("/tmp/claude-501/mgr")

def run(cmd, env=None, cwd=ROOT, check=True):
    t0 = time.perf_counter()
    r = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd,
                       env={**os.environ, **(env or {})})
    dt = time.perf_counter() - t0
    if check and r.returncode != 0:
        print("FALLO:", cmd, "\n", r.stdout[-1500:], r.stderr[-1500:])
        sys.exit(1)
    return dt

def size(p):
    p = pathlib.Path(p)
    if not p.exists(): return 0
    return sum(f.stat().st_size for f in p.rglob("*") if f.is_file()) / 1e6

PY = "/opt/homebrew/bin/python3.14"
cache = ROOT / "cache-pip"
for d in (".venv-pip", ".venv-pip2", "cache-pip", "reqs.txt"):
    shutil.rmtree(ROOT / d, ignore_errors=True) if (ROOT/d).is_dir() else (ROOT/d).unlink(missing_ok=True)

env = {"PIP_CACHE_DIR": str(cache)}
t_venv = run(f"{PY} -m venv .venv-pip", env)
run(".venv-pip/bin/python -m pip install -q --disable-pip-version-check pip-tools==7.6.1", env)

t_compile_cold = run(".venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in", env)
t_sync_cold = run(".venv-pip/bin/pip-sync -q reqs.txt", env)
size_env = size(ROOT/".venv-pip")

(ROOT/"reqs.txt").rename(ROOT/"reqs.keep")
t_compile_warm = run(".venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in", env)

shutil.rmtree(ROOT/".venv-pip2", ignore_errors=True)
t_recreate_warm = run(f"{PY} -m venv .venv-pip2 && .venv-pip2/bin/python -m pip install -q --disable-pip-version-check -r reqs.txt", env)

n = sum(1 for l in (ROOT/"reqs.txt").read_text().splitlines() if "==" in l and not l.startswith("#"))
print(f"pip+pip-tools | venv {t_venv:.1f}s | compile frío {t_compile_cold:.1f}s | install frío {t_sync_cold:.1f}s")
print(f"              | compile caliente {t_compile_warm:.1f}s | recrear entorno caliente {t_recreate_warm:.1f}s")
print(f"              | entorno {size_env:.0f} MB | caché {size(cache):.0f} MB | {n} paquetes en el lock")
