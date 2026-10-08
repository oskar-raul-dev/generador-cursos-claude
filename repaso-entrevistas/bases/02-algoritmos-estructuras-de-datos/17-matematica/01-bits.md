# 01 — Bits

> Las operaciones de bits con las que se escribe medio corpus —aislar el bit más bajo, contar unos,
> recorrer submáscaras, desplazar sin sorpresas de signo—, el `bitset` como forma de dividir entre 64 el
> trabajo de una DP o de un recorrido, y la base XOR: la eliminación de Gauss sobre `GF(2)` que responde
> «¿qué XOR se pueden formar con estos números?». Es el dueño de las operaciones de bits.
>
> **Niveles:** operaciones y trucos [A] · `bitset` como optimización [B] · base XOR [B].
>
> **📚 Lectura troncal:** Warren, *Hacker's Delight*, 2.ª ed. (Addison-Wesley, 2012), caps. 2 y 5.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--operaciones-y-trucos) · [4](#4--bitset-como-optimización) · [5](#5--base-xor) · [6](#6-️-la-tabla-de-costes) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Tres situaciones donde los bits deciden. Un arreglo de `10⁶` números del 1 al `n` donde uno se repite y otro
falta: ordenarlo, o un conjunto, gasta `Θ(n)` de memoria; con XOR se encuentra en una pasada y `O(1)` de
memoria. Una mochila de 0/1 con `n = 1 000` objetos y capacidad `10⁵`: la DP de [`12/03`](../12-dp-clasica/03-mochilas.md) son `10⁸`
operaciones; con un `bitset`, `10⁸ / 64`. Y una pregunta que parece de búsqueda exhaustiva: ¿cuál es el
mayor XOR que se puede formar eligiendo un subconjunto de `10⁵` números? Hay `2^(10⁵)` subconjuntos; la base
XOR responde en `Θ(n · 60)`.

Detrás de las tres está lo mismo: un entero es un vector de bits, y las operaciones de bits trabajan sobre
64 posiciones a la vez.

> 🧠 **Modelo mental.** Un `long` es un arreglo de 64 booleanos con operaciones en bloque: `&` es la
> intersección, `|` la unión, `^` la diferencia simétrica, y el desplazamiento mueve el arreglo entero.

Los ejemplos usan el arreglo de juguete `[5, 2, 9, 1, 5, 6]` y el número `44 = 101100₂`.

---

## 2. 📐 La teoría

**Complemento a dos.** Con `w` bits, `−x` se representa como `2^w − x`, es decir, `~x + 1`. De ahí:

```text
x & -x        el bit encendido más bajo           44 & -44 = 4   (101100 → 000100)
x & (x - 1)   apaga el bit más bajo                44 & 43  = 40  (101100 → 101000)
x & (x - 1) == 0, con x > 0   x es potencia de 2
x | (x + 1)   enciende el cero más bajo
```

**Desplazamientos.** `x << k` multiplica por `2^k` mientras no desborde. `x >> k` sobre un número **con
signo** es aritmético en Java, en Python y en C++20: replica el bit de signo y redondea hacia `−∞`
(`−7 >> 1 = −4`), mientras que la división redondea hacia 0 en C++ y Java (`−7 / 2 = −3`). Desplazar por `w` o
más bits es comportamiento indefinido en C++ y en Java se reduce módulo `w`.

**XOR.** Asociativo y conmutativo, con `a ^ a = 0` y `a ^ 0 = a`. Consecuencias: el XOR de todos los
elementos cancela los que aparecen un número par de veces; el XOR de un tramo es `pre[r] ^ pre[l − 1]` con
prefijos ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)); y `a ^ b ^ b = a`.

**Base XOR.** Los números son vectores sobre `GF(2)`, el cuerpo de dos elementos donde la suma es el XOR. El
conjunto de XOR de todos los subconjuntos es el **subespacio generado**. Una base de ese subespacio, con
pivotes distintos (como en la eliminación de Gauss, [`17/07`](07-matrices-y-gauss.md)), tiene tamaño `r ≤ 60` (el rango): hay
exactamente `2^r` XOR distintos, y el mayor se obtiene de forma voraz desde el pivote más alto.

