# 🔤 vz02 — La gramática: Altair, plotnine, Great Tables

> Python para desarrolladores Java senior · **Carta** · Track `vz` — Visualización y gráficos ·
> sección 2 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El reporte mensual para Julián tiene un gráfico que cambia cada mes de forma: un mes quiere ver el recaudo por semana de las diez sedes
en barras; el siguiente, en líneas para ver la tendencia; el otro, un panel por sede. Con Matplotlib (`vz01`), cada cambio es reescribir
el bucle que dibuja. Con una **gramática de gráficos** es cambiar una palabra.

La gramática de gráficos —la idea de Leland Wilkinson que popularizó `ggplot2` en R— describe un gráfico como **qué columna va a qué
canal visual**: la semana al eje X, el recaudo al Y, la sede al color; y una **marca**: barras, líneas, puntos. La biblioteca hace el
resto. En Python hay dos: **Altair** (sobre Vega-Lite, que produce gráficos como especificaciones JSON) y **plotnine** (la gramática de
`ggplot2`, sobre Matplotlib). Y para la tabla del mismo reporte, **Great Tables** aplica la misma idea a las tablas: formato por columna,
título, notas.

---

## 🧠 2. El modelo

| Pieza de la gramática | En Altair 6.3 | En plotnine 0.15 |
|---|---|---|
| Datos | `alt.Chart(df)` | `ggplot(df)` |
| Marca | `.mark_bar()`, `.mark_line()` | `geom_col()`, `geom_line()` |
| Canales | `.encode(x="semana", y="recaudo", color="sede")` | `aes(x="semana", y="recaudo", color="sede")` |
| Facetas | `.facet("sede")` | `facet_wrap("sede")` |
| Resultado | Una especificación JSON de Vega-Lite | Una figura de Matplotlib |
| Exportar a PNG | `vl-convert-python` | `.save()` de Matplotlib |

| Biblioteca | Versión | Para qué |
|---|---|---|
| Altair | 6.3.0 | Gráficos declarativos; HTML interactivo o imagen |
| plotnine | 0.15.8 | `ggplot2` en Python; para quien viene de R |
| Great Tables | 1.0.0 | Tablas para publicar, con formato |
| seaborn | 0.13.2 💤 | Gráficos estadísticos sobre Matplotlib; sin versiones desde enero de 2024 |

### Tu instinto de Java dice… y esta vez se equivoca

En Java no hay una gramática de gráficos de uso común: se configura un objeto de gráfico propiedad por propiedad. El instinto lleva esa forma a
Python y escribe Matplotlib para todo. Para un gráfico que cambia según lo que se quiere ver, la gramática no es azúcar sintáctico: es otra forma
de pensar el gráfico, en la que cambiar de barras a líneas no toca la lógica.

---

## 💻 3. El ejemplo que corre

```bash
uv add altair vl-convert-python plotnine great-tables pandas
```

`gramatica.py`:

