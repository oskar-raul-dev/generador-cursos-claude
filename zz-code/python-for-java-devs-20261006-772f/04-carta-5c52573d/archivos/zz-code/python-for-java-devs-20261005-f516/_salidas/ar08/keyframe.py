import av, numpy as np
def frames(path):
    with av.open(path) as c:
        return [(f.time, f.to_ndarray(format="gray")) for f in c.decode(video=0)]
src = dict((round(t, 2), a) for t, a in frames("muestra.mp4"))
for path in ("corte_copia.mp4", "corte_recodificado.mp4", "corte_moviepy.mp4"):
    fs = frames(path)
    first = fs[0][1].astype(int)
    match = min(src, key=lambda t: np.abs(src[t].astype(int) - first).mean())
    print(path, len(fs), "cuadros; el primero es el del segundo", match, "del original; tiempos", fs[0][0], fs[-1][0])
