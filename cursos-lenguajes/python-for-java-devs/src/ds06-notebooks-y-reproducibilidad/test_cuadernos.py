"""Pruebas de los cuadernos y de la medición de reproducibilidad.

    uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 --with pytest pytest -q

Las del generador corren **sin dependencias**; las que ejecutan cuadernos se saltan solas si
no hay kernel. Esa separación no es comodidad: es la misma tesis de la sección —lo que
depende de un entorno se declara y se aísla— aplicada a sus propias pruebas.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

from generar_cuadernos import NOTEBOOKS

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def notebooks(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("cuadernos")
    subprocess.run([sys.executable, str(HERE / "generar_cuadernos.py"),
                    "--salida", str(out)], check=True, capture_output=True)
    return out


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


# --- Los cuadernos, sin ejecutarlos --------------------------------------------------

def test_se_generan_los_seis(notebooks: Path):
    assert {path.name for path in notebooks.glob("*.ipynb")} == set(NOTEBOOKS)


def test_el_generador_es_determinista(tmp_path: Path):
    runs = []
    for name in ("a", "b"):
        out = tmp_path / name
        subprocess.run([sys.executable, str(HERE / "generar_cuadernos.py"),
                        "--salida", str(out)], check=True, capture_output=True)
        runs.append(sorted((p.name, p.read_bytes()) for p in out.iterdir()))
    assert runs[0] == runs[1]


def test_todos_traen_sus_salidas_guardadas(notebooks: Path):
    """Es la trampa entera: un cuaderno con salidas se lee como si funcionara."""
    for path in notebooks.glob("*.ipynb"):
        document = load(path)
        assert any(cell["outputs"] for cell in document["cells"]), path.name


def test_el_estado_oculto_deja_su_huella_en_el_orden(notebooks: Path):
    """1, 3, 2. Es lo único que delata el problema sin ejecutar nada, y es lo primero que
    hay que mirar al recibir un cuaderno ajeno."""
    counts = [cell["execution_count"]
              for cell in load(notebooks / "estado-oculto.ipynb")["cells"]]
    assert counts == [1, 3, 2]
    assert counts != sorted(counts)


def test_la_celda_borrada_no_deja_huella(notebooks: Path):
    """Y este es peor justamente por eso: los contadores van en orden y falta una celda."""
    counts = [cell["execution_count"]
              for cell in load(notebooks / "celda-borrada.ipynb")["cells"]]
    assert counts == sorted(counts)
    assert counts[0] != 1      # el único indicio: no empieza en 1


def test_la_ruta_absoluta_esta_ahi_para_verse(notebooks: Path):
    source = "".join(load(notebooks / "ruta-absoluta.ipynb")["cells"][0]["source"])
    assert source.count("/Users/") == 1


# --- La medición, que necesita un kernel ---------------------------------------------

@pytest.fixture(scope="module", autouse=False)
def kernel():
    """Se salta el módulo entero si no hay kernel. No lo instala: lo comprueba."""
    pytest.importorskip("ipykernel")
    pytest.importorskip("nbclient")
    from check_reproducibility import require_kernel

    require_kernel()


def test_el_cuaderno_limpio_corre_y_es_estable(notebooks: Path, kernel):
    from check_reproducibility import run_once

    ran, error, outputs = run_once(notebooks / "limpio.ipynb")
    assert ran, error
    _, _, again = run_once(notebooks / "limpio.ipynb")
    assert outputs == again


@pytest.mark.parametrize("name,expected", [
    ("estado-oculto.ipynb", "NameError"),
    ("celda-borrada.ipynb", "NameError"),
    ("ruta-absoluta.ipynb", "FileNotFoundError"),
    ("dependencia-no-declarada.ipynb", "ModuleNotFoundError"),
])
def test_cada_defecto_falla_como_dice_la_seccion(notebooks: Path, kernel, name, expected):
    from check_reproducibility import run_once

    ran, error, _ = run_once(notebooks / name)
    assert not ran
    assert expected in error


def test_el_error_no_trae_codigos_de_color(notebooks: Path, kernel):
    """El kernel colorea el traceback porque cree que habla con una terminal. Si eso llega
    al JSON de la medición, la tabla de la sección 6 queda ilegible."""
    from check_reproducibility import run_once

    _, error, _ = run_once(notebooks / "estado-oculto.ipynb")
    assert "\x1b[" not in error


def test_correr_no_es_ser_reproducible(notebooks: Path, kernel):
    """`azar-sin-semilla` pasa la primera prueba y falla la que importa. Es el defecto más
    difícil de ver porque no produce ningún error."""
    from check_reproducibility import run_once

    ran, _, outputs = run_once(notebooks / "azar-sin-semilla.ipynb")
    assert ran
    _, _, again = run_once(notebooks / "azar-sin-semilla.ipynb")
    assert outputs != again


# --- marimo ---------------------------------------------------------------------------

def test_el_cuaderno_de_marimo_es_un_archivo_python():
    """Sin ejecutarlo: es `.py`, se lee, se revisa en un pull request y se versiona. La
    mitad del argumento de marimo está en la extensión del archivo."""
    source = (HERE / "cuaderno_marimo.py").read_text(encoding="utf-8")
    assert "@app.cell" in source
    # Lo que no puede haber es el **campo** de un `.ipynb`, no la palabra: el docstring de
    # ese archivo explica justamente que no lo tiene. La primera versión de esta prueba
    # buscaba la palabra suelta y fallaba contra su propia explicación.
    assert '"execution_count"' not in source
    assert "image/png" not in source


def test_marimo_resuelve_el_orden_por_dependencias():
    """La celda que usa `adquiridos` está **antes** que la que lo define, y corre igual.
    En Jupyter eso mismo es el bug de `estado-oculto.ipynb`."""
    pytest.importorskip("marimo")
    completed = subprocess.run([sys.executable, str(HERE / "cuaderno_marimo.py")],
                               check=True, capture_output=True, text=True)
    assert "['google', 'instagram', 'tiktok']" in completed.stdout
