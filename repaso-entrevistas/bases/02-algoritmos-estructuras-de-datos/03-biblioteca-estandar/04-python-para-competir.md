# 04 — Python: `collections`, `heapq`, `bisect`, `itertools`, recursión y PyPy

> Qué viene hecho en Python, cuánto cuesta y dónde se queda corto: las estructuras de la librería
> estándar con su coste real, el límite de recursión y la pila del hilo, el factor de 30–50 frente a
> C++ y cuándo PyPy lo arregla.
>
> **Niveles:** `list`, `dict`, `set`, `deque`, `Counter`, `defaultdict`, `heapq`, `bisect` [A] ·
> `itertools`, `functools.cache`, `sys.setrecursionlimit` [A] · PyPy [B].
>
> **📚 Lectura troncal:** Miller y Ranum, *Problem Solving with Algorithms and Data Structures using
> Python*, cap. 2; Ramalho, *Fluent Python*, 2.ª ed. (O'Reilly, 2022), caps. 2–3; la documentación de
> Python.
>
> **Ruta corta:** sí (si tu lenguaje es Python).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--list) · [3](#3--dict-set-counter-y-defaultdict) · [4](#4--deque) · [5](#5--heapq) · [6](#6--bisect-y-el-mapa-ordenado-que-no-existe) · [7](#7--itertools-y-functoolscache) · [8](#8--la-recursión) · [9](#9--el-factor-y-pypy) · [10](#10-️-la-tabla-de-costes) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un BFS en Python, con la cola en una lista:

```python
# falla: TLE con 2·10⁵ nodos. pop(0) desplaza toda la lista en cada extracción.
queue = [start]
while queue:
    node = queue.pop(0)
    for nxt in graph[node]:
        if not seen[nxt]:
            seen[nxt] = True
            queue.append(nxt)
```

Es correcto y es `O(V + E)` en la cabeza de quien lo escribe. En la máquina es `O(V²)`: `list.pop(0)`
quita el primer elemento y **mueve todos los demás una posición**. Con `2·10⁵` nodos son unos `2·10¹⁰`
movimientos, y en Python eso no termina. La versión correcta cambia una línea: `collections.deque` y
`popleft()`.

Python tiene la librería estándar más cómoda de los tres lenguajes del corpus, y la más traicionera en
coste: las operaciones se escriben igual de cortas y cuestan muy distinto. Además, el propio lenguaje
es de 30 a 50 veces más lento que C++ en bucles, así que un factor que en C++ no se notaría aquí
decide el veredicto. Este capítulo recorre lo que viene hecho con su coste, lo que **no** viene hecho
—un montículo de máximos, un mapa ordenado— y las dos trampas del intérprete: la recursión y la
velocidad.

> 🧠 **Modelo mental.** Recordatorio, si llegas directo aquí: con un límite de 1 segundo, C++ hace del
> orden de `10⁸` operaciones simples y Python del orden de `10⁷` en bucles propios. Lo que hace la
> librería escrita en C (`sorted`, `sum`, `heapq`) se salva en buena parte de ese factor.

---

## 2. 🧱 `list`

**Qué es.** Un arreglo dinámico de punteros a objetos, que sobreasigna alrededor de un octavo al
crecer ([`02/03`](../02-analisis/03-analisis-amortizado.md)). Es la secuencia por defecto.

**Cómo va.**

```python
a = [5, 2, 9, 1, 5, 6]
a.append(7)           # al final: O(1) amortizado
a.pop()               # el último: O(1)
x = a[2]              # 9: O(1)
a.insert(0, 4)        # al principio: O(n)
a.pop(0)              # el primero: O(n) — no es una cola
grid = [[0] * 4 for _ in range(3)]   # 3 × 4; [[0] * 4] * 3 repetiría la misma fila
```

- **`pop(0)` e `insert(0, x)` son `O(n)`**: desplazan todo. Para los extremos, `deque` (§4).
- **`[[0] * m] * n` crea `n` referencias a la misma fila**: escribir en una fila las cambia todas. La
  matriz se crea con una comprensión.
- **`x in lista` es `O(n)`**: para pertenencia, un `set`.

**Cuánto cuesta.** Acceso y final en `O(1)`; principio, medio y búsqueda en `O(n)`. Cada entero es un
objeto aparte, de unos 28 bytes más el puntero de la lista ([`02/05`](../02-analisis/05-el-coste-real.md)).

**Cuándo sí**: secuencias, pilas (`append` y `pop`). **Cuándo no**: colas, ni pertenencia en bucles.

> **Veredicto:** `list` es pila y arreglo, nunca cola. `pop(0)` en un bucle es un TLE escrito en una
> línea.

---

## 3. 🧱 `dict`, `set`, `Counter` y `defaultdict`

**Qué es.** Tablas *hash* ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)): `dict` de clave a valor, `set` de claves. `Counter` y
`defaultdict`, de `collections`, son `dict` con comportamientos de conteo y de valor por defecto.
Desde Python 3.7, el `dict` **conserva el orden de inserción**.

