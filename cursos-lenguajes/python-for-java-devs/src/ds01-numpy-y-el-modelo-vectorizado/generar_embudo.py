"""Genera el conjunto de datos del Embudo de Áurea: pauta, toques, leads, etapas,
planes de tratamiento, cuotas y la red de aliados.

    python generar_embudo.py --salida data --semilla 20260913
    python generar_embudo.py --salida data --escala 60      # ← sintético, ver abajo

Mismo criterio que los generadores del camino base: **semilla fija**, salida reproducible
byte a byte, solo biblioteca estándar y **cero datos clínicos**. Lo que produce son
registros comerciales —gasto de pauta, contactos, etapas del embudo y pagos—, que es
justo lo que el análisis del Embudo necesita y lo único que la §5 de la historia de Áurea
deja salir de la sede.

Lo usan seis secciones: `ds01` a `ds06`. Por eso el esquema se congela aquí y ninguna de
ellas lo amplía por su cuenta: si una columna cambia, cambian seis capítulos.

⚠️ **El factor de escala produce filas que Áurea no tiene.** La red hace 3.900 citas al
mes y, a escala 1, el archivo más grande de aquí ronda las 80.000 filas. La medición de
`ds01` necesita un tercer tamaño de millones de filas para encontrar el umbral donde el
bucle deja de servir, y ese tamaño **es sintético y se declara como tal** en la sección:
multiplicar la ficción hasta que dé cinco millones sería mentir sobre el negocio para
que cuadre el benchmark. `manifiesto.json` deja escrita la escala con la que se generó.

⚠️ **La atribución es ambigua a propósito, no por descuido.** Cada lead trae entre uno y
cuatro toques de canales distintos, con el descubrimiento sesgado hacia TikTok e
Instagram y la decisión hacia Google y el referido. Por construcción, la atribución al
primer toque y la del último **no dan la misma respuesta**, que es exactamente la tesis
de `ds04`. Lo que el generador NO hace es decidir cuál de las dos tiene razón.
"""

from __future__ import annotations

import argparse
import json
import random
from datetime import date, datetime, timedelta
from pathlib import Path

# --- El dominio -------------------------------------------------------------------

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]

# Los tres canales pagos son los únicos que aparecen en `pauta.csv`: los otros tres no
# cuestan pauta, y esa asimetría es media lección de ds04 —el costo por paciente
# adquirido de un canal sin gasto no es cero, es "no medido por aquí"—.
PAID_CHANNELS = ["instagram", "tiktok", "google"]
FREE_CHANNELS = ["referido", "aliado", "walk_in"]
CHANNELS = PAID_CHANNELS + FREE_CHANNELS

# Cada campaña pertenece a un canal y a un interés. Los nombres son los que usaría
# Marcela, no identificadores: viajan como dato, no como código.
CAMPAIGNS = [
    ("instagram", "ortodoncia", "ig-brackets-adolescente"),
    ("instagram", "estetica", "ig-diseno-de-sonrisa"),
    ("tiktok", "ortodoncia", "tt-antes-y-despues"),
    ("tiktok", "estetica", "tt-carillas-15s"),
    ("google", "ortodoncia", "sem-ortodoncia-bogota"),
    ("google", "estetica", "sem-diseno-sonrisa-precio"),
]

INTERESTS = ["ortodoncia", "estetica"]

# Las seis etapas del embudo, en orden. Un lead avanza hasta donde llegue y se detiene:
# no hay saltos, y eso hay que poder comprobarlo (lo comprueba test_generar_embudo.py).
STAGES = ["mensaje", "valoracion_agendada", "valoracion_asistida",
          "cotizacion", "plan_aceptado", "primera_cuota"]

