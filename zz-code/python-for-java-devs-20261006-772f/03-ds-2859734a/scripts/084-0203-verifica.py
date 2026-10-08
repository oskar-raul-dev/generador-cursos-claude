# rescatado de la sesión 2859734a, 2026-09-14T02:03:45Z · Train the network and compare against the baseline
from pathlib import Path
from shared import *
from net import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, rep = train_network(train)
print(f"épocas {rep.epochs_run} (mejor {rep.best_epoch}) · parámetros {rep.parameters} · {rep.seconds:.1f} s")
print(f"pérdida entrenamiento {rep.train_loss:.4f} · validación {rep.validation_loss:.4f}")
s_net = score_network(net, scaler, test)
s_log = score_rows(fit_logistic(train), test)
s_rule = three_variable_rule(test)
for name, s in (("regla", s_rule), ("logística", s_log), ("red", s_net)):
    th = threshold_for_capacity(s, 0.20); p,r,n = precision_recall(s, y, th)
    print(f"{name:<12} AUC {roc_auc(s,y):.4f} · precisión {p:.3f} · recall {r:.3f} · marca {n:,}")
