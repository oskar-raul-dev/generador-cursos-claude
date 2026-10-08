# 02 — C++: algoritmos, *ranges* y `ordered_set`

> Usar `<algorithm>` y `<numeric>` en vez de reescribirlos: ordenar con un comparador correcto, buscar
> en un rango ordenado, generar permutaciones, seleccionar el `k`-ésimo y acumular sin desbordar. Y
> lo que añaden `std::ranges` y el `ordered_set` de las estructuras basadas en políticas de GCC.
>
> **Niveles:** `sort`, `lower_bound`, `next_permutation`, `nth_element`, `accumulate`, `partial_sum`
> [A] · `std::ranges` [B] · `ordered_set` de PBDS [B].
>
> **📚 Lectura troncal:** Farrier, *Data Structures and Algorithms with the C++ STL* (Packt, 2024),
> caps. 11–15; cppreference; la documentación de GCC sobre las estructuras basadas en políticas.
>
> **Asume leído:** [`03/01` — C++: contenedores de la STL](01-cpp-contenedores.md).
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [1](#1--el-problema) · [2](#2--sort-y-el-comparador) · [3](#3--la-búsqueda-binaria-de-la-librería) · [4](#4--next_permutation) · [5](#5--nth_element-y-partial_sort) · [6](#6--los-numéricos) · [7](#7--stdranges) · [8](#8--ordered_set-de-pbds) · [9](#9-️-la-tabla-de-costes) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Ordenar por puntuación de mayor a menor, y a igualdad, como sea. Se escribe con una lambda:

```cpp
// falla: comportamiento indefinido; con muchos empates puede leer fuera del arreglo
std::sort(scores.begin(), scores.end(), [](int a, int b) { return a >= b; });
```

Con los ejemplos funciona. Con un caso de `10⁵` puntuaciones donde muchas son iguales, el programa
puede dar *Runtime Error* (RE) o una ordenación incorrecta, según la implementación. El motivo es que
`std::sort` exige que el comparador sea un **orden estricto débil**, y `>=` no lo es: dice que `a`
va antes que `a`. La implementación de libstdc++ confía en esa propiedad para no comprobar los límites
del arreglo en su bucle interno, y con `>=` se sale.

`<algorithm>` y `<numeric>` traen hechas, probadas y rápidas casi todas las operaciones sobre rangos
que un problema necesita. Pero cada una tiene un **contrato**: qué exige de los datos y del
comparador, y qué garantiza. Este capítulo recorre las que se usan en competitiva con su contrato y su
coste, y termina con dos extensiones: los *ranges* de C++20 y el `ordered_set` de GCC.

---

## 2. 🧱 `sort` y el comparador

**Qué es.** `std::sort` ordena un rango de acceso aleatorio en `O(n log n)` en el caso peor; es un
*introsort*: *quicksort* que cambia a *heapsort* si la recursión se hace demasiado profunda, y a
inserción en los tramos pequeños. `std::stable_sort` conserva el orden relativo de los iguales.

**Cómo va.**

```cpp
#include <algorithm>
#include <functional>
#include <utility>
#include <vector>

std::vector<int> a = {5, 2, 9, 1, 5, 6};
std::sort(a.begin(), a.end());                       // 1 2 5 5 6 9
std::sort(a.begin(), a.end(), std::greater<>());     // 9 6 5 5 2 1

std::vector<std::pair<int, int>> byEnd = {{1, 4}, {3, 5}, {0, 6}};
std::sort(byEnd.begin(), byEnd.end(),
          [](const auto& p, const auto& q) { return p.second < q.second; });   // por final

std::stable_sort(a.begin(), a.end());                // mismo orden, y los iguales no se cruzan
```

- **Los pares y las tuplas** se comparan lexicográficamente con su `<`: ordenar pares sin comparador
  ordena por el primero y desempata por el segundo.
- **El comparador recibe por referencia constante** (`const auto&`): copiar dos objetos en cada
  comparación multiplica el coste con tipos grandes.

**El contrato del comparador.** `comp(a, b)` tiene que definir un **orden estricto débil**:

```text
irreflexivo     comp(a, a) es falso                         (por eso <= y >= no valen)
asimétrico      si comp(a, b), entonces no comp(b, a)
transitivo      si comp(a, b) y comp(b, c), entonces comp(a, c)
equivalencia    «ni comp(a, b) ni comp(b, a)» también es transitiva
```

Un comparador que viole cualquiera de las cuatro produce **comportamiento indefinido**: ordenaciones
incorrectas, bucles que se salen del arreglo o, en un `set`, elementos que no se encuentran. El caso
más frecuente es usar `<=`; el segundo, comparar `double` con tolerancia, que rompe la transitividad
de la equivalencia.

**Cuánto cuesta.** `sort`: `O(n log n)` en el caso peor, sin memoria extra. `stable_sort`: `O(n log n)`
con memoria auxiliar `O(n)` (si no la consigue, `O(n log² n)`).

**Cuándo sí**: siempre que haya que ordenar. **Cuándo no**: si solo necesitas el `k`-ésimo (§5) o los
`k` menores; ahí hay algo más barato.

> **Veredicto:** `sort` con `<` o con una lambda que se comporte como `<`, nunca como `<=`. Y
> `stable_sort` solo si el orden de los empates importa.

---

## 3. 🧱 La búsqueda binaria de la librería

**Qué es.** Cuatro funciones sobre un rango **ordenado con el mismo criterio** con que se busca:

| Función | Devuelve | Para qué |
|---|---|---|
| `lower_bound(first, last, x)` | el primero `≥ x` | Posición de inserción; primera aparición |
| `upper_bound(first, last, x)` | el primero `> x` | Final de las apariciones |
| `equal_range(first, last, x)` | el par de los dos anteriores | Todas las apariciones de `x` |
| `binary_search(first, last, x)` | `bool` | Solo si está; no dice dónde |

**Cómo va**, sobre `[1, 2, 5, 5, 6, 9]`:

```cpp
std::vector<int> v = {1, 2, 5, 5, 6, 9};
auto lo = std::lower_bound(v.begin(), v.end(), 5);     // apunta a v[2]
auto hi = std::upper_bound(v.begin(), v.end(), 5);     // apunta a v[4]
long long howMany = hi - lo;                           // 2 apariciones de 5
long long countBelow7 = std::lower_bound(v.begin(), v.end(), 7) - v.begin();   // 5 valores < 7
```

- **Contar en un rango** `[L, R]` es `upper_bound(R) − lower_bound(L)`.
- **Con un comparador propio**, hay que pasar el mismo con que se ordenó: buscar con `<` en un rango
  ordenado con `>` es comportamiento indefinido.
- **Sobre un `set`**, el miembro (`03/01`); estas funciones son para rangos de acceso aleatorio.

**Cuánto cuesta.** `O(log n)` comparaciones con iteradores de acceso aleatorio. El invariante que las
sostiene está en [`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md), y la búsqueda binaria sobre la respuesta, en [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md).

**Cuándo sí**: con un `vector` ordenado que no cambia. **Cuándo no**: si el rango se modifica entre
consultas; entonces, un `set`.

> **Veredicto:** `lower_bound` y `upper_bound` resuelven «cuántos hay» y «dónde iría» en una línea. No
> escribas tu propia búsqueda binaria si una de estas cuatro es el contrato.

---

## 4. 🧱 `next_permutation`

**Qué es.** Transforma el rango en la **siguiente permutación en orden lexicográfico** y devuelve
`true`; si ya era la última, lo deja en la primera (ordenado) y devuelve `false`.

**Cómo va.** Para enumerar todas, se empieza **ordenado**:

```cpp
#include <algorithm>
#include <string>

std::string s = "aab";
std::sort(s.begin(), s.end());            // imprescindible: empezar por la primera
do {
    // usar s: "aab", "aba", "baa"
} while (std::next_permutation(s.begin(), s.end()));
```

- **Con repetidos**, cada permutación **distinta** sale una sola vez: `"aab"` da 3, no 6.
- **Sin ordenar antes**, solo se recorren las permutaciones posteriores a la inicial.

**Cuánto cuesta.** Cada llamada es `O(n)` en el caso peor y `O(1)` amortizada sobre todas; recorrer las
`n!` permutaciones cuesta `O(n! · n)` si cada una se procesa en `O(n)`. Con `n ≤ 10`, unos `3,6·10⁷`.

**Cuándo sí**: fuerza bruta sobre órdenes con `n ≤ 10` ([`10/02`](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md)). **Cuándo no**: con `n` mayor, donde
`n!` no cabe; ahí, programación dinámica sobre subconjuntos ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)).

> **Veredicto:** ordenar, `do`/`while` con `next_permutation`, y la fuerza bruta de permutaciones está
> escrita. Los repetidos los gestiona sola.

---

## 5. 🧱 `nth_element` y `partial_sort`

**Qué es.** Dos formas de no ordenar entero cuando no hace falta.

- **`nth_element(first, nth, last)`** reorganiza el rango para que en `nth` quede el elemento que
  estaría ahí si se ordenara, con todos los anteriores `≤` y todos los posteriores `≥`, **sin ordenar
  ninguna de las dos partes**.
- **`partial_sort(first, middle, last)`** deja ordenados los `middle − first` menores al principio.

**Cómo va.**

```cpp
std::vector<int> a = {5, 2, 9, 1, 5, 6};
std::nth_element(a.begin(), a.begin() + 2, a.end());
int third = a[2];          // 5: el tercer menor; a[0..1] son {1, 2} en algún orden

std::partial_sort(a.begin(), a.begin() + 3, a.end());
// a[0..2] = 1 2 5, ordenados; el resto en orden no especificado
```

**Cuánto cuesta.** `nth_element`: `O(n)` en promedio (es una selección rápida, [`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md)).
`partial_sort`: `O(n log k)` con `k` el tamaño de la parte ordenada.

