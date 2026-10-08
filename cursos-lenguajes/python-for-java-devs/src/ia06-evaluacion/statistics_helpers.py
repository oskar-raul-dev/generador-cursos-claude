"""Acuerdo, kappa e intervalo. Funciones puras: sin red, sin modelo, sin base de datos.

Son las tres piezas que convierten una calificación en algo defendible, y las tres se
escriben en cincuenta líneas. Es también la respuesta a por qué el curso no adopta una
biblioteca de evaluación: no hay nada aquí que valga una dependencia.
"""

from __future__ import annotations

import math
from collections import Counter
from collections.abc import Sequence


def raw_agreement(a: Sequence[str], b: Sequence[str]) -> float:
    """Fracción de casos en que dos jueces coincidieron.

    Fácil de leer y engañoso: si el 90% de las respuestas son buenas, un juez que diga
    siempre "correcta" saca 0.90 y no sirve para nada. Por eso nunca va solo.
    """
    if len(a) != len(b):
        raise ValueError("Las dos series de juicios tienen que tener el mismo largo.")
    if not a:
        return 0.0
    # `strict=True` es redundante con la comprobación de largos de arriba, y se pone
    # igual: si alguien borra esa comprobación, el error sale aquí en vez de dar un
    # acuerdo calculado sobre la serie más corta.
    return sum(1 for x, y in zip(a, b, strict=True) if x == y) / len(a)


def cohen_kappa(a: Sequence[str], b: Sequence[str]) -> float:
    """Acuerdo descontando el que habría salido por azar. El número honesto.

    Interpretación operativa, y conviene tenerla a mano al leer el resultado:
      < 0.40  el juez no sirve para decidir nada
      0.40–0.60  hay señal, pero no se despliega con esto
      0.60–0.80  utilizable con cuidado
      > 0.80  bueno, y sospecha de un conjunto demasiado fácil

    Cuando los dos jueces etiquetan siempre igual —todo "correcta", por ejemplo— el
    acuerdo esperado por azar es 1 y el kappa queda indefinido. Se devuelve 1.0 y se
    declara aquí, que es la convención menos mala: el caso hay que detectarlo mirando
    también el reparto de etiquetas, no el kappa.
    """
    observed = raw_agreement(a, b)

    total = len(a)
    counts_a, counts_b = Counter(a), Counter(b)
    expected = sum(
        (counts_a[label] / total) * (counts_b[label] / total)
        for label in set(counts_a) | set(counts_b)
    )

    if math.isclose(expected, 1.0):
        return 1.0
    return (observed - expected) / (1 - expected)


def wilson_interval(successes: int, trials: int, *, z: float = 1.96) -> tuple[float, float]:
    """Intervalo de confianza del 95% para una proporción, método de Wilson.

    Wilson y no el normal de toda la vida porque con pocas muestras —que es siempre, en
    un conjunto de cincuenta casos— el normal da intervalos que se salen de [0, 1] y
    mienten en los extremos.

    El número que importa es el LÍMITE INFERIOR: con 16 aciertos de 20 el punto es 0.80
    y el intervalo va de 0.58 a 0.92. Celebrar el 0.80 es engañarse.
    """
    if trials <= 0:
        return 0.0, 0.0

    proportion = successes / trials
    denominator = 1 + z**2 / trials
    center = (proportion + z**2 / (2 * trials)) / denominator
    margin = (
        z
        * math.sqrt(proportion * (1 - proportion) / trials + z**2 / (4 * trials**2))
        / denominator
    )
    return max(0.0, center - margin), min(1.0, center + margin)


def required_sample_size(baseline: float, improvement: float, *, z: float = 1.96) -> int:
    """Cuántos casos hacen falta para distinguir `baseline` de `baseline + improvement`.

    Es el número del tag `ia-mini-06` y el que más va a cambiar lo que le prometes a
    Julián sobre "medimos la calidad": si para detectar cinco puntos hacen falta
    trescientos casos y tienes cincuenta, no puedes detectar cinco puntos y punto.

    Aproximación normal, dos proporciones, una cola. Es una estimación de orden de
    magnitud y así hay que leerla; para eso sobra.
    """
    if not 0 < baseline < 1 or improvement <= 0 or baseline + improvement >= 1:
        raise ValueError("Las proporciones tienen que caer dentro de (0, 1).")

    p_avg = baseline + improvement / 2
    variance = 2 * p_avg * (1 - p_avg)
    return math.ceil(variance * (z / improvement) ** 2)
