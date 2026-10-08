# 03 — Java: las colecciones para competir y sus trampas

> Usar las colecciones de Java con su coste real: `ArrayList`, `ArrayDeque`, `HashMap`, `TreeMap` y
> `PriorityQueue`, con `Arrays`, `Collections` y `BitSet` de apoyo. Y las trampas que dan WA o RE
> sin avisar: `Integer` con `==`, `remove(int)` frente a `remove(Object)`, el *multiset* que no existe
> y la pila que se desborda con la recursión.
>
> **Niveles:** `ArrayList`, `ArrayDeque`, `HashMap`, `TreeMap`, `PriorityQueue` [A] · `BitSet`,
> `Arrays`, `Collections` [B].
>
> **📚 Lectura troncal:** la documentación de la API de Java 21, paquete `java.util`; Sedgewick y Wayne,
> *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), cap. 1.
>
> **Ruta corta:** sí (si tu lenguaje es Java).
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [1](#1--el-problema) · [2](#2--arraylist) · [3](#3--arraydeque) · [4](#4--hashmap) · [5](#5--treemap) · [6](#6--priorityqueue) · [7](#7--arrays-collections-y-bitset) · [8](#8--las-trampas-de-la-jvm) · [9](#9-️-la-tabla-de-costes) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Dos listas de votos, y hay que saber si cada candidato recibió el mismo número de votos en las dos.
Se cuentan en dos `HashMap<Integer, Integer>` y se comparan:

```java
// falla: con conteos mayores que 127, compara referencias y dice que son distintos
for (int candidate : first.keySet()) {
    if (first.get(candidate) != second.get(candidate)) return false;
}
```

Con los ejemplos —pocos votos— funciona. Con el caso grande, donde un candidato tiene 500 votos en
las dos listas, devuelve `false`. `get` devuelve un `Integer`, y `!=` entre dos `Integer` compara **si
son el mismo objeto**, no si valen lo mismo. Java reutiliza los objetos de −128 a 127, así que con
conteos pequeños las referencias coinciden por casualidad; con 500, cada mapa tiene su objeto.

Java es el lenguaje de la entrevista, y su librería de colecciones tiene casi todo lo que hace falta:
un arreglo dinámico, una cola doble, un diccionario *hash*, uno ordenado con sucesor y predecesor, y un
montículo. Pero todo eso trabaja con **objetos**, y de ahí salen sus trampas: el *boxing*, las
comparaciones por referencia, la memoria y las sobrecargas que se confunden. Este capítulo recorre cada
colección con su coste y su trampa, y cierra con lo que la JVM cobra aparte: la pila de la recursión.

---

## 2. 🧱 `ArrayList`

**Qué es.** Un arreglo dinámico de referencias, que crece un 50 % cada vez que se llena ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

**Cómo va.**

```java
import java.util.ArrayList;
import java.util.List;

List<Integer> list = new ArrayList<>(List.of(5, 2, 9, 1, 5, 6));
list.add(7);                        // al final: O(1) amortizado
int x = list.get(2);                // 9: O(1), con desempaquetado
list.remove(list.size() - 1);       // quita el último: O(1)
list.remove(Integer.valueOf(5));    // quita el PRIMER 5 por valor: O(n)
list.remove(0);                     // quita el de la POSICIÓN 0: O(n), desplaza todo
```

- **`remove(int)` frente a `remove(Object)`**: con una `List<Integer>`, `list.remove(5)` quita el
  elemento de la **posición** 5, no el valor 5. Para quitar el valor hay que pasar un objeto:
  `list.remove(Integer.valueOf(5))`. Es la trampa más silenciosa de las colecciones de Java.
- **`remove(0)` es `O(n)`**: una `ArrayList` no es una cola ([`02/06`](../02-analisis/06-tipos-abstractos-de-datos.md)).
- **Para muchos enteros**, un `int[]` con un contador hace lo mismo sin *boxing* (`02/05`).

> 📝 **Desde Java 21:** `ArrayList`, `ArrayDeque`, `LinkedHashMap` y `TreeSet`, entre otras, implementan
> las nuevas interfaces *sequenced*: `getFirst()`, `getLast()`, `removeLast()` y `reversed()` sin
> índices. En las versiones anteriores, `get(0)` y `get(size() − 1)`.

**Cuánto cuesta.** `get`, `set` y `add` al final en `O(1)` (amortizado el `add`); insertar o borrar en
otra posición, `O(n)`. Unos 20 bytes por entero entre el objeto y la referencia.

**Cuándo sí**: listas de tamaño variable, listas de adyacencia ([`14/01`](../14-grafos-recorridos/01-representaciones.md)). **Cuándo no**: como cola, ni
para millones de primitivos donde un `int[]` cabe.

> **Veredicto:** `ArrayList` es la secuencia por defecto. Y con `List<Integer>`, `remove` con un `int`
> borra por posición.

---

## 3. 🧱 `ArrayDeque`

**Qué es.** Una cola doble sobre un arreglo circular: la pila y la cola de Java. No admite `null`.

**Cómo va.**

```java
import java.util.ArrayDeque;
import java.util.Deque;

Deque<Integer> stack = new ArrayDeque<>();
stack.push(5); stack.push(2);       // pila: por el principio
int top = stack.pop();              // 2

Deque<Integer> queue = new ArrayDeque<>();
queue.offer(5); queue.offer(2);     // cola: entra por el final
int first = queue.poll();           // 5: sale por el principio; null si está vacía
```

- **Como pila**, `push`, `pop` y `peek` trabajan por el principio; **como cola**, `offer` añade al final
  y `poll` saca del principio. Mezclar los dos conjuntos de métodos sobre la misma `Deque` mezcla los
  extremos.
- **`pop` lanza** `NoSuchElementException` si está vacía; **`poll` devuelve `null`**. Con `poll` y un
  `int` de destino, el `null` se desempaqueta y lanza `NullPointerException`.
- **`Stack` no es la pila de Java**: es una clase antigua que hereda de `Vector`, sincronizada y con
  acceso por índice (`02/06`). **`LinkedList`** cumple el mismo contrato que `ArrayDeque`, con un nodo
  por elemento y más lenta.

**Cuánto cuesta.** Todas las operaciones de los extremos en `O(1)` (amortizado al crecer).

**Cuándo sí**: pilas, colas, BFS ([`14/02`](../14-grafos-recorridos/02-bfs.md)), colas monótonas ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)). **Cuándo no**: si necesitas
acceso por índice.