# Probabilidad de pasar de una etapa a la siguiente, por canal. TikTok trae volumen y se
# cae temprano; el referido y el aliado llegan casi decididos. Es la intuición de Marcela
# y Julián puesta en números —y el curso la va a medir, no a repetir—.
STAGE_ODDS = {
    "tiktok":    [0.34, 0.55, 0.62, 0.70, 0.46, 0.88],
    "instagram": [0.46, 0.62, 0.71, 0.75, 0.55, 0.90],
    "google":    [0.58, 0.71, 0.78, 0.80, 0.62, 0.92],
    "referido":  [0.72, 0.83, 0.88, 0.86, 0.74, 0.95],
    "aliado":    [0.80, 0.86, 0.90, 0.88, 0.78, 0.96],
    "walk_in":   [1.00, 0.90, 0.95, 0.82, 0.66, 0.93],
}

# Días que tarda cada canal en cerrar, de primer toque a plan aceptado. Julián cree que
# TikTok sí convierte, pero más lento; el dato existe para que ds04 pueda darle la razón
# o quitársela con la mediana en la mano.
LAG_DAYS = {
    "tiktok": (21, 96), "instagram": (12, 61), "google": (5, 34),
    "referido": (4, 25), "aliado": (3, 18), "walk_in": (0, 9),
}

# Costo por mil impresiones y tasa de clic, por canal. Números de orden de magnitud
# colombiano en 2024-2026, no una cotización: sirven para que el costo por paciente
# adquirido salga en un rango creíble.
CPM_COP = {"instagram": 18_000, "tiktok": 9_500, "google": 26_000}
CTR = {"instagram": 0.012, "tiktok": 0.021, "google": 0.038}

# Valor del plan, en pesos. La historia dice entre ocho y veintidós millones.
PLAN_VALUE_COP = {"ortodoncia": (8_000_000, 14_500_000),
                  "estetica": (11_000_000, 22_000_000)}

INSTALLMENTS = 24          # el ingreso llega en cuotas durante veinticuatro meses

SPECIALTIES = ["endodoncia", "periodoncia", "cirugia_oral", "odontopediatria", "protesis"]
ZONES = ["norte", "centro", "occidente", "sur", "sabana"]

START = date(2024, 1, 1)
END = date(2026, 3, 31)


# --- Estacionalidad ---------------------------------------------------------------

def easter_sunday(year: int) -> date:
    """Domingo de Pascua por el algoritmo gregoriano anónimo.

    Se calcula en vez de escribirse a mano porque la Semana Santa se mueve y el
    conjunto cubre tres años. Una tabla de tres fechas copiadas es justo la clase de
    dato que envejece mal y que nadie vuelve a revisar.
    """
    a, b, c = year % 19, year // 100, year % 100
    d, e = b // 4, b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    lunar = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * lunar) // 451
    month = (h + lunar - 7 * m + 114) // 31
    day = ((h + lunar - 7 * m + 114) % 31) + 1
    return date(year, month, day)


def holy_week(year: int) -> tuple[date, date]:
    """Domingo de Ramos a Domingo de Pascua: la semana en que Áurea no vende nada."""
    easter = easter_sunday(year)
    return easter - timedelta(days=6), easter


def seasonality(day: date, interest: str) -> float:
    """Multiplicador de demanda del día. Es el regalo didáctico de la §8 de la historia.

    La ortodoncia adolescente se dispara con el regreso a clases; el diseño de sonrisa,
    con la prima de fin de año y los matrimonios. La Semana Santa es un agujero para los
    dos, y ninguna otra cosa del conjunto lo explica: si un análisis de ds04 no la ve,
    es que no está mirando.
    """
    start, end = holy_week(day.year)
    if start <= day <= end:
        return 0.30

    if interest == "ortodoncia":
        factor = {1: 1.95, 2: 1.60, 3: 1.15, 11: 0.80, 12: 0.65}.get(day.month, 1.0)
    else:
        factor = {11: 1.70, 12: 1.85, 1: 0.75, 2: 0.85}.get(day.month, 1.0)

    if day.weekday() == 6:        # domingo: la red no atiende, y la pauta rinde menos
        factor *= 0.45
    return factor


# --- Generación -------------------------------------------------------------------

def each_day(start: date, end: date):
    day = start
    while day <= end:
        yield day
        day += timedelta(days=1)


