"""Valkey desde Python: bytes, vencimiento, el turno bloqueado, y lo que cuesta KEYS."""

import os
import statistics
import threading
import time

import redis

HOST = os.environ.get("AUREA_VALKEY", "valkey")
r = redis.Redis(host=HOST)
for _ in range(30):
    try:
        r.ping()
        break
    except redis.ConnectionError:
        time.sleep(1)
print("servidor:", r.info("server").get("valkey_version") or r.info("server")["redis_version"])

# 1. todo vuelve como bytes
r.set("cartera:Suba:hoy", 12_450_000)
print("get:", repr(r.get("cartera:Suba:hoy")))
text = redis.Redis(host=HOST, decode_responses=True)
print("con decode_responses:", repr(text.get("cartera:Suba:hoy")))

# 2. el turno bloqueado que se suelta solo
taken = r.set("turno:Suba:2026-10-06T09:00", "paciente-anonimo-1", nx=True, ex=2)
again = r.set("turno:Suba:2026-10-06T09:00", "paciente-anonimo-2", nx=True, ex=2)
print("primer bloqueo:", taken, "· segundo:", again, "· vence en", r.ttl("turno:Suba:2026-10-06T09:00"), "s")
time.sleep(2.1)
print("después de 2,1 s:", r.get("turno:Suba:2026-10-06T09:00"))

# 3. KEYS bloquea a todos; SCAN no
with r.pipeline(transaction=False) as p:
    for i in range(500_000):
        p.set(f"cita:{i}", 1)
    p.execute()

latencies, stop = [], threading.Event()


def ping_loop():
    other = redis.Redis(host=HOST)
    while not stop.is_set():
        start = time.perf_counter()
        other.ping()
        latencies.append((time.perf_counter() - start) * 1000)


for label, action in [("KEYS", lambda: r.keys("cita:*")), ("SCAN", lambda: sum(1 for _ in r.scan_iter("cita:*", count=1000)))]:
    latencies.clear()
    stop.clear()
    t = threading.Thread(target=ping_loop)
    t.start()
    start = time.perf_counter()
    found = action()
    took = time.perf_counter() - start
    stop.set()
    t.join()
    print(f"{label}: {len(found) if isinstance(found, list) else found} claves en {took:.2f} s · "
          f"PING de otro cliente: mediana {statistics.median(latencies):.1f} ms, peor {max(latencies):.0f} ms")
