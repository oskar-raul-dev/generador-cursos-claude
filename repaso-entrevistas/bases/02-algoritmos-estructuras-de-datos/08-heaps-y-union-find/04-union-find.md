# 04 — Union-Find

> La estructura de conjuntos disjuntos: `find` y `union` con compresión de caminos y unión por tamaño o
> rango, en `O(α(n))` amortizado; la versión con pesos, que mantiene diferencias o paridades entre
> elementos del mismo grupo; y la versión con *rollback*, sin compresión, que permite deshacer uniones y
> procesar conexiones *offline*.
>
> **Niveles:** Union-Find [A] · con pesos o paridad [B] · con *rollback* y *offline* [B].
>
> **📚 Lectura troncal:** Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed.
> (MIT Press, 2009), cap. 21; Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §1.5;
> Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--union-find) · [4](#4--con-pesos-o-paridad) · [5](#5--con-rollback-y-offline) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Una red social recibe `10⁵` amistades nuevas y, tras cada una, quiere saber cuántos grupos de amigos
(conectados directa o indirectamente) hay. Recalcular las componentes con un recorrido tras cada amistad
cuesta `O(n + m)` cada vez: `10¹⁰` en total. Guardar una etiqueta de grupo por persona y reetiquetar al
unir cuesta `O(n)` por unión en el peor caso.

**Union-Find** (o *disjoint set union*, DSU) mantiene una partición de `n` elementos con dos operaciones:
`find(x)`, que dice a qué grupo pertenece `x` (devolviendo un representante), y `union(a, b)`, que une los
grupos de `a` y `b`. Con dos mejoras —comprimir caminos y unir el pequeño bajo el grande— cada operación
cuesta `O(α(n))` amortizado, donde `α` es la inversa de la función de Ackermann: menor que 5 para cualquier
`n` que quepa en el universo.

Es la estructura de Kruskal ([`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)), de la detección de ciclos en grafos no dirigidos, y de cualquier
problema que **solo une** grupos. Este capítulo es su dueño, con dos variantes que aparecen mucho: la que
guarda una relación numérica dentro de cada grupo y la que permite deshacer.

---

## 2. 📐 La teoría

**La representación.** Un bosque: cada elemento apunta a su padre, y la raíz de cada árbol es el
representante del grupo. `find` sube hasta la raíz; `union` cuelga una raíz de la otra.

**Las dos mejoras.**

- **Compresión de caminos**: tras `find(x)`, todos los nodos del camino apuntan directamente a la raíz (o,
  en la variante *halving*, cada uno a su abuelo).
- **Unión por tamaño (o por rango)**: se cuelga la raíz del árbol más pequeño de la del más grande.

**Teorema (unión por tamaño).** Con unión por tamaño, y sin compresión, todo árbol de altura `h` tiene al
menos `2ʰ` nodos; así que la altura es `≤ log₂ n` y `find` cuesta `O(log n)`.

*Prueba.* Por inducción sobre las uniones. La altura de un nodo `x` solo aumenta cuando su raíz se cuelga
de otra, y entonces el árbol que contiene a `x` pasa a tener al menos el doble de nodos (se cuelga el menor
del mayor). Cada aumento de profundidad duplica el tamaño del árbol de `x`, y el tamaño no pasa de `n`.

**Teorema (las dos juntas, enunciado).** Con compresión de caminos y unión por tamaño o rango, una
secuencia de `m` operaciones sobre `n` elementos cuesta `O(m · α(n))`. La prueba (Tarjan, 1975) es larga;
CLRS, 3.ª ed., §21.4. Con **solo** compresión, el coste amortizado es `O(log n)` por operación, no `α(n)`.

**`α(n)`** crece tan despacio que `α(n) ≤ 4` para `n` menor que un número con más dígitos que átomos hay en
el universo observable: en la práctica, constante.

**Con pesos.** Cada elemento guarda `d[x]`, una magnitud relativa a su padre (una diferencia, una paridad,
un cociente). Al comprimir, se acumulan las de todo el camino, y `d[x]` pasa a ser relativa a la raíz. Así
se responden preguntas como «¿cuánto vale `x_b − x_a`?» si `a` y `b` están en el mismo grupo.

**Con *rollback*.** Sin compresión, cada `union` cambia **un** puntero (y un tamaño); guardando esos cambios
en una pila, se pueden deshacer en orden inverso. Es la pieza del procesamiento *offline* de conexiones que
aparecen y desaparecen ([`07/07`](../07-arboles/07-arboles-dinamicos.md)).

---

## 3. 🧱 Union-Find

**Qué es.** Arreglos `parent` y `size`; `find` con compresión y `union` por tamaño.

**Por qué es correcto.** Invariante: dos elementos están en el mismo grupo si y solo si sus raíces
coinciden. `union` cuelga una raíz de otra, lo que une exactamente los dos grupos; la compresión solo
cambia a qué nodo del **mismo** árbol apunta cada uno, así que no cambia ninguna raíz.

**Cómo va**, con 6 elementos y las uniones `(1,2) (3,4) (2,4) (5,6) (1,3)`:

```text
union(1,2)   parent: 1→1 2→1                     grupos {1,2} {3} {4} {5} {6}
union(3,4)   parent: 3→3 4→3                     {1,2} {3,4} {5} {6}
union(2,4)   raíces 1 y 3, mismo tamaño: 3→1     {1,2,3,4} {5} {6}
union(5,6)   6→5                                 {1,2,3,4} {5,6}
union(1,3)   find(1) = find(3) = 1: ya estaban juntos → esta arista cerraría un ciclo
quedan 2 grupos
```

**Cuánto.** `O(α(n))` amortizado por operación; memoria `Θ(n)`.

**La plantilla:**

```cpp
#include <numeric>
#include <utility>
#include <vector>

// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
struct DSU {
    std::vector<int> parent, size;
    explicit DSU(int n) : parent(n), size(n, 1) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }   // iterativo
        return x;
    }
    bool unite(int a, int b) {                       // false si ya estaban juntos
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) std::swap(a, b);
        parent[b] = a; size[a] += size[b];
        return true;
    }
    bool same(int a, int b) { return find(a) == find(b); }
};
```

```java
// Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado.
static final class DSU {
    final int[] parent, size;
    DSU(int n) { parent = new int[n]; size = new int[n]; for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; } }
    int find(int x) {
        while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
        return x;
    }
    boolean unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) { int t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b];
        return true;
    }
}
```

```python
class DSU:
    """Union-Find con compresión (halving) y unión por tamaño. O(α(n)) amortizado."""
    def __init__(self, n):
        self.parent, self.size = list(range(n)), [1] * n

    def find(self, x):
        p = self.parent
        while p[x] != x:
            p[x] = p[p[x]]
            x = p[x]
        return x

    def unite(self, a, b):
        a, b = self.find(a), self.find(b)
        if a == b:
            return False
        if self.size[a] < self.size[b]:
            a, b = b, a
        self.parent[b] = a
        self.size[a] += self.size[b]
        return True