> **Veredicto:** `ArrayDeque` para la pila y para la cola; `Stack` y `LinkedList`, nunca para eso.

---

## 4. 🧱 `HashMap`

**Qué es.** Un diccionario con tabla *hash*: `O(1)` esperado, sin orden. `HashSet` es un `HashMap` sin
valores.

**Cómo va.**

```java
import java.util.HashMap;
import java.util.Map;

Map<Integer, Integer> freq = new HashMap<>();
for (int x : new int[] {5, 2, 9, 1, 5, 6}) freq.merge(x, 1, Integer::sum);   // conteo en una línea
int fives = freq.getOrDefault(5, 0);                                          // 2
Map<Integer, List<Integer>> groups = new HashMap<>();
groups.computeIfAbsent(5, k -> new ArrayList<>()).add(0);                     // lista por clave
boolean sameCount = freq.get(5).equals(freq.get(1) + 1);                      // equals, nunca ==
```

- **`merge`, `getOrDefault` y `computeIfAbsent`** sustituyen al patrón «si no está, poner; si está,
  actualizar», con una sola búsqueda.
- **Por dentro**: la cubeta es el `hashCode()` mezclado (`h ^ (h >>> 16)`) y reducido a la capacidad,
  que es una potencia de dos; crece al doble cuando pasa del 75 % de carga. **Desde Java 8, una cubeta
  con más de 8 entradas** (en una tabla de al menos 64 cubetas) **se convierte en un árbol
  rojo-negro**, y con claves comparables el caso peor por operación baja de `O(n)` a `O(log n)`.
- **El *hash* de `Integer` es su propio valor**: un adversario puede elegir claves que caigan en la
  misma cubeta. El árbol limita el daño, pero la constante sube. Los detalles son de [`06/03`](../06-lineales-y-hashing/03-tablas-hash.md).

> 📝 **Desde Java 19:** `HashMap.newHashMap(n)` crea un mapa con capacidad para `n` entradas sin
> crecer. Antes, `new HashMap<>(n * 4 / 3 + 1)`, que tiene en cuenta el factor de carga.

**Cuánto cuesta.** `get` y `put` en `O(1)` esperado; `O(log n)` en el caso peor con claves
comparables. Unos 50 a 80 bytes por entrada entre el nodo y los objetos.

