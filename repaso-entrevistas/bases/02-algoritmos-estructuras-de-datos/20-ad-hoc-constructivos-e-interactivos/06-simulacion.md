# 06 — Simulación

> El examen del bloque `20`: preguntas que cruzan invariantes, simulación, constructivos, interactivos, el
> estilo de las pruebas de empresa y los heurísticos; cuatro problemas propios cronometrados que no dicen de qué
> capítulo son —uno de ellos es una simulación directa que cabe sin trucos—, y cinco problemas externos que no
> aparecen antes en el bloque. Las respuestas y las pistas 2 y 3 están en el
> [solucionario](07-respuestas.md#06--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di si buscas un invariante, una construcción o una simulación, y
  cuenta los pasos o el tamaño de la salida antes de escribir.
- **Tecleando de verdad**, con un verificador en el constructivo y una fuerza bruta en el de los colores
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Lo básico y un patrón

**S1.** ¿Qué es un invariante y qué permite demostrar? 🟢

**S2.** ¿Qué hay que hacer después de cada pregunta en un problema interactivo? 🟢

**S3.** ¿Cómo comprueba un juez una respuesta constructiva? 🟢

**S4.** ¿Cuántas preguntas de sí o no hacen falta para adivinar un número entre 1 y `10⁶`? 🟢

**S5.** ¿Cómo calculas la duración de un turno de 22:00 a 06:00? 🟡

### Simulación, constructivos y heurísticos

**S6.** ¿Qué es un óptimo local? 🟢

**S7.** ¿Cuándo se puede saltar un ciclo en una simulación de `10¹⁸` pasos? 🟡

**S8.** ¿Qué diferencia hay entre búsqueda local y recocido simulado? 🟡

**S9.** ¿Qué garantiza la 2-aproximación de la cobertura de vértices? 🟡

**S10.** ¿Por qué el dinero se calcula en céntimos y no en `double`? 🟡

### Las que descolocan

**S11.** «Si no hay técnica, no hay método.» ¿Qué respondes? 🟠

**S12.** Tu interactivo funciona en la terminal y da *Idleness Limit Exceeded* en el juez. ¿Qué ha pasado? 🟠

**S13.** «Si hay muchas respuestas válidas, el problema es más fácil.» ¿Qué respondes? 🟠

**S14.** Tu simulación con detección de ciclo da una respuesta distinta de la simulación lenta. ¿Qué miras? 🟠

**S15.** Tu programa imprime `0,11` en tu máquina y el juez espera `0.11`. ¿Qué ha pasado? 🟠

**S16.** «Si no es óptimo, no sirve.» ¿Qué respondes, ante un viajante de 500 ciudades? 🟠

**S17.** El invariante de tu problema vale lo mismo en el estado inicial y en el objetivo. ¿Ya sabes que se
puede? 🟠

**S18.** En una prueba de 90 minutos te quedan 15 y el problema 3 no está. ¿Qué haces? 🟠

**S19.** Demuestra que un caballo de ajedrez no puede volver a su casilla en un número impar de saltos. 🔴

**S20.** Diseña una estrategia para encontrar la moneda más pesada entre 100 con una balanza, en el menor número
de pesadas posible en el peor caso, y demuestra que no se puede con menos. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Los camaleones

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** encontrar el invariante, y ver cuándo no basta.

En una isla hay camaleones rojos (`R`), verdes (`G`) y azules (`B`). Cuando dos de colores distintos se
encuentran, los dos pasan a ser del tercer color. Imprime, en el orden `R G B`, los colores en los que pueden
llegar a estar **todos** los camaleones a la vez, o `NINGUNO`.

- **Entrada.** Una línea con `r`, `g` y `b`.
- **Salida.** Los colores separados por espacios, o `NINGUNO`.
- **Restricciones.** `0 ≤ r, g, b ≤ 10¹⁸`; `r + g + b ≥ 1`.

```text
Entrada         Salida
1 2 3           NINGUNO

Entrada         Salida
4 1 1           R G B

Entrada         Salida
0 1 1           R
```

**Pista 1:** ¿qué le pasa a la diferencia entre el número de verdes y el de azules en cada encuentro, mirada
módulo algo?

### Récords

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo; se acepta cualquier respuesta válida.

**Fuerza:** construir en lugar de buscar.

Un récord de una secuencia es un elemento mayor que todos los anteriores (el primero siempre lo es). Imprime una
permutación de `1..n` con exactamente `k` récords, o `-1` si no existe.

- **Entrada.** Una línea con `n` y `k`.
- **Salida.** `n` números, o `-1`.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `0 ≤ k ≤ 10⁶`.

```text
Entrada         Una salida válida
5 2             4 1 2 3 5

Entrada         Salida
3 0             -1

Entrada         Salida
4 4             1 2 3 4
```

**Pista 1:** ¿qué valores de `k` son imposibles, y qué pasa con los récords si pones los números grandes al
final en orden creciente?

### Días hábiles

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** fechas con la librería, sin reescribir el calendario.

Cuenta los días hábiles (de lunes a viernes, sin festivos) entre dos fechas, las dos incluidas.

- **Entrada.** Una línea con dos fechas `AAAA-MM-DD`. Una línea con `h`. Después, `h` líneas con un festivo.
- **Salida.** Un entero.
- **Restricciones.** Las fechas están entre 1900 y 2100, la primera no es posterior a la segunda; `0 ≤ h ≤ 10⁵`.

```text
Entrada                      Salida
2026-10-01 2026-10-12        7
1
2026-10-12

Entrada                      Salida
2024-02-26 2024-03-04        6
0
```

**Pista 1:** con hasta 200 años de rango, ¿cuánto cuesta recorrer los días uno a uno, y cómo sabes el día de la
semana sin calcularlo tú?

### La cola del banco

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** simular sin buscar un truco que no hace falta.

Un banco tiene una sola ventanilla. Los clientes llegan en orden, cada uno en el instante `aᵢ` y necesita `sᵢ`
minutos. Se atiende por orden de llegada. Imprime la suma de los tiempos de espera (desde que llega hasta que le
atienden) y el instante en que termina el último.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `aᵢ` y `sᵢ`, con los `aᵢ` no decrecientes.
- **Salida.** Dos enteros.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `0 ≤ aᵢ ≤ 10⁹`; `1 ≤ sᵢ ≤ 10⁴`.

```text
Entrada           Salida
4                 10 12
0 5
1 3
2 1
10 2

Entrada           Salida
2                 10000 1000020000
1000000000 10000
1000000000 10000
```

**Pista 1:** ¿qué tienes que recordar mientras recorres los clientes, y cuándo empieza a atender al siguiente?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Teemo Attacking](https://leetcode.com/problems/teemo-attacking/) | LeetCode | 🟢 | Si un ataque llega antes de que acabe el veneno anterior, ¿cuánto suma de verdad? |
| [ ] | [Different Differences](https://codeforces.com/problemset/problem/1772/C) | Codeforces | 🟢 | Si las diferencias crecen de uno en uno, ¿cuándo te pasas de `n`, y qué haces con los que faltan? |
| [ ] | [Binary Period](https://codeforces.com/problemset/problem/1342/B) | Codeforces | 🟡 | Si la cadena tiene ceros y unos, ¿qué periodo es el menor posible, y qué cadena lo consigue conteniéndola? |
| [ ] | [Seating System](https://adventofcode.com/2020/day/11) | Advent of Code | 🟡 | ¿Por qué hay que calcular el estado nuevo entero antes de sustituir el viejo? |
| [ ] | [Beautiful Permutation II](https://cses.fi/problemset/task/3175) | CSES | 🟠 | Si eliges siempre el menor número que no rompe la condición, ¿cuándo te quedas sin opción al final? |

---

## ✅ Las frases que hay que tener listas

> «Si no se parece a nada, busco qué no cambia: paridad, resto, suma. El invariante demuestra el no; para el
> sí, construyo.»

> «En un interactivo, *flush* después de cada pregunta y la cota de `log_b` de las posibilidades antes de
> diseñar. En un constructivo, verificador antes de enviar.»

> «En una prueba de empresa: dos lecturas del enunciado, fechas con la librería, dinero en céntimos, salida
> comparada carácter a carácter y una versión correcta enviada pronto.»

---

**Anterior:** [`20/05` — Heurísticos y aproximados](05-heuristicos-y-aproximados.md) · **Siguiente:** [`20/07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`20/01` — Ad hoc y simulación](01-ad-hoc-y-simulacion.md).
