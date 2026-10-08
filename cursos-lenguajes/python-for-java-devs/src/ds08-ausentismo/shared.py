"""Lo que esta sección toma prestado de `ds07`, y por qué no se copia.

`ds08` compara una red neuronal contra la línea base de `ds07`, y esa comparación **solo es
válida si las dos usan exactamente las mismas variables, el mismo tope de historial y el
mismo corte temporal**. Copiar `features.py` aquí sería más limpio de leer y garantizaría
que algún día las dos definiciones diverjan sin que nadie se entere — y ese día la tabla de
la sección 6 dejaría de significar algo sin dar ningún error.

Así que se importa, y se hace explícito:

    from shared import HONEST, build_matrix, roc_auc, fit_logistic

Es la única vez en los dos tracks que una sección importa código de otra. La regla general
—cada carpeta de `src/` corre sola— sigue en pie; la excepción se declara aquí, con su
motivo, en vez de esconderse detrás de un `sys.path` sin comentario.
"""

from __future__ import annotations

import sys
from pathlib import Path

DS07 = Path(__file__).resolve().parent.parent / "ds07-scikit-learn"
if str(DS07) not in sys.path:
    sys.path.insert(0, str(DS07))

from baseline import (  # noqa: E402  — el `sys.path` de arriba tiene que ir primero
    precision_recall,
    roc_auc,
    three_variable_rule,
    threshold_for_capacity,
)
from features import (  # noqa: E402
    HONEST,
    LEAKY,
    PRIOR_CAP,
    build_matrix,
    cutoff_of,
    load_rows,
    split_temporal,
)
from model import coefficients, fit_logistic, score_rows  # noqa: E402

__all__ = [
    "HONEST", "LEAKY", "PRIOR_CAP", "build_matrix", "coefficients", "cutoff_of",
    "fit_logistic", "load_rows", "precision_recall", "roc_auc", "score_rows",
    "split_temporal", "three_variable_rule", "threshold_for_capacity",
]
