"""T24 (07/10/2026): extrae de cada sección de la carta sus archivos de código y arma src/opNNN-…/.

Un bloque es un archivo si la línea no vacía anterior nombra un archivo entre comillas invertidas y
termina en ':' (`modelo.py`: · `rutas.py` escribe el barrio…:). Uso:
    python3 src_desde_secciones.py --informe          # qué reconoce, sin escribir nada
    python3 src_desde_secciones.py --escribir         # crea src/opNNN-…/ con los archivos y su README
"""
import pathlib, re, sys

CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
FILE = re.compile(r"`([\w./-]+\.(?:py|pyx|pyi|sh|toml|yaml|yml|json|sql|j2|jinja|html|css|js|ts|java|kt|c|h|cpp|hpp|rs|go|proto|xml|xsd|"
                  r"typ|tex|md|txt|cfg|ini|conf|service|timer|properties|csv|env|graphql|avsc|feature|mako|pt|mustache|dot|mmd)|"
                  r"Dockerfile[\w.-]*|Makefile|Caddyfile|\.env[\w.-]*)`")


def blocks(text):
    lines, i, out = text.splitlines(), 0, []
    while i < len(lines):
        m = re.match(r"^(`{3,})([\w+-]*)\s*$", lines[i])
        if m:
            fence, lang, j = m.group(1), m.group(2), i + 1
            while j < len(lines) and lines[j].rstrip() != fence:
                j += 1
            k = i - 1
            while k >= 0 and not lines[k].strip():
                k -= 1
            out.append((lines[k] if k >= 0 else "", lang, "\n".join(lines[i + 1:j]), i + 1))
            i = j + 1
        else:
            i += 1
    return out


RUN = re.compile(r"(?:python3?|uv run(?: --script)?|pytest|bash|sh)\s+(?:-\S+\s+)*([\w./-]+\.(?:py|sh))")


def paragraph_before(lines_before):
    """El párrafo inmediatamente anterior al bloque (hasta la línea en blanco)."""
    return " ".join(lines_before)


def files_of(md):
    text = md.read_text(encoding="utf-8")
    lines = text.splitlines()
    bl = blocks(text)
    found, conflicts, commands, unnamed = {}, [], [], []
    for idx, (before, lang, body, line) in enumerate(bl):
        b = before.strip()
        k, para = line - 2, []
        while k >= 0 and not lines[k].strip():
            k -= 1
        while k >= 0 and lines[k].strip() and not lines[k].startswith("```"):
            para.insert(0, lines[k].strip()); k -= 1
        para_text = " ".join(para)
        name = None
        if lang in ("text", "mermaid", "console", "diff") or para_text.startswith("Salida"):
            continue                                            # salidas y diagramas no son archivos
        if para_text.endswith(":") and not para_text.startswith(">") and (m := FILE.search(para_text)):
            name = m.group(1)
            if lang in ("bash", "sh") and not name.endswith(".sh"):
                name = None                                     # un bloque de comandos que menciona un archivo no es ese archivo
        elif lang in ("python", "py") and len(body.splitlines()) > 3 and (m := FILE.search(para_text)) and m.group(1).endswith(".py"):
            name = m.group(1)                                   # el párrafo nombra el archivo aunque no termine en ':'
        elif lang in ("python", "py") and len(body.splitlines()) > 3:
            for _, nlang, nbody, _ in bl[idx + 1: idx + 2]:      # el comando que lo corre, en el bloque siguiente
                if nlang in ("bash", "sh") and (m := RUN.search(nbody)) and m.group(1).endswith(".py"):
                    name = m.group(1).split("/")[-1]
                    break
            if name is None:
                unnamed.append(line)
        if name:
            if name in found and found[name][0] != body:
                conflicts.append((name, line))
                continue
            found.setdefault(name, (body, line))
        elif lang in ("bash", "sh") and re.search(r"\b(uv |pip |docker |python3? |pytest|bash |sh |make|cargo|gcc|javac|java )", body):
            commands.append(body)
    return found, conflicts, commands, unnamed


