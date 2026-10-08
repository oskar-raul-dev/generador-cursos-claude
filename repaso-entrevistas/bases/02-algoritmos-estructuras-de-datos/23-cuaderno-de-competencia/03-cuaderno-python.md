# 03 — Cuaderno de Python

> **Opcional.** Las plantillas de nivel A del corpus en Python, y las de nivel B que tienen versión en Python, sin explicación y listas para copiar. Cada una lleva el enlace a la sección
> del capítulo de donde sale, que es donde están su invariante, su coste y sus trampas.
> **Se genera de los capítulos**, no se edita a mano: si una plantilla cambia en su capítulo, este cuaderno
> se regenera en la misma edición. Las plantillas y las salidas que muestran algunos comentarios se
> comprobaron en la pasada de verificación del 2026-10-04, como en el capítulo de origen.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#-bloque-01--oficio-del-competidor) · [04](#-bloque-04--secuencias) · [05](#-bloque-05--orden-y-búsqueda) · [06](#-bloque-06--lineales-y-hashing) · [07](#-bloque-07--árboles) · [08](#-bloque-08--heaps-y-union-find) · [09](#-bloque-09--consultas-sobre-rangos) · [10](#-bloque-10--búsqueda-completa-y-divide-y-vencerás) · [11](#-bloque-11--voraces) · [12](#-bloque-12--dp-clásica) · [13](#-bloque-13--dp-avanzada) · [14](#-bloque-14--grafos-recorridos) · [15](#-bloque-15--grafos-con-pesos-y-flujos) · [16](#-bloque-16--cadenas) · [17](#-bloque-17--matemática) · [18](#-bloque-18--geometría) · [19](#-bloque-19--aleatorizados-y-probabilísticos) · [22](#-bloque-22--teoría-de-la-computación-opcional)

---

## 🧱 Bloque 01 — Oficio del competidor

### `01/03` — La plantilla [A]