def build_spend(rng: random.Random, scale: int) -> list[dict]:
    """Gasto diario de pauta, por campaña y sede. Una fila por día, campaña y sede."""
    rows = []
    for day in each_day(START, END):
        for channel, interest, campaign in CAMPAIGNS:
            factor = seasonality(day, interest)
            for branch in BRANCHES:
                # Las sedes propias pautan más que las franquiciadas, que aportan a un
                # fondo común y deciden poco. Es una decisión de negocio, no ruido.
                weight = 1.4 if branch in BRANCHES[:4] else 0.8
                budget = rng.uniform(45_000, 190_000) * factor * weight * scale
                impressions = int(budget / CPM_COP[channel] * 1000)
                clicks = int(impressions * CTR[channel] * rng.uniform(0.75, 1.3))
                rows.append({
                    "fecha": day.isoformat(), "canal": channel, "campana": campaign,
                    "interes": interest, "sede": branch,
                    "impresiones": impressions, "clics": clicks,
                    "costo_cop": int(budget),
                })
    return rows


def pick_first_channel(rng: random.Random) -> str:
    """El canal del descubrimiento. Sesgado a lo que la gente ve sin buscarlo."""
    return rng.choices(CHANNELS, [30, 38, 11, 9, 8, 4])[0]


def pick_last_channel(rng: random.Random, first: str) -> str:
    """El canal de la decisión. Sesgado a lo que la gente usa cuando ya decidió.

    El sesgo opuesto al del primer toque es el motor de ds04: con estos dos pesos, la
    atribución al primer toque y la del último discrepan sobre TikTok por construcción.
    """
    candidates = [c for c in CHANNELS if c != first]
    weights = {"google": 34, "referido": 21, "instagram": 18,
               "aliado": 13, "tiktok": 9, "walk_in": 5}
    return rng.choices(candidates, [weights[c] for c in candidates])[0]


def build_leads(rng: random.Random, scale: int):
    """Leads, sus toques y sus etapas. Devuelve las tres listas ya alineadas.

    Se generan juntos porque comparten el reloj: un toque no puede ser posterior a la
    etapa que lo sigue, y separarlos en tres funciones que sortean fechas por su cuenta
    es la receta para un conjunto incoherente que nadie nota hasta ds04.
    """
    leads, touches, stages = [], [], []
    lead_number = 0

    for day in each_day(START, END):
        for interest in INTERESTS:
            factor = seasonality(day, interest)
            for _ in range(int(rng.uniform(14, 26) * factor * scale)):
                lead_number += 1
                lead_id = f"L{lead_number:07d}"
                branch = rng.choice(BRANCHES)

                first = pick_first_channel(rng)
                last = first if rng.random() < 0.38 else pick_last_channel(rng, first)
                middle = [rng.choice(CHANNELS)
                          for _ in range(rng.choices([0, 1, 2], [58, 30, 12])[0])]
                path = [first, *middle, last] if last != first else [first]

                low, high = LAG_DAYS[last]
                window = rng.randint(low, high)
                moments = sorted(rng.uniform(0, window) for _ in path)
                for order, (channel, offset) in enumerate(zip(path, moments, strict=True),
                                                          start=1):
                    when = datetime.combine(day, datetime.min.time()) + timedelta(
                        days=offset, hours=rng.uniform(7, 22))
                    # El conjunto es un export tomado el `END`, y un export no contiene el
                    # futuro. Un lead creado en marzo todavía no ha terminado su recorrido:
                    # sus toques y etapas posteriores al corte **no existen todavía**, y
                    # dejarlos dentro le daría al análisis de cohortes de `ds04` un dato que
                    # nadie podía tener. Esto es censura por la derecha, y es real.
                    if when.date() > END:
                        break
                    touches.append({
                        "lead_id": lead_id, "orden": order,
                        "fecha_hora": when.isoformat(timespec="seconds"),
                        "canal": channel,
                        # La campaña solo existe si el canal es pago: un referido no
                        # tiene campaña, y rellenar ese hueco con "ninguna" convierte
                        # un dato ausente en un dato falso.
                        "campana": next((c for ch, it, c in CAMPAIGNS
                                         if ch == channel and it == interest), ""),
                        "sede": branch,
                    })

                leads.append({
                    "lead_id": lead_id, "creado": day.isoformat(), "sede": branch,
                    "interes": interest, "canal_primer_toque": first,
                    "canal_ultimo_toque": last, "toques": len(path),
                })

                # El avance por el embudo, etapa por etapa, con el reloj del último toque
                # **que de verdad ocurrió** antes del corte.
                clock = datetime.combine(day, datetime.min.time()) + timedelta(
                    days=moments[-1], hours=rng.uniform(8, 19))
                for stage, odds in zip(STAGES, STAGE_ODDS[last], strict=True):
                    if rng.random() > odds:
                        break
                    clock += timedelta(days=rng.uniform(0.2, window / 3 + 1))
                    if clock.date() > END:      # todavía no ha pasado: ver el comentario de arriba
                        break
                    stages.append({
                        "lead_id": lead_id, "etapa": stage,
                        "fecha_hora": clock.isoformat(timespec="seconds"),
                    })

    return leads, touches, stages


