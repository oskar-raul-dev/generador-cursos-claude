"""El engine de SQLAlchemy (Core, sin ORM) y la transacción "actual". Todos los adaptadores de
PostgreSQL pasan por `Db.rows` / `Db.exec`, que usan la conexión transaccional en curso si la hay
(ContextVar) y una conexión con autocommit si no. Así dos adaptadores comparten la misma transacción
sin que el caso de uso les pase una sesión. El ContextVar se usa SOLO para esto, nunca para actor
ni autorización (capítulo 05/05)."""

from __future__ import annotations

from collections.abc import Callable
from contextvars import ContextVar

from sqlalchemy import Connection, Engine, create_engine, text

_current: ContextVar[Connection | None] = ContextVar("hex_tx", default=None)


class Db:
    def __init__(self, url: str) -> None:
        self.engine: Engine = create_engine(url, pool_pre_ping=True)

    def rows(self, sql: str, **params) -> list[dict]:
        conn = _current.get()
        if conn is not None:
            return [dict(r) for r in conn.execute(text(sql), params).mappings()]
        with self.engine.begin() as c:  # una consulta suelta: transacción propia y corta
            return [dict(r) for r in c.execute(text(sql), params).mappings()]

    def one(self, sql: str, **params) -> dict | None:
        found = self.rows(sql, **params)
        return found[0] if found else None

    def exec(self, sql: str, **params) -> int:
        conn = _current.get()
        if conn is not None:
            return conn.execute(text(sql), params).rowcount
        with self.engine.begin() as c:
            return c.execute(text(sql), params).rowcount

    # ---------------------------------------------------------------- UnitOfWork

    def run[T](self, work: Callable[[], T]) -> T:
        """Una transacción; si ya hay una en curso, se reutiliza. Si `work` lanza, se revierte."""
        if _current.get() is not None:
            return work()
        with self.engine.begin() as conn:
            token = _current.set(conn)
            try:
                return work()
            finally:
                _current.reset(token)

    def close(self) -> None:
        self.engine.dispose()
