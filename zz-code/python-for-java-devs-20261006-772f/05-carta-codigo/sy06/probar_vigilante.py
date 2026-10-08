"""Hacer de systemd: recibir los avisos de sd_notify y mandar las señales."""

import os
import signal
import socket
import subprocess
import sys
import time

path = "/tmp/notify.sock"
if os.path.exists(path):
    os.remove(path)
sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
sock.bind(path)
sock.settimeout(2)

proc = subprocess.Popen([sys.executable, "vigilante.py"], env={**os.environ, "NOTIFY_SOCKET": path},
                        stdout=subprocess.PIPE, text=True)
messages = [sock.recv(64).decode() for _ in range(3)]
proc.send_signal(signal.SIGHUP)
time.sleep(0.3)
proc.send_signal(signal.SIGTERM)
out, _ = proc.communicate(timeout=5)
while True:
    try:
        messages.append(sock.recv(64).decode())
    except TimeoutError:
        break
print("avisos recibidos:", sorted(set(messages)), "· WATCHDOG:", messages.count("WATCHDOG=1"))
print("salida (lo que vería el journal):", out.splitlines())
print("código de salida:", proc.returncode)
