"""Las tres trampas de SQLite por defecto, y la línea que corrige cada una."""

import sqlite3
import threading
import time

# ------------------------------------------------- 1. los tipos son sugerencias
db = sqlite3.connect(":memory:", autocommit=False)
db.execute("CREATE TABLE abono_flexible (valor INTEGER)")
db.execute("INSERT INTO abono_flexible VALUES ('mil pesos')")
print("INTEGER acepta texto:", db.execute("SELECT valor, typeof(valor) FROM abono_flexible").fetchone())
db.execute("CREATE TABLE abono_estricto (valor INTEGER) STRICT")
try:
    db.execute("INSERT INTO abono_estricto VALUES ('mil pesos')")
except sqlite3.IntegrityError as e:
    print("STRICT lo rechaza:", e)

# ------------------------------------------------- 2. las claves foráneas, apagadas
db.execute("CREATE TABLE sede (codigo TEXT PRIMARY KEY)")
db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
db.commit()                                                            # el DDL también es transaccional
db.execute("INSERT INTO cita VALUES ('CHIA')")                         # no existe esa sede
print("fila huérfana aceptada:", db.execute("SELECT count(*) FROM cita").fetchone()[0])
db.rollback()
db.autocommit = True                                                   # PRAGMA no corre dentro de una transacción
db.execute("PRAGMA foreign_keys = ON")
try:
    db.execute("INSERT INTO cita VALUES ('CHIA')")
except sqlite3.IntegrityError as e:
    print("con foreign_keys = ON:", e)

# ------------------------------------------------- 3. un solo escritor
PATH = "agenda.db"
setup = sqlite3.connect(PATH, autocommit=True)
setup.execute("PRAGMA journal_mode = WAL")
setup.execute("CREATE TABLE IF NOT EXISTS turno (n INTEGER)")
setup.close()


def long_writer():
    w = sqlite3.connect(PATH, autocommit=False)
    w.execute("INSERT INTO turno VALUES (1)")                          # toma el bloqueo de escritura
    time.sleep(1.5)
    w.commit()
    w.close()


threading.Thread(target=long_writer).start()
time.sleep(0.2)
reader = sqlite3.connect(PATH)
print("en WAL, el lector no espera:", reader.execute("SELECT count(*) FROM turno").fetchone()[0], "filas")
second = sqlite3.connect(PATH, timeout=0.5, autocommit=True)
start = time.perf_counter()
try:
    second.execute("INSERT INTO turno VALUES (2)")
except sqlite3.OperationalError as e:
    print(f"segundo escritor: {e} tras {time.perf_counter() - start:.1f} s")
