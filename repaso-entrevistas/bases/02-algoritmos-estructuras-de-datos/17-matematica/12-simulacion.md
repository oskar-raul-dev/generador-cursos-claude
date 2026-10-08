# 12 — Simulación

> El examen del bloque `17`: preguntas que cruzan bits, divisibilidad, aritmética modular, primos,
> combinatoria, probabilidad, matrices, juegos y lo que se nombra sin escribir; cuatro problemas propios
> cronometrados que no dicen de qué capítulo son —uno se resuelve probando divisores hasta `√n` porque hay
> una sola consulta—, y cinco problemas externos que no aparecen antes en el bloque. Las respuestas y las
> pistas 2 y 3 están en el [solucionario](13-respuestas.md#12--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di qué herramienta matemática usas, qué tipo de entero necesitas
  y dónde puede desbordarse.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en el de las fracciones modulares:
  para `p` pequeño, compara con la fracción calculada a mano
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Lo básico y un patrón

**S1.** ¿Cómo compruebas con una sola operación de bits si `n > 0` es potencia de 2? 🟢

**S2.** ¿Por qué `gcd(a, b) = gcd(b, a mod b)`, y cuántos pasos da Euclides? 🟢

**S3.** ¿Cómo calculas `a⁻¹ mod p` con `p` primo? 🟢

**S4.** ¿Cuánto cuesta la criba hasta `n`, y factorizar `q` números con la criba del menor factor primo? 🟡

**S5.** ¿Cómo respondes muchas consultas de `C(n, k) mod p` con `n ≤ 10⁶`? 🟡

### Probabilidad, matrices, juegos y transformadas

**S6.** ¿Qué dice la linealidad de la esperanza, y por qué no exige independencia? 🟢

**S7.** ¿Cuántos intentos se esperan hasta el primer éxito, si cada uno sale bien con probabilidad `p`? 🟢

**S8.** ¿Qué hace la eliminación de Gauss y cuánto cuesta? 🟡

**S9.** ¿Cuándo gana quien empieza en una suma de juegos imparciales? 🟡

**S10.** ¿Qué es una convolución y cuándo se calcula en `Θ(n log n)`? 🟡

### Las que descolocan

**S11.** Tu `a * b % m` da negativo en Java, con `a, b < m = 10⁹ + 7`. ¿Qué ha pasado? 🟠

**S12.** «Para dividir módulo `m`, divido y después tomo el módulo.» ¿Qué respondes? 🟠

**S13.** Hay que decir si un único `n ≤ 10¹²` es primo y alguien propone una criba hasta `n`. ¿Qué dices? 🟠

**S14.** «`-7 % 3` da lo mismo en Python que en Java.» ¿Es cierto, y qué haces para no depender de ello? 🟠

**S15.** Tu Gauss con `double` dice que un sistema de enteros no tiene solución, y sí la tiene. ¿Qué ha
pasado? 🟠

**S16.** «Para saber quién gana hay que simular todas las partidas.» ¿Qué respondes? 🟠

**S17.** Un problema pide una probabilidad «como `P · Q⁻¹ mod 998 244 353`». ¿Por qué ese formato, y cómo
trabajas con él? 🟠

**S18.** Calculas `C(n, k) mod m` con factoriales e inversos y falla con `m = 10⁶`. ¿Por qué? 🟠

**S19.** Demuestra que dejar el XOR de los montones en 0 es una estrategia ganadora en Nim. 🔴

**S20.** Una DP de 5 estados con transiciones lineales da la respuesta; piden el término `10¹⁸` y escribir la
matriz a mano es incómodo. ¿Qué haces? 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Fracciones elevadas

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** dividir módulo un primo sin desbordar.

Para cada consulta, imprime `(a / b)ᶜ` módulo `10⁹ + 7`, es decir `aᶜ · (bᶜ)⁻¹ mod 10⁹ + 7`.

- **Entrada.** Una línea con `q`. Después, `q` líneas con `a`, `b` y `c`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ q ≤ 10⁵`; `1 ≤ a, b ≤ 10¹⁸`; `b` no es múltiplo de `10⁹ + 7`; `0 ≤ c ≤ 10¹⁸`.

```text
Entrada                                         Salida
3                                               500000004
1 2 1                                           250000004
3 2 2                                           610590127
1000000000000000000 3 1000000000000000000

Entrada                                         Salida
2                                               1
5 7 0                                           1000000006
1000000006 1 1
```

**Pista 1:** ¿qué tienes que hacer con `a` y `b` antes de multiplicarlos por nada, si caben en un `long` pero
su producto no?

### El factor más grande

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** precalcular una vez para muchas factorizaciones.

Para cada número, imprime su mayor factor primo y cuántos primos distintos lo dividen. Para el 1, imprime
`1 0`.

- **Entrada.** Una línea con `q`. Una línea con los `q` números.
- **Salida.** `q` líneas con dos enteros.
- **Restricciones.** `1 ≤ q ≤ 10⁶`; `1 ≤ x ≤ 10⁷`.

```text
Entrada                   Salida
5                         1 0
1 12 997 720720 9699690   3 2
                          997 1
                          13 6
                          19 8

Entrada                   Salida
2                         5 2
10000000 9999991          9999991 1
```

**Pista 1:** con `10⁶` números, ¿cuánto cuesta la división de prueba de cada uno, y qué tabla te deja
factorizar cada uno en tantos pasos como factores tenga?

### Fichas que se acercan

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** ver el montón de Nim dentro de un tablero.

Un tablero tiene `n` filas. En cada fila hay dos fichas, en las columnas `l < r`. En su turno, un jugador
elige una fila y mueve **una** de sus dos fichas hacia la otra, una o más casillas, sin saltarla ni ocupar su
casilla. Pierde quien no puede mover. Imprime `first` si gana quien empieza y `second` si no.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `l` y `r`.
- **Salida.** `first` o `second`.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `1 ≤ l < r ≤ 10⁹`.

```text
Entrada         Salida
3               first
1 5
2 4
3 9

Entrada         Salida
2               second
1 3
4 6
```

**Pista 1:** en una fila, ¿qué cantidad cambia con cualquier movimiento, sea de la ficha que sea, y qué valores
puede tomar después?

### La mesa del banquete

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no cribar cuando hay una sola consulta.

Se quiere montar una mesa rectangular de exactamente `n` módulos cuadrados de `1 × 1`, con lados enteros. ¿Cuál es
el menor perímetro posible?

- **Entrada.** Un entero `n`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁹`.

```text
Entrada         Salida
12              14

Entrada         Salida
13              28

Entrada         Salida
1000000000      126500
```

**Pista 1:** los divisores de `n` van en parejas `(d, n/d)`: ¿hasta dónde hace falta buscar el primer lado, y
en qué orden te conviene recorrerlos?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Distinct Prime Factors of Product of Array](https://leetcode.com/problems/distinct-prime-factors-of-product-of-array/) | LeetCode | 🟢 | ¿Hace falta calcular el producto, que no cabe en ningún tipo? |
| [ ] | [Nimble Game](https://www.hackerrank.com/challenges/nimble-game-1/problem) | HackerRank | 🟡 | Una moneda en la casilla `i`, ¿a qué se parece si la miras sola? |
| [ ] | [Ugly Number III](https://leetcode.com/problems/ugly-number-iii/) | LeetCode | 🟠 | Si supieras contar cuántos números `≤ x` son múltiplos de `a`, `b` o `c`, ¿cómo encontrarías el `n`-ésimo? |
| [ ] | [Prime Multiples](https://cses.fi/problemset/task/2185) | CSES | 🟠 | Con `k ≤ 20` primos, ¿cuántos subconjuntos hay, y qué cuenta cada uno? |
| [ ] | [Counting Coprime Pairs](https://cses.fi/problemset/task/2417) | CSES | 🔴 | ¿Cuántos pares tienen los dos números múltiplos de `d`, si sabes cuántos números del arreglo lo son? |

---

## ✅ Las frases que hay que tener listas

> «Antes de operar, el tipo: con `m ≈ 10⁹`, el producto de dos residuos cabe en 64 bits pero no en 32; con
> operandos de 64 bits, se reduce primero o se usa `__int128` / `Math.multiplyHigh`.»

> «Dividir módulo un primo es multiplicar por el inverso, `a^{p−2}`; con un módulo compuesto, el inverso
> existe solo si `gcd(a, m) = 1`, y sale de Euclides extendido.»

> «Muchas consultas, criba del menor factor primo; una sola consulta hasta `10¹²`, división de prueba hasta
> `√n`; hasta `10¹⁸`, Miller-Rabin determinista y Pollard rho.»

> «En un juego imparcial, Grundy de cada componente y XOR; gana quien empieza si no es 0.»

---

**Anterior:** [`17/11` — Funciones generadoras y Berlekamp-Massey](11-funciones-generadoras.md) · **Siguiente:** [`17/13` — Respuestas](13-respuestas.md) ·
**Relacionado:** [`17/03` — Aritmética modular](03-aritmetica-modular.md).
