"""Las herramientas que el agente puede usar sobre la agenda de la red.

Tres, y ninguna más. La tentación de exponer "todo lo que la API sabe hacer" produce
agentes que eligen mal: cada herramienta que agregas es una decisión más que le pides
al modelo, y las decisiones se equivocan.

Regla de la sección: SOLO `propose_booking` toca el estado, y lo toca de forma
provisional. Las otras dos son de lectura.
"""

from __future__ import annotations

import hashlib
from datetime import date, datetime, timedelta
from decimal import Decimal

# La zona se importa de la frontera en vez de redeclararse: dos definiciones de "Bogotá"
# en dos módulos es cómo se cuela un naive donde se esperaba un aware.
from agenda_client import BOGOTA, AgendaClient, SlotTaken

# Las diez sedes de la red. Van como enum en el esquema para que el modelo no tenga
# que adivinar el formato ni gastar un turno preguntándolo.
BRANCH_CODES = ("CEN", "CHA", "SUB", "KEN", "USA", "ENG", "FON", "RES", "SOA", "ZIP")

# Zipaquirá lleva la agenda en un cuaderno de pasta dura. No es una broma del dominio:
# es una sede real de la red y el modelo tiene que saber que consultarla no sirve.
BRANCHES_WITHOUT_DIGITAL_AGENDA = frozenset({"ZIP"})

HOLD_MINUTES = 15


TOOL_DEFINITIONS = [
    {
        "name": "find_availability",
        "description": (
            "Devuelve los espacios libres de una sede en un día, en orden cronológico. "
            "Solo consulta la agenda: no reserva nada. Devuelve una lista vacía si no hay "
            "espacios, y también si la sede no tiene agenda digital (Zipaquirá) — en ese "
            "segundo caso el texto lo dice, y hay que pedirle a la persona que llame a la sede."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "branch": {
                    "type": "string",
                    "enum": list(BRANCH_CODES),
                    "description": "Código de tres letras de la sede.",
                },
                "day": {
                    "type": "string",
                    "format": "date",
                    "description": "Fecha en formato AAAA-MM-DD, zona horaria de Bogotá.",
                },
                "minutes": {
                    "type": "integer",
                    "enum": [20, 30, 45, 60],
                    "description": "Duración necesaria. Un control de ortodoncia son 20 minutos.",
                },
            },
            "required": ["branch", "day", "minutes"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "name": "get_treatment_price",
        "description": (
            "Precio de lista de un procedimiento en una sede, en pesos colombianos. "
            "Las sedes franquiciadas tienen tarifas propias, así que la sede es obligatoria. "
            "No aplica descuentos, ni cobertura de prepagada, ni el precio pactado de un plan "
            "ya firmado: para eso hay que mirar el plan del paciente."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "procedure_code": {"type": "string", "description": "Código del manual tarifario."},
                "branch": {"type": "string", "enum": list(BRANCH_CODES)},
            },
            "required": ["procedure_code", "branch"],
            "additionalProperties": False,
        },
        "strict": True,
    },
    {
        "name": "propose_booking",
        "description": (
            "Aparta un espacio de forma PROVISIONAL durante 15 minutos y devuelve un código "
            "de propuesta. NO crea la cita: una auxiliar tiene que confirmarla. "
            "Si el espacio ya no está libre, lo dice y no aparta nada — en ese caso hay que "
            "volver a consultar disponibilidad. Llamarla dos veces con los mismos datos "
            "devuelve la misma propuesta, no dos."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "patient_id": {"type": "string", "description": "Identificador del paciente."},
                "branch": {"type": "string", "enum": list(BRANCH_CODES)},
                "starts_at": {
                    "type": "string",
                    "description": "Inicio en formato AAAA-MM-DDTHH:MM, zona horaria de Bogotá.",
                },
                "minutes": {"type": "integer", "enum": [20, 30, 45, 60]},
                "reason": {
                    "type": "string",
                    "description": "Motivo en una línea, para que la auxiliar sepa qué confirma.",
                },
            },
            "required": ["patient_id", "branch", "starts_at", "minutes", "reason"],
            "additionalProperties": False,
        },
        "strict": True,
    },
]


def idempotency_key(patient_id: str, branch: str, starts_at: str) -> str:
    """Clave derivada de los datos, no de un UUID nuevo.

    Es la diferencia entre protegerse de una llamada repetida y no protegerse de nada:
    dos llamadas con los mismos argumentos son la misma intención, y tienen que producir
    una sola reserva. Misma técnica que la Fase 13, mismo motivo.
    """
    material = f"{patient_id}|{branch}|{starts_at}".encode()
    return hashlib.sha256(material).hexdigest()[:32]


def find_availability(agenda: AgendaClient, branch: str, day: str, minutes: int) -> str:
    """Ejecuta la herramienta. Devuelve TEXTO, porque texto es lo que el modelo lee.

    Devolver JSON aquí es un reflejo comprensible y sale peor: el modelo lo lee igual y
    gasta más tokens en las llaves y las comillas que en la información.
    """
    if branch in BRANCHES_WITHOUT_DIGITAL_AGENDA:
        return (
            f"La sede {branch} no tiene agenda digital: hay que llamarla por teléfono. "
            "No hay disponibilidad consultable desde aquí."
        )

    slots = agenda.free_slots(branch=branch, day=date.fromisoformat(day), minutes=minutes)
    if not slots:
        return f"No hay espacios de {minutes} minutos en {branch} el {day}."

    listed = ", ".join(slot.strftime("%H:%M") for slot in slots)
    return f"Espacios libres de {minutes} minutos en {branch} el {day}: {listed}."


def get_treatment_price(agenda: AgendaClient, procedure_code: str, branch: str) -> str:
    price: Decimal | None = agenda.list_price(procedure_code=procedure_code, branch=branch)
    if price is None:
        return (
            f"El código {procedure_code} no está en la lista de precios de {branch}. "
            "Puede ser un código de otro manual o un procedimiento que la sede no presta."
        )
    return f"Precio de lista de {procedure_code} en {branch}: ${price:,.0f} COP."


def propose_booking(
    agenda: AgendaClient,
    patient_id: str,
    branch: str,
    starts_at: str,
    minutes: int,
    reason: str,
    *,
    now: datetime | None = None,
) -> str:
    """La única herramienta que toca estado, y lo toca de forma reversible.

    `now` entra por parámetro para poder probar el vencimiento sin esperar quince
    minutos de verdad. El agente nunca lo pasa: es siempre la hora real.
    """
    start = datetime.fromisoformat(starts_at).replace(tzinfo=BOGOTA)
    key = idempotency_key(patient_id, branch, starts_at)
    reference = now or datetime.now(BOGOTA)

    try:
        proposal = agenda.hold_slot(
            idempotency_key=key,
            patient_id=patient_id,
            branch=branch,
            start=start,
            minutes=minutes,
            reason=reason,
            expires_at=reference + timedelta(minutes=HOLD_MINUTES),
        )
    except SlotTaken:
        # No es una excepción para el bucle: es información para el modelo, que va a
        # volver a consultar disponibilidad. Por eso se devuelve como texto normal.
        return (
            f"El espacio de las {start:%H:%M} en {branch} ya está tomado. "
            "No se apartó nada; hay que consultar disponibilidad de nuevo."
        )

    return (
        f"Propuesta {proposal.code} apartada hasta las {proposal.expires_at:%H:%M}. "
        f"{branch}, {start:%Y-%m-%d %H:%M}, {minutes} minutos. "
        "Falta que una auxiliar la confirme para que sea una cita."
    )
