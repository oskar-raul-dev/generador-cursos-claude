"""Carga el dominio de Áurea en Postgres para medir."""
import random
from datetime import date, datetime, timedelta, timezone
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
BOGOTA = timezone(timedelta(hours=-5))
BRANCHES = ["Centro","Chapinero","Suba","Kennedy","Usaquen","Engativa","Fontibon","Restrepo","Soacha","Zipaquira"]
PHASES = ["diagnosis","orthodontic","periodontal","restorative","retention"]

DDL = """
DROP TABLE IF EXISTS appointments, plan_phases, treatment_plans, patients, dentists, branches CASCADE;
CREATE TABLE branches (id serial PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE dentists (id serial PRIMARY KEY, name text NOT NULL, branch_id int NOT NULL REFERENCES branches(id));
CREATE TABLE patients (id serial PRIMARY KEY, document text NOT NULL UNIQUE, name text NOT NULL);
CREATE TABLE treatment_plans (
    id serial PRIMARY KEY, patient_id int NOT NULL REFERENCES patients(id),
    opened_on date NOT NULL, total_amount numeric(14,2) NOT NULL);
CREATE TABLE plan_phases (
    id serial PRIMARY KEY, plan_id int NOT NULL REFERENCES treatment_plans(id),
    kind text NOT NULL, branch_id int NOT NULL REFERENCES branches(id),
    dentist_id int REFERENCES dentists(id), status text NOT NULL,
    consent_signed_on date, last_moved_on date NOT NULL);
CREATE TABLE appointments (
    id serial PRIMARY KEY, patient_id int NOT NULL REFERENCES patients(id),
    branch_id int NOT NULL REFERENCES branches(id), starts_at timestamptz NOT NULL,
    minutes int NOT NULL, status text NOT NULL);
CREATE INDEX idx_appt_branch_start ON appointments(branch_id, starts_at);
CREATE INDEX idx_phase_plan ON plan_phases(plan_id);
CREATE INDEX idx_phase_status_moved ON plan_phases(status, last_moved_on);
"""

def main():
    rng = random.Random(2026)
    with psycopg.connect(DSN, autocommit=True) as con:
        con.execute(DDL)
        with con.cursor() as cur:
            cur.executemany("INSERT INTO branches (name) VALUES (%s)", [(b,) for b in BRANCHES])
            cur.executemany("INSERT INTO dentists (name, branch_id) VALUES (%s, %s)",
                            [(f"Dr. {n}", rng.randint(1,10)) for n in range(34)])
            cur.executemany("INSERT INTO patients (document, name) VALUES (%s, %s)",
                            [(str(10_000_000+i*97), f"Paciente {i}") for i in range(2800)])
            # 700 planes integrales, cada uno con sus cinco fases
            plans = [(rng.randint(1,2800), date(2025,1,1)+timedelta(days=rng.randint(0,500)),
                      rng.choice([8_000_000, 12_000_000, 16_000_000, 22_000_000])) for _ in range(700)]
            cur.executemany("INSERT INTO treatment_plans (patient_id, opened_on, total_amount) VALUES (%s,%s,%s)", plans)
            phases=[]
            for plan_id in range(1, 701):
                for kind in PHASES:
                    status = rng.choice(["done","done","in_progress","pending"])
                    phases.append((plan_id, kind, rng.randint(1,10), rng.randint(1,34), status,
                                   date(2025,6,1) if status!="pending" else None,
                                   date(2026,9,12)-timedelta(days=rng.randint(0,200))))
            cur.executemany("""INSERT INTO plan_phases (plan_id,kind,branch_id,dentist_id,status,consent_signed_on,last_moved_on)
                               VALUES (%s,%s,%s,%s,%s,%s,%s)""", phases)
            # 3 meses de citas de toda la red
            appts=[]
            start = datetime(2026,7,1,tzinfo=BOGOTA)
            for day in range(90):
                d = start + timedelta(days=day)
                if d.weekday()==6: continue
                for b in range(1,11):
                    for _ in range(rng.randint(20,40)):
                        h, m = rng.randint(7,18), rng.choice((0,20,40))
                        appts.append((rng.randint(1,2800), b, d.replace(hour=h, minute=m), 20,
                                      rng.choice(["asistio","no_show","reservada"])))
            cur.executemany("INSERT INTO appointments (patient_id,branch_id,starts_at,minutes,status) VALUES (%s,%s,%s,%s,%s)", appts)
        con.execute("ANALYZE")
        for t in ("branches","dentists","patients","treatment_plans","plan_phases","appointments"):
            n = con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
            print(f"{t:18s} {n:>8,}")

if __name__ == "__main__":
    main()
