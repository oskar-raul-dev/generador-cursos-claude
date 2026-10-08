"""Marca filas del plan de la carta: python3 plan.py <desde> <hasta> <escrita> <corrida>
y tandas: python3 plan.py tanda T1 ✅   ·   bitácora: python3 plan.py bitacora 'texto'"""
import re, sys, pathlib
P = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md")
t = P.read_text(encoding="utf-8")
a = sys.argv[1:]
if a[0] == "tanda":
    t = re.sub(rf"^(\| \*\*{a[1]}\*\* \|.*\| )(⬜|🟡|✅) \|$", rf"\g<1>{a[2]} |", t, flags=re.M)
elif a[0] == "bitacora":
    t = t.replace("## 7. 📓 Bitácora\n\n", "## 7. 📓 Bitácora\n\n" + a[1].strip() + "\n\n", 1)
elif a[0] == "dondeesta":
    t = re.sub(r"> 🚦 \*\*Dónde está la producción.*?(?=\n\n)", "> 🚦 **Dónde está la producción (" + __import__("datetime").date.today().strftime("%d/%m/%Y") + "):** " + a[1], t, flags=re.S)
else:
    desde, hasta, esc, cor = int(a[0]), int(a[1]), a[2], a[3]
    for n in range(desde, hasta + 1):
        t = re.sub(rf"^(\| op{n:03d} \| .*? \| .*? \| )(\S+) \| (\S+) \|$", rf"\g<1>{esc} | {cor} |", t, flags=re.M)
P.write_text(t, encoding="utf-8")
