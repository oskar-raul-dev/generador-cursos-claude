import pulp
PROCS = {"control": (30, 0, 80_000, 120), "limpieza": (40, 0, 60_000, 60),
         "blanqueamiento": (60, 30, 250_000, 12), "carilla": (120, 120, 900_000, 6)}
def solve(chair, rehab, integer):
    prob = pulp.LpProblem("m", pulp.LpMaximize)
    n = prob.add_variable_dicts("n", list(PROCS), lowBound=0, cat="Integer" if integer else "Continuous")
    prob += pulp.lpSum(PROCS[p][2] * n[p] for p in PROCS)
    prob += pulp.lpSum(PROCS[p][0] * n[p] for p in PROCS) <= chair, "silla"
    prob += pulp.lpSum(PROCS[p][1] * n[p] for p in PROCS) <= rehab, "rehabilitador"
    for p in PROCS:
        prob += n[p] <= PROCS[p][3], f"demanda_{p}"
    st = prob.solve(pulp.HiGHS(msg=False))
    return prob, {p: n[p].value() for p in PROCS}, st
for rehab in (450, 500, 630):
    prob, mix, st = solve(6480, rehab, False)
    print(rehab, {p: round(v, 3) for p, v in mix.items()}, st.objective)
cs = prob.constraints()
print(type(cs).__name__)
c = list(cs.values())[0] if hasattr(cs, "values") else cs[0]
print(type(c).__name__, [n for n in dir(c) if not n.startswith("_")])