**`bitset`.** Un arreglo de bits empaquetado en palabras de 64: `&`, `|`, `^`, desplazamientos y conteo
trabajan sobre 64 posiciones por instrucción. Divide entre 64 el coste de las operaciones de conjunto.

---

## 3. 🧱 Operaciones y trucos

**Qué es.** El repertorio diario: leer, encender, apagar y conmutar un bit; aislar el más bajo; contar
unos; recorrer los bits encendidos; recorrer las submáscaras de una máscara.

**Por qué es correcto.** Las identidades del complemento a dos de §2; el recorrido de submáscaras
`sub = (sub − 1) & mask` enumera en orden decreciente todos los subconjuntos de `mask`, porque restar 1 apaga
el bit más bajo y enciende los de debajo, y el `&` los recorta a `mask`.

**Cómo va**, con `44 = 101100`:

```text
popcount(44) = 3        bit más bajo: 44 & -44 = 4 (posición 2)       bit más alto: posición 5
submáscaras de 101100:  101100 101000 100100 100000 001100 001000 000100 000000   (2³ = 8)
XOR de [5, 2, 9, 1, 5, 6] = 12   (los dos 5 se cancelan: 2 ^ 9 ^ 1 ^ 6)
```

**Cuánto.** `O(1)` cada operación; recorrer los unos, `O(popcount)`; las submáscaras de `mask`,
`2^popcount(mask)`.

**La plantilla:**

```cpp
#include <cstdint>

// Repertorio de bits sobre 64 bits sin signo (los desplazamientos con signo, mejor evitarlos).
inline bool getBit(uint64_t x, int i) { return x >> i & 1; }
inline uint64_t setBit(uint64_t x, int i) { return x | (1ULL << i); }       // 1ULL: no 1, que es int
inline uint64_t clearBit(uint64_t x, int i) { return x & ~(1ULL << i); }
inline uint64_t lowBit(uint64_t x) { return x & -x; }
inline bool isPowerOfTwo(uint64_t x) { return x && !(x & (x - 1)); }
inline int popcount(uint64_t x) { return __builtin_popcountll(x); }         // C++20: std::popcount
inline int lowestIndex(uint64_t x) { return __builtin_ctzll(x); }           // x ≠ 0; C++20: std::countr_zero
inline int highestIndex(uint64_t x) { return 63 - __builtin_clzll(x); }     // x ≠ 0; C++20: std::bit_width − 1

// for (uint64_t m = x; m; m &= m - 1) { int i = __builtin_ctzll(m); … }   recorrer los unos
// for (int sub = mask; ; sub = (sub - 1) & mask) { …; if (sub == 0) break; } submáscaras, incluida la vacía
```

```java
static boolean getBit(long x, int i) { return (x >>> i & 1) == 1; }         // >>> : sin replicar el signo
static long setBit(long x, int i) { return x | (1L << i); }                  // 1L: no 1, que es int
static long clearBit(long x, int i) { return x & ~(1L << i); }
static long lowBit(long x) { return x & -x; }
static boolean isPowerOfTwo(long x) { return x > 0 && (x & (x - 1)) == 0; }
static int popcount(long x) { return Long.bitCount(x); }
static int lowestIndex(long x) { return Long.numberOfTrailingZeros(x); }
static int highestIndex(long x) { return 63 - Long.numberOfLeadingZeros(x); }
// for (long m = x; m != 0; m &= m - 1) { int i = Long.numberOfTrailingZeros(m); … }
```

```python
def get_bit(x, i): return x >> i & 1
def set_bit(x, i): return x | (1 << i)
def clear_bit(x, i): return x & ~(1 << i)
def low_bit(x): return x & -x
def is_power_of_two(x): return x > 0 and x & (x - 1) == 0
def popcount(x): return x.bit_count()                 # Python 3.10+; antes, bin(x).count('1')
def lowest_index(x): return (x & -x).bit_length() - 1
def highest_index(x): return x.bit_length() - 1
# Los enteros de Python no tienen tamaño fijo: ~x es −x − 1 y no hay desbordamiento.
```

