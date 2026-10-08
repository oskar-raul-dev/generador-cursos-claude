"""payments: cobra pedidos hablando con el proveedor externo (psp-simulator).

Extraído del monolito en el taller 03. Asíncrono de punta a punta: FastAPI con `async def`, pool
asíncrono de psycopg y cliente httpx asíncrono. Un solo proceso atiende muchas esperas a la vez
porque casi todo su tiempo es esperar al proveedor.
"""
import logging
import os
import uuid
from contextlib import asynccontextmanager
from decimal import Decimal

import httpx
from fastapi import FastAPI, Header, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from psycopg import errors as pg_errors
from psycopg_pool import AsyncConnectionPool
from purgatory import AsyncCircuitBreakerFactory
from purgatory.domain.model import OpenedState
from pydantic import BaseModel, Field

DB_URL = os.environ.get("PAYMENTS_DB_URL", "postgresql://ms_payments:ms-lab-pass@localhost:25432/ms_payments")
PSP_URL = os.environ.get("PAYMENTS_PSP_URL", "http://localhost:28185")        # a través de Toxiproxy
PSP_TIMEOUT_S = float(os.environ.get("PAYMENTS_PSP_TIMEOUT_S", "2.0"))        # el 666.00 tarda 3 s
BREAKER_THRESHOLD = int(os.environ.get("PAYMENTS_PSP_BREAKER_THRESHOLD", "3"))  # fallos SEGUIDOS para abrir
BREAKER_TTL_S = float(os.environ.get("PAYMENTS_PSP_BREAKER_TTL_S", "10"))       # abierto antes de probar

log = logging.getLogger("payments")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = AsyncConnectionPool(DB_URL, min_size=1, max_size=10, open=False)
    await app.state.pool.open()
    # timeout por petición al proveedor: 2 s para leer, 1 s para conectar
    app.state.psp = httpx.AsyncClient(base_url=PSP_URL, timeout=httpx.Timeout(PSP_TIMEOUT_S, connect=1.0))
    # circuit breaker hacia el proveedor (taller 05). El estado vive EN ESTE PROCESO: con varios
    # workers, cada uno tiene el suyo (purgatory permite guardarlo en Redis para compartirlo).
    app.state.breakers = AsyncCircuitBreakerFactory(default_threshold=BREAKER_THRESHOLD, default_ttl=BREAKER_TTL_S)
    yield
    await app.state.psp.aclose()
    await app.state.pool.close()


app = FastAPI(title="payments", lifespan=lifespan)


class PaymentRequest(BaseModel):
    orderId: uuid.UUID
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    currency: str = Field(default="USD", pattern="^[A-Z]{3}$")


def problem(status: int, title: str, code: str, request: Request, **extra) -> JSONResponse:
    body = {"type": "about:blank", "title": title, "status": status, "code": code, "instance": request.url.path, **extra}
    return JSONResponse(status_code=status, content=body, media_type="application/problem+json")


@app.exception_handler(RequestValidationError)
async def invalid(request: Request, exc: RequestValidationError):
    errors = [{"field": ".".join(str(p) for p in e["loc"][1:]), "message": e["msg"]} for e in exc.errors()]
    return problem(400, "Validation failed", "VALIDATION_FAILED", request, errors=errors)


@app.get("/health")
async def health():
    return {"status": "UP"}


@app.get("/payments")
async def list_payments(request: Request):
    async with request.app.state.pool.connection() as conn:
        cur = await conn.execute("SELECT id, order_id, operation_id, status, reference, amount FROM payments ORDER BY created_at")
        rows = await cur.fetchall()
    return {"items": [{"id": str(r[0]), "orderId": str(r[1]), "operationId": r[2], "status": r[3],
                       "reference": r[4], "amount": f"{r[5]:.2f}"} for r in rows]}


@app.post("/payments", status_code=201)
async def create_payment(body: PaymentRequest, request: Request,
                         idempotency_key: str | None = Header(default=None)):
    # Sin clave, cada petición es un intento nuevo con su propia clave hacia el proveedor: es lo que
    # hace que un reintento del llamador cobre dos veces (06/03 §6). Con clave, es la misma operación.
    operation_id = idempotency_key or f"gen-{uuid.uuid4()}"
    pool: AsyncConnectionPool = request.app.state.pool

    async with pool.connection() as conn:
        cur = await conn.execute(
            "SELECT id, status, reference FROM payments WHERE operation_id = %s", (operation_id,))
        row = await cur.fetchone()
        if row:
            if row[1] == "IN_PROGRESS":
                return problem(409, "Payment in progress", "PAYMENT_IN_PROGRESS", request)
            if row[1] != "PENDING":
                return JSONResponse(status_code=200, headers={"Idempotent-Replay": "true"},
                                    content=view(row[0], body, operation_id, row[1], row[2]))
            # PENDING no es una respuesta final: la repetición vuelve a preguntar al proveedor con la
            # MISMA clave, que él reconoce (06/03 §7). Si sigue sin responder, sigue PENDING.
            payment_id = row[0]
        else:
            payment_id = None
    inserted = payment_id is None
    if payment_id is None:
        payment_id = uuid.uuid4()
        async with pool.connection() as conn:
            try:
                # la intención se registra y se confirma ANTES de llamar: si el proceso muere durante la
                # llamada, queda una fila IN_PROGRESS que se puede conciliar, no un cobro sin rastro
                await conn.execute(
                    "INSERT INTO payments (id, order_id, operation_id, amount, status) VALUES (%s, %s, %s, %s, 'IN_PROGRESS')",
                    (payment_id, body.orderId, operation_id, body.amount))
                await conn.commit()
            except pg_errors.UniqueViolation:
                return problem(409, "Payment in progress", "PAYMENT_IN_PROGRESS", request)

    # la llamada al proveedor, sin conexión de base tomada (la lección de 06/01)
    status, reference = "PENDING", None
    try:
        async with await request.app.state.breakers.get_breaker("psp"):
            res = await request.app.state.psp.post(
                "/payments", headers={"Idempotency-Key": operation_id},
                json={"orderId": str(body.orderId), "amount": f"{body.amount:.2f}", "currency": body.currency})
            res.raise_for_status()
            status, reference = res.json()["status"], res.json()["reference"]
    except OpenedState:
        # el breaker no dejó llamar: es SEGURO que no se cobró. La intención recién registrada se
        # borra (una repetición con la misma clave empezará de cero) y se dice con un código propio.
        log.warning("psp breaker open: not calling for %s (%s)", body.orderId, operation_id)
        if inserted:
            async with pool.connection() as conn:
                await conn.execute("DELETE FROM payments WHERE id = %s AND status = 'IN_PROGRESS'", (payment_id,))
        return problem(503, "PSP unavailable", "PSP_UNAVAILABLE", request)
    except (httpx.TimeoutException, httpx.TransportError) as e:
        log.warning("psp did not answer for %s (%s): %s → PENDING", body.orderId, operation_id, type(e).__name__)

    async with pool.connection() as conn:
        await conn.execute("UPDATE payments SET status = %s, reference = %s WHERE id = %s",
                           (status, reference, payment_id))
    log.info("payment %s order=%s key=%s → %s", payment_id, body.orderId, operation_id, status)
    return view(payment_id, body, operation_id, status, reference)


def view(payment_id, body: PaymentRequest, operation_id: str, status: str, reference: str | None) -> dict:
    return {"id": str(payment_id), "orderId": str(body.orderId), "operationId": operation_id,
            "status": status, "reference": reference, "amount": f"{body.amount:.2f}"}
