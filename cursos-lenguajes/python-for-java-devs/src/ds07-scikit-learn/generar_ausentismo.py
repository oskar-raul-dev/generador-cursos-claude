"""Genera el histórico de citas de Áurea para el proyecto Ausentismo, con su clima y
sus pacientes seudonimizados.

    python generar_ausentismo.py --salida data --semilla 20260913

Semilla fija, salida reproducible byte a byte, solo biblioteca estándar y **cero datos
clínicos**: una cita es aquí una hora, una sede, un paciente seudónimo y si vino o no.
Ni diagnóstico, ni procedimiento, ni documento. El modelo que `ds07` y `ds08` entrenan
predice asistencia, y para eso no hace falta cruzar la frontera de la §5.

Lo usan `ds07`, `ds08` y `ds09`.

🧠 **El proceso que genera los datos es casi lineal, y eso es una decisión, no un
descuido.** La probabilidad de asistir sale de una combinación lineal de cinco variables
—historial de inasistencia, día, hora, lluvia y distancia— más una única interacción
débil. Esa es la tesis del track: cuando el fenómeno es así, **una regresión logística de
cinco variables le gana a una red neuronal**, y `ds08` tiene que poder llegar a esa
conclusión con la medición delante en vez de con una moraleja. Si el generador escondiera
una estructura no lineal fuerte, la red ganaría y el capítulo diría lo contrario — que
también sería honesto, pero no es lo que Áurea tiene.

⚠️ **`inasistencias_totales_paciente` es una fuga de datos, y está puesta a propósito.**
Se calcula sobre el histórico completo del paciente, futuro incluido. Entrenar con ella
infla cualquier métrica y es el error que más se comete en este dominio; `ds07` la usa
como ejemplo concreto antes de quitarla. La columna que sí se puede usar es
`inasistencias_previas`, que solo mira hacia atrás desde la fecha de la cita.
"""

from __future__ import annotations

import argparse
import json
import math
import random
from datetime import date, timedelta
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]

# Zona de cada sede: el clima llega por zona, no por sede, porque llueve sobre la ciudad
# y no sobre el consultorio.
ZONE_OF = {"Centro": "centro", "Chapinero": "norte", "Usaquen": "norte",
           "Suba": "noroccidente", "Engativa": "noroccidente", "Fontibon": "occidente",
           "Kennedy": "sur", "Restrepo": "sur", "Soacha": "sabana",
           "Zipaquira": "sabana"}
ZONES = sorted(set(ZONE_OF.values()))

# Tipo de cita en registro administrativo. `control` es la cita mensual de ortodoncia y
# es la mayoría del volumen; ninguna de estas etiquetas dice nada de la boca del paciente.
VISIT_TYPES = ["control", "valoracion", "instalacion", "retiro", "rehabilitacion"]
VISIT_WEIGHTS = [68, 12, 6, 4, 10]

START = date(2024, 1, 1)
END = date(2026, 3, 31)

# La frontera temporal que `ds07` usa para partir entrenamiento y prueba. Vive aquí para
# que las tres secciones usen la misma y sus números sean comparables entre capítulos.
CUTOFF = date(2025, 10, 1)

# Los pesos del proceso real. `ds07` no los ve —los descubre—, pero quien escriba el
# capítulo necesita saber cuál es la respuesta correcta para poder decir si el modelo la
# encontró. El intercepto está **calibrado numéricamente** para que la inasistencia global
# quede en el 19% del dominio: se buscó, no se supuso.
INTERCEPT = 3.40
W_PRIOR_NO_SHOWS = -0.40      # la variable que más pesa, y de lejos
W_THURSDAY_LATE = -0.55       # el jueves a las cuatro, que es la pregunta operativa
W_RAIN = -0.024               # por milímetro
W_DISTANCE = -0.045           # por kilómetro
W_LEAD_TIME = -0.011          # por día entre que se agenda y la cita
W_INTERACTION = -0.030        # lluvia × distancia: la única no linealidad, y es débil

# El historial satura: la tercera inasistencia ya no dice nada que la segunda no dijera.
# Sin este tope, el efecto se acumula sobre sí mismo —quien falta tiene más probabilidad
# de faltar, que a su vez sube el conteo— y la red entera termina en 54% de inasistencia,
# que es lo que pasó en la primera versión de este generador. El tope no es un parche de
# calibración: es la forma que tiene el fenómeno, y `ds07` lo va a encontrar en los datos.
PRIOR_NO_SHOW_CAP = 3


