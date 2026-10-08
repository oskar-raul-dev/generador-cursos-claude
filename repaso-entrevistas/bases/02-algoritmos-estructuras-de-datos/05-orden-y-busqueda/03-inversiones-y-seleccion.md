# 03 — Inversiones, selección y mediana

> Dos preguntas que parecen pedir ordenar y no lo necesitan del todo: cuántos pares están fuera de
> orden, en `O(n log n)` con la mezcla, y cuál es el `k`-ésimo menor, en `O(n)` esperado con
> *quickselect*. Más la mediana de medianas, que da la garantía lineal en el caso peor.
>
> **Niveles:** inversiones con la mezcla [A] · *quickselect* [A] · mediana de medianas [C].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), cap. 9; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997),
> cap. 7; Kleinberg y Tardos, *Algorithm Design* (Pearson, 2005), cap. 5 (inversiones).
>
> **Asume leído:** [`05/01` — Ordenación por comparación](01-ordenacion-por-comparacion.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--contar-inversiones-con-la-mezcla) · [4](#4--quickselect) · [5](#5--mediana-de-medianas) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Dos preguntas frecuentes sobre un arreglo:

- **¿Cuán desordenado está?** Una medida natural es el número de **inversiones**: pares `i < j` con
  `a[i] > a[j]`. Es cuántos intercambios de vecinos hacen falta para ordenarlo, y cuántos pares de
  dos rankings están en desacuerdo. Contarlos par a par es `Θ(n²)`: con `n = 2·10⁵`, `2·10¹⁰` pares.
- **¿Cuál es el `k`-ésimo menor?** La mediana, el percentil 90, los `k` más cercanos. Ordenar y mirar
  la posición `k` cuesta `Θ(n log n)`, y ordena mucho más de lo que hace falta.

Las dos se resuelven con piezas de `05/01`: la **mezcla** cuenta las inversiones de paso mientras
ordena, y la **partición** de *quicksort*, recursando en un solo lado, encuentra el `k`-ésimo sin
ordenar el resto.

---

## 2. 📐 La teoría

**Inversiones.** El número de inversiones `I` va de 0 (ordenado) a `n(n−1)/2` (al revés). Es el número
de desplazamientos de la inserción (`05/01`) y el mínimo número de **intercambios adyacentes** que
ordenan el arreglo: cada intercambio de dos vecinos fuera de orden quita exactamente una inversión.

**Inversiones en la mezcla.** Cada inversión `(i, j)` está o dentro de la mitad izquierda, o dentro de
la derecha, o **cruza**: `i` a la izquierda y `j` a la derecha. Las dos primeras las cuentan las
llamadas recursivas; las que cruzan se cuentan al mezclar: cuando se toma `R[j]` de la derecha, todos
los que **quedan** en la izquierda son mayores que él, y cada uno forma una inversión con `R[j]`.

**Selección.** El `k`-ésimo menor (estadístico de orden `k`) se encuentra particionando: si el pivote
cae en la posición `k`, es la respuesta; si cae a la derecha, la respuesta está a la izquierda, y al
revés. Solo se recursa en un lado.

**Teorema (coste esperado de *quickselect*).** Con pivote aleatorio, *quickselect* hace `O(n)`
comparaciones esperadas.

*Prueba*, en forma de cota. Llama **buena** a una partición si el pivote cae en el tramo central de la
mitad de los elementos (entre el cuartil 1 y el 3): ocurre con probabilidad `1/2`, y entonces el lado
en que se recursa tiene como mucho `3n/4` elementos. El número esperado de particiones hasta una buena
es 2, con coste `O(n)` cada una. Así, el trabajo esperado mientras el tamaño está entre `(3/4)^{t+1}·n`
y `(3/4)^t·n` es `O((3/4)^t·n)`, y la suma geométrica `Σ (3/4)^t · n` es `4n = O(n)`. CLRS, 3.ª ed.,
§9.2; Kleinberg y Tardos, §13.5.

Con pivote fijo, el caso peor es `Θ(n²)`, como el de *quicksort*: el pivote siempre en un extremo y
la recursión de `n − 1`.

---

## 3. 🧱 Contar inversiones con la mezcla

**Qué es.** La ordenación por mezcla de `05/01`, que además devuelve el número de inversiones.

**Por qué es correcto.** Por inducción sobre el tamaño. Las inversiones del total son las de la mitad
izquierda, más las de la derecha, más las que cruzan. Las dos primeras las da la hipótesis. Para las
que cruzan: al tomar `R[j]` durante la mezcla, los elementos `L[i..]` que quedan son exactamente los de
la izquierda mayores que `R[j]` —los menores o iguales ya salieron antes, porque la mezcla toma de la
izquierda en caso de empate—, y cada uno forma con `R[j]` una inversión que cruza. Cada inversión que
cruza se cuenta una sola vez: al salir su elemento derecho.

**Cómo va:**

```text
[5 2 9 1 5 6]
izquierda [5 2 9] → [2 5 9], 1 inversión (5, 2)
derecha   [1 5 6] → [1 5 6], 0 inversiones
mezcla [2 5 9] con [1 5 6]:
  sale 1 (der.): quedan 2, 5, 9 en la izquierda → +3
  sale 2, sale 5 (izq.; empate con 5: izquierda primero)
  sale 5 (der.): queda 9 → +1
  sale 6 (der.): queda 9 → +1
  sale 9
total 1 + 0 + 5 = 6
```

**Cuánto.** Lo mismo que la mezcla: `Θ(n log n)` y `Θ(n)` de memoria. El resultado puede llegar a
`n(n−1)/2 ≈ 2·10¹⁰` con `n = 2·10⁵`: necesita 64 bits.

**La plantilla:**

```cpp
#include <vector>

// Ordena a[lo, hi) por mezcla y devuelve sus inversiones. Θ(n log n). buf, del tamaño de a.
long long countInversions(std::vector<int>& a, std::vector<int>& buf, int lo, int hi) {
    if (hi - lo <= 1) return 0;
    int mid = lo + (hi - lo) / 2;
    long long inv = countInversions(a, buf, lo, mid) + countInversions(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) {
        if (a[j] < a[i]) { inv += mid - i; buf[k++] = a[j++]; }   // quedan mid − i mayores
        else buf[k++] = a[i++];
    }
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    for (k = lo; k < hi; k++) a[k] = buf[k];
    return inv;
}
```

```java
// Ordena a[lo, hi) por mezcla y devuelve sus inversiones. Θ(n log n). buf, del tamaño de a.
static long countInversions(int[] a, int[] buf, int lo, int hi) {
    if (hi - lo <= 1) return 0;
    int mid = lo + (hi - lo) / 2;
    long inv = countInversions(a, buf, lo, mid) + countInversions(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) {
        if (a[j] < a[i]) { inv += mid - i; buf[k++] = a[j++]; }
        else buf[k++] = a[i++];
    }
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    System.arraycopy(buf, lo, a, lo, hi - lo);
    return inv;
}
```

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

- **`inv += mid − i`** al tomar de la derecha: es el número de elementos que quedan en la izquierda.
- **`a[j] < a[i]` estricto**: los iguales no son inversión; con `<=`, se contarían.
- **`long long` / `long`**: el total puede pasar de `2³¹`. Python no tiene el problema.
- **La función ordena `a`**: si el arreglo original hace falta después, se pasa una copia.

**La alternativa con Fenwick.** Recorriendo de derecha a izquierda, se cuenta cuántos de los ya vistos
son menores que `a[i]` con un árbol de Fenwick sobre los valores comprimidos (`04/04`). También
`O(n log n)`, y además da el número **por elemento**; lo trata [`09/02`](../09-consultas-sobre-rangos/02-fenwick.md).

### De la versión ingenua a la buena

**El problema.** Dos críticos ordenan las mismas `n` películas. ¿En cuántos pares de películas no están
de acuerdo sobre cuál es mejor? Con el crítico A diciendo `a b c d e` y el B, `c a b e d`, hay 3 pares en
desacuerdo: (a, c), (b, c) y (d, e).

**La versión ingenua:**

```java
// O(n²): para cada par de películas, compara su orden en los dos rankings.
static long disagreements(int[] posA, int[] posB) {      // posX[p] = puesto de la película p
    int n = posA.length;
    long count = 0;
    for (int p = 0; p < n; p++)
        for (int q = p + 1; q < n; q++)
            if ((posA[p] < posA[q]) != (posB[p] < posB[q])) count++;
    return count;
}
```

> «Si renumero las películas por su puesto en A, el ranking de B se convierte en una permutación y
> cada par en desacuerdo es una inversión de esa permutación. Contarlas con la mezcla es `n log n`.»

**El camino a la buena.** Recorre B en orden y escribe, para cada película, su puesto en A: con el
ejemplo, `c a b e d` da `[2, 0, 1, 4, 3]`, que tiene 3 inversiones. Cuéntalas con la plantilla.

**Cuándo sí**: cuántos intercambios adyacentes ordenan; distancia entre rankings (la distancia de
Kendall tau); el coste de la inserción. **Cuándo no**: si se necesita el conteo por elemento o con
actualizaciones, Fenwick.

> **Veredicto:** las inversiones que cruzan las mitades se cuentan gratis mientras se mezcla: `n log n`
> en vez de `n²`, con el mismo código de la mezcla y una línea más.

---

## 4. 🧱 *Quickselect*

**Qué es.** La partición de *quicksort* con recursión en un solo lado: el que contiene la posición `k`.

**Por qué es correcto.** Tras partir, el pivote está en su posición final `q` del orden (todo lo de la
izquierda es menor o igual, todo lo de la derecha mayor o igual). Si `q = k`, es la respuesta; si
`k < q`, el `k`-ésimo está entre los de la izquierda, y si `k > q`, entre los de la derecha, con el mismo
índice `k` porque los índices son absolutos. El tramo se reduce en cada vuelta, así que termina.

**Cómo va**, buscando la posición `k = 3` (el cuarto menor) con Lomuto y el último como pivote, para
poder seguirlo a mano:

```text
[5 2 9 1 5 6]  rango [0, 5], pivote 6 → [5 2 1 5 | 6 | 9], pivote en 4; 3 < 4: izquierda
[5 2 1 5]      rango [0, 3], pivote 5 → [2 1 | 5 | 5], pivote en 2; 3 > 2: derecha
[5]            rango [3, 3], pivote 5 → en 3 = k
respuesta 5    (el orden completo es [1 2 5 5 6 9]; la posición 3 es 5)
```

**Cuánto.** `O(n)` esperado con pivote aleatorio (el teorema de §2); `Θ(n²)` en el caso peor. Memoria
`O(1)` con la versión iterativa.

**La plantilla**, iterativa, con pivote aleatorio y Hoare:

```cpp
#include <random>
#include <utility>
#include <vector>

std::mt19937 rng(20261004);

// Valor que ocuparía la posición k (0-indexada) si a estuviera ordenado. Reordena a. O(n) esperado.
int quickSelect(std::vector<int>& a, int k) {
    int lo = 0, hi = (int)a.size() - 1;
    while (lo < hi) {
        std::swap(a[lo], a[std::uniform_int_distribution<int>(lo, hi)(rng)]);   // pivote aleatorio en a[lo]
        int p = a[lo];
        int i = lo - 1, j = hi + 1;
        while (true) {
            do i++; while (a[i] < p);
            do j--; while (a[j] > p);
            if (i >= j) break;
            std::swap(a[i], a[j]);
        }
        if (k <= j) hi = j; else lo = j + 1;      // el corte de Hoare: [lo, j] y [j+1, hi]
    }
    return a[k];
}
```

```java
static final java.util.Random RNG = new java.util.Random(20261004);

// Valor que ocuparía la posición k (0-indexada) si a estuviera ordenado. Reordena a. O(n) esperado.
static int quickSelect(int[] a, int k) {
    int lo = 0, hi = a.length - 1;
    while (lo < hi) {
        int r = lo + RNG.nextInt(hi - lo + 1);
        int t0 = a[lo]; a[lo] = a[r]; a[r] = t0;        // pivote aleatorio en a[lo]
        int p = a[lo];
        int i = lo - 1, j = hi + 1;
        while (true) {
            do i++; while (a[i] < p);
            do j--; while (a[j] > p);
            if (i >= j) break;
            int t = a[i]; a[i] = a[j]; a[j] = t;
        }
        if (k <= j) hi = j; else lo = j + 1;
    }
    return a[k];
}
```

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

- **Con Hoare, el pivote no queda en su sitio**: por eso no se pregunta «¿`q = k`?», sino en qué lado
  del corte está `k`; el bucle acaba cuando el tramo tiene un elemento, que es la respuesta.
- **El pivote se lleva a `a[lo]`**, por la misma razón que en `05/01`: así el corte de Hoare cae en
  `[lo, hi − 1]` y el tramo siempre se reduce.
- **Iterativa**: sin recursión, memoria `O(1)` y sin límite de profundidad.
- **Reordena `a`**: tras la llamada, `a[k]` tiene el valor, a su izquierda los menores o iguales y a su
  derecha los mayores o iguales. Eso da los `k` menores **sin ordenar**.
- **El `k`-ésimo mayor** es la posición `n − k` del orden creciente.

**En la librería.** C++ tiene `std::nth_element(a.begin(), a.begin() + k, a.end())`, con la misma
garantía de reordenación y `O(n)` en promedio (libstdc++ usa *introselect*, con respaldo para el caso
peor). Java no tiene equivalente. Python tampoco: `heapq.nsmallest(k, a)` es `O(n log k)` y
`statistics.median` ordena.

### De la versión ingenua a la buena

**El problema.** Un servicio guarda las latencias del último minuto, `n = 10⁶` valores. Se pide el
percentil 90: el valor en la posición `⌊0,9 · (n − 1)⌋` del orden.

**La versión ingenua:**

```java
// Θ(n log n): ordena el millón entero para leer una posición.
static int percentile90(int[] latencies) {
    int[] copy = latencies.clone();
    java.util.Arrays.sort(copy);
    return copy[(int) (0.9 * (copy.length - 1))];
}
```

> «Solo necesito un valor en una posición, no el orden completo. Particionando y siguiendo solo el lado
> donde cae la posición, cada vuelta descarta en promedio una fracción fija del arreglo: lineal
> esperado.»

**El camino a la buena.** `quickSelect(copy, (int) (0.9 * (copy.length − 1)))` en lugar de ordenar. En
C++, `std::nth_element`.

**Cuándo sí**: un estadístico de orden, la mediana, los `k` menores sin orden. **Cuándo no**: si se
piden **muchas** posiciones distintas sobre los mismos datos, ordenar una vez sale más barato; si los
datos llegan en flujo, montículos ([`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md)).

> **Veredicto:** para el `k`-ésimo no hace falta ordenar: *quickselect* es lineal esperado. Su caso peor
> es cuadrático, como el de *quicksort*; la garantía lineal la da la mediana de medianas.

---

## 5. 🧱 Mediana de medianas

- **Qué resuelve.** Selección en `O(n)` **en el caso peor**, sin aleatoriedad.
- **Qué garantiza.** Elige un pivote que deja al menos unos `3n/10` elementos a cada lado: divide en
  grupos de 5, toma la mediana de cada grupo y, recursivamente, la mediana de esas `n/5` medianas. La
  recurrencia es `T(n) ≤ T(n/5) + T(7n/10 + 6) + O(n)`, y como `1/5 + 7/10 < 1`, `T(n) = O(n)`.
- **Cuánto.** `O(n)` caso peor, con una constante alta: en la práctica, más lento que *quickselect*
  aleatorio.
- **Cómo reconocerlo.** La pregunta teórica «¿se puede seleccionar en lineal en el caso peor?», o un
  entorno adversario donde la aleatoriedad no basta.
- **Si no te la sabes.** *Quickselect* aleatorio: `O(n)` esperado.
- **Dónde está entera.** CLRS, 3.ª ed., §9.3 (el algoritmo SELECT); el artículo original es Blum, Floyd,
  Pratt, Rivest y Tarjan, «Time Bounds for Selection», *Journal of Computer and System Sciences* 7(4),
  1973.

---

## 6. ⏱️ La tabla de costes

| Problema | Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|---|
| Contar inversiones | Mezcla | `Θ(n log n)` | `Θ(n)` | Resultado en 64 bits; ordena el arreglo |
| Contar inversiones | Fenwick sobre valores comprimidos | `Θ(n log n)` | `Θ(n)` | Da el conteo por elemento (`09/02`) |
| `k`-ésimo menor | *Quickselect* aleatorio | `O(n)` esperado, `Θ(n²)` peor | `O(1)` | Reordena el arreglo |
| `k`-ésimo menor | Mediana de medianas | `O(n)` peor | `O(log n)` | Constante alta |
| `k`-ésimo menor | Ordenar | `Θ(n log n)` | según el lenguaje | Compensa si se piden muchas posiciones |
| `k` menores en flujo | Montículo de tamaño `k` | `O(n log k)` | `O(k)` | Sin tener todos los datos a la vez (`08/01`) |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Mínimo de intercambios **adyacentes**» | Inversiones | Cada intercambio adyacente quita una |
| «Pares `i < j` con `a[i] > a[j]`» o una variante con una condición sobre los valores | Mezcla con conteo | Las parejas que cruzan se cuentan al mezclar |
| «Para cada elemento, cuántos menores hay después» | Fenwick (`09/02`) o mezcla con índices | El conteo es por elemento |
| «El `k`-ésimo mayor», «la mediana», «los `k` más cercanos» | *Quickselect* o `nth_element` | No hace falta el orden completo |
| «Minimizar la suma de distancias a un punto» | Mediana | La suma de `\|x − c\|` es mínima en la mediana |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Para el `k`-ésimo hay que ordenar» | *Quickselect* lo hace en `O(n)` esperado; ordenar es `n log n` |
| «*Quickselect* es `O(n)`» | En esperanza, con pivote aleatorio; el caso peor es `Θ(n²)` |
| «Las inversiones caben en un `int`» | Con `n = 2·10⁵`, hasta `2·10¹⁰`: hace falta `long long` / `long` |
| «Al mezclar, la inversión se suma al tomar de la izquierda» | Se suma al tomar de la **derecha**: los que quedan en la izquierda son los mayores |
| «Python tiene `nth_element`» | No: `heapq.nsmallest` es `O(n log k)` y `statistics.median` ordena |
| «La mediana de medianas es la forma práctica de seleccionar» | Es la garantía teórica; en la práctica, *quickselect* aleatorio o *introselect* |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  cap. 9: *quickselect* con su análisis y SELECT en lineal. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 7: selección y
  mediana dentro de divide y vencerás. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Pearson, 2005), §5.3: contar inversiones como
  ejemplo de divide y vencerás; §13.5, *quickselect* aleatorio. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*K-th order statistic in O(N)*](https://cp-algorithms.com/sequences/k-th.html).
- **Documentación** — cppreference, [`std::nth_element`](https://en.cppreference.com/cpp/algorithm/nth_element).

---

## 🧠 Preguntas

1. ¿Qué es una inversión, y cuántas tiene un arreglo ordenado al revés? 🟢
2. ¿Qué hace `std::nth_element`, y cómo queda el arreglo después? 🟢
3. ¿Por qué el número de inversiones es el mínimo de intercambios adyacentes que ordenan el arreglo? 🟡
4. Al contar inversiones con la mezcla, ¿cuándo se suma y cuánto? 🟡
5. ¿Por qué *quickselect* recursa en un solo lado y *quicksort* en los dos, y cómo cambia eso el coste? 🟡
6. ¿Qué pasa con el conteo de inversiones si cambias `a[j] < a[i]` por `a[j] <= a[i]`? 🟡
7. ¿Cuándo ordenar una vez es mejor que llamar a *quickselect* varias veces? 🟡
8. Demuestra que *quickselect* aleatorio hace `O(n)` comparaciones esperadas. 🟠
9. Compara cómo obtienes el `k`-ésimo menor en C++, Java y Python con la biblioteca estándar, y su coste. 🟠
10. ¿Por qué la mediana minimiza la suma de distancias `Σ |x − c|`? 🟠
11. En la mediana de medianas, ¿por qué grupos de 5 y no de 3? Justifica con la recurrencia. 🔴
12. Con todos los elementos iguales, ¿cuánto cuesta *quickselect* con Lomuto y con Hoare? Demuestra que con Hoare los cortes quedan equilibrados. 🔴
13. ¿Cómo encuentras la mediana de `10⁹` enteros que no caben en memoria, con varias pasadas sobre el disco? 🔴
14. ¿Cuántas inversiones cambian al intercambiar dos elementos adyacentes, y al intercambiar dos cualesquiera? Demuéstralo. 🔴

---

## 🧩 Problemas propios

### Intercambios adyacentes

**Nivel:** 🟡 · **Formato:** programa completo.

Imprime el mínimo número de intercambios de elementos vecinos que ordenan el arreglo de forma creciente.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ a[i] ≤ 10⁹`.

```text
Entrada            Salida
6                  6
5 2 9 1 5 6

Entrada            Salida
3                  3
3 2 1
```

**Pista 1:** ¿cuántos pares desordenados arregla un intercambio de vecinos?

### El peso del medio

**Nivel:** 🟢 · **Formato:** programa completo.

Imprime el valor que ocuparía la posición `⌊(n − 1)/2⌋` (0-indexada) si los pesos estuvieran ordenados.

- **Entrada.** Una línea con `n`. Una línea con los `n` pesos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `1 ≤ peso ≤ 10⁹`.

```text
Entrada            Salida
6                  5
5 2 9 1 5 6

Entrada            Salida
3                  2
3 1 2
```

**Pista 1:** ¿necesitas el orden completo para saber qué valor cae en una posición?

### Rotaciones de una permutación

**Nivel:** 🟠 · **Formato:** programa completo.

Una permutación de `1..n` se rota a la izquierda una posición cada vez (el primero pasa al final), `n`
veces. Imprime el menor número de inversiones entre las `n` rotaciones.

- **Entrada.** Una línea con `n`. Una línea con la permutación.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`.

```text
Entrada            Salida
4                  1
2 4 1 3

Entrada            Salida
4                  2
4 3 2 1
```

**Pista 1:** cuando el primero, de valor `x`, pasa al final, ¿qué inversiones desaparecen y cuáles
aparecen?

---

## 🧩 Práctica externa

> 💡 **Truco.** En los problemas de inversiones, el WA más común es el desbordamiento del contador. Antes
> de enviar, pide a una IA el caso de tamaño máximo ordenado al revés y comprueba que tu tipo aguanta
> `n(n−1)/2` ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Find the Median](https://www.hackerrank.com/challenges/find-the-median/problem) | HackerRank | 🟢 | Selección | ¿Qué posición ocupa la mediana con `n` impar? |
| [ ] | [Kth Largest Element in an Array](https://leetcode.com/problems/kth-largest-element-in-an-array/) | LeetCode | 🟡 | *Quickselect* | ¿Qué posición del orden creciente es el `k`-ésimo mayor? |
| [ ] | [K Closest Points to Origin](https://leetcode.com/problems/k-closest-points-to-origin/) | LeetCode | 🟡 | *Quickselect* por clave | ¿Hace falta devolverlos ordenados? |
| [ ] | [Minimum Moves to Equal Array Elements II](https://leetcode.com/problems/minimum-moves-to-equal-array-elements-ii/) | LeetCode | 🟡 | Mediana | ¿A qué valor conviene llevarlos a todos? |
| [ ] | [Global and Local Inversions](https://leetcode.com/problems/global-and-local-inversions/) | LeetCode | 🟡 | Inversiones con estructura | Toda inversión local es global: ¿qué tiene que no existir? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Stick Lengths](https://cses.fi/problemset/task/1074) | CSES | 🟢 | Mediana | ¿Qué valor minimiza la suma de distancias? |
| [ ] | [Wiggle Sort II](https://leetcode.com/problems/wiggle-sort-ii/) | LeetCode | 🟠 | Mediana y partición de tres vías | ¿Dónde tienen que ir los mayores que la mediana? |
| [ ] | [Insertion Sort Advanced Analysis](https://www.hackerrank.com/challenges/insertion-sort/problem) | HackerRank | 🟠 | Inversiones | ¿Qué cuenta la inserción en cada desplazamiento? |
| [ ] | [Reverse Pairs](https://leetcode.com/problems/reverse-pairs/) | LeetCode | 🔴 | Mezcla con conteo aparte | ¿Puedes contar los pares de las dos mitades antes de mezclarlas? |
| [ ] | [Count of Smaller Numbers After Self](https://leetcode.com/problems/count-of-smaller-numbers-after-self/) | LeetCode | 🔴 | Conteo por elemento | Al mezclar, ¿cómo sabes a qué elemento original sumar? |

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Count of Range Sum](https://leetcode.com/problems/count-of-range-sum/) | LeetCode | 🔴 | Prefijos y mezcla con conteo | Un tramo es una resta de dos prefijos: ¿qué pares de prefijos cuentas? |

---

## ✅ Criterio de dominio

- Escribir el conteo de inversiones con la mezcla y el *quickselect* iterativo sin mirar.
- Demostrar el coste esperado lineal de *quickselect* con el argumento de las particiones buenas.
- Decir qué ofrece cada biblioteca estándar para la selección y cuánto cuesta.
- Resolver Kth Largest Element y Reverse Pairs sin pista 2.

---

**Anterior:** [`05/02` — Ordenación lineal](02-ordenacion-lineal.md) · **Siguiente:** [`05/04` — Búsqueda binaria](04-busqueda-binaria.md) ·
**Relacionado:** [`09/02` — Fenwick](../09-consultas-sobre-rangos/02-fenwick.md); [`04/04` — Compresión de coordenadas y barrido](../04-secuencias/04-compresion-y-barrido.md).
