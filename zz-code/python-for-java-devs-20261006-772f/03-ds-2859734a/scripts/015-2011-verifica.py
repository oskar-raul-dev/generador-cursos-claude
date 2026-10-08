# rescatado de la sesión 2859734a, 2026-09-13T20:11:50Z · Get overflow and view/copy numbers
import numpy as np
from acquisition import read_spend_arrays, total_spend_with_dtype, read_spend_rows, arrays_from_rows
from pathlib import Path
s = read_spend_arrays(Path("data/pauta.csv"))
print("filas reales:", len(s))
print("int64:", f"{total_spend_with_dtype(s, np.int64):,}")
print("int32:", f"{total_spend_with_dtype(s, np.int32):,}")
# ¿a partir de cuántas filas se rompe int32?
import itertools
cost = s.cost
run = np.cumsum(cost)
bad = np.argmax(run > 2**31-1)
print("primera fila donde int32 desborda:", bad, "· acumulado:", f"{int(run[bad]):,}")
# vistas y copias
a = s.cost[:5].copy()
view = s.cost[:5]
print("vista antes:", s.cost[:5])
view[:] = 0
print("original después de tocar la vista:", s.cost[:5])
s.cost[:5] = a
print("restaurado:", s.cost[:5])
