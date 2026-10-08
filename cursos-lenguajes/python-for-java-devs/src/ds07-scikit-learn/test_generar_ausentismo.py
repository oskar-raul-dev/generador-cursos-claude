"""Pruebas del generador del histórico de ausentismo. Sin red, sin dependencias, sin modelo.

    pytest test_generar_ausentismo.py

Tres secciones entrenan sobre este archivo. Lo que se comprueba aquí es que el conjunto
**tenga la señal que ds07 dice que tiene y la fuga que ds07 dice que tiene**: si la
variable de historial no discriminara, el capítulo mediría ruido y llamaría modelo a una
moneda; si la columna con fuga no filtrara de verdad, el ejemplo de fuga sería una
afirmación sin demostración.
"""

from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path

import pytest

import generar_ausentismo as gen

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def dataset(tmp_path_factory) -> dict:
    """Un solo conjunto para todo el módulo. Con 1.800 pacientes basta para las señales
    y la suite corre en segundos; el volumen real solo importa para las mediciones."""
    out = tmp_path_factory.mktemp("ausentismo")
    subprocess.run([sys.executable, str(HERE / "generar_ausentismo.py"),
                    "--salida", str(out), "--semilla", "20260913", "--pacientes", "1800"],
                   check=True, capture_output=True)
    return {"dir": out,
            "citas": read_csv(out / "citas_historicas.csv"),
            "pacientes": read_csv(out / "pacientes.csv"),
            "clima": read_csv(out / "clima.csv"),
            "manifiesto": json.loads((out / "manifiesto.json").read_text("utf-8"))}


def read_csv(path: Path) -> list[dict]:
    lines = path.read_text("utf-8").splitlines()
    header = lines[0].split(",")
    # `strict=True` no es adorno: si una fila trae más o menos columnas que el
    # encabezado, el `zip` silencioso la recortaría y la prueba pasaría sobre datos
    # mutilados.
    return [dict(zip(header, line.split(","), strict=True)) for line in lines[1:]]


def no_show_rate(rows) -> float:
    return sum(1 - int(row["asistio"]) for row in rows) / len(rows)


# --- Reproducibilidad y manifiesto -------------------------------------------------

def test_la_misma_semilla_produce_los_mismos_bytes(tmp_path):
    runs = []
    for name in ("a", "b"):
        out = tmp_path / name
        subprocess.run([sys.executable, str(HERE / "generar_ausentismo.py"),
                        "--salida", str(out), "--pacientes", "300"],
                       check=True, capture_output=True)
        runs.append((out / "citas_historicas.csv").read_bytes())
    assert runs[0] == runs[1]


def test_el_manifiesto_cuenta_las_filas_que_existen(dataset):
    filas = dataset["manifiesto"]["filas"]
    assert filas["citas_historicas.csv"] == len(dataset["citas"])
    assert filas["pacientes.csv"] == len(dataset["pacientes"])
    assert filas["clima.csv"] == len(dataset["clima"])


def test_el_manifiesto_nombra_la_columna_con_fuga(dataset):
    """Que la trampa esté documentada en el propio conjunto, no solo en la prosa."""
    assert dataset["manifiesto"]["columna_con_fuga"] in dataset["citas"][0]


# --- La frontera clínica -----------------------------------------------------------

def test_no_hay_ni_una_columna_clinica_ni_identificable(dataset):
    forbidden = {"diagnostico", "procedimiento", "codigo", "documento", "cedula",
                 "nombre", "telefono", "correo", "direccion", "historia", "tratamiento"}
    for key in ("citas", "pacientes"):
        assert not (set(dataset[key][0]) & forbidden)


def test_la_propension_no_se_escribe_a_disco(dataset):
    """Es el parámetro oculto del proceso. Si saliera en el CSV, cualquier modelo lo
    usaría y ds07 estaría midiendo una copia de la respuesta, no una predicción."""
    assert "propension_base" not in dataset["pacientes"][0]
    assert "propension_base" not in dataset["citas"][0]


# --- Integridad temporal -----------------------------------------------------------

def test_el_historial_previo_solo_mira_hacia_atras(dataset):
    """`inasistencias_previas` y `citas_previas` se reconstruyen desde cero, en orden
    cronológico, y tienen que coincidir con lo que escribió el generador. Es la prueba
    que separa una variable legítima de una fuga."""
    by_patient = defaultdict(list)
    for row in dataset["citas"]:
        by_patient[row["paciente_id"]].append(row)

    for patient_id, rows in by_patient.items():
        rows.sort(key=lambda row: (row["fecha"], row["hora"]))
        misses = 0
        for visits, row in enumerate(rows):
            assert int(row["citas_previas"]) == visits, patient_id
            assert int(row["inasistencias_previas"]) == misses, patient_id
            misses += 1 - int(row["asistio"])


def test_la_columna_con_fuga_filtra_de_verdad(dataset):
    """Un valor constante para todas las citas de un paciente solo puede salir de haber
    mirado el histórico completo. Esa constancia **es** la fuga, y se comprueba."""
    by_patient = defaultdict(set)
    for row in dataset["citas"]:
        by_patient[row["paciente_id"]].add(row["inasistencias_totales_paciente"])
    assert all(len(values) == 1 for values in by_patient.values())

    # Y en la primera cita de cada paciente el total ya sabe lo que todavía no ha pasado.
    first_rows = {}
    for row in sorted(dataset["citas"], key=lambda row: (row["fecha"], row["hora"])):
        first_rows.setdefault(row["paciente_id"], row)
    knows_the_future = [row for row in first_rows.values()
                        if int(row["inasistencias_totales_paciente"])
                        > int(row["inasistencias_previas"])]
    assert len(knows_the_future) > len(first_rows) * 0.5


