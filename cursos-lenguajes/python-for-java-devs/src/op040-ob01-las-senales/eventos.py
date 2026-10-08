"""Un evento ancho por sede y por noche, y las preguntas que contesta sin haberlas previsto."""

import json
import statistics
import time
from collections import Counter
from contextlib import contextmanager
from pathlib import Path

EVENTS = Path("eventos-cierre.jsonl")


@contextmanager
def wide_event(**fields):
    """Acumula campos durante el trabajo y escribe UNA línea al final, pase lo que pase."""
    event = dict(fields, started_at=time.time())
    try:
        yield event
        event["outcome"] = "ok"
    except Exception as error:
        event["outcome"] = "error"
        event["error"] = f"{type(error).__name__}: {error}"
        raise
    finally:
        event["duration_ms"] = round((time.time() - event.pop("started_at")) * 1000)
        with EVENTS.open("a", encoding="utf-8") as out:
            out.write(json.dumps(event, ensure_ascii=False) + "\n")


def close_branch(branch: str, rows: list[dict]) -> None:
    with wide_event(job="cierre", night="2026-10-05", branch=branch, code_version="a3f9c1") as ev:
        ev["rows_read"] = len(rows)
        rejected = [r for r in rows if r["valor"] <= 0]
        ev["rows_rejected"] = len(rejected)
        ev["reject_reasons"] = dict(Counter(r["motivo"] for r in rejected))
        time.sleep(0.01 * len(rows) / 100)            # el trabajo de verdad
        if branch == "Kennedy":
            raise TimeoutError("la base no respondió")


if __name__ == "__main__":
    EVENTS.unlink(missing_ok=True)
    nights = {
        "Centro": [{"valor": 1, "motivo": ""}] * 900,
        "Suba": [{"valor": 1, "motivo": ""}] * 400 + [{"valor": 0, "motivo": "sin código"}] * 35
                + [{"valor": -1, "motivo": "fecha futura"}] * 5,
        "Kennedy": [{"valor": 1, "motivo": ""}] * 300,
    }
    for branch, rows in nights.items():
        try:
            close_branch(branch, rows)
        except TimeoutError:
            pass                                         # el cierre sigue con las demás sedes

    events = [json.loads(line) for line in EVENTS.read_text(encoding="utf-8").splitlines()]
    print("una línea por sede:", len(events))
    suba = next(e for e in events if e["branch"] == "Suba")
    print("¿por qué no cuadra Suba?", suba["rows_rejected"], "rechazadas:", suba["reject_reasons"])
    print("¿qué falló?", [(e["branch"], e["error"]) for e in events if e["outcome"] == "error"])
    durations = [e["duration_ms"] for e in events]
    print("¿qué sede tardó más?", max(events, key=lambda e: e["duration_ms"])["branch"],
          "· mediana", statistics.median(durations), "ms")
