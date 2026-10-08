"""Medición de la sección 6: cuatro configuraciones sobre las mismas solicitudes.

    uv run python bench_agent.py --solicitudes solicitudes_whatsapp.jsonl --runs 5

La hipótesis es que las descripciones pesan más que el modelo. La cuarta fila
—formulario más SQL, sin agente— es la que puede cambiar el alcance de ia07.
"""

from __future__ import annotations

import argparse
import copy
import json
import statistics
import time
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

import anthropic

import agent
from agenda_client import seeded_agenda
from tools import TOOL_DEFINITIONS


def strip_descriptions(tools: list[dict]) -> list[dict]:
    """La configuración 1: lo que sale de generar herramientas desde las firmas.

    No es un competidor de paja: es exactamente lo que produce un equipo con prisa y
    buen criterio de Java, donde la firma basta y el javadoc es cortesía.
    """
    poor = copy.deepcopy(tools)
    for tool in poor:
        tool["description"] = tool["name"].replace("_", " ").capitalize() + "."
        for prop in tool["input_schema"]["properties"].values():
            prop.pop("description", None)
            prop.pop("enum", None)
            prop.pop("format", None)
        tool.pop("strict", None)
        tool["input_schema"].pop("additionalProperties", None)
    return poor


@dataclass(frozen=True, slots=True)
class Outcome:
    configuration: str
    request_id: str
    turns: int
    tool_calls: int
    input_tokens: int
    output_tokens: int
    latency_ms: float
    cost_usd: str


def run_configuration(
    client: anthropic.Anthropic,
    name: str,
    *,
    model: str,
    tools: list[dict],
    requests: list[tuple[str, str]],
) -> list[Outcome]:
    outcomes: list[Outcome] = []

    original_model, original_tools = agent.MODEL, TOOL_DEFINITIONS[:]
    agent.MODEL = model
    TOOL_DEFINITIONS[:] = tools
    try:
        for request_id, text in requests:
            agenda = seeded_agenda()  # agenda limpia por solicitud: no se contaminan entre sí
            started = time.perf_counter()
            run = agent.run_agent(client, agenda, text)
            outcomes.append(
                Outcome(
                    configuration=name,
                    request_id=request_id,
                    turns=run.turns,
                    tool_calls=len(run.tool_calls),
                    input_tokens=run.input_tokens,
                    output_tokens=run.output_tokens,
                    latency_ms=(time.perf_counter() - started) * 1000,
                    cost_usd=str(run.cost),
                )
            )
    finally:
        agent.MODEL, TOOL_DEFINITIONS[:] = original_model, original_tools

    return outcomes


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--solicitudes", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=5)
    parser.add_argument("--out", type=Path, default=Path("bench_ia03.json"))
    args = parser.parse_args()

    requests = [
        (record["id"], record["texto"])
        for record in (
            json.loads(line)
            for line in args.solicitudes.read_text(encoding="utf-8").splitlines()
            if line.strip()
        )
    ]

    client = anthropic.Anthropic(timeout=180.0, max_retries=3)
    configurations = [
        ("descripciones pobres · opus", "claude-opus-5", strip_descriptions(TOOL_DEFINITIONS)),
        ("descripciones completas · opus", "claude-opus-5", TOOL_DEFINITIONS[:]),
        ("descripciones completas · haiku", "claude-haiku-4-5", TOOL_DEFINITIONS[:]),
    ]

    outcomes: list[Outcome] = []
    for _ in range(args.runs):
        for name, model, tools in configurations:
            outcomes.extend(run_configuration(client, name, model=model, tools=tools,
                                              requests=requests))

    args.out.write_text(
        json.dumps([asdict(o) for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    for name, _, _ in configurations:
        rows = [o for o in outcomes if o.configuration == name]
        total = sum((Decimal(o.cost_usd) for o in rows), start=Decimal(0))
        print(
            f"{name:<34} turnos(med)={statistics.median(o.turns for o in rows):>4.1f}  "
            f"herramientas={statistics.median(o.tool_calls for o in rows):>4.1f}  "
            f"USD/reserva={total / Decimal(len(rows)):.6f}"
        )

    # La cuarta fila de la tabla —formulario más SQL— NO se corre aquí: no tiene modelo
    # que medir. Se cuenta a mano cuántas de las solicitudes resuelve un formulario de
    # tres campos, y ese conteo es el ejercicio 19. Automatizarlo sería fingir que la
    # pregunta es técnica cuando es de producto.


if __name__ == "__main__":
    main()
