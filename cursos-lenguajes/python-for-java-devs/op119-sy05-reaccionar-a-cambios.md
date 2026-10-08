# 👀 sy05 — Reaccionar a cambios

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La aseguradora deja las autorizaciones de tratamiento en una carpeta compartida: un CSV por lote, cuando quiere, varias veces al día.
Áurea tiene que procesarlas apenas llegan, para que la recepción sepa qué está autorizado. La solución obvia es vigilar la carpeta y
reaccionar a cada archivo nuevo, y en Python la herramienta es **`watchdog`**, que usa los mecanismos del sistema (`inotify` en Linux,
FSEvents en macOS) para avisar sin preguntar cada segundo.

La trampa es la que el título del track adelanta: **el archivo que se leyó a medio copiar**. "Se creó un archivo" es el primer evento que
llega, y llega cuando la aseguradora apenas empezó a escribirlo. El manejador que lo lee en ese momento procesa la mitad de las
autorizaciones, y nadie se entera hasta que un paciente llega con una autorización que el sistema no tiene. La sección lo provoca y
muestra las dos salidas correctas.

---

## 🧠 2. El modelo

| Evento (Linux) | Cuándo llega | ¿El archivo está completo? |
|---|---|---|
| `created` | Al crear el archivo | **No**: puede estar vacío |
| `modified` | Con cada escritura | No: llega muchas veces durante la copia |
| `closed` (`IN_CLOSE_WRITE`) | Cuando quien escribía cierra el archivo | **Sí**, si escribió de una vez |
| `moved` (cambio de nombre) | Cuando se renombra hacia la carpeta | **Sí**, si el emisor escribió con otro nombre y renombró al final |

| Patrón | Quién lo aplica | Funciona en |
|---|---|---|
| Esperar `closed` | El receptor | Linux (`inotify`); no en macOS ni en carpetas de red |
| **Escribir con nombre temporal y renombrar** | El emisor | **Cualquier sistema**; es el contrato que se le pide a la aseguradora |
| Esperar a que el tamaño deje de cambiar | El receptor | Cualquiera; es una heurística, con un retraso |

### Tu instinto de Java dice… y esta vez se equivoca

Java tiene `WatchService`, y este perfil quizás lo usó con `ENTRY_CREATE`. La trampa es la misma en los dos lenguajes, y el instinto la resuelve con un
`Thread.sleep(1000)` antes de leer, "para darle tiempo". Un segundo alcanza para un archivo de diez filas y no para uno de cien mil copiado por una red
lenta; el `sleep` no es una solución sino una apuesta.

---

## 💻 3. El ejemplo que corre

```bash
uv add watchdog
```

`entrada.py`:

```python
"""La carpeta de la aseguradora: leer al 'crearse' lee a medias; 'closed' y el renombrado leen completo."""

import os
import pathlib
import threading
import time

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

INBOX = pathlib.Path("entrada")
INBOX.mkdir(exist_ok=True)
ROWS = 50_000
seen: dict[str, list[str]] = {"al crearse": [], "al cerrarse": [], "al renombrarse": []}


def count_rows(path: str) -> int:
    try:
        return max(sum(1 for _ in open(path)) - 1, 0)
    except FileNotFoundError:
        return -1


class Handler(FileSystemEventHandler):
    def on_created(self, event):
        if event.src_path.endswith(".csv"):
            seen["al crearse"].append(f"{pathlib.Path(event.src_path).name}: {count_rows(event.src_path)} filas")

    def on_closed(self, event):
        if event.src_path.endswith(".csv"):
            seen["al cerrarse"].append(f"{pathlib.Path(event.src_path).name}: {count_rows(event.src_path)} filas")

    def on_moved(self, event):
        if event.dest_path.endswith(".csv"):
            seen["al renombrarse"].append(f"{pathlib.Path(event.dest_path).name}: {count_rows(event.dest_path)} filas")


def insurer_writes(name: str, rename: bool):
    """La aseguradora copia el lote despacio, como por una red lenta."""
    target = INBOX / name
    path = target.with_suffix(".part") if rename else target
    with open(path, "w") as f:
        f.write("autorizacion,plan,valor\n")
        for i in range(ROWS):
            f.write(f"AUT-{i:06d},PL-{i % 300:03d},{150_000 + i}\n")
            if i % 5_000 == 0:
                f.flush()
                time.sleep(0.05)
    if rename:
        os.replace(path, target)


observer = Observer()
observer.schedule(Handler(), str(INBOX))
observer.start()
for name, rename in [("lote-1.csv", False), ("lote-2.csv", True)]:
    t = threading.Thread(target=insurer_writes, args=(name, rename))
    t.start()
    t.join()
time.sleep(1)
observer.stop()
observer.join()
for when, items in seen.items():
    print(f"{when:<15}", items)
```

```bash
python3 entrada.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
al crearse      ['lote-1.csv: 1 filas', 'lote-1.csv: 1 filas', 'lote-2.csv: 50000 filas']
al cerrarse     ['lote-1.csv: 50000 filas']
al renombrarse  ['lote-2.csv: 50000 filas']
```

Tres lecciones en tres líneas. El lote escrito con su nombre definitivo disparó `created` con **una** fila de cincuenta mil: el manejador ingenuo habría
procesado una autorización y descartado el resto. Además, `watchdog` entregó **dos** eventos `created` para el mismo archivo, que es la razón práctica
para que el procesamiento sea idempotente. El `closed` llegó con el archivo completo. Y el lote escrito como `.part` y renombrado llegó completo **por
los dos caminos**: el `moved`, y también un `created` del nombre definitivo, que aparece recién cuando el archivo ya está entero. Con el contrato del
renombrado, hasta un manejador ingenuo lee bien.

