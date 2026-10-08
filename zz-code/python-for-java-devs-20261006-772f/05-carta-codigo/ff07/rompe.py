"""Lo que se rompe: una extensión que no declara soporte sin GIL, y NumPy dentro de un subintérprete."""

import subprocess
import sys
from concurrent import interpreters

subprocess.run([sys.executable, "-m", "Cython.Build.Cythonize", "-q", "-i", "-3", "ema_v3.pyx"], check=True, capture_output=True)
print("GIL antes de importar la extensión:", sys._is_gil_enabled())
import ema_v3  # noqa: E402,F401
print("GIL después:", sys._is_gil_enabled())

interp = interpreters.create()
try:
    interp.exec("import numpy")
except interpreters.ExecutionFailed as error:
    original = error.excinfo.msg.strip().splitlines()[-1]          # el mensaje de NumPy culpa a la instalación; la causa está al final
    print("numpy en un subintérprete:", error.excinfo.type.__name__, "·", original)
finally:
    interp.close()
