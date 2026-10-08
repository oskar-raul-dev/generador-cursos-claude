# 📝 tx05 — Markdown y su ecosistema

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 5 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las administradoras de Áurea escriben los procedimientos de las sedes —el cierre de caja, el protocolo de
bioseguridad, cómo se agenda una cita de control— en Markdown, porque se aprende en una tarde y se versiona en git.
La intranet los muestra como HTML. Parece resuelto: se instala un paquete de Markdown y se llama a una función.

Hay tres problemas que aparecen después. **Markdown no es uno**: hay una especificación (CommonMark) y varias
bibliotecas que la siguen en distinto grado, y el mismo archivo se ve distinto según cuál lo procese. **Markdown
deja pasar HTML**, y un procedimiento con un `<script>` copiado de algún lado se ejecuta en la intranet. Y muchas
veces no se quiere HTML sino **saber qué dice el documento**: sus títulos para un índice, sus enlaces para verificar
que no estén rotos. Para eso, el paso correcto es el árbol, no el HTML.

---

## 🧠 2. El modelo

| Biblioteca | Sigue | HTML crudo por defecto | Árbol accesible | Para qué |
|---|---|---|---|---|
| `markdown-it-py` 4.2.0 | **CommonMark**, con *presets* | Depende del *preset* | **Sí**: lista de *tokens* | El defecto: MkDocs, Jupyter y MyST lo usan |
| `mistune` 3.3.4 | CommonMark casi completo | **Pasa** con `mistune.html`; `escape=True` lo escapa | Sí: su AST como dicts | Velocidad, *plugins* simples |
| `Markdown` (python-markdown) 3.11 | **Su propia variante**, anterior a CommonMark | **Pasa** | No directamente | Extensiones históricas; MkDocs lo usó durante años |

La diferencia que más se nota con un documento real: python-markdown exige **cuatro espacios** de sangría para
anidar una lista; CommonMark acepta los dos que escribe casi todo el mundo. La lista anidada del procedimiento se
aplana en uno y no en los otros.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, `commonmark-java` o `flexmark` siguen CommonMark, y el instinto asume que "Markdown" en Python también. El
paquete que se instala con el nombre más obvio, `Markdown`, es el que **no** lo sigue. Se elige por especificación,
no por nombre.

---

## 💻 3. El ejemplo que corre

```bash
uv add markdown-it-py mistune markdown
```

`procedimiento.py`:

```python
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
```

```bash
python3 procedimiento.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
markdown-it (commonmark)  lista anidada: ✅           <script>: ❌ pasa
markdown-it (js-default)  lista anidada: ✅           <script>: ✅ bloqueado
mistune (html)            lista anidada: ✅           <script>: ❌ pasa
mistune (escape=True)     lista anidada: ✅           <script>: ✅ bloqueado
python-markdown           lista anidada: ❌ aplanada  <script>: ❌ pasa

índice:
  Cierre de caja
    Si no cuadra
enlaces:
   https://intranet.aurea.example/cartera
   planilla-de-cierre.xlsx
```

Cinco configuraciones, y tres de ellas dejan pasar el `<script>`. La que más se usa en tutoriales
—`markdown.markdown(texto)`— además aplana la lista que la administradora escribió con dos espacios. `mistune.html`, la
función que su documentación muestra primero, también deja pasar el HTML: hay que crear el *renderer* con
`escape=True`. El *preset* `js-default` de `markdown-it-py` —el que imita a `markdown-it` de JavaScript— y `mistune`
con `escape=True` hacen las dos cosas bien. Y el índice y los enlaces salen
del árbol sin generar HTML: la base de un verificador de enlaces o de un índice automático para la intranet.

**Detalles con intención**

- **Los *presets* de `markdown-it-py`**: `commonmark` es la especificación estricta, que permite HTML porque la
  especificación lo permite; `js-default` desactiva el HTML y activa tablas y tachado; `gfm-like` se acerca a GitHub.
  Se elige uno a propósito.
- **`tok.children`**: los *tokens* de bloque (párrafos, títulos) tienen hijos *inline* (texto, enlaces, énfasis). El
  título está en el *token* `inline` que sigue a `heading_open`.
- **El árbol sirve para validar**: un enlace a `planilla-de-cierre.xlsx` que no existe en el repositorio se detecta
  antes de publicar.

---

## ⚠️ 4. Lo que se rompe

**Bloquear HTML no es sanear.** Un `[enlace](javascript:alert(1))` no es HTML crudo. `markdown-it-py` valida los
esquemas de los enlaces por defecto y descarta `javascript:`; otras bibliotecas no. Si el Markdown viene de alguien en
quien no se confía, el HTML resultante pasa además por un saneador (`nh3`) con una lista de etiquetas permitidas.

