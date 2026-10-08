# rescatado de la sesión b74cbeda, 2026-09-13T04:10:59Z · Final structural and link check
import pathlib, re
fases = sorted([p for p in pathlib.Path(".").glob("*.md")
                if re.match(r"^(0[0-9]|1[0-7])-", p.name)],
               key=lambda p: p.name)
ok = True
for f in fases:
    t = f.read_text()
    secciones = len(re.findall(r"^## ", t, re.M))
    tag = len(re.findall(r"git tag -a fase-", t))
    ej = re.search(r"## 🧪 8\. Ejercicios \((\d+)\)", t)
    med = "## 📏 6" in t
    mini = "## 🧱 7" in t
    pend = "📌 Pendientes" in t
    estado = "✓" if (secciones == 11 and tag == 1 and ej and med and mini and pend) else "✗"
    if estado == "✗": ok = False
    print(f" {estado} {f.name:<42} secciones={secciones} tag={tag} ej={ej.group(1) if ej else '—'} 📏={med} 🧱={mini} 📌={pend}")
print("\nTODAS CONFORMES" if ok else "\nHAY FASES NO CONFORMES")
