# 📽️ ui07 — Presentaciones programáticas

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 7 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El primer lunes de cada mes, Julián y Marcela se reúnen con Patricia a revisar la red: una diapositiva por sede con lo
facturado, el recaudo y la mora, y una de resumen. Patricia arma la presentación a mano: copia números del Excel, pega
gráficos, ajusta colores. Le toma una mañana, y cada mes hay un número mal copiado que alguien encuentra en la reunión.

La presentación es un entregable más, y se puede generar como se generan los reportes. Hay dos familias de herramientas,
y la elección depende de una pregunta que no es técnica: **¿la presentación la va a seguir editando una persona en
PowerPoint, o se mira y ya?** Si Patricia o Marcela van a retocarla —cambiar un color, agregar una nota—, el entregable es
un `.pptx`. Si no, una presentación HTML generada desde Markdown pesa menos, se versiona mejor y se abre en cualquier
navegador.

---

## 🧠 2. El modelo

| Herramienta | Qué produce | Editable después por una persona | Para qué |
|---|---|---|---|
| `python-pptx` 1.0.2 💤 | `.pptx` nativo | **Sí**, en PowerPoint o Keynote | El comité mensual que Marcela retoca |
| Quarto (binario, no es un paquete de Python) | reveal.js (HTML), `.pptx`, PDF desde Markdown con código | Poco | Presentaciones con código y gráficos que se ejecutan al construir |
| Marp (binario de Node) | HTML, PDF, `.pptx` (como imágenes) desde Markdown | No | Presentaciones simples escritas en Markdown |
| `manim` | Video | No | Animaciones explicativas (`ed`) |

`python-pptx` lleva desde agosto de 2024 sin versiones nuevas (💤). Es el único camino maduro en Python para escribir
`.pptx` editables, el formato no cambia rápido y la biblioteca sigue funcionando; es una dependencia que se fija y se
vigila, no una que se evita.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, Apache POI escribe `.pptx` (XSLF) y este perfil quizás lo usó para Excel y sufrió su API. El instinto espera lo
mismo de `python-pptx`. La API es más corta, y la idea que cambia todo es otra: **no se diseña la diapositiva en código**,
se parte de una plantilla `.pptx` que diseñó una persona —Marcela, con los colores de la marca— y el código solo llena
los marcadores.

---

## 💻 3. El ejemplo que corre

```bash
uv add python-pptx
```

`comite.py`:

```python
"""La presentación del comité mensual: una diapositiva por sede, con tabla y gráfico nativos."""

from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.util import Inches, Pt

SEDES = {"Centro": (187_450_000, 162_300_000, 3_100_000),
         "Suba": (142_900_000, 118_600_000, 9_800_000),
         "Kennedy": (98_300_000, 91_200_000, 1_200_000)}


def pesos(v: int) -> str:
    return "$" + f"{v:,}".replace(",", ".")


deck = Presentation()                          # en la casa: Presentation("plantilla-aurea.pptx")
title_only = deck.slide_layouts[5]

summary = deck.slides.add_slide(deck.slide_layouts[0])
summary.shapes.title.text = "Comité mensual · septiembre de 2026"
summary.placeholders[1].text = "Red Áurea: facturado, recaudo y mora por sede"

for sede, (billed, collected, overdue) in SEDES.items():
    slide = deck.slides.add_slide(title_only)
    slide.shapes.title.text = f"Sede {sede}"
    rows = [("Facturado", pesos(billed)), ("Recaudado", pesos(collected)),
            ("Recaudo", f"{collected / billed:.1%}".replace(".", ",")), ("Mora > 90 días", pesos(overdue))]
    table = slide.shapes.add_table(len(rows), 2, Inches(0.5), Inches(1.6), Inches(4.5), Inches(2)).table
    for i, (label, value) in enumerate(rows):
        table.cell(i, 0).text, table.cell(i, 1).text = label, value
        table.cell(i, 1).text_frame.paragraphs[0].runs[0].font.size = Pt(16)

    chart_data = CategoryChartData()
    chart_data.categories = ["Facturado", "Recaudado"]
    chart_data.add_series("Pesos", (billed, collected))
    slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, Inches(5.3), Inches(1.6),
                           Inches(4.2), Inches(3.5), chart_data)

deck.save("comite-2026-09.pptx")

# Verificación: abrir el archivo y leer lo que quedó, como lo leería PowerPoint.
for n, slide in enumerate(Presentation("comite-2026-09.pptx").slides, 1):
    kinds = sorted(s.shape_type.name for s in slide.shapes if not s.is_placeholder)
    print(n, slide.shapes.title.text, kinds)
```

```bash
python3 comite.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
1 Comité mensual · septiembre de 2026 []
2 Sede Centro ['CHART', 'TABLE']
3 Sede Suba ['CHART', 'TABLE']
4 Sede Kennedy ['CHART', 'TABLE']
```

Cuatro diapositivas, y en cada sede una tabla y un gráfico **nativos**: el gráfico es un gráfico de PowerPoint con sus
datos adentro, no una imagen. Marcela puede cambiarle el color de la barra —lo va a hacer— y Patricia puede abrir "Editar
datos" y ver los números. Ningún número se copió a mano.

**Detalles con intención**

