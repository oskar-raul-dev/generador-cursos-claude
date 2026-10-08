# 07 — Simulación

> El examen del bloque `10`: preguntas que cruzan recursión, enumeración, *backtracking*, partir en
> mitades, divide y vencerás, NP y juegos; cuatro problemas propios cronometrados que no dicen de qué
> capítulo son, y cinco problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas
> 2 y 3 están en el [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 25 minutos para cada problema propio, 15 para el más
  corto.
- **En voz alta.** Antes de cada problema, haz la cuenta de casos con el `n` máximo: `2ⁿ`, `n!`, `C(n, k)`,
  `2^(n/2)`, `log n`. Esa cuenta elige la técnica antes que cualquier idea brillante.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de las dos mitades
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Recursión

**S1.** ¿Qué dos costes tiene una recursión, y cuál de los dos tumba un envío con `n = 2·10⁵`? 🟢

**S2.** ¿Por qué subir `sys.setrecursionlimit` no basta siempre en Python? 🟡

**S3.** ¿Qué guarda un marco de la pila explícita cuando la recursión tiene dos llamadas con trabajo entre ellas? 🟡

### Enumeración

**S4.** ¿Hasta qué `n` se enumeran subconjuntos, permutaciones y combinaciones en un segundo? 🟢

**S5.** ¿Por qué `next_permutation` necesita empezar con el arreglo ordenado? 🟢

**S6.** ¿Qué te da `m & (m − 1)` y para qué lo usas? 🟢

### *Backtracking* y poda

**S7.** ¿Qué hipótesis tiene que cumplir una poda para no perder soluciones? 🟡

**S8.** ¿Qué pasa si una rama del *backtracking* no deshace lo que hizo? 🟡

**S9.** ¿Qué cota usa la ramificación y poda de la mochila 0/1, y por qué es válida? 🟡

### Mitades y búsqueda iterativa

**S10.** ¿Qué número del enunciado delata *meet in the middle*, y qué exige de la condición? 🟢

**S11.** ¿Qué gana IDDFS frente a BFS y qué paga? 🟡

### Divide y vencerás y NP

**S12.** ¿Qué recurrencia tiene Karatsuba y qué da? 🟢

**S13.** ¿Qué invariante mantiene la exponenciación rápida? 🟡

**S14.** ¿Qué significa NP y qué **no** significa? 🟡

**S15.** ¿Por qué la mochila con DP `O(n · W)` es pseudopolinomial? 🟠

### Juegos

**S16.** ¿Alfa-beta devuelve el mismo valor que minimax? ¿Por qué? 🟡

**S17.** ¿Qué ventana pasa *negamax* con alfa-beta a la llamada del rival? 🟠

### Las que descolocan

**S18.** «Es exponencial, así que no puede ser la solución.» El enunciado dice `n ≤ 18`. ¿Qué respondes? 🟠

**S19.** Tu *backtracking* de suma de subconjuntos da menos soluciones que la fuerza bruta en cuanto aparecen pesos negativos. ¿Qué miras? 🟠

**S20.** Te piden el recorrido más corto que visita 15 ciudades. ¿Por qué no un voraz, y qué haces? 🟠

**S21.** «Uso divide y vencerás para Fibonacci: `F(n) = F(n − 1) + F(n − 2)`, se parte en dos.» ¿Qué falla? 🟠

**S22.** Con `n = 40` y valores hasta `10¹²`, alguien propone la DP de la mochila. ¿Qué le dices? 🟠

**S23.** Tu solución recursiva da RE en Java y AC en C++ con el mismo algoritmo. ¿Qué pasa y qué haces? 🟠

**S24.** Demuestra por inducción que `pow(a, n)` recursivo (`a^(n/2)` al cuadrado, por `a` si `n` es impar) es correcto. 🔴

**S25.** Diseña la búsqueda del menor número de volteos de prefijo que ordena una permutación de 10 elementos y justifica la técnica con la cuenta de estados. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Grupo de estudio sin roces

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** decidir si se enumera todo o se poda con una cota.

Hay `n` estudiantes y `m` pares que no se llevan bien. ¿Cuál es el grupo más grande en el que no hay
ningún par de los que no se llevan bien?

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con un par `a b` (de 1 a `n`).
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 25`; `0 ≤ m ≤ n(n − 1)/2`.

```text
Entrada     Salida
5 5         2
1 2
2 3
3 4
4 5
5 1

Entrada     Salida
4 3         3
1 2
1 3
1 4
```

**Pista 1:** si al grupo actual, sumándole todos los que quedan por decidir, no le alcanza para superar el
mejor ya encontrado, ¿hace falta seguir?

### Dos turnos parejos

**Nivel:** 🟠 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que `2ⁿ` no cabe y `2^(n/2)` sí.

Hay `n` tareas con su duración. Cada una se asigna al turno de mañana o al de tarde (todas se asignan).
¿De cuántas formas la diferencia entre las duraciones totales de los dos turnos es como mucho `D`?

- **Entrada.** Una línea con `n` y `D`. Una línea con las `n` duraciones.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 40`; `1 ≤ duración ≤ 10⁹`; `0 ≤ D ≤ 4·10¹⁰`.

```text
Entrada            Salida
6 0                4
5 2 9 1 5 6

Entrada            Salida
6 2                10
5 2 9 1 5 6

Entrada            Salida
1 2                0
3
```

**Pista 1:** con `n = 40`, ¿cuántas asignaciones hay, y cuántas hay si miras solo las primeras 20 tareas?

### Contraseñas con vocal

**Nivel:** 🟢 · **Tiempo:** 15 minutos · **Formato:** programa completo.

**Fuerza:** contar sin enumerar, con un exponente que no se recorre.

Un alfabeto tiene `k` letras, de las que `v` son vocales. ¿Cuántas cadenas de longitud `n` contienen al
menos una vocal? Imprime el resultado módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n`, `k` y `v`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10¹⁸`; `1 ≤ v ≤ k ≤ 10⁹`.

```text
Entrada       Salida
1 26 5        5

Entrada       Salida
3 26 5        8315

Entrada       Salida
2 2 1         3
```

**Pista 1:** ¿es más fácil contar las cadenas **sin** ninguna vocal?

### Ruta de reparto

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** resistir la tentación de la técnica sofisticada cuando la fuerza bruta cabe.

Una furgoneta sale del almacén `0`, visita una vez a cada uno de los `n − 1` clientes y vuelve al almacén.
`d[i][j]` es el tiempo de ir de `i` a `j` (no necesariamente igual a `d[j][i]`). Imprime el menor tiempo
total.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 9`; `0 ≤ d[i][j] ≤ 10⁶`; `d[i][i] = 0`.

```text
Entrada            Salida
4                  21
0 2 9 10
1 0 6 4
15 7 0 8
6 3 12 0

Entrada            Salida
1                  0
0
```

**Pista 1:** ¿cuántos órdenes de visita distintos hay con 8 clientes?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Beautiful Arrangement](https://leetcode.com/problems/beautiful-arrangement/) | LeetCode | 🟡 | Si colocas los números posición a posición, ¿cuándo sabes que una rama ya no sirve? |
| [ ] | [Fair Distribution of Cookies](https://leetcode.com/problems/fair-distribution-of-cookies/) | LeetCode | 🟡 | Si un niño ya tiene más que el mejor injusto encontrado, ¿hace falta seguir? |
| [ ] | [Password Cracker](https://www.hackerrank.com/challenges/password-cracker/problem) | HackerRank | 🟡 | Si desde la posición `i` ya falló, ¿tiene sentido volver a intentarlo desde `i`? |
| [ ] | [Maximum Score Words Formed by Letters](https://leetcode.com/problems/maximum-score-words-formed-by-letters/) | LeetCode | 🟠 | Con 14 palabras como mucho, ¿cuántas elecciones hay? |
| [ ] | [Stone Game IV](https://leetcode.com/problems/stone-game-iv/) | LeetCode | 🟠 | ¿Desde cuántas piedras gana quien mueve, si conoces la respuesta para todos los números menores? |

---

## ✅ Las frases que hay que tener listas

> «Con `n ≤ 20` son un millón de subconjuntos; con `n ≤ 40`, dos mitades de un millón. Antes de buscar
> algo polinomial, hago la cuenta.»

> «La poda no cambia el caso peor; cambia cuánto del árbol visito. Por eso digo la cota y por qué no pierde
> soluciones.»

> «NP no es "no polinomial": es verificable en tiempo polinomial. Si lo reconozco como NP-difícil, busco el
> parámetro pequeño del enunciado y hago que el exponente caiga ahí.»

---

**Anterior:** [`10/06` — Juegos y búsqueda adversarial](06-juegos-y-busqueda-adversarial.md) · **Siguiente:** [`10/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`10/01` — Recursión](01-recursion.md); [`10/04` — *Meet in the middle*, IDDFS y *Dancing Links*](04-meet-in-the-middle-iddfs-y-dancing-links.md).