**Las extensiones que atan a una biblioteca.** Los avisos de MkDocs Material (`!!! note`), las tablas de
python-markdown y la sintaxis de MyST no son CommonMark. Un documento que las usa solo se ve bien en esa biblioteca.
Se decide qué extensiones se permiten y se escribe en la guía de estilo.

**Cambiar de biblioteca con documentos viejos.** Pasar de python-markdown a `markdown-it-py` corrige las listas con
dos espacios… y rompe las que se escribieron con cuatro esperando el otro comportamiento en algún caso límite. Se
renderizan todos los documentos con las dos y se comparan antes de cambiar.

---

## ⚖️ 5. Cuándo NO usar Markdown

**Para documentos con estructura obligatoria.** Una historia clínica, una factura o un contrato tienen campos que no
pueden faltar. Markdown no valida nada: para eso, datos estructurados y una plantilla (`tx02`).

**Para documentos largos con referencias cruzadas, índices y numeración.** Markdown no tiene "ver la figura 3". Para
manuales grandes, reStructuredText con Sphinx o MyST (`tx06`).

**Cuando los autores necesitan maquetar.** Si la administradora quiere dos columnas y una imagen a la derecha, Markdown
la va a frustrar; ahí sirve un editor visual, o aceptar que el procedimiento no necesita dos columnas.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Sangra la lista anidada con cuatro espacios y vuelve a correr. **Criterio:** reportas qué cambia en cada biblioteca.
2. Agrega una tabla al documento. **Criterio:** dices qué configuraciones la muestran como tabla y cuáles como texto.
3. Agrega un enlace `javascript:` y busca en la salida de cada biblioteca. **Criterio:** cuáles lo dejan pasar.

**🟡 Intermedio (4–6)**

4. Escribe el verificador de enlaces locales: cada enlace relativo tiene que existir en el directorio. **Criterio:** la
   planilla que falta se reporta con su documento.
5. Genera el índice como HTML con anclas en los títulos (`mdit-py-plugins` tiene `anchors`). **Criterio:** cada entrada
   del índice lleva a su título.
6. Pasa la salida de `commonmark` por `nh3` con una lista corta de etiquetas. **Criterio:** el `<script>` desaparece y
   las listas quedan.

**🟠 Difícil (7–9)**

7. Escribe un *plugin* de `markdown-it-py` que convierta `[[Cartera]]` en un enlace a la página de ese nombre.
   **Criterio:** el *plugin* trabaja sobre *tokens*, no sobre el texto con expresiones regulares.
8. Renderiza veinte documentos con python-markdown y con `markdown-it-py`, y compara el HTML. **Criterio:** la lista de
   documentos que cambian y por qué.
9. Mide las tres bibliotecas con un documento de 5 000 líneas. **Criterio:** los tiempos en tu máquina, con las
   versiones.

**🔴 Muy difícil (10)**

10. Diseña la intranet de procedimientos de Áurea. **Criterio:** una página. *Rúbrica:* (a) biblioteca y *preset*, con
    su razón; (b) qué extensiones se permiten y dónde queda escrito; (c) cómo se valida un documento antes de
    publicarlo; (d) qué pasa con el HTML que alguien pegue.

---

## 📚 7. Referencias

**Documentación oficial**

- CommonMark, la especificación: https://spec.commonmark.org/
- `markdown-it-py`: https://markdown-it-py.readthedocs.io/en/latest/
- `mistune`: https://mistune.lepture.com/en/latest/
- Python-Markdown: https://python-markdown.github.io/
- `nh3`, el saneador: https://nh3.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la página de *presets* y *tokens* de `markdown-it-py`; la especificación de CommonMark
como referencia cuando dos bibliotecas no coinciden.

---

## 🚀 8. Cierre

Markdown no es uno: se elige la biblioteca por la especificación que sigue, y el *preset* por lo que deja pasar. Para
mostrar, HTML sin HTML crudo (y saneado si el autor no es de confianza); para entender el documento —índices,
enlaces, validación— el árbol de *tokens*.

**La señal de que quedó bien:** *"La administradora escribe la lista con dos espacios, como en cualquier lado, y la
intranet la muestra anidada; y el enlace roto a la planilla se detectó antes de publicar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-05 -m "op tx05 cerrada: tres Markdown, el HTML que pasa y el índice del árbol"
> ```
>
> Los commits llevan su prefijo (`op tx05: …`) y los de ejercicio su número
> (`op tx05 ej07: …`).
