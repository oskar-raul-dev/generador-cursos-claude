# rescatado de la sesión 2859734a, 2026-09-13T20:01:20Z · Wider calibration scan
import random, math, generar_ausentismo as g
def run(intercept,wprior,cap,n=1500,seed=20260913):
    rng=random.Random(seed); weather=g.build_weather(rng); patients=g.build_patients(rng,n)
    tot=att=0; th_no=th_n=0
    for patient in patients:
        entry=g.START+g.timedelta(days=rng.randint(0,640)); months=rng.randint(4,26)
        ab=rng.randint(5,20) if rng.random()<0.11 else months+1
        pn=0
        for month in range(1,min(months,ab)+1):
            day=entry+g.timedelta(days=30*(month-1)+rng.randint(-3,3))
            if not g.START<=day<=g.END or day.weekday()==6 or g.is_holy_week(day): continue
            hour=rng.choices(range(7,19),[4,7,9,10,9,6,5,8,10,11,9,6])[0]
            rng.choice((0,20,40)); lead=rng.randint(3,45)
            rain=weather[(patient["zona"],day)]; th=int(day.weekday()==3 and hour>=16)
            logit=(intercept+wprior*min(pn,cap)-0.55*th-0.024*rain-0.045*patient["distancia_km"]
                   -0.011*lead-0.030*rain*patient["distancia_km"]+patient["propension_base"])
            a=int(rng.random()<1/(1+math.exp(-logit))); rng.choices(g.VISIT_TYPES,g.VISIT_WEIGHTS)
            tot+=1; att+=a; pn+=1-a
            if th: th_n+=1; th_no+=1-a
    return 1-att/tot, th_no/max(th_n,1)
for wp in (-0.30,-0.40):
    for ic in (2.6,3.0,3.4,3.8):
        r,th=run(ic,wp,3); print(f"w={wp} ic={ic} -> global {r:.3f} · jueves tarde {th:.3f}")
