"""Cuánto de la latencia del endpoint es validación."""
import statistics, time, json
from datetime import date, datetime, time as t, timedelta, timezone
from fastapi.testclient import TestClient
import app as A

c = TestClient(A.app)

def bench(fn, reps=400):
    for _ in range(40): fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1]

payload = {"patient_document":"1019283746","branch":"centro","phase":"orthodontic",
           "starts_at":"2026-10-15T15:40:00-05:00"}

print("=== endpoints (en proceso, sin red) ===")
for name, fn in [
    ("GET /availability (con modelo de salida)", lambda: c.get("/availability", params={"branch":"centro","day":"2026-10-15"})),
    ("GET /availability-raw (sin modelo)",        lambda: c.get("/availability-raw", params={"branch":"centro","day":"2026-10-15"})),
    ("POST /bookings (valida entrada y salida)",  lambda: c.post("/bookings", json=payload)),
]:
    m,p = bench(fn)
    print(f"{name:44s} mediana {m:6.2f} ms   p95 {p:6.2f} ms")

print()
print("=== el costo puro de Pydantic, sin HTTP ===")
raw = A.availability_raw("centro", "2026-10-15")
def validar_salida(): A.AvailabilityResponse.model_validate({"branch":"centro","day":"2026-10-15","slots":raw["slots"]})
def validar_entrada(): A.BookingRequest.model_validate(payload)
def serializar(): A.AvailabilityResponse.model_validate({"branch":"centro","day":"2026-10-15","slots":raw["slots"]}).model_dump_json()
for name, fn in [("validar la entrada del POST (4 campos)", validar_entrada),
                 ("validar la salida (36 espacios)", validar_salida),
                 ("validar + serializar la salida", serializar),
                 ("json.dumps del dict crudo", lambda: json.dumps(raw))]:
    m,p = bench(fn, 2000)
    print(f"{name:44s} mediana {m*1000:7.1f} µs   p95 {p*1000:7.1f} µs")
