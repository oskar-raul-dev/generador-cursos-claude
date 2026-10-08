# 🔍 sy03 — Inspección del sistema

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El agente que corre en el equipo de cada sede tiene que saber cosas de la máquina donde vive: si queda disco para el exporte de la
noche, cuánta memoria está usando, si un proceso hijo se quedó colgado, y cómo apagarse en orden cuando el sistema le pide que
termine. En Java, buena parte de eso lo resuelven JMX y la JVM; en Python se le pregunta al sistema operativo, y la herramienta es
**`psutil`**, más tres conceptos del sistema que este perfil probablemente nunca tuvo que tocar: **los límites de recursos**, **las
señales** y **el proceso zombi**.

Esta sección los muestra en un solo programa: el agente se inspecciona a sí mismo, crea un zombi a propósito y lo recoge, choca contra
el límite de archivos abiertos, y maneja un `SIGTERM` para terminar sin dejar el exporte a medias.

---

## 🧠 2. El modelo

| Pieza | Qué es | Desde Python |
|---|---|---|
| `psutil` 7.2.2 | Memoria, CPU, archivos abiertos, hijos, disco: de cualquier proceso y del sistema | `psutil.Process()`, `psutil.disk_usage("/")` |
| Límites de recursos | Topes del sistema por proceso: archivos abiertos, memoria, tiempo de CPU | `resource.getrlimit` / `setrlimit` (Unix) |
| Señales | Mensajes del sistema al proceso: `SIGTERM` (termina, por favor), `SIGKILL` (sin aviso), `SIGHUP` | `signal.signal(SIGTERM, handler)` |
| Proceso zombi | Un hijo que terminó y cuyo padre no recogió el estado | `os.waitpid` lo recoge |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, un *shutdown hook* (`Runtime.addShutdownHook`) se ejecuta al recibir `SIGTERM` y el instinto busca lo mismo. Python tiene `atexit`, pero
**`atexit` no corre con `SIGTERM`**: la señal, sin un manejador, termina el proceso sin ejecutar nada más. Para terminar en orden ante un
`systemctl stop` o un `docker stop`, se instala un manejador de `SIGTERM`.

---

## 💻 3. El ejemplo que corre

```bash
uv add psutil
```

`agente.py`:

```python
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
```

```bash
python3 agente.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
agente pid 10: memoria 13 MB · disco libre 973.1 GB (95 %)
hijo sin recoger: zombie
después de waitpid: ya no existe
con límite 64: abrió 61 archivos y falló con errno 24 (Too many open files)
SIGTERM recibido: termino el lote actual y cierro
cerrado en orden después del lote 0
```

**Detalles con intención**

- **El zombi** no ocupa memoria ni CPU, pero ocupa una entrada en la tabla de procesos. Un proceso que lanza hijos con `os.fork` (o `Popen` sin
  esperar) y nunca los recoge los acumula hasta que el sistema no puede crear procesos nuevos. `subprocess` los recoge al esperar; `os.fork`, no.
- **El límite de 64 archivos** abre menos de 64: la salida estándar, la de error, la entrada y los archivos que el propio Python tiene abiertos ya
  cuentan. `errno 24` (`EMFILE`) es el error que aparece en producción como "Too many open files", casi siempre por archivos o conexiones que no se
  cierran.
- **El manejador de `SIGTERM`** solo levanta una bandera: el trabajo se termina en el bucle principal, en un punto seguro. Hacer el trabajo dentro del
  manejador es peligroso, porque interrumpe al programa en cualquier línea.

---

## ⚠️ 4. Lo que se rompe

**`atexit` como plan de cierre.** No corre con `SIGTERM` ni con `SIGKILL`. Con `SIGTERM` se instala un manejador; con `SIGKILL` no hay nada que
hacer, y por eso el trabajo tiene que poder retomarse (`sy04`, escritura atómica).

**Trabajo pesado dentro del manejador de señales.** Escribir en una base o en un archivo desde el manejador puede ocurrir en medio de otra escritura.
La bandera y el bucle es el patrón seguro.

