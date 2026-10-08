# rescatado de la sesión b74cbeda, 2026-09-13T02:50:15Z · Measure the naive vs single-query plan report
import statistics, time, psycopg
DSN="host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
con = psycopg.connect(DSN)

# La pregunta: ¿qué planes llevan más de 90 días quietos en la fase periodontal?
GOOD = """
SELECT p.id, ph.last_moved_on
FROM treatment_plans p
JOIN plan_phases ph ON ph.plan_id = p.id
WHERE ph.kind = 'periodontal' AND ph.status = 'in_progress'
  AND ph.last_moved_on < current_date - interval '90 days'
ORDER BY ph.last_moved_on
"""
def good():
    with con.cursor() as c:
        c.execute(GOOD); return c.fetchall()

def naive():
    """El modelo obvio: traer los planes y preguntar por cada uno."""
    with con.cursor() as c:
        c.execute("SELECT id FROM treatment_plans")
        plans=[r[0] for r in c.fetchall()]
        out=[]
        for pid in plans:
            c.execute("""SELECT last_moved_on FROM plan_phases
                         WHERE plan_id=%s AND kind='periodontal' AND status='in_progress'
                           AND last_moved_on < current_date - interval '90 days'""", (pid,))
            r=c.fetchone()
            if r: out.append((pid, r[0]))
        return out

def bench(fn, reps=15):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), len(r)

a,na = bench(naive, 5); b,nb = bench(good)
print(f"una consulta por plan (701 consultas): {a:8.1f} ms · {na} planes")
print(f"una sola consulta con JOIN:            {b:8.2f} ms · {nb} planes")
print(f"relación: {a/b:.0f}×")
with con.cursor() as c:
    c.execute("EXPLAIN (ANALYZE, BUFFERS) " + GOOD)
    for row in c.fetchall()[:4]: print("   ", row[0])
