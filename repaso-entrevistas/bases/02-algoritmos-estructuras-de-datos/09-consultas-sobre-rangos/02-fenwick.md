# 02 — Fenwick

> El árbol de Fenwick (*binary indexed tree*): sumas de prefijos con actualizaciones en `O(log n)` sobre un
> arreglo de `n + 1` posiciones, gracias a `i & −i`. Sus variantes —actualizar un rango y consultar un punto,
> rangos en las dos operaciones, dos dimensiones— y la búsqueda por bits que encuentra el primer prefijo
> que alcanza un valor.
>
> **Niveles:** puntual/rango [A] · rango/puntual [A] · rango/rango [B] · 2D [B] · búsqueda por bits [B].
>
> **📚 Lectura troncal:** Fenwick, «A New Data Structure for Cumulative Frequency Tables», *Software:
> Practice and Experience* 24(3), 1994; Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer,
> 2024), cap. 9.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--puntual-y-rango) · [4](#4--rango-y-puntual) · [5](#5--rango-y-rango) · [6](#6--fenwick-2d) · [7](#7--búsqueda-por-bits) · [8](#8-️-la-tabla-de-costes) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Los prefijos de `04/01` dan la suma de cualquier tramo en `O(1)`, pero si un valor cambia hay que rehacer
todos los prefijos posteriores: `O(n)` por cambio. Con `q = 2·10⁵` cambios y consultas mezclados, `4·10¹⁰`.
Sin prefijos, el cambio es `O(1)` y la consulta `O(n)`: lo mismo.

El **árbol de Fenwick** reparte la diferencia: cada posición guarda la suma de un tramo cuya longitud es
la potencia de 2 más baja de su índice. Un prefijo se compone de `O(log n)` de esos tramos, y un cambio
afecta a `O(log n)` de ellos. Todo cabe en un arreglo de `n + 1` enteros y en dos bucles de tres líneas.

Es la estructura de las sumas dinámicas: contar inversiones (`05/03`), contar elementos menores que `x`
con valores comprimidos ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)), sumas sobre subárboles con el recorrido de Euler ([`07/01`](../07-arboles/01-arboles-y-recorridos.md)). Su límite:
la operación tiene que ser **invertible** (suma, *xor*), porque las consultas de tramo restan dos prefijos.

---

## 2. 📐 La teoría

**El bit más bajo.** Para `i > 0`, `i & −i` es la potencia de 2 del bit menos significativo encendido de `i`
(en complemento a 2, `−i` invierte todos los bits por encima de ese). Por ejemplo, `6 & −6 = 2`,
`4 & −4 = 4`.

**Qué guarda cada celda.** Con índices desde 1, `tree[i]` es la suma del tramo `(i − (i & −i), i]`: los
`i & −i` elementos que acaban en `i`.

```text
i:          1     2      3     4      5     6      7     8
cubre:     [1]  [1..2]  [3]  [1..4]  [5]  [5..6]  [7]  [1..8]
```

**El prefijo.** La suma de `[1, i]` se obtiene sumando `tree[i]`, quitando el bit bajo (`i −= i & −i`) y
repitiendo hasta 0: los tramos encajan uno tras otro hacia la izquierda. Cada paso apaga un bit: como mucho
`log₂ n` pasos.

**La actualización.** Si `a[p]` cambia en `δ`, hay que sumar `δ` a todas las celdas cuyo tramo contiene `p`:
son `p`, `p + (p & −p)`, y así sucesivamente (sumando el bit bajo). Cada paso sube al menos un bit: como
mucho `log₂ n` pasos.

**Teorema (las celdas que contienen `p`).** Las celdas `j ≥ p` cuyo tramo `(j − lowbit(j), j]` contiene a `p`
son exactamente las de la sucesión `p, p + lowbit(p), …` (sin pasar de `n`).

*Prueba (esbozo).* Al sumar a `j` su bit bajo, el nuevo índice `j' = j + lowbit(j)` tiene un bit bajo mayor
que el de `j`, y su tramo `(j' − lowbit(j'), j']` empieza en o antes del inicio del tramo de `j`: lo
contiene. Recíprocamente, una celda que contiene a `p` y no está en la sucesión tendría un tramo que
empieza en una posición que corta alguno de los de la sucesión, lo que no ocurre porque los tramos de
Fenwick están anidados o son disjuntos. La prueba completa está en el artículo de Fenwick.

