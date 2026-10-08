# 04 — *Meet in the middle*, IDDFS y *Dancing Links*

> Tres formas de llevar la búsqueda completa más lejos: partir un espacio de `2ⁿ` en dos mitades de
> `2^(n/2)` y cruzarlas (*meet in the middle*); buscar en profundidad con un límite que crece, con la
> memoria de un DFS y la optimalidad de un BFS (IDDFS); y reconocer el problema de cobertura exacta, que
> Knuth resuelve con *Dancing Links*.
>
> **Niveles:** *meet in the middle* [B] · IDDFS [B] · *Dancing Links* [C].
>
> **📚 Lectura troncal:** Knuth, *The Art of Computer Programming*, Vol. 4B (Addison-Wesley, 2022), §7.2.2
> (*Dancing Links*); Russell y Norvig, *Artificial Intelligence: A Modern Approach*, 4.ª ed. (Pearson,
> 2020), cap. 3 (IDDFS).
>
> **Asume leído:** [`10/03` — *Backtracking* con poda y ramificación y poda](03-backtracking-y-poda.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--meet-in-the-middle) · [4](#4--iddfs) · [5](#5--dancing-links-y-cobertura-exacta) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un enunciado da `n = 40` números y pregunta por el subconjunto cuya suma más se acerca a un objetivo sin
pasarse, con valores de hasta `10⁹`. La tabla de la mochila no cabe (el objetivo es enorme), y
`2⁴⁰ ≈ 1,1·10¹²` subconjuntos no caben en ningún límite de tiempo. Parece imposible, y el número 40 es
precisamente la pista de que no lo es: es el doble de 20, y `2²⁰ ≈ 10⁶` sí cabe.

**La idea:** partir los 40 números en dos mitades de 20. Todo subconjunto es la unión de un subconjunto de
la izquierda y uno de la derecha, y su suma es la suma de las dos. Se enumeran las `2²⁰` sumas de cada
mitad por separado, se ordena una, y para cada suma de la otra se busca en ella la mejor pareja con una
búsqueda binaria: `2 · 2²⁰` sumas y `2²⁰ · 20` comparaciones, unos `2·10⁷` pasos en lugar de `10¹²`.

```text
n = 40
todos los subconjuntos      2⁴⁰ ≈ 1,1·10¹²
dos mitades                 2 · 2²⁰ ≈ 2·10⁶ sumas, más ordenar y buscar ≈ 2·10⁷ pasos
```

El capítulo tiene además otras dos herramientas para cuando la búsqueda en profundidad de `10/03` se
queda corta: IDDFS, cuando hace falta la solución **más corta** y no hay memoria para un BFS, y la
cobertura exacta, un problema tan frecuente disfrazado (sudoku, pentominós, horarios) que tiene
estructura de datos propia.

---

## 2. 📐 La teoría

**Teorema (*meet in the middle*).** Si una solución se descompone en dos mitades independientes `(x, y)`
con `x ∈ X`, `y ∈ Y`, y la condición sobre la solución se puede consultar como «buscar en `Y` la pareja de
cada `x`» con una estructura ordenada o una tabla hash, entonces la búsqueda cuesta
`O(|X| log |Y| + |Y| log |Y|)` en lugar de `O(|X| · |Y|)`. Con `|X| = |Y| = 2^(n/2)`, se pasa de `2ⁿ` a
`O(2^(n/2) · n)`.

No es magia: se cambia tiempo por memoria (hay que guardar `2^(n/2)` valores) y exige que la condición
**se pueda partir**. «La suma total no pasa de `S`» se parte: fijado `x`, la mejor `y` es la mayor
`≤ S − x`. «El subconjunto no tiene dos elementos adyacentes» se parte solo si se tiene en cuenta la
frontera entre las mitades.

**Teorema (optimalidad de IDDFS).** Con coste unitario por arista, la búsqueda en profundidad iterativa
—DFS con límite de profundidad `L = 0, 1, 2, …` hasta encontrar una meta— encuentra una meta a la
**menor profundidad** posible, porque la iteración `L` visita todos los nodos a profundidad `≤ L` y la
primera iteración con éxito es la de la profundidad mínima `d`.

**Su sobrecoste está acotado.** Con factor de ramificación `b ≥ 2`, los nodos a profundidad `i` se generan
`d − i + 1` veces, y el total es

```text
Σ_{i=0..d} (d − i + 1) · bⁱ  ≤  bᵈ · (b / (b − 1))²
```

Con `b = 10`, repetir las iteraciones cuesta un 23 % más que un BFS; con `b = 2`, el factor es 4. La
memoria es la de un DFS: `O(b · d)` o `O(d)`, frente a los `O(bᵈ)` del BFS. Russell y Norvig, cap. 3,
tienen la cuenta entera.

**Cobertura exacta.** Dada una matriz de ceros y unos, elegir un subconjunto de filas tal que **cada
columna** tenga exactamente un 1 entre las filas elegidas. Es NP-completo; el algoritmo X de Knuth es un
*backtracking* que elige siempre la columna con menos opciones (MRV, como el sudoku de `10/03`).

---

## 3. 🧱 *Meet in the middle*

**Qué es.** Partir la búsqueda en dos mitades, enumerar cada una por separado y **combinarlas** con una
búsqueda o una tabla, en vez de enumerar el producto.

**Por qué es correcto.** Cada subconjunto de los `n` elementos es, de forma única, la unión de un
subconjunto de la izquierda y uno de la derecha (es la biyección de máscaras de [`10/02`](02-generar-subconjuntos-y-permutaciones.md) partida en dos). Si
para cada `x` de la izquierda se encuentra la mejor `y` de la derecha compatible, el máximo sobre `x` es el
máximo global.

**Cómo va**, la mayor suma `≤ 12` de un subconjunto de `[5, 2, 9, 1, 5, 6]`:

```text
izquierda [5, 2, 9] → sumas ordenadas: 0 2 5 7 9 11 14 16
derecha   [1, 5, 6] → sumas ordenadas: 0 1 5 6 6 7 11 12
para cada x de la izquierda con x ≤ 12, la mayor y ≤ 12 − x de la derecha:
x = 0 → y = 12 → 12        x = 5 → y = 7 → 12        x = 9  → y = 1 → 10
x = 2 → y = 7  → 9         x = 7 → y = 5 → 12        x = 11 → y = 1 → 12
mejor: 12
```

**Cuánto.** Enumerar cada mitad, `O(2^(n/2))` con las sumas incrementales de `10/02`; ordenar la derecha,
`O(2^(n/2) · n)`; una búsqueda binaria por cada `x`, `O(2^(n/2) · n)`. Total `O(2^(n/2) · n)` de tiempo y
`O(2^(n/2))` de memoria: con `n = 40`, dos arreglos de un millón de `long`, 16 MB.

**La plantilla**, la mayor suma de un subconjunto que no pasa de `S`:

```cpp
#include <algorithm>
#include <vector>

// Todas las sumas de subconjuntos de a[from..to), en un vector de 2^(to−from) posiciones.
std::vector<long long> halfSums(const std::vector<long long>& a, int from, int to) {
    int k = to - from;
    std::vector<long long> sums(1 << k, 0);
    for (int m = 1; m < (1 << k); m++)
        sums[m] = sums[m & (m - 1)] + a[from + __builtin_ctz(m)];
    return sums;
}

// Mayor suma de un subconjunto de a que no pasa de S (0 si solo el vacío). O(2^(n/2) · n). n ≤ ~44.
long long bestSumAtMost(const std::vector<long long>& a, long long S) {
    int n = (int)a.size(), mid = n / 2;
    std::vector<long long> left = halfSums(a, 0, mid), right = halfSums(a, mid, n);
    std::sort(right.begin(), right.end());
    long long best = 0;
    for (long long x : left) {
        if (x > S) continue;
        auto it = std::upper_bound(right.begin(), right.end(), S - x);   // primera > S − x
        best = std::max(best, x + *std::prev(it));                         // right[0] = 0 siempre cabe
    }
    return best;
}
```

```java
import java.util.Arrays;

// Todas las sumas de subconjuntos de a[from..to).
static long[] halfSums(long[] a, int from, int to) {
    int k = to - from;
    long[] sums = new long[1 << k];
    for (int m = 1; m < (1 << k); m++)
        sums[m] = sums[m & (m - 1)] + a[from + Integer.numberOfTrailingZeros(m)];
    return sums;
}

// Mayor suma de un subconjunto de a que no pasa de S (0 si solo el vacío). O(2^(n/2) · n).
static long bestSumAtMost(long[] a, long S) {
    int n = a.length, mid = n / 2;
    long[] left = halfSums(a, 0, mid), right = halfSums(a, mid, n);
    Arrays.sort(right);                                       // primitivos: sin boxing
    long best = 0;
    for (long x : left) {
        if (x > S) continue;
        int lo = 0, hi = right.length;                        // primer índice con right[i] > S − x
        while (lo < hi) { int m = (lo + hi) >>> 1; if (right[m] <= S - x) lo = m + 1; else hi = m; }
        best = Math.max(best, x + right[lo - 1]);             // lo ≥ 1 porque right[0] = 0
    }
    return best;
}
```

- **Pesos no negativos**: entonces `right[0] = 0` (el vacío) siempre cabe y `prev(it)` es válido. Con
  negativos, hay que comprobar que la búsqueda no devuelva el principio.
- **`1 << k` con `k ≤ 22`** cabe en `int`; las sumas, en 64 bits (20 valores de `10⁹`).
- **Ordenar solo una mitad** basta para buscar; ordenar las dos permite un recorrido con **dos punteros**
  ([`04/02`](../04-secuencias/02-dos-punteros-y-ventana.md)) en lugar de la binaria, que quita el `log` de la combinación.
- **Para contar** subconjuntos con suma exacta, se cuenta con `upper_bound − lower_bound`, o con un mapa
  hash de las sumas de la derecha; con XOR o igualdad, el mapa es lo natural.

**Cuándo sí**: `n` entre 30 y 45 con una condición que se parte en dos (sumas, XOR, productos), y valores
demasiado grandes para una DP. **Cuándo no**: con `n ≤ 20`, la enumeración directa; con valores pequeños,
la DP pseudopolinomial de [`12/03`](../12-dp-clasica/03-mochilas.md); y si la condición acopla los elementos de las dos mitades de forma que
no se puede consultar por separado.

> **Veredicto:** cuando `n` ronda 40, piensa en dos mitades de 20. Se paga con `2^(n/2)` de memoria y con
> tener que demostrar que la condición se parte.

---

## 4. 🧱 IDDFS

**Qué es.** La búsqueda en profundidad iterativa (*iterative deepening depth-first search*): un DFS con
límite de profundidad `L`, repetido con `L = 0, 1, 2, …` hasta que encuentra una meta. Se usa cuando hace
falta **la solución más corta** en un árbol de estados demasiado grande para guardar los visitados de un
BFS, o cuando la profundidad de la solución es pequeña y la ramificación grande.

**Por qué es correcto.** Por el teorema de §2: la iteración `L` explora todos los nodos a profundidad
`≤ L`, así que la primera que encuentra una meta lo hace a la profundidad mínima.

**Cómo va**, la cadena de sumas más corta para 15: una sucesión que empieza en 1 y en la que cada término
es la suma de dos anteriores (repetidos permitidos), hasta llegar a 15. Con cada límite `L` se buscan
cadenas de `L` sumas; se poda si ni doblando en cada paso se llega (`último · 2^(pasos que quedan) < 15`):

```text
L = 0..3 → 1 · 2ᴸ ≤ 8 < 15: la poda corta en la raíz
L = 4    → doblando se llega a 16, pero ninguna cadena de 4 sumas da 15
L = 5    → 1, 2, 4, 5, 10, 15          ✅ la más corta tiene 5 sumas
nodos visitados en la iteración que encuentra la cadena: 45
```

Un BFS sobre cadenas parciales tendría que guardar todos los prefijos de cada longitud; IDDFS solo guarda
la cadena actual.

**Cuánto.** `O(bᵈ)` nodos, con la constante `(b/(b − 1))²` de §2, y memoria `O(d)`. Con una buena poda por
cota (como la de doblar), es la misma idea que la ramificación y poda de [`10/03`](03-backtracking-y-poda.md), aplicada a la
profundidad. Con una heurística admisible en lugar de la profundidad pura, se llama IDA\* ([`15/03`](../15-grafos-pesos-y-flujos/03-a-estrella.md)).

**La plantilla**, el esqueleto genérico con un estado que se modifica y se deshace:

```cpp
#include <vector>

// IDDFS genérico: true si hay una meta a profundidad ≤ limit desde 'state'.
// isGoal, moves, apply, undo y lowerBound los define el problema.
template <class State, class Problem>
bool depthLimited(State& state, int depth, int limit, Problem& p) {
    if (p.isGoal(state)) return true;
    if (depth + p.lowerBound(state) > limit) return false;    // poda: no llega dentro del límite
    for (auto mv : p.moves(state)) {
        p.apply(state, mv);
        if (depthLimited(state, depth + 1, limit, p)) return true;   // el estado queda con la solución
        p.undo(state, mv);
    }
    return false;
}

template <class State, class Problem>
int iddfs(State& start, Problem& p, int maxDepth) {
    for (int limit = 0; limit <= maxDepth; limit++)
        if (depthLimited(start, 0, limit, p)) return limit;   // la primera es la más corta
    return -1;
}
```

```java
// IDDFS sobre un problema concreto: la cadena de sumas más corta hasta target.
static int[] chain = new int[64];

static boolean dfs(int len, int limit, int target) {
    int last = chain[len - 1];
    if (last == target) return true;
    if (len - 1 == limit) return false;
    if ((long) last << (limit - (len - 1)) < target) return false;   // ni doblando se llega
    for (int i = len - 1; i >= 0; i--)
        for (int j = i; j >= 0; j--) {
            int s = chain[i] + chain[j];
            if (s <= last || s > target) continue;                     // cadena creciente
            chain[len] = s;                                            // aplicar (se sobrescribe al volver)
            if (dfs(len + 1, limit, target)) return true;
        }
    return false;
}

static int shortestChain(int target) {
    chain[0] = 1;
    for (int limit = 0; ; limit++) if (dfs(1, limit, target)) return limit;
}
```

- **La poda por cota inferior** (`depth + lowerBound > limit`) es lo que hace útil a IDDFS: sin ella, cada
  iteración recorre el árbol entero hasta `L`.
- **Probar primero los movimientos prometedores** (en la cadena, las sumas mayores) encuentra antes la meta
  en la última iteración, que es la que más cuesta.
- **La memoria** es la pila de la recursión y el estado: `O(d)`. Por eso en Java el arreglo `chain` es
  único y se sobrescribe.
- **El estado repetido** no se detecta: un mismo estado alcanzado por dos caminos se explora dos veces. Si
  los estados se repiten mucho y caben en memoria, el BFS de [`14/02`](../14-grafos-recorridos/02-bfs.md) es mejor.

**Cuándo sí**: soluciones cortas (profundidad ≤ 15–20) en espacios enormes o infinitos, sin memoria para
los visitados; puzzles con «mínimo número de movimientos» y una buena cota inferior. **Cuándo no**: si los
estados caben en memoria y se repiten (BFS con visitados), o si los costes no son unitarios (Dijkstra o A\*,
bloque `15`).

> **Veredicto:** IDDFS es un BFS que no guarda nada, pagando con repetir las capas de arriba. Con una cota
> inferior que pode, es la forma de buscar la solución más corta cuando la memoria no alcanza.

---

## 5. 🧱 *Dancing Links* y cobertura exacta

### Algoritmo X con *Dancing Links*

**Qué resuelve.** La cobertura exacta: elegir filas de una matriz 0/1 de forma que cada columna quede
cubierta exactamente una vez. El sudoku, colocar pentominós en un tablero, el problema de las N reinas y
muchos horarios se traducen a cobertura exacta con una fila por decisión y una columna por restricción.

**Qué garantiza.** El algoritmo X es un *backtracking* correcto y completo: elige la columna con menos
unos (MRV), prueba cada fila que la cubre, elimina las columnas que esa fila cubre y las filas que chocan
con ella, y recurre. *Dancing Links* (DLX) es la estructura que hace barato el «eliminar» y el
«restaurar»: listas doblemente enlazadas circulares en las que un nodo quitado se vuelve a poner con dos
asignaciones (`x.left.right = x; x.right.left = x`), porque conserva sus propios punteros.

**Cuánto.** Exponencial en el caso peor (el problema es NP-completo), pero cada paso de eliminar y
restaurar cuesta proporcional a los unos tocados, no al tamaño de la matriz. Un sudoku de 9 × 9 son 729
filas y 324 columnas, y DLX lo resuelve en milisegundos.

**Cómo reconocerlo.** «Cada casilla / restricción exactamente una vez», «llenar el tablero sin solaparse»,
«cada fila, columna y caja con cada número una vez». Si cada decisión cubre un conjunto fijo de
restricciones y cada restricción debe cubrirse una sola vez, es cobertura exacta.

**Si no te la sabes.** El *backtracking* con marcas y MRV de `10/03` es el algoritmo X sin la estructura de
listas: resuelve los sudokus de los jueces habituales y la mayoría de los rompecabezas de concurso.

**Dónde está entera.** Knuth, *The Art of Computer Programming*, Vol. 4B, §7.2.2.1, y su artículo
«Dancing Links» (2000).

---

## 6. ⏱️ La tabla de costes

| Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Enumeración directa | `O(2ⁿ)` | `O(1)` o `O(2ⁿ)` | Cabe hasta `n ≈ 20–25` |
| *Meet in the middle* | `O(2^(n/2) · n)` | `O(2^(n/2))` | Exige que la condición se parta; `n ≈ 40–45` |
| BFS por niveles | `O(bᵈ)` | `O(bᵈ)` | Detecta estados repetidos; la memoria es su límite |
| IDDFS | `O(bᵈ)`, constante `(b/(b − 1))²` | `O(d)` | No detecta repetidos; una cota inferior lo hace práctico |
| Algoritmo X con DLX | Exponencial | Proporcional a los unos | Muy rápido en la práctica; el *backtracking* con MRV basta casi siempre |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| `n ≤ 40` (o 36, 44), valores hasta `10⁹` o `10¹⁸` | *Meet in the middle* | `2²⁰` cabe; `2⁴⁰` no; la DP no por los valores |
| «Repartir en dos grupos» con `n ≤ 30` y tamaños iguales | *Meet in the middle* por tamaño | Se agrupan las sumas de cada mitad por cuántos elementos usan |
| «Mínimo número de movimientos», respuesta pequeña, estados enormes | IDDFS (o IDA\*) | Profundidad baja, sin memoria para BFS |
| «Cada X exactamente una vez», tableros que se llenan sin solaparse | Cobertura exacta | Algoritmo X, o *backtracking* con MRV |
| Dos extremos conocidos (estado inicial y final) | BFS bidireccional | Es *meet in the middle* sobre caminos: `2 · b^(d/2)` en lugar de `bᵈ` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`n = 40` es imposible» | `2^(n/2) = 2²⁰`: con dos mitades, unos `2·10⁷` pasos |
| «*Meet in the middle* sirve para cualquier búsqueda» | Solo si la condición se consulta por mitades; si acopla los dos lados, no |
| «IDDFS desperdicia trabajo repitiendo capas» | Repite un factor `(b/(b − 1))²`, pequeño con `b ≥ 3`, a cambio de memoria `O(d)` |
| «IDDFS encuentra el camino de menor coste» | El de menos aristas; con costes distintos hace falta Dijkstra o A\* |
| «DLX es un algoritmo polinomial para el sudoku» | Es *backtracking*; la cobertura exacta es NP-completa |
| «En *meet in the middle* hay que ordenar las dos mitades» | Basta una para buscar; las dos, para recorrerlas con dos punteros |

---

## 📚 Para profundizar

- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 4B (Addison-Wesley, 2022), §7.2.2.1:
  *Dancing Links* y el algoritmo X. *Lectura troncal.*
- **Libro** — Russell y Norvig, *Artificial Intelligence: A Modern Approach*, 4.ª ed. (Pearson, 2020),
  cap. 3: búsqueda iterativa en profundidad, IDA\* y búsqueda bidireccional. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 9: exploración
  de grafos implícitos.
- **Referencia** — USACO Guide, [*Meet In The Middle*](https://usaco.guide/gold/meet-in-the-middle).
- **Referencia** — Russell y Norvig, [pseudocódigo de AIMA](https://aima.cs.berkeley.edu/algorithms.pdf):
  `ITERATIVE-DEEPENING-SEARCH`.

---

## 🧠 Preguntas

1. ¿Cuántos pasos cuesta *meet in the middle* con `n = 40`, y cuánta memoria? 🟢
2. ¿Qué garantiza IDDFS con coste unitario, y cuánta memoria usa? 🟢
3. ¿Qué es la cobertura exacta, y cómo se escribe un sudoku como cobertura exacta? 🟢
4. ¿Qué condición tiene que cumplir un problema para poder partirlo en dos mitades? Da uno que se parta y uno que no. 🟡
5. ¿En qué se diferencian IDDFS y BFS en tiempo, memoria y estados repetidos? 🟡
6. ¿Qué hace barato el «restaurar» en *Dancing Links*? 🟡
7. ¿Por qué buscar con dos punteros sobre las dos mitades ordenadas quita el `log` de la combinación? 🟠
8. ¿Cómo cuentas los subconjuntos con suma exacta `S` con *meet in the middle*, y qué cambia en C++, Java y Python? 🟠
9. Deriva el sobrecoste de IDDFS frente a BFS para un factor de ramificación `b`. 🟠
10. ¿Por qué la poda «ni doblando se llega» de la cadena de sumas es una cota inferior válida? 🟠
11. ¿Qué tiene en común el BFS bidireccional con *meet in the middle*, y cuánto ahorra? 🟠
12. Repartir 30 números en dos grupos de 15 con sumas lo más parecidas posible: diseña la solución y di su coste. 🔴
13. Tu *meet in the middle* da una respuesta mayor que la de la fuerza bruta en entradas con negativos. ¿Qué pasa? 🔴

---

## 🧩 Problemas propios

### Balanza de pesas

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` pesas. Cada una se pone en el platillo izquierdo, en el derecho o se deja fuera. ¿De cuántas formas
la diferencia (izquierdo menos derecho) es exactamente `D`?

- **Entrada.** Una línea con `n` y `D`. Una línea con los `n` pesos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 24`; `1 ≤ peso ≤ 10⁸`; `|D| ≤ 3·10⁹`.

```text
Entrada        Salida
3 0            3
1 2 3

Entrada        Salida
4 3            4
5 2 9 1

Entrada        Salida
1 5            0
4
```

**Pista 1:** con 24 pesas y tres opciones cada una, ¿cuántas configuraciones hay, y cuántas en cada
mitad?

### Subconjuntos con XOR dado

**Nivel:** 🟠 · **Formato:** programa completo.

¿Cuántos subconjuntos de `n` enteros (contando el vacío, cuyo XOR es 0) tienen XOR exactamente `x`?

- **Entrada.** Una línea con `n` y `x`. Una línea con los `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 40`; `0 ≤ aᵢ, x < 2³⁰`.

```text
Entrada            Salida
6 12               4
5 2 9 1 5 6

Entrada            Salida
2 0                2
1 1
```

**Pista 1:** si conoces el XOR `l` de la parte izquierda de un subconjunto, ¿qué XOR tiene que tener la
parte derecha?

### Tortitas

**Nivel:** 🟡 · **Formato:** programa completo.

Una pila de `n` tortitas de distintos tamaños (puede haber tamaños repetidos) se ordena con una espátula:
cada volteo invierte las `k` tortitas de arriba (`2 ≤ k ≤ n`). ¿Cuál es el menor número de volteos que deja
la pila ordenada de menor a mayor de arriba abajo? La pila se da de arriba abajo.

- **Entrada.** Una línea con `n`. Una línea con los tamaños.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 8`; tamaños entre 1 y 100.

```text
Entrada            Salida
3                  2
3 1 2

Entrada            Salida
6                  4
5 2 9 1 5 6

Entrada            Salida
3                  0
1 2 3
```

**Pista 1:** ¿cuántos estados distintos puede tener la pila, y qué búsqueda devuelve el camino más corto?

---

## 🧩 Práctica externa

Las tres bases apenas llegan aquí: LeetCode tiene *meet in the middle* en dificultad alta, HackerRank y
Codility no lo tienen. El núcleo se completa con CSES.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Meet in the Middle](https://cses.fi/problemset/task/1628) | CSES | 🟡 | Contar sumas exactas en dos mitades | Con `n = 40`, ¿cuántas sumas tiene cada mitad? |
| [ ] | [Closest Subsequence Sum](https://leetcode.com/problems/closest-subsequence-sum/) | LeetCode | 🟠 | Mitades ordenadas y búsqueda | Fijada la suma de la izquierda, ¿qué suma de la derecha te acerca más al objetivo? |
| [ ] | [Partition Array Into Two Arrays to Minimize Sum Difference](https://leetcode.com/problems/partition-array-into-two-arrays-to-minimize-sum-difference/) | LeetCode | 🟠 | Mitades agrupadas por tamaño | Si la izquierda aporta `k` números al primer grupo, ¿cuántos tiene que aportar la derecha? |
| [ ] | [Sliding Puzzle](https://leetcode.com/problems/sliding-puzzle/) | LeetCode | 🟠 | Mínimo número de movimientos | ¿Cuántos estados distintos tiene un tablero de 2 × 3? |
| [ ] | [Split Array With Same Average](https://leetcode.com/problems/split-array-with-same-average/) | LeetCode | 🔴 | Mitades por tamaño y suma | Si una parte tiene `k` elementos y la media global, ¿cuánto suma? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Maximum Subsequence](https://codeforces.com/problemset/problem/888/E) | Codeforces | 🟠 | Mitades con sumas módulo `m` | Fijado el resto de la izquierda, ¿qué resto de la derecha conviene, y hay solo dos candidatos? |
| [ ] | [Knights in Fen](https://open.kattis.com/problems/knightsfen) | Kattis | 🟠 | Mínimo de movimientos con límite 10 | Si la respuesta es como mucho 10, ¿cuántos estados ves desde cada extremo con 5 movimientos? |
| [ ] | [Xor-Paths](https://codeforces.com/problemset/problem/1006/F) | Codeforces | 🔴 | *Meet in the middle* sobre caminos | ¿Dónde se cruzan a mitad de camino los caminos de una esquina a otra? |
| [ ] | [Anya and Cubes](https://codeforces.com/problemset/problem/525/E) | Codeforces | 🔴 | Mitades con tres opciones por elemento | ¿Qué factoriales tiene sentido calcular si `S ≤ 10¹⁶`? |

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Sudokunique](https://open.kattis.com/problems/sudokunique) | Kattis | 🟠 | Cobertura exacta | ¿Cómo sabes que la solución es única sin enumerar todas? |

SPOJ tiene problemas clásicos de *Dancing Links* y de *meet in the middle*, pero responde `403` a la
verificación automática y no se enlaza.

---

## ✅ Criterio de dominio

- Escribir *meet in the middle* para «la mayor suma `≤ S`» sin mirar la plantilla, en menos de quince
  minutos.
- Decir, ante un `n ≤ 40`, si la condición se parte en dos mitades y cómo se combinan.
- Explicar la optimalidad de IDDFS y su sobrecoste frente a BFS.
- Traducir un sudoku a cobertura exacta: qué son las filas y qué las columnas.
- Resolver Meet in the Middle y Closest Subsequence Sum sin pista 2.

---

**Anterior:** [`10/03` — *Backtracking* con poda y ramificación y poda](03-backtracking-y-poda.md) · **Siguiente:**
[`10/05` — Divide y vencerás](05-divide-y-venceras.md) · **Relacionado:** [`15/03` — A\* y heurísticas admisibles](../15-grafos-pesos-y-flujos/03-a-estrella.md); [`14/02` — BFS](../14-grafos-recorridos/02-bfs.md).
