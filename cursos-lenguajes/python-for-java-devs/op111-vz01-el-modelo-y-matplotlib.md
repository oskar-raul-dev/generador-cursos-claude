# 📊 vz01 — El modelo y Matplotlib

> Python para desarrolladores Java senior · **Carta** · Track `vz` — Visualización y gráficos ·
> sección 1 de 4
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El cierre nocturno de Áurea produce, además de los números, una imagen por sede: el recaudo diario del mes, para el reporte que
reciben los franquiciados (`ui08`). Diez imágenes cada noche, generadas por un proceso que nadie mira, en un servidor sin pantalla.
Este track trata exactamente eso: **la imagen como entregable de un sistema**, producida por código y sin un diseñador. Explorar datos
con gráficos es otro oficio, que vive en el track de datos; aquí el gráfico sale solo, todas las noches, y tiene que salir bien.

Hay dos maneras de pedirle a una biblioteca un gráfico, y la elección decide todo lo demás. La **imperativa** —Matplotlib— dice qué
dibujar, paso a paso: un eje, una línea, una etiqueta. La **declarativa**, la gramática de gráficos (`vz02`), dice qué significa cada
columna de los datos y deja que la biblioteca dibuje. Matplotlib es el sustrato de casi todo el ecosistema, y tiene una trampa que
aparece justamente en un proceso nocturno: **sus dos API**, una de las cuales guarda estado global.

---

## 🧠 2. El modelo

| | Imperativo (Matplotlib) | Gramática (Altair, plotnine; `vz02`) |
|---|---|---|
| Se describe | Qué dibujar | Qué significa cada columna |
| Control | Total, píxel a píxel | El que permite la gramática |
| Cambiar de barras a líneas | Reescribir | Cambiar una palabra |
| Para qué | Imágenes con forma fija, ajustes finos, el sustrato de otras | Gráficos estadísticos que cambian según los datos |

**Las dos API de Matplotlib 3.11:**

| | `pyplot` (`plt.plot`, `plt.figure`) | Orientada a objetos (`Figure`, `ax.plot`) |
|---|---|---|
| Estado | **Global**: una figura "actual" que `pyplot` recuerda | Ninguno: cada figura es un objeto |
| Liberar memoria | Hay que cerrar cada figura (`plt.close`) | Se libera cuando el objeto deja de usarse |
| Hilos | No es segura | Una figura por hilo funciona |
| Para qué | Notebooks, exploración | **Procesos, servidores, todo lo que corre solo** |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, un gráfico es un objeto (JFreeChart, XChart) y el instinto espera lo mismo. Los tutoriales de Python enseñan `plt.plot(...)`, que
parece una función pura y no lo es: agrega la línea a la figura "actual" que `pyplot` guarda en un registro global, y esa figura vive hasta que
alguien la cierra. En un notebook no importa; en un proceso que genera diez imágenes cada noche durante meses, sí.

---

## 💻 3. El ejemplo que corre

```bash
uv add matplotlib
```

`recaudo.py`:

```python
"""Diez imágenes de recaudo con pyplot (estado global) y con Figure (sin estado): memoria y figuras vivas."""

import random
import tracemalloc
import warnings

import matplotlib

matplotlib.use("Agg")                                     # sin pantalla: el servidor no tiene una
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.figure import Figure  # noqa: E402
from matplotlib.ticker import FuncFormatter  # noqa: E402

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
pesos = FuncFormatter(lambda v, _: "$" + f"{v / 1e6:.0f}" + " M")


def data(sede: str) -> list[int]:
    random.seed(sede)
    return [random.randint(2_000_000, 9_000_000) for _ in range(30)]


def with_pyplot(sede: str, path: str):
    plt.figure(figsize=(8, 3))
    plt.bar(range(1, 31), data(sede), color="#2E6F9E")
    plt.title(f"Recaudo diario de {sede}, septiembre de 2026")
    plt.gca().yaxis.set_major_formatter(pesos)
    plt.savefig(path, dpi=100)                            # y nadie llama a plt.close()


def with_figure(sede: str, path: str):
    fig = Figure(figsize=(8, 3))
    ax = fig.subplots()
    ax.bar(range(1, 31), data(sede), color="#2E6F9E")
    ax.set_title(f"Recaudo diario de {sede}, septiembre de 2026")
    ax.yaxis.set_major_formatter(pesos)
    fig.savefig(path, dpi=100)


for label, draw in [("pyplot sin cerrar", with_pyplot), ("Figure", with_figure)]:
    tracemalloc.start()
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        for night in range(3):                            # tres noches del proceso
            for sede in SEDES:
                draw(sede, f"recaudo-{sede}.png")
    current, _ = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    print(f"{label:<18} figuras vivas en pyplot: {len(plt.get_fignums()):>2} · memoria retenida: {current / 1e6:5.1f} MB ·"
          f" avisos: {len(caught)}")
    if caught:
        print("  ", str(caught[0].message)[:100], "…")
    plt.close("all")
```

```bash
python3 recaudo.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
pyplot sin cerrar  figuras vivas en pyplot: 30 · memoria retenida:  27.9 MB · avisos: 1
   More than 20 figures have been opened. Figures created through the pyplot interface (`matplotlib.pyp …
