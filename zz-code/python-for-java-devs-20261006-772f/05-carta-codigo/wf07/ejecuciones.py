"""Ejecuciones con clave, arrendamiento y efectos idempotentes, sobre SQLite."""

import os
import sqlite3
import time
from multiprocessing import Process

DB = "ejecuciones.db"
LEASE_SECONDS = 2.0
# La historia de Áurea nombra dos de las seis franquicias; las otras cuatro van sin nombre.
FRANCHISES = ["Suba", "Zipaquirá", "franquicia-3", "franquicia-4", "franquicia-5", "franquicia-6"]


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(DB, timeout=10, isolation_level=None)  # transacciones explícitas
    conn.execute("PRAGMA journal_mode=WAL")
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS runs (
            job TEXT, logical_date TEXT, status TEXT, owner TEXT, lease_until REAL,
            attempts INTEGER DEFAULT 0, PRIMARY KEY (job, logical_date));
        CREATE TABLE IF NOT EXISTS effects (effect_key TEXT PRIMARY KEY, created_by TEXT);
    """)
    return conn


def claim(conn: sqlite3.Connection, job: str, day: str, owner: str) -> bool:
    """Toma la ejecución si está libre, falló o su arrendamiento venció. Atómico."""
    now = time.time()
    conn.execute("BEGIN IMMEDIATE")            # un solo escritor a la vez en SQLite
    try:
        conn.execute("INSERT OR IGNORE INTO runs (job, logical_date, status) VALUES (?, ?, 'pending')",
                     (job, day))
        taken = conn.execute(
            """UPDATE runs SET status = 'running', owner = ?, lease_until = ?, attempts = attempts + 1
               WHERE job = ? AND logical_date = ?
                 AND (status IN ('pending', 'failed') OR (status = 'running' AND lease_until < ?))""",
            (owner, now + LEASE_SECONDS, job, day, now)).rowcount == 1
        conn.execute("COMMIT")
        return taken
    except BaseException:
        conn.execute("ROLLBACK")
        raise


def write_effect(conn: sqlite3.Connection, key: str, owner: str) -> bool:
    """El efecto se escribe una sola vez en la historia, aunque la tarea corra diez."""
    return conn.execute("INSERT OR IGNORE INTO effects VALUES (?, ?)", (key, owner)).rowcount == 1


def settle_quarter(day: str, crash_after: int | None = None) -> None:
    owner = f"pid-{os.getpid()}"
    conn = connect()
    if not claim(conn, "regalias", day, owner):
        print(f"{owner}: la ejecución de {day} la tiene otra copia; salgo")
        return
    for i, franchise in enumerate(FRANCHISES, start=1):
        written = write_effect(conn, f"regalia:{franchise}:{day}", owner)
        # flush: os._exit no vacía el búfer, y sin esto lo que imprimió la copia que se cae se pierde.
        print(f"{owner}: {franchise} {'facturada' if written else 'ya estaba'}", flush=True)
        if crash_after == i:
            print(f"{owner}: se cae a la mitad", flush=True)
            os._exit(1)                         # sin limpiar nada: como un kill -9
        time.sleep(0.1)
    conn.execute("UPDATE runs SET status = 'done' WHERE job = 'regalias' AND logical_date = ?", (day,))


if __name__ == "__main__":
    if os.path.exists(DB):
        os.remove(DB)
    print("== dos copias a la vez")
    copies = [Process(target=settle_quarter, args=("2026T3",)) for _ in range(2)]
    for p in copies:
        p.start()
    for p in copies:
        p.join()

    print("== una copia que se cae, y el reintento después del arrendamiento")
    crashing = Process(target=settle_quarter, args=("2026T4", 3))
    crashing.start()
    crashing.join()
    settle_quarter("2026T4")                    # el arrendamiento sigue vigente: no la toma
    time.sleep(LEASE_SECONDS)
    settle_quarter("2026T4")                    # venció: la toma y completa lo que faltaba

    conn = connect()
    print("== efectos por trimestre:",
          dict(conn.execute("SELECT substr(effect_key, -6), count(*) FROM effects GROUP BY 1")))
    print("== intentos:", conn.execute("SELECT logical_date, status, attempts FROM runs").fetchall())
