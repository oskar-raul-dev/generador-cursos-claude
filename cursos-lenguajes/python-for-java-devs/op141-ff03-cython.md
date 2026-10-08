# 🐍 ff03 — Cython

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

`ctypes` (`ff02`) llama a una biblioteca de C que alguien ya escribió. Cuando la función caliente es tuya y está en Python, la pregunta es otra: ¿se puede hacer
rápida **sin reescribirla en C**? **Cython** es la respuesta más vieja y más usada: un compilador que traduce un dialecto de Python a C y lo compila como módulo
de extensión. Código de Python válido compila tal cual; cada anotación de tipos de C que se agrega saca una parte del trabajo del intérprete. Lo usan
scikit-learn, pandas, `lxml` y el propio SciPy.

La promesa habitual es "agrega tipos y obtienes velocidad de C". Esta sección la mide **paso a paso** sobre el suavizado exponencial del track: cuánto da compilar
sin tocar nada, cuánto cada anotación, y cuál de ellas no da nada aunque los tutoriales siempre la pongan.

---

## 🧠 2. El modelo

| Paso | Qué se anota | Qué deja de hacer el intérprete |
|---|---|---|
| 0 | Nada: el mismo `.py` compilado | Solo el despacho de *bytecode* |
| 1 | `cdef double`, `Py_ssize_t` para escalares | Crear un objeto `float` por cada operación |
| 2 | *Memoryviews* tipadas (`double[:]`) | Indexar la secuencia a través de objetos |
| 3 | `boundscheck(False)`, `wraparound(False)` | Revisar límites e índices negativos |

`cython -a` genera un HTML que pinta cada línea según cuántas llamadas a la API de C de CPython produce: blanco es C puro, amarillo es intérprete. Es la
herramienta para saber qué anotar.

### Esto sí funciona igual

La idea es la de un compilador AOT con tipos opcionales: donde hay tipos, el código es rápido; donde no, se comporta como el dinámico. Quien conoce cómo un JIT de la
JVM especializa por tipos reconoce lo que pasa, con una diferencia: aquí los tipos los escribe uno, y se compila antes de correr.

---

## 💻 3. El ejemplo que corre

`ema_v0.pyx` —Python sin tocar—:

```cython
# Paso 0: el mismo código de Python, sin una sola anotación.
def ema(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
```

`ema_v1.pyx`:

```cython
# Paso 1: tipos de C para los escalares.
def ema(x, double alpha):
    cdef double s = x[0], v
    cdef Py_ssize_t i
    out = [0.0] * len(x)
    for i in range(len(x)):
        v = x[i]
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
```

`ema_v2.pyx`:

```cython
# Paso 2: memoryviews tipadas; el bucle ya no toca objetos de Python.
from cpython cimport array
import array


def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    result = array.array("d", bytes(8 * n))
    cdef double[:] out = result
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return result
```

`ema_v3.pyx`:

```cython
# Paso 3: sin revisión de límites ni índices negativos.
cimport cython
from cpython cimport array
import array


@cython.boundscheck(False)
@cython.wraparound(False)
def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    result = array.array("d", bytes(8 * n))
    cdef double[:] out = result
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return result
```

`medir.py` compila los cuatro con el HTML de anotaciones y mide:

```python
"""El suavizado en Python y en cuatro pasos de Cython: tiempo, exactitud y cuánto Python queda en el cálculo."""

import array
import math
import re
import subprocess
import time

subprocess.run(["cythonize", "-q", "-i", "-3", "-a", "ema_v0.pyx", "ema_v1.pyx", "ema_v2.pyx", "ema_v3.pyx"],
               check=True, capture_output=True)
import ema_v0, ema_v1, ema_v2, ema_v3  # noqa: E401  — compilados recién


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))
reference = ema_python(x, ALPHA)
for name, fn in (("Python", ema_python), ("Cython paso 0", ema_v0.ema), ("Cython paso 1", ema_v1.ema),
                 ("Cython paso 2", ema_v2.ema), ("Cython paso 3", ema_v3.ema)):
    times = []
    for _ in range(3):
        start = time.perf_counter(); fn(x, ALPHA); times.append(time.perf_counter() - start)
    best = min(times)
    diff = max(abs(a - b) for a, b in zip(fn(x, ALPHA), reference))
    module = name.replace("Cython paso ", "ema_v")
    note = ""
    if module != "Python":
        html = open(f"{module}.html", encoding="utf-8").read()
        score = re.search(r'score-(\d+)"[^\n]*s = alpha', html).group(1)
        note = f" · interacciones con Python en la línea del cálculo: {score}"
    print(f"{name:<14} {best * 1000:7.1f} ms · diferencia máx. {diff:.1e}{note}")
```

