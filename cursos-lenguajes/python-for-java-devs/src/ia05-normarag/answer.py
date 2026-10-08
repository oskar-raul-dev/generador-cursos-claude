"""Generación de la respuesta y verificación mecánica de sus citas."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import date
from decimal import Decimal

import anthropic
from pydantic import BaseModel, Field

from extract import _normalize  # la normalización de ia02: comillas, espacios, NFC
from pricing import CATALOG
from search import Hit, hybrid_search

logger = logging.getLogger(__name__)

MODEL = "claude-opus-5"

SYSTEM = """Contestas preguntas sobre coberturas de prepagadas para una red odontológica,
usando ÚNICAMENTE los fragmentos de documentos que te paso.

Reglas que no se negocian:
- Cada afirmación va acompañada del número de fragmento que la sostiene y de una frase
  copiada literalmente de ese fragmento.
- Si los fragmentos no contestan la pregunta, dilo. No completes con lo que sabes de
  otras aseguradoras ni con lo que suele ser cierto en el sector.
- Si dos fragmentos se contradicen, dilo y cita los dos. No elijas por tu cuenta.

Contesta en español colombiano, en dos o tres frases. Patricia va a copiar tu respuesta
en un correo a la aseguradora.
"""

NO_RETRIEVAL = (
    "No encontré en los documentos vigentes nada que conteste esto. "
    "Hay que preguntarle directamente a la aseguradora."
)
NO_VERIFIABLE_CITATION = (
    "Encontré documentos relacionados pero no pude respaldar una respuesta "
    "con una cita verificable. Revísalo a mano antes de contestarle a nadie."
)


class Citation(BaseModel):
    """Una afirmación con su respaldo. El contrato de ia02, aplicado a la respuesta."""

    model_config = {"extra": "forbid"}

    chunk_number: int = Field(description="Número del fragmento, tal como se te presentó.")
    quote: str = Field(
        min_length=12, description="Frase EXACTA y contigua copiada de ese fragmento."
    )


class DraftAnswer(BaseModel):
    """Lo que el modelo propone. Todavía no es una respuesta: falta verificarla."""

    model_config = {"extra": "forbid"}

    answer: str
    citations: list[Citation]
    answered: bool = Field(
        description="False si los fragmentos no contestan la pregunta. Si es False, "
        "`citations` va vacía y `answer` explica qué falta."
    )


@dataclass(frozen=True, slots=True)
class Answer:
    """La respuesta verificada, lista para que Patricia la copie en un correo."""

    text: str
    citations: list[str]
    abstained: bool
    cost: Decimal
    retrieved_chunk_ids: list[int]
    rejected_citations: list[str]


def verify_citations(
    citations: list[Citation], hits: list[Hit]
) -> tuple[list[str], list[str]]:
    """Devuelve (verificadas, rechazadas). Función pura: se prueba sin red y sin Postgres.

    Son DOS comprobaciones y hacen falta las dos:

      1. El fragmento citado tiene que ser uno de los que le pasamos. Un número fuera de
         rango significa que el modelo se inventó la referencia.
      2. La frase tiene que aparecer LITERALMENTE en ESE fragmento, no en otro. Verificar
         contra el corpus completo dejaría pasar la cita cruzada —texto del anexo de una
         aseguradora atribuido al contrato de otra—, que es el error que a ojo nadie ve.
    """
    verified: list[str] = []
    rejected: list[str] = []

    for citation in citations:
        if not 1 <= citation.chunk_number <= len(hits):
            rejected.append(f"fragmento {citation.chunk_number} inexistente")
            continue

        hit = hits[citation.chunk_number - 1]
        if _normalize(citation.quote) not in _normalize(hit.content):
            rejected.append(f"cita no literal en el fragmento {citation.chunk_number}")
            continue

        verified.append(f"«{citation.quote}» — {hit.document_title}, {hit.clause or 's. c.'}")

    return verified, rejected


def _render_context(hits: list[Hit], *, on: date) -> str:
    """Numera los fragmentos. El número es el que el modelo va a citar.

    Se numeran por posición en ESTA petición, no por su id de base de datos: un entero
    pequeño es más difícil de confundir para el modelo que un bigserial de seis cifras,
    y la traducción de vuelta la hacemos nosotros.
    """
    blocks = []
    for number, hit in enumerate(hits, start=1):
        blocks.append(
            f"[Fragmento {number}] {hit.document_title} — {hit.clause or 'sin cláusula'}\n"
            f"{hit.content}"
        )
    return f"Fecha de referencia: {on.isoformat()}\n\n" + "\n\n".join(blocks)


def answer_question(
    client: anthropic.Anthropic,
    connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
) -> Answer:
    """Recupera, genera y verifica. Puede abstenerse, y abstenerse es un buen resultado."""
    reference = on or date.today()
    hits = hybrid_search(connection, question, k=k, insurer_nit=insurer_nit, on=reference)

    if not hits:
        # El umbral de ia04 hizo su trabajo. No se llama al modelo: no hay nada que
        # generar, y llamarlo aquí es pagar por una alucinación.
        return Answer(
            text=NO_RETRIEVAL,
            citations=[],
            abstained=True,
            cost=Decimal(0),
            retrieved_chunk_ids=[],
            rejected_citations=[],
        )

    response = client.messages.parse(
        model=MODEL,
        max_tokens=2048,
        system=SYSTEM,
        messages=[
            {
                "role": "user",
                "content": f"{_render_context(hits, on=reference)}\n\nPregunta: {question}",
            }
        ],
        output_format=DraftAnswer,
    )

    pricing = CATALOG[MODEL]
    cost = pricing.cost_of(response.usage.input_tokens, response.usage.output_tokens)
    draft = response.parsed_output
    retrieved = [hit.chunk_id for hit in hits]

    if not draft.answered:
        return Answer(
            text=draft.answer,
            citations=[],
            abstained=True,
            cost=cost,
            retrieved_chunk_ids=retrieved,
            rejected_citations=[],
        )

    verified, rejected = verify_citations(draft.citations, hits)

    if not verified:
        # Había respuesta y ninguna cita sobrevivió. NO se emite: es exactamente el caso
        # que la regla del proyecto existe para atrapar, y es el más peligroso porque el
        # texto se ve bien.
        logger.warning("Respuesta descartada: ninguna cita verificable. %s", rejected)
        return Answer(
            text=NO_VERIFIABLE_CITATION,
            citations=[],
            abstained=True,
            cost=cost,
            retrieved_chunk_ids=retrieved,
            rejected_citations=rejected,
        )

    return Answer(
        text=draft.answer,
        citations=verified,
        abstained=False,
        cost=cost,
        retrieved_chunk_ids=retrieved,
        rejected_citations=rejected,
    )