- **`1 << 40` desborda** en C++ y Java si el `1` es `int`: `1ULL` y `1L`.
- **`>>` en Java y C++ sobre negativos** replica el signo; para tratar el número como bits sin signo, `>>>`
  en Java y `uint64_t` en C++. Python solo tiene `>>` aritmético, y sus enteros son ilimitados.
- **Prefijo XOR**: `pre[i] = pre[i − 1] ^ a[i]`; el XOR del tramo `[l, r]` es `pre[r] ^ pre[l − 1]`.
- **XOR de `1..n`** sin recorrer: `n, 1, n + 1, 0` según `n mod 4` sea `0, 1, 2, 3`.

### De la versión ingenua a la buena

**El problema.** En un arreglo con los números del 1 al `n`, uno aparece dos veces y otro falta. ¿Cuáles son?
En `[1, 2, 2, 4]`, sobra el 2 y falta el 3.

**La versión ingenua:**

```java
// Correcta: contar apariciones en un arreglo auxiliar. Θ(n) tiempo y Θ(n) memoria.
static int[] mismatchNaive(int[] a) {
    int n = a.length;
    int[] count = new int[n + 1];
    for (int v : a) count[v]++;
    int dup = -1, missing = -1;
    for (int v = 1; v <= n; v++) { if (count[v] == 2) dup = v; if (count[v] == 0) missing = v; }
    return new int[]{dup, missing};
}
```

> «Si hago el XOR de todos los valores y de todos los índices del 1 al `n`, todo se cancela salvo el
> repetido y el que falta: me queda `dup ^ missing`. Sus bits encendidos son donde difieren; separo valores e
> índices por uno de esos bits y, en cada mitad, el XOR me da uno de los dos.»

**El camino a la buena.** `x = XOR(a) ^ XOR(1..n)`; `b = x & −x`; el XOR de los valores e índices con el bit
`b` da uno de los dos; el otro es `x ^` ese. Una pasada más decide cuál es el repetido. `Θ(n)` tiempo y
`Θ(1)` memoria. En el ejemplo, `x = 2 ^ 3 = 1`.

**Cuándo sí:** cancelar pares, conjuntos pequeños como máscaras (`n ≤ 64`), flags, prefijos XOR, potencias
de dos, recorrer subconjuntos ([`10/02`](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md), `13/01`). **Cuándo no:** cuando la versión con un arreglo o un
conjunto es igual de rápida y más legible, y no hay límite de memoria.

> **Veredicto:** los trucos de bits son identidades del complemento a dos y del XOR; en Java, `1L` y `>>>`;
> en C++, `1ULL` y sin signo; en Python, enteros sin límite.

---

## 4. 🧱 `bitset` como optimización

**Qué es.** Representar un conjunto de hasta `N` elementos como `N/64` palabras y hacer las operaciones de
conjunto palabra a palabra.

**Por qué es correcto.** Cada bit de cada palabra es un elemento; las operaciones lógicas de palabras son
las de conjuntos en paralelo sobre 64 elementos.

**Cómo va.** Sumas alcanzables con `[5, 2, 9]`: empieza `reach = {0}` y, por cada `a`, `reach |= reach << a`.

```text
tras 5: {0, 5}      tras 2: {0, 2, 5, 7}      tras 9: {0, 2, 5, 7, 9, 11, 14, 16}
```

**Cuánto.** `Θ(N / 64)` por operación de conjunto; la mochila de sumas, `Θ(n · S / 64)`.

**La plantilla:**

```cpp
#include <bitset>
#include <vector>

// Sumas alcanzables con subconjuntos de a (cada uno usado como mucho una vez), hasta MAXS − 1.
const int MAXS = 100001;
std::bitset<MAXS> reachable(const std::vector<int>& a) {
    std::bitset<MAXS> reach;
    reach[0] = 1;
    for (int x : a) reach |= reach << x;
    return reach;
}
// Otros usos: matriz de adyacencia como vector<bitset<N>> (triángulos, cierre transitivo, 14/01, 15/02).
```

