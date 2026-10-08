# 03 — Mochilas

> La familia de la mochila: la 0/1 (cada objeto una vez), la ilimitada (cada objeto las veces que se
> quiera), la acotada (cada objeto hasta `cᵢ` veces, con la división binaria), y el cambio de monedas en
> sus dos versiones, contar y mínimo. Con la tabla en una sola fila, el sentido del bucle que la hace
> correcta, y por qué `O(n · W)` no es polinomial.
>
> **Niveles:** 0/1 [A] · ilimitada [A] · acotada con división binaria [B] · monedas: contar y mínimo [A] ·
> una fila de memoria [A].
>
> **📚 Lectura troncal:** Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 8;
> Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §6.4.
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--mochila-01) · [4](#4--una-fila-de-memoria) · [5](#5--mochila-ilimitada) · [6](#6--monedas-contar-y-mínimo) · [7](#7--mochila-acotada) · [8](#8-️-la-tabla-de-costes) · [9](#9--cómo-se-elige) · [10](#10--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Los objetos de [`10/03`](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md), `(peso, valor)` = `(5,10) (2,3) (9,14) (1,2) (5,8) (6,9)`, y una mochila de
capacidad 10. El voraz por valor/peso, que era óptimo en la mochila fraccionaria de [`11/03`](../11-voraces/03-plazos-huffman-y-monedas.md), aquí da 15;
el óptimo es 18 (`(5,10)` y `(5,8)`). La búsqueda completa prueba `2⁶ = 64` subconjuntos; con 100 objetos
serían `2¹⁰⁰`.

La DP de este capítulo lo hace en `O(n · W)`: con 100 objetos y capacidad `10⁴`, un millón de pasos. Y la
misma tabla, cambiando una línea, resuelve la ilimitada, las monedas y la partición en dos mitades.

> 🧠 **Modelo mental.** Una mochila es una DP sobre (objetos considerados, capacidad usada). Todas las
> variantes son la misma tabla; cambia **una dirección de bucle** o **un orden de bucles**, y esos cambios
> son exactamente los que el juez castiga.

Lo que se asume de [`12/01`](01-de-la-recursion-a-la-tabla.md): estado, transición, casos base, orden y respuesta; tabulación y reconstrucción por
padres.

---

## 2. 📐 La teoría

**La recurrencia de la 0/1.** `dp[i][c]` = el mejor valor con los `i` primeros objetos y capacidad `c`:

```text
dp[0][c] = 0
dp[i][c] = dp[i−1][c]                                   (no coger el objeto i)
         = max(dp[i−1][c], dp[i−1][c − wᵢ] + vᵢ)        (cogerlo, si wᵢ ≤ c)
```

Subestructura: si el óptimo coge el objeto `i`, el resto es un óptimo con capacidad `c − wᵢ` sobre los
`i − 1` anteriores; si no lo coge, es un óptimo con capacidad `c` sobre ellos. Las dos opciones cubren todo.

**Por qué es pseudopolinomial.** `n · W` es polinomial en el **valor** de `W`, pero `W` se escribe con
`log W` bits: con `W = 10¹⁸`, la entrada ocupa 60 bits y la tabla `10¹⁸` columnas. Eso no contradice que la
mochila sea NP-difícil (`10/05`): el algoritmo es rápido solo cuando los números son pequeños.

**La ilimitada** cambia una letra: si se coge el objeto `i`, **se sigue pudiendo coger**:

```text
dp[i][c] = max(dp[i−1][c], dp[i][c − wᵢ] + vᵢ)          (dp[i], no dp[i−1], en el segundo término)
```

**El sentido del bucle en una fila.** Con una sola fila `dp[c]`, recorrer `c` **de mayor a menor** lee
`dp[c − wᵢ]` todavía sin actualizar —es `dp[i−1][c − wᵢ]`: 0/1—; recorrer **de menor a mayor** lo lee ya
actualizado —es `dp[i][c − wᵢ]`: ilimitada—. La misma línea de código, con el bucle al revés, resuelve
el otro problema.

**Contar.** Para contar formas de pagar, el **anidamiento** de los bucles decide si se cuentan
combinaciones o sucesiones ordenadas (§6).

---

## 3. 🧱 Mochila 0/1

**Qué es.** Elegir un subconjunto de objetos de peso total `≤ W` con valor máximo; cada objeto, como mucho
una vez.

**Por qué es correcto.** Por la recurrencia de §2, con inducción sobre `i`.

**Cómo va**, la tabla por filas (cada fila, tras considerar un objeto más), capacidad 0 a 10:

```text
objeto     c:  0  1  2  3  4  5   6   7   8   9   10
(5,10)         0  0  0  0  0  10  10  10  10  10  10
(2,3)          0  0  3  3  3  10  10  13  13  13  13
(9,14)         0  0  3  3  3  10  10  13  13  14  14
(1,2)          0  2  3  5  5  10  12  13  15  15  16
(5,8)          0  2  3  5  5  10  12  13  15  15  18
(6,9)          0  2  3  5  5  10  12  13  15  15  18
reconstrucción desde (6,9), c = 10: no cambia → sin (6,9); con (5,8) sí: c = 5; … → (5,10) y (5,8)
```

**Cuánto.** `(n + 1)(W + 1)` estados por `O(1)`: `Θ(n · W)` tiempo y memoria con la tabla entera, que hace
falta para reconstruir.

**La plantilla**, con la tabla completa y la reconstrucción:

```cpp
#include <algorithm>
#include <vector>

// Mochila 0/1: mejor valor con capacidad W y los índices elegidos. Θ(n · W).
std::pair<long long, std::vector<int>> knapsack01(const std::vector<int>& w, const std::vector<long long>& v, int W) {
    int n = (int)w.size();
    std::vector<std::vector<long long>> dp(n + 1, std::vector<long long>(W + 1, 0));
    for (int i = 1; i <= n; i++)
        for (int c = 0; c <= W; c++) {
            dp[i][c] = dp[i - 1][c];                                       // no cogerlo
            if (w[i - 1] <= c) dp[i][c] = std::max(dp[i][c], dp[i - 1][c - w[i - 1]] + v[i - 1]);
        }
    std::vector<int> chosen;
    for (int i = n, c = W; i >= 1; i--)
        if (dp[i][c] != dp[i - 1][c]) { chosen.push_back(i - 1); c -= w[i - 1]; }   // se cogió
    std::reverse(chosen.begin(), chosen.end());
    return {dp[n][W], chosen};
}
```

```java
// Mochila 0/1: mejor valor con capacidad W. La reconstrucción sigue dp como en C++. Θ(n · W).
static long knapsack01(int[] w, long[] v, int W) {
    int n = w.length;
    long[][] dp = new long[n + 1][W + 1];
    for (int i = 1; i <= n; i++)
        for (int c = 0; c <= W; c++) {
            dp[i][c] = dp[i - 1][c];
            if (w[i - 1] <= c) dp[i][c] = Math.max(dp[i][c], dp[i - 1][c - w[i - 1]] + v[i - 1]);
        }
    return dp[n][W];
}
```

```python
def knapsack01(w, v, W):
    """Mochila 0/1: mejor valor y los índices elegidos. Θ(n · W)."""
    n = len(w)
    dp = [[0] * (W + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        wi, vi = w[i - 1], v[i - 1]
        prev, row = dp[i - 1], dp[i]
        for c in range(W + 1):
            row[c] = prev[c]
            if wi <= c and prev[c - wi] + vi > row[c]:
                row[c] = prev[c - wi] + vi
    chosen, c = [], W
    for i in range(n, 0, -1):
        if dp[i][c] != dp[i - 1][c]:
            chosen.append(i - 1)
            c -= w[i - 1]
    return dp[n][W], chosen[::-1]
```

- **La reconstrucción** no necesita padres: si `dp[i][c]` difiere de `dp[i − 1][c]`, el objeto `i` se cogió.
- **Valores en 64 bits**: con 100 objetos de valor `10⁹`, la suma pasa de `2³¹`.
- **En Python**, con `n · W = 10⁷` el bucle puro tarda varios segundos: la fila única de §4.

### De la versión ingenua a la buena

**El problema.** Elegir proyectos con coste y beneficio dentro de un presupuesto `W ≤ 10⁴`, con
`n ≤ 100` proyectos.

**La versión ingenua:**

```java
// Correcta: para cada proyecto, cogerlo o no. Θ(2ⁿ).
static long best(int[] w, long[] v, int i, int cap) {
    if (i == w.length) return 0;
    long skip = best(w, v, i + 1, cap);
    long take = w[i] <= cap ? v[i] + best(w, v, i + 1, cap - w[i]) : Long.MIN_VALUE;
    return Math.max(skip, take);
}
```

> «La recursión es correcta y exponencial, pero su estado es `(i, cap)`: solo hay `n · (W + 1)` estados
> distintos, un millón. Tabulándolos, `Θ(n · W)`.»

**El camino a la buena.** La plantilla.

**Cuándo sí**: «elegir un subconjunto con un presupuesto», con capacidad hasta `10⁵`–`10⁶` y `n · W ≤ 10⁸`.
**Cuándo no**: con `W` enorme y `n ≤ 40`, *meet in the middle* ([`10/04`](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md)); con valores pequeños y `W`
enorme, la DP **por valor** (`dp[v]` = el menor peso para alcanzar el valor `v`); con objetos divisibles, el
voraz de `11/03`.

> **Veredicto:** la 0/1 es una tabla de objetos por capacidad con dos opciones por celda. Es
> pseudopolinomial: cabe cuando `n · W` cabe.

---

## 4. 🧱 Una fila de memoria

**Qué es.** Guardar solo `dp[c]` para la fila actual y recorrer `c` **de mayor a menor**, para que cada
lectura de `dp[c − w]` sea todavía la de la fila anterior.

**Por qué es correcto.** Invariante: al procesar la capacidad `c` del objeto `i` en orden descendente, las
celdas `> c` ya tienen el valor de la fila `i` y las `≤ c` todavía el de la fila `i − 1`. La transición
solo lee `dp[c]` y `dp[c − w]`, ambas `≤ c`: lee la fila anterior, como la recurrencia de la 0/1.

**Cómo va.** La fila acaba igual que la última de §3. Con el bucle **ascendente**, `(5,10)` se coge dos
veces y sale 20: es la mochila **ilimitada**.

**Cuánto.** `Θ(n · W)` tiempo y `Θ(W)` memoria. Se pierde la reconstrucción directa; si hace falta, se
guarda una tabla de decisiones de bits (`n · W` bits) o se recalcula.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria.
long long knapsackRow(const std::vector<int>& w, const std::vector<long long>& v, int W) {
    std::vector<long long> dp(W + 1, 0);
    for (size_t i = 0; i < w.size(); i++)
        for (int c = W; c >= w[i]; c--)                          // DESCENDENTE: cada objeto una vez
            dp[c] = std::max(dp[c], dp[c - w[i]] + v[i]);
    return dp[W];
}
```

```java
// Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria.
static long knapsackRow(int[] w, long[] v, int W) {
    long[] dp = new long[W + 1];
    for (int i = 0; i < w.length; i++)
        for (int c = W; c >= w[i]; c--)                            // descendente
            dp[c] = Math.max(dp[c], dp[c - w[i]] + v[i]);
    return dp[W];
}
```

```python
def knapsack_row(w, v, W):
    """Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria."""
    dp = [0] * (W + 1)
    for wi, vi in zip(w, v):
        for c in range(W, wi - 1, -1):                             # descendente
            if dp[c - wi] + vi > dp[c]:
                dp[c] = dp[c - wi] + vi
    return dp[W]
```

- **`c >= w[i]`** como condición del bucle evita el `if` y los índices negativos.
- **El sentido** es la única diferencia con la ilimitada (§5): conviene comentarlo en el código.
- **Para «¿se alcanza la suma exacta?»** la fila es de booleanos, y en C++ un `std::bitset` hace la
  transición entera con `reach |= reach << w`, 64 sumas por instrucción.

### De la versión ingenua a la buena

**El problema.** Con pesas de `[5, 2, 9, 1]`, ¿qué pesos totales se pueden formar? (16 distintos, de 0 a 17
sin el 4 ni el 13.) Con `n = 100` pesas de hasta `10³`.

**La versión ingenua**: recorrer las `2ⁿ` máscaras, sumar cada subconjunto y guardar la suma en un conjunto.
Correcta e imposible con `n = 100`.

> «Hay `2ⁿ` subconjuntos pero como mucho `Σw + 1 ≤ 10⁵` sumas distintas. Una fila de booleanos por suma:
> para cada pesa, de mayor a menor, `reach[s] |= reach[s − w]`.»

**El camino a la buena.** La plantilla con booleanos: `Θ(n · Σw)`, `10⁷`; con `bitset`, `10⁷ / 64`.

**Cuándo sí**: siempre que no haga falta reconstruir, y en todo problema de sumas alcanzables. **Cuándo
no**: si se pide qué objetos, sin guardar las decisiones aparte.

> **Veredicto:** una fila y el bucle descendente son la mochila 0/1; ascendente, la ilimitada. Escribe el
> sentido como un comentario, porque es lo que se olvida.

---

## 5. 🧱 Mochila ilimitada

**Qué es.** Cada objeto se puede coger cualquier número de veces.

**Por qué es correcto.** La recurrencia de §2 con `dp[i][c − wᵢ]`: tras coger el objeto `i`, sigue
disponible. En una fila, `dp[c] = max(dp[c], dp[c − w] + v)` recorriendo `c` **ascendente**, o, lo que es
lo mismo, `dp[c] = max sobre los objetos de dp[c − wᵢ] + vᵢ` con `c` por fuera.

**Cómo va**, el corte de una barra de longitud 8 con los precios por longitud de CLRS, §15.1
(`1, 5, 8, 9, 10, 17, 17, 20` para longitudes 1 a 8): cada trozo de longitud `k` es un objeto de peso `k` y
valor `p[k]`, ilimitado.

```text
longitud   0  1  2  3  4   5   6   7   8
mejor      0  1  5  8  10  13  17  18  22      22 = 2 + 6 (5 + 17)
```

**Cuánto.** `Θ(n · W)` tiempo, `Θ(W)` memoria.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W).
long long knapsackUnbounded(const std::vector<int>& w, const std::vector<long long>& v, int W) {
    std::vector<long long> dp(W + 1, 0);
    for (size_t i = 0; i < w.size(); i++)
        for (int c = w[i]; c <= W; c++)                            // ASCENDENTE: se puede repetir
            dp[c] = std::max(dp[c], dp[c - w[i]] + v[i]);
    return dp[W];
}
```

```java
// Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W).
static long knapsackUnbounded(int[] w, long[] v, int W) {
    long[] dp = new long[W + 1];
    for (int i = 0; i < w.length; i++)
        for (int c = w[i]; c <= W; c++)                            // ascendente
            dp[c] = Math.max(dp[c], dp[c - w[i]] + v[i]);
    return dp[W];
}
```

```python
def knapsack_unbounded(w, v, W):
    """Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W)."""
    dp = [0] * (W + 1)
    for wi, vi in zip(w, v):
        for c in range(wi, W + 1):                                 # ascendente
            if dp[c - wi] + vi > dp[c]:
                dp[c] = dp[c - wi] + vi
    return dp[W]
```

- **Ascendente**: cuando se lee `dp[c − w]`, ya puede incluir este mismo objeto.
- **`dp` empieza en 0** porque la mochila no tiene que llenarse; si el enunciado exige llenarla exactamente,
  `dp[0] = 0` y el resto a `−∞`.

### De la versión ingenua a la buena

**El problema.** El precio máximo cortando una barra de longitud `L ≤ 10⁴` en trozos con precio por longitud.

**La versión ingenua**: la recursión que prueba la longitud del primer trozo, `cut(len) = max_k p[k] +
cut(len − k)`, sin guardar nada: correcta y exponencial en `L`.

> «El estado es solo la longitud que queda: `L + 1` estados con `L` opciones cada uno. Tabulado de menor
> a mayor, `Θ(L²)`, que es la mochila ilimitada con un objeto por longitud.»

**El camino a la buena.** `knapsackUnbounded` con los trozos como objetos, o `best[l] = max_k p[k] + best[l − k]`.

**Cuándo sí**: objetos repetibles —trozos, monedas, productos fabricables—. **Cuándo no**: si hay un límite
de unidades por objeto, la acotada de §7.

> **Veredicto:** la ilimitada es la 0/1 con el bucle al revés. Las dos se escriben en cinco líneas; la
> diferencia es una dirección.

---

## 6. 🧱 Monedas: contar y mínimo

**Qué es.** Con monedas de valores dados (ilimitadas), (a) cuántas formas hay de pagar `x`, y (b) cuál es
el menor número de monedas. Son mochilas ilimitadas donde el «valor» es una cuenta o un mínimo.

**Por qué es correcto.** Mínimo: `mn[s] = 1 + min mn[s − c]`, la recurrencia de la ilimitada con mínimos.
Contar: la cuenta de las formas de pagar `s` es la suma de las de `s − c`, pero **qué se cuenta depende del
orden de los bucles** (§2): con las monedas por fuera, cada combinación una vez; con las sumas por fuera,
cada sucesión ordenada.

**Cómo va**, con `{1, 3, 4}`:

```text
s                     0  1  2  3  4  5  6
combinaciones         1  1  1  2  3  3  4      6 = 1+1+1+1+1+1 = 1+1+1+3 = 3+3 = 1+1+4
sucesiones ordenadas  1  1  1  2  4  6  9      cuenta 1+1+4, 1+4+1 y 4+1+1 por separado
mínimo de monedas     0  1  2  1  1  2  2      6 = 3 + 3 (el voraz daría 4 + 1 + 1)
```

**Cuánto.** `Θ(k · x)` para `k` monedas.

**La plantilla**, las dos cuentas y el mínimo:

```cpp
#include <algorithm>
#include <climits>
#include <vector>

const long long MOD = 1'000'000'007;

// Combinaciones (sin orden) de pagar x. Monedas por FUERA.
long long countCombinations(const std::vector<int>& coins, int x) {
    std::vector<long long> ways(x + 1, 0);
    ways[0] = 1;
    for (int c : coins)
        for (int s = c; s <= x; s++) ways[s] = (ways[s] + ways[s - c]) % MOD;
    return ways[x];
}

// Mínimo de monedas para pagar x, o −1. Θ(k · x).
int minCoins(const std::vector<int>& coins, int x) {
    std::vector<int> mn(x + 1, INT_MAX);
    mn[0] = 0;
    for (int s = 1; s <= x; s++)
        for (int c : coins)
            if (c <= s && mn[s - c] != INT_MAX) mn[s] = std::min(mn[s], mn[s - c] + 1);
    return mn[x] == INT_MAX ? -1 : mn[x];
}
```

```java
static final long MOD = 1_000_000_007L;

// Combinaciones (sin orden) de pagar x. Monedas por FUERA.
static long countCombinations(int[] coins, int x) {
    long[] ways = new long[x + 1];
    ways[0] = 1;
    for (int c : coins)
        for (int s = c; s <= x; s++) ways[s] = (ways[s] + ways[s - c]) % MOD;
    return ways[x];
}

// Mínimo de monedas para pagar x, o −1. Θ(k · x).
static int minCoins(int[] coins, int x) {
    int[] mn = new int[x + 1];
    java.util.Arrays.fill(mn, Integer.MAX_VALUE);
    mn[0] = 0;
    for (int s = 1; s <= x; s++)
        for (int c : coins)
            if (c <= s && mn[s - c] != Integer.MAX_VALUE) mn[s] = Math.min(mn[s], mn[s - c] + 1);
    return mn[x] == Integer.MAX_VALUE ? -1 : mn[x];
}
```

```python
MOD = 1_000_000_007

def count_combinations(coins, x):
    """Combinaciones (sin orden) de pagar x: monedas por fuera."""
    ways = [1] + [0] * x
    for c in coins:
        for s in range(c, x + 1):
            ways[s] = (ways[s] + ways[s - c]) % MOD
    return ways[x]

def min_coins(coins, x):
    """Mínimo de monedas para pagar x, o -1."""
    INF = float("inf")
    mn = [0] + [INF] * x
    for s in range(1, x + 1):
        mn[s] = min((mn[s - c] + 1 for c in coins if c <= s), default=INF)
    return -1 if mn[x] == INF else mn[x]
```

- **El orden de los bucles** decide qué se cuenta: para las **sucesiones** ordenadas, se intercambian los
  dos bucles (`for s` por fuera, `for c` por dentro, con `c <= s`). El mínimo no depende del orden, porque
  el mínimo de un conjunto no cambia con el orden en que se enumera.
- **`mn[s − c] != ∞`** antes de sumar 1: `INT_MAX + 1` desborda y se vuelve el mínimo.
- **`ways[0] = 1`**: hay exactamente una forma de pagar 0, no usar ninguna moneda.

### De la versión ingenua a la buena

**El problema.** Cubrir un zócalo de longitud exacta `L ≤ 10⁵` con piezas de longitudes y precios dados
(ilimitadas), al menor precio. Con piezas `(2, 3) (3, 4) (5, 9)` y `L = 11`, el mínimo es 15.

**La versión ingenua**: la recursión que prueba la última pieza, `cheapest(len) = min_p precio(p) +
cheapest(len − longitud(p))`, sin guardar nada: correcta y exponencial en `L`.

> «Es el mínimo de monedas con cada moneda costando su precio en lugar de 1. El estado es la longitud que
> falta: `L + 1` estados con `k` opciones.»

**El camino a la buena.** `minCoins` con `+ precio` en lugar de `+ 1`: `Θ(k · L)`.

**Cuándo sí**: «de cuántas formas se paga / se sube / se descompone», y «el mínimo de piezas o de coste para
completar exactamente». **Cuándo no**: con sistemas canónicos y cantidades enormes, el voraz de `11/03`;
con un número limitado de cada moneda, la acotada de §7.

> **Veredicto:** contar y minimizar monedas son la mochila ilimitada. Para contar, el orden de los bucles
> decide entre combinaciones y sucesiones: decídelo leyendo si el enunciado distingue `1+2` de `2+1`.

---

## 7. 🧱 Mochila acotada

**Qué es.** Cada objeto `i` está disponible hasta `cᵢ` veces. Con la **división binaria**, cada objeto se
parte en paquetes de `1, 2, 4, …, 2ᵏ` unidades y un resto, y el problema queda en una 0/1 sobre los
paquetes.

**Por qué es correcto** (enunciado y una frase). Con paquetes `1, 2, 4, …, 2ᵏ⁻¹` y un resto `r = c − (2ᵏ − 1)`,
toda cantidad de `0` a `c` es suma de un subconjunto de paquetes, y ninguna pasa de `c`: con `c = 13`,
paquetes `1, 2, 4, 6`.

**Cuánto.** `Θ(W · Σ log cᵢ)` en lugar de `Θ(W · Σ cᵢ)` de repetir cada objeto. Con una cola monótona sobre
los restos módulo `w` se baja a `Θ(n · W)`, que casi nunca hace falta.

**La plantilla**, en C++ (en Java es la misma con `long[]`; se omite por longitud, desviación declarada del
nivel B):

```cpp
#include <algorithm>
#include <vector>

// Mochila acotada: objeto i con peso w, valor v y hasta cnt copias. Θ(W · Σ log cnt).
long long knapsackBounded(const std::vector<int>& w, const std::vector<long long>& v,
                          const std::vector<long long>& cnt, int W) {
    std::vector<long long> dp(W + 1, 0);
    for (size_t i = 0; i < w.size(); i++) {
        long long left = cnt[i];
        for (long long k = 1; left > 0; k *= 2) {
            long long take = std::min(k, left);                     // paquete de 'take' unidades
            left -= take;
            long long pw = take * w[i], pv = take * v[i];
            if (pw > W) continue;                                   // el paquete no cabe
            for (int c = W; c >= pw; c--) dp[c] = std::max(dp[c], dp[c - pw] + pv);   // 0/1
        }
    }
    return dp[W];
}
```

- **Los paquetes son objetos 0/1** (bucle descendente); con `cnt = 10⁹` son 30, y los que no caben se saltan.
- **Si `cnt · w ≥ W`**, el objeto es en la práctica ilimitado y basta el bucle ascendente.

**Cuándo sí**: «hay `cᵢ` unidades de cada uno». **Cuándo no**: con todos los `cᵢ = 1` (0/1) o
suficientemente grandes (ilimitada).

> **Veredicto:** la acotada se reduce a la 0/1 partiendo cada objeto en potencias de 2. Es una idea de una
> línea que convierte un `cᵢ` en un `log cᵢ`.

---

## 8. ⏱️ La tabla de costes

| Variante | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| 0/1 con tabla | `Θ(n · W)` | `Θ(n · W)` | Permite reconstruir sin padres |
| 0/1 en una fila | `Θ(n · W)` | `Θ(W)` | Bucle descendente; ascendente es otro problema |
| Ilimitada | `Θ(n · W)` | `Θ(W)` | Bucle ascendente |
| Acotada, división binaria | `Θ(W · Σ log cᵢ)` | `Θ(W)` | Los paquetes son 0/1 |
| Monedas: contar | `Θ(k · x)` | `Θ(x)` | El orden de los bucles decide combinaciones o sucesiones |

---

## 9. 🧭 Cómo se elige

```text
cada objeto una vez → 0/1 descendente · ilimitado → ascendente · hasta cᵢ → paquetes binarios + 0/1
contar formas → ¿1+2 ≠ 2+1? no: monedas por fuera · sí: sumas por fuera
W enorme → n ≤ 40: meet in the middle (10/04) · Σv pequeño: DP por valor · si no, no cabe
```

> **Regla de entrevista:** antes de la tabla, di si es 0/1 o ilimitada y por qué el bucle va en ese
> sentido. «Descendente para que cada objeto se use una vez» es la frase que distingue a quien lo sabe de
> quien lo recuerda.

---

## 10. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Presupuesto», «capacidad», «elige un subconjunto», `W ≤ 10⁵` | Mochila 0/1 | Tabla objetos × capacidad |
| «¿Se puede repartir en dos de igual suma?» | 0/1 de booleanos hasta `Σ/2` | Sumas alcanzables |
| «Cantidad ilimitada», «trozos», «fabricar» | Mochila ilimitada | Bucle ascendente |
| «De cuántas formas se paga» | Monedas: contar | Orden de bucles |
| «Mínimo de monedas / piezas para exactamente `x`» | Monedas: mínimo | Ilimitada con mínimo |
| «Hay `cᵢ` de cada uno» | Acotada | Paquetes binarios |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`O(n · W)` es polinomial» | Es pseudopolinomial: `W` se escribe con `log W` bits; con `W = 10¹⁸` no cabe |
| «El orden de los bucles da igual» | En una fila, el sentido distingue 0/1 de ilimitada; al contar, el anidamiento distingue combinaciones de sucesiones |
| «La mochila es voraz por valor/peso» | La fraccionaria sí; la 0/1 no (15 frente a 18 en el ejemplo) |
| «`mn[s − c] + 1` con `INT_MAX`» | Desborda: se comprueba antes que no sea infinito |
| «Para reconstruir basta la fila única» | Se pierden las decisiones: tabla entera o bits de decisión |
| «La acotada es la 0/1 con cada copia como objeto» | Es correcto pero `Θ(W · Σcᵢ)`; con paquetes binarios, `Θ(W · Σ log cᵢ)` |

---

## 📚 Para profundizar

- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 8: la mochila y
  el cambio de monedas por programación dinámica. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §6.4: *Subset Sums and
  Knapsacks*, con la discusión de por qué es pseudopolinomial. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §15.1: el corte de barras como primer ejemplo de DP.
- **Referencia** — cp-algorithms, [*Knapsack Problem*](https://cp-algorithms.com/dynamic_programming/knapsack.html).
- **Referencia** — USACO Guide, [*Knapsack DP*](https://usaco.guide/gold/knapsack).

---

## 🧠 Preguntas

1. ¿Cuál es la recurrencia de la mochila 0/1 y cuántos estados tiene? 🟢
2. ¿En qué sentido se recorre la capacidad en la 0/1 de una fila, y en la ilimitada? 🟢
3. ¿Cómo se reconstruyen los objetos elegidos a partir de la tabla completa? 🟢
4. ¿Qué cambia entre contar combinaciones y contar sucesiones de monedas? 🟢
5. ¿Por qué `O(n · W)` no contradice que la mochila sea NP-difícil? 🟡
6. ¿Por qué el mínimo de monedas no depende del orden de los bucles y el conteo sí? 🟡
7. Compara cómo representas «infinito» en el mínimo de monedas en C++, Java y Python, y qué trampa tiene cada uno. 🟡
8. ¿Qué pasa si recorres la 0/1 de una fila en sentido ascendente? Da el resultado con los objetos del capítulo. 🟠
9. Demuestra que el bucle descendente de la fila única implementa la recurrencia de la 0/1. 🟠
10. ¿Cómo partirías un objeto con 13 copias en la mochila acotada, y por qué basta? 🟠
11. ¿Qué haces si `W = 10⁹` pero los valores son pequeños (`Σv ≤ 10⁵`)? 🟠
12. ¿Cómo decides si un problema de partición en dos grupos de igual suma cabe en una DP de mochila, y con qué tabla? 🔴
13. Tu conteo de formas de pagar da 9 cuando el enunciado esperaba 4. ¿Qué pasó y cómo lo arreglas? 🔴

---

## 🧩 Problemas propios

### Plantilla con presupuesto

**Nivel:** 🟡 · **Formato:** programa completo.

Hay que fichar como mucho `K` jugadores con un presupuesto `B`. Cada jugador tiene precio y valoración.
Imprime la valoración total máxima.

- **Entrada.** Una línea con `n`, `B` y `K`. Después, `n` líneas con `precio valoración`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 100`; `0 ≤ B ≤ 10⁴`; `1 ≤ K ≤ 15`; `1 ≤ precio ≤ 10⁴`; `1 ≤ valoración ≤ 10⁶`.

```text
Entrada     Salida
6 10 2      18
5 10
2 3
9 14
1 2
5 8
6 9

Entrada     Salida
1 0 5       0
1 9
```

**Pista 1:** además del dinero gastado, ¿qué más tiene que recordar el estado?

### Almacén con existencias

**Nivel:** 🟠 · **Formato:** programa completo.

Un camión de capacidad `W` se carga con productos de `n` tipos; del tipo `i` hay `cᵢ` unidades, de peso
`wᵢ` y valor `vᵢ` cada una. Imprime el valor máximo.

- **Entrada.** Una línea con `n` y `W`. Después, `n` líneas con `wᵢ vᵢ cᵢ`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 100`; `1 ≤ W ≤ 10⁵`; `1 ≤ wᵢ ≤ 10⁵`; `1 ≤ vᵢ ≤ 10⁹`; `1 ≤ cᵢ ≤ 10⁹`.

```text
Entrada     Salida
3 20        34
3 5 2
4 7 1
6 11 3

Entrada     Salida
1 5         6
2 3 1000000000
```

**Pista 1:** con `cᵢ = 10⁹`, ¿puedes tratar cada unidad como un objeto distinto?

---

## 🧩 Práctica externa

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [The Coin Change Problem](https://www.hackerrank.com/challenges/coin-change/problem) | HackerRank | 🟡 | Contar combinaciones | ¿Importa el orden de las monedas en un pago? |
| [ ] | [Partition Equal Subset Sum](https://leetcode.com/problems/partition-equal-subset-sum/) | LeetCode | 🟡 | 0/1 de booleanos | ¿Qué suma tiene que alcanzar uno de los dos grupos? |
| [ ] | [Coin Change II](https://leetcode.com/problems/coin-change-ii/) | LeetCode | 🟡 | Contar combinaciones | ¿Qué bucle va por fuera para no contar `1+2` y `2+1` por separado? |
| [ ] | [Combination Sum IV](https://leetcode.com/problems/combination-sum-iv/) | LeetCode | 🟡 | Contar sucesiones | Aquí `1+2` y `2+1` son distintas: ¿qué bucle va por fuera? |
| [ ] | [Target Sum](https://leetcode.com/problems/target-sum/) | LeetCode | 🟡 | 0/1 de conteo tras una transformación | Si los positivos suman `P` y los negativos `N`, ¿qué vale `P`? |
| [ ] | [Ones and Zeroes](https://leetcode.com/problems/ones-and-zeroes/) | LeetCode | 🟡 | 0/1 con dos capacidades | ¿Qué dos recursos gasta cada cadena? |
| [ ] | [MinAbsSum](https://app.codility.com/programmers/lessons/17-dynamic_programming/min_abs_sum/) | Codility | 🟠 | Sumas alcanzables hasta `Σ/2` | ¿Qué importa el signo, si puedes elegirlo para cada número? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Minimizing Coins](https://cses.fi/problemset/task/1634) | CSES | 🟢 | Mínimo de monedas | ¿Cuál fue la última moneda del pago? |
| [ ] | [Coin Combinations II](https://cses.fi/problemset/task/1636) | CSES | 🟢 | Contar combinaciones | ¿Qué orden de bucles cuenta cada combinación una vez? |
| [ ] | [Two Sets II](https://cses.fi/problemset/task/1093) | CSES | 🟡 | Contar subconjuntos con suma `Σ/2` | Cada partición aparece dos veces si cuentas los dos lados: ¿cómo lo evitas? |
| [ ] | [Last Stone Weight II](https://leetcode.com/problems/last-stone-weight-ii/) | LeetCode | 🟡 | Partición de diferencia mínima | Al final, ¿qué piedras se restaron de cuáles? |
| [ ] | [Book Shop II](https://cses.fi/problemset/task/1159) | CSES | 🟠 | Mochila acotada | Con hasta 1 000 copias de cada libro, ¿cómo evitas tratarlas una a una? |

---

## ✅ Criterio de dominio

- Escribir la 0/1 en una fila y la ilimitada sin mirar, con el sentido de bucle correcto y comentado.
- Explicar por qué `O(n · W)` es pseudopolinomial.
- Contar combinaciones y sucesiones de monedas eligiendo el orden de los bucles, y decir cuál pide el
  enunciado.
- Resolver Partition Equal Subset Sum, Coin Change II y Combination Sum IV sin pista 2.

---

**Anterior:** [`12/02` — DP lineal y LIS](02-dp-lineal-y-lis.md) · **Siguiente:** [`12/04` — DP sobre cadenas](04-dp-sobre-cadenas.md) ·
**Relacionado:** [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas](../11-voraces/03-plazos-huffman-y-monedas.md); [`10/05` — Divide y vencerás](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md).
