"""Compara la salida rotulada número N (desde 1) de una sección con un archivo de salida. Desde T20 (07/10/2026).

Uso: python3 comparar.py <seccion.md> <salida.txt> [N]   → IGUAL, o la diferencia línea a línea.
"""
import difflib, pathlib, re, sys
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
md = (CARTA / sys.argv[1]).read_text(encoding="utf-8")
n = int(sys.argv[3]) if len(sys.argv) > 3 else 1
blocks = re.findall(r"Salida (?:esperada, sin correr|\(Python 3\.14\.7, [\d/]+\)).*?:\n\n```text\n(.*?)\n```", md, re.S)
pub = blocks[n - 1].strip().splitlines()
got = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").strip().splitlines()
print("IGUAL" if pub == got else "\n".join(difflib.unified_diff(pub, got, "publicada", "corrida", lineterm="")))
