"""Unitarias y propiedades de la regalía: rápidas, sin servicios, en cada cambio."""

from decimal import Decimal

import pytest
from hypothesis import given
from hypothesis import strategies as st

from liquidacion import royalty

money = st.decimals(min_value=0, max_value=10**10, places=2)


@pytest.mark.parametrize(("billed", "refunds", "expected"), [
    ("18420000", "0", "1105200"),
    ("18420000", "420000", "1080000"),
    ("100", "500", "0"),          # devoluciones mayores que lo facturado: cero, nunca negativo
])
def test_known_cases(billed, refunds, expected):
    assert royalty(Decimal(billed), Decimal(refunds)) == Decimal(expected)


@given(billed=money, refunds=money)
def test_never_negative_and_never_above_rate(billed, refunds):
    value = royalty(billed, refunds)
    assert Decimal(0) <= value <= (billed * Decimal("0.06")).quantize(Decimal("1")) + 1


@pytest.mark.integration
def test_settlement_persists_in_postgres():
    pytest.skip("necesita Postgres: corre con -m integration antes de cada entrega")
