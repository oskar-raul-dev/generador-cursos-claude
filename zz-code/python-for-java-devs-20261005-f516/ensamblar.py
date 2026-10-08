"""Arma una sección desde una plantilla con __CODIGO__/__SALIDA__ (o __CODIGO:archivo__ y __SALIDA:archivo__). Desde T20 (07/10/2026).

Uso: python3 ensamblar.py salidas/<id>/seccion.md <opNNN-….md> [codigo.py salida.txt]
"""
import pathlib, re, sys
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
src = pathlib.Path(sys.argv[1]); d = src.parent
t = src.read_text(encoding="utf-8")
if len(sys.argv) > 3:
    t = t.replace("__CODIGO__", f"__CODIGO:{sys.argv[3]}__").replace("__SALIDA__", f"__SALIDA:{sys.argv[4]}__")
t = re.sub(r"__(?:CODIGO|SALIDA):([^_]+(?:_[^_]+)*)__", lambda m: (d / m.group(1)).read_text(encoding="utf-8").strip("\n"), t)
assert "__CODIGO" not in t and "__SALIDA" not in t, "quedaron marcadores"
(CARTA / sys.argv[2]).write_text(t, encoding="utf-8")
print("escrita:", sys.argv[2], len(t.splitlines()), "líneas")