```

- **`find` iterativo con *halving*** (cada nodo pasa a apuntar a su abuelo): misma garantía que la
  compresión completa y sin recursión, que con caminos largos desbordaría.
- **`unite` devuelve si unió**: `false` significa que la arista cierra un ciclo (Kruskal la descarta).
- **`size[raíz]`** es el tamaño del grupo; los tamaños de nodos que no son raíz no significan nada.
- **El número de grupos** se lleva con un contador que baja en cada `unite` que devuelve `true`.

### De la versión ingenua a la buena

**El problema.** `n = 10⁵` personas; llegan `10⁵` amistades y, tras cada una, hay que decir cuántos grupos
quedan.

**La versión ingenua:**

```java
// O(n) por unión: reetiqueta a todo el grupo absorbido recorriendo a todos. 10¹⁰ en total.
static int addFriendship(int[] label, int a, int b, int groups) {
    int la = label[a], lb = label[b];
    if (la == lb) return groups;
    for (int i = 0; i < label.length; i++) if (label[i] == lb) label[i] = la;
    return groups - 1;
}
```

> «No necesito que todos lleven la etiqueta de su grupo al día: me basta poder llegar al representante.
> Si cada uno apunta a alguien de su grupo y uno solo apunta a sí mismo, unir es cambiar un puntero; y
> colgando el pequeño del grande y aplanando al buscar, cada operación es prácticamente constante.»

**El camino a la buena.** `DSU` y un contador de grupos que baja en cada unión efectiva.

**Cuándo sí**: componentes con aristas que solo se añaden; ciclos en grafos no dirigidos; Kruskal;
equivalencias. **Cuándo no**: si hay que separar grupos (borrar aristas) *online* (`07/07`); si hay que
listar los miembros de un grupo a menudo, guardar además una lista por raíz.

> **Veredicto:** Union-Find une y pregunta «¿mismo grupo?» en tiempo prácticamente constante, con dos
> mejoras que hay que poner las dos: compresión y unión por tamaño.

---

## 4. 🧱 Con pesos o paridad

**Qué es.** Un Union-Find en el que cada nodo guarda `d[x]`, su valor relativo al padre; tras `find`, es
relativo a la raíz. Responde «¿cuánto vale `x_b − x_a`?» y detecta contradicciones.

**Por qué es correcto** (el enunciado y una frase): si `d[x] = x − raíz` para todo nodo comprimido, la
diferencia `x_b − x_a` entre dos nodos del mismo grupo es `d[b] − d[a]`; al unir con la relación
`x_b − x_a = w`, el desplazamiento de una raíz respecto de la otra queda determinado por `w`, `d[a]` y `d[b]`.

**Cómo va**, con las relaciones «`x₂ − x₁ = 3`», «`x₃ − x₂ = 2`» y dos consultas:

```text
unir (1, 2, 3):  2 cuelga de 1 con d[2] = 3
unir (2, 3, 2):  3 cuelga de 1 con d[3] = d[2] + 2 = 5
¿x₃ − x₁ = 5?   d[3] − d[1] = 5 − 0 = 5: coherente
¿x₃ − x₁ = 4?   5 ≠ 4: contradicción
```

**Cuánto.** Lo mismo que Union-Find: `O(α(n))` amortizado.

**La plantilla**, con diferencias (para paridad, se sustituye la suma por el *xor*):

```cpp
#include <numeric>
#include <vector>

