"""La aplicación FastAPI: rutas, dependencias y traducción de errores. Recibe los casos de uso ya
construidos (Deps); no importa ningún adaptador de salida. Los endpoints son síncronos (`def`):
FastAPI los ejecuta en un threadpool, y como el driver de PostgreSQL es síncrono, un `async def`
no lo volvería no bloqueante: solo lo escondería (capítulo 05/05).

Sin `from __future__ import annotations`: FastAPI resuelve las anotaciones en tiempo de definición
y los alias `Auth`, `Who` y `Key` son variables locales de `create_app`; como strings diferidos no
podría encontrarlos (véase §8 del taller)."""

import hashlib
from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from fastapi import Depends, FastAPI, Header, Query, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from hexorders.application.actor import Actor
from hexorders.application.page import PageRequest
from hexorders.application.ports import TokenRevocationStore
from hexorders.application.usecases.auth import Login, Logout
from hexorders.application.usecases.cancel import CancelOrder
from hexorders.application.usecases.notifications import ListNotifications
from hexorders.application.usecases.orders import CreateOrder, CreateOrderCommand, GetOrder, LineRequest, ListOrders
from hexorders.application.usecases.payments import AuthorizePayment
from hexorders.application.usecases.products import CreateProduct, GetProduct, ListProducts

from . import problems, schemas
from .auth import AuthContext, Authenticator, TokenVerifier


@dataclass(frozen=True, slots=True)
class Deps:
    login: Login
    logout: Logout
    list_products: ListProducts
    get_product: GetProduct
    create_product: CreateProduct
    create_order: CreateOrder
    get_order: GetOrder
    list_orders: ListOrders
    authorize_payment: AuthorizePayment
    cancel_order: CancelOrder
    list_notifications: ListNotifications
    verifier: TokenVerifier
    revocations: TokenRevocationStore
    cors_origin: str


def require_idempotency_key(idempotency_key: Annotated[str | None, Header()] = None) -> str:
    if not idempotency_key:
        raise problems.MissingIdempotencyKey()
    if not 8 <= len(idempotency_key) <= 128:
        raise problems.ValidationFailed([{"field": "Idempotency-Key", "message": "must be between 8 and 128 characters"}])
    return idempotency_key


def request_hash(canonical: str) -> str:
    return hashlib.sha256(canonical.encode()).hexdigest()


def create_app(deps: Deps, lifespan=None) -> FastAPI:
    app = FastAPI(title="hex-orders", docs_url=None, redoc_url=None, openapi_url=None, lifespan=lifespan)
    app.add_middleware(CORSMiddleware, allow_origins=[deps.cors_origin], allow_methods=["GET", "POST", "OPTIONS"],
                       allow_headers=["Authorization", "Content-Type", "Idempotency-Key", "Accept"],
                       expose_headers=["Location", "Idempotent-Replay"])
    problems.install(app)

    authenticate = Authenticator(deps.verifier, deps.revocations)
    Auth = Annotated[AuthContext, Depends(authenticate)]

    def actor_of(auth: Auth) -> Actor:
        return auth.actor

    Who = Annotated[Actor, Depends(actor_of)]
    Key = Annotated[str, Depends(require_idempotency_key)]

    @app.get("/health")
    def health():
        return {"status": "UP"}

    @app.post("/api/v1/auth/login")
    def login(body: schemas.LoginRequest):
        token = deps.login.execute(body.email, body.password)
        return {"accessToken": token.value, "tokenType": "Bearer", "expiresIn": token.expires_in_seconds}

    @app.post("/api/v1/auth/logout", status_code=204)
    def logout(auth: Auth):
        deps.logout.execute(auth.token.token_id, auth.token.expires_at)
        return Response(status_code=204)

    @app.get("/api/v1/products")
    def list_products(_: Who, cursor: str | None = None, limit: int | None = Query(default=None)):
        page = deps.list_products.execute(PageRequest.of(cursor, limit))
        return schemas.page_response([schemas.product_response(p) for p in page.items], page.next_cursor)

    @app.get("/api/v1/products/{sku}")
    def get_product(_: Who, sku: str):
        return schemas.product_response(deps.get_product.execute(sku))

    @app.post("/api/v1/products", status_code=201)
    def create_product(actor: Who, body: schemas.CreateProductRequest, response: Response):
        created = deps.create_product.execute(actor, body.sku, body.name, body.unit_price.to_money(), body.stock)
        response.headers["Location"] = f"/api/v1/products/{created.product.sku}"
        return schemas.product_response(created)

    @app.post("/api/v1/orders")
    def create_order(actor: Who, key: Key, body: schemas.CreateOrderRequest, response: Response):
        result = deps.create_order.execute(CreateOrderCommand(
            actor, key, request_hash(body.canonical()), [LineRequest(l.sku, l.quantity) for l in body.lines]))
        if result.replayed:
            response.status_code = 200
            response.headers["Idempotent-Replay"] = "true"
        else:
            response.status_code = 201
            response.headers["Location"] = f"/api/v1/orders/{result.order.id}"
        return schemas.order_response(result.order)

    @app.get("/api/v1/orders")
    def list_orders(actor: Who, cursor: str | None = None, limit: int | None = Query(default=None)):
        page = deps.list_orders.execute(actor, PageRequest.of(cursor, limit))
        return schemas.page_response([schemas.order_response(o) for o in page.items], page.next_cursor)

    @app.get("/api/v1/orders/{order_id}")
    def get_order(actor: Who, order_id: UUID):
        return schemas.order_response(deps.get_order.execute(actor, str(order_id)))

    @app.post("/api/v1/orders/{order_id}/payment")
    def pay(actor: Who, order_id: UUID, key: Key, response: Response):
        result = deps.authorize_payment.execute(actor, str(order_id), key)
        if result.replayed:
            response.headers["Idempotent-Replay"] = "true"
        return schemas.payment_response(result.order, result.payment)

    @app.post("/api/v1/orders/{order_id}/cancel")
    def cancel(actor: Who, order_id: UUID):
        return schemas.order_response(deps.cancel_order.execute(actor, str(order_id)))

    @app.get("/api/v1/notifications")
    def list_notifications(actor: Who, orderId: UUID | None = None, cursor: str | None = None,
                           limit: int | None = Query(default=None)):
        page = deps.list_notifications.execute(actor, str(orderId) if orderId else None, PageRequest.of(cursor, limit))
        return schemas.page_response([schemas.notification_response(n) for n in page.items], page.next_cursor)

    return app
