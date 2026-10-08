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
