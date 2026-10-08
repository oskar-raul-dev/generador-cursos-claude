"""El sitio de reservas, mínimo: elegir sede, ver espacios y reservar."""

from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse

app = FastAPI()
FREE = {"Centro": ["08:00", "15:40"], "Suba": ["09:20"]}


@app.get("/reservar", response_class=HTMLResponse)
def form() -> str:
    options = "".join(f"<option>{s}</option>" for s in FREE)
    return f"""<!doctype html><html lang="es"><body>
      <h1>Reservar una cita</h1>
      <form method="post" action="/reservar">
        <label>Sede <select name="sede">{options}</select></label>
        <label>Documento <input name="documento" required></label>
        <button type="submit">Ver espacios</button>
      </form></body></html>"""


@app.post("/reservar", response_class=HTMLResponse)
def slots(sede: str = Form(), documento: str = Form()) -> str:
    buttons = "".join(f'<button name="hora" value="{h}">{h}</button>' for h in FREE[sede])
    return f"""<!doctype html><html lang="es"><body>
      <h1>Espacios en {sede}</h1>
      <form method="post" action="/confirmar">
        <input type="hidden" name="sede" value="{sede}">{buttons}
      </form></body></html>"""


@app.post("/confirmar", response_class=HTMLResponse)
def confirm(sede: str = Form(), hora: str = Form()) -> str:
    return f'<!doctype html><html lang="es"><body><p role="status">Cita confirmada: {sede}, {hora}</p></body></html>'
