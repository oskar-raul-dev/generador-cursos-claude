# rescatado de la sesión 5c52573d, 2026-10-05T21:46:02Z · Check internal markdown links in carta
import re, pathlib
bad = 0
for p in sorted(pathlib.Path(".").glob("op*.md")):
    for target in re.findall(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)", p.read_text()):
        if target.startswith("http"): continue
        if not (p.parent / target).exists():
            bad += 1; print(p.name, "→", target)
print("enlaces rotos:", bad)
