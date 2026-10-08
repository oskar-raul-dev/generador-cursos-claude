# 📊 ar05 — Office: Word, Excel y PowerPoint

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 5 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las personas que no son ingenieras trabajan en Excel, Word y PowerPoint, y la mitad de los encargos de automatización terminan en uno de esos archivos: el reporte
mensual en Excel, la carta con los datos de cada sede en Word, la presentación del comité con su gráfico. Los formatos de Office son *zips* con XML adentro (Office
Open XML), y Python tiene una biblioteca para cada uno: **openpyxl** y **XlsxWriter** para Excel, **python-docx** para Word y **python-pptx** para PowerPoint.

Ninguna de ellas **es** Office: escriben y leen el XML, pero no calculan fórmulas, no reacomodan texto ni dibujan nada. Esta sección mide las dos de Excel con
100.000 filas y muestra las dos trampas que más tiempo cuestan: la fórmula que nadie calculó y el marcador de plantilla partido en pedazos.

---

## 🧠 2. El modelo

| Biblioteca | Lee | Escribe | Lo que la distingue | El equivalente en Java |
|---|---|---|---|---|
| **openpyxl** | Sí | Sí | Modificar archivos existentes | Apache POI (XSSF) |
| **XlsxWriter** | **No** | Sí | Más rápida; memoria constante; gráficos y formatos completos | POI SXSSF |
| **python-docx** | Sí | Sí | Párrafos, *runs*, tablas, estilos | POI XWPF, docx4j |
| **python-pptx** | Sí | Sí | Diapositivas, formas, **gráficos nativos** editables | POI XSLF |

### Esto sí funciona igual

Es Apache POI: el mismo modelo de libro, hoja y celda; de párrafo y *run*. Las trampas también son las mismas: POI tampoco calcula fórmulas al escribir sin
`FormulaEvaluator`, y los *runs* de Word parten el texto igual en Java que en Python.

---

## 💻 3. El ejemplo que corre

`office.py`:

```python
"""Office desde Python: Excel con dos bibliotecas, la fórmula que nadie calculó, Word con plantilla y una diapositiva."""

import os
import time
import tracemalloc

import openpyxl
import xlsxwriter
from docx import Document
from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.util import Inches

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo"]
N = 100_000


def measure(fn):
    start = time.perf_counter(); fn(); elapsed = time.perf_counter() - start
    tracemalloc.start(); fn(); peak = tracemalloc.get_traced_memory()[1]; tracemalloc.stop()   # aparte: tracemalloc frena
    return f"{elapsed:5.2f} s · memoria máx. {peak / 2**20:5.0f} MB"


# 1) 100.000 filas con openpyxl y con XlsxWriter (modo de memoria constante)
def with_openpyxl():
    wb = openpyxl.Workbook(); ws = wb.active
    ws.append(["fila", "sede", "valor"])
    for i in range(N):
        ws.append([i, BRANCHES[i % 8], i * 1.5])
    ws.append(["", "total", f"=SUM(C2:C{N + 1})"])
    wb.save("openpyxl.xlsx")


def with_xlsxwriter():
    wb = xlsxwriter.Workbook("xlsxwriter.xlsx", {"constant_memory": True}); ws = wb.add_worksheet()
    ws.write_row(0, 0, ["fila", "sede", "valor"])
    for i in range(N):
        ws.write_row(i + 1, 0, [i, BRANCHES[i % 8], i * 1.5])
    ws.write_row(N + 1, 1, ["total", f"=SUM(C2:C{N + 1})"])
    wb.close()


print(f"openpyxl   {measure(with_openpyxl)} · {os.path.getsize('openpyxl.xlsx') / 2**20:.1f} MB")
print(f"XlsxWriter {measure(with_xlsxwriter)} · {os.path.getsize('xlsxwriter.xlsx') / 2**20:.1f} MB")

# 2) La fórmula: openpyxl no calcula
total = openpyxl.load_workbook("openpyxl.xlsx").active.cell(N + 2, 3).value
cached = openpyxl.load_workbook("openpyxl.xlsx", data_only=True).active.cell(N + 2, 3).value
print(f"la celda del total: {total!r} · con data_only=True: {cached!r}")

# 3) Word: una plantilla con el marcador partido en dos "runs" por un cambio de formato
template = Document()
paragraph = template.add_paragraph("Informe de la sede ")
paragraph.add_run("{{se")
paragraph.add_run("de}}").bold = True                     # alguien puso en negrita la mitad del marcador
template.save("plantilla.docx")
doc = Document("plantilla.docx")
for p in doc.paragraphs:
    for run in p.runs:
        run.text = run.text.replace("{{sede}}", "Kennedy")
print(f"reemplazo run por run: {doc.paragraphs[0].text!r} · runs: {[r.text for r in doc.paragraphs[0].runs]}")

# 4) PowerPoint: una diapositiva con un gráfico nativo (editable en PowerPoint)
deck = Presentation()
slide = deck.slides.add_slide(deck.slide_layouts[5])
slide.shapes.title.text = "Filas por sede (muestra)"
data = CategoryChartData(); data.categories = BRANCHES; data.add_series("filas", [N // 8] * 8)
slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, Inches(0.5), Inches(1.5), Inches(9), Inches(5), data)
deck.save("muestra.pptx")
print(f"muestra.pptx {os.path.getsize('muestra.pptx') / 1024:.0f} KB con un gráfico nativo")
for f in ("openpyxl.xlsx", "xlsxwriter.xlsx", "plantilla.docx", "muestra.pptx"):
    os.remove(f)
```

