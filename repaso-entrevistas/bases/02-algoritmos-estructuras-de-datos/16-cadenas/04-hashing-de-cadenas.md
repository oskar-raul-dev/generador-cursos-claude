# 04 — *Hashing* de cadenas aplicado

> El *hash* polinomial de `06/04` puesto a trabajar en problemas de cadenas: comparar dos subcadenas en
> `O(1)`, calcular el prefijo común más largo y el orden lexicográfico de dos sufijos con una búsqueda
> binaria, y responder «¿cuál es la longitud máxima tal que…?» con binaria sobre la respuesta más un
> conjunto de *hashes*. Con la cuenta que casi nadie hace: la probabilidad de colisión cuando las
> comparaciones son millones.
>
> **Niveles:** comparar subcadenas [B] · binaria + *hash* [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §32.2 (Rabin-Karp); [`06/04` — *Hashing* de secuencias](../06-lineales-y-hashing/04-hashing-de-secuencias.md),
> que es el dueño del *hash* polinomial.
>
> **Asume leído:** [`06/04` — *Hashing* de secuencias](../06-lineales-y-hashing/04-hashing-de-secuencias.md); [`16/02` — KMP y la función de prefijo](02-kmp.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--comparar-subcadenas) · [4](#4--binaria--hash) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

¿Cuál es la subcadena que aparece al menos dos veces y es la más larga, en un texto de `10⁵` caracteres?
Probar todas las subcadenas son `n²/2 = 5·10⁹`, y compararlas, más. Con KMP o Z no se ve cómo: no hay un
patrón fijo que buscar. La salida es combinar dos ideas: si una longitud `L` tiene una subcadena repetida,
cualquier `L′ < L` también (basta recortarla), así que la longitud se busca con una **binaria**; y para una
`L` fija, las `n − L + 1` subcadenas se comparan por su *hash* en un conjunto.

El *hash* de `06/04` convierte la comparación de subcadenas en una comparación de números en `O(1)`. El
precio es la probabilidad de error, que hay que controlar: un millón de comparaciones con un módulo de
`10⁹` ya no es «casi seguro».

> 🧠 **Modelo mental.** El *hash* es la huella dactilar de una subcadena: dos huellas distintas prueban que
> las cadenas son distintas; dos iguales lo sugieren con mucha confianza, si el diccionario de huellas es
> grande comparado con el número de cotejos.

Los ejemplos usan la cadena de juguete `"abracadabra"`: su subcadena repetida más larga es `"abra"`.

---

## 2. 📐 La teoría

**El *hash* de una subcadena** (`06/04`). Con los prefijos `H[i] = h(s[0..i))` y las potencias `P[i] = Bⁱ`
módulo `M`, `h(s[l..r)) = H[r] − H[l] · P[r − l]`. Dos subcadenas iguales tienen el mismo *hash*.

**Probabilidad de colisión de una comparación.** Con `M` primo y la base `B` elegida **al azar**, dos cadenas
distintas de longitud `L` colisionan con probabilidad `≤ (L − 1)/M`: la diferencia de sus *hashes* es un
polinomio de grado `< L` en `B`, que tiene como mucho `L − 1` raíces.

**Muchas comparaciones.** Por la cota de la unión, `Q` comparaciones fallan con probabilidad `≤ Q · L / M`.
Con `M ≈ 10⁹`, `Q = 10⁶` y `L = 10⁵`, la cota supera 1: no garantiza nada. Peor aún al meter `n` *hashes*
en un conjunto y buscar duplicados: hay `n²/2` pares, y con `n = 10⁵` y `M = 10⁹` la probabilidad de alguna
colisión entre **distintos** es del orden de `n² / (2M) ≈ 5` (paradoja del cumpleaños). De ahí que haga falta
`M ≈ 2⁶¹ − 1` o dos módulos: `n²/(2M) ≈ 10¹⁰ / 4·10¹⁸`, despreciable.

**Base aleatoria y anti-*hash*.** Con base fija y módulo `2⁶⁴` (el desbordamiento natural), existen
cadenas —las de Thue-Morse— que colisionan siempre; los jueces las usan. Base aleatoria y módulo primo
grande (`2⁶¹ − 1`) es la combinación segura.

**Prefijo común más largo (LCP) de dos sufijos.** La propiedad «`s[i..i+L) = s[j..j+L)`» es monótona en
`L`: si vale para `L`, vale para todo `L′ < L`. Por eso el LCP se encuentra con una búsqueda binaria de
`O(log n)` comparaciones de *hashes*. Y con el LCP, el orden lexicográfico de dos sufijos se decide mirando
el primer carácter distinto.

---

## 3. 🧱 Comparar subcadenas

**Qué es.** Una estructura con los prefijos de *hash* que responde en `O(1)` «¿son iguales `s[a..a+L)` y
`s[b..b+L)`?», y en `O(log n)` su LCP y su orden.

**Por qué es correcto.** Iguales ⇒ mismo *hash* siempre; mismo *hash* ⇒ iguales salvo con la probabilidad de
colisión de §2. La binaria del LCP es correcta por la monotonía.

**Cómo va**, en `abracadabra`:

```text
h(s[0..4)) = h(s[7..11)) → «abra» = «abra»
LCP(sufijo 0, sufijo 7): ¿L = 4? sí; ¿L = 5? no hay 5 caracteres en el sufijo 7 → LCP = 4
orden: el sufijo 7 («abra») es prefijo del sufijo 0 («abracadabra») → sufijo 7 < sufijo 0
s[0..4) frente a s[3..7): «abra» y «acad»; LCP = 1, y en la posición 1, b < c → «abra» < «acad»
```

**Cuánto.** `Θ(n)` preproceso; igualdad `O(1)`; LCP y orden `O(log n)`.

**La plantilla**, con módulo `2⁶¹ − 1` y base aleatoria:

```cpp
#include <chrono>
#include <cstdint>
#include <random>
#include <string>
#include <vector>

// Hash polinomial módulo 2^61 − 1. El producto de 128 bits se reduce sin división.
struct StringHash {
    static constexpr uint64_t MOD = (1ULL << 61) - 1;
    static uint64_t mul(uint64_t a, uint64_t b) {
        __uint128_t p = (__uint128_t)a * b;
        uint64_t r = (uint64_t)(p & MOD) + (uint64_t)(p >> 61);
        return r >= MOD ? r - MOD : r;
    }
    std::vector<uint64_t> h, pw;
    const std::string& s;
    explicit StringHash(const std::string& str) : h(str.size() + 1, 0), pw(str.size() + 1, 1), s(str) {
        static const uint64_t base =
            std::mt19937_64(std::chrono::steady_clock::now().time_since_epoch().count())() % (MOD - 256) + 256;
        for (size_t i = 0; i < str.size(); i++) {
            h[i + 1] = (mul(h[i], base) + (unsigned char)str[i]) % MOD;
            pw[i + 1] = mul(pw[i], base);
        }
    }
    uint64_t get(int l, int r) const {                   // hash de s[l..r)
        uint64_t v = h[r] + MOD - mul(h[l], pw[r - l]);
        return v >= MOD ? v - MOD : v;
    }
    int lcp(int a, int b) const {                        // prefijo común de los sufijos a y b
        int lo = 0, hi = (int)s.size() - std::max(a, b);
        while (lo < hi) {
            int mid = (lo + hi + 1) / 2;
            if (get(a, a + mid) == get(b, b + mid)) lo = mid; else hi = mid - 1;
        }
        return lo;
    }
    int compare(int a, int b, int len) const {           // −1, 0, 1 para s[a..a+len) frente a s[b..b+len)
        int l = std::min(lcp(a, b), len);
        if (l == len) return 0;
        return s[a + l] < s[b + l] ? -1 : 1;
    }
};
```

```java
// Módulo 2^61 − 1 con Math.multiplyHigh (Java 9+). Base aleatoria por ejecución.
static final long MOD = (1L << 61) - 1;

static long mul(long a, long b) {
    long hi = Math.multiplyHigh(a, b), lo = a * b;     // producto de 128 bits: hi·2^64 + lo
    long r = (lo & MOD) + (lo >>> 61) + (hi << 3);      // 2^64 ≡ 2^3 (mod 2^61 − 1)
    r = (r & MOD) + (r >>> 61);
    return r >= MOD ? r - MOD : r;
}

static long[] h, pw;
static char[] s;

static void build(String str) {
    s = str.toCharArray();
    int n = s.length;
    long base = java.util.concurrent.ThreadLocalRandom.current().nextLong(256, MOD);
    h = new long[n + 1]; pw = new long[n + 1]; pw[0] = 1;
    for (int i = 0; i < n; i++) {
        h[i + 1] = (mul(h[i], base) + s[i]) % MOD;
        pw[i + 1] = mul(pw[i], base);
    }
}

static long get(int l, int r) {                         // hash de s[l..r)
    long v = h[r] - mul(h[l], pw[r - l]);
    return v < 0 ? v + MOD : v;
}

static int lcp(int a, int b) {
    int lo = 0, hi = s.length - Math.max(a, b);
    while (lo < hi) {
        int mid = (lo + hi + 1) >>> 1;
        if (get(a, a + mid) == get(b, b + mid)) lo = mid; else hi = mid - 1;
    }
    return lo;
}
```

- **`2⁶¹ − 1`** permite reducir sin división (es un primo de Mersenne) y da colisiones despreciables; con
  dos módulos de `10⁹` el efecto es parecido, con el doble de operaciones.
- **La base aleatoria por ejecución** es lo que da la cota de §2; con una base fija, un caso de prueba
  diseñado puede romperla.
- **Palíndromos con *hash***: el *hash* de `s` y el de su inversa; `s[l..r)` es palíndromo si su *hash*
  coincide con el del tramo simétrico de la inversa. Con modificaciones de letras, los prefijos se
  sustituyen por un Fenwick o un árbol de segmentos ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)).
