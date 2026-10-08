#!/usr/bin/env python3
# =============================================================================
#  controles-texto.py — controles 5, 6 y 7 de verificar-corpus.sh.
#
#    python3 prompts/controles-texto.py        # desde la raíz del corpus
#
#  5. Anclas: cada enlace con `#ancla` apunta a un encabezado que existe, con el
#     cálculo de GitHub (minúsculas, se borra lo que no es letra, número,
#     espacio, guion o guion bajo, y los espacios pasan a guiones). El selector
#     de variación U+FE0F de ⚠️, ⚙️… se conserva, como en GitHub.
#  6. Ancho: la prosa no pasa de 100 caracteres —caracteres, no bytes, y sin
#     contar el U+FE0F invisible de las anclas—. Quedan
#     fuera los bloques de código, las tablas y las líneas que son solo una URL
#     o solo un enlace. Un `code span` partido entre dos líneas no es fallo
#     —GitHub lo pinta con un espacio— y la guía no lo prohíbe.
#  7. Sincronía literal: cada enunciado del solucionario es copia exacta del de
#     su capítulo, y lo mismo las `S#` y los títulos de escenario.
#
#  Sale con código 1 si alguno falla. `prompts/` queda fuera, como en los otros.
# =============================================================================
import glob, os, re, sys, unicodedata
from urllib.parse import unquote

os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
docs = sorted(p for p in glob.glob("**/*.md", recursive=True)
              if not p.startswith("prompts/") and "node_modules" not in p)


def lineas_fuera_de_codigo(path):
    fence = False
    with open(path, encoding="utf-8") as f:
        for i, linea in enumerate(f, 1):
            linea = linea.rstrip("\n")
            if re.match(r"^\s*(```|~~~)", linea):
                fence = not fence
                continue
            if not fence:
                yield i, linea


# --- 5. Anclas ---------------------------------------------------------------
def slug(h):
    h = h.strip().lower()
    return "".join(c for c in h
                   if c in " -_\ufe0f" or unicodedata.category(c)[0] in "LN").replace(" ", "-")


_anclas = {}
def anclas(path):
    if path not in _anclas:
        vistos, res = {}, set()
        for _, linea in lineas_fuera_de_codigo(path):
            m = re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", linea)
            if m:
                s = slug(m.group(2))
                n = vistos.get(s, 0)
                res.add(s if n == 0 else f"{s}-{n}")
                vistos[s] = n + 1
        _anclas[path] = res
    return _anclas[path]


def control_anclas():
    rotas = []
    enlace = re.compile(r"\]\(([^)\s]*?)(#[^)\s]+)\)")
    for p in docs:
        d = os.path.dirname(p)
        for i, linea in lineas_fuera_de_codigo(p):
            for destino, frag in enlace.findall(linea):
                if destino.startswith("http"):
                    continue
                tp = p if destino == "" else os.path.normpath(os.path.join(d, unquote(destino)))
                if tp.endswith(".md") and os.path.exists(tp) and unquote(frag[1:]) not in anclas(tp):
                    rotas.append(f"{p}:{i}  {destino}{frag}")
    return rotas


# --- 6. Ancho ----------------------------------------------------------------
def control_ancho():
    malas = []
    solo = re.compile(r"<https?://\S+>\.?|\[[^\]]+\]\([^)]+\)[.,]?")
    for p in docs:
        for i, linea in lineas_fuera_de_codigo(p):
            if linea.lstrip().startswith("|"):
                continue
            nucleo = re.sub(r"^\s*(>\s*)?(-\s+|\d+\.\s+)?", "", linea)
            ancho = len(linea.replace("️", ""))   # el U+FE0F de las anclas no ocupa
            if ancho > 100 and not solo.fullmatch(nucleo):
                malas.append(f"{p}:{i}  ancha ({ancho})")
    return malas


# --- 7. Sincronía literal -----------------------------------------------------
def norm(t):
    return " ".join(t.replace("**", "").split())


def control_sincronia():
    malas = []
    for bloque in sorted(glob.glob("[0-9][0-9]-*/")):
        sol = glob.glob(bloque + "*-respuestas.md")
        if not sol:
            continue
        r = open(sol[0], encoding="utf-8").read()
        respuestas = {(nn, int(n)): norm(t) for nn, n, t in
                      re.findall(r"^\*\*(\d\d) → (\d+)\.\*\* (.*?)\n\n", r, re.S | re.M)}
        for f in sorted(glob.glob(bloque + "[0-9][0-9]-*.md") + glob.glob(bloque + "l[0-9][0-9]-*.md")):
            nombre = os.path.basename(f)
            if "respuestas" in nombre or "simulacion" in nombre:
                continue
            nn = nombre[1:3] if nombre.startswith("l") else nombre[:2]
            s = open(f, encoding="utf-8").read()
            if "## 🧠 Preguntas" not in s:
                continue
            q = s[s.index("## 🧠 Preguntas"):].split("\n---")[0]
            for n, t in re.findall(r"^(\d+)\. (.*?)(?=^\d+\. |\Z)", q, re.S | re.M):
                if respuestas.get((nn, int(n))) != norm(t):
                    malas.append(f"{f}  pregunta {n}")
        for sim in glob.glob(bloque + "*-simulacion-de-entrevista.md"):
            nn = os.path.basename(sim)[:2]
            s = open(sim, encoding="utf-8").read()
            sol_s = {n: norm(t) for n, t in
                     re.findall(r"^\*\*" + nn + r" → S(\d+)\.\*\* (.*?)\n\n", r, re.S | re.M)}
            for n, t in re.findall(r"^\*\*S(\d+)\.\*\* (.*?)\n\n", s, re.S | re.M):
                if sol_s.get(n) != norm(t):
                    malas.append(f"{sim}  S{n}")
            sol_e = {n: norm(t) for n, t in re.findall(
                r"^\*\*" + nn + r" → E(\d+)\.\*\* (?:\*\*)?Escenario \d+ — (.*?)(?:\*\*)?$", r, re.M)}
            for n, t in re.findall(r"^### Escenario (\d+) — (.*)$", s, re.M):
                if sol_e.get(n) != norm(t):
                    malas.append(f"{sim}  escenario {n}")
    return malas


fallos = 0
for titulo, control in (("5. Anclas", control_anclas),
                        ("6. Ancho de prosa", control_ancho),
                        ("7. Sincronía literal de enunciados", control_sincronia)):
    print(f"== {titulo} ==")
    res = control()
    for linea in res:
        print("  " + linea)
    if res:
        fallos += 1
    else:
        print("  (ninguno)")
sys.exit(1 if fallos else 0)
