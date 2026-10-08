"""El agente se inspecciona, crea y recoge un zombi, choca con el límite de archivos y maneja SIGTERM."""

import os
import resource
import signal
import time

import psutil

me = psutil.Process()
disk = psutil.disk_usage("/")
print(f"agente pid {me.pid}: memoria {me.memory_info().rss / 1e6:.0f} MB · disco libre {disk.free / 1e9:.1f} GB "
      f"({100 - disk.percent:.0f} %)")

# ------------------------------------------------- el zombi
child = os.fork()
if child == 0:
    os._exit(0)                                          # el hijo termina enseguida
time.sleep(0.2)
print("hijo sin recoger:", psutil.Process(child).status())
os.waitpid(child, 0)
print("después de waitpid:", "ya no existe" if not psutil.pid_exists(child) else "sigue")

# ------------------------------------------------- el límite de archivos abiertos
soft, hard = resource.getrlimit(resource.RLIMIT_NOFILE)
resource.setrlimit(resource.RLIMIT_NOFILE, (64, hard))   # como un servidor mal configurado
handles = []
try:
    while True:
        handles.append(open("/dev/null"))
except OSError as e:
    print(f"con límite 64: abrió {len(handles)} archivos y falló con errno {e.errno} ({os.strerror(e.errno)})")
for h in handles:
    h.close()
resource.setrlimit(resource.RLIMIT_NOFILE, (soft, hard))

# ------------------------------------------------- terminar en orden
stopping = False


def on_sigterm(signum, frame):
    global stopping
    stopping = True
    print("SIGTERM recibido: termino el lote actual y cierro")


signal.signal(signal.SIGTERM, on_sigterm)
os.kill(os.getpid(), signal.SIGTERM)                      # lo que haría 'systemctl stop' o 'docker stop'
for batch in range(1, 100):
    if stopping:
        print(f"cerrado en orden después del lote {batch - 1}")
        break