**Cómo va.**

```python
from collections import Counter, defaultdict

freq = Counter([5, 2, 9, 1, 5, 6])      # Counter({5: 2, 2: 1, 9: 1, 1: 1, 6: 1})
freq[5]                                  # 2
freq[7]                                  # 0: una clave ausente vale 0, y no se crea
top = freq.most_common(2)                # [(5, 2), (2, 1)]: los dos más frecuentes

groups = defaultdict(list)
groups["a"].append(1)                    # crea la lista vacía la primera vez

seen = set()
seen.add((2, 3))                         # tuplas como claves: hashables
```

- **Las claves tienen que ser *hashables***: números, cadenas, tuplas de *hashables*; **no** listas ni
  conjuntos. Una lista como clave da `TypeError`; se convierte en `tuple`.
- **`Counter` devuelve 0 para lo ausente sin crearlo**; `defaultdict` **sí crea** la entrada al
  consultarla, como el `operator[]` de C++ ([`03/01`](01-cpp-contenedores.md)).
- **`most_common(k)`** usa un montículo por dentro: `O(n log k)`.

**Cuánto cuesta.** `O(1)` esperado por operación; `O(n)` en el caso peor con colisiones. El *hash* de
las cadenas en Python está **aleatorizado por proceso**; el de los enteros pequeños es el propio
valor, y un adversario puede elegir enteros que colisionen (`06/03`).

**Cuándo sí**: conteos, pertenencia, agrupar, memoizar. **Cuándo no**: si necesitas orden por clave o
el sucesor de un valor (§6).

> **Veredicto:** `Counter` para contar y `defaultdict` para agrupar; y las claves compuestas, como
> tuplas.

---

## 4. 🧱 `deque`

**Qué es.** Una cola doble de `collections`, implementada como una lista doblemente enlazada de bloques:
`O(1)` por los dos extremos.

**Cómo va.**

```python
from collections import deque

q = deque([5, 2])
q.append(9)          # por la derecha
q.appendleft(1)      # por la izquierda
q.popleft()          # 1: la cola de un BFS
q.pop()              # 9: la pila
window = deque(maxlen=3)   # al llenarse, cada append expulsa el más viejo
```

- **Es la cola de Python**: el BFS de §1 se arregla con `popleft()`.
- **El acceso por índice es `O(n)` en el medio** (`O(1)` en los extremos): no es un arreglo.

**Cuánto cuesta.** `O(1)` en los extremos. **Cuándo sí**: colas, BFS ([`14/02`](../14-grafos-recorridos/02-bfs.md)), colas monótonas
([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)). **Cuándo no**: con acceso por índice frecuente.

> **Veredicto:** cualquier cola en Python es un `deque`. Siempre.

---

## 5. 🧱 `heapq`

