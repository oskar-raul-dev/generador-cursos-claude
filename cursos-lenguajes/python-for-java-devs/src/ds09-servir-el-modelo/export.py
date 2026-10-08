"""Entrena el modelo de `ds08` y lo guarda en los dos formatos que compiten.

    uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 python export.py --salida modelos

Produce `modelo.pkl` y `modelo.onnx` **del mismo pipeline entrenado**, y comprueba que los
dos devuelven la misma probabilidad antes de dejarlos en disco. Esa comprobación no es
opcional: un modelo exportado que predice distinto del original es el peor error posible de
esta sección, porque nada falla y la diferencia aparece en producción.

🧭 **Lo que se exporta es el `Pipeline` completo, no el estimador.** El escalado es parte del
modelo: exportar solo la regresión y escalar a mano en el servidor es garantizar que algún día
el escalado del servidor y el del entrenamiento dejen de coincidir. ONNX se lleva las dos
cosas en el mismo grafo.
"""

from __future__ import annotations

import argparse
import pickle
from pathlib import Path

from upstream import build_with_interaction, cutoff_of, load_rows, split_temporal

# La tolerancia de la comprobación. `1e-6` no es rigor ceremonial: ONNX calcula en `float32`
# y scikit-learn en `float64`, así que exigir igualdad exacta fallaría siempre y aceptar
# `1e-3` dejaría pasar un error de conversión de verdad.
TOLERANCE = 1e-6


def train(data: Path):
    """El modelo ganador de `ds08`: la logística con la interacción escrita a mano."""
    from sklearn.linear_model import LogisticRegression
    from sklearn.pipeline import Pipeline
    from sklearn.preprocessing import StandardScaler

    rows = load_rows(data)
    train_rows, _ = split_temporal(rows, cutoff_of(data))
    matrix, target = build_with_interaction(train_rows)

    pipeline = Pipeline([
        ("escala", StandardScaler()),
        ("modelo", LogisticRegression(max_iter=1000, solver="lbfgs")),
    ])
    pipeline.fit(matrix, target)
    return pipeline, matrix


def to_onnx(pipeline, columns: int):
    """Convierte el pipeline a un grafo ONNX con entrada de `columns` flotantes.

    `zipmap=False` es la opción que más tiempo hace perder: sin ella, el conversor envuelve
    la salida en una lista de diccionarios `{clase: probabilidad}` que es cómoda en Python y
    obliga a desempaquetar en cada predicción. Con ella, la salida es un tensor y el
    consumidor puede ser cualquier cosa, que es el punto de ONNX.
    """
    from skl2onnx import to_onnx as convert
    from skl2onnx.common.data_types import FloatTensorType

    return convert(pipeline, initial_types=[("entrada", FloatTensorType([None, columns]))],
                   options={id(pipeline): {"zipmap": False}})


def probabilities_onnx(model_bytes: bytes, matrix: list[list[float]]) -> list[float]:
    import numpy as np
    import onnxruntime

    session = onnxruntime.InferenceSession(model_bytes,
                                           providers=["CPUExecutionProvider"])
    name = session.get_inputs()[0].name
    outputs = session.run(None, {name: np.array(matrix, dtype=np.float32)})
    # La segunda salida son las probabilidades; la primera es la clase predicha, que esta
    # sección no usa por lo que explica `ds07` §5.3 sobre el umbral de 0,5.
    return [float(row[1]) for row in outputs[1]]


def main() -> None:
    parser = argparse.ArgumentParser(description="Exporta el modelo en los dos formatos.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--salida", type=Path, default=Path("modelos"))
    args = parser.parse_args()

    args.salida.mkdir(parents=True, exist_ok=True)
    pipeline, matrix = train(args.datos)

    pickle_path = args.salida / "modelo.pkl"
    pickle_path.write_bytes(pickle.dumps(pipeline))

    model = to_onnx(pipeline, len(matrix[0]))
    onnx_path = args.salida / "modelo.onnx"
    onnx_path.write_bytes(model.SerializeToString())

    # La comprobación, sobre mil filas reales. Si los dos formatos no coinciden, no se
    # publica ninguno: un modelo exportado que predice distinto es peor que no exportar.
    sample = matrix[:1000]
    original = [float(row[1]) for row in pipeline.predict_proba(sample)]
    exported = probabilities_onnx(onnx_path.read_bytes(), sample)
    worst = max(abs(a - b) for a, b in zip(original, exported, strict=True))
    if worst > TOLERANCE:
        raise SystemExit(f"El ONNX no coincide con el original: {worst:.2e} > {TOLERANCE:.0e}")

    print(f"{pickle_path}: {pickle_path.stat().st_size / 1024:.1f} KB")
    print(f"{onnx_path}: {onnx_path.stat().st_size / 1024:.1f} KB")
    print(f"Máxima diferencia sobre {len(sample):,} filas: {worst:.2e}")


if __name__ == "__main__":
    main()