def test_el_corte_temporal_deja_datos_de_los_dos_lados(dataset):
    """La división de ds07 es temporal, no aleatoria. Si el corte dejara el 5% de un lado,
    la métrica de prueba sería ruido y el capítulo no podría sostener nada."""
    cutoff = dataset["manifiesto"]["corte_temporal"]
    before = [row for row in dataset["citas"] if row["fecha"] < cutoff]
    after = [row for row in dataset["citas"] if row["fecha"] >= cutoff]
    assert 0.25 < len(after) / len(dataset["citas"]) < 0.45
    assert before and after


def test_no_se_atiende_en_domingo_ni_en_semana_santa(dataset):
    for row in dataset["citas"]:
        day = date.fromisoformat(row["fecha"])
        assert day.weekday() != 6
        assert not gen.is_holy_week(day)


def test_todas_las_citas_caen_dentro_del_rango(dataset):
    """La prueba que nació del primer bug de este generador: el jitter de la primera cita
    empujaba al paciente a diciembre de 2023, fuera del clima, y reventaba el KeyError."""
    for row in dataset["citas"]:
        assert gen.START <= date.fromisoformat(row["fecha"]) <= gen.END


def test_la_pascua_cae_donde_debe():
    assert gen.easter_sunday(2024) == date(2024, 3, 31)
    assert gen.easter_sunday(2025) == date(2025, 4, 20)
    assert gen.easter_sunday(2026) == date(2026, 4, 5)


# --- La señal que ds07 tiene que encontrar -----------------------------------------

def test_la_inasistencia_global_es_la_del_dominio(dataset):
    """19%, que es el dato de la historia de Áurea, no un número cómodo."""
    assert 0.17 < no_show_rate(dataset["citas"]) < 0.22


def test_el_historial_es_la_variable_que_mas_pesa(dataset):
    """Con cero inasistencias previas contra tres o más: la diferencia tiene que ser
    grande y monótona, o la línea base de tres variables no tendría de dónde salir."""
    buckets = defaultdict(list)
    for row in dataset["citas"]:
        buckets[min(int(row["inasistencias_previas"]), 3)].append(row)
    rates = [no_show_rate(buckets[level]) for level in sorted(buckets)]
    assert rates == sorted(rates), rates
    assert rates[-1] > rates[0] * 1.8


def test_el_historial_satura(dataset):
    """La cuarta inasistencia no dice mucho más que la tercera. `ds07` lo va a descubrir
    y es la razón de que la variable entre topada y no como conteo crudo."""
    def rate_at(level_from, level_to):
        rows = [row for row in dataset["citas"]
                if level_from <= int(row["inasistencias_previas"]) <= level_to]
        return no_show_rate(rows)
    salto_temprano = rate_at(2, 2) - rate_at(1, 1)
    salto_tardio = rate_at(5, 9) - rate_at(4, 4)
    assert salto_tardio < salto_temprano


def test_el_jueves_a_las_cuatro_es_peor(dataset):
    """Es la pregunta operativa de la §8: ¿conviene sobreagendar el jueves a las cuatro?
    Si el dato no tuviera el efecto, la pregunta no tendría respuesta posible."""
    late_thursday = [row for row in dataset["citas"]
                     if row["dia_semana"] == "3" and row["hora"] >= "16:00"]
    rest = [row for row in dataset["citas"]
            if not (row["dia_semana"] == "3" and row["hora"] >= "16:00")]
    assert no_show_rate(late_thursday) > no_show_rate(rest) * 1.15


def test_llover_y_vivir_lejos_empeoran_la_asistencia(dataset):
    dry = [row for row in dataset["citas"] if float(row["lluvia_mm"]) == 0]
    wet = [row for row in dataset["citas"] if float(row["lluvia_mm"]) > 8]
    assert no_show_rate(wet) > no_show_rate(dry)

    near = [row for row in dataset["citas"] if float(row["distancia_km"]) < 4]
    far = [row for row in dataset["citas"] if float(row["distancia_km"]) > 15]
    assert no_show_rate(far) > no_show_rate(near)


def test_la_lluvia_no_es_uniforme_en_el_ano(dataset):
    """Abril-mayo y octubre-noviembre. Si lloviera igual todo el año, el efecto de la
    lluvia y el del mes serían la misma columna con dos nombres."""
    per_month: Counter = Counter()
    for row in dataset["clima"]:
        per_month[date.fromisoformat(row["fecha"]).month] += float(row["lluvia_mm"])
    assert per_month[4] > per_month[7] * 2
    assert per_month[10] > per_month[7] * 2


def test_hay_pacientes_que_abandonan_el_tratamiento(dataset):
    """El paciente del mes ocho de veinticuatro que se desaparece. `ds08` lo necesita."""
    last_month = {}
    for row in dataset["citas"]:
        patient = row["paciente_id"]
        last_month[patient] = max(last_month.get(patient, 0), int(row["mes_tratamiento"]))
    abandoned = [month for month in last_month.values() if 5 <= month <= 20]
    assert len(abandoned) > len(last_month) * 0.15


def test_el_volumen_se_parece_al_de_la_red(dataset):
    """A 1.800 pacientes el archivo es una muestra; lo que se comprueba es la proporción
    citas/paciente, que es la que fija el volumen mensual con el parámetro por defecto."""
    ratio = len(dataset["citas"]) / len(dataset["pacientes"])
    assert 8 < ratio < 14, ratio