```python
"""El mismo recaudo en la gramática: Altair (una palabra cambia la marca), plotnine, y la tabla con Great Tables."""

import json
import random
import re

import altair as alt
import pandas as pd
from great_tables import GT
from plotnine import aes, geom_col, ggplot, labs

random.seed(9)
SEDES = ["Centro", "Chapinero", "Suba", "Kennedy"]
df = pd.DataFrame([{"semana": w, "sede": s, "recaudo": random.randint(20, 60) * 1_000_000}
                   for w in range(1, 5) for s in SEDES])

base = alt.Chart(df).encode(x="semana:O", y=alt.Y("recaudo:Q", title="Recaudo (pesos)"), color="sede:N")
bars, lines = base.mark_bar(), base.mark_line(point=True)
panels = base.mark_bar().facet("sede:N", columns=2)
for name, chart in [("barras", bars), ("lineas", lines), ("paneles", panels)]:
    chart.save(f"recaudo-{name}.png")
spec_bars, spec_lines = bars.to_dict(), lines.to_dict()
changed = [k for k in spec_bars if spec_bars[k] != spec_lines.get(k)]
print("Altair: lo que cambia entre barras y líneas en la especificación:", changed, "→",
      spec_bars["mark"], "/", spec_lines["mark"])
print("Altair: tamaño de la especificación:", len(json.dumps(spec_bars)), "bytes")

(ggplot(df, aes(x="semana", y="recaudo", fill="sede")) + geom_col(position="dodge")
 + labs(title="Recaudo semanal por sede")).save("recaudo-plotnine.png", width=8, height=3, dpi=100, verbose=False)
print("plotnine: recaudo-plotnine.png")

table = (df.pivot_table(index="sede", columns="semana", values="recaudo", aggfunc="sum").reset_index())
table.columns = ["sede"] + [f"sem {c}" for c in table.columns[1:]]
html = (GT(table, rowname_col="sede").tab_header(title="Recaudo de septiembre de 2026")
        .fmt_currency(columns=[c for c in table.columns if c != "sede"], currency="COP", decimals=0, locale="es")
        .tab_source_note("Fuente: cierre nocturno.").as_raw_html())
print("Great Tables: HTML de", len(html), "bytes; primera cifra:", re.search(r"\$\s?[\d.]+", html).group())

big = pd.DataFrame({"x": range(6_000), "y": range(6_000)})
try:
    alt.Chart(big).mark_point().encode(x="x", y="y").to_dict()
except Exception as e:
    print(f"Altair con 6 000 filas: {type(e).__name__}: {str(e).splitlines()[0][:80]}")
```

```bash
python3 gramatica.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Altair: lo que cambia entre barras y líneas en la especificación: ['mark'] → {'type': 'bar'} / {'type': 'line', 'point': True}
Altair: tamaño de la especificación: 1335 bytes
plotnine: recaudo-plotnine.png
Great Tables: HTML de 11010 bytes; primera cifra: $49.000.000
Altair con 6 000 filas: MaxRowsError: The number of rows in your dataset (6000) is greater than the maximum allowed (5
```

Entre el gráfico de barras y el de líneas, la especificación de Altair difiere en **una sola clave**, `mark`; los datos, los canales y los títulos son
los mismos. El gráfico entero, con sus dieciséis filas de datos adentro, pesa 1,3 KB de JSON. Great Tables formateó el primer monto como
`$49.000.000`, con el punto de miles de Colombia, sin tocar el dato. Y la última línea es la trampa de la sección: con 6 000 filas, Altair se niega
antes de dibujar nada.

**Detalles con intención**

- **`"semana:O"`, `"recaudo:Q"`, `"sede:N"`**: el sufijo dice el tipo de dato —ordinal, cuantitativo, nominal— y decide la escala, el eje y los
  colores. Es la parte de la gramática que más se olvida y que más cambia el gráfico.
- **La especificación de Altair es JSON**: el gráfico es un dato que se puede guardar, comparar y versionar. La comparación de arriba muestra que
  barras y líneas difieren solo en `mark`.
- **`vl-convert-python`** convierte la especificación a PNG o SVG sin navegador. Sin él, `chart.save("x.png")` falla.
- **`fmt_currency(..., locale="es")`** de Great Tables formatea los pesos como se leen en Colombia, sin tocar los datos.

---

## ⚠️ 4. Lo que se rompe

**El límite de 5 000 filas de Altair.** Altair incrusta los datos en la especificación JSON; para que un cuaderno no se congele, se niega a pasar de
5 000 filas por defecto. En un proceso con datos reales, el gráfico falla una noche cualquiera, cuando el mes trae más filas. Se agrega en pandas
antes de graficar (es lo correcto casi siempre), o se activa el transformador `vegafusion`, que calcula del lado de Python.

**Los tipos de dato mal declarados.** La semana como cuantitativa (`semana:Q`) dibuja un eje continuo con semana 2,5; como ordinal, cuatro
categorías. Un franquiciado no debería ver una semana 2,5.

