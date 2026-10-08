"""Tarifas de los modelos que usa Áurea, con su fecha de verificación.

Verificado el 13 de septiembre de 2026 contra la documentación oficial de la API.
Los precios cambian: este archivo es el único lugar donde se tocan, y el que hay que
revisar antes de repetir cualquier medición de costo del track.
"""

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

VERIFIED_ON = date(2026, 9, 13)

# Un millón de tokens. Se declara como constante porque aparece en cada división y
# un 1_000_000 suelto en medio de una fórmula es donde se cuela el error de factor mil.
TOKENS_PER_UNIT = Decimal(1_000_000)


@dataclass(frozen=True, slots=True)
class ModelPricing:
    """Tarifa de un modelo, en dólares por millón de tokens."""

    model_id: str
    input_per_unit: Decimal
    output_per_unit: Decimal
    context_window: int

    def cost_of(self, input_tokens: int, output_tokens: int) -> Decimal:
        """Costo en dólares de una petición ya ejecutada.

        No redondea: el redondeo es decisión de quien presenta el número, y redondear
        aquí escondería el costo de las peticiones baratas, que sumadas son la factura.
        """
        return (
            Decimal(input_tokens) * self.input_per_unit
            + Decimal(output_tokens) * self.output_per_unit
        ) / TOKENS_PER_UNIT


# El modelo por defecto del track es Opus 5. Haiku entra donde el volumen manda y la
# tarea es simple —clasificar, resumir una línea—, y esa decisión se toma con la
# medición de la sección 6, no por costumbre.
CATALOG: dict[str, ModelPricing] = {
    "claude-opus-5": ModelPricing(
        model_id="claude-opus-5",
        input_per_unit=Decimal("5.00"),
        output_per_unit=Decimal("25.00"),
        context_window=1_000_000,
    ),
    "claude-haiku-4-5": ModelPricing(
        model_id="claude-haiku-4-5",
        input_per_unit=Decimal("1.00"),
        output_per_unit=Decimal("5.00"),
        context_window=200_000,
    ),
}

# El modelo local no tiene tarifa por token, y poner Decimal("0") sería mentir por
# omisión: cuesta electricidad, RAM y —sobre todo— el tiempo de quien lo mantiene.
# Se representa como ausencia de tarifa para que el código que suma costos tenga que
# decidir explícitamente qué hace con él.
LOCAL_MODELS: frozenset[str] = frozenset({"gemma3"})
