# 🐚 sy01 — subprocess a fondo

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 1 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El cierre nocturno de Áurea llama a programas externos: `pg_dump` para el respaldo, el exportador de Odontovía que el proveedor
entrega como ejecutable, `gzip`, `rsync`. La Fase 05 del camino base enseñó `subprocess.run` para lo común. Este track empieza donde
lo común se rompe, y se rompe de formas que no dan error: el proceso que se queda colgado para siempre porque nadie leyó su salida,
el `timeout` que mata al hijo y deja al nieto corriendo, el nombre de archivo que se convierte en un comando.

Este perfil viene de `ProcessBuilder`, y la mitad de estas trampas existen también en Java; la otra mitad las trae la comodidad de
Python. La sección provoca las tres, con números, y muestra la corrección de cada una.

---

## 🧠 2. El modelo

| La trampa | Qué pasa | La corrección |
|---|---|---|
| **La tubería llena** | El hijo escribe más de lo que cabe en la tubería (64 KB en Linux), se bloquea esperando a que alguien lea, y el padre espera a que termine: interbloqueo | `communicate()` o `run(capture_output=True)`, que leen mientras esperan |
| **El nieto huérfano** | `timeout` mata al hijo; **todos** los procesos que el hijo lanzó siguen vivos | Un grupo de procesos propio (`start_new_session=True`) y matar el grupo |
| **La inyección de shell** | Con `shell=True`, un dato con `;` o `$(...)` se ejecuta como comando | Lista de argumentos, sin shell |

### Esto sí funciona igual

La tubería llena es exactamente el mismo problema que en Java con `Process.getInputStream()` sin consumir: el mismo búfer del sistema operativo, el
mismo interbloqueo. Quien lo sufrió con `ProcessBuilder` ya sabe la regla —leer mientras se espera— y en Python la aplica `communicate()`.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `trampas_subprocess.py`:

```python
"""Las tres trampas de subprocess provocadas y corregidas: tubería llena, nieto huérfano, inyección de shell."""

import os
import signal
import subprocess
import sys
import time


def sleepers() -> int:
    """Cuenta los procesos 'sleep 30' vivos, leyendo /proc (Linux)."""
    count = 0
    for pid in filter(str.isdigit, os.listdir("/proc")):
        try:
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                count += f.read().split(b"\0")[:2] == [b"sleep", b"30"]
        except OSError:
            pass
    return count


# ------------------------------------------------- 1. la tubería llena
big = [sys.executable, "-c", "print('x' * 200_000)"]           # 200 KB por la salida estándar
proc = subprocess.Popen(big, stdout=subprocess.PIPE)
try:
    proc.wait(timeout=2)
    print("wait(): terminó")
except subprocess.TimeoutExpired:
    print("wait(): bloqueado 2 s — el hijo espera que alguien lea, el padre espera que termine")
    proc.kill()
    proc.wait()
out, _ = subprocess.Popen(big, stdout=subprocess.PIPE).communicate(timeout=5)
print(f"communicate(): {len(out)} bytes leídos")

# ------------------------------------------------- 2. el nieto que sobrevive al timeout
try:
    subprocess.run(["sh", "-c", "sleep 30 & sleep 30"], timeout=1)
except subprocess.TimeoutExpired:
    time.sleep(0.2)
    print("run(timeout=1): procesos 'sleep 30' vivos después:", sleepers())
os.system("pkill -x sleep")                                     # limpieza del experimento

proc = subprocess.Popen(["sh", "-c", "sleep 30 & sleep 30"], start_new_session=True)
try:
    proc.wait(timeout=1)
except subprocess.TimeoutExpired:
    os.killpg(proc.pid, signal.SIGTERM)                         # todo el grupo, no solo el hijo
    proc.wait()
    time.sleep(0.2)
    print("grupo propio + killpg: procesos 'sleep 30' vivos después:", sleepers())

# ------------------------------------------------- 3. la inyección de shell
filename = "cierre-2026-10-05.csv; echo INYECTADO"              # un nombre que llegó de afuera
r1 = subprocess.run(f"echo procesando {filename}", shell=True, capture_output=True, text=True)
r2 = subprocess.run(["echo", "procesando", filename], capture_output=True, text=True)
print("shell=True:", r1.stdout.splitlines())
print("lista:     ", r2.stdout.splitlines())
```

```bash
python3 trampas_subprocess.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
wait(): bloqueado 2 s — el hijo espera que alguien lea, el padre espera que termine
communicate(): 200001 bytes leídos
run(timeout=1): procesos 'sleep 30' vivos después: 2
grupo propio + killpg: procesos 'sleep 30' vivos después: 0
shell=True: ['procesando cierre-2026-10-05.csv', 'INYECTADO']
lista:      ['procesando cierre-2026-10-05.csv; echo INYECTADO']
```

**Detalles con intención**

- **`proc.wait()` con `stdout=PIPE`** es el patrón que se bloquea: el hijo llena los 64 KB de la tubería y se detiene a esperar, y `wait` no lee. Con
  salidas chicas funciona, y por eso el error aparece en producción, el día que el exportador escribe más de lo habitual.
