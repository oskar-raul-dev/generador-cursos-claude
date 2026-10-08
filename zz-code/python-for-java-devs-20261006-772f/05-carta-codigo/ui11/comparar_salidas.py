"""La misma herramienta, para el cron y para una persona: cuántos códigos de escape escribe cada vez."""

import os
import subprocess
import sys

for label, extra in [("cron (sin terminal)", {}), ("persona (FORCE_COLOR)", {"FORCE_COLOR": "1"})]:
    env = {k: v for k, v in os.environ.items() if k not in ("FORCE_COLOR", "NO_COLOR", "TERM")} | extra
    run = subprocess.run([sys.executable, "reproceso.py"], input="Bogotá\nSuba\n", capture_output=True,
                         text=True, env=env)
    print(f"{label:<22} {len(run.stdout):>5} bytes, {run.stdout.count(chr(27)):>3} escapes · {run.stderr.strip()}")
    if not extra:
        print(run.stdout)
