# 01 — Las Vegas y Monte Carlo

> Los dos tipos de algoritmo aleatorizado: Las Vegas, que siempre acierta y cuyo tiempo es aleatorio, y
> Monte Carlo, que tarda siempre lo mismo y puede equivocarse con una probabilidad acotada. Cómo se acota el
> tiempo esperado (*quicksort* con pivote aleatorio), cómo se reduce el error repitiendo (Freivalds,
> Miller-Rabin), y por qué una semilla fija convierte un algoritmo aleatorizado en uno atacable.
>
> **Niveles:** Las Vegas [B] · Monte Carlo [B] · *quicksort* aleatorio [B] · Freivalds [B] · Miller-Rabin
> como Monte Carlo [B].
>
> **📚 Lectura troncal:** Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 10;
> Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017), cap. 1.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--las-vegas) · [4](#4--monte-carlo) · [5](#5--quicksort-aleatorio) · [6](#6--freivalds) · [7](#7--miller-rabin-como-monte-carlo) · [8](#8-️-la-tabla-de-costes) · [9](#9--cómo-se-elige) · [10](#10--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un servicio recibe dos matrices `A` y `B` de `1 000 × 1 000` y un resultado `C` que dice ser su producto.
Comprobarlo multiplicando cuesta `10⁹` operaciones. Hay una forma de comprobarlo en `3·10⁶`: elegir un
vector `r` de ceros y unos al azar y mirar si `A(Br) = Cr`. Si `C` es correcta, la igualdad se cumple
siempre; si no, falla con probabilidad al menos `1/2`. Repitiendo 20 veces, la probabilidad de aceptar una
`C` incorrecta baja a una entre un millón.

Eso es un algoritmo **Monte Carlo**: rápido siempre, y con una probabilidad de error que se elige. Su
pareja, **Las Vegas**, nunca se equivoca y lo que es aleatorio es el tiempo: *quicksort* con pivote al azar
ordena siempre bien y tarda `Θ(n log n)` en esperanza, para **cualquier** entrada.

> 🧠 **Modelo mental.** La aleatoriedad no está en los datos sino en las decisiones del algoritmo. Ningún
> adversario puede preparar una entrada mala, porque no sabe qué monedas va a tirar el algoritmo.

Las trazas usan el arreglo de juguete `[5, 2, 9, 1, 5, 6]` y las matrices `A = [[1,2],[3,4]]`,
`B = [[5,6],[7,8]]`, cuyo producto es `[[19,22],[43,50]]`.

---

## 2. 📐 La teoría

**Las Vegas.** Siempre devuelve la respuesta correcta; su tiempo de ejecución es una variable aleatoria. Se
analiza su **tiempo esperado** (sobre las monedas del algoritmo, para la peor entrada).

**Monte Carlo.** Su tiempo está acotado; la respuesta es correcta con probabilidad al menos `1 − ε`. Es de
**error unilateral** si solo se equivoca en un sentido (Freivalds y Miller-Rabin solo pueden decir «sí» por
error) y **bilateral** si puede equivocarse en los dos.

**Amplificación.** Con error unilateral `ε` y `k` repeticiones independientes, el error baja a `εᵏ`: basta
que una repetición diga «no». Con error bilateral `ε < 1/2`, se vota por mayoría y el error baja
exponencialmente en `k` (cota de Chernoff).

**De un tipo al otro.** Un Las Vegas con tiempo esperado `T` se convierte en Monte Carlo cortándolo a los
`c·T` pasos: por la desigualdad de Markov, `P(tiempo ≥ c·T) ≤ 1/c`. Un Monte Carlo cuya respuesta se puede
**verificar** se convierte en Las Vegas repitiéndolo hasta que la verificación pase.

**El tiempo esperado de *quicksort*.** Sean `z₁ < … < zₙ` los elementos ordenados. `zᵢ` y `zⱼ` se comparan
si y solo si el primer pivote elegido entre `zᵢ, …, zⱼ` es uno de los dos: con pivotes al azar, eso pasa con
probabilidad `2 / (j − i + 1)`. Por linealidad de la esperanza:

```text
E[comparaciones] = Σ_{i<j} 2 / (j − i + 1)  ≤  2n · Hₙ  ≈  2n ln n  ≈  1,39 n log₂ n
```

Vale para **toda** entrada: la esperanza es sobre los pivotes, no sobre los datos.

**Freivalds.** Si `AB ≠ C`, sea `D = AB − C ≠ 0`, con `d_{ij} ≠ 0`. Para `r` uniforme en `{0, 1}ⁿ`,
`(Dr)ᵢ = d_{ij} rⱼ + (lo demás)`; fijado lo demás, como mucho uno de los dos valores de `rⱼ` anula la suma.
Así que `P(Dr = 0) ≤ 1/2`.

---

## 3. 🧱 Las Vegas

**Qué es.** Un algoritmo aleatorizado que siempre acierta; lo aleatorio es el tiempo.

**Por qué es correcto.** Su corrección no depende de las monedas: cualquier secuencia de decisiones lleva a
la respuesta correcta. La aleatoriedad solo decide cuánto se tarda.

**Cómo va.** *Quicksort* con pivote al azar (§5), el *treap* ([`07/03`](../07-arboles/03-arboles-aleatorizados.md)),
el muestreo por **rechazo**: para un punto uniforme en un círculo de radio 1, se elige uno uniforme en el
cuadrado `[−1, 1]²` y se repite hasta que cae dentro. Cada intento acierta con probabilidad `π/4 ≈ 0,785`:
el número de intentos es geométrico, con esperanza `4/π ≈ 1,27`.

**Cuánto.** Tiempo esperado acotado; el caso peor puede no estarlo (el rechazo podría no terminar nunca, con
probabilidad 0).

**La plantilla.** Es la del algoritmo concreto: el *quicksort* de
[`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md), que elige el pivote con un generador
sembrado del reloj.

**Cuándo sí:** cuando un adversario puede elegir la entrada (*quicksort*, tablas *hash*, árboles); cuando el
rechazo es sencillo y su probabilidad de acierto es alta. **Cuándo no:** con tiempo real duro, donde el caso
peor importa; ahí, el determinista con cota de caso peor (*introsort*, árboles balanceados).

> **Veredicto:** Las Vegas no se equivoca nunca. «Aleatorizado» no significa «a veces falla»: significa que
> ningún adversario elige el caso malo.

---

## 4. 🧱 Monte Carlo

**Qué es.** Un algoritmo de tiempo acotado que acierta con probabilidad al menos `1 − ε`.

**Por qué es correcto.** Lo garantiza una cota de probabilidad sobre las monedas del algoritmo, para toda
entrada; y la amplificación de §2 baja `ε` tanto como se quiera.

**Cómo va.** Con error unilateral `1/2` (Freivalds), 20 repeticiones dan `2⁻²⁰ < 10⁻⁶`; 60 repeticiones dan
`2⁻⁶⁰ ≈ 10⁻¹⁸`, menos que la probabilidad de un fallo del *hardware* durante la ejecución.

**Cuánto.** `k` veces el coste de una repetición, para error `εᵏ`.

**La plantilla.** El esquema común:

```text
repetir k veces:
    tirar las monedas (con un generador sembrado del reloj)
    si la prueba falla → responder «no» (seguro)
responder «sí» (con error ≤ εᵏ)
```

**Cuándo sí:** comprobaciones caras (productos de matrices, identidades de polinomios, primalidad);
*hashing* para comparar objetos grandes. **Cuándo no:** cuando un error, por pequeño que sea, es
inaceptable y hay un determinista que entra en el tiempo.

> **Veredicto:** Monte Carlo cambia certeza por velocidad, y el precio se elige: con 60 repeticiones de error
> `1/2`, el error es menor que el del ordenador que lo ejecuta.

---

## 5. 🧱 *Quicksort* aleatorio

**Qué es.** *Quicksort* con el pivote elegido al azar entre los elementos del tramo; el algoritmo, con su
partición, está en [`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md). Aquí va el análisis.

**Por qué es correcto.** El análisis de §2: dos elementos se comparan si y solo si uno de ellos es el primer
pivote de su tramo, y eso tiene probabilidad `2 / (j − i + 1)`.

**Cómo va**, con `[5, 2, 9, 1, 5, 6]` (ordenado: `1, 2, 5, 5, 6, 9`):

```text
z₁ = 1 y z₂ = 2:  se comparan con probabilidad 2/2 = 1     (son vecinos: siempre)
z₁ = 1 y z₆ = 9:  con probabilidad 2/6 = 1/3                (solo si uno de los dos es el primer pivote)
E[comparaciones] = Σ 2/(j − i + 1) = 2(n + 1)Hₙ − 4n ≈ 10,3 para n = 6
```

**Cuánto.** `Θ(n log n)` esperado para toda entrada; `Θ(n²)` en el caso peor, con probabilidad que decrece
exponencialmente: el número de comparaciones pasa de `c · n ln n` con probabilidad que baja como `n^{−Ω(c)}`.

**La plantilla.** La de [`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md): pivote aleatorio
con un generador sembrado del reloj, y partición de Hoare.

**Cuándo sí:** ordenar en memoria con buena localidad; selección (`quickselect`, [`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md)) con el mismo
análisis, `Θ(n)` esperado. **Cuándo no:** si hace falta estabilidad (mezcla) o una cota de caso peor
(*introsort*, `heapsort`).

