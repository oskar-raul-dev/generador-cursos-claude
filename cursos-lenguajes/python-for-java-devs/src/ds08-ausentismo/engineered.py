"""La sexta columna: el producto de lluvia por distancia.

    from engineered import WITH_INTERACTION, build_with_interaction

Es una línea de ingeniería de variables y es el competidor más incómodo de la red neuronal.
Una regresión logística solo puede sumar efectos; si el mundo tiene un **producto** —llover
importa más cuando vives lejos, que es exactamente lo que le pasa a un paciente de Soacha en
octubre—, el modelo lineal no lo ve y una red sí.

La salida barata es escribirlo a mano. La sección 6 mide si eso alcanza.

🧭 **Esto no es hacer trampa, es el trabajo.** La ingeniería de variables es el sitio donde se
mete el conocimiento del dominio, y el dominio aquí lo tiene Julián: *"cuando llueve, los de
la sabana no vienen"*. Una red descubre esa interacción sola; un humano la escribe en una
línea. Comparar las dos opciones **incluye comparar quién la mantiene**.
"""

from __future__ import annotations

from shared import HONEST, build_matrix

INTERACTION = "lluvia_x_distancia"
WITH_INTERACTION = [*HONEST, INTERACTION]


def build_with_interaction(rows: list[dict[str, str]]) -> tuple[list[list[float]], list[int]]:
    """La matriz de `ds07` más una columna: el producto de las dos variables del dominio.

    Se construye aquí y no se toca `features.py` de `ds07`, porque aquella es la definición
    contra la que se compara: si la línea base cambiara para ganar esta comparación, la
    comparación no diría nada.
    """
    matrix, target = build_matrix(rows)
    rain = HONEST.index("lluvia_mm")
    distance = HONEST.index("distancia_km")
    return ([[*row, row[rain] * row[distance]] for row in matrix], target)


def fit_with_interaction(train_rows: list[dict[str, str]]):
    """La misma logística de `ds07`, con seis columnas en vez de cinco."""
    from sklearn.linear_model import LogisticRegression
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    matrix, target = build_with_interaction(train_rows)
    pipeline = Pipeline([
        ("escala", StandardScaler()),
        ("modelo", LogisticRegression(max_iter=1000, solver="lbfgs")),
    ])
    pipeline.fit(matrix, target)
    return pipeline


def score_with_interaction(pipeline, rows: list[dict[str, str]]) -> list[float]:
    matrix, _ = build_with_interaction(rows)
    return [float(probability[1]) for probability in pipeline.predict_proba(matrix)]