// Union-Find con pesos: d[x] = valor(x) − valor(padre(x)); tras find, relativo a la raíz.
struct WeightedDSU {
    std::vector<int> parent; std::vector<long long> d;
    explicit WeightedDSU(int n) : parent(n), d(n, 0) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) {
        if (parent[x] == x) return x;
        int r = find(parent[x]);                     // recursivo: sin unión por tamaño, hasta n de hondo
        d[x] += d[parent[x]];
        parent[x] = r;
        return r;
    }
    bool unite(int a, int b, long long w) {          // impone valor(b) − valor(a) = w; false si contradice
        int ra = find(a), rb = find(b);
        if (ra == rb) return d[b] - d[a] == w;
        parent[rb] = ra;
        d[rb] = d[a] + w - d[b];
        return true;
    }
    long long diff(int a, int b) { find(a); find(b); return d[b] - d[a]; }   // pre: mismo grupo
};
```

```java
// Union-Find con pesos: d[x] = valor(x) − valor(padre(x)); tras find, relativo a la raíz.
static final class WeightedDSU {
    final int[] parent; final long[] d;
    WeightedDSU(int n) { parent = new int[n]; d = new long[n]; for (int i = 0; i < n; i++) parent[i] = i; }
    int find(int x) {
        if (parent[x] == x) return x;
        int r = find(parent[x]);
        d[x] += d[parent[x]];
        parent[x] = r;
        return r;
    }
    boolean unite(int a, int b, long w) {
        int ra = find(a), rb = find(b);
        if (ra == rb) return d[b] - d[a] == w;
        parent[rb] = ra;
        d[rb] = d[a] + w - d[b];
        return true;
    }
}
```

- **El orden importa en `find`**: primero se comprime el padre (que deja `d[padre]` relativo a la raíz) y
  después se suma.
- **Recursión**: esta versión no une por tamaño para no complicar el desplazamiento; con caminos de
  longitud `n` puede desbordar. Se añade la unión por tamaño (cambiando de lado `w` y signos al
  intercambiar) o se escribe `find` iterativo en dos pasadas.
- **Paridad** («`a` y `b` están en equipos distintos»): `d` en `{0, 1}` con *xor* en lugar de suma; un
  conflicto es un ciclo impar.

**Cuándo sí**: sistemas de diferencias o cocientes («`a` es `k` veces `b`»), bipartición con uniones
incrementales, detectar el primer dato contradictorio. **Cuándo no**: si las relaciones no son de grupo
(no se pueden componer e invertir), no hay desplazamiento que guardar.

> **Veredicto:** con un peso relativo a la raíz, Union-Find guarda no solo «mismo grupo», sino «cuánto
> difieren», y detecta la primera contradicción.

---

## 5. 🧱 Con *rollback* y *offline*

**Qué es.** Union-Find **sin compresión**, con unión por tamaño, que guarda en una pila cada cambio que
hace `unite` para poder deshacer las últimas uniones.

**Por qué es correcto** (el enunciado y una frase): sin compresión, `find` no modifica nada y cada `unite`
cambia exactamente un `parent` y un `size`; deshacer en orden inverso restaura el estado exacto anterior.

**Cómo va.** Tras `unite(1,2)` y `unite(2,4)` la pila guarda `[(2 → 1), (3 → 1)]`; `rollback(1)` deshace la
última: el 3 vuelve a ser raíz y el tamaño de 1 baja en lo que se le sumó.

**Cuánto.** `find` `O(log n)` (por la unión por tamaño); `unite` y deshacer, `O(log n)` y `O(1)`.

**La plantilla:**

```cpp
#include <numeric>
#include <utility>
#include <vector>

