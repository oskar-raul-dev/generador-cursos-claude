"""Las treinta solicitudes de reagendación, como las escribe un paciente por WhatsApp.

    uv run python generar_solicitudes.py

Con faltas, sin fecha explícita, con "el jueves" y "por la tarde". Eso no es color: es
la dificultad de la medición de la sección 6. Una solicitud bien redactada no prueba
nada porque no se parece a lo que llega.

Seudonimizadas: los pacientes son números, no nombres, y no hay un solo dato clínico.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# Cada solicitud trae la dificultad que aporta, para poder leer los resultados de la
# medición por clase en vez de en agregado.
SOLICITUDES: list[tuple[str, str]] = [
    ("fecha relativa", "Buenas, necesito cambiar mi control del jueves"),
    ("fecha relativa", "hola, me puedes correr la cita de mañana para la otra semana?"),
    ("otra sede", "Buenas tardes, me mudé a Suba, puedo hacer el control allá?"),
    ("otra sede", "Hay cupo en Kennedy? me queda mas cerca del trabajo"),
    ("franja vaga", "necesito una cita por la tarde, la que sea"),
    ("franja vaga", "Buenas! tienen algo temprano el viernes?"),
    ("sin datos", "Buenas necesito cita"),
    ("sin datos", "hola"),
    ("precio", "cuanto me sale ponerme una carilla?"),
    ("precio", "Buenas, cuanto cuesta el control mensual en el centro?"),
    ("sede sin agenda", "Buenas, atienden en Zipaquirá? necesito control"),
    ("sede sin agenda", "puedo ir a la sede de Zipa el sábado?"),
    ("cancelar", "no voy a poder ir mañana, toca cancelar"),
    ("cancelar", "Buenas disculpe, puedo cancelar la del martes?"),
    ("urgencia", "se me soltó un bracket, puedo ir hoy?"),
    ("urgencia", "Buenas tardes, se me partió el retenedor"),
    ("dos peticiones", "Buenas, quiero cambiar la cita del jueves y saber cuanto debo"),
    ("dos peticiones", "me pasan la cita a Suba y me dicen el precio de la limpieza?"),
    ("tercero", "Buenas, escribo por mi hija, necesita el control"),
    ("tercero", "es para mi esposo, el paciente 4471"),
    ("horario imposible", "tienen algo el domingo?"),
    ("horario imposible", "puedo ir a las 7 de la noche?"),
    ("reagendar reagendado", "Buenas, ya había cambiado la cita pero otra vez no puedo"),
    ("confirmación", "confirmo la cita del jueves a las 3:40"),
    ("ambigua", "Buenas, la cita sigue en pie?"),
    ("ambigua", "me llegó un mensaje de recordatorio pero yo no tengo cita"),
    ("mucho texto", "Buenas tardes, disculpe la molestia, resulta que tengo el control "
                    "el jueves pero me salió una reunión de trabajo que no puedo mover y "
                    "quería ver si hay alguna posibilidad de cambiarlo, ojalá para la "
                    "misma semana porque ya llevo dos meses sin ir"),
    ("cortés y vaga", "Buenas tardes, quisiera saber por la disponibilidad"),
    ("fecha explícita", "Necesito cita el 17 de septiembre en la mañana en el Centro"),
    ("fecha explícita", "Buenas, agendame el control para el 2026-09-24 en Chapinero"),
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=Path("solicitudes_whatsapp.jsonl"))
    args = parser.parse_args()

    args.salida.write_text(
        "\n".join(
            json.dumps(
                {"id": f"s{index:03d}", "dificultad": dificultad, "texto": texto},
                ensure_ascii=False,
            )
            for index, (dificultad, texto) in enumerate(SOLICITUDES, start=1)
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"{len(SOLICITUDES)} solicitudes en {args.salida}")
    print("Clases:", ", ".join(sorted({d for d, _ in SOLICITUDES})))


if __name__ == "__main__":
    main()
