# 01 — DP con máscaras de bits

> La programación dinámica cuyo estado es un **subconjunto**, codificado como una máscara de bits: la
> asignación y el viajante en `O(2ⁿ · n²)` en lugar de `O(n!)`, el recorrido de las submáscaras en `O(3ⁿ)`
> y la suma sobre subconjuntos (SOS) en `O(2ⁿ · n)`.
>
> **Niveles:** DP sobre subconjuntos [B] · viajante [B] · SOS DP [B].
>
> **📚 Lectura troncal:** Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 6;
> cp-algorithms, [*Enumerating submasks of a bitmask*](https://cp-algorithms.com/algebra/all-submasks.html).
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--dp-sobre-subconjuntos) · [4](#4--viajante) · [5](#5--sos-dp) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un repartidor tiene que visitar 16 clientes y volver. Probar todos los órdenes son `15! ≈ 1,3·10¹²`
recorridos: no cabe. Pero lo que importa para continuar un recorrido parcial no es **en qué orden** se
visitaron los clientes, sino **cuáles** se visitaron y **dónde** está ahora. Esos estados son
`2¹⁶ · 16 ≈ 10⁶`, y desde cada uno hay 16 opciones: `1,7·10⁷` pasos.

Es la DP de Held y Karp (1962), y la idea se aplica a todo problema donde el estado natural es «qué
elementos ya se usaron»: asignaciones, emparejamientos, ordenaciones con coste entre vecinos. El viajante
es NP-difícil ([`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md)); lo que hace esta DP es que el exponente caiga en `2ⁿ` en lugar de en `n!`.

```text
n = 16     n! ≈ 2·10¹³      2ⁿ · n² ≈ 1,7·10⁷
n = 20     n! ≈ 2,4·10¹⁸    2ⁿ · n² ≈ 4·10⁸     (al límite)
```

---

## 2. 📐 La teoría

**El estado es un subconjunto.** Con `n ≤ 20`, un subconjunto de `{0, …, n − 1}` es un entero de `[0, 2ⁿ)`
(la biyección de `10/02`), y sirve directamente como índice de una tabla. Las operaciones son las de bits
([`17/01`](../17-matematica/01-bits.md)): `m | (1 << j)` añade `j`, `(m >> j) & 1` pregunta si está.

**El orden de cálculo es el orden numérico.** Si la transición solo **añade** elementos, `m | (1 << j) > m`,
así que recorrer las máscaras de menor a mayor respeta las dependencias. (Si las quitara, de mayor a menor.)

**El viajante (Held-Karp).** `dp[S][v]` = el coste mínimo de un camino que sale de 0, visita exactamente los
vértices de `S` y acaba en `v ∈ S`:

```text
dp[{0}][0] = 0
dp[S ∪ {u}][u] = min sobre v ∈ S de dp[S][v] + w(v, u)        para u ∉ S
respuesta (ciclo) = min sobre v de dp[todos][v] + w(v, 0)
```

Correcto por el principio de optimalidad: lo mejor que se puede hacer desde «visité `S` y estoy en `v`» no
depende del orden en que se visitó `S`. Coste `Θ(2ⁿ · n²)` tiempo y `Θ(2ⁿ · n)` memoria.

**Las submáscaras.** `for (s = m; s > 0; s = (s − 1) & m)` recorre todas las submáscaras no vacías de `m` en
orden decreciente. Recorriéndolo para todas las `m`, el total es `Σ 2^|m| = 3ⁿ` (cada bit está fuera de
`m`, en `m` y no en `s`, o en los dos).

**La suma sobre subconjuntos (SOS).** `F[m] = Σ_{s ⊆ m} f[s]` para todas las `m` a la vez. Con las
submáscaras cuesta `3ⁿ`; procesando **bit a bit** —primero se suma sobre el bit 0, luego sobre el 1…—, cada
`F[m]` acumula lo suyo en `n` pasos: `Θ(2ⁿ · n)`. Es la prefix sum en `n` dimensiones de tamaño 2.

---

## 3. 🧱 DP sobre subconjuntos

**Qué es.** Una DP cuyo estado incluye una máscara de los elementos ya usados. El caso más limpio es la
**asignación**: `n` personas, `n` tareas, `g[i][j]` el beneficio de dar a la persona `i` la tarea `j`; la
persona que toca asignar es `popcount(m)`, así que el estado es solo la máscara.

**Por qué es correcto** (enunciado y una frase). `dp[m]` = el mejor beneficio asignando las tareas de `m` a
las personas `0..|m| − 1`; la transición asigna una tarea libre a la siguiente persona, y cada asignación
completa tiene un único camino (por orden de personas).

**Cómo va**, con `g = [[5, 2, 9], [1, 5, 6], [9, 1, 5]]`: la persona 0 coge la tarea 2 (9), la 1 la 1 (5) y
la 2 la 0 (9): 23, el máximo de las 6 permutaciones.

**Cuánto.** `2ⁿ` máscaras por `n` transiciones: `Θ(2ⁿ · n)`, frente a `n!` de probar las permutaciones.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Asignación de beneficio máximo: la persona popcount(m) elige una tarea libre. Θ(2ⁿ · n).
long long assignment(const std::vector<std::vector<long long>>& g) {
    int n = (int)g.size();
    std::vector<long long> dp(1 << n, -1);
    dp[0] = 0;
    for (int m = 0; m < (1 << n); m++) {
        if (dp[m] < 0) continue;                                   // inalcanzable
        int person = __builtin_popcount(m);
        if (person == n) continue;
        for (int task = 0; task < n; task++)
            if (!(m >> task & 1))
                dp[m | 1 << task] = std::max(dp[m | 1 << task], dp[m] + g[person][task]);
    }
    return dp[(1 << n) - 1];
}
```

```java
// Asignación de beneficio máximo: la persona bitCount(m) elige una tarea libre. Θ(2ⁿ · n).
static long assignment(long[][] g) {
    int n = g.length;
    long[] dp = new long[1 << n];
    java.util.Arrays.fill(dp, -1);
    dp[0] = 0;
    for (int m = 0; m < (1 << n); m++) {
        if (dp[m] < 0) continue;
        int person = Integer.bitCount(m);
        if (person == n) continue;
        for (int task = 0; task < n; task++)
            if ((m >> task & 1) == 0)
                dp[m | 1 << task] = Math.max(dp[m | 1 << task], dp[m] + g[person][task]);
    }
    return dp[(1 << n) - 1];
}
```

- **`popcount(m)`** dice qué persona toca: el estado no necesita guardarla.
- **«Empuje» hacia delante** (`dp[m | bit] = max(…)`) en lugar de «tirar» desde atrás: es más fácil de
  escribir cuando la transición añade elementos.
- **`−1` como inalcanzable** vale porque los beneficios son no negativos; con negativos, un centinela aparte.

**Cuándo sí**: `n ≤ 20` y el estado natural es «qué elementos ya se usaron». **Cuándo no**: con `n` grande y
estructura de flujo (la asignación general es el algoritmo húngaro, `O(n³)`, o flujo de coste mínimo,
[`15/07`](../15-grafos-pesos-y-flujos/07-grafos-de-nivel-experto.md)).

> **Veredicto:** cuando el orden no importa pero el conjunto sí, la máscara es el estado. `2ⁿ` en lugar de
> `n!` es la diferencia entre `n = 20` y `n = 10`.

---

## 4. 🧱 Viajante

**Qué es.** El ciclo (o camino) de coste mínimo que visita todos los vértices una vez, con Held-Karp.

**Por qué es correcto** (enunciado y una frase). Por la recurrencia de §2: el futuro de un recorrido parcial
solo depende del conjunto visitado y del vértice actual.

**Cómo va**, en el grafo de juguete G (`A-B 2 · A-C 4 · B-D 3 · B-E 1 · C-E 7 · D-F 2 · E-F 5`, con las
aristas ausentes a infinito): el único ciclo hamiltoniano es `A → B → D → F → E → C → A`, de coste
`2 + 3 + 2 + 5 + 7 + 4 = 23`, y la DP lo encuentra sin enumerar los `5! = 120` órdenes.

**Cuánto.** `Θ(2ⁿ · n²)` tiempo y `Θ(2ⁿ · n)` memoria: con `n = 20`, `4·10⁸` operaciones y 20 millones de
entradas (160 MB en `long`, 80 MB en `int`).

**La plantilla**, el ciclo desde el vértice 0:

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Ciclo hamiltoniano de coste mínimo desde 0; w[v][u] = coste (INF si no hay arista). Θ(2ⁿ · n²).
long long tsp(const std::vector<std::vector<long long>>& w) {
    int n = (int)w.size(), full = (1 << n) - 1;
    const long long INF = LLONG_MAX / 4;
    std::vector<std::vector<long long>> dp(1 << n, std::vector<long long>(n, INF));
    dp[1][0] = 0;                                                    // visitado {0}, en 0
    for (int S = 1; S <= full; S++) {
        if (!(S & 1)) continue;                                      // todo camino contiene al 0
        for (int v = 0; v < n; v++) {
            if (!(S >> v & 1) || dp[S][v] >= INF) continue;
            for (int u = 0; u < n; u++)
                if (!(S >> u & 1) && w[v][u] < INF)
                    dp[S | 1 << u][u] = std::min(dp[S | 1 << u][u], dp[S][v] + w[v][u]);
        }
    }
    long long best = INF;
    for (int v = 1; v < n; v++)
        if (dp[full][v] < INF && w[v][0] < INF) best = std::min(best, dp[full][v] + w[v][0]);
    return n == 1 ? 0 : best;                                        // INF: no hay ciclo
}
```

```java
// Ciclo hamiltoniano de coste mínimo desde 0; w[v][u] = coste (INF si no hay arista). Θ(2ⁿ · n²).
static long tsp(long[][] w) {
    int n = w.length, full = (1 << n) - 1;
    final long INF = Long.MAX_VALUE / 4;
    long[][] dp = new long[1 << n][n];
    for (long[] row : dp) java.util.Arrays.fill(row, INF);
    dp[1][0] = 0;
    for (int S = 1; S <= full; S++) {
        if ((S & 1) == 0) continue;
        for (int v = 0; v < n; v++) {
            if ((S >> v & 1) == 0 || dp[S][v] >= INF) continue;
            for (int u = 0; u < n; u++)
                if ((S >> u & 1) == 0 && w[v][u] < INF)
                    dp[S | 1 << u][u] = Math.min(dp[S | 1 << u][u], dp[S][v] + w[v][u]);
        }
    }
    long best = INF;
    for (int v = 1; v < n; v++)
        if (dp[full][v] < INF && w[v][0] < INF) best = Math.min(best, dp[full][v] + w[v][0]);
    return n == 1 ? 0 : best;
}
```

- **`INF = MAX / 4`**: así `INF + w` no desborda; además se comprueba antes de sumar.
- **Saltar las máscaras sin el 0** divide los estados útiles a la mitad.
- **Para el camino** (sin volver), la respuesta es `min_v dp[full][v]`; para empezar en cualquier vértice, se
  inicializan todos los `dp[1 << v][v] = 0`.
- **Memoria**: con `n = 20` en Java, `long[1 << 20][20]` son un millón de arreglos; un único `long[]` de
  `(1 << n) · n` ahorra cabeceras.

**Cuándo sí**: «visitar todos una vez», «el orden de `n ≤ 20` elementos con coste entre consecutivos».
**Cuándo no**: `n ≥ 25`; ahí, ramificación y poda ([`10/03`](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md)) o heurísticas ([`20/05`](../20-ad-hoc-constructivos-e-interactivos/05-heuristicos-y-aproximados.md)).

> **Veredicto:** el viajante no se resuelve solo por fuerza bruta: Held-Karp lo baja de `n!` a `2ⁿ · n²`,
> que con `n ≤ 20` cabe. Sigue siendo exponencial, como corresponde a un NP-difícil.

---

## 5. 🧱 SOS DP

**Qué es.** Calcular para **todas** las máscaras `m` la suma (o el máximo, o la cuenta) de `f` sobre sus
submáscaras, en `Θ(2ⁿ · n)`.

**Por qué es correcto** (enunciado y una frase). Tras procesar los bits `0..b`, `F[m]` es la suma de `f[s]`
sobre las `s ⊆ m` que coinciden con `m` en los bits mayores que `b`; al procesar el bit `b + 1`, las máscaras
con ese bit encendido suman la de su gemela sin él, y el invariante avanza un bit.

**Cómo va**, con los valores `[5, 2, 9, 1, 5, 6]` como máscaras de 4 bits y `f[x]` = cuántas veces aparece
`x`: `F[7] = 5` (5, 2, 1, 5 y 6 son submáscaras de `0111`), `F[6] = 2` (2 y 6), `F[15] = 6`.

**Cuánto.** `n` pasadas sobre `2ⁿ` máscaras: `Θ(2ⁿ · n)`. Con `n = 20`, `2·10⁷`.

**La plantilla:**

```cpp
#include <vector>

// F[m] = Σ f[s] sobre las submáscaras s de m, para todas las m. Θ(2ⁿ · n). En el sitio.
void sumOverSubsets(std::vector<long long>& F, int bits) {
    for (int b = 0; b < bits; b++)
        for (int m = 0; m < (1 << bits); m++)
            if (m >> b & 1) F[m] += F[m ^ (1 << b)];         // suma la gemela sin el bit b
}

// Recorrer las submáscaras no vacías de m: Θ(2^popcount(m)); para todas las m, Θ(3ⁿ).
// for (int s = m; s > 0; s = (s - 1) & m) { … }
```

```java
// F[m] = Σ f[s] sobre las submáscaras s de m, para todas las m. Θ(2ⁿ · n). En el sitio.
static void sumOverSubsets(long[] F, int bits) {
    for (int b = 0; b < bits; b++)
        for (int m = 0; m < (1 << bits); m++)
            if ((m >> b & 1) == 1) F[m] += F[m ^ (1 << b)];
}
```

- **El bucle de bits va por fuera.** Con las máscaras por fuera, una submáscara se sumaría por varios
  caminos y se contaría de más.
- **Supermáscaras**: para `Σ` sobre las `s ⊇ m`, la condición es el bit **apagado** y se suma la gemela con
  el bit encendido.
- **La inversa** (de `F` a `f`) es restar en lugar de sumar: es la inclusión-exclusión.

**Cuándo sí**: «para cada máscara, cuántos/cuánto de sus submáscaras (o supermáscaras)», AND u OR igual a
cero, compatibilidades por bits con valores de hasta `2²⁰`. **Cuándo no**: con valores de 30 bits, `2³⁰` no
cabe; si solo hay pocas consultas, recorrer las submáscaras de cada una puede bastar.

> **Veredicto:** SOS es una suma de prefijos en `n` dimensiones de tamaño 2. Bit por fuera, máscara por
> dentro, y `3ⁿ` pasa a `2ⁿ · n`.

---

## 6. ⏱️ La tabla de costes

| Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Asignación por máscaras | `Θ(2ⁿ · n)` | `Θ(2ⁿ)` | El húngaro hace `O(n³)` para `n` grande |
| Viajante (Held-Karp) | `Θ(2ⁿ · n²)` | `Θ(2ⁿ · n)` | Con `n = 20`, la memoria es el límite |
| Todas las submáscaras de todas las máscaras | `Θ(3ⁿ)` | — | `3¹⁸ ≈ 3,9·10⁸` |
| SOS DP | `Θ(2ⁿ · n)` | `Θ(2ⁿ)` | Bit por fuera; la inversa es inclusión-exclusión |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| `n ≤ 20` y «visitar todos», «asignar uno a uno», «ordenar con coste entre vecinos» | DP sobre máscaras | El estado es el conjunto usado |
| «Cada uno exactamente una vez», con `n ≤ 16`–`20` | Held-Karp | `2ⁿ · n²` cabe; `n!` no |
| «Para cada máscara, cuántos valores son submáscara», AND igual a 0 | SOS DP | Suma sobre subconjuntos |
| Partir `n ≤ 16` elementos en grupos con coste por grupo | Submáscaras en `3ⁿ` | `dp[m] = min dp[m \ s] + coste(s)` |
| `n ≤ 12` y pocos estados por elemento | Puede bastar la permutación (`10/02`) | `12!` aún es grande; `2¹²` es nada |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El viajante solo se resuelve por fuerza bruta» | Held-Karp lo hace en `Θ(2ⁿ · n²)`; con `n ≤ 20` cabe |
| «En SOS, máscaras por fuera y bits por dentro» | Bits por fuera: si no, se cuenta de más |
| «Recorrer las submáscaras de todas las máscaras es `4ⁿ`» | Es `3ⁿ`: cada bit tiene tres situaciones |
| «`INF + w` está bien» | Desborda con `MAX_VALUE`: `MAX / 4` y comprobar antes |
| «La máscara puede tener 64 elementos» | La tabla mide `2ⁿ`: `n ≤ 20`–`24` como mucho |
| «`1 << n` con `n = 31`» | Desborda `int`: con más de 30 bits, `1L << n` |

---

## 📚 Para profundizar

- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 6: la DP sobre
  subconjuntos y el viajante. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Enumerating submasks of a bitmask*](https://cp-algorithms.com/algebra/all-submasks.html):
  el recorrido en `3ⁿ` y su prueba. *Lectura troncal.*
- **Referencia** — USACO Guide, [*Bitmask DP*](https://usaco.guide/gold/dp-bitmasks) y [*Sum over Subsets DP*](https://usaco.guide/plat/dp-sos).
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  cap. 34: el viajante como problema NP-completo.

---

## 🧠 Preguntas

1. ¿Qué estado usa Held-Karp y cuántos estados hay? 🟢
2. ¿Cuánto cuesta recorrer todas las submáscaras de todas las máscaras de `n` bits, y por qué? 🟢
3. ¿Qué calcula la SOS DP y en cuánto tiempo? 🟢
4. ¿Por qué en la asignación por máscaras el estado no necesita guardar qué persona toca? 🟡
5. ¿Por qué el orden numérico de las máscaras es un orden válido de cálculo? 🟡
6. ¿Por qué en SOS el bucle de bits va por fuera? 🟡
7. Compara cómo cuentas los bits de una máscara y cómo representas `2ⁿ` estados en C++, Java y Python. 🟡
8. Deriva la recurrencia de Held-Karp y explica por qué el principio de optimalidad se cumple. 🟠
9. ¿Cómo cambias Held-Karp para un camino que puede acabar en cualquier vértice, o empezar en cualquiera? 🟠
10. ¿Cómo calculas la suma sobre **supermáscaras** en lugar de submáscaras? 🟠
11. Demuestra que `s = (s − 1) & m` recorre exactamente las submáscaras de `m`. 🔴
12. Partir `n ≤ 16` tareas en grupos que caben en un camión de capacidad `C`, minimizando los viajes: diseña la DP y di su coste. 🔴
13. Tu Held-Karp en Java da MLE con `n = 20`. ¿Qué cambias? 🔴

---

## 🧩 Problemas propios

### Asignación de turnos

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` trabajadores y `n` turnos; `g[i][j]` es la satisfacción del trabajador `i` con el turno `j`. Cada
uno recibe un turno distinto. Imprime la satisfacción total máxima.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 20`; `0 ≤ g[i][j] ≤ 10⁶`.

```text
Entrada     Salida
3           23
5 2 9
1 5 6
9 1 5

Entrada     Salida
2           16
9 8
8 1
```

**Pista 1:** con `n = 20`, ¿cuántas permutaciones hay, y cuántos conjuntos de turnos ya asignados?

### Ruta por todas las tiendas

**Nivel:** 🟠 · **Formato:** programa completo.

Un repartidor sale del almacén 0 y tiene que pasar por todas las tiendas `1..n − 1`, acabando en
cualquiera (no vuelve). `d[i][j]` es el tiempo de ir de `i` a `j`. Imprime el tiempo mínimo.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 18`; `0 ≤ d[i][j] ≤ 10⁶`; `d[i][i] = 0`.

```text
Entrada            Salida
4                  16
0 2 9 10
1 0 6 4
15 7 0 8
6 3 12 0

Entrada            Salida
1                  0
0
```

**Pista 1:** para seguir el recorrido, ¿qué necesitas saber de lo ya hecho: el orden, o algo menos?

### Submáscaras de cada consulta

**Nivel:** 🟠 · **Formato:** programa completo.

Hay `n` números y `q` consultas `x`. Para cada consulta, imprime cuántos números `a` cumplen
`a & x = a` (todos los bits de `a` están en `x`).

- **Entrada.** Una línea con `n` y `q`. Una línea con los números. Una línea con las consultas.
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ n, q ≤ 10⁶`; `0 ≤ a, x < 2²⁰`.

```text
Entrada            Salida
6 4                5
5 2 9 1 5 6        6
7 15 0 6           0
                   2

Entrada            Salida
3 2                2
0 0 1048575        3
0 1048575
```

**Pista 1:** con `10⁶` consultas, ¿puedes precalcular la respuesta para **todas** las `x` posibles?

---

## 🧩 Práctica externa

Las bases solo llegan en dificultad alta; la plataforma específica es CSES, con AtCoder y Codeforces para
la ampliación.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Hamiltonian Flights](https://cses.fi/problemset/task/1690) | CSES | 🟡 | Caminos hamiltonianos por máscaras | ¿Qué basta saber de un vuelo parcial para continuarlo? |
| [ ] | [Elevator Rides](https://cses.fi/problemset/task/1653) | CSES | 🟠 | Máscara con un estado extra | Además de quién ya subió, ¿qué necesitas del último viaje? |
| [ ] | [Matching](https://atcoder.jp/contests/dp/tasks/dp_o) | AtCoder | 🟡 | Asignación por máscaras | ¿Qué hombre toca emparejar si ya se emparejaron `k` mujeres? |
| [ ] | [Shortest Path Visiting All Nodes](https://leetcode.com/problems/shortest-path-visiting-all-nodes/) | LeetCode | 🟠 | BFS sobre (máscara, nodo) | ¿Qué estado repite un BFS ingenuo? |
| [ ] | [Minimum XOR Sum of Two Arrays](https://leetcode.com/problems/minimum-xor-sum-of-two-arrays/) | LeetCode | 🟠 | Asignación por máscaras | ¿A qué elemento del segundo arreglo emparejas el siguiente del primero? |
| [ ] | [Parallel Courses II](https://leetcode.com/problems/parallel-courses-ii/) | LeetCode | 🟠 | Submáscaras | En un semestre, ¿qué cursos están disponibles y cuántos puedes elegir? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Number of Ways to Wear Different Hats to Each Other](https://leetcode.com/problems/number-of-ways-to-wear-different-hats-to-each-other/) | LeetCode | 🟠 | Máscara sobre el lado pequeño | ¿Qué lado conviene poner en la máscara: 40 sombreros o 10 personas? |
| [ ] | [SOS Bit Problem](https://cses.fi/problemset/task/1654) | CSES | 🔴 | SOS sobre submáscaras y supermáscaras | Para `x \| y = x`, ¿son los `y` submáscaras o supermáscaras de `x`? |
| [ ] | [Compatible Numbers](https://codeforces.com/problemset/problem/165/E) | Codeforces | 🔴 | SOS con un testigo | Si `a & b = 0`, ¿qué relación hay entre `b` y el complemento de `a`? |
| [ ] | [Counting Tilings](https://cses.fi/problemset/task/2181) | CSES | 🔴 | Máscara de perfil | Al avanzar columna a columna, ¿qué casillas de la siguiente columna ya están ocupadas? |

---

## ✅ Criterio de dominio

- Escribir Held-Karp sin mirar, con el `INF` que no desborda, en menos de quince minutos.
- Escribir SOS con el orden de bucles correcto y explicar por qué.
- Recorrer las submáscaras de una máscara y justificar el `3ⁿ`.
- Resolver Hamiltonian Flights y Matching sin pista 2.

---

**Anterior:** — · **Siguiente:** [`13/02` — *Digit DP*](02-digit-dp.md) · **Relacionado:**
[`10/02` — Generar subconjuntos, permutaciones y combinaciones](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md); [`17/01` — Bits](../17-matematica/01-bits.md).
