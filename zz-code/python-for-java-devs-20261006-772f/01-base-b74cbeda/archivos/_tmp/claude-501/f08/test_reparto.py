"""El invariante del dominio: lo repartido suma exactamente lo cobrado."""
from decimal import Decimal

from hypothesis import given, settings
from hypothesis import strategies as st


def split_fee_float(total, shares):
    """Reparte el total entre los profesionales. Con float, como saldría solo."""
    total_f = float(total)
    return [round(total_f * s, 2) for s in shares]


def split_fee_decimal(total, shares):
    """Con Decimal, y el último se lleva el residuo."""
    parts = []
    remaining = total
    for share in shares[:-1]:
        part = (total * Decimal(str(share))).quantize(Decimal("0.01"))
        parts.append(part)
        remaining -= part
    parts.append(remaining)
    return parts


money = st.decimals(min_value=Decimal("1000"), max_value=Decimal("50000000"),
                    places=2, allow_nan=False, allow_infinity=False)

@given(total=money)
@settings(max_examples=300)
def test_float_suma_exacta(total):
    partes = split_fee_float(total, [0.4, 0.35, 0.25])
    assert Decimal(str(sum(partes))) == total

@given(total=money)
@settings(max_examples=300)
def test_decimal_suma_exacta(total):
    partes = split_fee_decimal(total, [0.4, 0.35, 0.25])
    assert sum(partes) == total