> **Veredicto:** el pivote aleatorio no mejora el caso medio, lo **traslada** a todas las entradas. El
> `2n ln n` es una esperanza sobre las monedas, no sobre los datos.

---

## 6. 🧱 Freivalds

**Qué es.** Comprobar si `AB = C` para matrices `n × n` en `Θ(n²)` por repetición, con error unilateral
`1/2`.

**Por qué es correcto.** Si `AB = C`, `A(Br) = Cr` para todo `r`: nunca rechaza una `C` correcta. Si
`AB ≠ C`, la prueba de §2 da `P(acepta) ≤ 1/2`.

**Cómo va**, con `A` y `B` de juguete y una `C` errónea, `[[19,22],[43,51]]`:

```text
r = (0,0):  A(Br) = (0, 0)     Cr = (0, 0)      acepta
r = (1,0):  A(Br) = (19, 43)   Cr = (19, 43)    acepta
r = (0,1):  A(Br) = (22, 50)   Cr = (22, 51)    rechaza
r = (1,1):  A(Br) = (41, 93)   Cr = (41, 94)    rechaza
→ acepta la C errónea con probabilidad 2/4 = 1/2, justo la cota
```

**Cuánto.** Tres productos matriz-vector por repetición: `Θ(k n²)` para error `2⁻ᵏ`.

