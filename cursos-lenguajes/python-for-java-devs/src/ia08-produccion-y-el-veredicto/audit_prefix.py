"""Encuentra el primer byte en que dos peticiones dejan de ser iguales.

Cuando `cache_read_input_tokens` sale cero en peticiones que deberían compartir prefijo,
la pregunta es *dónde* se rompió, y leerlo a ojo sobre veinte mil caracteres de contexto
no funciona. Función pura: se prueba sin red, sin modelo y sin gastar un peso.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True, slots=True)
class Divergence:
    """Dónde y cómo se rompió el prefijo compartido."""

    position: int | None
    before: str
    after: str
    # True cuando uno de los dos prefijos es prefijo del otro. Es el caso BENIGNO —el
    # más corto se cachea entero— y confundirlo con una divergencia manda a alguien a
    # buscar un bug que no existe.
    truncation: bool = False

    @property
    def identical(self) -> bool:
        return self.position is None

    def explain(self) -> str:
        if self.identical:
            return "Los dos prefijos son idénticos: la caché debería acertar."
        if self.truncation:
            return (
                f"Un prefijo es continuación del otro; se separan en el carácter "
                f"{self.position}. El más corto sí se cachea entero: esto no rompe la "
                f"caché, solo la limita."
            )
        return (
            f"Los prefijos divergen en el carácter {self.position}.\n"
            f"  petición A: …{self.before}\n"
            f"  petición B: …{self.after}\n"
            "Todo lo que venga después de ese punto no se cachea."
        )


def render_prefix(request: dict[str, Any]) -> str:
    """Reconstruye el prefijo en el ORDEN EN QUE LO RENDERIZA LA API: tools → system.

    Reconstruirlo en otro orden da una respuesta que se ve razonable y señala al
    culpable equivocado. El orden es parte del contrato y hay que respetarlo aquí.

    ⚠️ No se ordenan las claves al serializar las herramientas, y es deliberado: si la
    petición real produce las claves en distinto orden entre llamadas, eso es justamente
    lo que este auditor tiene que detectar. Normalizar aquí escondería el bug.
    """
    parts: list[str] = []

    for tool in request.get("tools", []):
        parts.append(json.dumps(tool, ensure_ascii=False))

    system = request.get("system", "")
    if isinstance(system, str):
        parts.append(system)
    else:
        parts.extend(block.get("text", "") for block in system)

    return "\n".join(parts)


def first_divergence(a: dict[str, Any], b: dict[str, Any], *, window: int = 40) -> Divergence:
    """Compara los prefijos de dos peticiones y devuelve dónde se separan."""
    left, right = render_prefix(a), render_prefix(b)

    limit = min(len(left), len(right))
    for position in range(limit):
        if left[position] != right[position]:
            start = max(0, position - window // 2)
            return Divergence(
                position=position,
                before=left[start : position + window],
                after=right[start : position + window],
            )

    if len(left) != len(right):
        return Divergence(
            position=limit,
            before=left[limit : limit + window],
            after=right[limit : limit + window],
            truncation=True,
        )

    return Divergence(position=None, before="", after="")
