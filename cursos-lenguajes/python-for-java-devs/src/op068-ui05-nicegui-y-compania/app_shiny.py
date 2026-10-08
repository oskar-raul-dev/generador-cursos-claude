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