def build_plans(rng: random.Random, leads, stages):
    """Planes de tratamiento y sus cuotas, para los leads que llegaron a `plan_aceptado`.

    Aquí vive la trampa contable de la §8: el plan se acepta en un mes y el dinero entra
    durante veinticuatro. Quien sume `valor_total_cop` por mes de aceptación y lo llame
    "ventas del mes" tiene una cifra que no significa lo que parece.
    """
    accepted = {row["lead_id"]: row["fecha_hora"]
                for row in stages if row["etapa"] == "plan_aceptado"}
    by_id = {row["lead_id"]: row for row in leads}

    plans, installments = [], []
    for number, (lead_id, when) in enumerate(sorted(accepted.items()), start=1):
        lead = by_id[lead_id]
        plan_id = f"TP{number:06d}"
        low, high = PLAN_VALUE_COP[lead["interes"]]
        total = int(rng.uniform(low, high) / 10_000) * 10_000
        accepted_on = date.fromisoformat(when[:10])

        plans.append({
            "plan_id": plan_id, "lead_id": lead_id, "sede": lead["sede"],
            "interes": lead["interes"], "fecha_aceptacion": accepted_on.isoformat(),
            "valor_total_cop": total, "cuotas": INSTALLMENTS,
        })

        # Uno de cada once planes se abandona a mitad de camino. Es el paciente del mes
        # ocho de veinticuatro que se desaparece con los brackets puestos, y es la otra
        # predicción cara de la §8 de la historia.
        abandons_at = rng.randint(5, 21) if rng.random() < 0.09 else INSTALLMENTS + 1
        value = total // INSTALLMENTS

        for index in range(1, INSTALLMENTS + 1):
            due = accepted_on + timedelta(days=30 * (index - 1))
            if due > END:
                break
            if index >= abandons_at:
                paid = ""
            else:
                # Pagar tarde es lo normal; no pagar es otra cosa. El curso necesita las
                # dos, y distinguirlas es trabajo de ds04, no del generador.
                paid_on = due + timedelta(days=int(rng.expovariate(1 / 6)))
                # Y un pago posterior al corte es un pago que hoy no ha ocurrido: la cuota
                # aparece impaga, que es exactamente lo que vería Yuli el día del export.
                paid = paid_on.isoformat() if paid_on <= END else ""
            installments.append({
                "plan_id": plan_id, "numero": index,
                "fecha_programada": due.isoformat(), "fecha_pago": paid,
                "valor_cop": value,
            })
    return plans, installments


