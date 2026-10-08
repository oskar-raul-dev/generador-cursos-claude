# 🎨 ui11 — rich e interacción en terminal

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 11 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El script de reproceso del cierre corre de noche desde el cron, y a veces de día, a mano, cuando una sede falló. De noche
nadie lo mira; de día, el ingeniero quiere ver una tabla legible de qué sede quedó cómo, una barra de progreso mientras
reprocesa, y que le pregunte qué sede reprocesar en vez de tener que recordar el argumento exacto.

`rich` hace todo eso con muy poco código —tablas, colores, barras de progreso, *tracebacks* legibles— y `questionary` o
`prompt_toolkit` agregan preguntas con opciones y autocompletado. La pregunta de esta sección no es cómo usarlas, que es
fácil, sino **cuánto adorno soporta una herramienta seria**: el mismo script que es agradable en la terminal del ingeniero
tiene que seguir siendo correcto cuando su salida va a un archivo de bitácora a las 4:00, sin una persona del otro lado.

---

## 🧠 2. El modelo

| Pieza | Para qué | Qué hace cuando no hay terminal |
|---|---|---|
| `rich.table.Table` 15.0.0 | Datos en filas y columnas, con alineación y color | Se imprime sin colores, con los bordes de texto |
| `rich.progress` | Barra de progreso | **No dibuja** la barra animada; con `transient`, no deja rastro |
| `rich.traceback.install()` | *Tracebacks* con código y variables locales | Se imprimen igual, más largos |
| `rich.prompt.Prompt` | Preguntar con opciones válidas | Lee de `stdin`, si hay algo que leer |
| `questionary` 2.1.1 | Listas para elegir con flechas, confirmaciones | **Falla**: necesita una terminal |
| `prompt_toolkit` 3.0.53 | Edición de línea, historial, autocompletado | Falla igual: es la base de `questionary` |

La regla que ordena la tabla: **`rich` detecta si la salida es una terminal y se modera solo**; las bibliotecas de
interacción no pueden, porque sin una persona no hay a quién preguntar. La herramienta seria pregunta solo si
`sys.stdin.isatty()`, y si no, exige el argumento.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, los colores en la terminal son códigos ANSI escritos a mano o una biblioteca como Jansi, y casi nadie los usa en
herramientas de servidor porque terminan como basura en los archivos de bitácora. El instinto evita los colores. Con `rich`
no hace falta evitarlos: detecta la terminal (y respeta `NO_COLOR` y `FORCE_COLOR`) y no escribe códigos de escape cuando la
salida va a un archivo.

---

## 💻 3. El ejemplo que corre

```bash
uv add rich
```

`reproceso.py`:

```python
"""Tabla, pregunta y progreso con rich, moderados solos cuando la salida no es una terminal."""

import sys
import time

from rich.console import Console
from rich.progress import track
from rich.prompt import Prompt
from rich.table import Table

console = Console()
CIERRE = {"Centro": ("ok", 118), "Chapinero": ("ok", 131), "Suba": ("falló", 0), "Kennedy": ("ok", 322)}

table = Table(title="Cierre del 2026-10-04")
table.add_column("Sede")
table.add_column("Estado")
table.add_column("Segundos", justify="right")
for sede, (status, secs) in CIERRE.items():
    style = "bold red" if status == "falló" else "green"
    table.add_row(sede, f"[{style}]{status}[/]", str(secs))
console.print(table)

sede = Prompt.ask("¿Qué sede reproceso?", choices=list(CIERRE), console=console)
for _ in track(range(5), description=f"Reprocesando {sede}…", console=console, transient=True):
    time.sleep(0.1)
console.print(f"[green]✔[/] {sede} reprocesada")
print(f"terminal: {console.is_terminal} · colores: {console.color_system}", file=sys.stderr)
```

`comparar_salidas.py` lo corre como lo correría el cron —con la salida a un archivo— y como lo vería el ingeniero
—`FORCE_COLOR=1`, que es lo que hace `rich` en una terminal de verdad—, y le contesta la pregunta por `stdin`, primero con
una sede que no existe:

```python
"""La misma herramienta, para el cron y para una persona: cuántos códigos de escape escribe cada vez."""

import os
import subprocess
import sys

for label, extra in [("cron (sin terminal)", {}), ("persona (FORCE_COLOR)", {"FORCE_COLOR": "1"})]:
    env = {k: v for k, v in os.environ.items() if k not in ("FORCE_COLOR", "NO_COLOR", "TERM")} | extra
    run = subprocess.run([sys.executable, "reproceso.py"], input="Bogotá\nSuba\n", capture_output=True,
                         text=True, env=env)
    print(f"{label:<22} {len(run.stdout):>5} bytes, {run.stdout.count(chr(27)):>3} escapes · {run.stderr.strip()}")
    if not extra:
        print(run.stdout)
```

```bash
python3 comparar_salidas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
cron (sin terminal)      477 bytes,   0 escapes · terminal: False · colores: None
      Cierre del 2026-10-04      
┏━━━━━━━━━━━┳━━━━━━━━┳━━━━━━━━━━┓
┃ Sede      ┃ Estado ┃ Segundos ┃
┡━━━━━━━━━━━╇━━━━━━━━╇━━━━━━━━━━┩
│ Centro    │ ok     │      118 │
│ Chapinero │ ok     │      131 │
│ Suba      │ falló  │        0 │
│ Kennedy   │ ok     │      322 │
└───────────┴────────┴──────────┘
¿Qué sede reproceso? [Centro/Chapinero/Suba/Kennedy]: Please select one of the available options
¿Qué sede reproceso? [Centro/Chapinero/Suba/Kennedy]: 
✔ Suba reprocesada

persona (FORCE_COLOR)   1438 bytes, 101 escapes · terminal: True · colores: standard
```

Sin terminal, 477 bytes y cero códigos de escape; para una persona, 1 438 bytes y 101 escapes: la bitácora del cron queda limpia, con la tabla en texto y sin la barra de progreso,
que `transient=True` borra al terminar. La pregunta rechazó `Bogotá` —que no es una sede de la lista— y aceptó `Suba`; las respuestas no aparecen después de
los dos puntos porque llegaron por una tubería, y una tubería no tiene eco.
Con `FORCE_COLOR`, la misma herramienta escribe los colores y la barra para una persona.

**Detalles con intención**

- **`console.is_terminal`** es lo que `rich` consulta para decidir; la herramienta puede consultarlo también para no preguntar
  nada si no hay nadie (`if not console.is_terminal: exigir el argumento`).
- **`Prompt.ask(..., choices=...)`** valida contra la lista y vuelve a preguntar. El mensaje de rechazo está en inglés; se
  cambia con `illegal_choice_message`.
- **El último `print` va a `stderr`**: es un mensaje de diagnóstico, no un dato. `comparar_salidas.py` lo separa justamente
  por eso.

---

## ⚠️ 4. Lo que se rompe

**`questionary` en el cron.** Una lista con flechas en un script que el cron llama sin terminal falla al arrancar (o se
queda esperando). La interacción se ofrece solo si `sys.stdin.isatty()`.

**La tabla ancha en una terminal angosta.** `rich` recorta o envuelve columnas para que quepan, y una cédula o un monto
recortado con `…` es un dato perdido. Las columnas de datos llevan `no_wrap=True` y `overflow="fold"`, o la herramienta
ofrece `--json` (`ui10`).

**`rich.traceback.install(show_locals=True)` en producción.** Muestra las variables locales de cada marco, que pueden ser
secretos o datos de pacientes (`se05`, `ob06`). En la terminal del ingeniero, útil; en la bitácora del servidor, no.

**El adorno que crece.** Paneles, emojis, árboles, colores por cada estado. Una herramienta seria tiene una tabla y una
línea final de resultado; lo demás se nota en la tercera semana de uso diario.

