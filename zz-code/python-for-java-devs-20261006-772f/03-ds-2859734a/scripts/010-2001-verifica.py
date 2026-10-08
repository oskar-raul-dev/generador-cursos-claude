# rescatado de la sesión 2859734a, 2026-09-13T20:01:04Z · Test saturated prior effect
import random, math, generar_ausentismo as g
src=open('generar_ausentismo.py').read()
# monkeypatch: reemplazo la función con versión saturada
def make(intercept, wprior, cap):
    def build(rng, patients, weather):
        rows=[]
        for patient in patients:
            entry=g.START+g.timedelta(days=rng.randint(0,640))
            months=rng.randint(4,26)
            ab=rng.randint(5,20) if rng.random()<0.11 else months+1
            pv=pn=0
            for month in range(1,min(months,ab)+1):
                day=entry+g.timedelta(days=30*(month-1)+rng.randint(-3,3))
                if not g.START<=day<=g.END or day.weekday()==6 or g.is_holy_week(day): continue
                hour=rng.choices(range(7,19),[4,7,9,10,9,6,5,8,10,11,9,6])[0]
                rng.choice((0,20,40)); lead=rng.randint(3,45)
                rain=weather[(patient["zona"],day)]
                th=int(day.weekday()==3 and hour>=16)
                logit=(intercept+wprior*min(pn,cap)-0.55*th-0.024*rain-0.045*patient["distancia_km"]
                       -0.011*lead-0.030*rain*patient["distancia_km"]+patient["propension_base"])
                a=int(rng.random()<1/(1+math.exp(-logit)))
                rng.choices(g.VISIT_TYPES,g.VISIT_WEIGHTS)
                rows.append(a); pv+=1; pn+=1-a
        return rows
    return build
for cap in (2,3):
    for ic in (1.4,1.7,2.0,2.3):
        rng=random.Random(20260913); w=g.build_weather(rng); p=g.build_patients(rng,1500)
        rows=make(ic,-0.62,cap)(rng,p,w)
        print(f"cap={cap} ic={ic} -> {1-sum(rows)/len(rows):.3f}  n={len(rows)}")