**Por qué invertible.** La suma de `[l, r]` es `prefijo(r) − prefijo(l − 1)`: necesita restar. Con el mínimo
no se puede «restar» el prefijo izquierdo, así que Fenwick no responde mínimos de tramos arbitrarios (solo
de prefijos, y solo si los valores solo bajan).

---

## 3. 🧱 Puntual y rango

**Qué es.** Fenwick básico: sumar `δ` a una posición y consultar la suma de un tramo.

**Por qué es correcto.** Por §2: el prefijo suma tramos disjuntos que cubren `[1, i]`, y la actualización
toca exactamente las celdas cuyo tramo contiene la posición.

**Cómo va**, sobre `[5, 2, 9, 1, 5, 6]` (posiciones 1 a 6):

```text
tree = [5, 7, 9, 17, 5, 11]       tree[4] = 5 + 2 + 9 + 1,  tree[6] = 5 + 6
prefijo(5) = tree[5] + tree[4] = 5 + 17 = 22              (5 → 4 → 0)
prefijo(6) = tree[6] + tree[4] = 11 + 17 = 28             (6 → 4 → 0)
a[3] += 1:   tree[3] = 10, tree[4] = 18                    (3 → 4 → 8 > 6, para)
suma de [2, 5] = prefijo(5) − prefijo(1)
```

**Cuánto.** `O(log n)` por actualización y por consulta; `Θ(n)` de memoria; construir con `n` actualizaciones,
`O(n log n)` (o `O(n)` con la construcción lineal).

**La plantilla:**

```cpp
#include <vector>

// Fenwick de sumas, índices 1..n. add y prefix en O(log n).
struct Fenwick {
    int n; std::vector<long long> t;
    explicit Fenwick(int n) : n(n), t(n + 1, 0) {}
    void add(int i, long long d) { for (; i <= n; i += i & -i) t[i] += d; }
    long long prefix(int i) const { long long s = 0; for (; i > 0; i -= i & -i) s += t[i]; return s; }
    long long range(int l, int r) const { return prefix(r) - prefix(l - 1); }   // suma de [l, r]
};
```

```java
// Fenwick de sumas, índices 1..n. add y prefix en O(log n).
static final class Fenwick {
    final int n; final long[] t;
    Fenwick(int n) { this.n = n; t = new long[n + 1]; }
    void add(int i, long d) { for (; i <= n; i += i & -i) t[i] += d; }
    long prefix(int i) { long s = 0; for (; i > 0; i -= i & -i) s += t[i]; return s; }
    long range(int l, int r) { return prefix(r) - prefix(l - 1); }
}
```

```python
class Fenwick:
    """Fenwick de sumas, índices 1..n. add y prefix en O(log n)."""
    def __init__(self, n):
        self.n, self.t = n, [0] * (n + 1)

    def add(self, i, d):
        while i <= self.n:
            self.t[i] += d
            i += i & -i

    def prefix(self, i):
        s = 0
        while i > 0:
            s += self.t[i]
            i -= i & -i
        return s

    def range(self, l, r):
        return self.prefix(r) - self.prefix(l - 1)
```

- **Índices desde 1**: con `i = 0`, `i & −i = 0` y `add(0, …)` no avanza nunca: bucle infinito. Si los
  datos vienen desde 0, se suma 1 al índice.
- **`long long` / `long`**: las sumas de tramos pasan de `2³¹` enseguida.
- **Para fijar un valor** (`a[p] = v`), se suma `v − a[p]` y se guarda `a` aparte.
- **Construcción lineal**: `t[i] = a[i]` y, para cada `i`, `t[i + lowbit(i)] += t[i]` si no se sale.

### De la versión ingenua a la buena

**El problema.** `n = 2·10⁵` cuentas bancarias; `q = 2·10⁵` operaciones mezcladas: un depósito en una cuenta,
o «¿cuánto suman las cuentas de `l` a `r`?».

**La versión ingenua:**

```java
// O(n) por depósito: rehace los prefijos desde la cuenta tocada. 4·10¹⁰ en el peor caso.
static void deposit(long[] a, long[] pre, int p, long v) {      // pre[i] = a[1] + … + a[i]
    a[p] += v;
    for (int i = p; i < pre.length; i++) pre[i] += v;
}
```

