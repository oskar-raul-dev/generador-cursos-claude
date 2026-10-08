# 🧰 ui05 — NiceGUI y compañía

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 5 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Gradio, Streamlit y Dash no son las únicas. Cada año aparece una biblioteca más que promete "aplicaciones web en Python
puro", y cinco de ellas tienen comunidad y mantenimiento serios: **NiceGUI**, **Reflex**, **Shiny for Python**, **Panel**
y **Flet**. El problema de este perfil no es aprender las cinco; es poder descartar cuatro con criterio cuando alguien del
equipo propone la que vio en un video.

El criterio no es la sintaxis, que en todas es agradable. Son dos cosas: **el modelo** —cómo se entera la pantalla de que
algo cambió, y dónde vive el estado— y **lo que pesa**, que es lo que se instala, se actualiza y se arranca en el servidor
de Áurea. Esta sección mide lo segundo y escribe la misma pantalla en las dos que mejor representan los dos modelos que
faltaban en el track: eventos (NiceGUI) y reactividad de hoja de cálculo (Shiny).

---

## 🧠 2. El modelo

| Biblioteca | Modelo | Estado | Para qué brilla |
|---|---|---|---|
| **NiceGUI** 3.17.1 | **Eventos**: un manejador cambia un componente | En el servidor, por cliente, por *websocket* | Pantallas con controles, paneles de máquinas, herramientas internas |
| **Shiny for Python** 1.8.0 | **Reactivo**: las salidas dependen de las entradas, como celdas de una hoja | En el servidor, por sesión | Análisis interactivo; viene de R y su comunidad estadística |
| **Panel** 1.9.4 | Reactivo, sobre Bokeh y HoloViz | En el servidor | Tableros científicos; integración con notebooks |
| **Reflex** 0.9.12 | Compila a una aplicación React + un servidor de estado | En el servidor, con *websocket* | Aplicaciones completas; necesita Node para construir |
| **Flet** 1.0.3 | Flutter controlado desde Python | En el proceso de Python | Escritorio y móvil además de web |

El modelo de eventos es el que este perfil conoce de Swing: `on_change=` y se cambia el texto de una etiqueta. El modelo
reactivo es el de una hoja de Excel: una salida declara de qué entradas depende, y se recalcula sola cuando cambian. Ninguno
es mejor; el reactivo evita olvidarse de actualizar algo, y el de eventos es más fácil de seguir con un depurador.

---

## 💻 3. El ejemplo que corre

La misma pantalla —una lista de sedes y lo facturado— en los dos modelos.

`app_nicegui.py`, eventos:

```python
"""La pantalla de cartera en NiceGUI: un manejador de evento cambia una etiqueta."""

from nicegui import ui

DATA = {"Centro": 187_450_000, "Suba": 142_900_000, "Kennedy": 98_300_000}


def pesos(v: int) -> str:
    return "$" + f"{v:,}".replace(",", ".")


@ui.page("/")
def index():
    ui.label("Cartera por sede").classes("text-2xl")
    billed = ui.label(f"Facturado: {pesos(DATA['Centro'])}")
    ui.select(list(DATA), value="Centro",
              on_change=lambda e: billed.set_text(f"Facturado: {pesos(DATA[e.value])}"))


if __name__ in {"__main__", "__mp_main__"}:
    ui.run(title="Cartera", port=8081, reload=False, show=False)
```

`app_shiny.py`, reactivo:

```python
"""La misma pantalla en Shiny: la salida declara de qué entrada depende."""

from shiny import App, render, ui

DATA = {"Centro": 187_450_000, "Suba": 142_900_000, "Kennedy": 98_300_000}


def pesos(v: int) -> str:
    return "$" + f"{v:,}".replace(",", ".")


app_ui = ui.page_fluid(
    ui.h2("Cartera por sede"),
    ui.input_select("sede", "Sede", list(DATA)),
    ui.output_text("facturado"),
)


def server(input, output, session):
    @render.text
    def facturado():
        return f"Facturado: {pesos(DATA[input.sede()])}"     # leer input.sede() crea la dependencia


app = App(app_ui, server)
```

```bash
python3 app_nicegui.py              # http://127.0.0.1:8081
shiny run app_shiny.py --port 8082  # http://127.0.0.1:8082
```

