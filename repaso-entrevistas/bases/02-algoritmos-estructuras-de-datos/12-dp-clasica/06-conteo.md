# 06 — Conteo con DP

> Contar con programación dinámica —caminos, palabras, subconjuntos, particiones— sin contar dos veces
> lo mismo ni dejarse nada, con el módulo en cada paso. Por qué contar **no** es optimizar cambiando
> `max` por `+`, y las particiones de un entero como caso de estudio.
>
> **Niveles:** conteo [A] · particiones [B].
>
> **📚 Lectura troncal:** Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994),
> cap. 7; Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 6.
>
> **Asume leído:** [`12/03` — Mochilas](03-mochilas.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--conteo) · [4](#4--particiones) · [5](#5-️-la-tabla-de-costes) · [6](#6--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

¿Cuántas subsecuencias **distintas** tiene `aba`? Una DP que parece obvia —«para cada letra, o la tomo o
no: el número se duplica»— da `2³ − 1 = 7`. Son 6: `a`, `b`, `ab`, `aa`, `ba`, `aba`. La subsecuencia `a`
se forma de dos maneras (con la primera `a` o con la tercera), y la DP la contó dos veces.

La versión de **optimización** del mismo problema («la subsecuencia más larga con tal propiedad») no tiene
este fallo: el máximo de un conjunto no cambia si un elemento aparece dos veces. El **conteo** sí cambia.
Por eso contar con DP exige algo que optimizar no exige: que **cada objeto corresponda exactamente a un
camino** en el grafo de estados.

> 🧠 **Modelo mental.** En una DP de conteo, la pregunta de diseño es «¿de cuántas maneras distintas puede
> la DP construir el mismo objeto?». La respuesta tiene que ser una. Si es más, se cuenta de más; si es
> cero para algún objeto, de menos.

Y la otra mitad del oficio: los números crecen exponencialmente y desbordan cualquier tipo enseguida, así
que se trabaja **módulo** un primo (casi siempre `10⁹ + 7`), reduciendo en cada suma y en cada producto
([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)).

---

## 2. 📐 La teoría

**Regla de la suma y regla del producto.** Si los objetos se parten en clases **disjuntas**, el total es
la suma de las cuentas de cada clase. Si un objeto se forma con una elección de `A` **y luego** una de `B`
independientes, el total es el producto. Una DP de conteo es la regla de la suma aplicada a la última
decisión: `cuenta(estado) = Σ cuenta(estado anterior)` sobre las transiciones.

**Teorema (correspondencia).** Una DP de conteo da el número correcto si y solo si existe una
**biyección** entre los objetos que se quieren contar y los caminos del grafo de estados desde los casos
base hasta el estado respuesta.

Las dos formas de romperla:

```text
dos caminos para el mismo objeto      → cuenta de más   (subsecuencias de «aba»; 1+2 y 2+1 en combinaciones)
un objeto sin camino                  → cuenta de menos (un caso base olvidado; un estado inalcanzable)
```

Las técnicas para conseguir un camino único son siempre del mismo tipo: **fijar un orden canónico** (las
monedas en orden, `12/03`), **fijar la última decisión** («el último elemento es…»), o **restar lo
repetido** (el último uso de cada letra, en las subsecuencias distintas).

**El módulo.** Con `p = 10⁹ + 7`, `(a + b) mod p` y `(a · b) mod p` se calculan reduciendo cada operando:
la DP entera se hace en `ℤ/pℤ`. Con dos valores menores que `p`, la suma cabe en 32 bits con signo justo
(`2·10⁹ < 2³¹`) y el producto necesita 64 bits (`10¹⁸ < 2⁶³`). Las restas pueden dar negativos en C++ y
Java: se suma `p` antes de reducir. Dividir exige el inverso modular ([`17/03`](../17-matematica/03-aritmetica-modular.md)).

---

## 3. 🧱 Conteo

**Qué es.** Una DP cuyo valor es un número de objetos: caminos, palabras, subconjuntos, formas. El estado
lleva lo que hace falta para que la siguiente decisión sea legal, y la transición **suma** las cuentas de
los estados de los que se puede venir.

**Por qué es correcto.** Por la regla de la suma y la correspondencia de §2: si los estados predecesores
parten los objetos en clases disjuntas (según la última decisión), la suma cuenta cada objeto una vez.

**Cómo va**, las palabras de longitud `n` con las letras `a`, `b`, `c` en las que no aparecen `aa` ni `bc`.
El estado es la **última letra**, porque es lo único que decide qué puede venir después:

```text
n                 1    2    3    4    5
acaban en a       1    2    5    11   25      (después de b o c)
acaban en b       1    3    7    16   36      (después de a, b o c)
acaban en c       1    2    4    9    20      (después de a o c)
total             3    7    16   36   81
```

**Cuánto.** `n` pasos por `L²` transiciones con un alfabeto de `L` letras: `Θ(n · L²)`. Con `n` hasta
`10¹⁸`, la misma transición como matriz y exponenciación rápida ([`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md)).

**La plantilla**, palabras de longitud `n` con transiciones permitidas `allowed[p][c]`:

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]. Θ(n · L²).
long long countWords(long long n, const std::vector<std::vector<bool>>& allowed) {
    int L = (int)allowed.size();
    std::vector<long long> cur(L, 1);                          // longitud 1: una por letra
    for (long long step = 1; step < n; step++) {
        std::vector<long long> nxt(L, 0);
        for (int p = 0; p < L; p++)
            for (int c = 0; c < L; c++)
                if (allowed[p][c]) nxt[c] = (nxt[c] + cur[p]) % MOD;
        cur = nxt;
    }
    long long total = 0;
    for (long long x : cur) total = (total + x) % MOD;
    return total;
}
```

```java
static final long MOD = 1_000_000_007L;

// Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]. Θ(n · L²).
static long countWords(int n, boolean[][] allowed) {
    int L = allowed.length;
    long[] cur = new long[L];
    java.util.Arrays.fill(cur, 1);
    for (int step = 1; step < n; step++) {
        long[] nxt = new long[L];
        for (int p = 0; p < L; p++)
            for (int c = 0; c < L; c++)
                if (allowed[p][c]) nxt[c] = (nxt[c] + cur[p]) % MOD;
        cur = nxt;
    }
    long total = 0;
    for (long x : cur) total = (total + x) % MOD;
    return total;
}
```

```python
MOD = 1_000_000_007

def count_words(n, allowed):
    """Palabras de longitud n (n ≥ 1) en las que cada par consecutivo (p, c) cumple allowed[p][c]."""
    L = len(allowed)
    cur = [1] * L
    for _ in range(n - 1):
        cur = [sum(cur[p] for p in range(L) if allowed[p][c]) % MOD for c in range(L)]
    return sum(cur) % MOD
```

- **El estado es la última letra** porque la restricción solo mira pares consecutivos; si mirara tríos, el
  estado serían las dos últimas.
- **`% MOD` en cada suma**: con `L` sumandos menores que `MOD`, la suma sin reducir cabe en 64 bits, pero
  reducir siempre es la costumbre que evita sorpresas.
- **En Python** los enteros no desbordan, pero los números enormes se vuelven lentos: se reduce igual.

### De la versión ingenua a la buena

**El problema.** ¿Cuántos subconjuntos de `n ≤ 10⁵` números tienen suma divisible por `k ≤ 1 000`? Con
`[5, 2, 9, 1, 5, 6]` y `k = 3`, son 20 (contando el vacío).

**La versión ingenua:**

```java
// Correcta: recorre los 2ⁿ subconjuntos. Θ(2ⁿ · n).
static long countDivisible(int[] a, int k) {
    long count = 0;
    for (long mask = 0; mask < (1L << a.length); mask++) {
        long sum = 0;
        for (int i = 0; i < a.length; i++) if ((mask >> i & 1) == 1) sum += a[i];
        if (sum % k == 0) count++;
    }
    return count;
}
```

> «No me hace falta la suma, solo su resto módulo `k`: hay `k` restos posibles. Para cada número, cada
> subconjunto anterior se queda como estaba o lo incluye, y su resto pasa de `r` a `(r + a) mod k`. Cada
> subconjunto tiene exactamente un camino: la secuencia de decisiones tomar/no tomar.»

**El camino a la buena.** `cnt[r]` = subconjuntos de los procesados con resto `r`; para cada número,
`nuevo[r] = cnt[r] + cnt[(r − a) mod k]`, módulo `10⁹ + 7`. `Θ(n · k)` = `10⁸`.

**Cuándo sí**: «de cuántas formas», «cuántos caminos / palabras / subconjuntos», con módulo en el enunciado.
**Cuándo no**: si existe una fórmula cerrada (combinatoria de [`17/05`](../17-matematica/05-combinatoria.md)), la DP es ceremonia; si `n` es
gigantesco y la transición es lineal y fija, potencia de matrices (`13/06`).

> **Veredicto:** contar con DP es sumar sobre la última decisión, con el estado justo para que cada objeto
> tenga un único camino. Antes de escribir, comprueba esa unicidad con un ejemplo de dos elementos iguales.

---

## 4. 🧱 Particiones

**Qué es.** Las particiones de un entero `n`: las formas de escribirlo como suma de enteros positivos **sin
importar el orden** (`4 = 3 + 1 = 2 + 2 = 2 + 1 + 1 = 1 + 1 + 1 + 1`, y `4` mismo: `p(4) = 5`).

**Por qué es correcto** (enunciado y una frase). Contar particiones es contar combinaciones de «monedas» de
valores `1, 2, …, n`: con las partes por fuera en orden creciente, cada partición se forma una sola vez
(`12/03`). Variantes: partes **distintas** (cada parte una vez: bucle descendente, como la 0/1), partes
**impares**, o a lo sumo `m` partes (`p(n, m) = p(n, m − 1) + p(n − m, m)`, por la conjugación de los
diagramas de Ferrers).

**Cómo va:**

```text
n               0  1  2  3  4  5  6   7   8   9   10
p(n)            1  1  2  3  5  7  11  15  22  30  42
partes distintas 1 1  1  2  2  3  4   5   6   8   10
```

**Cuánto.** `Θ(n²)` con la DP de monedas; `Θ(n√n)` con el teorema pentagonal de Euler, que expresa `p(n)`
como una suma alternada de `p(n − k(3k − 1)/2)`.

**La plantilla**, `p(0..n)` y las de partes distintas, módulo `10⁹ + 7`:

```cpp
#include <vector>

// p[s] = particiones de s en partes positivas (orden indiferente). Θ(n²).
std::vector<long long> partitions(int n, bool distinct) {
    const long long MOD = 1'000'000'007;
    std::vector<long long> p(n + 1, 0);
    p[0] = 1;
    for (int part = 1; part <= n; part++) {
        if (distinct)                                           // cada parte, una vez: descendente
            for (int s = n; s >= part; s--) p[s] = (p[s] + p[s - part]) % MOD;
        else                                                    // repetible: ascendente
            for (int s = part; s <= n; s++) p[s] = (p[s] + p[s - part]) % MOD;
    }
    return p;
}
```

```java
// p[s] = particiones de s en partes positivas (orden indiferente). Θ(n²).
static long[] partitions(int n, boolean distinct) {
    final long MOD = 1_000_000_007L;
    long[] p = new long[n + 1];
    p[0] = 1;
    for (int part = 1; part <= n; part++) {
        if (distinct) for (int s = n; s >= part; s--) p[s] = (p[s] + p[s - part]) % MOD;
        else for (int s = part; s <= n; s++) p[s] = (p[s] + p[s - part]) % MOD;
    }
    return p;
}
```

- **Las partes por fuera** dan particiones (sin orden); con las sumas por fuera saldrían las
  **composiciones** (`2ⁿ⁻¹` de `n`), que sí distinguen el orden.
- **El sentido del bucle** distingue partes repetibles (ascendente) de distintas (descendente): es la
  mochila ilimitada frente a la 0/1 de `12/03`.
- **`p(100) = 190 569 292`** cabe sin módulo; `p(1000)` tiene 32 cifras.

**Cuándo sí**: «de cuántas formas se escribe `n` como suma» con orden indiferente, con restricciones sobre
las partes. **Cuándo no**: si el orden importa (composiciones), es la otra anidación; si `n` es enorme
(`10⁶`), el teorema pentagonal o funciones generadoras ([`17/11`](../17-matematica/11-funciones-generadoras.md)).

> **Veredicto:** las particiones son el cambio de monedas con monedas `1..n`. El orden de los bucles
> decide particiones o composiciones, y el sentido, partes repetibles o distintas.

---

## 5. ⏱️ La tabla de costes

| Problema | Tiempo | Lo que la tabla no dice |
|---|---|---|
| Palabras con transiciones | `Θ(n · L²)` | Con `n` gigante, matriz y exponenciación en `Θ(L³ log n)` |
| Subconjuntos con resto | `Θ(n · k)` | El estado es el resto, no la suma |
| Particiones de `n` | `Θ(n²)` | `Θ(n√n)` con el teorema pentagonal |
| Subsecuencias distintas | `Θ(n · σ)` o `Θ(n)` | Hay que restar lo contado con el último uso de cada letra |

---

## 6. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «De cuántas formas», «módulo `10⁹ + 7`» | DP de conteo | El módulo delata que la cuenta es enorme |
| «Palabras / sucesiones de longitud `n` con reglas entre vecinos» | Estado = la última letra (o las últimas) | La regla solo mira atrás |
| «Subconjuntos cuya suma es divisible por `k`» | Estado = el resto | Solo importa el resto |
| «Escribir `n` como suma», «el orden no importa» | Particiones | Partes por fuera |
| «Distintas», «sin repetir» en un conteo | Cuidado con la doble cuenta | Fijar un orden o restar lo repetido |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Contar es como optimizar, cambiando `max` por `+`» | Contar exige un camino único por objeto; el máximo tolera duplicados y la suma no |
| «Reduzco el módulo al final» | Se reduce en cada operación; al final ya desbordó |
| «`(a − b) % MOD` es no negativo» | En C++ y Java puede ser negativo: `(a − b + MOD) % MOD` |
| «Particiones y composiciones son lo mismo» | Las particiones ignoran el orden; las composiciones no: `p(4) = 5`, composiciones de 4: 8 |
| «`a * b % MOD` en `int` está bien» | El producto de dos valores de `10⁹` necesita 64 bits |
| «Divido por 2 al final para no contar dos veces» | Con módulo, se multiplica por el inverso de 2 (`17/03`) |

---

## 📚 Para profundizar

- **Libro** — Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994), cap. 7:
  funciones generadoras y particiones. *Lectura troncal.*
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 6: la
  programación dinámica de conteo. *Lectura troncal.*
- **Libro** — Erickson, *Algorithms* (2019, libre del autor), cap. 3: el diseño del estado.
- **Referencia** — USACO Guide, [*Combinatorics*](https://usaco.guide/gold/combo): conteo con módulo.

---

## 🧠 Preguntas

1. ¿Qué dicen la regla de la suma y la del producto, y cuál aplica una DP de conteo en cada transición? 🟢
2. ¿Por qué se reduce el módulo en cada operación y no al final? 🟢
3. ¿Qué es una partición de `n` y cuánto vale `p(5)`? 🟢
4. ¿Por qué contar no es optimizar cambiando `max` por `+`? Da el ejemplo. 🟡
5. ¿Qué distingue particiones de composiciones en el código? 🟡
6. ¿Qué estado usas para contar palabras con una regla sobre letras consecutivas, y cuál si la regla mira tres letras? 🟡
7. Compara cómo haces `(a − b) mod p` y `(a · b) mod p` en C++, Java, Python y JavaScript. 🟡
8. Enuncia la condición de correspondencia que hace correcta una DP de conteo, y las dos formas de romperla. 🟠
9. ¿Cómo cuentas subconjuntos con suma divisible por `k` sin recorrerlos, y por qué cada uno se cuenta una vez? 🟠
10. ¿Cómo divides por 2 una cuenta calculada módulo `10⁹ + 7`? 🟠
11. ¿Qué cambia entre contar particiones en partes distintas y en partes repetibles? 🟠
12. Diseña la DP que cuenta las subsecuencias **distintas** de una cadena y explica qué resta y por qué. 🔴
13. Tu DP de conteo da 9 donde esperabas 4. ¿Cuál es la primera hipótesis y cómo la compruebas? 🔴

---

## 🧩 Problemas propios

### Sin tres iguales

**Nivel:** 🟢 · **Formato:** programa completo.

¿Cuántas cadenas de longitud `n` sobre un alfabeto de `k` letras no tienen tres letras iguales seguidas?
Imprime el resultado módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n` y `k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `1 ≤ k ≤ 10⁹`.

```text
Entrada     Salida
5 2         16

Entrada     Salida
3 3         24

Entrada     Salida
1 5         5
```

**Pista 1:** para decidir la siguiente letra, ¿qué necesitas saber del final de la cadena?

🔥 **Para el geek — en JavaScript:** `(k − 1) · cuenta` con valores cerca de `10⁹` pasa de `2⁵³` y pierde
precisión sin avisar; hace falta `BigInt` o partir la multiplicación.

### Partes distintas

**Nivel:** 🟡 · **Formato:** programa completo.

¿De cuántas formas se escribe `n` como suma de enteros positivos **distintos**, sin importar el orden?
Imprime el resultado módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 5 000`.

```text
Entrada     Salida
10          10

Entrada     Salida
100         444793
```

**Pista 1:** si cada parte se puede usar una sola vez, ¿a qué mochila se parece?

### Pocos sumandos

**Nivel:** 🟠 · **Formato:** programa completo.

¿De cuántas formas se escribe `n` como suma de **a lo sumo** `m` enteros positivos, sin importar el orden?
Imprime el resultado módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n` y `m`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n, m ≤ 5 000`.

```text
Entrada     Salida
10 3        14

Entrada     Salida
7 2         4
```

**Pista 1:** si una partición tiene exactamente `m` partes, ¿qué pasa si le restas 1 a cada una?

---

## 🧩 Práctica externa

Codility no tiene DP de conteo. La plataforma específica es CSES, cuya sección de DP es casi entera de
conteo con módulo.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Construct the Array](https://www.hackerrank.com/challenges/construct-the-array/problem) | HackerRank | 🟡 | Conteo con estado reducido | ¿Importa qué valor concreto tiene la penúltima posición, o solo si es igual a `x`? |
| [ ] | [Red John is Back](https://www.hackerrank.com/challenges/red-john-is-back/problem) | HackerRank | 🟡 | Conteo lineal y primos | ¿Cómo puede acabar la pared por la derecha? |
| [ ] | [Number of Dice Rolls With Target Sum](https://leetcode.com/problems/number-of-dice-rolls-with-target-sum/) | LeetCode | 🟡 | Conteo por dado y suma | ¿Qué sacó el último dado? |
| [ ] | [Knight Dialer](https://leetcode.com/problems/knight-dialer/) | LeetCode | 🟡 | Conteo con estado = la última tecla | ¿Desde qué teclas se llega a cada una? |
| [ ] | [Domino and Tromino Tiling](https://leetcode.com/problems/domino-and-tromino-tiling/) | LeetCode | 🟡 | Conteo con estados de borde | ¿Cómo puede quedar el borde derecho de un tablero a medio cubrir? |
| [ ] | [Count Ways To Build Good Strings](https://leetcode.com/problems/count-ways-to-build-good-strings/) | LeetCode | 🟡 | Conteo por longitud | ¿Con qué bloque acaba la cadena? |
| [ ] | [Coin Combinations I](https://cses.fi/problemset/task/1635) | CSES | 🟢 | Contar sucesiones | ¿Importa aquí el orden de las monedas? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Array Description](https://cses.fi/problemset/task/1746) | CSES | 🟡 | Conteo con estado = el último valor | Si sabes el valor de la posición anterior, ¿qué valores puede tener la actual? |
| [ ] | [Count Vowels Permutation](https://leetcode.com/problems/count-vowels-permutation/) | LeetCode | 🟠 | Palabras con transiciones | ¿Qué vocal puede ir antes de cada una? |
| [ ] | [Counting Towers](https://cses.fi/problemset/task/2413) | CSES | 🟠 | Conteo con dos estados por altura | ¿La fila de arriba está unida o partida en dos? |
| [ ] | [Number of Ways to Stay in the Same Place After Some Steps](https://leetcode.com/problems/number-of-ways-to-stay-in-the-same-place-after-some-steps/) | LeetCode | 🟠 | Conteo con estado acotado | ¿Puedes alejarte más de `pasos/2` posiciones y volver? |

---

## ✅ Criterio de dominio

- Escribir una DP de conteo con módulo en cada operación y la resta segura, sin mirar.
- Explicar con un ejemplo por qué contar no es optimizar con `+`, y cómo se garantiza un camino único.
- Contar particiones y particiones en partes distintas eligiendo el sentido del bucle.
- Resolver Knight Dialer y Domino and Tromino Tiling sin pista 2.

---

**Anterior:** [`12/05` — DP en rejillas y de intervalos](05-rejillas-e-intervalos.md) · **Siguiente:** [`12/07` — Simulación](07-simulacion.md) ·
**Relacionado:** [`17/05` — Combinatoria](../17-matematica/05-combinatoria.md); [`12/03` — Mochilas](03-mochilas.md).
