"""Errores de negocio del dominio: rechazos esperados con nombre propio. El borde les pone
código HTTP; aquí no hay números."""


class DomainError(Exception):
    pass


class EmptyOrder(DomainError):
    def __init__(self) -> None:
        super().__init__("an order must have at least one line")


class OrderNotPayable(DomainError):
    def __init__(self, status: str) -> None:
        super().__init__(f"order is {status}")
        self.status = status


class OrderNotCancellable(DomainError):
    def __init__(self, status: str) -> None:
        super().__init__(f"order is {status}")
        self.status = status


class InsufficientInventory(DomainError):
    """La lanza el adaptador de inventario al primer faltante; la unidad de trabajo revierte el resto."""

    def __init__(self, sku: str, requested: int, available: int, line_index: int) -> None:
        super().__init__(f"{sku}: requested {requested}, available {available}")
        self.sku, self.requested, self.available, self.line_index = sku, requested, available, line_index
