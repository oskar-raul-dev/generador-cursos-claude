"""Pruebas del proyecto Embudo. Sin red, sin dependencias, sin servicios.

    pytest test_embudo.py

La prueba que sostiene la sección entera es `test_todo_modelo_reparte_exactamente_un
_credito`: si un modelo repartiera de más, estaría inventando pacientes, que es justo lo
que hacen los tableros que la sección desmonta.
"""

from __future__ import annotations

import subprocess
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

import pytest

from attribution import (
    MATURITY,
    MODELS,
    cost_per_acquisition,
    credit_by_channel,
    credit_first,
    credit_last,
    credit_linear,
    credit_time_decay,
    load_acquisitions,
    load_journeys,
    load_lead_created,
    load_spend,
    mature_leads,
    share_of_credit,
)
from funnel import (
    STAGES,
    cohort_conversion,
    leads_by_month,
    load_lead_interest,
    load_stage_reach,
    seasonal_index,
    stage_rates,
)
from partners import (
    PartnerValue,
    by_dimension,
    load_partner_values,
    network_summary,
    ranked,
)

HERE = Path(__file__).parent
GENERATOR = HERE.parent / "ds01-numpy-y-el-modelo-vectorizado" / "generar_embudo.py"
CUTOFF = date(2026, 3, 31)


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("embudo")
    subprocess.run([sys.executable, str(GENERATOR), "--salida", str(out)],
                   check=True, capture_output=True)
    return out


@pytest.fixture(scope="module")
def pieces(data: Path):
    return (load_journeys(data), load_acquisitions(data), load_lead_created(data))


# --- Un reparto es un reparto -------------------------------------------------------

def test_todo_modelo_reparte_exactamente_un_credito(pieces):
    journeys, _, _ = pieces
    for lead, touches in list(journeys.items())[:2000]:
        for name, model in MODELS.items():
            assert sum(model(touches).values()) == pytest.approx(1.0), (name, lead)


def test_el_credito_total_es_el_numero_de_pacientes(pieces, data: Path):
    journeys, acquisitions, created = pieces
    mature = mature_leads(created, CUTOFF)
    expected = len({lead for lead in acquisitions if lead in mature})
    for name, model in MODELS.items():
        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())
        assert total == pytest.approx(expected), name


def test_con_un_solo_toque_los_cuatro_modelos_coinciden():
    touches = [(datetime(2026, 1, 5, 10), "tiktok")]
    for model in MODELS.values():
        assert model(touches) == {"tiktok": 1.0}


def test_el_decaimiento_se_parece_al_ultimo_toque_cuando_los_toques_estan_lejos():
    """Con meses de separación, el peso del primero se hace despreciable. Es la propiedad
    que hay que entender antes de elegir la vida media: el parámetro decide el modelo."""
    touches = [(datetime(2026, 1, 1), "tiktok"), (datetime(2026, 6, 1), "google")]
    credits = credit_time_decay(touches, half_life_days=14.0)
    assert credits["google"] > 0.999
    assert credits["tiktok"] < 0.001


def test_el_decaimiento_se_parece_al_lineal_cuando_la_vida_media_es_enorme(pieces):
    journeys, _, _ = pieces
    touches = next(t for t in journeys.values() if len(t) >= 3)
    slow = credit_time_decay(touches, half_life_days=1_000_000.0)
    for channel, share in credit_linear(touches).items():
        assert slow[channel] == pytest.approx(share, rel=1e-3)


# --- La tesis de la sección ---------------------------------------------------------

def test_el_ranking_se_invierte_entre_el_primer_y_el_ultimo_toque(pieces, data: Path):
    """Es la sección entera en una prueba: los mismos datos, dos modelos, dos respuestas
    opuestas. TikTok es el canal más barato por primer toque y el más caro por el último."""
    journeys, acquisitions, created = pieces
    mature = mature_leads(created, CUTOFF)
    spend = load_spend(data, until=CUTOFF - MATURITY)

    first = cost_per_acquisition(
        spend, credit_by_channel(journeys, acquisitions, credit_first, mature))
    last = cost_per_acquisition(
        spend, credit_by_channel(journeys, acquisitions, credit_last, mature))

    assert min(first, key=first.get) == "tiktok"
    assert max(last, key=last.get) == "tiktok"
    assert last["tiktok"] / first["tiktok"] > 5


def test_el_descubrimiento_y_la_decision_son_canales_distintos(pieces):
    journeys, acquisitions, created = pieces
    mature = mature_leads(created, CUTOFF)
    first = share_of_credit(credit_by_channel(journeys, acquisitions, credit_first, mature))
    last = share_of_credit(credit_by_channel(journeys, acquisitions, credit_last, mature))
    assert first["tiktok"] > last["tiktok"] * 4
    assert last["referido"] > first["referido"] * 2


# --- La ventana y la madurez ---------------------------------------------------------

def test_el_gasto_se_recorta_con_la_misma_ventana(data: Path):
    """Numerador y denominador cubren el mismo período, o el cociente no significa nada."""
    everything = sum(load_spend(data).values())
    window = sum(load_spend(data, until=CUTOFF - MATURITY).values())
    assert 0 < window < everything


