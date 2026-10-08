"""¿Conviene sobreagendar el jueves a las cuatro, y en qué medida?

    from overbooking import decide, expected_cost, COLLISION_RATIO

La pregunta operativa de la §8 de la historia de Áurea, y la única de todo el track que se
contesta con una esperanza matemática y no con una métrica.

La cuenta es esta. Un cupo tiene un paciente agendado que falta con probabilidad `p`. Si
metemos un segundo paciente en el mismo cupo:

- con probabilidad `p` el primero no viene y el segundo ocupa la silla → **ganamos** una
  consulta que se habría perdido;
- con probabilidad `1 − p` vienen los dos → **dos pacientes en la misma silla**, que es una
  espera de cuarenta minutos, una disculpa y a veces un paciente que no vuelve.

🧭 **La asimetría es el problema entero.** Una silla vacía cuesta el margen de una consulta.
Dos pacientes en la misma silla cuesta eso **y además** la confianza de uno de los dos, que
es lo que Áurea vende. Mientras esa relación no esté escrita en un número, la decisión no es
del modelo: es de Marcela y de Julián.
"""

from __future__ import annotations

# Cuántas veces peor es una colisión que una silla vacía. **No es un parámetro técnico**: es
# una decisión de los dueños, y el 3 de aquí es un valor de partida para poder hacer la
# cuenta, no una medición. El ejercicio 19 pide estimarlo con datos de Áurea.
COLLISION_RATIO = 3.0


def expected_gain(probability: float, ratio: float = COLLISION_RATIO) -> float:
    """Ganancia esperada de sobreagendar un cupo, en unidades de "una consulta".

    `p × 1` por la consulta que se rescata, menos `(1 − p) × ratio` por la colisión. Cuando
    sale negativa, sobreagendar destruye valor aunque el paciente falte a veces.
    """
    return probability - (1 - probability) * ratio


def break_even(ratio: float = COLLISION_RATIO) -> float:
    """La probabilidad a partir de la cual sobreagendar deja de perder plata.

    Con `ratio = 3`, hace falta que el paciente falte **tres de cada cuatro veces**. Ese
    umbral es el resultado más útil de este módulo, y se deduce en una línea de álgebra:
    `p = ratio / (1 + ratio)`.
    """
    return ratio / (1 + ratio)


def decide(probabilities: list[float], ratio: float = COLLISION_RATIO) -> list[bool]:
    """Qué cupos se sobreagendan, uno por uno."""
    threshold = break_even(ratio)
    return [probability > threshold for probability in probabilities]


def expected_cost(probabilities: list[float], decisions: list[bool],
                  ratio: float = COLLISION_RATIO) -> float:
    """Valor esperado total de una agenda, en consultas.

    Cada cupo sin sobreagendar vale `-(p)`: la silla que se pierde si el paciente falta.
    Cada cupo sobreagendado vale su `expected_gain`. Sumado sobre el día, es lo que la
    decisión gana o pierde — y es la cifra que se lleva a la reunión, no el AUC.
    """
    total = 0.0
    for probability, overbook in zip(probabilities, decisions, strict=True):
        total += expected_gain(probability, ratio) if overbook else -probability
    return total


def realised_cost(probabilities: list[float], decisions: list[bool],
                  actual_no_show: list[int], ratio: float = COLLISION_RATIO) -> float:
    """Lo que **de verdad** pasó, con las decisiones tomadas y los resultados observados.

    La diferencia entre esto y `expected_cost` es la prueba de fuego de la calibración: si
    el modelo está bien calibrado, las dos cifras se parecen. Si no, la esperanza matemática
    era una fantasía y la agenda del jueves lo va a notar.
    """
    del probabilities
    total = 0.0
    for overbook, missed in zip(decisions, actual_no_show, strict=True):
        if overbook:
            total += 1.0 if missed else -ratio
        elif missed:
            total -= 1.0
    return total