**La plantilla:**

```cpp
#include <chrono>
#include <random>
#include <vector>

using Matrix = std::vector<std::vector<long long>>;

std::vector<long long> mulVec(const Matrix& m, const std::vector<long long>& v) {
    int n = m.size();
    std::vector<long long> res(n, 0);
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++) res[i] += m[i][k] * v[k];
    return res;
}

// ¿AB = C? Si responde false, seguro que no; si responde true, se equivoca con prob. ≤ 2^−rounds.
bool freivalds(const Matrix& a, const Matrix& b, const Matrix& c, int rounds = 30) {
    static std::mt19937_64 rng(std::chrono::steady_clock::now().time_since_epoch().count());
    int n = a.size();
    for (int t = 0; t < rounds; t++) {
        std::vector<long long> r(n);
        for (auto& x : r) x = rng() & 1;                     // r uniforme en {0, 1}ⁿ
        if (mulVec(a, mulVec(b, r)) != mulVec(c, r)) return false;
    }
    return true;
}
```

```java
static final java.util.Random RNG = new java.util.Random();       // semilla del sistema

static long[] mulVec(long[][] m, long[] v) {
    int n = m.length;
    long[] res = new long[n];
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++) res[i] += m[i][k] * v[k];
    return res;
}

static boolean freivalds(long[][] a, long[][] b, long[][] c, int rounds) {
    int n = a.length;
    for (int t = 0; t < rounds; t++) {
        long[] r = new long[n];
        for (int i = 0; i < n; i++) r[i] = RNG.nextInt(2);
        if (!java.util.Arrays.equals(mulVec(a, mulVec(b, r)), mulVec(c, r))) return false;
    }
    return true;
}
```

- **El orden de los productos**: `A(Br)` son dos productos matriz-vector, `Θ(n²)`; `(AB)r` sería volver a
  multiplicar matrices.
