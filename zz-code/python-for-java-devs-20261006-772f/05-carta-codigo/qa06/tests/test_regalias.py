from decimal import Decimal

from regalias import royalty


def test_royalty_runs():
    assert royalty(Decimal("18420000"), Decimal("0")) is not None


def test_royalty_with_big_refunds():
    assert royalty(Decimal("100"), Decimal("500")) >= 0
