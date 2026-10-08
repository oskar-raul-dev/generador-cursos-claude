"""El proveedor de pagos de las partes 1–3: la regla determinista de §11 de la guía."""

from hexorders.domain.money import Money
from hexorders.domain.order import Payment


class DeterministicPaymentGateway:
    def authorize(self, operation_id: str, amount: Money) -> Payment:
        if amount.is_greater_than(Money.usd("1000.00")):
            return Payment("REJECTED", operation_id, None)
        if amount.has_amount("666.00"):
            return Payment("PENDING", operation_id, None)  # el proveedor "no respondió"
        return Payment("AUTHORIZED", operation_id, f"gw-{operation_id}")
