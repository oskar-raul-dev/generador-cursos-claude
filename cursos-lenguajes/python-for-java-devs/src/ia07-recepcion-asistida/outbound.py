"""La segunda barrera: lo que el agente está a punto de decir.

El guardrail de entrada atrapa lo que llega. Este atrapa lo que sale, que es donde vive
el riesgo de verdad: una respuesta amable que da una indicación clínica hace daño aunque
el mensaje entrante fuera inocente.
"""

from __future__ import annotations

import re

from guardrails import normalize

# Lo que el agente no puede decir, pase lo que pase. Cada patrón está aquí por una frase
# concreta que alguien escribiría con buena intención.
FORBIDDEN: dict[str, list[re.Pattern[str]]] = {
    "indicación clínica": [
        re.compile(r"\btomate?\b"),
        re.compile(r"\bte recomiendo (que )?(tomes|uses|apliques)\b"),
        re.compile(r"\bpon(te|le)\b.{0,20}\b(hielo|agua|sal)\b"),
        re.compile(r"\benjuagate\b"),
        re.compile(r"\bes normal\b"),
        re.compile(r"\bno es grave\b"),
        re.compile(r"\bespera (al|hasta el)\b"),
    ],
    "promesa de resultado": [
        re.compile(r"\bva a quedar\b"),
        re.compile(r"\bqueda(ra)? perfecto\b"),
        re.compile(r"\bgarantiza(mos|do)\b"),
        re.compile(r"\ble aseguro\b"),
        re.compile(r"\bsin dolor\b"),
        re.compile(r"\bno (te )?va a doler\b"),
    ],
    "compromiso que no puede hacer": [
        re.compile(r"\bcita (confirmada|agendada)\b"),
        re.compile(r"\bya quedo agendad"),
        re.compile(r"\bte la confirmo\b"),
        re.compile(r"\bqueda confirmada\b"),
    ],
}


def check_outbound(reply: str) -> tuple[str, str] | None:
    """Devuelve (categoría, fragmento) si la respuesta no puede salir; None si puede.

    Devuelve el fragmento y no solo la categoría porque Yuli va a leer esto en la
    bandeja y necesita saber qué frase lo disparó. Un guardrail que solo dice
    "bloqueado" se desactiva en dos semanas.

    Los patrones se aplican sobre el texto NORMALIZADO —sin tildes—, así que aquí se
    escriben sin ellas: `\\btomate\\b` y no `\\btómate\\b`. Escribirlos con tilde es el
    error silencioso de este archivo: el patrón compila, no coincide nunca, y el
    guardrail queda abierto sin que nada falle.
    """
    normalized = normalize(reply)

    for category, patterns in FORBIDDEN.items():
        for pattern in patterns:
            found = pattern.search(normalized)
            if found:
                return category, found.group(0)

    return None
