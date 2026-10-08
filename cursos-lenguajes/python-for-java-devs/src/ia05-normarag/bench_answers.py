"""Medición de la sección 6: cuatro enfoques sobre las mismas cincuenta preguntas.

    uv run python bench_answers.py --preguntas preguntas_anotadas.jsonl --runs 3

La fila que decide el proyecto no es la de NormaRAG: es la tercera, la que devuelve la
cláusula sin generar nada. Si le sirve a Patricia en la mitad de los casos, NormaRAG
debería generar solo en la otra mitad.
"""

from __future__ import annotations

import argparse
import json
import statistics
import time
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

import anthropic
from pydantic import ValidationError

from answer import SYSTEM, DraftAnswer, answer_question
from db import connect
from pricing import CATALOG
from search import hybrid_search

MODEL = "claude-opus-5"


@dataclass(frozen=True, slots=True)
class Outcome:
    approach: str
    question_id: str
    abstained: bool
    abstention_cause: str  # "" | "sin recuperacion" | "sin cita verificable" | "modelo"
    verified_citations: int
    rejected_citations: int
    input_tokens: int
    cost_usd: str
    latency_ms: float


def _full_context(corpus_dir: Path) -> str:
    """El competidor 1: el corpus entero en el sistema, sin recuperación.

    Va con el MISMO prompt y el mismo contrato de salida que NormaRAG. Medirlo con un
    prompt peor sería caricaturizarlo, y entonces la comparación no probaría nada.
    """
    return "\n\n".join(path.read_text(encoding="utf-8")
                       for path in sorted(corpus_dir.glob("*.txt")))


def run_full_context(
    client: anthropic.Anthropic, corpus: str, question: str
) -> tuple[Outcome | None, Decimal]:
    started = time.perf_counter()
    response = client.messages.parse(
        model=MODEL,
        max_tokens=2048,
        system=f"{SYSTEM}\n\nDocumentos:\n\n{corpus}",
        messages=[{"role": "user", "content": question}],
        output_format=DraftAnswer,
    )
    elapsed_ms = (time.perf_counter() - started) * 1000
    cost = CATALOG[MODEL].cost_of(response.usage.input_tokens, response.usage.output_tokens)

    try:
        draft = response.parsed_output
    except ValidationError:
        return None, cost

    # Aquí está el punto de la sección 4: con el corpus completo NO HAY contra qué
    # verificar la cita sin releer todo. Se cuenta lo que el modelo afirma, y se declara
    # en la tabla que esta fila no tiene columna de cita verificada.
    return (
        Outcome(
            approach="contexto completo",
            question_id="",
            abstained=not draft.answered,
            abstention_cause="" if draft.answered else "modelo",
            verified_citations=0,
            rejected_citations=len(draft.citations),
            input_tokens=response.usage.input_tokens,
            cost_usd=str(cost),
            latency_ms=elapsed_ms,
        ),
        cost,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preguntas", type=Path, required=True)
    parser.add_argument("--corpus", type=Path, default=Path("corpus_txt"))
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--out", type=Path, default=Path("bench_ia05.json"))
    parser.add_argument(
        "--sin-contexto-completo",
        action="store_true",
        help="Omite el competidor 1. Es el más caro de los cuatro: paga el corpus "
             "entero por pregunta.",
    )
    args = parser.parse_args()

    questions = [
        (record["id"], record["texto"])
        for record in (
            json.loads(line)
            for line in args.preguntas.read_text(encoding="utf-8").splitlines()
            if line.strip()
        )
    ]

    client = anthropic.Anthropic(timeout=180.0, max_retries=3)
    corpus = "" if args.sin_contexto_completo else _full_context(args.corpus)
    outcomes: list[Outcome] = []

    with connect() as connection:
        for _ in range(args.runs):
            for question_id, text in questions:
                # Fila 2: NormaRAG completo.
                started = time.perf_counter()
                result = answer_question(client, connection, text)
                elapsed_ms = (time.perf_counter() - started) * 1000

                cause = ""
                if result.abstained:
                    cause = "sin recuperacion" if not result.retrieved_chunk_ids else (
                        "sin cita verificable" if result.rejected_citations else "modelo"
                    )

                outcomes.append(
                    Outcome(
                        approach="normarag",
                        question_id=question_id,
                        abstained=result.abstained,
                        abstention_cause=cause,
                        verified_citations=len(result.citations),
                        rejected_citations=len(result.rejected_citations),
                        input_tokens=0,  # lo reporta el usage; se rellena en el ejercicio 7
                        cost_usd=str(result.cost),
                        latency_ms=elapsed_ms,
                    )
                )

                # Fila 3: solo recuperación. Sin modelo, sin costo de generación.
                started = time.perf_counter()
                hits = hybrid_search(connection, text, k=5)
                outcomes.append(
                    Outcome(
                        approach="solo recuperacion",
                        question_id=question_id,
                        abstained=not hits,
                        abstention_cause="sin recuperacion" if not hits else "",
                        verified_citations=len(hits),
                        rejected_citations=0,
                        input_tokens=0,
                        cost_usd="0",
                        latency_ms=(time.perf_counter() - started) * 1000,
                    )
                )

                if corpus:
                    outcome, _ = run_full_context(client, corpus, text)
                    if outcome is not None:
                        outcomes.append(
                            Outcome(**{**asdict(outcome), "question_id": question_id})
                        )

    args.out.write_text(
        json.dumps([asdict(o) for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    for approach in ("contexto completo", "normarag", "solo recuperacion"):
        rows = [o for o in outcomes if o.approach == approach]
        if not rows:
            continue
        total = sum((Decimal(o.cost_usd) for o in rows), start=Decimal(0))
        latencies = sorted(o.latency_ms for o in rows)
        print(
            f"{approach:<20} abstención={sum(o.abstained for o in rows) / len(rows):.2f}  "
            f"citas verif.(med)={statistics.median(o.verified_citations for o in rows):.0f}  "
            f"USD/resp={total / Decimal(len(rows)):.6f}  "
            f"p95={latencies[max(0, int(len(latencies) * 0.95) - 1)]:.0f} ms"
        )

    # La fila 4 —Patricia con los PDF— se cronometra a mano sobre diez preguntas y se
    # escribe en BENCHMARKS.md. No se automatiza porque no se puede: es el sistema actual.


if __name__ == "__main__":
    main()