> «Los prefijos responden rápido pero se actualizan lento; sin ellos, al revés. Si cada celda guarda la
> suma de un tramo de longitud potencia de 2 que acaba en ella, un prefijo son `log n` tramos y un cambio
> toca `log n` celdas.»

**El camino a la buena.** `Fenwick` con `add` en cada depósito y `range` en cada consulta.

**Cuándo sí**: sumas o *xor* con actualizaciones puntuales; contar con valores comprimidos (inversiones,
elementos menores que `x`). **Cuándo no**: mínimos o máximos de tramos arbitrarios (segment tree, [`09/03`](03-segment-tree.md));
sin actualizaciones, los prefijos bastan.

> **Veredicto:** Fenwick es un arreglo de sumas parciales en el que `i & −i` dice qué tramo guarda cada
> celda: `O(log n)` por cambio y por consulta, con una operación invertible.

---

## 4. 🧱 Rango y puntual

**Qué es.** Sumar `v` a todo un tramo `[l, r]` y consultar el valor de una posición: Fenwick sobre el
**arreglo de diferencias** (`04/01`).

**Por qué es correcto.** Si `d` es el arreglo de diferencias de `a`, `a[i] = d[1] + … + d[i]`; sumar `v` a
`a[l..r]` es sumar `v` a `d[l]` y restarlo a `d[r + 1]`. La consulta de `a[i]` es un prefijo de `d`.

**Cómo va**, cinco posiciones a 0:

```text
sumar 10 a [1, 3]:   d[1] += 10, d[4] −= 10        a = [10, 10, 10, 0, 0]
sumar 5 a [2, 5]:    d[2] += 5,  d[6] fuera         a = [10, 15, 15, 5, 5]
a[4] = prefijo de d hasta 4 = 10 + 5 − 10 = 5
```

**Cuánto.** `O(log n)` por operación.

**La plantilla**, con la misma clase de §3:

```cpp
// Suma v a a[l..r] y lee a[i], sobre un Fenwick de tamaño n + 1 (para r + 1 = n + 1).
void rangeAdd(Fenwick& f, int l, int r, long long v) { f.add(l, v); f.add(r + 1, -v); }
long long pointGet(const Fenwick& f, int i) { return f.prefix(i); }
```

```java
static void rangeAdd(Fenwick f, int l, int r, long v) { f.add(l, v); f.add(r + 1, -v); }
static long pointGet(Fenwick f, int i) { return f.prefix(i); }
```

```python
def range_add(f, l, r, v):
    f.add(l, v)
    f.add(r + 1, -v)          # el Fenwick tiene tamaño n + 1

def point_get(f, i):
    return f.prefix(i)
```

- **Tamaño `n + 1`** para que `add(r + 1, …)` con `r = n` no se salga (o se ignora si `r + 1 > n`).
- **Si además hay valores iniciales**, se suman como «tramos» de un elemento, o se guardan aparte y se
  suman al leer.

### De la versión ingenua a la buena

**El problema.** `n = 2·10⁵` empleados; llegan bonificaciones «todos los de `l` a `r` cobran `v` más» y
consultas «¿cuánto cobra el `i`?».

**La versión ingenua:**

```java
// O(n) por bonificación: suma uno a uno. 4·10¹⁰ en el peor caso.
static void bonus(long[] pay, int l, int r, long v) { for (int i = l; i <= r; i++) pay[i] += v; }
```

> «Una bonificación de tramo son dos marcas en el arreglo de diferencias: `+v` en `l` y `−v` después de
> `r`. El sueldo de uno es el prefijo de las marcas. Con un Fenwick sobre las marcas, las dos cosas cuestan
> `log n`.»

**El camino a la buena.** `rangeAdd` y `pointGet`.

**Cuándo sí**: actualizaciones de tramo con consultas puntuales. **Cuándo no**: si también se consultan
sumas de tramos, rango/rango (§5) o segment tree con *lazy* (`09/03`).

> **Veredicto:** con el arreglo de diferencias, el mismo Fenwick suma a tramos y lee puntos: los papeles de
> actualizar y consultar se intercambian.

---

## 5. 🧱 Rango y rango

**Qué es.** Sumar `v` a un tramo y consultar la suma de un tramo, con **dos** Fenwick.

