"""Frontera con AgendaAPI.

El cliente real es el de la Fase 13 y vive en tu repositorio. Aquí está el `Protocol`
que las herramientas necesitan y una implementación en memoria para las pruebas, que es
lo que permite probar el 90% del agente sin red y sin modelo.

⚠️ `hold_slot` y la tabla de propuestas con vencimiento NO estaban en el camino base:
son nuevos de esta sección. La lección lo dice junto a `propose_booking`.
"""

from __future__ import annotations

import threading
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from typing import Protocol
from zoneinfo import ZoneInfo

# La zona vive aquí, en la frontera, y no en las herramientas: los `datetime` que salen
# de la agenda y los que entran a `hold_slot` tienen que ser comparables, y un naive y
# un aware que representan el mismo instante NO son iguales ni tienen el mismo hash.
# Esa desigualdad silenciosa es el bug que atrapó `test_expired_proposal_frees_the_slot`.
BOGOTA = ZoneInfo("America/Bogota")


class SlotTaken(RuntimeError):
    """Alguien ganó la carrera por ese espacio. Lo lanza la restricción única, no el código."""


@dataclass(frozen=True, slots=True)
class Proposal:
    """Una reserva PROVISIONAL. No es una cita hasta que una persona la confirme."""

    code: str
    patient_id: str
    branch: str
    start: datetime
    minutes: int
    expires_at: datetime

    def summary_for_model(self) -> str:
        return (
            f"Propuesta {self.code} en {self.branch}, "
            f"{self.start:%Y-%m-%d %H:%M}, {self.minutes} minutos."
        )


class AgendaClient(Protocol):
    """Lo que las herramientas necesitan de AgendaAPI, y nada más."""

    def free_slots(self, *, branch: str, day: date, minutes: int) -> list[datetime]: ...

    def list_price(self, *, procedure_code: str, branch: str) -> Decimal | None: ...

    def hold_slot(
        self,
        *,
        idempotency_key: str,
        patient_id: str,
        branch: str,
        start: datetime,
        minutes: int,
        reason: str,
        expires_at: datetime,
    ) -> Proposal: ...


class InMemoryAgenda:
    """Implementación de prueba. Reproduce lo único que importa: la carrera y la clave.

    El candado no simula Postgres: simula la restricción ÚNICA sobre (sede, inicio), que
    es la que de verdad garantiza que no haya dos propuestas. Si tu corrección depende de
    este candado y no de esa restricción, el miniproyecto va a fallar en producción.
    """

    def __init__(self, *, slots: dict[tuple[str, date], list[time]], prices: dict[str, Decimal]):
        self._slots = slots
        self._prices = prices
        self._held: dict[tuple[str, datetime], Proposal] = {}
        self._by_key: dict[str, Proposal] = {}
        self._lock = threading.Lock()
        self._counter = 0

    def free_slots(self, *, branch: str, day: date, minutes: int) -> list[datetime]:
        available = self._slots.get((branch, day), [])
        candidates = [datetime.combine(day, slot, tzinfo=BOGOTA) for slot in sorted(available)]
        return [start for start in candidates if (branch, start) not in self._held]

    def list_price(self, *, procedure_code: str, branch: str) -> Decimal | None:
        return self._prices.get(f"{branch}:{procedure_code}") or self._prices.get(procedure_code)

    def hold_slot(
        self,
        *,
        idempotency_key: str,
        patient_id: str,
        branch: str,
        start: datetime,
        minutes: int,
        reason: str,
        expires_at: datetime,
    ) -> Proposal:
        with self._lock:
            # La clave primero: dos llamadas con los mismos datos son la misma intención.
            existing = self._by_key.get(idempotency_key)
            if existing is not None:
                return existing

            if (branch, start) in self._held:
                raise SlotTaken(f"{branch} {start:%Y-%m-%d %H:%M}")

            self._counter += 1
            proposal = Proposal(
                code=f"P{self._counter:05d}",
                patient_id=patient_id,
                branch=branch,
                start=start,
                minutes=minutes,
                expires_at=expires_at,
            )
            self._held[(branch, start)] = proposal
            self._by_key[idempotency_key] = proposal
            return proposal

    def release_expired(self, *, now: datetime) -> int:
        """Libera lo vencido. El reloj entra por parámetro para poder probarlo sin esperar."""
        with self._lock:
            expired = [key for key, p in self._held.items() if p.expires_at <= now]
            for key in expired:
                proposal = self._held.pop(key)
                self._by_key = {k: v for k, v in self._by_key.items() if v.code != proposal.code}
            return len(expired)


def seeded_agenda() -> InMemoryAgenda:
    """Agenda mínima para las pruebas: dos sedes, un jueves, precios de dos procedimientos."""
    thursday = date(2026, 9, 17)
    return InMemoryAgenda(
        slots={
            ("SUB", thursday): [time(15, 0), time(15, 40), time(16, 20)],
            ("CEN", thursday): [time(9, 0), time(15, 40)],
        },
        prices={"CEN:992102": Decimal("180000"), "SUB:992102": Decimal("165000")},
    )


__all__ = [
    "BOGOTA",
    "AgendaClient",
    "InMemoryAgenda",
    "Proposal",
    "SlotTaken",
    "seeded_agenda",
    "timedelta",
]
