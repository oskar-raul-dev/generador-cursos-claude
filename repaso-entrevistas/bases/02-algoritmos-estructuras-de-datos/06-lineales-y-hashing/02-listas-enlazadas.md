# 02 — Listas enlazadas

> Manipular listas enlazadas sin perder punteros: invertir, encontrar el punto medio, mezclar, detectar
> un ciclo con dos punteros (Floyd) y encontrar dónde empieza; la caché LRU con una lista doble y un
> mapa; y cuándo no usar una lista enlazada.
>
> **Niveles:** inversión, mezcla y punteros lento y rápido (Floyd) [A] · LRU con lista y *hash* [A] ·
> listas múltiples [C].
>
> **📚 Lectura troncal:** Goodrich, Tamassia y Goldwasser, *Data Structures and Algorithms in Java*, 6.ª
> ed. (Wiley, 2014), cap. 3; Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997),
> cap. 5.
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--inversión-punto-medio-y-mezcla) · [4](#4--floyd-detectar-el-ciclo-y-su-inicio) · [5](#5--la-caché-lru) · [6](#6--listas-múltiples) · [7](#7-️-la-tabla-de-costes) · [8](#8--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

En competición casi nunca se elige una lista enlazada: un arreglo es más rápido en casi todo (`02/05`).
Pero en entrevista aparecen constantemente, por dos razones. La primera, que **manipular punteros sin
perder ninguno** es una prueba directa de cuidado: invertir una lista, cortarla por la mitad o mezclar
dos son diez líneas en las que un orden equivocado de asignaciones pierde media lista. La segunda, que
dos diseños clásicos se apoyan en ellas: la **caché LRU**, que necesita mover un elemento al frente en
`O(1)`, y la **detección de ciclos** con dos punteros, que vale también para secuencias que no son
listas.

Este capítulo da las plantillas de manipulación, con el **nodo centinela** que elimina los casos
especiales; demuestra por qué el algoritmo de Floyd encuentra el inicio del ciclo; y construye la LRU en
los tres lenguajes.

---

## 2. 📐 La teoría

**El modelo de coste.** Insertar o borrar **junto a un nodo que ya tienes** es `O(1)`: se cambian dos o
cuatro punteros. **Llegar** a una posición es `O(n)`, y cada paso es un acceso a memoria disperso que
puede fallar en la caché. Por eso «la lista inserta en `O(1)`» es cierto solo a medias: el coste está en
encontrar el sitio.

**El nodo centinela.** Un nodo ficticio delante de la cabeza (`dummy`) hace que **todo nodo real tenga un
anterior**. Borrar la cabeza, insertar delante o construir una lista nueva dejan de ser casos
especiales: se trabaja siempre con `prev.next`, y al final se devuelve `dummy.next`.

**Teorema (Floyd).** Sea una secuencia `x₀, x₁ = f(x₀), x₂ = f(x₁), …` sobre un conjunto finito, con una
cola de longitud `μ` antes de un ciclo de longitud `λ`. Un puntero lento (un paso) y uno rápido (dos
pasos) que salen de `x₀` se encuentran dentro del ciclo; y si después uno vuelve a `x₀` y los dos avanzan
de uno en uno, se encuentran exactamente en el inicio del ciclo, `x_μ`.

*Prueba.* Tras `t` pasos, el lento está en `x_t` y el rápido en `x_{2t}`. Para `t ≥ μ`, los dos están en el
ciclo y coinciden si y solo si `2t − t = t` es múltiplo de `λ`. El primer múltiplo de `λ` mayor o igual
que `μ` existe y es como mucho `μ + λ`: se encuentran en algún `t = kλ ≥ μ`. Desde ahí, el lento está a
`t − μ` pasos del inicio del ciclo dentro de él. Si avanza `μ` pasos más, estará a `t` pasos, que es
múltiplo de `λ`: está en el inicio. Un puntero que sale de `x₀` y avanza `μ` pasos llega al inicio a la
vez. Los dos se encuentran por primera vez justo ahí. Knuth, Vol. 2, §3.1, ejercicio 6.

**La LRU.** Una caché de capacidad `C` que, al llenarse, expulsa el elemento **usado hace más tiempo**.
Necesita tres operaciones en `O(1)`: encontrar una clave (un mapa *hash*, [`06/03`](03-tablas-hash.md)), marcarla como recién
usada (moverla al frente de un orden) y expulsar la menos reciente (quitar del final de ese orden). Una
**lista doblemente enlazada** da las dos últimas si el mapa guarda, para cada clave, su nodo.

---

## 3. 🧱 Inversión, punto medio y mezcla

**Qué es.** Las tres manipulaciones básicas: invertir los enlaces; encontrar el nodo central con un
puntero que avanza el doble; mezclar dos listas ordenadas reenlazando nodos.

**Por qué es correcto.** Invertir mantiene el invariante «`prev` es la cabeza de la parte ya invertida
y `cur` la de la parte por invertir»; cada vuelta mueve un nodo de una a otra. En el punto medio, cuando
el rápido llega al final ha dado el doble de pasos que el lento, que está en la mitad. La mezcla es la de
[`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md) sobre nodos.

**Cómo va**, la inversión de `5 → 2 → 9`:

```text
prev    cur    (lista ya invertida)    (lista por invertir)
null    5      ∅                       5 → 2 → 9
5       2      5                       2 → 9
2       9      2 → 5                   9
9       null   9 → 2 → 5               ∅
```

**Cuánto.** `Θ(n)` las tres; `Θ(1)` de memoria extra.

**La plantilla:**

```cpp
struct ListNode {
    int val;
    ListNode* next;
    explicit ListNode(int v, ListNode* n = nullptr) : val(v), next(n) {}
};

ListNode* reverse(ListNode* head) {
    ListNode* prev = nullptr;
    while (head) {
        ListNode* nxt = head->next;     // guarda el resto ANTES de cambiar el enlace
        head->next = prev;
        prev = head;
        head = nxt;
    }
    return prev;
}

// Con n par, devuelve el primero de la segunda mitad.
ListNode* middle(ListNode* head) {
    ListNode *slow = head, *fast = head;
    while (fast && fast->next) { slow = slow->next; fast = fast->next->next; }
    return slow;
}

ListNode* merge(ListNode* a, ListNode* b) {
    ListNode dummy(0);                  // centinela en la pila: nada que liberar
    ListNode* tail = &dummy;
    while (a && b) {
        ListNode*& pick = (b->val < a->val) ? b : a;   // empate: a, estable
        tail->next = pick; tail = pick; pick = pick->next;
    }
    tail->next = a ? a : b;
    return dummy.next;
}
```

```java
static final class ListNode {
    int val; ListNode next;
    ListNode(int val, ListNode next) { this.val = val; this.next = next; }
}

static ListNode reverse(ListNode head) {
    ListNode prev = null;
    while (head != null) {
        ListNode nxt = head.next;
        head.next = prev;
        prev = head;
        head = nxt;
    }
    return prev;
}

static ListNode middle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) { slow = slow.next; fast = fast.next.next; }
    return slow;
}

