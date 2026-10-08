# 03 — Kadane y subarreglos

> El subarreglo de suma máxima en `O(n)` con su invariante, su variante circular, el conteo de
> subarreglos con una suma dada usando prefijos y una tabla *hash*, y el voto de mayoría de
> Boyer-Moore. Es el dueño de Kadane; la programación dinámica de [`12/02`](../12-dp-clasica/02-dp-lineal-y-lis.md) lo cita.
>
> **Niveles:** Kadane [A] · variante circular [A] · conteo con prefijos y *hash* [A] · voto de mayoría
> de Boyer-Moore [B].
>
> **📚 Lectura troncal:** Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 8;
> Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009), cap. 4
> (el subarreglo máximo por divide y vencerás).
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--kadane) · [4](#4--la-variante-circular) · [5](#5--contar-subarreglos-con-prefijos-y-hash) · [6](#6--el-voto-de-mayoría-de-boyer-moore) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Los beneficios diarios de una tienda, con días de pérdidas. ¿Cuál es el periodo de días consecutivos
con mayor beneficio total? Con valores negativos, la ventana de `04/02` no sirve: añadir un día con
pérdidas puede valer la pena si después vienen ganancias. Y probar todos los tramos son `n²/2`.

Los datos del capítulo, declarados para el bloque porque el arreglo de juguete no tiene negativos:

```text
beneficios:   [3, −4, 5, −1, 2, −6, 4]
subarreglo máximo:   [5, −1, 2]  → 6
circular máximo:     [4, 3, −4, 5, −1, 2], dando la vuelta  → 9
tramos con suma 0:   4
```

Una observación lo resuelve en un recorrido: el mejor tramo **que termina en el día `i`** es el mejor
que terminaba en `i − 1` más el día `i`, o solo el día `i` si lo acumulado era negativo. Es el
**algoritmo de Kadane**, la programación dinámica más pequeña que existe. La misma familia de ideas
cuenta cuántos tramos tienen una suma dada, con prefijos (`04/01`) y una tabla *hash*.

> 🧠 **Modelo mental.** Recordatorio, si llegas directo aquí: la suma de un tramo `a[l..r]` es la
> diferencia de dos prefijos, `P[r+1] − P[l]`, con `P[0] = 0` y `P[k]` la suma de los `k` primeros.

---

## 2. 📐 La teoría

**La subestructura de Kadane.** Sea `best_end(i)` la mayor suma de un subarreglo **no vacío que
termina en `i`**. Entonces:

```text
best_end(0) = a[0]
best_end(i) = max( a[i], best_end(i−1) + a[i] )
respuesta   = max sobre i de best_end(i)
```

**Teorema (corrección de Kadane).** La recurrencia calcula `best_end(i)`, y el máximo de `best_end(i)`
sobre todos los `i` es la suma del subarreglo máximo.

*Prueba.* Todo subarreglo no vacío termina en algún `i`, así que el máximo global es el máximo de los
`best_end(i)`. Un subarreglo que termina en `i` es `[i]` solo, o un subarreglo que termina en `i − 1`
seguido de `a[i]`; el mejor de la segunda clase es `best_end(i − 1) + a[i]`, porque sumar `a[i]` a todos
conserva el orden. Por inducción sobre `i` ([`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md)), la recurrencia es correcta. Es una
**programación dinámica** con un estado por posición ([`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md)).

**El caso circular.** En un arreglo circular, un tramo o no da la vuelta (Kadane normal) o la da; y un
tramo que da la vuelta es el **complemento** de un tramo que no la da. Por tanto:

```text
máximo circular = max( Kadane(a),  total − mínimo subarreglo(a) )
excepto si todos son negativos: entonces el complemento del mínimo sería vacío, y vale Kadane(a)
```

**Teorema (voto de mayoría).** Si un valor aparece más de `n/2` veces, eliminar repetidamente dos
elementos **distintos** no lo elimina del todo, y es el que queda.

*Esbozo.* Cada eliminación quita como mucho una copia del mayoritario y al menos un elemento de otro
valor. Como el mayoritario tiene más copias que todos los demás juntos, se acaban antes los demás. El
algoritmo de Boyer-Moore hace estas eliminaciones con un candidato y un contador.

---

## 3. 🧱 Kadane

**Qué es.** Un recorrido que mantiene la mejor suma de un subarreglo que termina en la posición
actual, y el máximo visto.

**Por qué es correcto.** Por el teorema de §2: la recurrencia de `best_end` y la inducción.

**Cómo va**, sobre los beneficios del bloque:

```text
a[i]    cur = max(a[i], cur + a[i])    best
 3       3                              3
−4      −1                              3
 5       5      (−1 + 5 = 4 < 5: empieza de nuevo)     5
−1       4                              5
 2       6                              6
−6       0                              6
 4       4                              6
```

**Cuánto.** `Θ(n)` en tiempo y `Θ(1)` en memoria. El divide y vencerás de CLRS (mejor tramo de cada
mitad y el que cruza el centro) es `2T(n/2) + Θ(n) = Θ(n log n)` ([`02/02`](../02-analisis/02-recurrencias-y-teorema-maestro.md)): un ejemplo, no una opción.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
long long maxSubarraySum(const std::vector<long long>& a) {
    long long best = a[0], cur = 0;
    for (long long x : a) {
        cur = std::max(x, cur + x);     // el mejor que termina aquí: extender o empezar
        best = std::max(best, cur);
    }
    return best;
}
```

```java
// Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n).
static long maxSubarraySum(long[] a) {
    long best = a[0], cur = 0;
    for (long x : a) {
        cur = Math.max(x, cur + x);
        best = Math.max(best, cur);
    }
    return best;
}
```

```python
def max_subarray_sum(a):
    """Suma máxima de un subarreglo no vacío. Pre: a no vacío. O(n)."""
    best, cur = a[0], 0
    for x in a:
        cur = max(x, cur + x)
        best = max(best, cur)
    return best
```

- **`best = a[0]`** y **`cur = max(x, cur + x)`**: el subarreglo nunca es vacío. La versión con
  `max(0, cur + x)` devuelve 0 cuando todos son negativos; es la autopsia de [`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md).
