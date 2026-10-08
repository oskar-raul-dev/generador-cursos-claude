"""Colocación de la caché de prompt, y su verificación.

La colocación es media línea; lo que cuesta es no romperla. Por eso la pieza importante
de esta sección es `audit_prefix.py`: la función que encuentra al invalidador cuando la
caché deja de acertar y nadie sabe por qué.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from decimal import Decimal

import anthropic

from pricing import CATALOG, TOKENS_PER_UNIT

MODEL = "claude-opus-5"

# Multiplicadores de la caché. Escribir cuesta MÁS que una entrada normal y leer cuesta
# una fracción; con tráfico bajo y prefijos que expiran entre peticiones, la caché puede
# salir más cara. Se declaran como constantes porque son precio, y el precio se
# reverifica: ver la fecha de pricing.py.
CACHE_WRITE_MULTIPLIER = Decimal("1.25")
CACHE_READ_MULTIPLIER = Decimal("0.10")

# El contrato del sistema es LO ESTABLE y va delante. No lleva fecha, no lleva
# identificador de sesión y no lleva nada que cambie entre peticiones: todo eso viaja en
# el mensaje del usuario, detrás del punto de corte, donde ya no invalida nada.
STABLE_SYSTEM = """Contestas preguntas sobre coberturas de prepagadas para una red
odontológica, usando únicamente los fragmentos que te paso, y citando la frase exacta
que sostiene cada afirmación.
"""


@dataclass(frozen=True, slots=True)
class CacheStats:
    """Lo que la caché hizo de verdad, que no es lo que crees que hace."""

    created: int
    read: int
    uncached: int
    output: int

    @property
    def hit_ratio(self) -> float:
        total = self.created + self.read + self.uncached
        return self.read / total if total else 0.0

    def effective_cost(self, *, model: str = MODEL) -> Decimal:
        """Costo real de la petición, con los dos multiplicadores aplicados.

        Es la función que permite falsar la hipótesis de la sección 6: si `created` es
        alto y `read` se queda en cero porque el prefijo expira entre consultas, este
        número sale MAYOR que sin caché.
        """
        pricing = CATALOG[model]
        per_input = pricing.input_per_unit / TOKENS_PER_UNIT
        per_output = pricing.output_per_unit / TOKENS_PER_UNIT

        return (
            per_input * Decimal(self.created) * CACHE_WRITE_MULTIPLIER
            + per_input * Decimal(self.read) * CACHE_READ_MULTIPLIER
            + per_input * Decimal(self.uncached)
            + per_output * Decimal(self.output)
        )


def ask_with_cache(
    client: anthropic.Anthropic,
    question: str,
    context: str,
    *,
    on: date | None = None,
) -> tuple[str, CacheStats]:
    """Una petición con el prefijo estable cacheado.

    El orden de renderizado es `tools` → `system` → `messages`, así que el corte se pone
    al final de `system` y todo lo volátil —la fecha, la pregunta— va en el mensaje del
    usuario. Poner la fecha en el sistema es el error ① de la sección 4 y no da error:
    solo deja de cachear.
    """
    response = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        system=[
            {
                "type": "text",
                "text": STABLE_SYSTEM + "\n\n" + context,
                # El punto de corte. Todo lo anterior se cachea; lo que viene después,
                # no. Hay un máximo de cuatro por petición, y con uno bien puesto suele
                # bastar: más puntos de corte no es más caché, es más superficie que
                # romper.
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[
            {
                "role": "user",
                # La fecha va AQUÍ, detrás del corte. Es el mismo dato que en la versión
                # ingenua estaba en el sistema, y la diferencia entre las dos es toda la
                # caché.
                "content": f"Fecha de referencia: {(on or date.today()).isoformat()}\n\n{question}",
            }
        ],
    )

    usage = response.usage
    stats = CacheStats(
        created=usage.cache_creation_input_tokens or 0,
        read=usage.cache_read_input_tokens or 0,
        uncached=usage.input_tokens,
        output=usage.output_tokens,
    )
    return "".join(b.text for b in response.content if b.type == "text"), stats


def ask_without_cache(
    client: anthropic.Anthropic, question: str, context: str, *, on: date | None = None
) -> tuple[str, CacheStats]:
    """La línea base de la medición: la misma petición sin `cache_control`."""
    response = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        system=STABLE_SYSTEM + "\n\n" + context,
        messages=[
            {
                "role": "user",
                "content": f"Fecha de referencia: {(on or date.today()).isoformat()}\n\n{question}",
            }
        ],
    )
    usage = response.usage
    return (
        "".join(b.text for b in response.content if b.type == "text"),
        CacheStats(created=0, read=0, uncached=usage.input_tokens, output=usage.output_tokens),
    )


def ask_with_broken_cache(
    client: anthropic.Anthropic, question: str, context: str, *, on: date | None = None
) -> tuple[str, CacheStats]:
    """La fila 3 de la medición: el error ① medido en vez de descrito.

    La fecha va en el sistema, delante del punto de corte. Cada petición tiene un
    prefijo distinto, así que la caché se escribe y nunca se lee. No falla, no avisa, y
    cuesta más que no ponerla.
    """
    reference = (on or date.today()).isoformat()
    response = client.messages.create(
        model=MODEL,
        max_tokens=2048,
        system=[
            {
                "type": "text",
                "text": f"Hoy es {reference}.\n" + STABLE_SYSTEM + "\n\n" + context,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        messages=[{"role": "user", "content": question}],
    )
    usage = response.usage
    return (
        "".join(b.text for b in response.content if b.type == "text"),
        CacheStats(
            created=usage.cache_creation_input_tokens or 0,
            read=usage.cache_read_input_tokens or 0,
            uncached=usage.input_tokens,
            output=usage.output_tokens,
        ),
    )
