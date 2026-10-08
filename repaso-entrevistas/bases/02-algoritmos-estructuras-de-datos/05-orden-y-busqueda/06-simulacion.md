# 06 — Simulación

> El examen del bloque `05`: preguntas que cruzan ordenación, selección, búsqueda binaria, ternaria y
> exponencial; cuatro problemas propios cronometrados que no dicen de qué capítulo son, y seis problemas
> externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](07-respuestas.md#06--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para cada uno de los dos primeros problemas
  y 20 para los otros dos.
- **En voz alta.** Antes de cada problema, di si la respuesta es «ordenar», «una frontera» o «un
  extremo», y por qué: es la decisión que más pesa en este bloque.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Ordenación

**S1.** ¿Qué algoritmo usa `sorted` de Python y qué garantiza? 🟢

**S2.** ¿Por qué *quicksort* con pivote aleatorio no tiene entradas malas, y qué sigue pudiendo pasar? 🟡

**S3.** ¿Qué condición necesita un comparador de `std::sort` y qué pasa si no la cumple? 🟡

**S4.** ¿Cuándo un *counting sort* es peor idea que `sort`? 🟢

### Inversiones y selección

**S5.** ¿Qué relación hay entre las inversiones y la ordenación por inserción? 🟢

**S6.** ¿Por qué *quickselect* es lineal en esperanza y *quicksort* no? 🟡

**S7.** ¿Cuál es el tipo correcto para un contador de inversiones con `n = 2·10⁵`, y por qué? 🟢

### Búsqueda binaria

**S8.** ¿Cuál es el invariante de la plantilla `firstTrue`? 🟡

**S9.** ¿Cómo obtienes «el último `≤ x`» con *upper bound*? 🟢

**S10.** ¿Por qué la binaria en reales no se para con `hi − lo > ε`? 🟡

### Ternaria y exponencial

**S11.** ¿Qué condición necesita la ternaria y qué la rompe? 🟡

**S12.** ¿Cuándo usarías la búsqueda exponencial en lugar de la binaria? 🟢

### Las que descolocan

**S13.** Tu binaria sobre la respuesta pasa los ejemplos y da WA en el caso 14. ¿Qué dos cosas compruebas primero? 🟠

**S14.** Un compañero ordena con `Comparator` que devuelve `a.x - b.x` y da WA solo con valores negativos grandes. ¿Qué pasa? 🟠

**S15.** «Para la mediana de un millón de valores, ordeno.» ¿Es mala respuesta en una entrevista? ¿Qué añadirías? 🟠

**S16.** Te piden «el mínimo de una función» y la ternaria da WA. Da dos causas posibles. 🟠

**S17.** ¿Por qué `std::lower_bound` sobre un `std::set` da TLE aunque la respuesta sea correcta? 🟠

**S18.** «Ningún algoritmo de ordenación baja de `n log n`.» Matiza la frase con precisión. 🔴

**S19.** Demuestra que el número mínimo de intercambios **adyacentes** para ordenar es el número de inversiones. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Cobertura de *routers*

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** ver que comprobar un radio es fácil y encontrarlo no; y que la comprobación necesita las
casas ordenadas.

Hay `n` casas en una calle, en las posiciones `xᵢ`, y `k` *routers*. Un *router* en la posición `p` con
radio `r` cubre `[p − r, p + r]`. Imprime el menor radio entero `r` con el que `k` *routers* bien
colocados cubren todas las casas.

- **Entrada.** Una línea con `n` y `k`. Una línea con las `n` posiciones.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ k ≤ n ≤ 2·10⁵`; `0 ≤ xᵢ ≤ 10⁹`.

```text
Entrada            Salida
6 2                2
1 2 5 5 6 9

Entrada            Salida
6 3                1
1 2 5 5 6 9

Entrada            Salida
2 1                50
0 100
```

**Pista 1:** fijado `r`, ¿dónde conviene poner el *router* que cubre la casa más a la izquierda?

### Adelantamientos

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** reconocer el patrón bajo un enunciado de física y elegir el tipo del contador.

En una carretera recta hay `n` coches en posiciones distintas, cada uno con una velocidad constante.
Todos avanzan en el mismo sentido durante un tiempo muy largo. Imprime cuántos adelantamientos se
producen (un coche adelanta a otro si empieza detrás y es estrictamente más rápido).

- **Entrada.** Una línea con `n`. Después, `n` líneas con `posición velocidad`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; posiciones distintas entre 0 y `10⁹`; `1 ≤ velocidad ≤ 10⁹`.

```text
Entrada            Salida
6                  6
0 5
10 2
20 9
30 1
40 5
50 6

Entrada            Salida
3                  0
1 1
2 2
3 3
```

**Pista 1:** si ordenas los coches por posición, ¿qué pares acaban adelantándose?

### Clasificación con extremos

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** escribir un comparador que no desborde y que defina un orden total.

Ordena a los participantes por puntuación de mayor a menor; a igual puntuación, por tiempo de menor a
mayor; a igualdad de ambos, por nombre alfabéticamente. Imprime los nombres.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `nombre puntuación tiempo`.
- **Salida.** `n` nombres, uno por línea.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `−2·10⁹ ≤ puntuación ≤ 2·10⁹`; `0 ≤ tiempo ≤ 10⁹`; nombres
  distintos de 1 a 10 letras.

```text
Entrada                     Salida
3                           ana
ana 2000000000 5            eva
luis -2000000000 3          luis
eva 7 1

Entrada                     Salida
3                           ana
zoe -2000000000 0           zoe
ana -2000000000 0           bea
bea -2000000000 1000000000
```

**Pista 1:** en Java, ¿cuánto vale `luis.puntuación − ana.puntuación` en `int`?

### Emparejar tallas

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** ver que ordenar basta y saber justificarlo.

Hay `n` zapatos izquierdos y `n` derechos de tallas variadas. Se forman `n` parejas de un izquierdo y un
derecho; el coste de una pareja es la diferencia de tallas en valor absoluto. Imprime el menor coste
total.

- **Entrada.** Una línea con `n`. Una línea con las tallas izquierdas y otra con las derechas.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ talla ≤ 10⁹`.

```text
Entrada            Salida
3                  4
5 2 9
1 5 6

Entrada            Salida
2                  2
40 38
41 37
```

**Pista 1:** si dos parejas se cruzan (el izquierdo menor con el derecho mayor), ¿empeora el coste al
descruzarlas?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Array Partition](https://leetcode.com/problems/array-partition/) | LeetCode | 🟢 | ¿Con quién conviene emparejar al menor de todos? |
| [ ] | [Single Element in a Sorted Array](https://leetcode.com/problems/single-element-in-a-sorted-array/) | LeetCode | 🟡 | Antes del elemento único, ¿en qué posiciones empieza cada pareja? |
| [ ] | [H-Index II](https://leetcode.com/problems/h-index-ii/) | LeetCode | 🟡 | En la posición `i`, ¿cuántos artículos tienen al menos `citations[i]` citas? |
| [ ] | [Find K Closest Elements](https://leetcode.com/problems/find-k-closest-elements/) | LeetCode | 🟡 | La respuesta es un tramo de longitud `k`: ¿qué buscas, su inicio? |
| [ ] | [Minimum Number of Days to Make m Bouquets](https://leetcode.com/problems/minimum-number-of-days-to-make-m-bouquets/) | LeetCode | 🟡 | Si el día `d` basta, ¿basta el `d + 1`? |
| [ ] | [Motarack's Birthday](https://codeforces.com/problemset/problem/1301/B) | Codeforces | 🟡 | ¿Qué vecinos de los huecos determinan el mejor valor de `k`? |

---

## ✅ Las frases que hay que tener listas

> «Si se puede con `v`, se puede con `v + 1`: el predicado es monótono, así que hago binaria sobre la
> respuesta y compruebo cada candidato en lineal.»

> «Para el `k`-ésimo no ordeno: *quickselect* es lineal en esperanza; en C++, `nth_element`.»

> «La cota `n log n` es para ordenar comparando; si las claves son enteros pequeños, cuento.»

---

**Anterior:** [`05/05` — Búsqueda ternaria, unimodales y exponencial](05-ternaria-y-exponencial.md) ·
**Siguiente:** [`05/07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`05/04` — Búsqueda binaria](04-busqueda-binaria.md).
