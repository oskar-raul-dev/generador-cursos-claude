import random, statistics, time
random.seed(2026)
def doc(): return str(random.randint(10_000_000, 1_299_999_999))
for n in (10, 50, 200, 1000, 2800):
    ids=[doc() for _ in range(n)]
    qs=ids[:n//2]+[doc() for _ in range(n//2)]
    def b(c):
        xs=[]
        for _ in range(21):
            t0=time.perf_counter(); sum(1 for q in qs if q in c); xs.append((time.perf_counter()-t0)*1e6)
        return statistics.median(xs)
    print(f"n={n:5d}  list {b(ids):9.1f} µs   set {b(set(ids)):9.1f} µs   ratio {b(ids)/b(set(ids)):6.1f}×")
