# rescatado de la sesión b74cbeda, 2026-09-13T02:43:37Z · Measure over real HTTP with uvicorn
import httpx, statistics, time
base="http://127.0.0.1:8765"
def bench(fn, reps=300):
    for _ in range(30): fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), xs[int(len(xs)*0.95)-1]
with httpx.Client(base_url=base) as c:
    for name, fn in [
        ("GET /availability", lambda: c.get("/availability", params={"branch":"centro","day":"2026-10-15"})),
        ("GET /availability-raw", lambda: c.get("/availability-raw", params={"branch":"centro","day":"2026-10-15"})),
        ("POST /bookings", lambda: c.post("/bookings", json={"patient_document":"1019283746","branch":"centro","phase":"orthodontic","starts_at":"2026-10-15T15:40:00-05:00"})),
        ("POST /bookings inválido (422)", lambda: c.post("/bookings", json={"patient_document":"AB1","branch":"centro","phase":"orthodontic","starts_at":"2026-10-15T15:40:00-05:00"})),
    ]:
        m,p=bench(fn); print(f"{name:32s} mediana {m:6.2f} ms   p95 {p:6.2f} ms")
