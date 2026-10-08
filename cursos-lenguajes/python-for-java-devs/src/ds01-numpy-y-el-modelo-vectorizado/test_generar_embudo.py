"""Pruebas del generador del Embudo. Corren sin red, sin dependencias y en segundos.

    pytest test_generar_embudo.py

Seis secciones leen este conjunto. Lo que se comprueba aquí no es que el generador
"funcione": es que el conjunto **sostenga las tesis de ds01 a ds06**. Un embudo que
permite saltos de etapa, un manifiesto que cuenta filas que no escribió o una atribución
en la que los dos modelos coinciden no rompen ningún `import` — rompen un capítulo.
"""

from __future__ import annotations

import json
import random
import subprocess
import sys
from collections import Counter
from datetime import date, datetime
from pathlib import Path

import pytest

import generar_embudo as gen

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def dataset(tmp_path_factory) -> dict:
    """Genera el conjunto una vez, a escala 1, y lo devuelve leído."""
    out = tmp_path_factory.mktemp("embudo")
    subprocess.run([sys.executable, str(HERE / "generar_embudo.py"),
                    "--salida", str(out), "--semilla", "20260913"],
                   check=True, capture_output=True)
    return {"dir": out, **{path.name: read_csv(path) for path in out.glob("*.csv")},
            "manifiesto": json.loads((out / "manifiesto.json").read_text("utf-8"))}


def read_csv(path: Path) -> list[dict]:
    lines = path.read_text("utf-8").splitlines()
    header = lines[0].split(",")
    # `strict=True` no es adorno: si una fila trae más o menos columnas que el
    # encabezado, el `zip` silencioso la recortaría y la prueba pasaría sobre datos
    # mutilados.
    return [dict(zip(header, line.split(","), strict=True)) for line in lines[1:]]


# --- Reproducibilidad --------------------------------------------------------------

def test_la_misma_semilla_produce_los_mismos_bytes(tmp_path):
    """Sin esto, ninguna medición del track es comparable entre dos corridas."""
    runs = []
    for name in ("a", "b"):
        out = tmp_path / name
        subprocess.run([sys.executable, str(HERE / "generar_embudo.py"),
                        "--salida", str(out), "--semilla", "20260913"],
                       check=True, capture_output=True)
        runs.append(sorted((path.name, path.read_bytes()) for path in out.iterdir()))
    assert runs[0] == runs[1]


def test_otra_semilla_produce_otro_conjunto(tmp_path):
    """La contraparte: si la semilla no cambia nada, no es una semilla."""
    outputs = []
    for seed in ("20260913", "20260914"):
        out = tmp_path / seed
        subprocess.run([sys.executable, str(HERE / "generar_embudo.py"),
                        "--salida", str(out), "--semilla", seed],
                       check=True, capture_output=True)
        outputs.append((out / "leads.csv").read_bytes())
    assert outputs[0] != outputs[1]


# --- El manifiesto no miente -------------------------------------------------------

def test_el_manifiesto_cuenta_las_filas_que_existen(dataset):
    """La prueba que nació del bug de `ia04`: allí el manifiesto decía veinticuatro
    documentos y en disco había ocho, porque dos plantillas colisionaban de nombre."""
    for name, expected in dataset["manifiesto"]["filas"].items():
        assert len(dataset[name]) == expected, name


def test_el_manifiesto_declara_si_el_volumen_es_sintetico(dataset, tmp_path):
    assert dataset["manifiesto"]["sintetico"] is False
    out = tmp_path / "grande"
    subprocess.run([sys.executable, str(HERE / "generar_embudo.py"),
                    "--salida", str(out), "--escala", "3"],
                   check=True, capture_output=True)
    manifest = json.loads((out / "manifiesto.json").read_text("utf-8"))
    assert manifest["sintetico"] is True and manifest["escala"] == 3


def test_la_escala_multiplica_el_volumen(dataset, tmp_path):
    out = tmp_path / "x3"
    subprocess.run([sys.executable, str(HERE / "generar_embudo.py"),
                    "--salida", str(out), "--escala", "3"],
                   check=True, capture_output=True)
    grown = len(read_csv(out / "leads.csv"))
    assert 2.5 < grown / len(dataset["leads.csv"]) < 3.5


# --- Nada clínico, nada identificable ----------------------------------------------

