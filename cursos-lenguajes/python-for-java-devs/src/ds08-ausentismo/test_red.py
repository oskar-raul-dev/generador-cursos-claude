"""Pruebas de la red, la calibración y la decisión de sobreagendar.

    uv run --with torch==2.14.0 --with scikit-learn==1.9.1 --with pytest pytest -q

Las de calibración y sobreagendamiento corren **sin torch y sin sklearn**: son aritmética, y
son justamente las que deciden plata. Las que entrenan se saltan solas si no hay torch.

La prueba que sostiene la sección es `test_una_columna_a_mano_alcanza_a_la_red`: si dejara de
ser cierta, el veredicto se reescribe alrededor del resultado nuevo.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

from calibration import brier_score, expected_calibration_error, reliability
from overbooking import break_even, decide, expected_gain, realised_cost
from shared import (
    DS07,
    build_matrix,
    cutoff_of,
    fit_logistic,
    load_rows,
    roc_auc,
    score_rows,
    split_temporal,
    three_variable_rule,
)

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("ausentismo")
    subprocess.run([sys.executable, str(DS07 / "generar_ausentismo.py"),
                    "--salida", str(out), "--pacientes", "6000"],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def split(data: Path):
    return split_temporal(load_rows(data), cutoff_of(data))


# --- La calibración es aritmética -----------------------------------------------------

def test_el_brier_en_los_casos_que_lo_definen():
    assert brier_score([1.0, 0.0], [1, 0]) == pytest.approx(0.0)
    assert brier_score([0.5, 0.5], [1, 0]) == pytest.approx(0.25)
    assert brier_score([0.0, 1.0], [1, 0]) == pytest.approx(1.0)


def test_un_modelo_perfectamente_calibrado_tiene_ece_cero():
    """Cien casos con probabilidad 0,3 de los que fallan treinta: eso es calibración."""
    scores = [0.3] * 100
    target = [1] * 30 + [0] * 70
    assert expected_calibration_error(scores, target, bins=1) == pytest.approx(0.0)


def test_la_fiabilidad_reparte_los_casos_en_bloques_iguales():
    scores = [index / 100 for index in range(100)]
    target = [index % 2 for index in range(100)]
    rows = reliability(scores, target, bins=10)
    assert len(rows) == 10
    assert {count for _, _, count in rows} == {10}


def test_discriminar_y_calibrar_son_cosas_distintas():
    """Dividir todas las probabilidades entre dos no cambia el orden —ni el AUC— y arruina
    la calibración. Es la razón de que las dos métricas vayan juntas."""
    scores = [0.8, 0.6, 0.4, 0.2]
    target = [1, 1, 0, 0]
    halved = [score / 2 for score in scores]
    assert roc_auc(halved, target) == roc_auc(scores, target)
    assert brier_score(halved, target) > brier_score(scores, target)


# --- La decisión de sobreagendar ------------------------------------------------------

def test_el_punto_de_equilibrio_sale_de_la_asimetria():
    """Con una colisión tres veces peor que una silla vacía, hay que fallar tres de cada
    cuatro veces para que sobreagendar no destruya valor."""
    assert break_even(3.0) == pytest.approx(0.75)
    assert break_even(1.0) == pytest.approx(0.5)
    assert expected_gain(0.75, 3.0) == pytest.approx(0.0)
    assert expected_gain(0.80, 3.0) > 0


def test_cuanto_peor_la_colision_menos_se_sobreagenda():
    probabilities = [index / 100 for index in range(100)]
    assert sum(decide(probabilities, 1.0)) > sum(decide(probabilities, 3.0))


def test_la_regla_mal_calibrada_pierde_plata_al_decidir(split):
    """El hallazgo operativo de la sección: la regla ordena decentemente y **decide
    pésimo**, porque su puntaje no es una probabilidad. Con la asimetría de Áurea, pasa de
    recuperar consultas a perderlas."""
    _, test = split
    _, target = build_matrix(test)
    never = -sum(target)

    rule = three_variable_rule(test)
    assert realised_cost(rule, decide(rule, 3.0), target, 3.0) - never < 0


def test_el_modelo_bien_calibrado_si_gana_al_sobreagendar(split):
    train, test = split
    _, target = build_matrix(test)
    never = -sum(target)
    scores = score_rows(fit_logistic(train), test)
    assert realised_cost(scores, decide(scores, 3.0), target, 3.0) - never > 0


def test_la_regla_esta_mal_calibrada_y_la_logistica_no(split):
    train, test = split
    _, target = build_matrix(test)
    assert expected_calibration_error(three_variable_rule(test), target) > 0.10
    assert expected_calibration_error(score_rows(fit_logistic(train), test), target) < 0.03


# --- La red ---------------------------------------------------------------------------

@pytest.fixture(scope="module")
def trained(split):
    pytest.importorskip("torch")
    from net import train_network

    train, _ = split
    return train_network(train)


def test_la_red_es_determinista(split, trained):
    """Dos entrenamientos con la misma semilla dan los mismos puntajes. Sin esto, la tabla
    de la sección 6 no se puede reproducir y la comparación con la logística —que es
    determinista— sería injusta."""
    from net import score_network, train_network

    train, test = split
    network, scaler, _ = trained
    other, other_scaler, _ = train_network(train)
    first = score_network(network, scaler, test[:500])
    second = score_network(other, other_scaler, test[:500])
    assert first == pytest.approx(second)


def test_la_red_para_antes_de_agotar_las_epocas(trained):
    """El criterio de parada existe: si corriera las 60 épocas, estaría sobreajustando y el
    número que se reporta sería el de una red peor."""
    from net import EPOCHS

    _, _, report = trained
    assert report.best_epoch < report.epochs_run <= EPOCHS


def test_la_red_le_gana_a_la_logistica_por_poco(split, trained):
    from net import score_network

    train, test = split
    _, target = build_matrix(test)
    network, scaler, _ = trained
    advantage = (roc_auc(score_network(network, scaler, test), target)
                 - roc_auc(score_rows(fit_logistic(train), test), target))
    assert 0.0 < advantage < 0.05


def test_una_columna_a_mano_alcanza_a_la_red(split, trained):
    """**La tesis de la sección.** El generador tiene una sola interacción —lluvia por
    distancia— y es todo lo que la red encuentra de más. Escrita a mano en una línea, la
    logística llega al mismo sitio."""
    from engineered import fit_with_interaction, score_with_interaction
    from net import score_network

    train, test = split
    _, target = build_matrix(test)
    network, scaler, _ = trained

    network_auc = roc_auc(score_network(network, scaler, test), target)
    interaction_auc = roc_auc(
        score_with_interaction(fit_with_interaction(train), test), target)
    assert interaction_auc == pytest.approx(network_auc, abs=0.01)


def test_la_columna_de_interaccion_es_el_producto(split):
    from engineered import WITH_INTERACTION, build_with_interaction
    from shared import HONEST

    train, _ = split
    matrix, _ = build_with_interaction(train[:100])
    rain, distance = HONEST.index("lluvia_mm"), HONEST.index("distancia_km")
    assert len(WITH_INTERACTION) == len(HONEST) + 1
    for row in matrix:
        assert row[-1] == pytest.approx(row[rain] * row[distance])
