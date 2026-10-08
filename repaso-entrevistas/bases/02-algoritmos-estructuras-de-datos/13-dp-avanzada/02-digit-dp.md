# 02 — *Digit DP*

> Contar los números de un rango `[a, b]` —con `b` hasta `10¹⁸`— que cumplen una propiedad de sus
> dígitos, recorriendo los dígitos de izquierda a derecha con un estado que recuerda si el número ya es
> menor que el límite. La cuenta del rango sale de dos cuentas de prefijo: `f(b) − f(a − 1)`.
>
> **Niveles:** *digit DP* [B].
>
> **📚 Lectura troncal:** ningún libro del canon trata la técnica (excepción declarada en la guía, §11.2).
> La guía fija cp-algorithms como referencia, pero cp-algorithms **no tiene** página de *digit DP*
> (comprobado el 2026-10-04); la referencia troncal es USACO Guide, [*Digit DP*](https://usaco.guide/gold/digit-dp).
>
> **Asume leído:** [`12/01` — De la recursión a la tabla](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--digit-dp) · [4](#4--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

¿Cuántos números entre 1 y `10¹⁸` tienen la suma de sus dígitos múltiplo de 7? Recorrerlos es imposible.
Pero la propiedad solo depende de los dígitos, y un número de 18 cifras se decide cifra a cifra: la suma
acumulada módulo 7 es todo lo que hace falta recordar de las cifras ya puestas. Hay 18 posiciones, 7 restos
y 10 dígitos por posición: unas 1 300 operaciones.

La única complicación es el **límite**: al contar hasta `N = 523`, la primera cifra puede ser 0–5, pero si
es 5, la segunda solo puede ser 0–2, y si es 52, la tercera solo 0–3. Esa restricción se lleva en un
indicador de **«todavía pegado al límite»** (*tight*).

> 🧠 **Modelo mental.** Una *digit DP* construye el número cifra a cifra de izquierda a derecha, como
> quien rellena un formulario; el estado es la posición, si ya se ha bajado del límite, y lo mínimo que
> la propiedad necesita recordar.

---

## 2. 📐 La teoría

**De un rango a dos prefijos.** Si `f(N)` = cuántos números de `[0, N]` cumplen la propiedad, la respuesta
de `[a, b]` es `f(b) − f(a − 1)`. Así solo hay que contar hasta un límite.

**El estado.** Con las cifras de `N` en `d₀ d₁ … d_{L−1}` (de la más significativa a la menos):

```text
(pos, tight, extra)
pos     → qué cifra se decide ahora
tight   → si las cifras ya puestas son exactamente d₀…d_{pos−1}: entonces la cifra actual va de 0 a d_pos;
          si ya se puso alguna menor, va de 0 a 9 y ya no vuelve a estar pegado
extra   → lo que la propiedad necesita: suma módulo k, cuántos 7, la última cifra, si ya empezó el número…
```

**La transición.** Para cada cifra `c` permitida, el nuevo `tight` es `tight && c == d_pos`, y el nuevo
`extra` se actualiza con `c`. Al llegar a `pos = L`, el número está completo y se cuenta si `extra` cumple la
propiedad.

**Por qué es correcto.** Cada número de `[0, N]`, escrito con `L` cifras (con ceros a la izquierda), es
exactamente un camino desde `(0, tight = sí)`: en cada posición hay una cifra, y `tight` solo se apaga en la
primera posición donde el número baja del límite. La correspondencia es biyectiva (`12/06`).

**Los ceros a la izquierda.** Con ceros a la izquierda, `0042` y `42` son el mismo número. Si la propiedad
no cambia por ellos (la suma de dígitos), no importa. Si sí (contar dígitos, «sin cifras repetidas»,
«dígitos no decrecientes»), se añade al estado un indicador **«todavía no ha empezado»**.

**Cuánto.** Estados `L · 2 · |extra|`, por 10 transiciones. Solo los estados con `tight = no` se reutilizan
(con `tight = sí` hay un único camino), así que la memoización suele guardar solo esos.

---

## 3. 🧱 *Digit DP*

**Qué es.** La DP de §2, escrita como memoización sobre `(pos, extra)` para los estados no pegados y
recorriendo el camino pegado a mano.

**Por qué es correcto** (enunciado y una frase). Por la biyección de §2: cada número de `[0, N]` es un camino
único, y la memo sobre los estados libres cuenta cada subárbol una vez.

**Cómo va**, la suma de dígitos múltiplo de `k` hasta `N = 523`: en la posición 0, con `tight`, se puede
poner 0–5. Poner 0–4 apaga el `tight` y deja dos cifras libres (con 100 combinaciones cada una, que la memo
reparte por restos); poner 5 deja `tight` y la posición 1 va de 0 a 2; y así hasta la última. Con `k = 10`
y «suma exactamente 10» hay 46 números en `[0, 523]`.

**La plantilla**, cuántos números de `[0, N]` tienen la suma de sus dígitos múltiplo de `k`:

```cpp
#include <cstring>
#include <string>

// Cuántos x en [0, N] tienen suma de dígitos ≡ 0 (mod k). N ≤ 10¹⁸, k ≤ 200. Θ(L · k · 10).
long long memo[20][200];
bool seen[20][200];
std::string digits;
int K;

long long go(int pos, int rem, bool tight) {
    if (pos == (int)digits.size()) return rem == 0 ? 1 : 0;
    if (!tight && seen[pos][rem]) return memo[pos][rem];
    int limit = tight ? digits[pos] - '0' : 9;
    long long count = 0;
    for (int c = 0; c <= limit; c++)
        count += go(pos + 1, (rem + c) % K, tight && c == limit);
    if (!tight) { seen[pos][rem] = true; memo[pos][rem] = count; }   // solo se guardan los libres
    return count;
}

long long countUpTo(long long N, int k) {
    if (N < 0) return 0;                                           // f(−1) = 0
    digits = std::to_string(N); K = k;
    std::memset(seen, 0, sizeof seen);
    return go(0, 0, true);
}
// Rango [a, b]: countUpTo(b, k) − countUpTo(a − 1, k)
```

```java
// Cuántos x en [0, N] tienen suma de dígitos ≡ 0 (mod k). N ≤ 10¹⁸, k ≤ 200. Θ(L · k · 10).
static long[][] memo;
static char[] digits;
static int K;

static long go(int pos, int rem, boolean tight) {
    if (pos == digits.length) return rem == 0 ? 1 : 0;
    if (!tight && memo[pos][rem] >= 0) return memo[pos][rem];
    int limit = tight ? digits[pos] - '0' : 9;
    long count = 0;
    for (int c = 0; c <= limit; c++)
        count += go(pos + 1, (rem + c) % K, tight && c == limit);
    if (!tight) memo[pos][rem] = count;
    return count;
}

static long countUpTo(long N, int k) {
    if (N < 0) return 0;
    digits = Long.toString(N).toCharArray(); K = k;
    memo = new long[digits.length][k];
    for (long[] row : memo) java.util.Arrays.fill(row, -1);
    return go(0, 0, true);
}
```

- **Solo se memoizan los estados libres** (`!tight`): los pegados son un único camino y además su valor
  depende de `N`. Si se memoizaran sin incluir `tight` en el estado, se mezclarían los dos.
- **La memo se reinicia** para cada `N` (o se indexa de derecha a izquierda, por «cifras que quedan», y
  entonces sirve para cualquier `N`).
- **El 0 se cuenta** (su suma es 0): si el rango empieza en 1, `f(b) − f(0)`; la fórmula `f(b) − f(a − 1)` lo
  resuelve sola.
- **Con ceros a la izquierda que importan**, se añade el indicador `started` y la transición `c = 0` con
  `!started` no actualiza `extra`.

**Cuándo sí**: «cuántos números en `[a, b]`» con una propiedad local de sus dígitos y `b` hasta `10¹⁸`.
**Cuándo no**: si la propiedad depende del número entero de forma no local (ser primo, ser un cuadrado),
salvo que se pueda reducir a un resto o a dígitos; o si `b − a` es pequeño (`10⁶`), donde recorrer basta.

> **Veredicto:** para `10¹⁸` sí hay forma: cifra a cifra con `(pos, tight, lo que la propiedad necesite)`, y
> el rango como diferencia de dos prefijos.

---

## 4. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Cuántos números entre `a` y `b`» con `b` hasta `10¹⁸` y una condición sobre sus dígitos | *Digit DP* | Cifra a cifra con `tight` |
| «La suma de los dígitos es…», «tiene exactamente `k` sietes», «no hay dos dígitos iguales seguidos» | *Digit DP* con `extra` | La propiedad cabe en un estado pequeño |
| «Divisible por `m`» con `m` pequeño | *Digit DP* con el resto del número | `(resto · 10 + c) mod m` |
| «Sin ceros a la izquierda», «cuántos dígitos tiene» | Añadir `started` | El cero inicial no es un dígito |
| `b − a ≤ 10⁶` | Recorrer el rango | La DP es ceremonia |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Para `10¹⁸` no hay forma» | Cifra a cifra son `18 · estados · 10` operaciones |
| «Memoizo `(pos, extra)` con y sin `tight` en la misma tabla» | Los pegados dependen de `N`: o se memoiza solo lo libre, o `tight` va en el estado |
| «`f(b) − f(a)`» | Es `f(b) − f(a − 1)`: el propio `a` entra en el rango |
| «Los ceros a la izquierda no importan» | Importan si la propiedad cuenta dígitos o mira el primero |
| «La memo sirve para la segunda llamada» | Si depende de `N` (por la posición desde la izquierda), hay que reiniciarla |

---

## 📚 Para profundizar

- **Referencia** — USACO Guide, [*Digit DP*](https://usaco.guide/gold/digit-dp): la técnica con problemas
  graduados. *Lectura troncal* (cp-algorithms no la trata).
- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 6: la
  programación dinámica de conteo en la que se apoya.
- **Referencia** — cp-algorithms, [*Introduction to Dynamic Programming*](https://cp-algorithms.com/dynamic_programming/intro-to-dp.html):
  el diseño del estado.

---

## 🧠 Preguntas

1. ¿Por qué la cuenta de `[a, b]` es `f(b) − f(a − 1)`? 🟢
2. ¿Qué significa el indicador `tight` y cuándo se apaga? 🟢
3. ¿Cuántos estados tiene la *digit DP* de la suma de dígitos módulo `k` con `N = 10¹⁸`? 🟢
4. ¿Por qué solo se memoizan los estados con `tight` apagado? 🟡
5. ¿Cuándo hacen falta los ceros a la izquierda en el estado, y qué indicador se añade? 🟡
6. ¿Qué `extra` lleva el estado para «divisible por `m`»? 🟡
7. Compara cómo obtienes las cifras de un `long` de 18 cifras en C++, Java y Python. 🟡
8. Demuestra que cada número de `[0, N]` corresponde a exactamente un camino de la DP. 🟠
9. ¿Qué cambia si la propiedad es «no hay dos dígitos iguales seguidos»? 🟠
10. ¿Cómo reutilizas la memo entre varias consultas con `N` distintos? 🟠
11. ¿Qué pasa si `a = 0`, y cómo lo maneja la fórmula de prefijos? 🟠
12. Diseña la *digit DP* para contar los números de `[a, b]` cuyos dígitos son no decrecientes. 🔴
13. Tu *digit DP* da 1 más de lo esperado en todos los casos. ¿Qué miras primero? 🔴

---

## 🧩 Problemas propios

### Solo cifras pares

**Nivel:** 🟢 · **Formato:** programa completo.

¿Cuántos números de `[0, N]` tienen todas sus cifras pares?

- **Entrada.** Una línea con `N`.
- **Salida.** Un entero.
- **Restricciones.** `0 ≤ N ≤ 10¹⁸`.

```text
Entrada     Salida
100         25

Entrada     Salida
2024        133

Entrada     Salida
5           3
```

**Pista 1:** si ya pusiste una cifra menor que la del límite, ¿cuántas opciones tiene cada cifra restante?

### Suma múltiplo de k

**Nivel:** 🟡 · **Formato:** programa completo.

¿Cuántos números de `[a, b]` tienen la suma de sus cifras múltiplo de `k`?

- **Entrada.** Una línea con `a`, `b` y `k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ a ≤ b ≤ 10¹⁸`; `1 ≤ k ≤ 200`.

```text
Entrada         Salida
1 100 7         13

Entrada         Salida
10 20 3         3
```

**Pista 1:** de las cifras ya puestas, ¿qué necesitas recordar para saber si la suma final será múltiplo de
`k`?

### Exactamente k sietes

**Nivel:** 🟠 · **Formato:** programa completo.

¿Cuántos números de `[a, b]` tienen exactamente `k` cifras iguales a 7?

- **Entrada.** Una línea con `a`, `b` y `k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ a ≤ b ≤ 10¹⁸`; `0 ≤ k ≤ 19`.

```text
Entrada         Salida
1 100 1         18

Entrada         Salida
1 1000 2        27

Entrada         Salida
70 77 2         1
```

**Pista 1:** con `k = 0`, ¿cuentan los ceros a la izquierda como cifras distintas de 7?

---

## 🧩 Práctica externa

Las bases tienen *digit DP* solo en dificultad alta; la específica es CSES y la serie de DP de AtCoder.
SPOJ tiene muchos, pero responde `403` a la verificación automática y no se enlaza.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Count Numbers with Unique Digits](https://leetcode.com/problems/count-numbers-with-unique-digits/) | LeetCode | 🟡 | Conteo cifra a cifra sin límite | Con `n` cifras y sin límite superior, ¿cuántas opciones tiene cada posición? |
| [ ] | [Rotated Digits](https://leetcode.com/problems/rotated-digits/) | LeetCode | 🟡 | *Digit DP* con un indicador | ¿Qué tiene que pasar con las cifras para que el número cambie al girarlo? |
| [ ] | [Digit Sum](https://atcoder.jp/contests/dp/tasks/dp_s) | AtCoder | 🟡 | Suma de dígitos módulo `D` | ¿Qué recuerdas de las cifras ya puestas? |
| [ ] | [Counting Numbers](https://cses.fi/problemset/task/2220) | CSES | 🟠 | *Digit DP* con la última cifra y `started` | ¿Qué cifra no puedes poner a continuación, y cuándo el cero no cuenta? |
| [ ] | [Number of Digit One](https://leetcode.com/problems/number-of-digit-one/) | LeetCode | 🟠 | Contar apariciones cifra a cifra | ¿Cuántas veces aparece un 1 en la posición de las decenas entre 0 y `N`? |
| [ ] | [Numbers At Most N Given Digit Set](https://leetcode.com/problems/numbers-at-most-n-given-digit-set/) | LeetCode | 🟠 | *Digit DP* con conjunto de cifras | Los números con menos cifras que `N`, ¿están todos por debajo? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Non-negative Integers without Consecutive Ones](https://leetcode.com/problems/non-negative-integers-without-consecutive-ones/) | LeetCode | 🟠 | *Digit DP* en binario | ¿Qué recuerdas del bit anterior? |
| [ ] | [Numbers With Repeated Digits](https://leetcode.com/problems/numbers-with-repeated-digits/) | LeetCode | 🟠 | Complementario: los de cifras distintas | ¿Es más fácil contar los que **no** repiten? |
| [ ] | [Count of Integers](https://leetcode.com/problems/count-of-integers/) | LeetCode | 🟠 | Rango con cadenas y suma acotada | Si `num1` y `num2` son cadenas, ¿cómo calculas `f(num1 − 1)`? |
| [ ] | [Count Special Integers](https://leetcode.com/problems/count-special-integers/) | LeetCode | 🔴 | *Digit DP* con máscara de cifras usadas | ¿Qué cifras ya usaste? Caben en 10 bits. |

---

## ✅ Criterio de dominio

- Escribir la plantilla con `tight` y la diferencia de prefijos sin mirar, en menos de quince minutos.
- Decidir qué `extra` lleva el estado para una propiedad dada, y si hace falta `started`.
- Explicar por qué solo se memoizan los estados libres.
- Resolver Digit Sum y Counting Numbers sin pista 2.

---

**Anterior:** [`13/01` — DP con máscaras de bits](01-mascaras-de-bits.md) · **Siguiente:** [`13/03` — DP en árboles y en DAG](03-dp-en-arboles-y-dag.md) ·
**Relacionado:** [`12/06` — Conteo con DP](../12-dp-clasica/06-conteo.md).
