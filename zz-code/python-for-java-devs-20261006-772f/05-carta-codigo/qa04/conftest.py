"""Un PostgreSQL de verdad por sesión, el esquema de producción, y una transacción por prueba."""

from pathlib import Path

import pytest
from sqlalchemy import create_engine, text
from testcontainers.community.postgres import PostgresContainer


@pytest.fixture(scope="session")
def engine():
    with PostgresContainer("postgres:18.6", driver="psycopg") as postgres:
        engine = create_engine(postgres.get_connection_url())
        with engine.begin() as conn:
            conn.execute(text(Path("esquema.sql").read_text()))   # las migraciones, una vez
        yield engine
        engine.dispose()


@pytest.fixture
def conn(engine):
    """Cada prueba corre dentro de una transacción que se deshace: no ve ni deja datos de otras."""
    with engine.connect() as connection:
        transaction = connection.begin()
        yield connection
        transaction.rollback()
