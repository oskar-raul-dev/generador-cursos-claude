"""El threading.Lock que no sirve: dos procesos, dos candados distintos."""
import sys, threading, psycopg
DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
candado = threading.Lock()   # ← uno por proceso. Ahí está el problema.

def reservar(paciente):
    with candado:            # "protegido"
        with psycopg.connect(DSN) as con, con.cursor() as cur:
            cur.execute("SELECT 1 FROM slots WHERE branch='Suba' AND starts_at='2026-10-15 15:40-05'")
            if cur.fetchone(): return "ocupado"
            import time; time.sleep(0.05)      # la ventana de la carrera
            cur.execute("INSERT INTO slots (branch, starts_at, patient) VALUES ('Suba','2026-10-15 15:40-05', %s)", (paciente,))
            con.commit(); return "reservado"

if __name__ == "__main__":
    print(reservar(sys.argv[1]))
