"""Medición de la sección 6: cuatro configuraciones del guardrail.

    uv run python bench_assistant.py \
        --solicitudes ../ia03-tool-calling-y-el-bucle-de-agente/solicitudes_whatsapp.jsonl \
        --sintomas sintomas.jsonl --runs 3

La columna que decide es **falsos negativos**, y va aparte a propósito: con costos
asimétricos, el agregado esconde el error caro.

La parte léxica de esta medición **no necesita la API** y se puede correr gratis con
`--solo-lexico`. Es lo primero que hay que mirar, porque es donde está el número.
"""

from __future__ import annotations

import argparse
import json
import time
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

from guardrails import has_clinical_image, mentions_symptom


@dataclass(frozen=True, slots=True)
class Outcome:
    configuration: str
    message_id: str
    should_escalate: bool
    escalated: bool
    reason: str
    latency_ms: float
    cost_usd: str

    @property
    def false_negative(self) -> bool:
        """Tenía que escalar y no escaló. El único error que no se puede aceptar."""
        return self.should_escalate and not self.escalated

    @property
    def false_positive(self) -> bool:
        """Escaló sin hacer falta. Le cuesta treinta segundos a Yuli."""
        return not self.should_escalate and self.escalated


def _load(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def run_lexical(messages: list[tuple[str, str, bool, list[str]]]) -> list[Outcome]:
    """La configuración 2: solo el guardrail léxico. Sin red y sin costo."""
    outcomes: list[Outcome] = []

    for message_id, text, should_escalate, attachments in messages:
        started = time.perf_counter()
        decision = mentions_symptom(text)
        if not decision.escalate:
            decision = has_clinical_image(attachments)
        elapsed_ms = (time.perf_counter() - started) * 1000

        outcomes.append(
            Outcome(
                configuration="guardrail léxico",
                message_id=message_id,
                should_escalate=should_escalate,
                escalated=decision.escalate,
                reason=decision.matched,
                latency_ms=elapsed_ms,
                cost_usd="0",
            )
        )

    return outcomes


def render(outcomes: list[Outcome]) -> str:
    lines = [
        f"{'configuración':<22}{'resolución':>12}{'falsos neg.':>13}"
        f"{'falsos pos.':>13}{'p95 ms':>10}{'USD/conv':>11}"
    ]

    configurations = dict.fromkeys(outcome.configuration for outcome in outcomes)
    for name in configurations:
        rows = [outcome for outcome in outcomes if outcome.configuration == name]
        resolved = sum(1 for row in rows if not row.escalated)
        latencies = sorted(row.latency_ms for row in rows)
        total = sum((Decimal(row.cost_usd) for row in rows), start=Decimal(0))

        lines.append(
            f"{name:<22}{resolved / len(rows):>11.0%}"
            f"{sum(row.false_negative for row in rows):>13}"
            f"{sum(row.false_positive for row in rows):>13}"
            f"{latencies[max(0, int(len(latencies) * 0.95) - 1)]:>10.2f}"
            f"{total / Decimal(len(rows)):>11.6f}"
        )

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--solicitudes", type=Path, required=True)
    parser.add_argument("--sintomas", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--out", type=Path, default=Path("bench_ia07.json"))
    parser.add_argument(
        "--solo-lexico",
        action="store_true",
        help="Corre solo la parte que no llama al modelo. Gratis, y es donde está el número.",
    )
    args = parser.parse_args()

    # Las solicitudes normales NO tienen que escalar; los mensajes con síntoma, sí.
    # Mezclarlas es lo que permite medir los dos errores a la vez, que es el punto.
    messages: list[tuple[str, str, bool, list[str]]] = [
        (row["id"], row["texto"], row.get("dificultad") == "urgencia", [])
        for row in _load(args.solicitudes)
    ] + [(row["id"], row["texto"], True, []) for row in _load(args.sintomas)]

    outcomes = run_lexical(messages)

    if not args.solo_lexico:
        # Las configuraciones 1 y 3 llaman al modelo y cuestan dinero. Se implementan en
        # los ejercicios 7 y 14 respectivamente; hasta entonces la tabla queda con ⏳ y
        # el guion lo dice en vez de inventar las filas.
        print(
            "⏳ Las configuraciones 'solo prompt' (ejercicio 7) y 'léxico + clasificador' "
            "(ejercicio 14) todavía no están implementadas. Corriendo solo la léxica.\n"
        )

    args.out.write_text(
        json.dumps([asdict(o) for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(render(outcomes))

    escapados = [o for o in outcomes if o.false_negative]
    if escapados:
        print(f"\nDejó pasar {len(escapados)}. Los tres primeros:")
        for outcome in escapados[:3]:
            print(f"  {outcome.message_id}")


if __name__ == "__main__":
    main()
