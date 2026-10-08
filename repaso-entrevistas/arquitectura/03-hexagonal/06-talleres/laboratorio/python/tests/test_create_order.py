"""El caso de uso con dobles fieles a los puertos y una unidad de trabajo de pruebas que restaura
los fakes si el trabajo lanza: lo que Db.run hace, reducido a lo observable. Los fakes no heredan
de nada: satisfacen los Protocol por tener los métodos."""

from datetime import datetime, timezone

import pytest

from hexorders.application.actor import Actor
from hexorders.application.errors import IdempotencyKeyReused
from hexorders.application.page import Page
from hexorders.application.ports import StoredResponse
from hexorders.application.usecases.orders import CreateOrder, CreateOrderCommand, LineRequest
from hexorders.domain.errors import InsufficientInventory
from hexorders.domain.money import Money
from hexorders.domain.product import Product

ANA = Actor("11111111-1111-4111-8111-111111111111", "ana@hex.local", "CUSTOMER")


class FakeProducts:
    def __init__(self):
        self.data = {}

    def find(self, sku):
        return self.data.get(sku)

    def exists(self, sku):
        return sku in self.data

    def list(self, page):
        return Page(list(self.data.values()), None)

    def save(self, product):
        self.data[product.sku] = product


class FakeInventory:
    def __init__(self):
        self.available = {}

    def available_for(self, skus):
        return {s: self.available.get(s, 0) for s in skus}

    def initialize(self, sku, quantity):
        self.available[sku] = quantity

    def reserve(self, order_id, lines):
        # como el adaptador real: descuenta línea a línea y lanza al primer faltante
        for i, line in enumerate(lines):
            have = self.available.get(line.sku, 0)
            if have < line.quantity:
                raise InsufficientInventory(line.sku, line.quantity, have, i)
            self.available[line.sku] = have - line.quantity

    def release(self, order_id):
        pass


class FakeOrders:
    def __init__(self):
        self.data = {}

    def find(self, id):
        return self.data.get(id)

    def save(self, order):
        self.data[order.id] = order

    def list(self, customer_id, page):
        return Page(list(self.data.values()), None)


class FakeIdempotency:
    def __init__(self):
        self.data = {}

    def find(self, actor_id, key):
        return self.data.get(f"{actor_id}:{key}")

    def save(self, actor_id, key, request_hash, status, body):
        self.data[f"{actor_id}:{key}"] = StoredResponse(request_hash, status, body)


class SnapshotUnitOfWork:
    def __init__(self, orders, inventory, keys):
        self.o, self.i, self.k = orders, inventory, keys

    def run(self, work):
        snapshot = (dict(self.o.data), dict(self.i.available), dict(self.k.data))
        try:
            return work()
        except Exception:
            self.o.data, self.i.available, self.k.data = snapshot
            raise


class FixedClock:
    def now(self):
        return datetime(2026, 9, 27, 12, 0, tzinfo=timezone.utc)


class SeqIds:
    def __init__(self):
        self.n = 0

    def next(self):
        self.n += 1
        return f"order-{self.n}"


@pytest.fixture
def system():
    products, inventory, orders, keys = FakeProducts(), FakeInventory(), FakeOrders(), FakeIdempotency()
    products.save(Product("SKU-001", "Mechanical keyboard", Money.usd("49.90")))
    products.save(Product("SKU-004", "Webcam", Money.usd("59.00")))
    inventory.initialize("SKU-001", 20)
    inventory.initialize("SKU-004", 0)
    uc = CreateOrder(products, inventory, orders, keys, SeqIds(), FixedClock(), SnapshotUnitOfWork(orders, inventory, keys))
    return uc, inventory, orders, keys


def command(key, *lines):
    return CreateOrderCommand(ANA, key, ",".join(f"{l.sku}:{l.quantity}" for l in lines), list(lines))


def test_reserves_stock_and_remembers_key(system):
    uc, inventory, orders, _ = system
    result = uc.execute(command("key-0001", LineRequest("SKU-001", 2)))
    assert not result.replayed and result.order.total.text() == "99.80"
    assert inventory.available["SKU-001"] == 18 and result.order.id in orders.data


def test_same_key_same_body_replays(system):
    uc, inventory, _, _ = system
    first = uc.execute(command("key-0002", LineRequest("SKU-001", 2)))
    again = uc.execute(command("key-0002", LineRequest("SKU-001", 2)))
    assert again.replayed and again.order.id == first.order.id and inventory.available["SKU-001"] == 18


def test_same_key_different_body_rejected(system):
    uc, _, _, _ = system
    uc.execute(command("key-0003", LineRequest("SKU-001", 1)))
    with pytest.raises(IdempotencyKeyReused):
        uc.execute(command("key-0003", LineRequest("SKU-001", 3)))


def test_insufficient_inventory_leaves_nothing_behind(system):
    uc, inventory, orders, keys = system
    with pytest.raises(InsufficientInventory):
        uc.execute(command("key-0004", LineRequest("SKU-001", 1), LineRequest("SKU-004", 1)))
    # el pedido se guardó antes de reservar; lo que lo deshace es la unidad de trabajo
    assert inventory.available["SKU-001"] == 20 and orders.data == {} and keys.data == {}
