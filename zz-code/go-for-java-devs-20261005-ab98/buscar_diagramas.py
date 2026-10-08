"""Lista los bloques de código de los .md del curso que parecen diagramas (cajas, flechas, árboles)."""
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
BOX = re.compile(r"[─│┌┐└┘├┤┬┴┼═║╔╗╚╝▶▼▲◀►→←↓↑⟶]|-->|==>|\+--|--\+|\|\s*$")
for md in sorted(root.rglob("*.md")):
    lines = md.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(```+|~~~+)(\S*)", lines[i])
        if m:
            fence, lang, start = m.group(2), m.group(3), i
            j = i + 1
            while j < len(lines) and not lines[j].strip().startswith(fence):
                j += 1
            body = lines[start+1:j]
            hits = sum(1 for l in body if BOX.search(l))
            if lang in ("", "text", "txt", "mermaid", "plaintext", "ascii") and hits >= 2:
                print(f"{md.relative_to(root)}:{start+1} lang={lang or '-'} lineas={len(body)} marcas={hits}")
            i = j + 1
        else:
            i += 1