- **64 bits** en C++ y Java: la suma de `2·10⁵` valores de `10⁹` pasa de `int`.
- **Python**: el bucle es del intérprete; con `10⁶` elementos va justo pero entra.

### De la versión ingenua a la buena

**El problema.** Además de la suma, el periodo: el primer día y el último del tramo máximo. Con los
beneficios del bloque, la suma 6 del día 3 al 5 (contando desde 1).

**La versión ingenua:**

```java
// Todos los tramos con suma incremental: O(n²). Devuelve {suma, inicio, fin}.
static long[] bestPeriod(long[] a) {
    long[] best = {a[0], 0, 0};
    for (int i = 0; i < a.length; i++) {
        long sum = 0;
        for (int j = i; j < a.length; j++) {
            sum += a[j];
            if (sum > best[0]) best = new long[] {sum, i, j};
        }
    }
    return best;
}
```

> «Es cuadrático. Para cada final, el mejor tramo que termina ahí o extiende al mejor anterior o empieza
> en ese día; si recuerdo dónde empezó el tramo actual, tengo el periodo con un solo recorrido.»

**El camino a la buena.** Kadane con un índice de inicio: cuando se «empieza de nuevo», el inicio pasa a
ser el día actual; cuando `cur` mejora `best`, se guarda el par inicio-final.

```java
// Kadane con reconstrucción. O(n). Devuelve {suma, inicio, fin}.
static long[] bestPeriod(long[] a) {
    long cur = 0, bestSum = a[0];
    int start = 0, bestL = 0, bestR = 0;
    for (int i = 0; i < a.length; i++) {
        if (cur + a[i] < a[i]) { cur = a[i]; start = i; }   // empezar de nuevo en i
        else cur += a[i];                                   // extender
        if (cur > bestSum) { bestSum = cur; bestL = start; bestR = i; }
    }
    return new long[] {bestSum, bestL, bestR};
}
```

- **Empezar de nuevo** equivale a `cur < 0` antes de sumar `a[i]`; escrito como la comparación de la
  recurrencia, se ve que es la misma decisión.
- **Los empates** los decide la desigualdad: con `>` estricto se queda el primer tramo que alcanza el
  máximo; si el enunciado pide otro desempate, se cambia ahí.

**Cuándo sí**: el subarreglo contiguo de suma máxima, con o sin negativos. **Cuándo no**: con
restricciones extra (longitud mínima, como mucho `k` elementos), que piden prefijos con un mínimo
acumulado o una cola monótona.

