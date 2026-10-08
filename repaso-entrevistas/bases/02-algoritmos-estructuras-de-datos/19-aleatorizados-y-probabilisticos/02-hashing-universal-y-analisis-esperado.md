# 02 — *Hashing* universal y análisis esperado

> Por qué elegir la función de *hash* al azar, de una familia universal, protege contra cualquier entrada:
> la probabilidad de que dos claves choquen es `1/m` sea cual sea la entrada, y la cadena esperada mide
> `1 + α`. Y el mismo tipo de análisis para las estructuras aleatorizadas de
> [`07/03`](../07-arboles/03-arboles-aleatorizados.md): la altura esperada de la *skip list*, su coste de
> búsqueda y las rotaciones del *treap*.
>
> **Niveles:** *hashing* universal [B] · análisis esperado de *treap* y *skip list* [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §11.3; Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017),
> cap. 15.
>
> **Asume leído:** [`19/01` — Las Vegas y Monte Carlo](01-las-vegas-y-monte-carlo.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--hashing-universal) · [4](#4--análisis-esperado-de-treap-y-skip-list) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

[`06/03`](../06-lineales-y-hashing/03-tablas-hash.md) mostró el ataque: con la función de *hash* de la
librería, que es pública y fija, alguien fabrica `2·10⁵` claves que caen en la misma cubeta, y una tabla
*hash* que debía ser `O(1)` por operación se vuelve cuadrática. Ninguna función fija resiste: para cualquier
`h` con `m` cubetas y un universo de claves mucho mayor, alguna cubeta recibe al menos `|U|/m` claves, y el
atacante elige de ahí.

La salida es no tener una función fija: elegirla **al azar** de una familia, después de que la entrada
exista. Si la familia es **universal**, dos claves distintas cualesquiera chocan con probabilidad `1/m`, y
ninguna entrada es mala para muchas funciones a la vez. Es el mismo argumento que el pivote aleatorio de
*quicksort*: el adversario no conoce las monedas.

> 🧠 **Modelo mental.** Una función fija tiene una entrada mala. Una familia universal tiene, para cada
> entrada, muy pocas funciones malas; y la función se sortea cuando la entrada ya está escrita.

---

## 2. 📐 La teoría

**Familia universal.** Una familia `H` de funciones `U → {0, …, m − 1}` es universal si, para todo par de
claves distintas `x ≠ y`:

```text
P_{h ∈ H}[ h(x) = h(y) ] ≤ 1/m
```

**Teorema (cadena esperada).** Con `h` universal, `n` claves y `m` cubetas (`α = n/m`), el número esperado de
otras claves en la cubeta de una clave dada es como mucho `(n − 1)/m < α`. Buscar cuesta `O(1 + α)` en
esperanza, para **cualquier** conjunto de claves. Es linealidad de la esperanza sobre los indicadores «`y`
choca con `x`».

**La familia de Carter y Wegman.** Con un primo `p` mayor que todas las claves:

```text
h_{a,b}(x) = ((a·x + b) mod p) mod m,      a ∈ {1, …, p − 1},  b ∈ {0, …, p − 1}
```

*Esbozo de por qué es universal.* Para `x ≠ y`, el par `(r, s) = (ax + b mod p, ay + b mod p)` recorre, al
variar `(a, b)`, todos los pares con `r ≠ s` exactamente una vez (es un sistema lineal invertible módulo
`p`). Para cada `r`, como mucho `⌈p/m⌉ − 1 ≤ (p − 1)/m` valores `s ≠ r` cumplen `s ≡ r (mod m)`. Así que la
fracción de funciones con choque es como mucho `1/m`.

**Skip list.** Cada elemento sube a cada nivel con probabilidad `1/2`:

- **Espacio.** El número esperado de niveles de un elemento es 2: `2n` punteros en total.
- **Altura.** `P(altura > log₂ n + c) ≤ n · 2^{−(log₂ n + c)} = 2⁻ᶜ` (unión de los `n` eventos); la altura es
  `log₂ n + O(1)` con alta probabilidad.
- **Búsqueda** (análisis hacia atrás). Recorriendo el camino de búsqueda al revés, desde abajo, en cada paso se
  sube un nivel con probabilidad `1/2` o se va a la izquierda: subir un nivel cuesta 2 pasos esperados, y hay
  unos `log₂ n` niveles. Coste esperado `≤ 2 log₂ n + O(1)`.

**Treap.** La profundidad esperada `2 ln n + O(1)` está demostrada en
[`07/03`](../07-arboles/03-arboles-aleatorizados.md). Además, una inserción hace **menos de 2 rotaciones** en
esperanza (Seidel y Aragon), y la altura es `O(log n)` con alta probabilidad: la probabilidad de que pase de
`c ln n` baja como una potencia negativa de `n`.

---

## 3. 🧱 *Hashing* universal

**Qué es.** Elegir la función de *hash* al azar, al empezar, de una familia universal.

**Por qué es correcto.** El teorema de la cadena esperada: para cualquier entrada fijada antes del sorteo, el
coste esperado por operación es `O(1 + α)`.

**Cómo va**, con `p = 5` y `m = 2`: las 20 funciones `h_{a,b}` sobre las claves `{0, …, 4}`. El par que más
choca es `(0, 1)`, que choca en 8 de las 20: `2/5 ≤ 1/2`. Con `p = 7` y `m = 3`, el peor par choca en `5/21 ≤
1/3`. La cota se cumple con margen.

**Cuánto.** Una multiplicación, una suma y dos módulos por clave; elegir la función es `O(1)`.

**La plantilla**, con `p = 2³¹ − 1` para claves de 31 bits:

```cpp
#include <chrono>
#include <cstdint>
#include <random>

// Familia de Carter y Wegman: h(x) = ((a·x + b) mod p) mod m, para 0 ≤ x < p.
struct UniversalHash {
    static constexpr uint64_t P = 2147483647;            // 2³¹ − 1, primo
    uint64_t a, b, m;
    explicit UniversalHash(uint64_t buckets) : m(buckets) {
        std::mt19937_64 rng(std::chrono::steady_clock::now().time_since_epoch().count());
        a = 1 + rng() % (P - 1);
        b = rng() % P;
    }
    uint64_t operator()(uint64_t x) const { return ((a * x + b) % P) % m; }   // a·x < 2⁶²
};
```

```java
static final class UniversalHash {
    static final long P = 2147483647L;                    // 2³¹ − 1, primo
    final long a, b, m;
    UniversalHash(long buckets) {
        java.util.SplittableRandom rng = new java.util.SplittableRandom();
        m = buckets;
        a = 1 + rng.nextLong(P - 1);
        b = rng.nextLong(P);
    }
    long apply(long x) { return ((a * x + b) % P) % m; }  // x en [0, P): a·x < 2⁶²
}
```

- **El primo y el tamaño de las claves.** Con `p = 2³¹ − 1` y claves menores que `p`, `a·x + b` no pasa de
  `2⁶²`: cabe en 64 bits. Para claves de 64 bits, `p = 2⁶¹ − 1` y el producto en 128 bits (`__int128` o
  `Math.multiplyHigh`).
- **La semilla**, del reloj o del sistema (`SplittableRandom()` sin argumento en Java): es lo que impide que el
  atacante conozca `a` y `b`.
- **En Python**, el *hash* de las cadenas ya lleva semilla aleatoria; el de los enteros no. Para una tabla
  propia, la misma fórmula con enteros sin límite.
- **En concurso**, `splitmix64` con semilla del reloj ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md))
  es más rápido; no es una familia universal demostrada, pero resiste los ataques conocidos.