static ListNode merge(ListNode a, ListNode b) {
    ListNode dummy = new ListNode(0, null), tail = dummy;
    while (a != null && b != null) {
        if (b.val < a.val) { tail.next = b; b = b.next; } else { tail.next = a; a = a.next; }
        tail = tail.next;
    }
    tail.next = (a != null) ? a : b;
    return dummy.next;
}
```

```python
class ListNode:
    __slots__ = ("val", "next")
    def __init__(self, val, next=None):
        self.val, self.next = val, next

def reverse(head):
    prev = None
    while head:
        head.next, prev, head = prev, head, head.next   # la tupla se evalúa entera antes de asignar
    return prev

def middle(head):
    slow = fast = head
    while fast and fast.next:
        slow, fast = slow.next, fast.next.next
    return slow

def merge(a, b):
    dummy = tail = ListNode(0)
    while a and b:
        if b.val < a.val:
            tail.next, b = b, b.next
        else:
            tail.next, a = a, a.next
        tail = tail.next
    tail.next = a or b
    return dummy.next
```

- **Guardar `next` antes de reescribirlo**: es el error que pierde media lista.
- **El punto medio con `n` par** devuelve el primero de la segunda mitad; para el último de la primera
  (y cortar ahí), arranca `fast` en `head.next`.
- **El centinela** de `merge` evita el caso «¿quién es la cabeza del resultado?».
- **Python**: la asignación múltiple evalúa la derecha completa antes de asignar, y el orden de la
  izquierda importa: `head.next` debe asignarse antes que `head`. `__slots__` reduce la memoria por nodo.
- **C++**: con `new` y sin liberar, en competición no importa; en entrevista, menciónalo o usa nodos en un
  `std::vector`.

> **Veredicto:** las manipulaciones de listas son cortas y frágiles: guarda el siguiente antes de
> cambiar un enlace, y usa un centinela para no tener casos especiales.

---

## 4. 🧱 Floyd: detectar el ciclo y su inicio

**Qué es.** Dos punteros sobre la secuencia `x, f(x), f(f(x)), …`: el lento avanza uno y el rápido dos.
Si hay ciclo, se encuentran; entonces uno vuelve al principio y los dos avanzan de uno en uno hasta
encontrarse en el inicio del ciclo.

**Por qué es correcto.** Por el teorema de §2.

**Cómo va**, la lista de seis nodos (índices 0 a 5, valores `5, 2, 9, 1, 5, 6`) cuyo último apunta al
nodo 2: cola `μ = 2`, ciclo `λ = 4`.

```text
paso    lento    rápido
1       1        2
2       2        4
3       3        2         (4 → 5 → 2)
4       4        4         se encuentran en el nodo 4
fase 2: uno vuelve al 0
        1        5
        2        2         se encuentran en el nodo 2: inicio del ciclo (valor 9)
