"""Fix ANCLA-FE0F findings: rewrite each anchor to the form GitHub generates.

Reads the base verifier output and replaces, on the reported line only, the anchor
written without U+FE0F with the one the verifier computed.
"""
import re
import subprocess
import sys

course = sys.argv[1]
out = subprocess.run(
    [sys.executable, "-B", "zz-instrucciones/herramientas/verificador_base.py", course, "--perfil=courses-ia"],
    capture_output=True, text=True).stdout
pat = re.compile(r"^ERROR ANCLA-FE0F (\S+):(\d+) → (\S*?)(#\S+) \(en GitHub es (#\S+)\)$")
fixes = 0
for line in out.splitlines():
    m = pat.match(line)
    if not m:
        continue
    doc, lineno, target, bad, good = m.groups()
    path = f"{course}/{doc}"
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    i = int(lineno) - 1
    old = f"({target}{bad})"
    if old not in lines[i]:
        print("NOT FOUND", doc, lineno, old)
        continue
    lines[i] = lines[i].replace(old, f"({target}{good})")
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    fixes += 1
print("fixed", fixes)
