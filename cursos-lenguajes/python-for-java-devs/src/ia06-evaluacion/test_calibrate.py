"""Pruebas del calibrador del umbral. Pura aritmética sobre distancias anotadas.

Es la deuda 💸 de ia04 pagada, y se prueba sin Postgres: `choose_threshold` no sabe de
dónde salieron las distancias.
"""

from __future__ import annotations

import pytest

from calibrate import choose_threshold


def test_separable_case_cuts_between_the_two_clouds() -> None:
    """Aciertos cerca, fallos lejos: el corte cae en el borde de los aciertos."""
    report = choose_threshold([0.10, 0.15, 0.20], [0.70, 0.80, 0.90])
    assert report.threshold == pytest.approx(0.20)
    assert report.recall_kept == 1.0
    assert report.noise_removed == 1.0


def test_priority_is_not_losing_hits() -> None:
    """El criterio es asimétrico a propósito: perder un acierto cuesta más que colar ruido.

    Con un acierto lejano (0.60), un corte en 0.30 eliminaría más ruido pero perdería
    ese acierto. Con min_recall=0.95 sobre cuatro aciertos no se puede perder ninguno.
    """
    report = choose_threshold([0.10, 0.12, 0.15, 0.60], [0.30, 0.35, 0.95])
    assert report.threshold >= 0.60
    assert report.recall_kept == 1.0


def test_relaxing_min_recall_allows_a_stricter_cut() -> None:
    report = choose_threshold([0.10, 0.12, 0.15, 0.60], [0.30, 0.35, 0.95], min_recall=0.75)
    assert report.threshold < 0.60
    assert report.recall_kept == pytest.approx(0.75)
    assert report.noise_removed > 0.5


def test_overlapping_clouds_are_reported_not_hidden() -> None:
    """Cuando las dos nubes se solapan del todo, el umbral no salva nada y hay que verlo."""
    report = choose_threshold([0.30, 0.40, 0.50], [0.30, 0.40, 0.50])
    assert report.recall_kept == 1.0
    assert report.noise_removed == 0.0  # ningún corte que conserve aciertos elimina ruido


def test_without_annotated_hits_it_refuses_to_calibrate() -> None:
    with pytest.raises(ValueError):
        choose_threshold([], [0.5, 0.6])


def test_no_misses_is_not_a_division_by_zero() -> None:
    report = choose_threshold([0.10, 0.20], [])
    assert report.noise_removed == 0.0
    assert report.recall_kept == 1.0
