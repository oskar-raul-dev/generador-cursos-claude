# rescatado de la sesión 2859734a, 2026-09-14T02:06:12Z · Measure calibration and the overbooking decision
import pickle
from pathlib import Path
from shared import *
from net import *
from engineered import *
from calibration import *
from overbooking import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, rep = train_network(train)
cands = {
 "regla de 3": three_variable_rule(test),
 "logística de 5": score_rows(fit_logistic(train), test),
 "logística + interacción": score_with_interaction(fit_with_interaction(train), test),
 "red neuronal": score_network(net, scaler, test),
}
print(f"{'candidato':<26}{'AUC':>8}{'Brier':>9}{'ECE':>8}")
for n,s in cands.items():
    print(f"{n:<26}{roc_auc(s,y):>8.4f}{brier_score(s,y):>9.4f}{expected_calibration_error(s,y):>8.4f}")
print("\nfiabilidad por decil (red neuronal): predicho → observado")
for p,o,c in reliability(cands["red neuronal"], y): print(f"  {p:.3f} → {o:.3f}  (n={c:,})")
print(f"\numbral de sobreagendamiento con ratio {COLLISION_RATIO}: p > {break_even():.2f}")
for n,s in cands.items():
    dec = decide(s); over=sum(dec)
    print(f"  {n:<26} sobreagenda {over:>5} de {len(s):,} cupos", end="")
    if over: print(f" · esperado {expected_cost(s,dec):+.1f} · real {realised_cost(s,dec,y):+.1f}")
    else: print()
for ratio in (1.0, 1.5, 2.0):
    s=cands["red neuronal"]; dec=decide(s,ratio)
    print(f"  ratio {ratio}: umbral {break_even(ratio):.2f} · sobreagenda {sum(dec):,} · esperado {expected_cost(s,dec,ratio):+.0f} · real {realised_cost(s,dec,y,ratio):+.0f}")
print(f"\nartefactos: red {len(pickle.dumps(net))/1024:.1f} KB · logística {len(pickle.dumps(fit_logistic(train)))/1024:.1f} KB")
print(f"entrenamiento red {rep.seconds:.1f} s · parámetros {rep.parameters}")
