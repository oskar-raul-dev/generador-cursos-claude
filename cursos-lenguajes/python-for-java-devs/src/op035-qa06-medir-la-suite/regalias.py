"""La regalía trimestral: tasa, piso cero y redondeo al peso."""

from decimal import ROUND_HALF_EVEN, Decimal

RATE = Decimal("0.06")


def royalty(billed: Decimal, refunds: Decimal) -> Decimal:
    base = billed - refunds
    if base < 0:
        base = Decimal(0)
    return (base * RATE).quantize(Decimal("1"), rounding=ROUND_HALF_EVEN)
