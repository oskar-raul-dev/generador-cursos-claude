# rescatado de la sesión 2859734a, 2026-09-14T02:06:40Z · Frame overbooking as net gain over doing nothing
from pathlib import Path
from shared import *
from net import *
from engineered import *
from overbooking import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, _ = train_network(train)
cands = {
 "regla de 3": three_variable_rule(test),
 "logística de 5": score_rows(fit_logistic(train), test),
 "logística + interacción": score_with_interaction(fit_with_interaction(train), test),
 "red neuronal": score_network(net, scaler, test),
}
never = -sum(y)   # no sobreagendar nada: se pierde una consulta por cada inasistencia
print(f"no sobreagendar nada: {never:,} consultas perdidas sobre {len(y):,} citas\n")
for ratio in (1.0, 2.0, 3.0, 4.0):
    print(f"--- una colisión cuesta {ratio:g}× una silla vacía · umbral p > {break_even(ratio):.2f} ---")
    for n,s in cands.items():
        dec=decide(s,ratio); real=realised_cost(s,dec,y,ratio)
        print(f"   {n:<26} sobreagenda {sum(dec):>6,} · neto frente a no hacer nada: {real-never:+8.0f} consultas")
