# 07 — Simulación

> El examen del bloque `02`: preguntas que cruzan notación, recurrencias, amortizado, corrección, coste
> real y TDA; tres problemas propios cronometrados que no dicen de qué capítulo son, y seis problemas
> externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta como máximo; 30 minutos para cada uno de los dos
  primeros problemas y 20 para el tercero.
- **En voz alta.** Las preguntas de prueba se responden con la forma fija: el invariante con sus tres
  partes, la inducción con su caso base y su paso, el intercambio con sus cuatro pasos.
- **Tecleando de verdad.** Los problemas se escriben y se prueban contra casos propios; en los de
  análisis, además, contra una fuerza bruta con `n` pequeño.
- **Solo después, el solucionario.** Anota qué preguntas fallaste: cada bloque temático corresponde a un
  capítulo.

---

## 🧠 Preguntas

### Notación y casos

**S1.** ¿Qué diferencia hay entre decir que un algoritmo es `O(n²)` y decir que es `Θ(n²)`? 🟢

**S2.** ¿Qué caso das cuando te preguntan cuánto cuesta buscar en un `HashMap`, y qué añades? 🟢

**S3.** ¿Por qué `Σ_{i=1}^{n} ⌊n/i⌋` es `Θ(n log n)` y no `Θ(n²)`? 🟡

**S4.** Un algoritmo aleatorizado tiene caso esperado `Θ(n log n)` y caso peor `Θ(n²)`. ¿Puede un caso de prueba adversario forzar el caso peor? 🟠

### Recurrencias

**S5.** Resuelve `T(n) = 4T(n/2) + n²` y `T(n) = 4T(n/2) + n`. 🟢

**S6.** ¿Por qué la exponenciación rápida tiene que hacer una sola llamada recursiva y no dos? 🟡

**S7.** ¿Qué recurrencia tiene una búsqueda que descarta un tercio en cada paso, y cuánto vale? 🟡

**S8.** Una recursión parte en `n/3` y `2n/3` y combina en lineal. ¿Por qué no puedes usar el teorema maestro y qué usas? 🟠

### Amortizado

**S9.** ¿Por qué el `push_back` de un arreglo dinámico es `O(1)` amortizado y no `O(1)`? 🟢

**S10.** ¿Qué potencial usarías para la pila con vaciado múltiple, y qué amortizado da cada operación? 🟡

**S11.** Un bucle `while` interno saca elementos de una pila dentro de un `for` de `n` vueltas. ¿Cómo justificas que el total es `O(n)`? 🟠

### Corrección

**S12.** Escribe el invariante de la búsqueda del primer índice con `a[i] ≥ x`. 🟢

**S13.** ¿Qué parte de la prueba de un bucle demuestra que termina, y qué la demuestra en la búsqueda binaria? 🟡

**S14.** Da el contraejemplo mínimo del voraz «la reunión que empieza antes». 🟡

**S15.** ¿Por qué un algoritmo recursivo que se llama con `n/2` necesita inducción fuerte? 🟠

### Coste real y TDA

**S16.** ¿Por qué recorrer una matriz por columnas es más lento que por filas, si hacen las mismas operaciones? 🟢

**S17.** ¿Qué TDA necesitas para «insertar, borrar y el menor elemento mayor que `x`», y qué implementación? 🟡

**S18.** ¿Por qué `LinkedList` no es la mejor cola en Java, si encola y desencola en `O(1)`? 🟠

### Las que descolocan

**S19.** Tu solución es `O(n log n)` con `n = 10⁶` en Java y da TLE. La complejidad es la correcta. ¿Qué miras primero? 🟠

**S20.** Te dicen «tu voraz pasa todos los ejemplos, ¿por qué no lo envías?». ¿Qué respondes? 🟠

**S21.** ¿Y si `n` fuera `10¹²`? Para «cuántas veces se ejecuta este doble bucle», ¿qué cambia? 🟠

**S22.** «Amortizado es lo mismo que promedio, ¿no?». Corrige la frase con un ejemplo donde la diferencia importe. 🔴

**S23.** Demuestra que una cola implementada con dos pilas es correcta: el invariante que garantiza el orden y por qué se conserva. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Bucles con raíz

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** contar sin ejecutar; el fragmento literal no cabe y su bucle exterior sí.

