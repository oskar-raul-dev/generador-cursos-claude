# 02 — Constructivos

> Problemas que piden **fabricar** algo —una permutación, una tabla, un calendario— que cumpla una
> condición, o decir que no existe. Cómo se diseña la construcción (casi siempre por inducción, de `n` a
> `n + 1` o `n + 2`), cómo se demuestra que cumple, cómo se demuestra que en los casos pequeños no hay
> solución, y cómo se comprueba con un verificador antes de enviar.
>
> **Niveles:** constructivos [B].
>
> **📚 Lectura troncal:** Engel, *Problem-Solving Strategies* (Springer, 1998), caps. 1–2; cp-algorithms.
>
> **Asume leído:** [`20/01` — Ad hoc y simulación](01-ad-hoc-y-simulacion.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--constructivos) · [4](#4-️-la-tabla-de-costes) · [5](#5--cómo-se-elige) · [6](#6--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Hay que organizar una liga de `n` equipos: todos contra todos, una vez, en el menor número de jornadas, sin
que nadie juegue dos partidos en la misma jornada. No hay nada que buscar ni que optimizar con una técnica
conocida: hay que **inventar** el calendario y demostrar que funciona. Con `n` par bastan `n − 1` jornadas, y
hay una construcción de una línea: fijar un equipo y hacer girar a los demás en círculo.

Los problemas constructivos tienen fama de fáciles porque «aceptan cualquier respuesta». Es al revés: no hay
un algoritmo que copiar, y la respuesta hay que diseñarla, demostrarla y, muchas veces, saber cuándo no
existe.

> 🧠 **Modelo mental.** Una construcción es una demostración por inducción escrita como código: resuelve los
> casos pequeños a mano y muestra cómo pasar de `n` a `n + 1` (o a `n + 2`) sin romper la condición.

---

## 2. 📐 La teoría

**Construir por inducción.** Para una familia de problemas indexada por `n`:

1. **Base:** los casos pequeños, a mano o por fuerza bruta; incluido decir cuáles no tienen solución.
2. **Paso:** cómo extender una solución de tamaño `n` a una de tamaño `n + 1` (o `n + 2`, si la paridad
   importa) conservando la condición.
3. **Código:** el paso inductivo, ejecutado en bucle.

**Demostrar que no existe.** Con un invariante ([`20/01`](01-ad-hoc-y-simulacion.md)) o con una cuenta: si la
condición exige más recursos de los que hay (más partidos de los que caben en las jornadas, más diferencias
distintas de las que permite el rango), no hay solución.

**El calendario de la liga** (método del círculo). Con `n` par, se fija el equipo `n − 1` y los demás, `0` a
`n − 2`, se colocan en un círculo. En la jornada `r`, el fijo juega contra `r`, y para `k = 1, …, n/2 − 1`, el
equipo `(r + k) mod (n − 1)` juega contra `(r − k) mod (n − 1)`. Cada par se encuentra exactamente una vez en
las `n − 1` jornadas: dos equipos `a ≠ b` del círculo juegan en la única jornada `r` con `2r ≡ a + b (mod
n − 1)`, que existe y es única porque `n − 1` es impar. Con `n` impar, se añade un equipo ficticio: quien juega
contra él, descansa.

**Cota.** Cada jornada tiene como mucho `n/2` partidos y hay `n(n − 1)/2`: hacen falta al menos `n − 1`
jornadas. La construcción alcanza la cota: es óptima.

---

## 3. 🧱 Constructivos

**Qué es.** Diseñar una salida que cumpla una condición, demostrar que la cumple, y decidir cuándo no existe.

**Por qué es correcto.** Cada construcción lleva su prueba: inducción sobre `n`, o un argumento directo como el
del calendario. La imposibilidad, con un invariante o una cuenta.

**Cómo va**, el calendario con `n = 4` (el fijo es el 3, el círculo es `0, 1, 2`):

```text
jornada 0:  3–0   (1, 2)        1 = 0 + 1, 2 = 0 − 1 mod 3
jornada 1:  3–1   (2, 0)
jornada 2:  3–2   (0, 1)
→ los 6 pares, cada uno una vez, en 3 jornadas (la cota n − 1)
```

**Cuánto.** `Θ(n²)`: es el tamaño de la salida.

**La plantilla**, con el verificador al lado: en un constructivo, el verificador es la mitad del trabajo.

```cpp
#include <utility>
#include <vector>

// Calendario de todos contra todos con n par: n − 1 jornadas de n/2 partidos.
std::vector<std::vector<std::pair<int, int>>> roundRobin(int n) {
    int m = n - 1;                                         // equipos del círculo: 0 .. n − 2
    std::vector<std::vector<std::pair<int, int>>> rounds(m);
    for (int r = 0; r < m; r++) {
        rounds[r].push_back({r, n - 1});                   // el fijo contra r
        for (int k = 1; k < n / 2; k++)
            rounds[r].push_back({(r + k) % m, (r - k + m) % m});
    }
    return rounds;
}

// Verificador: cada par exactamente una vez y nadie dos veces en la misma jornada.
bool checkRoundRobin(int n, const std::vector<std::vector<std::pair<int, int>>>& rounds) {
    std::vector<std::vector<int>> met(n, std::vector<int>(n, 0));
    for (const auto& round : rounds) {
        std::vector<bool> busy(n, false);
        for (auto [a, b] : round) {
            if (a == b || busy[a] || busy[b]) return false;
            busy[a] = busy[b] = true;
            met[a][b]++; met[b][a]++;
        }
    }
    for (int a = 0; a < n; a++)
        for (int b = a + 1; b < n; b++)
            if (met[a][b] != 1) return false;
    return true;
}
```

```java
static int[][][] roundRobin(int n) {
    int m = n - 1;
    int[][][] rounds = new int[m][n / 2][];
    for (int r = 0; r < m; r++) {
        rounds[r][0] = new int[]{r, n - 1};
        for (int k = 1; k < n / 2; k++)
            rounds[r][k] = new int[]{(r + k) % m, (r - k + m) % m};
    }
    return rounds;
}

static boolean checkRoundRobin(int n, int[][][] rounds) {
    int[][] met = new int[n][n];
    for (int[][] round : rounds) {
        boolean[] busy = new boolean[n];
        for (int[] g : round) {
            int a = g[0], b = g[1];
            if (a == b || busy[a] || busy[b]) return false;
            busy[a] = busy[b] = true;
            met[a][b]++; met[b][a]++;
        }
    }
    for (int a = 0; a < n; a++)
        for (int b = a + 1; b < n; b++)
            if (met[a][b] != 1) return false;
    return true;
}
```

- **`(r − k + m) % m`**: en C++ y Java, `%` de un negativo es negativo; se suma `m` antes.
- **El verificador comprueba la condición del enunciado, no la construcción**: así detecta errores en la idea,
  no solo en el código. Con él, un *stress test* sobre todos los `n` pequeños
  ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)) da confianza antes de enviar.