**Cuándo sí**: la mediana, el `k`-ésimo, los `k` menores sin necesidad de orden. **Cuándo no**: si
después vas a necesitar el arreglo ordenado entero; entonces `sort` desde el principio.

> **Veredicto:** `nth_element` no ordena: coloca uno y parte el resto. Es la mediana en `O(n)` de la
> librería.

---

## 6. 🧱 Los numéricos

**Qué es.** `<numeric>` trae las operaciones de acumular: `accumulate` (suma o pliegue), `partial_sum`
(prefijos), `adjacent_difference` (diferencias) e `iota` (rellenar con valores consecutivos).

**Cómo va.**

```cpp
#include <numeric>
#include <vector>

std::vector<long long> a = {5, 2, 9, 1, 5, 6};
long long total = std::accumulate(a.begin(), a.end(), 0LL);      // 28; el tipo lo fija el 0LL
std::vector<long long> prefix(a.size());
std::partial_sum(a.begin(), a.end(), prefix.begin());           // 5 7 16 17 22 28
std::vector<int> idx(6);
std::iota(idx.begin(), idx.end(), 0);                           // 0 1 2 3 4 5
```

- **El tipo del resultado de `accumulate` es el del valor inicial**, no el de los elementos.
  `std::accumulate(a.begin(), a.end(), 0)` suma en `int` aunque `a` sea de `long long`, y desborda en
  silencio con valores grandes ([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)). El literal correcto es `0LL`.
