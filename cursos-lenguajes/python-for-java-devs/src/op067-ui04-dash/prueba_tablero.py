"""El callback es una función, y la interacción es un POST sin sesión."""

from tablero import app, show

print("como función:", show("Suba"))

client = app.server.test_client()
for sede in ("Suba", "Kennedy"):
    payload = {
        "output": "..facturado.children...recaudo.children..",
        "outputs": [{"id": "facturado", "property": "children"}, {"id": "recaudo", "property": "children"}],
        "inputs": [{"id": "sede", "property": "value", "value": sede}],
        "changedPropIds": ["sede.value"],
        "state": [],
    }
    response = client.post("/_dash-update-component", json=payload)
    print("por HTTP:    ", response.status_code, response.get_json()["response"])
