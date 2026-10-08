"""Calibración: si el modelo dice 0,30, ¿falta el 30%?

    from calibration import brier_score, expected_calibration_error, reliability

El AUC contesta *"¿ordena bien?"* y no contesta *"¿cuánto?"*. Para elegir a quién llama Yuli
alcanza con ordenar. Para **decidir si se sobreagenda el jueves a las cuatro** no alcanza:
ahí hace falta que el 0,30 signifique 30%, porque la cuenta que decide es una esperanza
matemática y una esperanza con probabilidades mal calibradas es un número inventado.

🧭 **Un modelo puede discriminar perfectamente y estar mal calibrado.** Multiplica todas sus
probabilidades por 0,5 y el AUC no se mueve ni un decimal: el orden es el mismo. Por eso
estas tres métricas van al lado del AUC y no en vez de él.
"""

from __future__ import annotations


def brier_score(scores: list[float], target: list[int]) -> float:
    """Error cuadrático medio de la probabilidad. Menos es mejor; 0,25 es decir 0,5 siempre.

    Es la métrica más honesta de las tres porque penaliza a la vez el orden y la magnitud:
    un modelo que ordena bien pero exagera sus probabilidades sale peor aquí y no en el AUC.
    """
    return sum((score - label) ** 2
               for score, label in zip(scores, target, strict=True)) / len(target)


def reliability(scores: list[float], target: list[int],
                bins: int = 10) -> list[tuple[float, float, int]]:
    """Por decil de probabilidad predicha: qué predijo, qué pasó y cuántos casos.

    Es la tabla que hay que mirar antes de usar una probabilidad para decidir plata. Los
    deciles se arman **por cantidad de casos** y no por rango fijo: con el 80% de las
    predicciones por debajo de 0,3, los rangos fijos dejarían siete bloques vacíos.
    """
    ordered = sorted(zip(scores, target, strict=True))
    size = len(ordered) // bins
    rows = []
    for index in range(bins):
        start = index * size
        end = len(ordered) if index == bins - 1 else start + size
        block = ordered[start:end]
        if not block:
            continue
        predicted = sum(score for score, _ in block) / len(block)
        observed = sum(label for _, label in block) / len(block)
        rows.append((predicted, observed, len(block)))
    return rows


def expected_calibration_error(scores: list[float], target: list[int],
                               bins: int = 10) -> float:
    """Diferencia media entre lo predicho y lo observado, pesada por cantidad de casos.

    Un ECE de 0,02 quiere decir que, en promedio, la probabilidad que el modelo anuncia se
    desvía dos puntos de la frecuencia real. Debajo de eso, la esperanza matemática del
    sobreagendamiento se puede calcular sin sonrojarse.
    """
    rows = reliability(scores, target, bins)
    total = sum(count for _, _, count in rows)
    return sum(abs(predicted - observed) * count
               for predicted, observed, count in rows) / total
