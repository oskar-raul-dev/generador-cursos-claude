# 01 — Pila, cola, deque y sus versiones monótonas

> Las tres estructuras lineales con acceso por los extremos, cómo se escriben en cada lenguaje, y sus
> dos versiones monótonas: la pila que responde «el siguiente mayor» y la cola que da «el mínimo de cada
> ventana», las dos en `O(n)` total.
>
> **Niveles:** pila, cola, deque [A] · pila monótona [A] · cola monótona [A].
>
> **📚 Lectura troncal:** Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5;
> Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §1.3; Goodrich, Tamassia y
> Goldwasser, *Data Structures and Algorithms in Java*, 6.ª ed. (Wiley, 2014), cap. 6.
>
> **Asume leído:** [`04/02` — Dos punteros y ventana deslizante](../04-secuencias/02-dos-punteros-y-ventana.md).
>
> **Ruta corta:** sí.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [1](#1--el-problema) · [2](#2--la-teoría) · [3](#3--pila-cola-y-deque) · [4](#4--pila-monótona) · [5](#5--cola-monótona) · [6](#6-️-la-tabla-de-costes) · [7](#7--señales-del-enunciado) · [🧠](#-preguntas) · [🧩](#-problemas-propios)

---

## 1. 🎯 El problema

Muchos problemas sobre secuencias preguntan, para cada elemento, por **otro elemento cercano** con una
propiedad: el siguiente mayor, el anterior menor, el mínimo de los últimos `k`. La fuerza bruta mira
hacia un lado hasta encontrarlo: `O(n)` por elemento, `O(n²)` en total, `4·10¹⁰` operaciones con
`n = 2·10⁵`.

La salida es observar que, mientras se recorre, muchos elementos **ya no pueden ser respuesta de nadie**
y se pueden olvidar. Lo que queda forma una secuencia **monótona**, y se guarda en una pila (si las
consultas miran hacia atrás sin límite) o en una cola de doble extremo (si miran dentro de una
ventana). Cada elemento entra y sale una vez: `O(n)` en total.

Antes de eso, la base: la pila, la cola y la deque, cómo se escriben en cada lenguaje y qué
implementación usar —que no siempre es la que tiene el nombre obvio—.

---

## 2. 📐 La teoría

**Las tres estructuras.** Una **pila** saca el último que entró (LIFO); una **cola**, el primero (FIFO);
una **deque** (cola de doble extremo) mete y saca por los dos extremos. Las tres hacen cada operación
en `O(1)`, amortizado si se apoyan en un arreglo dinámico (`02/03`).

**El invariante de la pila monótona.** Para «el siguiente mayor a la derecha», se recorre de izquierda a
derecha guardando en una pila los índices que **todavía esperan** su siguiente mayor:

```text
Invariante: los valores de la pila, de abajo arriba, son estrictamente decrecientes,
            y son exactamente los índices ya vistos que aún no tienen un mayor a su derecha.
```

Cuando llega `a[i]`, todo índice de la cima con valor menor que `a[i]` tiene en `i` su respuesta: se
saca y se anota. Los que quedan son mayores o iguales que `a[i]`, así que al apilar `i` el orden se
mantiene. Un índice que sale **nunca volverá a ser respuesta** de nadie más a la derecha: `a[i]` es
mayor que él y está más cerca.

**El análisis agregado.** El bucle `while` de dentro puede sacar muchos elementos en una vuelta, pero
cada índice entra en la pila una vez y sale como mucho una vez: en total, como mucho `n` apilados y `n`
desapilados. El coste es `Θ(n)`, aunque haya un bucle dentro de otro (`02/03`).

**La cola monótona.** Para el mínimo de cada ventana de tamaño `k`, se guardan en una deque los índices
que aún pueden ser mínimo de alguna ventana futura: los valores, de delante atrás, son crecientes. Un
índice deja de ser útil por dos razones: llega uno **menor o igual** después de él (que vivirá más y es
mejor), y se saca por detrás; o **sale de la ventana**, y se saca por delante. El mínimo de la ventana
es siempre el de delante. Mismo análisis: cada índice entra y sale una vez.

---

## 3. 🧱 Pila, cola y deque

**Qué es.** Las tres estructuras de §2, con la implementación que conviene en cada lenguaje.

**Cómo va**, con la pila: al leer una ruta de archivos `/a/./b/../../c/` por componentes, cada nombre se
apila, `.` no hace nada y `..` desapila:

```text
a     → [a]
.     → [a]
b     → [a, b]
..    → [a]
..    → []
c     → [c]          resultado: /c
```

**Cuánto.** `O(1)` por operación (amortizado con arreglos dinámicos); memoria `Θ(n)`.

**La plantilla**, las operaciones en los tres lenguajes:

```cpp
#include <deque>
#include <stack>
#include <vector>

std::vector<int> st;            // pila: push_back, back, pop_back (más flexible que std::stack)
std::deque<int> dq;             // cola y deque: push_back, push_front, front, back, pop_front, pop_back
std::stack<int> s;              // adaptador sobre deque: push, top, pop; no se puede recorrer
```

```java
import java.util.ArrayDeque;
import java.util.Deque;

Deque<Integer> stack = new ArrayDeque<>();   // pila: push, peek, pop
Deque<Integer> queue = new ArrayDeque<>();   // cola: offer, peek, poll
Deque<Integer> deque = new ArrayDeque<>();   // deque: offerFirst/offerLast, peekFirst/peekLast,
                                             //        pollFirst/pollLast
```

```python
from collections import deque

stack = []          # pila: append, stack[-1], pop()
dq = deque()        # cola y deque: append, appendleft, dq[0], dq[-1], popleft(), pop()
```

- **C++**: un `std::vector` como pila permite recorrerla y mirar cualquier posición, que en las pilas
  monótonas se necesita a menudo. `std::deque` reserva por bloques: sin realojar todo al crecer.
- **Java**: `ArrayDeque` es la pila y la cola. `Stack` hereda de `Vector`, sincroniza cada operación y
  su propia documentación recomienda `Deque`; `LinkedList` crea un nodo por elemento ([`02/05`](../02-analisis/05-el-coste-real.md)).
  `ArrayDeque` no admite `null`.
- **Python**: `list` es una buena pila; como cola, `list.pop(0)` es `O(n)` porque desplaza todo:
  `deque.popleft()` es `O(1)`. El acceso por índice en mitad de una `deque` es `O(n)`.

> 📝 **En JavaScript:** no hay deque en la biblioteca estándar, y `Array.prototype.shift()` puede ser
> `O(n)`. Una cola se escribe con un arreglo y un índice de cabeza que avanza ([`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)).

### De la versión ingenua a la buena

**El problema.** Normalizar una ruta de archivos: `.` es el directorio actual y `..` el padre. Con
`/a/./b/../../c/`, el resultado es `/c`.

**La versión ingenua:**

```java
// O(n²): la cadena hace de pila, y cada concatenación o recorte la copia entera.
static String simplify(String path) {
    String res = "";
    for (String part : path.split("/")) {
        if (part.isEmpty() || part.equals(".")) continue;
        if (part.equals("..")) {
            int cut = res.lastIndexOf('/');
            res = cut < 0 ? "" : res.substring(0, cut);
        } else res = res + "/" + part;
    }
    return res.isEmpty() ? "/" : res;
}
```

> «La cadena resultado ya funciona como una pila, pero cada `+` y cada `substring` copian todo lo
> acumulado: con `10⁵` componentes, cuadrático. Con una pila de componentes, apilar y desapilar son
> `O(1)`, y la ruta se une una sola vez al final.»

**El camino a la buena.** Partir por `/`, recorrer los componentes con una `ArrayDeque` y unir lo que
quede, desde el fondo de la pila.

**Cuándo sí**: anidamiento, deshacer, evaluación de expresiones, recorridos en profundidad sin
recursión. **Cuándo no**: si hay que consultar posiciones intermedias con frecuencia, un arreglo.

> **Veredicto:** pila, cola y deque son `O(1)` por operación si se elige bien la implementación: en Java,
> `ArrayDeque`; en Python, `list` para pila y `deque` para cola.

---

## 4. 🧱 Pila monótona

**Qué es.** Una pila de índices cuyos valores son monótonos, que responde «el siguiente (o anterior)
mayor (o menor)» de cada elemento en un recorrido.

**Por qué es correcto.** Por el invariante de §2: al llegar `a[i]`, los índices de la cima con valor
menor son exactamente los que tienen en `i` su primer mayor a la derecha, porque todo lo que había entre
ellos e `i` ya era menor o igual (si no, estarían resueltos).

**Cómo va**, el siguiente mayor en `[5, 2, 9, 1, 5, 6]`:

```text
i  a[i]  saca (y su respuesta es i)     pila (valores)
0  5     —                              [5]
1  2     —                              [5, 2]
2  9     1 (el 2), 0 (el 5)             [9]
3  1     —                              [9, 1]
4  5     3 (el 1)                       [9, 5]
5  6     4 (el 5)                       [9, 6]
fin: 2 y 5 quedan sin siguiente mayor → −1
siguiente mayor: [9, 9, −1, 5, 6, −1]
```

**Cuánto.** `Θ(n)` por el análisis agregado; `Θ(n)` de memoria en el caso peor (entrada decreciente).

**La plantilla:**

```cpp
#include <vector>

// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
std::vector<int> nextGreater(const std::vector<int>& a) {
    int n = a.size();
    std::vector<int> ans(n, -1), st;              // st: índices con valores decrecientes
    for (int i = 0; i < n; i++) {
        while (!st.empty() && a[st.back()] < a[i]) { ans[st.back()] = i; st.pop_back(); }
        st.push_back(i);
    }
    return ans;
}
```

```java
// Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n).
static int[] nextGreater(int[] a) {
    int n = a.length;
    int[] ans = new int[n], st = new int[n];
    java.util.Arrays.fill(ans, -1);
    int top = 0;                                   // pila en un arreglo: sin cajas de Integer
    for (int i = 0; i < n; i++) {
        while (top > 0 && a[st[top - 1]] < a[i]) ans[st[--top]] = i;
        st[top++] = i;
    }
    return ans;
}
```

```python
def next_greater(a):
    """Para cada i, el índice del primer j > i con a[j] > a[i], o -1. Θ(n)."""
    ans, st = [-1] * len(a), []
    for i, x in enumerate(a):
        while st and a[st[-1]] < x:
            ans[st.pop()] = i
        st.append(i)
    return ans
```

- **Se guardan índices**, no valores: dan la distancia y permiten recuperar el valor.
- **`<` frente a `<=`** decide qué pasa con los iguales: con `<`, el siguiente **estrictamente** mayor;
  con `<=`, el siguiente mayor **o igual**.
- **Las cuatro variantes** (siguiente/anterior × mayor/menor) son la misma plantilla: cambiar el sentido
  del recorrido o la comparación. «El anterior menor» de cada elemento es lo que queda en la cima,
  después de sacar, al recorrer de izquierda a derecha.
- **Java**: una pila en un `int[]` con `top` evita crear un `Integer` por elemento.

**Una aplicación clásica**: el mayor rectángulo de un histograma. Para cada barra, con el anterior menor
`L[i]` y el siguiente menor `R[i]`, el rectángulo más ancho de altura `h[i]` mide `h[i] · (R[i] − L[i] − 1)`;
la respuesta es el máximo. Con `[5, 2, 9, 1, 5, 6]`, el área máxima es 10 (altura 5, sobre `[5, 6]`).

### De la versión ingenua a la buena

**El problema.** Una tienda aplica a cada artículo un descuento igual al precio del primer artículo
posterior que cueste lo mismo o menos (0 si no hay). Con precios `[5, 2, 9, 1, 5, 6]`, los precios finales
son `[3, 1, 8, 1, 5, 6]`; con `n = 2·10⁵` artículos.

**La versión ingenua:**

```java
// O(n²): con precios crecientes, cada artículo mira hasta el final.
static int[] finalPrices(int[] price) {
    int n = price.length;
    int[] out = price.clone();
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++)
            if (price[j] <= price[i]) { out[i] -= price[j]; break; }
    return out;
}
```

> «Es "el siguiente menor o igual": la plantilla con la comparación al revés. Los artículos que aún
> esperan su descuento forman una secuencia creciente en la pila; cada precio nuevo resuelve los de la
> cima que son mayores o iguales. Cada artículo entra y sale una vez: lineal.»

**El camino a la buena.** La plantilla con `a[st.back()] >= a[i]` como condición de salida, y restando
el precio de `i` a cada índice que sale.

**Cuándo sí**: siguiente/anterior mayor/menor; rangos donde un elemento es el mínimo o el máximo
(contribuciones); histogramas. **Cuándo no**: si la consulta es sobre una ventana de tamaño fijo, la cola
monótona; si son rangos arbitrarios, una tabla dispersa ([`09/01`](../09-consultas-sobre-rangos/01-sparse-table.md)).

> **Veredicto:** la pila monótona guarda solo los que aún pueden ser respuesta. Tiene un bucle dentro
> de otro y es lineal, porque cada elemento sale una sola vez.

---

## 5. 🧱 Cola monótona

**Qué es.** Una deque de índices con valores crecientes de delante atrás, que da el mínimo de una
ventana que se desliza (o el máximo, con la comparación al revés).

**Por qué es correcto.** Por el invariante de §2: un índice `j` con un índice posterior `i` y
`a[i] ≤ a[j]` no puede ser el mínimo de ninguna ventana futura, porque toda ventana que contenga a `j` y
sea futura contiene también a `i`. Los que quedan están ordenados, y el de delante es el menor de los
que siguen en la ventana.

**Cómo va**, el máximo de cada ventana de `k = 3` en `[5, 2, 9, 1, 5, 6]` (valores decrecientes):

```text
i  a[i]  deque (valores)       ventana     máximo
0  5     [5]
1  2     [5, 2]
2  9     [9]                   [0, 2]      9
3  1     [9, 1]                [1, 3]      9
4  5     [9, 5]                [2, 4]      9
5  6     [9, 6] → [6]          [3, 5]      6       el 9 (índice 2) sale de la ventana por delante
máximos: [9, 9, 9, 6]
```

**Cuánto.** `Θ(n)` total; `O(k)` de memoria.

**La plantilla**, el mínimo de cada ventana de tamaño `k`:

```cpp
#include <deque>
#include <vector>

// mins[i] = mínimo de a[i, i + k). Θ(n).
std::vector<int> windowMin(const std::vector<int>& a, int k) {
    std::deque<int> dq;                            // índices con valores crecientes
    std::vector<int> mins;
    for (int i = 0; i < (int)a.size(); i++) {
        while (!dq.empty() && a[dq.back()] >= a[i]) dq.pop_back();   // ya no serán mínimo
        dq.push_back(i);
        if (dq.front() <= i - k) dq.pop_front();                       // salió de la ventana
        if (i >= k - 1) mins.push_back(a[dq.front()]);
    }
    return mins;
}
```

```java
// mins[i] = mínimo de a[i, i + k). Θ(n).
static int[] windowMin(int[] a, int k) {
    int n = a.length;
    int[] dq = new int[n], mins = new int[n - k + 1];
    int head = 0, tail = 0;                        // deque en un arreglo: [head, tail)
    for (int i = 0; i < n; i++) {
        while (tail > head && a[dq[tail - 1]] >= a[i]) tail--;
        dq[tail++] = i;
        if (dq[head] <= i - k) head++;
        if (i >= k - 1) mins[i - k + 1] = a[dq[head]];
    }
    return mins;
}
```

```python
from collections import deque

def window_min(a, k):
    """mins[i] = mínimo de a[i:i+k]. Θ(n)."""
    dq, mins = deque(), []
    for i, x in enumerate(a):
        while dq and a[dq[-1]] >= x:
            dq.pop()
        dq.append(i)
        if dq[0] <= i - k:
            dq.popleft()
        if i >= k - 1:
            mins.append(a[dq[0]])
    return mins
```

- **`>=` al sacar por detrás**: con iguales, el más reciente vive más y basta con él. Con `>` también es
  correcto, pero la deque guarda repetidos.
- **Un solo `if` para sacar por delante**: la ventana avanza de uno en uno, así que como mucho sale un
  índice por paso.
- **Java**: como cada índice entra una vez, un arreglo de `n` con `head` y `tail` hace de deque sin
  realojar.
- **Ventanas de tamaño variable** (los dos extremos avanzan sin retroceder, `04/02`): la misma deque,
  sacando por delante con un `while` mientras el índice quede fuera.

### De la versión ingenua a la buena

**El problema.** Un camino de `n = 10⁵` casillas con puntos (pueden ser negativos). Se empieza en la
casilla 0 y, desde cada una, se salta a cualquiera de las `k` siguientes; hay que llegar a la última
sumando el máximo de puntos. Con `[5, −2, −9, 1, −5, 6]` y `k = 2`, el máximo es 10 (casillas 0, 1, 3, 5).

**La versión ingenua:**

```java
// O(n · k): para cada casilla, recorre las k anteriores buscando el mejor origen.
static long bestPath(int[] pts, int k) {
    int n = pts.length;
    long[] dp = new long[n];
    dp[0] = pts[0];
    for (int i = 1; i < n; i++) {
        long best = Long.MIN_VALUE;
        for (int j = Math.max(0, i - k); j < i; j++) best = Math.max(best, dp[j]);
        dp[i] = pts[i] + best;
    }
    return dp[n - 1];
}
```

> «El bucle de dentro es el máximo de `dp` sobre una ventana de tamaño `k` que avanza de uno en uno: una
> cola monótona de índices con `dp` decreciente. El mejor origen está siempre delante. Cada casilla entra
> y sale una vez: de `n · k` a `n`.»

**El camino a la buena.** Antes de calcular `dp[i]`, saca por delante el índice que quedó fuera de la
ventana; `dp[i] = pts[i] + dp[frente]`; después saca por detrás los `dp` menores o iguales y mete `i`.
Con el ejemplo, la deque guarda los `dp` `[5, 3]`, `[5, 3, −4]`, `[4]`, `[4, −1]`, `[10]`.

**Cuándo sí**: mínimo o máximo de ventanas que avanzan; programación dinámica con transiciones sobre una
ventana ([`13/05`](../13-dp-avanzada/05-optimizaciones.md)). **Cuándo no**: rangos arbitrarios fuera de orden; ahí una tabla dispersa o un árbol de
segmentos (`09/01`, [`09/03`](../09-consultas-sobre-rangos/03-segment-tree.md)).

> **Veredicto:** la cola monótona es la pila monótona con salida por delante: los que ya no pueden ser
> mínimo salen por detrás, los que salen de la ventana, por delante.

---

## 6. ⏱️ La tabla de costes

| Estructura | Operación | Coste | Lo que la tabla no dice |
|---|---|---|---|
| Pila (`vector`, `ArrayDeque`, `list`) | `push`, `pop`, `top` | `O(1)` amortizado | `Stack` de Java sincroniza cada llamada |
| Cola (`deque`, `ArrayDeque`, `collections.deque`) | `push`, `pop`, `front` | `O(1)` | `list.pop(0)` de Python es `O(n)` |
| Pila monótona | todo el recorrido | `Θ(n)` | Un `while` dentro del `for`, y aun así lineal |
| Cola monótona | todo el recorrido | `Θ(n)` | La ventana tiene que avanzar, no saltar |

---

## 7. 🔎 Señales del enunciado

| Señal | Técnica | Por qué |
|---|---|---|
| Paréntesis, etiquetas, «deshacer», anidamiento | Pila | Lo último que se abrió es lo primero que se cierra |
| «El siguiente mayor», «el anterior menor», «cuántos días hasta» | Pila monótona | Los resueltos no vuelven a ser respuesta |
| «Para cada elemento, el rango donde es el mínimo» | Pila monótona en los dos sentidos | Anterior y siguiente menor delimitan el rango |
| «Máximo / mínimo de cada ventana de tamaño `k`» | Cola monótona | Ventana que avanza |
| DP con `max` sobre las últimas `k` posiciones | Cola monótona | Es un máximo de ventana sobre los estados |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| «La pila monótona es `O(n²)` porque tiene un bucle dentro» | Cada índice entra y sale una vez: `Θ(n)` por el análisis agregado |
| «`Stack` de Java es la pila» | Es una clase heredada de `Vector`, sincronizada; la documentación recomienda `Deque` y `ArrayDeque` |
| «En Python, `list` sirve de cola» | `pop(0)` es `O(n)`; para cola, `collections.deque` |
| «En la pila se guardan los valores» | Casi siempre índices: dan la distancia y el valor |
| «`<` o `<=` da igual» | Decide si la respuesta es el estrictamente mayor o el mayor o igual; con repetidos cambia el resultado |
| «La cola monótona sirve para cualquier rango» | Solo si los extremos avanzan sin retroceder |

---

## 📚 Para profundizar

- **Libro** — Brassard y Bratley, *Fundamentos de algoritmia* (Prentice Hall, 1997), cap. 5: pilas,
  colas y su implementación sobre arreglos. *Lectura troncal.*
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4.ª ed. (Addison-Wesley, 2011), §1.3: *bags*, colas y pilas
  en Java, con la evaluación de expresiones de Dijkstra. *Lectura troncal.*
- **Libro** — Goodrich, Tamassia y Goldwasser, *Data Structures and Algorithms in Java*, 6.ª ed. (Wiley,
  2014), cap. 6: pilas, colas y deques, con el arreglo circular. *Lectura troncal.*
- **Referencia** — cp-algorithms, [*Minimum stack / Minimum queue*](https://cp-algorithms.com/data_structures/stack_queue_modification.html):
  la cola con mínimo hecha con dos pilas.
- **Documentación** — Java, [`ArrayDeque`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/ArrayDeque.html);
  Python, [`collections.deque`](https://docs.python.org/3/library/collections.html#collections.deque).

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre pila, cola y deque, y qué usarías en Java para cada una? 🟢
2. ¿Por qué `list.pop(0)` es una mala cola en Python? 🟢
3. ¿Qué se guarda en la pila monótona, índices o valores, y por qué? 🟢
4. Enuncia el invariante de la pila monótona para «el siguiente mayor». 🟡
5. Demuestra con el análisis agregado que la pila monótona es `Θ(n)`. 🟡
6. ¿Cómo cambia la plantilla para obtener «el anterior menor» en lugar del «siguiente mayor»? 🟡
7. En la cola monótona, ¿por qué se puede descartar un índice cuando llega otro posterior con valor menor o igual? 🟡
8. ¿Qué diferencia hay entre usar `<` y `<=` en la pila monótona con valores repetidos? Da un ejemplo. 🟠
9. Compara `Stack`, `ArrayDeque` y `LinkedList` como pila en Java, y `list` y `deque` en Python. 🟠
10. Calcula el anterior y el siguiente menor de cada barra del histograma `[3, 1, 3, 2, 2]`, y con ellos el mayor rectángulo. 🟠
11. ¿Cómo implementas una cola que dé su mínimo en `O(1)` usando dos pilas? 🟠
12. ¿Cómo construye una pila monótona el árbol cartesiano de un arreglo en `O(n)`, y qué tiene que ver ese árbol con el mínimo de un rango? 🔴
13. ¿Cómo calculas el máximo de cada submatriz `k × k` de una matriz `R × C` combinando colas monótonas, y con qué coste? 🔴

---

## 🧩 Problemas propios

### Etiquetas bien anidadas

**Nivel:** 🟢 · **Formato:** programa completo.

Un documento es una secuencia de etiquetas de apertura `<x>` y cierre `</x>`. Imprime `SI` si están bien
anidadas; si no, `NO` y la posición (1-indexada) de la primera etiqueta que lo impide, o `n + 1` si el
problema es que al final quedan etiquetas abiertas.

- **Entrada.** Una línea con `n`. Una línea con las `n` etiquetas separadas por espacios.
- **Salida.** `SI`, o `NO` y la posición.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; nombres de 1 a 10 letras minúsculas.

```text
Entrada                          Salida
4                                SI
<a> <b> </b> </a>

Entrada                          Salida
4                                NO 3
<a> <b> </a> </b>

Entrada                          Salida
2                                NO 3
<a> <b>
```

**Pista 1:** al ver un cierre, ¿con qué apertura tiene que coincidir?

### Recuento de dominados

**Nivel:** 🟡 · **Formato:** programa completo.

Para cada posición `i`, imprime cuántos elementos **consecutivos** a su derecha son estrictamente
menores que `a[i]`, empezando por `a[i+1]` y parando en el primero que no lo sea.

- **Entrada.** Una línea con `n`. Una línea con los `n` valores.
- **Salida.** `n` enteros separados por espacios.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; `1 ≤ a[i] ≤ 10⁹`.

```text
Entrada            Salida
6                  1 0 3 0 0 0
5 2 9 1 5 6

Entrada            Salida
3                  0 1 0
3 3 1
```

**Pista 1:** ¿dónde para la cuenta de `i`, y qué relación tiene esa posición con «el siguiente mayor»?

### Mínimos con ventana elástica

**Nivel:** 🟠 · **Formato:** programa completo.

Hay un arreglo y `q` consultas `[lᵢ, rᵢ]`, dadas en un orden en el que `lᵢ` y `rᵢ` nunca disminuyen.
Imprime el mínimo de cada consulta.

- **Entrada.** Una línea con `n` y `q`. Una línea con los `n` valores. Después, `q` líneas con `l r`
  (0-indexados, inclusivos).
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `|a[i]| ≤ 10⁹`; `l ≤ r`; `lᵢ ≤ lᵢ₊₁` y `rᵢ ≤ rᵢ₊₁`.

```text
Entrada            Salida
6 4                2
5 2 9 1 5 6        1
0 2                1
1 3                5
1 5
4 5

Entrada            Salida
1 2                -1000000000
-1000000000        -1000000000
0 0
0 0
```

**Pista 1:** si los dos extremos solo avanzan, ¿cuántas veces entra y sale cada índice de la ventana?

---

## 🧩 Práctica externa

> 💡 **Truco.** Antes de escribir la pila monótona, di en voz alta qué guarda la pila y por qué un
> elemento que sale no vuelve a ser respuesta. Si no te sale la frase, pide a una IA que te haga esa
> pregunta, no que te dé el código ([`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md)).

