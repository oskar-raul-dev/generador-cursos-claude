# rescatado de la sesión 5c52573d, 2026-10-05T21:45:17Z · Cross-check plan vs files, headers; run verifier
import re, pathlib
plan = open("prompts/plan-de-produccion-carta.md").read()
rows = re.findall(r"^\| op(\d{3}) \| `([^`]+)` \| [^|]+ \| (\S+) \| (\S+) \|$", plan, re.M)
upto = [r for r in rows if int(r[0]) <= 156]
print("filas hasta op156:", len(upto))
for n, f, w, t in upto:
    p = pathlib.Path(f)
    problems = []
    if not p.exists(): problems.append("no existe")
    else:
        s = p.read_text()
        if "sin correr" in s: problems.append("queda 'sin correr'")
        if "Código probado" not in s: problems.append("encabezado sin 'Código probado'")
    if (w, t) != ("✅", "✅"): problems.append(f"marcas {w}{t}")
    if problems: print(f"op{n} {f}: {', '.join(problems)}")
extra = sorted(set(x.name for x in pathlib.Path(".").glob("op*.md")) - {f for _, f, _, _ in rows})
print("archivos op*.md fuera del plan:", extra)
