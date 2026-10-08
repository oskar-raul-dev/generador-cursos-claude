# 02 — Cuaderno de Java

> **Opcional.** Las plantillas de nivel A y B del corpus, en Java, sin explicación y listas para copiar. Cada una lleva el enlace a la sección
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

```java
import java.io.*;
import java.util.*;

public class Main {
    public static void main(String[] args) throws IOException {
        FastReader in = new FastReader(System.in);
        PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(System.out)));

        int n = in.nextInt();
        long[] a = new long[n];
        for (int i = 0; i < n; i++) a[i] = in.nextLong();

        long sum = 0;                   // aquí va la solución
        for (long x : a) sum += x;

        out.println(sum);
        out.flush();                    // sin esto, la salida se queda en el búfer
    }

    static class FastReader {
        private final BufferedReader br;
        private StringTokenizer st;

        FastReader(InputStream is) {
            br = new BufferedReader(new InputStreamReader(is), 1 << 16);
        }

        String next() throws IOException {
            while (st == null || !st.hasMoreTokens()) {
                String line = br.readLine();
                if (line == null) return null;   // fin de la entrada
                st = new StringTokenizer(line);
            }
            return st.nextToken();
        }

        int nextInt() throws IOException { return Integer.parseInt(next()); }
        long nextLong() throws IOException { return Long.parseLong(next()); }
    }
}
```

### `01/05` — El *stress test* [A]

