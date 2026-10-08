"""El cierre nocturno con un fallo inyectado, con punto de control y sin él."""
import hashlib, sqlite3, time
from decimal import Decimal
from pathlib import Path

FUENTE = Path("ventas-2026-Q1.csv")
LOTE = 20_000
FALLO_EN = 0.80


class FalloInyectado(Exception):
    """El fallo de la hora cinco: la base se cae, la red se corta, lo que sea."""


def trabajo(fila):
    """Lo que cuesta procesar una fila del cierre: liquidar su comisión."""
    documento, codigo, valor = fila
    hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
    return Decimal(valor) * Decimal("0.15")


def total_filas():
    with FUENTE.open(encoding="utf-8") as f:
        return sum(1 for _ in f) - 1


N = total_filas()


def sin_checkpoint(fallar):
    """Todo o nada: si falla, se pierde todo y hay que empezar de cero."""
    total = Decimal("0"); hechas = 0
    with FUENTE.open(encoding="utf-8") as f:
        next(f)
        for linea in f:
            if fallar and hechas >= int(N * FALLO_EN):
                raise FalloInyectado(f"cayó tras {hechas:,} filas")
            total += trabajo(tuple(linea.rstrip("\n").split(","))); hechas += 1
    return hechas, total


def con_checkpoint(fallar, db):
    """Reanudable: el punto de control guarda el DESPLAZAMIENTO en bytes.

    Guardar el número de filas obligaría a releer y descartar lo ya hecho, que
    convierte la reanudación en cuadrática. El desplazamiento se busca con seek.
    """
    con = sqlite3.connect(db)
    con.execute("CREATE TABLE IF NOT EXISTS avance ("
                "id INTEGER PRIMARY KEY CHECK (id=1), offset INT, hechas INT, total TEXT)")
    fila = con.execute("SELECT offset, hechas, total FROM avance WHERE id=1").fetchone()
    offset, hechas, total = (fila[0], fila[1], Decimal(fila[2])) if fila else (0, 0, Decimal("0"))

    with FUENTE.open(encoding="utf-8") as f:
        if offset:
            f.seek(offset)
        else:
            next(f)
        while True:
            lote_total = Decimal("0"); lote_hechas = 0
            for linea in f:
                if fallar and hechas + lote_hechas >= int(N * FALLO_EN):
                    con.close()
                    raise FalloInyectado(f"cayó tras {hechas + lote_hechas:,} filas")
                lote_total += trabajo(tuple(linea.rstrip("\n").split(","))); lote_hechas += 1
                if lote_hechas >= LOTE:
                    break
            if lote_hechas == 0:
                break
            # El avance y el resultado, en la MISMA transacción.
            with con:
                con.execute(
                    "INSERT INTO avance (id, offset, hechas, total) VALUES (1,?,?,?) "
                    "ON CONFLICT(id) DO UPDATE SET offset=excluded.offset, "
                    "hechas=excluded.hechas, total=excluded.total",
                    (f.tell(), hechas + lote_hechas, str(total + lote_total)))
            hechas += lote_hechas; total += lote_total
    con.close()
    return hechas, total


print(f"archivo: {N:,} filas · lote: {LOTE:,} · fallo inyectado al {FALLO_EN:.0%}\n")
t0=time.perf_counter(); sin_checkpoint(False); a = time.perf_counter()-t0
db = Path("avance.sqlite3"); db.unlink(missing_ok=True)
t0=time.perf_counter(); con_checkpoint(False, db); b = time.perf_counter()-t0
print(f"{'cierre completo, sin punto de control':<46}{a:7.2f} s")
print(f"{'cierre completo, con punto de control':<46}{b:7.2f} s   (+{(b/a-1)*100:.0f}% de sobrecosto)\n")

print("=== cae en la 'hora cinco' (80% del trabajo hecho) ===")
t0=time.perf_counter()
try: sin_checkpoint(True)
except FalloInyectado as e: pass
h1 = time.perf_counter()-t0
t0=time.perf_counter(); sin_checkpoint(False); r1 = time.perf_counter()-t0
print(f"sin punto de control: se pierde TODO · hasta el fallo {h1:.2f} s + recuperación {r1:.2f} s = {h1+r1:.2f} s")

db.unlink(missing_ok=True)
t0=time.perf_counter()
try: con_checkpoint(True, db)
except FalloInyectado: pass
h2 = time.perf_counter()-t0
con = sqlite3.connect(db); guardadas = con.execute("SELECT hechas FROM avance WHERE id=1").fetchone()[0]; con.close()
t0=time.perf_counter(); hechas,_ = con_checkpoint(False, db); r2 = time.perf_counter()-t0
print(f"con punto de control: se conservan {guardadas:,} de {N:,} · hasta el fallo {h2:.2f} s"
      f" + recuperación {r2:.2f} s = {h2+r2:.2f} s")
print(f"\ntrabajo perdido: sin punto de control {int(N*FALLO_EN):,} filas · con punto de control "
      f"{int(N*FALLO_EN)-guardadas:,} filas")
