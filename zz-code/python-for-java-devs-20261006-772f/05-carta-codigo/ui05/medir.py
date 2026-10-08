"""Lo que pesa cada biblioteca: tamaño instalado y tiempo de importación, cada una en su venv."""

import subprocess
import sys
from pathlib import Path

LIBS = {"nicegui": "nicegui==3.17.1", "shiny": "shiny==1.8.0", "panel": "panel==1.9.4",
        "reflex": "reflex==0.9.12", "flet": "flet==1.0.3", "streamlit": "streamlit==1.65.0",
        "dash": "dash==4.4.1", "gradio": "gradio==6.29.1"}
IMPORT_TIME = "import time; t = time.perf_counter(); import {m}; print(time.perf_counter() - t)"

print(f"{'biblioteca':<11}{'paquetes':>9}{'MB':>7}{'importar (s)':>14}")
for module, spec in LIBS.items():
    venv = Path("/tmp/venvs") / module
    subprocess.run([sys.executable, "-m", "venv", str(venv)], check=True)
    py = venv / "bin" / "python"
    subprocess.run([py, "-m", "pip", "install", "-q", "--disable-pip-version-check", spec], check=True)
    site = next(venv.glob("lib/python*/site-packages"))
    mb = sum(f.stat().st_size for f in site.rglob("*") if f.is_file()) / 1e6
    packages = len(list(site.glob("*.dist-info"))) - 1                  # menos pip
    runs = [float(subprocess.run([py, "-c", IMPORT_TIME.format(m=module)], capture_output=True,
                                 text=True, check=True).stdout) for _ in range(3)]
    print(f"{module:<11}{packages:>9}{mb:>7.0f}{min(runs):>14.2f}")
