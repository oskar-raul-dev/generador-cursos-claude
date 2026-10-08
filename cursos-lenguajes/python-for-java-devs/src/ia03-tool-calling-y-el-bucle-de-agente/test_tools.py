"""Pruebas de las herramientas. Sin red y sin modelo.

Es el 90% del agente que se puede probar sin la API, y el criterio 7 del miniproyecto
en pequeño: si estas pruebas no pasan, el problema nunca fue del modelo.
"""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

from agenda_client import seeded_agenda
from tools import BOGOTA, find_availability, get_treatment_price, idempotency_key, propose_booking

THURSDAY = "2026-09-17"
SLOT_340 = f"{THURSDAY}T15:40"


def test_availability_lists_slots_in_order() -> None:
    agenda = seeded_agenda()
    assert "15:00, 15:40, 16:20" in find_availability(agenda, "SUB", THURSDAY, 20)


def test_branch_without_digital_agenda_says_so() -> None:
    """Una lista vacía se lee como 'no hay cupo'. Zipaquirá necesita decir otra cosa."""
    result = find_availability(seeded_agenda(), "ZIP", THURSDAY, 20)
    assert "no tiene agenda digital" in result
    assert "llamarla por teléfono" in result


def test_price_is_per_branch() -> None:
    """Las sedes franquiciadas tienen tarifas propias; el precio sin sede sería una mentira."""
    agenda = seeded_agenda()
    assert "180,000" in get_treatment_price(agenda, "992102", "CEN")
    assert "165,000" in get_treatment_price(agenda, "992102", "SUB")


def test_unknown_code_does_not_raise() -> None:
    result = get_treatment_price(seeded_agenda(), "999999", "CEN")
    assert "no está en la lista de precios" in result


def test_same_arguments_return_the_same_proposal() -> None:
    """Idempotencia: dos llamadas iguales son la misma intención, no dos reservas."""
    agenda = seeded_agenda()
    first = propose_booking(agenda, "4471", "SUB", SLOT_340, 20, "control")
    second = propose_booking(agenda, "4471", "SUB", SLOT_340, 20, "control")
    assert first == second
    assert "Propuesta P00001" in first


def test_losing_the_race_is_information_not_an_exception() -> None:
    agenda = seeded_agenda()
    propose_booking(agenda, "4471", "SUB", SLOT_340, 20, "control")
    other = propose_booking(agenda, "9002", "SUB", SLOT_340, 20, "control")
    assert "ya está tomado" in other
    assert "No se apartó nada" in other


def test_concurrent_bookings_produce_exactly_one_proposal() -> None:
    """El hueco de las 3:40, en pequeño: seis hilos, un ganador."""
    agenda = seeded_agenda()

    def attempt(patient: int) -> str:
        return propose_booking(agenda, f"p{patient}", "SUB", SLOT_340, 20, "control")

    with ThreadPoolExecutor(max_workers=6) as pool:
        results = list(pool.map(attempt, range(6)))

    granted = [r for r in results if "Propuesta" in r]
    rejected = [r for r in results if "ya está tomado" in r]
    assert len(granted) == 1
    assert len(rejected) == 5


def test_expired_proposal_frees_the_slot() -> None:
    """El vencimiento se prueba moviendo el reloj, no esperando quince minutos."""
    agenda = seeded_agenda()
    now = datetime(2026, 9, 17, 10, 0, tzinfo=BOGOTA)
    propose_booking(agenda, "4471", "SUB", SLOT_340, 20, "control", now=now)

    assert "15:40" not in find_availability(agenda, "SUB", THURSDAY, 20)
    assert agenda.release_expired(now=now + timedelta(minutes=16)) == 1
    assert "15:40" in find_availability(agenda, "SUB", THURSDAY, 20)


def test_idempotency_key_is_derived_not_random() -> None:
    a = idempotency_key("4471", "SUB", SLOT_340)
    b = idempotency_key("4471", "SUB", SLOT_340)
    c = idempotency_key("4471", "CEN", SLOT_340)
    assert a == b
    assert a != c
