"""Prepara la plantilla de los treinta juicios humanos. **No los inventa.**

    uv run python preparar_juicios.py --informe informe.json --salida juicios_humanos.jsonl

Este es el único insumo del track que un script no puede producir, y el archivo lo dice
en voz alta: sale con el campo `veredicto_humano` **vacío**, y `bench_judges.py` se
niega a correr si encuentra alguno sin llenar.

Fabricar juicios humanos con un modelo y después medir el acuerdo del juez contra ellos
produciría un kappa alto y completamente vacío: estarías midiendo cuánto se parece un
modelo a otro modelo. El procedimiento correcto son veinte minutos con la rúbrica de
`judge.py` delante, y sin haber visto el fallo del juez —el anclaje es real y arruina la
comparación.
"""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

VERDICTS = ("correcta", "incompleta", "incorrecta")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--informe", type=Path, required=True, help="Salida de run_eval.py")
    parser.add_argument("--conjunto", type=Path, default=Path("evalset.jsonl"))
    parser.add_argument("--salida", type=Path, default=Path("juicios_humanos.jsonl"))
    parser.add_argument("--cuantos", type=int, default=30)
    parser.add_argument("--semilla", type=int, default=20260913)
    args = parser.parse_args()

    report = json.loads(args.informe.read_text(encoding="utf-8"))
    evalset = {
        json.loads(line)["id"]: json.loads(line)
        for line in args.conjunto.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }

    # Muestra aleatoria con semilla fija: elegir a dedo las que "se ven interesantes"
    # sesga el conjunto hacia los casos difíciles y el kappa sale peor de lo que es.
    rng = random.Random(args.semilla)
    sample = rng.sample(report["casos"], k=min(args.cuantos, len(report["casos"])))

    lines = []
    for case in sample:
        source = evalset[case["case_id"]]
        lines.append(
            json.dumps(
                {
                    "id": case["case_id"],
                    "pregunta": source["pregunta"],
                    "referencia": source["respuesta_referencia"],
                    "respuesta": case.get("respuesta", ""),
                    # El campo que tienes que llenar tú, a mano, con la rúbrica delante.
                    "veredicto_humano": "",
                    "_valores_validos": list(VERDICTS),
                }
            )
            + ""
        )

    args.salida.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(lines)} juicios por llenar en {args.salida}")
    print("Llena `veredicto_humano` con: " + " | ".join(VERDICTS))
    print("Hazlo con la rúbrica de judge.py delante y SIN mirar el fallo del juez.")


if __name__ == "__main__":
    main()
