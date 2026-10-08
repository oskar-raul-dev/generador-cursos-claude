# 🧵 ff07 — Paralelismo real: subintérpretes y sin GIL

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Durante treinta años, la respuesta a "quiero usar los ocho núcleos con código de Python" fue `multiprocessing`: procesos aparte, cada uno con su intérprete y su
GIL, y los datos serializados de ida y vuelta. Python 3.14 trae dos respuestas más, las dos oficiales: los **subintérpretes** (PEP 734), varios intérpretes
aislados dentro de un mismo proceso, cada uno con su propio GIL; y la **compilación sin GIL** (PEP 703, soportada desde la PEP 779), un CPython donde los hilos
corren Python en paralelo de verdad, como en la JVM.

El camino base midió la compilación sin GIL contra una carga real (`BENCHMARKS.md` §14: 2,27× con aritmética pura, 1,14× con la conciliación). Esta sección
pone las cuatro formas lado a lado con la misma carga de Python puro, en los dos intérpretes, y mide **qué se rompe**: lo que las promesas no dicen.

---

## 🧠 2. El modelo

| Forma | Paralelismo de Python puro | Comparte objetos | Costo de arrancar | Lo que exige |
|---|---|---|---|---|
| Hilos, con GIL | No | Sí | Mínimo | — |
| **Hilos, sin GIL (`3.14t`)** | **Sí** | Sí | Mínimo | Extensiones que declaren soporte sin GIL |
| Procesos | Sí | No: serializa | Alto (un intérprete por proceso) | `if __name__ == "__main__"` |
| **Subintérpretes** | **Sí**, un GIL por intérprete | No: serializa o comparte *buffers* | Medio | Extensiones que soporten varios intérpretes |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de la JVM es que hilos y paralelismo son lo mismo, y con `3.14t` por fin lo son también en Python. Lo que el instinto no ve es que el ecosistema de
Python se escribió durante treinta años **suponiendo** el GIL: una extensión de C que no declara que funciona sin él vuelve a encender el GIL al importarse, para
todo el proceso, con una advertencia y sin error. El intérprete sin GIL es tan paralelo como su extensión menos preparada.

---

## 💻 3. El ejemplo que corre

`paralelo.py` —la misma carga con las cuatro formas—:

```python
"""Cuatro tareas de Python puro: secuencial, hilos, procesos y subintérpretes, con y sin GIL."""

import os
import sys
import time
from concurrent.futures import InterpreterPoolExecutor, ProcessPoolExecutor, ThreadPoolExecutor


def work(seed):
    """Suavizado de una serie pseudoaleatoria generada en el momento: CPU pura, sin E/S ni NumPy."""
    s, x = 0.0, seed
    for _ in range(2_000_000):
        x = (x * 1103515245 + 12345) % 2**31
        s = 0.1 * x + 0.9 * s
    return s


def run(label, executor_cls=None):
    seeds = [1, 2, 3, 4]
    start = time.perf_counter()
    if executor_cls is None:
        results = [work(s) for s in seeds]
    else:
        with executor_cls(max_workers=4) as pool:
            results = list(pool.map(work, seeds))
    elapsed = time.perf_counter() - start
    return label, elapsed, results


if __name__ == "__main__":
    build = "sin GIL (3.14t)" if not sys._is_gil_enabled() else "con GIL"
    rows = [run("secuencial"), run("hilos", ThreadPoolExecutor), run("procesos", ProcessPoolExecutor),
            run("subintérpretes", InterpreterPoolExecutor)]
    base = rows[0][1]
    assert all(r[2] == rows[0][2] for r in rows)
    print(f"Python {sys.version.split()[0]} {build}, {os.cpu_count()} núcleos")
    for label, elapsed, _ in rows:
        print(f"  {label:<15} {elapsed:5.2f} s · {base / elapsed:4.2f}×")
```

`rompe.py` —una extensión de Cython sin declarar soporte sin GIL (el `ema_v3.pyx` de `ff03`), y NumPy dentro de un subintérprete—:

