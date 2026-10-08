import random, statistics, time

random.seed(2026)
def doc():  # cédulas colombianas plausibles
    return str(random.randint(10_000_000, 1_299_999_999))

ids = [doc() for _ in range(2800)]
as_list, as_set, as_dict = ids, set(ids), {d: i for i, d in enumerate(ids)}

# mitad presentes, mitad ausentes: el caso realista de una consolidación
queries = ids[:1400] + [doc() for _ in range(1400)]
random.shuffle(queries)

def bench(container, reps=15):
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        n = sum(1 for q in queries if q in container)
        xs.append((time.perf_counter() - t0) * 1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], n

for name, c in [("list", as_list), ("set", as_set), ("dict", as_dict)]:
    med, p95, n = bench(c)
    print(f"{name:6s} mediana {med:8.3f} ms  p95 {p95:8.3f} ms  (encontrados {n})")

# comparaciones promedio en la lista
tot = 0
for q in queries:
    for i, v in enumerate(as_list, 1):
        if v == q:
            tot += i; break
    else:
        tot += len(as_list)
print(f"\ncomparaciones promedio por consulta en list: {tot/len(queries):.0f}")
print(f"tamaño en memoria: list {as_list.__sizeof__()} B · set {as_set.__sizeof__()} B · dict {as_dict.__sizeof__()} B")
