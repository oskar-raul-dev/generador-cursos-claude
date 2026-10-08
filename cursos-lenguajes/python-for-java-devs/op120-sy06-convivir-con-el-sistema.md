# 🛎️ sy06 — Convivir con systemd

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 6 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7, en contenedor: el
> protocolo `sd_notify`, las señales y supervisord; y el 07/10/2026 la unidad de systemd, en un contenedor con systemd
> 257 como PID 1.

---

## 🎯 1. Qué problema resuelve

El vigilante de la carpeta de la aseguradora (`sy05`) y el agente de sede (`sy03`) son procesos que tienen que estar siempre
corriendo: arrancar con la máquina, reiniciarse si se caen, dejar sus bitácoras donde el administrador las busca, y avisar si se
colgaron aunque sigan vivos. En Java eso lo hacía el servidor de aplicaciones o un *wrapper*; en un servidor Linux moderno lo hace
**systemd**, y la pregunta para este perfil es qué tiene que hacer el programa de Python para convivir bien con él.

La respuesta es poco código y bastante contrato: una **unidad** que describe el servicio; escribir las bitácoras en la salida estándar
para que lleguen al **journal**; avisar con **`sd_notify`** cuando el servicio está listo y, periódicamente, que sigue vivo (el
*watchdog* de systemd); y manejar **`SIGTERM`** y **`SIGHUP`** (`sy03`). Donde no hay systemd —un contenedor, un servidor viejo—,
**supervisord** hace el papel de reiniciar.

---

## 🧠 2. El modelo

| Lo que el sistema necesita | En la unidad de systemd | En el programa de Python |
|---|---|---|
| Arrancar con la máquina | `WantedBy=multi-user.target` | Nada |
| Reiniciar si se cae | `Restart=on-failure`, `RestartSec=5` | Salir con código distinto de 0 si algo va mal |
| Saber cuándo está listo | `Type=notify` | Enviar `READY=1` por el *socket* de `NOTIFY_SOCKET` |
| Detectar que se colgó | `WatchdogSec=30` | Enviar `WATCHDOG=1` cada menos de 30 s |
| Bitácoras | `StandardOutput=journal` (por defecto) | Escribir en la salida estándar, sin rotar archivos |
| Terminar en orden | `KillSignal=SIGTERM`, `TimeoutStopSec=` | Manejar `SIGTERM` (`sy03`) |
| Recargar configuración | `ExecReload=kill -HUP $MAINPID` | Manejar `SIGHUP` |

`sd_notify` es un protocolo de diez líneas: un mensaje de texto (`READY=1`) por un *socket* Unix de datagramas cuya ruta llega en la
variable de entorno `NOTIFY_SOCKET`. Los paquetes que lo envuelven (`sdnotify` 0.3.2, sin versiones desde 2017, 💤; `systemd-python` 235,
desde 2023, 💤) están detenidos; escribirlo es más simple que depender de ellos.

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien viene de servidores Java es que el programa maneje sus propios archivos de bitácora con rotación (Logback, `RollingFileAppender`)
y su propio reinicio. Con systemd, las dos cosas sobran y estorban: el programa escribe en la salida estándar y el journal guarda, rota y consulta
(`journalctl -u`); systemd reinicia. Un programa que rota sus propios archivos pelea con el sistema.

---

## 💻 3. El ejemplo que corre

La unidad, `/etc/systemd/system/aurea-vigilante.service`:

```ini
[Unit]
Description=Vigilante de la carpeta de la aseguradora
After=network-online.target

[Service]
Type=notify
User=aurea
ExecStart=/opt/aurea/.venv/bin/python -m aurea.vigilante
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
WatchdogSec=30
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload && sudo systemctl enable --now aurea-vigilante
journalctl -u aurea-vigilante -f
```

El servicio, `vigilante.py`, con `sd_notify` escrito a mano:

```python
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
```

`probar_vigilante.py` hace de systemd: crea el *socket*, arranca el servicio con `NOTIFY_SOCKET`, le manda `SIGHUP` y `SIGTERM`, y muestra lo que el
servicio le avisó:

```python
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
```

Y donde no hay systemd, `supervisord.conf` reinicia el servicio cuando sale con error:

```ini
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log

[program:vigilante]
command=python vigilante.py
environment=AUREA_FALLAR="1"
autorestart=unexpected
startsecs=0
startretries=3
stdout_logfile=/tmp/vigilante.log
```

