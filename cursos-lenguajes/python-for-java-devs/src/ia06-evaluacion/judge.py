"""El juez automático. Es un modelo, se equivoca, y por eso se mide contra humanos."""

from __future__ import annotations

from decimal import Decimal
from typing import Literal

import anthropic
from pydantic import BaseModel, Field

from pricing import CATALOG

# Un modelo distinto del que genera. No elimina el sesgo de "me gusta lo que yo habría
# escrito", pero lo reduce; y es más barato, que importa cuando la suite corre a diario.
JUDGE_MODEL = "claude-haiku-4-5"

# La rúbrica va en el prompt y va en el repositorio. Si no está escrita, cada corrida
# califica con un criterio ligeramente distinto y los números dejan de ser comparables
# entre versiones, que es justo lo que la evaluación viene a evitar.
RUBRIC = """Califica la RESPUESTA contra la REFERENCIA para una administradora de una red
odontológica. Tres niveles y nada más:

- "correcta": afirma lo mismo que la referencia en lo que importa para facturar. La
  redacción puede ser distinta; el sentido no.
- "incompleta": lo que dice es cierto pero le falta algo de la referencia que cambia la
  decisión (una condición, una vigencia, un copago).
- "incorrecta": contradice la referencia, o afirma algo que la referencia no sostiene.

Dos advertencias sobre tu propio sesgo, y son parte del criterio:
- La longitud no es calidad. Una respuesta de una línea puede ser "correcta" y una de un
  párrafo puede ser "incorrecta".
- Que la respuesta no se parezca a como tú la habrías escrito no la hace peor.

Caso especial: si la referencia dice que NO se puede contestar con los documentos, una
respuesta que se abstiene es "correcta" y una que contesta es "incorrecta", por buena que
suene.
"""

Verdict = Literal["correcta", "incompleta", "incorrecta"]


class Judgment(BaseModel):
    """El fallo del juez. La justificación es obligatoria y es para ti, no para la métrica."""

    model_config = {"extra": "forbid"}

    # `reason` va ANTES que `verdict` en el orden del esquema a propósito: obliga a que
    # el texto se genere antes de comprometerse con la etiqueta.
    reason: str = Field(min_length=10, description="Una frase. Qué falta o qué contradice.")
    verdict: Verdict


def judge(
    client: anthropic.Anthropic,
    *,
    question: str,
    reference: str,
    candidate: str,
) -> tuple[Verdict, str, Decimal]:
    """Califica una respuesta. Devuelve el veredicto, su motivo y lo que costó."""
    response = client.messages.parse(
        model=JUDGE_MODEL,
        max_tokens=512,
        system=RUBRIC,
        messages=[
            {
                "role": "user",
                "content": (
                    f"PREGUNTA: {question}\n\n"
                    f"REFERENCIA: {reference}\n\n"
                    f"RESPUESTA: {candidate}"
                ),
            }
        ],
        output_format=Judgment,
    )

    judgment = response.parsed_output
    cost = CATALOG[JUDGE_MODEL].cost_of(
        response.usage.input_tokens, response.usage.output_tokens
    )
    return judgment.verdict, judgment.reason, cost