- **Python** cabe: sus enteros no desbordan, y `(a * b) % MOD` con `MOD = 2**61 − 1` es directo, aunque más
  lento.

**Cuándo sí:** muchas comparaciones de subcadenas arbitrarias; LCP y orden de sufijos sin construir un
*suffix array*; palíndromos con modificaciones. **Cuándo no:** si un algoritmo exacto lineal lo resuelve
(KMP, Z, Manacher): no hay razón para aceptar una probabilidad de error.

> **Veredicto:** con prefijos de *hash* módulo `2⁶¹ − 1` y base aleatoria, comparar subcadenas cuesta
> `O(1)` y el LCP `O(log n)`; el error es despreciable y controlado.

---

## 4. 🧱 Binaria + *hash*

**Qué es.** Para preguntas «la mayor longitud `L` tal que existe una subcadena de longitud `L` con la
propiedad», cuando la propiedad es monótona en `L`: búsqueda binaria sobre `L` y, para cada `L`, los
*hashes* de todas las ventanas de longitud `L` en un conjunto.

**Por qué es correcto.** Si hay una subcadena repetida de longitud `L`, recortándola hay una de cada
longitud menor: el predicado es monótono, y la binaria encuentra la frontera (`05/04`). Para cada `L`, dos
ventanas iguales tienen el mismo *hash*.

