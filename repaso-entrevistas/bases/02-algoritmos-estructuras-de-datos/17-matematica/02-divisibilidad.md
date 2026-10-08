# 02 — Divisibilidad

> El máximo común divisor con el algoritmo de Euclides y su cota de Lamé, el algoritmo extendido que da los
> coeficientes de la identidad de Bézout, y las ecuaciones diofánticas lineales `ax + by = c` con todas sus
> soluciones: cuándo existen, cuáles son y cuántas caen en un rango. Con el mínimo común múltiplo escrito
> para que no desborde.
>
> **Niveles:** Euclides [A] · extendido [A] · diofánticas [A].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §31.2; Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994),
> cap. 4.
>
> **Asume leído:** [`17/01` — Bits](01-bits.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--euclides) · [4](#4--euclides-extendido) · [5](#5--diofánticas-lineales) · [6](#6-️-la-tabla-de-costes) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Una máquina de cambio solo tiene monedas de 6 y de 10. ¿De cuántas formas puede devolver exactamente 100?
¿Y 101? Probar todas las cantidades de una moneda funciona con 100, pero no con `10¹⁸`. La teoría de la
divisibilidad responde las dos preguntas sin probar: 101 es imposible porque todo lo que se paga con 6 y 10
es múltiplo de `gcd(6, 10) = 2`, y para 100 hay una fórmula que da todas las soluciones a partir de una.

Todo descansa en un algoritmo de hace 2 300 años: Euclides calcula el máximo común divisor en `O(log)` pasos,
y su versión extendida da, además, los coeficientes `x`, `y` con `ax + by = gcd(a, b)`.

> 🧠 **Modelo mental.** Euclides es restar el menor del mayor, pero de golpe: `gcd(a, b) = gcd(b, a mod b)`.
> Cada paso conserva los divisores comunes y encoge los números como mínimo a la mitad cada dos pasos.

Los ejemplos usan `a = 252` y `b = 105`: `gcd = 21`, `mcm = 1 260`.

---

## 2. 📐 La teoría

**Euclides.** `gcd(a, b) = gcd(b, a mod b)` y `gcd(a, 0) = a`. Un divisor de `a` y `b` divide a
`a − qb = a mod b`, y al revés: los dos pares tienen los mismos divisores comunes.

**Cota de Lamé.** Si Euclides da `k` pasos, `b ≥ F_{k+1}` (Fibonacci). Así que los pasos son `O(log_φ b)`,
como mucho unos 92 para números de 64 bits. El peor caso son dos Fibonacci consecutivos: `gcd(89, 55)` da 9
pasos.

*Esbozo.* Cada paso `(a, b) → (b, a mod b)` cumple `a ≥ b + (a mod b)`; leyendo los pasos hacia atrás desde
`(gcd, 0)`, los números crecen como mínimo como la sucesión de Fibonacci.

**Identidad de Bézout.** Para enteros `a`, `b` no ambos nulos, existen `x`, `y` enteros con
`ax + by = gcd(a, b)`; y `gcd(a, b)` es el menor positivo de la forma `ax + by`.

*Prueba.* Sea `d` el menor positivo de la forma `ax + by`. Al dividir `a` entre `d`, el resto también es de
esa forma y es menor que `d`: tiene que ser 0, así que `d | a`; igual `d | b`. Y todo divisor común de `a` y
`b` divide a `ax + by = d`. Por tanto `d = gcd(a, b)`.

**Euclides extendido.** Si `gcd(b, a mod b) = b x′ + (a mod b) y′`, como `a mod b = a − ⌊a/b⌋ b`, se tiene
`gcd(a, b) = a y′ + b (x′ − ⌊a/b⌋ y′)`. Recursivamente desde `(g, 1, 0)` en `b = 0`.

**Diofánticas lineales.** `ax + by = c` tiene solución entera si y solo si `g = gcd(a, b)` divide a `c`. Si
`(x₀, y₀)` es una, todas son

```text
x = x₀ + (b/g) · t,     y = y₀ − (a/g) · t,     t ∈ ℤ
```

**mcm.** `mcm(a, b) · gcd(a, b) = a · b`, pero se calcula como `a / gcd · b`: dividir primero evita que
`a · b` desborde aunque el mcm quepa.

---

## 3. 🧱 Euclides

**Qué es.** `gcd(a, b)` por divisiones sucesivas.

**Por qué es correcto.** El invariante `gcd(a, b) = gcd(b, a mod b)` de §2, y la terminación porque `b`
decrece estrictamente.

**Cómo va**, con 252 y 105:

```text
252 = 2 · 105 + 42
105 = 2 · 42  + 21
 42 = 2 · 21  + 0     → gcd = 21          mcm = 252 / 21 · 105 = 1 260
```

**Cuánto.** `O(log min(a, b))` divisiones.

**La plantilla:**

```cpp
#include <cstdint>
#include <numeric>

// C++17 tiene std::gcd y std::lcm en <numeric>; esta es la versión explícita.
long long gcdLL(long long a, long long b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b) { long long t = a % b; a = b; b = t; }
    return a;
}
long long lcmLL(long long a, long long b) {
    if (a == 0 || b == 0) return 0;
    return a / gcdLL(a, b) * b;                          // dividir antes de multiplicar
}
```

```java
static long gcd(long a, long b) {
    a = Math.abs(a); b = Math.abs(b);
    while (b != 0) { long t = a % b; a = b; b = t; }
    return a;
}

static long lcm(long a, long b) {
    if (a == 0 || b == 0) return 0;
    return a / gcd(a, b) * b;
}
// java.math.BigInteger.gcd para enteros grandes.
```

```python
from math import gcd, lcm                                # lcm con varios argumentos desde 3.9

def gcd_manual(a, b):
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a
```

- **`a / g * b`**, nunca `a * b / g`: con `a, b ≈ 10⁹` el producto cabe en 64 bits, pero con `a, b ≈ 10¹²`
  no, aunque el mcm sí quepa.
- **Varios números**: `gcd(a, b, c) = gcd(gcd(a, b), c)`; el gcd de un arreglo es un plegado, y el de un
  tramo, una tabla dispersa (`09/01`).
- **Negativos**: el signo del resto depende del lenguaje (`%` en C++ y Java puede ser negativo; en Python,
  no); con valores absolutos al principio se evita.
- **`gcd(0, 0)`** es 0 por convenio.

### De la versión ingenua a la buena

**El problema.** Simplificar `10⁵` fracciones `p/q` con `p, q ≤ 10¹⁸`. `252/105` queda `12/5`.

**La versión ingenua:**

```java
// Correcta: probar divisores comunes desde el menor de los dos hacia abajo. Θ(min(p, q)) por fracción.
static long gcdNaive(long p, long q) {
    for (long d = Math.min(p, q); d > 1; d--) if (p % d == 0 && q % d == 0) return d;
    return 1;
}
```

> «Con `10¹⁸` el bucle no termina. Euclides cambia el par por `(q, p mod q)` sin perder divisores comunes,
> y la cota de Lamé dice que en 64 bits son como mucho unos 92 pasos.»

**El camino a la buena.** `g = gcd(p, q)` y `p/g`, `q/g`: `O(log)` por fracción.

**Cuándo sí:** simplificar, comprobar coprimalidad, mcm, ciclos que se repiten (dos periodos coinciden cada
`mcm`), pasos en una circunferencia (`k` saltos de `s` en un círculo de `n` visitan `n / gcd(n, s)`
puntos). **Cuándo no:** si se necesitan los factores primos ([`17/04`](04-primos.md)).

> **Veredicto:** el gcd es Euclides, `O(log)` y diez caracteres de código; el mcm, `a / gcd · b`.

---

## 4. 🧱 Euclides extendido

**Qué es.** Euclides que devuelve, además del gcd, los coeficientes `x`, `y` de la identidad de Bézout.

**Por qué es correcto.** La recurrencia de §2: los coeficientes del par `(b, a mod b)` se traducen a los
de `(a, b)` con un cambio de variable.

**Cómo va**, con 252 y 105, deshaciendo los pasos:

```text
21 = 105 − 2 · 42
   = 105 − 2 · (252 − 2 · 105) = 5 · 105 − 2 · 252
→ x = −2, y = 5:   252 · (−2) + 105 · 5 = 21
```

**Cuánto.** `O(log min(a, b))`, como Euclides.

**La plantilla**, iterativa (sin recursión):

```cpp
#include <tuple>

// Devuelve g = gcd(a, b) y x, y con a·x + b·y = g. a, b ≥ 0.
long long extGcd(long long a, long long b, long long& x, long long& y) {
    long long x0 = 1, y0 = 0, x1 = 0, y1 = 1;
    while (b) {
        long long q = a / b;
        std::tie(a, b) = std::make_tuple(b, a - q * b);
        std::tie(x0, x1) = std::make_tuple(x1, x0 - q * x1);
        std::tie(y0, y1) = std::make_tuple(y1, y0 - q * y1);
    }
    x = x0; y = y0;
    return a;
}
```

```java
// Devuelve {g, x, y} con a·x + b·y = g.
static long[] extGcd(long a, long b) {
    long x0 = 1, y0 = 0, x1 = 0, y1 = 1;
    while (b != 0) {
        long q = a / b, t;
        t = a - q * b; a = b; b = t;
        t = x0 - q * x1; x0 = x1; x1 = t;
        t = y0 - q * y1; y0 = y1; y1 = t;
    }
    return new long[]{a, x0, y0};
}
```

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

- **Los coeficientes son pequeños**: `|x| ≤ b / g` y `|y| ≤ a / g`; no desbordan si `a` y `b` caben.
- **El inverso modular** de `a` módulo `m` (si `gcd(a, m) = 1`) es el `x` de `extGcd(a, m)`, reducido a
  `[0, m)`; es el uso más frecuente ([`17/03`](03-aritmetica-modular.md)).
- **Iterativo** para no depender de la pila; la versión recursiva es más corta y tiene profundidad
  `O(log)`, así que también vale.

### De la versión ingenua a la buena

**El problema.** Encontrar enteros `x`, `y` con `252x + 105y = 21`.

**La versión ingenua:** probar `x` desde `−105` hasta `105` y comprobar si `(21 − 252x)` es divisible entre
105. Correcta (por la cota de los coeficientes), `Θ(b)`.

> «Euclides ya hace las divisiones que necesito; si guardo los cocientes y voy deshaciendo, cada resto se
> escribe como combinación de `a` y `b`. Llevando dos pares de coeficientes, lo hago a la vez.»

**El camino a la buena.** Euclides extendido: `O(log)`.

**Cuándo sí:** inversos modulares con módulo no primo, ecuaciones diofánticas, teorema chino del resto
(`17/03`). **Cuándo no:** si el módulo es primo y solo hace falta el inverso, Fermat es igual de corto
(`17/03`).

> **Veredicto:** el extendido es Euclides con dos pares de coeficientes: da Bézout en `O(log)` y, con él,
> inversos y diofánticas.

---

## 5. 🧱 Diofánticas lineales

**Qué es.** Resolver `ax + by = c` en enteros: decidir si hay solución, dar una y describir todas; y con
restricciones de rango (`x, y ≥ 0`), contarlas o elegir la mejor.

**Por qué es correcto.** Existe solución si y solo si `g | c` (Bézout); una particular es la de Bézout
multiplicada por `c / g`; y dos soluciones difieren en un múltiplo de `(b/g, −a/g)`, porque
`a(x − x′) = −b(y − y′)` y `a/g`, `b/g` son coprimos.

**Cómo va**, `252x + 105y = 63`:

```text
g = 21 | 63 → hay solución;   Bézout por 3: x₀ = −6, y₀ = 15
todas: x = −6 + 5t, y = 15 − 12t   (b/g = 5, a/g = 12)
t = 2: x = 4, y = −9 → 1 008 − 945 = 63 ✓
```

**Cuánto.** `O(log)` para una solución; contar las de un rango es `O(1)` tras ella (dos divisiones con
redondeo correcto).

**La plantilla**, contar las soluciones con `x, y ≥ 0`:

```cpp
// Necesita extGcd de §4. Cuenta las (x, y) enteras no negativas con a·x + b·y = c (a, b > 0, c ≥ 0).
long long extGcd(long long a, long long b, long long& x, long long& y);

long long countNonNegative(long long a, long long b, long long c) {
    long long x, y, g = extGcd(a, b, x, y);
    if (c % g) return 0;
    __int128 x0 = (__int128)x * (c / g), y0 = (__int128)y * (c / g);   // pueden pasar de 64 bits
    long long sx = b / g, sy = a / g;
    // x0 + sx·t ≥ 0  →  t ≥ ceil(−x0 / sx);   y0 − sy·t ≥ 0  →  t ≤ floor(y0 / sy)
    __int128 lo = -x0 >= 0 ? (-x0 + sx - 1) / sx : -((x0) / sx);
    __int128 hi = y0 >= 0 ? y0 / sy : -((-y0 + sy - 1) / sy);
    return hi >= lo ? (long long)(hi - lo + 1) : 0;
}
```

```java
// Con long y Math.floorDiv (redondea hacia −∞); ⌈−x0/sx⌉ = −⌊x0/sx⌋. c hasta 10⁹ para que x0, y0 quepan en long.
static long countNonNegative(long a, long b, long c) {
    long[] e = extGcd(a, b);
    long g = e[0];
    if (c % g != 0) return 0;
    long x0 = e[1] * (c / g), y0 = e[2] * (c / g), sx = b / g, sy = a / g;
    long lo = -Math.floorDiv(x0, sx), hi = Math.floorDiv(y0, sy);
    return Math.max(0, hi - lo + 1);
}
```

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

- **El redondeo es la trampa**: `/` en C++ y Java trunca hacia 0; para `⌈p/q⌉` y `⌊p/q⌋` con negativos
  hacen falta `floorDiv` y `ceilDiv`. En Python, `//` ya redondea hacia `−∞`.
- **El tamaño de `x₀`**: el coeficiente de Bézout por `c/g` puede pasar de 64 bits con `c ≈ 10¹⁸`: `__int128`
  en C++, `BigInteger` en Java, nada en Python.
- **Elegir la mejor**: el número de monedas `x + y = x₀ + y₀ + t (b − a)/g` es lineal en `t`: el óptimo está
  en un extremo del rango de `t`.

### De la versión ingenua a la buena

**El problema.** ¿De cuántas formas se devuelven exactamente `c` con monedas de `a` y `b`? Con 6, 10 y 100,
cuatro: `(0, 10)`, `(5, 7)`, `(10, 4)`, `(15, 1)`.

**La versión ingenua:** para cada `x` de 0 a `c / a`, comprobar si `c − ax` es múltiplo de `b`. Correcta,
`Θ(c / a)`; con `c = 10¹⁸`, imposible.

> «Las soluciones forman una recta de enteros: una particular más `t` veces el paso `(b/g, −a/g)`. Las no
> negativas son un tramo de valores de `t`, y su longitud son dos divisiones.»

**El camino a la buena.** Extendido, solución particular y los dos extremos de `t`: `O(log)`.

**Cuándo sí:** cambio con dos monedas, «¿se puede llegar a `c` con pasos de `a` y `b`?», encuentros de
ciclos, rectas con puntos enteros. **Cuándo no:** con tres o más monedas no hay fórmula cerrada sencilla:
DP ([`12/03`](../12-dp-clasica/03-mochilas.md)) o, con `c` enorme, el problema de Frobenius.

> **Veredicto:** `ax + by = c` tiene solución si y solo si `gcd | c`; todas salen de una con el paso
> `(b/g, −a/g)`, y los rangos, con divisiones bien redondeadas.

---

## 6. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| `gcd(a, b)` | `O(log min(a, b))` | Como mucho ~92 pasos en 64 bits (Lamé) |
| `mcm(a, b)` | `O(log)` | `a / g · b`: dividir primero |
| Euclides extendido | `O(log)` | Coeficientes acotados por `b/g` y `a/g` |
| Una solución de `ax + by = c` | `O(log)` | `x₀` puede necesitar 128 bits |
| Contar soluciones en un rango | `O(log)` | Redondeos de `floor` y `ceil` |

---

## 7. 🧭 Cómo se elige

```text
¿Divisores comunes, simplificar, coprimos? → Euclides
¿mcm? → a / gcd · b
¿Coeficientes de Bézout o un inverso con módulo no primo? → extendido
¿Ecuación ax + by = c? → existe si gcd | c; todas con el paso; rangos con floorDiv/ceilDiv
¿Factores primos? → 17/04
```

> **Regla de entrevista:** cuando escribas el mcm, di en voz alta «divido antes de multiplicar para no
> desbordar»; es lo que separa una respuesta correcta de una que falla con números grandes.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Simplifica», «coprimos», «máximo divisor común» | Euclides | Es la definición |
| «¿Cuándo vuelven a coincidir?» dos ciclos | mcm | El primer múltiplo común |
| «Con pasos de `a` y `b`, ¿se llega a `c`?» | `gcd \| c` | Bézout |
| «De cuántas formas con dos monedas» | Diofántica y rango de `t` | Las soluciones son una recta |
| «Saltos de `s` en un círculo de `n`» | `gcd(n, s)` | Ciclos de longitud `n / gcd` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El mcm es `a · b / gcd`» | Sin cuidar el orden, `a · b` desborda: `a / gcd · b` |
| «Euclides es lento con números grandes» | `O(log)`: unos 92 pasos como mucho en 64 bits |
| «`ax + by = c` siempre tiene solución entera» | Solo si `gcd(a, b)` divide a `c` |
| «Hay una sola solución» | Hay infinitas, separadas por `(b/g, −a/g)` |
| «`−7 / 2` redondea hacia abajo» | En C++ y Java trunca hacia 0 (`−3`); `floorDiv` da `−4` |
| «`gcd` con negativos funciona igual» | El resto puede ser negativo en C++ y Java: valores absolutos primero |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §31.2: Euclides, Lamé y el extendido. *Lectura troncal.*
- **Libro** — Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994), cap. 4:
  divisibilidad y Bézout. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Euclidean algorithm for computing the greatest common divisor*](https://cp-algorithms.com/algebra/euclid-algorithm.html).
- **Referencia** — cp-algorithms, [*Linear Diophantine Equations*](https://cp-algorithms.com/algebra/linear-diophantine-equation.html).

---

## 🧠 Preguntas

1. ¿Por qué `gcd(a, b) = gcd(b, a mod b)`? 🟢
2. ¿Cómo calculas el mcm sin desbordar? 🟢
3. ¿Cuándo tiene solución entera `ax + by = c`? 🟢
4. ¿Qué dice la cota de Lamé y cuál es el peor caso de Euclides? 🟡
5. Enuncia la identidad de Bézout. 🟡
6. Si `(x₀, y₀)` es una solución de `ax + by = c`, ¿cuáles son todas? 🟡
7. ¿Qué pasa con `%` y `/` con negativos en C++, Java y Python, y cómo afecta al gcd y a las diofánticas? 🟡
8. Demuestra la identidad de Bézout. 🟠
9. Deduce la recurrencia de los coeficientes del Euclides extendido. 🟠
10. ¿Cómo cuentas las soluciones no negativas de `ax + by = c` sin recorrerlas? 🟠
11. ¿Cuántos puntos distintos visitas saltando de `s` en `s` en un círculo de `n` posiciones? 🟠
12. ¿Por qué los coeficientes de Bézout que da el extendido no desbordan? 🔴
13. Entre las soluciones no negativas de `ax + by = c`, ¿cómo eliges la de menos monedas? 🔴

---

## 🧩 Problemas propios

### Máximo y mínimo

**Nivel:** 🟢 · **Formato:** programa completo.

Imprime el máximo común divisor y el mínimo común múltiplo de dos enteros positivos.

- **Entrada.** Una línea con `a` y `b`.
- **Salida.** Dos enteros.
- **Restricciones.** `1 ≤ a, b ≤ 10⁹`.

```text
Entrada         Salida
252 105         21 1260

Entrada         Salida
7 13            1 91
```

**Pista 1:** ¿cabe `a · b` en 32 bits? ¿Y el mcm?

### Puntos en el segmento

**Nivel:** 🟡 · **Formato:** programa completo.

¿Cuántos puntos de coordenadas enteras hay en el segmento que une `(x₁, y₁)` y `(x₂, y₂)`, extremos incluidos?

- **Entrada.** Una línea con `x₁ y₁ x₂ y₂`.
- **Salida.** Un entero.
- **Restricciones.** `|coordenadas| ≤ 10⁹`.

```text
Entrada         Salida
0 0 4 6         3

Entrada         Salida
-3 2 5 2        9
```

**Pista 1:** si avanzas desde un extremo al siguiente punto entero, ¿qué fracción del vector recorres?

### Pagar con menos monedas

**Nivel:** 🟠 · **Formato:** programa completo.

Con monedas de valor `a` y `b` (tantas como se quiera), paga exactamente `c` usando el menor número de
monedas, e imprime ese número; `-1` si no se puede.

- **Entrada.** Una línea con `a`, `b` y `c`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ a, b ≤ 10⁹`; `0 ≤ c ≤ 10¹⁸`.

```text
Entrada         Salida
6 10 100        10

Entrada         Salida
3 5 7           -1
```

**Pista 1:** si todas las soluciones son `x₀ + (b/g) t`, `y₀ − (a/g) t`, ¿cómo cambia `x + y` al aumentar
`t`?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con una diofántica, comprueba tu solución particular sustituyéndola
> en la ecuación, y tus extremos de `t` con un bucle en un caso pequeño. Si una IA te ayuda, que sea a
> revisar los redondeos ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [ChocolatesByNumbers](https://app.codility.com/programmers/lessons/12-euclidean_algorithm/chocolates_by_numbers/) | Codility | 🟢 | Saltos en un círculo | ¿Cuántas posiciones distintas visitas saltando `M` en un círculo de `N`? |
| [ ] | [Find Greatest Common Divisor of Array](https://leetcode.com/problems/find-greatest-common-divisor-of-array/) | LeetCode | 🟢 | gcd | ¿De qué dos números del arreglo te piden el gcd? |
| [ ] | [Greatest Common Divisor of Strings](https://leetcode.com/problems/greatest-common-divisor-of-strings/) | LeetCode | 🟢 | gcd de longitudes | Si `s + t ≠ t + s`, ¿puede haber divisor común? |
| [ ] | [X of a Kind in a Deck of Cards](https://leetcode.com/problems/x-of-a-kind-in-a-deck-of-cards/) | LeetCode | 🟢 | gcd de frecuencias | ¿Qué tamaño de grupo divide a todas las frecuencias? |
| [ ] | [CommonPrimeDivisors](https://app.codility.com/programmers/lessons/12-euclidean_algorithm/common_prime_divisors/) | Codility | 🟡 | gcd repetido | Si divides `a` por `gcd(a, b)` una y otra vez, ¿qué te queda? |
| [ ] | [Water and Jug Problem](https://leetcode.com/problems/water-and-jug-problem/) | LeetCode | 🟡 | Bézout | ¿Qué cantidades se pueden medir con dos jarras? |
| [ ] | [Common Divisors](https://cses.fi/problemset/task/1081) | CSES | 🟡 | Contar múltiplos por divisor | Para cada `d`, ¿cuántos números del arreglo son múltiplos? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Check If It Is a Good Array](https://leetcode.com/problems/check-if-it-is-a-good-array/) | LeetCode | 🔴 | Bézout con varios números | ¿Qué gcd tiene que tener el arreglo para formar 1? |
| [ ] | [Candy Distribution](https://open.kattis.com/problems/candydistribution) | Kattis | 🟠 | Extendido | Si cada bolsa tiene `C` caramelos y sobra uno, ¿qué ecuación es? |
| [ ] | [Nth Magical Number](https://leetcode.com/problems/nth-magical-number/) | LeetCode | 🔴 | mcm y binaria | ¿Cuántos múltiplos de `a` o de `b` hay hasta `x`? |
| [ ] | [Billiard](https://codeforces.com/problemset/problem/982/E) | Codeforces | 🔴 | Reflexiones y diofántica | Si despliegas la mesa en espejos, ¿qué ecuación da la tronera? |

---

## ✅ Criterio de dominio

- Escribir gcd, mcm y el extendido en los tres lenguajes sin mirar.
- Demostrar Bézout y la forma de todas las soluciones de `ax + by = c`.
- Contar soluciones en un rango con los redondeos correctos.
- Resolver Water and Jug Problem y CommonPrimeDivisors sin pista 2.

---

**Anterior:** [`17/01` — Bits](01-bits.md) · **Siguiente:** [`17/03` — Aritmética modular](03-aritmetica-modular.md) ·
**Relacionado:** [`09/01` — *Sparse table*](../09-consultas-sobre-rangos/01-sparse-table.md).
