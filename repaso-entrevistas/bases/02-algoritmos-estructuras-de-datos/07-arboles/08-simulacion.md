# 08 — Simulación

> El examen del bloque `07`: preguntas que cruzan recorridos, árboles de búsqueda balanceados y
> aleatorizados, *tries*, LCA, técnicas sobre árboles y árboles dinámicos; cuatro problemas propios
> cronometrados que no dicen de qué capítulo son, y seis problemas externos que no aparecen antes en el
> bloque. Las respuestas y las pistas 2 y 3 están en el [solucionario](09-respuestas.md#08--simulación).
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [Método](#-método) · [Preguntas](#-preguntas) · [Problemas propios](#-problemas-propios) · [Práctica externa](#-práctica-externa) · [Frases](#-las-frases-que-hay-que-tener-listas)

---

## 🧭 Método

- **Con cronómetro.** Dos minutos por pregunta; 30 minutos para cada uno de los dos primeros problemas
  y 20 para los otros dos.
- **En voz alta.** Antes de cada problema, di si el árbol es fijo o cambia, y si la pregunta es sobre
  subárboles, caminos o todo el árbol: es lo que decide la técnica en este bloque.
- **Tecleando de verdad**, con un *stress test* contra la fuerza bruta en los dos primeros ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).
- **Solo después, el solucionario.**

---

## 🧠 Preguntas

### Recorridos y estructura

**S1.** ¿Cuántas aristas tiene un árbol de `n` nodos, y qué propiedad de los caminos lo caracteriza? 🟢

**S2.** ¿Por qué el diámetro se calcula con dos recorridos? 🟡

**S3.** ¿Qué tramo ocupa un subárbol en el recorrido con tiempos de entrada y salida? 🟢

### Árboles de búsqueda

**S4.** ¿Qué recorrido de un BST da las claves ordenadas? 🟢

**S5.** ¿Qué garantiza un AVL y qué un rojo-negro sobre la altura? 🟡

**S6.** ¿Por qué un *treap* es balanceado en esperanza para cualquier orden de inserción? 🟡

### *Tries*

**S7.** ¿Cuánto cuesta contar las palabras con un prefijo en un *trie*? 🟢

**S8.** ¿Por qué el voraz bit a bit da el XOR máximo? 🟡

### LCA y técnicas

**S9.** ¿Qué fórmula da la distancia entre dos nodos con el LCA? 🟢

**S10.** ¿Cuándo usarías *rerooting* y cuándo *small-to-large*? 🟡

**S11.** ¿Cuál es la profundidad de la descomposición en centroides, y por qué? 🟡

### Las que descolocan

**S12.** Tu DFS recursivo en Java da `StackOverflowError` en el caso 12 y pasa los demás. ¿Qué ha pasado y qué cambias? 🟠

**S13.** Usas `std::lower_bound(s.begin(), s.end(), x)` sobre un `std::set` y da TLE. ¿Por qué? 🟠

**S14.** «Un BST es `O(log n)`.» ¿Qué le respondes a un entrevistador? 🟠

**S15.** Te piden un mapa ordenado en Python, sin bibliotecas externas. ¿Qué haces? 🟠

**S16.** El enunciado borra aristas de un bosque y pregunta si dos nodos están conectados. ¿Qué preguntas antes de elegir estructura? 🟠

**S17.** Demuestra que el nodo más lejano de cualquier nodo es extremo de un diámetro. 🔴

**S18.** Demuestra que en *small-to-large* cada elemento se mueve como mucho `log₂ n` veces. 🔴

---

## 🧩 Problemas propios

No dicen de qué capítulo son. Cada uno tiene una línea **Fuerza** que dice qué decisión obliga a tomar.

### Punto de encuentro

**Nivel:** 🟠 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** reducir una pregunta sobre tres nodos a varias de LCA.

Una red de `n` pueblos sin ciclos, con caminos de longitud 1. Para cada consulta `a b c`, tres amigos
viven en `a`, `b` y `c` y quieren reunirse en un pueblo minimizando la suma de lo que caminan. Imprime el
pueblo de reunión y la suma.

- **Entrada.** Una línea con `n` y `q`. Después, `n − 1` aristas. Después, `q` líneas con `a b c`.
- **Salida.** `q` líneas con dos enteros.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; el árbol puede ser una cadena.

```text
Entrada            Salida
7 3                2 6
1 2                5 3
1 3                6 0
2 4
2 5
3 6
5 7
4 7 6
4 5 7
6 6 6

Entrada            Salida
4 1                1 3
1 2
2 3
3 4
4 1 1
```

**Pista 1:** el punto óptimo está en los tres caminos entre pares de amigos; ¿qué nodos especiales hay en
esos caminos?

### Contraseñas fuertes

**Nivel:** 🟡 · **Tiempo:** 30 minutos · **Formato:** programa completo.

**Fuerza:** evitar comparar cada consulta con todas las claves.

Un sistema guarda `n` claves numéricas. La «fuerza» de una contraseña `x` es el mayor `x ⊕ k` sobre las
claves `k` guardadas. Responde `q` consultas.

- **Entrada.** Una línea con `n` y `q`. Una línea con las `n` claves. Después, `q` líneas con `x`.
- **Salida.** `q` líneas.
- **Restricciones.** `1 ≤ n, q ≤ 2·10⁵`; `0 ≤ k, x < 2³⁰`.

```text
Entrada            Salida
6 3                15
5 2 9 1 5 6        9
9                  14
0
15

Entrada            Salida
1 2                0
0                  1073741823
0
1073741823
```

**Pista 1:** ¿qué bit del resultado conviene asegurar primero?

### Ruta del parque

**Nivel:** 🟡 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** no lanzar un recorrido desde cada nodo.

Un parque tiene `n` miradores unidos por senderos sin ciclos, todos de la misma longitud. Imprime el mayor
número de senderos entre dos miradores.

- **Entrada.** Una línea con `n`. Después, `n − 1` senderos.
- **Salida.** Un entero.
- **Restricciones.** `2 ≤ n ≤ 2·10⁵`.

```text
Entrada            Salida
7                  5
1 2
1 3
2 4
2 5
3 6
5 7

Entrada            Salida
2                  1
1 2
```

**Pista 1:** si empiezas en un mirador cualquiera, ¿qué sabes del más lejano que encuentras?

### Mediana del árbol

**Nivel:** 🟢 · **Tiempo:** 20 minutos · **Formato:** programa completo.

**Fuerza:** ver que la estructura ya da el orden.

Un BST de `n` nodos con claves distintas viene dado por la clave y los hijos de cada nodo (`0` si no hay);
la raíz es el nodo 1. Imprime la clave que ocupa la posición `⌊(n − 1)/2⌋` (0-indexada) en orden creciente.

- **Entrada.** Una línea con `n`. Después, `n` líneas con `clave izquierdo derecho`.
- **Salida.** Un entero.
- **Restricciones.** `1 ≤ n ≤ 2·10⁵`; el árbol puede ser una cadena.

```text
Entrada            Salida
5                  5
5 2 3
2 4 0
9 5 0
1 0 0
6 0 0

Entrada            Salida
3                  2
3 2 0
2 3 0
1 0 0
```

**Pista 1:** ¿qué recorrido de un BST da las claves en orden?

---

## 🧩 Práctica externa

Ninguno aparece antes en el bloque. La columna «Patrón» está oculta a propósito.

| ✔ | Problema | Plataforma | Nivel | Pista 1 |
|---|---|---|---|---|
| [ ] | [Same Tree](https://leetcode.com/problems/same-tree/) | LeetCode | 🟢 | ¿Qué tienes que comparar en cada par de nodos, y en qué orden? |
| [ ] | [Invert Binary Tree](https://leetcode.com/problems/invert-binary-tree/) | LeetCode | 🟢 | ¿Qué cambio local, aplicado a todos los nodos, da el espejo? |
| [ ] | [Diameter of Binary Tree](https://leetcode.com/problems/diameter-of-binary-tree/) | LeetCode | 🟢 | Si el camino más largo pasa por un nodo como punto más alto, ¿qué mide? |
| [ ] | [Balanced Binary Tree](https://leetcode.com/problems/balanced-binary-tree/) | LeetCode | 🟢 | ¿Puedes calcular las alturas y comprobar el equilibrio en el mismo recorrido? |
| [ ] | [Path Sum III](https://leetcode.com/problems/path-sum-iii/) | LeetCode | 🟡 | En el camino de la raíz al nodo actual, ¿qué técnica de secuencias cuenta tramos con suma dada? |
| [ ] | [Tree Distances II](https://cses.fi/problemset/task/1133) | CSES | 🟠 | Si conoces la suma desde un nodo, ¿cuánto cambia en su vecino? |

---

## ✅ Las frases que hay que tener listas

> «Es un árbol: el camino entre dos nodos es único, así que las distancias salen de un recorrido y la
> distancia entre `u` y `v` es `prof(u) + prof(v) − 2·prof(LCA)`.»

> «Un BST es `O(h)`; balanceado, `O(log n)`. En C++ y Java uso `std::map` o `TreeMap`, que son
> rojo-negros.»

> «Con `n` hasta `2·10⁵` en Java o Python, recorro el árbol de forma iterativa: la recursión puede tener
> profundidad `n`.»

---

**Anterior:** [`07/07` — Árboles dinámicos](07-arboles-dinamicos.md) · **Siguiente:**
[`07/09` — Respuestas](09-respuestas.md) · **Relacionado:** [`07/05` — LCA](05-lca.md).
