"""Extracción de reglas de cobertura desde el texto de una circular."""

from __future__ import annotations

import logging
import unicodedata

import anthropic
from pydantic import ValidationError

from coverage import CircularExtraction

logger = logging.getLogger(__name__)

MODEL = "claude-opus-5"

SYSTEM = """Extraes reglas de cobertura de circulares de aseguradoras colombianas para una
red odontológica.

Reglas que no se negocian:
- Cada regla lleva la frase exacta del documento que la sostiene, copiada literalmente.
- Si el documento no afirma algo, se dice que no lo dice. No completes con lo que sería
  razonable ni con lo que suele pasar en otras aseguradoras.
- Un procedimiento mencionado de pasada, sin afirmación de cobertura, no genera una regla.
"""


class ExtractionFailedError(RuntimeError):
    """Ni el primer intento ni las correcciones produjeron algo válido."""


# Las comillas tipográficas, los guiones largos y los apóstrofos curvos NO los unifica
# la normalización Unicode: 'a' y 'a' son caracteres distintos y NFC los deja como están.
# Un PDF de aseguradora los trae todos, y el modelo devuelve la versión recta. Sin esta
# tabla, una cita correcta falla la verificación y descartas una regla buena.
PUNCTUATION_FOLD = str.maketrans(
    {
        "\u201c": '"', "\u201d": '"', "\u201e": '"', "\u00ab": '"', "\u00bb": '"',
        "\u2018": "'", "\u2019": "'", "\u201a": "'",
        "\u2013": "-", "\u2014": "-", "\u2212": "-",
        "\u2026": "...",
    }
)


def _normalize(text: str) -> str:
    """Normaliza para comparar citas: Unicode NFC, puntuación plegada, espacios colapsados.

    Sin esto, una cita correcta falla la verificación porque el modelo devolvió comillas
    rectas donde el PDF tenía tipográficas, o un espacio duro donde había uno normal. Es
    el mismo problema de normalización de la Fase 06, y aquí decide si una regla se
    acepta o se descarta.

    Lo que NO hace, y es deliberado: comparación difusa. La diferencia entre "no cubre" y
    "no cubre salvo" es una palabra, y una similitud del 95% la deja pasar.
    """
    folded = unicodedata.normalize("NFC", text).translate(PUNCTUATION_FOLD)
    return " ".join(folded.split()).casefold()


def extract_rules(
    client: anthropic.Anthropic,
    circular_text: str,
    *,
    max_attempts: int = 3,
) -> CircularExtraction:
    """Extrae las reglas de una circular, negociando con el modelo si no valida.

    El bucle no es manejo de errores: es el diseño. Un fallo de validación se le
    devuelve al modelo como contexto, porque el modelo puede corregirse y un `raise`
    tira a la basura el trabajo ya pagado.
    """
    messages: list[dict[str, object]] = [
        {"role": "user", "content": f"Circular:\n\n{circular_text}"}
    ]
    last_error: ValidationError | None = None

    for attempt in range(1, max_attempts + 1):
        response = client.messages.parse(
            model=MODEL,
            max_tokens=8192,
            system=SYSTEM,
            messages=messages,
            output_format=CircularExtraction,
        )

        try:
            extraction = response.parsed_output
        except ValidationError as error:
            last_error = error
            logger.warning("Intento %d: la salida no validó. Se devuelve el error.", attempt)

            # Lo que se le manda de vuelta es el mensaje de Pydantic, literal y completo.
            # Resumirlo con nuestras palabras es tentador y contraproducente: el modelo
            # corrige mejor con la ruta del campo y el mensaje exacto que con una paráfrasis.
            messages.append({"role": "assistant", "content": response.content})
            messages.append(
                {
                    "role": "user",
                    "content": (
                        "La salida anterior no cumple el contrato. Errores de validación:\n"
                        f"{error}\n\nCorrige solo lo señalado y vuelve a emitir el objeto completo."
                    ),
                }
            )
            continue

        # Validó el tipo. Falta lo que ningún esquema puede verificar: que las citas
        # existan de verdad en el documento. Esta es la comprobación que separa una
        # extracción auditable de una alucinación bien formada.
        haystack = _normalize(circular_text)
        fabricated = [rule for rule in extraction.rules if _normalize(rule.quote) not in haystack]

        if not fabricated:
            return extraction

        logger.warning(
            "Intento %d: %d cita(s) no aparecen en el documento.", attempt, len(fabricated)
        )
        messages.append({"role": "assistant", "content": response.content})
        messages.append(
            {
                "role": "user",
                "content": (
                    "Estas citas no aparecen literalmente en el documento:\n"
                    + "\n".join(f"- {rule.quote!r}" for rule in fabricated)
                    + "\n\nVuelve a emitir el objeto usando solo frases copiadas del texto. "
                    "Si una regla no tiene una frase que la sostenga, elimínala."
                ),
            }
        )

    raise ExtractionFailedError(
        f"No se obtuvo una extracción válida en {max_attempts} intentos."
        + (f" Último error de validación: {last_error}" if last_error else "")
    )