```python
"""Lo que se rompe: una extensión que no declara soporte sin GIL, y NumPy dentro de un subintérprete."""

import subprocess
import sys
from concurrent import interpreters

subprocess.run([sys.executable, "-m", "Cython.Build.Cythonize", "-q", "-i", "-3", "ema_v3.pyx"], check=True, capture_output=True)
print("GIL antes de importar la extensión:", sys._is_gil_enabled())
import ema_v3  # noqa: E402,F401
print("GIL después:", sys._is_gil_enabled())

interp = interpreters.create()
try:
    interp.exec("import numpy")
except interpreters.ExecutionFailed as error:
    original = error.excinfo.msg.strip().splitlines()[-1]          # el mensaje de NumPy culpa a la instalación; la causa está al final
    print("numpy en un subintérprete:", error.excinfo.type.__name__, "·", original)
finally:
    interp.close()
```

```bash
pip install uv
python3 paralelo.py                                            # el CPython de siempre, con GIL
uv python install 3.14.7t
uv run -p 3.14.7t --no-project python paralelo.py              # la compilación sin GIL
uv venv -p 3.14.7t /tmp/ft && uv pip install -p /tmp/ft/bin/python cython setuptools numpy
/tmp/ft/bin/python rompe.py                                    # con ema_v3.pyx en la carpeta
```

Salida (Python 3.14.7, 05/10/2026) (8 núcleos; los segundos son de la máquina que corre):

```text
Python 3.14.7 con GIL, 8 núcleos
  secuencial       1.25 s · 1.00×
  hilos            1.28 s · 0.98×
  procesos         0.39 s · 3.19×
  subintérpretes   0.37 s · 3.43×
Python 3.14.7 sin GIL (3.14t), 8 núcleos
  secuencial       1.26 s · 1.00×
  hilos            0.43 s · 2.93×
  procesos         0.42 s · 3.02×
  subintérpretes   0.39 s · 3.21×
<frozen importlib._bootstrap>:491: RuntimeWarning: The global interpreter lock (GIL) has been enabled to load module 'ema_v3', which has not declared that it can run safely without the GIL. To override this behavior and keep the GIL disabled (at your own risk), run with PYTHON_GIL=0 or -Xgil=0.
GIL antes de importar la extensión: False
GIL después: True
numpy en un subintérprete: ImportError · Original error was: module numpy._core._multiarray_umath does not support loading in subinterpreters
```

Con GIL, los hilos no ganan nada (0,98×), y procesos y subintérpretes dan algo más de 3× con cuatro tareas. Los **subintérpretes ganan a los procesos** (3,43 contra
3,19), porque arrancan más rápido. Sin GIL, los hilos pasan de 0,98× a **2,93×** sin cambiar una línea; y el intérprete sin GIL no cobra nada en secuencial
(1,26 contra 1,25 s), lo mismo que midió el camino base. Las tres últimas líneas son la letra chica: importar **una** extensión que no declaró soporte sin GIL
enciende el GIL para todo el proceso, con una advertencia; y NumPy, la biblioteca más usada del ecosistema, **no carga en un subintérprete**, con un mensaje que
empieza culpando a la instalación y dice la causa real en la última línea.

**Detalles con intención**

- **`InterpreterPoolExecutor`** (nuevo en 3.14, en `concurrent.futures`) tiene la misma interfaz que los otros dos ejecutores: cambiar de procesos a subintérpretes es
  cambiar una clase. Los argumentos y resultados viajan serializados, como entre procesos.
- **`work` no usa NumPy ni E/S**: es la carga donde el GIL más pesa. Con NumPy, el trabajo ya corre en C y suelta el GIL (`ff01`), y la comparación sería otra.
- **El `assert`** comprueba que las cuatro formas devuelven lo mismo: el paralelismo no cambió el resultado.
- **Cuatro tareas, 8 núcleos, ~3×** y no 4×: arrancar trabajadores y repartir cuesta, y con tareas de un tercio de segundo ese costo pesa.
- **`PYTHON_GIL=0`** fuerza el GIL apagado aunque la extensión no lo declare. Es "bajo tu riesgo" en serio: si la extensión tiene estado global sin proteger, se
  corrompe.

---

## ⚠️ 4. Lo que se rompe

**La extensión que enciende el GIL.** En `3.14t`, cualquier módulo de C sin la declaración (`Py_mod_gil`) lo vuelve a encender. Se revisa con
`sys._is_gil_enabled()` **después** de importar todo, en una prueba del CI, y se tratan las advertencias `RuntimeWarning` como errores.

**NumPy (y casi todo) en subintérpretes.** Una extensión tiene que soportar varios intérpretes de forma explícita, y la mayoría todavía no lo hace. Hoy los
subintérpretes sirven para Python puro y la biblioteca estándar.

