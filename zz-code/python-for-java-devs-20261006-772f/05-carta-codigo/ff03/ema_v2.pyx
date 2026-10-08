# Paso 2: memoryviews tipadas; el bucle ya no toca objetos de Python.
from cpython cimport array
import array


def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    result = array.array("d", bytes(8 * n))
    cdef double[:] out = result
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return result
