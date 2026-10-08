"""Una traza de Tempo, como árbol de tiempos (Fase 23): cada span con su inicio, su duración y su servicio.

    python scripts/obs/trace.py <trace_id>                  del cluster lab
    python scripts/obs/trace.py <trace_id> --context kind-minimo

El trace_id sale de la línea "request" de inventory (G7 + G10). El script abre un port-forward a Tempo en un puerto
libre, pide la traza a su API (/api/v2/traces/<id>) y lo cierra. Lo mismo que Grafana (Explore, fuente Tempo), en
la terminal. Solo la biblioteca estándar: corre igual en macOS, Linux y Windows.
"""

import argparse
import json
import socket
import subprocess
import sys
import time
import urllib.request


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def fetch(context: str, trace_id: str) -> dict:
    port = free_port()
    forward = subprocess.Popen(["kubectl", "--context", context, "-n", "observability", "port-forward", "svc/tempo",
                                f"{port}:3200"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        url = f"http://127.0.0.1:{port}/api/v2/traces/{trace_id}"
        for _ in range(30):  # el port-forward tarda un momento en abrir
            try:
                request = urllib.request.Request(url, headers={"Accept": "application/json"})
                with urllib.request.urlopen(request, timeout=20) as response:
                    return json.load(response)
            except OSError:
                time.sleep(1)
        sys.exit(f"Tempo no contestó en 127.0.0.1:{port}: ¿están encendidas las trazas (task obs:on -- traces)?")
    finally:
        forward.terminate()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_id")
    parser.add_argument("--context", default="kind-lab", help="el contexto de kubectl (por defecto, kind-lab)")
    args = parser.parse_args()

    data = fetch(args.context, args.trace_id)
    trace = data.get("trace", data)
    spans = []
    for resource in trace.get("resourceSpans", []):
        service = next((a["value"].get("stringValue") for a in resource["resource"]["attributes"]
                        if a["key"] == "service.name"), "?")
        for scope in resource.get("scopeSpans", []):
            for span in scope["spans"]:
                start, end = int(span["startTimeUnixNano"]), int(span["endTimeUnixNano"])
                kind = span.get("kind", "").replace("SPAN_KIND_", "")
                spans.append((start, service, span["name"], kind, (end - start) / 1e6))
    if not spans:
        print(f"Tempo no tiene la traza {args.trace_id} (¿todavía no llegó, o ya venció la retención?)")
        return 1
    spans.sort()
    t0 = spans[0][0]
    print(len(spans), "spans", sorted({s[1] for s in spans}))
    for start, service, name, kind, duration in spans:
        print(f"{(start - t0) / 1e6:8.1f} ms {duration:8.1f} ms  {service:10} {kind:7} {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
