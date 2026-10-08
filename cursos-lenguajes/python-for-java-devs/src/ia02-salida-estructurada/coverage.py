"""El contrato de una regla de cobertura extraída de una circular de aseguradora.

Este archivo es el que hay que leer con más cuidado de toda la sección: cada decisión
de tipo y de obligatoriedad cambia lo que el modelo puede y no puede inventar.
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal, InvalidOperation
from typing import Literal

from pydantic import BaseModel, Field, field_validator

# Tres estados, no dos. El tercero es el que salva la tabla de coberturas de Áurea:
# una circular que habla de copago sin mencionar cobertura tiene que poder decirlo.
CoverageStatus = Literal["si", "no", "no_dice"]


class CoverageRule(BaseModel):
    """Una regla de cobertura tal como la afirma un documento.

    Ojo con el "tal como la afirma": esto no es la verdad sobre la cobertura, es lo que
    un documento concreto dice en una fecha concreta. La verdad sale de conciliar varias
    de estas, y esa conciliación es trabajo de Patricia, no del modelo.
    """

    model_config = {"extra": "forbid"}  # el esquema se cierra: un campo de más es un error

    insurer_nit: str = Field(description="NIT de la aseguradora, sin dígito de verificación.")
    procedure_code: str = Field(description="Código del procedimiento en el manual tarifario.")
    covered: CoverageStatus = Field(
        description=(
            "Usa 'no_dice' cuando el documento no afirme nada sobre la cobertura de este "
            "procedimiento. No infieras a partir de otros procedimientos parecidos."
        )
    )

    # El copago viaja como CADENA y no como Decimal, y esto es deliberado.
    # El esquema que ve el modelo es JSON: no tiene un tipo decimal, y forzarlo produce
    # un esquema con alternativas que la generación restringida no siempre honra. Se
    # recibe como texto, se valida aquí, y del otro lado del borde ya es Decimal.
    copayment_cop: str | None = Field(
        default=None,
        description="Valor del copago en pesos, solo dígitos, sin separadores ni símbolo.",
    )

    requires_prior_authorization: bool | None = Field(
        default=None,
        description="Déjalo ausente si el documento no lo menciona.",
    )
    valid_from: date | None = Field(
        default=None, description="Fecha desde la que aplica, si el documento la da."
    )

    # El campo que hace auditable todo lo demás. Sin cita no hay regla: es la misma
    # disciplina que NormaRAG va a exigir a las respuestas en ia05.
    quote: str = Field(
        min_length=12,
        description="Frase EXACTA y contigua del documento que sostiene esta regla.",
    )

    @field_validator("copayment_cop")
    @classmethod
    def only_digits(cls, value: str | None) -> str | None:
        """El modelo tiende a devolver '45.000' o '$45.000 COP'. Aquí se corta eso."""
        if value is None:
            return None
        if not value.isdigit():
            raise ValueError(
                f"El copago debe venir solo con dígitos, sin puntos ni símbolos; llegó {value!r}."
            )
        return value

    def copayment(self) -> Decimal | None:
        """El valor del dominio. Dinero es Decimal desde que cruza el borde."""
        if self.copayment_cop is None:
            return None
        try:
            return Decimal(self.copayment_cop)
        except InvalidOperation as error:  # defensivo: el validador ya lo garantiza
            raise ValueError(f"Copago no convertible: {self.copayment_cop!r}") from error


class CircularExtraction(BaseModel):
    """Lo que se extrae de una circular completa: cero o más reglas."""

    model_config = {"extra": "forbid"}

    insurer_name: str
    rules: list[CoverageRule] = Field(
        description="Puede venir vacía. Una circular administrativa no siempre trae reglas."
    )
