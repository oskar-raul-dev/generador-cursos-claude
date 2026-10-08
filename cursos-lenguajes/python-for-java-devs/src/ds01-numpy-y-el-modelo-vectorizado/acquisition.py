"""Costo por paciente adquirido, por canal. La misma cuenta escrita tres veces.

Las tres versiones —bucle, comprehension y vectorizada— tienen que devolver **exactamente
lo mismo**, y hay una prueba que lo comprueba. Esa igualdad es lo que hace legítima la
comparación de la sección 6: si el vectorizado ganara porque calcula otra cosa, no habría
medición, habría trampa.

    from acquisition import read_spend_arrays, cost_per_acquisition_vectorized

La atribución es aquí la más simple posible —**el último toque**, tal cual viene en
`leads.csv`—, y está mal. Está mal a propósito: `ds04` demuestra que la respuesta cambia
según el modelo de atribución, y para demostrarlo necesita que aquí haya una respuesta.
"""

from __future__ import annotations

import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np

# El dinero de Áurea es `Decimal` en todo el curso (guía §6.6), y aquí es `int64` de pesos
# enteros. No es una excepción a la regla: es que la regla es sobre dinero que se cobra, y
# esto es un agregado de gasto publicitario que nadie factura. Un peso arriba o abajo en un
# costo por adquisición de 340.000 no cambia ninguna decisión; en una cuota de ortodoncia,
# sí. La diferencia está en el uso, no en el tipo.
PESOS = np.int64


@dataclass(frozen=True, slots=True)
class SpendArrays:
    """La pauta como columnas, no como filas.

    Es el cambio de modelo mental de la sección: una lista de diccionarios es una lista de
    objetos con sus campos; esto son tres bloques de memoria contigua, cada uno de un solo
    tipo. La fila deja de existir como cosa.
    """

    channel_codes: np.ndarray   # int64, índice dentro de `channels`
    cost: np.ndarray            # int64, pesos
    clicks: np.ndarray          # int64
    channels: list[str]         # el diccionario de códigos, en orden

    def __len__(self) -> int:
        return int(self.channel_codes.size)


def read_spend_rows(path: Path) -> list[dict[str, str]]:
    """La pauta como el lector la leería en la Fase 06: una lista de diccionarios."""
    with path.open(encoding="utf-8", newline="") as file:
        return list(csv.DictReader(file))


def read_spend_arrays(path: Path) -> SpendArrays:
    """La pauta como columnas tipadas.

    Se lee con el `csv` de siempre y se convierte con `np.fromiter`, que asigna el bloque
    una sola vez porque se le dice `count`. La alternativa cómoda, `np.array(lista)`,
    construye antes la lista completa de Python y paga dos veces la memoria: es justo el
    reflejo que esta sección ataca, cometido al cargar los datos.
    """
    return arrays_from_rows(read_spend_rows(path))


def arrays_from_rows(rows: list[dict[str, str]]) -> SpendArrays:
    """Las columnas a partir de filas que ya están en memoria.

    Existe separada de `read_spend_arrays` por la medición: la sección 6 compara las tres
    versiones **sobre las mismas filas**, y volver a leer el CSV para la versión vectorizada
    metería el disco dentro del número.
    """
    channels = sorted({row["canal"] for row in rows})
    index = {channel: code for code, channel in enumerate(channels)}

    return SpendArrays(
        channel_codes=np.fromiter((index[row["canal"]] for row in rows),
                                  dtype=np.int64, count=len(rows)),
        cost=np.fromiter((int(row["costo_cop"]) for row in rows),
                         dtype=PESOS, count=len(rows)),
        clicks=np.fromiter((int(row["clics"]) for row in rows),
                           dtype=np.int64, count=len(rows)),
        channels=channels,
    )