**Cuándo sí**: conteos, pertenencia, memoización con claves dispersas. **Cuándo no**: si necesitas
orden, o con muchos millones de entradas pequeñas, donde un arreglo indexado gana.

> **Veredicto:** `HashMap` con `merge` y `getOrDefault`, y los valores se comparan con `equals`. El
> árbol de Java 8 lo protege de los ataques a medias.

---

## 5. 🧱 `TreeMap`

**Qué es.** Un diccionario ordenado sobre un árbol rojo-negro: `O(log n)` en el caso peor, con
sucesor, predecesor y rangos. `TreeSet` es un `TreeMap` sin valores.

**Cómo va.**

```java
import java.util.TreeMap;

TreeMap<Integer, Integer> counts = new TreeMap<>();   // multiset: valor → copias
for (int x : new int[] {5, 2, 9, 1, 5, 6}) counts.merge(x, 1, Integer::sum);

Integer atMost7 = counts.floorKey(7);      // 6: mayor clave <= 7, o null
Integer above5 = counts.higherKey(5);      // 6: menor clave > 5
Integer atLeast3 = counts.ceilingKey(3);   // 5: menor clave >= 3
int smallest = counts.firstKey();          // 1

// quitar UNA copia del multiset
counts.merge(5, -1, Integer::sum);         // quedan 1 copia de 5
if (counts.get(5) == 0) counts.remove(5);  // == con un int a la derecha: desempaqueta, es seguro

var between = counts.subMap(2, true, 6, true);   // vista de las claves en [2, 6], sin copiar
```

- **`floorKey`, `ceilingKey`, `lowerKey` y `higherKey`** devuelven `null` si no hay ninguna: el
  resultado es un `Integer`, y asignarlo a un `int` sin comprobar lanza `NullPointerException`.
- **El *multiset* no existe en Java**: se escribe con un `TreeMap` de conteos, como arriba. Quitar una
  copia es decrementar el conteo y **borrar la clave cuando llega a cero**, o `firstKey` devolverá un
  valor que ya no está.
- **`subMap`, `headMap` y `tailMap` son vistas**: no copian; modificarlas modifica el mapa.

**Cuánto cuesta.** Todas las operaciones en `O(log n)` caso peor; la constante es mayor que la de
`HashMap` y cada entrada es un nodo con varios punteros.

**Cuándo sí**: el mayor que no pasa de un valor, el siguiente libre, rangos de claves, *multiset*.
**Cuándo no**: como diccionario sin orden; ahí `HashMap`.

> **Veredicto:** `TreeMap` es el `set`, el `map` y el `multiset` de C++ en uno, con `floorKey` y
> `ceilingKey` que devuelven `null` y el conteo que hay que borrar al llegar a cero.

---

## 6. 🧱 `PriorityQueue`

**Qué es.** Un montículo binario ([`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md)). **Da el mínimo por defecto**, al revés que el
`priority_queue` de C++.

**Cómo va.**

```java
import java.util.Collections;
import java.util.PriorityQueue;

PriorityQueue<Integer> minHeap = new PriorityQueue<>();
PriorityQueue<Integer> maxHeap = new PriorityQueue<>(Collections.reverseOrder());

// Pares (distancia, nodo) como long[]: se ordena por el primero
PriorityQueue<long[]> pq = new PriorityQueue<>((p, q) -> Long.compare(p[0], q[0]));
pq.offer(new long[] {7, 3});
long[] best = pq.poll();             // el de menor distancia; null si está vacía
```

- **El comparador con `Long.compare`**, nunca con una resta: `(p, q) -> (int) (p[0] − q[0])` desborda y
  deja de ser un orden ([`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md)).
- **No hay `decrease-key`**: se reinserta con la prioridad nueva y se descartan las entradas viejas al
  sacarlas. **`remove(Object)` existe pero es `O(n)`**.
- **Recorrerla con `for` no da los elementos en orden**: solo `poll` sucesivos lo hacen.

**Cuánto cuesta.** `offer` y `poll` en `O(log n)`; `peek` en `O(1)`; construirla desde una colección,
`O(n)`.

