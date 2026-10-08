# 03 — Estructuras probabilísticas

> Estructuras que responden en poco espacio a cambio de un error acotado y conocido: el filtro de Bloom dice
> si un elemento **puede** estar en un conjunto (nunca da falsos negativos), Count-Min estima frecuencias por
> exceso, HyperLogLog cuenta elementos distintos con unos kilobytes y MinHash estima la semejanza de dos
> conjuntos. Para cada una, qué error acepta, cómo se dimensiona y dónde aparece.
>
> **Niveles:** Bloom [B] · Count-Min [B] · HyperLogLog [C] · MinHash [C].
>
> **📚 Lectura troncal:** La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), cap. 4;
> Kubica, *Data Structures the Fun Way* (No Starch, 2022), cap. 13; Medjedovic, Tahirovic y Dedovic,
> *Algorithms and Data Structures for Massive Datasets* (Manning, 2022), caps. 3–5.
>
> **Asume leído:** [`19/02` — *Hashing* universal y análisis esperado](02-hashing-universal-y-analisis-esperado.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--bloom) · [4](#4--count-min) · [5](#5--hyperloglog) · [6](#6--minhash) · [7](#7-️-la-tabla-de-costes) · [8](#8--cómo-se-elige) · [9](#9--señales-del-enunciado) · [10](#10--dónde-aparece-de-verdad) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un servicio de acortar URL recibe mil millones de enlaces y, antes de ir a la base de datos, quiere saber si
un enlace **seguro que no** está registrado. Un conjunto *hash* de mil millones de cadenas ocupa decenas de
gigabytes. Un filtro de Bloom con un 1 % de falsos positivos ocupa 1,2 GB, cabe en memoria, y nunca dice «no
está» de algo que sí está: los «quizá» van a la base de datos; los «no», no.

Ese es el trato de todo el capítulo: renunciar a la respuesta exacta, con un error que se conoce y se elige,
a cambio de memoria pequeña (a veces de tamaño **constante**, sin importar cuántos datos pasen).

> 🧠 **Modelo mental.** Bloom y Count-Min son la misma idea: varias funciones de *hash* que marcan o suman en
> una tabla pequeña. Las colisiones solo pueden **añadir**, nunca quitar: de ahí que Bloom no tenga falsos
> negativos y Count-Min nunca subestime.

---

## 2. 📐 La teoría

**Filtro de Bloom.** Un arreglo de `m` bits y `k` funciones de *hash*. Insertar pone a 1 los `k` bits;
consultar responde «quizá» si los `k` están a 1 y «no» si alguno está a 0. Con `n` elementos insertados, la
probabilidad de un falso positivo es aproximadamente:

```text
ε ≈ (1 − e^{−kn/m})ᵏ
k óptimo = (m/n) · ln 2            bits por elemento = −ln ε / (ln 2)² ≈ 1,44 · log₂(1/ε)
```

Con `ε = 1 %`: 9,6 bits por elemento y `k = 7`. Con `0,1 %`: 14,4 bits y `k = 10`. **No hay falsos
negativos**: un elemento insertado tiene sus `k` bits a 1 para siempre (no se borra).

**Count-Min.** Una tabla de `d` filas y `w` columnas, una función de *hash* por fila. Sumar `c` a `x` suma `c`
en la celda `hᵢ(x)` de cada fila; la estimación es el **mínimo** de las `d` celdas. Con `N` la suma total de
las cuentas:

```text
f(x) ≤ estimación(x) ≤ f(x) + ε·N   con probabilidad ≥ 1 − δ,   si  w = ⌈e/ε⌉,  d = ⌈ln(1/δ)⌉
```

**HyperLogLog.** Para contar elementos distintos: se mira, en el *hash* de cada elemento, la posición del
primer 1. Ver un *hash* que empieza por `r` ceros es un suceso de probabilidad `2^{−r}`: sugiere unos `2ʳ`
distintos. Con `m` registros (cada elemento va a uno según sus primeros bits) y una media armónica, el error
estándar es `1,04 / √m`.

**MinHash.** La semejanza de Jaccard de dos conjuntos es `J(A, B) = |A ∩ B| / |A ∪ B|`. Con una función de
*hash* al azar, `P[min h(A) = min h(B)] = J(A, B)`: el elemento de menor *hash* de la unión está en la
intersección con esa probabilidad. Con `k` funciones, la fracción de mínimos iguales estima `J` con error
`≈ 1/√k`.

---

## 3. 🧱 Bloom

**Qué es.** Un conjunto aproximado: inserta y consulta en `O(k)`, con falsos positivos de tasa conocida y sin
falsos negativos.

**Por qué es correcto.** Tras `n` inserciones, un bit concreto sigue a 0 con probabilidad `(1 − 1/m)^{kn} ≈
e^{−kn/m}`. Un elemento no insertado da falso positivo si sus `k` bits están a 1: aproximadamente
`(1 − e^{−kn/m})ᵏ`. Derivando, el mínimo está en `k = (m/n) ln 2`, con la mitad de los bits a 1.

**Cómo va**, para `n = 1 000` y `ε = 1 %`:

```text
m = −n ln ε / (ln 2)² = 9 585,06 → 9 586 bits (1,2 KB)
k = (m/n) ln 2 = 6,64 → 7 funciones
ε real con m = 9 586, k = 7: (1 − e^{−7·1000/9586})⁷ = 1,003 %
```

**Cuánto.** `O(k)` por operación; `m` bits de memoria, independiente del tamaño de los elementos.

**La plantilla**, con dos *hashes* combinados (`h₁ + i·h₂`), que basta para simular `k` funciones
(Kirsch y Mitzenmacher):

```cpp
#include <cstdint>
#include <vector>

struct BloomFilter {
    std::vector<uint64_t> bits;
    uint64_t m, seed;
    int k;
    BloomFilter(uint64_t mBits, int hashes, uint64_t s) : bits((mBits + 63) / 64), m(mBits), seed(s), k(hashes) {}

    static uint64_t mix(uint64_t x) {                           // splitmix64
        x += 0x9e3779b97f4a7c15ULL;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
        x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
        return x ^ (x >> 31);
    }
    void add(uint64_t key) {
        uint64_t h1 = mix(key ^ seed), h2 = mix(h1) | 1;
        for (int i = 0; i < k; i++) {
            uint64_t b = (h1 + i * h2) % m;
            bits[b >> 6] |= 1ULL << (b & 63);
        }
    }
    bool mightContain(uint64_t key) const {                     // false: seguro que no está
        uint64_t h1 = mix(key ^ seed), h2 = mix(h1) | 1;
        for (int i = 0; i < k; i++) {
            uint64_t b = (h1 + i * h2) % m;
            if (!(bits[b >> 6] >> (b & 63) & 1)) return false;
        }
        return true;
    }
};
```

```java
static final class BloomFilter {
    final long[] bits;
    final long m, seed;
    final int k;
    BloomFilter(long mBits, int hashes, long s) {
        bits = new long[(int) ((mBits + 63) / 64)]; m = mBits; k = hashes; seed = s;
    }
    static long mix(long x) {                                   // splitmix64
        x += 0x9e3779b97f4a7c15L;
        x = (x ^ (x >>> 30)) * 0xbf58476d1ce4e5b9L;
        x = (x ^ (x >>> 27)) * 0x94d049bb133111ebL;
        return x ^ (x >>> 31);
    }
    void add(long key) {
        long h1 = mix(key ^ seed), h2 = mix(h1) | 1;
        for (int i = 0; i < k; i++) {
            long b = Long.remainderUnsigned(h1 + i * h2, m);
            bits[(int) (b >>> 6)] |= 1L << (b & 63);
        }
    }
    boolean mightContain(long key) {
        long h1 = mix(key ^ seed), h2 = mix(h1) | 1;
        for (int i = 0; i < k; i++) {
            long b = Long.remainderUnsigned(h1 + i * h2, m);
            if ((bits[(int) (b >>> 6)] >>> (b & 63) & 1) == 0) return false;
        }
        return true;
    }
}
```

- **Los bits empaquetados** en enteros de 64: `b >> 6` es la palabra y `b & 63` el bit. Un `vector<bool>` o
  un `BitSet` también sirven.
- **Sin signo.** En Java no hay `unsigned long`: `>>>` en lugar de `>>`, y `Long.remainderUnsigned` para que
  el módulo no salga negativo.
- **Claves que no son enteros**: se reduce primero la cadena a 64 bits (un *hash* de cadena,
  [`16/04`](../16-cadenas/04-hashing-de-cadenas.md)) y después se usa el filtro.
- **No se borra.** Poner un bit a 0 podría borrar otros elementos; para borrar hace falta un Bloom con
  contadores (4 bits por posición).

**Cuándo sí:** evitar consultas caras a disco o red para lo que seguro no está (bases de datos LSM, cachés,
navegadores con listas de URL peligrosas); deduplicar un flujo aceptando algunos falsos «ya visto».
**Cuándo no:** si un falso positivo es caro e irreversible; si hay que enumerar o borrar los elementos.

> **Veredicto:** Bloom responde «seguro que no» o «quizá». Con 10 bits por elemento y 7 funciones, el
> «quizá» se equivoca un 1 % de las veces; el «seguro que no», nunca.

---

## 4. 🧱 Count-Min

**Qué es.** Un contador de frecuencias aproximado: suma en `O(d)`, estima en `O(d)`, nunca por debajo.

**Por qué es correcto.** Cada celda contiene la cuenta de `x` más las de los elementos que chocan con él en
esa fila: nunca menos que `f(x)`. El exceso esperado en una fila es `N/w`; por Markov, pasa de `e·N/w = εN`
con probabilidad `≤ 1/e`; que pase en las `d` filas a la vez, con probabilidad `≤ e^{−d} = δ`. El mínimo
de las filas hereda la cota.

**Cómo va**, con `w = 5`, dos filas `h₁(x) = (3x + 1) mod 5` y `h₂(x) = (2x + 3) mod 5`, y el flujo
`5, 2, 9, 1, 5, 6`:

```text
fila 1: [0, 2, 1, 1, 2]        fila 2: [2, 1, 1, 2, 0]
estimación(5) = min(2, 2) = 2   (real 2)
estimación(1) = min(2, 2) = 2   (real 1: comparte celda con el 6 en las dos filas)
estimación(7) = min(1, 1) = 1   (real 0)
```

**Cuánto.** `O(d)` por operación; `d · w` contadores. Con `ε = 0,1 %` y `δ = 1 %`: `w = 2 719`, `d = 5`,
unos 13 600 contadores, para cualquier número de elementos distintos.

**La plantilla:**

```cpp
#include <algorithm>
#include <climits>
#include <cstdint>
#include <vector>

struct CountMin {
    int d, w;
    std::vector<std::vector<long long>> t;
    std::vector<uint64_t> seeds;
    CountMin(int rows, int cols, const std::vector<uint64_t>& s)
        : d(rows), w(cols), t(rows, std::vector<long long>(cols, 0)), seeds(s) {}
    int cell(int i, uint64_t x) const { return BloomFilter::mix(x ^ seeds[i]) % w; }
    void add(uint64_t x, long long c = 1) { for (int i = 0; i < d; i++) t[i][cell(i, x)] += c; }
    long long estimate(uint64_t x) const {
        long long best = LLONG_MAX;
        for (int i = 0; i < d; i++) best = std::min(best, t[i][cell(i, x)]);
        return best;
    }
};
```

```java
static final class CountMin {
    final int d, w;
    final long[][] t;
    final long[] seeds;
    CountMin(int rows, int cols, long[] s) { d = rows; w = cols; t = new long[rows][cols]; seeds = s; }
    int cell(int i, long x) { return (int) Long.remainderUnsigned(BloomFilter.mix(x ^ seeds[i]), w); }
    void add(long x, long c) { for (int i = 0; i < d; i++) t[i][cell(i, x)] += c; }
    long estimate(long x) {
        long best = Long.MAX_VALUE;
        for (int i = 0; i < d; i++) best = Math.min(best, t[i][cell(i, x)]);
        return best;
    }
}
```

- **Una semilla por fila**: las filas tienen que usar funciones independientes; con la misma, el mínimo no
  mejora nada.
- **Solo cuentas positivas.** Con restas, el mínimo deja de ser una cota superior; se usa la mediana.
- **Los más frecuentes** (*heavy hitters*): Count-Min más un *heap* de los `k` con mayor estimación.

**Cuándo sí:** frecuencias aproximadas en un flujo (consultas más buscadas, IP que más tráfico generan), con
memoria fija. **Cuándo no:** si las frecuencias pequeñas importan: el error es relativo a `N`, no a `f(x)`.

> **Veredicto:** Count-Min nunca subestima y sobrestima como mucho `εN` con probabilidad `1 − δ`. Sirve para
> los frecuentes; para los raros, el ruido es mayor que la señal.

---

## 5. 🧱 HyperLogLog

**Qué resuelve.** Contar elementos **distintos** de un flujo enorme (visitantes únicos, IP distintas) con
memoria fija.

**Qué garantiza.** Error estándar `1,04 / √m` con `m` registros de 6 bits. Con `m = 2¹⁴`: error del 0,81 % y
12 KB, para miles de millones de elementos. Dos HyperLogLog se **unen** tomando el máximo registro a registro:
cuenta los distintos de la unión.

**Cuánto.** `O(1)` por elemento; `m` registros.

**Cómo reconocerlo.** «Cuántos distintos» con datos que no caben, o en muchos servidores que hay que combinar.

**Si no te la sabes.** Un conjunto *hash* exacto si cabe; o contar distintos de una muestra (sesgado); o
*Linear Counting* (un mapa de bits) para cardinalidades pequeñas.

**Dónde está entera.** Medjedovic, Tahirovic y Dedovic, cap. 5; Flajolet y otros, «HyperLogLog: the analysis
of a near-optimal cardinality estimation algorithm», *AofA* (2007).

---

## 6. 🧱 MinHash

**Qué resuelve.** Estimar la semejanza de Jaccard de dos conjuntos (documentos, carritos, perfiles) sin
compararlos enteros, y encontrar pares parecidos entre millones (con LSH, *locality-sensitive hashing*).

**Qué garantiza.** Con `k` funciones de *hash*, la fracción de mínimos iguales estima `J(A, B)` sin sesgo y con
desviación `≈ √(J(1 − J)/k)`. Con `A = {a, b, c, d}` y `B = {c, d, e}`, `J = 2/5 = 0,4`.

**Cuánto.** `O(k · |A|)` para la firma; comparar dos firmas, `O(k)`.

**Cómo reconocerlo.** «Documentos casi duplicados», «usuarios parecidos», semejanza entre millones de pares.

**Si no te la sabes.** Calcular `|A ∩ B|` con un conjunto *hash*, `O(|A| + |B|)` por par; entra si los pares
son pocos.

**Dónde está entera.** Broder, «On the resemblance and containment of documents», *Compression and
Complexity of Sequences* (1997).

---

## 7. ⏱️ La tabla de costes

| Estructura | Pregunta | Memoria | Error | Lo que la tabla no dice |
|---|---|---|---|---|
| Bloom | ¿Está? | `1,44 log₂(1/ε)` bits por elemento | Falsos positivos `ε`; ningún falso negativo | No borra ni enumera |
| Count-Min | ¿Cuántas veces? | `(e/ε) · ln(1/δ)` contadores | `+εN` con probabilidad `1 − δ` | Nunca subestima; malo para lo raro |
| HyperLogLog | ¿Cuántos distintos? | `m` registros de 6 bits | `1,04/√m` relativo | Se une con el máximo |
| MinHash | ¿Cuán parecidos? | `k` *hashes* por conjunto | `≈ 1/√k` | Con LSH, busca pares parecidos sin compararlos todos |

---

## 8. 🧭 Cómo se elige

```text
¿Pertenencia, y un "seguro que no" ahorra trabajo? → Bloom
¿Frecuencias de un flujo con memoria fija? → Count-Min (+ heap para los k mayores)
¿Cuántos distintos? → cabe: conjunto hash · no cabe o hay que unir: HyperLogLog
¿Semejanza de conjuntos? → pocos pares: exacto · muchos: MinHash (+ LSH)
¿El error no es aceptable? → la estructura exacta, o memoria externa (19/06)
```

> **Regla de entrevista:** al proponer una de estas, di el error y la memoria en la misma frase: «un Bloom con
> el 1 % de falsos positivos son 10 bits por elemento: 1,2 GB para mil millones».

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Ya vimos esta URL?» con miles de millones | Bloom | 10 bits por elemento |
| «Las búsquedas más frecuentes de hoy» | Count-Min + *heap* | Memoria fija |
| «Visitantes únicos por día, en muchos servidores» | HyperLogLog | Se unen con el máximo |
| «Documentos casi duplicados» | MinHash | Estima Jaccard con `k` *hashes* |
| «Se aceptan falsos positivos, no falsos negativos» | Bloom | Es su contrato |

---

## 10. 🔭 Dónde aparece de verdad

- **Bases de datos LSM** (Cassandra, RocksDB, HBase): un Bloom por fichero evita leer del disco los ficheros
  que no tienen la clave.
- **Redis**: `PFADD` y `PFCOUNT` son HyperLogLog, 12 KB por contador con un error del 0,81 %.
- **Analítica de flujos**: Count-Min para las claves más frecuentes en sistemas de monitorización.
- **Buscadores**: MinHash y LSH para detectar páginas casi duplicadas.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Un Bloom puede dar falsos negativos» | Nunca: un elemento insertado tiene sus `k` bits a 1 para siempre |
| «Más funciones de *hash* siempre reducen el error» | Hay un óptimo, `k = (m/n) ln 2`; más funciones llenan el filtro |
| «Se puede borrar de un Bloom poniendo los bits a 0» | Borraría otros elementos; hace falta un Bloom con contadores |
| «Count-Min puede subestimar» | Con cuentas positivas, nunca: solo suma de más |
| «HyperLogLog necesita memoria proporcional a los distintos» | Es fija: `m` registros, sin importar cuántos haya |
| «El error de Count-Min es relativo a cada frecuencia» | Es `εN`, relativo al total: las frecuencias pequeñas quedan tapadas |

---

## 📚 Para profundizar

- **Libro** — La Rocca, *Advanced Algorithms and Data Structures* (Manning, 2021), cap. 4: Bloom, con el
  análisis y variantes. *Lectura troncal.*
- **Libro** — Kubica, *Data Structures the Fun Way* (No Starch, 2022), cap. 13: Bloom explicado desde cero.
  *Lectura troncal.*
- **Libro** — Medjedovic, Tahirovic y Dedovic, *Algorithms and Data Structures for Massive Datasets*
  (Manning, 2022), caps. 3 (Bloom y *quotient filters*), 4 (Count-Min) y 5 (HyperLogLog). *Lectura troncal.*
- **Artículo** — Cormode y Muthukrishnan, «An improved data stream summary: the count-min sketch and its
  applications», *Journal of Algorithms* 55(1), 2005.

---

## 🧠 Preguntas

1. ¿Qué responde un filtro de Bloom, y qué tipo de error tiene? 🟢
2. ¿Cuántos bits por elemento hacen falta para un 1 % de falsos positivos, y cuántas funciones? 🟢
3. ¿Qué estima Count-Min y en qué sentido se equivoca? 🟢
4. ¿Qué pregunta responde HyperLogLog, y con qué error? 🟢
5. ¿Por qué un Bloom no puede dar falsos negativos? 🟡
6. ¿Por qué hay un número óptimo de funciones de *hash* en un Bloom? 🟡
7. ¿Qué diferencia hay entre el error de Count-Min y un error relativo a cada frecuencia? 🟡
8. ¿Qué cambia entre C++ y Java al implementar el Bloom sobre enteros de 64 bits sin signo? 🟠
9. ¿Por qué no se puede borrar de un Bloom, y qué variante lo permite? 🟠
10. ¿Por qué Count-Min toma el mínimo de las filas y no la media? 🟠
11. Deduce la tasa de falsos positivos de un Bloom y el `k` que la minimiza. 🔴
12. Diseña cómo contar los usuarios distintos por día de 100 servidores, con memoria fija por servidor, y di
    el error. 🔴

---

## 🧩 Problemas propios

### Tasa de falsos positivos

**Nivel:** 🟢 · **Formato:** programa completo.

Para cada consulta con los parámetros `m`, `n` y `k` de un filtro de Bloom, imprime la tasa aproximada de
falsos positivos `(1 − e^{−kn/m})ᵏ` con 6 decimales.

- **Entrada.** Una línea con `q`. Después, `q` líneas con `m`, `n` y `k`.
- **Salida.** `q` líneas. Se aceptan errores de hasta `10⁻⁶`.
- **Restricciones.** `1 ≤ q ≤ 10⁵`; `1 ≤ m, n ≤ 10¹²`; `1 ≤ k ≤ 30`.

```text
Entrada             Salida
2                   0.221199
8 2 1               0.008194
10000 1000 7

Entrada             Salida
2                   0.000000
1000000000000 1 30  1.000000
1 1000000000000 1
```

**Pista 1:** ¿qué parte de la fórmula puede perder precisión cuando `kn/m` es muy pequeño, y hay alguna función
de la librería para eso?

### El contador aproximado

**Nivel:** 🟡 · **Formato:** programa completo.

Implementa un Count-Min con `d` filas y `w` columnas, cuya fila `i` usa la función
`hᵢ(x) = ((aᵢ·x + bᵢ) mod 1 000 000 007) mod w`. Se procesa un flujo de `n` valores (cada uno suma 1) y
después, para cada consulta, se imprime la estimación.

- **Entrada.** Una línea con `d` y `w`. Después, `d` líneas con `aᵢ` y `bᵢ`. Una línea con `n` y la siguiente
  con los `n` valores. Una línea con `q` y la siguiente con las `q` consultas.
- **Salida.** Una línea con las `q` estimaciones.
- **Restricciones.** `1 ≤ d ≤ 10`; `1 ≤ w ≤ 10⁵`; `1 ≤ aᵢ, bᵢ < 10⁹ + 7`; `1 ≤ n, q ≤ 10⁶`; valores entre `0` y
  `10⁹`.

```text
Entrada         Salida
2 4             2 1 2 1
3 1
5 3
5
1 2 3 1 4
4
1 3 5 2

Entrada         Salida
1 1             3 3
1 1
3
0 1000000000 7
2
5 0
```

**Pista 1:** ¿qué celda toca cada valor en cada fila, y qué se queda la estimación de entre las `d` celdas?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de dimensionar una de estas estructuras, escribe la fórmula del error y despeja la
> memoria: es lo que se pregunta en una entrevista de diseño. Si una IA te ayuda, que sea a revisar tu cuenta
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

Las bases y los jueces no tienen problemas sobre estas estructuras: la respuesta exacta siempre cabe en sus
límites. Se practican con los propios, con la simulación ([`19/07`](07-simulacion.md)) y con las preguntas de diseño.

---

## ✅ Criterio de dominio

- Dimensionar un Bloom para un `n` y un `ε` dados, con `m` y `k`, y explicar por qué no hay falsos negativos.
- Escribir el Bloom en C++ o Java sin mirar.
- Explicar la cota de Count-Min y por qué se toma el mínimo.
- Decir qué resuelven HyperLogLog y MinHash, con su error y su memoria.

---

**Anterior:** [`19/02` — *Hashing* universal y análisis esperado](02-hashing-universal-y-analisis-esperado.md) · **Siguiente:** [`19/04` — Muestreo y cadenas de Markov](04-muestreo-y-markov.md) ·
**Relacionado:** [`19/06` — Datos masivos](06-datos-masivos.md).
