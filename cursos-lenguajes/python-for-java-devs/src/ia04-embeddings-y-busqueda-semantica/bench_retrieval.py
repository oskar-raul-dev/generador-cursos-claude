"""Medición de la sección 6: tres estrategias sobre las mismas cincuenta preguntas.

    uv run python bench_retrieval.py --preguntas preguntas_anotadas.jsonl --k 5

Cada pregunta trae anotado el fragmento correcto y su etiqueta —lexica, semantica o
mixta—, puesta ANTES de ver ningún resultado. Etiquetar después sería fabricar la
conclusión, y la conclusión de esta sección es justamente el corte por etiqueta.
"""

from __future__ import annotations

import argparse
import json
import statistics
import time
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

from db import connect
from search import Hit, hybrid_search, lexical_search, vector_search

STRATEGIES: dict[str, Callable[..., list[Hit]]] = {
    "texto completo": lexical_search,
    "vectorial": vector_search,
    "híbrida": hybrid_search,
}


@dataclass(frozen=True, slots=True)
class Question:
    question_id: str
    text: str
    expected_chunk_id: int
    kind: str  # lexica | semantica | mixta


@dataclass(frozen=True, slots=True)
class Outcome:
    strategy: str
    question_id: str
    kind: str
    hit_rank: int | None  # posición del fragmento correcto, o None si no salió
    returned: int
    latency_ms: float


def load_questions(path: Path) -> list[Question]:
    questions: list[Question] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        questions.append(
            Question(
                question_id=record["id"],
                text=record["texto"],
                expected_chunk_id=record["fragmento_correcto"],
                kind=record["tipo"],
            )
        )
    return questions


def evaluate(questions: list[Question], k: int) -> list[Outcome]:
    outcomes: list[Outcome] = []

    with connect() as connection:
        for name, strategy in STRATEGIES.items():
            for question in questions:
                started = time.perf_counter()
                hits = strategy(connection, question.text, k=k)
                elapsed_ms = (time.perf_counter() - started) * 1000

                rank = next(
                    (
                        position
                        for position, hit in enumerate(hits, start=1)
                        if hit.chunk_id == question.expected_chunk_id
                    ),
                    None,
                )
                outcomes.append(
                    Outcome(
                        strategy=name,
                        question_id=question.question_id,
                        kind=question.kind,
                        hit_rank=rank,
                        returned=len(hits),
                        latency_ms=elapsed_ms,
                    )
                )

    return outcomes


def recall_at_k(outcomes: list[Outcome]) -> float:
    """Fracción de preguntas cuyo fragmento correcto salió entre los k devueltos."""
    if not outcomes:
        return 0.0
    return sum(1 for o in outcomes if o.hit_rank is not None) / len(outcomes)


def mrr(outcomes: list[Outcome]) -> float:
    """Rango recíproco medio: premia que el correcto salga primero, no solo que salga."""
    if not outcomes:
        return 0.0
    return sum(1 / o.hit_rank for o in outcomes if o.hit_rank) / len(outcomes)


def render(outcomes: list[Outcome]) -> str:
    lines = [
        f"{'estrategia':<18}{'todas':>8}{'léxicas':>10}{'semánt.':>10}"
        f"{'MRR':>8}{'p95 ms':>10}{'vacías':>8}"
    ]

    for name in STRATEGIES:
        rows = [o for o in outcomes if o.strategy == name]
        lexical = [o for o in rows if o.kind == "lexica"]
        semantic = [o for o in rows if o.kind == "semantica"]
        latencies = sorted(o.latency_ms for o in rows)
        p95 = latencies[max(0, int(len(latencies) * 0.95) - 1)]

        lines.append(
            f"{name:<18}{recall_at_k(rows):>8.2f}{recall_at_k(lexical):>10.2f}"
            f"{recall_at_k(semantic):>10.2f}{mrr(rows):>8.3f}{p95:>10.1f}"
            f"{sum(1 for o in rows if o.returned == 0):>8}"
        )

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preguntas", type=Path, required=True)
    parser.add_argument("--k", type=int, default=5)
    parser.add_argument("--out", type=Path, default=Path("bench_ia04.json"))
    args = parser.parse_args()

    questions = load_questions(args.preguntas)
    outcomes = evaluate(questions, args.k)

    args.out.write_text(
        json.dumps([o.__dict__ for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(render(outcomes))

    # La columna "vacías" no es ruido: es la que dice si el umbral está haciendo algo.
    # Si la vectorial nunca devuelve vacío sobre cincuenta preguntas reales, el umbral
    # está demasiado alto y el sistema no puede decir "no sé".
    print(
        "\nMediana de fragmentos devueltos por consulta: "
        f"{statistics.median(o.returned for o in outcomes):.0f}"
    )


if __name__ == "__main__":
    main()