**Cuándo sí:** tablas *hash* expuestas a entradas de un adversario (servidores, jueces con *hacks*); como
pieza de las estructuras probabilísticas ([`19/03`](03-estructuras-probabilisticas.md)), que necesitan varias
funciones independientes. **Cuándo no:** con claves que controla el propio programa, la función de la
librería basta.

> **Veredicto:** un buen *hash* fijo no basta contra un adversario: tiene su entrada mala. Uno sorteado de
> una familia universal da `O(1 + α)` esperado para toda entrada, con la misma idea que el pivote aleatorio.

---

## 4. 🧱 Análisis esperado de *treap* y *skip list*

**Qué es.** Las garantías de coste de las dos estructuras aleatorizadas de
[`07/03`](../07-arboles/03-arboles-aleatorizados.md), que es donde están el código y la profundidad esperada
del *treap*.

**Por qué es correcto.** Las cuentas de §2: unión de eventos para la altura de la *skip list*, análisis
hacia atrás para su búsqueda, y la equivalencia del *treap* con un BST aleatorio.

**Cómo va**, la altura esperada de una *skip list* (número de niveles, con cada elemento subiendo con
probabilidad `1/2`):

```text
n = 1        2,00 niveles          n = 1 000       11,30   (log₂ n ≈ 9,97)
n = 2        2,67                  n = 10⁶         21,26   (log₂ n ≈ 19,93)
E[altura] = Σ_{k ≥ 1} P(altura ≥ k) = Σ_{k ≥ 1} (1 − (1 − 2^{−(k−1)})ⁿ)
```

**Cuánto.**

