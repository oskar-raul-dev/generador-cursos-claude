"""Del PDF al fragmento citable.

La regla que ordena este archivo: un fragmento del que no se pueda construir una cita
—documento, versión y cláusula— NO entra al índice. Es preferible un corpus más
pequeño y citable que uno completo y no defendible.
"""

from __future__ import annotations

import hashlib
import logging
import re
from collections.abc import Iterator
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from pypdf import PdfReader

logger = logging.getLogger(__name__)

# Encabezados de cláusula tal como aparecen en los contratos y anexos de las
# aseguradoras colombianas. Se amplía con lo que aparezca: es una expresión regular de
# dominio, no una solución general, y pretender lo contrario sería el error.
CLAUSE_HEADING = re.compile(
    r"^\s*(?:"
    r"(?:CL[ÁA]USULA|ARTÍCULO|ART\.)\s+(?P<number>[\dIVXLC]+[\w.\-]*)"
    r"|(?P<decimal>\d+(?:\.\d+){1,3})\s+(?=[A-ZÁÉÍÓÚÑ])"
    r")\s*(?P<title>.{0,120})$",
    re.MULTILINE,
)

# Un fragmento más corto que esto casi nunca sostiene una respuesta: suele ser un
# encabezado suelto o una línea de tabla. Entra igual al corpus pero se marca, porque
# es material de diagnóstico cuando la recuperación falle.
MIN_USEFUL_CHARS = 120


@dataclass(frozen=True, slots=True)
class Chunk:
    """Un fragmento citable. Todo lo que hace falta para construir la cita va aquí."""

    document_id: str
    document_title: str
    document_version: str
    clause: str | None
    insurer_nit: str | None
    valid_from: date | None
    valid_to: date | None
    content: str
    # Posición en el texto del documento original. Es lo que permite que una queja de
    # dentro de dos años se resuelva abriendo el PDF en la página correcta.
    start_char: int
    end_char: int

    @property
    def citation(self) -> str:
        """La cita, tal como la va a leer Patricia y como la va a mandar a la aseguradora."""
        where = self.clause or f"caracteres {self.start_char}–{self.end_char}"
        return f"{self.document_title} (v. {self.document_version}), {where}"


@dataclass(frozen=True, slots=True)
class IngestReport:
    """Lo que pasó al ingerir. La segunda lista es la que nadie publica y hay que publicar."""

    ingested: list[str]
    without_extractable_text: list[str]
    without_clause_structure: list[str]

    def coverage(self) -> float:
        """Fracción del corpus que el sistema puede consultar de verdad."""
        total = len(self.ingested) + len(self.without_extractable_text)
        return len(self.ingested) / total if total else 0.0


def extract_text(pdf_path: Path) -> str:
    """Extrae el texto de un PDF. Devuelve cadena vacía si es un escaneado.

    `pypdf` no lanza nada ante un PDF de imágenes: devuelve vacío. Ese silencio es el
    que hay que convertir en una señal, y por eso quien llama tiene que mirar el largo.
    """
    reader = PdfReader(pdf_path)
    return "\n".join(page.extract_text() or "" for page in reader.pages).strip()


def split_by_clause(text: str) -> Iterator[tuple[str | None, int, int]]:
    """Trocea por la estructura del documento, no por longitud.

    Devuelve (encabezado, inicio, fin). El encabezado es lo que convierte un párrafo en
    algo citable; sin él, el fragmento no puede entrar al índice. Ver la sección 4.
    """
    matches = list(CLAUSE_HEADING.finditer(text))

    if not matches:
        # Sin estructura reconocible no se inventa una: se devuelve el documento entero
        # y quien llama decide. Trocear a ciegas cada mil caracteres produciría
        # fragmentos no citables, que es justo lo que este archivo no hace.
        yield None, 0, len(text)
        return

    for index, match in enumerate(matches):
        start = match.start()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        number = match.group("number") or match.group("decimal")
        title = (match.group("title") or "").strip()
        heading = f"Cláusula {number}" + (f" — {title}" if title else "")
        yield heading, start, end


def chunk_text(
    text: str,
    *,
    document_title: str,
    document_version: str,
    insurer_nit: str | None = None,
    valid_from: date | None = None,
    valid_to: date | None = None,
) -> tuple[list[Chunk], str]:
    """Trocea un texto ya extraído. Separada de la lectura del PDF para poder probarla."""
    if len(text) < MIN_USEFUL_CHARS:
        # Es un escaneado, o un PDF roto. No entra, y se dice cuál.
        return [], "sin texto extraíble"

    # El identificador sale del contenido, no del nombre del archivo: reingerir el mismo
    # documento renombrado no puede duplicar fragmentos. Es la idempotencia de la Fase 15.
    document_id = hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]

    chunks: list[Chunk] = []
    structured = False

    for heading, start, end in split_by_clause(text):
        structured = structured or heading is not None
        content = text[start:end].strip()
        if len(content) < MIN_USEFUL_CHARS:
            continue

        chunks.append(
            Chunk(
                document_id=document_id,
                document_title=document_title,
                document_version=document_version,
                clause=heading,
                insurer_nit=insurer_nit,
                valid_from=valid_from,
                valid_to=valid_to,
                content=content,
                start_char=start,
                end_char=end,
            )
        )

    return chunks, "" if structured else "sin estructura de cláusulas"


def chunk_document(
    pdf_path: Path,
    *,
    document_title: str,
    document_version: str,
    insurer_nit: str | None,
    valid_from: date | None,
    valid_to: date | None,
) -> tuple[list[Chunk], str]:
    """Convierte un documento en fragmentos. Devuelve también el motivo si no produjo nada."""
    if valid_from is None:
        # Criterio 5 del miniproyecto: un anexo sin vigencia es indistinguible de uno
        # vigente desde siempre, y ese es el agujero por donde entra el derogado.
        raise ValueError(
            f"{pdf_path.name} no trae fecha de vigencia. Sin `valid_from` no se puede "
            "decidir qué versión citar, y el documento no entra al corpus."
        )

    return chunk_text(
        extract_text(pdf_path),
        document_title=document_title,
        document_version=document_version,
        insurer_nit=insurer_nit,
        valid_from=valid_from,
        valid_to=valid_to,
    )