```bash
pip install openpyxl XlsxWriter python-docx python-pptx
python3 office.py
```

Salida (Python 3.14.7, 05/10/2026) (los segundos son de la máquina que corre):

```text
openpyxl    1.50 s · memoria máx.   102 MB · 1.7 MB
XlsxWriter  1.02 s · memoria máx.     1 MB · 1.7 MB
la celda del total: '=SUM(C2:C100001)' · con data_only=True: None
reemplazo run por run: 'Informe de la sede {{sede}}' · runs: ['Informe de la sede ', '{{se', 'de}}']
muestra.pptx 34 KB con un gráfico nativo
```

Con 100.000 filas, XlsxWriter en modo `constant_memory` tarda un tercio menos y usa **1 MB** de memoria contra **102** de openpyxl, que guarda todo el libro antes
de escribirlo. El archivo es el mismo. La fórmula del total se lee como texto, `'=SUM(C2:C100001)'`; con `data_only=True` la respuesta es **`None`**, porque el valor
calculado solo existe si Excel abrió y guardó el archivo. Y el marcador `{{sede}}` no se reemplazó: está partido en dos *runs* (`{{se` y `de}}`) porque media palabra
está en negrita, y ningún *run* contiene el marcador completo.

**Detalles con intención**

- **`constant_memory`** escribe cada fila al disco en cuanto se pasa a la siguiente: no se puede volver atrás a una fila ya escrita. Es el precio de 1 MB.
- **`data_only=True`** lee el valor en caché que guardó la última aplicación que calculó. Un archivo generado por Python no tiene caché; uno abierto y guardado en Excel,
  sí.
- **Los *runs*** son tramos de texto con el mismo formato. Una plantilla editada a mano suele partir los marcadores sin que se vea: un corrector ortográfico, un cambio
  de fuente o un "deshacer" bastan.
- **`add_chart`** crea un gráfico nativo de PowerPoint, con sus datos en una hoja incrustada: quien recibe la presentación lo edita como cualquier gráfico.

---

## ⚠️ 4. Lo que se rompe

**El total que sale vacío.** Un sistema que lee con `data_only=True` un Excel generado por otro sistema recibe `None` en cada fórmula. Se calcula en Python y se
escribe el valor, o se recalcula con LibreOffice sin interfaz (`soffice --headless --convert-to xlsx`).