De [`01/03` — Entrada, salida y la plantilla en C++, Java y Python, §6](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md#6--la-plantilla).

```python
import sys

def main():
    data = sys.stdin.buffer.read().split()
    n = int(data[0])
    a = list(map(int, data[1:1 + n]))

    total = sum(a)                      # aquí va la solución

    sys.stdout.write(str(total) + "\n")

main()
```

### `01/05` — El *stress test* [A]

De [`01/05` — Probar sin IDE: casos borde, depuración y *stress test*, §4](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md#4--el-stress-test).

```python
import random
import sys

random.seed(int(sys.argv[1]))                      # la semilla la pasa el arnés
n = random.randint(1, 8)                           # de 1 a 8, los dos incluidos
print(n)
print(*(random.randint(-5, 5) for _ in range(n)))
```

```python
#!/usr/bin/env python3
# Compara sol contra brute con entradas aleatorias hasta encontrar una diferencia.
import subprocess
import sys

def run(cmd, data):
    # check=True: si el programa termina con error (un RE), el arnés también para
    return subprocess.run(cmd, input=data, capture_output=True, text=True, check=True).stdout.split()

def main():
    gen, sol, brute = ["./gen"], ["./sol"], ["./brute"]   # en Java: ["java", "Gen"], etc.
    for seed in range(1, 10_001):
        data = subprocess.run(gen + [str(seed)], capture_output=True, text=True, check=True).stdout
        mine, oracle = run(sol, data), run(brute, data)
        if mine != oracle:
            print(f"Diferencia con la semilla {seed}:\n{data}")
            print("sol:  ", " ".join(mine))
            print("brute:", " ".join(oracle))
            sys.exit(1)
    print("10 000 casos sin diferencias")

main()
```

---

## 🧱 Bloque 04 — Secuencias

### `04/01` — Prefijos 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §3](../04-secuencias/01-prefijos-y-diferencias.md#3--prefijos-1d).

```python
from itertools import accumulate

def build_prefix(a):
    """P[k] = a[0] + ... + a[k-1]; suma de a[l..r] = P[r+1] - P[l]."""
    return [0] + list(accumulate(a))

def range_sum(p, l, r):   # l, r incluidos
    return p[r + 1] - p[l]
```

### `04/01` — Diferencias 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §4](../04-secuencias/01-prefijos-y-diferencias.md#4--diferencias-1d).

```python
from itertools import accumulate

class RangeAdd:
    """Suma v a [l, r] en O(1); al final, finish() reconstruye el arreglo con prefijos."""

    def __init__(self, n):
        self.d = [0] * (n + 1)

    def add(self, l, r, v):
        self.d[l] += v
        self.d[r + 1] -= v

    def finish(self):
        return list(accumulate(self.d[:-1]))   # prefijos de las diferencias
```

### `04/01` — Prefijos y diferencias 2D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §5](../04-secuencias/01-prefijos-y-diferencias.md#5--prefijos-y-diferencias-2d).

```python
class Prefix2D:
    """S[i][j] = suma de M[0..i-1][0..j-1]; consulta inclusiva de (r1,c1) a (r2,c2)."""

    def __init__(self, m):
        rows, cols = len(m), len(m[0]) if m else 0
        s = [[0] * (cols + 1) for _ in range(rows + 1)]
        for i in range(rows):
            row, prev, cur = m[i], s[i], s[i + 1]
            for j in range(cols):
                cur[j + 1] = row[j] + prev[j + 1] + cur[j] - prev[j]
        self.s = s

    def query(self, r1, c1, r2, c2):
        s = self.s
        return s[r2 + 1][c2 + 1] - s[r1][c2 + 1] - s[r2 + 1][c1] + s[r1][c1]
```

### `04/02` — Dos punteros [A]

De [`04/02` — Dos punteros y ventana deslizante, §3](../04-secuencias/02-dos-punteros-y-ventana.md#3--dos-punteros).

```python
def count_pairs_at_most(a, k):
    """Número de pares i < j con a[i] + a[j] <= k. Pre: a ordenado. O(n)."""
    count, l, r = 0, 0, len(a) - 1
    while l < r:
        if a[l] + a[r] <= k:
            count += r - l
            l += 1
        else:
            r -= 1
    return count
```

### `04/02` — Ventana variable [A]

De [`04/02` — Dos punteros y ventana deslizante, §4](../04-secuencias/02-dos-punteros-y-ventana.md#4--ventana-variable).

```python
def longest_at_most(a, s):
    """Longitud del subarreglo más largo con suma <= s. Pre: a[i] >= 0. O(n)."""
    total = best = l = 0
    for r, x in enumerate(a):
        total += x
        while total > s:
            total -= a[l]
            l += 1
        best = max(best, r - l + 1)
    return best
```

### `04/02` — Ventana fija [A]

De [`04/02` — Dos punteros y ventana deslizante, §5](../04-secuencias/02-dos-punteros-y-ventana.md#5--ventana-fija).

```python
def max_window_sum(a, k):
    """Máxima suma de k elementos consecutivos. Pre: 1 <= k <= n. O(n)."""
    total = sum(a[:k])
    best = total
    for i in range(k, len(a)):
        total += a[i] - a[i - k]
        best = max(best, total)
    return best
```

### `04/03` — Kadane [A]

De [`04/03` — Kadane y subarreglos, §3](../04-secuencias/03-kadane-y-subarreglos.md#3--kadane).

```python
def max_subarray_sum(a):
    """Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n)."""
    best, cur = a[0], 0
    for x in a:
        cur = max(x, cur + x)
        best = max(best, cur)
    return best
```

### `04/03` — La variante circular [A]

De [`04/03` — Kadane y subarreglos, §4](../04-secuencias/03-kadane-y-subarreglos.md#4--la-variante-circular).

```python
def max_circular_sum(a):
    """Suma máxima de un subarreglo no vacío de un arreglo circular. O(n)."""
    total = cur_max = cur_min = 0
    best = worst = a[0]
    for x in a:
        total += x
        cur_max = max(x, cur_max + x); best = max(best, cur_max)
        cur_min = min(x, cur_min + x); worst = min(worst, cur_min)
    return best if best < 0 else max(best, total - worst)
```

### `04/03` — Contar subarreglos con prefijos y *hash* [A]

De [`04/03` — Kadane y subarreglos, §5](../04-secuencias/03-kadane-y-subarreglos.md#5--contar-subarreglos-con-prefijos-y-hash).

```python
from collections import defaultdict

def count_subarrays_with_sum(a, k):
    """Número de subarreglos con suma exactamente k. O(n) esperado."""
    seen = defaultdict(int)
    seen[0] = 1                                   # el prefijo vacío
    prefix = count = 0
    for x in a:
        prefix += x
        count += seen.get(prefix - k, 0)
        seen[prefix] += 1
    return count
```

### `04/04` — Compresión de coordenadas [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §3](../04-secuencias/04-compresion-y-barrido.md#3--compresión-de-coordenadas).

```python
def compress(a):
    """Devuelve (rangos de a en [0, k), lista ordenada de distintos). O(n log n)."""
    distinct = sorted(set(a))
    pos = {v: i for i, v in enumerate(distinct)}
    return [pos[x] for x in a], distinct
```

### `04/04` — Barrido de eventos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §4](../04-secuencias/04-compresion-y-barrido.md#4--barrido-de-eventos).

```python
def max_overlap(intervals):
    """Máximo de intervalos [s, e) que se solapan en algún instante. O(n log n)."""
    events = []
    for s, e in intervals:
        events.append((s, 1))
        events.append((e, -1))
    events.sort()                      # en empate, -1 antes que 1: cierra primero
    open_ = best = 0
    for _, d in events:
        open_ += d
        best = max(best, open_)
    return best
```

### `04/04` — Unión de intervalos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §5](../04-secuencias/04-compresion-y-barrido.md#5--unión-de-intervalos).

```python
def merge_intervals(v):
    """Une intervalos [s, e) que se solapan. Devuelve los bloques disjuntos ordenados. O(n log n)."""
    out = []
    for s, e in sorted(v):
        if out and s < out[-1][1]:
            out[-1][1] = max(out[-1][1], e)
        else:
            out.append([s, e])
    return out
```

### `04/05` — Recorridos, rotación y espiral [A]

De [`04/05` — Matrices, §3](../04-secuencias/05-matrices.md#3--recorridos-rotación-y-espiral).

```python
DIRS = ((-1, 0), (1, 0), (0, -1), (0, 1))   # arriba, abajo, izquierda, derecha

def neighbors(r, c, rows, cols):
    for dr, dc in DIRS:
        nr, nc = r + dr, c + dc
        if 0 <= nr < rows and 0 <= nc < cols:
            yield nr, nc

def rotate_clockwise(m):
    """Gira una matriz n × n 90° en sentido horario, en el sitio."""
    n = len(m)
    for i in range(n):
        for j in range(i + 1, n):
            m[i][j], m[j][i] = m[j][i], m[i][j]
    for row in m:
        row.reverse()

def spiral(m):
    out = []
    top, bottom, left, right = 0, len(m) - 1, 0, len(m[0]) - 1
    while top <= bottom and left <= right:
        out.extend(m[top][left:right + 1]); top += 1
        out.extend(m[i][right] for i in range(top, bottom + 1)); right -= 1
        if top <= bottom:
            out.extend(m[bottom][j] for j in range(right, left - 1, -1)); bottom -= 1
        if left <= right:
            out.extend(m[i][left] for i in range(bottom, top - 1, -1)); left += 1
    return out
```

### `04/05` — Búsqueda en matriz ordenada [A]

De [`04/05` — Matrices, §4](../04-secuencias/05-matrices.md#4--búsqueda-en-matriz-ordenada).

```python
def staircase_search(m, x):
    """Busca x en una matriz con filas y columnas crecientes. Devuelve (fila, columna) o None. O(R + C)."""
    i, j = 0, len(m[0]) - 1
    while i < len(m) and j >= 0:
        if m[i][j] == x:
            return i, j
        if m[i][j] > x:
            j -= 1
        else:
            i += 1
    return None
```

---

## 🧱 Bloque 05 — Orden y búsqueda

### `05/01` — Inserción y estabilidad [A]

De [`05/01` — Ordenación por comparación, §3](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#3--inserción-y-estabilidad).

```python
def insertion_sort(a):
    """Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general."""
    for j in range(1, len(a)):
        key, i = a[j], j
        while i > 0 and a[i - 1] > key:
            a[i] = a[i - 1]
            i -= 1
        a[i] = key
```

### `05/01` — Ordenación por mezcla [A]

De [`05/01` — Ordenación por comparación, §4](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#4--ordenación-por-mezcla).

```python
def merge_sort(a):
    """Ordenación por mezcla, estable. Devuelve una lista nueva. Θ(n log n)."""
    if len(a) <= 1:
        return a[:]
    mid = len(a) // 2
    left, right = merge_sort(a[:mid]), merge_sort(a[mid:])
    out, i, j = [], 0, 0
    while i < len(left) and j < len(right):
        if right[j] < left[i]:
            out.append(right[j]); j += 1
        else:
            out.append(left[i]); i += 1          # empate: izquierda, estable
    out.extend(left[i:]); out.extend(right[j:])
    return out
```

### `05/01` — *Quicksort* [A]

De [`05/01` — Ordenación por comparación, §5](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#5--quicksort).

```python
import random

def quick_sort(a, lo=0, hi=None):
    """Quicksort de a[lo..hi] con pivote aleatorio y partición de Hoare. Θ(n log n) esperado."""
    if hi is None:
        hi = len(a) - 1
    if lo >= hi:
        return
    r = random.randint(lo, hi)
    a[lo], a[r] = a[r], a[lo]               # pivote aleatorio en a[lo]
    p = a[lo]
    i, j = lo - 1, hi + 1
    while True:
        i += 1
        while a[i] < p:
            i += 1
        j -= 1
        while a[j] > p:
            j -= 1
        if i >= j:
            break
        a[i], a[j] = a[j], a[i]
    quick_sort(a, lo, j)
    quick_sort(a, j + 1, hi)
```

### `05/03` — Contar inversiones con la mezcla [A]

De [`05/03` — Inversiones, selección y mediana, §3](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#3--contar-inversiones-con-la-mezcla).

```python
def count_inversions(a):
    """Devuelve (lista ordenada, inversiones). Θ(n log n)."""
    if len(a) <= 1:
        return a[:], 0
    mid = len(a) // 2
    left, x = count_inversions(a[:mid])
    right, y = count_inversions(a[mid:])
    out, i, j, inv = [], 0, 0, x + y
    while i < len(left) and j < len(right):
        if right[j] < left[i]:
            inv += len(left) - i                 # quedan len(left) − i mayores
            out.append(right[j]); j += 1
        else:
            out.append(left[i]); i += 1
    out.extend(left[i:]); out.extend(right[j:])
    return out, inv
```

### `05/03` — *Quickselect* [A]

De [`05/03` — Inversiones, selección y mediana, §4](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#4--quickselect).

```python
import random

def quick_select(a, k):
    """Valor que ocuparía la posición k (0-indexada) si a estuviera ordenado. Reordena a. O(n) esperado."""
    lo, hi = 0, len(a) - 1
    while lo < hi:
        r = random.randint(lo, hi)
        a[lo], a[r] = a[r], a[lo]               # pivote aleatorio en a[lo]
        p = a[lo]
        i, j = lo - 1, hi + 1
        while True:
            i += 1
            while a[i] < p:
                i += 1
            j -= 1
            while a[j] > p:
                j -= 1
            if i >= j:
                break
            a[i], a[j] = a[j], a[i]
        if k <= j:
            hi = j
        else:
            lo = j + 1
    return a[k]
```

### `05/04` — *Lower* y *upper bound* [A]

De [`05/04` — Búsqueda binaria, §3](../05-orden-y-busqueda/04-busqueda-binaria.md#3--lower-y-upper-bound).

```python
from bisect import bisect_left, bisect_right

def lower_bound(a, x):
    """Primer índice en [0, n] con a[i] >= x. Equivale a bisect_left(a, x)."""
    lo, hi = 0, len(a)
    while lo < hi:
        mid = (lo + hi) // 2
        if a[mid] < x:
            lo = mid + 1
        else:
            hi = mid
    return lo

# upper bound: bisect_right(a, x)
```

### `05/04` — Binaria sobre la respuesta [A]

De [`05/04` — Búsqueda binaria, §4](../05-orden-y-busqueda/04-busqueda-binaria.md#4--binaria-sobre-la-respuesta).

```python
def first_true(lo, hi, p):
    """Primer v en [lo, hi) con p(v) cierto, o hi si no hay. Pre: p monótono (falso…cierto)."""
    while lo < hi:
        mid = (lo + hi) // 2
        if p(mid):
            hi = mid
        else:
            lo = mid + 1
    return lo
```

### `05/04` — Binaria en reales [A]

De [`05/04` — Búsqueda binaria, §5](../05-orden-y-busqueda/04-busqueda-binaria.md#5--binaria-en-reales).

```python
def boundary_real(lo, hi, p):
    """Frontera de p (falso…cierto) en [lo, hi], con 100 vueltas fijas."""
    for _ in range(100):
        mid = lo + (hi - lo) / 2
        if p(mid):
            hi = mid
        else:
            lo = mid
    return hi
```

---

## 🧱 Bloque 06 — Lineales y hashing

### `06/01` — Pila, cola y deque [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §3](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#3--pila-cola-y-deque).

```python
from collections import deque

stack = []          # pila: append, stack[-1], pop()
dq = deque()        # cola y deque: append, appendleft, dq[0], dq[-1], popleft(), pop()
```

### `06/01` — Pila monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §4](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#4--pila-monótona).

```python
def next_greater(a):
    """Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n)."""
    ans, st = [-1] * len(a), []
    for i, x in enumerate(a):
        while st and a[st[-1]] < x:
            ans[st.pop()] = i
        st.append(i)
    return ans
```

### `06/01` — Cola monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §5](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#5--cola-monótona).

```python
from collections import deque

def window_min(a, k):
    """mins[i] = mínimo de a[i:i+k]. Θ(n)."""
    dq, mins = deque(), []
    for i, x in enumerate(a):
        while dq and a[dq[-1]] >= x:
            dq.pop()
        dq.append(i)
        if dq[0] <= i - k:
            dq.popleft()
        if i >= k - 1:
            mins.append(a[dq[0]])
    return mins
```

### `06/02` — Inversión, punto medio y mezcla [A]

De [`06/02` — Listas enlazadas, §3](../06-lineales-y-hashing/02-listas-enlazadas.md#3--inversión-punto-medio-y-mezcla).

```python
class ListNode:
    __slots__ = ("val", "next")
    def __init__(self, val, next=None):
        self.val, self.next = val, next

def reverse(head):
    prev = None
    while head:
        head.next, prev, head = prev, head, head.next   # la tupla se evalúa entera antes de asignar
    return prev

def middle(head):
    slow = fast = head
    while fast and fast.next:
        slow, fast = slow.next, fast.next.next
    return slow

def merge(a, b):
    dummy = tail = ListNode(0)
    while a and b:
        if b.val < a.val:
            tail.next, b = b, b.next
        else:
            tail.next, a = a, a.next
        tail = tail.next
    tail.next = a or b
    return dummy.next
```

### `06/02` — Floyd: detectar el ciclo y su inicio [A]

De [`06/02` — Listas enlazadas, §4](../06-lineales-y-hashing/02-listas-enlazadas.md#4--floyd-detectar-el-ciclo-y-su-inicio).

```python
def cycle_start(head):
    """Inicio del ciclo, o None si la lista termina. O(n) tiempo, O(1) memoria."""
    slow = fast = head
    while fast and fast.next:
        slow, fast = slow.next, fast.next.next
        if slow is fast:
            p = head
            while p is not slow:
                p, slow = p.next, slow.next
            return p
    return None
```

### `06/02` — La caché LRU [A]

De [`06/02` — Listas enlazadas, §5](../06-lineales-y-hashing/02-listas-enlazadas.md#5--la-caché-lru).

```python
from collections import OrderedDict

class LRUCache:
    """LRU de capacidad cap. O(1) por operación."""
    def __init__(self, cap):
        self.cap, self.d = cap, OrderedDict()   # el final es el más reciente

    def get(self, key):
        if key not in self.d:
            return -1
        self.d.move_to_end(key)
        return self.d[key]

    def put(self, key, value):
        self.d[key] = value
        self.d.move_to_end(key)
        if len(self.d) > self.cap:
            self.d.popitem(last=False)          # el primero es el menos reciente
```

### `06/03` — Encadenamiento y direccionamiento abierto [A]

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §3](../06-lineales-y-hashing/03-tablas-hash.md#3--encadenamiento-y-direccionamiento-abierto).

```python
class IntSet:
    """Conjunto con sondeo lineal; capacidad potencia de 2; α ≤ 1/2. Didáctico: en Python, usa set."""
    def __init__(self, cap=16):
        self.keys, self.n = [None] * cap, 0

    def _slot(self, x):
        return hash(x) & (len(self.keys) - 1)

    def __contains__(self, x):
        i = self._slot(x)
        while self.keys[i] is not None:
            if self.keys[i] == x:
                return True
            i = (i + 1) & (len(self.keys) - 1)
        return False

    def add(self, x):
        if 2 * (self.n + 1) > len(self.keys):
            old, self.keys, self.n = self.keys, [None] * (2 * len(self.keys)), 0
            for k in old:
                if k is not None:
                    self.add(k)
        i = self._slot(x)
        while self.keys[i] is not None:
            if self.keys[i] == x:
                return
            i = (i + 1) & (len(self.keys) - 1)
        self.keys[i], self.n = x, self.n + 1
```

---

## 🧱 Bloque 07 — Árboles

### `07/01` — Representación [A]

De [`07/01` — Árboles: representación y recorridos, §3](../07-arboles/01-arboles-y-recorridos.md#3--representación).

```python
def build_tree(n, edges):
    """Árbol de n nodos (1..n) a partir de sus n − 1 aristas no dirigidas."""
    adj = [[] for _ in range(n + 1)]
    for u, v in edges:
        adj[u].append(v)
        adj[v].append(u)
    return adj
```

### `07/01` — Los cuatro recorridos [A]

De [`07/01` — Árboles: representación y recorridos, §4](../07-arboles/01-arboles-y-recorridos.md#4--los-cuatro-recorridos).

```python
def inorder(t, out):
    if t:
        inorder(t.left, out); out.append(t.val); inorder(t.right, out)

def preorder(adj, root):
    """Preorden iterativo; devuelve (orden, parent, depth). O(n)."""
    n = len(adj)
    parent, depth, order, st = [0] * n, [0] * n, [], [root]
    parent[root] = -1
    while st:
        v = st.pop()
        order.append(v)
        for w in adj[v]:
            if w != parent[v]:
                parent[w], depth[w] = v, depth[v] + 1
                st.append(w)
    return order, parent, depth
```

### `07/01` — Diámetro [A]

De [`07/01` — Árboles: representación y recorridos, §5](../07-arboles/01-arboles-y-recorridos.md#5--diámetro).

```python
from collections import deque

def farthest(adj, s):
    """(nodo más lejano de s, distancia). BFS sobre árbol sin pesos. O(n)."""
    dist = [-1] * len(adj)
    dist[s] = 0
    q, best = deque([s]), s
    while q:
        v = q.popleft()
        if dist[v] > dist[best]:
            best = v
        for w in adj[v]:
            if dist[w] < 0:
                dist[w] = dist[v] + 1
                q.append(w)
    return best, dist[best]

def diameter(adj):
    return farthest(adj, farthest(adj, 1)[0])[1]
```

### `07/02` — El árbol binario de búsqueda [A]

De [`07/02` — BST y árboles balanceados, §3](../07-arboles/02-bst-y-balanceados.md#3--el-árbol-binario-de-búsqueda).

```python
class Node:
    __slots__ = ("key", "left", "right")
    def __init__(self, key):
        self.key, self.left, self.right = key, None, None

def insert(t, key):
    if t is None:
        return Node(key)
    if key < t.key:
        t.left = insert(t.left, key)
    elif key > t.key:
        t.right = insert(t.right, key)
    return t

def ceiling(t, x):
    """Menor clave >= x, o None. O(h)."""
    best = None
    while t:
        if t.key >= x:
            best, t = t, t.left
        else:
            t = t.right
    return best
```

### `07/04` — *Trie* de palabras [A]

De [`07/04` — *Tries*, §3](../07-arboles/04-tries.md#3--trie-de-palabras).

```python
class Trie:
    """Trie con diccionarios por nodo: insert y count_prefix en O(L)."""
    def __init__(self):
        self.next, self.pass_, self.end = [{}], [0], [0]

    def insert(self, w):
        v = 0
        for ch in w:
            nxt = self.next[v].get(ch)
            if nxt is None:
                nxt = len(self.next)
                self.next[v][ch] = nxt
                self.next.append({}); self.pass_.append(0); self.end.append(0)
            v = nxt
            self.pass_[v] += 1
        self.end[v] += 1

    def count_prefix(self, p):
        v = 0
        for ch in p:
            v = self.next[v].get(ch)
            if v is None:
                return 0
        return self.pass_[v]
```

### `07/04` — *Trie* binario [A]

De [`07/04` — *Tries*, §4](../07-arboles/04-tries.md#4--trie-binario).

```python
class XorTrie:
    """Trie binario de enteros no negativos de B bits; borrado con contadores. O(B) por operación."""
    B = 30

    def __init__(self):
        self.next, self.cnt = [[0, 0]], [0]

    def add(self, x, d=1):
        v = 0
        for b in range(self.B - 1, -1, -1):
            bit = (x >> b) & 1
            if not self.next[v][bit]:
                self.next[v][bit] = len(self.next)
                self.next.append([0, 0]); self.cnt.append(0)
            v = self.next[v][bit]
            self.cnt[v] += d

    def max_xor(self, x):
        v, res = 0, 0
        for b in range(self.B - 1, -1, -1):
            want = ((x >> b) & 1) ^ 1
            u = self.next[v][want]
            if u and self.cnt[u] > 0:
                res |= 1 << b; v = u
            else:
                v = self.next[v][want ^ 1]
        return res
```

### `07/05` — *Binary lifting* [A]

De [`07/05` — LCA, §3](../07-arboles/05-lca.md#3--binary-lifting).

```python
class Lca:
    """Binary lifting. parent[root] = root; order = preorden (cada padre antes que sus hijos)."""
    def __init__(self, parent, depth, order):
        n = len(parent)
        self.LOG = max(1, (n - 1).bit_length())
        self.depth = depth
        self.up = [parent[:]]
        for k in range(1, self.LOG):
            prev = self.up[-1]
            self.up.append([prev[prev[v]] for v in range(n)])

    def lift(self, v, d):
        k = 0
        while d:
            if d & 1:
                v = self.up[k][v]
            d >>= 1; k += 1
        return v

    def lca(self, u, v):
        if self.depth[u] < self.depth[v]:
            u, v = v, u
        u = self.lift(u, self.depth[u] - self.depth[v])
        if u == v:
            return u
        for k in range(self.LOG - 1, -1, -1):
            if self.up[k][u] != self.up[k][v]:
                u, v = self.up[k][u], self.up[k][v]
        return self.up[0][u]
```

---

## 🧱 Bloque 08 — Heaps y Union-Find

### `08/01` — El montículo binario [A]

De [`08/01` — Montículo binario, §3](../08-heaps-y-union-find/01-monticulo-binario.md#3--el-montículo-binario).

```python
class MinHeap:
    """Montículo de mínimos sobre una lista. push y pop en O(log n). Didáctico: en Python, heapq."""
    def __init__(self):
        self.a = []

    def push(self, x):
        a = self.a
        a.append(x)
        i = len(a) - 1
        while i > 0 and a[(i - 1) // 2] > a[i]:
            p = (i - 1) // 2
            a[i], a[p] = a[p], a[i]
            i = p

    def pop(self):
        a = self.a
        res, last = a[0], a.pop()
        if a:
            a[0], i, n = last, 0, len(a)
            while 2 * i + 1 < n:
                c = 2 * i + 1
                if c + 1 < n and a[c + 1] < a[c]:
                    c += 1
                if a[i] <= a[c]:
                    break
                a[i], a[c] = a[c], a[i]
                i = c
        return res
```

### `08/01` — `heapify` [A]

De [`08/01` — Montículo binario, §4](../08-heaps-y-union-find/01-monticulo-binario.md#4--heapify).

```python
import heapq

a = [5, 2, 9, 1, 5, 6]
heapq.heapify(a)          # en el sitio, O(n): a queda [1, 2, 6, 5, 5, 9]
```

### `08/02` — Los `k` mayores [A]

De [`08/02` — Patrones con *heap*, §3](../08-heaps-y-union-find/02-patrones-con-heap.md#3--los-k-mayores).

```python
import heapq

def top_k(a, k):
    """Los k mayores de a (en orden creciente). Pre: k >= 1. O(n log k) tiempo, O(k) memoria."""
    h = []
    for x in a:
        if len(h) < k:
            heapq.heappush(h, x)
        elif x > h[0]:
            heapq.heapreplace(h, x)          # saca la cima y mete x en una sola bajada
    return sorted(h)
```

### `08/02` — Mezcla de `k` listas [A]

De [`08/02` — Patrones con *heap*, §4](../08-heaps-y-union-find/02-patrones-con-heap.md#4--mezcla-de-k-listas).

```python
import heapq

def merge_k(lists):
    """Mezcla k listas ordenadas. O(N log k)."""
    h = [(l[0], i, 0) for i, l in enumerate(lists) if l]
    heapq.heapify(h)
    out = []
    while h:
        v, i, j = heapq.heappop(h)
        out.append(v)
        if j + 1 < len(lists[i]):
            heapq.heappush(h, (lists[i][j + 1], i, j + 1))
    return out
```

### `08/02` — La mediana con dos *heaps* [A]

De [`08/02` — Patrones con *heap*, §5](../08-heaps-y-union-find/02-patrones-con-heap.md#5--la-mediana-con-dos-heaps).

```python
import heapq

class RunningMedian:
    """Mediana inferior de un flujo. add O(log n), median O(1)."""
    def __init__(self):
        self.lo, self.hi = [], []            # lo guarda negados (montículo de máximos)

    def add(self, x):
        if not self.lo or x <= -self.lo[0]:
            heapq.heappush(self.lo, -x)
        else:
            heapq.heappush(self.hi, x)
        if len(self.lo) > len(self.hi) + 1:
            heapq.heappush(self.hi, -heapq.heappop(self.lo))
        elif len(self.hi) > len(self.lo):
            heapq.heappush(self.lo, -heapq.heappop(self.hi))

    def median(self):
        return -self.lo[0]
```

### `08/04` — Union-Find [A]

De [`08/04` — Union-Find, §3](../08-heaps-y-union-find/04-union-find.md#3--union-find).

```python
class DSU:
    """Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado."""
    def __init__(self, n):
        self.parent, self.size = list(range(n)), [1] * n

    def find(self, x):
        p = self.parent
        while p[x] != x:
            p[x] = p[p[x]]
            x = p[x]
        return x

    def unite(self, a, b):
        a, b = self.find(a), self.find(b)
        if a == b:
            return False
        if self.size[a] < self.size[b]:
            a, b = b, a
        self.parent[b] = a
        self.size[a] += self.size[b]
        return True
```

---

## 🧱 Bloque 09 — Consultas sobre rangos

### `09/02` — Puntual y rango [A]

De [`09/02` — Fenwick, §3](../09-consultas-sobre-rangos/02-fenwick.md#3--puntual-y-rango).

```python
class Fenwick:
    """Fenwick de sumas, índices 1..n. add y prefix en O(log n)."""
    def __init__(self, n):
        self.n, self.t = n, [0] * (n + 1)

    def add(self, i, d):
        while i <= self.n:
            self.t[i] += d
            i += i & -i

    def prefix(self, i):
        s = 0
        while i > 0:
            s += self.t[i]
            i -= i & -i
        return s

    def range(self, l, r):
        return self.prefix(r) - self.prefix(l - 1)
```

### `09/02` — Rango y puntual [A]

De [`09/02` — Fenwick, §4](../09-consultas-sobre-rangos/02-fenwick.md#4--rango-y-puntual).

```python
def range_add(f, l, r, v):
    f.add(l, v)
    f.add(r + 1, -v)          # el Fenwick tiene tamaño n + 1

def point_get(f, i):
    return f.prefix(i)
```

### `09/03` — Iterativo [B]

De [`09/03` — Segment tree, §3](../09-consultas-sobre-rangos/03-segment-tree.md#3--iterativo).

```python
class SegTree:
    """Segment tree iterativo con operación genérica. Consulta [l, r), actualización puntual."""
    def __init__(self, a, op=min, e=float("inf")):
        self.n, self.op, self.e = len(a), op, e
        self.t = [e] * self.n + list(a)
        for i in range(self.n - 1, 0, -1):
            self.t[i] = op(self.t[2 * i], self.t[2 * i + 1])

    def set(self, p, v):
        p += self.n
        self.t[p] = v
        while p > 1:
            p >>= 1
            self.t[p] = self.op(self.t[2 * p], self.t[2 * p + 1])

    def query(self, l, r):
        resl = resr = self.e
        l += self.n; r += self.n
        while l < r:
            if l & 1:
                resl = self.op(resl, self.t[l]); l += 1
            if r & 1:
                r -= 1; resr = self.op(self.t[r], resr)
            l >>= 1; r >>= 1
        return self.op(resl, resr)
```

---

## 🧱 Bloque 10 — Búsqueda completa y divide y vencerás

### `10/01` — Recursión y pila de llamadas [A]

De [`10/01` — Recursión, §3](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#3--recursión-y-pila-de-llamadas).

```python
def hanoi(n, src, dst, via, out):
    """Mueve n discos de src a dst usando via. Θ(2ⁿ) tiempo, Θ(n) pila."""
    if n == 0:
        return                                  # caso base
    hanoi(n - 1, src, via, dst, out)
    out.append(f"{src} {dst}")
    hanoi(n - 1, via, dst, src, out)
```

### `10/01` — Paso a iterativo [A]

De [`10/01` — Recursión, §4](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#4--paso-a-iterativo).

```python
def hanoi_iterative(n, src, dst, via, out):
    """Hanoi iterativo: marcos [n, src, dst, via, etapa] en una lista. Θ(2ⁿ) tiempo, Θ(n) memoria."""
    stack = [[n, src, dst, via, 0]]
    while stack:
        f = stack[-1]
        k, a, b, c, stage = f
        if k == 0 or stage == 2:
            stack.pop()                                  # base o terminado: vuelve
        elif stage == 0:
            f[4] = 1
            stack.append([k - 1, a, c, b, 0])            # hanoi(k−1, src, via, dst)
        else:
            out.append(f"{a} {b}")
            f[4] = 2
            stack.append([k - 1, c, b, a, 0])            # hanoi(k−1, via, dst, src)
```

### `10/02` — Subconjuntos con máscaras de bits [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §3](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#3--subconjuntos-con-máscaras-de-bits).

```python
def subset_sums(a):
    """sum[m] = suma de los a[i] con el bit i encendido en m. Θ(2ⁿ) tiempo y memoria."""
    n = len(a)
    total = [0] * (1 << n)
    for m in range(1, 1 << n):
        low = (m & -m).bit_length() - 1              # índice del bit más bajo
        total[m] = total[m & (m - 1)] + a[low]
    return total
```

### `10/02` — Permutaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §4](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#4--permutaciones).

```python
def next_permutation(a):
    """Siguiente permutación lexicográfica en su sitio; False si a era la última."""
    i = len(a) - 2
    while i >= 0 and a[i] >= a[i + 1]:
        i -= 1
    if i < 0:
        return False
    j = len(a) - 1
    while a[j] <= a[i]:
        j -= 1
    a[i], a[j] = a[j], a[i]
    a[i + 1:] = reversed(a[i + 1:])
    return True

def permute(a, cur, used):
    """Recursiva: añade a cur cada índice no usado y deshace al volver."""
    if len(cur) == len(a):
        return  # procesar cur
    for i in range(len(a)):
        if not used[i]:
            used[i] = True
            cur.append(a[i])
            permute(a, cur, used)
            cur.pop()
            used[i] = False
```

### `10/02` — Combinaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §5](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#5--combinaciones).

```python
from itertools import combinations

def combine(n, k, start, cur):
    """Todas las combinaciones de k índices de [0, n), en orden lexicográfico."""
    if len(cur) == k:
        return  # procesar cur
    for i in range(start, n - (k - len(cur)) + 1):              # poda: quedan huecos suficientes
        cur.append(i)
        combine(n, k, i + 1, cur)
        cur.pop()

# Sin recursión: for c in combinations(range(n), k): ...   (mismo orden, en C)
```

### `10/03` — *Backtracking* [A]

De [`10/03` — *Backtracking* con poda y ramificación y poda, §3](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#3--backtracking).

```python
def count_subsets(a, suffix, start, rem):
    """Subconjuntos (por posición) de a con suma exacta rem. a ascendente, positivos."""
    if rem == 0:
        return 1
    count = 0
    for j in range(start, len(a)):
        if a[j] > rem or suffix[j] < rem:                     # las dos podas
            break
        count += count_subsets(a, suffix, j + 1, rem - a[j])
    return count
```

### `10/05` — El esquema [A]

De [`10/05` — Divide y vencerás, §3](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#3--el-esquema).

```python
def max_subarray(a, lo, hi):
    """Suma máxima de un subarreglo no vacío de a[lo:hi]. Θ(n log n). Pre: lo < hi."""
    if hi - lo == 1:
        return a[lo]
    mid = (lo + hi) // 2
    best = max(max_subarray(a, lo, mid), max_subarray(a, mid, hi))
    s, left_best = 0, float("-inf")
    for i in range(mid - 1, lo - 1, -1):
        s += a[i]
        left_best = max(left_best, s)
    s, right_best = 0, float("-inf")
    for i in range(mid, hi):
        s += a[i]
        right_best = max(right_best, s)
    return max(best, left_best + right_best)
```

### `10/05` — Exponenciación rápida [A]

De [`10/05` — Divide y vencerás, §6](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#6--exponenciación-rápida).

```python
def pow_mod(a, n, m):
    """aⁿ mod m. Θ(log n). En la práctica: pow(a, n, m), que hace lo mismo en C."""
    result, base = 1 % m, a % m
    while n > 0:
        if n & 1:
            result = result * base % m
        base = base * base % m
        n >>= 1
    return result
```

---

## 🧱 Bloque 11 — Voraces

### `11/02` — Selección de actividades [A]

De [`11/02` — Intervalos, §3](../11-voraces/02-intervalos.md#3--selección-de-actividades).

```python
def max_disjoint(intervals):
    """Máximo número de intervalos [s, f) disjuntos. Θ(n log n)."""
    count, last_end = 0, float("-inf")
    for s, f in sorted(intervals, key=lambda iv: iv[1]):
        if s >= last_end:
            count += 1
            last_end = f
    return count
```

### `11/02` — Cubrimiento con puntos [A]

De [`11/02` — Intervalos, §4](../11-voraces/02-intervalos.md#4--cubrimiento-con-puntos).

```python
def min_points(intervals):
    """Mínimo de puntos que pinchan todos los intervalos cerrados [s, f]. Θ(n log n)."""
    count, last = 0, float("-inf")
    for s, f in sorted(intervals, key=lambda iv: iv[1]):
        if s > last:
            count += 1
            last = f
    return count
```

### `11/02` — Mezcla [A]

De [`11/02` — Intervalos, §5](../11-voraces/02-intervalos.md#5--mezcla).

```python
def merge_intervals(intervals):
    """Unión de intervalos cerrados [s, f], como lista ordenada de disjuntos. Θ(n log n)."""
    out = []
    for s, f in sorted(intervals):
        if out and s <= out[-1][1]:
            out[-1][1] = max(out[-1][1], f)
        else:
            out.append([s, f])
    return out
```

### `11/02` — Mínimo de salas [A]

De [`11/02` — Intervalos, §6](../11-voraces/02-intervalos.md#6--mínimo-de-salas).

```python
def min_rooms(intervals):
    """Mínimo de salas para reuniones [s, f) (profundidad). Θ(n log n)."""
    starts = sorted(s for s, _ in intervals)
    ends = sorted(f for _, f in intervals)
    rooms = best = j = 0
    for s in starts:
        while j < len(ends) and ends[j] <= s:
            j += 1
            rooms -= 1
        rooms += 1
        best = max(best, rooms)
    return best
```

### `11/03` — Planificación con plazos [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §3](../11-voraces/03-plazos-huffman-y-monedas.md#3--planificación-con-plazos).

```python
import heapq

def max_profit(jobs):
    """Máximo beneficio de tareas unitarias (plazo, beneficio) que acaban a tiempo. Θ(n log n)."""
    kept, total = [], 0
    for d, p in sorted(jobs):
        heapq.heappush(kept, p)
        total += p
        if len(kept) > d:
            total -= heapq.heappop(kept)
    return total
```

### `11/03` — Huffman [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §4](../11-voraces/03-plazos-huffman-y-monedas.md#4--huffman).

```python
import heapq

def huffman_cost(freq):
    """Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman. Θ(n log n)."""
    heap = list(freq)
    heapq.heapify(heap)
    cost = 0
    while len(heap) > 1:
        a, b = heapq.heappop(heap), heapq.heappop(heap)
        cost += a + b
        heapq.heappush(heap, a + b)
    return cost
```

### `11/03` — Mochila fraccionaria [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §5](../11-voraces/03-plazos-huffman-y-monedas.md#5--mochila-fraccionaria).

```python
from fractions import Fraction

def fractional_knapsack(items, cap):
    """Valor máximo con materiales divisibles (peso, valor), exacto con Fraction. Θ(n log n)."""
    value = Fraction(0)
    for w, v in sorted(items, key=lambda it: Fraction(it[1], it[0]), reverse=True):
        if cap == 0:
            break
        take = min(w, cap)
        value += Fraction(v * take, w)
        cap -= take
    return value
```

### `11/03` — Monedas canónicas [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §6](../11-voraces/03-plazos-huffman-y-monedas.md#6--monedas-canónicas).

```python
def greedy_coins(coins, x):
    """Monedas del voraz para x; coins de mayor a menor, con la de 1. O(k)."""
    count = 0
    for c in coins:
        count += x // c
        x %= c
    return count
```

---

## 🧱 Bloque 12 — DP clásica

### `12/01` — Memoización [A]

De [`12/01` — De la recursión a la tabla, §3](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#3--memoización).

```python
from functools import cache

MOD = 1_000_000_007

@cache
def ways(i):
    """Formas de llegar al escalón i con pasos de 1, 2 o 3."""
    if i < 0:
        return 0
    if i == 0:
        return 1
    return (ways(i - 1) + ways(i - 2) + ways(i - 3)) % MOD
```

### `12/01` — Tabulación [A]

De [`12/01` — De la recursión a la tabla, §4](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#4--tabulación).

```python
def ways_table(n, broken):
    """Formas de subir n escalones con pasos de 1, 2 o 3, sin pisar los rotos. Θ(n)."""
    MOD = 1_000_000_007
    dp = [0] * (n + 1)
    dp[0] = 1
    for i in range(1, n + 1):
        if not broken[i]:
            dp[i] = sum(dp[i - s] for s in (1, 2, 3) if s <= i) % MOD
    return dp[n]
```

### `12/01` — Reconstrucción [A]

De [`12/01` — De la recursión a la tabla, §5](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#5--reconstrucción).

```python
def ops_path(n):
    """Menor número de operaciones +1, ×2, ×3 de 1 a n, y la secuencia. Θ(n)."""
    dp, parent = [0] * (n + 1), [0] * (n + 1)
    for x in range(2, n + 1):
        dp[x], parent[x] = dp[x - 1] + 1, x - 1
        for d in (2, 3):
            if x % d == 0 and dp[x // d] + 1 < dp[x]:
                dp[x], parent[x] = dp[x // d] + 1, x // d
    path, x = [], n
    while x != 1:
        path.append(x)                                   # se sigue la cadena de padres
        x = parent[x]
    path.append(1)
    return path[::-1]
```

### `12/02` — Escaleras y robos [A]

De [`12/02` — DP lineal y LIS, §3](../12-dp-clasica/02-dp-lineal-y-lis.md#3--escaleras-y-robos).

```python
def max_non_adjacent(a):
    """Mayor suma de elementos sin coger dos consecutivos. Θ(n), O(1) memoria."""
    take = skip = 0
    for x in a:
        take, skip = skip + x, max(take, skip)       # asignación simultánea
    return max(take, skip)
```

### `12/02` — LIS en O(n²) [A]

De [`12/02` — DP lineal y LIS, §4](../12-dp-clasica/02-dp-lineal-y-lis.md#4--lis-en-on).

```python
def lis_quadratic(a):
    """Una LIS estrictamente creciente, por índices. Θ(n²)."""
    n = len(a)
    d, parent = [1] * n, [-1] * n
    for i in range(n):
        for j in range(i):
            if a[j] < a[i] and d[j] + 1 > d[i]:
                d[i], parent[i] = d[j] + 1, j
    i = max(range(n), key=d.__getitem__) if n else -1
    seq = []
    while i != -1:
        seq.append(i)
        i = parent[i]
    return seq[::-1]
```

### `12/02` — LIS en O(n log n) [A]

De [`12/02` — DP lineal y LIS, §5](../12-dp-clasica/02-dp-lineal-y-lis.md#5--lis-en-on-log-n).

```python
from bisect import bisect_left

def lis_fast(a):
    """Una LIS estrictamente creciente, por índices. Θ(n log n)."""
    tails, tail_idx, parent = [], [], [-1] * len(a)
    for i, x in enumerate(a):
        k = bisect_left(tails, x)                  # estricta; bisect_right para no decreciente
        if k == len(tails):
            tails.append(x)
            tail_idx.append(i)
        else:
            tails[k], tail_idx[k] = x, i
        if k > 0:
            parent[i] = tail_idx[k - 1]
    seq, i = [], tail_idx[-1] if tail_idx else -1
    while i != -1:
        seq.append(i)
        i = parent[i]
    return seq[::-1]
```

### `12/03` — Mochila 0/1 [A]

De [`12/03` — Mochilas, §3](../12-dp-clasica/03-mochilas.md#3--mochila-01).

```python
def knapsack01(w, v, W):
    """Mochila 0/1: mejor valor y los índices elegidos. Θ(n · W)."""
    n = len(w)
    dp = [[0] * (W + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        wi, vi = w[i - 1], v[i - 1]
        prev, row = dp[i - 1], dp[i]
        for c in range(W + 1):
            row[c] = prev[c]
            if wi <= c and prev[c - wi] + vi > row[c]:
                row[c] = prev[c - wi] + vi
    chosen, c = [], W
    for i in range(n, 0, -1):
        if dp[i][c] != dp[i - 1][c]:
            chosen.append(i - 1)
            c -= w[i - 1]
    return dp[n][W], chosen[::-1]
```

### `12/03` — Una fila de memoria [A]

De [`12/03` — Mochilas, §4](../12-dp-clasica/03-mochilas.md#4--una-fila-de-memoria).

```python
def knapsack_row(w, v, W):
    """Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria."""
    dp = [0] * (W + 1)
    for wi, vi in zip(w, v):
        for c in range(W, wi - 1, -1):                             # descendente
            if dp[c - wi] + vi > dp[c]:
                dp[c] = dp[c - wi] + vi
    return dp[W]
```

### `12/03` — Mochila ilimitada [A]

De [`12/03` — Mochilas, §5](../12-dp-clasica/03-mochilas.md#5--mochila-ilimitada).

```python
def knapsack_unbounded(w, v, W):
    """Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W)."""
    dp = [0] * (W + 1)
    for wi, vi in zip(w, v):
        for c in range(wi, W + 1):                                 # ascendente
            if dp[c - wi] + vi > dp[c]:
                dp[c] = dp[c - wi] + vi
    return dp[W]
```

### `12/03` — Monedas: contar y mínimo [A]

De [`12/03` — Mochilas, §6](../12-dp-clasica/03-mochilas.md#6--monedas-contar-y-mínimo).

```python
MOD = 1_000_000_007

def count_combinations(coins, x):
    """Combinaciones (sin orden) de pagar x: monedas por fuera."""
    ways = [1] + [0] * x
    for c in coins:
        for s in range(c, x + 1):
            ways[s] = (ways[s] + ways[s - c]) % MOD
    return ways[x]

def min_coins(coins, x):
    """Mínimo de monedas para pagar x, o -1."""
    INF = float("inf")
    mn = [0] + [INF] * x
    for s in range(1, x + 1):
        mn[s] = min((mn[s - c] + 1 for c in coins if c <= s), default=INF)
    return -1 if mn[x] == INF else mn[x]
```

### `12/04` — LCS [A]

De [`12/04` — DP sobre cadenas, §3](../12-dp-clasica/04-dp-sobre-cadenas.md#3--lcs).

```python
def lcs(a, b):
    """Una subsecuencia común más larga de a y b. Θ(n · m)."""
    n, m = len(a), len(b)
    L = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            L[i][j] = L[i - 1][j - 1] + 1 if a[i - 1] == b[j - 1] else max(L[i - 1][j], L[i][j - 1])
    out, i, j = [], n, m
    while i > 0 and j > 0:
        if a[i - 1] == b[j - 1]:
            out.append(a[i - 1]); i -= 1; j -= 1
        elif L[i - 1][j] >= L[i][j - 1]:
            i -= 1
        else:
            j -= 1
    return "".join(reversed(out))
```

### `12/04` — Distancia de edición [A]

De [`12/04` — DP sobre cadenas, §4](../12-dp-clasica/04-dp-sobre-cadenas.md#4--distancia-de-edición).

```python
def edit_distance(a, b):
    """Distancia de Levenshtein entre a y b, con dos filas. Θ(n · m) tiempo, Θ(m) memoria."""
    prev = list(range(len(b) + 1))
    for i in range(1, len(a) + 1):
        cur = [i] + [0] * len(b)
        for j in range(1, len(b) + 1):
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] != b[j - 1]))
        prev = cur
    return prev[len(b)]
```

### `12/04` — Subsecuencias y palíndromos [A]

De [`12/04` — DP sobre cadenas, §5](../12-dp-clasica/04-dp-sobre-cadenas.md#5--subsecuencias-y-palíndromos).

```python
def longest_pal_subseq(s):
    """Longitud de la subsecuencia palindrómica más larga de s. Θ(n²)."""
    n = len(s)
    P = [[0] * n for _ in range(n)]
    for i in range(n - 1, -1, -1):
        P[i][i] = 1
        for j in range(i + 1, n):
            P[i][j] = P[i + 1][j - 1] + 2 if s[i] == s[j] else max(P[i + 1][j], P[i][j - 1])
    return P[0][n - 1] if n else 0
```

### `12/05` — Rejillas [A]

De [`12/05` — DP en rejillas y de intervalos, §3](../12-dp-clasica/05-rejillas-e-intervalos.md#3--rejillas).

```python
def best_path(g):
    """Máximo recogido bajando o a la derecha; '#' bloquea; '.' vale 0. -1 si no hay camino."""
    R, C = len(g), len(g[0])
    d = [None] * C                                             # None = inalcanzable
    for i in range(R):
        for j in range(C):
            if g[i][j] == "#":
                d[j] = None
                continue
            options = [0] if i == j == 0 else [x for x in (d[j], d[j - 1] if j else None) if x is not None]
            d[j] = max(options) + (0 if g[i][j] == "." else int(g[i][j])) if options else None
    return -1 if d[-1] is None else d[-1]
```

### `12/06` — Conteo [A]

De [`12/06` — Conteo con DP, §3](../12-dp-clasica/06-conteo.md#3--conteo).

```python
MOD = 1_000_000_007

def count_words(n, allowed):
    """Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]."""
    L = len(allowed)
    cur = [1] * L
    for _ in range(n - 1):
        cur = [sum(cur[p] for p in range(L) if allowed[p][c]) % MOD for c in range(L)]
    return sum(cur) % MOD
```

---

## 🧱 Bloque 13 — DP avanzada

### `13/03` — DP en árboles [A]

De [`13/03` — DP en árboles y en DAG, §3](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#3--dp-en-árboles).

```python
def max_independent_set(parent, w):
    """Conjunto independiente de peso máximo en un árbol con raíz 0 y padres parent (parent[0] = -1)."""
    n = len(parent)
    children = [[] for _ in range(n)]
    for v in range(1, n):
        children[parent[v]].append(v)
    order, stack = [], [0]
    while stack:                                   # preorden iterativo
        v = stack.pop()
        order.append(v)
        stack.extend(children[v])
    inc, exc = [0] * n, [0] * n
    for v in reversed(order):                      # hijos antes que padres
        inc[v] = w[v] + sum(exc[c] for c in children[v])
        exc[v] = sum(max(inc[c], exc[c]) for c in children[v])
    return max(inc[0], exc[0])
```

### `13/03` — DP sobre DAG [A]

De [`13/03` — DP en árboles y en DAG, §4](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#4--dp-sobre-dag).

```python
from collections import deque

def dag_dp(n, adj, s):
    """En un DAG con adj[u] = [(v, w)]: (caminos desde s mod p, camino más largo). Θ(V + E)."""
    MOD = 1_000_000_007
    indeg = [0] * n
    for u in range(n):
        for v, _ in adj[u]:
            indeg[v] += 1
    q = deque(u for u in range(n) if indeg[u] == 0)
    order = []
    while q:                                       # Kahn
        u = q.popleft()
        order.append(u)
        for v, _ in adj[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    ways, longest = [0] * n, [None] * n
    ways[s], longest[s] = 1, 0
    for u in order:
        if longest[u] is None:
            continue
        for v, w in adj[u]:
            ways[v] = (ways[v] + ways[u]) % MOD
            longest[v] = longest[u] + w if longest[v] is None else max(longest[v], longest[u] + w)
    return ways, longest
```

---

## 🧱 Bloque 14 — Grafos: recorridos

### `14/01` — Representaciones [A]

De [`14/01` — Representaciones y su coste, §3](../14-grafos-recorridos/01-representaciones.md#3--representaciones).

```python
import sys

def read_graph():
    """Lee n, m y m aristas no dirigidas «u v w» en listas de adyacencia (índices desde 0)."""
    data = sys.stdin.buffer.read().split()
    n, m = int(data[0]), int(data[1])
    adj = [[] for _ in range(n)]
    idx = 2
    for _ in range(m):
        u, v, w = int(data[idx]) - 1, int(data[idx + 1]) - 1, int(data[idx + 2])
        idx += 3
        adj[u].append((v, w))
        adj[v].append((u, w))
    return n, adj
```

### `14/02` — BFS [A]

De [`14/02` — BFS, §3](../14-grafos-recorridos/02-bfs.md#3--bfs).

```python
from collections import deque

def bfs(adj, sources):
    """Distancias desde las fuentes (−1 = inalcanzable) y el arreglo de padres."""
    n = len(adj)
    dist, parent = [-1] * n, [-1] * n
    q = deque(sources)
    for s in sources:
        dist[s] = 0
    while q:
        u = q.popleft()
        for v in adj[u]:
            if dist[v] == -1:
                dist[v] = dist[u] + 1
                parent[v] = u
                q.append(v)
    return dist, parent
```

### `14/02` — Multifuente y rejillas [A]

De [`14/02` — BFS, §4](../14-grafos-recorridos/02-bfs.md#4--multifuente-y-rejillas).

```python
from collections import deque

def grid_bfs(g, sources):
    """Distancia de cada casilla a la fuente más cercana; −1 = pared o inalcanzable."""
    R, C = len(g), len(g[0])
    dist = [[-1] * C for _ in range(R)]
    q = deque(sources)
    for r, c in sources:
        dist[r][c] = 0
    while q:
        r, c = q.popleft()
        for r2, c2 in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= r2 < R and 0 <= c2 < C and g[r2][c2] != '#' and dist[r2][c2] == -1:
                dist[r2][c2] = dist[r][c] + 1
                q.append((r2, c2))
    return dist
```

### `14/02` — 0-1 BFS [A]

De [`14/02` — BFS, §5](../14-grafos-recorridos/02-bfs.md#5--0-1-bfs).

```python
from collections import deque

def bfs01(adj, s):
    """adj[u] = [(v, w)] con w en {0, 1}."""
    INF = float('inf')
    dist = [INF] * len(adj)
    dist[s] = 0
    dq = deque([s])
    while dq:
        u = dq.popleft()
        for v, w in adj[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                (dq.appendleft if w == 0 else dq.append)(v)
    return dist
```

### `14/02` — Estados compuestos [A]

De [`14/02` — BFS, §6](../14-grafos-recorridos/02-bfs.md#6--estados-compuestos).

```python
from collections import deque

def bfs_with_state(g, sr, sc, max_walls):
    """Pasos mínimos de (sr, sc) a T atravesando hasta max_walls muros. Estado (r, c, k) en un dict."""
    R, C = len(g), len(g[0])
    dist = {(sr, sc, 0): 0}
    q = deque([(sr, sc, 0)])
    while q:
        r, c, k = q.popleft()
        if g[r][c] == 'T':
            return dist[(r, c, k)]
        for r2, c2 in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
            if 0 <= r2 < R and 0 <= c2 < C:
                k2 = k + (g[r2][c2] == '#')
                if k2 <= max_walls and (r2, c2, k2) not in dist:
                    dist[(r2, c2, k2)] = dist[(r, c, k)] + 1
                    q.append((r2, c2, k2))
    return -1
```

### `14/03` — DFS [A]

De [`14/03` — DFS, §3](../14-grafos-recorridos/03-dfs.md#3--dfs).

```python
def dfs_all(adj):
    """DFS iterativo con tiempos; tin[v] = 0 marca «blanco»."""
    n = len(adj)
    tin, tout, parent, it = [0] * n, [0] * n, [-1] * n, [0] * n
    timer = 0
    for s in range(n):
        if tin[s]:
            continue
        timer += 1
        tin[s] = timer
        stack = [s]
        while stack:
            u = stack[-1]
            if it[u] < len(adj[u]):
                v = adj[u][it[u]]
                it[u] += 1
                if not tin[v]:
                    parent[v] = u
                    timer += 1
                    tin[v] = timer
                    stack.append(v)
            else:
                timer += 1
                tout[u] = timer
                stack.pop()
    return tin, tout, parent
```

### `14/03` — Componentes [A]

De [`14/03` — DFS, §4](../14-grafos-recorridos/03-dfs.md#4--componentes).

```python
def components(adj):
    """Etiqueta de componente por vértice y número de componentes."""
    n = len(adj)
    comp = [-1] * n
    c = 0
    for s in range(n):
        if comp[s] != -1:
            continue
        comp[s] = c
        stack = [s]
        while stack:
            u = stack.pop()
            for v in adj[u]:
                if comp[v] == -1:
                    comp[v] = c
                    stack.append(v)
        c += 1
    return comp, c
```

### `14/03` — Ciclos [A]

De [`14/03` — DFS, §5](../14-grafos-recorridos/03-dfs.md#5--ciclos).

```python
def has_directed_cycle(adj):
    """Tres colores, iterativo: True si hay una arista a un vértice gris."""
    n = len(adj)
    color, it = [0] * n, [0] * n
    for s in range(n):
        if color[s]:
            continue
        color[s] = 1
        stack = [s]
        while stack:
            u = stack[-1]
            if it[u] < len(adj[u]):
                v = adj[u][it[u]]
                it[u] += 1
                if color[v] == 1:
                    return True
                if color[v] == 0:
                    color[v] = 1
                    stack.append(v)
            else:
                color[u] = 2
                stack.pop()
    return False
```

### `14/03` — Bipartición [A]

De [`14/03` — DFS, §6](../14-grafos-recorridos/03-dfs.md#6--bipartición).

```python
def bipartite(adj):
    """Colores 0/1 por vértice, o None si hay un ciclo impar."""
    color = [-1] * len(adj)
    for s in range(len(adj)):
        if color[s] != -1:
            continue
        color[s] = 0
        stack = [s]
        while stack:
            u = stack.pop()
            for v in adj[u]:
                if color[v] == -1:
                    color[v] = color[u] ^ 1
                    stack.append(v)
                elif color[v] == color[u]:
                    return None
    return color
```

### `14/04` — Kahn [A]

De [`14/04` — Orden topológico y DP sobre DAG, §3](../14-grafos-recorridos/04-orden-topologico.md#3--kahn).

```python
from collections import deque

def kahn(adj):
    """Orden topológico, o None si hay ciclo."""
    n = len(adj)
    indeg = [0] * n
    for out in adj:
        for v in out:
            indeg[v] += 1
    q = deque(v for v in range(n) if indeg[v] == 0)
    order = []
    while q:
        u = q.popleft()
        order.append(u)
        for v in adj[u]:
            indeg[v] -= 1
            if indeg[v] == 0:
                q.append(v)
    return order if len(order) == n else None
```

### `14/04` — Por DFS [A]

De [`14/04` — Orden topológico y DP sobre DAG, §4](../14-grafos-recorridos/04-orden-topologico.md#4--por-dfs).

```python
def topo_dfs(adj):
    """Postorden invertido, iterativo; None si hay ciclo."""
    n = len(adj)
    color, it, post = [0] * n, [0] * n, []
    for s in range(n):
        if color[s]:
            continue
        color[s] = 1
        stack = [s]
        while stack:
            u = stack[-1]
            if it[u] < len(adj[u]):
                v = adj[u][it[u]]
                it[u] += 1
                if color[v] == 1:
                    return None
                if color[v] == 0:
                    color[v] = 1
                    stack.append(v)
            else:
                color[u] = 2
                stack.pop()
                post.append(u)
    return post[::-1]
```

---

## 🧱 Bloque 15 — Grafos con pesos y flujos

### `15/01` — Dijkstra con montículo [A]

De [`15/01` — Dijkstra, §3](../15-grafos-pesos-y-flujos/01-dijkstra.md#3--dijkstra-con-montículo).

```python
import heapq

def dijkstra(adj, s):
    """adj[u] = [(v, w)] con w >= 0. Distancias (inf = inalcanzable) y padres."""
    n = len(adj)
    INF = float('inf')
    dist, parent = [INF] * n, [-1] * n
    dist[s] = 0
    pq = [(0, s)]
    while pq:
        d, u = heapq.heappop(pq)
        if d > dist[u]:
            continue                                     # entrada vieja
        for v, w in adj[u]:
            nd = d + w
            if nd < dist[v]:
                dist[v] = nd
                parent[v] = u
                heapq.heappush(pq, (nd, v))
    return dist, parent
```

### `15/01` — Dijkstra sobre estados [A]

De [`15/01` — Dijkstra, §4](../15-grafos-pesos-y-flujos/01-dijkstra.md#4--dijkstra-sobre-estados).

```python
import heapq

def dijkstra_vouchers(adj, s, K):
    """Distancia mínima usando hasta K vales; estado (vértice, vales usados)."""
    n = len(adj)
    INF = float('inf')
    dist = [[INF] * (K + 1) for _ in range(n)]
    dist[s][0] = 0
    pq = [(0, s, 0)]
    while pq:
        d, u, k = heapq.heappop(pq)
        if d > dist[u][k]:
            continue
        for v, w in adj[u]:
            if d + w < dist[v][k]:
                dist[v][k] = d + w
                heapq.heappush(pq, (d + w, v, k))
            if k < K and d < dist[v][k + 1]:
                dist[v][k + 1] = d
                heapq.heappush(pq, (d, v, k + 1))
    return [min(row) for row in dist]
```

### `15/02` — Bellman-Ford [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §3](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#3--bellman-ford).

```python
def bellman_ford(n, edges, s):
    """edges = [(u, v, w)]. Devuelve (dist, hay_ciclo_negativo)."""
    INF = float('inf')
    dist = [INF] * n
    dist[s] = 0
    for rnd in range(n):
        changed = False
        for u, v, w in edges:
            if dist[u] != INF and dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                changed = True
        if not changed:
            return dist, False
    return dist, True                                    # la ronda n todavía mejoró
```

### `15/02` — Floyd-Warshall [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §4](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#4--floyd-warshall).

```python
def floyd_warshall(d):
    """d: matriz n × n con INF (float('inf')) sin arista y 0 en la diagonal; se modifica en el sitio."""
    n = len(d)
    for k in range(n):
        dk = d[k]
        for i in range(n):
            dik = d[i][k]
            if dik == float('inf'):
                continue
            di = d[i]
            for j in range(n):
                if dik + dk[j] < di[j]:
                    di[j] = dik + dk[j]
```

### `15/04` — Kruskal [A]

De [`15/04` — Árbol de expansión mínima, §3](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#3--kruskal).

```python
def kruskal(n, edges):
    """edges = [(w, u, v)]. Peso del MST, o -1 si no es conexo."""
    parent, size = list(range(n)), [1] * n

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    total = used = 0
    for w, u, v in sorted(edges):
        a, b = find(u), find(v)
        if a == b:
            continue
        if size[a] < size[b]:
            a, b = b, a
        parent[b] = a
        size[a] += size[b]
        total += w
        used += 1
        if used == n - 1:
            break
    return total if used == n - 1 else -1
```

### `15/04` — Prim [A]

De [`15/04` — Árbol de expansión mínima, §4](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#4--prim).

```python
import heapq

def prim(adj):
    """adj[u] = [(v, w)]. Peso del MST, o -1 si no es conexo."""
    n = len(adj)
    in_tree = [False] * n
    pq = [(0, 0)]
    total = taken = 0
    while pq and taken < n:
        w, u = heapq.heappop(pq)
        if in_tree[u]:
            continue
        in_tree[u] = True
        total += w
        taken += 1
        for v, wv in adj[u]:
            if not in_tree[v]:
                heapq.heappush(pq, (wv, v))
    return total if taken == n else -1
```

---

## 🧱 Bloque 16 — Cadenas

### `16/01` — Inmutabilidad y concatenación [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §3](../16-cadenas/01-cadenas-y-patrones-basicos.md#3--inmutabilidad-y-concatenación).

```python
def join_words(words, sep):
    """En Python: una lista de trozos y un solo join al final."""
    parts = []
    for i, w in enumerate(words):
        if i:
            parts.append(sep)
        parts.append(w)
    return ''.join(parts)                                # o directamente sep.join(words)
```

### `16/01` — Frecuencias y anagramas [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §4](../16-cadenas/01-cadenas-y-patrones-basicos.md#4--frecuencias-y-anagramas).

```python
from collections import Counter

def freq(s):
    f = [0] * 26
    for ch in s:
        f[ord(ch) - 97] += 1
    return f

def is_anagram(a, b):
    return len(a) == len(b) and freq(a) == freq(b)       # o Counter(a) == Counter(b)

def signature(s):
    return ''.join(sorted(s))                            # o tuple(freq(s)) como clave de dict
```

### `16/01` — Palíndromos con dos punteros [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §5](../16-cadenas/01-cadenas-y-patrones-basicos.md#5--palíndromos-con-dos-punteros).

```python
def mismatches(s, l, r):
    """Pares simétricos distintos en s[l..r]."""
    count = 0
    while l < r:
        if s[l] != s[r]:
            count += 1
        l += 1
        r -= 1
    return count
```

### `16/02` — Función de prefijo [A]

De [`16/02` — KMP y la función de prefijo, §3](../16-cadenas/02-kmp.md#3--función-de-prefijo).

```python
def prefix_function(s):
    """pi[i] = longitud del borde más largo de s[0..i]."""
    n = len(s)
    pi = [0] * n
    for i in range(1, n):
        k = pi[i - 1]
        while k and s[i] != s[k]:
            k = pi[k - 1]
        if s[i] == s[k]:
            k += 1
        pi[i] = k
    return pi
```

### `16/02` — KMP [A]

De [`16/02` — KMP y la función de prefijo, §4](../16-cadenas/02-kmp.md#4--kmp).

```python
def kmp_search(t, p):
    """Posiciones de inicio de las apariciones (solapadas) de p en t."""
    pi = prefix_function(p)
    found, k, m = [], 0, len(p)
    for i, ch in enumerate(t):
        while k and ch != p[k]:
            k = pi[k - 1]
        if ch == p[k]:
            k += 1
        if k == m:
            found.append(i - m + 1)
            k = pi[k - 1]
    return found
```

### `16/03` — Función Z [B]

De [`16/03` — Función Z y Manacher, §3](../16-cadenas/03-funcion-z-y-manacher.md#3--función-z).

```python
def z_function(s):
    """z[i] = prefijo común más largo de s y s[i:]; z[0] = 0."""
    n = len(s)
    z = [0] * n
    l = r = 0
    for i in range(1, n):
        if i < r:
            z[i] = min(r - i, z[i - l])
        while i + z[i] < n and s[z[i]] == s[i + z[i]]:
            z[i] += 1
        if i + z[i] > r:
            l, r = i, i + z[i]
    return z
```

---

## 🧱 Bloque 17 — Matemática

### `17/01` — Operaciones y trucos [A]

De [`17/01` — Bits, §3](../17-matematica/01-bits.md#3--operaciones-y-trucos).

```python
def get_bit(x, i): return x >> i & 1
def set_bit(x, i): return x | (1 << i)
def clear_bit(x, i): return x & ~(1 << i)
def low_bit(x): return x & -x
def is_power_of_two(x): return x > 0 and x & (x - 1) == 0
def popcount(x): return x.bit_count()                 # Python 3.10+; antes, bin(x).count('1')
def lowest_index(x): return (x & -x).bit_length() - 1
def highest_index(x): return x.bit_length() - 1
# Los enteros de Python no tienen tamaño fijo: ~x es −x − 1 y no hay desbordamiento.
```

### `17/02` — Euclides [A]

De [`17/02` — Divisibilidad, §3](../17-matematica/02-divisibilidad.md#3--euclides).

```python
from math import gcd, lcm                                # lcm con varios argumentos desde 3.9

def gcd_manual(a, b):
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a
```

### `17/02` — Euclides extendido [A]

De [`17/02` — Divisibilidad, §4](../17-matematica/02-divisibilidad.md#4--euclides-extendido).

```python
def ext_gcd(a, b):
    """(g, x, y) con a*x + b*y = g."""
    x0, y0, x1, y1 = 1, 0, 0, 1
    while b:
        q = a // b
        a, b = b, a - q * b
        x0, x1 = x1, x0 - q * x1
        y0, y1 = y1, y0 - q * y1
    return a, x0, y0
```

### `17/02` — Diofánticas lineales [A]

De [`17/02` — Divisibilidad, §5](../17-matematica/02-divisibilidad.md#5--diofánticas-lineales).

```python
def count_non_negative(a, b, c):
    """Soluciones (x, y) enteras con x, y >= 0 de a*x + b*y = c."""
    g, x, y = ext_gcd(a, b)
    if c % g:
        return 0
    x0, y0, sx, sy = x * (c // g), y * (c // g), b // g, a // g
    lo = -(x0 // sx)                                      # ceil(-x0 / sx), con // que redondea hacia −∞
    hi = y0 // sy
    return max(0, hi - lo + 1)
```

### `17/03` — Exponenciación modular [A]

De [`17/03` — Aritmética modular, §3](../17-matematica/03-aritmetica-modular.md#3--exponenciación-modular).

```python
# Python ya lo trae: pow(a, e, m), con enteros sin límite; pow(a, -1, m) es el inverso (3.8+).
def pow_mod(a, e, m):
    result, a = 1 % m, a % m
    while e > 0:
        if e & 1:
            result = result * a % m
        a = a * a % m
        e >>= 1
    return result
```

### `17/03` — Inverso modular [A]

De [`17/03` — Aritmética modular, §4](../17-matematica/03-aritmetica-modular.md#4--inverso-modular).

```python
def inv_fermat(a, p):
    return pow(a, p - 2, p)

def inv_ext(a, m):
    return pow(a, -1, m)                                 # 3.8+: lanza ValueError si no existe

def inverses_up_to(n, p):
    inv = [0, 1] + [0] * (n - 1)
    for i in range(2, n + 1):
        inv[i] = (p - (p // i) * inv[p % i] % p) % p
    return inv
```

### `17/04` — Criba de Eratóstenes [A]

De [`17/04` — Primos, §3](../17-matematica/04-primos.md#3--criba-de-eratóstenes).

```python
def sieve(n):
    """bytearray: is_prime[i] es 1 si i es primo."""
    is_prime = bytearray([1]) * (n + 1)
    is_prime[0:2] = b'\x00\x00'[: n + 1]
    for p in range(2, int(n ** 0.5) + 1):
        if is_prime[p]:
            is_prime[p * p :: p] = bytes(len(range(p * p, n + 1, p)))   # tachar con un corte
    return is_prime
```

### `17/04` — Criba lineal y menor factor primo [A]

De [`17/04` — Primos, §4](../17-matematica/04-primos.md#4--criba-lineal-y-menor-factor-primo).

```python
def linear_sieve(n):
    """spf[x] = menor factor primo; primes = primos hasta n."""
    spf = [0] * (n + 1)
    primes = []
    for i in range(2, n + 1):
        if spf[i] == 0:
            spf[i] = i
            primes.append(i)
        for p in primes:
            if p > spf[i] or i * p > n:
                break
            spf[i * p] = p
    return spf, primes

def factorize(x, spf):
    f = []
    while x > 1:
        p, e = spf[x], 0
        while x % p == 0:
            x //= p
            e += 1
        f.append((p, e))
    return f
```

### `17/05` — `nCr` con factoriales [A]

De [`17/05` — Combinatoria, §3](../17-matematica/05-combinatoria.md#3--ncr-con-factoriales).

```python
MOD = 10**9 + 7

def init_binomial(n):
    fact = [1] * (n + 1)
    for i in range(1, n + 1):
        fact[i] = fact[i - 1] * i % MOD
    inv_fact = [1] * (n + 1)
    inv_fact[n] = pow(fact[n], MOD - 2, MOD)
    for i in range(n, 0, -1):
        inv_fact[i - 1] = inv_fact[i] * i % MOD
    return fact, inv_fact

def C(n, k, fact, inv_fact):
    if k < 0 or k > n:
        return 0
    return fact[n] * inv_fact[k] % MOD * inv_fact[n - k] % MOD
```

---

## 🧱 Bloque 18 — Geometría

### `18/01` — Vectores, punto y cruz [A]

De [`18/01` — Vectores, productos y orientación, §3](../18-geometria/01-vectores-y-orientacion.md#3--vectores-punto-y-cruz).

```python
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])

def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]

def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]
```

### `18/01` — Orientación [A]

De [`18/01` — Vectores, productos y orientación, §4](../18-geometria/01-vectores-y-orientacion.md#4--orientación).

```python
def orient(a, b, c):
    v = cross(sub(b, a), sub(c, a))
    return (v > 0) - (v < 0)

def in_triangle(a, b, c, p):
    s = (orient(a, b, p), orient(b, c, p), orient(c, a, p))
    return not (min(s) < 0 < max(s))
```

### `18/01` — Enteros frente a épsilon [A]

De [`18/01` — Vectores, productos y orientación, §5](../18-geometria/01-vectores-y-orientacion.md#5--enteros-frente-a-épsilon).

```python
from fractions import Fraction        # exactitud sin épsilon, a cambio de tiempo

def sgn(v, eps):
    return (v > eps) - (v < -eps)
```

### `18/03` — Rectángulos: lo que sí te pueden preguntar [B]

De [`18/03` — Polígonos, §6](../18-geometria/03-poligonos.md#6--rectángulos-lo-que-sí-te-pueden-preguntar).

```python
def overlap_area(r, s):
    w = min(r[2], s[2]) - max(r[0], s[0])
    h = min(r[3], s[3]) - max(r[1], s[1])
    return w * h if w > 0 and h > 0 else 0
```

### `18/04` — Cadena monótona de Andrew [B]

De [`18/04` — Envolvente convexa, §3](../18-geometria/04-envolvente-convexa.md#3--cadena-monótona-de-andrew).

```python
def convex_hull(pts, keep_collinear=False):
    pts = sorted(set(pts))
    if len(pts) <= 2:
        return pts

    def chain(seq):
        h = []
        for p in seq:
            while len(h) >= 2 and (orient(h[-2], h[-1], p) < 0 if keep_collinear
                                   else orient(h[-2], h[-1], p) <= 0):
                h.pop()
            h.append(p)
        return h

    lower, upper = chain(pts), chain(reversed(pts))
    return lower[:-1] + upper[:-1]
```

---

## 🧱 Bloque 19 — Aleatorizados y probabilísticos

### `19/04` — Fisher-Yates [A]

De [`19/04` — Muestreo y cadenas de Markov, §3](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#3--fisher-yates).

```python
import random

def fisher_yates(a):
    for i in range(len(a) - 1, 0, -1):
        j = random.randint(0, i)                            # j en [0, i], incluido i
        a[i], a[j] = a[j], a[i]
# random.shuffle(a) hace lo mismo.
```

### `19/04` — *Reservoir* [B]

De [`19/04` — Muestreo y cadenas de Markov, §4](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#4--reservoir).

```python
import random

def reservoir(stream, k):
    sample = []
    for seen, x in enumerate(stream, start=1):
        if seen <= k:
            sample.append(x)
        else:
            j = random.randrange(seen)                       # uniforme en [0, seen)
            if j < k:
                sample[j] = x
    return sample
```

---

## 🧱 Bloque 22 — Teoría de la computación (opcional)

### `22/02` — CYK [B]

De [`22/02` — Autómatas de pila, §5](../22-teoria-de-la-computacion/02-automatas-de-pila.md#5--cyk).

```python
def cyk(unit, binr, w):
    """CYK. unit = [(A, a)]; binr = [(A, B, C)]; variables numeradas desde 0, la inicial es la 0."""
    n = len(w)
    if n == 0:
        return False
    t = [[0] * n for _ in range(n)]
    for i, c in enumerate(w):
        for a, s in unit:
            if s == c:
                t[i][i] |= 1 << a
    for length in range(2, n + 1):
        for i in range(n - length + 1):
            j = i + length - 1
            for k in range(i, j):
                left, right = t[i][k], t[k + 1][j]
                for a, b, c in binr:
                    if left >> b & 1 and right >> c & 1:
                        t[i][j] |= 1 << a
    return bool(t[0][n - 1] & 1)
```

### `22/03` — La máquina de Turing y su simulación [A]

De [`22/03` — Máquinas de Turing y decidibilidad, §3](../22-teoria-de-la-computacion/03-maquinas-de-turing-y-decidibilidad.md#3--la-máquina-de-turing-y-su-simulación).

```python
def run_tm(delta, halt, tape, blank, limit):
    """Simula una MT desde el estado 0. delta[(q, símbolo)] = (escribe, mueve ±1, siguiente).
    Devuelve (estado final o -1 si agotó el límite, pasos, cinta)."""
    left, right = [], list(reversed(tape))
    cur = right.pop() if right else blank
    q, steps = 0, 0
    while q != halt:
        if steps == limit:
            return -1, steps, None
        rule = delta.get((q, cur))
        if rule is None:                     # sin transición: se detiene
            break
        write, move, q = rule
        src, dst = (right, left) if move > 0 else (left, right)
        dst.append(write)
        cur = src.pop() if src else blank
        steps += 1
    return q, steps, ''.join(left) + cur + ''.join(reversed(right))
```

### `22/04` — P y NP por certificados [A]

De [`22/04` — P, NP y reducciones, §3](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#3--p-y-np-por-certificados).

```python
def verify_cover(n, edges, cover, k):
    """Verificador de NP: ¿cover es una cobertura de vértices de tamaño <= k? O(n + m)."""
    if len(cover) > k:
        return False
    inside = [False] * n
    for v in cover:
        inside[v] = True
    return all(inside[u] or inside[v] for u, v in edges)
```

### `22/05` — Qué hacer con un NP-difícil [A]

De [`22/05` — NP-completitud, §6](../22-teoria-de-la-computacion/05-np-completitud.md#6--qué-hacer-con-un-np-difícil).

```python
def hamiltonian_cycle(adj):
    """adj[v] = máscara de vecinos de v. O(2^n · n); en CPython, hasta n ≈ 18."""
    n = len(adj)
    if n < 3:
        return False
    reach = [0] * (1 << n)
    reach[1] = 1
    for mask in range(3, 1 << n, 2):
        r = 0
        for w in range(1, n):
            if mask >> w & 1 and reach[mask ^ (1 << w)] & adj[w]:
                r |= 1 << w
        reach[mask] = r
    return bool(reach[(1 << n) - 1] & adj[0])
```

### `22/06` — Análisis léxico [B]

De [`22/06` — Análisis léxico y gramáticas simples, §3](../22-teoria-de-la-computacion/06-analisis-lexico-y-gramaticas-simples.md#3--análisis-léxico).

```python
def tokenize(s):
    """Lexer: lista de (tipo, texto, posición) con 'NUM', 'IDENT', 'OP' y un 'END' final. Θ(n)."""
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c.isspace():
            i += 1
            continue
        start = i
        if '0' <= c <= '9':
            while i < len(s) and '0' <= s[i] <= '9':
                i += 1
            out.append(('NUM', s[start:i], start))
        elif c.isalpha() or c == '_':
            while i < len(s) and (s[i].isalnum() or s[i] == '_'):
                i += 1
            out.append(('IDENT', s[start:i], start))
        elif c in '+-*/^()=':
            i += 1
            out.append(('OP', c, start))
        else:
            raise ValueError(f'carácter inesperado en la posición {start}')
    out.append(('END', '', len(s)))
    return out
```
