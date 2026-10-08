"""El perfil del cierre: dónde se va el tiempo de verdad."""
import cProfile, hashlib, io, pstats, time
from decimal import Decimal
from pathlib import Path
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
FILAS = 20_000     # un lote del cierre

def cargar(n):
    rows=[]
    with open("ventas-2026-Q1.csv", encoding="utf-8") as f:
        next(f)
        for i, l in enumerate(f):
            if i>=n: break
            rows.append(tuple(l.rstrip("\n").split(",")))
    return rows

ROWS = cargar(FILAS)

def cierre_ingenuo(con):
    """Una consulta por fila para saber si el paciente existe. El N+1 del cierre."""
    total = Decimal("0")
    with con.cursor() as cur:
        for documento, codigo, valor in ROWS:
            cur.execute("SELECT 1 FROM patients WHERE document = %s LIMIT 1", (documento,))
            cur.fetchone()
            hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
            total += Decimal(valor) * Decimal("0.15")
    return total

def cierre_con_una_consulta(con):
    """Los documentos conocidos se traen UNA vez y se consultan en memoria."""
    with con.cursor() as cur:
        cur.execute("SELECT document FROM patients")
        conocidos = {r[0] for r in cur.fetchall()}
    total = Decimal("0")
    for documento, codigo, valor in ROWS:
        documento in conocidos
        hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
        total += Decimal(valor) * Decimal("0.15")
    return total

with psycopg.connect(DSN) as con:
    for nombre, fn in [("ingenuo (una consulta por fila)", cierre_ingenuo),
                       ("una sola consulta", cierre_con_una_consulta)]:
        fn(con)
        t0=time.perf_counter(); fn(con); dt=time.perf_counter()-t0
        print(f"{nombre:<38}{dt:7.2f} s para {FILAS:,} filas")

    print("\n=== perfil del ingenuo (cProfile, 20.000 filas) ===")
    pr = cProfile.Profile(); pr.enable(); cierre_ingenuo(con); pr.disable()
    s = io.StringIO(); pstats.Stats(pr, stream=s).sort_stats("cumulative").print_stats(8)
    print("\n".join(s.getvalue().splitlines()[4:16]))

    print("\n=== perfil del optimizado ===")
    pr = cProfile.Profile(); pr.enable(); cierre_con_una_consulta(con); pr.disable()
    s = io.StringIO(); pstats.Stats(pr, stream=s).sort_stats("tottime").print_stats(8)
    print("\n".join(s.getvalue().splitlines()[4:16]))
