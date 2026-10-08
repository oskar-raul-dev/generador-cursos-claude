# 01 — Vectores, productos y orientación

> Los dos productos de vectores del plano y lo que responde cada uno: el producto punto dice si un ángulo es
> agudo, recto u obtuso; el producto cruz, hacia qué lado gira un camino y cuánta área encierra un triángulo.
> Todo con coordenadas enteras y aritmética exacta, porque el `double` falla justo en los casos que importan.
>
> **Niveles:** vectores, punto y cruz [A] · orientación [A] · enteros frente a épsilon [A].
>
> **📚 Lectura troncal:** de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed.
> (Springer, 2008), cap. 1; Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT
> Press, 2009), §33.1.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--vectores-punto-y-cruz) · [4](#4--orientación) · [5](#5--enteros-frente-a-épsilon) · [6](#6-️-la-tabla-de-costes) · [7](#7--cómo-se-elige) · [8](#8--señales-del-enunciado) · [9](#9--dónde-aparece-de-verdad) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un repartidor recorre una lista de esquinas. En cada una gira a la izquierda, a la derecha o sigue recto.
¿Cuántas veces gira a cada lado? La primera idea es calcular ángulos con `atan2`, restarlos y mirar el signo.
Funciona con los ejemplos, pero son dos funciones trigonométricas, una normalización del ángulo a
`(−π, π]` y un `double` que, con puntos casi alineados, responde lo que le toca: con `a = (0, 0)`,
`b = (117 721 111, 259 577 155)` y `c = (232 542 314, 512 759 961)`, la diferencia de ángulos sale `0,0`
(«recto»), y el giro es a la izquierda.

La respuesta exacta es una multiplicación y una resta en enteros: el **producto cruz** de los vectores
`b − a` y `c − a`, que vale `1`. Casi toda la geometría de concurso descansa en dos fórmulas de una línea,
el producto punto y el producto cruz, escritas en enteros.

> 🧠 **Modelo mental.** Un punto es una posición; la resta de dos puntos es un vector, una flecha. El
> producto punto mide cuánto apuntan dos flechas en la misma dirección; el producto cruz, cuánto se separan
> hacia un lado, con signo.

Los ejemplos usan los puntos de juguete de la guía:

```text
(0,0) · (4,0) · (4,3) · (0,3) · (2,1)
envolvente convexa: los cuatro primeros, en ese orden antihorario · área 12 · (2,1) es interior
```

---

## 2. 📐 La teoría

**Vectores.** Con `a = (x₁, y₁)` y `b = (x₂, y₂)`, el vector de `a` a `b` es `b − a = (x₂ − x₁, y₂ − y₁)`.

**Producto punto.** `a · b = x₁x₂ + y₁y₂ = |a| |b| cos θ`, con `θ` el ángulo entre ellos. Su signo dice si
el ángulo es agudo (`> 0`), recto (`= 0`) u obtuso (`< 0`). `a · a = |a|²`.

**Producto cruz** (en el plano, un escalar). `a × b = x₁y₂ − y₁x₂ = |a| |b| sen θ`, con `θ` medido de `a` a
`b` en sentido antihorario. Su valor absoluto es el área del paralelogramo que forman `a` y `b`; su signo,
el sentido del giro de `a` a `b`: positivo si es antihorario, negativo si es horario, cero si son
paralelos. Es antisimétrico: `b × a = −(a × b)`.

**Orientación de tres puntos.** `orient(a, b, c) = (b − a) × (c − a)`:

```text
orient(a, b, c) > 0   →  a → b → c gira a la izquierda (antihorario)
orient(a, b, c) < 0   →  gira a la derecha (horario)
orient(a, b, c) = 0   →  los tres están alineados
|orient(a, b, c)| / 2 →  área del triángulo abc
```

*Prueba del signo.* Traslada `a` al origen y gira el plano para que `b − a` quede sobre el eje `x` positivo:
ni la traslación ni el giro cambian el producto cruz (es un determinante, y los giros tienen determinante
1). Entonces `b − a = (d, 0)` con `d > 0` y `orient = d · y_c`: es positivo si y solo si `c` queda por
encima del eje, es decir, a la izquierda de la dirección `a → b`.

**Por qué en enteros.** Con coordenadas enteras, sumas, restas y productos son exactos. Con coordenadas de
hasta `10⁹` en valor absoluto, las diferencias llegan a `2·10⁹` y el producto cruz a `8·10¹⁸`, por debajo de
`2⁶³ ≈ 9,2·10¹⁸`: cabe en 64 bits. Un `double` solo tiene 53 bits de mantisa (`≈ 9·10¹⁵`): el mismo cálculo
redondea.

---

## 3. 🧱 Vectores, punto y cruz

**Qué es.** Dos funciones de una línea sobre pares de enteros.

**Por qué es correcto.** Las identidades `a · b = |a| |b| cos θ` y `a × b = |a| |b| sen θ` de §2.

**Cómo va**, con `u = (4,0) − (0,0) = (4, 0)` y `v = (4,3) − (0,0) = (4, 3)`:

```text
u · v = 4·4 + 0·3 = 16     > 0: el ángulo entre u y v es agudo
u × v = 4·3 − 0·4 = 12     > 0: de u a v se gira en sentido antihorario
área del triángulo (0,0) (4,0) (4,3) = |12| / 2 = 6
```

**Cuánto.** `O(1)`: dos multiplicaciones y una suma o resta.

**La plantilla:**

```cpp
struct Pt { long long x, y; };

Pt operator-(Pt a, Pt b) { return {a.x - b.x, a.y - b.y}; }
long long dot(Pt a, Pt b) { return a.x * b.x + a.y * b.y; }
long long cross(Pt a, Pt b) { return a.x * b.y - a.y * b.x; }
long long norm2(Pt a) { return dot(a, a); }               // |a|², sin raíz
```

```java
record Pt(long x, long y) {
    Pt minus(Pt o) { return new Pt(x - o.x, y - o.y); }
    long dot(Pt o) { return x * o.x + y * o.y; }
    long cross(Pt o) { return x * o.y - y * o.x; }
    long norm2() { return x * x + y * y; }                 // |a|², sin raíz
}
```

```python
def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])

def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]

def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]
```

- **`long long` / `long` en las coordenadas**, no solo en el resultado: si `x` es `int`, `a.x * b.y` se
  calcula en 32 bits y desborda antes de guardarse.
- **`record` de Java** (Java 16+) da constructor, `equals` y `hashCode`; sirve como clave de un `HashSet`.
  Con millones de puntos, dos arreglos `long[] xs, ys` evitan crear objetos.
- **En Python**, tuplas y enteros sin límite: no hay desbordamiento, pero cada punto es un objeto y la
  constante es 30–50 veces la de C++.
- **`norm2` sin raíz**: comparar distancias por su cuadrado es exacto; la raíz solo al imprimir.

### De la versión ingenua a la buena

**El problema.** El área del triángulo `(0,0) (4,0) (4,3)`, y en general de tres puntos con coordenadas de
hasta `2·10⁹`.

**La versión ingenua**, con la fórmula de Herón:

```java
// Correcta en aritmética exacta: Herón con los tres lados.
static double heron(long[] a, long[] b, long[] c) {
    double x = Math.hypot(a[0] - b[0], a[1] - b[1]);
    double y = Math.hypot(b[0] - c[0], b[1] - c[1]);
    double z = Math.hypot(c[0] - a[0], c[1] - a[1]);
    double s = (x + y + z) / 2;
    return Math.sqrt(Math.max(0, s * (s - x) * (s - y) * (s - z)));
}
```

> «Herón da 6 con el ejemplo, pero hace tres raíces y una resta de números casi iguales: con un triángulo
> muy plano, `(0,0) (10⁹,1) (2·10⁹,3)`, devuelve 0 y el área es `5·10⁸`. El producto cruz da el doble del
> área en enteros, sin raíces.»

**El camino a la buena.** `|cross(b − a, c − a)| / 2`; si hace falta el área exacta, se guarda el doble
(un entero) y se divide al imprimir.

**Cuándo sí:** ángulos (punto), giros y áreas (cruz), distancias al cuadrado, proyecciones. **Cuándo no:**
cuando el resultado no es polinómico en las coordenadas (una distancia, un ángulo en grados, un punto de
intersección): ahí hace falta `double` o fracciones (§5).

> **Veredicto:** el producto cruz es la primitiva de la geometría plana. En enteros de 64 bits, con
> coordenadas de hasta `10⁹`, es exacto; casi todo lo demás del bloque se construye con él.

---

## 4. 🧱 Orientación

**Qué es.** El signo de `orient(a, b, c) = (b − a) × (c − a)`: izquierda, derecha o alineados.

**Por qué es correcto.** La prueba del signo de §2.

**Cómo va**, con los puntos de juguete. ¿Está `(2,1)` dentro del triángulo `(0,0) (4,0) (4,3)`?

```text
orient((0,0), (4,0), (4,3)) = 12   el triángulo está en sentido antihorario
orient((0,0), (4,0), (2,1)) =  4   (2,1) a la izquierda de la arista 1
orient((4,0), (4,3), (2,1)) =  6   a la izquierda de la arista 2
orient((4,3), (0,0), (2,1)) =  2   a la izquierda de la arista 3
→ los tres del mismo signo que el triángulo: (2,1) es interior
```

**Cuánto.** `O(1)` por consulta.

**La plantilla:**

```cpp
// +1 si a→b→c gira a la izquierda, −1 a la derecha, 0 si están alineados.
int orient(Pt a, Pt b, Pt c) {
    long long v = cross(b - a, c - a);
    return (v > 0) - (v < 0);
}

// ¿p está dentro del triángulo abc, o en su borde? Vale con abc en cualquier sentido.
bool inTriangle(Pt a, Pt b, Pt c, Pt p) {
    int s1 = orient(a, b, p), s2 = orient(b, c, p), s3 = orient(c, a, p);
    bool neg = s1 < 0 || s2 < 0 || s3 < 0, pos = s1 > 0 || s2 > 0 || s3 > 0;
    return !(neg && pos);
}
```

```java
static int orient(Pt a, Pt b, Pt c) {
    return Long.signum(b.minus(a).cross(c.minus(a)));
}

static boolean inTriangle(Pt a, Pt b, Pt c, Pt p) {
    int s1 = orient(a, b, p), s2 = orient(b, c, p), s3 = orient(c, a, p);
    boolean neg = s1 < 0 || s2 < 0 || s3 < 0, pos = s1 > 0 || s2 > 0 || s3 > 0;
    return !(neg && pos);
}
```

```python
def orient(a, b, c):
    v = cross(sub(b, a), sub(c, a))
    return (v > 0) - (v < 0)

def in_triangle(a, b, c, p):
    s = (orient(a, b, p), orient(b, c, p), orient(c, a, p))
    return not (min(s) < 0 < max(s))
```

- **Devolver el signo**, no el valor: así nadie compara el valor con un umbral, y el resultado cabe en un
  `int`.
- **`inTriangle` incluye el borde**: un `0` no cuenta como signo contrario. Para «estrictamente dentro»,
  se exige que los tres sean del mismo signo y no nulos.
- **`Long.signum`** en Java y `(v > 0) - (v < 0)` en C++ y Python son el mismo truco.

### De la versión ingenua a la buena

**El problema.** Contar giros a la izquierda, a la derecha y rectos de un recorrido de `n` esquinas.

**La versión ingenua**, con ángulos:

```java
// Correcta en aritmética exacta: la diferencia de direcciones normalizada a (−π, π].
static int turnNaive(long[] a, long[] b, long[] c) {
    double t1 = Math.atan2(b[1] - a[1], b[0] - a[0]);
    double t2 = Math.atan2(c[1] - b[1], c[0] - b[0]);
    double d = t2 - t1;
    while (d <= -Math.PI) d += 2 * Math.PI;
    while (d > Math.PI) d -= 2 * Math.PI;
    return d > 0 ? 1 : (d < 0 ? -1 : 0);
}
```

> «Esto funciona con puntos pequeños, pero con `(0,0)`, `(117 721 111, 259 577 155)` y
> `(232 542 314, 512 759 961)` las dos direcciones salen iguales en `double` y dice "recto": el giro es a la
> izquierda. El producto cruz da `1` exacto en enteros, sin trigonometría ni normalización.»

**El camino a la buena.** `orient(a, b, c)` en cada esquina: `O(n)` multiplicaciones exactas.

**Cuándo sí:** giros, lado de una recta, punto en triángulo, alineación, y como pieza de la intersección
de segmentos ([`18/02`](02-rectas-y-segmentos.md)) y de la envolvente convexa ([`18/04`](04-envolvente-convexa.md)). **Cuándo no:** para
el ángulo en sí (cuántos grados), que no es polinómico: `atan2`, aceptando el error.

> **Veredicto:** «¿a qué lado?» se responde con el signo de un producto cruz, nunca con ángulos. Es exacto,
> cuesta dos multiplicaciones y no tiene casos especiales de pendiente vertical.

---

## 5. 🧱 Enteros frente a épsilon

**Qué es.** La regla para elegir el tipo: enteros mientras el resultado sea un polinomio de las
coordenadas (punto, cruz, áreas dobles, distancias al cuadrado); `double` con un **épsilon** solo cuando no
lo es (distancias, ángulos, puntos de intersección), o fracciones exactas si hace falta exactitud.

**Por qué es correcto.** Un `double` representa exactamente los enteros hasta `2⁵³ ≈ 9·10¹⁵`. Por encima,
redondea al representable más cercano. El producto cruz de coordenadas de `10⁹` llega a `10¹⁸`: cabe en
`long long`, no en la mantisa de un `double`.

**Cómo va**, con `a = (0, 0)`, `b = (10⁹, 10⁹ − 1)` y `c = (10⁹ − 1, 10⁹ − 2)`:

```text
b.x · c.y = 10⁹ · (10⁹ − 2)       = 999 999 998 000 000 000
b.y · c.x = (10⁹ − 1)²            = 999 999 998 000 000 001
cruz exacta (long long)           = −1        → giro a la derecha
cruz en double                    =  0        → «alineados»: el segundo producto se redondea al primero
```

**Cuánto.** Lo mismo en tiempo. En memoria, un `long long` y un `double` ocupan lo mismo.

**La plantilla**, para cuando el `double` es inevitable:

```cpp
#include <cmath>

// Signo con tolerancia: el épsilon se escala con la magnitud de los datos.
int sgn(double v, double eps) { return (v > eps) - (v < -eps); }
```

```java
static int sgn(double v, double eps) { return v > eps ? 1 : (v < -eps ? -1 : 0); }
```

```python
from fractions import Fraction        # exactitud sin épsilon, a cambio de tiempo

def sgn(v, eps):
    return (v > eps) - (v < -eps)
```

- **El épsilon depende de la magnitud.** Con coordenadas de hasta `10⁴`, los productos cruz son de `10⁸` y
  un `1e-9` sirve; con coordenadas de `10⁶`, el error de redondeo de un producto de `10¹²` ya ronda
  `10⁻⁴`, y `1e-9` es demasiado estricto. Se razona en error relativo: unos `10⁻¹⁵` del valor más grande
  que interviene.
- **`Fraction` de Python** representa los puntos de intersección exactos; en C++ y Java se guardan
  numerador y denominador en enteros (cuidando que no desborden).
- **`long double`** en C++ (80 bits en x86 con GCC) da 64 bits de mantisa: ayuda, pero no es exacto, y en
  ARM o con MSVC es igual que `double`.

### De la versión ingenua a la buena

**El problema.** ¿Están alineados tres puntos con coordenadas de hasta `10⁹`?

**La versión ingenua**, con pendientes:

```java
// Correcta en aritmética exacta con tres puntos distintos; las rectas verticales se tratan aparte.
static boolean collinearNaive(long[] a, long[] b, long[] c) {
    if (a[0] == b[0] || a[0] == c[0]) return a[0] == b[0] && a[0] == c[0];
    double m1 = (double) (b[1] - a[1]) / (b[0] - a[0]);
    double m2 = (double) (c[1] - a[1]) / (c[0] - a[0]);
    return m1 == m2;
}
```

> «Necesita un caso para las verticales, y con `(0,0)`, `(10⁹, 10⁹ − 1)` y `(10⁹ − 1, 10⁹ − 2)` las dos
> pendientes se redondean al mismo `double` y dice que sí. Comparar pendientes es comparar fracciones:
> multiplicando en cruz queda el producto cruz, en enteros.»

**El camino a la buena.** `cross(b − a, c − a) == 0` en 64 bits.

**Cuándo sí:** siempre que las entradas sean enteras y el resultado se pueda escribir con sumas, restas y
productos. **Cuándo no:** con coordenadas reales en la entrada, o resultados irracionales (una distancia):
ahí `double` con épsilon, y la conciencia de que el resultado es aproximado.

> **Veredicto:** «la geometría es con `double`» es el error más caro del bloque. Enteros exactos mientras se
> pueda; `double` solo donde el resultado no es entero, con un épsilon a la escala de los datos.

---

## 6. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| Producto punto o cruz | `O(1)` | Con coordenadas de `10⁹`, el resultado llega a `8·10¹⁸`: 64 bits justos |
| Orientación de tres puntos | `O(1)` | Exacta en enteros; en `double`, puede dar 0 con giros reales |
| Área de un triángulo | `O(1)` | Se guarda el doble, entero; la mitad solo al imprimir |
| Distancia | `O(1)` | Con raíz: comparar por el cuadrado mientras se pueda |
| Ángulo con `atan2` | `O(1)`, constante alta | Aproximado; nunca para decidir un giro |

---

## 7. 🧭 Cómo se elige

```text
¿Agudo, recto u obtuso? ¿Proyección? → producto punto
¿Hacia qué lado? ¿Alineados? ¿Área? → producto cruz / orient
¿Cuál está más cerca? → distancias al cuadrado
¿El resultado no es entero (distancia, punto de corte, ángulo)? → double con épsilon, o fracciones
```

> **Regla de entrevista:** antes de escribir la primera línea de geometría, di en voz alta «coordenadas
> enteras, productos en 64 bits, nada de pendientes». Evita la mitad de los WA del bloque.

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Están alineados?», «¿forman un triángulo?» | `cross == 0` | Pendientes sin división |
| «¿A la izquierda o a la derecha de la recta?» | `orient` | Es el signo del giro |
| «Área del triángulo», «¿qué triángulo es mayor?» | `\|cross\| / 2`, o el doble | Exacto en enteros |
| «¿Ángulo recto?», «¿perpendiculares?» | `dot == 0` | Coseno nulo |
| «Ordenar por ángulo» | Comparador con `cross` por semiplanos | Sin `atan2` |
| Coordenadas de hasta `10⁹` | 64 bits en los productos | `8·10¹⁸ < 2⁶³` |

---

## 9. 🔭 Dónde aparece de verdad

**Lo que sí te pueden preguntar.** En una prueba de empresa, la geometría aparece poco y casi siempre en
estas formas: ¿están alineados estos puntos? (*Max Points on a Line*), ¿se solapan dos rectángulos?
([`18/03`](03-poligonos.md)), el área de un triángulo o de un polígono, la distancia de un punto a otro o a un segmento. Las
tres primeras se resuelven con un producto cruz o con comparaciones, y lo que se evalúa es no usar
pendientes con `double`.

Fuera de las entrevistas, el producto cruz es la primitiva de los motores de juegos (¿a qué lado de una
pared está el jugador?), de los sistemas de información geográfica (punto en polígono, `18/03`) y de la
robótica (el giro de una trayectoria).

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La geometría es con `double`» | Con coordenadas enteras, productos y áreas dobles son exactos en enteros; `double` solo donde el resultado no es entero |
| «`cross(a, b) = cross(b, a)`» | Es antisimétrico: `cross(b, a) = −cross(a, b)` |
| «Tres puntos están alineados si sus pendientes son iguales» | Las pendientes dividen por cero en las verticales y redondean; `cross == 0` en enteros |
| «Un épsilon de `1e-9` sirve siempre» | Depende de la magnitud de los datos: con productos de `10¹²`, el error de redondeo es mucho mayor |
| «El área del triángulo es `cross / 2`» | Es `\|cross\| / 2`; el signo dice la orientación |
| «En Java, `int` alcanza para coordenadas de `10⁹`» | Las coordenadas sí; sus productos no: `long` antes de multiplicar |

---

## 📚 Para profundizar

- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), cap. 1: el test de orientación y la robustez numérica. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §33.1: productos cruz y giros. *Lectura troncal.*
- **Libro** — O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), cap. 1: el área con signo
  como primitiva, con código.
