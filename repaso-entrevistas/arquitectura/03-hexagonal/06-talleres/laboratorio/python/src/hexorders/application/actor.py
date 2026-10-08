"""Quién ejecuta el caso de uso, ya verificado por el borde. Sin JWT, sin claims crudos, sin FastAPI."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from hexorders.domain.order import Order

from .errors import AccessDenied

Role = Literal["CUSTOMER", "OPERATOR"]


@dataclass(frozen=True, slots=True)
class Actor:
    id: str
    email: str
    role: Role

    def is_operator(self) -> bool:
        return self.role == "OPERATOR"

    def can_see(self, order: Order) -> bool:
        """Autorización contextual: dueño u operador. Vive aquí porque un job o un consumidor que
        use el mismo caso de uso tiene que cumplirla igual."""
        return self.is_operator() or order.customer_id == self.id

    def require_operator(self) -> None:
        if not self.is_operator():
            raise AccessDenied()