def read_acquisitions(leads_path: Path, stages_path: Path) -> dict[str, int]:
    """Pacientes adquiridos por canal, por atribución al último toque.

    Un lead cuenta como adquirido cuando llegó a `plan_aceptado`. Se lee con la biblioteca
    estándar porque son dos recorridos y un conjunto: meter NumPy aquí no ganaría nada y
    enseñaría lo contrario de lo que enseña la sección — vectorizar lo que no es aritmética
    sobre bloques es ceremonia.
    """
    with stages_path.open(encoding="utf-8", newline="") as file:
        accepted = {row["lead_id"] for row in csv.DictReader(file)
                    if row["etapa"] == "plan_aceptado"}

    counts: dict[str, int] = {}
    with leads_path.open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            if row["lead_id"] in accepted:
                channel = row["canal_ultimo_toque"]
                counts[channel] = counts.get(channel, 0) + 1
    return counts


# --- Las tres versiones de la misma cuenta ----------------------------------------

def cost_per_acquisition_loop(rows: list[dict[str, str]],
                              acquisitions: dict[str, int]) -> dict[str, float]:
    """El reflejo: un bucle correcto, legible, y el que cualquiera aprobaría en revisión.

    No es código malo. En Java, con el JIT detrás, esta es la versión que se escribe y la
    que gana. Aquí es la línea base contra la que se mide, y hasta cierto tamaño **también
    es la respuesta correcta**: la sección 6 dice cuál es ese tamaño.
    """
    total: dict[str, int] = {}
    for row in rows:
        channel = row["canal"]
        total[channel] = total.get(channel, 0) + int(row["costo_cop"])
    return {channel: spent / acquisitions[channel]
            for channel, spent in total.items() if acquisitions.get(channel)}


def cost_per_acquisition_comprehension(rows: list[dict[str, str]],
                                       acquisitions: dict[str, int]) -> dict[str, float]:
    """La versión "pythónica" que este perfil escribe en cuanto le dicen que el bucle es lento.

    Recorre la lista una vez por canal, así que hace seis pasadas donde el bucle hacía una.
    Es más corta y es **peor**, y está aquí porque la sección 6 la mide: "más pythónico" no
    es una unidad de medida.
    """
    return {
        channel: sum(int(row["costo_cop"]) for row in rows if row["canal"] == channel)
                 / acquisitions[channel]
        for channel in {row["canal"] for row in rows}
        if acquisitions.get(channel)
    }


def cost_per_acquisition_vectorized(spend: SpendArrays,
                                    acquisitions: dict[str, int]) -> dict[str, float]:
    """La suma por canal en una sola llamada, sin bucle de Python.

    `bincount` con pesos es exactamente "suma agrupada por código entero", que es el 80% de
    lo que uno quiere de un `GROUP BY` cuando las claves ya son enteros pequeños. Recorre el
    bloque una vez, en C, sin crear un objeto de Python por fila.
    """
    # `minlength` evita que el resultado se acorte si el último canal no aparece en el
    # recorte de datos: sin él, el vector devuelto cambia de tamaño según los datos y el
    # `zip` de abajo se desalinea en silencio. Es un error que no levanta excepción.
    totals = np.bincount(spend.channel_codes,
                         weights=spend.cost.astype(np.float64),
                         minlength=len(spend.channels))
    return {channel: float(total) / acquisitions[channel]
            for channel, total in zip(spend.channels, totals, strict=True)
            if acquisitions.get(channel)}


# --- El experimento que rompe a propósito -----------------------------------------

def total_spend_with_dtype(spend: SpendArrays, dtype: type) -> int:
    """Suma el gasto acumulándolo en el tipo que se le pida.

    Existe para el 🧨 de la sección: con `np.int32` el resultado es **incorrecto y
    silencioso** a partir de unos pocos miles de filas, porque un `int` de NumPy es un
    entero de máquina y desborda como el `int` de Java, no como el de Python.
    """
    return int(np.sum(spend.cost.astype(dtype), dtype=dtype))
