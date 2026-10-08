"""Escribir el estado del cierre: ingenuo contra atómico, con SIGKILL a mitad de camino; y un contador con y sin filelock."""

import json
import multiprocessing as mp
import os
import random
import signal
import time

from filelock import FileLock

STATE = {"fecha": "2026-10-05", "sedes": {f"sede-{i:05d}": {"estado": "ok", "filas": i * 1000} for i in range(40_000)}}
PAYLOAD = json.dumps(STATE)


def naive(path: str, started=None):
    with open(path, "w") as f:
        if started:
            started.set()                                 # avisa que ya abrió (y truncó) el archivo
        for i in range(0, len(PAYLOAD), 4096):
            f.write(PAYLOAD[i:i + 4096])
            f.flush()


def atomic(path: str, started=None):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        if started:
            started.set()
        for i in range(0, len(PAYLOAD), 4096):
            f.write(PAYLOAD[i:i + 4096])
            f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)                                 # el cambio de nombre es atómico


def is_valid(path: str) -> bool:
    try:
        with open(path) as f:
            return json.load(f)["fecha"] == "2026-10-05"
    except (OSError, ValueError, KeyError):
        return False


# ------------------------------------------------- un contador en un archivo, desde cuatro procesos
def bump(path: str, n: int, lock: bool):
    for _ in range(n):
        with FileLock(path + ".lock") if lock else open(os.devnull):
            value = int(open(path).read() or 0)          # sin bloqueo, a veces lo lee recién truncado: vacío
            with open(path, "w") as f:
                f.write(str(value + 1))


if __name__ == "__main__":                                # obligatorio con multiprocessing en Python 3.14 (ver §4)
    random.seed(1)
    for writer in (naive, atomic):
        broken = 0
        for _ in range(20):
            atomic("estado.json")                         # un estado válido de la noche anterior
            started = mp.Event()
            p = mp.Process(target=writer, args=("estado.json", started))
            p.start()
            started.wait(10)
            time.sleep(random.uniform(0, 0.005))          # el corte llega en cualquier momento de la escritura
            try:
                os.kill(p.pid, signal.SIGKILL)
            except ProcessLookupError:                    # alcanzó a terminar: no hubo corte
                pass
            p.join()
            broken += not is_valid("estado.json")
        print(f"{writer.__name__:<7} con SIGKILL a mitad de camino: {broken:>2} de 20 archivos quedaron rotos")

    for lock in (False, True):
        with open("contador.txt", "w") as f:
            f.write("0")
        procs = [mp.Process(target=bump, args=("contador.txt", 250, lock)) for _ in range(4)]
        for p in procs:
            p.start()
        for p in procs:
            p.join()
        print(f"contador {'con' if lock else 'sin'} filelock: {open('contador.txt').read():>4} (esperado 1000)")
