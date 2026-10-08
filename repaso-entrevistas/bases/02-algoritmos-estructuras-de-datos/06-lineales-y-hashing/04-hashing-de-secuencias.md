# 04 — *Hashing* de secuencias

> Comparar subcadenas y subarreglos en `O(1)` con un *hash* polinomial sobre prefijos; por qué la base
> tiene que ser aleatoria, cuánto vale la probabilidad de colisión y cuándo hace falta un doble módulo;
> y dos *hashes* para conjuntos: Zobrist para estados y la suma de valores aleatorios para multiconjuntos.
>
> **Niveles:** *hash* polinomial [B] · doble módulo [B] · Zobrist y *hash* de multiconjuntos [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), cap. 32 (Rabin-Karp); cp-algorithms, [*String Hashing*](https://cp-algorithms.com/string/string-hashing.html).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--hash-polinomial-sobre-prefijos) · [4](#4--doble-módulo-y-módulo-2--1) · [5](#5--zobrist-y-hash-de-multiconjuntos) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Comparar dos subcadenas de longitud `L` cuesta `O(L)`. Si un algoritmo hace `10⁵` comparaciones de
subcadenas de longitud `10⁵`, son `10¹⁰` operaciones. El *hashing* de secuencias reduce cada comparación a
`O(1)`: se precalcula un *hash* de cada prefijo, y el *hash* de cualquier subcadena sale de dos prefijos,
como las sumas de `04/01`.

El precio es la **probabilidad**: dos subcadenas distintas pueden tener el mismo *hash*. Con una base
fija y conocida, un adversario puede fabricar esas colisiones; con una base aleatoria, la probabilidad
es calculable y pequeña, siempre que el módulo sea lo bastante grande para el **número** de
comparaciones. Este capítulo es el dueño del *hash* polinomial; [`16/04`](../16-cadenas/04-hashing-de-cadenas.md) lo aplica a problemas de cadenas.

La misma idea sirve para objetos que no son secuencias: un tablero (Zobrist) o un multiconjunto, que se
representan con una suma o un *xor* de valores aleatorios y se actualizan en `O(1)` al cambiar un
elemento.

---

## 2. 📐 La teoría

**El *hash* polinomial.** Para una cadena `s` de longitud `L` con caracteres codificados como enteros
positivos, una base `b` y un primo `p`:

```text
H(s) = (s[0]·b^{L−1} + s[1]·b^{L−2} + … + s[L−1]) mod p
```

**Los prefijos.** Con `P[0] = 0` y `P[i+1] = (P[i]·b + s[i]) mod p`, el *hash* de `s[l, r)` es

```text
H(s[l, r)) = (P[r] − P[l]·b^{r−l}) mod p
```

porque `P[r]` contiene a `P[l]` desplazado `r − l` posiciones. Con las potencias `b^k` precalculadas,
cada subcadena cuesta `O(1)`.

**Teorema (probabilidad de colisión).** Si `b` se elige uniformemente en `[0, p)`, dos cadenas distintas
de longitud `L` tienen el mismo *hash* con probabilidad como mucho `(L − 1) / p`.

*Prueba.* `H(s) − H(t)` es un polinomio en `b` de grado como mucho `L − 1` con coeficientes `s[i] − t[i]`,
no todos nulos porque `s ≠ t`. Sobre el cuerpo `ℤ_p`, un polinomio no nulo de grado `d` tiene como mucho
`d` raíces. Colisionan solo si `b` es una de ellas: probabilidad `≤ (L − 1)/p`.

**Muchas comparaciones.** Con `Q` comparaciones, la probabilidad de **alguna** colisión es como mucho
`Q · (L − 1)/p` (unión de sucesos). Y si se meten `n` *hashes* en un conjunto para detectar repetidos, el
número esperado de pares que colisionan es `≈ n²/(2p)` (la paradoja del cumpleaños): con `n = 10⁵` y
`p = 10⁹ + 7`, unas **5 colisiones esperadas**. Un módulo de `10⁹` no basta para eso.

**Por qué la base aleatoria.** Con base y módulo fijos, el adversario conoce el polinomio y puede buscar
dos cadenas que colisionen. Con el módulo `2⁶⁴` (dejar que la aritmética desborde), hay una familia de
cadenas, las de Thue–Morse, que colisionan **para cualquier base**: por eso el desbordamiento natural no
es un módulo seguro.

---

## 3. 🧱 *Hash* polinomial sobre prefijos

**Qué es.** El arreglo `P` de §2 y las potencias de `b`, para obtener el *hash* de cualquier subcadena en
`O(1)`.

**Por qué es correcto** (el enunciado y una frase): si dos subcadenas son iguales, sus *hashes* son
iguales; si son distintas, coinciden con probabilidad `≤ (L − 1)/p` por el teorema de §2.

**Cómo va**, «abracadabra» con `a = 1, b = 2, c = 3, d = 4, r = 18`, base 131 y `p = 10⁹ + 7`:

```text
P[0] = 0
P[1] = 0·131 + 1              = 1
P[2] = 1·131 + 2              = 133
P[3] = 133·131 + 18           = 17 441
P[4] = 17 441·131 + 1         = 2 284 772        = H("abra")
H(s[7, 11)) = P[11] − P[7]·131⁴ mod p = 2 284 772   el «abra» final: mismo hash
```

**Cuánto.** `Θ(n)` de preproceso y memoria; `O(1)` por subcadena.

**La plantilla**, con módulo `2⁶¹ − 1` y base aleatoria, que da una probabilidad de colisión de `≈ L / 2⁶¹`
por comparación sin necesitar dos módulos:

```cpp
#include <chrono>
#include <cstdint>
#include <random>
#include <string>
#include <vector>

// Hash polinomial módulo 2^61 − 1 con base aleatoria. Preproceso O(n), subcadena O(1).
struct StringHash {
    static constexpr uint64_t MOD = (1ULL << 61) - 1;
    static uint64_t mul(uint64_t a, uint64_t b) {
        __uint128_t c = (__uint128_t)a * b;                   // 122 bits como mucho
        uint64_t r = (uint64_t)(c & MOD) + (uint64_t)(c >> 61);
        return r >= MOD ? r - MOD : r;
    }
    static uint64_t base() {
        static uint64_t B = std::mt19937_64(
            std::chrono::steady_clock::now().time_since_epoch().count())() % (MOD - 256) + 256;
        return B;
    }
    std::vector<uint64_t> pre, pw;
    explicit StringHash(const std::string& s) : pre(s.size() + 1), pw(s.size() + 1) {
        pw[0] = 1;
        for (size_t i = 0; i < s.size(); i++) {
            pre[i + 1] = (mul(pre[i], base()) + (unsigned char)s[i] + 1) % MOD;
            pw[i + 1] = mul(pw[i], base());
        }
    }
    uint64_t get(size_t l, size_t r) const {                  // hash de s[l, r)
        return (pre[r] + MOD - mul(pre[l], pw[r - l])) % MOD;
    }
};
```

```java
// Hash polinomial módulo 2^61 − 1 con base aleatoria. Preproceso O(n), subcadena O(1).
static final class StringHash {
    static final long MOD = (1L << 61) - 1;
    static final long B = 256 + Math.floorMod(new java.util.Random().nextLong(), MOD - 256);
    final long[] pre, pw;

    static long mul(long a, long b) {                         // producto exacto con 128 bits
        long hi = Math.multiplyHigh(a, b), lo = a * b;        // a, b < 2^61: el producto < 2^122
        long r = (lo & MOD) + ((lo >>> 61) | (hi << 3));
        return r >= MOD ? r - MOD : r;
    }

    StringHash(String s) {
        int n = s.length();
        pre = new long[n + 1]; pw = new long[n + 1]; pw[0] = 1;
        for (int i = 0; i < n; i++) {
            pre[i + 1] = (mul(pre[i], B) + s.charAt(i) + 1) % MOD;
            pw[i + 1] = mul(pw[i], B);
        }
    }

    long get(int l, int r) {                                  // hash de s[l, r)
        long v = pre[r] - mul(pre[l], pw[r - l]);
        return v < 0 ? v + MOD : v;
    }
}
```

- **Módulo `2⁶¹ − 1`**: es primo (de Mersenne) y la reducción se hace con desplazamientos: `x mod p` es
  `(x & p) + (x >> 61)` ajustado una vez. Con valores menores que `2⁶¹`, el producto cabe en 122 bits.
- **Base aleatoria** en `[256, p)`: mayor que cualquier carácter, elegida al ejecutar.
- **`+ 1` a cada carácter**: así ningún carácter vale 0, y `"a"` y `"\0a"` no colisionan trivialmente.
- **Java**: `Math.multiplyHigh` (Java 9+) da los 64 bits altos del producto; `(lo >>> 61) | (hi << 3)` son
  los bits del 61 en adelante.

**Rabin-Karp.** Buscar un patrón `t` de longitud `m` en `s`: comparar `H(t)` con `H(s[i, i+m))` para cada
`i`, en `O(n + m)`. Si se verifica carácter a carácter cada coincidencia de *hash*, el resultado es exacto
y el coste esperado sigue siendo lineal.

**Cuándo sí**: comparar muchas subcadenas; subcadena repetida más larga con binaria (`16/04`); palíndromos
comparando con la cadena invertida. **Cuándo no**: si basta una búsqueda de patrón, KMP o Z ([`16/02`](../16-cadenas/02-kmp.md),
[`16/03`](../16-cadenas/03-funcion-z-y-manacher.md)) son exactos y deterministas.

> **Veredicto:** el *hash* polinomial convierte comparar subcadenas en restar prefijos. Es probabilístico:
> base aleatoria y un módulo grande para el número de comparaciones.

---

## 4. 🧱 Doble módulo y módulo `2⁶¹ − 1`

**Qué es.** Dos *hashes* independientes (dos primos distintos, cada uno con su base aleatoria) que se
comparan a la vez, para que la probabilidad de colisión sea el producto de las dos.

**Por qué es correcto** (el enunciado y una frase): con bases elegidas de forma independiente, dos
cadenas distintas colisionan en los dos *hashes* con probabilidad `≤ ((L−1)/p₁) · ((L−1)/p₂)`.

**Cómo va.** Con `p₁ = 10⁹ + 7` y `p₂ = 998 244 353`, el par `(H₁, H₂)` funciona como un *hash* de unos
60 bits: con `n = 10⁵` cadenas en un conjunto, las colisiones esperadas pasan de 5 a `≈ 5·10⁻⁹`.

**Cuánto.** El doble de trabajo y de memoria que un módulo; el mismo `O(1)` por subcadena.

**La plantilla**, la idea en C++ (en Java, igual con `long`):

```cpp
#include <cstdint>
#include <utility>

// Doble módulo: cada valor es un par; productos en 64 bits porque los factores son < 2^30.
constexpr uint64_t P1 = 1'000'000'007, P2 = 998'244'353;
using H2 = std::pair<uint64_t, uint64_t>;
H2 step(H2 h, uint64_t b1, uint64_t b2, uint64_t c) {        // un carácter más
    return {(h.first * b1 + c) % P1, (h.second * b2 + c) % P2};
}
```

- **Las dos bases, aleatorias e independientes**: dos bases fijas siguen siendo atacables.
- **El par como clave** de un conjunto: `p₁ · 2³² + p₂` cabe en 64 bits y se usa como un solo entero.
- **Preferible, `2⁶¹ − 1`**: con un solo módulo de 61 bits la probabilidad es comparable, y el código de §3
  es más corto que llevar pares.

> **Veredicto:** un módulo de `10⁹` no basta para muchas comparaciones o muchos *hashes* en un conjunto.
> Dos módulos o un módulo de 61 bits, siempre con bases aleatorias.

---

## 5. 🧱 Zobrist y *hash* de multiconjuntos

**Qué es.** Para un objeto formado por elementos sin orden (un tablero con piezas, un multiconjunto), se
asigna a cada elemento posible un valor aleatorio de 64 bits y se combina con una operación
conmutativa: **xor** (Zobrist, para presencia) o **suma módulo `2⁶⁴`** (multiconjuntos, para cuentas).

**Por qué es correcto** (el enunciado y una frase): con valores aleatorios independientes, dos
conjuntos distintos dan el mismo *xor* con probabilidad `2⁻⁶⁴`, porque su diferencia simétrica no vacía
tiene un *xor* uniforme; con la suma pasa lo mismo para multiconjuntos de multiplicidades acotadas.

**Cómo va**, un tablero donde cada jugada activa o desactiva una casilla:

```text
estado inicial                   h = 0
activa (0,0)                     h = z[0][0]
activa (1,1)                     h = z[0][0] ⊕ z[1][1]
desactiva (0,0)                  h = z[1][1]                 el xor se deshace a sí mismo
desactiva (1,1)                  h = 0                       ¡estado repetido: el inicial!
```

Para un multiconjunto, con `r[x]` aleatorio por valor: `H({1, 2, 2}) = r[1] + 2·r[2]`. Sobre un
arreglo, los prefijos de `r[a[i]]` dan el *hash* del multiconjunto de cualquier subarreglo con una
resta, y se compara con el *hash* esperado (por ejemplo, el de `{1, …, k}`).

**Cuánto.** `O(1)` por actualización; `O(1)` por subarreglo con prefijos.

**La plantilla:**

```cpp
#include <chrono>
#include <cstdint>
#include <random>
#include <vector>

// r[v] aleatorio de 64 bits por valor; H(a[l, r)) = pre[r] − pre[l] (suma mod 2^64).
std::vector<uint64_t> multisetPrefix(const std::vector<int>& a, std::vector<uint64_t>& r) {
    std::mt19937_64 rng(std::chrono::steady_clock::now().time_since_epoch().count());
    for (auto& x : r) x = rng();                             // r tiene tamaño > máximo valor
    std::vector<uint64_t> pre(a.size() + 1, 0);
    for (size_t i = 0; i < a.size(); i++) pre[i + 1] = pre[i] + r[a[i]];   // desborda a propósito
    return pre;
}
```

```java
// r[v] aleatorio de 64 bits por valor; H(a[l, r)) = pre[r] − pre[l] (suma mod 2^64).
static long[] multisetPrefix(int[] a, long[] r) {
    java.util.SplittableRandom rng = new java.util.SplittableRandom();
    for (int v = 0; v < r.length; v++) r[v] = rng.nextLong();
    long[] pre = new long[a.length + 1];
    for (int i = 0; i < a.length; i++) pre[i + 1] = pre[i] + r[a[i]];   // desborda a propósito
    return pre;
}
```

- **Aquí sí vale `2⁶⁴`**: la suma de valores **aleatorios** no tiene la estructura polinomial que atacan
  las cadenas de Thue–Morse.
- **Xor frente a suma**: el *xor* solo ve la paridad de cada elemento (`{2, 2}` y `{}` dan lo mismo); la
  suma distingue las multiplicidades.
- **Java** desborda `long` de forma definida (módulo `2⁶⁴`); en C++, con `uint64_t` también.

**Cuándo sí**: estados repetidos (tableros, configuraciones); «¿este subarreglo es una permutación de
`1..k`?»; comparar multiconjuntos de subarreglos. **Cuándo no**: cuando importa el orden, *hash*
polinomial.

> **Veredicto:** para conjuntos y multiconjuntos, la suma o el *xor* de valores aleatorios es un *hash*
> que se actualiza en `O(1)` y se resta con prefijos.

---

## 6. ⏱️ La tabla de costes

| Técnica | Preproceso | Consulta | Probabilidad de colisión | Lo que la tabla no dice |
|---|---|---|---|---|
| Polinomial, un módulo `≈ 10⁹` | `Θ(n)` | `O(1)` | `≤ (L−1)/p` por comparación | Con muchos *hashes* en un conjunto, colisiona seguro |
| Polinomial, módulo `2⁶¹ − 1` | `Θ(n)` | `O(1)` | `≤ (L−1)/2⁶¹` | Necesita producto de 128 bits |
| Doble módulo | `Θ(n)` ×2 | `O(1)` ×2 | el producto de las dos | Las bases, independientes y aleatorias |
| Módulo `2⁶⁴` (desbordar) | `Θ(n)` | `O(1)` | atacable para cualquier base | No usar con cadenas de un adversario |
| Zobrist / multiconjunto | `Θ(n)` | `O(1)` | `≈ 2⁻⁶⁴` | Sin orden |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Son iguales `s[l₁..r₁]` y `s[l₂..r₂]`?», muchas consultas | *Hash* polinomial con prefijos | `O(1)` por consulta |
| «Subcadenas distintas de longitud `k`», «la repetida más larga» | *Hash* en un conjunto, con módulo grande | Cumpleaños: `n²/2p` colisiones |
| «Posición repetida», «configuración ya vista» | Zobrist | Actualización en `O(1)` por jugada |
| «¿Es el subarreglo una permutación?», «mismo multiconjunto» | Suma de valores aleatorios con prefijos | Sin orden |
| Patrón único en un texto | KMP o Z (`16/02`, `16/03`), o Rabin-Karp con verificación | Exactos |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Con módulo `10⁹ + 7` no hay colisiones» | Con `10⁵` *hashes* en un conjunto se esperan unas 5; hace falta `2⁶¹ − 1` o doble módulo |
| «Si los *hashes* son iguales, las cadenas son iguales» | Solo con alta probabilidad; si hace falta certeza, se verifica |
| «Dejar desbordar `unsigned long long` es un módulo como otro» | Las cadenas de Thue–Morse colisionan con módulo `2⁶⁴` para cualquier base |
| «La base puede ser 31 o 131» | Una base fija es atacable; se elige al azar al ejecutar |
| «El *xor* sirve para multiconjuntos» | Solo ve la paridad: `{x, x}` da lo mismo que `{}`; para cuentas, la suma |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §32.2: Rabin-Karp con su análisis. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*String Hashing*](https://cp-algorithms.com/string/string-hashing.html):
  prefijos, probabilidad de colisión y aplicaciones. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Rabin-Karp*](https://cp-algorithms.com/string/rabin-karp.html).
- **Artículo** — Zobrist, «A New Hashing Method with Application for Game Playing», informe técnico 88,
  Universidad de Wisconsin, 1970: el *hash* de posiciones de tablero.

---

## 🧠 Preguntas

1. ¿Cómo se calcula el *hash* de `s[l, r)` a partir de los prefijos? 🟢
2. ¿Por qué ningún carácter debe valer 0 en el *hash* polinomial? 🟢
3. ¿Qué diferencia hay entre un *hash* Zobrist con *xor* y uno de multiconjunto con suma? 🟢
4. ¿Por qué la base tiene que ser aleatoria? 🟡
5. Con `10⁵` *hashes* en un conjunto y `p = 10⁹ + 7`, ¿cuántas colisiones esperas? Justifica con la paradoja del cumpleaños. 🟡
6. ¿Qué hace Rabin-Karp y cómo consigue un resultado exacto? 🟡
7. Demuestra que dos cadenas distintas de longitud `L` colisionan con probabilidad `≤ (L − 1)/p` si la base es aleatoria. 🟠
8. ¿Por qué el módulo `2⁶¹ − 1` permite reducir con desplazamientos, y por qué el producto cabe en 128 bits? 🟠
9. Compara cómo calculas `a · b mod (2⁶¹ − 1)` en C++, Java y JavaScript. 🟠
10. ¿Por qué el módulo `2⁶⁴` es atacable para cualquier base, y por qué no lo es la suma de valores aleatorios? 🟠
11. ¿Cómo decides, con prefijos de *hash* de multiconjunto, si `a[l..r]` es una permutación de `1..(r − l + 1)`? 🟠
12. Con `Q = 10⁶` comparaciones de subcadenas de longitud `10⁵`, ¿qué módulo necesitas para una probabilidad de error menor que `10⁻⁶`? 🔴
13. ¿Cómo combinas *hash* y búsqueda binaria para comparar lexicográficamente dos subcadenas en `O(log n)`? 🔴

---

## 🧩 Problemas propios

### Subcadenas iguales

**Nivel:** 🟡 · **Formato:** programa completo.

Dada una cadena y `q` consultas `l₁ r₁ l₂ r₂` (0-indexadas, inclusivas, misma longitud), imprime `SI` si
las dos subcadenas son iguales y `NO` si no.

- **Entrada.** Una línea con `s`. Una línea con `q`. Después, `q` líneas con las consultas.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ |s|, q ≤ 2·10⁵`; letras minúsculas.

```text
Entrada            Salida
abracadabra        SI
4                  NO
0 3 7 10           SI
0 1 3 4            SI
1 1 8 8
0 0 3 3

Entrada            Salida
a                  SI
1
0 0 0 0
```

**Pista 1:** ¿cuánto cuesta comparar carácter a carácter en el peor caso, con `q = 2·10⁵`?

🔥 **Para el geek — en JavaScript:** el producto de dos valores cercanos a `2⁶¹` no cabe en un `Number`
(53 bits exactos); hay que usar `BigInt` o partir los factores en mitades de 16 o 26 bits.

### ¿Es una permutación?

**Nivel:** 🟠 · **Formato:** programa completo.

Para cada consulta `l r` (0-indexada, inclusiva), imprime `SI` si `a[l..r]` contiene exactamente los
valores `1, 2, …, r − l + 1`, cada uno una vez.

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` valores. Después, `q` líneas con `l r`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `1 ≤ a[i] ≤ n`.

```text
Entrada            Salida
5 5                SI
2 1 3 1 2          NO
0 2                SI
1 3                SI
2 4                SI
3 4
1 1

Entrada            Salida
3 2                NO
3 3 3              NO
0 0
0 2
```

**Pista 1:** si conocieras el *hash* del multiconjunto `{1, …, k}`, ¿qué tendrías que calcular para cada
consulta?

### Tableros repetidos

**Nivel:** 🟡 · **Formato:** programa completo.

Un tablero de `8 × 8` empieza vacío. Cada jugada activa o desactiva una casilla. Imprime el número de la
primera jugada tras la cual el tablero vuelve a un estado que ya tuvo (incluido el inicial), o 0 si no
ocurre.

- **Entrada.** Una línea con `k`. Después, `k` líneas con `fila columna` (de 0 a 7).
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ 10⁶`.

```text
Entrada            Salida
4                  4
0 0
1 1
0 0
1 1

Entrada            Salida
2                  2
3 3
3 3
```

**Pista 1:** guardar el tablero entero tras cada jugada son 64 bits; ¿y si fueran `100 × 100` casillas?

---

## 🧩 Práctica externa

> 💡 **Truco.** Si una solución con *hash* falla en un caso grande y no en los pequeños, sospecha de una
> colisión antes que del algoritmo: cambia a `2⁶¹ − 1` o a doble módulo y vuelve a enviar. Pide a una
> IA la cuenta del cumpleaños para tu `n`, no el código ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Find the Index of the First Occurrence in a String](https://leetcode.com/problems/find-the-index-of-the-first-occurrence-in-a-string/) | LeetCode | 🟢 | Rabin-Karp | ¿Cómo actualizas el *hash* de la ventana al moverla una posición? |
| [ ] | [String Matching](https://cses.fi/problemset/task/1753) | CSES | 🟢 | Rabin-Karp | Con `10⁶` caracteres, ¿qué módulo evita colisiones? |
| [ ] | [Repeated DNA Sequences](https://leetcode.com/problems/repeated-dna-sequences/) | LeetCode | 🟡 | *Hash* de ventana en un conjunto | Con 4 letras y longitud 10, ¿cabe la ventana entera en un entero? |
| [ ] | [Finding Borders](https://cses.fi/problemset/task/1732) | CSES | 🟡 | Comparar prefijo y sufijo | ¿Qué dos subcadenas comparas para cada longitud de borde? |
| [ ] | [Sherlock and Anagrams](https://www.hackerrank.com/challenges/sherlock-and-anagrams/problem) | HackerRank | 🟡 | *Hash* de multiconjunto | ¿Qué tienen en común dos subcadenas que son anagramas? |
| [ ] | [Good Substrings](https://codeforces.com/problemset/problem/271/D) | Codeforces | 🟠 | Subcadenas distintas con *hash* | Con `n ≤ 1500`, ¿cuántas subcadenas hay, y cómo las distingues? |
| [ ] | [Watto and Mechanism](https://codeforces.com/problemset/problem/514/C) | Codeforces | 🟠 | *Hash* con un cambio | Si cambias un carácter, ¿cómo cambia el *hash* sin recalcularlo? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Finding Periods](https://cses.fi/problemset/task/1733) | CSES | 🟡 | Comparar la cadena con su desplazamiento | Si `p` es un periodo, ¿qué dos subcadenas son iguales? |
| [ ] | [Minimal Rotation](https://cses.fi/problemset/task/1110) | CSES | 🟠 | Comparación lexicográfica con *hash* y binaria | Sobre `s + s`, ¿cómo comparas dos rotaciones en `O(log n)`? |
| [ ] | [Compress Words](https://codeforces.com/problemset/problem/1200/E) | Codeforces | 🟠 | Solapamiento sufijo-prefijo | ¿Cuántos caracteres del resultado necesitas mirar para cada palabra nueva? |
| [ ] | [Distinct Echo Substrings](https://leetcode.com/problems/distinct-echo-substrings/) | LeetCode | 🔴 | Comparar mitades con *hash* | Fijados el inicio y la mitad, ¿qué dos subcadenas comparas? |

---

## ✅ Criterio de dominio

- Escribir el *hash* polinomial con prefijos y módulo `2⁶¹ − 1` sin mirar.
- Demostrar la cota `(L − 1)/p` y calcular las colisiones esperadas con el cumpleaños.
- Elegir entre polinomial, doble módulo, Zobrist y multiconjunto según el problema.
- Resolver Finding Borders y Watto and Mechanism sin pista 2.

---

**Anterior:** [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*](03-tablas-hash.md) ·
**Siguiente:** [`06/05` — Simulación](05-simulacion.md) · **Relacionado:** [`16/04` — *Hashing* de cadenas aplicado](../16-cadenas/04-hashing-de-cadenas.md);
[`04/01` — Sumas de prefijos y arreglos de diferencias](../04-secuencias/01-prefijos-y-diferencias.md).