def easter_sunday(year: int) -> date:
    """Misma función que en `generar_embudo.py`, y a propósito duplicada.

    Compartirla obligaría a `ds07` a importar un módulo de `src/ds01-…/`, y el curso no
    tiene paquete común: cada sección corre sola. Doce líneas repetidas cuestan menos que
    un `sys.path` remendado en dos capítulos.
    """
    a, b, c = year % 19, year // 100, year % 100
    d, e = b // 4, b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    lunar = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * lunar) // 451
    month = (h + lunar - 7 * m + 114) // 31
    day = ((h + lunar - 7 * m + 114) % 31) + 1
    return date(year, month, day)


def is_holy_week(day: date) -> bool:
    easter = easter_sunday(day.year)
    return easter - timedelta(days=6) <= day <= easter


def each_day(start: date, end: date):
    day = start
    while day <= end:
        yield day
        day += timedelta(days=1)


def build_weather(rng: random.Random) -> dict[tuple[str, date], float]:
    """Lluvia diaria por zona, en milímetros.

    Bogotá tiene dos temporadas de lluvia —abril-mayo y octubre-noviembre— y eso importa
    para el modelo: si la lluvia estuviera repartida uniforme, su efecto se confundiría
    con el del mes y `ds07` no podría separarlos.
    """
    rainy = {4: 2.1, 5: 2.0, 10: 2.3, 11: 2.2, 3: 1.4, 9: 1.3}
    weather = {}
    for day in each_day(START, END):
        intensity = rainy.get(day.month, 0.6)
        for zone in ZONES:
            # La sabana recibe más agua que el centro. Diferencia pequeña y sostenida:
            # suficiente para que la zona no sea intercambiable, no tanto como para que
            # el modelo aprenda la zona en vez de la lluvia.
            local = intensity * (1.25 if zone == "sabana" else 1.0)
            weather[(zone, day)] = (0.0 if rng.random() > local * 0.28
                                    else round(rng.expovariate(1 / (4.5 * local)), 1))
    return weather


def build_patients(rng: random.Random, count: int) -> list[dict]:
    """Pacientes seudonimizados: distancia, zona y mes de tratamiento en que entran.

    `propension_base` es la heterogeneidad que hace realista el histórico —hay gente que
    falta y gente que no—, y **no se escribe a ningún archivo**: es parte del proceso que
    genera los datos, no una columna que el modelo pueda leer. Si se filtrara, cualquier
    modelo la usaría y el ejercicio perdería sentido.
    """
    patients = []
    for number in range(1, count + 1):
        branch = rng.choice(BRANCHES)
        patients.append({
            "paciente_id": f"P{number:06d}",
            "sede": branch,
            "zona": ZONE_OF[branch],
            "distancia_km": round(min(rng.expovariate(1 / 6.5) + 0.8, 34.0), 1),
            "franja_edad": rng.choices(
                ["12-17", "18-29", "30-44", "45-59", "60+"], [34, 27, 22, 13, 4])[0],
            "propension_base": rng.gauss(0, 0.8),
        })
    return patients


def build_appointments(rng: random.Random, patients, weather) -> list[dict]:
    """El histórico de citas, paciente por paciente y en orden cronológico.

    Se recorre por paciente y no por día porque `inasistencias_previas` depende de lo que
    ya pasó: calcularla después, en un segundo recorrido, es exactamente la operación que
    se hace mal cuando alguien mete el futuro en el pasado sin darse cuenta.
    """
    rows = []
    for patient in patients:
        # Cada paciente entra al plan en un mes distinto y asiste a controles mensuales.
        # La entrada se reparte por **todo** el rango, no solo por los primeros meses:
        # Áurea no deja de captar pacientes en 2025, y cortar las altas antes del final
        # adelgaza el tramo de prueba de `ds07` justo donde se mide.
        entry = START + timedelta(days=rng.randint(0, (END - START).days))
        months = rng.randint(4, 26)

        # El abandono de tratamiento: el paciente del mes ocho de veinticuatro que se
        # desaparece con los brackets puestos. Deja de aparecer, no falta para siempre.
        abandons_at = rng.randint(5, 20) if rng.random() < 0.11 else months + 1

        prior_visits = prior_no_shows = 0
        for month in range(1, min(months, abandons_at) + 1):
            # El jitter de la cita puede empujar la primera fuera del rango por abajo:
            # `entry` puede ser el propio 1 de enero y el sorteo restar tres días. Se
            # descarta en vez de recortarse, porque recortar amontona citas en el borde.
            day = entry + timedelta(days=30 * (month - 1) + rng.randint(-3, 3))
            if not START <= day <= END or day.weekday() == 6 or is_holy_week(day):
                continue

            hour = rng.choices(range(7, 19), [4, 7, 9, 10, 9, 6, 5, 8, 10, 11, 9, 6])[0]
            minute = rng.choice((0, 20, 40))
            lead_time = rng.randint(3, 45)
            rain = weather[(patient["zona"], day)]
            thursday_late = int(day.weekday() == 3 and hour >= 16)

            # El proceso real, en una línea de álgebra. Todo lo que el modelo puede
            # aprender está aquí, y nada más: si `ds07` encuentra algo que no está en
            # esta suma, encontró ruido.
            logit = (INTERCEPT
                     + W_PRIOR_NO_SHOWS * min(prior_no_shows, PRIOR_NO_SHOW_CAP)
                     + W_THURSDAY_LATE * thursday_late
                     + W_RAIN * rain
                     + W_DISTANCE * patient["distancia_km"]
                     + W_LEAD_TIME * lead_time
                     + W_INTERACTION * rain * patient["distancia_km"]
                     + patient["propension_base"])
            attended = int(rng.random() < 1 / (1 + math.exp(-logit)))

            rows.append({
                "cita_id": "",                       # se numera al final, en orden global
                "paciente_id": patient["paciente_id"],
                "sede": patient["sede"],
                "zona": patient["zona"],
                "fecha": day.isoformat(),
                "hora": f"{hour:02d}:{minute:02d}",
                "dia_semana": day.weekday(),
                "tipo": rng.choices(VISIT_TYPES, VISIT_WEIGHTS)[0],
                "mes_tratamiento": month,
                "dias_desde_agendamiento": lead_time,
                "distancia_km": patient["distancia_km"],
                "lluvia_mm": rain,
                "franja_edad": patient["franja_edad"],
                "citas_previas": prior_visits,
                "inasistencias_previas": prior_no_shows,
                "asistio": attended,
            })
            prior_visits += 1
            prior_no_shows += 1 - attended

    rows.sort(key=lambda row: (row["fecha"], row["hora"], row["paciente_id"]))
    for number, row in enumerate(rows, start=1):
        row["cita_id"] = f"C{number:07d}"
    return rows


