"""Tres estrategias de recuperación sobre los mismos fragmentos.

Misma firma para las tres. Es lo que permite que la medición de la sección 6 las trate
como intercambiables y que el miniproyecto pueda enrutar entre ellas.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date

from psycopg import Connection
from psycopg.rows import class_row

# `embeddings` se importa DENTRO de `vector_search`, no aquí. Importarlo arriba arrastra
# `sentence_transformers` y con él PyTorch: son segundos de arranque y cientos de megas
# para un proceso que quizá solo va a usar la búsqueda léxica. Es también lo que permite
# probar `fuse_ranks` sin tener el modelo instalado.

# Calibrado en la sección 6 sobre las preguntas anotadas, no elegido a ojo. Por encima
# de esta distancia coseno, los fragmentos dejaron de tener que ver con la pregunta.
DEFAULT_MAX_DISTANCE = 0.35

# Constante de la fusión de rangos recíprocos. 60 es el valor del artículo original y
# funciona bien; se deja explícito para que se pueda variar en un ejercicio.
RRF_K = 60


@dataclass(frozen=True, slots=True)
class Hit:
    """Un fragmento recuperado, con lo necesario para citarlo y para descartarlo."""

    chunk_id: int
    document_title: str
    clause: str | None
    content: str
    score: float  # comparable DENTRO de una estrategia, nunca entre estrategias


def fuse_ranks(rankings: list[list[Hit]], *, k: int, rrf_k: int = RRF_K) -> list[Hit]:
    """Fusión de rangos recíprocos: función pura, y por eso se puede probar sin Postgres.

    Se fusionan las POSICIONES, no los puntajes, y esa es la decisión importante: el
    `ts_rank` de la léxica y la similitud coseno de la vectorial no son comparables ni
    normalizándolos, porque no miden lo mismo. Sumar el inverso de la posición sí tiene
    sentido, y es lo que hace que la fusión funcione sin calibrar pesos.
    """
    fused: dict[int, float] = {}
    by_id: dict[int, Hit] = {}

    for hits in rankings:
        for position, hit in enumerate(hits, start=1):
            fused[hit.chunk_id] = fused.get(hit.chunk_id, 0.0) + 1 / (rrf_k + position)
            by_id[hit.chunk_id] = hit

    ranked = sorted(fused.items(), key=lambda item: (-item[1], item[0]))[:k]
    return [
        Hit(
            chunk_id=chunk_id,
            document_title=by_id[chunk_id].document_title,
            clause=by_id[chunk_id].clause,
            content=by_id[chunk_id].content,
            score=score,
        )
        for chunk_id, score in ranked
    ]


def vector_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
    max_distance: float = DEFAULT_MAX_DISTANCE,
) -> list[Hit]:
    """Búsqueda por similitud, con umbral y con filtros en la MISMA consulta.

    El filtro por aseguradora y vigencia dentro del SQL es la razón por la que esto vive
    en Postgres: con un servicio vectorial aparte serían dos consultas y una intersección
    a mano, y el `LIMIT k` se aplicaría antes de filtrar, que es peor de lo que parece.
    """
    from embeddings import embed_query  # importación diferida; ver la cabecera

    vector = embed_query(question)
    reference = on or date.today()

    with connection.cursor(row_factory=class_row(Hit)) as cursor:
        cursor.execute(
            """
            SELECT id                        AS chunk_id,
                   document_title,
                   clause,
                   content,
                   1 - (embedding <=> %(vector)s::vector) AS score
            FROM document_chunk
            WHERE (%(nit)s::text IS NULL OR insurer_nit = %(nit)s)
              AND (valid_from IS NULL OR valid_from <= %(on)s)
              AND (valid_to   IS NULL OR valid_to   >= %(on)s)
              AND (embedding <=> %(vector)s::vector) <= %(max_distance)s
            ORDER BY embedding <=> %(vector)s::vector
            LIMIT %(k)s
            """,
            {
                "vector": vector,
                "nit": insurer_nit,
                "on": reference,
                "max_distance": max_distance,
                "k": k,
            },
        )
        return cursor.fetchall()


def lexical_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
) -> list[Hit]:
    """Búsqueda de texto completo. El competidor, bien configurado.

    `websearch_to_tsquery` acepta lo que la gente escribe de verdad —comillas, guiones,
    la palabra "or"— en vez de exigir la sintaxis de tsquery. Usar `plainto_tsquery`
    aquí sería debilitar al competidor, y eso invalidaría la medición.
    """
    reference = on or date.today()

    with connection.cursor(row_factory=class_row(Hit)) as cursor:
        cursor.execute(
            """
            SELECT id AS chunk_id,
                   document_title,
                   clause,
                   content,
                   ts_rank(content_tsv, query) AS score
            FROM document_chunk,
                 websearch_to_tsquery('spanish', %(question)s) AS query
            WHERE content_tsv @@ query
              AND (%(nit)s::text IS NULL OR insurer_nit = %(nit)s)
              AND (valid_from IS NULL OR valid_from <= %(on)s)
              AND (valid_to   IS NULL OR valid_to   >= %(on)s)
            ORDER BY score DESC
            LIMIT %(k)s
            """,
            {"question": question, "nit": insurer_nit, "on": reference, "k": k},
        )
        return cursor.fetchall()


def hybrid_search(
    connection: Connection,
    question: str,
    *,
    k: int = 5,
    insurer_nit: str | None = None,
    on: date | None = None,
) -> list[Hit]:
    """Fusión de las dos listas. El trabajo real lo hace `fuse_ranks`."""
    pool = 4 * k  # se pide de más a cada una: la fusión necesita cola para trabajar
    vector_hits = vector_search(
        connection, question, k=pool, insurer_nit=insurer_nit, on=on, max_distance=1.0
    )
    lexical_hits = lexical_search(connection, question, k=pool, insurer_nit=insurer_nit, on=on)
    return fuse_ranks([vector_hits, lexical_hits], k=k)
