# rescatado de la sesión 2859734a, 2026-09-14T01:39:09Z · First run of the baseline versus model comparison
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)
print(f"corte {cut} · entrenamiento {len(train):,} · prueba {len(test):,} ({len(test)/len(rows):.0%})")
_, y = build_matrix(test)
print(f"inasistencia en prueba: {sum(y)/len(y):.1%}\n")
cands = {
  "siempre asiste": always_attends(test),
  "regla 3 variables": three_variable_rule(test),
}
pipe = fit_logistic(train)
cands["logística 5 var"] = score_rows(pipe, test)
leaky_cols = HONEST + [LEAKY]
pipe_leak = fit_logistic(train, leaky_cols)
cands["logística + FUGA"] = score_rows(pipe_leak, test, leaky_cols)
for name, s in cands.items():
    auc = roc_auc(s, y)
    th = threshold_for_capacity(s, 0.20)
    p, r, n = precision_recall(s, y, th)
    print(f"{name:<20} AUC {auc:.3f} · marca {n:>6,} ({n/len(y):.0%}) · precisión {p:.3f} · recall {r:.3f}")
print("\ncoeficientes (datos escalados):")
for k,v in coefficients(pipe).items(): print(f"  {k:<26}{v:+.3f}")
