# 02 — Leer las restricciones: de `n` a la complejidad

> Mirar las cotas del enunciado y decir, antes de escribir una línea, qué complejidad cabe, qué
> técnicas la dan, cuánta memoria hay y de qué tipo tiene que ser cada número.
>
> **Niveles:** la tabla `n` → complejidad [A] · estimación de memoria [A].
>
> **📚 Lectura troncal:** Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024),
> cap. 3; Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 2.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-regla-de-los-10) · [3](#3--la-tabla-n--complejidad) · [4](#4--lo-que-cambia-por-lenguaje) · [5](#5--la-memoria) · [6](#6--el-valor-frente-al-tamaño) · [7](#7--cómo-se-elige) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

El enunciado dice: *dado un arreglo de `n` enteros, cuenta las parejas `i < j` con `a[i] + a[j] = K`*.
Y debajo, en letra pequeña:

```text
1 ≤ n ≤ 2·10⁵        −10⁹ ≤ a[i], K ≤ 10⁹        límite: 1 segundo, 256 MB
```

La primera idea es probar todas las parejas: dos bucles anidados. Son `n(n−1)/2` parejas, y con
`n = 2·10⁵` eso es unos **2·10¹⁰** pasos. El juez te da un segundo, y en un segundo un programa hace
del orden de **10⁸** operaciones simples. Tu programa tardaría **unos 200 segundos**. Es TLE seguro, y
lo sabías antes de escribirlo: estaba en la letra pequeña.

Esa letra pequeña dice más cosas. El número de parejas puede llegar a `2·10¹⁰`, que **no cabe en un
entero de 32 bits**: la respuesta necesita 64. Y los valores llegan a `10⁹` en valor absoluto, así que
no puedes usarlos como índice de un arreglo. **Las restricciones son la pista principal del
problema**: dicen qué complejidad cabe, qué estructura sirve y de qué tipo es cada número. Este
capítulo enseña a leerlas.

> 🧠 **Modelo mental.** Recordatorio, si llegas directo aquí: `O(f(n))` describe **cómo crece** el
> número de pasos cuando crece la entrada, ignorando constantes. `O(n²)` con `n` el doble son cuatro
> veces los pasos; `O(n log n)`, algo más del doble. El capítulo [`02/01`](../02-analisis/01-notacion-asintotica.md) da las definiciones formales;
> aquí basta con contar pasos.

---

## 2. 🧱 La regla de los 10⁸

**Qué es.** La regla de bolsillo: **un programa compilado hace del orden de 10⁸ operaciones simples
por segundo**. «Simple» es una suma, una comparación, un acceso a un arreglo que está en caché.

**Cómo va.** Calculas el número de pasos de tu algoritmo con el `n` **máximo** de las restricciones,
lo comparas con `10⁸ × segundos del límite`, y miras el margen:

```text
pasos ≤ 10⁷           cabe con holgura, en cualquier lenguaje
10⁷ < pasos ≤ 10⁸     cabe en C++ y en Java; en Python, depende
10⁸ < pasos ≤ 10⁹     solo con constante baja, en C++, y con suerte
pasos > 10⁹           no cabe; busca otra idea
```

**Por qué es orientativa.** Un procesador moderno ejecuta miles de millones de instrucciones por
segundo, así que 10⁸ parece pesimista. No lo es, porque una «operación» del análisis no es una
instrucción: un acceso a memoria que **falla en caché** cuesta lo que cien sumas, una división entera
cuesta lo que varias sumas, y una llamada a función o un `HashMap.get` con *boxing* cuesta decenas.
`10⁸` es un promedio honesto para código normal. El capítulo [`02/05`](../02-analisis/05-el-coste-real.md) cuenta qué hay debajo de la
constante.

**Cuánto cuesta aplicarla.** Diez segundos y una multiplicación. Es lo más barato que vas a hacer en
todo el problema, y lo que más TLE evita.

**Cuándo sí**: siempre, antes de escribir. **Cuándo no** confiar en ella a ciegas: cuando estás cerca
del borde (entre 10⁸ y 10⁹), donde deciden la constante, la localidad y el lenguaje.

> **Veredicto:** multiplica antes de programar. Si el número de pasos con el `n` máximo pasa de 10⁸ por
> segundo de límite, la idea no sirve, por bonita que sea.

---

## 3. 🧱 La tabla `n` → complejidad

**Qué es.** La regla anterior, despejada al revés: dado el `n` máximo, **qué complejidad cabe** en un
segundo. Se memoriza, porque es lo primero que se mira en un enunciado.

```text
Regla:
n ≤ 10–11        → n!          permutaciones de todo
n ≤ 20           → 2ⁿ · n      subconjuntos, máscara de bits
n ≤ 40           → 2^(n/2)     partir en dos mitades y combinar (meet in the middle)
n ≤ 100–500      → n³          tres bucles: DP de intervalos, Floyd-Warshall
n ≤ 5 000        → n²          DP en dos dimensiones, todas las parejas
n ≤ 2·10⁵–10⁶    → n log n     ordenar, heap, búsqueda binaria, segment tree
n ≤ 10⁷–10⁸      → n           prefijos, ventana, dos punteros, un recorrido
n ~ 10⁹–10¹⁸     → √n, log n   divisores, binaria sobre la respuesta, exponenciación, fórmula
```

**Cómo va**, con los números hechos, para que la tabla no sea un acto de fe:

| `n` máximo | Complejidad | Pasos aproximados | ¿Cabe en 1 s? |
|---|---|---|---|
| 11 | `n!` | 4·10⁷ | ✅ |
| 20 | `2ⁿ · n` | 2·10⁷ | ✅ |
| 500 | `n³` | 1,25·10⁸ | ✅ justo, con constante baja |
| 5 000 | `n²` | 2,5·10⁷ | ✅ |
| 2·10⁵ | `n²` | 4·10¹⁰ | ❌ |
| 2·10⁵ | `n log n` | 3,6·10⁶ (`log₂ 2·10⁵ ≈ 18`) | ✅ con holgura |
| 10⁷ | `n log n` | 2,3·10⁸ | ❌ casi seguro |
| 10¹⁸ | `log n` | 60 | ✅ |

**Leerla al revés también es información.** Si el enunciado dice `n ≤ 20`, el autor **te está diciendo**
que espera algo exponencial: con `n ≤ 10⁵` no habría puesto 20. Si dice `n ≤ 5 000`, espera algo
cuadrático, y probablemente una DP. Si dice `n ≤ 10¹⁸`, ni siquiera puedes leer `n` elementos: la
solución es una fórmula o algo logarítmico.

**Las trampas de la lectura:**

- **Varios parámetros.** Con `n ≤ 10⁵` y `q ≤ 10⁵` consultas, `O(n · q)` son 10¹⁰: hay que responder
  cada consulta en `O(log n)` o `O(1)` tras un preproceso. Cada parámetro entra en la cuenta.
- **Varios casos de prueba.** «`t ≤ 10⁴` casos, `n ≤ 2·10⁵`» parece terrible hasta que lees la línea
  que casi siempre sigue: **«la suma de `n` sobre todos los casos no pasa de 2·10⁵»**. Esa línea cambia
  la cuenta: lo que importa es la suma, no el producto. Y si no está, el producto sí cuenta.
- **El `log` no es gratis.** `n log n` con `n = 10⁶` son `2·10⁷` comparaciones, pero si cada una es un
  acceso a un `TreeMap` con objetos, la constante se come el margen.

### De la versión ingenua a la buena

**El problema.** Dado un arreglo de `n ≤ 2·10⁵` enteros y un `K`, ¿existe una pareja `i < j` con
`a[i] + a[j] = K`? Con el arreglo `[5, 2, 9, 1, 5, 6]` y `K = 10`, sí: `5 + 5`, en los índices 0 y 4.

**La versión ingenua**, la de los primeros cinco minutos:

```java
// Fuerza bruta: prueba todas las parejas i < j. Correcta, y O(n²).
static boolean hasPairWithSum(int[] a, long k) {
    for (int i = 0; i < a.length; i++)
        for (int j = i + 1; j < a.length; j++)
            if ((long) a[i] + a[j] == k) return true;   // la suma en long: dos 10⁹ desbordan int
    return false;
}
```

- **Es correcta**: prueba exactamente las parejas que pide el enunciado, ni una más.
- **`(long) a[i] + a[j]`**: el *cast* va antes de sumar. `(long) (a[i] + a[j])` desbordaría primero y
  convertiría después.

> «Esto prueba `n(n−1)/2` parejas. Con `n = 2·10⁵` son `2·10¹⁰`, unas 200 veces lo que cabe en un
> segundo. Necesito algo `n log n` o lineal. Lo que repito es buscar, para cada `a[i]`, si existe su
> complemento `K − a[i]`; esa búsqueda es lo que hay que abaratar.»

**El camino a la buena.** Si guardo los valores ya vistos en un conjunto hash, cada búsqueda del
complemento es `O(1)` esperado y el total baja a `O(n)` esperado. (Ordenar y usar dos punteros da
`O(n log n)` en caso peor, sin depender del hash; las dos son válidas.)

```java
// Un recorrido: para cada valor, ¿vi ya su complemento? O(n) esperado.
static boolean hasPairWithSum(int[] a, long k) {
    java.util.HashSet<Long> seen = new java.util.HashSet<>();
    for (int x : a) {
        if (seen.contains(k - x)) return true;   // el complemento apareció antes: i < j
        seen.add((long) x);
    }
    return false;
}
```

- **`seen` guarda solo lo anterior a `x`**, y por eso la pareja encontrada cumple `i < j` y nunca
  empareja un elemento consigo mismo.
- **Las técnicas tienen su capítulo**: dos punteros en [`04/02`](../04-secuencias/02-dos-punteros-y-ventana.md), tablas hash en [`06/03`](../06-lineales-y-hashing/03-tablas-hash.md). Aquí lo que
  importa es que **la cota eligió la técnica**: `2·10⁵` descarta `n²` antes de pensar nada más.

**Cuándo sí** se usa la tabla: en todo enunciado, como primer paso. **Cuándo no** basta: cerca de los
bordes de cada fila, donde decide el lenguaje (§4) o la constante.

> **Veredicto:** el `n` máximo te dice la complejidad que el autor tenía en mente. Léelo primero y
> descarta en diez segundos las ideas que no caben.

---

## 4. 🧱 Lo que cambia por lenguaje

**Qué es.** La regla de los 10⁸ es para código compilado con tipos primitivos. Cada lenguaje la mueve:

| Lenguaje | Operaciones simples por segundo, orientativo | El detalle que muerde |
|---|---|---|
| **C++** | ~10⁸ a 10⁹, según la localidad | Casi nada: es la referencia de la regla |
| **Java** | ~10⁸ con primitivos, bastante menos con objetos | El arranque de la JVM, la E/S con `Scanner` y el *boxing* de `Integer` en colecciones |
| **Python** | ~10⁷ en bucles puros | Un factor de 30 a 50 frente a C++; las funciones de la librería escritas en C (`sorted`, `sum`) se salvan |

**Cómo va.** En Java, la regla se cumple mientras trabajes con `int[]` y `long[]`; una
`ArrayList<Integer>` de 10⁶ elementos son 10⁶ objetos en el *heap*, y recorrerla es más lento por
punteros y caché. En Python, un bucle `for` de 10⁷ iteraciones ya tarda del orden de un segundo; la
salida es empujar el trabajo a funciones de la librería, que corren en C.

**Cuánto cuesta.** En la práctica, Python pierde una fila de la tabla de §3: donde C++ hace `n log n`
con `n = 10⁶`, Python necesita `n` o `n log n` con `n = 10⁵`. Java pierde media fila si usas objetos.

**Cuándo sí** se cambia de lenguaje: cuando la complejidad correcta en Python queda por encima de 10⁷
pasos y el límite no compensa. **Cuándo no**: cuando la complejidad no cabe; ningún lenguaje arregla
un `n²` con `n = 2·10⁵`.

> **Veredicto:** el lenguaje mueve la constante, no la fila. Si la complejidad no cabe, cambiar de
> lenguaje no salva el problema; si cabe justo, puede salvarlo.

---

## 5. 🧱 La memoria

**Qué es.** El otro límite del enunciado, el que casi nadie mira hasta que da MLE. La cuenta es igual
de mecánica: **elementos × bytes por elemento**, contra el límite.

```text
Regla de memoria (256 MB = 268 435 456 bytes):
int / int32                4 bytes   →  ~6,7·10⁷ elementos caben
long long / long / int64   8 bytes   →  ~3,3·10⁷ elementos caben
bool en C++ (bitset)       1 bit     →  ~2·10⁹ elementos caben
Integer de Java           ~16 bytes  + 4 u 8 del puntero en la colección
int de Python             ~28 bytes  + 8 del puntero en la lista (salvo los cacheados, de −5 a 256)
```

**Cómo va**, con los casos que salen de verdad:

| Estructura | Cuenta | ¿Cabe en 256 MB? |
|---|---|---|
| `int` de `10⁷` | 40 MB | ✅ |
| `long long` de `10⁸` | 800 MB | ❌ |
| matriz `int` de `5000 × 5000` | 100 MB | ✅ |
| matriz `long long` de `5000 × 5000` | 200 MB | ✅ justo |
| matriz `int` de `10⁴ × 10⁴` | 400 MB | ❌ |
| `ArrayList<Integer>` de `10⁷` en Java | ~200 MB | ❌ casi seguro, con el resto del programa |
| `list` de `10⁷` enteros grandes en Python | ~360 MB | ❌ |

**La pila es memoria aparte.** La recursión usa la pila del hilo, que suele ser mucho más pequeña que
el límite del problema: en Java, del orden de 1 MB por hilo en una JVM de 64 bits; en Python, el límite de
recursión es 1000 llamadas. Una recursión de profundidad `10⁵` revienta en los dos aunque la memoria
total sobre. El bloque `03` dice cómo se amplía en cada lenguaje.

**Cuándo sí** se calcula: cada vez que reservas algo proporcional a `n²`, a `n · m` o a un valor del
enunciado. **Cuándo no** hace falta: con `O(n)` primitivos y `n ≤ 10⁶`, cabe siempre.

> **Veredicto:** 256 MB son unos 64 millones de `int`. Una matriz de `n²` con `n = 10⁴` no cabe, y un
> arreglo de `10⁸` `long long` tampoco: si la idea los necesita, la idea está mal.

---

## 6. 🧱 El valor frente al tamaño

**Qué es.** Un enunciado tiene dos clases de cotas: las de **tamaño** (`n`, `m`, `q`), que deciden la
complejidad, y las de **valor** (`a[i] ≤ 10⁹`), que deciden los tipos y las estructuras. Se leen por
separado, porque piden cosas distintas.

| Cota de valor | Qué implica |
|---|---|
| `a[i] ≤ 10⁶` | Puedes indexar por valor: un arreglo de conteo de tamaño `10⁶ + 1` |
| `a[i] ≤ 10⁹` | No puedes indexar por valor: ordena, comprime coordenadas o usa un mapa |
| `a[i] ≤ 10⁹`, sumas de `n ≤ 10⁵` | La suma llega a `10¹⁴`: acumulador de 64 bits |
| producto de dos `a[i] ≤ 10⁹` | Llega a `10¹⁸`: cabe justo en 64 bits con signo (tope ~`9,2·10¹⁸`) |
| `x ≤ 10¹⁸` | Ni siquiera recorres hasta `x`: binaria sobre la respuesta, `√x` o fórmula |
| «la respuesta, módulo 10⁹+7» | La respuesta real es enorme; el capítulo [`01/04`](04-tipos-desbordamiento-y-modulo.md) explica por qué ese módulo |

**Cómo va.** Con `n ≤ 10⁵` y valores `≤ 10⁹`, la complejidad la manda `n` (cabe `n log n`) y el
valor manda que no haya arreglos indexados por valor ni acumuladores de 32 bits. Con `n ≤ 10⁵` y
valores `≤ 10⁵`, el mismo problema admite un arreglo de conteo y se vuelve lineal.

**Cuánto cuesta equivocarse.** Un tipo de 32 bits donde hacía falta uno de 64 da WA en los casos
grandes, y no en los ejemplos: el error se esconde justo donde no miras. El capítulo `01/04` hace la
autopsia completa de ese bug.

**Cuándo sí** se mira el valor: siempre que sumes, multipliques o indexes por un dato. **Cuándo no**:
nunca deja de mirarse.

> **Veredicto:** el tamaño elige el algoritmo y el valor elige los tipos. Un problema bien leído tiene
> decididas las dos cosas antes de la primera línea.

---

## 7. 🧭 Cómo se elige

El procedimiento entero, en el orden en que se hace, sobre la letra pequeña de cualquier enunciado:

```text
1. Tamaños (n, m, q, t, la suma de n)   → complejidad máxima con la tabla de §3
2. Lenguaje                              → ¿pierdo una fila? (§4)
3. Técnicas de esa fila                  → las candidatas; descarta las de filas más caras
4. Memoria                               → elementos × bytes de lo que piensas reservar (§5)
5. Valores                               → tipos de 64 bits, indexar o no por valor, módulo (§6)
6. Profundidad de recursión              → ¿cabe en la pila de tu lenguaje?
```

Y la frase que se dice en voz alta en una entrevista, antes de proponer nada:

> **Mejor:** «Con `n` hasta 2·10⁵ no me cabe un `n²`, que serían 4·10¹⁰ pasos; necesito `n log n` o
> mejor. Y como los valores llegan a 10⁹, la suma va en 64 bits.»

---

## 8. 🔭 Dónde aparece de verdad

La misma cuenta tiene nombre fuera de los jueces: **estimación de servilleta** (*back-of-the-envelope
estimation*).

- **Dimensionar un servicio.** «Un millón de usuarios, cada uno con 100 eventos al día» son 10⁸
  eventos: si el procesamiento es cuadrático en algo, ya sabes que no escala, sin escribir código.
- **Elegir un índice.** Una consulta que recorre 10⁷ filas por petición no aguanta 1000 peticiones por
  segundo; un índice que la deja en `log n` sí. Es la tabla de §3 con otras unidades.
- **La memoria de un proceso.** Cargar 10⁸ objetos de Java en un mapa es la fila de `ArrayList<Integer>`
  de §5 multiplicada por diez, y el motivo de muchos `OutOfMemoryError` en producción.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «O grande es el tiempo que tarda» | Es cómo crece el número de pasos; el tiempo sale de multiplicar por la constante, que depende del lenguaje y de la memoria |
| «Si es `O(n log n)`, entra seguro» | Con `n = 10⁷` son 2,3·10⁸ pasos; con objetos de Java o en Python, no entra |
| «La memoria no se mira» | 256 MB son ~6,7·10⁷ `int`; una matriz de 10⁴ × 10⁴ ya no cabe |
| «Con `t` casos de `n` cada uno, multiplico» | Si el enunciado acota la suma de `n`, lo que cuenta es la suma |
| «`n ≤ 10⁵` y valores `≤ 10⁹` es lo mismo que valores `≤ 10⁵`» | El valor decide si puedes indexar por valor y de qué tipo es la suma |
| «Python es lento, pero la complejidad correcta siempre entra» | Python pierde una fila de la tabla; cerca del borde, no entra |
| «La recursión solo gasta lo que gasta» | Gasta pila, que es mucho más pequeña que el límite de memoria |

---

## 📚 Para profundizar

- **Libro** — Laaksonen, *Guide to Competitive Programming*, 3.ª ed. (Springer, 2024), cap. 3: la
  estimación de eficiencia y la tabla de tamaños. *Lectura troncal.*
- **Libro** — Skiena, *The Algorithm Design Manual*, 3.ª ed. (Springer, 2020), cap. 2: el análisis de
  algoritmos con la mirada puesta en lo que cabe en la práctica.
- **Libro** — Bentley, *Programming Pearls*, 2.ª ed. (Addison-Wesley, 2000), columna 7: los cálculos de
  servilleta, con el mismo espíritu fuera de los jueces.
- **Documentación** — cppreference, [`std::numeric_limits`](https://en.cppreference.com/cpp/types/numeric_limits):
  el rango exacto de cada tipo entero en C++.
- **Documentación** — Java 21, [`Integer`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Integer.html):
  `MAX_VALUE` y los métodos con detección de desbordamiento.
- **Referencia** — USACO Guide, [*Time Complexity*](https://usaco.guide/bronze/time-comp): la tabla de
  tamaños con ejemplos.

---

## 🧠 Preguntas

1. ¿Cuántas operaciones simples por segundo asume la regla de bolsillo, y qué cuenta como «simple»? 🟢
2. ¿Qué complejidad cabe en un segundo con `n ≤ 20`, con `n ≤ 5 000` y con `n ≤ 2·10⁵`? 🟢
3. ¿Cuántos `int` caben en 256 MB, y cuántos `long long`? 🟢
4. ¿Qué diferencia hay entre una cota de tamaño y una cota de valor, y qué decide cada una? 🟡
5. Un enunciado tiene `t ≤ 10⁴` casos con `n ≤ 2·10⁵` cada uno. ¿Qué línea del enunciado buscas antes de calcular, y por qué cambia todo? 🟡
6. ¿Por qué la regla de los 10⁸ es orientativa, si un procesador ejecuta miles de millones de instrucciones por segundo? 🟡
7. Compara C++, Java y Python ante `n log n` con `n = 10⁶`: ¿cabe en un segundo en cada uno, y qué detalle de cada lenguaje decide? 🟡
8. Con `n ≤ 10⁵` y `q ≤ 10⁵` consultas sobre rangos, ¿por qué no basta con responder cada consulta recorriendo el rango? 🟠
9. Un enunciado dice `n ≤ 40`. ¿Qué te está diciendo el autor, y por qué no es ni `2ⁿ` ni `n²`? 🟠
10. Tu solución recursiva tiene la complejidad correcta, cabe en memoria y da RE en el caso grande. ¿Qué cota olvidaste mirar? 🟠
11. Calcula si cabe una matriz de `long long` de `n × n` con `n = 10⁴` en 256 MB, y propone qué harías si no cabe. 🔴
12. Con `n ≤ 10⁵` y valores `a[i] ≤ 10⁹`, el problema pide contar parejas con cierta propiedad. Decide el tipo de la respuesta y justifica la cota que usas. 🔴
13. Para el problema de §1 (contar parejas que suman `K`), escribe la cuenta de pasos de la fuerza bruta con el `n` máximo, decide qué complejidad necesitas y nombra dos técnicas que la dan. 🔴

---

## 🧩 Problemas propios

### ¿Cabe o no cabe?

**Nivel:** 🟢 · **Formato:** programa completo.

Para cada consulta recibes el `n` máximo, el límite de tiempo en segundos y una complejidad. Decide si
cabe con la regla de 10⁸ operaciones por segundo.

- **Entrada.** Una línea con `q`. Después, `q` líneas con `n`, `s` y una de estas cadenas: `1`, `logn`,
  `n`, `nlogn`, `n2`, `n3`, `2n` (que significa `2ⁿ`), `nfact` (que significa `n!`).
- **Salida.** Por cada consulta, `SI` si `pasos ≤ 10⁸ · s`, y `NO` si no. Para `logn` y `nlogn`, usa
  `⌈log₂ n⌉`, y `log₂ 1 = 0`.
- **Restricciones.** `1 ≤ q ≤ 1000`; `1 ≤ n ≤ 10¹⁸`; `1 ≤ s ≤ 10`.

```text
Entrada            Salida
4                  SI
5000 1 n2          NO
200000 1 n2        SI
20 1 2n            NO
100 1 2n

Entrada            Salida
2                  SI
1 1 nfact          SI
1000000000000000000 1 logn
```

**Pista 1:** ¿qué pasa con tus variables si calculas `2¹⁰⁰` o `100!` antes de compararlos?

🔥 **Para el geek — en JavaScript:** `n` llega a `10¹⁸`, que pasa de `2⁵³`: leerlo como `Number`
pierde dígitos, y hay que decidir entre `BigInt` y no calcular nunca el número grande.

### Parejas que suman K

**Nivel:** 🟡 · **Formato:** programa completo.

Cuenta las parejas de índices `i < j` con `a[i] + a[j] = K`.

- **Entrada.** Una línea con `n` y `K`. Una segunda línea con `n` enteros.
- **Salida.** Un entero: el número de parejas.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `−10⁹ ≤ a[i], K ≤ 10⁹`. Límite: 1 segundo.

```text
Entrada            Salida
6 10               2
5 2 9 1 5 6

Entrada            Salida
4 2                6
1 1 1 1
```

**Pista 1:** si todos los valores son iguales y suman `K` de dos en dos, ¿cuántas parejas hay con el
`n` máximo, y en qué tipo cabe ese número?

### Filas y columnas vigiladas

**Nivel:** 🟠 · **Formato:** programa completo.

Un almacén es una cuadrícula de `R` filas y `C` columnas. Hay `k` guardias, cada uno en una celda, y
cada guardia vigila **toda su fila y toda su columna**. Cuenta las celdas vigiladas.

- **Entrada.** Una línea con `R`, `C` y `k`. Después, `k` líneas con la fila y la columna de cada
  guardia (numeradas desde 1). Puede haber dos guardias en la misma celda.
- **Salida.** Un entero: el número de celdas vigiladas.
- **Restricciones.** `1 ≤ R, C ≤ 10⁵`; `1 ≤ k ≤ 2·10⁵`. Límite: 1 segundo, 256 MB.

```text
Entrada            Salida
3 4 1              6
2 2

Entrada            Salida
2 2 2              4
1 1
2 2
```

**Pista 1:** ¿cuántas celdas tiene el almacén más grande, y cabe una celda por posición en memoria?

---

## 🧩 Práctica externa

En todos, **antes de escribir**: anota la complejidad máxima que permiten las cotas y el tipo que
necesita la respuesta. Ese es el ejercicio; el código es la comprobación.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Two Sum](https://leetcode.com/problems/two-sum/) | LeetCode | 🟢 | Leer la cota | Con el `n` máximo de este enunciado, ¿cuántas parejas hay, y caben en un segundo? |
| [ ] | [Contains Duplicate](https://leetcode.com/problems/contains-duplicate/) | LeetCode | 🟢 | Leer la cota | ¿Cabe comparar cada pareja con el `n` de este enunciado? |
| [ ] | [Maximum Subarray](https://leetcode.com/problems/maximum-subarray/) | LeetCode | 🟡 | Leer la cota | Con `n` hasta `10⁵`, ¿qué complejidad te queda después de descartar las parejas de extremos? |
| [ ] | [Sherlock and Array](https://www.hackerrank.com/challenges/sherlock-and-array/problem) | HackerRank | 🟢 | Leer la cota | ¿Hace falta volver a sumar la izquierda y la derecha para cada posición? |
| [ ] | [TapeEquilibrium](https://app.codility.com/programmers/lessons/3-time_complexity/tape_equilibrium/) | Codility | 🟢 | Leer la cota | Si mueves el corte una posición, ¿qué cambia en cada parte? |
| [ ] | [CountDiv](https://app.codility.com/programmers/lessons/5-prefix_sums/count_div/) | Codility | 🟢 | Valor frente a tamaño | Con `B` hasta `2·10⁹`, ¿puedes recorrer el intervalo? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Array Manipulation](https://www.hackerrank.com/challenges/crush/problem) | HackerRank | 🟠 | Varios parámetros | Con `n` y `m` máximos, ¿cuántos pasos da aplicar cada operación celda a celda? |
| [ ] | [Count Number of Bad Pairs](https://leetcode.com/problems/count-number-of-bad-pairs/) | LeetCode | 🟡 | Contar al revés, tipo de la respuesta | ¿Es más fácil contar las parejas malas o las buenas, y cuántas parejas hay en total? |
| [ ] | [Number Spiral](https://cses.fi/problemset/task/1071) | CSES | 🟡 | Valor frente a tamaño | Con coordenadas hasta `10⁹`, ¿puedes construir la espiral? |
| [ ] | [Missing Number](https://cses.fi/problemset/task/1083) | CSES | 🟢 | Leer la cota | ¿Qué sabes de la suma de todos los números del 1 al `n`? |

---

## ✅ Criterio de dominio

- Recitar la tabla `n` → complejidad de §3 sin mirar, y justificar dos de sus filas con la cuenta.
- Calcular en menos de un minuto si una estructura cabe en 256 MB, en `int`, en `long long` y con
  objetos de Java.
- Decir, ante cualquier enunciado del núcleo, la complejidad máxima y el tipo de la respuesta antes de
  escribir código.
- Explicar por qué Python pierde una fila de la tabla y Java media con objetos.

---

**Anterior:** [`01/01` — El juez, los veredictos y las plataformas](01-el-juez-los-veredictos-y-las-plataformas.md) ·
**Siguiente:** [`01/03` — Entrada, salida y la plantilla](03-entrada-salida-y-plantilla.md) ·
**Relacionado:** [`02/01` — Notación asintótica](../02-analisis/01-notacion-asintotica.md); [`01/05` — Probar sin IDE](05-probar-sin-ide-y-stress-test.md).
