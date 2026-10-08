# 07 — Simulación

> El examen del bloque `18`: preguntas que cruzan productos cruz, segmentos, polígonos, envolvente, barrido y
> lo que se nombra sin escribir; cuatro problemas propios cronometrados que no dicen de qué capítulo son —uno
> se resuelve con un doble bucle porque `n ≤ 2 000`—, y cinco problemas externos que no aparecen antes en el
> bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](08-respuestas.md#07--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos por problema propio (20 para el 🟢).
- **En voz alta.** Antes de cada problema, di qué tipo usas para las coordenadas y los productos, y qué casos
  degenerados (alineados, repetidos, verticales) tienes que cubrir.
- **Tecleando de verdad**, con un *stress test* contra la versión de todos los pares en el de los cables
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Lo básico y un patrón

**S1.** ¿Qué dice el signo de `(b − a) × (c − a)`? 🟢

**S2.** ¿Cómo calculas el área de un polígono simple dados sus vértices en orden? 🟢

**S3.** ¿Cuándo se solapan dos rectángulos alineados con los ejes? 🟢

**S4.** ¿Cuánto cuesta construir la envolvente convexa, y qué paso domina? 🟡

**S5.** ¿Cómo decides si un punto está sobre un segmento? 🟡

### Polígonos, envolvente, barrido y lo avanzado

**S6.** ¿Qué dice el teorema de Pick? 🟢

**S7.** ¿Cuánto cuesta encontrar el par más cercano de `n` puntos? 🟢

**S8.** ¿Cómo se calcula la distancia de un punto a un segmento? 🟡

**S9.** ¿Qué diferencia hay entre desapilar con `< 0` y con `≤ 0` en Andrew? 🟡

**S10.** ¿Qué relación hay entre el diagrama de Voronoi y la triangulación de Delaunay? 🟡

### Las que descolocan

**S11.** «La geometría es con `double`.» ¿Qué respondes? 🟠

**S12.** Tu intersección de segmentos dice que `(0,0)–(1,0)` y `(2,0)–(3,0)` se cortan. ¿Qué línea miras? 🟠

**S13.** Tu punto en polígono falla solo cuando el punto está a la altura de un vértice. ¿Qué ha pasado? 🟠

**S14.** El área de tu polígono sale negativa. ¿Está mal? 🟠

**S15.** Tu producto cruz en Java da resultados absurdos con coordenadas de `10⁹`, aunque guardas el resultado
en un `long`. ¿Por qué? 🟠

**S16.** Piden el par más lejano de `n = 2 000` puntos y alguien propone envolvente y *rotating calipers*. ¿Qué
dices? 🟠

**S17.** Tu envolvente que conserva los alineados devuelve puntos repetidos. ¿Qué entradas lo provocan? 🟠

**S18.** Comparas pendientes en `double` para ver si tres puntos están alineados, y falla un caso oculto. ¿Por
qué? 🟠

**S19.** Demuestra que la envolvente convexa no se puede calcular en `o(n log n)` en el modelo de
comparaciones. 🔴

**S20.** Diseña cómo calcular el área de la unión de `10⁵` rectángulos alineados con los ejes, y di el coste.
🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### El terreno con estanque

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** usar el área con signo sin depender de la orientación de la entrada.

Un terreno tiene forma de polígono simple y, dentro, un estanque también poligonal que no toca el borde del
terreno. Imprime el área del terreno sin el estanque, con un decimal. Cada polígono puede venir en sentido
horario o antihorario.

- **Entrada.** Una línea con `n`. Después, `n` líneas con los vértices del terreno. Una línea con `m`.
  Después, `m` líneas con los del estanque.
- **Salida.** Un real con un decimal (el área siempre es múltiplo de `0,5`).
- **Restricciones.** `3 ≤ n, m ≤ 10⁵`; coordenadas enteras con `|·| ≤ 10⁹`.

```text
Entrada         Salida
4               11.5
0 0
4 0
4 3
0 3
3
1 1
1 2
2 1

Entrada         Salida
4               10.0
0 0
4 0
4 3
0 3
4
1 1
1 2
3 2
3 1
```

**Pista 1:** ¿qué signo da la fórmula del área a cada polígono según el sentido en que vienen sus vértices, y
qué haces para no depender de eso?

### Capas de cebolla

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** repetir la envolvente y decidir qué pasa con los alineados.

Se pela un conjunto de puntos por capas: en cada paso se quitan todos los puntos que están sobre el borde de su
envolvente convexa (también los que caen en medio de un lado). Si los puntos que quedan están todos alineados
(o son uno o dos), forman la última capa. ¿Cuántas capas hay?

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`, todos distintos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2 000`; `|x|, |y| ≤ 10⁹`.

```text
Entrada         Salida
5               2
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
4               1
0 0
1 1
2 2
5 0
```

**Pista 1:** si sabes construir una capa en `O(n log n)`, ¿cuántas capas puede haber como mucho, y te alcanza
con repetir?

### Cables cruzados

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** escribir la intersección con todos sus casos.

En un panel hay `n` cables rectos. ¿Cuántos pares de cables se tocan o se cruzan? Cuentan el contacto en un
extremo y el solapamiento de dos cables sobre la misma recta.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x₁ y₁ x₂ y₂`, con extremos distintos.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2 000`; coordenadas con `|·| ≤ 10⁹`.

```text
Entrada         Salida
5               5
0 0 4 3
4 0 0 3
0 0 4 0
2 0 6 0
5 1 6 1

Entrada         Salida
3               2
0 0 1 0
2 0 3 0
1 0 2 0
```

**Pista 1:** con `2 000` cables hay unos dos millones de pares. Para cada par, ¿qué tres situaciones distintas
tienes que reconocer?

### Los dos faros más lejanos

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no usar una técnica avanzada cuando el doble bucle entra.

Hay `n` faros. Imprime el cuadrado de la mayor distancia entre dos de ellos.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 2 000`; `|x|, |y| ≤ 10⁹`.

```text
Entrada                  Salida
5                        25
0 0
4 0
4 3
0 3
2 1

Entrada                  Salida
2                        8000000000000000000
-1000000000 -1000000000
1000000000 1000000000
```

**Pista 1:** ¿cuántos pares hay con `2 000` faros, y de qué tamaño puede ser el cuadrado de una distancia?

---

## 🧩 Práctica externa

No aparecen antes en el bloque. La columna de patrón se oculta: decirlo sería la pista 2.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Beehives](https://open.kattis.com/problems/beehives) | Kattis | 🟢 | ¿Cuántas colmenas hay como mucho, y cuántos pares tienes que mirar? |
| [ ] | [Queries on Number of Points Inside a Circle](https://leetcode.com/problems/queries-on-number-of-points-inside-a-circle/) | LeetCode | 🟢 | ¿Cómo decides si un punto está dentro de un círculo sin raíces? |
| [ ] | [Number of Boomerangs](https://leetcode.com/problems/number-of-boomerangs/) | LeetCode | 🟡 | Fijado el punto del medio, ¿qué tienen en común los otros dos? |
| [ ] | [Detect Squares](https://leetcode.com/problems/detect-squares/) | LeetCode | 🟡 | Si conoces una esquina y la opuesta en diagonal, ¿dónde están las otras dos? |
| [ ] | [Maximum Number of Darts Inside of a Circular Dartboard](https://leetcode.com/problems/maximum-number-of-darts-inside-of-a-circular-dartboard/) | LeetCode | 🔴 | Si un círculo óptimo contiene varios dardos, ¿puedes moverlo hasta que pase por dos de ellos? |

---

## ✅ Las frases que hay que tener listas

> «Coordenadas enteras, productos en 64 bits, nada de pendientes: el giro es el signo de un producto cruz, y
> el área de un polígono, la suma de `pᵢ × p_{i+1}`.»

> «La intersección de segmentos tiene tres casos: se cruzan, se tocan en un extremo, son colineales. Con
> `< 0` estricto para el primero y `onSegment` para los otros dos.»

> «Envolvente con Andrew en `n log n`, que es óptimo; par más cercano con barrido o divide y vencerás en
> `n log n`; y con `n ≤ 2 000`, todos los pares.»

---

**Anterior:** [`18/06` — Geometría avanzada](06-geometria-avanzada.md) · **Siguiente:** [`18/08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md).
