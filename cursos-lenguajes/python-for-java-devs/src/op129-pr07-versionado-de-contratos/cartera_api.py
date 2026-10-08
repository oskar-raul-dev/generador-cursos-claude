"""La API de cartera: calcula en cuántas cuotas se paga un saldo."""

from fastapi import FastAPI, Query

app = FastAPI(title="Cartera de Áurea", version="1.0.0")


@app.get("/cuotas")
def cuotas(saldo: int = Query(ge=0), cuota: int = Query(ge=0)) -> dict:
    return {"saldo": saldo, "cuota": cuota, "cuotas": -(-saldo // cuota)}   # techo de la división