def build_partners(rng: random.Random, leads):
    """Los veintitrés aliados y sus remisiones, con la comisión y el paciente que volvió.

    Es la segunda pregunta de plata de la §8: ingreso por comisiones contra pacientes que
    no volvieron, por aliado, por especialidad y por zona.
    """
    # La especialidad se reparte en orden y la zona **se sortea**. Con las dos derivadas del
    # índice —`SPECIALTIES[i % 5]` y `ZONES[(i * 3) % 5]`— quedaban perfectamente
    # correlacionadas sobre veintitrés aliados, y agrupar por una o por otra daba exactamente
    # la misma tabla. Eso no es una propiedad de Áurea: es aritmética modular, y le habría
    # quitado el sentido a la pregunta de `ds04` sobre si el problema es el aliado o la
    # especialidad que se le remite.
    partners = [{
        "aliado_id": f"A{index:03d}",
        "especialidad": SPECIALTIES[index % len(SPECIALTIES)],
        "zona": rng.choice(ZONES),
        "comision_pct": round(rng.uniform(0.06, 0.14), 3),
        "desde": (START + timedelta(days=rng.randint(0, 400))).isoformat(),
    } for index in range(1, 24)]

    referrals = []
    for lead in leads:
        if lead["canal_primer_toque"] != "aliado":
            continue
        partner = rng.choice(partners)
        fee = int(rng.uniform(180_000, 720_000) / 1000) * 1000
        referrals.append({
            "aliado_id": partner["aliado_id"], "lead_id": lead["lead_id"],
            "fecha": lead["creado"], "zona": partner["zona"],
            "especialidad": partner["especialidad"],
            # Que el paciente vuelva depende del aliado, y ese es el número que Marcela
            # necesita para sostener —o desmentir— la decisión que ya tomó con dos de ellos.
            "volvio": int(rng.random() < 0.30 + 0.5 * partner["comision_pct"]),
            "comision_cop": fee,
        })
    return partners, referrals


# --- Salida -----------------------------------------------------------------------

def write_csv(path: Path, rows: list[dict]) -> None:
    """Escribe el CSV a mano, sin `csv`, para que la salida sea byte a byte reproducible.

    Ninguna columna de este conjunto lleva comas ni comillas —las campañas y las sedes
    son identificadores, no texto libre—, así que el escape no hace falta y su ausencia
    es verificable: `test_generar_embudo.py` lo comprueba en vez de confiar.
    """
    header = list(rows[0])
    with path.open("w", encoding="utf-8", newline="\n") as file:
        file.write(",".join(header) + "\n")
        for row in rows:
            file.write(",".join(str(row[column]) for column in header) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera el conjunto del Embudo de Áurea.")
    parser.add_argument("--salida", type=Path, default=Path("data"))
    parser.add_argument("--semilla", type=int, default=20260913)
    parser.add_argument("--escala", type=int, default=1,
                        help="Multiplica el volumen. Por encima de 1 los datos son "
                             "sintéticos y la sección que los use tiene que decirlo.")
    args = parser.parse_args()

    rng = random.Random(args.semilla)
    args.salida.mkdir(parents=True, exist_ok=True)

    spend = build_spend(rng, args.escala)
    leads, touches, stages = build_leads(rng, args.escala)
    plans, installments = build_plans(rng, leads, stages)
    partners, referrals = build_partners(rng, leads)

    tables = {
        "pauta.csv": spend,
        "leads.csv": leads,
        "toques.csv": touches,
        "etapas.csv": stages,
        "planes_de_tratamiento.csv": plans,
        "cuotas.csv": installments,
        "aliados.csv": partners,
        "remisiones.csv": referrals,
    }
    for name, rows in tables.items():
        write_csv(args.salida / name, rows)

    # El manifiesto es el contrato del conjunto, y tiene que decir la verdad: en el track
    # `ia` un generador con colisión de nombres dejó veinticuatro documentos en ocho
    # archivos y el manifiesto siguió diciendo veinticuatro. Aquí las cifras se cuentan
    # de las filas que se escribieron, no de las que se pensaban escribir.
    manifest = {
        "semilla": args.semilla,
        "escala": args.escala,
        "sintetico": args.escala > 1,
        "desde": START.isoformat(),
        "hasta": END.isoformat(),
        "filas": {name: len(rows) for name, rows in tables.items()},
        "etapas": STAGES,
        "canales": CHANNELS,
        "canales_pagos": PAID_CHANNELS,
    }
    (args.salida / "manifiesto.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    for name, rows in tables.items():
        print(f"{args.salida / name}: {len(rows):,} filas")
    if args.escala > 1:
        print(f"⚠️  escala {args.escala}: este volumen NO es el de Áurea. Decláralo.")


if __name__ == "__main__":
    main()
