# 04 — DP sobre cadenas

> Las DP de dos dimensiones sobre una o dos cadenas: la subsecuencia común más larga (LCS), la distancia
> de edición y las subsecuencias y subcadenas palindrómicas. Con la recurrencia de cada una, su
> reconstrucción, la memoria en dos filas y Hirschberg como ficha.
>
> **Niveles:** LCS [A] · distancia de edición [A] · subsecuencias y palíndromos [A].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §15.4; Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §6.6.
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--lcs) · [4](#4--distancia-de-edición) · [5](#5--subsecuencias-y-palíndromos) · [6](#6--hirschberg) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

`diff` compara dos versiones de un fichero y dice qué líneas se borraron y cuáles se añadieron. Un
corrector ortográfico propone «perro» cuando escribes «perra». Un biólogo alinea dos cadenas de ADN. Las
tres cosas son la misma DP: una tabla de `n × m` donde la celda `(i, j)` responde la pregunta sobre los
**prefijos** `a[0..i)` y `b[0..j)`, y la respuesta de cada celda sale de sus tres vecinas de arriba y la
izquierda.

Con dos cadenas de `10⁴` caracteres, probar todas las subsecuencias de una (`2¹⁰⁰⁰⁰`) es absurdo; la tabla
son `10⁸` celdas de `O(1)`. Y con una sola cadena, la misma idea sobre **intervalos** `[i, j]` resuelve los
palíndromos.

> 🧠 **Modelo mental.** En la DP de dos cadenas, el estado es un par de prefijos, y la transición mira el
> **último carácter** de cada uno: si coinciden, se usan los dos; si no, se descarta uno (o se sustituye).
> Todas las variantes cambian solo qué cuesta cada movimiento.

---

## 2. 📐 La teoría

**Subsecuencia frente a subcadena.** Una **subsecuencia** se obtiene borrando caracteres (no necesariamente
contiguos): `aca` es subsecuencia de `abracadabra`. Una **subcadena** es un tramo contiguo. La LCS es de
subsecuencias; la subcadena común más larga es otro problema (y otra recurrencia, o un *suffix array* en
[`16/06`](../16-cadenas/06-suffix-array-y-automaton.md)).

**La recurrencia de la LCS.** `L[i][j]` = la LCS de los prefijos `a[0..i)` y `b[0..j)`:

```text
L[0][j] = L[i][0] = 0
L[i][j] = L[i−1][j−1] + 1                    si a[i−1] = b[j−1]
        = max(L[i−1][j], L[i][j−1])          si no
```

*Por qué.* Si los últimos caracteres coinciden, alguna LCS los empareja (si una no lo hiciera, se puede
cambiar su último emparejamiento por este sin acortarla: intercambio). Si no coinciden, al menos uno de
los dos no está en la LCS, y se prueba quitando cada uno.

**La distancia de edición (Levenshtein).** `D[i][j]` = el mínimo de inserciones, borrados y sustituciones
para convertir `a[0..i)` en `b[0..j)`:

```text
D[i][0] = i,  D[0][j] = j
D[i][j] = min( D[i−1][j] + 1,                          borrar a[i−1]
               D[i][j−1] + 1,                          insertar b[j−1]
               D[i−1][j−1] + [a[i−1] ≠ b[j−1]] )       sustituir (gratis si coinciden)
```

**Los palíndromos, sobre intervalos de una cadena.** `P[i][j]` = la subsecuencia palindrómica más larga
de `s[i..j]`: `P[i][i] = 1`; si `s[i] = s[j]`, `P[i][j] = P[i+1][j−1] + 2`; si no,
`max(P[i+1][j], P[i][j−1])`. El orden de cálculo es **por longitud del intervalo** (o `i` decreciente), no
por filas: `P[i][j]` depende de `P[i+1][…]`.

**Memoria.** Las dos primeras solo usan la fila anterior: **dos filas** bastan para el valor (`Θ(m)` de
memoria). Para reconstruir hace falta la tabla, o Hirschberg (§6), que reconstruye en espacio lineal.

---

## 3. 🧱 LCS

**Qué es.** La subsecuencia común más larga de dos cadenas.

**Por qué es correcto.** Por la recurrencia de §2, con inducción sobre `i + j`.

**Cómo va**, `a = abrac`, `b = barca`:

```text
          ""  b  a  r  c  a
    ""     0  0  0  0  0  0
    a      0  0  1  1  1  1
    b      0  1  1  1  1  1
    r      0  1  1  2  2  2
    a      0  1  2  2  2  3
    c      0  1  2  2  3  3
LCS = 3; reconstrucción desde la esquina: "ara" (otra óptima es "brc")
```

**Cuánto.** `Θ(n · m)` tiempo; `Θ(n · m)` con la tabla, `Θ(min(n, m))` con dos filas si solo se pide la
longitud.

**La plantilla**, con la reconstrucción:

```cpp
#include <algorithm>
#include <string>
#include <vector>

// Una subsecuencia común más larga de a y b. Θ(n · m).
std::string lcs(const std::string& a, const std::string& b) {
    int n = (int)a.size(), m = (int)b.size();
    std::vector<std::vector<int>> L(n + 1, std::vector<int>(m + 1, 0));
    for (int i = 1; i <= n; i++)
        for (int j = 1; j <= m; j++)
            L[i][j] = a[i - 1] == b[j - 1] ? L[i - 1][j - 1] + 1 : std::max(L[i - 1][j], L[i][j - 1]);
    std::string out;
    for (int i = n, j = m; i > 0 && j > 0;) {                        // desde la esquina
        if (a[i - 1] == b[j - 1]) { out += a[i - 1]; i--; j--; }
        else if (L[i - 1][j] >= L[i][j - 1]) i--;
        else j--;
    }
    std::reverse(out.begin(), out.end());
    return out;
}
```

```java
// Una subsecuencia común más larga de a y b. Θ(n · m).
static String lcs(String a, String b) {
    int n = a.length(), m = b.length();
    int[][] L = new int[n + 1][m + 1];
    for (int i = 1; i <= n; i++)
        for (int j = 1; j <= m; j++)
            L[i][j] = a.charAt(i - 1) == b.charAt(j - 1) ? L[i - 1][j - 1] + 1 : Math.max(L[i - 1][j], L[i][j - 1]);
    StringBuilder out = new StringBuilder();
    for (int i = n, j = m; i > 0 && j > 0;) {
        if (a.charAt(i - 1) == b.charAt(j - 1)) { out.append(a.charAt(i - 1)); i--; j--; }
        else if (L[i - 1][j] >= L[i][j - 1]) i--;
        else j--;
    }
    return out.reverse().toString();
}
```

```python
def lcs(a, b):
    """Una subsecuencia común más larga de a y b. Θ(n · m)."""
    n, m = len(a), len(b)
    L = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            L[i][j] = L[i - 1][j - 1] + 1 if a[i - 1] == b[j - 1] else max(L[i - 1][j], L[i][j - 1])
    out, i, j = [], n, m
    while i > 0 and j > 0:
        if a[i - 1] == b[j - 1]:
            out.append(a[i - 1]); i -= 1; j -= 1
        elif L[i - 1][j] >= L[i][j - 1]:
            i -= 1
        else:
            j -= 1
    return "".join(reversed(out))
```

- **La tabla mide `(n + 1) × (m + 1)`**: la fila y la columna 0 son los prefijos vacíos, y evitan los casos
  especiales.
- **La reconstrucción** sigue la misma decisión que la recurrencia: diagonal si coinciden, si no hacia el
  vecino con el valor mayor. Los empates deciden cuál de las LCS óptimas sale.
- **En Python**, `10⁴ × 10⁴` celdas tardan decenas de segundos; para longitudes de `10³`, va bien.

### De la versión ingenua a la buena

**El problema.** La longitud de la cadena más corta que contiene a `a` y a `b` como subsecuencias (la
supersecuencia común más corta). Con `abrac` y `barca`, mide 7.

**La versión ingenua:**

```java
// Correcta: al final de la supersecuencia va el último carácter de a, el de b, o ambos si coinciden.
// Exponencial: hasta 2^(n+m) llamadas.
static int scs(String a, String b, int i, int j) {
    if (i == 0) return j;
    if (j == 0) return i;
    if (a.charAt(i - 1) == b.charAt(j - 1)) return 1 + scs(a, b, i - 1, j - 1);
    return 1 + Math.min(scs(a, b, i - 1, j), scs(a, b, i, j - 1));
}
```

> «El estado es el par de prefijos: `(n + 1)(m + 1)` estados. Además, cada carácter común emparejado se
> escribe una vez en lugar de dos, así que la longitud es `n + m − LCS`.»

**El camino a la buena.** La tabla de la LCS y `n + m − L[n][m]`: `Θ(n · m)`. Para escribir la
supersecuencia, se reconstruye la LCS intercalando los caracteres no emparejados.

**Cuándo sí**: comparar dos secuencias por lo que tienen en común en orden: `diff`, versiones, ADN, «borrar
lo mínimo para que sean iguales». **Cuándo no**: si se pide lo común **contiguo** (subcadena), otra
recurrencia (`L[i][j] = L[i−1][j−1] + 1` o 0); si las cadenas miden `10⁵` o más, la tabla no cabe, y hay
que buscar estructura (por ejemplo, una de ellas es una permutación: LIS, [`12/02`](02-dp-lineal-y-lis.md)).

> **Veredicto:** la LCS es la tabla de prefijos con diagonal si coinciden y máximo si no. Casi toda DP de
> dos cadenas es una variación de esta.

---

## 4. 🧱 Distancia de edición

**Qué es.** El mínimo de operaciones —insertar, borrar o sustituir un carácter— para convertir una cadena
en otra.

**Por qué es correcto.** Por la recurrencia de §2: en una edición óptima, el último carácter de `a` o se
borra, o se sustituye por (o coincide con) el último de `b`, o el último de `b` se inserta; las tres
opciones cubren todos los casos.

**Cómo va**, `perro` → `pera`:

```text
          ""  p  e  r  a
    ""     0  1  2  3  4
    p      1  0  1  2  3
    e      2  1  0  1  2
    r      3  2  1  0  1
    r      4  3  2  1  1
    o      5  4  3  2  2
distancia 2: borrar una r y sustituir o → a
```

**Cuánto.** `Θ(n · m)` tiempo; `Θ(min(n, m))` memoria con dos filas.

**La plantilla**, en dos filas:

```cpp
#include <algorithm>
#include <string>
#include <vector>

// Distancia de Levenshtein entre a y b, con dos filas. Θ(n · m) tiempo, Θ(m) memoria.
int editDistance(const std::string& a, const std::string& b) {
    int n = (int)a.size(), m = (int)b.size();
    std::vector<int> prev(m + 1), cur(m + 1);
    for (int j = 0; j <= m; j++) prev[j] = j;                   // de "" a b[0..j): j inserciones
    for (int i = 1; i <= n; i++) {
        cur[0] = i;                                             // de a[0..i) a "": i borrados
        for (int j = 1; j <= m; j++)
            cur[j] = std::min({prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] != b[j - 1])});
        std::swap(prev, cur);
    }
    return prev[m];
}
```

```java
// Distancia de Levenshtein entre a y b, con dos filas. Θ(n · m) tiempo, Θ(m) memoria.
static int editDistance(String a, String b) {
    int n = a.length(), m = b.length();
    int[] prev = new int[m + 1], cur = new int[m + 1];
    for (int j = 0; j <= m; j++) prev[j] = j;
    for (int i = 1; i <= n; i++) {
        cur[0] = i;
        for (int j = 1; j <= m; j++) {
            int sub = prev[j - 1] + (a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1);
            cur[j] = Math.min(Math.min(prev[j] + 1, cur[j - 1] + 1), sub);
        }
        int[] t = prev; prev = cur; cur = t;                    // intercambia las filas
    }
    return prev[m];
}
```

```python
def edit_distance(a, b):
    """Distancia de Levenshtein entre a y b, con dos filas. Θ(n · m) tiempo, Θ(m) memoria."""
    prev = list(range(len(b) + 1))
    for i in range(1, len(a) + 1):
        cur = [i] + [0] * len(b)
        for j in range(1, len(b) + 1):
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] != b[j - 1]))
        prev = cur
    return prev[len(b)]
```

- **Los casos base** son la fila y la columna 0: convertir en o desde la cadena vacía.
- **Dos filas** y un intercambio al final de cada `i`; con la tabla entera se reconstruye la secuencia de
  operaciones como en la LCS.
- **Con costes distintos** por operación, se cambia cada `+ 1` por su coste; la estructura no cambia.

### De la versión ingenua a la buena

**El problema.** Una distancia que además permite **intercambiar dos caracteres vecinos** con coste 1 (la
errata más común al teclear): `abarcadabra` está a 1 de `abracadabra`, no a 2.

**La versión ingenua:** la recursión sobre `(i, j)` con las cuatro opciones, sin memoria: exponencial.

> «Es Levenshtein con una cuarta opción: si `a[i−1] = b[j−2]` y `a[i−2] = b[j−1]`, puedo venir de
> `D[i−2][j−2] + 1`. El estado sigue siendo el par de prefijos; la tabla necesita ahora dos filas atrás.»

**El camino a la buena.** La plantilla con la tabla entera (o tres filas) y la línea extra de la
transposición: `Θ(n · m)`. Es la distancia de Damerau en su versión restringida (*optimal string
alignment*).

**Cuándo sí**: «el menor número de cambios», correctores, comparación tolerante a erratas. **Cuándo no**:
si solo se permiten sustituciones, es la distancia de Hamming (`O(n)`); si solo inserciones y borrados,
`n + m − 2 · LCS`.

> **Veredicto:** la distancia de edición es la tabla de prefijos con tres vecinos y un `+ 1` en cada
> movimiento. Cada variante añade un movimiento o cambia un coste.

---

## 5. 🧱 Subsecuencias y palíndromos

**Qué es.** DP sobre **intervalos** de una sola cadena: la subsecuencia palindrómica más larga, la tabla
`esPal[i][j]` de subcadenas palindrómicas, y lo que se construye sobre ella (contar palíndromos, partir en
palíndromos).

**Por qué es correcto.** `s[i..j]` es palíndromo si sus extremos coinciden y el interior lo es; la
subsecuencia palindrómica más larga de `s[i..j]` empareja los extremos si coinciden (intercambio, como en
la LCS) o descarta uno.

**Cómo va**, con `abracadabra` (11 letras): la subsecuencia palindrómica más larga mide 7 (`abacaba`, por
ejemplo), y hay 13 subcadenas palindrómicas (las 11 letras, `aca` y `ada`).

**Cuánto.** `Θ(n²)` intervalos por `O(1)`: `Θ(n²)` tiempo y memoria.

**La plantilla**, la subsecuencia palindrómica más larga con `i` decreciente:

```cpp
#include <algorithm>
#include <string>
#include <vector>

// Longitud de la subsecuencia palindrómica más larga de s. Θ(n²).
int longestPalSubseq(const std::string& s) {
    int n = (int)s.size();
    std::vector<std::vector<int>> P(n, std::vector<int>(n, 0));
    for (int i = n - 1; i >= 0; i--) {                           // i decreciente: P[i+1] ya está
        P[i][i] = 1;
        for (int j = i + 1; j < n; j++)
            P[i][j] = s[i] == s[j] ? P[i + 1][j - 1] + 2 : std::max(P[i + 1][j], P[i][j - 1]);
    }
    return n ? P[0][n - 1] : 0;
}
```

```java
// Longitud de la subsecuencia palindrómica más larga de s. Θ(n²).
static int longestPalSubseq(String s) {
    int n = s.length();
    int[][] P = new int[n][n];
    for (int i = n - 1; i >= 0; i--) {
        P[i][i] = 1;
        for (int j = i + 1; j < n; j++)
            P[i][j] = s.charAt(i) == s.charAt(j) ? P[i + 1][j - 1] + 2 : Math.max(P[i + 1][j], P[i][j - 1]);
    }
    return n > 0 ? P[0][n - 1] : 0;
}
```

```python
def longest_pal_subseq(s):
    """Longitud de la subsecuencia palindrómica más larga de s. Θ(n²)."""
    n = len(s)
    P = [[0] * n for _ in range(n)]
    for i in range(n - 1, -1, -1):
        P[i][i] = 1
        for j in range(i + 1, n):
            P[i][j] = P[i + 1][j - 1] + 2 if s[i] == s[j] else max(P[i + 1][j], P[i][j - 1])
    return P[0][n - 1] if n else 0
```

- **`i` decreciente** y `j` creciente: `P[i][j]` usa `P[i+1][…]`, ya calculada, y `P[i][j−1]`, de esta
  misma fila. Recorrer `i` creciente lee ceros sin calcular.
- **`P[i+1][j−1]` con `j = i + 1`** lee una celda con `i + 1 > j − 1`, que vale 0 (intervalo vacío): por eso
  la tabla se inicializa a 0.
- **Es la LCS de `s` con su reverso**: misma longitud, otra forma de verlo.

### De la versión ingenua a la buena

**El problema.** ¿Cuántas subcadenas de `s` (con `n ≤ 5 000`) son palíndromos? Con `abracadabra`, 13.

**La versión ingenua:**

```java
// Correcta: cada una de las n(n+1)/2 subcadenas, comprobada en O(n). Θ(n³).
static long countPalNaive(String s) {
    long count = 0;
    for (int i = 0; i < s.length(); i++)
        for (int j = i; j < s.length(); j++) {
            int l = i, r = j;
            while (l < r && s.charAt(l) == s.charAt(r)) { l++; r--; }
            if (l >= r) count++;
        }
    return count;
}
```

> «Compruebo cada subcadena desde cero, pero `s[i..j]` es palíndromo si y solo si sus extremos coinciden y
> `s[i+1..j−1]` lo es: guardando esa tabla por intervalos, cada comprobación es `O(1)` y el total `Θ(n²)`.»

**El camino a la buena.** `esPal[i][j] = s[i] == s[j] && (j − i < 2 || esPal[i+1][j−1])` con `i`
decreciente, contando los ciertos. (Expandir desde cada centro también da `Θ(n²)` sin tabla; Manacher, en
[`16/03`](../16-cadenas/03-funcion-z-y-manacher.md), lo hace en `Θ(n)`.)

**Cuándo sí**: palíndromos con `n ≤ 5 000`, y como tabla auxiliar de otra DP (partir en palíndromos).
**Cuándo no**: `n ≥ 10⁵`: Manacher o *hashing* (`16/03`, [`16/04`](../16-cadenas/04-hashing-de-cadenas.md)).

> **Veredicto:** los palíndromos son DP sobre intervalos de una cadena: extremos más interior, con `i`
> decreciente. El orden de cálculo es lo que hay que escribir bien.

---

## 6. 🧱 Hirschberg

### Reconstrucción en espacio lineal

**Qué resuelve.** Reconstruir la LCS (o una alineación de edición) de dos cadenas de `10⁵` caracteres,
donde la tabla de `10¹⁰` celdas no cabe pero `10¹⁰` operaciones sí podrían.

**Qué garantiza.** La reconstrucción completa en `Θ(n · m)` tiempo y `Θ(n + m)` memoria: se parte `a` por la
mitad, se calcula con dos filas la DP de la primera mitad hacia delante y la de la segunda hacia atrás, se
elige el corte de `b` que maximiza la suma, y se recurre en los dos cuartos.

**Cuánto.** El tiempo es el doble que la DP simple (`T = n·m + n·m/2 + …`); la memoria, lineal.

**Cómo reconocerlo.** «Imprime la alineación» con cadenas largas y un límite de memoria que no deja la
tabla.

**Si no te la sabes.** Guardar las decisiones en bits (`n · m / 8` bytes) a veces cabe donde la tabla de
enteros no.

**Dónde está entera.** Kleinberg y Tardos, §6.7; el artículo de Hirschberg (1975).

---

## 7. ⏱️ La tabla de costes

| Problema | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| LCS (longitud) | `Θ(n · m)` | `Θ(min(n, m))` | Dos filas; para reconstruir, la tabla o Hirschberg |
| Distancia de edición | `Θ(n · m)` | `Θ(min(n, m))` | Los costes por operación se cambian sin tocar la estructura |
| Subsecuencia palindrómica | `Θ(n²)` | `Θ(n²)` | Orden por `i` decreciente; es la LCS con el reverso |
| Subcadenas palindrómicas | `Θ(n²)` | `Θ(n²)` o `O(1)` expandiendo | Manacher la hace en `Θ(n)` |
| Hirschberg | `Θ(n · m)` | `Θ(n + m)` | Constante doble; solo si la tabla no cabe |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Subsecuencia común», «borrar lo mínimo para que coincidan» | LCS | Prefijos con diagonal o máximo |
| «Mínimo de operaciones para transformar una cadena en otra» | Distancia de edición | Tres movimientos |
| «Palíndromo» con `n ≤ 5 000` | DP sobre intervalos | Extremos más interior |
| «Subsecuencia que es palíndromo», «insertar lo mínimo para hacerla palíndromo» | LCS con el reverso | `n −` la subsecuencia palindrómica más larga |
| «Común **contiguo**» | Subcadena común, no LCS | Otra recurrencia (o *suffix array*) |
| Patrones con `*` y `?` contra un texto | DP de prefijos con transiciones especiales | Como la edición con movimientos propios |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La LCS es la subcadena común más larga» | La LCS es de subsecuencias (no contiguas); la subcadena es otra DP |
| «La tabla mide `n × m`» | Mide `(n + 1) × (m + 1)`: la fila y la columna 0 son los prefijos vacíos |
| «Los palíndromos se llenan por filas» | `P[i][j]` usa `P[i+1][…]`: `i` decreciente o por longitud |
| «Para reconstruir basta con dos filas» | Dos filas dan el valor; la reconstrucción necesita la tabla o Hirschberg |
| «La distancia de edición cuenta el intercambio de vecinos» | Levenshtein no: cuesta 2; Damerau añade la transposición |
| «Insertar y borrar es lo mismo que editar» | Sin sustitución, la distancia es `n + m − 2 · LCS` |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §15.4: la subsecuencia común más larga con su reconstrucción. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §6.6 y §6.7: la alineación de
  secuencias y Hirschberg en espacio lineal. *Lectura troncal.*
- **Libro** — Gusfield, *Algorithms on Strings, Trees and Sequences* (Cambridge, 1997), cap. 11: la
  distancia de edición y sus variantes.
- **Referencia** — USACO Guide, [*Introduction to DP*](https://usaco.guide/gold/intro-dp): LCS y edición
  entre los problemas clásicos.

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre una subsecuencia y una subcadena? Da un ejemplo con `abracadabra`. 🟢
2. ¿Cuál es la recurrencia de la LCS y qué guarda `L[i][j]`? 🟢
3. ¿Qué tres movimientos tiene la distancia de edición, y qué valen los casos base? 🟢
4. ¿En qué orden se llena la tabla de palíndromos, y por qué no por filas? 🟡
5. ¿Por qué con dos filas se obtiene la distancia pero no la secuencia de operaciones? 🟡
6. ¿Qué relación hay entre la subsecuencia palindrómica más larga y la LCS? 🟡
7. Compara la memoria de una tabla de `5 000 × 5 000` enteros en C++, Java y Python. 🟡
8. Demuestra que, si los últimos caracteres coinciden, alguna LCS los empareja. 🟠
9. ¿Cómo calculas la distancia si solo se permiten inserciones y borrados, sin rehacer la DP? 🟠
10. ¿Cómo cambia la recurrencia si sustituir cuesta 2 y borrar o insertar cuesta 1? ¿Qué distancia es esa? 🟠
11. ¿Qué hace Hirschberg y cuándo lo necesitas? 🟠
12. Escribe la recurrencia de la **subcadena** común más larga y explica en qué se diferencia de la LCS. 🔴
13. Tu tabla de palíndromos da resultados absurdos para intervalos de longitud 2. ¿Qué miras? 🔴

---

## 🧩 Problemas propios

### Corrector ortográfico

**Nivel:** 🟢 · **Formato:** programa completo.

Para una palabra tecleada y un diccionario, imprime la palabra del diccionario a menor distancia de
edición (inserciones, borrados y sustituciones de un carácter); si hay empate, la menor en orden
alfabético.

- **Entrada.** Una línea con la palabra. Una línea con `m`. Después, `m` líneas con una palabra.
- **Salida.** La palabra elegida.
- **Restricciones.** `1 ≤ m ≤ 1 000`; palabras de 1 a 20 letras minúsculas.

```text
Entrada     Salida
perra       parra
5
perro
pera
pero
parra
arpa

Entrada     Salida
zzz         ab
2
ab
ba
```

**Pista 1:** ¿cuánto cuesta comparar la palabra con cada una del diccionario, y cabe hacerlo con todas?

### Tres cadenas

**Nivel:** 🟡 · **Formato:** programa completo.

Imprime la longitud de la subsecuencia común más larga de **tres** cadenas.

- **Entrada.** Tres líneas con una cadena cada una.
- **Salida.** Un entero.
- **Restricciones.** Cada cadena tiene entre 1 y 100 letras minúsculas.

```text
Entrada         Salida
abracadabra     3
barbacoa
cabra

Entrada         Salida
ab              0
cd
ef
```

**Pista 1:** si los tres últimos caracteres coinciden, ¿qué haces? ¿Y si no?

### Cortes en palíndromos

**Nivel:** 🟠 · **Formato:** programa completo.

Parte una cadena en trozos que sean todos palíndromos con el menor número de cortes. Imprime ese número.

- **Entrada.** Una línea con la cadena.
- **Salida.** Un entero.
- **Restricciones.** Entre 1 y 2 000 letras minúsculas.

```text
Entrada            Salida
abracadabra        8

Entrada            Salida
aab                1

Entrada            Salida
anitalavalatina    0
```

**Pista 1:** si supieras qué subcadenas son palíndromos en `O(1)`, ¿cuál sería el estado de la DP de los
cortes?

---

## 🧩 Práctica externa

Codility no tiene DP sobre cadenas.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Longest Common Subsequence](https://leetcode.com/problems/longest-common-subsequence/) | LeetCode | 🟡 | LCS | ¿Qué pasa con la LCS de los prefijos si sus últimos caracteres coinciden? |
| [ ] | [Edit Distance](https://leetcode.com/problems/edit-distance/) | LeetCode | 🟡 | Distancia de edición | ¿Qué le pudo pasar al último carácter de la primera cadena? |
| [ ] | [Delete Operation for Two Strings](https://leetcode.com/problems/delete-operation-for-two-strings/) | LeetCode | 🟡 | LCS | Lo que no se borra de ninguna de las dos, ¿qué es? |
| [ ] | [Longest Palindromic Subsequence](https://leetcode.com/problems/longest-palindromic-subsequence/) | LeetCode | 🟡 | DP de intervalos | Si los extremos coinciden, ¿qué parte del intervalo queda por resolver? |
| [ ] | [Common Child](https://www.hackerrank.com/challenges/common-child/problem) | HackerRank | 🟡 | LCS con dos filas | Con 5 000 caracteres por cadena, ¿cuánta memoria pide la tabla entera? |
| [ ] | [The Longest Common Subsequence](https://www.hackerrank.com/challenges/dynamic-programming-classics-the-longest-common-subsequence/problem) | HackerRank | 🟡 | LCS con reconstrucción | ¿Cómo recorres la tabla desde la esquina para escribir la subsecuencia? |
| [ ] | [Interleaving String](https://leetcode.com/problems/interleaving-string/) | LeetCode | 🟡 | DP de dos prefijos | Si usaste `i` caracteres de la primera y `j` de la segunda, ¿cuántos de la tercera? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Edit Distance](https://cses.fi/problemset/task/1639) | CSES | 🟡 | Distancia de edición | Con 5 000 caracteres, ¿dos filas o la tabla? |
| [ ] | [Uncrossed Lines](https://leetcode.com/problems/uncrossed-lines/) | LeetCode | 🟡 | LCS disfrazada | ¿Qué condición cumplen las líneas que no se cruzan? |
| [ ] | [Distinct Subsequences](https://leetcode.com/problems/distinct-subsequences/) | LeetCode | 🟠 | DP de conteo sobre dos prefijos | Si `s[i] = t[j]`, ¿de cuántas formas puedes usarlo o no usarlo? |
| [ ] | [Wildcard Matching](https://leetcode.com/problems/wildcard-matching/) | LeetCode | 🟠 | Prefijos con transición especial | Un `*`, ¿qué puede emparejar: nada, un carácter, o más? |
| [ ] | [Regular Expression Matching](https://leetcode.com/problems/regular-expression-matching/) | LeetCode | 🔴 | Prefijos con `*` que repite el anterior | ¿Qué estado necesitas cuando el patrón tiene `x*`? |

---

## ✅ Criterio de dominio

- Escribir la LCS con reconstrucción y la distancia de edición en dos filas sin mirar, en menos de diez
  minutos cada una.
- Explicar por qué la tabla de palíndromos se llena con `i` decreciente.
- Distinguir subsecuencia y subcadena común y dar la recurrencia de cada una.
- Resolver Edit Distance e Interleaving String sin pista 2.

---

**Anterior:** [`12/03` — Mochilas](03-mochilas.md) · **Siguiente:** [`12/05` — DP en rejillas y de intervalos](05-rejillas-e-intervalos.md) ·
**Relacionado:** [`16/01` — Cadenas en los tres lenguajes y patrones básicos](../16-cadenas/01-cadenas-y-patrones-basicos.md); [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
