# rescatado de la sesión aadc4f68, 2026-09-13T17:25:22Z · 
import re,glob,os
malos=[]
for f in glob.glob("*.md")+glob.glob("prompts/*.md"):
    base=os.path.dirname(f)
    for m in re.finditer(r'\]\(([^)#:]+\.md)(?:#[^)]*)?\)', open(f,encoding='utf-8').read()):
        t=m.group(1)
        if not os.path.exists(os.path.join(base,t)):
            malos.append((f,t))
for f,t in malos: print(f"  {f} -> {t}")
print("  (ninguno)" if not malos else f"\n  {len(malos)} rotos")