> **Veredicto:** Kadane es dos líneas, y su forma correcta es la que nunca permite el tramo vacío.

---

## 4. 🧱 La variante circular

**Qué es.** El subarreglo de suma máxima cuando el arreglo es un círculo: el tramo puede empezar al
final y seguir por el principio.

**Por qué es correcto.** Por el argumento del complemento de §2: un tramo que da la vuelta deja fuera
exactamente un tramo que no la da, y maximizar el primero es minimizar el segundo.

**Cómo va**, con los beneficios del bloque: el total es 3 y el mínimo subarreglo es `[−6]`, con −6. El
máximo circular candidato es `3 − (−6) = 9`, que corresponde al tramo `[4, 3, −4, 5, −1, 2]` dando la
vuelta; es mayor que el Kadane normal, 6.

**Cuánto.** Dos pasadas de Kadane (una para el máximo y otra para el mínimo) o una sola que lleve las
dos: `Θ(n)`, `Θ(1)` memoria.

**La plantilla:**

```cpp
#include <algorithm>
#include <vector>

// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
long long maxCircularSum(const std::vector<long long>& a) {
    long long total = 0, curMax = 0, curMin = 0, best = a[0], worst = a[0];
    for (long long x : a) {
        total += x;
        curMax = std::max(x, curMax + x); best = std::max(best, curMax);
        curMin = std::min(x, curMin + x); worst = std::min(worst, curMin);
    }
    return best < 0 ? best : std::max(best, total - worst);   // todos negativos: no hay complemento
}
```

```java
// Suma máxima de un subarreglo no vacío de un arreglo circular. O(n).
static long maxCircularSum(long[] a) {
    long total = 0, curMax = 0, curMin = 0, best = a[0], worst = a[0];
    for (long x : a) {
        total += x;
        curMax = Math.max(x, curMax + x); best = Math.max(best, curMax);
        curMin = Math.min(x, curMin + x); worst = Math.min(worst, curMin);
    }
    return best < 0 ? best : Math.max(best, total - worst);
}
```

```python
def max_circular_sum(a):
    """Suma máxima de un subarreglo no vacío de un arreglo circular. O(n)."""
    total = cur_max = cur_min = 0
    best = worst = a[0]
    for x in a:
        total += x
        cur_max = max(x, cur_max + x); best = max(best, cur_max)
        cur_min = min(x, cur_min + x); worst = min(worst, cur_min)
    return best if best < 0 else max(best, total - worst)
```

- **`best < 0`**: si todos son negativos, el mínimo subarreglo es el arreglo entero y `total − worst = 0`
  correspondería al tramo vacío, que no vale. En ese caso la respuesta es el Kadane normal.
- **Una sola pasada** con dos Kadane en paralelo: el de máximos y el de mínimos.

### De la versión ingenua a la buena

**El problema.** Una ruta circular de reparto con beneficio o pérdida en cada parada; el mejor tramo de
paradas consecutivas, pudiendo pasar por el final. Con los beneficios del bloque, 9.

**La versión ingenua:**

```java
// Todos los inicios y todas las longitudes, con índices módulo n: O(n²).
static long maxCircularSum(long[] a) {
    int n = a.length;
    long best = a[0];
    for (int i = 0; i < n; i++) {
        long sum = 0;
        for (int len = 1; len <= n; len++) { sum += a[(i + len - 1) % n]; best = Math.max(best, sum); }
    }
    return best;
}
```

> «Pruebo cada inicio y cada longitud dando la vuelta: `O(n²)`. Pero un tramo que da la vuelta es todo
> menos un tramo que no la da; así que el mejor circular es el total menos el peor tramo normal, y los
> dos se calculan con Kadane en `O(n)`.»

**El camino a la buena.** La plantilla, con el caso de todos negativos.

**Cuándo sí**: arreglos circulares con sumas de tramos. **Cuándo no**: si además hay restricción de
longitud; entonces se duplica el arreglo y se usan prefijos con una cola monótona.

> **Veredicto:** circular = máximo entre Kadane y total menos el mínimo, con cuidado del caso en que
> todos son negativos.

---

## 5. 🧱 Contar subarreglos con prefijos y *hash*

**Qué es.** Contar los tramos cuya suma cumple una condición sobre una **diferencia de prefijos**:
suma igual a `k`, suma divisible por `m`, suma cero. Con un mapa de «cuántas veces vi cada prefijo».

