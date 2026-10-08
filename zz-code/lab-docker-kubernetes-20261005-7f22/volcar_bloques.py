"""Vuelca los bloques text/sin lenguaje con marcas de diagrama, numerados, para clasificarlos."""
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
BOX = re.compile(r"[─│┌┐└┘├┤┬┴┼═║╔╗╚╝▶▼▲◀►→←↓↑⟶]|-->|==>|\+--|--\+")
n = 0
for md in sorted(root.glob("*.md")):
    if md.name == "ajuste_estructura.md":
        continue
    lines = md.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(```+)(\S*)\s*$", lines[i])
        if m:
            fence, lang, start = m.group(2), m.group(3), i
            j = i + 1
            while j < len(lines) and not re.match(r"^\s*" + fence + r"\s*$", lines[j]):
                j += 1
            body = lines[start + 1:j]
            hits = sum(1 for l in body if BOX.search(l))
            if lang in ("", "text") and hits >= 2:
                n += 1
                print(f"=== #{n} {md.name}:{start+1} lineas={len(body)}")
                print("\n".join(body))
            i = j + 1
        else:
            i += 1