**Qué es.** Funciones que mantienen una `list` como **montículo de mínimos** ([`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md)). No es una
clase: el montículo es la lista, y las funciones respetan su invariante.

**Cómo va.**

```python
import heapq

h = [5, 2, 9, 1, 5, 6]
heapq.heapify(h)             # O(n): h[0] es el mínimo, 1
heapq.heappush(h, 0)         # O(log n)
smallest = heapq.heappop(h)  # 0
# heapq.heappush(h, (3, "c")) lanzaría TypeError: no se mezclan int y tuple en un montículo

dist = []
heapq.heappush(dist, (7, 4))           # pares (prioridad, dato): ordena por el primero
heapq.heappush(dist, (-9, "max"))      # montículo de máximos: se niega la prioridad
largest3 = heapq.nlargest(3, [5, 2, 9, 1, 5, 6])   # [9, 6, 5]
```

- **Solo hay montículo de mínimos** en Python 3.12: para el máximo, se niega la clave al meter y al
  sacar.
- **Las tuplas comparan componente a componente**: si dos prioridades empatan, se compara el segundo
  componente, que tiene que ser comparable. Si no lo es (objetos sin orden), se añade un contador
  único como desempate: `(prioridad, contador, dato)`.
- **No hay `decrease-key`**: se reinserta y se descartan al sacar las entradas viejas.

> 📝 **Desde Python 3.14:** `heapq` añade funciones públicas para montículos de máximos
> (`heapify_max`, `heappush_max`, `heappop_max` y otras). El corpus no las usa en sus plantillas, porque
> su techo es Python 3.12 ([`01/01`](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md)).

**Cuánto cuesta.** `heapify` `O(n)`; `heappush` y `heappop` `O(log n)`; `nlargest(k, …)` `O(n log k)`.

**Cuándo sí**: Dijkstra ([`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md)), los `k` mayores, la mediana con dos montículos ([`08/02`](../08-heaps-y-union-find/02-patrones-con-heap.md)). **Cuándo
no**: si necesitas borrar un elemento concreto o buscar; ahí no hay estructura en la librería.

> **Veredicto:** `heapq` sobre una lista, con prioridades negadas para el máximo y un contador de
> desempate cuando los datos no se comparan.

---

## 6. 🧱 `bisect` y el mapa ordenado que no existe

**Qué es.** `bisect` hace búsqueda binaria sobre una **lista ordenada** ([`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)). Python **no tiene**
en su librería estándar un árbol balanceado: ni `TreeMap`, ni `std::set`, ni *multiset* ordenado.

**Cómo va.**

```python
import bisect

v = [1, 2, 5, 5, 6, 9]
bisect.bisect_left(v, 5)      # 2: primer índice con v[i] >= 5
bisect.bisect_right(v, 5)     # 4: primer índice con v[i] > 5
bisect.insort(v, 4)           # inserta manteniendo el orden: búsqueda O(log n), inserción O(n)
```

- **`bisect_left` y `bisect_right`** son el `lower_bound` y el `upper_bound` de C++; desde 3.10 aceptan
  `key=`.
- **`insort` es `O(n)`**: busca en `O(log n)` pero inserta desplazando la lista. Cada inserción mueve
  memoria contigua con una copia en C, que es muy rápida: con unos `10⁵` elementos suele entrar; con
  `10⁶`, no.
- **El sustituto del mapa ordenado**: la librería `sortedcontainers` (`SortedList`) existe, pero **no
  está en los jueces** de las bases. Las alternativas son la lista con `insort` cuando el tamaño lo
  permite, resolver *offline* con compresión y un árbol de Fenwick ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)), o escribir un *treap*
  ([`07/03`](../07-arboles/03-arboles-aleatorizados.md)).

**Cuánto cuesta.** Búsqueda `O(log n)`; inserción `O(n)`. **Cuándo sí**: listas ordenadas fijas o de
pocas inserciones. **Cuándo no**: con muchas inserciones y borrados mezclados con consultas de orden.

> **Veredicto:** `bisect` es la binaria de Python. El mapa ordenado no existe, y hay que saber cuál de
> sus sustitutos cabe antes de empezar.

---

## 7. 🧱 `itertools` y `functools.cache`

**Qué es.** `itertools` genera combinaciones, permutaciones y productos de forma perezosa;
`functools.cache` memoiza una función con un decorador ([`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md)).

