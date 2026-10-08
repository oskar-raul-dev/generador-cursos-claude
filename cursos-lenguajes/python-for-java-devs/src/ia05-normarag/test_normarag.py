"""Pruebas de la ingesta y de la verificación de citas. Sin red, sin Postgres, sin modelo.

Las dos piezas que aquí se prueban son las que sostienen la regla del proyecto: sin cita
verificada no hay respuesta. Si estas pruebas pasan, lo que quede mal es del modelo o de
la recuperación, y eso se mide en ia04 y en ia06.
"""

from __future__ import annotations

import pytest

from answer import Citation, verify_citations
from ingest import MIN_USEFUL_CHARS, chunk_text, split_by_clause
from search import Hit

RELLENO = " El presente anexo regula las condiciones aplicables a los servicios pactados."

CONTRATO = (
    "ANEXO TARIFARIO 2026\n"
    "\n"
    f"CLÁUSULA 4.1 Coberturas incluidas\n"
    f"El plan complementario cubre la instalación de aparatología fija.{RELLENO * 2}\n"
    "\n"
    f"CLÁUSULA 4.2 Exclusiones\n"
    f"El retiro de aparatología no está cubierto en el plan complementario.{RELLENO * 2}\n"
)


def chunk(content: str, *, number: int = 1, title: str = "Anexo Andina") -> Hit:
    return Hit(
        chunk_id=number,
        document_title=title,
        clause=f"Cláusula {number}",
        content=content,
        score=0.9,
    )


# --- Troceado -----------------------------------------------------------------


def test_splits_by_clause_and_keeps_the_heading_inside() -> None:
    """El encabezado va DENTRO del contenido: sin él el fragmento no se puede citar."""
    chunks, reason = chunk_text(CONTRATO, document_title="Anexo Andina", document_version="2026")
    assert reason == ""
    assert len(chunks) == 2
    assert chunks[0].clause.startswith("Cláusula 4.1")
    assert "CLÁUSULA 4.1" in chunks[0].content


def test_positions_point_back_to_the_original_text() -> None:
    """start_char/end_char son lo que permite abrir el PDF en el sitio correcto dos años después."""
    chunks, _ = chunk_text(CONTRATO, document_title="Anexo Andina", document_version="2026")
    for piece in chunks:
        assert CONTRATO[piece.start_char : piece.end_char].strip() == piece.content


def test_citation_reads_like_something_patricia_can_send() -> None:
    chunks, _ = chunk_text(CONTRATO, document_title="Anexo Andina", document_version="2026")
    assert chunks[1].citation.startswith("Anexo Andina (v. 2026), Cláusula 4.2")


def test_same_text_gives_the_same_document_id() -> None:
    """Reingerir el mismo documento renombrado no puede duplicar fragmentos."""
    a, _ = chunk_text(CONTRATO, document_title="Anexo Andina", document_version="2026")
    b, _ = chunk_text(CONTRATO, document_title="anexo_andina(1)", document_version="2026")
    assert a[0].document_id == b[0].document_id


def test_scanned_pdf_is_reported_not_swallowed() -> None:
    """pypdf devuelve vacío ante un escaneado y no lanza nada: ese silencio se vuelve señal."""
    chunks, reason = chunk_text("", document_title="Escaneado", document_version="2025")
    assert chunks == []
    assert reason == "sin texto extraíble"


def test_document_without_structure_is_flagged() -> None:
    texto = "Comunicación administrativa sin cláusulas numeradas. " * 10
    chunks, reason = chunk_text(texto, document_title="Circular", document_version="2026")
    assert reason == "sin estructura de cláusulas"
    assert len(chunks) == 1  # el documento entero, y marcado


def test_tiny_fragments_do_not_enter() -> None:
    corto = "CLÁUSULA 1 Objeto\nBreve.\n\nCLÁUSULA 2 Alcance\n" + "x" * MIN_USEFUL_CHARS
    chunks, _ = chunk_text(corto, document_title="Anexo", document_version="2026")
    assert all(len(c.content) >= MIN_USEFUL_CHARS for c in chunks)


def test_split_without_headings_yields_whole_text() -> None:
    assert list(split_by_clause("texto plano")) == [(None, 0, len("texto plano"))]


# --- Verificación de citas ----------------------------------------------------


def test_literal_citation_is_accepted() -> None:
    hits = [chunk("El retiro de aparatología no está cubierto en el plan complementario.")]
    verified, rejected = verify_citations(
        [Citation(chunk_number=1, quote="no está cubierto en el plan complementario")], hits
    )
    assert len(verified) == 1
    assert rejected == []


def test_invented_fragment_number_is_rejected() -> None:
    hits = [chunk("contenido cualquiera del anexo vigente")]
    verified, rejected = verify_citations(
        [Citation(chunk_number=7, quote="cualquier cosa suficientemente larga")], hits
    )
    assert verified == []
    assert "inexistente" in rejected[0]


def test_cross_citation_is_rejected() -> None:
    """El error que a ojo nadie ve: la frase existe, pero en OTRO documento."""
    hits = [
        chunk("Andina cubre la instalación de aparatología fija.", number=1, title="Andina"),
        chunk("Sura no cubre el retiro de aparatología.", number=2, title="Sura"),
    ]
    verified, rejected = verify_citations(
        [Citation(chunk_number=1, quote="no cubre el retiro de aparatología")], hits
    )
    assert verified == []
    assert "no literal" in rejected[0]


def test_typographic_quotes_do_not_break_a_good_citation() -> None:
    """La normalización de ia02 se hereda entera: si no, se descartan citas buenas."""
    hits = [chunk("El plan “complementario” no cubre el retiro de brackets.")]
    verified, _ = verify_citations(
        [Citation(chunk_number=1, quote='El plan "complementario" no cubre el retiro')], hits
    )
    assert len(verified) == 1


@pytest.mark.parametrize("number", [0, -1])
def test_out_of_range_numbers_are_rejected(number: int) -> None:
    hits = [chunk("contenido suficientemente largo para una cita")]
    verified, rejected = verify_citations(
        [Citation(chunk_number=number, quote="contenido suficientemente largo")], hits
    )
    assert verified == []
    assert rejected
