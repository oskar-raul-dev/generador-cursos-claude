# 05 — Heurísticos y aproximados

> Qué hacer cuando un problema de optimización no tiene solución exacta en el tiempo disponible: búsqueda
> local, que mejora una solución con cambios pequeños; recocido simulado, que acepta empeorar a veces para
> salir de los óptimos locales; *beam search*, que explora varias soluciones parciales a la vez; y los
> algoritmos de aproximación, que sí garantizan estar a un factor del óptimo. Con el formato de los concursos
> de heurísticos (AtCoder Heuristic Contest, CodinGame).
>
> **Niveles:** búsqueda local [B] · recocido simulado [B] · *beam search* [B] · aproximación con garantía [C].
>
> **📚 Lectura troncal:** Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 13;
> Russell y Norvig, *Artificial Intelligence: A Modern Approach*, 4.ª ed. (Pearson, 2020), cap. 4; Kleinberg y
> Tardos, *Algorithm Design* (Addison-Wesley, 2005), caps. 11–12.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--búsqueda-local) · [4](#4--recocido-simulado) · [5](#5--beam-search) · [6](#6--aproximación-con-garantía) · [7](#7-️-la-tabla-de-costes) · [8](#8--cómo-se-elige) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un repartidor tiene que visitar 200 direcciones y volver al almacén por el camino más corto. Es el problema
del viajante: NP-difícil ([`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md)), y
la DP exacta sobre subconjuntos ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)) se queda en unas 20
direcciones. Pero el repartidor no necesita **el** óptimo: necesita un recorrido bueno, hoy.

Con 200 puntos al azar, recorrerlos en el orden de la lista mide 1 058 347 unidades. Mejorando el recorrido
con cambios pequeños mientras se pueda (búsqueda local con 2-opt), baja a 112 231. Aceptando de vez en cuando
un cambio que empeora (recocido simulado), baja a unos 106 000: un 5 % más corto, en menos de un segundo. Ninguno
de los dos garantiza el óptimo; los dos son lo que se usa en la industria y en los concursos de heurísticos.

> 🧠 **Modelo mental.** La búsqueda local es bajar una montaña a ciegas, siempre cuesta abajo: llegas a un
> valle, no necesariamente el más profundo. El recocido es bajar con un poco de temblor, que al principio te
> deja saltar crestas y al final se calma.

---

## 2. 📐 La teoría

**Vecindad y óptimo local.** Una búsqueda local necesita un **movimiento** que transforma una solución en
otra parecida (en el viajante, 2-opt: invertir un tramo del recorrido, que cambia dos aristas). Un **óptimo
local** es una solución que ningún movimiento mejora; puede estar lejos del óptimo global.

**Recocido simulado.** En cada paso se propone un movimiento al azar con variación `Δ` del coste. Si mejora
(`Δ ≤ 0`), se acepta; si empeora, se acepta con probabilidad `e^{−Δ/T}`. La **temperatura** `T` baja con el
tiempo: al principio se aceptan empeoramientos grandes y la búsqueda explora; al final casi ninguno y la
búsqueda se comporta como una local. Con un enfriamiento lo bastante lento, la cadena de Markov resultante
([`19/04`](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md)) se concentra en los óptimos
globales; en la práctica, se usa como heurística sin esa garantía.

**Beam search.** Una búsqueda en anchura que, en cada nivel, conserva solo las `B` mejores soluciones parciales
según una evaluación. Con `B = 1` es un voraz; con `B` infinito, una búsqueda exhaustiva.

**Aproximación con garantía.** Un algoritmo es una `α`-aproximación si su solución nunca cuesta más que `α`
veces el óptimo (en minimización). La **cobertura de vértices** tiene una 2-aproximación: tomar un
emparejamiento maximal y meter en la cobertura los dos extremos de cada arista emparejada.

*Prueba.* Las aristas emparejadas no comparten extremos, así que cualquier cobertura necesita al menos un
vértice por cada una: `OPT ≥ |M|`. El algoritmo toma `2|M| ≤ 2 · OPT`. Y es una cobertura: si una arista no
estuviera cubierta, se podría añadir al emparejamiento, contra que es maximal.

---

## 3. 🧱 Búsqueda local

**Qué es.** Partir de una solución y aplicar movimientos que la mejoran mientras exista alguno.

**Por qué es correcto.** Siempre devuelve una solución válida (los movimientos la conservan) y termina
(el coste baja en cada paso y hay un número finito de soluciones). No garantiza el óptimo: se detiene en un
óptimo local.

**Cómo va**, con 2-opt sobre el rectángulo de juguete recorrido en orden cruzado `(0,0) (4,3) (4,0) (0,3)`:

```text
recorrido inicial: 5 + 3 + 5 + 3 = 16      (las dos diagonales se cruzan)
2-opt sobre las aristas (0,0)–(4,3) y (4,0)–(0,3): se cambian por (0,0)–(4,0) y (4,3)–(0,3)
nuevo recorrido: (0,0) (4,0) (4,3) (0,3), longitud 14; ningún 2-opt lo mejora: óptimo local (y global)
```

**Cuánto.** Cada pasada por todos los movimientos 2-opt cuesta `Θ(n²)`; el número de pasadas no tiene una cota
pequeña en el peor caso, pero en la práctica son pocas.

**La plantilla**, en pseudocódigo (el capítulo escribe en C++ solo el recocido, como fija su ficha):

```text
sol ← solución inicial (por ejemplo, voraz)
repetir:
    para cada movimiento m de la vecindad de sol:
        si coste(m(sol)) < coste(sol): sol ← m(sol); volver a empezar
    si ninguno mejora: devolver sol
```

**Cuándo sí:** como primera mejora de una solución voraz; cuando la vecindad es pequeña y la evaluación del
cambio es barata (`O(1)` en 2-opt). **Cuándo no:** si los óptimos locales son malos y abundantes; ahí, recocido
o reinicios aleatorios.

> **Veredicto:** la búsqueda local convierte una solución voraz en una buena con muy poco código. Su límite es
> el primer valle que encuentra.

---

## 4. 🧱 Recocido simulado

**Qué es.** Búsqueda local con movimientos al azar que acepta empeorar con probabilidad `e^{−Δ/T}`, con `T`
bajando durante la ejecución.

**Por qué es correcto.** Como heurística, no garantiza nada en tiempo finito; su ventaja es que puede salir de
los óptimos locales. Con `T` alta acepta casi todo (explora); con `T` baja, casi solo mejoras (explota).

**Cómo va**, con los 200 puntos de §1, 20 millones de iteraciones y la temperatura bajando de 1 000 a 1:

```text
recorrido inicial (orden de la lista)    1 058 347
búsqueda local 2-opt                        112 231
recocido, tres semillas                     106 514 · 105 807 · 107 031   (≈ 5 % mejor, ≈ 0,6 s cada uno)
```

**Cuánto.** Lo que se le dé: el número de iteraciones (o el tiempo) es un parámetro. Cada iteración cuesta lo
que evaluar `Δ` (aquí, `O(1)`) más aplicar el movimiento si se acepta (aquí, invertir un tramo, `O(n)`).

**La plantilla**, en C++:

```cpp
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <numeric>
#include <random>
#include <vector>

struct P2 { double x, y; };

double dist(const P2& a, const P2& b) { return std::hypot(a.x - b.x, a.y - b.y); }

// Recocido simulado para el viajante con movimientos 2-opt (invertir un tramo del recorrido).
// La temperatura baja de forma geométrica de t0 a t1 a lo largo de las iteraciones.
std::vector<int> annealTSP(const std::vector<P2>& p, long long iterations, double t0, double t1, uint64_t seed) {
    int n = p.size();
    std::vector<int> tour(n);
    std::iota(tour.begin(), tour.end(), 0);
    if (n < 4) return tour;
    std::mt19937_64 rng(seed);
    std::uniform_real_distribution<double> unif(0.0, 1.0);
    for (long long it = 0; it < iterations; it++) {
        double temp = t0 * std::pow(t1 / t0, (double) it / iterations);
        int i = rng() % n, j = rng() % n;
        if (i > j) std::swap(i, j);
        if (j - i < 2 || (i == 0 && j == n - 1)) continue;          // tramo vacío o el recorrido entero
        int a = tour[i], b = tour[i + 1], c = tour[j], d = tour[(j + 1) % n];
        double delta = dist(p[a], p[c]) + dist(p[b], p[d]) - dist(p[a], p[b]) - dist(p[c], p[d]);
        if (delta <= 0 || unif(rng) < std::exp(-delta / temp))       // acepta peores con prob. e^(−Δ/T)
            std::reverse(tour.begin() + i + 1, tour.begin() + j + 1);
    }
    return tour;
}
```

- **La temperatura en las unidades del coste.** `t0` del orden de un `Δ` típico al principio (aquí, distancias
  de cientos o miles), `t1` del orden del menor cambio que importa. Se ajustan probando: es el parámetro que más
  cambia el resultado.
- **Evaluar `Δ`, no el coste entero**: el cambio de 2-opt solo toca dos aristas, `O(1)`. Recalcular el recorrido
  entero en cada iteración lo haría `n` veces más lento.
- **Por iteraciones o por tiempo.** Con un número fijo de iteraciones y una semilla, el resultado es
  reproducible; en un concurso se usa el reloj (`steady_clock`) para gastar todo el tiempo disponible.
- **En Java** el esquema es el mismo; en Python, el número de iteraciones por segundo es unas 50 veces menor y
  conviene NumPy o mover el bucle a una función compilada.

**Cuándo sí:** problemas de optimización con una solución fácil de modificar y de evaluar: rutas, asignaciones,
calendarios, colocaciones; los concursos de heurísticos. **Cuándo no:** si existe un algoritmo exacto que entra
en el tiempo, o si la evaluación de un cambio es tan cara que se pueden probar muy pocos.

> **Veredicto:** el recocido es búsqueda local con permiso para empeorar al principio. Con un movimiento barato
> de evaluar y una temperatura bien ajustada, es la herramienta que más rinde por línea de código en
> optimización.

---

## 5. 🧱 *Beam search*

**Qué es.** Construir la solución paso a paso, conservando en cada paso las `B` mejores soluciones parciales
según una evaluación, y descartando el resto.

**Por qué es correcto.** Como heurística: con `B = 1` es un voraz; con `B` mayor, tolera que la mejor opción del
momento no sea la mejor al final. No garantiza el óptimo: la evaluación de una solución parcial puede
engañar.

**Cómo va.** En un juego de un jugador de `T` turnos con unas pocas jugadas por turno, se guardan los `B` estados
con mejor puntuación tras cada turno; se expanden todas sus jugadas, se evalúan los hijos y se vuelven a quedar
los `B` mejores.

**Cuánto.** `Θ(T · B · jugadas · coste de evaluar)`, más ordenar o seleccionar los `B` mejores en cada nivel.

**La plantilla**, en pseudocódigo:

```text
haz ← {estado inicial}
para turno = 1 .. T:
    hijos ← todos los estados alcanzables con una jugada desde algún estado del haz
    haz ← los B hijos con mejor evaluación (quitando repetidos)
devolver el mejor estado del haz
```

**Cuándo sí:** problemas por turnos o por pasos con una buena evaluación parcial (juegos de un jugador,
planificación); cuando el voraz se equivoca por poco. **Cuándo no:** si la evaluación parcial no se correlaciona
con el resultado final; ahí, recocido sobre soluciones completas.

> **Veredicto:** *beam search* es un voraz con memoria de `B` alternativas. Funciona tan bien como su función
> de evaluación.

---

## 6. 🧱 Aproximación con garantía

**Qué resuelve.** Problemas NP-difíciles en los que se quiere una solución **con un factor demostrado** respecto
al óptimo, no solo buena en la práctica.

**Qué garantiza.** Cobertura de vértices: 2-aproximación con un emparejamiento maximal (§2). Viajante métrico
(distancias que cumplen la desigualdad triangular): 2-aproximación recorriendo el árbol de expansión mínima en
preorden, y 1,5 con Christofides. Cobertura de conjuntos: el voraz que elige el conjunto que cubre más
elementos nuevos está a un factor `Hₙ ≈ ln n`, y no se puede mejorar mucho salvo que P = NP.

**Cuánto.** Polinómico: el emparejamiento maximal es lineal; el árbol mínimo, `O(E log V)`.

**Cómo reconocerlo.** «Demuestra que tu solución está a un factor del óptimo»; problemas de cobertura y de
recorridos en entrevistas de diseño de algoritmos.

**Si no te la sabes.** Un voraz sin garantía, mejorado con búsqueda local. Con el grafo de juguete `G`, el
emparejamiento maximal en el orden de las aristas da una cobertura de 6 vértices, y la óptima tiene 3
(`B, C, F`): justo el factor 2.

**Dónde está entera.** Kleinberg y Tardos, cap. 11; Cormen, Leiserson, Rivest y Stein, cap. 35.

---

## 7. ⏱️ La tabla de costes

| Técnica | Coste | Garantía | Lo que la tabla no dice |
|---|---|---|---|
| Voraz | Normalmente `O(n log n)` | Ninguna (salvo pruebas concretas) | Es el punto de partida de los demás |
| Búsqueda local | Pasadas de `O(vecindad)` | Óptimo local | Se queda en el primer valle |
| Recocido simulado | El presupuesto que se le dé | Ninguna en tiempo finito | La temperatura decide casi todo |
| *Beam search* | `T · B · jugadas` | Ninguna | Depende de la evaluación parcial |
| 2-aproximación de cobertura | `O(V + E)` | `≤ 2 · OPT` | En la práctica suele quedar mejor que 2 |

---

## 8. 🧭 Cómo se elige

```text
¿Hay un exacto que entra en el tiempo? → el exacto
¿Hace falta un factor demostrado? → algoritmo de aproximación
¿Solución completa fácil de modificar y de evaluar? → búsqueda local, y recocido si se atasca
¿Decisiones por turnos con buena evaluación parcial? → beam search
¿Concurso de heurísticos? → voraz para empezar, recocido o beam, y todo el tiempo disponible
```

> **Regla de entrevista:** ante un problema NP-difícil, nombra las tres salidas: «exacto si `n` es pequeño,
> aproximación si necesito una garantía, heurística si necesito algo bueno ya».

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Tu puntuación es…», sin respuesta correcta única | Heurística | Concurso de heurísticos |
| Viajante, asignación, calendario con `n` de cientos o miles | Recocido o búsqueda local | El exacto no entra |
| Juego de un jugador por turnos con puntuación | *Beam search* | Evaluación por turno |
| «Demuestra que estás a un factor del óptimo» | Aproximación | Garantía demostrable |
| Límite de tiempo por turno (CodinGame) | Heurística con reloj | Mejor respuesta en el tiempo disponible |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si no es óptimo, no sirve» | En problemas NP-difíciles, una solución a un 5 % del óptimo en un segundo es lo que se usa |
| «La búsqueda local encuentra el óptimo» | Encuentra un óptimo local; puede estar lejos del global |
| «El recocido funciona con cualquier temperatura» | Con `T` demasiado alta es un paseo al azar; demasiado baja, una búsqueda local |
| «Para el recocido hay que recalcular el coste entero» | Se evalúa el cambio `Δ`, normalmente en `O(1)` |
| «Una 2-aproximación da el doble del óptimo» | Da **como mucho** el doble; a menudo bastante menos |
| «*Beam search* con `B` grande es exhaustiva» | Solo con `B` infinito; con `B` finito puede descartar el camino óptimo |

---

## 📚 Para profundizar

- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 13: algoritmos
  heurísticos y aproximados. *Lectura troncal.*
- **Libro** — Russell y Norvig, *Artificial Intelligence: A Modern Approach*, 4.ª ed. (Pearson, 2020), cap. 4:
  búsqueda local, recocido simulado y *beam search*. *Lectura troncal.*
- **Libro** — Kleinberg y Tardos, *Algorithm Design* (Addison-Wesley, 2005), caps. 11 (aproximación) y 12
  (búsqueda local). *Lectura troncal.*
- **Artículo** — Kirkpatrick, Gelatt y Vecchi, «Optimization by simulated annealing», *Science* 220(4598),
  1983.

---

## 🧠 Preguntas

1. ¿Qué es un óptimo local? 🟢
2. ¿Qué hace un movimiento 2-opt en el problema del viajante? 🟢
3. ¿Qué garantiza una `α`-aproximación? 🟢
4. ¿Qué diferencia hay entre búsqueda local y recocido simulado? 🟡
5. ¿Qué diferencia hay entre *beam search* y un voraz? 🟡
6. ¿Qué pasa si la temperatura del recocido es demasiado alta o demasiado baja? 🟡
7. ¿Por qué el recocido evalúa `Δ` y no el coste entero de cada vecino? 🟠
8. ¿Qué cambia entre C++, Java y Python para un recocido con un límite de dos segundos? 🟠
9. ¿Por qué el recocido puede salir de un óptimo local y la búsqueda local no? 🟠
10. «Si no es óptimo, no sirve.» ¿Qué respondes? 🟠
11. Demuestra que el emparejamiento maximal da una 2-aproximación de la cobertura de vértices. 🔴
12. Diseña una heurística para asignar 1 000 turnos a 50 empleados minimizando los turnos seguidos de cada uno,
    y di cómo evaluarías un cambio en `O(1)`. 🔴

---

## 🧩 Problemas propios

### La cobertura del emparejamiento

**Nivel:** 🟡 · **Formato:** programa completo.

Aplica la 2-aproximación de la cobertura de vértices recorriendo las aristas en el orden de la entrada: si los
dos extremos de una arista están fuera de la cobertura, se meten los dos. Imprime el tamaño de la cobertura y
sus vértices en orden creciente.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con los extremos de cada arista (de `1` a `n`).
- **Salida.** Una línea con el tamaño y otra con los vértices.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `0 ≤ m ≤ 2·10⁵`.

```text
Entrada         Salida
4 3             4
1 2             1 2 3 4
2 3
3 4

Entrada         Salida
4 3             2
1 2             1 2
1 3
1 4
```

**Pista 1:** ¿qué necesitas recordar de cada vértice para decidir, al leer una arista, si la tomas?

### Mejora por 2-opt

**Nivel:** 🟠 · **Formato:** programa completo.

Se recorren `n` puntos en el orden de la entrada (y se vuelve al primero). Aplica 2-opt de esta forma exacta:
recorre `i` de `0` a `n − 2` y, para cada `i`, `j` de `i + 2` a `n − 1` (saltando `i = 0, j = n − 1`); si cambiar
las aristas `(tᵢ, tᵢ₊₁)` y `(tⱼ, tⱼ₊₁)` por `(tᵢ, tⱼ)` y `(tᵢ₊₁, tⱼ₊₁)` acorta el recorrido en más de `10⁻⁹`,
invierte el tramo `tᵢ₊₁ … tⱼ` y vuelve a empezar desde `i = 0`. Cuando ningún cambio mejore, imprime la longitud
con 6 decimales.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `x` e `y`.
- **Salida.** Un real.
- **Restricciones.** `4 ≤ n ≤ 200`; coordenadas enteras con `|·| ≤ 10⁴`.

```text
Entrada         Salida
5               8.828427
0 0
2 2
2 0
0 2
1 3

Entrada         Salida
4               0.000000
0 0
0 0
0 0
0 0
```

**Pista 1:** ¿qué cuatro distancias cambian al invertir un tramo, y por qué no hace falta recalcular las demás?

---

## 🧩 Práctica externa

> 💡 **Truco.** En un concurso de heurísticos, envía en la primera hora una solución voraz que puntúe, y mejora
> después. Guarda la puntuación de cada versión en local con varias semillas: una mejora que solo sale con una
> semilla no es una mejora. Si una IA te ayuda, que sea a montar ese banco de pruebas
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

Las bases no tienen problemas de heurísticos: no hay una respuesta única que comprobar. Los niveles miden lo
difícil que es puntuar bien, no aprobar.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Code vs Zombies](https://www.codingame.com/multiplayer/optimization/code-vs-zombies) | CodinGame | 🟠 | Simulación y búsqueda aleatoria | Si puedes simular el turno entero, ¿qué ganas probando muchas secuencias de movimientos al azar? |
| [ ] | [Search Race](https://www.codingame.com/multiplayer/optimization/search-race) | CodinGame | 🟠 | Simulación y búsqueda por turnos | ¿Qué evaluación de un estado intermedio predice bien el tiempo que falta? |
| [ ] | [Mars Lander](https://www.codingame.com/multiplayer/optimization/mars-lander) | CodinGame | 🟠 | Búsqueda sobre controles | Si una secuencia de ángulos y potencias se puede simular, ¿qué haces con las que casi aterrizan? |
| [ ] | [Walking on Tiles](https://atcoder.jp/contests/ahc002/tasks/ahc002_a) | AtCoder Heuristic Contest | 🟠 | Camino largo con recocido o *beam* | Si partes de un camino voraz, ¿qué movimiento local lo alarga sin pisar dos veces la misma baldosa? |
| [ ] | [Patrolling](https://atcoder.jp/contests/ahc005/tasks/ahc005_a) | AtCoder Heuristic Contest | 🟠 | Viajante sobre puntos clave | Si eliges pocos puntos desde los que se ven todas las calles, ¿qué problema clásico queda? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [SameGame](https://www.codingame.com/multiplayer/optimization/samegame) | CodinGame | 🔴 | *Beam search* | ¿Qué evaluación de un tablero a medio jugar mide bien lo que aún se puede sacar? |
| [ ] | [AtCoder Ad](https://atcoder.jp/contests/ahc001/tasks/ahc001_a) | AtCoder Heuristic Contest | 🔴 | Recocido sobre rectángulos | Si empiezas con rectángulos de 1 × 1, ¿qué movimiento los agranda sin solaparlos? |
| [ ] | [Shortest Path Queries](https://atcoder.jp/contests/ahc003/tasks/ahc003_a) | AtCoder Heuristic Contest | 🔴 | Estimación en línea | Con cada camino devuelves un coste observado: ¿cómo repartes ese coste entre las aristas que usaste? |

---

## ✅ Criterio de dominio

- Explicar óptimo local, el recocido y la temperatura, y *beam search*, con su coste.
- Escribir el recocido para el viajante en C++ sin mirar, evaluando `Δ` en `O(1)`.
- Demostrar la 2-aproximación de la cobertura de vértices.
- Puntuar en Code vs Zombies y en Walking on Tiles con una versión que mejore a la voraz.

---

**Anterior:** [`20/04` — El estilo de las pruebas de empresa](04-el-estilo-de-las-pruebas-de-empresa.md) · **Siguiente:** [`20/06` — Simulación](06-simulacion.md) ·
**Relacionado:** [`10/06` — Juegos y búsqueda adversarial](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md).
