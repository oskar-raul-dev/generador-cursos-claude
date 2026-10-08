# 07 — Simulación

> El examen del bloque `03`: preguntas que cruzan las librerías de C++, Java, Python, Go y JavaScript;
> tres problemas propios cronometrados que no dicen de qué capítulo son, y seis problemas externos que
> no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 25 minutos para cada problema propio.
- **En tu lenguaje y en otro.** Cada problema propio se resuelve en tu lenguaje y después se traduce a
  uno de los otros dos, revisando cada estructura contra la tabla de `03/05`.
- **Tecleando de verdad**, con la plantilla de E/S de [`01/03`](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md).
- **Solo después, el solucionario.** Si fallas una pregunta de un lenguaje que no es el tuyo, anótalo
  igual: es lo que verás al leer código ajeno.

---

## 🧠 Preguntas

### Contenedores y colecciones

**S1.** ¿Qué devuelve `std::map::operator[]` con una clave que no existe, y qué efecto secundario tiene? 🟢

**S2.** ¿Qué colección de Java usas como pila, y cuál como cola? 🟢

**S3.** ¿Por qué `std::lower_bound(s.begin(), s.end(), x)` sobre un `std::set` es lento? 🟡

**S4.** ¿Qué diferencia hay entre `HashMap` y `TreeMap` en Java, en coste y en lo que permiten? 🟡

**S5.** ¿Cuándo un `vector` ordenado gana a un `set`? 🟠

### Algoritmos de la librería

**S6.** ¿Qué condición tiene que cumplir el comparador de `std::sort`? 🟢

**S7.** ¿Qué diferencia hay entre `nth_element` y `partial_sort`? 🟡

**S8.** ¿Por qué `std::accumulate(v.begin(), v.end(), 0)` puede desbordar con `v` de `long long`? 🟡

**S9.** ¿Qué garantiza `Arrays.sort` sobre `int[]` en Java 21, y qué cambia en Java 11? 🟠

### Python

**S10.** ¿Por qué `list.pop(0)` no sirve para una cola? 🟢

**S11.** ¿Cómo haces un montículo de máximos con `heapq` en Python 3.12? 🟡

**S12.** ¿Qué haces en Python cuando necesitas un mapa ordenado con inserciones y borrados? 🟠

**S13.** Una recursión de profundidad `10⁵` da RE en Python con el límite subido. ¿Qué falta? 🟠

### Go y JavaScript

**S14.** ¿Qué da `[10, 9, 1].sort()` en JavaScript? 🟢

**S15.** ¿Por qué no se llama a `h.Pop()` directamente sobre un montículo de `container/heap`? 🟡

**S16.** ¿Por qué `(a * b) % MOD` falla en JavaScript con `a` y `b` cerca de `10⁹`? 🟠

### Las que descolocan

**S17.** Traduces de C++ a Java un Dijkstra con `priority_queue` y `-dist`. Compila y da distancias incorrectas. ¿Qué pasó? 🟠

**S18.** Tu solución Java compara dos conteos de un `HashMap` con `==` y pasa los ejemplos. ¿Por qué falla en el caso grande? 🟠

**S19.** ¿Y si `n` fuera `10⁶` y tu lenguaje fuera Python? Para una cola con `10⁶` operaciones, ¿qué cambia en tu código? 🟠

**S20.** Un *multiset* de C++ con `erase(x)` da WA solo cuando hay repetidos. ¿Por qué no lo detectaron los ejemplos? 🟠

**S21.** «Python no tiene `TreeMap`, así que no se puede usar en pruebas con mapas ordenados.» Corrige la frase con tres sustitutos y cuándo vale cada uno. 🔴

**S22.** Escribe el patrón de eliminación perezosa para una cola de prioridad sin `decrease-key`, y por qué no rompe la corrección. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Almacén de tallas

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** traducir un *multiset* entre lenguajes sin borrar de más.

Un almacén guarda piezas por talla. Operaciones: `+ x` añade una pieza de talla `x`; `- x` retira
**una** pieza de talla `x` (se garantiza que existe); `? x` imprime la menor talla guardada `≥ x`, o
`-1`.

