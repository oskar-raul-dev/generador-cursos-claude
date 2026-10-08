"""Conexión a Postgres. Una sola forma de conectarse en todo el track.

Reusa la configuración de la Fase 11: la cadena sale del entorno y no hay credenciales
en el código. Aquí solo se agrega el registro de tipos de pgvector, que hace falta para
que un `list[float]` de Python viaje como `vector` sin convertirlo a mano.
"""

from __future__ import annotations

import os
from collections.abc import Iterator
from contextlib import contextmanager

import psycopg
from pgvector.psycopg import register_vector

DSN_ENV = "AUREA_DSN"


@contextmanager
def connect() -> Iterator[psycopg.Connection]:
    """Abre una conexión con los tipos de pgvector registrados."""
    dsn = os.environ.get(DSN_ENV)
    if not dsn:
        raise RuntimeError(
            f"Falta la variable {DSN_ENV} con la cadena de conexión a Postgres. "
            "Es la misma de la Fase 11."
        )

    with psycopg.connect(dsn) as connection:
        register_vector(connection)
        yield connection


def embedding_dimensions(connection: psycopg.Connection) -> int:
    """Dimensión declarada de la columna, para poder compararla con la del modelo.

    Es el criterio 7 del miniproyecto: cambiar de modelo tiene que fallar ruidosamente,
    no insertar vectores de otro espacio en silencio.
    """
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT atttypmod
            FROM pg_attribute
            WHERE attrelid = 'document_chunk'::regclass AND attname = 'embedding'
            """
        )
        row = cursor.fetchone()

    if row is None:
        raise RuntimeError("La tabla document_chunk no tiene columna embedding.")
    return int(row[0])
