# rescatado de la sesión 5c52573d, 2026-10-05T21:09:52Z · Verify small /dev/shm failure mode
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06 && timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'df -h /dev/shm | tail -1; timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; timeout 60 python -c "
import numpy as np
from multiprocessing import shared_memory
s = shared_memory.SharedMemory(create=True, size=200*2**20)
try:
    np.ndarray((25_000_000,), dtype=np.float64, buffer=s.buf)[:] = 1.0
    print(\"ok\")
finally:
    s.close(); s.unlink()
"; echo "salida: $?"'
