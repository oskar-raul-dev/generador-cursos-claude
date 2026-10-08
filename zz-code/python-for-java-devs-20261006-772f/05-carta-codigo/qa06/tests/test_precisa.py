from decimal import Decimal

import pytest

from regalias import royalty


@pytest.mark.parametrize(("billed", "refunds", "expected"), [
    ("18420000", "0", "1105200"),       # la tasa: cualquier cambio a 0.06 falla aquí
    ("18420000", "420000", "1080000"),  # las devoluciones se restan, no se suman
    ("100", "500", "0"),                # el piso: negativo se vuelve cero
    ("100", "100", "0"),                # el borde del piso: exactamente cero
    ("75", "0", "4"),                   # 4,50 → 4 con redondeo bancario (y 5 hacia arriba)
])
def test_royalty_exact(billed, refunds, expected):
    assert royalty(Decimal(billed), Decimal(refunds)) == Decimal(expected)
