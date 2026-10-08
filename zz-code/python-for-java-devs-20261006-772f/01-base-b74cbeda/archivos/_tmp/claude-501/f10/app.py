"""AgendaAPI — la agenda de la red Áurea. Fase 10: validar en la frontera."""

from datetime import date, datetime, time, timedelta, timezone
from enum import StrEnum
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

BOGOTA = timezone(timedelta(hours=-5))

class Branch(StrEnum):
    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"

class PhaseKind(StrEnum):
    DIAGNOSIS = "diagnosis"
    ORTHODONTIC = "orthodontic"
    PERIODONTAL = "periodontal"
    RESTORATIVE = "restorative"
    RETENTION = "retention"

PHASE_MINUTES = {PhaseKind.DIAGNOSIS: 60, PhaseKind.ORTHODONTIC: 20,
                 PhaseKind.PERIODONTAL: 45, PhaseKind.RESTORATIVE: 90,
                 PhaseKind.RETENTION: 20}

class Slot(BaseModel):
    starts_at: datetime
    minutes: int

class AvailabilityResponse(BaseModel):
    branch: Branch
    day: date
    slots: list[Slot]

class BookingRequest(BaseModel):
    """El modelo de ENTRADA. Valida forma, no reglas de negocio."""
    patient_document: str = Field(min_length=6, max_length=12, pattern=r"^\d+$")
    branch: Branch
    phase: PhaseKind
    starts_at: datetime

    @field_validator("starts_at")
    @classmethod
    def must_be_timezone_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("la fecha debe traer zona horaria explícita")
        return value

class BookingResponse(BaseModel):
    booking_id: str
    branch: Branch
    starts_at: datetime
    minutes: int

app = FastAPI(title="AgendaAPI")

def build_slots(day: date, branch: Branch) -> list[Slot]:
    slots = []
    for hour in range(7, 19):
        for minute in (0, 20, 40):
            slots.append(Slot(starts_at=datetime.combine(day, time(hour, minute), BOGOTA), minutes=20))
    return slots

@app.get("/availability", response_model=AvailabilityResponse)
def availability(branch: Branch, day: date) -> AvailabilityResponse:
    return AvailabilityResponse(branch=branch, day=day, slots=build_slots(day, branch))

@app.post("/bookings", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def book(request: BookingRequest) -> BookingResponse:
    if request.starts_at < datetime.now(BOGOTA):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "la cita no puede ser en el pasado")
    return BookingResponse(booking_id="b-0001", branch=request.branch,
                           starts_at=request.starts_at, minutes=PHASE_MINUTES[request.phase])

@app.get("/availability-raw")
def availability_raw(branch: str, day: str) -> dict:
    """La misma respuesta SIN modelo de salida: para medir qué cuesta validar."""
    d = date.fromisoformat(day)
    return {"branch": branch, "day": day,
            "slots": [{"starts_at": datetime.combine(d, time(h, m), BOGOTA).isoformat(), "minutes": 20}
                      for h in range(7, 19) for m in (0, 20, 40)]}
