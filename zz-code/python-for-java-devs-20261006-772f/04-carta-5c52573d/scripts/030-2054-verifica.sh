# rescatado de la sesión 5c52573d, 2026-10-05T20:54:34Z · Rerun ff04 from doc, check signatures claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/ff04/__pycache__ && python3 humo.py op142-ff04-numba.md ff04 'jit.py=@jit.py' --pip numba==0.68.0 --cmd 'python3 -X importtime -c "import numba" 2>&1 | tail -1; python3 jit.py; python3 jit.py | head -1; python3 -c "
import numpy as np, jit
jit.ema(np.zeros(3, dtype=np.float32), 0.1); print(jit.ema.signatures)" | tail -1'
