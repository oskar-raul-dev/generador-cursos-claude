# Respuestas — bloque 07: Árboles

> Solucionario del bloque `07`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--árboles-representación-y-recorridos) · [02](#02--bst-y-árboles-balanceados) · [03](#03--árboles-aleatorizados-y-autoajustables) · [04](#04--tries) · [05](#05--lca) · [06](#06--técnicas-sobre-árboles) · [07](#07--árboles-dinámicos) · [08](#08--simulación)

---

# 01 — Árboles: representación y recorridos

**01 → 1.** Da tres definiciones equivalentes de árbol con `n` vértices. 🟢

⏱️ **30 segundos.** Conexo y sin ciclos; conexo con `n − 1` aristas; sin ciclos con `n − 1` aristas. Equivalente: entre cada par de vértices hay exactamente un camino.

🗣️ **2 minutos.** Cualquiera de las dos primeras propiedades (conexo, sin ciclos, `n − 1` aristas) implica la tercera. Lo útil en un enunciado: si te dicen «`n` nodos, `n − 1` aristas, conexo», es un árbol, y entonces el camino entre dos nodos es único.

🔬 **El detalle.** Un bosque (sin ciclos, no necesariamente conexo) con `c` componentes tiene `n − c` aristas.

**01 → 2.** ¿Qué diferencia hay entre profundidad de un nodo y altura del árbol? 🟢

⏱️ **30 segundos.** La profundidad de un nodo es su distancia a la raíz; la altura del árbol es la mayor profundidad. En T, 7 tiene profundidad 3 y la altura es 3.

🗣️ **2 minutos.** La altura depende de la raíz elegida; la profundidad, también. La altura de un **nodo** suele definirse como la distancia a su hoja más profunda, y la del árbol es la altura de la raíz.

🔬 **El detalle.** Algunos textos cuentan nodos en lugar de aristas (la altura de un árbol de un solo nodo sería 1); hay que mirar la convención del enunciado.

**01 → 3.** Escribe el preorden, el postorden y el recorrido por niveles de T. 🟢

⏱️ **30 segundos.** Preorden `1 2 4 5 7 3 6`; postorden `4 7 5 2 6 3 1`; por niveles `1 | 2 3 | 4 5 6 | 7`.

🗣️ **2 minutos.** Preorden: el nodo, luego sus subárboles en orden. Postorden: los subárboles y después el nodo. Por niveles: un BFS desde la raíz, que agrupa por profundidad.

🔬 **El detalle.** Con los hijos en otro orden, el preorden y el postorden cambian; el recorrido por niveles cambia solo dentro de cada nivel.

**01 → 4.** ¿Por qué en un árbol las distancias desde un nodo salen con un BFS (o un DFS) y no hace falta Dijkstra, aunque haya pesos? 🟡

⏱️ **30 segundos.** Porque entre dos nodos hay un único camino: la distancia es la suma de sus aristas, y cualquier recorrido que salga del origen la acumula correctamente al llegar por primera vez.

🗣️ **2 minutos.** Dijkstra resuelve la elección entre caminos alternativos. En un árbol no hay alternativas: el primer (y único) camino por el que se llega a un nodo es el bueno. Un DFS o BFS que sume pesos da las distancias en `Θ(n)`, incluso con pesos negativos.

🔬 **El detalle.** Lo que sí falla con pesos negativos es el método de los dos recorridos para el diámetro, no el cálculo de distancias.

**01 → 5.** ¿Cómo obtienes el postorden a partir de un preorden iterativo? 🟡

⏱️ **30 segundos.** Recorriendo el preorden al revés: cada nodo aparece después de todos sus descendientes, que es lo que necesita un cálculo de postorden.

🗣️ **2 minutos.** En el preorden, todo descendiente de `v` va después de `v`. Al revés, va antes. Eso basta para acumular de hijos a padres: tamaños de subárbol, sumas, alturas. No es exactamente el postorden (el orden entre hermanos sale invertido), pero cumple la misma propiedad.

🔬 **El detalle.** Si se necesita el postorden exacto, hay que apilar los hijos en orden inverso y además invertir el resultado, o usar una pila con estado.

**01 → 6.** ¿Por qué el recorrido recursivo puede fallar en Java y en Python con `n = 10⁶`, y qué haces? 🟡

⏱️ **30 segundos.** Porque la profundidad de la recursión es la altura del árbol, que en una cadena es `n`: `10⁶` marcos de pila desbordan la pila por defecto de Java (`StackOverflowError`) y superan el límite de Python (1000 por defecto). Se escribe iterativo.

🗣️ **2 minutos.** En C++ la pila suele ser de 8 MB en Linux y muchos jueces la amplían, pero no hay garantía. En Java se puede lanzar el cálculo en un `Thread` con una pila grande; en Python, subir `sys.setrecursionlimit` no evita que el proceso se quede sin pila real. La solución robusta es el preorden iterativo con una pila explícita.

🔬 **El detalle.** [`01/03`](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md) y [`03/04`](../03-biblioteca-estandar/04-python-para-competir.md) cuentan los trucos de cada lenguaje para la pila; en árboles, el iterativo es la respuesta general.

**01 → 7.** ¿Qué tramo ocupa el subárbol de `v` con los tiempos de entrada y salida, y por qué es contiguo? 🟡

⏱️ **30 segundos.** `[tin[v], tout[v]]`, con `tout[v] = tin[v] + size[v] − 1`. Es contiguo porque el preorden, al entrar en `v`, visita todo su subárbol antes de salir a un nodo que no es descendiente.

🗣️ **2 minutos.** Cuando el recorrido entra en `v`, recorre sus hijos y todos sus descendientes; no vuelve a ningún nodo de fuera hasta acabar. Así que los descendientes ocupan las posiciones inmediatamente siguientes a `v`. `u` es ancestro de `v` si y solo si `tin[u] ≤ tin[v] ≤ tout[u]`.

🔬 **El detalle.** Con un arreglo indexado por `tin`, las operaciones sobre subárboles son operaciones sobre tramos (Fenwick, segment tree).

**01 → 8.** Demuestra que el nodo más lejano de cualquier nodo es extremo de un diámetro. 🟠

⏱️ **30 segundos.** Sea `a–b` un diámetro y `u` el más lejano de `s`. Si el camino `s–u` toca `a–b`, el camino de `u` al extremo opuesto mide al menos `D`; si no lo toca, se construye un camino más largo que `D`, contradicción.

🗣️ **2 minutos.** Caso 1: sea `x` el primer vértice de `s–u` en `a–b`. Como `u` es el más lejano de `s`, `d(x, u) ≥ d(x, a)` y `d(x, u) ≥ d(x, b)`. Si el camino `x–u` se va hacia el lado de `a`, el de `b` a `u` pasa por `x` y mide `d(b, x) + d(x, u) ≥ d(b, x) + d(x, a) = D`. Caso 2: con `x` el vértice de `a–b` más cercano a `s` y `w` el punto donde se separan `s–u` y `s–x`, `d(w, u) ≥ d(w, x) + d(x, b)`, y el camino `a–x–w–u` mide más que `D`.

🔬 **El detalle.** La prueba usa que las distancias se suman a lo largo de caminos y que los pesos no son negativos; con negativos, la desigualdad `d(w, u) ≥ …` no lleva a un camino más largo.

**01 → 9.** Da un árbol con pesos negativos en el que los dos recorridos no dan el diámetro. 🟠

⏱️ **30 segundos.** Cadena `1 −(1)− 2 −(−10)− 3 −(5)− 4`. El diámetro (mayor suma) es 5, entre 3 y 4. Desde 1, el más lejano es 2 (distancia 1); desde 2, el más lejano es 1: el método da 1.

🗣️ **2 minutos.** Con pesos negativos, «el más lejano» desde un nodo puede quedar detrás de una arista negativa que esconde la parte buena del árbol. El teorema necesita que alargar un camino no reduzca su longitud.

🔬 **El detalle.** La alternativa es la DP de la pregunta 13, que funciona con cualquier signo.

**01 → 10.** Compara cómo representarías un árbol de `2·10⁵` nodos en C++, Java y Python para un juez, y por qué. 🟠

⏱️ **30 segundos.** C++: `vector<vector<int>>`. Java: arreglos `head[]`, `next[]`, `to[]` (estrella hacia delante) en lugar de `List<Integer>[]`. Python: lista de listas, con lectura rápida de toda la entrada.

🗣️ **2 minutos.** En C++, el vector de vectores es simple y suficientemente rápido. En Java, `ArrayList<Integer>` crea un objeto por arista y fragmenta la memoria: con `2·10⁵` nodos funciona, pero los arreglos planos son más rápidos y no presionan al recolector. En Python, la lista de listas es lo natural; el cuello de botella es la lectura y el recorrido, que debe ser iterativo.

🔬 **El detalle.** La representación CSR (aristas ordenadas por origen y un arreglo de inicios) es la más compacta y la de mejor localidad en los tres lenguajes ([`04/05`](../04-secuencias/05-matrices.md), [`14/01`](../14-grafos-recorridos/01-representaciones.md)).

**01 → 11.** ¿Por qué el preorden y el postorden juntos no siempre determinan un árbol binario? Da dos árboles distintos con los mismos dos recorridos. 🟠

⏱️ **30 segundos.** Porque, si un nodo tiene un solo hijo, ni el preorden ni el postorden dicen si es izquierdo o derecho. Ejemplo: la raíz 1 con un único hijo 2, a la izquierda o a la derecha: los dos árboles tienen preorden `1 2` y postorden `2 1`.

🗣️ **2 minutos.** El inorden sí distingue: `2 1` si es izquierdo, `1 2` si es derecho. Por eso preorden + inorden (o postorden + inorden) determinan un árbol binario con valores distintos, y preorden + postorden solo lo determinan si todo nodo interno tiene dos hijos (árbol lleno).

🔬 **El detalle.** Con valores repetidos, ni siquiera preorden + inorden basta en general.

**01 → 12.** ¿Cómo encuentras el centro del árbol (el nodo que minimiza la mayor distancia) a partir del diámetro? Demuestra que es correcto. 🔴

⏱️ **30 segundos.** El centro es el vértice (o los dos vértices) a mitad del camino del diámetro: a distancia `⌈D/2⌉` de un extremo. Su excentricidad es `⌈D/2⌉`, y ningún nodo puede tener menos.

🗣️ **2 minutos.** Por el teorema, la excentricidad de cualquier `v` (su mayor distancia) se alcanza en uno de los dos extremos `u`, `w` del diámetro: `ecc(v) = max(d(v, u), d(v, w))`. Como `d(v, u) + d(v, w) ≥ D`, `ecc(v) ≥ ⌈D/2⌉`. El punto medio del camino `u–w` alcanza esa cota. Con `D` impar hay dos centros adyacentes.

🔬 **El detalle.** Se recupera guardando los padres en el segundo BFS y subiendo `⌊D/2⌋` pasos desde el extremo final.

**01 → 13.** ¿Cómo calculas el diámetro en `O(n)` cuando hay pesos negativos, y por qué ahí falla el método de los dos recorridos? 🔴

⏱️ **30 segundos.** Con una DP en postorden: `down[v]` es el mejor camino que baja desde `v` (`max(0, down[c] + w)` sobre los hijos), y el diámetro es el máximo, sobre todos los `v`, de la suma de sus dos mejores ramas. Los dos recorridos fallan porque el teorema necesita pesos no negativos.

🗣️ **2 minutos.** Todo camino del árbol tiene un vértice más alto `v` (el más cercano a la raíz); el camino baja desde `v` por como mucho dos hijos distintos. Para cada `v`, se toman las dos mejores ramas `down[c] + w(v, c)` (o 0 si conviene no bajar) y se suman. `Θ(n)` con el preorden al revés.

🔬 **El detalle.** Es la DP en árboles de [`07/06`](06-tecnicas-sobre-arboles.md) y [`13/03`](../13-dp-avanzada/03-dp-en-arboles-y-dag.md); con «0 si conviene no bajar», el camino puede ser un solo vértice (longitud 0). Si el enunciado exige al menos una arista, se quita ese 0.

**01 → Problema: Jefes y equipos.**

- **Pista 2 — patrón:** **tamaños de subárbol** sin recursión.
- **Pista 3 — diseño:** como el jefe de `i` es menor que `i`, recorre `i` de `n` a 2 sumando `size[i]` a `size[jefe[i]]`, con `size` inicializado a 1. Es el preorden al revés gratis.

**01 → Problema: El cable más largo.**

- **Pista 2 — patrón:** **diámetro con pesos positivos**: dos recorridos acumulando pesos.
- **Pista 3 — diseño:** un DFS iterativo (o BFS) que acumule distancias en 64 bits desde el nodo 1; desde el más lejano, otro; la mayor distancia del segundo es la respuesta.

**01 → Problema: ¿Es ancestro?.**

- **Pista 2 — patrón:** **tiempos de entrada y salida**.
- **Pista 3 — diseño:** preorden iterativo desde 1 para `tin` y tamaños de subárbol para `tout`; `u` es ancestro de `v` si `tin[u] ≤ tin[v] ≤ tout[u]`.

**01 → Problema: Maximum Depth of Binary Tree.**

- **Pista 2 — patrón:** **postorden**: altura = 1 + máximo de las de los hijos.
- **Pista 3 — diseño:** recursión con caso base `null → 0`; o un BFS que cuente niveles.

**01 → Problema: Minimum Depth of Binary Tree.**

- **Pista 2 — patrón:** **por niveles**, parando en la primera hoja.
- **Pista 3 — diseño:** BFS que devuelve la profundidad de la primera hoja (sin hijos) que saca; ojo: un nodo con un solo hijo no es hoja.

**01 → Problema: Symmetric Tree.**

- **Pista 2 — patrón:** **dos recorridos en espejo**.
- **Pista 3 — diseño:** compara `(izq.left, der.right)` y `(izq.right, der.left)` recursivamente, o con una cola de pares.

**01 → Problema: Binary Tree Level Order Traversal.**

- **Pista 2 — patrón:** **por niveles** con el tamaño de la cola.
- **Pista 3 — diseño:** al empezar cada nivel, el tamaño de la cola es el número de nodos de ese nivel; saca exactamente esos y añade sus hijos.

**01 → Problema: Binary Tree Right Side View.**

- **Pista 2 — patrón:** **por niveles**: el último de cada nivel.
- **Pista 3 — diseño:** el BFS por niveles del problema anterior, guardando el último nodo sacado de cada nivel; o un DFS que visite primero la derecha y anote el primer nodo de cada profundidad.

**01 → Problema: Construct Binary Tree from Preorder and Inorder Traversal.**

- **Pista 2 — patrón:** **reconstrucción recursiva** partiendo el inorden por la raíz.
- **Pista 3 — diseño:** el primer elemento del preorden es la raíz; su posición en el inorden (con un mapa de valor a índice) separa los dos subárboles y sus tamaños; recursión con índices, sin copiar subarreglos.

**01 → Problema: Binary Tree Zigzag Level Order Traversal.**

- **Pista 2 — patrón:** **por niveles** con alternancia al guardar.
- **Pista 3 — diseño:** el BFS por niveles normal; invierte la lista de los niveles impares (o inserta por delante con una deque).

**01 → Problema: All Nodes Distance K in Binary Tree.**

- **Pista 2 — patrón:** **árbol como grafo no dirigido**.
- **Pista 3 — diseño:** guarda el padre de cada nodo con un recorrido; después, BFS desde el objetivo moviéndote a hijos y padre hasta la distancia `k`.

**01 → Problema: Subordinates.**

- **Pista 2 — patrón:** **tamaños de subárbol**.
- **Pista 3 — diseño:** construye los hijos a partir de los jefes; preorden iterativo y acumulación al revés; la respuesta de cada uno es su tamaño menos 1.

**01 → Problema: Tree Distances I.**

- **Pista 2 — patrón:** **extremos del diámetro**.
- **Pista 3 — diseño:** encuentra los extremos `u` y `w` del diámetro con dos BFS; la respuesta de cada nodo es `max(d(v, u), d(v, w))`, con un tercer BFS.

**01 → Problema: Serialize and Deserialize Binary Tree.**

- **Pista 2 — patrón:** **preorden con marcas de nulo**.
- **Pista 3 — diseño:** serializa en preorden escribiendo un símbolo para cada hijo vacío; al deserializar, lee en el mismo orden con un índice compartido: cada símbolo nulo cierra una rama.

---

# 02 — BST y árboles balanceados

**02 → 1.** ¿Qué es la propiedad de BST, y qué recorrido da las claves en orden? 🟢

⏱️ **30 segundos.** En todo nodo, las claves del subárbol izquierdo son menores y las del derecho, mayores. El inorden da las claves en orden creciente.

🗣️ **2 minutos.** La propiedad es sobre subárboles enteros, no solo sobre los hijos: por eso el inorden (izquierdo, nodo, derecho) sale ordenado. Es la base de todas las operaciones: en cada nodo se sabe a qué lado está una clave.

🔬 **El detalle.** Con claves repetidas hay que fijar una convención (repetidos a la derecha, o un contador por nodo); `std::multiset` los admite, `std::set` no.

**02 → 2.** ¿Qué estructura hay debajo de `std::map` y de `TreeMap`? 🟢

⏱️ **30 segundos.** Un árbol rojo-negro en los dos: libstdc++ y libc++ para `std::map`, y la propia documentación de `TreeMap` lo dice.

🗣️ **2 minutos.** Por eso las dos garantizan `O(log n)` en el peor caso por operación, y ofrecen consultas de orden (`lower_bound`, `ceiling`, `floor`, recorridos en orden y por rangos).

🔬 **El detalle.** El estándar de C++ no exige rojo-negro, solo las complejidades; en la práctica, todas las implementaciones lo usan.

**02 → 3.** ¿Qué hace una rotación, y por qué no rompe la propiedad de BST? 🟢

⏱️ **30 segundos.** Sube un hijo al lugar de su padre y baja el padre, reasignando un subárbol. No rompe el orden porque el inorden antes y después es el mismo: `A < x < B < y < C`.

🗣️ **2 minutos.** En la rotación a la derecha sobre `y` con hijo izquierdo `x`, el subárbol `B` (entre `x` e `y`) pasa de ser hijo derecho de `x` a hijo izquierdo de `y`. Solo cambian tres punteros, `O(1)`, y la altura de los dos nodos implicados.

🔬 **El detalle.** Las rotaciones son la única herramienta de reestructuración de AVL, rojo-negro, *treap* y *splay*: lo que cambia entre ellos es cuándo rotar.

**02 → 4.** ¿Cuánto cuesta buscar en un BST sin balancear en el peor caso, y con qué entrada se alcanza? 🟡

⏱️ **30 segundos.** `O(n)`: con claves insertadas en orden (creciente o decreciente), el árbol es una cadena de altura `n − 1`.

🗣️ **2 minutos.** Cada inserción va al extremo de la cadena. Buscar la última clave recorre todos los nodos. Con `n = 10⁵` inserciones ordenadas, construir el árbol cuesta `Θ(n²)`. Con un orden aleatorio, la altura esperada es `O(log n)` (asintóticamente, unas `4,31 ln n`), pero no se puede contar con que los datos lleguen al azar.

🔬 **El detalle.** La recursión de inserción con altura `10⁵` además desborda la pila.

**02 → 5.** ¿Cómo se borra un nodo con dos hijos en un BST? 🟡

⏱️ **30 segundos.** Se sustituye su clave por la de su sucesor (el mínimo del subárbol derecho) y se borra el sucesor, que no tiene hijo izquierdo.

🗣️ **2 minutos.** El sucesor es la menor clave mayor que la borrada: ponerla en su lugar mantiene el orden. El sucesor tiene como mucho un hijo (el derecho), así que borrarlo es el caso fácil: se enlaza su hijo con su padre. Con el predecesor (máximo del izquierdo) funciona igual.

🔬 **El detalle.** En un árbol balanceado, el borrado sigue con la reparación del balanceo desde el padre del nodo que se quitó de verdad.

**02 → 6.** ¿Por qué validar un BST comparando cada nodo con sus hijos es incorrecto? Da un contraejemplo. 🟡

⏱️ **30 segundos.** Porque la propiedad afecta a todos los ancestros, no solo al padre. En `5(2(1, 6), 9)`, cada nodo cumple con sus hijos, pero el 6 está a la izquierda del 5 y es mayor.

🗣️ **2 minutos.** La comprobación correcta pasa hacia abajo el intervalo permitido: a la izquierda de `v`, las claves deben ser menores que `v` además de cumplir lo que ya exigían los ancestros. Alternativa: el inorden debe ser estrictamente creciente, comprobado con el valor anterior.

🔬 **El detalle.** Si el intervalo usa `int` y las claves llegan a `Integer.MIN_VALUE` o `MAX_VALUE`, hay que usar `long` o límites nulos.

**02 → 7.** ¿Cuántas rotaciones hace como mucho una inserción en un AVL, y en qué casos hacen falta dos? 🟠

⏱️ **30 segundos.** Como mucho dos (una rotación doble) por inserción. Hacen falta dos en los casos cruzados: el nodo nuevo está en el subárbol derecho del hijo izquierdo (izquierda-derecha) o al revés.

🗣️ **2 minutos.** En los casos rectos (izquierda-izquierda, derecha-derecha), una rotación sobre el nodo desequilibrado basta. En los cruzados, una sola rotación deja el árbol desequilibrado hacia el otro lado; primero se rota el hijo para convertirlo en el caso recto. Tras esa reparación, la altura del subárbol vuelve a la de antes de insertar y no hay que seguir subiendo.

🔬 **El detalle.** El borrado puede necesitar rotaciones en `O(log n)` niveles, porque la altura sí puede bajar y propagar el desequilibrio.

**02 → 8.** Demuestra que la altura de un AVL es `O(log n)` con la recurrencia de Fibonacci. 🟠

⏱️ **30 segundos.** El AVL mínimo de altura `h` tiene `N(h) = 1 + N(h−1) + N(h−2)` nodos, que es `F(h+3) − 1`; como Fibonacci crece como `φʰ`, `h = O(log n)`, en concreto `h < 1,45 log₂(n + 2)`.

🗣️ **2 minutos.** Para minimizar nodos con altura `h`, un subárbol tiene altura `h − 1` (para alcanzar `h`) y el otro la mínima permitida, `h − 2`. Con `N(0) = 1`, `N(1) = 2`, por inducción `N(h) = F(h + 3) − 1`. Como `F(k) ≥ φ^{k−2}`, `n ≥ N(h) ≥ φ^{h+1} − 1`, y despejando `h ≤ log_φ(n + 1) − 1 ≈ 1,44 log₂(n + 1)`.

🔬 **El detalle.** Esos árboles mínimos se llaman árboles de Fibonacci; son el peor caso del AVL.

**02 → 9.** Demuestra que la altura de un rojo-negro es como mucho `2 log₂(n + 1)`. 🟠

⏱️ **30 segundos.** Un subárbol con altura negra `bh` tiene al menos `2^{bh} − 1` nodos internos, y como no hay dos rojos seguidos, `bh ≥ h/2`. Entonces `n ≥ 2^{h/2} − 1`, es decir, `h ≤ 2 log₂(n + 1)`.

🗣️ **2 minutos.** La primera afirmación, por inducción en la altura: un nodo con altura negra `bh` tiene hijos con altura negra `≥ bh − 1`, cada uno con `≥ 2^{bh−1} − 1` nodos; sumando los dos y el nodo, `≥ 2^{bh} − 1`. La segunda: en el camino de la raíz a una hoja, de longitud `h`, no hay dos rojos consecutivos, así que al menos la mitad son negros.

🔬 **El detalle.** CLRS, 3.ª ed., lema 13.1. La cota `2 log₂ n` frente a `1,44 log₂ n` del AVL es el precio de rotar menos.

**02 → 10.** Explica la correspondencia entre un rojo-negro y un árbol (2,4). 🟠

⏱️ **30 segundos.** Cada nodo negro, junto con sus hijos rojos, forma un nodo (2,4): sin hijos rojos, un 2-nodo; con uno, un 3-nodo; con dos, un 4-nodo. La altura negra del rojo-negro es la altura del (2,4).

🗣️ **2 minutos.** Como en el (2,4) todas las hojas están a la misma profundidad, en el rojo-negro todos los caminos tienen el mismo número de negros. La regla «no hay dos rojos seguidos» es la que impide nodos de más de 3 claves. Insertar un rojo es añadir una clave a un nodo (2,4); el caso del tío rojo (recolorear) es el *split* de un 4-nodo lleno.

🔬 **El detalle.** Sedgewick usa la variante *left-leaning*, que corresponde a árboles 2-3 y simplifica mucho el código.

**02 → 11.** Compara qué ofrecen C++, Java y Python para un mapa ordenado, y qué haces en Python si lo necesitas. 🟠

⏱️ **30 segundos.** C++: `std::map`/`std::set`/`std::multiset` (y el `tree` de *policy-based* con orden estadístico). Java: `TreeMap`/`TreeSet`. Python: nada en la biblioteca estándar.

🗣️ **2 minutos.** En Python se sustituye según el caso: arreglo ordenado con `bisect` si las inserciones son pocas (`insort` es `O(n)`); montículo con borrado perezoso si solo hace falta el mínimo; Fenwick sobre valores comprimidos si hace falta contar o el `k`-ésimo; o un *treap* propio. Fuera de concursos, la biblioteca `sortedcontainers` es lo habitual, pero no está en los jueces.

🔬 **El detalle.** [`03/02`](../03-biblioteca-estandar/02-cpp-algoritmos-ranges-y-pbds.md) (*policy-based*) y `03/04` (Python) cuentan los detalles.

**02 → 12.** ¿Por qué los índices de las bases de datos son árboles B+ y no rojo-negros? Calcula la altura para `10⁹` claves con `t = 500`. 🔴

⏱️ **30 segundos.** Porque minimizan los accesos a disco: un nodo es una página con cientos de claves, y la altura es `log_t n`. Con `t = 500` y `10⁹` claves, `h ≤ log₅₀₀(5·10⁸) ≈ 3,2`: unos 4 niveles, frente a unos 60 de un rojo-negro.

🗣️ **2 minutos.** En disco, leer una página cuesta lo mismo que leer una clave, y mucho más que compararlas. Un rojo-negro haría una lectura por nivel, con unos 30 a 60 niveles. El árbol B hace 4, y los primeros niveles suelen estar en memoria. El B+ además deja los datos en las hojas, enlazadas para recorrer rangos (`WHERE x BETWEEN a AND b`) sin volver a subir.

🔬 **El detalle.** El mismo argumento vale en memoria con la caché: hay árboles B en memoria por localidad ([`02/05`](../02-analisis/05-el-coste-real.md)).

**02 → 13.** ¿Qué tienes que guardar en cada nodo de un árbol balanceado para responder «el `k`-ésimo menor» y «cuántas claves menores que `x`» en `O(log n)`, y cómo lo mantienes en las rotaciones? 🔴

⏱️ **30 segundos.** El tamaño del subárbol en cada nodo. Con él, el `k`-ésimo se busca bajando (si `k ≤ tamaño izquierdo`, a la izquierda; si no, se descuenta y a la derecha), y las claves menores que `x` se cuentan sumando tamaños izquierdos al bajar. En cada rotación se recalcula el tamaño de los dos nodos implicados.

🗣️ **2 minutos.** `size(v) = 1 + size(izq) + size(der)`. Las rotaciones solo cambian los hijos de dos nodos; se actualiza primero el que baja y después el que sube, como la altura en el AVL. Las inserciones y borrados actualizan los tamaños en el camino. Todo sigue siendo `O(log n)`.

🔬 **El detalle.** Es el árbol de estadísticos de orden de CLRS (§14.1) y lo que da el `tree` de *policy-based* de GCC con `find_by_order` y `order_of_key`.

**02 → Problema: Butacas libres.**

- **Pista 2 — patrón:** **conjunto ordenado** con `ceiling` y borrado.
- **Pista 3 — diseño:** mete `1..n` en un `TreeSet` (o `std::set`); para cada petición, `ceiling(x)` (o `lower_bound`); si existe, imprímelo y bórralo. En Python, sin conjunto ordenado: Union-Find de «siguiente libre» ([`08/04`](../08-heaps-y-union-find/04-union-find.md)).

**02 → Problema: ¿Es un BST?.**

- **Pista 2 — patrón:** **intervalo permitido** pasado hacia abajo, o **inorden creciente**.
- **Pista 3 — diseño:** recorrido iterativo (el árbol puede ser una cadena) con una pila de `(nodo, lo, hi)` en 64 bits; o inorden iterativo comparando con el anterior. Claves distintas: la desigualdad es estricta.

**02 → Problema: Search in a Binary Search Tree.**

- **Pista 2 — patrón:** **búsqueda en BST**.
- **Pista 3 — diseño:** baja a la izquierda si la clave es menor, a la derecha si es mayor; devuelve el nodo o nulo.

**02 → Problema: Convert Sorted Array to Binary Search Tree.**

- **Pista 2 — patrón:** **construcción balanceada** por la mediana.
- **Pista 3 — diseño:** el elemento central es la raíz; recursión sobre las dos mitades con índices. La altura queda en `⌈log₂(n + 1)⌉`.

**02 → Problema: Two Sum IV - Input is a BST.**

- **Pista 2 — patrón:** **inorden** y **dos punteros**, o conjunto de vistos.
- **Pista 3 — diseño:** saca el inorden (ordenado) y busca la suma con dos punteros desde los extremos; o recorre con un conjunto de complementos.

**02 → Problema: Insert into a Binary Search Tree.**

- **Pista 2 — patrón:** **inserción en BST**: la clave nueva acaba siempre en una hoja.
- **Pista 3 — diseño:** baja hasta el hueco donde debería estar y cuélgala ahí; recursivo devolviendo el subárbol, o iterativo guardando el padre.

**02 → Problema: Delete Node in a BST.**

- **Pista 2 — patrón:** **borrado con sucesor**.
- **Pista 3 — diseño:** busca el nodo; si tiene un hijo o ninguno, devuelve ese hijo; si tiene dos, copia la clave del mínimo del subárbol derecho y bórralo de ahí recursivamente.

**02 → Problema: Kth Smallest Element in a BST.**

- **Pista 2 — patrón:** **inorden** con contador.
- **Pista 3 — diseño:** inorden iterativo con pila, parando al sacar el `k`-ésimo; para muchas consultas con cambios, tamaños de subárbol en cada nodo.

**02 → Problema: Binary Search Tree Iterator.**

- **Pista 2 — patrón:** **inorden iterativo perezoso**.
- **Pista 3 — diseño:** la pila guarda la rama izquierda por visitar; `next` saca la cima y apila la rama izquierda de su hijo derecho. `O(h)` de memoria y `O(1)` amortizado por llamada.

**02 → Problema: Balance a Binary Search Tree.**

- **Pista 2 — patrón:** **inorden** y **construcción balanceada**.
- **Pista 3 — diseño:** saca el inorden a un arreglo y reconstruye tomando la mediana como raíz, recursivamente.

**02 → Problema: Recover Binary Search Tree.**

- **Pista 2 — patrón:** **inorden con dos anomalías**.
- **Pista 3 — diseño:** en el inorden, los pares con `anterior > actual` delatan el intercambio: si hay uno, intercambia sus dos nodos; si hay dos, el primero del primer par y el segundo del segundo. Para memoria `O(1)`, recorrido de Morris.

**02 → Problema: Self Balancing Tree.**

- **Pista 2 — patrón:** **inserción AVL** con alturas.
- **Pista 3 — diseño:** la plantilla de §4 adaptada a la estructura del enunciado: actualiza alturas al volver de la recursión y aplica la rotación simple o doble según el lado del desequilibrio.

---

# 03 — Árboles aleatorizados y autoajustables

**03 → 1.** ¿Qué dos propiedades cumple a la vez un *treap*? 🟢

⏱️ **30 segundos.** Es un BST por las claves y un montículo por las prioridades: a la izquierda claves menores, a la derecha mayores, y todo nodo con más prioridad que sus hijos.

🗣️ **2 minutos.** Las dos propiedades juntas determinan la forma del árbol. Las prioridades son aleatorias y se asignan al crear el nodo; nunca cambian. El balanceo sale de que la raíz de cada subárbol es un elemento elegido al azar.

🔬 **El detalle.** Con prioridades repetidas, el árbol deja de ser único, pero sigue siendo correcto; con 32 o 64 bits aleatorios, las repeticiones son raras.

**03 → 2.** ¿Qué hacen `split` y `merge`, y qué condición necesita `merge`? 🟢

⏱️ **30 segundos.** `split(t, k)` parte el *treap* en uno con las claves menores que `k` y otro con el resto; `merge(L, R)` une dos *treaps* si todas las claves de `L` son menores que las de `R`.

🗣️ **2 minutos.** `split` baja por un camino decidiendo en cada nodo de qué lado queda y reenganchando; `merge` baja por las ramas derecha de `L` e izquierda de `R`, eligiendo la raíz por prioridad. Las dos cuestan la profundidad, `O(log n)` esperado. Con ellas se escribe todo lo demás.

🔬 **El detalle.** Si se llama a `merge` con claves que se solapan, el resultado deja de ser un BST sin ningún error visible.

**03 → 3.** ¿Por qué la *skip list* sube cada elemento con probabilidad `1/2`? 🟢

⏱️ **30 segundos.** Para que el número esperado de elementos en cada nivel se reduzca a la mitad: el nivel `i` tiene unos `n/2ⁱ` elementos, hay unos `log₂ n` niveles, y la búsqueda da un número esperado constante de pasos por nivel.

🗣️ **2 minutos.** Es el análogo aleatorio de una lista con atajos cada 2, 4, 8… posiciones. Con `p = 1/2`, el número esperado de pasos horizontales por nivel es como mucho 2, y el total `O(log n)`. Otros valores de `p` (por ejemplo `1/4`) cambian la constante y la memoria.

🔬 **El detalle.** La memoria esperada es `n/(1 − p)` nodos: `2n` con `p = 1/2`.

**03 → 4.** ¿Por qué el *treap* de un conjunto de claves y prioridades es único? 🟡

⏱️ **30 segundos.** Porque la raíz tiene que ser la de mayor prioridad (por la propiedad de montículo), y entonces las claves menores van a la izquierda y las mayores a la derecha (por la de BST); recursivamente, cada subárbol queda determinado igual.

🗣️ **2 minutos.** Por inducción sobre el número de claves: con 0 o 1, trivial. Con más, la raíz está forzada y los dos conjuntos de claves de los subárboles también; por hipótesis, cada subárbol es único. La consecuencia es que el *treap* no depende del orden de las operaciones, solo de las claves y prioridades actuales.

🔬 **El detalle.** Es la razón de que el análisis sea tan limpio: el *treap* es el BST que da insertar las claves por orden de prioridad, un BST aleatorio.

**03 → 5.** Escribe la inserción y el borrado de un *treap* con `split` y `merge`. 🟡

⏱️ **30 segundos.** Insertar: `(L, R) = split(t, k)` y `t = merge(merge(L, nodo(k)), R)`. Borrar: `(L, R) = split(t, k)`, `(M, R) = split(R, k + 1)`, `t = merge(L, R)`.

🗣️ **2 minutos.** En la inserción, `L` tiene las claves menores que `k` y `R` las mayores o iguales: el nodo nuevo cabe exactamente entre las dos, y los `merge` recolocan la prioridad. En el borrado, el segundo `split` aísla las claves iguales a `k` en `M`, que se descarta.

🔬 **El detalle.** El `split(R, k + 1)` vale para enteros; con claves no enteras, se parte por «`≤ k`» con un `split` que mande los iguales a la izquierda.

**03 → 6.** ¿Qué es la «clave implícita» del *treap* implícito y cómo la calcula `split` al bajar? 🟡

⏱️ **30 segundos.** Es la posición del nodo en el inorden. No se guarda: se calcula bajando, sumando el tamaño del subárbol izquierdo más uno cada vez que se va a la derecha.

🗣️ **2 minutos.** `split(t, k)` por tamaño compara `k` con `sz[izq]`: si `sz[izq] < k`, el nodo y su izquierdo van a la parte de los `k` primeros, y se sigue por la derecha con `k − sz[izq] − 1`. Por eso las posiciones se «actualizan solas» al insertar o borrar: no hay ninguna clave que renumerar.

🔬 **El detalle.** Es lo que hace imposible un *treap* implícito con claves explícitas: insertar en medio cambiaría las claves de todos los de detrás.

**03 → 7.** Demuestra que la profundidad esperada de un nodo en un *treap* es `O(log n)`. 🟠

⏱️ **30 segundos.** `xᵢ` es ancestro de `xⱼ` si y solo si tiene la mayor prioridad entre `xᵢ…xⱼ`: probabilidad `1/(|i − j| + 1)`. La profundidad esperada es `Σ_{i≠j} 1/(|i − j| + 1) < 2Hₙ ≈ 2 ln n`.

🗣️ **2 minutos.** Si el de mayor prioridad del tramo es `xᵢ`, entonces al construir el árbol de arriba abajo, `xᵢ` se elige como raíz de un subárbol que contiene a `xⱼ` antes que cualquier otro del tramo: es ancestro. Si es otro `x_m` del tramo, `x_m` se elige antes y separa a `xᵢ` y `xⱼ` en subárboles distintos: no es ancestro. Sumando las probabilidades por linealidad de la esperanza, se obtiene la cota.

🔬 **El detalle.** El mismo argumento da el número esperado de comparaciones de *quicksort* ([`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md)), que es la suma de las profundidades.

**03 → 8.** ¿Por qué la marca de inversión tiene que aplicarse antes de bajar, tanto en `split` como en `merge`? 🟠

⏱️ **30 segundos.** Porque al bajar por un nodo con una inversión sin aplicar, sus hijos están «al revés»: si no se aplica, `split` cuenta tamaños del lado equivocado y `merge` engancha subárboles en el orden equivocado.

🗣️ **2 minutos.** La marca dice «este subárbol debe leerse invertido». `push` la aplica en el nodo (intercambia sus hijos) y la pasa a los hijos. Cualquier operación que decida algo según qué hijo es el izquierdo (las dos lo hacen) necesita la marca aplicada antes.

🔬 **El detalle.** Las marcas se componen por *xor*: dos inversiones del mismo subárbol se cancelan.

**03 → 9.** Compara qué harías en C++, Java y Python si necesitas «el número de claves menores que `x`» con inserciones. 🟠

⏱️ **30 segundos.** C++: `tree` de *policy-based* con `order_of_key`. Java: no hay en la biblioteca; un *treap* propio o un Fenwick sobre valores comprimidos si se conocen de antemano. Python: lo mismo que Java; `bisect` sobre una lista ordenada si las inserciones son pocas.

🗣️ **2 minutos.** `TreeSet` no da el rango de un elemento en `O(log n)` (`headSet(x).size()` es lineal). Si todas las claves se conocen al principio (procesamiento *offline*), Fenwick sobre los valores comprimidos es lo más simple en los tres. Si no, *treap* con tamaños.

🔬 **El detalle.** `03/02` explica el `tree` de GCC; [`09/02`](../09-consultas-sobre-rangos/02-fenwick.md), el Fenwick.

**03 → 10.** ¿Qué diferencia hay entre el `O(log n)` esperado del *treap*, el amortizado del *splay* y el de peor caso del rojo-negro? 🟠

⏱️ **30 segundos.** Esperado: el promedio sobre las monedas del algoritmo, para cualquier entrada. Amortizado: el total de `m` operaciones es `O(m log n)`, aunque alguna cueste `O(n)`. Peor caso: cada operación, siempre, `O(log n)`.

🗣️ **2 minutos.** El *treap* puede tener mala suerte en una ejecución (improbable); el *splay* tiene operaciones caras que se compensan con baratas; el rojo-negro no tiene ninguna de las dos cosas. Para un juez, los tres sirven; para tiempo real, solo el de peor caso.

🔬 **El detalle.** [`02/01`](../02-analisis/01-notacion-asintotica.md) define los tres tipos de coste; [`02/03`](../02-analisis/03-analisis-amortizado.md), el amortizado.

**03 → 11.** ¿Por qué Java tiene `ConcurrentSkipListMap` y no un `ConcurrentTreeMap`? 🔴

⏱️ **30 segundos.** Porque en una *skip list* insertar y borrar solo cambian punteros locales, que se pueden actualizar con operaciones atómicas sin bloquear la estructura; en un rojo-negro, una inserción puede rotar y recolorear lejos del punto de inserción.

🗣️ **2 minutos.** Un árbol balanceado concurrente necesita bloquear caminos o subárboles durante las reparaciones. La *skip list* enlaza el nodo nuevo nivel a nivel con *compare-and-swap*, y los lectores nunca ven un estado inconsistente en los niveles que importan. Por eso es la elección de `java.util.concurrent`.

🔬 **El detalle.** Redis usa *skip lists* para sus conjuntos ordenados por razones parecidas: simplicidad y recorridos por rango.

**03 → 12.** En un *treap* implícito con inversiones, ¿qué cambia en `pull` y en `push` si cada nodo guarda el mínimo de su subárbol? ¿Y si guarda el *hash* polinomial de la secuencia ([`06/04`](../06-lineales-y-hashing/04-hashing-de-secuencias.md))? 🔴

⏱️ **30 segundos.** Con el mínimo, `pull` hace `min(val, min[izq], min[der])` y `push` no lo toca, porque invertir no cambia el mínimo. Con el *hash*, depende del orden: hay que guardar también el *hash* de la secuencia invertida, y `push` intercambia los dos.

🗣️ **2 minutos.** Un agregado conmutativo (suma, mínimo, máximo) no cambia al invertir: la marca solo intercambia hijos. Un agregado que depende del orden, como el *hash* polinomial, sí cambia: `pull` combina `hash[izq] · b^{1 + sz[der]} + val · b^{sz[der]} + hash[der]` y su versión al revés; al aplicar una inversión, se intercambian `hash` y `hashRev` del nodo.

🔬 **El detalle.** Es la técnica general: para cada operación perezosa, hay que saber cómo transforma el agregado sin bajar; si no se puede, se guarda información extra que lo permita.

**03 → 13.** Acota la probabilidad de que la altura de una *skip list* de `n` elementos pase de `3 log₂ n`. 🔴

⏱️ **30 segundos.** La probabilidad de que un elemento llegue al nivel `h` es `2⁻ʰ`; por la unión sobre los `n` elementos, `P(altura ≥ h) ≤ n · 2⁻ʰ`. Con `h = 3 log₂ n`, `≤ n · n⁻³ = n⁻²`.

🗣️ **2 minutos.** Cada elemento sube de nivel con probabilidad `1/2` de forma independiente; llegar al nivel `h` exige `h` éxitos seguidos. La altura de la lista es el máximo de los niveles; que pase de `h` exige que al menos uno lo haga. Con `n = 10⁶`, la probabilidad es `10⁻¹²`.

🔬 **El detalle.** Es el tipo de cota «con alta probabilidad» que se formaliza en [`19/02`](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md); para el *treap* sale una del mismo tipo.

**03 → Problema: Fila del comedor.**

- **Pista 2 — patrón:** **treap implícito**: insertar por posición y consultar por posición.
- **Pista 3 — diseño:** insertar en `p` es `split` por tamaño `p` y dos `merge`; consultar la posición `p` es bajar por los tamaños. Sin inversiones, no hace falta la marca.

**03 → Problema: Ventana de inversiones.**

- **Pista 2 — patrón:** **treap implícito con marca de inversión**.
- **Pista 3 — diseño:** la plantilla de §4: dos `split`, marcar, dos `merge`; al final, un inorden aplicando las marcas (iterativo o recursivo, la profundidad es logarítmica en esperanza).

**03 → Problema: Yet Another Array Queries Problem.**

- **Pista 2 — patrón:** **seguir hacia atrás** las posiciones consultadas (o *treap* implícito).
- **Pista 3 — diseño:** con pocas consultas `m`, para cada posición consultada recorre las operaciones al revés y deshaz cada rotación o inversión sobre esa posición: `O(q · m)`. El *treap* implícito también entra, simulando todo.

**03 → Problema: Cut and Paste.**

- **Pista 2 — patrón:** **treap implícito**.
- **Pista 3 — diseño:** separa la cadena en tres (antes, tramo, después) con dos `split` por tamaño y une en el orden «antes, después, tramo». Al final, un inorden.

**03 → Problema: Substring Reversals.**

- **Pista 2 — patrón:** **treap implícito con marca de inversión**.
- **Pista 3 — diseño:** cada inversión es partir en tres, marcar el del medio y unir; `push` en `split` y en `merge`; el resultado, con un inorden.

**03 → Problema: Array and simple queries.**

- **Pista 2 — patrón:** **treap implícito** con mover tramos a un extremo.
- **Pista 3 — diseño:** el tipo 1 lleva el tramo al principio (`merge(medio, merge(antes, después))`) y el tipo 2 al final; imprime `|A[1] − A[N]|` y el arreglo final con un inorden.

**03 → Problema: Design Skiplist.**

- **Pista 2 — patrón:** **skip list** con un arreglo de predecesores por nivel.
- **Pista 3 — diseño:** la búsqueda guarda, en cada nivel, el último nodo menor que el valor (`update[lv]`); la inserción sortea el nivel del nodo nuevo y lo engancha tras `update[lv]` en cada nivel; el borrado desengancha en los niveles donde aparece. Admite repetidos.

**03 → Problema: Multiset.**

- **Pista 2 — patrón:** **estadístico de orden** con poca memoria: Fenwick sobre los valores.
- **Pista 3 — diseño:** los valores están en `[1, n]`: un Fenwick de cuentas; insertar suma 1; borrar el `k`-ésimo es buscar en el Fenwick por descenso binario la posición donde el prefijo alcanza `k` (`09/02`). Un *treap* de `10⁶` nodos con varios arreglos puede pasarse de memoria.

**03 → Problema: Letters Removing.**

- **Pista 2 — patrón:** **posición actual a original** con un Fenwick o un *treap*, y un conjunto por letra.
- **Pista 3 — diseño:** guarda, por cada carácter, un conjunto ordenado de sus posiciones originales vivas; traduce `l` y `r` actuales a originales con un Fenwick de vivos (descenso binario); borra del conjunto del carácter las posiciones en ese rango y márcalas muertas en el Fenwick.

**03 → Problema: Reversals and Sums.**

- **Pista 2 — patrón:** **treap implícito con suma** y marca de inversión.
- **Pista 3 — diseño:** `sum` por nodo actualizada en `pull`; `push` intercambia hijos sin tocar sumas; inversión y consulta parten en tres y leen o marcan el del medio. Sumas en 64 bits.

---

# 04 — Tries

**04 → 1.** ¿Qué representa el camino de la raíz a un nodo de un *trie*? 🟢

⏱️ **30 segundos.** Un prefijo: el camino deletrea, carácter a carácter, el prefijo común de todas las palabras que pasan por ese nodo.

🗣️ **2 minutos.** La raíz representa la cadena vacía; cada arista añade un carácter. Dos palabras comparten exactamente los nodos de su prefijo común más largo y se separan en el primer carácter distinto.

🔬 **El detalle.** Por eso el *trie* ordena las palabras: un recorrido en preorden visitando los hijos en orden alfabético las da en orden lexicográfico.

**04 → 2.** ¿Cuánto cuesta buscar una palabra de longitud `L`, y de qué no depende? 🟢

⏱️ **30 segundos.** `O(L)`: un paso por carácter. No depende del número de palabras guardadas.

🗣️ **2 minutos.** Con hijos en un arreglo, cada paso es un acceso directo; con un mapa por nodo, un acceso a una tabla *hash* (`O(1)` esperado). En los dos casos, `L` pasos. Una tabla *hash* de palabras también es `O(L)` (hay que calcular el *hash*), pero no responde por prefijos.

🔬 **El detalle.** En la práctica, el *trie* hace `L` accesos dispersos a memoria; un *hash* hace uno: para palabras completas, el *hash* suele ser más rápido.

**04 → 3.** ¿Qué diferencia hay entre `pass` y `end` en un nodo? 🟢

⏱️ **30 segundos.** `pass` cuenta las palabras que pasan por el nodo (las que tienen ese prefijo); `end`, las que terminan exactamente en él.

🗣️ **2 minutos.** «¿Cuántas empiezan por `p`?» es `pass` del nodo de `p`; «¿está `p`?» es `end > 0`. Un nodo con `pass > 0` y `end = 0` es prefijo de otras palabras pero no es una palabra.

🔬 **El detalle.** Con repetidos, `end` cuenta las veces que se insertó la palabra.

**04 → 4.** ¿Cuánta memoria gasta un *trie* con arreglos de 26 hijos y `10⁶` nodos en C++, y cómo lo reduces? 🟡

⏱️ **30 segundos.** `10⁶ × 26 × 4 bytes ≈ 104 MB`, más los contadores. Se reduce con un mapa por nodo, con hijos en lista enlazada (primer hijo y hermano), o comprimiendo las cadenas sin ramificar.

🗣️ **2 minutos.** El arreglo de 26 desperdicia casi todo cuando los nodos tienen uno o dos hijos, que es lo habitual en las partes profundas. Un mapa ordenado o *hash* por nodo gasta según los hijos reales, a cambio de constante. El *trie* comprimido reduce el número de nodos a `O(N)`.

🔬 **El detalle.** Con un alfabeto pequeño (4 letras del ADN, 2 bits), el arreglo es lo mejor.

**04 → 5.** ¿Cómo borras una palabra de un *trie* sin quitar nodos? 🟡

⏱️ **30 segundos.** Bajando por la palabra y restando 1 a `pass` en cada nodo y a `end` en el último; un nodo con `pass = 0` se trata como inexistente.

🗣️ **2 minutos.** Quitar los nodos de verdad obliga a recordar el padre y comprobar si quedan hijos; con contadores no hace falta, y las búsquedas posteriores comprueban `pass > 0` al bajar. Si se reinserta la palabra, los nodos se reutilizan.

🔬 **El detalle.** El precio es que la memoria no baja; si hay muchísimas inserciones y borrados de palabras distintas, puede hacer falta reciclar nodos.

**04 → 6.** ¿Por qué el bit más alto domina en el XOR, y qué consecuencia tiene para el voraz? 🟡

⏱️ **30 segundos.** Porque `2ᵏ > 2ᵏ⁻¹ + … + 1 = 2ᵏ − 1`: un 1 en el bit `k` vale más que todos los bits inferiores juntos. El voraz puede decidir bit a bit, de arriba abajo, sin mirar los de abajo.

🗣️ **2 minutos.** Al comparar dos números, gana el que tiene un 1 en el primer bit (desde arriba) en que difieren. Así que maximizar el XOR es: hacer 1 el bit más alto posible; entre las opciones que lo consiguen, el siguiente, etc. El *trie* binario agrupa justamente por prefijos de bits.

🔬 **El detalle.** Para la suma no funciona: `a + b` no tiene esa estructura por bits (hay acarreos).

**04 → 7.** ¿Cómo compruebas, al insertar, que ninguna palabra es prefijo de otra? 🟡

⏱️ **30 segundos.** Hay conflicto si, al insertar, se pasa por un nodo con `end > 0` (una palabra ya insertada es prefijo de la nueva) o si al terminar el nodo ya tenía `pass > 0` antes de insertar (la nueva es prefijo de otra).

🗣️ **2 minutos.** El primer caso se ve durante el descenso; el segundo, al final, si el último nodo ya existía (tiene hijos o se pasó por él). También es conflicto insertar dos veces la misma palabra.

🔬 **El detalle.** Es el problema No Prefix Set; la respuesta suele pedir la primera palabra que provoca el conflicto, según el orden de entrada.

**04 → 8.** Demuestra que el voraz bit a bit sobre el *trie* binario da el XOR máximo con `x`. 🟠

⏱️ **30 segundos.** Por intercambio bit a bit: si en el nivel `k` hay un candidato que pone un 1 en el bit `k` del XOR, cualquier candidato que ponga un 0 es peor, porque todos los bits inferiores juntos no compensan `2ᵏ`. El voraz nunca descarta al óptimo.

🗣️ **2 minutos.** Sea `y*` el óptimo. Invariante: tras procesar los bits `B − 1..k`, el nodo actual es el prefijo de `y*` (o de otro óptimo). Si en el nivel `k` existe el hijo con el bit contrario al de `x`, `y*` tiene que estar en él: si no, su XOR tendría un 0 en el bit `k` y otro candidato de ese hijo, que coincide en los bits superiores, lo superaría. Si no existe, solo queda el otro hijo, y el óptimo está ahí.

🔬 **El detalle.** El mismo argumento sirve para el XOR **mínimo** (bajar por el bit igual) y para contar pares con XOR menor que un umbral.

**04 → 9.** Compara cómo implementarías el nodo de un *trie* en C++, Java y Python, y por qué. 🟠

⏱️ **30 segundos.** C++: un `std::vector<std::array<int, 26>>` (o de 2 para bits) con índices. Java: arreglos planos (`next[26 · v + c]`) para no crear un objeto por nodo. Python: un diccionario por nodo en una lista, o un diccionario anidado.

🗣️ **2 minutos.** En C++ los arreglos de tamaño fijo son contiguos y rápidos. En Java, un `int[cap][26]` crea `cap` objetos con cabecera, y una clase `Node` con un arreglo dentro aún más; los arreglos planos indexados son lo eficiente. En Python, la memoria por nodo es alta de todas formas; un diccionario guarda solo los hijos reales.

🔬 **El detalle.** Para el *trie* binario en Python, dos listas `zero` y `one` de enteros son más compactas que una lista de listas.

**04 → 10.** ¿Cómo encuentras el subarreglo con XOR máximo en `O(n · B)`? 🟠

⏱️ **30 segundos.** Con prefijos XOR `P[0] = 0`, `P[i+1] = P[i] ⊕ a[i]`: el XOR de `a[l..r]` es `P[r+1] ⊕ P[l]`. Se insertan los prefijos en un *trie* binario y, para cada `P[j]`, se busca el mejor compañero entre los anteriores.

🗣️ **2 minutos.** El XOR es su propio inverso, así que los prefijos XOR funcionan como las sumas de prefijos ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)). El máximo sobre los pares `i < j` de `P[j] ⊕ P[i]` es el máximo XOR de dos elementos del arreglo de prefijos: insertar `P[0]` y, para cada `j`, consultar y luego insertar `P[j]`. `O(n · B)`.

🔬 **El detalle.** Con la longitud del subarreglo acotada (como mucho `k`), hay que borrar del *trie* los prefijos que quedan fuera de la ventana: los contadores lo permiten.

**04 → 11.** ¿Por qué un *trie* comprimido tiene como mucho `2N − 1` nodos? 🟠

⏱️ **30 segundos.** Porque cada nodo interno de un *trie* comprimido tiene al menos dos hijos, y un árbol con `N` hojas en el que todo nodo interno tiene al menos dos hijos tiene como mucho `N − 1` nodos internos.

🗣️ **2 minutos.** Las palabras acaban en hojas o en nodos marcados; si ninguna es prefijo de otra, cada palabra es una hoja: `N` hojas. Contando aristas: un árbol de `I` nodos internos con al menos dos hijos cada uno tiene al menos `2I` aristas, y un árbol de `N + I` nodos tiene `N + I − 1`: `2I ≤ N + I − 1`, así que `I ≤ N − 1`. Total `≤ 2N − 1`.

🔬 **El detalle.** Si hay palabras que son prefijo de otras, terminan en nodos internos; la cota se mantiene con un ajuste (o añadiendo un terminador como `$`).

**04 → 12.** Con un *trie* binario, ¿cómo cuentas los pares `(i, j)` con `a[i] ⊕ a[j] < K`? 🔴

⏱️ **30 segundos.** Para cada `x`, bajando por los bits de `K`: si el bit de `K` es 1, todos los del hijo que da bit 0 en el XOR cumplen (se suman con su contador) y se sigue por el que da 1; si es 0, se sigue por el que da 0. Se inserta cada elemento después de consultarlo.

🗣️ **2 minutos.** En el nivel `k`, el XOR con los números de un hijo tiene el bit `k` fijo. Si `K` tiene un 1 ahí y el XOR un 0, el XOR ya es menor que `K` sea cual sea el resto: se suma el subárbol entero. Si los dos bits son iguales, no se decide aún y se baja. Si `K` tiene 0 y el XOR 1, ya es mayor: no se cuenta. `O(n · B)`.

🔬 **El detalle.** Con «`≤ K`», se cuenta `< K + 1`; para «en `[L, R]`», `cuenta(R + 1) − cuenta(L)`.

**04 → 13.** ¿Cómo respondes «el XOR máximo de `x` con algún elemento de `a[l..r]`» para muchas consultas *online*? 🔴

⏱️ **30 segundos.** Con un *trie* binario **persistente**: una versión por cada prefijo del arreglo, con contadores; la consulta baja a la vez por la versión `r` y la `l − 1`, y un hijo «existe en el rango» si la diferencia de contadores es positiva.

🗣️ **2 minutos.** Insertar `a[i]` en la versión `i − 1` crea `B` nodos nuevos que copian el camino y comparten el resto: `O(n · B)` nodos en total. El contador de un nodo en la versión `r` menos el de la versión `l − 1` es cuántos elementos de `a[l..r]` tienen ese prefijo de bits. El voraz es el mismo, consultando esa diferencia. `O(B)` por consulta.

🔬 **El detalle.** La persistencia por copia de camino es la misma técnica que el segment tree persistente ([`09/04`](../09-consultas-sobre-rangos/04-segment-tree-avanzado.md)).

**04 → Problema: Prefijo más popular.**

- **Pista 2 — patrón:** **trie** con `pass` y recorrido hasta la profundidad `k`.
- **Pista 3 — diseño:** inserta todas las palabras; recorre el *trie* en orden alfabético hasta la profundidad `k` y quédate con el nodo de mayor `pass` (el primero en el orden, a igualdad). Alternativa: un mapa de los prefijos de longitud `k`.

**04 → Problema: El mejor socio.**

- **Pista 2 — patrón:** **trie binario con contadores**.
- **Pista 3 — diseño:** `add(x, +1)` y `add(x, −1)`; antes de consultar, comprueba si el número de socios presentes es 0 para imprimir `-1`; si no, `maxXor(x)`.

**04 → Problema: Implement Trie (Prefix Tree).**

- **Pista 2 — patrón:** **trie de palabras** con marca de fin.
- **Pista 3 — diseño:** `insert` crea los nodos; `search` baja y mira `end`; `startsWith` baja y solo comprueba que el camino existe.

**04 → Problema: Replace Words.**

- **Pista 2 — patrón:** **prefijo más corto** del diccionario.
- **Pista 3 — diseño:** inserta las raíces; para cada palabra de la frase, baja por el *trie* y para en el primer nodo con `end`; si no hay, deja la palabra.

**04 → Problema: Search Suggestions System.**

- **Pista 2 — patrón:** **autocompletar** con las tres primeras en cada nodo.
- **Pista 3 — diseño:** ordena los productos e insértalos; cada nodo guarda los tres primeros que pasan por él (al insertar en orden, los tres primeros que llegan). Alternativa sin *trie*: ordenar y búsqueda binaria del prefijo.

**04 → Problema: Design Add and Search Words Data Structure.**

- **Pista 2 — patrón:** **trie con comodín** y búsqueda recursiva.
- **Pista 3 — diseño:** con una letra, baja por su hijo; con `.`, prueba todos los hijos existentes con una recursión; al final, mira `end`.

**04 → Problema: Longest Word in Dictionary.**

- **Pista 2 — patrón:** **trie** y recorrido por nodos que son palabra.
- **Pista 3 — diseño:** inserta todas; recorre desde la raíz solo por hijos con `end > 0`, guardando la palabra más larga (y la menor alfabéticamente a igualdad).

**04 → Problema: No Prefix Set.**

- **Pista 2 — patrón:** **detección de prefijos al insertar**.
- **Pista 3 — diseño:** al insertar, si pasas por un nodo con `end > 0`, o si el nodo final ya existía (tenía `pass > 0`), es conflicto: imprime `BAD SET` y la palabra actual.

**04 → Problema: Perfect Security.**

- **Pista 2 — patrón:** **trie binario voraz** minimizando el XOR, con borrado.
- **Pista 3 — diseño:** inserta la clave permutable; para cada `A[i]` en orden, busca el elemento que da el XOR **mínimo** (bajar por el bit igual), imprímelo y bórralo.

**04 → Problema: Word Combinations.**

- **Pista 2 — patrón:** **trie** + **DP** sobre posiciones.
- **Pista 3 — diseño:** `dp[i]` = formas de formar el sufijo desde `i`; desde cada `i`, baja por el *trie* con `s[i], s[i+1], …` y, por cada nodo con `end`, suma `dp[j + 1]`. Módulo `10⁹ + 7`; la longitud de las palabras acota el descenso.

**04 → Problema: Vasiliy's Multiset.**

- **Pista 2 — patrón:** **trie binario con borrado**.
- **Pista 3 — diseño:** inserta el 0 al principio (siempre está), y aplica `add` con `+1` o `−1` y `maxXor` según la orden.

**04 → Problema: Maximum XOR With an Element From Array.**

- **Pista 2 — patrón:** **trie binario offline** ordenando por el límite.
- **Pista 3 — diseño:** ordena los números y las consultas por `m`; para cada consulta, inserta los números `≤ m` que falten y aplica `maxXor`; si el *trie* está vacío, `-1`.

**04 → Problema: Word Search II.**

- **Pista 2 — patrón:** **trie de las palabras** + **DFS** en la rejilla.
- **Pista 3 — diseño:** un solo DFS desde cada celda que avanza por el *trie* a la vez; corta en cuanto el prefijo no existe; al llegar a un nodo con palabra, regístrala y quita la marca para no repetir; poda las ramas ya agotadas.

---

# 05 — LCA

**05 → 1.** ¿Qué es el LCA de dos nodos? Da `LCA(4, 7)` y `LCA(4, 6)` en T. 🟢

⏱️ **30 segundos.** El nodo más profundo que es ancestro de los dos. En T, `LCA(4, 7) = 2` y `LCA(4, 6) = 1`.

🗣️ **2 minutos.** Un nodo es ancestro de sí mismo, así que si `u` es ancestro de `v`, el LCA es `u`. El camino entre `u` y `v` sube de `u` al LCA y baja a `v`: el LCA es el punto más alto del camino.

🔬 **El detalle.** El LCA depende de la raíz elegida; la distancia entre `u` y `v`, no.

**05 → 2.** ¿Qué fórmula da la distancia entre dos nodos con el LCA? 🟢

⏱️ **30 segundos.** `dist(u, v) = prof(u) + prof(v) − 2 · prof(LCA(u, v))`.

🗣️ **2 minutos.** El camino es `u → LCA → v`. La subida mide `prof(u) − prof(LCA)` y la bajada `prof(v) − prof(LCA)`. Con pesos, se usan las distancias ponderadas a la raíz en lugar de las profundidades.

🔬 **El detalle.** El mismo esquema da la suma de cualquier magnitud aditiva sobre el camino: `S(u) + S(v) − 2 · S(LCA)` para aristas, y sumando el valor del propio LCA si se cuentan nodos.

**05 → 3.** ¿Qué guarda `up[k][v]`, y cómo se calcula a partir de `up[k − 1]`? 🟢

⏱️ **30 segundos.** El ancestro de `v` a distancia `2ᵏ`. `up[k][v] = up[k − 1][up[k − 1][v]]`: subir `2ᵏ` es subir `2ᵏ⁻¹` dos veces.

🗣️ **2 minutos.** `up[0]` es el padre. Cada nivel se calcula a partir del anterior en `O(n)`, y hay `log₂ n` niveles: `Θ(n log n)`. La raíz se toma como su propio padre, para que los saltos que se pasan se queden en ella.

🔬 **El detalle.** Llenar por niveles completos (primero todo `k = 1`, luego todo `k = 2`…) no necesita ningún orden especial de los nodos.

**05 → 4.** ¿Por qué hay que igualar profundidades antes de saltar los dos nodos a la vez? 🟡

⏱️ **30 segundos.** Porque los saltos simultáneos solo funcionan si los dos nodos están a la misma distancia del LCA; si no, el mismo salto los deja a alturas distintas y nunca coinciden.

🗣️ **2 minutos.** El paso de saltar juntos compara `up[k][u]` con `up[k][v]`: si están a profundidades distintas, esos dos ancestros no pueden ser el mismo nodo salvo por encima del LCA, y la búsqueda se descontrola. Igualando primero, los dos están a la misma distancia del LCA y la búsqueda binaria sobre esa distancia funciona.

🔬 **El detalle.** Tras igualar, si `u = v`, uno era ancestro del otro y ese es el LCA.

**05 → 5.** ¿Cómo subes `d` niveles con la tabla, y cuántos saltos hace como mucho? 🟡

⏱️ **30 segundos.** Escribiendo `d` en binario y aplicando `up[k]` por cada bit `k` encendido. Como mucho `⌊log₂ d⌋ + 1` saltos.

🗣️ **2 minutos.** Los saltos conmutan (subir `2ᵃ` y luego `2ᵇ` es subir `2ᵃ + 2ᵇ`), así que el orden de los bits no importa. Con `d < 2^LOG`, basta la tabla construida.

🔬 **El detalle.** Si `d` es mayor que la profundidad, la plantilla devuelve la raíz; algunos problemas piden `-1` en ese caso, y hay que comprobar `d > prof(v)` antes.

**05 → 6.** ¿Por qué el recorrido de Euler tiene `2n − 1` posiciones? 🟡

⏱️ **30 segundos.** Porque se anota cada nodo al entrar (`n` veces) y cada vez que se vuelve a un padre tras terminar un hijo (`n − 1` veces, una por arista): `2n − 1`.

🗣️ **2 minutos.** Cada arista se recorre dos veces, bajando y subiendo. Bajando se anota el hijo; subiendo, el padre. Más la raíz al principio: `1 + 2(n − 1) = 2n − 1`.

🔬 **El detalle.** Hay variantes que anotan solo al entrar y al salir (`2n`), que sirven para ancestros pero no para el LCA por mínimo.

**05 → 7.** ¿Qué memoria necesita el *binary lifting* con `n = 2·10⁵`, y cómo la reduces si no cabe? 🟠

⏱️ **30 segundos.** `n · LOG` enteros: con `n = 2·10⁵` y `LOG = 18`, unos 3,6 millones de `int`, 14 MB. Si no cabe, el `k`-ésimo ancestro se puede responder *offline* con la pila de un DFS, o con punteros de salto en `O(n)`.

🗣️ **2 minutos.** La memoria suele caber; el problema aparece con agregados (un segundo arreglo del mismo tamaño) o con `n = 10⁶`. Alternativas: Euler + RMQ cuesta parecido; para LCA *offline*, Tarjan con Union-Find (`08/04`) es lineal; para el `k`-ésimo ancestro *offline*, el DFS guarda el camino a la raíz en una pila y la respuesta es `pila[prof − k]`.

🔬 **El detalle.** Ver la pregunta 13 para la versión *online* con memoria lineal.

**05 → 8.** Demuestra que los saltos de mayor a menor dejan `u` y `v` como hijos del LCA. 🟠

⏱️ **30 segundos.** Invariante: `u ≠ v`, a la misma profundidad, con el LCA por encima de los dos. Se salta `2ᵏ` solo si los ancestros siguen siendo distintos, lo que mantiene el invariante; probar los `k` de mayor a menor construye en binario la mayor subida posible, que deja a los dos justo bajo el LCA.

🗣️ **2 minutos.** Sea `D = prof(u) − prof(LCA) − 1` la subida que deja a los dos como hijos del LCA. Para una subida `s`, los ancestros son distintos si y solo si `s ≤ D`: el predicado es monótono, como en la búsqueda binaria. El bucle de `k` de mayor a menor decide los bits de `D` uno a uno: salta `2ᵏ` si lo acumulado más `2ᵏ` sigue siendo `≤ D`. Al terminar, ha subido exactamente `D`.

🔬 **El detalle.** Es la búsqueda binaria «por bits» de [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md): en lugar de un intervalo, se construye la respuesta bit a bit.

**05 → 9.** Demuestra que el LCA es el nodo de menor profundidad entre las primeras apariciones de `u` y `v` en el recorrido de Euler. 🟠

⏱️ **30 segundos.** Entre la primera aparición de `u` y la de `v`, el DFS va de `u` a `v` dentro del subárbol del LCA y pasa por el LCA al volver de la rama de `u`; ningún nodo del tramo es menos profundo que el LCA.

🗣️ **2 minutos.** Sea `u` el visitado antes. Al aparecer `u`, el DFS está dentro del subárbol del LCA. No sale de ese subárbol hasta haberlo recorrido entero, y `v` está en él: así que todo el tramo está dentro del subárbol, con profundidad `≥ prof(LCA)`. Si `u` no es ancestro de `v`, están en ramas distintas bajo el LCA, y para pasar de una a otra el DFS vuelve al LCA, que aparece en el tramo. Si `u` es ancestro de `v`, el propio `u` está en el tramo.

🔬 **El detalle.** CLRS no lo trata; cp-algorithms y Bender y Farach-Colton lo usan como paso de la reducción LCA → RMQ.

**05 → 10.** Compara cómo implementarías la tabla `up` en C++, Java y Python para `n = 2·10⁵`, y su coste real. 🟠

⏱️ **30 segundos.** C++: `vector<vector<int>>` con `LOG` filas de `n`. Java: `int[LOG][n]`, con filas largas y no al revés. Python: una lista por nivel, construida con comprensiones. En los tres, la construcción son unos `3,6·10⁶` accesos.

🗣️ **2 minutos.** La forma `[LOG][n]` llena cada fila recorriendo la anterior: buen acceso a memoria. `[n][LOG]` en Java crearía `n` arreglos pequeños, con cabecera cada uno. En Python, `[prev[prev[v]] for v in range(n)]` corre en C y construye la tabla en una fracción de segundo; un doble bucle en Python puro es varias veces más lento. Las consultas en Python cuestan `log n` pasos interpretados: con `2·10⁵` consultas, unos 4 millones de pasos, que entran justo.

🔬 **El detalle.** En Java, un solo arreglo plano `up[k * n + v]` es aún más compacto.

**05 → 11.** ¿Cómo calculas el máximo peso de arista en el camino entre `u` y `v` con *binary lifting*? 🟠

⏱️ **30 segundos.** Guardando junto a `up[k][v]` el máximo `mx[k][v]` de las aristas en esos `2ᵏ` pasos; `mx[k][v] = max(mx[k−1][v], mx[k−1][up[k−1][v]])`. La consulta acumula el máximo de cada salto que hace al subir `u` y `v` hasta el LCA.

🗣️ **2 minutos.** `mx[0][v]` es el peso de la arista de `v` a su padre. Como el máximo es asociativo, los saltos se combinan. En la consulta, igualar profundidades y los saltos simultáneos van acumulando; al final se añaden las dos aristas al LCA (`mx[0][u]` y `mx[0][v]`).

🔬 **El detalle.** Vale para cualquier operación asociativa: suma, mínimo, máximo, `gcd`. No vale para «la mediana del camino».

**05 → 12.** ¿Cómo calculas el LCA de un conjunto de `k` nodos con una sola llamada a `lca`, usando los tiempos de entrada? 🔴

⏱️ **30 segundos.** El LCA de un conjunto es el LCA del nodo con menor `tin` y el de mayor `tin`.

🗣️ **2 minutos.** Sea `w` el LCA del conjunto: todos están en el subárbol de `w`, es decir, en `[tin[w], tout[w]]`. El de menor `tin` y el de mayor `tin` están en ese tramo; si los dos estuvieran en el subárbol de un mismo hijo `c` de `w`, todos los demás (con `tin` entre ellos) también, y `c` sería un ancestro común más bajo. Así que están en ramas distintas de `w` (o uno es `w`), y su LCA es `w`.

🔬 **El detalle.** Calcular los dos extremos es `O(k)`, y basta una llamada a `lca`. Es la pieza básica de los árboles virtuales (*virtual trees*), que comprimen un árbol a los nodos de una consulta.

**05 → 13.** ¿Se puede responder el `k`-ésimo ancestro en `O(log n)` con memoria `O(n)` en lugar de `O(n log n)`? Esboza cómo. 🔴

⏱️ **30 segundos.** Sí: con **punteros de salto** de un solo nivel por nodo, organizados en binario sesgado (Myers, 1983), cada nodo guarda su padre y un único salto, y el `k`-ésimo ancestro se encuentra en `O(log n)`.

🗣️ **2 minutos.** El salto de `v` se define a partir del de su padre `p`: si los saltos de `p` y de `salto(p)` tienen la misma longitud, `salto(v) = salto(salto(p))`; si no, `salto(v) = p`. Las longitudes siguen la estructura de los números binarios sesgados, y la consulta toma el salto si no se pasa y el padre si se pasa: `O(log n)` pasos, `O(n)` memoria.

🔬 **El detalle.** En concurso casi nunca hace falta; la memoria `O(n log n)` del *binary lifting* suele caber.

**05 → Problema: Primos lejanos.**

- **Pista 2 — patrón:** **binary lifting** para el LCA y la distancia.
- **Pista 3 — diseño:** padres y profundidades con un preorden iterativo (los padres vienen dados y son menores, así que basta un bucle de 2 a `n`); la tabla `up`; para cada consulta, `lca` y `dist`.

**05 → Problema: ¿Está en el camino?.**

- **Pista 2 — patrón:** **LCA** y **prueba de ancestro** con tiempos de entrada y salida.
- **Pista 3 — diseño:** `w` está en el camino si el LCA es ancestro de `w` y `w` es ancestro de `u` o de `v`. Con `tin`/`tout`, cada prueba de ancestro es `O(1)`; el LCA, *binary lifting*.

**05 → Problema: Lowest Common Ancestor of a Binary Search Tree.**

- **Pista 2 — patrón:** **LCA con la propiedad de BST**.
- **Pista 3 — diseño:** baja desde la raíz: si los dos son menores, a la izquierda; si los dos son mayores, a la derecha; en otro caso, el nodo actual es el LCA.

**05 → Problema: Lowest Common Ancestor of a Binary Tree.**

- **Pista 2 — patrón:** **LCA recursivo** de una sola consulta.
- **Pista 3 — diseño:** la recursión devuelve `p` o `q` si los encuentra en el subárbol; si los dos lados devuelven algo, el nodo actual es el LCA; si solo uno, se propaga ese.

**05 → Problema: Company Queries I.**

- **Pista 2 — patrón:** **k-ésimo ancestro** con *binary lifting*.
- **Pista 3 — diseño:** la tabla `up` con el director como su propio jefe y una marca para «no existe»: si `k` es mayor que la profundidad, `-1`; si no, `lift(x, k)`.

**05 → Problema: Company Queries II.**

- **Pista 2 — patrón:** **LCA con binary lifting**.
- **Pista 3 — diseño:** profundidades desde los jefes (que vienen antes) y la plantilla `lca` tal cual.

**05 → Problema: Planets Queries I.**

- **Pista 2 — patrón:** **binary lifting sobre un grafo funcional**.
- **Pista 3 — diseño:** `up[0][v]` es el teletransporte de `v`; `up[k][v] = up[k−1][up[k−1][v]]`; cada consulta `x k` es `lift(x, k)` con `k` hasta `10⁹`: 30 niveles. No hay raíz ni profundidades: solo saltos.

**05 → Problema: Kth Ancestor of a Tree Node.**

- **Pista 2 — patrón:** **binary lifting** con «no existe».
- **Pista 3 — diseño:** usa `−1` como padre de la raíz y propágalo (`up[k][v] = −1` si `up[k−1][v] = −1`); al subir, si llegas a `−1`, devuelve `−1`.

**05 → Problema: Counting Paths.**

- **Pista 2 — patrón:** **diferencias en el árbol** con el LCA.
- **Pista 3 — diseño:** por cada camino `(a, b)`: `+1` en `a` y en `b`, `−1` en `LCA(a, b)` y `−1` en su padre; al final, el valor de cada nodo es la suma de su subárbol (preorden al revés).

**05 → Problema: Fools and Roads.**

- **Pista 2 — patrón:** **diferencias sobre aristas** con el LCA.
- **Pista 3 — diseño:** para aristas: `+1` en `a` y en `b`, `−2` en el LCA; la suma del subárbol de `v` es el número de caminos que usan la arista de `v` a su padre. Responde en el orden de entrada de las aristas.

**05 → Problema: Tree Queries.**

- **Pista 2 — patrón:** **ancestros** respecto del nodo más profundo.
- **Pista 3 — diseño:** sustituye cada nodo de la consulta por su padre (la raíz se queda); la respuesta es `YES` si todos son ancestros del más profundo, comprobado con `tin`/`tout`.

**05 → Problema: Minimum spanning tree for each edge.**

- **Pista 2 — patrón:** **MST** + **máximo en el camino** con *binary lifting*.
- **Pista 3 — diseño:** calcula el MST con Kruskal ([`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)); para cada arista `(u, v, w)`, la respuesta es `peso(MST) − max(camino u–v en el MST) + w`, con el máximo por saltos. Sumas en 64 bits.

---

# 06 — Técnicas sobre árboles

**06 → 1.** ¿Qué es un centroide, y por qué todo árbol tiene al menos uno? 🟢

⏱️ **30 segundos.** Un nodo cuya eliminación deja componentes de como mucho `n/2` nodos. Existe siempre: desde cualquier nodo, se baja hacia el subárbol de más de `n/2` mientras lo haya, y nunca hace falta volver.

🗣️ **2 minutos.** Si en `c` hay un hijo con más de `n/2`, se baja a él; desde él, lo que queda «arriba» es menos de `n/2`, así que el problema solo puede estar en otro hijo suyo. Como el tamaño del subárbol actual baja en cada paso, el proceso termina en un nodo sin hijos grandes ni parte de arriba grande: un centroide.

🔬 **El detalle.** Un árbol tiene uno o dos centroides; si tiene dos, son adyacentes y cada uno deja exactamente `n/2` del lado del otro.

**06 → 2.** ¿Qué cambia en la suma de distancias al mover la raíz de `p` a su hijo `c`? 🟢

⏱️ **30 segundos.** Los `size[c]` nodos del subárbol de `c` se acercan 1 y los `n − size[c]` restantes se alejan 1: `ans[c] = ans[p] − size[c] + (n − size[c])`.

🗣️ **2 minutos.** Para cualquier nodo `x`, el camino de `c` a `x` y el de `p` a `x` solo difieren en la arista `p–c`: si `x` está en el subárbol de `c`, el camino desde `c` es un paso más corto; si no, un paso más largo.

🔬 **El detalle.** Con pesos, la arista `p–c` de peso `w` cambia la suma en `w · (n − 2·size[c])`.

**06 → 3.** ¿Qué es una arista pesada en HLD? 🟢

⏱️ **30 segundos.** La arista de un nodo al hijo con el subárbol más grande. Las demás son ligeras.

🗣️ **2 minutos.** Las aristas pesadas forman cadenas que bajan de un nodo a una hoja; cada nodo está en exactamente una cadena. HLD numera los nodos para que cada cadena ocupe un tramo contiguo de un arreglo.

🔬 **El detalle.** Con empates de tamaño, cualquiera de los hijos más grandes vale.

**06 → 4.** Calcula con *rerooting* la suma de distancias desde 5 en T a partir de la de 2. 🟡

⏱️ **30 segundos.** `ans[5] = ans[2] − size[5] + (n − size[5]) = 10 − 2 + 5 = 13`.

🗣️ **2 minutos.** Desde 5, los nodos de su subárbol (5 y 7) están un paso más cerca que desde 2, y los otros cinco (1, 2, 3, 4, 6) un paso más lejos: `10 − 2 + 5 = 13`. Comprobación directa: desde 5, las distancias son 7:1, 2:1, 4:2, 1:2, 3:3, 6:4, suma 13.

🔬 **El detalle.** El valor de 2 (10) es el mínimo de T: 2 es el centroide, y el centroide minimiza la suma de distancias.

**06 → 5.** ¿Por qué en *small-to-large* hay que intercambiar los conjuntos en `O(1)` y no copiarlos? 🟡

⏱️ **30 segundos.** Porque copiar el conjunto grande cuesta su tamaño, y el análisis `O(n log n)` cuenta solo los elementos del pequeño. Si se copia el grande, en una cadena se copia todo en cada nodo: `O(n²)`.

🗣️ **2 minutos.** El argumento de §2 dice que cada elemento cambia de conjunto `log n` veces **si solo se mueven los del menor**. El conjunto grande tiene que «heredarse» sin tocar sus elementos: `std::swap` de dos `std::set` es `O(1)` (intercambia punteros internos), y en Java o Python se intercambian referencias.

🔬 **El detalle.** En C++, `s[p] = s[v]` copia; `s[p] = std::move(s[v])` o `swap` no.

**06 → 6.** ¿Qué diferencia hay entre el centro de un árbol y su centroide? Da un árbol donde no coincidan. 🟡

⏱️ **30 segundos.** El centro minimiza la mayor distancia a los demás; el centroide minimiza el mayor componente al quitarlo. En una escoba —un camino `1-2-3-4-5` con seis hojas colgadas de 1—, el centroide es 1 y el centro está en el camino, hacia el medio del diámetro (2 o 3).

🗣️ **2 minutos.** El centro depende de las distancias (el punto medio del diámetro); el centroide, de los tamaños. En la escoba hay muchas hojas cerca de 1, así que quitar 1 deja componentes pequeños; pero el diámetro va de una hoja a 5, y su punto medio está más lejos de 1.

🔬 **El detalle.** El centroide también minimiza la suma de distancias a todos los nodos, mientras que el centro minimiza la máxima.

**06 → 7.** ¿Por qué un camino a la raíz cruza como mucho `log₂ n` aristas ligeras? 🟡

⏱️ **30 segundos.** Porque al bajar por una arista ligera, el tamaño del subárbol al menos se divide por dos: el hijo ligero tiene como mucho la mitad del subárbol del padre (si no, sería el pesado).

🗣️ **2 minutos.** Si el hijo ligero `c` de `v` tuviera más de `size[v]/2`, el pesado tendría al menos tanto, y entre los dos pasarían de `size[v]`. Así que, subiendo desde un nodo hacia la raíz, cada arista ligera al menos duplica el tamaño; como no puede pasar de `n`, hay como mucho `log₂ n` aristas ligeras.

🔬 **El detalle.** Entre dos aristas ligeras, el camino va por una cadena pesada: por eso el camino se parte en `O(log n)` tramos.

**06 → 8.** Demuestra que en *small-to-large* cada elemento se mueve como mucho `log₂ n` veces. 🟠

⏱️ **30 segundos.** Al moverse, un elemento pasa del conjunto menor a la unión, que tiene al menos el doble de tamaño. Su conjunto se duplica cada vez que se mueve, y no puede pasar de `n`: como mucho `log₂ n` movimientos.

🗣️ **2 minutos.** Sea `a ≤ b` el tamaño de los dos conjuntos que se fusionan; el elemento está en el de tamaño `a` (si no, no se mueve). Después está en uno de tamaño `a + b ≥ 2a`. Tras `t` movimientos, su conjunto tiene al menos `2ᵗ` elementos, así que `t ≤ log₂ n`. Sumando sobre los `n` elementos: `O(n log n)` movimientos.

🔬 **El detalle.** Es el mismo argumento de la unión por tamaño en Union-Find (`08/04`).

**06 → 9.** Demuestra que la descomposición en centroides tiene profundidad `O(log n)`. 🟠

⏱️ **30 segundos.** Cada componente de un nivel tiene como mucho la mitad que su componente padre, porque el centroide deja componentes de `≤ n/2`. Tras `k` niveles, `≤ n/2ᵏ`, así que hay como mucho `⌊log₂ n⌋ + 1` niveles.

🗣️ **2 minutos.** Por inducción: el componente del nivel 0 tiene `n` nodos; si uno del nivel `k` tiene `m` nodos, su centroide deja componentes de `≤ m/2` para el nivel `k + 1`. Un componente no vacío tiene al menos un nodo: `n/2ᵏ ≥ 1` da `k ≤ log₂ n`.

🔬 **El detalle.** Como cada nodo está en un componente por nivel, la suma de los tamaños de todos los componentes es `O(n log n)`: eso es lo que cuesta construir la descomposición.

**06 → 10.** Compara cómo harías *small-to-large* en C++, Java y Python, y qué coste tiene el conjunto en cada uno. 🟠

⏱️ **30 segundos.** C++: `std::set` (o `std::unordered_set`) con `std::swap`, `O(n log² n)` u `O(n log n)` esperado. Java: `HashSet` con intercambio de referencias y `addAll`, `O(n log n)` esperado. Python: `set` con intercambio de referencias y `|=`.

🗣️ **2 minutos.** En los tres, la clave es el intercambio en `O(1)`. Con conjuntos ordenados, cada inserción es `O(log n)` y el total `O(n log² n)`, que con `n = 2·10⁵` sigue entrando. En Python, la constante de las inserciones y el recorrido iterativo pesan; `|=` corre en C y ayuda.

🔬 **El detalle.** Si los valores son pequeños o se comprimen, un arreglo de frecuencias por subárbol con la técnica *DSU on tree* (Sack) evita los conjuntos.

**06 → 11.** ¿Cómo cuentas los caminos de longitud exactamente `k` que pasan por un centroide sin contar dos veces los que bajan por el mismo hijo? 🟠

⏱️ **30 segundos.** Se procesan los subárboles del centroide uno a uno: para cada uno, se recogen sus profundidades, se combinan con un arreglo de cuentas de las profundidades de los subárboles **anteriores** (`cnt[k − d]`), y solo después se añaden al arreglo.

🗣️ **2 minutos.** Un camino por el centroide une dos nodos de subárboles distintos (o el centroide con un nodo). Combinando cada subárbol solo con los anteriores, cada par se cuenta una vez y nunca con dos nodos del mismo subárbol, que no pasan por el centroide. El centroide aporta `cnt[0] = 1`. El arreglo se limpia hasta la profundidad máxima usada, no entero, para mantener el `O(tamaño)` por componente.

🔬 **El detalle.** La alternativa «contar todo y restar lo de cada subárbol» también funciona, pero es más fácil equivocarse con las profundidades desplazadas.

**06 → 12.** ¿Cómo haces *rerooting* para «la distancia al nodo más lejano», donde la corrección no es una suma? 🔴

⏱️ **30 segundos.** Guardando para cada nodo las dos mayores alturas hacia abajo por hijos **distintos**, y calculando `up[c]`, la mayor distancia saliendo de `c` hacia su padre: `up[c] = 1 + max(up[p], mejor altura de p por un hijo distinto de c)`. La respuesta de `c` es `max(down1[c], up[c])`.

🗣️ **2 minutos.** El máximo no se puede «deshacer» como una suma: al pasar a `c`, hay que saber cuál sería la mejor rama de `p` sin la de `c`. Con la mejor y la segunda mejor, si la mejor de `p` pasa por `c`, se usa la segunda. Es un recorrido de abajo arriba para `down1`, `down2` y un recorrido de arriba abajo para `up`.

🔬 **El detalle.** La alternativa general es guardar, para cada nodo, prefijos y sufijos de las contribuciones de sus hijos, que sirve para cualquier operación asociativa.

**06 → 13.** ¿Por qué una consulta de camino con HLD cuesta `O(log² n)` y no `O(log n)`, y cuándo se puede bajar? 🔴

⏱️ **30 segundos.** Porque el camino se parte en `O(log n)` tramos y cada tramo es una consulta al segment tree de `O(log n)`. Se puede bajar a `O(log n)` en casos concretos: sin actualizaciones, con prefijos por cadena; o con estructuras amortizadas como el *link-cut tree*.

🗣️ **2 minutos.** El tramo de una cadena completa hasta su cabeza es un prefijo de la cadena; si no hay actualizaciones, un prefijo precalculado lo da en `O(1)`, y solo el primer y el último tramo necesitan consulta: `O(log n)`. Con actualizaciones, el *link-cut tree* ([`07/07`](07-arboles-dinamicos.md)) da `O(log n)` amortizado por operación.

🔬 **El detalle.** En la práctica, `log² n` con `n = 2·10⁵` son unas 300 operaciones por consulta: suele entrar.

**06 → Problema: La mejor sede.**

- **Pista 2 — patrón:** **rerooting** de la suma de distancias.
- **Pista 3 — diseño:** preorden iterativo desde 1, tamaños y `down` al revés, y propagación `ans[c] = ans[p] − size[c] + (n − size[c])`; el mínimo y su ciudad. 64 bits.

**06 → Problema: Colores de cada rama.**

- **Pista 2 — patrón:** **small-to-large** con conjuntos.
- **Pista 3 — diseño:** preorden al revés; cada nodo añade su color, anota el tamaño de su conjunto y lo fusiona en el del padre intercambiando para mover siempre el menor.

**06 → Problema: Minimum Height Trees.**

- **Pista 2 — patrón:** **centro del árbol** quitando hojas por capas.
- **Pista 3 — diseño:** cola con las hojas; quita una capa entera cada vez, bajando el grado de sus vecinos y metiendo los nuevos de grado 1; cuando quedan uno o dos nodos, esos son las raíces.

**06 → Problema: Finding a Centroid.**

- **Pista 2 — patrón:** **centroide** bajando hacia el subárbol grande.
- **Pista 3 — diseño:** tamaños de subárbol desde una raíz (iterativo); desde la raíz, baja al hijo con `2·size > n` mientras exista.

**06 → Problema: Path Queries.**

- **Pista 2 — patrón:** **Euler + Fenwick** para la suma de la raíz a cada nodo.
- **Pista 3 — diseño:** cambiar el valor de `v` en `δ` suma `δ` a todos los nodos de su subárbol: suma por rango `[tin[v], tout[v]]` en un Fenwick de diferencias; la consulta es una consulta puntual en `tin[v]`. 64 bits.

**06 → Problema: Tree with Maximum Cost.**

- **Pista 2 — patrón:** **rerooting** con pesos de nodo.
- **Pista 3 — diseño:** con `S` la suma de los pesos y `sub[c]` la suma del subárbol de `c`, al mover la raíz de `p` a `c` el coste cambia en `S − 2·sub[c]`; calcula el coste desde la raíz 1 y propaga. 64 bits.

**06 → Problema: Ciel the Commander.**

- **Pista 2 — patrón:** **profundidad en el árbol de centroides**.
- **Pista 3 — diseño:** construye la descomposición; la letra de cada nodo es `'A' + nivel` en el árbol de centroides. Con `n ≤ 10⁵`, el nivel máximo es 16: siempre cabe en 26 letras.

**06 → Problema: Lomsat gelral.**

- **Pista 2 — patrón:** **small-to-large** con mapas de frecuencia.
- **Pista 3 — diseño:** por subárbol, un mapa color→frecuencia, la frecuencia máxima y la suma de los colores que la alcanzan; al fusionar el menor en el mayor, actualiza los tres. Respuestas en 64 bits.

**06 → Problema: Fixed-Length Paths I.**

- **Pista 2 — patrón:** **centroides** con un arreglo de cuentas por profundidad.
- **Pista 3 — diseño:** en cada centroide, recorre sus subárboles uno a uno; para cada profundidad `d ≤ k` del subárbol actual, suma `cnt[k − d]` de los anteriores; después añade sus profundidades. Limpia `cnt` solo hasta la profundidad usada.

**06 → Problema: Path Queries II.**

- **Pista 2 — patrón:** **HLD + segment tree** de máximos.
- **Pista 3 — diseño:** DFS para tamaños e hijo pesado, otro DFS que numera visitando primero el hijo pesado y anota la cabeza de cada cadena; la consulta sube por cadenas desde el más profundo de los dos hasta que comparten cadena, consultando el máximo de cada tramo.

**06 → Problema: Fixed-Length Paths II.**

- **Pista 2 — patrón:** **centroides** con cuentas por **rango** de profundidad.
- **Pista 3 — diseño:** como en la versión I, pero para cada `d` se suman las cuentas de profundidades en `[k₁ − d, k₂ − d]`: con un Fenwick sobre profundidades, o con prefijos y dos punteros si se procesan los subárboles por profundidad creciente.

**06 → Problema: Xenia and Tree.**

- **Pista 2 — patrón:** **árbol de centroides** con la menor distancia a un rojo por centroide.
- **Pista 3 — diseño:** `best[c]` = menor distancia de un nodo rojo del componente de `c` a `c`; al pintar `v`, sube por sus centroides actualizando `best[c] = min(best[c], dist(v, c))`; la consulta de `v` es el mínimo de `best[c] + dist(v, c)` sobre sus centroides. `dist` con LCA.

---

# 07 — Árboles dinámicos

**07 → 1.** ¿Qué operaciones soporta un árbol dinámico? 🟢

⏱️ **30 segundos.** `link(u, v)` (une dos árboles con una arista), `cut(u, v)` (quita una arista) y consultas: si dos nodos están conectados, agregados sobre un camino o un subárbol, cambiar la raíz.

🗣️ **2 minutos.** El conjunto exacto depende de la estructura: el *link-cut tree* se especializa en caminos; el *Euler tour tree*, en componentes y subárboles. Las dos mantienen un **bosque**: nunca hay ciclos.

🔬 **El detalle.** Algunas variantes permiten también actualizar valores de nodos o de aristas, y agregados como el máximo con su posición.

**07 → 2.** ¿Por qué rehacer el preproceso tras cada cambio no escala? 🟢

⏱️ **30 segundos.** Porque cada preproceso (tabla de LCA, tiempos de Euler, cadenas pesadas) cuesta `O(n)` o `O(n log n)`; con `q` cambios, `O(q · n)`, que con `10⁵` de cada son `10¹⁰`.

🗣️ **2 minutos.** Las técnicas estáticas amortizan el preproceso entre muchas consultas. Si el árbol cambia entre consulta y consulta, el preproceso no se amortiza. Los árboles dinámicos pagan `O(log n)` por cambio en lugar de `O(n)`.

🔬 **El detalle.** Si los cambios son pocos (`√q`, por ejemplo), reconstruir por bloques puede bastar: es la idea de la descomposición por raíz del tiempo ([`09/05`](../09-consultas-sobre-rangos/05-raiz-cuadrada-y-mo.md)).

**07 → 3.** Si solo se añaden aristas, ¿qué estructura basta? 🟢

⏱️ **30 segundos.** Union-Find (`08/04`), con `O(α(n))` amortizado por operación.

🗣️ **2 minutos.** Si nunca se corta una arista, las componentes solo se fusionan, que es exactamente lo que hace Union-Find. Consultas de conectividad y tamaño de componente salen directas.

🔬 **El detalle.** Si además hay que responder sobre caminos (el máximo entre `u` y `v`) con solo uniones, se puede construir el bosque final *offline* y usar LCA con agregados.

**07 → 4.** ¿Cómo convierte el tiempo al revés los borrados en inserciones? 🟡

⏱️ **30 segundos.** Se empieza con el grafo en su estado final (sin las aristas que se borran) y se recorren las operaciones hacia atrás: cada borrado, visto al revés, es una inserción, que Union-Find sí sabe hacer.

🗣️ **2 minutos.** Las respuestas se calculan en orden inverso y se guardan; al final se imprimen en el orden original. Funciona si todas las operaciones se conocen al principio y si las consultas dependen solo del estado del grafo en su momento.

🔬 **El detalle.** Si una arista se borra y vuelve a añadirse varias veces, el tiempo al revés no basta: hace falta el *segment tree* sobre el tiempo.

**07 → 5.** ¿Qué diferencia hay entre lo que resuelve un *link-cut tree* y un *Euler tour tree*? 🟡

⏱️ **30 segundos.** El *link-cut tree* responde sobre **caminos** (máximo, suma entre `u` y `v`); el *Euler tour tree*, sobre **componentes y subárboles** (¿conectados?, tamaño, suma del subárbol).

🗣️ **2 minutos.** El *link-cut tree* organiza el bosque en caminos y los guarda en *splays* por profundidad, así que un camino raíz-nodo es una secuencia. El *Euler tour tree* guarda el recorrido de Euler de cada árbol, donde un subárbol es un tramo contiguo. Cada uno hace fácil lo que su representación pone contiguo.

🔬 **El detalle.** Hay variantes del *link-cut tree* que también mantienen agregados de subárboles («*top trees*», o información virtual de los hijos), a costa de más complejidad.

**07 → 6.** ¿Qué es «*offline*» y por qué cambia tanto la dificultad? 🟡

⏱️ **30 segundos.** Que todas las operaciones se conocen antes de responder la primera, y se pueden reordenar o procesar en cualquier orden. *Online*, cada respuesta debe darse antes de leer la siguiente operación.

🗣️ **2 minutos.** *Offline* permite técnicas que no respetan el orden del tiempo: invertirlo, ordenar las consultas por un parámetro, dividir el tiempo en un *segment tree*. Con eso, estructuras simples (Union-Find) resuelven problemas que *online* necesitan árboles dinámicos.

🔬 **El detalle.** Los jueces fuerzan el modo *online* cifrando cada consulta con la respuesta anterior (como en Forced Online Queries Problem).

**07 → 7.** ¿Por qué Union-Find con *rollback* no puede usar compresión de caminos? 🟠

⏱️ **30 segundos.** Porque el *rollback* deshace las últimas uniones restaurando unos pocos punteros, y la compresión de caminos cambia muchos punteros en cada `find`, que habría que guardar y deshacer. Sin compresión, con unión por rango, `find` es `O(log n)` y cada unión cambia un solo puntero.

🗣️ **2 minutos.** El *rollback* guarda en una pila, por cada unión, qué puntero y qué rango cambiaron; deshacer es restaurarlos. La compresión modificaría punteros fuera de esa pila, en operaciones que en principio son de solo lectura, y la estructura quedaría inconsistente al deshacer. La unión por rango sola garantiza árboles de altura `O(log n)` (`08/04`).

🔬 **El detalle.** El coste total pasa de `O(α(n))` a `O(log n)` por operación; en el *segment tree* sobre el tiempo, eso da `O(m log m log n)`.

**07 → 8.** ¿Cómo sirve un *segment tree* sobre el tiempo para la conectividad con borrados *offline*? 🟠

⏱️ **30 segundos.** Cada arista existe durante un intervalo de tiempo; se inserta en los `O(log T)` nodos del *segment tree* que cubren ese intervalo. Un DFS sobre el *segment tree* une las aristas al entrar en un nodo y las deshace al salir; en cada hoja (un instante), Union-Find tiene exactamente las aristas vivas.

🗣️ **2 minutos.** La pila de llamadas del DFS coincide con la pila de *rollback*: lo que se une al entrar se deshace al salir, en orden inverso. Cada arista se une `O(log T)` veces, cada unión cuesta `O(log n)`: total `O(m log T log n)`.

🔬 **El detalle.** La misma técnica (*divide and conquer* sobre el tiempo) sirve para cualquier estructura con operaciones deshacibles, no solo Union-Find.

**07 → 9.** ¿Qué garantiza el `O(log n)` del *link-cut tree*: peor caso o amortizado? ¿De qué estructura lo hereda? 🟠

⏱️ **30 segundos.** Amortizado, en la versión habitual con *splays*: hereda el análisis amortizado del *splay* ([`07/03`](03-arboles-aleatorizados.md)). Con árboles sesgados se obtiene peor caso, pero el código es mucho más largo.

🗣️ **2 minutos.** El análisis de Sleator y Tarjan combina el potencial del *splay* con el número de cambios de camino preferido, que también se acota amortizado: `O(log n)` por `access`. Una operación concreta puede costar más; la suma de `m` operaciones es `O(m log n)`.

🔬 **El detalle.** Para un juez, amortizado basta; para garantías de tiempo real, no.

**07 → 10.** Compara qué ofrecen C++, Java y Python para estos problemas: ¿alguno trae algo en su biblioteca? 🟠

⏱️ **30 segundos.** Ninguno: ni C++, ni Java, ni Python traen árboles dinámicos. C++ trae, con *policy-based*, un `tree` con estadísticos de orden, pero no `link` ni `cut`.

🗣️ **2 minutos.** En concurso hay que escribirlos (de una biblioteca propia) o evitarlos con una solución *offline*. En C++ y Java la implementación con arreglos es razonable; en Python, la constante del *splay* hace difícil entrar en tiempo, y la vía *offline* es casi obligatoria.

🔬 **El detalle.** Fuera de concursos, existen implementaciones en bibliotecas académicas, pero en entrevista basta con saber nombrarlos y decir qué garantizan.

**07 → 11.** ¿Cómo cambia la raíz un *Euler tour tree* sin recorrer el árbol? 🔴

⏱️ **30 segundos.** Rotando la secuencia de Euler: el recorrido de Euler de un árbol es cíclico, y empezar en otro nodo es partir la secuencia en la primera aparición de ese nodo y poner la segunda parte delante. Con un *treap* implícito, dos `split` y un `merge`.

🗣️ **2 minutos.** Si la secuencia guarda aristas dirigidas (`u→v` y `v→u`), un recorrido de Euler desde cualquier raíz es una rotación de cualquier otro. `link(u, v)` cambia la raíz de cada árbol a `u` y a `v` y concatena: `E(u) + (u→v) + E(v) + (v→u)`. `cut(u, v)` parte en las dos apariciones de la arista y une los extremos.

🔬 **El detalle.** `connected(u, v)` es comprobar si los nodos de `u` y `v` están en el mismo *treap*: subir hasta la raíz del *treap* desde cada uno.

**07 → 12.** ¿Por qué la conectividad dinámica en grafos con ciclos es más difícil que en bosques? 🔴

⏱️ **30 segundos.** Porque en un bosque, borrar una arista siempre separa su árbol en dos; en un grafo con ciclos, puede no separar nada, y saber si existe una arista de reemplazo que vuelva a conectar es el problema difícil.

🗣️ **2 minutos.** Holm, de Lichtenberg y Thorup mantienen un bosque de expansión con *Euler tour trees* y, al borrar una arista del bosque, buscan una arista de reemplazo entre las que no están en él, con un sistema de niveles que amortiza la búsqueda: `O(log² n)` amortizado. En un bosque no hay reemplazo posible que buscar.

🔬 **El detalle.** *Offline*, el *segment tree* sobre el tiempo esquiva el problema por completo.

**07 → Problema: Bosque pequeño.**

- **Pista 2 — patrón:** **fuerza bruta** dentro de las restricciones: un recorrido por consulta.
- **Pista 3 — diseño:** listas de adyacencia con conjuntos (para borrar aristas); `link` y `cut` en `O(1)`; `ask` con un BFS o DFS desde `u`: `O(n)` por consulta, `O(n · q) = 4·10⁶`.

**07 → Problema: Red que se rompe.**

- **Pista 2 — patrón:** **tiempo al revés** con Union-Find.
- **Pista 3 — diseño:** empieza con los cables que nunca se rompen unidos; el número de componentes tras la última rotura es el de ese estado; añade los cables rotos en orden inverso, anotando el número de componentes **antes** de cada unión; imprime las respuestas en el orden original.

**07 → Problema: Bricks Falling When Hit.**

- **Pista 2 — patrón:** **tiempo al revés** con Union-Find y un nodo «techo».
- **Pista 3 — diseño:** quita todos los ladrillos golpeados; une los restantes, conectando la fila 0 con un nodo techo; repone los golpes al revés; los ladrillos que caen por un golpe son lo que crece el componente del techo al reponerlo, menos el propio ladrillo.

**07 → Problema: Checking Existence of Edge Length Limited Paths.**

- **Pista 2 — patrón:** **consultas offline** ordenadas por el límite con Union-Find.
- **Pista 3 — diseño:** ordena aristas por peso y consultas por límite; para cada consulta, une las aristas con peso menor que el límite que falten y comprueba si los dos nodos están en la misma componente.

**07 → Problema: Number of Good Paths.**

- **Pista 2 — patrón:** **uniones por orden de valor** con Union-Find.
- **Pista 3 — diseño:** procesa los nodos de menor a mayor valor; une cada uno con sus vecinos de valor `≤`; en cada componente cuenta cuántos nodos tienen el valor actual; cada grupo de `c` iguales aporta `c(c − 1)/2` caminos más los `c` triviales.

**07 → Problema: Dynamic Connectivity.**

- **Pista 2 — patrón:** **segment tree sobre el tiempo** con Union-Find con *rollback*.
- **Pista 3 — diseño:** calcula el intervalo de vida de cada arista; insértala en los nodos del *segment tree* de tiempos que cubren el intervalo; DFS que une al entrar, anota el número de componentes en cada hoja y deshace al salir.

**07 → Problema: Forced Online Queries Problem.**

- **Pista 2 — patrón:** **conectividad offline** sobre las aristas candidatas.
- **Pista 3 — diseño:** cada consulta puede afectar solo a dos aristas posibles (según el último resultado): trata las dos como candidatas en el *segment tree* sobre el tiempo y decide en cada hoja, con el resultado real de la anterior, cuál está viva.

**07 → Problema: Matches Are Not a Child's Play.**

- **Pista 2 — patrón:** **link-cut tree** con colores por camino.
- **Pista 3 — diseño:** el orden de combustión depende de caminos que se «recolorean» al subir un nodo al máximo; el `access` del *link-cut tree* recolorea exactamente esos caminos, y un Fenwick por color cuenta posiciones.

**07 → Problema: Pastoral Oddities.**

- **Pista 2 — patrón:** **paridad de componentes** con divide y vencerás *offline* (o *link-cut tree*).
- **Pista 3 — diseño:** existe solución si todas las componentes tienen tamaño par; la respuesta es monótona en el peso máximo, lo que permite un divide y vencerás sobre las consultas con Union-Find con *rollback* que cuenta componentes impares.

---

# 08 — Simulación

**08 → S1.** ¿Cuántas aristas tiene un árbol de `n` nodos, y qué propiedad de los caminos lo caracteriza? 🟢

⏱️ **30 segundos.** `n − 1` aristas; entre cada par de nodos hay exactamente un camino.

🗣️ **2 minutos.** Conexo y sin ciclos equivale a conexo con `n − 1` aristas, y a camino único entre cada par. Por eso las distancias salen de un recorrido, sin Dijkstra.

🔬 **El detalle.** [`07/01`](01-arboles-y-recorridos.md), §2.

**08 → S2.** ¿Por qué el diámetro se calcula con dos recorridos? 🟡

⏱️ **30 segundos.** Porque el nodo más lejano de cualquier nodo es extremo de un diámetro, y el más lejano de ese extremo es el otro.

🗣️ **2 minutos.** Un recorrido desde cualquier nodo da un extremo `u`; un segundo desde `u` da el otro extremo y la longitud. `Θ(n)` frente a `Θ(n²)` de un recorrido desde cada nodo. Vale con pesos no negativos.

🔬 **El detalle.** `07/01`, §2 y §5; la prueba es la S17.

**08 → S3.** ¿Qué tramo ocupa un subárbol en el recorrido con tiempos de entrada y salida? 🟢

⏱️ **30 segundos.** `[tin[v], tout[v]]`, con `tout[v] = tin[v] + size[v] − 1`.

🗣️ **2 minutos.** El preorden visita `v` y a continuación todo su subárbol antes de salir: los descendientes son contiguos. Con eso, sumas sobre subárboles son sumas sobre tramos.

🔬 **El detalle.** `07/01`, §6.

**08 → S4.** ¿Qué recorrido de un BST da las claves ordenadas? 🟢

⏱️ **30 segundos.** El inorden: izquierdo, nodo, derecho.

🗣️ **2 minutos.** Por la propiedad de BST, todo el subárbol izquierdo es menor que el nodo y todo el derecho mayor; recursivamente, el inorden sale ordenado. Es la base de validar un BST y de encontrar el `k`-ésimo.

🔬 **El detalle.** [`07/02`](02-bst-y-balanceados.md), §2.

**08 → S5.** ¿Qué garantiza un AVL y qué un rojo-negro sobre la altura? 🟡

⏱️ **30 segundos.** AVL: altura `< 1,45 log₂(n + 2)`. Rojo-negro: altura `≤ 2 log₂(n + 1)`.

🗣️ **2 minutos.** El AVL acota la diferencia de alturas en cada nodo; su peor caso son los árboles de Fibonacci. El rojo-negro acota con la altura negra y la regla de no tener dos rojos seguidos. El AVL es más bajo; el rojo-negro rota menos al modificar.

🔬 **El detalle.** `07/02`, §2.

**08 → S6.** ¿Por qué un *treap* es balanceado en esperanza para cualquier orden de inserción? 🟡

⏱️ **30 segundos.** Porque el *treap* es el BST que resultaría de insertar las claves en orden de prioridad, y las prioridades son aleatorias: es un BST aleatorio, independiente del orden real de las operaciones.

🗣️ **2 minutos.** La profundidad esperada de cada nodo es `< 2 ln n`: `xᵢ` es ancestro de `xⱼ` con probabilidad `1/(|i − j| + 1)`. Un adversario que elige el orden de inserción no controla las prioridades.

🔬 **El detalle.** `07/03`, §2.

**08 → S7.** ¿Cuánto cuesta contar las palabras con un prefijo en un *trie*? 🟢

⏱️ **30 segundos.** `O(L)`, con `L` la longitud del prefijo, si cada nodo guarda cuántas palabras pasan por él.

🗣️ **2 minutos.** Se baja por el prefijo y se lee el contador del nodo al que se llega. No depende del número de palabras.

🔬 **El detalle.** [`07/04`](04-tries.md), §3.

**08 → S8.** ¿Por qué el voraz bit a bit da el XOR máximo? 🟡

⏱️ **30 segundos.** Porque el bit `k` vale más que todos los inferiores juntos: asegurar un 1 en el bit más alto posible nunca es peor, sea lo que sea lo de abajo.

🗣️ **2 minutos.** Bajando por el *trie* binario desde el bit más alto, se elige el hijo con el bit contrario al de `x` si existe. Entre dos candidatos que coinciden arriba, el que gana el bit actual gana siempre.

🔬 **El detalle.** `07/04`, §2.

**08 → S9.** ¿Qué fórmula da la distancia entre dos nodos con el LCA? 🟢

⏱️ **30 segundos.** `dist(u, v) = prof(u) + prof(v) − 2 · prof(LCA(u, v))`.

🗣️ **2 minutos.** El camino sube de `u` al LCA y baja a `v`. Con pesos, se usan las distancias a la raíz.

🔬 **El detalle.** [`07/05`](05-lca.md), §1.

**08 → S10.** ¿Cuándo usarías *rerooting* y cuándo *small-to-large*? 🟡

⏱️ **30 segundos.** *Rerooting* cuando hay que dar una respuesta para cada nodo como raíz; *small-to-large* cuando hay que responder algo sobre el conjunto de valores de cada subárbol.

🗣️ **2 minutos.** El *rerooting* corrige la respuesta al mover la raíz por una arista; el *small-to-large* fusiona conjuntos de hijos moviendo siempre el menor. Si la pregunta sobre el subárbol es una suma o un mínimo, ni siquiera hace falta *small-to-large*: basta el tramo de Euler.

🔬 **El detalle.** `07/06`, §7.

**08 → S11.** ¿Cuál es la profundidad de la descomposición en centroides, y por qué? 🟡

⏱️ **30 segundos.** `⌊log₂ n⌋ + 1` niveles, porque cada componente tiene como mucho la mitad que su componente padre.

🗣️ **2 minutos.** El centroide deja componentes de `≤ n/2`; repitiendo, tras `k` niveles quedan `≤ n/2ᵏ` nodos por componente.

🔬 **El detalle.** `07/06`, §2.

**08 → S12.** Tu DFS recursivo en Java da `StackOverflowError` en el caso 12 y pasa los demás. ¿Qué ha pasado y qué cambias? 🟠

⏱️ **30 segundos.** El árbol del caso 12 es profundo (probablemente una cadena) y la recursión tiene profundidad `n`. Se cambia a un recorrido iterativo con pila explícita.

🗣️ **2 minutos.** La pila de Java por defecto no admite cientos de miles de marcos. El preorden iterativo da el orden y los padres, y recorriéndolo al revés se hacen los cálculos de abajo arriba. Lanzar el cálculo en un `Thread` con pila grande es un parche que funciona en algunos jueces.

🔬 **El detalle.** `07/01`, §4.

**08 → S13.** Usas `std::lower_bound(s.begin(), s.end(), x)` sobre un `std::set` y da TLE. ¿Por qué? 🟠

⏱️ **30 segundos.** Porque los iteradores de `std::set` no son de acceso aleatorio: el algoritmo genérico avanza nodo a nodo, `O(n)` por llamada. Hay que usar `s.lower_bound(x)`.

🗣️ **2 minutos.** `std::lower_bound` hace `O(log n)` comparaciones pero `O(n)` avances de iterador sobre un árbol. La función miembro baja por el rojo-negro.

🔬 **El detalle.** `05/04`, §6.

**08 → S14.** «Un BST es `O(log n)`.» ¿Qué le respondes a un entrevistador? 🟠

⏱️ **30 segundos.** Que es `O(h)`: con claves ordenadas, `h = n − 1` y es una lista. Solo un BST balanceado (AVL, rojo-negro, *treap*) garantiza `O(log n)`.

🗣️ **2 minutos.** La altura depende del orden de inserción. Las bibliotecas usan rojo-negros precisamente para que el orden no importe.

🔬 **El detalle.** `07/02`, §1.

**08 → S15.** Te piden un mapa ordenado en Python, sin bibliotecas externas. ¿Qué haces? 🟠

⏱️ **30 segundos.** Depende de las operaciones: con pocas inserciones, una lista ordenada con `bisect`; si solo hace falta el mínimo, un montículo con borrado perezoso; si se conocen los valores de antemano, un Fenwick sobre valores comprimidos; si no, un *treap* propio.

🗣️ **2 minutos.** Python no tiene mapa ordenado en la biblioteca estándar. `insort` es `O(n)` por inserción, que con `10⁵` inserciones aún suele entrar por ser una copia en C; con `10⁶`, no. El *treap* es el árbol balanceado más corto de escribir.

🔬 **El detalle.** `07/02`, pregunta 11; `07/03`, §3.

**08 → S16.** El enunciado borra aristas de un bosque y pregunta si dos nodos están conectados. ¿Qué preguntas antes de elegir estructura? 🟠

⏱️ **30 segundos.** Si las operaciones se conocen de antemano (*offline*) o hay que responder una a una (*online*). *Offline*, el tiempo al revés o el *segment tree* sobre el tiempo con Union-Find bastan; *online*, hace falta un árbol dinámico.

🗣️ **2 minutos.** También si solo se borran o si se borran y se añaden: si solo se borran, el tiempo al revés convierte todo en uniones. Y las restricciones: con `n, q ≤ 2000`, un recorrido por consulta basta.

🔬 **El detalle.** `07/07`, §5.

**08 → S17.** Demuestra que el nodo más lejano de cualquier nodo es extremo de un diámetro. 🔴

⏱️ **30 segundos.** Sea `a–b` un diámetro y `u` el más lejano de `s`. Si `s–u` toca `a–b`, el camino de `u` al extremo del lado contrario mide al menos `D`; si no lo toca, se construye un camino de más de `D`: contradicción.

🗣️ **2 minutos.** Con `x` el primer vértice de `s–u` en `a–b`, `d(x, u) ≥ d(x, a)` y `d(x, u) ≥ d(x, b)` porque `u` es el más lejano; según el lado por el que el camino `x–u` sale de `a–b`, `u` y el extremo contrario están a distancia `≥ D`. Si `s–u` no toca `a–b`, el camino `a–x–w–u` mide `D + 2·d(x, w) > D`.

🔬 **El detalle.** `07/01`, §2 y pregunta 8.

**08 → S18.** Demuestra que en *small-to-large* cada elemento se mueve como mucho `log₂ n` veces. 🔴

⏱️ **30 segundos.** Cada vez que un elemento se mueve, pasa del conjunto menor a la unión, de al menos el doble de tamaño. Como no puede pasar de `n`, se mueve como mucho `log₂ n` veces.

🗣️ **2 minutos.** Si los conjuntos tienen tamaños `a ≤ b` y el elemento está en el de `a`, tras moverse está en uno de tamaño `a + b ≥ 2a`. Tras `t` movimientos, su conjunto tiene `≥ 2ᵗ` elementos.

🔬 **El detalle.** `07/06`, §2 y pregunta 8.

**08 → Problema: Punto de encuentro.**

- **Pista 2 — patrón:** **LCA de los pares**: el óptimo es el más profundo de `LCA(a, b)`, `LCA(a, c)` y `LCA(b, c)`.
- **Pista 3 — diseño:** *binary lifting*; el punto de reunión es el LCA par más profundo; la suma de distancias es `(d(a, b) + d(a, c) + d(b, c)) / 2`. Recorridos iterativos por si es una cadena.

**08 → Problema: Contraseñas fuertes.**

- **Pista 2 — patrón:** **trie binario** con el voraz desde el bit más alto.
- **Pista 3 — diseño:** inserta las `n` claves en un *trie* de 30 bits; cada consulta baja buscando el bit contrario. `O((n + q) · 30)`.

**08 → Problema: Ruta del parque.**

- **Pista 2 — patrón:** **diámetro** con dos recorridos.
- **Pista 3 — diseño:** BFS desde 1, el más lejano `u`; BFS desde `u`, la mayor distancia es la respuesta.

**08 → Problema: Mediana del árbol.**

- **Pista 2 — patrón:** **inorden** de un BST.
- **Pista 3 — diseño:** inorden iterativo (el árbol puede ser una cadena) parando en la posición `⌊(n − 1)/2⌋`.

**08 → Problema: Same Tree.**

- **Pista 2 — patrón:** **recorrido simultáneo** de los dos árboles.
- **Pista 3 — diseño:** dos nulos son iguales; un nulo y un nodo, no; dos nodos, si sus valores coinciden y sus subárboles izquierdos y derechos son iguales.

**08 → Problema: Invert Binary Tree.**

- **Pista 2 — patrón:** **intercambio de hijos** en todos los nodos.
- **Pista 3 — diseño:** cualquier recorrido (preorden, por niveles) que intercambie `left` y `right` de cada nodo.

**08 → Problema: Diameter of Binary Tree.**

- **Pista 2 — patrón:** **altura en postorden** y la suma de las dos ramas.
- **Pista 3 — diseño:** para cada nodo, la altura de cada hijo; el mejor camino que tiene ese nodo como punto más alto mide `altura(izq) + altura(der)` en aristas; guarda el máximo.

**08 → Problema: Balanced Binary Tree.**

- **Pista 2 — patrón:** **postorden** que devuelve la altura o una marca de desequilibrio.
- **Pista 3 — diseño:** devuelve `−1` si un subárbol está desequilibrado; si no, su altura; un nodo es correcto si los dos hijos lo son y sus alturas difieren como mucho en 1.

**08 → Problema: Path Sum III.**

- **Pista 2 — patrón:** **prefijos con un mapa** sobre el camino de la raíz al nodo actual.
- **Pista 3 — diseño:** DFS con la suma de la raíz al nodo; cuenta cuántas veces apareció `suma − objetivo` en los ancestros (mapa de prefijos, [`04/03`](../04-secuencias/03-kadane-y-subarreglos.md)); al volver, quita la suma actual del mapa.

**08 → Problema: Tree Distances II.**

- **Pista 2 — patrón:** **rerooting** de la suma de distancias.
- **Pista 3 — diseño:** tamaños de subárbol y suma de distancias desde la raíz con un preorden al revés; propaga `ans[c] = ans[p] − size[c] + (n − size[c])`. 64 bits.
