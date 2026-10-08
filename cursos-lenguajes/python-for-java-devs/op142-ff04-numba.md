# ⚡ ff04 — numba

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 4 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Cython (`ff03`) pide archivos `.pyx`, un paso de compilación y ruedas por plataforma. **numba** pide un decorador. Compila la función a código de máquina con LLVM
la primera vez que se llama, especializada para los tipos de los argumentos que recibió: es lo más parecido al JIT de la JVM que hay en Python. Para un bucle
numérico sobre arreglos de NumPy, el resultado se parece al de C.

El "para un bucle numérico" es la letra chica, y esta sección la mide: cuánto cuesta la primera llamada (que compila), qué guarda el caché en disco, qué da
paralelizar con `prange`, y qué código de Python perfectamente válido numba se niega a compilar.

---

## 🧠 2. El modelo

| | JIT de la JVM (HotSpot) | numba |
|---|---|---|
| Qué compila | Todo el *bytecode* caliente, solo | Las funciones con `@njit`, y solo esas |
| Cuándo | Después de miles de llamadas, en segundo plano | **En la primera llamada**, bloqueando |
| Para qué tipos | Los que observa; desoptimiza si cambian | Los de los argumentos; una versión por combinación |
| Qué acepta | Todo Java | Un subconjunto: números, arreglos de NumPy, tuplas, algunas estructuras |
| Caché entre ejecuciones | No (salvo CDS/AOT) | `cache=True`, en `__pycache__` |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de la JVM es que el JIT acelera "el programa". numba acelera **una función**, y solo si todo lo que esa función toca está en su subconjunto. Un
`Decimal`, un `dict` de objetos o una expresión generadora bastan para que no compile. No hay calentamiento ni desoptimización: o la función entra completa en
el subconjunto, o falla al llamarla.

---

## 💻 3. El ejemplo que corre

`jit.py`:

```python
"""numba sobre el suavizado: el costo de compilar, el caché en disco, prange y lo que no compila."""

import os
import time
from decimal import Decimal

import numpy as np
from numba import njit, prange
from numba.core.errors import NumbaError


@njit(cache=True)
def ema(x, alpha):
    out = np.empty_like(x)
    s = x[0]
    for i in range(x.shape[0]):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return out


@njit(parallel=True, cache=True)
def ema_many(series, alpha):
    out = np.empty_like(series)
    for k in prange(series.shape[0]):          # cada serie es independiente: esas sí se reparten
        s = series[k, 0]
        for i in range(series.shape[1]):
            s = alpha * series[k, i] + (1 - alpha) * s
            out[k, i] = s
    return out


def ms(fn):
    start = time.perf_counter(); fn(); return (time.perf_counter() - start) * 1000


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
print(f"primera llamada (compila o lee el caché): {ms(lambda: ema(x, ALPHA)):7.1f} ms")
print(f"segunda llamada:                         {min(ms(lambda: ema(x, ALPHA)) for _ in range(3)):7.1f} ms")

series = np.tile(x, (8, 1))
ema_many(series, ALPHA)
one_by_one = min(ms(lambda: [ema(s, ALPHA) for s in series]) for _ in range(3))
parallel = min(ms(lambda: ema_many(series, ALPHA)) for _ in range(3))
print(f"8 series · una tras otra {one_by_one:6.1f} ms · prange en {os.cpu_count()} núcleos {parallel:6.1f} ms ({one_by_one / parallel:.1f}×)")


@njit
def total_with_generator(amounts):
    return sum(a for a in amounts)               # Python válido; numba no compila generadores aquí


@njit
def total_exact(amounts):
    total = Decimal(0)                           # un objeto de Python que numba no conoce
    for a in amounts:
        total += Decimal(a)
    return total


for fn in (total_with_generator, total_exact):
    try:
        fn(np.array([1.0, 2.0]))
    except NumbaError as error:
        reason = next(l for l in str(error).splitlines()[1:] if l.strip())
        print(f"{fn.__name__} no compila: {reason.strip()[:80]}")
```

```bash
pip install numba
python3 -X importtime -c "import numba" 2>&1 | tail -1
python3 jit.py                                   # la primera vez: compila
python3 jit.py | head -1                         # la segunda: lee el caché de __pycache__
```

Salida (Python 3.14.7, 05/10/2026) (8 núcleos; los milisegundos son de la máquina que corre):

```text
import time:       504 |     150740 | numba
primera llamada (compila o lee el caché):   186.1 ms
segunda llamada:                             4.5 ms
8 series · una tras otra   42.7 ms · prange en 8 núcleos    7.5 ms (5.7×)
total_with_generator no compila: The use of yield in a closure is unsupported.
total_exact no compila: Untyped global name 'Decimal': Cannot determine Numba type of <class 'type'>
primera llamada (compila o lee el caché):    88.2 ms
```

La función compilada tarda **4,5 ms**: lo mismo que el C de `ff02` (5,1) y la mitad que el mejor Cython de `ff03` (8,6), con un decorador y sin compilar nada a
mano. El precio está alrededor: `import numba` cuesta **151 ms**, la primera llamada **186 ms** porque compila, y con el caché en disco la primera llamada del
proceso siguiente baja a 88 ms, no a 4,5 (cargar y verificar lo compilado también cuesta). `prange` reparte ocho series independientes en 5,7 veces menos
tiempo. Y las dos últimas líneas son el límite: una expresión generadora —Python de todos los días— y un `Decimal` no compilan.

**Detalles con intención**