```

**Cuánto.** `O(μ + λ)` pasos y `O(1)` de memoria. La longitud del ciclo sale dando una vuelta más desde el
inicio.

**La plantilla:**

```cpp
// Inicio del ciclo, o nullptr si la lista termina. O(n) tiempo, O(1) memoria.
ListNode* cycleStart(ListNode* head) {
    ListNode *slow = head, *fast = head;
    while (fast && fast->next) {
        slow = slow->next; fast = fast->next->next;
        if (slow == fast) {                       // dentro del ciclo
            ListNode* p = head;
            while (p != slow) { p = p->next; slow = slow->next; }
            return p;
        }
    }
    return nullptr;
}
```

```java
// Inicio del ciclo, o null si la lista termina. O(n) tiempo, O(1) memoria.
static ListNode cycleStart(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next; fast = fast.next.next;
        if (slow == fast) {
            ListNode p = head;
            while (p != slow) { p = p.next; slow = slow.next; }
            return p;
        }
    }
    return null;
}
```

```python
def cycle_start(head):
    """Inicio del ciclo, o None si la lista termina. O(n) tiempo, O(1) memoria."""
    slow = fast = head
    while fast and fast.next:
        slow, fast = slow.next, fast.next.next
        if slow is fast:
            p = head
            while p is not slow:
                p, slow = p.next, slow.next
            return p
    return None
