"""Copiar o compartir: memoryview, NumPy, memoria compartida entre procesos y Arrow mapeado de disco."""

import os
import time
from multiprocessing import Process, Queue, shared_memory

import numpy as np
import pyarrow as pa


def rss_mb():
    with open("/proc/self/statm") as f:
        return int(f.read().split()[1]) * os.sysconf("SC_PAGE_SIZE") / 2**20


def timed(fn):
    start = time.perf_counter(); result = fn(); return result, (time.perf_counter() - start) * 1000


def consume_pickled(inbox, outbox):
    outbox.put(float(inbox.get().sum()))


def consume_shared(name, n, queue):
    shm = shared_memory.SharedMemory(name=name)
    data = np.ndarray((n,), dtype=np.float64, buffer=shm.buf)
    queue.put(float(data.sum()))
    del data
    shm.close()


if __name__ == "__main__":
    N = 25_000_000                                            # 200 MB de float64
    blob = bytes(200 * 2**20)

    # 1) Rebanar: bytes copia, memoryview no
    before = rss_mb()
    part, ms = timed(lambda: blob[: 100 * 2**20])
    print(f"bytes[:100 MB]      {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")
    del part
    before = rss_mb()
    view, ms = timed(lambda: memoryview(blob)[: 100 * 2**20])
    print(f"memoryview[:100 MB] {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")

    # 2) NumPy sobre un buffer ajeno: la misma memoria
    raw = bytearray(8 * 4)
    shared = np.frombuffer(raw, dtype=np.float64)
    shared[0] = 42.0
    print("np.frombuffer comparte la memoria:", raw[:8] == np.float64(42.0).tobytes())

    # 3) Entre procesos: serializar contra memoria compartida
    data = np.random.default_rng(7).random(N)
    inbox, queue = Queue(), Queue()                         # dos colas: quien envía no lee su propio envío
    worker = Process(target=consume_pickled, args=(inbox, queue))
    start = time.perf_counter(); worker.start(); inbox.put(data); result = queue.get(); worker.join()
    print(f"proceso, serializado        {(time.perf_counter() - start) * 1000:7.1f} ms · suma {result:,.0f}")

    shm = shared_memory.SharedMemory(create=True, size=data.nbytes)
    np.ndarray(data.shape, dtype=data.dtype, buffer=shm.buf)[:] = data
    worker = Process(target=consume_shared, args=(shm.name, N, queue))
    start = time.perf_counter(); worker.start(); result = queue.get(); worker.join()
    print(f"proceso, memoria compartida {(time.perf_counter() - start) * 1000:7.1f} ms · suma {result:,.0f}")
    shm.close(); shm.unlink()

    # 4) Arrow: escribir una vez, mapear en vez de leer
    table = pa.table({"valor": data})
    with pa.OSFile("valores.arrow", "wb") as sink, pa.ipc.new_file(sink, table.schema) as writer:
        writer.write_table(table)
    before = rss_mb()
    mapped, ms = timed(lambda: pa.ipc.open_file(pa.memory_map("valores.arrow")).read_all())
    column = mapped.column("valor").chunk(0).to_numpy(zero_copy_only=True)   # un solo bloque: se puede sin copiar
    print(f"Arrow mapeado de disco {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB · {len(column):,} valores")
    before = rss_mb()
    read, ms = timed(lambda: pa.ipc.open_file(pa.OSFile("valores.arrow")).read_all())
    print(f"Arrow leído a memoria  {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")
    os.remove("valores.arrow")
