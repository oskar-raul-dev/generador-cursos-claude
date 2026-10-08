"""La misma función en Python y en C, llamada con ctypes y con cffi, y el primer segfault."""

import array
import ctypes
import math
import subprocess
import sys
import time

from cffi import FFI

subprocess.run(["gcc", "-O2", "-shared", "-fPIC", "-o", "libsuavizado.so", "suavizado.c"], check=True)

N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


def timed(fn):
    best = min(_once(fn) for _ in range(3))
    return f"{best * 1000:7.1f} ms"


def _once(fn):
    start = time.perf_counter(); fn(); return time.perf_counter() - start


# ctypes: se declara la firma a mano
lib = ctypes.CDLL("./libsuavizado.so")
lib.ema.argtypes = [ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double), ctypes.c_long, ctypes.c_double]
lib.ema.restype = None
lib.add.argtypes, lib.add.restype = [ctypes.c_double, ctypes.c_double], ctypes.c_double
out_c = array.array("d", bytes(8 * N))
as_ptr = lambda a: (ctypes.c_double * len(a)).from_buffer(a)


def ema_ctypes():
    lib.ema(as_ptr(x), as_ptr(out_c), N, ALPHA)


# cffi, modo ABI: la firma se copia del encabezado de C
ffi = FFI()
ffi.cdef("void ema(const double *x, double *out, long n, double alpha); double add(double a, double b);")
clib = ffi.dlopen("./libsuavizado.so")
out_f = array.array("d", bytes(8 * N))


def ema_cffi():
    clib.ema(ffi.from_buffer("double[]", x), ffi.from_buffer("double[]", out_f), N, ALPHA)


print(f"ema de {N:,} valores · Python {timed(lambda: ema_python(x, ALPHA))} · ctypes {timed(ema_ctypes)} · cffi {timed(ema_cffi)}")
ref = ema_python(x, ALPHA)
print("los tres coinciden:", max(abs(a - b) for a, b in zip(ref, out_c)) < 1e-9 and list(out_c) == list(out_f))

# El costo de cruzar: un millón de llamadas a una suma
calls = 1_000_000
py_add = lambda a, b: a + b
for name, f in (("Python", py_add), ("ctypes", lib.add), ("cffi", clib.add)):
    start = time.perf_counter()
    for _ in range(calls):
        f(1.0, 2.0)
    print(f"1M llamadas a add() · {name:<6} {(time.perf_counter() - start) * 1000:6.0f} ms")

# El primer segfault: leer la dirección 0
r = subprocess.run([sys.executable, "-X", "faulthandler", "-c", "import ctypes; ctypes.string_at(0)"],
                   capture_output=True, text=True)
print("código de salida:", r.returncode, "·", r.stderr.splitlines()[0])
