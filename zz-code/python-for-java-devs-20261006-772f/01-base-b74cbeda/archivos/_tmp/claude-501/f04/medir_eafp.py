"""EAFP contra LBYL en el caso feliz y en el caso malo, variando la tasa de fallo."""
import random, statistics, time

random.seed(2026)
N = 200_000

def make_rows(bad_rate):
    rows = []
    for _ in range(N):
        if random.random() < bad_rate:
            rows.append({"documento": "1019", "valor": ""})        # vacío: no convertible
        else:
            rows.append({"documento": "1019", "valor": str(random.randint(1, 900000))})
    return rows

def lbyl(rows):
    total = 0
    for row in rows:
        value = row.get("valor", "")
        if value and value.isdigit():        # comprobar antes
            total += int(value)
    return total

def eafp(rows):
    total = 0
    for row in rows:
        try:
            total += int(row["valor"])        # intentar y fallar
        except (KeyError, ValueError):
            pass
    return total

def bench(fn, rows, reps=7):
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(rows); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs)

print(f"{'fallos':>8} {'LBYL':>10} {'EAFP':>10}  veredicto")
for rate in (0.0, 0.01, 0.05, 0.10, 0.25, 0.50, 1.0):
    rows = make_rows(rate)
    assert lbyl(rows) == eafp(rows)
    a, b = bench(lbyl, rows), bench(eafp, rows)
    who = "EAFP" if b < a else "LBYL"
    print(f"{rate*100:7.0f}% {a:8.1f} ms {b:8.1f} ms  gana {who} ({abs(a-b)/max(a,b)*100:.0f}% de diferencia)")
