"""La misma tarea en Python, y el experimento que compara las tres versiones."""

import pathlib
import shutil
import subprocess

INBOX = pathlib.Path("entrada")
shutil.rmtree(INBOX, ignore_errors=True)
INBOX.mkdir()
for name, rows in [("lote 1.csv", 3), ("lote\n2.csv", 5), ("-n.csv", 7), ("normal.csv", 2)]:
    (INBOX / name).write_text("".join(f"fila {i}\n" for i in range(rows)))
expected = {"lote 1.csv": 3, "lote\n2.csv": 5, "-n.csv": 7, "normal.csv": 2}


def with_python() -> dict[str, int]:
    return {p.name: sum(1 for _ in p.open()) for p in INBOX.glob("*.csv")}


print("python:     ", "correcto" if with_python() == expected else with_python())
for script in ("ingenuo.sh", "cuidadoso.sh"):
    r = subprocess.run(["bash", script], capture_output=True, text=True)
    ok = sum(f"{name}: {rows}" in r.stdout for name, rows in expected.items())
    print(f"{script:<12} {ok} de {len(expected)} lotes bien · código {r.returncode} · errores: {len(r.stderr.splitlines())} líneas")

# El paso que falla en medio de una tubería: ¿se entera el script?
for flags in ("", "set -euo pipefail; "):
    r = subprocess.run(["bash", "-c", flags + "cat no-existe.csv | wc -l; echo 'siguió como si nada'"],
                       capture_output=True, text=True)
    print(f"tubería con error {'con' if flags else 'sin'} pipefail: código {r.returncode} · {r.stdout.split()}")
