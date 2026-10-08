"""El traductor central: cada error propio se convierte UNA vez en problem+json con el código
estable del contrato. Ni el dominio ni los casos de uso conocen estos números."""

from __future__ import annotations

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from hexorders.application.errors import AccessDenied, IdempotencyKeyReused, InvalidCredentials, NotFound, ProductAlreadyExists
from hexorders.domain.errors import EmptyOrder, InsufficientInventory, OrderNotCancellable, OrderNotPayable

log = logging.getLogger("hexorders")


class ValidationFailed(Exception):
    """Error de forma propio del borde (cabeceras, ids), con campos."""

    def __init__(self, errors: list[dict]) -> None:
        super().__init__("validation failed")
        self.errors = errors


class MissingIdempotencyKey(Exception):
    pass


class Unauthenticated(Exception):
    def __init__(self, code: str) -> None:  # UNAUTHENTICATED | TOKEN_REVOKED
        super().__init__(code)
        self.code = code


def problem(request: Request, status: int, title: str, code: str, detail: str | None = None,
            errors: list[dict] | None = None) -> JSONResponse:
    body: dict = {"type": "about:blank", "title": title, "status": status, "instance": request.url.path, "code": code}
    if detail:
        body["detail"] = detail
    if errors:
        body["errors"] = errors
    headers = {"WWW-Authenticate": "Bearer"} if status == 401 else None
    return JSONResponse(body, status_code=status, media_type="application/problem+json", headers=headers)


def _field(loc: tuple) -> str:
    parts = [str(p) for p in loc if p not in ("body", "query", "path", "header")]
    out = ""
    for p in parts:
        out += f"[{p}]" if p.isdigit() else (f".{p}" if out else p)
    return out or "body"


def install(app: FastAPI) -> None:
    @app.exception_handler(InsufficientInventory)
    def insufficient(request: Request, e: InsufficientInventory):
        return problem(request, 409, "Insufficient inventory", "INSUFFICIENT_INVENTORY", str(e),
                       [{"field": f"lines[{e.line_index}].quantity", "message": f"requested {e.requested}, available {e.available}"}])

    @app.exception_handler(OrderNotPayable)
    def not_payable(request: Request, e: OrderNotPayable):
        return problem(request, 409, "Order not payable", "ORDER_NOT_PAYABLE", str(e))

    @app.exception_handler(OrderNotCancellable)
    def not_cancellable(request: Request, e: OrderNotCancellable):
        return problem(request, 409, "Order not cancellable", "ORDER_NOT_CANCELLABLE", str(e))

    @app.exception_handler(EmptyOrder)
    def empty(request: Request, e: EmptyOrder):
        return problem(request, 400, "Validation failed", "VALIDATION_FAILED", str(e), [{"field": "lines", "message": "must not be empty"}])

    @app.exception_handler(NotFound)
    def not_found(request: Request, e: NotFound):
        if e.kind == "PRODUCT":
            return problem(request, 404, "Product not found", "PRODUCT_NOT_FOUND", e.identifier)
        return problem(request, 404, "Order not found", "ORDER_NOT_FOUND")

    @app.exception_handler(AccessDenied)
    def forbidden(request: Request, e: AccessDenied):
        return problem(request, 403, "Forbidden", "FORBIDDEN")

    @app.exception_handler(InvalidCredentials)
    def invalid_credentials(request: Request, e: InvalidCredentials):
        return problem(request, 401, "Invalid credentials", "INVALID_CREDENTIALS")

    @app.exception_handler(IdempotencyKeyReused)
    def key_reused(request: Request, e: IdempotencyKeyReused):
        return problem(request, 422, "Idempotency-Key reused with a different payload", "IDEMPOTENCY_KEY_REUSED")

    @app.exception_handler(ProductAlreadyExists)
    def exists(request: Request, e: ProductAlreadyExists):
        return problem(request, 409, "Product already exists", "PRODUCT_ALREADY_EXISTS", str(e))

    @app.exception_handler(Unauthenticated)
    def unauthenticated(request: Request, e: Unauthenticated):
        return problem(request, 401, "Token revoked" if e.code == "TOKEN_REVOKED" else "Unauthenticated", e.code)

    @app.exception_handler(MissingIdempotencyKey)
    def missing_key(request: Request, e: MissingIdempotencyKey):
        return problem(request, 400, "Idempotency-Key required", "IDEMPOTENCY_KEY_REQUIRED")

    @app.exception_handler(ValidationFailed)
    def validation_failed(request: Request, e: ValidationFailed):
        return problem(request, 400, "Validation failed", "VALIDATION_FAILED", errors=e.errors)

    @app.exception_handler(RequestValidationError)
    def request_validation(request: Request, e: RequestValidationError):
        # cuerpo, query o path que no cumplen el DTO: 400 con campos, no el 422 por defecto de FastAPI
        errors = [{"field": _field(err["loc"]), "message": err["msg"]} for err in e.errors()]
        return problem(request, 400, "Validation failed", "VALIDATION_FAILED", errors=errors)

    @app.exception_handler(StarletteHTTPException)
    def http_exception(request: Request, e: StarletteHTTPException):
        if e.status_code == 404:
            return problem(request, 404, "Not found", "ORDER_NOT_FOUND")
        return problem(request, e.status_code, str(e.detail), "VALIDATION_FAILED" if e.status_code < 500 else "INTERNAL_ERROR")

    @app.exception_handler(Exception)
    def unexpected(request: Request, e: Exception):
        log.exception("unexpected error handling %s %s", request.method, request.url.path)
        return problem(request, 500, "Internal error", "INTERNAL_ERROR")
