# 🔌 ff02 — ctypes y cffi

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 2 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Hay una biblioteca en C —la del lector de huellas, la de un fabricante, una que escribiste para otra cosa— y Python tiene que llamarla. En Java la respuesta era
JNI, con su código de pegamento en C y su compilación aparte, o, desde Java 22, la API de funciones y memoria foráneas (FFM). Python tiene dos formas de llamar a
una `.so` **sin compilar nada del lado de Python**: **`ctypes`**, en la biblioteca estándar, y **`cffi`**, el paquete que usan `cryptography` y buena parte del
ecosistema.

Esta sección las usa sobre la función caliente del track: un **suavizado exponencial** de dos millones de valores, un bucle donde cada resultado depende del
anterior y que NumPy no vectoriza. Mide tres cosas: cuánto gana el cálculo al cruzar a C, cuánto cuesta **cada cruce**, y qué pasa cuando el lado de C se
equivoca. Esto último es una experiencia nueva para quien viene de la JVM: no hay excepción, hay un proceso muerto.

---

## 🧠 2. El modelo

| | `ctypes` | `cffi` (modo ABI) |
|---|---|---|
| Dónde está | Biblioteca estándar | `pip install cffi` |
| Cómo se declara la firma | `argtypes` y `restype`, con objetos de Python | **El encabezado de C**, copiado en `ffi.cdef` |
| Qué se compila | Nada | Nada (en modo API, un módulo de extensión: más rápido y más seguro) |
| Si la firma está mal | Corrupción o *segfault* | Corrupción o *segfault* |
| Costo por llamada (medido abajo) | El más alto | Unas tres veces menos |

### Tu instinto de Java dice… y esta vez se equivoca

En la JVM, un error del código nativo de JNI también tumba el proceso, pero casi nadie escribe JNI: la JVM es un mundo cerrado y seguro, y una
`NullPointerException` se atrapa. El instinto traslada esa seguridad a Python. Con `ctypes` y `cffi`, una firma mal declarada o un puntero nulo no lanzan una
excepción: el proceso termina con la señal 11, sin `except` que lo detenga y, si no se activó `faulthandler`, sin una línea de *traceback*.

---

## 💻 3. El ejemplo que corre

`suavizado.c`:

```c
/* Suavizado exponencial: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1]. */
void ema(const double *x, double *out, long n, double alpha) {
    double s = x[0];
    for (long i = 0; i < n; i++) {
        s = alpha * x[i] + (1.0 - alpha) * s;
        out[i] = s;
    }
}

double add(double a, double b) { return a + b; }
```

`frontera_c.py` compila la biblioteca, la llama de las dos formas y mide:

```python
"""La misma función en Python y en C, llamada con ctypes y con cffi, y el primer segfault."""

import array
import ctypes
import math
import subprocess
import sys
import time

from cffi import FFI

subprocess.run(["gcc", "-O2", "-shared", "-fPIC", "-o", "libsuavizado.so", "suavizado.c"], check=True)

N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


def timed(fn):
    best = min(_once(fn) for _ in range(3))
    return f"{best * 1000:7.1f} ms"


def _once(fn):
    start = time.perf_counter(); fn(); return time.perf_counter() - start


# ctypes: se declara la firma a mano
lib = ctypes.CDLL("./libsuavizado.so")
lib.ema.argtypes = [ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double), ctypes.c_long, ctypes.c_double]
lib.ema.restype = None
lib.add.argtypes, lib.add.restype = [ctypes.c_double, ctypes.c_double], ctypes.c_double
out_c = array.array("d", bytes(8 * N))
as_ptr = lambda a: (ctypes.c_double * len(a)).from_buffer(a)


def ema_ctypes():
    lib.ema(as_ptr(x), as_ptr(out_c), N, ALPHA)


# cffi, modo ABI: la firma se copia del encabezado de C
ffi = FFI()
ffi.cdef("void ema(const double *x, double *out, long n, double alpha); double add(double a, double b);")
clib = ffi.dlopen("./libsuavizado.so")
out_f = array.array("d", bytes(8 * N))


def ema_cffi():
    clib.ema(ffi.from_buffer("double[]", x), ffi.from_buffer("double[]", out_f), N, ALPHA)


print(f"ema de {N:,} valores · Python {timed(lambda: ema_python(x, ALPHA))} · ctypes {timed(ema_ctypes)} · cffi {timed(ema_cffi)}")
ref = ema_python(x, ALPHA)
print("los tres coinciden:", max(abs(a - b) for a, b in zip(ref, out_c)) < 1e-9 and list(out_c) == list(out_f))

# El costo de cruzar: un millón de llamadas a una suma
calls = 1_000_000
py_add = lambda a, b: a + b
for name, f in (("Python", py_add), ("ctypes", lib.add), ("cffi", clib.add)):
    start = time.perf_counter()
    for _ in range(calls):
        f(1.0, 2.0)
    print(f"1M llamadas a add() · {name:<6} {(time.perf_counter() - start) * 1000:6.0f} ms")

# El primer segfault: leer la dirección 0
r = subprocess.run([sys.executable, "-X", "faulthandler", "-c", "import ctypes; ctypes.string_at(0)"],
                   capture_output=True, text=True)
print("código de salida:", r.returncode, "·", r.stderr.splitlines()[0])
```

