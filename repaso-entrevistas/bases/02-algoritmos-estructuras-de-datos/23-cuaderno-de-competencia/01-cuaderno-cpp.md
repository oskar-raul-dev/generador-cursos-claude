# 01 — Cuaderno de C++

> **Opcional.** Las plantillas de nivel A y B del corpus, en C++, sin explicación y listas para copiar. Cada una lleva el enlace a la sección
> del capítulo de donde sale, que es donde están su invariante, su coste y sus trampas.
> **Se genera de los capítulos**, no se edita a mano: si una plantilla cambia en su capítulo, este cuaderno
> se regenera en la misma edición. Las plantillas y las salidas que muestran algunos comentarios se
> comprobaron en la pasada de verificación del 2026-10-04, como en el capítulo de origen.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#-bloque-01--oficio-del-competidor) · [02](#-bloque-02--análisis) · [04](#-bloque-04--secuencias) · [05](#-bloque-05--orden-y-búsqueda) · [06](#-bloque-06--lineales-y-hashing) · [07](#-bloque-07--árboles) · [08](#-bloque-08--heaps-y-union-find) · [09](#-bloque-09--consultas-sobre-rangos) · [10](#-bloque-10--búsqueda-completa-y-divide-y-vencerás) · [11](#-bloque-11--voraces) · [12](#-bloque-12--dp-clásica) · [13](#-bloque-13--dp-avanzada) · [14](#-bloque-14--grafos-recorridos) · [15](#-bloque-15--grafos-con-pesos-y-flujos) · [16](#-bloque-16--cadenas) · [17](#-bloque-17--matemática) · [18](#-bloque-18--geometría) · [19](#-bloque-19--aleatorizados-y-probabilísticos) · [20](#-bloque-20--ad-hoc-constructivos-e-interactivos) · [22](#-bloque-22--teoría-de-la-computación-opcional)

---

## 🧱 Bloque 01 — Oficio del competidor

### `01/03` — La plantilla [A]