- **Desbordamiento**: con entradas de hasta `10⁴` y `n = 1 000`, `Br` llega a `10⁷` y `A(Br)` a `10¹⁴`,
  que caben en 64 bits. Con entradas mayores, se trabaja módulo un primo grande; el argumento de §2 vale en
  cualquier cuerpo, y con `r` en todo el cuerpo el error baja a `1/p`.
- **La semilla**: del reloj en C++ (`steady_clock`), del sistema en Java (`new Random()` sin argumento). Con
  una semilla fija, un adversario que conoce el código construye la `C` errónea que pasa siempre.

**Cuándo sí:** verificar un producto de matrices que da otro (un servidor, un juez, una caché); comprobar
`AB = C` con matrices módulo `p`. **Cuándo no:** si de todos modos hay que calcular `AB`, la verificación no
ahorra nada.

> **Veredicto:** Freivalds verifica en `n²` lo que cuesta `n³` calcular. Es el ejemplo más limpio de Monte
> Carlo: error unilateral `1/2`, amplificado a lo que se quiera.

---

## 7. 🧱 Miller-Rabin como Monte Carlo

**Qué es.** El test de primalidad de [`17/04`](../17-matematica/04-primos.md) visto como Monte Carlo: si
responde «compuesto», es seguro; si responde «primo», puede equivocarse.

**Por qué es correcto.** Para `n` compuesto impar, como mucho `1/4` de las bases `a` lo declaran
«probablemente primo» (teorema de Rabin). Con `k` bases al azar, el error es como mucho `4⁻ᵏ`.

**Cómo va.** Con 20 bases al azar, el error es `4⁻²⁰ ≈ 10⁻¹²`. Para enteros de 64 bits hay algo mejor: las
12 primeras bases primas (`2, 3, 5, …, 37`) bastan para que el test sea **exacto**, y deja de ser
aleatorizado.

**Cuánto.** `O(k log n)` multiplicaciones modulares.

**La plantilla.** La de [`17/04`](../17-matematica/04-primos.md), con las bases fijas para 64 bits; para
números mayores (criptografía, `BigInteger`), bases al azar.

**Cuándo sí:** primalidad de números grandes; `BigInteger.isProbablePrime(c)` de Java hace exactamente esto,
con error `2⁻ᶜ`. **Cuándo no:** si hace falta un certificado de primalidad (ECPP, AKS), o si los números son
pequeños y una criba los cubre.

> **Veredicto:** Miller-Rabin es Monte Carlo de error unilateral `1/4`; en 64 bits, con bases fijas, ya ni
> siquiera es aleatorizado.

---

## 8. ⏱️ La tabla de costes

| Algoritmo | Tipo | Coste | Lo que la tabla no dice |
|---|---|---|---|
| *Quicksort* aleatorio | Las Vegas | `Θ(n log n)` esperado | `2n ln n` comparaciones; caso peor con probabilidad despreciable |
| Muestreo por rechazo | Las Vegas | `1/p` intentos esperados | Con `p` pequeña, se vuelve lento |
| Freivalds | Monte Carlo unilateral | `Θ(k n²)` | Error `2⁻ᵏ`; con `r` en un cuerpo grande, `p⁻ᵏ` |
| Miller-Rabin | Monte Carlo unilateral | `O(k log n)` multiplicaciones | Exacto en 64 bits con 12 bases fijas |
| Igualdad de polinomios por evaluación | Monte Carlo unilateral | `O(n)` por evaluación | Error `≤ grado / p` (Schwartz-Zippel) |

---

## 9. 🧭 Cómo se elige

```text
¿La respuesta tiene que ser siempre correcta? → Las Vegas (o determinista)
¿Comprobar es mucho más barato que calcular? → Monte Carlo con error unilateral y repetición
¿Hay un adversario que conoce el código? → semilla del reloj o del sistema, nunca fija
¿Un determinista con la misma cota entra? → el determinista
```

> **Regla de entrevista:** al proponer un aleatorizado, di de qué tipo es y cuál es su garantía: «Las Vegas,
> `n log n` esperado para toda entrada» o «Monte Carlo, error `2⁻³⁰` con 30 repeticiones».

---