```

- **`slow == fast` compara identidad** (punteros, referencias, `is`), no valores: dos nodos distintos
  pueden valer lo mismo.
- **Sirve para cualquier función `f`** sobre un conjunto finito, no solo para listas: generadores
  pseudoaleatorios, secuencias `x ↦ f(x)` de un enunciado, arreglos cuyos valores son índices.

### De la versión ingenua a la buena

**El problema.** Un generador produce `x_{i+1} = f(x_i)` sobre un espacio de `10¹²` estados. ¿Cuándo se
repite? Se necesitan `μ` y `λ` sin guardar la secuencia.

**La versión ingenua:**

```java
// O(μ + λ) tiempo, pero O(μ + λ) memoria: con 10⁸ estados antes de repetir, gigabytes de HashMap.
static long[] rhoNaive(java.util.function.LongUnaryOperator f, long x0) {
    java.util.HashMap<Long, Long> seen = new java.util.HashMap<>();
    long x = x0;
    for (long i = 0; ; i++) {
        Long first = seen.putIfAbsent(x, i);
        if (first != null) return new long[]{first, i - first};   // {μ, λ}
        x = f.applyAsLong(x);
    }
}
```

> «Recordar todos los estados cuesta memoria lineal. Con dos punteros a distinta velocidad sé que me he
> metido en el ciclo cuando coinciden; y por la aritmética de las distancias, volviendo uno al inicio,
> el siguiente encuentro está justo en el inicio del ciclo. Memoria constante.»

**El camino a la buena.** La plantilla con `f` en lugar de `.next`, contando los pasos de la fase 2 (que
son `μ`) y una vuelta más desde el inicio del ciclo (que da `λ`).

**Cuándo sí**: ciclos en listas, en secuencias funcionales y en arreglos de índices; memoria `O(1)`.
**Cuándo no**: si la memoria sobra y la secuencia es corta, un conjunto es más simple; si `f` es cara,
Floyd evalúa unas tres veces más que el conjunto (el algoritmo de Brent las reduce).

> **Veredicto:** Floyd detecta el ciclo y encuentra su inicio con dos punteros y memoria constante, para
> cualquier función iterada sobre un conjunto finito.

---

## 5. 🧱 La caché LRU

**Qué es.** Un mapa de capacidad fija que, al llenarse, expulsa la clave usada hace más tiempo; `get` y
`put` en `O(1)`.

**Por qué es correcto.** La lista doble mantiene el invariante «las claves están ordenadas de la más
reciente (delante) a la menos reciente (detrás)»: cada uso mueve su nodo al frente, cada inserción entra
al frente, y la expulsión quita el de detrás. El mapa, de clave a nodo, da el acceso directo.

**Cómo va**, capacidad 2:

```text
put(1, A)   orden [1]
put(2, B)   orden [2, 1]
get(1) → A  orden [1, 2]          el 1 pasa al frente
put(3, C)   orden [3, 1]          llena: expulsa el de detrás, el 2
get(2) → —  (expulsado)
```

**Cuánto.** `O(1)` esperado por operación (lo que cueste el mapa *hash*); `O(C)` de memoria.

**La plantilla**, con lo que da cada biblioteca:

```cpp
#include <list>
#include <unordered_map>
#include <utility>

// LRU de capacidad cap: get y put en O(1) esperado.
class LRUCache {
    int cap;
    std::list<std::pair<int, int>> order;     // delante, el más reciente
    std::unordered_map<int, std::list<std::pair<int, int>>::iterator> pos;
public:
    explicit LRUCache(int capacity) : cap(capacity) {}
    int get(int key) {
        auto it = pos.find(key);
        if (it == pos.end()) return -1;
        order.splice(order.begin(), order, it->second);   // mueve el nodo al frente, O(1)
        return it->second->second;
    }
    void put(int key, int value) {
        if (auto it = pos.find(key); it != pos.end()) {
            it->second->second = value;
            order.splice(order.begin(), order, it->second);
            return;
        }
        if ((int)order.size() == cap) { pos.erase(order.back().first); order.pop_back(); }
        order.emplace_front(key, value);
        pos[key] = order.begin();
    }
};
```

```java
import java.util.LinkedHashMap;
import java.util.Map;

// LRU de capacidad cap con LinkedHashMap en orden de acceso. O(1) esperado.
static final class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int cap;
    LRUCache(int cap) {
        super(16, 0.75f, true);                // true: orden de acceso, no de inserción
        this.cap = cap;
    }
    @Override protected boolean removeEldestEntry(Map.Entry<K, V> eldest) {
        return size() > cap;                   // tras cada put, expulsa el menos reciente
    }
}
```

```python
from collections import OrderedDict

