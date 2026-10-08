# rescatado de la sesión 2859734a, 2026-09-14T02:04:25Z · Test whether one hand-written interaction closes the gap
import random
from pathlib import Path
from shared import *
from net import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)

# la logística con el término de interacción que el generador SÍ tiene (lluvia × distancia)
import features as F
orig = F._value
def patched(row, column):
    if column == "lluvia_x_distancia":
        return float(row["lluvia_mm"]) * float(row["distancia_km"])
    return orig(row, column)
F._value = patched
cols = [*HONEST, "lluvia_x_distancia"]

net, scaler, rep = train_network(train)
cands = {
 "logística 5": score_rows(fit_logistic(train), test),
 "logística 5 + interacción": score_rows(fit_logistic(train, cols), test, cols),
 "red neuronal": score_network(net, scaler, test),
}
for n,s in cands.items(): print(f"{n:<28} AUC {roc_auc(s,y):.4f}")

# ¿es real la diferencia? bootstrap sobre el tramo de prueba
rng=random.Random(20260913); idx=list(range(len(y)))
base=cands["logística 5"]; nn=cands["red neuronal"]; inter=cands["logística 5 + interacción"]
diffs_nn=[]; diffs_in=[]
for _ in range(200):
    sample=[idx[rng.randrange(len(idx))] for _ in idx]
    yy=[y[i] for i in sample]
    a=roc_auc([base[i] for i in sample], yy)
    diffs_nn.append(roc_auc([nn[i] for i in sample], yy)-a)
    diffs_in.append(roc_auc([inter[i] for i in sample], yy)-a)
for name,dd in (("red − logística", diffs_nn), ("interacción − logística", diffs_in)):
    dd.sort(); print(f"{name:<28} Δ {sum(dd)/len(dd):+.4f}  IC95 [{dd[5]:+.4f}, {dd[194]:+.4f}]")
