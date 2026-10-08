"""Pruebas del tablero y de la paleta.

    pytest test_dashboard.py

Las de la paleta corren **sin ninguna dependencia**: el contraste es aritmética, y por eso
se puede exigir en CI aunque la máquina no tenga matplotlib. Las de los tres renderizadores
se saltan solas si su biblioteca no está instalada, que es lo correcto para un repositorio
donde cada sección declara lo suyo.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from dashboard import AUREA_CAC, RENDERERS, as_table
from palette import (
    BRAND,
    LARGE_TEXT_MINIMUM,
    TEXT_MINIMUM,
    check_palette,
    contrast_ratio,
    distinguishable_in_print,
    readable_colors,
    relative_luminance,
    to_grayscale,
)

# --- El contraste es aritmética ------------------------------------------------------

def test_los_extremos_conocidos():
    """Negro sobre blanco es 21:1 y un color sobre sí mismo es 1:1. Si estos dos fallan, la
    fórmula está mal y todo lo demás de este archivo no significa nada."""
    assert contrast_ratio("#000000", "#FFFFFF") == pytest.approx(21.0, rel=1e-3)
    assert contrast_ratio("#B8860B", "#B8860B") == pytest.approx(1.0)
    assert relative_luminance("#FFFFFF") == pytest.approx(1.0)
    assert relative_luminance("#000000") == pytest.approx(0.0)


def test_el_dorado_de_la_marca_no_sirve_para_texto_y_si_para_barra():
    """Es el hallazgo de la sección y la conversación que evita: el color de la marca no se
    prohíbe, se le asigna el papel en el que funciona."""
    ratio, for_text, for_bars = check_palette()["dorado"]
    assert ratio < TEXT_MINIMUM
    assert ratio >= LARGE_TEXT_MINIMUM
    assert for_text is False
    assert for_bars is True


def test_la_arena_solo_sirve_de_fondo():
    ratio, for_text, for_bars = check_palette()["arena"]
    assert ratio < LARGE_TEXT_MINIMUM
    assert (for_text, for_bars) == (False, False)


def test_hay_al_menos_dos_colores_legibles_para_texto():
    assert len(readable_colors()) >= 2
    assert BRAND["carbon"] in readable_colors()


def test_la_paleta_completa_no_sobrevive_a_la_impresion():
    """El comité de franquicia imprime en blanco y negro. Los cinco colores de la marca no
    se distinguen entre sí en gris, y dos de ellos —teja y pizarra— quedan prácticamente en
    el mismo tono. Se descubre aquí o en la reunión."""
    assert distinguishable_in_print(list(BRAND.values())) is False
    teja, pizarra = to_grayscale(BRAND["teja"]), to_grayscale(BRAND["pizarra"])
    assert contrast_ratio(teja, pizarra) < 1.1


def test_una_seleccion_de_tres_si_puede_sobrevivir():
    """La salida no es renunciar al color: es elegir menos series, o separar por luminancia."""
    assert distinguishable_in_print(["#FFFFFF", "#8D8D8D", "#2B2B2B"]) is True


# --- El tablero dice lo que ds04 midió ------------------------------------------------

def test_la_banda_de_tiktok_es_la_de_ds04():
    low, point, high = AUREA_CAC["tiktok"]
    assert low < point < high
    assert high / low == pytest.approx(7.5, abs=0.1)


def test_todos_los_canales_traen_su_banda():
    for channel, (low, point, high) in AUREA_CAC.items():
        assert low <= point <= high, channel
        assert high > low, channel


def test_la_tabla_ordena_por_la_cifra_principal():
    rows = [line for line in as_table().splitlines()
            if line[:1].isalpha() and "M" in line]
    values = [float(line.split()[2].rstrip("M")) for line in rows]
    assert values == sorted(values, reverse=True)


def test_la_tabla_publica_la_banda_y_no_solo_el_punto():
    """Si algún día alguien 'simplifica' la tabla dejando una cifra por canal, esta prueba
    falla. Es la regla de la sección convertida en aserción."""
    table = as_table()
    assert "mínimo" in table and "máximo" in table and "banda" in table
    assert "7.5×" in table


# --- Los tres renderizadores ----------------------------------------------------------

@pytest.mark.parametrize("option,module,suffix", [
    ("matplotlib", "matplotlib", ".png"),
    ("plotly", "plotly", ".html"),
    ("altair", "altair", ".html"),
])
def test_cada_renderizador_produce_su_archivo(option, module, suffix, tmp_path: Path):
    pytest.importorskip(module)
    target = tmp_path / f"tablero{suffix}"
    RENDERERS[option](target=target)
    assert target.exists() and target.stat().st_size > 0


def test_el_html_de_plotly_no_lleva_la_biblioteca_dentro(tmp_path: Path):
    """`include_plotlyjs="cdn"` baja el archivo de 4,10 MB a 9 KB **y** lo vuelve inútil sin
    internet. La decisión está tomada y esta prueba la fija para que nadie la cambie sin
    querer."""
    pytest.importorskip("plotly")
    target = tmp_path / "tablero.html"
    RENDERERS["plotly"](target=target)
    assert target.stat().st_size < 100 * 1024
    assert "cdn.plot.ly" in target.read_text(encoding="utf-8")


def test_matplotlib_no_intenta_abrir_una_ventana(tmp_path: Path):
    """El backend `Agg` se fija dentro de la función. Sin eso, esto falla en cualquier
    máquina sin pantalla, que son todas las que corren tareas programadas."""
    matplotlib = pytest.importorskip("matplotlib")
    RENDERERS["matplotlib"](target=tmp_path / "t.png")
    assert matplotlib.get_backend().lower() == "agg"