// Union-Find con rollback: sin compresión, unión por tamaño. find O(log n).
struct RollbackDSU {
    std::vector<int> parent, size; std::vector<std::pair<int, int>> history;   // (b colgado, a raíz)
    int components;
    explicit RollbackDSU(int n) : parent(n), size(n, 1), components(n) { std::iota(parent.begin(), parent.end(), 0); }
    int find(int x) const { while (parent[x] != x) x = parent[x]; return x; }
    bool unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) std::swap(a, b);
        parent[b] = a; size[a] += size[b]; components--;
        history.push_back({b, a});
        return true;
    }
    int snapshot() const { return history.size(); }
    void rollback(int snap) {                        // deshace hasta dejar snap uniones
        while ((int)history.size() > snap) {
            auto [b, a] = history.back(); history.pop_back();
            parent[b] = b; size[a] -= size[b]; components++;
        }
    }
};
```

```java
// Union-Find con rollback: sin compresión, unión por tamaño. find O(log n).
static final class RollbackDSU {
    final int[] parent, size, histB, histA; int top = 0, components;
    RollbackDSU(int n) {
        parent = new int[n]; size = new int[n]; histB = new int[n]; histA = new int[n]; components = n;
        for (int i = 0; i < n; i++) { parent[i] = i; size[i] = 1; }
    }
    int find(int x) { while (parent[x] != x) x = parent[x]; return x; }
    boolean unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) return false;
        if (size[a] < size[b]) { int t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b]; components--;
        histB[top] = b; histA[top++] = a;
        return true;
    }
    int snapshot() { return top; }
    void rollback(int snap) {
        while (top > snap) { top--; int b = histB[top], a = histA[top]; parent[b] = b; size[a] -= size[b]; components++; }
    }
}
```

- **Sin compresión**: comprimir cambiaría punteros que la pila no registra, y deshacer dejaría el bosque
  inconsistente.
- **`snapshot` y `rollback`** se usan en pila: se toma la instantánea al entrar en un subproblema y se
  deshace al salir.
- **El uso típico** es el *segment tree* sobre el tiempo (`07/07`): cada arista se une en los nodos del
  árbol que cubren su intervalo de vida, y un DFS une al entrar y deshace al salir.

**Cuándo sí**: conectividad con aristas que aparecen y desaparecen, *offline*; divide y vencerás sobre
consultas que necesitan «probar» uniones y volver atrás. **Cuándo no**: si nunca hay que deshacer, la
versión con compresión es más rápida.

> **Veredicto:** quitando la compresión, Union-Find puede deshacer sus últimas uniones en `O(1)` cada una.
> Con eso, los borrados *offline* se vuelven uniones que se deshacen.

---

## 6. ⏱️ La tabla de costes

| Variante | `find` | `unite` | Lo que la tabla no dice |
|---|---|---|---|
| Sin mejoras | `O(n)` | `O(n)` | Una cadena de uniones lo degrada |
| Solo unión por tamaño | `O(log n)` | `O(log n)` | Altura acotada por `log₂ n` |
| Solo compresión | `O(log n)` amortizado | `O(log n)` amortizado | Mejor, pero no `α(n)` |
| Compresión + unión por tamaño | `O(α(n))` amortizado | `O(α(n))` amortizado | `α(n) ≤ 4` en la práctica |
| Con pesos | `O(α(n))` | `O(α(n))` | Acumular `d` al comprimir |
| Con *rollback* | `O(log n)` | `O(log n)`; deshacer `O(1)` | Sin compresión |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Une», «conecta», «¿están en el mismo grupo?», solo se añade | Union-Find | `O(α(n))` por operación |
| «La primera arista que cierra un ciclo» | Union-Find: `unite` devuelve `false` | Ya estaban conectados |
| «`a` pesa `w` más que `b`», «¿hay contradicción?» | Con pesos | Diferencias relativas a la raíz |
| «En equipos distintos», «bipartito» con llegadas | Con paridad | Ciclo impar = conflicto |
| Aristas que aparecen y desaparecen, todas conocidas | Con *rollback* + segment tree sobre el tiempo | Deshacer al volver |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «Union-Find es `O(1)`» | Es `O(α(n))` **amortizado**, prácticamente constante; una operación concreta puede costar más |
| «Con compresión basta, la unión da igual» | Solo compresión da `O(log n)` amortizado; hacen falta las dos para `α(n)` |
| «`size[x]` es el tamaño del grupo de `x`» | Solo si `x` es raíz: hay que leer `size[find(x)]` |
| «Union-Find sirve para separar grupos» | Solo une; los borrados necesitan *offline* o árboles dinámicos (`07/07`) |
| «Con *rollback* se puede comprimir» | No: la compresión cambia punteros que no se registran |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 3.ª ed. (MIT Press, 2009),
  cap. 21: conjuntos disjuntos y el análisis con `α(n)`. *Lectura troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §1.5, con las versiones
  *quick-find*, *quick-union* y ponderada en [*Union-Find*](https://algs4.cs.princeton.edu/15uf/). *Lectura
  troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5. *Lectura
  troncal.*
- **Referencia** — cp-algorithms, [*Disjoint Set Union*](https://cp-algorithms.com/data_structures/disjoint_set_union.html):
  con pesos, paridad y aplicaciones *offline*.
- **Visualización interactiva** — VisuAlgo, [*Union-Find Disjoint Sets*](https://visualgo.net/en/ufds).

---

## 🧠 Preguntas

1. ¿Qué hacen `find` y `union`, y qué representa la raíz de cada árbol? 🟢
2. ¿Qué es la compresión de caminos y qué es la unión por tamaño? 🟢
3. ¿Cómo detectas con Union-Find si una arista cierra un ciclo en un grafo no dirigido? 🟢
4. ¿Por qué `size[x]` solo es fiable si `x` es raíz? 🟡
5. ¿Por qué la unión por tamaño sola garantiza altura `≤ log₂ n`? 🟡
6. ¿Cuánto cuesta Union-Find con solo compresión, y con las dos mejoras? 🟡
7. ¿Por qué en el Union-Find con pesos hay que comprimir el padre antes de sumar su `d`? 🟡
8. Demuestra que con unión por tamaño todo árbol de altura `h` tiene al menos `2ʰ` nodos. 🟠
9. ¿Cómo detectas con paridad que un grafo deja de ser bipartito al añadir una arista? 🟠
10. Compara cómo escribirías Union-Find en C++, Java y Python, y por qué `find` iterativo. 🟠
11. ¿Por qué el Union-Find con *rollback* no puede usar compresión de caminos? 🟠
12. ¿Qué es `α(n)` y por qué se considera constante en la práctica? 🔴
13. ¿Cómo combinas Union-Find con *rollback* y un *segment tree* sobre el tiempo para la conectividad con borrados *offline*, y con qué coste? 🔴

---

## 🧩 Problemas propios

### El cable que sobra

**Nivel:** 🟡 · **Formato:** programa completo.

Se tienden cables entre `n` nodos en el orden dado. Imprime el número (1-indexado) del primer cable que une
dos nodos ya conectados, o `0` si ninguno lo hace.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con los cables.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n, m ≤ 2·10⁵`.

