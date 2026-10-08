"""Medición de la sección 6: cuatro formas de calificar contra el juicio humano.

    uv run python bench_judges.py --conjunto evalset.jsonl --humanos juicios_humanos.jsonl

Los juicios humanos se escriben ANTES de ver el fallo del juez. Al revés, el anclaje
arruina la comparación y el kappa que salga no significa nada.
"""

from __future__ import annotations

import argparse
import json
from decimal import Decimal
from pathlib import Path

import anthropic

import judge as judge_module
from statistics_helpers import cohen_kappa, raw_agreement

# Fila 1: la línea base barata, y lo que hay en muchos repositorios. Se mide en serio
# para poder descartarla con un número en vez de con una opinión.
STOPWORDS = frozenset(
    "el la los las de del y o que no un una en para por con se su al es está".split()
)


def keyword_verdict(reference: str, candidate: str, *, threshold: float = 0.5) -> str:
    """Solapamiento de palabras significativas. Sin modelo y sin costo."""
    def significant(text: str) -> set[str]:
        return {w.strip(".,;:()").casefold() for w in text.split()} - STOPWORDS

    expected = significant(reference)
    if not expected:
        return "incorrecta"
    overlap = len(expected & significant(candidate)) / len(expected)
    return "correcta" if overlap >= threshold else "incorrecta"


def embedding_verdict(reference: str, candidate: str, *, threshold: float = 0.75) -> str:
    """Fila 2: similitud coseno con el modelo local de ia04. Sin costo por token."""
    from embeddings import embed_query  # diferido: arrastra PyTorch

    a, b = embed_query(reference), embed_query(candidate)
    # Los vectores vienen normalizados de embeddings.py, así que el producto punto ES
    # el coseno. Si algún día dejaran de venir normalizados, esto mentiría en silencio.
    similarity = sum(x * y for x, y in zip(a, b, strict=True))
    return "correcta" if similarity >= threshold else "incorrecta"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--conjunto", type=Path, required=True)
    parser.add_argument("--humanos", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path("bench_ia06.json"))
    args = parser.parse_args()

    # {id_caso: {"pregunta", "referencia", "respuesta", "veredicto_humano"}}
    humans = {
        record["id"]: record
        for record in (
            json.loads(line)
            for line in args.humanos.read_text(encoding="utf-8").splitlines()
            if line.strip()
        )
    }

    # El único insumo que un script no puede producir. Si está vacío, el acuerdo que
    # saldría sería el de un modelo contra otro modelo: un kappa alto y sin significado.
    pendientes = [key for key, row in humans.items() if not row.get("veredicto_humano")]
    if pendientes:
        raise SystemExit(
            f"Faltan {len(pendientes)} juicios humanos por llenar en {args.humanos} "
            f"(por ejemplo {pendientes[0]}). Llénalos a mano con la rúbrica de judge.py "
            "delante y sin mirar el fallo del juez; ver preparar_juicios.py."
        )

    client = anthropic.Anthropic(timeout=120.0, max_retries=3)
    human_verdicts = [humans[key]["veredicto_humano"] for key in sorted(humans)]
    rows: dict[str, dict[str, object]] = {}

    strategies: dict[str, object] = {
        "palabras clave": lambda r: keyword_verdict(r["referencia"], r["respuesta"]),
        "embeddings": lambda r: embedding_verdict(r["referencia"], r["respuesta"]),
    }

    for name, score in strategies.items():
        verdicts = [score(humans[key]) for key in sorted(humans)]  # type: ignore[operator]
        rows[name] = {
            "acuerdo": raw_agreement(human_verdicts, verdicts),
            "kappa": cohen_kappa(human_verdicts, verdicts),
            "costo": "0",
        }

    # Filas 3 y 4: el mismo juez con dos modelos. El caro solo se justifica si sube el
    # kappa de forma clara; si no, la suite puede correr a diario con el barato.
    for model in ("claude-haiku-4-5", "claude-opus-5"):
        original = judge_module.JUDGE_MODEL
        judge_module.JUDGE_MODEL = model
        try:
            verdicts, cost = [], Decimal(0)
            for key in sorted(humans):
                record = humans[key]
                verdict, _, call_cost = judge_module.judge(
                    client,
                    question=record["pregunta"],
                    reference=record["referencia"],
                    candidate=record["respuesta"],
                )
                verdicts.append(verdict)
                cost += call_cost
        finally:
            judge_module.JUDGE_MODEL = original

        rows[f"juez · {model}"] = {
            "acuerdo": raw_agreement(human_verdicts, verdicts),
            "kappa": cohen_kappa(human_verdicts, verdicts),
            "costo": str(cost),
        }

    args.out.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"{'forma de calificar':<24}{'acuerdo':>10}{'kappa':>10}{'costo USD':>12}")
    for name, row in rows.items():
        print(f"{name:<24}{row['acuerdo']:>10.2f}{row['kappa']:>10.2f}{row['costo']:>12}")

    # Recordatorio que el informe imprime a propósito: el acuerdo alto con kappa bajo es
    # la firma del juez perezoso, y las dos primeras filas suelen tenerla.
    print("\nLee el kappa antes que el acuerdo. Acuerdo alto + kappa bajo = juez inútil.")


if __name__ == "__main__":
    main()
