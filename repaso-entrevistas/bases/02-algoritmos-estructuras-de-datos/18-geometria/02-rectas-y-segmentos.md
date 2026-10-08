# 02 — Rectas y segmentos

> Decidir si dos segmentos se cortan con cuatro productos cruz, sin olvidar los casos colineales; calcular
> dónde se cortan dos rectas, y las distancias de un punto a una recta y a un segmento. Todo apoyado en la
> orientación de [`18/01`](01-vectores-y-orientacion.md), en enteros mientras se pueda.
>
> **Niveles:** intersección de segmentos [B] · distancias [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §33.1; O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), caps. 1 y 7.
>
> **Asume leído:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--intersección-de-segmentos) · [4](#4--distancias) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Dos calles rectas, cada una entre dos esquinas. ¿Se cruzan? La respuesta escolar —calcular las dos rectas
con pendiente e intercepto, resolver el sistema y mirar si el punto cae dentro de los dos tramos— necesita
casos especiales para las verticales, divide, redondea, y aun así falla cuando las calles van por la misma
recta.

La respuesta de la geometría computacional no calcula el punto: pregunta **de qué lado** de cada calle quedan
los extremos de la otra. Si los extremos de cada una quedan a lados distintos de la otra, se cruzan. Son
cuatro productos cruz en enteros, más un caso aparte para los colineales, que es donde está casi todo el
error.

> 🧠 **Modelo mental.** Dos segmentos se cortan si cada uno **separa** los extremos del otro. Y si alguno
> de los cuatro extremos cae justo sobre la otra recta, ya no hay que mirar signos: hay que mirar si cae
> dentro del tramo.

Los ejemplos usan los puntos de juguete: las dos diagonales del rectángulo, `(0,0)–(4,3)` y `(4,0)–(0,3)`,
se cortan en `(2, 1,5)`; el punto `(2,1)` está a distancia `0,4` de la primera.

---

## 2. 📐 La teoría

**Punto sobre segmento.** `p` está en el segmento `ab` si y solo si `orient(a, b, p) = 0` (está en la recta)
y sus coordenadas caen entre las de `a` y `b` (está en el tramo). La segunda condición equivale a
`(a − p) · (b − p) ≤ 0`.

**Intersección de dos segmentos** `ab` y `cd`. Con `o₁ = orient(a, b, c)`, `o₂ = orient(a, b, d)`,
`o₃ = orient(c, d, a)` y `o₄ = orient(c, d, b)`:

```text
o₁·o₂ < 0  y  o₃·o₄ < 0                       → se cortan en un punto interior de los dos
si no, se tocan si y solo si algún extremo está sobre el otro segmento:
  c ∈ ab,  d ∈ ab,  a ∈ cd  o  b ∈ cd
si nada de eso → no se cortan
```

*Por qué.* Si `c` y `d` están a lados estrictamente distintos de la recta `ab`, el segmento `cd` cruza esa
recta en un único punto; si además `a` y `b` están a lados distintos de la recta `cd`, ese punto cae dentro
de `ab`. Cuando alguna orientación es 0, un extremo está **sobre la recta** del otro segmento, y el corte
existe solo si está **dentro del tramo**: eso cubre el contacto en un extremo y el solapamiento de dos
segmentos colineales.

**Punto de corte de dos rectas.** Las rectas `a + t (b − a)` y `c + s (d − c)` se cortan, si no son paralelas
(`(b − a) × (d − c) ≠ 0`), en

```text
t = ((c − a) × (d − c)) / ((b − a) × (d − c))         punto = a + t · (b − a)
```

Con coordenadas enteras, `t` es una fracción: el punto es racional, no entero.

**Distancias.** De `p` a la **recta** `ab`: `|(b − a) × (p − a)| / |b − a|` (el área del paralelogramo entre la
base). Al **segmento** `ab`: se proyecta, `t = ((p − a) · (b − a)) / |b − a|²`; si `t ≤ 0`, la distancia es
`|p − a|`; si `t ≥ 1`, `|p − b|`; si no, la distancia a la recta.

---

## 3. 🧱 Intersección de segmentos

**Qué es.** Decidir si dos segmentos tienen algún punto en común, contando el contacto en un extremo y el
solapamiento.

**Por qué es correcto.** El caso general separa con los signos; el colineal, con la pertenencia al tramo
(§2). Si cualquier orientación es 0, el caso general no aplica, y las cuatro comprobaciones de pertenencia
cubren todas las formas de tocarse.

**Cómo va**, con las diagonales `ab = (0,0)–(4,3)` y `cd = (4,0)–(0,3)`, y dos casos de borde:

```text
o₁ = orient(a, b, c) = −1    o₂ = orient(a, b, d) = +1     c y d a lados distintos de ab
o₃ = orient(c, d, a) = +1    o₄ = orient(c, d, b) = −1     a y b a lados distintos de cd
→ se cortan; t = 12 / 24 = 1/2, en (2, 1,5)

(0,0)–(4,0) y (4,0)–(4,3): o₁ = 0 y (4,0) ∈ (0,0)–(4,0) → se tocan en un extremo
(0,0)–(4,0) y (2,0)–(6,0): las cuatro son 0; (2,0) ∈ el primero → se solapan en [2, 4]
```

**Cuánto.** `O(1)`: cuatro orientaciones y, como mucho, cuatro comprobaciones de pertenencia.

**La plantilla**, con `Pt`, `cross`, `dot` y `orient` de [`18/01`](01-vectores-y-orientacion.md):

```cpp
#include <algorithm>
#include <utility>

// ¿p está en el segmento ab (extremos incluidos)?
bool onSegment(Pt a, Pt b, Pt p) {
    return orient(a, b, p) == 0
        && std::min(a.x, b.x) <= p.x && p.x <= std::max(a.x, b.x)
        && std::min(a.y, b.y) <= p.y && p.y <= std::max(a.y, b.y);
}

// ¿Los segmentos ab y cd tienen algún punto en común?
bool segmentsIntersect(Pt a, Pt b, Pt c, Pt d) {
    int o1 = orient(a, b, c), o2 = orient(a, b, d);
    int o3 = orient(c, d, a), o4 = orient(c, d, b);
    if (o1 * o2 < 0 && o3 * o4 < 0) return true;              // caso general
    return onSegment(a, b, c) || onSegment(a, b, d)           // colineales y extremos
        || onSegment(c, d, a) || onSegment(c, d, b);
}

// Punto de corte de las rectas ab y cd (no paralelas), en double.
std::pair<double, double> lineIntersection(Pt a, Pt b, Pt c, Pt d) {
    double t = (double) cross(c - a, d - c) / (double) cross(b - a, d - c);
    return {a.x + t * (b.x - a.x), a.y + t * (b.y - a.y)};
}
```

```java
static boolean onSegment(Pt a, Pt b, Pt p) {
    return orient(a, b, p) == 0
        && Math.min(a.x(), b.x()) <= p.x() && p.x() <= Math.max(a.x(), b.x())
        && Math.min(a.y(), b.y()) <= p.y() && p.y() <= Math.max(a.y(), b.y());
}

static boolean segmentsIntersect(Pt a, Pt b, Pt c, Pt d) {
    int o1 = orient(a, b, c), o2 = orient(a, b, d);
    int o3 = orient(c, d, a), o4 = orient(c, d, b);
    if (o1 * o2 < 0 && o3 * o4 < 0) return true;
    return onSegment(a, b, c) || onSegment(a, b, d) || onSegment(c, d, a) || onSegment(c, d, b);
}

static double[] lineIntersection(Pt a, Pt b, Pt c, Pt d) {
    double t = (double) c.minus(a).cross(d.minus(c)) / b.minus(a).cross(d.minus(c));
    return new double[]{a.x() + t * (b.x() - a.x()), a.y() + t * (b.y() - a.y())};
}
```

- **Se multiplican los signos, no los productos.** `o1 * o2` con `orient` devolviendo `−1`, `0` o `1` no
  desborda; multiplicar dos productos cruz de `10¹⁸` sí.
- **El caso general va primero y con `< 0` estricto.** Con `≤ 0`, dos segmentos colineales separados pasan
  la prueba (la autopsia de abajo).
- **El punto de corte es racional**: `t` es una fracción de dos productos cruz. Si hace falta exacto, se
  guardan numerador y denominador (con 128 bits, porque el producto de `t` por una coordenada pasa de 64);
  en Python, `Fraction`.
- **`onSegment` usa la caja** de `a` y `b`; con `orient == 0` ya garantizado, basta y no multiplica.

**Cuándo sí:** cruces de calles, cables, trayectorias; detectar si un polígono es simple; como pieza del
barrido de [`18/05`](05-barrido-geometrico.md). **Cuándo no:** con muchos segmentos (`n ≥ 10⁴`) y la pregunta «¿hay algún par que se
corte?», la comparación de todos los pares es cuadrática: barrido.

> **Veredicto:** cuatro orientaciones y cuatro pertenencias, siempre las ocho. Es la función de geometría
> que más se escribe mal, y siempre por el mismo sitio: los colineales.

### Autopsia de un bug: el caso colineal

**El código que escribe todo el mundo:**

```java
// Parece correcto: «se cortan si cada uno separa (o toca) los extremos del otro».
static boolean intersectNaive(Pt a, Pt b, Pt c, Pt d) {
    return orient(a, b, c) * orient(a, b, d) <= 0 && orient(c, d, a) * orient(c, d, b) <= 0;
}
```

**Por qué parece correcto.** Acierta el corte limpio de las diagonales, el contacto en un extremo y el
solapamiento de `(0,0)–(4,0)` con `(2,0)–(6,0)`: los ejemplos típicos pasan.

**La entrada que lo rompe.** `(0,0)–(1,0)` y `(2,0)–(3,0)`: colineales y separados. Las cuatro
orientaciones son 0, `0 ≤ 0` es cierto, y dice que se cortan.

**El código correcto** es `segmentsIntersect`: con `< 0` estricto en el caso general, y la pertenencia al
tramo (`onSegment`) para todo lo que tenga una orientación nula.

**La generalización.** Cuando una prueba de signos tiene un caso «igual a 0», ese caso casi nunca se
resuelve con el mismo signo: es una situación degenerada con su propia regla. Pasa igual en punto en
polígono ([`18/03`](03-poligonos.md)) y en la envolvente convexa con puntos alineados ([`18/04`](04-envolvente-convexa.md)).

---

## 4. 🧱 Distancias

**Qué es.** La distancia de un punto a una recta, a un segmento, y entre dos segmentos.

**Por qué es correcto.** Área del paralelogramo entre la base para la recta; para el segmento, el punto más
cercano de la recta es la proyección, y si cae fuera del tramo, el más cercano del tramo es el extremo de
ese lado (la distancia crece al alejarse de la proyección). Entre dos segmentos que no se cortan, la distancia
mínima se alcanza en algún extremo: es el mínimo de las cuatro distancias punto-segmento.

**Cómo va**, con `p = (2,1)`:

```text
a la recta (0,0)–(4,3):     |(4,3) × (2,1)| / |(4,3)| = |4 − 6| / 5 = 0,4
al segmento (0,3)–(4,3):    proyección dentro del tramo → distancia a la recta = 2
de (5,5) al segmento (0,0)–(4,3):  t = ((5,5) · (4,3)) / 25 = 35/25 > 1 → |(5,5) − (4,3)| = √5
```

**Cuánto.** `O(1)`; una raíz al final.

**La plantilla:**

```cpp
#include <cmath>

// Distancia de p al segmento ab (a ≠ b).
double distPointSegment(Pt p, Pt a, Pt b) {
    Pt ab = b - a, ap = p - a;
    long long len2 = norm2(ab);
    long long proj = dot(ap, ab);                              // t = proj / len2
    if (proj <= 0) return std::sqrt((double) norm2(ap));
    if (proj >= len2) return std::sqrt((double) norm2(p - b));
    return std::fabs((double) cross(ab, ap)) / std::sqrt((double) len2);
}

double distSegments(Pt a, Pt b, Pt c, Pt d) {
    if (segmentsIntersect(a, b, c, d)) return 0;
    return std::min({distPointSegment(a, c, d), distPointSegment(b, c, d),
                     distPointSegment(c, a, b), distPointSegment(d, a, b)});
}
```

```java
static double distPointSegment(Pt p, Pt a, Pt b) {
    Pt ab = b.minus(a), ap = p.minus(a);
    long len2 = ab.norm2(), proj = ap.dot(ab);
    if (proj <= 0) return Math.sqrt(ap.norm2());
    if (proj >= len2) return Math.sqrt(p.minus(b).norm2());
    return Math.abs((double) ab.cross(ap)) / Math.sqrt(len2);
}

static double distSegments(Pt a, Pt b, Pt c, Pt d) {
    if (segmentsIntersect(a, b, c, d)) return 0;
    return Math.min(Math.min(distPointSegment(a, c, d), distPointSegment(b, c, d)),
                    Math.min(distPointSegment(c, a, b), distPointSegment(d, a, b)));
}
```

- **La proyección se decide en enteros**: comparar `proj` con `0` y con `len2` evita dividir y es exacto.
- **La raíz va al final**, una sola vez. Para **comparar** distancias punto-recta sin raíces, se comparan
  `cross² / len2` como fracciones: `cross₁² · len2₂` frente a `cross₂² · len2₁`, que necesita 128 bits con
  coordenadas de `10⁹`.
- **`(double)` antes de dividir**: en Java y C++, `cross / len2` entre enteros trunca.

**Cuándo sí:** el punto más cercano de una ruta, colisiones (¿pasa a menos de `r`?), la distancia entre dos
polígonos (mínimo sobre pares de lados). **Cuándo no:** para la distancia mínima entre muchos puntos, el
barrido de `18/05`; para «¿está dentro?», punto en polígono (`18/03`).

> **Veredicto:** la distancia a un segmento es una proyección con dos topes. Decide el tope en enteros y
> haz la raíz una sola vez, al final.

---

## 5. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| ¿Se cortan dos segmentos? | `O(1)` | Exacto en enteros; los colineales necesitan su caso |
| Punto de corte de dos rectas | `O(1)` | Racional: `double` o fracción con 128 bits |
| Distancia punto-recta | `O(1)` | Una raíz; comparar sin raíz cuesta 128 bits |
| Distancia punto-segmento | `O(1)` | El tope se decide en enteros |
| ¿Algún par de `n` segmentos se corta? | `O(n²)` directo; `O(n log n)` con barrido | El barrido está en `18/05` |

---

## 6. 🧭 Cómo se elige

```text
¿Se tocan o se cortan dos segmentos? → segmentsIntersect (sí/no, en enteros)
¿Dónde? → lineIntersection (racional): double o fracción
¿A qué distancia de una recta o un segmento? → proyección con topes; raíz al final
¿Muchos segmentos? → n ≤ 3 000: todos los pares · si no: barrido (18/05)
```

> **Regla de entrevista:** al escribir la intersección, nombra los tres casos en voz alta —«se cruzan, se
> tocan en un extremo, son colineales»— y escribe el tercero aunque no te lo pidan.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Se cruzan las rutas, cables, paredes?» | Cuatro orientaciones + colineales | Exacto en enteros |
| «¿El recorrido se corta a sí mismo?» | Intersección entre tramos no consecutivos | Los consecutivos comparten esquina |
| «Distancia mínima de un punto a una ruta» | Punto-segmento por cada tramo | Proyección con topes |
| «Punto de corte con dos decimales» | `lineIntersection` en `double` | El punto es racional |
| «Distancia entre dos polígonos» | Mínimo de punto-segmento entre lados | Se alcanza en un extremo |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si los productos cruz cambian de signo, se cortan» | Sin el caso colineal aparte, `(0,0)–(1,0)` y `(2,0)–(3,0)` «se cortan» |
| «La distancia a un segmento es la distancia a su recta» | Solo si la proyección cae dentro; si no, es la distancia al extremo más cercano |
| «El punto de corte de dos segmentos enteros es entero» | Es racional: `(2, 1,5)` en el ejemplo |
| «Dos segmentos paralelos no se cortan» | Si son colineales, pueden solaparse |
| «`p` está en el segmento si `orient(a, b, p) = 0`» | Eso dice que está en la recta; falta que caiga entre los extremos |
| «Pendiente e intercepto representan cualquier recta» | Las verticales no tienen pendiente: dos puntos, o `ax + by = c` |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §33.1: la intersección de segmentos con orientaciones y el caso colineal. *Lectura troncal.*
- **Libro** — O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), cap. 1 (las primitivas de
  intersección) y cap. 7 (el punto de corte), con código. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Check if two segments intersect*](https://cp-algorithms.com/geometry/check-segments-intersection.html).
- **Referencia** — cp-algorithms, [*Intersection Point of Lines*](https://cp-algorithms.com/geometry/lines-intersection.html).
- **Referencia** — cp-algorithms, [*Intersection of Segments*](https://cp-algorithms.com/geometry/segments-intersection.html):
  el segmento común de dos colineales.

---

## 🧠 Preguntas

1. ¿Cómo decides si un punto está sobre un segmento? 🟢
2. ¿Qué cuatro orientaciones se calculan para saber si dos segmentos se cortan? 🟢
3. ¿Cómo se calcula la distancia de un punto a una recta? 🟢
4. ¿Qué diferencia hay entre la distancia de un punto a una recta y a un segmento? 🟡
5. ¿Qué casos aparecen cuando alguna de las cuatro orientaciones vale 0? 🟡
6. ¿Por qué el punto de corte de dos segmentos con extremos enteros no es, en general, entero? 🟡
7. ¿Por qué se multiplican los signos de las orientaciones y no los productos cruz? 🟡
8. ¿Qué cambia entre C++, Java y Python para representar el punto de corte exacto? 🟠
9. ¿Cómo calculas la distancia entre dos segmentos, y por qué basta mirar los extremos? 🟠
10. ¿Cómo comparas dos distancias punto-recta sin raíces ni `double`? 🟠
11. Demuestra que si `c` y `d` quedan a lados estrictamente distintos de la recta `ab`, y `a` y `b` a lados
    estrictamente distintos de la recta `cd`, los segmentos se cortan en un punto interior de los dos. 🔴
12. Da el par de segmentos más simple en el que «se cortan si `o₁·o₂ ≤ 0` y `o₃·o₄ ≤ 0`» da un falso
    positivo, y el más simple en el que la versión con `< 0` estricto y sin más casos da un falso negativo. 🔴

---

## 🧩 Problemas propios

### La casa más cerca del camino

**Nivel:** 🟡 · **Formato:** programa completo.

Un camino es una línea quebrada de `n` esquinas. Para cada casa, imprime la distancia más corta de la casa
al camino, con 6 decimales.

- **Entrada.** Una línea con `n`. Después, `n` líneas con las esquinas. Una línea con `q`. Después, `q` líneas
  con las casas. Dos esquinas consecutivas nunca coinciden.
- **Salida.** `q` líneas. Se aceptan errores de hasta `10⁻⁶`.
- **Restricciones.** `2 ≤ n ≤ 1 000`; `1 ≤ q ≤ 1 000`; coordenadas enteras con `|·| ≤ 10⁶`.

```text
Entrada         Salida
3               1.000000
0 0             2.236068
4 0             2.000000
4 3             0.000000
4
2 1
5 5
6 1
4 0

Entrada         Salida
2               1000000.000000
-1000000 0
1000000 0
1
0 -1000000
```

**Pista 1:** el camino está hecho de tramos rectos. ¿Qué punto de un tramo está más cerca de la casa si la
casa «se proyecta» fuera del tramo?

### El trazo que se cruza

**Nivel:** 🟠 · **Formato:** programa completo.

Un trazo pasa por `n` puntos en orden. Imprime `YES` si se toca o se corta a sí mismo y `NO` si no. Dos tramos
consecutivos pueden compartir su esquina común, pero nada más; dos tramos no consecutivos no pueden
compartir ningún punto.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`. Dos puntos consecutivos nunca
  coinciden.
- **Salida.** `YES` o `NO`.
- **Restricciones.** `2 ≤ n ≤ 2 000`; `|x|, |y| ≤ 10⁹`.

```text
Entrada         Salida
5               NO
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
4               YES
0 0
4 3
4 0
0 3

Entrada         Salida
3               YES
0 0
4 0
2 0
```

**Pista 1:** con `2 000` puntos hay unos dos millones de pares de tramos: ¿te alcanza con mirarlos todos, y
qué tiene de especial un par de tramos consecutivos?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de enviar una intersección, pruébala con los tres casos de §3 y con dos segmentos
> colineales separados. Si una IA te ayuda, que sea a generar casos degenerados, no la función
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). SPOJ no se enlaza (`403`).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Goat Rope](https://open.kattis.com/problems/goatrope) | Kattis | 🟢 | Distancia punto-rectángulo | Según dónde quede el poste respecto al rectángulo, ¿a qué parte del rectángulo está más cerca: un lado o una esquina? |
| [ ] | [Circle and Rectangle Overlapping](https://leetcode.com/problems/circle-and-rectangle-overlapping/) | LeetCode | 🟡 | Punto más cercano | ¿Qué punto del rectángulo está más cerca del centro, si recortas cada coordenada al rango del rectángulo? |
| [ ] | [Line Segment Intersection](https://cses.fi/problemset/task/2190) | CSES | 🟡 | Intersección con colineales | ¿Qué responde tu función con dos segmentos sobre la misma recta que no se tocan? |
| [ ] | [Imperfect GPS](https://open.kattis.com/problems/imperfectgps) | Kattis | 🟡 | Interpolación en segmentos | Si sabes en qué tramo estás en el instante `t`, ¿qué fracción del tramo has recorrido? |
| [ ] | [White Water Rafting](https://open.kattis.com/problems/rafting) | Kattis | 🟠 | Distancia entre polígonos | ¿Entre qué pares de elementos de los dos polígonos se alcanza la distancia mínima? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Counting Triangles](https://open.kattis.com/problems/countingtriangles) | Kattis | 🟠 | Intersección de pares | Con 50 segmentos, ¿qué tienen que cumplir tres de ellos para formar un triángulo? |
| [ ] | [Line Segment Intersection](https://open.kattis.com/problems/segmentintersection) | Kattis | 🔴 | Punto o tramo de corte | Si son colineales y se solapan, ¿qué dos puntos delimitan el tramo común? |
| [ ] | [Self Crossing](https://leetcode.com/problems/self-crossing/) | LeetCode | 🔴 | Casos de cruce | Con giros siempre a la izquierda, ¿con qué tramos anteriores puede chocar el tramo `i`? |

---

## ✅ Criterio de dominio

- Escribir `onSegment` y `segmentsIntersect` en C++ o Java sin mirar, con el caso colineal.
- Explicar la autopsia del `≤ 0` y dar la entrada que lo rompe.
- Calcular a mano la distancia de un punto a un segmento con los dos topes.
- Resolver Line Segment Intersection (CSES) y Goat Rope sin pista 2.

---

**Anterior:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md) · **Siguiente:** [`18/03` — Polígonos](03-poligonos.md) ·
**Relacionado:** [`18/05` — Barrido geométrico](05-barrido-geometrico.md).
