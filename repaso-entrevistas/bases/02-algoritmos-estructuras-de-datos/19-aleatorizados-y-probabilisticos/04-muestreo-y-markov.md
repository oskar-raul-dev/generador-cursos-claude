# 04 — Muestreo y cadenas de Markov

> Barajar sin sesgo con Fisher-Yates, y la versión que escribe todo el mundo y está sesgada; elegir `k`
> elementos uniformes de un flujo que no cabe en memoria y cuya longitud no se conoce, con *reservoir
> sampling*; y lo justo de cadenas de Markov para entender la distribución estacionaria, MCMC y la búsqueda
> de Monte Carlo en árboles.
>
> **Niveles:** Fisher-Yates [A] · *reservoir* [B] · cadenas de Markov [C] · MCMC y MCTS [C].
>
> **📚 Lectura troncal:** Knuth, *The Art of Computer Programming*, Vol. 2, 3.ª ed. (Addison-Wesley, 1997),
> §3.4.2; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 10; Blum, Hopcroft y
> Kannan, *Foundations of Data Science* (Cambridge, 2020), cap. 4.
>
> **Asume leído:** [`19/01` — Las Vegas y Monte Carlo](01-las-vegas-y-monte-carlo.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--fisher-yates) · [4](#4--reservoir) · [5](#5--cadenas-de-markov) · [6](#6--mcmc-y-mcts) · [7](#7-️-la-tabla-de-costes) · [8](#8--cómo-se-elige) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Una aplicación de música baraja una lista. El código que sale primero recorre la lista e intercambia cada
canción con una posición al azar de **toda** la lista. Parece justo, y no lo es: con tres canciones, algunos
órdenes salen 5 veces de cada 27 y otros 4. Fisher-Yates, que intercambia cada posición con una al azar de
las que **quedan**, da los 6 órdenes con la misma probabilidad, en tiempo lineal.

El segundo problema es un flujo: llegan registros de *log* uno a uno, sin saber cuántos serán, y hay que
quedarse con 100 elegidos uniformemente al azar, con memoria para 100. El *reservoir sampling* lo hace en una
pasada.

> 🧠 **Modelo mental.** Un barajado uniforme es elegir al azar quién va en la última posición, después quién
> va en la penúltima entre los que quedan, y así. El *reservoir* es la misma idea al revés: cada recién
> llegado entra con la probabilidad justa para que todos los vistos tengan la misma.

Los ejemplos usan el arreglo de juguete `[5, 2, 9, 1, 5, 6]` y el grafo de juguete `G` de la guía.

---

## 2. 📐 La teoría

**Fisher-Yates.** Para `i` de `n − 1` a `1`, elegir `j` uniforme en `[0, i]` e intercambiar `a[i]` con
`a[j]`. Hay `n · (n − 1) · … · 2 = n!` secuencias de elecciones, todas equiprobables, y cada una produce una
permutación distinta: por tanto cada permutación sale con probabilidad `1/n!`.

**El barajado sesgado.** Intercambiar `a[i]` con `a[j]`, `j` uniforme en `[0, n − 1]`, para cada `i`: hay
`nⁿ` secuencias equiprobables. Para `n = 3`, `27` secuencias sobre `6` permutaciones: como 27 no es múltiplo
de 6, **no puede** ser uniforme. Las cuentas son `4, 5, 5, 5, 4, 4`.

**Reservoir sampling** (algoritmo R). Se guardan los `k` primeros. El elemento `i`-ésimo (`i > k`, contando
desde 1) entra con probabilidad `k/i`, sustituyendo a uno del depósito elegido al azar.

*Prueba por inducción.* Tras ver `i` elementos, cada uno está en el depósito con probabilidad `k/i`. Al llegar
el `(i + 1)`-ésimo, entra con probabilidad `k/(i + 1)`. Uno de los antiguos sigue si estaba
(`k/i`) y no lo echan: `1 − (k/(i + 1)) · (1/k) = i/(i + 1)`. Producto: `k/(i + 1)`.

**Cadenas de Markov.** Un proceso con estados y una matriz de transición `P`, donde `P[u][v]` es la
probabilidad de pasar de `u` a `v`, sin memoria del pasado. Una distribución `π` es **estacionaria** si
`π = πP`.

**Teorema (estacionaria).** Si la cadena es finita, irreducible (se puede llegar de todo estado a todo estado)
y aperiódica, tiene una única estacionaria `π` y, desde cualquier estado inicial, la distribución tras `t`
pasos converge a `π`. La fracción de tiempo que se pasa en `v` tiende a `π(v)` (basta irreducible).

**Paseo aleatorio en un grafo no dirigido.** Desde `v`, ir a un vecino uniforme: la estacionaria es
`π(v) = grado(v) / 2|E|`. En `G`: `A, C, D, F` tienen grado 2 y `B, E` grado 3, con `|E| = 7`:
`π = (1/7, 3/14, 1/7, 1/7, 3/14, 1/7)`.

---

## 3. 🧱 Fisher-Yates

**Qué es.** Barajar un arreglo de forma uniforme, en el sitio, en `Θ(n)`.

**Por qué es correcto.** La biyección de §2 entre secuencias de elecciones (`n!`, equiprobables) y
permutaciones.

**Cómo va**, con `[5, 2, 9, 1, 5, 6]` y unas elecciones concretas de `j`:

```text
i = 5, j = 2:  [5, 2, 6, 1, 5, 9]     el 9 queda fijo al final
i = 4, j = 4:  [5, 2, 6, 1, 5, 9]     (se intercambia consigo mismo)
i = 3, j = 0:  [1, 2, 6, 5, 5, 9]
i = 2, j = 1:  [1, 6, 2, 5, 5, 9]
i = 1, j = 0:  [6, 1, 2, 5, 5, 9]
```

**Cuánto.** `Θ(n)` tiempo, `O(1)` memoria extra, `n − 1` números aleatorios.

**La plantilla:**

```cpp
#include <chrono>
#include <random>
#include <utility>
#include <vector>

void fisherYates(std::vector<int>& a, std::mt19937_64& rng) {
    for (int i = (int) a.size() - 1; i > 0; i--) {
        std::uniform_int_distribution<int> pick(0, i);     // j en [0, i], incluido i
        std::swap(a[i], a[pick(rng)]);
    }
}
// std::shuffle(a.begin(), a.end(), rng) hace lo mismo.
```

```java
static void fisherYates(int[] a, java.util.Random rng) {
    for (int i = a.length - 1; i > 0; i--) {
        int j = rng.nextInt(i + 1);                         // j en [0, i]
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }
}
// Collections.shuffle(list) hace lo mismo sobre una List.
```

```python
import random

def fisher_yates(a):
    for i in range(len(a) - 1, 0, -1):
        j = random.randint(0, i)                            # j en [0, i], incluido i
        a[i], a[j] = a[j], a[i]
# random.shuffle(a) hace lo mismo.
```

- **`[0, i]`, incluido `i`.** Sin la opción de quedarse quieto, sale el algoritmo de Sattolo, que solo genera
  permutaciones cíclicas.
- **El generador**: en C++, `uniform_int_distribution` evita el sesgo de `rng() % (i + 1)`; en Java,
  `nextInt(bound)` ya es uniforme; en Python, `randint` incluye los dos extremos.
- **La librería** lo trae en los tres: `std::shuffle`, `Collections.shuffle`, `random.shuffle`. Para barajar
  un `int[]` en Java hay que escribirlo (o pasar por una `List<Integer>`, con *boxing*).

### De la versión ingenua a la buena

**El problema.** Barajar `n = 10⁶` canciones de forma uniforme.

**La versión ingenua**, correcta y lenta:

```java
// Correcta: una clave aleatoria por elemento y ordenar por ella (las claves de 64 bits casi nunca empatan).
static int[] shuffleBySort(int[] a, java.util.Random rng) {
    long[][] keyed = new long[a.length][];
    for (int i = 0; i < a.length; i++) keyed[i] = new long[]{rng.nextLong(), a[i]};
    java.util.Arrays.sort(keyed, java.util.Comparator.comparingLong(p -> p[0]));
    int[] out = new int[a.length];
    for (int i = 0; i < a.length; i++) out[i] = (int) keyed[i][1];
    return out;
}
```

> «Esto es uniforme si las claves no empatan, pero ordena: `Θ(n log n)` y un objeto por elemento. No hace
> falta ordenar: basta con decidir, de atrás hacia delante, quién ocupa cada posición entre los que quedan.»

**El camino a la buena.** Fisher-Yates: `Θ(n)`, en el sitio, la plantilla de arriba.

**Cuándo sí:** barajar cualquier secuencia; elegir `k` de `n` sin repetición (las `k` primeras iteraciones);
generar permutaciones aleatorias para un *stress test* ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
**Cuándo no:** si los datos no caben en memoria o llegan en flujo: *reservoir*.

> **Veredicto:** barajar es Fisher-Yates o la función de la librería, nunca un intercambio con «cualquier
> posición». La diferencia entre `[0, i]` y `[0, n − 1]` es la diferencia entre uniforme y sesgado.

### Autopsia de un bug: el barajado sesgado

**El código que escribe todo el mundo:**

```java
static void naiveShuffle(int[] a, java.util.Random rng) {
    for (int i = 0; i < a.length; i++) {
        int j = rng.nextInt(a.length);                      // ← cualquier posición, no solo las que quedan
        int t = a[i]; a[i] = a[j]; a[j] = t;
    }
}
```

**Por qué parece correcto.** Cada elemento se mueve a una posición al azar, y a ojo los resultados se ven
mezclados; ningún ejemplo pequeño lo delata.

**La entrada que lo rompe.** `[1, 2, 3]`, contando todas las secuencias: `27` resultados equiprobables sobre
`6` órdenes. `(1,3,2)`, `(2,1,3)` y `(2,3,1)` salen 5 veces; `(1,2,3)`, `(3,1,2)` y `(3,2,1)`, 4. Como `27` no
es múltiplo de `6`, ningún reparto podría ser uniforme.

**El código correcto** recorre de atrás hacia delante con `j` en `[0, i]` (la plantilla).

**La generalización.** Un algoritmo aleatorizado uniforme sobre `N` resultados necesita un número de
secuencias equiprobables múltiplo de `N`. Si cuentas `nⁿ` secuencias para `n!` resultados, ya sabes que está
sesgado.

---

## 4. 🧱 *Reservoir*

**Qué es.** Elegir `k` elementos uniformes, sin repetición, de un flujo de longitud desconocida, en una
pasada y con memoria `O(k)`.

**Por qué es correcto.** La inducción de §2: tras `i` elementos, cada uno está con probabilidad `k/i`.

**Cómo va**, con `k = 2`, el flujo `5, 2, 9, 1, 5, 6` y unas tiradas concretas:

```text
5, 2      depósito [5, 2]                 (los k primeros)
9 (i=3)   j = 0 en [0, 3) < 2 → entra en 0      [9, 2]
1 (i=4)   j = 3 en [0, 4) ≥ 2 → no entra        [9, 2]
5 (i=5)   j = 1 en [0, 5) < 2 → entra en 1      [9, 5]
6 (i=6)   j = 4 en [0, 6) ≥ 2 → no entra        [9, 5]
```

**Cuánto.** `Θ(n)` tiempo, `O(k)` memoria, un número aleatorio por elemento. El algoritmo L de Li salta
directamente al siguiente elemento que entra: `O(k (1 + log(n/k)))` números aleatorios.

**La plantilla:**

```cpp
#include <random>
#include <vector>

// Muestra uniforme de k elementos de un flujo; next() devuelve false al terminar.
template <class Source>
std::vector<long long> reservoir(Source next, int k, std::mt19937_64& rng) {
    std::vector<long long> sample;
    long long x, seen = 0;
    while (next(x)) {
        seen++;
        if ((long long) sample.size() < k) { sample.push_back(x); continue; }
        std::uniform_int_distribution<long long> pick(0, seen - 1);
        long long j = pick(rng);
        if (j < k) sample[j] = x;                            // entra con probabilidad k/seen
    }
    return sample;
}
```

```java
static long[] reservoir(java.util.PrimitiveIterator.OfLong stream, int k, java.util.Random rng) {
    long[] sample = new long[k];
    long seen = 0;
    while (stream.hasNext()) {
        long x = stream.nextLong();
        seen++;
        if (seen <= k) { sample[(int) (seen - 1)] = x; continue; }
        long j = rng.nextLong(seen);                         // Java 17+: uniforme en [0, seen)
        if (j < k) sample[(int) j] = x;
    }
    return seen < k ? java.util.Arrays.copyOf(sample, (int) seen) : sample;
}
```

```python
import random

def reservoir(stream, k):
    sample = []
    for seen, x in enumerate(stream, start=1):
        if seen <= k:
            sample.append(x)
        else:
            j = random.randrange(seen)                       # uniforme en [0, seen)
            if j < k:
                sample[j] = x
    return sample
```

- **`seen` en 64 bits**: los flujos de *logs* pasan de `2³¹` sin esfuerzo.
- **`j < k` hace dos cosas a la vez**: decide si entra (probabilidad `k/seen`) y, si entra, a qué casilla (uniforme
  entre las `k`).
- **Con `k = 1`** es elegir un nodo al azar de una lista enlazada de longitud desconocida en una pasada.

**Cuándo sí:** muestras de flujos, de ficheros que no caben, de listas enlazadas sin recorrerlas dos veces;
muestreo distribuido (cada servidor su depósito, y se combinan ponderando por lo que vio cada uno). **Cuándo
no:** si se conoce `n` y los datos están en memoria, Fisher-Yates parcial (`k` iteraciones) es más simple.

> **Veredicto:** el *reservoir* resuelve «`k` al azar de algo que no sé cuánto mide» en una pasada: el
> elemento `i` entra con probabilidad `k/i`, y la inducción hace el resto.

---

## 5. 🧱 Cadenas de Markov

**Qué resuelve.** Modelar procesos sin memoria (un paseo aleatorio, un usuario que navega, una cola) y
calcular su comportamiento a largo plazo: la distribución estacionaria y el tiempo de mezcla.

**Qué garantiza.** El teorema de §2: con cadena finita, irreducible y aperiódica, `π` única y convergencia
desde cualquier inicio. En un paseo por un grafo no dirigido conexo, `π(v) ∝ grado(v)`. PageRank es la
estacionaria de un paseo por la web con «teletransporte», que fuerza la irreducibilidad y la aperiodicidad.

**Cuánto.** `π` resolviendo `π = πP` con `Σ π = 1` (Gauss, [`17/07`](../17-matematica/07-matrices-y-gauss.md)),
`O(n³)`; o iterando `π ← πP`, que converge al ritmo del segundo valor propio.

**Cómo reconocerlo.** «A largo plazo, ¿qué fracción del tiempo…?», «probabilidad de estar en el estado `v`
tras muchos pasos», esperanzas con estados que forman ciclos (la DP de
[`13/04`](../13-dp-avanzada/04-probabilidad-y-esperanza.md) solo vale sin ciclos).

**Si no te la sabes.** Simular el proceso muchas veces y medir (Monte Carlo); o plantear las ecuaciones de
esperanza y resolverlas con Gauss.

**Dónde está entera.** Blum, Hopcroft y Kannan, cap. 4; Mitzenmacher y Upfal, cap. 7.

---

## 6. 🧱 MCMC y MCTS

**Qué resuelve.** **MCMC** (*Markov Chain Monte Carlo*): muestrear de una distribución que solo se conoce
salvo una constante (en estadística bayesiana, física, optimización), construyendo una cadena cuya
estacionaria es esa distribución. **MCTS**: elegir jugadas con partidas aleatorias, que es de
[`10/06`](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md).

**Qué garantiza.** Metropolis-Hastings propone un movimiento y lo acepta con probabilidad
`min(1, π(y)/π(x))` (con propuestas simétricas): la cadena resultante tiene `π` como estacionaria, sin
conocer la constante de normalización. El recocido simulado es lo mismo con una «temperatura» que baja.

**Cuánto.** Por paso, el coste de proponer y evaluar; cuántos pasos hacen falta lo decide el tiempo de mezcla,
que puede ser enorme.

**Cómo reconocerlo.** «Muestrea configuraciones con probabilidad proporcional a…», optimización heurística
sin estructura (recocido), *bots* de juego con tiempo limitado (MCTS).

**Si no te la sabes.** Muestreo por rechazo (`19/01`) si la distribución está acotada y el espacio es pequeño;
búsqueda local con reinicios aleatorios.

**Dónde está entera.** Blum, Hopcroft y Kannan, cap. 4 (MCMC); Mitzenmacher y Upfal, cap. 11.

---

## 7. ⏱️ La tabla de costes

| Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Fisher-Yates | `Θ(n)` | `O(1)` extra | `j` en `[0, i]`: con `[0, n − 1]`, sesgado |
| Ordenar por claves aleatorias | `Θ(n log n)` | `Θ(n)` | Uniforme si no hay empates; más lento |
| *Reservoir* (algoritmo R) | `Θ(n)` | `O(k)` | Un aleatorio por elemento; el algoritmo L salta |
| Estacionaria por Gauss | `O(n³)` | `O(n²)` | Exacta; para cadenas grandes, iterar |
| MCMC | Pasos × coste del paso | El estado | El tiempo de mezcla decide si sirve |

---

## 8. 🧭 Cómo se elige

```text
¿Barajar en memoria? → Fisher-Yates o la de la librería
¿k al azar de n conocidos y en memoria? → k iteraciones de Fisher-Yates
¿k al azar de un flujo de longitud desconocida? → reservoir
¿Con pesos? → reservoir ponderado (claves u^{1/w}) o prefijos + binaria si está en memoria
¿Comportamiento a largo plazo de un proceso sin memoria? → estacionaria (Gauss o iterar)
```

> **Regla de entrevista:** si te piden barajar, di «Fisher-Yates, de atrás hacia delante, `j` en `[0, i]`»
> antes de escribir, y menciona por qué el intercambio con cualquier posición está sesgado.

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Baraja», «permutación aleatoria uniforme» | Fisher-Yates | `Θ(n)`, uniforme |
| «Nodo al azar de una lista enlazada», «una sola pasada» | *Reservoir* con `k = 1` | Longitud desconocida |
| «Muestra de `k` de un flujo» | *Reservoir* | Memoria `O(k)` |
| «Elige con probabilidad proporcional al peso» | Prefijos + binaria, o *reservoir* ponderado | Muestreo ponderado |
| «Fracción del tiempo a largo plazo» | Estacionaria | `π = πP` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Intercambiar con una posición al azar de todo el arreglo baraja bien» | `nⁿ` secuencias no se reparten por igual entre `n!` órdenes: sesgado |
| «`rng() % n` da un número uniforme» | Solo si `n` divide al rango del generador; si no, sesgo pequeño: `uniform_int_distribution` o `nextInt(n)` |
| «Para muestrear de un flujo hay que conocer su longitud» | El *reservoir* no la necesita |
| «Quitar la opción `j = i` no cambia nada» | Sale el algoritmo de Sattolo: solo permutaciones cíclicas |
| «Toda cadena de Markov converge a su estacionaria» | Hace falta irreducible y aperiódica; un paseo en un grafo bipartito oscila |
| «MCMC da muestras independientes» | Las muestras consecutivas están correladas; hay que esperar la mezcla |

---

## 📚 Para profundizar

- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 2, 3.ª ed. (Addison-Wesley, 1997), §3.4.2:
  barajado y muestreo, incluido el *reservoir*. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 10: algoritmos
  numéricos probabilistas y muestreo. *Lectura troncal.*
- **Libro** — Blum, Hopcroft y Kannan, *Foundations of Data Science* (Cambridge, 2020), cap. 4: paseos
  aleatorios, cadenas de Markov y MCMC. *Lectura troncal.*
- **Libro** — Medjedovic, Tahirovic y Dedovic, *Algorithms and Data Structures for Massive Datasets* (Manning,
  2022), cap. 7: muestreo de flujos.
- **Artículo** — Vitter, «Random sampling with a reservoir», *ACM Transactions on Mathematical Software*
  11(1), 1985.

---

## 🧠 Preguntas

1. ¿Qué hace Fisher-Yates y cuánto cuesta? 🟢
2. ¿Qué resuelve el *reservoir sampling*? 🟢
3. ¿Qué es la distribución estacionaria de una cadena de Markov? 🟢
4. ¿Qué diferencia hay entre elegir `j` en `[0, i]` y en `[0, n − 1]` al barajar? 🟡
5. ¿Qué diferencia hay entre Fisher-Yates y el algoritmo de Sattolo? 🟡
6. ¿Cuál es la estacionaria de un paseo aleatorio en un grafo no dirigido conexo? 🟡
7. ¿Qué cambia entre C++, Java y Python para obtener un entero uniforme en `[0, i]`? 🟠
8. ¿Cómo eliges un nodo al azar de una lista enlazada en una sola pasada? 🟠
9. ¿Por qué un paseo aleatorio en un grafo bipartito no converge a su estacionaria? 🟠
10. ¿Para qué sirve MCMC si ya se conoce la distribución salvo una constante? 🟠
11. Demuestra que el *reservoir sampling* deja cada elemento en el depósito con probabilidad `k/n`. 🔴
12. Demuestra que el barajado que intercambia cada posición con una de todo el arreglo no es uniforme para
    `n = 3`, y generaliza el argumento. 🔴

---

## 🧩 Problemas propios

### Barajado reproducible

**Nivel:** 🟢 · **Formato:** programa completo.

Para que un sorteo sea auditable, se usa un generador fijo: `x₀ = s` y `x_{t+1} = (1 103 515 245 · x_t + 12 345)
mod 2³¹`. Baraja el arreglo con Fisher-Yates recorriendo `i` de `n − 1` a `1`: en cada paso se calcula el
siguiente `x` y se usa `j = x mod (i + 1)`. Imprime el arreglo final.

- **Entrada.** Una línea con `n` y `s`. Una línea con los `n` valores.
- **Salida.** Una línea con el arreglo barajado.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `0 ≤ s < 2³¹`.

```text
Entrada         Salida
6 1             9 1 2 5 6 5
5 2 9 1 5 6

Entrada         Salida
3 42            2 3 1
1 2 3
```

**Pista 1:** ¿qué tipo necesitas para que `1 103 515 245 · x` no desborde, y en qué orden se recorren las
posiciones?

### El paseo del cartero

**Nivel:** 🟡 · **Formato:** programa completo.

Un cartero recorre una ciudad: desde cada esquina, sigue por una calle elegida al azar entre las que salen de
ella. A la larga, ¿qué fracción del tiempo pasa en cada esquina? Imprime una fracción irreducible por esquina.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con las dos esquinas de cada calle (de `1` a `n`).
  El grafo es conexo, sin bucles ni calles repetidas.
- **Salida.** `n` líneas con `p/q`.
- **Restricciones.** `2 ≤ n ≤ 10⁵`; `1 ≤ m ≤ 2·10⁵`.

```text
Entrada         Salida
3 2             1/4
1 2             1/2
2 3             1/4

Entrada         Salida
4 3             1/2
1 2             1/6
1 3             1/6
1 4             1/6
```

**Pista 1:** si dejas que el paseo dure muchísimo, ¿cuántas veces se recorre cada calle en cada sentido, y qué
dice eso de las visitas a una esquina con muchas calles?

### Muestra con pesos

**Nivel:** 🟠 · **Formato:** programa completo.

Llega un flujo de `n` elementos con pesos `wᵢ`. Para elegir `k` con probabilidad que favorece a los pesados,
cada elemento trae un número `uᵢ` en `(0, 1)` y su clave es `uᵢ^{1/wᵢ}`; la muestra son los `k` de mayor clave.
Imprime sus índices (desde 1) en orden creciente. No hay empates de clave.

- **Entrada.** Una línea con `n` y `k`. Después, `n` líneas con `wᵢ` (entero) y `uᵢ` (con 6 decimales).
- **Salida.** Una línea con `k` índices.
- **Restricciones.** `1 ≤ k ≤ n ≤ 10⁶`; `1 ≤ wᵢ ≤ 10⁶`; `k ≤ 1 000`.

```text
Entrada            Salida
4 2                2 4
1 0.500000
2 0.600000
4 0.300000
1 0.900000

Entrada            Salida
2 2                1 2
1000000 0.000001
1 0.999999
```

**Pista 1:** con `10⁶` elementos y `k ≤ 1 000`, ¿qué estructura guarda los `k` mejores vistos hasta ahora, y
cómo comparas claves sin calcular potencias de números muy pequeños?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de enviar un barajado o un muestreo, cuenta: ejecútalo un millón de veces sobre un caso
> de 3 elementos y comprueba que las frecuencias son iguales. Si una IA te ayuda, que sea a escribir ese
> contador ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Shuffle an Array](https://leetcode.com/problems/shuffle-an-array/) | LeetCode | 🟡 | Fisher-Yates | ¿Entre qué posiciones eliges la que va al final? |
| [ ] | [Linked List Random Node](https://leetcode.com/problems/linked-list-random-node/) | LeetCode | 🟡 | *Reservoir* con `k = 1` | Si no conoces la longitud, ¿con qué probabilidad debería quedarse el nodo `i`? |
| [ ] | [Random Pick Index](https://leetcode.com/problems/random-pick-index/) | LeetCode | 🟡 | *Reservoir* sobre los que coinciden | Entre las posiciones con el valor buscado, ¿cómo eliges una sin guardarlas todas? |
| [ ] | [Random Pick with Weight](https://leetcode.com/problems/random-pick-with-weight/) | LeetCode | 🟡 | Prefijos y binaria | Si pones los pesos uno detrás de otro en una recta, ¿dónde cae un punto al azar? |
| [ ] | [Random Point in Non-overlapping Rectangles](https://leetcode.com/problems/random-point-in-non-overlapping-rectangles/) | LeetCode | 🟡 | Ponderado por puntos | ¿Cuántos puntos enteros tiene cada rectángulo, y qué peso le das? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Random Flip Matrix](https://leetcode.com/problems/random-flip-matrix/) | LeetCode | 🟠 | Fisher-Yates virtual | Si la matriz fuera un arreglo y barajaras de forma perezosa, ¿qué necesitarías guardar? |
| [ ] | [Insert Delete GetRandom O(1) - Duplicates allowed](https://leetcode.com/problems/insert-delete-getrandom-o1-duplicates-allowed/) | LeetCode | 🔴 | Arreglo + mapa de posiciones | Para borrar en `O(1)` de un arreglo, ¿con qué elemento intercambias el que sale? |
| [ ] | [Random Pick with Blacklist](https://leetcode.com/problems/random-pick-with-blacklist/) | LeetCode | 🔴 | Remapeo | Si eliges al azar entre los `n − b` primeros (con `b` el tamaño de la lista negra), ¿adónde mandas los que caen en ella? |

---

## ✅ Criterio de dominio

- Escribir Fisher-Yates y el *reservoir* en los tres lenguajes sin mirar.
- Demostrar la uniformidad de los dos, y explicar con la cuenta `nⁿ / n!` por qué el barajado ingenuo está
  sesgado.
- Calcular la estacionaria de un paseo aleatorio en un grafo.
- Resolver Shuffle an Array, Linked List Random Node y Random Pick with Weight sin pista 2.

---

**Anterior:** [`19/03` — Estructuras probabilísticas](03-estructuras-probabilisticas.md) · **Siguiente:** [`19/05` — Estructuras espaciales](05-estructuras-espaciales.md) ·
**Relacionado:** [`10/06` — Juegos y búsqueda adversarial](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md).