- **`run(timeout=…)`** mata al hijo (`sh`) y a nadie más: **los dos** `sleep 30` que `sh` lanzó —el de segundo plano y el que esperaba— quedan
  huérfanos y siguen corriendo. El borrador de esta sección esperaba uno; la corrida encontró dos, porque matar a `sh` no mata a ninguno de sus
  hijos. En un cierre nocturno, esos huérfanos se acumulan noche tras noche.
- **`start_new_session=True`** pone al hijo en su propia sesión y grupo de procesos, y `os.killpg` le manda la señal a todo el grupo, nietos incluidos.
- **La lista de argumentos** pasa el nombre de archivo como **un** argumento: el `;` es parte del nombre, no un separador de comandos.

---

## ⚠️ 4. Lo que se rompe

**`shell=True` "porque el comando tiene una tubería".** `gzip -c x | ssh ...` se puede hacer con dos `Popen` encadenados, o con `shell=True` y cada dato
pasado por `shlex.quote`. La segunda es aceptable si **todos** los datos van citados; un solo dato sin citar es la inyección.

**Los errores que no se miran.** `run(...)` sin `check=True` no lanza nada si el programa falla; el cierre sigue con un respaldo vacío. Se usa
`check=True`, o se lee `returncode` siempre.

**La salida que se decodifica mal.** `text=True` decodifica con la codificación del sistema; el exportador de un proveedor puede escribir en Latin-1.
Se fija `encoding=` cuando se sabe, o se recibe en `bytes` (`lg`).

**El entorno heredado.** El hijo hereda todo el entorno, incluidos los secretos (`se05`). Se le pasa `env=` con lo que necesita.

---

## ⚖️ 5. Cuándo NO usarlo

**Para lo que Python hace solo.** Copiar archivos (`shutil`), comprimir (`gzip`, `zipfile`), listar (`pathlib`): llamar a `cp` o `ls` desde Python agrega
un proceso y una dependencia del sistema por nada.

**Para un programa interactivo.** Si el programa externo hace preguntas, `subprocess` no alcanza: es el caso de `pexpect`.

**Cuando hay una biblioteca.** Llamar a `psql` para una consulta en vez de usar `psycopg` (`db01`) es parsear texto que un *driver* entregaría tipado.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas cada una de las seis líneas.
2. Cambia el tamaño de la salida a 60 000 y a 70 000 bytes. **Criterio:** encuentras el tamaño a partir del cual `wait()` se bloquea en tu sistema.
3. Repite la inyección con `shlex.quote(filename)` y `shell=True`. **Criterio:** el `echo INYECTADO` ya no se ejecuta.

**🟡 Intermedio (4–6)**

4. Encadena `gzip` y `wc -c` con dos `Popen` y una tubería entre ellos, sin `shell=True`. **Criterio:** el resultado coincide con el de la consola.
5. Lee la salida de un proceso largo línea por línea mientras corre. **Criterio:** imprimes cada línea apenas llega, sin esperar al final.
6. Haz que el exportador simulado falle con código 3 y que el cierre lo detecte con `check=True`. **Criterio:** la excepción y su `returncode`.

**🟠 Difícil (7–9)**

7. Escribe una función `run_with_timeout(cmd, seconds)` que siempre mate al grupo entero y devuelva la salida parcial. **Criterio:** una prueba con un nieto.
8. Lanza 50 procesos con un límite de 8 en paralelo y recoge sus salidas. **Criterio:** nunca hay más de 8 vivos, medido.
9. Mide el costo de lanzar un proceso: 1 000 veces `true` con `subprocess.run`. **Criterio:** milisegundos por proceso, y cuándo eso importa.

**🔴 Muy difícil (10)**

10. Revisa las llamadas a programas externos de un proceso tuyo (o del cierre de Áurea). **Criterio:** una tabla. *Rúbrica:* (a) cada llamada con su forma
    (`shell`, lista); (b) cómo se lee su salida; (c) qué pasa si se cuelga o deja nietos; (d) la corrección de las riesgosas.

---

## 📚 7. Referencias

**Documentación oficial**

- `subprocess`: https://docs.python.org/3/library/subprocess.html
- `subprocess`, consideraciones de seguridad: https://docs.python.org/3/library/subprocess.html#security-considerations
- `shlex.quote`: https://docs.python.org/3/library/shlex.html#shlex.quote

**Orden de lectura sugerido:** la sección de `Popen.communicate` y su advertencia sobre interbloqueos; después la de consideraciones de seguridad.

---

## 🚀 8. Cierre

`subprocess` tiene tres trampas que no dan error: la tubería llena que se bloquea para siempre (se lee mientras se espera con `communicate`), el nieto
que sobrevive al `timeout` (grupo propio y `killpg`) y la inyección de `shell=True` (lista de argumentos). Las tres se provocan en un minuto y se
corrigen con una línea.

**La señal de que quedó bien:** *"El cierre lleva meses sin colgarse, y no hay un solo `sleep` huérfano en el servidor."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-01 -m "op sy01 cerrada: tubería llena, nieto huérfano e inyección, provocados y corregidos"
> ```
>
> Los commits llevan su prefijo (`op sy01: …`) y los de ejercicio su número
> (`op sy01 ej07: …`).
