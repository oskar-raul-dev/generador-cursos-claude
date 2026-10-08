# 05 — Simulación

> El examen del bloque `11`: preguntas que cruzan las propiedades de un voraz, sus pruebas, los intervalos,
> los plazos, Huffman, las monedas y las matroides; cuatro problemas propios cronometrados que no dicen de
> qué capítulo son —y en uno de ellos el voraz falla—, y cinco problemas externos que no aparecen antes en
> el bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](06-respuestas.md#05--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 25 minutos por problema propio.
- **En voz alta.** Antes de cada problema, di la regla voraz candidata y **un intento de romperla**. Si no
  sabes romperla ni demostrarla, escribe la fuerza bruta y compara ([`11/04`](04-matroides-y-contraejemplos.md)).
- **Tecleando de verdad**, con un *stress test* en el problema de los contratos ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Cuándo funciona

**S1.** ¿Qué dos propiedades necesita un voraz para ser correcto? 🟢

**S2.** ¿Qué dos formas de prueba hay, y cuándo encaja cada una? 🟡

**S3.** ¿Cómo sacas el comparador de un problema de ordenación con la cuenta del intercambio de vecinos? 🟡

### Intervalos

**S4.** ¿Por qué orden se resuelven la selección, el cubrimiento con puntos, la mezcla y las salas? 🟢

**S5.** ¿Qué relación hay entre el mínimo de puntos que pinchan unos intervalos y el máximo de disjuntos? 🟡

**S6.** ¿Qué es la profundidad y por qué es el número de salas? 🟡

### Plazos, Huffman, mochila y monedas

**S7.** ¿Qué hace el montículo en la planificación con plazos, y qué tarea suelta? 🟢

**S8.** ¿Qué une Huffman y cuánto cuesta el código resultante? 🟢

**S9.** ¿Por qué la mochila fraccionaria es voraz y la 0/1 no? 🟡

**S10.** ¿Cómo sabes si un sistema de monedas es canónico? 🟡

### Matroides y contraejemplos

**S11.** ¿Qué dice el teorema de Rado-Edmonds? 🟡

**S12.** ¿Por qué se buscan contraejemplos con entradas pequeñas? 🟢

### Las que descolocan

**S13.** «Funciona en los cinco ejemplos que probé, así que el voraz es correcto.» ¿Qué respondes? 🟠

**S14.** Te piden el máximo de **beneficio** con trabajos que no se solapan. ¿Por qué no ordenar por final? 🟠

**S15.** «El cambio de monedas es voraz.» ¿Cuándo es verdad y cuándo no? 🟠

**S16.** Tu mínimo de salas da uno más que lo esperado cuando dos reuniones se tocan en un instante. ¿Qué cambias? 🟠

**S17.** Unir montones **vecinos** pagando la suma: ¿Huffman? 🟠

**S18.** «Ordeno las tareas por duración y listo.» El coste tiene pesos. ¿Qué falla? 🟠

**S19.** Demuestra con «el voraz se adelanta» que el voraz de saltos de Jump Game II da el mínimo de saltos. 🔴

**S20.** Demuestra que la concatenación ordenada con `a + b < b + a` da la cadena lexicográficamente menor. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Contratos

**Nivel:** 🟠 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** reconocer que el voraz por final falla con pesos y que hace falta otra cosa.

Una empresa recibe `n` ofertas de contrato. La oferta `i` ocupa el intervalo `[s, f)` y paga `w`. No puede
atender dos contratos que se solapen. Imprime el pago máximo.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `s f w`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `0 ≤ s < f ≤ 10⁹`; `1 ≤ w ≤ 10⁹`.

```text
Entrada        Salida
3              10
0 10 10
0 5 3
5 10 3

Entrada        Salida
11             19
1 4 5
3 5 1
0 6 8
5 7 4
3 9 6
5 9 3
6 10 2
8 11 4
8 12 7
2 14 9
12 16 3
```

**Pista 1:** con el contrato `i` elegido, ¿qué contratos anteriores siguen siendo compatibles, y cómo los
encuentras rápido?

### Recuperaciones

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** ver que «minimizar la multa» es el complementario de «maximizar lo que se salva».

Un profesor corrige un examen por día, desde el día 1. Cada examen tiene un plazo y una multa si se
corrige después de su plazo. Imprime la multa total mínima.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `plazo multa`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ plazo ≤ 10⁹`; `1 ≤ multa ≤ 10⁹`.

```text
Entrada     Salida
6           8
2 5
1 2
2 9
1 1
3 5
3 6

Entrada     Salida
3           6
1 3
1 3
1 3
```

**Pista 1:** las multas que se pagan son las de los exámenes que no se corrigen a tiempo: ¿qué conjunto
conviene corregir a tiempo?

### La concatenación más pequeña

**Nivel:** 🟡 · **Tiempo:** 25 minutos · **Formato:** programa completo.

**Fuerza:** obtener el comparador de una prueba de intercambio.

Dadas `n` cadenas de letras minúsculas, imprime la cadena lexicográficamente más pequeña que se obtiene
concatenándolas todas en algún orden.

- **Entrada.** Una línea con `n`. Después, `n` líneas con una cadena.
- **Salida.** La cadena.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; la suma de longitudes no pasa de `10⁶`.

```text
Entrada     Salida
3           abab
ba
b
a

Entrada     Salida
3           cbacbc
c
cb
cba
```

**Pista 1:** si `x` va justo antes que `y` en la respuesta, ¿qué tiene que cumplirse entre `x + y` e
`y + x`?

### Turnos con preferencias

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no buscar un voraz cuando la fuerza bruta cabe.

Hay `n` trabajadores y `n` turnos; `g[i][j]` es la satisfacción del trabajador `i` con el turno `j`. Cada
trabajador recibe un turno distinto. Imprime la satisfacción total máxima.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `n` enteros.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 9`; `0 ≤ g[i][j] ≤ 10⁶`.

```text
Entrada     Salida
3           23
5 2 9
1 5 6
9 1 5

Entrada     Salida
2           16
9 8
8 1
```

**Pista 1:** si el primer trabajador se queda con su turno favorito, ¿qué le pasa al segundo en el ejemplo
de 2 × 2?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Boats to Save People](https://leetcode.com/problems/boats-to-save-people/) | LeetCode | 🟡 | La persona más pesada, ¿con quién conviene emparejarla? |
| [ ] | [Minimum Number of Arrows to Burst Balloons](https://leetcode.com/problems/minimum-number-of-arrows-to-burst-balloons/) | LeetCode | 🟡 | El globo que acaba antes necesita una flecha: ¿dónde la pones? |
| [ ] | [Max Min](https://www.hackerrank.com/challenges/angry-children/problem) | HackerRank | 🟡 | Si eliges `k` paquetes, ¿cómo están colocados en el arreglo ordenado los de la mejor elección? |
| [ ] | [Advantage Shuffle](https://leetcode.com/problems/advantage-shuffle/) | LeetCode | 🟡 | Contra el rival más fuerte que no puedes ganar, ¿qué carta sacrificas? |
| [ ] | [Bag of Tokens](https://leetcode.com/problems/bag-of-tokens/) | LeetCode | 🟡 | Para ganar puntos, ¿qué ficha gastas; para recuperar energía, cuál sacrificas? |

---

## ✅ Las frases que hay que tener listas

> «Un voraz es correcto porque tiene una prueba —intercambio o "se adelanta"—, no porque parezca obvio. Antes
> de escribirlo, intento romperlo.»

> «Por final para seleccionar y pinchar; por inicio para mezclar; inicios y finales por separado para las
> salas. Con pesos, ya no es voraz: es una DP.»

> «Si el problema es una matroide, el voraz por peso es correcto para cualquier peso. Si no lo es, hay pesos
> que lo rompen.»

---

**Anterior:** [`11/04` — Matroides y cómo romper un voraz](04-matroides-y-contraejemplos.md) · **Siguiente:**
[`11/06` — Respuestas](06-respuestas.md) · **Relacionado:** [`11/01` — Cuándo funciona un voraz](01-cuando-funciona-un-voraz.md).
