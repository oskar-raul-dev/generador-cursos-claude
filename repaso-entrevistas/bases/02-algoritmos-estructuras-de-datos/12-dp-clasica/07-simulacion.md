# 07 — Simulación

> El examen del bloque `12`: preguntas que cruzan el diseño del estado, la memoización y la tabulación, la
> LIS, las mochilas, las cadenas, las rejillas, los intervalos y el conteo; cuatro problemas propios
> cronometrados que no dicen de qué capítulo son —uno parece DP y no lo es, y otro cabe por fuerza
> bruta—, y cinco problemas externos que no aparecen antes en el bloque. Las respuestas y las pistas 2 y 3
> están en el [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 25 minutos por problema propio (15 para el de fuerza
  bruta).
- **En voz alta.** Antes de teclear, di las cinco piezas: estado, transición, casos base, orden y respuesta,
  y el coste como estados por transición. Si no salen, puede que no sea DP.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de los montones
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Diseño

**S1.** ¿Qué cinco piezas tiene una DP y cuánto cuesta? 🟢

**S2.** ¿Qué dice el principio de optimalidad, dicho para programar? 🟡

**S3.** ¿Cuándo memoizas y cuándo tabulas? 🟡

**S4.** ¿Cómo reconstruyes la solución sin guardarla entera en cada estado? 🟢

### Secuencias y mochilas

**S5.** ¿Qué guarda el arreglo de colas de la LIS, y por qué no es la LIS? 🟡

**S6.** ¿En qué sentido va el bucle de capacidad en la 0/1 de una fila, y en la ilimitada? 🟢

**S7.** ¿Por qué `O(n · W)` es pseudopolinomial? 🟡

**S8.** ¿Qué decide el anidamiento de los bucles al contar formas de pagar? 🟡

### Cadenas, rejillas e intervalos

**S9.** ¿Qué diferencia hay entre la LCS y la subcadena común más larga? 🟢

**S10.** ¿En qué orden se rellena una DP de intervalos? 🟢

**S11.** ¿Por qué *burst balloons* elige el último globo y no el primero? 🟡

### Conteo

**S12.** ¿Por qué contar no es optimizar cambiando `max` por `+`? 🟡

### Las que descolocan

**S13.** «Esto es DP: elige qué hacer con cada elemento.» Pero `n ≤ 15`. ¿Qué haces? 🟠

**S14.** Tu DP con memo da la respuesta correcta y TLE. ¿Qué tres cosas miras? 🟠

**S15.** «La mochila es voraz por valor/peso.» ¿Qué respondes, con números? 🟠

**S16.** Tu DP de intervalos cambia de resultado al reordenar los bucles. ¿Qué pasa? 🟠

**S17.** Te piden emparejar trabajadores con puestos minimizando la suma de diferencias, y empiezas una DP sobre máscaras. ¿Hay algo mejor? 🟠

**S18.** Tu memoización da RE en Java con `n = 10⁵` y AC en C++. ¿Qué cambias? 🟠

**S19.** Demuestra que el bucle descendente de la mochila 0/1 en una fila es correcto. 🔴

**S20.** Diseña la DP para unir montones dispuestos en **círculo**, y di su coste. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Maleta pequeña

**Nivel:** 🟢 · **Tiempo:** 15 minutos · **Formato:** programa completo.

**Fuerza:** con `n ≤ 15`, la fuerza bruta es más corta y segura que la DP.

Hay `n` objetos con peso y valor y una maleta de capacidad `W`. Imprime el valor máximo y los índices
(desde 0) de los objetos elegidos; si hay varias selecciones óptimas, la de lista de índices menor en orden
lexicográfico.

- **Entrada.** Una línea con `n` y `W`. Después, `n` líneas con `peso valor`.
- **Salida.** El valor y, en la línea siguiente, los índices separados por espacios (vacía si ninguno).
- **Restricciones.** `1 ≤ n ≤ 15`; `0 ≤ W ≤ 10⁹`; `1 ≤ peso, valor ≤ 10⁹`.

```text
Entrada     Salida
6 10        18
5 10        0 4
2 3
9 14
1 2
5 8
6 9

Entrada     Salida
2 3         1
4 5         1
1 1
```

**Pista 1:** ¿cuántos subconjuntos hay con 15 objetos, y cuánto cuesta comprobar cada uno?

### Corrector con costes

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** adaptar una recurrencia conocida a costes distintos sin rehacerla.

Convertir una cadena en otra cuesta `ci` por inserción, `cd` por borrado y `cs` por sustitución. Imprime el
coste mínimo.

- **Entrada.** Una línea con `ci cd cs`. Dos líneas con las cadenas (la segunda puede estar vacía).
- **Salida.** Un entero.
- **Restricciones.** Cadenas de hasta 2 000 letras; `1 ≤ ci, cd, cs ≤ 10⁶`.

```text
Entrada     Salida
1 1 3       3
perro
pera

Entrada     Salida
2 5 1       15
abc

```

**Pista 1:** si sustituir cuesta más que borrar e insertar, ¿qué operación no conviene nunca?

### Montones en círculo

**Nivel:** 🟠 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** romper un círculo para que quepa una DP de intervalos.

Hay `n` montones dispuestos **en círculo** (el último es vecino del primero). Se unen de dos en dos, solo
vecinos, y cada unión cuesta la suma de los dos montones. Imprime el coste mínimo de dejar uno solo.

- **Entrada.** Una línea con `n`. Una línea con los tamaños, en orden alrededor del círculo.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 200`; `1 ≤ tamaño ≤ 10⁹`.

```text
Entrada     Salida
4           31
5 2 9 1

Entrada     Salida
3           14
1 10 1
```

**Pista 1:** al final quedan dos montones que se unen; ¿entre qué dos vecinos del círculo nunca hubo unión?

### Parejas de turnos

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que no hace falta DP: hay un voraz con prueba de intercambio.

Hay `n` trabajadores con su hora preferida y `n` turnos con su hora de inicio. Cada trabajador recibe un
turno distinto, y su disgusto es la diferencia absoluta entre las dos horas. Imprime el disgusto total
mínimo.

- **Entrada.** Una línea con `n`. Una línea con las horas preferidas. Una línea con las horas de los turnos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; horas entre 0 y `10⁹`.

```text
Entrada     Salida
4           6
5 2 9 1
3 8 4 6

Entrada     Salida
1           9
1
10
```

**Pista 1:** si dos trabajadores tienen sus turnos «cruzados» (el de hora menor con el turno mayor), ¿qué
pasa al cambiarlos?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [House Robber II](https://leetcode.com/problems/house-robber-ii/) | LeetCode | 🟡 | Si la primera y la última casa son vecinas, ¿qué dos problemas sin círculo cubren todos los casos? |
| [ ] | [Maximum Product Subarray](https://leetcode.com/problems/maximum-product-subarray/) | LeetCode | 🟡 | Un número negativo, ¿convierte el peor producto en el mejor? |
| [ ] | [Partition Array for Maximum Sum](https://leetcode.com/problems/partition-array-for-maximum-sum/) | LeetCode | 🟡 | ¿Cuánto mide el último trozo del prefijo? |
| [ ] | [Ugly Number II](https://leetcode.com/problems/ugly-number-ii/) | LeetCode | 🟡 | Cada número feo es otro feo multiplicado por 2, 3 o 5: ¿cuál es el siguiente candidato de cada tipo? |
| [ ] | [Equal](https://www.hackerrank.com/challenges/equal/problem) | HackerRank | 🟡 | Dar a todos menos a uno, ¿equivale a quitarle a uno? |

---

## ✅ Las frases que hay que tener listas

> «Estado, transición, casos base, orden y respuesta; y el coste, estados por transición. Si no sé decir el
> estado, todavía no sé resolverlo.»

> «Una fila: descendente para la 0/1, ascendente para la ilimitada. Contando: monedas por fuera para
> combinaciones, sumas por fuera para sucesiones.»

> «La DP de intervalos se llena por longitud; la de rejilla, por filas. Y antes de una DP, miro `n`: con 15
> elementos, la fuerza bruta basta.»

---

**Anterior:** [`12/06` — Conteo con DP](06-conteo.md) · **Siguiente:** [`12/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`12/01` — De la recursión a la tabla](01-de-la-recursion-a-la-tabla.md).
