"""Medición de la sección 6: la red neuronal contra la línea base de `ds07`.

    uv run --with torch==2.14.0 --with scikit-learn==1.9.1 python bench_net.py --datos data

Cuatro tablas:

1. **Discriminación y calibración**: AUC, Brier y ECE de los cuatro candidatos.
2. **La decisión**: cuántas consultas recupera cada uno sobreagendando, contra no hacer nada.
3. **La diferencia es real**: intervalo bootstrap de la ventaja de la red sobre la logística,
   y de la logística con una columna a mano sobre la misma logística.
4. **Costo**: entrenamiento, artefacto, dependencias y horas-persona al año.

La tercera existe porque la ventaja de la red es de un punto de AUC, y un punto sin intervalo
no se puede defender ni atacar.
"""

from __future__ import annotations

import argparse
import pickle
import random
import time
from pathlib import Path

from calibration import brier_score, expected_calibration_error, reliability
from engineered import fit_with_interaction, score_with_interaction
from net import score_network, train_network
from overbooking import COLLISION_RATIO, break_even, decide, realised_cost
from shared import (
    build_matrix,
    cutoff_of,
    fit_logistic,
    load_rows,
    precision_recall,
    roc_auc,
    score_rows,
    split_temporal,
    three_variable_rule,
    threshold_for_capacity,
)

CAPACITY = 0.20


def bootstrap_difference(better: list[float], worse: list[float], target: list[int],
                         repetitions: int, seed: int) -> tuple[float, float, float]:
    """Media e intervalo al 95% de la diferencia de AUC, remuestreando las mismas filas."""
    generator = random.Random(seed)
    size = len(target)
    differences = []
    for _ in range(repetitions):
        sample = [generator.randrange(size) for _ in range(size)]
        labels = [target[index] for index in sample]
        differences.append(roc_auc([better[index] for index in sample], labels)
                           - roc_auc([worse[index] for index in sample], labels))
    differences.sort()
    return (sum(differences) / repetitions,
            differences[int(0.025 * repetitions)],
            differences[int(0.975 * repetitions) - 1])


def main() -> None:
    parser = argparse.ArgumentParser(description="La red contra la línea base.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--remuestreos", type=int, default=200)
    parser.add_argument("--semilla", type=int, default=20260913)
    args = parser.parse_args()

    rows = load_rows(args.datos)
    train, test = split_temporal(rows, cutoff_of(args.datos))
    _, target = build_matrix(test)

    started = time.perf_counter()
    logistic = fit_logistic(train)
    logistic_seconds = time.perf_counter() - started
    interacted = fit_with_interaction(train)
    network, scaler, report = train_network(train)

    candidates = {
        "regla de 3": three_variable_rule(test),
        "logística de 5": score_rows(logistic, test),
        "logística + interacción": score_with_interaction(interacted, test),
        "red neuronal": score_network(network, scaler, test),
    }

    print(f"Entrenamiento {len(train):,} · prueba {len(test):,} · "
          f"inasistencia {sum(target) / len(target):.1%}\n")

    print("=== 1. Discriminación, calibración y operación ===")
    print(f"{'candidato':<26}{'AUC':>8}{'Brier':>9}{'ECE':>8}{'precisión@20%':>15}")
    for name, scores in candidates.items():
        precision, _, _ = precision_recall(
            scores, target, threshold_for_capacity(scores, CAPACITY))
        print(f"{name:<26}{roc_auc(scores, target):>8.4f}"
              f"{brier_score(scores, target):>9.4f}"
              f"{expected_calibration_error(scores, target):>8.4f}{precision:>15.3f}")

    print("\n=== 2. Fiabilidad de la red, por decil: predicho → observado ===")
    for predicted, observed, count in reliability(candidates["red neuronal"], target):
        print(f"  {predicted:.3f} → {observed:.3f}   (n={count:,})")

    print("\n=== 3. Sobreagendar: consultas recuperadas frente a no hacer nada ===")
    never = -sum(target)
    print(f"  Sin sobreagendar se pierden {-never:,} consultas de {len(target):,} citas.")
    for ratio in (1.0, 2.0, COLLISION_RATIO, 4.0):
        print(f"  una colisión = {ratio:g}× una silla vacía · umbral p > "
              f"{break_even(ratio):.2f}")
        for name, scores in candidates.items():
            decisions = decide(scores, ratio)
            net = realised_cost(scores, decisions, target, ratio) - never
            print(f"     {name:<26}{sum(decisions):>7,} cupos{net:>+9.0f} consultas")

    print("\n=== 4. ¿Es real la ventaja? Bootstrap de la diferencia de AUC ===")
    for label, better in (("red − logística", candidates["red neuronal"]),
                          ("interacción − logística",
                           candidates["logística + interacción"])):
        mean, low, high = bootstrap_difference(
            better, candidates["logística de 5"], target, args.remuestreos, args.semilla)
        print(f"  {label:<26}{mean:+.4f}   IC95 [{low:+.4f}, {high:+.4f}]")

    print("\n=== 5. Lo que cuesta cada uno ===")
    costs = [
        ("logística · entrenar (1ª llamada)", f"{logistic_seconds * 1000:.0f} ms"),
        ("red · entrenar", f"{report.seconds:.1f} s"),
        ("red · épocas corridas / mejor", f"{report.epochs_run} / {report.best_epoch}"),
        ("red · parámetros", f"{report.parameters}"),
        ("logística · artefacto", f"{len(pickle.dumps(logistic)) / 1024:.1f} KB"),
        ("red · artefacto", f"{len(pickle.dumps(network)) / 1024:.1f} KB"),
    ]
    for label, value in costs:
        print(f"  {label:<34}{value:>12}")
    print("  La primera llamada a la logística incluye el import de sklearn; en caliente,")
    print("  `ds07` §6.3 la mide en 143,8 ms.")


if __name__ == "__main__":
    main()
