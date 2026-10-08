"""Los adaptadores de PostgreSQL, uno por puerto, con SQL a mano sobre el esquema compartido. Los
importes se leen y escriben como texto (`::text`, `CAST(:p AS numeric)`); los jsonb, con
`json`; los uuid, como texto con CAST."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

from hexorders.application.page import Page, PageRequest
from hexorders.application.ports import Notification, StoredResponse, User
from hexorders.domain.errors import InsufficientInventory
from hexorders.domain.events import DomainEvent, OrderCancelled
from hexorders.domain.money import Money
from hexorders.domain.order import Order, OrderLine, Payment
from hexorders.domain.product import Product

from . import cursors
from .db import Db


def _money(value: Decimal | str, currency: str) -> Money:
    return Money.parse(str(Decimal(str(value)).quantize(Decimal("0.01"))), currency)


def _json(value) -> dict:
    return value if isinstance(value, dict) else json.loads(value)


class PgUsers:
    def __init__(self, db: Db) -> None:
        self.db = db

    def find_by_email(self, email: str) -> User | None:
        return self._to_user(self.db.one("SELECT id::text AS id, email, password_hash, role FROM users WHERE email = :email", email=email))

    def find_by_id(self, id: str) -> User | None:
        return self._to_user(self.db.one("SELECT id::text AS id, email, password_hash, role FROM users WHERE id = CAST(:id AS uuid)", id=id))

    @staticmethod
    def _to_user(row: dict | None) -> User | None:
        return None if row is None else User(row["id"], row["email"], row["password_hash"], row["role"].upper())


class PgProducts:
    """Catálogo en PostgreSQL (partes 1 y 2). main elige entre este y MongoProducts."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def find(self, sku: str) -> Product | None:
        row = self.db.one("SELECT sku, name, unit_price::text AS unit_price, currency FROM products WHERE sku = :sku", sku=sku)
        return None if row is None else Product(row["sku"], row["name"], _money(row["unit_price"], row["currency"]))

    def exists(self, sku: str) -> bool:
        return self.db.one("SELECT 1 AS x FROM products WHERE sku = :sku", sku=sku) is not None

    def list(self, page: PageRequest) -> Page[Product]:
        rows = self.db.rows(
            "SELECT sku, name, unit_price::text AS unit_price, currency FROM products WHERE sku > :after ORDER BY sku LIMIT :limit",
            after=cursors.decode(page.cursor) or "", limit=page.limit + 1)  # una fila más: ¿hay siguiente?
        more = len(rows) > page.limit
        rows = rows[: page.limit]
        items = [Product(r["sku"], r["name"], _money(r["unit_price"], r["currency"])) for r in rows]
        return Page(items, cursors.encode(rows[-1]["sku"]) if more else None)

    def save(self, product: Product) -> None:
        self.db.exec("""
            INSERT INTO products (sku, name, unit_price, currency) VALUES (:sku, :name, CAST(:price AS numeric), :currency)
            ON CONFLICT (sku) DO UPDATE SET name = EXCLUDED.name, unit_price = EXCLUDED.unit_price,
                currency = EXCLUDED.currency, updated_at = now()""",
            sku=product.sku, name=product.name, price=product.unit_price.text(), currency=product.unit_price.currency)


