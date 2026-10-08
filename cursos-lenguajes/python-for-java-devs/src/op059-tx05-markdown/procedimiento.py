"""El mismo procedimiento en tres bibliotecas de Markdown, y su índice sacado del árbol."""

import markdown
import mistune
from markdown_it import MarkdownIt

DOC = """\
# Cierre de caja

Pasos:

- Contar el efectivo
  - billetes
  - monedas
- Cuadrar contra el sistema

<script>alert('copiado de un foro')</script>

## Si no cuadra

Avisar a Cartera. Ver [el manual](https://intranet.aurea.example/cartera) y
[la planilla](planilla-de-cierre.xlsx).
"""

renderers = {
    "markdown-it (commonmark)": MarkdownIt("commonmark").render,
    "markdown-it (js-default)": MarkdownIt("js-default").render,
    "mistune (html)": mistune.html,
    "mistune (escape=True)": mistune.create_markdown(escape=True),
    "python-markdown": markdown.markdown,
}

for label, render in renderers.items():
    out = render(DOC)
    nested = "✅" if out.count("<ul>") == 2 else "❌ aplanada"
    script = "❌ pasa" if "<script>" in out else "✅ bloqueado"
    print(f"{label:<25} lista anidada: {nested:<11} <script>: {script}")

# El árbol en vez del HTML: índice y enlaces, sin tocar HTML.
tokens = MarkdownIt("commonmark").parse(DOC)
print("\níndice:")
for i, tok in enumerate(tokens):
    if tok.type == "heading_open":
        print(f"  {'  ' * (int(tok.tag[1]) - 1)}{tokens[i + 1].content}")
print("enlaces:")
for tok in tokens:
    for child in tok.children or []:
        if child.type == "link_open":
            print("  ", child.attrs["href"])
