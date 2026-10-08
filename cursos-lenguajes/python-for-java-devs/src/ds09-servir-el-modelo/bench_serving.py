"""Medición de la sección 6: el endpoint con `pickle` y con `onnxruntime`.

    uv run --with fastapi==0.141.1 --with uvicorn==0.52.4 --with scikit-learn==1.9.1 \\
           --with onnxruntime==1.30.0 python bench_serving.py --modelos modelos

Se mide **sobre HTTP contra un uvicorn de verdad**, no con el cliente de pruebas en proceso.
Es la lección de la Fase 10 del camino base cobrada otra vez: allí el costo del modelo de
salida parecía un 33% medido en proceso y **desapareció** medido sobre HTTP, porque el
servidor y la red se comen la diferencia. Un número en proceso responde otra pregunta.

Tres cosas por backend:

- **Arranque en frío**: desde que se lanza el proceso hasta que `/salud` contesta. Es lo que
  espera un contenedor que acaba de escalar.
- **Latencia p50 y p95** de `/riesgo` sobre peticiones reales.
- **Tamaño en disco** del artefacto.

El cliente es `urllib` de la biblioteca estándar: meter `httpx` aquí agregaría una dependencia
al medidor, y el medidor no debe pesar más que lo medido.
"""

from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

# Una cita cualquiera del tramo de prueba. Los seis campos con nombre: el vector lo arma el
# servidor, que es la decisión de diseño de `serve.py`.
PAYLOAD = {
    "inasistencias_previas": 2,
    "jueves_tarde": 1,
    "lluvia_mm": 12.0,
    "distancia_km": 18.0,
    "dias_desde_agendamiento": 30,
}


def wait_until_ready(port: int, timeout: float = 40.0) -> float:
    """Segundos hasta que `/salud` contesta. Lanza si no contesta nunca."""
    started = time.perf_counter()
    while time.perf_counter() - started < timeout:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/salud", timeout=1):
                return time.perf_counter() - started
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            time.sleep(0.05)
    raise SystemExit(f"El servidor del puerto {port} no arrancó en {timeout:g} s")


def post(port: int, payload: dict) -> dict:
    request = urllib.request.Request(
        f"http://127.0.0.1:{port}/riesgo",
        data=json.dumps(payload).encode(), method="POST",
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=5) as response:
        return json.loads(response.read())


def measure(backend: str, port: int, models: Path, requests: int,
            warmup: int) -> dict:
    """Arranca un uvicorn con ese backend, mide y lo apaga."""
    environment = {**os.environ, "AUREA_BACKEND": backend,
                   "AUREA_MODELOS": str(models.resolve())}
    process = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "serve:app", "--port", str(port),
         "--log-level", "warning"],
        cwd=Path(__file__).parent, env=environment,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        cold = wait_until_ready(port)
        # El calentamiento no es cortesía: la primera petición paga la importación perezosa
        # de medio FastAPI y el primer paso por el validador de Pydantic. Sin descartarla,
        # el p95 de mil peticiones lo decide una sola.
        for _ in range(warmup):
            post(port, PAYLOAD)

        timings = []
        for _ in range(requests):
            started = time.perf_counter()
            body = post(port, PAYLOAD)
            timings.append((time.perf_counter() - started) * 1000)
        timings.sort()

        return {
            "backend": backend,
            "arranque_s": cold,
            "p50_ms": statistics.median(timings),
            "p95_ms": timings[int(len(timings) * 0.95) - 1],
            "probabilidad": body["probabilidad_inasistencia"],
        }
    finally:
        process.terminate()
        process.wait(timeout=10)


def main() -> None:
    parser = argparse.ArgumentParser(description="El endpoint, en sus dos formatos.")
    parser.add_argument("--modelos", type=Path, default=Path("modelos"))
    parser.add_argument("--peticiones", type=int, default=500)
    parser.add_argument("--calentamiento", type=int, default=50)
    parser.add_argument("--puerto", type=int, default=8100)
    args = parser.parse_args()

    results = [measure(backend, args.puerto + offset, args.modelos,
                       args.peticiones, args.calentamiento)
               for offset, backend in enumerate(("pickle", "onnx"))]

    print(f"{'backend':<12}{'arranque':>12}{'p50':>10}{'p95':>10}{'artefacto':>12}")
    for result in results:
        suffix = "pkl" if result["backend"] == "pickle" else "onnx"
        size = (args.modelos / f"modelo.{suffix}").stat().st_size / 1024
        print(f"{result['backend']:<12}{result['arranque_s']:>9.2f} s"
              f"{result['p50_ms']:>7.2f} ms{result['p95_ms']:>7.2f} ms{size:>9.1f} KB")

    difference = abs(results[0]["probabilidad"] - results[1]["probabilidad"])
    print(f"\n{args.peticiones:,} peticiones por backend, {args.calentamiento} de "
          f"calentamiento descartadas.")
    print(f"Los dos backends devuelven la misma probabilidad: "
          f"diferencia {difference:.2e}")


if __name__ == "__main__":
    main()
