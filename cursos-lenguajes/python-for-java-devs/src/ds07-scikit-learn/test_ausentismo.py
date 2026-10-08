"""Pruebas de la línea base, las variables y el modelo.

    uv run --with scikit-learn==1.9.1 --with pytest pytest test_ausentismo.py -q

Las de las métricas y la regla corren **sin scikit-learn**, y eso no es comodidad: la línea
base no puede depender de la biblioteca contra la que compite. Si `baseline.py` importara
sklearn, la cuarta tabla de la sección 6 —la del costo de mantener— sería mentira.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

from baseline import (
    always_attends,
    precision_recall,
    roc_auc,
    three_variable_rule,
    threshold_for_capacity,
)
from features import (
    HONEST,
    LEAKY,
    PRIOR_CAP,
    build_matrix,
    cutoff_of,
    load_rows,
    split_temporal,
)

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("ausentismo")
    subprocess.run([sys.executable, str(HERE / "generar_ausentismo.py"),
                    "--salida", str(out), "--pacientes", "4000"],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def split(data: Path):
    rows = load_rows(data)
    return split_temporal(rows, cutoff_of(data))


# --- Las métricas, contra casos conocidos --------------------------------------------

def test_el_auc_en_los_tres_casos_que_lo_definen():
    """Separación perfecta, azar y orden invertido. Si estos tres fallan, ninguna cifra de
    la sección 6 significa nada."""
    assert roc_auc([0.9, 0.8, 0.2, 0.1], [1, 1, 0, 0]) == pytest.approx(1.0)
    assert roc_auc([0.1, 0.2, 0.8, 0.9], [1, 1, 0, 0]) == pytest.approx(0.0)
    assert roc_auc([0.5, 0.5, 0.5, 0.5], [1, 1, 0, 0]) == pytest.approx(0.5)


def test_el_auc_promedia_los_empates():
    """La regla de tres variables produce pocos puntajes distintos, así que empata mucho.
    Sin promediar rangos, el empate se resolvería por el orden de la lista y la regla
    saldría mejor o peor según cómo estuviera ordenado el CSV."""
    scores = [0.5, 0.5, 0.5, 0.5]
    assert roc_auc(scores, [1, 0, 1, 0]) == pytest.approx(0.5)
    assert roc_auc(scores, [0, 0, 1, 1]) == pytest.approx(0.5)


def test_el_auc_no_existe_sin_las_dos_clases():
    import math

    assert math.isnan(roc_auc([0.1, 0.2], [0, 0]))


def test_precision_recall_cuenta_lo_que_marca():
    scores = [0.9, 0.8, 0.4, 0.1]
    precision, recall, flagged = precision_recall(scores, [1, 0, 1, 0], 0.5)
    assert flagged == 2
    assert precision == pytest.approx(0.5)
    assert recall == pytest.approx(0.5)


def test_el_umbral_por_capacidad_respeta_la_capacidad():
    scores = [index / 100 for index in range(100)]
    threshold = threshold_for_capacity(scores, 0.10)
    assert sum(score >= threshold for score in scores) <= 11


# --- Las variables y el corte ---------------------------------------------------------

def test_el_objetivo_es_no_asistir(split):
    """`1` es el paciente que faltó. Con el objetivo invertido, "todos asisten" sacaría 81%
    de recall y parecería un modelo."""
    train, _ = split
    _, target = build_matrix(train[:200])
    for row, label in zip(train[:200], target, strict=True):
        assert label == 1 - int(row["asistio"])


def test_el_corte_temporal_no_mezcla_fechas(data: Path, split):
    train, test = split
    cutoff = cutoff_of(data).isoformat()
    assert all(row["fecha"] < cutoff for row in train)
    assert all(row["fecha"] >= cutoff for row in test)
    assert train and test


def test_el_historial_entra_topado(split):
    train, _ = split
    matrix, _ = build_matrix(train)
    column = HONEST.index("inasistencias_previas")
    assert max(row[column] for row in matrix) == PRIOR_CAP
    assert any(int(row["inasistencias_previas"]) > PRIOR_CAP for row in train)


def test_el_jueves_tarde_se_deriva_bien(split):
    train, _ = split
    matrix, _ = build_matrix(train)
    column = HONEST.index("jueves_tarde")
    for row, features in zip(train[:500], matrix[:500], strict=True):
        expected = float(row["dia_semana"] == "3" and row["hora"] >= "16:00")
        assert features[column] == expected


def test_la_columna_con_fuga_no_esta_en_las_honestas():
    assert LEAKY not in HONEST


# --- Las líneas base ------------------------------------------------------------------

def test_siempre_asiste_no_discrimina_nada(split):
    _, test = split
    _, target = build_matrix(test)
    assert roc_auc(always_attends(test), target) == pytest.approx(0.5)


def test_siempre_asiste_acierta_el_ochenta_por_ciento_y_es_inutil(split):
    """La exactitud es la métrica que hay que no usar aquí, y esta prueba es la razón."""
    _, test = split
    _, target = build_matrix(test)
    accuracy = sum(1 - label for label in target) / len(target)
    assert 0.75 < accuracy < 0.85


def test_la_regla_le_gana_al_piso(split):
    _, test = split
    _, target = build_matrix(test)
    assert roc_auc(three_variable_rule(test), target) > 0.6


def test_la_regla_no_alcanza_la_capacidad_por_los_empates(split):
    """Con cuatro puntajes distintos no se puede marcar exactamente el 20%: el umbral cae
    dentro de un bloque de empates y arrastra a todo el bloque. Es una limitación operativa
    de las reglas que ninguna métrica de discriminación muestra."""
    _, test = split
    scores = three_variable_rule(test)
    threshold = threshold_for_capacity(scores, 0.20)
    flagged = sum(score >= threshold for score in scores)
    assert flagged > len(scores) * 0.25


# --- El modelo ------------------------------------------------------------------------

@pytest.fixture(scope="module")
def pipelines(split):
    pytest.importorskip("sklearn")
    from model import fit_logistic

    train, _ = split
    return fit_logistic(train), fit_logistic(train, [*HONEST, LEAKY])


def test_la_logistica_le_gana_a_la_regla(split, pipelines):
    """La tesis de la sección. Si dejara de ser cierta, el capítulo se reescribe alrededor
    del resultado nuevo — que es lo que el curso hace siempre."""
    from model import score_rows

    _, test = split
    _, target = build_matrix(test)
    honest, _ = pipelines
    assert roc_auc(score_rows(honest, test), target) > roc_auc(
        three_variable_rule(test), target) + 0.05


def test_la_fuga_infla_el_auc(split, pipelines):
    from model import score_rows

    _, test = split
    _, target = build_matrix(test)
    honest, leaky = pipelines
    columns = [*HONEST, LEAKY]
    assert roc_auc(score_rows(leaky, test, columns), target) > roc_auc(
        score_rows(honest, test), target) + 0.03


def test_el_escalado_vive_dentro_del_pipeline(pipelines):
    """Si la media y la desviación se calcularan sobre el conjunto completo antes de partir,
    el entrenamiento habría visto la prueba. El `Pipeline` existe para eso."""
    honest, _ = pipelines
    assert "escala" in honest.named_steps
    assert hasattr(honest.named_steps["escala"], "mean_")


def test_predict_marca_la_mitad_de_lo_que_deberia(split, pipelines):
    """`predict` decide con un umbral de 0,5 que nadie eligió. Con una clase positiva del
    20%, marca alrededor del 10%: la mitad de los que faltan no aparecen, y el número no lo
    decidió nadie. Por eso el código usa `predict_proba` y elige el umbral por capacidad."""
    _, test = split
    honest, _ = pipelines
    matrix, target = build_matrix(test)
    marked = sum(honest.predict(matrix)) / len(test)
    rate = sum(target) / len(target)
    assert marked < rate * 0.7


def test_los_coeficientes_apuntan_al_mismo_lado(pipelines):
    """Todas las variables suben el riesgo de faltar: más inasistencias previas, jueves
    tarde, más lluvia, más distancia y más días de anticipación. Un signo negativo aquí
    sería una señal de que algo se construyó al revés."""
    from model import coefficients

    honest, _ = pipelines
    assert all(weight > 0 for weight in coefficients(honest).values())
