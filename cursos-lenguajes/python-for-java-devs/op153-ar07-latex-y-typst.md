# 📐 ar07 — LaTeX y Typst

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 7 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Cuando el PDF tiene que verse bien —un certificado, un informe con tablas, un documento con fórmulas—, ReportLab (`ar04`) se queda corto y HTML con CSS no controla
la página. Los sistemas de composición tipográfica sí: **LaTeX**, el estándar académico de hace cuarenta años, y **Typst**, el que nació en 2023 con la misma idea, una
sintaxis legible y un compilador en Rust. Typst tiene además una ventaja para este curso: se instala con `pip install typst` y **compila dentro del proceso de
Python**, sin binarios aparte.

La sección compila el mismo informe con los dos y mide tiempo e instalación, pero el hallazgo importante es otro: llenar una plantilla de LaTeX con datos reales se
rompe con el primer `&` o `%` que trae un concepto de gasto. Y Typst permite no llenar plantillas con texto en absoluto: los datos entran como JSON.

---

## 🧠 2. El modelo

| | LaTeX (`pdflatex`) | Typst (`typst` de PyPI) |
|---|---|---|
| Se instala | TeX Live del sistema (aquí ~96 MB lo mínimo; completo, varios GB) | `pip install typst` (75 MB, con el compilador adentro) |
| Se llama | `subprocess`, con archivos temporales | `typst.compile()`, en el proceso |
| Datos desde Python | Texto interpolado en la plantilla, **escapando** | `sys_inputs`: el documento lee JSON |
| Caracteres especiales | `& % $ # _ { } ~ ^ \` | `# $ * _ @` y otros, si se interpola texto |
| Errores | Mensajes famosamente crípticos | Mensajes con línea y explicación |
| Ecosistema | Enorme: plantillas de revistas, paquetes para todo | Joven, creciendo rápido |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien llena plantillas (JSP, Thymeleaf, Jasper) es que el motor escapa por uno: en HTML, Thymeleaf convierte `<` en `&lt;` solo. Una plantilla de LaTeX
armada con `%` de Python o con Jinja **no escapa nada**, porque esos motores no saben que la salida es LaTeX. Es el mismo error que la inyección de SQL, con un
compilador de documentos del otro lado.

---

## 💻 3. El ejemplo que corre

`informe.typ`:

```typst
// Los datos llegan como JSON por sys.inputs: no se interpola texto, no hay nada que escapar.
#let rows = json(bytes(sys.inputs.at("rows")))
#set page(paper: "us-letter")
#set text(lang: "es")
= Relación de gastos de muestra · octubre de 2026
#table(
  columns: 3,
  [*Sede*], [*Concepto*], [*Valor*],
  ..rows.map(r => (r.sede, r.concepto, r.valor)).flatten()
)
```

`documentos.py`:

```python
"""El mismo informe con Typst (en el proceso) y con LaTeX (el binario), y el carácter que rompe la plantilla."""

import json
import os
import subprocess
import tempfile
import time

import typst

ROWS = [{"sede": "Kennedy", "concepto": "Arriendo de octubre", "valor": "4.200.000"},
        {"sede": "Engativá", "concepto": "Aseo & mantenimiento", "valor": "1.150.000"},
        {"sede": "Fontibón", "concepto": "Anticipo del 50% · cuenta #12_3", "valor": "780.000"}]

LATEX = r"""\documentclass{article}
\usepackage[T1]{fontenc}
\begin{document}
\section*{Relación de gastos de muestra · octubre de 2026}
\begin{tabular}{lll}
Sede & Concepto & Valor \\ \hline
%s
\end{tabular}
\end{document}
"""


def latex_pdf(rows, escape):
    def clean(text):
        if not escape:
            return text
        for char, repl in (("\\", r"\textbackslash{}"), ("&", r"\&"), ("%", r"\%"), ("$", r"\$"), ("#", r"\#"), ("_", r"\_"),
                           ("{", r"\{"), ("}", r"\}"), ("~", r"\textasciitilde{}"), ("^", r"\textasciicircum{}")):
            text = text.replace(char, repl)
        return text
    body = "\n".join(" & ".join(clean(r[k]) for k in ("sede", "concepto", "valor")) + r" \\" for r in rows)
    with tempfile.TemporaryDirectory() as tmp:
        with open(f"{tmp}/informe.tex", "w", encoding="utf-8") as f:
            f.write(LATEX % body)
        run = subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "informe.tex"], cwd=tmp,
                             capture_output=True, text=True)
        error = next((l for l in run.stdout.splitlines() if l.startswith("!")), None)
        return (os.path.getsize(f"{tmp}/informe.pdf") if run.returncode == 0 else None), error


start = time.perf_counter()
pdf = typst.compile("informe.typ", sys_inputs={"rows": json.dumps(ROWS)})
print(f"Typst (en el proceso)       {(time.perf_counter() - start) * 1000:6.0f} ms · {len(pdf):,} bytes")

start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=False)
print(f"LaTeX sin escapar           {(time.perf_counter() - start) * 1000:6.0f} ms · falla: {error}")
start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=True)
print(f"LaTeX escapando             {(time.perf_counter() - start) * 1000:6.0f} ms · {size:,} bytes")
```

```bash
apt-get install --no-install-recommends texlive-latex-base texlive-fonts-recommended   # 38 s en el contenedor
pip install typst
python3 documentos.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
Typst (en el proceso)           18 ms · 17,914 bytes
LaTeX sin escapar               45 ms · falla: ! Extra alignment tab has been changed to \cr.
LaTeX escapando                656 ms · 20,399 bytes
```

