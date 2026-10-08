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
