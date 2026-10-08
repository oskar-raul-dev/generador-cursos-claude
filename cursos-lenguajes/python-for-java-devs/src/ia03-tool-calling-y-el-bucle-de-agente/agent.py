"""El bucle de agente, escrito a mano.

Sesenta líneas. Se escribe antes que el ayudante del SDK por una razón práctica: el día
que el agente haga algo raro, esto es lo que vas a tener que leer.
"""

from __future__ import annotations

import logging
from collections.abc import Callable
from dataclasses import dataclass, field
from decimal import Decimal

import anthropic

from agenda_client import AgendaClient
from pricing import CATALOG
from tools import TOOL_DEFINITIONS, find_availability, get_treatment_price, propose_booking

logger = logging.getLogger(__name__)

MODEL = "claude-opus-5"

SYSTEM = """Ayudas a las auxiliares de Áurea a resolver solicitudes de agenda por WhatsApp.

Puedes consultar disponibilidad, precios de lista y apartar propuestas provisionales.
No confirmas citas: eso lo hace una persona.

Habla en español colombiano, corto y sin adornos. Si te falta un dato para actuar
—cuál sede, qué día, qué paciente—, pregúntalo en vez de suponerlo.
"""

# El despacho. Es el `switch` del que habla la sección 4, y no es más que esto.
HANDLERS: dict[str, Callable[..., str]] = {
    "find_availability": find_availability,
    "get_treatment_price": get_treatment_price,
    "propose_booking": propose_booking,
}


@dataclass(slots=True)
class Run:
    """Lo que produjo una ejecución del agente, con su factura y su rastro."""

    reply: str
    turns: int = 0
    tool_calls: list[str] = field(default_factory=list)
    input_tokens: int = 0
    output_tokens: int = 0
    cost: Decimal = Decimal(0)


def run_agent(
    client: anthropic.Anthropic,
    agenda: AgendaClient,
    user_message: str,
    *,
    max_turns: int = 8,
) -> Run:
    """Ejecuta el bucle hasta que el modelo termine o se acabe el presupuesto de turnos.

    El tope de turnos no es paranoia: un agente sin tope y con una herramienta que
    devuelve siempre lo mismo entra en bucle y factura hasta que alguien lo note.
    """
    pricing = CATALOG[MODEL]
    messages: list[dict[str, object]] = [{"role": "user", "content": user_message}]
    run = Run(reply="")

    for turn in range(1, max_turns + 1):
        response = client.messages.create(
            model=MODEL,
            max_tokens=4096,
            system=SYSTEM,
            tools=TOOL_DEFINITIONS,
            messages=messages,
        )

        run.turns = turn
        run.input_tokens += response.usage.input_tokens
        run.output_tokens += response.usage.output_tokens
        run.cost += pricing.cost_of(response.usage.input_tokens, response.usage.output_tokens)

        if response.stop_reason == "pause_turn":
            # Turno pausado: se reenvía tal cual para que continúe. El ayudante del SDK
            # NO hace esto y por eso devuelve respuestas truncadas sin avisar.
            messages.append({"role": "assistant", "content": response.content})
            continue

        if response.stop_reason != "tool_use":
            run.reply = "".join(b.text for b in response.content if b.type == "text")
            return run

        # El turno del asistente entra COMPLETO, con sus bloques tool_use adentro.
        messages.append({"role": "assistant", "content": response.content})

        # Todos los resultados van en UN solo mensaje de usuario. Repartirlos en varios
        # no da error y le enseña al modelo a no volver a llamar en paralelo.
        results: list[dict[str, object]] = []
        for block in response.content:
            if block.type != "tool_use":
                continue

            run.tool_calls.append(block.name)
            logger.info("herramienta=%s argumentos=%s", block.name, block.input)

            try:
                handler = HANDLERS[block.name]
                output = handler(agenda, **block.input)
                is_error = False
            except Exception as error:  # noqa: BLE001 — a propósito: ver el comentario
                # Se atrapa todo y se le devuelve al modelo. Dejar subir la excepción
                # mata la conversación y bota el contexto que ya se pagó; el modelo, en
                # cambio, puede probar otra sede o avisar que el sistema está caído.
                output = f"La herramienta falló: {error}"
                is_error = True
                logger.warning("herramienta=%s falló: %s", block.name, error)

            results.append(
                {
                    "type": "tool_result",
                    "tool_use_id": block.id,  # tiene que casar, o es un 400
                    "content": output,
                    "is_error": is_error,
                }
            )

        messages.append({"role": "user", "content": results})

    run.reply = (
        "No pude resolverlo en los pasos disponibles. "
        "Te paso la conversación para que la revises."
    )
    return run
