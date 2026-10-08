"""El conjunto de evaluación, derivado del manifiesto del corpus de ia04.

    uv run python generar_evalset.py --manifiesto ../ia04-.../corpus/manifiesto.json

Cincuenta casos: treinta y cinco contestables y **quince de abstención**, que son los
más valiosos y los que casi nadie incluye. Los de abstención preguntan por cosas que no
están en el corpus —una aseguradora que no existe, un código que nadie pactó—, y la
respuesta correcta es no contestar.

⚠️ **Lo que este generador NO hace, y es deliberado:** escribir las respuestas de
referencia con un modelo. La sección 4 lo dice: una referencia generada por otro modelo
convierte la evaluación en un espejo. Aquí la referencia se **deriva del manifiesto**,
que es el hecho del que salió el documento — no una opinión de nadie.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

# Aseguradoras y códigos que NO están en el corpus. Son la materia prima de los casos de
# abstención: si el sistema contesta algo sobre esto, está inventando.
ABSENT_INSURERS = ["Seguros Aurora", "Medisalud del Norte", "Previsora Oral"]
ABSENT_CODES = ["994500", "112233", "870101"]


def _reference_for(row: dict) -> str:
    """La respuesta de referencia, derivada del hecho que generó el documento."""
    if not row["cubierto"]:
        return (
            f"No. El procedimiento {row['codigo']} no está cubierto en "
            f"{row['plan_articulo']} de {row['aseguradora']}; lo paga el paciente. "
            f"({row['titulo']}, {row['clausula']})"
        )

    copago = f"{row['copago']:,}".replace(",", ".")
    autorizacion = (
        " Requiere autorización previa." if row["autorizacion_previa"]
        else " No requiere autorización previa."
    )
    return (
        f"Sí. El procedimiento {row['codigo']} está cubierto en {row['plan_articulo']} "
        f"de {row['aseguradora']} con copago de ${copago} pesos.{autorizacion} "
        f"({row['titulo']}, {row['clausula']})"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifiesto", type=Path, required=True)
    parser.add_argument("--salida", type=Path, default=Path("evalset.jsonl"))
    parser.add_argument("--contestables", type=int, default=35)
    parser.add_argument("--abstenciones", type=int, default=15)
    args = parser.parse_args()

    manifest = json.loads(args.manifiesto.read_text(encoding="utf-8"))
    current = [row for row in manifest if row["vigente_hasta"] is None]
    cases: list[dict[str, object]] = []

    for position in range(args.contestables):
        row = current[position % len(current)]
        # Los primeros dos tercios a desarrollo, el resto a retención. La partición se
        # decide AQUÍ y no al correr: si cambia entre corridas, los números dejan de ser
        # comparables y la retención pierde su sentido.
        split = "desarrollo" if position < args.contestables * 2 // 3 else "retencion"

        cases.append(
            {
                "id": f"e{position + 1:03d}",
                "pregunta": (
                    f"¿{row['aseguradora']} cubre el procedimiento {row['codigo']} "
                    f"en {row['plan_articulo']}?"
                ),
                "respuesta_referencia": _reference_for(row),
                "fragmento_esperado": row["fragmento"],
                "por_que": (
                    f"Cobertura {'positiva' if row['cubierto'] else 'negativa'} con "
                    f"cláusula explícita. Caso base de recuperación y atribución."
                ),
                "particion": split,
            }
        )

    for position in range(args.abstenciones):
        # Mitad aseguradora inexistente, mitad código inexistente. Son fallos distintos:
        # el primero no recupera nada; el segundo recupera fragmentos plausibles de la
        # aseguradora correcta y es mucho más fácil de contestar mal.
        if position % 2 == 0:
            insurer = ABSENT_INSURERS[position % len(ABSENT_INSURERS)]
            row = current[position % len(current)]
            pregunta = f"¿{insurer} cubre el procedimiento {row['codigo']}?"
            por_que = "La aseguradora no está en el corpus. No hay nada que recuperar."
        else:
            row = current[position % len(current)]
            code = ABSENT_CODES[position % len(ABSENT_CODES)]
            pregunta = f"¿{row['aseguradora']} cubre el procedimiento {code}?"
            por_que = (
                "El código no existe en ningún anexo, pero la aseguradora sí: la "
                "recuperación va a traer fragmentos plausibles y el sistema tiene que "
                "abstenerse igual. Es el caso difícil."
            )

        cases.append(
            {
                "id": f"a{position + 1:03d}",
                "pregunta": pregunta,
                "respuesta_referencia": (
                    "No se puede contestar con los documentos disponibles. Hay que "
                    "preguntarle directamente a la aseguradora."
                ),
                "fragmento_esperado": None,
                "por_que": por_que,
                "particion": "desarrollo" if position < args.abstenciones * 2 // 3 else "retencion",
                "debe_abstenerse": True,
            }
        )

    args.salida.write_text(
        "\n".join(json.dumps(case, ensure_ascii=False) for case in cases) + "\n",
        encoding="utf-8",
    )

    retention = sum(1 for c in cases if c["particion"] == "retencion")
    print(f"{len(cases)} casos en {args.salida}")
    print(f"  desarrollo: {len(cases) - retention} · retención: {retention}")
    print(f"  de abstención: {sum(1 for c in cases if c.get('debe_abstenerse'))}")


if __name__ == "__main__":
    main()
