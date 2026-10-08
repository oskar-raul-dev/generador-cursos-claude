"""Memoria en reposo de un escalón: RSS de sus procesos y memoria de sus contenedores."""

import json
import subprocess
import sys


def process_rss_mb(pattern: str) -> float:
    """Suma el RSS de los procesos cuyo comando contiene el patrón (Linux y macOS)."""
    out = subprocess.run(["ps", "-axo", "rss=,command="], capture_output=True, text=True, check=True)
    total_kb = sum(int(line.split(None, 1)[0]) for line in out.stdout.splitlines()
                   if pattern in line and "memoria_en_reposo" not in line)
    return total_kb / 1024


def container_mb(label: str) -> float:
    """Suma la memoria de los contenedores con la etiqueta del escalón."""
    ids = subprocess.run(["docker", "ps", "-q", "--filter", f"label={label}"],
                         capture_output=True, text=True, check=True).stdout.split()
    if not ids:
        return 0.0
    stats = subprocess.run(["docker", "stats", "--no-stream", "--format", "{{json .}}", *ids],
                           capture_output=True, text=True, check=True).stdout.splitlines()
    units = {"KiB": 1 / 1024, "MiB": 1, "GiB": 1024}
    total = 0.0
    for line in stats:
        used = json.loads(line)["MemUsage"].split("/")[0].strip()
        number, unit = used[:-3], used[-3:]
        total += float(number) * units[unit]
    return total


if __name__ == "__main__":
    step, pattern, label = sys.argv[1], sys.argv[2], sys.argv[3]
    print(f"{step}: procesos {process_rss_mb(pattern):.0f} MB · contenedores {container_mb(label):.0f} MB")
