"""El endpoint de predicción de AgendaAPI, con los dos formatos detrás.

    AUREA_BACKEND=pickle uvicorn serve:app --port 8100
    AUREA_BACKEND=onnx   uvicorn serve:app --port 8101

Misma API, mismo modelo, dos maneras de cargarlo. La sección 6 las mide de punta a punta
—por HTTP, no en proceso— porque es lo que aprendió la Fase 10 del camino base: el costo del
modelo de salida de FastAPI parecía un 33% medido en proceso y desapareció medido sobre HTTP.

🧭 **El backend se elige por variable de entorno y se anuncia en `/salud`.** Un servicio que
no dice qué modelo tiene cargado es un servicio que nadie puede depurar cuando las
predicciones cambien.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field

MODELS = Path(os.environ.get("AUREA_MODELOS", "modelos"))
BACKEND: Literal["pickle", "onnx"] = os.environ.get("AUREA_BACKEND", "onnx")  # type: ignore[assignment]


class Appointment(BaseModel):
    """Una cita a puntuar. Los nombres y el orden son los de `ds08`, y eso importa.

    Las seis columnas llegan **con nombre** y el servidor arma el vector en el orden del
    modelo. Aceptar una lista de seis números habría sido más corto y convierte cualquier
    reordenamiento en un error silencioso que nadie detecta hasta que las predicciones se
    vuelven raras.
    """

    inasistencias_previas: float = Field(ge=0)
    jueves_tarde: float = Field(ge=0, le=1)
    lluvia_mm: float = Field(ge=0)
    distancia_km: float = Field(gt=0)
    dias_desde_agendamiento: float = Field(ge=0)

    def vector(self) -> list[float]:
        return [self.inasistencias_previas, self.jueves_tarde, self.lluvia_mm,
                self.distancia_km, self.dias_desde_agendamiento,
                # La interacción se calcula aquí, no la manda el cliente: es parte del
                # modelo, y pedírsela a quien llama sería filtrar el modelo a la API.
                self.lluvia_mm * self.distancia_km]


class Prediction(BaseModel):
    probabilidad_inasistencia: float
    backend: str


def load_pickle():
    import pickle

    # ⚠️ Esto ejecuta código si el archivo no es el que crees. Ver `pickle_danger.py` y la
    # sección 5.4: la ruta se fija por configuración y el archivo lo escribe el proceso de
    # entrenamiento, nunca un cliente.
    with (MODELS / "modelo.pkl").open("rb") as file:
        pipeline = pickle.load(file)

    def predict(vector: list[float]) -> float:
        return float(pipeline.predict_proba([vector])[0][1])

    return predict


def load_onnx():
    import numpy as np
    import onnxruntime

    session = onnxruntime.InferenceSession(str(MODELS / "modelo.onnx"),
                                           providers=["CPUExecutionProvider"])
    name = session.get_inputs()[0].name

    def predict(vector: list[float]) -> float:
        batch = np.array([vector], dtype=np.float32)
        return float(session.run(None, {name: batch})[1][0][1])

    return predict


app = FastAPI(title="Ausentismo · Áurea", version="1.0")
_predict = (load_pickle if BACKEND == "pickle" else load_onnx)()


@app.get("/salud")
def health() -> dict[str, str]:
    return {"estado": "ok", "backend": BACKEND}


@app.post("/riesgo", response_model=Prediction)
def score(appointment: Appointment) -> Prediction:
    return Prediction(probabilidad_inasistencia=_predict(appointment.vector()),
                      backend=BACKEND)