```bash
python3 probar_vigilante.py
timeout 6 supervisord -c supervisord.conf; grep -c "error irrecuperable" /tmp/vigilante.log
```

Salida (Python 3.14.7, 05/10/2026):

```text
avisos recibidos: ['READY=1', 'STOPPING=1', 'WATCHDOG=1'] · WATCHDOG: 5
salida (lo que vería el journal): ['<6>vigilante arrancando', '<6>configuración recargada', '<6>terminando en orden después de 5 ciclos']
código de salida: 0
3
INFO spawned: 'vigilante' with pid 14
WARN exited: vigilante (exit status 1; not expected)
INFO spawned: 'vigilante' with pid 15
WARN exited: vigilante (exit status 1; not expected)
INFO spawned: 'vigilante' with pid 16
```

El servicio avisó que estaba listo, mandó cinco latidos de *watchdog*, recargó la configuración con `SIGHUP` (el intervalo bajó a la mitad, por eso
alcanzó cinco ciclos) y terminó en orden con `SIGTERM`, con código 0, avisando `STOPPING=1`. Su salida son tres líneas con nivel, que es todo lo que el
journal necesita. Y con `AUREA_FALLAR`, supervisord lo vio salir con 1 —"not expected"— y lo volvió a lanzar: tres salidas con error en los seis segundos
de la prueba, cada una seguida de un proceso nuevo.

**Y bajo systemd de verdad (07/10/2026).** Con la unidad instalada en un contenedor con systemd 257 como PID 1:
`systemctl start` volvió recién cuando llegó el `READY=1` (`ActiveState=active`, `WatchdogUSec=30s`), `systemctl
reload` llegó como `SIGHUP`, y con `AUREA_FALLAR=1` el servicio salió con 1 y `Restart=on-failure` lo relanzó a los
cinco segundos. Después se congeló el proceso con `kill -STOP` —vivo, pero sin mandar latidos— y pasó esto (extracto del journal, sin las líneas `Starting` y `Started`):

```text
python[353]: vigilante arrancando
systemd[1]: aurea-vigilante.service: Watchdog timeout (limit 30s)!
systemd[1]: aurea-vigilante.service: Killing process 353 (python) with signal SIGABRT.
systemd[1]: aurea-vigilante.service: Main process exited, code=killed, status=6/ABRT
systemd[1]: aurea-vigilante.service: Failed with result 'watchdog'.
systemd[1]: aurea-vigilante.service: Scheduled restart job, restart counter is at 1.
python[361]: vigilante arrancando
systemd[1]: Stopping aurea-vigilante.service - Vigilante de la carpeta de la aseguradora...
python[361]: terminando en orden después de 19 ciclos
```

El proceso colgado no murió solo: lo mató el *watchdog* a los 30 segundos y la unidad lo reinició, que es exactamente
lo que ningún monitor de "¿está vivo el proceso?" habría detectado. Y las líneas con `<3>` llegaron al journal con
`PRIORITY=3`, así que `journalctl -u aurea-vigilante -p err` las encuentra sin mirar el texto.

**Detalles con intención**

- **`<6>` y `<3>` al principio de la línea** son los niveles de *syslog* (información, error). El journal los entiende si la unidad tiene
  `SyslogLevelPrefix=true` (el valor por defecto), y `journalctl -p err` filtra solo los errores. Es todo lo que necesita una bitácora para el journal:
  sin archivos ni rotación.
- **`PYTHONUNBUFFERED=1`** en la unidad (o `flush=True`): sin él, la salida estándar de Python va por un búfer cuando no es una terminal, y las líneas
  llegan al journal tarde o se pierden si el proceso muere.
- **`sd_notify` sin `NOTIFY_SOCKET` no hace nada**: el mismo programa corre a mano, en una prueba o bajo systemd.
- **`WatchdogSec=30`**: si el servicio deja de mandar `WATCHDOG=1` durante 30 segundos —porque se colgó, no porque murió—, systemd lo mata y lo reinicia.
  Es lo único que detecta un proceso vivo pero inútil.

---

## ⚠️ 4. Lo que se rompe

**`Type=simple` con un servicio que tarda en estar listo.** systemd lo da por arrancado apenas lanza el proceso, y los servicios que dependen de él
arrancan antes de tiempo. `Type=notify` con `READY=1` resuelve el orden.

**El *watchdog* enviado desde un hilo aparte.** Si un hilo manda `WATCHDOG=1` cada 10 segundos mientras el hilo principal está colgado, el *watchdog* no
detecta nada. El aviso se manda desde el bucle que hace el trabajo.

