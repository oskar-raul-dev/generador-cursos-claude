"""Las variables del modelo de ausentismo, y el corte temporal que las separa.

    from features import load_rows, split_temporal, build_matrix, HONEST, LEAKY

Este módulo no entrena nada. Hace las dos cosas que deciden si un modelo sirve, y que se
hacen mal mucho más seguido que el entrenamiento:

- **Elegir qué columnas entran**, con la distinción entre las que se conocen antes de la
  cita y las que no.
- **Partir el histórico por fecha**, no al azar.

🧭 **La regla que ordena el módulo: una variable solo entra si estaba disponible antes de la
cita.** Es la única definición operativa de "sin fuga" que se puede aplicar columna por
columna, y contestarla obliga a saber **cuándo** se llena cada campo, que es una pregunta de
negocio y no de estadística.
"""

from __future__ import annotations

import csv
import json
from datetime import date
from pathlib import Path

# Las cinco variables honestas: todas se conocen el día que se agenda la cita.
HONEST = ["inasistencias_previas", "jueves_tarde", "lluvia_mm", "distancia_km",
          "dias_desde_agendamiento"]

# ⚠️ La sexta, que **no** se conoce: es el total del histórico del paciente, futuro incluido.
# Entra en el experimento de la sección 5.4 y en ningún otro sitio.
LEAKY = "inasistencias_totales_paciente"

# El historial satura: la tercera inasistencia ya no dice lo que dijo la segunda. El tope no
# es una corrección estadística, es la forma que tiene el fenómeno —y el generador lo sabe—.
PRIOR_CAP = 3


def load_rows(data: Path) -> list[dict[str, str]]:
    with (data / "citas_historicas.csv").open(encoding="utf-8", newline="") as file:
        return list(csv.DictReader(file))


def cutoff_of(data: Path) -> date:
    """El corte temporal sale del manifiesto del conjunto, no de una constante local.

    Así las tres secciones que usan estos datos —`ds07`, `ds08` y `ds09`— parten por la
    misma fecha y sus números se pueden comparar. Una constante repetida en tres archivos
    es una constante que va a divergir.
    """
    manifest = json.loads((data / "manifiesto.json").read_text(encoding="utf-8"))
    return date.fromisoformat(manifest["corte_temporal"])


def split_temporal(rows: list[dict[str, str]],
                   cutoff: date) -> tuple[list[dict], list[dict]]:
    """Antes del corte para entrenar, desde el corte para probar.

    ⚠️ **No es `train_test_split`.** Partir al azar pone citas de diciembre en el
    entrenamiento y de octubre en la prueba, y entonces el modelo predice el pasado con
    información del futuro. La métrica sale mejor y la mentira no se ve: es el error más
    común de todo el aprendizaje automático aplicado a datos con fecha.
    """
    limit = cutoff.isoformat()
    return ([row for row in rows if row["fecha"] < limit],
            [row for row in rows if row["fecha"] >= limit])


def build_matrix(rows: list[dict[str, str]],
                 columns: list[str] | None = None) -> tuple[list[list[float]], list[int]]:
    """Las filas como matriz de números y el objetivo como lista de 0/1.

    El objetivo es **no asistir** —`1` cuando el paciente faltó— y no al revés. Predecir la
    clase rara es lo que hace interpretables la precisión y el recall: con el objetivo
    invertido, un modelo que dice "todos asisten" saca 81% de recall y no sirve para nada.
    """
    columns = columns or HONEST
    matrix = [[_value(row, column) for column in columns] for row in rows]
    target = [1 - int(row["asistio"]) for row in rows]
    return matrix, target


def _value(row: dict[str, str], column: str) -> float:
    if column == "jueves_tarde":
        # El jueves a las cuatro de la tarde: la pregunta operativa de Áurea, convertida en
        # una columna. Se deriva aquí y no en el generador porque es una decisión de
        # modelado —dónde se pone el corte de "tarde"— y tiene que poder discutirse.
        return float(row["dia_semana"] == "3" and row["hora"] >= "16:00")
    if column == "inasistencias_previas":
        return float(min(int(row[column]), PRIOR_CAP))
    return float(row[column])
