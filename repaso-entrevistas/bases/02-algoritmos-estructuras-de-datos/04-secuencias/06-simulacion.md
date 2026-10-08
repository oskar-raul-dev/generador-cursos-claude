# 06 — Simulación

> El examen del bloque `04`: preguntas que cruzan prefijos, diferencias, dos punteros, ventanas, Kadane,
> compresión, barrido y matrices; tres problemas propios cronometrados que no dicen de qué capítulo son,
> y seis problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están
> en el [solucionario](07-respuestas.md#06--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para el primer y el segundo problema, 20 para
  el tercero.
- **En voz alta.** Antes de cada problema, di qué técnica descartas y por qué: es lo que más pesa en este
  bloque, donde varias técnicas se parecen.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros.
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Prefijos y diferencias

**S1.** ¿Qué fórmula da la suma de `a[l..r]` con prefijos, y por qué el arreglo tiene `n + 1` posiciones? 🟢

**S2.** ¿Cuándo usas diferencias y cuándo un Fenwick para sumas por rango? 🟡

**S3.** ¿Por qué los prefijos no sirven para el máximo de un rango? 🟡

### Dos punteros y ventanas

**S4.** ¿Qué propiedad necesita una condición para que la ventana variable sea correcta? 🟢

**S5.** ¿Por qué un `while` dentro de un `for` en una ventana es `O(n)`? 🟡

**S6.** Da un ejemplo de tres elementos en el que la ventana para «suma `≥ S`» falla por los negativos. 🟠

### Kadane y conteo

**S7.** ¿Cuál es la forma de Kadane que nunca devuelve el subarreglo vacío? 🟢

**S8.** ¿Qué guardas en el mapa para contar subarreglos con suma `k`, y con qué valor empieza? 🟡

**S9.** ¿Qué excepción tiene la fórmula del subarreglo máximo circular? 🟡

### Compresión y barrido

**S10.** ¿Qué pierde la compresión de coordenadas? 🟢

**S11.** ¿Qué orden de empates usas en un barrido con intervalos semiabiertos? 🟡

**S12.** Al unir intervalos, ¿por qué el final del bloque es el máximo de los finales? 🟡

### Matrices

**S13.** ¿Desde qué esquina empieza la búsqueda en escalera, y cuántos pasos da como mucho? 🟢

**S14.** ¿Cómo giras una matriz `n × n` 90° en el sitio? 🟡

### Las que descolocan

**S15.** Tu ventana deslizante pasa los ejemplos y da WA en el caso 9. ¿Qué miras primero en el enunciado? 🟠

**S16.** ¿Y si las coordenadas llegaran a `10¹⁸`? Para un barrido de intervalos, ¿qué cambia en tu código? 🟠

**S17.** Te piden «el número de subarreglos con suma `≤ S`» y los valores pueden ser negativos. ¿Por qué no es una ventana, y qué complejidad esperas? 🟠

**S18.** Un barrido da 3 reuniones a la vez y el juez espera 2. ¿Qué dos explicaciones tiene, una de ellas correcta? 🟠

**S19.** Una solución de prefijos 2D da WA solo en las consultas que no tocan el borde superior izquierdo. ¿Dónde está el error? 🟠

**S20.** «Los dos punteros son siempre `O(n)`.» Da el caso en que el mismo código con dos índices es `O(n²)`. 🔴

**S21.** ¿Por qué Kadane es una programación dinámica, y cuál es su estado? 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### La parcela más fértil

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** decidir el preproceso; sin él, cada cuadrado cuesta `k²` sumas.

Un campo es una cuadrícula de `R × C` con la cosecha de cada parcela. Imprime la mayor cosecha total de
un cuadrado de `k × k` parcelas.

- **Entrada.** Una línea con `R`, `C` y `k`. Después, `R` líneas con `C` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ min(R, C)`; `1 ≤ R, C ≤ 1000`; `0 ≤ cosecha ≤ 10⁹`.

```text
Entrada            Salida
3 4 2              22
3 1 4 1
5 9 2 6
5 3 5 8

Entrada            Salida
3 4 3              39
3 1 4 1
5 9 2 6
5 3 5 8
```

**Pista 1:** con `R = C = 1000` y `k = 500`, ¿cuántas sumas hace sumar cada cuadrado desde cero?

### Saldos a cero

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** descartar la ventana deslizante cuando hay negativos.

Cuenta los tramos contiguos de un registro de movimientos (ingresos y gastos) cuya suma es exactamente
`S`.

- **Entrada.** Una línea con `n` y `S`. Una línea con los `n` movimientos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `|a[i]| ≤ 10⁹`; `|S| ≤ 10¹⁴`.

```text
Entrada            Salida
7 0                4
3 -4 5 -1 2 -6 4

Entrada            Salida
3 1                3
1 -1 1

Entrada            Salida
3 0                6
0 0 0
```

**Pista 1:** en el segundo ejemplo, ¿qué haría una ventana que encoge en cuanto la suma pasa de `S`?

### Reservas que se tocan

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que con `n ≤ 300` comparar todos los pares basta, y decidir qué significa
«tocarse» con extremos cerrados.

Cada reserva es un intervalo **cerrado** `[s, e]` de días. Dos reservas están en conflicto si comparten
al menos un día. Cuenta los pares de reservas en conflicto.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `s e`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 300`; `1 ≤ s ≤ e ≤ 10⁹`.

```text
Entrada            Salida
3                  1
1 3
3 5
6 7

Entrada            Salida
3                  2
1 10
2 3
4 5
```

**Pista 1:** ¿cuántos pares hay con `n = 300`, y cuánto cuesta comprobar cada uno?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Find All Anagrams in a String](https://leetcode.com/problems/find-all-anagrams-in-a-string/) | LeetCode | 🟡 | ¿De qué tamaño son los tramos que tienes que comparar, y qué cambia al moverte uno? |
| [ ] | [Grumpy Bookstore Owner](https://leetcode.com/problems/grumpy-bookstore-owner/) | LeetCode | 🟡 | Si fijas los minutos de la técnica, ¿qué clientes ganas respecto de no usarla? |
| [ ] | [Continuous Subarray Sum](https://leetcode.com/problems/continuous-subarray-sum/) | LeetCode | 🟡 | ¿Qué tienen en común dos prefijos que delimitan un tramo múltiplo de `k`? |
| [ ] | [My Calendar II](https://leetcode.com/problems/my-calendar-ii/) | LeetCode | 🟡 | Con pocas reservas, ¿te basta guardar los tramos donde ya hay dos? |
| [ ] | [Maximum Subarray Sum II](https://cses.fi/problemset/task/1644) | CSES | 🟠 | Para un final fijo, ¿entre qué prefijos eliges el inicio? |
| [ ] | [Minimum Window Substring](https://leetcode.com/problems/minimum-window-substring/) | LeetCode | 🟠 | ¿Qué tienes que contar dentro de la ventana para saber que ya cubre todo? |

---

## ✅ Las frases que hay que tener listas

> «Como los valores no son negativos, la ventana solo avanza: si se pasa, alargarla no la arregla. Con
> negativos, prefijos y un mapa.»

> «La suma de cualquier rango es una resta de dos prefijos: `O(n)` de preproceso y `O(1)` por consulta,
> siempre que el arreglo no cambie.»

> «En el barrido, los cierres antes que las aperturas porque los intervalos son semiabiertos.»

---

**Anterior:** [`04/05` — Matrices](05-matrices.md) · **Siguiente:** [`04/07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`04/02` — Dos punteros y ventana deslizante](02-dos-punteros-y-ventana.md).