**Por qué es correcto** (el enunciado y una frase): con diferencias `d`, `Σ_{j≤i} a[j] = Σ_{k≤i} d[k] · (i − k + 1) = (i + 1) · Σ d[k] − Σ k · d[k]`;
dos Fenwick guardan `d[k]` y `k · d[k]`, y el prefijo de `a` sale de sus dos prefijos.

**Cómo va.** Sumar 10 a `[1, 3]` es `d[1] += 10`, `d[4] −= 10`; la suma de `a[1..2]` es `3 · 10 − 1 · 10 = 20`.

**Cuánto.** `O(log n)` por operación, con el doble de constante.

**La plantilla:**

```cpp
// Suma por tramos y consulta por tramos con dos Fenwick (B1 guarda d[k], B2 guarda k·d[k]).
struct RangeFenwick {
    Fenwick b1, b2;
    explicit RangeFenwick(int n) : b1(n + 1), b2(n + 1) {}
    void add(int l, int r, long long v) {
        b1.add(l, v); b1.add(r + 1, -v);
        b2.add(l, v * l); b2.add(r + 1, -v * (r + 1));
    }
    long long prefix(int i) const { return b1.prefix(i) * (i + 1) - b2.prefix(i); }
    long long range(int l, int r) const { return prefix(r) - prefix(l - 1); }
};
```

```java
static final class RangeFenwick {
    final Fenwick b1, b2;
    RangeFenwick(int n) { b1 = new Fenwick(n + 1); b2 = new Fenwick(n + 1); }
    void add(int l, int r, long v) { b1.add(l, v); b1.add(r + 1, -v); b2.add(l, v * l); b2.add(r + 1, -v * (r + 1)); }
    long prefix(int i) { return b1.prefix(i) * (i + 1) - b2.prefix(i); }
    long range(int l, int r) { return prefix(r) - prefix(l - 1); }
}
```

- **`(i + 1)` y no `i`**: con `a[j] = Σ_{k≤j} d[k]`, cada `d[k]` aparece en `i − k + 1` términos del prefijo.
- **Desbordamiento**: `v · (r + 1)` y `prefix · (i + 1)` crecen rápido; con valores grandes, `__int128` o
  módulo.

> **Veredicto:** dos Fenwick bastan para sumar y consultar tramos; es la alternativa corta al segment tree
> con *lazy* cuando la operación es una suma.

---

## 6. 🧱 Fenwick 2D

**Qué es.** Un Fenwick de Fenwicks: `tree[i][j]` guarda la suma de un rectángulo; actualizaciones puntuales
y sumas de rectángulos en `O(log² n)`.

**Por qué es correcto** (el enunciado y una frase): el bucle sobre `i` recorre los tramos de filas y, dentro,
el bucle sobre `j` los de columnas; la suma de `[1..x] × [1..y]` es la suma de los productos de tramos, y
un rectángulo cualquiera sale por inclusión-exclusión como en [`04/05`](../04-secuencias/05-matrices.md).

**Cómo va.** `sum(x2, y2) − sum(x1 − 1, y2) − sum(x2, y1 − 1) + sum(x1 − 1, y1 − 1)`.

**Cuánto.** `O(log R · log C)` por operación; `Θ(R · C)` de memoria.

**La plantilla:**

```cpp
#include <vector>

struct Fenwick2D {
    int R, C; std::vector<std::vector<long long>> t;
    Fenwick2D(int R, int C) : R(R), C(C), t(R + 1, std::vector<long long>(C + 1, 0)) {}
    void add(int x, int y, long long d) {
        for (int i = x; i <= R; i += i & -i) for (int j = y; j <= C; j += j & -j) t[i][j] += d;
    }
    long long sum(int x, int y) const {                       // suma de [1..x] × [1..y]
        long long s = 0;
        for (int i = x; i > 0; i -= i & -i) for (int j = y; j > 0; j -= j & -j) s += t[i][j];
        return s;
    }
};
```

```java
static final class Fenwick2D {
    final int R, C; final long[][] t;
    Fenwick2D(int R, int C) { this.R = R; this.C = C; t = new long[R + 1][C + 1]; }
    void add(int x, int y, long d) {
        for (int i = x; i <= R; i += i & -i) for (int j = y; j <= C; j += j & -j) t[i][j] += d;
    }
    long sum(int x, int y) {
        long s = 0;
        for (int i = x; i > 0; i -= i & -i) for (int j = y; j > 0; j -= j & -j) s += t[i][j];
        return s;
    }
}
```

