"""El reparto de especialistas del sábado: el algoritmo voraz contra el modelo declarado."""

import random

import pulp

SEDES = ["Chapinero", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha"]   # sedes propias; las franquicias tienen su personal
SPECIALISTS = [f"esp-{i:02d}" for i in range(1, 11)]
random.seed(10)
minutes = {(e, s): random.randint(10, 90) for e in SPECIALISTS for s in SEDES}


# ------------------------------------------------- 1. lo que escribiría el instinto: voraz por sede
def greedy() -> dict[str, str]:
    free, plan = set(SPECIALISTS), {}
    for s in SEDES:
        best = min(free, key=lambda e: minutes[e, s])
        plan[s] = best
        free.remove(best)
    return plan


# ------------------------------------------------- 2. el problema descrito
def model(extra_rules: bool = False) -> tuple[dict[str, list[str]], float, str]:
    prob = pulp.LpProblem("reparto_sabado", pulp.LpMinimize)
    x = prob.add_variable_dicts("x", [(e, s) for e in SPECIALISTS for s in SEDES], cat="Binary")   # PuLP 4: desde el problema
    prob += pulp.lpSum(minutes[e, s] * x[e, s] for e in SPECIALISTS for s in SEDES)          # objetivo
    for s in SEDES:
        prob += pulp.lpSum(x[e, s] for e in SPECIALISTS) >= (2 if extra_rules and s == "Kennedy" else 1)
    for e in SPECIALISTS:
        prob += pulp.lpSum(x[e, s] for s in SEDES) <= 1
    if extra_rules:
        prob += x["esp-03", "Soacha"] == 0                                                  # una regla, una línea
    stats = prob.solve(pulp.HiGHS(msg=False))                                                  # PuLP 4: devuelve el resultado
    plan = {s: [e for e in SPECIALISTS if x[e, s].value() > 0.5] for s in SEDES}
    return plan, stats.objective, stats.status.name


g = greedy()
print("voraz:          ", sum(minutes[e, s] for s, e in g.items()), "minutos")
plan, total, status = model()
print("modelo:         ", int(total), "minutos ·", status)
plan2, total2, status2 = model(extra_rules=True)
print("con dos reglas: ", int(total2), "minutos ·", status2, "· Kennedy:", plan2["Kennedy"], "· Soacha:", plan2["Soacha"])
