"""Cuántas operaciones se pierden y cuántas se duplican, con y sin defensas."""
import statistics, time
import httpx

BASE = "http://127.0.0.1:8099"
N = 60   # sesenta notificaciones de disponibilidad

def reset():
    httpx.get(f"{BASE}/_reiniciar")

def recibidos():
    return httpx.get(f"{BASE}/_recibidos").json()

def sin_defensas(ruta):
    """Lo que sale solo: un POST, sin timeout, sin reintento, sin mirar nada."""
    enviadas = perdidas = 0
    with httpx.Client() as c:
        for i in range(N):
            enviadas += 1
            try:
                c.post(f"{BASE}{ruta}", json={"evento": i})
            except Exception:
                perdidas += 1
    return enviadas, perdidas

def con_reintento(ruta, idempotente=False):
    """Timeout, tres intentos con backoff, y clave de idempotencia si aplica."""
    enviadas = perdidas = reintentos = 0
    with httpx.Client(timeout=httpx.Timeout(1.0, connect=0.5)) as c:
        for i in range(N):
            enviadas += 1
            headers = {"Idempotency-Key": f"evt-{i}"} if idempotente else {}
            for intento in range(3):
                try:
                    r = c.post(f"{BASE}{ruta}", json={"evento": i}, headers=headers)
                    if r.status_code < 500:
                        break
                except Exception:
                    pass
                reintentos += 1
                time.sleep(0.05 * (2 ** intento))   # backoff exponencial
            else:
                perdidas += 1
    return enviadas, perdidas, reintentos

print(f"{'escenario':<44}{'enviadas':>9}{'llegaron':>10}{'perdidas':>10}{'duplicadas':>12}{'tiempo':>10}")

for nombre, ruta, fn in [
    ("intermitente, sin defensas", "/intermitente", lambda: sin_defensas("/intermitente")),
    ("intermitente, con reintento", "/intermitente", lambda: con_reintento("/intermitente")),
    ("idempotente, con reintento SIN clave", "/idempotente", lambda: con_reintento("/idempotente")),
    ("idempotente, con reintento CON clave", "/idempotente", lambda: con_reintento("/idempotente", True)),
    ("mentiroso, con reintento", "/mentiroso", lambda: con_reintento("/mentiroso")),
]:
    reset()
    t0=time.perf_counter(); res = fn(); dt=(time.perf_counter()-t0)
    enviadas, perdidas = res[0], res[1]
    llegaron = recibidos().get(ruta, 0)
    dup = max(0, llegaron - (enviadas - perdidas))
    print(f"{nombre:<44}{enviadas:>9}{llegaron:>10}{perdidas:>10}{dup:>12}{dt:>9.1f}s")
