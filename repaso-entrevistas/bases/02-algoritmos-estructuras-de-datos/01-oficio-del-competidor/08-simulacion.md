# 08 — Simulación

> El examen del bloque `01`: preguntas que cruzan los siete capítulos, tres problemas propios
> cronometrados que no dicen de qué capítulo son, y seis problemas externos que no aparecen antes en
> el bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](09-respuestas.md#08--simulación).
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Las preguntas, a dos minutos cada una como máximo; los problemas, con el reparto
  de `01/06`: 30 minutos para los dos primeros y 20 para el tercero.
- **En voz alta.** Cada respuesta se dice como en una entrevista: primero la frase de 30 segundos,
  después el porqué. Si puedes, grábate.
- **Tecleando de verdad.** Los problemas se escriben en un editor sin autocompletado y se corren con
  la plantilla de [`01/03`](03-entrada-salida-y-plantilla.md), contra casos que escribes tú.
- **Solo después, el solucionario.** Anota qué preguntas fallaste y qué pista necesitaste en cada
  problema: eso dice qué capítulo repasar.

---

## 🧠 Preguntas

### El juez y los formatos

**S1.** ¿Qué te dice y qué no te dice el número del caso en que falla un envío? 🟢

**S2.** ¿Por qué el juez solo te muestra el primer veredicto distinto de AC? 🟢

**S3.** ¿Qué cambia en tu estrategia entre una prueba de Codility y un concurso de Codeforces? 🟡

**S4.** ¿Qué tres versiones de lenguaje fija el corpus y de dónde sale cada una? 🟡

### Restricciones, tipos y módulo

**S5.** Con `n ≤ 3 000`, ¿cabe `O(n²)`? ¿Y `O(n² log n)`? Haz las cuentas. 🟢

**S6.** ¿Cuántos `long long` caben en 64 MB? 🟢

**S7.** ¿Por qué `1 << 40` no vale `2⁴⁰` ni en C++ ni en Java, y qué da en cada uno? 🟡

**S8.** ¿Qué diferencia hay entre desbordar en Java y desbordar en C++, en cuanto a lo que puedes predecir? 🟡

**S9.** Un problema pide «el número de caminos, módulo 10⁹+7» y tu fórmula tiene una división. ¿Qué haces? 🟠

**S10.** Con `n ≤ 10⁵` y valores `≤ 10⁶`, ¿qué te permite el valor que no te permitiría con valores `≤ 10⁹`? 🟠

### Entrada, salida y plantilla

**S11.** ¿Qué dos líneas van al principio de todo `main` de C++ del corpus, y cuándo una de ellas sobra? 🟢

**S12.** ¿Qué olvido convierte la plantilla de Java en un WA en todos los casos? 🟢

**S13.** ¿Cuándo lees línea a línea en Python y cuándo todo de golpe? 🟡

**S14.** Tu solución en Python es `O(n)` con `n = 10⁶` y da TLE. ¿Qué miras antes de cambiar de algoritmo? 🟠

### Probar y depurar

**S15.** ¿Qué hace un *stress test* que no hace probar con el ejemplo? 🟢

**S16.** ¿Por qué la fuerza bruta de un *stress test* no debe compartir código con la solución? 🟡

**S17.** ¿Qué tipo de fallo no encuentra un *stress test* con entradas pequeñas, y cómo lo buscas? 🟠

**S18.** El *sanitizer* de C++ se detiene en una línea con «signed integer overflow». ¿Qué te está diciendo, y por qué sin él podrías no verlo? 🟠

### Protocolo y en vivo

**S19.** ¿Qué fila de la ficha de antes suele llevar a la idea optimizada? 🟢

**S20.** ¿Cuándo pides la pista 2, y qué anotas cuando lo haces? 🟡

**S21.** ¿Qué dos frases dices después de escribir la versión ingenua en una entrevista en vivo? 🟡

**S22.** ¿Qué haces con la IA cuando llevas 20 minutos atascado en un problema de práctica? 🟠

### Las que descolocan

**S23.** Tu solución pasa el ejemplo y da WA en el caso 2. ¿Qué miras primero? 🟠

**S24.** ¿Y si `n` fuera `10¹²`? Para un problema de «suma de `1` a `n`», ¿qué cambia en tu solución? 🟠

**S25.** El entrevistador te dice «tu solución es correcta, ¿cuánta memoria usa?» y no lo habías pensado. Responde para una solución con un mapa de `n` enteros en Java. 🔴

**S26.** Te dan un problema con `n ≤ 15` y la idea óptima es una DP que no ves clara. Argumenta por qué escribirías otra cosa. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Registro de accesos

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** elegir la forma de leer; el algoritmo es trivial y la entrada no.

Un sistema registra `n` sesiones con su minuto de entrada y de salida dentro del mismo día. Imprime la
duración total de todas las sesiones y la duración de la más larga.

- **Entrada.** Una línea con `n`. Después, `n` líneas con dos enteros `entrada salida`.
- **Salida.** Dos enteros: la duración total y la máxima.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `0 ≤ entrada ≤ salida ≤ 1440`. Límite: 1 segundo.

```text
Entrada            Salida
3                  130 60
0 60
100 130
200 240

Entrada            Salida
1                  0 0
5 5
```

**Pista 1:** ¿cuántos números lees con el `n` máximo, y cuánto tarda en leerlos tu forma habitual?

### Área de los terrenos

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** decidir el tipo de cada operación y dónde reducir, cuando los ejemplos no lo muestran.

Hay `n` terrenos rectangulares. Imprime la suma de sus áreas, módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n`. Después, `n` líneas con dos enteros, el ancho y el largo.
- **Salida.** Un entero en `[0, 10⁹ + 6]`.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ ancho, largo ≤ 10⁹`.

```text
Entrada            Salida
2                  26
3 4
2 7

Entrada            Salida
1                  49
1000000000 1000000000
```

**Pista 1:** ¿cuánto vale el área de un solo terreno con las cotas máximas, y en qué tipo cabe?

🔥 **Para el geek — en JavaScript:** el área de un terreno ya pasa de `2⁵³`; la multiplicación modular
necesita `BigInt` o partir los factores.

### Equipos equilibrados

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que la fuerza bruta cabe y que es la solución más clara.

Hay `n` jugadores con su nivel. Hay que repartirlos en dos equipos no vacíos (no necesariamente del
mismo tamaño) de forma que la diferencia entre la suma de niveles de los dos equipos sea mínima.
Imprime esa diferencia.

- **Entrada.** Una línea con `n`. Una segunda línea con `n` enteros, los niveles.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 15`; `1 ≤ nivel ≤ 10⁹`.

```text
Entrada            Salida
4                  1
5 2 9 1

Entrada            Salida
2                  999999999
1 1000000000
```

**Pista 1:** ¿cuántas formas distintas hay de repartir 15 jugadores en dos equipos?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito: decidirlo es parte
del ejercicio.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Missing Number](https://leetcode.com/problems/missing-number/) | LeetCode | 🟢 | ¿Qué sabes de la suma de `0` a `n`, y cabe en el tipo? |
| [ ] | [First Unique Character in a String](https://leetcode.com/problems/first-unique-character-in-a-string/) | LeetCode | 🟢 | ¿Cuántas pasadas sobre la cadena necesitas para saber si un carácter se repite? |
| [ ] | [Birthday Cake Candles](https://www.hackerrank.com/challenges/birthday-cake-candles/problem) | HackerRank | 🟢 | ¿Necesitas ordenar para contar cuántas veces aparece el máximo? |
| [ ] | [Grading Students](https://www.hackerrank.com/challenges/grading/problem) | HackerRank | 🟢 | ¿Qué notas quedan fuera del redondeo, aunque estén cerca de un múltiplo de 5? |
| [ ] | [Beautiful Matrix](https://codeforces.com/problemset/problem/263/A) | Codeforces | 🟢 | ¿Cuántos movimientos separan una fila de la del centro? |
| [ ] | [Sum of Round Numbers](https://codeforces.com/problemset/problem/1352/A) | Codeforces | 🟢 | ¿Qué aporta cada dígito distinto de cero, según su posición? |

---

## ✅ Las frases que hay que tener listas

> «Con `n` hasta 2·10⁵ no me cabe un `n²`, que serían 4·10¹⁰ pasos; necesito `n log n` o mejor. Y
> como los valores llegan a 10⁹, la suma va en 64 bits.»

> «Empiezo por una versión directa, que es cuadrática, la pruebo con el ejemplo, y después la mejoro:
> lo que repito es esto, y con esta estructura cada paso es `O(1)`.»

> «Antes de reenviar, genero casos pequeños y comparo contra la fuerza bruta; con el caso que falla
> delante, el bug sale en dos minutos.»

---

**Anterior:** [`01/07` — Programar en vivo](07-programar-en-vivo.md) ·
**Siguiente:** [`01/09` — Respuestas](09-respuestas.md) ·
**Relacionado:** [`01/06` — El protocolo de resolución](06-protocolo-de-resolucion.md).