- **`n` impar**: se llama con `n + 1` y el partido contra `n` es un descanso.

**Cuándo sí:** «construye», «imprime cualquier», «si no existe, imprime `-1`» o `NO`; permutaciones con
propiedades, tablas, calendarios, grafos con grados dados. **Cuándo no:** si el enunciado pide la **mejor**
construcción y no hay una cota que la certifique, puede ser un problema de optimización disfrazado (DP,
voraz, o heurístico, [`20/05`](05-heuristicos-y-aproximados.md)).

> **Veredicto:** un constructivo se resuelve en papel: casos pequeños, patrón, prueba por inducción, cota que
> dice cuándo no existe. El código es corto; el verificador, obligatorio.

---

## 4. ⏱️ La tabla de costes

| Paso | Coste | Lo que la tabla no dice |
|---|---|---|
| Fuerza bruta de los casos pequeños | `n!` o `2ⁿ` con `n ≤ 8–10` | Es la fuente del patrón y de los casos sin solución |
| La construcción | Normalmente el tamaño de la salida | El coste está en la idea, no en el código |
| El verificador | Normalmente el tamaño de la salida | Comprueba la condición, no la construcción |

---

## 5. 🧭 Cómo se elige

```text
1. Fuerza bruta para n ≤ 8: ¿para qué n hay solución? ¿qué forma tienen?
2. ¿Hay una cuenta o un invariante que explique los n sin solución?
3. ¿Se pasa de n a n + 1 o n + 2 sin romper la condición? → construcción inductiva
4. Verificador + stress test sobre todos los n pequeños antes de enviar
```

