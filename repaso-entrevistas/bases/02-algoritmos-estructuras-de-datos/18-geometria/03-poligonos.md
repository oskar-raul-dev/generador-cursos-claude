# 03 — Polígonos

> El área de un polígono con la fórmula del cordón, que suma productos cruz y no necesita triangular; si un
> punto está dentro, fuera o en el borde, con un rayo; el teorema de Pick, que cuenta los puntos enteros de
> un polígono sin recorrerlos; y el solapamiento de rectángulos, que es lo que de verdad sale en entrevista.
>
> **Niveles:** fórmula del cordón [B] · punto en polígono [B] · Pick [B].
>
> **📚 Lectura troncal:** O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), cap. 1.
>
> **Asume leído:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--fórmula-del-cordón) · [4](#4--punto-en-polígono) · [5](#5--pick) · [6](#6--rectángulos-lo-que-sí-te-pueden-preguntar) · [7](#7-️-la-tabla-de-costes) · [8](#8--cómo-se-elige) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un terreno tiene forma de polígono, dado por sus esquinas en orden. ¿Cuánto mide? ¿Está la casa dentro? ¿Cuántos
árboles caben si se plantan en los puntos de coordenadas enteras? La intuición escolar dice que para el área
hay que partir el polígono en triángulos, y para «dentro» hay que mirar ángulos. Ninguna de las dos hace
falta.

El área sale de una suma de `n` productos cruz, sin triangular y aunque el polígono no sea convexo. «Dentro»
se decide contando cuántas veces un rayo cruza el borde. Y los puntos enteros salen de una fórmula de dos
números, el área y los puntos del borde.

> 🧠 **Modelo mental.** El área de un polígono es la suma de las áreas con signo de los triángulos que cada
> lado forma con un punto fijo: los que «sobran» fuera del polígono aparecen dos veces con signos opuestos y
> se cancelan.

Los ejemplos usan el rectángulo de juguete `R = (0,0) (4,0) (4,3) (0,3)` y el pentágono no convexo
`C = (0,0) (4,0) (4,3) (2,1) (0,3)`, el mismo con una muesca hasta `(2,1)`:

```text
R: área 12 · (2,1) interior · 14 puntos enteros en el borde · 6 dentro
C: área 8  · (2,1) es un vértice · (2,2) queda fuera, en la muesca · 14 en el borde · 2 dentro
```

---

## 2. 📐 La teoría

**Fórmula del cordón** (*shoelace*). Para un polígono simple con vértices `p₀, …, p_{n−1}` en orden:

```text
2A = Σ_{i=0}^{n−1} pᵢ × p_{i+1}          (con p_n = p₀)
```

El signo es la orientación: positivo si los vértices van en sentido antihorario, negativo si van en horario.
El área es `|2A| / 2`.

*Prueba.* `pᵢ × p_{i+1}` es el doble del área con signo del triángulo `(O, pᵢ, p_{i+1})`, con `O` el origen.
Para un punto `q` cualquiera, la suma de esas áreas con signo cuenta `q` tantas veces como el **número de
vueltas** del borde alrededor de `q`: 1 si está dentro de un polígono simple antihorario, 0 si está fuera. Así
que la suma es el área del polígono. El origen no importa: cambiarlo suma y resta los mismos términos.

**Punto en polígono.** Un rayo horizontal desde `p` hacia la derecha cruza el borde un número impar de veces
si y solo si `p` está dentro (teorema de la curva de Jordan para polígonos). Para no contar dos veces un
vértice que el rayo toca, cada lado se trata como **semiabierto** en `y`: cuenta si un extremo está
estrictamente por encima de `p` y el otro no.

**Número de vueltas.** La alternativa: sumar `+1` por cada lado que cruza el rayo subiendo y `−1` por cada uno
que lo cruza bajando. Para polígonos simples da lo mismo que la paridad; para polígonos que se cruzan, dice
cuántas veces se rodea el punto.

**Teorema de Pick.** Para un polígono simple con vértices enteros, con `I` puntos enteros en el interior y
`B` en el borde:

```text
A = I + B/2 − 1
```

Los puntos enteros de un lado de `(x₁, y₁)` a `(x₂, y₂)`, sin contar uno de los extremos, son
`gcd(|x₂ − x₁|, |y₂ − y₁|)`: `B` es la suma de esos `gcd`.

---

## 3. 🧱 Fórmula del cordón

**Qué es.** El área de un polígono simple, en enteros (el doble) y con su orientación.

**Por qué es correcto.** La suma de áreas orientadas de §2.

**Cómo va**, con `C` (antihorario):

```text
(0,0) × (4,0) = 0      (4,0) × (4,3) = 12     (4,3) × (2,1) = 4·1 − 3·2 = −2
(2,1) × (0,3) = 6      (0,3) × (0,0) = 0
2A = 16 > 0 → antihorario, área 8          (R da 2A = 24, área 12; R al revés, −24)
```

**Cuánto.** `Θ(n)`.

**La plantilla:**

```cpp
#include <vector>

// Doble del área con signo: > 0 si los vértices van en sentido antihorario.
long long area2(const std::vector<Pt>& p) {
    __int128 s = 0;                        // las sumas parciales pueden pasar de 2⁶³
    int n = p.size();
    for (int i = 0; i < n; i++) s += cross(p[i], p[(i + 1) % n]);
    return (long long) s;
}
```

```java
// Doble del área con signo. El desbordamiento de long en Java da la vuelta de forma definida:
// si el total cabe en 64 bits, sale bien aunque una suma parcial no quepa.
static long area2(Pt[] p) {
    long s = 0;
    for (int i = 0; i < p.length; i++) s += p[i].cross(p[(i + 1) % p.length]);
    return s;
}
```

- **El doble, en enteros.** El área de un polígono con vértices enteros es múltiplo de `1/2`: se guarda
  `2A` y se imprime `2A / 2` con su `.5` si es impar.
- **Las sumas parciales** pueden pasar de `2⁶³` con coordenadas de `10⁹` aunque el total quepa (`2A ≤ 8·10¹⁸`).
  En C++ el desbordamiento con signo es comportamiento indefinido: `__int128`. En Java da la vuelta de forma
  definida y el total sale bien. En Python, sin límite.
- **El signo** dice la orientación: es lo que usan los algoritmos que necesitan los vértices en sentido
  antihorario (la envolvente de [`18/04`](04-envolvente-convexa.md)), y se pierde con el valor absoluto.

**Cuándo sí:** el área de cualquier polígono simple, convexo o no; la orientación de un polígono dado.
**Cuándo no:** si el polígono se corta a sí mismo, la fórmula da la suma con signo de las regiones, no el área
que se ve; si hay agujeros, se resta el área de cada agujero.

> **Veredicto:** el área de un polígono es una línea de código: la suma de `pᵢ × p_{i+1}`. Sin triangular, sin
> raíces, exacta en enteros, y con la orientación de regalo.

---

## 4. 🧱 Punto en polígono

**Qué es.** Decidir si un punto está dentro, fuera o en el borde de un polígono simple.

**Por qué es correcto.** La paridad de cortes de un rayo (§2), con los lados semiabiertos para que un vértice
cuente una sola vez, y una comprobación previa del borde, que el rayo no distingue.

**Cómo va**, con `C` y el rayo horizontal hacia la derecha:

```text
p = (1,1): cruza (4,0)–(4,3)                                   → 1 corte, dentro
p = (2,2): cruza (4,0)–(4,3) y (4,3)–(2,1)                     → 2 cortes, fuera (la muesca)
p = (2,1): está en el borde (es un vértice)                    → borde, antes de contar
p = (5,1): ningún lado cruza a su derecha                      → 0 cortes, fuera
```

**Cuánto.** `Θ(n)` por consulta. Para un polígono **convexo**, `O(log n)` con búsqueda binaria por ángulo
desde un vértice.

**La plantilla**, con `onSegment` de [`18/02`](02-rectas-y-segmentos.md):

```cpp
// 1 si p está dentro, 0 si está en el borde, −1 si está fuera.
int pointInPolygon(const std::vector<Pt>& poly, Pt p) {
    bool inside = false;
    int n = poly.size();
    for (int i = 0; i < n; i++) {
        Pt a = poly[i], b = poly[(i + 1) % n];
        if (onSegment(a, b, p)) return 0;
        if ((a.y > p.y) != (b.y > p.y)) {                   // el lado cruza la horizontal de p
            long long o = cross(b - a, p - a);
            if ((o > 0) == (b.y > a.y)) inside = !inside;   // y el cruce está a la derecha de p
        }
    }
    return inside ? 1 : -1;
}
```

```java
static int pointInPolygon(Pt[] poly, Pt p) {
    boolean inside = false;
    for (int i = 0; i < poly.length; i++) {
        Pt a = poly[i], b = poly[(i + 1) % poly.length];
        if (onSegment(a, b, p)) return 0;
        if ((a.y() > p.y()) != (b.y() > p.y())) {
            long o = b.minus(a).cross(p.minus(a));
            if ((o > 0) == (b.y() > a.y())) inside = !inside;
        }
    }
    return inside ? 1 : -1;
}
```

- **`(a.y > p.y) != (b.y > p.y)`** es el lado semiabierto: un vértice a la altura de `p` cuenta para uno solo
  de sus dos lados, y un lado horizontal no cuenta nunca.
- **Sin divisiones.** En lugar de calcular la `x` del cruce, se mira de qué lado del lado queda `p`: si el lado
  sube y `p` está a su izquierda, el cruce está a la derecha de `p`.
- **El borde primero**: el rayo no sabe distinguir «en el borde» y lo clasificaría al azar.

**Cuándo sí:** pocas consultas sobre un polígono cualquiera. **Cuándo no:** con `10⁵` consultas sobre un
polígono de `10⁵` lados: si es convexo, la binaria; si no, un barrido o una estructura de localización.

> **Veredicto:** dentro o fuera es la paridad de un rayo, con lados semiabiertos y el borde comprobado antes.
> Las dos líneas que se olvidan son exactamente esas dos.

---

## 5. 🧱 Pick

**Qué es.** El número de puntos enteros dentro de un polígono simple de vértices enteros, a partir de su área
y de los puntos del borde.

**Por qué es correcto.** El teorema de Pick, `A = I + B/2 − 1`. *Esbozo:* la fórmula es aditiva al pegar dos
polígonos por un lado (los puntos del lado común pasan del borde al interior y la cuenta cuadra), y es cierta
para los triángulos con un solo punto entero en cada vértice y ninguno más, que tienen área `1/2`; todo
polígono se descompone en ellos.

**Cómo va**, con `R`:

```text
B = gcd(4,0) + gcd(0,3) + gcd(4,0) + gcd(0,3) = 4 + 3 + 4 + 3 = 14
I = A − B/2 + 1 = 12 − 7 + 1 = 6            los puntos (1..3, 1..2)
```

y con `C`: `2A = 16`, `B = 4 + 3 + 2 + 2 + 3 = 14`, `I = (16 − 14 + 2) / 2 = 2`: `(1,1)` y `(3,1)`.

**Cuánto.** `Θ(n log C)`, con `C` el tamaño de las coordenadas (un `gcd` por lado).

**La plantilla:**

```cpp
#include <cstdlib>
#include <numeric>
#include <utility>

// Puntos enteros en el borde y en el interior de un polígono simple con vértices enteros.
std::pair<long long, long long> latticePoints(const std::vector<Pt>& p) {
    long long b = 0;
    int n = p.size();
    for (int i = 0; i < n; i++) {
        Pt d = p[(i + 1) % n] - p[i];
        b += std::gcd(std::llabs(d.x), std::llabs(d.y));
    }
    long long a2 = std::llabs(area2(p));
    return {b, (a2 - b + 2) / 2};                          // I = (2A − B + 2) / 2
}
```

```java
static long[] latticePoints(Pt[] p) {
    long b = 0;
    for (int i = 0; i < p.length; i++) {
        Pt d = p[(i + 1) % p.length].minus(p[i]);
        b += java.math.BigInteger.valueOf(Math.abs(d.x())).gcd(java.math.BigInteger.valueOf(Math.abs(d.y()))).longValue();
    }
    long a2 = Math.abs(area2(p));
    return new long[]{b, (a2 - b + 2) / 2};
}
```

- **Todo en enteros**: `2I = 2A − B + 2`, sin mitades.
- **Java no trae `gcd` de `long`** fuera de `BigInteger`; en un concurso se escribe el de
  [`17/02`](../17-matematica/02-divisibilidad.md) en dos líneas. C++17 trae `std::gcd`; Python, `math.gcd`.

**Cuándo sí:** contar puntos enteros dentro o en el borde sin recorrerlos (coordenadas de `10⁹`); comprobar
un área. **Cuándo no:** si los vértices no son enteros, o si el polígono no es simple.

> **Veredicto:** Pick convierte «cuántos puntos enteros hay dentro» en el área y una suma de `gcd`. Es la
> única forma razonable cuando las coordenadas son grandes.

---

## 6. 🧱 Rectángulos: lo que sí te pueden preguntar

**Qué es.** El caso de entrevista: dos rectángulos alineados con los ejes, dados por sus esquinas
`(x₁, y₁, x₂, y₂)`. ¿Se solapan? ¿Cuánto mide la intersección? ¿Y la unión?

**Por qué es correcto.** La intersección de dos rectángulos alineados es otro rectángulo (o vacío): sus lados
son el máximo de los izquierdos, el mínimo de los derechos, y lo mismo en `y`. Es la intersección de dos
intervalos en cada eje.

**Cómo va**, con `[0,4]×[0,3]` y `[2,6]×[1,5]`:

```text
ancho = min(4, 6) − max(0, 2) = 2        alto = min(3, 5) − max(0, 1) = 2
intersección = 4 · unión = 12 + 16 − 4 = 24
[0,4]×[0,3] y [4,8]×[0,1]: ancho = 4 − 4 = 0 → se tocan, no se solapan
```

**Cuánto.** `O(1)`.

**La plantilla**, también en Python, porque es la que se pide en una entrevista:

```cpp
#include <algorithm>

// Área de la intersección de dos rectángulos {x1, y1, x2, y2} con x1 < x2, y1 < y2.
long long overlapArea(const long long r[4], const long long s[4]) {
    long long w = std::min(r[2], s[2]) - std::max(r[0], s[0]);
    long long h = std::min(r[3], s[3]) - std::max(r[1], s[1]);
    return (w > 0 && h > 0) ? w * h : 0;
}
```

```java
static long overlapArea(long[] r, long[] s) {
    long w = Math.min(r[2], s[2]) - Math.max(r[0], s[0]);
    long h = Math.min(r[3], s[3]) - Math.max(r[1], s[1]);
    return (w > 0 && h > 0) ? w * h : 0;
}
```

```python
def overlap_area(r, s):
    w = min(r[2], s[2]) - max(r[0], s[0])
    h = min(r[3], s[3]) - max(r[1], s[1])
    return w * h if w > 0 and h > 0 else 0
```

- **`w > 0 && h > 0`**, no `w * h > 0`: con dos negativos, el producto es positivo.
- **Tocarse no es solaparse**: con `w = 0` el área común es 0. Si el enunciado cuenta el contacto, `≥`.
- **La unión de dos** es `A₁ + A₂ − intersección`; la de muchos, un barrido ([`18/05`](05-barrido-geometrico.md)).

**Cuándo sí:** solapamiento de reservas en un plano, ventanas en pantalla, cajas de colisión. **Cuándo no:**
con rectángulos girados, que son polígonos convexos: intersección de polígonos ([`18/06`](06-geometria-avanzada.md)).

> **Veredicto:** dos rectángulos se solapan si se solapan sus intervalos en `x` **y** en `y`. Es la pregunta
> de geometría más frecuente en entrevistas, y se resuelve con dos `min` y dos `max`.

---

## 7. ⏱️ La tabla de costes

| Operación | Coste | Lo que la tabla no dice |
|---|---|---|
| Área (cordón) | `Θ(n)` | Sumas parciales de más de `2⁶³` con coordenadas de `10⁹` |
| Orientación de un polígono | `Θ(n)` | Es el signo del área |
| Punto en polígono | `Θ(n)` | `O(log n)` si es convexo |
| Puntos enteros (Pick) | `Θ(n log C)` | Solo con vértices enteros y polígono simple |
| Intersección de dos rectángulos | `O(1)` | `w > 0` y `h > 0` por separado |

---

## 8. 🧭 Cómo se elige

```text
¿Área u orientación de un polígono? → cordón, en enteros (el doble)
¿Dentro, fuera o en el borde? → borde primero; después el rayo semiabierto · convexo y muchas consultas: binaria
¿Cuántos puntos enteros dentro o en el borde? → Pick
¿Rectángulos alineados? → intervalos en x y en y
¿Unión de muchos rectángulos? → barrido (18/05)
```

> **Regla de entrevista:** si te preguntan por el solapamiento de dos rectángulos, empieza por «es la
> intersección de dos intervalos en cada eje» y escribe el `max` y el `min` antes que ningún caso.

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Área del polígono», «¿en qué sentido van los vértices?» | Cordón | Suma de productos cruz |
| «¿Está dentro?» con un polígono cualquiera | Rayo semiabierto | Paridad de cortes |
| «Puntos de coordenadas enteras dentro del terreno» | Pick | Sin recorrerlos |
| «¿Se solapan dos rectángulos?», «área común» | Intervalos en cada eje | `O(1)` |
| «Polígono convexo» y `10⁵` consultas de punto | Binaria por ángulo | `O(log n)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El área de un polígono necesita triangularlo» | El cordón suma `n` productos cruz y vale para no convexos |
| «El área es la suma de `pᵢ × p_{i+1}`» | Es la **mitad** del valor absoluto de esa suma |
| «Un rayo que pasa por un vértice cuenta dos cortes» | Con lados semiabiertos cuenta uno; sin ellos, el resultado es aleatorio |
| «El rayo dice también si el punto está en el borde» | No: el borde se comprueba aparte, antes |
| «Dos rectángulos se solapan si `w · h > 0`» | Con `w` y `h` negativos, el producto es positivo: `w > 0` **y** `h > 0` |
| «Pick vale para cualquier polígono» | Solo para simples con vértices enteros |

---

## 📚 Para profundizar

- **Libro** — O'Rourke, *Computational Geometry in C*, 2.ª ed. (Cambridge, 1998), cap. 1: el área como suma
  de áreas con signo, con código. *Lectura troncal.*
- **Libro** — de Berg y otros, *Computational Geometry: Algorithms and Applications*, 3.ª ed. (Springer,
  2008), cap. 3: polígonos y triangulación, para quien quiera ir más allá.
- **Referencia** — cp-algorithms, [*Area of simple polygon*](https://cp-algorithms.com/geometry/area-of-simple-polygon.html).
- **Referencia** — cp-algorithms, [*Pick's Theorem - area of lattice polygons*](https://cp-algorithms.com/geometry/picks-theorem.html).
- **Referencia** — cp-algorithms, [*Check if points belong to the convex polygon in O(log N)*](https://cp-algorithms.com/geometry/point-in-convex-polygon.html).

---

## 🧠 Preguntas

1. ¿Qué es la fórmula del cordón y qué dice su signo? 🟢
2. ¿Cómo decides si un punto está dentro de un polígono con un rayo? 🟢
3. ¿Qué dice el teorema de Pick? 🟢
4. ¿Cuándo se solapan dos rectángulos alineados con los ejes, y cuánto mide su intersección? 🟢
5. ¿Por qué la fórmula del cordón funciona también con polígonos no convexos? 🟡
6. ¿Qué diferencia hay entre la paridad de cortes del rayo y el número de vueltas? 🟡
7. ¿Cuántos puntos enteros tiene el segmento entre dos puntos enteros? 🟡
8. ¿Por qué el rayo cuenta mal si pasa por un vértice, y cómo se evita? 🟠
9. ¿Qué cambia entre C++, Java y Python al calcular el área de un polígono de `10⁵` vértices con coordenadas de
   `10⁹`? 🟠
10. ¿Cómo decides en `O(log n)` si un punto está dentro de un polígono convexo? 🟠
11. Demuestra la fórmula del cordón a partir de las áreas con signo de triángulos. 🔴
12. Diseña cómo contar los puntos enteros estrictamente dentro de un polígono simple con vértices enteros de
    hasta `10⁹`, y aplícalo al pentágono `C`. 🔴

---

## 🧩 Problemas propios

### Salas que se solapan

**Nivel:** 🟢 · **Formato:** programa completo.

En el plano de una oficina hay `n` salas rectangulares, alineadas con los ejes. ¿Cuántos pares de salas
comparten un área positiva? Tocarse por un lado o una esquina no cuenta.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x₁ y₁ x₂ y₂`, con `x₁ < x₂` e `y₁ < y₂`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2 000`; coordenadas con `|·| ≤ 10⁹`.

```text
Entrada         Salida
4               2
0 0 4 3
2 1 6 5
4 0 8 1
5 4 7 6

Entrada         Salida
2               0
0 0 1 1
1 1 2 2
```

**Pista 1:** ¿qué tiene que pasar con los intervalos en `x` de dos salas, y qué con los de `y`, para que
compartan área?

### Boyas en el lago

**Nivel:** 🟡 · **Formato:** programa completo.

Un lago tiene forma de polígono simple, no necesariamente convexo. Para cada boya, imprime `DENTRO`, `FUERA`
u `ORILLA`.

- **Entrada.** Una línea con `n`. Después, `n` líneas con los vértices en orden (horario o antihorario). Una
  línea con `q`. Después, `q` líneas con las boyas.
- **Salida.** `q` líneas.
- **Restricciones.** `3 ≤ n ≤ 1 000`; `1 ≤ q ≤ 1 000`; coordenadas enteras con `|·| ≤ 10⁹`.

```text
Entrada              Salida
5                    DENTRO
0 0                  FUERA
4 0                  ORILLA
4 3                  FUERA
2 1                  ORILLA
0 3
5
1 1
2 2
2 1
5 1
4 2

Entrada              Salida
3                    ORILLA
0 0                  ORILLA
1000000000 0
0 1000000000
2
0 0
500000000 500000000
```

**Pista 1:** si sales de la boya en línea recta hacia el este, ¿qué te dice el número de veces que cruzas la
orilla, y qué haces si la línea pasa justo por una esquina?

---

## 🧩 Práctica externa

> 💡 **Truco.** Prueba tus funciones con un polígono no convexo y con puntos en vértices y en lados
> horizontales: son los casos que rompen el rayo. Si una IA te ayuda, que sea a dibujar el caso que falla, no a
> escribir la función ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Rectangle Overlap](https://leetcode.com/problems/rectangle-overlap/) | LeetCode | 🟢 | Intervalos en cada eje | ¿Cuándo **no** se solapan dos intervalos? |
| [ ] | [Polygon Area](https://cses.fi/problemset/task/2191) | CSES | 🟢 | Cordón | ¿Por qué el enunciado pide el doble del área? |
| [ ] | [Polygon Area](https://open.kattis.com/problems/polygonarea) | Kattis | 🟢 | Cordón con orientación | ¿Qué parte del resultado te dice si los vértices van en sentido horario? |
| [ ] | [Rectangle Area](https://leetcode.com/problems/rectangle-area/) | LeetCode | 🟡 | Unión de dos | Si sabes la intersección, ¿cuánto mide la unión? |
| [ ] | [Find the Largest Area of Square Inside Two Rectangles](https://leetcode.com/problems/find-the-largest-area-of-square-inside-two-rectangles/) | LeetCode | 🟡 | Intersección por pares | Si la intersección de dos rectángulos mide `w × h`, ¿qué cuadrado cabe dentro? |
| [ ] | [Minimum Area Rectangle](https://leetcode.com/problems/minimum-area-rectangle/) | LeetCode | 🟡 | Diagonales y conjunto | Si eliges dos puntos como esquinas opuestas, ¿qué otros dos tienen que existir? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Jabuke](https://open.kattis.com/problems/jabuke) | Kattis | 🟡 | Área y punto en triángulo | ¿Qué tres orientaciones dicen si un manzano está dentro del triángulo o en su borde? |
| [ ] | [Polygon Lattice Points](https://cses.fi/problemset/task/2193) | CSES | 🟠 | Pick | ¿Qué dos números del polígono, fáciles de calcular, determinan los puntos del interior? |
| [ ] | [Cookie Cutters](https://open.kattis.com/problems/cookiecutter) | Kattis | 🟠 | Escalar un polígono | Si escalas un polígono por `k`, ¿por cuánto se multiplica el área? |
| [ ] | [Perfect Rectangle](https://leetcode.com/problems/perfect-rectangle/) | LeetCode | 🔴 | Área y esquinas | Si las piezas forman un rectángulo exacto, ¿qué tiene que cumplir la suma de áreas y qué esquinas aparecen un número impar de veces? |

---

## ✅ Criterio de dominio

- Escribir el cordón y el punto en polígono en C++ o Java sin mirar, con los lados semiabiertos.
- Demostrar el cordón con áreas con signo y aplicar Pick a mano.
- Escribir el solapamiento de dos rectángulos en el lenguaje de la entrevista en dos minutos.
- Resolver Rectangle Overlap, Polygon Area (CSES) y Rectangle Area sin pista 2.

---

**Anterior:** [`18/02` — Rectas y segmentos](02-rectas-y-segmentos.md) · **Siguiente:** [`18/04` — Envolvente convexa](04-envolvente-convexa.md) ·
**Relacionado:** [`18/01` — Vectores, productos y orientación](01-vectores-y-orientacion.md).
