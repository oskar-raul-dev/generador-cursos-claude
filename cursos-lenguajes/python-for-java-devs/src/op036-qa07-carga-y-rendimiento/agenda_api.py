"""AgendaAPI mínima: disponibilidad por sede y reserva, con una latencia simulada de base de datos."""

import asyncio
import random

from fastapi import FastAPI, HTTPException

app = FastAPI()
SEDES = {"centro", "suba", "zipaquira"}


@app.get("/disponibilidad/{sede}")
async def availability(sede: str) -> dict:
    if sede not in SEDES:
        raise HTTPException(404, f"no existe la sede {sede}")
    await asyncio.sleep(random.uniform(0.005, 0.020))     # la consulta a la base
    return {"sede": sede, "libres": ["08:00", "08:40", "15:40"]}


@app.post("/reservas/{sede}")
async def book(sede: str) -> dict:
    await asyncio.sleep(random.uniform(0.010, 0.040))
    return {"reserva": "R1"}