Imprime cuántas veces se ejecuta `count++` en este fragmento:

```text
for (i = 1; i·i ≤ n; i++)
  for (j = i; j ≤ n; j += i)
    count++
```

- **Entrada.** Un entero `n`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10¹²`. Límite: 1 segundo.

```text
Entrada            Salida
10                 18

Entrada            Salida
1                  1

Entrada            Salida
16                 33
```

**Pista 1:** para un `i` fijo, ¿cuántas vueltas da el bucle interno, y cuántos valores de `i` hay?

### Recurrencia desequilibrada

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** decidir si la recursión con memoria basta, estimando cuántos estados distintos aparecen.

Sea `T(0) = 0`, `T(1) = 1` y, para `n ≥ 2`, `T(n) = T(⌊n/3⌋) + T(⌊2n/3⌋) + n`. Imprime `T(n)`.

- **Entrada.** Un entero `n`.
- **Salida.** Un entero.
- **Restricciones.** `0 ≤ n ≤ 10¹²`.

```text
Entrada            Salida
3                  7

Entrada            Salida
10                 34
```

**Pista 1:** si dibujas el árbol de llamadas para un `n` grande, ¿cuántos argumentos distintos
aparecen en realidad?

### ¿Falla el voraz?

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que con `n ≤ 15` la fuerza bruta es la solución, y que sirve de oráculo.

Hay `n` reuniones `[s, f)`. Imprime dos números: el máximo de reuniones disjuntas que se pueden
elegir, y el número que elige el voraz «la más corta primero» (recorre las reuniones de menor a mayor
duración, desempatando por inicio, y toma cada una si no se solapa con las ya tomadas).

- **Entrada.** Una línea con `n`. Después, `n` líneas con `s f`.
- **Salida.** Dos enteros.
- **Restricciones.** `1 ≤ n ≤ 15`; `0 ≤ s < f ≤ 10⁹`.

```text
Entrada            Salida
3                  2 1
0 5
4 6
5 10

Entrada            Salida
4                  2 2
1 4
3 5
0 6
5 7
```

**Pista 1:** ¿cuántos subconjuntos de reuniones hay con `n = 15`, y cuánto cuesta comprobar cada uno?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Guess Number Higher or Lower](https://leetcode.com/problems/guess-number-higher-or-lower/) | LeetCode | 🟢 | ¿Qué sabes de los números a cada lado de tu intento después de cada respuesta? |
| [ ] | [Insertion Sort - Part 1](https://www.hackerrank.com/challenges/insertionsort1/problem) | HackerRank | 🟢 | ¿Qué está ordenado antes de insertar el último elemento? |
| [ ] | [Peak Index in a Mountain Array](https://leetcode.com/problems/peak-index-in-a-mountain-array/) | LeetCode | 🟡 | Mirando dos posiciones vecinas, ¿sabes en qué lado está la cima? |
| [ ] | [Boats to Save People](https://leetcode.com/problems/boats-to-save-people/) | LeetCode | 🟡 | ¿Con quién debería ir la persona más pesada, si va con alguien? |
| [ ] | [Count Primes](https://leetcode.com/problems/count-primes/) | LeetCode | 🟡 | Si tachas los múltiplos de cada número, ¿cuánto trabajo haces en total? |
| [ ] | [My Calendar I](https://leetcode.com/problems/my-calendar-i/) | LeetCode | 🟡 | Para una reserva nueva, ¿qué reservas existentes son las únicas que pueden chocar? |

---

## ✅ Las frases que hay que tener listas

> «Es `Θ(n log n)` en el caso peor; el `HashMap` sería `O(1)` esperado, pero con casos adversarios
> prefiero la garantía de ordenar.»

> «Funciona porque mantiene este invariante: todo lo anterior a `lo` es menor que `x` y todo lo que
> está desde `hi` es mayor o igual. Termina porque `hi − lo` baja en cada vuelta.»

> «El `add` es `O(1)` amortizado: de vez en cuando copia todo, pero la capacidad crece por un factor y
> cada elemento se copia un número constante de veces en total.»

---

**Anterior:** [`02/06` — Tipos abstractos de datos](06-tipos-abstractos-de-datos.md) ·
**Siguiente:** [`02/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`02/04` — Corrección](04-correccion-invariantes-induccion-intercambio.md).