- **Entrada.** Una línea con `q`. Después, `q` líneas con una operación.
- **Salida.** Una línea por cada `?`.
- **Restricciones.** `1 ≤ q ≤ 2·10⁵`; `1 ≤ x ≤ 10⁹`.

```text
Entrada            Salida
8                  5
+ 5                5
+ 5                -1
+ 2
? 3
- 5
? 3
- 5
? 3

Entrada            Salida
4                  -1
? 1                1000000000
+ 1000000000       1000000000
? 1
? 1000000000
```

**Pista 1:** después de retirar una pieza de 5 cuando había dos, ¿qué tiene que responder la siguiente
consulta?

### Cola de la ventanilla

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** elegir la estructura de la cola; el algoritmo es una simulación directa.

`n` personas hacen cola, numeradas de 1 a `n`; la persona `i` quiere `t[i]` entradas. En cada turno, la
primera de la cola compra una entrada; si aún le faltan, vuelve al final. Imprime el orden en que las
personas terminan.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores `t[i]`.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ t[i]`; `Σ t[i] ≤ 10⁶`. Límite: 1 segundo.

```text
Entrada            Salida
3                  2 1 3
2 1 3

Entrada            Salida
1                  1
5
```

**Pista 1:** ¿cuántas veces sacas a alguien del principio de la cola en total, y cuánto cuesta cada
vez en tu estructura?

🔥 **Para el geek — en JavaScript:** con `shift()` son hasta `10⁶` extracciones lineales; la cola con
índice de cabeza cambia el diseño.

### Frecuencias gemelas

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que con `n ≤ 2000` la comparación directa basta, y comparar valores y no
referencias.

Dado un arreglo, cuenta los pares no ordenados de **valores distintos** que aparecen el mismo número de
veces.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2000`; `1 ≤ a[i] ≤ 10⁹`.

```text
Entrada            Salida
6                  6
5 2 9 1 5 6

Entrada            Salida
2                  0
7 7
```

**Pista 1:** con `n ≤ 2000`, ¿cuántos pares de valores distintos puede haber como mucho, y cuesta
compararlos todos?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Kth Largest Element in a Stream](https://leetcode.com/problems/kth-largest-element-in-a-stream/) | LeetCode | 🟢 | ¿Cuántos elementos necesitas guardar de verdad para responder? |
| [ ] | [Collections.OrderedDict()](https://www.hackerrank.com/challenges/py-collections-ordereddict/problem) | HackerRank | 🟢 | ¿Qué estructura de Python recuerda el orden de primera aparición? |
| [ ] | [Majority Element II](https://leetcode.com/problems/majority-element-ii/) | LeetCode | 🟡 | ¿Cuántos valores, como mucho, pueden aparecer más de `n/3` veces? |
| [ ] | [Minimum Number of Arrows to Burst Balloons](https://leetcode.com/problems/minimum-number-of-arrows-to-burst-balloons/) | LeetCode | 🟡 | Los extremos llegan a `±2³¹`: ¿qué hace tu comparador con ellos? |
| [ ] | [Josephus Problem I](https://cses.fi/problemset/task/2162) | CSES | 🟡 | Si cada niño que se salva vuelve al final, ¿qué estructura simula el círculo? |
| [ ] | [Sum of Two Values](https://cses.fi/problemset/task/1640) | CSES | 🟡 | ¿Qué estructura de tu lenguaje te dice al instante si el complemento ya apareció, y con qué índice? |

---

## ✅ Las frases que hay que tener listas

> «C++ da el máximo en su cola de prioridad; Java y Python, el mínimo. Al traducir, lo primero que
> reviso es eso.»

> «En C++, una copia de un `multiset` se borra con `erase(find(x))`; en Java, decremento el conteo del
> `TreeMap` y borro la clave al llegar a cero.»

> «En Python, la cola es un `deque`: `pop(0)` desplaza la lista entera.»

---

**Anterior:** [`03/06` — Competir sin arsenal: Go y JavaScript](06-sin-arsenal-go-y-javascript.md) ·
**Siguiente:** [`03/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`03/05` — La tabla de equivalencias](05-equivalencias-entre-lenguajes.md).