**`Restart=always` con un error de configuración.** El servicio falla al arrancar, systemd lo reinicia, falla de nuevo… hasta el límite de reinicios
(`StartLimitBurst`). Se distingue un error recuperable (salir con 1 y reintentar) de uno de configuración (salir con un código que la unidad marque como
no reiniciable, `RestartPreventExitStatus=`).

**El servicio corriendo como `root`.** Sin `User=`, corre como `root`. Un servicio que lee archivos de una carpeta compartida no necesita esos permisos (`se01`).

---

## ⚖️ 5. Cuándo NO usarlo

**Dentro de un contenedor.** El contenedor ya tiene su supervisor (Docker, Kubernetes) que reinicia y recoge la salida estándar; systemd adentro es una capa de
más. El programa escribe en la salida estándar y maneja `SIGTERM`, igual.

**`python-daemon` y el "doble *fork*".** La forma vieja de hacer un demonio en Unix (separarse de la terminal, escribir un archivo PID) es exactamente lo que
systemd ya no necesita: con `Type=notify` o `Type=simple`, el programa corre en primer plano.

**supervisord en un servidor con systemd.** Dos supervisores para el mismo proceso. supervisord tiene sentido donde no hay systemd.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `probar_vigilante.py`. **Criterio:** explicas cada aviso recibido y cada línea de salida.
2. Quita `flush=True` de los `print` y corre el servicio con la salida redirigida. **Criterio:** qué pasa con las líneas si el proceso recibe `SIGKILL`.
3. Corre el servicio sin `NOTIFY_SOCKET`. **Criterio:** funciona igual, sin errores.

**🟡 Intermedio (4–6)**

4. Haz que el servicio mande `STATUS=procesando lote-2.csv` (lo muestra `systemctl status`). **Criterio:** el mensaje llega al *socket* de prueba.
5. Cuelga el bucle principal (un `sleep` largo) y verifica que dejan de llegar `WATCHDOG=1`. **Criterio:** lo muestra la prueba.
6. Corre la configuración de supervisord y cuenta los reinicios en su bitácora. **Criterio:** se detiene después de `startretries`.

**🟠 Difícil (7–9)**

7. Instala la unidad en una máquina virtual con systemd (o un contenedor con systemd como PID 1). **Criterio:** `systemctl status` muestra el servicio listo,
   y matarlo con `kill -STOP` dispara el reinicio por *watchdog*.
8. Agrega `RestartPreventExitStatus=78` y haz que un error de configuración salga con 78. **Criterio:** systemd no lo reinicia.
9. Endurece la unidad con `ProtectSystem=strict`, `ReadWritePaths=` y `NoNewPrivileges=yes`. **Criterio:** el servicio sigue funcionando, y explicas qué
   protege cada línea.

**🔴 Muy difícil (10)**

10. Escribe las unidades de los servicios de Áurea (vigilante, agente de sede, cierre programado con un *timer*). **Criterio:** los archivos y una página.
    *Rúbrica:* (a) tipo de servicio y aviso de listo; (b) reinicio y *watchdog*; (c) usuario y endurecimiento; (d) cómo se consultan sus bitácoras.

---

## 📚 7. Referencias

**Documentación oficial**

- `systemd.service(5)`: https://man7.org/linux/man-pages/man5/systemd.service.5.html
- `sd_notify(3)`: https://man7.org/linux/man-pages/man3/sd_notify.3.html
- supervisord: https://supervisord.org/

**Orden de lectura sugerido:** la página de `systemd.service` (las opciones `Type`, `Restart` y `WatchdogSec`); después `sd_notify`.

---

## 🚀 8. Cierre

Convivir con systemd es un contrato pequeño: una unidad que describe el servicio, bitácoras en la salida estándar para el journal, `READY=1` y `WATCHDOG=1`
por `sd_notify` (diez líneas, sin dependencias), `SIGTERM` para terminar y `SIGHUP` para recargar. systemd arranca, reinicia y detecta el proceso colgado;
donde no está, supervisord reinicia.

**La señal de que quedó bien:** *"El vigilante se colgó una madrugada por un archivo malformado, y systemd lo reinició a los treinta segundos sin que nadie se
despertara."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-06 -m "op sy06 cerrada: la unidad, el journal y sd_notify escrito a mano"
> ```
>
> Los commits llevan su prefijo (`op sy06: …`) y los de ejercicio su número
> (`op sy06 ej07: …`).
