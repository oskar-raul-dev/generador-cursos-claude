# 05 — Simulación

> El examen del bloque `08`: preguntas que cruzan montículos, sus patrones, los fusionables y Union-Find;
> cuatro problemas propios cronometrados que no dicen de qué capítulo son, y seis problemas externos que
> no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](06-respuestas.md#05--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para cada uno de los dos primeros problemas
  y 20 para los otros dos.
- **En voz alta.** Antes de cada problema, di si los datos llegan de uno en uno o están todos desde el
  principio, y si los grupos solo se unen: son las dos preguntas que deciden la estructura.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Montículos

**S1.** ¿Qué cuesta construir un montículo con `heapify`, y por qué no `O(n log n)`? 🟡

**S2.** ¿Qué da por defecto `std::priority_queue`, `PriorityQueue` y `heapq`? 🟢

**S3.** ¿Qué haces cuando necesitas `decrease-key` con la cola de tu biblioteca? 🟡

### Patrones

**S4.** ¿Qué montículo y de qué tamaño usas para los `k` mayores de un flujo? 🟢

**S5.** ¿Cuánto cuesta mezclar `k` listas ordenadas con `N` elementos en total? 🟢

**S6.** ¿Qué invariantes mantienen los dos montículos de la mediana? 🟡

### Fusionables

**S7.** ¿Por qué el montículo de Fibonacci casi nunca gana a un binario en Dijkstra? 🟡

### Union-Find

**S8.** ¿Qué dos mejoras necesita Union-Find para `O(α(n))`? 🟢

**S9.** ¿Cómo detectas con Union-Find la primera arista que cierra un ciclo? 🟢

**S10.** ¿Qué guarda el Union-Find con pesos y para qué sirve? 🟡

### Las que descolocan

**S11.** Tu Dijkstra con `PriorityQueue` da WA y metes la misma arista varias veces. ¿Qué te falta al sacar de la cola? 🟠

**S12.** «Para los `k` mayores ordeno todo.» ¿Cuándo es la mejor respuesta y cuándo no? 🟠

**S13.** Tu Union-Find en Java da `StackOverflowError` con `n = 10⁶`. ¿Por qué, si es casi constante? 🟠

**S14.** Imprimes una `PriorityQueue` para depurar y no sale ordenada. ¿Es un error? 🟠

**S15.** Te piden «grupos que se separan» además de grupos que se unen. ¿Qué preguntas antes de elegir estructura? 🟠

**S16.** Demuestra que con unión por tamaño la altura de los árboles de Union-Find es como mucho `log₂ n`. 🔴

**S17.** Demuestra que `heapify` es `O(n)`. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Islas que crecen

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** no recontar las islas desde cero tras cada cambio.

Un mapa de `R × C` empieza todo agua. Llegan `q` celdas que se convierten en tierra (pueden repetirse).
Tras cada una, imprime el número de islas (grupos de tierra conectados en horizontal o vertical).

- **Entrada.** Una línea con `R`, `C` y `q`. Después, `q` líneas con `fila columna` (0-indexadas).
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ R · C ≤ 10⁶`; `1 ≤ q ≤ 2·10⁵`.

```text
Entrada            Salida
3 3 5              1 2 1 2 1
0 0
0 2
0 1
2 2
1 2

Entrada            Salida
1 1 2              1 1
0 0
0 0
```

**Pista 1:** cuando una celda se vuelve tierra, ¿qué islas pueden cambiar, y cómo?

### Mediana de las pujas

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** mantener el centro sin reordenar.

En una subasta llegan `n` pujas. Tras cada una, imprime la mediana inferior de las recibidas (la de posición
`⌊(i − 1)/2⌋` en orden, con `i` pujas).

- **Entrada.** Una línea con `n`. Una línea con las `n` pujas.
- **Salida.** `n` enteros.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ puja ≤ 10⁹`.

```text
Entrada            Salida
6                  5 2 5 2 5 5
5 2 9 1 5 6

Entrada            Salida
2                  1000000000 1
1000000000 1
```

**Pista 1:** ¿qué dos valores tienes que poder leer en todo momento para conocer la mediana?

### Registros mezclados

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** aprovechar que cada registro ya está ordenado.

Hay `k` registros, cada uno con sus marcas de tiempo en orden creciente. Imprime todas las marcas en orden
global, cada una con el número del registro del que viene (1-indexado); a igual marca, primero el registro
de menor número.

- **Entrada.** Una línea con `k`. Después, `k` líneas: la longitud y las marcas de cada registro.
- **Salida.** Una línea por marca: `marca registro`.
- **Restricciones.** `1 ≤ k ≤ 10⁵`; suma de longitudes `≤ 10⁶`.

```text
Entrada            Salida
3                  1 1
3 1 5 9            2 2
2 2 5              5 1
1 5                5 2
                   5 3
                   9 1

Entrada            Salida
2                  4 1
2 4 4              4 1
1 4                4 2
```

**Pista 1:** ¿cuántos candidatos hay que comparar para saber cuál es la siguiente marca global?

### Reparto de premios

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** ver que no hace falta ninguna estructura dinámica.

Hay `n` puntuaciones y `q` consultas `k`: ¿cuánto suman las `k` mayores?

- **Entrada.** Una línea con `n` y `q`. Una línea con las `n` puntuaciones. Después, `q` líneas con `k`.
- **Salida.** `q` enteros.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `1 ≤ k ≤ n`; `1 ≤ puntuación ≤ 10⁹`.

```text
Entrada                Salida
6 3                    9
5 2 9 1 5 6            20
1                      28
3
6

Entrada                Salida
2 1                    2000000000
1000000000 1000000000
2
```

**Pista 1:** si respondes cada consulta con un montículo, ¿cuánto cuesta con `q = n = 2·10⁵`? ¿Y si los datos no
cambian nunca?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Smallest String With Swaps](https://leetcode.com/problems/smallest-string-with-swaps/) | LeetCode | 🟡 | Si puedes intercambiar `a` con `b` y `b` con `c`, ¿qué posiciones pueden recibir cualquier letra de las otras? |
| [ ] | [Lexicographically Smallest Equivalent String](https://leetcode.com/problems/lexicographically-smallest-equivalent-string/) | LeetCode | 🟡 | Dentro de un grupo de letras equivalentes, ¿cuál conviene usar siempre? |
| [ ] | [Regions Cut By Slashes](https://leetcode.com/problems/regions-cut-by-slashes/) | LeetCode | 🟡 | Si divides cada celda en cuatro triángulos, ¿qué une cada símbolo? |
| [ ] | [Journey to the Moon](https://www.hackerrank.com/challenges/journey-to-the-moon/problem) | HackerRank | 🟡 | Con los tamaños de los grupos, ¿cuántos pares hay de astronautas de países distintos? |
| [ ] | [K-th Smallest Prime Fraction](https://leetcode.com/problems/k-th-smallest-prime-fraction/) | LeetCode | 🟡 | Para cada numerador, las fracciones forman una lista ordenada: ¿qué haces con `k` listas ordenadas? |
| [ ] | [Maximum Subsequence Score](https://leetcode.com/problems/maximum-subsequence-score/) | LeetCode | 🟡 | Si fijas qué elemento da el mínimo, ¿qué `k − 1` compañeros te conviene? |

---

## ✅ Las frases que hay que tener listas

> «Para los `k` mayores, un montículo de **mínimos** de tamaño `k`: `O(n log k)` y `O(k)` de memoria.»

> «Mi cola de prioridad no tiene `decrease-key`: meto la entrada nueva y descarto las viejas al sacarlas.»

> «Union-Find con compresión y unión por tamaño: `O(α(n))` amortizado, que en la práctica es constante.»

---

**Anterior:** [`08/04` — Union-Find](04-union-find.md) · **Siguiente:** [`08/06` — Respuestas](06-respuestas.md) ·
**Relacionado:** [`08/02` — Patrones con *heap*](02-patrones-con-heap.md).
