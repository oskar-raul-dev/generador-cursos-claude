"""Estimación de costo antes de enviar la petición."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal

import anthropic

from pricing import CATALOG


@dataclass(frozen=True, slots=True)
class CostEstimate:
    """Estimación previa. El costo de salida es una cota superior, no una predicción."""

    input_tokens: int
    max_output_tokens: int
    worst_case_cost: Decimal


def estimate(
    client: anthropic.Anthropic,
    question: str,
    *,
    system: str | None = None,
    model: str = "claude-opus-5",
    max_tokens: int = 4096,
) -> CostEstimate:
    """Cuenta los tokens de entrada contra el modelo real y calcula el peor caso.

    La entrada se cuenta exacto porque la API la cuenta por ti. La salida no se puede
    saber de antemano —el modelo decide cuánto escribe—, así que se acota con max_tokens
    y se dice que es el peor caso. Prometer una estimación de salida sería inventarla.
    """
    pricing = CATALOG[model]

    extra: dict[str, str] = {"system": system} if system is not None else {}

    counted = client.messages.count_tokens(
        model=model,
        messages=[{"role": "user", "content": question}],
        **extra,
    )

    return CostEstimate(
        input_tokens=counted.input_tokens,
        max_output_tokens=max_tokens,
        worst_case_cost=pricing.cost_of(counted.input_tokens, max_tokens),
    )