> **Veredicto:** el Fenwick 2D es dos bucles anidados de Fenwick; sirve mientras `R · C` quepa en memoria.

---

## 7. 🧱 Búsqueda por bits

**Qué es.** Encontrar la menor posición `p` con `prefijo(p) ≥ k` (con valores no negativos) en `O(log n)`,
bajando por los bits como en una búsqueda binaria, sin llamar a `prefix` en cada paso.

**Por qué es correcto** (el enunciado y una frase): bajando por potencias de 2 de mayor a menor, `tree[pos +
2ᵇ]` es exactamente la suma de `(pos, pos + 2ᵇ]` cuando `pos` es múltiplo de `2^{b+1}`; si esa suma no
alcanza lo que falta, se avanza y se descuenta, con el invariante «`prefijo(pos) < k`».

**Cómo va**, con `tree = [5, 7, 9, 17, 5, 11]` y `k = 15` (prefijos `5, 7, 16, 17, 22, 28`):

```text
b = 2: pos + 4 = 4, tree[4] = 17 ≥ 15        → no avanza
b = 1: pos + 2 = 2, tree[2] = 7 < 15          → pos = 2, k = 8
b = 0: pos + 1 = 3, tree[3] = 9 ≥ 8           → no avanza
respuesta pos + 1 = 3                          (prefijo(3) = 16 ≥ 15, prefijo(2) = 7 < 15)
```

**Cuánto.** `O(log n)`, frente a `O(log² n)` de una binaria que llama a `prefix` en cada paso.

**La plantilla**, como método del Fenwick de §3:

```cpp
// Menor p con prefix(p) >= k (valores no negativos); n + 1 si no existe.
int lowerBound(const Fenwick& f, long long k) {
    int pos = 0, LOG = 1;
    while ((1 << LOG) <= f.n) LOG++;
    for (int b = LOG; b >= 0; b--) {
        int nxt = pos + (1 << b);
        if (nxt <= f.n && f.t[nxt] < k) { pos = nxt; k -= f.t[nxt]; }
    }
    return pos + 1;
}
```

```java
static int lowerBound(Fenwick f, long k) {
    int pos = 0, LOG = 1;
    while ((1 << LOG) <= f.n) LOG++;
    for (int b = LOG; b >= 0; b--) {
        int nxt = pos + (1 << b);
        if (nxt <= f.n && f.t[nxt] < k) { pos = nxt; k -= f.t[nxt]; }
    }
    return pos + 1;
}
```

**Cuándo sí**: el `k`-ésimo elemento de un multiconjunto de valores pequeños (con un Fenwick de cuentas); el
`k`-ésimo hueco libre. **Cuándo no**: con valores negativos, los prefijos no son monótonos.

> **Veredicto:** la búsqueda por bits recorre el Fenwick de arriba abajo como una binaria y encuentra el
> `k`-ésimo en `O(log n)`: es el árbol de estadísticos de orden más corto que existe.

---

## 8. ⏱️ La tabla de costes

| Variante | Actualización | Consulta | Lo que la tabla no dice |
|---|---|---|---|
| Puntual / rango | `O(log n)` | `O(log n)` | Operación invertible |
| Rango / puntual | `O(log n)` | `O(log n)` | Sobre las diferencias |
| Rango / rango | `O(log n)` | `O(log n)` | Dos Fenwick; cuidado con el desbordamiento |
| 2D | `O(log R · log C)` | `O(log R · log C)` | Memoria `R · C` |
| Búsqueda por bits | — | `O(log n)` | Valores no negativos |

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Cambia `a[p]`; suma de `a[l..r]`» | Fenwick puntual/rango | `O(log n)` las dos |
| «Suma `v` a `a[l..r]`; ¿cuánto vale `a[i]`?» | Fenwick sobre diferencias | Rango/puntual |
| «Cuántos menores que `x` hay antes de `i`» | Fenwick de cuentas sobre valores comprimidos | Recorrido con inserciones |
| «El `k`-ésimo menor», con inserciones y borrados de valores acotados | Fenwick de cuentas + búsqueda por bits | `O(log n)` |
| «Mínimo de `a[l..r]` con cambios» | Segment tree, no Fenwick | El mínimo no es invertible |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Fenwick sirve para mínimos» | Solo para operaciones invertibles; el mínimo de un tramo arbitrario necesita segment tree |
| «Con índice 0 funciona» | `0 & −0 = 0`: `add(0, …)` no avanza y entra en bucle; los índices empiezan en 1 |
| «Para fijar `a[p] = v` llamo a `add(p, v)`» | Hay que sumar la diferencia `v − a[p]`, guardando `a` aparte |
| «La búsqueda del `k`-ésimo con Fenwick es `O(log² n)`» | Con la búsqueda por bits es `O(log n)` |
| «Rango/rango necesita un segment tree» | Dos Fenwick bastan si la operación es la suma |

