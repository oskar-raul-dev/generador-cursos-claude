"""Encola las liquidaciones en RQ, con reintentos, y espera los resultados."""

import os
import time

from redis import Redis
from rq import Queue, Retry

from tareas import build_settlement_pdf

queue = Queue("liquidaciones", connection=Redis.from_url(os.environ.get("REDIS_URL", "redis://127.0.0.1:6379")))
jobs = [queue.enqueue(build_settlement_pdf, sede, "2026T3",
                      retry=Retry(max=3, interval=[1, 2, 4]),   # en producción, minutos
                      job_timeout=300, result_ttl=86_400)
        for sede in ("Suba", "Zipaquirá")]
while not all(j.is_finished or j.is_failed for j in jobs):
    time.sleep(0.5)
    for j in jobs:
        j.refresh()
for j in jobs:
    print(j.args[0], j.get_status(), j.return_value())
