# rescatado de la sesión 2859734a, 2026-09-14T01:40:39Z · Compare three split strategies against two feature sets
import random
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)
rng=random.Random(20260913); shuffled=rows[:]; rng.shuffle(shuffled)
rt, rs = shuffled[:len(train)], shuffled[len(train):]
# partición por paciente: ningún paciente en los dos lados
patients=sorted({r["paciente_id"] for r in rows}); rng2=random.Random(7); rng2.shuffle(patients)
held=set(patients[:len(patients)//3])
gt=[r for r in rows if r["paciente_id"] not in held]; gs=[r for r in rows if r["paciente_id"] in held]
leaky=HONEST+[LEAKY]
print(f"{'partición':<26}{'honestas':>12}{'con fuga':>12}")
for name, (a,b) in {"temporal": (train,test), "al azar": (rt,rs), "por paciente": (gt,gs)}.items():
    _, y = build_matrix(b)
    h = roc_auc(score_rows(fit_logistic(a), b), y)
    l = roc_auc(score_rows(fit_logistic(a, leaky), b, leaky), y)
    print(f"{name:<26}{h:>12.3f}{l:>12.3f}")
print(f"\ncitas por paciente en el conjunto: {len(rows)/len(patients):.1f}")
same = sum(1 for r in rs if r["paciente_id"] in {x["paciente_id"] for x in rt[:5000]})
print("con partición al azar, un paciente aparece en los dos lados casi siempre")
