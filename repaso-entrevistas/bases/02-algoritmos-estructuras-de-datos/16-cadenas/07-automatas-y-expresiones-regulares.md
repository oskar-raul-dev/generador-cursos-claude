# 07 — Autómatas y expresiones regulares

> De la expresión regular a un programa que la reconoce: autómatas deterministas (DFA) y no deterministas
> (NFA), la construcción de Thompson que convierte una expresión en un NFA lineal en su tamaño, la
> construcción de subconjuntos que lo convierte en DFA —a veces exponencial—, y por qué los motores de
> `std::regex`, `java.util.regex` y `re`, que usan vuelta atrás, pueden tardar un tiempo exponencial con una
> expresión de diez caracteres. Es el dueño de los autómatas finitos del corpus.
>
> **Niveles:** DFA y NFA [B] · Thompson [B] · subconjuntos [B] · *backtracking* y ReDoS [B].
>
> **📚 Lectura troncal:** Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y
> computación*, 3.ª ed. (Pearson, 2007), caps. 2–4; Sedgewick y Wayne, *Algorithms*, 4.ª ed.
> (Addison-Wesley, 2011), §5.4.
>
> **Asume leído:** [`16/02` — KMP y la función de prefijo](02-kmp.md).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--dfa-y-nfa) · [4](#4--thompson) · [5](#5--subconjuntos) · [6](#6--backtracking-y-redos) · [7](#7-️-la-tabla-de-costes) · [8](#8--cómo-se-elige) · [9](#9--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Un servicio valida correos con la expresión `^([a-z]+)+@…` y, un día, una petición con 30 letras y un
carácter inválido al final deja un núcleo del servidor al 100 % durante minutos. No es un error de la
expresión: es cómo la evalúa el motor. `java.util.regex`, `std::regex` y `re` prueban las alternativas con
**vuelta atrás**, y una expresión con cuantificadores anidados tiene un número exponencial de formas de
repartir la entrada entre ellos. Es un ataque con nombre propio: ReDoS.

La teoría de autómatas dice que no tiene por qué ser así: toda expresión regular se puede reconocer en
`O(n · m)` simulando un NFA (Thompson, 1968), o en `O(n)` con un DFA si el número de estados no explota. El
capítulo recorre ese camino —expresión, NFA, DFA— y explica cuándo la vuelta atrás es inevitable (las
referencias hacia atrás) y cuándo es un descuido.

> 🧠 **Modelo mental.** Un DFA es un tablero donde cada letra te lleva a una sola casilla. Un NFA permite
> estar en varias casillas a la vez: simularlo es llevar la **lista** de casillas posibles, no probar un
> camino y retroceder.

Los ejemplos usan la expresión `(a|b)*abb` —las cadenas de `a` y `b` que terminan en `abb`— y la cadena
`aababb`, que la cumple.

---

## 2. 📐 La teoría

**DFA.** Un conjunto finito de estados, un estado inicial, unos estados finales y una función de
transición `δ(q, c)` que da **un** estado por cada estado y carácter. Reconoce una cadena si, partiendo del
inicial y aplicando `δ` carácter a carácter, termina en un final. `Θ(n)` por cadena.

**NFA.** Igual, pero `δ(q, c)` es un **conjunto** de estados (quizá vacío), y hay transiciones ε que se
toman sin leer. Acepta si **algún** camino termina en un final.

**Teorema de Kleene** (enunciado). DFA, NFA y expresiones regulares reconocen exactamente la misma clase de
lenguajes: los **regulares**. Hay construcciones en los tres sentidos.

**Thompson.** De una expresión de longitud `m` sale un NFA con `O(m)` estados y transiciones: una regla por
operador (concatenación, `|`, `*`) que encadena NFA más pequeños con transiciones ε.

**Simulación del NFA.** Se lleva el conjunto de estados activos: cierre ε del inicial; por cada carácter,
los estados a los que se llega leyéndolo, y su cierre ε. Cada paso cuesta `O(m)`: `O(n · m)` en total.

**Subconjuntos.** Cada estado del DFA es un **conjunto** de estados del NFA (los que estarían activos a la
vez). Se construyen solo los alcanzables, por BFS. En el peor caso hay `2^m`: la expresión `(a|b)*a(a|b)^k`
(la `a` a `k + 1` posiciones del final) necesita `2^(k+1)` estados en cualquier DFA.

**Vuelta atrás.** Un motor que prueba una alternativa, y si falla vuelve y prueba la siguiente, explora
**caminos** del NFA en lugar de conjuntos de estados. Con `(a|a)*b` sobre `aaa…a` (sin `b`), cada `a` se puede
leer por cualquiera de las dos ramas: `2ⁿ` caminos, y ninguno acepta. Las **referencias hacia atrás**
(`(a+)\1`) no son regulares y obligan a la vuelta atrás; el resto de la sintaxis común, no.

---

## 3. 🧱 DFA y NFA

**Qué es.** Un DFA como tabla `δ[q][c]` y un recorrido; un NFA como grafo de transiciones con letras y ε.

**Por qué es correcto.** Por definición: un DFA tiene un único camino por cadena; el NFA acepta si alguno de
sus caminos acepta, y el conjunto de estados activos representa todos los caminos a la vez.

**Cómo va**, el DFA mínimo de `(a|b)*abb` («cuánto de `abb` llevo leído al final»):

```text
estado   significado            a    b
0        nada útil              1    0
1        termina en a           1    2
2        termina en ab          1    3
3        termina en abb (final) 1    0
aababb: 0 →a 1 →a 1 →b 2 →a 1 →b 2 →b 3  ✓
```

Es el autómata de KMP del patrón `abb` (`16/02`): `.*abb` es buscar `abb`.

**Cuánto.** DFA: `Θ(n)` por cadena y `Θ(estados · σ)` de memoria. NFA: `O(n · m)` simulándolo.

**La plantilla**, un DFA como tabla y el ejemplo clásico de los restos módulo `k`:

```cpp
#include <string>
#include <vector>

// Ejecuta un DFA: delta[q][c] con c ya traducido a índice; finales marcados.
bool runDfa(const std::vector<std::vector<int>>& delta, const std::vector<bool>& isFinal,
            const std::vector<int>& input) {
    int q = 0;
    for (int c : input) q = delta[q][c];
    return isFinal[q];
}

// DFA de «el número binario leído es múltiplo de k»: estado = resto; leer un bit b lleva a (2q + b) % k.
std::vector<std::vector<int>> multipleOfK(int k) {
    std::vector<std::vector<int>> delta(k, std::vector<int>(2));
    for (int q = 0; q < k; q++) for (int b = 0; b < 2; b++) delta[q][b] = (2 * q + b) % k;
    return delta;
}
```

```java
static boolean runDfa(int[][] delta, boolean[] isFinal, int[] input) {
    int q = 0;
    for (int c : input) q = delta[q][c];
    return isFinal[q];
}

static int[][] multipleOfK(int k) {
    int[][] delta = new int[k][2];
    for (int q = 0; q < k; q++) for (int b = 0; b < 2; b++) delta[q][b] = (2 * q + b) % k;
    return delta;
}
```

- **Contar cadenas aceptadas** de longitud `n`: DP sobre `(posición, estado)` con las transiciones del DFA,
  `Θ(n · estados · σ)`; es la *digit DP* de [`13/02`](../13-dp-avanzada/02-digit-dp.md) vista como autómata.
- **Validadores** (números, direcciones IP, fechas) son DFA escritos como `switch` sobre el estado: más
  fáciles de razonar que una cadena de `if`.

**Cuándo sí:** validar formatos, reconocer patrones fijos, contar cadenas con una propiedad regular.
**Cuándo no:** propiedades que necesitan memoria no acotada (paréntesis equilibrados, `aⁿbⁿ`): no son
regulares ([`22/01`](../22-teoria-de-la-computacion/01-lenguajes-y-gramaticas.md)).

> **Veredicto:** un DFA es una tabla y un bucle: `Θ(n)` por cadena. Un NFA es la misma idea con conjuntos de
> estados activos.

---

## 4. 🧱 Thompson

**Qué es.** Construir el NFA de una expresión con una pila, añadiendo transiciones ε según los operadores.
En la versión de Sedgewick y Wayne, los estados son las posiciones de la expresión (más uno final), las
transiciones con letra van de cada letra a la posición siguiente, y el grafo ε lo forman `(`, `)`, `*` y
`|`.

**Por qué es correcto.** Cada operador se traduce a un fragmento de NFA que reconoce exactamente su
lenguaje (inducción sobre la expresión): `*` añade ε de vuelta y de salto; `|` añade ε desde el `(` a la
segunda alternativa y desde el `|` al `)`.

**Cómo va**, `((a|b)*abb)` (con paréntesis exteriores, 11 caracteres y 12 estados):

```text
posición: 0 1 2 3 4 5 6 7 8 9 10 | 11 (final)
símbolo:  ( ( a | b ) * a b b )
ε: 0→1 · 1→2 · 1→4 (|) · 3→5 (| → )) · 5→6 · 1→6 y 6→1 (*) · 6→7 · 10→11
inicio (cierre ε de 0):  0 1 2 4 6 7
tras «a»:  1 2 3 4 5 6 7 8      tras «ab»: 1 2 4 5 6 7 9
…tras «aababb»: 1 2 4 5 6 7 10 11  → contiene 11: acepta
```

**Cuánto.** Construcción `Θ(m)`; simulación `O(n · m)`.

**La plantilla:**

```cpp
#include <stack>
#include <string>
#include <vector>

// NFA de Thompson (Sedgewick-Wayne): soporta letras, '.', '*', '|' y paréntesis. Coincidencia completa.
struct Nfa {
    std::string re;
    int m;
    std::vector<std::vector<int>> eps;                 // grafo de transiciones ε
    explicit Nfa(const std::string& regexp) : re("(" + regexp + ")"), m(re.size()), eps(re.size() + 1) {
        std::stack<int> ops;
        for (int i = 0; i < m; i++) {
            int lp = i;
            if (re[i] == '(' || re[i] == '|') ops.push(i);
            else if (re[i] == ')') {
                int orIdx = ops.top(); ops.pop();
                if (re[orIdx] == '|') { lp = ops.top(); ops.pop(); eps[lp].push_back(orIdx + 1); eps[orIdx].push_back(i); }
                else lp = orIdx;
            }
            if (i < m - 1 && re[i + 1] == '*') { eps[lp].push_back(i + 1); eps[i + 1].push_back(lp); }
            if (re[i] == '(' || re[i] == '*' || re[i] == ')') eps[i].push_back(i + 1);
        }
    }
    void closure(std::vector<bool>& active) const {    // añade todo lo alcanzable por ε
        std::vector<int> st;
        for (int v = 0; v <= m; v++) if (active[v]) st.push_back(v);
        while (!st.empty()) {
            int v = st.back(); st.pop_back();
            for (int w : eps[v]) if (!active[w]) { active[w] = true; st.push_back(w); }
        }
    }
    bool matches(const std::string& txt) const {
        std::vector<bool> active(m + 1, false);
        active[0] = true; closure(active);
        for (char c : txt) {
            std::vector<bool> next(m + 1, false);
            for (int v = 0; v < m; v++) if (active[v] && (re[v] == c || re[v] == '.')) next[v + 1] = true;
            closure(next);
            active.swap(next);
        }
        return active[m];
    }
};
```

```java
// Misma construcción; el grafo ε como listas y los activos como boolean[].
static String re;
static int m;
static java.util.List<java.util.List<Integer>> eps;

static void build(String regexp) {
    re = "(" + regexp + ")"; m = re.length();
    eps = new java.util.ArrayList<>();
    for (int i = 0; i <= m; i++) eps.add(new java.util.ArrayList<>());
    java.util.ArrayDeque<Integer> ops = new java.util.ArrayDeque<>();
    for (int i = 0; i < m; i++) {
        int lp = i;
        char c = re.charAt(i);
        if (c == '(' || c == '|') ops.push(i);
        else if (c == ')') {
            int orIdx = ops.pop();
            if (re.charAt(orIdx) == '|') { lp = ops.pop(); eps.get(lp).add(orIdx + 1); eps.get(orIdx).add(i); }
            else lp = orIdx;
        }
        if (i < m - 1 && re.charAt(i + 1) == '*') { eps.get(lp).add(i + 1); eps.get(i + 1).add(lp); }
        if (c == '(' || c == '*' || c == ')') eps.get(i).add(i + 1);
    }
}

static void closure(boolean[] active) {
    java.util.ArrayDeque<Integer> st = new java.util.ArrayDeque<>();
    for (int v = 0; v <= m; v++) if (active[v]) st.push(v);
    while (!st.isEmpty()) {
        int v = st.pop();
        for (int w : eps.get(v)) if (!active[w]) { active[w] = true; st.push(w); }
    }
}

static boolean matches(String txt) {
    boolean[] active = new boolean[m + 1];
    active[0] = true; closure(active);
    for (int k = 0; k < txt.length(); k++) {
        char c = txt.charAt(k);
        boolean[] next = new boolean[m + 1];
        for (int v = 0; v < m; v++) if (active[v] && (re.charAt(v) == c || re.charAt(v) == '.')) next[v + 1] = true;
        closure(next);
        active = next;
    }
    return active[m];
}
```

- **La expresión se envuelve en paréntesis** para que el último `|` tenga su `(`.
- **Coincidencia completa** (`fullmatch`): se acepta si el estado final está activo al terminar. Para
  buscar en cualquier sitio, se antepone `.*` (o se reactiva el estado 0 en cada paso).
- **`+` y `?`** se reescriben: `x+ = xx*`, `x? = (x|)`; las clases `[a-z]` se tratan como una letra que
  acepta un rango.

**Cuándo sí:** un motor de expresiones regulares sin explosión: `O(n · m)` garantizado. **Cuándo no:** si se
evalúan muchas cadenas con la misma expresión pequeña, compilar a DFA y recorrerlo es más rápido.

> **Veredicto:** Thompson convierte la expresión en un NFA de `O(m)` estados; simularlo con el conjunto de
> activos es `O(n · m)`, nunca exponencial.

---

## 5. 🧱 Subconjuntos

**Qué es.** Construir un DFA cuyos estados son conjuntos de estados del NFA: desde el cierre ε del inicial,
por BFS, la transición con `c` de un conjunto es el cierre ε de los estados alcanzables con `c`.

**Por qué es correcto.** El conjunto de activos de la simulación depende solo del conjunto anterior y del
carácter: es una función determinista sobre conjuntos. Un conjunto es final si contiene un final del NFA.

**Cómo va**, sobre el NFA de `((a|b)*abb)`: salen **5** conjuntos alcanzables, con las transiciones

```text
     a  b
0    1  2        final: 4
1    1  3        los conjuntos 0 y 2 se comportan igual: al minimizar,
2    1  2        el DFA queda con los 4 estados de §3
3    1  4
4    1  2
```

**Cuánto.** `O(2^m · σ · m)` en el peor caso; en la práctica, mucho menos, porque solo se construyen los
conjuntos alcanzables. Los motores modernos (RE2) construyen el DFA **perezosamente**, conjunto a conjunto,
con una memoria acotada.

**La plantilla**, con los conjuntos como máscaras de bits (NFA de hasta 64 estados):

```cpp
#include <cstdint>
#include <map>
#include <queue>
#include <vector>

// nfaMove[v][c] = máscara de estados alcanzados desde v leyendo c (ya con cierre ε aplicado);
// startMask = cierre ε del inicial. Devuelve la tabla del DFA (estados alcanzables) y sus máscaras.
std::vector<std::vector<int>> subsetConstruction(const std::vector<std::vector<uint64_t>>& nfaMove,
                                                 uint64_t startMask, int sigma, std::vector<uint64_t>& masks) {
    std::map<uint64_t, int> id;
    std::vector<std::vector<int>> delta;
    std::queue<uint64_t> q;
    id[startMask] = 0; masks = {startMask}; delta.push_back(std::vector<int>(sigma, -1)); q.push(startMask);
    while (!q.empty()) {
        uint64_t S = q.front(); q.pop();
        int from = id[S];
        for (int c = 0; c < sigma; c++) {
            uint64_t T = 0;
            for (int v = 0; v < 64; v++) if (S >> v & 1) T |= nfaMove[v][c];
            if (!id.count(T)) {
                id[T] = masks.size(); masks.push_back(T);
                delta.push_back(std::vector<int>(sigma, -1)); q.push(T);
            }
            delta[from][c] = id[T];
        }
    }
    return delta;
}
```

En Java es el mismo BFS con un `HashMap<Long, Integer>`; no se repite.

**Cuándo sí:** una expresión fija y muchas cadenas (lexers, filtros); contar cadenas con la DP sobre el
DFA. **Cuándo no:** expresiones con patrones del tipo «la `k`-ésima desde el final» y `k` grande: la
explosión es real.

> **Veredicto:** la construcción de subconjuntos da un DFA con transición `O(1)`, a cambio de un número de
> estados que puede ser `2^m`; en la práctica se construye perezosamente.

---

## 6. 🧱 *Backtracking* y ReDoS

**Qué es.** Lo que hacen `std::regex`, `java.util.regex.Pattern` y `re`: probar las alternativas y los
cuantificadores en orden, y volver atrás al fallar. Admiten referencias hacia atrás y otras extensiones no
regulares, y por eso no pueden limitarse a simular el NFA.

**Por qué es correcto.** Explora todos los caminos del NFA en profundidad; si alguno acepta, lo encuentra.
El problema no es la corrección: es el número de caminos.

**Cómo va.** `(a|a)*b` sobre `aaaa` (sin `b`): cada `a` puede leerse por la primera o la segunda rama, y el
motor prueba las `2⁴ = 16` formas antes de rendirse. Con 30 aes, `10⁹`. La simulación de Thompson lleva el
**conjunto** de estados activos, que tras cada `a` es el mismo: `O(n · m)`.

**Cuánto.** Exponencial en el peor caso, con expresiones que tienen cuantificadores anidados o alternativas
solapadas (`(a+)+`, `(a|a)*`, `(a|ab)*c`).

**La plantilla.** No se escribe un motor con vuelta atrás: se evita. Las reglas prácticas, en los tres
lenguajes:

```text
Evitar cuantificadores anidados sobre lo mismo:     (a+)+   (\w+\s*)*   →  a+   (\w+\s*)… reescrita
Evitar alternativas que solapan bajo un *:          (a|ab)* c           →  a(b)?… o un DFA a mano
Anclar y acotar la entrada:                         ^…$ y longitud máxima antes de evaluar
Usar un motor sin vuelta atrás cuando se pueda:     RE2 (C++), re2j (Java), google-re2 (Python)
Java 9+ y .NET permiten límites de tiempo o de pasos; Python 3.11 añadió grupos atómicos y posesivos
```

- **Cuantificadores posesivos y grupos atómicos** (`a++`, `(?>…)`) cortan la vuelta atrás donde no hace
  falta; Java los tiene desde siempre, Python desde 3.11, C++ `std::regex` no.
- **`std::regex`** es además lento en las implementaciones comunes, incluso sin casos patológicos: en
  concursos se evita.

**Cuándo sí** (la vuelta atrás): referencias hacia atrás, búsquedas hacia delante y atrás (*lookaround*),
expresiones pequeñas sobre entradas controladas. **Cuándo no:** entradas de usuarios sin control de
longitud, expresiones con anidamientos; ahí, un motor de autómatas.

> **Veredicto:** las expresiones regulares no son lineales en los motores con vuelta atrás; lo son con
> autómatas. Si la entrada viene de fuera, o se acota, o se usa un motor sin vuelta atrás.

---

## 7. ⏱️ La tabla de costes

| Técnica | Preproceso | Por cadena | Lo que la tabla no dice |
|---|---|---|---|
| DFA | `Θ(estados · σ)` | `Θ(n)` | Los estados pueden ser `2^m` |
| NFA de Thompson simulado | `Θ(m)` | `O(n · m)` | Sin explosión, nunca |
| DFA perezoso (RE2) | Bajo demanda | `Θ(n)` amortizado | Memoria acotada; recalcula si se llena |
| Vuelta atrás (`regex`, `re`) | `Θ(m)` | Exponencial peor caso | Admite referencias hacia atrás |

---

## 8. 🧭 Cómo se elige

```text
¿Validar un formato fijo (número, IP, fecha)? → DFA a mano (switch de estados)
¿Una expresión regular sobre entradas no controladas? → motor de autómatas (RE2) o Thompson
¿Muchas cadenas con la misma expresión pequeña? → subconjuntos → DFA
¿Contar cadenas con una propiedad regular? → DP sobre el DFA
¿Referencias hacia atrás? → vuelta atrás inevitable: acotar la entrada
```

> **Regla de entrevista:** si te piden «implementa *regex matching*», distingue: con `.` y `*` solamente,
> la DP de [`12/04`](../12-dp-clasica/04-dp-sobre-cadenas.md); con `|` y paréntesis, Thompson. Y menciona ReDoS si la pregunta es de producción.

---

## 9. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «¿Es un número válido / una IP / un identificador?» | DFA | Formato regular |
| «Cuántas cadenas de longitud `n` cumplen…» (propiedad regular) | DP sobre el DFA | Estado = estado del autómata |
| «Coincide con el patrón con `*`, `\|` y paréntesis» | Thompson | `O(n · m)` |
| «El servidor se cuelga con cierta entrada», expresiones con `+` anidados | ReDoS | Vuelta atrás exponencial |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Las expresiones regulares son lineales» | Con vuelta atrás, pueden ser exponenciales; con autómatas, `O(n · m)` |
| «Un NFA se simula probando caminos» | Se simula con el **conjunto** de estados activos; probar caminos es la vuelta atrás |
| «Convertir a DFA siempre compensa» | El DFA puede tener `2^m` estados |
| «Cualquier cosa que acepta `regex` es regular» | Las referencias hacia atrás no lo son |
| «`std::regex` es la opción rápida en C++» | Es lento y con vuelta atrás; para concursos, autómatas a mano |

---

## 📚 Para profundizar

- **Libro** — Hopcroft, Motwani y Ullman, *Introducción a la teoría de autómatas, lenguajes y computación*,
  3.ª ed. (Pearson, 2007), caps. 2–4: DFA, NFA, subconjuntos y expresiones regulares. *Lectura troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §5.4: el NFA de Thompson y su
  simulación. *Lectura troncal.*
- **Referencia** — Sedgewick y Wayne, [código de `NFA.java`](https://algs4.cs.princeton.edu/54regexp/NFA.java.html).
- **Documentación** — Java SE 21, [`java.util.regex.Pattern`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/regex/Pattern.html).
- **Documentación** — Python, [`re` — Regular expression operations](https://docs.python.org/3/library/re.html).

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre un DFA y un NFA? 🟢
2. ¿Qué dice el teorema de Kleene? 🟢
3. ¿Cuánto cuesta reconocer una cadena con un DFA y con un NFA simulado? 🟢
4. ¿Qué es el cierre ε y para qué sirve en la simulación? 🟡
5. ¿Cómo se traducen `*` y `|` en la construcción de Thompson? 🟡
6. ¿Qué motores usan `std::regex`, `java.util.regex` y `re`, y qué consecuencia tiene? 🟡
7. ¿Qué es ReDoS y qué tipo de expresión lo provoca? 🟡
8. ¿Por qué la construcción de subconjuntos puede dar `2^m` estados? Da una expresión. 🟠
9. ¿Por qué la simulación del NFA nunca es exponencial? 🟠
10. ¿Cómo cuentas las cadenas de longitud `n` que acepta un DFA? 🟠
11. ¿Por qué las referencias hacia atrás obligan a la vuelta atrás? 🟠
12. ¿Qué relación hay entre el autómata de KMP y el DFA de `.*p`? 🔴
13. ¿Cómo protegerías un servicio que evalúa expresiones regulares sobre entradas de usuarios? 🔴

---

## 🧩 Problemas propios

### Múltiplos de `k`

**Nivel:** 🟡 · **Formato:** programa completo.

¿Cuántas cadenas binarias de longitud `n` (con ceros a la izquierda permitidos) representan un número
múltiplo de `k`? Módulo `10⁹ + 7`.

- **Entrada.** Una línea con `n` y `k`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 10⁵`; `1 ≤ k ≤ 1 000`.

```text
Entrada     Salida
3 3         3

Entrada     Salida
4 5         4
```

**Pista 1:** si conoces el resto del número leído hasta ahora, ¿qué resto tiene al añadir un bit?

### `grep` mínimo

**Nivel:** 🟠 · **Formato:** programa completo.

Una expresión con letras minúsculas, `.`, `*`, `|` y paréntesis. Para cada cadena, imprime `YES` si la
expresión la describe **entera** y `NO` si no.

- **Entrada.** Una línea con la expresión. Una línea con `q`. Después, `q` líneas con una cadena.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ |expresión| ≤ 1 000`; `1 ≤ q ≤ 100`; cada cadena de hasta `10⁴` caracteres.

```text
Entrada         Salida
(a|b)*abb       YES
3               NO
aababb          YES
abab
abb

Entrada         Salida
a*              YES
2               NO
a
b
```

**Pista 1:** con expresiones de mil caracteres y entradas de diez mil, ¿qué coste te garantiza llevar el
conjunto de estados activos?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de pedir ayuda con un validador que falla, dibuja su DFA con los estados y las
> transiciones: cada `if` encadenado que no sabes situar en el dibujo es un error en potencia. Si una IA te
> ayuda, que sea a revisar el dibujo ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Matching Specific String](https://www.hackerrank.com/challenges/matching-specific-string/problem) | HackerRank | 🟢 | Expresión regular de biblioteca | ¿Qué devuelve la búsqueda sin anclar? |
| [ ] | [Number of Valid Words in a Sentence](https://leetcode.com/problems/number-of-valid-words-in-a-sentence/) | LeetCode | 🟢 | Validador por estados | ¿Qué estados atraviesa una palabra válida? |
| [ ] | [String to Integer (atoi)](https://leetcode.com/problems/string-to-integer-atoi/) | LeetCode | 🟡 | Máquina de estados | ¿Qué estados hay entre los espacios iniciales y el primer no dígito? |
| [ ] | [Validate IP Address](https://leetcode.com/problems/validate-ip-address/) | LeetCode | 🟡 | Validador por tramos | ¿Qué reglas tiene un tramo IPv4 y uno IPv6? |
| [ ] | [Detect HTML links](https://www.hackerrank.com/challenges/detect-html-links/problem) | HackerRank | 🟡 | Expresión con grupos | ¿Qué parte del enlace capturas, y cómo evitas que el `.*` se coma de más? |
| [ ] | [Valid Number](https://leetcode.com/problems/valid-number/) | LeetCode | 🔴 | DFA de números | ¿Cuántos estados necesita el autómata, y cuáles son finales? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Detect the Email Addresses](https://www.hackerrank.com/challenges/detect-the-email-addresses/problem) | HackerRank | 🟡 | Expresión sin vuelta atrás peligrosa | ¿Qué parte de la dirección puede contener puntos, y cuál no? |
| [ ] | [Find a Word](https://www.hackerrank.com/challenges/find-a-word/problem) | HackerRank | 🟡 | Límites de palabra | ¿Qué separa una palabra de lo que la rodea? |
| [ ] | [Tag Validator](https://leetcode.com/problems/tag-validator/) | LeetCode | 🔴 | Analizador con pila | ¿Qué parte es regular y qué parte necesita una pila? |

---

## ✅ Criterio de dominio

- Escribir un DFA como tabla y la DP que cuenta sus cadenas aceptadas.
- Construir el NFA de Thompson con la plantilla delante y simularlo con conjuntos.
- Explicar la construcción de subconjuntos, su explosión y la versión perezosa.
- Explicar ReDoS con un ejemplo y las defensas.
- Resolver Valid Number y `grep` mínimo sin pista 2.

---

**Anterior:** [`16/06` — *Suffix array*, LCP y *suffix automaton*](06-suffix-array-y-automaton.md) ·
**Siguiente:** [`16/08` — Árbol de palíndromos y árbol de sufijos](08-eertree-y-ukkonen.md) ·
**Relacionado:** [`22/01` — Lenguajes y gramáticas](../22-teoria-de-la-computacion/01-lenguajes-y-gramaticas.md).
