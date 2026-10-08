"""Los DTO del contrato HTTP: modelos Pydantic en modo estricto, solo en el borde. El núcleo
recibe comandos con tipos propios; Pydantic no cruza el puerto."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from hexorders.application.ports import Notification
from hexorders.application.usecases.products import ProductWithStock
from hexorders.domain.money import Money
from hexorders.domain.order import Order, OrderLine, Payment


class Strict(BaseModel):
    # strict: "10" no se convierte en 10; extra="ignore": los campos que el DTO no declara se descartan
    model_config = ConfigDict(strict=True, extra="ignore")


class LoginRequest(Strict):
    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    password: str = Field(min_length=8)


class MoneyDto(Strict):
    amount: str = Field(pattern=r"^-?[0-9]+\.[0-9]{2}$", description="must be a decimal with two digits")
    currency: str = Field(pattern=r"^[A-Z]{3}$")

    def to_money(self) -> Money:
        return Money.parse(self.amount, self.currency)


class CreateProductRequest(Strict):
    sku: str = Field(pattern=r"^SKU-[0-9]{3,}$")
    name: str = Field(min_length=1, max_length=120)
    unit_price: MoneyDto = Field(alias="unitPrice")
    stock: int = Field(ge=0)


class LineRequestDto(Strict):
    sku: str = Field(pattern=r"^SKU-[0-9]{3,}$")
    quantity: int = Field(ge=1, le=1000)


class CreateOrderRequest(Strict):
    lines: list[LineRequestDto] = Field(min_length=1, max_length=50)

    def canonical(self) -> str:
        """Huella canónica del cuerpo para la idempotencia."""
        return ",".join(f"{l.sku}:{l.quantity}" for l in self.lines)


# ---------------------------------------------------------------- salida (dicts con las claves del contrato)

def money(m: Money) -> dict:
    return {"amount": m.text(), "currency": m.currency}


def product_response(p: ProductWithStock) -> dict:
    return {"sku": p.product.sku, "name": p.product.name, "unitPrice": money(p.product.unit_price), "stock": p.stock}


def _line(l: OrderLine) -> dict:
    return {"sku": l.sku, "name": l.name, "quantity": l.quantity, "unitPrice": money(l.unit_price), "lineTotal": money(l.line_total())}


def _payment(p: Payment | None) -> dict | None:
    return None if p is None else {"status": p.status, "operationId": p.operation_id, "reference": p.reference}


def order_response(o: Order) -> dict:
    return {
        "id": o.id, "customerId": o.customer_id, "status": o.status, "lines": [_line(l) for l in o.lines],
        "total": money(o.total), "payment": _payment(o.payment), "createdAt": o.created_at.isoformat().replace("+00:00", "Z"),
    }


def payment_response(o: Order, p: Payment) -> dict:
    return {"orderId": o.id, "orderStatus": o.status, "payment": _payment(p)}


def notification_response(n: Notification) -> dict:
    return {"id": n.id, "orderId": n.order_id, "type": n.type, "recipient": n.recipient,
            "createdAt": n.created_at.isoformat().replace("+00:00", "Z")}


def page_response(items: list[dict], next_cursor: str | None) -> dict:
    return {"items": items, "nextCursor": next_cursor}
