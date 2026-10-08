"""Arranque, salida encadenable y código de salida de las tres CLI."""

import json
import subprocess
import sys
import time

for cli in ("cli_argparse.py", "cli_typer.py", "cli_cyclopts.py"):
    times = []
    for _ in range(5):
        start = time.perf_counter()
        subprocess.run([sys.executable, cli, "--help"], capture_output=True, check=True)
        times.append(time.perf_counter() - start)
    ok = subprocess.run([sys.executable, cli, "1250000", "45", "--json"], capture_output=True, text=True)
    bad = subprocess.run([sys.executable, cli, "1.250.000", "45"], capture_output=True, text=True)
    print(f"{cli:<17} arranque {min(times) * 1000:4.0f} ms · json → {json.loads(ok.stdout)['mora']} · "
          f"con puntos: salida {bad.returncode}, stdout {len(bad.stdout)} bytes, stderr {len(bad.stderr)} bytes")
