"""Abrir un entorno virtual: qué hay adentro, qué hace 'activar', y cuánto cuesta crearlo."""

import os
import pathlib
import shutil
import subprocess
import sys
import time

ENV = pathlib.Path("demo-venv")
shutil.rmtree(ENV, ignore_errors=True)

for with_pip in (False, True):
    shutil.rmtree(ENV, ignore_errors=True)
    start = time.perf_counter()
    cmd = [sys.executable, "-m", "venv", str(ENV)] + ([] if with_pip else ["--without-pip"])
    subprocess.run(cmd, check=True)
    print(f"crear el entorno {'con' if with_pip else 'sin'} pip: {time.perf_counter() - start:.2f} s")

print("pyvenv.cfg:", (ENV / "pyvenv.cfg").read_text().strip().splitlines())
print("bin/python es un enlace a:", os.readlink(ENV / "bin" / "python"))

probe = "import sys, site; print(sys.prefix != sys.base_prefix, site.getsitepackages()[0])"
inside = subprocess.run([ENV / "bin" / "python", "-c", probe], capture_output=True, text=True).stdout.split()
print("python del entorno, sin 'activar': ¿en un entorno?", inside[0], "· site-packages:", inside[1])

# 'Activar' es esto: el PATH con el bin del entorno primero.
env_path = {**os.environ, "PATH": f"{ENV.resolve() / 'bin'}:{os.environ['PATH']}"}
which = subprocess.run(["sh", "-c", "command -v python"], env=env_path, capture_output=True, text=True).stdout.strip()
print("con el PATH 'activado', 'python' es:", which)

size = sum(f.stat().st_size for f in ENV.rglob("*") if f.is_file() and not f.is_symlink()) / 1e6
print(f"tamaño del entorno con pip: {size:.1f} MB")
