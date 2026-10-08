# 01 — Ordenación por comparación

> La ordenación por mezcla, *quicksort*, *heapsort* y la inserción, cada una con su invariante y su
> coste; la estabilidad; la cota inferior `Ω(n log n)` por árboles de decisión, y lo que usa de verdad
> cada librería.
>
> **Niveles:** ordenación por mezcla [A] · *quicksort* [A] · inserción [A] · estabilidad [A] ·
> *heapsort* [B] · TimSort e *introsort* [C].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), caps. 2 y 6–8; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall,
> 1997), caps. 7 y 12 (cota inferior); Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley,
> 2011), cap. 2.
>
> **Asume leído:** [`02/01` — Notación asintótica y casos](../02-analisis/01-notacion-asintotica.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--inserción-y-estabilidad) · [4](#4--ordenación-por-mezcla) · [5](#5--quicksort) · [6](#6--heapsort) · [7](#7--lo-que-usan-las-librerías) · [8](#8-️-la-tabla-de-costes) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Ordenar es la operación más usada del corpus: casi la mitad de los capítulos empiezan por «ordena y
después…». En la práctica se llama a la librería y ya está. Pero las preguntas de entrevista y los
WA de los jueces viven en lo que la llamada esconde:

- ¿Por qué *quicksort* es «`O(n log n)`» si con un caso preparado tarda `n²`?
- ¿Por qué ordenar por puntuación y después por nombre da un resultado distinto según el algoritmo?
- ¿Se puede ordenar más rápido que `n log n`? ¿Por qué no, o por qué sí?

Este capítulo responde las tres: los cuatro algoritmos que hay que poder escribir, con su invariante y
su recurrencia (`02/02`); la **estabilidad**, que decide la segunda; y la **cota inferior**, que dice que
ninguno que solo compare baja de `n log n` en el caso peor —y por qué los de [`05/02`](02-ordenacion-lineal.md) sí bajan sin
contradecirla.

---

## 2. 📐 La teoría

**El modelo de comparación.** Un algoritmo de ordenación **por comparación** solo obtiene información
de los datos comparando pares (`a[i] < a[j]`). Todo lo de este capítulo está en ese modelo; las
ordenaciones de `05/02` miran los dígitos de las claves y están fuera.

**Teorema (cota inferior).** Todo algoritmo de ordenación por comparación hace `Ω(n log n)`
comparaciones en el caso peor.

*Prueba.* La ejecución de un algoritmo determinista sobre `n` elementos distintos se describe con un
**árbol de decisión**: cada nodo interno es una comparación, cada rama un resultado, y cada hoja una
permutación de salida. Para ordenar bien todas las entradas, el árbol necesita al menos una hoja por
cada una de las `n!` permutaciones. Un árbol binario de altura `h` tiene como mucho `2ʰ` hojas, así que
`2ʰ ≥ n!` y `h ≥ log₂ n!`. Por la aproximación de Stirling, `log₂ n! = Θ(n log n)`; basta con
`n! ≥ (n/2)^{n/2}`, que da `log₂ n! ≥ (n/2) log₂(n/2)`. La altura es el número de comparaciones del
caso peor. CLRS, 3.ª ed., §8.1; Brassard y Bratley, cap. 12.

Con números: ordenar 10 elementos exige al menos `⌈log₂ 10!⌉ = 22` comparaciones en el caso peor, y
1000 elementos, al menos 8530.

**Estabilidad.** Una ordenación es **estable** si dos elementos con la misma clave quedan en el mismo
orden relativo que tenían en la entrada. Importa cuando se ordena por una clave y el orden previo
codifica otra: ordenar por nombre y después, de forma estable, por puntuación, deja los empates de
puntuación por orden alfabético.

**Los invariantes**, uno por algoritmo, que son los que se demuestran en cada sección:

```text
inserción    al empezar la vuelta j, a[0..j) contiene sus elementos originales, ordenados
mezcla       la mezcla de dos tramos ordenados produce su unión ordenada
quicksort    tras partir, todo lo de la izquierda del pivote es ≤ pivote ≤ todo lo de la derecha
heapsort     a[0..k) es un montículo de máximos y a[k..n) contiene los mayores, ordenados
```

---

## 3. 🧱 Inserción y estabilidad

**Qué es.** La ordenación por inserción toma cada elemento y lo inserta en su sitio dentro del prefijo
ya ordenado, desplazando a la derecha los mayores.

**Por qué es correcto.** Por el invariante de la tabla de §2; la prueba con sus tres partes está en
[`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md) (pregunta 11 de su solucionario). Es **estable** si se desplazan solo los **estrictamente**
mayores: un igual nunca salta por encima de otro igual.

**Cómo va**, sobre el arreglo de juguete:

```text
[5 | 2 9 1 5 6]   inserta 2 → [2 5 | 9 1 5 6]
[2 5 | 9 1 5 6]   inserta 9 → [2 5 9 | 1 5 6]
[2 5 9 | 1 5 6]   inserta 1 → [1 2 5 9 | 5 6]
[1 2 5 9 | 5 6]   inserta 5 → [1 2 5 5 9 | 6]    el segundo 5 queda detrás del primero: estable
[1 2 5 5 9 | 6]   inserta 6 → [1 2 5 5 6 9]
```

**Cuánto.** Caso peor (entrada al revés) `Θ(n²)`: el elemento `j` se desplaza `j` posiciones. Caso mejor
(ya ordenada) `Θ(n)`. Más exactamente, el número de desplazamientos es el **número de inversiones** de
la entrada ([`05/03`](03-inversiones-y-seleccion.md)): por eso es muy rápida con datos casi ordenados. Memoria `Θ(1)`.

**La plantilla:**

```cpp
#include <vector>

// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
void insertionSort(std::vector<int>& a) {
    for (std::size_t j = 1; j < a.size(); j++) {
        int key = a[j];
        std::size_t i = j;
        while (i > 0 && a[i - 1] > key) { a[i] = a[i - 1]; i--; }   // solo los estrictamente mayores
        a[i] = key;
    }
}
```

```java
// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
static void insertionSort(int[] a) {
    for (int j = 1; j < a.length; j++) {
        int key = a[j], i = j;
        while (i > 0 && a[i - 1] > key) { a[i] = a[i - 1]; i--; }
        a[i] = key;
    }
}
```

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

- **`a[i − 1] > key`, estricto**: con `>=` deja de ser estable.
- **C++**: `std::size_t` y la comprobación `i > 0` antes de leer `a[i − 1]`, porque `i − 1` con `i = 0`
  daría la vuelta en un tipo sin signo.

### De la versión ingenua a la buena

**El problema.** Mantener ordenada una lista a la que llegan elementos de uno en uno, casi siempre ya
en orden. Con `[1, 2, 5, 5, 6]` y llega 9, no hay nada que mover.

**La versión ingenua:**

```java
// Reordenar entera tras cada llegada: O(n log n) por elemento, O(n² log n) en total.
static void addAndSort(java.util.List<Integer> list, int x) {
    list.add(x);
    java.util.Collections.sort(list);
}
```

> «Reordenar todo en cada llegada ignora que la lista ya estaba ordenada. Insertando el nuevo en su
> sitio, cada llegada cuesta lo que se desplaza, y con datos casi ordenados eso es casi nada.»

**El camino a la buena.** Un paso de inserción por llegada: el bucle interno de la plantilla. Con datos
que llegan en orden, `O(1)` por elemento.

**Cuándo sí**: tramos pequeños (las librerías la usan por debajo de unos 16–32 elementos) y datos casi
ordenados. **Cuándo no**: datos arbitrarios grandes.

> **Veredicto:** inserción es cuadrática y aun así está dentro de todas las ordenaciones de librería:
> para tramos pequeños y casi ordenados no tiene rival.

---

## 4. 🧱 Ordenación por mezcla

**Qué es.** Divide el arreglo en dos mitades, ordena cada una recursivamente y **mezcla** las dos mitades
ordenadas con dos índices.

**Por qué es correcto.** Por inducción fuerte sobre el tamaño (`02/04`): el caso base (un elemento) está
ordenado; si las dos mitades lo están, la mezcla toma siempre el menor de las dos cabezas, con el
invariante «la salida contiene los menores de los ya vistos, en orden». Tomando de la **izquierda en
caso de empate**, es estable.

**Cómo va:**

```text
[5 2 9 1 5 6]
[5 2 9]            [1 5 6]
[5] [2 9]          [1] [5 6]
[5] [2] [9]        [1] [5] [6]
[5] [2 9]  →  [2 5 9]        [1] [5 6]  →  [1 5 6]
mezcla [2 5 9] y [1 5 6]: 1 · 2 · 5 (izq.) · 5 (der.) · 6 · 9  →  [1 2 5 5 6 9]
```

**Cuánto.** `T(n) = 2T(n/2) + Θ(n)`, caso 2 del teorema maestro: `Θ(n log n)` en el caso **peor**, mejor y
promedio (`02/02`). Memoria auxiliar `Θ(n)` para la mezcla, más `Θ(log n)` de pila.

**La plantilla:**

```cpp
#include <vector>

// Ordenación por mezcla de a[lo, hi), estable. Θ(n log n) caso peor, Θ(n) memoria auxiliar.
void mergeSort(std::vector<int>& a, std::vector<int>& buf, int lo, int hi) {
    if (hi - lo <= 1) return;
    int mid = lo + (hi - lo) / 2;
    mergeSort(a, buf, lo, mid);
    mergeSort(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) buf[k++] = (a[j] < a[i]) ? a[j++] : a[i++];   // empate: izquierda
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    for (k = lo; k < hi; k++) a[k] = buf[k];
}
```

```java
// Ordenación por mezcla de a[lo, hi), estable. Θ(n log n) caso peor, Θ(n) memoria auxiliar.
static void mergeSort(int[] a, int[] buf, int lo, int hi) {
    if (hi - lo <= 1) return;
    int mid = lo + (hi - lo) / 2;
    mergeSort(a, buf, lo, mid);
    mergeSort(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) buf[k++] = (a[j] < a[i]) ? a[j++] : a[i++];
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    System.arraycopy(buf, lo, a, lo, hi - lo);
}
```

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

- **`a[j] < a[i]` estricto** para tomar de la derecha: en empate se toma de la izquierda, y por eso es
  estable.
- **C++ y Java** reservan el búfer **una vez** fuera y lo pasan; reservar en cada llamada multiplica la
  constante. Se llama con `mergeSort(a, buf, 0, n)` y `buf` del mismo tamaño que `a`.
- **Python** crea listas nuevas en cada nivel: es la versión más clara y la más lenta; en un juez,
  `sorted` gana siempre.

### De la versión ingenua a la buena

**El problema.** Ordenar `n = 2·10⁵` registros. La versión ingenua es la inserción de §3: correcta,
estable y `2·10¹⁰` desplazamientos con la entrada al revés.

> «La inserción es cuadrática con datos desordenados. Si parto en mitades, ordeno cada una y las mezclo
> en lineal, la recurrencia es `2T(n/2) + n`: `n log n` en el caso peor, y sigue siendo estable.»

**El camino a la buena.** La plantilla de mezcla.

**Cuándo sí**: cuando hace falta `n log n` garantizado y estabilidad; listas enlazadas (la mezcla no
necesita acceso aleatorio ni búfer); ordenación externa. **Cuándo no**: con memoria muy justa, por el
búfer `Θ(n)`.

> **Veredicto:** la mezcla es la ordenación con garantías: `n log n` en el caso peor y estable. Su precio
> es la memoria auxiliar.

---

## 5. 🧱 *Quicksort*

**Qué es.** Elige un **pivote**, **parte** el arreglo en los menores (o iguales) y los mayores, y ordena
cada parte recursivamente. No necesita mezclar.

**Por qué es correcto.** Por inducción: tras partir, todo lo de la izquierda es `≤` que todo lo de la
derecha (el invariante de §2), así que ordenar cada parte por separado ordena el total. La partición de
**Lomuto** está escrita y demostrada en `02/04` (`partitionBelow`, con su invariante de dos zonas); la
de **Hoare**, con dos índices que se acercan desde los extremos, hace menos intercambios y se comporta
mejor con muchos iguales. *Quicksort* **no es estable**: la partición mueve elementos por encima de sus
iguales.

**Cómo va**, Lomuto con el último como pivote (6) sobre el arreglo de juguete:

```text
[5 2 9 1 5 6]    pivote 6, frontera i = 0
j=0: 5 < 6 → intercambia a[0] con a[0], i = 1
j=1: 2 < 6 → i = 2
j=2: 9       → nada
j=3: 1 < 6 → intercambia a[2] y a[3] → [5 2 1 9 5 6], i = 3
j=4: 5 < 6 → intercambia a[3] y a[4] → [5 2 1 5 9 6], i = 4
coloca el pivote en i: → [5 2 1 5 | 6 | 9]
```

**Cuánto.** Depende del pivote:

```text
caso peor        pivote siempre el mínimo o el máximo: T(n) = T(n−1) + Θ(n) = Θ(n²)
                 (pivote fijo el último y entrada ya ordenada)
caso promedio    sobre permutaciones uniformes: ~2n ln n ≈ 1,39 n log₂ n comparaciones, Θ(n log n)
esperado         con pivote aleatorio, Θ(n log n) para CUALQUIER entrada (02/01)
```

El análisis del promedio cuenta, para cada par de elementos, la probabilidad de que se comparen: los
elementos `i`-ésimo y `j`-ésimo del orden final se comparan si y solo si uno de los dos es el primer
pivote elegido entre los `j − i + 1` que hay entre ellos, con probabilidad `2 / (j − i + 1)`. Sumando,
`Σ 2/(j−i+1) ≈ 2n ln n`. CLRS, 3.ª ed., §7.4.

**La plantilla**, con pivote aleatorio y partición de Hoare:

```cpp
#include <random>
#include <utility>
#include <vector>

std::mt19937 rng(20261004);   // semilla fija para reproducir; en un juez con hacks, una del reloj

// Quicksort de a[lo, hi] (inclusivo) con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
void quickSort(std::vector<int>& a, int lo, int hi) {
    if (lo >= hi) return;
    std::swap(a[lo], a[std::uniform_int_distribution<int>(lo, hi)(rng)]);   // pivote aleatorio en a[lo]
    int p = a[lo];
    int i = lo - 1, j = hi + 1;
    while (true) {
        do i++; while (a[i] < p);
        do j--; while (a[j] > p);
        if (i >= j) break;
        std::swap(a[i], a[j]);
    }
    quickSort(a, lo, j);        // con Hoare, el corte es j: [lo, j] y [j+1, hi]
    quickSort(a, j + 1, hi);
}
```

```java
static final java.util.Random RNG = new java.util.Random(20261004);

// Quicksort de a[lo, hi] (inclusivo) con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
static void quickSort(int[] a, int lo, int hi) {
    if (lo >= hi) return;
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
    quickSort(a, lo, j);
    quickSort(a, j + 1, hi);
}
```

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

- **Con Hoare, el corte es `j`** y las llamadas son `[lo, j]` y `[j+1, hi]`; llamar con `j − 1` o
  dejar el pivote fuera, como en Lomuto, cuelga o pierde elementos.
- **Las comparaciones son estrictas** (`<` y `>`): los iguales al pivote paran los dos índices y se
  reparten entre las dos mitades, que es lo que evita el caso cuadrático con muchos repetidos.
- **El pivote aleatorio** convierte el caso promedio en caso esperado: ninguna entrada es mala.
- **El pivote se lleva a `a[lo]`**: con Hoare, si el pivote fuera el máximo y estuviera en `hi`, el corte
  caería en `hi` y la llamada se repetiría sin avanzar. Con el pivote en `lo`, el corte queda siempre en
  `[lo, hi − 1]`.
- **Python** tiene límite de recursión: con la recursión esperada `O(log n)` no se acerca, pero el caso
  desafortunado podría; en la práctica, `sorted`.

### De la versión ingenua a la buena

**El problema.** Ordenar con *quicksort* una entrada que un adversario ya ordenó.

**La versión ingenua:**

```java
// falla: TLE con entrada ordenada. Pivote fijo (el último) con Lomuto: particiones de 0 y n−1, Θ(n²).
static void quickSortLast(int[] a, int lo, int hi) {
    if (lo >= hi) return;
    int p = a[hi], i = lo;
    for (int j = lo; j < hi; j++)
        if (a[j] < p) { int t = a[i]; a[i] = a[j]; a[j] = t; i++; }
    int t = a[i]; a[i] = a[hi]; a[hi] = t;
    quickSortLast(a, lo, i - 1);
    quickSortLast(a, i + 1, hi);
}
```

> «Con el pivote siempre en el último y la entrada ya ordenada, cada partición deja un lado vacío: la
> recurrencia es `T(n−1) + n`, cuadrática, y además la recursión tiene profundidad `n`. Eligiendo el
> pivote al azar, ninguna entrada es mala y el coste esperado es `n log n`.»

**El camino a la buena.** La plantilla: pivote aleatorio y Hoare, que además resiste muchos repetidos.

**Cuándo sí**: ordenar en el sitio, rápido y sin búfer. **Cuándo no**: si hace falta estabilidad o
garantía de caso peor; ahí, mezcla o *introsort* (§7).

> **Veredicto:** *quicksort* es `n log n` esperado **con pivote aleatorio**, no siempre. El caso peor
> existe; la aleatoriedad hace que ningún adversario lo elija.

---

## 6. 🧱 *Heapsort*

**Qué es.** Construir un montículo de máximos sobre el arreglo ([`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md)) y sacar el máximo `n` veces,
colocándolo al final: `heapify` en `O(n)` y después `n − 1` intercambios de la raíz con el último,
bajando la nueva raíz. No es estable: los intercambios con la raíz saltan por encima de iguales.

