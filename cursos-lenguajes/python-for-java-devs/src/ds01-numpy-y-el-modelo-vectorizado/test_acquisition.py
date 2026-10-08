"""Pruebas del cálculo de costo por paciente adquirido.

    uv run --with numpy==2.5.3 pytest test_acquisition.py

La prueba que sostiene la sección 6 es la primera: **las tres versiones devuelven lo
mismo**. Sin ella, la tabla de tiempos compara tres programas distintos y no significa nada.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
import pytest

from acquisition import (
    arrays_from_rows,
    cost_per_acquisition_comprehension,
    cost_per_acquisition_loop,
    cost_per_acquisition_vectorized,
    read_acquisitions,
    read_spend_arrays,
    read_spend_rows,
    total_spend_with_dtype,
)

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("embudo")
    subprocess.run([sys.executable, str(HERE / "generar_embudo.py"), "--salida", str(out)],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def pieces(data: Path):
    rows = read_spend_rows(data / "pauta.csv")
    return (rows, arrays_from_rows(rows),
            read_acquisitions(data / "leads.csv", data / "etapas.csv"))


# --- La igualdad que hace legítima la medición -------------------------------------

def test_las_tres_versiones_dan_la_misma_respuesta(pieces):
    rows, spend, acquisitions = pieces
    loop = cost_per_acquisition_loop(rows, acquisitions)
    comprehension = cost_per_acquisition_comprehension(rows, acquisitions)
    vector = cost_per_acquisition_vectorized(spend, acquisitions)

    assert set(loop) == set(comprehension) == set(vector)
    for channel, value in loop.items():
        # Tolerancia relativa, no igualdad exacta: el bucle acumula en `int` de Python y el
        # vectorizado en `float64`. Exigir bit a bit sería exigir que dos aritméticas
        # distintas coincidan, y no es lo que la sección afirma.
        assert value == pytest.approx(comprehension[channel], rel=1e-12)
        assert value == pytest.approx(vector[channel], rel=1e-9)


def test_los_canales_sin_adquisiciones_no_aparecen(pieces):
    """Dividir por cero no lanza en NumPy: devuelve `inf` y sigue. Un canal con gasto y
    cero pacientes tiene que quedar fuera del resultado, no entrar con un infinito."""
    rows, spend, _ = pieces
    only_google = {"google": 10}
    for result in (cost_per_acquisition_loop(rows, only_google),
                   cost_per_acquisition_vectorized(spend, only_google)):
        assert set(result) == {"google"}
        assert np.isfinite(result["google"])


# --- Las columnas -------------------------------------------------------------------

def test_solo_los_canales_pagos_tienen_pauta(pieces):
    _, spend, _ = pieces
    assert spend.channels == ["google", "instagram", "tiktok"]


def test_las_columnas_son_enteros_de_maquina(pieces):
    """`int64`, no `object`. Si una columna sale de tipo `object`, NumPy está guardando
    punteros a enteros de Python y no queda nada de la ventaja: es el error que convierte
    un array en una lista disfrazada."""
    _, spend, _ = pieces
    assert spend.cost.dtype == np.int64
    assert spend.channel_codes.dtype == np.int64
    assert spend.cost.flags["C_CONTIGUOUS"]


def test_leer_de_disco_y_leer_de_filas_dan_lo_mismo(data: Path):
    from_disk = read_spend_arrays(data / "pauta.csv")
    from_rows = arrays_from_rows(read_spend_rows(data / "pauta.csv"))
    assert np.array_equal(from_disk.cost, from_rows.cost)
    assert from_disk.channels == from_rows.channels


# --- Vistas y copias ----------------------------------------------------------------

def test_un_corte_es_una_vista_y_escribe_sobre_el_original(pieces):
    """La primera sorpresa para quien viene de copias defensivas: `costos[:5] = 0` no
    modifica una copia, modifica el original. `subList` de Java se comporta igual; lo que
    no existe en Java es que la aritmética también devuelva vistas."""
    _, spend, _ = pieces
    original = spend.cost[:5].copy()
    view = spend.cost[:5]
    view[:] = 0
    assert np.array_equal(spend.cost[:5], np.zeros(5, dtype=np.int64))
    assert view.base is spend.cost          # así se comprueba que es vista y no copia

    spend.cost[:5] = original               # se restaura para las demás pruebas
    assert np.array_equal(spend.cost[:5], original)


def test_copy_rompe_el_vinculo(pieces):
    _, spend, _ = pieces
    copy = spend.cost[:5].copy()
    copy[:] = 0
    assert not np.array_equal(spend.cost[:5], copy)
    assert copy.base is None


# --- 🧨 El desbordamiento silencioso ------------------------------------------------

def test_int32_desborda_con_los_datos_reales_de_aurea(pieces):
    """No es un caso de laboratorio: la pauta real de la red desborda `int32` en la fila
    18.205 de 49.260. El resultado no lanza, no avisa y está mal por más del triple."""
    _, spend, _ = pieces
    correct = total_spend_with_dtype(spend, np.int64)
    wrong = total_spend_with_dtype(spend, np.int32)
    assert correct > 2**31 - 1
    assert wrong != correct
    assert wrong < correct


def test_el_int_de_python_no_desborda(pieces):
    """La contraparte, y el motivo de que el reflejo no exista: en Python puro esto no
    puede pasar. El `int` de NumPy es el `long` de Java; el de Python no es ninguno."""
    rows, spend, _ = pieces
    assert sum(int(row["costo_cop"]) for row in rows) == total_spend_with_dtype(
        spend, np.int64)