- **`partial_sum`** escribe los prefijos en otro rango (o en el mismo); es el arreglo de prefijos de
  [`04/01`](../04-secuencias/01-prefijos-y-diferencias.md) en una línea.
- **`iota`** es la forma de crear un vector de índices para ordenarlos por otra clave.

**Cuánto cuesta.** Todos lineales. **Cuándo sí**: siempre que el bucle sea una de estas cuatro formas.
**Cuándo no**: cuando el bucle tiene lógica que no encaja; forzarlo en `accumulate` con una lambda
compleja es menos legible que el `for`.

> **Veredicto:** `accumulate` con `0LL`, `partial_sum` para prefijos, `iota` para índices. El `0` de
> `int` en `accumulate` es un desbordamiento esperando.

---

## 7. 🧱 `std::ranges`

**Qué es.** La versión C++20 de los algoritmos: reciben el contenedor entero en vez de dos iteradores,
admiten **proyecciones** (ordenar por un campo sin escribir un comparador) y vienen con **vistas**
perezosas que se componen.

**Por qué es correcto** (el enunciado y una frase): los algoritmos de `std::ranges` exigen los mismos
contratos que los clásicos, pero los comprueban en compilación con *concepts*: un comparador o un
iterador incorrectos dan un error legible en vez de comportamiento indefinido en ejecución.