**Cómo va**, la subcadena repetida más larga de `abracadabra`:

```text
L = 5: ventanas abrac braca racad acada cadab adabr dabra → ninguna repetida → no
L = 3: abr aparece en 0 y 7 → sí
L = 4: abra aparece en 0 y 7 → sí
respuesta: 4 («abra»), tras log₂ 11 ≈ 4 pruebas de Θ(n) cada una
```

**Cuánto.** `Θ(n log n)` con un conjunto *hash* (o `Θ(n log² n)` ordenando los *hashes*).

**La plantilla:**

```cpp
#include <algorithm>
#include <string>
#include <unordered_set>
#include <vector>

// Sobre la StringHash de §3: longitud de la subcadena repetida más larga (apariciones solapadas valen).
int longestRepeated(const StringHash& sh, int n) {
    auto repeats = [&](int L) {
        std::vector<uint64_t> v;
        v.reserve(n - L + 1);
        for (int i = 0; i + L <= n; i++) v.push_back(sh.get(i, i + L));
        std::sort(v.begin(), v.end());                  // ordenar es seguro frente a hashes adversarios
        return std::adjacent_find(v.begin(), v.end()) != v.end();
    };
    int lo = 0, hi = n - 1;                             // L = 0 siempre vale
    while (lo < hi) {
        int mid = (lo + hi + 1) / 2;
        if (repeats(mid)) lo = mid; else hi = mid - 1;
    }
    return lo;
}
```

```java
// Sobre get(l, r) de §3.
static int longestRepeated(int n) {
    int lo = 0, hi = n - 1;
    while (lo < hi) {
        int mid = (lo + hi + 1) >>> 1;
        long[] v = new long[n - mid + 1];
        for (int i = 0; i + mid <= n; i++) v[i] = get(i, i + mid);
        java.util.Arrays.sort(v);                         // long[]: dual-pivot quicksort, sin objetos
        boolean found = false;
        for (int i = 1; i < v.length && !found; i++) found = v[i] == v[i - 1];
        if (found) lo = mid; else hi = mid - 1;
    }
    return lo;
}
```

