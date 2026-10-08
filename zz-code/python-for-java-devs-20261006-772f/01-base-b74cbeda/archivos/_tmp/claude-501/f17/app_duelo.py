"""El endpoint del duelo: solo disponibilidad, igual que el de Java."""

from datetime import date, datetime, time, timedelta, timezone
from enum import StrEnum

from fastapi import FastAPI
from pydantic import BaseModel

BOGOTA = timezone(timedelta(hours=-5))


class Branch(StrEnum):
    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"


class Slot(BaseModel):
    starts_at: datetime
    minutes: int


class AvailabilityResponse(BaseModel):
    branch: Branch
    day: date
    slots: list[Slot]


app = FastAPI()


@app.get("/availability", response_model=AvailabilityResponse)
def availability(branch: Branch, day: date) -> AvailabilityResponse:
    slots = [
        Slot(starts_at=datetime.combine(day, time(hour, minute), BOGOTA), minutes=20)
        for hour in range(7, 19)
        for minute in (0, 20, 40)
    ]
    return AvailabilityResponse(branch=branch, day=day, slots=slots)