**Cómo va.**

```cpp
#include <algorithm>
#include <ranges>
#include <vector>

struct Meeting { int start, end; };

std::vector<int> a = {5, 2, 9, 1, 5, 6};
std::ranges::sort(a);                                         // sin begin()/end()
auto it = std::ranges::lower_bound(a, 5);

std::vector<Meeting> ms = {{1, 4}, {3, 5}, {0, 6}};
std::ranges::sort(ms, {}, &Meeting::end);                     // proyección: ordena por end

for (int x : a | std::views::reverse | std::views::take(3)) {   // vistas perezosas: 9 6 5
    // ...
}
```

```java
// En Java, lo más parecido son los comparadores por clave y los streams.
record Meeting(int start, int end) {}
List<Meeting> ms = new ArrayList<>(List.of(new Meeting(1, 4), new Meeting(3, 5), new Meeting(0, 6)));
ms.sort(Comparator.comparingInt(Meeting::end));               // la «proyección» de Java
```

- **La proyección** (`&Meeting::end`) sustituye a la lambda de comparación cuando se ordena por un
  campo; el comparador por defecto (`{}`) es `std::ranges::less`.
- **Las vistas no copian**: `views::reverse` y `views::take` recorren `a` sin crear vectores
  intermedios.
- **Java** no tiene vistas perezosas sobre listas en la librería básica; `Comparator.comparingInt` es
  la proyección, y los *streams* son lo más parecido a componer vistas, con más coste.

**Cuánto cuesta.** Lo mismo que los algoritmos clásicos. **El coste real es de compatibilidad**: hace
falta un compilador con C++20 completo. G++ 10 ya los trae; **la opción «C++20» de HackerRank, que es
G++ 8.3, no** ([`01/01`](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md)).

**Cuándo sí**: proyecciones para ordenar por un campo, y código más corto donde el compilador lo
admite. **Cuándo no**: en una plataforma con un compilador antiguo, o cuando un compañero de equipo
lee C++ clásico.

> **Veredicto:** `std::ranges` es la forma moderna y más segura de lo mismo. En competitiva, útil por
> las proyecciones; imprescindible, nunca.

---

## 8. 🧱 `ordered_set` de PBDS

**Qué es.** Las estructuras basadas en políticas (*policy-based data structures*, PBDS) son una
extensión de **libstdc++, la librería de GCC**, no del estándar. La que se usa en competitiva es un
árbol con **estadísticos de orden**: un conjunto ordenado que además responde, en `O(log n)`, «cuál es
el `k`-ésimo» y «cuántos hay menores que `x`».

**Por qué es correcto** (el enunciado y una frase): es un árbol rojo-negro en el que cada nodo guarda
el tamaño de su subárbol, y esos tamaños permiten bajar al `k`-ésimo o contar los menores en un solo
camino de la raíz a una hoja ([`07/02`](../07-arboles/02-bst-y-balanceados.md)).

**Cómo va.**

```cpp
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
#include <functional>

using OrderedSet = __gnu_pbds::tree<int, __gnu_pbds::null_type, std::less<int>,
                                    __gnu_pbds::rb_tree_tag,
                                    __gnu_pbds::tree_order_statistics_node_update>;

OrderedSet s;
for (int x : {5, 2, 9, 1, 6}) s.insert(x);       // 1 2 5 6 9 (es un set: sin repetidos)
int third = *s.find_by_order(2);                 // 5: el de posición 2 desde 0
int below6 = s.order_of_key(6);                  // 3: cuántos son < 6
```

- **`find_by_order(k)`** devuelve un iterador al `k`-ésimo, contando desde 0; **`order_of_key(x)`**,
  cuántos elementos son estrictamente menores que `x`.
- **Es un `set`**: no admite repetidos. Para un *multiset* se guardan pares `(valor, identificador
  único)`. **No** se usa `std::less_equal` como comparador: no es un orden estricto (§2) y `erase` y
  `find` dejan de funcionar.
