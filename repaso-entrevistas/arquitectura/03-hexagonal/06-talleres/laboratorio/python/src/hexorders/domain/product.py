"""Catálogo: qué se vende y a qué precio. El stock vive en el inventario (otra unidad de
consistencia y, en la parte 3, otra base)."""

from __future__ import annotations

import re
from dataclasses import dataclass

from .money import Money

_SKU = re.compile(r"^SKU-[0-9]{3,}$")


@dataclass(frozen=True, slots=True)
class Product:
    sku: str
    name: str
    unit_price: Money

    def __post_init__(self) -> None:
        if not _SKU.match(self.sku):
            raise ValueError(f"invalid sku: {self.sku!r}")
        if not self.name:
            raise ValueError("empty product name")