### Núcleo

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Valid Parentheses](https://leetcode.com/problems/valid-parentheses/) | LeetCode | 🟢 | Pila | Al ver un cierre, ¿qué tiene que haber en la cima? |
| [ ] | [Nesting](https://app.codility.com/programmers/lessons/7-stacks_and_queues/nesting/) | Codility | 🟢 | Pila con un contador | Con un solo tipo de paréntesis, ¿necesitas la pila entera? |
| [ ] | [Evaluate Reverse Polish Notation](https://leetcode.com/problems/evaluate-reverse-polish-notation/) | LeetCode | 🟡 | Pila de operandos | Al llegar un operador, ¿dónde están sus dos operandos? |
| [ ] | [Asteroid Collision](https://leetcode.com/problems/asteroid-collision/) | LeetCode | 🟡 | Pila con choques | ¿Qué asteroides pueden chocar con uno que va a la izquierda? |
| [ ] | [Next Greater Element II](https://leetcode.com/problems/next-greater-element-ii/) | LeetCode | 🟡 | Pila monótona circular | ¿Cuántas vueltas al arreglo necesitas para resolver el circular? |
| [ ] | [Remove K Digits](https://leetcode.com/problems/remove-k-digits/) | LeetCode | 🟡 | Pila monótona voraz | ¿Cuándo conviene borrar el dígito anterior al actual? |
| [ ] | [Longest Continuous Subarray With Absolute Diff Less Than or Equal to Limit](https://leetcode.com/problems/longest-continuous-subarray-with-absolute-diff-less-than-or-equal-to-limit/) | LeetCode | 🟡 | Ventana con dos colas monótonas | ¿Qué dos valores de la ventana necesitas conocer en todo momento? |

### Ampliación

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | [Car Fleet](https://leetcode.com/problems/car-fleet/) | LeetCode | 🟡 | Ordenar y pila de tiempos | Ordenados por posición, ¿cuándo alcanza un coche a la flota de delante? |
| [ ] | [132 Pattern](https://leetcode.com/problems/132-pattern/) | LeetCode | 🟠 | Pila monótona de derecha a izquierda | Fijado el «3», ¿cuál es el mejor «2» a su derecha? |
| [ ] | [Trapping Rain Water](https://leetcode.com/problems/trapping-rain-water/) | LeetCode | 🟠 | Pila monótona o dos punteros | ¿Qué determina el agua sobre una posición? |
| [ ] | [Maximal Rectangle](https://leetcode.com/problems/maximal-rectangle/) | LeetCode | 🔴 | Histograma por filas | Fila a fila, ¿qué histograma se forma? |

### Por curiosidad

| ✔ | Problema | Plataforma | Nivel | Patrón | Pista 1 |
|---|---|---|---|---|---|
| [ ] | 💀 [Shortest Subarray with Sum at Least K](https://leetcode.com/problems/shortest-subarray-with-sum-at-least-k/) | LeetCode | 🔴 | Cola monótona sobre prefijos | Con negativos, ¿qué prefijos anteriores pueden seguir siendo útiles? |
| [ ] | 💀 [Poisonous Plants](https://www.hackerrank.com/challenges/poisonous-plants/problem) | HackerRank | 🔴 | Pila con el día de muerte | ¿De qué depende el día en que muere cada planta? |

---

## ✅ Criterio de dominio

- Escribir la pila monótona y la cola monótona sin mirar, con su invariante.
- Explicar por qué son lineales con el análisis agregado.
- Elegir la implementación correcta de pila y cola en C++, Java y Python, y justificarla.
- Resolver Remove K Digits y Longest Continuous Subarray sin pista 2.

---

**Anterior:** — · **Siguiente:** [`06/02` — Listas enlazadas](02-listas-enlazadas.md) · **Relacionado:**
[`02/03` — Análisis amortizado](../02-analisis/03-analisis-amortizado.md); [`13/05` — Optimizaciones de DP](../13-dp-avanzada/05-optimizaciones.md).
