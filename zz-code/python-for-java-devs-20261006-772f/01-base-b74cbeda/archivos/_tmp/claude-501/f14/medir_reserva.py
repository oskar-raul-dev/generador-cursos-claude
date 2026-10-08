"""Dos auxiliares reservando las 3:40, con y sin defensa."""
import concurrent.futures as cf
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
INTENTOS = 50

def preparar(con_restriccion: bool):
    with psycopg.connect(DSN, autocommit=True) as con:
        con.execute("DROP TABLE IF EXISTS slots")
        con.execute("""CREATE TABLE slots (
            id serial PRIMARY KEY, branch text NOT NULL, starts_at timestamptz NOT NULL,
            patient text NOT NULL)""")
        if con_restriccion:
            con.execute("CREATE UNIQUE INDEX uq_slot ON slots(branch, starts_at)")

def reservar(paciente: str) -> str:
    """Lo que escribe el instinto: comprobar y después insertar."""
    with psycopg.connect(DSN) as con, con.cursor() as cur:
        cur.execute("SELECT 1 FROM slots WHERE branch='Suba' AND starts_at='2026-10-15 15:40-05'")
        if cur.fetchone():
            return "ocupado"
        try:
            cur.execute("INSERT INTO slots (branch, starts_at, patient) "
                        "VALUES ('Suba','2026-10-15 15:40-05', %s)", (paciente,))
            con.commit()
            return "reservado"
        except psycopg.errors.UniqueViolation:
            con.rollback()
            return "conflicto detectado"

def correr(con_restriccion: bool):
    preparar(con_restriccion)
    with cf.ThreadPoolExecutor(2) as ex:
        res = list(ex.map(reservar, [f"paciente-{i%2}" for i in range(2)]))
    with psycopg.connect(DSN) as con:
        filas = con.execute("SELECT count(*) FROM slots").fetchone()[0]
    return res, filas

print(f"{'escenario':<44}{'resultados':<40}{'filas en la tabla'}")
for etiqueta, restriccion in [("comprobar-y-insertar, SIN restricción", False),
                              ("comprobar-y-insertar, CON restricción", True)]:
    # se repite varias veces porque la carrera no ocurre siempre
    peor = 0; muestra = None
    for _ in range(25):
        res, filas = correr(restriccion)
        if filas > peor: peor, muestra = filas, res
    print(f"{etiqueta:<44}{str(muestra):<40}{peor}")
