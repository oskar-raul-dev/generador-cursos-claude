"""El resumen de las 7:00: qué corrió, qué falló y qué se está degradando, en un mensaje."""

import json
import random
import statistics
from collections import defaultdict
from datetime import date, timedelta

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo",
         "Soacha", "Zipaquirá"]


def fake_week(today: date) -> list[dict]:
    """Siete noches de eventos: Kennedy se va volviendo lenta y anoche Soacha falló."""
    random.seed(5)
    events = []
    for days_ago in range(7, 0, -1):
        night = (today - timedelta(days=days_ago)).isoformat()
        for sede in SEDES:
            base = 120 + random.uniform(-15, 15)
            if sede == "Kennedy":
                base *= 1 + (7 - days_ago) * 0.25          # 25% más lenta cada noche
            failed = sede == "Soacha" and days_ago == 1
            events.append({"night": night, "branch": sede, "duration_s": round(base),
                           "outcome": "error" if failed else "ok",
                           "error": "TimeoutError: el export no llegó" if failed else None})
    return events


def digest(events: list[dict], last_night: str) -> str:
    history = defaultdict(list)
    for e in events:
        if e["night"] < last_night and e["outcome"] == "ok":
            history[e["branch"]].append(e["duration_s"])
    tonight = [e for e in events if e["night"] == last_night]
    failed = [e for e in tonight if e["outcome"] == "error"]
    slow = [(e["branch"], e["duration_s"], statistics.median(history[e["branch"]]))
            for e in tonight if e["outcome"] == "ok"
            and e["duration_s"] > 1.5 * statistics.median(history[e["branch"]])]
    lines = [f"Cierre del {last_night}: {len(tonight) - len(failed)} de {len(tonight)} sedes bien."]
    lines += [f"❌ {e['branch']}: {e['error']}" for e in failed]
    lines += [f"🐢 {b}: {d} s, su mediana de la semana es {m:.0f} s" for b, d, m in slow]
    if not failed and not slow:
        lines.append("Nada que mirar hoy.")
    return "\n".join(lines)


if __name__ == "__main__":
    today = date(2026, 10, 6)
    events = fake_week(today)
    print(digest(events, (today - timedelta(days=1)).isoformat()))
