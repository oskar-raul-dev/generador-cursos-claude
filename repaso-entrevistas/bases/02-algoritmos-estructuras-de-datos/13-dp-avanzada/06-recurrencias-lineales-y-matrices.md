# 06 — Recurrencias lineales y exponenciación de matrices

> Cómo calcular el término `10¹⁸` de una recurrencia lineal —Fibonacci, un conteo con transiciones fijas,
> el número de caminos de longitud `k` en un grafo— sin recorrer los términos: la recurrencia es una
> multiplicación por una matriz fija, y la potencia `k`-ésima de una matriz se calcula con exponenciación
> rápida en `O(m³ log k)`.
>
> **Niveles:** exponenciación de matrices [B].
>
> **📚 Lectura troncal:** Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994),
> cap. 7; cp-algorithms, [*Binary Exponentiation*](https://cp-algorithms.com/algebra/binary-exp.html)
> (la sección de matrices).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--exponenciación-de-matrices) · [4](#4--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

`F(10¹⁸) mod 10⁹ + 7`. La tabla de [`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md) recorre los `10¹⁸` términos: siglos. Pero el paso de un par de
términos al siguiente es **lineal** y **siempre el mismo**:

```text
⎡ F(n+1) ⎤   ⎡ 1  1 ⎤ ⎡ F(n)   ⎤                 ⎡ F(n+1) ⎤   ⎡ 1  1 ⎤ⁿ ⎡ 1 ⎤
⎣ F(n)   ⎦ = ⎣ 1  0 ⎦ ⎣ F(n−1) ⎦     y por tanto  ⎣ F(n)   ⎦ = ⎣ 1  0 ⎦  ⎣ 0 ⎦
```

Avanzar `n` pasos es multiplicar por la `n`-ésima potencia de una matriz de 2 × 2, y esa potencia se calcula
con la exponenciación rápida de [`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md): unas 60 multiplicaciones de matrices de 2 × 2.

> 🧠 **Modelo mental.** Si una DP avanza por pasos con una transición **lineal** que **no cambia** de un paso
> a otro, el paso es una matriz, y `n` pasos son su potencia. El tamaño de la matriz es el número de estados
> por paso.

---

## 2. 📐 La teoría

**Recurrencia lineal de orden `m`.** `a(n) = c₁ a(n−1) + c₂ a(n−2) + … + cₘ a(n−m)`. El vector de estado
`v(n) = (a(n), a(n−1), …, a(n−m+1))` avanza con la **matriz compañera**:

```text
⎡ c₁ c₂ … cₘ₋₁ cₘ ⎤
⎢ 1  0  …  0   0  ⎥        v(n+1) = T · v(n),     v(n) = Tⁿ⁻ᵐ⁺¹ · v(m−1)
⎢ 0  1  …  0   0  ⎥
⎣ 0  0  …  1   0  ⎦
```

**Por qué la exponenciación rápida es correcta.** El producto de matrices es **asociativo** (aunque no
conmutativo), y eso es todo lo que necesita el invariante `resultado · baseᵉ = Tⁿ` de `10/05`: las matrices
cuadradas con el producto forman un monoide, con la identidad como neutro.

**Términos constantes y variables.** `a(n) = 2a(n−1) + 3a(n−2) + 5` no es lineal homogénea, pero se
convierte añadiendo la constante al vector: `(a(n), a(n−1), 5)` con la matriz
`[[2, 3, 1], [1, 0, 0], [0, 0, 1]]`. Lo mismo con un término `n` (se añade `(n, 1)`) o con la suma de los
términos anteriores (se añade el acumulado).

**Caminos de longitud `k`.** Si `A` es la matriz de adyacencia de un grafo, `(Aᵏ)[i][j]` es el número de
caminos (paseos, con repeticiones) de longitud exactamente `k` de `i` a `j`. Es la DP de conteo de [`12/06`](../12-dp-clasica/06-conteo.md)
sobre «estoy en el vértice `v` tras `t` pasos», con la transición `A`. Cambiando `(+, ·)` por `(min, +)`, la
misma potencia da el camino **más barato** de exactamente `k` aristas.

**Cuánto.** Un producto de matrices `m × m` cuesta `Θ(m³)`, y la potencia necesita `⌊log₂ n⌋ + 1`
cuadrados y como mucho otros tantos productos: `Θ(m³ log n)`. Con `m = 100` y `n = 10¹⁸`, `6·10⁷`.

---

## 3. 🧱 Exponenciación de matrices

**Qué es.** Elevar la matriz de transición a la potencia del número de pasos, con la exponenciación rápida,
y multiplicar por el vector inicial.

**Por qué es correcto** (enunciado y una frase). Por asociatividad, `T · T · … · T · v = Tⁿ · v`, y `Tⁿ` se
obtiene con el algoritmo de cuadrados repetidos, que solo usa asociatividad y el neutro.

**Cómo va**, `F(10)`: `10 = 1010₂`, así que se combinan `T²` y `T⁸`:

```text
T¹ = [[1,1],[1,0]]   T² = [[2,1],[1,1]]   T⁴ = [[5,3],[3,2]]   T⁸ = [[34,21],[21,13]]
T¹⁰ = T⁸ · T² = [[89, 55], [55, 34]]          F(10) = 55, F(11) = 89
```

**Cuánto.** `Θ(m³ log n)` tiempo, `Θ(m²)` memoria.

**La plantilla:**

```cpp
#include <vector>

using Matrix = std::vector<std::vector<long long>>;
const long long MOD = 1'000'000'007;

Matrix multiply(const Matrix& A, const Matrix& B) {
    int n = (int)A.size(), m = (int)B[0].size(), k = (int)B.size();
    Matrix C(n, std::vector<long long>(m, 0));
    for (int i = 0; i < n; i++)
        for (int t = 0; t < k; t++) {
            if (A[i][t] == 0) continue;
            for (int j = 0; j < m; j++) C[i][j] = (C[i][j] + A[i][t] * B[t][j]) % MOD;   // orden i-t-j: localidad
        }
    return C;
}

// Tᵉ mod MOD. Θ(m³ log e).
Matrix matPow(Matrix T, long long e) {
    int n = (int)T.size();
    Matrix R(n, std::vector<long long>(n, 0));
    for (int i = 0; i < n; i++) R[i][i] = 1;                    // identidad
    for (; e > 0; e >>= 1) {
        if (e & 1) R = multiply(R, T);
        T = multiply(T, T);
    }
    return R;
}
// F(n) = matPow({{1,1},{1,0}}, n)[0][1]
```

```java
static final long MOD = 1_000_000_007L;

static long[][] multiply(long[][] A, long[][] B) {
    int n = A.length, m = B[0].length, k = B.length;
    long[][] C = new long[n][m];
    for (int i = 0; i < n; i++)
        for (int t = 0; t < k; t++) {
            if (A[i][t] == 0) continue;
            long a = A[i][t];
            for (int j = 0; j < m; j++) C[i][j] = (C[i][j] + a * B[t][j]) % MOD;
        }
    return C;
}

// Tᵉ mod MOD. Θ(m³ log e).
static long[][] matPow(long[][] T, long e) {
    int n = T.length;
    long[][] R = new long[n][n];
    for (int i = 0; i < n; i++) R[i][i] = 1;
    for (; e > 0; e >>= 1) {
        if ((e & 1) == 1) R = multiply(R, T);
        T = multiply(T, T);
    }
    return R;
}
```

- **El orden de los bucles `i-t-j`** recorre `B` por filas: con matrices de 100 × 100, la diferencia con
  `i-j-t` es visible.
- **`% MOD` tras cada producto**: `(10⁹)² ≈ 10¹⁸` cabe en 64 bits; la suma de dos de esos no, por eso se
  reduce en cada término.
- **La identidad** es el neutro: con `e = 0`, `T⁰ = I`.
- **Para el vector**, en lugar de elevar y después multiplicar, se puede multiplicar el vector por cada
  potencia necesaria: `Θ(m² log n)` si solo se quiere un término, pero con la matriz completa ya calculada
  se responden varias consultas.

**Cuándo sí**: recurrencias lineales con coeficientes constantes y `n` hasta `10¹⁸`; DP de conteo con pocos
estados por paso y muchísimos pasos (palabras de longitud `10¹⁸` con transiciones fijas, `12/06`); caminos de
longitud `k`. **Cuándo no**: si `n ≤ 10⁷`, la tabla es más simple; si la transición cambia con `n`
(coeficientes que dependen de `n`), no hay una matriz fija; si `m` es grande (`m ≥ 300`), `m³ log n` no cabe y
hace falta Berlekamp-Massey o el polinomio característico ([`17/11`](../17-matematica/11-funciones-generadoras.md)).

> **Veredicto:** para `n = 10¹⁸` no hay que iterar: la transición es una matriz y `n` pasos son su potencia.
> El coste lo marca el número de estados por paso, al cubo.

---

## 4. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| `n` hasta `10¹⁸` en una recurrencia o un conteo por pasos | Exponenciación de matrices | `log n` pasos |
| «Número de caminos de longitud exactamente `k`» | Potencia de la matriz de adyacencia | `(Aᵏ)[i][j]` |
| «Camino más barato con exactamente `k` aristas», `k` enorme | Potencia en `(min, +)` | Mismo esquema, otro semianillo |
| Recurrencia con un término constante o con `n` | Matriz aumentada | Se añaden componentes al vector |
| Muchos estados por paso (`m ≥ 300`) | Polinomio característico o Berlekamp-Massey (`17/11`) | `m³` no cabe |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Para `n = 10¹⁸` hay que iterar» | Con la matriz de transición, `60` productos |
| «El producto de matrices es conmutativo» | No lo es; la potencia funciona porque es **asociativo** |
| «La matriz compañera tiene los coeficientes en la primera columna» | En la primera **fila**; el resto es una identidad desplazada |
| «`A[i][t] * B[t][j]` suma sin reducir» | Dos productos de `10¹⁸` desbordan al sumarse: se reduce en cada término |
| «El término constante impide usar matrices» | Se añade la constante como una componente más del vector |
| «`Aᵏ` cuenta caminos simples» | Cuenta paseos: pueden repetir vértices |

---

## 📚 Para profundizar

- **Libro** — Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994), cap. 7:
  recurrencias lineales y funciones generadoras. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Binary Exponentiation*](https://cp-algorithms.com/algebra/binary-exp.html):
  la aplicación a matrices y a transformaciones lineales. *Lectura troncal.*
- **Referencia** — USACO Guide, [*Matrix Exponentiation*](https://usaco.guide/plat/matrix-expo).
- **Libro** — Strang, *Introduction to Linear Algebra*, 6.ª ed. (Wellesley-Cambridge, 2023): el producto de
  matrices y su asociatividad.

---

## 🧠 Preguntas

1. ¿Qué matriz avanza la sucesión de Fibonacci un paso? 🟢
2. ¿Cuánto cuesta calcular `Tⁿ` para una matriz `m × m`? 🟢
3. ¿Qué cuenta `(Aᵏ)[i][j]` si `A` es la matriz de adyacencia? 🟢
4. ¿Por qué basta la asociatividad para la exponenciación rápida de matrices, si el producto no es conmutativo? 🟡
5. ¿Cómo se escribe la matriz compañera de una recurrencia lineal de orden `m`? 🟡
6. ¿Cómo incluyes un término constante en la recurrencia? 🟡
7. Compara cómo evitas el desbordamiento en el producto de matrices módulo `10⁹ + 7` en C++, Java y Python. 🟡
8. ¿Qué cambia para calcular el camino más barato con exactamente `k` aristas? 🟠
9. ¿Por qué el orden de bucles `i-t-j` es más rápido que `i-j-t`? 🟠
10. ¿Cuándo es mejor la tabla de `12/01` que la potencia de la matriz? 🟠
11. ¿Cómo calculas la suma `a(0) + a(1) + … + a(n)` de una recurrencia lineal con `n = 10¹⁸`? 🟠
12. Diseña la matriz para contar palabras de longitud `n = 10¹⁸` sobre `{a, b, c}` sin `aa` ni `bc`, y di su tamaño. 🔴
13. Tu potencia de matrices da el resultado correcto para `n` pequeño y basura para `n = 10¹⁸`. ¿Qué miras? 🔴

---

## 🧩 Problemas propios

### Tribonacci gigante

**Nivel:** 🟢 · **Formato:** programa completo.

`T(0) = 0`, `T(1) = 0`, `T(2) = 1` y `T(n) = T(n−1) + T(n−2) + T(n−3)`. Imprime `T(n) mod 10⁹ + 7`.

- **Entrada.** Una línea con `n`.
- **Salida.** Un entero.
- **Restricciones.** `0 ≤ n ≤ 10¹⁸`.

```text
Entrada     Salida
9           44

Entrada     Salida
2           1

Entrada                   Salida
1000000000000000000       913728402
```

**Pista 1:** ¿qué tres valores necesitas para dar un paso, y cómo se obtienen los tres siguientes?

### Paseos cerrados

**Nivel:** 🟡 · **Formato:** programa completo.

En un grafo dirigido de `n` vértices, ¿cuántos paseos de longitud exactamente `k` empiezan y acaban en el
mismo vértice (sumando sobre todos los vértices)? Imprime el resultado módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n`, `m` y `k`. Después, `m` líneas con una arista `a b` (de 1 a `n`).
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 100`; `0 ≤ m ≤ n²`; `1 ≤ k ≤ 10¹⁸`.

```text
Entrada     Salida
4 7 3       9
1 2
1 3
2 3
2 4
3 1
3 4
4 1

Entrada     Salida
4 7 1       0
1 2
1 3
2 3
2 4
3 1
3 4
4 1
```

**Pista 1:** si sabes cuántos paseos de longitud `k` hay de cada `i` a cada `j`, ¿qué entradas sumas?

### Recurrencia con constante

**Nivel:** 🟠 · **Formato:** programa completo.

`a(0) = 0`, `a(1) = 1` y `a(n) = 2a(n−1) + 3a(n−2) + 5`. Imprime `a(n) mod 10⁹ + 7`.

- **Entrada.** Una línea con `n`.
- **Salida.** Un entero.
- **Restricciones.** `0 ≤ n ≤ 10¹⁸`.

```text
Entrada     Salida
6           637

Entrada     Salida
2           7

Entrada                   Salida
1000000000000000000       965544602
```

**Pista 1:** el 5 no depende de los términos anteriores; ¿qué pasa si lo tratas como una componente más del
estado que no cambia?

---

## 🧩 Práctica externa

Codility no tiene exponenciación de matrices; la específica es la sección de matemáticas de CSES.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Fibonacci Finding (easy)](https://www.hackerrank.com/challenges/fibonacci-finding-easy/problem) | HackerRank | 🟡 | Matriz de 2 × 2 con condiciones iniciales | ¿Qué matriz lleva `(F(1), F(0)) = (b, a)` a `(F(n+1), F(n))`? |
| [ ] | [Fibonacci Numbers](https://cses.fi/problemset/task/1722) | CSES | 🟡 | Matriz de 2 × 2 | ¿Cuántas multiplicaciones hacen falta para `n = 10¹⁸`? |
| [ ] | [Throwing Dice](https://cses.fi/problemset/task/1096) | CSES | 🟡 | Matriz compañera de orden 6 | ¿De qué seis valores depende la cuenta de la suma `n`? |
| [ ] | [Graph Paths I](https://cses.fi/problemset/task/1723) | CSES | 🟡 | Potencia de la adyacencia | ¿Qué entrada de `Aᵏ` cuenta los caminos de 1 a `n`? |
| [ ] | [Number of Ways to Paint N × 3 Grid](https://leetcode.com/problems/number-of-ways-to-paint-n-3-grid/) | LeetCode | 🟠 | Pocos tipos de fila y transición fija | ¿En cuántos tipos se agrupan las filas válidas? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Plant](https://codeforces.com/problemset/problem/185/A) | Codeforces | 🟡 | Matriz de 2 × 2 con dos tipos | ¿Cuántos triángulos de cada tipo salen de uno de cada tipo? |
| [ ] | [Magic Gems](https://codeforces.com/problemset/problem/1117/D) | Codeforces | 🟠 | Matriz compañera de orden `M` | Si una gema mágica se parte en `M`, ¿de qué términos anteriores depende `f(n)`? |
| [ ] | [Graph Paths II](https://cses.fi/problemset/task/1724) | CSES | 🟠 | Potencia en `(min, +)` | Si cambias suma por mínimo y producto por suma, ¿qué calcula `Aᵏ`? |
| [ ] | [Student Attendance Record II](https://leetcode.com/problems/student-attendance-record-ii/) | LeetCode | 🟠 | DP de pocos estados | ¿Qué estados lleva el registro: ausencias y retrasos seguidos? |

---

## ✅ Criterio de dominio

- Escribir la potencia de matrices sin mirar, con la reducción en cada término.
- Construir la matriz compañera de una recurrencia, con término constante si lo hay.
- Explicar por qué basta la asociatividad y qué cambia en `(min, +)`.
- Resolver Throwing Dice y Graph Paths II sin pista 2.

---

**Anterior:** [`13/05` — Optimizaciones de DP](05-optimizaciones.md) · **Siguiente:** [`13/07` — Trucos de nivel alto](07-trucos-de-nivel-alto.md) ·
**Relacionado:** [`10/05` — Divide y vencerás](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md); [`17/07` — Matrices y eliminación de Gauss](../17-matematica/07-matrices-y-gauss.md); [`17/11` — Funciones generadoras y Berlekamp-Massey](../17-matematica/11-funciones-generadoras.md).
