# 🧱 ui12 — TUI completas con Textual

> Python para desarrolladores Java senior · **Carta** · Track `ui` — Interfaces y entregables sin
> frontend · sección 12 de 13
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El ingeniero de Áurea entra por SSH al servidor de las sedes varias veces por semana: a ver cómo quedó el cierre, a reprocesar
una sede, a mirar una bitácora. Hoy son cinco comandos distintos con sus argumentos. Una herramienta de terminal con
pantalla completa —una lista de sedes que se recorre con flechas, una tecla para reprocesar, un panel con el detalle—
juntaría las cinco en una, y funcionaría por SSH sin abrir puertos ni levantar un servidor web.

Eso es una TUI (*text user interface*), y Textual es el *framework* de Python para escribirlas: componentes, disposición con
un CSS propio, eventos, enlaces de teclas, y una herramienta de pruebas que opera la aplicación sin terminal. Es del mismo
autor que `rich`, y lo que dibuja `rich` en una línea, Textual lo convierte en una aplicación.

---

## 🧠 2. El modelo

| Pieza | Qué es | En el ejemplo |
|---|---|---|
| `App` | La aplicación, con su ciclo de eventos (asyncio) | `CierreApp` |
| *Widgets* | Componentes: `DataTable`, `Input`, `Log`, `Header`, `Footer` | La tabla de sedes |
| `BINDINGS` | Teclas que disparan acciones (`action_*`) | `r` reprocesa la sede elegida |
| CSS de Textual (`.tcss`) | Disposición y estilo, con un subconjunto de CSS | — |
| `run_test()` y `Pilot` | Ejecutar la aplicación sin terminal y operarla desde una prueba | La prueba del ejemplo |
| `textual serve` | Servir la misma aplicación en un navegador | Ejercicio 8 |

### Tu instinto de Java dice… y esta vez se equivoca

Las TUI en Java fueron Lanterna o curses por JNI, y el instinto las asocia con interfaces de los ochenta, difíciles de escribir
y de probar. Textual se escribe como una aplicación de escritorio moderna —componentes, eventos, estilos— y se prueba como
una aplicación web, con un piloto que aprieta teclas. El costo ya no está en escribirla.

---

## 💻 3. El ejemplo que corre

```bash
uv add textual
```

`cierre_tui.py`:

```python
"""La consola del cierre: las sedes en una tabla, y 'r' reprocesa la elegida."""

from textual.app import App, ComposeResult
from textual.widgets import DataTable, Footer, Header

CIERRE = [("Centro", "ok", 118), ("Chapinero", "ok", 131), ("Suba", "falló", 0), ("Kennedy", "ok", 322)]


class CierreApp(App):
    TITLE = "Cierre del 2026-10-04"
    BINDINGS = [("r", "reprocess", "Reprocesar"), ("q", "quit", "Salir")]

    def compose(self) -> ComposeResult:
        yield Header()
        yield DataTable(cursor_type="row")
        yield Footer()

    def on_mount(self) -> None:
        table = self.query_one(DataTable)
        for label in ("Sede", "Estado", "Segundos"):
            table.add_column(label, key=label.lower())
        for sede, status, secs in CIERRE:
            table.add_row(sede, status, secs, key=sede)

    def action_reprocess(self) -> None:
        table = self.query_one(DataTable)
        row_key, _ = table.coordinate_to_cell_key(table.cursor_coordinate)
        table.update_cell(row_key, "estado", "reprocesada")      # en la vida real: lanzar el trabajo
        self.notify(f"{row_key.value} enviada a reproceso")


if __name__ == "__main__":
    CierreApp().run()
```

Las columnas se agregan con clave (`key=`) para que `update_cell` encuentre la del estado por nombre. La prueba, `prueba_tui.py`,
opera la aplicación como lo haría el ingeniero —dos flechas abajo, la tecla `r`— sin ninguna terminal:

```python
"""Opera la TUI sin terminal: baja dos filas, aprieta 'r' y lee la tabla."""

import asyncio

from textual.widgets import DataTable

from cierre_tui import CierreApp


async def main():
    app = CierreApp()
    async with app.run_test() as pilot:
        await pilot.press("down", "down", "r")
        await pilot.pause()
        table = app.query_one(DataTable)
        for row in range(table.row_count):
            print(table.get_row_at(row))


asyncio.run(main())
```

```bash
python3 prueba_tui.py
python3 cierre_tui.py          # la aplicación, en tu terminal
```

Salida (Python 3.14.7, 05/10/2026):

```text
['Centro', 'ok', 118]
['Chapinero', 'ok', 131]
['Suba', 'reprocesada', 0]
['Kennedy', 'ok', 322]
```

El cursor empieza en Centro, baja dos filas hasta Suba, y la `r` cambia su estado. La prueba no abrió ninguna terminal: Textual
corre la aplicación completa —eventos, enlaces de teclas, componentes— en modo sin cabeza, y el piloto aprieta las teclas. Es
la misma prueba que va en el CI.

**Detalles con intención**

