"""¿Cuándo mandar los dos recordatorios? Caja negra con ruido: rejilla, SciPy y Optuna, contando evaluaciones."""

import itertools
import math

import numpy as np
import optuna
from scipy.optimize import differential_evolution

calls = 0


def no_show_rate(first_h: float, second_h: float, patients: int = 4_000, seed: int | None = None) -> float:
    """Simulador de ausentismo (de juguete): horas antes de la cita del primer y del segundo recordatorio."""
    global calls
    calls += 1
    rng = np.random.default_rng(seed)
    base = 0.09 + 0.02 * math.log1p(abs(first_h - 30) / 6) + 0.025 * math.log1p(abs(second_h - 3) / 1.5)
    annoyed = 0.03 if abs(first_h - second_h) < 4 else 0.0          # dos mensajes casi seguidos molestan
    return rng.binomial(patients, min(base + annoyed, 1.0)) / patients


def objective(h):                                                  # ruido incluido: cada llamada es una simulación nueva
    return no_show_rate(h[0], h[1])


def report(name: str, h1: float, h2: float):
    global calls
    used, calls = calls, 0
    check = no_show_rate(h1, h2, patients=400_000, seed=1)           # reevaluación grande, casi sin ruido
    calls = 0
    print(f"{name:<24} primero {h1:5.1f} h · segundo {h2:4.1f} h · ausentismo {check:6.2%} · {used:4d} evaluaciones")


grid = min(itertools.product(range(1, 73), range(1, 13)), key=objective)
report("rejilla (72 × 12)", *grid)

de = differential_evolution(objective, bounds=[(1, 72), (1, 12)], seed=3, maxiter=20, polish=False)
report("evolución diferencial", *de.x)

optuna.logging.set_verbosity(optuna.logging.WARNING)
study = optuna.create_study(sampler=optuna.samplers.TPESampler(seed=3))
study.optimize(lambda t: objective((t.suggest_float("first", 1, 72), t.suggest_float("second", 1, 12))), n_trials=60)
report("Optuna (TPE)", study.best_params["first"], study.best_params["second"])

report("lo que se hace hoy", 48, 24)