**Cómo va.**

```python
from functools import cache
from itertools import accumulate, combinations, permutations, product

list(combinations([5, 2, 9], 2))      # [(5, 2), (5, 9), (2, 9)]
sum(1 for _ in permutations(range(4)))   # 24
list(product([0, 1], repeat=2))       # [(0, 0), (0, 1), (1, 0), (1, 1)]
list(accumulate([5, 2, 9, 1, 5, 6]))  # prefijos: [5, 7, 16, 17, 22, 28]

@cache
def ways(n: int) -> int:              # escaleras de 1 o 2 peldaños
    return 1 if n <= 1 else ways(n - 1) + ways(n - 2)
```

- **Son perezosos**: `permutations` no crea la lista de `n!` permutaciones, las va dando. Envolverlo en
  `list(...)` las crea todas.
- **`@cache`** guarda cada resultado por sus argumentos, que tienen que ser *hashables*; la memoria crece
  con los estados distintos.
- **`ways(5000)` recursivo revienta el límite de recursión** (§8) aunque esté memoizado: la primera
  llamada baja 5000 niveles.

**Cuánto cuesta.** Lo que cueste enumerar; `cache`, una consulta al diccionario por llamada.
**Cuándo sí**: fuerza bruta corta y DP con pocos estados y poca profundidad. **Cuándo no**: DP profundas
o con millones de estados, donde una tabla en un bucle es más rápida y no usa pila.

> **Veredicto:** `itertools` para la fuerza bruta, `@cache` para memoizar sin escribir el diccionario. Y
> la profundidad, mirada antes.

---

## 8. 🧱 La recursión

**Qué es.** Python limita la profundidad de recursión a **1000 llamadas** por defecto. Subir el límite
con `sys.setrecursionlimit` **no basta**: la pila del hilo del sistema es finita, y una recursión de
`10⁵` niveles puede tumbar el intérprete con un error del proceso, no con una excepción.

**Cómo va.** La receta completa: subir el límite **y** ejecutar en un hilo con pila grande.

```python
import sys
import threading

def main():
    sys.setrecursionlimit(1 << 20)    # el límite de Python
    # aquí va el programa entero, con la recursión profunda

threading.stack_size(1 << 27)          # 128 MB de pila para los hilos que se creen después
worker = threading.Thread(target=main)
worker.start()
worker.join()
```

- **`setrecursionlimit`** solo cambia el contador de Python; sin pila suficiente, el proceso muere con
  un fallo de segmentación, que el juez informa como *Runtime Error* (RE).
- **`threading.stack_size`** fija la pila de los hilos nuevos; por eso se llama **antes** de crear el
  hilo, y el programa se ejecuta dentro.