> **Regla de entrevista:** en un constructivo, enseña primero los casos pequeños en la pizarra y el patrón que
> ves; el código viene después, y el verificador antes de decir «está».

---

## 6. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Imprime cualquier permutación / tabla / grafo que cumpla…» | Construcción | No hay respuesta única que calcular |
| «Si no existe, imprime `-1`» | Construcción + imposibilidad | Hay casos sin solución que explicar |
| Restricciones con `n` hasta `10⁵` y salida de tamaño `n` | Construcción lineal | No cabe ninguna búsqueda |
| «Todos contra todos», «cada par una vez» | Método del círculo | `n − 1` jornadas con `n` par |
| Condiciones sobre vecinos o diferencias | Separar por paridad o intercalar | Pares e impares no son vecinos consecutivos |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si hay muchas respuestas, es más fácil» | Hay que diseñar una y demostrarla: no hay algoritmo que copiar |
| «La construcción funciona con los ejemplos, así que funciona» | Hace falta la prueba, o al menos un verificador con todos los `n` pequeños |
| «Si para `n = 5` funciona, para `n = 2` también» | Los casos pequeños suelen ser excepciones: `n = 2, 3, 4` sin solución es frecuente |
| «Para demostrar que no existe hay que probarlo todo» | Una cuenta o un invariante bastan |
| «El juez compara con la respuesta oficial» | Usa un verificador (*checker*): cualquier respuesta válida se acepta |
| «La primera construcción que funciona es la buena» | Si el enunciado pide la mínima, hace falta una cota que la certifique |

---

## 📚 Para profundizar