De [`01/05` — Probar sin IDE: casos borde, depuración y *stress test*, §4](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md#4--el-stress-test).

```java
import java.util.Random;

public class Gen {
    public static void main(String[] args) {
        Random rng = new Random(Long.parseLong(args[0]));   // la semilla la pasa el arnés
        int n = 1 + rng.nextInt(8);                          // de 1 a 8
        StringBuilder sb = new StringBuilder().append(n).append('\n');
        for (int i = 0; i < n; i++) sb.append(rng.nextInt(11) - 5).append(i + 1 < n ? ' ' : '\n');
        System.out.print(sb);
    }
}
```

---

## 🧱 Bloque 02 — Análisis

### `02/03` — El método agregado [A]

De [`02/03` — Análisis amortizado, §3](../02-analisis/03-analisis-amortizado.md#3--el-método-agregado).

```java
// Arreglo dinámico de int: push O(1) amortizado, get O(1) en el caso peor.
final class IntArrayList {
    private int[] data = new int[1];
    private int size = 0;

    void push(int x) {
        if (size == data.length)
            data = java.util.Arrays.copyOf(data, 2 * data.length);   // duplica: copia size elementos
        data[size++] = x;
    }

    int get(int i) {
        if (i < 0 || i >= size) throw new IndexOutOfBoundsException(i);
        return data[i];
    }

    int size() { return size; }
}
```

### `02/04` — Invariante de bucle [A]

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §3](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#3--invariante-de-bucle).

```java
// Primer índice i en [0, n] con a[i] >= x (lower bound). Pre: a ordenado de forma no decreciente.
static int lowerBound(int[] a, int x) {
    int lo = 0, hi = a.length;
    // Invariante: a[0..lo) < x  y  a[hi..n) >= x.  Cota: hi - lo, que baja en cada vuelta.
    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;     // lo <= mid < hi
        if (a[mid] < x) lo = mid + 1;     // a[0..mid] < x: el invariante se mantiene
        else hi = mid;                    // a[mid..n) >= x: el invariante se mantiene
    }
    return lo;                            // lo == hi: la frontera exacta
}
```

### `02/04` — Argumento de intercambio [A]

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §5](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#5--argumento-de-intercambio).

```java
// Máximo número de intervalos [s, f) disjuntos. Θ(n log n) por la ordenación.
static int maxDisjoint(int[][] intervals) {
    int[][] byEnd = intervals.clone();
    java.util.Arrays.sort(byEnd, (p, q) -> Integer.compare(p[1], q[1]));
    int count = 0;
    long lastEnd = Long.MIN_VALUE;                 // final del último elegido
    for (int[] iv : byEnd) {
        if (iv[0] >= lastEnd) {                    // semiabierto: empezar justo al terminar vale
            count++;
            lastEnd = iv[1];
        }
    }
    return count;
}
```

### `02/05` — Caché y localidad [B]

De [`02/05` — El coste real, §3](../02-analisis/05-el-coste-real.md#3--caché-y-localidad).

```java
// En Java, int[][] es un arreglo de filas: cada fila es contigua, las filas no lo son entre sí.
static long sumByRows(int[][] m) {
    long s = 0;
    for (int[] row : m)
        for (int x : row) s += x;          // contiguo dentro de cada fila
    return s;
}
```

### `02/06` — TDA, contrato e invariante de representación [A]

De [`02/06` — Tipos abstractos de datos, §3](../02-analisis/06-tipos-abstractos-de-datos.md#3--tda-contrato-e-invariante-de-representación).

```java
// El contrato: una cola de enteros. Pre de dequeue y peek: !isEmpty().
interface IntQueue {
    void enqueue(int x);
    int dequeue();
    int peek();
    boolean isEmpty();
    int size();
}

// Arreglo circular. Invariante: 0 <= size <= data.length, 0 <= head < data.length;
// los elementos son data[(head + i) % data.length] para i en [0, size).
final class RingBufferQueue implements IntQueue {
    private int[] data = new int[4];
    private int head = 0, size = 0;

    public void enqueue(int x) {
        if (size == data.length) grow();
        data[(head + size) % data.length] = x;
        size++;
    }

    public int dequeue() {
        int x = peek();
        head = (head + 1) % data.length;
        size--;
        return x;
    }

    public int peek() {
        if (size == 0) throw new java.util.NoSuchElementException();
        return data[head];
    }

    public boolean isEmpty() { return size == 0; }
    public int size() { return size; }

    private void grow() {                       // copia en orden lógico: la cabeza vuelve a 0
        int[] bigger = new int[2 * data.length];
        for (int i = 0; i < size; i++) bigger[i] = data[(head + i) % data.length];
        data = bigger;
        head = 0;
    }
}

// Lista enlazada simple. Invariante: size nodos desde head; tail es el último (o null si size == 0).
final class LinkedQueue implements IntQueue {
    private static final class Node { int value; Node next; Node(int v) { value = v; } }
    private Node head, tail;
    private int size = 0;

    public void enqueue(int x) {
        Node node = new Node(x);
        if (tail == null) head = node; else tail.next = node;
        tail = node;
        size++;
    }

    public int dequeue() {
        int x = peek();
        head = head.next;
        if (head == null) tail = null;          // la cola quedó vacía: tail también
        size--;
        return x;
    }

    public int peek() {
        if (size == 0) throw new java.util.NoSuchElementException();
        return head.value;
    }

    public boolean isEmpty() { return size == 0; }
    public int size() { return size; }
}
```

---

## 🧱 Bloque 04 — Secuencias

### `04/01` — Prefijos 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §3](../04-secuencias/01-prefijos-y-diferencias.md#3--prefijos-1d).

```java
// P[k] = a[0] + ... + a[k-1]; suma de a[l..r] = P[r+1] - P[l].
static long[] buildPrefix(int[] a) {
    long[] p = new long[a.length + 1];
    for (int i = 0; i < a.length; i++) p[i + 1] = p[i] + a[i];
    return p;
}

static long rangeSum(long[] p, int l, int r) {   // l, r incluidos
    return p[r + 1] - p[l];
}
```

### `04/01` — Diferencias 1D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §4](../04-secuencias/01-prefijos-y-diferencias.md#4--diferencias-1d).

```java
// Suma v a [l, r] en O(1); al final, finish() reconstruye el arreglo con prefijos.
final class RangeAdd {
    private final long[] d;
    RangeAdd(int n) { d = new long[n + 1]; }
    void add(int l, int r, long v) { d[l] += v; d[r + 1] -= v; }
    long[] finish() {
        long[] b = new long[d.length - 1];
        long run = 0;
        for (int i = 0; i < b.length; i++) b[i] = (run += d[i]);
        return b;
    }
}
```

### `04/01` — Prefijos y diferencias 2D [A]

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §5](../04-secuencias/01-prefijos-y-diferencias.md#5--prefijos-y-diferencias-2d).

```java
// S[i][j] = suma de M[0..i-1][0..j-1]; consulta inclusiva de (r1,c1) a (r2,c2).
final class Prefix2D {
    private final long[][] s;
    Prefix2D(int[][] m) {
        int rows = m.length, cols = rows == 0 ? 0 : m[0].length;
        s = new long[rows + 1][cols + 1];
        for (int i = 0; i < rows; i++)
            for (int j = 0; j < cols; j++)
                s[i + 1][j + 1] = m[i][j] + s[i][j + 1] + s[i + 1][j] - s[i][j];
    }
    long query(int r1, int c1, int r2, int c2) {
        return s[r2 + 1][c2 + 1] - s[r1][c2 + 1] - s[r2 + 1][c1] + s[r1][c1];
    }
}
```

### `04/02` — Dos punteros [A]

De [`04/02` — Dos punteros y ventana deslizante, §3](../04-secuencias/02-dos-punteros-y-ventana.md#3--dos-punteros).

```java
// Número de pares i < j con a[i] + a[j] <= k. Pre: a ordenado. O(n).
static long countPairsAtMost(int[] a, long k) {
    long count = 0;
    int l = 0, r = a.length - 1;
    while (l < r) {
        if ((long) a[l] + a[r] <= k) { count += r - l; l++; }
        else r--;
    }
    return count;
}
```

### `04/02` — Ventana variable [A]

De [`04/02` — Dos punteros y ventana deslizante, §4](../04-secuencias/02-dos-punteros-y-ventana.md#4--ventana-variable).

```java
// Longitud del subarreglo más largo con suma <= s. Pre: a[i] >= 0. O(n).
static int longestAtMost(int[] a, long s) {
    long sum = 0;
    int best = 0;
    for (int l = 0, r = 0; r < a.length; r++) {
        sum += a[r];
        while (sum > s) sum -= a[l++];
        best = Math.max(best, r - l + 1);
    }
    return best;
}
```

### `04/02` — Ventana fija [A]

De [`04/02` — Dos punteros y ventana deslizante, §5](../04-secuencias/02-dos-punteros-y-ventana.md#5--ventana-fija).

```java
// Máxima suma de k elementos consecutivos. Pre: 1 <= k <= n. O(n).
static long maxWindowSum(int[] a, int k) {
    long sum = 0;
    for (int i = 0; i < k; i++) sum += a[i];
    long best = sum;
    for (int i = k; i < a.length; i++) {
        sum += a[i] - a[i - k];
        best = Math.max(best, sum);
    }
    return best;
}
```

### `04/03` — Kadane [A]

De [`04/03` — Kadane y subarreglos, §3](../04-secuencias/03-kadane-y-subarreglos.md#3--kadane).

```java
// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
static long maxSubarraySum(long[] a) {
    long best = a[0], cur = 0;
    for (long x : a) {
        cur = Math.max(x, cur + x);
        best = Math.max(best, cur);
    }
    return best;
}
```

### `04/03` — La variante circular [A]

De [`04/03` — Kadane y subarreglos, §4](../04-secuencias/03-kadane-y-subarreglos.md#4--la-variante-circular).

```java
// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
static long maxCircularSum(long[] a) {
    long total = 0, curMax = 0, curMin = 0, best = a[0], worst = a[0];
    for (long x : a) {
        total += x;
        curMax = Math.max(x, curMax + x); best = Math.max(best, curMax);
        curMin = Math.min(x, curMin + x); worst = Math.min(worst, curMin);
    }
    return best < 0 ? best : Math.max(best, total - worst);
}
```

### `04/03` — Contar subarreglos con prefijos y *hash* [A]

De [`04/03` — Kadane y subarreglos, §5](../04-secuencias/03-kadane-y-subarreglos.md#5--contar-subarreglos-con-prefijos-y-hash).

```java
// Número de subarreglos con suma exactamente k. O(n) esperado.
static long countSubarraysWithSum(long[] a, long k) {
    java.util.HashMap<Long, Long> seen = new java.util.HashMap<>();
    seen.put(0L, 1L);                             // el prefijo vacío
    long prefix = 0, count = 0;
    for (long x : a) {
        prefix += x;
        count += seen.getOrDefault(prefix - k, 0L);
        seen.merge(prefix, 1L, Long::sum);
    }
    return count;
}
```

### `04/03` — El voto de mayoría de Boyer-Moore [B]

De [`04/03` — Kadane y subarreglos, §6](../04-secuencias/03-kadane-y-subarreglos.md#6--el-voto-de-mayoría-de-boyer-moore).

```java
// Valor que aparece más de n/2 veces, o -1 si no hay. O(n), O(1) memoria. Pre: valores >= 0.
static long majority(long[] a) {
    long cand = -1, cnt = 0;
    for (long x : a) {
        if (cnt == 0) { cand = x; cnt = 1; }
        else if (x == cand) cnt++;
        else cnt--;
    }
    long occ = 0;
    for (long x : a) if (x == cand) occ++;
    return 2 * occ > a.length ? cand : -1;
}
```

### `04/04` — Compresión de coordenadas [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §3](../04-secuencias/04-compresion-y-barrido.md#3--compresión-de-coordenadas).

```java
// Devuelve los rangos de a en [0, k), con k el número de valores distintos. O(n log n).
static int[] compress(long[] a) {
    long[] sorted = a.clone();
    java.util.Arrays.sort(sorted);
    int k = 0;
    for (int i = 0; i < sorted.length; i++)
        if (i == 0 || sorted[i] != sorted[i - 1]) sorted[k++] = sorted[i];   // quitar repetidos
    int[] rank = new int[a.length];
    for (int i = 0; i < a.length; i++)
        rank[i] = java.util.Arrays.binarySearch(sorted, 0, k, a[i]);         // valores distintos: índice único
    return rank;
}
```

### `04/04` — Barrido de eventos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §4](../04-secuencias/04-compresion-y-barrido.md#4--barrido-de-eventos).

```java
// Máximo de intervalos [s, e) que se solapan en algún instante. O(n log n).
static int maxOverlap(long[][] intervals) {
    long[][] events = new long[2 * intervals.length][];
    int k = 0;
    for (long[] iv : intervals) { events[k++] = new long[] {iv[0], +1}; events[k++] = new long[] {iv[1], -1}; }
    java.util.Arrays.sort(events, (p, q) -> p[0] != q[0] ? Long.compare(p[0], q[0])
                                                        : Long.compare(p[1], q[1]));   // cierre primero
    int open = 0, best = 0;
    for (long[] ev : events) { open += (int) ev[1]; best = Math.max(best, open); }
    return best;
}
```

### `04/04` — Unión de intervalos [A]

De [`04/04` — Compresión de coordenadas y barrido de eventos, §5](../04-secuencias/04-compresion-y-barrido.md#5--unión-de-intervalos).

```java
// Une intervalos [s, e) que se solapan. Devuelve los bloques disjuntos ordenados. O(n log n).
static java.util.List<long[]> mergeIntervals(long[][] v) {
    long[][] sorted = v.clone();
    java.util.Arrays.sort(sorted, (p, q) -> Long.compare(p[0], q[0]));
    java.util.List<long[]> out = new java.util.ArrayList<>();
    for (long[] iv : sorted) {
        long[] last = out.isEmpty() ? null : out.get(out.size() - 1);
        if (last != null && iv[0] < last[1]) last[1] = Math.max(last[1], iv[1]);
        else out.add(new long[] {iv[0], iv[1]});
    }
    return out;
}
```

### `04/05` — Recorridos, rotación y espiral [A]

De [`04/05` — Matrices, §3](../04-secuencias/05-matrices.md#3--recorridos-rotación-y-espiral).

```java
static final int[] DR = {-1, 1, 0, 0}, DC = {0, 0, -1, 1};   // arriba, abajo, izquierda, derecha

// Gira una matriz n × n 90° en sentido horario, en el sitio: transponer y reflejar cada fila.
static void rotateClockwise(int[][] m) {
    int n = m.length;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) { int t = m[i][j]; m[i][j] = m[j][i]; m[j][i] = t; }
    for (int[] row : m)
        for (int l = 0, r = n - 1; l < r; l++, r--) { int t = row[l]; row[l] = row[r]; row[r] = t; }
}

// Recorrido en espiral en sentido horario desde la esquina superior izquierda.
static java.util.List<Integer> spiral(int[][] m) {
    java.util.List<Integer> out = new java.util.ArrayList<>();
    int top = 0, bottom = m.length - 1, left = 0, right = m[0].length - 1;
    while (top <= bottom && left <= right) {
        for (int j = left; j <= right; j++) out.add(m[top][j]);
        top++;
        for (int i = top; i <= bottom; i++) out.add(m[i][right]);
        right--;
        if (top <= bottom) { for (int j = right; j >= left; j--) out.add(m[bottom][j]); bottom--; }
        if (left <= right) { for (int i = bottom; i >= top; i--) out.add(m[i][left]); left++; }
    }
    return out;
}
```

### `04/05` — Búsqueda en matriz ordenada [A]

De [`04/05` — Matrices, §4](../04-secuencias/05-matrices.md#4--búsqueda-en-matriz-ordenada).

```java
// Busca x en una matriz con filas y columnas crecientes. Devuelve {fila, columna} o {-1, -1}. O(R + C).
static int[] staircaseSearch(int[][] m, int x) {
    int i = 0, j = m[0].length - 1;
    while (i < m.length && j >= 0) {
        if (m[i][j] == x) return new int[] {i, j};
        if (m[i][j] > x) j--;
        else i++;
    }
    return new int[] {-1, -1};
}
```

---

## 🧱 Bloque 05 — Orden y búsqueda

### `05/01` — Inserción y estabilidad [A]

De [`05/01` — Ordenación por comparación, §3](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#3--inserción-y-estabilidad).

```java
// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
static void insertionSort(int[] a) {
    for (int j = 1; j < a.length; j++) {
        int key = a[j], i = j;
        while (i > 0 && a[i - 1] > key) { a[i] = a[i - 1]; i--; }
        a[i] = key;
    }
}
```

### `05/01` — Ordenación por mezcla [A]

De [`05/01` — Ordenación por comparación, §4](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#4--ordenación-por-mezcla).

```java
// Ordenación por mezcla de a[lo, hi), estable. Θ(n log n) caso peor, Θ(n) memoria auxiliar.
static void mergeSort(int[] a, int[] buf, int lo, int hi) {
    if (hi - lo <= 1) return;
    int mid = lo + (hi - lo) / 2;
    mergeSort(a, buf, lo, mid);
    mergeSort(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) buf[k++] = (a[j] < a[i]) ? a[j++] : a[i++];
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    System.arraycopy(buf, lo, a, lo, hi - lo);
}
```

### `05/01` — *Quicksort* [A]

De [`05/01` — Ordenación por comparación, §5](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#5--quicksort).

```java
static final java.util.Random RNG = new java.util.Random(20261004);

// Quicksort de a[lo, hi] (inclusivo) con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
static void quickSort(int[] a, int lo, int hi) {
    if (lo >= hi) return;
    int r = lo + RNG.nextInt(hi - lo + 1);
    int t0 = a[lo]; a[lo] = a[r]; a[r] = t0;        // pivote aleatorio en a[lo]
    int p = a[lo];
    int i = lo - 1, j = hi + 1;
    while (true) {
        do i++; while (a[i] < p);
        do j--; while (a[j] > p);
        if (i >= j) break;
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }
    quickSort(a, lo, j);
    quickSort(a, j + 1, hi);
}
```

### `05/01` — *Heapsort* [B]

De [`05/01` — Ordenación por comparación, §6](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#6--heapsort).

```java
// Heapsort en el sitio. Θ(n log n) caso peor, Θ(1) memoria. No estable.
static void heapSort(int[] a) {
    int n = a.length;
    for (int i = n / 2 - 1; i >= 0; i--) siftDown(a, i, n);           // heapify
    for (int end = n - 1; end > 0; end--) {
        int t = a[0]; a[0] = a[end]; a[end] = t;                        // el máximo, a su sitio
        siftDown(a, 0, end);
    }
}

static void siftDown(int[] a, int i, int n) {                           // montículo de máximos en a[0, n)
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] > a[c]) c++;
        if (a[i] >= a[c]) return;
        int t = a[i]; a[i] = a[c]; a[c] = t;
        i = c;
    }
}
```

### `05/02` — *Counting sort* [B]

De [`05/02` — Ordenación lineal, §3](../05-orden-y-busqueda/02-ordenacion-lineal.md#3--counting-sort).

```java
// Counting sort estable de valores en [0, k). Θ(n + k) tiempo y memoria.
static int[] countingSort(int[] a, int k) {
    int[] start = new int[k + 1];
    for (int x : a) start[x + 1]++;
    for (int v = 0; v < k; v++) start[v + 1] += start[v];
    int[] out = new int[a.length];
    for (int x : a) out[start[x]++] = x;
    return out;
}
```

### `05/02` — *Radix sort* [B]

De [`05/02` — Ordenación lineal, §4](../05-orden-y-busqueda/02-ordenacion-lineal.md#4--radix-sort).

```java
// Radix sort LSD de enteros no negativos, base 256: cuatro pasadas de counting. Θ(4 · (n + 256)).
static void radixSort(int[] a) {
    int[] buf = new int[a.length];
    for (int shift = 0; shift < 32; shift += 8) {
        int[] start = new int[257];
        for (int x : a) start[((x >>> shift) & 255) + 1]++;
        for (int v = 0; v < 256; v++) start[v + 1] += start[v];
        for (int x : a) buf[start[(x >>> shift) & 255]++] = x;
        System.arraycopy(buf, 0, a, 0, a.length);
    }
}
```

### `05/03` — Contar inversiones con la mezcla [A]

De [`05/03` — Inversiones, selección y mediana, §3](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#3--contar-inversiones-con-la-mezcla).

```java
// Ordena a[lo, hi) por mezcla y devuelve sus inversiones. Θ(n log n). buf, del tamaño de a.
static long countInversions(int[] a, int[] buf, int lo, int hi) {
    if (hi - lo <= 1) return 0;
    int mid = lo + (hi - lo) / 2;
    long inv = countInversions(a, buf, lo, mid) + countInversions(a, buf, mid, hi);
    int i = lo, j = mid, k = lo;
    while (i < mid && j < hi) {
        if (a[j] < a[i]) { inv += mid - i; buf[k++] = a[j++]; }
        else buf[k++] = a[i++];
    }
    while (i < mid) buf[k++] = a[i++];
    while (j < hi) buf[k++] = a[j++];
    System.arraycopy(buf, lo, a, lo, hi - lo);
    return inv;
}
```

### `05/03` — *Quickselect* [A]

De [`05/03` — Inversiones, selección y mediana, §4](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#4--quickselect).

```java
static final java.util.Random RNG = new java.util.Random(20261004);

// Valor que ocuparía la posición k (0-indexada) si a estuviera ordenado. Reordena a. O(n) esperado.
static int quickSelect(int[] a, int k) {
    int lo = 0, hi = a.length - 1;
    while (lo < hi) {
        int r = lo + RNG.nextInt(hi - lo + 1);
        int t0 = a[lo]; a[lo] = a[r]; a[r] = t0;        // pivote aleatorio en a[lo]
        int p = a[lo];
        int i = lo - 1, j = hi + 1;
        while (true) {
            do i++; while (a[i] < p);
            do j--; while (a[j] > p);
            if (i >= j) break;
            int t = a[i]; a[i] = a[j]; a[j] = t;
        }
        if (k <= j) hi = j; else lo = j + 1;
    }
    return a[k];
}
```

### `05/04` — *Lower* y *upper bound* [A]

De [`05/04` — Búsqueda binaria, §3](../05-orden-y-busqueda/04-busqueda-binaria.md#3--lower-y-upper-bound).

```java
// Primer índice en [0, n] con a[i] >= x. Pre: a ordenado. Θ(log n).
static int lowerBound(int[] a, int x) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
        int mid = (lo + hi) >>> 1;
        if (a[mid] < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}

// Primer índice en [0, n] con a[i] > x. Solo cambia la comparación.
static int upperBound(int[] a, int x) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
        int mid = (lo + hi) >>> 1;
        if (a[mid] <= x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

### `05/04` — Binaria sobre la respuesta [A]

De [`05/04` — Búsqueda binaria, §4](../05-orden-y-busqueda/04-busqueda-binaria.md#4--binaria-sobre-la-respuesta).

```java
import java.util.function.LongPredicate;

// Primer v en [lo, hi) con P(v) cierto, o hi si no hay. Pre: P monótono (falso…cierto).
static long firstTrue(long lo, long hi, LongPredicate p) {
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (p.test(mid)) hi = mid; else lo = mid + 1;
    }
    return lo;
}
```

### `05/04` — Binaria en reales [A]

De [`05/04` — Búsqueda binaria, §5](../05-orden-y-busqueda/04-busqueda-binaria.md#5--binaria-en-reales).

```java
import java.util.function.DoublePredicate;

// Frontera de P (falso…cierto) en [lo, hi], con 100 vueltas fijas.
static double boundaryReal(double lo, double hi, DoublePredicate p) {
    for (int it = 0; it < 100; it++) {
        double mid = lo + (hi - lo) / 2;
        if (p.test(mid)) hi = mid; else lo = mid;
    }
    return hi;
}
```

### `05/05` — Búsqueda ternaria [B]

De [`05/05` — Búsqueda ternaria, unimodales y exponencial, §3](../05-orden-y-busqueda/05-ternaria-y-exponencial.md#3--búsqueda-ternaria).

```java
import java.util.function.DoubleUnaryOperator;
import java.util.function.LongUnaryOperator;

// Posición del mínimo de f en [lo, hi], f estrictamente unimodal (o convexa). O(log n) evaluaciones.
static long ternaryMinInt(long lo, long hi, LongUnaryOperator f) {
    while (hi - lo > 2) {
        long m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f.applyAsLong(m1) < f.applyAsLong(m2)) hi = m2 - 1; else lo = m1 + 1;
    }
    long best = lo;
    for (long x = lo + 1; x <= hi; x++) if (f.applyAsLong(x) < f.applyAsLong(best)) best = x;
    return best;
}

// Mínimo de f en [lo, hi] sobre reales, con 100 vueltas fijas.
static double ternaryMinReal(double lo, double hi, DoubleUnaryOperator f) {
    for (int it = 0; it < 100; it++) {
        double m1 = lo + (hi - lo) / 3, m2 = hi - (hi - lo) / 3;
        if (f.applyAsDouble(m1) < f.applyAsDouble(m2)) hi = m2; else lo = m1;
    }
    return lo + (hi - lo) / 2;
}
```

### `05/05` — Búsqueda exponencial [B]

De [`05/05` — Búsqueda ternaria, unimodales y exponencial, §5](../05-orden-y-busqueda/05-ternaria-y-exponencial.md#5--búsqueda-exponencial).

```java
import java.util.function.LongUnaryOperator;

// Lower bound de x en una secuencia ordenada sin tamaño conocido. at(i) = Long.MAX_VALUE fuera de rango.
static long exponentialLowerBound(LongUnaryOperator at, long x) {
    if (at.applyAsLong(0) >= x) return 0;
    long hi = 1;
    while (at.applyAsLong(hi) < x) hi *= 2;
    long lo = hi / 2 + 1;
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (at.applyAsLong(mid) < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
```

---

## 🧱 Bloque 06 — Lineales y hashing

### `06/01` — Pila, cola y deque [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §3](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#3--pila-cola-y-deque).

```java
import java.util.ArrayDeque;
import java.util.Deque;

Deque<Integer> stack = new ArrayDeque<>();   // pila: push, peek, pop
Deque<Integer> queue = new ArrayDeque<>();   // cola: offer, peek, poll
Deque<Integer> deque = new ArrayDeque<>();   // deque: offerFirst/offerLast, peekFirst/peekLast,
                                             //        pollFirst/pollLast
```

### `06/01` — Pila monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §4](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#4--pila-monótona).

```java
// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
static int[] nextGreater(int[] a) {
    int n = a.length;
    int[] ans = new int[n], st = new int[n];
    java.util.Arrays.fill(ans, -1);
    int top = 0;                                   // pila en un arreglo: sin cajas de Integer
    for (int i = 0; i < n; i++) {
        while (top > 0 && a[st[top - 1]] < a[i]) ans[st[--top]] = i;
        st[top++] = i;
    }
    return ans;
}
```

### `06/01` — Cola monótona [A]

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §5](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#5--cola-monótona).

```java
// mins[i] = mínimo de a[i, i + k). Θ(n).
static int[] windowMin(int[] a, int k) {
    int n = a.length;
    int[] dq = new int[n], mins = new int[n - k + 1];
    int head = 0, tail = 0;                        // deque en un arreglo: [head, tail)
    for (int i = 0; i < n; i++) {
        while (tail > head && a[dq[tail - 1]] >= a[i]) tail--;
        dq[tail++] = i;
        if (dq[head] <= i - k) head++;
        if (i >= k - 1) mins[i - k + 1] = a[dq[head]];
    }
    return mins;
}
```

### `06/02` — Inversión, punto medio y mezcla [A]

De [`06/02` — Listas enlazadas, §3](../06-lineales-y-hashing/02-listas-enlazadas.md#3--inversión-punto-medio-y-mezcla).

```java
static final class ListNode {
    int val; ListNode next;
    ListNode(int val, ListNode next) { this.val = val; this.next = next; }
}

static ListNode reverse(ListNode head) {
    ListNode prev = null;
    while (head != null) {
        ListNode nxt = head.next;
        head.next = prev;
        prev = head;
        head = nxt;
    }
    return prev;
}

static ListNode middle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) { slow = slow.next; fast = fast.next.next; }
    return slow;
}

static ListNode merge(ListNode a, ListNode b) {
    ListNode dummy = new ListNode(0, null), tail = dummy;
    while (a != null && b != null) {
        if (b.val < a.val) { tail.next = b; b = b.next; } else { tail.next = a; a = a.next; }
        tail = tail.next;
    }
    tail.next = (a != null) ? a : b;
    return dummy.next;
}
```

### `06/02` — Floyd: detectar el ciclo y su inicio [A]

De [`06/02` — Listas enlazadas, §4](../06-lineales-y-hashing/02-listas-enlazadas.md#4--floyd-detectar-el-ciclo-y-su-inicio).

```java
// Inicio del ciclo, o null si la lista termina. O(n) tiempo, O(1) memoria.
static ListNode cycleStart(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next; fast = fast.next.next;
        if (slow == fast) {
            ListNode p = head;
            while (p != slow) { p = p.next; slow = slow.next; }
            return p;
        }
    }
    return null;
}
```

### `06/02` — La caché LRU [A]

De [`06/02` — Listas enlazadas, §5](../06-lineales-y-hashing/02-listas-enlazadas.md#5--la-caché-lru).

```java
import java.util.LinkedHashMap;
import java.util.Map;

// LRU de capacidad cap con LinkedHashMap en orden de acceso. O(1) esperado.
static final class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int cap;
    LRUCache(int cap) {
        super(16, 0.75f, true);                // true: orden de acceso, no de inserción
        this.cap = cap;
    }
    @Override protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > cap;                   // tras cada put, expulsa el menos reciente
    }
}
```

### `06/03` — Encadenamiento y direccionamiento abierto [A]

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §3](../06-lineales-y-hashing/03-tablas-hash.md#3--encadenamiento-y-direccionamiento-abierto).

```java
// Conjunto de long con sondeo lineal; capacidad potencia de 2; α ≤ 1/2.
static final class LongSet {
    long[] keys = new long[16]; boolean[] used = new boolean[16]; int n = 0;
    int slot(long x) {
        long h = x * 0x9e3779b97f4a7c15L;
        return (int) (h ^ (h >>> 32)) & (keys.length - 1);
    }
    boolean contains(long x) {
        for (int i = slot(x); used[i]; i = (i + 1) & (keys.length - 1))
            if (keys[i] == x) return true;
        return false;
    }
    void add(long x) {
        if (2 * (n + 1) > keys.length) grow();
        int i = slot(x);
        for (; used[i]; i = (i + 1) & (keys.length - 1)) if (keys[i] == x) return;
        keys[i] = x; used[i] = true; n++;
    }
    void grow() {
        long[] ok = keys; boolean[] ou = used;
        keys = new long[ok.length * 2]; used = new boolean[ok.length * 2]; n = 0;
        for (int i = 0; i < ok.length; i++) if (ou[i]) add(ok[i]);
    }
}
```

### `06/03` — *Anti-hash tests* y *hash* propio [B]

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §5](../06-lineales-y-hashing/03-tablas-hash.md#5--anti-hash-tests-y-hash-propio).

```java
// Mezcla biyectiva con semilla aleatoria: claves distintas siguen siendo distintas, y las cubetas
// dejan de ser predecibles. Se usa mix(x) como clave del HashMap.
static final long SEED = System.nanoTime();

static long mix(long x) {
    x += SEED + 0x9e3779b97f4a7c15L;
    x = (x ^ (x >>> 30)) * 0xbf58476d1ce4e5b9L;
    x = (x ^ (x >>> 27)) * 0x94d049bb133111ebL;
    return x ^ (x >>> 31);
}

// Uso: map.merge(mix(x), 1, Integer::sum);  para contar o comprobar pertenencia.
```

### `06/04` — *Hash* polinomial sobre prefijos [B]

De [`06/04` — *Hashing* de secuencias, §3](../06-lineales-y-hashing/04-hashing-de-secuencias.md#3--hash-polinomial-sobre-prefijos).

```java
// Hash polinomial módulo 2^61 − 1 con base aleatoria. Preproceso O(n), subcadena O(1).
static final class StringHash {
    static final long MOD = (1L << 61) - 1;
    static final long B = 256 + Math.floorMod(new java.util.Random().nextLong(), MOD - 256);
    final long[] pre, pw;

    static long mul(long a, long b) {                         // producto exacto con 128 bits
        long hi = Math.multiplyHigh(a, b), lo = a * b;        // a, b < 2^61: el producto < 2^122
        long r = (lo & MOD) + ((lo >>> 61) | (hi << 3));
        return r >= MOD ? r - MOD : r;
    }

    StringHash(String s) {
        int n = s.length();
        pre = new long[n + 1]; pw = new long[n + 1]; pw[0] = 1;
        for (int i = 0; i < n; i++) {
            pre[i + 1] = (mul(pre[i], B) + s.charAt(i) + 1) % MOD;
            pw[i + 1] = mul(pw[i], B);
        }
    }

    long get(int l, int r) {                                  // hash de s[l, r)
        long v = pre[r] - mul(pre[l], pw[r - l]);
        return v < 0 ? v + MOD : v;
    }
}
```

### `06/04` — Zobrist y *hash* de multiconjuntos [B]

De [`06/04` — *Hashing* de secuencias, §5](../06-lineales-y-hashing/04-hashing-de-secuencias.md#5--zobrist-y-hash-de-multiconjuntos).

```java
// r[v] aleatorio de 64 bits por valor; H(a[l, r)) = pre[r] − pre[l] (suma mod 2^64).
static long[] multisetPrefix(int[] a, long[] r) {
    java.util.SplittableRandom rng = new java.util.SplittableRandom();
    for (int v = 0; v < r.length; v++) r[v] = rng.nextLong();
    long[] pre = new long[a.length + 1];
    for (int i = 0; i < a.length; i++) pre[i + 1] = pre[i] + r[a[i]];   // desborda a propósito
    return pre;
}
```

---

## 🧱 Bloque 07 — Árboles

### `07/01` — Representación [A]

De [`07/01` — Árboles: representación y recorridos, §3](../07-arboles/01-arboles-y-recorridos.md#3--representación).

```java
// Árbol de n nodos (1..n) a partir de sus n − 1 aristas no dirigidas.
static java.util.List<Integer>[] buildTree(int n, int[][] edges) {
    @SuppressWarnings("unchecked")
    java.util.List<Integer>[] adj = new java.util.List[n + 1];
    for (int i = 0; i <= n; i++) adj[i] = new java.util.ArrayList<>();
    for (int[] e : edges) { adj[e[0]].add(e[1]); adj[e[1]].add(e[0]); }
    return adj;
}
```

### `07/01` — Los cuatro recorridos [A]

De [`07/01` — Árboles: representación y recorridos, §4](../07-arboles/01-arboles-y-recorridos.md#4--los-cuatro-recorridos).

```java
static final class TreeNode { int val; TreeNode left, right; }

static void inorder(TreeNode t, java.util.List<Integer> out) {
    if (t == null) return;
    inorder(t.left, out); out.add(t.val); inorder(t.right, out);
}

// Preorden iterativo desde root sobre lista de adyacencia; parent y depth de cada nodo. O(n).
static int[] preorder(java.util.List<Integer>[] adj, int root, int[] parent, int[] depth) {
    int n = adj.length;
    int[] order = new int[n - 1], st = new int[n];
    int top = 0, k = 0;
    st[top++] = root; parent[root] = -1;
    while (top > 0) {
        int v = st[--top];
        order[k++] = v;
        for (int w : adj[v]) if (w != parent[v]) {
            parent[w] = v; depth[w] = depth[v] + 1; st[top++] = w;
        }
    }
    return order;
}
```

### `07/01` — Diámetro [A]

De [`07/01` — Árboles: representación y recorridos, §5](../07-arboles/01-arboles-y-recorridos.md#5--diámetro).

```java
// {nodo más lejano de s, distancia}. BFS sobre árbol sin pesos. O(n).
static int[] farthest(java.util.List<Integer>[] adj, int s) {
    int[] dist = new int[adj.length], q = new int[adj.length];
    java.util.Arrays.fill(dist, -1);
    int head = 0, tail = 0, best = s;
    q[tail++] = s; dist[s] = 0;
    while (head < tail) {
        int v = q[head++];
        if (dist[v] > dist[best]) best = v;
        for (int w : adj[v]) if (dist[w] < 0) { dist[w] = dist[v] + 1; q[tail++] = w; }
    }
    return new int[]{best, dist[best]};
}

static int diameter(java.util.List<Integer>[] adj) {
    return farthest(adj, farthest(adj, 1)[0])[1];
}
```

### `07/01` — Recorrido de Euler y tiempos [B]

De [`07/01` — Árboles: representación y recorridos, §6](../07-arboles/01-arboles-y-recorridos.md#6--recorrido-de-euler-y-tiempos).

```java
// Con order de preorden y size de subárbol (§4): tin y tout en O(n).
static void eulerTimes(int[] order, int[] size, int[] tin, int[] tout) {
    for (int i = 0; i < order.length; i++) tin[order[i]] = i;
    for (int v : order) tout[v] = tin[v] + size[v] - 1;
}
```

### `07/02` — El árbol binario de búsqueda [A]

De [`07/02` — BST y árboles balanceados, §3](../07-arboles/02-bst-y-balanceados.md#3--el-árbol-binario-de-búsqueda).

```java
static final class Node { int key; Node left, right; Node(int k) { key = k; } }

static Node insert(Node t, int key) {
    if (t == null) return new Node(key);
    if (key < t.key) t.left = insert(t.left, key);
    else if (key > t.key) t.right = insert(t.right, key);
    return t;
}

static boolean contains(Node t, int key) {
    while (t != null && t.key != key) t = key < t.key ? t.left : t.right;
    return t != null;
}

static Node ceiling(Node t, int x) {
    Node best = null;
    while (t != null) {
        if (t.key >= x) { best = t; t = t.left; } else t = t.right;
    }
    return best;
}
```

### `07/02` — AVL [B]

De [`07/02` — BST y árboles balanceados, §4](../07-arboles/02-bst-y-balanceados.md#4--avl).

```java
static final class Avl { int key, h; Avl l, r; Avl(int k) { key = k; } }

static int height(Avl t) { return t == null ? -1 : t.h; }
static void update(Avl t) { t.h = 1 + Math.max(height(t.l), height(t.r)); }

static Avl rotateRight(Avl y) { Avl x = y.l; y.l = x.r; x.r = y; update(y); update(x); return x; }
static Avl rotateLeft(Avl x)  { Avl y = x.r; x.r = y.l; y.l = x; update(x); update(y); return y; }

static Avl insert(Avl t, int key) {
    if (t == null) return new Avl(key);
    if (key < t.key) t.l = insert(t.l, key);
    else if (key > t.key) t.r = insert(t.r, key);
    else return t;
    update(t);
    int balance = height(t.l) - height(t.r);
    if (balance > 1) {
        if (key > t.l.key) t.l = rotateLeft(t.l);
        return rotateRight(t);
    }
    if (balance < -1) {
        if (key < t.r.key) t.r = rotateRight(t.r);
        return rotateLeft(t);
    }
    return t;
}
```

### `07/02` — Árbol B [B]

De [`07/02` — BST y árboles balanceados, §7](../07-arboles/02-bst-y-balanceados.md#7--árbol-b).

```java
static final class BNode { int[] keys; int n; BNode[] kids; boolean leaf = true; }

static boolean bSearch(BNode t, int key) {
    while (t != null) {
        int i = java.util.Arrays.binarySearch(t.keys, 0, t.n, key);
        if (i >= 0) return true;
        if (t.leaf) return false;
        t = t.kids[-i - 1];                            // punto de inserción = índice del hijo
    }
    return false;
}
```

### `07/03` — *Treap* [B]

De [`07/03` — Árboles aleatorizados y autoajustables, §3](../07-arboles/03-arboles-aleatorizados.md#3--treap).

```java
// Treap con split/merge sobre arreglos. Nodo 0 = vacío. O(log n) esperado por operación.
static final class Treap {
    final int[] key, pri, lc, rc, sz;
    int cnt = 0, root = 0;
    final java.util.SplittableRandom rng = new java.util.SplittableRandom();
    Treap(int cap) { key = new int[cap + 1]; pri = new int[cap + 1]; lc = new int[cap + 1];
                     rc = new int[cap + 1]; sz = new int[cap + 1]; }
    int node(int k) { cnt++; key[cnt] = k; pri[cnt] = rng.nextInt(); sz[cnt] = 1; return cnt; }
    void pull(int t) { sz[t] = 1 + sz[lc[t]] + sz[rc[t]]; }
    int sa, sb;                                     // resultado de split
    void split(int t, int k) {                      // (claves < k) en sa, (claves >= k) en sb
        if (t == 0) { sa = sb = 0; return; }
        if (key[t] < k) { split(rc[t], k); rc[t] = sa; pull(t); sa = t; }
        else { split(lc[t], k); lc[t] = sb; pull(t); sb = t; }
    }
    int merge(int a, int b) {
        if (a == 0 || b == 0) return a + b;
        if (pri[a] > pri[b]) { rc[a] = merge(rc[a], b); pull(a); return a; }
        lc[b] = merge(a, lc[b]); pull(b); return b;
    }
    void insert(int k) { split(root, k); int a = sa, b = sb; root = merge(merge(a, node(k)), b); }
    void erase(int k) { split(root, k); int a = sa; split(sb, k + 1); root = merge(a, sb); }
    int countLess(int k) { split(root, k); int r = sz[sa]; root = merge(sa, sb); return r; }
}
```

### `07/03` — *Skip list* [B]

De [`07/03` — Árboles aleatorizados y autoajustables, §5](../07-arboles/03-arboles-aleatorizados.md#5--skip-list).

```java
static final class SkipNode { int key; SkipNode[] next; SkipNode(int k, int lvl) { key = k; next = new SkipNode[lvl]; } }

// head tiene MAX niveles y clave −∞. ¿Está key? O(log n) esperado.
static boolean contains(SkipNode head, int levels, int key) {
    SkipNode x = head;
    for (int lv = levels - 1; lv >= 0; lv--)
        while (x.next[lv] != null && x.next[lv].key < key) x = x.next[lv];
    x = x.next[0];
    return x != null && x.key == key;
}
```

### `07/04` — *Trie* de palabras [A]

De [`07/04` — *Tries*, §3](../07-arboles/04-tries.md#3--trie-de-palabras).

```java
// Trie de minúsculas: insert y countPrefix en O(L). Nodo 0 = raíz; capacidad = total de letras + 1.
// Hijos en un arreglo plano: next[26 * v + c]. Un int[cap][26] crearía cap objetos.
static final class Trie {
    final int[] next, pass, end; int cnt = 1;
    Trie(int cap) { next = new int[26 * cap]; pass = new int[cap]; end = new int[cap]; }
    void insert(String w) {
        int v = 0;
        for (int i = 0; i < w.length(); i++) {
            int c = 26 * v + (w.charAt(i) - 'a');
            if (next[c] == 0) next[c] = cnt++;
            v = next[c]; pass[v]++;
        }
        end[v]++;
    }
    int countPrefix(String p) {
        int v = 0;
        for (int i = 0; i < p.length(); i++) { v = next[26 * v + (p.charAt(i) - 'a')]; if (v == 0) return 0; }
        return pass[v];
    }
}
```

### `07/04` — *Trie* binario [A]

De [`07/04` — *Tries*, §4](../07-arboles/04-tries.md#4--trie-binario).

```java
// Trie binario de enteros no negativos de B bits; borrado con contadores. O(B) por operación.
static final class XorTrie {                               // hijos en next[2 * v + bit]
    static final int B = 30;
    final int[] next, cnt; int nodes = 1;
    XorTrie(int maxInserts) { next = new int[2 * (maxInserts * B + 1)]; cnt = new int[maxInserts * B + 1]; }
    void add(int x, int d) {
        int v = 0;
        for (int b = B - 1; b >= 0; b--) {
            int c = 2 * v + ((x >> b) & 1);
            if (next[c] == 0) next[c] = nodes++;
            v = next[c]; cnt[v] += d;
        }
    }
    int maxXor(int x) {
        int v = 0, res = 0;
        for (int b = B - 1; b >= 0; b--) {
            int want = ((x >> b) & 1) ^ 1, u = next[2 * v + want];
            if (u != 0 && cnt[u] > 0) { res |= 1 << b; v = u; } else v = next[2 * v + (want ^ 1)];
        }
        return res;
    }
}
```

### `07/05` — *Binary lifting* [A]

De [`07/05` — LCA, §3](../07-arboles/05-lca.md#3--binary-lifting).

```java
// Binary lifting. parent[root] = root; order = preorden (cada padre antes que sus hijos).
static final class Lca {
    final int LOG; final int[][] up; final int[] depth;
    Lca(int[] parent, int[] depth, int[] order) {
        int n = parent.length, lg = 1;
        while ((1 << lg) < n) lg++;
        LOG = lg; this.depth = depth;
        up = new int[LOG][];
        up[0] = parent.clone();
        for (int k = 1; k < LOG; k++) {
            up[k] = new int[n];
            for (int v : order) up[k][v] = up[k - 1][up[k - 1][v]];
        }
    }
    int lift(int v, int d) {
        for (int k = 0; d > 0; k++, d >>= 1) if ((d & 1) != 0) v = up[k][v];
        return v;
    }
    int lca(int u, int v) {
        if (depth[u] < depth[v]) { int t = u; u = v; v = t; }
        u = lift(u, depth[u] - depth[v]);
        if (u == v) return u;
        for (int k = LOG - 1; k >= 0; k--)
            if (up[k][u] != up[k][v]) { u = up[k][u]; v = up[k][v]; }
        return up[0][u];
    }
    int dist(int u, int v) { return depth[u] + depth[v] - 2 * depth[lca(u, v)]; }
}
```

### `07/05` — Euler + RMQ [B]

De [`07/05` — LCA, §4](../07-arboles/05-lca.md#4--euler--rmq).

```java
// LCA por Euler + tabla dispersa, con el Euler construido como en la versión C++:
// eulNode[i], eulDepth[i] y first[v].
static final class EulerLca {
    final int[] first, lg; final int[][] sp; final int[] eulNode, eulDepth;   // sp guarda índices
    EulerLca(int[] eulNode, int[] eulDepth, int[] first) {
        this.eulNode = eulNode; this.eulDepth = eulDepth; this.first = first;
        int m = eulNode.length;
        lg = new int[m + 1];
        for (int i = 2; i <= m; i++) lg[i] = lg[i / 2] + 1;
        sp = new int[lg[m] + 1][m];
        for (int i = 0; i < m; i++) sp[0][i] = i;
        for (int k = 1; k <= lg[m]; k++)
            for (int i = 0; i + (1 << k) <= m; i++) {
                int a = sp[k - 1][i], b = sp[k - 1][i + (1 << (k - 1))];
                sp[k][i] = eulDepth[a] <= eulDepth[b] ? a : b;
            }
    }
    int lca(int u, int v) {
        int l = Math.min(first[u], first[v]), r = Math.max(first[u], first[v]);
        int k = lg[r - l + 1], a = sp[k][l], b = sp[k][r - (1 << k) + 1];
        return eulNode[eulDepth[a] <= eulDepth[b] ? a : b];
    }
}
```

### `07/06` — *Rerooting* [B]

De [`07/06` — Técnicas sobre árboles, §3](../07-arboles/06-tecnicas-sobre-arboles.md#3--rerooting).

```java
// Suma de distancias desde cada nodo. order = preorden desde la raíz; parent[raíz] = 0. Θ(n).
static long[] sumOfDistances(int n, int[] order, int[] parent) {
    long[] size = new long[n + 1], down = new long[n + 1], ans = new long[n + 1];
    java.util.Arrays.fill(size, 1);
    for (int i = n - 1; i > 0; i--) {
        int v = order[i], p = parent[v];
        size[p] += size[v];
        down[p] += down[v] + size[v];
    }
    ans[order[0]] = down[order[0]];
    for (int i = 1; i < n; i++) {
        int v = order[i];
        ans[v] = ans[parent[v]] - size[v] + (n - size[v]);
    }
    return ans;
}
```

### `07/06` — *Small-to-large* [B]

De [`07/06` — Técnicas sobre árboles, §4](../07-arboles/06-tecnicas-sobre-arboles.md#4--small-to-large).

```java
// Colores distintos de cada subárbol. order = preorden; parent[raíz] = 0. O(n log n) esperado.
@SuppressWarnings("unchecked")
static int[] distinctInSubtree(int n, int[] order, int[] parent, int[] color) {
    java.util.HashSet<Integer>[] s = new java.util.HashSet[n + 1];
    int[] ans = new int[n + 1];
    for (int i = n - 1; i >= 0; i--) {
        int v = order[i];
        if (s[v] == null) s[v] = new java.util.HashSet<>();
        s[v].add(color[v]);
        ans[v] = s[v].size();
        int p = parent[v];
        if (p == 0) continue;
        if (s[p] == null) { s[p] = s[v]; s[v] = null; continue; }
        if (s[p].size() < s[v].size()) { var t = s[p]; s[p] = s[v]; s[v] = t; }   // mueve referencias
        s[p].addAll(s[v]);
        s[v] = null;
    }
    return ans;
}
```

### `07/06` — Descomposición en centroides [B]

De [`07/06` — Técnicas sobre árboles, §5](../07-arboles/06-tecnicas-sobre-arboles.md#5--descomposición-en-centroides).

```java
// Árbol de centroides: cpar[v] = centroide padre de v (−1 en la raíz). O(n log n).
static final class CentroidDecomposition {
    final java.util.List<Integer>[] adj; final int[] sz, par, cpar; final boolean[] removed;
    CentroidDecomposition(java.util.List<Integer>[] g) {
        adj = g; int n = g.length;
        sz = new int[n]; par = new int[n]; cpar = new int[n]; removed = new boolean[n];
        java.util.Arrays.fill(cpar, -1);
    }
    int findCentroid(int root) {
        int[] order = new int[adj.length]; int cnt = 0;
        order[cnt++] = root; par[root] = -1;
        for (int i = 0; i < cnt; i++)
            for (int w : adj[order[i]])
                if (w != par[order[i]] && !removed[w]) { par[w] = order[i]; order[cnt++] = w; }
        for (int i = cnt - 1; i >= 0; i--) {
            int v = order[i]; sz[v] = 1;
            for (int w : adj[v]) if (w != par[v] && !removed[w]) sz[v] += sz[w];
        }
        int c = root;
        while (true) {
            int heavy = -1;
            for (int w : adj[c]) if (w != par[c] && !removed[w] && 2 * sz[w] > cnt) heavy = w;
            if (heavy < 0) return c;
            c = heavy;
        }
    }
    void build(int root, int parentCentroid) {
        int c = findCentroid(root);
        cpar[c] = parentCentroid; removed[c] = true;
        for (int w : adj[c]) if (!removed[w]) build(w, c);
    }
}
```

---

## 🧱 Bloque 08 — Heaps y Union-Find

### `08/01` — El montículo binario [A]

De [`08/01` — Montículo binario, §3](../08-heaps-y-union-find/01-monticulo-binario.md#3--el-montículo-binario).

```java
// Montículo de mínimos sobre un arreglo que crece. push y pop en O(log n).
static final class MinHeap {
    int[] a = new int[16]; int n = 0;
    void push(int x) {
        if (n == a.length) a = java.util.Arrays.copyOf(a, 2 * n);
        a[n] = x;
        for (int i = n++; i > 0 && a[(i - 1) / 2] > a[i]; i = (i - 1) / 2) {
            int p = (i - 1) / 2, t = a[i]; a[i] = a[p]; a[p] = t;
        }
    }
    int top() { return a[0]; }
    int pop() {
        int res = a[0];
        a[0] = a[--n];
        for (int i = 0;;) {
            int c = 2 * i + 1;
            if (c >= n) break;
            if (c + 1 < n && a[c + 1] < a[c]) c++;
            if (a[i] <= a[c]) break;
            int t = a[i]; a[i] = a[c]; a[c] = t; i = c;
        }
        return res;
    }
    boolean isEmpty() { return n == 0; }
}
```

### `08/01` — `heapify` [A]

De [`08/01` — Montículo binario, §4](../08-heaps-y-union-find/01-monticulo-binario.md#4--heapify).

```java
static void siftDown(int[] a, int i, int n) {
    while (2 * i + 1 < n) {
        int c = 2 * i + 1;
        if (c + 1 < n && a[c + 1] < a[c]) c++;
        if (a[i] <= a[c]) return;
        int t = a[i]; a[i] = a[c]; a[c] = t; i = c;
    }
}

static void heapify(int[] a) {                                    // O(n)
    for (int i = a.length / 2 - 1; i >= 0; i--) siftDown(a, i, a.length);
}
```

### `08/01` — Cola indexada [B]

De [`08/01` — Montículo binario, §5](../08-heaps-y-union-find/01-monticulo-binario.md#5--cola-indexada).

```java
// Cola de prioridad indexada (mínimos) sobre índices 0..n−1, con decrease-key.
static final class IndexedMinPQ {
    final long[] key; final int[] heap, pos; int size = 0;
    IndexedMinPQ(int n) { key = new long[n]; heap = new int[n]; pos = new int[n]; java.util.Arrays.fill(pos, -1); }
    void swapAt(int a, int b) { int t = heap[a]; heap[a] = heap[b]; heap[b] = t; pos[heap[a]] = a; pos[heap[b]] = b; }
    void up(int k) { while (k > 0 && key[heap[(k - 1) / 2]] > key[heap[k]]) { swapAt(k, (k - 1) / 2); k = (k - 1) / 2; } }
    void down(int k) {
        while (2 * k + 1 < size) {
            int c = 2 * k + 1;
            if (c + 1 < size && key[heap[c + 1]] < key[heap[c]]) c++;
            if (key[heap[k]] <= key[heap[c]]) break;
            swapAt(k, c); k = c;
        }
    }
    boolean contains(int i) { return pos[i] >= 0; }
    void push(int i, long k) { key[i] = k; pos[i] = size; heap[size++] = i; up(pos[i]); }
    void decrease(int i, long k) { key[i] = k; up(pos[i]); }
    int pop() {
        int top = heap[0];
        swapAt(0, --size); pos[top] = -1;
        if (size > 0) down(0);
        return top;
    }
    boolean isEmpty() { return size == 0; }
}
```

### `08/02` — Los `k` mayores [A]

De [`08/02` — Patrones con *heap*, §3](../08-heaps-y-union-find/02-patrones-con-heap.md#3--los-k-mayores).

```java
// Los k mayores de a (en orden creciente). Pre: k >= 1. O(n log k) tiempo, O(k) memoria.
static int[] topK(int[] a, int k) {
    java.util.PriorityQueue<Integer> pq = new java.util.PriorityQueue<>();   // de mínimos
    for (int x : a) {
        if (pq.size() < k) pq.offer(x);
        else if (x > pq.peek()) { pq.poll(); pq.offer(x); }
    }
    int[] res = new int[pq.size()];
    for (int i = 0; i < res.length; i++) res[i] = pq.poll();
    return res;
}
```

### `08/02` — Mezcla de `k` listas [A]

De [`08/02` — Patrones con *heap*, §4](../08-heaps-y-union-find/02-patrones-con-heap.md#4--mezcla-de-k-listas).

```java
// Mezcla k listas ordenadas. O(N log k).
static java.util.List<Integer> mergeK(int[][] lists) {
    java.util.PriorityQueue<int[]> pq =
        new java.util.PriorityQueue<>((x, y) -> Integer.compare(x[0], y[0]));   // {valor, lista, pos}
    for (int i = 0; i < lists.length; i++) if (lists[i].length > 0) pq.offer(new int[]{lists[i][0], i, 0});
    java.util.List<Integer> out = new java.util.ArrayList<>();
    while (!pq.isEmpty()) {
        int[] t = pq.poll();
        out.add(t[0]);
        if (t[2] + 1 < lists[t[1]].length) pq.offer(new int[]{lists[t[1]][t[2] + 1], t[1], t[2] + 1});
    }
    return out;
}
```

### `08/02` — La mediana con dos *heaps* [A]

De [`08/02` — Patrones con *heap*, §5](../08-heaps-y-union-find/02-patrones-con-heap.md#5--la-mediana-con-dos-heaps).

```java
// Mediana inferior de un flujo. add O(log n), median O(1).
static final class RunningMedian {
    final java.util.PriorityQueue<Integer> lo = new java.util.PriorityQueue<>(java.util.Comparator.reverseOrder());
    final java.util.PriorityQueue<Integer> hi = new java.util.PriorityQueue<>();
    void add(int x) {
        if (lo.isEmpty() || x <= lo.peek()) lo.offer(x); else hi.offer(x);
        if (lo.size() > hi.size() + 1) hi.offer(lo.poll());
        else if (hi.size() > lo.size()) lo.offer(hi.poll());
    }
    int median() { return lo.peek(); }
}
```

### `08/02` — Borrado perezoso [B]

De [`08/02` — Patrones con *heap*, §6](../08-heaps-y-union-find/02-patrones-con-heap.md#6--borrado-perezoso).

```java
// Montículo de mínimos con borrado perezoso de valores. O(log n) amortizado.
static final class LazyHeap {
    final java.util.PriorityQueue<Integer> pq = new java.util.PriorityQueue<>();
    final java.util.HashMap<Integer, Integer> dead = new java.util.HashMap<>();
    int alive = 0;
    void push(int x) { pq.offer(x); alive++; }
    void erase(int x) { dead.merge(x, 1, Integer::sum); alive--; }
    void clean() {
        while (!pq.isEmpty()) {
            Integer c = dead.get(pq.peek());
            if (c == null || c == 0) return;
            dead.put(pq.peek(), c - 1); pq.poll();
        }
    }
    int top() { clean(); return pq.peek(); }
    void pop() { clean(); pq.poll(); alive--; }
}
```

### `08/04` — Union-Find [A]

De [`08/04` — Union-Find, §3](../08-heaps-y-union-find/04-union-find.md#3--union-find).

```java
// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
static final class DSU {
    final int[] parent, size;
    DSU(int n) { parent = new int[n]; size = new int[n]; for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; } }
    int find(int x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
        return x;
    }
    boolean unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) { int t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b];
        return true;
    }
}
```

### `08/04` — Con pesos o paridad [B]

De [`08/04` — Union-Find, §4](../08-heaps-y-union-find/04-union-find.md#4--con-pesos-o-paridad).

```java
// Union-Find con pesos: d[x] = valor(x) − valor(padre(x)); tras find, relativo a la raíz.
static final class WeightedDSU {
    final int[] parent; final long[] d;
    WeightedDSU(int n) { parent = new int[n]; d = new long[n]; for (int i = 0; i < n; i++) parent[i] = i; }
    int find(int x) {
        if (parent[x] == x) return x;
        int r = find(parent[x]);
        d[x] += d[parent[x]];
        parent[x] = r;
        return r;
    }
    boolean unite(int a, int b, long w) {
        int ra = find(a), rb = find(b);
        if (ra == rb) return d[b] - d[a] == w;
        parent[rb] = ra;
        d[rb] = d[a] + w - d[b];
        return true;
    }
}
```

### `08/04` — Con *rollback* y *offline* [B]

De [`08/04` — Union-Find, §5](../08-heaps-y-union-find/04-union-find.md#5--con-rollback-y-offline).

```java
// Union-Find con rollback: sin compresión, unión por tamaño. find O(log n).
static final class RollbackDSU {
    final int[] parent, size, histB, histA; int top = 0, components;
    RollbackDSU(int n) {
        parent = new int[n]; size = new int[n]; histB = new int[n]; histA = new int[n]; components = n;
        for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; }
    }
    int find(int x) { while (parent[x] != x) x = parent[x]; return x; }
    boolean unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) { int t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b]; components--;
        histB[top] = b; histA[top++] = a;
        return true;
    }
    int snapshot() { return top; }
    void rollback(int snap) {
        while (top > snap) { top--; int b = histB[top], a = histA[top]; parent[b] = b; size[a] -= size[b]; components++; }
    }
}
```

---

## 🧱 Bloque 09 — Consultas sobre rangos

### `09/01` — La *sparse table* [B]

De [`09/01` — *Sparse table* y RMQ, §3](../09-consultas-sobre-rangos/01-sparse-table.md#3--la-sparse-table).

```java
// Sparse table de mínimos sobre un arreglo estático. Preproceso O(n log n), consulta O(1).
static final class SparseTable {
    final int[][] st; final int[] lg;
    SparseTable(int[] a) {
        int n = a.length;
        lg = new int[n + 1];
        for (int i = 2; i <= n; i++) lg[i] = lg[i / 2] + 1;
        st = new int[lg[n] + 1][];
        st[0] = a.clone();
        for (int k = 1; k <= lg[n]; k++) {
            st[k] = new int[n - (1 << k) + 1];
            for (int i = 0; i + (1 << k) <= n; i++)
                st[k][i] = Math.min(st[k - 1][i], st[k - 1][i + (1 << (k - 1))]);
        }
    }
    int query(int l, int r) {
        int k = lg[r - l + 1];
        return Math.min(st[k][l], st[k][r - (1 << k) + 1]);
    }
}
```

### `09/02` — Puntual y rango [A]

De [`09/02` — Fenwick, §3](../09-consultas-sobre-rangos/02-fenwick.md#3--puntual-y-rango).

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

### `09/02` — Rango y puntual [A]

De [`09/02` — Fenwick, §4](../09-consultas-sobre-rangos/02-fenwick.md#4--rango-y-puntual).

```java
static void rangeAdd(Fenwick f, int l, int r, long v) { f.add(l, v); f.add(r + 1, -v); }
static long pointGet(Fenwick f, int i) { return f.prefix(i); }
```

### `09/02` — Rango y rango [B]

De [`09/02` — Fenwick, §5](../09-consultas-sobre-rangos/02-fenwick.md#5--rango-y-rango).

```java
static final class RangeFenwick {
    final Fenwick b1, b2;
    RangeFenwick(int n) { b1 = new Fenwick(n + 1); b2 = new Fenwick(n + 1); }
    void add(int l, int r, long v) { b1.add(l, v); b1.add(r + 1, -v); b2.add(l, v * l); b2.add(r + 1, -v * (r + 1)); }
    long prefix(int i) { return b1.prefix(i) * (i + 1) - b2.prefix(i); }
    long range(int l, int r) { return prefix(r) - prefix(l - 1); }
}
```

### `09/02` — Fenwick 2D [B]

De [`09/02` — Fenwick, §6](../09-consultas-sobre-rangos/02-fenwick.md#6--fenwick-2d).

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

### `09/02` — Búsqueda por bits [B]

De [`09/02` — Fenwick, §7](../09-consultas-sobre-rangos/02-fenwick.md#7--búsqueda-por-bits).

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

### `09/03` — Iterativo [B]

De [`09/03` — Segment tree, §3](../09-consultas-sobre-rangos/03-segment-tree.md#3--iterativo).

```java
// Segment tree iterativo de mínimos. Consulta [l, r), actualización puntual. O(log n).
static final class SegTree {
    final int n; final int[] t;
    static int op(int a, int b) { return Math.min(a, b); }
    static final int E = Integer.MAX_VALUE;
    SegTree(int[] a) {
        n = a.length; t = new int[2 * n];
        for (int i = 0; i < n; i++) t[n + i] = a[i];
        for (int i = n - 1; i > 0; i--) t[i] = op(t[2 * i], t[2 * i + 1]);
    }
    void set(int p, int v) {
        for (t[p += n] = v; p > 1; p >>= 1) t[p >> 1] = op(t[p], t[p ^ 1]);
    }
    int query(int l, int r) {
        int resl = E, resr = E;
        for (l += n, r += n; l < r; l >>= 1, r >>= 1) {
            if ((l & 1) == 1) resl = op(resl, t[l++]);
            if ((r & 1) == 1) resr = op(t[--r], resr);
        }
        return op(resl, resr);
    }
}
```

### `09/03` — Recursivo [B]

De [`09/03` — Segment tree, §4](../09-consultas-sobre-rangos/03-segment-tree.md#4--recursivo).

```java
// Segment tree recursivo de máximos con descenso. Nodos 1..4n; tramos [lo, hi).
static final class MaxTree {
    final int n; final int[] t;
    MaxTree(int[] a) { n = a.length; t = new int[4 * n]; build(1, 0, n, a); }
    void build(int v, int lo, int hi, int[] a) {
        if (hi - lo == 1) { t[v] = a[lo]; return; }
        int mid = (lo + hi) / 2;
        build(2 * v, lo, mid, a); build(2 * v + 1, mid, hi, a);
        t[v] = Math.max(t[2 * v], t[2 * v + 1]);
    }
    void set(int v, int lo, int hi, int p, int x) {
        if (hi - lo == 1) { t[v] = x; return; }
        int mid = (lo + hi) / 2;
        if (p < mid) set(2 * v, lo, mid, p, x); else set(2 * v + 1, mid, hi, p, x);
        t[v] = Math.max(t[2 * v], t[2 * v + 1]);
    }
    int query(int v, int lo, int hi, int l, int r) {
        if (r <= lo || hi <= l) return Integer.MIN_VALUE;
        if (l <= lo && hi <= r) return t[v];
        int mid = (lo + hi) / 2;
        return Math.max(query(2 * v, lo, mid, l, r), query(2 * v + 1, mid, hi, l, r));
    }
    int firstAtLeast(int v, int lo, int hi, int i, int x) {
        if (hi <= i || t[v] < x) return -1;
        if (hi - lo == 1) return lo;
        int mid = (lo + hi) / 2;
        int res = firstAtLeast(2 * v, lo, mid, i, x);
        return res != -1 ? res : firstAtLeast(2 * v + 1, mid, hi, i, x);
    }
}
```

### `09/03` — *Lazy propagation* [B]

De [`09/03` — Segment tree, §5](../09-consultas-sobre-rangos/03-segment-tree.md#5--lazy-propagation).

```java
// Lazy: suma v a a[l..r) y suma de a[l..r). Nodos 1..4n; tramos [lo, hi). O(log n).
static final class LazySum {
    final int n; final long[] sum, add;
    LazySum(int n) { this.n = n; sum = new long[4 * n]; add = new long[4 * n]; }
    void apply(int v, int lo, int hi, long x) { sum[v] += x * (hi - lo); add[v] += x; }
    void push(int v, int lo, int hi) {
        if (add[v] == 0) return;
        int mid = (lo + hi) / 2;
        apply(2 * v, lo, mid, add[v]); apply(2 * v + 1, mid, hi, add[v]);
        add[v] = 0;
    }
    void update(int v, int lo, int hi, int l, int r, long x) {
        if (r <= lo || hi <= l) return;
        if (l <= lo && hi <= r) { apply(v, lo, hi, x); return; }
        push(v, lo, hi);
        int mid = (lo + hi) / 2;
        update(2 * v, lo, mid, l, r, x); update(2 * v + 1, mid, hi, l, r, x);
        sum[v] = sum[2 * v] + sum[2 * v + 1];
    }
    long query(int v, int lo, int hi, int l, int r) {
        if (r <= lo || hi <= l) return 0;
        if (l <= lo && hi <= r) return sum[v];
        push(v, lo, hi);
        int mid = (lo + hi) / 2;
        return query(2 * v, lo, mid, l, r) + query(2 * v + 1, mid, hi, l, r);
    }
}
```

### `09/05` — Descomposición en raíz [B]

De [`09/05` — Raíz cuadrada y Mo, §3](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#3--descomposición-en-raíz).

```java
// Descomposición en raíz para sumas: set puntual O(1), suma de [l, r] en O(√n).
static final class SqrtSum {
    final int n, B; final long[] a, block;
    SqrtSum(long[] v) {
        n = v.length; a = v.clone(); B = Math.max(1, (int) Math.sqrt(n));
        block = new long[(n + B - 1) / B];
        for (int i = 0; i < n; i++) block[i / B] += a[i];
    }
    void set(int p, long x) { block[p / B] += x - a[p]; a[p] = x; }
    long query(int l, int r) {
        long s = 0;
        int bl = l / B, br = r / B;
        if (bl == br) { for (int i = l; i <= r; i++) s += a[i]; return s; }
        for (int i = l; i < (bl + 1) * B; i++) s += a[i];
        for (int b = bl + 1; b < br; b++) s += block[b];
        for (int i = br * B; i <= r; i++) s += a[i];
        return s;
    }
}
```

### `09/05` — Mo [B]

De [`09/05` — Raíz cuadrada y Mo, §4](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#4--mo).

```java
// Mo: distintos en cada [l, r]. Valores comprimidos a 0..V−1. O((n + q)√n).
static int[] moDistinct(int[] a, int V, int[][] qs) {
    int n = a.length, q = qs.length, B = Math.max(1, (int) (n / Math.sqrt(Math.max(q, 1))));
    Integer[] order = new Integer[q];
    for (int i = 0; i < q; i++) order[i] = i;
    java.util.Arrays.sort(order, (x, y) -> {
        int bx = qs[x][0] / B, by = qs[y][0] / B;
        if (bx != by) return Integer.compare(bx, by);
        return (bx & 1) == 1 ? Integer.compare(qs[y][1], qs[x][1]) : Integer.compare(qs[x][1], qs[y][1]);
    });
    int[] cnt = new int[V], ans = new int[q];
    int curL = 0, curR = -1, distinct = 0;
    for (int id : order) {
        int l = qs[id][0], r = qs[id][1];
        while (curR < r) if (cnt[a[++curR]]++ == 0) distinct++;
        while (curL > l) if (cnt[a[--curL]]++ == 0) distinct++;
        while (curR > r) if (--cnt[a[curR--]] == 0) distinct--;
        while (curL < l) if (--cnt[a[curL++]] == 0) distinct--;
        ans[id] = distinct;
    }
    return ans;
}
```

### `09/05` — Consultas *offline* [B]

De [`09/05` — Raíz cuadrada y Mo, §5](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md#5--consultas-offline).

```java
// Distintos en [l, r] offline: ordenar por r y Fenwick sobre la última aparición. O((n + q) log n).
static int[] offlineDistinct(int[] a, int[][] qs) {
    int n = a.length, q = qs.length;
    Integer[] order = new Integer[q];
    for (int i = 0; i < q; i++) order[i] = i;
    java.util.Arrays.sort(order, (x, y) -> Integer.compare(qs[x][1], qs[y][1]));
    Fenwick f = new Fenwick(n);
    java.util.HashMap<Integer, Integer> last = new java.util.HashMap<>();
    int[] ans = new int[q];
    int k = 0;
    for (int i = 0; i < n; i++) {
        Integer prev = last.put(a[i], i);
        if (prev != null) f.add(prev + 1, -1);
        f.add(i + 1, 1);
        while (k < q && qs[order[k]][1] == i) { int id = order[k++]; ans[id] = (int) f.range(qs[id][0] + 1, i + 1); }
    }
    return ans;
}
```

---

## 🧱 Bloque 10 — Búsqueda completa y divide y vencerás

### `10/01` — Recursión y pila de llamadas [A]

De [`10/01` — Recursión, §3](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#3--recursión-y-pila-de-llamadas).

```java
// Mueve n discos de 'from' a 'to' usando 'via'. Θ(2ⁿ) tiempo, Θ(n) pila.
static void hanoi(int n, char from, char to, char via, StringBuilder out) {
    if (n == 0) return;                                   // caso base
    hanoi(n - 1, from, via, to, out);
    out.append(from).append(' ').append(to).append('\n');
    hanoi(n - 1, via, to, from, out);
}
```

### `10/01` — Paso a iterativo [A]

De [`10/01` — Recursión, §4](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#4--paso-a-iterativo).

```java
import java.util.ArrayDeque;

// Hanoi iterativo: cada marco es {n, from, to, via, etapa}. Θ(2ⁿ) tiempo, Θ(n) memoria.
static void hanoiIterative(int n, char from, char to, char via, StringBuilder out) {
    ArrayDeque<int[]> stack = new ArrayDeque<>();
    stack.push(new int[]{n, from, to, via, 0});
    while (!stack.isEmpty()) {
        int[] f = stack.peek();
        if (f[0] == 0 || f[4] == 2) { stack.pop(); continue; }             // base o terminado
        if (f[4] == 0) {
            f[4] = 1;
            stack.push(new int[]{f[0] - 1, f[1], f[3], f[2], 0});           // hanoi(n−1, from, via, to)
        } else {
            out.append((char) f[1]).append(' ').append((char) f[2]).append('\n');
            f[4] = 2;
            stack.push(new int[]{f[0] - 1, f[3], f[2], f[1], 0});           // hanoi(n−1, via, to, from)
        }
    }
}
```

### `10/02` — Subconjuntos con máscaras de bits [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §3](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#3--subconjuntos-con-máscaras-de-bits).

```java
// sum[m] = suma de los a[i] con el bit i encendido en m. Θ(2ⁿ) tiempo y memoria. n ≤ ~25.
static long[] subsetSums(long[] a) {
    int n = a.length;
    long[] sum = new long[1 << n];
    for (int m = 1; m < (1 << n); m++) {
        int low = Integer.numberOfTrailingZeros(m); // índice del bit más bajo
        sum[m] = sum[m & (m - 1)] + a[low];
    }
    return sum;
}
```

### `10/02` — Permutaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §4](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#4--permutaciones).

```java
// Siguiente permutación lexicográfica en su sitio; false si a era la última (y entonces no la toca).
static boolean nextPermutation(int[] a) {
    int i = a.length - 2;
    while (i >= 0 && a[i] >= a[i + 1]) i--;               // el sufijo a[i+1..] es no creciente
    if (i < 0) return false;
    int j = a.length - 1;
    while (a[j] <= a[i]) j--;                               // el menor del sufijo mayor que a[i]
    int t = a[i]; a[i] = a[j]; a[j] = t;
    for (int l = i + 1, r = a.length - 1; l < r; l++, r--) { t = a[l]; a[l] = a[r]; a[r] = t; }
    return true;
}

// Recursiva: cur[0..pos) ya está decidido; used marca los índices colocados.
static void permute(int[] a, int[] cur, boolean[] used, int pos) {
    if (pos == a.length) { /* procesar cur */ return; }
    for (int i = 0; i < a.length; i++) {
        if (used[i]) continue;
        used[i] = true; cur[pos] = a[i];
        permute(a, cur, used, pos + 1);
        used[i] = false;                                    // deshace la elección
    }
}
```

### `10/02` — Combinaciones [A]

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §5](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#5--combinaciones).

```java
// Todas las combinaciones de k índices de [0, n): cur[0..size) es la elección parcial.
static void combine(int n, int k, int start, int[] cur, int size) {
    if (size == k) { /* procesar cur */ return; }
    for (int i = start; n - i >= k - size; i++) {               // poda: quedan huecos suficientes
        cur[size] = i;
        combine(n, k, i + 1, cur, size + 1);
    }
}
```

### `10/03` — *Backtracking* [A]

De [`10/03` — *Backtracking* con poda y ramificación y poda, §3](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#3--backtracking).

```java
// Cuenta los subconjuntos (por posición) de a con suma exacta rem. a ordenado ascendente,
// pesos positivos; suffix[j] = a[j] + … + a[n−1]. Exponencial en el caso peor.
static long countSubsets(long[] a, long[] suffix, int start, long rem) {
    if (rem == 0) return 1;
    long count = 0;
    for (int j = start; j < a.length; j++) {
        if (a[j] > rem) break;                                // poda por exceso
        if (suffix[j] < rem) break;                           // poda por defecto
        count += countSubsets(a, suffix, j + 1, rem - a[j]);
    }
    return count;
}
```

### `10/03` — Ramificación y poda [B]

De [`10/03` — *Backtracking* con poda y ramificación y poda, §4](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#4--ramificación-y-poda).

```java
// Pre: w y v ordenados por v/w descendente. best[0] guarda el mejor valor encontrado.
static double bound(long[] w, long[] v, int i, long cap, long value) {
    double b = value;
    for (; i < w.length; i++) {
        if (w[i] <= cap) { cap -= w[i]; b += v[i]; }
        else { b += (double) v[i] * cap / w[i]; break; }
    }
    return b;
}

static void branchAndBound(long[] w, long[] v, int i, long cap, long value, long[] best) {
    best[0] = Math.max(best[0], value);
    if (i == w.length || bound(w, v, i, cap, value) <= best[0]) return;          // poda por cota
    if (w[i] <= cap) branchAndBound(w, v, i + 1, cap - w[i], value + v[i], best); // tomar
    branchAndBound(w, v, i + 1, cap, value, best);                                // dejar
}
```

### `10/04` — *Meet in the middle* [B]

De [`10/04` — *Meet in the middle*, IDDFS y *Dancing Links*, §3](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md#3--meet-in-the-middle).

```java
import java.util.Arrays;

// Todas las sumas de subconjuntos de a[from..to).
static long[] halfSums(long[] a, int from, int to) {
    int k = to - from;
    long[] sums = new long[1 << k];
    for (int m = 1; m < (1 << k); m++)
        sums[m] = sums[m & (m - 1)] + a[from + Integer.numberOfTrailingZeros(m)];
    return sums;
}

// Mayor suma de un subconjunto de a que no pasa de S (0 si solo el vacío). O(2^(n/2) · n).
static long bestSumAtMost(long[] a, long S) {
    int n = a.length, mid = n / 2;
    long[] left = halfSums(a, 0, mid), right = halfSums(a, mid, n);
    Arrays.sort(right);                                       // primitivos: sin boxing
    long best = 0;
    for (long x : left) {
        if (x > S) continue;
        int lo = 0, hi = right.length;                        // primer índice con right[i] > S − x
        while (lo < hi) { int m = (lo + hi) >>> 1; if (right[m] <= S - x) lo = m + 1; else hi = m; }
        best = Math.max(best, x + right[lo - 1]);             // lo ≥ 1 porque right[0] = 0
    }
    return best;
}
```

### `10/04` — IDDFS [B]

De [`10/04` — *Meet in the middle*, IDDFS y *Dancing Links*, §4](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md#4--iddfs).

```java
// IDDFS sobre un problema concreto: la cadena de sumas más corta hasta target.
static int[] chain = new int[64];

static boolean dfs(int len, int limit, int target) {
    int last = chain[len - 1];
    if (last == target) return true;
    if (len - 1 == limit) return false;
    if ((long) last << (limit - (len - 1)) < target) return false;   // ni doblando se llega
    for (int i = len - 1; i >= 0; i--)
        for (int j = i; j >= 0; j--) {
            int s = chain[i] + chain[j];
            if (s <= last || s > target) continue;                     // cadena creciente
            chain[len] = s;                                            // aplicar (se sobrescribe al volver)
            if (dfs(len + 1, limit, target)) return true;
        }
    return false;
}

static int shortestChain(int target) {
    chain[0] = 1;
    for (int limit = 0; ; limit++) if (dfs(1, limit, target)) return limit;
}
```

### `10/05` — El esquema [A]

De [`10/05` — Divide y vencerás, §3](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#3--el-esquema).

```java
// Suma máxima de un subarreglo no vacío de a[lo, hi). Θ(n log n). Pre: lo < hi.
static long maxSubarray(long[] a, int lo, int hi) {
    if (hi - lo == 1) return a[lo];
    int mid = (lo + hi) >>> 1;
    long best = Math.max(maxSubarray(a, lo, mid), maxSubarray(a, mid, hi));
    long sum = 0, leftBest = Long.MIN_VALUE, rightBest = Long.MIN_VALUE;
    for (int i = mid - 1; i >= lo; i--) { sum += a[i]; leftBest = Math.max(leftBest, sum); }
    sum = 0;
    for (int i = mid; i < hi; i++) { sum += a[i]; rightBest = Math.max(rightBest, sum); }
    return Math.max(best, leftBest + rightBest);
}
```

### `10/05` — Exponenciación rápida [A]

De [`10/05` — Divide y vencerás, §6](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#6--exponenciación-rápida).

```java
// aⁿ mod m, con 1 ≤ m ≤ 2³¹. Θ(log n).
static long powMod(long a, long n, long m) {
    long result = 1 % m, base = Math.floorMod(a, m);
    while (n > 0) {
        if ((n & 1) == 1) result = result * base % m;
        base = base * base % m;
        n >>= 1;
    }
    return result;
}
```

### `10/06` — Minimax [B]

De [`10/06` — Juegos y búsqueda adversarial, §3](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md#3--minimax).

```java
// Mejor diferencia (propio − rival) para quien mueve con las monedas a[i..j]. Θ(n²) estados.
static long negamax(long[] a, int i, int j, Long[][] memo) {
    if (i > j) return 0;
    if (memo[i][j] != null) return memo[i][j];
    long takeLeft  = a[i] - negamax(a, i + 1, j, memo);
    long takeRight = a[j] - negamax(a, i, j - 1, memo);
    return memo[i][j] = Math.max(takeLeft, takeRight);
}
```

### `10/06` — Alfa-beta [B]

De [`10/06` — Juegos y búsqueda adversarial, §4](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md#4--alfa-beta).

```java
// Negamax con alfa-beta sobre un juego que se modifica y se deshace.
interface Game {
    boolean terminal();
    int evaluate();                  // valor para el jugador que mueve
    int[] moves();
    void play(int mv);
    void undo(int mv);
}

static int alphaBeta(Game g, int depth, int alpha, int beta) {
    if (depth == 0 || g.terminal()) return g.evaluate();
    int best = Integer.MIN_VALUE + 1;
    for (int mv : g.moves()) {
        g.play(mv);
        int value = -alphaBeta(g, depth - 1, -beta, -alpha);
        g.undo(mv);
        best = Math.max(best, value);
        alpha = Math.max(alpha, value);
        if (alpha >= beta) break;
    }
    return best;
}
```

---

## 🧱 Bloque 11 — Voraces

### `11/02` — Selección de actividades [A]

De [`11/02` — Intervalos, §3](../11-voraces/02-intervalos.md#3--selección-de-actividades).

```java
// Máximo número de intervalos [s, f) disjuntos. Θ(n log n).
static int maxDisjoint(int[][] intervals) {
    int[][] byEnd = intervals.clone();
    java.util.Arrays.sort(byEnd, (p, q) -> Integer.compare(p[1], q[1]));
    int count = 0;
    long lastEnd = Long.MIN_VALUE;
    for (int[] iv : byEnd)
        if (iv[0] >= lastEnd) { count++; lastEnd = iv[1]; }
    return count;
}
```

### `11/02` — Cubrimiento con puntos [A]

De [`11/02` — Intervalos, §4](../11-voraces/02-intervalos.md#4--cubrimiento-con-puntos).

```java
// Mínimo de puntos que pinchan todos los intervalos cerrados [s, f]. Θ(n log n).
static int minPoints(long[][] intervals) {
    long[][] byEnd = intervals.clone();
    java.util.Arrays.sort(byEnd, (p, q) -> Long.compare(p[1], q[1]));
    int count = 0;
    long last = Long.MIN_VALUE;
    for (long[] iv : byEnd)
        if (iv[0] > last) { count++; last = iv[1]; }
    return count;
}
```

### `11/02` — Mezcla [A]

De [`11/02` — Intervalos, §5](../11-voraces/02-intervalos.md#5--mezcla).

```java
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

// Unión de intervalos cerrados [s, f], como lista ordenada de disjuntos. Θ(n log n).
static List<long[]> mergeIntervals(long[][] intervals) {
    long[][] byStart = intervals.clone();
    Arrays.sort(byStart, (p, q) -> Long.compare(p[0], q[0]));
    List<long[]> out = new ArrayList<>();
    for (long[] iv : byStart) {
        long[] last = out.isEmpty() ? null : out.get(out.size() - 1);
        if (last != null && iv[0] <= last[1]) last[1] = Math.max(last[1], iv[1]);
        else out.add(new long[]{iv[0], iv[1]});                   // copia: no se modifica la entrada
    }
    return out;
}
```

### `11/02` — Mínimo de salas [A]

De [`11/02` — Intervalos, §6](../11-voraces/02-intervalos.md#6--mínimo-de-salas).

```java
// Mínimo de salas para reuniones [s, f) (profundidad). Θ(n log n).
static int minRooms(long[][] intervals) {
    int n = intervals.length;
    long[] starts = new long[n], ends = new long[n];
    for (int i = 0; i < n; i++) { starts[i] = intervals[i][0]; ends[i] = intervals[i][1]; }
    java.util.Arrays.sort(starts);
    java.util.Arrays.sort(ends);
    int rooms = 0, best = 0;
    for (int i = 0, j = 0; i < n; i++) {
        while (j < n && ends[j] <= starts[i]) { j++; rooms--; }
        rooms++;
        best = Math.max(best, rooms);
    }
    return best;
}
```

### `11/03` — Planificación con plazos [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §3](../11-voraces/03-plazos-huffman-y-monedas.md#3--planificación-con-plazos).

```java
import java.util.Arrays;
import java.util.PriorityQueue;

// Máximo beneficio de tareas unitarias {plazo, beneficio} que acaban a tiempo. Θ(n log n).
static long maxProfit(long[][] jobs) {
    long[][] byDeadline = jobs.clone();
    Arrays.sort(byDeadline, (a, b) -> Long.compare(a[0], b[0]));
    PriorityQueue<Long> kept = new PriorityQueue<>();                     // min-heap
    long total = 0;
    for (long[] j : byDeadline) {
        kept.add(j[1]); total += j[1];
        if (kept.size() > j[0]) total -= kept.poll();
    }
    return total;
}
```

### `11/03` — Huffman [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §4](../11-voraces/03-plazos-huffman-y-monedas.md#4--huffman).

```java
import java.util.PriorityQueue;

// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman. Θ(n log n).
static long huffmanCost(long[] freq) {
    PriorityQueue<Long> pq = new PriorityQueue<>();
    for (long f : freq) pq.add(f);
    long cost = 0;
    while (pq.size() > 1) {
        long a = pq.poll(), b = pq.poll();
        cost += a + b;
        pq.add(a + b);
    }
    return cost;
}
```

### `11/03` — Mochila fraccionaria [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §5](../11-voraces/03-plazos-huffman-y-monedas.md#5--mochila-fraccionaria).

```java
import java.util.Arrays;

// Valor máximo con materiales divisibles {peso, valor}. Θ(n log n).
static double fractionalKnapsack(long[][] items, long cap) {
    long[][] byRatio = items.clone();
    Arrays.sort(byRatio, (a, b) -> Long.compare(b[1] * a[0], a[1] * b[0]));   // razón decreciente
    double value = 0;
    for (long[] it : byRatio) {
        if (cap == 0) break;
        long take = Math.min(it[0], cap);
        value += (double) it[1] * take / it[0];
        cap -= take;
    }
    return value;
}
```

### `11/03` — Monedas canónicas [A]

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §6](../11-voraces/03-plazos-huffman-y-monedas.md#6--monedas-canónicas).

```java
// Monedas del voraz para x; coins ordenadas de mayor a menor, con la de 1. O(k).
static long greedyCoins(long[] coins, long x) {
    long count = 0;
    for (long c : coins) { count += x / c; x %= c; }
    return count;
}
```

---

## 🧱 Bloque 12 — DP clásica

### `12/01` — Memoización [A]

De [`12/01` — De la recursión a la tabla, §3](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#3--memoización).

```java
static final long MOD = 1_000_000_007L;

// Formas de llegar al escalón i con pasos de 1, 2 o 3. memo[i] = −1 si no se ha calculado.
static long ways(int i, long[] memo) {
    if (i < 0) return 0;
    if (i == 0) return 1;
    if (memo[i] != -1) return memo[i];
    return memo[i] = (ways(i - 1, memo) + ways(i - 2, memo) + ways(i - 3, memo)) % MOD;
}
// long[] memo = new long[n + 1]; Arrays.fill(memo, -1); ways(n, memo);
```

### `12/01` — Tabulación [A]

De [`12/01` — De la recursión a la tabla, §4](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#4--tabulación).

```java
// Formas de subir n escalones con pasos de 1, 2 o 3, sin pisar los rotos. Θ(n) tiempo y memoria.
static long waysTable(int n, boolean[] broken) {
    final long MOD = 1_000_000_007L;
    long[] dp = new long[n + 1];
    dp[0] = 1;
    for (int i = 1; i <= n; i++) {
        if (broken[i]) continue;
        for (int step = 1; step <= 3 && step <= i; step++) dp[i] = (dp[i] + dp[i - step]) % MOD;
    }
    return dp[n];
}
```

### `12/01` — Reconstrucción [A]

De [`12/01` — De la recursión a la tabla, §5](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#5--reconstrucción).

```java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

// Menor número de operaciones +1, ×2, ×3 de 1 a n, y la secuencia. Θ(n).
static List<Integer> opsPath(int n) {
    int[] dp = new int[n + 1], parent = new int[n + 1];
    for (int x = 2; x <= n; x++) {
        dp[x] = dp[x - 1] + 1; parent[x] = x - 1;
        if (x % 2 == 0 && dp[x / 2] + 1 < dp[x]) { dp[x] = dp[x / 2] + 1; parent[x] = x / 2; }
        if (x % 3 == 0 && dp[x / 3] + 1 < dp[x]) { dp[x] = dp[x / 3] + 1; parent[x] = x / 3; }
    }
    List<Integer> path = new ArrayList<>();
    for (int x = n; x != 1; x = parent[x]) path.add(x);
    path.add(1);
    Collections.reverse(path);
    return path;
}
```

### `12/02` — Escaleras y robos [A]

De [`12/02` — DP lineal y LIS, §3](../12-dp-clasica/02-dp-lineal-y-lis.md#3--escaleras-y-robos).

```java
// Mayor suma de elementos sin coger dos consecutivos. Θ(n), O(1) memoria.
static long maxNonAdjacent(long[] a) {
    long take = 0, skip = 0;
    for (long x : a) {
        long newTake = skip + x;
        skip = Math.max(skip, take);
        take = newTake;
    }
    return Math.max(take, skip);
}
```

### `12/02` — LIS en O(n²) [A]

De [`12/02` — DP lineal y LIS, §4](../12-dp-clasica/02-dp-lineal-y-lis.md#4--lis-en-on).

```java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

// Una LIS estrictamente creciente, por índices. Θ(n²).
static List<Integer> lisQuadratic(long[] a) {
    int n = a.length, best = -1;
    int[] d = new int[n], parent = new int[n];
    for (int i = 0; i < n; i++) {
        d[i] = 1; parent[i] = -1;
        for (int j = 0; j < i; j++)
            if (a[j] < a[i] && d[j] + 1 > d[i]) { d[i] = d[j] + 1; parent[i] = j; }
        if (best < 0 || d[i] > d[best]) best = i;
    }
    List<Integer> seq = new ArrayList<>();
    for (int i = best; i != -1; i = parent[i]) seq.add(i);
    Collections.reverse(seq);
    return seq;
}
```

### `12/02` — LIS en O(n log n) [A]

De [`12/02` — DP lineal y LIS, §5](../12-dp-clasica/02-dp-lineal-y-lis.md#5--lis-en-on-log-n).

```java
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

// Una LIS estrictamente creciente, por índices. Θ(n log n).
static List<Integer> lisFast(long[] a) {
    int n = a.length, len = 0;
    long[] tails = new long[n];
    int[] tailIdx = new int[n], parent = new int[n];
    for (int i = 0; i < n; i++) {
        int lo = 0, hi = len;                      // lower bound de a[i] en tails[0..len)
        while (lo < hi) { int mid = (lo + hi) >>> 1; if (tails[mid] < a[i]) lo = mid + 1; else hi = mid; }
        tails[lo] = a[i]; tailIdx[lo] = i;
        parent[i] = lo > 0 ? tailIdx[lo - 1] : -1;
        if (lo == len) len++;
    }
    List<Integer> seq = new ArrayList<>();
    for (int i = len > 0 ? tailIdx[len - 1] : -1; i != -1; i = parent[i]) seq.add(i);
    Collections.reverse(seq);
    return seq;
}
```

### `12/03` — Mochila 0/1 [A]

De [`12/03` — Mochilas, §3](../12-dp-clasica/03-mochilas.md#3--mochila-01).

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

### `12/03` — Una fila de memoria [A]

De [`12/03` — Mochilas, §4](../12-dp-clasica/03-mochilas.md#4--una-fila-de-memoria).

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

### `12/03` — Mochila ilimitada [A]

De [`12/03` — Mochilas, §5](../12-dp-clasica/03-mochilas.md#5--mochila-ilimitada).

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

### `12/03` — Monedas: contar y mínimo [A]

De [`12/03` — Mochilas, §6](../12-dp-clasica/03-mochilas.md#6--monedas-contar-y-mínimo).

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

### `12/04` — LCS [A]

De [`12/04` — DP sobre cadenas, §3](../12-dp-clasica/04-dp-sobre-cadenas.md#3--lcs).

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

### `12/04` — Distancia de edición [A]

De [`12/04` — DP sobre cadenas, §4](../12-dp-clasica/04-dp-sobre-cadenas.md#4--distancia-de-edición).

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

### `12/04` — Subsecuencias y palíndromos [A]

De [`12/04` — DP sobre cadenas, §5](../12-dp-clasica/04-dp-sobre-cadenas.md#5--subsecuencias-y-palíndromos).

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

### `12/05` — Rejillas [A]

De [`12/05` — DP en rejillas y de intervalos, §3](../12-dp-clasica/05-rejillas-e-intervalos.md#3--rejillas).

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

### `12/05` — Cadena de matrices [B]

De [`12/05` — DP en rejillas y de intervalos, §4](../12-dp-clasica/05-rejillas-e-intervalos.md#4--cadena-de-matrices).

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

### `12/05` — *Burst balloons* [B]

De [`12/05` — DP en rejillas y de intervalos, §5](../12-dp-clasica/05-rejillas-e-intervalos.md#5--burst-balloons).

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

### `12/06` — Conteo [A]

De [`12/06` — Conteo con DP, §3](../12-dp-clasica/06-conteo.md#3--conteo).

```java
static final long MOD = 1_000_000_007L;

// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]. Θ(n · L²).
static long countWords(int n, boolean[][] allowed) {
    int L = allowed.length;
    long[] cur = new long[L];
    java.util.Arrays.fill(cur, 1);
    for (int step = 1; step < n; step++) {
        long[] nxt = new long[L];
        for (int p = 0; p < L; p++)
            for (int c = 0; c < L; c++)
                if (allowed[p][c]) nxt[c] = (nxt[c] + cur[p]) % MOD;
        cur = nxt;
    }
    long total = 0;
    for (long x : cur) total = (total + x) % MOD;
    return total;
}
```

### `12/06` — Particiones [B]

De [`12/06` — Conteo con DP, §4](../12-dp-clasica/06-conteo.md#4--particiones).

```java
// p[s] = particiones de s en partes positivas (orden indiferente). Θ(n²).
static long[] partitions(int n, boolean distinct) {
    final long MOD = 1_000_000_007L;
    long[] p = new long[n + 1];
    p[0] = 1;
    for (int part = 1; part <= n; part++) {
        if (distinct) for (int s = n; s >= part; s--) p[s] = (p[s] + p[s - part]) % MOD;
        else for (int s = part; s <= n; s++) p[s] = (p[s] + p[s - part]) % MOD;
    }
    return p;
}
```

---

## 🧱 Bloque 13 — DP avanzada

### `13/01` — DP sobre subconjuntos [B]

De [`13/01` — DP con máscaras de bits, §3](../13-dp-avanzada/01-mascaras-de-bits.md#3--dp-sobre-subconjuntos).

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

### `13/01` — Viajante [B]

De [`13/01` — DP con máscaras de bits, §4](../13-dp-avanzada/01-mascaras-de-bits.md#4--viajante).

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

### `13/01` — SOS DP [B]

De [`13/01` — DP con máscaras de bits, §5](../13-dp-avanzada/01-mascaras-de-bits.md#5--sos-dp).

```java
// F[m] = Σ f[s] sobre las submáscaras s de m, para todas las m. Θ(2ⁿ · n). En el sitio.
static void sumOverSubsets(long[] F, int bits) {
    for (int b = 0; b < bits; b++)
        for (int m = 0; m < (1 << bits); m++)
            if ((m >> b & 1) == 1) F[m] += F[m ^ (1 << b)];
}
```

### `13/02` — *Digit DP* [B]

De [`13/02` — *Digit DP*, §3](../13-dp-avanzada/02-digit-dp.md#3--digit-dp).

```java
// Cuántos x en [0, N] tienen suma de dígitos ≡ 0 (mod k). N ≤ 10¹⁸, k ≤ 200. Θ(L · k · 10).
static long[][] memo;
static char[] digits;
static int K;

static long go(int pos, int rem, boolean tight) {
    if (pos == digits.length) return rem == 0 ? 1 : 0;
    if (!tight && memo[pos][rem] >= 0) return memo[pos][rem];
    int limit = tight ? digits[pos] - '0' : 9;
    long count = 0;
    for (int c = 0; c <= limit; c++)
        count += go(pos + 1, (rem + c) % K, tight && c == limit);
    if (!tight) memo[pos][rem] = count;
    return count;
}

static long countUpTo(long N, int k) {
    if (N < 0) return 0;
    digits = Long.toString(N).toCharArray(); K = k;
    memo = new long[digits.length][k];
    for (long[] row : memo) java.util.Arrays.fill(row, -1);
    return go(0, 0, true);
}
```

### `13/03` — DP en árboles [A]

De [`13/03` — DP en árboles y en DAG, §3](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#3--dp-en-árboles).

```java
import java.util.ArrayList;
import java.util.List;

// Conjunto independiente de peso máximo en un árbol con raíz 0 y padres parent[] (parent[0] = −1). Θ(n).
static long maxIndependentSet(int[] parent, long[] w) {
    int n = parent.length;
    List<List<Integer>> children = new ArrayList<>();
    for (int v = 0; v < n; v++) children.add(new ArrayList<>());
    for (int v = 1; v < n; v++) children.get(parent[v]).add(v);
    int[] order = new int[n], stack = new int[n];
    int top = 0, k = 0;
    stack[top++] = 0;
    while (top > 0) {
        int v = stack[--top];
        order[k++] = v;
        for (int c : children.get(v)) stack[top++] = c;
    }
    long[] in = new long[n], out = new long[n];
    for (int i = n - 1; i >= 0; i--) {
        int v = order[i];
        in[v] = w[v];
        for (int c : children.get(v)) { in[v] += out[c]; out[v] += Math.max(in[c], out[c]); }
    }
    return Math.max(in[0], out[0]);
}
```

### `13/03` — DP sobre DAG [A]

De [`13/03` — DP en árboles y en DAG, §4](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#4--dp-sobre-dag).

```java
import java.util.ArrayDeque;
import java.util.List;

// En un DAG con aristas adj.get(u) = {v, w}: número de caminos desde s (mod p) y el más largo. Θ(V + E).
static void dagDP(int n, List<List<long[]>> adj, int s, long[] ways, long[] longest) {
    final long MOD = 1_000_000_007L, NONE = Long.MIN_VALUE;
    int[] indeg = new int[n];
    for (int u = 0; u < n; u++) for (long[] e : adj.get(u)) indeg[(int) e[0]]++;
    ArrayDeque<Integer> q = new ArrayDeque<>();
    for (int u = 0; u < n; u++) if (indeg[u] == 0) q.add(u);
    int[] order = new int[n]; int k = 0;
    while (!q.isEmpty()) {
        int u = q.poll(); order[k++] = u;
        for (long[] e : adj.get(u)) if (--indeg[(int) e[0]] == 0) q.add((int) e[0]);
    }
    java.util.Arrays.fill(ways, 0); java.util.Arrays.fill(longest, NONE);
    ways[s] = 1; longest[s] = 0;
    for (int i = 0; i < k; i++) {
        int u = order[i];
        if (longest[u] == NONE) continue;
        for (long[] e : adj.get(u)) {
            int v = (int) e[0];
            ways[v] = (ways[v] + ways[u]) % MOD;
            longest[v] = Math.max(longest[v], longest[u] + e[1]);
        }
    }
}
```

### `13/04` — DP de probabilidad [B]

De [`13/04` — DP de probabilidad y esperanza, §3](../13-dp-avanzada/04-probabilidad-y-esperanza.md#3--dp-de-probabilidad).

```java
// prob[s] = probabilidad de que n dados de k caras sumen s. Θ(n · (n·k) · k).
static double[] diceSum(int n, int k) {
    double[] prob = {1.0};
    for (int i = 0; i < n; i++) {
        double[] next = new double[prob.length + k];
        for (int s = 0; s < prob.length; s++)
            if (prob[s] > 0)
                for (int d = 1; d <= k; d++) next[s + d] += prob[s] / k;
        prob = next;
    }
    return prob;
}
```

### `13/04` — Esperanza hacia atrás [B]

De [`13/04` — DP de probabilidad y esperanza, §4](../13-dp-avanzada/04-probabilidad-y-esperanza.md#4--esperanza-hacia-atrás).

```java
static final long MOD = 1_000_000_007L;

static long power(long b, long e) {
    long r = 1; b %= MOD;
    for (; e > 0; e >>= 1, b = b * b % MOD) if ((e & 1) == 1) r = r * b % MOD;
    return r;
}

// E[0] mod MOD, con E[i] = 1 + (E[i+1] + … + E[i+m]) / m y E[i] = 0 si i ≥ n. Θ(n).
static long expectedRolls(int n, int m) {
    long invM = power(m, MOD - 2);
    long[] E = new long[n + m + 1];
    long window = 0;
    for (int i = n - 1; i >= 0; i--) {
        E[i] = (1 + window * invM) % MOD;
        window = ((window + E[i] - E[i + m]) % MOD + MOD) % MOD;
    }
    return E[0];
}
```

### `13/05` — Cola monótona [B]

De [`13/05` — Optimizaciones de DP, §3](../13-dp-avanzada/05-optimizaciones.md#3--cola-monótona).

```java
// dp[i] = c[i] + min dp[j] con j ∈ [i − R, i − L] (1 ≤ L ≤ R); dp[0] = c[0]. −1 si inalcanzable. Θ(n).
static long windowDP(long[] c, int L, int R) {
    int n = c.length;
    long[] dp = new long[n];
    java.util.Arrays.fill(dp, -1);
    dp[0] = c[0];
    int[] dq = new int[n];
    int head = 0, tail = 0;
    for (int i = 1; i < n; i++) {
        int add = i - L;
        if (add >= 0 && dp[add] != -1) {
            while (tail > head && dp[dq[tail - 1]] >= dp[add]) tail--;
            dq[tail++] = add;
        }
        while (tail > head && dq[head] < i - R) head++;
        if (tail > head) dp[i] = c[i] + dp[dq[head]];
    }
    return dp[n - 1];
}
```

### `13/05` — *Convex hull trick* [B]

De [`13/05` — Optimizaciones de DP, §4](../13-dp-avanzada/05-optimizaciones.md#4--convex-hull-trick).

```java
// Envolvente inferior de rectas y = m·x + b. Pre: pendientes decrecientes al añadir, x crecientes al consultar.
static final class MonotoneCHT {
    long[] m = new long[1 << 18], b = new long[1 << 18];       // capacidad: el máximo de rectas
    int head = 0, tail = 0;

    private boolean bad(int i1, int i2, long m3, long b3) {      // ¿sobra la recta i2?
        return java.math.BigInteger.valueOf(b3 - b[i1]).multiply(java.math.BigInteger.valueOf(m[i1] - m[i2]))
            .compareTo(java.math.BigInteger.valueOf(b[i2] - b[i1]).multiply(java.math.BigInteger.valueOf(m[i1] - m3))) <= 0;
    }
    void add(long mm, long bb) {
        if (tail > head && m[tail - 1] == mm) {
            if (b[tail - 1] <= bb) return;
            tail--;
        }
        while (tail - head >= 2 && bad(tail - 2, tail - 1, mm, bb)) tail--;
        m[tail] = mm; b[tail] = bb; tail++;
    }
    long query(long x) {
        while (tail - head >= 2 && m[head + 1] * x + b[head + 1] <= m[head] * x + b[head]) head++;
        return m[head] * x + b[head];
    }
}
```

### `13/06` — Exponenciación de matrices [B]

De [`13/06` — Recurrencias lineales y exponenciación de matrices, §3](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md#3--exponenciación-de-matrices).

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

---

## 🧱 Bloque 14 — Grafos: recorridos

### `14/01` — Representaciones [A]

De [`14/01` — Representaciones y su coste, §3](../14-grafos-recorridos/01-representaciones.md#3--representaciones).

```java
import java.io.DataInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

// Lee n, m y m aristas no dirigidas «u v w» en listas de adyacencia (índices desde 0). Cada arista: {to, w}.
static List<long[]>[] readGraph(FastReader in) throws IOException {
    int n = in.nextInt(), m = in.nextInt();
    @SuppressWarnings("unchecked")
    List<long[]>[] adj = new List[n];
    for (int i = 0; i < n; i++) adj[i] = new ArrayList<>();
    for (int i = 0; i < m; i++) {
        int u = in.nextInt() - 1, v = in.nextInt() - 1;
        long w = in.nextLong();
        adj[u].add(new long[]{v, w});
        adj[v].add(new long[]{u, w});
    }
    return adj;
}
// FastReader: el lector con DataInputStream de 01/03.
```

### `14/02` — BFS [A]

De [`14/02` — BFS, §3](../14-grafos-recorridos/02-bfs.md#3--bfs).

```java
import java.util.Arrays;

// Distancias desde las fuentes; la cola es un arreglo con cabeza y cola (cada vértice entra una vez).
static int[] bfs(int[][] adj, int[] sources, int[] parent) {
    int n = adj.length;
    int[] dist = new int[n], queue = new int[n];
    Arrays.fill(dist, -1);
    Arrays.fill(parent, -1);
    int head = 0, tail = 0;
    for (int s : sources) { dist[s] = 0; queue[tail++] = s; }
    while (head < tail) {
        int u = queue[head++];
        for (int v : adj[u])
            if (dist[v] == -1) { dist[v] = dist[u] + 1; parent[v] = u; queue[tail++] = v; }
    }
    return dist;
}
```

### `14/02` — Multifuente y rejillas [A]

De [`14/02` — BFS, §4](../14-grafos-recorridos/02-bfs.md#4--multifuente-y-rejillas).

```java
// Rejilla aplanada: casilla r · C + c; la cola es un int[R · C].
static int[] gridBfs(char[][] g, int[] sources) {
    int R = g.length, C = g[0].length;
    int[] DR = {-1, 1, 0, 0}, DC = {0, 0, -1, 1};
    int[] dist = new int[R * C], queue = new int[R * C];
    java.util.Arrays.fill(dist, -1);
    int head = 0, tail = 0;
    for (int s : sources) { dist[s] = 0; queue[tail++] = s; }
    while (head < tail) {
        int cur = queue[head++], r = cur / C, c = cur % C;
        for (int d = 0; d < 4; d++) {
            int r2 = r + DR[d], c2 = c + DC[d];
            if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C || g[r2][c2] == '#') continue;
            int nxt = r2 * C + c2;
            if (dist[nxt] == -1) { dist[nxt] = dist[cur] + 1; queue[tail++] = nxt; }
        }
    }
    return dist;
}
```

### `14/03` — DFS [A]

De [`14/03` — DFS, §3](../14-grafos-recorridos/03-dfs.md#3--dfs).

```java
// DFS iterativo con tiempos: la pila guarda el vértice; it[u] es el próximo vecino por mirar.
static int[] tin, tout, parent;

static void dfsAll(int[][] adj) {
    int n = adj.length, timer = 0;
    tin = new int[n]; tout = new int[n]; parent = new int[n];
    java.util.Arrays.fill(parent, -1);
    int[] it = new int[n], stack = new int[n];
    for (int s = 0; s < n; s++) {
        if (tin[s] != 0) continue;
        int top = 0;
        stack[top++] = s; tin[s] = ++timer;
        while (top > 0) {
            int u = stack[top - 1];
            if (it[u] < adj[u].length) {
                int v = adj[u][it[u]++];
                if (tin[v] == 0) { parent[v] = u; tin[v] = ++timer; stack[top++] = v; }
            } else {
                tout[u] = ++timer; top--;                    // todos los vecinos vistos: sale
            }
        }
    }
}
```

### `14/03` — Componentes [A]

De [`14/03` — DFS, §4](../14-grafos-recorridos/03-dfs.md#4--componentes).

```java
static int components(int[][] adj, int[] comp) {
    int n = adj.length, c = 0;
    java.util.Arrays.fill(comp, -1);
    int[] stack = new int[n];
    for (int s = 0; s < n; s++) {
        if (comp[s] != -1) continue;
        int top = 0;
        comp[s] = c; stack[top++] = s;
        while (top > 0) {
            int u = stack[--top];
            for (int v : adj[u]) if (comp[v] == -1) { comp[v] = c; stack[top++] = v; }
        }
        c++;
    }
    return c;
}
```

### `14/04` — Kahn [A]

De [`14/04` — Orden topológico y DP sobre DAG, §3](../14-grafos-recorridos/04-orden-topologico.md#3--kahn).

```java
// Orden topológico por Kahn; null si hay ciclo. La cola es el propio arreglo del orden.
static int[] kahn(int[][] adj) {
    int n = adj.length;
    int[] indeg = new int[n], order = new int[n];
    for (int[] out : adj) for (int v : out) indeg[v]++;
    int head = 0, tail = 0;
    for (int v = 0; v < n; v++) if (indeg[v] == 0) order[tail++] = v;
    while (head < tail) {
        int u = order[head++];
        for (int v : adj[u]) if (--indeg[v] == 0) order[tail++] = v;
    }
    return tail == n ? order : null;
}
```

### `14/04` — Por DFS [A]

De [`14/04` — Orden topológico y DP sobre DAG, §4](../14-grafos-recorridos/04-orden-topologico.md#4--por-dfs).

```java
// Iterativo con it[u] (14/03): al desapilar, el vértice va al postorden. null si hay ciclo.
static int[] topoDfs(int[][] adj) {
    int n = adj.length, k = n;
    int[] color = new int[n], it = new int[n], stack = new int[n], order = new int[n];
    for (int s = 0; s < n; s++) {
        if (color[s] != 0) continue;
        int top = 0;
        stack[top++] = s; color[s] = 1;
        while (top > 0) {
            int u = stack[top - 1];
            if (it[u] < adj[u].length) {
                int v = adj[u][it[u]++];
                if (color[v] == 1) return null;              // arista de retroceso
                if (color[v] == 0) { color[v] = 1; stack[top++] = v; }
            } else {
                color[u] = 2; top--;
                order[--k] = u;                              // se llena desde el final: ya invertido
            }
        }
    }
    return order;
}
```

### `14/05` — Kosaraju [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §3](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#3--kosaraju).

```java
// Kosaraju iterativo: el primer DFS con it[u] (14/03); el segundo, con una pila simple sobre el transpuesto.
static int[] kosaraju(int[][] adj, int[][] radj) {
    int n = adj.length, k = 0;
    int[] order = new int[n], it = new int[n], stack = new int[n], comp = new int[n];
    boolean[] seen = new boolean[n];
    for (int s = 0; s < n; s++) {
        if (seen[s]) continue;
        int top = 0;
        stack[top++] = s; seen[s] = true;
        while (top > 0) {
            int u = stack[top - 1];
            if (it[u] < adj[u].length) {
                int v = adj[u][it[u]++];
                if (!seen[v]) { seen[v] = true; stack[top++] = v; }
            } else { order[k++] = u; top--; }
        }
    }
    java.util.Arrays.fill(comp, -1);
    int c = 0;
    for (int i = n - 1; i >= 0; i--) {
        int s = order[i];
        if (comp[s] != -1) continue;
        int top = 0;
        stack[top++] = s; comp[s] = c;
        while (top > 0) {
            int u = stack[--top];
            for (int v : radj[u]) if (comp[v] == -1) { comp[v] = c; stack[top++] = v; }
        }
        c++;
    }
    return comp;
}
```

### `14/05` — Tarjan [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §4](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#4--tarjan).

```java
// Tarjan recursivo: con n grande, en un hilo con pila de 256 MB (03/03).
static int[] tin, low, comp, stk;
static boolean[] onStack;
static int timer, top, count;

static void tarjan(int[][] adj) {
    int n = adj.length;
    tin = new int[n]; low = new int[n]; comp = new int[n]; stk = new int[n];
    onStack = new boolean[n];
    timer = 0; top = 0; count = 0;
    for (int v = 0; v < n; v++) if (tin[v] == 0) dfs(adj, v);
}

static void dfs(int[][] adj, int u) {
    tin[u] = low[u] = ++timer;
    stk[top++] = u; onStack[u] = true;
    for (int v : adj[u]) {
        if (tin[v] == 0) { dfs(adj, v); low[u] = Math.min(low[u], low[v]); }
        else if (onStack[v]) low[u] = Math.min(low[u], tin[v]);
    }
    if (low[u] == tin[u]) {
        int w;
        do { w = stk[--top]; onStack[w] = false; comp[w] = count; } while (w != u);
        count++;
    }
}
```

### `14/05` — 2-SAT [B]

De [`14/05` — Componentes fuertemente conexas y 2-SAT, §5](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md#5--2-sat).

```java
// Sobre tarjan(int[][]) de §4. Las cláusulas se acumulan en listas y se pasan a int[][] al resolver.
static boolean[] twoSat(int n, int[][] clauses) {      // cada fila: {i, vi, j, vj} con vi, vj en {0, 1}
    java.util.List<java.util.List<Integer>> g = new java.util.ArrayList<>();
    for (int k = 0; k < 2 * n; k++) g.add(new java.util.ArrayList<>());
    for (int[] c : clauses) {
        int a = 2 * c[0] + (c[1] == 1 ? 0 : 1), b = 2 * c[2] + (c[3] == 1 ? 0 : 1);
        g.get(a ^ 1).add(b);                             // ¬a → b
        g.get(b ^ 1).add(a);                             // ¬b → a
    }
    int[][] adj = new int[2 * n][];
    for (int k = 0; k < 2 * n; k++) adj[k] = g.get(k).stream().mapToInt(Integer::intValue).toArray();
    tarjan(adj);
    boolean[] value = new boolean[n];
    for (int i = 0; i < n; i++) {
        if (comp[2 * i] == comp[2 * i + 1]) return null;
        value[i] = comp[2 * i] < comp[2 * i + 1];
    }
    return value;
}
```

### `14/06` — Puentes y puntos de articulación [B]

De [`14/06` — Puentes, puntos de articulación y Euler, §3](../14-grafos-recorridos/06-puentes-articulacion-y-euler.md#3--puentes-y-puntos-de-articulación).

```java
// Recursivo: con n grande, en un hilo con pila de 256 MB (03/03). adj[u] = {vecino, índice} alternados.
static int[] tin, low;
static boolean[] isCut, isBridge;
static int timer;

static void bridges(int[][] adj, int m) {
    int n = adj.length;
    tin = new int[n]; low = new int[n]; isCut = new boolean[n]; isBridge = new boolean[m];
    timer = 0;
    for (int s = 0; s < n; s++) if (tin[s] == 0) dfs(adj, s, -1);
}

static void dfs(int[][] adj, int u, int parentEdge) {
    tin[u] = low[u] = ++timer;
    int children = 0;
    for (int k = 0; k < adj[u].length; k += 2) {
        int v = adj[u][k], id = adj[u][k + 1];
        if (id == parentEdge) continue;
        if (tin[v] != 0) { low[u] = Math.min(low[u], tin[v]); continue; }
        dfs(adj, v, id);
        children++;
        low[u] = Math.min(low[u], low[v]);
        if (low[v] > tin[u]) isBridge[id] = true;
        if (parentEdge != -1 && low[v] >= tin[u]) isCut[u] = true;
    }
    if (parentEdge == -1 && children > 1) isCut[u] = true;
}
```

### `14/06` — Euler (Hierholzer) [B]

De [`14/06` — Puentes, puntos de articulación y Euler, §4](../14-grafos-recorridos/06-puentes-articulacion-y-euler.md#4--euler-hierholzer).

```java
// Dirigido: adj[u] = vecinos; cada arista se usa al avanzar el puntero, sin arreglo used.
static int[] eulerDirected(int[][] adj, int m, int start) {
    int[] ptr = new int[adj.length], stack = new int[m + 1], path = new int[m + 1];
    int top = 0, k = 0;
    stack[top++] = start;
    while (top > 0) {
        int u = stack[top - 1];
        if (ptr[u] < adj[u].length) stack[top++] = adj[u][ptr[u]++];
        else path[k++] = stack[--top];
    }
    if (k != m + 1) return null;
    for (int i = 0, j = k - 1; i < j; i++, j--) { int t = path[i]; path[i] = path[j]; path[j] = t; }
    return path;
}
```

---

## 🧱 Bloque 15 — Grafos con pesos y flujos

### `15/01` — Dijkstra con montículo [A]

De [`15/01` — Dijkstra, §3](../15-grafos-pesos-y-flujos/01-dijkstra.md#3--dijkstra-con-montículo).

```java
import java.util.Arrays;
import java.util.PriorityQueue;

// adj[u] = {vecino, peso} en filas de long[]. Distancias desde s; Long.MAX_VALUE = inalcanzable.
static long[] dijkstra(long[][][] adj, int s, int[] parent) {
    int n = adj.length;
    long[] dist = new long[n];
    Arrays.fill(dist, Long.MAX_VALUE);
    Arrays.fill(parent, -1);
    PriorityQueue<long[]> pq = new PriorityQueue<>((a, b) -> Long.compare(a[0], b[0]));
    dist[s] = 0;
    pq.add(new long[]{0, s});
    while (!pq.isEmpty()) {
        long[] top = pq.poll();
        long d = top[0];
        int u = (int) top[1];
        if (d > dist[u]) continue;                       // entrada vieja
        for (long[] e : adj[u]) {
            int v = (int) e[0];
            if (d + e[1] < dist[v]) {
                dist[v] = d + e[1]; parent[v] = u;
                pq.add(new long[]{dist[v], v});
            }
        }
    }
    return dist;
}
```

### `15/01` — Dijkstra sobre estados [A]

De [`15/01` — Dijkstra, §4](../15-grafos-pesos-y-flujos/01-dijkstra.md#4--dijkstra-sobre-estados).

```java
import java.util.PriorityQueue;

// Estado codificado en un entero: u · (K + 1) + k. La entrada del montículo: {dist, estado}.
static long[] dijkstraVouchers(long[][][] adj, int s, int K) {
    int n = adj.length, S = K + 1;
    long[] dist = new long[n * S];
    java.util.Arrays.fill(dist, Long.MAX_VALUE);
    PriorityQueue<long[]> pq = new PriorityQueue<>((a, b) -> Long.compare(a[0], b[0]));
    dist[s * S] = 0;
    pq.add(new long[]{0, s * S});
    while (!pq.isEmpty()) {
        long[] top = pq.poll();
        long d = top[0];
        int st = (int) top[1], u = st / S, k = st % S;
        if (d > dist[st]) continue;
        for (long[] e : adj[u]) {
            int v = (int) e[0];
            if (d + e[1] < dist[v * S + k]) { dist[v * S + k] = d + e[1]; pq.add(new long[]{d + e[1], v * S + k}); }
            if (k < K && d < dist[v * S + k + 1]) { dist[v * S + k + 1] = d; pq.add(new long[]{d, v * S + k + 1}); }
        }
    }
    long[] best = new long[n];
    for (int v = 0; v < n; v++) {
        best[v] = Long.MAX_VALUE;
        for (int k = 0; k < S; k++) best[v] = Math.min(best[v], dist[v * S + k]);
    }
    return best;
}
```

### `15/02` — Bellman-Ford [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §3](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#3--bellman-ford).

```java
// edges[i] = {u, v, w}. Distancias desde s; false si hay ciclo negativo alcanzable.
static boolean bellmanFord(int n, long[][] edges, int s, long[] dist) {
    final long INF = Long.MAX_VALUE / 4;
    java.util.Arrays.fill(dist, INF);
    dist[s] = 0;
    for (int round = 0; round < n; round++) {
        boolean changed = false;
        for (long[] e : edges) {
            int u = (int) e[0], v = (int) e[1];
            if (dist[u] != INF && dist[u] + e[2] < dist[v]) { dist[v] = dist[u] + e[2]; changed = true; }
        }
        if (!changed) return true;
        if (round == n - 1) return false;
    }
    return true;
}
```

### `15/02` — Floyd-Warshall [A]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §4](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#4--floyd-warshall).

```java
static void floydWarshall(long[][] d) {
    final long INF = Long.MAX_VALUE / 4;
    int n = d.length;
    for (int k = 0; k < n; k++)
        for (int i = 0; i < n; i++) {
            if (d[i][k] >= INF) continue;
            long[] di = d[i], dk = d[k];                 // filas en variables: menos indirecciones
            long dik = di[k];
            for (int j = 0; j < n; j++)
                if (dik + dk[j] < di[j]) di[j] = dik + dk[j];
        }
}
```

### `15/02` — Por qué no SPFA [B]

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §5](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#5--por-qué-no-spfa).

```java
// Igual que la versión de C++, con la cola en un ArrayDeque<Integer>.
static boolean spfa(long[][][] adj, int s, long[] dist) {
    int n = adj.length;
    int[] cnt = new int[n];
    boolean[] inQueue = new boolean[n];
    java.util.Arrays.fill(dist, Long.MAX_VALUE / 4);
    java.util.ArrayDeque<Integer> q = new java.util.ArrayDeque<>();
    dist[s] = 0; q.add(s); inQueue[s] = true;
    while (!q.isEmpty()) {
        int u = q.poll(); inQueue[u] = false;
        for (long[] e : adj[u]) {
            int v = (int) e[0];
            if (dist[u] + e[1] < dist[v]) {
                dist[v] = dist[u] + e[1];
                if (!inQueue[v]) {
                    if (++cnt[v] >= n) return false;
                    q.add(v); inQueue[v] = true;
                }
            }
        }
    }
    return true;
}
```

### `15/03` — A\* [B]

De [`15/03` — A\* y heurísticas admisibles, §3](../15-grafos-pesos-y-flujos/03-a-estrella.md#3--a).

```java
// Misma idea; la entrada del montículo es {f, g, casilla} y el comparador desempata por mayor g.
static int aStar(char[][] g, int sr, int sc, int tr, int tc) {
    int R = g.length, C = g[0].length;
    int[] DR = {-1, 1, 0, 0}, DC = {0, 0, -1, 1};
    int[] dist = new int[R * C];
    java.util.Arrays.fill(dist, Integer.MAX_VALUE);
    java.util.PriorityQueue<int[]> pq = new java.util.PriorityQueue<>(
        (a, b) -> a[0] != b[0] ? Integer.compare(a[0], b[0]) : Integer.compare(b[1], a[1]));
    dist[sr * C + sc] = 0;
    pq.add(new int[]{Math.abs(sr - tr) + Math.abs(sc - tc), 0, sr * C + sc});
    while (!pq.isEmpty()) {
        int[] top = pq.poll();
        int g0 = top[1], cur = top[2], r = cur / C, c = cur % C;
        if (g0 > dist[cur]) continue;
        if (r == tr && c == tc) return g0;
        for (int d = 0; d < 4; d++) {
            int r2 = r + DR[d], c2 = c + DC[d];
            if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C || g[r2][c2] == '#') continue;
            int nxt = r2 * C + c2;
            if (g0 + 1 < dist[nxt]) {
                dist[nxt] = g0 + 1;
                pq.add(new int[]{g0 + 1 + Math.abs(r2 - tr) + Math.abs(c2 - tc), g0 + 1, nxt});
            }
        }
    }
    return -1;
}
```

### `15/04` — Kruskal [A]

De [`15/04` — Árbol de expansión mínima, §3](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#3--kruskal).

```java
// edges[i] = {u, v, w}. Peso del MST, o −1 si no es conexo.
static long kruskal(int n, long[][] edges) {
    java.util.Arrays.sort(edges, (a, b) -> Long.compare(a[2], b[2]));
    int[] parent = new int[n], size = new int[n];
    for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; }
    long total = 0;
    int used = 0;
    for (long[] e : edges) {
        int a = find(parent, (int) e[0]), b = find(parent, (int) e[1]);
        if (a == b) continue;
        if (size[a] < size[b]) { int t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b];
        total += e[2];
        if (++used == n - 1) break;
    }
    return used == n - 1 ? total : -1;
}

static int find(int[] parent, int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}
```

### `15/04` — Prim [A]

De [`15/04` — Árbol de expansión mínima, §4](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#4--prim).

```java
static long prim(long[][][] adj) {
    int n = adj.length, taken = 0;
    boolean[] inTree = new boolean[n];
    java.util.PriorityQueue<long[]> pq = new java.util.PriorityQueue<>((a, b) -> Long.compare(a[0], b[0]));
    pq.add(new long[]{0, 0});
    long total = 0;
    while (!pq.isEmpty() && taken < n) {
        long[] top = pq.poll();
        int u = (int) top[1];
        if (inTree[u]) continue;
        inTree[u] = true; total += top[0]; taken++;
        for (long[] e : adj[u]) if (!inTree[(int) e[0]]) pq.add(new long[]{e[1], e[0]});
    }
    return taken == n ? total : -1;
}
```

### `15/05` — Ford-Fulkerson y Edmonds-Karp [B]

De [`15/05` — Flujo máximo y corte mínimo, §3](../15-grafos-pesos-y-flujos/05-flujo-maximo.md#3--ford-fulkerson-y-edmonds-karp).

```java
// Misma estructura con arreglos: to[e], cap[e], y la vuelta de e en e ^ 1.
static int[] head, next, to;
static long[] cap;
static int edgeCount;

static void init(int n, int maxEdges) {
    head = new int[n]; java.util.Arrays.fill(head, -1);
    next = new int[2 * maxEdges]; to = new int[2 * maxEdges]; cap = new long[2 * maxEdges];
    edgeCount = 0;
}

static void addEdge(int u, int v, long c) {
    to[edgeCount] = v; cap[edgeCount] = c; next[edgeCount] = head[u]; head[u] = edgeCount++;
    to[edgeCount] = u; cap[edgeCount] = 0; next[edgeCount] = head[v]; head[v] = edgeCount++;
}

static long maxFlow(int n, int s, int t) {
    long flow = 0;
    int[] parentEdge = new int[n], queue = new int[n];
    while (true) {
        java.util.Arrays.fill(parentEdge, -1);
        int qh = 0, qt = 0;
        queue[qt++] = s;
        while (qh < qt && parentEdge[t] == -1) {
            int u = queue[qh++];
            for (int e = head[u]; e != -1; e = next[e])
                if (cap[e] > 0 && to[e] != s && parentEdge[to[e]] == -1) { parentEdge[to[e]] = e; queue[qt++] = to[e]; }
        }
        if (parentEdge[t] == -1) return flow;
        long push = Long.MAX_VALUE;
        for (int v = t; v != s; v = to[parentEdge[v] ^ 1]) push = Math.min(push, cap[parentEdge[v]]);
        for (int v = t; v != s; v = to[parentEdge[v] ^ 1]) { cap[parentEdge[v]] -= push; cap[parentEdge[v] ^ 1] += push; }
        flow += push;
    }
}
```

### `15/05` — Dinic [B]

De [`15/05` — Flujo máximo y corte mínimo, §4](../15-grafos-pesos-y-flujos/05-flujo-maximo.md#4--dinic).

```java
// Sobre los arreglos head/next/to/cap de §3. level e it por vértice; it guarda una arista (índice), no una posición.
static int[] level, it;

static boolean bfs(int n, int s, int t) {
    level = new int[n]; java.util.Arrays.fill(level, -1);
    int[] queue = new int[n];
    int qh = 0, qt = 0;
    queue[qt++] = s; level[s] = 0;
    while (qh < qt) {
        int u = queue[qh++];
        for (int e = head[u]; e != -1; e = next[e])
            if (cap[e] > 0 && level[to[e]] == -1) { level[to[e]] = level[u] + 1; queue[qt++] = to[e]; }
    }
    return level[t] != -1;
}

static long dfs(int u, int t, long pushed) {
    if (u == t) return pushed;
    for (; it[u] != -1; it[u] = next[it[u]]) {
        int e = it[u], v = to[e];
        if (cap[e] > 0 && level[v] == level[u] + 1) {
            long got = dfs(v, t, Math.min(pushed, cap[e]));
            if (got > 0) { cap[e] -= got; cap[e ^ 1] += got; return got; }
        }
    }
    return 0;
}

static long dinic(int n, int s, int t) {
    long flow = 0;
    while (bfs(n, s, t)) {
        it = head.clone();                               // el puntero empieza en la primera arista
        long f;
        while ((f = dfs(s, t, Long.MAX_VALUE)) > 0) flow += f;
    }
    return flow;
}
```

### `15/06` — Kuhn [B]

De [`15/06` — Emparejamientos, §3](../15-grafos-pesos-y-flujos/06-emparejamientos.md#3--kuhn).

```java
// matchR[v] = pareja de v (derecha), o −1. seen por ronda para no reinicializar.
static int[][] adj;
static int[] matchR, seen;
static int round;

static boolean tryKuhn(int u) {
    for (int v : adj[u]) {
        if (seen[v] == round) continue;
        seen[v] = round;
        if (matchR[v] == -1 || tryKuhn(matchR[v])) { matchR[v] = u; return true; }
    }
    return false;
}

static int maxMatching(int nr) {
    matchR = new int[nr]; seen = new int[nr];
    java.util.Arrays.fill(matchR, -1);
    int result = 0;
    for (int u = 0; u < adj.length; u++) { round++; if (tryKuhn(u)) result++; }
    return result;
}
```

---

## 🧱 Bloque 16 — Cadenas

### `16/01` — Inmutabilidad y concatenación [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §3](../16-cadenas/01-cadenas-y-patrones-basicos.md#3--inmutabilidad-y-concatenación).

```java
// En Java: StringBuilder, y toString() una sola vez al final.
static String joinWords(String[] words, char sep) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < words.length; i++) {
        if (i > 0) sb.append(sep);
        sb.append(words[i]);
    }
    return sb.toString();
}
// Para la salida de un programa, todo en un StringBuilder (o un PrintWriter con búfer) y un solo print.
```

### `16/01` — Frecuencias y anagramas [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §4](../16-cadenas/01-cadenas-y-patrones-basicos.md#4--frecuencias-y-anagramas).

```java
static int[] freq(String s) {
    int[] f = new int[26];
    for (int i = 0; i < s.length(); i++) f[s.charAt(i) - 'a']++;
    return f;
}

static boolean isAnagram(String a, String b) {
    return a.length() == b.length() && java.util.Arrays.equals(freq(a), freq(b));
}

// Firma para agrupar en un HashMap: la cadena ordenada (o Arrays.toString(freq(s))).
static String signature(String s) {
    char[] c = s.toCharArray();
    java.util.Arrays.sort(c);
    return new String(c);
}
```

### `16/01` — Palíndromos con dos punteros [A]

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §5](../16-cadenas/01-cadenas-y-patrones-basicos.md#5--palíndromos-con-dos-punteros).

```java
static int mismatches(String s, int l, int r) {
    int count = 0;
    while (l < r) { if (s.charAt(l) != s.charAt(r)) count++; l++; r--; }
    return count;
}
```

### `16/02` — Función de prefijo [A]

De [`16/02` — KMP y la función de prefijo, §3](../16-cadenas/02-kmp.md#3--función-de-prefijo).

```java
static int[] prefixFunction(String s) {
    int n = s.length();
    int[] pi = new int[n];
    for (int i = 1; i < n; i++) {
        int k = pi[i - 1];
        while (k > 0 && s.charAt(i) != s.charAt(k)) k = pi[k - 1];
        if (s.charAt(i) == s.charAt(k)) k++;
        pi[i] = k;
    }
    return pi;
}
```

### `16/02` — KMP [A]

De [`16/02` — KMP y la función de prefijo, §4](../16-cadenas/02-kmp.md#4--kmp).

```java
static java.util.List<Integer> kmpSearch(String t, String p) {
    int[] pi = prefixFunction(p);
    java.util.List<Integer> found = new java.util.ArrayList<>();
    int m = p.length(), k = 0;
    for (int i = 0; i < t.length(); i++) {
        while (k > 0 && t.charAt(i) != p.charAt(k)) k = pi[k - 1];
        if (t.charAt(i) == p.charAt(k)) k++;
        if (k == m) { found.add(i - m + 1); k = pi[k - 1]; }
    }
    return found;
}
```

### `16/02` — Autómata de KMP [B]

De [`16/02` — KMP y la función de prefijo, §5](../16-cadenas/02-kmp.md#5--autómata-de-kmp).

```java
static int[][] kmpAutomaton(String p) {
    int m = p.length();
    int[] pi = prefixFunction(p);
    int[][] delta = new int[m + 1][26];
    for (int q = 0; q <= m; q++)
        for (int c = 0; c < 26; c++) {
            if (q < m && p.charAt(q) - 'a' == c) delta[q][c] = q + 1;
            else delta[q][c] = q == 0 ? 0 : delta[pi[q - 1]][c];
        }
    return delta;
}
```

### `16/03` — Función Z [B]

De [`16/03` — Función Z y Manacher, §3](../16-cadenas/03-funcion-z-y-manacher.md#3--función-z).

```java
static int[] zFunction(String s) {
    int n = s.length();
    int[] z = new int[n];
    for (int i = 1, l = 0, r = 0; i < n; i++) {
        if (i < r) z[i] = Math.min(r - i, z[i - l]);
        while (i + z[i] < n && s.charAt(z[i]) == s.charAt(i + z[i])) z[i]++;
        if (i + z[i] > r) { l = i; r = i + z[i]; }
    }
    return z;
}
```

### `16/03` — Manacher [B]

De [`16/03` — Función Z y Manacher, §4](../16-cadenas/03-funcion-z-y-manacher.md#4--manacher).

```java
static int[] manacher(String s) {
    StringBuilder sb = new StringBuilder("#");
    for (char c : s.toCharArray()) sb.append(c).append('#');
    char[] t = sb.toString().toCharArray();
    int n = t.length;
    int[] d = new int[n];
    for (int i = 0, l = 0, r = -1; i < n; i++) {
        int k = (i > r) ? 1 : Math.min(d[l + r - i], r - i + 1);
        while (i - k >= 0 && i + k < n && t[i - k] == t[i + k]) k++;
        d[i] = k;
        if (i + k - 1 > r) { l = i - k + 1; r = i + k - 1; }
    }
    for (int i = 0; i < n; i++) d[i]--;
    return d;
}
```

### `16/04` — Comparar subcadenas [B]

De [`16/04` — *Hashing* de cadenas aplicado, §3](../16-cadenas/04-hashing-de-cadenas.md#3--comparar-subcadenas).

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

### `16/04` — Binaria + *hash* [B]

De [`16/04` — *Hashing* de cadenas aplicado, §4](../16-cadenas/04-hashing-de-cadenas.md#4--binaria--hash).

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

### `16/05` — Aho-Corasick [B]

De [`16/05` — Aho-Corasick, §3](../16-cadenas/05-aho-corasick.md#3--aho-corasick).

```java
// Misma estructura con arreglos que crecen: go[nodo * 26 + c].
static int[] go = new int[26], fail = new int[1];
static int nodes = 1;
static int[] order;
static java.util.List<Integer> endOf = new java.util.ArrayList<>();
static { java.util.Arrays.fill(go, -1); }               // la raíz empieza sin hijos

static int newNode() {
    if ((nodes + 1) * 26 > go.length) { go = java.util.Arrays.copyOf(go, go.length * 2); fail = java.util.Arrays.copyOf(fail, fail.length * 2); }
    java.util.Arrays.fill(go, nodes * 26, nodes * 26 + 26, -1);
    return nodes++;
}

static void add(String p) {
    int u = 0;
    for (int i = 0; i < p.length(); i++) {
        int c = p.charAt(i) - 'a';
        if (go[u * 26 + c] == -1) { int v = newNode(); go[u * 26 + c] = v; }
        u = go[u * 26 + c];
    }
    endOf.add(u);
}

static void build() {
    order = new int[nodes];
    int qh = 0, qt = 0;
    for (int c = 0; c < 26; c++)
        if (go[c] == -1) go[c] = 0;
        else { fail[go[c]] = 0; order[qt++] = go[c]; }
    while (qh < qt) {
        int u = order[qh++];
        for (int c = 0; c < 26; c++) {
            int v = go[u * 26 + c];
            if (v == -1) go[u * 26 + c] = go[fail[u] * 26 + c];
            else { fail[v] = go[fail[u] * 26 + c]; order[qt++] = v; }
        }
    }
    order = java.util.Arrays.copyOf(order, qt);
}

static long[] count(String t) {
    long[] visits = new long[nodes];
    int u = 0;
    for (int i = 0; i < t.length(); i++) { u = go[u * 26 + t.charAt(i) - 'a']; visits[u]++; }
    for (int i = order.length - 1; i >= 0; i--) visits[fail[order[i]]] += visits[order[i]];
    long[] res = new long[endOf.size()];
    for (int i = 0; i < res.length; i++) res[i] = visits[endOf.get(i)];
    return res;
}
```

### `16/06` — *Suffix array* en `O(n log n)` [B]

De [`16/06` — *Suffix array*, LCP y *suffix automaton*, §3](../16-cadenas/06-suffix-array-y-automaton.md#3--suffix-array-en-on-log-n).

```java
// Versión n log² n con sort de pares: más corta y suficiente con n ≤ 2·10⁵.
static int[] suffixArray(String s) {
    int n = s.length();
    Integer[] sa = new Integer[n];
    int[] rank = new int[n], tmp = new int[n];
    for (int i = 0; i < n; i++) { sa[i] = i; rank[i] = s.charAt(i); }
    for (int k = 1; ; k <<= 1) {
        final int kk = k;
        final int[] r = rank;
        java.util.Comparator<Integer> cmp = (a, b) -> {
            if (r[a] != r[b]) return Integer.compare(r[a], r[b]);
            int ra = a + kk < n ? r[a + kk] : -1, rb = b + kk < n ? r[b + kk] : -1;
            return Integer.compare(ra, rb);
        };
        java.util.Arrays.sort(sa, cmp);
        tmp[sa[0]] = 0;
        for (int i = 1; i < n; i++) tmp[sa[i]] = tmp[sa[i - 1]] + (cmp.compare(sa[i - 1], sa[i]) < 0 ? 1 : 0);
        System.arraycopy(tmp, 0, rank, 0, n);
        if (rank[sa[n - 1]] == n - 1) break;             // todos los rangos distintos
    }
    int[] res = new int[n];
    for (int i = 0; i < n; i++) res[i] = sa[i];
    return res;
}
```

### `16/06` — LCP de Kasai [B]

De [`16/06` — *Suffix array*, LCP y *suffix automaton*, §4](../16-cadenas/06-suffix-array-y-automaton.md#4--lcp-de-kasai).

```java
static int[] kasai(String s, int[] sa) {
    int n = s.length(), h = 0;
    int[] rank = new int[n], lcp = new int[n];
    for (int k = 0; k < n; k++) rank[sa[k]] = k;
    for (int i = 0; i < n; i++) {
        if (rank[i] == 0) { h = 0; continue; }
        int j = sa[rank[i] - 1];
        while (i + h < n && j + h < n && s.charAt(i + h) == s.charAt(j + h)) h++;
        lcp[rank[i]] = h;
        if (h > 0) h--;
    }
    return lcp;
}
```

### `16/07` — DFA y NFA [B]

De [`16/07` — Autómatas y expresiones regulares, §3](../16-cadenas/07-automatas-y-expresiones-regulares.md#3--dfa-y-nfa).

```java
static boolean runDfa(int[][] delta, boolean[] isFinal, int[] input) {
    int q = 0;
    for (int c : input) q = delta[q][c];
    return isFinal[q];
}

static int[][] multipleOfK(int k) {
    int[][] delta = new int[k][2];
    for (int q = 0; q < k; q++) for (int b = 0; b < 2; b++) delta[q][b] = (2 * q + b) % k;
    return delta;
}
```

### `16/07` — Thompson [B]

De [`16/07` — Autómatas y expresiones regulares, §4](../16-cadenas/07-automatas-y-expresiones-regulares.md#4--thompson).

```java
// Misma construcción; el grafo ε como listas y los activos como boolean[].
static String re;
static int m;
static java.util.List<java.util.List<Integer>> eps;

static void build(String regexp) {
    re = "(" + regexp + ")"; m = re.length();
    eps = new java.util.ArrayList<>();
    for (int i = 0; i <= m; i++) eps.add(new java.util.ArrayList<>());
    java.util.ArrayDeque<Integer> ops = new java.util.ArrayDeque<>();
    for (int i = 0; i < m; i++) {
        int lp = i;
        char c = re.charAt(i);
        if (c == '(' || c == '|') ops.push(i);
        else if (c == ')') {
            int orIdx = ops.pop();
            if (re.charAt(orIdx) == '|') { lp = ops.pop(); eps.get(lp).add(orIdx + 1); eps.get(orIdx).add(i); }
            else lp = orIdx;
        }
        if (i < m - 1 && re.charAt(i + 1) == '*') { eps.get(lp).add(i + 1); eps.get(i + 1).add(lp); }
        if (c == '(' || c == '*' || c == ')') eps.get(i).add(i + 1);
    }
}

static void closure(boolean[] active) {
    java.util.ArrayDeque<Integer> st = new java.util.ArrayDeque<>();
    for (int v = 0; v <= m; v++) if (active[v]) st.push(v);
    while (!st.isEmpty()) {
        int v = st.pop();
        for (int w : eps.get(v)) if (!active[w]) { active[w] = true; st.push(w); }
    }
}

static boolean matches(String txt) {
    boolean[] active = new boolean[m + 1];
    active[0] = true; closure(active);
    for (int k = 0; k < txt.length(); k++) {
        char c = txt.charAt(k);
        boolean[] next = new boolean[m + 1];
        for (int v = 0; v < m; v++) if (active[v] && (re.charAt(v) == c || re.charAt(v) == '.')) next[v + 1] = true;
        closure(next);
        active = next;
    }
    return active[m];
}
```

---

## 🧱 Bloque 17 — Matemática

### `17/01` — Operaciones y trucos [A]

De [`17/01` — Bits, §3](../17-matematica/01-bits.md#3--operaciones-y-trucos).

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

### `17/01` — `bitset` como optimización [B]

De [`17/01` — Bits, §4](../17-matematica/01-bits.md#4--bitset-como-optimización).

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

### `17/01` — Base XOR [B]

De [`17/01` — Bits, §5](../17-matematica/01-bits.md#5--base-xor).

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

### `17/02` — Euclides [A]

De [`17/02` — Divisibilidad, §3](../17-matematica/02-divisibilidad.md#3--euclides).

```java
static long gcd(long a, long b) {
    a = Math.abs(a); b = Math.abs(b);
    while (b != 0) { long t = a % b; a = b; b = t; }
    return a;
}

static long lcm(long a, long b) {
    if (a == 0 || b == 0) return 0;
    return a / gcd(a, b) * b;
}
// java.math.BigInteger.gcd para enteros grandes.
```

### `17/02` — Euclides extendido [A]

De [`17/02` — Divisibilidad, §4](../17-matematica/02-divisibilidad.md#4--euclides-extendido).

```java
// Devuelve {g, x, y} con a·x + b·y = g.
static long[] extGcd(long a, long b) {
    long x0 = 1, y0 = 0, x1 = 0, y1 = 1;
    while (b != 0) {
        long q = a / b, t;
        t = a - q * b; a = b; b = t;
        t = x0 - q * x1; x0 = x1; x1 = t;
        t = y0 - q * y1; y0 = y1; y1 = t;
    }
    return new long[]{a, x0, y0};
}
```

### `17/02` — Diofánticas lineales [A]

De [`17/02` — Divisibilidad, §5](../17-matematica/02-divisibilidad.md#5--diofánticas-lineales).

```java
// Con long y Math.floorDiv (redondea hacia −∞); ⌈−x0/sx⌉ = −⌊x0/sx⌋. c hasta 10⁹ para que x0, y0 quepan en long.
static long countNonNegative(long a, long b, long c) {
    long[] e = extGcd(a, b);
    long g = e[0];
    if (c % g != 0) return 0;
    long x0 = e[1] * (c / g), y0 = e[2] * (c / g), sx = b / g, sy = a / g;
    long lo = -Math.floorDiv(x0, sx), hi = Math.floorDiv(y0, sy);
    return Math.max(0, hi - lo + 1);
}
```

### `17/03` — Exponenciación modular [A]

De [`17/03` — Aritmética modular, §3](../17-matematica/03-aritmetica-modular.md#3--exponenciación-modular).

```java
// a^e mod m con m < 2^31: los productos de dos restos caben en long.
static long powMod(long a, long e, long m) {
    long result = 1 % m;
    a %= m;
    if (a < 0) a += m;
    while (e > 0) {
        if ((e & 1) == 1) result = result * a % m;
        a = a * a % m;
        e >>= 1;
    }
    return result;
}
// Con m hasta 10¹⁸: BigInteger.modPow, o multiplicar con Math.multiplyHigh.
```

### `17/03` — Inverso modular [A]

De [`17/03` — Aritmética modular, §4](../17-matematica/03-aritmetica-modular.md#4--inverso-modular).

```java
static long invFermat(long a, long p) { return powMod(a, p - 2, p); }

static long invExt(long a, long m) {                             // usa extGcd de 17/02
    long[] e = extGcd(((a % m) + m) % m, m);
    if (e[0] != 1) return -1;
    return ((e[1] % m) + m) % m;
}

static long[] inversesUpTo(int n, long p) {
    long[] inv = new long[n + 1];
    inv[1] = 1;
    for (int i = 2; i <= n; i++) inv[i] = (p - (p / i) * inv[(int) (p % i)] % p) % p;
    return inv;
}
```

### `17/03` — Teorema chino del resto [B]

De [`17/03` — Aritmética modular, §5](../17-matematica/03-aritmetica-modular.md#5--teorema-chino-del-resto).

```java
// Con BigInteger para no preocuparse del mcm; long[] r = {a, m}.
static boolean crtMerge(java.math.BigInteger[] r, long a2, long m2) {
    java.math.BigInteger a1 = r[0], m1 = r[1], A2 = java.math.BigInteger.valueOf(a2), M2 = java.math.BigInteger.valueOf(m2);
    java.math.BigInteger g = m1.gcd(M2), diff = A2.subtract(a1);
    if (diff.mod(g).signum() != 0) return false;
    java.math.BigInteger m2g = M2.divide(g);
    java.math.BigInteger t = diff.divide(g).multiply(m1.divide(g).modInverse(m2g)).mod(m2g);
    r[0] = a1.add(m1.multiply(t));
    r[1] = m1.multiply(m2g);
    r[0] = r[0].mod(r[1]);
    return true;
}
```

### `17/04` — Criba de Eratóstenes [A]

De [`17/04` — Primos, §3](../17-matematica/04-primos.md#3--criba-de-eratóstenes).

```java
static boolean[] sieve(int n) {
    boolean[] isPrime = new boolean[n + 1];
    java.util.Arrays.fill(isPrime, true);
    isPrime[0] = false;
    if (n >= 1) isPrime[1] = false;
    for (long p = 2; p * p <= n; p++)
        if (isPrime[(int) p])
            for (long q = p * p; q <= n; q += p) isPrime[(int) q] = false;
    return isPrime;
}
```

### `17/04` — Criba lineal y menor factor primo [A]

De [`17/04` — Primos, §4](../17-matematica/04-primos.md#4--criba-lineal-y-menor-factor-primo).

```java
static int[] spf;
static int[] primes;
static int primeCount;

static void linearSieve(int n) {
    spf = new int[n + 1];
    primes = new int[n + 1];
    primeCount = 0;
    for (int i = 2; i <= n; i++) {
        if (spf[i] == 0) { spf[i] = i; primes[primeCount++] = i; }
        for (int k = 0; k < primeCount; k++) {
            int p = primes[k];
            if (p > spf[i] || (long) i * p > n) break;
            spf[i * p] = p;
        }
    }
}

static java.util.List<int[]> factorize(int x) {             // {primo, exponente}
    java.util.List<int[]> f = new java.util.ArrayList<>();
    while (x > 1) {
        int p = spf[x], e = 0;
        while (x % p == 0) { x /= p; e++; }
        f.add(new int[]{p, e});
    }
    return f;
}
```

### `17/04` — Criba segmentada [B]

De [`17/04` — Primos, §5](../17-matematica/04-primos.md#5--criba-segmentada).

```java
static boolean[] segmentedSieve(long L, long R, int[] basePrimes, int count) {
    boolean[] isPrime = new boolean[(int) (R - L + 1)];
    java.util.Arrays.fill(isPrime, true);
    for (int k = 0; k < count; k++) {
        long p = basePrimes[k];
        if (p * p > R) break;
        long start = Math.max(p * p, (L + p - 1) / p * p);
        for (long q = start; q <= R; q += p) isPrime[(int) (q - L)] = false;
    }
    for (long x = L; x <= Math.min(R, 1); x++) isPrime[(int) (x - L)] = false;
    return isPrime;
}
```

### `17/04` — Miller-Rabin [B]

De [`17/04` — Primos, §7](../17-matematica/04-primos.md#7--miller-rabin).

```java
// BigInteger para el producto de 128 bits; BigInteger.isProbablePrime también existe (probabilístico).
static boolean isPrime64(long n) {
    if (n < 2) return false;
    long[] bases = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37};
    for (long p : bases) if (n % p == 0) return n == p;
    java.math.BigInteger N = java.math.BigInteger.valueOf(n), N1 = N.subtract(java.math.BigInteger.ONE);
    long d = n - 1; int s = 0;
    while ((d & 1) == 0) { d >>= 1; s++; }
    java.math.BigInteger D = java.math.BigInteger.valueOf(d);
    for (long a : bases) {
        java.math.BigInteger x = java.math.BigInteger.valueOf(a).modPow(D, N);
        if (x.equals(java.math.BigInteger.ONE) || x.equals(N1)) continue;
        boolean composite = true;
        for (int r = 1; r < s && composite; r++) { x = x.multiply(x).mod(N); if (x.equals(N1)) composite = false; }
        if (composite) return false;
    }
    return true;
}
```

### `17/05` — `nCr` con factoriales [A]

De [`17/05` — Combinatoria, §3](../17-matematica/05-combinatoria.md#3--ncr-con-factoriales).

```java
static final long MOD = 1_000_000_007L;
static long[] fact, invFact;

static void initBinomial(int n) {
    fact = new long[n + 1]; invFact = new long[n + 1];
    fact[0] = 1;
    for (int i = 1; i <= n; i++) fact[i] = fact[i - 1] * i % MOD;
    invFact[n] = powMod(fact[n], MOD - 2, MOD);             // powMod de 17/03
    for (int i = n; i > 0; i--) invFact[i - 1] = invFact[i] * i % MOD;
}

static long C(int n, int k) {
    if (k < 0 || k > n) return 0;
    return fact[n] * invFact[k] % MOD * invFact[n - k] % MOD;
}
```

### `17/05` — Lucas [B]

De [`17/05` — Combinatoria, §5](../17-matematica/05-combinatoria.md#5--lucas).

```java
static long luP;
static long[] luFact, luInv;

static void initLucas(int p) {
    luP = p; luFact = new long[p]; luInv = new long[p];
    luFact[0] = 1;
    for (int i = 1; i < p; i++) luFact[i] = luFact[i - 1] * i % p;
    luInv[p - 1] = p - 1;                                                  // Wilson
    for (int i = p - 1; i > 0; i--) luInv[i - 1] = luInv[i] * i % p;
}

static long lucas(long n, long k) {
    long r = 1;
    while (n > 0 || k > 0) {
        int ni = (int) (n % luP), ki = (int) (k % luP);
        if (ki > ni) return 0;
        r = r * luFact[ni] % luP * luInv[ki] % luP * luInv[ni - ki] % luP;
        n /= luP; k /= luP;
    }
    return r;
}
```

### `17/05` — Catalan [B]

De [`17/05` — Combinatoria, §6](../17-matematica/05-combinatoria.md#6--catalan).

```java
static long catalan(int n) { return (C(2 * n, n) - C(2 * n, n + 1) + MOD) % MOD; }   // initBinomial(2n)
```

### `17/05` — Inclusión-exclusión [B]

De [`17/05` — Combinatoria, §7](../17-matematica/05-combinatoria.md#7--inclusión-exclusión).

```java
static long multiplesOfAny(long N, long[] ns) {
    int k = ns.length;
    long total = 0;
    for (int mask = 1; mask < (1 << k); mask++) {
        long l = 1;
        boolean tooBig = false;
        for (int i = 0; i < k && !tooBig; i++)
            if ((mask >> i & 1) == 1) {
                long g = gcd(l, ns[i]);                   // gcd de 17/02
                if (l / g > N / ns[i]) tooBig = true;     // l/g · ns[i] > N sin desbordar
                else l = l / g * ns[i];
            }
        if (tooBig) continue;
        total += (Integer.bitCount(mask) & 1) == 1 ? N / l : -(N / l);
    }
    return total;
}
```

### `17/06` — Linealidad de la esperanza [B]

De [`17/06` — Probabilidad y esperanza, §3](../17-matematica/06-probabilidad-y-esperanza.md#3--linealidad-de-la-esperanza).

```java
static final long MOD = 1_000_000_007L;                   // powMod de 17/03

static long expectedDistinct(long n, long k) {
    long invN = powMod(n % MOD, MOD - 2, MOD);
    long q = (n - 1) % MOD * invN % MOD;
    long notSeen = powMod(q, k, MOD);
    return n % MOD * ((1 - notSeen + MOD) % MOD) % MOD;
}
```

### `17/06` — Indicadoras [B]

De [`17/06` — Probabilidad y esperanza, §4](../17-matematica/06-probabilidad-y-esperanza.md#4--indicadoras).

```java
static long expectedInversions(long[] a) {
    long n = a.length;
    java.util.Map<Long, Long> freq = new java.util.HashMap<>();
    for (long v : a) freq.merge(v, 1L, Long::sum);
    long pairs = n * (n - 1) / 2 % MOD;
    for (long c : freq.values()) pairs = (pairs - c * (c - 1) / 2 % MOD + MOD) % MOD;
    return pairs * ((MOD + 1) / 2) % MOD;
}
```

### `17/07` — Exponenciación [B]

De [`17/07` — Matrices y eliminación de Gauss, §3](../17-matematica/07-matrices-y-gauss.md#3--exponenciación).

```java
static final long MOD = 1_000_000_007L;

static long[][] multiply(long[][] A, long[][] B) {
    int n = A.length, m = B[0].length, inner = B.length;
    long[][] C = new long[n][m];
    for (int i = 0; i < n; i++)
        for (int k = 0; k < inner; k++) {
            long a = A[i][k];
            if (a == 0) continue;
            for (int j = 0; j < m; j++) C[i][j] = (C[i][j] + a * B[k][j]) % MOD;
        }
    return C;
}

static long[][] matPow(long[][] A, long k) {
    int n = A.length;
    long[][] R = new long[n][n];
    for (int i = 0; i < n; i++) R[i][i] = 1;
    for (; k > 0; k >>= 1) {
        if ((k & 1) == 1) R = multiply(R, A);
        A = multiply(A, A);
    }
    return R;
}
```

### `17/07` — Gauss [B]

De [`17/07` — Matrices y eliminación de Gauss, §4](../17-matematica/07-matrices-y-gauss.md#4--gauss).

```java
// Con double y pivote parcial; EPS para decidir si un valor es cero. Devuelve 0, 1 o 2 como la de C++.
static int gaussDouble(double[][] a, int m, double[] x) {
    final double EPS = 1e-9;
    int n = a.length, row = 0;
    int[] where = new int[m];
    java.util.Arrays.fill(where, -1);
    for (int col = 0; col < m && row < n; col++) {
        int sel = row;
        for (int i = row; i < n; i++) if (Math.abs(a[i][col]) > Math.abs(a[sel][col])) sel = i;   // pivote parcial
        if (Math.abs(a[sel][col]) < EPS) continue;
        double[] t = a[sel]; a[sel] = a[row]; a[row] = t;
        where[col] = row;
        for (int i = 0; i < n; i++)
            if (i != row) {
                double f = a[i][col] / a[row][col];
                for (int j = col; j <= m; j++) a[i][j] -= f * a[row][j];
            }
        row++;
    }
    for (int j = 0; j < m; j++) x[j] = where[j] == -1 ? 0 : a[where[j]][m] / a[where[j]][j];
    for (int i = 0; i < n; i++) {                                // comprobar la solución
        double s = 0;
        for (int j = 0; j < m; j++) s += a[i][j] * x[j];
        if (Math.abs(s - a[i][m]) > EPS) return 0;
    }
    for (int j = 0; j < m; j++) if (where[j] == -1) return 2;
    return 1;
}
```

### `17/07` — Sobre GF(2) [B]

De [`17/07` — Matrices y eliminación de Gauss, §5](../17-matematica/07-matrices-y-gauss.md#5--sobre-gf2).

```java
// Filas como long[] de (m + 1 + 63) / 64 palabras; mismo algoritmo.
static int gaussGF2(long[][] a, int m) {
    int n = a.length, row = 0, words = a[0].length;
    for (int col = 0; col < m && row < n; col++) {
        int w = col >> 6; long bit = 1L << (col & 63);
        int sel = row;
        while (sel < n && (a[sel][w] & bit) == 0) sel++;
        if (sel == n) continue;
        long[] t = a[sel]; a[sel] = a[row]; a[row] = t;
        for (int i = 0; i < n; i++)
            if (i != row && (a[i][w] & bit) != 0)
                for (int k = 0; k < words; k++) a[i][k] ^= a[row][k];
        row++;
    }
    int wb = m >> 6; long bb = 1L << (m & 63);
    for (int i = row; i < n; i++) if ((a[i][wb] & bb) != 0) return -1;
    return row;
}
```

### `17/08` — Juegos sobre DAG [B]

De [`17/08` — Teoría de juegos, §3](../17-matematica/08-teoria-de-juegos.md#3--juegos-sobre-dag).

```java
static int[][] moves;
static int[] memo;                                        // −1, 0, 1

static int wins(int v) {
    if (memo[v] != -1) return memo[v];
    int r = 0;
    for (int w : moves[v]) if (wins(w) == 0) { r = 1; break; }
    return memo[v] = r;
}
```

### `17/08` — Nim [B]

De [`17/08` — Teoría de juegos, §4](../17-matematica/08-teoria-de-juegos.md#4--nim).

```java
static long[] nimMove(long[] piles) {                    // {índice, nuevo tamaño} o {−1, −1}
    long s = 0;
    for (long p : piles) s ^= p;
    if (s == 0) return new long[]{-1, -1};
    for (int i = 0; i < piles.length; i++)
        if ((piles[i] ^ s) < piles[i]) return new long[]{i, piles[i] ^ s};
    return new long[]{-1, -1};
}
```

### `17/08` — Sprague-Grundy [B]

De [`17/08` — Teoría de juegos, §5](../17-matematica/08-teoria-de-juegos.md#5--sprague-grundy).

```java
static int[] grundySubtraction(int maxN, int[] S) {
    int[] g = new int[maxN + 1];
    boolean[] seen = new boolean[S.length + 2];
    for (int n = 1; n <= maxN; n++) {
        java.util.Arrays.fill(seen, false);
        for (int s : S) if (s <= n && g[n - s] <= S.length) seen[g[n - s]] = true;
        int m = 0;
        while (seen[m]) m++;
        g[n] = m;
    }
    return g;
}
```

---

## 🧱 Bloque 18 — Geometría

### `18/01` — Vectores, punto y cruz [A]

De [`18/01` — Vectores, productos y orientación, §3](../18-geometria/01-vectores-y-orientacion.md#3--vectores-punto-y-cruz).

```java
record Pt(long x, long y) {
    Pt minus(Pt o) { return new Pt(x - o.x, y - o.y); }
    long dot(Pt o) { return x * o.x + y * o.y; }
    long cross(Pt o) { return x * o.y - y * o.x; }
    long norm2() { return x * x + y * y; }                 // |a|², sin raíz
}
```

### `18/01` — Orientación [A]

De [`18/01` — Vectores, productos y orientación, §4](../18-geometria/01-vectores-y-orientacion.md#4--orientación).

```java
static int orient(Pt a, Pt b, Pt c) {
    return Long.signum(b.minus(a).cross(c.minus(a)));
}

static boolean inTriangle(Pt a, Pt b, Pt c, Pt p) {
    int s1 = orient(a, b, p), s2 = orient(b, c, p), s3 = orient(c, a, p);
    boolean neg = s1 < 0 || s2 < 0 || s3 < 0, pos = s1 > 0 || s2 > 0 || s3 > 0;
    return !(neg && pos);
}
```

### `18/01` — Enteros frente a épsilon [A]

De [`18/01` — Vectores, productos y orientación, §5](../18-geometria/01-vectores-y-orientacion.md#5--enteros-frente-a-épsilon).

```java
static int sgn(double v, double eps) { return v > eps ? 1 : (v < -eps ? -1 : 0); }
```

### `18/02` — Intersección de segmentos [B]

De [`18/02` — Rectas y segmentos, §3](../18-geometria/02-rectas-y-segmentos.md#3--intersección-de-segmentos).

```java
static boolean onSegment(Pt a, Pt b, Pt p) {
    return orient(a, b, p) == 0
        && Math.min(a.x(), b.x()) <= p.x() && p.x() <= Math.max(a.x(), b.x())
        && Math.min(a.y(), b.y()) <= p.y() && p.y() <= Math.max(a.y(), b.y());
}

static boolean segmentsIntersect(Pt a, Pt b, Pt c, Pt d) {
    int o1 = orient(a, b, c), o2 = orient(a, b, d);
    int o3 = orient(c, d, a), o4 = orient(c, d, b);
    if (o1 * o2 < 0 && o3 * o4 < 0) return true;
    return onSegment(a, b, c) || onSegment(a, b, d) || onSegment(c, d, a) || onSegment(c, d, b);
}

static double[] lineIntersection(Pt a, Pt b, Pt c, Pt d) {
    double t = (double) c.minus(a).cross(d.minus(c)) / b.minus(a).cross(d.minus(c));
    return new double[]{a.x() + t * (b.x() - a.x()), a.y() + t * (b.y() - a.y())};
}
```

### `18/02` — Distancias [B]

De [`18/02` — Rectas y segmentos, §4](../18-geometria/02-rectas-y-segmentos.md#4--distancias).

```java
static double distPointSegment(Pt p, Pt a, Pt b) {
    Pt ab = b.minus(a), ap = p.minus(a);
    long len2 = ab.norm2(), proj = ap.dot(ab);
    if (proj <= 0) return Math.sqrt(ap.norm2());
    if (proj >= len2) return Math.sqrt(p.minus(b).norm2());
    return Math.abs((double) ab.cross(ap)) / Math.sqrt(len2);
}

static double distSegments(Pt a, Pt b, Pt c, Pt d) {
    if (segmentsIntersect(a, b, c, d)) return 0;
    return Math.min(Math.min(distPointSegment(a, c, d), distPointSegment(b, c, d)),
                    Math.min(distPointSegment(c, a, b), distPointSegment(d, a, b)));
}
```

### `18/03` — Fórmula del cordón [B]

De [`18/03` — Polígonos, §3](../18-geometria/03-poligonos.md#3--fórmula-del-cordón).

```java
// Doble del área con signo. El desbordamiento de long en Java da la vuelta de forma definida:
// si el total cabe en 64 bits, sale bien aunque una suma parcial no quepa.
static long area2(Pt[] p) {
    long s = 0;
    for (int i = 0; i < p.length; i++) s += p[i].cross(p[(i + 1) % p.length]);
    return s;
}
```

### `18/03` — Punto en polígono [B]

De [`18/03` — Polígonos, §4](../18-geometria/03-poligonos.md#4--punto-en-polígono).

```java
static int pointInPolygon(Pt[] poly, Pt p) {
    boolean inside = false;
    for (int i = 0; i < poly.length; i++) {
        Pt a = poly[i], b = poly[(i + 1) % poly.length];
        if (onSegment(a, b, p)) return 0;
        if ((a.y() > p.y()) != (b.y() > p.y())) {
            long o = b.minus(a).cross(p.minus(a));
            if ((o > 0) == (b.y() > a.y())) inside = !inside;
        }
    }
    return inside ? 1 : -1;
}
```

### `18/03` — Pick [B]

De [`18/03` — Polígonos, §5](../18-geometria/03-poligonos.md#5--pick).

```java
static long[] latticePoints(Pt[] p) {
    long b = 0;
    for (int i = 0; i < p.length; i++) {
        Pt d = p[(i + 1) % p.length].minus(p[i]);
        b += java.math.BigInteger.valueOf(Math.abs(d.x())).gcd(java.math.BigInteger.valueOf(Math.abs(d.y()))).longValue();
    }
    long a2 = Math.abs(area2(p));
    return new long[]{b, (a2 - b + 2) / 2};
}
```

### `18/03` — Rectángulos: lo que sí te pueden preguntar [B]

De [`18/03` — Polígonos, §6](../18-geometria/03-poligonos.md#6--rectángulos-lo-que-sí-te-pueden-preguntar).

```java
static long overlapArea(long[] r, long[] s) {
    long w = Math.min(r[2], s[2]) - Math.max(r[0], s[0]);
    long h = Math.min(r[3], s[3]) - Math.max(r[1], s[1]);
    return (w > 0 && h > 0) ? w * h : 0;
}
```

### `18/04` — Cadena monótona de Andrew [B]

De [`18/04` — Envolvente convexa, §3](../18-geometria/04-envolvente-convexa.md#3--cadena-monótona-de-andrew).

```java
static Pt[] convexHull(Pt[] input, boolean keepCollinear) {
    Pt[] pts = java.util.Arrays.stream(input).distinct()
        .sorted(java.util.Comparator.comparingLong(Pt::x).thenComparingLong(Pt::y))
        .toArray(Pt[]::new);
    int n = pts.length;
    if (n <= 2) return pts;
    Pt[] h = new Pt[2 * n];
    int k = 0;
    for (int i = 0; i < n; i++) {
        while (k >= 2 && bad(h[k - 2], h[k - 1], pts[i], keepCollinear)) k--;
        h[k++] = pts[i];
    }
    for (int i = n - 2, low = k + 1; i >= 0; i--) {
        while (k >= low && bad(h[k - 2], h[k - 1], pts[i], keepCollinear)) k--;
        h[k++] = pts[i];
    }
    return java.util.Arrays.copyOf(h, k - 1);
}

static boolean bad(Pt a, Pt b, Pt c, boolean keepCollinear) {
    int o = orient(a, b, c);
    return keepCollinear ? o < 0 : o <= 0;
}
```

### `18/05` — Par más cercano [B]

De [`18/05` — Barrido geométrico, §3](../18-geometria/05-barrido-geometrico.md#3--par-más-cercano).

```java
static long closestPair(Pt[] input) {
    Pt[] pts = input.clone();
    java.util.Arrays.sort(pts, java.util.Comparator.comparingLong(Pt::x));
    java.util.TreeSet<long[]> active = new java.util.TreeSet<>(
        (a, b) -> a[0] != b[0] ? Long.compare(a[0], b[0]) : Long.compare(a[1], b[1]));  // (y, x)
    long best = Long.MAX_VALUE;
    int left = 0;
    for (Pt p : pts) {
        long d = (long) Math.sqrt((double) best) + 1;
        while (p.x() - pts[left].x() > d) {
            active.remove(new long[]{pts[left].y(), pts[left].x()});
            left++;
        }
        for (long[] q : active.tailSet(new long[]{p.y() - d, Long.MIN_VALUE}, true)) {
            if (q[0] > p.y() + d) break;
            long dx = p.x() - q[1], dy = p.y() - q[0];
            best = Math.min(best, dx * dx + dy * dy);
        }
        active.add(new long[]{p.y(), p.x()});
    }
    return best;
}
```

---

## 🧱 Bloque 19 — Aleatorizados y probabilísticos

### `19/01` — Freivalds [B]

De [`19/01` — Las Vegas y Monte Carlo, §6](../19-aleatorizados-y-probabilisticos/01-las-vegas-y-monte-carlo.md#6--freivalds).

```java
static final java.util.Random RNG = new java.util.Random();       // semilla del sistema

static long[] mulVec(long[][] m, long[] v) {
    int n = m.length;
    long[] res = new long[n];
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++) res[i] += m[i][k] * v[k];
    return res;
}

static boolean freivalds(long[][] a, long[][] b, long[][] c, int rounds) {
    int n = a.length;
    for (int t = 0; t < rounds; t++) {
        long[] r = new long[n];
        for (int i = 0; i < n; i++) r[i] = RNG.nextInt(2);
        if (!java.util.Arrays.equals(mulVec(a, mulVec(b, r)), mulVec(c, r))) return false;
    }
    return true;
}
```

### `19/02` — *Hashing* universal [B]

De [`19/02` — *Hashing* universal y análisis esperado, §3](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md#3--hashing-universal).

```java
static final class UniversalHash {
    static final long P = 2147483647L;                    // 2³¹ − 1, primo
    final long a, b, m;
    UniversalHash(long buckets) {
        java.util.SplittableRandom rng = new java.util.SplittableRandom();
        m = buckets;
        a = 1 + rng.nextLong(P - 1);
        b = rng.nextLong(P);
    }
    long apply(long x) { return ((a * x + b) % P) % m; }  // x en [0, P): a·x < 2⁶²
}
```

### `19/03` — Bloom [B]

De [`19/03` — Estructuras probabilísticas, §3](../19-aleatorizados-y-probabilisticos/03-estructuras-probabilisticas.md#3--bloom).

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

### `19/03` — Count-Min [B]

De [`19/03` — Estructuras probabilísticas, §4](../19-aleatorizados-y-probabilisticos/03-estructuras-probabilisticas.md#4--count-min).

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

### `19/04` — Fisher-Yates [A]

De [`19/04` — Muestreo y cadenas de Markov, §3](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#3--fisher-yates).

```java
static void fisherYates(int[] a, java.util.Random rng) {
    for (int i = a.length - 1; i > 0; i--) {
        int j = rng.nextInt(i + 1);                         // j en [0, i]
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }
}
// Collections.shuffle(list) hace lo mismo sobre una List.
```

### `19/04` — *Reservoir* [B]

De [`19/04` — Muestreo y cadenas de Markov, §4](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#4--reservoir).

```java
static long[] reservoir(java.util.PrimitiveIterator.OfLong stream, int k, java.util.Random rng) {
    long[] sample = new long[k];
    long seen = 0;
    while (stream.hasNext()) {
        long x = stream.nextLong();
        seen++;
        if (seen <= k) { sample[(int) (seen - 1)] = x; continue; }
        long j = rng.nextLong(seen);                         // Java 17+: uniforme en [0, seen)
        if (j < k) sample[(int) j] = x;
    }
    return seen < k ? java.util.Arrays.copyOf(sample, (int) seen) : sample;
}
```

---

## 🧱 Bloque 20 — Ad hoc, constructivos e interactivos

### `20/01` — Invariantes y paridad [A]

De [`20/01` — Ad hoc y simulación, §3](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#3--invariantes-y-paridad).

```java
// Paridad de una permutación de 0..n−1: 0 si par, 1 si impar. n − (número de ciclos) intercambios.
static int permutationParity(int[] p) {
    boolean[] seen = new boolean[p.length];
    int cycles = 0;
    for (int i = 0; i < p.length; i++) {
        if (seen[i]) continue;
        cycles++;
        for (int j = i; !seen[j]; j = p[j]) seen[j] = true;
    }
    return (p.length - cycles) % 2;
}
```

### `20/01` — Simulación [A]

De [`20/01` — Ad hoc y simulación, §4](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#4--simulación).

```java
// Estado tras k aplicaciones de f desde x0, saltando el ciclo. Los estados se guardan en un mapa.
static long iterate(long x0, long k, java.util.function.LongUnaryOperator f) {
    java.util.Map<Long, Long> firstSeen = new java.util.HashMap<>();
    long x = x0;
    for (long step = 0; step < k; step++) {
        Long prev = firstSeen.putIfAbsent(x, step);
        if (prev != null) {                                   // el estado x ya salió en el paso prev
            long cycle = step - prev;
            long remaining = (k - step) % cycle;
            for (long r = 0; r < remaining; r++) x = f.applyAsLong(x);
            return x;
        }
        x = f.applyAsLong(x);
    }
    return x;
}
```

### `20/02` — Constructivos [B]

De [`20/02` — Constructivos, §3](../20-ad-hoc-constructivos-e-interactivos/02-constructivos.md#3--constructivos).

```java
static int[][][] roundRobin(int n) {
    int m = n - 1;
    int[][][] rounds = new int[m][n / 2][];
    for (int r = 0; r < m; r++) {
        rounds[r][0] = new int[]{r, n - 1};
        for (int k = 1; k < n / 2; k++)
            rounds[r][k] = new int[]{(r + k) % m, (r - k + m) % m};
    }
    return rounds;
}

static boolean checkRoundRobin(int n, int[][][] rounds) {
    int[][] met = new int[n][n];
    for (int[][] round : rounds) {
        boolean[] busy = new boolean[n];
        for (int[] g : round) {
            int a = g[0], b = g[1];
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

```java
static final java.io.BufferedReader IN =
    new java.io.BufferedReader(new java.io.InputStreamReader(System.in));
static final java.io.PrintWriter OUT = new java.io.PrintWriter(System.out);

static String ask(long x) throws java.io.IOException {
    OUT.println("? " + x);
    OUT.flush();                                           // sin esto, el juez no ve la pregunta
    String reply = IN.readLine().trim();
    if (reply.equals("-1")) System.exit(0);
    return reply;
}

static void answer(long x) { OUT.println("! " + x); OUT.flush(); }
```

### `20/03` — Binaria interactiva [B]

De [`20/03` — Interactivos, §4](../20-ad-hoc-constructivos-e-interactivos/03-interactivos.md#4--binaria-interactiva).

```java
static long findSecret(long n) throws java.io.IOException {
    long lo = 1, hi = n;
    while (lo < hi) {
        long mid = lo + (hi - lo) / 2;
        if (ask(mid).equals("YES")) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}
```

---

## 🧱 Bloque 22 — Teoría de la computación (opcional)

### `22/02` — Autómatas de pila [B]

De [`22/02` — Autómatas de pila, §3](../22-teoria-de-la-computacion/02-automatas-de-pila.md#3--autómatas-de-pila).

```java
import java.util.ArrayDeque;

// DPDA de aⁿbⁿ (n ≥ 1) con la pila explícita. Θ(n).
static boolean anbn(String w) {
    ArrayDeque<Character> stack = new ArrayDeque<>();
    int i = 0;
    while (i < w.length() && w.charAt(i) == 'a') { stack.push('A'); i++; }      // estado p
    if (stack.isEmpty()) return false;
    while (i < w.length() && w.charAt(i) == 'b' && !stack.isEmpty()) { stack.pop(); i++; }   // estado q
    return i == w.length() && stack.isEmpty();                                 // fondo de pila y sin entrada
}
```

### `22/02` — CYK [B]

De [`22/02` — Autómatas de pila, §5](../22-teoria-de-la-computacion/02-automatas-de-pila.md#5--cyk).

```java
// CYK. unit[r] = {A, símbolo}; bin[r] = {A, B, C}. Variables 0..63, la inicial es la 0.
static boolean cyk(int[][] unit, int[][] bin, String w) {
    int n = w.length();
    if (n == 0) return false;
    long[][] t = new long[n][n];
    for (int i = 0; i < n; i++)
        for (int[] u : unit) if (u[1] == w.charAt(i)) t[i][i] |= 1L << u[0];
    for (int len = 2; len <= n; len++)
        for (int i = 0; i + len - 1 < n; i++) {
            int j = i + len - 1;
            for (int k = i; k < j; k++)
                for (int[] r : bin)
                    if ((t[i][k] >> r[1] & 1) != 0 && (t[k + 1][j] >> r[2] & 1) != 0) t[i][j] |= 1L << r[0];
        }
    return (t[0][n - 1] & 1) != 0;
}
```

### `22/03` — La máquina de Turing y su simulación [A]

De [`22/03` — Máquinas de Turing y decidibilidad, §3](../22-teoria-de-la-computacion/03-maquinas-de-turing-y-decidibilidad.md#3--la-máquina-de-turing-y-su-simulación).

```java
import java.util.Map;

// Misma simulación. delta: clave = estado * 256 + símbolo; valor = {escribe, mueve (−1 o +1), siguiente}.
static long steps;

static int runTm(Map<Integer, int[]> delta, int halt, StringBuilder tape, char blank, long limit) {
    StringBuilder left = new StringBuilder(), right = new StringBuilder(tape).reverse();
    char cur = blank;
    if (right.length() > 0) { cur = right.charAt(right.length() - 1); right.setLength(right.length() - 1); }
    int q = 0;
    for (steps = 0; q != halt; steps++) {
        if (steps == limit) return -1;
        int[] r = delta.get(q * 256 + cur);
        if (r == null) break;                                    // sin transición: se detiene
        StringBuilder from = r[1] > 0 ? right : left, to = r[1] > 0 ? left : right;
        to.append((char) r[0]);
        if (from.length() == 0) cur = blank;
        else { cur = from.charAt(from.length() - 1); from.setLength(from.length() - 1); }
        q = r[2];
    }
    tape.setLength(0);
    tape.append(left).append(cur).append(right.reverse());
    return q;
}
```

### `22/04` — P y NP por certificados [A]

De [`22/04` — P, NP y reducciones, §3](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#3--p-y-np-por-certificados).

```java
static boolean verifyCover(int n, int[][] edges, int[] cover, int k) {
    if (cover.length > k) return false;
    boolean[] in = new boolean[n];
    for (int v : cover) in[v] = true;
    for (int[] e : edges) if (!in[e[0]] && !in[e[1]]) return false;
    return true;
}
```

### `22/04` — Reducciones polinomiales [B]

De [`22/04` — P, NP y reducciones, §4](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#4--reducciones-polinomiales).

```java
static boolean[][] complementGraph(int n, int[][] edges) {
    boolean[][] adj = new boolean[n][n];
    for (int u = 0; u < n; u++) for (int v = 0; v < n; v++) adj[u][v] = u != v;
    for (int[] e : edges) adj[e[0]][e[1]] = adj[e[1]][e[0]] = false;
    return adj;
}
```

### `22/05` — La cadena de reducciones clásicas [B]

De [`22/05` — NP-completitud, §4](../22-teoria-de-la-computacion/05-np-completitud.md#4--la-cadena-de-reducciones-clásicas).

```java
import java.util.ArrayList;
import java.util.List;

static List<int[]> satToIndependentSet(int[][] clauses) {
    int m = clauses.length;
    List<int[]> edges = new ArrayList<>();
    for (int i = 0; i < m; i++) {
        edges.add(new int[]{3 * i, 3 * i + 1});
        edges.add(new int[]{3 * i + 1, 3 * i + 2});
        edges.add(new int[]{3 * i, 3 * i + 2});
    }
    for (int i = 0; i < m; i++)
        for (int k = i + 1; k < m; k++)
            for (int j = 0; j < 3; j++)
                for (int l = 0; l < 3; l++)
                    if (clauses[i][j] == -clauses[k][l]) edges.add(new int[]{3 * i + j, 3 * k + l});
    return edges;
}
```

### `22/05` — Qué hacer con un NP-difícil [A]

De [`22/05` — NP-completitud, §6](../22-teoria-de-la-computacion/05-np-completitud.md#6--qué-hacer-con-un-np-difícil).

```java
static boolean hamiltonianCycle(int[] adj) {
    int n = adj.length;
    if (n < 3) return false;
    int[] reach = new int[1 << n];
    reach[1] = 1;
    for (int mask = 3; mask < (1 << n); mask += 2)
        for (int w = 1; w < n; w++)
            if ((mask >> w & 1) != 0 && (reach[mask ^ (1 << w)] & adj[w]) != 0)
                reach[mask] |= 1 << w;
    return (reach[(1 << n) - 1] & adj[0]) != 0;
}
```

### `22/06` — Análisis léxico [B]

De [`22/06` — Análisis léxico y gramáticas simples, §3](../22-teoria-de-la-computacion/06-analisis-lexico-y-gramaticas-simples.md#3--análisis-léxico).

```java
import java.util.ArrayList;
import java.util.List;

enum Kind { NUM, IDENT, OP, END }
record Token(Kind kind, String text, int pos) { }

static List<Token> tokenize(String s) {
    List<Token> out = new ArrayList<>();
    int i = 0;
    while (i < s.length()) {
        char c = s.charAt(i);
        if (Character.isWhitespace(c)) { i++; continue; }
        int start = i;
        if (c >= '0' && c <= '9') {
            while (i < s.length() && s.charAt(i) >= '0' && s.charAt(i) <= '9') i++;
            out.add(new Token(Kind.NUM, s.substring(start, i), start));
        } else if (Character.isLetter(c) || c == '_') {
            while (i < s.length() && (Character.isLetterOrDigit(s.charAt(i)) || s.charAt(i) == '_')) i++;
            out.add(new Token(Kind.IDENT, s.substring(start, i), start));
        } else if ("+-*/^()=".indexOf(c) >= 0) {
            i++;
            out.add(new Token(Kind.OP, String.valueOf(c), start));
        } else {
            throw new IllegalArgumentException("carácter inesperado en la posición " + start);
        }
    }
    out.add(new Token(Kind.END, "", s.length()));
    return out;
}
```

### `22/06` — Descenso recursivo [B]

De [`22/06` — Análisis léxico y gramáticas simples, §5](../22-teoria-de-la-computacion/06-analisis-lexico-y-gramaticas-simples.md#5--descenso-recursivo).

```java
import java.util.List;

static final class Parser {
    private final List<Token> toks;
    private int p = 0;
    Parser(List<Token> toks) { this.toks = toks; }

    private boolean accept(String op) {
        Token t = toks.get(p);
        if (t.kind() == Kind.OP && t.text().equals(op)) { p++; return true; }
        return false;
    }
    private IllegalArgumentException fail(String what) {
        return new IllegalArgumentException(what + " en la posición " + toks.get(p).pos());
    }
    long parse() {
        long v = expr();
        if (toks.get(p).kind() != Kind.END) throw fail("sobra entrada");
        return v;
    }
    private long expr() {
        long v = term();
        while (true) {
            if (accept("+")) v += term();
            else if (accept("-")) v -= term();
            else return v;
        }
    }
    private long term() {
        long v = unary();
        while (true) {
            if (accept("*")) v *= unary();
            else if (accept("/")) {
                long d = unary();
                if (d == 0) throw fail("división por cero");
                v /= d;
            } else return v;
        }
    }
    private long unary() { return accept("-") ? -unary() : power(); }
    private long power() {
        long base = atom();
        if (!accept("^")) return base;
        long e = unary();
        if (e < 0) throw fail("exponente negativo");
        long r = 1;
        for (; e > 0; e >>= 1) {
            if ((e & 1) != 0) r *= base;
            if (e > 1) base *= base;
        }
        return r;
    }
    private long atom() {
        Token t = toks.get(p);
        if (t.kind() == Kind.NUM) { p++; return Long.parseLong(t.text()); }
        if (accept("(")) {
            long v = expr();
            if (!accept(")")) throw fail("se esperaba ')'");
            return v;
        }
        throw fail("se esperaba un número o '('");
    }
}
```
