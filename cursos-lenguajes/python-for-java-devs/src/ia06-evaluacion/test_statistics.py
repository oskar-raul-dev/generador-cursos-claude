"""Pruebas de los tres números que hacen honesta la evaluación.

Sin red, sin modelo, sin base de datos, en milisegundos. Es deliberado: el número que
decide un despliegue tiene que ser el mejor probado del sistema.
"""

from __future__ import annotations

import pytest

from statistics_helpers import (
    cohen_kappa,
    raw_agreement,
    required_sample_size,
    wilson_interval,
)


def test_perfect_agreement_with_varied_labels() -> None:
    labels = ["correcta", "incorrecta", "incompleta", "correcta"]
    assert raw_agreement(labels, labels) == 1.0
    assert cohen_kappa(labels, labels) == pytest.approx(1.0)


def test_lazy_judge_has_high_agreement_and_zero_kappa() -> None:
    """La trampa de la sección 4, en una prueba.

    Un juez que dice "correcta" siempre acierta el 90% cuando el 90% lo es, y no aporta
    absolutamente nada. El acuerdo bruto lo premia; el kappa lo desenmascara.
    """
    humano = ["correcta"] * 9 + ["incorrecta"]
    juez_perezoso = ["correcta"] * 10

    assert raw_agreement(humano, juez_perezoso) == pytest.approx(0.9)
    assert cohen_kappa(humano, juez_perezoso) == pytest.approx(0.0, abs=1e-9)


def test_kappa_is_negative_when_worse_than_chance() -> None:
    a = ["correcta", "correcta", "incorrecta", "incorrecta"]
    b = ["incorrecta", "incorrecta", "correcta", "correcta"]
    assert cohen_kappa(a, b) < 0


def test_kappa_in_the_usable_band() -> None:
    """Un juez que se equivoca en dos de diez, con reparto real de etiquetas."""
    humano = ["correcta"] * 6 + ["incorrecta"] * 2 + ["incompleta"] * 2
    juez = ["correcta"] * 5 + ["incompleta"] + ["incorrecta"] * 2 + ["incompleta", "correcta"]
    kappa = cohen_kappa(humano, juez)
    assert 0.4 < kappa < 0.8


def test_agreement_rejects_mismatched_lengths() -> None:
    with pytest.raises(ValueError):
        raw_agreement(["correcta"], ["correcta", "incorrecta"])


def test_wilson_matches_the_number_quoted_in_the_lesson() -> None:
    """16 de 20 es 0.80, y el intervalo va de 0.58 a 0.92. La lección cita estos números."""
    low, high = wilson_interval(16, 20)
    assert low == pytest.approx(0.584, abs=0.005)
    assert high == pytest.approx(0.918, abs=0.005)


def test_same_proportion_narrows_with_more_samples() -> None:
    """Los tres son 0.80 y no dicen lo mismo. Es el ejercicio 3."""
    widths = [
        wilson_interval(s, n)[1] - wilson_interval(s, n)[0]
        for s, n in ((16, 20), (80, 100), (800, 1000))
    ]
    assert widths[0] > widths[1] > widths[2]


def test_wilson_stays_inside_the_unit_interval_at_the_extremes() -> None:
    """Donde el intervalo normal de los apuntes se sale de [0, 1] y miente."""
    assert wilson_interval(20, 20) == (pytest.approx(0.839, abs=0.005), 1.0)
    assert wilson_interval(0, 20)[0] == 0.0


def test_no_trials_is_not_a_division_by_zero() -> None:
    assert wilson_interval(0, 0) == (0.0, 0.0)


def test_detecting_small_improvements_needs_many_more_cases() -> None:
    """El número incómodo: cinco puntos sobre 0.80 no se detectan con cincuenta casos."""
    for_five_points = required_sample_size(0.80, 0.05)
    for_fifteen_points = required_sample_size(0.80, 0.15)
    assert for_five_points > 300
    assert for_fifteen_points < for_five_points / 8


@pytest.mark.parametrize("baseline, improvement", [(0.95, 0.10), (0.80, 0.20), (0.80, 0.0)])
def test_required_sample_size_rejects_impossible_targets(
    baseline: float, improvement: float
) -> None:
    """Mejorar hasta 1.0 exacto no es una hipótesis que esta aproximación pueda contestar,
    y fallar es mejor que devolver un número que alguien va a citar."""
    with pytest.raises(ValueError):
        required_sample_size(baseline, improvement)