Typst compila el informe en **18 ms**, dentro del proceso. LaTeX, la primera vez sin escapar, **falla**: el `&` de "Aseo & mantenimiento" es el separador de columnas de
una tabla de LaTeX, y la fila quedó con una columna de más; el `%` de "50%" habría comentado el resto de la línea, y `#` y `_` también son especiales. Escapando los diez
caracteres, compila en **656 ms**, 36 veces lo de Typst, porque arranca `pdflatex`, carga sus formatos y fuentes y escribe archivos auxiliares. Typst no escapó nada:
los datos entraron como JSON y el documento los leyó como datos, no como código.

**Detalles con intención**

- **`sys_inputs`** pasa cadenas al documento, que las lee con `sys.inputs`; `json(bytes(...))` las convierte en arreglos y diccionarios de Typst. Es una consulta
  parametrizada, no una concatenación.
- **El orden de los reemplazos** en `clean` importa: la barra invertida va primero, o se escaparían las barras que agregan los demás reemplazos.
- **`-interaction=nonstopmode -halt-on-error`**: sin esas opciones, `pdflatex` se detiene a preguntar en la terminal ante un error, y el `subprocess` se queda colgado.
- **El directorio temporal**: `pdflatex` deja `.aux` y `.log` junto al `.tex`; sin un directorio propio por compilación, dos compilaciones en paralelo se pisan.

---

## ⚠️ 4. Lo que se rompe

**El dato que trae un carácter especial.** El primer concepto con `&`, `%` o `_` rompe el PDF de LaTeX, o peor: un `\input{/etc/passwd}` en los datos mete un archivo del
servidor en el PDF, y `\write18` ejecuta comandos si alguien habilitó `--shell-escape`. Se escapa siempre, o se usa un paquete que lo haga (`pylatex` escapa al construir el documento).

**El `pdflatex` que espera en silencio.** Sin `nonstopmode`, un error deja el proceso esperando una tecla. Se usa `-halt-on-error` y un `timeout=` en el
`subprocess`.

**Interpolar texto en Typst.** `sys_inputs` evita el problema; armar el `.typ` con f-strings lo trae de vuelta: `#` y `$` son especiales en Typst también.

**Las fuentes.** Un documento que usa una fuente instalada en el portátil compila distinto en el contenedor. Typst trae las suyas y acepta `font_paths=`; LaTeX
depende de los paquetes del sistema.

---

## ⚖️ 5. Cuándo NO usarlos

**Para un PDF simple de una tabla.** ReportLab (`ar04`) o HTML con WeasyPrint, sin otro lenguaje que aprender.

**Typst si el documento va a una revista que exige LaTeX.** El ecosistema de plantillas académicas sigue siendo de LaTeX.

**LaTeX para generar miles de documentos por hora.** 656 ms por documento, más los archivos temporales; Typst, en el proceso, cuesta 36 veces menos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las tres líneas, y qué carácter rompió LaTeX primero.
2. Agrega a Typst una fila con `#`, `$` y `*` en el concepto. **Criterio:** el PDF los muestra tal cual, sin escapar nada.
3. Pon un pie de página con el número de página en el `.typ`. **Criterio:** "Página 1 de 1".

**🟡 Intermedio (4–6)**

4. Arma el `.typ` con una f-string en vez de `sys_inputs` y la misma fila. **Criterio:** el error de Typst y cómo se ve.
5. Genera el informe con `pylatex` en lugar de la plantilla de texto. **Criterio:** compila con la fila especial, sin escape manual.
6. Compila cien informes con Typst y con LaTeX. **Criterio:** el tiempo total de cada uno.

**🟠 Difícil (7–9)**

7. Agrega una fórmula (`$sum_(i=1)^n v_i$` en Typst, `\sum` en LaTeX) y un gráfico en SVG. **Criterio:** los dos PDF los muestran.
8. Arma un `Dockerfile` para cada uno y compara el tamaño de las imágenes. **Criterio:** los dos tamaños.
9. Pon un `timeout=` en el `subprocess` de LaTeX y un documento que entre en un bucle (`\loop`). **Criterio:** el proceso termina con un error claro.

**🔴 Muy difícil (10)**

10. Decide cómo se generan los certificados de un sistema (miles al mes, con logo, firma y tabla). **Criterio:** una página. *Rúbrica:* (a) LaTeX, Typst, ReportLab o HTML,
    con números; (b) cómo entran los datos sin inyección; (c) fuentes y reproducibilidad en el contenedor; (d) cómo se firma después (`ar04`).

---

## 📚 7. Referencias

**Documentación oficial**

- Typst: https://typst.app/docs/
- `typst` para Python: https://github.com/messense/typst-py
- LaTeX, el proyecto: https://www.latex-project.org/help/documentation/

**Libros**

- Leslie Lamport, *LaTeX: A Document Preparation System* (2.ª ed., Addison-Wesley, 1994): el libro de quien lo creó.

**Orden de lectura sugerido:** el tutorial de Typst (una hora); después la referencia de `sys.inputs` y `json`.

---

## 🚀 8. Cierre

Typst y LaTeX componen PDF de calidad tipográfica. Typst compila en el proceso en 18 ms, con datos que entran como JSON y no necesitan escaparse; LaTeX tarda 656 ms,
arranca un binario y se rompe con el primer `&` de los datos si no se escapan diez caracteres. LaTeX gana en ecosistema; Typst, en todo lo demás que se midió aquí.

**La señal de que quedó bien:** *"Ningún dato entra a un documento como texto interpolado: en Typst por `sys_inputs`, en LaTeX escapado por una función con pruebas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-07 -m "op ar07 cerrada: Typst en el proceso, LaTeX escapado, los dos medidos"
> ```
>
> Los commits llevan su prefijo (`op ar07: …`) y los de ejercicio su número
> (`op ar07 ej07: …`).