- **Ordenar en lugar de un conjunto *hash*** evita el *hashing* de la biblioteca (atacable, [`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)) y los
  objetos; cuesta un `log` más.
- **Para recuperar la subcadena**, guardar el índice junto al *hash* al ordenar.
- **Dos cadenas** (subcadena común más larga): los *hashes* de las ventanas de una en un conjunto y buscar
  las de la otra, con la misma binaria.

**Cuándo sí:** subcadena repetida o común más larga, «la mayor `L` con…» sobre subcadenas, cuando un
*suffix array* ([`16/06`](06-suffix-array-y-automaton.md)) sería más largo de escribir. **Cuándo no:** si el predicado no es monótono en `L`;
o si hace falta la respuesta exacta sin riesgo (*suffix array* con LCP).

> **Veredicto:** «la mayor longitud tal que…» sobre subcadenas es una binaria sobre `L` con los *hashes*
> de las ventanas; `Θ(n log n)` y diez líneas sobre la estructura de §3.

---

## 5. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| Preproceso de prefijos | `Θ(n)` | Una vez por cadena (y otra para la inversa) |
| ¿`s[a..a+L) = s[b..b+L)`? | `O(1)` | Probabilística: error `≤ L / M` |
| LCP de dos sufijos | `O(log n)` | Binaria sobre `L` |
| Orden lexicográfico de dos subcadenas | `O(log n)` | LCP y un carácter |
| Subcadena repetida más larga | `Θ(n log n)` | Binaria + conjunto (o `n log² n` ordenando) |
| Igual con *suffix array* | `Θ(n log n)` | Exacto, más largo de escribir (`16/06`) |

---

## 6. 🧭 Cómo se elige

```text
¿Un patrón fijo en un texto? → KMP o Z (exactos y lineales)
¿Comparar muchas subcadenas arbitrarias, LCP, orden? → hashing con 2⁶¹ − 1
¿«La mayor longitud con…» y es monótona? → binaria + hash
¿Hace falta exactitud garantizada o muchas consultas de LCP? → suffix array + LCP (16/06)
¿Hay modificaciones de letras? → hash en un Fenwick o árbol de segmentos
```

> **Regla de entrevista:** si propones *hashing*, di en la misma frase cómo controlas las colisiones:
> «módulo `2⁶¹ − 1`, base aleatoria; con `10⁵` *hashes*, la probabilidad de colisión es del orden de
> `10⁻⁹`».

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «La subcadena más larga que se repite / que comparten» | Binaria + *hash* | Monótona en `L` |
| «Compara estas dos subcadenas» muchas veces | Prefijos de *hash* y LCP | `O(log n)` por consulta |
| «Cuántas subcadenas distintas de longitud `L`» | *Hashes* de ventanas en un conjunto | Una pasada |
| «Palíndromo» con modificaciones de letras | *Hash* directo e inverso en Fenwick | Actualizaciones puntuales |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Con *hash* no hace falta KMP» | El *hash* es probabilístico; KMP es exacto y lineal: si basta KMP, se usa KMP |
| «Con un módulo de `10⁹ + 7` sobra» | Con `10⁵` *hashes* en un conjunto, la colisión es casi segura (cumpleaños): `2⁶¹ − 1` o doble módulo |
| «El desbordamiento de `unsigned long long` es un buen módulo» | Con base fija, las cadenas de Thue-Morse colisionan siempre |
| «La base puede ser 31 o 131» | Fija, es atacable; aleatoria por ejecución da la cota |
| «El LCP necesita un *suffix array*» | Con *hash* y binaria, `O(log n)` por par |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §32.2: Rabin-Karp y la aritmética modular del *hash*. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*String Hashing*](https://cp-algorithms.com/string/string-hashing.html).

---

## 🧠 Preguntas

1. ¿Cómo se obtiene el *hash* de una subcadena a partir de los prefijos? 🟢
2. ¿Por qué un *hash* igual no garantiza que las cadenas sean iguales? 🟢
3. ¿Qué es la búsqueda binaria + *hash* y qué propiedad necesita? 🟢
4. ¿Cómo calculas el LCP de dos sufijos con *hashes*? 🟡
5. ¿Cómo comparas lexicográficamente dos subcadenas con *hashes*? 🟡
6. ¿Por qué se elige la base al azar? 🟡
7. ¿Cómo implementas el producto módulo `2⁶¹ − 1` en C++, en Java y en Python? 🟡
8. Acota la probabilidad de que dos cadenas distintas de longitud `L` colisionen con base aleatoria. 🟠
9. ¿Por qué meter `10⁵` *hashes* en un conjunto con módulo `10⁹` es arriesgado? Haz la cuenta. 🟠
10. ¿Cómo compruebas si una subcadena es palíndromo con *hashes*, y cómo lo mantienes con modificaciones? 🟠
11. ¿Cuándo prefieres KMP o Z a *hashing*? 🔴
12. Calcula la subcadena común más larga de dos cadenas de `10⁵` y di el coste. 🔴

---

## 🧩 Problemas propios

### ¿Antes o después?

**Nivel:** 🟡 · **Formato:** programa completo.

Para cada consulta `a b L` (posiciones desde 1), compara `s[a..a+L−1]` con `s[b..b+L−1]` e imprime `<`,
`=` o `>` según el orden lexicográfico.

- **Entrada.** Una línea con `s`. Una línea con `q`. Después, `q` líneas con `a b L`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ |s|, q ≤ 2·10⁵`; las dos subcadenas caben en `s`.

```text
Entrada         Salida
abracadabra     =
4               <
1 8 4           >
1 4 4           =
5 1 2
2 9 3

Entrada         Salida
ba              >
2               <
1 2 1
2 1 1
```

**Pista 1:** si sabes cuántos caracteres coinciden al principio, ¿qué carácter decide el orden?

### La subcadena común más larga

**Nivel:** 🟠 · **Formato:** programa completo.

Imprime la longitud de la subcadena más larga que aparece en `a` y en `b`.

- **Entrada.** Una línea con `a` y otra con `b`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ |a|, |b| ≤ 10⁵`; minúsculas.

```text
Entrada         Salida
abracadabra     3
cadena

Entrada         Salida
abc             0
xyz
```

**Pista 1:** si comparten una subcadena de longitud `L`, ¿comparten una de longitud `L − 1`?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con un *hash* que da WA «a veces», cambia la base por otra aleatoria y
> vuelve a enviar: si el veredicto cambia, es una colisión, no un error de lógica. Si una IA te ayuda, que
> sea a revisar el módulo y la base ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [String Hashing](https://open.kattis.com/problems/hashing) | Kattis | 🟡 | *Hash* de subcadenas | ¿Qué fórmula da el *hash* de `s[l..r)` desde los prefijos? |
| [ ] | [Finding Patterns](https://cses.fi/problemset/task/2102) | CSES | 🟠 | Muchas búsquedas | Con `k` patrones, ¿puedes agrupar por longitud y usar *hashes*? |
| [ ] | [Longest Duplicate Substring](https://leetcode.com/problems/longest-duplicate-substring/) | LeetCode | 🔴 | Binaria + *hash* | Si una longitud `L` se repite, ¿se repite `L − 1`? |
| [ ] | [Petr#](https://codeforces.com/problemset/problem/113/B) | Codeforces | 🟠 | Subcadenas distintas con condición | ¿Cómo cuentas subcadenas distintas sin guardarlas? |
| [ ] | [Palindrome Queries](https://cses.fi/problemset/task/2420) | CSES | 🔴 | *Hash* directo e inverso con Fenwick | Con modificaciones, ¿qué estructura mantiene sumas de prefijos? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Longest Common Subpath](https://leetcode.com/problems/longest-common-subpath/) | LeetCode | 🔴 | Binaria + *hash* sobre arreglos | Con muchos caminos, ¿qué conjunto intersecas para cada `L`? |
| [ ] | [Count Prefix and Suffix Pairs II](https://leetcode.com/problems/count-prefix-and-suffix-pairs-ii/) | LeetCode | 🔴 | Bordes por *hash* | ¿Qué pares (prefijo, sufijo) de longitud `k` tiene cada palabra? |
| [ ] | [Double Profiles](https://codeforces.com/problemset/problem/154/C) | Codeforces | 🔴 | *Hash* de conjuntos de vecinos | ¿Cuándo tienen dos perfiles los mismos amigos, con y sin incluirse? |

---

## ✅ Criterio de dominio

- Escribir los prefijos de *hash* con `2⁶¹ − 1` y base aleatoria con la plantilla delante.
- Calcular LCP y orden de dos subcadenas con binaria.
- Justificar la probabilidad de colisión de una comparación y de un conjunto.
- Resolver Longest Duplicate Substring y Palindrome Queries sin pista 2.

---

**Anterior:** [`16/03` — Función Z y Manacher](03-funcion-z-y-manacher.md) · **Siguiente:** [`16/05` — Aho-Corasick](05-aho-corasick.md) ·
**Relacionado:** [`05/04` — Búsqueda binaria](../05-orden-y-busqueda/04-busqueda-binaria.md).
