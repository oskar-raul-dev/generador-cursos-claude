"""El disparador de la outbox: un hilo con dueño. Arranca en el lifespan de la app y se para
con un Event; no solapa rondas porque es un solo hilo secuencial."""

from __future__ import annotations

import logging
import threading

from hexorders.application.usecases.notifications import DeliverPendingPublications

log = logging.getLogger("hexorders.outbox")


class OutboxDispatcher:
    def __init__(self, deliver: DeliverPendingPublications, poll_ms: int) -> None:
        self._deliver, self._interval = deliver, poll_ms / 1000
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, name="outbox-dispatcher", daemon=True)

    def start(self) -> None:
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        self._thread.join(timeout=5)

    def _loop(self) -> None:
        while not self._stop.wait(self._interval):
            try:
                delivered = self._deliver.execute(50)
                if delivered:
                    log.info("outbox: delivered %d event(s)", delivered)
            except Exception:
                log.exception("outbox: delivery round failed")  # la siguiente ronda reintenta