- **`Presentation("plantilla-aurea.pptx")`** es la forma de la casa: el diseño (fuentes, colores, logo, disposiciones) lo
  hace una persona en PowerPoint, y el código elige `slide_layouts[i]` y llena. Cambiar el diseño no toca el código.
- **`slide_layouts[5]`** es "solo título" en la plantilla por defecto; en una plantilla propia, los índices son otros. Se
  buscan por nombre (`layout.name`) en vez de por número.
- **La verificación reabre el archivo**: es la prueba barata de que el `.pptx` es válido para la biblioteca. La prueba cara
  —que PowerPoint lo abre sin pedir "reparar"— se hace a mano una vez por cambio de plantilla.

---

## ⚠️ 4. Lo que se rompe

**El texto que no cabe.** `python-pptx` no mide texto: un nombre de sede largo o una cifra de doce dígitos se sale del
cuadro, y PowerPoint no lo achica hasta que alguien edita la caja. Se prueba con los datos más largos, o se activa el
ajuste automático en la plantilla.

**Gráficos como imágenes de matplotlib.** Es lo primero que se hace y funciona, pero una imagen no se puede editar: el
día que Marcela pide otro color, hay que regenerar. Los gráficos nativos de `python-pptx` cubren barras, líneas, tortas y
dispersión; para lo demás, imagen.

**Marp a `.pptx`.** Marp exporta a `.pptx` con cada diapositiva como **una imagen**. Se ve igual y no se puede editar nada.
Si el entregable es "un PowerPoint que Marcela retoca", Marp no lo es.

**La presentación generada que alguien edita a mano y se regenera el mes siguiente.** Los retoques de Marcela se pierden.
O los retoques pasan a la plantilla, o se acuerda que lo generado no se edita.

---

## ⚖️ 5. Cuándo NO usarlo

**Si nadie va a editarla.** Para una presentación que se proyecta y se archiva, Quarto o Marp desde Markdown pesan menos,
se revisan en un *pull request* y no dependen de PowerPoint.

**Si los números cambian en vivo.** Una presentación es una foto. Si en la reunión van a preguntar "¿y si filtramos por
plan?", la respuesta es el tablero (`ui03`, `ui04`), no la diapositiva.

**Para una sola presentación.** Generar se paga cuando se repite: el comité de cada mes, la liquidación de cada trimestre.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Abre `comite-2026-09.pptx` en PowerPoint, Keynote o LibreOffice. **Criterio:** describes si el gráfico es editable y
   qué ves al "editar datos".
2. Agrega la sede Zipaquirá con datos de prueba. **Criterio:** aparece una diapositiva más sin tocar el bucle.
3. Lista los nombres de los *layouts* de la plantilla por defecto. **Criterio:** reemplazas `slide_layouts[5]` por una
   búsqueda por nombre.

**🟡 Intermedio (4–6)**

4. Crea una plantilla `.pptx` con un color y un logo, y genera con ella. **Criterio:** el código no tiene ningún color.
5. Agrega una diapositiva de resumen con una tabla de todas las sedes y la mora resaltada en rojo cuando pasa de
   $4.000.000. **Criterio:** el formato lo pone el código, no una persona.
6. Escribe la misma presentación en Markdown para Quarto (reveal.js). **Criterio:** se construye con `quarto render` y se
   abre en el navegador.

**🟠 Difícil (7–9)**

7. Escribe una prueba que detecte texto que no cabe: estima el ancho con la fuente y el tamaño. **Criterio:** la prueba
   falla con un nombre de sede de 40 caracteres.
8. Genera la presentación con datos de una base SQLite y prográmala para el primer lunes del mes (`wf`). **Criterio:** llega
   por correo el día correcto.
9. Exporta la misma presentación con Marp a `.pptx` y compárala con la de `python-pptx`. **Criterio:** describes qué se
   puede editar en cada una.

**🔴 Muy difícil (10)**

10. Decide cómo se produce la presentación del comité de Áurea. **Criterio:** una página. *Rúbrica:* (a) quién la edita
    después y qué; (b) herramienta, con su razón; (c) dónde vive el diseño y quién lo cambia; (d) qué pasa con
    `python-pptx` si sigue sin versiones nuevas dos años más.

---

## 📚 7. Referencias

**Documentación oficial**

- `python-pptx`: https://python-pptx.readthedocs.io/en/latest/
- `python-pptx`, gráficos: https://python-pptx.readthedocs.io/en/latest/user/charts.html
- Quarto, presentaciones reveal.js: https://quarto.org/docs/presentations/revealjs/
- Marp: https://marp.app/

**Orden de lectura sugerido:** la página de gráficos de `python-pptx`; después la de presentaciones de Quarto, para tener
la alternativa clara.

---

## 🚀 8. Cierre

Una presentación que se repite se genera. Si alguien la va a retocar, el entregable es un `.pptx` con gráficos nativos que
parte de una plantilla diseñada por una persona; si se mira y ya, HTML desde Markdown. `python-pptx` está sin versiones
nuevas y sigue siendo la herramienta: se fija y se vigila.

**La señal de que quedó bien:** *"El comité de octubre empezó sin que nadie encontrara un número mal copiado, y Marcela
solo cambió el color de una barra."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-07 -m "op ui07 cerrada: el comité mensual generado, con gráficos nativos"
> ```
>
> Los commits llevan su prefijo (`op ui07: …`) y los de ejercicio su número
> (`op ui07 ej07: …`).
