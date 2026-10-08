"""Pruebas del informe de cobranza. Sin red y sin base de datos.

    uv run --with pandas==3.0.5 --with pytest pytest test_collections_report.py

La primera prueba es la que sostiene la sección 6 —las tres versiones producen la misma
tabla—, y las demás fijan las tres cosas que en pandas se rompen sin avisar: la llave que no
es única, el dato ausente que alguien convierte en cero, y la asignación encadenada.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pandas as pd
import pytest

from collections_report import (
    collected_lean,
    collected_naive,
    collected_vectorized,
    frame_memory_mb,
    read_installments,
    read_plans,
)

HERE = Path(__file__).parent
GENERATOR = HERE.parent / "ds01-numpy-y-el-modelo-vectorizado" / "generar_embudo.py"


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("embudo")
    subprocess.run([sys.executable, str(GENERATOR), "--salida", str(out)],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def frames(data: Path):
    return (read_plans(data / "planes_de_tratamiento.csv"),
            read_installments(data / "cuotas.csv"))


# --- La igualdad que hace legítima la medición -------------------------------------

def test_las_tres_versiones_dan_la_misma_tabla(frames):
    plans, installments = frames
    naive = collected_naive(plans, installments)
    vectorized = collected_vectorized(plans, installments)
    lean = collected_lean(plans, installments)

    pd.testing.assert_frame_equal(naive, vectorized)
    # La versión `lean` lee con dtypes `category`, así que el índice es categórico y el de
    # las otras dos es de cadenas. Es la misma tabla con otro tipo de índice, y compararla
    # exige decirlo: `check_categorical=False` no relaja los valores, solo el tipo del eje.
    pd.testing.assert_frame_equal(naive, lean, check_index_type=False,
                                  check_categorical=False)


def test_la_tabla_tiene_una_fila_por_sede_e_interes(frames):
    plans, installments = frames
    assert len(collected_lean(plans, installments)) == 20   # 10 sedes × 2 intereses


# --- El dato ausente no es un cero --------------------------------------------------

def test_lo_cobrado_es_menor_que_lo_comprometido(frames):
    """Hay planes abandonados: cuotas programadas que nunca se pagaron. Si esta prueba
    empezara a fallar, alguien convirtió un `fecha_pago` vacío en un cobro."""
    plans, installments = frames
    table = collected_lean(plans, installments)
    assert (table["cobrado_cop"] < table["comprometido_cop"]).all()
    assert (table["cobrado_pct"] > 80).all()      # tampoco es un desastre: es cartera normal


def test_el_total_coincide_con_la_suma_directa(frames):
    """La comprobación aburrida y la que más vale: el informe contra un `sum` a mano."""
    plans, installments = frames
    paid = installments.loc[installments["fecha_pago"].notna(), "valor_cop"].sum()
    assert collected_lean(plans, installments)["cobrado_cop"].sum() == paid


# --- La llave que no es única -------------------------------------------------------

def test_validate_atrapa_la_union_muchos_a_muchos(data: Path):
    """`etapas` y `toques` tienen varias filas por lead. Unirlas sin pensar multiplica, y
    `validate=` es lo que convierte ese error silencioso en una excepción."""
    stages = pd.read_csv(data / "etapas.csv")
    touches = pd.read_csv(data / "toques.csv")

    exploded = stages.merge(touches, on="lead_id")
    assert len(exploded) > len(stages)            # 133.288 contra 64.062

    with pytest.raises(pd.errors.MergeError):
        stages.merge(touches, on="lead_id", validate="1:1")


def test_la_union_del_informe_si_es_uno_a_uno(frames):
    """Y la contraparte: la del informe pasa `validate="1:1"` sin quejarse. Si algún día
    deja de pasar, es que los datos cambiaron y el informe estaba mintiendo."""
    plans, installments = frames
    collected_lean(plans, installments)           # lleva el validate dentro


# --- Copy-on-Write ------------------------------------------------------------------

def test_filtrar_y_asignar_no_toca_el_original(frames):
    """En pandas 3.0 esto es seguro y silencioso, y antes de 2.0 era el bug más común de
    todo el ecosistema. La prueba está aquí para que el lector vea la garantía escrita."""
    plans, _ = frames
    before = plans["valor_total_cop"].copy()

    subset = plans[plans["interes"] == "estetica"]
    subset["valor_total_cop"] = 0

    pd.testing.assert_series_equal(plans["valor_total_cop"], before)


def test_la_asignacion_encadenada_avisa_y_no_hace_nada(frames):
    plans, _ = frames
    before = plans["valor_total_cop"].copy()

    with pytest.warns(pd.errors.ChainedAssignmentError):
        plans[plans["interes"] == "estetica"]["valor_total_cop"] = 0

    pd.testing.assert_series_equal(plans["valor_total_cop"], before)


# --- La memoria ---------------------------------------------------------------------

def test_memory_usage_sin_deep_se_queda_corto(frames):
    """El mismo `getsizeof` mentiroso de `ds01`, un nivel más arriba."""
    _, installments = frames
    shallow = float(installments.memory_usage(deep=False).sum()) / 1e6
    assert frame_memory_mb(installments) > shallow * 2


def test_las_categorias_ahorran_memoria_sin_cambiar_el_resultado(data: Path):
    plain = read_plans(data / "planes_de_tratamiento.csv")
    lean = read_plans(data / "planes_de_tratamiento.csv", lean=True)
    assert frame_memory_mb(lean) < frame_memory_mb(plain)
    assert lean["valor_total_cop"].sum() == plain["valor_total_cop"].sum()
