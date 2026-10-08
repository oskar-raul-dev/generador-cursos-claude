"""Medición de la sección 6: tres estrategias de salida estructurada, mismo corpus.

    uv run python bench_extraction.py --corpus circulares/ \
        --anotadas reglas_esperadas.json --runs 3

Las tres estrategias son defendibles y por eso están las tres. La primera es lo que hay
en producción en media industria; las otras dos son el mismo mecanismo del servidor con
distinta ergonomía.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path

import anthropic
from pydantic import ValidationError

from coverage import CircularExtraction
from extract import MODEL, SYSTEM, _normalize

# El modelo envuelve el JSON en un bloque de código más o menos la mitad de las veces.
# Esta expresión es exactamente la limpieza que todo el mundo termina escribiendo, y
# forma parte de la estrategia 1: quitarla sería medir un competidor de paja.
FENCED_JSON = re.compile(r"```(?:json)?\s*(?P<body>.*?)\s*```", re.DOTALL)

SCHEMA = CircularExtraction.model_json_schema()


@dataclass(frozen=True, slots=True)
class Outcome:
    """Resultado de extraer una circular con una estrategia."""

    strategy: str
    document: str
    valid_first_try: bool
    fabricated_quotes: int
    input_tokens: int
    output_tokens: int


def _fabricated(extraction: CircularExtraction, source: str) -> int:
    """Citas que no aparecen literalmente en el documento. La cuarta columna de la tabla."""
    haystack = _normalize(source)
    return sum(1 for rule in extraction.rules if _normalize(rule.quote) not in haystack)


def by_prompt(client: anthropic.Anthropic, text: str) -> tuple[CircularExtraction | None, object]:
    """Estrategia 1: pedirlo en el prompt y parsear a mano."""
    response = client.messages.create(
        model=MODEL,
        max_tokens=8192,
        system=SYSTEM + f"\n\nDevuelve SOLO un JSON con esta forma:\n{json.dumps(SCHEMA)}",
        messages=[{"role": "user", "content": f"Circular:\n\n{text}"}],
    )
    raw = "".join(b.text for b in response.content if b.type == "text").strip()
    fenced = FENCED_JSON.search(raw)
    candidate = fenced.group("body") if fenced else raw

    try:
        return CircularExtraction.model_validate_json(candidate), response.usage
    except (ValidationError, ValueError):
        return None, response.usage


def by_raw_schema(
    client: anthropic.Anthropic, text: str
) -> tuple[CircularExtraction | None, object]:
    """Estrategia 2: esquema JSON crudo en output_config, sin Pydantic del lado de la petición."""
    response = client.messages.create(
        model=MODEL,
        max_tokens=8192,
        system=SYSTEM,
        messages=[{"role": "user", "content": f"Circular:\n\n{text}"}],
        output_config={"format": {"type": "json_schema", "schema": SCHEMA}},
    )
    raw = next(b.text for b in response.content if b.type == "text")

    try:
        return CircularExtraction.model_validate_json(raw), response.usage
    except ValidationError:
        return None, response.usage


def by_parse(client: anthropic.Anthropic, text: str) -> tuple[CircularExtraction | None, object]:
    """Estrategia 3: messages.parse con el modelo de Pydantic. La de la sección 5."""
    response = client.messages.parse(
        model=MODEL,
        max_tokens=8192,
        system=SYSTEM,
        messages=[{"role": "user", "content": f"Circular:\n\n{text}"}],
        output_format=CircularExtraction,
    )
    try:
        return response.parsed_output, response.usage
    except ValidationError:
        return None, response.usage


STRATEGIES = {
    "prompt+json.loads": by_prompt,
    "output_config crudo": by_raw_schema,
    "messages.parse": by_parse,
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--corpus", type=Path, required=True)
    parser.add_argument("--anotadas", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--out", type=Path, default=Path("bench_ia02.json"))
    args = parser.parse_args()

    client = anthropic.Anthropic(timeout=180.0, max_retries=3)
    documents = sorted(args.corpus.glob("*.txt"))
    outcomes: list[Outcome] = []

    for _ in range(args.runs):
        for document in documents:
            text = document.read_text(encoding="utf-8")
            for name, strategy in STRATEGIES.items():
                extraction, usage = strategy(client, text)
                outcomes.append(
                    Outcome(
                        strategy=name,
                        document=document.name,
                        valid_first_try=extraction is not None,
                        fabricated_quotes=_fabricated(extraction, text) if extraction else 0,
                        input_tokens=usage.input_tokens,
                        output_tokens=usage.output_tokens,
                    )
                )

    args.out.write_text(
        json.dumps([o.__dict__ for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    for name in STRATEGIES:
        rows = [o for o in outcomes if o.strategy == name]
        valid = sum(1 for o in rows if o.valid_first_try)
        print(
            f"{name:<22} válidas al 1er intento: {valid}/{len(rows)}  "
            f"citas fabricadas: {sum(o.fabricated_quotes for o in rows)}"
        )

    # El acierto contra `--anotadas` NO se calcula aquí a propósito: comparar reglas
    # extraídas contra reglas esperadas es evaluación, y la evaluación honesta es ia06.
    # Sacar aquí un porcentaje de acierto con una comparación ingenua de campos sería
    # publicar un número que no aguanta la primera pregunta.


if __name__ == "__main__":
    main()
