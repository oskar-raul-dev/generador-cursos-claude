import array, ctypes, math, subprocess
N, A = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))
ref, s = [], x[0]
for v in x:
    s = A * v + (1 - A) * s; ref.append(s)
for flags in ([], ["-ffp-contract=off"]):
    subprocess.run(["gcc", "-O2", *flags, "-shared", "-fPIC", "-o", "l.so", "suavizado.c"], check=True)
    lib = ctypes.CDLL("./l.so" if not flags else "./l2.so") if False else None
    so = "l%d.so" % len(flags); subprocess.run(["cp", "l.so", so])
    lib = ctypes.CDLL("./" + so)
    lib.ema.argtypes = [ctypes.POINTER(ctypes.c_double)] * 2 + [ctypes.c_long, ctypes.c_double]
    out = array.array("d", bytes(8 * N))
    p = lambda a: (ctypes.c_double * N).from_buffer(a)
    lib.ema(p(x), p(out), N, A)
    print(flags, max(abs(a - b) for a, b in zip(out, ref)))