class PgInventory:
    """reserve descuenta línea a línea con un UPDATE condicional; al primer 0 lanza, y la transacción
    del caso de uso revierte lo ya descontado."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def available_for(self, skus: list[str]) -> dict[str, int]:
        if not skus:
            return {}
        rows = self.db.rows("SELECT sku, available FROM inventory WHERE sku = ANY(:skus)", skus=skus)
        return {r["sku"]: r["available"] for r in rows}

    def initialize(self, sku: str, quantity: int) -> None:
        self.db.exec("INSERT INTO inventory (sku, available) VALUES (:sku, :q)", sku=sku, q=quantity)

    def reserve(self, order_id: str, lines: list[OrderLine]) -> None:
        for index, line in enumerate(lines):
            updated = self.db.exec(
                "UPDATE inventory SET available = available - :q, version = version + 1, updated_at = now() WHERE sku = :sku AND available >= :q",
                sku=line.sku, q=line.quantity)
            if updated == 0:
                row = self.db.one("SELECT available FROM inventory WHERE sku = :sku", sku=line.sku)
                raise InsufficientInventory(line.sku, line.quantity, row["available"] if row else 0, index)
            self.db.exec(
                "INSERT INTO inventory_reservations (id, order_id, sku, quantity, status) VALUES (CAST(:id AS uuid), CAST(:order_id AS uuid), :sku, :q, 'RESERVED')",
                id=str(uuid.uuid4()), order_id=order_id, sku=line.sku, q=line.quantity)

    def release(self, order_id: str) -> None:
        for r in self.db.rows("SELECT id::text AS id, sku, quantity FROM inventory_reservations WHERE order_id = CAST(:o AS uuid) AND status = 'RESERVED'", o=order_id):
            self.db.exec("UPDATE inventory SET available = available + :q, version = version + 1, updated_at = now() WHERE sku = :sku", sku=r["sku"], q=r["quantity"])
            self.db.exec("UPDATE inventory_reservations SET status = 'RELEASED', updated_at = now() WHERE id = CAST(:id AS uuid)", id=r["id"])


class PgOrders:
    """Traduce entre Order y las filas de orders/order_lines/payments; reconstruye el agregado completo."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def find(self, id: str) -> Order | None:
        row = self.db.one("SELECT id::text AS id, customer_id::text AS customer_id, status, total_amount::text AS total, currency, version, created_at "
                          "FROM orders WHERE id = CAST(:id AS uuid)", id=id)
        return None if row is None else self._reconstitute(row)

    def save(self, order: Order) -> None:
        updated = self.db.exec("UPDATE orders SET status = :status, version = :version, updated_at = now() WHERE id = CAST(:id AS uuid)",
                               id=order.id, status=order.status, version=order.version + 1)
        if updated:
            return
        self.db.exec("INSERT INTO orders (id, customer_id, status, total_amount, currency, version, created_at) "
                     "VALUES (CAST(:id AS uuid), CAST(:customer AS uuid), :status, CAST(:total AS numeric), :currency, 0, :created)",
                     id=order.id, customer=order.customer_id, status=order.status, total=order.total.text(),
                     currency=order.total.currency, created=order.created_at)
        for i, line in enumerate(order.lines):
            self.db.exec("INSERT INTO order_lines (order_id, line_no, sku, product_name, quantity, unit_price) "
                         "VALUES (CAST(:o AS uuid), :n, :sku, :name, :q, CAST(:price AS numeric))",
                         o=order.id, n=i, sku=line.sku, name=line.name, q=line.quantity, price=line.unit_price.text())

    def list(self, customer_id: str | None, page: PageRequest) -> Page[Order]:
        sql = ("SELECT id::text AS id, customer_id::text AS customer_id, status, total_amount::text AS total, currency, version, created_at "
               "FROM orders WHERE true")
        params: dict = {"limit": page.limit + 1}
        if customer_id:
            sql += " AND customer_id = CAST(:customer AS uuid)"
            params["customer"] = customer_id
        cursor = cursors.decode_time(page.cursor)
        if cursor:  # (created_at, id) descendente: estable aunque se creen pedidos entre páginas
            sql += " AND (created_at, id) < (:ts, CAST(:cid AS uuid))"
            params["ts"], params["cid"] = cursor
        sql += " ORDER BY created_at DESC, id DESC LIMIT :limit"
        rows = self.db.rows(sql, **params)
        more = len(rows) > page.limit
        rows = rows[: page.limit]
        next_cursor = cursors.encode_time(rows[-1]["created_at"], rows[-1]["id"]) if more else None
        return Page([self._reconstitute(r) for r in rows], next_cursor)

    def _reconstitute(self, row: dict) -> Order:
        currency = row["currency"]
        lines = [OrderLine(l["sku"], l["product_name"], l["quantity"], _money(l["unit_price"], currency))
                 for l in self.db.rows("SELECT sku, product_name, quantity, unit_price::text AS unit_price FROM order_lines "
                                       "WHERE order_id = CAST(:o AS uuid) ORDER BY line_no", o=row["id"])]
        last = self.db.one("SELECT status, operation_id, reference FROM payments WHERE order_id = CAST(:o AS uuid) ORDER BY created_at DESC LIMIT 1", o=row["id"])
        payment = None if last is None else Payment(last["status"], last["operation_id"], last["reference"])
        return Order.reconstitute(row["id"], row["customer_id"], lines, _money(row["total"], currency), row["created_at"],
                                  row["status"], payment, int(row["version"]))


