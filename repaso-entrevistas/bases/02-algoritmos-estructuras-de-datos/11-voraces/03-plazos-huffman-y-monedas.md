# 03 — Plazos, Huffman, mochila fraccionaria y monedas

> Cuatro voraces clásicos con su prueba: la planificación de tareas con plazos y beneficios, el código de
> Huffman, la mochila fraccionaria y el cambio de monedas en sistemas canónicos. Y el contraste que más se
> pregunta: por qué la mochila 0/1 y las monedas arbitrarias **no** son voraces.
>
> **Niveles:** planificación con plazos [A] · Huffman [A] · mochila fraccionaria [A] · monedas
> canónicas [A].
>
> **📚 Lectura troncal:** Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 6;
> Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009), §16.3;
> Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), cap. 4.
>
> **Asume leído:** [`11/01` — Cuándo funciona un voraz](01-cuando-funciona-un-voraz.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--planificación-con-plazos) · [4](#4--huffman) · [5](#5--mochila-fraccionaria) · [6](#6--monedas-canónicas) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Cuatro preguntas que parecen de la misma familia:

```text
cargar la mochila de capacidad 10 con trozos de cualquier tamaño   → voraz por valor/peso: 18,4
cargar la mochila de capacidad 10 con objetos enteros              → voraz falla: hace falta DP (12/03)
dar 63 céntimos con monedas {1, 5, 10, 25}                          → voraz: 25 + 25 + 10 + 1 + 1 + 1
dar 6 con monedas {1, 3, 4}                                         → voraz da 4 + 1 + 1; lo óptimo es 3 + 3
```

Cambiar un detalle del enunciado (poder partir los objetos, el sistema de monedas) cambia la técnica
entera. Este capítulo trae cuatro voraces que sí son correctos, cada uno con la prueba que lo sostiene, y
el criterio para saber cuándo el gemelo de al lado ya no lo es.

> 🧠 **Modelo mental.** Un voraz es correcto por la **estructura** del problema, no por su aspecto. Si el
> enunciado permite fracciones, si las tareas duran lo mismo, si el sistema de monedas es canónico: esos
> detalles son la prueba, y quitarlos la rompe.

---

## 2. 📐 La teoría

**Plazos (tareas unitarias).** Cada tarea dura una unidad, tiene un plazo `d` y un beneficio `p`, y solo
da beneficio si termina a tiempo. Un conjunto de tareas es **factible** si, ordenadas por plazo, la `k`-ésima
tiene plazo `≥ k`. Los conjuntos factibles forman una **matroide** ([`11/04`](04-matroides-y-contraejemplos.md)), y en una matroide el voraz
«de mayor a menor beneficio, si sigue siendo factible» es óptimo.

**Teorema (Huffman).** Para unas frecuencias `f₁, …, fₙ`, el árbol que se obtiene uniendo repetidamente
los dos nodos de menor frecuencia minimiza el coste `Σ fᵢ · profundidad(i)`, que es el número total de
bits del texto codificado. *Esbozo*: (1) en algún árbol óptimo, los dos símbolos menos frecuentes son
hermanos en el nivel más profundo (intercambio: si no lo fueran, cambiarlos con los del fondo no empeora);
(2) uniéndolos en un solo símbolo de frecuencia `f₁ + f₂`, el problema se reduce a `n − 1` símbolos, y el
coste cambia en exactamente `f₁ + f₂`, así que un óptimo del reducido da un óptimo del original. CLRS,
§16.3, tiene la prueba entera.

**Mochila fraccionaria.** Ordenar por valor por unidad de peso y llenar: cualquier solución que lleve
menos del mejor material y más de uno peor se puede mejorar intercambiando una cantidad igual de peso.

**Monedas.** Un sistema es **canónico** si el voraz (siempre la moneda más grande que cabe) da el mínimo de
monedas para toda cantidad. `{1, 5, 10, 25}` lo es; `{1, 3, 4}` no (6 = 3 + 3). **Teorema (Kozen y Zaks,
1994).** Si un sistema no es canónico, su menor contraejemplo es menor que la suma de sus dos monedas
mayores: basta comprobar con una DP las cantidades hasta ahí.

---

## 3. 🧱 Planificación con plazos

**Qué es.** Elegir qué tareas unitarias hacer (una por instante, desde el 1) para maximizar el beneficio de
las que acaban dentro de su plazo.

**Por qué es correcto.** Por la estructura de matroide de §2, o por intercambio directo: si una óptima no
incluye la tarea de mayor beneficio entre las que caben, se puede cambiar por la de menor beneficio de su
mismo hueco sin perder factibilidad ni beneficio. La plantilla usa una forma equivalente y más fácil de
escribir: recorrer **por plazo** y, si hay más tareas que huecos, **soltar la de menor beneficio** (un
voraz con arrepentimiento).

**Cómo va**, tareas `(plazo, beneficio)` = `(2,5) (1,2) (2,9) (1,1) (3,5) (3,6)`, por plazo, con un montículo
de mínimos de beneficios:

```text
(1,1) → {1}                       caben 1, hay 1
(1,2) → {1,2} → sobra: suelta 1   {2}
(2,5) → {2,5}                     caben 2
(2,9) → {2,5,9} → sobra: suelta 2 {5,9}
(3,5) → {5,5,9}                   caben 3
(3,6) → {5,5,6,9} → suelta 5      {5,6,9}
beneficio: 20  (la fuerza bruta sobre los 64 subconjuntos da lo mismo)
```

**Cuánto.** Ordenar, `Θ(n log n)`, y cada tarea entra y sale del montículo una vez: `Θ(n log n)`.

**La plantilla:**

```cpp
#include <algorithm>
#include <functional>
#include <queue>
#include <vector>

// Máximo beneficio de tareas unitarias (plazo, beneficio) que acaban a tiempo. Θ(n log n).
long long maxProfit(std::vector<std::pair<long long, long long>> jobs) {
    std::sort(jobs.begin(), jobs.end());                                  // por plazo
    std::priority_queue<long long, std::vector<long long>, std::greater<>> kept;   // min-heap
    long long total = 0;
    for (auto [d, p] : jobs) {
        kept.push(p); total += p;
        if ((long long)kept.size() > d) { total -= kept.top(); kept.pop(); }   // suelta la peor
    }
    return total;
}
```

```java
import java.util.Arrays;
import java.util.PriorityQueue;

// Máximo beneficio de tareas unitarias {plazo, beneficio} que acaban a tiempo. Θ(n log n).
static long maxProfit(long[][] jobs) {
    long[][] byDeadline = jobs.clone();
    Arrays.sort(byDeadline, (a, b) -> Long.compare(a[0], b[0]));
    PriorityQueue<Long> kept = new PriorityQueue<>();                     // min-heap
    long total = 0;
    for (long[] j : byDeadline) {
        kept.add(j[1]); total += j[1];
        if (kept.size() > j[0]) total -= kept.poll();
    }
    return total;
}
```

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

- **El invariante**: tras procesar las tareas con plazo `≤ d`, el montículo tiene las mejores tareas
  factibles entre ellas, como mucho `d`.
- **Plazos enormes** (`10⁹`) no molestan: nunca se crea un arreglo de huecos.
- **Con duraciones distintas** el problema ya no es este; si se maximiza el número de tareas, el mismo
  esquema soltando la **más larga** funciona (Course Schedule III); con beneficios y duraciones, es NP-difícil.

### De la versión ingenua a la buena

**El problema.** Maximizar el beneficio con `n ≤ 2·10⁵` tareas unitarias.

**La versión ingenua:**

```java
// Correcta: todos los subconjuntos, comprobando la factibilidad por plazos ordenados. Θ(2ⁿ · n log n).
static long bruteForce(long[][] jobs) {
    int n = jobs.length; long best = 0;
    for (int mask = 0; mask < (1 << n); mask++) {
        long[] d = new long[Integer.bitCount(mask)]; long sum = 0; int k = 0;
        for (int i = 0; i < n; i++) if ((mask >> i & 1) == 1) { d[k++] = jobs[i][0]; sum += jobs[i][1]; }
        java.util.Arrays.sort(d);
        boolean ok = true;
        for (int i = 0; i < k; i++) ok &= d[i] >= i + 1;
        if (ok) best = Math.max(best, sum);
    }
    return best;
}
```

> «Pruebo todos los conjuntos. Pero un conjunto es factible si sus plazos ordenados lo permiten, y si al
> añadir una tarea me paso, me conviene quitar la de menor beneficio de las que llevo: recorro por plazo
> con un montículo de beneficios y suelto el mínimo cuando sobran.»

**El camino a la buena.** La plantilla. `Θ(n log n)`.

**Cuándo sí**: tareas de duración igual, plazos y beneficios; «haz como mucho `k` por día». **Cuándo no**:
duraciones distintas con beneficios (NP-difícil, DP sobre el tiempo si es pequeño); o si las tareas tienen
inicio además de plazo.

> **Veredicto:** plazos con tareas unitarias: por plazo, montículo de mínimos, y soltar la peor cuando
> sobran. Es un voraz con arrepentimiento, y es correcto porque los conjuntos factibles son una matroide.

---

## 4. 🧱 Huffman

**Qué es.** Construir el código prefijo de longitud media mínima para unas frecuencias de símbolos, uniendo
siempre los dos nodos menos frecuentes.

**Por qué es correcto.** El teorema de §2: elección voraz (los dos menos frecuentes son hermanos al fondo
de algún óptimo) y subestructura óptima (unirlos deja el mismo problema con un símbolo menos).

**Cómo va**, con las frecuencias de la cadena de juguete `abracadabra`: `a 5 · b 2 · r 2 · c 1 · d 1`:

```text
une c(1) + d(1)       → 2       montículo: 2 2 2 5
une 2 + 2             → 4       montículo: 2 4 5
une 2 + 4             → 6       montículo: 5 6
une 5 + 6             → 11      raíz
coste = 2 + 4 + 6 + 11 = 23 bits     (con un código fijo de 3 bits: 11 · 3 = 33)
```

El coste total es la suma de los nodos internos creados: cada símbolo suma su frecuencia una vez por cada
unión que lo contiene, es decir, por cada nivel de profundidad.

**Cuánto.** `n − 1` uniones con un montículo: `Θ(n log n)`. Si las frecuencias vienen ordenadas, con dos
colas `Θ(n)`.

**La plantilla**, el coste total (los bits del texto codificado):

```cpp
#include <functional>
#include <queue>
#include <vector>

// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman. Θ(n log n).
long long huffmanCost(const std::vector<long long>& freq) {
    std::priority_queue<long long, std::vector<long long>, std::greater<>> pq(freq.begin(), freq.end());
    long long cost = 0;
    while (pq.size() > 1) {
        long long a = pq.top(); pq.pop();
        long long b = pq.top(); pq.pop();
        cost += a + b;                         // el nodo interno nuevo
        pq.push(a + b);
    }
    return cost;                               // 0 con un solo símbolo
}
```

```java
import java.util.PriorityQueue;

// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman. Θ(n log n).
static long huffmanCost(long[] freq) {
    PriorityQueue<Long> pq = new PriorityQueue<>();
    for (long f : freq) pq.add(f);
    long cost = 0;
    while (pq.size() > 1) {
        long a = pq.poll(), b = pq.poll();
        cost += a + b;
        pq.add(a + b);
    }
    return cost;
}
```

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

- **Para construir el código** (no solo el coste), cada entrada del montículo lleva un nodo con sus hijos, y
  el código de un símbolo es el camino desde la raíz (0 a la izquierda, 1 a la derecha).
- **Con un solo símbolo** el coste es 0, pero un código de 0 bits no se puede transmitir: los formatos
  reales le dan 1 bit.
- **64 bits**: con `10⁵` frecuencias de `10⁹`, el coste pasa de `2³¹`.

### De la versión ingenua a la buena

**El problema.** Los bits mínimos para codificar un texto con un código prefijo, dadas sus frecuencias.

**La versión ingenua:**

```java
// Correcta: prueba todos los pares en cada paso. Θ(n!²) aproximadamente.
static long bestMerge(java.util.List<Long> nodes) {
    if (nodes.size() == 1) return 0;
    long best = Long.MAX_VALUE;
    for (int i = 0; i < nodes.size(); i++)
        for (int j = i + 1; j < nodes.size(); j++) {
            java.util.List<Long> next = new java.util.ArrayList<>(nodes);
            long a = next.get(i), b = next.get(j);
            next.remove(j); next.remove(i); next.add(a + b);
            best = Math.min(best, a + b + bestMerge(next));
        }
    return best;
}
```

> «Pruebo todos los órdenes de unión. Pero el coste es la suma de los nodos internos, y unir primero lo
> más pequeño hace que lo pequeño quede más abajo y lo grande más arriba. Los dos menos frecuentes pueden
> ser hermanos al fondo de un óptimo, así que unirlos es seguro: con un montículo, `n log n`.»

**El camino a la buena.** La plantilla.

**Cuándo sí**: «código prefijo óptimo», «unir montones pagando su suma», «coste de mezclar ficheros por
pares». **Cuándo no**: si el orden de los símbolos debe conservarse (código alfabético) o solo se pueden unir
vecinos, el voraz falla: es una DP de intervalos ([`12/05`](../12-dp-clasica/05-rejillas-e-intervalos.md)).

> **Veredicto:** Huffman es «une los dos más pequeños» con un montículo, y su coste es la suma de los nodos
> internos. Detrás de casi todo problema de «unir pagando la suma» está este árbol.

---

## 5. 🧱 Mochila fraccionaria

**Qué es.** Llenar una mochila de capacidad `W` con materiales divisibles, cada uno con peso y valor
totales, maximizando el valor.

**Por qué es correcto.** Intercambio: si una solución lleva una cantidad `ε` de un material de razón menor
y deja sin tomar `ε` de uno de razón mayor, cambiarlos aumenta el valor. Luego en el óptimo se toman los
materiales por razón decreciente hasta llenar, y solo el último queda partido.

**Cómo va**, con los objetos de `10/03`, `(peso, valor)` = `(5,10) (2,3) (9,14) (1,2) (5,8) (6,9)` y `W = 10`:

```text
por razón: (5,10) 2 · (1,2) 2 · (5,8) 1,6 · (9,14) 1,56 · (2,3) 1,5 · (6,9) 1,5
toma (5,10) entero    → peso 5, valor 10
toma (1,2) entero     → peso 6, valor 12
toma 4/5 de (5,8)     → peso 10, valor 12 + 6,4 = 18,4
```

Es la cota que usaba la ramificación y poda de [`10/03`](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md): la mochila entera vale 18 y la fraccionaria
18,4.

**Cuánto.** Ordenar, `Θ(n log n)`; con selección lineal de la razón mediana se puede en `Θ(n)`.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Valor máximo con materiales divisibles (peso, valor). Θ(n log n).
double fractionalKnapsack(std::vector<std::pair<long long, long long>> items, long long cap) {
    std::sort(items.begin(), items.end(), [](const auto& a, const auto& b) {
        return a.second * b.first > b.second * a.first;                   // razón decreciente, sin dividir
    });
    double value = 0;
    for (auto [w, v] : items) {
        if (cap == 0) break;
        long long take = std::min(w, cap);
        value += (double)v * take / w;
        cap -= take;
    }
    return value;
}
```

```java
import java.util.Arrays;

// Valor máximo con materiales divisibles {peso, valor}. Θ(n log n).
static double fractionalKnapsack(long[][] items, long cap) {
    long[][] byRatio = items.clone();
    Arrays.sort(byRatio, (a, b) -> Long.compare(b[1] * a[0], a[1] * b[0]));   // razón decreciente
    double value = 0;
    for (long[] it : byRatio) {
        if (cap == 0) break;
        long take = Math.min(it[0], cap);
        value += (double) it[1] * take / it[0];
        cap -= take;
    }
    return value;
}
```

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

- **Ordenar con productos cruzados**, como la regla de Smith de [`11/01`](01-cuando-funciona-un-voraz.md): sin divisiones en el comparador.
- **El resultado es fraccionario**: `double` para imprimirlo con decimales; `Fraction` en Python si se
  quiere exacto.
- **Solo el último material** queda partido: es la propiedad que la prueba garantiza.

### De la versión ingenua a la buena

**El problema.** Valor máximo con `n ≤ 10⁵` materiales y `W ≤ 10⁹`.

**La versión ingenua**: con cantidades enteras, tomar una unidad cada vez del material de mejor razón que
quede, buscándolo entre los `n` en cada vuelta. Es correcta y cuesta `Θ(W · n)`.

> «Cada unidad la tomo del mejor material disponible, y eso es lo correcto; pero lo hago `W` veces. El
> mejor material sigue siéndolo hasta agotarlo, así que ordeno una vez por razón y tomo cada material
> entero de golpe, salvo el último.»

**El camino a la buena.** La plantilla: `Θ(n log n)`, independiente de `W`.

**Cuándo sí**: materiales divisibles (líquidos, granos, tiempo). **Cuándo no**: objetos enteros, donde el
voraz por razón falla —`(6, 9)`, `(5, 7)`, `(5, 7)` con `W = 10` toma el de razón 1,5 y deja 9, cuando dos de
7 dan 14—: es la mochila 0/1 de [`12/03`](../12-dp-clasica/03-mochilas.md).

> **Veredicto:** la fraccionaria es voraz por razón; la 0/1, no. La diferencia es poder partir el último
> objeto.

---

## 6. 🧱 Monedas canónicas

**Qué es.** Dar una cantidad con el menor número de monedas, usando siempre la moneda más grande que
cabe. Correcto **solo** en sistemas canónicos.

**Por qué es correcto** en `{1, 5, 10, 25}`: en una solución óptima no hay cinco monedas de 1 (cambiables por
una de 5), ni dos de 5 (por una de 10), ni tres de 10 (por 25 + 5) ni dos de 10 y una de 5 (por 25). Con esas
restricciones, lo que se da con monedas menores que 25 es como mucho 24, así que el número de monedas de 25
es el máximo posible, como hace el voraz; y lo mismo hacia abajo. La prueba se rehace para cada sistema.

**Cómo va**:

```text
{1, 5, 10, 25}, 63:  25 + 25 + 10 + 1 + 1 + 1 = 6 monedas  (óptimo: 6)
{1, 3, 4}, 6:        4 + 1 + 1 = 3 monedas                 (óptimo: 3 + 3 = 2)
{1, 5, 12}, 15:      12 + 1 + 1 + 1 = 4 monedas            (óptimo: 5 + 5 + 5 = 3)
```

**Cuánto.** El voraz, `O(k)` divisiones con `k` monedas. Comprobar si un sistema es canónico con el teorema
de Kozen y Zaks: una DP hasta `cₖ₋₁ + cₖ`, `O(k · (cₖ₋₁ + cₖ))`.

**La plantilla**, el voraz y la comprobación de canonicidad:

```cpp
#include <algorithm>
#include <vector>

// Monedas del voraz para x; coins ordenadas de mayor a menor, con la de 1. O(k).
long long greedyCoins(const std::vector<long long>& coins, long long x) {
    long long count = 0;
    for (long long c : coins) { count += x / c; x %= c; }
    return count;
}

// ¿Es canónico? Compara el voraz con la DP hasta la suma de las dos mayores (Kozen y Zaks).
bool isCanonical(const std::vector<long long>& coins) {           // de mayor a menor
    if (coins.size() < 3) return true;
    int limit = (int)(coins[0] + coins[1]);
    std::vector<long long> best(limit, 0);
    for (int x = 1; x < limit; x++) {
        best[x] = x;                                               // todo con monedas de 1
        for (long long c : coins) if (c <= x) best[x] = std::min(best[x], best[x - c] + 1);
        if (greedyCoins(coins, x) > best[x]) return false;         // x es contraejemplo
    }
    return true;
}
```

```java
// Monedas del voraz para x; coins ordenadas de mayor a menor, con la de 1. O(k).
static long greedyCoins(long[] coins, long x) {
    long count = 0;
    for (long c : coins) { count += x / c; x %= c; }
    return count;
}
```

```python
def greedy_coins(coins, x):
    """Monedas del voraz para x; coins de mayor a menor, con la de 1. O(k)."""
    count = 0
    for c in coins:
        count += x // c
        x %= c
    return count
```

- **`x / c` y `x % c`** dan todas las monedas de un valor de una vez: no hace falta restar en bucle.
- **Con cantidades enormes** (`10¹⁸`) en un sistema canónico, el voraz sigue siendo `O(k)`; la DP no cabe.
- **`isCanonical`** solo en C++ por longitud: en Java y Python es la misma DP.

### De la versión ingenua a la buena

**El problema.** Dar `x ≤ 10¹⁸` con el menor número de monedas del sistema `{1, 2, 5, 10, 20, 50, 100, 200}`.

**La versión ingenua:** la DP de `12/03`, `O(k · x)`, correcta para cualquier sistema e imposible con
`x = 10¹⁸`.

> «La DP no cabe con `10¹⁸`. Pero este sistema es canónico: lo compruebo con la DP hasta `100 + 200`, que es
> el límite de Kozen y Zaks, y después el voraz es correcto para cualquier cantidad. Son ocho divisiones.»

**El camino a la buena.** `isCanonical` una vez y `greedyCoins` para cada cantidad.

**Cuándo sí**: sistemas monetarios reales (casi todos son canónicos) y cantidades grandes. **Cuándo no**: un
sistema arbitrario del enunciado sin comprobar; ahí la DP de `12/03` (o la comprobación de canonicidad).

> **Veredicto:** «el cambio de monedas es voraz» solo en sistemas canónicos. Compruébalo con la DP hasta la
> suma de las dos mayores, o usa directamente la DP.

---

## 7. ⏱️ La tabla de costes

| Problema | Voraz | Coste | Lo que la tabla no dice |
|---|---|---|---|
| Plazos, tareas unitarias | Por plazo, soltar la peor | `Θ(n log n)` | Con duraciones distintas y beneficios, NP-difícil |
| Huffman | Unir los dos menores | `Θ(n log n)`; `Θ(n)` si vienen ordenadas | Si el orden de los símbolos se conserva, DP |
| Mochila fraccionaria | Por razón valor/peso | `Θ(n log n)` | La 0/1 no es voraz |
| Monedas | La mayor que cabe | `O(k)` | Solo en sistemas canónicos |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Cada tarea dura un día», «plazo», «beneficio si a tiempo» | Plazos con montículo | Matroide de conjuntos factibles |
| «Unir montones / cuerdas / ficheros pagando la suma» | Huffman | Coste = suma de nodos internos |
| «Puedes llevar una fracción», «litros», «gramos» | Mochila fraccionaria | Intercambio por razón |
| «Mínimo de monedas» con un sistema real o comprobable | Voraz de monedas | Canonicidad |
| «Mínimo de monedas» con un sistema arbitrario | No es voraz | DP (`12/03`) |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El cambio de monedas es voraz» | Solo en sistemas canónicos: `{1, 3, 4}` con 6 lo rompe |
| «La mochila es voraz por valor/peso» | La fraccionaria sí; la 0/1 no, y es la que más sale |
| «Huffman une los dos más frecuentes» | Une los dos **menos** frecuentes, que quedan abajo |
| «Plazos: ordeno por beneficio y meto en el primer hueco libre» | En el **último** hueco libre antes del plazo, o el recorrido por plazo con montículo |
| «Comparo razones con `double`» | Productos cruzados en 64 bits |
| «Si el voraz funciona con los billetes de mi país, funciona siempre» | Funciona con ese sistema; otro sistema necesita su comprobación |

---

## 📚 Para profundizar

- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 6: la
  planificación con plazos, la mochila y el cambio de monedas. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §16.3: los códigos de Huffman y su optimalidad. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), cap. 4, §4.8: Huffman y la
  compresión. *Lectura troncal.*
- **Artículo** — Kozen y Zaks, «Optimal Bounds for the Change-Making Problem», *Theoretical Computer
  Science* 123 (1994): la cota del menor contraejemplo.

---

## 🧠 Preguntas

1. ¿Qué une Huffman en cada paso, y cómo se calcula el coste total del código? 🟢
2. ¿Qué es un sistema de monedas canónico? Da uno que lo sea y uno que no. 🟢
3. ¿Cuándo es factible un conjunto de tareas unitarias con plazos? 🟢
4. ¿Por qué la mochila fraccionaria es voraz y la 0/1 no? Da el contraejemplo de la 0/1. 🟡
5. ¿Qué invariante mantiene el montículo en la planificación con plazos? 🟡
6. ¿Por qué el coste de Huffman es la suma de los nodos internos? 🟡
7. Compara cómo escribes el montículo de mínimos de la planificación con plazos en C++, Java y Python. 🟡
8. Esboza la prueba de optimalidad de Huffman: las dos partes y qué demuestra cada una. 🟠
9. ¿Qué dice el teorema de Kozen y Zaks y cómo lo usas para decidir si el voraz de monedas sirve? 🟠
10. ¿Por qué en la planificación con plazos conviene soltar la tarea de menor beneficio y no la última añadida? 🟠
11. ¿Qué cambia si las tareas tienen duraciones distintas, y qué voraz sigue funcionando para maximizar su número? 🔴
12. Demuestra que `{1, 5, 10, 25}` es canónico. 🔴
13. Unir montones de piedras **vecinos** pagando la suma: ¿sirve Huffman? Da un contraejemplo o una prueba. 🔴

---

## 🧩 Problemas propios

### Llenar el depósito

**Nivel:** 🟢 · **Formato:** programa completo.

Hay que comprar `L` litros de combustible. Cada proveedor vende hasta `stock` litros a `precio` por litro, y
se le puede comprar cualquier cantidad entera hasta su *stock*. Imprime el coste mínimo, o `-1` si entre
todos no llegan a `L` litros.

- **Entrada.** Una línea con `n` y `L`. Después, `n` líneas con `precio stock`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `0 ≤ L ≤ 10⁹`; `1 ≤ precio ≤ 10⁹`; `1 ≤ stock ≤ 10⁹`.

```text
Entrada     Salida
3 10        27
3 4
2 5
5 10

Entrada     Salida
2 10        -1
1 3
2 3
```

**Pista 1:** si te queda litro barato sin comprar y has comprado uno caro, ¿qué pasa si los cambias?

### Pedidos con plazo y cupo diario

**Nivel:** 🟡 · **Formato:** programa completo.

Un taller entrega hasta `c` pedidos por día, empezando el día 1. Cada pedido tiene un plazo (el último día
en que puede entregarse) y un pago si se entrega a tiempo. Imprime el pago máximo.

- **Entrada.** Una línea con `n` y `c`. Después, `n` líneas con `plazo pago`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ c ≤ 10⁵`; `1 ≤ plazo ≤ 10⁹`; `1 ≤ pago ≤ 10⁹`.

```text
Entrada     Salida
7 2         31
2 5
1 2
2 9
1 1
3 5
3 6
1 4

Entrada     Salida
3 1         7
1 3
1 7
1 2
```

**Pista 1:** ¿cuántos pedidos con plazo `≤ d` caben como mucho, y qué sueltas cuando te pasas?

### Mezclar de tres en tres

**Nivel:** 🟠 · **Formato:** programa completo.

Hay `n` ficheros con sus tamaños. La herramienta solo mezcla **exactamente tres** ficheros a la vez, con
coste igual a la suma de sus tamaños, y da uno con esa suma. Se pueden crear ficheros vacíos (tamaño 0) si
hace falta. ¿Cuál es el coste mínimo de dejarlos todos en uno?

- **Entrada.** Una línea con `n`. Una línea con los tamaños.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ tamaño ≤ 10⁹`.

```text
Entrada            Salida
5                  15
5 2 2 1 1

Entrada            Salida
4                  20
5 2 9 1

Entrada            Salida
2                  3
1 2
```

**Pista 1:** si cada mezcla quita dos ficheros de la cuenta, ¿con cuántos ficheros se puede acabar en uno, y
qué haces si no son tantos?

---

## 🧩 Práctica externa

Codility no tiene problemas de estos cuatro voraces fuera de los de `11/01`.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Jim and the Orders](https://www.hackerrank.com/challenges/jim-and-the-orders/problem) | HackerRank | 🟢 | Orden por la clave correcta | ¿Qué instante decide el orden de entrega de cada pedido? |
| [ ] | [Tree: Huffman Decoding](https://www.hackerrank.com/challenges/tree-huffman-decoding/problem) | HackerRank | 🟡 | El árbol de Huffman | ¿Qué te dice llegar a una hoja mientras lees los bits? |
| [ ] | [Reduce Array Size to The Half](https://leetcode.com/problems/reduce-array-size-to-the-half/) | LeetCode | 🟡 | Elección voraz por frecuencia | ¿Qué valor conviene borrar primero? |
| [ ] | [Minimum Deletions to Make Character Frequencies Unique](https://leetcode.com/problems/minimum-deletions-to-make-character-frequencies-unique/) | LeetCode | 🟡 | Voraz sobre frecuencias ordenadas | Si dos letras tienen la misma frecuencia, ¿a cuál le bajas y hasta dónde? |
| [ ] | [Minimum Number of Coins to be Added](https://leetcode.com/problems/minimum-number-of-coins-to-be-added/) | LeetCode | 🟡 | Monedas y alcance | Si puedes formar todo lo que hay en `[1, r]`, ¿qué moneda amplía más el alcance? |
| [ ] | [Furthest Building You Can Reach](https://leetcode.com/problems/furthest-building-you-can-reach/) | LeetCode | 🟡 | Voraz con arrepentimiento | Si te quedas sin ladrillos, ¿a qué subida le cambias los ladrillos por una escalera? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Maximum Subsequence Score](https://leetcode.com/problems/maximum-subsequence-score/) | LeetCode | 🟡 | Orden y montículo de los mejores `k` | Si fijas cuál es el mínimo de `nums2`, ¿qué elementos de `nums1` te conviene sumar? |
| [ ] | [Patching Array](https://leetcode.com/problems/patching-array/) | LeetCode | 🟠 | Monedas y alcance | Si alcanzas `[1, r)` y el siguiente número es mayor que `r`, ¿qué número añades? |
| [ ] | [Maximum Performance of a Team](https://leetcode.com/problems/maximum-performance-of-a-team/) | LeetCode | 🟠 | Orden por eficiencia y montículo | Fijada la eficiencia mínima del equipo, ¿qué velocidades conviene sumar? |

---

## ✅ Criterio de dominio

- Escribir la planificación con plazos y el coste de Huffman sin mirar, con el montículo de cada lenguaje.
- Esbozar la prueba de Huffman en dos pasos y la de la fraccionaria por intercambio.
- Dar los contraejemplos de la mochila 0/1 y de `{1, 3, 4}` y explicar qué detalle de la estructura rompen.
- Resolver Minimum Number of Coins to be Added y Furthest Building You Can Reach sin pista 2.

---

**Anterior:** [`11/02` — Intervalos](02-intervalos.md) · **Siguiente:** [`11/04` — Matroides y cómo romper un voraz](04-matroides-y-contraejemplos.md) ·
**Relacionado:** [`12/03` — Mochilas](../12-dp-clasica/03-mochilas.md); [`08/02` — Patrones con *heap*](../08-heaps-y-union-find/02-patrones-con-heap.md).
