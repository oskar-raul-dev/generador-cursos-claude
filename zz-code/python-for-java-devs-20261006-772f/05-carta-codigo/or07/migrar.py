"""Aplicar, revertir y volver a aplicar con yoyo, y lo que pasa al editar una migración ya aplicada."""

import pathlib
import sqlite3

from yoyo import get_backend, read_migrations

backend = get_backend("sqlite:///aurea.db")


def status(label: str):
    migrations = read_migrations("migraciones")
    applied = [m.id for m in migrations if backend.is_applied(m)]
    tables = [r[0] for r in sqlite3.connect("aurea.db").execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '\\_yoyo%' ESCAPE '\\' "
        "AND name NOT LIKE 'yoyo%' ORDER BY name")]
    print(f"{label:<28} aplicadas: {applied} · tablas: {tables}")


with backend.lock():
    backend.apply_migrations(backend.to_apply(read_migrations("migraciones")))
status("después de aplicar")

with backend.lock():
    backend.rollback_one(next(m for m in read_migrations("migraciones") if m.id == "0002_fases"))
status("después de revertir 0002")

with backend.lock():
    backend.apply_migrations(backend.to_apply(read_migrations("migraciones")))
status("después de reaplicar")

# Alguien "corrige" una migración ya aplicada en vez de escribir una nueva.
first = pathlib.Path("migraciones/0001_planes.sql")
first.write_text(first.read_text().replace("sede TEXT NOT NULL", "sede TEXT NOT NULL, activo INTEGER"))
pending = backend.to_apply(read_migrations("migraciones"))
print("pendientes tras editar 0001:", [m.id for m in pending], "· ¿tiene la columna activo?",
      "activo" in [c[1] for c in sqlite3.connect("aurea.db").execute("PRAGMA table_info(plan)")])