- **`@njit`** es `@jit(nopython=True)`: si algo no entra en el subconjunto, falla en vez de caer en silencio a un modo lento. Desde numba 0.59 es el único
  comportamiento.
- **`np.empty_like`** reserva el resultado sin llenarlo de ceros, dentro de la función compilada; por eso no aparece el costo de reservar que tenía Cython.
- **`prange`** paraleliza el bucle de afuera, el de las series, que son independientes. El de adentro no se puede: cada valor depende del anterior.
- **El resultado es idéntico al de Python**, bit a bit: numba no fusiona multiplicación y suma (FMA) salvo que se le pida con `fastmath=True`, a diferencia del C de
  `ff02` y `ff03` (comprobado aparte, con la misma serie).
- **El 5,7× en 8 núcleos** y no 8×: las ocho series de 16 MB compiten por el ancho de banda de memoria, y repartir el trabajo tiene su costo.

---

## ⚠️ 4. Lo que se rompe

**El primer llamado en el camino de un usuario.** 186 ms de compilación más 151 de importación en la primera petición de un servicio, o en cada ejecución de un
*script* corto. Se compila al arrancar (una llamada de calentamiento) o se usa `cache=True`, sabiendo que el caché no lleva el costo a cero.

**El caché que se invalida.** El caché depende del archivo fuente, la versión de numba y la CPU. Un contenedor que se reconstruye, o una imagen construida en una
máquina y ejecutada en otra con distinto procesador, recompila.

**La función que dejó de compilar con un cambio pequeño.** Agregar un `Decimal`, un `logging.info` o una expresión generadora a una función con `@njit` la rompe en
la siguiente llamada, no al importar. Se prueba cada función compilada con un *test* que la llama.

**numba atrás de Python.** numba depende de LLVM y de los internos de CPython; cada versión nueva de Python tarda en tener soporte. Hoy cubre 3.14; el día que salga
3.15, el proyecto que la usa espera.

---

## ⚖️ 5. Cuándo NO usarlo

**Si el código no es numérico.** Cadenas, diccionarios de objetos, E/S: numba no los compila o no los acelera.

**En *scripts* que corren menos de un segundo.** 151 ms de importación y la compilación se comen la ganancia.

**Si NumPy ya lo vectoriza.** Una operación de arreglo completo no necesita JIT.

**Si el código tiene que correr en PyPy, GraalPy o sin NumPy.** numba es CPython con NumPy.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo dos veces. **Criterio:** las líneas, y qué archivos aparecieron en `__pycache__`.
2. Llama `ema` con un arreglo de `float32`. **Criterio:** la primera llamada vuelve a compilar; `ema.signatures` muestra las dos versiones.
3. Reescribe `total_with_generator` con un bucle. **Criterio:** compila.

**🟡 Intermedio (4–6)**

4. Mide el tiempo de compilación con `NUMBA_DEBUG_CACHE=1` y sin caché. **Criterio:** cuánto tarda en compilar, cuánto en cargar del caché.
5. Usa `@vectorize` para una función elemento a elemento (por ejemplo, la mora diaria de un saldo). **Criterio:** se comporta como un *ufunc* de NumPy.
6. Compila con firma explícita (`@njit("float64[:](float64[:], float64)")`). **Criterio:** la compilación ocurre al importar, no al llamar.

**🟠 Difícil (7–9)**

7. Compara `prange` con cuatro hilos de Python llamando a `ema` con `nogil=True`. **Criterio:** los dos tiempos y cuál es más simple.
8. Mide el arranque de un servicio FastAPI que importa una función con `@njit` y la calienta al iniciar. **Criterio:** el tiempo hasta la primera respuesta.
9. Pasa el ejemplo a la compilación sin GIL (`3.14t`) si numba la soporta en tu versión. **Criterio:** qué pasa, con el mensaje exacto si no.

**🔴 Muy difícil (10)**

10. Decide entre numba y Cython para una función caliente tuya. **Criterio:** una página. *Rúbrica:* (a) los tiempos de los dos; (b) el arranque y la primera llamada;
    (c) qué parte del código quedó fuera del subconjunto de numba; (d) el costo de distribuir cada uno.

---

## 📚 7. Referencias

**Documentación oficial**

- numba: https://numba.readthedocs.io/en/stable/
- Lo que numba soporta de Python: https://numba.readthedocs.io/en/stable/reference/pysupported.html

**Charlas**

- Antoine Pitrou, *Numba, a JIT compiler for fast numerical code* (EuroPython 2015), de uno de sus desarrolladores; anterior a las versiones actuales, y el modelo
  sigue igual: https://www.youtube.com/watch?v=-3KMZEPXQNQ

**Orden de lectura sugerido:** la guía de cinco minutos de numba; después la lista de lo que soporta, que es donde están los límites.

---

## 🚀 8. Cierre

numba compila una función numérica con un decorador y la deja tan rápida como el C escrito a mano: 4,5 ms contra 5,1. El costo está en los bordes: 151 ms de
importación, 186 de compilación en la primera llamada, un caché que no lo lleva a cero y un subconjunto de Python que deja afuera generadores y objetos. Para
bucles numéricos en procesos largos, es la frontera más barata del track.

**La señal de que quedó bien:** *"Las funciones con `@njit` son pocas, numéricas, tienen su prueba, y el servicio las calienta al arrancar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-04 -m "op ff04 cerrada: numba, la primera llamada, el caché y su subconjunto"
> ```
>
> Los commits llevan su prefijo (`op ff04: …`) y los de ejercicio su número
> (`op ff04 ej07: …`).
