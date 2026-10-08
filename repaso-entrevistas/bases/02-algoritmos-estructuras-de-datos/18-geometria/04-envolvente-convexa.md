# 04 — Envolvente convexa

> El menor polígono convexo que contiene un conjunto de puntos, construido en `Θ(n log n)` con la cadena
> monótona de Andrew: ordenar por coordenadas y una pila que descarta los giros a la derecha. Con la cota
> inferior que dice que no se puede hacer mejor, el tratamiento de los puntos alineados, y los *rotating
> calipers*, que sobre la envolvente dan el diámetro y el ancho en tiempo lineal.
>
> **Niveles:** cadena monótona de Andrew [B] · *rotating calipers* [C].
>
> **📚 Lectura troncal:** de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed.
> (Springer, 2008), cap. 1; Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §33.3.
>
> **Asume leído:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--cadena-monótona-de-andrew) · [4](#4--rotating-calipers) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Hay que cercar un rebaño con la valla más corta posible. La valla óptima es la **envolvente convexa** de los
animales: el polígono convexo más pequeño que los contiene a todos, el que formaría una goma elástica
soltada alrededor de clavos.

La idea ingenua prueba, para cada par de puntos, si todos los demás quedan del mismo lado de la recta que
los une: si es así, el par es un lado de la envolvente. Son `n²` pares por `n` comprobaciones: `Θ(n³)`. Con
`10⁵` puntos, `10¹⁵`. La envolvente se construye en `Θ(n log n)`, y no se puede hacer mejor.

> 🧠 **Modelo mental.** Recorriendo la envolvente en sentido antihorario, en cada vértice se gira a la
> izquierda. Andrew recorre los puntos ordenados y, cada vez que el último giro sale a la derecha, deshace el
> último punto: lo que queda en la pila nunca gira a la derecha.

Los ejemplos usan los puntos de juguete:

```text
(0,0) · (4,0) · (4,3) · (0,3) · (2,1)
envolvente: (0,0) (4,0) (4,3) (0,3), antihoraria · (2,1) es interior · diámetro 5 · ancho 3
```

---

## 2. 📐 La teoría

**Envolvente convexa.** La intersección de todos los convexos que contienen los puntos; para un conjunto
finito, un polígono convexo cuyos vértices son algunos de los puntos.

**Cadena monótona de Andrew.** Se ordenan los puntos por `(x, y)`. El primero y el último están en la
envolvente (son los extremos en `x`). La envolvente se parte en la **cadena inferior** (de izquierda a
derecha por abajo) y la **superior** (de derecha a izquierda por arriba). Cada una se construye con una pila:
al llegar un punto, mientras los dos últimos de la pila y el nuevo **no** giren a la izquierda, se desapila
el último.

*Por qué es correcto.* Un punto desapilado `q`, entre `p` (antes) y `r` (el nuevo), queda dentro del triángulo
que forman `p`, `r` y algún punto de la otra cadena, o sobre el lado `pr`: no puede ser vértice. Y lo que queda
en la pila gira siempre a la izquierda y contiene todos los puntos procesados por encima (o por debajo): es la
cadena buscada.

**Coste.** Ordenar, `Θ(n log n)`. Cada punto se apila una vez y se desapila como mucho una vez en cada
cadena: el recorrido es `Θ(n)` amortizado.

**Cota inferior `Ω(n log n)`.** Ordenar `n` números `x₁, …, xₙ` se reduce a la envolvente de los puntos
`(xᵢ, xᵢ²)`: están todos sobre una parábola, todos son vértices, y la envolvente los devuelve en orden de
`x`. Si la envolvente se pudiera calcular en `o(n log n)` en el modelo de comparaciones, también ordenar.

**Puntos alineados.** Con la condición «desapilar si el giro es `≤ 0`», los puntos alineados sobre un lado
se descartan; con «`< 0`», se quedan. Los dos son correctos: depende de qué pida el enunciado.

---

## 3. 🧱 Cadena monótona de Andrew

**Qué es.** La envolvente convexa en `Θ(n log n)`, con los vértices en sentido antihorario.

**Por qué es correcto.** El argumento de §2: la pila de cada cadena solo gira a la izquierda y nunca pierde un
vértice de la envolvente.

**Cómo va**, la cadena inferior con los puntos ordenados `(0,0) (0,3) (2,1) (4,0) (4,3)`:

```text
(0,0)  pila: (0,0)
(0,3)  pila: (0,0) (0,3)
(2,1)  orient((0,0), (0,3), (2,1)) = −6 → desapila (0,3)       pila: (0,0) (2,1)
(4,0)  orient((0,0), (2,1), (4,0)) = −4 → desapila (2,1)       pila: (0,0) (4,0)
(4,3)  orient((0,0), (4,0), (4,3)) = 12 → se queda             pila: (0,0) (4,0) (4,3)
```

La superior, con el orden inverso, deja `(4,3) (0,3) (0,0)`. Uniendo las dos sin repetir los extremos:
`(0,0) (4,0) (4,3) (0,3)`.

**Cuánto.** `Θ(n log n)` por la ordenación; `Θ(n)` el resto.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Envolvente convexa en sentido antihorario, sin repetir el primer vértice.
// keepCollinear: conserva los puntos alineados sobre los lados (exige que no estén todos alineados).
std::vector<Pt> convexHull(std::vector<Pt> pts, bool keepCollinear = false) {
    std::sort(pts.begin(), pts.end(), [](Pt a, Pt b) { return a.x != b.x ? a.x < b.x : a.y < b.y; });
    pts.erase(std::unique(pts.begin(), pts.end(),
                          [](Pt a, Pt b) { return a.x == b.x && a.y == b.y; }), pts.end());
    int n = pts.size();
    if (n <= 2) return pts;
    std::vector<Pt> h(2 * n);
    int k = 0;
    auto bad = [&](Pt a, Pt b, Pt c) {                   // ¿hay que desapilar b?
        int o = orient(a, b, c);
        return keepCollinear ? o < 0 : o <= 0;
    };
    for (int i = 0; i < n; i++) {                        // cadena inferior
        while (k >= 2 && bad(h[k - 2], h[k - 1], pts[i])) k--;
        h[k++] = pts[i];
    }
    for (int i = n - 2, low = k + 1; i >= 0; i--) {      // cadena superior
        while (k >= low && bad(h[k - 2], h[k - 1], pts[i])) k--;
        h[k++] = pts[i];
    }
    h.resize(k - 1);                                     // el último repite el primero
    return h;
}
```

```java
static Pt[] convexHull(Pt[] input, boolean keepCollinear) {
    Pt[] pts = java.util.Arrays.stream(input).distinct()
        .sorted(java.util.Comparator.comparingLong(Pt::x).thenComparingLong(Pt::y))
        .toArray(Pt[]::new);
    int n = pts.length;
    if (n <= 2) return pts;
    Pt[] h = new Pt[2 * n];
    int k = 0;
    for (int i = 0; i < n; i++) {
        while (k >= 2 && bad(h[k - 2], h[k - 1], pts[i], keepCollinear)) k--;
        h[k++] = pts[i];
    }
    for (int i = n - 2, low = k + 1; i >= 0; i--) {
        while (k >= low && bad(h[k - 2], h[k - 1], pts[i], keepCollinear)) k--;
        h[k++] = pts[i];
    }
    return java.util.Arrays.copyOf(h, k - 1);
}

static boolean bad(Pt a, Pt b, Pt c, boolean keepCollinear) {
    int o = orient(a, b, c);
    return keepCollinear ? o < 0 : o <= 0;
}
```

```python
def convex_hull(pts, keep_collinear=False):
    pts = sorted(set(pts))
    if len(pts) <= 2:
        return pts

    def chain(seq):
        h = []
        for p in seq:
            while len(h) >= 2 and (orient(h[-2], h[-1], p) < 0 if keep_collinear
                                   else orient(h[-2], h[-1], p) <= 0):
                h.pop()
            h.append(p)
        return h

    lower, upper = chain(pts), chain(reversed(pts))
    return lower[:-1] + upper[:-1]
```

- **Los duplicados se quitan antes**: con dos puntos iguales, `orient` da 0 y, con `keepCollinear`, se
  quedarían los dos.
- **`low = k + 1`** impide que la cadena superior desapile la inferior: el último punto de la inferior es el
  primero de la superior.
- **Todos alineados.** Con `≤ 0`, la envolvente son los dos extremos. Con `keepCollinear`, cada punto
  aparece en las dos cadenas y la salida los repite: ese caso se trata aparte.
- **El comparador**: en Java, `record` con `distinct()` usa su `equals`; en Python, las tuplas se ordenan por
  `(x, y)` y `set` quita duplicados. En C++, `unique` necesita el vector ordenado.

**Cuándo sí:** la valla más corta, el área o el perímetro mínimo que encierra los puntos, el diámetro y el
ancho (con calipers), y como paso previo de cualquier pregunta sobre «los puntos extremos». **Cuándo no:** si
los puntos llegan uno a uno y hay consultas entre medias (envolvente dinámica, fuera del alcance); para el
truco de la envolvente en DP, que es otra cosa ([`13/05`](../13-dp-avanzada/05-optimizaciones.md)).

> **Veredicto:** ordenar y una pila que solo admite giros a la izquierda. Es `Θ(n log n)`, que es óptimo, y la
> única decisión es `< 0` o `≤ 0`: qué pasa con los alineados.

---

## 4. 🧱 *Rotating calipers*

**Qué resuelve.** Preguntas sobre «pares opuestos» de un polígono convexo: el **diámetro** (los dos puntos
más lejanos), el **ancho** (la franja más estrecha que lo contiene), el rectángulo de área o perímetro mínimo
que lo encierra, la distancia entre dos polígonos convexos.

**Qué garantiza.** Los dos puntos más lejanos de un conjunto son vértices de la envolvente y forman un **par
antipodal**: admiten dos rectas paralelas de apoyo, una por cada uno. Un polígono convexo de `h` vértices
tiene `O(h)` pares antipodales, y se recorren todos girando dos «calibres» paralelos con dos punteros que solo
avanzan. Con los puntos de juguete: diámetro `5` (entre `(0,0)` y `(4,3)`), ancho `3`.

**Cuánto.** `Θ(h)` tras la envolvente; `Θ(n log n)` en total.

**Cómo reconocerlo.** «Los dos puntos más alejados» con `n = 10⁵`; «la caja más pequeña que contiene los
puntos, girada como sea»; «el pasillo más estrecho por el que pasa el conjunto».

**Si no te la sabes.** La envolvente suele tener muchos menos vértices que puntos (con puntos al azar en un
cuadrado, `O(log n)`): comparar todos los pares de **vértices de la envolvente** en `O(h²)` entra a menudo,
aunque no en el peor caso (puntos sobre un círculo).

**Dónde está entera.** de Berg y otros, cap. 1 (notas); Toussaint, «Solving geometric problems with the
rotating calipers», *Proceedings of IEEE MELECON* (1983).

---

## 5. ⏱️ La tabla de costes

| Algoritmo | Tiempo | Lo que la tabla no dice |
|---|---|---|
| Todos los pares como lado candidato | `Θ(n³)` | Correcto y corto, para `n ≤ 200` |
| Andrew | `Θ(n log n)` | La ordenación domina; el recorrido es lineal amortizado |
| Graham (por ángulo) | `Θ(n log n)` | Ordena por ángulo: comparador con productos cruz, más delicado |
| *Gift wrapping* (Jarvis) | `Θ(n h)` | Mejor si la envolvente tiene pocos vértices |
| Diámetro con calipers | `Θ(h)` tras la envolvente | `O(h²)` sobre los vértices suele bastar |

---

## 6. 🧭 Cómo se elige

```text
¿Envolvente? → Andrew (n ≤ 200 y prisa: todos los pares)
¿Se cuentan los puntos alineados del borde? → < 0; si no, ≤ 0
¿Diámetro, ancho, caja mínima? → envolvente + calipers; o pares de vértices si h es pequeño
¿Mínimos de rectas en una DP? → no es esto: el truco de la envolvente (13/05)
```

> **Regla de entrevista:** si aparece la envolvente, di «Andrew: ordenar y una pila; `n log n`, que es
> óptimo porque ordenar se reduce a ella», y pregunta qué hacer con los puntos alineados antes de escribir.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «La valla más corta», «el área mínima que encierra» | Envolvente | Es su definición |
| «Los dos puntos más lejanos», `n = 10⁵` | Envolvente + calipers | El par está en la envolvente |
| «Incluye los puntos sobre la valla» | Andrew con `< 0` | Conserva los alineados |
| «La caja más pequeña, con cualquier giro» | Calipers | Un lado de la caja va sobre un lado de la envolvente |
| Puntos que llegan ordenados por `x` | Andrew sin ordenar | `Θ(n)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La envolvente se hace probando todos los triángulos» | Andrew: ordenar y una pila, `Θ(n log n)` |
| «Da igual desapilar con `< 0` o con `≤ 0`» | Uno conserva los puntos alineados del borde y el otro no; con duplicados sin quitar, `< 0` los repite |
| «La envolvente se puede construir en `O(n)`» | Solo si los puntos ya vienen ordenados; en general, `Ω(n log n)` |
| «El diámetro necesita comparar todos los pares de puntos» | Está entre vértices de la envolvente; con calipers, lineal sobre ella |
| «La envolvente de puntos alineados es un polígono» | Es un segmento: sus dos extremos |
| «Para ordenar por ángulo, `atan2`» | Andrew ordena por `(x, y)` y no necesita ángulos |

---

## 📚 Para profundizar

- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), cap. 1: la envolvente como ejemplo inaugural, con la discusión de degeneraciones. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §33.3: Graham y Jarvis, y la cota inferior. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Convex hull construction*](https://cp-algorithms.com/geometry/convex-hull.html).
- **Artículo** — Andrew, «Another efficient algorithm for convex hulls in two dimensions», *Information
  Processing Letters* 9(5), 1979.

---

## 🧠 Preguntas

1. ¿Qué es la envolvente convexa de un conjunto de puntos? 🟢
2. ¿Cuánto cuesta la cadena monótona de Andrew y qué paso domina? 🟢
3. ¿Qué es el diámetro de un conjunto de puntos y entre qué puntos se alcanza? 🟢
4. ¿Qué cambia en el algoritmo si los puntos alineados del borde deben quedarse? 🟡
5. ¿Por qué Andrew construye la envolvente en dos cadenas? 🟡
6. ¿Qué diferencia hay entre Andrew y Graham? 🟡
7. ¿Qué es un par antipodal? 🟡
8. ¿Por qué la envolvente convexa no se puede calcular en `o(n log n)` con comparaciones? 🟠
9. ¿Qué cambia entre C++, Java y Python al quitar duplicados y ordenar los puntos para la envolvente? 🟠
10. ¿Qué devuelve la plantilla si todos los puntos están alineados, con y sin `keepCollinear`? 🟠
11. Demuestra que el recorrido de la pila de Andrew es `Θ(n)` aunque haya un bucle dentro de otro. 🔴
12. Traza la cadena superior de Andrew sobre los puntos de juguete y di qué puntos se desapilan y con qué
    orientación. 🔴

---

## 🧩 Problemas propios

### Postes en la valla

**Nivel:** 🟡 · **Formato:** programa completo.

Se rodean `n` postes con la valla más corta posible. ¿Cuántos postes quedan tocando la valla, contando los que
están en un tramo recto entre dos esquinas?

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`, todos distintos. No están todos
  alineados.
- **Salida.** Un entero.
- **Restricciones.** `3 ≤ n ≤ 2·10⁵`; `|x|, |y| ≤ 10⁹`.

```text
Entrada         Salida
5               4
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
8               7
0 0
4 0
4 3
0 3
2 1
2 0
4 1
4 2
```

**Pista 1:** si construyes la valla quitando los giros que no van a la izquierda, ¿qué pasa con un poste que
está justo sobre el tramo, y cómo cambias eso?

### El pasillo más estrecho

**Nivel:** 🔴 · **Formato:** programa completo.

Un conjunto de cajas, vistas desde arriba como puntos, tiene que pasar por un pasillo recto. ¿Cuál es el
ancho mínimo del pasillo, es decir, la menor distancia entre dos rectas paralelas que dejan todos los puntos
entre ellas? Imprime el resultado con 6 decimales.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`, todos distintos. No están todos
  alineados.
- **Salida.** Un real. Se aceptan errores de hasta `10⁻⁶`.
- **Restricciones.** `3 ≤ n ≤ 2·10⁵`; `|x|, |y| ≤ 10⁶`.

```text
Entrada         Salida
5               3.000000
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
3               2.400000
0 0
4 0
0 3
```

**Pista 1:** ¿qué puntos pueden tocar las dos rectas del pasillo más estrecho, y puede alguna de ellas no ir
apoyada sobre un lado completo?

---

## 🧩 Práctica externa

> 💡 **Truco.** Prueba tu envolvente con puntos repetidos, con todos alineados y con puntos alineados sobre
> un lado: son los tres casos que más fallan. Si una IA te ayuda, que sea a generar esos casos y compararlos
> con una versión `Θ(n³)` ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). SPOJ no
> se enlaza (`403`).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Robot Protection](https://open.kattis.com/problems/robotprotection) | Kattis | 🟡 | Área de la envolvente | ¿Qué polígono encierra a todos con el área mínima? |
| [ ] | [Dart Scoring](https://open.kattis.com/problems/dartscoring) | Kattis | 🟡 | Perímetro de la envolvente | ¿Qué tienen en común la goma elástica y el perímetro que pide el enunciado? |
| [ ] | [Convex Hull](https://cses.fi/problemset/task/2195) | CSES | 🟡 | Andrew con alineados | ¿Pide el enunciado los puntos que están sobre un lado, o solo las esquinas? |
| [ ] | [Convex Hull](https://open.kattis.com/problems/convexhull) | Kattis | 🟡 | Andrew | ¿Qué pasa con los puntos repetidos y con un caso de un solo punto? |
| [ ] | [Erect the Fence](https://leetcode.com/problems/erect-the-fence/) | LeetCode | 🔴 | Envolvente con alineados | ¿Qué condición de giro deja los árboles que están justo sobre la valla? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Board Wrapping](https://open.kattis.com/problems/wrapping) | Kattis | 🟠 | Esquinas de rectángulos girados | ¿Qué cuatro puntos aporta cada tabla girada, y qué haces con todos ellos? |
| [ ] | [Robert Hood](https://open.kattis.com/problems/roberthood) | Kattis | 🟠 | Diámetro | ¿Entre qué puntos puede estar el par más lejano, y cuántos son en la práctica? |
| [ ] | [Fence Orthogonality](https://open.kattis.com/problems/fenceortho) | Kattis | 🔴 | Calipers: caja mínima | ¿Por qué uno de los lados de la caja óptima va apoyado sobre un lado de la envolvente? |

---

## ✅ Criterio de dominio

- Escribir Andrew en C++ o Java sin mirar, con la opción de los alineados.
- Explicar la reducción desde la ordenación que da la cota `Ω(n log n)`.
- Explicar qué es un par antipodal y por qué el diámetro está entre vértices de la envolvente.
- Resolver Convex Hull (CSES) y Erect the Fence sin pista 2.

---

**Anterior:** [`18/03` — Polígonos](03-poligonos.md) · **Siguiente:** [`18/05` — Barrido geométrico](05-barrido-geometrico.md) ·
**Relacionado:** [`13/05` — Optimizaciones de DP](../13-dp-avanzada/05-optimizaciones.md).