```java
// java.util.BitSet no tiene desplazamiento: se escribe sobre long[] (64 bits por palabra).
static long[] reachable(int[] a, int maxS) {
    int words = (maxS >> 6) + 1;
    long[] reach = new long[words];
    reach[0] = 1;
    for (int x : a) {
        int ws = x >> 6, bs = x & 63;
        for (int i = words - 1; i >= ws; i--) {          // reach |= reach << x, de arriba abajo
            long v = reach[i - ws] << bs;
            if (bs != 0 && i - ws - 1 >= 0) v |= reach[i - ws - 1] >>> (64 - bs);
            reach[i] |= v;
        }
    }
    return reach;
}
```

- **En Python**, un `int` es un `bitset` de tamaño libre: `reach |= reach << x` funciona igual y es rápido
  (está escrito en C).
- **`std::bitset` necesita el tamaño en compilación**; con tamaño variable, `vector<uint64_t>` a mano o
  `boost::dynamic_bitset`.
- **`count()`, `_Find_first()`, `_Find_next()`** (los dos últimos, extensiones de GCC) recorren los unos sin
  mirar bit a bit.

**Cuándo sí:** mochilas de factibilidad, cierre transitivo, triángulos, intersecciones de vecindarios,
cualquier DP booleana con transición «desplazar y unir». **Cuándo no:** si la DP lleva valores (máximos,
conteos), no booleanos.

> **Veredicto:** un `bitset` divide entre 64 las operaciones de conjunto; en DP booleanas, es la diferencia
> entre TLE y AC.

---

## 5. 🧱 Base XOR

**Qué es.** Una base de los XOR alcanzables, con a lo sumo un vector por bit pivote: al insertar `x`, se le
quitan (con XOR) los vectores de la base cuyos pivotes tiene encendidos, de mayor a menor; si queda algo, su
bit más alto es un pivote nuevo.

**Por qué es correcto.** Es la eliminación de Gauss sobre `GF(2)`: las operaciones no cambian el subespacio
generado, y los pivotes distintos garantizan independencia. El mayor XOR se construye de forma voraz: desde
el pivote más alto, se toma el vector si mejora el resultado (enciende un bit más alto que no se puede
perder después).

**Cómo va**, con `[5, 2, 9, 1, 5, 6]` (4 bits):

```text
inserta 5 (0101): pivote 2      inserta 2 (0010): pivote 1     inserta 9 (1001): pivote 3
inserta 1 (0001): pivote 0      inserta 5: 5 ^ 5 = 0 → nada    inserta 6 (0110): 6 ^ 5 = 3, 3 ^ 2 = 1, 1 ^ 1 = 0 → nada
base = {9, 5, 2, 1}, rango 4 → 2⁴ = 16 XOR distintos; el mayor, 15
```

**Cuánto.** `Θ(B)` por inserción con `B` bits (60 para valores hasta `10¹⁸`); `Θ(n · B)` en total.

**La plantilla:**

```cpp
#include <cstdint>

struct XorBasis {
    static const int B = 60;
    uint64_t basis[B] = {};                              // basis[b] tiene su bit más alto en b, o es 0
    int rank = 0;
    bool insert(uint64_t x) {
        for (int b = B - 1; b >= 0; b--) {
            if (!(x >> b & 1)) continue;
            if (!basis[b]) { basis[b] = x; rank++; return true; }
            x ^= basis[b];
        }
        return false;                                    // x ya se podía formar
    }
    uint64_t maxXor() const {
        uint64_t r = 0;
        for (int b = B - 1; b >= 0; b--) if ((r ^ basis[b]) > r) r ^= basis[b];
        return r;
    }
    bool canForm(uint64_t x) const {
        for (int b = B - 1; b >= 0; b--) if (x >> b & 1) { if (!basis[b]) return false; x ^= basis[b]; }
        return true;
    }
};
```

```java
static long[] basis = new long[60];
static int rank = 0;

static boolean insert(long x) {
    for (int b = 59; b >= 0; b--) {
        if ((x >> b & 1) == 0) continue;
        if (basis[b] == 0) { basis[b] = x; rank++; return true; }
        x ^= basis[b];
    }
    return false;
}

static long maxXor() {
    long r = 0;
    for (int b = 59; b >= 0; b--) if ((r ^ basis[b]) > r) r ^= basis[b];
    return r;
}
```