**Detalles con intención**

- **`lote-1.csv`** se escribe directamente con su nombre: el evento `created` llega con el archivo vacío (o casi), y el manejador que lee ahí procesa
  cero autorizaciones. El `closed` del mismo archivo llega al final, completo.
- **`lote-2.csv`** se escribe como `lote-2.part` y se renombra al terminar: el manejador ignora los `.part` y el `moved` hacia `.csv` llega con el archivo
  entero. Es el contrato que se le pide al emisor, y funciona en cualquier sistema.
- **`on_closed`** existe en `watchdog` para Linux (`inotify` tiene `IN_CLOSE_WRITE`); en macOS no se emite. El renombrado es la opción portátil.
- **El renombrado del emisor** es la escritura atómica de `sy04` vista desde el otro lado: el receptor nunca ve un archivo a medias.

---

## ⚠️ 4. Lo que se rompe

**Carpetas de red.** `inotify` no ve los cambios que otra máquina hace en una carpeta montada por SMB o NFS: los eventos no llegan. En ese caso,
`watchdog` tiene un observador por sondeo (`PollingObserver`) que revisa la carpeta cada tanto, con su costo y su retraso.

**El mismo archivo procesado dos veces.** `modified` llega muchas veces durante una copia, y un reinicio del vigilante vuelve a ver los archivos que ya
estaban. El procesamiento tiene que ser idempotente: mover el archivo procesado a otra carpeta, o registrar su *hash* (`wf`).

**El vigilante que se cae y nadie lo nota.** Si el proceso muere, los lotes se acumulan sin procesar. Se vigila con el latido de `au06` o se
complementa con un barrido periódico de la carpeta.

**El manejador lento.** Los eventos se procesan en el hilo del observador; un manejador que tarda bloquea a los siguientes. El manejador encola el
archivo y otro hilo o proceso lo procesa.

---

## ⚖️ 5. Cuándo NO usarlo

**Si los archivos llegan una vez al día.** Un trabajo programado que barre la carpeta a las 6:00 (`wf03`) es más simple y no tiene eventos perdidos.

**Si el emisor puede llamar a una API.** Una petición HTTP con el lote, o un mensaje en una cola (`db14`), dice cuándo está completo sin adivinar.

**Sobre carpetas de red sin sondeo.** Por lo de arriba.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas las tres líneas y cuántas filas habría procesado un manejador en `on_created`.
2. Cuenta cuántos eventos `modified` llegan durante la copia de `lote-1.csv`. **Criterio:** el número, y por qué no sirve para saber cuándo terminó.
3. Cambia `Observer` por `PollingObserver`. **Criterio:** los eventos que llegan y con cuánto retraso.

**🟡 Intermedio (4–6)**

4. Implementa el patrón "tamaño estable": procesa un archivo cuando su tamaño no cambió en 2 segundos. **Criterio:** lee completo `lote-1.csv`, y dices
   qué pasa si la copia se pausa 3 segundos.
5. Haz el manejador idempotente: mueve cada lote procesado a `procesados/`. **Criterio:** reiniciar el vigilante no procesa nada dos veces.
6. Encola los archivos en el manejador y procésalos en otro hilo. **Criterio:** diez lotes seguidos no bloquean el observador.

**🟠 Difícil (7–9)**

7. Monta la carpeta de entrada como volumen de Docker desde otro contenedor y vigila con `Observer` y con `PollingObserver`. **Criterio:** cuál ve los
   cambios.
8. Escribe el contrato para la aseguradora: nombre temporal, renombrado, y un archivo `.ok` de cierre. **Criterio:** el vigilante solo procesa lotes con
   `.ok`.
9. Combina el vigilante con un barrido cada 10 minutos que procesa lo que el vigilante no vio. **Criterio:** detener el vigilante 5 minutos no pierde
   lotes.

**🔴 Muy difícil (10)**

10. Diseña la recepción de autorizaciones de la aseguradora. **Criterio:** una página. *Rúbrica:* (a) el contrato que se le pide al emisor; (b) cómo se sabe
    que un lote está completo; (c) qué pasa si el vigilante se cae; (d) cómo se evita procesar un lote dos veces.

---

## 📚 7. Referencias

**Documentación oficial**

- `watchdog`: https://python-watchdog.readthedocs.io/en/stable/
- `inotify(7)`: https://man7.org/linux/man-pages/man7/inotify.7.html

**Orden de lectura sugerido:** la página de manual de `inotify` (la lista de eventos, en especial `IN_CLOSE_WRITE` e `IN_MOVED_TO`); después la guía de
`watchdog`.

---

## 🚀 8. Cierre

Vigilar una carpeta es fácil; saber cuándo un archivo está completo, no. `created` llega con el archivo vacío; `closed` llega completo en Linux; y el
contrato portátil es que el emisor escriba con otro nombre y renombre al final. El procesamiento es idempotente y un barrido periódico cubre lo que el
vigilante no vio.

**La señal de que quedó bien:** *"La aseguradora sube sus lotes con nombre temporal, y ninguna autorización se volvió a procesar a medias."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-05 -m "op sy05 cerrada: el archivo leído a medias y las dos formas de leerlo completo"
> ```
>
> Los commits llevan su prefijo (`op sy05: …`) y los de ejercicio su número
> (`op sy05 ej07: …`).
