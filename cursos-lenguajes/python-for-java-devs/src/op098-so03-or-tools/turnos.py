"""Los turnos de recepción de una semana con CP-SAT: reglas duras, preferencias y equidad."""

from ortools.sat.python import cp_model

SEDES = ["Centro", "Chapinero", "Kennedy", "Usaquén"]
DAYS = ["lun", "mar", "mié", "jue", "vie", "sáb"]
SHIFTS = ["mañana", "tarde"]
STAFF = {"Yuli": "Centro", "rec-02": "Centro", "rec-03": "Chapinero", "rec-04": "Chapinero", "rec-05": "Kennedy",
         "rec-06": "Kennedy", "rec-07": "Usaquén", "rec-08": "Usaquén", "rec-09": "Centro"}

m = cp_model.CpModel()
work = {(p, s, d, t): m.new_bool_var(f"{p}_{s}_{d}_{t}") for p in STAFF for s in SEDES for d in DAYS for t in SHIFTS}

for s in SEDES:                                          # cobertura: una persona por sede, día y turno
    for d in DAYS:
        for t in SHIFTS:
            m.add_exactly_one(work[p, s, d, t] for p in STAFF)
for p in STAFF:
    m.add(sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) <= 6)       # tope semanal
    for d in DAYS:
        m.add_at_most_one(work[p, s, d, t] for s in SEDES for t in SHIFTS)              # un turno por día
for s in SEDES:                                          # Yuli no trabaja sábados
    for t in SHIFTS:
        m.add(work["Yuli", s, "sáb", t] == 0)
for s in SEDES:                                          # rec-03 no cierra los viernes
    m.add(work["rec-03", s, "vie", "tarde"] == 0)

away = sum(work[p, s, d, t] for p, home in STAFF.items() for s in SEDES if s != home for d in DAYS for t in SHIFTS)
load = {p: sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) for p in STAFF}
most, least = m.new_int_var(0, 6, "most"), m.new_int_var(0, 6, "least")
for p in STAFF:
    m.add(most >= load[p])
    m.add(least <= load[p])
m.minimize(10 * away + (most - least))                   # primero la sede habitual, después la equidad

solver = cp_model.CpSolver()
solver.parameters.max_time_in_seconds = 10
status = solver.solve(m)
print(solver.status_name(status), f"en {solver.wall_time:.2f} s · fuera de su sede: {int(solver.value(away))} turnos",
      f"· carga entre {solver.value(least)} y {solver.value(most)}")
for s in SEDES:
    row = [next(p for p in STAFF if solver.value(work[p, s, d, t])) for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join("Yu" if p == "Yuli" else p[-2:] for p in row))