- **Número de XOR distintos**: `2^rank` (incluido el 0 del subconjunto vacío).
- **El `k`-ésimo XOR más pequeño**: reducir la base a forma escalonada reducida y leer `k` en binario.
- **Prefijos de bases** (para tramos `[l, r]`): guardar con cada vector la posición más reciente que lo usa
  (Ivan and Burgers).

**Cuándo sí:** «mayor / número / `k`-ésimo XOR de un subconjunto», «¿se puede formar `x`?», independencia
lineal sobre `GF(2)`. **Cuándo no:** si se pide el XOR de un tramo **contiguo** (prefijos) o de dos elementos
(trie binario, [`07/04`](../07-arboles/04-tries.md)).

> **Veredicto:** la base XOR es Gauss sobre `GF(2)` con un vector por bit pivote: `2^rango` XOR distintos y
> el máximo, voraz desde arriba.

---

## 6. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| Leer, encender, apagar, aislar el bit bajo | `O(1)` | `1L` / `1ULL` para posiciones `≥ 31` |
| `popcount` | `O(1)` (instrucción) | `Long.bitCount`, `int.bit_count` (3.10+) |
| Recorrer los unos | `O(popcount)` | `m &= m − 1` |
| Recorrer las submáscaras de todas las máscaras | `Θ(3ⁿ)` | `13/01` |
| Operación de `bitset` de `N` bits | `Θ(N / 64)` | Tamaño fijo en C++ |
| Insertar en la base XOR | `Θ(B)` | `B = 60` para valores hasta `10¹⁸` |

---

## 7. 🧭 Cómo se elige

```text
¿Pares que se cancelan, un elemento distinto? → XOR de todos
¿XOR de tramos? → prefijos XOR
¿Conjunto pequeño (≤ 64) como estado? → máscara (13/01)
¿DP booleana con «desplazar y unir»? → bitset
¿XOR de subconjuntos arbitrarios: máximo, cuántos, si se puede formar? → base XOR
¿XOR máximo de dos elementos? → trie binario (07/04)
```

