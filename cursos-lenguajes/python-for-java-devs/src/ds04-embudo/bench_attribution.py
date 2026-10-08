"""Medición de la sección 6: el costo por paciente adquirido, según quién se lleve el mérito.

    uv run python bench_attribution.py --datos data --corte 2026-03-31

No mide tiempo. Mide **cuánto cambia la respuesta al negocio** según una decisión de método
que nadie discute porque viene puesta por defecto en el tablero de la plataforma.

El intervalo es bootstrap por percentiles sobre los pacientes adquiridos, con semilla fija.
Está aquí por una razón concreta: sin él, alguien puede decir que la diferencia entre dos
modelos es ruido de muestreo. Con él, se ve que los intervalos **ni se tocan**.
"""

from __future__ import annotations

import argparse
import random
from datetime import date
from pathlib import Path

from attribution import (
    MATURITY,
    MODELS,
    cost_per_acquisition,
    credit_by_channel,
    load_acquisitions,
    load_journeys,
    load_lead_created,
    load_spend,
    mature_leads,
    share_of_credit,
)

PAID = ("google", "instagram", "tiktok")


def cac_for(pool: list[str], journeys, model, spend: dict[str, int],
            channel: str) -> float:
    credited = sum(model(journeys[lead]).get(channel, 0.0) for lead in pool)
    return spend[channel] / credited if credited else float("nan")


def interval(pool: list[str], journeys, model, spend, channel: str,
             repetitions: int, seed: int) -> tuple[float, float]:
    """Percentiles 2,5 y 97,5 de remuestrear los pacientes con reemplazo."""
    rng = random.Random(seed)
    size = len(pool)
    samples = sorted(
        cac_for([pool[rng.randrange(size)] for _ in range(size)], journeys, model,
                spend, channel)
        for _ in range(repetitions))
    return samples[int(0.025 * repetitions)], samples[int(0.975 * repetitions) - 1]


def main() -> None:
    parser = argparse.ArgumentParser(description="Cuatro atribuciones, una sola verdad menos.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--corte", type=date.fromisoformat, default=date(2026, 3, 31))
    parser.add_argument("--remuestreos", type=int, default=200)
    parser.add_argument("--semilla", type=int, default=20260913)
    args = parser.parse_args()

    journeys = load_journeys(args.datos)
    acquisitions = load_acquisitions(args.datos)
    created = load_lead_created(args.datos)

    limit = args.corte - MATURITY
    mature = mature_leads(created, args.corte)
    # El numerador y el denominador cubren **la misma ventana**. Es la corrección que más
    # mueve los números de esta medición, y la que más fácil se olvida.
    spend = load_spend(args.datos, until=limit)
    pool = [lead for lead in acquisitions if lead in mature]

    print(f"Corte {args.corte} · ventana madura hasta {limit} "
          f"(madurez {MATURITY.days} días)")
    print(f"{len(created):,} leads · {len(mature):,} maduros · "
          f"{len(acquisitions):,} adquiridos · {len(pool):,} adquiridos maduros")
    print(f"Gasto de pauta en la ventana: {sum(spend.values()):,} COP\n")

    print("=== Reparto del crédito, en porcentaje ===")
    print(f"{'canal':<12}" + "".join(f"{name:>16}" for name in MODELS))
    shares = {name: share_of_credit(credit_by_channel(journeys, acquisitions, model, mature))
              for name, model in MODELS.items()}
    for channel in sorted(shares["primer toque"]):
        print(f"{channel:<12}"
              + "".join(f"{shares[name].get(channel, 0.0):>15.1f}%" for name in MODELS))

    print("\n=== Costo por paciente adquirido, en millones de COP, con su intervalo 95% ===")
    print(f"{'canal':<12}" + "".join(f"{name:>22}" for name in MODELS))
    for channel in PAID:
        cells = []
        for model in MODELS.values():
            point = cac_for(pool, journeys, model, spend, channel)
            low, high = interval(pool, journeys, model, spend, channel,
                                 args.remuestreos, args.semilla)
            cells.append(f"{point / 1e6:>7.2f} [{low / 1e6:.2f}–{high / 1e6:.2f}]")
        print(f"{channel:<12}" + "".join(f"{cell:>22}" for cell in cells))

    print("\n=== Lo que cuesta ignorar la madurez (último toque) ===")
    naive = cost_per_acquisition(
        load_spend(args.datos),
        credit_by_channel(journeys, acquisitions, MODELS["último toque"]))
    honest = cost_per_acquisition(
        spend, credit_by_channel(journeys, acquisitions, MODELS["último toque"], mature))
    for channel in PAID:
        change = (honest[channel] / naive[channel] - 1) * 100
        print(f"  {channel:<10} sin filtro {naive[channel]:>12,.0f} → "
              f"maduros {honest[channel]:>12,.0f}  ({change:+.1f}%)")

    print("\n=== La comprobación que ningún tablero pasa ===")
    for name, model in MODELS.items():
        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())
        print(f"  {name:<14} reparte {total:>10.1f} créditos "
              f"para {len(pool):,} pacientes")


if __name__ == "__main__":
    main()