- **Libro** — Engel, *Problem-Solving Strategies* (Springer, 1998), caps. 1 (invariantes) y 2 (coloraciones):
  las imposibilidades y las construcciones. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Gray code*](https://cp-algorithms.com/algebra/gray-code.html): una
  construcción inductiva clásica (reflejar y prefijar). *Lectura troncal.*
- **Libro** — Halim, Halim y Effendy, *Competitive Programming 4*, libro 1 (2020), cap. 1: problemas ad hoc y
  constructivos por categorías.

---

## 🧠 Preguntas

1. ¿Qué pide un problema constructivo y qué tiene que acompañar a la respuesta? 🟢
2. ¿Cuántas jornadas necesita una liga de `n` equipos, con `n` par, y por qué no menos? 🟢
3. ¿Cómo comprueba un juez una respuesta constructiva? 🟢
4. ¿Qué papel tiene la fuerza bruta en un problema constructivo? 🟡
5. ¿Qué diferencia hay entre demostrar que tu construcción cumple y demostrar que no hay solución? 🟡
6. ¿Por qué un verificador debe comprobar la condición y no la construcción? 🟡
7. ¿Qué cambia entre C++, Java y Python al calcular `(r − k) mod m` en el calendario? 🟠
8. ¿Cómo adaptas el calendario cuando `n` es impar? 🟠
9. «Si hay muchas respuestas, es más fácil.» ¿Qué respondes? 🟠
10. ¿Cómo construyes una secuencia de Gray de `n` bits por inducción? 🟠
11. Demuestra que el método del círculo hace que cada par de equipos juegue exactamente una vez. 🔴
12. Demuestra que no se pueden sentar 4 personas numeradas del 1 al 4 en una mesa redonda sin que dos
    números consecutivos queden juntos. 🔴

---

## 🧩 Problemas propios

### Ninguna es suma de otras dos

**Nivel:** 🟢 · **Formato:** programa completo; se acepta cualquier respuesta válida.

Imprime `n` enteros positivos distintos, como mucho `10⁹`, tales que ninguno sea igual a la suma de otros dos
de la lista.

- **Entrada.** Un entero `n`.
- **Salida.** Una línea con `n` enteros.
- **Restricciones.** `1 ≤ n ≤ 10⁵`.

```text
Entrada         Una salida válida
3               3 4 5
```

**Pista 1:** si todos los números son mayores que la mitad del más grande, ¿cuánto vale como mínimo la suma de
dos de ellos?

### La mesa sin conocidos

**Nivel:** 🟡 · **Formato:** programa completo; se acepta cualquier respuesta válida.

`n` personas numeradas del 1 al `n` se sientan en una mesa redonda. Las personas con números consecutivos se
conocen y no quieren sentarse juntas. Imprime un orden de la mesa (el último es vecino del primero) en el que
ningún par de vecinos tenga números consecutivos, o `NO` si no existe.

- **Entrada.** Un entero `n`.
- **Salida.** `n` números, o `NO`.
- **Restricciones.** `1 ≤ n ≤ 10⁶`.

```text
Entrada         Salida
4               NO

Entrada         Una salida válida
6               2 4 6 1 3 5
```

**Pista 1:** ¿qué tienen los números pares entre sí, y qué pasa en los dos puntos donde se juntan pares e
impares? Prueba a mano los `n` hasta 5.

---

## 🧩 Práctica externa

> 💡 **Truco.** Escribe el verificador antes que la construcción y pásalo por todos los `n` hasta 10. Si una IA
> te ayuda, que sea a escribir la fuerza bruta de los casos pequeños, no la construcción
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Gray Code](https://leetcode.com/problems/gray-code/) | LeetCode | 🟡 | Inducción: reflejar | Si tienes la secuencia de `n − 1` bits, ¿qué obtienes al recorrerla al revés con un 1 delante? |
| [ ] | [Circular Permutation in Binary Representation](https://leetcode.com/problems/circular-permutation-in-binary-representation/) | LeetCode | 🟡 | Gray desplazado | Si tienes una secuencia de Gray que empieza en 0, ¿cómo la conviertes en una que empiece en `start`? |
| [ ] | [Beautiful Arrangement II](https://leetcode.com/problems/beautiful-arrangement-ii/) | LeetCode | 🟡 | Intercalar extremos | Si alternas el menor y el mayor de los que quedan, ¿cuántas diferencias distintas aparecen? |
| [ ] | [Monotone Subsequences](https://cses.fi/problemset/task/2215) | CSES | 🟡 | Bloques decrecientes | Si partes la permutación en bloques decrecientes y los pones en orden creciente, ¿cuánto miden la subsecuencia creciente y la decreciente más largas? |
| [ ] | [Inverse Inversions](https://cses.fi/problemset/task/2214) | CSES | 🟡 | Voraz por posiciones | Si colocas el mayor que queda al principio, ¿cuántas inversiones crea? |
| [ ] | [Special Permutation](https://codeforces.com/problemset/problem/1352/G) | Codeforces | 🟡 | Impares y pares | ¿Qué pasa si recorres los impares de mayor a menor y después los pares, y dónde se juntan? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Third Permutation](https://cses.fi/problemset/task/3422) | CSES | 🟠 | Desplazamiento cíclico | Si una permutación desplazada choca con las dos dadas en alguna posición, ¿cuántos desplazamientos puedes probar? |
| [ ] | [Chess Tournament](https://cses.fi/problemset/task/1697) | CSES | 🟠 | Voraz por el mayor | Si el que más partidas quiere jugar las juega contra los siguientes que más quieren, ¿qué condición falla cuando no existe? |
| [ ] | [Filling Trominos](https://cses.fi/problemset/task/2423) | CSES | 🔴 | Bloques y casos pequeños | ¿Qué rectángulos pequeños se llenan con trominós en L, y cómo pegas varios? |
| [ ] | [Grid Path Construction](https://cses.fi/problemset/task/2418) | CSES | 🔴 | Paridad y casos | Colorea la rejilla como un tablero de ajedrez: ¿qué dice el color del inicio y del final sobre si existe el camino? |

---

## ✅ Criterio de dominio

- Resolver un constructivo en papel: casos pequeños, patrón, prueba e imposibilidad.
- Escribir el calendario de la liga y su verificador en C++ o Java sin mirar.
- Explicar por qué el juez usa un verificador y por qué tú también deberías.
- Resolver Gray Code, Monotone Subsequences y Special Permutation sin pista 2.

---

**Anterior:** [`20/01` — Ad hoc y simulación](01-ad-hoc-y-simulacion.md) · **Siguiente:** [`20/03` — Interactivos](03-interactivos.md) ·
**Relacionado:** [`17/01` — Bits](../17-matematica/01-bits.md).
