# 02 — Patrones con *heap*

> Cuatro usos del montículo que aparecen una y otra vez: los `k` mayores de un flujo con un montículo de
> tamaño `k`, la mezcla de `k` listas ordenadas, la mediana de un flujo con dos montículos, y el borrado
> perezoso que sustituye al `decrease-key` y al borrado que las bibliotecas no traen.
>
> **Niveles:** `k` mayores [A] · mezcla de `k` listas [A] · mediana con dos *heaps* [A] · borrado perezoso
> [B].
>
> **📚 Lectura troncal:** Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §2.4; Skiena,
> *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 3.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--los-k-mayores) · [4](#4--mezcla-de-k-listas) · [5](#5--la-mediana-con-dos-heaps) · [6](#6--borrado-perezoso) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

El montículo de `08/01` da el mínimo de un conjunto que cambia. Con esa sola operación se resuelven
problemas que, a primera vista, piden ordenar:

- **Los `k` mayores** de `10⁸` valores que llegan en flujo: ordenar exige guardarlos todos.
- **Mezclar `k` archivos ordenados** en uno: concatenar y ordenar ignora que ya estaban ordenados.
- **La mediana** tras cada llegada: reordenar cada vez es cuadrático.
- **Planificar**: siempre la tarea más urgente, con tareas que llegan y que se cancelan.

En los cuatro, la clave es **qué se guarda en el montículo** y **qué invariante se mantiene**. Y en el
último aparece la limitación de las bibliotecas: no se puede borrar ni cambiar un elemento que está
dentro. El **borrado perezoso** lo resuelve sin escribir una cola indexada.

---

## 2. 📐 La teoría

**Los `k` mayores.** Un montículo de **mínimos** de tamaño `k` guarda los `k` mayores vistos; su cima es
el menor de ellos, el «portero»: un valor nuevo entra solo si supera al portero, que entonces sale.

**Teorema (los `k` mayores).** Tras procesar un flujo con esa regla, el montículo contiene exactamente los
`k` mayores del flujo, y el coste es `O(n log k)` en tiempo y `O(k)` en memoria.

*Prueba.* Invariante: tras procesar `x₁…xᵢ`, el montículo contiene los `min(i, k)` mayores de ellos. Si
llega `x` y hay menos de `k`, entra. Si hay `k`: si `x` es mayor que la cima, la cima deja de estar entre
los `k` mayores (hay `k` valores mayores que ella: los otros `k − 1` y `x`) y `x` entra; si no, `x` no
puede estar entre los `k` mayores (hay `k` valores `≥` que él). Cada paso es `O(log k)`.

**La mezcla de `k` listas.** El montículo guarda la **cabeza** de cada lista (el menor elemento que le
queda). El menor de todo lo que queda es el menor de las cabezas; al sacarlo, entra el siguiente de su
lista. El montículo nunca tiene más de `k` elementos: `O(N log k)` para `N` elementos en total.

**La mediana con dos *heaps*.** Se reparten los valores en dos mitades: `lo`, un montículo de **máximos**
con la mitad menor, y `hi`, uno de **mínimos** con la mitad mayor.

```text
Invariante:   todo valor de lo ≤ todo valor de hi        (max(lo) ≤ min(hi))
              |lo| = |hi|   o   |lo| = |hi| + 1
Mediana (la inferior, con n par):   la cima de lo
```

Al insertar, el valor va a `lo` si es `≤ max(lo)` y a `hi` si no; después, si los tamaños se
descompensan, se pasa una cima al otro lado. Cada inserción es `O(log n)`.

**El borrado perezoso.** Para borrar un valor que está dentro, no se busca: se anota como «pendiente de
borrar» (en un mapa de cuentas o en un segundo montículo). Cuando ese valor llega a la cima, se descarta.
Para cambiar una prioridad, se mete una copia nueva y la vieja se descarta al salir. El montículo puede
contener elementos muertos, pero cada uno sale una sola vez: el coste amortizado no cambia.

---

## 3. 🧱 Los `k` mayores

**Qué es.** Un montículo de mínimos de tamaño `k` que retiene los `k` mayores de un flujo.

**Por qué es correcto.** Por el teorema de §2: la cima es el menor de los `k` retenidos, y un valor nuevo
solo puede pertenecer a los `k` mayores si la supera.

**Cómo va**, `k = 3` sobre `[5, 2, 9, 1, 5, 6]`:

```text
llega   montículo (de mínimos)   cima
5       {5}                      5
2       {2, 5}                   2
9       {2, 5, 9}                2       lleno
1       {2, 5, 9}                2       1 < 2: no entra
5       {5, 5, 9}                5       5 > 2: sale el 2
6       {5, 6, 9}                5       6 > 5: sale un 5
los 3 mayores: 9, 6, 5
```

**Cuánto.** `O(n log k)` en tiempo y `O(k)` en memoria.

**La plantilla:**

```cpp
#include <functional>
#include <queue>
#include <vector>

// Los k mayores de a (en orden creciente). Pre: k >= 1. O(n log k) tiempo, O(k) memoria.
std::vector<int> topK(const std::vector<int>& a, int k) {
    std::priority_queue<int, std::vector<int>, std::greater<int>> pq;    // de mínimos
    for (int x : a) {
        if ((int)pq.size() < k) pq.push(x);
        else if (x > pq.top()) { pq.pop(); pq.push(x); }
    }
    std::vector<int> res;
    while (!pq.empty()) { res.push_back(pq.top()); pq.pop(); }
    return res;
}
```

```java
// Los k mayores de a (en orden creciente). Pre: k >= 1. O(n log k) tiempo, O(k) memoria.
static int[] topK(int[] a, int k) {
    java.util.PriorityQueue<Integer> pq = new java.util.PriorityQueue<>();   // de mínimos
    for (int x : a) {
        if (pq.size() < k) pq.offer(x);
        else if (x > pq.peek()) { pq.poll(); pq.offer(x); }
    }
    int[] res = new int[pq.size()];
    for (int i = 0; i < res.length; i++) res[i] = pq.poll();
    return res;
}
```

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

- **Montículo de mínimos para los mayores** (y de máximos para los menores): la cima tiene que ser el
  candidato a salir.
- **`heapreplace`** en Python saca y mete con un solo `siftDown`; `heapq.nlargest(k, a)` hace todo esto
  y además ordena.
- **Con `k` cerca de `n`**, ordenar o *quickselect* ([`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md)) son mejores.

### De la versión ingenua a la buena

**El problema.** Un registro de `10⁸` transacciones que se lee línea a línea; se piden las `k = 100` de
mayor importe.

**La versión ingenua:**

```java
// O(n log n) tiempo y O(n) memoria: guarda las 10⁸ y las ordena. No cabe en memoria.
static long[] topAmounts(java.util.Iterator<Long> log, int k) {
    java.util.ArrayList<Long> all = new java.util.ArrayList<>();
    log.forEachRemaining(all::add);
    all.sort(java.util.Collections.reverseOrder());
    return all.subList(0, k).stream().mapToLong(Long::longValue).toArray();
}
```

> «Solo necesito las 100 mayores. Si guardo esas 100 en un montículo de mínimos, la peor de ellas está
> arriba y decide si entra cada nueva. Memoria `O(k)` y `log k` por línea.»

**El camino a la buena.** La plantilla con `long` y el flujo de entrada.

**Cuándo sí**: flujos que no caben en memoria; `k` mucho menor que `n`; «los `k` más frecuentes» tras
contar. **Cuándo no**: si se piden posiciones arbitrarias muchas veces, ordenar una vez.

> **Veredicto:** para los `k` mayores, un montículo de **mínimos** de tamaño `k`: el peor de los buenos
> vigila la puerta. `O(n log k)` y `O(k)` de memoria.

---

## 4. 🧱 Mezcla de `k` listas

**Qué es.** Un montículo con la cabeza de cada lista ordenada; se saca la menor y entra la siguiente de la
misma lista.

**Por qué es correcto.** Invariante: el montículo contiene, para cada lista no agotada, su menor elemento
no emitido. El menor de todos los no emitidos es el menor de las cabezas, así que la salida queda
ordenada.

**Cómo va**, con `A = [1, 5, 9]`, `B = [2, 6]`, `C = [5]`:

```text
montículo (valor, lista)          sale    entra
(1,A) (2,B) (5,C)                 1       (5,A)
(2,B) (5,A) (5,C)                 2       (6,B)
(5,A) (5,C) (6,B)                 5 (A)   (9,A)
(5,C) (6,B) (9,A)                 5 (C)   —
(6,B) (9,A)                       6       —
(9,A)                             9       —
salida: 1 2 5 5 6 9
```

**Cuánto.** `O(N log k)`; memoria `O(k)` más la salida.

**La plantilla**, sobre arreglos:

```cpp
#include <functional>
#include <queue>
#include <tuple>
#include <vector>

// Mezcla k listas ordenadas. O(N log k).
std::vector<int> mergeK(const std::vector<std::vector<int>>& lists) {
    using Entry = std::tuple<int, int, int>;                          // (valor, lista, posición)
    std::priority_queue<Entry, std::vector<Entry>, std::greater<Entry>> pq;
    for (int i = 0; i < (int)lists.size(); i++) if (!lists[i].empty()) pq.emplace(lists[i][0], i, 0);
    std::vector<int> out;
    while (!pq.empty()) {
        auto [v, i, j] = pq.top(); pq.pop();
        out.push_back(v);
        if (j + 1 < (int)lists[i].size()) pq.emplace(lists[i][j + 1], i, j + 1);
    }
    return out;
}
```

```java
// Mezcla k listas ordenadas. O(N log k).
static java.util.List<Integer> mergeK(int[][] lists) {
    java.util.PriorityQueue<int[]> pq =
        new java.util.PriorityQueue<>((x, y) -> Integer.compare(x[0], y[0]));   // {valor, lista, pos}
    for (int i = 0; i < lists.length; i++) if (lists[i].length > 0) pq.offer(new int[]{lists[i][0], i, 0});
    java.util.List<Integer> out = new java.util.ArrayList<>();
    while (!pq.isEmpty()) {
        int[] t = pq.poll();
        out.add(t[0]);
        if (t[2] + 1 < lists[t[1]].length) pq.offer(new int[]{lists[t[1]][t[2] + 1], t[1], t[2] + 1});
    }
    return out;
}
```

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

- **El índice de lista en la tupla** desempata y evita comparar objetos que no son comparables.
- **`Integer.compare`** en el comparador de Java, nunca la resta.
- **Python** tiene `heapq.merge(*lists)`, que hace esto de forma perezosa.

### De la versión ingenua a la buena

**El problema.** `k = 10³` archivos de registro, cada uno ordenado por marca de tiempo, con `N = 10⁷`
líneas en total; hay que producir un solo registro ordenado.

**La versión ingenua:**

```java
// O(N · k): en cada paso, recorre las k cabezas buscando la menor. 10¹⁰ comparaciones.
static java.util.List<Long> mergeNaive(long[][] files) {
    int[] pos = new int[files.length];
    java.util.List<Long> out = new java.util.ArrayList<>();
    while (true) {
        int best = -1;
        for (int i = 0; i < files.length; i++)
            if (pos[i] < files[i].length && (best < 0 || files[i][pos[i]] < files[best][pos[best]])) best = i;
        if (best < 0) return out;
        out.add(files[best][pos[best]++]);
    }
}
```

> «En cada paso solo cambia una cabeza: la que sale. No hace falta volver a mirar las `k`: si las tengo en
> un montículo, la menor está arriba y la nueva cabeza entra en `log k`.»

**El camino a la buena.** La plantilla con `long`.

**Cuándo sí**: ordenación externa, mezcla de índices, el `k`-ésimo menor de varias listas ordenadas.
**Cuándo no**: con `k = 2`, la mezcla de dos punteros de [`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md) es más simple.

> **Veredicto:** mezclar `k` listas es mantener sus cabezas en un montículo: `log k` por elemento en vez
> de `k`.

---

## 5. 🧱 La mediana con dos *heaps*

**Qué es.** Un montículo de máximos con la mitad menor y uno de mínimos con la mitad mayor, equilibrados
para que la mediana esté siempre en una cima.

**Por qué es correcto.** Por el invariante de §2: si todo lo de `lo` es `≤` que todo lo de `hi` y los
tamaños difieren en 0 o 1 (con `lo` el grande), la cima de `lo` es el elemento central (el inferior, con
`n` par).

**Cómo va**, sobre `[5, 2, 9, 1, 5, 6]` (mediana inferior):

```text
llega   lo (máximos)    hi (mínimos)    mediana
5       {5}             {}              5
2       {2}             {5}             2       el 5 pasa a hi para equilibrar
9       {2, 5}          {9}             5
1       {1, 2}          {5, 9}          2
5       {1, 2, 5}       {5, 9}          5
6       {1, 2, 5}       {5, 6, 9}       5
```

**Cuánto.** `O(log n)` por inserción; `O(1)` para leer la mediana.

**La plantilla:**

```cpp
#include <functional>
#include <queue>
#include <vector>

// Mediana inferior de un flujo. add O(log n), median O(1).
struct RunningMedian {
    std::priority_queue<int> lo;                                            // máximos: mitad menor
    std::priority_queue<int, std::vector<int>, std::greater<int>> hi;      // mínimos: mitad mayor
    void add(int x) {
        if (lo.empty() || x <= lo.top()) lo.push(x); else hi.push(x);
        if (lo.size() > hi.size() + 1) { hi.push(lo.top()); lo.pop(); }
        else if (hi.size() > lo.size()) { lo.push(hi.top()); hi.pop(); }
    }
    int median() const { return lo.top(); }                                // pre: no vacío
};
```

```java
// Mediana inferior de un flujo. add O(log n), median O(1).
static final class RunningMedian {
    final java.util.PriorityQueue<Integer> lo = new java.util.PriorityQueue<>(java.util.Comparator.reverseOrder());
    final java.util.PriorityQueue<Integer> hi = new java.util.PriorityQueue<>();
    void add(int x) {
        if (lo.isEmpty() || x <= lo.peek()) lo.offer(x); else hi.offer(x);
        if (lo.size() > hi.size() + 1) hi.offer(lo.poll());
        else if (hi.size() > lo.size()) lo.offer(hi.poll());
    }
    int median() { return lo.peek(); }
}
```

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

- **Para la mediana como media** de los dos centrales con `n` par: `(lo.top() + hi.top()) / 2`, con
  cuidado de no desbordar ni perder decimales.
- **Equilibrar después de insertar**: un solo trasvase basta, porque los tamaños solo cambian en 1.
- **Con borrados** (mediana de una ventana deslizante), hace falta borrado perezoso en los dos montículos
  y llevar los tamaños **vivos** aparte (§6).

### De la versión ingenua a la buena

**El problema.** Un monitor recibe `10⁵` latencias y, tras cada una, muestra la mediana de todas las
recibidas.

**La versión ingenua:**

```java
// O(n²): inserta en una lista ordenada (desplazando) y lee el centro.
static int addAndMedian(java.util.ArrayList<Integer> sorted, int x) {
    int pos = java.util.Collections.binarySearch(sorted, x);
    sorted.add(pos < 0 ? -pos - 1 : pos, x);
    return sorted.get((sorted.size() - 1) / 2);
}
```

> «Para la mediana solo necesito el borde entre la mitad menor y la mayor. Si guardo cada mitad en un
> montículo, el máximo de la menor y el mínimo de la mayor están arriba, y mantener el equilibrio cuesta
> `log n` por llegada.»

**El camino a la buena.** `RunningMedian`.

**Cuándo sí**: medianas o percentiles de un flujo; cualquier «elemento central» con inserciones.
**Cuándo no**: si también hay borrados arbitrarios, dos montículos con borrado perezoso, o un árbol de
estadísticos de orden ([`07/02`](../07-arboles/02-bst-y-balanceados.md)).

> **Veredicto:** la mediana de un flujo es el borde entre dos montículos: uno de máximos con la mitad
> menor y otro de mínimos con la mayor.

---

## 6. 🧱 Borrado perezoso

**Qué es.** Borrar o actualizar elementos de un montículo de biblioteca sin buscarlos: se anota el borrado
y se descarta el elemento cuando llega a la cima.

**Por qué es correcto** (el enunciado y una frase): la cima que se devuelve es siempre un elemento vivo,
porque antes de mirarla se descartan todas las cimas anotadas como borradas; los muertos que quedan
debajo no influyen hasta que suben, y entonces se descartan.

**Cómo va**, montículo de mínimos con `{1, 2, 5, 6, 9}` y borrados pendientes `{2}`:

```text
borrar 1   → pendientes {1, 2}            (el montículo no cambia)
cima?      → la cima es 1, está pendiente: se saca y se tacha; la cima es 2, pendiente: igual
           → la cima es 5: viva. Respuesta 5. Pendientes {}
```

**Cuánto.** Cada elemento entra y sale una vez: `O(log n)` amortizado por operación, con el montículo
creciendo hasta el número total de inserciones.

**La plantilla**, con un mapa de cuentas pendientes:

```cpp
#include <functional>
#include <queue>
#include <unordered_map>
#include <vector>

// Montículo de mínimos con borrado perezoso de valores. O(log n) amortizado.
struct LazyHeap {
    std::priority_queue<int, std::vector<int>, std::greater<int>> pq;
    std::unordered_map<int, int> dead;                   // valor → copias por borrar
    int alive = 0;
    void push(int x) { pq.push(x); alive++; }
    void erase(int x) { dead[x]++; alive--; }            // pre: x está vivo
    void clean() {
        while (!pq.empty()) {
            auto it = dead.find(pq.top());
            if (it == dead.end() || it->second == 0) return;
            it->second--; pq.pop();
        }
    }
    int top() { clean(); return pq.top(); }              // pre: alive > 0
    void pop() { clean(); pq.pop(); alive--; }
};
```

```java
// Montículo de mínimos con borrado perezoso de valores. O(log n) amortizado.
static final class LazyHeap {
    final java.util.PriorityQueue<Integer> pq = new java.util.PriorityQueue<>();
    final java.util.HashMap<Integer, Integer> dead = new java.util.HashMap<>();
    int alive = 0;
    void push(int x) { pq.offer(x); alive++; }
    void erase(int x) { dead.merge(x, 1, Integer::sum); alive--; }
    void clean() {
        while (!pq.isEmpty()) {
            Integer c = dead.get(pq.peek());
            if (c == null || c == 0) return;
            dead.put(pq.peek(), c - 1); pq.poll();
        }
    }
    int top() { clean(); return pq.peek(); }
    void pop() { clean(); pq.poll(); alive--; }
}
```

- **`alive`**: el tamaño de la cola de biblioteca incluye los muertos; el tamaño real se lleva aparte.
- **Para cambiar prioridades** (Dijkstra), no hace falta el mapa: se mete `(distancia nueva, nodo)` y, al
  sacar, se descarta si la distancia no coincide con la mejor conocida del nodo ([`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md)).
- **Memoria**: el montículo puede tener tantos elementos como inserciones; si hay muchísimos borrados,
  conviene reconstruirlo cuando los muertos superan a los vivos.

**Cuándo sí**: borrar o actualizar en colas de biblioteca; medianas de ventanas; planificadores con
cancelaciones. **Cuándo no**: si la memoria no da para los muertos, la cola indexada (`08/01`) o un árbol
balanceado.

> **Veredicto:** el borrado perezoso no borra: anota y descarta al llegar arriba. Es la forma de tener
> borrado y `decrease-key` con la cola de prioridad de cualquier biblioteca.

---

## 7. ⏱️ La tabla de costes

| Patrón | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| `k` mayores | `O(n log k)` | `O(k)` | Montículo de **mínimos** para los mayores |
| Mezcla de `k` listas | `O(N log k)` | `O(k)` | Con `k = 2`, dos punteros |
| Mediana con dos *heaps* | `O(log n)` por inserción, `O(1)` consulta | `O(n)` | Con borrados, perezoso en los dos |
| Borrado perezoso | `O(log n)` amortizado | Hasta las inserciones totales | El tamaño vivo, aparte |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Los `k` mayores / más frecuentes / más cercanos», `k ≪ n` | Montículo de tamaño `k` | `O(n log k)` |
| «Mezcla», «`k` listas ordenadas», «el `m`-ésimo de varias listas» | Montículo de cabezas | Solo cambia una cabeza por paso |
| «La mediana tras cada llegada» | Dos montículos | El borde entre mitades |
| «Cancela la tarea», «actualiza la prioridad» | Borrado perezoso | Las bibliotecas no borran |
| «La más urgente disponible en el instante `t`» | Ordenar por llegada + montículo de disponibles | Planificación por eventos |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Para los `k` mayores ordeno todo» | `O(n log n)` y memoria `O(n)`; con un montículo de tamaño `k`, `O(n log k)` y `O(k)` |
| «Para los `k` mayores uso un montículo de máximos» | Uno de **mínimos** de tamaño `k`: la cima es la que puede salir |
| «En la mediana, cada valor nuevo va a `lo`» | Va a `lo` o a `hi` según su valor, y después se equilibra |
| «`pq.size()` es el número de elementos vivos» | Con borrado perezoso, no: se lleva un contador aparte |
| «La mezcla de `k` listas es `O(N log N)`» | Es `O(N log k)`: el montículo nunca pasa de `k` |

---

## 📚 Para profundizar

- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §2.4: colas de prioridad y
  sus aplicaciones (los `M` mayores, la mezcla de flujos). *Lectura troncal.*
- **Libro** — Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 3: colas de prioridad
  como estructura de diseño. *Lectura troncal.*
- **Documentación** — Python, [`heapq`](https://docs.python.org/3/library/heapq.html), con `merge`,
  `nlargest` y `nsmallest`.

---

## 🧠 Preguntas

1. ¿Qué montículo usas para los `k` mayores, de mínimos o de máximos, y de qué tamaño? 🟢
2. ¿Qué guarda el montículo al mezclar `k` listas? 🟢
3. ¿Dónde está la mediana en el esquema de dos montículos? 🟢
4. ¿Por qué la mezcla de `k` listas cuesta `O(N log k)` y no `O(N log N)`? 🟡
5. ¿Qué invariantes mantienen los dos montículos de la mediana, y cómo se restauran tras insertar? 🟡
6. ¿Qué es el borrado perezoso y por qué no cambia el coste amortizado? 🟡
7. ¿Cómo haces Dijkstra con la cola de prioridad de tu lenguaje, sin `decrease-key`? 🟡
8. Demuestra que el montículo de tamaño `k` retiene exactamente los `k` mayores. 🟠
9. Compara cómo escribes la mediana de un flujo en C++, Java y Python. 🟠
10. ¿Cómo calculas la mediana de cada ventana de tamaño `k` con dos montículos? ¿Qué cambia respecto del flujo? 🟠
11. ¿Cuándo es mejor ordenar o *quickselect* que un montículo de tamaño `k`? 🟠
12. Con `k` listas ordenadas de enteros, ¿cómo encuentras el `m`-ésimo menor sin mezclarlas enteras, y con qué coste? 🔴
13. Demuestra que ningún algoritmo por comparación mezcla `k` listas ordenadas de `N/k` elementos cada una en menos de `Ω(N log k)` comparaciones. 🔴

---

## 🧩 Problemas propios

### Turnos de las atracciones

**Nivel:** 🟡 · **Formato:** programa completo.

Un parque tiene `k` operarios (numerados de 0 a `k − 1`) y una cola de `n` atracciones por revisar, cada una
con su duración. Cada atracción, en orden, la toma el operario que antes quede libre (a igualdad, el de
menor número); todos empiezan libres en el instante 0. Imprime el instante en que termina cada revisión.

- **Entrada.** Una línea con `n` y `k`. Una línea con las `n` duraciones.
- **Salida.** `n` enteros.
- **Restricciones.** `1 ≤ n, k ≤ 2·10⁵`; `1 ≤ duración ≤ 10⁹`.

```text
Entrada                Salida
6 2                    5 2 11 6 11 17
5 2 9 1 5 6

Entrada                Salida
2 3                    1000000000 1000000000
1000000000 1000000000
```

**Pista 1:** ¿qué necesitas saber de cada operario para asignar la siguiente atracción?

### Fusión de clasificaciones

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `k` clasificaciones, cada una con sus tiempos ordenados de menor a mayor. Imprime los `m` mejores
tiempos de todas juntas.

- **Entrada.** Una línea con `k` y `m`. Después, `k` líneas: la longitud y los tiempos de cada una.
- **Salida.** `m` enteros en orden creciente.
- **Restricciones.** `1 ≤ k ≤ 10⁵`; suma de longitudes `≤ 10⁶`; `1 ≤ m ≤` suma de longitudes.

```text
Entrada            Salida
3 4                1 2 5 5
3 1 5 9
2 2 6
1 5

Entrada            Salida
2 3                7 7 7
1 7
2 7 7
```

**Pista 1:** ¿cuántos tiempos tienes que mirar como candidatos en cada paso?

### Mediana con bajas

**Nivel:** 🟠 · **Formato:** programa completo.

Un multiconjunto empieza vacío. Llegan órdenes: `+ x` (añade `x`), `- x` (quita una copia de `x`, que
existe) y `?` (imprime la mediana inferior: el elemento en la posición `⌊(n − 1)/2⌋` en orden).

- **Entrada.** Una línea con `q`. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`; se garantiza que el conjunto no está vacío.
- **Restricciones.** `1 ≤ q ≤ 2·10⁵`; `|x| ≤ 10⁹`.

```text
Entrada            Salida
8                  5
+ 5                2
+ 2                2
+ 9
?
- 5
?
+ 1
?

Entrada            Salida
4                  -1000000000
+ -1000000000      -1000000000
?
+ 1000000000
?
```

**Pista 1:** si un valor borrado sigue dentro de un montículo, ¿qué tamaño tienes que usar para equilibrar?

---

## 🧩 Práctica externa

> 💡 **Truco.** En los problemas de planificación, antes de escribir código, simula a mano los tres
> primeros eventos con los montículos dibujados. Si una IA te da la solución, pídele solo esa simulación
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Task Scheduler](https://leetcode.com/problems/task-scheduler/) | LeetCode | 🟡 | Montículo de frecuencias con espera | ¿Qué tarea conviene ejecutar en cada hueco? |
| [ ] | [Reorganize String](https://leetcode.com/problems/reorganize-string/) | LeetCode | 🟡 | Montículo de frecuencias | ¿Qué letra pones en cada posición para no repetir la anterior? |
| [ ] | [Single-Threaded CPU](https://leetcode.com/problems/single-threaded-cpu/) | LeetCode | 🟡 | Eventos + montículo de disponibles | ¿Qué tareas puede elegir la CPU en cada instante? |
| [ ] | [Furthest Building You Can Reach](https://leetcode.com/problems/furthest-building-you-can-reach/) | LeetCode | 🟡 | Montículo de los `k` mayores saltos | ¿A qué saltos conviene reservar las escaleras? |
| [ ] | [Design Twitter](https://leetcode.com/problems/design-twitter/) | LeetCode | 🟡 | Mezcla de `k` listas | ¿Cuántos tuits de cada usuario necesitas mirar para dar los 10 más recientes? |
| [ ] | [Design a Number Container System](https://leetcode.com/problems/design-a-number-container-system/) | LeetCode | 🟡 | Borrado perezoso | Si un índice cambia de número, ¿cómo sabes que la cima de un montículo ya no vale? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Minimum Average Waiting Time](https://www.hackerrank.com/challenges/minimum-average-waiting-time/problem) | HackerRank | 🟠 | Planificación por la más corta disponible | Cuando el cocinero queda libre, ¿qué pedido le conviene empezar? |
| [ ] | [Sliding Window Median](https://leetcode.com/problems/sliding-window-median/) | LeetCode | 🔴 | Dos montículos con borrado perezoso | Al salir un valor de la ventana, ¿en qué montículo estaba? |
| [ ] | [Smallest Range Covering Elements from K Lists](https://leetcode.com/problems/smallest-range-covering-elements-from-k-lists/) | LeetCode | 🔴 | Montículo de cabezas con máximo | Con una cabeza de cada lista, ¿qué rango cubren y cómo lo estrechas? |
| [ ] | [IPO](https://leetcode.com/problems/ipo/) | LeetCode | 🔴 | Ordenar + montículo de disponibles | Con el capital actual, ¿qué proyectos puedes elegir y cuál conviene? |
| [ ] | [Minimum Number of Refueling Stops](https://leetcode.com/problems/minimum-number-of-refueling-stops/) | LeetCode | 🔴 | Montículo de gasolineras pasadas | Si te quedas sin combustible, ¿en qué gasolinera ya pasada «habrías» parado? |
| [ ] | [The Skyline Problem](https://leetcode.com/problems/the-skyline-problem/) | LeetCode | 🔴 | Barrido + montículo con borrado perezoso | En cada coordenada, ¿qué edificios siguen en pie y cuál es el más alto? |

---

## ✅ Criterio de dominio

- Escribir los `k` mayores, la mezcla de `k` listas y la mediana con dos montículos sin mirar.
- Demostrar el invariante de los `k` mayores y el de la mediana.
- Añadir borrado perezoso a la cola de prioridad de cualquier lenguaje.
- Resolver Single-Threaded CPU y Sliding Window Median sin pista 2.

---

**Anterior:** [`08/01` — Montículo binario](01-monticulo-binario.md) · **Siguiente:** [`08/03` — Montículos fusionables](03-monticulos-fusionables.md) ·
**Relacionado:** [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas](../11-voraces/03-plazos-huffman-y-monedas.md); [`15/01` — Dijkstra](../15-grafos-pesos-y-flujos/01-dijkstra.md).