**Por qué es correcto** (el enunciado y una frase): con el invariante de §2, cada extracción pone en su
sitio definitivo el mayor de los que quedan.

**Cuánto.** `Θ(n log n)` en el caso peor, `Θ(1)` de memoria extra. Con peor localidad de caché que
*quicksort* ([`02/05`](../02-analisis/05-el-coste-real.md)), y por eso más lento en la práctica.

**La plantilla**, en C++ con la librería y en Java a mano:

```cpp
#include <algorithm>
#include <vector>

void heapSort(std::vector<int>& a) {
    std::make_heap(a.begin(), a.end());   // montículo de máximos, O(n)
    std::sort_heap(a.begin(), a.end());   // n extracciones, O(n log n)
}
```

```java
// Heapsort en el sitio. Θ(n log n) caso peor, Θ(1) memoria. No estable.
static void heapSort(int[] a) {
    int n = a.length;
    for (int i = n / 2 - 1; i >= 0; i--) siftDown(a, i, n);           // heapify
    for (int end = n - 1; end > 0; end--) {
        int t = a[0]; a[0] = a[end]; a[end] = t;                        // el máximo, a su sitio
        siftDown(a, 0, end);
    }
}

static void siftDown(int[] a, int i, int n) {                           // montículo de máximos en a[0, n)
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] > a[c]) c++;
        if (a[i] >= a[c]) return;
        int t = a[i]; a[i] = a[c]; a[c] = t;
        i = c;
    }
}
```

