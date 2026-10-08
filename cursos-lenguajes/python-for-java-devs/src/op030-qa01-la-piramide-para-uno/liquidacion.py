"""Regalías del trimestre: la regla que más dinero mueve y más se discute."""

from decimal import ROUND_HALF_EVEN, Decimal

ROYALTY_RATE = Decimal("0.06")


def royalty(billed: Decimal, refunds: Decimal = Decimal(0)) -> Decimal:
    if billed < 0 or refunds < 0:
        raise ValueError("facturado y devoluciones no pueden ser negativos")
    base = max(billed - refunds, Decimal(0))
    return (base * ROYALTY_RATE).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
