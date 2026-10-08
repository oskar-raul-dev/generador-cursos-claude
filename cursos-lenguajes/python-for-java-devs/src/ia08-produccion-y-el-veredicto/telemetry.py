"""Qué se registra de una conversación, y qué no se puede registrar.

Esta decisión se escribe antes del código porque revertirla implica borrar datos que ya
guardaste. La tabla completa está en la sección 4 de la lección; aquí está implementada.
"""

from __future__ import annotations

import hashlib
import json
import logging
from dataclasses import asdict, dataclass, field
from datetime import date, datetime
from decimal import Decimal
from zoneinfo import ZoneInfo

BOGOTA = ZoneInfo("America/Bogota")
logger = logging.getLogger("aurea.ia")

# Ventana de retención, en un solo sitio. Que esté en una constante y no repartida por
# el código es lo que permite cumplir el criterio 5 del miniproyecto sin cazar literales.
RETENTION_DAYS = 90


def fingerprint(text: str) -> str:
    """Huella del mensaje del paciente. Se guarda esto y NO el texto.

    Permite contar repeticiones, detectar un mismo mensaje reenviado y correlacionar un
    incidente con su conversación, sin que el texto quede en el registro. Lo que no
    permite es leer qué escribió el paciente, y eso es el punto: para eso está el
    procedimiento de revisión humana sobre el canal original.
    """
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


@dataclass(frozen=True, slots=True)
class Event:
    """Una interacción, registrada. Todo lo que hay aquí se puede guardar."""

    thread_id: str
    branch: str
    at: datetime
    project: str  # "normarag" | "recepcion"
    model: str
    prompt_version: str
    message_hash: str
    # La clasificación sí, el texto no. Es lo que permite medir sin exponer.
    classification: str
    escalated: bool
    escalation_reason: str
    abstained: bool
    retrieved_chunk_ids: list[int] = field(default_factory=list)
    rejected_citations: list[str] = field(default_factory=list)
    # El borrador que la capa ③ impidió enviar. NO es información del paciente: es texto
    # que generó el modelo, y es la materia prima para mejorar el prompt. Sin él solo
    # sabes que algo se bloqueó, que es la peor de las dos situaciones.
    blocked_draft: str = ""
    input_tokens: int = 0
    output_tokens: int = 0
    cached_read_tokens: int = 0
    cost_usd: str = "0"
    latency_ms: float = 0.0

    def to_log(self) -> str:
        return json.dumps(
            {**asdict(self), "at": self.at.isoformat()}, ensure_ascii=False, sort_keys=True
        )


def record(event: Event) -> None:
    """Escribe el evento. Un solo sitio por el que pasa todo lo que se guarda.

    Tener una sola puerta es lo que hace auditable la frontera: para comprobar que no se
    está guardando el texto del paciente hay que leer este archivo y ninguno más.
    """
    logger.info("%s", event.to_log())


def expired(events: list[Event], *, today: date | None = None) -> list[Event]:
    """Los eventos que la política de retención obliga a borrar.

    Devuelve los que sobran en vez de borrarlos: quien llama decide, y así esta función
    se puede probar sin tocar almacenamiento.
    """
    reference = today or datetime.now(BOGOTA).date()
    return [
        event for event in events if (reference - event.at.date()).days > RETENTION_DAYS
    ]


def monthly_summary(events: list[Event]) -> dict[str, object]:
    """El resumen que lee Julián. Números que se pueden defender, y nada más.

    La abstención y el escalamiento van aquí y no en una sección secundaria: son la
    señal de salud más temprana que tienen estos dos sistemas, y ninguna alerta de las
    que se saben poner se dispara con ellas.
    """
    if not events:
        return {"eventos": 0}

    total_cost = sum((Decimal(event.cost_usd) for event in events), start=Decimal(0))
    escalated = sum(1 for event in events if event.escalated)
    abstained = sum(1 for event in events if event.abstained)
    cached = sum(event.cached_read_tokens for event in events)

    return {
        "eventos": len(events),
        "costo_usd": f"{total_cost:.4f}",
        "costo_por_evento_usd": f"{total_cost / len(events):.6f}",
        "tasa_escalamiento": round(escalated / len(events), 3),
        "tasa_abstencion": round(abstained / len(events), 3),
        "tokens_leidos_de_cache": cached,
        # Si esto es cero con tráfico repetido, hay un invalidador: audit_prefix.py.
        "cache_activa": cached > 0,
        "borradores_bloqueados": sum(1 for event in events if event.blocked_draft),
    }