> **Regla de entrevista:** si usas un truco de bits, di la identidad que lo justifica («`x & (x − 1)` apaga
> el bit más bajo»): el entrevistador quiere ver que no es magia memorizada.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Todos aparecen dos veces salvo…» | XOR de todos | `a ^ a = 0` |
| «Sin memoria extra», «`O(1)` de espacio» con números del 1 al `n` | XOR o sumas | Cancelar contra los índices |
| «¿Se puede alcanzar la suma `S`?», `n · S` del orden de `10⁸` o más | `bitset` | DP booleana entre 64 |
| «XOR máximo de un subconjunto», «cuántos XOR distintos» | Base XOR | Subespacio sobre `GF(2)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`>>` divide por 2 siempre» | Con negativos redondea hacia `−∞` (`−7 >> 1 = −4`), y la división hacia 0 (`−7 / 2 = −3`) |
| «`1 << 40` vale 2⁴⁰» | Con `1` de tipo `int` desborda: `1L << 40` o `1ULL << 40` |
| «`x & 1 == 0` comprueba si es par» | En C++ y Java, `==` tiene más precedencia que `&`: `(x & 1) == 0` |
| «Para el mayor XOR hay que probar los subconjuntos» | La base XOR lo da en `Θ(n · B)` |
| «`java.util.BitSet` sirve para la mochila» | No tiene desplazamiento: hay que escribirlo sobre `long[]` |
| «En Python `~x` es el complemento de 32 bits» | Es `−x − 1`: los enteros no tienen tamaño fijo |

---

## 📚 Para profundizar

- **Libro** — Warren, *Hacker's Delight*, 2.ª ed. (Addison-Wesley, 2012), cap. 2 (manipulaciones básicas) y
  cap. 5 (contar bits). *Lectura troncal.*
- **Documentación** — cppreference, [cabecera `<bit>`](https://en.cppreference.com/cpp/header/bit).
- **Documentación** — Java SE 21, [`Long`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Long.html)
  (`bitCount`, `numberOfTrailingZeros`).
- **Referencia** — cp-algorithms, [*Bit manipulation*](https://cp-algorithms.com/algebra/bit-manipulation.html).

---

## 🧠 Preguntas

1. ¿Qué hacen `x & -x` y `x & (x − 1)`? 🟢
2. ¿Cómo compruebas si un número es potencia de 2? 🟢
3. ¿Cómo cuentas los bits encendidos en C++, Java y Python? 🟢
4. ¿Por qué `1 << 40` puede dar un resultado incorrecto, y cómo se escribe bien en cada lenguaje? 🟡
5. ¿Qué diferencia hay entre `>>` y `>>>` en Java, y qué pasa en C++ y Python? 🟡
6. ¿Cuánto vale el XOR de `1..n` sin recorrer, y por qué? 🟡
7. ¿Cómo recorres todas las submáscaras de una máscara? 🟡
8. ¿Por qué `−7 >> 1` y `−7 / 2` dan resultados distintos? 🟡
9. ¿Cómo encuentras, en `Θ(n)` y memoria constante, el repetido y el que falta del 1 al `n`? 🟠
10. ¿Cómo usas un `bitset` para la mochila de factibilidad, y cuánto ganas? 🟠
11. ¿Qué es la base XOR y por qué hay `2^rango` XOR distintos? 🟠
12. ¿Por qué el voraz desde el pivote más alto da el mayor XOR? 🔴
13. ¿Qué diferencia hay entre «XOR máximo de dos elementos» y «XOR máximo de un subconjunto», y qué estructura resuelve cada uno? 🔴

---

## 🧩 Problemas propios

### Radiografía de un número

**Nivel:** 🟢 · **Formato:** programa completo.

Para un entero `n`, imprime cuántos bits tiene encendidos, la posición de su bit encendido más bajo y la de su
bit más alto (las posiciones empiezan en 0).

- **Entrada.** Una línea con `n`.
- **Salida.** Tres enteros.
- **Restricciones.** `1 ≤ n < 2⁶³`.

```text
Entrada     Salida
44          3 2 5

Entrada     Salida
1           1 0 0
```

**Pista 1:** ¿qué funciones de la biblioteca de tu lenguaje dan cada una de las tres cosas?

### XOR de tramos de enteros

**Nivel:** 🟡 · **Formato:** programa completo.

Para cada consulta `l r`, imprime el XOR de todos los enteros del `l` al `r`.

- **Entrada.** Una línea con `q`. Después, `q` líneas con `l r`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ q ≤ 2·10⁵`; `1 ≤ l ≤ r ≤ 10¹⁸`.

```text
Entrada                                  Salida
4                                        1
1 5                                      3
3 7                                      4
4 4                                      10
2 10

Entrada                                  Salida
2                                        1000000000000000000
1000000000000000000 1000000000000000000  1000000000000000000
1 1000000000000000000
```

**Pista 1:** si supieras el XOR de `1..n` para cualquier `n`, ¿cómo sacarías el de un tramo?

### El mayor XOR

**Nivel:** 🟠 · **Formato:** programa completo.

Imprime el mayor XOR que se puede obtener eligiendo un subconjunto (quizá vacío) de los números dados, y
cuántos valores distintos de XOR se pueden obtener.

- **Entrada.** Una línea con `n`. Una línea con los `n` números.
- **Salida.** Dos enteros.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `0 ≤ aᵢ < 2⁶⁰`.

```text
Entrada         Salida
6               15 16
5 2 9 1 5 6

Entrada         Salida
2               3 2
3 3
```

**Pista 1:** si dos subconjuntos dan el mismo XOR, ¿qué da su diferencia simétrica?