```text
Entrada            Salida
6 5                5
1 2
3 4
2 4
5 6
1 3

Entrada            Salida
3 2                0
1 2
2 3
```

**Pista 1:** al llegar un cable, ¿qué tienes que saber de sus dos extremos?

### Balanzas

**Nivel:** 🟠 · **Formato:** programa completo.

Llegan afirmaciones «el objeto `b` pesa `w` gramos más que el `a`» (con `w` posiblemente negativo). Imprime
el número (1-indexado) de la primera que contradice a las anteriores, o `0` si todas son coherentes.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con `a b w`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n, m ≤ 2·10⁵`; `|w| ≤ 10⁹`.

```text
Entrada            Salida
3 3                3
1 2 3
2 3 2
1 3 4

Entrada            Salida
2 2                0
1 2 -1000000000
2 1 1000000000
```

**Pista 1:** si sabes cuánto pesa cada objeto respecto de un objeto de referencia de su grupo, ¿qué tienes
que comprobar cuando `a` y `b` ya están en el mismo grupo?

### Equipos rivales

**Nivel:** 🟡 · **Formato:** programa completo.

Llegan pares de personas que deben estar en equipos distintos (hay dos equipos). Imprime el número
(1-indexado) del primer par que hace imposible el reparto, o `0`.

- **Entrada.** Una línea con `n` y `m`. Después, `m` líneas con `a b`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n, m ≤ 2·10⁵`; `a ≠ b`.

