"""Convierte 'Fase NN' (o 'la Fase NN' en prosa) en enlace al archivo de la fase, fuera de bloques de código."""
import re, sys, glob
nn, target = sys.argv[1], sys.argv[2]
skip = {"00-historia-de-la-vecina.md", target}
for f in sorted(glob.glob("*.md")):
    if f in skip: continue
    lines = open(f, encoding="utf-8").read().split("\n"); fence = False; changed = 0
    for i, l in enumerate(lines):
        if l.lstrip().startswith("```"): fence = not fence; continue
        if fence or target in l: continue
        new = re.sub(rf"(?<!\[)\bFase {nn}\b(?!\])", f"[Fase {nn}]({target})", l, count=1)
        if new != l: lines[i] = new; changed += 1
    if changed:
        open(f, "w", encoding="utf-8").write("\n".join(lines)); print(f, changed)
