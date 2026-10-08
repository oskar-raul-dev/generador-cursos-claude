"""Pruebas del exportador, del endpoint y del 🧨 de `pickle`.

    uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 --with onnxruntime==1.30.0 \\
           --with fastapi==0.141.1 --with pytest pytest -q

La prueba que sostiene la sección es `test_los_dos_formatos_predicen_lo_mismo`: si un día el
ONNX dejara de coincidir con el original, el endpoint estaría sirviendo otro modelo **sin que
nada fallara**, y ese es el peor error posible aquí.

Y la más incómoda es `test_cargar_un_pickle_ejecuta_codigo`, que **afirma que la
vulnerabilidad existe**. Está escrita como prueba y no como comentario porque el día que
`pickle` deje de comportarse así —no va a pasar— habría que reescribir media sección.
"""

from __future__ import annotations

import os
import pickle
import subprocess
import sys
from pathlib import Path

import pytest

HERE = Path(__file__).parent
UPSTREAM = HERE.parent / "ds07-scikit-learn"


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("ausentismo")
    subprocess.run([sys.executable, str(UPSTREAM / "generar_ausentismo.py"),
                    "--salida", str(out), "--pacientes", "4000"],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def models(data: Path, tmp_path_factory) -> Path:
    pytest.importorskip("skl2onnx")
    out = tmp_path_factory.mktemp("modelos")
    subprocess.run([sys.executable, str(HERE / "export.py"),
                    "--datos", str(data), "--salida", str(out)],
                   check=True, capture_output=True, cwd=HERE)
    return out


# --- El exportador ---------------------------------------------------------------------

def test_produce_los_dos_archivos(models: Path):
    assert (models / "modelo.pkl").exists()
    assert (models / "modelo.onnx").exists()


def test_el_onnx_pesa_menos_que_el_pickle(models: Path):
    """No es el argumento principal —son kilobytes— pero sí importa en una imagen de
    contenedor que además no necesita scikit-learn instalado."""
    assert (models / "modelo.onnx").stat().st_size < (models / "modelo.pkl").stat().st_size


def test_los_dos_formatos_predicen_lo_mismo(models: Path, data: Path):
    """La prueba que sostiene la sección. La tolerancia es de `float32` contra `float64`,
    no de 'más o menos igual'."""
    from export import TOLERANCE, probabilities_onnx
    from upstream import build_with_interaction, cutoff_of, load_rows, split_temporal

    rows = load_rows(data)
    _, test = split_temporal(rows, cutoff_of(data))
    matrix, _ = build_with_interaction(test[:500])

    with (models / "modelo.pkl").open("rb") as file:
        pipeline = pickle.load(file)
    original = [float(row[1]) for row in pipeline.predict_proba(matrix)]
    exported = probabilities_onnx((models / "modelo.onnx").read_bytes(), matrix)

    worst = max(abs(a - b) for a, b in zip(original, exported, strict=True))
    assert worst < TOLERANCE


def test_el_exportador_falla_si_los_formatos_no_coinciden(models: Path, data: Path,
                                                          tmp_path: Path):
    """Se comprueba que la comprobación existe: con una tolerancia imposible, el exportador
    tiene que negarse a publicar en vez de dejar los archivos igual."""
    environment = {**os.environ, "PYTHONPATH": str(HERE)}
    completed = subprocess.run(
        [sys.executable, "-c",
         "import export; export.TOLERANCE = 0.0; export.main()",
         "--datos", str(data), "--salida", str(tmp_path)],
        capture_output=True, text=True, cwd=HERE, env=environment)
    assert completed.returncode != 0
    assert "no coincide" in completed.stdout + completed.stderr


# --- El endpoint ------------------------------------------------------------------------

def test_el_vector_lleva_la_interaccion_y_el_orden_del_modelo(models: Path):
    """El cliente manda cinco campos con nombre; el servidor arma seis columnas en el orden
    del modelo. Aceptar una lista de seis números habría convertido cualquier reordenamiento
    en un error silencioso."""
    os.environ["AUREA_MODELOS"] = str(models)
    os.environ["AUREA_BACKEND"] = "onnx"
    pytest.importorskip("onnxruntime")
    pytest.importorskip("fastapi")
    import serve

    appointment = serve.Appointment(
        inasistencias_previas=2, jueves_tarde=1, lluvia_mm=12.0,
        distancia_km=18.0, dias_desde_agendamiento=30)
    vector = appointment.vector()
    assert len(vector) == 6
    assert vector[-1] == pytest.approx(12.0 * 18.0)


def test_el_endpoint_rechaza_una_distancia_imposible(models: Path):
    pytest.importorskip("fastapi")
    from pydantic import ValidationError

    import serve

    with pytest.raises(ValidationError):
        serve.Appointment(inasistencias_previas=0, jueves_tarde=0, lluvia_mm=0,
                          distancia_km=0, dias_desde_agendamiento=1)


def test_los_dos_backends_del_endpoint_coinciden(models: Path):
    """Cargados los dos en el mismo proceso, sobre la misma cita."""
    pytest.importorskip("onnxruntime")
    pytest.importorskip("sklearn")
    os.environ["AUREA_MODELOS"] = str(models)
    import serve

    vector = serve.Appointment(
        inasistencias_previas=2, jueves_tarde=1, lluvia_mm=12.0,
        distancia_km=18.0, dias_desde_agendamiento=30).vector()
    assert serve.load_pickle()(vector) == pytest.approx(serve.load_onnx()(vector),
                                                        abs=1e-6)


# --- 🧨 El pickle -------------------------------------------------------------------------

def test_cargar_un_pickle_ejecuta_codigo():
    """**Afirma que la vulnerabilidad existe.** No hay validación previa posible: para saber
    qué hay dentro habría que interpretarlo, que es lo que produce el problema."""
    from pickle_danger import demonstrate

    assert "lo escribió el archivo al cargarse" in demonstrate()


def test_un_onnx_no_es_un_pickle(models: Path):
    """Y no se puede cargar como tal: un grafo ONNX describe operaciones sobre tensores y no
    tiene forma de nombrar una función de Python."""
    with pytest.raises(Exception):  # noqa: B017 — cualquier error sirve: no es un pickle
        pickle.loads((models / "modelo.onnx").read_bytes())


def test_el_onnx_no_menciona_ningun_modulo_de_python(models: Path):
    """Un `.pkl` lleva dentro los nombres de los módulos que va a importar —`sklearn`,
    `numpy`, `builtins`—. El `.onnx` del mismo modelo no menciona ninguno."""
    onnx_bytes = (models / "modelo.onnx").read_bytes()
    pickle_bytes = (models / "modelo.pkl").read_bytes()
    assert b"sklearn" in pickle_bytes
    assert b"sklearn" not in onnx_bytes
    assert b"builtins" not in onnx_bytes