**Cuándo sí**: el menor o el mayor de los que hay con inserciones (Dijkstra, [`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md); la mediana con dos
montículos). **Cuándo no**: con borrados arbitrarios frecuentes; ahí `TreeMap`.

> **Veredicto:** `PriorityQueue` da el mínimo; para el máximo, `Collections.reverseOrder()`. Y el
> comparador, con `Integer.compare` o `Long.compare`.

---

## 7. 🧱 `Arrays`, `Collections` y `BitSet`

**Qué es.** Las utilidades de nivel B: ordenar, buscar, rellenar, barajar, y un conjunto de bits.

**Cómo va.**

```java
import java.util.Arrays;
import java.util.BitSet;
import java.util.Collections;

int[] a = {5, 2, 9, 1, 5, 6};
Arrays.sort(a);                              // primitivos: quicksort de doble pivote
Arrays.fill(a, 0);                           // rellena
int pos = Arrays.binarySearch(a, 0);         // ALGÚN índice con ese valor; si no está, −(inserción) − 1

Integer[] boxed = {5, 2, 9, 1, 5, 6};
Arrays.sort(boxed, Collections.reverseOrder());   // objetos: TimSort, estable

BitSet seen = new BitSet(1_000_001);
seen.set(5);
int next = seen.nextSetBit(3);               // 5: el siguiente bit a 1 desde 3
int howMany = seen.cardinality();            // bits a 1
```

- **`Arrays.sort` en primitivos** es un *quicksort* de doble pivote. **Desde Java 14, cambia a
  *heapsort*** si la recursión se hace demasiado profunda, así que en Java 21 es `O(n log n)` en el caso
  peor; **hasta Java 13 no tenía ese respaldo**, y había entradas construidas para hacerlo cuadrático,
  que algunos concursos usaban contra soluciones en Java 8 u 11. Comprobado en el código fuente de
  OpenJDK 21. Si el juez corre una versión antigua, se baraja el arreglo antes de ordenar.
- **`Arrays.sort` en objetos** y `Collections.sort` usan TimSort: estable y `O(n log n)` en el caso
  peor, con la constante de comparar objetos.
- **`Arrays.binarySearch`** devuelve **algún** índice si hay repetidos, no el primero (`02/04`).
- **`BitSet`** crece solo y opera de 64 en 64; `nextSetBit` recorre los bits a 1 sin mirar los demás.

**Cuánto cuesta.** Ordenar `O(n log n)`; `fill` y `binarySearch` lo esperado; `BitSet` `O(n/64)` en las
operaciones de conjunto.

**Cuándo sí**: siempre que la operación sea una de estas. **Cuándo no**: `binarySearch` cuando necesitas
el primero de varios iguales; ahí, tu propia búsqueda.

> **Veredicto:** `Arrays.sort` sobre primitivos para ordenar rápido, y en objetos solo si hace falta
> estabilidad o un comparador. `binarySearch` no da el primero.

---

## 8. 🧱 Las trampas de la JVM

**Qué es.** Lo que la JVM cobra aparte de las colecciones: el *boxing*, la igualdad por referencia y la
pila de la recursión.

**`Integer` y `==`.** El *autoboxing* convierte un `int` en un `Integer` llamando a `Integer.valueOf`,
que **reutiliza los objetos de −128 a 127**. Por eso `==` entre dos `Integer` funciona con valores
pequeños y falla con grandes: compara referencias. Las reglas:

```text
Integer con Integer      → equals, o desempaqueta uno: a.intValue() == b
Integer con int          → == desempaqueta y compara valores: es seguro
Integer null con int     → NullPointerException al desempaquetar
```

**La recursión profunda.** La pila del hilo principal es pequeña (del orden de 1 MB en una JVM de 64
bits), y una recursión de profundidad `10⁵` —un DFS sobre una lista encadenada— da
`StackOverflowError`, que el juez informa como RE. La salida es ejecutar el trabajo en un hilo con
la pila que se pida:

```java
public class Main {
    public static void main(String[] args) throws InterruptedException {
        Thread worker = new Thread(null, Main::solve, "solve", 1L << 28);   // pila de 256 MB
        worker.start();
        worker.join();                         // esperar a que termine antes de salir
    }

    static void solve() {
        // aquí va el programa entero: lectura, recursión y salida
    }
}
```

- **El cuarto argumento** del constructor es el tamaño de pila pedido; la JVM puede tratarlo como una
  sugerencia, pero en los jueces habituales se respeta.
- **`join()`** hace que `main` espere: sin él, el programa podría terminar antes que el hilo.
- **La alternativa** es convertir la recursión en iterativa con una pila explícita ([`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md)), que no
  depende de la JVM.