if __name__ == "__main__":
    total = empty = 0
    for md in sorted(CARTA.glob("op*.md")):
        found, conflicts, commands, unnamed = files_of(md)
        total += len(found)
        if not found:
            empty += 1
        if "--informe" in sys.argv and (not found or conflicts or unnamed):
            print(f"{md.name}: {len(found)} archivos · conflictos {conflicts} · bloques python sin nombre en líneas {unnamed}")
    print(f"{total} archivos en 176 secciones · {empty} secciones sin archivos reconocidos")


def describe(name, body):
    """La primera línea del docstring o del primer comentario: lo que el archivo dice de sí mismo."""
    lines = [l.strip() for l in body.strip().splitlines() if l.strip()]
    if not lines:
        return "—"
    first = lines[0]
    if first.startswith(('"""', "'''")):
        return first.strip("\"' ").rstrip(".") or (lines[1].rstrip(".") if len(lines) > 1 else "—")
    for l in lines[:3]:
        for mark in ("#", "//", "/*", "--", "<!--", ";"):
            if l.startswith(mark) and not l.startswith("#!") and not l.startswith("#include"):
                return l.lstrip("#/*-<!; ").rstrip("*/ ->").rstrip(".")
    return FALLBACK.get(pathlib.Path(name).suffix or pathlib.Path(name).name, FALLBACK.get(pathlib.Path(name).name, "—"))


FALLBACK = {
    "compose.yaml": "Los servicios del ejemplo, en contenedores", "pyproject.toml": "El proyecto y sus dependencias",
    "conftest.py": "Configuración compartida de pytest", ".xml": "Archivo de datos del ejemplo", ".xsd": "El esquema XSD del ejemplo",
    ".service": "Unidad de systemd", ".timer": "Temporizador de systemd", ".html": "La página del ejemplo",
    ".json": "Datos del ejemplo", ".csv": "Datos del ejemplo", ".yaml": "Configuración del ejemplo", ".yml": "Configuración del ejemplo",
    ".toml": "Configuración del ejemplo", ".sql": "Script SQL del ejemplo", ".proto": "El contrato Protobuf", ".j2": "Plantilla Jinja2",
    ".txt": "Archivo del ejemplo", ".md": "Documento del ejemplo", ".ini": "Configuración del ejemplo", ".cfg": "Configuración del ejemplo",
    "Dockerfile": "La imagen del ejemplo", ".graphql": "El esquema GraphQL",
}


def write_src():
    root = CARTA / "src"
    for md in sorted(CARTA.glob("op*.md")):
        found, _, commands, _ = files_of(md)
        text = md.read_text(encoding="utf-8")
        title = text.splitlines()[0].lstrip("# ").split(" ", 1)[1] if text.startswith("#") else md.stem
        partial = "probado en parte" in text[:1500]
        target = root / md.stem
        target.mkdir(parents=True, exist_ok=True)
        rows = []
        for name, (body, _) in found.items():
            path = target / name.lstrip("/")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(body.rstrip("\n") + "\n", encoding="utf-8")
            rows.append(f"| `{name.lstrip('/')}` | {describe(name, body).replace('|', '·')} |")
        run = "\n\n".join(c.strip() for c in commands[:4]) or "# la sección explica cómo se usa cada archivo"
        note = ("\n> ⚠️ **La sección se probó en parte**: su encabezado dice qué quedó sin correr y por qué.\n"
                if partial else "")
        readme = f"""# {title}

Código de la sección [`{md.name}`](../../{md.name}), extraído tal como se publica en ella. La sección
es la fuente: si este directorio y la sección difieren, manda la sección.
{note}
| Archivo | Qué es |
|---|---|
{chr(10).join(rows)}

## Cómo se corre

Los comandos de la sección, en orden (los que levantan servicios o instalan paquetes del sistema
están explicados allí):

```bash
{run}
```

La salida esperada es la que la sección muestra en su §3, rotulada con la fecha de su corrida en
contenedor con Python 3.14.7.
"""
        (target / "README.md").write_text(readme, encoding="utf-8")
    print("escritos", len(list(root.glob("op*"))), "directorios en", root)


if "--escribir" in sys.argv:
    write_src()
