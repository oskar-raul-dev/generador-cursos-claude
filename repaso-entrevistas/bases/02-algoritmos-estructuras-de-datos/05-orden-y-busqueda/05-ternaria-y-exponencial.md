# 05 — Búsqueda ternaria, unimodales y exponencial

> Dos parientes de la búsqueda binaria: la **ternaria**, que encuentra el extremo de una función
> unimodal, y la **exponencial**, que busca sin conocer el tamaño. Por qué la ternaria exige
> unimodalidad estricta, qué la rompe, y la binaria sobre la diferencia como alternativa.
>
> **Niveles:** ternaria [B] · exponencial [B].
>
> **📚 Lectura troncal:** cp-algorithms, [*Ternary Search*](https://cp-algorithms.com/num_methods/ternary_search.html);
> Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 5.
>
> **Asume leído:** [`05/04` — Búsqueda binaria](04-busqueda-binaria.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--búsqueda-ternaria) · [4](#4--binaria-sobre-la-diferencia) · [5](#5--búsqueda-exponencial) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

La binaria de `05/04` busca una **frontera**: el punto donde un predicado pasa de falso a cierto. Hay
dos situaciones parecidas en las que esa herramienta no encaja tal cual:

- **Un extremo, no una frontera.** El coste de colocar una antena en la posición `x` baja y después
  sube. No hay un predicado «`x` funciona»: hay una función con un mínimo, y se busca **dónde**.
- **Sin cota superior.** Un registro ordenado del que no se conoce el tamaño, o una binaria sobre la
  respuesta sin un `hi` razonable. Empezar con `hi = 10¹⁸` funciona, pero cuesta 60 pasos aunque la
  respuesta sea 5.

La **ternaria** resuelve la primera si la función es **unimodal**; la **exponencial**, la segunda,
duplicando el `hi` hasta pasarse. Las dos se reducen a la binaria: la ternaria, a una binaria sobre el
signo de la diferencia; la exponencial, a una binaria después de encontrar el rango.

---

## 2. 📐 La teoría

**Unimodal.** Una función `f` sobre `[lo, hi]` es **estrictamente unimodal** (con un mínimo) si existe
`p` tal que `f` es estrictamente decreciente en `[lo, p]` y estrictamente creciente en `[p, hi]`. Para
un máximo, al revés.

**La idea de la ternaria.** Se toman dos puntos interiores `m₁ < m₂`. Si `f(m₁) < f(m₂)`, el mínimo no
puede estar a la derecha de `m₂`: si `p ≥ m₂`, los dos estarían en el tramo decreciente y sería
`f(m₁) > f(m₂)`. Se descarta `(m₂, hi]`. Si `f(m₁) > f(m₂)`, por simetría se descarta `[lo, m₁)`. Si son
iguales, con unimodalidad **estricta** el mínimo está entre los dos.

**Por qué estricta.** Con mesetas, `f(m₁) = f(m₂)` ya no dice de qué lado está el mínimo: puede estar
fuera de `[m₁, m₂]`. En `[1, 4, 4, 4, 4, 4, 4, 5]` (mínimo en la posición 0), los puntos `m₁ = 2` y
`m₂ = 5` valen 4 los dos, y la ternaria descarta el tramo del mínimo (§3). Las funciones **convexas** sí
funcionan aunque tengan una meseta, porque la meseta solo puede estar en el mínimo.

**La binaria sobre la diferencia.** Sobre enteros, `f` estrictamente unimodal con mínimo en `p`
equivale a que el predicado `D(x) = f(x + 1) − f(x) ≥ 0` sea falso en `[lo, p)` y cierto desde `p`. Es
monótono, y la binaria de `05/04` encuentra `p` con `log₂` evaluaciones en lugar de `log₁,₅`.

**Teorema (coste de la exponencial).** Si la respuesta está en la posición `p`, la búsqueda exponencial
la encuentra con `O(log p)` comparaciones.

*Prueba.* La fase de duplicación prueba `1, 2, 4, …, 2ᵏ` y para en el primer `2ᵏ ≥ p`, con
`k = ⌈log₂ p⌉` pruebas. La binaria sobre `(2^{k−1}, 2ᵏ]` recorre un intervalo de tamaño `2^{k−1} < p`, con
`O(log p)` pasos más. Total, `O(log p)`.

---

## 3. 🧱 Búsqueda ternaria

**Qué es.** Reducir el intervalo a sus dos tercios en cada vuelta comparando `f` en dos puntos
interiores, hasta que quedan pocos candidatos.

**Por qué es correcto** (el enunciado y una frase): con `f` estrictamente unimodal, cada comparación
descarta un tercio que no contiene el mínimo, por el argumento de §2.

**Cómo va**, `f(x) = (x − 7)²` en `[0, 20]` sobre enteros:

```text
lo  hi  m₁  f(m₁)  m₂  f(m₂)
0   20  6   1      14  49     f(m₁) < f(m₂) → hi = 13
0   13  4   9      9   4      f(m₁) ≥ f(m₂) → lo = 5
5   13  7   0      11  16     → hi = 10
5   10  6   1      9   4      → hi = 8
5   8   6   1      7   0      → lo = 7
7   8   quedan dos: el mínimo es 7
```

Con la meseta `[1, 4, 4, 4, 4, 4, 4, 5]`: `m₁ = 2`, `m₂ = 5`, los dos valen 4 y la ternaria hace
`lo = 3`. El mínimo, en la posición 0, queda fuera; devuelve la posición 5, con valor 4.

**Cuánto.** Cada vuelta conserva `2/3` del intervalo con **dos** evaluaciones: `≈ 2 log_{3/2} n ≈ 3,4 log₂ n`
evaluaciones. La binaria sobre la diferencia usa `2 log₂ n` (dos evaluaciones por paso).

**La plantilla**, sobre enteros y sobre reales:

```cpp
#include <functional>

// Posición del mínimo de f en [lo, hi], f estrictamente unimodal (o convexa). O(log n) evaluaciones.
long long ternaryMinInt(long long lo, long long hi, const std::function<long long(long long)>& f) {
    while (hi - lo > 2) {
        long long m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f(m1) < f(m2)) hi = m2 - 1; else lo = m1 + 1;
    }
    long long best = lo;                                  // quedan como mucho tres candidatos
    for (long long x = lo + 1; x <= hi; x++) if (f(x) < f(best)) best = x;
    return best;
}

// Mínimo de f en [lo, hi] sobre reales, con 100 vueltas fijas.
double ternaryMinReal(double lo, double hi, const std::function<double(double)>& f) {
    for (int it = 0; it < 100; it++) {
        double m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f(m1) < f(m2)) hi = m2; else lo = m1;
    }
    return lo + (hi - lo) / 2;
}
```

```java
import java.util.function.DoubleUnaryOperator;
import java.util.function.LongUnaryOperator;

// Posición del mínimo de f en [lo, hi], f estrictamente unimodal (o convexa). O(log n) evaluaciones.
static long ternaryMinInt(long lo, long hi, LongUnaryOperator f) {
    while (hi - lo > 2) {
        long m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f.applyAsLong(m1) < f.applyAsLong(m2)) hi = m2 - 1; else lo = m1 + 1;
    }
    long best = lo;
    for (long x = lo + 1; x <= hi; x++) if (f.applyAsLong(x) < f.applyAsLong(best)) best = x;
    return best;
}

// Mínimo de f en [lo, hi] sobre reales, con 100 vueltas fijas.
static double ternaryMinReal(double lo, double hi, DoubleUnaryOperator f) {
    for (int it = 0; it < 100; it++) {
        double m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f.applyAsDouble(m1) < f.applyAsDouble(m2)) hi = m2; else lo = m1;
    }
    return lo + (hi - lo) / 2;
}
```

- **`hi = m2 − 1` y `lo = m1 + 1`** en enteros: si `f(m₁) < f(m₂)`, `m₂` no es el mínimo y se descarta
  también. El caso de igualdad va a la rama `else`.
- **`while (hi − lo > 2)`** y el recorrido final de hasta tres candidatos evitan el caso en que `m₁` y
  `m₂` coinciden o se cruzan con intervalos pequeños.
- **En reales**, 100 vueltas reducen el intervalo en `(2/3)¹⁰⁰ ≈ 2·10⁻¹⁸`: suficiente para cualquier
  intervalo de partida razonable. Si `f` es cara, 60 vueltas suelen bastar.
- **Para un máximo**, se cambia `<` por `>`, o se minimiza `−f`.

**Cuándo sí**: funciones reales unimodales (distancias, tiempos, áreas), y funciones convexas sobre
enteros. **Cuándo no**: funciones con mesetas fuera del mínimo, o con varios mínimos locales; sobre
enteros, la binaria sobre la diferencia (§4) es más simple y más rápida.

> **Veredicto:** la ternaria encuentra el extremo de una función unimodal **estricta**. Una meseta
> fuera del mínimo la engaña sin avisar.

---

## 4. 🧱 Binaria sobre la diferencia

**Qué es.** Sobre enteros, buscar con la binaria de `05/04` el primer `x` con `f(x + 1) ≥ f(x)`: es el
mínimo de una función estrictamente unimodal.

**Por qué es correcto**: por §2, el predicado de la diferencia es monótono si `f` es estrictamente
unimodal.

```cpp
// Mínimo de f en [lo, hi], f estrictamente unimodal sobre enteros. 2·log₂ n evaluaciones.
long long minByDifference(long long lo, long long hi, const std::function<long long(long long)>& f) {
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;              // mid < hi: f(mid + 1) existe
        if (f(mid + 1) >= f(mid)) hi = mid; else lo = mid + 1;
    }
    return lo;
}
```

```java
// Mínimo de f en [lo, hi], f estrictamente unimodal sobre enteros. 2·log₂ n evaluaciones.
static long minByDifference(long lo, long hi, LongUnaryOperator f) {
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (f.applyAsLong(mid + 1) >= f.applyAsLong(mid)) hi = mid; else lo = mid + 1;
    }
    return lo;
}
```

- **Es `firstTrue`** de `05/04` con el predicado `P(x) = f(x + 1) ≥ f(x)` sobre `[lo, hi)`; si ninguno
  cumple, devuelve `hi`, que es entonces el mínimo.
- **Con una meseta** fuera del mínimo, el predicado deja de ser monótono y falla igual que la ternaria.

> **Veredicto:** sobre enteros, la binaria sobre la diferencia hace lo mismo que la ternaria con menos
> evaluaciones y la plantilla que ya conoces.

---

## 5. 🧱 Búsqueda exponencial

**Qué es.** Para buscar en una secuencia ordenada sin tamaño conocido (o sin cota razonable para la
respuesta), probar las posiciones `1, 2, 4, 8, …` hasta pasarse, y hacer la binaria en el último tramo.

**Por qué es correcto** (el enunciado y una frase): cuando la duplicación para en `2ᵏ`, la respuesta
está en `(2^{k−1}, 2ᵏ]`, porque `2^{k−1}` todavía no cumplía; dentro, la binaria de `05/04`.

**Cómo va**, *lower bound* de 6 en un registro que empieza `[1, 2, 5, 5, 6, 9, …]`:

```text
a[0] = 1 < 6
sonda 1: a[1] = 2 < 6
sonda 2: a[2] = 5 < 6
sonda 4: a[4] = 6 ≥ 6   → la respuesta está en (2, 4]
binaria en [3, 4]: a[3] = 5 < 6 → lo = 4; respuesta 4
```

**Cuánto.** `O(log p)`, con `p` la posición de la respuesta (el teorema de §2), sin importar el
tamaño total.

**La plantilla**, con una función de acceso que devuelve «infinito» más allá del final:

```cpp
#include <functional>
#include <limits>

// Lower bound de x en una secuencia ordenada sin tamaño conocido. at(i) = +∞ fuera de rango. O(log p).
long long exponentialLowerBound(const std::function<long long(long long)>& at, long long x) {
    if (at(0) >= x) return 0;
    long long hi = 1;
    while (at(hi) < x) hi *= 2;                           // al salir, at(hi / 2) < x <= at(hi)
    long long lo = hi / 2 + 1;
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;
        if (at(mid) < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

```java
import java.util.function.LongUnaryOperator;

// Lower bound de x en una secuencia ordenada sin tamaño conocido. at(i) = Long.MAX_VALUE fuera de rango.
static long exponentialLowerBound(LongUnaryOperator at, long x) {
    if (at.applyAsLong(0) >= x) return 0;
    long hi = 1;
    while (at.applyAsLong(hi) < x) hi *= 2;
    long lo = hi / 2 + 1;
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (at.applyAsLong(mid) < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

- **El «infinito» fuera de rango** hace que la duplicación pare al pasarse del final, aunque no se
  conozca el tamaño.
- **`lo = hi / 2 + 1`**: la posición `hi / 2` ya se comprobó y no cumplía.
- **Sobre la respuesta**: la misma duplicación da un `hi` para `firstTrue` cuando el enunciado no acota
  la respuesta; es lo que hace la *galloping* de TimSort ([`05/01`](01-ordenacion-por-comparacion.md)) al mezclar tramos.

**Cuándo sí**: flujos o registros sin tamaño; respuestas probablemente pequeñas dentro de un rango
enorme; mezclar un tramo corto con uno largo. **Cuándo no**: si el tamaño es conocido y la respuesta
puede estar en cualquier sitio, la binaria directa hace los mismos pasos.

> **Veredicto:** la exponencial convierte «no sé dónde acaba» en `O(log p)`: paga por lo lejos que está
> la respuesta, no por el tamaño total.

---

## 6. ⏱️ La tabla de costes

| Técnica | Evaluaciones | Requisito | Lo que la tabla no dice |
|---|---|---|---|
| Ternaria (enteros) | `≈ 3,4 log₂ n` | Unimodal estricta o convexa | Termina con un recorrido de hasta tres candidatos |
| Ternaria (reales) | `2 · vueltas` | Unimodal estricta | Se para por vueltas, como la binaria en reales |
| Binaria sobre la diferencia | `2 log₂ n` | Unimodal estricta, enteros | Es `firstTrue` con otro predicado |
| Exponencial | `O(log p)` | Secuencia ordenada | No necesita conocer el tamaño |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Minimiza `f(x)`» con `f` que baja y luego sube | Ternaria, o binaria sobre la diferencia | Es un extremo, no una frontera |
| Coste que es suma de funciones convexas de `x` | Ternaria sobre `x` | La suma de convexas es convexa |
| «Pico», «montaña», «elemento mayor que sus vecinos» | Binaria sobre la diferencia | Hacia dónde sube dice el lado |
| Tamaño desconocido, flujo o interfaz «`get(i)`» | Exponencial | Duplicar hasta pasarse |
| Respuesta sin cota superior clara | Exponencial y después `firstTrue` | El rango se descubre |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La ternaria funciona en cualquier función con un mínimo» | Necesita unimodalidad estricta (o convexidad); una meseta fuera del mínimo la engaña |
| «La ternaria es más rápida que la binaria porque parte en tres» | Hace dos evaluaciones por vuelta y conserva `2/3`: más evaluaciones que la binaria sobre la diferencia |
| «En enteros, la ternaria acaba cuando `lo = hi`» | Con intervalos pequeños, `m₁` y `m₂` se cruzan; se para con `hi − lo > 2` y se recorre el resto |
| «La exponencial es `O(log n)`» | Es `O(log p)`, con `p` la posición de la respuesta |
| «Para buscar sin tamaño, pruebo `hi = 10¹⁸`» | Funciona si el acceso tolera índices enormes; la exponencial no lo necesita |

---

## 📚 Para profundizar

- **Referencia** — cp-algorithms, [*Ternary Search*](https://cp-algorithms.com/num_methods/ternary_search.html):
  la ternaria con su análisis y la búsqueda de la sección áurea. *Lectura troncal.*
- **Libro** — Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 5: búsqueda binaria
  y sus variantes, con la búsqueda sin tamaño conocido. *Lectura troncal.*
- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 3 (Addison-Wesley), §6.2.1: la búsqueda de
  Fibonacci, pariente de la sección áurea.
- **Referencia** — el documento de TimSort,
  [`listsort.txt`](https://github.com/python/cpython/blob/3.12/Objects/listsort.txt): la *galloping*
  como búsqueda exponencial al mezclar.

---

## 🧠 Preguntas

1. ¿Qué es una función estrictamente unimodal? 🟢
2. ¿Cuántas evaluaciones hace la búsqueda exponencial si la respuesta está en la posición `p`? 🟢
3. En la ternaria, si `f(m₁) < f(m₂)`, ¿qué parte se descarta y por qué? 🟡
4. ¿Por qué la ternaria sobre enteros para con `hi − lo > 2` y recorre el resto? 🟡
5. ¿Qué predicado usas para encontrar el mínimo de una función unimodal con la binaria de `05/04`? 🟡
6. Da una función con un único mínimo global en la que la ternaria falla, y explica qué devuelve. 🟠
7. ¿Por qué una función convexa con una meseta en el mínimo no rompe la ternaria? 🟠
8. Demuestra que la búsqueda exponencial hace `O(log p)` comparaciones. 🟠
9. Compara el número de evaluaciones de la ternaria y de la binaria sobre la diferencia para `n = 10⁹`. 🟠
10. ¿Cómo escribirías la ternaria en reales en Java y en C++ para que dé el mismo resultado, y qué parte depende del redondeo? 🟠
11. ¿Qué es la búsqueda de la sección áurea y qué ahorra respecto de la ternaria? 🔴
12. La suma de dos funciones unimodales, ¿es unimodal? ¿Y la de dos convexas? Demuestra o da un contraejemplo. 🔴

---

## 🧩 Problemas propios

### Coste de transporte

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` almacenes en una recta, en las posiciones `xᵢ`, que envían `wᵢ` cargas cada uno a un centro de
distribución en la posición entera `c`. El coste es `Σ wᵢ · |c − xᵢ|`. Imprime el menor coste posible.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `xᵢ wᵢ`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `|xᵢ| ≤ 10⁹`; `1 ≤ wᵢ ≤ 10⁴`.

```text
Entrada            Salida
3                  8
1 1
5 1
9 1

Entrada            Salida
2                  10
0 3
10 1
```

**Pista 1:** ¿cómo es la gráfica del coste en función de `c`, y qué le pasa entre dos almacenes
consecutivos?

### Registro sin tamaño

**Nivel:** 🟠 · **Formato:** función.

Implementa `long firstAtLeast(Log log, long x)`, que devuelve el primer índice `i` con `log.get(i) ≥ x`.
El registro está ordenado de forma no decreciente y tiene un tamaño `n` desconocido; `log.get(i)`
devuelve `Long.MAX_VALUE` si `i ≥ n`. Puedes llamar a `get` como mucho `2 · ⌈log₂(p + 2)⌉ + 2` veces, con
`p` la respuesta.

- **Restricciones.** `1 ≤ n ≤ 10¹⁸`; los valores, entre 0 y `10¹⁸`.

```text
log = [1, 2, 5, 5, 6, 9]    x = 6     →  4
log = [1, 2, 5, 5, 6, 9]    x = 10    →  6
```

**Pista 1:** ¿qué devuelve `get` en una posición más allá del final, y cómo te ayuda a encontrar un
`hi`?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de escribir una ternaria, pide a una IA un contraejemplo a la unimodalidad de tu
> función con el tamaño mínimo del enunciado: es más rápido que descubrir la meseta con un WA ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Peak Index in a Mountain Array](https://leetcode.com/problems/peak-index-in-a-mountain-array/) | LeetCode | 🟢 | Binaria sobre la diferencia | ¿Qué te dice comparar `arr[mid]` con `arr[mid + 1]`? |
| [ ] | [Find Peak Element](https://leetcode.com/problems/find-peak-element/) | LeetCode | 🟡 | Binaria sobre la diferencia | Si subes hacia la derecha, ¿hay seguro un pico a la derecha? |
| [ ] | [Meeting on the Line](https://codeforces.com/problemset/problem/1730/B) | Codeforces | 🟡 | Ternaria en reales | ¿Cómo es el tiempo máximo en función del punto de reunión? |
| [ ] | [Devu and his Brother](https://codeforces.com/problemset/problem/439/D) | Codeforces | 🟠 | Ternaria sobre un umbral | Fijado el umbral, ¿cuánto cuesta y cómo varía? |
| [ ] | [Searching Local Minimum](https://codeforces.com/problemset/problem/1479/A) | Codeforces | 🟠 | Binaria sobre la diferencia, interactivo | Con 100 consultas y `n ≤ 10⁵`, ¿qué invariante mantienes sobre los extremos? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Ruler (hard version)](https://codeforces.com/problemset/problem/1999/G2) | Codeforces | 🟠 | Ternaria interactiva | ¿Cuántos tramos puedes descartar con una consulta? |
| [ ] | [Maximize!](https://codeforces.com/problemset/problem/939/E) | Codeforces | 🟠 | Ternaria sobre el número de elementos | Fijado el máximo, ¿cuántos de los menores conviene tomar? |
| [ ] | [Weakness and Poorness](https://codeforces.com/problemset/problem/578/C) | Codeforces | 🔴 | Ternaria en reales con Kadane | Fijado `x`, ¿cómo calculas la debilidad, y cómo varía con `x`? |

---

## ✅ Criterio de dominio

- Escribir la ternaria en enteros y en reales, y la binaria sobre la diferencia, sin mirar.
- Dar un contraejemplo con meseta y explicar por qué las convexas sí funcionan.
- Demostrar el `O(log p)` de la búsqueda exponencial.
- Resolver Find Peak Element y Devu and his Brother sin pista 2.

---

**Anterior:** [`05/04` — Búsqueda binaria](04-busqueda-binaria.md) · **Siguiente:** [`05/06` — Simulación](06-simulacion.md) ·
**Relacionado:** [`04/03` — Kadane y subarreglos](../04-secuencias/03-kadane-y-subarreglos.md).