**Por qué es correcto.** La suma de `a[l..r]` es `P[r+1] − P[l]`: contar tramos con suma `k` es contar
pares `l < j` con `P[l] = P[j] − k`. Recorriendo `j` en orden y llevando las frecuencias de los prefijos
anteriores, cada `j` suma exactamente los `l` válidos.

**Cómo va**, contando los tramos con suma 0 en los beneficios del bloque. Los prefijos son
`[0, 3, −1, 4, 3, 5, −1, 3]`; dos prefijos iguales delimitan un tramo de suma 0:

```text
j   P[j]   visto antes   tramos nuevos (P[l] = P[j], l < j)        total
1    3     0             —                                          0
2   −1     0             —                                          0
3    4     0             —                                          0
4    3     1             a[1..3] = −4 + 5 − 1                       1
5    5     0             —                                          1
6   −1     1             a[2..5] = 5 − 1 + 2 − 6                    2
7    3     2             a[1..6] y a[4..6]                          4
```

**Cuánto.** `Θ(n)` esperado con tabla *hash* ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)), `Θ(n log n)` con un mapa ordenado; memoria
`Θ(n)`. El contador llega a `n²/2`: 64 bits.

**La plantilla:**

```cpp
#include <unordered_map>
#include <vector>

// Número de subarreglos con suma exactamente k. O(n) esperado.
long long countSubarraysWithSum(const std::vector<long long>& a, long long k) {
    std::unordered_map<long long, long long> seen;
    seen.reserve(a.size() * 2 + 1);
    seen[0] = 1;                                  // el prefijo vacío
    long long prefix = 0, count = 0;
    for (long long x : a) {
        prefix += x;
        auto it = seen.find(prefix - k);
        if (it != seen.end()) count += it->second;   // tramos que terminan aquí
        seen[prefix]++;
    }
    return count;
}
```

```java
// Número de subarreglos con suma exactamente k. O(n) esperado.
static long countSubarraysWithSum(long[] a, long k) {
    java.util.HashMap<Long, Long> seen = new java.util.HashMap<>();
    seen.put(0L, 1L);                             // el prefijo vacío
    long prefix = 0, count = 0;
    for (long x : a) {
        prefix += x;
        count += seen.getOrDefault(prefix - k, 0L);
        seen.merge(prefix, 1L, Long::sum);
    }
    return count;
}
```

```python
from collections import defaultdict

def count_subarrays_with_sum(a, k):
    """Número de subarreglos con suma exactamente k. O(n) esperado."""
    seen = defaultdict(int)
    seen[0] = 1                                   # el prefijo vacío
    prefix = count = 0
    for x in a:
        prefix += x
        count += seen.get(prefix - k, 0)
        seen[prefix] += 1
    return count
```

- **`seen[0] = 1`** antes de empezar: el prefijo vacío permite contar los tramos que empiezan en 0.
- **Primero se cuenta y después se registra** el prefijo actual: si no, con `k = 0` se contaría el
  tramo vacío.
- **Para «suma divisible por `m`»**, la clave es `prefix mod m`, normalizado a `[0, m)` en C++ y Java,
  porque el `%` de un negativo es negativo ([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)).

### De la versión ingenua a la buena

**El problema.** ¿Cuántos periodos de días consecutivos terminan con el balance a cero? Con los
beneficios del bloque, 4.

**La versión ingenua:**

```java
// Todos los tramos con suma incremental: O(n²).
static long countZeroSum(long[] a) {
    long count = 0;
    for (int i = 0; i < a.length; i++) {
        long sum = 0;
        for (int j = i; j < a.length; j++) {
            sum += a[j];
            if (sum == 0) count++;
        }
    }
    return count;
}
```

> «Es cuadrático. Un tramo suma cero exactamente cuando el prefijo al empezar y el prefijo al terminar
> son iguales; así que basta contar, para cada prefijo, cuántas veces salió antes: `O(n)` esperado con
> un mapa.»

**El camino a la buena.** La plantilla con `k = 0`.

**Cuándo sí**: conteos de tramos con condiciones sobre la suma, **con negativos**, donde la ventana no
sirve. **Cuándo no**: si la condición no se expresa como una relación entre dos prefijos (el tramo con
máximo `≤ x`, por ejemplo).

