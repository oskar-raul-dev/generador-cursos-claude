"""Medición 6.1: la caché de prompt sobre el tráfico de un día.

    uv run python bench_caching.py --trafico trafico_un_dia.jsonl --runs 3

Tres colocaciones sobre el mismo tráfico. La tercera —la fecha en el sistema— es el
error de la sección 4 medido en vez de descrito: esperamos que dé **exactamente lo mismo
que no poner caché**, y esa igualdad es la demostración.

⚠️ El tráfico importa tanto como la colocación. Quince consultas repartidas en ocho horas
y 900 mensajes concentrados en dos picos no son el mismo experimento, y por eso el guion
respeta las marcas de tiempo en vez de disparar las peticiones seguidas: un prefijo que
expira entre consultas es justamente lo que la hipótesis dice que pasa en NormaRAG.
"""

from __future__ import annotations

import argparse
import json
import time
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

import anthropic

from caching import ask_with_broken_cache, ask_with_cache, ask_without_cache

PLACEMENTS = {
    "sin caché": ask_without_cache,
    "caché bien puesta": ask_with_cache,
    "fecha en el sistema": ask_with_broken_cache,
}


@dataclass(frozen=True, slots=True)
class Outcome:
    placement: str
    project: str
    request_id: str
    created: int
    read: int
    uncached: int
    cost_usd: str


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trafico", type=Path, required=True)
    parser.add_argument("--contexto", type=Path, required=True)
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--out", type=Path, default=Path("bench_ia08.json"))
    parser.add_argument(
        "--acelerar",
        type=float,
        default=1.0,
        help=(
            "Divisor de las esperas entre peticiones. Con 1.0 el experimento tarda un "
            "día. Acelerarlo cambia el resultado —los prefijos dejan de expirar— y por "
            "eso el informe lo declara."
        ),
    )
    args = parser.parse_args()

    context = args.contexto.read_text(encoding="utf-8")
    traffic = [
        json.loads(line)
        for line in args.trafico.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    client = anthropic.Anthropic(timeout=180.0, max_retries=3)
    outcomes: list[Outcome] = []

    for _ in range(args.runs):
        for placement, ask in PLACEMENTS.items():
            previous_offset = 0.0
            for row in traffic:
                # La espera es el experimento. Sin ella, las tres colocaciones aciertan
                # la caché y la medición no dice nada sobre el tráfico real de Áurea.
                wait = (row["offset_segundos"] - previous_offset) / args.acelerar
                if wait > 0:
                    time.sleep(wait)
                previous_offset = row["offset_segundos"]

                _, stats = ask(client, row["pregunta"], context)
                outcomes.append(
                    Outcome(
                        placement=placement,
                        project=row["proyecto"],
                        request_id=row["id"],
                        created=stats.created,
                        read=stats.read,
                        uncached=stats.uncached,
                        cost_usd=str(stats.effective_cost()),
                    )
                )

    args.out.write_text(
        json.dumps([asdict(o) for o in outcomes], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"{'colocación':<22}{'proyecto':<12}{'leídos':>10}{'creados':>10}{'USD total':>12}")
    for placement in PLACEMENTS:
        for project in sorted({o.project for o in outcomes}):
            rows = [o for o in outcomes if o.placement == placement and o.project == project]
            if not rows:
                continue
            total = sum((Decimal(o.cost_usd) for o in rows), start=Decimal(0))
            print(
                f"{placement:<22}{project:<12}"
                f"{sum(o.read for o in rows):>10}{sum(o.created for o in rows):>10}"
                f"{total:>12.6f}"
            )

    if args.acelerar != 1.0:
        print(
            f"\n⚠️ Corrido con --acelerar {args.acelerar}: las esperas se dividieron, así que "
            "los prefijos expiraron menos de lo que expirarían en producción. El resultado "
            "favorece a la caché y hay que declararlo al publicar la tabla."
        )


if __name__ == "__main__":
    main()
