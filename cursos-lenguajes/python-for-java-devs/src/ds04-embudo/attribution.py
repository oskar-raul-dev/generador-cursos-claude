"""Atribución de marketing: a quién se le acredita un paciente adquirido.

    from attribution import load_journeys, credit, cost_per_acquisition

Cuatro modelos sobre **los mismos datos**, que dan cuatro respuestas distintas a la
pregunta de Marcela: *¿cuánto me cuesta un paciente por canal?* Ninguno es el correcto.
Esa es la tesis de la sección y el motivo de que estén los cuatro.

🧭 **La regla que ordena el módulo: un modelo de atribución es un reparto, y todo reparto
suma uno.** Cada paciente adquirido reparte exactamente un crédito entre los canales que lo
tocaron. Si un modelo suma más de uno, está contando pacientes que no existen — y es
exactamente lo que hacen los tableros de las plataformas de pauta, cada una acreditándose la
misma conversión.
"""

from __future__ import annotations

import csv
from collections import defaultdict
from datetime import date, datetime, timedelta
from pathlib import Path

# Lo que tarda el canal más lento —TikTok— en cerrar, de primer toque a plan aceptado. Un
# lead creado después de `END - MATURITY` todavía puede convertir, así que incluirlo en el
# denominador **sin haber esperado su recorrido** lo cuenta como fracaso.
MATURITY = timedelta(days=96)

# Vida media del modelo de decaimiento, en días. No es un número universal: es el tiempo en
# que un toque pierde la mitad de su mérito, y se elige por negocio. Catorce días para una
# compra que se piensa dos meses es una decisión discutible, y por eso es un parámetro.
HALF_LIFE_DAYS = 14.0


def load_journeys(data: Path) -> dict[str, list[tuple[datetime, str]]]:
    """El recorrido de cada lead: sus toques en orden, con su canal.

    Se carga entero en memoria porque son decenas de miles de leads y cabe. A la escala de
    `ds03` esto sería un `scan_csv`; aquí la claridad gana, y la sección 6 dice cuánto
    cuesta esa decisión.
    """
    journeys: dict[str, list[tuple[datetime, str]]] = defaultdict(list)
    with (data / "toques.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            journeys[row["lead_id"]].append(
                (datetime.fromisoformat(row["fecha_hora"]), row["canal"]))
    for touches in journeys.values():
        touches.sort()
    return dict(journeys)


def load_acquisitions(data: Path) -> dict[str, date]:
    """Los leads que llegaron a `plan_aceptado`, con la fecha en que lo aceptaron."""
    with (data / "etapas.csv").open(encoding="utf-8", newline="") as file:
        return {row["lead_id"]: date.fromisoformat(row["fecha_hora"][:10])
                for row in csv.DictReader(file) if row["etapa"] == "plan_aceptado"}


def load_lead_branches(data: Path) -> dict[str, str]:
    with (data / "leads.csv").open(encoding="utf-8", newline="") as file:
        return {row["lead_id"]: row["sede"] for row in csv.DictReader(file)}


def load_lead_created(data: Path) -> dict[str, date]:
    with (data / "leads.csv").open(encoding="utf-8", newline="") as file:
        return {row["lead_id"]: date.fromisoformat(row["creado"])
                for row in csv.DictReader(file)}


