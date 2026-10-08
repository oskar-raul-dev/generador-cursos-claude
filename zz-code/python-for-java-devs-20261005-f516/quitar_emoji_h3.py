"""Publicación (07/10/2026): quita los emoji de los encabezados ### del curso, salvo la escala de dificultad,
y corrige los enlaces a las anclas que cambian. Uso: python3 quitar_emoji_h3.py [--aplicar]
"""
import pathlib, re, sys, unicodedata

CURSO = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
PERMITIDOS = {"🟢", "🟡", "🟠", "🔴", "🔥", "💀"}


def es_emoji(c):
    cp = ord(c)
    return unicodedata.category(c) == "So" or 0x1F000 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF


def limpiar(titulo):
    out = "".join(c for c in titulo if c in PERMITIDOS or not (es_emoji(c) or c in "️‍"))
    out = re.sub(r"\s+", " ", out).strip()
    return re.sub(r"^· ", "", out).replace(" · ·", " ·")


def slug(titulo):
    t = titulo.strip().lower()
    t = "".join(c for c in t if c.isalnum() or c in " -_")
    return t.replace(" ", "-")


archivos = [p for p in CURSO.rglob("*.md") if "prompts" not in p.parts]
cambios, anclas = 0, {}                                  # archivo → {slug viejo: slug nuevo}
nuevos = {}
for p in archivos:
    lineas, dentro, mapa = p.read_text(encoding="utf-8").split("\n"), False, {}
    for i, l in enumerate(lineas):
        if re.match(r"^\s*(```|~~~)", l):
            dentro = not dentro
        m = None if dentro else re.match(r"^(###) (.*)$", l)
        if m and any(es_emoji(c) and c not in PERMITIDOS for c in m.group(2)):
            nuevo = limpiar(m.group(2))
            mapa[slug(m.group(2))] = slug(nuevo)
            lineas[i] = f"### {nuevo}"
            cambios += 1
    if mapa:
        anclas[p] = mapa
        nuevos[p] = "\n".join(lineas)
print(f"{cambios} encabezados en {len(anclas)} archivos")
enlaces = 0
for p in archivos:
    t = nuevos.get(p, p.read_text(encoding="utf-8"))
    def arreglar(m):
        global enlaces
        destino, ancla = m.group(1), m.group(2)
        objetivo = (p.parent / destino).resolve() if destino else p
        mapa = anclas.get(objetivo, {})
        if ancla in mapa:
            enlaces += 1
            return f"]({destino}#{mapa[ancla]})"
        return m.group(0)
    t2 = re.sub(r"\]\(([^)#\s]*)#([^)\s]+)\)", arreglar, t)
    if t2 != t or p in nuevos:
        nuevos[p] = t2
print(f"{enlaces} enlaces a anclas corregidos")
if "--aplicar" in sys.argv:
    for p, t in nuevos.items():
        p.write_text(t, encoding="utf-8")
    print("aplicado")
else:
    for p, mapa in list(anclas.items())[:3]:
        print(p.name, list(mapa.items())[:2])
