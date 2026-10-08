"""Errores de aplicación: existencia, permisos, credenciales, idempotencia."""

from typing import Literal


class ApplicationError(Exception):
    pass


class NotFound(ApplicationError):
    """'No existe' y 'no es tuyo' se expresan igual: el borde responde 404 sin revelar existencia."""

    def __init__(self, kind: Literal["PRODUCT", "ORDER"], identifier: str) -> None:
        super().__init__(f"{kind.lower()} not found: {identifier}")
        self.kind, self.identifier = kind, identifier


class AccessDenied(ApplicationError):
    def __init__(self) -> None:
        super().__init__("actor lacks the required capability")


class InvalidCredentials(ApplicationError):
    def __init__(self) -> None:
        super().__init__("invalid credentials")


class IdempotencyKeyReused(ApplicationError):
    def __init__(self) -> None:
        super().__init__("Idempotency-Key reused with a different payload")


class ProductAlreadyExists(ApplicationError):
    def __init__(self, sku: str) -> None:
        super().__init__(f"{sku} already exists")
        self.sku = sku
