# rescatado de la sesión 5c52573d, 2026-10-05T21:50:34Z · Check prompts links, verifier, pycache ignore
import re, pathlib
bad=0
for p in sorted(pathlib.Path("prompts").glob("*.md")):
    for t in re.findall(r"\]\(([^)#\s]+)(?:#[^)]*)?\)", p.read_text()):
        if t.startswith(("http","mailto")): continue
        if not (p.parent/t).exists(): bad+=1; print(p.name,"→",t)
print("enlaces rotos en prompts/:", bad)