- **`key=sede`** en cada fila hace que `row_key.value` sea el nombre de la sede, no un índice. Si la tabla se reordena, la
  acción sigue apuntando a la sede correcta.
- **`action_reprocess`** sigue la convención de Textual: la tecla `r` declarada en `BINDINGS` llama a `action_` más el nombre.
  El pie (`Footer`) muestra las teclas solo.
- **`pilot.pause()`** espera a que la aplicación procese los eventos pendientes antes de leer la tabla. Sin él, la prueba puede
  leer antes de que la tecla tenga efecto.
- **Por SSH funciona tal cual**: Textual dibuja con códigos de terminal, y una sesión SSH es una terminal.

---

## ⚠️ 4. Lo que se rompe

**Trabajo lento en el manejador.** El reproceso tarda minutos; si `action_reprocess` lo hace directamente, la pantalla se
congela. Se lanza como trabajo de fondo (`self.run_worker`, o `@work`) y la tabla se actualiza cuando termina.

**Las terminales que no ayudan.** La consola vieja de Windows, `screen` mal configurado, o una terminal con pocas columnas
dibujan mal los bordes y los colores. Textual degrada, pero el ingeniero que entra desde el teléfono va a ver una tabla rota.

**La TUI como reemplazo de la CLI.** Una TUI no se puede llamar desde el cron ni desde otro script. Las acciones de la TUI
llaman a los mismos comandos de la CLI (`ui10`), que siguen existiendo para la automatización.

**Las versiones mayores.** Textual cambió bastante entre versiones mayores; la versión se fija y las pruebas con el piloto
avisan cuando una actualización rompe algo.

---

## ⚖️ 5. Cuándo NO usarlo

**Para Patricia.** Una TUI es una interfaz para quien vive en la terminal. Para todos los demás, la página web de los
escalones anteriores.

**Para algo que se usa una vez por semana.** Si el ingeniero reprocesa una sede una vez por semana, un comando con
autocompletado (`ui10`) es más barato que una aplicación.

**Si ya hay una página web interna con lo mismo.** Dos interfaces para la misma operación son dos cosas que mantener.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `cierre_tui.py`, recorre la tabla y reprocesa Suba. **Criterio:** ves la notificación y el pie con las teclas.
2. Agrega la tecla `d` que muestre el detalle de la sede en una notificación. **Criterio:** la prueba con el piloto la
   aprieta y lee la notificación.
3. Colorea en rojo las filas con estado `falló`. **Criterio:** usas el CSS de Textual o `rich.text.Text`, no códigos a mano.

**🟡 Intermedio (4–6)**

4. Haz que el reproceso sea un trabajo de fondo de tres segundos. **Criterio:** durante esos segundos la tabla se puede
   recorrer, y al terminar el estado cambia.
5. Agrega un panel lateral con la bitácora de la sede elegida (`Log`). **Criterio:** cambiar de fila cambia la bitácora.
6. Escribe una prueba de captura de pantalla con `pytest-textual-snapshot`. **Criterio:** un cambio en la disposición hace
   fallar la prueba.

**🟠 Difícil (7–9)**

7. Haz que la acción de reproceso llame al comando de la CLI de `ui10` con `subprocess`. **Criterio:** la TUI y el cron usan el
   mismo comando.
8. Sirve la aplicación en el navegador con `textual serve` en un contenedor (sin puertos por defecto). **Criterio:** la misma
   aplicación funciona en el navegador, y explicas qué cambia en seguridad.
9. Conéctate por SSH a un contenedor que corra la TUI como *shell* de un usuario. **Criterio:** al entrar, aparece la consola
   del cierre en vez de un *shell*.

**🔴 Muy difícil (10)**

10. Decide si la operación del cierre de Áurea merece una TUI. **Criterio:** una página. *Rúbrica:* (a) quién la usa y con qué
    frecuencia; (b) qué hace que no haga la CLI; (c) cómo se prueba; (d) qué pasa con la automatización.

---

## 📚 7. Referencias

**Documentación oficial**

- Textual, guía: https://textual.textualize.io/guide/
- Textual, pruebas: https://textual.textualize.io/guide/testing/
- Textual, `DataTable`: https://textual.textualize.io/widgets/data_table/

**Orden de lectura sugerido:** el tutorial de la guía de Textual (una tarde) y después la página de pruebas.

---

## 🚀 8. Cierre

Textual convierte las cinco consultas por SSH en una aplicación de terminal con tabla, teclas y notificaciones, que se prueba
sin terminal con un piloto que aprieta teclas. Sus acciones llaman a los mismos comandos que usa el cron, y es una interfaz
para quien vive en la terminal: el ingeniero, no Patricia.

**La señal de que quedó bien:** *"Entré por SSH desde la casa, bajé hasta Suba, apreté `r`, y la prueba del CI hace
exactamente lo mismo."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ui-fase-12 -m "op ui12 cerrada: la consola del cierre en Textual, probada con el piloto"
> ```
>
> Los commits llevan su prefijo (`op ui12: …`) y los de ejercicio su número
> (`op ui12 ej07: …`).
