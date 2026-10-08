"""Los interruptores de observabilidad (Fase 17): enciende o apaga una pieza en .observability.json.

    python scripts/obs/switch.py on metrics
    python scripts/obs/switch.py off dashboards
    python scripts/obs/switch.py show
    python scripts/obs/switch.py file     el archivo, si existe (lo usa task deploy)
    python scripts/obs/switch.py chaos on|off    el generador de caos entre inventory y catalog (Fase 22)
    python scripts/obs/switch.py chaos on replenish    …o entre inventory y otro vecino (Fase 24)
    python scripts/obs/switch.py bus on|off valkey|nats    el bus de eventos (Fase 25)

El archivo no se versiona: es el estado de tu laboratorio, no del curso. task deploy lo suma a los valores
del chart (es JSON, que Helm lee como YAML), así que un deploy posterior respeta lo que encendiste.
Solo la biblioteca estándar: corre igual en macOS, Linux y Windows.
"""

import json
import sys
from pathlib import Path

PIECES = {
    "metrics": "Prometheus",
    "dashboards": "Grafana",
    "logs": "Loki y Fluent Bit",
    "traces": "Tempo",
}
STATE = Path(__file__).resolve().parents[2] / ".observability.json"


def load() -> dict:
    if STATE.exists():
        return json.loads(STATE.read_text(encoding="utf-8"))
    return {"observability": {}}


def main() -> int:
    if len(sys.argv) in (3, 4) and sys.argv[1] == "chaos" and sys.argv[2] in ("on", "off"):
        state = load()
        chaos = state.setdefault("global", {}).setdefault("chaos", {})
        chaos["enabled"] = sys.argv[2] == "on"
        # El vecino que intercepta (Fase 24): catalog si no se dice otro.
        if sys.argv[2] == "on":
            chaos["target"] = sys.argv[3] if len(sys.argv) == 4 else "catalog"
        STATE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"{STATE.name}: {json.dumps(state)}")
        return 0
    # El bus (Fase 25): bus.<x> para el interruptor del contrato y global.bus.<x> para los subcharts.
    if len(sys.argv) == 4 and sys.argv[1] == "bus" and sys.argv[2] in ("on", "off") and sys.argv[3] in ("valkey", "nats"):
        state = load()
        on = sys.argv[2] == "on"
        state.setdefault("bus", {})[sys.argv[3]] = {"enabled": on}
        state.setdefault("global", {}).setdefault("bus", {})[sys.argv[3]] = {"enabled": on}
        STATE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"{STATE.name}: {json.dumps(state)}")
        return 0
    if len(sys.argv) == 2 and sys.argv[1] == "file":
        print(STATE.name if STATE.exists() else "")
        return 0
    if len(sys.argv) == 2 and sys.argv[1] == "show":
        state = load()["observability"]
        for piece, what in PIECES.items():
            on = state.get(piece, {}).get("enabled", False)
            print(f"{piece:<11} {'encendida' if on else 'apagada':<10} {what}")
        return 0
    if len(sys.argv) != 3 or sys.argv[1] not in ("on", "off") or sys.argv[2] not in (*PIECES, "all"):
        print(f"uso: switch.py on|off <pieza>|all   (piezas: {', '.join(PIECES)})", file=sys.stderr)
        return 2
    action, piece = sys.argv[1], sys.argv[2]
    state = load()
    for name in PIECES if piece == "all" else [piece]:
        state["observability"][name] = {"enabled": action == "on"}
    # Grafana sin Prometheus no tiene qué mostrar: encenderla enciende también las métricas. Y los logs se
    # consultan desde Grafana (Loki no tiene interfaz propia): encenderlos enciende Grafana (Fase 18).
    if action == "on" and piece in ("dashboards", "logs", "all"):
        state["observability"]["metrics"] = {"enabled": True}
    if action == "on" and piece in ("logs", "all"):
        state["observability"]["dashboards"] = {"enabled": True}
    # La fuente de datos de Loki en Grafana sigue al interruptor de los logs.
    logs_on = state["observability"].get("logs", {}).get("enabled", False)
    state.setdefault("grafana", {}).setdefault("datasources", {})["loki"] = logs_on
    # Las trazas (Fase 23): Grafana necesita la fuente de Tempo, y los servicios, las variables de OpenTelemetry.
    if action == "on" and piece in ("traces", "all"):
        state["observability"]["dashboards"] = {"enabled": True}
        state["observability"]["metrics"] = {"enabled": True}
    traces_on = state["observability"].get("traces", {}).get("enabled", False)
    state["grafana"]["datasources"]["tempo"] = traces_on
    state.setdefault("global", {}).setdefault("traces", {})["enabled"] = traces_on
    STATE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"{STATE.name}: {json.dumps(state)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
