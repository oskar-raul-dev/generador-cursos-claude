"""Medición de la sección 6: la regla contra el modelo, y lo que cuesta cada uno.

    uv run --with scikit-learn==1.9.1 python bench_baseline.py --datos data

Cuatro tablas, y las cuatro hacen falta:

1. **Discriminación**: AUC de los cuatro candidatos sobre el mismo corte temporal.
2. **Operación**: a la capacidad real de Yuli —el 20% de la agenda—, a cuántos marca cada
   uno y con qué precisión y recall.
3. **Partición**: el mismo modelo con tres formas de partir el histórico. La respuesta de
   esta tabla no es la que dice el manual, y por eso se publica.
4. **Costo de mantener**: líneas, dependencias, arranque, entrenamiento y artefacto.

La cuarta es la que nadie publica y la que decide si el modelo entra a producción.
"""

from __future__ import annotations

import argparse
import pickle
import random
import statistics
import subprocess
import sys
import time
from pathlib import Path

from baseline import (
    always_attends,
    precision_recall,
    roc_auc,
    three_variable_rule,
    threshold_for_capacity,
)
from features import HONEST, LEAKY, build_matrix, cutoff_of, load_rows, split_temporal
from model import coefficients, fit_logistic, score_rows

# Lo que Yuli puede llamar: media mañana, más o menos el 20% de la agenda del día. El umbral
# sale de aquí y no de maximizar una métrica, que es la diferencia entre un modelo y una
# operación.
CAPACITY = 0.20


def cold_start_ms(code: str, repetitions: int = 5) -> float:
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        subprocess.run([sys.executable, "-c", code], check=True, capture_output=True)
        timings.append((time.perf_counter() - started) * 1000)
    return statistics.median(timings)


def timed(work, repetitions: int = 5) -> float:
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        work()
        timings.append((time.perf_counter() - started) * 1000)
    return statistics.median(timings)


def main() -> None:
    parser = argparse.ArgumentParser(description="La línea base contra el modelo.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--capacidad", type=float, default=CAPACITY)
    parser.add_argument("--semilla", type=int, default=20260913)
    args = parser.parse_args()

    rows = load_rows(args.datos)
    cutoff = cutoff_of(args.datos)
    train, test = split_temporal(rows, cutoff)
    _, target = build_matrix(test)

    print(f"Corte temporal {cutoff} · entrenamiento {len(train):,} · prueba {len(test):,}")
    print(f"Inasistencia en el tramo de prueba: {sum(target) / len(target):.1%}\n")

    leaky_columns = [*HONEST, LEAKY]
    honest_pipeline = fit_logistic(train)
    leaky_pipeline = fit_logistic(train, leaky_columns)

    candidates = {
        "siempre asiste": always_attends(test),
        "regla de 3 variables": three_variable_rule(test),
        "logística de 5": score_rows(honest_pipeline, test),
        "logística + FUGA": score_rows(leaky_pipeline, test, leaky_columns),
    }

    print("=== 1. Discriminación y operación, a capacidad "
          f"{args.capacidad:.0%} ===")
    print(f"{'candidato':<24}{'AUC':>8}{'marcadas':>12}{'precisión':>11}{'recall':>9}")
    for name, scores in candidates.items():
        threshold = threshold_for_capacity(scores, args.capacidad)
        precision, recall, flagged = precision_recall(scores, target, threshold)
        print(f"{name:<24}{roc_auc(scores, target):>8.3f}"
              f"{flagged:>8,} ({flagged / len(target):>3.0%}){precision:>11.3f}"
              f"{recall:>9.3f}")

    print("\n=== 2. Los pesos que aprendió, sobre datos escalados ===")
    for variable, weight in coefficients(honest_pipeline).items():
        print(f"  {variable:<28}{weight:+.3f}")

    print("\n=== 3. Tres formas de partir el mismo histórico ===")
    generator = random.Random(args.semilla)
    shuffled = rows[:]
    generator.shuffle(shuffled)
    random_train, random_test = shuffled[:len(train)], shuffled[len(train):]

    patients = sorted({row["paciente_id"] for row in rows})
    generator.shuffle(patients)
    held_out = set(patients[:len(patients) // 3])
    group_train = [row for row in rows if row["paciente_id"] not in held_out]
    group_test = [row for row in rows if row["paciente_id"] in held_out]

    print(f"{'partición':<24}{'honestas':>12}{'con fuga':>12}")
    for name, (fit_rows, eval_rows) in {
        "temporal": (train, test),
        "al azar": (random_train, random_test),
        "por paciente": (group_train, group_test),
    }.items():
        _, labels = build_matrix(eval_rows)
        honest = roc_auc(score_rows(fit_logistic(fit_rows), eval_rows), labels)
        leaky = roc_auc(
            score_rows(fit_logistic(fit_rows, leaky_columns), eval_rows, leaky_columns),
            labels)
        print(f"{name:<24}{honest:>12.3f}{leaky:>12.3f}")

    print("\n=== 4. Lo que cuesta mantener cada una ===")
    artifact = pickle.dumps(honest_pipeline)
    costs = [
        (f"regla · {len(test):,} filas", f"{timed(lambda: three_variable_rule(test)):.1f} ms"),
        ("logística · entrenar", f"{timed(lambda: fit_logistic(train)):.1f} ms"),
        (f"logística · {len(test):,} filas",
         f"{timed(lambda: score_rows(honest_pipeline, test)):.1f} ms"),
        ("artefacto serializado", f"{len(artifact) / 1024:.1f} KB"),
        ("arranque del intérprete", f"{cold_start_ms('pass'):.0f} ms"),
        ("arranque + import de sklearn",
         f"{cold_start_ms('import sklearn.linear_model'):.0f} ms"),
    ]
    for label, value in costs:
        print(f"  {label:<34}{value:>12}")


if __name__ == "__main__":
    main()
