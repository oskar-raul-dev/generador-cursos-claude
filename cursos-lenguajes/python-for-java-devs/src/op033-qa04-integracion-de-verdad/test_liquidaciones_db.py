"""Lo que SQLite deja pasar y PostgreSQL no: la prueba tiene que correr contra el motor real."""

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import DataError, IntegrityError

UPSERT = text("""
    INSERT INTO settlements (franchise, quarter, amount) VALUES (:f, :q, :a)
    ON CONFLICT (franchise, quarter) DO UPDATE SET amount = EXCLUDED.amount
    RETURNING id, amount
""")


def test_upsert_keeps_one_row_per_quarter(conn):
    first = conn.execute(UPSERT, {"f": "Suba", "q": "2026T3", "a": "1105200.00"}).one()
    second = conn.execute(UPSERT, {"f": "Suba", "q": "2026T3", "a": "1080000.00"}).one()
    assert first.id == second.id
    assert conn.execute(text("SELECT count(*) FROM settlements")).scalar_one() == 1


def test_postgres_rejects_text_in_numeric(conn):
    with pytest.raises(DataError):
        conn.execute(text("INSERT INTO settlements (franchise, quarter, amount) VALUES ('Suba', 'T', 'mil')"))


def test_negative_amount_violates_the_check(conn):
    with pytest.raises(IntegrityError):
        conn.execute(text("INSERT INTO settlements (franchise, quarter, amount) VALUES ('Suba', 'T', -1)"))


def test_isolation_previous_tests_left_nothing(conn):
    assert conn.execute(text("SELECT count(*) FROM settlements")).scalar_one() == 0


def test_sqlite_would_have_lied():
    """La misma inserción contra SQLite: pasa sin error, y esa es la mentira."""
    sqlite = create_engine("sqlite://")
    with sqlite.begin() as c:
        c.execute(text("CREATE TABLE settlements (franchise text, quarter text, amount numeric(14, 2))"))
        c.execute(text("INSERT INTO settlements VALUES ('Suba', 'T', 'mil')"))
        assert c.execute(text("SELECT amount FROM settlements")).scalar_one() == "mil"