def test_no_hay_ni_una_columna_clinica(dataset):
    """La §5 de la historia de Áurea es una frontera, no una recomendación: el análisis
    comercial no toca la historia clínica, y el conjunto ni siquiera la tiene."""
    forbidden = {"diagnostico", "procedimiento", "codigo", "documento", "cedula",
                 "nombre", "telefono", "correo", "direccion", "historia"}
    for name, rows in dataset.items():
        if not name.endswith(".csv"):
            continue
        assert not (set(rows[0]) & forbidden), f"{name}: {set(rows[0]) & forbidden}"


def test_los_identificadores_son_seudonimos(dataset):
    assert all(row["lead_id"].startswith("L") for row in dataset["leads.csv"])
    assert all(row["plan_id"].startswith("TP")
               for row in dataset["planes_de_tratamiento.csv"])


def test_ningun_campo_trae_comas_ni_comillas(dataset):
    """`write_csv` escribe sin escape. Esto es lo que hace legítimo ese atajo."""
    for name, rows in dataset.items():
        if not name.endswith(".csv"):
            continue
        for row in rows[:500]:
            for value in row.values():
                assert '"' not in value and "," not in value


# --- El embudo es un embudo --------------------------------------------------------

def test_las_etapas_van_en_orden_y_sin_saltos(dataset):
    """Un lead que aparece en `cotizacion` sin haber pasado por `valoracion_asistida`
    inventa conversiones y arruina cualquier tasa que ds04 calcule."""
    by_lead: dict[str, list[str]] = {}
    for row in dataset["etapas.csv"]:
        by_lead.setdefault(row["lead_id"], []).append(row["etapa"])
    for lead_id, reached in by_lead.items():
        assert reached == gen.STAGES[:len(reached)], lead_id


def test_ningun_evento_ocurre_despues_del_corte(dataset):
    """El conjunto es un export tomado el 2026-03-31, y un export no contiene el futuro.

    La primera versión de este generador dejaba etapas en agosto de 2026 y pagos en mayo,
    porque el reloj del embudo seguía corriendo después de la última fecha declarada. Nada
    fallaba: simplemente el conjunto sabía cosas que nadie podía saber, y el análisis de
    cohortes de `ds04` habría medido conversiones que todavía no han ocurrido.
    """
    limit = gen.END.isoformat()
    for row in dataset["etapas.csv"]:
        assert row["fecha_hora"][:10] <= limit
    for row in dataset["toques.csv"]:
        assert row["fecha_hora"][:10] <= limit
    for row in dataset["planes_de_tratamiento.csv"]:
        assert row["fecha_aceptacion"] <= limit
    for row in dataset["cuotas.csv"]:
        assert row["fecha_programada"] <= limit
        assert not row["fecha_pago"] or row["fecha_pago"] <= limit


def test_hay_leads_censurados_por_la_derecha(dataset):
    """La consecuencia del corte, y es contenido de `ds04`: los leads recientes todavía no
    terminaron su recorrido. Si no hubiera ninguno, el corte no estaría haciendo nada."""
    reached = {row["lead_id"] for row in dataset["etapas.csv"]
               if row["etapa"] == "primera_cuota"}
    recent = [row for row in dataset["leads.csv"] if row["creado"] >= "2026-03-01"]
    assert recent
    assert sum(row["lead_id"] in reached for row in recent) / len(recent) < 0.20


def test_las_etapas_avanzan_en_el_tiempo(dataset):
    by_lead: dict[str, list[datetime]] = {}
    for row in dataset["etapas.csv"]:
        by_lead.setdefault(row["lead_id"], []).append(
            datetime.fromisoformat(row["fecha_hora"]))
    for lead_id, moments in by_lead.items():
        assert moments == sorted(moments), lead_id


def test_cada_etapa_convierte_menos_que_la_anterior(dataset):
    counts = Counter(row["etapa"] for row in dataset["etapas.csv"])
    volumes = [counts[stage] for stage in gen.STAGES]
    assert volumes == sorted(volumes, reverse=True), volumes


def test_todo_plan_viene_de_un_lead_que_lo_acepto(dataset):
    accepted = {row["lead_id"] for row in dataset["etapas.csv"]
                if row["etapa"] == "plan_aceptado"}
    from_plans = {row["lead_id"] for row in dataset["planes_de_tratamiento.csv"]}
    assert from_plans == accepted


