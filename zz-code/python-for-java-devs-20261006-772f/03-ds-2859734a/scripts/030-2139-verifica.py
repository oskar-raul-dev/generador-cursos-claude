# rescatado de la sesión 2859734a, 2026-09-13T21:39:37Z · Check the four engines agree
from pathlib import Path
from consolidation import ENGINES
out={}
for name, fn in ENGINES.items():
    try:
        rows = fn(Path("data")); out[name]=rows
        print(f"{name:14s} {len(rows):>4} filas · primera {rows[0]}")
    except Exception as e:
        print(f"{name:14s} ERROR {type(e).__name__}: {e}")
ref = out.get("bucle")
for name, rows in out.items():
    if name=="bucle": continue
    print(f"{name:14s} == bucle:", rows==ref)
    if rows!=ref:
        for a,b in zip(ref,rows):
            if a!=b: print("   ref:",a,"\n   otr:",b); break