> **Veredicto:** «cuántos subarreglos suman `k`» es «cuántos pares de prefijos difieren en `k`». Con el
> prefijo vacío en el mapa desde el principio.

---

## 6. 🧱 El voto de mayoría de Boyer-Moore

**Qué es.** Encontrar, en `O(n)` y `O(1)` de memoria, el valor que aparece más de `n/2` veces, si
existe.

**Por qué es correcto** (el enunciado y una frase): por el teorema del voto de §2, emparejar y descartar
elementos distintos nunca elimina al mayoritario, y el contador implementa esos emparejamientos.

**Cómo va.** Un candidato y un contador: si el contador es 0, el elemento actual pasa a ser el
candidato; si coincide con el candidato, el contador sube; si no, baja (un emparejamiento). Al final, el
candidato es el único que **puede** ser mayoritario: hay que **comprobarlo** con una segunda pasada,
porque si no hay mayoritario, el candidato es un valor cualquiera.

**Cuánto.** Dos pasadas, `Θ(n)`; `Θ(1)` memoria.

**La plantilla:**

```cpp
#include <vector>

// Valor que aparece más de n/2 veces, o -1 si no hay. O(n), O(1) memoria. Pre: valores >= 0.
long long majority(const std::vector<long long>& a) {
    long long cand = -1, cnt = 0;
    for (long long x : a) {
        if (cnt == 0) { cand = x; cnt = 1; }
        else if (x == cand) cnt++;
        else cnt--;                               // empareja x con una copia del candidato
    }
    long long occ = 0;
    for (long long x : a) occ += (x == cand);
    return 2 * occ > static_cast<long long>(a.size()) ? cand : -1;   // la comprobación
}
```

```java
// Valor que aparece más de n/2 veces, o -1 si no hay. O(n), O(1) memoria. Pre: valores >= 0.
static long majority(long[] a) {
    long cand = -1, cnt = 0;
    for (long x : a) {
        if (cnt == 0) { cand = x; cnt = 1; }
        else if (x == cand) cnt++;
        else cnt--;
    }
    long occ = 0;
    for (long x : a) if (x == cand) occ++;
    return 2 * occ > a.length ? cand : -1;
}
```

- **La segunda pasada no es opcional**: con `[1, 2, 3]` el candidato final es 3 y no es mayoritario.
- **Para «más de `n/k`»**, la generalización lleva `k − 1` candidatos.

**Cuándo sí**: el mayoritario con memoria constante. **Cuándo no**: si la memoria no importa, un mapa de
conteos es igual de lineal y más legible.

> **Veredicto:** Boyer-Moore es el ejemplo clásico de invariante sorprendente. En la práctica, cuéntalo
> con un mapa salvo que te pidan `O(1)` de memoria.

---

## 7. ⏱️ La tabla de costes

| Técnica | Tiempo | Memoria | Lo que la tabla no dice |
|---|---|---|---|
| Todos los tramos | `O(n²)` | `O(1)` | El oráculo del *stress test* |
| Kadane | `O(n)` | `O(1)` | Con `max(0, …)` falla si todos son negativos |
| Circular | `O(n)` | `O(1)` | El caso de todos negativos va aparte |
| Conteo con prefijos y *hash* | `O(n)` esperado | `O(n)` | Con *hash* atacable, `O(n log n)` con mapa ordenado |
| Boyer-Moore | `O(n)` | `O(1)` | Sin la segunda pasada, da un candidato falso |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Subarreglo contiguo de suma máxima», con negativos | Kadane | El mejor que termina en `i` extiende o empieza |
| «Arreglo circular», «puede dar la vuelta» | Kadane circular | El tramo que da la vuelta es el complemento de uno normal |
| «Cuántos subarreglos suman `k`», con negativos | Prefijos y mapa de frecuencias | La suma de un tramo es una diferencia de prefijos |
| «Suma divisible por `m`» | Prefijos módulo `m` y conteo | Dos prefijos con el mismo resto delimitan un tramo divisible |
| «El que aparece más de la mitad de las veces», memoria `O(1)` | Boyer-Moore | Emparejar distintos no elimina al mayoritario |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Kadane falla con todos negativos» | Falla la versión con `max(0, …)`; con `best = a[0]` y `cur = max(x, cur + x)` acierta |
| «Para contar subarreglos hay que enumerarlos» | Con prefijos y un mapa se cuentan en `O(n)` esperado |
| «El circular es total menos el mínimo» | Excepto si todos son negativos, donde eso da el tramo vacío |
| «Boyer-Moore devuelve el mayoritario» | Devuelve un candidato; hay que comprobar que pasa de `n/2` |
| «En el mapa de prefijos se registra antes de contar» | Al revés: registrar antes cuenta el tramo vacío cuando `k = 0` |
| «El resto de un prefijo negativo sirve de clave» | En C++ y Java hay que normalizarlo a `[0, m)` |

