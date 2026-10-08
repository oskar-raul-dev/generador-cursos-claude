# 01 — Montículo binario

> El montículo binario sobre un arreglo: subir y bajar elementos para mantener su invariante, construirlo
> en `O(n)` con `heapify` y la prueba de esa cota, lo que ofrece cada biblioteca —y lo que no: ninguna
> trae `decrease-key`—, la cola indexada que sí lo hace, y el montículo `d`-ario.
>
> **Niveles:** montículo binario [A] · `heapify` [A] · cola indexada [B] · `d`-ario [C].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), cap. 6; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997),
> cap. 5; Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §2.4.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--el-montículo-binario) · [4](#4--heapify) · [5](#5--cola-indexada) · [6](#6--montículo-d-ario) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Muchos algoritmos necesitan, una y otra vez, **el menor de un conjunto que cambia**: Dijkstra saca el
nodo más cercano y añade vecinos; un planificador saca la tarea más urgente y recibe nuevas; una
simulación de eventos saca el siguiente evento en el tiempo.

Con un arreglo ordenado, sacar el menor es `O(1)` pero insertar es `O(n)`. Con un arreglo sin ordenar,
insertar es `O(1)` pero sacar el menor es `O(n)`. Con `n = 10⁵` operaciones de cada tipo, cualquiera de las
dos son `10¹⁰` pasos.

El **montículo** (*heap*) hace las dos en `O(log n)`, guardado en un simple arreglo, sin punteros. Es la
**cola de prioridad** de todas las bibliotecas. Este capítulo es su dueño: cómo funciona por dentro, por
qué construirlo cuesta `O(n)` y no `O(n log n)`, y qué hacer cuando hace falta cambiar la prioridad de un
elemento que ya está dentro.

---

## 2. 📐 La teoría

**La forma.** Un montículo binario es un árbol binario **completo** (todos los niveles llenos salvo el
último, que se llena de izquierda a derecha), guardado en un arreglo por niveles:

```text
índice:   0    1    2    3    4    5
hijos de i:   2i + 1 y 2i + 2          padre de i:   (i − 1) / 2   (división entera)
```

**El invariante** (montículo de mínimos): todo nodo es menor o igual que sus hijos. En consecuencia, la
raíz `a[0]` es el mínimo. Los hermanos **no** están ordenados entre sí: el arreglo no está ordenado.

**Las dos reparaciones.**

- `siftUp(i)`: si `a[i]` es menor que su padre, se intercambian y se repite desde el padre. Se usa al
  insertar al final.
- `siftDown(i)`: si `a[i]` es mayor que su menor hijo, se intercambian y se repite desde ese hijo. Se usa
  al sacar la raíz (se pone el último en su lugar) y en `heapify`.

Cada una recorre como mucho la altura, `⌊log₂ n⌋`.

**Teorema (`heapify` es lineal).** Construir un montículo de `n` elementos aplicando `siftDown` a los nodos
`⌊n/2⌋ − 1, …, 1, 0`, en ese orden, cuesta `O(n)`.

*Prueba.* Un `siftDown` desde un nodo de altura `h` (distancia a las hojas) hace como mucho `h`
intercambios. En un árbol completo hay como mucho `⌈n / 2^{h+1}⌉` nodos de altura `h`. El total es

```text
Σ_{h=0}^{⌊log n⌋} ⌈n / 2^{h+1}⌉ · O(h)  =  O( n · Σ_{h≥0} h / 2^h )  =  O(2n)  =  O(n)
```

porque `Σ h/2^h = 2`. La intuición: la mitad de los nodos son hojas y no se mueven; un cuarto baja como
mucho 1; un octavo, 2… Los nodos que pueden bajar mucho son pocos. CLRS, 3.ª ed., §6.3.

---

## 3. 🧱 El montículo binario

**Qué es.** Un arreglo con el invariante de §2 y tres operaciones: `push` (añadir al final y subir), `top`
(leer `a[0]`) y `pop` (mover el último a la raíz y bajarlo).

**Por qué es correcto.** `push` solo puede romper el invariante en el camino del nuevo elemento a la raíz,
y `siftUp` lo restaura subiéndolo mientras sea menor que su padre. `pop` solo lo rompe en la raíz, y
`siftDown` lo restaura bajándola por el hijo menor (el menor de los dos es el único que puede quedar como
padre del otro).

**Cómo va**, insertando `5, 2, 9, 1, 5, 6` en un montículo de mínimos:

```text
push 5   [5]
push 2   [2, 5]                  2 sube sobre 5
push 9   [2, 5, 9]
push 1   [1, 2, 9, 5]            1 sube dos niveles
push 5   [1, 2, 9, 5, 5]
push 6   [1, 2, 6, 5, 5, 9]      6 sube sobre 9
pop → 1  [2, 5, 6, 9, 5]         el 9 pasa a la raíz y baja: por 2, después por 5
```

**Cuánto.** `push` y `pop` `O(log n)`; `top` `O(1)`; memoria `Θ(n)`, sin punteros.

**La plantilla**, un montículo de mínimos de enteros:

```cpp
#include <utility>
#include <vector>

// Montículo de mínimos sobre un vector. push y pop en O(log n).
struct MinHeap {
    std::vector<int> a;
    void push(int x) {
        a.push_back(x);
        for (int i = (int)a.size() - 1; i > 0 && a[(i - 1) / 2] > a[i]; i = (i - 1) / 2)
            std::swap(a[i], a[(i - 1) / 2]);                     // siftUp
    }
    int top() const { return a[0]; }
    int pop() {                                                   // pre: no vacío
        int res = a[0];
        a[0] = a.back(); a.pop_back();
        for (int i = 0, n = a.size();;) {                         // siftDown
            int c = 2 * i + 1;
            if (c >= n) break;
            if (c + 1 < n && a[c + 1] < a[c]) c++;
            if (a[i] <= a[c]) break;
            std::swap(a[i], a[c]); i = c;
        }
        return res;
    }
    bool empty() const { return a.empty(); }
};
```

```java
// Montículo de mínimos sobre un arreglo que crece. push y pop en O(log n).
static final class MinHeap {
    int[] a = new int[16]; int n = 0;
    void push(int x) {
        if (n == a.length) a = java.util.Arrays.copyOf(a, 2 * n);
        a[n] = x;
        for (int i = n++; i > 0 && a[(i - 1) / 2] > a[i]; i = (i - 1) / 2) {
            int p = (i - 1) / 2, t = a[i]; a[i] = a[p]; a[p] = t;
        }
    }
    int top() { return a[0]; }
    int pop() {
        int res = a[0];
        a[0] = a[--n];
        for (int i = 0;;) {
            int c = 2 * i + 1;
            if (c >= n) break;
            if (c + 1 < n && a[c + 1] < a[c]) c++;
            if (a[i] <= a[c]) break;
            int t = a[i]; a[i] = a[c]; a[c] = t; i = c;
        }
        return res;
    }
    boolean isEmpty() { return n == 0; }
}
```

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

- **`a[(i − 1) / 2] > a[i]` estricto** al subir: con iguales, no se mueve (menos intercambios).
- **Al bajar, el hijo menor**: si se bajara por el mayor, el menor quedaría por debajo de él.
- **En la biblioteca**:

| Lenguaje | Cola de prioridad | Por defecto | Notas |
|---|---|---|---|
| C++ | `std::priority_queue<T>` | **Máximos** | Mínimos con `std::priority_queue<T, std::vector<T>, std::greater<T>>` |
| Java | `PriorityQueue<E>` | Mínimos | Máximos con `Comparator.reverseOrder()`; su iterador **no** está ordenado |
| Python | `heapq` sobre una `list` | Mínimos | Máximos: guardar `−x`; `heapify`, `nsmallest`, `nlargest` |

> 📝 **Desde Python 3.14:** `heapq` añade funciones para montículos de máximos (`heappush_max`,
> `heappop_max` y similares). Este corpus fija Python 3.12, donde se usa el truco de negar.

### De la versión ingenua a la buena

**El problema.** Un servidor recibe `10⁵` tareas con prioridad y, entre llegada y llegada, atiende la de
menor número de prioridad pendiente.

**La versión ingenua:**

```java
// O(n) por inserción: mantiene una lista ordenada insertando en su sitio. 10⁵ · 10⁵ desplazamientos.
static void addTask(java.util.ArrayList<Integer> pending, int prio) {
    int pos = java.util.Collections.binarySearch(pending, prio);
    if (pos < 0) pos = -pos - 1;
    pending.add(pos, prio);                          // desplaza todo lo de detrás
}
```

> «No necesito el orden completo: solo saber cuál es el menor en cada momento. Un montículo mantiene
> justo eso, con inserción y extracción en `log n`, sin desplazar el resto.»

**El camino a la buena.** `PriorityQueue<Integer>` (`offer` y `poll`), o la plantilla.

**Cuándo sí**: el mínimo o el máximo de un conjunto que cambia; Dijkstra, Prim, simulación de eventos,
mezcla de `k` listas ([`08/02`](02-patrones-con-heap.md)). **Cuándo no**: si hace falta buscar o borrar un elemento cualquiera, un
árbol balanceado ([`07/02`](../07-arboles/02-bst-y-balanceados.md)); si solo hay inserciones y luego todas las extracciones, ordenar una vez.

> **Veredicto:** el montículo es un arreglo con una regla padre-hijo: el mínimo arriba, el resto sin
> ordenar, y `O(log n)` por operación. Es la cola de prioridad de todas las bibliotecas.

---

## 4. 🧱 `heapify`

**Qué es.** Convertir un arreglo cualquiera en montículo, aplicando `siftDown` de los nodos internos
hacia la raíz: de `⌊n/2⌋ − 1` a 0.

**Por qué es correcto.** Invariante: al procesar el nodo `i`, los subárboles de todos los nodos `> i` ya son
montículos. Las hojas lo son trivialmente; `siftDown(i)`, con sus dos subárboles ya montículos, convierte
el subárbol de `i` en montículo. Al terminar con `i = 0`, todo el arreglo lo es.

**Cómo va**, `heapify` de `[5, 2, 9, 1, 5, 6]`:

```text
i = 2  (9, hijo 6)          → [5, 2, 6, 1, 5, 9]
i = 1  (2, hijos 1 y 5)     → [5, 1, 6, 2, 5, 9]
i = 0  (5, hijos 1 y 6)     → baja por 1, después por 2 → [1, 2, 6, 5, 5, 9]
```

**Cuánto.** `O(n)`, por el teorema de §2.

**La plantilla:**

```cpp
#include <utility>
#include <vector>

void siftDown(std::vector<int>& a, int i, int n) {               // montículo de mínimos en a[0, n)
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] < a[c]) c++;
        if (a[i] <= a[c]) return;
        std::swap(a[i], a[c]); i = c;
    }
}

void heapify(std::vector<int>& a) {                                // O(n)
    for (int i = (int)a.size() / 2 - 1; i >= 0; i--) siftDown(a, i, a.size());
}
```

```java
static void siftDown(int[] a, int i, int n) {
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] < a[c]) c++;
        if (a[i] <= a[c]) return;
        int t = a[i]; a[i] = a[c]; a[c] = t; i = c;
    }
}

static void heapify(int[] a) {                                    // O(n)
    for (int i = a.length / 2 - 1; i >= 0; i--) siftDown(a, i, a.length);
}
```

```python
import heapq

a = [5, 2, 9, 1, 5, 6]
heapq.heapify(a)          # en el sitio, O(n): a queda [1, 2, 6, 5, 5, 9]
```

- **De abajo arriba**: empezar por la raíz no funciona, porque `siftDown` necesita que los subárboles ya
  sean montículos.
- **`std::make_heap`** hace lo mismo en C++ (de máximos por defecto); en Java, `new PriorityQueue<>(coleccion)`
  usa `heapify` internamente.

### De la versión ingenua a la buena

**El problema.** Construir una cola de prioridad con `10⁷` elementos que ya se tienen en un arreglo.

**La versión ingenua:**

```java
// O(n log n): un offer por elemento; con la entrada al revés, cada uno sube hasta la raíz.
static java.util.PriorityQueue<Integer> build(int[] a) {
    java.util.PriorityQueue<Integer> pq = new java.util.PriorityQueue<>();
    for (int x : a) pq.offer(x);
    return pq;
}
```

> «Insertar uno a uno cuesta `log n` por elemento porque cada uno puede subir hasta arriba. Si tengo todos
> a la vez, puedo bajar desde los nodos internos: la mitad son hojas y no se mueven, y la suma da lineal.»

**El camino a la buena.** `heapify` sobre el arreglo, o en Java pasar la colección al constructor.

**Cuándo sí**: siempre que todos los elementos estén disponibles al principio; *heapsort* ([`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md)).
**Cuándo no**: si llegan de uno en uno, no hay más remedio que `push`.

> **Veredicto:** `heapify` construye el montículo en `O(n)`, no en `O(n log n)`: los muchos nodos de abajo
> bajan poco y los pocos de arriba bajan mucho.

---

## 5. 🧱 Cola indexada

**Qué es.** Un montículo de **índices** `0..n−1` con su prioridad, que además guarda `pos[i]`, la posición
de cada índice en el arreglo del montículo. Así se puede **cambiar la prioridad** de un elemento que ya
está dentro (`decrease-key`) en `O(log n)`.

**Por qué es correcto** (el enunciado y una frase): cada intercambio del montículo actualiza `pos` de los
dos índices intercambiados, así que `pos[i]` siempre dice dónde está `i`; tras bajar su prioridad, basta
un `siftUp` desde `pos[i]`.

**Cómo va.** Con prioridades `[5, 2, 9]` para los índices 0, 1, 2, el montículo es `[1, 0, 2]` (el índice 1
con prioridad 2 arriba). `decrease(2, 1)`: `pos[2] = 2`; la prioridad del índice 2 pasa a 1 y sube a la
raíz: `[2, 0, 1]`.

**Cuánto.** `O(log n)` por `push`, `pop` y `decrease`; `O(1)` para saber si un índice está dentro.

**La plantilla:**

```cpp
#include <utility>
#include <vector>

// Cola de prioridad indexada (mínimos) sobre índices 0..n−1, con decrease-key.
struct IndexedMinPQ {
    std::vector<long long> key; std::vector<int> heap, pos;       // pos[i] = −1 si i no está
    explicit IndexedMinPQ(int n) : key(n), pos(n, -1) {}
    void swapAt(int a, int b) { std::swap(heap[a], heap[b]); pos[heap[a]] = a; pos[heap[b]] = b; }
    void up(int k) { while (k > 0 && key[heap[(k - 1) / 2]] > key[heap[k]]) { swapAt(k, (k - 1) / 2); k = (k - 1) / 2; } }
    void down(int k) {
        int n = heap.size();
        while (2 * k + 1 < n) {
            int c = 2 * k + 1;
            if (c + 1 < n && key[heap[c + 1]] < key[heap[c]]) c++;
            if (key[heap[k]] <= key[heap[c]]) break;
            swapAt(k, c); k = c;
        }
    }
    bool contains(int i) const { return pos[i] >= 0; }
    void push(int i, long long k) { key[i] = k; pos[i] = heap.size(); heap.push_back(i); up(pos[i]); }
    void decrease(int i, long long k) { key[i] = k; up(pos[i]); }   // pre: k <= key[i]
    int pop() {                                                     // devuelve el índice mínimo
        int top = heap[0];
        swapAt(0, heap.size() - 1); heap.pop_back(); pos[top] = -1;
        if (!heap.empty()) down(0);
        return top;
    }
    bool empty() const { return heap.empty(); }
};
```

```java
// Cola de prioridad indexada (mínimos) sobre índices 0..n−1, con decrease-key.
static final class IndexedMinPQ {
    final long[] key; final int[] heap, pos; int size = 0;
    IndexedMinPQ(int n) { key = new long[n]; heap = new int[n]; pos = new int[n]; java.util.Arrays.fill(pos, -1); }
    void swapAt(int a, int b) { int t = heap[a]; heap[a] = heap[b]; heap[b] = t; pos[heap[a]] = a; pos[heap[b]] = b; }
    void up(int k) { while (k > 0 && key[heap[(k - 1) / 2]] > key[heap[k]]) { swapAt(k, (k - 1) / 2); k = (k - 1) / 2; } }
    void down(int k) {
        while (2 * k + 1 < size) {
            int c = 2 * k + 1;
            if (c + 1 < size && key[heap[c + 1]] < key[heap[c]]) c++;
            if (key[heap[k]] <= key[heap[c]]) break;
            swapAt(k, c); k = c;
        }
    }
    boolean contains(int i) { return pos[i] >= 0; }
    void push(int i, long k) { key[i] = k; pos[i] = size; heap[size++] = i; up(pos[i]); }
    void decrease(int i, long k) { key[i] = k; up(pos[i]); }
    int pop() {
        int top = heap[0];
        swapAt(0, --size); pos[top] = -1;
        if (size > 0) down(0);
        return top;
    }
    boolean isEmpty() { return size == 0; }
}
```

- **Las bibliotecas no tienen `decrease-key`**: `priority_queue`, `PriorityQueue` y `heapq` no dejan
  encontrar un elemento dentro. La alternativa sin cola indexada es meter el elemento otra vez con la
  prioridad nueva y descartar las copias viejas al sacarlas: el **borrado perezoso** (`08/02`).
- **`PriorityQueue.remove(Object)`** existe en Java, pero es `O(n)`: busca linealmente.

**Cuándo sí**: Dijkstra y Prim con memoria justa ([`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md), [`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)); cualquier cola donde las prioridades
cambian muchas veces. **Cuándo no**: si el borrado perezoso entra en tiempo y memoria, es más simple.

> **Veredicto:** la cola indexada recuerda dónde está cada elemento y por eso puede cambiar su prioridad
> en `O(log n)`. Las bibliotecas no la traen; el borrado perezoso es su sustituto habitual.

---

## 6. 🧱 Montículo `d`-ario

- **Qué resuelve.** Ajustar el equilibrio entre `push`/`decrease` (que suben) y `pop` (que baja) cambiando
  el número de hijos.
- **Qué garantiza.** Con `d` hijos por nodo, la altura es `log_d n`: subir cuesta `O(log_d n)` y bajar
  `O(d · log_d n)` (hay que buscar el menor de `d` hijos).
- **Cuánto.** Hijos de `i` en `d·i + 1 … d·i + d`; padre en `(i − 1)/d`.
- **Cómo reconocerlo.** Dijkstra en grafos densos, donde hay muchos más `decrease-key` que `pop`: con
  `d ≈ m/n`, el coste total es `O(m log_{m/n} n)`. También por localidad: con `d = 4` u 8, los hijos caben en
  una línea de caché.
- **Si no te la sabes.** El binario es casi siempre suficiente.
- **Dónde está entera.** CLRS, 3.ª ed., problema 6-2; Sedgewick y Wayne, §2.4 (ejercicios).

---

## 7. ⏱️ La tabla de costes

| Operación | Binario | `d`-ario | Lo que la tabla no dice |
|---|---|---|---|
| `push` | `O(log n)` | `O(log_d n)` | Sube por el camino al padre |
| `pop` | `O(log n)` | `O(d · log_d n)` | Baja por el menor de los hijos |
| `top` | `O(1)` | `O(1)` | — |
| Construir (`heapify`) | `O(n)` | `O(n)` | No `O(n log n)` |
| `decrease-key` | `O(log n)` con cola indexada | `O(log_d n)` | Las bibliotecas no lo tienen |
| Buscar o borrar uno cualquiera | `O(n)` | `O(n)` | Para eso, un árbol balanceado |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Siempre el menor/mayor de los que quedan», con llegadas | Montículo | `O(log n)` por operación |
| Todos los datos al principio y luego extracciones | `heapify` u ordenar | `O(n)` para construir |
| «Actualiza la prioridad del elemento `i`» | Cola indexada o borrado perezoso | No hay `decrease-key` en las bibliotecas |
| «Borra el elemento `x`» además del mínimo | Árbol balanceado o borrado perezoso | El montículo no busca |
| «El `k`-ésimo menor» con llegadas | Montículo de tamaño `k` (`08/02`) | `O(log k)` por llegada |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Construir un *heap* es `O(n log n)`» | Con `heapify` es `O(n)`; `O(n log n)` es insertar de uno en uno |
| «`PriorityQueue` está ordenada» | Solo la cabeza es el mínimo; su iterador y `toString` recorren el arreglo del montículo, sin orden |
| «`priority_queue` da el mínimo» | En C++ da el **máximo** por defecto |
| «Puedo bajar la prioridad de un elemento de `PriorityQueue`» | No hay `decrease-key`; `remove(Object)` es `O(n)`; se usa borrado perezoso o cola indexada |
| «El montículo sirve para buscar» | Buscar un elemento cualquiera es `O(n)` |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  cap. 6: montículos, `heapify` lineal y colas de prioridad. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5. *Lectura
  troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §2.4, con la cola indexada,
  en [*Priority Queues*](https://algs4.cs.princeton.edu/24pq/). *Lectura troncal.*
- **Documentación** — Python, [`heapq`](https://docs.python.org/3/library/heapq.html); Java,
  [`PriorityQueue`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/PriorityQueue.html).
- **Visualización interactiva** — VisuAlgo, [*Binary Heap*](https://visualgo.net/en/heap).

---

## 🧠 Preguntas

1. ¿En qué posiciones están los hijos y el padre del índice `i` en un montículo binario guardado en un arreglo? 🟢
2. ¿Qué garantiza el invariante del montículo, y qué no garantiza sobre los hermanos? 🟢
3. ¿Qué devuelve por defecto `std::priority_queue`, `PriorityQueue` y `heapq`: el mínimo o el máximo? 🟢
4. ¿Por qué al bajar se elige el hijo menor y no cualquiera? 🟡
5. ¿Por qué `heapify` se aplica de los últimos nodos internos hacia la raíz, y no al revés? 🟡
6. ¿Cómo se simula un montículo de máximos con `heapq` en Python 3.12? 🟡
7. Demuestra que `heapify` es `O(n)`. 🟠
8. ¿Por qué ninguna cola de prioridad de biblioteca tiene `decrease-key`, y qué dos alternativas hay? 🟠
9. Compara `std::priority_queue`, `PriorityQueue` y `heapq`: interfaz, orden por defecto y cómo se pasa un comparador. 🟠
10. ¿Qué cuesta Dijkstra con un montículo binario y con uno `d`-ario, y cómo se elige `d`? 🟠
11. Demuestra que `siftDown` aplicado a la raíz restaura el invariante si los dos subárboles ya eran montículos. 🟠
12. ¿Por qué el iterador de `PriorityQueue` no está ordenado, y cómo obtendrías sus elementos en orden? 🔴
13. ¿Cómo implementarías `remove(i)` (borrar un índice cualquiera) en la cola indexada en `O(log n)`? 🔴

---

## 🧩 Problemas propios

### Cola de urgencias

**Nivel:** 🟢 · **Formato:** programa completo.

Llegan órdenes: `+ x` (llega un paciente con gravedad `x`, menor es más grave) y `-` (se atiende al más
grave y se imprime su gravedad). Se garantiza que nunca se atiende con la cola vacía.

- **Entrada.** Una línea con `q`. Después, `q` órdenes.
- **Salida.** Una línea por cada `-`.
- **Restricciones.** `1 ≤ q ≤ 2·10⁵`; `1 ≤ x ≤ 10⁹`.

```text
Entrada            Salida
7                  2
+ 5                1
+ 2                5
-
+ 9
+ 1
-
-

Entrada            Salida
4                  1000000000
+ 1000000000       1000000000
+ 1000000000
-
-
```

**Pista 1:** ¿qué estructura da el menor en `O(1)` y lo quita en `O(log n)`?

🔥 **Para el geek — en Go y JavaScript:** Go tiene `container/heap`, pero hay que implementar su interfaz
(`Len`, `Less`, `Swap`, `Push`, `Pop`) sobre un tipo propio; JavaScript no tiene montículo y hay que
escribir la plantilla.

### Montículo desde cero

**Nivel:** 🟡 · **Formato:** programa completo.

Aplica `heapify` (de mínimos, con `siftDown` desde `⌊n/2⌋ − 1` hasta 0, eligiendo el hijo menor y el
izquierdo en caso de empate) al arreglo e imprime el resultado.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores.
- **Salida.** El arreglo tras `heapify`.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`.

```text
Entrada            Salida
6                  1 2 6 5 5 9
5 2 9 1 5 6

Entrada            Salida
3                  4 9 4
9 4 4
```

**Pista 1:** ¿por qué hay que empezar por los últimos nodos con hijos y no por la raíz?

### Rebajas

**Nivel:** 🟠 · **Formato:** programa completo.

Una tienda tiene `n` productos con precio. Llegan órdenes: `r i p` (el producto `i` baja su precio a `p`, que
es menor que el actual) y `?` (imprime el producto más barato y su precio; a igual precio, el de menor
número).

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` precios. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; precios entre 1 y `10⁹`.

```text
Entrada            Salida
3 5                2 2
5 2 9              3 1
?                  1 1
r 3 1
?
r 1 1
?

Entrada            Salida
2 3                1 7
7 9                1 7
?
r 2 7
?
```

**Pista 1:** si los precios solo bajan, ¿qué operación del montículo necesitas que las bibliotecas no
traen?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de usar la cola de prioridad de tu lenguaje, escribe en un comentario si da el mínimo o
> el máximo. Si una IA te da código con `priority_queue`, comprueba eso primero ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [QHEAP1](https://www.hackerrank.com/challenges/qheap1/problem) | HackerRank | 🟢 | Montículo con borrado | ¿Cómo borras un valor cualquiera si el montículo no sabe buscar? |
| [ ] | [Take Gifts From the Richest Pile](https://leetcode.com/problems/take-gifts-from-the-richest-pile/) | LeetCode | 🟢 | Montículo de máximos | ¿Qué montón eliges en cada segundo y cómo lo vuelves a meter? |
| [ ] | [Remove Stones to Minimize the Total](https://leetcode.com/problems/remove-stones-to-minimize-the-total/) | LeetCode | 🟡 | Montículo de máximos | ¿De qué montón conviene quitar en cada paso? |
| [ ] | [Maximal Score After Applying K Operations](https://leetcode.com/problems/maximal-score-after-applying-k-operations/) | LeetCode | 🟡 | Montículo de máximos | Tras usar un elemento, ¿cómo vuelve al conjunto? |
| [ ] | [Minimum Operations to Halve Array Sum](https://leetcode.com/problems/minimum-operations-to-halve-array-sum/) | LeetCode | 🟡 | Montículo de máximos con reales | ¿Qué elemento reduce más la suma al dividirlo? |
| [ ] | [Smallest Number in Infinite Set](https://leetcode.com/problems/smallest-number-in-infinite-set/) | LeetCode | 🟡 | Montículo y contador | ¿Qué parte del conjunto infinito necesitas guardar de verdad? |
| [ ] | [Find Score of an Array After Marking All Elements](https://leetcode.com/problems/find-score-of-an-array-after-marking-all-elements/) | LeetCode | 🟡 | Montículo de pares | Al sacar el menor, ¿cómo sabes si ya estaba marcado? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Ugly Number II](https://leetcode.com/problems/ugly-number-ii/) | LeetCode | 🟡 | Montículo de candidatos sin repetidos | Cada número feo genera tres más: ¿cómo evitas meter dos veces el mismo? |
| [ ] | [Super Ugly Number](https://leetcode.com/problems/super-ugly-number/) | LeetCode | 🟡 | Montículo de punteros | ¿Qué guardas por cada primo para generar el siguiente candidato? |
| [ ] | [Total Cost to Hire K Workers](https://leetcode.com/problems/total-cost-to-hire-k-workers/) | LeetCode | 🟡 | Dos montículos por los extremos | ¿Qué dos grupos de candidatos compiten en cada ronda? |
| [ ] | [Minimum Cost to Hire K Workers](https://leetcode.com/problems/minimum-cost-to-hire-k-workers/) | LeetCode | 🔴 | Ordenar por razón y montículo de calidades | Fijado el trabajador que marca la razón, ¿qué `k − 1` compañeros conviene elegir? |

---

## ✅ Criterio de dominio

- Escribir el montículo binario con `siftUp` y `siftDown`, y `heapify`, sin mirar.
- Demostrar que `heapify` es `O(n)`.
- Decir qué da por defecto la cola de prioridad de cada lenguaje y cómo cambiarlo.
- Escribir la cola indexada con `decrease-key` y resolver Minimum Cost to Hire K Workers sin pista 2.

---

**Anterior:** — · **Siguiente:** [`08/02` — Patrones con *heap*](02-patrones-con-heap.md) · **Relacionado:** [`15/01` — Dijkstra](../15-grafos-pesos-y-flujos/01-dijkstra.md);
[`02/06` — Tipos abstractos de datos](../02-analisis/06-tipos-abstractos-de-datos.md).
