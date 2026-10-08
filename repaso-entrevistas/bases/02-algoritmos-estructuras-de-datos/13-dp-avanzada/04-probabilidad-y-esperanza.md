# 04 — DP de probabilidad y esperanza

> Dos formas de DP con azar: propagar **probabilidades** hacia delante (la distribución de la suma de
> unos dados, la probabilidad de estar en una casilla) y calcular **esperanzas** hacia atrás (cuántas
> tiradas faltan, en media, desde cada estado). Con la respuesta como fracción módulo un primo, y lo
> mínimo de linealidad de la esperanza.
>
> **Niveles:** DP de probabilidad [B] · esperanza hacia atrás [B].
>
> **📚 Lectura troncal:** Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017),
> cap. 2; Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 11.
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--dp-de-probabilidad) · [4](#4--esperanza-hacia-atrás) · [5](#5-️-la-tabla-de-costes) · [6](#6--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Se lanza un dado de seis caras y se avanza lo que sale, empezando en 0. ¿Cuántas tiradas hacen falta, en
media, para llegar o pasar de la casilla 10? Simular un millón de partidas da algo cerca de 3,3, pero no el
valor exacto que pide el juez, a veces como fracción módulo `10⁹ + 7`.

La DP lo calcula exacto: desde la casilla `i`, la tirada siguiente lleva a `i + 1, …, i + 6` con
probabilidad `1/6` cada una, y la esperanza de lo que falta es

```text
E[i] = 1 + (E[i+1] + E[i+2] + … + E[i+6]) / 6         con E[i] = 0 si i ≥ 10
E[0] = 33 495 175 / 10 077 696 ≈ 3,3237
```

Es una DP calculada **desde el final hacia el principio**, porque lo que se conoce es el final (desde la
meta faltan 0 tiradas). La versión con probabilidades —«¿con qué probabilidad paso por la casilla 7?»— va al
revés: hacia delante, desde el inicio, que se conoce con probabilidad 1.

> 🧠 **Modelo mental.** Las probabilidades se **empujan** hacia delante desde donde se sabe que se está;
> las esperanzas se **tiran** hacia atrás desde donde se sabe cuánto falta.

---

## 2. 📐 La teoría

**Probabilidades hacia delante.** Si `P[s]` es la probabilidad de estar en el estado `s`, y desde `s` se
pasa a `t` con probabilidad `p(s, t)`, entonces `P[t] = Σ_s P[s] · p(s, t)`, en el orden del proceso. Es una
DP de conteo ([`12/06`](../12-dp-clasica/06-conteo.md)) con pesos que suman 1.

**Linealidad de la esperanza** (su dueño es [`17/06`](../17-matematica/06-probabilidad-y-esperanza.md); aquí lo mínimo). `E[X + Y] = E[X] + E[Y]` **siempre**,
sean `X` e `Y` independientes o no. Es lo que permite descomponer «el número esperado de…» en una suma de
indicadores.

**Lo que no es lineal.** `E[X · Y] = E[X] · E[Y]` solo si `X` e `Y` son independientes. Con `X = Y` = un
dado, `E[X]² = 49/4` pero `E[X²] = 91/6`. La confusión es la fuente de muchos WA.

**Esperanza hacia atrás.** Si desde el estado `s` se paga un coste `c(s)` y se pasa a `t` con probabilidad
`p(s, t)`, la esperanza del coste total desde `s` es

```text
E[s] = c(s) + Σ_t p(s, t) · E[t]          con E[final] = 0
```

Se calcula en orden inverso al del proceso. Si un estado puede volver a sí mismo (un **autolazo**, como
«tirar otra vez si sale 6»), la ecuación tiene `E[s]` a los dos lados y se despeja:
`E[s] = (c(s) + Σ_{t ≠ s} p(s, t) E[t]) / (1 − p(s, s))`.

**Fracciones módulo un primo.** Si la respuesta es `p/q`, el juez pide `p · q⁻¹ mod M`, con `q⁻¹` el
inverso modular, que por el pequeño teorema de Fermat es `q^(M−2) mod M` ([`17/03`](../17-matematica/03-aritmetica-modular.md)). Toda la DP se hace en
aritmética modular: dividir entre 6 es multiplicar por `6⁻¹`.

---

## 3. 🧱 DP de probabilidad

**Qué es.** Propagar una distribución de probabilidad por los estados de un proceso aleatorio, en el orden
del proceso.

**Por qué es correcto** (enunciado y una frase). Por la ley de la probabilidad total: la probabilidad de
estar en `t` tras un paso es la suma, sobre los estados de los que se puede venir, de la probabilidad de
estar ahí por la de pasar a `t`.

**Cómo va**, la suma de dos dados: la distribución tras el primer dado es uniforme en 1–6; tras el segundo,
cada suma `s` acumula `P₁[s − d] / 6`:

```text
suma     2     3     4     5     6     7     8     9     10    11    12
casos    1     2     3     4     5     6     5     4     3     2     1      (de 36)
```

**Cuánto.** `n` pasos por estados por transiciones: con `n` dados de `k` caras y sumas hasta `n · k`,
`Θ(n² · k²)`, o `Θ(n² · k)` con prefijos.

**La plantilla**, la distribución de la suma de `n` dados de `k` caras:

```cpp
#include <vector>

// prob[s] = probabilidad de que n dados de k caras sumen s. Θ(n · (n·k) · k).
std::vector<double> diceSum(int n, int k) {
    std::vector<double> prob(1, 1.0);                           // 0 dados: suma 0 con probabilidad 1
    for (int i = 0; i < n; i++) {
        std::vector<double> next(prob.size() + k, 0.0);
        for (size_t s = 0; s < prob.size(); s++)
            if (prob[s] > 0)
                for (int d = 1; d <= k; d++) next[s + d] += prob[s] / k;   // empujar hacia delante
        prob = next;
    }
    return prob;
}
```

```java
// prob[s] = probabilidad de que n dados de k caras sumen s. Θ(n · (n·k) · k).
static double[] diceSum(int n, int k) {
    double[] prob = {1.0};
    for (int i = 0; i < n; i++) {
        double[] next = new double[prob.length + k];
        for (int s = 0; s < prob.length; s++)
            if (prob[s] > 0)
                for (int d = 1; d <= k; d++) next[s + d] += prob[s] / k;
        prob = next;
    }
    return prob;
}
```

- **Empujar** (de `s` a sus sucesores) es lo natural cuando se conoce el estado de partida.
- **En `double`** las probabilidades muy pequeñas pierden precisión relativa, pero la suma se mantiene
  bien; para respuestas exactas, aritmética modular o `Fraction` en Python.
- **Con prefijos**, la suma de `prob[s − d]` para `d = 1..k` sale en `O(1)`.

**Cuándo sí**: «¿con qué probabilidad…?», procesos con un número fijo de pasos o estados que solo avanzan.
**Cuándo no**: si los estados forman ciclos sin un número fijo de pasos (cadenas de Markov, [`19/04`](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md)), hace
falta resolver un sistema lineal ([`17/07`](../17-matematica/07-matrices-y-gauss.md)) o iterar hasta converger.

> **Veredicto:** una DP de probabilidad es una DP de conteo con pesos: se empuja la distribución hacia
> delante desde el estado inicial.

---

## 4. 🧱 Esperanza hacia atrás

**Qué es.** Calcular el valor esperado de un coste (tiradas, pasos, puntos) desde cada estado, empezando por
los finales, con la recurrencia de §2.

**Por qué es correcto** (enunciado y una frase). Por la linealidad de la esperanza condicionada: el coste
desde `s` es el coste de este paso más el coste desde el estado siguiente, y la esperanza de lo segundo es
la media ponderada de las esperanzas de los sucesores.

**Cómo va**, el dado hasta llegar a 2 o más, desde 0: `E[1] = 1` (cualquier tirada llega); `E[0] = 1 +
(E[1] + 0 + 0 + 0 + 0 + 0) / 6 = 7/6`. Módulo `10⁹ + 7`, `7 · 6⁻¹ = 166 666 669`.

**Cuánto.** Estados por transiciones, como cualquier DP; más un inverso modular (`O(log M)`) si hay que
dividir, que se precalcula.

**La plantilla**, tiradas esperadas para llegar a `n` o más con un dado de `m` caras, módulo `M`:

```cpp
#include <vector>

const long long MOD = 1'000'000'007;

long long power(long long b, long long e) {                     // b^e mod MOD
    long long r = 1; b %= MOD;
    for (; e > 0; e >>= 1, b = b * b % MOD) if (e & 1) r = r * b % MOD;
    return r;
}

// E[0] mod MOD, con E[i] = 1 + (E[i+1] + … + E[i+m]) / m y E[i] = 0 si i ≥ n. Θ(n) con suma deslizante.
long long expectedRolls(int n, int m) {
    long long invM = power(m, MOD - 2);                          // 1/m por Fermat
    std::vector<long long> E(n + m + 1, 0);
    long long window = 0;                                        // E[i+1] + … + E[i+m]
    for (int i = n - 1; i >= 0; i--) {
        E[i] = (1 + window * invM) % MOD;
        window = (window + E[i] - E[i + m] + MOD) % MOD;         // la ventana baja una posición
    }
    return E[0];
}
```

```java
static final long MOD = 1_000_000_007L;

static long power(long b, long e) {
    long r = 1; b %= MOD;
    for (; e > 0; e >>= 1, b = b * b % MOD) if ((e & 1) == 1) r = r * b % MOD;
    return r;
}

// E[0] mod MOD, con E[i] = 1 + (E[i+1] + … + E[i+m]) / m y E[i] = 0 si i ≥ n. Θ(n).
static long expectedRolls(int n, int m) {
    long invM = power(m, MOD - 2);
    long[] E = new long[n + m + 1];
    long window = 0;
    for (int i = n - 1; i >= 0; i--) {
        E[i] = (1 + window * invM) % MOD;
        window = ((window + E[i] - E[i + m]) % MOD + MOD) % MOD;
    }
    return E[0];
}
```

- **Hacia atrás**: `E[i]` depende de estados mayores, que ya están.
- **La ventana deslizante** mantiene `Σ E[i+1..i+m]` en `O(1)` por paso: es la suma de prefijos de [`04/01`](../04-secuencias/01-prefijos-y-diferencias.md).
- **La resta modular** con `+ MOD` para no quedar negativa.
- **Con autolazo**, se despeja: `E[s] = (c + Σ_{t≠s} p E[t]) · (1 − p(s,s))⁻¹`.

**Cuándo sí**: «número esperado de pasos / tiradas / turnos», con estados que avanzan hacia un final.
**Cuándo no**: si la esperanza se descompone en indicadores (cuántos pares, cuántos récords), la linealidad
da la respuesta sin DP (`17/06`); si hay ciclos generales, un sistema lineal.

> **Veredicto:** la esperanza se calcula desde el final, donde vale 0, hacia el principio. Con módulo,
> cada división es un inverso.

---

## 5. ⏱️ La tabla de costes

| Técnica | Tiempo | Lo que la tabla no dice |
|---|---|---|
| Probabilidades hacia delante | Estados × transiciones | En `double`; para exacto, módulo o fracciones |
| Esperanza hacia atrás | Estados × transiciones | Autolazos: despejar; ciclos generales: sistema lineal |
| Linealidad con indicadores | Lo que cueste cada indicador | A menudo evita la DP entera |
| Inverso modular por Fermat | `O(log M)` | Solo con `M` primo; precalcular los que se repiten |

---

## 6. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Con qué probabilidad…?», número fijo de pasos | DP de probabilidad hacia delante | Se conoce el inicio |
| «Número esperado de…» hasta llegar a algo | Esperanza hacia atrás | Se conoce el final |
| «Imprime `p · q⁻¹ mod 998244353`» | Aritmética modular con inversos | La respuesta es una fracción |
| «Esperanza de la suma / del número de…» | Linealidad con indicadores | No hace falta independencia |
| «Repetir si sale…» | Autolazo: despejar | El estado aparece a los dos lados |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La esperanza de un producto es el producto de esperanzas» | Solo con independencia: con `X = Y` = un dado, `49/4` frente a `91/6` |
| «La esperanza se calcula hacia delante como la probabilidad» | Se calcula desde el final, donde vale 0 |
| «Divido entre 6 con `/` en módulo» | Se multiplica por `6⁻¹ = 6^(M−2)` |
| «Un autolazo hace la DP circular» | Se despeja: `E = (resto) / (1 − p)` |
| «Para la esperanza necesito independencia» | La suma es lineal siempre; el producto no |
| «Simulo un millón de partidas y redondeo» | El juez pide el valor exacto, o con error relativo pequeño que la simulación no garantiza |

---

## 📚 Para profundizar

- **Libro** — Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017), cap. 2:
  variables aleatorias, esperanza y linealidad. *Lectura troncal.*
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 11: la
  probabilidad en problemas de concurso. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Modular Multiplicative Inverse*](https://cp-algorithms.com/algebra/module-inverse.html).
- **Libro** — Graham, Knuth y Patashnik, *Concrete Mathematics*, 2.ª ed. (Addison-Wesley, 1994), cap. 8:
  probabilidad discreta.

---

## 🧠 Preguntas

1. ¿Por qué las probabilidades se propagan hacia delante y las esperanzas hacia atrás? 🟢
2. ¿Qué dice la linealidad de la esperanza y qué no dice? 🟢
3. ¿Cómo se calcula `p/q mod M` con `M` primo? 🟢
4. ¿Qué es un autolazo en una DP de esperanza y cómo se resuelve? 🟡
5. ¿En qué se diferencia una DP de probabilidad de una DP de conteo? 🟡
6. Da un ejemplo en que `E[X · Y] ≠ E[X] · E[Y]`. 🟡
7. Compara cómo calculas una probabilidad exacta en C++, Java y Python. 🟡
8. ¿Por qué la ventana deslizante en la esperanza de las tiradas es correcta, y qué ahorra? 🟠
9. Deriva la esperanza del coleccionista de cromos con `n` cromos equiprobables con una DP hacia atrás. 🟠
10. ¿Cuándo resuelves «número esperado de…» con indicadores en lugar de con una DP? 🟠
11. ¿Qué haces si los estados de un proceso forman un ciclo general, no un autolazo? 🟠
12. Lanzando un dado de 6 caras desde la casilla 0 hasta llegar a `n` o pasarla, ¿con qué probabilidad se cae **exactamente** en `n`? Diseña la DP y di su coste. 🔴
13. Tu esperanza módulo `10⁹ + 7` da un número que no coincide con el decimal esperado. ¿Cómo lo compruebas? 🔴

---

## 🧩 Problemas propios

### Exactamente k caras

**Nivel:** 🟢 · **Formato:** programa completo.

Hay `n` monedas; la `i` sale cara con probabilidad `pᵢ`. Se lanzan todas. Imprime la probabilidad de que
salgan exactamente `k` caras, con seis decimales.

- **Entrada.** Una línea con `n` y `k`. Una línea con las `n` probabilidades.
- **Salida.** Un número con seis decimales.
- **Restricciones.** `1 ≤ n ≤ 3 000`; `0 ≤ k ≤ n`; `0 ≤ pᵢ ≤ 1`.

```text
Entrada            Salida
3 2                0.375000
0.5 0.5 0.5

Entrada            Salida
3 1                0.306000
0.3 0.6 0.9
```

**Pista 1:** si conoces la probabilidad de tener `j` caras con las `i` primeras monedas, ¿qué pasa al lanzar
la siguiente?

### Hasta la meta

**Nivel:** 🟡 · **Formato:** programa completo.

Se empieza en la casilla 0 y se lanza un dado de `m` caras (de 1 a `m`), avanzando lo que sale, hasta llegar
a la casilla `n` o pasarla. Imprime el número esperado de lanzamientos como `p · q⁻¹ mod 10⁹ + 7`.

- **Entrada.** Una línea con `n` y `m`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`; `1 ≤ m ≤ 10⁶`.

```text
Entrada     Salida
2 6         166666669

Entrada     Salida
1 6         1

Entrada     Salida
3 2         250000004
```

(Con `n = 2` y `m = 6` la esperanza es `7/6`; con `n = 3` y `m = 2`, `9/4`.)

**Pista 1:** desde la meta, ¿cuántos lanzamientos faltan? ¿Y desde la casilla anterior?

### El coleccionista

**Nivel:** 🟠 · **Formato:** programa completo.

Cada sobre trae un cromo de `n` posibles, todos con la misma probabilidad. ¿Cuántos sobres hay que abrir, en
media, para tener todos? Imprime el resultado como `p · q⁻¹ mod 10⁹ + 7`.

- **Entrada.** Una línea con `n`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁶`.

```text
Entrada     Salida
1           1

Entrada     Salida
2           3

Entrada     Salida
3           500000009
```

(Con `n = 3`, la esperanza es `11/2`.)

**Pista 1:** si ya tienes `i` cromos distintos, ¿con qué probabilidad el siguiente sobre trae uno nuevo, y
qué pasa si no?

---

## 🧩 Práctica externa

Codility no tiene problemas de probabilidad. Las específicas son CSES (sección de matemáticas) y la serie
de DP de AtCoder.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Knight Probability in Chessboard](https://leetcode.com/problems/knight-probability-in-chessboard/) | LeetCode | 🟡 | Probabilidad hacia delante | Tras `k` movimientos, ¿con qué probabilidad está el caballo en cada casilla? |
| [ ] | [New 21 Game](https://leetcode.com/problems/new-21-game/) | LeetCode | 🟡 | Probabilidad con ventana deslizante | ¿De qué puntuaciones se llega a `i` con una carta? |
| [ ] | [Soup Servings](https://leetcode.com/problems/soup-servings/) | LeetCode | 🟡 | Probabilidad con estados acotados | Con `n` muy grande, ¿cuánto se acerca la respuesta a 1? |
| [ ] | [Coins](https://atcoder.jp/contests/dp/tasks/dp_i) | AtCoder | 🟡 | Distribución del número de caras | ¿Qué estado basta tras lanzar las `i` primeras? |
| [ ] | [Dice Probability](https://cses.fi/problemset/task/1725) | CSES | 🟡 | Distribución de la suma | ¿Hasta qué suma llega la tabla con `n` dados? |
| [ ] | [Inversion Probability](https://cses.fi/problemset/task/1728) | CSES | 🟡 | Linealidad con indicadores | Para un par `i < j`, ¿con qué probabilidad forma una inversión? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Candy Lottery](https://cses.fi/problemset/task/1727) | CSES | 🟡 | Esperanza del máximo | ¿Cuál es la probabilidad de que el máximo sea `≤ x`? |
| [ ] | [Sushi](https://atcoder.jp/contests/dp/tasks/dp_j) | AtCoder | 🟠 | Esperanza hacia atrás con autolazo | ¿Qué estado basta: cuántos platos tienen 1, 2 y 3 piezas? |
| [ ] | [Moving Robots](https://cses.fi/problemset/task/1726) | CSES | 🟠 | Probabilidad por robot y linealidad | La casilla vacía, ¿es la suma de indicadores de algo? |

---

## ✅ Criterio de dominio

- Escribir la esperanza hacia atrás con inverso modular y ventana deslizante sin mirar.
- Despejar un autolazo y explicar por qué hace falta.
- Decidir cuándo basta la linealidad con indicadores.
- Resolver Coins y Sushi sin pista 2.

---

**Anterior:** [`13/03` — DP en árboles y en DAG](03-dp-en-arboles-y-dag.md) · **Siguiente:** [`13/05` — Optimizaciones de DP](05-optimizaciones.md) ·
**Relacionado:** [`17/06` — Probabilidad y esperanza](../17-matematica/06-probabilidad-y-esperanza.md); [`17/03` — Aritmética modular](../17-matematica/03-aritmetica-modular.md).
