"""Las dos líneas base, escritas antes de entrenar nada.

    from baseline import always_attends, three_variable_rule, roc_auc, precision_recall

Sin línea base no hay medición, hay una cifra suelta. Un AUC de 0,70 no significa nada hasta
que se sabe qué saca la regla que cualquiera escribiría a mano en veinte minutos — y a veces
resulta que saca 0,69.

Aquí hay dos, y las dos importan:

- **`always_attends`**: el piso absoluto. Dice que todos vienen. Acierta el 81% de las veces
  porque el 19% falta, y es inútil: es lo que demuestra que la exactitud no sirve para medir
  esto.
- **`three_variable_rule`**: historial, día y hora. Es lo que Patricia ya hace en la cabeza,
  escrito en ocho líneas y sin una sola dependencia.

🧭 **La regla que ordena el módulo: la línea base se escribe primero y se publica siempre**,
gane o pierda. Publicarla solo cuando pierde es lo que convierte un informe en publicidad.
"""

from __future__ import annotations

from features import PRIOR_CAP

# Los pesos de la regla. No salen de ningún ajuste: son la intuición de Patricia puesta en
# números —el historial manda, el jueves tarde suma, la hora muy temprana también— y se
# dejan visibles para que se puedan discutir en una reunión, que es medio valor de una regla.
WEIGHT_PRIOR = 2.0
WEIGHT_THURSDAY_LATE = 1.0
WEIGHT_EARLY = 0.5
MAX_SCORE = WEIGHT_PRIOR * PRIOR_CAP + WEIGHT_THURSDAY_LATE + WEIGHT_EARLY


def always_attends(rows: list[dict[str, str]]) -> list[float]:
    """El piso: nadie falta nunca. Un solo número para todo el mundo."""
    return [0.0] * len(rows)


def three_variable_rule(rows: list[dict[str, str]]) -> list[float]:
    """Historial, día y hora. Ocho líneas, cero dependencias, cero entrenamiento.

    Devuelve un puntaje entre 0 y 1 —no una decisión— para poder compararla con el modelo
    en las mismas condiciones. Convertir un puntaje en un sí o un no es elegir un umbral, y
    ese es un problema aparte que la sección 6 trata aparte.
    """
    scores = []
    for row in rows:
        risk = WEIGHT_PRIOR * min(int(row["inasistencias_previas"]), PRIOR_CAP)
        if row["dia_semana"] == "3" and row["hora"] >= "16:00":
            risk += WEIGHT_THURSDAY_LATE
        if row["hora"] < "08:00":
            risk += WEIGHT_EARLY
        scores.append(risk / MAX_SCORE)
    return scores


# --- Las métricas, a mano ------------------------------------------------------------
#
# Se escriben aquí en vez de importarlas de scikit-learn por una razón concreta: la línea
# base no puede depender de la biblioteca contra la que compite. Si `baseline.py` importara
# sklearn, la comparación de "cuánto cuesta mantener cada una" sería mentira.

def roc_auc(scores: list[float], target: list[int]) -> float:
    """Área bajo la curva ROC, por el atajo de Mann-Whitney.

    Es la probabilidad de que un caso positivo tomado al azar tenga más puntaje que uno
    negativo. Esa definición es la que hay que llevarse: **el AUC no depende del umbral**, y
    por eso sirve para comparar modelos antes de decidir a quién se llama por teléfono.
    """
    pairs = sorted(zip(scores, target, strict=True))
    positives = sum(target)
    negatives = len(target) - positives
    if not positives or not negatives:
        return float("nan")

    # Rangos con empates promediados: sin esto, una regla con muchos empates —y la de tres
    # variables tiene cuatro puntajes distintos— sale peor de lo que es.
    ranks: list[float] = [0.0] * len(pairs)
    index = 0
    while index < len(pairs):
        end = index
        while end + 1 < len(pairs) and pairs[end + 1][0] == pairs[index][0]:
            end += 1
        average = (index + end) / 2 + 1
        for position in range(index, end + 1):
            ranks[position] = average
        index = end + 1

    rank_sum = sum(rank for rank, (_, label) in zip(ranks, pairs, strict=True) if label)
    return (rank_sum - positives * (positives + 1) / 2) / (positives * negatives)


def precision_recall(scores: list[float], target: list[int],
                     threshold: float) -> tuple[float, float, int]:
    """Precisión, recall y cuántos casos se marcan por encima del umbral.

    El tercer número es el que se olvida y el que decide si esto es operable: marcar al 60%
    de la agenda con un recall precioso no sirve, porque nadie tiene tiempo de llamar a esa
    gente.
    """
    flagged = [index for index, score in enumerate(scores) if score >= threshold]
    if not flagged:
        return float("nan"), 0.0, 0
    hits = sum(target[index] for index in flagged)
    return hits / len(flagged), hits / sum(target), len(flagged)


def threshold_for_capacity(scores: list[float], capacity: float) -> float:
    """El umbral que marca como mucho una fracción `capacity` de las citas.

    Áurea no puede llamar a todo el mundo: Yuli tiene media mañana. Elegir el umbral por
    capacidad y no por una métrica es lo que convierte un modelo en una operación — y es una
    decisión de negocio, otra vez.
    """
    ordered = sorted(scores, reverse=True)
    position = min(int(len(ordered) * capacity), len(ordered) - 1)
    return ordered[position]