# --- Las tesis que el conjunto tiene que sostener ----------------------------------

def test_las_dos_atribuciones_no_dan_la_misma_respuesta(dataset):
    """La tesis de ds04. Si el primer toque y el último coincidieran, el capítulo se
    quedaría sin su demostración y habría que inventarla, que es justo lo que no se hace."""
    first = Counter(row["canal_primer_toque"] for row in dataset["leads.csv"])
    last = Counter(row["canal_ultimo_toque"] for row in dataset["leads.csv"])
    total = len(dataset["leads.csv"])
    gap = abs(first["tiktok"] - last["tiktok"]) / total
    assert gap > 0.10, f"TikTok apenas se mueve entre atribuciones: {gap:.1%}"


def test_tiktok_trae_volumen_y_convierte_menos(dataset):
    """La sospecha de Marcela, que ds04 tiene que poder confirmar con datos propios."""
    accepted = {row["lead_id"] for row in dataset["etapas.csv"]
                if row["etapa"] == "plan_aceptado"}
    rates = {}
    for channel in ("tiktok", "google"):
        pool = [row for row in dataset["leads.csv"]
                if row["canal_ultimo_toque"] == channel]
        rates[channel] = sum(row["lead_id"] in accepted for row in pool) / len(pool)
    assert rates["tiktok"] < rates["google"]


def test_tiktok_cierra_mas_lento(dataset):
    """La creencia de Julián: convierte, pero tarda. También tiene que estar en los datos."""
    created = {row["lead_id"]: date.fromisoformat(row["creado"])
               for row in dataset["leads.csv"]}
    channel = {row["lead_id"]: row["canal_ultimo_toque"] for row in dataset["leads.csv"]}
    lags = {"tiktok": [], "google": []}
    for row in dataset["etapas.csv"]:
        if row["etapa"] != "plan_aceptado":
            continue
        which = channel[row["lead_id"]]
        if which in lags:
            lags[which].append(
                (date.fromisoformat(row["fecha_hora"][:10]) - created[row["lead_id"]]).days)
    assert median(lags["tiktok"]) > median(lags["google"])


def median(values: list[int]) -> float:
    ordered = sorted(values)
    mid = len(ordered) // 2
    return ordered[mid] if len(ordered) % 2 else (ordered[mid - 1] + ordered[mid]) / 2


def test_enero_y_febrero_son_de_ortodoncia_y_diciembre_de_estetica(dataset):
    counts: Counter = Counter()
    for row in dataset["leads.csv"]:
        counts[(date.fromisoformat(row["creado"]).month, row["interes"])] += 1
    assert counts[(1, "ortodoncia")] > counts[(6, "ortodoncia")] * 1.5
    assert counts[(12, "estetica")] > counts[(6, "estetica")] * 1.4


def test_la_semana_santa_es_un_agujero(dataset):
    """2024, 2025 y 2026 tienen la Pascua en fechas distintas; el agujero se mueve con ella."""
    per_day: Counter = Counter()
    for row in dataset["leads.csv"]:
        per_day[date.fromisoformat(row["creado"])] += 1
    for year in (2024, 2025, 2026):
        start, end = gen.holy_week(year)
        if end > gen.END:
            continue
        inside = [per_day[day] for day in per_day if start <= day <= end]
        outside = [count for day, count in per_day.items()
                   if day.year == year and not start <= day <= end]
        assert sum(inside) / len(inside) < sum(outside) / len(outside) * 0.6


def test_la_pascua_cae_donde_debe():
    """El algoritmo se comprueba contra fechas conocidas, no contra sí mismo."""
    assert gen.easter_sunday(2024) == date(2024, 3, 31)
    assert gen.easter_sunday(2025) == date(2025, 4, 20)
    assert gen.easter_sunday(2026) == date(2026, 4, 5)


# --- El dinero ---------------------------------------------------------------------

def test_el_ingreso_llega_repartido_en_veinticuatro_meses(dataset):
    """La trampa contable de la §8: aceptar un plan no es cobrarlo."""
    per_plan = Counter(row["plan_id"] for row in dataset["cuotas.csv"])
    old_plans = [row for row in dataset["planes_de_tratamiento.csv"]
                 if date.fromisoformat(row["fecha_aceptacion"]) < date(2024, 3, 1)]
    assert old_plans, "hace falta al menos un plan viejo para ver el calendario completo"
    assert all(per_plan[row["plan_id"]] == gen.INSTALLMENTS for row in old_plans)


