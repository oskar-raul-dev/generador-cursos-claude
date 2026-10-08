"""Un servicio que convive con systemd: READY, WATCHDOG, SIGHUP para recargar y SIGTERM para terminar."""

import os
import signal
import socket
import sys
import time


def sd_notify(message: str) -> bool:
    """El protocolo entero: un datagrama al socket de NOTIFY_SOCKET. Sin systemd, no hace nada."""
    address = os.environ.get("NOTIFY_SOCKET")
    if not address:
        return False
    if address.startswith("@"):                           # socket abstracto de Linux
        address = "\0" + address[1:]
    with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM) as s:
        s.sendto(message.encode(), address)
    return True


config = {"intervalo": 0.2}
stopping = False


def on_term(signum, frame):
    global stopping
    stopping = True


def on_hup(signum, frame):
    config["intervalo"] = 0.1
    print("<6>configuración recargada", flush=True)        # <6> = info, para el journal


signal.signal(signal.SIGTERM, on_term)
signal.signal(signal.SIGHUP, on_hup)
print("<6>vigilante arrancando", flush=True)
sd_notify("READY=1")
cycles = 0
while not stopping:
    time.sleep(config["intervalo"])
    sd_notify("WATCHDOG=1")
    cycles += 1
    if os.environ.get("AUREA_FALLAR") and cycles == 3:
        print("<3>error irrecuperable, salgo con 1 para que me reinicien", flush=True)   # <3> = error
        sys.exit(1)
sd_notify("STOPPING=1")
print(f"<6>terminando en orden después de {cycles} ciclos", flush=True)