---

## ⚖️ 5. Cuándo NO usarlo

**`rich` en una biblioteca.** Si el código es una biblioteca que otros importan, no decide cómo se ve la salida: devuelve
datos, y quien la usa decide. `rich` va en la capa de la herramienta.

**Preguntas interactivas en un comando que se automatiza.** Si el comando se va a llamar desde otro script, todo lo que pregunta
tiene que poder darse como argumento.

**Colores para transmitir información sin texto.** "Rojo es falló" no le sirve a quien no distingue colores ni a la bitácora:
el estado se escribe con palabras, y el color se agrega encima.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `python3 reproceso.py` en tu terminal y luego `python3 reproceso.py > salida.txt`. **Criterio:** describes las
   diferencias y abres `salida.txt`.
2. Cambia el mensaje de opción inválida a español. **Criterio:** la corrida con `Bogotá` lo muestra.
3. Corre con `NO_COLOR=1` en tu terminal. **Criterio:** la tabla sale sin colores.

**🟡 Intermedio (4–6)**

4. Haz que la sede se pueda dar como argumento y que, sin argumento y sin terminal, el programa salga con código 2.
   **Criterio:** `python3 reproceso.py < /dev/null` sale con 2 y un mensaje en `stderr`.
5. Usa `questionary.select` para elegir la sede con flechas, solo cuando hay terminal. **Criterio:** el cron sigue
   funcionando con el argumento.
6. Reemplaza `track` por un `Progress` con dos tareas (descargar y reprocesar). **Criterio:** las dos barras avanzan en la
   terminal, y la bitácora queda limpia.

**🟠 Difícil (7–9)**

7. Escribe una prueba de la pregunta con `prompt_toolkit.input.create_pipe_input`. **Criterio:** la prueba elige Suba sin
   terminal real.
8. Instala `rich.traceback` con `show_locals=True` y provoca un error con un secreto en una variable local. **Criterio:**
   muestras que aparece, y lo evitas en producción con una variable de entorno.
9. Exporta la tabla a HTML con `Console(record=True)` y `save_html`. **Criterio:** el HTML se ve como la terminal.

**🔴 Muy difícil (10)**

10. Define la guía de estilo de las herramientas de terminal de Áurea. **Criterio:** una página. *Rúbrica:* (a) qué se
    imprime con terminal y sin ella; (b) cuándo se pregunta y cuándo se exige el argumento; (c) qué adorno se permite; (d)
    cómo se prueba que la bitácora del cron queda limpia.

---

## 📚 7. Referencias

**Documentación oficial**

- `rich`: https://rich.readthedocs.io/en/stable/
- `rich`, la consola y la detección de terminal: https://rich.readthedocs.io/en/stable/console.html
- `questionary`: https://questionary.readthedocs.io/en/stable/
- `prompt_toolkit`: https://python-prompt-toolkit.readthedocs.io/en/master/
- La convención `NO_COLOR`: https://no-color.org/

**Orden de lectura sugerido:** la página de la consola de `rich`, que explica la detección de terminal y las variables de
entorno; después, si hace falta interacción, `questionary`.

---

## 🚀 8. Cierre

`rich` vuelve legible una herramienta de terminal y se modera solo cuando la salida no es una terminal: cero códigos de escape
en la bitácora del cron. La interacción —preguntas, listas con flechas— solo se ofrece si hay una persona; si no, se exige el
argumento. Una herramienta seria tiene una tabla y una línea de resultado, y escribe los estados con palabras.

**La señal de que quedó bien:** *"De día, el reproceso muestra una tabla con colores y pregunta qué sede; de noche, la
bitácora del cron tiene la misma tabla en texto y ningún carácter raro."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-11 -m "op ui11 cerrada: rich que se modera solo y la interacción solo con persona"
> ```
>
> Los commits llevan su prefijo (`op ui11: …`) y los de ejercicio su número
> (`op ui11 ej07: …`).
