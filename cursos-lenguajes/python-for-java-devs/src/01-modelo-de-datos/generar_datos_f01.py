"""Genera los diez exports de marzo de 2026, con la suciedad del mundo real.

Uso:  python generar_datos_f01.py
Produce data/<sede>-2026-03.csv para las diez sedes.
"""

import random
import unicodedata
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = {"D8010": 180000, "D8020": 95000, "D2740": 890000,
         "D7140": 210000, "D1110": 75000, "D8670": 120000}
FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel",
         "Nubia Esther", "Édinson Alberto", "Leidy Johana", "Fabián Ricardo",
         "Martha Liliana", "Héctor Julio", "Claudia Patricia", "Freddy Alexánder",
         "Rocío del Pilar", "Gustavo Adolfo", "Mónica Andrea", "Jairo Enrique",
         "Astrid Carolina", "Néstor Fabio"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez", "Alfonso",
        "Chacón", "Piraquive", "Urrego", "Salamanca", "Bohórquez", "Trujillo",
        "Velandia", "Camargo", "Sáenz", "Pulido", "Lozano", "Forero", "Amaya",
        "Barbosa", "Gaitán", "Rincón", "Támara"]


def strip_accents(text):
    """Quita tildes. Algunas sedes digitan sin ellas y otras no."""
    return "".join(c for c in unicodedata.normalize("NFD", text)
                   if unicodedata.category(c) != "Mn")


def main():
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)

    # 2.800 pacientes reales en la red, cada uno con su documento canónico y su nombre.
    # Los nombres se muestrean SIN repetición del producto completo: así el único homónimo
    # de los datos es el que sembramos abajo a propósito, y la señal no se pierde entre
    # coincidencias de azar. (En los datos reales de Áurea sí hay homónimos de verdad;
    # el ejercicio 🔥 del final te pide qué cambiaría si los hubiera.)
    all_names = [f"{first} {last1} {last2}"
                 for first in FIRST for last1 in LAST for last2 in LAST if last1 != last2]
    people = [(str(random.randint(10_000_000, 1_299_999_999)), name)
              for name in random.sample(all_names, 2800)]

    # 340 de ellos se atienden en una segunda sede: son los duplicados de verdad.
    shared = random.sample(people, 340)

    # Y los dos casos que ninguna normalización resuelve, sembrados a propósito y
    # repartidos en sedes concretas para que no dependan del azar del muestreo.
    # Están aquí porque existen en Áurea, no para hacer el ejercicio más difícil.
    document_a, name_a = people[7]
    document_b, name_b = people[11]
    swapped = document_b[:-2] + document_b[-1] + document_b[-2]   # dígitos cambiados al digitar

    seeded = {
        # Mismo documento, dos personas: alguien digitó mal la cédula al admitir a Gloria.
        "Centro": [(document_a, name_a)],
        "Kennedy": [(document_a, "Gloria Esperanza Mahecha Vargas")],
        # Misma persona, dos documentos: Suba le invirtió dos dígitos.
        "Chapinero": [(document_b, name_b)],
        "Suba": [(swapped, name_b)],
    }

    for branch in BRANCHES:
        rows = []
        for document, name in (random.sample(people, 260) + random.sample(shared, 40)
                               + seeded.get(branch, [])):
            # La suciedad: cada sede digita a su manera.
            if random.random() < 0.15:
                document = f"{document[:-3]}.{document[-3:]}"   # con puntos
            if random.random() < 0.10:
                document = document + " "                        # con espacio al final
            if random.random() < 0.25:
                name = strip_accents(name)                       # sin tildes
            if random.random() < 0.10:
                name = name.upper()                              # en mayúsculas
            for _ in range(random.randint(1, 3)):
                code = random.choice(list(CODES))
                day = random.randint(1, 28)
                rows.append(f"{document},{name},{branch},2026-03-{day:02d},{code},{CODES[code]}")

        path = Path("data") / f"{branch.lower()}-2026-03.csv"
        path.write_text("documento,paciente,sede,fecha,codigo,valor\n" + "\n".join(rows) + "\n",
                        encoding="utf-8")
        print(f"{path}: {len(rows)} filas")


if __name__ == "__main__":
    main()
