# 06 — Árbol cartesiano y *wavelet tree*

> Dos estructuras que conviene reconocer: el árbol cartesiano, que convierte el mínimo de un tramo en el
> ancestro común de dos nodos (y se construye en `O(n)` con una pila), y el *wavelet tree*, que responde el
> `k`-ésimo menor, el número de apariciones o cuántos valores caen en un rango, dentro de cualquier tramo,
> en `O(log V)`.
>
> **Niveles:** árbol cartesiano [C] · *wavelet tree* [C].
>
> **📚 Lectura troncal:** cp-algorithms, [*Linear RMQ*](https://cp-algorithms.com/graph/rmq_linear.html);
> Navarro, *Compact Data Structures* (Cambridge University Press, 2016), el capítulo de *wavelet trees*.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--árbol-cartesiano) · [4](#4--wavelet-tree) · [5](#5--cómo-se-elige) · [6](#6--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Dos preguntas que el bloque ha ido tocando de lado:

- **¿Son lo mismo el mínimo de un tramo y el ancestro común de dos nodos?** El LCA se resolvió con un RMQ
  sobre el recorrido de Euler (`07/05`). El árbol cartesiano cierra el círculo: todo RMQ es un LCA en un
  árbol construido en `O(n)`. Los dos problemas son el mismo.
- **¿Cuál es el `k`-ésimo menor de `a[l..r]`, y cuántas veces aparece `x` en él?** El segment tree
  persistente lo responde ([`09/04`](04-segment-tree-avanzado.md)), con mucha memoria. El *wavelet tree* lo hace con `O(n log V)` bits y
  un código más corto.

Este capítulo es de fichas: lo que interesa es saber que existen, qué responden y cómo se relacionan con lo
que ya está en el bloque.

---

## 2. 📐 La teoría

**El árbol cartesiano** de un arreglo (de mínimos) tiene como raíz la posición del mínimo; su subárbol
izquierdo es el árbol cartesiano de lo que queda a la izquierda, y el derecho, el de la derecha. Es a la vez
un BST por las **posiciones** y un montículo por los **valores**: un *treap* en el que las prioridades son
los valores ([`07/03`](../07-arboles/03-arboles-aleatorizados.md)).

**Teorema (RMQ = LCA).** En el árbol cartesiano de mínimos de `a`, el mínimo de `a[l..r]` está en la
posición `LCA(l, r)`.

*Prueba.* El LCA de `l` y `r` es el primer nodo, bajando desde la raíz, que separa a `l` y `r` (o es uno de
ellos). Por la construcción recursiva, ese nodo es el mínimo de un tramo que contiene a `[l, r]` y su posición
está entre `l` y `r`: es el mínimo de `[l, r]`. Recíprocamente, con el recorrido de Euler, todo LCA es un RMQ
(`07/05`). Los dos problemas se reducen el uno al otro en tiempo lineal.

**La construcción con pila.** Recorriendo de izquierda a derecha, una pila guarda la **rama derecha** del
árbol actual (valores crecientes). Al llegar `a[i]`, se sacan los mayores; el último sacado pasa a ser hijo
izquierdo de `i`, e `i` pasa a ser hijo derecho de la nueva cima. Es la pila monótona de `06/01`: `O(n)`.

**El *wavelet tree*** parte el rango de valores `[0, V)` por la mitad en cada nivel. Cada nodo guarda, para
la subsecuencia de valores que le llegan (en el orden original), un arreglo de bits: 0 si el valor va a la
mitad baja, 1 si va a la alta, con sus prefijos. Con esos prefijos, un tramo `[l, r)` del nodo se traduce al
tramo correspondiente de cada hijo en `O(1)`. Altura `log V`.

---

## 3. 🧱 Árbol cartesiano

- **Qué resuelve.** Reducir RMQ a LCA (y al revés); calcular para cada elemento el tramo en el que es el
  mínimo; es la forma de un *treap* con prioridades dadas.
- **Qué garantiza.** Construcción en `O(n)` con una pila monótona; el mínimo de `a[l..r]` es el LCA de `l` y
  `r`.
- **Cuánto.** Tres arreglos (`padre`, `izq`, `der`).
- **Cómo reconocerlo.** «Para cada elemento, ¿en cuántos tramos es el mínimo?» (el tamaño de sus subárboles);
  divide y vencerás por el mínimo («parte el arreglo por el menor y recursa a los dos lados») sin recursión
  cuadrática; la teoría de RMQ en `O(n)`/`O(1)`.
- **Si no te la sabes.** Para RMQ, la *sparse table* ([`09/01`](01-sparse-table.md)); para «el tramo donde es mínimo», anterior y
  siguiente menor con la pila monótona (`06/01`).
- **Dónde está entera.** cp-algorithms, [*Linear RMQ*](https://cp-algorithms.com/graph/rmq_linear.html)
  (Farach-Colton y Bender).

**Cómo va**, sobre `[5, 2, 9, 1, 5, 6]`:

```text
i  a[i]  pila (valores)    efecto
0  5     [5]
1  2     [2]               saca 5 → 5 es hijo izquierdo de 2
2  9     [2, 9]            9 es hijo derecho de 2
3  1     [1]               saca 9 y 2 → 2 es hijo izquierdo de 1
4  5     [1, 5]            5 (pos. 4) es hijo derecho de 1
5  6     [1, 5, 6]         6 es hijo derecho de 5
raíz: 1 (pos. 3).  min(a[0..2]) = LCA(0, 2) = pos. 1 (el 2)
```

---

## 4. 🧱 *Wavelet tree*

- **Qué resuelve.** Sobre un arreglo estático: el `k`-ésimo menor de `a[l..r]`, cuántas veces aparece `x`
  en `a[l..r]`, cuántos valores de `a[l..r]` están en `[x, y]`.
- **Qué garantiza.** `O(log V)` por consulta, *online*; construcción `O(n log V)`.
- **Cuánto.** `O(n log V)` enteros en la versión de concurso (prefijos como enteros); `n log V` bits en la
  versión compacta.
- **Cómo reconocerlo.** «El `k`-ésimo menor del tramo», «la mediana del tramo», «cuántos entre `x` e `y`
  en el tramo», muchas consultas y sin actualizaciones.
- **Si no te la sabes.** Persistente sobre valores (`09/04`); *offline*, búsqueda binaria paralela o un
  *merge sort tree* con binaria (`O(log³ n)`).
- **Dónde está entera.** Navarro, *Compact Data Structures*, el capítulo de *wavelet trees*; Grossi, Gupta y
  Vitter, «High-Order Entropy-Compressed Text Indexes», SODA 2003 (la estructura original).

**Cómo va**, el `k`-ésimo con `k = 3` en todo `[5, 2, 9, 1, 5, 6]` (valores `1..9`, partidos en `1..5` y
`6..9`):

```text
raíz: bits 0 0 1 0 0 1   (5, 2, 1, 5 van abajo; 9, 6 arriba)    ceros en el tramo: 4 ≥ 3 → baja a la mitad baja
nivel 1, valores 1..5 en orden: 5 2 1 5 → partido en 1..3 y 4..5: bits 1 0 0 1
   ceros: 2 < 3 → sube a la mitad alta con k = 3 − 2 = 1
nivel 2, valores 4..5: 5 5 → el primero es 5
el 3.er menor es 5
```

---

## 5. 🧭 Cómo se elige

| Pregunta | Estructura | Coste | Alternativa |
|---|---|---|---|
| Mínimo de un tramo estático | *Sparse table* | `O(1)` | Árbol cartesiano + LCA (teoría `O(n)`/`O(1)`) |
| Tramo donde cada elemento es mínimo | Pila monótona (`06/01`) | `O(n)` | Árbol cartesiano |
| `k`-ésimo de `a[l..r]`, *online* | *Wavelet tree* | `O(log V)` | Persistente (`09/04`) |
| Apariciones de `x` en `a[l..r]` | Posiciones por valor + binaria | `O(log n)` | *Wavelet tree* |
| Cuántos en `[x, y]` dentro de `a[l..r]`, *online* | *Wavelet tree* | `O(log V)` | *Merge sort tree* `O(log² n)` |

---

## 6. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Divide por el mínimo y recursa a los lados» | Árbol cartesiano | La recursión es el árbol |
| «Para cada elemento, en cuántos subarreglos es el mínimo» | Árbol cartesiano o pila monótona | Tamaños de sus subárboles |
| «`k`-ésimo menor en `[l, r]`», sin cambios, muchas consultas | *Wavelet tree* | `O(log V)` *online* |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «RMQ y LCA son problemas distintos» | Se reducen el uno al otro en lineal: árbol cartesiano en un sentido, recorrido de Euler en el otro |
| «Construir el árbol cartesiano es `O(n log n)`» | Con la pila monótona, `O(n)` |
| «El *wavelet tree* admite actualizaciones» | La versión básica es estática; las dinámicas son mucho más complejas |
| «Para el `k`-ésimo de un tramo hay que ordenarlo» | `O(log V)` con *wavelet* o persistente |

---

## 📚 Para profundizar

- **Referencia** — cp-algorithms, [*Linear RMQ*](https://cp-algorithms.com/graph/rmq_linear.html): árbol
  cartesiano y la reducción RMQ ↔ LCA. *Lectura troncal.*
- **Libro** — Navarro, *Compact Data Structures* (Cambridge University Press, 2016), el capítulo de
  *wavelet trees*. *Lectura troncal.*
- **Artículo** — Bender y Farach-Colton, «The LCA Problem Revisited», LATIN 2000.

---

## 🧠 Preguntas

1. ¿Qué dos propiedades tiene a la vez un árbol cartesiano? 🟢
2. ¿Qué responde un *wavelet tree*? 🟢
3. ¿Cómo se construye el árbol cartesiano con una pila? 🟢
4. ¿Por qué el árbol cartesiano es un *treap*? 🟡
5. ¿Qué guarda cada nodo de un *wavelet tree* y cómo se baja un tramo de un nodo a su hijo? 🟡
6. ¿Cómo se encuentra el `k`-ésimo menor de `a[l..r]` con un *wavelet tree*? 🟡
7. Demuestra que el mínimo de `a[l..r]` está en el LCA de `l` y `r` en el árbol cartesiano. 🟠
8. ¿Por qué la construcción con pila es `O(n)`? 🟠
9. ¿Cómo cuentas con un *wavelet tree* los valores de `a[l..r]` que caen en `[x, y]`? 🟠
10. Compara para el `k`-ésimo de un tramo el *wavelet tree*, el persistente y el *merge sort tree*: memoria y tiempo en C++ o Java. 🟠
11. Con el árbol cartesiano, ¿cómo calculas en cuántos subarreglos es mínimo cada elemento? 🟠
12. ¿Cómo se obtiene RMQ en `O(n)`/`O(1)` a partir del árbol cartesiano? 🔴

---

## 🧩 Problemas propios

### El árbol de los mínimos

**Nivel:** 🟡 · **Formato:** programa completo.

Imprime, para cada posición (0-indexada), su padre en el árbol cartesiano de mínimos del arreglo (`-1` para
la raíz). Los valores son distintos.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores.
- **Salida.** `n` enteros.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; valores distintos.

```text
Entrada            Salida
6                  1 3 1 -1 3 4
5 2 9 1 4 6

Entrada            Salida
4                  -1 0 1 2
1 2 3 4
```

**Pista 1:** al recorrer de izquierda a derecha, ¿qué nodos pueden todavía recibir un hijo derecho?

### El `k`-ésimo del tramo

**Nivel:** 🟠 · **Formato:** programa completo.

Para cada consulta `l r k` (0-indexada, inclusiva), imprime el `k`-ésimo menor (1-indexado) de `a[l..r]`.

- **Entrada.** Una línea con `n` y `q`. Una línea con los valores. Después, `q` líneas con `l r k`.
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; valores entre 1 y `10⁹`; `1 ≤ k ≤ r − l + 1`.

```text
Entrada            Salida
6 3                5
5 2 9 1 5 6        1
0 5 3              5
1 4 1
2 5 2

Entrada            Salida
3 2                1000000000
4 4 1000000000     4
0 2 3
0 1 2
```

**Pista 1:** si supieras cuántos de `a[l..r]` van a la mitad baja de los valores, ¿a qué mitad bajarías?

---

## 🧩 Práctica externa

Las tres bases no llegan a estas estructuras; la práctica está en Library Checker y Codeforces. La
plataforma que se previó (SPOJ) no admite la verificación automática de enlaces.

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Cartesian Tree](https://judge.yosupo.jp/problem/cartesian_tree) | Library Checker | 🟡 | Construcción con pila | Al llegar un valor menor que la cima, ¿qué nodos dejan de poder recibir un hijo derecho? |
| [ ] | [Static Range Frequency](https://judge.yosupo.jp/problem/static_range_frequency) | Library Checker | 🟠 | Apariciones en un tramo | ¿Qué guardas por valor para contar sus apariciones en `[l, r)` con dos búsquedas? |
| [ ] | [Destiny](https://codeforces.com/problemset/problem/840/D) | Codeforces | 🔴 | Valores frecuentes en un tramo | Si un valor aparece más de `len/k` veces, ¿en qué posiciones del tramo ordenado tiene que estar? |

---

## ✅ Criterio de dominio

- Construir el árbol cartesiano con una pila y explicar la reducción RMQ ↔ LCA.
- Decir qué responde el *wavelet tree* y cómo baja un tramo de nivel en nivel.
- Elegir entre *wavelet*, persistente y *merge sort tree* para el `k`-ésimo de un tramo.

---

**Anterior:** [`09/05` — Raíz cuadrada y Mo](05-raiz-cuadrada-y-mo.md) · **Siguiente:** [`09/07` — Simulación](07-simulacion.md) ·
**Relacionado:** [`07/05` — LCA](../07-arboles/05-lca.md); [`06/01` — Pila, cola, deque y sus versiones monótonas](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md).
