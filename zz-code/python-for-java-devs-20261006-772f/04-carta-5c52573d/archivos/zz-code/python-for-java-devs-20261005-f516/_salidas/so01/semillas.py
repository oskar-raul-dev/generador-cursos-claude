import random, re, pathlib
src = pathlib.Path("reparto_sabado.py").read_text()
body = src.split("g = greedy()")[0]
for seed in range(1, 21):
    ns = {}
    exec(body.replace("random.seed(4)", f"random.seed({seed})"), ns)
    g = ns["greedy"](); gm = sum(ns["minutes"][e, s] for s, e in g.items())
    _, opt, _ = ns["model"]()
    print(seed, gm, int(opt), f"{(gm/opt-1)*100:.0f}%")
