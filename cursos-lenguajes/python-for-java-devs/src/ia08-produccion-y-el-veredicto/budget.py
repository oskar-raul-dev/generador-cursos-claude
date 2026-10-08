"""Presupuesto por usuario y por día. En Decimal, y corta de verdad.

Un servicio que puede gastar sin techo es un incidente con fecha. La pregunta que este
archivo obliga a contestar no es cuánto se gasta: es **qué pasa cuando se acaba**, y esa
respuesta es de producto.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from decimal import Decimal


class BudgetExceeded(RuntimeError):
    """Se agotó el presupuesto. Quien llama decide qué hacer, y tiene que decidirlo."""


@dataclass(slots=True)
class DailyBudget:
    """Gasto acumulado por clave y por día.

    La clave es el paciente en Recepción asistida y la sede en NormaRAG: son los dos
    ejes por los que el gasto se dispara de verdad —un paciente ansioso a las once de la
    noche, una sede que descubre la herramienta y la usa cien veces—.

    💸 Vive en memoria: no sobrevive a un reinicio ni se comparte entre procesos. Se
    paga en el criterio 3 del miniproyecto. En producción, dos procesos con esta clase
    tienen dos presupuestos.
    """

    limit_per_key: Decimal
    limit_total: Decimal
    day: date
    spent: dict[str, Decimal] = field(default_factory=dict)

    def total(self) -> Decimal:
        return sum(self.spent.values(), start=Decimal(0))

    def check(self, key: str, estimated: Decimal) -> None:
        """Comprueba ANTES de gastar. Es la única comprobación que previene el gasto.

        Comprobar después informa; comprobar antes protege. Se hace con la estimación
        del peor caso de `ia01` —`max_tokens` completo—, que es pesimista a propósito:
        un presupuesto que se pasa porque la estimación era optimista no es un
        presupuesto.
        """
        current = self.spent.get(key, Decimal(0))

        if current + estimated > self.limit_per_key:
            raise BudgetExceeded(
                f"{key} lleva ${current} hoy y esta petición costaría hasta ${estimated}; "
                f"el tope por clave es ${self.limit_per_key}."
            )
        if self.total() + estimated > self.limit_total:
            raise BudgetExceeded(
                f"El gasto del día va en ${self.total()} y el tope es ${self.limit_total}."
            )

    def record(self, key: str, actual: Decimal) -> None:
        """Registra lo que costó de verdad, que es menos que la estimación."""
        self.spent[key] = self.spent.get(key, Decimal(0)) + actual

    def report(self) -> str:
        top = sorted(self.spent.items(), key=lambda item: item[1], reverse=True)[:3]
        lines = [f"{self.day.isoformat()}: ${self.total():.4f} en {len(self.spent)} claves"]
        lines.extend(f"  {key}: ${amount:.4f}" for key, amount in top)
        return "\n".join(lines)
