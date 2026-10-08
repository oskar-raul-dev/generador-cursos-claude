"""Cambia las fallas del generador de caos en caliente (Fase 22), por un port-forward que abre y cierra solo.
Solo la biblioteca estándar: corre igual en macOS, Linux y Windows.

    python scripts/chaos/chaos.py show
    python scripts/chaos/chaos.py set latencyMs=5000 latencyPercent=100
    python scripts/chaos/chaos.py set errorPercent=50
    python scripts/chaos/chaos.py clear
    python scripts/chaos/chaos.py perfil sogamoso-con-lluvia

Los perfiles llevan nombre de ciudad, como los cuenta la historia de La Vecina:
    giron-un-martes        todo bien: ninguna falla
    sogamoso-con-lluvia    la droguería lejana con mala conexión: la mitad de las respuestas tarda 3 s, y un 20 % falla
    bogota-en-quincena     un vecino ahogado por la carga: todas tardan 800 ms, y un 5 % falla
"""
import json
import os
import subprocess
import sys
import time
import urllib.request

CONTEXT = os.environ.get("KUBE_CONTEXT", "kind-lab")
NAMESPACE = os.environ.get("NAMESPACE", "apps")
PORT = 18089
FIELDS = ("latencyMs", "latencyPercent", "errorPercent", "malformedPercent", "hangPercent")
PROFILES = {
    "giron-un-martes": {},
    "sogamoso-con-lluvia": {"latencyMs": 3000, "latencyPercent": 50, "errorPercent": 20},
    "bogota-en-quincena": {"latencyMs": 800, "latencyPercent": 100, "errorPercent": 5},
}


def call(method: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(f"http://127.0.0.1:{PORT}/chaos", data=data, method=method,
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=10))


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("show", "set", "clear", "perfil") or \
            (sys.argv[1] == "perfil" and (len(sys.argv) != 3 or sys.argv[2] not in PROFILES)):
        print(__doc__)
        return 2
    forward = subprocess.Popen(["kubectl", "--context", CONTEXT, "-n", NAMESPACE, "port-forward", "svc/chaos",
                                f"{PORT}:8080"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            try:
                current = call("GET")
                break
            except OSError:
                time.sleep(0.2)
        else:
            print("no se pudo llegar al generador (¿está encendido? task chaos:on)", file=sys.stderr)
            return 1
        if sys.argv[1] == "clear":
            current = call("PUT", {})
        elif sys.argv[1] == "perfil":
            current = call("PUT", PROFILES[sys.argv[2]])
        elif sys.argv[1] == "set":
            faults = dict(current["faults"])
            for arg in sys.argv[2:]:
                key, _, value = arg.partition("=")
                if key not in FIELDS:
                    print(f"campo desconocido: {key} (son: {', '.join(FIELDS)})", file=sys.stderr)
                    return 2
                faults[key] = int(value)
            current = call("PUT", faults)
        print(json.dumps(current, indent=2))
        return 0
    finally:
        forward.terminate()


if __name__ == "__main__":
    sys.exit(main())
