# rescatado de la sesión 2859734a, 2026-09-13T20:00:48Z · Calibrate no-show rate
import importlib, random, math
import generar_ausentismo as g
def rate(intercept, wprior, seed=20260913):
    g.INTERCEPT=intercept; g.W_PRIOR_NO_SHOWS=wprior
    rng=random.Random(seed)
    w=g.build_weather(rng); p=g.build_patients(rng,1200)
    rows=g.build_appointments(rng,p,w)
    ns=sum(1-r["asistio"] for r in rows)
    return ns/len(rows), len(rows)
for wp in (-0.35,-0.45):
    for ic in (1.6,2.0,2.4,2.8):
        r,n=rate(ic,wp); print(f"w={wp} ic={ic} -> {r:.3f} ({n} filas)")
