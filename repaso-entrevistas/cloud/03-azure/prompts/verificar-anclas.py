#!/usr/bin/env python3
# Comprueba que todo enlace con ancla (#...) del curso apunte a un encabezado existente,
# con la regla de GitHub: minúsculas, se borra todo lo que no sea letra, número, espacio,
# guion o guion bajo, y los espacios pasan a guiones. El selector U+FE0F de ⚠️, ⚙️… se
# conserva, como en GitHub. Se corre desde 03-azure/.
import glob, os, re, sys

def slug(encabezado):
    h = re.sub(r"[^\w\- \ufe0f]", "", encabezado.strip().lower())
    return h.replace(" ", "-")

def anclas(ruta):
    texto = open(ruta, encoding="utf-8").read()
    texto = re.sub(r"(?ms)^```.*?^```", "", texto)  # los bloques de código no cuentan
    return texto, {slug(m.group(1)) for m in re.finditer(r"^#{1,6} (.+)$", texto, re.M)}

problemas = 0
for doc in sorted(glob.glob("*.md")):
    texto, propias = anclas(doc)
    for m in re.finditer(r"\]\(([^)#\s]*)#([^)]+)\)", texto):
        destino, ancla = m.group(1), m.group(2)
        if destino and not os.path.exists(destino):
            print(f"ARCHIVO ROTO {doc} -> {destino}"); problemas += 1; continue
        validas = propias if not destino else anclas(destino)[1]
        if ancla not in validas:
            print(f"ANCLA ROTA {doc} -> {destino}#{ancla}"); problemas += 1
print(f"anclas: {problemas} problemas")
sys.exit(1 if problemas else 0)
