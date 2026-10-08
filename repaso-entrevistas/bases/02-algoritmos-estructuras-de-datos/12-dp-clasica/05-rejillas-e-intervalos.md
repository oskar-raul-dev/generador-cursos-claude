# 05 — DP en rejillas y de intervalos

> Dos familias de DP en dos dimensiones: los caminos por una rejilla, con obstáculos y movimientos
> restringidos, donde el orden es fila a fila; y la DP de intervalos —la cadena de multiplicación de
> matrices, reventar globos—, donde el orden es **por longitud del intervalo** y el coste suele ser `O(n³)`.
> El árbol binario de búsqueda óptimo, como ficha.
>
> **Niveles:** rejillas [A] · intervalos: cadena de matrices [B] · *burst balloons* [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §15.2; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 8.
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--rejillas) · [4](#4--cadena-de-matrices) · [5](#5--burst-balloons) · [6](#6--árbol-binario-de-búsqueda-óptimo) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Multiplicar tres matrices de dimensiones `10 × 30`, `30 × 5` y `5 × 60` cuesta **4 500** multiplicaciones
escalares si se hace `(AB)C` y **27 000** si se hace `A(BC)`. El producto es el mismo; el orden de los
paréntesis cambia el coste por seis. Con `n` matrices hay tantas parentizaciones como el número de
Catalan `C(n−1)`, que crece como `4ⁿ`: con 20 matrices, más de mil millones.

Este capítulo trata dos formas de DP en dos dimensiones que se reconocen por su **orden de cálculo**:

- **Rejillas**: el estado es una casilla, se llega desde la de arriba o la de la izquierda, y se rellena
  fila a fila.
- **Intervalos**: el estado es un tramo `[i, j]`, se resuelve probando dónde partirlo (o qué elemento va
  el último), y se rellena **por longitud creciente**, porque un tramo depende de tramos más cortos.

> ⚠️ **Advertencia.** La DP de intervalos rellenada por filas (`i` creciente, `j` creciente) lee celdas de
> tramos más largos que todavía no se han calculado y da basura sin avisar. El orden es por longitud, o con
> `i` decreciente.

---

## 2. 📐 La teoría

**Rejillas.** En una rejilla `R × C` con movimientos hacia abajo y hacia la derecha, `d[i][j]` = lo mejor
para llegar a `(i, j)`:

```text
d[i][j] = valor(i, j) + mejor(d[i−1][j], d[i][j−1])       si (i, j) no está bloqueada
```

El grafo de dependencias es un DAG (nunca se vuelve atrás), y el orden fila a fila es topológico. Con
movimientos en las cuatro direcciones ya no es un DAG: es un problema de caminos mínimos ([`14/02`](../14-grafos-recorridos/02-bfs.md), [`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md)).

**Intervalos.** El estado es un tramo `[i, j]` y la transición prueba un **punto de corte** `k`:

```text
d[i][j] = mejor sobre k ∈ [i, j)  de  d[i][k] ⊕ d[k+1][j] ⊕ coste(i, k, j)
```

Hay `Θ(n²)` tramos y cada uno prueba `Θ(n)` cortes: `Θ(n³)`. La subestructura: en una parentización
óptima de `[i, j]`, la última multiplicación parte el tramo en dos, y cada mitad está parentizada de forma
óptima (si no, cambiándola se mejoraría el todo).

**Teorema (Knuth, ficha).** Si el coste cumple la desigualdad del cuadrilátero, el corte óptimo es monótono
(`opt[i][j−1] ≤ opt[i][j] ≤ opt[i+1][j]`), y restringiendo `k` a ese rango la DP baja a `Θ(n²)`. Es la
optimización de [`13/05`](../13-dp-avanzada/05-optimizaciones.md).

---

## 3. 🧱 Rejillas

**Qué es.** DP sobre las casillas de una rejilla con movimientos que no forman ciclos (abajo y derecha,
o diagonales hacia delante): contar caminos, el camino de suma mínima o máxima, con obstáculos.

**Por qué es correcto.** Todo camino que llega a `(i, j)` llega desde una de las casillas permitidas; por
inducción en el orden fila a fila, sus valores ya son óptimos.

**Cómo va**, recoger monedas en la rejilla `5 . 2 / # 9 . / 1 6 .` moviéndose a la derecha o hacia
abajo, sin pisar `#`:

```text
rejilla           d (máximo recogido hasta la casilla; ✕ = inalcanzable)
5  .  2           5   5   7
#  9  .           ✕   14  14
1  6  .           ✕   20  20
respuesta: 20 (5 → . → 9 → 6 → .)
```

**Cuánto.** `Θ(R · C)` tiempo; `Θ(C)` memoria con una fila, porque `d[i][j]` solo usa la fila anterior y la
casilla de la izquierda.

**La plantilla**, el camino de suma máxima con obstáculos en una fila:

```cpp
#include <algorithm>
#include <climits>
#include <string>
#include <vector>

// Máximo recogido de (0,0) a (R−1,C−1) bajando o a la derecha; '#' bloquea; '.' vale 0. −1 si no hay camino.
long long bestPath(const std::vector<std::string>& g) {
    int R = (int)g.size(), C = (int)g[0].size();
    const long long NONE = LLONG_MIN;
    std::vector<long long> d(C, NONE);                                   // d[j] = fila actual
    for (int i = 0; i < R; i++)
        for (int j = 0; j < C; j++) {
            if (g[i][j] == '#') { d[j] = NONE; continue; }
            long long from = (i == 0 && j == 0) ? 0 : std::max(d[j], j > 0 ? d[j - 1] : NONE);  // arriba o izquierda
            d[j] = from == NONE ? NONE : from + (g[i][j] == '.' ? 0 : g[i][j] - '0');
        }
    return d[C - 1] == NONE ? -1 : d[C - 1];
}
```

```java
// Máximo recogido de (0,0) a (R−1,C−1) bajando o a la derecha; '#' bloquea. −1 si no hay camino.
static long bestPath(char[][] g) {
    int R = g.length, C = g[0].length;
    final long NONE = Long.MIN_VALUE;
    long[] d = new long[C];
    java.util.Arrays.fill(d, NONE);
    for (int i = 0; i < R; i++)
        for (int j = 0; j < C; j++) {
            if (g[i][j] == '#') { d[j] = NONE; continue; }
            long from = (i == 0 && j == 0) ? 0 : Math.max(d[j], j > 0 ? d[j - 1] : NONE);
            d[j] = from == NONE ? NONE : from + (g[i][j] == '.' ? 0 : g[i][j] - '0');
        }
    return d[C - 1] == NONE ? -1 : d[C - 1];
}
```

```python
def best_path(g):
    """Máximo recogido bajando o a la derecha; '#' bloquea; '.' vale 0. -1 si no hay camino."""
    R, C = len(g), len(g[0])
    d = [None] * C                                             # None = inalcanzable
    for i in range(R):
        for j in range(C):
            if g[i][j] == "#":
                d[j] = None
                continue
            options = [0] if i == j == 0 else [x for x in (d[j], d[j - 1] if j else None) if x is not None]
            d[j] = max(options) + (0 if g[i][j] == "." else int(g[i][j])) if options else None
    return -1 if d[-1] is None else d[-1]
```

- **En una fila**, `d[j]` antes de escribirlo es el valor de arriba, y `d[j − 1]` ya es el de la izquierda en
  la fila actual: no hace falta segunda fila.
- **Inalcanzable** se marca con un centinela (`LLONG_MIN`, `None`) y se comprueba antes de sumar: sumar al
  centinela desborda en C++ y Java.
- **Para contar caminos** es lo mismo con suma en lugar de máximo, módulo si hace falta, y `0` como
  inalcanzable.

### De la versión ingenua a la buena

**El problema.** El máximo de monedas recogidas en una rejilla de hasta `1 000 × 1 000` con obstáculos.

**La versión ingenua:**

```java
// Correcta: prueba todos los caminos desde (i, j) hasta la esquina. Θ(C(R+C, R)) caminos.
static long naive(char[][] g, int i, int j) {
    int R = g.length, C = g[0].length;
    if (i >= R || j >= C || g[i][j] == '#') return Long.MIN_VALUE;
    long here = g[i][j] == '.' ? 0 : g[i][j] - '0';
    if (i == R - 1 && j == C - 1) return here;
    long best = Math.max(naive(g, i + 1, j), naive(g, i, j + 1));
    return best == Long.MIN_VALUE ? best : best + here;
}
```

> «El número de caminos es un binomial enorme, pero lo mejor desde una casilla no depende de cómo llegué:
> hay `R · C` estados. Rellenando fila a fila, cada casilla mira arriba e izquierda.»

**El camino a la buena.** La plantilla: `Θ(R · C)` = `10⁶`.

**Cuándo sí**: rejillas con movimientos «hacia delante» (abajo, derecha, diagonal abajo): contar caminos,
suma mínima o máxima, el cuadrado más grande. **Cuándo no**: con movimientos en todas las direcciones (hay
ciclos): BFS si los pasos valen 1, Dijkstra si tienen peso (bloque `15`).

> **Veredicto:** una rejilla con movimientos hacia delante es un DAG ordenado por filas: una fila de
> memoria, dos lecturas por casilla, y un centinela para lo inalcanzable.

---

## 4. 🧱 Cadena de matrices

**Qué es.** El orden de multiplicación de `n` matrices `A₁ ⋯ Aₙ` (la `i`-ésima de `p[i−1] × p[i]`) que
minimiza las multiplicaciones escalares.

**Por qué es correcto** (enunciado y una frase). En la parentización óptima de `Aᵢ ⋯ Aⱼ`, la última
multiplicación es `(Aᵢ ⋯ Aₖ)(Aₖ₊₁ ⋯ Aⱼ)` para algún `k`, y cada lado está parentizado de forma óptima:
`m[i][j] = min_k m[i][k] + m[k+1][j] + p[i−1] · p[k] · p[j]`.

**Cómo va**, `p = [10, 30, 5, 60]`:

```text
longitud 2:  m[1][2] = 10·30·5 = 1 500        m[2][3] = 30·5·60 = 9 000
longitud 3:  m[1][3] = min( m[1][1] + m[2][3] + 10·30·60 = 27 000,     k = 1: A(BC)
                            m[1][2] + m[3][3] + 10·5·60 = 4 500 )      k = 2: (AB)C  ← mínimo
```

**Cuánto.** `Θ(n²)` tramos por `Θ(n)` cortes: `Θ(n³)`. Con `n = 500`, `2·10⁷`.

**La plantilla**, con la reconstrucción de los paréntesis por el arreglo de cortes:

```cpp
#include <climits>
#include <string>
#include <vector>

// Mínimo de multiplicaciones para A1…An, Ai de p[i−1] × p[i]. Θ(n³). split guarda el mejor corte.
long long matrixChain(const std::vector<long long>& p, std::vector<std::vector<int>>& split) {
    int n = (int)p.size() - 1;
    std::vector<std::vector<long long>> m(n + 1, std::vector<long long>(n + 1, 0));
    split.assign(n + 1, std::vector<int>(n + 1, 0));
    for (int len = 2; len <= n; len++)                                  // POR LONGITUD
        for (int i = 1; i + len - 1 <= n; i++) {
            int j = i + len - 1;
            m[i][j] = LLONG_MAX;
            for (int k = i; k < j; k++) {
                long long cost = m[i][k] + m[k + 1][j] + p[i - 1] * p[k] * p[j];
                if (cost < m[i][j]) { m[i][j] = cost; split[i][j] = k; }
            }
        }
    return m[1][n];
}

// Paréntesis de la parentización óptima de Ai…Aj.
std::string parens(const std::vector<std::vector<int>>& split, int i, int j) {
    if (i == j) return "A" + std::to_string(i);
    int k = split[i][j];
    return "(" + parens(split, i, k) + parens(split, k + 1, j) + ")";
}
```

```java
// Mínimo de multiplicaciones para A1…An, Ai de p[i−1] × p[i]. Θ(n³).
static long matrixChain(long[] p) {
    int n = p.length - 1;
    long[][] m = new long[n + 1][n + 1];
    for (int len = 2; len <= n; len++)
        for (int i = 1; i + len - 1 <= n; i++) {
            int j = i + len - 1;
            m[i][j] = Long.MAX_VALUE;
            for (int k = i; k < j; k++)
                m[i][j] = Math.min(m[i][j], m[i][k] + m[k + 1][j] + p[i - 1] * p[k] * p[j]);
        }
    return m[1][n];
}
```

- **El bucle exterior es la longitud**: todos los tramos más cortos están calculados antes.
- **Índices desde 1**, como en CLRS, para que `p[i − 1] × p[i]` sea la matriz `i`.
- **`p[i−1] · p[k] · p[j]`** en 64 bits: con dimensiones de `10⁴`, el producto es `10¹²`.

**Cuándo sí**: «parentizar», «agrupar elementos consecutivos con un coste que depende de los extremos y del
corte», «unir montones vecinos». **Cuándo no**: con `n ≥ 5 000`, `n³` no cabe; si el coste cumple las
condiciones de Knuth, la versión `Θ(n²)` de `13/05`.

> **Veredicto:** la cadena de matrices es la plantilla de la DP de intervalos: tramo, corte, y longitud
> creciente. Lo demás son costes distintos.

---

## 5. 🧱 *Burst balloons*

**Qué es.** Reventar globos en fila (con un `1` imaginario en cada extremo): reventar el globo `k`
puntúa `v[izquierda] · v[k] · v[derecha]` con sus vecinos **actuales**; maximizar la puntuación total.

**Por qué es correcto** (enunciado y una frase). El truco es elegir el globo que se revienta **el último**
dentro del tramo abierto `(l, r)`: cuando se revienta, sus vecinos son exactamente `l` y `r`, y los dos
lados son independientes: `d[l][r] = max_k d[l][k] + d[k][r] + v[l] · v[k] · v[r]`.

**Cómo va.** Con `[3, 1, 5, 8]` (extendido a `[1, 3, 1, 5, 8, 1]`) el máximo es 167. Elegir el **primero**
en reventar no funciona como estado, porque los vecinos de los demás cambian y los lados no quedan
independientes.

**Cuánto.** `Θ(n³)`, como la cadena de matrices.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Máxima puntuación reventando todos los globos. Θ(n³).
long long burstBalloons(const std::vector<long long>& vals) {
    std::vector<long long> v = {1};
    v.insert(v.end(), vals.begin(), vals.end());
    v.push_back(1);
    int n = (int)v.size();
    std::vector<std::vector<long long>> d(n, std::vector<long long>(n, 0));  // d[l][r]: tramo abierto (l, r)
    for (int len = 2; len < n; len++)
        for (int l = 0; l + len < n; l++) {
            int r = l + len;
            for (int k = l + 1; k < r; k++)                                   // k: el último en reventar
                d[l][r] = std::max(d[l][r], d[l][k] + d[k][r] + v[l] * v[k] * v[r]);
        }
    return d[0][n - 1];
}
```

```java
// Máxima puntuación reventando todos los globos. Θ(n³).
static long burstBalloons(long[] vals) {
    int n = vals.length + 2;
    long[] v = new long[n];
    v[0] = 1; v[n - 1] = 1;
    System.arraycopy(vals, 0, v, 1, vals.length);
    long[][] d = new long[n][n];
    for (int len = 2; len < n; len++)
        for (int l = 0; l + len < n; l++) {
            int r = l + len;
            for (int k = l + 1; k < r; k++)
                d[l][r] = Math.max(d[l][r], d[l][k] + d[k][r] + v[l] * v[k] * v[r]);
        }
    return d[0][n - 1];
}
```

- **Tramos abiertos** `(l, r)`: `l` y `r` no se revientan en ese subproblema; son los vecinos fijos.
- **El último, no el primero**: es la decisión que deja los dos lados independientes. Es la idea que
  convierte este problema en una DP de intervalos.

**Cuándo sí**: «quitar elementos uno a uno con un coste que depende de los vecinos actuales». **Cuándo no**:
si el coste solo depende del elemento, no hay interacción y basta ordenar.

> **Veredicto:** cuando quitar un elemento cambia los vecinos de los demás, piensa en el **último** que se
> quita dentro del tramo: así los lados se separan.

---

## 6. 🧱 Árbol binario de búsqueda óptimo

### El ABB de coste de búsqueda mínimo

**Qué resuelve.** Dadas `n` claves ordenadas con sus frecuencias de búsqueda, el ABB que minimiza el coste
esperado `Σ frecuencia · (profundidad + 1)`.

**Qué garantiza.** La DP de intervalos `e[i][j] = min_r e[i][r−1] + e[r+1][j] + Σ frecuencias(i..j)`, con la
raíz `r` como corte, da el óptimo en `Θ(n³)`; con la desigualdad de Knuth (`raíz[i][j−1] ≤ raíz[i][j] ≤
raíz[i+1][j]`), en `Θ(n²)`.

**Cuánto.** `Θ(n³)`, o `Θ(n²)` con Knuth.

**Cómo reconocerlo.** «Diccionario con frecuencias de consulta», «árbol de decisión con probabilidades», o
cualquier «elige una raíz y los dos lados son subproblemas».

**Si no te la sabes.** La cadena de matrices con el coste cambiado: misma estructura.

**Dónde está entera.** CLRS, §15.5; Knuth, Vol. 3, §6.2.2.

---

## 7. ⏱️ La tabla de costes

| Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Rejilla, movimientos hacia delante | `Θ(R · C)` | `Θ(C)` con una fila | Con movimientos en todas direcciones no es DP: es BFS o Dijkstra |
| Intervalos (cadena, montones, ABB) | `Θ(n³)` | `Θ(n²)` | Orden por longitud; con Knuth, `Θ(n²)` |
| *Burst balloons* | `Θ(n³)` | `Θ(n²)` | El estado es el último en salir, no el primero |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| Rejilla, «solo derecha y abajo», «contar caminos», obstáculos | DP de rejilla | DAG por filas |
| «El mayor cuadrado / rectángulo de…» en una matriz | DP de rejilla con mínimo de vecinos | La casilla depende de tres vecinas |
| «Parentizar», «orden de las operaciones», «unir vecinos» | DP de intervalos | Corte del tramo |
| «Quitar uno a uno, el coste depende de los vecinos actuales» | DP de intervalos por el último | Separa los lados |
| `n ≤ 500` y una secuencia que se parte | `Θ(n³)` | `500³ ≈ 10⁸` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La DP de intervalos se llena por filas» | Por longitud (o `i` decreciente): un tramo depende de tramos más cortos |
| «En *burst balloons*, el estado es el primero que revienta» | El último: así sus vecinos son los extremos fijos |
| «Una rejilla siempre es DP» | Solo si los movimientos no forman ciclos; si no, caminos mínimos |
| «Sumo al centinela de inalcanzable» | `LLONG_MIN + valor` desborda: se comprueba antes |
| «La cadena de matrices se resuelve con el voraz del producto más barato» | El voraz falla; hay que probar todos los cortes |
| «`n³` siempre es lento» | Con `n ≤ 500`, `10⁸` operaciones simples caben; con `n = 2 000`, no |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §15.2 (la cadena de matrices) y §15.5 (el ABB óptimo). *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 8: la
  multiplicación encadenada de matrices y los árboles de búsqueda óptimos. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Knuth's Optimization*](https://cp-algorithms.com/dynamic_programming/knuth-optimization.html):
  cuándo la DP de intervalos baja a `Θ(n²)`.
- **Referencia** — USACO Guide, [*Introduction to DP*](https://usaco.guide/gold/intro-dp): rejillas entre los
  problemas clásicos.

---

## 🧠 Preguntas

1. ¿En qué orden se rellena una DP de rejilla, y por qué es válido? 🟢
2. ¿Qué recurrencia tiene la cadena de matrices y cuánto cuesta? 🟢
3. ¿En qué orden se rellena una DP de intervalos? 🟢
4. ¿Por qué en *burst balloons* el estado se define por el último globo y no por el primero? 🟡
5. ¿Por qué basta una fila en la DP de rejilla con movimientos abajo y derecha? 🟡
6. ¿Cuándo una rejilla deja de ser una DP y pasa a ser un problema de caminos mínimos? 🟡
7. Compara cómo marcas una casilla inalcanzable en C++, Java y Python, y qué error evita cada forma. 🟡
8. Demuestra la subestructura óptima de la cadena de matrices. 🟠
9. ¿Por qué el voraz «multiplica primero el par más barato» no sirve en la cadena de matrices? 🟠
10. ¿Qué cambia si en la rejilla se puede mover también en diagonal abajo-derecha? 🟠
11. ¿Qué dice la desigualdad de Knuth y qué consigue en una DP de intervalos? 🔴
12. Demuestra que el número de parentizaciones de `n` matrices crece al menos como `2ⁿ⁻²` y explica qué dice eso de la búsqueda completa. 🔴
13. Tu DP de intervalos da un resultado distinto cada vez que cambias el orden de los bucles. ¿Qué miras? 🔴

---

## 🧩 Problemas propios

### Robot con tres movimientos

**Nivel:** 🟢 · **Formato:** programa completo.

Un robot va de la esquina superior izquierda a la inferior derecha de una rejilla de costes, moviéndose a
la derecha, hacia abajo o en diagonal abajo-derecha. Imprime el coste mínimo del recorrido (sumando las
casillas pisadas, incluidas la primera y la última).

- **Entrada.** Una línea con `R` y `C`. Después, `R` líneas con `C` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ R, C ≤ 1 000`; `0 ≤ coste ≤ 10⁹`.

```text
Entrada     Salida
3 3         12
5 2 9
1 5 6
9 1 5

Entrada     Salida
1 1         7
7
```

**Pista 1:** ¿desde qué casillas se puede llegar a `(i, j)`?

### Unir montones vecinos

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` montones de arena en fila. Se unen de dos en dos, solo **vecinos**, y unir dos montones cuesta la
suma de sus tamaños. ¿Cuál es el coste mínimo de dejar un solo montón?

- **Entrada.** Una línea con `n`. Una línea con los tamaños.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 400`; `1 ≤ tamaño ≤ 10⁹`.

```text
Entrada            Salida
4                  34
5 2 9 1

Entrada            Salida
3                  23
1 10 1
```

**Pista 1:** la última unión junta dos montones; ¿qué tramo de la fila forma cada uno?

### Paréntesis para el máximo

**Nivel:** 🟠 · **Formato:** programa completo.

Una expresión alterna números enteros (pueden ser negativos) y operadores `+` o `*`. Pon paréntesis para
que su valor sea el máximo posible e imprímelo.

- **Entrada.** Una línea con `n`. Una línea con los `n` números. Una línea con los `n − 1` operadores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 100`; `|número| ≤ 9`; se garantiza que todos los valores intermedios caben en
  64 bits con signo.

```text
Entrada     Salida
3           20
2 3 4
+ *

Entrada     Salida
3           2
-2 3 -4
* +
```

**Pista 1:** si un tramo puede dar un valor muy negativo, ¿te sirve para algo al multiplicarlo por otro
negativo?

---

## 🧩 Práctica externa

Codility no tiene DP de rejillas ni de intervalos.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Unique Paths](https://leetcode.com/problems/unique-paths/) | LeetCode | 🟡 | Contar caminos en rejilla | ¿De cuántas casillas se llega a cada una? |
| [ ] | [Unique Paths II](https://leetcode.com/problems/unique-paths-ii/) | LeetCode | 🟡 | Contar con obstáculos | ¿Cuántos caminos llegan a una casilla bloqueada? |
| [ ] | [Minimum Path Sum](https://leetcode.com/problems/minimum-path-sum/) | LeetCode | 🟡 | Rejilla de mínimo | ¿Cuánto cuesta como mínimo llegar a la casilla de arriba y a la de la izquierda? |
| [ ] | [Triangle](https://leetcode.com/problems/triangle/) | LeetCode | 🟡 | Rejilla triangular | ¿Es más fácil de abajo arriba? |
| [ ] | [Maximal Square](https://leetcode.com/problems/maximal-square/) | LeetCode | 🟡 | Rejilla con mínimo de tres vecinas | Si `(i, j)` es la esquina inferior derecha de un cuadrado de unos, ¿qué cumplen sus tres vecinas? |
| [ ] | [Minimum Score Triangulation of Polygon](https://leetcode.com/problems/minimum-score-triangulation-of-polygon/) | LeetCode | 🟡 | DP de intervalos | El lado `(i, j)` está en un triángulo: ¿cuál es su tercer vértice? |
| [ ] | [Grid Paths I](https://cses.fi/problemset/task/1638) | CSES | 🟢 | Contar caminos con trampas | ¿Qué pasa con la cuenta si la casilla inicial tiene trampa? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Rectangle Cutting](https://cses.fi/problemset/task/1744) | CSES | 🟡 | DP sobre dimensiones | Un corte parte el rectángulo en dos; ¿qué subproblemas quedan? |
| [ ] | [Dungeon Game](https://leetcode.com/problems/dungeon-game/) | LeetCode | 🟠 | Rejilla de abajo arriba | ¿Qué vida mínima necesitas **al entrar** en cada casilla? |
| [ ] | [Burst Balloons](https://leetcode.com/problems/burst-balloons/) | LeetCode | 🟠 | Intervalos por el último | ¿Qué globo del tramo revientas el último? |
| [ ] | [Minimum Cost to Cut a Stick](https://leetcode.com/problems/minimum-cost-to-cut-a-stick/) | LeetCode | 🟠 | Intervalos sobre los cortes | Ordenados los cortes, ¿qué corte haces primero en cada tramo? |
| [ ] | [Cherry Pickup](https://leetcode.com/problems/cherry-pickup/) | LeetCode | 🔴 | Dos caminos simultáneos | Si dos personas bajan a la vez, ¿qué basta guardar de las dos? |

---

## ✅ Criterio de dominio

- Escribir la DP de rejilla en una fila con obstáculos y la cadena de matrices por longitud sin mirar.
- Explicar por qué la DP de intervalos no se llena por filas.
- Reconocer cuándo el estado es «el último en salir».
- Resolver Maximal Square y Burst Balloons sin pista 2.

---

**Anterior:** [`12/04` — DP sobre cadenas](04-dp-sobre-cadenas.md) · **Siguiente:** [`12/06` — Conteo con DP](06-conteo.md) ·
**Relacionado:** [`13/05` — Optimizaciones de DP](../13-dp-avanzada/05-optimizaciones.md); [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
