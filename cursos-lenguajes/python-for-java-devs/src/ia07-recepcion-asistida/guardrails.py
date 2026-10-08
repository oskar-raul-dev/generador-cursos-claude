"""Las dos barreras que no dependen del modelo.

Esta es la pieza de la que depende que el proyecto sea defendible, y por eso es la más
aburrida del track: léxico, normalización y un criterio asimétrico. Se prueba en
milisegundos, se audita leyéndola, y no se deja convencer por un mensaje que insista.
"""

from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass
from typing import Literal

# ⚠️ Palabras y frases van en DOS colecciones separadas, y no es organización: es
# corrección. La primera versión de este archivo tenía una sola lista escrita como
# `"""duele dolor ... no puedo comer""".split()`, y `.split()` parte las frases: "no",
# "puedo" y "comer" quedaban como términos sueltos, así que **todo mensaje con la
# palabra "no" escalaba** —"no tienen cita el jueves?" incluido— y ninguna frase de
# varias palabras llegaba a coincidir nunca. Ningún tipo lo detecta: las dos son
# `frozenset[str]`.

# Términos que un paciente colombiano usa de verdad cuando algo le pasa. Salen del
# historial de WhatsApp de las sedes, no de un diccionario médico: nadie escribe
# "presento sintomatología dolorosa", escriben "me duele mucho".
SYMPTOM_WORDS = frozenset(
    """
    duele duelen dolor adolorido adolorida molestia punzada punzante
    sangra sangrado sangrando sangre
    hinchado hinchada hinchazon inflamado inflamada inflamacion
    fiebre pus absceso flemon infeccion infectado infectada
    roto rota rompio rompe partido partida partio fracturado quebrado quebro
    despego despegado solto solte soltando
    inflamo hincho desinflamo
    flojo floja alergia alergico ronchas
    """.split()
)

# Frases. Se buscan como subcadena sobre el texto normalizado, y por eso van aparte.
SYMPTOM_PHRASES = frozenset(
    {
        "no puedo comer",
        "no puedo masticar",
        "no puedo abrir",
        "no puedo cerrar",
        "se me solto",
        "se me cayo",
        "se me partio",
        "me esta doliendo",
        "no aguanto",
    }
)

# Frases que piden una opinión clínica aunque no mencionen un síntoma. Van aparte porque
# el motivo del escalamiento es distinto y Yuli lo lee en la bandeja.
ADVICE_PATTERNS = [
    re.compile(pattern)
    for pattern in (
        r"\bes normal\b",
        r"\bqu[e] (me )?(tomo|hago|puedo tomar)\b",
        r"\bpuedo tomar\b",
        r"\bser[a] (que|grave)\b",
        r"\bme preocupa\b",
        r"\bes grave\b",
    )
]

EscalationReason = Literal["sintoma", "consejo", "imagen", "salida", ""]

IMAGE_SUFFIXES = (".jpg", ".jpeg", ".png", ".heic", ".webp")


@dataclass(frozen=True, slots=True)
class Decision:
    """Qué hacer con un mensaje, y por qué. El motivo va a la bandeja de Yuli."""

    escalate: bool
    reason: EscalationReason
    matched: str = ""


def normalize(text: str) -> str:
    """Minúsculas, sin tildes, sin puntuación, espacios colapsados.

    Sin quitar las tildes, "me duele" pasa y "me duelé" —que alguien escribe con el
    teclado del celular— no. Aquí la normalización no es cosmética: es la diferencia
    entre atrapar un síntoma y dejarlo pasar, y por eso es más agresiva que la de ia02.
    Allá el objetivo era comparar citas sin perder precisión; aquí, equivocarse por
    exceso es barato.
    """
    lowered = unicodedata.normalize("NFD", text.casefold())
    stripped = "".join(char for char in lowered if unicodedata.category(char) != "Mn")
    return " ".join(re.sub(r"[^\w\s]", " ", stripped).split())


def mentions_symptom(message: str) -> Decision:
    """Decide si el mensaje trae señal de síntoma o de petición de consejo.

    Deliberadamente sobre-escala. Un "se me soltó un bracket" no siempre es una urgencia
    y va a escalar igual: escalar de más le cuesta a Yuli treinta segundos, escalar de
    menos le cuesta a Áurea un problema de responsabilidad profesional. Con esa
    asimetría, el umbral se pone donde está.
    """
    normalized = normalize(message)

    # Las frases primero: son señales más claras y más específicas que una palabra
    # suelta, y conviene que el motivo que ve Yuli sea el más informativo de los dos.
    for phrase in sorted(SYMPTOM_PHRASES):
        if phrase in normalized:
            return Decision(escalate=True, reason="sintoma", matched=phrase)

    found_words = set(normalized.split()) & SYMPTOM_WORDS
    if found_words:
        return Decision(escalate=True, reason="sintoma", matched=sorted(found_words)[0])

    for pattern in ADVICE_PATTERNS:
        found = pattern.search(normalized)
        if found:
            return Decision(escalate=True, reason="consejo", matched=found.group(0))

    return Decision(escalate=False, reason="")


def has_clinical_image(attachments: list[str]) -> Decision:
    """Cualquier imagen escala, sin mirarla.

    No se clasifica si la foto es de la boca o del comprobante de pago: mirarla ya
    sería procesar una imagen que puede ser historia clínica. Se escala y una persona
    decide. La §5 de la historia de Áurea no admite una versión más cómoda de esto.
    """
    images = [name for name in attachments if name.lower().endswith(IMAGE_SUFFIXES)]
    if images:
        return Decision(escalate=True, reason="imagen", matched=images[0])
    return Decision(escalate=False, reason="")