- **Solo compila con libstdc++**: con GCC en Codeforces, CSES, HackerRank y Codility. En LeetCode depende
  de que su Clang enlace libstdc++, y eso no se ha comprobado con un envío: si allí no compila, el Fenwick de
  abajo lo sustituye. Con la libc++ de Apple, no.

**Cuánto cuesta.** `insert`, `erase`, `find_by_order` y `order_of_key` en `O(log n)`, con más constante
que un `std::set`. **La plantilla** es el alias de arriba; sin equivalente en Java, donde lo sustituye
un árbol de Fenwick con compresión de coordenadas ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)) o un *treap* ([`07/03`](../07-arboles/03-arboles-aleatorizados.md)).

**Cuándo sí**: rango de un elemento y `k`-ésimo con inserciones y borrados mezclados, en un juez con
GCC. **Cuándo no**: si el problema se puede resolver *offline* con un Fenwick, que es más rápido y
portable; ni fuera de la competitiva.

> **Veredicto:** el `ordered_set` es el atajo de GCC para el `k`-ésimo dinámico. Conviene saber
> usarlo, y saber resolver lo mismo sin él.

---

## 9. ⏱️ La tabla de costes

| Algoritmo | Coste | Lo que la tabla no dice |
|---|---|---|
| `sort` | `O(n log n)` caso peor | Comparador estricto, o comportamiento indefinido |
| `stable_sort` | `O(n log n)` con `O(n)` extra | Conserva el orden de los iguales |
| `lower_bound` / `upper_bound` | `O(log n)` | Solo con acceso aleatorio; sobre un `set`, el miembro |
| `next_permutation` | `O(n)` peor, `O(1)` amortizado | Hay que empezar ordenado |
| `nth_element` | `O(n)` promedio | No ordena ninguna de las dos partes |
| `partial_sort` | `O(n log k)` | Ordena solo los `k` primeros |
| `accumulate` | `O(n)` | El tipo lo fija el valor inicial: `0LL` |
| `ordered_set` (PBDS) | `O(log n)` | Solo libstdc++; sin repetidos |

---

## 10. 🧭 Cómo se elige

```text
¿Necesitas el rango entero ordenado?                    → sort (stable_sort si importan los empates)
¿Solo el k-ésimo, o la mediana?                         → nth_element
¿Solo los k menores, ordenados?                         → partial_sort
¿Contar o localizar en un rango ordenado que no cambia? → lower_bound / upper_bound
¿Recorrer todas las permutaciones con n ≤ 10?           → sort + next_permutation
¿El k-ésimo o el rango con inserciones y borrados?      → ordered_set (GCC) o Fenwick offline
¿Prefijos o suma?                                       → partial_sum / accumulate con 0LL
```

> **Mejor:** «Para la mediana no ordeno: `nth_element` la coloca en `O(n)` promedio; y para contar
> cuántos hay en `[L, R]`, `upper_bound` menos `lower_bound` sobre el vector ordenado.»

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Un comparador con `<=` vale» | No es un orden estricto débil: comportamiento indefinido, y en libstdc++ puede salirse del arreglo |
| «`nth_element` ordena» | Coloca un elemento y parte el resto, sin ordenar ninguna de las dos mitades |
| «`next_permutation` da todas las permutaciones» | Da las siguientes a la actual; para todas, hay que empezar ordenado |
| «`accumulate` suma en el tipo de los elementos» | Suma en el tipo del valor inicial: con `0`, en `int` |
| «PBDS es parte de C++» | Es una extensión de libstdc++: compila con GCC y con Clang sobre libstdc++, no con libc++ |
| «`ordered_set` con `less_equal` es un *multiset*» | Rompe `find` y `erase`; se usan pares `(valor, id)` |
| «`std::ranges` está en todos los jueces con C++20» | Necesita un compilador moderno; la opción «C++20» de HackerRank es G++ 8.3 |

---

## 📚 Para profundizar

- **Libro** — Farrier, *Data Structures and Algorithms with the C++ STL* (Packt, 2024), caps. 11–15:
  los algoritmos de la STL y su uso moderno. *Lectura troncal.*
