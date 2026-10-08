# rescatado de la sesión 2859734a, 2026-09-14T01:43:48Z · Correct the predict claim with the measured number
from pathlib import Path
from features import *
from model import *
from baseline import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
m,y=build_matrix(test); pipe=fit_logistic(train)
marked=int(sum(pipe.predict(m)))
print(f"predict marca {marked:,} de {len(test):,} ({marked/len(test):.1%}) · tasa real {sum(y)/len(y):.1%}")
s=score_rows(pipe,test); p,r,n=precision_recall(s,y,0.5)
print(f"a umbral 0,5: precisión {p:.3f} recall {r:.3f} marcadas {n:,}")
