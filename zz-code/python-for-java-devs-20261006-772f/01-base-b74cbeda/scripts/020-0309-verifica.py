# rescatado de la sesión b74cbeda, 2026-09-13T03:09:45Z · Measure the slow partner with and without timeout
import time, httpx
BASE="http://127.0.0.1:8099"
httpx.get(f"{BASE}/_reiniciar")
N=10
print("=== el socio lento (tarda entre 2 y 6 s) ===")
# sin timeout: el emisor se bloquea con cada notificación
t0=time.perf_counter()
with httpx.Client(timeout=None) as c:
    for i in range(N):
        c.post(f"{BASE}/lento", json={"evento": i})
sin_to = time.perf_counter()-t0
llegaron_sin = httpx.get(f"{BASE}/_recibidos").json().get("/lento", 0)
httpx.get(f"{BASE}/_reiniciar")
# con timeout de 1 s: se abandona rápido, pero se pierde
t0=time.perf_counter(); perdidas=0
with httpx.Client(timeout=1.0) as c:
    for i in range(N):
        try: c.post(f"{BASE}/lento", json={"evento": i})
        except httpx.TimeoutException: perdidas+=1
con_to = time.perf_counter()-t0
time.sleep(7)  # el servidor sigue procesando en segundo plano
llegaron_con = httpx.get(f"{BASE}/_recibidos").json().get("/lento", 0)
print(f"sin timeout: {sin_to:6.1f} s para {N} notificaciones · llegaron {llegaron_sin}")
print(f"con timeout de 1 s: {con_to:6.1f} s · el emisor dio por perdidas {perdidas} · pero al socio LLEGARON {llegaron_con}")
