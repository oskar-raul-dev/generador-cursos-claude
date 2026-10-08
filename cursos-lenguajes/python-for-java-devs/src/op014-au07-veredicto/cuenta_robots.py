"""¿Siguen valiendo la pena los robots? La cuenta, desde el registro de corridas."""

import csv
import io
from collections import defaultdict
from dataclasses import dataclass

# Una línea por corrida: fecha, robot, ok (1/0) y horas que tomó arreglarlo si falló.
RUNS = """fecha,robot,ok,horas_arreglo
2026-07-06,radicacion,1,0
2026-07-13,radicacion,0,3.0
2026-07-20,radicacion,1,0
2026-07-27,radicacion,1,0
2026-08-03,radicacion,0,1.5
2026-08-10,radicacion,1,0
2026-08-17,radicacion,1,0
2026-08-24,radicacion,0,4.0
2026-07-06,circulares,1,0
2026-07-13,circulares,1,0
2026-07-20,circulares,1,0
2026-07-27,circulares,1,0
2026-08-03,circulares,0,0.5
2026-08-10,circulares,1,0
2026-08-17,circulares,1,0
2026-08-24,circulares,1,0
"""

# Lo que tardaba una persona en hacer el trabajo, por corrida (estimación de quien lo hacía).
MANUAL_HOURS = {"radicacion": 4.0, "circulares": 0.25}


@dataclass
class Verdict:
    robot: str
    runs: int
    failures: int
    saved: float
    fixing: float

    @property
    def net(self) -> float:
        return self.saved - self.fixing

    @property
    def failure_rate(self) -> float:
        return self.failures / self.runs


def tally(log: str) -> list[Verdict]:
    totals: dict[str, list[float]] = defaultdict(lambda: [0, 0, 0.0, 0.0])
    for row in csv.DictReader(io.StringIO(log)):
        t = totals[row["robot"]]
        t[0] += 1
        if row["ok"] == "1":
            t[2] += MANUAL_HOURS[row["robot"]]   # solo las corridas buenas ahorran
        else:
            t[1] += 1
            t[3] += float(row["horas_arreglo"])
    return [Verdict(robot, int(r), int(f), s, x) for robot, (r, f, s, x) in sorted(totals.items())]


if __name__ == "__main__":
    for v in tally(RUNS):
        print(f"{v.robot:11} corridas {v.runs:2}  fallas {v.failures} ({v.failure_rate:.0%})  "
              f"ahorro {v.saved:5.2f} h  arreglos {v.fixing:4.1f} h  neto {v.net:+6.2f} h")