## 10. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Comprueba si `AB = C`», `n = 1 000` | Freivalds | `n²` frente a `n³` |
| «¿Son iguales estos dos polinomios / expresiones?» | Evaluar en un punto al azar | Schwartz-Zippel |
| Un elemento que aparece en al menos la mitad de las posiciones | Muestreo al azar | Cada intento acierta con probabilidad `≥ 1/2` |
| «Genera un punto uniforme en una figura» | Rechazo | Las Vegas con esperanza `área caja / área figura` |
| Juez con *hacks* (Codeforces) | Semilla del reloj | Una semilla fija se puede atacar |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Aleatorizado significa que a veces falla» | Las Vegas no falla nunca; lo aleatorio es el tiempo |
| «*Quicksort* aleatorio es `n log n` en promedio sobre las entradas» | Es `n log n` **esperado sobre los pivotes** para cada entrada |
| «Con error `1/2` el algoritmo no sirve» | Repetido 60 veces, el error es `10⁻¹⁸` |
| «La semilla da igual» | Con semilla fija, un adversario construye la entrada mala |
| «Miller-Rabin siempre puede equivocarse» | En 64 bits, con las 12 primeras bases primas, es exacto |
| «Freivalds calcula `AB`» | Solo compara `A(Br)` con `Cr`: nunca multiplica matrices |

---

## 📚 Para profundizar

- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 10: algoritmos
  probabilistas, Las Vegas, Monte Carlo y la amplificación. *Lectura troncal.*
- **Libro** — Mitzenmacher y Upfal, *Probability and Computing*, 2.ª ed. (Cambridge, 2017), cap. 1:
  Freivalds, identidad de polinomios y el corte mínimo aleatorizado. *Lectura troncal.*
- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  §7.4: el análisis esperado de *quicksort* aleatorio.

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre un algoritmo Las Vegas y uno Monte Carlo? 🟢
2. ¿Qué es un error unilateral, y qué algoritmo del capítulo lo tiene? 🟢
3. ¿Cuánto cuesta Freivalds y qué probabilidad de error tiene? 🟢
4. ¿Cómo se reduce el error de un Monte Carlo de error unilateral? 🟡
5. ¿Qué diferencia hay entre el caso promedio de *quicksort* con pivote fijo y el esperado con pivote
   aleatorio? 🟡
6. ¿Cómo se convierte un Las Vegas en Monte Carlo, y al revés? 🟡
7. ¿Por qué una semilla fija hace atacable un algoritmo aleatorizado, y cómo se siembra en C++, Java y
   Python? 🟠
8. ¿Cuántas repeticiones de Freivalds necesitas para un error menor que `10⁻⁹`? 🟠
9. ¿Qué probabilidad tiene de comparar `zᵢ` y `zⱼ` el *quicksort* aleatorio, y por qué? 🟠
10. ¿Por qué Miller-Rabin deja de ser aleatorizado en 64 bits? 🟠
11. Demuestra que, si `AB ≠ C`, Freivalds acepta con probabilidad como mucho `1/2`. 🔴
12. Diseña un algoritmo para decidir si un arreglo de `10⁶` enteros tiene un valor que aparece en al menos la
    mitad de las posiciones, usando muestreo, y acota su error. 🔴

---

## 🧩 Problemas propios

### Polinomios iguales

**Nivel:** 🟠 · **Formato:** programa completo.

Un polinomio `P` viene como producto de `n` factores lineales `(aᵢ x + bᵢ)`; otro, `Q`, viene por sus
coeficientes. Imprime `YES` si son el mismo polinomio y `NO` si no.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `aᵢ` y `bᵢ`. Después, una línea con los `n + 1`
  coeficientes de `Q`, de `x⁰` a `xⁿ`.
- **Salida.** `YES` o `NO`.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `|aᵢ|, |bᵢ| ≤ 10`; `|cⱼ| ≤ 10¹⁸`.

```text
Entrada         Salida
2               YES
1 1
1 2
2 3 1

Entrada         Salida
2               NO
1 1
1 1
1 0 1
```

**Pista 1:** multiplicar los `10⁵` factores cuesta caro y da números enormes. ¿Qué te dice comparar los dos
polinomios en un solo punto, y qué pasa si el punto lo eliges tú al azar?

### Mismos valores en dos tramos

**Nivel:** 🟠 · **Formato:** programa completo.