```bash
pip install cffi                # y gcc: viene en la imagen python:3.14.7, no en la -slim
python3 frontera_c.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ema de 2,000,000 valores · Python   163.8 ms · ctypes     5.1 ms · cffi     5.2 ms
los tres coinciden: True
1M llamadas a add() · Python     53 ms
1M llamadas a add() · ctypes    497 ms
1M llamadas a add() · cffi      173 ms
código de salida: -11 · Fatal Python error: Segmentation fault
```

El suavizado baja de **163,8 ms a 5,1**: 32 veces, con una sola llamada que cruza la frontera y hace dos millones de iteraciones del otro lado. `ctypes` y `cffi`
empatan, porque el costo de la llamada se diluye. La segunda medición muestra lo contrario: un millón de llamadas a una suma trivial cuestan **53 ms en Python,
497 en `ctypes` y 173 en `cffi`**. Cruzar la frontera por cada elemento es **9 veces más caro** que no cruzarla. Y la última línea es el *segfault*: código de
salida −11, la señal SIGSEGV, sin excepción que atrapar.

**Detalles con intención**

- **`array.array("d")`** guarda los números como `double` de C contiguos, y `from_buffer` (en los dos) le pasa a C un puntero a esa memoria **sin copiar**. Con una
  lista de Python habría que convertir cada elemento, y la conversión costaría más que el cálculo (`ff06`).
- **`argtypes` y `restype`** son obligatorios en la práctica: sin ellos, `ctypes` supone `int` para todo, y un `double` pasado como `int` produce un resultado
  basura sin ningún error.
- **`ffi.cdef`** recibe el encabezado de C tal cual. Es la ventaja de `cffi`: la firma se copia de la documentación de la biblioteca en vez de traducirse a objetos de
  Python.
- **"Coinciden" es con tolerancia** (`< 1e-9`) contra Python, y exacto entre `ctypes` y `cffi`: el C compilado con `-O2` en ARM difiere de Python en 5,7e-13. Es
  gcc fusionando la multiplicación y la suma en una sola instrucción (FMA), que redondea una vez en vez de dos; con `-ffp-contract=off` la diferencia es 0,0.
- **`-X faulthandler`** hace que el intérprete imprima la pila de Python antes de morir. En producción se activa siempre que haya código nativo (`PYTHONFAULTHANDLER=1`).

---

## ⚠️ 4. Lo que se rompe

**La firma equivocada.** `long` en Linux de 64 bits mide 8 bytes y en Windows 4. Una firma copiada sin pensar funciona en un sistema y corrompe memoria en el otro.
Se usan los tipos de ancho fijo (`int64_t`, `ctypes.c_int64`).

**El *buffer* que se libera mientras C lo usa.** Si la biblioteca guarda el puntero para usarlo después (una retrollamada, un hilo propio) y Python libera el
`array`, C escribe en memoria que ya no es suya. Se mantiene una referencia viva mientras C la necesite.

**La llamada en el bucle caliente.** 497 ms por millón de llamadas en `ctypes`: llamar a C por cada elemento es peor que no llamarlo. Se mueve el bucle completo al
otro lado.