def test_el_valor_del_plan_esta_en_el_rango_de_la_historia(dataset):
    """Entre ocho y veintidós millones. Es un dato del negocio, no una escala libre."""
    values = [int(row["valor_total_cop"])
              for row in dataset["planes_de_tratamiento.csv"]]
    assert 8_000_000 <= min(values) and max(values) <= 22_000_000


def test_hay_planes_abandonados_y_se_distinguen_de_los_atrasados(dataset):
    """Pagar tarde y dejar de pagar son cosas distintas, y las dos tienen que existir."""
    unpaid: Counter = Counter()
    late = 0
    for row in dataset["cuotas.csv"]:
        if not row["fecha_pago"]:
            unpaid[row["plan_id"]] += 1
        elif row["fecha_pago"] > row["fecha_programada"]:
            late += 1
    assert unpaid, "ningún plan abandonado"
    assert late > len(dataset["cuotas.csv"]) * 0.2, "nadie paga tarde: irreal"


def test_solo_los_canales_pagos_aparecen_en_la_pauta(dataset):
    spent = {row["canal"] for row in dataset["pauta.csv"]}
    assert spent == set(gen.PAID_CHANNELS)


def test_el_referido_no_trae_campana(dataset):
    """Un dato ausente se deja ausente. Rellenarlo con 'ninguna' lo vuelve un dato falso."""
    for row in dataset["toques.csv"]:
        if row["canal"] in gen.FREE_CHANNELS:
            assert row["campana"] == ""


# --- La red de aliados -------------------------------------------------------------

def test_son_veintitres_aliados(dataset):
    assert len(dataset["aliados.csv"]) == 23


def test_la_zona_y_la_especialidad_no_son_la_misma_particion(dataset):
    """Nacieron las dos del índice del aliado y quedaban perfectamente correlacionadas: con
    veintitrés aliados, `i % 5` y `(i * 3) % 5` parten el conjunto igual. Agrupar por zona o
    por especialidad daba la misma tabla, y `ds04` se quedaba sin poder preguntar si el
    problema es el aliado o el caso que se le remite."""
    pairs = {(row["especialidad"], row["zona"]) for row in dataset["aliados.csv"]}
    by_specialty: dict[str, set[str]] = {}
    for specialty, zone in pairs:
        by_specialty.setdefault(specialty, set()).add(zone)
    assert any(len(zones) > 1 for zones in by_specialty.values())


def test_cada_remision_apunta_a_un_aliado_que_existe(dataset):
    known = {row["aliado_id"] for row in dataset["aliados.csv"]}
    assert {row["aliado_id"] for row in dataset["remisiones.csv"]} <= known


def test_los_aliados_se_distinguen_entre_si(dataset):
    """Si todos los aliados rinden igual, la pregunta de Marcela no tiene respuesta
    posible y la sección de ds04 que la contesta se queda sin datos."""
    returned: dict[str, list[int]] = {}
    for row in dataset["remisiones.csv"]:
        returned.setdefault(row["aliado_id"], []).append(int(row["volvio"]))
    rates = [sum(values) / len(values) for values in returned.values() if len(values) > 30]
    assert max(rates) - min(rates) > 0.10


# --- La estacionalidad como función pura -------------------------------------------

def test_la_estacionalidad_no_depende_del_azar():
    """Es una función pura y conviene que siga siéndolo: ds04 la va a citar."""
    assert gen.seasonality(date(2026, 1, 15), "ortodoncia") > 1.5
    assert gen.seasonality(date(2026, 12, 15), "estetica") > 1.5
    assert gen.seasonality(date(2026, 4, 1), "ortodoncia") < 0.5   # Semana Santa 2026


def test_el_generador_no_usa_el_random_global():
    """Un `random.seed()` global convierte cualquier `import` en un efecto secundario.
    El camino base lo usa porque sus scripts son de un solo uso; este alimenta seis
    secciones y una suite de pruebas, así que lleva su propia instancia."""
    random.seed(1)
    before = random.random()
    gen.build_partners(random.Random(7), [])
    random.seed(1)
    assert random.random() == before
