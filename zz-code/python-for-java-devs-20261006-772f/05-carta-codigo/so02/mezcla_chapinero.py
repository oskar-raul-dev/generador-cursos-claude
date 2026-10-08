"""La mezcla semanal de Chapinero: lineal (con precios sombra) y entera (la que se agenda)."""

import pulp

PROCS = {                 # minutos de silla, minutos del rehabilitador, margen en pesos, máximo semanal de demanda
    "control": (30, 0, 80_000, 120),
    "limpieza": (40, 0, 60_000, 60),
    "blanqueamiento": (60, 30, 250_000, 12),
    "carilla": (120, 120, 900_000, 6),
}
CHAIR_MINUTES = 2 * 6 * 9 * 60          # dos sillas, seis días, nueve horas
REHAB_MINUTES = 3 * 210                 # tres tardes de tres horas y media


def solve(integer: bool):
    prob = pulp.LpProblem("mezcla_chapinero", pulp.LpMaximize)
    n = prob.add_variable_dicts("n", list(PROCS), lowBound=0, cat="Integer" if integer else "Continuous")
    prob += pulp.lpSum(PROCS[p][2] * n[p] for p in PROCS)
    prob += pulp.lpSum(PROCS[p][0] * n[p] for p in PROCS) <= CHAIR_MINUTES, "silla"
    prob += pulp.lpSum(PROCS[p][1] * n[p] for p in PROCS) <= REHAB_MINUTES, "rehabilitador"
    for p in PROCS:
        prob += n[p] <= PROCS[p][3], f"demanda_{p}"
    stats = prob.solve(pulp.HiGHS(msg=False))
    return prob, {p: n[p].value() for p in PROCS}, stats


prob, mix, stats = solve(integer=False)
print("lineal:", {p: round(v, 2) for p, v in mix.items()}, f"· margen ${stats.objective:,.0f}")
for c in prob.constraints():                     # PuLP 4: un método que devuelve la lista
    if c.pi:
        print(f"  precio sombra de {c.name}: ${c.pi:,.0f} por unidad")

_, mix_int, stats_int = solve(integer=True)
print("entera:", {p: int(v) for p, v in mix_int.items()}, f"· margen ${stats_int.objective:,.0f}")
