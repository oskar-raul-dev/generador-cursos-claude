# 04 — Cuaderno de Go

> **Opcional.** Las plantillas de nivel A del corpus en Go, sin explicación y listas para copiar. **Son las
> únicas plantillas completas en Go del corpus**: los capítulos usan C++, Java y Python, y este cuaderno las
> traduce con los modismos de Go —slices con índice de cabeza como cola, genéricos para el montículo y el
> deque, `math/bits` para los bits y el producto modular de 128 bits—. Cada una lleva el enlace a la sección
> del capítulo donde están su invariante, su coste y sus trampas. Escritas para Go 1.26, la versión de
> HackerRank; las que necesitan el montículo o el deque usan los de `08/01` y `06/01` de este mismo cuaderno.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#-bloque-01--oficio-del-competidor) · [02](#-bloque-02--análisis) · [04](#-bloque-04--secuencias) · [05](#-bloque-05--orden-y-búsqueda) · [06](#-bloque-06--lineales-y-hashing) · [07](#-bloque-07--árboles) · [08](#-bloque-08--heaps-y-union-find) · [09](#-bloque-09--consultas-sobre-rangos) · [10](#-bloque-10--búsqueda-completa-y-divide-y-vencerás) · [11](#-bloque-11--voraces) · [12](#-bloque-12--dp-clásica) · [13](#-bloque-13--dp-avanzada) · [14](#-bloque-14--grafos-recorridos) · [15](#-bloque-15--grafos-con-pesos-y-flujos) · [16](#-bloque-16--cadenas) · [17](#-bloque-17--matemática) · [18](#-bloque-18--geometría) · [19](#-bloque-19--aleatorizados-y-probabilísticos) · [20](#-bloque-20--ad-hoc-constructivos-e-interactivos) · [22](#-bloque-22--teoría-de-la-computación-opcional)

---

## 🧱 Bloque 01 — Oficio del competidor

### `01/03` — La plantilla