```text
Entrada            Salida
3 3                3
1 2
2 3
1 3

Entrada            Salida
2 2                0
1 2
2 1
```

**Pista 1:** ¿qué tipo de ciclo hace imposible repartir en dos equipos?

---

## 🧩 Práctica externa

> 💡 **Truco.** Si tu Union-Find da TLE, comprueba que haces las dos mejoras y que `find` no es recursivo en
> Java o Python. Pide a una IA que revise solo eso, no la lógica del problema ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Number of Provinces](https://leetcode.com/problems/number-of-provinces/) | LeetCode | 🟡 | Contar grupos | ¿Cuántas uniones efectivas hay, y cuántos grupos quedan? |
| [ ] | [Redundant Connection](https://leetcode.com/problems/redundant-connection/) | LeetCode | 🟡 | Arista que cierra un ciclo | ¿Qué te dice `unite` cuando los dos ya estaban juntos? |
| [ ] | [Satisfiability of Equality Equations](https://leetcode.com/problems/satisfiability-of-equality-equations/) | LeetCode | 🟡 | Igualdades primero, desigualdades después | ¿En qué orden conviene procesar `==` y `!=`? |
| [ ] | [Number of Operations to Make Network Connected](https://leetcode.com/problems/number-of-operations-to-make-network-connected/) | LeetCode | 🟡 | Grupos y cables sobrantes | ¿Cuántos cables necesitas para unir `c` grupos, y cuántos te sobran? |
| [ ] | [Accounts Merge](https://leetcode.com/problems/accounts-merge/) | LeetCode | 🟡 | Union-Find sobre correos | ¿Qué elementos unes: cuentas o correos? |
| [ ] | [Components in a graph](https://www.hackerrank.com/challenges/components-in-graph/problem) | HackerRank | 🟡 | Tamaños de grupo | ¿Qué grupos cuentan para el mínimo, según el enunciado? |
| [ ] | [Merging Communities](https://www.hackerrank.com/challenges/merging-communities/problem) | HackerRank | 🟠 | Unión con tamaño | ¿Dónde guardas el tamaño de cada comunidad? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Evaluate Division](https://leetcode.com/problems/evaluate-division/) | LeetCode | 🟡 | Union-Find con cocientes | Si guardas cada variable respecto de su raíz, ¿cómo sale `a / b`? |
| [ ] | [Possible Bipartition](https://leetcode.com/problems/possible-bipartition/) | LeetCode | 🟡 | Paridad | ¿Con quién tiene que estar el enemigo de mi enemigo? |
| [ ] | [Most Stones Removed with Same Row or Column](https://leetcode.com/problems/most-stones-removed-with-same-row-or-column/) | LeetCode | 🟡 | Unir filas y columnas | En cada grupo conectado, ¿cuántas piedras pueden quedar como mínimo? |
| [ ] | [Similar String Groups](https://leetcode.com/problems/similar-string-groups/) | LeetCode | 🔴 | Unir pares similares | ¿Cuántos pares tienes que comparar y cuánto cuesta cada comparación? |
| [ ] | [Redundant Connection II](https://leetcode.com/problems/redundant-connection-ii/) | LeetCode | 🔴 | Dirigido: dos padres o ciclo | ¿Qué dos situaciones pueden hacer que no sea un árbol enraizado? |

---

## ✅ Criterio de dominio

- Escribir Union-Find con las dos mejoras, la versión con pesos y la de *rollback* sin mirar.
- Demostrar la cota de altura de la unión por tamaño y explicar qué aporta la compresión.
- Detectar ciclos, contradicciones y ciclos impares con la variante adecuada.
- Resolver Accounts Merge y Evaluate Division sin pista 2.

---

**Anterior:** [`08/03` — Montículos fusionables](03-monticulos-fusionables.md) · **Siguiente:**
[`08/05` — Simulación](05-simulacion.md) · **Relacionado:** [`15/04` — Árbol de expansión mínima](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md); [`14/03` — DFS](../14-grafos-recorridos/03-dfs.md);
[`02/03` — Análisis amortizado](../02-analisis/03-analisis-amortizado.md).
