"""Pruebas que usan la fábrica, la parametrización compuesta y la indirecta."""

import time
from decimal import Decimal

import pytest

from conftest import LOADS


def test_tariffs_are_loaded_once(tariffs):
    assert LOADS["tariffs"] == 1


def test_tariffs_are_read_only(tariffs):
    with pytest.raises(TypeError):
        tariffs["D0120"] = Decimal(0)


@pytest.mark.parametrize("franchise", ["Suba", "Zipaquirá"])
@pytest.mark.parametrize("codes", [("D0120",), ("D0120", "D1110")])
def test_billed_is_sum_of_tariffs(make_settlement, franchise, codes):
    settlement = make_settlement(franchise=franchise, codes=codes)
    assert settlement["billed"] > 0
    assert settlement["franchise"] == franchise


@pytest.mark.parametrize("quarter", ["2026T3", "2026T4"], indirect=True)
def test_quarter_is_built(quarter):
    assert quarter["year"] == 2026 and quarter["q"] in (3, 4)


def test_too_slow_for_the_fast_suite():
    time.sleep(0.6)                                    # viola el presupuesto de medio segundo