**Las ruedas de `3.14t`.** La compilación sin GIL tiene su propia ABI (`cp314t`): cada paquete con código nativo necesita ruedas aparte. Las que no las publican se
compilan al instalar, o no se instalan.

**Las carreras que el GIL escondía.** Código de Python puro que "funcionaba" con hilos porque el GIL serializaba operaciones puede tener carreras de datos sin él. Los
contadores compartidos se protegen con `threading.Lock` aunque antes no hiciera falta.

---

## ⚖️ 5. Cuándo NO usarlos

**`3.14t` si dependes de extensiones sin soporte.** El GIL vuelve con la primera, y se paga la complejidad sin la ganancia.

**Subintérpretes con NumPy, pandas o casi cualquier extensión científica.** No cargan. Procesos.

**Para E/S.** Hilos o `asyncio` ya la paralelizan con el GIL (`BENCHMARKS.md` §14: 3,95×).

**Si el trabajo ya está en C.** NumPy, `hashlib` o tu extensión que suelta el GIL ya corren en paralelo con hilos normales.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `paralelo.py` en los dos intérpretes. **Criterio:** las dos tablas, y por qué los hilos cambian y los procesos no.
2. Corre `rompe.py` con `PYTHON_GIL=0`. **Criterio:** el GIL queda apagado, y explicas el riesgo.
3. Agrega `# cython: freethreading_compatible=True` a `ema_v3.pyx`. **Criterio:** la advertencia desaparece y el GIL sigue apagado.

**🟡 Intermedio (4–6)**

4. Repite la medición con 8 tareas y con 16. **Criterio:** cómo cambia la ganancia de cada forma.
5. Escribe un contador compartido incrementado por 4 hilos un millón de veces cada uno, en los dos intérpretes. **Criterio:** si pierde incrementos en alguno, y la
   corrección.
6. Lista qué paquetes de tu proyecto tienen ruedas `cp314t` en PyPI. **Criterio:** la lista, y los que no.

**🟠 Difícil (7–9)**

7. Pasa datos a un subintérprete con un `memoryview` compartido en vez de serializar. **Criterio:** el tiempo contra serializar un arreglo grande.
8. Mide un servicio FastAPI con `uvicorn` en `3.14t` con hilos de trabajo. **Criterio:** peticiones por segundo contra 3.14 con GIL, con una ruta de CPU pura.
9. Escribe una prueba de CI que importe todo el proyecto en `3.14t` y falle si el GIL se encendió. **Criterio:** la prueba, fallando con una extensión sin soporte.

**🔴 Muy difícil (10)**

10. Decide si un servicio con carga de CPU en Python pasa a `3.14t`, a subintérpretes o se queda en procesos. **Criterio:** una página. *Rúbrica:* (a) las mediciones
    con tu carga; (b) las extensiones del proyecto y su soporte; (c) las carreras que habría que revisar; (d) el plan si una dependencia enciende el GIL.

---

## 📚 7. Referencias

**Documentación oficial**

- PEP 734, subintérpretes en la biblioteca estándar: https://peps.python.org/pep-0734/
- PEP 779, criterios para el soporte de la compilación sin GIL: https://peps.python.org/pep-0779/
- Guía de Python sin GIL para mantenedores de extensiones: https://py-free-threading.github.io/

**Orden de lectura sugerido:** la guía de py-free-threading (el estado real del ecosistema); después la PEP 734, sobre qué se comparte entre subintérpretes.

---

## 🚀 8. Cierre

Python 3.14 tiene tres formas de usar varios núcleos con código de Python: procesos (3,19×), subintérpretes (3,43×) y, en `3.14t`, hilos (2,93×), sin costo en
secuencial. Las tres funcionan con Python puro. El límite es el ecosistema: una extensión sin soporte enciende el GIL para todo el proceso, y NumPy no carga en un
subintérprete. Se mide con la carga propia y se revisa cada dependencia antes de elegir.

**La señal de que quedó bien:** *"El CI importa todo en `3.14t` y verifica que el GIL siga apagado, y la decisión de paralelismo tiene sus números al lado."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-07 -m "op ff07 cerrada: procesos, subintérpretes y 3.14t medidos, y lo que se rompe"
> ```
>
> Los commits llevan su prefijo (`op ff07: …`) y los de ejercicio su número
> (`op ff07 ej07: …`).