**El GIL suelto sin saberlo.** `ctypes` (con `CDLL`; `PyDLL` no) y `cffi` sueltan el GIL durante la llamada. Es lo que permite paralelizar con hilos, y también lo
que permite que dos hilos de Python entren a la vez en una biblioteca de C que no es segura para hilos y corrompan su estado. Se protege con un `threading.Lock`
o se lee la documentación de la biblioteca antes.

---

## ⚖️ 5. Cuándo NO usarlos

**Si la biblioteca ya tiene un paquete en PyPI.** Alguien ya escribió y probó el pegamento; se usa ese.

**Para una API de C grande y cambiante.** Cientos de funciones declaradas a mano en `argtypes` son cientos de lugares para equivocarse. Se genera el pegamento (`cffi`
en modo API, `pybind11`, `ff05`).

**Si el código nativo es tuyo y puede escribirse en otra cosa.** Cython, `numba` o Rust (`ff03`–`ff05`) dan tipos revisados al compilar; `ctypes` los revisa al morir.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las seis líneas, y por qué la llamada a `add` es más cara en C que en Python.
2. Quita `lib.add.restype` y llama `lib.add(1.0, 2.0)`. **Criterio:** el resultado basura, y por qué no hubo error.
3. Llama `strlen` de la biblioteca de C del sistema (`ctypes.CDLL(None)`). **Criterio:** la longitud de una cadena en `bytes`.

**🟡 Intermedio (4–6)**

4. Reescribe el ejemplo de `cffi` en **modo API** (`ffi.set_source` y `ffi.compile()`). **Criterio:** el costo por llamada de `add` comparado con el modo ABI.
5. Pasa una lista de Python en vez de `array.array` (convirtiendo con `(c_double * n)(*lista)`). **Criterio:** cuánto cuesta la conversión contra el cálculo.
6. Activa `faulthandler` con `PYTHONFAULTHANDLER=1` en un *script* que llama mal a una función. **Criterio:** la pila de Python en el error.

**🟠 Difícil (7–9)**

7. Agrega a `suavizado.c` una función que recibe una retrollamada de Python (`CFUNCTYPE`) y la llama por cada elemento. **Criterio:** el costo por elemento.
8. Llama a `ema` desde cuatro hilos de Python sobre cuatro series distintas. **Criterio:** la ganancia, y la prueba de que `ctypes` soltó el GIL.
9. Usa `ctypes` contra una biblioteca real del sistema (`libz`, `libsqlite3`). **Criterio:** una llamada útil funcionando, con su firma correcta.

**🔴 Muy difícil (10)**

10. Envuelve una biblioteca de C de diez funciones con `ctypes` y con `cffi`. **Criterio:** una página. *Rúbrica:* (a) las líneas de pegamento de cada una; (b) los
    errores que cometiste al declarar firmas y cómo los encontraste; (c) el costo por llamada medido; (d) cuál mantendrías dentro de dos años.

---

## 📚 7. Referencias

**Documentación oficial**

- `ctypes`: https://docs.python.org/3/library/ctypes.html
- `cffi`: https://cffi.readthedocs.io/en/stable/
- `faulthandler`: https://docs.python.org/3/library/faulthandler.html

**Orden de lectura sugerido:** el tutorial de `ctypes` hasta "Specifying the required argument types"; después la página de `cffi` sobre los modos ABI y API.

---

## 🚀 8. Cierre

`ctypes` y `cffi` llaman a C sin compilar nada del lado de Python. El cálculo que cruza una vez y trabaja del otro lado gana 32 veces; el que cruza por cada
elemento pierde 9. Y el error de C no es una excepción: es un proceso muerto, que `faulthandler` al menos deja explicado.

**La señal de que quedó bien:** *"La llamada a C ocurre una vez por lote, la firma usa tipos de ancho fijo, y el servicio corre con `PYTHONFAULTHANDLER=1`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-02 -m "op ff02 cerrada: ctypes y cffi, el cruce por lote y el primer segfault"
> ```
>
> Los commits llevan su prefijo (`op ff02: …`) y los de ejercicio su número
> (`op ff02 ej07: …`).
