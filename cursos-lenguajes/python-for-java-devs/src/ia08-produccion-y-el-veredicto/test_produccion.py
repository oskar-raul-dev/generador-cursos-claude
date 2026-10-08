"""Pruebas del auditor de prefijo y del presupuesto. Sin red y sin modelo.

Las dos piezas de esta sección que deciden dinero, y por eso son las dos que se prueban:
el auditor dice por qué la caché dejó de acertar, y el presupuesto impide que la factura
se dispare. Ninguna de las dos necesita la API para demostrar que funciona.
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal

import pytest

from audit_prefix import first_divergence, render_prefix
from budget import BudgetExceeded, DailyBudget

SYSTEM = "Contestas preguntas sobre coberturas usando solo los fragmentos que te paso."
TOOL = {"name": "find_availability", "description": "Consulta la agenda."}


def request(system: str = SYSTEM, tools: list[dict] | None = None) -> dict:
    return {"system": system, "tools": tools or [TOOL]}


# --- Los cuatro invalidadores silenciosos --------------------------------------------


def test_identical_requests_share_the_whole_prefix() -> None:
    divergence = first_divergence(request(), request())
    assert divergence.identical
    assert "debería acertar" in divergence.explain()


def test_the_clock_breaks_the_prefix() -> None:
    """El invalidador ① y el más frecuente: el modelo necesita saber qué día es."""
    divergence = first_divergence(
        request(f"Hoy es 2026-09-13 10:00. {SYSTEM}"),
        request(f"Hoy es 2026-09-13 10:05. {SYSTEM}"),
    )
    assert not divergence.identical
    assert not divergence.truncation


def test_the_session_id_breaks_the_prefix() -> None:
    divergence = first_divergence(
        request(f"{SYSTEM}\nSesión: 8f3a-1"), request(f"{SYSTEM}\nSesión: 8f3a-2")
    )
    assert not divergence.identical


def test_unordered_json_breaks_the_prefix() -> None:
    """El invalidador ③: un dict serializado sin ordenar claves entre peticiones."""
    divergence = first_divergence(
        request(f'{SYSTEM}\n{{"andina": 1, "altamira": 2}}'),
        request(f'{SYSTEM}\n{{"altamira": 2, "andina": 1}}'),
    )
    assert not divergence.identical


def test_tool_order_breaks_the_prefix() -> None:
    """El invalidador ④: `list(registry.values())` no garantiza orden entre procesos."""
    other = {"name": "get_treatment_price", "description": "Precio de lista."}
    divergence = first_divergence(request(tools=[TOOL, other]), request(tools=[other, TOOL]))
    assert not divergence.identical
    assert "find_availability" in divergence.before or "get_treatment_price" in divergence.after


def test_tools_render_before_system() -> None:
    """El orden de renderizado es contrato: tools → system.

    Auditar en otro orden señala al culpable equivocado con toda la confianza del mundo.
    """
    rendered = render_prefix(request())
    assert rendered.index("find_availability") < rendered.index("Contestas")


def test_a_longer_prefix_is_truncation_not_divergence() -> None:
    """El caso benigno: el corto se cachea entero. Distinguirlo evita buscar un bug falso."""
    divergence = first_divergence(request(), request(SYSTEM + "\nY además citas la cláusula."))
    assert not divergence.identical
    assert divergence.truncation
    assert "no rompe la caché" in divergence.explain()


def test_divergence_shows_both_sides_with_context() -> None:
    """El explain() se pega en un incidente: tiene que decir qué había a cada lado."""
    divergence = first_divergence(request(SYSTEM + " Versión A."), request(SYSTEM + " Versión B."))
    assert "petición A" in divergence.explain()
    assert "petición B" in divergence.explain()


# --- El presupuesto -------------------------------------------------------------------


def budget(per_key: str = "0.50", total: str = "5.00") -> DailyBudget:
    return DailyBudget(
        limit_per_key=Decimal(per_key), limit_total=Decimal(total), day=date(2026, 9, 13)
    )


def test_a_fresh_budget_allows_spending() -> None:
    budget().check("4471", Decimal("0.01"))


def test_the_per_key_limit_cuts() -> None:
    """El paciente ansioso de las once de la noche."""
    daily = budget()
    for _ in range(50):
        daily.record("4471", Decimal("0.01"))

    with pytest.raises(BudgetExceeded) as error:
        daily.check("4471", Decimal("0.01"))
    assert "tope por clave" in str(error.value)


def test_other_keys_keep_working_when_one_is_exhausted() -> None:
    """Cortar a uno no puede dejar sin servicio a los otros nueve."""
    daily = budget()
    daily.record("4471", Decimal("0.50"))

    with pytest.raises(BudgetExceeded):
        daily.check("4471", Decimal("0.01"))
    daily.check("9002", Decimal("0.01"))  # no lanza


def test_the_global_limit_cuts_even_with_room_per_key() -> None:
    daily = budget(per_key="10.00", total="1.00")
    daily.record("CEN", Decimal("0.99"))

    with pytest.raises(BudgetExceeded) as error:
        daily.check("SUB", Decimal("0.02"))
    assert "gasto del día" in str(error.value)


def test_checking_uses_the_estimate_not_the_actual_cost() -> None:
    """Comprobar antes con el peor caso es lo que previene el gasto.

    Un presupuesto que comprueba con el costo real solo se entera de que se pasó cuando
    ya se pasó. Aquí la petición de 0.20 se rechaza porque PODRÍA costar eso, aunque
    probablemente cueste mucho menos.
    """
    daily = budget(per_key="0.25")
    daily.record("4471", Decimal("0.10"))

    with pytest.raises(BudgetExceeded):
        daily.check("4471", Decimal("0.20"))


def test_money_is_decimal_and_the_sum_does_not_drift() -> None:
    """Diez mil peticiones de tres milésimas son exactamente treinta dólares.

    En float da 30.000000000001023, y el error crece con el volumen. Es la regla de la
    guía §6.6, y aquí es la diferencia entre cuadrar con la factura del proveedor dentro
    del 5% —criterio 2 del miniproyecto— y no cuadrar.
    """
    daily = budget(per_key="100", total="1000")
    for _ in range(10_000):
        daily.record("CEN", Decimal("0.003"))
    assert daily.total() == Decimal("30.000")


def test_the_report_shows_the_top_spenders() -> None:
    daily = budget(per_key="100", total="1000")
    daily.record("CEN", Decimal("1.00"))
    daily.record("SUB", Decimal("3.00"))
    assert daily.report().splitlines()[1].strip().startswith("SUB")


# --- La frontera de lo que se registra ------------------------------------------------


def evento(**overrides: object):
    """Construye un `Event` de telemetry. Sin anotación de retorno a propósito: el tipo se
    importa dentro para que este archivo se pueda leer sin el módulo instalado."""
    from datetime import datetime

    from telemetry import BOGOTA, Event, fingerprint

    base = dict(
        thread_id="t1",
        branch="CEN",
        at=datetime(2026, 9, 13, 10, 0, tzinfo=BOGOTA),
        project="recepcion",
        model="claude-opus-5",
        prompt_version="v3",
        message_hash=fingerprint("se me soltó un bracket y me duele"),
        classification="sintoma",
        escalated=True,
        escalation_reason="sintoma",
        abstained=False,
        cost_usd="0.004620",
    )
    return Event(**{**base, **overrides})  # type: ignore[arg-type]


def test_the_patient_text_never_reaches_the_log() -> None:
    """La frontera de la sección 4, comprobada sobre el registro serializado."""
    texto = "se me soltó un bracket y me duele"
    linea = evento().to_log()

    assert texto not in linea
    assert "soltó" not in linea
    # Lo que sí está: la huella y la clasificación, que es con lo que se mide.
    assert "sintoma" in linea


def test_the_same_message_gives_the_same_fingerprint() -> None:
    """Permite contar repeticiones sin guardar el texto."""
    from telemetry import fingerprint

    assert fingerprint("hola") == fingerprint("hola")
    assert fingerprint("hola") != fingerprint("holá")


def test_the_blocked_draft_is_kept_on_purpose() -> None:
    """Texto que generó el modelo y que el sistema impidió enviar: se guarda y se dice."""
    linea = evento(blocked_draft="Tómate un ibuprofeno").to_log()
    assert "ibuprofeno" in linea


def test_retention_selects_what_has_to_be_deleted() -> None:
    from datetime import datetime

    from telemetry import BOGOTA, expired

    viejo = evento(at=datetime(2026, 1, 1, 9, 0, tzinfo=BOGOTA))
    reciente = evento(at=datetime(2026, 9, 1, 9, 0, tzinfo=BOGOTA))

    a_borrar = expired([viejo, reciente], today=date(2026, 9, 13))
    assert a_borrar == [viejo]


def test_the_summary_puts_abstention_and_escalation_up_front() -> None:
    from telemetry import monthly_summary

    resumen = monthly_summary([evento(), evento(escalated=False, abstained=True)])
    assert resumen["tasa_escalamiento"] == 0.5
    assert resumen["tasa_abstencion"] == 0.5
    assert resumen["cache_activa"] is False  # y por eso hay que auditar el prefijo