class PgPayments:
    def __init__(self, db: Db) -> None:
        self.db = db

    def record(self, order_id: str, payment: Payment, amount: Money) -> None:
        self.db.exec("INSERT INTO payments (id, order_id, operation_id, status, reference, amount, currency) "
                     "VALUES (CAST(:id AS uuid), CAST(:o AS uuid), :op, :status, :ref, CAST(:amount AS numeric), :currency)",
                     id=str(uuid.uuid4()), o=order_id, op=payment.operation_id, status=payment.status, ref=payment.reference,
                     amount=amount.text(), currency=amount.currency)


class PgIdempotencyStore:
    """La clave vive en PostgreSQL, en la misma transacción que el efecto. response_body es jsonb."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def find(self, actor_id: str, key: str) -> StoredResponse | None:
        row = self.db.one("SELECT request_hash, response_status, response_body FROM idempotency_keys WHERE key = :key AND actor_id = CAST(:a AS uuid)",
                          key=key, a=actor_id)
        return None if row is None else StoredResponse(row["request_hash"], row["response_status"], _json(row["response_body"])["ref"])

    def save(self, actor_id: str, key: str, request_hash: str, status: int, body: str) -> None:
        self.db.exec("INSERT INTO idempotency_keys (key, actor_id, request_hash, response_status, response_body) "
                     "VALUES (:key, CAST(:a AS uuid), :hash, :status, CAST(:body AS jsonb))",
                     key=key, a=actor_id, hash=request_hash, status=status, body=json.dumps({"ref": body}))


class PgPendingPublications:
    """La outbox en PostgreSQL."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def add(self, event: DomainEvent) -> None:
        self.db.exec("INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload, occurred_at) "
                     "VALUES (CAST(:id AS uuid), 'Order', CAST(:o AS uuid), :type, CAST(:payload AS jsonb), :at)",
                     id=event.event_id, o=event.order_id, type=event.type,
                     payload=json.dumps({"orderId": event.order_id, "customerId": event.customer_id}), at=event.occurred_at)

    def next_batch(self, size: int) -> list[DomainEvent]:
        rows = self.db.rows("SELECT id::text AS id, aggregate_id::text AS order_id, payload, occurred_at FROM outbox "
                            "WHERE published_at IS NULL ORDER BY occurred_at LIMIT :n", n=size)
        if rows:
            self.db.exec("UPDATE outbox SET attempts = attempts + 1 WHERE id = ANY(CAST(:ids AS uuid[]))", ids=[r["id"] for r in rows])
        return [OrderCancelled(r["id"], r["order_id"], _json(r["payload"])["customerId"], r["occurred_at"]) for r in rows]

    def mark_published(self, event_id: str) -> None:
        self.db.exec("UPDATE outbox SET published_at = now() WHERE id = CAST(:id AS uuid)", id=event_id)


class PgNotifications:
    def __init__(self, db: Db) -> None:
        self.db = db

    def list(self, order_id: str | None, page: PageRequest) -> Page[Notification]:
        sql = "SELECT id::text AS id, order_id::text AS order_id, type, recipient, created_at FROM notifications WHERE true"
        params: dict = {"limit": page.limit + 1}
        if order_id:
            sql += " AND order_id = CAST(:o AS uuid)"
            params["o"] = order_id
        cursor = cursors.decode_time(page.cursor)
        if cursor:
            sql += " AND (created_at, id) < (:ts, CAST(:cid AS uuid))"
            params["ts"], params["cid"] = cursor
        sql += " ORDER BY created_at DESC, id DESC LIMIT :limit"
        rows = self.db.rows(sql, **params)
        more = len(rows) > page.limit
        rows = rows[: page.limit]
        items = [Notification(r["id"], r["order_id"], r["type"], r["recipient"], r["created_at"]) for r in rows]
        return Page(items, cursors.encode_time(rows[-1]["created_at"], rows[-1]["id"]) if more else None)


class TableNotifier:
    """Entrega escribiendo una fila; ON CONFLICT DO NOTHING hace que una segunda entrega no cree otra."""

    def __init__(self, db: Db) -> None:
        self.db = db

    def notify(self, event: DomainEvent, recipient: str) -> None:
        self.db.exec("INSERT INTO notifications (id, order_id, type, recipient, payload) "
                     "VALUES (CAST(:id AS uuid), CAST(:o AS uuid), :type, :to, CAST(:payload AS jsonb)) ON CONFLICT (id) DO NOTHING",
                     id=event.event_id, o=event.order_id, type=event.type, to=recipient,
                     payload=json.dumps({"eventId": event.event_id, "occurredAt": event.occurred_at.isoformat()}))


_ = timedelta  # (importado para el tipo del puerto; no se usa aquí)
