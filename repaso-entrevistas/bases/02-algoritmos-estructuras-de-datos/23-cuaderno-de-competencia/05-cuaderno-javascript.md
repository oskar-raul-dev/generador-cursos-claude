# 05 — Cuaderno de JavaScript

> **Opcional.** Las plantillas de nivel A del corpus en JavaScript, sin explicación y listas para copiar.
> **Son las únicas plantillas completas en JavaScript del corpus**: los capítulos usan C++, Java y Python, y
> este cuaderno las traduce teniendo en cuenta lo que JavaScript cambia —un solo tipo numérico, exacto
> hasta 2⁵³; `sort()` que ordena como texto; `shift()` que cuesta O(n); sin montículo, deque ni mapa
> ordenado—. Cada una lleva el enlace a la sección del capítulo donde están su invariante, su coste y sus
> trampas. Escritas para Node 20, la versión de HackerRank; las que necesitan el montículo o el deque usan
> los de `08/01` y `06/01` de este mismo cuaderno.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#-bloque-01--oficio-del-competidor) · [02](#-bloque-02--análisis) · [04](#-bloque-04--secuencias) · [05](#-bloque-05--orden-y-búsqueda) · [06](#-bloque-06--lineales-y-hashing) · [07](#-bloque-07--árboles) · [08](#-bloque-08--heaps-y-union-find) · [09](#-bloque-09--consultas-sobre-rangos) · [10](#-bloque-10--búsqueda-completa-y-divide-y-vencerás) · [11](#-bloque-11--voraces) · [12](#-bloque-12--dp-clásica) · [13](#-bloque-13--dp-avanzada) · [14](#-bloque-14--grafos-recorridos) · [15](#-bloque-15--grafos-con-pesos-y-flujos) · [16](#-bloque-16--cadenas) · [17](#-bloque-17--matemática) · [18](#-bloque-18--geometría) · [19](#-bloque-19--aleatorizados-y-probabilísticos) · [20](#-bloque-20--ad-hoc-constructivos-e-interactivos) · [22](#-bloque-22--teoría-de-la-computación-opcional)

---

## 🧱 Bloque 01 — Oficio del competidor

### `01/03` — La plantilla

