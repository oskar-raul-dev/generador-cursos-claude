"""Medición de la sección 6: la misma pregunta contra tres modelos.

Amplía el arnés de la Fase 02 en vez de reemplazarlo: reusa `environment()` para que
el entorno se declare exactamente igual que en las dieciocho mediciones del camino
base, y cambia dos cosas que aquí no aplican.

    1. No mide pico de memoria. El trabajo es de red: `tracemalloc` mediría el JSON de
       la respuesta, que no le interesa a nadie.
    2. No repite el trabajo dos veces como hace `measure()`. Cada repetición cuesta
       dinero de verdad, y una corrida extra por modelo, por pregunta, multiplicada por
       treinta, es una línea en la factura de Áurea.

Uso:
    uv run python bench_models.py --questions preguntas_patricia.jsonl \
        --repeats 30 --out bench_ia01.json
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
import time
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

import anthropic

from llm import Answer, ask, build_client
from local import LOCAL_MODEL, ask_local
from pricing import CATALOG, VERIFIED_ON

REMOTE_MODELS = ("claude-opus-5", "claude-haiku-4-5")


@dataclass(frozen=True, slots=True)
class Sample:
    """Una ejecución: un modelo, una pregunta, una vez."""

    model: str
    question_id: str
    latency_ms: float
    input_tokens: int
    output_tokens: int
    cost_usd: str  # cadena, no float: Decimal no es serializable a JSON sin perder precisión


def load_questions(path: Path) -> list[tuple[str, str]]:
    """Lee el banco de preguntas seudonimizadas. Una por línea, en JSON.

    Formato: {"id": "cob-004", "texto": "¿La prepagada cubre el retiro de brackets?"}
    Ningún campo clínico, ninguna identificación de paciente. Ver la §5 de la historia.
    """
    questions: list[tuple[str, str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        questions.append((record["id"], record["texto"]))
    return questions


def measure_remote(
    client: anthropic.Anthropic, model: str, question_id: str, question: str
) -> Sample:
    """Una llamada cronometrada de extremo a extremo, con su costo real."""
    started = time.perf_counter()  # reloj monótono, igual que el arnés de la Fase 02
    answer: Answer = ask(client, question, model=model)
    elapsed_ms = (time.perf_counter() - started) * 1000

    return Sample(
        model=model,
        question_id=question_id,
        latency_ms=elapsed_ms,
        input_tokens=answer.input_tokens,
        output_tokens=answer.output_tokens,
        cost_usd=str(answer.cost),
    )


def measure_local(question_id: str, question: str) -> Sample:
    """El modelo local no reporta tokens: se registran en cero y se dice en la tabla.

    Inventar un conteo aproximado aquí sería exactamente el tipo de número que este
    curso no publica.
    """
    started = time.perf_counter()
    ask_local(question)
    elapsed_ms = (time.perf_counter() - started) * 1000

    return Sample(
        model=LOCAL_MODEL,
        question_id=question_id,
        latency_ms=elapsed_ms,
        input_tokens=0,
        output_tokens=0,
        cost_usd="0",
    )


def run(questions: list[tuple[str, str]], repeats: int, *, include_local: bool) -> list[Sample]:
    """Ejecuta la medición intercalando modelos.

    El orden importa: si se corrieran todas las de un modelo seguidas y la red se
    degradara a mitad de la corrida, la degradación se le cargaría entera a ese modelo.
    """
    client = build_client()
    samples: list[Sample] = []

    for repetition in range(repeats):
        for question_id, question in questions:
            for model in REMOTE_MODELS:
                samples.append(measure_remote(client, model, question_id, question))
            if include_local:
                samples.append(measure_local(question_id, question))
        print(f"repetición {repetition + 1}/{repeats} completa", file=sys.stderr)

    return samples


def summarize(samples: list[Sample]) -> str:
    """La tabla lista para pegar en la sección 6 de la lección."""
    lines = [
        f"Tarifas verificadas el {VERIFIED_ON.isoformat()}",
        "",
        f"{'modelo':<22}{'p50 ms':>10}{'p95 ms':>10}{'ent.':>8}{'sal.':>8}{'USD/resp.':>12}",
    ]

    by_model: dict[str, list[Sample]] = {}
    for sample in samples:
        by_model.setdefault(sample.model, []).append(sample)

    for model, model_samples in by_model.items():
        latencies = sorted(s.latency_ms for s in model_samples)
        p95 = latencies[max(0, int(len(latencies) * 0.95) - 1)]
        total_cost = sum((Decimal(s.cost_usd) for s in model_samples), start=Decimal(0))
        per_answer = total_cost / Decimal(len(model_samples))
        priced = model in CATALOG

        lines.append(
            f"{model:<22}"
            f"{statistics.median(latencies):>10.0f}"
            f"{p95:>10.0f}"
            f"{statistics.median(s.input_tokens for s in model_samples):>8.0f}"
            f"{statistics.median(s.output_tokens for s in model_samples):>8.0f}"
            f"{(f'{per_answer:.6f}' if priced else 'sin tarifa'):>12}"
        )

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questions", type=Path, required=True)
    parser.add_argument("--repeats", type=int, default=30)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument(
        "--no-local",
        action="store_true",
        help="Omite el modelo local (útil si Ollama no está corriendo).",
    )
    args = parser.parse_args()

    questions = load_questions(args.questions)
    samples = run(questions, args.repeats, include_local=not args.no_local)

    args.out.write_text(
        json.dumps([asdict(s) for s in samples], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(summarize(samples))


if __name__ == "__main__":
    main()
