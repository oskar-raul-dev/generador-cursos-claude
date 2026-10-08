# Paso 0: el mismo código de Python, sin una sola anotación.
def ema(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
