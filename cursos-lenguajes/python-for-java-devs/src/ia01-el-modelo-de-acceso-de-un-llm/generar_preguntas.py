"""Las veinte preguntas frecuentes de Patricia y las auxiliares.

    uv run python generar_preguntas.py

Semilla fija, salida reproducible, **cero datos clínicos**: son preguntas sobre
coberturas y tarifas, que es lo que de verdad ocupa una hora diaria en Áurea. Ningún
paciente identificable, ningún diagnóstico, ninguna fecha de nacimiento.

Las consume `bench_models.py` de esta sección. Son cortas a propósito: la hipótesis de
la medición es que en preguntas de una línea Haiku empata con Opus, y para probarla
hacen falta preguntas de una línea.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# Escritas a mano, no generadas al azar: veinte preguntas reales se escriben en media
# hora y salen mejores que cualquier plantilla. La combinatoria se reserva para el
# corpus de ia04, donde hacen falta cientos de fragmentos.
PREGUNTAS = [
    "¿El retiro de brackets lo cubre la prepagada o lo paga el paciente?",
    "¿Cuánto es el copago de un control mensual de ortodoncia?",
    "¿Hay que pedir autorización previa para una corona libre de metal?",
    "¿La radiografía panorámica va incluida en el plan o se factura aparte?",
    "¿Qué pasa si el paciente se cambia de plan a mitad del tratamiento?",
    "¿La profilaxis entra en el plan básico?",
    "¿Cuántas sesiones de control cubre la póliza al año?",
    "¿El retenedor después de la ortodoncia está cubierto?",
    "¿Se puede facturar la valoración inicial o es gratuita para la aseguradora?",
    "¿Qué soporte piden para radicar una carilla en resina?",
    "¿Cuánto tiempo hay para responder una glosa de la aseguradora?",
    "¿El plan complementario cubre tratamientos estéticos?",
    "¿Se puede cambiar de sede un control sin autorización de la aseguradora?",
    "¿La instalación de brackets requiere autorización previa?",
    "¿Qué código se usa para el control mensual de ortodoncia?",
    "¿Cubren la corona libre de metal o solo la metal-porcelana?",
    "¿El copago se cobra por sesión o por tratamiento completo?",
    "¿Hasta cuándo está vigente el anexo tarifario de este año?",
    "¿Se factura a la aseguradora o al paciente cuando el plan no cubre?",
    "¿Qué pasa si el procedimiento no aparece en el manual tarifario?",
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=Path("preguntas_patricia.jsonl"))
    args = parser.parse_args()

    args.salida.write_text(
        "\n".join(
            json.dumps({"id": f"cob-{index:03d}", "texto": texto}, ensure_ascii=False)
            for index, texto in enumerate(PREGUNTAS, start=1)
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"{len(PREGUNTAS)} preguntas en {args.salida}")


if __name__ == "__main__":
    main()
