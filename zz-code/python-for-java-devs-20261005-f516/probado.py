"""Marca una sección como probada: encabezado y rótulos. Uso: python3 probado.py <seccion.md>

Desde T20 (07/10/2026) toma la fecha del encabezado de la propia sección: «verificadas contra PyPI el DD/MM/AAAA».
"""
import pathlib, re, sys
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
p = CARTA / sys.argv[1]
t = p.read_text(encoding="utf-8")
m = re.search(r"> Versiones verificadas contra PyPI el (\d\d/\d\d/\d{4}) · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida\.", t)
assert m, "el encabezado no es el estándar"
fecha = m.group(1)
NEW = f"> Versiones verificadas contra PyPI el {fecha} · Código probado el {fecha} con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida."
t = t.replace(m.group(0), NEW).replace("Salida esperada, sin correr", f"Salida (Python 3.14.7, {fecha})")
p.write_text(t, encoding="utf-8")
print("probado:", p.name, fecha)
