"""Composition root del sabor Python. Abre los recursos, construye los adaptadores, los enchufa a
los casos de uso y arranca uvicorn. Es el único módulo que conoce a la vez los casos de uso y las
implementaciones, y el dueño del cierre (lifespan)."""

from __future__ import annotations

import logging
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone

import uvicorn

from hexorders.application.ports import Products
from hexorders.application.usecases.auth import Login, Logout
from hexorders.application.usecases.cancel import CancelOrder
from hexorders.application.usecases.notifications import DeliverPendingPublications, ListNotifications
from hexorders.application.usecases.orders import CreateOrder, GetOrder, ListOrders
from hexorders.application.usecases.payments import AuthorizePayment
from hexorders.application.usecases.products import CreateProduct, GetProduct, ListProducts
from hexorders.infrastructure import config
from hexorders.infrastructure.inbound.http.app import Deps, create_app
from hexorders.infrastructure.outbound.mongo.products import MongoProducts
from hexorders.infrastructure.outbound.notification.dispatcher import OutboxDispatcher
from hexorders.infrastructure.outbound.payment.deterministic import DeterministicPaymentGateway
from hexorders.infrastructure.outbound.postgres.adapters import (
    PgIdempotencyStore, PgInventory, PgNotifications, PgOrders, PgPayments, PgPendingPublications, PgProducts, PgUsers, TableNotifier,
)
from hexorders.infrastructure.outbound.postgres.db import Db
from hexorders.infrastructure.outbound.redis.revocation import RedisTokenRevocationStore
from hexorders.infrastructure.outbound.security.tokens import BcryptHasher, JwtTokens


class SystemClock:
    def now(self) -> datetime:
        return datetime.now(timezone.utc)


class RandomIds:
    def next(self) -> str:
        return str(uuid.uuid4())


def build():
    cfg = config.load()
    db = Db(cfg.database_url)
    revocations = RedisTokenRevocationStore(cfg.redis_url)
    clock, ids = SystemClock(), RandomIds()
    tokens = JwtTokens(cfg.jwt_secret, cfg.jwt_ttl_seconds, clock)

    # El catálogo: parte 3. Un solo valor Products; qué implementación, lo decide la configuración.
    mongo: MongoProducts | None = None
    products: Products = PgProducts(db)
    if cfg.catalog == "mongo":
        mongo = MongoProducts(cfg.mongo_url)
        products = mongo

    users, inventory, orders = PgUsers(db), PgInventory(db), PgOrders(db)
    idempotency, pending = PgIdempotencyStore(db), PgPendingPublications(db)
    deliver = DeliverPendingPublications(pending, TableNotifier(db), users, db)
    dispatcher = OutboxDispatcher(deliver, cfg.outbox_poll_ms)

    @asynccontextmanager
    async def lifespan(_):
        dispatcher.start()
        logging.getLogger("hexorders").info("hex-orders-python listening on :%d (catalog=%s)", cfg.port, cfg.catalog)
        yield
        dispatcher.stop()
        if mongo:
            mongo.close()
        revocations.close()
        db.close()

    deps = Deps(
        login=Login(users, BcryptHasher(), tokens),
        logout=Logout(revocations, clock),
        list_products=ListProducts(products, inventory),
        get_product=GetProduct(products, inventory),
        create_product=CreateProduct(products, inventory, db),
        create_order=CreateOrder(products, inventory, orders, idempotency, ids, clock, db),
        get_order=GetOrder(orders),
        list_orders=ListOrders(orders),
        authorize_payment=AuthorizePayment(orders, PgPayments(db), DeterministicPaymentGateway(), idempotency, db),
        cancel_order=CancelOrder(orders, inventory, pending, ids, clock, db),
        list_notifications=ListNotifications(PgNotifications(db)),
        verifier=tokens,
        revocations=revocations,
        cors_origin=cfg.cors_origin,
    )
    return create_app(deps, lifespan=lifespan), cfg


def run() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
    app, cfg = build()
    uvicorn.run(app, host="0.0.0.0", port=cfg.port, log_level="warning")


if __name__ == "__main__":
    run()