**El marcador partido.** El reemplazo por *run* falla en silencio. Se reemplaza a nivel de párrafo (uniendo los *runs*, perdiendo formato dentro del marcador), o se
usa una biblioteca de plantillas como `docxtpl`, que usa Jinja sobre el XML y repara los marcadores.

**openpyxl con archivos grandes.** 102 MB para 100.000 filas de tres columnas; un reporte de un millón de filas y veinte columnas no cabe. XlsxWriter para escribir,
`read_only=True` de openpyxl para leer.

**Fechas como números.** Excel guarda fechas como días desde 1900 con formato; una celda sin formato muestra 46300 en vez de la fecha.

---

## ⚖️ 5. Cuándo NO usarlas

**Para entregar datos a otro sistema.** CSV o Parquet. Excel es para personas.

**Para documentos de diseño cuidado.** python-docx no maneja bien encabezados complejos ni secciones; una plantilla con `docxtpl` o un PDF desde HTML (`ar04`) se
mantienen mejor.

**Si el archivo tiene macros.** openpyxl las descarta al guardar salvo `keep_vba=True`, y ninguna biblioteca las ejecuta.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cinco líneas, y por qué el total es `None`.
2. Escribe el total calculado en Python en vez de la fórmula. **Criterio:** `data_only=True` lo lee.
3. Reemplaza el marcador a nivel de párrafo. **Criterio:** el texto dice "Kennedy", y qué formato se perdió.

**🟡 Intermedio (4–6)**

4. Lee el archivo de 100.000 filas con `read_only=True`. **Criterio:** el tiempo y la memoria contra el modo normal.
5. Haz la plantilla de Word con `docxtpl`. **Criterio:** el marcador partido se reemplaza.
6. Agrega a la hoja de XlsxWriter formato de moneda, una fila fija de encabezado y un filtro automático. **Criterio:** se ven al abrir en Excel o LibreOffice.

**🟠 Difícil (7–9)**

7. Recalcula el libro con LibreOffice sin interfaz y vuelve a leer con `data_only=True`. **Criterio:** el total aparece.
8. Genera la presentación mensual con un gráfico por sede desde un CSV. **Criterio:** una diapositiva por sede, con su gráfico editable.
9. Mide openpyxl y XlsxWriter con un millón de filas. **Criterio:** cuál termina y con cuánta memoria.

**🔴 Muy difícil (10)**

10. Diseña el reporte mensual en Excel de un área no técnica. **Criterio:** una página. *Rúbrica:* (a) la biblioteca y por qué, con números; (b) qué va como fórmula y
    qué como valor; (c) cómo se prueba que el archivo abre bien; (d) qué pasa el mes que crece diez veces.

---

## 📚 7. Referencias

**Documentación oficial**

- openpyxl: https://openpyxl.readthedocs.io/en/stable/
- XlsxWriter, el modo de memoria constante: https://xlsxwriter.readthedocs.io/working_with_memory.html
- python-docx: https://python-docx.readthedocs.io/en/latest/
- python-pptx: https://python-pptx.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la página de memoria de XlsxWriter; después la explicación de *runs* en la documentación de python-docx.

---

## 🚀 8. Cierre

openpyxl, XlsxWriter, python-docx y python-pptx escriben el XML de Office, no son Office: no calculan fórmulas y no ven los marcadores partidos. XlsxWriter escribe
100.000 filas con 1 MB de memoria contra 102 de openpyxl; para leer, openpyxl. Las dos trampas se resuelven igual: saber qué hace el archivo por dentro.

**La señal de que quedó bien:** *"El reporte llega con los totales como valores, las plantillas de Word se llenan con `docxtpl`, y nadie lee `None` donde había una
fórmula."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-05 -m "op ar05 cerrada: Excel medido, la fórmula sin calcular y el marcador partido"
> ```
>
> Los commits llevan su prefijo (`op ar05: …`) y los de ejercicio su número
> (`op ar05 ej07: …`).
