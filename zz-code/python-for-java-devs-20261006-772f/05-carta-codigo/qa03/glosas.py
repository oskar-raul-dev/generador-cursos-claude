"""Glosas notificadas por la prepagada, y cuáles vencen esta semana."""

import datetime as dt
from decimal import Decimal

import httpx
from pydantic import BaseModel

RESPONSE_BUSINESS_DAYS = 15     # plazo de ejemplo; el real lo fija el contrato con cada aseguradora


class Objection(BaseModel):
    invoice: str
    code: str
    patient_name: str
    amount: Decimal
    notified_on: dt.date


def fetch_objections(client: httpx.Client) -> list[Objection]:
    response = client.get("https://api.prepagada.example/v2/glosas")
    response.raise_for_status()
    return [Objection.model_validate(item) for item in response.json()]


def due_date(notified_on: dt.date, business_days: int = RESPONSE_BUSINESS_DAYS) -> dt.date:
    """Suma días hábiles (lunes a viernes). No descuenta festivos: ver §4."""
    day, remaining = notified_on, business_days
    while remaining:
        day += dt.timedelta(days=1)
        if day.weekday() < 5:
            remaining -= 1
    return day


def due_this_week(objections: list[Objection]) -> list[Objection]:
    today = dt.date.today()                          # el reloj: la prueba lo controla
    week_end = today + dt.timedelta(days=6 - today.weekday())
    return [o for o in objections if today <= due_date(o.notified_on) <= week_end]
