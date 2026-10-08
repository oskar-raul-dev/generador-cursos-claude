"""El arnés: corre el conjunto, califica, y emite un informe reproducible.

    uv run python run_eval.py --conjunto evalset.jsonl --particion retencion --corridas 3

El informe se lee al revés de como invita: primero el kappa del juez, después el
intervalo, y solo al final el punto. Ese orden está en la sección 5 y es deliberado.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from dataclasses import asdict, dataclass
from datetime import datetime
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

import anthropic

import evalset as evalset_module
from answer import answer_question
from db import connect
from judge import JUDGE_MODEL, judge
from statistics_helpers import required_sample_size, wilson_interval

BOGOTA = ZoneInfo("America/Bogota")


@dataclass(frozen=True, slots=True)
class CaseResult:
    case_id: str
    verdict: str
    reason: str
    abstained: bool
    should_abstain: bool
    cost_usd: str


@dataclass(frozen=True, slots=True)
class Report:
    """Lo que se guarda y se compara. Sin la huella, dos informes no son comparables."""

    fingerprint: str
    split: str
    runs: int
    cases: int
    verdicts: dict[str, int]
    correct_rate: float
    correct_interval: tuple[float, float]
    abstention_correct: int
    abstention_total: int
    judge_model: str
    total_cost_usd: str
    ran_at: str
    # Lo que hace honesto el informe: cuántos casos harían falta para detectar la
    # mejora que interesa. Con cincuenta casos, casi nada es distinguible.
    cases_needed_for_five_points: int


def run(
    client: anthropic.Anthropic,
    evalset_path: Path,
    *,
    split: str,
    runs: int,
) -> tuple[Report, list[CaseResult]]:
    evalset = evalset_module.load(evalset_path)
    cases = evalset.split(split)  # type: ignore[arg-type]
    results: list[CaseResult] = []
    total_cost = Decimal(0)

    with connect() as connection:
        for _ in range(runs):
            for case in cases:
                answer = answer_question(client, connection, case.question)
                total_cost += answer.cost

                verdict, reason, judge_cost = judge(
                    client,
                    question=case.question,
                    reference=case.reference_answer,
                    candidate=answer.text,
                )
                total_cost += judge_cost

                results.append(
                    CaseResult(
                        case_id=case.case_id,
                        verdict=verdict,
                        reason=reason,
                        abstained=answer.abstained,
                        should_abstain=case.should_abstain,
                        cost_usd=str(answer.cost + judge_cost),
                    )
                )

    verdicts = Counter(result.verdict for result in results)
    correct = verdicts["correcta"]
    rate = correct / len(results) if results else 0.0

    abstention = [r for r in results if r.should_abstain]

    report = Report(
        fingerprint=evalset.fingerprint,
        split=split,
        runs=runs,
        cases=len(cases),
        verdicts=dict(verdicts),
        correct_rate=rate,
        correct_interval=wilson_interval(correct, len(results)),
        # Se reportan aparte: un sistema que contesta más y se abstiene menos puede
        # estar empeorando, y el agregado lo esconde.
        abstention_correct=sum(1 for r in abstention if r.abstained),
        abstention_total=len(abstention),
        judge_model=JUDGE_MODEL,
        total_cost_usd=str(total_cost),
        ran_at=datetime.now(BOGOTA).isoformat(timespec="seconds"),
        cases_needed_for_five_points=required_sample_size(max(rate, 0.05), 0.05)
        if 0.05 < rate < 0.94
        else -1,
    )
    return report, results


def render(report: Report) -> str:
    low, high = report.correct_interval
    return "\n".join(
        [
            f"Conjunto {report.fingerprint} · partición {report.split} · "
            f"{report.cases} casos × {report.runs} corridas · {report.ran_at}",
            f"Juez: {report.judge_model} — el kappa vigente sale de `calibrar-juez` y "
            "sin él este informe no es concluyente.",
            "",
            f"  correctas   {report.correct_rate:.2f}  (IC 95%: {low:.2f}–{high:.2f})",
            *(f"  {name:<11} {count}" for name, count in sorted(report.verdicts.items())),
            "",
            f"  abstenciones acertadas: {report.abstention_correct}/{report.abstention_total}",
            f"  costo total: ${report.total_cost_usd}",
            f"  casos necesarios para detectar +5 puntos: "
            f"{report.cases_needed_for_five_points}",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--conjunto", type=Path, required=True)
    parser.add_argument("--particion", default="retencion", choices=["desarrollo", "retencion"])
    parser.add_argument("--corridas", type=int, default=3)
    parser.add_argument("--out", type=Path, default=Path("informe.json"))
    args = parser.parse_args()

    client = anthropic.Anthropic(timeout=180.0, max_retries=3)
    report, results = run(client, args.conjunto, split=args.particion, runs=args.corridas)

    args.out.write_text(
        json.dumps(
            {"informe": asdict(report), "casos": [asdict(r) for r in results]},
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print(render(report))


if __name__ == "__main__":
    main()