**Cuándo sí**: cuando hace falta `n log n` garantizado **sin** memoria extra; es el respaldo de
*introsort*. **Cuándo no**: como ordenación general, donde *quicksort* es más rápido y la mezcla es
estable.

> **Veredicto:** *heapsort* es la garantía sin memoria. Rara vez se escribe; su papel es de red de
> seguridad dentro de la librería.

---

## 7. 🧱 Lo que usan las librerías

### TimSort

- **Qué resuelve.** Ordenar de forma estable y rápida datos reales, que suelen traer tramos ya
  ordenados.
- **Qué garantiza.** `O(n log n)` en el caso peor, estable, y `O(n)` con datos ya ordenados: detecta
  tramos crecientes (o decrecientes, que invierte), los extiende con inserción y los mezcla con reglas
  que mantienen la pila de tramos equilibrada.
- **Cuánto.** Memoria `O(n)` en el caso peor.
- **Cómo reconocerlo.** Es `sorted` y `list.sort` de Python, y `Arrays.sort` sobre objetos y
  `Collections.sort` de Java.
- **Si no te la sabes.** La ordenación por mezcla da las mismas garantías, sin la adaptación a los tramos.
- **Dónde está entera.** El documento de Tim Peters en el código de CPython,
  [`listsort.txt`](https://github.com/python/cpython/blob/3.12/Objects/listsort.txt).

### *Introsort*

- **Qué resuelve.** Tener la velocidad de *quicksort* sin su caso peor.
- **Qué garantiza.** `O(n log n)` en el caso peor: hace *quicksort* y, si la profundidad de recursión
  pasa de unos `2 log n`, cambia a *heapsort* en ese tramo; los tramos pequeños, con inserción.
- **Cuánto.** `O(log n)` de pila; no es estable.
- **Cómo reconocerlo.** Es el `std::sort` de libstdc++. El `Arrays.sort` de primitivos de Java 14 en
  adelante sigue la misma idea con su *quicksort* de doble pivote y un respaldo de *heapsort* ([`03/03`](../03-biblioteca-estandar/03-java-colecciones.md)).
- **Si no te la sabes.** *Quicksort* con pivote aleatorio da `n log n` esperado.
- **Dónde está entera.** Musser, «Introspective Sorting and Selection Algorithms», *Software: Practice
  and Experience* 27(8), 1997.

| Librería | Algoritmo | Estable |
|---|---|---|
| C++ `std::sort` | *Introsort* | No |
| C++ `std::stable_sort` | Mezcla | Sí |
| Java `Arrays.sort(int[])` | *Quicksort* de doble pivote con respaldo de *heapsort* (desde Java 14) | No (no importa con primitivos) |
| Java `Arrays.sort(Object[])`, `Collections.sort` | TimSort | Sí |
| Python `sorted`, `list.sort` | TimSort | Sí |

> 📝 **En JavaScript:** `Array.prototype.sort` es estable desde ES2019, pero **sin comparador ordena como
> texto**: `[10, 9, 1].sort()` da `[1, 10, 9]` ([`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)).

---

## 8. ⏱️ La tabla de costes

| Algoritmo | Peor | Promedio | Memoria | Estable | Lo que la tabla no dice |
|---|---|---|---|---|---|
| Inserción | `Θ(n²)` | `Θ(n²)` | `Θ(1)` | Sí | `Θ(n + inversiones)`: imbatible con datos casi ordenados |
| Mezcla | `Θ(n log n)` | `Θ(n log n)` | `Θ(n)` | Sí | La de las listas enlazadas y la ordenación externa |
| *Quicksort* | `Θ(n²)` | `Θ(n log n)` | `Θ(log n)` | No | Pivote aleatorio: esperado `n log n` para toda entrada |
| *Heapsort* | `Θ(n log n)` | `Θ(n log n)` | `Θ(1)` | No | Mala localidad; el respaldo de *introsort* |

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Ordena por A y, a igualdad, conserva el orden de entrada» | Ordenación estable | Es la definición de estabilidad |
| «Ordena una lista enlazada» | Mezcla | No necesita acceso aleatorio |
| Datos casi ordenados, «pocos fuera de sitio» | Inserción | Su coste es el de las inversiones |
| «Sin memoria extra» y caso peor garantizado | *Heapsort* | `n log n` en el sitio |
| «¿Se puede ordenar en menos de `n log n`?» | Cota inferior, o salir del modelo de comparación (`05/02`) | Árbol de decisión |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «*Quicksort* es `O(n log n)`» | Con pivote fijo, `Θ(n²)` en el caso peor; `n log n` en promedio, o esperado con pivote aleatorio |
| «Ordenar con comparador es estable» | Depende del algoritmo: `std::sort` no lo es; `std::stable_sort`, TimSort y la mezcla sí |
| «Ningún algoritmo baja de `n log n`» | Ninguno **por comparación**; *counting* y *radix* (`05/02`) sí, porque miran las claves |
| «La inserción es inútil» | Es la mejor con tramos pequeños y datos casi ordenados, y está dentro de las librerías |
| «Con Hoare, las llamadas son `[lo, j−1]` y `[j+1, hi]`» | Son `[lo, j]` y `[j+1, hi]`: Hoare no deja el pivote en su sitio |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  caps. 2 (inserción y mezcla), 6 (*heapsort*), 7 (*quicksort* y su análisis) y 8 (cota inferior).
  *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 7 (divide y
  vencerás) y cap. 12 (cotas inferiores). *Lectura troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), cap. 2: las ordenaciones
  en Java con mediciones. *Lectura troncal.*
- **Referencia** — Sedgewick y Wayne, [*Quicksort*](https://algs4.cs.princeton.edu/23quicksort/): la
  partición de tres vías para muchos iguales.
- **Documentación** — Python, [*Sorting Techniques*](https://docs.python.org/3/howto/sorting.html): la
  estabilidad y las claves.

---

## 🧠 Preguntas

1. ¿Qué es una ordenación estable? Da un algoritmo estable y otro que no lo sea. 🟢
2. ¿Cuánto cuesta la ordenación por mezcla en el caso peor y cuánta memoria usa? 🟢
3. ¿Qué algoritmo usan `std::sort`, `Arrays.sort` sobre objetos y `sorted` de Python? 🟢
4. ¿Qué diferencia hay entre el caso promedio de *quicksort* con pivote fijo y el caso esperado con pivote aleatorio? 🟡
5. ¿Qué diferencia hay entre las particiones de Lomuto y de Hoare, en intercambios y en lo que devuelven? 🟡
6. ¿Por qué el coste de la inserción depende del número de inversiones? 🟡
7. Demuestra la cota inferior `Ω(n log n)` con el árbol de decisión. 🟠
8. Compara la estabilidad de las ordenaciones de librería de C++, Java y Python, y qué haces en C++ si la necesitas. 🟠
9. ¿Por qué *quicksort* con Hoare usa comparaciones estrictas, y qué pasa con muchos valores repetidos si no? 🟠
10. ¿Por qué *heapsort* no es estable? Da un ejemplo de dos elementos iguales que cambian de orden. 🟠
11. Escribe el invariante de la mezcla y demuestra que tomar de la izquierda en caso de empate la hace estable. 🔴
12. Calcula el número esperado de comparaciones de *quicksort* aleatorio con el argumento de los pares, y di dónde aparece el `2 n ln n`. 🔴
13. Demuestra que un *quicksort* que toma como pivote la mediana exacta (calculada en lineal, `05/03`) es `Θ(n log n)` en el caso peor, y explica por qué las librerías no lo hacen. 🔴

---

## 🧩 Problemas propios

### Clasificación estable

**Nivel:** 🟢 · **Formato:** programa completo.

Hay `n` participantes con nombre y puntuación, en orden de inscripción. Imprime los nombres ordenados por
puntuación de mayor a menor; a igual puntuación, en orden de inscripción.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `nombre puntuación`.
- **Salida.** `n` nombres, uno por línea.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; nombres de 1 a 10 letras; `0 ≤ puntuación ≤ 10⁹`.

```text
Entrada            Salida
4                  luis
ana 5              ana
luis 9             carmen
carmen 5           pedro
pedro 1

Entrada            Salida
3                  zoe
zoe 0              ana
ana 0              bea
bea 0
```

**Pista 1:** si el algoritmo de ordenación de tu lenguaje no conserva el orden de los empates, ¿qué
información puedes añadir a cada registro?

### El adversario del pivote

**Nivel:** 🟠 · **Formato:** programa completo.

El *quicksort* ingenuo de §5 (pivote el último, Lomuto) se ejecuta sobre una permutación de `1..n`.
Imprime el número total de comparaciones `a[j] < p` que hace, sumando todas las llamadas.

- **Entrada.** Una línea con `n`. Una línea con la permutación.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2000`.

```text
Entrada            Salida
3                  3
1 2 3

Entrada            Salida
3                  2
1 3 2
```

**Pista 1:** con la entrada ya ordenada, ¿qué tamaños tienen las dos partes de cada partición?

---

## 🧩 Práctica externa

> 💡 **Truco.** En las entrevistas casi nunca se pide escribir una ordenación desde cero; se pide explicar
> qué hace la de la librería y elegir bien el comparador. Si te atascas con uno, pide a una IA que revise
> tu comparador, no que lo escriba ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Quicksort 1 - Partition](https://www.hackerrank.com/challenges/quicksort1/problem) | HackerRank | 🟢 | Partición | ¿Qué tres grupos pide el enunciado respecto del pivote? |
| [ ] | [Running Time of Algorithms](https://www.hackerrank.com/challenges/runningtime/problem) | HackerRank | 🟢 | Desplazamientos de la inserción | ¿Qué cuentas en cada desplazamiento? |
| [ ] | [Sort the People](https://leetcode.com/problems/sort-the-people/) | LeetCode | 🟢 | Ordenar por clave | ¿Qué ordenas: los nombres o los índices? |
| [ ] | [Distinct](https://app.codility.com/programmers/lessons/6-sorting/distinct/) | Codility | 🟢 | Ordenar y comparar vecinos | Tras ordenar, ¿dónde están los repetidos? |
| [ ] | [Largest Number](https://leetcode.com/problems/largest-number/) | LeetCode | 🟡 | Comparador propio | Para dos números, ¿qué concatenación es mejor, `ab` o `ba`? |
| [ ] | [Sort List](https://leetcode.com/problems/sort-list/) | LeetCode | 🟡 | Mezcla sobre una lista enlazada | ¿Cómo encuentras la mitad de una lista sin índices? |
| [ ] | [Insertion Sort List](https://leetcode.com/problems/insertion-sort-list/) | LeetCode | 🟡 | Inserción con un nodo centinela | ¿Dónde empiezas a buscar el sitio de cada nodo? |
| [ ] | [Custom Sort String](https://leetcode.com/problems/custom-sort-string/) | LeetCode | 🟡 | Clave de ordenación | ¿Qué número asignas a cada letra para que el orden dado mande? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Triangle](https://app.codility.com/programmers/lessons/6-sorting/triangle/) | Codility | 🟢 | Ordenar y vecinos | Si hay triángulo, ¿lo hay entre tres consecutivos tras ordenar? |
| [ ] | [Closest Numbers](https://www.hackerrank.com/challenges/closest-numbers/problem) | HackerRank | 🟢 | Ordenar y vecinos | ¿Entre qué pares puede estar la menor diferencia? |
| [ ] | [Lily's Homework](https://www.hackerrank.com/challenges/lilys-homework/problem) | HackerRank | 🟡 | Ciclos de la permutación | Cada intercambio coloca un elemento: ¿cuántos hacen falta por ciclo? |

---

## ✅ Criterio de dominio

- Escribir la mezcla y el *quicksort* aleatorio con Hoare sin mirar, con sus invariantes.
- Demostrar la cota inferior con el árbol de decisión.
- Decir qué ordenación usa cada librería, si es estable y qué garantiza.
- Resolver Largest Number y Sort List sin pista 2.

---

**Anterior:** — · **Siguiente:** [`05/02` — Ordenación lineal](02-ordenacion-lineal.md) ·
**Relacionado:** [`05/03` — Inversiones, selección y mediana](03-inversiones-y-seleccion.md); [`02/02` — Recurrencias y teorema maestro](../02-analisis/02-recurrencias-y-teorema-maestro.md).
