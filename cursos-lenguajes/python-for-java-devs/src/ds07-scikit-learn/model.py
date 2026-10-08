"""La regresión logística de cinco variables, en un `Pipeline` de scikit-learn.

    from model import fit_logistic, score_rows

Cincuenta líneas contra las ocho de la regla. Lo que compran esas cuarenta y dos líneas de
más lo dice la sección 6, y no es lo que uno esperaría.

🧭 **Todo lo que aprende del entrenamiento va dentro del `Pipeline`.** Incluida la
normalización. Si la media y la desviación se calculan sobre el conjunto completo antes de
partir, el entrenamiento vio la prueba: es una fuga, es silenciosa, y es la razón de que el
`Pipeline` exista.
"""

from __future__ import annotations

from features import HONEST, build_matrix


def fit_logistic(train_rows: list[dict[str, str]],
                 columns: list[str] | None = None):
    """Entrena y devuelve el pipeline. Determinista: no hay azar que declarar.

    `lbfgs` con `max_iter` explícito porque el valor por defecto se queda corto con cinco
    variables sin escalar y avisa con un `ConvergenceWarning` que todo el mundo ignora. El
    escalado va dentro, así que con él converge de sobra; el `max_iter` se deja alto de
    todos modos para que el día que alguien agregue una variable no se lleve una sorpresa.
    """
    from sklearn.linear_model import LogisticRegression
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    matrix, target = build_matrix(train_rows, columns)
    pipeline = Pipeline([
        ("escala", StandardScaler()),
        ("modelo", LogisticRegression(max_iter=1000, solver="lbfgs")),
    ])
    pipeline.fit(matrix, target)
    return pipeline


def score_rows(pipeline, rows: list[dict[str, str]],
               columns: list[str] | None = None) -> list[float]:
    """Probabilidad de **no** asistir, fila por fila.

    Se devuelve la columna 1 de `predict_proba` y no `predict`: `predict` decide con un
    umbral de 0,5 que nadie eligió y que aquí es malísimo —solo el 19% falta, así que casi
    nada llega a 0,5 y el modelo dice que viene todo el mundo—. El umbral se elige aparte,
    por capacidad, en `baseline.threshold_for_capacity`.
    """
    matrix, _ = build_matrix(rows, columns)
    return [float(probability[1]) for probability in pipeline.predict_proba(matrix)]


def coefficients(pipeline, columns: list[str] | None = None) -> dict[str, float]:
    """Los pesos aprendidos, por variable, sobre datos ya escalados.

    Se publican porque son la mitad del argumento a favor de este modelo: un coeficiente
    negativo grande en `inasistencias_previas` es una frase que Marcela entiende —*"el
    historial es lo que más pesa"*— y una red neuronal no tiene nada equivalente que
    enseñar. La comparabilidad entre coeficientes la da el escalado: sin él, el de
    `distancia_km` y el de `lluvia_mm` estarían en unidades distintas.
    """
    columns = columns or HONEST
    weights = pipeline.named_steps["modelo"].coef_[0]
    return dict(zip(columns, (float(weight) for weight in weights), strict=True))
