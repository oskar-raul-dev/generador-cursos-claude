"""El embudo de Áurea: conversión por etapa, cohortes y estacionalidad.

    from funnel import stage_rates, cohort_conversion, seasonal_index

Tres cálculos que responden tres preguntas distintas de Marcela, y que se confunden entre
sí todo el tiempo:

- **¿Dónde se cae la gente?** → tasa de paso entre etapas, sobre el embudo completo.
- **¿Está mejorando?** → conversión por cohorte de creación, que es la única forma de
  comparar meses sin mezclar peras con manzanas.
- **¿Esto es una mejora o es enero?** → índice de estacionalidad.

La tercera pregunta es la que hunde más informes. Áurea vende ortodoncia adolescente: enero
y febrero son el doble que junio **todos los años**, y cualquier campaña lanzada en
diciembre va a parecer un éxito en enero.
"""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from datetime import date, timedelta
from pathlib import Path

STAGES = ["mensaje", "valoracion_agendada", "valoracion_asistida",
          "cotizacion", "plan_aceptado", "primera_cuota"]


def load_stage_reach(data: Path) -> dict[str, set[str]]:
    """Qué leads alcanzaron cada etapa."""
    reach: defaultdict[str, set[str]] = defaultdict(set)
    with (data / "etapas.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            reach[row["etapa"]].add(row["lead_id"])
    return dict(reach)


def stage_rates(reach: dict[str, set[str]],
                total_leads: int) -> list[tuple[str, int, float, float]]:
    """Etapa, cuántos llegaron, qué porcentaje del total y **qué porcentaje del anterior**.

    Las dos últimas columnas son distintas y se confunden siempre. La del total dice cuánto
    queda; la del paso dice **dónde se está cayendo la gente**, que es la accionable: un 92%
    al final del embudo no consuela si el paso anterior fue del 55%.
    """
    rows = []
    previous = total_leads
    for stage in STAGES:
        reached = len(reach.get(stage, ()))
        rows.append((stage, reached, reached / total_leads * 100,
                     reached / previous * 100 if previous else 0.0))
        previous = reached
    return rows


def cohort_conversion(created: dict[str, date], accepted: set[str], cutoff: date,
                      maturity: timedelta) -> dict[str, tuple[int, int, float, bool]]:
    """Conversión por mes de creación del lead, con su madurez declarada.

    ⚠️ **El último trimestre de cualquier informe de embudo está incompleto y parece malo.**
    Un lead de marzo puede tardar tres meses en aceptar; si se mide el 31 de marzo, cuenta
    como fracaso. La cuarta columna dice si la cohorte ya tuvo tiempo, y **la que no lo tuvo
    no se compara con las demás** — se muestra aparte o no se muestra.
    """
    limit = cutoff - maturity
    totals: Counter[str] = Counter()
    wins: Counter[str] = Counter()
    for lead, day in created.items():
        month = day.isoformat()[:7]
        totals[month] += 1
        if lead in accepted:
            wins[month] += 1

    return {month: (totals[month], wins[month], wins[month] / totals[month] * 100,
                    date.fromisoformat(f"{month}-01") <= limit)
            for month in sorted(totals)}


def seasonal_index(monthly: dict[str, float]) -> dict[int, float]:
    """Índice de estacionalidad: cuánto se desvía cada mes del promedio general.

    Es el cálculo más simple que sirve —la media de cada mes del calendario dividida por la
    media global— y se queda ahí a propósito. Para ver el pico de enero y el agujero de
    Semana Santa no hace falta descomponer una serie en tendencia, estacionalidad y ruido, y
    hacerlo aquí sería enseñar la herramienta antes que el problema.
    """
    by_month: defaultdict[int, list[float]] = defaultdict(list)
    for key, value in monthly.items():
        by_month[int(key[5:7])].append(value)
    total = sum(sum(values) for values in by_month.values())
    count = sum(len(values) for values in by_month.values())
    overall = total / count
    return {month: (sum(values) / len(values)) / overall
            for month, values in sorted(by_month.items())}


def leads_by_month(created: dict[str, date],
                   interest: dict[str, str] | None = None,
                   only: str | None = None) -> dict[str, float]:
    """Leads creados por mes, opcionalmente de un solo interés."""
    counts: Counter[str] = Counter()
    for lead, day in created.items():
        if only and interest and interest.get(lead) != only:
            continue
        counts[day.isoformat()[:7]] += 1
    return dict(counts)


def load_lead_interest(data: Path) -> dict[str, str]:
    with (data / "leads.csv").open(encoding="utf-8", newline="") as file:
        return {row["lead_id"]: row["interes"] for row in csv.DictReader(file)}


def holy_week_drop(created: dict[str, date], year: int,
                   easter: date) -> tuple[float, float]:
    """Leads por día dentro de la Semana Santa y fuera de ella, ese año.

    Se devuelve el par y no el cociente porque la división la hace quien escribe el informe,
    y conviene que vea los dos números: una semana de siete días contra cincuenta y una.
    """
    start, end = easter - timedelta(days=6), easter
    inside: Counter[date] = Counter()
    outside: Counter[date] = Counter()
    for day in created.values():
        if day.year != year:
            continue
        (inside if start <= day <= end else outside)[day] += 1
    return (sum(inside.values()) / max(len(inside), 1),
            sum(outside.values()) / max(len(outside), 1))
