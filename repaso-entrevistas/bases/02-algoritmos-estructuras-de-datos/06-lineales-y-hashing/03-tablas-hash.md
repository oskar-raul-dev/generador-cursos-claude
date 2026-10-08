# 03 — Tablas *hash* por dentro y los *anti-hash tests*

> Cómo funciona una tabla *hash* —encadenamiento y direccionamiento abierto—, qué cuesta según el
> factor de carga, por qué el *rehash* es amortizado, y cómo se degrada a lineal ante un caso adversario:
> el `unordered_map` atacado, el árbol del `HashMap` de Java y el *hash* propio con `splitmix64`.
>
> **Niveles:** encadenamiento y direccionamiento abierto [A] · factor de carga y *rehash* [A] ·
> *anti-hash tests* y *hash* propio [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), cap. 11; Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §3.4.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--encadenamiento-y-direccionamiento-abierto) · [4](#4--factor-de-carga-y-rehash) · [5](#5--anti-hash-tests-y-hash-propio) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

La tabla *hash* es la estructura que más se usa en entrevistas: contar, deduplicar, recordar lo visto,
indexar por una clave. Se dice que es `O(1)`, y casi siempre lo es. Pero:

- **«Casi siempre» es un promedio**, que depende de que las claves se repartan bien. Con una función de
  *hash* conocida, un adversario puede elegir claves que caigan todas en la misma cubeta, y cada
  operación pasa a costar `O(n)`. En Codeforces, donde los participantes pueden atacar las soluciones
  de otros (*hacks*), esto ocurre de verdad con `unordered_map`.
- **El coste depende del factor de carga**, y crecer cuesta un *rehash* de todo: ¿por qué sigue siendo
  `O(1)`?
- **El contrato entre igualdad y *hash*** decide si una clave se encuentra: una clase con `equals` y sin
  `hashCode` coherente «pierde» elementos.

Este capítulo abre la tabla por dentro para responder las tres cosas, y es el dueño de las tablas *hash*
del corpus.

---

## 2. 📐 La teoría

**La idea.** Una función `h` lleva cada clave a una de `m` cubetas; la clave se busca solo en su cubeta.
Dos claves distintas en la misma cubeta son una **colisión**. Hay dos formas de resolverlas:

- **Encadenamiento**: cada cubeta es una lista de las claves que caen en ella.
- **Direccionamiento abierto**: todas las claves viven en el arreglo; si la cubeta está ocupada, se
  **sondea** otra según una secuencia (lineal: `h, h+1, h+2, …`).

**El factor de carga** es `α = n / m`: elementos por cubeta.

**Teorema (coste esperado con encadenamiento).** Bajo *hash* uniforme simple (cada clave cae en cada
cubeta con probabilidad `1/m`, independientemente), una búsqueda sin éxito cuesta `Θ(1 + α)` en
esperanza, y una con éxito, también `Θ(1 + α)`.

*Prueba de la búsqueda sin éxito.* La clave buscada cae en una cubeta cualquiera, y la longitud esperada
de cada lista es `n / m = α`; recorrerla entera y calcular `h` cuesta `1 + α`. CLRS, 3.ª ed., teoremas
11.1 y 11.2.

Con `α` acotado por una constante (manteniendo `m` proporcional a `n`), las operaciones son `O(1)`
**esperado**. Con sondeo lineal, Knuth calculó `≈ ½ (1 + 1/(1−α)²)` sondas por búsqueda sin éxito y
`≈ ½ (1 + 1/(1−α))` con éxito: con `α = 0,5`, 2,5 y 1,5; con `α = 0,75`, 8,5 y 2,5. Por eso las tablas
abiertas crecen antes que las encadenadas.

**El caso peor** es `Θ(n)` por operación: todas las claves en una cubeta. El «`O(1)`» es una afirmación
sobre la **distribución** de las claves, no sobre todas las entradas.

**El *rehash*.** Cuando `α` pasa de un umbral, se reserva un arreglo del doble y se reinsertan todas las
claves: `Θ(n)` esa vez. Como el tamaño se duplica, entre dos *rehash* hay tantas inserciones como
elementos se copian, y el coste **amortizado** por inserción es `O(1)` (el mismo argumento del arreglo
dinámico, [`02/03`](../02-analisis/03-analisis-amortizado.md)).

**El contrato igualdad-*hash*.** Si `a` es igual a `b`, `h(a)` tiene que ser igual a `h(b)`; si no,
`a` y `b` caen en cubetas distintas y la tabla no ve que son la misma clave. Y la clave no debe cambiar
mientras está dentro: su cubeta se calculó con el valor antiguo.

---

## 3. 🧱 Encadenamiento y direccionamiento abierto

**Qué es.** Las dos formas de resolver colisiones de §2. Las bibliotecas eligen: C++ `unordered_map` y
Java `HashMap` encadenan; Python `dict` usa direccionamiento abierto.

**Por qué es correcto.** Una clave está, si está, en su cubeta (encadenamiento) o en la secuencia de
sondeo que empieza en su cubeta, antes del primer hueco (abierto). Por eso, en direccionamiento abierto,
**borrar** no puede dejar un hueco sin más: rompería las secuencias de otras claves. Se marca con una
**lápida** o se recolocan las siguientes.

**Cómo va**, el arreglo `[5, 2, 9, 1, 5, 6]` en una tabla de `m = 7` cubetas con `h(x) = x mod 7`:

```text
clave   h   encadenamiento               sondeo lineal
5       5   cubeta 5: [5]                posición 5
2       2   cubeta 2: [2]                posición 2
9       2   cubeta 2: [2, 9]  colisión   2 ocupada → 3
1       1   cubeta 1: [1]                posición 1
5       5   ya está                      encontrada en 5
6       6   cubeta 6: [6]                posición 6
tabla abierta: [−, 1, 2, 9, −, 5, 6]
```

**Cuánto.** `O(1 + α)` esperado por operación con encadenamiento; con sondeo lineal, las fórmulas de §2.
Memoria `Θ(n + m)`.

**La plantilla**, una tabla de enteros con sondeo lineal, que es lo que hace falta escribir cuando la
biblioteca no basta o el entrevistador lo pide:

```cpp
#include <cstdint>
#include <utility>
#include <vector>

// Conjunto de enteros de 64 bits con sondeo lineal; capacidad potencia de 2; α ≤ 1/2.
struct IntSet {
    std::vector<uint64_t> keys; std::vector<char> used; size_t n = 0;
    explicit IntSet(size_t cap = 16) : keys(cap), used(cap) {}
    size_t slot(uint64_t x) const {               // mezcla: los bits altos influyen en los bajos
        uint64_t h = x * 0x9e3779b97f4a7c15ULL;
        return (h ^ (h >> 32)) & (keys.size() - 1);
    }
    bool contains(uint64_t x) const {
        for (size_t i = slot(x); used[i]; i = (i + 1) & (keys.size() - 1))
            if (keys[i] == x) return true;
        return false;
    }
    void insert(uint64_t x) {
        if (2 * (n + 1) > keys.size()) grow();
        size_t i = slot(x);
        for (; used[i]; i = (i + 1) & (keys.size() - 1)) if (keys[i] == x) return;
        keys[i] = x; used[i] = 1; n++;
    }
    void grow() {                                 // rehash al doble: O(n), amortizado O(1)
        IntSet bigger(keys.size() * 2);
        for (size_t i = 0; i < keys.size(); i++) if (used[i]) bigger.insert(keys[i]);
        *this = std::move(bigger);
    }
};
```

```java
// Conjunto de long con sondeo lineal; capacidad potencia de 2; α ≤ 1/2.
static final class LongSet {
    long[] keys = new long[16]; boolean[] used = new boolean[16]; int n = 0;
    int slot(long x) {
        long h = x * 0x9e3779b97f4a7c15L;
        return (int) (h ^ (h >>> 32)) & (keys.length - 1);
    }
    boolean contains(long x) {
        for (int i = slot(x); used[i]; i = (i + 1) & (keys.length - 1))
            if (keys[i] == x) return true;
        return false;
    }
    void add(long x) {
        if (2 * (n + 1) > keys.length) grow();
        int i = slot(x);
        for (; used[i]; i = (i + 1) & (keys.length - 1)) if (keys[i] == x) return;
        keys[i] = x; used[i] = true; n++;
    }
    void grow() {
        long[] ok = keys; boolean[] ou = used;
        keys = new long[ok.length * 2]; used = new boolean[ok.length * 2]; n = 0;
        for (int i = 0; i < ok.length; i++) if (ou[i]) add(ok[i]);
    }
}
```

```python
class IntSet:
    """Conjunto con sondeo lineal; capacidad potencia de 2; α ≤ 1/2. Didáctico: en Python, usa set."""
    def __init__(self, cap=16):
        self.keys, self.n = [None] * cap, 0

    def _slot(self, x):
        return hash(x) & (len(self.keys) - 1)

    def __contains__(self, x):
        i = self._slot(x)
        while self.keys[i] is not None:
            if self.keys[i] == x:
                return True
            i = (i + 1) & (len(self.keys) - 1)
        return False

    def add(self, x):
        if 2 * (self.n + 1) > len(self.keys):
            old, self.keys, self.n = self.keys, [None] * (2 * len(self.keys)), 0
            for k in old:
                if k is not None:
                    self.add(k)
        i = self._slot(x)
        while self.keys[i] is not None:
            if self.keys[i] == x:
                return
            i = (i + 1) & (len(self.keys) - 1)
        self.keys[i], self.n = x, self.n + 1
```

- **Capacidad potencia de 2** y máscara `& (cap − 1)` en lugar de `mod`. Con una máscara, los bits bajos
  deciden la cubeta: por eso la clave se **mezcla** antes (la multiplicación por la constante de
  Fibonacci, `0x9e37…`, y un *xor* que baja los bits altos a los bajos).
- **`α ≤ 1/2`**: con sondeo lineal, por encima de `0,7` las secuencias se alargan rápido (agrupamiento
  primario).
- **Sin borrado**: borrar en sondeo lineal exige lápidas o recolocar; la plantilla no lo necesita para
  contar o deduplicar.
- **En la biblioteca**, lo normal es usar la de cada lenguaje: `unordered_map`/`unordered_set`,
  `HashMap`/`HashSet`, `dict`/`set`/`Counter`. Esta plantilla gana cuando la constante importa (sin
  nodos ni *boxing*) o cuando hay que defenderse de un adversario.

### De la versión ingenua a la buena

**El problema.** Contar cuántas veces aparece cada una de `n = 10⁶` palabras.

**La versión ingenua:**

```java
// O(n · d): busca cada palabra en una lista de pares, con d palabras distintas. Con d = 10⁵, 10¹¹.
static java.util.List<Object[]> countWords(String[] words) {
    java.util.List<Object[]> counts = new java.util.ArrayList<>();
    outer:
    for (String w : words) {
        for (Object[] p : counts) if (p[0].equals(w)) { p[1] = (Integer) p[1] + 1; continue outer; }
        counts.add(new Object[]{w, 1});
    }
    return counts;
}
```

> «Cada palabra busca en todas las distintas vistas: lineal por consulta. Si la palabra me dice
> directamente en qué cubeta mirar, cada búsqueda revisa en promedio un elemento: `O(1)` esperado.»

**El camino a la buena.** `HashMap<String, Integer>` con `merge(w, 1, Integer::sum)`; en Python,
`Counter(words)`; en C++, `unordered_map<string, int>` con `++cnt[w]`.

**Cuándo sí**: contar, deduplicar, indexar por clave, «¿lo he visto antes?». **Cuándo no**: si hace
falta el orden de las claves (mapa ordenado, [`03/01`](../03-biblioteca-estandar/01-cpp-contenedores.md), [`07/02`](../07-arboles/02-bst-y-balanceados.md)); si las claves son enteros pequeños, un
arreglo es más rápido.

> **Veredicto:** encadenamiento y direccionamiento abierto dan `O(1)` esperado con `α` acotado. La tabla
> abierta es más compacta y rápida, pero borrar es delicado.

---

## 4. 🧱 Factor de carga y *rehash*

**Qué es.** La política de crecimiento: cuando `n / m` pasa de un umbral, duplicar `m` y reinsertar.

**Por qué es correcto.** El *rehash* reinserta todas las claves con la función de la tabla nueva: después,
cada clave está en su cubeta nueva. El coste amortizado sale de §2.

**Cómo va**, una tabla que empieza con `m = 4` y crece al doble cuando `α` pasaría de `1/2`:

```text
inserción   n antes   m antes   ¿crece?    copias   copias acumuladas
1, 2        0, 1      4         no         0        0
3           2         4         sí → 8     2        2
4           3         8         no         0        2
5           4         8         sí → 16    4        6
6 a 8       5 a 7     16        no         0        6
9           8         16        sí → 32    8        14
…           tras n inserciones, copias acumuladas < 2n
```

**Cuánto.** `Θ(n)` el *rehash*; `O(1)` amortizado por inserción; memoria `Θ(n)`.

**Los umbrales de cada biblioteca:**

| Biblioteca | Resolución | Crece cuando | Reservar de antemano |
|---|---|---|---|
| C++ `unordered_map` | Encadenamiento | `α > max_load_factor()` (1,0 por defecto) | `reserve(n)` |
| Java `HashMap` | Encadenamiento (árbol si la cubeta pasa de 8) | `α > 0,75` | `HashMap.newHashMap(n)` (Java 19+) |
| Python `dict` | Direccionamiento abierto | lleno en 2/3 | no hay; se construye de una vez si se puede |

### De la versión ingenua a la buena

**El problema.** Una tabla propia que crece «lo justo» para ahorrar memoria: una cubeta más por cada
inserción que la llena.

**La versión ingenua:**

```java
// falla: la inserción 33 no termina. Con + 16 la capacidad pasa a 80 y la máscara solo alcanza 32 casillas.
// Y aun con % en vez de la máscara: crece en una cantidad fija, O(n²) copias en total.
void growNaive() {
    long[] ok = keys; boolean[] ou = used;
    keys = new long[ok.length + 16]; used = new boolean[ok.length + 16]; n = 0;   // + 16, no × 2
    for (int i = 0; i < ok.length; i++) if (ou[i]) add(ok[i]);
}
```

> «Si crezco en una cantidad fija, cada `k` inserciones copio todo: `n²/k` copias. Si crezco al doble,
> entre dos copias hay tantas inserciones como elementos copio: lineal en total, `O(1)` amortizado.
> Además, con `+ 16` la capacidad deja de ser potencia de 2 y la máscara falla.»

**El camino a la buena.** El `grow` de la plantilla: siempre `× 2`.

**Cuándo sí**: siempre que la tabla crezca. **Cuándo no**: si se conoce `n` de antemano, se reserva la
capacidad y no hay *rehash* (`reserve`, `newHashMap`).

> **Veredicto:** el *rehash* cuesta lineal, pero duplicando la capacidad se paga una vez por elemento:
> `O(1)` amortizado. Si sabes cuántos elementos habrá, reserva.

---

## 5. 🧱 *Anti-hash tests* y *hash* propio

**Qué es.** Un *anti-hash test* es una entrada construida para que todas las claves caigan en pocas
cubetas de una función de *hash* conocida. El remedio es una función de *hash* que el atacante **no
conoce**: con una semilla aleatoria elegida al ejecutar.

**Por qué es correcto** (el enunciado y una frase): si la función se elige al azar de una familia
universal ([`19/02`](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md)) **después** de fijada la entrada, la probabilidad de colisión de dos claves es `O(1/m)`
para cualquier entrada, y el coste esperado vuelve a ser `O(1 + α)`.

**Cómo es el ataque.** En libstdc++, `std::hash` de un entero es la identidad y la cubeta es `x mod m`,
con `m` sacado de una lista fija de primos. Una entrada de `n` múltiplos de uno de esos primos cae en una
sola cubeta: `n` inserciones cuestan `Θ(n²)`, y con `n = 2·10⁵` el programa da TLE. En Java, las cubetas
de `HashMap` con más de 8 claves se convierten en un árbol rojinegro (desde Java 8) si la tabla tiene al
menos 64 cubetas, lo que limita el daño a `O(log n)` por operación con claves comparables; con claves no
comparables, sigue siendo lineal. En Python, el *hash* de un entero es el propio valor (módulo
`2⁶¹ − 1`) y también se pueden fabricar colisiones; las cadenas están protegidas por una semilla aleatoria
desde Python 3.3.

**Cuánto.** El *hash* propio añade unas pocas operaciones por llamada; protege del caso cuadrático.

**La plantilla**, en C++ con `splitmix64` y en Java mezclando la clave antes de usarla:

```cpp
#include <chrono>
#include <cstdint>
#include <unordered_map>

// splitmix64 con una semilla del reloj: el atacante no puede predecir las cubetas.
struct SafeHash {
    static uint64_t splitmix64(uint64_t x) {
        x += 0x9e3779b97f4a7c15ULL;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
        x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
        return x ^ (x >> 31);
    }
    size_t operator()(uint64_t x) const {
        static const uint64_t SEED =
            std::chrono::steady_clock::now().time_since_epoch().count();
        return splitmix64(x + SEED);
    }
};

std::unordered_map<long long, int, SafeHash> cnt;   // uso: igual que un unordered_map normal
```

```java
// Mezcla biyectiva con semilla aleatoria: claves distintas siguen siendo distintas, y las cubetas
// dejan de ser predecibles. Se usa mix(x) como clave del HashMap.
static final long SEED = System.nanoTime();

static long mix(long x) {
    x += SEED + 0x9e3779b97f4a7c15L;
    x = (x ^ (x >>> 30)) * 0xbf58476d1ce4e5b9L;
    x = (x ^ (x >>> 27)) * 0x94d049bb133111ebL;
    return x ^ (x >>> 31);
}

// Uso: map.merge(mix(x), 1, Integer::sum);  para contar o comprobar pertenencia.
```

- **La semilla del reloj** hace que cada ejecución use una función distinta; una semilla fija vuelve a ser
  atacable.
- **`splitmix64` es biyectiva** (sumas, *xorshifts* y productos por impares lo son): `mix(x)` no crea
  colisiones nuevas, así que se puede usar como clave sin perder información, aunque para recuperar `x`
  hay que guardarlo aparte.
- **En Python**, la defensa equivalente es usar como clave `x ^ R` con `R` aleatorio de 64 bits, o
  convertir a cadena, cuyo *hash* está aleatorizado.

**Cuándo sí**: en concursos con *hacks* (Codeforces) y siempre que las claves vengan de alguien que puede
elegirlas. **Cuándo no**: si las claves son enteros pequeños, un arreglo; si hace falta el peor caso
garantizado, un mapa ordenado `O(log n)`.

> **Veredicto:** el `O(1)` de una tabla *hash* supone que nadie elige las claves contra ti. Con una
> semilla aleatoria, vuelve a ser cierto en esperanza para cualquier entrada.

---

## 6. ⏱️ La tabla de costes

| Operación | Esperado | Peor caso | Lo que la tabla no dice |
|---|---|---|---|
| Buscar, insertar, borrar (encadenamiento) | `O(1 + α)` | `Θ(n)` | El peor caso lo elige un adversario si el *hash* es conocido |
| Igual, direccionamiento abierto | `O(1/(1 − α))` | `Θ(n)` | Borrar exige lápidas |
| `HashMap` de Java con claves comparables | `O(1)` | `O(log n)` | La cubeta se convierte en árbol con más de 8 claves |
| *Rehash* | `O(1)` amortizado | `Θ(n)` esa vez | `reserve` lo evita si se conoce `n` |
| Recorrer la tabla | `Θ(n + m)` | `Θ(n + m)` | Sin orden (salvo `dict` y `LinkedHashMap`, en orden de inserción) |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Cuántas veces aparece», «el primero que se repite», «¿existe?» | Tabla *hash* | Contar y pertenencia en `O(1)` esperado |
| Claves hasta `10⁹` o cadenas, sin necesidad de orden | Tabla *hash* | Un arreglo no cabe |
| Claves enteras pequeñas (letras, edades) | Arreglo de contadores | Más rápido que cualquier *hash* |
| Codeforces con *hacks*, `n ≥ 10⁵` y `unordered_map` | *Hash* propio con semilla | El caso adversario existe |
| «Mínimo / siguiente mayor que una clave» | Mapa ordenado, no *hash* | La tabla *hash* no tiene orden |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «El `HashMap` es `O(1)`» | `O(1)` **esperado** con claves bien repartidas; el peor caso es `Θ(n)` (o `O(log n)` en Java con claves comparables) |
| «En un concurso nadie va a atacar mi *hash*» | En Codeforces, los *hacks* contra `unordered_map` son habituales; se usa una semilla aleatoria |
| «Si redefino `equals`, ya funciona como clave» | También hay que redefinir `hashCode` de forma coherente |
| «El *rehash* hace que insertar sea `O(n)`» | Esa inserción sí; amortizado, `O(1)` porque la capacidad se duplica |
| «Un `unordered_map` siempre gana a un `map`» | Con claves pequeñas o pocas operaciones, el `map` o un arreglo pueden ganar; y la tabla atacada pierde |
| «Python no tiene ese problema» | Las cadenas están aleatorizadas; los enteros, no |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  cap. 11: encadenamiento, direccionamiento abierto, *hashing* universal y su análisis. *Lectura troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §3.4, con el código en
  [*Hash Tables*](https://algs4.cs.princeton.edu/34hash/). *Lectura troncal.*
- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 3 (Addison-Wesley), §6.4: el análisis del
  sondeo lineal.
- **Documentación** — Java, [`HashMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/HashMap.html):
  factor de carga y capacidad; cppreference, [`std::unordered_map`](https://en.cppreference.com/cpp/container/unordered_map);
  Python, [*Data model*](https://docs.python.org/3/reference/datamodel.html) (`__hash__` y `__eq__`).

---

## 🧠 Preguntas

1. ¿Qué es una colisión, y cuáles son las dos formas de resolverlas? 🟢
2. ¿Qué es el factor de carga, y qué valor por defecto usa Java? 🟢
3. ¿Por qué hay que redefinir `hashCode` cuando se redefine `equals`? 🟢
4. ¿Por qué el caso peor de una tabla *hash* es `Θ(n)` por operación? 🟡
5. ¿Por qué el *rehash* es `O(1)` amortizado si copia toda la tabla? 🟡
6. ¿Por qué en direccionamiento abierto no se puede borrar dejando un hueco? 🟡
7. ¿Qué cambió en el `HashMap` de Java 8 para las cubetas con muchas colisiones, y qué garantiza? 🟡
8. Demuestra que, bajo *hash* uniforme simple, una búsqueda sin éxito con encadenamiento cuesta `Θ(1 + α)` esperado. 🟠
9. Explica cómo se construye un *anti-hash test* contra `unordered_map` de libstdc++ con enteros. 🟠
10. Compara cómo se protegen de una entrada adversaria `unordered_map`, `HashMap` y `dict`, y qué haces en cada lenguaje. 🟠
11. ¿Por qué se mezcla la clave antes de quedarse con sus bits bajos cuando la capacidad es potencia de 2? 🟠
12. ¿Qué es una familia universal de funciones de *hash*, y por qué elegir la función al azar al ejecutar protege de cualquier entrada? 🔴
13. ¿Qué es el agrupamiento primario del sondeo lineal, y por qué aun así suele ser más rápido que el encadenamiento en la práctica? 🔴

---

## 🧩 Problemas propios

### Votos repetidos

**Nivel:** 🟢 · **Formato:** programa completo.

Llegan `n` votos con el identificador de quien vota. Imprime cuántos votantes distintos hay, el que más
veces votó (a igualdad, el de menor identificador) y cuántas veces lo hizo.

- **Entrada.** Una línea con `n`. Una línea con los `n` identificadores.
- **Salida.** Una línea con los tres valores.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ identificador ≤ 10¹⁸`.

```text
Entrada                                              Salida
6                                                    3 5 3
1000000000000000000 5 7 5 1000000000000000000 5

Entrada                                              Salida
3                                                    2 3 2
3 3 9
```

**Pista 1:** ¿cabe un arreglo indexado por el identificador?

### Matrículas en las dos listas

**Nivel:** 🟢 · **Formato:** programa completo.

Hay dos listas de matrículas. Imprime las que aparecen en las dos, en el orden de la primera lista y sin
repetir.

- **Entrada.** Una línea con `n` y `m`. Una línea con las `n` de la primera y otra con las `m` de la
  segunda.
- **Salida.** Las matrículas comunes separadas por espacios, o una línea vacía si no hay.
- **Restricciones.** `1 ≤ n, m ≤ 2·10⁵`; matrículas de 1 a 10 caracteres alfanuméricos.

```text
Entrada                  Salida
4 3                      luis eva
ana luis eva luis
eva pedro luis

Entrada                  Salida
3 3                      AB1 ab1
AB1 ab1 AB1
ab1 AB1 AB1
```

**Pista 1:** ¿qué estructura responde «¿está en la segunda lista?» en `O(1)`, y cuál «¿ya la imprimí?»?

### Distintos por ventana

**Nivel:** 🟡 · **Formato:** programa completo.

Imprime cuántos valores distintos hay en cada ventana de `k` elementos consecutivos.

- **Entrada.** Una línea con `n` y `k`. Una línea con los `n` valores.
- **Salida.** `n − k + 1` enteros separados por espacios.
- **Restricciones.** `1 ≤ k ≤ n ≤ 2·10⁵`; `1 ≤ a[i] ≤ 10⁹`.

```text
Entrada            Salida
6 3                3 3 3 3
5 2 9 1 5 6

Entrada            Salida
5 2                2 2 1 2
1 2 1 1 3
```

**Pista 1:** al mover la ventana, ¿qué valor entra, cuál sale, y cuándo cambia el número de distintos?

---

## 🧩 Práctica externa

> 💡 **Truco.** En Codeforces, si tu solución con `unordered_map` pasa los ejemplos, pregúntate antes de
> enviar si alguien puede elegir las claves; pide a una IA que te explique el ataque, no que te escriba
> el *hash* ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)). La lección 4 de Codility (*Counting Elements*) ya está en el bloque `01`.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Ransom Note](https://leetcode.com/problems/ransom-note/) | LeetCode | 🟢 | Contador | ¿Necesitas un mapa, o bastan 26 contadores? |
| [ ] | [Isomorphic Strings](https://leetcode.com/problems/isomorphic-strings/) | LeetCode | 🟢 | Dos mapas | ¿Por qué no basta un mapa en un solo sentido? |
| [ ] | [Brick Wall](https://leetcode.com/problems/brick-wall/) | LeetCode | 🟡 | Contar posiciones de juntas | ¿Dónde cruza la línea menos ladrillos? |
| [ ] | [4Sum II](https://leetcode.com/problems/4sum-ii/) | LeetCode | 🟡 | Encuentro en el medio con mapa | Si juntas los arreglos de dos en dos, ¿qué buscas en el mapa? |
| [ ] | [Insert Delete GetRandom O(1)](https://leetcode.com/problems/insert-delete-getrandom-o1/) | LeetCode | 🟡 | Mapa a índices de un arreglo | ¿Cómo borras de un arreglo en `O(1)` si no importa el orden? |
| [ ] | [Frequency Queries](https://www.hackerrank.com/challenges/frequency-queries/problem) | HackerRank | 🟡 | Dos mapas: valor→frecuencia y frecuencia→cuántos | ¿Cómo respondes «¿hay algún valor con frecuencia `f`?» sin recorrer? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Registration System](https://codeforces.com/problemset/problem/4/C) | Codeforces | 🟢 | Mapa de cadena a contador | ¿Qué número le toca a un nombre repetido? |
| [ ] | [Valid Sudoku](https://leetcode.com/problems/valid-sudoku/) | LeetCode | 🟡 | Conjuntos por fila, columna y caja | ¿Qué índice de caja tiene la celda `(i, j)`? |
| [ ] | [Contiguous Array](https://leetcode.com/problems/contiguous-array/) | LeetCode | 🟡 | Prefijos y primera aparición | Si cambias los 0 por −1, ¿qué buscas? |
| [ ] | [Powers of Two](https://codeforces.com/problemset/problem/702/B) | Codeforces | 🟡 | Contar complementos | Para cada potencia de 2, ¿qué valor necesita cada elemento? |
| [ ] | [Count Triplets](https://www.hackerrank.com/challenges/count-triplets-1/problem) | HackerRank | 🟠 | Dos mapas: a la izquierda y pares pendientes | Para que `a[j]` sea el centro, ¿qué necesitas a cada lado? |

---

## ✅ Criterio de dominio

- Explicar encadenamiento, direccionamiento abierto, factor de carga y *rehash*, con sus costes.
- Escribir la tabla con sondeo lineal y el *hash* propio con `splitmix64` sin mirar.
- Explicar el ataque a `unordered_map` y cómo se defiende cada lenguaje.
- Resolver 4Sum II e Insert Delete GetRandom O(1) sin pista 2.

---

**Anterior:** [`06/02` — Listas enlazadas](02-listas-enlazadas.md) · **Siguiente:** [`06/04` — *Hashing* de secuencias](04-hashing-de-secuencias.md) ·
**Relacionado:** [`19/02` — *Hashing* universal](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md); [`03/03` — Java: las colecciones](../03-biblioteca-estandar/03-java-colecciones.md).