| Estructura | Búsqueda | Inserción | Espacio |
|---|---|---|---|
| *Skip list* | `≤ 2 log₂ n + O(1)` esperado | Igual | `2n` punteros esperados |
| *Treap* | `2 ln n + O(1) ≈ 1,39 log₂ n` esperado | `< 2` rotaciones esperadas | `n` nodos |

**La plantilla.** La de [`07/03`](../07-arboles/03-arboles-aleatorizados.md); aquí no se repite.

**Cuándo sí:** argumentar en una entrevista por qué una estructura aleatorizada es `O(log n)` sin
rebalanceo; comparar con los árboles balanceados deterministas ([`07/02`](../07-arboles/02-bst-y-balanceados.md)). **Cuándo no:** con tiempo real
duro: «con alta probabilidad» no es «siempre».

> **Veredicto:** las estructuras aleatorizadas son `O(log n)` esperado **para toda secuencia de
> operaciones**, porque la forma la deciden las monedas, no el orden de las claves.

---

## 5. ⏱️ La tabla de costes

| Técnica | Garantía | Coste | Lo que la tabla no dice |
|---|---|---|---|
| *Hash* fijo | Ninguna contra un adversario | `O(1)` por llamada | Existe una entrada que lo vuelve `Θ(n)` por operación |
| *Hash* universal | Choque `≤ 1/m` por par | `O(1)` por llamada | Cadena esperada `1 + α` para cualquier entrada |
| `splitmix64` con semilla | Empírica | `O(1)`, muy rápido | No es universal demostrada |
| *Skip list* | `O(log n)` esperado | `2n` punteros | Altura `log₂ n + O(1)` con alta probabilidad |
| *Treap* | `O(log n)` esperado | `< 2` rotaciones por inserción | Altura `O(log n)` con alta probabilidad |

---

## 6. 🧭 Cómo se elige

```text
¿La entrada la puede elegir un adversario que conoce el código? → hash con semilla (universal si hay que demostrarlo)
¿Hace falta una garantía demostrable? → Carter-Wegman o multiplicar y desplazar con a impar al azar
¿Varias funciones independientes (Bloom, Count-Min)? → varias funciones de una familia universal
¿Árbol ordenado sin rotaciones complicadas? → treap o skip list, O(log n) esperado
```

> **Regla de entrevista:** si te preguntan por qué una tabla *hash* es `O(1)`, di «esperado, con una
> función elegida al azar de una familia universal; con una función fija hay entradas que la degradan».

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| Juez con *hacks*, `unordered_map` con claves enteras | Semilla del reloj | La función de la librería es pública |
| «Demuestra que la búsqueda es `O(1)` esperado» | Familia universal | La cadena esperada es `1 + α` |
| Varias funciones de *hash* «independientes» | Varias funciones de la familia | Bloom y Count-Min las necesitan |
| «Árbol de búsqueda sin rebalanceo explícito» | *Treap* o *skip list* | `O(log n)` esperado |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Un buen *hash* fijo basta» | Toda función fija tiene una entrada que manda todo a una cubeta |
| «*Hash* universal significa que no hay colisiones» | Significa que cada par choca con probabilidad `≤ 1/m` |
| «Con `h(x) = x mod m` y `m` primo ya es seguro» | Es una función fija: los múltiplos de `m` caen juntos |
| «La *skip list* tiene altura `log₂ n` siempre» | En esperanza, `log₂ n + O(1)`; con alta probabilidad, no mucho más |
| «El *treap* es `O(log n)` en el caso peor» | Esperado y con alta probabilidad; el peor caso es `Θ(n)`, con probabilidad despreciable |
| «La familia funciona aunque el atacante vea `a` y `b`» | La garantía exige que la función se sortee sin que el atacante la conozca |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §11.3.3: familias universales y la demostración de Carter y Wegman. *Lectura troncal.*
- **Libro** — Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017), cap. 15:
  independencia por pares y funciones de *hash* universales. *Lectura troncal.*
- **Artículo** — Carter y Wegman, «Universal classes of hash functions», *Journal of Computer and System
  Sciences* 18(2), 1979.
- **Artículo** — Pugh, «Skip lists: a probabilistic alternative to balanced trees», *Communications of the
  ACM* 33(6), 1990.

---

## 🧠 Preguntas