- **La alternativa robusta** es convertir la recursión en iterativa con una pila explícita ([`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md)),
  que además es más rápida en Python.

**Cuánto cuesta.** Una llamada a función en Python es cara; una recursión de `10⁵` niveles cuesta
tiempo además de pila. **Cuándo sí** se usa la receta: DFS o DP recursivos con profundidad que depende
de `n`. **Cuándo no**: con profundidades logarítmicas.

> **Veredicto:** en Python, recursión profunda es límite más hilo con pila grande, o mejor, un bucle con
> pila explícita.

---

## 9. 🧱 El factor y PyPy

**Qué es.** Un bucle de Python ejecuta cada operación a través del intérprete: del orden de 30 a 50
veces más lento que C++ en código de bucles. **PyPy** es otro intérprete de Python con compilación al
vuelo (JIT), que acerca los bucles a la velocidad de Java.

**Por qué es correcto** (el enunciado y una frase): el intérprete de CPython despacha cada operación con
comprobaciones de tipo y objetos en el *heap*; un JIT observa los tipos reales y genera código de
máquina para el bucle.

**Cómo va.** Lo que se hace en CPython cuando la complejidad cabe justo:

- **Empujar el trabajo a C**: `sum`, `sorted`, `max`, `map`, comprensiones, `str.join`, en vez de
  bucles con `+=`.
- **Variables locales** dentro de `main()` (`01/03`), y métodos guardados en locales en los bucles
  calientes (`push = heapq.heappush`).
- **E/S en bloque** (`01/03`).

**Dónde está PyPy**, comprobado en las plataformas el 2026-10-03: **Codeforces** ofrece PyPy 3 de 64
bits; **HackerRank**, solo un PyPy antiguo (`01/01`); **LeetCode** y **Codility**, ninguno. En las
pruebas de empresa, por tanto, se trabaja con CPython.

**Cuánto cuesta.** PyPy arranca más lento y usa más memoria; para programas cortos con mucha librería en
C puede no ganar nada. **Cuándo sí**: bucles numéricos largos en un concurso que lo ofrece. **Cuándo
no**: en las pruebas de empresa, donde no está.

> **Veredicto:** en Python, la complejidad correcta no basta si está en el límite: empuja el trabajo a
> la librería, y si el juez ofrece PyPy y el código es de bucles, úsalo.

---

## 10. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| `list.append`, `list.pop()` | `O(1)` amortizado | Pila perfecta |
| `list.pop(0)`, `list.insert(0, x)` | `O(n)` | Una cola con `list` es cuadrática |
| `x in list` | `O(n)` | Para pertenencia, `set` |
| `dict` / `set` | `O(1)` esperado | Enteros atacables; las claves, *hashables* |
| `deque` en los extremos | `O(1)` | Índice en el medio `O(n)` |
| `heappush` / `heappop` / `heapify` | `O(log n)` / `O(log n)` / `O(n)` | Solo mínimos hasta 3.13; negar para el máximo |
| `bisect_left` / `insort` | `O(log n)` / `O(n)` | No hay mapa ordenado en la librería |
| Una iteración de un bucle propio | decenas de ns | El factor 30–50 frente a C++ |

---

## 11. 🧭 Cómo se elige

```text
¿Cola o BFS?                                      → deque y popleft
¿Pila?                                            → list con append/pop
¿Contar o agrupar?                                → Counter / defaultdict
¿El menor de los que hay?                         → heapq (negar para el mayor)
¿Buscar en una lista ordenada fija?               → bisect
¿Mapa ordenado con inserciones y borrados?        → no hay: insort si n es pequeño;
                                                    offline con Fenwick; o un treap a mano
¿Recursión con profundidad n?                     → límite + hilo con pila, o iterativo
¿Bucle de 10⁷ o más?                              → mover el trabajo a la librería; PyPy si lo hay
```

> **Mejor:** «En Python la cola es un `deque`: `list.pop(0)` desplaza todo y haría el BFS cuadrático.»

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`list.pop(0)` es `O(1)`» | Es `O(n)`: desplaza todos los elementos; la cola es `deque` |
| «Subir el límite de recursión basta» | Sin una pila de hilo más grande, el proceso muere con RE |
| «`heapq` tiene montículo de máximos» | Hasta 3.13 no: se niegan las prioridades; 3.14 añade funciones de máximos |
| «`[[0] * m] * n` crea una matriz» | Crea `n` referencias a la misma fila |
| «Python tiene `TreeMap`» | No en la librería estándar; `sortedcontainers` no está en los jueces |
| «`defaultdict` y `Counter` consultan igual» | `Counter` devuelve 0 sin crear la clave; `defaultdict` la crea |
| «Si la complejidad es correcta, Python entra» | Con `10⁷` pasos en bucles propios, no |

---

## 📚 Para profundizar

- **Libro** — Miller y Ranum, *Problem Solving with Algorithms and Data Structures using Python*
  (libre en Runestone), cap. 2: el análisis del coste de las operaciones de `list` y `dict`. *Lectura
  troncal.*
- **Libro** — Ramalho, *Fluent Python*, 2.ª ed. (O'Reilly, 2022), caps. 2–3: secuencias, diccionarios y
  conjuntos por dentro. *Lectura troncal.*
- **Documentación** — Python, [`collections`](https://docs.python.org/3/library/collections.html):
  `deque`, `Counter`, `defaultdict`.
- **Documentación** — Python, [`heapq`](https://docs.python.org/3/library/heapq.html) y
  [`bisect`](https://docs.python.org/3/library/bisect.html).
- **Documentación** — Python, [`itertools`](https://docs.python.org/3/library/itertools.html),
  [`functools`](https://docs.python.org/3/library/functools.html) y
  [`threading`](https://docs.python.org/3/library/threading.html).
- **Referencia** — la wiki de Python, [*TimeComplexity*](https://wiki.python.org/moin/TimeComplexity):
  el coste de cada operación de las estructuras de CPython.

---

## 🧠 Preguntas

1. ¿Cuánto cuestan `list.pop()` y `list.pop(0)`, y por qué son distintos? 🟢
2. ¿Qué estructura usas como cola en Python? 🟢
3. ¿Qué hace `heapq.heapify` y cuánto cuesta? 🟢
4. ¿Qué diferencia hay entre consultar una clave ausente en un `Counter` y en un `defaultdict`? 🟡
5. ¿Qué diferencia hay entre `bisect_left` y `bisect_right`? 🟡
6. ¿Por qué `sys.setrecursionlimit` no basta para una recursión de `10⁵` niveles? 🟡
7. ¿Por qué `grid = [[0] * 3] * 3` seguido de `grid[0][0] = 1` cambia tres celdas? 🟡
8. ¿Cómo haces un montículo de máximos con `heapq` en Python 3.12, y qué cuidado hay con las tuplas? 🟠
9. Compara cómo resuelves «el mayor elemento menor o igual que `x`, con inserciones» en C++, Java y Python. 🟠
10. Tu solución `O(n log n)` con `n = 10⁶` en Python da TLE. ¿Qué cambias antes de cambiar de algoritmo? 🟠
11. Diseña con `heapq` una cola de tareas que saque siempre la de **mayor** prioridad y, a igual prioridad, la que llegó antes, donde las tareas son objetos que no se pueden comparar. Escribe qué tupla metes y por qué. 🔴
12. Una DP recursiva con `@cache` y `n = 10⁵` da RE. Explica la causa y propone dos soluciones con su coste. 🔴

---

## 🧩 Problemas propios

### Atención por orden de llegada

**Nivel:** 🟢 · **Formato:** programa completo.

Llegan clientes con su número y se atienden en orden de llegada. Operaciones: `L x` llega el cliente
`x`; `A` atiende al primero e imprime su número, o `NADIE`.

- **Entrada.** Una línea con `q`. Después, `q` líneas con una operación.
- **Salida.** Una línea por cada `A`.
- **Restricciones.** `1 ≤ q ≤ 5·10⁵`. Límite: 1 segundo.

```text
Entrada            Salida
5                  5
L 5                2
L 2                NADIE
A
A
A

Entrada            Salida
3                  NADIE
A                  7
L 7
A
```

**Pista 1:** con el `q` máximo, ¿cuántos elementos mueve tu estructura en cada atención?

### Las tres más caras

**Nivel:** 🟡 · **Formato:** programa completo.

Llegan ventas con su importe. Después de cada venta, imprime la suma de las tres ventas más altas
recibidas hasta el momento (o de todas, si hay menos de tres).

- **Entrada.** Una línea con `n`. Una línea con los `n` importes.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ importe ≤ 10⁹`.

```text
Entrada                                      Salida
6                                            5 7 16 16 19 20
5 2 9 1 5 6

Entrada                                      Salida
4                                            1000000000 2000000000 3000000000 3000000000
1000000000 1000000000 1000000000 1000000000
```

**Pista 1:** ¿cuántos importes necesitas recordar en cada momento, y cuál de ellos es el que puede
salir?

### Llamadas en cadena

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` funciones; la función `i` (para `i ≥ 2`) llama a la función `p[i] < i`, y cada llamada cuesta
`c[i]`. El coste total de ejecutar la función `i` es `c[i]` más el coste total de la función a la que
llama (la función 1 no llama a nadie). Imprime el coste total de cada función.

- **Entrada.** Una línea con `n`. Una línea con `c[1..n]`. Una línea con `p[2..n]`.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ c[i] ≤ 10⁹`. La cadena de llamadas puede tener longitud `n`.

```text
Entrada            Salida
4                  5 7 16 17
5 2 9 1
1 2 3

Entrada            Salida
3                  5 7 14
5 2 9
1 1
```

**Pista 1:** si lo escribes recursivo, ¿qué profundidad alcanza con `p[i] = i − 1` y `n = 2·10⁵`?

---

## 🧩 Práctica externa

Los de HackerRank son de su sección de Python: cada uno ejercita un módulo concreto.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [collections.Counter()](https://www.hackerrank.com/challenges/collections-counter/problem) | HackerRank | 🟢 | `Counter` | ¿Qué haces con el conteo de una talla cuando vendes una? |
| [ ] | [DefaultDict Tutorial](https://www.hackerrank.com/challenges/defaultdict-tutorial/problem) | HackerRank | 🟢 | `defaultdict(list)` | ¿Qué guardas por palabra para responder todas las posiciones? |
| [ ] | [Collections.deque()](https://www.hackerrank.com/challenges/py-collections-deque/problem) | HackerRank | 🟢 | `deque` | ¿Qué método corresponde a cada orden del enunciado? |
| [ ] | [itertools.permutations()](https://www.hackerrank.com/challenges/itertools-permutations/problem) | HackerRank | 🟢 | `itertools` | ¿En qué orden salen las permutaciones si ordenas la cadena antes? |
| [ ] | [Number of Recent Calls](https://leetcode.com/problems/number-of-recent-calls/) | LeetCode | 🟢 | `deque` como ventana | ¿Qué llamadas ya no volverán a contar nunca? |
| [ ] | [Word Order](https://www.hackerrank.com/challenges/word-order/problem) | HackerRank | 🟡 | `dict` con orden de inserción | ¿Qué estructura recuerda el orden de primera aparición sin hacer nada? |
| [ ] | [Piling Up!](https://www.hackerrank.com/challenges/piling-up/problem) | HackerRank | 🟡 | `deque` por los dos extremos | ¿De qué extremo conviene tomar el siguiente cubo? |
| [ ] | [Top K Frequent Words](https://leetcode.com/problems/top-k-frequent-words/) | LeetCode | 🟡 | `Counter` y orden con desempate | ¿Qué clave ordena por frecuencia descendente y por palabra ascendente a la vez? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Find K Pairs with Smallest Sums](https://leetcode.com/problems/find-k-pairs-with-smallest-sums/) | LeetCode | 🟡 | `heapq` con tuplas | Si sacas el par `(i, j)`, ¿qué pares nuevos pueden ser los siguientes? |
| [ ] | [Find the Running Median](https://www.hackerrank.com/challenges/find-the-running-median/problem) | HackerRank | 🟠 | Dos `heapq`, uno negado | Si partes los números en dos mitades, ¿qué necesitas de cada una? |
| [ ] | [Sliding Window Maximum](https://leetcode.com/problems/sliding-window-maximum/) | LeetCode | 🟠 | `deque` monótona | Si un valor tiene a su derecha uno mayor en la ventana, ¿puede volver a ser el máximo? |

---

## ✅ Criterio de dominio

- Escribir de memoria el BFS con `deque`, el montículo de máximos con `heapq` negado y la receta de
  recursión profunda con hilo.
- Decir qué estructura falta en la librería de Python y dos sustitutos según el tamaño.
- Explicar el factor de 30–50 y tres formas de mover el trabajo a la librería.
- Resolver dos problemas del núcleo y uno de ampliación con AC en CPython.

---

**Anterior:** [`03/03` — Java: las colecciones](03-java-colecciones.md) ·
**Siguiente:** [`03/05` — La tabla de equivalencias](05-equivalencias-entre-lenguajes.md) ·
**Relacionado:** [`01/03` — Entrada, salida y la plantilla](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md); [`10/01` — Recursión](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md).