Hay dos arreglos `a` y `b` de longitud `n`. Cada consulta da un tramo de `a` y otro de `b` de la misma
longitud: imprime `YES` si contienen los mismos valores con las mismas repeticiones (uno es una permutación
del otro) y `NO` si no.

- **Entrada.** Una línea con `n` y `q`. Una línea con `a` y otra con `b`. Después, `q` líneas con
  `l₁ r₁ l₂ r₂` (índices desde 1, `r₁ − l₁ = r₂ − l₂`).
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `1 ≤ aᵢ, bᵢ ≤ 10⁹`.

```text
Entrada         Salida
6 4             NO
5 2 9 1 5 6     YES
1 5 5 2 9 6     YES
1 3 2 4         NO
1 5 1 5
6 6 6 6
2 4 4 6

Entrada         Salida
1 1             YES
7
7
1 1 1 1
```

**Pista 1:** si a cada valor le asignas un número al azar, ¿qué pasa con la suma de esos números en dos tramos
que son permutación uno del otro, y qué pasa si no lo son?

---

## 🧩 Práctica externa

> 💡 **Truco.** En Codeforces, siembra siempre con el reloj: los problemas aleatorizados atraen *hacks*
> contra semillas fijas. Si una IA te ayuda, que sea a calcular cuántas repeticiones necesitas para tu
> error, no a escribir la solución ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).
> CSES no tiene problemas que pidan aleatorizar.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Implement Rand10() Using Rand7()](https://leetcode.com/problems/implement-rand10-using-rand7/) | LeetCode | 🟡 | Rechazo | Con dos llamadas a `rand7()` tienes 49 resultados equiprobables: ¿cuántos usas y qué haces con el resto? |
| [ ] | [Generate Random Point in a Circle](https://leetcode.com/problems/generate-random-point-in-a-circle/) | LeetCode | 🟡 | Rechazo | Si eliges un punto uniforme en el cuadrado que rodea al círculo, ¿qué haces cuando cae fuera? |
| [ ] | [Cut and Stick](https://codeforces.com/problemset/problem/1514/D) | Codeforces | 🟠 | Muestreo de un mayoritario | Si un valor ocupa más de la mitad del tramo, ¿con qué probabilidad lo encuentras eligiendo una posición al azar? |
| [ ] | [Interactive LowerBound](https://codeforces.com/problemset/problem/843/B) | Codeforces | 🟠 | Muestreo e interacción | Con 2 000 preguntas sobre una lista de `5·10⁴`, ¿qué ganas preguntando primero por posiciones al azar? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Kuroni and the Punishment](https://codeforces.com/problemset/problem/1305/F) | Codeforces | 🔴 | Muestreo y primos | Si la respuesta es como mucho `n`, ¿cuántos elementos pueden necesitar más de un cambio, y qué te dice eso de un elemento al azar? |
| [ ] | [Love-Hate](https://codeforces.com/problemset/problem/1523/D) | Codeforces | 🔴 | Muestreo de un representante | Un amigo al azar está en el grupo buscado con probabilidad `≥ 1/2`: ¿qué haces con sus 15 monedas favoritas? |
| [ ] | [Kazaee](https://codeforces.com/problemset/problem/1746/F) | Codeforces | 🔴 | *Hashing* aleatorio y Fenwick | Si cada valor aparece un múltiplo de `k` veces, ¿qué pasa con la suma de un subconjunto aleatorio de valores? |
| [ ] | [Ghd](https://codeforces.com/problemset/problem/364/D) | Codeforces | 🔴 | Muestreo y divisores | Un número al azar es múltiplo de la respuesta con probabilidad `≥ 1/2`: ¿entre qué candidatos está entonces? |

---

## ✅ Criterio de dominio

- Explicar Las Vegas y Monte Carlo con un ejemplo de cada uno y su garantía.
- Demostrar la cota de error de Freivalds y escribirlo en C++ o Java sin mirar.
- Deducir el número esperado de comparaciones de *quicksort* aleatorio con variables indicadoras.
- Resolver Implement Rand10() Using Rand7() y Cut and Stick sin pista 2.

---

**Anterior:** — · **Siguiente:** [`19/02` — *Hashing* universal y análisis esperado](02-hashing-universal-y-analisis-esperado.md) ·
**Relacionado:** [`17/04` — Primos](../17-matematica/04-primos.md).
