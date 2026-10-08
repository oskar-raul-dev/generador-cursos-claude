"""Dos réplicas con planificador propio: un trabajo por réplica y otro una sola vez en total."""

import fcntl
import threading
import time
from contextlib import contextmanager
from zoneinfo import ZoneInfo

from apscheduler.schedulers.background import BackgroundScheduler

BOGOTA = ZoneInfo("America/Bogota")
log: list[str] = []
log_lock = threading.Lock()


def record(text: str) -> None:
    with log_lock:
        log.append(text)


@contextmanager
def single_runner(name: str):
    """El ShedLock de esta sección: un bloqueo exclusivo y no bloqueante sobre un archivo."""
    with open(f"/tmp/{name}.lock", "w") as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            yield False                     # otra réplica lo tiene: esta no hace nada
            return
        try:
            yield True
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def refresh_cache(replica: str) -> None:
    record(f"{replica}: caché refrescada")      # cada réplica tiene la suya: corre en todas


def send_reminders(replica: str) -> None:
    with single_runner("recordatorios") as mine:
        if not mine:
            record(f"{replica}: recordatorios — los manda otra réplica")
            return
        time.sleep(0.3)                          # mandar los recordatorios del día
        record(f"{replica}: recordatorios enviados")


def start_replica(name: str) -> BackgroundScheduler:
    scheduler = BackgroundScheduler(
        timezone=BOGOTA,
        job_defaults={"coalesce": True, "max_instances": 1, "misfire_grace_time": 30},
    )
    scheduler.add_job(refresh_cache, "interval", seconds=1, args=[name], id="cache")
    # En producción: "cron", hour=8. Aquí, cada dos segundos para verlo en la prueba.
    scheduler.add_job(send_reminders, "interval", seconds=2, args=[name], id="reminders")
    scheduler.start()
    return scheduler


if __name__ == "__main__":
    replicas = [start_replica("réplica-1"), start_replica("réplica-2")]
    time.sleep(2.5)
    for scheduler in replicas:
        scheduler.shutdown(wait=True)
    for line in sorted(log):
        print(line)