---

## 📚 Para profundizar

- **Libro** — Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 8: la historia del
  subarreglo máximo, de cúbico a lineal. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §4.1: el subarreglo máximo por divide y vencerás, y el ejercicio que pide la versión lineal. *Lectura
  troncal.*
- **Referencia** — Codility, [lección 9, *Maximum slice problem*](https://app.codility.com/programmers/lessons/9-maximum_slice_problem/max_slice_sum/):
  el problema y su material de lectura.

---

## 🧠 Preguntas

1. Escribe la recurrencia de Kadane y di qué significa `best_end(i)`. 🟢
2. ¿Cuál es la fórmula del subarreglo máximo circular, y cuál es su excepción? 🟢
3. ¿Por qué el mapa de prefijos empieza con `{0: 1}`? 🟢
4. ¿Qué diferencia hay entre el Kadane con `max(0, cur + x)` y el de `max(x, cur + x)`? 🟡
5. ¿Qué diferencia hay entre contar subarreglos con suma `k` usando una ventana y usando prefijos con mapa? 🟡
6. ¿Por qué Boyer-Moore necesita una segunda pasada? 🟡
7. Demuestra por inducción que la recurrencia de Kadane calcula la mejor suma que termina en cada posición. 🟠
8. Compara las tres plantillas de conteo: ¿qué cambia en el mapa entre C++, Java y Python, y qué riesgo tiene el de C++ con datos adversarios? 🟠
9. ¿Por qué un tramo circular que da la vuelta es el complemento de uno normal, y qué pasa con el arreglo entero? 🟠
10. Para «subarreglos con suma divisible por `m`», ¿qué guardas en el mapa y por qué hay que normalizar el resto? 🟠
11. Escribe el invariante del voto de Boyer-Moore y demuestra que el mayoritario, si existe, es el candidato final. 🔴
12. Diseña cómo obtener la suma máxima de un subarreglo de longitud al menos `L`, con su coste. 🔴
13. El divide y vencerás del subarreglo máximo: escribe su recurrencia, resuélvela y explica qué calcula el paso de combinar. 🔴

---

## 🧩 Problemas propios

### El mejor periodo, con desempate

**Nivel:** 🟡 · **Formato:** programa completo.

Imprime la suma máxima de un tramo no vacío de días consecutivos, y su primer y último día (desde 1). Si
varios tramos tienen la suma máxima, el de inicio más temprano; y entre esos, el más corto.

- **Entrada.** Una línea con `n`. Una línea con los `n` beneficios.
- **Salida.** Tres enteros: la suma, el primer día y el último.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `|a[i]| ≤ 10⁹`.

```text
Entrada            Salida
7                  6 3 5
3 -4 5 -1 2 -6 4

Entrada            Salida
3                  -1 2 2
-3 -1 -2

Entrada            Salida
3                  2 1 1
2 -2 2
```

**Pista 1:** en el tercer ejemplo, ¿qué decide tu comparación cuando el tramo actual iguala al mejor?

### Al menos L días

**Nivel:** 🟠 · **Formato:** programa completo.

Imprime la mayor suma de un tramo de **al menos** `L` días consecutivos.

- **Entrada.** Una línea con `n` y `L`. Una línea con los `n` beneficios.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ L ≤ n ≤ 2·10⁵`; `|a[i]| ≤ 10⁹`.

```text
Entrada            Salida
7 3                6
3 -4 5 -1 2 -6 4

Entrada            Salida
6 6                28
5 2 9 1 5 6

Entrada            Salida
3 2                -3
-1 -2 -3
```

**Pista 1:** si el tramo termina en `j` y empieza en `i`, su suma es `P[j] − P[i]`: ¿qué `i` te conviene
entre los permitidos?

### Restos de los tramos

**Nivel:** 🟡 · **Formato:** programa completo.

Cuenta los tramos no vacíos cuya suma, dividida por `m`, deja resto `r`. El resto se toma en `[0, m)`,
también para sumas negativas (por ejemplo, el resto de −1 entre 3 es 2).

- **Entrada.** Una línea con `n`, `m` y `r`. Una línea con los `n` valores.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ m ≤ 10⁹`; `0 ≤ r < m`; `|a[i]| ≤ 10⁹`.

```text
Entrada            Salida
6 3 0              7
5 2 9 1 5 6

Entrada            Salida
7 3 1              8
3 -4 5 -1 2 -6 4

Entrada            Salida
2 2 1              2
1 2
```

**Pista 1:** si dos prefijos dejan restos `x` e `y`, ¿qué resto deja el tramo entre ellos?

---

## 🧩 Práctica externa

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [MaxSliceSum](https://app.codility.com/programmers/lessons/9-maximum_slice_problem/max_slice_sum/) | Codility | 🟢 | Kadane | ¿Qué devuelve tu solución si todos los valores son negativos? |
| [ ] | [MaxProfit](https://app.codility.com/programmers/lessons/9-maximum_slice_problem/max_profit/) | Codility | 🟢 | Mínimo acumulado | Para vender el día `i`, ¿qué día de compra te interesa? |
| [ ] | [Best Time to Buy and Sell Stock](https://leetcode.com/problems/best-time-to-buy-and-sell-stock/) | LeetCode | 🟢 | Mínimo acumulado | ¿Qué necesitas recordar de los días anteriores? |
| [ ] | [MaxDoubleSliceSum](https://app.codility.com/programmers/lessons/9-maximum_slice_problem/max_double_slice_sum/) | Codility | 🟡 | Kadane hacia los dos lados | Si fijas el elemento del medio, ¿qué dos cantidades combinas? |
| [ ] | [Maximum Sum Circular Subarray](https://leetcode.com/problems/maximum-sum-circular-subarray/) | LeetCode | 🟡 | Kadane circular | ¿Qué deja fuera un tramo que da la vuelta? |
| [ ] | [Maximum Product Subarray](https://leetcode.com/problems/maximum-product-subarray/) | LeetCode | 🟡 | Kadane con dos estados | Un negativo puede convertir el peor producto en el mejor: ¿qué guardas además del máximo? |
| [ ] | [Subarray Sum Equals K](https://leetcode.com/problems/subarray-sum-equals-k/) | LeetCode | 🟡 | Prefijos y mapa | ¿Qué prefijo anterior necesitas haber visto para que el tramo que termina aquí sume `k`? |
| [ ] | [The Maximum Subarray](https://www.hackerrank.com/challenges/maxsubarray/problem) | HackerRank | 🟡 | Kadane y subsecuencia | Si el subarreglo tiene que ser contiguo pero la subsecuencia no, ¿qué cambia para la segunda? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Maximum Subarray Sum](https://cses.fi/problemset/task/1643) | CSES | 🟢 | Kadane | ¿En qué tipo cabe la suma más grande posible? |
| [ ] | [Subarray Divisibility](https://cses.fi/problemset/task/1662) | CSES | 🟡 | Prefijos módulo `n` | ¿Cuándo dos prefijos delimitan un tramo divisible por `n`? |
| [ ] | [Subarray Sums Divisible by K](https://leetcode.com/problems/subarray-sums-divisible-by-k/) | LeetCode | 🟡 | Prefijos módulo `k` | ¿Qué haces con el resto de un prefijo negativo? |

---

## ✅ Criterio de dominio

- Escribir Kadane de memoria en su forma correcta y demostrar su recurrencia por inducción.
- Explicar la fórmula del circular con su excepción y el porqué del complemento.
- Escribir la plantilla de conteo con el prefijo vacío y el orden contar-después-registrar.
- Resolver MaxDoubleSliceSum y Subarray Sum Equals K sin pista 2.

---

**Anterior:** [`04/02` — Dos punteros y ventana deslizante](02-dos-punteros-y-ventana.md) ·
**Siguiente:** [`04/04` — Compresión de coordenadas y barrido de eventos](04-compresion-y-barrido.md) ·
**Relacionado:** [`12/02` — DP lineal y LIS](../12-dp-clasica/02-dp-lineal-y-lis.md); [`04/01` — Sumas de prefijos y diferencias](01-prefijos-y-diferencias.md).
