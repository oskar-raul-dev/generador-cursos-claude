"""El hilo de conversación como máquina de estados.

Un hilo de WhatsApp vive días. El paciente contesta a las once de la noche, se calla dos
días y vuelve a mitad de otra cosa. Sin estado explícito, el agente retoma conversaciones
que ya tomó una persona, y eso es peor que no contestar.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from zoneinfo import ZoneInfo

from guardrails import EscalationReason

BOGOTA = ZoneInfo("America/Bogota")


class State(Enum):
    """Los cuatro estados de un hilo. `ESCALATED` es terminal PARA EL AGENTE."""

    NEW = "nuevo"
    AGENT = "con el asistente"
    ESCALATED = "con una persona"
    CLOSED = "cerrado"


class EscalatedThread(RuntimeError):
    """Se intentó que el agente atendiera un hilo que ya tomó una persona."""


@dataclass(slots=True)
class Conversation:
    """Un hilo. El estado es del dominio, no del transporte."""

    thread_id: str
    patient_id: str | None = None
    state: State = State.NEW
    turns: list[tuple[str, str]] = field(default_factory=list)
    escalated_at: datetime | None = None
    escalation_reason: EscalationReason = ""

    def can_be_handled_by_agent(self) -> bool:
        return self.state in (State.NEW, State.AGENT)

    def escalate(self, reason: EscalationReason, *, now: datetime | None = None) -> None:
        """Transición terminal para el agente.

        No hay `de_escalate`, y no es un olvido: una vez que Yuli tomó el hilo, el
        agente no vuelve a escribir en él. Devolvérselo automáticamente —porque "ya pasó
        el rato" o porque el siguiente mensaje parece inocente— es exactamente cómo se
        manda un mensaje automático a alguien que está en medio de una conversación con
        una persona.
        """
        self.state = State.ESCALATED
        self.escalated_at = now or datetime.now(BOGOTA)
        self.escalation_reason = reason

    def record(self, role: str, text: str) -> None:
        if role == "agent" and self.state == State.ESCALATED:
            raise EscalatedThread(
                f"El hilo {self.thread_id} está con una persona desde "
                f"{self.escalated_at:%Y-%m-%d %H:%M}. El asistente no escribe aquí."
            )
        self.turns.append((role, text))
        if role == "agent":
            self.state = State.AGENT