**Cuánto cuesta.** El *boxing*, memoria y tiempo (`02/05`); el hilo, nada medible. **Cuándo sí** se
lanza el hilo: con cualquier recursión cuya profundidad dependa de `n`. **Cuándo no**: con recursiones
de profundidad logarítmica.

> **Veredicto:** los valores de colecciones se comparan con `equals`, y toda recursión de profundidad
> `n` va en un hilo con pila grande.

---

## 9. ⏱️ La tabla de costes

| Colección | Operación principal | Coste | Lo que la tabla no dice |
|---|---|---|---|
| `ArrayList` | `add` / `get` / `remove(0)` | `O(1)` amort. / `O(1)` / `O(n)` | `remove(int)` borra por posición |
| `ArrayDeque` | `push`, `pop`, `offer`, `poll` | `O(1)` | Sin `null`; `poll` devuelve `null` si está vacía |
| `HashMap` | `get`, `put`, `merge` | `O(1)` esperado, `O(log n)` peor con claves comparables | El árbol de Java 8; atacable con el *hash* de `Integer` |
| `TreeMap` | `put`, `floorKey`, `ceilingKey` | `O(log n)` | Las consultas de vecino devuelven `null` |
| `PriorityQueue` | `offer`, `poll` / `peek` | `O(log n)` / `O(1)` | Mínimo por defecto; `remove(Object)` es `O(n)` |
| `Arrays.sort(int[])` | ordenar | `O(n log n)` peor desde Java 14 | Hasta Java 13, atacable; no estable (irrelevante en primitivos) |
| `Arrays.sort(Object[])` | ordenar | `O(n log n)` peor | Estable; compara objetos |

---

## 10. 🧭 Cómo se elige

```text
¿Secuencia con acceso por índice?                      → ArrayList (o int[] si son muchos primitivos)
¿Pila o cola?                                           → ArrayDeque
¿Diccionario o conjunto sin orden?                      → HashMap / HashSet
¿Orden: vecino, rango, mínimo con borrados, multiset?   → TreeMap / TreeSet (multiset = conteos)
¿El menor o el mayor de los que hay, con inserciones?   → PriorityQueue
¿Ordenar muchos enteros?                                → int[] y Arrays.sort
¿Recursión con profundidad que depende de n?            → Thread con pila grande, o iterativo
```

> **Mejor:** «Lo resuelvo con un `TreeMap` de conteos como *multiset*: `floorKey` me da el mayor que no
> pasa del valor, y al vender decremento y borro la clave si llega a cero.»

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «`Arrays.sort` es siempre `n log n`» | En Java 21 sí, en primitivos por el respaldo de *heapsort*; hasta Java 13, el de primitivos se podía forzar a cuadrático |
| «`Integer == Integer` compara valores» | Compara referencias; acierta de −128 a 127 por la caché, y falla fuera |
| «`Stack` es la pila de Java» | Es una clase heredada de `Vector`; la pila es `ArrayDeque` |
| «`list.remove(5)` quita el 5» | Con `List<Integer>`, quita el de la posición 5; el valor, con `remove(Integer.valueOf(5))` |
| «Java tiene *multiset*» | No: se escribe con un `TreeMap` de conteos, borrando la clave al llegar a cero |
| «`PriorityQueue` da el máximo» | Da el mínimo; el máximo, con `Collections.reverseOrder()` |
| «`HashMap` es `O(n)` en el caso peor» | Desde Java 8, con claves comparables, `O(log n)` por el árbol en las cubetas llenas |

---

## 📚 Para profundizar

- **Documentación** — Java 21, [`TreeMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/TreeMap.html)
  y [`NavigableMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/NavigableMap.html):
  `floorKey`, `ceilingKey` y las vistas de rango. *Lectura troncal.*