def load_spend(data: Path, until: date | None = None) -> dict[str, int]:
    """Gasto de pauta por canal, hasta `until` inclusive. Solo hay tres canales pagos.

    ⚠️ **`until` no es un adorno: es lo que hace comparable el cociente.** Si el denominador
    se recorta a los leads maduros —los creados hasta `corte - MATURITY`— y el numerador se
    queda con el gasto de todo el período, el costo por adquisición sale inflado por la
    pauta de unas semanas que todavía no pudo producir a nadie. La primera versión de este
    módulo tenía ese error y hacía que el filtro de madurez **empeorara** el número de
    TikTok en vez de mejorarlo, que era justo al revés de lo que decía el texto.
    """
    spend: defaultdict[str, int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            if until is None or date.fromisoformat(row["fecha"]) <= until:
                spend[row["canal"]] += int(row["costo_cop"])
    return dict(spend)


def load_spend_by_branch(data: Path,
                         until: date | None = None) -> dict[tuple[str, str], int]:
    spend: defaultdict[tuple[str, str], int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            if until is None or date.fromisoformat(row["fecha"]) <= until:
                spend[(row["canal"], row["sede"])] += int(row["costo_cop"])
    return dict(spend)


# --- Los cuatro modelos -------------------------------------------------------------
#
# Cada uno recibe el recorrido de un lead y devuelve cuánto crédito le toca a cada canal.
# Todos suman exactamente 1.0, y hay una prueba que lo comprueba para los cuatro sobre
# todos los recorridos del conjunto.

def credit_first(touches: list[tuple[datetime, str]]) -> dict[str, float]:
    """Todo el mérito al descubrimiento. Favorece a quien genera demanda."""
    return {touches[0][1]: 1.0}


def credit_last(touches: list[tuple[datetime, str]]) -> dict[str, float]:
    """Todo el mérito al último toque. Es el modelo por defecto de casi todas las
    plataformas, y el que `ds01` usó sin decir que elegía."""
    return {touches[-1][1]: 1.0}


def credit_linear(touches: list[tuple[datetime, str]]) -> dict[str, float]:
    """Reparto igual entre todos los toques. El más ingenuo y el más difícil de discutir."""
    share = 1.0 / len(touches)
    credits: defaultdict[str, float] = defaultdict(float)
    for _, channel in touches:
        credits[channel] += share
    return dict(credits)


def credit_time_decay(touches: list[tuple[datetime, str]],
                      half_life_days: float = HALF_LIFE_DAYS) -> dict[str, float]:
    """Cuanto más cerca del cierre, más mérito, con decaimiento exponencial.

    Es el único de los cuatro que usa **cuándo** ocurrió cada toque y no solo su orden, y
    por eso es el que más se acerca a lo que la gente cree que mide un tablero.
    """
    closing = touches[-1][0]
    weights = [0.5 ** ((closing - when).total_seconds() / 86400 / half_life_days)
               for when, _ in touches]
    total = sum(weights)
    credits: defaultdict[str, float] = defaultdict(float)
    for weight, (_, channel) in zip(weights, touches, strict=True):
        credits[channel] += weight / total
    return dict(credits)


MODELS = {
    "primer toque": credit_first,
    "último toque": credit_last,
    "lineal": credit_linear,
    "decaimiento": credit_time_decay,
}


# --- Del crédito al costo -----------------------------------------------------------

def mature_leads(created: dict[str, date], cutoff: date,
                 maturity: timedelta = MATURITY) -> set[str]:
    """Los leads que tuvieron tiempo de recorrer el embudo entero antes del corte.

    ⚠️ Es la corrección que más cambia los números de esta sección. Un lead creado en marzo
    con el conjunto cortado el 31 de marzo **no ha fracasado**: no ha terminado. Meterlo en
    el denominador infla el costo por adquisición de los canales lentos —TikTok, que tarda
    hasta 96 días— y hace que la decisión de apagarlo parezca obvia cuando no lo es.
    """
    limit = cutoff - maturity
    return {lead for lead, day in created.items() if day <= limit}


def credit_by_channel(journeys: dict[str, list[tuple[datetime, str]]],
                      acquisitions: dict[str, date],
                      model, eligible: set[str] | None = None) -> dict[str, float]:
    """Crédito total por canal, sumando el reparto de cada paciente adquirido."""
    totals: defaultdict[str, float] = defaultdict(float)
    for lead in acquisitions:
        if eligible is not None and lead not in eligible:
            continue
        touches = journeys.get(lead)
        if not touches:
            continue
        for channel, share in model(touches).items():
            totals[channel] += share
    return dict(totals)


def cost_per_acquisition(spend: dict[str, int],
                         credits: dict[str, float]) -> dict[str, float]:
    """Costo por paciente adquirido, canal por canal.

    Solo se calcula para los canales con gasto conocido. El referido, el aliado y quien
    entra por la puerta **no tienen costo cero**: tienen un costo que esta fuente no mide
    —la comisión del aliado, el tiempo de la valoración gratuita— y devolver un cero ahí
    sería la mentira más cara del informe.
    """
    return {channel: spent / credits[channel]
            for channel, spent in sorted(spend.items()) if credits.get(channel)}


def bootstrap_interval(values: list[float], statistic, repetitions: int = 1000,
                       seed: int = 20260913,
                       confidence: float = 0.95) -> tuple[float, float]:
    """Intervalo por percentiles, remuestreando con reemplazo.

    Se usa bootstrap y no una fórmula cerrada porque el costo por adquisición es un cociente
    de dos cantidades que dependen del mismo conjunto de leads, y la fórmula del error
    estándar de una media no aplica. El precio es que hay que declarar la semilla: **el
    intervalo también es reproducible o no es un número del curso**.
    """
    import random

    rng = random.Random(seed)
    size = len(values)
    samples = sorted(statistic([values[rng.randrange(size)] for _ in range(size)])
                     for _ in range(repetitions))
    lower = samples[int((1 - confidence) / 2 * repetitions)]
    upper = samples[int((1 + confidence) / 2 * repetitions) - 1]
    return lower, upper


def share_of_credit(credits: dict[str, float]) -> dict[str, float]:
    """El reparto en porcentaje. Es la cifra que se compara entre modelos."""
    total = sum(credits.values())
    return {channel: value / total * 100 for channel, value in sorted(credits.items())}


def sanity_check(journeys, acquisitions, model, eligible=None) -> float:
    """Cuánto crédito reparte el modelo en total. Tiene que ser el número de pacientes.

    Es la comprobación que ningún tablero de plataforma pasa: si sumas lo que se acreditan
    Instagram, TikTok y Google por separado, te salen más pacientes de los que hubo.
    """
    return sum(credit_by_channel(journeys, acquisitions, model, eligible).values())
