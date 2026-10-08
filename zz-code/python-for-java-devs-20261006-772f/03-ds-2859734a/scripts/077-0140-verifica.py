# rescatado de la sesión 2859734a, 2026-09-14T01:40:07Z · Measure split inflation and maintenance cost
import pickle, random, time, subprocess, sys, statistics
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)

print("=== partición temporal contra partición al azar ===")
_, y = build_matrix(test)
pipe = fit_logistic(train)
print(f"  temporal   AUC {roc_auc(score_rows(pipe,test), y):.3f}")
rng=random.Random(20260913); shuffled=rows[:]; rng.shuffle(shuffled)
cutpoint=len(train)
rt, rs = shuffled[:cutpoint], shuffled[cutpoint:]
_, ry = build_matrix(rs)
print(f"  al azar    AUC {roc_auc(score_rows(fit_logistic(rt), rs), ry):.3f}")

print("\n=== costo de mantener cada una ===")
t=[]
for _ in range(5):
    s=time.perf_counter(); fit_logistic(train); t.append((time.perf_counter()-s)*1000)
print(f"  entrenamiento logística: {statistics.median(t):.0f} ms")
t=[]
for _ in range(5):
    s=time.perf_counter(); score_rows(pipe,test); t.append((time.perf_counter()-s)*1000)
print(f"  predicción 33k filas:    {statistics.median(t):.1f} ms")
t=[]
for _ in range(5):
    s=time.perf_counter(); three_variable_rule(test); t.append((time.perf_counter()-s)*1000)
print(f"  regla 33k filas:         {statistics.median(t):.1f} ms")
blob=pickle.dumps(pipe); print(f"  artefacto pickle:        {len(blob)/1024:.1f} KB")
def cold(code):
    tt=[]
    for _ in range(5):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); tt.append((time.perf_counter()-s)*1000)
    tt.sort(); return statistics.median(tt)
print(f"  arranque + import sklearn: {cold('import sklearn.linear_model'):.0f} ms")
print(f"  arranque solo:             {cold('pass'):.0f} ms")