```bash
pip install cython setuptools   # setuptools: cythonize -i lo necesita desde que Python 3.12 quitó distutils
python3 medir.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
Python           163.0 ms · diferencia máx. 0.0e+00
Cython paso 0    154.3 ms · diferencia máx. 0.0e+00 · interacciones con Python en la línea del cálculo: 12
Cython paso 1     75.5 ms · diferencia máx. 5.7e-13 · interacciones con Python en la línea del cálculo: 0
Cython paso 2      8.7 ms · diferencia máx. 5.7e-13 · interacciones con Python en la línea del cálculo: 2
Cython paso 3      8.6 ms · diferencia máx. 5.7e-13 · interacciones con Python en la línea del cálculo: 0
```

Compilar sin anotar da **5%**: el intérprete se va, pero los objetos se quedan. Tipar los escalares parte el tiempo a la mitad (75,5 ms): la cuenta ya es C, pero
leer `x[i]` y escribir `out[i]` sigue pasando por objetos de Python, en otras líneas. Las *memoryviews* dan el salto grande: **8,7 ms, 19 veces más rápido que
Python**. Y el paso 3, el de los decoradores que todos los tutoriales ponen, **no da nada medible** (8,6 contra 8,7): las dos interacciones que quita de la línea
del cálculo son la revisión del índice, una comparación que en un bucle así siempre da lo mismo y casi no cuesta. La diferencia de 5,7e-13 desde el paso 1 es el compilador de C
fusionando la multiplicación y la suma en una instrucción (FMA, `ff02`), no un error de Cython: compilado con `CFLAGS=-ffp-contract=off`, la diferencia es
0,0 y el paso 3 tarda **13,2 ms** en vez de 8,6. La FMA es más exacta y un 35% más rápida; lo que no es, es idéntica a Python.

**Detalles con intención**

- **`cythonize -a`** escribe el HTML de anotaciones; el puntaje de cada línea es el número de llamadas a la API de C de CPython que genera. La línea del cálculo pasa
  de 12 a 0.
- **`double[:]`** es una *memoryview* tipada: Cython lee la memoria del `array.array` directamente, con el protocolo de *buffers* (`ff06`), sin crear objetos.
- **El resultado es un `array.array`** y no una lista: llenar una lista obligaría a crear un `float` de Python por elemento, y el bucle volvería a tocar el intérprete.
- **8,7 ms contra los 5,1 del C de `ff02`**: la diferencia es reservar y llenar de ceros los 16 MB del resultado en cada llamada; el C de `ff02` recibía el arreglo ya
  creado.

---

## ⚠️ 4. Lo que se rompe

**`cythonize -i` sin `setuptools`.** Desde Python 3.12 no existe `distutils` en la biblioteca estándar, y la compilación en el lugar falla con
`ModuleNotFoundError: No module named 'distutils'`. Se instala `setuptools` o se compila con un `pyproject.toml` (`ff08`).

**Anotar a ciegas.** Los decoradores del paso 3 no dieron nada aquí, y quitan la revisión de límites: un índice equivocado ya no lanza `IndexError`, lee memoria ajena.
Se mira el HTML de `cython -a` y se mide antes de apagar una revisión.