Y lo que pesa cada una. `medir.py` instala cada biblioteca en su propio entorno virtual, limpio, y mide el tamaño instalado
y lo que tarda en importarse —el costo que se paga en cada despliegue y en cada arranque—:

```python
"""Lo que pesa cada biblioteca: tamaño instalado y tiempo de importación, cada una en su venv."""

import subprocess
import sys
from pathlib import Path

LIBS = {"nicegui": "nicegui==3.17.1", "shiny": "shiny==1.8.0", "panel": "panel==1.9.4",
        "reflex": "reflex==0.9.12", "flet": "flet==1.0.3", "streamlit": "streamlit==1.65.0",
        "dash": "dash==4.4.1", "gradio": "gradio==6.29.1"}
IMPORT_TIME = "import time; t = time.perf_counter(); import {m}; print(time.perf_counter() - t)"

print(f"{'biblioteca':<11}{'paquetes':>9}{'MB':>7}{'importar (s)':>14}")
for module, spec in LIBS.items():
    venv = Path("/tmp/venvs") / module
    subprocess.run([sys.executable, "-m", "venv", str(venv)], check=True)
    py = venv / "bin" / "python"
    subprocess.run([py, "-m", "pip", "install", "-q", "--disable-pip-version-check", spec], check=True)
    site = next(venv.glob("lib/python*/site-packages"))
    mb = sum(f.stat().st_size for f in site.rglob("*") if f.is_file()) / 1e6
    packages = len(list(site.glob("*.dist-info"))) - 1                  # menos pip
    runs = [float(subprocess.run([py, "-c", IMPORT_TIME.format(m=module)], capture_output=True,
                                 text=True, check=True).stdout) for _ in range(3)]
    print(f"{module:<11}{packages:>9}{mb:>7.0f}{min(runs):>14.2f}")
```

```bash
python3 medir.py
```

Salida (Python 3.14.7, 05/10/2026) (los números dependen de la máquina; la columna de importación es la mejor de tres):

```text
biblioteca  paquetes     MB  importar (s)
nicegui           49    114          0.31
shiny             32    110          0.22
panel             31    354          0.48
reflex            40     71          0.00
flet              12     23          0.04
streamlit         36    418          0.16
dash              28    136          0.16
gradio            53    326          1.19
```

Las bibliotecas del track van de 23 MB a más de 400, y de 12 a 53 paquetes que vigilar. Streamlit y Panel pesan lo que
pesan por arrastrar pandas y NumPy (Streamlit, además, PyArrow; Panel, Bokeh); Gradio, además, tarda más de un segundo en importarse, que se paga en cada
arranque y en cada prueba. Dos cifras engañan y conviene leerlas bien: Reflex "se importa" en 0,00 s porque carga sus
módulos de forma perezosa —el costo se muda al primer uso y a la construcción con Node—, y Flet pesa 23 MB porque el
cliente de Flutter no viene en el paquete: se descarga la primera vez que corre.

**Detalles con intención**

- **En NiceGUI, `@ui.page("/")`** crea la pantalla por cliente: cada navegador tiene su propia etiqueta y su propia lista.
  Sin el decorador, los componentes se crean una vez y **todos los navegadores comparten la misma pantalla** —útil para un
  panel de una máquina, sorprendente para un tablero de cartera—.
- **En Shiny, la dependencia es implícita**: `facturado` lee `input.sede()`, y Shiny anota que depende de ella. No hay
  `Input(...)` declarado como en Dash (`ui04`); la lectura es la declaración.
- **El HTML inicial dice mucho del modelo.** En la prueba de humo, la página de NiceGUI (10 515 bytes) ya trae el texto
  "Facturado: …"; la de Shiny (2 419 bytes) no lo trae: la salida se calcula cuando el navegador abre su *websocket* y la
  sesión empieza. Una página de Shiny sin JavaScript, o detrás de un proxy que corta *websockets*, muestra la lista y nada
  más.
- **El tamaño instalado cuenta todo el árbol de dependencias**, no solo el paquete. Es lo que hay que actualizar cuando sale
  un parche de seguridad en cualquiera de esos paquetes (`se07`).

---

## ⚠️ 4. Lo que se rompe

**Reflex y el Node escondido.** Reflex compila la interfaz a una aplicación de React, y para eso descarga y usa Node (o Bun)
en la primera ejecución. En un servidor sin acceso a internet, o en un contenedor mínimo, la primera ejecución falla. Es una
biblioteca de Python con una cadena de construcción de JavaScript adentro.