def test_el_filtro_de_madurez_abarata_mas_al_canal_mas_lento(pieces, data: Path):
    """TikTok tarda hasta 96 días en cerrar. Contar sus leads recientes como fracasos lo
    castiga más que a Google, que cierra en menos de cinco semanas."""
    journeys, acquisitions, created = pieces
    mature = mature_leads(created, CUTOFF)

    naive = cost_per_acquisition(
        load_spend(data), credit_by_channel(journeys, acquisitions, credit_last))
    honest = cost_per_acquisition(
        load_spend(data, until=CUTOFF - MATURITY),
        credit_by_channel(journeys, acquisitions, credit_last, mature))

    tiktok_change = honest["tiktok"] / naive["tiktok"]
    google_change = honest["google"] / naive["google"]
    assert tiktok_change < google_change < 1.0


def test_la_madurez_deja_fuera_los_leads_recientes(pieces):
    _, _, created = pieces
    mature = mature_leads(created, CUTOFF)
    limit = CUTOFF - MATURITY
    assert all(created[lead] <= limit for lead in mature)
    assert any(day > limit for day in created.values())


# --- El embudo ----------------------------------------------------------------------

def test_cada_etapa_convierte_menos_que_la_anterior(data: Path, pieces):
    _, _, created = pieces
    rows = stage_rates(load_stage_reach(data), len(created))
    assert [row[0] for row in rows] == STAGES
    counts = [row[1] for row in rows]
    assert counts == sorted(counts, reverse=True)


def test_las_cohortes_recientes_se_marcan_como_inmaduras(pieces):
    journeys, acquisitions, created = pieces
    del journeys
    cohorts = cohort_conversion(created, set(acquisitions), CUTOFF, MATURITY)
    assert cohorts["2024-01"][3] is True
    assert cohorts["2026-03"][3] is False


def test_la_cohorte_inmadura_convierte_peor_y_es_un_espejismo(pieces):
    """No es que marzo haya sido malo: es que marzo no ha terminado. Si esta prueba
    fallara, el filtro de madurez de la sección no tendría nada que corregir."""
    journeys, acquisitions, created = pieces
    del journeys
    cohorts = cohort_conversion(created, set(acquisitions), CUTOFF, MATURITY)
    mature_rate = cohorts["2025-06"][2]
    fresh_rate = cohorts["2026-03"][2]
    assert fresh_rate < mature_rate


def test_enero_y_febrero_son_de_ortodoncia(data: Path, pieces):
    _, _, created = pieces
    interest = load_lead_interest(data)
    index = seasonal_index(leads_by_month(created, interest, "ortodoncia"))
    assert index[1] > 1.5
    assert index[6] < 1.0


def test_diciembre_es_de_estetica(data: Path, pieces):
    _, _, created = pieces
    interest = load_lead_interest(data)
    index = seasonal_index(leads_by_month(created, interest, "estetica"))
    assert index[12] > 1.4
    assert index[1] < 1.0


# --- Los aliados ---------------------------------------------------------------------

def test_la_red_de_aliados_cuadra(data: Path):
    values = load_partner_values(data)
    summary = network_summary(values)
    assert summary["aliados"] == 23
    assert summary["remisiones"] == sum(value.referrals for value in values)
    assert 0.2 < summary["tasa_retorno"] < 0.6


def test_el_aliado_sin_retornos_no_sale_primero():
    """Su costo por paciente retenido es infinito, no cero. Devolver cero lo pondría a la
    cabeza del ranking, que es exactamente el error que esta decisión evita."""
    empty = PartnerValue("A999", "endodoncia", "norte", 40, 0, 12_000_000)
    good = PartnerValue("A001", "endodoncia", "norte", 40, 20, 12_000_000)
    assert ranked([empty, good])[0] is good
    assert empty.cost_per_returned == float("inf")


def test_los_aliados_sin_volumen_no_entran_al_ranking(data: Path):
    values = load_partner_values(data)
    assert all(value.referrals >= 30 for value in ranked(values))


def test_los_aliados_se_distinguen_entre_si(data: Path):
    """Si todos costaran lo mismo, la pregunta de Marcela no tendría respuesta posible."""
    listed = ranked(load_partner_values(data))
    assert listed[-1].cost_per_returned / listed[0].cost_per_returned > 1.3


def test_agrupar_por_zona_y_por_especialidad_da_numeros_distintos(data: Path):
    values = load_partner_values(data)
    zones = by_dimension(values, "zone")
    specialties = by_dimension(values, "specialty")
    assert len(zones) == 5
    assert len(specialties) == 5
    assert max(zones.values()) > min(zones.values())


def test_el_costo_de_la_red_es_comparable_al_de_un_canal_pago(data: Path):
    """El marco entero de la sección: la comisión no se compara contra cero, se compara
    contra lo que cuesta traer a ese paciente por Google."""
    summary = network_summary(load_partner_values(data))
    journeys = load_journeys(data)
    acquisitions = load_acquisitions(data)
    mature = mature_leads(load_lead_created(data), CUTOFF)
    google = cost_per_acquisition(
        load_spend(data, until=CUTOFF - MATURITY),
        credit_by_channel(journeys, acquisitions, credit_last, mature))["google"]
    assert 0.3 < summary["costo_por_retenido"] / google < 3.0


def test_el_generador_no_dejo_remisiones_huerfanas(data: Path):
    import csv

    with (data / "aliados.csv").open(encoding="utf-8") as file:
        known = {row["aliado_id"] for row in csv.DictReader(file)}
    with (data / "remisiones.csv").open(encoding="utf-8") as file:
        assert all(row["aliado_id"] in known for row in csv.DictReader(file))


def test_la_madurez_del_curso_es_el_peor_rezago_declarado():
    """96 días es el techo de `LAG_DAYS` del generador, para TikTok. Si alguien cambia ese
    rezago sin tocar `MATURITY`, la ventana deja de cubrir el canal más lento."""
    assert MATURITY == timedelta(days=96)