🔥 **Para el geek — en JavaScript:** los operadores de bits convierten los operandos a enteros de 32 bits
con signo: `1 << 31` es negativo y `2 ** 40 | 0` es 0. `>>>` desplaza sin signo y devuelve un número no
negativo. Para 64 bits, `BigInt` (`1n << 40n`), sin mezclarlo con `Number`.

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con un truco de bits que falla, imprime los números en binario
> (`bin`, `Long.toBinaryString`, `bitset<8>(x)`) en el ejemplo: casi siempre es un `1` sin `L` o un
> desplazamiento con signo. Si una IA te ayuda, que sea a revisar eso ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).
> La lección 1 de Codility (*BinaryGap*) ya está en [`01/01`](../01-oficio-del-competidor/01-el-juez-los-veredictos-y-las-plataformas.md).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Number of 1 Bits](https://leetcode.com/problems/number-of-1-bits/) | LeetCode | 🟢 | `popcount` | ¿Cuántas vueltas da `n &= n − 1`? |
| [ ] | [Power of Two](https://leetcode.com/problems/power-of-two/) | LeetCode | 🟢 | Un solo bit | ¿Qué deja `n & (n − 1)` si solo hay un bit? |
| [ ] | [Counting Bits](https://leetcode.com/problems/counting-bits/) | LeetCode | 🟢 | DP sobre bits | ¿Qué relación hay entre `popcount(i)` y `popcount(i >> 1)`? |
| [ ] | [Reverse Bits](https://leetcode.com/problems/reverse-bits/) | LeetCode | 🟢 | Desplazamientos sin signo | ¿Qué desplazamiento usas en Java para no arrastrar el signo? |
| [ ] | [Sum of Two Integers](https://leetcode.com/problems/sum-of-two-integers/) | LeetCode | 🟡 | Suma con XOR y acarreo | ¿Qué parte de la suma da el XOR, y cuál el AND desplazado? |
| [ ] | [Single Number II](https://leetcode.com/problems/single-number-ii/) | LeetCode | 🟡 | Conteo por bit módulo 3 | Para cada posición de bit, ¿cuántos unos hay módulo 3? |
| [ ] | [Counting Bits](https://cses.fi/problemset/task/1146) | CSES | 🟡 | Unos de `1..n` por bit | ¿Cada cuánto se repite el patrón del bit `k`? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Maximum XOR of Two Numbers in an Array](https://leetcode.com/problems/maximum-xor-of-two-numbers-in-an-array/) | LeetCode | 🟡 | Trie binario o voraz por bit | Bit a bit desde el más alto, ¿puedes conseguir un 1 aquí? |
| [ ] | [Minimum Flips to Make a OR b Equal to c](https://leetcode.com/problems/minimum-flips-to-make-a-or-b-equal-to-c/) | LeetCode | 🟡 | Bit a bit | Si el bit de `c` es 0, ¿cuántos cambios cuesta? |
| [ ] | [Square Subsets](https://codeforces.com/problemset/problem/895/C) | Codeforces | 🔴 | Base XOR de paridades de primos | Un producto es cuadrado si cada primo aparece un número par de veces: ¿qué vector asocias a cada número? |
| [ ] | [Mahmoud and Ehab and yet another xor task](https://codeforces.com/problemset/problem/959/F) | Codeforces | 🔴 | Base XOR por prefijos | Si `x` se puede formar con los `l` primeros, ¿de cuántas formas? |
| [ ] | [Ivan and Burgers](https://codeforces.com/problemset/problem/1100/F) | Codeforces | 🔴 | Base XOR con posiciones | ¿Qué vector conviene conservar en la base cuando hay dos con el mismo pivote? |

---

## ✅ Criterio de dominio

- Escribir el repertorio de bits en los tres lenguajes sin mirar, con `1L`, `1ULL` y `>>>` donde toca.
- Recorrer unos y submáscaras, y usar el XOR para cancelar y para tramos.
- Acelerar una DP booleana con `bitset` y construir una base XOR con la plantilla delante.
- Resolver Single Number II y CSES Counting Bits sin pista 2.

---

**Anterior:** — · **Siguiente:** [`17/02` — Divisibilidad](02-divisibilidad.md) · **Relacionado:**
[`13/01` — DP con máscaras de bits](../13-dp-avanzada/01-mascaras-de-bits.md).
