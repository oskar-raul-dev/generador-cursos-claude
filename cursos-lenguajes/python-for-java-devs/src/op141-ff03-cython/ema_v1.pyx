# Paso 1: tipos de C para los escalares.
def ema(x, double alpha):
    cdef double s = x[0], v
    cdef Py_ssize_t i
    out = [0.0] * len(x)
    for i in range(len(x)):
        v = x[i]
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