- **Referencia** — cp-algorithms, [*Basic Geometry*](https://cp-algorithms.com/geometry/basic-geometry.html).
- **Referencia** — cp-algorithms, [*Oriented area of a triangle*](https://cp-algorithms.com/geometry/oriented-triangle-area.html).

---

## 🧠 Preguntas

1. ¿Qué miden el producto punto y el producto cruz de dos vectores del plano? 🟢
2. ¿Cómo decides si tres puntos giran a la izquierda, a la derecha o están alineados? 🟢
3. ¿Cómo calculas el área de un triángulo a partir de sus vértices? 🟢
4. ¿Qué responde el signo del producto punto y qué responde el del producto cruz? 🟡
5. ¿Hasta qué coordenadas cabe el producto cruz en 64 bits con signo? 🟡
6. ¿Por qué se comparan distancias por su cuadrado? 🟡
7. ¿Por qué el producto cruz en `double` puede decir «alineados» cuando no lo están? 🟠
8. ¿Cuándo hace falta un épsilon, y de qué depende su valor? 🟠
9. ¿Qué cambia entre C++, Java y Python al calcular un producto cruz con coordenadas de hasta `10⁹`? 🟠
10. ¿Por qué no se decide un giro con `atan2`? 🟠
11. Demuestra que el signo de `(b − a) × (c − a)` dice hacia qué lado gira `a → b → c`. 🔴
12. Da tres puntos con coordenadas menores que `10⁹` cuyo producto cruz en `double` salga 0 sin estar
    alineados, y explica por qué ocurre. 🔴

---

## 🧩 Problemas propios

### Las esquinas del repartidor

**Nivel:** 🟢 · **Formato:** programa completo.

Un recorrido pasa por `n` esquinas en orden. En cada esquina intermedia, el repartidor gira a la izquierda,
a la derecha o sigue recto (también si da media vuelta sobre la misma recta). Imprime cuántas veces hace
cada cosa.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`. Dos esquinas consecutivas nunca
  coinciden.
- **Salida.** Tres enteros: giros a la izquierda, a la derecha y rectos.
- **Restricciones.** `3 ≤ n ≤ 2·10⁵`; `|x|, |y| ≤ 10⁹`.

```text
Entrada         Salida
5               3 0 0
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
4               0 1 1
0 0
1 1
2 2
3 1
```

**Pista 1:** ¿qué operación con las tres esquinas `i − 1`, `i`, `i + 1` dice el lado, y de qué tipo tiene que
ser el resultado?

### El ángulo del brazo

**Nivel:** 🟡 · **Formato:** programa completo.

Un brazo robótico tiene el codo en `B` y sus extremos en `A` y `C`. Para cada consulta, imprime cómo es el
ángulo `ABC`: `AGUDO`, `RECTO` u `OBTUSO`; o `NULO` si `A` y `C` están en la misma semirrecta desde `B`, y
`LLANO` si están en semirrectas opuestas.

- **Entrada.** Una línea con `q`. Después, `q` líneas con `xA yA xB yB xC yC`. `A` y `C` son distintos de
  `B`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ q ≤ 10⁵`; coordenadas con `|·| ≤ 10⁹`.

```text
Entrada                                                               Salida
5                                                                     RECTO
0 3 0 0 4 0                                                           AGUDO
4 3 0 0 4 0                                                           OBTUSO
0 3 2 1 4 0                                                           NULO
4 0 0 0 2 0                                                           LLANO
4 0 2 0 0 0

Entrada                                                               Salida
1                                                                     AGUDO
-1000000000 -1000000000 1000000000 1000000000 -1000000000 1000000000
```

**Pista 1:** ¿qué producto distingue agudo de obtuso, cuál distingue «alineados» de «no alineados», y qué
pasa si los combinas?

### Triángulos de área entera

**Nivel:** 🟠 · **Formato:** programa completo.

Hay `n` puntos distintos. ¿Cuántos tríos de puntos forman un triángulo cuya área sea un número **entero**? Los
tríos alineados forman un triángulo de área 0, que cuenta.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`.
- **Salida.** Un entero.
- **Restricciones.** `3 ≤ n ≤ 2·10⁵`; `|x|, |y| ≤ 10⁹`.

```text
Entrada         Salida
5               10
0 0
4 0
4 3
0 3
2 1

Entrada         Salida
4               2
0 0
1 0
0 1
2 2
```

**Pista 1:** con `2·10⁵` puntos no puedes recorrer los tríos. ¿Qué información mínima de cada punto basta para
saber si el doble del área es par?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de enviar, prueba tus funciones con tres puntos alineados en vertical y con
> coordenadas de `10⁹`: son los dos casos que rompen la versión con pendientes. Si una IA te ayuda, que sea a
> generar esos casos, no la solución ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Valid Boomerang](https://leetcode.com/problems/valid-boomerang/) | LeetCode | 🟢 | Alineación | ¿Qué dos condiciones hacen que tres puntos no formen un bumerán? |
| [ ] | [Check If It Is a Straight Line](https://leetcode.com/problems/check-if-it-is-a-straight-line/) | LeetCode | 🟢 | Alineación | Si fijas los dos primeros puntos, ¿qué compruebas con cada uno de los demás? |
| [ ] | [Find the Point](https://www.hackerrank.com/challenges/find-point/problem) | HackerRank | 🟢 | Reflexión de un punto | Si `q` es el punto medio entre `p` y su reflejo, ¿dónde está el reflejo? |
| [ ] | [Largest Triangle Area](https://leetcode.com/problems/largest-triangle-area/) | LeetCode | 🟢 | Área con cruz | Con 50 puntos, ¿cuántos tríos hay, y cómo calculas el área de cada uno sin raíces? |
| [ ] | [Point Location Test](https://cses.fi/problemset/task/2189) | CSES | 🟢 | Orientación | ¿Qué signo tiene el resultado cuando el punto está a la izquierda? |
| [ ] | [Valid Square](https://leetcode.com/problems/valid-square/) | LeetCode | 🟡 | Distancias al cuadrado | ¿Cuántas distancias distintas hay entre los cuatro vértices de un cuadrado, y cuántas veces aparece cada una? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Trojke](https://open.kattis.com/problems/trojke) | Kattis | 🟡 | Tríos alineados | Con como mucho 26 puntos, ¿cuántos tríos hay que mirar? |
| [ ] | [Polar Angles](https://www.hackerrank.com/challenges/polar-angles/problem) | HackerRank | 🟠 | Ordenar por ángulo | ¿Cómo comparas dos puntos por ángulo sin calcularlo, si primero los separas por semiplano? |
| [ ] | [Max Points on a Line](https://leetcode.com/problems/max-points-on-a-line/) | LeetCode | 🔴 | Dirección normalizada | Fijado un punto, ¿cómo representas la dirección hacia otro para que dos direcciones iguales den la misma clave? |
| [ ] | [Maximum Number of Visible Points](https://leetcode.com/problems/maximum-number-of-visible-points/) | LeetCode | 🔴 | Ángulos y ventana | Si ordenas los ángulos y los duplicas sumando 360°, ¿qué técnica de secuencias queda? |

---

## ✅ Criterio de dominio

- Escribir `cross`, `dot` y `orient` en los tres lenguajes sin mirar, con los tipos correctos.
- Demostrar por qué el signo del producto cruz da el sentido del giro.
- Dar un ejemplo en el que el `double` falla y explicar el épsilon a escala.
- Resolver Valid Boomerang, Point Location Test y Valid Square sin pista 2.

---

**Anterior:** — · **Siguiente:** [`18/02` — Rectas y segmentos](02-rectas-y-segmentos.md) ·
**Relacionado:** [`01/04` — Tipos, desbordamiento y el primer contacto con el módulo](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md).
