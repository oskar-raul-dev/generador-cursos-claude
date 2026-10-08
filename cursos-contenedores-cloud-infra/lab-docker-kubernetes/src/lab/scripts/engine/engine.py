"""Motor activo del laboratorio: qué motor usa el Taskfile, si responde, y cómo alternar.

Uso (desde src/lab/, normalmente a través del Taskfile):
    python3 scripts/engine/engine.py status
    python3 scripts/engine/engine.py use docker|podman
    python3 scripts/engine/engine.py stop docker|podman

El motor activo se guarda en .engine.env (LAB_ENGINE=docker|podman), que el Taskfile lee con
dotenv. No toca variables de entorno globales: cada tarea recibe el motor de ese archivo.
Solo biblioteca estándar: no necesita entorno virtual.
"""
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path

ENGINES = ("docker", "podman")
ENGINE_FILE = Path(__file__).resolve().parents[2] / ".engine.env"
SYSTEM = platform.system()  # "Darwin", "Linux" o "Windows"


def run(cmd: list[str], timeout: int = 15) -> tuple[int, str]:
    """Corre un comando y devuelve (código, salida). Nunca lanza: el diagnóstico sigue."""
    try:
        done = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return done.returncode, (done.stdout or done.stderr).strip()
    except FileNotFoundError:
        return 127, "no instalado"
    except subprocess.TimeoutExpired:
        return 124, f"sin respuesta en {timeout} s"


def active_engine() -> str:
    if ENGINE_FILE.exists():
        for line in ENGINE_FILE.read_text().splitlines():
            if line.startswith("LAB_ENGINE="):
                return line.split("=", 1)[1].strip()
    return "docker"  # el camino principal del curso


def responds(engine: str) -> tuple[bool, str]:
    """La única prueba que importa: que el motor conteste, no lo que diga su interfaz gráfica."""
    fmt = "{{.ServerVersion}}" if engine == "docker" else "{{.Version.Version}}"
    code, out = run([engine, "info", "--format", fmt])
    if code == 0:
        return True, out
    # Sin motor, el CLI puede imprimir media página; basta con decir que no responde.
    return False, "no instalado" if code == 127 else "no responde"


def memory(engine: str) -> str:
    fmt = "{{.MemTotal}}" if engine == "docker" else "{{.Host.MemTotal}}"
    code, out = run([engine, "info", "--format", fmt])
    return f"{int(out) / 2**30:.1f} GiB" if code == 0 and out.isdigit() else "?"


def podman_machine_state() -> str:
    if SYSTEM == "Linux":
        return "sin máquina (Podman corre nativo en Linux)"
    code, out = run(["podman", "machine", "inspect", "--format", "{{.State}}"])
    return out if code == 0 else f"sin máquina ({out})"


def status() -> int:
    current = active_engine()
    print(f"Motor activo del laboratorio: {current}  ({ENGINE_FILE.name})")
    for engine in ENGINES:
        installed = shutil.which(engine) is not None
        ok, detail = responds(engine) if installed else (False, "no instalado")
        mark = "✅" if ok else "❌"
        extra = f" · memoria de la VM {memory(engine)}" if ok else ""
        print(f"  {mark} {engine:6} {'responde, versión ' + detail if ok else detail}{extra}")
        if engine == "podman" and installed:
            print(f"           máquina: {podman_machine_state()}")
    # En Windows, CONTAINER_HOST apuntando a otro sitio rompe el CLI de Podman (a02).
    if SYSTEM == "Windows" and os.environ.get("CONTAINER_HOST"):
        print("  ⚠️  CONTAINER_HOST está definida y puede romper el CLI de Podman; ver a02.")
    ok, _ = responds(current)
    if not ok:
        print(f"El motor activo ({current}) no responde. Arráncalo con: task engine:use -- {current}")
        return 1
    return 0


def start(engine: str) -> None:
    if engine == "docker":
        # El CLI de Docker Desktop existe en las tres plataformas; en Linux con Docker Engine,
        # el demonio lo arranca systemd.
        cmd = ["docker", "desktop", "start"] if SYSTEM != "Linux" or shutil.which("docker-desktop") \
            else ["systemctl", "start", "docker"]
        subprocess.run(cmd, check=False)
    elif SYSTEM != "Linux":
        subprocess.run(["podman", "machine", "start"], check=False)


def wait_until_responds(engine: str, seconds: int = 120) -> bool:
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if responds(engine)[0]:
            return True
        time.sleep(3)
    return False


def use(engine: str) -> int:
    if engine not in ENGINES:
        print(f"Motor desconocido: {engine}. Usa docker o podman.")
        return 2
    if not responds(engine)[0]:
        print(f"{engine} no responde; arrancándolo…", flush=True)
        start(engine)
        if not wait_until_responds(engine):
            print(f"{engine} sigue sin responder. Mira task engine:status y a02.")
            return 1
    ENGINE_FILE.write_text(f"LAB_ENGINE={engine}\n")
    other = "podman" if engine == "docker" else "docker"
    print(f"Motor activo: {engine}.")
    if responds(other)[0]:
        print(f"Aviso: {other} también está encendido. Conviven, pero suman memoria, y un cluster de "
              f"cada uno no puede publicar a la vez el puerto 8080. Si no lo usas: task engine:stop -- {other}")
    return 0


def stop(engine: str) -> int:
    if engine == "docker":
        cmd = ["docker", "desktop", "stop"] if SYSTEM != "Linux" or shutil.which("docker-desktop") \
            else ["systemctl", "stop", "docker"]
        subprocess.run(cmd, check=False)
    elif SYSTEM != "Linux":
        subprocess.run(["podman", "machine", "stop"], check=False)
        # `podman machine stop` puede decir que paró sin haber parado (a02): se comprueba.
        if podman_machine_state() == "running":
            print("Aviso: la máquina de Podman sigue encendida aunque stop dijo que no. Ver a02.")
            return 1
    still = responds(engine)[0]
    print(f"{engine}: {'sigue respondiendo' if still else 'detenido'}.")
    return 1 if still else 0


def main(argv: list[str]) -> int:
    if not argv or argv[0] not in ("status", "use", "stop"):
        print(__doc__)
        return 2
    if argv[0] == "status":
        return status()
    if len(argv) < 2:
        print(f"Falta el motor: {argv[0]} docker|podman")
        return 2
    return use(argv[1]) if argv[0] == "use" else stop(argv[1])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
