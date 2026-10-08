# rescatado de la sesión b74cbeda, 2026-09-13T04:10:59Z · Final structural and link check
import pathlib, re
existentes = {p.name for p in pathlib.Path(".").glob("*.md")}
rotos = 0
for f in pathlib.Path(".").glob("*.md"):
    for destino in re.findall(r"\]\((?!http)([^)#]+\.md)\)", f.read_text()):
        if destino not in existentes:
            print(f"  {f.name} -> {destino}"); rotos += 1
print("  ninguno" if not rotos else f"  {rotos} rotos")