**La extensión que ya no es para todos.** El `.pyx` compilado es un `.so` para una versión de Python y una plataforma. El paquete que era `pip install` en todas partes
ahora necesita ruedas por plataforma (`ff08`).

**El tipo que se desborda.** `cdef int` es un entero de C de 32 bits: el contador que en Python crecía sin límite, en Cython da la vuelta en silencio.

---

## ⚖️ 5. Cuándo NO usarlo

**Si la función se vectoriza con NumPy.** Una operación sobre el arreglo completo no necesita compilar nada (`ds01` del camino base).

**Si `numba` alcanza** (`ff04`): para un bucle numérico, un decorador sin paso de compilación ni archivos `.pyx`.

**Para código que cambia todas las semanas.** Cada cambio pasa por el compilador y por la construcción de ruedas; el costo de iterar sube.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre la medición y abre `ema_v1.html`. **Criterio:** las líneas amarillas del paso 1 y por qué siguen amarillas.
2. Agrega un paso que use `cdef int` como contador con `n = 3_000_000_000`. **Criterio:** qué pasa, y la corrección con `Py_ssize_t`.
3. Escribe el paso 1 en modo Python puro (`cython.double` en anotaciones, en un `.py`). **Criterio:** el mismo tiempo, y el `.py` corre también sin compilar.

**🟡 Intermedio (4–6)**

4. Haz que la función reciba el arreglo de salida ya creado, como el C de `ff02`. **Criterio:** el tiempo se acerca a 5 ms.
5. Pasa al paso 3 un índice fuera de rango a propósito (por ejemplo, `out[n]`). **Criterio:** qué pasa con y sin `boundscheck`.
6. Compila con `-ffp-contract=off` (variable `CFLAGS`). **Criterio:** la diferencia contra Python baja a cero, y explicas por qué el tiempo sube.

**🟠 Difícil (7–9)**

7. Suelta el GIL en el bucle del paso 3 (`with nogil:`) y corre la función en cuatro hilos sobre cuatro series. **Criterio:** la ganancia con hilos.
8. Arma un `pyproject.toml` que compile el `.pyx` con `setuptools` y construye la rueda. **Criterio:** la rueda, su etiqueta de plataforma y su tamaño.
9. Toma una función caliente tuya que no se vectoriza y llévala a Cython con los pasos de esta sección. **Criterio:** la tabla de tiempos por paso.

**🔴 Muy difícil (10)**

10. Decide si una biblioteca interna pasa a Cython. **Criterio:** una página. *Rúbrica:* (a) la ganancia medida por paso; (b) las plataformas que hay que construir y
    cómo; (c) qué se pierde en depuración y en iteración; (d) la alternativa sin compilar (`numba`, NumPy) y por qué no alcanzó.

---

## 📚 7. Referencias

**Documentación oficial**

- Cython: https://cython.readthedocs.io/en/latest/
- *Typed memoryviews*: https://cython.readthedocs.io/en/latest/src/userguide/memoryviews.html

**Libros**

- Kurt W. Smith, *Cython: A Guide for Python Programmers* (O'Reilly, 2015). Anterior a Cython 3, y su modelo sigue vigente.

**Orden de lectura sugerido:** el tutorial básico de Cython; después la página de *memoryviews*, que es donde está el salto de velocidad.

---

## 🚀 8. Cierre

Cython convierte Python en C de a una anotación. Medido sobre el suavizado: compilar sin anotar da 5%, tipar escalares 2 veces, las *memoryviews* 19 veces, y los
decoradores de los tutoriales nada. La herramienta que dice qué anotar es `cython -a`, y el costo que no aparece en la tabla es que el paquete ahora se construye
por plataforma.

**La señal de que quedó bien:** *"Cada anotación de Cython en el proyecto está ahí porque `cython -a` la pidió y una medición la justificó."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-03 -m "op ff03 cerrada: Cython anotado paso a paso, cada paso medido"
> ```
>
> Los commits llevan su prefijo (`op ff03: …`) y los de ejercicio su número
> (`op ff03 ej07: …`).