---

## 📚 Para profundizar

- **Artículo** — Fenwick, «A New Data Structure for Cumulative Frequency Tables», *Software: Practice and
  Experience* 24(3), 1994. *Lectura troncal.*
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 9. *Lectura
  troncal.*
- **Referencia** — cp-algorithms, [*Fenwick Tree*](https://cp-algorithms.com/data_structures/fenwick.html),
  con las variantes de rangos.
- **Visualización interactiva** — VisuAlgo, [*Fenwick Tree*](https://visualgo.net/en/fenwicktree).

---

## 🧠 Preguntas

1. ¿Qué vale `i & −i`, y qué tramo guarda `tree[i]`? 🟢
2. ¿Por qué Fenwick empieza en el índice 1? 🟢
3. ¿Cómo obtienes la suma de `[l, r]` con dos prefijos? 🟢
4. ¿Cuántas celdas toca una actualización y una consulta, y por qué? 🟡
5. ¿Cómo fijas `a[p] = v` (no sumar) con un Fenwick? 🟡
6. ¿Cómo sumas a un tramo y consultas un punto con un solo Fenwick? 🟡
7. ¿Cómo cuentas las inversiones de un arreglo con un Fenwick y valores comprimidos? 🟡
8. Demuestra que el prefijo de Fenwick suma tramos disjuntos que cubren exactamente `[1, i]`. 🟠
9. ¿Por qué Fenwick no sirve para el mínimo de un tramo, y en qué caso particular sí sirve para mínimos de prefijos? 🟠
10. Compara la implementación de Fenwick en C++, Java y Python: tipos, índices y coste real. 🟠
11. Deduce la fórmula del Fenwick rango/rango a partir del arreglo de diferencias. 🟠
12. ¿Cómo construyes un Fenwick en `O(n)` en lugar de `O(n log n)`? 🔴
13. Demuestra que la búsqueda por bits encuentra la menor posición con prefijo `≥ k` en `O(log n)`. 🔴

---

## 🧩 Problemas propios

### Saldos de las cuentas

**Nivel:** 🟢 · **Formato:** programa completo.

Hay `n` cuentas con saldo inicial. Llegan órdenes: `+ p v` (se ingresan `v` en la cuenta `p`) y `? l r`
(imprime la suma de los saldos de las cuentas `l` a `r`, 1-indexadas).

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` saldos. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; saldos e ingresos entre 0 y `10⁹`.

```text
Entrada                Salida
6 4                    17
5 2 9 1 5 6            27
? 1 4                  19
+ 3 10
? 1 4
? 3 3

Entrada                Salida
2 3                    3000000000
1000000000 1000000000  1000000000
+ 1 1000000000
? 1 2
? 2 2
```

**Pista 1:** con `2·10⁵` ingresos, ¿cuánto cuesta rehacer los prefijos tras cada uno?

### Bonificaciones

**Nivel:** 🟡 · **Formato:** programa completo.

`n` empleados empiezan cobrando 0. Llegan órdenes: `+ l r v` (los empleados `l` a `r` cobran `v` más, con
`v` posiblemente negativo) y `? i` (imprime lo que cobra el empleado `i`).

- **Entrada.** Una línea con `n` y `q`. Después, `q` órdenes.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `|v| ≤ 10⁹`.

```text
Entrada            Salida
5 6                15
+ 1 3 10           5
+ 2 5 5            7
? 2
? 4
+ 1 1 -3
? 1

Entrada            Salida
1 3                -2000000000
+ 1 1 -1000000000
+ 1 1 -1000000000
? 1
```

**Pista 1:** ¿qué dos posiciones del arreglo de diferencias cambian con una bonificación de tramo?

### El `k`-ésimo asiento libre

**Nivel:** 🟠 · **Formato:** programa completo.

Una fila tiene `n` asientos libres numerados de 1 a `n`. Llegan órdenes: `ocupa k` (se ocupa el `k`-ésimo
asiento libre contando desde la izquierda; imprime su número) y `libera s` (el asiento `s`, ocupado, queda
libre).

- **Entrada.** Una línea con `n` y `q`. Después, `q` órdenes.
- **Salida.** Una línea por cada `ocupa`; se garantiza que hay al menos `k` libres.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`.

```text
Entrada            Salida
5 5                2
ocupa 2            3
ocupa 2            1
libera 2           5
ocupa 1
ocupa 3

Entrada            Salida
1 3                1
ocupa 1            1
libera 1
ocupa 1
```

**Pista 1:** si guardas un 1 por asiento libre, ¿qué prefijo identifica al `k`-ésimo libre?

---

## 🧩 Práctica externa

> 💡 **Truco.** Si tu Fenwick se cuelga, mira primero si alguna llamada usa el índice 0. Si una IA te da un
> Fenwick que empieza en 0, pídele que explique qué hace `i & −i` con `i = 0` ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Range Sum Query - Mutable](https://leetcode.com/problems/range-sum-query-mutable/) | LeetCode | 🟡 | Fenwick puntual/rango | Para fijar un valor, ¿qué sumas al Fenwick? |
| [ ] | [Queries on a Permutation With Key](https://leetcode.com/problems/queries-on-a-permutation-with-key/) | LeetCode | 🟡 | Fenwick de posiciones | Si reservas `m` huecos delante, ¿cómo mueves un elemento al principio? |
| [ ] | [Create Sorted Array through Instructions](https://leetcode.com/problems/create-sorted-array-through-instructions/) | LeetCode | 🔴 | Fenwick de cuentas por valor | ¿Cuántos menores y cuántos mayores hay ya, para cada valor nuevo? |
| [ ] | [Count Good Triplets in an Array](https://leetcode.com/problems/count-good-triplets-in-an-array/) | LeetCode | 🔴 | Fenwick por posiciones de la otra permutación | Fijado el elemento central, ¿cuántos buenos hay a cada lado? |
| [ ] | [Dynamic Range Sum Queries](https://cses.fi/problemset/task/1648) | CSES | 🟡 | Fenwick puntual/rango | La orden fija un valor: ¿qué diferencia sumas? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Point Add Range Sum](https://judge.yosupo.jp/problem/point_add_range_sum) | Library Checker | 🟡 | Fenwick puntual/rango | ¿Cómo construyes el Fenwick inicial sin `n` actualizaciones? |
| [ ] | [Forest Queries II](https://cses.fi/problemset/task/1739) | CSES | 🟠 | Fenwick 2D | ¿Cómo sale la suma de un rectángulo de cuatro prefijos? |
| [ ] | [Enemy is weak](https://codeforces.com/problemset/problem/61/E) | Codeforces | 🟠 | Dos Fenwick de cuentas | Fijado el elemento central, ¿cuántos mayores a su izquierda y menores a su derecha? |
| [ ] | [Vertex Add Subtree Sum](https://judge.yosupo.jp/problem/vertex_add_subtree_sum) | Library Checker | 🟠 | Euler + Fenwick | ¿Qué tramo del recorrido es el subárbol? |

---

## ✅ Criterio de dominio

- Escribir Fenwick con `add`, `prefix` y `range`, y la búsqueda por bits, sin mirar.
- Usarlo sobre diferencias y con dos Fenwick para rango/rango.
- Explicar por qué solo sirve con operaciones invertibles y por qué empieza en 1.
- Resolver Create Sorted Array through Instructions sin pista 2.

---

**Anterior:** [`09/01` — *Sparse table* y RMQ](01-sparse-table.md) · **Siguiente:** [`09/03` — Segment tree](03-segment-tree.md) ·
**Relacionado:** [`04/01` — Sumas de prefijos y arreglos de diferencias](../04-secuencias/01-prefijos-y-diferencias.md);
[`05/03` — Inversiones, selección y mediana](../05-orden-y-busqueda/03-inversiones-y-seleccion.md).
