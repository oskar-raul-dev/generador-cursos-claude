# rescatado de la sesión 5c52573d, 2026-10-05T21:16:32Z · Check numba exactness vs Python
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff04 && timeout 400 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; python -c "
import numpy as np
from numba import njit
@njit
def ema(x, alpha):
    out = np.empty_like(x); s = x[0]
    for i in range(x.shape[0]):
        s = alpha * x[i] + (1 - alpha) * s; out[i] = s
    return out
x = np.sin(np.arange(2_000_000) / 1000) * 100 + 500
ref = []; s = x[0]
for v in x.tolist():
    s = 0.1 * v + 0.9 * s; ref.append(s)
print(np.abs(ema(x, 0.1) - np.array(ref)).max())"'
