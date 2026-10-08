"""El tablero de cartera en Dash: un callback declarado, y el servidor sin estado."""

from dash import Dash, Input, Output, callback, dcc, html

DATA = {"Centro": (187_450_000, 162_300_000), "Suba": (142_900_000, 118_600_000),
        "Kennedy": (98_300_000, 91_200_000)}


def pesos(v: int) -> str:
    return "$" + f"{v:,}".replace(",", ".")


app = Dash(__name__)
app.layout = html.Div([
    html.H1("Cartera por sede"),
    dcc.Dropdown(list(DATA), "Centro", id="sede", clearable=False),
    html.P(id="facturado"),
    html.P(id="recaudo"),
])


@callback(Output("facturado", "children"), Output("recaudo", "children"), Input("sede", "value"))
def show(sede: str):
    billed, collected = DATA[sede]
    return f"Facturado: {pesos(billed)}", f"Recaudo: {collected / billed:.1%}"


if __name__ == "__main__":
    app.run(debug=False)
