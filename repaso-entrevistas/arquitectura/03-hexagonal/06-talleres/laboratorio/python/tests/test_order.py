"""Pruebas del agregado sin FastAPI, sin base y sin mocks: la máquina de estados del contrato."""

from datetime import datetime, timezone

import pytest

from hexorders.domain.errors import EmptyOrder, OrderNotCancellable, OrderNotPayable
from hexorders.domain.money import Money
from hexorders.domain.order import Order, OrderLine, Payment

NOW = datetime(2026, 9, 27, 12, 0, tzinfo=timezone.utc)
ANA = "11111111-1111-4111-8111-111111111111"


def order(amount: str) -> Order:
    return Order.place("o-1", ANA, [OrderLine("SKU-001", "Mechanical keyboard", 1, Money.usd(amount))], NOW)


def test_rejects_an_order_without_lines():
    with pytest.raises(EmptyOrder):
        Order.place("o-1", ANA, [], NOW)


def test_confirmed_and_totals_without_floats():
    o = Order.place("o-1", ANA, [
        OrderLine("SKU-001", "Mechanical keyboard", 2, Money.usd("49.90")),
        OrderLine("SKU-002", "USB-C cable", 1, Money.usd("9.90")),
    ], NOW)
    assert o.status == "CONFIRMED"
    assert o.total.text() == "109.70"


def test_paid_is_neither_payable_nor_cancellable():
    o = order("9.90")
    o.apply_payment(Payment("AUTHORIZED", "op-1", "gw-op-1"))
    assert o.status == "PAID"
    with pytest.raises(OrderNotPayable):
        o.apply_payment(Payment("AUTHORIZED", "op-2", None))
    with pytest.raises(OrderNotCancellable):
        o.cancel(NOW, "e-1")


def test_rejected_stays_payable_pending_does_not():
    rejected = order("1499.00")
    rejected.apply_payment(Payment("REJECTED", "op-1", None))
    assert rejected.is_payable()
    pending = order("666.00")
    pending.apply_payment(Payment("PENDING", "op-2", None))
    assert not pending.is_payable() and pending.is_cancellable()


def test_cancel_is_idempotent_and_emits_once():
    o = order("9.90")
    assert o.cancel(NOW, "e-1") is True
    assert len(o.pull_events()) == 1
    assert o.cancel(NOW, "e-2") is False
    assert o.pull_events() == []
    assert o.status == "CANCELLED"
