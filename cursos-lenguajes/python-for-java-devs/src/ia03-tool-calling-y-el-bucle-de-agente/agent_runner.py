"""La misma tarea con `tool_runner`, para comparar.

Se escribe DESPUÉS del bucle manual, y el ejercicio 13 pide decidir cuál se queda.
"""

from __future__ import annotations

import anthropic
from anthropic import beta_tool

from agenda_client import AgendaClient
from tools import find_availability as _find_availability

# La agenda se inyecta al arrancar el proceso. Se declara con valor `None` y no solo con la
# anotación: una anotación suelta no crea el nombre, así que el módulo se importaría bien y
# fallaría con `NameError` en la primera llamada de la herramienta —a las siete de la mañana y
# dentro del bucle del agente, que es el peor sitio para enterarse—.
agenda: AgendaClient | None = None


@beta_tool
def find_availability(branch: str, day: str, minutes: int) -> str:
    """Devuelve los espacios libres de una sede en un día, en orden cronológico.

    Solo consulta la agenda: no reserva nada. Devuelve lista vacía si no hay espacios, y
    también si la sede no tiene agenda digital (Zipaquirá).

    Args:
        branch: Código de tres letras de la sede (CEN, CHA, SUB, KEN, USA, ENG, FON,
            RES, SOA, ZIP).
        day: Fecha en formato AAAA-MM-DD, zona horaria de Bogotá.
        minutes: Duración necesaria; un control de ortodoncia son 20 minutos.
    """
    if agenda is None:
        raise RuntimeError("La agenda no se inyectó: asigna `agent_runner.agenda` al arrancar.")
    return _find_availability(agenda, branch, day, minutes)


def run_with_runner(client: anthropic.Anthropic, user_message: str) -> str:
    runner = client.beta.messages.tool_runner(
        model="claude-opus-5",
        max_tokens=4096,
        tools=[find_availability],
        messages=[{"role": "user", "content": user_message}],
    )

    last = None
    for message in runner:
        last = message

    # ⚠️ Si `last.stop_reason` es "pause_turn", esto devuelve una respuesta TRUNCADA sin
    # avisar. El bucle de agent.py lo trata; aquí hay que comprobarlo a mano.
    return "".join(b.text for b in last.content if b.type == "text") if last else ""
