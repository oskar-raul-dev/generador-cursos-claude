"""Consultar el histórico releyendo los CSV contra tenerlo en sqlite3 con índice."""
import csv, random, sqlite3, statistics, time
from pathlib import Path
import sys
sys.path.insert(0, ".")
from bench import measure, render

HIST = Path("data/historico")
HIST.mkdir(parents=True, exist_ok=True)
rng = random.Random(7)

def build_months(months):
    """Un CSV por sede y mes, como los guarda hoy Patricia."""
    for f in HIST.glob("*.csv"): f.unlink()
    rows_total = 0
    for m in range(months):
        for branch in ("centro","chapinero","suba","kennedy","usaquen",
                       "engativa","fontibon","restrepo","soacha","zipaquira"):
            p = HIST / f"{branch}-2025-{m%12+1:02d}.csv"
            with p.open("a", encoding="utf-8", newline="") as f:
                w = csv.writer(f)
                if p.stat().st_size == 0: w.writerow(["documento","codigo","fecha","valor"])
                for _ in range(600):
                    w.writerow([rng.randint(10_000_000,1_299_999_999),
                                rng.choice(["D8010","D8020","D2740","D7140"]),
                                f"2025-{m%12+1:02d}-{rng.randint(1,28):02d}",
                                rng.choice([75000,95000,180000,890000])])
                    rows_total += 1
    return rows_total

def build_sqlite(db_path):
    if db_path.exists(): db_path.unlink()
    con = sqlite3.connect(db_path)
    con.execute("CREATE TABLE billed (document TEXT, code TEXT, date TEXT, amount INTEGER)")
    for p in sorted(HIST.glob("*.csv")):
        with p.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f); next(reader)
            con.executemany("INSERT INTO billed VALUES (?,?,?,?)", reader)
    con.execute("CREATE INDEX idx_billed ON billed(document, code, date)")
    con.commit()
    return con

def scan_csv(queries):
    found = 0
    wanted = set(queries)
    for p in sorted(HIST.glob("*.csv")):
        with p.open(encoding="utf-8", newline="") as f:
            reader = csv.reader(f); next(reader)
            for r in reader:
                if (r[0], r[1], r[2]) in wanted: found += 1
    return found

def query_sqlite(con, queries):
    found = 0
    for q in queries:
        if con.execute("SELECT 1 FROM billed WHERE document=? AND code=? AND date=? LIMIT 1", q).fetchone():
            found += 1
    return found

for months in (1, 6, 24):
    rows = build_months(months)
    db = Path("data/historico.sqlite3")
    con = build_sqlite(db)
    sample = [tuple(map(str, r)) for r in con.execute(
        "SELECT document, code, date FROM billed ORDER BY RANDOM() LIMIT 50")]
    csv_bytes = sum(p.stat().st_size for p in HIST.glob("*.csv"))
    a = measure("csv", lambda: scan_csv(sample), 3)
    b = measure("sqlite", lambda: query_sqlite(con, sample), 3)
    print(f"{months:>2} meses · {rows:>7,} filas · CSV {csv_bytes/1e6:5.1f} MB · db {db.stat().st_size/1e6:5.1f} MB"
          f" || releer CSV {a['mediana_ms']:8.1f} ms (pico {a['pico_mb']:.1f} MB)"
          f" · sqlite {b['mediana_ms']:7.2f} ms (pico {b['pico_mb']:.2f} MB)")
    con.close()
