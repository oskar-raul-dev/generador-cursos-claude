# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "httpx==0.28.1",
#     "selectolax==1.0.0",
# ]
# ///
"""Revisa las circulares de las prepagadas y manda un latido al monitor al terminar bien."""

import os
import sys
from pathlib import Path

import httpx


def read_secret(name: str) -> str:
    """systemd deja las credenciales en $CREDENTIALS_DIRECTORY, legibles solo por este servicio."""
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if directory:
        return (Path(directory) / name).read_text().strip()
    return os.environ[name.upper().replace("-", "_")]  # en desarrollo, desde el entorno


def heartbeat(status: str = "") -> None:
    url = os.environ.get("HEARTBEAT_URL")
    if not url:
        return
    # El latido nunca tumba la tarea: si el monitor está caído, el monitor avisará solo.
    try:
        httpx.post(f"{url}{status}", timeout=10)
    except httpx.HTTPError as error:
        print(f"no se pudo enviar el latido: {error}", file=sys.stderr)


def main() -> int:
    token = read_secret("portal-token")
    print(f"revisando circulares con un token de {len(token)} caracteres")
    # … aquí va el scraper de la sección au02 …
    heartbeat()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        heartbeat("/fail")
        raise