**seaborn en un proyecto nuevo.** Lleva desde enero de 2024 sin versiones (💤). Funciona, y para lo que hace hay alternativas activas en la
gramática.

---

## ⚖️ 5. Cuándo NO usarlo

**Para una imagen con forma fija y detalles finos.** Un gráfico con anotaciones a mano, el logo en una esquina y una línea de meta: Matplotlib (`vz01`)
da el control que la gramática no da.

**Altair con muchos datos sin agregar.** Por el límite y porque la especificación pesa lo que pesan los datos.

**plotnine si nadie en el equipo viene de R.** Su ventaja es la familiaridad con `ggplot2`; para un equipo sin R, Altair es igual de declarativo y más
usado en Python.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo y abre las tres imágenes de Altair. **Criterio:** describes qué cambió en el código entre cada una.
2. Cambia `semana:O` por `semana:Q`. **Criterio:** qué pasa con el eje.
3. Agrega a Great Tables una fila de totales (`grand_summary_rows`). **Criterio:** los totales salen en pesos.

**🟡 Intermedio (4–6)**

4. Agrega una línea horizontal de meta (una capa con `mark_rule`). **Criterio:** la meta se ve en las tres versiones.
5. Agrega el mes a los datos y haz el gráfico con 12 meses × 10 sedes × 4 semanas sin superar el límite. **Criterio:** agregas antes de graficar.
6. Haz la misma tabla de Great Tables en el PDF del reporte (`ui08`). **Criterio:** se ve igual en el PDF.

**🟠 Difícil (7–9)**

7. Activa `alt.data_transformers.enable("vegafusion")` y grafica las 6 000 filas. **Criterio:** funciona, y cuánto pesa la especificación con y sin
   VegaFusion.
8. Guarda las especificaciones JSON del mes en el repositorio y escribe una prueba que detecte un cambio de gráfico. **Criterio:** cambiar el color
   hace fallar la prueba.
9. Haz el mismo gráfico en Matplotlib puro (`vz01`) y compara las líneas de código para cambiar de barras a líneas. **Criterio:** las dos cuentas.

**🔴 Muy difícil (10)**

10. Diseña los gráficos del reporte mensual de Áurea. **Criterio:** una página. *Rúbrica:* (a) qué gráfico va con la gramática y cuál con Matplotlib;
    (b) dónde se agregan los datos antes de graficar; (c) cómo se exportan sin navegador; (d) cómo se prueba que un gráfico no cambió sin querer.

---

## 📚 7. Referencias

**Documentación oficial**

- Altair: https://altair-viz.github.io/
- plotnine: https://plotnine.org/
- Great Tables: https://posit-dev.github.io/great-tables/

**Lectura**

- Hadley Wickham, *A Layered Grammar of Graphics* (2010), el artículo que convirtió la idea de Wilkinson en `ggplot2`:
  https://vita.had.co.nz/papers/layered-grammar.html

**Orden de lectura sugerido:** el artículo de Wickham (la idea en veinte páginas); después la guía de codificación de Altair.

---

## 🚀 8. Cierre

La gramática de gráficos describe qué columna va a qué canal y deja que la biblioteca dibuje: cambiar de barras a líneas es una palabra. Altair produce
especificaciones JSON que se versionan y se exportan sin navegador; plotnine trae `ggplot2`; Great Tables hace lo mismo con las tablas. Los datos se
agregan antes de graficar, que además esquiva el límite de Altair.

**La señal de que quedó bien:** *"Julián pidió ver el recaudo en líneas en vez de barras, y el cambio fue una palabra y un commit."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-vz-fase-02 -m "op vz02 cerrada: la gramática de gráficos, Altair, plotnine y Great Tables"
> ```
>
> Los commits llevan su prefijo (`op vz02: …`) y los de ejercicio su número
> (`op vz02 ej07: …`).
