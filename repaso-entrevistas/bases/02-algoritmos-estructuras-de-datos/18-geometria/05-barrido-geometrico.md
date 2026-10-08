# 05 — Barrido geométrico

> Una recta imaginaria recorre el plano de izquierda a derecha y se detiene solo donde pasa algo: en cada
> parada, una estructura ordenada guarda lo que la recta está tocando. Con esa idea, el par de puntos más
> cercano sale en `Θ(n log n)`, el área de la unión de rectángulos también, y todas las intersecciones de un
> conjunto de segmentos en `O((n + k) log n)`.
>
> **Niveles:** par más cercano [B] · unión de rectángulos [C] · Bentley-Ottmann [C].
>
> **📚 Lectura troncal:** de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed.
> (Springer, 2008), cap. 2; Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §5.4.
>
> **Asume leído:** [`18/02` — Rectas y segmentos](02-rectas-y-segmentos.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--par-más-cercano) · [4](#4--unión-de-rectángulos) · [5](#5--bentley-ottmann) · [6](#6-️-la-tabla-de-costes) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Hay `10⁵` antenas y hay que encontrar las dos más cercanas, porque interfieren. Comparar todos los pares son
`5·10⁹` distancias. [`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md) ya lo
resolvió en `Θ(n log n)` partiendo el plano por la mitad. Este capítulo lo resuelve de otra forma, que se
escribe con menos riesgo en un juez y que sirve para muchos más problemas: **barrer**.

El barrido ya apareció en una dimensión en [`04/04`](../04-secuencias/04-compresion-y-barrido.md): ordenar
los eventos (inicios y finales de intervalos) y recorrerlos llevando un estado. En el plano, el estado deja de
ser un contador y pasa a ser una **estructura ordenada** de lo que la recta corta en ese momento: los puntos
cercanos ordenados por `y`, o los tramos de `y` cubiertos por rectángulos.

> 🧠 **Modelo mental.** El barrido convierte un problema de dos dimensiones en una secuencia de problemas de
> una: la `x` la da el orden de los eventos; la `y`, la estructura.

Los ejemplos usan los puntos de juguete `(0,0) (4,0) (4,3) (0,3) (2,1)`, cuyo par más cercano está a `√5`, y
los rectángulos `[0,4]×[0,3]` y `[2,6]×[1,5]` de [`18/03`](03-poligonos.md), cuya unión mide 24.

---

## 2. 📐 La teoría

**El esquema.** Un barrido tiene tres piezas:

1. **Los eventos**: los puntos de parada, ordenados por `x` (inicio y fin de cada rectángulo, cada punto,
   cada extremo de segmento).
2. **El estado**: una estructura sobre `y` con lo que la recta corta: un conjunto ordenado, un *segment tree*,
   un Fenwick.
3. **El invariante**: lo que el estado garantiza en cada parada, y lo que se actualiza en ella.

**Par más cercano por barrido.** Se ordenan los puntos por `x`. Se lleva la mejor distancia `d` hasta ahora y
el conjunto **activo** de los puntos con `x` a menos de `d` del punto actual, ordenados por `y`. Al llegar el
punto `p`, se sacan del activo los que quedaron a más de `d` en `x`, se miran los activos con `y` entre
`p.y − d` y `p.y + d`, y se actualiza `d`.

**Por qué la franja tiene pocos puntos por celda.** Los activos que se miran están en un rectángulo de
`d × 2d` a la izquierda de `p`. Partido en ocho cuadrados de lado `d/2`, cada cuadrado tiene como mucho un
punto: dos puntos en el mismo cuadrado estarían como mucho a `d/√2 < d`, contra la definición de `d`
(todos los activos ya se compararon entre sí). Así que se miran como mucho 8 puntos por paso, y el coste es el
del conjunto ordenado: `Θ(n log n)`.

**Unión de rectángulos.** Eventos: los lados verticales (izquierdo, `+1`; derecho, `−1`). Estado: un
*segment tree* sobre las `y` comprimidas que guarda cuántas veces está cubierto cada tramo y la longitud
cubierta. Entre dos eventos consecutivos, el área que se añade es `longitud cubierta × Δx`.

**Bentley-Ottmann.** Eventos: los extremos de los segmentos **y las intersecciones** que se van descubriendo.
Estado: los segmentos que corta la recta, ordenados por su `y` en la `x` actual. Dos segmentos solo pueden
cortarse después de ser vecinos en ese orden: basta comprobar vecinos al insertar, al borrar y al cruzar.

---

## 3. 🧱 Par más cercano

**Qué es.** Las dos más cercanas de `n` puntos, en `Θ(n log n)`, con un conjunto ordenado por `y`.

**Por qué es correcto.** El invariante: al procesar `p`, el par más cercano con `p` como punto derecho o está
en la ventana `[p.x − d, p.x] × [p.y − d, p.y + d]`, o está a más de `d` y no mejora. La ventana tiene como
mucho 8 activos (§2).

**Cómo va**, con los puntos ordenados por `x` (el activo se guarda como `(y, x)`):

```text
(0,0)  activo {(0,0)}                        d² = ∞
(0,3)  compara con (0,0): 9                  d² = 9    activo {(0,0), (3,0)}
(2,1)  compara con los dos: 5 y 8            d² = 5    activo {(0,0), (1,2), (3,0)}
(4,0)  ventana en x: d = ⌊√5⌋ + 1 = 3 → salen (0,0) y (0,3); compara con (2,1): 5
(4,3)  compara con (2,1) y (4,0): 8 y 9      d² = 5 → la respuesta es √5
```

**Cuánto.** `Θ(n log n)`: ordenar, y cada punto se inserta, se borra y mira como mucho 8 vecinos, con
operaciones `O(log n)` del conjunto.

**La plantilla:**

```cpp
#include <algorithm>
#include <climits>
#include <cmath>
#include <set>
#include <utility>
#include <vector>

// Menor distancia al cuadrado entre dos de los puntos (n ≥ 2).
long long closestPair(std::vector<Pt> pts) {
    std::sort(pts.begin(), pts.end(), [](Pt a, Pt b) { return a.x < b.x; });
    std::set<std::pair<long long, long long>> active;            // (y, x) de los activos
    long long best = LLONG_MAX;
    int left = 0;
    for (int i = 0; i < (int) pts.size(); i++) {
        long long d = (long long) std::sqrt((double) best) + 1;  // ancho de la ventana, por exceso
        while (pts[i].x - pts[left].x > d) {                     // salen los que quedaron lejos en x
            active.erase({pts[left].y, pts[left].x});
            left++;
        }
        auto it = active.lower_bound({pts[i].y - d, LLONG_MIN});
        for (; it != active.end() && it->first <= pts[i].y + d; ++it) {
            long long dx = pts[i].x - it->second, dy = pts[i].y - it->first;
            best = std::min(best, dx * dx + dy * dy);
        }
        active.insert({pts[i].y, pts[i].x});
    }
    return best;
}
```

```java
static long closestPair(Pt[] input) {
    Pt[] pts = input.clone();
    java.util.Arrays.sort(pts, java.util.Comparator.comparingLong(Pt::x));
    java.util.TreeSet<long[]> active = new java.util.TreeSet<>(
        (a, b) -> a[0] != b[0] ? Long.compare(a[0], b[0]) : Long.compare(a[1], b[1]));  // (y, x)
    long best = Long.MAX_VALUE;
    int left = 0;
    for (Pt p : pts) {
        long d = (long) Math.sqrt((double) best) + 1;
        while (p.x() - pts[left].x() > d) {
            active.remove(new long[]{pts[left].y(), pts[left].x()});
            left++;
        }
        for (long[] q : active.tailSet(new long[]{p.y() - d, Long.MIN_VALUE}, true)) {
            if (q[0] > p.y() + d) break;
            long dx = p.x() - q[1], dy = p.y() - q[0];
            best = Math.min(best, dx * dx + dy * dy);
        }
        active.add(new long[]{p.y(), p.x()});
    }
    return best;
}
```

- **Distancias al cuadrado, ventana por exceso.** `best` es exacto en enteros; el ancho `d` se calcula con
  una raíz en `double` y se suma 1, para no dejar fuera un par justo en el borde por redondeo.
- **El activo guarda `(y, x)`** para ordenar por `y` y poder borrar un punto concreto. En Java, `TreeSet`
  con un comparador sobre `long[]` (los arreglos no tienen `equals` por contenido, pero el `TreeSet` usa el
  comparador); `tailSet(…).iterator()` recorre desde `p.y − d`.
- **Puntos repetidos.** El segundo encuentra al primero en la ventana y da distancia 0; el `set` no guarda
  duplicados, pero borrar dos veces el mismo `(y, x)` es inofensivo.
- **Python** no tiene conjunto ordenado en la librería estándar: `sortedcontainers` no está en todos los
  jueces. La alternativa es la rejilla: celdas de lado `d` en un diccionario, que se rehace cuando `d` baja.

**Cuándo sí:** el par más cercano de `10⁵` puntos en un juez; distancias mínimas entre dos conjuntos (con dos
activos). **Cuándo no:** con `n ≤ 3 000`, todos los pares; en una entrevista que pide el esquema de divide y
vencerás, la versión de `10/05`.

> **Veredicto:** el barrido es el par más cercano que se escribe sin miedo en un juez: ordenar por `x`, un
> conjunto por `y` y una ventana. Distancias al cuadrado, y la ventana redondeada hacia arriba.

---

## 4. 🧱 Unión de rectángulos

**Qué resuelve.** El área (o el perímetro) de la unión de `n` rectángulos alineados con los ejes.

**Qué garantiza.** Con un *segment tree* sobre las `y` comprimidas que guarda, por nodo, cuántas veces está
cubierto entero y la longitud cubierta de su tramo, cada evento cuesta `O(log n)`, sin propagación perezosa:
un nodo cubierto al menos una vez aporta su tramo entero, y si no, la suma de sus hijos. Con
`[0,4]×[0,3]` y `[2,6]×[1,5]`: entre `x = 0` y `2` se cubre `[0,3]` (6); entre 2 y 4, `[0,5]` (10); entre 4 y
6, `[1,5]` (8): total 24.

**Cuánto.** `Θ(n log n)`.

**Cómo reconocerlo.** «Área total cubierta por `n` alfombras, carteles, manchas rectangulares» con
`n = 10⁵` o coordenadas de `10⁹`.

**Si no te la sabes.** Con `n ≤ 300`, compresión de coordenadas en los dos ejes y marcar las celdas cubiertas:
`O(n³)` o `O(n²)` con diferencias en dos dimensiones ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)).

**Dónde está entera.** de Berg y otros, cap. 10 (los *segment trees* para intervalos); cp-algorithms tiene la
versión en una dimensión, [*Length of the union of segments*](https://cp-algorithms.com/geometry/length-of-segments-union.html).

---

## 5. 🧱 Bentley-Ottmann

**Qué resuelve.** Todas las intersecciones de `n` segmentos, o saber si hay alguna.

**Qué garantiza.** Las `k` intersecciones en `O((n + k) log n)`. Para la pregunta «¿hay algún par que se
corte?», el algoritmo de Shamos y Hoey se detiene en la primera: `O(n log n)`. Ambos dependen de que dos
segmentos que se cortan sean **vecinos** en el orden de la recta justo antes del corte.

**Cuánto.** `O((n + k) log n)`; si `k` es del orden de `n²`, es peor que comparar todos los pares.

**Cómo reconocerlo.** «¿Se corta este trazado?» con `10⁵` tramos; «cuántos cruces hay» entre muchos
segmentos con pocas intersecciones; «¿es simple este polígono?» con `10⁵` lados.

**Si no te la sabes.** Con `n ≤ 3 000`, todos los pares con la función de
[`18/02`](02-rectas-y-segmentos.md). Con segmentos solo horizontales y verticales, un barrido con un Fenwick
sobre `y` cuenta los cruces en `O(n log n)`, y es mucho más simple.

**Dónde está entera.** de Berg y otros, cap. 2; cp-algorithms, [*Search for a pair of intersecting segments*](https://cp-algorithms.com/geometry/intersecting_segments.html).

---

## 6. ⏱️ La tabla de costes

| Problema | Directo | Con barrido | Lo que la tabla no dice |
|---|---|---|---|
| Par más cercano | `Θ(n²)` | `Θ(n log n)` | Divide y vencerás da lo mismo (`10/05`); la rejilla, esperado lineal con datos uniformes |
| Unión de rectángulos | `O(n³)` compresión | `Θ(n log n)` | El *segment tree* sin perezosa: cuenta y longitud por nodo |
| ¿Algún par de segmentos se corta? | `Θ(n²)` | `O(n log n)` | Los casos degenerados (verticales, extremos compartidos) son el trabajo real |
| Todas las intersecciones | `Θ(n²)` | `O((n + k) log n)` | Con `k ≈ n²`, el directo gana |

---

## 7. 🧭 Cómo se elige

```text
¿Par más cercano? → n ≤ 3 000: todos los pares · si no: barrido (juez) o divide y vencerás (entrevista)
¿Unión de rectángulos? → n ≤ 300: compresión y celdas · si no: barrido con segment tree
¿Cruces de segmentos? → n ≤ 3 000: todos los pares · solo ejes: Fenwick · general: Bentley-Ottmann
¿Intervalos en una dimensión? → 04/04, sin estructura ordenada
```

> **Regla de entrevista:** si te piden el par más cercano, nombra las dos versiones —«divide y vencerás con el
> lema de la franja, o barrido con un conjunto ordenado por `y`»— y escribe la que pidan.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Las dos más cercanas» con `n = 10⁵` | Barrido con conjunto por `y` | Ventana de 8 puntos |
| «Área total cubierta», `n = 10⁵` | Barrido con *segment tree* | Longitud cubierta por evento |
| «Segmentos horizontales y verticales, cuántos cruces» | Barrido con Fenwick | Las verticales consultan, las horizontales entran y salen |
| «¿Algún par de segmentos se corta?» con `10⁵` | Shamos-Hoey | Vecinos en el orden de la recta |
| Puntos «uniformemente al azar» | Rejilla de celdas de lado `d` | Esperado lineal |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El par más cercano es `O(n²)`» | `Θ(n log n)` con barrido o con divide y vencerás |
| «En el barrido se compara con todos los activos» | Solo con los de la ventana de alto `2d`: como mucho 8 |
| «Para los activos basta un `HashSet`» | Hace falta orden por `y` para recorrer solo la ventana: `set` o `TreeSet` |
| «La unión de rectángulos es la suma menos las intersecciones por pares» | Solo con dos; con más, inclusión-exclusión exponencial o barrido |
| «Bentley-Ottmann es `O(n log n)`» | Es `O((n + k) log n)`; la versión que solo decide si hay alguno, sí |
| «La ventana se calcula con `sqrt` y ya» | Redondea hacia arriba con margen, o se pierde el par justo en el borde |

---

## 📚 Para profundizar

- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), cap. 2: el barrido para intersecciones de segmentos, con los casos degenerados. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), §5.4: el par más cercano y el
  lema de la franja. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Finding the nearest pair of points*](https://cp-algorithms.com/geometry/nearest_points.html).
- **Referencia** — cp-algorithms, [*Search for a pair of intersecting segments*](https://cp-algorithms.com/geometry/intersecting_segments.html).
- **Artículo** — Bentley y Ottmann, «Algorithms for reporting and counting geometric intersections», *IEEE
  Transactions on Computers* C-28(9), 1979.

---

## 🧠 Preguntas

1. ¿Qué es un barrido geométrico y cuáles son sus tres piezas? 🟢
2. ¿Cuánto cuesta el par más cercano por barrido, y qué estructura lo permite? 🟢
3. ¿Cuánto cuesta el área de la unión de `n` rectángulos con un barrido? 🟢
4. ¿Qué resuelve Bentley-Ottmann y cuánto cuesta? 🟢
5. ¿Qué diferencia hay entre el par más cercano por divide y vencerás y por barrido? 🟡
6. ¿Por qué la ventana del barrido contiene como mucho 8 puntos? 🟡
7. ¿Qué tiene en común este barrido con el de intervalos de `04/04`, y qué cambia? 🟡
8. ¿Qué cambia entre C++, Java y Python para guardar el conjunto activo ordenado por `y`? 🟠
9. ¿Por qué la ventana se redondea hacia arriba, y qué pasa si no? 🟠
10. ¿Cuándo basta comparar todos los pares, y cuándo una rejilla es mejor que el barrido? 🟠
11. Demuestra que dos segmentos que se cortan son vecinos en el orden de la recta de barrido justo antes del
    punto de corte (suponiendo que no hay tres segmentos por un mismo punto). 🔴
12. Traza el barrido del área de la unión de `[0,4]×[0,3]` y `[2,6]×[1,5]`: los eventos, la longitud cubierta
    entre ellos y el área acumulada. 🔴

---

## 🧩 Problemas propios

### El enchufe más cercano

**Nivel:** 🟠 · **Formato:** programa completo.

En una nave hay `n` máquinas y `m` enchufes. ¿Cuál es el cuadrado de la menor distancia entre una máquina y un
enchufe?

- **Entrada.** Una línea con `n` y `m`. Después, `n` líneas con las máquinas y `m` líneas con los enchufes.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n, m ≤ 10⁵`; coordenadas enteras con `|·| ≤ 10⁹`.

```text
Entrada         Salida
2 3             5
0 0
4 3
4 0
0 3
2 1

Entrada         Salida
1 2             25
0 0
3 4
10 0
```

**Pista 1:** si barres todos los puntos juntos por `x`, ¿contra qué puntos de la ventana tiene sentido
comparar una máquina, y qué guardas para poder hacerlo?

### El contorno de los puestos

**Nivel:** 🔴 · **Formato:** programa completo.

En una feria hay `n` puestos rectangulares, alineados con los ejes, que pueden solaparse. Se quiere rodear con
cinta todo el borde de la zona ocupada, incluidos los bordes de los huecos interiores. ¿Cuánta cinta hace
falta?

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x₁ y₁ x₂ y₂`, con `x₁ < x₂` e `y₁ < y₂`.
- **Salida.** Un entero: el perímetro de la unión.
- **Restricciones.** `1 ≤ n ≤ 1 000`; coordenadas con `|·| ≤ 10⁹`.

```text
Entrada         Salida
2               22
0 0 4 3
2 1 6 5

Entrada         Salida
2               12
0 0 2 2
2 0 4 2
```

**Pista 1:** si comprimes las coordenadas, el plano queda en unas `2n × 2n` celdas, cada una cubierta o no.
¿Qué lados de una celda cubierta forman parte del contorno?

---

## 🧩 Práctica externa

> 💡 **Truco.** Compara tu barrido con la versión de todos los pares en casos pequeños al azar, incluidos
> puntos repetidos y con la misma `x`: son los que rompen la ventana. Si una IA te ayuda, que sea a escribir el
> generador, no el barrido ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). SPOJ no
> se enlaza (`403`).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [The Rectangles Are Surrounding Us!](https://open.kattis.com/problems/rectanglesurrounding) | Kattis | 🟢 | Unión en rejilla pequeña | Con coordenadas tan pequeñas, ¿cuántas celdas unitarias hay en total? |
| [ ] | [Closest Pair (Uniform)](https://open.kattis.com/problems/closestpair1) | Kattis | 🟡 | Rejilla | Si los puntos están repartidos al azar, ¿cuántos caen en una celda del tamaño de la respuesta? |
| [ ] | [Rectangle Area II](https://leetcode.com/problems/rectangle-area-ii/) | LeetCode | 🟠 | Compresión y barrido | Con 200 rectángulos, ¿cuántas franjas verticales distintas hay entre lados? |
| [ ] | [Minimum Euclidean Distance](https://cses.fi/problemset/task/2194) | CSES | 🟠 | Par más cercano | Si ordenas por `x`, ¿qué puntos anteriores pueden mejorar la mejor distancia hasta ahora? |
| [ ] | [Closest Pair](https://open.kattis.com/problems/closestpair2) | Kattis | 🟠 | Par más cercano | Con varios casos y puntos repetidos, ¿qué distancia devuelves si dos coinciden? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Intersection Points](https://cses.fi/problemset/task/1740) | CSES | 🟠 | Barrido con Fenwick | Si recorres por `x`, ¿qué hace una horizontal al empezar y al terminar, y qué pregunta una vertical? |
| [ ] | [Area of Rectangles](https://cses.fi/problemset/task/1741) | CSES | 🔴 | Unión con *segment tree* | Entre dos lados verticales consecutivos, ¿qué longitud de `y` está cubierta? |
| [ ] | [Robot Path](https://cses.fi/problemset/task/1742) | CSES | 🔴 | Primer autocruce | Si sabes en `O(n log n)` si los primeros `k` tramos se cortan, ¿cómo encuentras el primer `k` que lo hace? |
| [ ] | [Simple Polygon](https://open.kattis.com/problems/polygon) | Kattis | 🔴 | Shamos-Hoey | Con `40 000` lados no puedes comparar todos los pares: ¿qué pares de lados basta comprobar si barres de izquierda a derecha? |

---

## ✅ Criterio de dominio

- Escribir el par más cercano por barrido en C++ o Java sin mirar, en distancias al cuadrado.
- Explicar por qué la ventana tiene como mucho 8 puntos y qué guarda el *segment tree* de la unión.
- Nombrar Bentley-Ottmann y Shamos-Hoey con sus costes, y la alternativa para segmentos de ejes.
- Resolver Minimum Euclidean Distance y Rectangle Area II sin pista 2.

---

**Anterior:** [`18/04` — Envolvente convexa](04-envolvente-convexa.md) · **Siguiente:** [`18/06` — Geometría avanzada](06-geometria-avanzada.md) ·
**Relacionado:** [`10/05` — Divide y vencerás](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md).
