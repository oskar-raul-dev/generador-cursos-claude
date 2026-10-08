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
