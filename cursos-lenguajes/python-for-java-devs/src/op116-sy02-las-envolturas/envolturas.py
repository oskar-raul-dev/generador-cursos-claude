"""La misma tubería en subprocess, plumbum y sh; qué hace cada una ante un error; y cuánto cuesta el azúcar."""

import subprocess
import time

import sh
from plumbum import local
from plumbum.commands.processes import ProcessExecutionError

with open("cierre.csv", "w") as f:
    f.write("sede,valor\n" + "Suba,1250000\n" * 20_000)

# ------------------------------------------------- la misma tubería: gzip -c cierre.csv | wc -c
gz = subprocess.Popen(["gzip", "-c", "cierre.csv"], stdout=subprocess.PIPE)
wc = subprocess.run(["wc", "-c"], stdin=gz.stdout, capture_output=True, text=True)
gz.wait()
print("subprocess:", wc.stdout.strip(), "bytes")
print("plumbum:   ", (local["gzip"]["-c", "cierre.csv"] | local["wc"]["-c"])().strip(), "bytes")
print("sh:        ", str(sh.wc("-c", _in=sh.gzip("-c", "cierre.csv", _piped=True))).strip(), "bytes")

# ------------------------------------------------- un programa que falla
r = subprocess.run(["gzip", "-c", "no-existe.csv"], capture_output=True)
print("\nsubprocess sin check: returncode", r.returncode, "· nada se lanzó")
for name, call, error in [("plumbum", lambda: local["gzip"]("-c", "no-existe.csv"), ProcessExecutionError),
                          ("sh", lambda: sh.gzip("-c", "no-existe.csv"), sh.ErrorReturnCode)]:
    try:
        call()
    except error as e:
        print(f"{name:<10} lanzó {type(e).__name__}")


# ------------------------------------------------- lo que cuesta cada llamada
def per_call_ms(fn, n=200) -> float:
    start = time.perf_counter()
    for _ in range(n):
        fn()
    return (time.perf_counter() - start) / n * 1000


print(f"\npor llamada a 'true': subprocess {per_call_ms(lambda: subprocess.run(['true'])):.2f} ms ·"
      f" plumbum {per_call_ms(lambda: local['true']()):.2f} ms · sh {per_call_ms(lambda: sh.true()):.2f} ms")
