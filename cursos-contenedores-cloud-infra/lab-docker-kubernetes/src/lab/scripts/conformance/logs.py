"""La segunda mitad de la suite de G7 (Fase 18): lee el log reciente de los cuatro backends en el cluster
y comprueba el contrato del log. Solo la biblioteca estándar: corre igual en macOS, Linux y Windows.

    python scripts/conformance/logs.py --context kind-lab [--namespace apps] [--since 10m]

Comprueba que:
  - cada línea es un objeto JSON con time, level, service y msg;
  - la petición de la suite (X-Request-Id: g7-conformance-<servicio>) tiene su línea "request" con method,
    uri, path, status, duration_ms y request_id;
  - la venta de la suite (g7-conformance-venta) aparece en inventory, catalog y pricing: inventory reenvió el id.
"""

import argparse
import json
import subprocess
import sys

SERVICES = ["pricing", "inventory", "catalog", "replenish"]
REQUIRED = {"time", "level", "service", "msg"}
REQUEST = {"method", "uri", "path", "status", "duration_ms", "request_id"}
LEVELS = {"DEBUG", "INFO", "WARN", "ERROR"}
# Lo único que se acepta en texto, y todo es de la JVM antes de que exista ningún logger: el anuncio de
# JAVA_TOOL_OPTIONS (la variable la pone el chart, Fase 15), y desde G10 (Fase 23) el aviso de CDS que provoca
# -javaagent y el saludo del agente de OpenTelemetry. Callarlos cuesta el CDS (-Xshare:off) y los errores del
# propio agente (otel.javaagent.logging=none): se prefirió aceptarlos.
ALLOWED_TEXT = ("Picked up JAVA_TOOL_OPTIONS:",
                "OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes",
                "[otel.javaagent ")


def logs(context: str, namespace: str, since: str, service: str) -> list[tuple[str, str]]:
    """(contenedor, línea) de los pods del servicio, sin los Job de migraciones."""
    selector = f"app.kubernetes.io/name={service},app.kubernetes.io/component=backend"
    out = subprocess.run(
        ["kubectl", "--context", context, "-n", namespace, "logs", "-l", selector, "--all-containers",
         "--prefix", f"--since={since}", "--tail=-1"],
        capture_output=True, text=True, check=True).stdout
    lines = []
    for raw in out.splitlines():
        prefix, _, line = raw.partition("] ")
        lines.append((prefix.rsplit("/", 1)[-1], line))
    return lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--context", default="kind-lab")
    parser.add_argument("--namespace", default="apps")
    parser.add_argument("--since", default="10m")
    args = parser.parse_args()

    failures = 0
    for service in SERVICES:
        lines = logs(args.context, args.namespace, args.since, service)
        bad, found, sale = [], None, False
        for container, line in lines:
            if line.startswith(ALLOWED_TEXT):
                continue
            try:
                record = json.loads(line)
                if not isinstance(record, dict):
                    raise ValueError
            except ValueError:
                bad.append(f"[{container}] no es JSON: {line[:120]}")
                continue
            missing = REQUIRED - record.keys()
            if missing:
                bad.append(f"[{container}] le faltan {sorted(missing)}: {line[:120]}")
            elif record["level"] not in LEVELS:
                bad.append(f"[{container}] level {record['level']!r} no es {sorted(LEVELS)}")
            rid = record.get("request_id")
            if rid == f"g7-conformance-{service}" and record.get("msg") == "request":
                found = record
            if rid == "g7-conformance-venta":
                sale = True
        status = "ok"
        if bad:
            status = f"{len(bad)} líneas fuera del contrato"
        if service != "inventory" and found is None:
            status = "falta la línea de la petición de la suite"
        if found is not None and REQUEST - found.keys():
            status = f"a la línea de la petición le faltan {sorted(REQUEST - found.keys())}"
        if service in ("inventory", "catalog", "pricing") and not sale:
            status = "no aparece la venta de la suite (g7-conformance-venta)"
        print(f"{service:<10} {len(lines):>5} líneas · {status}")
        for line in bad[:5]:
            print(f"           {line}")
        failures += status != "ok"
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