**Flet y la versión 1.0.** Flet cambió de API en el paso a 1.0. Los ejemplos y tutoriales anteriores no corren sin
cambios; se lee la guía de migración y se fija la versión.

**NiceGUI sin `@ui.page`.** Por lo del detalle de arriba: dos personas eligiendo sede en la misma pantalla compartida.

**Elegir por la demo.** Todas hacen una demo vistosa en diez líneas. La diferencia aparece en la pantalla número cinco, con
permisos, con datos que tardan y con alguien que pide un cambio de diseño. Se prueba la pantalla difícil, no la fácil.

---

## ⚖️ 5. Cuándo NO usarlas

**Cuando una de las tres grandes ya está en la casa.** Si Áurea ya opera Streamlit, una segunda biblioteca de interfaces es
el doble de dependencias, de actualizaciones y de cosas que aprender, para pantallas parecidas.

**Reflex para una herramienta interna.** Su promesa es una aplicación completa; su costo es una cadena de construcción con
Node. Para una herramienta de Patricia, es demasiado.

**Flet para web solamente.** Su ventaja es el escritorio y el móvil; para una pantalla web, las otras pesan menos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `medir.py` en tu máquina. **Criterio:** la tabla, y la biblioteca más liviana y la más pesada.
2. Quita `@ui.page("/")` en NiceGUI y abre la página en dos navegadores. **Criterio:** describes lo que pasa al cambiar la
   sede en uno.
3. Agrega a la versión de Shiny una segunda salida, el recaudo, que dependa de la misma entrada. **Criterio:** las dos se
   actualizan sin código de evento.

**🟡 Intermedio (4–6)**

4. Escribe la misma pantalla en Panel. **Criterio:** funciona, y cuentas las líneas contra las otras dos.
5. Prueba la versión de NiceGUI con su *fixture* `user` de `pytest` (sin navegador). **Criterio:** la prueba elige Suba y
   verifica el texto.
6. Agrega a Shiny un `@reactive.calc` que cargue los datos, usado por las dos salidas. **Criterio:** la carga corre una vez
   por cambio de sede, demostrado con un contador.

**🟠 Difícil (7–9)**

7. Instala Reflex en un contenedor sin acceso a internet después de la instalación de paquetes. **Criterio:** el error exacto
   de la primera ejecución y cómo se resuelve.
8. Mide la memoria del servidor con diez clientes conectados en NiceGUI y en Shiny. **Criterio:** la tabla, en tu máquina.
9. Escribe la misma pantalla en Flet y ábrela como aplicación de escritorio. **Criterio:** el mismo código corre en el
   navegador y en una ventana.

**🔴 Muy difícil (10)**

10. Haz la "prueba de la pantalla cinco": un formulario con validación, una tabla editable y permisos por sede, en dos de las
    cinco bibliotecas. **Criterio:** las dos versiones y una página. *Rúbrica:* (a) líneas de código; (b) lo que no se pudo
    hacer o costó un truco; (c) memoria y tiempo de respuesta medidos; (d) la elegida y por qué.

---

## 📚 7. Referencias

**Documentación oficial**

- NiceGUI: https://nicegui.io/documentation
- Shiny for Python: https://shiny.posit.co/py/
- Panel: https://panel.holoviz.org/
- Reflex: https://reflex.dev/docs/getting-started/introduction/
- Flet: https://flet.dev/docs/

**Orden de lectura sugerido:** la sección de reactividad de la documentación de Shiny, que explica el modelo de hoja de
cálculo mejor que nadie; después la de páginas de NiceGUI.

---

## 🚀 8. Cierre

Las cinco hacen la misma pantalla. Las separa el modelo —eventos o reactividad, estado por cliente o compartido— y lo que
pesan en el servidor, que se mide en una tarde. Se elige una, se prueba con la pantalla difícil, y la segunda biblioteca
de interfaces de la casa necesita una razón medida.

**La señal de que quedó bien:** *"Alguien propuso Reflex después de ver un video, y la tabla de `medir.py` cerró la
discusión en cinco minutos."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-05 -m "op ui05 cerrada: eventos o reactividad, y lo que pesa cada biblioteca"
> ```
>
> Los commits llevan su prefijo (`op ui05: …`) y los de ejercicio su número
> (`op ui05 ej07: …`).