- **Documentación** — cppreference, [*Compare*](https://en.cppreference.com/cpp/named_req/Compare): el
  contrato del orden estricto débil. *Lectura troncal.*
- **Documentación** — cppreference, [`std::sort`](https://en.cppreference.com/cpp/algorithm/sort),
  [`std::nth_element`](https://en.cppreference.com/cpp/algorithm/nth_element) y
  [`std::next_permutation`](https://en.cppreference.com/cpp/algorithm/next_permutation).
- **Documentación** — cppreference, [`std::accumulate`](https://en.cppreference.com/cpp/algorithm/accumulate)
  y [*Ranges library*](https://en.cppreference.com/cpp/ranges).
- **Documentación** — GCC, [*Policy-Based Data Structures*](https://gcc.gnu.org/onlinedocs/libstdc++/manual/policy_data_structures.html):
  el diseño de PBDS y sus árboles con estadísticos de orden. *Lectura troncal.*
- **Libro** — Halim, Halim y Effendy, *Competitive Programming 4*, libro 1 (2020), cap. 2: la librería
  estándar de C++ usada para competir.

---

## 🧠 Preguntas

1. ¿Qué cuatro propiedades tiene que cumplir el comparador de `std::sort`? 🟢
2. ¿Qué devuelven `lower_bound` y `upper_bound`, y cómo cuentas las apariciones de `x` con ellas? 🟢
3. ¿Qué hace `nth_element` con los elementos que no son el `n`-ésimo? 🟢
4. ¿Qué diferencia hay entre `sort` y `stable_sort`, en garantías y en coste? 🟡
5. ¿Por qué hay que ordenar antes de recorrer las permutaciones con `next_permutation`, y qué pasa con los repetidos? 🟡
6. ¿Qué diferencia hay entre `find_by_order` y `order_of_key` en un `ordered_set`? 🟡
7. ¿Por qué `std::accumulate(v.begin(), v.end(), 0)` puede dar un resultado incorrecto con `v` de `long long`? 🟠
8. ¿Por qué un comparador de `double` con tolerancia puede romper `std::sort`? 🟠
9. Compara cómo ordenas una lista de reuniones por su hora de fin en C++ con `std::ranges`, en Java y en Python. 🟠
10. ¿Por qué un `ordered_set` con `std::less_equal` no funciona como *multiset*, y qué se hace en su lugar? 🔴
11. Explica por qué `std::sort` con `>=` puede leer fuera del arreglo en libstdc++, relacionándolo con el contrato del comparador. 🔴
12. Diseña la solución a «para cada uno de `q` rangos `[L, R]`, cuántos valores de un arreglo fijo caen dentro», di su coste y por qué no hace falta ninguna estructura más que un `vector`. 🔴

---

## 🧩 Problemas propios

### Los k más baratos

**Nivel:** 🟢 · **Formato:** programa completo.

Imprime la suma de los `k` precios más bajos de una lista.

- **Entrada.** Una línea con `n` y `k`. Una línea con los `n` precios.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ n ≤ 10⁶`; `1 ≤ precio ≤ 10⁹`. Límite: 1 segundo.

```text
Entrada            Salida
6 3                8
5 2 9 1 5 6

Entrada            Salida
2 2                2000000000
1000000000 1000000000
```

**Pista 1:** ¿hace falta que los `k` más baratos queden ordenados entre sí?

### Precios en un rango

**Nivel:** 🟡 · **Formato:** programa completo.

Un catálogo tiene `n` precios fijos. Para cada consulta `[L, R]`, imprime cuántos precios están entre
`L` y `R`, los dos incluidos.

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` precios. Después, `q` líneas con `L R`.
- **Salida.** `q` enteros, uno por línea.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `1 ≤ precio, L ≤ R ≤ 10⁹`.

```text
Entrada            Salida
6 3                3
5 2 9 1 5 6        6
5 6                0
1 9
10 20

Entrada            Salida
3 2                3
7 7 7              0
7 7
1 6
```

**Pista 1:** si los precios estuvieran ordenados, ¿dónde empiezan y dónde terminan los que caen en el
rango?

### Posición en vivo

**Nivel:** 🟠 · **Formato:** programa completo.

Llegan puntuaciones de jugadores, todas distintas, una a una. Después de cada llegada, imprime en qué
posición está el jugador que acaba de llegar (1 es el de mayor puntuación entre los que ya llegaron).

- **Entrada.** Una línea con `n`. Una línea con las `n` puntuaciones.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ puntuación ≤ 10⁹`, todas distintas.

```text
Entrada            Salida
5                  1 2 1 4 2
5 2 9 1 6

Entrada            Salida
4                  1 1 1 1
1 2 3 4
```

**Pista 1:** la posición del recién llegado, ¿qué tiene que ver con cuántos de los anteriores tienen más
puntos que él?

🔥 **Para el geek — en Go:** sin `ordered_set` ni árbol en la librería, la versión en Go obliga a
resolverlo *offline* con compresión de coordenadas y un árbol de Fenwick, que es otra forma de pensar
el problema.

---

## 🧩 Práctica externa

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Vector-Sort](https://www.hackerrank.com/challenges/vector-sort/problem) | HackerRank | 🟢 | `sort` | ¿Qué rango le pasas a `sort` para ordenar todo el vector? |
| [ ] | [Relative Sort Array](https://leetcode.com/problems/relative-sort-array/) | LeetCode | 🟢 | Comparador propio | ¿Qué clave asignas a cada valor para que el orden de la segunda lista mande? |
| [ ] | [Triangle](https://app.codility.com/programmers/lessons/6-sorting/triangle/) | Codility | 🟢 | Ordenar y vecinos | Si hay un triángulo, ¿lo hay también entre tres valores consecutivos tras ordenar? |
| [ ] | [Sorting: Comparator](https://www.hackerrank.com/challenges/ctci-comparator-sorting/problem) | HackerRank | 🟡 | Comparador con desempate | ¿Qué devuelve tu comparador cuando las puntuaciones son iguales? |
| [ ] | [Next Permutation](https://leetcode.com/problems/next-permutation/) | LeetCode | 🟡 | La operación de `next_permutation` | ¿Qué parte final de la secuencia ya está en su orden máximo? |
| [ ] | [Permutations](https://leetcode.com/problems/permutations/) | LeetCode | 🟡 | `next_permutation` | ¿Desde qué orden tienes que empezar para recorrerlas todas? |
| [ ] | [Kth Largest Element in an Array](https://leetcode.com/problems/kth-largest-element-in-an-array/) | LeetCode | 🟡 | Selección | ¿Necesitas ordenar todo para saber cuál queda en la posición `k`? |
| [ ] | [NumberOfDiscIntersections](https://app.codility.com/programmers/lessons/6-sorting/number_of_disc_intersections/) | Codility | 🟡 | Ordenar extremos y buscar | Si ordenas los inicios y los finales por separado, ¿qué cuentas para cada disco? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Creating Strings](https://cses.fi/problemset/task/1622) | CSES | 🟢 | `next_permutation` con repetidos | ¿Cuántas permutaciones distintas hay, y en qué orden se piden? |
| [ ] | [List Removals](https://cses.fi/problemset/task/1749) | CSES | 🟡 | `k`-ésimo dinámico | ¿Qué estructura te da el elemento en la posición `k` después de borrar otros? |
| [ ] | [Josephus Problem II](https://cses.fi/problemset/task/2163) | CSES | 🟡 | `k`-ésimo dinámico | Si conoces la posición del último eliminado, ¿cómo calculas la del siguiente entre los que quedan? |
| [ ] | [Nested Ranges Count](https://cses.fi/problemset/task/2169) | CSES | 🟠 | Rango con inserciones | Ordenando los rangos de una forma concreta, ¿qué tienes que contar entre los ya vistos? |

---

## ✅ Criterio de dominio

- Enunciar las cuatro propiedades del orden estricto débil y dar un comparador que viole cada una.
- Contar las apariciones de un valor y los valores de un rango con `lower_bound` y `upper_bound`.
- Recorrer todas las permutaciones con repetidos y decir cuántas salen.
- Declarar un `ordered_set` de memoria y resolver con él List Removals.

---

**Anterior:** [`03/01` — C++: contenedores de la STL](01-cpp-contenedores.md) ·
**Siguiente:** [`03/03` — Java: las colecciones](03-java-colecciones.md) ·
**Relacionado:** [`05/01` — Ordenación por comparación](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md); [`05/03` — Inversiones, selección y mediana](../05-orden-y-busqueda/03-inversiones-y-seleccion.md).
