"""Embeddings locales.

Corre en tu máquina, no cuesta por token y no saca nada a internet. Lo que se paga a
cambio está declarado en la Nota de ecosistema de la sección 4, y es real.
"""

from __future__ import annotations

from collections.abc import Iterable, Iterator
from functools import lru_cache

from sentence_transformers import SentenceTransformer

# Modelo multilingüe pequeño: 384 dimensiones, corre en CPU en un portátil, y entiende
# español razonablemente. La dimensión está escrita en schema.sql: cambiar de modelo
# obliga a reembeber el corpus completo y a migrar la columna.
MODEL_NAME = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
DIMENSIONS = 384

# El lote no es un capricho de rendimiento: embeber de a uno sobre veinte mil fragmentos
# tarda un orden de magnitud más. Se mide en la sección 6.
BATCH_SIZE = 64


@lru_cache(maxsize=1)
def load_model() -> SentenceTransformer:
    """Carga el modelo una vez por proceso. Pesa cientos de megas y tarda en arrancar."""
    return SentenceTransformer(MODEL_NAME)


def embed_texts(texts: Iterable[str]) -> Iterator[list[float]]:
    """Embebe en lotes y devuelve un generador.

    Generador y no lista, por la razón de la Fase 02: el corpus de Áurea no cabe cómodo
    en memoria como matriz de flotantes, y quien consume esto lo va a insertar por lotes.
    """
    model = load_model()
    batch: list[str] = []

    for text in texts:
        batch.append(text)
        if len(batch) == BATCH_SIZE:
            # normalize_embeddings=True deja los vectores de norma 1. Con eso la
            # distancia coseno y el producto punto coinciden, y el operador <=> de
            # pgvector se comporta como esperas. Omitirlo es el error silencioso de
            # esta función: no falla, solo devuelve peores resultados.
            yield from model.encode(batch, normalize_embeddings=True).tolist()
            batch.clear()

    if batch:
        yield from model.encode(batch, normalize_embeddings=True).tolist()


def embed_query(question: str) -> list[float]:
    """Embebe una sola pregunta. Mismo modelo y misma normalización que el corpus.

    Usar un modelo distinto para la consulta y para el corpus es el error que produce
    resultados aleatorios sin lanzar ni un error: los dos vectores viven en espacios
    diferentes y la distancia entre ellos no significa nada.
    """
    return load_model().encode([question], normalize_embeddings=True)[0].tolist()


def assert_matches_schema(column_dimensions: int) -> None:
    """Falla ruidosamente si el modelo y la columna no coinciden.

    Criterio 7 del miniproyecto. Sin esto, cambiar de modelo inserta vectores de otra
    dimensión —o peor, del mismo tamaño y de otro espacio— y la búsqueda devuelve
    resultados aleatorios sin un solo error.
    """
    if column_dimensions != DIMENSIONS:
        raise RuntimeError(
            f"El modelo {MODEL_NAME} produce vectores de {DIMENSIONS} dimensiones y la "
            f"columna espera {column_dimensions}. Hay que migrar la columna y reembeber "
            f"el corpus completo: no existe migración incremental entre espacios distintos."
        )
