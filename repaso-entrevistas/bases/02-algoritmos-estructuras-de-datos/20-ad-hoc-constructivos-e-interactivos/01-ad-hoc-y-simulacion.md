# 01 — Ad hoc y simulación

> Los problemas que no tienen nombre de técnica: los que se resuelven encontrando algo que no cambia (un
> invariante, casi siempre una paridad) y los que se resuelven haciendo exactamente lo que dice el enunciado,
> con cuidado. Cómo se demuestra que algo es imposible sin probar todos los caminos, y cuándo una simulación
> cabe en las restricciones o necesita saltarse un ciclo.
>
> **Niveles:** invariantes y paridad [A] · simulación [A].
>
> **📚 Lectura troncal:** Halim, Halim y Effendy, *Competitive Programming 4*, libro 1 (2020), cap. 1 (ad hoc);
> Engel, *Problem-Solving Strategies* (Springer, 1998), cap. 1 (el principio de invariancia).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--invariantes-y-paridad) · [4](#4--simulación) · [5](#5-️-la-tabla-de-costes) · [6](#6--cómo-se-elige) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

En una pizarra están escritos los números del 1 al `n`. En cada paso se borran dos y se escribe el valor
absoluto de su diferencia. Al final queda un número. ¿Puede ser 0? Con `n = 5` hay miles de órdenes
posibles; con `n = 100`, más que átomos en el universo. Y la respuesta sale en una línea: la **paridad de la
suma** no cambia nunca (`a + b` y `|a − b|` tienen la misma paridad), así que el último número tiene la
paridad de `1 + 2 + … + n`. Con `n = 5` la suma es 15, impar: el 0 es imposible.

Eso es un **invariante**: una cantidad que ninguna jugada cambia. Es la herramienta de los problemas «ad hoc»,
los que no se parecen a nada del corpus. La otra mitad de esos problemas es la **simulación**: hacer lo que
dice el enunciado, paso a paso, sin equivocarse en ningún detalle, y comprobar antes que el número de pasos
cabe en el tiempo.

> 🧠 **Modelo mental.** Ante un proceso con reglas, pregunta primero qué **no** cambia (invariante) y qué
> **solo** crece o decrece (monovariante). El primero demuestra imposibilidades; el segundo, que el proceso
> termina.

---

## 2. 📐 La teoría

**Invariante.** Una función del estado que ninguna operación permitida cambia. Si el estado inicial y el
objetivo tienen valores distintos del invariante, el objetivo es **inalcanzable**, sin necesidad de explorar
ningún camino.

**Monovariante.** Una función que cada operación cambia siempre en el mismo sentido (estrictamente). Si además
está acotada, el proceso **termina**: es el argumento de terminación de los bucles ([`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md)).

**Los invariantes más frecuentes:**

| Invariante | Cuándo aparece |
|---|---|
| Paridad de una suma o de un conteo | Operaciones que cambian dos cosas a la vez |
| Paridad de una permutación | Intercambios de dos elementos (cada uno cambia la paridad) |
| Coloración del tablero | Fichas que cubren casillas de colores fijos (dominós, trominós) |
| Resto módulo `k` | Operaciones que suman o restan múltiplos de `k` |
| `gcd` de los valores | Operaciones del tipo `a ← a − b` |

**Un invariante no basta para decir «sí».** Demuestra que algo es imposible; para demostrar que es posible
hace falta una **construcción** ([`20/02`](02-constructivos.md)). En la pizarra, con la suma par el 0 sí se
alcanza, pero eso se demuestra construyendo la secuencia de jugadas.

**Simulación y ciclos.** Si un proceso determinista tiene un número finito de estados `S`, a partir de algún
paso se repite: hay un prefijo de longitud `μ` y un ciclo de longitud `λ`, con `μ + λ ≤ S`. El estado tras
`K` pasos, con `K` enorme, es el del paso `μ + (K − μ) mod λ`.

---

## 3. 🧱 Invariantes y paridad

**Qué es.** Encontrar una cantidad que las operaciones conservan y usarla para decidir si el objetivo es
alcanzable.

**Por qué es correcto.** Por inducción sobre el número de operaciones: si cada operación conserva el
invariante, cualquier secuencia lo conserva. Un estado con otro valor no se alcanza nunca.

**Cómo va**, con el tablero de ajedrez sin dos esquinas opuestas: ¿se cubre con 31 dominós?

```text
cada dominó cubre una casilla blanca y una negra       → invariante: blancas cubiertas = negras cubiertas
las dos esquinas opuestas son del mismo color          → quedan 32 de un color y 30 del otro
31 dominós cubrirían 31 y 31                            → imposible, sin probar ninguna colocación
```

**Cuánto.** Calcular el invariante suele ser `O(n)`: una suma, un conteo, la paridad de una permutación.

**La plantilla.** Los invariantes no tienen plantilla; lo que se reutiliza es calcularlos. La paridad de una
permutación, en Java (el capítulo usa Java, como fija su ficha):

```java
// Paridad de una permutación de 0..n−1: 0 si par, 1 si impar. n − (número de ciclos) intercambios.
static int permutationParity(int[] p) {
    boolean[] seen = new boolean[p.length];
    int cycles = 0;
    for (int i = 0; i < p.length; i++) {
        if (seen[i]) continue;
        cycles++;
        for (int j = i; !seen[j]; j = p[j]) seen[j] = true;
    }
    return (p.length - cycles) % 2;
}
```

- **Un ciclo de longitud `L` se deshace con `L − 1` intercambios**: la permutación necesita `n − ciclos` en
  total, y cada intercambio cambia la paridad. Por eso dos permutaciones de paridad distinta no se
  transforman una en otra con un número par de intercambios.
- **`O(n)`**, sin contar inversiones (que serían `O(n log n)`).

### De la versión ingenua a la buena

**El problema.** La pizarra con los números del 1 al `n`: ¿puede quedar 0?

**La versión ingenua**, una búsqueda sobre todos los estados:

```java
// Correcta: explora todos los multiconjuntos alcanzables. Exponencial: con n = 12 ya no termina.
static boolean canReachZero(java.util.List<Integer> nums, java.util.Map<java.util.List<Integer>, Boolean> memo) {
    if (nums.size() == 1) return nums.get(0) == 0;
    java.util.List<Integer> key = new java.util.ArrayList<>(nums);
    java.util.Collections.sort(key);
    Boolean cached = memo.get(key);
    if (cached != null) return cached;
    boolean ok = false;
    for (int i = 0; i < key.size() && !ok; i++)
        for (int j = i + 1; j < key.size() && !ok; j++) {
            java.util.List<Integer> next = new java.util.ArrayList<>(key);
            next.remove(j); next.remove(i);
            next.add(Math.abs(key.get(i) - key.get(j)));
            ok = canReachZero(next, memo);
        }
    memo.put(key, ok);
    return ok;
}
```

> «Esto explora todas las jugadas, y el número de estados crece de forma exponencial. Pero `a + b` y
> `|a − b|` tienen la misma paridad: la suma de la pizarra conserva su paridad, y el último número la hereda.
> Si `n(n + 1)/2` es impar, el 0 es imposible. Si es par, se puede construir.»

**El camino a la buena.** El invariante para el «no»; para el «sí», una construcción (agrupar de cuatro en
cuatro: `(k, k+1, k+2, k+3)` deja `1 − 1 = 0`). La búsqueda exhaustiva confirma para `n ≤ 8` que el 0 se
alcanza exactamente cuando la suma es par.

**Cuándo sí:** «¿se puede llegar de A a B con estas operaciones?», «¿se puede cubrir?», «¿quién gana?» en
juegos con jugadas simétricas. **Cuándo no:** cuando el invariante coincide en A y B: entonces no dice nada, y
hace falta construir o buscar.

> **Veredicto:** «no hay técnica» casi nunca es cierto: hay un invariante. Busca qué no cambia antes de
> buscar caminos; demuestra el «no» con él y el «sí» con una construcción.

---

## 4. 🧱 Simulación

**Qué es.** Hacer lo que dice el enunciado, paso a paso, con un estado bien elegido; y, si el número de pasos
es enorme, detectar el ciclo y saltarlo.

**Por qué es correcto.** Por definición: el programa reproduce las reglas. Lo que puede fallar es el coste y
los detalles (el orden de las actualizaciones, los bordes, las unidades). Para saltar ciclos, el argumento de
§2: el estado del paso `K` es el del paso `μ + (K − μ) mod λ`.

**Cómo va**, con el proceso `x ← (x² + 1) mod 10` desde `x₀ = 0` y `K = 10¹⁸` pasos:

```text
0 → 1 → 2 → 5 → 6 → 7 → 0 → …        el 0 reaparece en el paso 6: μ = 0, λ = 6
10¹⁸ mod 6 = 4  → el estado del paso 4: 6
```

**Cuánto.** Sin ciclos, el número de pasos por el coste de cada uno. Con detección de ciclos, como mucho
`μ + λ ≤ S` pasos (el número de estados distintos) más una tabla de estados vistos.

**La plantilla**, en Java:

```java
// Estado tras k aplicaciones de f desde x0, saltando el ciclo. Los estados se guardan en un mapa.
static long iterate(long x0, long k, java.util.function.LongUnaryOperator f) {
    java.util.Map<Long, Long> firstSeen = new java.util.HashMap<>();
    long x = x0;
    for (long step = 0; step < k; step++) {
        Long prev = firstSeen.putIfAbsent(x, step);
        if (prev != null) {                                   // el estado x ya salió en el paso prev
            long cycle = step - prev;
            long remaining = (k - step) % cycle;
            for (long r = 0; r < remaining; r++) x = f.applyAsLong(x);
            return x;
        }
        x = f.applyAsLong(x);
    }
    return x;
}
```

- **El estado tiene que ser completo**: todo lo que influye en el paso siguiente (posición **y** dirección,
  tablero **y** turno). Si falta algo, el «ciclo» detectado es falso.
- **Con un mapa** se guarda el paso de cada estado: memoria `O(μ + λ)`. Con el algoritmo de Floyd (liebre y
  tortuga, [`06/06`](../06-lineales-y-hashing/06-respuestas.md)) basta memoria `O(1)`, a cambio de más
  evaluaciones.
- **Estados grandes** (un tablero) se codifican como cadena o como un *hash* del contenido; con el *hash*,
  hay que confirmar la igualdad al encontrar un repetido.

### De la versión ingenua a la buena

**El problema.** El estado de `x ← (x² + 1) mod 10` tras `K = 10¹⁸` pasos.

**La versión ingenua:**

```java
// Correcta: aplica f k veces. Con k = 10¹⁸, unos 30 años.
static long iterateNaive(long x0, long k, java.util.function.LongUnaryOperator f) {
    long x = x0;
    for (long step = 0; step < k; step++) x = f.applyAsLong(x);
    return x;
}
```

> «Esto hace `10¹⁸` pasos. Pero el estado solo puede tomar 10 valores: se repite en como mucho 10 pasos, y a
> partir de ahí todo es periódico. Guardo en qué paso vi cada estado y, al ver uno repetido, salto
> `(K − paso) mod ciclo`.»

**El camino a la buena.** La plantilla `iterate`: como mucho `S` pasos más el resto del ciclo.

**Cuándo sí:** cuando el enunciado describe un proceso y las restricciones permiten seguirlo; con `K` enorme
y pocos estados, saltando el ciclo. **Cuándo no:** si el número de estados es enorme y no se repiten (una
posición que crece sin límite): hay que encontrar una fórmula o una regularidad distinta del ciclo.

> **Veredicto:** simular es la solución correcta más a menudo de lo que parece; el trabajo está en contar los
> pasos antes de escribir y en elegir un estado completo. Si los pasos no caben, busca el ciclo.

---

## 5. ⏱️ La tabla de costes

| Técnica | Coste | Lo que la tabla no dice |
|---|---|---|
| Comprobar un invariante | `O(n)` normalmente | Solo demuestra el «no» |
| Paridad de una permutación | `O(n)` por ciclos | Contar inversiones da lo mismo en `O(n log n)` |
| Simulación directa | pasos × coste del paso | Contarlos antes de escribir |
| Simulación con ciclo (mapa) | `O(S)` pasos, `O(S)` memoria | El estado tiene que ser completo |
| Simulación con ciclo (Floyd) | `O(μ + λ)` evaluaciones, `O(1)` memoria | Unas tres veces más evaluaciones |

---

## 6. 🧭 Cómo se elige

```text
¿«Se puede llegar a…?» con operaciones dadas? → invariante para el no; construcción para el sí
¿El enunciado describe un proceso paso a paso? → cuenta los pasos: si caben, simula
¿Pasos enormes y pocos estados posibles? → simula hasta repetir y salta el ciclo
¿Pasos enormes y estados que no se repiten? → fórmula, o simular por bloques
```

> **Regla de entrevista:** si un problema no se parece a nada, di en voz alta «busco qué no cambia» y prueba
> las tres primeras candidatas: paridad de la suma, paridad del número de algo, resto módulo algo.

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Es posible llegar a…?» con operaciones que tocan dos cosas a la vez | Paridad | Cambian dos cosas: la paridad se conserva |
| Tableros y fichas que cubren casillas | Coloración | Cada ficha cubre colores fijos |
| «Intercambia dos elementos» | Paridad de la permutación | Cada intercambio la cambia |
| «Tras `10¹⁸` segundos / rondas» | Ciclo | Pocos estados, muchos pasos |
| Reglas largas, restricciones pequeñas | Simulación directa | Lo difícil es no equivocarse |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Si no hay técnica, no hay método» | Hay método: invariante, monovariante, simulación con estado completo |
| «El invariante coincide, así que se puede» | El invariante solo demuestra el «no»; el «sí» necesita una construcción |
| «Simular es de principiantes» | Es la solución correcta cuando los pasos caben; el riesgo está en los detalles |
| «El ciclo empieza en el primer estado» | Puede haber un prefijo `μ` antes del ciclo |
| «Para detectar el ciclo basta guardar la posición» | El estado incluye todo lo que influye en el paso siguiente (dirección, turno…) |
| «`10¹⁸` pasos con un bucle simple tardan un rato» | Tardan décadas: hay que saltar el ciclo |

---

## 📚 Para profundizar

- **Libro** — Halim, Halim y Effendy, *Competitive Programming 4*, libro 1 (2020), cap. 1: problemas ad hoc
  por categorías. *Lectura troncal.*
- **Libro** — Engel, *Problem-Solving Strategies* (Springer, 1998), cap. 1: el principio de invariancia, con
  decenas de ejemplos resueltos. *Lectura troncal.*
- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 2, 3.ª ed. (Addison-Wesley, 1997), §3.1,
  ejercicio 6: el algoritmo de Floyd para detectar el ciclo de una secuencia con memoria constante.

---

## 🧠 Preguntas

1. ¿Qué es un invariante y qué permite demostrar? 🟢
2. ¿Qué es un monovariante y para qué sirve? 🟢
3. ¿Por qué el tablero sin dos esquinas opuestas no se cubre con dominós? 🟢
4. ¿Qué diferencia hay entre demostrar que algo es imposible y demostrar que es posible? 🟡
5. ¿Cómo se calcula la paridad de una permutación, y por qué funciona? 🟡
6. ¿Qué es el prefijo `μ` y el ciclo `λ` de un proceso determinista? 🟡
7. ¿Qué tiene que contener el estado para que la detección de ciclos sea correcta? 🟠
8. ¿Qué cambia entre guardar los estados en un mapa y usar el algoritmo de Floyd? 🟠
9. ¿Cómo decides si una simulación directa cabe en el tiempo? 🟠
10. ¿Qué cambia entre Java, C++ y Python para guardar estados grandes (un tablero) en un mapa? 🟠
11. Demuestra que, en la pizarra con los números del 1 al `n`, el último número tiene la paridad de
    `n(n + 1)/2`. 🔴
12. Una ficha se mueve como un caballo de ajedrez. Demuestra que no puede volver a su casilla en un número
    impar de movimientos. 🔴

---

## 🧩 Problemas propios

### Monedas de dos en dos

**Nivel:** 🟡 · **Formato:** programa completo.

Hay `n` monedas en fila, cada una cara (`H`) o cruz (`T`). Una operación da la vuelta a dos monedas
**vecinas**. Imprime el menor número de operaciones para dejar todas en cara, o `-1` si es imposible.

- **Entrada.** Una línea con la fila de monedas.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 10⁶`.

```text
Entrada         Salida
THHTTH          -1

Entrada         Salida
HTHHHT          4
```

**Pista 1:** ¿qué le pasa al número de cruces con cada operación, y qué dice eso del primer ejemplo?

### El anillo de luces

**Nivel:** 🟠 · **Formato:** programa completo.

Un anillo de `n` luces está encendido (`1`) o apagado (`0`). En cada segundo, cada luz pasa a valer el XOR de
sus dos vecinas en el segundo anterior (la luz `0` es vecina de la `n − 1`). Imprime el anillo tras `K`
segundos.

- **Entrada.** Una línea con `n` y `K`. Una línea con las `n` luces.
- **Salida.** Una línea con las `n` luces.
- **Restricciones.** `3 ≤ n ≤ 20`; `0 ≤ K ≤ 10¹⁸`.

```text
Entrada         Salida
4 1             0101
1000

Entrada                   Salida
5 1000000000000000000     00011
10100
```

**Pista 1:** ¿cuántos estados distintos puede tener el anillo con `n ≤ 20`, y qué pasa con la secuencia de
estados cuando uno se repite?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de simular, escribe el número de pasos que vas a dar y multiplícalo por el coste de
> cada uno. Si una IA te ayuda, que sea a encontrar candidatos a invariante, no la solución
> ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). Advent of Code no tiene juez de
> tiempo: el límite lo pones tú, y la segunda parte de cada día suele exigir saltar un ciclo.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Number Line Jumps](https://www.hackerrank.com/challenges/kangaroo/problem) | HackerRank | 🟢 | Invariante de la distancia | ¿Cómo cambia la distancia entre los dos canguros en cada salto? |
| [ ] | [Save the Prisoner!](https://www.hackerrank.com/challenges/save-the-prisoner/problem) | HackerRank | 🟢 | Simulación con módulo | Si repartes `m` caramelos en un círculo de `n` sillas, ¿qué parte del reparto da vueltas completas? |
| [ ] | [Bulb Switcher](https://leetcode.com/problems/bulb-switcher/) | LeetCode | 🟡 | Paridad de divisores | ¿Cuántas veces se toca la bombilla `i`, y cuándo es ese número impar? |
| [ ] | [Robot Bounded In Circle](https://leetcode.com/problems/robot-bounded-in-circle/) | LeetCode | 🟡 | Simulación de cuatro vueltas | Tras ejecutar las órdenes una vez, ¿qué dos datos del robot deciden si se queda en un círculo? |
| [ ] | [Walking Robot Simulation](https://leetcode.com/problems/walking-robot-simulation/) | LeetCode | 🟡 | Simulación con obstáculos | ¿Cómo compruebas en `O(1)` si la casilla siguiente es un obstáculo? |
| [ ] | [Prison Cells After N Days](https://leetcode.com/problems/prison-cells-after-n-days/) | LeetCode | 🟡 | Ciclo | ¿Cuántos estados distintos pueden tener 8 celdas, y qué haces con `n = 10⁹`? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Flip the Bits](https://codeforces.com/problemset/problem/1504/B) | Codeforces | 🟡 | Invariante de los prefijos | ¿Qué prefijos se pueden invertir, y qué tiene que pasar en cada tramo entre dos de ellos? |
| [ ] | [Regolith Reservoir](https://adventofcode.com/2022/day/14) | Advent of Code | 🟡 | Simulación | ¿Qué estructura guarda las casillas ocupadas, y cuándo deja de caer arena? |
| [ ] | [Parabolic Reflector Dish](https://adventofcode.com/2023/day/14) | Advent of Code | 🟠 | Ciclo | En la segunda parte, ¿cuántos ciclos de inclinación hacen falta antes de que el tablero se repita? |
| [ ] | [Pyroclastic Flow](https://adventofcode.com/2022/day/17) | Advent of Code | 🔴 | Ciclo con estado completo | ¿Qué tiene que incluir el estado (pieza, posición en el viento, forma de la superficie) para que la repetición sea real? |

---

## ✅ Criterio de dominio

- Encontrar el invariante de paridad de un proceso y usarlo para demostrar una imposibilidad.
- Escribir la detección de ciclos con un mapa en Java sin mirar.
- Decir antes de escribir si una simulación cabe, contando pasos.
- Resolver Bulb Switcher, Robot Bounded In Circle y Prison Cells After N Days sin pista 2.

---

**Anterior:** — · **Siguiente:** [`20/02` — Constructivos](02-constructivos.md) ·
**Relacionado:** [`02/04` — Corrección: invariante de bucle, inducción y argumento de intercambio](../02-analisis/04-correccion-invariantes-induccion-intercambio.md).