1. ¿Qué es una familia universal de funciones de *hash*? 🟢
2. ¿Cuál es la longitud esperada de una cadena con *hashing* universal? 🟢
3. ¿Cuál es la altura esperada de una *skip list* de `n` elementos? 🟢
4. ¿Por qué ninguna función de *hash* fija resiste a un adversario? 🟡
5. ¿Qué diferencia hay entre «sin colisiones» y «universal»? 🟡
6. ¿Cuántos punteros ocupa en esperanza una *skip list*, y por qué? 🟡
7. ¿Qué cambia entre C++, Java y Python para implementar Carter-Wegman con claves de 64 bits? 🟠
8. ¿Por qué el análisis hacia atrás da `2 log₂ n` para la búsqueda en una *skip list*? 🟠
9. ¿Qué relación hay entre el pivote aleatorio de *quicksort* y el *hashing* universal? 🟠
10. ¿Qué garantiza «con alta probabilidad» que no garantiza «en esperanza»? 🟠
11. Demuestra que la familia `((a·x + b) mod p) mod m` es universal. 🔴
12. Demuestra que, con *hashing* universal, el número esperado de claves en la cubeta de una clave dada es
    menor que `1 + α`. 🔴

---

## 🧩 Problemas propios

### Colisiones esperadas

**Nivel:** 🟢 · **Formato:** programa completo.

Se insertan `n` claves distintas en una tabla de `m` cubetas con una función elegida al azar de una familia
en la que cada par de claves choca con probabilidad exactamente `1/m`. Imprime el número esperado de pares
de claves que chocan, como fracción irreducible `p/q`.

- **Entrada.** Una línea con `n` y `m`.
- **Salida.** `p/q`.
- **Restricciones.** `1 ≤ n ≤ 10⁹`; `1 ≤ m ≤ 10⁹`.

```text
Entrada         Salida
4 6             1/1

Entrada         Salida
10 100          9/20
```

**Pista 1:** ¿cuántos pares de claves hay, y qué aporta cada uno a la esperanza?

### ¿Cumple la cota?

**Nivel:** 🟡 · **Formato:** programa completo.

Para la familia `h_{a,b}(x) = ((a·x + b) mod p) mod m`, con `a ∈ {1, …, p − 1}` y `b ∈ {0, …, p − 1}`, y las
claves `{0, …, p − 1}`, imprime la mayor probabilidad de choque entre dos claves distintas, como fracción
irreducible.

- **Entrada.** Una línea con `p` (primo) y `m`.
- **Salida.** `p/q`.
- **Restricciones.** `2 ≤ m ≤ p ≤ 47`.

```text
Entrada         Salida
5 2             2/5

Entrada         Salida
7 3             5/21
```

**Pista 1:** ¿cuántas funciones tiene la familia y cuántos pares de claves hay? ¿Te alcanza con probarlas
todas?

### Altura esperada

**Nivel:** 🟠 · **Formato:** programa completo.

En una *skip list*, cada elemento ocupa al menos un nivel, y sube a cada nivel siguiente con probabilidad
`1/2`, de forma independiente. La altura es el mayor número de niveles de un elemento. Imprime la altura
esperada con `n` elementos, con 6 decimales.

- **Entrada.** Un entero `n`.
- **Salida.** Un real. Se aceptan errores de hasta `10⁻⁶`.
- **Restricciones.** `1 ≤ n ≤ 10¹⁸`.

```text
Entrada         Salida
1               2.000000

Entrada         Salida
2               2.666667

Entrada         Salida
1000            11.299253
```

**Pista 1:** la esperanza de una variable entera positiva es la suma de las probabilidades de que valga al
menos `k`. ¿Cuál es la probabilidad de que **ningún** elemento llegue al nivel `k`?

---

## 🧩 Práctica externa

> 💡 **Truco.** Este capítulo se practica con los propios y con el análisis: antes de usar una tabla *hash*
> en un juez con *hacks*, escribe en una línea qué te garantiza tu función. Si una IA te ayuda, que sea a
> revisar tu demostración, no a escribirla
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

Las bases no tienen problemas sobre la teoría del *hashing* universal; lo que se usa en juez está en
[`06/03`](../06-lineales-y-hashing/03-tablas-hash.md).

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [The Untended Antiquity](https://codeforces.com/problemset/problem/869/E) | Codeforces | 🔴 | Valores aleatorios y Fenwick 2D | Si a cada rectángulo le asignas un número al azar y lo sumas en su zona, ¿qué dice que dos celdas tengan la misma suma? |

---

## ✅ Criterio de dominio

- Definir familia universal y demostrar la cadena esperada `1 + α`.
- Escribir Carter-Wegman en C++ o Java con la semilla correcta.
- Explicar la altura esperada y la búsqueda de la *skip list* con el análisis hacia atrás.
- Resolver los tres propios.

---

**Anterior:** [`19/01` — Las Vegas y Monte Carlo](01-las-vegas-y-monte-carlo.md) · **Siguiente:** [`19/03` — Estructuras probabilísticas](03-estructuras-probabilisticas.md) ·
**Relacionado:** [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*](../06-lineales-y-hashing/03-tablas-hash.md).
