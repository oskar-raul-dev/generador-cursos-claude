"""Las tres trampas de subprocess provocadas y corregidas: tubería llena, nieto huérfano, inyección de shell."""

import os
import signal
import subprocess
import sys
import time


def sleepers() -> int:
    """Cuenta los procesos 'sleep 30' vivos, leyendo /proc (Linux)."""
    count = 0
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                count += f.read().split(b"\0")[:2] == [b"sleep", b"30"]
        except OSError:
            pass
    return count


# ------------------------------------------------- 1. la tubería llena
big = [sys.executable, "-c", "print('x' * 200_000)"]           # 200 KB por la salida estándar
proc = subprocess.Popen(big, stdout=subprocess.PIPE)
try:
    proc.wait(timeout=2)
    print("wait(): terminó")
except subprocess.TimeoutExpired:
    print("wait(): bloqueado 2 s — el hijo espera que alguien lea, el padre espera que termine")
    proc.kill()
    proc.wait()
out, _ = subprocess.Popen(big, stdout=subprocess.PIPE).communicate(timeout=5)
print(f"communicate(): {len(out)} bytes leídos")

# ------------------------------------------------- 2. el nieto que sobrevive al timeout
try:
    subprocess.run(["sh", "-c", "sleep 30 & sleep 30"], timeout=1)
except subprocess.TimeoutExpired:
    time.sleep(0.2)
    print("run(timeout=1): procesos 'sleep 30' vivos después:", sleepers())
os.system("pkill -x sleep")                                     # limpieza del experimento

proc = subprocess.Popen(["sh", "-c", "sleep 30 & sleep 30"], start_new_session=True)
try:
    proc.wait(timeout=1)
except subprocess.TimeoutExpired:
    os.killpg(proc.pid, signal.SIGTERM)                         # todo el grupo, no solo el hijo
    proc.wait()
    time.sleep(0.2)
    print("grupo propio + killpg: procesos 'sleep 30' vivos después:", sleepers())

# ------------------------------------------------- 3. la inyección de shell
filename = "cierre-2026-10-05.csv; echo INYECTADO"              # un nombre que llegó de afuera
r1 = subprocess.run(f"echo procesando {filename}", shell=True, capture_output=True, text=True)
r2 = subprocess.run(["echo", "procesando", filename], capture_output=True, text=True)
print("shell=True:", r1.stdout.splitlines())
print("lista:     ", r2.stdout.splitlines())