**Medir memoria con `rss` y concluir que hay una fuga.** El RSS incluye bibliotecas compartidas y cachés; para una fuga de Python, `tracemalloc`
(`ob05`).

**Código solo para Unix.** `os.fork`, `resource` y `SIGTERM` como aquí son de Unix. El agente que tiene que correr en el Windows de una sede usa solo
`psutil` (que sí es multiplataforma) y otro mecanismo de cierre.

---

## ⚖️ 5. Cuándo NO usarlo

**`psutil` para monitorear el servidor.** Para métricas del sistema en el tiempo, un exportador (`node_exporter`) y Prometheus (`ob03`); `psutil` es
para que el programa se mire a sí mismo o decida algo ("no hay disco, no exporto").

**`os.fork` para paralelismo.** `multiprocessing` o `concurrent.futures` (Fase 14 del camino base) manejan los hijos y los recogen.

**Subir los límites "por si acaso".** Si un proceso llega al límite de archivos, casi siempre hay algo que no se cierra; subir el límite esconde la
fuga un tiempo más.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas por qué abrió menos de 64 archivos.
2. Comenta el `os.waitpid` y lista los zombis con `psutil.process_iter`. **Criterio:** el zombi aparece con su padre.
3. Registra una función con `atexit` y envía `SIGTERM` sin manejador. **Criterio:** muestras que la función no corre.

**🟡 Intermedio (4–6)**

4. Haz que el agente se niegue a exportar si queda menos de 5 GB libres. **Criterio:** una prueba con `disk_usage` simulado.
5. Maneja `SIGHUP` para recargar la configuración sin reiniciar. **Criterio:** `kill -HUP` cambia un valor leído de un archivo.
6. Lista los archivos y conexiones abiertas del agente con `psutil`. **Criterio:** detectas una conexión que no se cerró.

**🟠 Difícil (7–9)**

7. Lanza 200 procesos con `Popen` sin esperarlos y mide los zombis. **Criterio:** cuántos quedan, y cómo los recoges.
8. Limita la memoria del agente con `RLIMIT_AS` y provoca un `MemoryError`. **Criterio:** el agente lo atrapa y termina en orden.
9. Prueba el cierre ordenado con `docker stop` en un contenedor. **Criterio:** el agente termina el lote antes de los 10 segundos del `SIGKILL`.

**🔴 Muy difícil (10)**

10. Diseña el agente de sede de Áurea desde el punto de vista del sistema. **Criterio:** una página. *Rúbrica:* (a) qué inspecciona y qué decide con eso;
    (b) cómo termina en orden y qué pasa con `SIGKILL`; (c) sus límites de recursos; (d) qué cambia en Windows.

---

## 📚 7. Referencias

**Documentación oficial**

- `psutil`: https://psutil.io/
- `signal`: https://docs.python.org/3/library/signal.html
- `resource`: https://docs.python.org/3/library/resource.html

**Libro**

- Michael Kerrisk, *The Linux Programming Interface* (No Starch Press, 2010). Los capítulos de procesos y señales son la referencia.

**Orden de lectura sugerido:** la documentación de `signal` (la sección sobre manejadores y el hilo principal); después la de `psutil`.

---

## 🚀 8. Cierre

`psutil` le deja al programa mirar la máquina y mirarse a sí mismo; los límites de recursos explican el "Too many open files"; el zombi es un hijo que
nadie recogió; y `SIGTERM` se maneja con una bandera para terminar en orden, porque `atexit` no corre. Es el oficio del sistema que la JVM hacía por
debajo.

**La señal de que quedó bien:** *"Reiniciamos el servidor de la sede a mitad del exporte, y el agente terminó el lote y cerró sin dejar archivos a
medias."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-03 -m "op sy03 cerrada: psutil, el zombi, el límite de archivos y SIGTERM en orden"
> ```
>
> Los commits llevan su prefijo (`op sy03: …`) y los de ejercicio su número
> (`op sy03 ej07: …`).
