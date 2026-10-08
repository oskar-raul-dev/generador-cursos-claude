"""Lo que esta sección toma de `ds07` y `ds08`.

    from shared import build_with_interaction, cutoff_of, load_rows, split_temporal

Misma excepción y mismo motivo que `ds08/shared.py`: el modelo que se sirve tiene que ser
**exactamente** el que `ds08` midió, con sus mismas variables y su misma interacción. Copiar
las definiciones garantizaría que algún día el modelo servido y el modelo medido dejaran de
ser el mismo, sin que nada fallara.
"""

from __future__ import annotations

import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent
for section in ("ds07-scikit-learn", "ds08-ausentismo"):
    path = str(SRC / section)
    if path not in sys.path:
        sys.path.insert(0, path)

from engineered import (  # noqa: E402  — el `sys.path` de arriba tiene que ir primero
    WITH_INTERACTION,
    build_with_interaction,
)
from features import HONEST, build_matrix, cutoff_of, load_rows, split_temporal  # noqa: E402

__all__ = ["HONEST", "WITH_INTERACTION", "build_matrix", "build_with_interaction",
           "cutoff_of", "load_rows", "split_temporal"]