De [`01/03` — Entrada, salida y la plantilla en C++, Java y Python, §6](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md#6--la-plantilla).

```cpp
#include <iostream>
#include <vector>

int main() {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    int n;
    std::cin >> n;
    std::vector<long long> a(n);
    for (auto& x : a) std::cin >> x;

    long long sum = 0;                  // aquí va la solución
    for (long long x : a) sum += x;

    std::cout << sum << '\n';
    return 0;
}
```

### `01/05` — El *stress test* [A]

De [`01/05` — Probar sin IDE: casos borde, depuración y *stress test*, §4](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md#4--el-stress-test).

```cpp
#include <iostream>
#include <random>
#include <string>

int main(int, char* argv[]) {
    std::mt19937 rng(std::stoul(argv[1]));            // la semilla la pasa el arnés
    auto between = [&](int lo, int hi) {
        return std::uniform_int_distribution<int>(lo, hi)(rng);
    };
    int n = between(1, 8);                             // pequeño: se lee a simple vista
    std::cout << n << '\n';
    for (int i = 0; i < n; i++) std::cout << between(-5, 5) << (i + 1 < n ? ' ' : '\n');
}
```

---

## 🧱 Bloque 02 — Análisis

### `02/05` — Caché y localidad [B]

De [`02/05` — El coste real, §3](../02-analisis/05-el-coste-real.md#3--caché-y-localidad).

```cpp
#include <cstddef>
#include <vector>

// Suma por filas: accesos contiguos, cada línea de caché se aprovecha entera.
long long sumByRows(const std::vector<int>& m, int n) {
    long long s = 0;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++) s += m[static_cast<std::size_t>(i) * n + j];
    return s;
}

// Suma por columnas: cada acceso salta n enteros; con n grande, una línea por acceso.
long long sumByColumns(const std::vector<int>& m, int n) {
    long long s = 0;
    for (int j = 0; j < n; j++)
        for (int i = 0; i < n; i++) s += m[static_cast<std::size_t>(i) * n + j];
    return s;
}
```

---

## 🧱 Bloque 04 — Secuencias

### `04/01` — Prefijos 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §3](../04-secuencias/01-prefijos-y-diferencias.md#3--prefijos-1d).

```cpp
#include <vector>

// P[k] = a[0] + ... + a[k-1]; suma de a[l..r] = P[r+1] - P[l].
std::vector<long long> buildPrefix(const std::vector<int>& a) {
    std::vector<long long> p(a.size() + 1, 0);
    for (std::size_t i = 0; i < a.size(); i++) p[i + 1] = p[i] + a[i];
    return p;
}

long long rangeSum(const std::vector<long long>& p, int l, int r) {   // l, r incluidos
    return p[r + 1] - p[l];
}
```

### `04/01` — Diferencias 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §4](../04-secuencias/01-prefijos-y-diferencias.md#4--diferencias-1d).

```cpp
#include <vector>

// Suma v a [l, r] en O(1); al final, finish() reconstruye el arreglo con prefijos.
struct RangeAdd {
    std::vector<long long> d;
    explicit RangeAdd(int n) : d(n + 1, 0) {}
    void add(int l, int r, long long v) { d[l] += v; d[r + 1] -= v; }
    std::vector<long long> finish() const {
        std::vector<long long> b(d.size() - 1);
        long long run = 0;
        for (std::size_t i = 0; i + 1 < d.size(); i++) b[i] = (run += d[i]);
        return b;
    }
};
```

### `04/01` — Prefijos y diferencias 2D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §5](../04-secuencias/01-prefijos-y-diferencias.md#5--prefijos-y-diferencias-2d).

```cpp
#include <vector>

// S[i][j] = suma de M[0..i-1][0..j-1]; consulta inclusiva de (r1,c1) a (r2,c2).
struct Prefix2D {
    std::vector<std::vector<long long>> s;
    explicit Prefix2D(const std::vector<std::vector<int>>& m)
        : s(m.size() + 1, std::vector<long long>(m.empty() ? 1 : m[0].size() + 1, 0)) {
        for (std::size_t i = 0; i < m.size(); i++)
            for (std::size_t j = 0; j < m[0].size(); j++)
                s[i + 1][j + 1] = m[i][j] + s[i][j + 1] + s[i + 1][j] - s[i][j];
    }
    long long query(int r1, int c1, int r2, int c2) const {
        return s[r2 + 1][c2 + 1] - s[r1][c2 + 1] - s[r2 + 1][c1] + s[r1][c1];
    }
};
```

### `04/02` — Dos punteros [A]

De [`04/02` — Dos punteros y ventana deslizante, §3](../04-secuencias/02-dos-punteros-y-ventana.md#3--dos-punteros).

```cpp
#include <vector>

// Número de pares i < j con a[i] + a[j] <= k. Pre: a ordenado. O(n).
long long countPairsAtMost(const std::vector<int>& a, long long k) {
    long long count = 0;
    int l = 0, r = static_cast<int>(a.size()) - 1;
    while (l < r) {
        if (static_cast<long long>(a[l]) + a[r] <= k) { count += r - l; l++; }
        else r--;
    }
    return count;
}
```

### `04/02` — Ventana variable [A]

De [`04/02` — Dos punteros y ventana deslizante, §4](../04-secuencias/02-dos-punteros-y-ventana.md#4--ventana-variable).

```cpp
#include <algorithm>
#include <vector>

// Longitud del subarreglo más largo con suma <= s. Pre: a[i] >= 0. O(n).
int longestAtMost(const std::vector<int>& a, long long s) {
    long long sum = 0;
    int best = 0;
    for (int l = 0, r = 0; r < static_cast<int>(a.size()); r++) {
        sum += a[r];                          // entra a[r]
        while (sum > s) sum -= a[l++];        // sale por la izquierda hasta volver a cumplir
        best = std::max(best, r - l + 1);     // [l, r] es el más largo que termina en r
    }
    return best;
}
```

### `04/02` — Ventana fija [A]

De [`04/02` — Dos punteros y ventana deslizante, §5](../04-secuencias/02-dos-punteros-y-ventana.md#5--ventana-fija).

```cpp
#include <algorithm>
#include <vector>

// Máxima suma de k elementos consecutivos. Pre: 1 <= k <= n. O(n).
long long maxWindowSum(const std::vector<int>& a, int k) {
    long long sum = 0;
    for (int i = 0; i < k; i++) sum += a[i];
    long long best = sum;
    for (int i = k; i < static_cast<int>(a.size()); i++) {
        sum += a[i] - a[i - k];               // entra a[i], sale a[i - k]
        best = std::max(best, sum);
    }
    return best;
}
```

### `04/03` — Kadane [A]

De [`04/03` — Kadane y subarreglos, §3](../04-secuencias/03-kadane-y-subarreglos.md#3--kadane).

```cpp
#include <algorithm>
#include <vector>

// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
long long maxSubarraySum(const std::vector<long long>& a) {
    long long best = a[0], cur = 0;
    for (long long x : a) {
        cur = std::max(x, cur + x);     // el mejor que termina aquí: extender o empezar
        best = std::max(best, cur);
    }
    return best;
}
```

### `04/03` — La variante circular [A]

De [`04/03` — Kadane y subarreglos, §4](../04-secuencias/03-kadane-y-subarreglos.md#4--la-variante-circular).

```cpp
#include <algorithm>
#include <vector>

// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
long long maxCircularSum(const std::vector<long long>& a) {
    long long total = 0, curMax = 0, curMin = 0, best = a[0], worst = a[0];
    for (long long x : a) {
        total += x;
        curMax = std::max(x, curMax + x); best = std::max(best, curMax);
        curMin = std::min(x, curMin + x); worst = std::min(worst, curMin);
    }
    return best < 0 ? best : std::max(best, total - worst);   // todos negativos: no hay complemento
}
```

### `04/03` — Contar subarreglos con prefijos y *hash* [A]

De [`04/03` — Kadane y subarreglos, §5](../04-secuencias/03-kadane-y-subarreglos.md#5--contar-subarreglos-con-prefijos-y-hash).

```cpp
#include <unordered_map>
#include <vector>

// Número de subarreglos con suma exactamente k. O(n) esperado.
long long countSubarraysWithSum(const std::vector<long long>& a, long long k) {
    std::unordered_map<long long, long long> seen;
    seen.reserve(a.size() * 2 + 1);
    seen[0] = 1;                                  // el prefijo vacío
    long long prefix = 0, count = 0;
    for (long long x : a) {
        prefix += x;
        auto it = seen.find(prefix - k);
        if (it != seen.end()) count += it->second;   // tramos que terminan aquí
        seen[prefix]++;
    }
    return count;
}
```

### `04/03` — El voto de mayoría de Boyer-Moore [B]

De [`04/03` — Kadane y subarreglos, §6](../04-secuencias/03-kadane-y-subarreglos.md#6--el-voto-de-mayoría-de-boyer-moore).

```cpp
#include <vector>

// Valor que aparece más de n/2 veces, o -1 si no hay. O(n), O(1) memoria. Pre: valores >= 0.
long long majority(const std::vector<long long>& a) {
    long long cand = -1, cnt = 0;
    for (long long x : a) {
        if (cnt == 0) { cand = x; cnt = 1; }
        else if (x == cand) cnt++;
        else cnt--;                               // empareja x con una copia del candidato
    }
    long long occ = 0;
    for (long long x : a) occ += (x == cand);
    return 2 * occ > static_cast<long long>(a.size()) ? cand : -1;   // la comprobación
}
```

### `04/04` — Compresión de coordenadas [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §3](../04-secuencias/04-compresion-y-barrido.md#3--compresión-de-coordenadas).

```cpp
#include <algorithm>
#include <vector>

// Devuelve los rangos de a en [0, k), con k el número de valores distintos. O(n log n).
std::vector<int> compress(const std::vector<long long>& a, std::vector<long long>& sortedDistinct) {
    sortedDistinct = a;
    std::sort(sortedDistinct.begin(), sortedDistinct.end());
    sortedDistinct.erase(std::unique(sortedDistinct.begin(), sortedDistinct.end()),
                         sortedDistinct.end());
    std::vector<int> rank(a.size());
    for (std::size_t i = 0; i < a.size(); i++)
        rank[i] = static_cast<int>(std::lower_bound(sortedDistinct.begin(), sortedDistinct.end(), a[i])
                                   - sortedDistinct.begin());
    return rank;
}
```

### `04/04` — Barrido de eventos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §4](../04-secuencias/04-compresion-y-barrido.md#4--barrido-de-eventos).

```cpp
#include <algorithm>
#include <utility>
#include <vector>

// Máximo de intervalos [s, e) que se solapan en algún instante. O(n log n).
int maxOverlap(const std::vector<std::pair<long long, long long>>& intervals) {
    std::vector<std::pair<long long, int>> events;     // (instante, +1 abre / −1 cierra)
    for (auto [s, e] : intervals) { events.push_back({s, +1}); events.push_back({e, -1}); }
    std::sort(events.begin(), events.end());           // en empate, −1 antes que +1: cierra primero
    int open = 0, best = 0;
    for (auto [t, d] : events) { open += d; best = std::max(best, open); }
    return best;
}
```

### `04/04` — Unión de intervalos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §5](../04-secuencias/04-compresion-y-barrido.md#5--unión-de-intervalos).

```cpp
#include <algorithm>
#include <utility>
#include <vector>

// Une intervalos [s, e) que se solapan. Devuelve los bloques disjuntos ordenados. O(n log n).
std::vector<std::pair<long long, long long>> mergeIntervals(std::vector<std::pair<long long, long long>> v) {
    std::sort(v.begin(), v.end());
    std::vector<std::pair<long long, long long>> out;
    for (auto [s, e] : v) {
        if (!out.empty() && s < out.back().second) out.back().second = std::max(out.back().second, e);
        else out.push_back({s, e});
    }
    return out;
}
```

### `04/05` — Recorridos, rotación y espiral [A]

De [`04/05` — Matrices, §3](../04-secuencias/05-matrices.md#3--recorridos-rotación-y-espiral).

```cpp
#include <algorithm>
#include <vector>

const int DR[4] = {-1, 1, 0, 0}, DC[4] = {0, 0, -1, 1};   // arriba, abajo, izquierda, derecha

// Recorre los vecinos de (r, c) dentro de una matriz rows × cols.
template <class F> void forNeighbors(int r, int c, int rows, int cols, F visit) {
    for (int d = 0; d < 4; d++) {
        int nr = r + DR[d], nc = c + DC[d];
        if (0 <= nr && nr < rows && 0 <= nc && nc < cols) visit(nr, nc);   // una sola comprobación
    }
}

// Gira una matriz n × n 90° en sentido horario, en el sitio: transponer y reflejar cada fila.
void rotateClockwise(std::vector<std::vector<int>>& m) {
    int n = static_cast<int>(m.size());
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) std::swap(m[i][j], m[j][i]);
    for (auto& row : m) std::reverse(row.begin(), row.end());
}

// Recorrido en espiral en sentido horario desde la esquina superior izquierda.
std::vector<int> spiral(const std::vector<std::vector<int>>& m) {
    std::vector<int> out;
    int top = 0, bottom = static_cast<int>(m.size()) - 1, left = 0, right = static_cast<int>(m[0].size()) - 1;
    while (top <= bottom && left <= right) {
        for (int j = left; j <= right; j++) out.push_back(m[top][j]);
        top++;
        for (int i = top; i <= bottom; i++) out.push_back(m[i][right]);
        right--;
        if (top <= bottom) { for (int j = right; j >= left; j--) out.push_back(m[bottom][j]); bottom--; }
        if (left <= right) { for (int i = bottom; i >= top; i--) out.push_back(m[i][left]); left++; }
    }
    return out;
}
```

### `04/05` — Búsqueda en matriz ordenada [A]

De [`04/05` — Matrices, §4](../04-secuencias/05-matrices.md#4--búsqueda-en-matriz-ordenada).

```cpp
#include <utility>
#include <vector>

// Busca x en una matriz con filas y columnas crecientes. Devuelve {fila, columna} o {-1, -1}. O(R + C).
std::pair<int, int> staircaseSearch(const std::vector<std::vector<int>>& m, int x) {
    int i = 0, j = static_cast<int>(m[0].size()) - 1;
    while (i < static_cast<int>(m.size()) && j >= 0) {
        if (m[i][j] == x) return {i, j};
        if (m[i][j] > x) j--;          // toda la columna j desde la fila i es > x
        else i++;                      // toda la fila i hasta la columna j es < x
    }
    return {-1, -1};
}
```

### `04/05` — Representación dispersa [B]

De [`04/05` — Matrices, §5](../04-secuencias/05-matrices.md#5--representación-dispersa).

```cpp
#include <vector>

// Matriz dispersa en formato CSR: la fila i ocupa [rowStart[i], rowStart[i+1]) de values y cols.
struct CsrMatrix {
    std::vector<int> rowStart, cols;
    std::vector<long long> values;

    std::vector<long long> multiply(const std::vector<long long>& x) const {   // y = A · x
        int rows = static_cast<int>(rowStart.size()) - 1;
        std::vector<long long> y(rows, 0);
        for (int i = 0; i < rows; i++)
            for (int k = rowStart[i]; k < rowStart[i + 1]; k++) y[i] += values[k] * x[cols[k]];
        return y;
    }
};
```

---

## 🧱 Bloque 05 — Orden y búsqueda

### `05/01` — Inserción y estabilidad [A]

De [`05/01` — Ordenación por comparación, §3](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#3--inserción-y-estabilidad).

```cpp
#include <vector>

// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
void insertionSort(std::vector<int>& a) {
    for (std::size_t j = 1; j < a.size(); j++) {
        int key = a[j];
        std::size_t i = j;
        while (i > 0 && a[i - 1] > key) { a[i] = a[i - 1]; i--; }   // solo los estrictamente mayores
        a[i] = key;
    }
}
```

### `05/01` — Ordenación por mezcla [A]

De [`05/01` — Ordenación por comparación, §4](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#4--ordenación-por-mezcla).

```cpp
#include <vector>

// Ordenación por mezcla de a[lo, hi), estable. Θ(n log n) caso peor, Θ(n) memoria auxiliar.
void mergeSort(std::vector<int>& a, std::vector<int>& buf, int lo, int hi) {
    if (hi - lo <= 1) return;
    int mid = lo + (hi - lo) / 2;
    mergeSort(a, buf, lo, mid);
    mergeSort(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) buf[k++] = (a[j] < a[i]) ? a[j++] : a[i++];   // empate: izquierda
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    for (k = lo; k < hi; k++) a[k] = buf[k];
}
```

### `05/01` — *Quicksort* [A]

De [`05/01` — Ordenación por comparación, §5](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#5--quicksort).

```cpp
#include <random>
#include <utility>
#include <vector>

std::mt19937 rng(20261004);   // semilla fija para reproducir; en un juez con hacks, una del reloj

// Quicksort de a[lo, hi] (inclusivo) con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
void quickSort(std::vector<int>& a, int lo, int hi) {
    if (lo >= hi) return;
    std::swap(a[lo], a[std::uniform_int_distribution<int>(lo, hi)(rng)]);   // pivote aleatorio en a[lo]
    int p = a[lo];
    int i = lo - 1, j = hi + 1;
    while (true) {
        do i++; while (a[i] < p);
        do j--; while (a[j] > p);
        if (i >= j) break;
        std::swap(a[i], a[j]);
    }
    quickSort(a, lo, j);        // con Hoare, el corte es j: [lo, j] y [j+1, hi]
    quickSort(a, j + 1, hi);
}
```

### `05/01` — *Heapsort* [B]

De [`05/01` — Ordenación por comparación, §6](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#6--heapsort).

```cpp
#include <algorithm>
#include <vector>

void heapSort(std::vector<int>& a) {
    std::make_heap(a.begin(), a.end());   // montículo de máximos, O(n)
    std::sort_heap(a.begin(), a.end());   // n extracciones, O(n log n)
}
```

### `05/02` — *Counting sort* [B]

De [`05/02` — Ordenación lineal, §3](../05-orden-y-busqueda/02-ordenacion-lineal.md#3--counting-sort).

```cpp
#include <vector>

// Counting sort estable de valores en [0, k). Θ(n + k) tiempo y memoria.
std::vector<int> countingSort(const std::vector<int>& a, int k) {
    std::vector<int> start(k + 1, 0);
    for (int x : a) start[x + 1]++;                       // cuenta desplazada una posición
    for (int v = 0; v < k; v++) start[v + 1] += start[v]; // start[v] = cuántos son menores que v
    std::vector<int> out(a.size());
    for (int x : a) out[start[x]++] = x;                  // izquierda a derecha: estable
    return out;
}
```

### `05/02` — *Radix sort* [B]

De [`05/02` — Ordenación lineal, §4](../05-orden-y-busqueda/02-ordenacion-lineal.md#4--radix-sort).

```cpp
#include <vector>

// Radix sort LSD de enteros no negativos, base 256: cuatro pasadas de counting. Θ(4 · (n + 256)).
void radixSort(std::vector<unsigned>& a) {
    std::vector<unsigned> buf(a.size());
    for (int shift = 0; shift < 32; shift += 8) {
        unsigned start[257] = {0};
        for (unsigned x : a) start[((x >> shift) & 255) + 1]++;
        for (int v = 0; v < 256; v++) start[v + 1] += start[v];
        for (unsigned x : a) buf[start[(x >> shift) & 255]++] = x;
        a.swap(buf);                     // cuatro intercambios: el resultado acaba en a
    }
}
```

### `05/03` — Contar inversiones con la mezcla [A]

De [`05/03` — Inversiones, selección y mediana, §3](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#3--contar-inversiones-con-la-mezcla).

```cpp
#include <vector>

// Ordena a[lo, hi) por mezcla y devuelve sus inversiones. Θ(n log n). buf, del tamaño de a.
long long countInversions(std::vector<int>& a, std::vector<int>& buf, int lo, int hi) {
    if (hi - lo <= 1) return 0;
    int mid = lo + (hi - lo) / 2;
    long long inv = countInversions(a, buf, lo, mid) + countInversions(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) {
        if (a[j] < a[i]) { inv += mid - i; buf[k++] = a[j++]; }   // quedan mid − i mayores
        else buf[k++] = a[i++];
    }
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    for (k = lo; k < hi; k++) a[k] = buf[k];
    return inv;
}
```

### `05/03` — *Quickselect* [A]

De [`05/03` — Inversiones, selección y mediana, §4](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#4--quickselect).

```cpp
#include <random>
#include <utility>
#include <vector>

std::mt19937 rng(20261004);

// Valor que ocuparía la posición k (0-indexada) si a estuviera ordenado. Reordena a. O(n) esperado.
int quickSelect(std::vector<int>& a, int k) {
    int lo = 0, hi = (int)a.size() - 1;
    while (lo < hi) {
        std::swap(a[lo], a[std::uniform_int_distribution<int>(lo, hi)(rng)]);   // pivote aleatorio en a[lo]
        int p = a[lo];
        int i = lo - 1, j = hi + 1;
        while (true) {
            do i++; while (a[i] < p);
            do j--; while (a[j] > p);
            if (i >= j) break;
            std::swap(a[i], a[j]);
        }
        if (k <= j) hi = j; else lo = j + 1;      // el corte de Hoare: [lo, j] y [j+1, hi]
    }
    return a[k];
}
```

### `05/04` — *Lower* y *upper bound* [A]

De [`05/04` — Búsqueda binaria, §3](../05-orden-y-busqueda/04-busqueda-binaria.md#3--lower-y-upper-bound).

```cpp
#include <vector>

// Primer índice en [0, n] con a[i] >= x. Pre: a ordenado. Θ(log n).
int lowerBound(const std::vector<int>& a, int x) {
    int lo = 0, hi = (int)a.size();
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (a[mid] < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}

// Primer índice en [0, n] con a[i] > x. Solo cambia la comparación.
int upperBound(const std::vector<int>& a, int x) {
    int lo = 0, hi = (int)a.size();
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (a[mid] <= x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

### `05/04` — Binaria sobre la respuesta [A]

De [`05/04` — Búsqueda binaria, §4](../05-orden-y-busqueda/04-busqueda-binaria.md#4--binaria-sobre-la-respuesta).

```cpp
#include <functional>

// Primer v en [lo, hi) con P(v) cierto, o hi si no hay. Pre: P monótono (falso…cierto).
long long firstTrue(long long lo, long long hi, const std::function<bool(long long)>& P) {
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;
        if (P(mid)) hi = mid; else lo = mid + 1;
    }
    return lo;
}

// Uso con los cables: la mayor longitud con al menos k trozos.
// long long f = firstTrue(1, maxLen + 1, [&](long long len) { return pieces(len) < k; });
// long long answer = f - 1;   // 0 si ni con longitud 1 salen k trozos
```

### `05/04` — Binaria en reales [A]

De [`05/04` — Búsqueda binaria, §5](../05-orden-y-busqueda/04-busqueda-binaria.md#5--binaria-en-reales).

```cpp
#include <functional>

// Frontera de P (falso…cierto) en [lo, hi], con 100 vueltas fijas.
double boundaryReal(double lo, double hi, const std::function<bool(double)>& P) {
    for (int it = 0; it < 100; it++) {
        double mid = lo + (hi - lo) / 2;
        if (P(mid)) hi = mid; else lo = mid;
    }
    return hi;
}
```

### `05/05` — Búsqueda ternaria [B]

De [`05/05` — Búsqueda ternaria, unimodales y exponencial, §3](../05-orden-y-busqueda/05-ternaria-y-exponencial.md#3--búsqueda-ternaria).

```cpp
#include <functional>

// Posición del mínimo de f en [lo, hi], f estrictamente unimodal (o convexa). O(log n) evaluaciones.
long long ternaryMinInt(long long lo, long long hi, const std::function<long long(long long)>& f) {
    while (hi - lo > 2) {
        long long m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f(m1) < f(m2)) hi = m2 - 1; else lo = m1 + 1;
    }
    long long best = lo;                                  // quedan como mucho tres candidatos
    for (long long x = lo + 1; x <= hi; x++) if (f(x) < f(best)) best = x;
    return best;
}

// Mínimo de f en [lo, hi] sobre reales, con 100 vueltas fijas.
double ternaryMinReal(double lo, double hi, const std::function<double(double)>& f) {
    for (int it = 0; it < 100; it++) {
        double m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f(m1) < f(m2)) hi = m2; else lo = m1;
    }
    return lo + (hi - lo) / 2;
}
```

### `05/05` — Búsqueda exponencial [B]

De [`05/05` — Búsqueda ternaria, unimodales y exponencial, §5](../05-orden-y-busqueda/05-ternaria-y-exponencial.md#5--búsqueda-exponencial).

```cpp
#include <functional>
#include <limits>

// Lower bound de x en una secuencia ordenada sin tamaño conocido. at(i) = +∞ fuera de rango. O(log p).
long long exponentialLowerBound(const std::function<long long(long long)>& at, long long x) {
    if (at(0) >= x) return 0;
    long long hi = 1;
    while (at(hi) < x) hi *= 2;                           // al salir, at(hi / 2) < x <= at(hi)
    long long lo = hi / 2 + 1;
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;
        if (at(mid) < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

---

## 🧱 Bloque 06 — Lineales y hashing

### `06/01` — Pila, cola y deque [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §3](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#3--pila-cola-y-deque).

```cpp
#include <deque>
#include <stack>
#include <vector>

std::vector<int> st;            // pila: push_back, back, pop_back (más flexible que std::stack)
std::deque<int> dq;             // cola y deque: push_back, push_front, front, back, pop_front, pop_back
std::stack<int> s;              // adaptador sobre deque: push, top, pop; no se puede recorrer
```

### `06/01` — Pila monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §4](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#4--pila-monótona).

```cpp
#include <vector>

// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
std::vector<int> nextGreater(const std::vector<int>& a) {
    int n = a.size();
    std::vector<int> ans(n, -1), st;              // st: índices con valores decrecientes
    for (int i = 0; i < n; i++) {
        while (!st.empty() && a[st.back()] < a[i]) { ans[st.back()] = i; st.pop_back(); }
        st.push_back(i);
    }
    return ans;
}
```

### `06/01` — Cola monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §5](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#5--cola-monótona).

```cpp
#include <deque>
#include <vector>

// mins[i] = mínimo de a[i, i + k). Θ(n).
std::vector<int> windowMin(const std::vector<int>& a, int k) {
    std::deque<int> dq;                            // índices con valores crecientes
    std::vector<int> mins;
    for (int i = 0; i < (int)a.size(); i++) {
        while (!dq.empty() && a[dq.back()] >= a[i]) dq.pop_back();   // ya no serán mínimo
        dq.push_back(i);
        if (dq.front() <= i - k) dq.pop_front();                       // salió de la ventana
        if (i >= k - 1) mins.push_back(a[dq.front()]);
    }
    return mins;
}
```

### `06/02` — Inversión, punto medio y mezcla [A]

De [`06/02` — Listas enlazadas, §3](../06-lineales-y-hashing/02-listas-enlazadas.md#3--inversión-punto-medio-y-mezcla).

```cpp
struct ListNode {
    int val;
    ListNode* next;
    explicit ListNode(int v, ListNode* n = nullptr) : val(v), next(n) {}
};

ListNode* reverse(ListNode* head) {
    ListNode* prev = nullptr;
    while (head) {
        ListNode* nxt = head->next;     // guarda el resto ANTES de cambiar el enlace
        head->next = prev;
        prev = head;
        head = nxt;
    }
    return prev;
}

// Con n par, devuelve el primero de la segunda mitad.
ListNode* middle(ListNode* head) {
    ListNode *slow = head, *fast = head;
    while (fast && fast->next) { slow = slow->next; fast = fast->next->next; }
    return slow;
}

ListNode* merge(ListNode* a, ListNode* b) {
    ListNode dummy(0);                  // centinela en la pila: nada que liberar
    ListNode* tail = &dummy;
    while (a && b) {
        ListNode*& pick = (b->val < a->val) ? b : a;   // empate: a, estable
        tail->next = pick; tail = pick; pick = pick->next;
    }
    tail->next = a ? a : b;
    return dummy.next;
}
```

### `06/02` — Floyd: detectar el ciclo y su inicio [A]

De [`06/02` — Listas enlazadas, §4](../06-lineales-y-hashing/02-listas-enlazadas.md#4--floyd-detectar-el-ciclo-y-su-inicio).

```cpp
// Inicio del ciclo, o nullptr si la lista termina. O(n) tiempo, O(1) memoria.
ListNode* cycleStart(ListNode* head) {
    ListNode *slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next; fast = fast->next->next;
        if (slow == fast) {                       // dentro del ciclo
            ListNode* p = head;
            while (p != slow) { p = p->next; slow = slow->next; }
            return p;
        }
    }
    return nullptr;
}
```

### `06/02` — La caché LRU [A]

De [`06/02` — Listas enlazadas, §5](../06-lineales-y-hashing/02-listas-enlazadas.md#5--la-caché-lru).

```cpp
#include <list>
#include <unordered_map>
#include <utility>

// LRU de capacidad cap: get y put en O(1) esperado.
class LRUCache {
    int cap;
    std::list<std::pair<int, int>> order;     // delante, el más reciente
    std::unordered_map<int, std::list<std::pair<int, int>>::iterator> pos;
public:
    explicit LRUCache(int capacity) : cap(capacity) {}
    int get(int key) {
        auto it = pos.find(key);
        if (it == pos.end()) return -1;
        order.splice(order.begin(), order, it->second);   // mueve el nodo al frente, O(1)
        return it->second->second;
    }
    void put(int key, int value) {
        if (auto it = pos.find(key); it != pos.end()) {
            it->second->second = value;
            order.splice(order.begin(), order, it->second);
            return;
        }
        if ((int)order.size() == cap) { pos.erase(order.back().first); order.pop_back(); }
        order.emplace_front(key, value);
        pos[key] = order.begin();
    }
};
```

### `06/03` — Encadenamiento y direccionamiento abierto [A]

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §3](../06-lineales-y-hashing/03-tablas-hash.md#3--encadenamiento-y-direccionamiento-abierto).

```cpp
#include <cstdint>
#include <utility>
#include <vector>

// Conjunto de enteros de 64 bits con sondeo lineal; capacidad potencia de 2; α ≤ 1/2.
struct IntSet {
    std::vector<uint64_t> keys; std::vector<char> used; size_t n = 0;
    explicit IntSet(size_t cap = 16) : keys(cap), used(cap) {}
    size_t slot(uint64_t x) const {               // mezcla: los bits altos influyen en los bajos
        uint64_t h = x * 0x9e3779b97f4a7c15ULL;
        return (h ^ (h >> 32)) & (keys.size() - 1);
    }
    bool contains(uint64_t x) const {
        for (size_t i = slot(x); used[i]; i = (i + 1) & (keys.size() - 1))
            if (keys[i] == x) return true;
        return false;
    }
    void insert(uint64_t x) {
        if (2 * (n + 1) > keys.size()) grow();
        size_t i = slot(x);
        for (; used[i]; i = (i + 1) & (keys.size() - 1)) if (keys[i] == x) return;
        keys[i] = x; used[i] = 1; n++;
    }
    void grow() {                                 // rehash al doble: O(n), amortizado O(1)
        IntSet bigger(keys.size() * 2);
        for (size_t i = 0; i < keys.size(); i++) if (used[i]) bigger.insert(keys[i]);
        *this = std::move(bigger);
    }
};
```

### `06/03` — *Anti-hash tests* y *hash* propio [B]

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §5](../06-lineales-y-hashing/03-tablas-hash.md#5--anti-hash-tests-y-hash-propio).

```cpp
#include <chrono>
#include <cstdint>
#include <unordered_map>

// splitmix64 con una semilla del reloj: el atacante no puede predecir las cubetas.
struct SafeHash {
    static uint64_t splitmix64(uint64_t x) {
        x += 0x9e3779b97f4a7c15ULL;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
        x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
        return x ^ (x >> 31);
    }
    size_t operator()(uint64_t x) const {
        static const uint64_t SEED =
            std::chrono::steady_clock::now().time_since_epoch().count();
        return splitmix64(x + SEED);
    }
};

std::unordered_map<long long, int, SafeHash> cnt;   // uso: igual que un unordered_map normal
```

### `06/04` — *Hash* polinomial sobre prefijos [B]

De [`06/04` — *Hashing* de secuencias, §3](../06-lineales-y-hashing/04-hashing-de-secuencias.md#3--hash-polinomial-sobre-prefijos).

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

### `06/04` — Doble módulo y módulo `2⁶¹ − 1` [B]

De [`06/04` — *Hashing* de secuencias, §4](../06-lineales-y-hashing/04-hashing-de-secuencias.md#4--doble-módulo-y-módulo-2--1).

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

### `06/04` — Zobrist y *hash* de multiconjuntos [B]

De [`06/04` — *Hashing* de secuencias, §5](../06-lineales-y-hashing/04-hashing-de-secuencias.md#5--zobrist-y-hash-de-multiconjuntos).

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

---

## 🧱 Bloque 07 — Árboles

### `07/01` — Representación [A]

De [`07/01` — Árboles: representación y recorridos, §3](../07-arboles/01-arboles-y-recorridos.md#3--representación).

```cpp
#include <vector>

// Árbol de n nodos (1..n) a partir de sus n − 1 aristas no dirigidas.
std::vector<std::vector<int>> buildTree(int n, const std::vector<std::pair<int, int>>& edges) {
    std::vector<std::vector<int>> adj(n + 1);
    for (auto [u, v] : edges) { adj[u].push_back(v); adj[v].push_back(u); }
    return adj;
}
```

### `07/01` — Los cuatro recorridos [A]

De [`07/01` — Árboles: representación y recorridos, §4](../07-arboles/01-arboles-y-recorridos.md#4--los-cuatro-recorridos).

```cpp
#include <vector>

struct TreeNode { int val; TreeNode *left = nullptr, *right = nullptr; };

void inorder(TreeNode* t, std::vector<int>& out) {             // pre y post: mover la línea del push
    if (!t) return;
    inorder(t->left, out); out.push_back(t->val); inorder(t->right, out);
}

// Preorden iterativo desde root sobre lista de adyacencia; parent y depth de cada nodo. O(n).
std::vector<int> preorder(const std::vector<std::vector<int>>& adj, int root,
                          std::vector<int>& parent, std::vector<int>& depth) {
    std::vector<int> order, st = {root};
    parent.assign(adj.size(), 0); depth.assign(adj.size(), 0);
    parent[root] = -1;
    while (!st.empty()) {
        int v = st.back(); st.pop_back();
        order.push_back(v);
        for (int w : adj[v]) if (w != parent[v]) {
            parent[w] = v; depth[w] = depth[v] + 1; st.push_back(w);
        }
    }
    return order;
}
```

### `07/01` — Diámetro [A]

De [`07/01` — Árboles: representación y recorridos, §5](../07-arboles/01-arboles-y-recorridos.md#5--diámetro).

```cpp
#include <queue>
#include <utility>
#include <vector>

// (nodo más lejano de s, distancia). BFS sobre árbol sin pesos. O(n).
std::pair<int, int> farthest(const std::vector<std::vector<int>>& adj, int s) {
    std::vector<int> dist(adj.size(), -1);
    std::queue<int> q; q.push(s); dist[s] = 0;
    int best = s;
    while (!q.empty()) {
        int v = q.front(); q.pop();
        if (dist[v] > dist[best]) best = v;
        for (int w : adj[v]) if (dist[w] < 0) { dist[w] = dist[v] + 1; q.push(w); }
    }
    return {best, dist[best]};
}

int diameter(const std::vector<std::vector<int>>& adj) {
    return farthest(adj, farthest(adj, 1).first).second;
}
```

### `07/01` — Recorrido de Euler y tiempos [B]

De [`07/01` — Árboles: representación y recorridos, §6](../07-arboles/01-arboles-y-recorridos.md#6--recorrido-de-euler-y-tiempos).

```cpp
#include <vector>

// Con order de preorden y size de subárbol (§4): tin y tout en O(n).
void eulerTimes(const std::vector<int>& order, const std::vector<int>& size,
                std::vector<int>& tin, std::vector<int>& tout) {
    for (int i = 0; i < (int)order.size(); i++) tin[order[i]] = i;
    for (int v : order) tout[v] = tin[v] + size[v] - 1;
}
```

### `07/02` — El árbol binario de búsqueda [A]

De [`07/02` — BST y árboles balanceados, §3](../07-arboles/02-bst-y-balanceados.md#3--el-árbol-binario-de-búsqueda).

```cpp
struct Node { int key; Node *left = nullptr, *right = nullptr; explicit Node(int k) : key(k) {} };

Node* insert(Node* t, int key) {                       // sin repetidos
    if (!t) return new Node(key);
    if (key < t->key) t->left = insert(t->left, key);
    else if (key > t->key) t->right = insert(t->right, key);
    return t;
}

bool contains(Node* t, int key) {
    while (t && t->key != key) t = key < t->key ? t->left : t->right;
    return t != nullptr;
}

// Menor clave >= x (ceiling), o nullptr. O(h).
Node* ceiling(Node* t, int x) {
    Node* best = nullptr;
    while (t) {
        if (t->key >= x) { best = t; t = t->left; }   // candidata; puede haber una menor a la izquierda
        else t = t->right;
    }
    return best;
}
```

### `07/02` — AVL [B]

De [`07/02` — BST y árboles balanceados, §4](../07-arboles/02-bst-y-balanceados.md#4--avl).

```cpp
#include <algorithm>

struct Avl { int key, h = 0; Avl *l = nullptr, *r = nullptr; explicit Avl(int k) : key(k) {} };

int height(Avl* t) { return t ? t->h : -1; }
void update(Avl* t) { t->h = 1 + std::max(height(t->l), height(t->r)); }

Avl* rotateRight(Avl* y) { Avl* x = y->l; y->l = x->r; x->r = y; update(y); update(x); return x; }
Avl* rotateLeft(Avl* x)  { Avl* y = x->r; x->r = y->l; y->l = x; update(x); update(y); return y; }

Avl* insert(Avl* t, int key) {
    if (!t) return new Avl(key);
    if (key < t->key) t->l = insert(t->l, key);
    else if (key > t->key) t->r = insert(t->r, key);
    else return t;
    update(t);
    int balance = height(t->l) - height(t->r);
    if (balance > 1) {                                  // pesa la izquierda
        if (key > t->l->key) t->l = rotateLeft(t->l);   // caso izquierda-derecha
        return rotateRight(t);
    }
    if (balance < -1) {                                 // pesa la derecha
        if (key < t->r->key) t->r = rotateRight(t->r);  // caso derecha-izquierda
        return rotateLeft(t);
    }
    return t;
}
```

### `07/02` — Árbol B [B]

De [`07/02` — BST y árboles balanceados, §7](../07-arboles/02-bst-y-balanceados.md#7--árbol-b).

```cpp
#include <algorithm>
#include <vector>

struct BNode { std::vector<int> keys; std::vector<BNode*> kids; bool leaf = true; };

// ¿Está key en el árbol B? Una lectura de nodo por nivel.
bool bSearch(const BNode* t, int key) {
    while (t) {
        auto it = std::lower_bound(t->keys.begin(), t->keys.end(), key);
        if (it != t->keys.end() && *it == key) return true;
        if (t->leaf) return false;
        t = t->kids[it - t->keys.begin()];            // el hijo entre la clave anterior y *it
    }
    return false;
}
```

### `07/03` — *Treap* [B]

De [`07/03` — Árboles aleatorizados y autoajustables, §3](../07-arboles/03-arboles-aleatorizados.md#3--treap).

```cpp
#include <chrono>
#include <random>
#include <utility>
#include <vector>

// Treap con split/merge sobre arreglos. Nodo 0 = vacío. O(log n) esperado por operación.
struct Treap {
    std::vector<int> key, pri, lc, rc, sz;
    std::mt19937 rng{(unsigned)std::chrono::steady_clock::now().time_since_epoch().count()};
    int root = 0;
    Treap() { key = pri = lc = rc = sz = {0}; }
    int node(int k) {
        key.push_back(k); pri.push_back((int)rng()); lc.push_back(0); rc.push_back(0); sz.push_back(1);
        return (int)key.size() - 1;
    }
    void pull(int t) { sz[t] = 1 + sz[lc[t]] + sz[rc[t]]; }
    // Parte t en (claves < k, claves >= k).
    std::pair<int, int> split(int t, int k) {
        if (!t) return {0, 0};
        if (key[t] < k) { auto [a, b] = split(rc[t], k); rc[t] = a; pull(t); return {t, b}; }
        auto [a, b] = split(lc[t], k); lc[t] = b; pull(t); return {a, t};
    }
    int merge(int a, int b) {                       // todas las claves de a < las de b
        if (!a || !b) return a ? a : b;
        if (pri[a] > pri[b]) { rc[a] = merge(rc[a], b); pull(a); return a; }
        lc[b] = merge(a, lc[b]); pull(b); return b;
    }
    void insert(int k) { auto [a, b] = split(root, k); root = merge(merge(a, node(k)), b); }
    void erase(int k) {                             // borra todas las apariciones de k
        auto [a, b] = split(root, k); auto [m, c] = split(b, k + 1); root = merge(a, c);
    }
    int countLess(int k) { auto [a, b] = split(root, k); int r = sz[a]; root = merge(a, b); return r; }
};
```

### `07/03` — *Treap* implícito [B]

De [`07/03` — Árboles aleatorizados y autoajustables, §4](../07-arboles/03-arboles-aleatorizados.md#4--treap-implícito).

```cpp
// Sobre el Treap de §3, sin usar key: rev[t] marca una inversión pendiente del subárbol.
std::vector<char> rev;                                      // mismo tamaño que key: rev.push_back(0) en node()

void push(Treap& T, int t) {                                // aplica la marca antes de bajar
    if (t && rev[t]) {
        std::swap(T.lc[t], T.rc[t]);
        rev[T.lc[t]] ^= 1; rev[T.rc[t]] ^= 1; rev[t] = 0;
    }
}

// Parte t en (los k primeros, el resto).
std::pair<int, int> splitBySize(Treap& T, int t, int k) {
    if (!t) return {0, 0};
    push(T, t);
    if (T.sz[T.lc[t]] < k) {
        auto [a, b] = splitBySize(T, T.rc[t], k - T.sz[T.lc[t]] - 1);
        T.rc[t] = a; T.pull(t); return {t, b};
    }
    auto [a, b] = splitBySize(T, T.lc[t], k);
    T.lc[t] = b; T.pull(t); return {a, t};
}

int mergeI(Treap& T, int a, int b) {                       // el merge de §3, con push antes de bajar
    if (!a || !b) return a ? a : b;
    push(T, a); push(T, b);
    if (T.pri[a] > T.pri[b]) { T.rc[a] = mergeI(T, T.rc[a], b); T.pull(a); return a; }
    T.lc[b] = mergeI(T, a, T.lc[b]); T.pull(b); return b;
}

void reverseRange(Treap& T, int l, int r) {                 // posiciones [l, r], 0-indexadas
    auto [a, bc] = splitBySize(T, T.root, l);
    auto [b, c] = splitBySize(T, bc, r - l + 1);
    rev[b] ^= 1;
    T.root = mergeI(T, mergeI(T, a, b), c);
}
```

### `07/03` — *Skip list* [B]

De [`07/03` — Árboles aleatorizados y autoajustables, §5](../07-arboles/03-arboles-aleatorizados.md#5--skip-list).

```cpp
#include <vector>

struct SkipNode { int key; std::vector<SkipNode*> next; };

// head tiene levels niveles y clave −∞. ¿Está key? O(log n) esperado.
bool contains(SkipNode* head, int levels, int key) {
    SkipNode* x = head;
    for (int lv = levels - 1; lv >= 0; lv--)
        while (x->next[lv] && x->next[lv]->key < key) x = x->next[lv];
    x = x->next[0];
    return x && x->key == key;
}
```

### `07/04` — *Trie* de palabras [A]

De [`07/04` — *Tries*, §3](../07-arboles/04-tries.md#3--trie-de-palabras).

```cpp
#include <array>
#include <string>
#include <vector>

// Trie de minúsculas: insert y countPrefix en O(L). Nodo 0 = raíz.
struct Trie {
    std::vector<std::array<int, 26>> next{std::array<int, 26>{}};   // next[v][c] = hijo, 0 = no existe
    std::vector<int> pass{0}, end{0};
    void insert(const std::string& w) {
        int v = 0;
        for (char ch : w) {
            int c = ch - 'a';
            if (!next[v][c]) {
                next[v][c] = (int)next.size();
                next.push_back({}); pass.push_back(0); end.push_back(0);
            }
            v = next[v][c]; pass[v]++;
        }
        end[v]++;
    }
    int countPrefix(const std::string& p) const {
        int v = 0;
        for (char ch : p) { v = next[v][ch - 'a']; if (!v) return 0; }
        return pass[v];
    }
};
```

### `07/04` — *Trie* binario [A]

De [`07/04` — *Tries*, §4](../07-arboles/04-tries.md#4--trie-binario).

```cpp
#include <array>
#include <vector>

// Trie binario de enteros no negativos de B bits; borrado con contadores. O(B) por operación.
struct XorTrie {
    static constexpr int B = 30;
    std::vector<std::array<int, 2>> next{std::array<int, 2>{}};
    std::vector<int> cnt{0};
    void add(int x, int d) {                               // d = +1 inserta, −1 borra
        int v = 0;
        for (int b = B - 1; b >= 0; b--) {
            int bit = (x >> b) & 1;
            if (!next[v][bit]) { next[v][bit] = (int)next.size(); next.push_back({0, 0}); cnt.push_back(0); }
            v = next[v][bit]; cnt[v] += d;
        }
    }
    int maxXor(int x) const {                              // pre: el conjunto no está vacío
        int v = 0, res = 0;
        for (int b = B - 1; b >= 0; b--) {
            int want = ((x >> b) & 1) ^ 1, u = next[v][want];
            if (u && cnt[u] > 0) { res |= 1 << b; v = u; } else v = next[v][want ^ 1];
        }
        return res;
    }
};
```

### `07/05` — *Binary lifting* [A]

De [`07/05` — LCA, §3](../07-arboles/05-lca.md#3--binary-lifting).

```cpp
#include <vector>

// Binary lifting. parent[root] = root; order = preorden (cada padre antes que sus hijos).
struct Lca {
    int LOG; std::vector<std::vector<int>> up; std::vector<int> depth;
    Lca(const std::vector<int>& parent, const std::vector<int>& dep, const std::vector<int>& order)
        : depth(dep) {
        int n = parent.size();
        LOG = 1; while ((1 << LOG) < n) LOG++;
        up.assign(LOG, std::vector<int>(n));
        up[0] = parent;
        for (int k = 1; k < LOG; k++)
            for (int v : order) up[k][v] = up[k - 1][up[k - 1][v]];
    }
    int lift(int v, int d) const {                          // ancestro a distancia d
        for (int k = 0; d; k++, d >>= 1) if (d & 1) v = up[k][v];
        return v;
    }
    int lca(int u, int v) const {
        if (depth[u] < depth[v]) std::swap(u, v);
        u = lift(u, depth[u] - depth[v]);
        if (u == v) return u;
        for (int k = LOG - 1; k >= 0; k--)
            if (up[k][u] != up[k][v]) { u = up[k][u]; v = up[k][v]; }
        return up[0][u];
    }
    int dist(int u, int v) const { return depth[u] + depth[v] - 2 * depth[lca(u, v)]; }
};
```

### `07/05` — Euler + RMQ [B]

De [`07/05` — LCA, §4](../07-arboles/05-lca.md#4--euler--rmq).

```cpp
#include <utility>
#include <vector>

// LCA por Euler + tabla dispersa. adj sin pesos, raíz root. O(1) por consulta.
struct EulerLca {
    std::vector<int> first, lg; std::vector<std::vector<std::pair<int, int>>> sp;
    EulerLca(const std::vector<std::vector<int>>& adj, int root) {
        int n = adj.size();
        first.assign(n, -1);
        std::vector<std::pair<int, int>> eul;                // (profundidad, nodo)
        std::vector<int> depth(n, 0), it(n, 0), parent(n, -1), st = {root};
        first[root] = 0; eul.push_back({0, root});
        while (!st.empty()) {
            int v = st.back();
            if (it[v] < (int)adj[v].size()) {
                int w = adj[v][it[v]++];
                if (w == parent[v]) continue;
                parent[w] = v; depth[w] = depth[v] + 1;
                first[w] = eul.size(); eul.push_back({depth[w], w});      // entra en w
                st.push_back(w);
            } else {
                st.pop_back();
                if (!st.empty()) eul.push_back({depth[st.back()], st.back()});   // vuelve al padre
            }
        }
        int m = eul.size();
        lg.assign(m + 1, 0);
        for (int i = 2; i <= m; i++) lg[i] = lg[i / 2] + 1;
        sp.assign(lg[m] + 1, eul);
        for (int k = 1; k <= lg[m]; k++)
            for (int i = 0; i + (1 << k) <= m; i++)
                sp[k][i] = std::min(sp[k - 1][i], sp[k - 1][i + (1 << (k - 1))]);
    }
    int lca(int u, int v) const {
        int l = first[u], r = first[v];
        if (l > r) std::swap(l, r);
        int k = lg[r - l + 1];
        return std::min(sp[k][l], sp[k][r - (1 << k) + 1]).second;
    }
};
```

### `07/06` — *Rerooting* [B]

De [`07/06` — Técnicas sobre árboles, §3](../07-arboles/06-tecnicas-sobre-arboles.md#3--rerooting).

```cpp
#include <vector>

// Suma de distancias desde cada nodo. order = preorden desde la raíz; parent[raíz] = 0. Θ(n).
std::vector<long long> sumOfDistances(int n, const std::vector<int>& order, const std::vector<int>& parent) {
    std::vector<long long> size(n + 1, 1), down(n + 1, 0), ans(n + 1, 0);
    for (int i = n - 1; i > 0; i--) {                 // abajo arriba: preorden al revés
        int v = order[i], p = parent[v];
        size[p] += size[v];
        down[p] += down[v] + size[v];
    }
    ans[order[0]] = down[order[0]];
    for (int i = 1; i < n; i++) {                     // arriba abajo: cada nodo tras su padre
        int v = order[i];
        ans[v] = ans[parent[v]] - size[v] + (n - size[v]);
    }
    return ans;
}
```

### `07/06` — *Small-to-large* [B]

De [`07/06` — Técnicas sobre árboles, §4](../07-arboles/06-tecnicas-sobre-arboles.md#4--small-to-large).

```cpp
#include <set>
#include <utility>
#include <vector>

// Colores distintos de cada subárbol. order = preorden; parent[raíz] = 0. O(n log² n).
std::vector<int> distinctInSubtree(int n, const std::vector<int>& order, const std::vector<int>& parent,
                                   const std::vector<int>& color) {
    std::vector<std::set<int>> s(n + 1);
    std::vector<int> ans(n + 1);
    for (int i = n - 1; i >= 0; i--) {                // preorden al revés: hijos antes que el padre
        int v = order[i];
        s[v].insert(color[v]);
        ans[v] = s[v].size();
        int p = parent[v];
        if (p == 0) continue;
        if (s[p].size() < s[v].size()) std::swap(s[p], s[v]);   // O(1): intercambia punteros internos
        for (int x : s[v]) s[p].insert(x);
        s[v].clear();
    }
    return ans;
}
```

### `07/06` — Descomposición en centroides [B]

De [`07/06` — Técnicas sobre árboles, §5](../07-arboles/06-tecnicas-sobre-arboles.md#5--descomposición-en-centroides).

```cpp
#include <vector>

// Árbol de centroides: cpar[v] = centroide padre de v (−1 en la raíz). O(n log n).
struct CentroidDecomposition {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> sz, par, removed, cpar;
    explicit CentroidDecomposition(const std::vector<std::vector<int>>& g)
        : adj(g), sz(g.size()), par(g.size()), removed(g.size(), 0), cpar(g.size(), -1) {}
    int findCentroid(int root) {
        std::vector<int> order{root}; par[root] = -1;
        for (size_t i = 0; i < order.size(); i++)               // preorden del componente
            for (int w : adj[order[i]])
                if (w != par[order[i]] && !removed[w]) { par[w] = order[i]; order.push_back(w); }
        for (int i = (int)order.size() - 1; i >= 0; i--) {      // tamaños
            int v = order[i]; sz[v] = 1;
            for (int w : adj[v]) if (w != par[v] && !removed[w]) sz[v] += sz[w];
        }
        int total = order.size(), c = root;
        while (true) {                                          // baja hacia el hijo con más de la mitad
            int heavy = -1;
            for (int w : adj[c]) if (w != par[c] && !removed[w] && 2 * sz[w] > total) heavy = w;
            if (heavy < 0) return c;
            c = heavy;
        }
    }
    void build(int root, int parentCentroid) {                   // profundidad de recursión O(log n)
        int c = findCentroid(root);
        cpar[c] = parentCentroid; removed[c] = 1;
        for (int w : adj[c]) if (!removed[w]) build(w, c);
    }
};
```

---

## 🧱 Bloque 08 — Heaps y Union-Find

### `08/01` — El montículo binario [A]

De [`08/01` — Montículo binario, §3](../08-heaps-y-union-find/01-monticulo-binario.md#3--el-montículo-binario).

```cpp
#include <utility>
#include <vector>

// Montículo de mínimos sobre un vector. push y pop en O(log n).
struct MinHeap {
    std::vector<int> a;
    void push(int x) {
        a.push_back(x);
        for (int i = (int)a.size() - 1; i > 0 && a[(i - 1) / 2] > a[i]; i = (i - 1) / 2)
            std::swap(a[i], a[(i - 1) / 2]);                     // siftUp
    }
    int top() const { return a[0]; }
    int pop() {                                                   // pre: no vacío
        int res = a[0];
        a[0] = a.back(); a.pop_back();
        for (int i = 0, n = a.size();;) {                         // siftDown
            int c = 2 * i + 1;
            if (c >= n) break;
            if (c + 1 < n && a[c + 1] < a[c]) c++;
            if (a[i] <= a[c]) break;
            std::swap(a[i], a[c]); i = c;
        }
        return res;
    }
    bool empty() const { return a.empty(); }
};
```

### `08/01` — `heapify` [A]

De [`08/01` — Montículo binario, §4](../08-heaps-y-union-find/01-monticulo-binario.md#4--heapify).

```cpp
#include <utility>
#include <vector>

void siftDown(std::vector<int>& a, int i, int n) {               // montículo de mínimos en a[0, n)
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] < a[c]) c++;
        if (a[i] <= a[c]) return;
        std::swap(a[i], a[c]); i = c;
    }
}

void heapify(std::vector<int>& a) {                                // O(n)
    for (int i = (int)a.size() / 2 - 1; i >= 0; i--) siftDown(a, i, a.size());
}
```

### `08/01` — Cola indexada [B]

De [`08/01` — Montículo binario, §5](../08-heaps-y-union-find/01-monticulo-binario.md#5--cola-indexada).

```cpp
#include <utility>
#include <vector>

// Cola de prioridad indexada (mínimos) sobre índices 0..n−1, con decrease-key.
struct IndexedMinPQ {
    std::vector<long long> key; std::vector<int> heap, pos;       // pos[i] = −1 si i no está
    explicit IndexedMinPQ(int n) : key(n), pos(n, -1) {}
    void swapAt(int a, int b) { std::swap(heap[a], heap[b]); pos[heap[a]] = a; pos[heap[b]] = b; }
    void up(int k) { while (k > 0 && key[heap[(k - 1) / 2]] > key[heap[k]]) { swapAt(k, (k - 1) / 2); k = (k - 1) / 2; } }
    void down(int k) {
        int n = heap.size();
        while (2 * k + 1 < n) {
            int c = 2 * k + 1;
            if (c + 1 < n && key[heap[c + 1]] < key[heap[c]]) c++;
            if (key[heap[k]] <= key[heap[c]]) break;
            swapAt(k, c); k = c;
        }
    }
    bool contains(int i) const { return pos[i] >= 0; }
    void push(int i, long long k) { key[i] = k; pos[i] = heap.size(); heap.push_back(i); up(pos[i]); }
    void decrease(int i, long long k) { key[i] = k; up(pos[i]); }   // pre: k <= key[i]
    int pop() {                                                     // devuelve el índice mínimo
        int top = heap[0];
        swapAt(0, heap.size() - 1); heap.pop_back(); pos[top] = -1;
        if (!heap.empty()) down(0);
        return top;
    }
    bool empty() const { return heap.empty(); }
};
```

### `08/02` — Los `k` mayores [A]

De [`08/02` — Patrones con *heap*, §3](../08-heaps-y-union-find/02-patrones-con-heap.md#3--los-k-mayores).

```cpp
#include <functional>
#include <queue>
#include <vector>

// Los k mayores de a (en orden creciente). Pre: k >= 1. O(n log k) tiempo, O(k) memoria.
std::vector<int> topK(const std::vector<int>& a, int k) {
    std::priority_queue<int, std::vector<int>, std::greater<int>> pq;    // de mínimos
    for (int x : a) {
        if ((int)pq.size() < k) pq.push(x);
        else if (x > pq.top()) { pq.pop(); pq.push(x); }
    }
    std::vector<int> res;
    while (!pq.empty()) { res.push_back(pq.top()); pq.pop(); }
    return res;
}
```

### `08/02` — Mezcla de `k` listas [A]

De [`08/02` — Patrones con *heap*, §4](../08-heaps-y-union-find/02-patrones-con-heap.md#4--mezcla-de-k-listas).

```cpp
#include <functional>
#include <queue>
#include <tuple>
#include <vector>

// Mezcla k listas ordenadas. O(N log k).
std::vector<int> mergeK(const std::vector<std::vector<int>>& lists) {
    using Entry = std::tuple<int, int, int>;                          // (valor, lista, posición)
    std::priority_queue<Entry, std::vector<Entry>, std::greater<Entry>> pq;
    for (int i = 0; i < (int)lists.size(); i++) if (!lists[i].empty()) pq.emplace(lists[i][0], i, 0);
    std::vector<int> out;
    while (!pq.empty()) {
        auto [v, i, j] = pq.top(); pq.pop();
        out.push_back(v);
        if (j + 1 < (int)lists[i].size()) pq.emplace(lists[i][j + 1], i, j + 1);
    }
    return out;
}
```

### `08/02` — La mediana con dos *heaps* [A]

De [`08/02` — Patrones con *heap*, §5](../08-heaps-y-union-find/02-patrones-con-heap.md#5--la-mediana-con-dos-heaps).

```cpp
#include <functional>
#include <queue>
#include <vector>

// Mediana inferior de un flujo. add O(log n), median O(1).
struct RunningMedian {
    std::priority_queue<int> lo;                                            // máximos: mitad menor
    std::priority_queue<int, std::vector<int>, std::greater<int>> hi;      // mínimos: mitad mayor
    void add(int x) {
        if (lo.empty() || x <= lo.top()) lo.push(x); else hi.push(x);
        if (lo.size() > hi.size() + 1) { hi.push(lo.top()); lo.pop(); }
        else if (hi.size() > lo.size()) { lo.push(hi.top()); hi.pop(); }
    }
    int median() const { return lo.top(); }                                // pre: no vacío
};
```

### `08/02` — Borrado perezoso [B]

De [`08/02` — Patrones con *heap*, §6](../08-heaps-y-union-find/02-patrones-con-heap.md#6--borrado-perezoso).

```cpp
#include <functional>
#include <queue>
#include <unordered_map>
#include <vector>

// Montículo de mínimos con borrado perezoso de valores. O(log n) amortizado.
struct LazyHeap {
    std::priority_queue<int, std::vector<int>, std::greater<int>> pq;
    std::unordered_map<int, int> dead;                   // valor → copias por borrar
    int alive = 0;
    void push(int x) { pq.push(x); alive++; }
    void erase(int x) { dead[x]++; alive--; }            // pre: x está vivo
    void clean() {
        while (!pq.empty()) {
            auto it = dead.find(pq.top());
            if (it == dead.end() || it->second == 0) return;
            it->second--; pq.pop();
        }
    }
    int top() { clean(); return pq.top(); }              // pre: alive > 0
    void pop() { clean(); pq.pop(); alive--; }
};
```

### `08/04` — Union-Find [A]

De [`08/04` — Union-Find, §3](../08-heaps-y-union-find/04-union-find.md#3--union-find).

```cpp
#include <numeric>
#include <utility>
#include <vector>

// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
struct DSU {
    std::vector<int> parent, size;
    explicit DSU(int n) : parent(n), size(n, 1) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }   // iterativo
        return x;
    }
    bool unite(int a, int b) {                       // false si ya estaban juntos
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) std::swap(a, b);
        parent[b] = a; size[a] += size[b];
        return true;
    }
    bool same(int a, int b) { return find(a) == find(b); }
};
```

### `08/04` — Con pesos o paridad [B]

De [`08/04` — Union-Find, §4](../08-heaps-y-union-find/04-union-find.md#4--con-pesos-o-paridad).

```cpp
#include <numeric>
#include <vector>

// Union-Find con pesos: d[x] = valor(x) − valor(padre(x)); tras find, relativo a la raíz.
struct WeightedDSU {
    std::vector<int> parent; std::vector<long long> d;
    explicit WeightedDSU(int n) : parent(n), d(n, 0) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) {
        if (parent[x] == x) return x;
        int r = find(parent[x]);                     // recursivo: sin unión por tamaño, hasta n de hondo
        d[x] += d[parent[x]];
        parent[x] = r;
        return r;
    }
    bool unite(int a, int b, long long w) {          // impone valor(b) − valor(a) = w; false si contradice
        int ra = find(a), rb = find(b);
        if (ra == rb) return d[b] - d[a] == w;
        parent[rb] = ra;
        d[rb] = d[a] + w - d[b];
        return true;
    }
    long long diff(int a, int b) { find(a); find(b); return d[b] - d[a]; }   // pre: mismo grupo
};
```

### `08/04` — Con *rollback* y *offline* [B]

De [`08/04` — Union-Find, §5](../08-heaps-y-union-find/04-union-find.md#5--con-rollback-y-offline).

```cpp
#include <numeric>
#include <utility>
#include <vector>

// Union-Find con rollback: sin compresión, unión por tamaño. find O(log n).
struct RollbackDSU {
    std::vector<int> parent, size; std::vector<std::pair<int, int>> history;   // (b colgado, a raíz)
    int components;
    explicit RollbackDSU(int n) : parent(n), size(n, 1), components(n) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) const { while (parent[x] != x) x = parent[x]; return x; }
    bool unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) std::swap(a, b);
        parent[b] = a; size[a] += size[b]; components--;
        history.push_back({b, a});
        return true;
    }
    int snapshot() const { return history.size(); }
    void rollback(int snap) {                        // deshace hasta dejar snap uniones
        while ((int)history.size() > snap) {
            auto [b, a] = history.back(); history.pop_back();
            parent[b] = b; size[a] -= size[b]; components++;
        }
    }
};
```

---

## 🧱 Bloque 09 — Consultas sobre rangos

### `09/01` — La *sparse table* [B]

De [`09/01` — *Sparse table* y RMQ, §3](../09-consultas-sobre-rangos/01-sparse-table.md#3--la-sparse-table).

```cpp
#include <algorithm>
#include <vector>

// Sparse table de mínimos sobre un arreglo estático. Preproceso O(n log n), consulta O(1).
struct SparseTable {
    std::vector<std::vector<int>> st; std::vector<int> lg;
    explicit SparseTable(const std::vector<int>& a) {
        int n = a.size();
        lg.assign(n + 1, 0);
        for (int i = 2; i <= n; i++) lg[i] = lg[i / 2] + 1;          // lg[L] = ⌊log₂ L⌋
        st.assign(lg[n] + 1, std::vector<int>(n));
        st[0] = a;
        for (int k = 1; k <= lg[n]; k++)
            for (int i = 0; i + (1 << k) <= n; i++)
                st[k][i] = std::min(st[k - 1][i], st[k - 1][i + (1 << (k - 1))]);
    }
    int query(int l, int r) const {                                    // mínimo de a[l..r], inclusivo
        int k = lg[r - l + 1];
        return std::min(st[k][l], st[k][r - (1 << k) + 1]);
    }
};
```

### `09/02` — Puntual y rango [A]

De [`09/02` — Fenwick, §3](../09-consultas-sobre-rangos/02-fenwick.md#3--puntual-y-rango).

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

### `09/02` — Rango y puntual [A]

De [`09/02` — Fenwick, §4](../09-consultas-sobre-rangos/02-fenwick.md#4--rango-y-puntual).

```cpp
// Suma v a a[l..r] y lee a[i], sobre un Fenwick de tamaño n + 1 (para r + 1 = n + 1).
void rangeAdd(Fenwick& f, int l, int r, long long v) { f.add(l, v); f.add(r + 1, -v); }
long long pointGet(const Fenwick& f, int i) { return f.prefix(i); }
```

### `09/02` — Rango y rango [B]

De [`09/02` — Fenwick, §5](../09-consultas-sobre-rangos/02-fenwick.md#5--rango-y-rango).

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

### `09/02` — Fenwick 2D [B]

De [`09/02` — Fenwick, §6](../09-consultas-sobre-rangos/02-fenwick.md#6--fenwick-2d).

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

### `09/02` — Búsqueda por bits [B]

De [`09/02` — Fenwick, §7](../09-consultas-sobre-rangos/02-fenwick.md#7--búsqueda-por-bits).

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

### `09/03` — Iterativo [B]

De [`09/03` — Segment tree, §3](../09-consultas-sobre-rangos/03-segment-tree.md#3--iterativo).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Segment tree iterativo de mínimos. Consulta [l, r), actualización puntual. O(log n).
struct SegTree {
    int n; std::vector<int> t;
    static int op(int a, int b) { return std::min(a, b); }
    static constexpr int E = INT_MAX;                          // neutro de la operación
    explicit SegTree(const std::vector<int>& a) : n(a.size()), t(2 * a.size()) {
        for (int i = 0; i < n; i++) t[n + i] = a[i];
        for (int i = n - 1; i > 0; i--) t[i] = op(t[2 * i], t[2 * i + 1]);
    }
    void set(int p, int v) {
        for (t[p += n] = v; p > 1; p >>= 1) t[p >> 1] = op(t[p], t[p ^ 1]);
    }
    int query(int l, int r) const {                            // op de a[l..r−1]
        int resl = E, resr = E;
        for (l += n, r += n; l < r; l >>= 1, r >>= 1) {
            if (l & 1) resl = op(resl, t[l++]);
            if (r & 1) resr = op(t[--r], resr);
        }
        return op(resl, resr);
    }
};
```

### `09/03` — Recursivo [B]

De [`09/03` — Segment tree, §4](../09-consultas-sobre-rangos/03-segment-tree.md#4--recursivo).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Segment tree recursivo de máximos con descenso. Nodos 1..4n; tramos [lo, hi).
struct MaxTree {
    int n; std::vector<int> t;
    explicit MaxTree(const std::vector<int>& a) : n(a.size()), t(4 * a.size(), INT_MIN) { build(1, 0, n, a); }
    void build(int v, int lo, int hi, const std::vector<int>& a) {
        if (hi - lo == 1) { t[v] = a[lo]; return; }
        int mid = (lo + hi) / 2;
        build(2 * v, lo, mid, a); build(2 * v + 1, mid, hi, a);
        t[v] = std::max(t[2 * v], t[2 * v + 1]);
    }
    void set(int v, int lo, int hi, int p, int x) {
        if (hi - lo == 1) { t[v] = x; return; }
        int mid = (lo + hi) / 2;
        if (p < mid) set(2 * v, lo, mid, p, x); else set(2 * v + 1, mid, hi, p, x);
        t[v] = std::max(t[2 * v], t[2 * v + 1]);
    }
    int query(int v, int lo, int hi, int l, int r) const {
        if (r <= lo || hi <= l) return INT_MIN;                     // fuera
        if (l <= lo && hi <= r) return t[v];                         // dentro
        int mid = (lo + hi) / 2;
        return std::max(query(2 * v, lo, mid, l, r), query(2 * v + 1, mid, hi, l, r));
    }
    // Primer índice j >= i con a[j] >= x, o −1. O(log n): solo baja por nodos que pueden tener la respuesta.
    int firstAtLeast(int v, int lo, int hi, int i, int x) const {
        if (hi <= i || t[v] < x) return -1;
        if (hi - lo == 1) return lo;
        int mid = (lo + hi) / 2;
        int res = firstAtLeast(2 * v, lo, mid, i, x);
        return res != -1 ? res : firstAtLeast(2 * v + 1, mid, hi, i, x);
    }
};
// Uso: MaxTree st(a); st.set(1, 0, st.n, p, x); st.query(1, 0, st.n, l, r); st.firstAtLeast(1, 0, st.n, i, x);
```

### `09/03` — *Lazy propagation* [B]

De [`09/03` — Segment tree, §5](../09-consultas-sobre-rangos/03-segment-tree.md#5--lazy-propagation).

```cpp
#include <vector>

// Lazy: suma v a a[l..r) y suma de a[l..r). Nodos 1..4n; tramos [lo, hi). O(log n).
struct LazySum {
    int n; std::vector<long long> sum, add;
    explicit LazySum(int n) : n(n), sum(4 * n, 0), add(4 * n, 0) {}
    void apply(int v, int lo, int hi, long long x) { sum[v] += x * (hi - lo); add[v] += x; }
    void push(int v, int lo, int hi) {
        if (add[v] == 0) return;
        int mid = (lo + hi) / 2;
        apply(2 * v, lo, mid, add[v]); apply(2 * v + 1, mid, hi, add[v]);
        add[v] = 0;
    }
    void update(int v, int lo, int hi, int l, int r, long long x) {
        if (r <= lo || hi <= l) return;
        if (l <= lo && hi <= r) { apply(v, lo, hi, x); return; }
        push(v, lo, hi);
        int mid = (lo + hi) / 2;
        update(2 * v, lo, mid, l, r, x); update(2 * v + 1, mid, hi, l, r, x);
        sum[v] = sum[2 * v] + sum[2 * v + 1];
    }
    long long query(int v, int lo, int hi, int l, int r) {
        if (r <= lo || hi <= l) return 0;
        if (l <= lo && hi <= r) return sum[v];
        push(v, lo, hi);
        int mid = (lo + hi) / 2;
        return query(2 * v, lo, mid, l, r) + query(2 * v + 1, mid, hi, l, r);
    }
};
// Uso: LazySum st(n); st.update(1, 0, n, l, r, x); st.query(1, 0, n, l, r);
```

### `09/05` — Descomposición en raíz [B]

De [`09/05` — Raíz cuadrada y Mo, §3](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#3--descomposición-en-raíz).

```cpp
#include <cmath>
#include <vector>

// Descomposición en raíz para sumas: set puntual O(1), suma de [l, r] en O(√n).
struct SqrtSum {
    int n, B; std::vector<long long> a, block;
    explicit SqrtSum(const std::vector<long long>& v) : n(v.size()), a(v) {
        B = std::max(1, (int)std::sqrt(n));
        block.assign((n + B - 1) / B, 0);
        for (int i = 0; i < n; i++) block[i / B] += a[i];
    }
    void set(int p, long long x) { block[p / B] += x - a[p]; a[p] = x; }
    long long query(int l, int r) const {                    // suma de a[l..r], inclusivo
        long long s = 0;
        int bl = l / B, br = r / B;
        if (bl == br) { for (int i = l; i <= r; i++) s += a[i]; return s; }
        for (int i = l; i < (bl + 1) * B; i++) s += a[i];     // trozo del primer bloque
        for (int b = bl + 1; b < br; b++) s += block[b];      // bloques enteros
        for (int i = br * B; i <= r; i++) s += a[i];          // trozo del último bloque
        return s;
    }
};
```

### `09/05` — Mo [B]

De [`09/05` — Raíz cuadrada y Mo, §4](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#4--mo).

```cpp
#include <algorithm>
#include <cmath>
#include <vector>

// Mo: distintos en cada [l, r]. Valores comprimidos a 0..V−1. O((n + q)√n).
std::vector<int> moDistinct(const std::vector<int>& a, int V, const std::vector<std::pair<int, int>>& qs) {
    int n = a.size(), q = qs.size(), B = std::max(1, (int)(n / std::sqrt((double)std::max(q, 1))));
    std::vector<int> order(q), cnt(V, 0), ans(q);
    for (int i = 0; i < q; i++) order[i] = i;
    std::sort(order.begin(), order.end(), [&](int x, int y) {
        int bx = qs[x].first / B, by = qs[y].first / B;
        if (bx != by) return bx < by;
        return (bx & 1) ? qs[x].second > qs[y].second : qs[x].second < qs[y].second;   // zigzag
    });
    int curL = 0, curR = -1, distinct = 0;
    auto add = [&](int i) { if (cnt[a[i]]++ == 0) distinct++; };
    auto remove = [&](int i) { if (--cnt[a[i]] == 0) distinct--; };
    for (int id : order) {
        auto [l, r] = qs[id];
        while (curR < r) add(++curR);
        while (curL > l) add(--curL);
        while (curR > r) remove(curR--);
        while (curL < l) remove(curL++);
        ans[id] = distinct;
    }
    return ans;
}
```

### `09/05` — Consultas *offline* [B]

De [`09/05` — Raíz cuadrada y Mo, §5](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#5--consultas-offline).

```cpp
#include <algorithm>
#include <numeric>
#include <unordered_map>
#include <vector>

// Distintos en [l, r] offline: ordenar por r y Fenwick sobre la última aparición. O((n + q) log n).
std::vector<int> offlineDistinct(const std::vector<int>& a, const std::vector<std::pair<int, int>>& qs) {
    int n = a.size(), q = qs.size();
    std::vector<int> order(q), ans(q);
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&](int x, int y) { return qs[x].second < qs[y].second; });
    Fenwick f(n);                                            // el de 09/02, índices 1..n
    std::unordered_map<int, int> last;
    int k = 0;
    for (int i = 0; i < n; i++) {
        auto it = last.find(a[i]);
        if (it != last.end()) f.add(it->second + 1, -1);
        last[a[i]] = i; f.add(i + 1, 1);
        while (k < q && qs[order[k]].second == i) {
            int id = order[k++];
            ans[id] = f.range(qs[id].first + 1, i + 1);
        }
    }
    return ans;
}
```

---

## 🧱 Bloque 10 — Búsqueda completa y divide y vencerás

### `10/01` — Recursión y pila de llamadas [A]

De [`10/01` — Recursión, §3](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#3--recursión-y-pila-de-llamadas).

```cpp
#include <cstdio>

// Mueve n discos de 'from' a 'to' usando 'via'. Θ(2ⁿ) tiempo, Θ(n) pila.
void hanoi(int n, char from, char to, char via) {
    if (n == 0) return;                       // caso base: nada que mover
    hanoi(n - 1, from, via, to);              // aparta los n − 1 de arriba
    std::printf("%c %c\n", from, to);         // mueve el disco mayor
    hanoi(n - 1, via, to, from);              // los pone encima
}
```

### `10/01` — Paso a iterativo [A]

De [`10/01` — Recursión, §4](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#4--paso-a-iterativo).

```cpp
#include <cstdio>
#include <vector>

struct Frame { int n; char from, to, via; int stage; };

// Hanoi iterativo: simula la pila de llamadas con marcos explícitos. Θ(2ⁿ) tiempo, Θ(n) memoria.
void hanoiIterative(int n, char from, char to, char via) {
    std::vector<Frame> stack;
    stack.push_back({n, from, to, via, 0});
    while (!stack.empty()) {
        Frame& f = stack.back();
        if (f.n == 0 || f.stage == 2) { stack.pop_back(); continue; }     // base o terminado: vuelve
        if (f.stage == 0) {                                                 // primera llamada
            f.stage = 1;
            Frame child{f.n - 1, f.from, f.via, f.to, 0};
            stack.push_back(child);                                         // f puede invalidarse aquí
        } else {                                                            // etapa 1: mueve y segunda llamada
            std::printf("%c %c\n", f.from, f.to);
            f.stage = 2;
            Frame child{f.n - 1, f.via, f.to, f.from, 0};
            stack.push_back(child);
        }
    }
}
```

### `10/02` — Subconjuntos con máscaras de bits [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §3](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#3--subconjuntos-con-máscaras-de-bits).

```cpp
#include <vector>

// sum[m] = suma de los a[i] con el bit i encendido en m. Θ(2ⁿ) tiempo y memoria. n ≤ ~25.
std::vector<long long> subsetSums(const std::vector<long long>& a) {
    int n = (int)a.size();
    std::vector<long long> sum(1 << n, 0);
    for (int m = 1; m < (1 << n); m++) {
        int low = __builtin_ctz(m);                 // índice del bit más bajo
        sum[m] = sum[m & (m - 1)] + a[low];         // m & (m − 1) apaga ese bit
    }
    return sum;
}
```

### `10/02` — Permutaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §4](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#4--permutaciones).

```cpp
#include <algorithm>
#include <vector>

// Iterativa: recorre las permutaciones distintas en orden lexicográfico. Θ(n!) llamadas en total.
void forEachPermutation(std::vector<int> a) {
    std::sort(a.begin(), a.end());                         // hay que empezar por la primera
    do {
        // procesar a
    } while (std::next_permutation(a.begin(), a.end()));
}

// Recursiva: pos es la siguiente posición libre; used marca los índices ya colocados.
void permute(const std::vector<int>& a, std::vector<int>& cur, std::vector<bool>& used) {
    if (cur.size() == a.size()) { /* procesar cur */ return; }
    for (size_t i = 0; i < a.size(); i++) {
        if (used[i]) continue;
        used[i] = true; cur.push_back(a[i]);
        permute(a, cur, used);
        cur.pop_back(); used[i] = false;                   // deshace la elección
    }
}
```

### `10/02` — Combinaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §5](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#5--combinaciones).

```cpp
#include <vector>

// Todas las combinaciones de k índices de [0, n), en orden lexicográfico. Θ(C(n, k) · k).
void combine(int n, int k, int start, std::vector<int>& cur) {
    if ((int)cur.size() == k) { /* procesar cur */ return; }
    for (int i = start; n - i >= k - (int)cur.size(); i++) {   // poda: quedan huecos suficientes
        cur.push_back(i);
        combine(n, k, i + 1, cur);
        cur.pop_back();
    }
}
```

### `10/03` — *Backtracking* [A]

De [`10/03` — *Backtracking* con poda y ramificación y poda, §3](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#3--backtracking).

```cpp
#include <vector>

// Cuenta los subconjuntos (por posición) de a con suma exacta 'rem'. a ordenado ascendente,
// pesos positivos; suffix[j] = a[j] + … + a[n−1]. Exponencial en el caso peor.
long long countSubsets(const std::vector<long long>& a, const std::vector<long long>& suffix,
                       int start, long long rem) {
    if (rem == 0) return 1;                                   // el parcial ya suma target
    long long count = 0;
    for (int j = start; j < (int)a.size(); j++) {
        if (a[j] > rem) break;                                // poda: los siguientes son mayores
        if (suffix[j] < rem) break;                           // poda: ni sumando todo llega
        count += countSubsets(a, suffix, j + 1, rem - a[j]);  // elegir a[j]; 'rem' se deshace solo
    }
    return count;
}
```

### `10/03` — Ramificación y poda [B]

De [`10/03` — *Backtracking* con poda y ramificación y poda, §4](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#4--ramificación-y-poda).

```cpp
#include <algorithm>
#include <vector>

struct Item { long long w, v; };

// Pre: items ordenados por v/w descendente. Cota optimista: mochila fraccionaria del resto.
double bound(const std::vector<Item>& it, int i, long long cap, long long value) {
    double b = (double)value;
    for (; i < (int)it.size(); i++) {
        if (it[i].w <= cap) { cap -= it[i].w; b += it[i].v; }
        else { b += (double)it[i].v * cap / it[i].w; break; }
    }
    return b;
}

void branchAndBound(const std::vector<Item>& it, int i, long long cap, long long value, long long& best) {
    best = std::max(best, value);
    if (i == (int)it.size() || bound(it, i, cap, value) <= (double)best) return;   // poda por cota
    if (it[i].w <= cap) branchAndBound(it, i + 1, cap - it[i].w, value + it[i].v, best);  // tomar
    branchAndBound(it, i + 1, cap, value, best);                                          // dejar
}
```

### `10/04` — *Meet in the middle* [B]

De [`10/04` — *Meet in the middle*, IDDFS y *Dancing Links*, §3](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md#3--meet-in-the-middle).

```cpp
#include <algorithm>
#include <vector>

// Todas las sumas de subconjuntos de a[from..to), en un vector de 2^(to−from) posiciones.
std::vector<long long> halfSums(const std::vector<long long>& a, int from, int to) {
    int k = to - from;
    std::vector<long long> sums(1 << k, 0);
    for (int m = 1; m < (1 << k); m++)
        sums[m] = sums[m & (m - 1)] + a[from + __builtin_ctz(m)];
    return sums;
}

// Mayor suma de un subconjunto de a que no pasa de S (0 si solo el vacío). O(2^(n/2) · n). n ≤ ~44.
long long bestSumAtMost(const std::vector<long long>& a, long long S) {
    int n = (int)a.size(), mid = n / 2;
    std::vector<long long> left = halfSums(a, 0, mid), right = halfSums(a, mid, n);
    std::sort(right.begin(), right.end());
    long long best = 0;
    for (long long x : left) {
        if (x > S) continue;
        auto it = std::upper_bound(right.begin(), right.end(), S - x);   // primera > S − x
        best = std::max(best, x + *std::prev(it));                         // right[0] = 0 siempre cabe
    }
    return best;
}
```

### `10/04` — IDDFS [B]

De [`10/04` — *Meet in the middle*, IDDFS y *Dancing Links*, §4](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md#4--iddfs).

```cpp
#include <vector>

// IDDFS genérico: true si hay una meta a profundidad ≤ limit desde 'state'.
// isGoal, moves, apply, undo y lowerBound los define el problema.
template <class State, class Problem>
bool depthLimited(State& state, int depth, int limit, Problem& p) {
    if (p.isGoal(state)) return true;
    if (depth + p.lowerBound(state) > limit) return false;    // poda: no llega dentro del límite
    for (auto mv : p.moves(state)) {
        p.apply(state, mv);
        if (depthLimited(state, depth + 1, limit, p)) return true;   // el estado queda con la solución
        p.undo(state, mv);
    }
    return false;
}

template <class State, class Problem>
int iddfs(State& start, Problem& p, int maxDepth) {
    for (int limit = 0; limit <= maxDepth; limit++)
        if (depthLimited(start, 0, limit, p)) return limit;   // la primera es la más corta
    return -1;
}
```

### `10/05` — El esquema [A]

De [`10/05` — Divide y vencerás, §3](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#3--el-esquema).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Suma máxima de un subarreglo no vacío de a[lo, hi). Θ(n log n). Pre: lo < hi.
long long maxSubarray(const std::vector<long long>& a, int lo, int hi) {
    if (hi - lo == 1) return a[lo];                          // caso base: un elemento
    int mid = lo + (hi - lo) / 2;
    long long best = std::max(maxSubarray(a, lo, mid), maxSubarray(a, mid, hi));
    long long sum = 0, leftBest = LLONG_MIN, rightBest = LLONG_MIN;
    for (int i = mid - 1; i >= lo; i--) { sum += a[i]; leftBest = std::max(leftBest, sum); }
    sum = 0;
    for (int i = mid; i < hi; i++) { sum += a[i]; rightBest = std::max(rightBest, sum); }
    return std::max(best, leftBest + rightBest);             // el que cruza el centro
}
```

### `10/05` — Par de puntos más cercano [B]

De [`10/05` — Divide y vencerás, §4](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#4--par-de-puntos-más-cercano).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

struct Pt { long long x, y; };

// pts[lo, hi) ordenados por x al entrar; al salir quedan ordenados por y. Devuelve la mínima d².
long long closest(std::vector<Pt>& pts, int lo, int hi, std::vector<Pt>& buf) {
    if (hi - lo <= 1) return LLONG_MAX;
    int mid = lo + (hi - lo) / 2;
    long long midX = pts[mid].x;
    long long d = std::min(closest(pts, lo, mid, buf), closest(pts, mid, hi, buf));
    std::inplace_merge(pts.begin() + lo, pts.begin() + mid, pts.begin() + hi,
                       [](const Pt& a, const Pt& b) { return a.y < b.y; });   // ahora por y
    int k = 0;
    for (int i = lo; i < hi; i++) {
        long long dx = pts[i].x - midX;
        if (dx * dx >= d) continue;                                  // fuera de la franja
        for (int j = k - 1; j >= 0; j--) {                           // los de la franja con y menor
            long long dy = pts[i].y - buf[j].y;
            if (dy * dy >= d) break;                                 // como mucho 7 vueltas
            long long ex = pts[i].x - buf[j].x;
            d = std::min(d, ex * ex + dy * dy);
        }
        buf[k++] = pts[i];
    }
    return d;
}
// Uso: ordenar pts por x; std::vector<Pt> buf(n); long long d2 = closest(pts, 0, n, buf);
```

### `10/05` — Karatsuba [B]

De [`10/05` — Divide y vencerás, §5](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#5--karatsuba).

```cpp
#include <vector>

using Poly = std::vector<long long>;

// Producto de polinomios de igual tamaño n (potencia de 2). Θ(n^1,585).
Poly karatsuba(const Poly& a, const Poly& b) {
    int n = (int)a.size();
    Poly res(2 * n, 0);
    if (n <= 32) {                                          // caso base: el escolar es más rápido
        for (int i = 0; i < n; i++)
            for (int j = 0; j < n; j++) res[i + j] += a[i] * b[j];
        return res;
    }
    int h = n / 2;
    Poly a0(a.begin(), a.begin() + h), a1(a.begin() + h, a.end());
    Poly b0(b.begin(), b.begin() + h), b1(b.begin() + h, b.end());
    Poly z0 = karatsuba(a0, b0), z2 = karatsuba(a1, b1);
    for (int i = 0; i < h; i++) { a0[i] += a1[i]; b0[i] += b1[i]; }   // (a0 + a1) y (b0 + b1)
    Poly z1 = karatsuba(a0, b0);
    for (int i = 0; i < n; i++) z1[i] -= z0[i] + z2[i];
    for (int i = 0; i < n; i++) { res[i] += z0[i]; res[i + h] += z1[i]; res[i + n] += z2[i]; }
    return res;
}
```

### `10/05` — Exponenciación rápida [A]

De [`10/05` — Divide y vencerás, §6](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#6--exponenciación-rápida).

```cpp
// aⁿ mod m, con 1 ≤ m ≤ 2³¹ para que (m − 1)² quepa en 64 bits. Θ(log n).
long long powMod(long long a, long long n, long long m) {
    long long result = 1 % m, base = a % m;
    if (base < 0) base += m;
    while (n > 0) {
        if (n & 1) result = result * base % m;       // el bit bajo de n está encendido
        base = base * base % m;
        n >>= 1;
    }
    return result;
}
```

### `10/06` — Minimax [B]

De [`10/06` — Juegos y búsqueda adversarial, §3](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md#3--minimax).

```cpp
#include <algorithm>
#include <vector>

// Mejor diferencia (propio − rival) para quien mueve con las monedas a[i..j]. Θ(n²) estados.
long long negamax(const std::vector<long long>& a, int i, int j,
                  std::vector<std::vector<long long>>& memo, std::vector<std::vector<bool>>& seen) {
    if (i > j) return 0;                                         // terminal: no quedan monedas
    if (seen[i][j]) return memo[i][j];
    long long takeLeft  = a[i] - negamax(a, i + 1, j, memo, seen);   // el rival juega lo mejor para él
    long long takeRight = a[j] - negamax(a, i, j - 1, memo, seen);
    seen[i][j] = true;
    return memo[i][j] = std::max(takeLeft, takeRight);
}
// Lo que se lleva el primero: (suma + negamax(a, 0, n − 1, …)) / 2
```

### `10/06` — Alfa-beta [B]

De [`10/06` — Juegos y búsqueda adversarial, §4](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md#4--alfa-beta).

```cpp
#include <algorithm>
#include <climits>

// Negamax con alfa-beta. Devuelve el valor para el jugador que mueve en 'state', a profundidad ≤ depth.
// Game define: terminal, evaluate (para quien mueve), moves, play y undo.
template <class Game>
int alphaBeta(Game& g, int depth, int alpha, int beta) {
    if (depth == 0 || g.terminal()) return g.evaluate();
    int best = INT_MIN + 1;                                     // + 1: así −best no desborda
    for (auto mv : g.moves()) {                                 // mejor ordenados de más a menos prometedor
        g.play(mv);
        int value = -alphaBeta(g, depth - 1, -beta, -alpha);    // la ventana se invierte para el rival
        g.undo(mv);
        best = std::max(best, value);
        alpha = std::max(alpha, value);
        if (alpha >= beta) break;                               // poda: el rival no permitirá esto
    }
    return best;
}
// Llamada inicial: alphaBeta(g, D, INT_MIN + 1, INT_MAX)
```

---

## 🧱 Bloque 11 — Voraces

### `11/02` — Selección de actividades [A]

De [`11/02` — Intervalos, §3](../11-voraces/02-intervalos.md#3--selección-de-actividades).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Máximo número de intervalos [s, f) disjuntos. Θ(n log n).
int maxDisjoint(std::vector<std::pair<long long, long long>> iv) {
    std::sort(iv.begin(), iv.end(), [](const auto& a, const auto& b) { return a.second < b.second; });
    int count = 0;
    long long lastEnd = LLONG_MIN;
    for (auto [s, f] : iv)
        if (s >= lastEnd) { count++; lastEnd = f; }      // semiabierto: empezar al terminar vale
    return count;
}
```

### `11/02` — Cubrimiento con puntos [A]

De [`11/02` — Intervalos, §4](../11-voraces/02-intervalos.md#4--cubrimiento-con-puntos).

```cpp
#include <algorithm>
#include <climits>
#include <vector>

// Mínimo de puntos que pinchan todos los intervalos cerrados [s, f]. Θ(n log n).
int minPoints(std::vector<std::pair<long long, long long>> iv) {
    std::sort(iv.begin(), iv.end(), [](const auto& a, const auto& b) { return a.second < b.second; });
    int count = 0;
    long long last = LLONG_MIN;                          // último punto colocado
    for (auto [s, f] : iv)
        if (s > last) { count++; last = f; }             // no lo pincha: punto en su final
    return count;
}
```

### `11/02` — Mezcla [A]

De [`11/02` — Intervalos, §5](../11-voraces/02-intervalos.md#5--mezcla).

```cpp
#include <algorithm>
#include <vector>

// Unión de intervalos cerrados [s, f], como lista ordenada de disjuntos. Θ(n log n).
std::vector<std::pair<long long, long long>> mergeIntervals(std::vector<std::pair<long long, long long>> iv) {
    std::sort(iv.begin(), iv.end());                              // por inicio
    std::vector<std::pair<long long, long long>> out;
    for (auto [s, f] : iv) {
        if (!out.empty() && s <= out.back().second)
            out.back().second = std::max(out.back().second, f);   // se une al bloque
        else
            out.push_back({s, f});                                // abre bloque nuevo
    }
    return out;
}
```

### `11/02` — Mínimo de salas [A]

De [`11/02` — Intervalos, §6](../11-voraces/02-intervalos.md#6--mínimo-de-salas).

```cpp
#include <algorithm>
#include <vector>

// Mínimo de salas para reuniones [s, f) (profundidad). Θ(n log n).
int minRooms(const std::vector<std::pair<long long, long long>>& iv) {
    std::vector<long long> starts, ends;
    for (auto [s, f] : iv) { starts.push_back(s); ends.push_back(f); }
    std::sort(starts.begin(), starts.end());
    std::sort(ends.begin(), ends.end());
    int rooms = 0, best = 0;
    for (size_t i = 0, j = 0; i < starts.size(); i++) {
        while (j < ends.size() && ends[j] <= starts[i]) { j++; rooms--; }   // semiabierto: libera antes
        rooms++;
        best = std::max(best, rooms);
    }
    return best;
}
```

### `11/03` — Planificación con plazos [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §3](../11-voraces/03-plazos-huffman-y-monedas.md#3--planificación-con-plazos).

```cpp
#include <algorithm>
#include <functional>
#include <queue>
#include <vector>

// Máximo beneficio de tareas unitarias (plazo, beneficio) que acaban a tiempo. Θ(n log n).
long long maxProfit(std::vector<std::pair<long long, long long>> jobs) {
    std::sort(jobs.begin(), jobs.end());                                  // por plazo
    std::priority_queue<long long, std::vector<long long>, std::greater<>> kept;   // min-heap
    long long total = 0;
    for (auto [d, p] : jobs) {
        kept.push(p); total += p;
        if ((long long)kept.size() > d) { total -= kept.top(); kept.pop(); }   // suelta la peor
    }
    return total;
}
```

### `11/03` — Huffman [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §4](../11-voraces/03-plazos-huffman-y-monedas.md#4--huffman).

```cpp
#include <functional>
#include <queue>
#include <vector>

// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman. Θ(n log n).
long long huffmanCost(const std::vector<long long>& freq) {
    std::priority_queue<long long, std::vector<long long>, std::greater<>> pq(freq.begin(), freq.end());
    long long cost = 0;
    while (pq.size() > 1) {
        long long a = pq.top(); pq.pop();
        long long b = pq.top(); pq.pop();
        cost += a + b;                         // el nodo interno nuevo
        pq.push(a + b);
    }
    return cost;                               // 0 con un solo símbolo
}
```

### `11/03` — Mochila fraccionaria [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §5](../11-voraces/03-plazos-huffman-y-monedas.md#5--mochila-fraccionaria).

```cpp
#include <algorithm>
#include <vector>

// Valor máximo con materiales divisibles (peso, valor). Θ(n log n).
double fractionalKnapsack(std::vector<std::pair<long long, long long>> items, long long cap) {
    std::sort(items.begin(), items.end(), [](const auto& a, const auto& b) {
        return a.second * b.first > b.second * a.first;                   // razón decreciente, sin dividir
    });
    double value = 0;
    for (auto [w, v] : items) {
        if (cap == 0) break;
        long long take = std::min(w, cap);
        value += (double)v * take / w;
        cap -= take;
    }
    return value;
}
```

### `11/03` — Monedas canónicas [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §6](../11-voraces/03-plazos-huffman-y-monedas.md#6--monedas-canónicas).

```cpp
#include <algorithm>
#include <vector>

// Monedas del voraz para x; coins ordenadas de mayor a menor, con la de 1. O(k).
long long greedyCoins(const std::vector<long long>& coins, long long x) {
    long long count = 0;
    for (long long c : coins) { count += x / c; x %= c; }
    return count;
}

// ¿Es canónico? Compara el voraz con la DP hasta la suma de las dos mayores (Kozen y Zaks).
bool isCanonical(const std::vector<long long>& coins) {           // de mayor a menor
    if (coins.size() < 3) return true;
    int limit = (int)(coins[0] + coins[1]);
    std::vector<long long> best(limit, 0);
    for (int x = 1; x < limit; x++) {
        best[x] = x;                                               // todo con monedas de 1
        for (long long c : coins) if (c <= x) best[x] = std::min(best[x], best[x - c] + 1);
        if (greedyCoins(coins, x) > best[x]) return false;         // x es contraejemplo
    }
    return true;
}
```

---

## 🧱 Bloque 12 — DP clásica

### `12/01` — Memoización [A]

De [`12/01` — De la recursión a la tabla, §3](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#3--memoización).

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

// Formas de llegar al escalón i con pasos de 1, 2 o 3. memo[i] = −1 si no se ha calculado.
long long ways(int i, std::vector<long long>& memo) {
    if (i < 0) return 0;                                  // se pasó: ninguna forma
    if (i == 0) return 1;                                 // caso base: ya está arriba
    if (memo[i] != -1) return memo[i];                    // ¿calculado?
    return memo[i] = (ways(i - 1, memo) + ways(i - 2, memo) + ways(i - 3, memo)) % MOD;
}
// std::vector<long long> memo(n + 1, -1); ways(n, memo);
```

### `12/01` — Tabulación [A]

De [`12/01` — De la recursión a la tabla, §4](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#4--tabulación).

```cpp
#include <vector>

// Formas de subir n escalones con pasos de 1, 2 o 3, sin pisar los rotos. Θ(n) tiempo y memoria.
long long waysTable(int n, const std::vector<bool>& broken) {
    const long long MOD = 1'000'000'007;
    std::vector<long long> dp(n + 1, 0);
    dp[0] = 1;                                            // caso base
    for (int i = 1; i <= n; i++) {
        if (broken[i]) continue;                          // dp[i] queda en 0
        for (int step = 1; step <= 3 && step <= i; step++) dp[i] = (dp[i] + dp[i - step]) % MOD;
    }
    return dp[n];
}
```

### `12/01` — Reconstrucción [A]

De [`12/01` — De la recursión a la tabla, §5](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#5--reconstrucción).

```cpp
#include <algorithm>
#include <vector>

// Menor número de operaciones +1, ×2, ×3 de 1 a n, y la secuencia. Θ(n).
std::vector<int> opsPath(int n) {
    std::vector<int> dp(n + 1, 0), parent(n + 1, 0);
    for (int x = 2; x <= n; x++) {
        dp[x] = dp[x - 1] + 1; parent[x] = x - 1;
        if (x % 2 == 0 && dp[x / 2] + 1 < dp[x]) { dp[x] = dp[x / 2] + 1; parent[x] = x / 2; }
        if (x % 3 == 0 && dp[x / 3] + 1 < dp[x]) { dp[x] = dp[x / 3] + 1; parent[x] = x / 3; }
    }
    std::vector<int> path;
    for (int x = n; x != 1; x = parent[x]) path.push_back(x);  // se sigue la cadena de padres
    path.push_back(1);
    std::reverse(path.begin(), path.end());
    return path;                                               // dp[n] = path.size() − 1
}
```

### `12/02` — Escaleras y robos [A]

De [`12/02` — DP lineal y LIS, §3](../12-dp-clasica/02-dp-lineal-y-lis.md#3--escaleras-y-robos).

```cpp
#include <algorithm>
#include <vector>

// Mayor suma de elementos sin coger dos consecutivos. Θ(n), O(1) memoria.
long long maxNonAdjacent(const std::vector<long long>& a) {
    long long take = 0, skip = 0;                  // mejores sumas hasta el anterior
    for (long long x : a) {
        long long newTake = skip + x;              // coger x obliga a no haber cogido el anterior
        skip = std::max(skip, take);
        take = newTake;
    }
    return std::max(take, skip);
}
```

### `12/02` — LIS en O(n²) [A]

De [`12/02` — DP lineal y LIS, §4](../12-dp-clasica/02-dp-lineal-y-lis.md#4--lis-en-on).

```cpp
#include <algorithm>
#include <vector>

// Una LIS estrictamente creciente, por índices. Θ(n²).
std::vector<int> lisQuadratic(const std::vector<long long>& a) {
    int n = (int)a.size(), best = -1;
    std::vector<int> d(n, 1), parent(n, -1);
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < i; j++)
            if (a[j] < a[i] && d[j] + 1 > d[i]) { d[i] = d[j] + 1; parent[i] = j; }
        if (best < 0 || d[i] > d[best]) best = i;
    }
    std::vector<int> seq;
    for (int i = best; i != -1; i = parent[i]) seq.push_back(i);
    std::reverse(seq.begin(), seq.end());
    return seq;
}
```

### `12/02` — LIS en O(n log n) [A]

De [`12/02` — DP lineal y LIS, §5](../12-dp-clasica/02-dp-lineal-y-lis.md#5--lis-en-on-log-n).

```cpp
#include <algorithm>
#include <vector>

// Una LIS estrictamente creciente, por índices. Θ(n log n).
std::vector<int> lisFast(const std::vector<long long>& a) {
    int n = (int)a.size();
    std::vector<long long> tails;                  // tails[k]: menor final de longitud k + 1
    std::vector<int> tailIdx, parent(n, -1);       // índice de ese final y padres
    for (int i = 0; i < n; i++) {
        int k = std::lower_bound(tails.begin(), tails.end(), a[i]) - tails.begin();  // estricta
        if (k == (int)tails.size()) { tails.push_back(a[i]); tailIdx.push_back(i); }
        else { tails[k] = a[i]; tailIdx[k] = i; }
        if (k > 0) parent[i] = tailIdx[k - 1];     // el final de longitud k que extiende
    }
    std::vector<int> seq;
    for (int i = tailIdx.empty() ? -1 : tailIdx.back(); i != -1; i = parent[i]) seq.push_back(i);
    std::reverse(seq.begin(), seq.end());
    return seq;
}
```

### `12/03` — Mochila 0/1 [A]

De [`12/03` — Mochilas, §3](../12-dp-clasica/03-mochilas.md#3--mochila-01).

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

### `12/03` — Una fila de memoria [A]

De [`12/03` — Mochilas, §4](../12-dp-clasica/03-mochilas.md#4--una-fila-de-memoria).

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

### `12/03` — Mochila ilimitada [A]

De [`12/03` — Mochilas, §5](../12-dp-clasica/03-mochilas.md#5--mochila-ilimitada).

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

### `12/03` — Monedas: contar y mínimo [A]

De [`12/03` — Mochilas, §6](../12-dp-clasica/03-mochilas.md#6--monedas-contar-y-mínimo).

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

### `12/03` — Mochila acotada [B]

De [`12/03` — Mochilas, §7](../12-dp-clasica/03-mochilas.md#7--mochila-acotada).

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

### `12/04` — LCS [A]

De [`12/04` — DP sobre cadenas, §3](../12-dp-clasica/04-dp-sobre-cadenas.md#3--lcs).

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

### `12/04` — Distancia de edición [A]

De [`12/04` — DP sobre cadenas, §4](../12-dp-clasica/04-dp-sobre-cadenas.md#4--distancia-de-edición).

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

### `12/04` — Subsecuencias y palíndromos [A]

De [`12/04` — DP sobre cadenas, §5](../12-dp-clasica/04-dp-sobre-cadenas.md#5--subsecuencias-y-palíndromos).

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

### `12/05` — Rejillas [A]

De [`12/05` — DP en rejillas y de intervalos, §3](../12-dp-clasica/05-rejillas-e-intervalos.md#3--rejillas).

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

### `12/05` — Cadena de matrices [B]

De [`12/05` — DP en rejillas y de intervalos, §4](../12-dp-clasica/05-rejillas-e-intervalos.md#4--cadena-de-matrices).

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

### `12/05` — *Burst balloons* [B]

De [`12/05` — DP en rejillas y de intervalos, §5](../12-dp-clasica/05-rejillas-e-intervalos.md#5--burst-balloons).

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

### `12/06` — Conteo [A]

De [`12/06` — Conteo con DP, §3](../12-dp-clasica/06-conteo.md#3--conteo).

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]. Θ(n · L²).
long long countWords(long long n, const std::vector<std::vector<bool>>& allowed) {
    int L = (int)allowed.size();
    std::vector<long long> cur(L, 1);                          // longitud 1: una por letra
    for (long long step = 1; step < n; step++) {
        std::vector<long long> nxt(L, 0);
        for (int p = 0; p < L; p++)
            for (int c = 0; c < L; c++)
                if (allowed[p][c]) nxt[c] = (nxt[c] + cur[p]) % MOD;
        cur = nxt;
    }
    long long total = 0;
    for (long long x : cur) total = (total + x) % MOD;
    return total;
}
```

### `12/06` — Particiones [B]

De [`12/06` — Conteo con DP, §4](../12-dp-clasica/06-conteo.md#4--particiones).

```cpp
#include <vector>

// p[s] = particiones de s en partes positivas (orden indiferente). Θ(n²).
std::vector<long long> partitions(int n, bool distinct) {
    const long long MOD = 1'000'000'007;
    std::vector<long long> p(n + 1, 0);
    p[0] = 1;
    for (int part = 1; part <= n; part++) {
        if (distinct)                                           // cada parte, una vez: descendente
            for (int s = n; s >= part; s--) p[s] = (p[s] + p[s - part]) % MOD;
        else                                                    // repetible: ascendente
            for (int s = part; s <= n; s++) p[s] = (p[s] + p[s - part]) % MOD;
    }
    return p;
}
```

---

## 🧱 Bloque 13 — DP avanzada

### `13/01` — DP sobre subconjuntos [B]

De [`13/01` — DP con máscaras de bits, §3](../13-dp-avanzada/01-mascaras-de-bits.md#3--dp-sobre-subconjuntos).

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

### `13/01` — Viajante [B]

De [`13/01` — DP con máscaras de bits, §4](../13-dp-avanzada/01-mascaras-de-bits.md#4--viajante).

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

### `13/01` — SOS DP [B]

De [`13/01` — DP con máscaras de bits, §5](../13-dp-avanzada/01-mascaras-de-bits.md#5--sos-dp).

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

### `13/02` — *Digit DP* [B]

De [`13/02` — *Digit DP*, §3](../13-dp-avanzada/02-digit-dp.md#3--digit-dp).

```cpp
#include <cstring>
#include <string>

// Cuántos x en [0, N] tienen suma de dígitos ≡ 0 (mod k). N ≤ 10¹⁸, k ≤ 200. Θ(L · k · 10).
long long memo[20][200];
bool seen[20][200];
std::string digits;
int K;

long long go(int pos, int rem, bool tight) {
    if (pos == (int)digits.size()) return rem == 0 ? 1 : 0;
    if (!tight && seen[pos][rem]) return memo[pos][rem];
    int limit = tight ? digits[pos] - '0' : 9;
    long long count = 0;
    for (int c = 0; c <= limit; c++)
        count += go(pos + 1, (rem + c) % K, tight && c == limit);
    if (!tight) { seen[pos][rem] = true; memo[pos][rem] = count; }   // solo se guardan los libres
    return count;
}

long long countUpTo(long long N, int k) {
    if (N < 0) return 0;                                           // f(−1) = 0
    digits = std::to_string(N); K = k;
    std::memset(seen, 0, sizeof seen);
    return go(0, 0, true);
}
// Rango [a, b]: countUpTo(b, k) − countUpTo(a − 1, k)
```

### `13/03` — DP en árboles [A]

De [`13/03` — DP en árboles y en DAG, §3](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#3--dp-en-árboles).

```cpp
#include <algorithm>
#include <vector>

// Conjunto independiente de peso máximo en un árbol con raíz 0 y padres parent[] (parent[0] = −1). Θ(n).
long long maxIndependentSet(const std::vector<int>& parent, const std::vector<long long>& w) {
    int n = (int)parent.size();
    std::vector<std::vector<int>> children(n);
    for (int v = 1; v < n; v++) children[parent[v]].push_back(v);
    std::vector<int> order, stack = {0};
    while (!stack.empty()) {                                  // preorden iterativo
        int v = stack.back(); stack.pop_back();
        order.push_back(v);
        for (int c : children[v]) stack.push_back(c);
    }
    std::vector<long long> in(n), out(n);
    for (int i = n - 1; i >= 0; i--) {                        // al revés: hijos antes que padres
        int v = order[i];
        in[v] = w[v]; out[v] = 0;
        for (int c : children[v]) { in[v] += out[c]; out[v] += std::max(in[c], out[c]); }
    }
    return std::max(in[0], out[0]);
}
```

### `13/03` — DP sobre DAG [A]

De [`13/03` — DP en árboles y en DAG, §4](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#4--dp-sobre-dag).

```cpp
#include <algorithm>
#include <climits>
#include <queue>
#include <vector>

// En un DAG con aristas (u, v, w): número de caminos desde s (mod p) y el camino más largo. Θ(V + E).
void dagDP(int n, const std::vector<std::vector<std::pair<int, long long>>>& adj, int s,
           std::vector<long long>& ways, std::vector<long long>& longest) {
    const long long MOD = 1'000'000'007, NONE = LLONG_MIN;
    std::vector<int> indeg(n, 0), order;
    for (int u = 0; u < n; u++) for (auto [v, w] : adj[u]) indeg[v]++;
    std::queue<int> q;
    for (int u = 0; u < n; u++) if (indeg[u] == 0) q.push(u);
    while (!q.empty()) {                                           // Kahn: orden topológico
        int u = q.front(); q.pop(); order.push_back(u);
        for (auto [v, w] : adj[u]) if (--indeg[v] == 0) q.push(v);
    }
    ways.assign(n, 0); longest.assign(n, NONE);
    ways[s] = 1; longest[s] = 0;
    for (int u : order) {
        if (longest[u] == NONE) continue;                          // no alcanzable desde s
        for (auto [v, w] : adj[u]) {
            ways[v] = (ways[v] + ways[u]) % MOD;
            longest[v] = std::max(longest[v], longest[u] + w);
        }
    }
}
```

### `13/04` — DP de probabilidad [B]

De [`13/04` — DP de probabilidad y esperanza, §3](../13-dp-avanzada/04-probabilidad-y-esperanza.md#3--dp-de-probabilidad).

```cpp
#include <vector>

// prob[s] = probabilidad de que n dados de k caras sumen s. Θ(n · (n·k) · k).
std::vector<double> diceSum(int n, int k) {
    std::vector<double> prob(1, 1.0);                           // 0 dados: suma 0 con probabilidad 1
    for (int i = 0; i < n; i++) {
        std::vector<double> next(prob.size() + k, 0.0);
        for (size_t s = 0; s < prob.size(); s++)
            if (prob[s] > 0)
                for (int d = 1; d <= k; d++) next[s + d] += prob[s] / k;   // empujar hacia delante
        prob = next;
    }
    return prob;
}
```

### `13/04` — Esperanza hacia atrás [B]

De [`13/04` — DP de probabilidad y esperanza, §4](../13-dp-avanzada/04-probabilidad-y-esperanza.md#4--esperanza-hacia-atrás).

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

long long power(long long b, long long e) {                     // b^e mod MOD
    long long r = 1; b %= MOD;
    for (; e > 0; e >>= 1, b = b * b % MOD) if (e & 1) r = r * b % MOD;
    return r;
}

// E[0] mod MOD, con E[i] = 1 + (E[i+1] + … + E[i+m]) / m y E[i] = 0 si i ≥ n. Θ(n) con suma deslizante.
long long expectedRolls(int n, int m) {
    long long invM = power(m, MOD - 2);                          // 1/m por Fermat
    std::vector<long long> E(n + m + 1, 0);
    long long window = 0;                                        // E[i+1] + … + E[i+m]
    for (int i = n - 1; i >= 0; i--) {
        E[i] = (1 + window * invM) % MOD;
        window = (window + E[i] - E[i + m] + MOD) % MOD;         // la ventana baja una posición
    }
    return E[0];
}
```

### `13/05` — Cola monótona [B]

De [`13/05` — Optimizaciones de DP, §3](../13-dp-avanzada/05-optimizaciones.md#3--cola-monótona).

```cpp
#include <deque>
#include <vector>

// dp[i] = c[i] + min dp[j] con j ∈ [i − R, i − L] (1 ≤ L ≤ R); dp[0] = c[0]. −1 si inalcanzable. Θ(n).
long long windowDP(const std::vector<long long>& c, int L, int R) {
    int n = (int)c.size();
    const long long NONE = -1;
    std::vector<long long> dp(n, NONE);
    dp[0] = c[0];
    std::deque<int> dq;                                           // índices con dp creciente
    for (int i = 1; i < n; i++) {
        int add = i - L;                                          // entra en la ventana
        if (add >= 0 && dp[add] != NONE) {
            while (!dq.empty() && dp[dq.back()] >= dp[add]) dq.pop_back();
            dq.push_back(add);
        }
        while (!dq.empty() && dq.front() < i - R) dq.pop_front();  // sale por la izquierda
        if (!dq.empty()) dp[i] = c[i] + dp[dq.front()];
    }
    return dp[n - 1];
}
```

### `13/05` — *Convex hull trick* [B]

De [`13/05` — Optimizaciones de DP, §4](../13-dp-avanzada/05-optimizaciones.md#4--convex-hull-trick).

```cpp
#include <deque>

// Envolvente inferior de rectas y = m·x + b. Pre: pendientes decrecientes al añadir, x crecientes al consultar.
struct MonotoneCHT {
    std::deque<std::pair<long long, long long>> lines;         // (m, b)

    // ¿Sobra l2 entre l1 y l3? Con m1 > m2 > m3, comparar los cortes sin dividir (__int128 por seguridad).
    static bool bad(const std::pair<long long, long long>& l1, const std::pair<long long, long long>& l2,
                    const std::pair<long long, long long>& l3) {
        return (__int128)(l3.second - l1.second) * (l1.first - l2.first)
            <= (__int128)(l2.second - l1.second) * (l1.first - l3.first);
    }
    void add(long long m, long long b) {
        if (!lines.empty() && lines.back().first == m) {          // misma pendiente: la de menor b
            if (lines.back().second <= b) return;
            lines.pop_back();
        }
        while (lines.size() >= 2 && bad(lines[lines.size() - 2], lines.back(), {m, b})) lines.pop_back();
        lines.push_back({m, b});
    }
    long long query(long long x) {                               // x no decrecientes entre llamadas
        auto val = [&](const std::pair<long long, long long>& l) { return l.first * x + l.second; };
        while (lines.size() >= 2 && val(lines[1]) <= val(lines[0])) lines.pop_front();
        return val(lines.front());
    }
};
```

### `13/06` — Exponenciación de matrices [B]

De [`13/06` — Recurrencias lineales y exponenciación de matrices, §3](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md#3--exponenciación-de-matrices).

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

---

## 🧱 Bloque 14 — Grafos: recorridos

### `14/01` — Representaciones [A]

De [`14/01` — Representaciones y su coste, §3](../14-grafos-recorridos/01-representaciones.md#3--representaciones).

```cpp
#include <cstdio>
#include <vector>

struct Edge { int to; long long w; };

// Lee n, m y m aristas no dirigidas «u v w» (vértices de 1 a n) en listas de adyacencia, índices desde 0.
std::vector<std::vector<Edge>> readGraph(int& n, int& m) {
    std::scanf("%d %d", &n, &m);
    std::vector<std::vector<Edge>> adj(n);
    for (int i = 0; i < m; i++) {
        int u, v; long long w;
        std::scanf("%d %d %lld", &u, &v, &w);
        u--; v--;                                            // a índices desde 0
        adj[u].push_back({v, w});
        adj[v].push_back({u, w});                            // no dirigido: en los dos sentidos
    }
    return adj;
}

// Vecinos implícitos en una rejilla R × C: las cuatro direcciones.
const int DR[4] = {-1, 1, 0, 0}, DC[4] = {0, 0, -1, 1};
// for (int d = 0; d < 4; d++) { int r2 = r + DR[d], c2 = c + DC[d];
//     if (r2 >= 0 && r2 < R && c2 >= 0 && c2 < C && grid[r2][c2] != '#') … }
```

### `14/02` — BFS [A]

De [`14/02` — BFS, §3](../14-grafos-recorridos/02-bfs.md#3--bfs).

```cpp
#include <queue>
#include <vector>

// Distancias desde las fuentes en un grafo sin pesos; −1 = inalcanzable. parent para reconstruir caminos.
std::vector<int> bfs(const std::vector<std::vector<int>>& adj, const std::vector<int>& sources,
                     std::vector<int>& parent) {
    int n = adj.size();
    std::vector<int> dist(n, -1);
    parent.assign(n, -1);
    std::queue<int> q;
    for (int s : sources) { dist[s] = 0; q.push(s); }       // se marca al encolar
    while (!q.empty()) {
        int u = q.front(); q.pop();
        for (int v : adj[u])
            if (dist[v] == -1) { dist[v] = dist[u] + 1; parent[v] = u; q.push(v); }
    }
    return dist;
}

```

### `14/02` — Multifuente y rejillas [A]

De [`14/02` — BFS, §4](../14-grafos-recorridos/02-bfs.md#4--multifuente-y-rejillas).

```cpp
#include <queue>
#include <string>
#include <vector>

// Distancia de cada casilla libre a la fuente más cercana (−1 = pared o inalcanzable).
std::vector<std::vector<int>> gridBfs(const std::vector<std::string>& g,
                                      const std::vector<std::pair<int, int>>& sources) {
    int R = g.size(), C = g[0].size();
    const int DR[4] = {-1, 1, 0, 0}, DC[4] = {0, 0, -1, 1};
    std::vector<std::vector<int>> dist(R, std::vector<int>(C, -1));
    std::queue<std::pair<int, int>> q;
    for (auto [r, c] : sources) { dist[r][c] = 0; q.push({r, c}); }
    while (!q.empty()) {
        auto [r, c] = q.front(); q.pop();
        for (int d = 0; d < 4; d++) {
            int r2 = r + DR[d], c2 = c + DC[d];
            if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C) continue;
            if (g[r2][c2] == '#' || dist[r2][c2] != -1) continue;
            dist[r2][c2] = dist[r][c] + 1;
            q.push({r2, c2});
        }
    }
    return dist;
}
```

### `14/02` — 0-1 BFS [A]

De [`14/02` — BFS, §5](../14-grafos-recorridos/02-bfs.md#5--0-1-bfs).

```cpp
#include <deque>
#include <vector>

// Aristas {vecino, peso} con peso 0 o 1. dist = INF si inalcanzable.
std::vector<int> bfs01(const std::vector<std::vector<std::pair<int, int>>>& adj, int s) {
    const int INF = 1e9;
    std::vector<int> dist(adj.size(), INF);
    std::deque<int> dq;
    dist[s] = 0; dq.push_back(s);
    while (!dq.empty()) {
        int u = dq.front(); dq.pop_front();
        for (auto [v, w] : adj[u])
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                if (w == 0) dq.push_front(v); else dq.push_back(v);
            }
    }
    return dist;
}
```

### `14/02` — Estados compuestos [A]

De [`14/02` — BFS, §6](../14-grafos-recorridos/02-bfs.md#6--estados-compuestos).

```cpp
#include <queue>
#include <string>
#include <vector>

// Pasos mínimos de (sr, sc) a T pudiendo atravesar hasta maxWalls muros. Estado: (r · C + c) · K + k.
int bfsWithState(const std::vector<std::string>& g, int sr, int sc, int maxWalls) {
    int R = g.size(), C = g[0].size(), K = maxWalls + 1;
    const int DR[4] = {-1, 1, 0, 0}, DC[4] = {0, 0, -1, 1};
    std::vector<int> dist(R * C * K, -1);
    std::queue<int> q;
    dist[(sr * C + sc) * K] = 0; q.push((sr * C + sc) * K);
    while (!q.empty()) {
        int st = q.front(); q.pop();
        int k = st % K, r = st / K / C, c = st / K % C;
        if (g[r][c] == 'T') return dist[st];                 // el primero que sale es el mínimo
        for (int d = 0; d < 4; d++) {
            int r2 = r + DR[d], c2 = c + DC[d];
            if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C) continue;
            int k2 = k + (g[r2][c2] == '#');                 // la transición del estado
            if (k2 >= K) continue;
            int nxt = (r2 * C + c2) * K + k2;
            if (dist[nxt] == -1) { dist[nxt] = dist[st] + 1; q.push(nxt); }
        }
    }
    return -1;
}
```

### `14/03` — DFS [A]

De [`14/03` — DFS, §3](../14-grafos-recorridos/03-dfs.md#3--dfs).

```cpp
#include <vector>

// DFS recursivo con tiempos. tin = 0 marca «blanco». Profundidad n: en C++ cabe con n ≈ 2·10⁵.
struct Dfs {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> tin, tout, parent;
    int timer = 0;
    explicit Dfs(const std::vector<std::vector<int>>& g)
        : adj(g), tin(g.size(), 0), tout(g.size(), 0), parent(g.size(), -1) {
        for (int s = 0; s < (int)g.size(); s++) if (!tin[s]) visit(s);
    }
    void visit(int u) {
        tin[u] = ++timer;
        for (int v : adj[u]) if (!tin[v]) { parent[v] = u; visit(v); }
        tout[u] = ++timer;
    }
};
```

### `14/03` — Componentes [A]

De [`14/03` — DFS, §4](../14-grafos-recorridos/03-dfs.md#4--componentes).

```cpp
#include <vector>

// comp[v] = número de componente; devuelve cuántas hay. Pila explícita.
int components(const std::vector<std::vector<int>>& adj, std::vector<int>& comp) {
    int n = adj.size(), c = 0;
    comp.assign(n, -1);
    std::vector<int> stack;
    for (int s = 0; s < n; s++) {
        if (comp[s] != -1) continue;
        comp[s] = c; stack.push_back(s);
        while (!stack.empty()) {
            int u = stack.back(); stack.pop_back();
            for (int v : adj[u]) if (comp[v] == -1) { comp[v] = c; stack.push_back(v); }
        }
        c++;
    }
    return c;
}
```

### `14/03` — Ciclos [A]

De [`14/03` — DFS, §5](../14-grafos-recorridos/03-dfs.md#5--ciclos).

```cpp
#include <algorithm>
#include <vector>

// Ciclo en un dirigido: color 0 blanco, 1 gris, 2 negro. Devuelve los vértices del ciclo, o vacío.
struct CycleFinder {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> color, parent, cycle;
    explicit CycleFinder(const std::vector<std::vector<int>>& g)
        : adj(g), color(g.size(), 0), parent(g.size(), -1) {
        for (int s = 0; s < (int)g.size() && cycle.empty(); s++) if (!color[s]) visit(s);
    }
    bool visit(int u) {
        color[u] = 1;
        for (int v : adj[u]) {
            if (color[v] == 1) {                             // arista de retroceso: hay ciclo
                for (int x = u; x != v; x = parent[x]) cycle.push_back(x);
                cycle.push_back(v);
                std::reverse(cycle.begin(), cycle.end());
                return true;
            }
            if (color[v] == 0) { parent[v] = u; if (visit(v)) return true; }
        }
        color[u] = 2;
        return false;
    }
};
```

### `14/04` — Kahn [A]

De [`14/04` — Orden topológico y DP sobre DAG, §3](../14-grafos-recorridos/04-orden-topologico.md#3--kahn).

```cpp
#include <queue>
#include <vector>

// Orden topológico por Kahn. Devuelve vacío si hay ciclo (el orden queda con menos de n vértices).
std::vector<int> kahn(const std::vector<std::vector<int>>& adj) {
    int n = adj.size();
    std::vector<int> indeg(n, 0), order;
    for (int u = 0; u < n; u++) for (int v : adj[u]) indeg[v]++;
    std::queue<int> q;                                  // min-heap aquí para el lexicográfico mínimo
    for (int v = 0; v < n; v++) if (indeg[v] == 0) q.push(v);
    while (!q.empty()) {
        int u = q.front(); q.pop();
        order.push_back(u);
        for (int v : adj[u]) if (--indeg[v] == 0) q.push(v);
    }
    if ((int)order.size() < n) order.clear();           // hay ciclo
    return order;
}
```

### `14/04` — Por DFS [A]

De [`14/04` — Orden topológico y DP sobre DAG, §4](../14-grafos-recorridos/04-orden-topologico.md#4--por-dfs).

```cpp
#include <algorithm>
#include <vector>

// Postorden invertido con tres colores. Devuelve vacío si encuentra una arista a un gris (ciclo).
struct TopoDfs {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> color, order;
    bool cyclic = false;
    explicit TopoDfs(const std::vector<std::vector<int>>& g) : adj(g), color(g.size(), 0) {
        for (int s = 0; s < (int)g.size() && !cyclic; s++) if (!color[s]) visit(s);
        if (cyclic) order.clear(); else std::reverse(order.begin(), order.end());
    }
    void visit(int u) {
        color[u] = 1;
        for (int v : adj[u]) {
            if (color[v] == 1) { cyclic = true; return; }
            if (color[v] == 0) { visit(v); if (cyclic) return; }
        }
        color[u] = 2;
        order.push_back(u);                              // al terminar: postorden
    }
};
```

### `14/05` — Kosaraju [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §3](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#3--kosaraju).

```cpp
#include <vector>

// Kosaraju: comp[v] = número de SCC, numeradas en orden topológico del condensado.
struct Kosaraju {
    std::vector<std::vector<int>> adj, radj;
    std::vector<int> order, comp;
    std::vector<bool> seen;
    int count = 0;
    explicit Kosaraju(const std::vector<std::vector<int>>& g) : adj(g), radj(g.size()) {
        int n = g.size();
        for (int u = 0; u < n; u++) for (int v : g[u]) radj[v].push_back(u);
        seen.assign(n, false);
        for (int v = 0; v < n; v++) if (!seen[v]) dfs1(v);
        comp.assign(n, -1);
        for (int i = n - 1; i >= 0; i--)
            if (comp[order[i]] == -1) dfs2(order[i], count++);
    }
    void dfs1(int u) {
        seen[u] = true;
        for (int v : adj[u]) if (!seen[v]) dfs1(v);
        order.push_back(u);                              // postorden
    }
    void dfs2(int u, int c) {
        comp[u] = c;
        for (int v : radj[u]) if (comp[v] == -1) dfs2(v, c);
    }
};
```

### `14/05` — Tarjan [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §4](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#4--tarjan).

```cpp
#include <algorithm>
#include <vector>

// Tarjan: comp[v] en orden topológico inverso del condensado.
struct Tarjan {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> tin, low, comp, stk;
    std::vector<bool> onStack;
    int timer = 0, count = 0;
    explicit Tarjan(const std::vector<std::vector<int>>& g)
        : adj(g), tin(g.size(), 0), low(g.size(), 0), comp(g.size(), -1), onStack(g.size(), false) {
        for (int v = 0; v < (int)g.size(); v++) if (!tin[v]) dfs(v);
    }
    void dfs(int u) {
        tin[u] = low[u] = ++timer;
        stk.push_back(u); onStack[u] = true;
        for (int v : adj[u]) {
            if (!tin[v]) { dfs(v); low[u] = std::min(low[u], low[v]); }
            else if (onStack[v]) low[u] = std::min(low[u], tin[v]);
        }
        if (low[u] == tin[u]) {                          // u es la raíz de su SCC
            while (true) {
                int w = stk.back(); stk.pop_back();
                onStack[w] = false; comp[w] = count;
                if (w == u) break;
            }
            count++;
        }
    }
};
```

### `14/05` — 2-SAT [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §5](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#5--2-sat).

```cpp
#include <vector>

struct TwoSat {
    int n;
    std::vector<std::vector<int>> g;
    explicit TwoSat(int vars) : n(vars), g(2 * vars) {}
    static int lit(int i, bool value) { return 2 * i + (value ? 0 : 1); }
    // Cláusula (xi == vi) ∨ (xj == vj).
    void addClause(int i, bool vi, int j, bool vj) {
        g[lit(i, !vi)].push_back(lit(j, vj));            // ¬a → b
        g[lit(j, !vj)].push_back(lit(i, vi));            // ¬b → a
    }
    // Devuelve la asignación, o vacío si no hay.
    std::vector<bool> solve() {
        Tarjan t(g);
        std::vector<bool> value(n);
        for (int i = 0; i < n; i++) {
            if (t.comp[2 * i] == t.comp[2 * i + 1]) return {};
            value[i] = t.comp[2 * i] < t.comp[2 * i + 1];
        }
        return value;
    }
};
```

### `14/06` — Puentes y puntos de articulación [B]

De [`14/06` — Puentes, puntos de articulación y Euler, §3](../14-grafos-recorridos/06-puentes-articulacion-y-euler.md#3--puentes-y-puntos-de-articulación).

```cpp
#include <algorithm>
#include <vector>

// adj[u] = {vecino, índice de la arista}. Puentes (índices) y puntos de articulación.
struct Bridges {
    const std::vector<std::vector<std::pair<int, int>>>& adj;
    std::vector<int> tin, low, bridges;
    std::vector<bool> isCut;
    int timer = 0;
    explicit Bridges(const std::vector<std::vector<std::pair<int, int>>>& g)
        : adj(g), tin(g.size(), 0), low(g.size(), 0), isCut(g.size(), false) {
        for (int s = 0; s < (int)g.size(); s++) if (!tin[s]) dfs(s, -1);
    }
    void dfs(int u, int parentEdge) {
        tin[u] = low[u] = ++timer;
        int children = 0;
        for (auto [v, id] : adj[u]) {
            if (id == parentEdge) continue;              // la arista del árbol hacia el padre, solo esa
            if (tin[v]) { low[u] = std::min(low[u], tin[v]); continue; }   // de retroceso
            dfs(v, id);
            children++;
            low[u] = std::min(low[u], low[v]);
            if (low[v] > tin[u]) bridges.push_back(id);
            if (parentEdge != -1 && low[v] >= tin[u]) isCut[u] = true;
        }
        if (parentEdge == -1 && children > 1) isCut[u] = true;   // la raíz
    }
};
```

### `14/06` — Euler (Hierholzer) [B]

De [`14/06` — Puentes, puntos de articulación y Euler, §4](../14-grafos-recorridos/06-puentes-articulacion-y-euler.md#4--euler-hierholzer).

```cpp
#include <algorithm>
#include <vector>

// adj[u] = {vecino, índice de la arista}. Camino de Euler desde start; vacío si no usa las m aristas.
std::vector<int> euler(const std::vector<std::vector<std::pair<int, int>>>& adj, int m, int start) {
    std::vector<int> ptr(adj.size(), 0), path, stack = {start};
    std::vector<bool> used(m, false);
    while (!stack.empty()) {
        int u = stack.back();
        while (ptr[u] < (int)adj[u].size() && used[adj[u][ptr[u]].second]) ptr[u]++;
        if (ptr[u] == (int)adj[u].size()) {              // sin aristas libres: al recorrido
            path.push_back(u); stack.pop_back();
        } else {
            auto [v, id] = adj[u][ptr[u]];
            used[id] = true;
            stack.push_back(v);
        }
    }
    if ((int)path.size() != m + 1) return {};            // aristas en otra componente
    std::reverse(path.begin(), path.end());
    return path;
}
```

---

## 🧱 Bloque 15 — Grafos con pesos y flujos

### `15/01` — Dijkstra con montículo [A]

De [`15/01` — Dijkstra, §3](../15-grafos-pesos-y-flujos/01-dijkstra.md#3--dijkstra-con-montículo).

```cpp
#include <functional>
#include <queue>
#include <vector>

const long long INF = (long long)4e18;

// adj[u] = {vecino, peso}, pesos ≥ 0. Distancias desde s (INF = inalcanzable) y padres.
std::vector<long long> dijkstra(const std::vector<std::vector<std::pair<int, long long>>>& adj, int s,
                         std::vector<int>& parent) {
    int n = adj.size();
    std::vector<long long> dist(n, INF);
    parent.assign(n, -1);
    using Item = std::pair<long long, int>;
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> pq;
    dist[s] = 0; pq.push({0, s});
    while (!pq.empty()) {
        auto [d, u] = pq.top(); pq.pop();
        if (d > dist[u]) continue;                       // entrada vieja: se descarta
        for (auto [v, w] : adj[u])
            if (d + w < dist[v]) { dist[v] = d + w; parent[v] = u; pq.push({dist[v], v}); }
    }
    return dist;
}
```

### `15/01` — Dijkstra sobre estados [A]

De [`15/01` — Dijkstra, §4](../15-grafos-pesos-y-flujos/01-dijkstra.md#4--dijkstra-sobre-estados).

```cpp
#include <functional>
#include <queue>
#include <tuple>
#include <vector>


// Distancia mínima de s a cada vértice usando hasta K vales (cada vale hace gratis una arista).
std::vector<long long> dijkstraVouchers(const std::vector<std::vector<std::pair<int, long long>>>& adj, int s, int K) {
    int n = adj.size();
    const long long INF = (long long)4e18;
    std::vector<std::vector<long long>> dist(n, std::vector<long long>(K + 1, INF));
    using Item = std::tuple<long long, int, int>;
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> pq;
    dist[s][0] = 0; pq.push({0, s, 0});
    while (!pq.empty()) {
        auto [d, u, k] = pq.top(); pq.pop();
        if (d > dist[u][k]) continue;
        for (auto [v, w] : adj[u]) {
            if (d + w < dist[v][k]) { dist[v][k] = d + w; pq.push({d + w, v, k}); }        // pagar
            if (k < K && d < dist[v][k + 1]) { dist[v][k + 1] = d; pq.push({d, v, k + 1}); } // vale
        }
    }
    std::vector<long long> best(n, INF);
    for (int v = 0; v < n; v++) for (int k = 0; k <= K; k++) best[v] = std::min(best[v], dist[v][k]);
    return best;
}
```

### `15/02` — Bellman-Ford [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §3](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#3--bellman-ford).

```cpp
#include <vector>

struct Edge { int u, v; long long w; };

// Distancias desde s; devuelve false si hay un ciclo negativo alcanzable desde s.
bool bellmanFord(int n, const std::vector<Edge>& edges, int s, std::vector<long long>& dist) {
    const long long INF = (long long)4e18;
    dist.assign(n, INF);
    dist[s] = 0;
    for (int round = 0; round < n; round++) {
        bool changed = false;
        for (const Edge& e : edges)
            if (dist[e.u] != INF && dist[e.u] + e.w < dist[e.v]) { dist[e.v] = dist[e.u] + e.w; changed = true; }
        if (!changed) return true;                       // estable: no hay ciclo negativo alcanzable
        if (round == n - 1) return false;                // la ronda n todavía mejora
    }
    return true;
}
```

### `15/02` — Floyd-Warshall [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §4](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#4--floyd-warshall).

```cpp
#include <algorithm>
#include <vector>

const long long INF = (long long)1e18;

// d[i][j] = peso de la arista (o INF), d[i][i] = 0. Al terminar, distancias; d[i][i] < 0 si hay ciclo negativo.
void floydWarshall(std::vector<std::vector<long long>>& d) {
    int n = d.size();
    for (int k = 0; k < n; k++)                          // k por fuera, siempre
        for (int i = 0; i < n; i++) {
            if (d[i][k] == INF) continue;
            for (int j = 0; j < n; j++)
                if (d[k][j] != INF) d[i][j] = std::min(d[i][j], d[i][k] + d[k][j]);
        }
}
```

### `15/02` — Por qué no SPFA [B]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §5](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#5--por-qué-no-spfa).

```cpp
#include <queue>
#include <vector>


// adj[u] = {v, w}. false si hay ciclo negativo alcanzable (un vértice entra n veces).
bool spfa(const std::vector<std::vector<std::pair<int, long long>>>& adj, int s, std::vector<long long>& dist) {
    int n = adj.size();
    const long long INF = (long long)4e18;
    dist.assign(n, INF);
    std::vector<int> cnt(n, 0);
    std::vector<bool> inQueue(n, false);
    std::queue<int> q;
    dist[s] = 0; q.push(s); inQueue[s] = true;
    while (!q.empty()) {
        int u = q.front(); q.pop(); inQueue[u] = false;
        for (auto [v, w] : adj[u])
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                if (!inQueue[v]) {
                    if (++cnt[v] >= n) return false;
                    q.push(v); inQueue[v] = true;
                }
            }
    }
    return true;
}
```

### `15/03` — A\* [B]

De [`15/03` — A\* y heurísticas admisibles, §3](../15-grafos-pesos-y-flujos/03-a-estrella.md#3--a).

```cpp
#include <cstdint>
#include <cstdlib>
#include <functional>
#include <queue>
#include <string>
#include <tuple>
#include <vector>

// Distancia mínima de (sr, sc) a (tr, tc) evitando '#'; −1 si no se llega.
int aStar(const std::vector<std::string>& g, int sr, int sc, int tr, int tc) {
    int R = g.size(), C = g[0].size();
    const int DR[4] = {-1, 1, 0, 0}, DC[4] = {0, 0, -1, 1};
    auto h = [&](int r, int c) { return std::abs(r - tr) + std::abs(c - tc); };   // Manhattan
    std::vector<int> dist(R * C, INT32_MAX);
    using Item = std::tuple<int, int, int>;                  // {f, −g (desempate), casilla}
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> pq;
    dist[sr * C + sc] = 0;
    pq.push({h(sr, sc), 0, sr * C + sc});
    while (!pq.empty()) {
        auto [f, negG, cur] = pq.top(); pq.pop();
        int g0 = -negG, r = cur / C, c = cur % C;
        if (g0 > dist[cur]) continue;                        // entrada vieja
        if (r == tr && c == tc) return g0;                   // T sale con su distancia final
        for (int d = 0; d < 4; d++) {
            int r2 = r + DR[d], c2 = c + DC[d];
            if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C || g[r2][c2] == '#') continue;
            int nxt = r2 * C + c2;
            if (g0 + 1 < dist[nxt]) { dist[nxt] = g0 + 1; pq.push({g0 + 1 + h(r2, c2), -(g0 + 1), nxt}); }
        }
    }
    return -1;
}
```

### `15/04` — Kruskal [A]

De [`15/04` — Árbol de expansión mínima, §3](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#3--kruskal).

```cpp
#include <algorithm>
#include <numeric>
#include <tuple>
#include <vector>


struct DSU {
    std::vector<int> p, sz;
    explicit DSU(int n) : p(n), sz(n, 1) { std::iota(p.begin(), p.end(), 0); }
    int find(int x) { while (p[x] != x) x = p[x] = p[p[x]]; return x; }   // compresión a la mitad
    bool unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (sz[a] < sz[b]) std::swap(a, b);
        p[b] = a; sz[a] += sz[b];
        return true;
    }
};

// edges = {peso, u, v}. Peso del MST, o −1 si el grafo no es conexo.
long long kruskal(int n, std::vector<std::tuple<long long, int, int>> edges) {
    std::sort(edges.begin(), edges.end());
    DSU dsu(n);
    long long total = 0; int used = 0;
    for (auto [w, u, v] : edges)
        if (dsu.unite(u, v)) { total += w; if (++used == n - 1) break; }
    return used == n - 1 ? total : -1;
}
```

### `15/04` — Prim [A]

De [`15/04` — Árbol de expansión mínima, §4](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#4--prim).

```cpp
#include <functional>
#include <queue>
#include <vector>


// adj[u] = {vecino, peso}. Peso del MST, o −1 si no es conexo. Montículo con borrado perezoso.
long long prim(const std::vector<std::vector<std::pair<int, long long>>>& adj) {
    int n = adj.size(), taken = 0;
    std::vector<bool> inTree(n, false);
    using Item = std::pair<long long, int>;
    std::priority_queue<Item, std::vector<Item>, std::greater<Item>> pq;
    pq.push({0, 0});
    long long total = 0;
    while (!pq.empty() && taken < n) {
        auto [w, u] = pq.top(); pq.pop();
        if (inTree[u]) continue;                         // entrada vieja
        inTree[u] = true; total += w; taken++;
        for (auto [v, wv] : adj[u]) if (!inTree[v]) pq.push({wv, v});   // el peso de la arista, no d + w
    }
    return taken == n ? total : -1;
}
```

### `15/05` — Ford-Fulkerson y Edmonds-Karp [B]

De [`15/05` — Flujo máximo y corte mínimo, §3](../15-grafos-pesos-y-flujos/05-flujo-maximo.md#3--ford-fulkerson-y-edmonds-karp).

```cpp
#include <algorithm>
#include <queue>
#include <vector>


struct EdmondsKarp {
    struct Edge { int to; long long cap; };
    std::vector<Edge> edges;                              // la arista e y su vuelta e ^ 1, contiguas
    std::vector<std::vector<int>> g;
    explicit EdmondsKarp(int n) : g(n) {}
    void addEdge(int u, int v, long long c) {
        g[u].push_back(edges.size()); edges.push_back({v, c});
        g[v].push_back(edges.size()); edges.push_back({u, 0});
    }
    long long maxFlow(int s, int t) {
        long long flow = 0;
        while (true) {
            std::vector<int> parentEdge(g.size(), -1);
            std::queue<int> q; q.push(s);
            while (!q.empty() && parentEdge[t] == -1) {
                int u = q.front(); q.pop();
                for (int e : g[u]) {
                    int v = edges[e].to;
                    if (edges[e].cap > 0 && v != s && parentEdge[v] == -1) { parentEdge[v] = e; q.push(v); }
                }
            }
            if (parentEdge[t] == -1) return flow;        // sin camino aumentante: máximo
            long long push = (long long)4e18;
            for (int v = t; v != s; v = edges[parentEdge[v] ^ 1].to) push = std::min(push, edges[parentEdge[v]].cap);
            for (int v = t; v != s; v = edges[parentEdge[v] ^ 1].to) {
                edges[parentEdge[v]].cap -= push;
                edges[parentEdge[v] ^ 1].cap += push;   // se puede deshacer
            }
            flow += push;
        }
    }
};
```

### `15/05` — Dinic [B]

De [`15/05` — Flujo máximo y corte mínimo, §4](../15-grafos-pesos-y-flujos/05-flujo-maximo.md#4--dinic).

```cpp
#include <algorithm>
#include <queue>
#include <vector>


struct Dinic {
    struct Edge { int to; long long cap; };
    std::vector<Edge> edges;
    std::vector<std::vector<int>> g;
    std::vector<int> level, it;
    explicit Dinic(int n) : g(n), level(n), it(n) {}
    void addEdge(int u, int v, long long c) {
        g[u].push_back(edges.size()); edges.push_back({v, c});
        g[v].push_back(edges.size()); edges.push_back({u, 0});
    }
    bool bfs(int s, int t) {
        std::fill(level.begin(), level.end(), -1);
        std::queue<int> q; q.push(s); level[s] = 0;
        while (!q.empty()) {
            int u = q.front(); q.pop();
            for (int e : g[u])
                if (edges[e].cap > 0 && level[edges[e].to] == -1) { level[edges[e].to] = level[u] + 1; q.push(edges[e].to); }
        }
        return level[t] != -1;
    }
    long long dfs(int u, int t, long long pushed) {
        if (u == t) return pushed;
        for (int& i = it[u]; i < (int)g[u].size(); i++) {   // el puntero no retrocede en la fase
            int e = g[u][i], v = edges[e].to;
            if (edges[e].cap > 0 && level[v] == level[u] + 1) {
                long long got = dfs(v, t, std::min(pushed, edges[e].cap));
                if (got > 0) { edges[e].cap -= got; edges[e ^ 1].cap += got; return got; }
            }
        }
        return 0;
    }
    long long maxFlow(int s, int t) {
        long long flow = 0;
        while (bfs(s, t)) {
            std::fill(it.begin(), it.end(), 0);
            while (long long f = dfs(s, t, (long long)4e18)) flow += f;
        }
        return flow;
    }
};
```

### `15/06` — Kuhn [B]

De [`15/06` — Emparejamientos, §3](../15-grafos-pesos-y-flujos/06-emparejamientos.md#3--kuhn).

```cpp
#include <vector>

// Bipartito con nl vértices a la izquierda y nr a la derecha; adj[u] = vecinos derechos de u.
struct Kuhn {
    const std::vector<std::vector<int>>& adj;
    std::vector<int> matchR;                             // matchR[v] = pareja izquierda de v, o −1
    std::vector<int> seen;                               // marca de la ronda en que se visitó v
    int round = 0;
    Kuhn(const std::vector<std::vector<int>>& g, int nr) : adj(g), matchR(nr, -1), seen(nr, 0) {}
    bool tryKuhn(int u) {
        for (int v : adj[u]) {
            if (seen[v] == round) continue;
            seen[v] = round;
            if (matchR[v] == -1 || tryKuhn(matchR[v])) { matchR[v] = u; return true; }
        }
        return false;
    }
    int maxMatching() {
        int result = 0;
        for (int u = 0; u < (int)adj.size(); u++) { round++; if (tryKuhn(u)) result++; }
        return result;
    }
};
```

### `15/06` — König [B]

De [`15/06` — Emparejamientos, §5](../15-grafos-pesos-y-flujos/06-emparejamientos.md#5--könig).

```cpp
#include <vector>

// Tras Kuhn: visitados por caminos alternantes desde los izquierdos libres.
// Cobertura = izquierdos con visL = false + derechos con visR = true.
void konig(const std::vector<std::vector<int>>& adj, const std::vector<int>& matchR,
           std::vector<bool>& visL, std::vector<bool>& visR) {
    int nl = adj.size();
    std::vector<bool> matchedL(nl, false);
    for (int v = 0; v < (int)matchR.size(); v++) if (matchR[v] != -1) matchedL[matchR[v]] = true;
    visL.assign(nl, false); visR.assign(matchR.size(), false);
    std::vector<int> stack;
    for (int u = 0; u < nl; u++) if (!matchedL[u]) { visL[u] = true; stack.push_back(u); }
    while (!stack.empty()) {
        int u = stack.back(); stack.pop_back();
        for (int v : adj[u])
            if (!visR[v] && matchR[v] != u) {            // arista fuera de M, de izquierda a derecha
                visR[v] = true;
                int w = matchR[v];                       // y de vuelta por la arista de M
                if (w != -1 && !visL[w]) { visL[w] = true; stack.push_back(w); }
            }
    }
}
```

---

## 🧱 Bloque 16 — Cadenas

### `16/01` — Inmutabilidad y concatenación [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §3](../16-cadenas/01-cadenas-y-patrones-basicos.md#3--inmutabilidad-y-concatenación).

```cpp
#include <string>
#include <vector>

// En C++ std::string es mutable: += y push_back son O(1) amortizado. reserve evita las ampliaciones.
std::string joinWords(const std::vector<std::string>& words, char sep) {
    std::string out;
    std::size_t total = 0;
    for (const auto& w : words) total += w.size() + 1;
    out.reserve(total);
    for (std::size_t i = 0; i < words.size(); i++) {
        if (i) out += sep;
        out += words[i];
    }
    return out;
}
```

### `16/01` — Frecuencias y anagramas [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §4](../16-cadenas/01-cadenas-y-patrones-basicos.md#4--frecuencias-y-anagramas).

```cpp
#include <array>
#include <string>

// Frecuencias de minúsculas y comprobación de anagrama.
std::array<int, 26> freq(const std::string& s) {
    std::array<int, 26> f{};
    for (char c : s) f[c - 'a']++;
    return f;
}
bool isAnagram(const std::string& a, const std::string& b) {
    return a.size() == b.size() && freq(a) == freq(b);   // std::array se compara elemento a elemento
}
```

### `16/01` — Palíndromos con dos punteros [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §5](../16-cadenas/01-cadenas-y-patrones-basicos.md#5--palíndromos-con-dos-punteros).

```cpp
#include <string>

// Número de pares (i, j) simétricos distintos en s[l..r]; 0 si es palíndromo.
int mismatches(const std::string& s, int l, int r) {
    int count = 0;
    while (l < r) { if (s[l] != s[r]) count++; l++; r--; }
    return count;
}
```

### `16/02` — Función de prefijo [A]

De [`16/02` — KMP y la función de prefijo, §3](../16-cadenas/02-kmp.md#3--función-de-prefijo).

```cpp
#include <string>
#include <vector>

// pi[i] = longitud del borde más largo de s[0..i].
std::vector<int> prefixFunction(const std::string& s) {
    int n = s.size();
    std::vector<int> pi(n, 0);
    for (int i = 1; i < n; i++) {
        int k = pi[i - 1];
        while (k > 0 && s[i] != s[k]) k = pi[k - 1];     // bajar al siguiente borde
        if (s[i] == s[k]) k++;
        pi[i] = k;
    }
    return pi;
}
```

### `16/02` — KMP [A]

De [`16/02` — KMP y la función de prefijo, §4](../16-cadenas/02-kmp.md#4--kmp).

```cpp
#include <string>
#include <vector>

std::vector<int> prefixFunction(const std::string& s);   // la de §3

// Posiciones de inicio de todas las apariciones (solapadas) de p en t.
std::vector<int> kmpSearch(const std::string& t, const std::string& p) {
    std::vector<int> pi = prefixFunction(p), found;
    int m = p.size(), k = 0;
    for (int i = 0; i < (int)t.size(); i++) {
        while (k > 0 && t[i] != p[k]) k = pi[k - 1];
        if (t[i] == p[k]) k++;
        if (k == m) { found.push_back(i - m + 1); k = pi[k - 1]; }   // seguir buscando solapadas
    }
    return found;
}
```

### `16/02` — Autómata de KMP [B]

De [`16/02` — KMP y la función de prefijo, §5](../16-cadenas/02-kmp.md#5--autómata-de-kmp).

```cpp
#include <array>
#include <string>
#include <vector>

std::vector<int> prefixFunction(const std::string& s);   // la de §3

// Autómata de KMP sobre minúsculas: delta[q][c] para q en [0, m].
std::vector<std::array<int, 26>> kmpAutomaton(const std::string& p) {
    int m = p.size();
    std::vector<int> pi = prefixFunction(p);
    std::vector<std::array<int, 26>> delta(m + 1);
    for (int q = 0; q <= m; q++)
        for (int c = 0; c < 26; c++) {
            if (q < m && p[q] - 'a' == c) delta[q][c] = q + 1;
            else delta[q][c] = q == 0 ? 0 : delta[pi[q - 1]][c];
        }
    return delta;
}
```

### `16/03` — Función Z [B]

De [`16/03` — Función Z y Manacher, §3](../16-cadenas/03-funcion-z-y-manacher.md#3--función-z).

```cpp
#include <algorithm>
#include <string>
#include <vector>

// z[i] = prefijo común más largo de s y s[i..]; z[0] = 0 por convenio.
std::vector<int> zFunction(const std::string& s) {
    int n = s.size();
    std::vector<int> z(n, 0);
    for (int i = 1, l = 0, r = 0; i < n; i++) {
        if (i < r) z[i] = std::min(r - i, z[i - l]);        // copia desde la caja
        while (i + z[i] < n && s[z[i]] == s[i + z[i]]) z[i]++;
        if (i + z[i] > r) { l = i; r = i + z[i]; }          // la caja avanza
    }
    return z;
}
```

### `16/03` — Manacher [B]

De [`16/03` — Función Z y Manacher, §4](../16-cadenas/03-funcion-z-y-manacher.md#4--manacher).

```cpp
#include <algorithm>
#include <string>
#include <vector>

// len[i] (para i en la cadena intercalada de tamaño 2n + 1) = longitud del palíndromo más largo
// de s centrado ahí. Las posiciones pares son huecos entre letras; las impares, letras.
std::vector<int> manacher(const std::string& s) {
    std::string t = "#";
    for (char c : s) { t += c; t += '#'; }
    int n = t.size();
    std::vector<int> d(n, 0);
    for (int i = 0, l = 0, r = -1; i < n; i++) {
        int k = (i > r) ? 1 : std::min(d[l + r - i], r - i + 1);   // radio heredado del simétrico
        while (i - k >= 0 && i + k < n && t[i - k] == t[i + k]) k++;
        d[i] = k;
        if (i + k - 1 > r) { l = i - k + 1; r = i + k - 1; }
    }
    for (int& x : d) x--;                               // radio en t → longitud en s
    return d;
}
```

### `16/04` — Comparar subcadenas [B]

De [`16/04` — *Hashing* de cadenas aplicado, §3](../16-cadenas/04-hashing-de-cadenas.md#3--comparar-subcadenas).

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

### `16/04` — Binaria + *hash* [B]

De [`16/04` — *Hashing* de cadenas aplicado, §4](../16-cadenas/04-hashing-de-cadenas.md#4--binaria--hash).

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

### `16/05` — Aho-Corasick [B]

De [`16/05` — Aho-Corasick, §3](../16-cadenas/05-aho-corasick.md#3--aho-corasick).

```cpp
#include <array>
#include <queue>
#include <string>
#include <vector>

struct AhoCorasick {
    std::vector<std::array<int, 26>> go;               // autómata completo tras build()
    std::vector<int> fail, order;                      // order: nodos en BFS
    std::vector<int> endOf;                            // nodo terminal de cada patrón
    AhoCorasick() { newNode(); }
    int newNode() { go.push_back({}); go.back().fill(-1); fail.push_back(0); return go.size() - 1; }
    void add(const std::string& p) {
        int u = 0;
        for (char ch : p) {
            int c = ch - 'a';
            if (go[u][c] == -1) { int v = newNode(); go[u][c] = v; }
            u = go[u][c];
        }
        endOf.push_back(u);
    }
    void build() {
        std::queue<int> q;
        for (int c = 0; c < 26; c++)
            if (go[0][c] == -1) go[0][c] = 0;
            else { fail[go[0][c]] = 0; q.push(go[0][c]); }
        while (!q.empty()) {
            int u = q.front(); q.pop(); order.push_back(u);
            for (int c = 0; c < 26; c++) {
                int v = go[u][c];
                if (v == -1) go[u][c] = go[fail[u]][c];   // transición heredada del fallo
                else { fail[v] = go[fail[u]][c]; q.push(v); }
            }
        }
    }
    // Apariciones de cada patrón en t: visitas por nodo, propagadas de hijo a fallo en BFS inverso.
    std::vector<long long> count(const std::string& t) {
        std::vector<long long> visits(go.size(), 0);
        int u = 0;
        for (char ch : t) { u = go[u][ch - 'a']; visits[u]++; }
        for (int i = (int)order.size() - 1; i >= 0; i--) visits[fail[order[i]]] += visits[order[i]];
        std::vector<long long> res;
        for (int node : endOf) res.push_back(visits[node]);
        return res;
    }
};
```

### `16/06` — *Suffix array* en `O(n log n)` [B]

De [`16/06` — *Suffix array*, LCP y *suffix automaton*, §3](../16-cadenas/06-suffix-array-y-automaton.md#3--suffix-array-en-on-log-n).

```cpp
#include <algorithm>
#include <string>
#include <vector>

// Suffix array por duplicación con ordenación por conteo. Devuelve los n sufijos de s (sin el '$').
std::vector<int> suffixArray(std::string s) {
    s += '$';                                            // menor que cualquier letra
    int n = s.size(), classes = 256;
    std::vector<int> p(n), c(n), cnt(std::max(classes, n), 0);
    for (char ch : s) cnt[(unsigned char)ch]++;
    for (int i = 1; i < classes; i++) cnt[i] += cnt[i - 1];
    for (int i = n - 1; i >= 0; i--) p[--cnt[(unsigned char)s[i]]] = i;
    c[p[0]] = 0; classes = 1;
    for (int i = 1; i < n; i++) { if (s[p[i]] != s[p[i - 1]]) classes++; c[p[i]] = classes - 1; }
    std::vector<int> pn(n), cn(n);
    for (int h = 0; (1 << h) < n; h++) {
        for (int i = 0; i < n; i++) { pn[i] = p[i] - (1 << h); if (pn[i] < 0) pn[i] += n; }   // ya ordenados por la 2.ª mitad
        std::fill(cnt.begin(), cnt.begin() + classes, 0);
        for (int i = 0; i < n; i++) cnt[c[pn[i]]]++;
        for (int i = 1; i < classes; i++) cnt[i] += cnt[i - 1];
        for (int i = n - 1; i >= 0; i--) p[--cnt[c[pn[i]]]] = pn[i];                         // estable por la 1.ª
        cn[p[0]] = 0; classes = 1;
        for (int i = 1; i < n; i++) {
            int cur1 = c[p[i]], prev1 = c[p[i - 1]];
            int cur2 = c[(p[i] + (1 << h)) % n], prev2 = c[(p[i - 1] + (1 << h)) % n];
            if (cur1 != prev1 || cur2 != prev2) classes++;
            cn[p[i]] = classes - 1;
        }
        c.swap(cn);
    }
    p.erase(p.begin());                                  // el primero es el sufijo «$»
    return p;
}
```

### `16/06` — LCP de Kasai [B]

De [`16/06` — *Suffix array*, LCP y *suffix automaton*, §4](../16-cadenas/06-suffix-array-y-automaton.md#4--lcp-de-kasai).

```cpp
#include <string>
#include <vector>

// lcp[k] = prefijo común de los sufijos sa[k − 1] y sa[k]; lcp[0] = 0.
std::vector<int> kasai(const std::string& s, const std::vector<int>& sa) {
    int n = s.size(), h = 0;
    std::vector<int> rank(n), lcp(n, 0);
    for (int k = 0; k < n; k++) rank[sa[k]] = k;
    for (int i = 0; i < n; i++) {
        if (rank[i] == 0) { h = 0; continue; }
        int j = sa[rank[i] - 1];                         // el predecesor en el orden
        while (i + h < n && j + h < n && s[i + h] == s[j + h]) h++;
        lcp[rank[i]] = h;
        if (h > 0) h--;                                  // baja como mucho uno
    }
    return lcp;
}
```

### `16/07` — DFA y NFA [B]

De [`16/07` — Autómatas y expresiones regulares, §3](../16-cadenas/07-automatas-y-expresiones-regulares.md#3--dfa-y-nfa).

```cpp
#include <string>
#include <vector>

// Ejecuta un DFA: delta[q][c] con c ya traducido a índice; finales marcados.
bool runDfa(const std::vector<std::vector<int>>& delta, const std::vector<bool>& isFinal,
            const std::vector<int>& input) {
    int q = 0;
    for (int c : input) q = delta[q][c];
    return isFinal[q];
}

// DFA de «el número binario leído es múltiplo de k»: estado = resto; leer un bit b lleva a (2q + b) % k.
std::vector<std::vector<int>> multipleOfK(int k) {
    std::vector<std::vector<int>> delta(k, std::vector<int>(2));
    for (int q = 0; q < k; q++) for (int b = 0; b < 2; b++) delta[q][b] = (2 * q + b) % k;
    return delta;
}
```

### `16/07` — Thompson [B]

De [`16/07` — Autómatas y expresiones regulares, §4](../16-cadenas/07-automatas-y-expresiones-regulares.md#4--thompson).

```cpp
#include <stack>
#include <string>
#include <vector>

// NFA de Thompson (Sedgewick-Wayne): soporta letras, '.', '*', '|' y paréntesis. Coincidencia completa.
struct Nfa {
    std::string re;
    int m;
    std::vector<std::vector<int>> eps;                 // grafo de transiciones ε
    explicit Nfa(const std::string& regexp) : re("(" + regexp + ")"), m(re.size()), eps(re.size() + 1) {
        std::stack<int> ops;
        for (int i = 0; i < m; i++) {
            int lp = i;
            if (re[i] == '(' || re[i] == '|') ops.push(i);
            else if (re[i] == ')') {
                int orIdx = ops.top(); ops.pop();
                if (re[orIdx] == '|') { lp = ops.top(); ops.pop(); eps[lp].push_back(orIdx + 1); eps[orIdx].push_back(i); }
                else lp = orIdx;
            }
            if (i < m - 1 && re[i + 1] == '*') { eps[lp].push_back(i + 1); eps[i + 1].push_back(lp); }
            if (re[i] == '(' || re[i] == '*' || re[i] == ')') eps[i].push_back(i + 1);
        }
    }
    void closure(std::vector<bool>& active) const {    // añade todo lo alcanzable por ε
        std::vector<int> st;
        for (int v = 0; v <= m; v++) if (active[v]) st.push_back(v);
        while (!st.empty()) {
            int v = st.back(); st.pop_back();
            for (int w : eps[v]) if (!active[w]) { active[w] = true; st.push_back(w); }
        }
    }
    bool matches(const std::string& txt) const {
        std::vector<bool> active(m + 1, false);
        active[0] = true; closure(active);
        for (char c : txt) {
            std::vector<bool> next(m + 1, false);
            for (int v = 0; v < m; v++) if (active[v] && (re[v] == c || re[v] == '.')) next[v + 1] = true;
            closure(next);
            active.swap(next);
        }
        return active[m];
    }
};
```

### `16/07` — Subconjuntos [B]

De [`16/07` — Autómatas y expresiones regulares, §5](../16-cadenas/07-automatas-y-expresiones-regulares.md#5--subconjuntos).

```cpp
#include <cstdint>
#include <map>
#include <queue>
#include <vector>

// nfaMove[v][c] = máscara de estados alcanzados desde v leyendo c (ya con cierre ε aplicado);
// startMask = cierre ε del inicial. Devuelve la tabla del DFA (estados alcanzables) y sus máscaras.
std::vector<std::vector<int>> subsetConstruction(const std::vector<std::vector<uint64_t>>& nfaMove,
                                                 uint64_t startMask, int sigma, std::vector<uint64_t>& masks) {
    std::map<uint64_t, int> id;
    std::vector<std::vector<int>> delta;
    std::queue<uint64_t> q;
    id[startMask] = 0; masks = {startMask}; delta.push_back(std::vector<int>(sigma, -1)); q.push(startMask);
    while (!q.empty()) {
        uint64_t S = q.front(); q.pop();
        int from = id[S];
        for (int c = 0; c < sigma; c++) {
            uint64_t T = 0;
            for (int v = 0; v < 64; v++) if (S >> v & 1) T |= nfaMove[v][c];
            if (!id.count(T)) {
                id[T] = masks.size(); masks.push_back(T);
                delta.push_back(std::vector<int>(sigma, -1)); q.push(T);
            }
            delta[from][c] = id[T];
        }
    }
    return delta;
}
```

---

## 🧱 Bloque 17 — Matemática

### `17/01` — Operaciones y trucos [A]

De [`17/01` — Bits, §3](../17-matematica/01-bits.md#3--operaciones-y-trucos).

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

### `17/01` — `bitset` como optimización [B]

De [`17/01` — Bits, §4](../17-matematica/01-bits.md#4--bitset-como-optimización).

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

### `17/01` — Base XOR [B]

De [`17/01` — Bits, §5](../17-matematica/01-bits.md#5--base-xor).

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

### `17/02` — Euclides [A]

De [`17/02` — Divisibilidad, §3](../17-matematica/02-divisibilidad.md#3--euclides).

```cpp
#include <cstdint>
#include <numeric>

// C++17 tiene std::gcd y std::lcm en <numeric>; esta es la versión explícita.
long long gcdLL(long long a, long long b) {
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b) { long long t = a % b; a = b; b = t; }
    return a;
}
long long lcmLL(long long a, long long b) {
    if (a == 0 || b == 0) return 0;
    return a / gcdLL(a, b) * b;                          // dividir antes de multiplicar
}
```

### `17/02` — Euclides extendido [A]

De [`17/02` — Divisibilidad, §4](../17-matematica/02-divisibilidad.md#4--euclides-extendido).

```cpp
#include <tuple>

// Devuelve g = gcd(a, b) y x, y con a·x + b·y = g. a, b ≥ 0.
long long extGcd(long long a, long long b, long long& x, long long& y) {
    long long x0 = 1, y0 = 0, x1 = 0, y1 = 1;
    while (b) {
        long long q = a / b;
        std::tie(a, b) = std::make_tuple(b, a - q * b);
        std::tie(x0, x1) = std::make_tuple(x1, x0 - q * x1);
        std::tie(y0, y1) = std::make_tuple(y1, y0 - q * y1);
    }
    x = x0; y = y0;
    return a;
}
```

### `17/02` — Diofánticas lineales [A]

De [`17/02` — Divisibilidad, §5](../17-matematica/02-divisibilidad.md#5--diofánticas-lineales).

```cpp
// Necesita extGcd de §4. Cuenta las (x, y) enteras no negativas con a·x + b·y = c (a, b > 0, c ≥ 0).
long long extGcd(long long a, long long b, long long& x, long long& y);

long long countNonNegative(long long a, long long b, long long c) {
    long long x, y, g = extGcd(a, b, x, y);
    if (c % g) return 0;
    __int128 x0 = (__int128)x * (c / g), y0 = (__int128)y * (c / g);   // pueden pasar de 64 bits
    long long sx = b / g, sy = a / g;
    // x0 + sx·t ≥ 0  →  t ≥ ceil(−x0 / sx);   y0 − sy·t ≥ 0  →  t ≤ floor(y0 / sy)
    __int128 lo = -x0 >= 0 ? (-x0 + sx - 1) / sx : -((x0) / sx);
    __int128 hi = y0 >= 0 ? y0 / sy : -((-y0 + sy - 1) / sy);
    return hi >= lo ? (long long)(hi - lo + 1) : 0;
}
```

### `17/03` — Exponenciación modular [A]

De [`17/03` — Aritmética modular, §3](../17-matematica/03-aritmetica-modular.md#3--exponenciación-modular).

```cpp
#include <cstdint>

// a^e mod m, con m hasta ~3·10⁹ (el producto cabe en 64 bits sin signo). Para m hasta 10¹⁸, __int128.
long long powMod(long long a, long long e, long long m) {
    long long result = 1 % m;
    a %= m;
    if (a < 0) a += m;
    while (e > 0) {
        if (e & 1) result = (__int128)result * a % m;
        a = (__int128)a * a % m;
        e >>= 1;
    }
    return result;
}
```

### `17/03` — Inverso modular [A]

De [`17/03` — Aritmética modular, §4](../17-matematica/03-aritmetica-modular.md#4--inverso-modular).

```cpp
#include <vector>

long long powMod(long long a, long long e, long long m);        // la de §3
long long extGcd(long long a, long long b, long long& x, long long& y);   // la de 17/02

long long invFermat(long long a, long long p) { return powMod(a, p - 2, p); }   // p primo, p ∤ a

long long invExt(long long a, long long m) {                    // gcd(a, m) = 1; −1 si no existe
    long long x, y;
    if (extGcd(((a % m) + m) % m, m, x, y) != 1) return -1;
    return ((x % m) + m) % m;
}

std::vector<long long> inversesUpTo(int n, long long p) {       // inv[i] para 1 ≤ i ≤ n < p, p primo
    std::vector<long long> inv(n + 1);
    inv[1] = 1;
    for (int i = 2; i <= n; i++) inv[i] = (p - (p / i) * inv[p % i] % p) % p;
    return inv;
}
```

### `17/03` — Teorema chino del resto [B]

De [`17/03` — Aritmética modular, §5](../17-matematica/03-aritmetica-modular.md#5--teorema-chino-del-resto).

```cpp
long long extGcd(long long a, long long b, long long& x, long long& y);   // 17/02

// Combina x ≡ a1 (mod m1) y x ≡ a2 (mod m2). Devuelve false si son incompatibles.
// Resultado en a1, m1 (m1 pasa a ser el mcm). Supone que el mcm cabe en 64 bits.
bool crtMerge(long long& a1, long long& m1, long long a2, long long m2) {
    long long p, q, g = extGcd(m1, m2, p, q);            // m1·p + m2·q = g
    long long diff = a2 - a1;
    if (diff % g != 0) return false;
    long long m2g = m2 / g;
    long long t = (__int128)(diff / g) % m2g * (p % m2g) % m2g;   // t ≡ (diff/g)·p (mod m2/g)
    if (t < 0) t += m2g;
    long long lcm = m1 / g * m2;
    a1 = ((__int128)m1 * t + a1) % lcm;
    if (a1 < 0) a1 += lcm;
    m1 = lcm;
    return true;
}
```

### `17/04` — Criba de Eratóstenes [A]

De [`17/04` — Primos, §3](../17-matematica/04-primos.md#3--criba-de-eratóstenes).

```cpp
#include <vector>

// isPrime[i] para 0 ≤ i ≤ n. vector<char> es más rápido que vector<bool> para escribir.
std::vector<char> sieve(int n) {
    std::vector<char> isPrime(n + 1, 1);
    isPrime[0] = 0;
    if (n >= 1) isPrime[1] = 0;
    for (long long p = 2; p * p <= n; p++)
        if (isPrime[p])
            for (long long q = p * p; q <= n; q += p) isPrime[q] = 0;
    return isPrime;
}
```

### `17/04` — Criba lineal y menor factor primo [A]

De [`17/04` — Primos, §4](../17-matematica/04-primos.md#4--criba-lineal-y-menor-factor-primo).

```cpp
#include <utility>
#include <vector>

// spf[x] = menor factor primo de x (2 ≤ x ≤ n); primes = los primos hasta n.
void linearSieve(int n, std::vector<int>& spf, std::vector<int>& primes) {
    spf.assign(n + 1, 0);
    for (int i = 2; i <= n; i++) {
        if (spf[i] == 0) { spf[i] = i; primes.push_back(i); }
        for (int p : primes) {
            if (p > spf[i] || (long long)i * p > n) break;
            spf[i * p] = p;
        }
    }
}

// Factorización con spf: pares (primo, exponente).
std::vector<std::pair<int, int>> factorize(int x, const std::vector<int>& spf) {
    std::vector<std::pair<int, int>> f;
    while (x > 1) {
        int p = spf[x], e = 0;
        while (x % p == 0) { x /= p; e++; }
        f.push_back({p, e});
    }
    return f;
}
```

### `17/04` — Criba segmentada [B]

De [`17/04` — Primos, §5](../17-matematica/04-primos.md#5--criba-segmentada).

```cpp
#include <algorithm>
#include <vector>

// Marca de primalidad para [L, R] (R − L pequeño, R hasta ~10¹²). basePrimes: primos hasta √R.
std::vector<char> segmentedSieve(long long L, long long R, const std::vector<int>& basePrimes) {
    std::vector<char> isPrime(R - L + 1, 1);
    for (long long p : basePrimes) {
        if (p * p > R) break;
        long long start = std::max(p * p, (L + p - 1) / p * p);
        for (long long q = start; q <= R; q += p) isPrime[q - L] = 0;
    }
    if (L <= 1) for (long long x = L; x <= std::min(R, 1LL); x++) isPrime[x - L] = 0;
    return isPrime;
}
```

### `17/04` — La función φ [B]

De [`17/04` — Primos, §6](../17-matematica/04-primos.md#6--la-función-φ).

```cpp
#include <vector>

long long phi(long long n) {                             // O(√n)
    long long result = n;
    for (long long p = 2; p * p <= n; p++)
        if (n % p == 0) { while (n % p == 0) n /= p; result -= result / p; }
    if (n > 1) result -= result / n;
    return result;
}

std::vector<int> phiUpTo(int N) {                        // criba: φ de 0..N
    std::vector<int> ph(N + 1);
    for (int i = 0; i <= N; i++) ph[i] = i;
    for (int p = 2; p <= N; p++)
        if (ph[p] == p) for (int q = p; q <= N; q += p) ph[q] -= ph[q] / p;
    return ph;
}
```

### `17/04` — Miller-Rabin [B]

De [`17/04` — Primos, §7](../17-matematica/04-primos.md#7--miller-rabin).

```cpp
#include <cstdint>
#include <initializer_list>


uint64_t mulMod(uint64_t a, uint64_t b, uint64_t m) { return (unsigned __int128)a * b % m; }
uint64_t powMod64(uint64_t a, uint64_t e, uint64_t m) {
    uint64_t r = 1; a %= m;
    while (e) { if (e & 1) r = mulMod(r, a, m); a = mulMod(a, a, m); e >>= 1; }
    return r;
}

bool isPrime64(uint64_t n) {
    if (n < 2) return false;
    for (uint64_t p : {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}) if (n % p == 0) return n == p;
    uint64_t d = n - 1; int s = 0;
    while ((d & 1) == 0) { d >>= 1; s++; }
    for (uint64_t a : {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37}) {
        uint64_t x = powMod64(a, d, n);
        if (x == 1 || x == n - 1) continue;
        bool composite = true;
        for (int r = 1; r < s; r++) {
            x = mulMod(x, x, n);
            if (x == n - 1) { composite = false; break; }
        }
        if (composite) return false;                     // a es testigo
    }
    return true;
}
```

### `17/05` — `nCr` con factoriales [A]

De [`17/05` — Combinatoria, §3](../17-matematica/05-combinatoria.md#3--ncr-con-factoriales).

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

long long powMod(long long a, long long e, long long m);   // 17/03

struct Binomial {
    std::vector<long long> fact, invFact;
    explicit Binomial(int n) : fact(n + 1), invFact(n + 1) {
        fact[0] = 1;
        for (int i = 1; i <= n; i++) fact[i] = fact[i - 1] * i % MOD;
        invFact[n] = powMod(fact[n], MOD - 2, MOD);         // un solo Fermat
        for (int i = n; i > 0; i--) invFact[i - 1] = invFact[i] * i % MOD;
    }
    long long C(int n, int k) const {
        if (k < 0 || k > n) return 0;
        return fact[n] * invFact[k] % MOD * invFact[n - k] % MOD;
    }
};
```

### `17/05` — Lucas [B]

De [`17/05` — Combinatoria, §5](../17-matematica/05-combinatoria.md#5--lucas).

```cpp
#include <vector>

// C(n, k) mod p con p primo pequeño (p ≤ 10⁶): factoriales hasta p − 1 y Lucas.
struct Lucas {
    long long p;
    std::vector<long long> fact, invFact;
    explicit Lucas(long long prime) : p(prime), fact(prime), invFact(prime) {
        fact[0] = 1;
        for (long long i = 1; i < p; i++) fact[i] = fact[i - 1] * i % p;
        invFact[p - 1] = p - 1;                                          // Wilson: (p − 1)! ≡ −1
        for (long long i = p - 1; i > 0; i--) invFact[i - 1] = invFact[i] * i % p;
    }
    long long small(long long n, long long k) const {
        if (k < 0 || k > n) return 0;
        return fact[n] * invFact[k] % p * invFact[n - k] % p;
    }
    long long C(long long n, long long k) const {
        long long r = 1;
        while (n > 0 || k > 0) {
            r = r * small(n % p, k % p) % p;
            if (r == 0) return 0;
            n /= p; k /= p;
        }
        return r;
    }
};
```

### `17/05` — Catalan [B]

De [`17/05` — Combinatoria, §6](../17-matematica/05-combinatoria.md#6--catalan).

```cpp
// Con el Binomial de §3: C(2n, n) · inv(n + 1), o C(2n, n) − C(2n, n + 1).
long long catalan(const Binomial& b, int n) {
    return (b.C(2 * n, n) - b.C(2 * n, n + 1) + MOD) % MOD;
}
```

### `17/05` — Inclusión-exclusión [B]

De [`17/05` — Combinatoria, §7](../17-matematica/05-combinatoria.md#7--inclusión-exclusión).

```cpp
#include <numeric>
#include <vector>

// Cuántos x en [1, N] son múltiplos de al menos un ns[i]. El mcm se corta si pasa de N.
long long multiplesOfAny(long long N, const std::vector<long long>& ns) {
    int k = ns.size();
    long long total = 0;
    for (int mask = 1; mask < (1 << k); mask++) {
        long long l = 1;
        bool tooBig = false;
        for (int i = 0; i < k && !tooBig; i++)
            if (mask >> i & 1) {
                long long g = std::gcd(l, ns[i]);
                if ((__int128)(l / g) * ns[i] > N) tooBig = true;   // ya no hay múltiplos
                else l = l / g * ns[i];
            }
        if (tooBig) continue;
        total += (__builtin_popcount(mask) & 1) ? N / l : -(N / l);
    }
    return total;
}
```

### `17/06` — Linealidad de la esperanza [B]

De [`17/06` — Probabilidad y esperanza, §3](../17-matematica/06-probabilidad-y-esperanza.md#3--linealidad-de-la-esperanza).

```cpp
#include <vector>

const long long MOD = 1'000'000'007;
long long powMod(long long a, long long e, long long m);        // 17/03

// Número esperado de caras distintas en k tiradas de un dado justo de n caras, módulo MOD:
// n · (1 − ((n − 1)/n)^k), con las fracciones como productos por inversos. n no múltiplo de MOD.
long long expectedDistinct(long long n, long long k) {
    long long invN = powMod(n % MOD, MOD - 2, MOD);
    long long q = (n - 1) % MOD * invN % MOD;                    // probabilidad de no salir una cara
    long long notSeen = powMod(q, k, MOD);                       // … en k tiradas
    return n % MOD * ((1 - notSeen + MOD) % MOD) % MOD;          // linealidad sobre las n caras
}
```

### `17/06` — Indicadoras [B]

De [`17/06` — Probabilidad y esperanza, §4](../17-matematica/06-probabilidad-y-esperanza.md#4--indicadoras).

```cpp
#include <map>
#include <vector>

// Pares de valores distintos / 2: C(n, 2) menos los pares iguales, por el inverso de 2.
long long expectedInversions(const std::vector<long long>& a) {
    long long n = a.size();
    std::map<long long, long long> freq;
    for (long long v : a) freq[v]++;
    long long pairs = n * (n - 1) / 2 % MOD;
    for (auto& [v, c] : freq) pairs = (pairs - c * (c - 1) / 2 % MOD + MOD) % MOD;
    return pairs * ((MOD + 1) / 2) % MOD;                         // (MOD + 1)/2 es el inverso de 2
}
```

### `17/07` — Exponenciación [B]

De [`17/07` — Matrices y eliminación de Gauss, §3](../17-matematica/07-matrices-y-gauss.md#3--exponenciación).

```cpp
#include <vector>

using Matrix = std::vector<std::vector<long long>>;
const long long MOD = 1'000'000'007;

Matrix multiply(const Matrix& A, const Matrix& B) {
    int n = A.size(), m = B[0].size(), inner = B.size();
    Matrix C(n, std::vector<long long>(m, 0));
    for (int i = 0; i < n; i++)
        for (int k = 0; k < inner; k++) {                  // orden i-k-j: mejor localidad
            long long a = A[i][k];
            if (a == 0) continue;
            for (int j = 0; j < m; j++) C[i][j] = (C[i][j] + a * B[k][j]) % MOD;
        }
    return C;
}

Matrix matPow(Matrix A, long long k) {
    int n = A.size();
    Matrix R(n, std::vector<long long>(n, 0));
    for (int i = 0; i < n; i++) R[i][i] = 1;
    while (k > 0) {
        if (k & 1) R = multiply(R, A);
        A = multiply(A, A);
        k >>= 1;
    }
    return R;
}
```

### `17/07` — Gauss [B]

De [`17/07` — Matrices y eliminación de Gauss, §4](../17-matematica/07-matrices-y-gauss.md#4--gauss).

```cpp
#include <algorithm>
#include <vector>

long long powMod(long long a, long long e, long long m);   // 17/03

// Resuelve A x = b (mod MOD). a = matriz ampliada n × (m + 1). Devuelve 0 si no hay solución,
// 1 si es única y 2 si hay infinitas; en x, una solución (libres a 0).
int gaussMod(std::vector<std::vector<long long>> a, int m, std::vector<long long>& x) {
    int n = a.size(), row = 0;
    std::vector<int> where(m, -1);
    for (int col = 0; col < m && row < n; col++) {
        int sel = row;
        while (sel < n && a[sel][col] == 0) sel++;
        if (sel == n) continue;                                  // columna sin pivote: variable libre
        std::swap(a[sel], a[row]);
        where[col] = row;
        long long inv = powMod(a[row][col], MOD - 2, MOD);
        for (int j = col; j <= m; j++) a[row][j] = a[row][j] * inv % MOD;
        for (int i = 0; i < n; i++)
            if (i != row && a[i][col] != 0) {
                long long f = a[i][col];
                for (int j = col; j <= m; j++) a[i][j] = (a[i][j] - f * a[row][j] % MOD + MOD) % MOD;
            }
        row++;
    }
    x.assign(m, 0);
    for (int j = 0; j < m; j++) if (where[j] != -1) x[j] = a[where[j]][m];
    for (int i = row; i < n; i++) if (a[i][m] != 0) return 0;     // fila 0 … 0 | c ≠ 0
    for (int j = 0; j < m; j++) if (where[j] == -1) return 2;
    return 1;
}
```

### `17/07` — Sobre GF(2) [B]

De [`17/07` — Matrices y eliminación de Gauss, §5](../17-matematica/07-matrices-y-gauss.md#5--sobre-gf2).

```cpp
#include <bitset>
#include <vector>

const int MAXV = 1024;                                   // columnas + 1 (la de términos independientes)

// Filas como bitset: bits 0..m−1 coeficientes, bit m término independiente.
// Devuelve el rango, o −1 si el sistema es incompatible.
int gaussGF2(std::vector<std::bitset<MAXV>> a, int m) {
    int n = a.size(), row = 0;
    for (int col = 0; col < m && row < n; col++) {
        int sel = row;
        while (sel < n && !a[sel][col]) sel++;
        if (sel == n) continue;
        std::swap(a[sel], a[row]);
        for (int i = 0; i < n; i++) if (i != row && a[i][col]) a[i] ^= a[row];   // XOR de la fila entera
        row++;
    }
    for (int i = row; i < n; i++) if (a[i][m]) return -1;   // 0 … 0 | 1
    return row;                                          // soluciones: 2^(m − rango)
}
```

### `17/08` — Juegos sobre DAG [B]

De [`17/08` — Teoría de juegos, §3](../17-matematica/08-teoria-de-juegos.md#3--juegos-sobre-dag).

```cpp
#include <vector>

// win[v] = true si quien mueve desde v gana. adj = movimientos; el grafo es un DAG.
std::vector<int> memo;                                   // −1 sin calcular, 0 pierde, 1 gana
const std::vector<std::vector<int>>* G;

int wins(int v) {
    if (memo[v] != -1) return memo[v];
    int r = 0;
    for (int w : (*G)[v]) if (!wins(w)) { r = 1; break; }    // algún movimiento a una P
    return memo[v] = r;
}
// Con estados profundos, en orden topológico inverso en lugar de recursión (14/04).
```

### `17/08` — Nim [B]

De [`17/08` — Teoría de juegos, §4](../17-matematica/08-teoria-de-juegos.md#4--nim).

```cpp
#include <vector>

// Devuelve el índice del montón a reducir y su nuevo tamaño, o {−1, −1} si la posición es perdedora.
std::pair<int, long long> nimMove(const std::vector<long long>& piles) {
    long long s = 0;
    for (long long p : piles) s ^= p;
    if (s == 0) return {-1, -1};
    for (int i = 0; i < (int)piles.size(); i++)
        if ((piles[i] ^ s) < piles[i]) return {i, piles[i] ^ s};
    return {-1, -1};                                     // inalcanzable si s ≠ 0
}
```

### `17/08` — Sprague-Grundy [B]

De [`17/08` — Teoría de juegos, §5](../17-matematica/08-teoria-de-juegos.md#5--sprague-grundy).

```cpp
#include <vector>

// Grundy del juego de restar un elemento de S (de un montón), para 0..maxN.
std::vector<int> grundySubtraction(int maxN, const std::vector<int>& S) {
    std::vector<int> g(maxN + 1, 0);
    std::vector<char> seen(S.size() + 2);
    for (int n = 1; n <= maxN; n++) {
        std::fill(seen.begin(), seen.end(), 0);
        for (int s : S) if (s <= n && g[n - s] <= (int)S.size()) seen[g[n - s]] = 1;
        int m = 0;
        while (seen[m]) m++;                             // mex: el g de n es ≤ |S|
        g[n] = m;
    }
    return g;
}
// Suma de juegos: XOR de los g de las componentes; gana quien empieza si no es 0.
```

---

## 🧱 Bloque 18 — Geometría

### `18/01` — Vectores, punto y cruz [A]

De [`18/01` — Vectores, productos y orientación, §3](../18-geometria/01-vectores-y-orientacion.md#3--vectores-punto-y-cruz).

```cpp
struct Pt { long long x, y; };

Pt operator-(Pt a, Pt b) { return {a.x - b.x, a.y - b.y}; }
long long dot(Pt a, Pt b) { return a.x * b.x + a.y * b.y; }
long long cross(Pt a, Pt b) { return a.x * b.y - a.y * b.x; }
long long norm2(Pt a) { return dot(a, a); }               // |a|², sin raíz
```

### `18/01` — Orientación [A]

De [`18/01` — Vectores, productos y orientación, §4](../18-geometria/01-vectores-y-orientacion.md#4--orientación).

```cpp
// +1 si a→b→c gira a la izquierda, −1 a la derecha, 0 si están alineados.
int orient(Pt a, Pt b, Pt c) {
    long long v = cross(b - a, c - a);
    return (v > 0) - (v < 0);
}

// ¿p está dentro del triángulo abc, o en su borde? Vale con abc en cualquier sentido.
bool inTriangle(Pt a, Pt b, Pt c, Pt p) {
    int s1 = orient(a, b, p), s2 = orient(b, c, p), s3 = orient(c, a, p);
    bool neg = s1 < 0 || s2 < 0 || s3 < 0, pos = s1 > 0 || s2 > 0 || s3 > 0;
    return !(neg && pos);
}
```

### `18/01` — Enteros frente a épsilon [A]

De [`18/01` — Vectores, productos y orientación, §5](../18-geometria/01-vectores-y-orientacion.md#5--enteros-frente-a-épsilon).

```cpp
#include <cmath>

// Signo con tolerancia: el épsilon se escala con la magnitud de los datos.
int sgn(double v, double eps) { return (v > eps) - (v < -eps); }
```

### `18/02` — Intersección de segmentos [B]

De [`18/02` — Rectas y segmentos, §3](../18-geometria/02-rectas-y-segmentos.md#3--intersección-de-segmentos).

```cpp
#include <algorithm>
#include <utility>

// ¿p está en el segmento ab (extremos incluidos)?
bool onSegment(Pt a, Pt b, Pt p) {
    return orient(a, b, p) == 0
        && std::min(a.x, b.x) <= p.x && p.x <= std::max(a.x, b.x)
        && std::min(a.y, b.y) <= p.y && p.y <= std::max(a.y, b.y);
}

// ¿Los segmentos ab y cd tienen algún punto en común?
bool segmentsIntersect(Pt a, Pt b, Pt c, Pt d) {
    int o1 = orient(a, b, c), o2 = orient(a, b, d);
    int o3 = orient(c, d, a), o4 = orient(c, d, b);
    if (o1 * o2 < 0 && o3 * o4 < 0) return true;              // caso general
    return onSegment(a, b, c) || onSegment(a, b, d)           // colineales y extremos
        || onSegment(c, d, a) || onSegment(c, d, b);
}

// Punto de corte de las rectas ab y cd (no paralelas), en double.
std::pair<double, double> lineIntersection(Pt a, Pt b, Pt c, Pt d) {
    double t = (double) cross(c - a, d - c) / (double) cross(b - a, d - c);
    return {a.x + t * (b.x - a.x), a.y + t * (b.y - a.y)};
}
```

### `18/02` — Distancias [B]

De [`18/02` — Rectas y segmentos, §4](../18-geometria/02-rectas-y-segmentos.md#4--distancias).

```cpp
#include <cmath>

// Distancia de p al segmento ab (a ≠ b).
double distPointSegment(Pt p, Pt a, Pt b) {
    Pt ab = b - a, ap = p - a;
    long long len2 = norm2(ab);
    long long proj = dot(ap, ab);                              // t = proj / len2
    if (proj <= 0) return std::sqrt((double) norm2(ap));
    if (proj >= len2) return std::sqrt((double) norm2(p - b));
    return std::fabs((double) cross(ab, ap)) / std::sqrt((double) len2);
}

double distSegments(Pt a, Pt b, Pt c, Pt d) {
    if (segmentsIntersect(a, b, c, d)) return 0;
    return std::min({distPointSegment(a, c, d), distPointSegment(b, c, d),
                     distPointSegment(c, a, b), distPointSegment(d, a, b)});
}
```

### `18/03` — Fórmula del cordón [B]

De [`18/03` — Polígonos, §3](../18-geometria/03-poligonos.md#3--fórmula-del-cordón).

```cpp
#include <vector>

// Doble del área con signo: > 0 si los vértices van en sentido antihorario.
long long area2(const std::vector<Pt>& p) {
    __int128 s = 0;                        // las sumas parciales pueden pasar de 2⁶³
    int n = p.size();
    for (int i = 0; i < n; i++) s += cross(p[i], p[(i + 1) % n]);
    return (long long) s;
}
```

### `18/03` — Punto en polígono [B]

De [`18/03` — Polígonos, §4](../18-geometria/03-poligonos.md#4--punto-en-polígono).

```cpp
// 1 si p está dentro, 0 si está en el borde, −1 si está fuera.
int pointInPolygon(const std::vector<Pt>& poly, Pt p) {
    bool inside = false;
    int n = poly.size();
    for (int i = 0; i < n; i++) {
        Pt a = poly[i], b = poly[(i + 1) % n];
        if (onSegment(a, b, p)) return 0;
        if ((a.y > p.y) != (b.y > p.y)) {                   // el lado cruza la horizontal de p
            long long o = cross(b - a, p - a);
            if ((o > 0) == (b.y > a.y)) inside = !inside;   // y el cruce está a la derecha de p
        }
    }
    return inside ? 1 : -1;
}
```

### `18/03` — Pick [B]

De [`18/03` — Polígonos, §5](../18-geometria/03-poligonos.md#5--pick).

```cpp
#include <cstdlib>
#include <numeric>
#include <utility>

// Puntos enteros en el borde y en el interior de un polígono simple con vértices enteros.
std::pair<long long, long long> latticePoints(const std::vector<Pt>& p) {
    long long b = 0;
    int n = p.size();
    for (int i = 0; i < n; i++) {
        Pt d = p[(i + 1) % n] - p[i];
        b += std::gcd(std::llabs(d.x), std::llabs(d.y));
    }
    long long a2 = std::llabs(area2(p));
    return {b, (a2 - b + 2) / 2};                          // I = (2A − B + 2) / 2
}
```

### `18/03` — Rectángulos: lo que sí te pueden preguntar [B]

De [`18/03` — Polígonos, §6](../18-geometria/03-poligonos.md#6--rectángulos-lo-que-sí-te-pueden-preguntar).

```cpp
#include <algorithm>

// Área de la intersección de dos rectángulos {x1, y1, x2, y2} con x1 < x2, y1 < y2.
long long overlapArea(const long long r[4], const long long s[4]) {
    long long w = std::min(r[2], s[2]) - std::max(r[0], s[0]);
    long long h = std::min(r[3], s[3]) - std::max(r[1], s[1]);
    return (w > 0 && h > 0) ? w * h : 0;
}
```

### `18/04` — Cadena monótona de Andrew [B]

De [`18/04` — Envolvente convexa, §3](../18-geometria/04-envolvente-convexa.md#3--cadena-monótona-de-andrew).

```cpp
#include <algorithm>
#include <vector>

// Envolvente convexa en sentido antihorario, sin repetir el primer vértice.
// keepCollinear: conserva los puntos alineados sobre los lados (exige que no estén todos alineados).
std::vector<Pt> convexHull(std::vector<Pt> pts, bool keepCollinear = false) {
    std::sort(pts.begin(), pts.end(), [](Pt a, Pt b) { return a.x != b.x ? a.x < b.x : a.y < b.y; });
    pts.erase(std::unique(pts.begin(), pts.end(),
                          [](Pt a, Pt b) { return a.x == b.x && a.y == b.y; }), pts.end());
    int n = pts.size();
    if (n <= 2) return pts;
    std::vector<Pt> h(2 * n);
    int k = 0;
    auto bad = [&](Pt a, Pt b, Pt c) {                   // ¿hay que desapilar b?
        int o = orient(a, b, c);
        return keepCollinear ? o < 0 : o <= 0;
    };
    for (int i = 0; i < n; i++) {                        // cadena inferior
        while (k >= 2 && bad(h[k - 2], h[k - 1], pts[i])) k--;
        h[k++] = pts[i];
    }
    for (int i = n - 2, low = k + 1; i >= 0; i--) {      // cadena superior
        while (k >= low && bad(h[k - 2], h[k - 1], pts[i])) k--;
        h[k++] = pts[i];
    }
    h.resize(k - 1);                                     // el último repite el primero
    return h;
}
```

### `18/05` — Par más cercano [B]

De [`18/05` — Barrido geométrico, §3](../18-geometria/05-barrido-geometrico.md#3--par-más-cercano).

```cpp
#include <algorithm>
#include <climits>
#include <cmath>
#include <set>
#include <utility>
#include <vector>

// Menor distancia al cuadrado entre dos de los puntos (n ≥ 2).
long long closestPair(std::vector<Pt> pts) {
    std::sort(pts.begin(), pts.end(), [](Pt a, Pt b) { return a.x < b.x; });
    std::set<std::pair<long long, long long>> active;            // (y, x) de los activos
    long long best = LLONG_MAX;
    int left = 0;
    for (int i = 0; i < (int) pts.size(); i++) {
        long long d = (long long) std::sqrt((double) best) + 1;  // ancho de la ventana, por exceso
        while (pts[i].x - pts[left].x > d) {                     // salen los que quedaron lejos en x
            active.erase({pts[left].y, pts[left].x});
            left++;
        }
        auto it = active.lower_bound({pts[i].y - d, LLONG_MIN});
        for (; it != active.end() && it->first <= pts[i].y + d; ++it) {
            long long dx = pts[i].x - it->second, dy = pts[i].y - it->first;
            best = std::min(best, dx * dx + dy * dy);
        }
        active.insert({pts[i].y, pts[i].x});
    }
    return best;
}
```

---

## 🧱 Bloque 19 — Aleatorizados y probabilísticos

### `19/01` — Freivalds [B]

De [`19/01` — Las Vegas y Monte Carlo, §6](../19-aleatorizados-y-probabilisticos/01-las-vegas-y-monte-carlo.md#6--freivalds).

```cpp
#include <chrono>
#include <random>
#include <vector>

using Matrix = std::vector<std::vector<long long>>;

std::vector<long long> mulVec(const Matrix& m, const std::vector<long long>& v) {
    int n = m.size();
    std::vector<long long> res(n, 0);
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++) res[i] += m[i][k] * v[k];
    return res;
}

// ¿AB = C? Si responde false, seguro que no; si responde true, se equivoca con prob. ≤ 2^−rounds.
bool freivalds(const Matrix& a, const Matrix& b, const Matrix& c, int rounds = 30) {
    static std::mt19937_64 rng(std::chrono::steady_clock::now().time_since_epoch().count());
    int n = a.size();
    for (int t = 0; t < rounds; t++) {
        std::vector<long long> r(n);
        for (auto& x : r) x = rng() & 1;                     // r uniforme en {0, 1}ⁿ
        if (mulVec(a, mulVec(b, r)) != mulVec(c, r)) return false;
    }
    return true;
}
```

### `19/02` — *Hashing* universal [B]

De [`19/02` — *Hashing* universal y análisis esperado, §3](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md#3--hashing-universal).

```cpp
#include <chrono>
#include <cstdint>
#include <random>

// Familia de Carter y Wegman: h(x) = ((a·x + b) mod p) mod m, para 0 ≤ x < p.
struct UniversalHash {
    static constexpr uint64_t P = 2147483647;            // 2³¹ − 1, primo
    uint64_t a, b, m;
    explicit UniversalHash(uint64_t buckets) : m(buckets) {
        std::mt19937_64 rng(std::chrono::steady_clock::now().time_since_epoch().count());
        a = 1 + rng() % (P - 1);
        b = rng() % P;
    }
    uint64_t operator()(uint64_t x) const { return ((a * x + b) % P) % m; }   // a·x < 2⁶²
};
```

### `19/03` — Bloom [B]

De [`19/03` — Estructuras probabilísticas, §3](../19-aleatorizados-y-probabilisticos/03-estructuras-probabilisticas.md#3--bloom).

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

### `19/03` — Count-Min [B]

De [`19/03` — Estructuras probabilísticas, §4](../19-aleatorizados-y-probabilisticos/03-estructuras-probabilisticas.md#4--count-min).

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

### `19/04` — Fisher-Yates [A]

De [`19/04` — Muestreo y cadenas de Markov, §3](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#3--fisher-yates).

```cpp
#include <chrono>
#include <random>
#include <utility>
#include <vector>

void fisherYates(std::vector<int>& a, std::mt19937_64& rng) {
    for (int i = (int) a.size() - 1; i > 0; i--) {
        std::uniform_int_distribution<int> pick(0, i);     // j en [0, i], incluido i
        std::swap(a[i], a[pick(rng)]);
    }
}
// std::shuffle(a.begin(), a.end(), rng) hace lo mismo.
```

### `19/04` — *Reservoir* [B]

De [`19/04` — Muestreo y cadenas de Markov, §4](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#4--reservoir).

```cpp
#include <random>
#include <vector>

// Muestra uniforme de k elementos de un flujo; next() devuelve false al terminar.
template <class Source>
std::vector<long long> reservoir(Source next, int k, std::mt19937_64& rng) {
    std::vector<long long> sample;
    long long x, seen = 0;
    while (next(x)) {
        seen++;
        if ((long long) sample.size() < k) { sample.push_back(x); continue; }
        std::uniform_int_distribution<long long> pick(0, seen - 1);
        long long j = pick(rng);
        if (j < k) sample[j] = x;                            // entra con probabilidad k/seen
    }
    return sample;
}
```

---

## 🧱 Bloque 20 — Ad hoc, constructivos e interactivos

### `20/02` — Constructivos [B]

De [`20/02` — Constructivos, §3](../20-ad-hoc-constructivos-e-interactivos/02-constructivos.md#3--constructivos).

```cpp
#include <utility>
#include <vector>

// Calendario de todos contra todos con n par: n − 1 jornadas de n/2 partidos.
std::vector<std::vector<std::pair<int, int>>> roundRobin(int n) {
    int m = n - 1;                                         // equipos del círculo: 0 .. n − 2
    std::vector<std::vector<std::pair<int, int>>> rounds(m);
    for (int r = 0; r < m; r++) {
        rounds[r].push_back({r, n - 1});                   // el fijo contra r
        for (int k = 1; k < n / 2; k++)
            rounds[r].push_back({(r + k) % m, (r - k + m) % m});
    }
    return rounds;
}

// Verificador: cada par exactamente una vez y nadie dos veces en la misma jornada.
bool checkRoundRobin(int n, const std::vector<std::vector<std::pair<int, int>>>& rounds) {
    std::vector<std::vector<int>> met(n, std::vector<int>(n, 0));
    for (const auto& round : rounds) {
        std::vector<bool> busy(n, false);
        for (auto [a, b] : round) {
            if (a == b || busy[a] || busy[b]) return false;
            busy[a] = busy[b] = true;
            met[a][b]++; met[b][a]++;
        }
    }
    for (int a = 0; a < n; a++)
        for (int b = a + 1; b < n; b++)
            if (met[a][b] != 1) return false;
    return true;
}
```

### `20/03` — El protocolo y el *flush* [B]

De [`20/03` — Interactivos, §3](../20-ad-hoc-constructivos-e-interactivos/03-interactivos.md#3--el-protocolo-y-el-flush).

```cpp
#include <iostream>
#include <string>

// Pregunta «? x» y devuelve la respuesta. std::endl escribe el salto de línea y vacía el búfer.
std::string ask(long long x) {
    std::cout << "? " << x << std::endl;
    std::string reply;
    std::cin >> reply;
    if (reply == "-1") std::exit(0);                      // pregunta inválida o de más: terminar ya
    return reply;
}

void answer(long long x) { std::cout << "! " << x << std::endl; }
```

### `20/03` — Binaria interactiva [B]

De [`20/03` — Interactivos, §4](../20-ad-hoc-constructivos-e-interactivos/03-interactivos.md#4--binaria-interactiva).

```cpp
// Secreto en [1, n]; ask(x) responde "YES" si el secreto es mayor que x.
long long findSecret(long long n) {
    long long lo = 1, hi = n;
    while (lo < hi) {
        long long mid = lo + (hi - lo) / 2;
        if (ask(mid) == "YES") lo = mid + 1;              // el secreto está a la derecha de mid
        else hi = mid;                                     // el secreto es ≤ mid
    }
    return lo;
}
```

### `20/05` — Recocido simulado [B]

De [`20/05` — Heurísticos y aproximados, §4](../20-ad-hoc-constructivos-e-interactivos/05-heuristicos-y-aproximados.md#4--recocido-simulado).

```cpp
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <numeric>
#include <random>
#include <vector>

struct P2 { double x, y; };

double dist(const P2& a, const P2& b) { return std::hypot(a.x - b.x, a.y - b.y); }

// Recocido simulado para el viajante con movimientos 2-opt (invertir un tramo del recorrido).
// La temperatura baja de forma geométrica de t0 a t1 a lo largo de las iteraciones.
std::vector<int> annealTSP(const std::vector<P2>& p, long long iterations, double t0, double t1, uint64_t seed) {
    int n = p.size();
    std::vector<int> tour(n);
    std::iota(tour.begin(), tour.end(), 0);
    if (n < 4) return tour;
    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<double> unif(0.0, 1.0);
    for (long long it = 0; it < iterations; it++) {
        double temp = t0 * std::pow(t1 / t0, (double) it / iterations);
        int i = rng() % n, j = rng() % n;
        if (i > j) std::swap(i, j);
        if (j - i < 2 || (i == 0 && j == n - 1)) continue;          // tramo vacío o el recorrido entero
        int a = tour[i], b = tour[i + 1], c = tour[j], d = tour[(j + 1) % n];
        double delta = dist(p[a], p[c]) + dist(p[b], p[d]) - dist(p[a], p[b]) - dist(p[c], p[d]);
        if (delta <= 0 || unif(rng) < std::exp(-delta / temp))       // acepta peores con prob. e^(−Δ/T)
            std::reverse(tour.begin() + i + 1, tour.begin() + j + 1);
    }
    return tour;
}
```

---

## 🧱 Bloque 22 — Teoría de la computación (opcional)

### `22/02` — CYK [B]

De [`22/02` — Autómatas de pila, §5](../22-teoria-de-la-computacion/02-automatas-de-pila.md#5--cyk).

```cpp
#include <array>
#include <cstdint>
#include <string>
#include <vector>

// CYK. unit = {A, a} por cada A → a; bin = {A, B, C} por cada A → B C. O(n³ · |bin|).
bool cyk(const std::vector<std::pair<int, char>>& unit, const std::vector<std::array<int, 3>>& bin,
         const std::string& w) {
    int n = w.size();
    if (n == 0) return false;                       // la vacía se trata aparte (S₀ → ε)
    std::vector<std::vector<uint64_t>> t(n, std::vector<uint64_t>(n, 0));
    for (int i = 0; i < n; i++)
        for (auto [a, c] : unit) if (c == w[i]) t[i][i] |= 1ULL << a;
    for (int len = 2; len <= n; len++)
        for (int i = 0; i + len - 1 < n; i++) {
            int j = i + len - 1;
            for (int k = i; k < j; k++)
                for (const auto& r : bin)
                    if ((t[i][k] >> r[1] & 1) && (t[k + 1][j] >> r[2] & 1)) t[i][j] |= 1ULL << r[0];
        }
    return t[0][n - 1] & 1;                         // ¿la variable inicial genera w entera?
}
```

### `22/03` — La máquina de Turing y su simulación [A]

De [`22/03` — Máquinas de Turing y decidibilidad, §3](../22-teoria-de-la-computacion/03-maquinas-de-turing-y-decidibilidad.md#3--la-máquina-de-turing-y-su-simulación).

```cpp
#include <map>
#include <string>
#include <utility>
#include <vector>

struct Rule { char write; int move; int next; };          // move: −1 izquierda, +1 derecha

// Simula una MT de una cinta desde el estado 0. Devuelve el estado final, o −1 si agotó 'limit'.
// Deja en 'steps' los pasos dados y en 'tape' la cinta final (si agotó el límite, 'tape' no se toca).
int runTm(const std::map<std::pair<int, char>, Rule>& delta, int halt, std::string& tape,
          char blank, long long limit, long long& steps) {
    std::vector<char> left, right(tape.rbegin(), tape.rend());   // la cima de cada pila toca la cabeza
    char cur = blank;
    if (!right.empty()) { cur = right.back(); right.pop_back(); }
    int q = 0;
    for (steps = 0; q != halt; steps++) {
        if (steps == limit) return -1;
        auto it = delta.find({q, cur});
        if (it == delta.end()) break;                           // sin transición: se detiene
        const Rule& r = it->second;
        std::vector<char>& from = r.move > 0 ? right : left;    // de dónde sale la celda nueva
        std::vector<char>& to = r.move > 0 ? left : right;      // dónde queda la que se escribió
        to.push_back(r.write);
        if (from.empty()) cur = blank; else { cur = from.back(); from.pop_back(); }
        q = r.next;
    }
    tape.assign(left.begin(), left.end());
    tape.push_back(cur);
    tape.append(right.rbegin(), right.rend());
    return q;
}
```

### `22/04` — P y NP por certificados [A]

De [`22/04` — P, NP y reducciones, §3](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#3--p-y-np-por-certificados).

```cpp
#include <utility>
#include <vector>

// Verificador de NP para la cobertura de vértices: ¿S es una cobertura de tamaño ≤ k? O(n + m).
bool verifyCover(int n, const std::vector<std::pair<int, int>>& edges, const std::vector<int>& cover, int k) {
    if ((int) cover.size() > k) return false;
    std::vector<bool> in(n, false);
    for (int v : cover) in[v] = true;
    for (auto [u, v] : edges) if (!in[u] && !in[v]) return false;   // arista sin cubrir
    return true;
}
```

### `22/04` — Reducciones polinomiales [B]

De [`22/04` — P, NP y reducciones, §4](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#4--reducciones-polinomiales).

```cpp
#include <utility>
#include <vector>

// Reducción IS(G, k) ≤ₚ CLIQUE(Ḡ, k): el complemento, como matriz. O(n²).
std::vector<std::vector<bool>> complementGraph(int n, const std::vector<std::pair<int, int>>& edges) {
    std::vector<std::vector<bool>> adj(n, std::vector<bool>(n, true));
    for (int v = 0; v < n; v++) adj[v][v] = false;                 // sin lazos
    for (auto [u, v] : edges) adj[u][v] = adj[v][u] = false;       // lo que estaba, desaparece
    return adj;
}
```

### `22/05` — La cadena de reducciones clásicas [B]

De [`22/05` — NP-completitud, §4](../22-teoria-de-la-computacion/05-np-completitud.md#4--la-cadena-de-reducciones-clásicas).

```cpp
#include <array>
#include <utility>
#include <vector>

// 3-SAT con m cláusulas → grafo de 3m vértices; φ es satisfacible ⇔ hay un independiente de tamaño m.
// El vértice 3i + j es el literal j de la cláusula i.
std::vector<std::pair<int, int>> satToIndependentSet(const std::vector<std::array<int, 3>>& clauses) {
    int m = clauses.size();
    std::vector<std::pair<int, int>> edges;
    for (int i = 0; i < m; i++) {                                     // el triángulo de la cláusula
        edges.push_back({3 * i, 3 * i + 1});
        edges.push_back({3 * i + 1, 3 * i + 2});
        edges.push_back({3 * i, 3 * i + 2});
    }
    for (int i = 0; i < m; i++)                                       // conflictos entre cláusulas
        for (int k = i + 1; k < m; k++)
            for (int j = 0; j < 3; j++)
                for (int l = 0; l < 3; l++)
                    if (clauses[i][j] == -clauses[k][l]) edges.push_back({3 * i + j, 3 * k + l});
    return edges;
}
```

### `22/05` — Qué hacer con un NP-difícil [A]

De [`22/05` — NP-completitud, §6](../22-teoria-de-la-computacion/05-np-completitud.md#6--qué-hacer-con-un-np-difícil).

```cpp
#include <cstdint>
#include <vector>

// ¿Hay ciclo hamiltoniano? adj[v] = máscara de vecinos de v. O(2ⁿ · n) tiempo, 2ⁿ enteros de memoria; n ≤ 24.
bool hamiltonianCycle(const std::vector<uint32_t>& adj) {
    int n = adj.size();
    if (n < 3) return false;
    std::vector<uint32_t> reach(1u << n, 0);
    reach[1] = 1;                                                   // el camino «0» termina en 0
    for (uint32_t mask = 3; mask < (1u << n); mask += 2)            // máscaras con el 0 y algo más
        for (int w = 1; w < n; w++)
            if ((mask >> w & 1) && (reach[mask ^ (1u << w)] & adj[w]))
                reach[mask] |= 1u << w;                             // se llega a w desde un vecino
    return reach[(1u << n) - 1] & adj[0];                           // algún final vuelve a 0
}
```

### `22/06` — Análisis léxico [B]

De [`22/06` — Análisis léxico y gramáticas simples, §3](../22-teoria-de-la-computacion/06-analisis-lexico-y-gramaticas-simples.md#3--análisis-léxico).

```cpp
#include <cctype>
#include <stdexcept>
#include <string>
#include <vector>

enum class Kind { Num, Ident, Op, End };
struct Token { Kind kind; std::string text; int pos; };

// Lexer escrito como DFA implícito: una rama por clase de lexema, coincidencia más larga. Θ(n).
std::vector<Token> tokenize(const std::string& s) {
    std::vector<Token> out;
    size_t i = 0;
    while (i < s.size()) {
        unsigned char c = s[i];
        if (std::isspace(c)) { i++; continue; }                        // los blancos no son tokens
        size_t start = i;
        if (std::isdigit(c)) {
            while (i < s.size() && std::isdigit((unsigned char) s[i])) i++;
            out.push_back({Kind::Num, s.substr(start, i - start), (int) start});
        } else if (std::isalpha(c) || c == '_') {
            while (i < s.size() && (std::isalnum((unsigned char) s[i]) || s[i] == '_')) i++;
            out.push_back({Kind::Ident, s.substr(start, i - start), (int) start});
        } else if (std::string("+-*/^()=").find(c) != std::string::npos) {
            i++;
            out.push_back({Kind::Op, std::string(1, (char) c), (int) start});
        } else {
            throw std::runtime_error("carácter inesperado en la posición " + std::to_string(start));
        }
    }
    out.push_back({Kind::End, "", (int) s.size()});                    // centinela: simplifica el parser
    return out;
}
```

### `22/06` — Descenso recursivo [B]

De [`22/06` — Análisis léxico y gramáticas simples, §5](../22-teoria-de-la-computacion/06-analisis-lexico-y-gramaticas-simples.md#5--descenso-recursivo).

```cpp
// Descenso recursivo con evaluación; sigue la gramática de §4. Θ(número de tokens).
struct Parser {
    std::vector<Token> toks;
    size_t p = 0;
    explicit Parser(std::vector<Token> t) : toks(std::move(t)) {}

    bool accept(const char* op) {                                  // consume el operador si es el siguiente
        if (toks[p].kind == Kind::Op && toks[p].text == op) { p++; return true; }
        return false;
    }
    [[noreturn]] void fail(const std::string& what) {
        throw std::runtime_error(what + " en la posición " + std::to_string(toks[p].pos));
    }
    long long parse() {
        long long v = expr();
        if (toks[p].kind != Kind::End) fail("sobra entrada");
        return v;
    }
    long long expr() {                                             // expr → term { ('+' | '-') term }
        long long v = term();
        while (true) {
            if (accept("+")) v += term();
            else if (accept("-")) v -= term();
            else return v;
        }
    }
    long long term() {                                             // term → unary { ('*' | '/') unary }
        long long v = unary();
        while (true) {
            if (accept("*")) v *= unary();
            else if (accept("/")) {
                long long d = unary();
                if (d == 0) fail("división por cero");
                v /= d;                                            // trunca hacia cero
            } else return v;
        }
    }
    long long unary() { return accept("-") ? -unary() : power(); }
    long long power() {                                            // power → atom [ '^' unary ]
        long long base = atom();
        if (!accept("^")) return base;
        long long e = unary();                                     // recursión: asociativa por la derecha
        if (e < 0) fail("exponente negativo");
        long long r = 1;
        for (; e > 0; e >>= 1) {                                   // exponenciación rápida (10/05)
            if (e & 1) r *= base;                                  // sin control de desbordamiento
            if (e > 1) base *= base;
        }
        return r;
    }
    long long atom() {
        if (toks[p].kind == Kind::Num) return std::stoll(toks[p++].text);
        if (accept("(")) {
            long long v = expr();
            if (!accept(")")) fail("se esperaba ')'");
            return v;
        }
        fail("se esperaba un número o '('");
    }
};
```