- **Documentación** — Java 21, [`HashMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/HashMap.html)
  y [`PriorityQueue`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/PriorityQueue.html):
  el factor de carga y el coste de cada operación.
- **Documentación** — Java 21, [`Arrays`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Arrays.html)
  y [`Collections`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Collections.html).
- **Documentación** — Java 21, [`SequencedCollection`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/SequencedCollection.html)
  y [`Thread`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Thread.html): el
  constructor con tamaño de pila.
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), cap. 1: pilas, colas y
  bolsas implementadas en Java, y el modelo de coste. *Lectura troncal.*
- **Referencia** — Sedgewick y Wayne, [*Data Abstraction*](https://algs4.cs.princeton.edu/12oop/): las
  trampas de los tipos envoltorio y de la igualdad en Java.

---

## 🧠 Preguntas

1. ¿Qué colección de Java usas como pila y como cola, y por qué no `Stack`? 🟢
2. ¿Qué devuelve `TreeMap.floorKey(x)` y qué devuelve si no hay ninguna clave que sirva? 🟢
3. ¿`PriorityQueue` da el mínimo o el máximo, y cómo consigues lo otro? 🟢
4. ¿Qué diferencia hay entre `list.remove(5)` y `list.remove(Integer.valueOf(5))` en una `List<Integer>`? 🟡
5. ¿Qué diferencia hay entre `Arrays.sort` sobre `int[]` y sobre `Integer[]`, en algoritmo y en garantías? 🟡
6. ¿Qué cambió en `HashMap` en Java 8 respecto del caso peor? 🟡
7. ¿Por qué `a == b` con dos `Integer` funciona con 100 y falla con 500? 🟠
8. Compara cómo escribes un *multiset* en C++, en Java y en Python, y qué hay que cuidar al quitar una copia en cada uno. 🟠
9. ¿Por qué un comparador `(p, q) -> p[0] - q[0]` para una `PriorityQueue` puede romper Dijkstra con distancias grandes? 🟠
10. Tu DFS recursivo en Java da RE solo en el caso más grande, que es una cadena de `2·10⁵` nodos. ¿Qué pasa y cómo lo arreglas sin reescribirlo? 🟠
11. Escribe con un `TreeMap` el fragmento que vende el billete más caro que no supera un presupuesto, en un *multiset* de precios, y di qué línea es la que más se olvida. 🔴
12. Un envío Java con `Arrays.sort(int[])` da TLE en un juez que corre Java 11 y pasa en uno con Java 21. Explica por qué es posible y cómo lo blindas en los dos. 🔴

---

## 🧩 Problemas propios

### Votos iguales

**Nivel:** 🟢 · **Formato:** programa completo.

Hay dos urnas con votos (identificadores de candidato). Imprime `SI` si todos los candidatos recibieron
el mismo número de votos en las dos urnas, y `NO` si no.

- **Entrada.** Una línea con `n`. Una línea con los `n` votos de la primera urna. Una línea con `m`. Una
  línea con los `m` votos de la segunda.
- **Salida.** `SI` o `NO`.
- **Restricciones.** `1 ≤ n, m ≤ 2·10⁵`; `1 ≤ voto ≤ 10⁹`.

```text
Entrada            Salida
3                  SI
5 2 5
3
2 5 5

Entrada            Salida
2                  NO
5 5
2
5 2
```

**Pista 1:** si cuentas con mapas, ¿cómo comparas dos conteos de 500 votos sin equivocarte?

### El turno anterior

**Nivel:** 🟡 · **Formato:** programa completo.

Una agenda registra turnos (enteros). Operaciones: `A x` añade el turno `x` (puede repetirse); `B x`
borra **una** copia del turno `x` (se garantiza que existe); `P x` imprime el mayor turno guardado que
sea `≤ x`, o `-1`.

- **Entrada.** Una línea con `q`. Después, `q` líneas con una operación.
- **Salida.** Una línea por cada `P`.
- **Restricciones.** `1 ≤ q ≤ 2·10⁵`; `0 ≤ x ≤ 10⁹`.

```text
Entrada            Salida
8                  5
A 5                5
A 5                2
A 2
P 7
B 5
P 5
B 5
P 5

Entrada            Salida
4                  -1
P 1000000000       0
A 0
P 0
B 0
```

**Pista 1:** después de borrar una copia, ¿cómo sabes si todavía quedan otras con el mismo valor?

### Tamaño de los equipos

**Nivel:** 🟠 · **Formato:** programa completo.

Una empresa tiene `n` empleados numerados de 1 a `n`; el 1 es el director y cada uno de los demás tiene
un jefe directo. El equipo de un empleado es él mismo más todos los que dependen de él, directa o
indirectamente. Imprime el tamaño del equipo de cada empleado.

- **Entrada.** Una línea con `n`. Una línea con `n − 1` enteros: el jefe de los empleados 2, 3, …, `n`.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`. La estructura puede ser una cadena: cada empleado, jefe del
  siguiente.

```text
Entrada            Salida
5                  5 3 1 1 1
1 1 2 2

Entrada            Salida
4                  4 3 2 1
1 2 3
```

**Pista 1:** si lo resuelves recursivamente, ¿qué profundidad alcanza la recursión en el segundo
ejemplo con `n = 2·10⁵`?

🔥 **Para el geek — en JavaScript:** la pila de Node también es pequeña y no hay un `Thread` con pila
grande; la versión en JavaScript obliga a escribir el recorrido iterativo con una pila explícita.

---

## 🧩 Práctica externa

Los de HackerRank son de su sección de Java: cada uno ejercita una colección concreta y sus métodos.

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Java Arraylist](https://www.hackerrank.com/challenges/java-arraylist/problem) | HackerRank | 🟢 | `ArrayList` de listas | ¿Qué pasa si la consulta pide una posición que esa fila no tiene? |
| [ ] | [Java Hashset](https://www.hackerrank.com/challenges/java-hashset/problem) | HackerRank | 🟢 | `HashSet` | ¿Qué clave representa un par de cadenas sin ambigüedad? |
| [ ] | [Java Map](https://www.hackerrank.com/challenges/phone-book/problem) | HackerRank | 🟢 | `HashMap` | ¿Qué devuelve `get` si el nombre no está? |
| [ ] | [Java BitSet](https://www.hackerrank.com/challenges/java-bitset/problem) | HackerRank | 🟢 | `BitSet` | ¿Qué operación de `BitSet` corresponde a cada orden del enunciado? |
| [ ] | [Java Dequeue](https://www.hackerrank.com/challenges/java-dequeue/problem) | HackerRank | 🟡 | `ArrayDeque` y conteo | Al mover la ventana, ¿qué cambia en el número de valores distintos? |
| [ ] | [Java Stack](https://www.hackerrank.com/challenges/java-stack/problem) | HackerRank | 🟡 | `ArrayDeque` como pila | Al ver un cierre, ¿con qué tiene que emparejar? |
| [ ] | [Java Priority Queue](https://www.hackerrank.com/challenges/java-priority-queue/problem) | HackerRank | 🟡 | `PriorityQueue` con comparador | ¿En qué orden se comparan los tres criterios del enunciado? |
| [ ] | [Java Comparator](https://www.hackerrank.com/challenges/java-comparator/problem) | HackerRank | 🟡 | Comparador con desempate | ¿Qué devuelve tu comparador cuando las puntuaciones coinciden? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Java Sort](https://www.hackerrank.com/challenges/java-sort/problem) | HackerRank | 🟢 | Ordenar objetos | ¿Cuántas claves de ordenación hay, y en qué sentido cada una? |
| [ ] | [Sort Characters By Frequency](https://leetcode.com/problems/sort-characters-by-frequency/) | LeetCode | 🟡 | Conteo y orden por valor | Después de contar, ¿por qué ordenas, por el carácter o por su conteo? |
| [ ] | [Contains Duplicate III](https://leetcode.com/problems/contains-duplicate-iii/) | LeetCode | 🟠 | Ventana con conjunto ordenado | Entre los valores de la ventana, ¿cuál es el único que necesitas mirar a cada lado del actual? |

---

## ✅ Criterio de dominio

- Escribir de memoria la pila y la cola con `ArrayDeque`, el *multiset* con `TreeMap` y el montículo de
  máximos con `PriorityQueue`.
- Explicar las tres trampas del capítulo: `Integer` con `==`, `remove(int)` y el `null` de `floorKey`.
- Lanzar una recursión profunda en un hilo con pila grande sin mirar.
- Decir qué garantiza `Arrays.sort` en primitivos según la versión de Java, y qué haces en un juez con
  Java 11.

---

**Anterior:** [`03/02` — C++: algoritmos, *ranges* y `ordered_set`](02-cpp-algoritmos-ranges-y-pbds.md) ·
**Siguiente:** [`03/04` — Python para competir](04-python-para-competir.md) ·
**Relacionado:** [`03/05` — La tabla de equivalencias](05-equivalencias-entre-lenguajes.md); [`02/05` — El coste real](../02-analisis/05-el-coste-real.md).