De [`01/03` — Entrada, salida y la plantilla en C++, Java y Python, §6](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md#6--la-plantilla).

```javascript
"use strict";
// Toda la entrada de una vez (descriptor 0 = stdin) y partida por blancos.
const data = require("fs").readFileSync(0, "utf8").split(/\s+/).filter(Boolean);
let pos = 0;
const next = () => data[pos++];

const n = Number(next());
const a = Array.from({ length: n }, () => Number(next()));

let total = 0; // aquí va la solución; exacto solo hasta 2⁵³: si puede pasar, BigInt
for (const x of a) total += x;

// Con muchas líneas de salida: acumularlas en un arreglo y un solo write con join("\n").
process.stdout.write(String(total) + "\n");
```

### `01/05` — El *stress test*

De [`01/05` — Probar sin IDE: casos borde, depuración y *stress test*, §4](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md#4--el-stress-test).

```javascript
"use strict";
// Compara ./sol contra ./brute con entradas de ./gen hasta la primera diferencia.
const { execFileSync } = require("child_process");
// execFileSync lanza una excepción si el programa termina con error: un RE detiene el arnés.
const run = (cmd, args, input) => execFileSync(cmd, args, { input, encoding: "utf8" });

for (let seed = 1; seed <= 10000; seed++) {
  const data = run("./gen", [String(seed)], "");
  const mine = run("./sol", [], data).split(/\s+/).filter(Boolean); // por tokens, como el juez
  const oracle = run("./brute", [], data).split(/\s+/).filter(Boolean);
  if (mine.join(" ") !== oracle.join(" ")) {
    console.log(`Diferencia con la semilla ${seed}:\n${data}`);
    console.log("sol:  ", mine.join(" "));
    console.log("brute:", oracle.join(" "));
    process.exit(1);
  }
}
console.log("10 000 casos sin diferencias");
```

```javascript
"use strict";
// Generador de «un arreglo de enteros»: node gen.js <semilla>.
// Math.random no admite semilla: mulberry32, un generador de 32 bits pequeño y reproducible.
function mulberry32(seed) {
  return function () {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296; // en [0, 1)
  };
}
const rng = mulberry32(Number(process.argv[2])); // la semilla la pasa el arnés
const between = (lo, hi) => lo + Math.floor(rng() * (hi - lo + 1)); // [lo, hi], los dos incluidos
const n = between(1, 8);
const values = Array.from({ length: n }, () => between(-5, 5));
process.stdout.write(`${n}\n${values.join(" ")}\n`);
```

---

## 🧱 Bloque 02 — Análisis

### `02/03` — El método agregado

De [`02/03` — Análisis amortizado, §3](../02-analisis/03-analisis-amortizado.md#3--el-método-agregado).

```javascript
// Arreglo dinámico: push O(1) amortizado, get O(1) en el caso peor.
// (Array.push ya es esto; aquí está a mano, sobre un Float64Array de tamaño fijo, para ver la duplicación.)
class NumberArrayList {
  constructor() {
    this.data = new Float64Array(1);
    this.size = 0;
  }
  push(x) {
    if (this.size === this.data.length) {
      const bigger = new Float64Array(2 * this.data.length); // duplica: copia size elementos
      bigger.set(this.data);
      this.data = bigger;
    }
    this.data[this.size++] = x;
  }
  get(i) {
    if (i < 0 || i >= this.size) throw new RangeError(`índice fuera de rango: ${i}`);
    return this.data[i];
  }
}
```

### `02/04` — Invariante de bucle

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §3](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#3--invariante-de-bucle).

```javascript
// Primer índice i en [0, n] con a[i] >= x (lower bound). Pre: a ordenado de forma no decreciente.
function lowerBound(a, x) {
  let lo = 0, hi = a.length;
  // Invariante: a[0..lo) < x  y  a[hi..n) >= x.  Cota: hi - lo, que baja en cada vuelta.
  while (lo < hi) {
    const mid = (lo + hi) >>> 1; // índices < 2³¹: la suma no pierde precisión y >>> trunca
    if (a[mid] < x) lo = mid + 1; // a[0..mid] < x: el invariante se mantiene
    else hi = mid; // a[mid..n) >= x: el invariante se mantiene
  }
  return lo; // lo === hi: la frontera exacta
}
```

### `02/04` — Argumento de intercambio

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §5](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#5--argumento-de-intercambio).

```javascript
// Máximo número de intervalos [s, f) disjuntos. Θ(n log n) por la ordenación.
function maxDisjoint(intervals) {
  const byEnd = [...intervals].sort((p, q) => p[1] - q[1]); // sin comparador, ordenaría como texto
  let count = 0, lastEnd = -Infinity; // final del último elegido
  for (const [s, f] of byEnd) {
    if (s >= lastEnd) { // semiabierto: empezar justo al terminar vale
      count++;
      lastEnd = f;
    }
  }
  return count;
}
```

### `02/06` — TDA, contrato e invariante de representación

De [`02/06` — Tipos abstractos de datos, §3](../02-analisis/06-tipos-abstractos-de-datos.md#3--tda-contrato-e-invariante-de-representación).

```javascript
// El contrato de una cola: enqueue, dequeue, peek, isEmpty, size. JavaScript no tiene interfaces:
// el contrato se documenta y se comprueba con pruebas. dequeue y peek lanzan si está vacía.

// Arreglo circular. Invariante: 0 <= size <= data.length, 0 <= head < data.length;
// los elementos son data[(head + i) % data.length] para i en [0, size).
class RingBufferQueue {
  constructor() {
    this.data = new Array(4);
    this.head = 0;
    this.length = 0;
  }
  enqueue(x) {
    if (this.length === this.data.length) this.#grow();
    this.data[(this.head + this.length) % this.data.length] = x;
    this.length++;
  }
  dequeue() {
    const x = this.peek();
    this.head = (this.head + 1) % this.data.length;
    this.length--;
    return x;
  }
  peek() {
    if (this.length === 0) throw new Error("cola vacía");
    return this.data[this.head];
  }
  isEmpty() { return this.length === 0; }
  size() { return this.length; }
  #grow() { // copia en orden lógico: la cabeza vuelve a 0
    const bigger = new Array(2 * this.data.length);
    for (let i = 0; i < this.length; i++) bigger[i] = this.data[(this.head + i) % this.data.length];
    this.data = bigger;
    this.head = 0;
  }
}

// Lista enlazada simple. Invariante: length nodos desde head; tail es el último (o null si está vacía).
class LinkedQueue {
  constructor() {
    this.head = this.tail = null;
    this.length = 0;
  }
  enqueue(x) {
    const node = { value: x, next: null };
    if (this.tail === null) this.head = node; else this.tail.next = node;
    this.tail = node;
    this.length++;
  }
  dequeue() {
    const x = this.peek();
    this.head = this.head.next;
    if (this.head === null) this.tail = null; // la cola quedó vacía: tail también
    this.length--;
    return x;
  }
  peek() {
    if (this.length === 0) throw new Error("cola vacía");
    return this.head.value;
  }
  isEmpty() { return this.length === 0; }
  size() { return this.length; }
}
```

---

## 🧱 Bloque 04 — Secuencias

### `04/01` — Prefijos 1D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §3](../04-secuencias/01-prefijos-y-diferencias.md#3--prefijos-1d).

```javascript
// p[k] = a[0] + ... + a[k-1]; la suma de a[l..r] es p[r+1] - p[l]. O(n).
// Exacto mientras las sumas no pasen de 2⁵³; si pueden pasar, BigInt.
function buildPrefix(a) {
  const p = new Array(a.length + 1).fill(0);
  for (let i = 0; i < a.length; i++) p[i + 1] = p[i] + a[i];
  return p;
}

const rangeSum = (p, l, r) => p[r + 1] - p[l]; // l y r incluidos
```

### `04/01` — Diferencias 1D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §4](../04-secuencias/01-prefijos-y-diferencias.md#4--diferencias-1d).

```javascript
// Suma v a [l, r] en O(1); finish() reconstruye el arreglo con prefijos.
class RangeAdd {
  constructor(n) { this.d = new Array(n + 1).fill(0); }
  add(l, r, v) {
    this.d[l] += v;
    this.d[r + 1] -= v;
  }
  finish() {
    const out = [];
    let run = 0;
    for (let i = 0; i + 1 < this.d.length; i++) out.push((run += this.d[i])); // prefijos de las diferencias
    return out;
  }
}
```

### `04/01` — Prefijos y diferencias 2D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §5](../04-secuencias/01-prefijos-y-diferencias.md#5--prefijos-y-diferencias-2d).

```javascript
// s[i][j] = suma de m[0..i-1][0..j-1]; consulta inclusiva de (r1, c1) a (r2, c2).
class Prefix2D {
  constructor(m) {
    const rows = m.length, cols = rows ? m[0].length : 0;
    this.s = Array.from({ length: rows + 1 }, () => new Array(cols + 1).fill(0));
    for (let i = 0; i < rows; i++)
      for (let j = 0; j < cols; j++)
        this.s[i + 1][j + 1] = m[i][j] + this.s[i][j + 1] + this.s[i + 1][j] - this.s[i][j];
  }
  query(r1, c1, r2, c2) {
    const s = this.s;
    return s[r2 + 1][c2 + 1] - s[r1][c2 + 1] - s[r2 + 1][c1] + s[r1][c1];
  }
}
```

### `04/02` — Dos punteros

De [`04/02` — Dos punteros y ventana deslizante, §3](../04-secuencias/02-dos-punteros-y-ventana.md#3--dos-punteros).

```javascript
// Número de pares i < j con a[i] + a[j] <= k. Pre: a ordenado (con comparador numérico). O(n).
function countPairsAtMost(a, k) {
  let count = 0, l = 0, r = a.length - 1;
  while (l < r) {
    if (a[l] + a[r] <= k) {
      count += r - l; // a[l] con todos los de (l, r]
      l++;
    } else r--;
  }
  return count;
}
```

### `04/02` — Ventana variable

De [`04/02` — Dos punteros y ventana deslizante, §4](../04-secuencias/02-dos-punteros-y-ventana.md#4--ventana-variable).

```javascript
// Longitud del subarreglo más largo con suma <= s. Pre: a[i] >= 0. O(n).
function longestAtMost(a, s) {
  let total = 0, best = 0, l = 0;
  for (let r = 0; r < a.length; r++) {
    total += a[r];
    while (total > s) total -= a[l++];
    best = Math.max(best, r - l + 1);
  }
  return best;
}
```

### `04/02` — Ventana fija

De [`04/02` — Dos punteros y ventana deslizante, §5](../04-secuencias/02-dos-punteros-y-ventana.md#5--ventana-fija).

```javascript
// Máxima suma de k elementos consecutivos. Pre: 1 <= k <= n. O(n).
function maxWindowSum(a, k) {
  let total = 0;
  for (let i = 0; i < k; i++) total += a[i];
  let best = total;
  for (let i = k; i < a.length; i++) {
    total += a[i] - a[i - k];
    best = Math.max(best, total);
  }
  return best;
}
```

### `04/03` — Kadane

De [`04/03` — Kadane y subarreglos, §3](../04-secuencias/03-kadane-y-subarreglos.md#3--kadane).

```javascript
// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
function maxSubarraySum(a) {
  let best = a[0], cur = 0;
  for (const x of a) {
    cur = Math.max(x, cur + x);
    best = Math.max(best, cur);
  }
  return best;
}
```

### `04/03` — La variante circular

De [`04/03` — Kadane y subarreglos, §4](../04-secuencias/03-kadane-y-subarreglos.md#4--la-variante-circular).

```javascript
// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
function maxCircularSum(a) {
  let total = 0, curMax = 0, curMin = 0, best = a[0], worst = a[0];
  for (const x of a) {
    total += x;
    curMax = Math.max(x, curMax + x); best = Math.max(best, curMax);
    curMin = Math.min(x, curMin + x); worst = Math.min(worst, curMin);
  }
  return best < 0 ? best : Math.max(best, total - worst); // todos negativos: no se da la vuelta
}
```

### `04/03` — Contar subarreglos con prefijos y *hash*

De [`04/03` — Kadane y subarreglos, §5](../04-secuencias/03-kadane-y-subarreglos.md#5--contar-subarreglos-con-prefijos-y-hash).

```javascript
// Número de subarreglos con suma exactamente k. O(n) esperado.
function countSubarraysWithSum(a, k) {
  const seen = new Map([[0, 1]]); // el prefijo vacío; Map, no un objeto: las claves son números
  let prefix = 0, count = 0;
  for (const x of a) {
    prefix += x;
    count += seen.get(prefix - k) ?? 0;
    seen.set(prefix, (seen.get(prefix) ?? 0) + 1);
  }
  return count;
}
```

### `04/04` — Compresión de coordenadas

De [`04/04` — Compresión de coordenadas y barrido de eventos, §3](../04-secuencias/04-compresion-y-barrido.md#3--compresión-de-coordenadas).

```javascript
// Devuelve [rango de cada valor en [0, k), lista ordenada de distintos]. O(n log n).
function compress(a) {
  const distinct = [...new Set(a)].sort((x, y) => x - y); // sort() sin comparador ordena como texto
  const pos = new Map(distinct.map((v, i) => [v, i]));
  return [a.map((x) => pos.get(x)), distinct];
}
```

### `04/04` — Barrido de eventos

De [`04/04` — Compresión de coordenadas y barrido de eventos, §4](../04-secuencias/04-compresion-y-barrido.md#4--barrido-de-eventos).

```javascript
// Máximo de intervalos [s, e) que se solapan en algún instante. O(n log n).
function maxOverlap(intervals) {
  const events = [];
  for (const [s, e] of intervals) events.push([s, 1], [e, -1]);
  events.sort((p, q) => p[0] - q[0] || p[1] - q[1]); // en empate, -1 antes que 1: cierra primero
  let open = 0, best = 0;
  for (const [, d] of events) best = Math.max(best, (open += d));
  return best;
}
```

### `04/04` — Unión de intervalos

De [`04/04` — Compresión de coordenadas y barrido de eventos, §5](../04-secuencias/04-compresion-y-barrido.md#5--unión-de-intervalos).

```javascript
// Une intervalos [s, e) que se solapan; devuelve los bloques disjuntos ordenados. O(n log n).
function mergeIntervals(v) {
  const out = [];
  for (const [s, e] of [...v].sort((p, q) => p[0] - q[0])) {
    const last = out[out.length - 1];
    if (last && s < last[1]) last[1] = Math.max(last[1], e);
    else out.push([s, e]);
  }
  return out;
}
```

### `04/05` — Recorridos, rotación y espiral

De [`04/05` — Matrices, §3](../04-secuencias/05-matrices.md#3--recorridos-rotación-y-espiral).

```javascript
const DIRS = [[-1, 0], [1, 0], [0, -1], [0, 1]]; // arriba, abajo, izquierda, derecha

// Las casillas vecinas de (r, c) dentro de una rejilla rows × cols.
function neighbors(r, c, rows, cols) {
  const out = [];
  for (const [dr, dc] of DIRS) {
    const nr = r + dr, nc = c + dc;
    if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) out.push([nr, nc]);
  }
  return out;
}

// Gira una matriz n × n 90° en sentido horario, en el sitio.
function rotateClockwise(m) {
  const n = m.length;
  for (let i = 0; i < n; i++)
    for (let j = i + 1; j < n; j++) [m[i][j], m[j][i]] = [m[j][i], m[i][j]]; // trasponer
  for (const row of m) row.reverse(); // invertir cada fila
}

// Recorre la matriz en espiral desde la esquina superior izquierda.
function spiral(m) {
  const out = [];
  let top = 0, bottom = m.length - 1, left = 0, right = m[0].length - 1;
  while (top <= bottom && left <= right) {
    for (let j = left; j <= right; j++) out.push(m[top][j]);
    top++;
    for (let i = top; i <= bottom; i++) out.push(m[i][right]);
    right--;
    if (top <= bottom) {
      for (let j = right; j >= left; j--) out.push(m[bottom][j]);
      bottom--;
    }
    if (left <= right) {
      for (let i = bottom; i >= top; i--) out.push(m[i][left]);
      left++;
    }
  }
  return out;
}
```

### `04/05` — Búsqueda en matriz ordenada

De [`04/05` — Matrices, §4](../04-secuencias/05-matrices.md#4--búsqueda-en-matriz-ordenada).

```javascript
// Busca x en una matriz con filas y columnas crecientes. Devuelve [fila, columna] o null. O(R + C).
function staircaseSearch(m, x) {
  let i = 0, j = m[0].length - 1;
  while (i < m.length && j >= 0) {
    if (m[i][j] === x) return [i, j];
    if (m[i][j] > x) j--; // todo lo de debajo en esta columna es mayor
    else i++; // todo lo de la izquierda en esta fila es menor
  }
  return null;
}
```

---

## 🧱 Bloque 05 — Orden y búsqueda

### `05/01` — Inserción y estabilidad

De [`05/01` — Ordenación por comparación, §3](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#3--inserción-y-estabilidad).

```javascript
// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
function insertionSort(a) {
  for (let j = 1; j < a.length; j++) {
    const key = a[j];
    let i = j;
    while (i > 0 && a[i - 1] > key) { // estricto: los iguales no se adelantan
      a[i] = a[i - 1];
      i--;
    }
    a[i] = key;
  }
}
```

### `05/01` — Ordenación por mezcla

De [`05/01` — Ordenación por comparación, §4](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#4--ordenación-por-mezcla).

```javascript
// Ordenación por mezcla, estable. Devuelve un arreglo nuevo. Θ(n log n).
function mergeSort(a) {
  if (a.length <= 1) return [...a];
  const mid = a.length >> 1;
  const left = mergeSort(a.slice(0, mid)), right = mergeSort(a.slice(mid));
  const out = [];
  let i = 0, j = 0;
  while (i < left.length && j < right.length) {
    if (right[j] < left[i]) out.push(right[j++]);
    else out.push(left[i++]); // empate: izquierda, estable
  }
  while (i < left.length) out.push(left[i++]);
  while (j < right.length) out.push(right[j++]);
  return out;
}
```

### `05/01` — *Quicksort*

De [`05/01` — Ordenación por comparación, §5](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#5--quicksort).

```javascript
// Quicksort de a[lo..hi] con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
function quickSort(a, lo = 0, hi = a.length - 1) {
  if (lo >= hi) return;
  const r = lo + Math.floor(Math.random() * (hi - lo + 1));
  [a[lo], a[r]] = [a[r], a[lo]]; // pivote aleatorio en a[lo]
  const p = a[lo];
  let i = lo - 1, j = hi + 1;
  for (;;) {
    do i++; while (a[i] < p);
    do j--; while (a[j] > p);
    if (i >= j) break;
    [a[i], a[j]] = [a[j], a[i]];
  }
  quickSort(a, lo, j);
  quickSort(a, j + 1, hi);
}
```

### `05/03` — Contar inversiones con la mezcla

De [`05/03` — Inversiones, selección y mediana, §3](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#3--contar-inversiones-con-la-mezcla).

```javascript
// Devuelve [arreglo ordenado, número de inversiones]. Θ(n log n).
function countInversions(a) {
  if (a.length <= 1) return [[...a], 0];
  const mid = a.length >> 1;
  const [left, x] = countInversions(a.slice(0, mid));
  const [right, y] = countInversions(a.slice(mid));
  const out = [];
  let i = 0, j = 0, inv = x + y; // con n hasta ~1,3·10⁸ cabe exacto en un número (< 2⁵³)
  while (i < left.length && j < right.length) {
    if (right[j] < left[i]) {
      inv += left.length - i; // quedan left.length − i mayores
      out.push(right[j++]);
    } else out.push(left[i++]);
  }
  while (i < left.length) out.push(left[i++]);
  while (j < right.length) out.push(right[j++]);
  return [out, inv];
}
```

### `05/03` — *Quickselect*

De [`05/03` — Inversiones, selección y mediana, §4](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#4--quickselect).

```javascript
// Valor que ocuparía la posición k (desde 0) si a estuviera ordenado. Reordena a. O(n) esperado.
function quickSelect(a, k) {
  let lo = 0, hi = a.length - 1;
  while (lo < hi) {
    const r = lo + Math.floor(Math.random() * (hi - lo + 1));
    [a[lo], a[r]] = [a[r], a[lo]]; // pivote aleatorio en a[lo]
    const p = a[lo];
    let i = lo - 1, j = hi + 1;
    for (;;) {
      do i++; while (a[i] < p);
      do j--; while (a[j] > p);
      if (i >= j) break;
      [a[i], a[j]] = [a[j], a[i]];
    }
    if (k <= j) hi = j;
    else lo = j + 1;
  }
  return a[k];
}
```

### `05/04` — *Lower* y *upper bound*

De [`05/04` — Búsqueda binaria, §3](../05-orden-y-busqueda/04-busqueda-binaria.md#3--lower-y-upper-bound).

```javascript
// Primer índice en [0, n] con a[i] >= x (lower) o con a[i] > x (upper). JavaScript no las trae.
function lowerBound(a, x) {
  let lo = 0, hi = a.length;
  while (lo < hi) {
    const mid = (lo + hi) >>> 1;
    if (a[mid] < x) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}

function upperBound(a, x) {
  let lo = 0, hi = a.length;
  while (lo < hi) {
    const mid = (lo + hi) >>> 1;
    if (a[mid] <= x) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}
```

### `05/04` — Binaria sobre la respuesta

De [`05/04` — Búsqueda binaria, §4](../05-orden-y-busqueda/04-busqueda-binaria.md#4--binaria-sobre-la-respuesta).

```javascript
// Primer v en [lo, hi) con p(v) cierto, o hi si no hay. Pre: p monótono (falso…cierto).
// Con números exactos hasta 2⁵³; para rangos mayores, la misma función con BigInt.
function firstTrue(lo, hi, p) {
  while (lo < hi) {
    const mid = lo + Math.floor((hi - lo) / 2);
    if (p(mid)) hi = mid;
    else lo = mid + 1;
  }
  return lo;
}
```

### `05/04` — Binaria en reales

De [`05/04` — Búsqueda binaria, §5](../05-orden-y-busqueda/04-busqueda-binaria.md#5--binaria-en-reales).

```javascript
// Frontera de p (falso…cierto) en [lo, hi], con 100 vueltas fijas.
function boundaryReal(lo, hi, p) {
  for (let it = 0; it < 100; it++) {
    const mid = lo + (hi - lo) / 2;
    if (p(mid)) hi = mid;
    else lo = mid;
  }
  return hi;
}
```

---

## 🧱 Bloque 06 — Lineales y hashing

### `06/01` — Pila, cola y deque

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §3](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#3--pila-cola-y-deque).

```javascript
// Pila: un arreglo con push, a[a.length - 1] y pop(), todos O(1).
// Cola y deque: shift() y unshift() cuestan O(n). Un deque sobre un arreglo circular, O(1) amortizado:
class Deque {
  constructor() {
    this.buf = new Array(4);
    this.head = 0;
    this.length = 0;
  }
  #grow() {
    const bigger = new Array(2 * this.buf.length);
    for (let i = 0; i < this.length; i++) bigger[i] = this.buf[(this.head + i) % this.buf.length];
    this.buf = bigger;
    this.head = 0;
  }
  pushBack(x) {
    if (this.length === this.buf.length) this.#grow();
    this.buf[(this.head + this.length) % this.buf.length] = x;
    this.length++;
  }
  pushFront(x) {
    if (this.length === this.buf.length) this.#grow();
    this.head = (this.head - 1 + this.buf.length) % this.buf.length;
    this.buf[this.head] = x;
    this.length++;
  }
  popFront() { // pre: length > 0
    const x = this.buf[this.head];
    this.buf[this.head] = undefined; // suelta la referencia
    this.head = (this.head + 1) % this.buf.length;
    this.length--;
    return x;
  }
  popBack() { // pre: length > 0
    this.length--;
    const i = (this.head + this.length) % this.buf.length;
    const x = this.buf[i];
    this.buf[i] = undefined;
    return x;
  }
  front() { return this.buf[this.head]; }
  back() { return this.buf[(this.head + this.length - 1) % this.buf.length]; }
}
```

### `06/01` — Pila monótona

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §4](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#4--pila-monótona).

```javascript
// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
function nextGreater(a) {
  const ans = new Array(a.length).fill(-1), st = []; // st: índices con valores no crecientes
  for (let i = 0; i < a.length; i++) {
    while (st.length && a[st[st.length - 1]] < a[i]) ans[st.pop()] = i;
    st.push(i);
  }
  return ans;
}
```

### `06/01` — Cola monótona

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §5](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#5--cola-monótona).

```javascript
// mins[i] = mínimo de a[i..i+k-1]. Θ(n). Solo se añade por detrás: un arreglo con un índice de
// cabeza basta (avanzar head es el popleft, sin el O(n) de shift()).
function windowMin(a, k) {
  const dq = [], mins = []; // dq: índices con valores crecientes, desde head
  let head = 0;
  for (let i = 0; i < a.length; i++) {
    while (dq.length > head && a[dq[dq.length - 1]] >= a[i]) dq.pop();
    dq.push(i);
    if (dq[head] <= i - k) head++;
    if (i >= k - 1) mins.push(a[dq[head]]);
  }
  return mins;
}
```

### `06/02` — Inversión, punto medio y mezcla

De [`06/02` — Listas enlazadas, §3](../06-lineales-y-hashing/02-listas-enlazadas.md#3--inversión-punto-medio-y-mezcla).

```javascript
// Nodo: { val, next }.
function reverse(head) {
  let prev = null;
  while (head) [head.next, prev, head] = [prev, head, head.next]; // el lado derecho se evalúa entero antes
  return prev;
}

function middle(head) {
  let slow = head, fast = head;
  while (fast && fast.next) {
    slow = slow.next;
    fast = fast.next.next;
  }
  return slow;
}

function merge(a, b) {
  const dummy = { val: 0, next: null };
  let tail = dummy;
  while (a && b) {
    if (b.val < a.val) { tail.next = b; b = b.next; }
    else { tail.next = a; a = a.next; }
    tail = tail.next;
  }
  tail.next = a || b;
  return dummy.next;
}
```

### `06/02` — Floyd: detectar el ciclo y su inicio

De [`06/02` — Listas enlazadas, §4](../06-lineales-y-hashing/02-listas-enlazadas.md#4--floyd-detectar-el-ciclo-y-su-inicio).

```javascript
// Inicio del ciclo, o null si la lista termina. O(n) tiempo, O(1) memoria.
function cycleStart(head) {
  let slow = head, fast = head;
  while (fast && fast.next) {
    slow = slow.next;
    fast = fast.next.next;
    if (slow === fast) { // se encuentran dentro del ciclo
      let p = head;
      while (p !== slow) { p = p.next; slow = slow.next; }
      return p;
    }
  }
  return null;
}
```

### `06/02` — La caché LRU

De [`06/02` — Listas enlazadas, §5](../06-lineales-y-hashing/02-listas-enlazadas.md#5--la-caché-lru).

```javascript
// LRU de capacidad cap. Un Map recorre sus claves en orden de inserción: borrar y volver a insertar
// lleva una clave al final (la más reciente), y la primera es la menos reciente. O(1) esperado.
class LRUCache {
  constructor(cap) {
    this.cap = cap;
    this.map = new Map();
  }
  get(key) {
    if (!this.map.has(key)) return -1;
    const value = this.map.get(key);
    this.map.delete(key);
    this.map.set(key, value);
    return value;
  }
  put(key, value) {
    this.map.delete(key);
    this.map.set(key, value);
    if (this.map.size > this.cap) this.map.delete(this.map.keys().next().value);
  }
}
```

### `06/03` — Encadenamiento y direccionamiento abierto

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §3](../06-lineales-y-hashing/03-tablas-hash.md#3--encadenamiento-y-direccionamiento-abierto).

```javascript
// Conjunto de enteros de 32 bits con sondeo lineal; capacidad potencia de 2; α ≤ 1/2.
// Didáctico: en JavaScript, Set. Los arreglos tipados guardan números sin objetos por casilla.
class IntSet {
  constructor() {
    this.keys = new Int32Array(16);
    this.used = new Uint8Array(16);
    this.n = 0;
  }
  #slot(x) {
    // multiplicativa de Fibonacci: los log₂(capacidad) bits altos del producto de 32 bits
    return Math.imul(x, 0x9e3779b1) >>> (Math.clz32(this.keys.length) + 1);
  }
  has(x) {
    for (let i = this.#slot(x); this.used[i]; i = (i + 1) & (this.keys.length - 1))
      if (this.keys[i] === x) return true;
    return false;
  }
  add(x) {
    if (2 * (this.n + 1) > this.keys.length) { // rehash: el doble de capacidad y reinsertar todo
      const oldKeys = this.keys, oldUsed = this.used;
      this.keys = new Int32Array(2 * oldKeys.length);
      this.used = new Uint8Array(2 * oldKeys.length);
      this.n = 0;
      for (let i = 0; i < oldKeys.length; i++) if (oldUsed[i]) this.add(oldKeys[i]);
    }
    let i = this.#slot(x);
    for (; this.used[i]; i = (i + 1) & (this.keys.length - 1)) if (this.keys[i] === x) return;
    this.keys[i] = x;
    this.used[i] = 1;
    this.n++;
  }
}
```

---

## 🧱 Bloque 07 — Árboles

### `07/01` — Representación

De [`07/01` — Árboles: representación y recorridos, §3](../07-arboles/01-arboles-y-recorridos.md#3--representación).

```javascript
// Árbol de n nodos (1..n) a partir de sus n − 1 aristas no dirigidas.
function buildTree(n, edges) {
  const adj = Array.from({ length: n + 1 }, () => []);
  for (const [u, v] of edges) {
    adj[u].push(v);
    adj[v].push(u);
  }
  return adj;
}
```

### `07/01` — Los cuatro recorridos

De [`07/01` — Árboles: representación y recorridos, §4](../07-arboles/01-arboles-y-recorridos.md#4--los-cuatro-recorridos).

```javascript
// Nodo binario: { val, left, right }.
function inorder(t, out) {
  if (t) {
    inorder(t.left, out);
    out.push(t.val);
    inorder(t.right, out);
  }
}

// Preorden iterativo con una pila; devuelve [orden, padres, profundidades]. O(n).
function preorder(adj, root) {
  const n = adj.length, parent = new Array(n).fill(0), depth = new Array(n).fill(0), order = [], st = [root];
  parent[root] = -1;
  while (st.length) {
    const v = st.pop();
    order.push(v);
    for (const w of adj[v]) {
      if (w !== parent[v]) {
        parent[w] = v;
        depth[w] = depth[v] + 1;
        st.push(w);
      }
    }
  }
  return [order, parent, depth];
}
```

### `07/01` — Diámetro

De [`07/01` — Árboles: representación y recorridos, §5](../07-arboles/01-arboles-y-recorridos.md#5--diámetro).

```javascript
// [nodo más lejano de s, distancia]: BFS sobre un árbol sin pesos. O(n).
function farthest(adj, s) {
  const dist = new Array(adj.length).fill(-1);
  dist[s] = 0;
  const queue = [s];
  let best = s;
  for (let head = 0; head < queue.length; head++) { // cola: arreglo con índice de cabeza, sin shift()
    const v = queue[head];
    if (dist[v] > dist[best]) best = v;
    for (const w of adj[v]) {
      if (dist[w] < 0) {
        dist[w] = dist[v] + 1;
        queue.push(w);
      }
    }
  }
  return [best, dist[best]];
}

// Diámetro (en aristas): el más lejano del más lejano de cualquier nodo.
const diameter = (adj) => farthest(adj, farthest(adj, 1)[0])[1];
```

### `07/02` — El árbol binario de búsqueda

De [`07/02` — BST y árboles balanceados, §3](../07-arboles/02-bst-y-balanceados.md#3--el-árbol-binario-de-búsqueda).

```javascript
// Nodo: { key, left, right }. Sin mapa ordenado en la librería, el BST es el sustituto mínimo.
function insert(t, key) {
  if (t === null) return { key, left: null, right: null };
  if (key < t.key) t.left = insert(t.left, key);
  else if (key > t.key) t.right = insert(t.right, key);
  return t;
}

// Menor clave >= x, o null. O(h).
function ceiling(t, x) {
  let best = null;
  while (t) {
    if (t.key >= x) { best = t; t = t.left; }
    else t = t.right;
  }
  return best;
}
```

### `07/04` — *Trie* de palabras

De [`07/04` — *Tries*, §3](../07-arboles/04-tries.md#3--trie-de-palabras).

```javascript
// Trie con un Map de hijos por nodo: insert y countPrefix en O(L).
class Trie {
  constructor() {
    this.next = [new Map()];
    this.pass = [0];
    this.end = [0];
  }
  insert(w) {
    let v = 0;
    for (const ch of w) {
      let nxt = this.next[v].get(ch);
      if (nxt === undefined) {
        nxt = this.next.length;
        this.next[v].set(ch, nxt);
        this.next.push(new Map());
        this.pass.push(0);
        this.end.push(0);
      }
      v = nxt;
      this.pass[v]++;
    }
    this.end[v]++;
  }
  countPrefix(p) {
    let v = 0;
    for (const ch of p) {
      v = this.next[v].get(ch);
      if (v === undefined) return 0;
    }
    return this.pass[v];
  }
}
```

### `07/04` — *Trie* binario

De [`07/04` — *Tries*, §4](../07-arboles/04-tries.md#4--trie-binario).

```javascript
// Trie binario de enteros no negativos de 30 bits; borrado con contadores. O(B) por operación.
// Los operadores de bits de JavaScript trabajan en 32 bits con signo: con B ≤ 30 no hay sorpresas.
class XorTrie {
  static B = 30;
  constructor() {
    this.next = [[0, 0]];
    this.cnt = [0];
  }
  add(x, d = 1) { // d = 1 inserta, d = −1 borra
    let v = 0;
    for (let b = XorTrie.B - 1; b >= 0; b--) {
      const bit = (x >> b) & 1;
      if (!this.next[v][bit]) {
        this.next[v][bit] = this.next.length;
        this.next.push([0, 0]);
        this.cnt.push(0);
      }
      v = this.next[v][bit];
      this.cnt[v] += d;
    }
  }
  maxXor(x) { // pre: el trie no está vacío
    let v = 0, res = 0;
    for (let b = XorTrie.B - 1; b >= 0; b--) {
      const want = ((x >> b) & 1) ^ 1, u = this.next[v][want];
      if (u && this.cnt[u] > 0) { res |= 1 << b; v = u; }
      else v = this.next[v][want ^ 1];
    }
    return res;
  }
}
```

### `07/05` — *Binary lifting*

De [`07/05` — LCA, §3](../07-arboles/05-lca.md#3--binary-lifting).

```javascript
// Binary lifting. parent[root] = root.
class Lca {
  constructor(parent, depth) {
    const n = parent.length;
    this.LOG = Math.max(1, 32 - Math.clz32(n - 1)); // bits de n − 1
    this.depth = depth;
    this.up = [[...parent]];
    for (let k = 1; k < this.LOG; k++) {
      const prev = this.up[k - 1];
      this.up.push(prev.map((p) => prev[p]));
    }
  }
  lift(v, d) {
    for (let k = 0; d; k++, d >>= 1) if (d & 1) v = this.up[k][v];
    return v;
  }
  query(u, v) {
    if (this.depth[u] < this.depth[v]) [u, v] = [v, u];
    u = this.lift(u, this.depth[u] - this.depth[v]);
    if (u === v) return u;
    for (let k = this.LOG - 1; k >= 0; k--) {
      if (this.up[k][u] !== this.up[k][v]) {
        u = this.up[k][u];
        v = this.up[k][v];
      }
    }
    return this.up[0][u];
  }
}
```

---

## 🧱 Bloque 08 — Heaps y Union-Find

### `08/01` — El montículo binario

De [`08/01` — Montículo binario, §3](../08-heaps-y-union-find/01-monticulo-binario.md#3--el-montículo-binario).

```javascript
// Montículo binario con comparador: less(a, b) dice si a va antes. push y pop en O(log n).
// JavaScript no trae cola de prioridad: esta clase la usan las demás plantillas del cuaderno.
class Heap {
  constructor(less = (x, y) => x < y, a = []) {
    this.less = less;
    this.a = a;
  }
  get size() { return this.a.length; }
  top() { return this.a[0]; } // pre: size > 0
  push(x) {
    const a = this.a;
    a.push(x);
    for (let i = a.length - 1; i > 0;) { // flotar
      const p = (i - 1) >> 1;
      if (!this.less(a[i], a[p])) break;
      [a[i], a[p]] = [a[p], a[i]];
      i = p;
    }
  }
  pop() { // pre: size > 0
    const a = this.a, res = a[0], last = a.pop();
    if (a.length) {
      a[0] = last;
      this.down(0);
    }
    return res;
  }
  replaceTop(x) { // sustituye la cima con una sola bajada (el heapreplace de Python)
    this.a[0] = x;
    this.down(0);
  }
  down(i) { // hundir
    const a = this.a, n = a.length;
    while (2 * i + 1 < n) {
      let c = 2 * i + 1;
      if (c + 1 < n && this.less(a[c + 1], a[c])) c++;
      if (!this.less(a[c], a[i])) break;
      [a[i], a[c]] = [a[c], a[i]];
      i = c;
    }
  }
}
```

### `08/01` — `heapify`

De [`08/01` — Montículo binario, §4](../08-heaps-y-union-find/01-monticulo-binario.md#4--heapify).

```javascript
// Heapify: convierte un arreglo en montículo en el sitio, hundiendo de n/2 − 1 hacia atrás. O(n).
// Con [5, 2, 9, 1, 5, 6] y menor primero, queda [1, 2, 6, 5, 5, 9].
function heapify(a, less = (x, y) => x < y) {
  const h = new Heap(less, a);
  for (let i = (a.length >> 1) - 1; i >= 0; i--) h.down(i);
  return h;
}
```

### `08/02` — Los `k` mayores

De [`08/02` — Patrones con *heap*, §3](../08-heaps-y-union-find/02-patrones-con-heap.md#3--los-k-mayores).

```javascript
// Los k mayores de a, en orden creciente, con el Heap de 08/01. O(n log k) tiempo, O(k) memoria.
function topK(a, k) {
  const h = new Heap(); // de mínimos: la cima es el menor de los k
  for (const x of a) {
    if (h.size < k) h.push(x);
    else if (k > 0 && x > h.top()) h.replaceTop(x);
  }
  const out = [];
  while (h.size) out.push(h.pop()); // salen en orden creciente
  return out;
}
```

### `08/02` — Mezcla de `k` listas

De [`08/02` — Patrones con *heap*, §4](../08-heaps-y-union-find/02-patrones-con-heap.md#4--mezcla-de-k-listas).

```javascript
// Mezcla k arreglos ordenados, con el Heap de 08/01. O(N log k).
function mergeK(lists) {
  const h = new Heap((x, y) => x[0] < y[0]); // [valor, lista, posición]
  lists.forEach((l, i) => { if (l.length) h.push([l[0], i, 0]); });
  const out = [];
  while (h.size) {
    const [v, i, j] = h.pop();
    out.push(v);
    if (j + 1 < lists[i].length) h.push([lists[i][j + 1], i, j + 1]);
  }
  return out;
}
```

### `08/02` — La mediana con dos *heaps*

De [`08/02` — Patrones con *heap*, §5](../08-heaps-y-union-find/02-patrones-con-heap.md#5--la-mediana-con-dos-heaps).

```javascript
// Mediana inferior de un flujo, con el Heap de 08/01. add O(log n), median O(1).
class RunningMedian {
  constructor() {
    this.lo = new Heap((x, y) => x > y); // la mitad baja, de máximos
    this.hi = new Heap((x, y) => x < y); // la mitad alta, de mínimos
  }
  add(x) {
    if (!this.lo.size || x <= this.lo.top()) this.lo.push(x);
    else this.hi.push(x);
    if (this.lo.size > this.hi.size + 1) this.hi.push(this.lo.pop()); // lo tiene igual o uno más
    else if (this.hi.size > this.lo.size) this.lo.push(this.hi.pop());
  }
  median() { return this.lo.top(); } // pre: se añadió al menos uno
}
```

### `08/04` — Union-Find

De [`08/04` — Union-Find, §3](../08-heaps-y-union-find/04-union-find.md#3--union-find).

```javascript
// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
class DSU {
  constructor(n) {
    this.parent = Int32Array.from({ length: n }, (_, i) => i);
    this.size = new Int32Array(n).fill(1);
  }
  find(x) {
    const p = this.parent;
    while (p[x] !== x) {
      p[x] = p[p[x]]; // halving: cada nodo salta a su abuelo
      x = p[x];
    }
    return x;
  }
  unite(a, b) {
    a = this.find(a);
    b = this.find(b);
    if (a === b) return false;
    if (this.size[a] < this.size[b]) [a, b] = [b, a];
    this.parent[b] = a;
    this.size[a] += this.size[b];
    return true;
  }
}
```

---

## 🧱 Bloque 09 — Consultas sobre rangos

### `09/02` — Puntual y rango

De [`09/02` — Fenwick, §3](../09-consultas-sobre-rangos/02-fenwick.md#3--puntual-y-rango).

```javascript
// Fenwick de sumas, índices 1..n. add y prefix en O(log n). Float64Array: exacto hasta 2⁵³.
class Fenwick {
  constructor(n) {
    this.n = n;
    this.t = new Float64Array(n + 1);
  }
  add(i, d) {
    for (; i <= this.n; i += i & -i) this.t[i] += d; // i & -i: el bit más bajo (índices < 2³¹)
  }
  prefix(i) { // suma de 1..i
    let s = 0;
    for (; i > 0; i -= i & -i) s += this.t[i];
    return s;
  }
  range(l, r) { return this.prefix(r) - this.prefix(l - 1); }
}
```

### `09/02` — Rango y puntual

De [`09/02` — Fenwick, §4](../09-consultas-sobre-rangos/02-fenwick.md#4--rango-y-puntual).

```javascript
// Rango y puntual: el Fenwick de 09/02 §3 sobre las diferencias (de tamaño n + 1).
function rangeAdd(f, l, r, v) {
  f.add(l, v);
  f.add(r + 1, -v);
}

const pointGet = (f, i) => f.prefix(i);
```

---

## 🧱 Bloque 10 — Búsqueda completa y divide y vencerás

### `10/01` — Recursión y pila de llamadas

De [`10/01` — Recursión, §3](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#3--recursión-y-pila-de-llamadas).

```javascript
// Mueve n discos de src a dst usando via. Θ(2ⁿ) tiempo, Θ(n) pila.
// La pila de Node aguanta del orden de diez mil llamadas: más hondo, versión iterativa (§4).
function hanoi(n, src, dst, via, out) {
  if (n === 0) return; // caso base
  hanoi(n - 1, src, via, dst, out);
  out.push(`${src} ${dst}`);
  hanoi(n - 1, via, dst, src, out);
}
```

### `10/01` — Paso a iterativo

De [`10/01` — Recursión, §4](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#4--paso-a-iterativo).

```javascript
// Hanoi iterativo: marcos [n, src, dst, via, etapa] en un arreglo. Θ(2ⁿ) tiempo, Θ(n) memoria.
function hanoiIterative(n, src, dst, via, out) {
  const stack = [[n, src, dst, via, 0]];
  while (stack.length) {
    const f = stack[stack.length - 1];
    const [k, a, b, c, stage] = f;
    if (k === 0 || stage === 2) stack.pop(); // base o terminado: vuelve
    else if (stage === 0) {
      f[4] = 1;
      stack.push([k - 1, a, c, b, 0]); // hanoi(k−1, src, via, dst)
    } else {
      out.push(`${a} ${b}`);
      f[4] = 2;
      stack.push([k - 1, c, b, a, 0]); // hanoi(k−1, via, dst, src)
    }
  }
}
```

### `10/02` — Subconjuntos con máscaras de bits

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §3](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#3--subconjuntos-con-máscaras-de-bits).

```javascript
// sum[m] = suma de los a[i] con el bit i encendido en m. Θ(2ⁿ) tiempo y memoria; n ≤ 30.
function subsetSums(a) {
  const n = a.length, total = new Float64Array(1 << n);
  for (let m = 1; m < 1 << n; m++) {
    const low = 31 - Math.clz32(m & -m); // índice del bit más bajo
    total[m] = total[m & (m - 1)] + a[low];
  }
  return total;
}
```

### `10/02` — Permutaciones

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §4](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#4--permutaciones).

```javascript
// Siguiente permutación lexicográfica en su sitio; false si a era la última.
function nextPermutation(a) {
  let i = a.length - 2;
  while (i >= 0 && a[i] >= a[i + 1]) i--;
  if (i < 0) return false;
  let j = a.length - 1;
  while (a[j] <= a[i]) j--;
  [a[i], a[j]] = [a[j], a[i]];
  for (let l = i + 1, r = a.length - 1; l < r; l++, r--) [a[l], a[r]] = [a[r], a[l]]; // invertir el sufijo
  return true;
}

// Recursiva: añade a cur cada índice no usado y deshace al volver.
function permute(a, cur, used, visit) {
  if (cur.length === a.length) return visit(cur); // procesar cur (copiarlo si se guarda)
  for (let i = 0; i < a.length; i++) {
    if (!used[i]) {
      used[i] = true;
      cur.push(a[i]);
      permute(a, cur, used, visit);
      cur.pop();
      used[i] = false;
    }
  }
}
```

### `10/02` — Combinaciones

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §5](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#5--combinaciones).

```javascript
// Todas las combinaciones de k índices de [0, n), en orden lexicográfico.
function combine(n, k, start, cur, visit) {
  if (cur.length === k) return visit(cur); // procesar cur
  for (let i = start; i <= n - (k - cur.length); i++) { // poda: quedan huecos suficientes
    cur.push(i);
    combine(n, k, i + 1, cur, visit);
    cur.pop();
  }
}
```

### `10/03` — *Backtracking*

De [`10/03` — *Backtracking* con poda y ramificación y poda, §3](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#3--backtracking).

```javascript
// Subconjuntos (por posición) de a con suma exacta rem. a ascendente y positivo;
// suffix[j] = a[j] + … + a[n−1].
function countSubsets(a, suffix, start, rem) {
  if (rem === 0) return 1;
  let count = 0;
  for (let j = start; j < a.length; j++) {
    if (a[j] > rem || suffix[j] < rem) break; // las dos podas
    count += countSubsets(a, suffix, j + 1, rem - a[j]);
  }
  return count;
}
```

### `10/05` — El esquema

De [`10/05` — Divide y vencerás, §3](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#3--el-esquema).

```javascript
// Suma máxima de un subarreglo no vacío de a[lo..hi). Θ(n log n). Pre: lo < hi.
function maxSubarrayDC(a, lo, hi) {
  if (hi - lo === 1) return a[lo];
  const mid = (lo + hi) >> 1;
  const best = Math.max(maxSubarrayDC(a, lo, mid), maxSubarrayDC(a, mid, hi));
  let s = 0, leftBest = -Infinity;
  for (let i = mid - 1; i >= lo; i--) leftBest = Math.max(leftBest, (s += a[i]));
  s = 0;
  let rightBest = -Infinity;
  for (let i = mid; i < hi; i++) rightBest = Math.max(rightBest, (s += a[i]));
  return Math.max(best, leftBest + rightBest); // el mejor que cruza el centro
}
```

### `10/05` — Exponenciación rápida

De [`10/05` — Divide y vencerás, §6](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#6--exponenciación-rápida).

```javascript
// aⁿ mod m con BigInt. Con Number, a * b pierde precisión en cuanto pasa de 2⁵³ (m mayor que ~9·10⁷),
// sin avisar: el resultado sale mal, no da error.
function powMod(a, n, m) {
  a = BigInt(a); n = BigInt(n); m = BigInt(m);
  let result = 1n % m, base = ((a % m) + m) % m;
  for (; n > 0n; n >>= 1n) {
    if (n & 1n) result = (result * base) % m;
    base = (base * base) % m;
  }
  return result;
}
```

---

## 🧱 Bloque 11 — Voraces

### `11/02` — Selección de actividades

De [`11/02` — Intervalos, §3](../11-voraces/02-intervalos.md#3--selección-de-actividades).

```javascript
// Máximo número de intervalos [s, f) disjuntos. Θ(n log n).
function maxDisjoint(intervals) {
  let count = 0, lastEnd = -Infinity;
  for (const [s, f] of [...intervals].sort((p, q) => p[1] - q[1])) { // por final
    if (s >= lastEnd) {
      count++;
      lastEnd = f;
    }
  }
  return count;
}
```

### `11/02` — Cubrimiento con puntos

De [`11/02` — Intervalos, §4](../11-voraces/02-intervalos.md#4--cubrimiento-con-puntos).

```javascript
// Mínimo de puntos que pinchan todos los intervalos cerrados [s, f]. Θ(n log n).
function minPoints(intervals) {
  let count = 0, last = -Infinity;
  for (const [s, f] of [...intervals].sort((p, q) => p[1] - q[1])) {
    if (s > last) { // no lo pincha el último punto: uno nuevo en su final
      count++;
      last = f;
    }
  }
  return count;
}
```

### `11/02` — Mezcla

De [`11/02` — Intervalos, §5](../11-voraces/02-intervalos.md#5--mezcla).

```javascript
// Unión de intervalos cerrados [s, f], como lista ordenada de disjuntos. Θ(n log n).
function mergeClosed(intervals) {
  const out = [];
  for (const [s, f] of [...intervals].sort((p, q) => p[0] - q[0])) {
    const last = out[out.length - 1];
    if (last && s <= last[1]) last[1] = Math.max(last[1], f); // cerrados: tocarse ya es solaparse
    else out.push([s, f]);
  }
  return out;
}
```

### `11/02` — Mínimo de salas

De [`11/02` — Intervalos, §6](../11-voraces/02-intervalos.md#6--mínimo-de-salas).

```javascript
// Mínimo de salas para reuniones [s, f) (la profundidad máxima). Θ(n log n).
function minRooms(intervals) {
  const starts = intervals.map((x) => x[0]).sort((p, q) => p - q);
  const ends = intervals.map((x) => x[1]).sort((p, q) => p - q);
  let rooms = 0, best = 0, j = 0;
  for (const s of starts) {
    while (j < ends.length && ends[j] <= s) { j++; rooms--; } // la que acaba en s libera la sala
    best = Math.max(best, ++rooms);
  }
  return best;
}
```

### `11/03` — Planificación con plazos

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §3](../11-voraces/03-plazos-huffman-y-monedas.md#3--planificación-con-plazos).

```javascript
// Máximo beneficio de tareas unitarias [plazo, beneficio] que acaban a tiempo, con el Heap de 08/01.
// Θ(n log n).
function maxProfit(jobs) {
  const kept = new Heap(); // las elegidas; la cima es la de menor beneficio
  let total = 0;
  for (const [d, p] of [...jobs].sort((x, y) => x[0] - y[0])) { // por plazo
    kept.push(p);
    total += p;
    if (kept.size > d) total -= kept.pop(); // no caben: se suelta la peor
  }
  return total;
}
```

### `11/03` — Huffman

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §4](../11-voraces/03-plazos-huffman-y-monedas.md#4--huffman).

```javascript
// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman, con el Heap de 08/01. Θ(n log n).
function huffmanCost(freq) {
  const h = new Heap();
  for (const f of freq) h.push(f);
  let cost = 0;
  while (h.size > 1) {
    const a = h.pop(), b = h.pop();
    cost += a + b;
    h.push(a + b);
  }
  return cost;
}
```

### `11/03` — Mochila fraccionaria

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §5](../11-voraces/03-plazos-huffman-y-monedas.md#5--mochila-fraccionaria).

```javascript
// Valor máximo con materiales divisibles [peso, valor], exacto: devuelve [numerador, denominador]
// como BigInt. JavaScript no tiene fracciones; comparar v₁·w₂ con v₂·w₁ evita dividir. Θ(n log n).
function fractionalKnapsack(items, cap) {
  const gcd = (x, y) => { while (y) [x, y] = [y, x % y]; return x; };
  let num = 0n, den = 1n;
  for (const [w, v] of [...items].sort((p, q) => q[1] * p[0] - p[1] * q[0])) { // valor/peso decreciente
    if (cap === 0) break;
    const take = Math.min(w, cap);
    num = num * BigInt(w) + BigInt(v * take) * den; // num/den + v·take/w
    den *= BigInt(w);
    const g = gcd(num, den);
    num /= g;
    den /= g;
    cap -= take;
  }
  return [num, den];
}
```

### `11/03` — Monedas canónicas

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §6](../11-voraces/03-plazos-huffman-y-monedas.md#6--monedas-canónicas).

```javascript
// Monedas del voraz para x; coins de mayor a menor, con la de 1. O(k).
function greedyCoins(coins, x) {
  let count = 0;
  for (const c of coins) {
    count += Math.floor(x / c);
    x %= c;
  }
  return count;
}
```

---

## 🧱 Bloque 12 — DP clásica

### `12/01` — Memoización

De [`12/01` — De la recursión a la tabla, §3](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#3--memoización).

```javascript
const MOD = 1_000_000_007;

// Formas de llegar al escalón i con pasos de 1, 2 o 3, con un Map como memoria.
// La recursión de Node se agota hacia los diez mil niveles: para n grande, la tabla de §4.
function ways(i, memo = new Map()) {
  if (i < 0) return 0;
  if (i === 0) return 1;
  if (memo.has(i)) return memo.get(i); // ya calculado: O(1)
  const r = (ways(i - 1, memo) + ways(i - 2, memo) + ways(i - 3, memo)) % MOD; // < 3·MOD: exacto
  memo.set(i, r);
  return r;
}
```

### `12/01` — Tabulación

De [`12/01` — De la recursión a la tabla, §4](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#4--tabulación).

```javascript
// Formas de subir n escalones con pasos de 1, 2 o 3, sin pisar los rotos. Θ(n). Usa MOD de §3.
function waysTable(n, broken) {
  const dp = new Array(n + 1).fill(0);
  dp[0] = 1;
  for (let i = 1; i <= n; i++) {
    if (broken[i]) continue; // dp[i] = 0: no se puede pisar
    for (let s = 1; s <= 3 && s <= i; s++) dp[i] += dp[i - s];
    dp[i] %= MOD;
  }
  return dp[n];
}
```

### `12/01` — Reconstrucción

De [`12/01` — De la recursión a la tabla, §5](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#5--reconstrucción).

```javascript
// Menor número de operaciones +1, ×2, ×3 de 1 a n, y la secuencia de valores. Θ(n).
function opsPath(n) {
  const dp = new Int32Array(n + 1), parent = new Int32Array(n + 1);
  for (let x = 2; x <= n; x++) {
    dp[x] = dp[x - 1] + 1;
    parent[x] = x - 1;
    for (const d of [2, 3]) {
      if (x % d === 0 && dp[x / d] + 1 < dp[x]) {
        dp[x] = dp[x / d] + 1;
        parent[x] = x / d;
      }
    }
  }
  const path = [];
  for (let x = n; x !== 1; x = parent[x]) path.push(x); // se sigue la cadena de padres
  path.push(1);
  return path.reverse();
}
```

### `12/02` — Escaleras y robos

De [`12/02` — DP lineal y LIS, §3](../12-dp-clasica/02-dp-lineal-y-lis.md#3--escaleras-y-robos).

```javascript
// Mayor suma de elementos sin coger dos consecutivos. Θ(n), O(1) memoria.
function maxNonAdjacent(a) {
  let take = 0, skip = 0;
  for (const x of a) [take, skip] = [skip + x, Math.max(take, skip)]; // asignación simultánea
  return Math.max(take, skip);
}
```

### `12/02` — LIS en O(n²)

De [`12/02` — DP lineal y LIS, §4](../12-dp-clasica/02-dp-lineal-y-lis.md#4--lis-en-on).

```javascript
// Una LIS estrictamente creciente, por índices. Θ(n²).
function lisQuadratic(a) {
  const n = a.length, d = new Array(n).fill(1), parent = new Array(n).fill(-1);
  let best = 0;
  for (let i = 0; i < n; i++) {
    for (let j = 0; j < i; j++) {
      if (a[j] < a[i] && d[j] + 1 > d[i]) {
        d[i] = d[j] + 1;
        parent[i] = j;
      }
    }
    if (d[i] > d[best]) best = i;
  }
  const seq = [];
  for (let i = n ? best : -1; i !== -1; i = parent[i]) seq.push(i);
  return seq.reverse();
}
```

### `12/02` — LIS en O(n log n)

De [`12/02` — DP lineal y LIS, §5](../12-dp-clasica/02-dp-lineal-y-lis.md#5--lis-en-on-log-n).

```javascript
// Una LIS estrictamente creciente, por índices. Θ(n log n).
function lisFast(a) {
  const tails = [], tailIdx = [], parent = new Array(a.length).fill(-1);
  for (let i = 0; i < a.length; i++) {
    let lo = 0, hi = tails.length; // lower bound: estricta; con <= sería no decreciente
    while (lo < hi) {
      const mid = (lo + hi) >>> 1;
      if (tails[mid] < a[i]) lo = mid + 1;
      else hi = mid;
    }
    tails[lo] = a[i];
    tailIdx[lo] = i;
    if (lo > 0) parent[i] = tailIdx[lo - 1];
  }
  const seq = [];
  for (let i = tailIdx.length ? tailIdx[tailIdx.length - 1] : -1; i !== -1; i = parent[i]) seq.push(i);
  return seq.reverse();
}
```

### `12/03` — Mochila 0/1

De [`12/03` — Mochilas, §3](../12-dp-clasica/03-mochilas.md#3--mochila-01).

```javascript
// Mochila 0/1: [mejor valor, índices elegidos]. Θ(n · W).
function knapsack01(w, v, W) {
  const n = w.length;
  const dp = Array.from({ length: n + 1 }, () => new Float64Array(W + 1));
  for (let i = 1; i <= n; i++) {
    const wi = w[i - 1], vi = v[i - 1], prev = dp[i - 1], row = dp[i];
    for (let c = 0; c <= W; c++) {
      row[c] = prev[c]; // sin el objeto i − 1
      if (wi <= c && prev[c - wi] + vi > row[c]) row[c] = prev[c - wi] + vi; // con él
    }
  }
  const chosen = [];
  for (let i = n, c = W; i > 0; i--) {
    if (dp[i][c] !== dp[i - 1][c]) { // cambió: el objeto i − 1 está dentro
      chosen.push(i - 1);
      c -= w[i - 1];
    }
  }
  return [dp[n][W], chosen.reverse()];
}
```

### `12/03` — Una fila de memoria

De [`12/03` — Mochilas, §4](../12-dp-clasica/03-mochilas.md#4--una-fila-de-memoria).

```javascript
// Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria.
function knapsackRow(w, v, W) {
  const dp = new Float64Array(W + 1);
  for (let i = 0; i < w.length; i++)
    for (let c = W; c >= w[i]; c--) dp[c] = Math.max(dp[c], dp[c - w[i]] + v[i]); // descendente
  return dp[W];
}
```

### `12/03` — Mochila ilimitada

De [`12/03` — Mochilas, §5](../12-dp-clasica/03-mochilas.md#5--mochila-ilimitada).

```javascript
// Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W).
function knapsackUnbounded(w, v, W) {
  const dp = new Float64Array(W + 1);
  for (let i = 0; i < w.length; i++)
    for (let c = w[i]; c <= W; c++) dp[c] = Math.max(dp[c], dp[c - w[i]] + v[i]); // ascendente
  return dp[W];
}
```

### `12/03` — Monedas: contar y mínimo

De [`12/03` — Mochilas, §6](../12-dp-clasica/03-mochilas.md#6--monedas-contar-y-mínimo).

```javascript
// Combinaciones (sin orden) de pagar x: las monedas por fuera. Usa MOD de 12/01 §3.
function countCombinations(coins, x) {
  const ways = new Array(x + 1).fill(0);
  ways[0] = 1;
  for (const c of coins) for (let s = c; s <= x; s++) ways[s] = (ways[s] + ways[s - c]) % MOD;
  return ways[x];
}

// Mínimo de monedas para pagar x, o -1.
function minCoins(coins, x) {
  const mn = new Array(x + 1).fill(Infinity);
  mn[0] = 0;
  for (let s = 1; s <= x; s++) for (const c of coins) if (c <= s) mn[s] = Math.min(mn[s], mn[s - c] + 1);
  return mn[x] === Infinity ? -1 : mn[x];
}
```

### `12/04` — LCS

De [`12/04` — DP sobre cadenas, §3](../12-dp-clasica/04-dp-sobre-cadenas.md#3--lcs).

```javascript
// Una subsecuencia común más larga de a y b (por unidades de UTF-16). Θ(n · m).
function lcs(a, b) {
  const n = a.length, m = b.length;
  const L = Array.from({ length: n + 1 }, () => new Int32Array(m + 1));
  for (let i = 1; i <= n; i++)
    for (let j = 1; j <= m; j++)
      L[i][j] = a[i - 1] === b[j - 1] ? L[i - 1][j - 1] + 1 : Math.max(L[i - 1][j], L[i][j - 1]);
  const out = [];
  for (let i = n, j = m; i > 0 && j > 0;) {
    if (a[i - 1] === b[j - 1]) { out.push(a[i - 1]); i--; j--; }
    else if (L[i - 1][j] >= L[i][j - 1]) i--;
    else j--;
  }
  return out.reverse().join("");
}
```

### `12/04` — Distancia de edición

De [`12/04` — DP sobre cadenas, §4](../12-dp-clasica/04-dp-sobre-cadenas.md#4--distancia-de-edición).

```javascript
// Distancia de Levenshtein entre a y b, con dos filas. Θ(n · m) tiempo, Θ(m) memoria.
function editDistance(a, b) {
  let prev = Int32Array.from({ length: b.length + 1 }, (_, j) => j), cur = new Int32Array(b.length + 1);
  for (let i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (let j = 1; j <= b.length; j++)
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] !== b[j - 1] ? 1 : 0));
    [prev, cur] = [cur, prev];
  }
  return prev[b.length];
}
```

### `12/04` — Subsecuencias y palíndromos

De [`12/04` — DP sobre cadenas, §5](../12-dp-clasica/04-dp-sobre-cadenas.md#5--subsecuencias-y-palíndromos).

```javascript
// Longitud de la subsecuencia palindrómica más larga de s. Θ(n²).
function longestPalSubseq(s) {
  const n = s.length;
  if (n === 0) return 0;
  const P = Array.from({ length: n }, () => new Int32Array(n));
  for (let i = n - 1; i >= 0; i--) {
    P[i][i] = 1;
    for (let j = i + 1; j < n; j++)
      P[i][j] = s[i] === s[j] ? P[i + 1][j - 1] + 2 : Math.max(P[i + 1][j], P[i][j - 1]); // P[i+1][i] = 0
  }
  return P[0][n - 1];
}
```

### `12/05` — Rejillas

De [`12/05` — DP en rejillas y de intervalos, §3](../12-dp-clasica/05-rejillas-e-intervalos.md#3--rejillas).

```javascript
// Máximo recogido bajando o a la derecha; '#' bloquea; '.' vale 0; un dígito, su valor. -1 si no hay camino.
function bestPath(g) {
  const R = g.length, C = g[0].length, d = new Array(C).fill(null); // null = inalcanzable
  for (let i = 0; i < R; i++) {
    for (let j = 0; j < C; j++) {
      if (g[i][j] === "#") { d[j] = null; continue; }
      const options = i === 0 && j === 0 ? [0] : [i > 0 ? d[j] : null, j > 0 ? d[j - 1] : null].filter((x) => x !== null);
      d[j] = options.length ? Math.max(...options) + (g[i][j] === "." ? 0 : Number(g[i][j])) : null;
    }
  }
  return d[C - 1] ?? -1;
}
```

### `12/06` — Conteo

De [`12/06` — Conteo con DP, §3](../12-dp-clasica/06-conteo.md#3--conteo).

```javascript
// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c].
// Usa MOD de 12/01 §3. Θ(n · L²).
function countWords(n, allowed) {
  const L = allowed.length;
  let cur = new Array(L).fill(1);
  for (let step = 1; step < n; step++) {
    const next = new Array(L).fill(0);
    for (let c = 0; c < L; c++) {
      for (let p = 0; p < L; p++) if (allowed[p][c]) next[c] += cur[p]; // L sumandos < MOD: exacto si L < 9·10⁶
      next[c] %= MOD;
    }
    cur = next;
  }
  return cur.reduce((x, y) => x + y, 0) % MOD;
}
```

---

## 🧱 Bloque 13 — DP avanzada

### `13/03` — DP en árboles

De [`13/03` — DP en árboles y en DAG, §3](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#3--dp-en-árboles).

```javascript
// Conjunto independiente de peso máximo en un árbol con raíz 0 y padres parent (parent[0] = -1). Θ(n).
function maxIndependentSet(parent, w) {
  const n = parent.length, children = Array.from({ length: n }, () => []);
  for (let v = 1; v < n; v++) children[parent[v]].push(v);
  const order = [], stack = [0];
  while (stack.length) { // preorden iterativo: sin recursión, sin el límite de la pila
    const v = stack.pop();
    order.push(v);
    stack.push(...children[v]);
  }
  const inc = new Array(n).fill(0), exc = new Array(n).fill(0); // con v dentro / sin v
  for (let k = n - 1; k >= 0; k--) { // al revés: hijos antes que padres
    const v = order[k];
    inc[v] = w[v];
    for (const c of children[v]) {
      inc[v] += exc[c];
      exc[v] += Math.max(inc[c], exc[c]);
    }
  }
  return Math.max(inc[0], exc[0]);
}
```

### `13/03` — DP sobre DAG

De [`13/03` — DP en árboles y en DAG, §4](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#4--dp-sobre-dag).

```javascript
// En un DAG con adj[u] = [[v, w], …]: [caminos desde s mod 1e9+7, camino más largo desde s (null si
// v no se alcanza)]. Θ(V + E).
function dagDP(n, adj, s) {
  const MOD = 1_000_000_007, indeg = new Array(n).fill(0);
  for (let u = 0; u < n; u++) for (const [v] of adj[u]) indeg[v]++;
  const order = [];
  for (let u = 0; u < n; u++) if (indeg[u] === 0) order.push(u);
  for (let head = 0; head < order.length; head++) // Kahn: order hace de cola
    for (const [v] of adj[order[head]]) if (--indeg[v] === 0) order.push(v);
  const ways = new Array(n).fill(0), longest = new Array(n).fill(null);
  ways[s] = 1;
  longest[s] = 0;
  for (const u of order) {
    if (longest[u] === null) continue;
    for (const [v, w] of adj[u]) {
      ways[v] = (ways[v] + ways[u]) % MOD;
      longest[v] = longest[v] === null ? longest[u] + w : Math.max(longest[v], longest[u] + w);
    }
  }
  return [ways, longest];
}
```

---

## 🧱 Bloque 14 — Grafos: recorridos

### `14/01` — Representaciones

De [`14/01` — Representaciones y su coste, §3](../14-grafos-recorridos/01-representaciones.md#3--representaciones).

```javascript
// Lee n, m y m aristas no dirigidas «u v w» (desde 1) en listas de adyacencia desde 0: adj[u] = [[v, w], …].
function readGraph(text) {
  const data = text.split(/\s+/).filter(Boolean).map(Number);
  let pos = 0;
  const n = data[pos++], m = data[pos++];
  const adj = Array.from({ length: n }, () => []);
  for (let i = 0; i < m; i++) {
    const u = data[pos++] - 1, v = data[pos++] - 1, w = data[pos++];
    adj[u].push([v, w]);
    adj[v].push([u, w]);
  }
  return [n, adj];
}
// Uso: const [n, adj] = readGraph(require("fs").readFileSync(0, "utf8"));
```

### `14/02` — BFS

De [`14/02` — BFS, §3](../14-grafos-recorridos/02-bfs.md#3--bfs).

```javascript
// Distancias desde las fuentes (−1 = inalcanzable) y el arreglo de padres. Θ(V + E).
function bfs(adj, sources) {
  const n = adj.length, dist = new Array(n).fill(-1), parent = new Array(n).fill(-1);
  const queue = [...sources]; // cola: arreglo con índice de cabeza (shift() es O(n))
  for (const s of sources) dist[s] = 0;
  for (let head = 0; head < queue.length; head++) {
    const u = queue[head];
    for (const v of adj[u]) {
      if (dist[v] === -1) { // se marca al encolar, no al sacar
        dist[v] = dist[u] + 1;
        parent[v] = u;
        queue.push(v);
      }
    }
  }
  return [dist, parent];
}
```

### `14/02` — Multifuente y rejillas

De [`14/02` — BFS, §4](../14-grafos-recorridos/02-bfs.md#4--multifuente-y-rejillas).

```javascript
// Distancia de cada casilla a la fuente más cercana; −1 = pared o inalcanzable.
function gridBFS(g, sources) {
  const R = g.length, C = g[0].length;
  const dist = Array.from({ length: R }, () => new Array(C).fill(-1));
  const queue = sources.map(([r, c]) => [r, c]);
  for (const [r, c] of sources) dist[r][c] = 0;
  for (let head = 0; head < queue.length; head++) {
    const [r, c] = queue[head];
    for (const [r2, c2] of [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]) {
      if (r2 >= 0 && r2 < R && c2 >= 0 && c2 < C && g[r2][c2] !== "#" && dist[r2][c2] === -1) {
        dist[r2][c2] = dist[r][c] + 1;
        queue.push([r2, c2]);
      }
    }
  }
  return dist;
}
```

### `14/02` — 0-1 BFS

De [`14/02` — BFS, §5](../14-grafos-recorridos/02-bfs.md#5--0-1-bfs).

```javascript
// 0-1 BFS con el Deque de 06/01: adj[u] = [[v, w], …] con w en {0, 1}. Θ(V + E).
function bfs01(adj, s) {
  const dist = new Array(adj.length).fill(Infinity);
  dist[s] = 0;
  const dq = new Deque();
  dq.pushBack(s);
  while (dq.length) {
    const u = dq.popFront();
    for (const [v, w] of adj[u]) {
      if (dist[u] + w < dist[v]) {
        dist[v] = dist[u] + w;
        if (w === 0) dq.pushFront(v); // peso 0: misma distancia, delante
        else dq.pushBack(v);
      }
    }
  }
  return dist;
}
```

### `14/02` — Estados compuestos

De [`14/02` — BFS, §6](../14-grafos-recorridos/02-bfs.md#6--estados-compuestos).

```javascript
// Pasos mínimos de (sr, sc) a 'T' atravesando hasta maxWalls muros '#'. Estado (r, c, k); -1 si no se llega.
function bfsWithState(g, sr, sc, maxWalls) {
  const R = g.length, C = g[0].length, K = maxWalls + 1;
  const id = (r, c, k) => (r * C + c) * K + k; // el estado aplanado: un Int32Array, no un Map de cadenas
  const dist = new Int32Array(R * C * K).fill(-1);
  dist[id(sr, sc, 0)] = 0;
  const queue = [[sr, sc, 0]];
  for (let head = 0; head < queue.length; head++) {
    const [r, c, k] = queue[head];
    if (g[r][c] === "T") return dist[id(r, c, k)];
    for (const [r2, c2] of [[r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]]) {
      if (r2 < 0 || r2 >= R || c2 < 0 || c2 >= C) continue;
      const k2 = k + (g[r2][c2] === "#" ? 1 : 0);
      if (k2 <= maxWalls && dist[id(r2, c2, k2)] === -1) {
        dist[id(r2, c2, k2)] = dist[id(r, c, k)] + 1;
        queue.push([r2, c2, k2]);
      }
    }
  }
  return -1;
}
```

### `14/03` — DFS

De [`14/03` — DFS, §3](../14-grafos-recorridos/03-dfs.md#3--dfs).

```javascript
// DFS iterativo de todo el grafo con tiempos de entrada y salida; tin[v] = 0 marca «blanco».
// Iterativo a propósito: la recursión de Node se agota hacia los diez mil niveles.
function dfsAll(adj) {
  const n = adj.length, tin = new Array(n).fill(0), tout = new Array(n).fill(0);
  const parent = new Array(n).fill(-1), it = new Array(n).fill(0); // it: por dónde va cada lista
  let timer = 0;
  for (let s = 0; s < n; s++) {
    if (tin[s]) continue;
    tin[s] = ++timer;
    const stack = [s];
    while (stack.length) {
      const u = stack[stack.length - 1];
      if (it[u] < adj[u].length) {
        const v = adj[u][it[u]++];
        if (!tin[v]) {
          parent[v] = u;
          tin[v] = ++timer;
          stack.push(v);
        }
      } else {
        tout[u] = ++timer;
        stack.pop();
      }
    }
  }
  return [tin, tout, parent];
}
```

### `14/03` — Componentes

De [`14/03` — DFS, §4](../14-grafos-recorridos/03-dfs.md#4--componentes).

```javascript
// [etiqueta de componente por vértice, número de componentes].
function components(adj) {
  const comp = new Array(adj.length).fill(-1);
  let c = 0;
  for (let s = 0; s < adj.length; s++) {
    if (comp[s] !== -1) continue;
    comp[s] = c;
    const stack = [s];
    while (stack.length) {
      const u = stack.pop();
      for (const v of adj[u]) {
        if (comp[v] === -1) {
          comp[v] = c;
          stack.push(v);
        }
      }
    }
    c++;
  }
  return [comp, c];
}
```

### `14/03` — Ciclos

De [`14/03` — DFS, §5](../14-grafos-recorridos/03-dfs.md#5--ciclos).

```javascript
// Tres colores, iterativo: true si hay una arista a un vértice gris (en la pila).
function hasDirectedCycle(adj) {
  const n = adj.length, color = new Array(n).fill(0), it = new Array(n).fill(0); // 0 blanco, 1 gris, 2 negro
  for (let s = 0; s < n; s++) {
    if (color[s]) continue;
    color[s] = 1;
    const stack = [s];
    while (stack.length) {
      const u = stack[stack.length - 1];
      if (it[u] < adj[u].length) {
        const v = adj[u][it[u]++];
        if (color[v] === 1) return true;
        if (color[v] === 0) {
          color[v] = 1;
          stack.push(v);
        }
      } else {
        color[u] = 2;
        stack.pop();
      }
    }
  }
  return false;
}
```

### `14/03` — Bipartición

De [`14/03` — DFS, §6](../14-grafos-recorridos/03-dfs.md#6--bipartición).

```javascript
// Colores 0/1 por vértice, o null si hay un ciclo impar.
function bipartite(adj) {
  const color = new Array(adj.length).fill(-1);
  for (let s = 0; s < adj.length; s++) {
    if (color[s] !== -1) continue;
    color[s] = 0;
    const stack = [s];
    while (stack.length) {
      const u = stack.pop();
      for (const v of adj[u]) {
        if (color[v] === -1) {
          color[v] = color[u] ^ 1;
          stack.push(v);
        } else if (color[v] === color[u]) return null;
      }
    }
  }
  return color;
}
```

### `14/04` — Kahn

De [`14/04` — Orden topológico y DP sobre DAG, §3](../14-grafos-recorridos/04-orden-topologico.md#3--kahn).

```javascript
// Orden topológico por Kahn, o null si hay ciclo. Θ(V + E).
function kahn(adj) {
  const n = adj.length, indeg = new Array(n).fill(0);
  for (const out of adj) for (const v of out) indeg[v]++;
  const order = [];
  for (let v = 0; v < n; v++) if (indeg[v] === 0) order.push(v);
  for (let head = 0; head < order.length; head++) // order hace de cola
    for (const v of adj[order[head]]) if (--indeg[v] === 0) order.push(v);
  return order.length === n ? order : null; // si faltan, hay ciclo
}
```

### `14/04` — Por DFS

De [`14/04` — Orden topológico y DP sobre DAG, §4](../14-grafos-recorridos/04-orden-topologico.md#4--por-dfs).

```javascript
// Postorden invertido, iterativo; null si hay ciclo. Θ(V + E).
function topoDFS(adj) {
  const n = adj.length, color = new Array(n).fill(0), it = new Array(n).fill(0), post = [];
  for (let s = 0; s < n; s++) {
    if (color[s]) continue;
    color[s] = 1;
    const stack = [s];
    while (stack.length) {
      const u = stack[stack.length - 1];
      if (it[u] < adj[u].length) {
        const v = adj[u][it[u]++];
        if (color[v] === 1) return null;
        if (color[v] === 0) {
          color[v] = 1;
          stack.push(v);
        }
      } else {
        color[u] = 2;
        stack.pop();
        post.push(u);
      }
    }
  }
  return post.reverse();
}
```

---

## 🧱 Bloque 15 — Grafos con pesos y flujos

### `15/01` — Dijkstra con montículo

De [`15/01` — Dijkstra, §3](../15-grafos-pesos-y-flujos/01-dijkstra.md#3--dijkstra-con-montículo).

```javascript
// Dijkstra con el Heap de 08/01; adj[u] = [[v, w], …] con w >= 0. [distancias (Infinity =
// inalcanzable), padres]. O((V + E) log V).
function dijkstra(adj, s) {
  const n = adj.length, dist = new Array(n).fill(Infinity), parent = new Array(n).fill(-1);
  const pq = new Heap((x, y) => x[0] < y[0]); // [distancia, vértice]
  dist[s] = 0;
  pq.push([0, s]);
  while (pq.size) {
    const [d, u] = pq.pop();
    if (d > dist[u]) continue; // entrada vieja: el vértice ya salió con una distancia menor
    for (const [v, w] of adj[u]) {
      const nd = d + w;
      if (nd < dist[v]) {
        dist[v] = nd;
        parent[v] = u;
        pq.push([nd, v]);
      }
    }
  }
  return [dist, parent];
}
```

### `15/01` — Dijkstra sobre estados

De [`15/01` — Dijkstra, §4](../15-grafos-pesos-y-flujos/01-dijkstra.md#4--dijkstra-sobre-estados).

```javascript
// Distancia mínima desde s usando hasta K vales (cada vale deja una arista a coste 0); estado
// (vértice, vales usados). Con el Heap de 08/01.
function dijkstraVouchers(adj, s, K) {
  const n = adj.length, dist = Array.from({ length: n }, () => new Array(K + 1).fill(Infinity));
  const pq = new Heap((x, y) => x[0] < y[0]); // [distancia, vértice, vales]
  dist[s][0] = 0;
  pq.push([0, s, 0]);
  while (pq.size) {
    const [d, u, k] = pq.pop();
    if (d > dist[u][k]) continue;
    for (const [v, w] of adj[u]) {
      if (d + w < dist[v][k]) { // pagando
        dist[v][k] = d + w;
        pq.push([d + w, v, k]);
      }
      if (k < K && d < dist[v][k + 1]) { // con un vale
        dist[v][k + 1] = d;
        pq.push([d, v, k + 1]);
      }
    }
  }
  return dist.map((row) => Math.min(...row));
}
```

### `15/02` — Bellman-Ford

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §3](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#3--bellman-ford).

```javascript
// edges = [[u, v, w], …]. [distancias desde s, ¿hay un ciclo negativo alcanzable?]. O(V · E).
function bellmanFord(n, edges, s) {
  const dist = new Array(n).fill(Infinity);
  dist[s] = 0;
  for (let round = 0; round < n; round++) {
    let changed = false;
    for (const [u, v, w] of edges) {
      if (dist[u] + w < dist[v]) { // Infinity + w sigue siendo Infinity: no hace falta comprobarlo
        dist[v] = dist[u] + w;
        changed = true;
      }
    }
    if (!changed) return [dist, false];
  }
  return [dist, true]; // la ronda n todavía mejoró
}
```

### `15/02` — Floyd-Warshall

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §4](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#4--floyd-warshall).

```javascript
// d: matriz n × n con Infinity sin arista y 0 en la diagonal; se modifica en el sitio. Θ(n³).
function floydWarshall(d) {
  const n = d.length;
  for (let k = 0; k < n; k++) { // k por fuera: es el invariante
    const dk = d[k];
    for (let i = 0; i < n; i++) {
      const dik = d[i][k];
      if (dik === Infinity) continue;
      const di = d[i];
      for (let j = 0; j < n; j++) if (dik + dk[j] < di[j]) di[j] = dik + dk[j];
    }
  }
}
```

### `15/04` — Kruskal

De [`15/04` — Árbol de expansión mínima, §3](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#3--kruskal).

```javascript
// edges = [[w, u, v], …]. Peso del árbol de expansión mínima, o -1 si no es conexo. O(E log E).
function kruskal(n, edges) {
  const parent = Int32Array.from({ length: n }, (_, i) => i), size = new Int32Array(n).fill(1);
  const find = (x) => { // el Union-Find de 08/04, en línea
    while (parent[x] !== x) x = parent[x] = parent[parent[x]];
    return x;
  };
  let total = 0, used = 0;
  for (const [w, u, v] of [...edges].sort((p, q) => p[0] - q[0])) {
    let a = find(u), b = find(v);
    if (a === b) continue; // cerraría un ciclo
    if (size[a] < size[b]) [a, b] = [b, a];
    parent[b] = a;
    size[a] += size[b];
    total += w;
    if (++used === n - 1) break;
  }
  return used === n - 1 || n === 0 ? total : -1;
}
```

### `15/04` — Prim

De [`15/04` — Árbol de expansión mínima, §4](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#4--prim).

```javascript
// Prim con el Heap de 08/01; adj[u] = [[v, w], …]. Peso del árbol de expansión mínima, o -1 si no
// es conexo. O(E log V).
function prim(adj) {
  const n = adj.length, inTree = new Array(n).fill(false);
  const pq = new Heap((x, y) => x[0] < y[0]); // [peso, vértice]
  pq.push([0, 0]);
  let total = 0, taken = 0;
  while (pq.size && taken < n) {
    const [w, u] = pq.pop();
    if (inTree[u]) continue; // entrada vieja
    inTree[u] = true;
    total += w;
    taken++;
    for (const [v, wv] of adj[u]) if (!inTree[v]) pq.push([wv, v]);
  }
  return taken === n ? total : -1;
}
```

---

## 🧱 Bloque 16 — Cadenas

### `16/01` — Inmutabilidad y concatenación

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §3](../16-cadenas/01-cadenas-y-patrones-basicos.md#3--inmutabilidad-y-concatenación).

```javascript
// Las cadenas de JavaScript son inmutables; los motores optimizan s += w con cuerdas (ropes), pero
// el coste no está garantizado. Lo seguro: un arreglo de trozos y un solo join.
function joinWords(words, sep) {
  const parts = [];
  words.forEach((w, i) => {
    if (i) parts.push(sep);
    parts.push(w);
  });
  return parts.join(""); // o directamente words.join(sep)
}
```

### `16/01` — Frecuencias y anagramas

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §4](../16-cadenas/01-cadenas-y-patrones-basicos.md#4--frecuencias-y-anagramas).

```javascript
// Frecuencias de las 26 minúsculas.
function freq(s) {
  const f = new Array(26).fill(0);
  for (let i = 0; i < s.length; i++) f[s.charCodeAt(i) - 97]++;
  return f;
}

const isAnagram = (a, b) => a.length === b.length && freq(a).every((x, i) => x === freq(b)[i]);

// La firma: las letras ordenadas. Dos anagramas tienen la misma; sirve de clave de un Map.
const signature = (s) => [...s].sort().join(""); // sort() sin comparador: por unidades UTF-16, bien aquí
```

### `16/01` — Palíndromos con dos punteros

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §5](../16-cadenas/01-cadenas-y-patrones-basicos.md#5--palíndromos-con-dos-punteros).

```javascript
// Pares simétricos distintos en s[l..r].
function mismatches(s, l, r) {
  let count = 0;
  for (; l < r; l++, r--) if (s[l] !== s[r]) count++;
  return count;
}
```

### `16/02` — Función de prefijo

De [`16/02` — KMP y la función de prefijo, §3](../16-cadenas/02-kmp.md#3--función-de-prefijo).

```javascript
// pi[i] = longitud del borde más largo de s[0..i]. Θ(n).
function prefixFunction(s) {
  const pi = new Int32Array(s.length);
  for (let i = 1; i < s.length; i++) {
    let k = pi[i - 1];
    while (k > 0 && s[i] !== s[k]) k = pi[k - 1]; // el siguiente borde más corto
    if (s[i] === s[k]) k++;
    pi[i] = k;
  }
  return pi;
}
```

### `16/02` — KMP

De [`16/02` — KMP y la función de prefijo, §4](../16-cadenas/02-kmp.md#4--kmp).

```javascript
// Posiciones de inicio de las apariciones (solapadas) de p en t, con prefixFunction de §3. Θ(n + m).
function kmpSearch(t, p) {
  const pi = prefixFunction(p), found = [], m = p.length;
  let k = 0;
  for (let i = 0; i < t.length; i++) {
    while (k > 0 && t[i] !== p[k]) k = pi[k - 1];
    if (t[i] === p[k]) k++;
    if (k === m) {
      found.push(i - m + 1);
      k = pi[k - 1]; // sigue buscando: las apariciones pueden solaparse
    }
  }
  return found;
}
```

---

## 🧱 Bloque 17 — Matemática

### `17/01` — Operaciones y trucos

De [`17/01` — Bits, §3](../17-matematica/01-bits.md#3--operaciones-y-trucos).

```javascript
// Los operadores de bits de JavaScript convierten a entero de 32 bits con signo: valen para x < 2³¹.
// Para 32 bits sin signo, >>> 0; para más, BigInt (1n << 40n).
const getBit = (x, i) => (x >> i) & 1;
const setBit = (x, i) => x | (1 << i);
const clearBit = (x, i) => x & ~(1 << i);
const lowBit = (x) => x & -x;
const isPowerOfTwo = (x) => x > 0 && (x & (x - 1)) === 0;
function popcount(x) { // JavaScript no lo trae: el truco de Hacker's Delight en 32 bits
  x -= (x >>> 1) & 0x55555555;
  x = (x & 0x33333333) + ((x >>> 2) & 0x33333333);
  return (Math.imul((x + (x >>> 4)) & 0x0f0f0f0f, 0x01010101) >>> 24);
}
const lowestIndex = (x) => 31 - Math.clz32(x & -x); // -1 si x === 0
const highestIndex = (x) => 31 - Math.clz32(x); // -1 si x === 0
```

### `17/02` — Euclides

De [`17/02` — Divisibilidad, §3](../17-matematica/02-divisibilidad.md#3--euclides).

```javascript
// Máximo común divisor por Euclides; gcd(0, 0) = 0. Exacto con enteros < 2⁵³; para más, BigInt.
function gcd(a, b) {
  a = Math.abs(a);
  b = Math.abs(b);
  while (b) [a, b] = [b, a % b];
  return a;
}

const lcm = (a, b) => (a / gcd(a, b)) * b; // dividir antes: el producto podría pasar de 2⁵³
```

### `17/02` — Euclides extendido

De [`17/02` — Divisibilidad, §4](../17-matematica/02-divisibilidad.md#4--euclides-extendido).

```javascript
// [g, x, y] con a*x + b*y = g. Iterativo: sin recursión.
function extGcd(a, b) {
  let x0 = 1, y0 = 0, x1 = 0, y1 = 1;
  while (b) {
    const q = Math.floor(a / b); // a, b >= 0: floor y truncar coinciden
    [a, b] = [b, a - q * b];
    [x0, x1] = [x1, x0 - q * x1];
    [y0, y1] = [y1, y0 - q * y1];
  }
  return [a, x0, y0];
}
```

### `17/02` — Diofánticas lineales

De [`17/02` — Divisibilidad, §5](../17-matematica/02-divisibilidad.md#5--diofánticas-lineales).

```javascript
// Soluciones (x, y) enteras con x, y >= 0 de a*x + b*y = c (a, b > 0), con extGcd de §4.
// Math.floor(p / q) es la división hacia −∞ que pide la cuenta (y no p / q | 0, que trunca).
function countNonNegative(a, b, c) {
  const [g, x, y] = extGcd(a, b);
  if (c % g) return 0;
  const x0 = x * (c / g), y0 = y * (c / g), sx = b / g, sy = a / g;
  const lo = -Math.floor(x0 / sx); // ⌈−x0 / sx⌉
  const hi = Math.floor(y0 / sy);
  return Math.max(0, hi - lo + 1);
}
```

### `17/03` — Exponenciación modular

De [`17/03` — Aritmética modular, §3](../17-matematica/03-aritmetica-modular.md#3--exponenciación-modular).

```javascript
// a · b mod m sin BigInt, para m < 2³⁰ (1e9+7 incluido): se parte b en dos mitades de 16 bits para que
// ningún producto intermedio pase de 2⁵³. a * b directo perdería precisión sin avisar.
function mulMod(a, b, m) {
  return ((a * (b >>> 16)) % m * 65536 + a * (b & 65535)) % m;
}

// aᵉ mod m, con 0 <= a < m < 2³⁰ y e >= 0 entero. Θ(log e).
function powMod(a, e, m) {
  let result = 1 % m;
  for (; e > 0; e = Math.floor(e / 2)) { // no e >>= 1: e puede pasar de 2³¹
    if (e % 2 === 1) result = mulMod(result, a, m);
    a = mulMod(a, a, m);
  }
  return result;
}
```

### `17/03` — Inverso modular

De [`17/03` — Aritmética modular, §4](../17-matematica/03-aritmetica-modular.md#4--inverso-modular).

```javascript
// Inverso de a módulo un primo p (Fermat), con powMod de §3.
const invFermat = (a, p) => powMod(a, p - 2, p);

// Inverso de a módulo m con extGcd de 17/02 §4; null si gcd(a, m) !== 1.
function invExt(a, m) {
  const [g, x] = extGcd(((a % m) + m) % m, m);
  return g === 1 ? ((x % m) + m) % m : null;
}

// Los inversos de 1..n módulo un primo p > n (p < 2³⁰), en Θ(n), con mulMod de §3.
function inversesUpTo(n, p) {
  const inv = new Array(n + 1).fill(0);
  if (n >= 1) inv[1] = 1;
  for (let i = 2; i <= n; i++) inv[i] = (p - mulMod(Math.floor(p / i), inv[p % i], p)) % p;
  return inv;
}
```

### `17/04` — Criba de Eratóstenes

De [`17/04` — Primos, §3](../17-matematica/04-primos.md#3--criba-de-eratóstenes).

```javascript
// isPrime[i] (1 o 0) para i en [0, n]: un Uint8Array, un byte por número. Θ(n log log n).
function sieve(n) {
  const isPrime = new Uint8Array(n + 1).fill(1);
  isPrime[0] = 0;
  if (n >= 1) isPrime[1] = 0;
  for (let p = 2; p * p <= n; p++)
    if (isPrime[p]) for (let q = p * p; q <= n; q += p) isPrime[q] = 0; // desde p²
  return isPrime;
}
```

### `17/04` — Criba lineal y menor factor primo

De [`17/04` — Primos, §4](../17-matematica/04-primos.md#4--criba-lineal-y-menor-factor-primo).

```javascript
// [spf, primes]: spf[x] = menor factor primo de x; primes, los primos hasta n. Θ(n).
function linearSieve(n) {
  const spf = new Int32Array(n + 1), primes = [];
  for (let i = 2; i <= n; i++) {
    if (spf[i] === 0) {
      spf[i] = i;
      primes.push(i);
    }
    for (const p of primes) {
      if (p > spf[i] || i * p > n) break;
      spf[i * p] = p; // cada compuesto se tacha una sola vez, por su menor primo
    }
  }
  return [spf, primes];
}

// Factorización de x <= n con la tabla spf: pares [primo, exponente]. O(log x).
function factorize(x, spf) {
  const f = [];
  while (x > 1) {
    const p = spf[x];
    let e = 0;
    while (x % p === 0) { x /= p; e++; }
    f.push([p, e]);
  }
  return f;
}
```

### `17/05` — `nCr` con factoriales

De [`17/05` — Combinatoria, §3](../17-matematica/05-combinatoria.md#3--ncr-con-factoriales).

```javascript
// C(n, k) mod 1e9+7 con factoriales y sus inversos, precalculados hasta n. Usa mulMod y powMod de 17/03 §3.
const MOD = 1_000_000_007;

class Binomial {
  constructor(n) {
    this.fact = new Array(n + 1).fill(1);
    for (let i = 1; i <= n; i++) this.fact[i] = mulMod(this.fact[i - 1], i, MOD);
    this.invFact = new Array(n + 1).fill(1);
    this.invFact[n] = powMod(this.fact[n], MOD - 2, MOD); // un solo inverso, por Fermat
    for (let i = n; i > 0; i--) this.invFact[i - 1] = mulMod(this.invFact[i], i, MOD);
  }
  C(n, k) {
    if (k < 0 || k > n) return 0;
    return mulMod(mulMod(this.fact[n], this.invFact[k], MOD), this.invFact[n - k], MOD);
  }
}
```

---

## 🧱 Bloque 18 — Geometría

### `18/01` — Vectores, punto y cruz

De [`18/01` — Vectores, productos y orientación, §3](../18-geometria/01-vectores-y-orientacion.md#3--vectores-punto-y-cruz).

```javascript
// Vectores como [x, y]. Exactos mientras cada producto quede bajo 2⁵³: coordenadas de hasta ~6·10⁷ en
// valor absoluto. Con 10⁹ la cruz llega a 4·10¹⁸ y hay que pasar a BigInt (1000000000n).
const sub = (a, b) => [a[0] - b[0], a[1] - b[1]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];
const cross = (a, b) => a[0] * b[1] - a[1] * b[0];
```

### `18/01` — Orientación

De [`18/01` — Vectores, productos y orientación, §4](../18-geometria/01-vectores-y-orientacion.md#4--orientación).

```javascript
// +1 si a, b, c giran a la izquierda (antihorario), -1 a la derecha, 0 si están alineados.
const orient = (a, b, c) => Math.sign(cross(sub(b, a), sub(c, a)));

// ¿Está p dentro del triángulo abc o en su borde? Dentro si las tres orientaciones no tienen signos opuestos.
function inTriangle(a, b, c, p) {
  const s = [orient(a, b, p), orient(b, c, p), orient(c, a, p)];
  return !(Math.min(...s) < 0 && Math.max(...s) > 0);
}
```

### `18/01` — Enteros frente a épsilon

De [`18/01` — Vectores, productos y orientación, §5](../18-geometria/01-vectores-y-orientacion.md#5--enteros-frente-a-épsilon).

```javascript
// Signo con tolerancia, cuando las coordenadas son reales: en JavaScript todo número es un double.
const sgn = (v, eps) => (v > eps ? 1 : v < -eps ? -1 : 0);
```

---

## 🧱 Bloque 19 — Aleatorizados y probabilísticos

### `19/04` — Fisher-Yates

De [`19/04` — Muestreo y cadenas de Markov, §3](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#3--fisher-yates).

```javascript
// Barajado uniforme en el sitio: cada una de las n! permutaciones con probabilidad 1/n!. Θ(n).
// JavaScript no trae shuffle; a.sort(() => Math.random() - 0.5) NO es uniforme.
function fisherYates(a, random = Math.random) {
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1)); // j en [0, i], incluido i
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
```

---

## 🧱 Bloque 20 — Ad hoc, constructivos e interactivos

### `20/01` — Invariantes y paridad

De [`20/01` — Ad hoc y simulación, §3](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#3--invariantes-y-paridad).

```javascript
// Paridad de una permutación de 0..n−1: 0 si par, 1 si impar. Hacen falta n − (número de ciclos) intercambios.
function permutationParity(p) {
  const seen = new Uint8Array(p.length);
  let cycles = 0;
  for (let i = 0; i < p.length; i++) {
    if (seen[i]) continue;
    cycles++;
    for (let j = i; !seen[j]; j = p[j]) seen[j] = 1;
  }
  return (p.length - cycles) % 2;
}
```

### `20/01` — Simulación

De [`20/01` — Ad hoc y simulación, §4](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#4--simulación).

```javascript
// Estado tras k aplicaciones de f desde x0, saltando el ciclo en cuanto un estado se repite.
// Los estados son números exactos (< 2⁵³) o cadenas: un Map los compara por valor.
function iterate(x0, k, f) {
  const firstSeen = new Map();
  let x = x0;
  for (let step = 0; step < k; step++) {
    const prev = firstSeen.get(x);
    if (prev !== undefined) { // el estado x ya salió en el paso prev
      const cycle = step - prev;
      for (let r = (k - step) % cycle; r > 0; r--) x = f(x);
      return x;
    }
    firstSeen.set(x, step);
    x = f(x);
  }
  return x;
}
```

---

## 🧱 Bloque 22 — Teoría de la computación (opcional)

### `22/03` — La máquina de Turing y su simulación

De [`22/03` — Máquinas de Turing y decidibilidad, §3](../22-teoria-de-la-computacion/03-maquinas-de-turing-y-decidibilidad.md#3--la-máquina-de-turing-y-su-simulación).

```javascript
// Simula una MT de una cinta desde el estado 0, con la cinta como dos pilas. delta es un Map con
// claves `${estado},${símbolo}` y valores [escribe, mueve (−1 o +1), siguiente].
// Devuelve [estado final (−1 si agotó limit), pasos, cinta].
function runTM(delta, halt, tape, blank, limit) {
  const left = [], right = [...tape].reverse(); // la cima de cada pila toca la cabeza
  let cur = right.length ? right.pop() : blank, q = 0, steps = 0;
  for (; q !== halt; steps++) {
    if (steps === limit) return [-1, steps, null];
    const rule = delta.get(`${q},${cur}`);
    if (rule === undefined) break; // sin transición: se detiene
    const [write, move, next] = rule;
    const [from, to] = move > 0 ? [right, left] : [left, right];
    to.push(write); // la celda escrita queda del lado contrario al movimiento
    cur = from.length ? from.pop() : blank; // pila vacía: cinta en blanco
    q = next;
  }
  return [q, steps, left.join("") + cur + right.reverse().join("")];
}
```

### `22/04` — P y NP por certificados

De [`22/04` — P, NP y reducciones, §3](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#3--p-y-np-por-certificados).

```javascript
// Verificador de NP para la cobertura de vértices: ¿cover es una cobertura de tamaño <= k? O(n + m).
function verifyCover(n, edges, cover, k) {
  if (cover.length > k) return false;
  const inside = new Uint8Array(n);
  for (const v of cover) inside[v] = 1;
  return edges.every(([u, v]) => inside[u] || inside[v]); // ninguna arista sin cubrir
}
```

### `22/05` — Qué hacer con un NP-difícil

De [`22/05` — NP-completitud, §6](../22-teoria-de-la-computacion/05-np-completitud.md#6--qué-hacer-con-un-np-difícil).

```javascript
// ¿Hay ciclo hamiltoniano? adj[v] = máscara de vecinos de v (n <= 30: los bits son de 32).
// reach[mask] = vértices donde puede acabar un camino que empieza en 0 y visita exactamente mask.
// O(2ⁿ · n) tiempo, 2ⁿ enteros; en la práctica, n <= 22 o 23.
function hamiltonianCycle(adj) {
  const n = adj.length;
  if (n < 3) return false;
  const reach = new Int32Array(1 << n);
  reach[1] = 1; // el camino «0» termina en 0
  for (let mask = 3; mask < 1 << n; mask += 2) { // máscaras con el 0 y algo más
    let r = 0;
    for (let w = 1; w < n; w++) if ((mask >> w) & 1 && reach[mask ^ (1 << w)] & adj[w]) r |= 1 << w;
    reach[mask] = r;
  }
  return (reach[(1 << n) - 1] & adj[0]) !== 0; // algún final vuelve a 0
}
```
