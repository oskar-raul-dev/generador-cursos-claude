"""pandoc orquestado desde Python: costo por llamada, lo que se pierde en el viaje y el HTML que deja pasar."""

import shutil
import subprocess
import time

import pypandoc
from markdown_it import MarkdownIt

SOURCE = """# Informe de la sede Suba

La franquicia **cumplió** la meta de octubre.

| Sede | Estado |
|---|---|
| Suba | Cumplió |
| Zipaquirá | Pendiente |

Nota al pie de la tabla[^1].

[^1]: Cifras de muestra.

<script>alert("hola")</script>
"""

print("pandoc:", subprocess.run(["pandoc", "--version"], capture_output=True, text=True).stdout.splitlines()[0])


def pandoc(text, *args):
    return subprocess.run(["pandoc", *args], input=text, capture_output=True, text=True, check=True).stdout


# 1) Costo por llamada: el binario contra una biblioteca en el proceso
md = MarkdownIt("commonmark").enable("table")
start = time.perf_counter()
for _ in range(50):
    pandoc(SOURCE, "-f", "markdown", "-t", "html")
per_pandoc = (time.perf_counter() - start) / 50 * 1000
start = time.perf_counter()
for _ in range(50):
    md.render(SOURCE)
per_lib = (time.perf_counter() - start) / 50 * 1000
print(f"Markdown a HTML · pandoc {per_pandoc:5.1f} ms por documento · markdown-it-py {per_lib:5.2f} ms")

# 2) El HTML crudo: pandoc lo deja pasar salvo que se le quite la extensión
html = pandoc(SOURCE, "-f", "markdown", "-t", "html")
safe = pandoc(SOURCE, "-f", "markdown-raw_html", "-t", "html")
print(f"<script> en la salida · por defecto: {'<script>' in html} · con markdown-raw_html: {'<script>' in safe}")

# 3) El viaje de ida y vuelta: Markdown → Word → Markdown
pypandoc.convert_text(SOURCE, "docx", format="markdown", outputfile="informe.docx")
back = pypandoc.convert_file("informe.docx", "gfm")
print("después de pasar por Word:")
print("\n".join("  " + line for line in back.strip().splitlines()))
print(f"pypandoc llama al binario del sistema: {pypandoc.get_pandoc_path()!r} → {shutil.which('pandoc')}, versión {pypandoc.get_pandoc_version()}")