def add_leaking_column(rows: list[dict]) -> None:
    """Agrega `inasistencias_totales_paciente`: el total del histórico, futuro incluido.

    Es la trampa de `ds07`. Se agrega al final, de un solo recorrido, porque así es como
    aparece en la vida real: alguien hace un `GROUP BY paciente` sobre toda la tabla,
    lo pega como columna y no se pregunta desde cuándo se conoce ese número.
    """
    totals: dict[str, int] = {}
    for row in rows:
        totals[row["paciente_id"]] = totals.get(row["paciente_id"], 0) + 1 - row["asistio"]
    for row in rows:
        row["inasistencias_totales_paciente"] = totals[row["paciente_id"]]


def write_csv(path: Path, rows: list[dict], drop: tuple[str, ...] = ()) -> None:
    header = [column for column in rows[0] if column not in drop]
    with path.open("w", encoding="utf-8", newline="\n") as file:
        file.write(",".join(header) + "\n")
        for row in rows:
            file.write(",".join(str(row[column]) for column in header) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera el histórico de ausentismo de Áurea.")
    parser.add_argument("--salida", type=Path, default=Path("data"))
    parser.add_argument("--semilla", type=int, default=20260913)
    # 12.400 pacientes con planes de 4 a 26 meses dejan unas 3.900 citas al mes activas,
    # que es el volumen que la historia de Áurea declara para la red. El número de
    # pacientes es el parámetro; el de citas al mes es la restricción que lo fija.
    parser.add_argument("--pacientes", type=int, default=12_400)
    args = parser.parse_args()

    rng = random.Random(args.semilla)
    args.salida.mkdir(parents=True, exist_ok=True)

    weather = build_weather(rng)
    patients = build_patients(rng, args.pacientes)
    appointments = build_appointments(rng, patients, weather)
    add_leaking_column(appointments)

    write_csv(args.salida / "citas_historicas.csv", appointments)
    write_csv(args.salida / "pacientes.csv", patients, drop=("propension_base",))
    write_csv(args.salida / "clima.csv", [
        {"fecha": day.isoformat(), "zona": zone, "lluvia_mm": rain}
        for (zone, day), rain in sorted(weather.items(), key=lambda item: item[0][::-1])
    ])

    no_shows = sum(1 - row["asistio"] for row in appointments)
    manifest = {
        "semilla": args.semilla,
        "desde": START.isoformat(), "hasta": END.isoformat(),
        "corte_temporal": CUTOFF.isoformat(),
        "filas": {"citas_historicas.csv": len(appointments),
                  "pacientes.csv": len(patients),
                  "clima.csv": len(weather)},
        "tasa_inasistencia": round(no_shows / len(appointments), 4),
        "columna_con_fuga": "inasistencias_totales_paciente",
    }
    (args.salida / "manifiesto.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"{len(appointments):,} citas · {len(patients):,} pacientes · "
          f"inasistencia {no_shows / len(appointments):.1%}")
    print("⚠️  `inasistencias_totales_paciente` tiene fuga temporal. Es a propósito.")


if __name__ == "__main__":
    main()
