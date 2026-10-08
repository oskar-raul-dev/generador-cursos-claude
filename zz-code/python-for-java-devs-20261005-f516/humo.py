"""Prueba de humo de una sección de la carta, en contenedor.

Uso: python3 humo.py <seccion.md> <dir> <archivo=inicio-del-bloque>... [--pip paq==v ...] [--cmd "python x.py"]
- Cada <archivo=inicio> extrae el primer bloque de código cuyo contenido empieza con <inicio>
  (o, si <inicio> es '@archivo', el bloque que sigue a la línea "`archivo`:").
- Corre <cmd> en python:3.14.7 con --rm y la etiqueta del curso, montando salidas/<dir>.
"""
import pathlib, re, subprocess, sys

Z = pathlib.Path(__file__).parent
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
args = sys.argv[1:]
md, d = CARTA / args[0], Z / "salidas" / args[1]
d.mkdir(parents=True, exist_ok=True)
pips, cmd, specs, mode = [], None, [], "spec"
for a in args[2:]:
    if a == "--pip": mode = "pip"; continue
    if a == "--cmd": mode = "cmd"; continue
    if mode == "pip": pips.append(a)
    elif mode == "cmd": cmd = a
    else: specs.append(a)
text = md.read_text(encoding="utf-8")
def fenced(text):
    """(línea no vacía anterior a la cerca, contenido) de cada bloque de nivel superior."""
    out, lines, i = [], text.splitlines(), 0
    while i < len(lines):
        m = re.match(r"^(`{3,})[\w-]*\s*$", lines[i])
        if m:
            fence, j = m.group(1), i + 1
            while j < len(lines) and lines[j].rstrip() != fence:
                j += 1
            before = next((l for l in reversed(lines[:i]) if l.strip()), "")
            out.append((before, "\n".join(lines[i + 1:j])))
            i = j + 1
        else:
            i += 1
    return out
blocks = fenced(text)
for spec in specs:
    name, start = spec.split("=", 1)
    found = None
    for before, body in blocks:
        if start.startswith("@") and before.strip().rstrip(":").strip("`").endswith(start[1:]):
            found = body; break
        if not start.startswith("@") and body.startswith(start):
            found = body; break
    if found is None:
        sys.exit(f"no encontré el bloque para {spec}")
    (d / name).parent.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(found + "\n", encoding="utf-8")
inst = f"pip install -q --root-user-action=ignore {' '.join(pips)} >/dev/null 2>&1; " if pips else ""
r = subprocess.run(["docker", "run", "--rm", "--label", "curso=python-for-java-devs", "-v", f"{d}:/w",
                    "-w", "/w", "-e", "PYTHONPATH=/w", "-e", "COLUMNS=200", "python:3.14.7", "sh", "-c", inst + (cmd or "true")],
                   capture_output=True, text=True)
print(r.stdout[-6000:], r.stderr[-4000:], sep="\n")