De [`01/03` — Entrada, salida y la plantilla en C++, Java y Python, §6](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md#6--la-plantilla).

```go
package main

import (
	"bufio"
	"os"
	"strconv"
)

func main() {
	in := bufio.NewReaderSize(os.Stdin, 1<<20)
	out := bufio.NewWriterSize(os.Stdout, 1<<20)
	defer out.Flush() // sin Flush, la salida se queda en el búfer y se pierde

	n := readInt(in)
	a := make([]int64, n)
	for i := range a {
		a[i] = int64(readInt(in))
	}

	var total int64 // aquí va la solución
	for _, x := range a {
		total += x
	}

	out.WriteString(strconv.FormatInt(total, 10))
	out.WriteByte('\n')
}

// readInt lee un entero con signo saltando blancos; mucho más rápido que fmt.Fscan.
func readInt(in *bufio.Reader) int {
	c, _ := in.ReadByte()
	for c == ' ' || c == '\n' || c == '\r' || c == '\t' {
		c, _ = in.ReadByte()
	}
	neg := c == '-'
	if neg {
		c, _ = in.ReadByte()
	}
	n := 0
	for c >= '0' && c <= '9' {
		n = n*10 + int(c-'0')
		c, _ = in.ReadByte()
	}
	if neg {
		return -n
	}
	return n
}
```

### `01/05` — El *stress test*

De [`01/05` — Probar sin IDE: casos borde, depuración y *stress test*, §4](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md#4--el-stress-test).

```go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"slices"
	"strconv"
	"strings"
)

// run ejecuta un programa con la entrada dada y devuelve su salida; un RE detiene el arnés.
func run(input string, name string, args ...string) string {
	cmd := exec.Command(name, args...)
	cmd.Stdin = strings.NewReader(input)
	out, err := cmd.Output()
	if err != nil {
		fmt.Println("falló", name, args, err)
		os.Exit(1)
	}
	return string(out)
}

// Compara ./sol contra ./brute con entradas de ./gen hasta la primera diferencia.
func main() {
	for seed := 1; seed <= 10000; seed++ {
		data := run("", "./gen", strconv.Itoa(seed))
		mine := strings.Fields(run(data, "./sol")) // por tokens, como el juez
		oracle := strings.Fields(run(data, "./brute"))
		if !slices.Equal(mine, oracle) {
			fmt.Printf("Diferencia con la semilla %d:\n%s", seed, data)
			fmt.Println("sol:  ", strings.Join(mine, " "))
			fmt.Println("brute:", strings.Join(oracle, " "))
			os.Exit(1)
		}
	}
	fmt.Println("10 000 casos sin diferencias")
}
```

```go
package main

import (
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
)

// Generador de «un arreglo de enteros» para el stress test: go run gen.go <semilla>
func main() {
	seed, _ := strconv.ParseInt(os.Args[1], 10, 64) // la semilla la pasa el arnés
	rng := rand.New(rand.NewSource(seed))           // misma semilla, misma entrada
	n := 1 + rng.Intn(8)                            // de 1 a 8
	parts := make([]string, n)
	for i := range parts {
		parts[i] = strconv.Itoa(rng.Intn(11) - 5) // de −5 a 5
	}
	fmt.Printf("%d\n%s\n", n, strings.Join(parts, " "))
}
```

---

## 🧱 Bloque 02 — Análisis

### `02/03` — El método agregado

De [`02/03` — Análisis amortizado, §3](../02-analisis/03-analisis-amortizado.md#3--el-método-agregado).

```go
// Arreglo dinámico de int: Push O(1) amortizado, Get O(1) en el caso peor.
// (Un slice con append ya es esto; aquí está escrito a mano para ver la duplicación.)
type IntArrayList struct {
	data []int // len(data) es la capacidad; size, los usados
	size int
}

func (l *IntArrayList) Push(x int) {
	if l.size == len(l.data) {
		bigger := make([]int, max(1, 2*len(l.data))) // duplica: copia size elementos
		copy(bigger, l.data)
		l.data = bigger
	}
	l.data[l.size] = x
	l.size++
}

func (l *IntArrayList) Get(i int) int {
	if i < 0 || i >= l.size {
		panic("índice fuera de rango")
	}
	return l.data[i]
}

func (l *IntArrayList) Size() int { return l.size }
```

### `02/04` — Invariante de bucle

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §3](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#3--invariante-de-bucle).

```go
// Primer índice i en [0, n] con a[i] >= x (lower bound). Pre: a ordenado de forma no decreciente.
func lowerBound(a []int, x int) int {
	lo, hi := 0, len(a)
	// Invariante: a[0..lo) < x  y  a[hi..n) >= x.  Cota: hi - lo, que baja en cada vuelta.
	for lo < hi {
		mid := lo + (hi-lo)/2 // lo <= mid < hi
		if a[mid] < x {
			lo = mid + 1 // a[0..mid] < x: el invariante se mantiene
		} else {
			hi = mid // a[mid..n) >= x: el invariante se mantiene
		}
	}
	return lo // lo == hi: la frontera exacta
}
```

### `02/04` — Argumento de intercambio

De [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio, §5](../02-analisis/04-correccion-invariantes-induccion-intercambio.md#5--argumento-de-intercambio).

```go
import (
	"math"
	"sort"
)

// Máximo número de intervalos [s, f) disjuntos. Θ(n log n) por la ordenación.
func maxDisjoint(intervals [][2]int) int {
	byEnd := append([][2]int(nil), intervals...) // no se toca la entrada
	sort.Slice(byEnd, func(i, j int) bool { return byEnd[i][1] < byEnd[j][1] })
	count, lastEnd := 0, math.MinInt // final del último elegido
	for _, iv := range byEnd {
		if iv[0] >= lastEnd { // semiabierto: empezar justo al terminar vale
			count++
			lastEnd = iv[1]
		}
	}
	return count
}
```

### `02/06` — TDA, contrato e invariante de representación

De [`02/06` — Tipos abstractos de datos, §3](../02-analisis/06-tipos-abstractos-de-datos.md#3--tda-contrato-e-invariante-de-representación).

```go
import "errors"

// El contrato: una cola de enteros. Dequeue y Peek devuelven error si está vacía.
type IntQueue interface {
	Enqueue(x int)
	Dequeue() (int, error)
	Peek() (int, error)
	IsEmpty() bool
	Size() int
}

var ErrEmpty = errors.New("cola vacía")

// Arreglo circular. Invariante: 0 <= size <= len(data), 0 <= head < len(data);
// los elementos son data[(head + i) % len(data)] para i en [0, size).
type RingBufferQueue struct {
	data       []int
	head, size int
}

func NewRingBufferQueue() *RingBufferQueue { return &RingBufferQueue{data: make([]int, 4)} }

func (q *RingBufferQueue) Enqueue(x int) {
	if q.size == len(q.data) {
		q.grow()
	}
	q.data[(q.head+q.size)%len(q.data)] = x
	q.size++
}

func (q *RingBufferQueue) Dequeue() (int, error) {
	x, err := q.Peek()
	if err != nil {
		return 0, err
	}
	q.head = (q.head + 1) % len(q.data)
	q.size--
	return x, nil
}

func (q *RingBufferQueue) Peek() (int, error) {
	if q.size == 0 {
		return 0, ErrEmpty
	}
	return q.data[q.head], nil
}

func (q *RingBufferQueue) IsEmpty() bool { return q.size == 0 }
func (q *RingBufferQueue) Size() int     { return q.size }

func (q *RingBufferQueue) grow() { // copia en orden lógico: la cabeza vuelve a 0
	bigger := make([]int, 2*len(q.data))
	for i := 0; i < q.size; i++ {
		bigger[i] = q.data[(q.head+i)%len(q.data)]
	}
	q.data, q.head = bigger, 0
}

// Lista enlazada simple. Invariante: size nodos desde head; tail es el último (o nil si size == 0).
type node struct {
	value int
	next  *node
}

type LinkedQueue struct {
	head, tail *node
	size       int
}

func (q *LinkedQueue) Enqueue(x int) {
	n := &node{value: x}
	if q.tail == nil {
		q.head = n
	} else {
		q.tail.next = n
	}
	q.tail = n
	q.size++
}

func (q *LinkedQueue) Dequeue() (int, error) {
	x, err := q.Peek()
	if err != nil {
		return 0, err
	}
	q.head = q.head.next
	if q.head == nil {
		q.tail = nil // la cola quedó vacía: tail también
	}
	q.size--
	return x, nil
}

func (q *LinkedQueue) Peek() (int, error) {
	if q.size == 0 {
		return 0, ErrEmpty
	}
	return q.head.value, nil
}

func (q *LinkedQueue) IsEmpty() bool { return q.size == 0 }
func (q *LinkedQueue) Size() int     { return q.size }

// Las dos cumplen el contrato; el compilador lo comprueba aquí.
var _ IntQueue = (*RingBufferQueue)(nil)
var _ IntQueue = (*LinkedQueue)(nil)
```

---

## 🧱 Bloque 04 — Secuencias

### `04/01` — Prefijos 1D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §3](../04-secuencias/01-prefijos-y-diferencias.md#3--prefijos-1d).

```go
// buildPrefix: p[k] = a[0] + ... + a[k-1]; la suma de a[l..r] es p[r+1] - p[l]. O(n).
func buildPrefix(a []int64) []int64 {
	p := make([]int64, len(a)+1)
	for i, x := range a {
		p[i+1] = p[i] + x
	}
	return p
}

func rangeSum(p []int64, l, r int) int64 { return p[r+1] - p[l] } // l y r incluidos
```

### `04/01` — Diferencias 1D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §4](../04-secuencias/01-prefijos-y-diferencias.md#4--diferencias-1d).

```go
// RangeAdd suma v a [l, r] en O(1); Finish reconstruye el arreglo con prefijos.
type RangeAdd struct{ d []int64 }

func NewRangeAdd(n int) *RangeAdd { return &RangeAdd{d: make([]int64, n+1)} }

func (ra *RangeAdd) Add(l, r int, v int64) {
	ra.d[l] += v
	ra.d[r+1] -= v
}

func (ra *RangeAdd) Finish() []int64 {
	out := make([]int64, len(ra.d)-1)
	var run int64
	for i := range out {
		run += ra.d[i] // prefijos de las diferencias
		out[i] = run
	}
	return out
}
```

### `04/01` — Prefijos y diferencias 2D

De [`04/01` — Sumas de prefijos y arreglos de diferencias, §5](../04-secuencias/01-prefijos-y-diferencias.md#5--prefijos-y-diferencias-2d).

```go
// Prefix2D: s[i][j] = suma de m[0..i-1][0..j-1]; consulta inclusiva de (r1, c1) a (r2, c2).
type Prefix2D struct{ s [][]int64 }

func NewPrefix2D(m [][]int64) *Prefix2D {
	rows, cols := len(m), 0
	if rows > 0 {
		cols = len(m[0])
	}
	s := make([][]int64, rows+1)
	for i := range s {
		s[i] = make([]int64, cols+1)
	}
	for i := 0; i < rows; i++ {
		for j := 0; j < cols; j++ {
			s[i+1][j+1] = m[i][j] + s[i][j+1] + s[i+1][j] - s[i][j]
		}
	}
	return &Prefix2D{s}
}

func (p *Prefix2D) Query(r1, c1, r2, c2 int) int64 {
	s := p.s
	return s[r2+1][c2+1] - s[r1][c2+1] - s[r2+1][c1] + s[r1][c1]
}
```

### `04/02` — Dos punteros

De [`04/02` — Dos punteros y ventana deslizante, §3](../04-secuencias/02-dos-punteros-y-ventana.md#3--dos-punteros).

```go
// Número de pares i < j con a[i] + a[j] <= k. Pre: a ordenado. O(n).
func countPairsAtMost(a []int64, k int64) int64 {
	var count int64
	l, r := 0, len(a)-1
	for l < r {
		if a[l]+a[r] <= k {
			count += int64(r - l) // a[l] con todos los de (l, r]
			l++
		} else {
			r--
		}
	}
	return count
}
```

### `04/02` — Ventana variable

De [`04/02` — Dos punteros y ventana deslizante, §4](../04-secuencias/02-dos-punteros-y-ventana.md#4--ventana-variable).

```go
// Longitud del subarreglo más largo con suma <= s. Pre: a[i] >= 0. O(n).
func longestAtMost(a []int64, s int64) int {
	var total int64
	best, l := 0, 0
	for r, x := range a {
		total += x
		for total > s {
			total -= a[l]
			l++
		}
		best = max(best, r-l+1)
	}
	return best
}
```

### `04/02` — Ventana fija

De [`04/02` — Dos punteros y ventana deslizante, §5](../04-secuencias/02-dos-punteros-y-ventana.md#5--ventana-fija).

```go
// Máxima suma de k elementos consecutivos. Pre: 1 <= k <= n. O(n).
func maxWindowSum(a []int64, k int) int64 {
	var total int64
	for _, x := range a[:k] {
		total += x
	}
	best := total
	for i := k; i < len(a); i++ {
		total += a[i] - a[i-k]
		best = max(best, total)
	}
	return best
}
```

### `04/03` — Kadane

De [`04/03` — Kadane y subarreglos, §3](../04-secuencias/03-kadane-y-subarreglos.md#3--kadane).

```go
// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
func maxSubarraySum(a []int64) int64 {
	best, cur := a[0], int64(0)
	for _, x := range a {
		cur = max(x, cur+x)
		best = max(best, cur)
	}
	return best
}
```

### `04/03` — La variante circular

De [`04/03` — Kadane y subarreglos, §4](../04-secuencias/03-kadane-y-subarreglos.md#4--la-variante-circular).

```go
// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
func maxCircularSum(a []int64) int64 {
	var total, curMax, curMin int64
	best, worst := a[0], a[0]
	for _, x := range a {
		total += x
		curMax = max(x, curMax+x)
		best = max(best, curMax)
		curMin = min(x, curMin+x)
		worst = min(worst, curMin)
	}
	if best < 0 { // todos negativos: dar la vuelta dejaría el subarreglo vacío
		return best
	}
	return max(best, total-worst)
}
```

### `04/03` — Contar subarreglos con prefijos y *hash*

De [`04/03` — Kadane y subarreglos, §5](../04-secuencias/03-kadane-y-subarreglos.md#5--contar-subarreglos-con-prefijos-y-hash).

```go
// Número de subarreglos con suma exactamente k. O(n) esperado.
func countSubarraysWithSum(a []int64, k int64) int64 {
	seen := map[int64]int64{0: 1} // el prefijo vacío
	var prefix, count int64
	for _, x := range a {
		prefix += x
		count += seen[prefix-k] // una clave ausente vale 0
		seen[prefix]++
	}
	return count
}
```

### `04/04` — Compresión de coordenadas

De [`04/04` — Compresión de coordenadas y barrido de eventos, §3](../04-secuencias/04-compresion-y-barrido.md#3--compresión-de-coordenadas).

```go
import "sort"

// compress devuelve el rango de cada valor en [0, k) y la lista ordenada de distintos. O(n log n).
func compress(a []int) ([]int, []int) {
	distinct := append([]int(nil), a...)
	sort.Ints(distinct)
	k := 0
	for i, v := range distinct { // quita repetidos en el sitio
		if i == 0 || v != distinct[k-1] {
			distinct[k] = v
			k++
		}
	}
	distinct = distinct[:k]
	ranks := make([]int, len(a))
	for i, x := range a {
		ranks[i] = sort.SearchInts(distinct, x) // binaria: sin mapa
	}
	return ranks, distinct
}
```

### `04/04` — Barrido de eventos

De [`04/04` — Compresión de coordenadas y barrido de eventos, §4](../04-secuencias/04-compresion-y-barrido.md#4--barrido-de-eventos).

```go
import "sort"

// Máximo de intervalos [s, e) que se solapan en algún instante. O(n log n).
func maxOverlap(intervals [][2]int) int {
	events := make([][2]int, 0, 2*len(intervals))
	for _, iv := range intervals {
		events = append(events, [2]int{iv[0], 1}, [2]int{iv[1], -1})
	}
	sort.Slice(events, func(i, j int) bool { // en empate, -1 antes que 1: cierra primero
		if events[i][0] != events[j][0] {
			return events[i][0] < events[j][0]
		}
		return events[i][1] < events[j][1]
	})
	open, best := 0, 0
	for _, e := range events {
		open += e[1]
		best = max(best, open)
	}
	return best
}
```

### `04/04` — Unión de intervalos

De [`04/04` — Compresión de coordenadas y barrido de eventos, §5](../04-secuencias/04-compresion-y-barrido.md#5--unión-de-intervalos).

```go
import "sort"

// Une intervalos [s, e) que se solapan; devuelve los bloques disjuntos ordenados. O(n log n).
func mergeIntervals(v [][2]int) [][2]int {
	sorted := append([][2]int(nil), v...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i][0] < sorted[j][0] })
	var out [][2]int
	for _, iv := range sorted {
		if n := len(out); n > 0 && iv[0] < out[n-1][1] {
			out[n-1][1] = max(out[n-1][1], iv[1])
		} else {
			out = append(out, iv)
		}
	}
	return out
}
```

### `04/05` — Recorridos, rotación y espiral

De [`04/05` — Matrices, §3](../04-secuencias/05-matrices.md#3--recorridos-rotación-y-espiral).

```go
var dirs = [4][2]int{{-1, 0}, {1, 0}, {0, -1}, {0, 1}} // arriba, abajo, izquierda, derecha

// neighbors devuelve las casillas vecinas de (r, c) dentro de una rejilla rows × cols.
func neighbors(r, c, rows, cols int) [][2]int {
	var out [][2]int
	for _, d := range dirs {
		nr, nc := r+d[0], c+d[1]
		if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
			out = append(out, [2]int{nr, nc})
		}
	}
	return out
}

// rotateClockwise gira una matriz n × n 90° en sentido horario, en el sitio.
func rotateClockwise(m [][]int) {
	n := len(m)
	for i := 0; i < n; i++ { // trasponer
		for j := i + 1; j < n; j++ {
			m[i][j], m[j][i] = m[j][i], m[i][j]
		}
	}
	for _, row := range m { // invertir cada fila
		for i, j := 0, n-1; i < j; i, j = i+1, j-1 {
			row[i], row[j] = row[j], row[i]
		}
	}
}

// spiral recorre la matriz en espiral desde la esquina superior izquierda.
func spiral(m [][]int) []int {
	var out []int
	top, bottom, left, right := 0, len(m)-1, 0, len(m[0])-1
	for top <= bottom && left <= right {
		for j := left; j <= right; j++ {
			out = append(out, m[top][j])
		}
		top++
		for i := top; i <= bottom; i++ {
			out = append(out, m[i][right])
		}
		right--
		if top <= bottom {
			for j := right; j >= left; j-- {
				out = append(out, m[bottom][j])
			}
			bottom--
		}
		if left <= right {
			for i := bottom; i >= top; i-- {
				out = append(out, m[i][left])
			}
			left++
		}
	}
	return out
}
```

### `04/05` — Búsqueda en matriz ordenada

De [`04/05` — Matrices, §4](../04-secuencias/05-matrices.md#4--búsqueda-en-matriz-ordenada).

```go
// Busca x en una matriz con filas y columnas crecientes. Devuelve (fila, columna, encontrado). O(R + C).
func staircaseSearch(m [][]int, x int) (int, int, bool) {
	i, j := 0, len(m[0])-1
	for i < len(m) && j >= 0 {
		switch {
		case m[i][j] == x:
			return i, j, true
		case m[i][j] > x:
			j-- // todo lo de debajo en esta columna es mayor: se descarta
		default:
			i++ // todo lo de la izquierda en esta fila es menor: se descarta
		}
	}
	return -1, -1, false
}
```

---

## 🧱 Bloque 05 — Orden y búsqueda

### `05/01` — Inserción y estabilidad

De [`05/01` — Ordenación por comparación, §3](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#3--inserción-y-estabilidad).

```go
// Ordenación por inserción, estable. Θ(n²) caso peor; Θ(n + inversiones) en general.
func insertionSort(a []int) {
	for j := 1; j < len(a); j++ {
		key, i := a[j], j
		for i > 0 && a[i-1] > key { // estricto: los iguales no se adelantan
			a[i] = a[i-1]
			i--
		}
		a[i] = key
	}
}
```

### `05/01` — Ordenación por mezcla

De [`05/01` — Ordenación por comparación, §4](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#4--ordenación-por-mezcla).

```go
// Ordenación por mezcla, estable. Devuelve un slice nuevo. Θ(n log n).
func mergeSort(a []int) []int {
	if len(a) <= 1 {
		return append([]int(nil), a...)
	}
	mid := len(a) / 2
	left, right := mergeSort(a[:mid]), mergeSort(a[mid:])
	out := make([]int, 0, len(a))
	i, j := 0, 0
	for i < len(left) && j < len(right) {
		if right[j] < left[i] {
			out = append(out, right[j])
			j++
		} else {
			out = append(out, left[i]) // empate: izquierda, estable
			i++
		}
	}
	out = append(out, left[i:]...)
	return append(out, right[j:]...)
}
```

### `05/01` — *Quicksort*

De [`05/01` — Ordenación por comparación, §5](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md#5--quicksort).

```go
import "math/rand"

// Quicksort de a[lo..hi] con pivote aleatorio y partición de Hoare. Θ(n log n) esperado.
// Llamada inicial: quickSort(a, 0, len(a)-1).
func quickSort(a []int, lo, hi int) {
	if lo >= hi {
		return
	}
	r := lo + rand.Intn(hi-lo+1)
	a[lo], a[r] = a[r], a[lo] // pivote aleatorio en a[lo]
	p := a[lo]
	i, j := lo-1, hi+1
	for {
		for i++; a[i] < p; i++ {
		}
		for j--; a[j] > p; j-- {
		}
		if i >= j {
			break
		}
		a[i], a[j] = a[j], a[i]
	}
	quickSort(a, lo, j)
	quickSort(a, j+1, hi)
}
```

### `05/03` — Contar inversiones con la mezcla

De [`05/03` — Inversiones, selección y mediana, §3](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#3--contar-inversiones-con-la-mezcla).

```go
// Devuelve el slice ordenado y el número de inversiones. Θ(n log n).
func countInversions(a []int) ([]int, int64) {
	if len(a) <= 1 {
		return append([]int(nil), a...), 0
	}
	mid := len(a) / 2
	left, x := countInversions(a[:mid])
	right, y := countInversions(a[mid:])
	out := make([]int, 0, len(a))
	inv := x + y
	i, j := 0, 0
	for i < len(left) && j < len(right) {
		if right[j] < left[i] {
			inv += int64(len(left) - i) // quedan len(left) − i mayores
			out = append(out, right[j])
			j++
		} else {
			out = append(out, left[i])
			i++
		}
	}
	out = append(out, left[i:]...)
	return append(out, right[j:]...), inv
}
```

### `05/03` — *Quickselect*

De [`05/03` — Inversiones, selección y mediana, §4](../05-orden-y-busqueda/03-inversiones-y-seleccion.md#4--quickselect).

```go
import "math/rand"

// Valor que ocuparía la posición k (desde 0) si a estuviera ordenado. Reordena a. O(n) esperado.
func quickSelect(a []int, k int) int {
	lo, hi := 0, len(a)-1
	for lo < hi {
		r := lo + rand.Intn(hi-lo+1)
		a[lo], a[r] = a[r], a[lo] // pivote aleatorio en a[lo]
		p := a[lo]
		i, j := lo-1, hi+1
		for {
			for i++; a[i] < p; i++ {
			}
			for j--; a[j] > p; j-- {
			}
			if i >= j {
				break
			}
			a[i], a[j] = a[j], a[i]
		}
		if k <= j {
			hi = j
		} else {
			lo = j + 1
		}
	}
	return a[k]
}
```

### `05/04` — *Lower* y *upper bound*

De [`05/04` — Búsqueda binaria, §3](../05-orden-y-busqueda/04-busqueda-binaria.md#3--lower-y-upper-bound).

```go
// Primer índice en [0, n] con a[i] >= x. Equivale a sort.SearchInts(a, x).
func lowerBound(a []int, x int) int {
	lo, hi := 0, len(a)
	for lo < hi {
		mid := int(uint(lo+hi) >> 1) // sin desbordamiento aunque lo + hi pase de MaxInt
		if a[mid] < x {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	return lo
}

// Primer índice en [0, n] con a[i] > x. Equivale a sort.Search(len(a), func(i int) bool { return a[i] > x }).
func upperBound(a []int, x int) int {
	lo, hi := 0, len(a)
	for lo < hi {
		mid := int(uint(lo+hi) >> 1)
		if a[mid] <= x {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	return lo
}
```

### `05/04` — Binaria sobre la respuesta

De [`05/04` — Búsqueda binaria, §4](../05-orden-y-busqueda/04-busqueda-binaria.md#4--binaria-sobre-la-respuesta).

```go
// Primer v en [lo, hi) con p(v) cierto, o hi si no hay. Pre: p monótono (falso…cierto).
func firstTrue(lo, hi int64, p func(int64) bool) int64 {
	for lo < hi {
		mid := lo + (hi-lo)/2
		if p(mid) {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}
```

### `05/04` — Binaria en reales

De [`05/04` — Búsqueda binaria, §5](../05-orden-y-busqueda/04-busqueda-binaria.md#5--binaria-en-reales).

```go
// Frontera de p (falso…cierto) en [lo, hi], con 100 vueltas fijas.
func boundaryReal(lo, hi float64, p func(float64) bool) float64 {
	for it := 0; it < 100; it++ {
		mid := lo + (hi-lo)/2
		if p(mid) {
			hi = mid
		} else {
			lo = mid
		}
	}
	return hi
}
```

---

## 🧱 Bloque 06 — Lineales y hashing

### `06/01` — Pila, cola y deque

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §3](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#3--pila-cola-y-deque).

```go
// Pila: un slice, con append, s[len(s)-1] y s = s[:len(s)-1].
// Cola y deque: Go no las trae (container/list es una lista doblemente enlazada, lenta y con
// interface{}). Un deque genérico sobre un arreglo circular, O(1) amortizado por operación:
type Deque[T any] struct {
	buf        []T
	head, size int
}

func (d *Deque[T]) grow() {
	bigger := make([]T, max(4, 2*len(d.buf)))
	for i := 0; i < d.size; i++ {
		bigger[i] = d.buf[(d.head+i)%len(d.buf)]
	}
	d.buf, d.head = bigger, 0
}

func (d *Deque[T]) PushBack(x T) {
	if d.size == len(d.buf) {
		d.grow()
	}
	d.buf[(d.head+d.size)%len(d.buf)] = x
	d.size++
}

func (d *Deque[T]) PushFront(x T) {
	if d.size == len(d.buf) {
		d.grow()
	}
	d.head = (d.head - 1 + len(d.buf)) % len(d.buf)
	d.buf[d.head] = x
	d.size++
}

func (d *Deque[T]) PopFront() T { // pre: Len() > 0
	x := d.buf[d.head]
	d.head = (d.head + 1) % len(d.buf)
	d.size--
	return x
}

func (d *Deque[T]) PopBack() T { // pre: Len() > 0
	d.size--
	return d.buf[(d.head+d.size)%len(d.buf)]
}

func (d *Deque[T]) Front() T { return d.buf[d.head] }
func (d *Deque[T]) Back() T  { return d.buf[(d.head+d.size-1)%len(d.buf)] }
func (d *Deque[T]) Len() int { return d.size }
```

### `06/01` — Pila monótona

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §4](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#4--pila-monótona).

```go
// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
func nextGreater(a []int) []int {
	ans := make([]int, len(a))
	var st []int // índices con valores no crecientes desde el fondo
	for i, x := range a {
		ans[i] = -1
		for len(st) > 0 && a[st[len(st)-1]] < x {
			ans[st[len(st)-1]] = i
			st = st[:len(st)-1]
		}
		st = append(st, i)
	}
	return ans
}
```

### `06/01` — Cola monótona

De [`06/01` — Pila, cola, deque y sus versiones monótonas, §5](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md#5--cola-monótona).

```go
// mins[i] = mínimo de a[i..i+k-1]. Θ(n). Como solo se añade por detrás, basta un slice con
// un índice de cabeza: lo de delante se «saca» avanzando head.
func windowMin(a []int, k int) []int {
	dq := make([]int, 0, len(a)) // índices con valores crecientes, desde head
	head := 0
	var mins []int
	for i, x := range a {
		for len(dq) > head && a[dq[len(dq)-1]] >= x {
			dq = dq[:len(dq)-1]
		}
		dq = append(dq, i)
		if dq[head] <= i-k {
			head++
		}
		if i >= k-1 {
			mins = append(mins, a[dq[head]])
		}
	}
	return mins
}
```

### `06/02` — Inversión, punto medio y mezcla

De [`06/02` — Listas enlazadas, §3](../06-lineales-y-hashing/02-listas-enlazadas.md#3--inversión-punto-medio-y-mezcla).

```go
type ListNode struct {
	Val  int
	Next *ListNode
}

func reverse(head *ListNode) *ListNode {
	var prev *ListNode
	for head != nil {
		head.Next, prev, head = prev, head, head.Next // se evalúa todo a la derecha antes de asignar
	}
	return prev
}

func middle(head *ListNode) *ListNode {
	slow, fast := head, head
	for fast != nil && fast.Next != nil {
		slow, fast = slow.Next, fast.Next.Next
	}
	return slow
}

func merge(a, b *ListNode) *ListNode {
	dummy := &ListNode{}
	tail := dummy
	for a != nil && b != nil {
		if b.Val < a.Val {
			tail.Next, b = b, b.Next
		} else {
			tail.Next, a = a, a.Next
		}
		tail = tail.Next
	}
	if a != nil {
		tail.Next = a
	} else {
		tail.Next = b
	}
	return dummy.Next
}
```

### `06/02` — Floyd: detectar el ciclo y su inicio

De [`06/02` — Listas enlazadas, §4](../06-lineales-y-hashing/02-listas-enlazadas.md#4--floyd-detectar-el-ciclo-y-su-inicio).

```go
// Inicio del ciclo, o nil si la lista termina. O(n) tiempo, O(1) memoria.
func cycleStart(head *ListNode) *ListNode {
	slow, fast := head, head
	for fast != nil && fast.Next != nil {
		slow, fast = slow.Next, fast.Next.Next
		if slow == fast { // se encuentran dentro del ciclo
			p := head
			for p != slow {
				p, slow = p.Next, slow.Next
			}
			return p
		}
	}
	return nil
}
```

### `06/02` — La caché LRU

De [`06/02` — Listas enlazadas, §5](../06-lineales-y-hashing/02-listas-enlazadas.md#5--la-caché-lru).

```go
import "container/list"

// LRU de capacidad cap: mapa de clave a nodo de una lista doble. O(1) esperado por operación.
type entry struct{ key, value int }

type LRUCache struct {
	cap   int
	order *list.List // el frente es el más reciente
	nodes map[int]*list.Element
}

func NewLRUCache(cap int) *LRUCache {
	return &LRUCache{cap: cap, order: list.New(), nodes: map[int]*list.Element{}}
}

func (c *LRUCache) Get(key int) int {
	e, ok := c.nodes[key]
	if !ok {
		return -1
	}
	c.order.MoveToFront(e)
	return e.Value.(entry).value
}

func (c *LRUCache) Put(key, value int) {
	if e, ok := c.nodes[key]; ok {
		e.Value = entry{key, value}
		c.order.MoveToFront(e)
		return
	}
	c.nodes[key] = c.order.PushFront(entry{key, value})
	if c.order.Len() > c.cap {
		oldest := c.order.Back() // el del final es el menos reciente
		c.order.Remove(oldest)
		delete(c.nodes, oldest.Value.(entry).key)
	}
}
```

### `06/03` — Encadenamiento y direccionamiento abierto

De [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*, §3](../06-lineales-y-hashing/03-tablas-hash.md#3--encadenamiento-y-direccionamiento-abierto).

```go
import "math/bits"

// Conjunto de int64 con sondeo lineal; capacidad potencia de 2; α ≤ 1/2. Didáctico: en Go, map[int64]struct{}.
type IntSet struct {
	keys []int64
	used []bool
	n    int
}

func NewIntSet() *IntSet { return &IntSet{keys: make([]int64, 16), used: make([]bool, 16)} }

func (s *IntSet) slot(x int64) int {
	h := uint64(x) * 0x9E3779B97F4A7C15 // multiplicativa de Fibonacci: se quedan los bits altos
	return int(h >> (bits.LeadingZeros64(uint64(len(s.keys))) + 1))
}

func (s *IntSet) Contains(x int64) bool {
	for i := s.slot(x); s.used[i]; i = (i + 1) & (len(s.keys) - 1) {
		if s.keys[i] == x {
			return true
		}
	}
	return false
}

func (s *IntSet) Add(x int64) {
	if 2*(s.n+1) > len(s.keys) { // rehash: el doble de capacidad y reinsertar todo
		oldKeys, oldUsed := s.keys, s.used
		s.keys, s.used, s.n = make([]int64, 2*len(oldKeys)), make([]bool, 2*len(oldKeys)), 0
		for i, k := range oldKeys {
			if oldUsed[i] {
				s.Add(k)
			}
		}
	}
	i := s.slot(x)
	for ; s.used[i]; i = (i + 1) & (len(s.keys) - 1) {
		if s.keys[i] == x {
			return
		}
	}
	s.keys[i], s.used[i] = x, true
	s.n++
}
```

---

## 🧱 Bloque 07 — Árboles

### `07/01` — Representación

De [`07/01` — Árboles: representación y recorridos, §3](../07-arboles/01-arboles-y-recorridos.md#3--representación).

```go
// Árbol de n nodos (1..n) a partir de sus n − 1 aristas no dirigidas.
func buildTree(n int, edges [][2]int) [][]int {
	adj := make([][]int, n+1)
	for _, e := range edges {
		adj[e[0]] = append(adj[e[0]], e[1])
		adj[e[1]] = append(adj[e[1]], e[0])
	}
	return adj
}
```

### `07/01` — Los cuatro recorridos

De [`07/01` — Árboles: representación y recorridos, §4](../07-arboles/01-arboles-y-recorridos.md#4--los-cuatro-recorridos).

```go
type TreeNode struct {
	Val         int
	Left, Right *TreeNode
}

func inorder(t *TreeNode, out *[]int) {
	if t != nil {
		inorder(t.Left, out)
		*out = append(*out, t.Val)
		inorder(t.Right, out)
	}
}

// Preorden iterativo con una pila; devuelve el orden, los padres y las profundidades. O(n).
func preorder(adj [][]int, root int) (order, parent, depth []int) {
	n := len(adj)
	parent, depth = make([]int, n), make([]int, n)
	parent[root] = -1
	st := []int{root}
	for len(st) > 0 {
		v := st[len(st)-1]
		st = st[:len(st)-1]
		order = append(order, v)
		for _, w := range adj[v] {
			if w != parent[v] {
				parent[w], depth[w] = v, depth[v]+1
				st = append(st, w)
			}
		}
	}
	return order, parent, depth
}
```

### `07/01` — Diámetro

De [`07/01` — Árboles: representación y recorridos, §5](../07-arboles/01-arboles-y-recorridos.md#5--diámetro).

```go
// Nodo más lejano de s y su distancia: BFS sobre un árbol sin pesos. O(n).
func farthest(adj [][]int, s int) (int, int) {
	dist := make([]int, len(adj))
	for i := range dist {
		dist[i] = -1
	}
	dist[s] = 0
	queue, best := []int{s}, s
	for head := 0; head < len(queue); head++ { // cola: slice con índice de cabeza
		v := queue[head]
		if dist[v] > dist[best] {
			best = v
		}
		for _, w := range adj[v] {
			if dist[w] < 0 {
				dist[w] = dist[v] + 1
				queue = append(queue, w)
			}
		}
	}
	return best, dist[best]
}

// Diámetro (en aristas): el más lejano del más lejano de cualquier nodo.
func diameter(adj [][]int) int {
	a, _ := farthest(adj, 1)
	_, d := farthest(adj, a)
	return d
}
```

### `07/02` — El árbol binario de búsqueda

De [`07/02` — BST y árboles balanceados, §3](../07-arboles/02-bst-y-balanceados.md#3--el-árbol-binario-de-búsqueda).

```go
type BSTNode struct {
	Key         int
	Left, Right *BSTNode
}

func insert(t *BSTNode, key int) *BSTNode {
	if t == nil {
		return &BSTNode{Key: key}
	}
	if key < t.Key {
		t.Left = insert(t.Left, key)
	} else if key > t.Key {
		t.Right = insert(t.Right, key)
	}
	return t
}

// Menor clave >= x, o nil. O(h).
func ceiling(t *BSTNode, x int) *BSTNode {
	var best *BSTNode
	for t != nil {
		if t.Key >= x {
			best, t = t, t.Left
		} else {
			t = t.Right
		}
	}
	return best
}
```

### `07/04` — *Trie* de palabras

De [`07/04` — *Tries*, §3](../07-arboles/04-tries.md#3--trie-de-palabras).

```go
// Trie de palabras en minúsculas a–z: insert y countPrefix en O(L). Para otro alfabeto, map[byte]int32.
type Trie struct {
	next      [][26]int32 // 0 = sin hijo (la raíz es el nodo 0 y nunca es hijo)
	pass, end []int32
}

func NewTrie() *Trie { return &Trie{next: make([][26]int32, 1), pass: []int32{0}, end: []int32{0}} }

func (t *Trie) Insert(w string) {
	v := 0
	for i := 0; i < len(w); i++ {
		c := w[i] - 'a'
		if t.next[v][c] == 0 {
			t.next[v][c] = int32(len(t.next))
			t.next = append(t.next, [26]int32{})
			t.pass = append(t.pass, 0)
			t.end = append(t.end, 0)
		}
		v = int(t.next[v][c])
		t.pass[v]++
	}
	t.end[v]++
}

func (t *Trie) CountPrefix(p string) int {
	v := 0
	for i := 0; i < len(p); i++ {
		v = int(t.next[v][p[i]-'a'])
		if v == 0 {
			return 0
		}
	}
	return int(t.pass[v])
}
```

### `07/04` — *Trie* binario

De [`07/04` — *Tries*, §4](../07-arboles/04-tries.md#4--trie-binario).

```go
// Trie binario de enteros no negativos de B bits; borrado con contadores. O(B) por operación.
const xorBits = 30

type XorTrie struct {
	next [][2]int32
	cnt  []int32
}

func NewXorTrie() *XorTrie { return &XorTrie{next: make([][2]int32, 1), cnt: []int32{0}} }

func (t *XorTrie) Add(x int, d int32) { // d = 1 inserta, d = −1 borra
	v := 0
	for b := xorBits - 1; b >= 0; b-- {
		bit := x >> b & 1
		if t.next[v][bit] == 0 {
			t.next[v][bit] = int32(len(t.next))
			t.next = append(t.next, [2]int32{})
			t.cnt = append(t.cnt, 0)
		}
		v = int(t.next[v][bit])
		t.cnt[v] += d
	}
}

// Máximo de x XOR y entre los y del trie. Pre: el trie no está vacío.
func (t *XorTrie) MaxXor(x int) int {
	v, res := 0, 0
	for b := xorBits - 1; b >= 0; b-- {
		want := (x >> b & 1) ^ 1
		if u := t.next[v][want]; u != 0 && t.cnt[u] > 0 {
			res |= 1 << b
			v = int(u)
		} else {
			v = int(t.next[v][want^1])
		}
	}
	return res
}
```

### `07/05` — *Binary lifting*

De [`07/05` — LCA, §3](../07-arboles/05-lca.md#3--binary-lifting).

```go
import "math/bits"

// Binary lifting. parent[root] = root; order = preorden (cada padre antes que sus hijos).
type Lca struct {
	up    [][]int
	depth []int
}

func NewLca(parent, depth []int) *Lca {
	n := len(parent)
	log := max(1, bits.Len(uint(n-1)))
	up := [][]int{append([]int(nil), parent...)}
	for k := 1; k < log; k++ {
		prev, cur := up[k-1], make([]int, n)
		for v := range cur {
			cur[v] = prev[prev[v]]
		}
		up = append(up, cur)
	}
	return &Lca{up, depth}
}

func (l *Lca) Lift(v, d int) int {
	for k := 0; d > 0; k, d = k+1, d>>1 {
		if d&1 == 1 {
			v = l.up[k][v]
		}
	}
	return v
}

func (l *Lca) Query(u, v int) int {
	if l.depth[u] < l.depth[v] {
		u, v = v, u
	}
	u = l.Lift(u, l.depth[u]-l.depth[v])
	if u == v {
		return u
	}
	for k := len(l.up) - 1; k >= 0; k-- {
		if l.up[k][u] != l.up[k][v] {
			u, v = l.up[k][u], l.up[k][v]
		}
	}
	return l.up[0][u]
}
```

---

## 🧱 Bloque 08 — Heaps y Union-Find

### `08/01` — El montículo binario

De [`08/01` — Montículo binario, §3](../08-heaps-y-union-find/01-monticulo-binario.md#3--el-montículo-binario).

```go
// Montículo binario genérico sobre un slice; less(a, b) dice si a va antes. Push y Pop en O(log n).
// container/heap obliga a implementar cinco métodos y trabaja con interface{}: este es más corto y sin boxing.
type Heap[T any] struct {
	a    []T
	less func(x, y T) bool
}

func NewHeap[T any](less func(x, y T) bool) *Heap[T] { return &Heap[T]{less: less} }

func (h *Heap[T]) Len() int { return len(h.a) }
func (h *Heap[T]) Top() T   { return h.a[0] } // pre: Len() > 0

func (h *Heap[T]) Push(x T) {
	h.a = append(h.a, x)
	for i := len(h.a) - 1; i > 0; { // flotar
		p := (i - 1) / 2
		if !h.less(h.a[i], h.a[p]) {
			break
		}
		h.a[i], h.a[p] = h.a[p], h.a[i]
		i = p
	}
}

func (h *Heap[T]) Pop() T { // pre: Len() > 0
	res, n := h.a[0], len(h.a)-1
	h.a[0] = h.a[n]
	h.a = h.a[:n]
	h.down(0)
	return res
}

// ReplaceTop sustituye la cima por x con una sola bajada (el heapreplace de Python). Pre: Len() > 0.
func (h *Heap[T]) ReplaceTop(x T) {
	h.a[0] = x
	h.down(0)
}

func (h *Heap[T]) down(i int) { // hundir
	n := len(h.a)
	for 2*i+1 < n {
		c := 2*i + 1
		if c+1 < n && h.less(h.a[c+1], h.a[c]) {
			c++
		}
		if !h.less(h.a[c], h.a[i]) {
			break
		}
		h.a[i], h.a[c] = h.a[c], h.a[i]
		i = c
	}
}
```

### `08/01` — `heapify`

De [`08/01` — Montículo binario, §4](../08-heaps-y-union-find/01-monticulo-binario.md#4--heapify).

```go
// Heapify: convierte un slice en montículo en el sitio, hundiendo de n/2 − 1 hacia atrás. O(n).
// Con [5, 2, 9, 1, 5, 6] y menor primero, queda [1, 2, 6, 5, 5, 9].
func Heapify[T any](a []T, less func(x, y T) bool) *Heap[T] {
	h := &Heap[T]{a: a, less: less}
	for i := len(a)/2 - 1; i >= 0; i-- {
		h.down(i)
	}
	return h
}
```

### `08/02` — Los `k` mayores

De [`08/02` — Patrones con *heap*, §3](../08-heaps-y-union-find/02-patrones-con-heap.md#3--los-k-mayores).

```go
// Los k mayores de a, en orden creciente, con el Heap de 08/01. O(n log k) tiempo, O(k) memoria.
func topK(a []int, k int) []int {
	h := NewHeap(func(x, y int) bool { return x < y }) // de mínimos: la cima es el menor de los k
	for _, x := range a {
		if h.Len() < k {
			h.Push(x)
		} else if k > 0 && x > h.Top() {
			h.ReplaceTop(x) // sale el menor de los k, entra x
		}
	}
	out := make([]int, 0, h.Len())
	for h.Len() > 0 {
		out = append(out, h.Pop()) // salen en orden creciente
	}
	return out
}
```

### `08/02` — Mezcla de `k` listas

De [`08/02` — Patrones con *heap*, §4](../08-heaps-y-union-find/02-patrones-con-heap.md#4--mezcla-de-k-listas).

```go
// Mezcla k slices ordenados, con el Heap de 08/01. O(N log k).
func mergeK(lists [][]int) []int {
	type item struct{ v, i, j int } // valor, lista y posición
	h := NewHeap(func(x, y item) bool { return x.v < y.v })
	for i, l := range lists {
		if len(l) > 0 {
			h.Push(item{l[0], i, 0})
		}
	}
	var out []int
	for h.Len() > 0 {
		it := h.Pop()
		out = append(out, it.v)
		if it.j+1 < len(lists[it.i]) {
			h.Push(item{lists[it.i][it.j+1], it.i, it.j + 1})
		}
	}
	return out
}
```

### `08/02` — La mediana con dos *heaps*

De [`08/02` — Patrones con *heap*, §5](../08-heaps-y-union-find/02-patrones-con-heap.md#5--la-mediana-con-dos-heaps).

```go
// Mediana inferior de un flujo, con el Heap de 08/01. Add O(log n), Median O(1).
type RunningMedian struct{ lo, hi *Heap[int] } // lo: máximos (la mitad baja); hi: mínimos

func NewRunningMedian() *RunningMedian {
	return &RunningMedian{
		lo: NewHeap(func(x, y int) bool { return x > y }),
		hi: NewHeap(func(x, y int) bool { return x < y }),
	}
}

func (m *RunningMedian) Add(x int) {
	if m.lo.Len() == 0 || x <= m.lo.Top() {
		m.lo.Push(x)
	} else {
		m.hi.Push(x)
	}
	if m.lo.Len() > m.hi.Len()+1 { // reequilibrar: lo tiene igual o uno más
		m.hi.Push(m.lo.Pop())
	} else if m.hi.Len() > m.lo.Len() {
		m.lo.Push(m.hi.Pop())
	}
}

func (m *RunningMedian) Median() int { return m.lo.Top() } // pre: se añadió al menos uno
```

### `08/04` — Union-Find

De [`08/04` — Union-Find, §3](../08-heaps-y-union-find/04-union-find.md#3--union-find).

```go
// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
type DSU struct{ parent, size []int }

func NewDSU(n int) *DSU {
	d := &DSU{make([]int, n), make([]int, n)}
	for i := range d.parent {
		d.parent[i], d.size[i] = i, 1
	}
	return d
}

func (d *DSU) Find(x int) int {
	for d.parent[x] != x {
		d.parent[x] = d.parent[d.parent[x]] // halving: cada nodo salta a su abuelo
		x = d.parent[x]
	}
	return x
}

func (d *DSU) Unite(a, b int) bool {
	a, b = d.Find(a), d.Find(b)
	if a == b {
		return false
	}
	if d.size[a] < d.size[b] {
		a, b = b, a
	}
	d.parent[b] = a
	d.size[a] += d.size[b]
	return true
}
```

---

## 🧱 Bloque 09 — Consultas sobre rangos

### `09/02` — Puntual y rango

De [`09/02` — Fenwick, §3](../09-consultas-sobre-rangos/02-fenwick.md#3--puntual-y-rango).

```go
// Fenwick de sumas, índices 1..n. Add y Prefix en O(log n).
type Fenwick struct {
	n int
	t []int64
}

func NewFenwick(n int) *Fenwick { return &Fenwick{n, make([]int64, n+1)} }

func (f *Fenwick) Add(i int, d int64) {
	for ; i <= f.n; i += i & -i { // i & -i: el bit más bajo de i
		f.t[i] += d
	}
}

func (f *Fenwick) Prefix(i int) int64 { // suma de 1..i
	var s int64
	for ; i > 0; i -= i & -i {
		s += f.t[i]
	}
	return s
}

func (f *Fenwick) Range(l, r int) int64 { return f.Prefix(r) - f.Prefix(l-1) }
```

### `09/02` — Rango y puntual

De [`09/02` — Fenwick, §4](../09-consultas-sobre-rangos/02-fenwick.md#4--rango-y-puntual).

```go
// Rango y puntual: el Fenwick de 09/02 §3 sobre las diferencias (de tamaño n + 1).
func rangeAdd(f *Fenwick, l, r int, v int64) {
	f.Add(l, v)
	f.Add(r+1, -v)
}

func pointGet(f *Fenwick, i int) int64 { return f.Prefix(i) }
```

---

## 🧱 Bloque 10 — Búsqueda completa y divide y vencerás

### `10/01` — Recursión y pila de llamadas

De [`10/01` — Recursión, §3](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#3--recursión-y-pila-de-llamadas).

```go
import "fmt"

// Mueve n discos de src a dst usando via. Θ(2ⁿ) tiempo, Θ(n) pila.
// La pila de una goroutine crece sola (hasta 1 GB por defecto): en Go, la recursión profunda
// rara vez desborda, al revés que en Java, Python o JavaScript.
func hanoi(n int, src, dst, via string, out *[]string) {
	if n == 0 {
		return // caso base
	}
	hanoi(n-1, src, via, dst, out)
	*out = append(*out, fmt.Sprintf("%s %s", src, dst))
	hanoi(n-1, via, dst, src, out)
}
```

### `10/01` — Paso a iterativo

De [`10/01` — Recursión, §4](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md#4--paso-a-iterativo).

```go
import "fmt"

// Hanoi iterativo: marcos {n, src, dst, via, etapa} en un slice. Θ(2ⁿ) tiempo, Θ(n) memoria.
func hanoiIterative(n int, src, dst, via string, out *[]string) {
	type frame struct {
		k       int
		a, b, c string
		stage   int
	}
	stack := []frame{{n, src, dst, via, 0}}
	for len(stack) > 0 {
		f := &stack[len(stack)-1] // puntero al marco de arriba: se modifica en el sitio
		switch {
		case f.k == 0 || f.stage == 2:
			stack = stack[:len(stack)-1] // base o terminado: vuelve
		case f.stage == 0:
			f.stage = 1
			stack = append(stack, frame{f.k - 1, f.a, f.c, f.b, 0}) // hanoi(k−1, src, via, dst)
		default:
			*out = append(*out, fmt.Sprintf("%s %s", f.a, f.b))
			f.stage = 2
			stack = append(stack, frame{f.k - 1, f.c, f.b, f.a, 0}) // hanoi(k−1, via, dst, src)
		}
	}
}
```

### `10/02` — Subconjuntos con máscaras de bits

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §3](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#3--subconjuntos-con-máscaras-de-bits).

```go
import "math/bits"

// sum[m] = suma de los a[i] con el bit i encendido en m. Θ(2ⁿ) tiempo y memoria.
func subsetSums(a []int64) []int64 {
	n := len(a)
	total := make([]int64, 1<<n)
	for m := 1; m < 1<<n; m++ {
		low := bits.TrailingZeros(uint(m)) // índice del bit más bajo
		total[m] = total[m&(m-1)] + a[low]
	}
	return total
}
```

### `10/02` — Permutaciones

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §4](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#4--permutaciones).

```go
// Siguiente permutación lexicográfica en su sitio; false si a era la última.
func nextPermutation(a []int) bool {
	i := len(a) - 2
	for i >= 0 && a[i] >= a[i+1] {
		i--
	}
	if i < 0 {
		return false
	}
	j := len(a) - 1
	for a[j] <= a[i] {
		j--
	}
	a[i], a[j] = a[j], a[i]
	for l, r := i+1, len(a)-1; l < r; l, r = l+1, r-1 { // invertir el sufijo
		a[l], a[r] = a[r], a[l]
	}
	return true
}

// Recursiva: añade a cur cada índice no usado y deshace al volver.
func permute(a []int, cur []int, used []bool, visit func([]int)) {
	if len(cur) == len(a) {
		visit(cur) // procesar cur (copiarlo si se guarda: el slice se reutiliza)
		return
	}
	for i := range a {
		if !used[i] {
			used[i] = true
			permute(a, append(cur, a[i]), used, visit)
			used[i] = false
		}
	}
}
```

### `10/02` — Combinaciones

De [`10/02` — Generar subconjuntos, permutaciones y combinaciones, §5](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md#5--combinaciones).

```go
// Todas las combinaciones de k índices de [0, n), en orden lexicográfico.
func combine(n, k, start int, cur []int, visit func([]int)) {
	if len(cur) == k {
		visit(cur) // procesar cur
		return
	}
	for i := start; i <= n-(k-len(cur)); i++ { // poda: quedan huecos suficientes
		combine(n, k, i+1, append(cur, i), visit)
	}
}
```

### `10/03` — *Backtracking*

De [`10/03` — *Backtracking* con poda y ramificación y poda, §3](../10-busqueda-completa-y-divide-y-venceras/03-backtracking-y-poda.md#3--backtracking).

```go
// Subconjuntos (por posición) de a con suma exacta rem. a ascendente y positivo;
// suffix[j] = a[j] + … + a[n−1].
func countSubsets(a, suffix []int64, start int, rem int64) int64 {
	if rem == 0 {
		return 1
	}
	var count int64
	for j := start; j < len(a); j++ {
		if a[j] > rem || suffix[j] < rem { // las dos podas
			break
		}
		count += countSubsets(a, suffix, j+1, rem-a[j])
	}
	return count
}
```

### `10/05` — El esquema

De [`10/05` — Divide y vencerás, §3](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#3--el-esquema).

```go
import "math"

// Suma máxima de un subarreglo no vacío de a[lo:hi]. Θ(n log n). Pre: lo < hi.
func maxSubarrayDC(a []int64, lo, hi int) int64 {
	if hi-lo == 1 {
		return a[lo]
	}
	mid := (lo + hi) / 2
	best := max(maxSubarrayDC(a, lo, mid), maxSubarrayDC(a, mid, hi))
	var s int64
	leftBest := int64(math.MinInt64)
	for i := mid - 1; i >= lo; i-- {
		s += a[i]
		leftBest = max(leftBest, s)
	}
	s = 0
	rightBest := int64(math.MinInt64)
	for i := mid; i < hi; i++ {
		s += a[i]
		rightBest = max(rightBest, s)
	}
	return max(best, leftBest+rightBest) // el mejor que cruza el centro
}
```

### `10/05` — Exponenciación rápida

De [`10/05` — Divide y vencerás, §6](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md#6--exponenciación-rápida).

```go
import "math/bits"

// aⁿ mod m, con m < 2⁶³. Θ(log n). bits.Mul64 da el producto de 128 bits y bits.Rem64 su resto:
// sin desbordamiento aunque m pase de 2³².
func powMod(a, n, m uint64) uint64 {
	mulMod := func(x, y uint64) uint64 {
		hi, lo := bits.Mul64(x, y)
		return bits.Rem64(hi, lo, m)
	}
	result, base := 1%m, a%m
	for ; n > 0; n >>= 1 {
		if n&1 == 1 {
			result = mulMod(result, base)
		}
		base = mulMod(base, base)
	}
	return result
}
```

---

## 🧱 Bloque 11 — Voraces

### `11/02` — Selección de actividades

De [`11/02` — Intervalos, §3](../11-voraces/02-intervalos.md#3--selección-de-actividades).

```go
import (
	"math"
	"sort"
)

// Máximo número de intervalos [s, f) disjuntos. Θ(n log n).
func maxDisjoint(intervals [][2]int) int {
	iv := append([][2]int(nil), intervals...)
	sort.Slice(iv, func(i, j int) bool { return iv[i][1] < iv[j][1] }) // por final
	count, lastEnd := 0, math.MinInt
	for _, x := range iv {
		if x[0] >= lastEnd {
			count++
			lastEnd = x[1]
		}
	}
	return count
}
```

### `11/02` — Cubrimiento con puntos

De [`11/02` — Intervalos, §4](../11-voraces/02-intervalos.md#4--cubrimiento-con-puntos).

```go
import (
	"math"
	"sort"
)

// Mínimo de puntos que pinchan todos los intervalos cerrados [s, f]. Θ(n log n).
func minPoints(intervals [][2]int) int {
	iv := append([][2]int(nil), intervals...)
	sort.Slice(iv, func(i, j int) bool { return iv[i][1] < iv[j][1] })
	count, last := 0, math.MinInt
	for _, x := range iv {
		if x[0] > last { // no lo pincha el último punto: uno nuevo en su final
			count++
			last = x[1]
		}
	}
	return count
}
```

### `11/02` — Mezcla

De [`11/02` — Intervalos, §5](../11-voraces/02-intervalos.md#5--mezcla).

```go
import "sort"

// Unión de intervalos cerrados [s, f], como lista ordenada de disjuntos. Θ(n log n).
func mergeClosed(intervals [][2]int) [][2]int {
	iv := append([][2]int(nil), intervals...)
	sort.Slice(iv, func(i, j int) bool { return iv[i][0] < iv[j][0] })
	var out [][2]int
	for _, x := range iv {
		if n := len(out); n > 0 && x[0] <= out[n-1][1] { // cerrados: tocarse ya es solaparse
			out[n-1][1] = max(out[n-1][1], x[1])
		} else {
			out = append(out, x)
		}
	}
	return out
}
```

### `11/02` — Mínimo de salas

De [`11/02` — Intervalos, §6](../11-voraces/02-intervalos.md#6--mínimo-de-salas).

```go
import "sort"

// Mínimo de salas para reuniones [s, f) (la profundidad máxima). Θ(n log n).
func minRooms(intervals [][2]int) int {
	starts, ends := make([]int, len(intervals)), make([]int, len(intervals))
	for i, x := range intervals {
		starts[i], ends[i] = x[0], x[1]
	}
	sort.Ints(starts)
	sort.Ints(ends)
	rooms, best, j := 0, 0, 0
	for _, s := range starts {
		for j < len(ends) && ends[j] <= s { // semiabiertos: la que acaba en s libera la sala
			j++
			rooms--
		}
		rooms++
		best = max(best, rooms)
	}
	return best
}
```

### `11/03` — Planificación con plazos

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §3](../11-voraces/03-plazos-huffman-y-monedas.md#3--planificación-con-plazos).

```go
import "sort"

// Máximo beneficio de tareas unitarias {plazo, beneficio} que acaban a tiempo, con el Heap de 08/01.
// Θ(n log n).
func maxProfit(jobs [][2]int64) int64 {
	js := append([][2]int64(nil), jobs...)
	sort.Slice(js, func(i, j int) bool { return js[i][0] < js[j][0] }) // por plazo
	kept := NewHeap(func(x, y int64) bool { return x < y })            // las elegidas; cima, la peor
	var total int64
	for _, j := range js {
		kept.Push(j[1])
		total += j[1]
		if int64(kept.Len()) > j[0] { // no caben: se suelta la de menor beneficio
			total -= kept.Pop()
		}
	}
	return total
}
```

### `11/03` — Huffman

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §4](../11-voraces/03-plazos-huffman-y-monedas.md#4--huffman).

```go
// Coste mínimo de unir: Σ frecuencia · profundidad del árbol de Huffman, con el Heap de 08/01. Θ(n log n).
func huffmanCost(freq []int64) int64 {
	h := NewHeap(func(x, y int64) bool { return x < y })
	for _, f := range freq {
		h.Push(f)
	}
	var cost int64
	for h.Len() > 1 {
		a, b := h.Pop(), h.Pop()
		cost += a + b
		h.Push(a + b)
	}
	return cost
}
```

### `11/03` — Mochila fraccionaria

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §5](../11-voraces/03-plazos-huffman-y-monedas.md#5--mochila-fraccionaria).

```go
import (
	"math/big"
	"sort"
)

// Valor máximo con materiales divisibles {peso, valor}, exacto con big.Rat. Θ(n log n).
func fractionalKnapsack(items [][2]int64, capacity int64) *big.Rat {
	it := append([][2]int64(nil), items...)
	sort.Slice(it, func(i, j int) bool { // por valor/peso decreciente, sin dividir: v_i·w_j > v_j·w_i
		return it[i][1]*it[j][0] > it[j][1]*it[i][0]
	})
	value := new(big.Rat)
	for _, x := range it {
		if capacity == 0 {
			break
		}
		take := min(x[0], capacity)
		value.Add(value, big.NewRat(x[1]*take, x[0]))
		capacity -= take
	}
	return value
}
```

### `11/03` — Monedas canónicas

De [`11/03` — Plazos, Huffman, mochila fraccionaria y monedas, §6](../11-voraces/03-plazos-huffman-y-monedas.md#6--monedas-canónicas).

```go
// Monedas del voraz para x; coins de mayor a menor, con la de 1. O(k).
func greedyCoins(coins []int64, x int64) int64 {
	var count int64
	for _, c := range coins {
		count += x / c
		x %= c
	}
	return count
}
```

---

## 🧱 Bloque 12 — DP clásica

### `12/01` — Memoización

De [`12/01` — De la recursión a la tabla, §3](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#3--memoización).

```go
const MOD = 1_000_000_007

// Formas de llegar al escalón i con pasos de 1, 2 o 3. memo[i] = -1 si aún no se calculó;
// llamada inicial con memo de tamaño n + 1 lleno de -1.
func ways(i int, memo []int64) int64 {
	if i < 0 {
		return 0
	}
	if i == 0 {
		return 1
	}
	if memo[i] >= 0 {
		return memo[i] // ya calculado: O(1)
	}
	memo[i] = (ways(i-1, memo) + ways(i-2, memo) + ways(i-3, memo)) % MOD
	return memo[i]
}
```

### `12/01` — Tabulación

De [`12/01` — De la recursión a la tabla, §4](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#4--tabulación).

```go
// Formas de subir n escalones con pasos de 1, 2 o 3, sin pisar los rotos. Θ(n). Usa MOD de §3.
func waysTable(n int, broken []bool) int64 {
	dp := make([]int64, n+1)
	dp[0] = 1
	for i := 1; i <= n; i++ {
		if broken[i] {
			continue // dp[i] = 0: no se puede pisar
		}
		for s := 1; s <= 3 && s <= i; s++ {
			dp[i] += dp[i-s]
		}
		dp[i] %= MOD
	}
	return dp[n]
}
```

### `12/01` — Reconstrucción

De [`12/01` — De la recursión a la tabla, §5](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md#5--reconstrucción).

```go
// Menor número de operaciones +1, ×2, ×3 de 1 a n, y la secuencia de valores. Θ(n).
func opsPath(n int) []int {
	dp, parent := make([]int, n+1), make([]int, n+1)
	for x := 2; x <= n; x++ {
		dp[x], parent[x] = dp[x-1]+1, x-1
		for _, d := range []int{2, 3} {
			if x%d == 0 && dp[x/d]+1 < dp[x] {
				dp[x], parent[x] = dp[x/d]+1, x/d
			}
		}
	}
	var path []int
	for x := n; x != 1; x = parent[x] { // se sigue la cadena de padres
		path = append(path, x)
	}
	path = append(path, 1)
	for i, j := 0, len(path)-1; i < j; i, j = i+1, j-1 {
		path[i], path[j] = path[j], path[i]
	}
	return path
}
```

### `12/02` — Escaleras y robos

De [`12/02` — DP lineal y LIS, §3](../12-dp-clasica/02-dp-lineal-y-lis.md#3--escaleras-y-robos).

```go
// Mayor suma de elementos sin coger dos consecutivos. Θ(n), O(1) memoria.
func maxNonAdjacent(a []int64) int64 {
	var take, skip int64
	for _, x := range a {
		take, skip = skip+x, max(take, skip) // asignación simultánea
	}
	return max(take, skip)
}
```

### `12/02` — LIS en O(n²)

De [`12/02` — DP lineal y LIS, §4](../12-dp-clasica/02-dp-lineal-y-lis.md#4--lis-en-on).

```go
// Una LIS estrictamente creciente, por índices. Θ(n²).
func lisQuadratic(a []int) []int {
	n := len(a)
	if n == 0 {
		return nil
	}
	d, parent := make([]int, n), make([]int, n)
	best := 0
	for i := 0; i < n; i++ {
		d[i], parent[i] = 1, -1
		for j := 0; j < i; j++ {
			if a[j] < a[i] && d[j]+1 > d[i] {
				d[i], parent[i] = d[j]+1, j
			}
		}
		if d[i] > d[best] {
			best = i
		}
	}
	var seq []int
	for i := best; i != -1; i = parent[i] {
		seq = append([]int{i}, seq...)
	}
	return seq
}
```

### `12/02` — LIS en O(n log n)

De [`12/02` — DP lineal y LIS, §5](../12-dp-clasica/02-dp-lineal-y-lis.md#5--lis-en-on-log-n).

```go
import "sort"

// Una LIS estrictamente creciente, por índices. Θ(n log n).
func lisFast(a []int) []int {
	var tails, tailIdx []int
	parent := make([]int, len(a))
	for i, x := range a {
		k := sort.SearchInts(tails, x) // lower bound: estricta; con x+1, no decreciente
		if k == len(tails) {
			tails, tailIdx = append(tails, x), append(tailIdx, i)
		} else {
			tails[k], tailIdx[k] = x, i
		}
		parent[i] = -1
		if k > 0 {
			parent[i] = tailIdx[k-1]
		}
	}
	var seq []int
	if len(tailIdx) > 0 {
		for i := tailIdx[len(tailIdx)-1]; i != -1; i = parent[i] {
			seq = append([]int{i}, seq...)
		}
	}
	return seq
}
```

### `12/03` — Mochila 0/1

De [`12/03` — Mochilas, §3](../12-dp-clasica/03-mochilas.md#3--mochila-01).

```go
// Mochila 0/1: mejor valor y los índices elegidos. Θ(n · W).
func knapsack01(w, v []int, W int) (int64, []int) {
	n := len(w)
	dp := make([][]int64, n+1)
	for i := range dp {
		dp[i] = make([]int64, W+1)
	}
	for i := 1; i <= n; i++ {
		wi, vi := w[i-1], int64(v[i-1])
		for c := 0; c <= W; c++ {
			dp[i][c] = dp[i-1][c] // sin el objeto i − 1
			if wi <= c && dp[i-1][c-wi]+vi > dp[i][c] {
				dp[i][c] = dp[i-1][c-wi] + vi // con él
			}
		}
	}
	var chosen []int
	for i, c := n, W; i > 0; i-- {
		if dp[i][c] != dp[i-1][c] { // cambió: el objeto i − 1 está dentro
			chosen = append([]int{i - 1}, chosen...)
			c -= w[i-1]
		}
	}
	return dp[n][W], chosen
}
```

### `12/03` — Una fila de memoria

De [`12/03` — Mochilas, §4](../12-dp-clasica/03-mochilas.md#4--una-fila-de-memoria).

```go
// Mochila 0/1 en una fila. Θ(n · W) tiempo, Θ(W) memoria.
func knapsackRow(w, v []int, W int) int64 {
	dp := make([]int64, W+1)
	for i := range w {
		for c := W; c >= w[i]; c-- { // descendente: cada objeto se usa una vez
			dp[c] = max(dp[c], dp[c-w[i]]+int64(v[i]))
		}
	}
	return dp[W]
}
```

### `12/03` — Mochila ilimitada

De [`12/03` — Mochilas, §5](../12-dp-clasica/03-mochilas.md#5--mochila-ilimitada).

```go
// Mochila ilimitada: cada objeto cualquier número de veces. Θ(n · W).
func knapsackUnbounded(w, v []int, W int) int64 {
	dp := make([]int64, W+1)
	for i := range w {
		for c := w[i]; c <= W; c++ { // ascendente: dp[c − w] ya puede incluir el objeto
			dp[c] = max(dp[c], dp[c-w[i]]+int64(v[i]))
		}
	}
	return dp[W]
}
```

### `12/03` — Monedas: contar y mínimo

De [`12/03` — Mochilas, §6](../12-dp-clasica/03-mochilas.md#6--monedas-contar-y-mínimo).

```go
import "math"

// Combinaciones (sin orden) de pagar x: las monedas por fuera. Usa MOD de 12/01 §3.
func countCombinations(coins []int, x int) int64 {
	ways := make([]int64, x+1)
	ways[0] = 1
	for _, c := range coins {
		for s := c; s <= x; s++ {
			ways[s] = (ways[s] + ways[s-c]) % MOD
		}
	}
	return ways[x]
}

// Mínimo de monedas para pagar x, o -1.
func minCoins(coins []int, x int) int {
	const inf = math.MaxInt32
	mn := make([]int, x+1)
	for s := 1; s <= x; s++ {
		mn[s] = inf
		for _, c := range coins {
			if c <= s && mn[s-c] != inf {
				mn[s] = min(mn[s], mn[s-c]+1)
			}
		}
	}
	if mn[x] == inf {
		return -1
	}
	return mn[x]
}
```

### `12/04` — LCS

De [`12/04` — DP sobre cadenas, §3](../12-dp-clasica/04-dp-sobre-cadenas.md#3--lcs).

```go
import "strings"

// Una subsecuencia común más larga de a y b (por bytes). Θ(n · m).
func lcs(a, b string) string {
	n, m := len(a), len(b)
	L := make([][]int, n+1)
	for i := range L {
		L[i] = make([]int, m+1)
	}
	for i := 1; i <= n; i++ {
		for j := 1; j <= m; j++ {
			if a[i-1] == b[j-1] {
				L[i][j] = L[i-1][j-1] + 1
			} else {
				L[i][j] = max(L[i-1][j], L[i][j-1])
			}
		}
	}
	var out []byte
	for i, j := n, m; i > 0 && j > 0; {
		switch {
		case a[i-1] == b[j-1]:
			out = append(out, a[i-1])
			i, j = i-1, j-1
		case L[i-1][j] >= L[i][j-1]:
			i--
		default:
			j--
		}
	}
	var sb strings.Builder
	for k := len(out) - 1; k >= 0; k-- {
		sb.WriteByte(out[k])
	}
	return sb.String()
}
```

### `12/04` — Distancia de edición

De [`12/04` — DP sobre cadenas, §4](../12-dp-clasica/04-dp-sobre-cadenas.md#4--distancia-de-edición).

```go
// Distancia de Levenshtein entre a y b (por bytes), con dos filas. Θ(n · m) tiempo, Θ(m) memoria.
func editDistance(a, b string) int {
	prev, cur := make([]int, len(b)+1), make([]int, len(b)+1)
	for j := range prev {
		prev[j] = j
	}
	for i := 1; i <= len(a); i++ {
		cur[0] = i
		for j := 1; j <= len(b); j++ {
			sub := 0
			if a[i-1] != b[j-1] {
				sub = 1
			}
			cur[j] = min(prev[j]+1, cur[j-1]+1, prev[j-1]+sub)
		}
		prev, cur = cur, prev
	}
	return prev[len(b)]
}
```

### `12/04` — Subsecuencias y palíndromos

De [`12/04` — DP sobre cadenas, §5](../12-dp-clasica/04-dp-sobre-cadenas.md#5--subsecuencias-y-palíndromos).

```go
// Longitud de la subsecuencia palindrómica más larga de s. Θ(n²).
func longestPalSubseq(s string) int {
	n := len(s)
	if n == 0 {
		return 0
	}
	P := make([][]int, n)
	for i := range P {
		P[i] = make([]int, n)
	}
	for i := n - 1; i >= 0; i-- {
		P[i][i] = 1
		for j := i + 1; j < n; j++ {
			if s[i] == s[j] {
				P[i][j] = P[i+1][j-1] + 2 // con j == i + 1, P[i+1][i] es 0
			} else {
				P[i][j] = max(P[i+1][j], P[i][j-1])
			}
		}
	}
	return P[0][n-1]
}
```

### `12/05` — Rejillas

De [`12/05` — DP en rejillas y de intervalos, §3](../12-dp-clasica/05-rejillas-e-intervalos.md#3--rejillas).

```go
// Máximo recogido bajando o a la derecha; '#' bloquea; '.' vale 0; un dígito, su valor. -1 si no hay camino.
func bestPath(g []string) int {
	R, C := len(g), len(g[0])
	const none = -1 // inalcanzable
	d := make([]int, C)
	for i := 0; i < R; i++ {
		for j := 0; j < C; j++ {
			if g[i][j] == '#' {
				d[j] = none
				continue
			}
			best := none
			if i == 0 && j == 0 {
				best = 0
			} else {
				if i > 0 {
					best = d[j] // desde arriba (la fila anterior)
				}
				if j > 0 && d[j-1] > best {
					best = d[j-1] // desde la izquierda
				}
			}
			if best == none {
				d[j] = none
			} else if g[i][j] == '.' {
				d[j] = best
			} else {
				d[j] = best + int(g[i][j]-'0')
			}
		}
	}
	return d[C-1]
}
```

### `12/06` — Conteo

De [`12/06` — Conteo con DP, §3](../12-dp-clasica/06-conteo.md#3--conteo).

```go
// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c].
// Usa MOD de 12/01 §3. Θ(n · L²).
func countWords(n int, allowed [][]bool) int64 {
	L := len(allowed)
	cur := make([]int64, L)
	for i := range cur {
		cur[i] = 1
	}
	for step := 1; step < n; step++ {
		next := make([]int64, L)
		for c := 0; c < L; c++ {
			for p := 0; p < L; p++ {
				if allowed[p][c] {
					next[c] += cur[p]
				}
			}
			next[c] %= MOD
		}
		cur = next
	}
	var total int64
	for _, x := range cur {
		total += x
	}
	return total % MOD
}
```

---

## 🧱 Bloque 13 — DP avanzada

### `13/03` — DP en árboles

De [`13/03` — DP en árboles y en DAG, §3](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#3--dp-en-árboles).

```go
// Conjunto independiente de peso máximo en un árbol con raíz 0 y padres parent (parent[0] = -1). Θ(n).
func maxIndependentSet(parent []int, w []int64) int64 {
	n := len(parent)
	children := make([][]int, n)
	for v := 1; v < n; v++ {
		children[parent[v]] = append(children[parent[v]], v)
	}
	order, stack := make([]int, 0, n), []int{0}
	for len(stack) > 0 { // preorden iterativo
		v := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		order = append(order, v)
		stack = append(stack, children[v]...)
	}
	inc, exc := make([]int64, n), make([]int64, n) // con v dentro / sin v
	for k := n - 1; k >= 0; k-- {                  // al revés: hijos antes que padres
		v := order[k]
		inc[v] = w[v]
		for _, c := range children[v] {
			inc[v] += exc[c]
			exc[v] += max(inc[c], exc[c])
		}
	}
	return max(inc[0], exc[0])
}
```

### `13/03` — DP sobre DAG

De [`13/03` — DP en árboles y en DAG, §4](../13-dp-avanzada/03-dp-en-arboles-y-dag.md#4--dp-sobre-dag).

```go
// En un DAG con adj[u] = {v, w}: caminos desde s (mod 1e9+7) y camino más largo desde s
// (reach[v] = false si v no se alcanza). Θ(V + E).
func dagDP(n int, adj [][][2]int, s int) (ways, longest []int64, reach []bool) {
	const mod = 1_000_000_007
	indeg := make([]int, n)
	for u := 0; u < n; u++ {
		for _, e := range adj[u] {
			indeg[e[0]]++
		}
	}
	var order []int
	for u := 0; u < n; u++ {
		if indeg[u] == 0 {
			order = append(order, u)
		}
	}
	for head := 0; head < len(order); head++ { // Kahn: order hace de cola
		for _, e := range adj[order[head]] {
			if indeg[e[0]]--; indeg[e[0]] == 0 {
				order = append(order, e[0])
			}
		}
	}
	ways, longest, reach = make([]int64, n), make([]int64, n), make([]bool, n)
	ways[s], reach[s] = 1, true
	for _, u := range order {
		if !reach[u] {
			continue
		}
		for _, e := range adj[u] {
			v, w := e[0], int64(e[1])
			ways[v] = (ways[v] + ways[u]) % mod
			if !reach[v] || longest[u]+w > longest[v] {
				longest[v] = longest[u] + w
			}
			reach[v] = true
		}
	}
	return ways, longest, reach
}
```

---

## 🧱 Bloque 14 — Grafos: recorridos

### `14/01` — Representaciones

De [`14/01` — Representaciones y su coste, §3](../14-grafos-recorridos/01-representaciones.md#3--representaciones).

```go
import (
	"bufio"
	"io"
)

// Lee n, m y m aristas no dirigidas «u v w» (desde 1) en listas de adyacencia desde 0.
type Edge struct{ To, W int }

func readGraph(r io.Reader) (int, [][]Edge) {
	in := bufio.NewReaderSize(r, 1<<20)
	next := func() int { // el lector de enteros de 01/03, en una línea por campo
		n, c := 0, byte(0)
		for c, _ = in.ReadByte(); c == ' ' || c == '\n' || c == '\r'; c, _ = in.ReadByte() {
		}
		neg := c == '-'
		if neg {
			c, _ = in.ReadByte()
		}
		for ; c >= '0' && c <= '9'; c, _ = in.ReadByte() {
			n = n*10 + int(c-'0')
		}
		if neg {
			return -n
		}
		return n
	}
	n, m := next(), next()
	adj := make([][]Edge, n)
	for i := 0; i < m; i++ {
		u, v, w := next()-1, next()-1, next()
		adj[u] = append(adj[u], Edge{v, w})
		adj[v] = append(adj[v], Edge{u, w})
	}
	return n, adj
}
```

### `14/02` — BFS

De [`14/02` — BFS, §3](../14-grafos-recorridos/02-bfs.md#3--bfs).

```go
// Distancias desde las fuentes (−1 = inalcanzable) y el arreglo de padres. Θ(V + E).
func bfs(adj [][]int, sources []int) (dist, parent []int) {
	n := len(adj)
	dist, parent = make([]int, n), make([]int, n)
	for i := range dist {
		dist[i], parent[i] = -1, -1
	}
	queue := append([]int(nil), sources...) // cola: slice con índice de cabeza
	for _, s := range sources {
		dist[s] = 0
	}
	for head := 0; head < len(queue); head++ {
		u := queue[head]
		for _, v := range adj[u] {
			if dist[v] == -1 { // se marca al encolar, no al sacar
				dist[v], parent[v] = dist[u]+1, u
				queue = append(queue, v)
			}
		}
	}
	return dist, parent
}
```

### `14/02` — Multifuente y rejillas

De [`14/02` — BFS, §4](../14-grafos-recorridos/02-bfs.md#4--multifuente-y-rejillas).

```go
// Distancia de cada casilla a la fuente más cercana; −1 = pared o inalcanzable.
func gridBFS(g []string, sources [][2]int) [][]int {
	R, C := len(g), len(g[0])
	dist := make([][]int, R)
	for i := range dist {
		dist[i] = make([]int, C)
		for j := range dist[i] {
			dist[i][j] = -1
		}
	}
	queue := append([][2]int(nil), sources...)
	for _, s := range sources {
		dist[s[0]][s[1]] = 0
	}
	moves := [4][2]int{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
	for head := 0; head < len(queue); head++ {
		r, c := queue[head][0], queue[head][1]
		for _, d := range moves {
			r2, c2 := r+d[0], c+d[1]
			if r2 >= 0 && r2 < R && c2 >= 0 && c2 < C && g[r2][c2] != '#' && dist[r2][c2] == -1 {
				dist[r2][c2] = dist[r][c] + 1
				queue = append(queue, [2]int{r2, c2})
			}
		}
	}
	return dist
}
```

### `14/02` — 0-1 BFS

De [`14/02` — BFS, §5](../14-grafos-recorridos/02-bfs.md#5--0-1-bfs).

```go
import "math"

// 0-1 BFS con el Deque de 06/01: adj[u] = {v, w} con w en {0, 1}. Θ(V + E).
func bfs01(adj [][]Edge, s int) []int {
	dist := make([]int, len(adj))
	for i := range dist {
		dist[i] = math.MaxInt
	}
	dist[s] = 0
	var dq Deque[int]
	dq.PushBack(s)
	for dq.Len() > 0 {
		u := dq.PopFront()
		for _, e := range adj[u] {
			if dist[u]+e.W < dist[e.To] {
				dist[e.To] = dist[u] + e.W
				if e.W == 0 {
					dq.PushFront(e.To) // peso 0: misma distancia, delante
				} else {
					dq.PushBack(e.To)
				}
			}
		}
	}
	return dist
}
```

### `14/02` — Estados compuestos

De [`14/02` — BFS, §6](../14-grafos-recorridos/02-bfs.md#6--estados-compuestos).

```go
// Pasos mínimos de (sr, sc) a 'T' atravesando hasta maxWalls muros '#'. Estado (r, c, k); -1 si no se llega.
func bfsWithState(g []string, sr, sc, maxWalls int) int {
	R, C, K := len(g), len(g[0]), maxWalls+1
	dist := make([]int, R*C*K) // el estado (r, c, k) aplanado en un índice
	for i := range dist {
		dist[i] = -1
	}
	id := func(r, c, k int) int { return (r*C+c)*K + k }
	dist[id(sr, sc, 0)] = 0
	queue := [][3]int{{sr, sc, 0}}
	moves := [4][2]int{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
	for head := 0; head < len(queue); head++ {
		r, c, k := queue[head][0], queue[head][1], queue[head][2]
		if g[r][c] == 'T' {
			return dist[id(r, c, k)]
		}
		for _, d := range moves {
			r2, c2 := r+d[0], c+d[1]
			if r2 < 0 || r2 >= R || c2 < 0 || c2 >= C {
				continue
			}
			k2 := k
			if g[r2][c2] == '#' {
				k2++
			}
			if k2 <= maxWalls && dist[id(r2, c2, k2)] == -1 {
				dist[id(r2, c2, k2)] = dist[id(r, c, k)] + 1
				queue = append(queue, [3]int{r2, c2, k2})
			}
		}
	}
	return -1
}
```

### `14/03` — DFS

De [`14/03` — DFS, §3](../14-grafos-recorridos/03-dfs.md#3--dfs).

```go
// DFS iterativo de todo el grafo con tiempos de entrada y salida; tin[v] = 0 marca «blanco».
func dfsAll(adj [][]int) (tin, tout, parent []int) {
	n := len(adj)
	tin, tout, parent = make([]int, n), make([]int, n), make([]int, n)
	it := make([]int, n) // por dónde va la lista de cada vértice
	for i := range parent {
		parent[i] = -1
	}
	timer := 0
	for s := 0; s < n; s++ {
		if tin[s] != 0 {
			continue
		}
		timer++
		tin[s] = timer
		stack := []int{s}
		for len(stack) > 0 {
			u := stack[len(stack)-1]
			if it[u] < len(adj[u]) {
				v := adj[u][it[u]]
				it[u]++
				if tin[v] == 0 {
					parent[v] = u
					timer++
					tin[v] = timer
					stack = append(stack, v)
				}
			} else {
				timer++
				tout[u] = timer
				stack = stack[:len(stack)-1]
			}
		}
	}
	return tin, tout, parent
}
```

### `14/03` — Componentes

De [`14/03` — DFS, §4](../14-grafos-recorridos/03-dfs.md#4--componentes).

```go
// Etiqueta de componente por vértice y número de componentes.
func components(adj [][]int) ([]int, int) {
	comp := make([]int, len(adj))
	for i := range comp {
		comp[i] = -1
	}
	c := 0
	for s := range adj {
		if comp[s] != -1 {
			continue
		}
		comp[s] = c
		stack := []int{s}
		for len(stack) > 0 {
			u := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			for _, v := range adj[u] {
				if comp[v] == -1 {
					comp[v] = c
					stack = append(stack, v)
				}
			}
		}
		c++
	}
	return comp, c
}
```

### `14/03` — Ciclos

De [`14/03` — DFS, §5](../14-grafos-recorridos/03-dfs.md#5--ciclos).

```go
// Tres colores, iterativo: true si hay una arista a un vértice gris (en la pila).
func hasDirectedCycle(adj [][]int) bool {
	n := len(adj)
	color, it := make([]int, n), make([]int, n) // 0 blanco, 1 gris, 2 negro
	for s := 0; s < n; s++ {
		if color[s] != 0 {
			continue
		}
		color[s] = 1
		stack := []int{s}
		for len(stack) > 0 {
			u := stack[len(stack)-1]
			if it[u] < len(adj[u]) {
				v := adj[u][it[u]]
				it[u]++
				if color[v] == 1 {
					return true
				}
				if color[v] == 0 {
					color[v] = 1
					stack = append(stack, v)
				}
			} else {
				color[u] = 2
				stack = stack[:len(stack)-1]
			}
		}
	}
	return false
}
```

### `14/03` — Bipartición

De [`14/03` — DFS, §6](../14-grafos-recorridos/03-dfs.md#6--bipartición).

```go
// Colores 0/1 por vértice, o nil si hay un ciclo impar.
func bipartite(adj [][]int) []int {
	color := make([]int, len(adj))
	for i := range color {
		color[i] = -1
	}
	for s := range adj {
		if color[s] != -1 {
			continue
		}
		color[s] = 0
		stack := []int{s}
		for len(stack) > 0 {
			u := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			for _, v := range adj[u] {
				if color[v] == -1 {
					color[v] = color[u] ^ 1
					stack = append(stack, v)
				} else if color[v] == color[u] {
					return nil
				}
			}
		}
	}
	return color
}
```

### `14/04` — Kahn

De [`14/04` — Orden topológico y DP sobre DAG, §3](../14-grafos-recorridos/04-orden-topologico.md#3--kahn).

```go
// Orden topológico por Kahn, o nil si hay ciclo. Θ(V + E).
func kahn(adj [][]int) []int {
	n := len(adj)
	indeg := make([]int, n)
	for _, out := range adj {
		for _, v := range out {
			indeg[v]++
		}
	}
	var order []int
	for v := 0; v < n; v++ {
		if indeg[v] == 0 {
			order = append(order, v)
		}
	}
	for head := 0; head < len(order); head++ { // order hace de cola
		for _, v := range adj[order[head]] {
			if indeg[v]--; indeg[v] == 0 {
				order = append(order, v)
			}
		}
	}
	if len(order) < n {
		return nil // quedan vértices con entradas: hay ciclo
	}
	return order
}
```

### `14/04` — Por DFS

De [`14/04` — Orden topológico y DP sobre DAG, §4](../14-grafos-recorridos/04-orden-topologico.md#4--por-dfs).

```go
// Postorden invertido, iterativo; nil si hay ciclo. Θ(V + E).
func topoDFS(adj [][]int) []int {
	n := len(adj)
	color, it := make([]int, n), make([]int, n)
	post := make([]int, 0, n)
	for s := 0; s < n; s++ {
		if color[s] != 0 {
			continue
		}
		color[s] = 1
		stack := []int{s}
		for len(stack) > 0 {
			u := stack[len(stack)-1]
			if it[u] < len(adj[u]) {
				v := adj[u][it[u]]
				it[u]++
				if color[v] == 1 {
					return nil
				}
				if color[v] == 0 {
					color[v] = 1
					stack = append(stack, v)
				}
			} else {
				color[u] = 2
				stack = stack[:len(stack)-1]
				post = append(post, u)
			}
		}
	}
	for i, j := 0, len(post)-1; i < j; i, j = i+1, j-1 {
		post[i], post[j] = post[j], post[i]
	}
	return post
}
```

---

## 🧱 Bloque 15 — Grafos con pesos y flujos

### `15/01` — Dijkstra con montículo

De [`15/01` — Dijkstra, §3](../15-grafos-pesos-y-flujos/01-dijkstra.md#3--dijkstra-con-montículo).

```go
import "math"

// Dijkstra con el Heap de 08/01 y aristas Edge de 14/01; pesos >= 0. Distancias (MaxInt64 =
// inalcanzable) y padres. O((V + E) log V).
func dijkstra(adj [][]Edge, s int) (dist []int64, parent []int) {
	n := len(adj)
	dist, parent = make([]int64, n), make([]int, n)
	for i := range dist {
		dist[i], parent[i] = math.MaxInt64, -1
	}
	type item struct {
		d int64
		u int
	}
	pq := NewHeap(func(x, y item) bool { return x.d < y.d })
	dist[s] = 0
	pq.Push(item{0, s})
	for pq.Len() > 0 {
		it := pq.Pop()
		if it.d > dist[it.u] {
			continue // entrada vieja: el vértice ya salió con una distancia menor
		}
		for _, e := range adj[it.u] {
			if nd := it.d + int64(e.W); nd < dist[e.To] {
				dist[e.To], parent[e.To] = nd, it.u
				pq.Push(item{nd, e.To})
			}
		}
	}
	return dist, parent
}
```

### `15/01` — Dijkstra sobre estados

De [`15/01` — Dijkstra, §4](../15-grafos-pesos-y-flujos/01-dijkstra.md#4--dijkstra-sobre-estados).

```go
import "math"

// Distancia mínima desde s usando hasta K vales (cada vale deja una arista a coste 0); estado
// (vértice, vales usados). Con el Heap de 08/01. O((V·K + E·K) log(V·K)).
func dijkstraVouchers(adj [][]Edge, s, K int) []int64 {
	n := len(adj)
	dist := make([][]int64, n)
	for i := range dist {
		dist[i] = make([]int64, K+1)
		for k := range dist[i] {
			dist[i][k] = math.MaxInt64
		}
	}
	type item struct {
		d    int64
		u, k int
	}
	pq := NewHeap(func(x, y item) bool { return x.d < y.d })
	dist[s][0] = 0
	pq.Push(item{0, s, 0})
	for pq.Len() > 0 {
		it := pq.Pop()
		if it.d > dist[it.u][it.k] {
			continue
		}
		for _, e := range adj[it.u] {
			if nd := it.d + int64(e.W); nd < dist[e.To][it.k] { // pagando
				dist[e.To][it.k] = nd
				pq.Push(item{nd, e.To, it.k})
			}
			if it.k < K && it.d < dist[e.To][it.k+1] { // con un vale
				dist[e.To][it.k+1] = it.d
				pq.Push(item{it.d, e.To, it.k + 1})
			}
		}
	}
	best := make([]int64, n)
	for v := range best {
		best[v] = math.MaxInt64
		for _, d := range dist[v] {
			best[v] = min(best[v], d)
		}
	}
	return best
}
```

### `15/02` — Bellman-Ford

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §3](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#3--bellman-ford).

```go
import "math"

// edges = {u, v, w}. Distancias desde s y si hay un ciclo negativo alcanzable. O(V · E).
func bellmanFord(n int, edges [][3]int, s int) ([]int64, bool) {
	dist := make([]int64, n)
	for i := range dist {
		dist[i] = math.MaxInt64
	}
	dist[s] = 0
	for round := 0; round < n; round++ {
		changed := false
		for _, e := range edges {
			u, v, w := e[0], e[1], int64(e[2])
			if dist[u] != math.MaxInt64 && dist[u]+w < dist[v] { // sin sumar al «infinito»
				dist[v] = dist[u] + w
				changed = true
			}
		}
		if !changed {
			return dist, false
		}
	}
	return dist, true // la ronda n todavía mejoró
}
```

### `15/02` — Floyd-Warshall

De [`15/02` — Bellman-Ford, Floyd-Warshall y Johnson, §4](../15-grafos-pesos-y-flujos/02-bellman-ford-floyd-y-johnson.md#4--floyd-warshall).

```go
// d: matriz n × n con inf (un valor grande, p. ej. 1 << 60) sin arista y 0 en la diagonal;
// se modifica en el sitio. Θ(n³). El inf se salta: inf + inf desbordaría.
func floydWarshall(d [][]int64, inf int64) {
	n := len(d)
	for k := 0; k < n; k++ { // k por fuera: es el invariante
		for i := 0; i < n; i++ {
			if d[i][k] == inf {
				continue
			}
			for j := 0; j < n; j++ {
				if d[k][j] != inf && d[i][k]+d[k][j] < d[i][j] {
					d[i][j] = d[i][k] + d[k][j]
				}
			}
		}
	}
}
```

### `15/04` — Kruskal

De [`15/04` — Árbol de expansión mínima, §3](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#3--kruskal).

```go
import "sort"

// edges = {w, u, v}. Peso del árbol de expansión mínima, o -1 si no es conexo. O(E log E).
func kruskal(n int, edges [][3]int) int64 {
	es := append([][3]int(nil), edges...)
	sort.Slice(es, func(i, j int) bool { return es[i][0] < es[j][0] })
	parent, size := make([]int, n), make([]int, n)
	for i := range parent {
		parent[i], size[i] = i, 1
	}
	find := func(x int) int { // el Union-Find de 08/04, en línea
		for parent[x] != x {
			parent[x] = parent[parent[x]]
			x = parent[x]
		}
		return x
	}
	var total int64
	used := 0
	for _, e := range es {
		a, b := find(e[1]), find(e[2])
		if a == b {
			continue // cerraría un ciclo
		}
		if size[a] < size[b] {
			a, b = b, a
		}
		parent[b] = a
		size[a] += size[b]
		total += int64(e[0])
		if used++; used == n-1 {
			break
		}
	}
	if used != n-1 && n > 0 {
		return -1
	}
	return total
}
```

### `15/04` — Prim

De [`15/04` — Árbol de expansión mínima, §4](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md#4--prim).

```go
// Prim con el Heap de 08/01 y aristas Edge de 14/01. Peso del árbol de expansión mínima, o -1 si
// no es conexo. O(E log V).
func prim(adj [][]Edge) int64 {
	n := len(adj)
	inTree := make([]bool, n)
	type item struct{ w, u int }
	pq := NewHeap(func(x, y item) bool { return x.w < y.w })
	pq.Push(item{0, 0})
	var total int64
	taken := 0
	for pq.Len() > 0 && taken < n {
		it := pq.Pop()
		if inTree[it.u] {
			continue // entrada vieja
		}
		inTree[it.u] = true
		total += int64(it.w)
		taken++
		for _, e := range adj[it.u] {
			if !inTree[e.To] {
				pq.Push(item{e.W, e.To})
			}
		}
	}
	if taken != n {
		return -1
	}
	return total
}
```

---

## 🧱 Bloque 16 — Cadenas

### `16/01` — Inmutabilidad y concatenación

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §3](../16-cadenas/01-cadenas-y-patrones-basicos.md#3--inmutabilidad-y-concatenación).

```go
import "strings"

// Los string de Go son inmutables: s += w en un bucle copia todo cada vez. strings.Builder acumula
// en un búfer que crece como un slice (amortizado O(1) por byte).
func joinWords(words []string, sep string) string {
	var sb strings.Builder
	for i, w := range words {
		if i > 0 {
			sb.WriteString(sep)
		}
		sb.WriteString(w)
	}
	return sb.String() // o directamente strings.Join(words, sep)
}
```

### `16/01` — Frecuencias y anagramas

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §4](../16-cadenas/01-cadenas-y-patrones-basicos.md#4--frecuencias-y-anagramas).

```go
import "slices"

// Frecuencias de las 26 minúsculas; un [26]int es comparable con == y sirve de clave de un map.
func freq(s string) [26]int {
	var f [26]int
	for i := 0; i < len(s); i++ {
		f[s[i]-'a']++
	}
	return f
}

func isAnagram(a, b string) bool { return len(a) == len(b) && freq(a) == freq(b) }

// signature: la cadena con sus letras ordenadas; dos anagramas tienen la misma.
func signature(s string) string {
	b := []byte(s)
	slices.Sort(b)
	return string(b)
}
```

### `16/01` — Palíndromos con dos punteros

De [`16/01` — Cadenas en los tres lenguajes y patrones básicos, §5](../16-cadenas/01-cadenas-y-patrones-basicos.md#5--palíndromos-con-dos-punteros).

```go
// Pares simétricos distintos en s[l..r] (por bytes).
func mismatches(s string, l, r int) int {
	count := 0
	for ; l < r; l, r = l+1, r-1 {
		if s[l] != s[r] {
			count++
		}
	}
	return count
}
```

### `16/02` — Función de prefijo

De [`16/02` — KMP y la función de prefijo, §3](../16-cadenas/02-kmp.md#3--función-de-prefijo).

```go
// pi[i] = longitud del borde más largo de s[0..i] (por bytes). Θ(n).
func prefixFunction(s string) []int {
	pi := make([]int, len(s))
	for i := 1; i < len(s); i++ {
		k := pi[i-1]
		for k > 0 && s[i] != s[k] {
			k = pi[k-1] // el siguiente borde más corto
		}
		if s[i] == s[k] {
			k++
		}
		pi[i] = k
	}
	return pi
}
```

### `16/02` — KMP

De [`16/02` — KMP y la función de prefijo, §4](../16-cadenas/02-kmp.md#4--kmp).

```go
// Posiciones de inicio de las apariciones (solapadas) de p en t, con prefixFunction de §3. Θ(n + m).
func kmpSearch(t, p string) []int {
	pi := prefixFunction(p)
	var found []int
	k, m := 0, len(p)
	for i := 0; i < len(t); i++ {
		for k > 0 && t[i] != p[k] {
			k = pi[k-1]
		}
		if t[i] == p[k] {
			k++
		}
		if k == m {
			found = append(found, i-m+1)
			k = pi[k-1] // sigue buscando: las apariciones pueden solaparse
		}
	}
	return found
}
```

---

## 🧱 Bloque 17 — Matemática

### `17/01` — Operaciones y trucos

De [`17/01` — Bits, §3](../17-matematica/01-bits.md#3--operaciones-y-trucos).

```go
import "math/bits"

// Los enteros de Go tienen tamaño fijo: con uint64 los desplazamientos son lógicos y ^x es el
// complemento a uno; math/bits da el recuento y los índices en una instrucción.
func getBit(x uint64, i int) uint64   { return x >> i & 1 }
func setBit(x uint64, i int) uint64   { return x | 1<<i }
func clearBit(x uint64, i int) uint64 { return x &^ (1 << i) } // &^ es «y no»: propio de Go
func lowBit(x uint64) uint64          { return x & -x }        // -x en uint64: complemento a dos
func isPowerOfTwo(x uint64) bool      { return x > 0 && x&(x-1) == 0 }
func popcount(x uint64) int           { return bits.OnesCount64(x) }
func lowestIndex(x uint64) int        { return bits.TrailingZeros64(x) } // 64 si x == 0
func highestIndex(x uint64) int       { return bits.Len64(x) - 1 }       // -1 si x == 0
```

### `17/02` — Euclides

De [`17/02` — Divisibilidad, §3](../17-matematica/02-divisibilidad.md#3--euclides).

```go
// Máximo común divisor por Euclides; gcd(0, 0) = 0. Go no lo trae para int (sí big.Int.GCD).
func gcd(a, b int64) int64 {
	if a < 0 {
		a = -a
	}
	if b < 0 {
		b = -b
	}
	for b != 0 {
		a, b = b, a%b
	}
	return a
}

func lcm(a, b int64) int64 { return a / gcd(a, b) * b } // dividir antes: el producto podría desbordar
```

### `17/02` — Euclides extendido

De [`17/02` — Divisibilidad, §4](../17-matematica/02-divisibilidad.md#4--euclides-extendido).

```go
// (g, x, y) con a*x + b*y = g. Iterativo: sin recursión.
func extGcd(a, b int64) (g, x, y int64) {
	x0, y0, x1, y1 := int64(1), int64(0), int64(0), int64(1)
	for b != 0 {
		q := a / b
		a, b = b, a-q*b
		x0, x1 = x1, x0-q*x1
		y0, y1 = y1, y0-q*y1
	}
	return a, x0, y0
}
```

### `17/02` — Diofánticas lineales

De [`17/02` — Divisibilidad, §5](../17-matematica/02-divisibilidad.md#5--diofánticas-lineales).

```go
// La división de Go trunca hacia cero: -7/2 es -3. floorDiv redondea hacia −∞, que es lo que pide
// la cuenta de soluciones.
func floorDiv(a, b int64) int64 {
	q := a / b
	if (a%b != 0) && ((a < 0) != (b < 0)) {
		q--
	}
	return q
}

// Soluciones (x, y) enteras con x, y >= 0 de a*x + b*y = c (a, b > 0), con extGcd de §4.
func countNonNegative(a, b, c int64) int64 {
	g, x, y := extGcd(a, b)
	if c%g != 0 {
		return 0
	}
	x0, y0, sx, sy := x*(c/g), y*(c/g), b/g, a/g
	lo := -floorDiv(x0, sx) // ⌈−x0 / sx⌉
	hi := floorDiv(y0, sy)
	return max(0, hi-lo+1)
}
```

### `17/03` — Exponenciación modular

De [`17/03` — Aritmética modular, §3](../17-matematica/03-aritmetica-modular.md#3--exponenciación-modular).

```go
import "math/bits"

// aᵉ mod m. Con m < 2³¹, el producto cabe en uint64; para m hasta 2⁶³, mulMod con bits.Mul64.
func mulMod(a, b, m uint64) uint64 {
	hi, lo := bits.Mul64(a, b)
	return bits.Rem64(hi, lo, m)
}

func powModU(a, e, m uint64) uint64 {
	result, a := 1%m, a%m
	for ; e > 0; e >>= 1 {
		if e&1 == 1 {
			result = mulMod(result, a, m)
		}
		a = mulMod(a, a, m)
	}
	return result
}
```

### `17/03` — Inverso modular

De [`17/03` — Aritmética modular, §4](../17-matematica/03-aritmetica-modular.md#4--inverso-modular).

```go
// Inverso de a módulo un primo p (Fermat), con powModU de §3.
func invFermat(a, p uint64) uint64 { return powModU(a, p-2, p) }

// Inverso de a módulo m con extGcd de 17/02 §4; ok = false si gcd(a, m) != 1.
func invExt(a, m int64) (int64, bool) {
	g, x, _ := extGcd(((a%m)+m)%m, m)
	if g != 1 {
		return 0, false
	}
	return ((x % m) + m) % m, true
}

// Los inversos de 1..n módulo un primo p > n, en Θ(n).
func inversesUpTo(n int, p int64) []int64 {
	inv := make([]int64, n+1)
	if n >= 1 {
		inv[1] = 1
	}
	for i := int64(2); i <= int64(n); i++ {
		inv[i] = (p - (p/i)*inv[p%i]%p) % p
	}
	return inv
}
```

### `17/04` — Criba de Eratóstenes

De [`17/04` — Primos, §3](../17-matematica/04-primos.md#3--criba-de-eratóstenes).

```go
// isPrime[i] para i en [0, n]. Θ(n log log n).
func sieve(n int) []bool {
	isPrime := make([]bool, n+1)
	for i := 2; i <= n; i++ {
		isPrime[i] = true
	}
	for p := 2; p*p <= n; p++ {
		if isPrime[p] {
			for q := p * p; q <= n; q += p { // empezar en p²: los menores ya están tachados
				isPrime[q] = false
			}
		}
	}
	return isPrime
}
```

### `17/04` — Criba lineal y menor factor primo

De [`17/04` — Primos, §4](../17-matematica/04-primos.md#4--criba-lineal-y-menor-factor-primo).

```go
// spf[x] = menor factor primo de x; primes = los primos hasta n. Θ(n).
func linearSieve(n int) (spf []int32, primes []int32) {
	spf = make([]int32, n+1)
	for i := 2; i <= n; i++ {
		if spf[i] == 0 {
			spf[i] = int32(i)
			primes = append(primes, int32(i))
		}
		for _, p := range primes {
			if p > spf[i] || i*int(p) > n {
				break
			}
			spf[i*int(p)] = p // cada compuesto se tacha una sola vez, por su menor primo
		}
	}
	return spf, primes
}

// Factorización de x <= n con la tabla spf: pares (primo, exponente). O(log x).
func factorize(x int, spf []int32) [][2]int {
	var f [][2]int
	for x > 1 {
		p, e := int(spf[x]), 0
		for x%p == 0 {
			x /= p
			e++
		}
		f = append(f, [2]int{p, e})
	}
	return f
}
```

### `17/05` — `nCr` con factoriales

De [`17/05` — Combinatoria, §3](../17-matematica/05-combinatoria.md#3--ncr-con-factoriales).

```go
// C(n, k) mod 1e9+7 con factoriales y sus inversos, precalculados hasta n. Usa powModU de 17/03 §3.
const MOD = 1_000_000_007

type Binomial struct{ fact, invFact []int64 }

func NewBinomial(n int) *Binomial {
	fact, invFact := make([]int64, n+1), make([]int64, n+1)
	fact[0] = 1
	for i := 1; i <= n; i++ {
		fact[i] = fact[i-1] * int64(i) % MOD // < 2⁶³: cabe en int64
	}
	invFact[n] = int64(powModU(uint64(fact[n]), MOD-2, MOD)) // un solo inverso, por Fermat
	for i := n; i > 0; i-- {
		invFact[i-1] = invFact[i] * int64(i) % MOD
	}
	return &Binomial{fact, invFact}
}

func (b *Binomial) C(n, k int) int64 {
	if k < 0 || k > n {
		return 0
	}
	return b.fact[n] * b.invFact[k] % MOD * b.invFact[n-k] % MOD
}
```

---

## 🧱 Bloque 18 — Geometría

### `18/01` — Vectores, punto y cruz

De [`18/01` — Vectores, productos y orientación, §3](../18-geometria/01-vectores-y-orientacion.md#3--vectores-punto-y-cruz).

```go
// Vectores con coordenadas enteras: con |x|, |y| <= 10⁹, la cruz cabe en int64 (hasta 4·10¹⁸).
type Pt struct{ X, Y int64 }

func sub(a, b Pt) Pt      { return Pt{a.X - b.X, a.Y - b.Y} }
func dot(a, b Pt) int64   { return a.X*b.X + a.Y*b.Y }
func cross(a, b Pt) int64 { return a.X*b.Y - a.Y*b.X }
```

### `18/01` — Orientación

De [`18/01` — Vectores, productos y orientación, §4](../18-geometria/01-vectores-y-orientacion.md#4--orientación).

```go
// +1 si a, b, c giran a la izquierda (antihorario), -1 a la derecha, 0 si están alineados. Exacto.
func orient(a, b, c Pt) int {
	v := cross(sub(b, a), sub(c, a))
	switch {
	case v > 0:
		return 1
	case v < 0:
		return -1
	}
	return 0
}

// ¿Está p dentro del triángulo abc o en su borde? Dentro si las tres orientaciones no tienen signos opuestos.
func inTriangle(a, b, c, p Pt) bool {
	s1, s2, s3 := orient(a, b, p), orient(b, c, p), orient(c, a, p)
	return !(min(s1, s2, s3) < 0 && max(s1, s2, s3) > 0)
}
```

### `18/01` — Enteros frente a épsilon

De [`18/01` — Vectores, productos y orientación, §5](../18-geometria/01-vectores-y-orientacion.md#5--enteros-frente-a-épsilon).

```go
// Signo con tolerancia, cuando las coordenadas son reales y no hay más remedio que float64.
func sgn(v, eps float64) int {
	switch {
	case v > eps:
		return 1
	case v < -eps:
		return -1
	}
	return 0
}
```

---

## 🧱 Bloque 19 — Aleatorizados y probabilísticos

### `19/04` — Fisher-Yates

De [`19/04` — Muestreo y cadenas de Markov, §3](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md#3--fisher-yates).

```go
import "math/rand"

// Barajado uniforme en el sitio: cada una de las n! permutaciones con probabilidad 1/n!. Θ(n).
// rand.Shuffle hace lo mismo.
func fisherYates(a []int, rng *rand.Rand) {
	for i := len(a) - 1; i > 0; i-- {
		j := rng.Intn(i + 1) // j en [0, i], incluido i
		a[i], a[j] = a[j], a[i]
	}
}
```

---

## 🧱 Bloque 20 — Ad hoc, constructivos e interactivos

### `20/01` — Invariantes y paridad

De [`20/01` — Ad hoc y simulación, §3](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#3--invariantes-y-paridad).

```go
// Paridad de una permutación de 0..n−1: 0 si par, 1 si impar. Hacen falta n − (número de ciclos) intercambios.
func permutationParity(p []int) int {
	seen := make([]bool, len(p))
	cycles := 0
	for i := range p {
		if seen[i] {
			continue
		}
		cycles++
		for j := i; !seen[j]; j = p[j] {
			seen[j] = true
		}
	}
	return (len(p) - cycles) % 2
}
```

### `20/01` — Simulación

De [`20/01` — Ad hoc y simulación, §4](../20-ad-hoc-constructivos-e-interactivos/01-ad-hoc-y-simulacion.md#4--simulación).

```go
// Estado tras k aplicaciones de f desde x0, saltando el ciclo en cuanto un estado se repite.
func iterate(x0, k int64, f func(int64) int64) int64 {
	firstSeen := map[int64]int64{}
	x := x0
	for step := int64(0); step < k; step++ {
		if prev, ok := firstSeen[x]; ok { // el estado x ya salió en el paso prev
			cycle := step - prev
			for r := (k - step) % cycle; r > 0; r-- {
				x = f(x)
			}
			return x
		}
		firstSeen[x] = step
		x = f(x)
	}
	return x
}
```

---

## 🧱 Bloque 22 — Teoría de la computación (opcional)

### `22/03` — La máquina de Turing y su simulación

De [`22/03` — Máquinas de Turing y decidibilidad, §3](../22-teoria-de-la-computacion/03-maquinas-de-turing-y-decidibilidad.md#3--la-máquina-de-turing-y-su-simulación).

```go
// Simula una MT de una cinta desde el estado 0 con la cinta como dos pilas. delta[estado][símbolo] =
// regla; move -1 izquierda, +1 derecha. Devuelve el estado final (-1 si agotó limit), los pasos y la cinta.
type Rule struct {
	Write byte
	Move  int
	Next  int
}

func runTM(delta map[[2]int]Rule, halt int, tape string, blank byte, limit int64) (int, int64, string) {
	left := []byte{}
	right := []byte{} // la cima de cada pila toca la cabeza
	for i := len(tape) - 1; i >= 0; i-- {
		right = append(right, tape[i])
	}
	cur := blank
	if len(right) > 0 {
		cur, right = right[len(right)-1], right[:len(right)-1]
	}
	q, steps := 0, int64(0)
	for ; q != halt; steps++ {
		if steps == limit {
			return -1, steps, ""
		}
		r, ok := delta[[2]int{q, int(cur)}]
		if !ok {
			break // sin transición: se detiene
		}
		from, to := &left, &right
		if r.Move > 0 {
			from, to = &right, &left
		}
		*to = append(*to, r.Write) // la celda escrita queda del lado contrario al movimiento
		if len(*from) == 0 {
			cur = blank // pila vacía: cinta en blanco, la cinta crece sola
		} else {
			cur, *from = (*from)[len(*from)-1], (*from)[:len(*from)-1]
		}
		q = r.Next
	}
	out := append(append([]byte{}, left...), cur)
	for i := len(right) - 1; i >= 0; i-- {
		out = append(out, right[i])
	}
	return q, steps, string(out)
}
```

### `22/04` — P y NP por certificados

De [`22/04` — P, NP y reducciones, §3](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md#3--p-y-np-por-certificados).

```go
// Verificador de NP para la cobertura de vértices: ¿cover es una cobertura de tamaño <= k? O(n + m).
func verifyCover(n int, edges [][2]int, cover []int, k int) bool {
	if len(cover) > k {
		return false
	}
	in := make([]bool, n)
	for _, v := range cover {
		in[v] = true
	}
	for _, e := range edges {
		if !in[e[0]] && !in[e[1]] {
			return false // arista sin cubrir
		}
	}
	return true
}
```

### `22/05` — Qué hacer con un NP-difícil

De [`22/05` — NP-completitud, §6](../22-teoria-de-la-computacion/05-np-completitud.md#6--qué-hacer-con-un-np-difícil).

```go
// ¿Hay ciclo hamiltoniano? adj[v] = máscara de vecinos de v. reach[mask] = vértices donde puede acabar
// un camino que empieza en 0 y visita exactamente mask. O(2ⁿ · n) tiempo, 2ⁿ enteros; n <= 24.
func hamiltonianCycle(adj []uint32) bool {
	n := len(adj)
	if n < 3 {
		return false
	}
	reach := make([]uint32, 1<<n)
	reach[1] = 1                                    // el camino «0» termina en 0
	for mask := uint32(3); mask < 1<<n; mask += 2 { // máscaras con el 0 y algo más
		for w := 1; w < n; w++ {
			if mask>>w&1 == 1 && reach[mask^(1<<w)]&adj[w] != 0 {
				reach[mask] |= 1 << w // se llega a w desde un vecino
			}
		}
	}
	return reach[1<<n-1]&adj[0] != 0 // algún final vuelve a 0
}
```