Figure             figuras vivas en pyplot:  0 · memoria retenida:   9.1 MB · avisos: 0
```

Tres noches de diez imágenes. Con `pyplot` sin cerrar, las treinta figuras siguen vivas en el registro global y retienen 27,9 MB; con `Figure`, no
queda ninguna. Los 9,1 MB del segundo caso no son una fuga: son los cachés que Matplotlib carga una vez (fuentes, entre otros) y que el primer caso
también tiene adentro. La diferencia, unos 19 MB en tres noches, crece con cada noche; la del segundo caso, no. Y de las treinta figuras olvidadas,
Matplotlib avisó **una vez**, al pasar de veinte.

**Detalles con intención**

- **`matplotlib.use("Agg")`** elige el *backend* que dibuja en memoria, sin ventana. En un servidor sin pantalla, otros *backends* fallan al
  importar o al dibujar; `Agg` es el que se fija en un proceso.
- **`Figure()` directo**, sin `pyplot`: es la forma que la documentación de Matplotlib recomienda para servidores web y procesos. Nadie más tiene
  una referencia a la figura, así que se libera sola.
- **`FuncFormatter`** pone los montos en millones de pesos en el eje. El formato de los números es parte del entregable; el que viene por
  defecto (`1e6` en la esquina) no lo entiende un franquiciado.
- **El aviso de las 20 figuras** es la única señal que da Matplotlib de que algo se está acumulando; en un proceso nocturno va a una bitácora
  que nadie lee.

---

## ⚠️ 4. Lo que se rompe

**Las figuras que nadie cierra.** Lo que mide el ejemplo. Al cabo de un mes de noches, el proceso que genera los reportes ocupa cientos de MB
y termina cayéndose por memoria, lejos del código que lo causó.

**`pyplot` en un servidor con hilos.** Dos peticiones que dibujan a la vez con `pyplot` comparten la figura "actual" y se mezclan las líneas.
Con `Figure()`, cada petición tiene la suya.

**Las fuentes del servidor.** El servidor no tiene las fuentes de la máquina del ingeniero, y las tildes de "Usaquén" o "Engativá" pueden salir
como cuadros si la fuente elegida no las tiene. Se fija una fuente que se instala con el proceso (DejaVu Sans viene con Matplotlib).

**Leer un gráfico en el código que lo dibuja.** Un error de datos (una sede con el mes de otra) no se ve en el código; se ve en la imagen. Las
imágenes del cierre se revisan, al menos, con una prueba de "imagen de referencia" (`pytest-mpl`).

---

## ⚖️ 5. Cuándo NO usarlo

**Matplotlib para un tablero interactivo.** Para eso, Dash con Plotly (`ui04`): Matplotlib produce imágenes fijas.

**Imperativo para un gráfico que cambia según los datos.** Si el reporte tiene que pasar de barras a líneas o agregar una faceta por sede, la
gramática (`vz02`) lo hace con menos código.

**Un gráfico donde una tabla bastaba.** Tres números se leen mejor en una tabla (`ui08`) que en tres barras.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** la memoria retenida con cada API, y cuántas figuras quedaron vivas.
2. Agrega `plt.close()` al final de `with_pyplot`. **Criterio:** las figuras vivas y la memoria con el arreglo.
3. Abre `recaudo-Usaquén.png`. **Criterio:** la tilde se ve bien, y el eje muestra millones de pesos.

**🟡 Intermedio (4–6)**

4. Genera las diez imágenes en paralelo con un `ThreadPoolExecutor` con cada API. **Criterio:** describes qué sale mal con `pyplot`.
5. Marca en rojo los días por debajo de la meta diaria de cada sede. **Criterio:** el color lo decide el código, no una persona.
6. Exporta a SVG en vez de PNG. **Criterio:** el tamaño de los dos archivos, y cuál conviene para un PDF (`ui08`).

**🟠 Difícil (7–9)**

7. Escribe una prueba de imagen de referencia con `pytest-mpl`. **Criterio:** cambiar el color de la barra hace fallar la prueba.
8. Mide la memoria del proceso (RSS) durante 300 iteraciones con cada API. **Criterio:** la curva de memoria de cada una.
9. Haz la imagen con el estilo de la marca de Áurea (fuente, colores, logo) definido en un archivo `.mplstyle`. **Criterio:** el código no tiene
   colores escritos.

**🔴 Muy difícil (10)**

10. Diseña la generación de imágenes del cierre nocturno. **Criterio:** una página. *Rúbrica:* (a) API y *backend*, con la medición; (b) fuentes y
    estilo, y cómo se instalan en el servidor; (c) cómo se prueba que una imagen está bien; (d) qué pasa si una sede no tiene datos esa noche.

---

## 📚 7. Referencias

**Documentación oficial**

- Matplotlib, las dos interfaces: https://matplotlib.org/stable/users/explain/figure/api_interfaces.html
- Matplotlib, usar Matplotlib en un servidor web: https://matplotlib.org/stable/gallery/user_interfaces/web_application_server_sgskip.html
- `pytest-mpl`: https://pytest-mpl.readthedocs.io/en/latest/

**Lectura**

- Claus O. Wilke, *Fundamentals of Data Visualization* (O'Reilly, 2019), gratuito en línea: https://clauswilke.com/dataviz/

**Orden de lectura sugerido:** la página de las dos interfaces de Matplotlib; después la de servidores web, que es la de este caso.

---

## 🚀 8. Cierre

Un gráfico como entregable se produce sin pantalla y sin nadie mirando. Matplotlib tiene dos API, y la de `pyplot` guarda figuras en un registro
global que hay que cerrar; en un proceso, se usa `Figure()` con el *backend* `Agg`, y se libera solo. El formato de los números, las fuentes y una
prueba de imagen son parte del entregable.

**La señal de que quedó bien:** *"El proceso de las imágenes del cierre corre desde hace meses con la misma memoria, y las tildes de Usaquén salen
bien."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-vz-fase-01 -m "op vz01 cerrada: pyplot contra Figure en un proceso que dibuja solo"
> ```
>
> Los commits llevan su prefijo (`op vz01: …`) y los de ejercicio su número
> (`op vz01 ej07: …`).
