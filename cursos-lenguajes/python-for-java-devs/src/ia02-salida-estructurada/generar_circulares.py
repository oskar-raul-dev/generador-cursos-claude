"""Las circulares de aseguradora, con sus reglas anotadas.

    uv run python generar_circulares.py --salida circulares --semilla 20260913

Produce dos cosas que tienen que estar de acuerdo entre sí: los documentos y el archivo
de reglas esperadas contra el que se mide la extracción. **Las reglas se derivan de lo
que se escribió**, no al revés: por construcción no puede haber desacuerdo entre el
corpus y su anotación, que es el error más caro de un conjunto anotado a mano.

Una de cada cinco circulares es **ambigua a propósito** —habla de copago sin decir nada
sobre cobertura— porque es el caso que justifica el valor `no_dice` del contrato, y un
corpus sin casos ambiguos hace que ese contrato parezca ceremonia.
"""

from __future__ import annotations

import argparse
import json
import random
import unicodedata
from datetime import date, timedelta
from pathlib import Path

INSURERS = [
    ("Seguros Andina", "830003564"),
    ("Prepagada Altamira", "800251440"),
    ("Salud Meridiano", "890903937"),
    ("Coberturas del Llano", "860002964"),
]

PROCEDURES = [
    ("992102", "retiro de aparatología ortodóncica fija"),
    ("992101", "instalación de aparatología ortodóncica fija"),
    ("992310", "control mensual de ortodoncia"),
    ("237101", "carilla en resina compuesta"),
    ("237204", "corona libre de metal"),
    ("992401", "retenedor termoformado"),
]

# Las comillas tipográficas van a propósito: son las que trae un PDF real y las que
# rompen la verificación de citas si `_normalize` no las pliega. El corpus tiene que
# ejercitar ese camino, no evitarlo.
OPENING = (
    "Respetado prestador:\n\n"
    "Por medio de la presente comunicamos las modificaciones a las condiciones de "
    "cobertura que regirán a partir de la fecha indicada. Le solicitamos socializar "
    "esta información con su personal administrativo y de facturación.\n\n"
)
CLOSING = (
    "\nCordialmente,\n\n"
    "Dirección de Prestadores\n"
    "Área de Auditoría y Cuentas Médicas\n"
)


def _sentence_covered(code: str, name: str, plan: str, copayment: int) -> str:
    monto = f"{copayment:,}".replace(",", ".")
    return (
        f"A partir de la fecha señalada, el procedimiento {code} —{name}— "
        f"queda cubierto en el {plan} con un copago de ${monto} pesos a cargo del "
        f"afiliado."
    )


def _sentence_not_covered(code: str, name: str, plan: str) -> str:
    return (
        f"Se informa que el procedimiento {code} —{name}— “no se "
        f"encuentra cubierto” en el {plan} y su valor deberá ser asumido "
        f"directamente por el afiliado."
    )


def _sentence_ambiguous(code: str, copayment: int) -> str:
    """Habla de copago y no dice nada de cobertura. Es el caso que exige `no_dice`."""
    monto = f"{copayment:,}".replace(",", ".")
    return (
        f"Se ajusta el valor del copago aplicable al procedimiento {code} a ${monto} "
        f"pesos, sin perjuicio de las condiciones generales del contrato."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--salida", type=Path, default=Path("circulares"))
    parser.add_argument("--semilla", type=int, default=20260913)
    parser.add_argument("--cuantas", type=int, default=100)
    parser.add_argument("--reglas", type=Path, default=Path("reglas_esperadas.json"))
    args = parser.parse_args()

    rng = random.Random(args.semilla)
    args.salida.mkdir(parents=True, exist_ok=True)
    expected: dict[str, list[dict[str, object]]] = {}

    for index in range(args.cuantas):
        insurer, nit = INSURERS[index % len(INSURERS)]
        plan = ["plan básico", "plan complementario", "plan integral"][index % 3]
        effective = date(2026, 3, 1) + timedelta(days=30 * (index % 8))
        ambiguous = index % 5 == 0

        body = [f"CIRCULAR {index + 1:03d} DE 2026 — {insurer.upper()}", "", OPENING]
        rules: list[dict[str, object]] = []

        for code, name in rng.sample(PROCEDURES, k=rng.randint(1, 3)):
            copayment = rng.choice([15000, 24000, 38000, 45000, 62000])

            if ambiguous:
                sentence = _sentence_ambiguous(code, copayment)
                covered = "no_dice"
            elif rng.random() < 0.5:
                sentence = _sentence_covered(code, name, plan, copayment)
                covered = "si"
            else:
                sentence = _sentence_not_covered(code, name, plan)
                covered = "no"
                copayment = 0

            body.append(sentence + "\n")
            rules.append(
                {
                    "insurer_nit": nit,
                    "procedure_code": code,
                    "covered": covered,
                    "copayment_cop": str(copayment) if covered != "no" else None,
                    "valid_from": effective.isoformat(),
                    # La cita esperada es la frase completa, tal como quedó escrita.
                    # Derivarla del texto en vez de escribirla aparte es lo que
                    # garantiza que el corpus y su anotación no puedan discrepar.
                    "quote": unicodedata.normalize("NFC", sentence),
                }
            )

        body.append(
            f"\nLas presentes disposiciones rigen a partir del {effective.isoformat()}."
        )
        body.append(CLOSING)

        name_file = f"{index:03d}-{insurer.lower().replace(' ', '-')}-{effective.isoformat()}.txt"
        (args.salida / name_file).write_text("\n".join(body), encoding="utf-8")
        expected[name_file] = rules

    args.reglas.write_text(json.dumps(expected, ensure_ascii=False, indent=2), encoding="utf-8")

    total = sum(len(rules) for rules in expected.values())
    ambiguous_rules = sum(
        1 for rules in expected.values() for rule in rules if rule["covered"] == "no_dice"
    )
    print(f"{args.cuantas} circulares en {args.salida}/ y {total} reglas en {args.reglas}")
    print(f"Reglas que exigen 'no_dice': {ambiguous_rules} ({ambiguous_rules / total:.0%})")


if __name__ == "__main__":
    main()