class LRUCache:
    """LRU de capacidad cap. O(1) por operación."""
    def __init__(self, cap):
        self.cap, self.d = cap, OrderedDict()   # el final es el más reciente

    def get(self, key):
        if key not in self.d:
            return -1
        self.d.move_to_end(key)
        return self.d[key]

    def put(self, key, value):
        self.d[key] = value
        self.d.move_to_end(key)
        if len(self.d) > self.cap:
            self.d.popitem(last=False)          # el primero es el menos reciente
```

- **C++ `splice`** mueve un nodo dentro de la misma lista sin invalidar iteradores: por eso el mapa
  puede guardar el iterador para siempre.
- **Java `LinkedHashMap(…, true)`**: con orden de acceso, cada `get` mueve la entrada al final; el
  `removeEldestEntry` se consulta tras cada inserción. En entrevista suelen pedir también la versión a
  mano, con nodos dobles y dos centinelas.
- **Python `OrderedDict`**: `move_to_end` y `popitem(last=False)` son `O(1)`. Para memorizar llamadas a
  una función, `functools.lru_cache` ya lo hace.

### De la versión ingenua a la buena

**El problema.** Una caché de `C = 10⁴` entradas con `10⁶` operaciones `get`/`put`.

**La versión ingenua:**

```java
// O(C) por operación: la lista de claves en orden se recorre para mover o quitar.
static final class NaiveLRU {
    final int cap;
    final java.util.HashMap<Integer, Integer> map = new java.util.HashMap<>();
    final java.util.ArrayList<Integer> order = new java.util.ArrayList<>();   // delante, la menos reciente
    NaiveLRU(int cap) { this.cap = cap; }
    int get(int key) {
        if (!map.containsKey(key)) return -1;
        order.remove(Integer.valueOf(key)); order.add(key);                   // O(C)
        return map.get(key);
    }
    void put(int key, int value) {
        if (map.containsKey(key)) order.remove(Integer.valueOf(key));
        else if (map.size() == cap) map.remove(order.remove(0));              // O(C)
        map.put(key, value); order.add(key);
    }
}
```

> «El mapa encuentra la clave en `O(1)`, pero reordenar un arreglo es lineal. Si el mapa me da el
> **nodo** de una lista doble, moverlo al frente o quitar el último es cambiar cuatro punteros: todo
> `O(1)`.»

**El camino a la buena.** Mapa de clave a nodo y lista doble con dos centinelas (cabeza y cola), o la
biblioteca de la plantilla.

**Cuándo sí**: cachés con expulsión por antigüedad de uso; cualquier «mapa con orden que cambia en cada
acceso». **Cuándo no**: si la política es por frecuencia (LFU), hace falta otra estructura.

> **Veredicto:** la LRU es un mapa a nodos más una lista doble: el mapa encuentra, la lista ordena. En
> Java y Python viene hecha; en entrevista, hay que saber escribirla a mano.

---

## 6. 🧱 Listas múltiples

- **Qué resuelve.** Representar estructuras donde cada elemento pertenece a varias secuencias a la vez:
  una matriz dispersa con cada celda enlazada a la siguiente de su fila y de su columna ([`04/05`](../04-secuencias/05-matrices.md)), una
  lista multinivel con punteros a sublistas, o la lista doble de la LRU.
- **Qué garantiza.** Recorrer cualquiera de las secuencias en tiempo proporcional a su longitud, e
  insertar o borrar un elemento en `O(1)` en todas ellas si ya se tiene el nodo.
- **Cuánto.** Un puntero por secuencia y nodo; la misma localidad de caché pobre que cualquier lista.
- **Cómo reconocerlo.** «Aplanar una lista multinivel»; matrices dispersas con inserciones; los *dancing
  links* de Knuth para cubrir exactamente, que quitan y reponen nodos de dos listas a la vez.
- **Si no te la sabes.** Arreglos de índices `next[]` y `prev[]` por secuencia: las mismas operaciones con
  mejor localidad.
- **Dónde está entera.** Brassard y Bratley, cap. 5; Knuth, Vol. 1, §2.2.6 (listas ortogonales).

---

## 7. ⏱️ La tabla de costes

| Operación | Lista simple | Lista doble | Arreglo | Lo que la tabla no dice |
|---|---|---|---|---|
| Acceso a la posición `i` | `Θ(i)` | `Θ(min(i, n − i))` | `Θ(1)` | Cada paso puede ser un fallo de caché |
| Insertar o borrar con el nodo en mano | `Θ(1)` (borrar necesita el anterior) | `Θ(1)` | `Θ(n)` | Encontrar el nodo suele costar `Θ(n)` |
| Invertir, punto medio, mezclar | `Θ(n)`, `Θ(1)` memoria | `Θ(n)` | `Θ(n)` | — |
| Detectar ciclo (Floyd) | `O(μ + λ)`, `Θ(1)` memoria | — | — | Vale para cualquier `f` iterada |
| LRU `get`/`put` | — | `O(1)` con mapa | — | El mapa es *hash*: `O(1)` esperado |

---

## 8. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| «Devuelve la cabeza nueva», borrados en la cabeza | Nodo centinela | Todo nodo tiene un anterior |
| «Mitad de la lista», «palíndromo», «reordenar» | Lento y rápido; invertir la segunda mitad | El rápido marca el final |
| «Ciclo», «se repite», «memoria `O(1)`» | Floyd | Dos velocidades sobre una función iterada |
| «Valores en `[1, n]` que son índices», «duplicado sin modificar el arreglo» | Floyd sobre `i ↦ a[i]` | El arreglo es una función |
| «Capacidad fija», «el usado hace más tiempo» | LRU: mapa + lista doble | Mover al frente y expulsar en `O(1)` |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La lista enlazada inserta en `O(1)`» | Con el nodo en mano; llegar a él es `O(n)` (`02/05`) |
| «`LinkedList` es buena cola» | Funciona, con un nodo por elemento y mala localidad; `ArrayDeque` es mejor (`06/01`) |
| «Floyd compara los valores de los nodos» | Compara identidades: dos nodos pueden tener el mismo valor |
| «Floyd encuentra el ciclo, pero no su inicio» | La fase 2 (uno vuelve al principio) da el inicio exacto |
| «Para la LRU basta un `HashMap` y una cola» | La cola no permite mover un elemento del medio al frente en `O(1)` |
| «Invertir la lista necesita memoria `O(n)`» | Se invierte en el sitio con tres punteros |

---

## 📚 Para profundizar

- **Libro** — Goodrich, Tamassia y Goldwasser, *Data Structures and Algorithms in Java*, 6.ª ed. (Wiley,
  2014), cap. 3: listas simples, dobles y circulares con centinelas. *Lectura troncal.*
- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5: listas y
  su representación con punteros y con arreglos. *Lectura troncal.*
- **Libro** — Knuth, *The Art of Computer Programming*, Vol. 2 (Addison-Wesley), §3.1, ejercicio 6: el
  algoritmo de Floyd para detectar ciclos.
- **Documentación** — Java, [`LinkedHashMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/LinkedHashMap.html)
  (el ejemplo de `removeEldestEntry`); Python, [`OrderedDict`](https://docs.python.org/3/library/collections.html#collections.OrderedDict).

---

## 🧠 Preguntas

1. ¿Qué es un nodo centinela y qué casos especiales elimina? 🟢
2. ¿Qué pasa si al invertir una lista cambias `cur.next` antes de guardarlo? 🟢
3. ¿Cuándo es `O(1)` insertar en una lista enlazada y cuándo no? 🟢
4. ¿Por qué el puntero rápido, al llegar al final, deja al lento en la mitad? ¿Qué devuelve con `n` par? 🟢
5. ¿Por qué el lento y el rápido se encuentran si hay un ciclo, y en cuántos pasos como mucho? 🟡
6. Explica las tres operaciones de la LRU y qué estructura hace cada una en `O(1)`. 🟡
7. ¿Qué hace el tercer argumento `true` del constructor de `LinkedHashMap`? 🟡
8. Demuestra que la fase 2 de Floyd termina exactamente en el inicio del ciclo. 🟠
9. Compara cómo escribes una LRU en C++, Java y Python con la biblioteca estándar. 🟠
10. ¿Cómo calculas la longitud del ciclo una vez encontrado su inicio? ¿Y con el algoritmo de Brent? 🟠
11. ¿Qué condición necesita una función `f` para que la secuencia `x, f(x), f(f(x)), …` tenga siempre un ciclo y Floyd termine? Da una `f` en la que no termina. 🟠
12. Diseña una lista doble sin punteros, con arreglos `next[]` y `prev[]`, y explica qué ganas. 🔴
13. Demuestra que la lista doble con dos centinelas de la LRU mantiene su invariante tras `get` y `put`, incluido un `put` de una clave que ya existe con la caché llena. 🔴

---

## 🧩 Problemas propios

### El corro

**Nivel:** 🟡 · **Formato:** programa completo.

`n` jugadores numerados de 1 a `n` forman un corro. Empezando a contar por el 1, cada `k`-ésimo jugador
sale, y la cuenta sigue desde el siguiente. Imprime el orden de salida.

- **Entrada.** Una línea con `n` y `k`.
- **Salida.** `n` números separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 5000`; `1 ≤ k ≤ 10⁹`.

```text
Entrada            Salida
6 2                2 4 6 3 1 5

Entrada            Salida
5 3                3 1 5 2 4
```

**Pista 1:** con `k = 10⁹`, ¿cuántas vueltas completas al corro puedes ahorrarte antes de cada salida?

### Editor con cursor

**Nivel:** 🟡 · **Formato:** programa completo.

Un editor empieza vacío con el cursor al principio. Cada carácter de la entrada es una orden: una letra
se escribe en el cursor; `<` mueve el cursor a la izquierda; `>` a la derecha; `-` borra el carácter a la
izquierda del cursor. Las órdenes imposibles no hacen nada. Imprime el texto final.

- **Entrada.** Una línea con las órdenes.
- **Salida.** El texto final.
- **Restricciones.** Hasta `10⁶` órdenes; letras minúsculas.

```text
Entrada            Salida
abc<<x>-           axc

Entrada            Salida
ab<<<-c            cab
```

**Pista 1:** ¿qué estructura deja insertar y borrar junto al cursor en `O(1)`?

### El bucle del generador

**Nivel:** 🟠 · **Formato:** programa completo.

La secuencia `x₀` dado, `x_{i+1} = (a · x_i² + b) mod m` acaba repitiéndose. Imprime `μ` (el índice del
primer valor que se repite) y `λ` (la longitud del ciclo), con memoria `O(1)`.

- **Entrada.** Una línea con `a`, `b`, `m` y `x₀`.
- **Salida.** Una línea con `μ` y `λ`.
- **Restricciones.** `2 ≤ m ≤ 10¹²`; `0 ≤ a, b, x₀ < m`; se garantiza `μ + λ ≤ 10⁷`.

```text
Entrada            Salida
1 1 10 0           0 6

Entrada            Salida
2 3 17 1           1 5
```

**Pista 1:** con `m = 10¹²`, ¿cuánto vale `x_i²` y en qué tipo cabe?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de escribir la manipulación de una lista, dibuja tres nodos y numera las
> asignaciones de punteros. Si una IA te da código, pídele el dibujo de cada paso; es donde se ve el
> puntero perdido ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Middle of the Linked List](https://leetcode.com/problems/middle-of-the-linked-list/) | LeetCode | 🟢 | Lento y rápido | ¿Dónde está el lento cuando el rápido no puede avanzar más? |
| [ ] | [Palindrome Linked List](https://leetcode.com/problems/palindrome-linked-list/) | LeetCode | 🟢 | Punto medio e inversión | ¿Qué mitad inviertes para compararla con la otra? |
| [ ] | [Intersection of Two Linked Lists](https://leetcode.com/problems/intersection-of-two-linked-lists/) | LeetCode | 🟢 | Dos punteros que cambian de lista | Si los dos recorren las dos listas, ¿cuánto camino hacen? |
| [ ] | [Remove Nth Node From End of List](https://leetcode.com/problems/remove-nth-node-from-end-of-list/) | LeetCode | 🟡 | Dos punteros con separación fija | ¿Cuántos pasos de ventaja le das al primero? |
| [ ] | [Reverse Linked List II](https://leetcode.com/problems/reverse-linked-list-ii/) | LeetCode | 🟡 | Inversión de un tramo con centinela | ¿Qué nodo tienes que guardar antes del tramo? |
| [ ] | [Reorder List](https://leetcode.com/problems/reorder-list/) | LeetCode | 🟡 | Mitad, inversión y mezcla alterna | ¿Qué tres manipulaciones encadenas? |
| [ ] | [Find the Duplicate Number](https://leetcode.com/problems/find-the-duplicate-number/) | LeetCode | 🟡 | Floyd sobre un arreglo | Si ves el arreglo como `i → nums[i]`, ¿qué forma tiene? |
| [ ] | [Copy List with Random Pointer](https://leetcode.com/problems/copy-list-with-random-pointer/) | LeetCode | 🟡 | Mapa de original a copia | ¿Cómo encuentras la copia del nodo al que apunta `random`? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Odd Even Linked List](https://leetcode.com/problems/odd-even-linked-list/) | LeetCode | 🟡 | Dos listas y unión | ¿Qué dos colas vas construyendo mientras recorres? |
| [ ] | [Add Two Numbers](https://leetcode.com/problems/add-two-numbers/) | LeetCode | 🟡 | Recorrido paralelo con acarreo | ¿Qué pasa cuando una lista se acaba antes que la otra? |
| [ ] | [Rotate List](https://leetcode.com/problems/rotate-list/) | LeetCode | 🟡 | Cerrar en anillo y cortar | Con `k` mayor que la longitud, ¿cuánto rotas de verdad? |
| [ ] | [Flatten a Multilevel Doubly Linked List](https://leetcode.com/problems/flatten-a-multilevel-doubly-linked-list/) | LeetCode | 🟡 | Lista múltiple con pila | ¿Dónde continúas cuando acabas una sublista? |
| [ ] | [Reverse Nodes in k-Group](https://leetcode.com/problems/reverse-nodes-in-k-group/) | LeetCode | 🔴 | Inversión por tramos | ¿Qué nodos necesitas para enganchar cada tramo invertido? |

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [LFU Cache](https://leetcode.com/problems/lfu-cache/) | LeetCode | 🔴 | Listas por frecuencia y mapa | Para expulsar en `O(1)`, ¿qué tienes que saber de la frecuencia mínima? |

---

## ✅ Criterio de dominio

- Escribir invertir, punto medio, mezclar y Floyd con su fase 2 sin mirar.
- Demostrar por qué la fase 2 de Floyd acaba en el inicio del ciclo.
- Escribir la LRU a mano con nodos dobles y con la biblioteca de cada lenguaje.
- Resolver Reorder List y Find the Duplicate Number sin pista 2.

---

**Anterior:** [`06/01` — Pila, cola, deque y sus versiones monótonas](01-pilas-colas-y-monotonas.md) ·
**Siguiente:** [`06/03` — Tablas *hash* por dentro y los *anti-hash tests*](03-tablas-hash.md) · **Relacionado:**
[`02/05` — El coste real](../02-analisis/05-el-coste-real.md).
