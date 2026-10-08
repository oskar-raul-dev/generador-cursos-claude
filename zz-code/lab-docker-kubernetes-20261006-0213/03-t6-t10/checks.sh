#!/bin/bash
# Las verificaciones de §4 del plan, desde la raíz del curso.
python3 - <<'PY'
import re, os, glob
def slug(h): return re.sub(r'[^\w\- ]', '', h.strip().lower()).replace(' ', '-')
def anchors(path):
    body = re.sub(r'```.*?```', '', open(path, encoding='utf-8').read(), flags=re.S)
    return {slug(h) for h in re.findall(r'^#{1,6} (.+)$', body, re.M)}
for f in glob.glob('**/*.md', recursive=True):
    if '/node_modules/' in f or '/vendor/' in f: continue
    body = re.sub(r'````.*?````', '', open(f, encoding='utf-8').read(), flags=re.S)
    body = re.sub(r'```.*?```', '', body, flags=re.S)
    for link in re.findall(r'\]\(([^)]+)\)', body):
        if link.startswith('http') or link == '#': continue
        path, _, anc = link.partition('#')
        target = os.path.normpath(os.path.join(os.path.dirname(f), path)) if path else f
        if path and not os.path.exists(target): print('ROTO', f, link)
        elif anc and target.endswith('.md') and anc not in anchors(target): print('ANCLA', f, link)
PY
echo "--- desechables/prompts:"; grep -ln "_desechable-\|prompts/" *.md
echo "--- otros cursos:"; grep -n "cursos-\|ruta-sql\|ruta-no-sql\|docker-container-legacy" *.md
echo "--- Ingress:"; grep -rn "kind: Ingress$" src/lab
echo "--- README:"; git status --short -- ':(glob)**/README.md'; ls 0-ESTRUCTURA-CURSO.md 2>/dev/null
echo "--- ejercicios y cuerpo:"; for f in [0-9][0-9]-*.md; do n=$(grep -cE '^### (🟢|🟡|🟠|🔴) Ejercicio [0-9]+' "$f"); w=$(sed '/^## 🧪/,$d' "$f" | wc -w); printf '%-45s %3s %6s\n' "$f" "$n" "$w"; done
echo "--- incidentes:"; grep -oE '^### 🩺 Incidente [0-9]+' cuaderno-incidentes.md | sort -u | tr '\n' ' '; echo
