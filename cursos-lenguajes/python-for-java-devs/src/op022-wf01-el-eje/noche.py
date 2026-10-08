"""La noche de Áurea como grafo: paralelo donde se puede, y nada que dependa de un fallo."""

import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from graphlib import TopologicalSorter

# Cada trabajo y aquello de lo que depende.
NIGHT = {
    "consolidar_rips": set(),
    "radicar": {"consolidar_rips"},
    "regalias": {"consolidar_rips"},
    "glosas_por_vencer": {"radicar"},
    "comisiones_aliados": {"regalias"},
    "informe_patricia": {"glosas_por_vencer", "comisiones_aliados"},
}


def run_job(name: str) -> str:
    time.sleep(0.2)                         # el trabajo de verdad va aquí
    if name == "radicar":
        raise RuntimeError("el portal de la aseguradora no responde")
    return name


def run_night(graph: dict[str, set[str]], workers: int = 3) -> dict[str, str]:
    sorter = TopologicalSorter(graph)
    sorter.prepare()                        # lanza CycleError si alguien creó un ciclo
    state: dict[str, str] = {}
    failed: set[str] = set()
    with ThreadPoolExecutor(workers) as pool:
        running = {}
        while sorter.is_active():
            for job in sorter.get_ready():
                if graph[job] & failed:
                    state[job] = "omitido: depende de un fallo"
                    failed.add(job)         # el fallo se propaga hacia adelante
                    sorter.done(job)
                    continue
                running[pool.submit(run_job, job)] = job
            if not running:
                continue
            finished, _ = wait(running, return_when=FIRST_COMPLETED)
            for future in finished:
                job = running.pop(future)
                try:
                    future.result()
                    state[job] = "ok"
                except Exception as error:
                    state[job] = f"falló: {error}"
                    failed.add(job)
                sorter.done(job)
    return state


if __name__ == "__main__":
    print(list(TopologicalSorter(NIGHT).static_order()))
    start = time.perf_counter()
    for job, result in run_night(NIGHT).items():
        print(f"{job:20} {result}")
    print(f"{time.perf_counter() - start:.1f} s")
