# 05 — Combinatoria

> Contar con fórmulas en lugar de con bucles: el coeficiente binomial módulo `p` con factoriales e inversos
> precalculados, las estrellas y barras para repartos, el teorema de Lucas para `n` enorme y `p` pequeño,
> los números de Catalan, la inclusión-exclusión y, en ficha, el lema de Burnside para contar salvo
> simetrías.
>
> **Niveles:** `nCr` con factoriales [A] · estrellas y barras [A] · Lucas [B] · Catalan [B] ·
> inclusión-exclusión [B] · Burnside [C].
>
> **📚 Lectura troncal:** Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994),
> cap. 5; Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 11.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--ncr-con-factoriales) · [4](#4--estrellas-y-barras) · [5](#5--lucas) · [6](#6--catalan) · [7](#7--inclusión-exclusión) · [8](#8--burnside) · [9](#9-️-la-tabla-de-costes) · [10](#10--cómo-se-elige) · [11](#11--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

¿Cuántos caminos de esquina a esquina hay en una rejilla de `10⁶ × 10⁶`, moviéndose solo a la derecha y
hacia abajo, módulo `10⁹ + 7`? La DP de [`12/05`](../12-dp-clasica/05-rejillas-e-intervalos.md) necesita `10¹²` celdas. Pero cada camino es una secuencia de
`2·10⁶ − 2` movimientos con exactamente `10⁶ − 1` a la derecha: la respuesta es un coeficiente binomial, y
con factoriales precalculados se obtiene en `O(1)`.

La combinatoria sustituye DP y búsquedas por fórmulas: elegir, repartir, ordenar con restricciones, contar
lo que cumple al menos una condición, contar salvo rotaciones. Lo que hay que dominar es reconocer cuál
fórmula es y calcularla módulo `p` sin desbordar ni dividir.

> 🧠 **Modelo mental.** Contar es poner en biyección con algo que ya se sabe contar: un camino en la rejilla
> es una palabra de `D` y `B`; un reparto, una fila de estrellas con barras; una secuencia de paréntesis, un
> camino que no baja de cero.

Los ejemplos usan `n = 10` (con `C(10, 3) = 120`) y el módulo `p = 10⁹ + 7`.

---

## 2. 📐 La teoría

**Coeficiente binomial.** `C(n, k) = n! / (k! (n − k)!)`, el número de subconjuntos de `k` elementos de un
conjunto de `n`. Identidades: Pascal `C(n, k) = C(n − 1, k − 1) + C(n − 1, k)`, simetría `C(n, k) = C(n, n − k)`
y Vandermonde `C(m + n, k) = Σ C(m, i) C(n, k − i)`.

**Módulo `p` primo.** Como `p` es primo y `n < p`, los factoriales son invertibles: `C(n, k) ≡ n! · (k!)⁻¹ ·
((n − k)!)⁻¹`. Con `fact` e `invFact` precalculados (un Fermat y `n` productos, [`17/03`](03-aritmetica-modular.md)), cada consulta es
`O(1)`.

**Estrellas y barras.** El número de soluciones de `x₁ + … + x_k = n` con `xᵢ ≥ 0` es `C(n + k − 1, k − 1)`:
cada solución es una fila de `n` estrellas y `k − 1` barras. Con `xᵢ ≥ 1`, `C(n − 1, k − 1)`; con
`xᵢ ≥ aᵢ`, se resta `Σ aᵢ` y se cuenta con `≥ 0`.

**Lucas.** Para `p` primo, si `n` y `k` en base `p` son `n = Σ nᵢ pⁱ`, `k = Σ kᵢ pⁱ`, entonces
`C(n, k) ≡ Π C(nᵢ, kᵢ) (mod p)`. Sirve cuando `n ≥ p` y `p` es pequeño (ahí `n!` es 0 módulo `p` y no hay
inversos).

**Catalan.** `Cₙ = C(2n, n) / (n + 1) = C(2n, n) − C(2n, n + 1)`: `1, 1, 2, 5, 14, 42, 132, …`. Cuenta las
secuencias de `n` pares de paréntesis bien formadas, los árboles binarios de `n` nodos, las triangulaciones
de un polígono de `n + 2` lados y los caminos monótonos que no cruzan la diagonal.

*La reflexión.* De los `C(2n, n)` caminos de `n` subidas y `n` bajadas, los malos (que bajan de 0) se reflejan
desde el primer punto donde tocan `−1`, y quedan en biyección con los caminos de `n + 1` bajadas y `n − 1`
subidas: `C(2n, n + 1)`.

**Inclusión-exclusión.** `|A₁ ∪ … ∪ A_k| = Σ |Aᵢ| − Σ |Aᵢ ∩ Aⱼ| + … ± |A₁ ∩ … ∩ A_k|`: sumar sobre los
`2^k − 1` subconjuntos no vacíos con signo `(−1)^(tamaño+1)`. Ejemplo: los desarreglos (permutaciones sin
puntos fijos) son `D(n) = n! Σ (−1)^i / i!`: `D(4) = 9`.

**Burnside.** El número de clases de objetos salvo un grupo de simetrías `G` es la media, sobre `g ∈ G`, de
los objetos que `g` deja fijos: `|X/G| = (1/|G|) Σ |Fix(g)|`.

---

## 3. 🧱 `nCr` con factoriales

**Qué es.** Precalcular `fact[i]` e `invFact[i]` hasta el `n` máximo y responder cada `C(n, k)` con dos
productos.

**Por qué es correcto.** `C(n, k) = n! / (k! (n − k)!)` y, con `p` primo y `n < p`, los factoriales tienen
inverso; dividir es multiplicar por él.

**Cómo va**, `C(10, 3)`:

```text
fact[10] = 3 628 800    invFact[3] = 6⁻¹    invFact[7] = 5 040⁻¹
C(10, 3) = 3 628 800 · 6⁻¹ · 5 040⁻¹ ≡ 120        caminos en una rejilla 3 × 4: C(5, 2) = 10
```

**Cuánto.** `Θ(N + log p)` el preproceso; `O(1)` cada consulta.

**La plantilla:**

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

long long powMod(long long a, long long e, long long m);   // 17/03

struct Binomial {
    std::vector<long long> fact, invFact;
    explicit Binomial(int n) : fact(n + 1), invFact(n + 1) {
        fact[0] = 1;
        for (int i = 1; i <= n; i++) fact[i] = fact[i - 1] * i % MOD;
        invFact[n] = powMod(fact[n], MOD - 2, MOD);         // un solo Fermat
        for (int i = n; i > 0; i--) invFact[i - 1] = invFact[i] * i % MOD;
    }
    long long C(int n, int k) const {
        if (k < 0 || k > n) return 0;
        return fact[n] * invFact[k] % MOD * invFact[n - k] % MOD;
    }
};
```

```java
static final long MOD = 1_000_000_007L;
static long[] fact, invFact;

static void initBinomial(int n) {
    fact = new long[n + 1]; invFact = new long[n + 1];
    fact[0] = 1;
    for (int i = 1; i <= n; i++) fact[i] = fact[i - 1] * i % MOD;
    invFact[n] = powMod(fact[n], MOD - 2, MOD);             // powMod de 17/03
    for (int i = n; i > 0; i--) invFact[i - 1] = invFact[i] * i % MOD;
}

static long C(int n, int k) {
    if (k < 0 || k > n) return 0;
    return fact[n] * invFact[k] % MOD * invFact[n - k] % MOD;
}
```

```python
MOD = 10**9 + 7

def init_binomial(n):
    fact = [1] * (n + 1)
    for i in range(1, n + 1):
        fact[i] = fact[i - 1] * i % MOD
    inv_fact = [1] * (n + 1)
    inv_fact[n] = pow(fact[n], MOD - 2, MOD)
    for i in range(n, 0, -1):
        inv_fact[i - 1] = inv_fact[i] * i % MOD
    return fact, inv_fact

def C(n, k, fact, inv_fact):
    if k < 0 or k > n:
        return 0
    return fact[n] * inv_fact[k] % MOD * inv_fact[n - k] % MOD
```

- **`k < 0` o `k > n` devuelve 0**: muchas fórmulas lo usan sin comprobarlo antes.
- **Sin módulo** (valores exactos hasta `10¹⁸`): `C(n, k)` por productos sucesivos `r = r · (n − i) / (i + 1)`,
  que siempre es exacto; Python, además, con `math.comb`.
- **`n ≥ p`**: los factoriales son 0 módulo `p`; hace falta Lucas (§5).

### De la versión ingenua a la buena

**El problema.** Caminos monótonos en una rejilla de `R × C` que pasan por una casilla obligatoria `(a, b)`,
con `R, C ≤ 10⁶`, módulo `10⁹ + 7`.

**La versión ingenua:** la DP de caminos de `12/05` hasta `(a, b)` y desde `(a, b)`. Correcta,
`Θ(R · C)` = `10¹²`.

> «Un camino hasta `(a, b)` es elegir cuáles de los `a + b` movimientos van hacia abajo: `C(a + b, a)`. Y
> desde ahí, lo mismo con lo que falta. El total es el producto de dos binomiales, con factoriales
> precalculados hasta `R + C`.»

**El camino a la buena.** `C(a + b, a) · C((R − 1 − a) + (C − 1 − b), R − 1 − a)`: `Θ(R + C)` de preproceso y
`O(1)` la respuesta.

**Cuándo sí:** elegir sin orden, caminos monótonos, coeficientes de potencias, probabilidades con conteos.
**Cuándo no:** con obstáculos arbitrarios en la rejilla (DP, o inclusión-exclusión sobre pocos obstáculos).

> **Veredicto:** con `p` primo, `C(n, k)` son tres productos con factoriales e inversos precalculados; el
> inverso del mayor factorial basta para todos.

---

## 4. 🧱 Estrellas y barras

**Qué es.** Contar las soluciones enteras de `x₁ + … + x_k = n` con cotas inferiores, como `C(n + k − 1, k − 1)`
tras restar los mínimos.

**Por qué es correcto.** Biyección: una solución con `xᵢ ≥ 0` es una fila de `n` estrellas separadas en `k`
grupos por `k − 1` barras; elegir las posiciones de las barras entre `n + k − 1` es `C(n + k − 1, k − 1)`.

**Cómo va**:

```text
10 caramelos entre 3 niños (≥ 0 cada uno):   C(12, 2) = 66
… con al menos uno cada uno:                  C(9, 2) = 36
sucesiones no decrecientes de 3 valores en 1..4: C(6, 3) = 20  (las «subidas» son estrellas)
```

**Cuánto.** `O(1)` con el `nCr` de §3.

**La plantilla.** Es el `nCr` de §3:

```text
starsAndBars(n, k) = C(n + k − 1, k − 1)                 // x₁ + … + x_k = n, xᵢ ≥ 0
con mínimos aᵢ:      C(n − Σaᵢ + k − 1, k − 1)          // 0 si n − Σaᵢ < 0
con máximos:         inclusión-exclusión sobre los que pasan del máximo (§7)
```

- **Mínimos**: se «regalan» los `aᵢ` y se reparte el resto.
- **Máximos**: no hay fórmula directa; inclusión-exclusión sobre el conjunto de variables que se pasan.
- **Objetos distintos en cajas**: no es estrellas y barras: `k^n` (sin restricciones) o Stirling.

### De la versión ingenua a la buena

**El problema.** ¿Cuántas sucesiones no decrecientes de longitud `k` hay con valores entre 1 y `m`? Con
`k = 4` y `m = 3`, 15.

**La versión ingenua:** DP `dp[i][v]` = sucesiones de longitud `i` que terminan en `v`, sumando los `dp[i − 1][u]`
con `u ≤ v`. Correcta, `Θ(k · m)` con prefijos.

> «Una sucesión no decreciente queda determinada por cuántas veces aparece cada valor: `c₁ + … + c_m = k`
> con `cᵢ ≥ 0`. Estrellas y barras: `C(k + m − 1, m − 1)`.»

**El camino a la buena.** `C(k + m − 1, m − 1)`: `O(1)`.

**Cuándo sí:** repartos de objetos iguales en cajas distintas, multiconjuntos, sucesiones no decrecientes,
soluciones de ecuaciones con sumas fijas. **Cuándo no:** con objetos distintos, o con máximos (sin
inclusión-exclusión).

> **Veredicto:** repartir `n` iguales en `k` cajas es `C(n + k − 1, k − 1)`; los mínimos se restan antes.

---

## 5. 🧱 Lucas

**Qué es.** `C(n, k) mod p` para `p` primo pequeño y `n` enorme, como producto de binomiales de las cifras de
`n` y `k` en base `p`.

**Por qué es correcto.** El teorema de Lucas (§2), que sale de `(1 + x)^p ≡ 1 + x^p (mod p)` comparando
coeficientes en `(1 + x)^n = Π ((1 + x)^(pⁱ))^(nᵢ)`.

**Cómo va.** `C(7, 3) mod 3`: `7 = 21₃`, `3 = 10₃`, así que `C(2, 1) · C(1, 0) = 2`, y en efecto
`C(7, 3) = 35 ≡ 2`. `C(10, 3) mod 3`: `10 = 101₃`, `3 = 010₃`, y `C(0, 1) = 0`: el resultado es 0.

**Cuánto.** `O(p)` el preproceso y `O(log_p n)` cada consulta.

**La plantilla:**

```cpp
#include <vector>

// C(n, k) mod p con p primo pequeño (p ≤ 10⁶): factoriales hasta p − 1 y Lucas.
struct Lucas {
    long long p;
    std::vector<long long> fact, invFact;
    explicit Lucas(long long prime) : p(prime), fact(prime), invFact(prime) {
        fact[0] = 1;
        for (long long i = 1; i < p; i++) fact[i] = fact[i - 1] * i % p;
        invFact[p - 1] = p - 1;                                          // Wilson: (p − 1)! ≡ −1
        for (long long i = p - 1; i > 0; i--) invFact[i - 1] = invFact[i] * i % p;
    }
    long long small(long long n, long long k) const {
        if (k < 0 || k > n) return 0;
        return fact[n] * invFact[k] % p * invFact[n - k] % p;
    }
    long long C(long long n, long long k) const {
        long long r = 1;
        while (n > 0 || k > 0) {
            r = r * small(n % p, k % p) % p;
            if (r == 0) return 0;
            n /= p; k /= p;
        }
        return r;
    }
};
```

```java
static long luP;
static long[] luFact, luInv;

static void initLucas(int p) {
    luP = p; luFact = new long[p]; luInv = new long[p];
    luFact[0] = 1;
    for (int i = 1; i < p; i++) luFact[i] = luFact[i - 1] * i % p;
    luInv[p - 1] = p - 1;                                                  // Wilson
    for (int i = p - 1; i > 0; i--) luInv[i - 1] = luInv[i] * i % p;
}

static long lucas(long n, long k) {
    long r = 1;
    while (n > 0 || k > 0) {
        int ni = (int) (n % luP), ki = (int) (k % luP);
        if (ki > ni) return 0;
        r = r * luFact[ni] % luP * luInv[ki] % luP * luInv[ni - ki] % luP;
        n /= luP; k /= luP;
    }
    return r;
}
```

**Cuándo sí:** módulo primo pequeño (2, 3, `10⁵ + 3`…) con `n` mayor que `p`; paridad de binomiales
(`C(n, k)` es impar si y solo si `k & n == k`). **Cuándo no:** si `n < p`, el `nCr` de §3 basta; con módulo
compuesto, Lucas por cada potencia de primo y TCR (`17/03`).

> **Veredicto:** con `n ≥ p` y `p` pequeño, Lucas parte `C(n, k)` en binomiales de las cifras en base `p`.

---

## 6. 🧱 Catalan

**Qué es.** La sucesión `Cₙ = C(2n, n)/(n + 1)` y su recurrencia `Cₙ₊₁ = Σ Cᵢ Cₙ₋ᵢ`.

**Por qué es correcto.** La reflexión de §2 (fórmula cerrada) y la descomposición por el primer retorno a 0
(recurrencia): una secuencia bien formada es `( A ) B` con `A` y `B` bien formadas.

**Cómo va.** `C₀..C₆ = 1, 1, 2, 5, 14, 42, 132`. Las 5 secuencias de 3 pares: `((()))`, `(()())`,
`(())()`, `()(())`, `()()()`.

**Cuánto.** `O(1)` con el `nCr` de §3; `O(n²)` con la recurrencia (útil sin módulo primo).

**La plantilla:**

```cpp
// Con el Binomial de §3: C(2n, n) · inv(n + 1), o C(2n, n) − C(2n, n + 1).
long long catalan(const Binomial& b, int n) {
    return (b.C(2 * n, n) - b.C(2 * n, n + 1) + MOD) % MOD;
}
```

```java
static long catalan(int n) { return (C(2 * n, n) - C(2 * n, n + 1) + MOD) % MOD; }   // initBinomial(2n)
```

- **La resta** `C(2n, n) − C(2n, n + 1)` evita el inverso de `n + 1` y es la forma que sale de la reflexión.
- **Variantes con la reflexión**: caminos que no tocan una línea, secuencias con prefijo dado (Bracket
  Sequences II).

**Cuándo sí:** paréntesis, árboles binarios, triangulaciones, caminos bajo la diagonal, montañas.
**Cuándo no:** si las restricciones no son «no bajar de cero»: DP.

> **Veredicto:** Catalan es `C(2n, n) − C(2n, n + 1)`, por reflexión; reconocerlo es la mitad del trabajo.

---

## 7. 🧱 Inclusión-exclusión

**Qué es.** Contar los elementos que cumplen **al menos una** de `k` condiciones (o ninguna) sumando, con
signos alternos, los que cumplen cada subconjunto de condiciones a la vez.

**Por qué es correcto.** Un elemento que cumple exactamente `t ≥ 1` condiciones se cuenta
`Σ_{i=1}^{t} (−1)^(i+1) C(t, i) = 1` veces (por el binomio de `(1 − 1)^t = 0`).

**Cómo va.** Números `≤ 100` divisibles por 2, 3 o 5: `50 + 33 + 20 − 16 − 10 − 6 + 3 = 74`.
Desarreglos de 4: `4! − C(4,1) 3! + C(4,2) 2! − C(4,3) 1! + C(4,4) 0! = 24 − 24 + 12 − 4 + 1 = 9`.

**Cuánto.** `Θ(2^k · coste de la intersección)`; con `k ≤ 20`, unos `10⁶` subconjuntos.

**La plantilla**, múltiplos de alguno de `k` números hasta `N`:

```cpp
#include <numeric>
#include <vector>

// Cuántos x en [1, N] son múltiplos de al menos un ns[i]. El mcm se corta si pasa de N.
long long multiplesOfAny(long long N, const std::vector<long long>& ns) {
    int k = ns.size();
    long long total = 0;
    for (int mask = 1; mask < (1 << k); mask++) {
        long long l = 1;
        bool tooBig = false;
        for (int i = 0; i < k && !tooBig; i++)
            if (mask >> i & 1) {
                long long g = std::gcd(l, ns[i]);
                if ((__int128)(l / g) * ns[i] > N) tooBig = true;   // ya no hay múltiplos
                else l = l / g * ns[i];
            }
        if (tooBig) continue;
        total += (__builtin_popcount(mask) & 1) ? N / l : -(N / l);
    }
    return total;
}
```

```java
static long multiplesOfAny(long N, long[] ns) {
    int k = ns.length;
    long total = 0;
    for (int mask = 1; mask < (1 << k); mask++) {
        long l = 1;
        boolean tooBig = false;
        for (int i = 0; i < k && !tooBig; i++)
            if ((mask >> i & 1) == 1) {
                long g = gcd(l, ns[i]);                   // gcd de 17/02
                if (l / g > N / ns[i]) tooBig = true;     // l/g · ns[i] > N sin desbordar
                else l = l / g * ns[i];
            }
        if (tooBig) continue;
        total += (Integer.bitCount(mask) & 1) == 1 ? N / l : -(N / l);
    }
    return total;
}
```

- **El mcm se corta** en cuanto supera `N`: sus términos son 0 y evita desbordamientos.
- **Desarreglos** también con la recurrencia `D(n) = (n − 1)(D(n − 1) + D(n − 2))`.
- **Con máximos en estrellas y barras**: el subconjunto `S` de variables que se pasan resta `(máx + 1)` a
  cada una de `S` antes de contar.

**Cuándo sí:** «al menos uno», «ninguno», condiciones que se solapan, coprimos con `n` en un rango (sobre sus
factores primos), repartos con máximos. **Cuándo no:** con `k` grande (más de 25): la intersección suele
tener estructura (Möbius, DP).

> **Veredicto:** inclusión-exclusión es sumar sobre los subconjuntos de condiciones con signo alterno;
> `2^k` términos, y el mcm (o la intersección) cortado a tiempo.

---

## 8. 🧱 Burnside

**Qué resuelve.** Contar configuraciones distintas salvo simetrías: collares (rotaciones), pulseras
(rotaciones y reflexiones), coloraciones de un tablero salvo giros.

**Qué garantiza.** `|X/G| = (1/|G|) Σ_{g ∈ G} |Fix(g)|`. Para collares de `n` cuentas con `k` colores, la
rotación de `i` posiciones fija `k^gcd(i, n)` coloraciones: `(1/n) Σ_{i=0}^{n−1} k^gcd(i, n)`. Para `n = 4` y
`k = 2`: `(16 + 2 + 4 + 2)/4 = 6`.

**Cuánto.** `O(|G| · coste de contar fijos)`; para collares, `O(n log n)` (o agrupando por divisores, `O(d(n)
log n)`).

**Cómo reconocerlo.** «Distintos salvo rotación / reflexión / giro», «collares», «pulseras».

**Si no te la sabes.** Con `n` pequeño, generar todas las configuraciones y quedarse con la canónica
(mínima entre sus simétricas).

**Dónde está entera.** Graham, Knuth y Patashnik, cap. 4 (collares) y la teoría de grupos de cualquier texto
de álgebra; cp-algorithms, [*Burnside's lemma / Pólya enumeration theorem*](https://cp-algorithms.com/combinatorics/burnside.html).

---

## 9. ⏱️ La tabla de costes

| Técnica | Preproceso | Consulta | Lo que la tabla no dice |
|---|---|---|---|
| `nCr` con factoriales | `Θ(N + log p)` | `O(1)` | Solo con `n < p` y `p` primo |
| Triángulo de Pascal | `Θ(N²)` | `O(1)` | Vale con cualquier módulo |
| Estrellas y barras | El de `nCr` | `O(1)` | Máximos con inclusión-exclusión |
| Lucas | `Θ(p)` | `O(log_p n)` | `p` primo pequeño |
| Catalan | El de `nCr` | `O(1)` | `C(2n, n) − C(2n, n + 1)` |
| Inclusión-exclusión | — | `Θ(2^k · k)` | `k ≤ 20` |
| Burnside (collares) | — | `O(n log n)` | Por divisores, menos |

---

## 10. 🧭 Cómo se elige

```text
¿Elegir k de n, módulo primo grande? → nCr con factoriales
¿Módulo primo pequeño y n ≥ p? → Lucas
¿Módulo compuesto o sin módulo y n ≤ 5 000? → triángulo de Pascal
¿Repartir iguales en cajas? → estrellas y barras (máximos: + inclusión-exclusión)
¿Paréntesis, árboles binarios, caminos bajo la diagonal? → Catalan
¿«Al menos uno de», «ninguno de» con condiciones solapadas? → inclusión-exclusión
¿«Distintos salvo rotación»? → Burnside
```

> **Regla de entrevista:** antes de escribir una DP de conteo, pregúntate si hay una biyección con algo que
> se cuenta con un binomial; decirlo en voz alta muestra el razonamiento.

---

## 11. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «De cuántas formas elegir», «subconjuntos de tamaño `k`» | `nCr` | Elegir sin orden |
| «Repartir objetos iguales», «sucesiones no decrecientes» | Estrellas y barras | Biyección con estrellas y barras |
| «Módulo un primo pequeño» y `n` mayor | Lucas | Cifras en base `p` |
| «Paréntesis bien formados», «árboles binarios», «no cruza la diagonal» | Catalan | Reflexión |
| «Al menos uno de», «ninguno de» | Inclusión-exclusión | Uniones con solapes |
| «Distintos salvo rotación o volteo» | Burnside | Media de puntos fijos |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`nCr` se calcula con la fórmula y luego módulo» | `n!` desborda mucho antes; se calcula módulo `p` con inversos de los factoriales |
| «`C(n, k) mod p` con factoriales vale siempre» | Si `n ≥ p`, `n!` es 0 módulo `p`: Lucas |
| «Repartir `n` objetos en `k` cajas es `C(n + k − 1, k − 1)`» | Solo si los objetos son iguales; distintos, `kⁿ` |
| «Inclusión-exclusión con el producto de los números» | Con el **mcm**: 4 y 6 tienen en común los múltiplos de 12, no de 24 |
| «Catalan es `C(2n, n)/(n + 1)` con división entera módulo `p`» | Con el inverso, o `C(2n, n) − C(2n, n + 1)` |

---

## 📚 Para profundizar

- **Libro** — Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994), cap. 5:
  coeficientes binomiales e identidades. *Lectura troncal.*
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 11:
  combinatoria, inclusión-exclusión y Burnside. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Binomial Coefficients*](https://cp-algorithms.com/combinatorics/binomial-coefficients.html).
- **Referencia** — cp-algorithms, [*Catalan Numbers*](https://cp-algorithms.com/combinatorics/catalan-numbers.html).
- **Referencia** — cp-algorithms, [*The Inclusion-Exclusion Principle*](https://cp-algorithms.com/combinatorics/inclusion-exclusion.html).
- **Referencia** — cp-algorithms, [*Stars and bars*](https://cp-algorithms.com/combinatorics/stars_and_bars.html).

---

## 🧠 Preguntas

1. ¿Cómo calculas `C(n, k) mod p` en `O(1)` por consulta? 🟢
2. ¿Cuántas soluciones tiene `x₁ + … + x_k = n` con `xᵢ ≥ 0`, y con `xᵢ ≥ 1`? 🟢
3. ¿Cuántos caminos monótonos hay en una rejilla de `R × C`? 🟢
4. ¿Por qué basta un Fermat para todos los inversos de los factoriales? 🟡
5. ¿Qué dice el teorema de Lucas y cuándo hace falta? 🟡
6. ¿Qué cuentan los números de Catalan? Da tres ejemplos. 🟡
7. ¿Cómo cuentas los números `≤ N` divisibles por al menos uno de `k` números? 🟡
8. Demuestra la fórmula de Catalan con el argumento de la reflexión. 🟠
9. ¿Por qué un elemento que cumple `t` condiciones se cuenta una vez en la inclusión-exclusión? 🟠
10. ¿Cómo cuentas repartos con máximos por caja? 🟠
11. ¿Cuántos desarreglos de `n` hay y cómo se calcula? 🟠
12. ¿Cómo calculas `C(n, k)` módulo un número compuesto? 🔴
13. ¿Cuántos collares distintos de `n` cuentas con `k` colores hay salvo rotación? Justifica con Burnside. 🔴

---

## 🧩 Problemas propios

### Repartos con mínimos

**Nivel:** 🟡 · **Formato:** programa completo.

Se reparten `n` caramelos iguales entre `k` niños; el niño `i` tiene que recibir al menos `aᵢ`. ¿De cuántas
formas? Módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n` y `k`. Una línea con `a₁ … a_k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `1 ≤ k ≤ 10⁶`; `0 ≤ aᵢ ≤ 10⁶`.

```text
Entrada     Salida
10 3        15
1 2 3

Entrada     Salida
5 2         0
3 3
```

**Pista 1:** si cada niño recibe primero su mínimo, ¿cuánto queda por repartir y sin qué restricción?

### Múltiplos de alguno

**Nivel:** 🟠 · **Formato:** programa completo.

¿Cuántos enteros de `1` a `N` son múltiplos de al menos uno de los `k` números dados?

- **Entrada.** Una línea con `N` y `k`. Una línea con los `k` números.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ N ≤ 10¹⁸`; `1 ≤ k ≤ 20`; los números entre 1 y `10¹⁸`.

```text
Entrada     Salida
100 3       74
2 3 5

Entrada     Salida
100 2       33
4 6
```

**Pista 1:** ¿cuántos múltiplos comunes de 4 y 6 hay hasta 100, y de qué número son múltiplos?

### Pulseras

**Nivel:** 🔴 · **Formato:** programa completo.

¿Cuántas pulseras distintas de `n` cuentas se pueden hacer con `k` colores, considerando iguales las que se
obtienen girando o dando la vuelta? Módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n` y `k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `1 ≤ k ≤ 10⁹`.

```text
Entrada     Salida
4 2         6

Entrada     Salida
5 3         39
```

**Pista 1:** el grupo tiene `2n` simetrías: `n` giros y `n` volteos. ¿Cuántas coloraciones deja fijas cada
volteo, según `n` sea par o impar?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con una fórmula de conteo, compárala con una fuerza bruta para `n ≤ 8`:
> si los primeros valores coinciden, la fórmula suele estar bien. Si una IA te ayuda, que sea a encontrar la
> biyección, no a darte la fórmula ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Pascal's Triangle](https://leetcode.com/problems/pascals-triangle/) | LeetCode | 🟢 | Identidad de Pascal | ¿Cómo sale cada fila de la anterior? |
| [ ] | [Binomial Coefficients](https://cses.fi/problemset/task/1079) | CSES | 🟡 | `nCr` con factoriales | Con `10⁵` consultas, ¿qué precalculas? |
| [ ] | [Creating Strings II](https://cses.fi/problemset/task/1715) | CSES | 🟡 | Multinomial | Si una letra aparece `c` veces, ¿por qué divides? |
| [ ] | [Distributing Apples](https://cses.fi/problemset/task/1716) | CSES | 🟡 | Estrellas y barras | ¿Cuántas barras separan a `n` niños? |
| [ ] | [Unique Binary Search Trees](https://leetcode.com/problems/unique-binary-search-trees/) | LeetCode | 🟡 | Catalan | Si fijas la raíz, ¿cuántos árboles hay a cada lado? |
| [ ] | [Christmas Party](https://cses.fi/problemset/task/1717) | CSES | 🟠 | Desarreglos | ¿Qué recurrencia cumple el número de desarreglos? |
| [ ] | [Bracket Sequences I](https://cses.fi/problemset/task/2064) | CSES | 🟠 | Catalan | ¿Qué pasa si `n` es impar? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Distribute Candies Among Children II](https://leetcode.com/problems/distribute-candies-among-children-ii/) | LeetCode | 🟡 | Estrellas y barras con máximos | ¿Cuántos repartos tienen a un niño por encima del límite? |
| [ ] | [Counting Necklaces](https://cses.fi/problemset/task/2209) | CSES | 🟠 | Burnside | ¿Cuántas coloraciones deja fijas el giro de `i` posiciones? |
| [ ] | [Count Ways to Make Array With Product](https://leetcode.com/problems/count-ways-to-make-array-with-product/) | LeetCode | 🔴 | Factorizar y estrellas y barras | Cada primo de `k` reparte su exponente entre `n` posiciones: ¿de cuántas formas? |
| [ ] | [Bracket Sequences II](https://cses.fi/problemset/task/2187) | CSES | 🔴 | Reflexión con prefijo | Si el prefijo deja `d` paréntesis abiertos, ¿qué caminos restas? |
| [ ] | [Counting Grids](https://cses.fi/problemset/task/2210) | CSES | 🔴 | Burnside en dos dimensiones | ¿Cuántas casillas forman cada órbita de un giro de 90°? |

---

## ✅ Criterio de dominio

- Escribir `nCr` con factoriales e inversos en los tres lenguajes sin mirar.
- Reconocer estrellas y barras, Catalan e inclusión-exclusión, y justificar cada fórmula.
- Usar Lucas con la plantilla delante cuando `n ≥ p`.
- Resolver Christmas Party y Distributing Apples sin pista 2.

---

**Anterior:** [`17/04` — Primos](04-primos.md) · **Siguiente:** [`17/06` — Probabilidad y esperanza](06-probabilidad-y-esperanza.md) ·
**Relacionado:** [`12/06` — Conteo con DP](../12-dp-clasica/06-conteo.md).
