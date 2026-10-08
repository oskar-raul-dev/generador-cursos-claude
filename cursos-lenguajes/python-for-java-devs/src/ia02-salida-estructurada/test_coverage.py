"""Pruebas del contrato. No tocan la red: validan lo que el esquema garantiza y lo que no."""

from datetime import date
from decimal import Decimal

import pytest
from pydantic import ValidationError

from coverage import CircularExtraction, CoverageRule
from extract import _normalize

VALID = {
    "insurer_nit": "830003564",
    "procedure_code": "992102",
    "covered": "no",
    "copayment_cop": "45000",
    "valid_from": "2026-10-01",
    "quote": "el retiro de aparatología no está cubierto en el plan complementario",
}


def test_copayment_becomes_decimal() -> None:
    rule = CoverageRule.model_validate(VALID)
    assert rule.copayment() == Decimal("45000")
    assert rule.valid_from == date(2026, 10, 1)


@pytest.mark.parametrize("bad", ["45.000", "$45000", "45 000", "cuarenta y cinco mil"])
def test_copayment_rejects_formatted_money(bad: str) -> None:
    """El modelo devuelve dinero con formato humano; el contrato lo rechaza y reintenta."""
    with pytest.raises(ValidationError):
        CoverageRule.model_validate({**VALID, "copayment_cop": bad})


def test_unknown_field_is_rejected() -> None:
    """extra=forbid convierte una invención silenciosa en un error reintentable."""
    with pytest.raises(ValidationError):
        CoverageRule.model_validate({**VALID, "observaciones": "según lo hablado"})


def test_no_dice_is_a_first_class_value() -> None:
    """El caso que un bool no puede representar, y por el que existe esta sección."""
    rule = CoverageRule.model_validate({**VALID, "covered": "no_dice", "copayment_cop": None})
    assert rule.covered == "no_dice"
    assert rule.copayment() is None


def test_short_quote_is_rejected() -> None:
    with pytest.raises(ValidationError):
        CoverageRule.model_validate({**VALID, "quote": "no cubre"})


def test_empty_rule_list_is_valid() -> None:
    """Una circular administrativa no trae reglas, y eso no es un fallo."""
    extraction = CircularExtraction.model_validate({"insurer_name": "Seguros Andina", "rules": []})
    assert extraction.rules == []


def test_normalize_survives_typographic_quotes_and_hard_spaces() -> None:
    """La razón por la que la verificación de citas funciona sobre PDF reales."""
    source = _normalize("El plan \u201ccomplementario\u201d no\u00a0cubre el retiro.")
    quoted = _normalize('El plan "complementario" no cubre el retiro.')
    assert quoted in source
