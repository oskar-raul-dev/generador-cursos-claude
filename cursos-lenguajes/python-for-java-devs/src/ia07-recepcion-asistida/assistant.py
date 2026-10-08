"""Recepción asistida: las tres capas, en orden."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal

import anthropic

from agenda_client import AgendaClient
from agent import run_agent
from conversation import Conversation
from guardrails import has_clinical_image, mentions_symptom
from outbound import check_outbound

logger = logging.getLogger(__name__)

SYSTEM = """Ayudas a los pacientes de Áurea con su agenda por WhatsApp, en español
colombiano, corto y amable.

Puedes: consultar disponibilidad, decir precios de lista y apartar una propuesta de cita
para que una auxiliar la confirme.

No puedes, y no hay excepciones:
- Dar indicaciones clínicas o decir si algo es normal o grave.
- Prometer un resultado estético o decir que algo no va a doler.
- Confirmar una cita. Tú propones; confirma una persona.
- Hablar del tratamiento de un paciente concreto más allá de sus citas.

Si el paciente pregunta algo de eso, dile que le va a responder alguien del equipo.
"""

# Lo que el paciente lee cuando el hilo se escala. Es parte del producto y no un detalle:
# un "no puedo ayudarte con eso" a las once de la noche y sin siguiente paso es peor que
# no contestar nada.
ESCALATION_REPLY = (
    "Gracias por escribir. Esto lo va a revisar alguien del equipo y te responde lo antes "
    "posible. Si es algo urgente y te sientes mal, no esperes: llama a tu sede o acude a "
    "un servicio de urgencias."
)


@dataclass(frozen=True, slots=True)
class Reply:
    """La respuesta que sale, con lo que hace falta para auditarla."""

    text: str
    escalated: bool
    reason: str
    cost: Decimal
    blocked_draft: str = ""


def handle_message(
    client: anthropic.Anthropic,
    agenda: AgendaClient,
    conversation: Conversation,
    message: str,
    *,
    attachments: list[str] | None = None,
) -> Reply:
    """Las tres capas: antes del modelo, el modelo, después del modelo."""
    if not conversation.can_be_handled_by_agent():
        # No es un error: el hilo ya lo tomó una persona y el agente se calla.
        return Reply(text="", escalated=True, reason="hilo ya escalado", cost=Decimal(0))

    # ① Antes del modelo. Barato, determinista, no se deja convencer.
    for decision in (mentions_symptom(message), has_clinical_image(attachments or [])):
        if decision.escalate:
            conversation.escalate(decision.reason)
            logger.info(
                "hilo=%s escalado motivo=%s coincidencia=%r",
                conversation.thread_id,
                decision.reason,
                decision.matched,
            )
            return Reply(
                text=ESCALATION_REPLY,
                escalated=True,
                reason=decision.reason,
                cost=Decimal(0),  # no se llamó al modelo: escalar es gratis
            )

    # ② El modelo, con las herramientas de ia03.
    conversation.record("patient", message)
    run = run_agent(client, agenda, message, max_turns=6)

    # ③ Después del modelo. Lo peligroso es lo que sale.
    violation = check_outbound(run.reply)
    if violation is not None:
        category, fragment = violation
        conversation.escalate("salida")
        logger.warning(
            "hilo=%s respuesta bloqueada categoria=%s fragmento=%r",
            conversation.thread_id,
            category,
            fragment,
        )
        return Reply(
            text=ESCALATION_REPLY,
            escalated=True,
            reason=f"salida bloqueada: {category}",
            cost=run.cost,
            # El borrador bloqueado se guarda: es la materia prima para mejorar el
            # prompt, y sin él solo sabes que algo se bloqueó.
            blocked_draft=run.reply,
        )

    conversation.record("agent", run.reply)
    return Reply(text=run.reply, escalated=False, reason="", cost=run.cost)
