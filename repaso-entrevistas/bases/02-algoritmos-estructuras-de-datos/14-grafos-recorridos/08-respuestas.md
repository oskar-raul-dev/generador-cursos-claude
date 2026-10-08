# Respuestas — bloque 14: Grafos: recorridos

> Solucionario del bloque `14`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--representaciones-y-su-coste) · [02](#02--bfs) · [03](#03--dfs) · [04](#04--orden-topológico-y-dp-sobre-dag) · [05](#05--componentes-fuertemente-conexas-y-2-sat) · [06](#06--puentes-puntos-de-articulación-y-euler) · [07](#07--simulación)

---

# 01 — Representaciones y su coste

**01 → 1.** ¿Qué dice el lema de los grados y cómo se prueba? 🟢

⏱️ **30 segundos.** En un grafo no dirigido, la suma de los grados es `2m`. Cada arista `{u, v}` suma 1 al grado de `u` y 1 al de `v`.

🗣️ **2 minutos.** Contando pares (vértice, arista incidente) de dos maneras: por vértices da `Σ deg(v)`; por aristas, cada una tiene dos extremos, `2m`. En un dirigido, la suma de los grados de salida y la de entrada valen `m` cada una.

🔬 **El detalle.** Un bucle `v — v` suma 2 al grado de `v`, y el lema sigue valiendo con ese convenio.

**01 → 2.** ¿Cuánta memoria usan las listas de adyacencia y la matriz? 🟢

⏱️ **30 segundos.** Listas: `Θ(n + m)`. Matriz: `Θ(n²)`.

🗣️ **2 minutos.** Las listas guardan un arreglo de `n` cabeceras y una entrada por arista (dos en un no dirigido). La matriz guarda una celda por par, haya arista o no: con `n = 2·10⁵`, `4·10¹⁰` celdas.

🔬 **El detalle.** Con un `bitset`, la matriz baja a `n²/8` bytes: con `n = 5 000`, unos 3 MB.

**01 → 3.** ¿Cuántas entradas tiene la lista de adyacencia de un grafo no dirigido con `m` aristas? 🟢

⏱️ **30 segundos.** `2m`: cada arista aparece en la lista de sus dos extremos.

🗣️ **2 minutos.** Es el lema de los grados: la lista de `v` tiene `deg(v)` entradas y la suma de los grados es `2m`. Por eso un arreglo de aristas de una estrella hacia delante no dirigida se dimensiona a `2m`.

🔬 **El detalle.** Con bucles, cada uno aparece dos veces en la lista de su vértice si se añade en los dos sentidos; hay que decidir si se quiere.

**01 → 4.** ¿Qué es un grafo implícito? Da un ejemplo. 🟢

⏱️ **30 segundos.** Un grafo que no se guarda: sus vecinos se calculan al vuelo. Ejemplo: una rejilla, donde los vecinos de `(r, c)` son las cuatro casillas adyacentes libres.

🗣️ **2 minutos.** Otros: los estados de un puzzle (cada movimiento es una arista), las configuraciones de un candado de cuatro ruedas, o `(posición, llaves)` en un laberinto. Solo hace falta la función de vecinos y una estructura de visitados.

🔬 **El detalle.** Si los estados no caben en un arreglo, los visitados van en un hash; la codificación del estado en un entero lo abarata.

**01 → 5.** ¿En qué se diferencian un grafo denso y uno disperso, y cuál es el habitual en los jueces? 🟡

⏱️ **30 segundos.** Denso: `m = Θ(n²)`. Disperso: `m` del orden de `n`. En los jueces casi siempre disperso, con `n, m ≤ 2·10⁵`.

🗣️ **2 minutos.** La densidad decide la representación: en un denso, la matriz no desperdicia (casi todas las celdas son aristas) y da consultas `O(1)`; en un disperso, la matriz es casi toda ceros y las listas ocupan lo justo.

🔬 **El detalle.** Algunos algoritmos tienen versiones distintas para cada caso: Dijkstra en `O(n²)` sin montículo es mejor en grafos densos ([`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md)).

**01 → 6.** ¿Cuándo prefieres la lista de aristas a las listas de adyacencia? 🟡

⏱️ **30 segundos.** Cuando el algoritmo recorre las aristas en bloque y no necesita los vecinos de un vértice: Kruskal (las ordena por peso) y Bellman-Ford (las relaja todas en cada ronda).

🗣️ **2 minutos.** La lista de aristas es lo más simple de leer y ordenar, y ocupa `Θ(m)`. Para BFS, DFS o Dijkstra no sirve: encontrar los vecinos de `u` costaría `O(m)`.

🔬 **El detalle.** Se puede pasar de lista de aristas a estrella hacia delante en `Θ(n + m)` con un conteo por origen.

**01 → 7.** Compara cómo representas listas de adyacencia en C++, Java y Python, y qué cuesta cada forma con `m = 10⁶`. 🟡

⏱️ **30 segundos.** C++: `vector<vector<pair<int,long long>>>`. Java: `List<long[]>[]` o la estrella hacia delante con arreglos de primitivos. Python: lista de listas de tuplas.

🗣️ **2 minutos.** En C++, los vectores son contiguos y el coste es pequeño. En Java, cada `long[]` o `Integer` es un objeto con cabecera de 16 bytes: con `m = 10⁶`, más de 50 MB y presión sobre el recolector; los arreglos planos `head`, `next`, `to`, `w` lo evitan. En Python, una tupla son unos 60 bytes y crear `2·10⁶` cuesta segundos; leer todo de una vez y, si se puede, guardar solo los vecinos sin peso.

🔬 **El detalle.** En C++, la versión CSR (ordenar las aristas por origen y un arreglo de inicios) mejora la localidad incluso frente a `vector<vector<…>>`.

**01 → 8.** ¿Por qué recorrer todos los vecinos de todos los vértices cuesta `Θ(n + m)` y no `Θ(n · m)`? 🟠

⏱️ **30 segundos.** Porque cada vértice recorre solo sus vecinos, y la suma de los grados es `2m`: el total es `n` (visitar cada vértice) más `2m` (cada arista dos veces).

🗣️ **2 minutos.** El error es multiplicar «`n` vértices por hasta `m` vecinos»; pero los grados no son todos `m`: suman `2m`. Es un análisis agregado, como el de la pila monótona.

🔬 **El detalle.** Con la matriz, el mismo recorrido cuesta `Θ(n²)`, porque buscar los vecinos de cada vértice recorre su fila entera.

**01 → 9.** ¿Qué es la estrella hacia delante y qué gana frente a `vector<vector<…>>`? 🟠

⏱️ **30 segundos.** Las listas de adyacencia guardadas en arreglos planos: `head[u]` es la última arista de `u`, `next[e]` la anterior del mismo origen, `to[e]` y `w[e]` su destino y peso.

🗣️ **2 minutos.** Gana memoria (sin objetos ni vectores con capacidad sobrante) y velocidad de construcción: añadir una arista son cuatro asignaciones. En Java es la forma estándar con `m = 10⁶`. Los vecinos salen en orden inverso al de inserción.

🔬 **El detalle.** La variante CSR (ordenar por origen y guardar los inicios) tiene mejor localidad al recorrer, pero exige conocer todas las aristas antes.

**01 → 10.** ¿Cuándo conviene la matriz, aunque ocupe `n²`? 🟠

⏱️ **30 segundos.** Con `n` pequeño (hasta unos pocos miles) y grafo denso, o cuando el algoritmo pregunta mucho «¿hay arista `(u, v)`?».

🗣️ **2 minutos.** Floyd-Warshall trabaja directamente sobre la matriz de distancias; los algoritmos de cliques y triángulos usan la matriz como `bitset` para hacer intersecciones de 64 en 64; y la potencia de la matriz de adyacencia cuenta caminos de longitud `k` ([`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md)).

🔬 **El detalle.** Con `n = 5 000`, la matriz de `bool` son 25 MB y la de `bitset`, 3 MB.

**01 → 11.** ¿Por qué el número de vértices de grado impar es par? 🟠

⏱️ **30 segundos.** Porque la suma de los grados es par (`2m`), y la suma de los grados pares es par: la de los impares también tiene que serlo, y una suma de impares es par solo si hay un número par de ellos.

🗣️ **2 minutos.** Es el corolario clásico del lema de los grados («en una fiesta, el número de personas que dieron la mano un número impar de veces es par»). Se usa en los caminos de Euler ([`14/06`](06-puentes-articulacion-y-euler.md)).

🔬 **El detalle.** En un camino de Euler, los vértices de grado impar son exactamente los dos extremos, o ninguno si es un circuito.

**01 → 12.** Diseña cómo contar los vecinos comunes de `q` pares en un grafo de `10⁵` vértices y di su coste. 🔴

⏱️ **30 segundos.** Listas de adyacencia y un conjunto hash de vecinos por vértice; por consulta, recorro los vecinos del de menor grado y pregunto en el conjunto del otro: `O(min(deg u, deg v))` esperado.

🗣️ **2 minutos.** Construir es `Θ(n + m)`. Si `min(deg u, deg v) ≤ √m`, la consulta cuesta `O(√m)`; el caso caro son dos vértices de grado alto, y de esos hay como mucho `2√m`, así que los pares caros distintos son pocos y se memoizan. Alternativa sin hash: listas ordenadas e intersección con dos punteros, `O(deg u + deg v)`.

🔬 **El detalle.** Con un vértice de grado `10⁵` consultado contra otro igual, el coste explota: se puede precomputar para los vértices «pesados» (grado mayor que `√m`), que son como mucho `2√m`.

**01 → 13.** Tu BFS sobre un grafo no dirigido no llega a vértices que deberían ser alcanzables. ¿Qué miras primero? 🔴

⏱️ **30 segundos.** Que cada arista se añada en los dos sentidos.

🗣️ **2 minutos.** Después: los índices (desde 1 en la entrada y desde 0 en memoria; una arista con `u = n` que se sale o que pisa otro vértice), el número de aristas leídas (un `m` mal leído corta la entrada) y que los visitados se marquen al encolar.

🔬 **El detalle.** Con varios casos de prueba, que las listas se limpien entre casos.

**01 → Problema: El más conectado.**

**Pista 2:** listas de adyacencia: el grado es el tamaño de la lista.

**Pista 3:** recorre los vértices de 1 a `n` quedándote con el primero de grado máximo, y ordena solo su lista; con `n = 1` y `m = 0`, la segunda línea queda vacía.

**01 → Problema: Rejilla con portales.**

**Pista 2:** recorrido (BFS o DFS) sobre el grafo implícito, con las casillas de cada letra agrupadas en una lista de antemano.

**Pista 3:** la primera vez que se usa una letra, se encolan todas sus casillas y se vacía su lista: así cada letra cuesta una vez y el total es `Θ(R · C)`.

**01 → Problema: Triángulos.**

**Pista 2:** el número de triángulos que contienen la arista `(u, v)` es el número de vecinos comunes; sumado sobre todas las aristas, cada triángulo se cuenta tres veces.

**Pista 3:** con las filas como `bitset`, los vecinos comunes son el `popcount` del AND de dos filas: `m · n / 64` operaciones, unos `3·10⁷` en el peor caso. Usa 64 bits para el total.

**01 → Problema: Find the Town Judge.**

**Pista 2:** el juez tiene grado de entrada `n − 1` y de salida 0; basta llevar la diferencia.

**Pista 3:** un solo arreglo: `+1` al destino y `−1` al origen de cada arista; busca el que tiene `n − 1`.

**01 → Problema: Find Center of Star Graph.**

**Pista 2:** el centro está en todas las aristas.

**Pista 3:** compara los extremos de las dos primeras aristas: el que se repite es el centro. `O(1)`.

**01 → Problema: Find if Path Exists in Graph.**

**Pista 2:** listas de adyacencia y un BFS o DFS desde el origen.

**Pista 3:** marca al encolar; también vale un Union-Find ([`08/04`](../08-heaps-y-union-find/04-union-find.md)).

**01 → Problema: Maximal Network Rank.**

**Pista 2:** el rango de un par es `deg(u) + deg(v)`, menos 1 si están unidos.

**Pista 3:** con `n ≤ 100`, grados más una matriz de adyacencia y todos los pares: `Θ(n² + m)`.

**01 → Problema: Minimum Number of Vertices to Reach All Nodes.**

**Pista 2:** en un DAG, los vértices de grado de entrada 0 tienen que estar; y bastan.

**Pista 3:** un arreglo de grados de entrada: la respuesta son los que valen 0. `Θ(n + m)`.

**01 → Problema: Clone Graph.**

**Pista 2:** un mapa de original a copia, y un recorrido que crea la copia la primera vez que ve un nodo.

**Pista 3:** crea la copia al encolar (o al entrar en el DFS) y añade los vecinos copiados después; así los ciclos no duplican.

**01 → Problema: Breadth First Search: Shortest Reach.**

**Pista 2:** listas de adyacencia y BFS; todas las aristas pesan 6.

**Pista 3:** distancia = 6 · niveles; −1 los no alcanzados; omite el origen al imprimir. Ojo con aristas repetidas.

**01 → Problema: Keys and Rooms.**

**Pista 2:** las llaves son las listas de adyacencia; la pregunta es si todo es alcanzable desde 0.

**Pista 3:** un DFS con pila y un contador de visitados; compara con `n`.

**01 → Problema: Building Roads.**

**Pista 2:** el número de carreteras es el número de componentes menos 1.

**Pista 3:** listas de adyacencia y un recorrido iterativo por componente; une un representante de cada una con el de la primera.

---

# 02 — BFS

**02 → 1.** ¿Qué garantiza BFS sobre la primera vez que visita un vértice, y con qué pesos? 🟢

⏱️ **30 segundos.** Que la primera vez que lo descubre lo hace por un camino con el mínimo número de aristas. Vale cuando todas las aristas pesan lo mismo.

🗣️ **2 minutos.** BFS visita por capas: todos los de distancia `d` antes que cualquiera de `d + 1`. Por eso la distancia que asigna al descubrir un vértice es la mínima, y no hace falta corregirla después.

🔬 **El detalle.** Con pesos distintos falla: un camino de dos aristas baratas puede ser mejor que uno de una arista cara. Ahí entra Dijkstra (`15/01`), o 0-1 BFS si los pesos son 0 y 1.

**02 → 2.** ¿Por qué se marca visitado al encolar y no al sacar? 🟢

⏱️ **30 segundos.** Para que cada vértice entre en la cola una sola vez: así el coste es `Θ(n + m)` y la cola no pasa de `n`.

🗣️ **2 minutos.** Marcando al sacar, un vértice no marcado puede encolarse desde cada vecino que se procese antes de que salga: la cola llega a `Θ(m)` entradas, que en un grafo denso son `Θ(n²)`. Las distancias siguen siendo correctas (la primera salida es la buena), pero se pierde tiempo y memoria.

🔬 **El detalle.** En 0-1 BFS y Dijkstra no se puede marcar al encolar: un vértice puede mejorar; allí se relaja con `<` y se ignoran las copias viejas.

**02 → 3.** ¿Cómo se reconstruye el camino mínimo después de un BFS? 🟢

⏱️ **30 segundos.** Guardando `parent[v]` al descubrir `v`, y siguiéndolo desde el destino hasta la fuente; después se invierte.

🗣️ **2 minutos.** Los punteros `parent` forman un árbol de caminos mínimos con raíz en la fuente; el camino del árbol hasta `t` tiene longitud `dist[t]`. En rejillas, se puede guardar la dirección del último movimiento en lugar del padre, y reconstruir las letras `U D L R`.

🔬 **El detalle.** Si se piden todos los caminos mínimos, el árbol no basta: hace falta el DAG de las aristas `u → v` con `dist[v] = dist[u] + 1`.

**02 → 4.** ¿Cómo haces un BFS desde varias fuentes, y qué distancia obtienes? 🟢

⏱️ **30 segundos.** Encolando todas las fuentes con distancia 0 antes de empezar. Se obtiene, para cada vértice, la distancia a la fuente más cercana.

🗣️ **2 minutos.** Es un BFS desde una superfuente ficticia unida a todas: tras sacarla, la cola son las fuentes. Cuesta `Θ(n + m)` sin importar cuántas fuentes haya. Si además se quiere saber cuál es la más cercana, se propaga su identificador como se propaga `parent`.

🔬 **El detalle.** No da la distancia a cada fuente por separado; para eso hacen falta `k` BFS.

**02 → 5.** Enuncia el invariante de la cola en BFS. 🟡

⏱️ **30 segundos.** La cola contiene vértices con distancia `d` seguidos de vértices con distancia `d + 1`, y nada más.

🗣️ **2 minutos.** Al principio solo está la fuente. Cada paso saca un vértice del frente (distancia `d`) y mete al final sus vecinos nuevos con `d + 1`; el invariante se mantiene. Su consecuencia es que los vértices salen en orden no decreciente de distancia.

🔬 **El detalle.** En 0-1 BFS, la cola doble cumple el mismo invariante: por eso es Dijkstra sin montículo.

**02 → 6.** ¿Por qué DFS no sirve para distancias mínimas sin pesos? Da un ejemplo pequeño. 🟡

⏱️ **30 segundos.** Porque DFS llega a cada vértice por el camino que la recursión eligió, no por el más corto, y no lo vuelve a visitar.

🗣️ **2 minutos.** Un triángulo `A–B`, `B–C`, `A–C`: si DFS desde `A` va primero a `B`, llega a `C` desde `B`, con profundidad 2, aunque `C` está a distancia 1. Para corregirlo habría que revisitar vértices cuando se encuentra un camino más corto, y eso es exponencial en el peor caso.

🔬 **El detalle.** En un árbol, DFS sí da las distancias: hay un único camino a cada vértice.

**02 → 7.** ¿Qué cambia en 0-1 BFS respecto de BFS, y por qué un vértice puede salir dos veces? 🟡

⏱️ **30 segundos.** La cola pasa a ser doble: por una arista de 0, el vecino entra por delante; por una de 1, por detrás. Se relaja con `<` en lugar de marcar visitados.

🗣️ **2 minutos.** Un vértice puede mejorar después de encolado: primero se le llega por una arista de 1 (va detrás, con `d + 1`), y luego desde otro vértice de distancia `d` por una de 0 (va delante, con `d`). Queda una copia vieja en la cola, que al salir no relaja nada porque sus vecinos ya tienen distancias al menos tan buenas.

🔬 **El detalle.** Se puede saltar explícitamente guardando la distancia con la que se encoló y comparándola al sacar, como en Dijkstra.

**02 → 8.** ¿Qué cola usas para BFS en C++, Java y Python, y qué error de rendimiento es típico en cada uno? 🟡

⏱️ **30 segundos.** C++: `std::queue` (o `deque`). Java: un `int[]` con cabeza y cola, o `ArrayDeque`. Python: `collections.deque` con `popleft`.

🗣️ **2 minutos.** El error típico de C++ es usar `std::queue<pair<int,int>>` en rejillas grandes sin aplanar (va bien, pero aplanar ahorra). En Java, `LinkedList` o `ArrayDeque<Integer>` con millones de entradas: el boxeo pesa; la cola en `int[]` lo evita. En Python, `list.pop(0)`, que es lineal y vuelve cuadrático el BFS.

🔬 **El detalle.** En JavaScript, `shift()` tiene el mismo problema que `pop(0)`: se usa un arreglo con índice de cabeza ([`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)).

**02 → 9.** Demuestra que BFS asigna a cada vértice su distancia mínima. 🟠

⏱️ **30 segundos.** `dist[v] ≥ δ(v)` porque sigue un camino real. Para `≤`: el `v` mal calculado de menor `δ` tiene un predecesor `w` bien calculado que sale de la cola antes que quien descubrió a `v`; al sacar `w`, `v` recibe como mucho `δ(w) + 1 = δ(v)`.

🗣️ **2 minutos.** La pieza clave es el invariante: los vértices salen en orden de `dist`. Si `v` se descubriera desde un `u` con `dist[u] ≥ δ(v)`, entonces `w` (con `dist[w] = δ(v) − 1 < dist[u]`) habría salido antes y habría descubierto a `v` con la distancia correcta, o `v` ya estaría marcado por alguien con `dist ≤ dist[w]`.

🔬 **El detalle.** Es la prueba de CLRS (lema 22.3 a teorema 22.5), en tres pasos: cota inferior, invariante de la cola y contradicción con el mínimo.

**02 → 10.** Demuestra que 0-1 BFS es correcto relacionándolo con Dijkstra. 🟠

⏱️ **30 segundos.** Dijkstra solo necesita sacar el vértice de menor distancia provisional. En 0-1 BFS la cola doble está siempre ordenada con valores `d` y `d + 1`, así que su frente es ese mínimo.

🗣️ **2 minutos.** Invariante: la cola doble, de frente a final, tiene distancias no decrecientes con diferencia máxima 1. Al sacar `u` con `d` (el mínimo), una arista de 0 produce `d` y entra delante; una de 1 produce `d + 1` y entra detrás: el orden se mantiene. Como Dijkstra con un montículo exacto, cada vértice queda fijado la primera vez que sale.

🔬 **El detalle.** Las copias viejas no rompen nada: salen con una distancia ya superada, y sus relajaciones fallan.

**02 → 11.** En un laberinto con llaves y puertas, ¿cuál es el estado y cuántos estados hay? 🟠

⏱️ **30 segundos.** El estado es `(fila, columna, máscara de llaves)`. Hay `R · C · 2^L` estados con `L` tipos de llave.

🗣️ **2 minutos.** Las puertas no hacen falta en el estado: se abren si la llave está en la máscara. Al pisar una llave, `k | (1 << llave)`; una puerta exige `k >> puerta & 1`. Con `R = C = 30` y 6 llaves, `57 600` estados: un BFS trivial.

🔬 **El detalle.** Si las llaves se gastan al usarse, la máscara ya no basta: hay que contar llaves por tipo, y el estado crece.

**02 → 12.** Te piden el número de caminos mínimos de `s` a `t`. ¿Cómo adaptas BFS y por qué no cuenta de más? 🔴

⏱️ **30 segundos.** Un arreglo `ways` junto a `dist`: al descubrir `v` desde `u`, `ways[v] = ways[u]`; si `v` ya estaba con `dist[v] = dist[u] + 1`, `ways[v] += ways[u]`.

🗣️ **2 minutos.** Cuando se saca `u`, ya están sumadas todas sus formas: todos sus predecesores en caminos mínimos (distancia `dist[u] − 1`) salieron antes. Cada camino mínimo a `v` se cuenta una vez, por su último paso `u → v`, y las aristas entre vértices del mismo nivel no suman nada.

🔬 **El detalle.** El número puede ser exponencial: se trabaja módulo `10⁹ + 7`.

**02 → 13.** Tu BFS en rejilla da TLE con `R = C = 1 000` y el grafo tiene `10⁶` casillas. ¿Qué miras? 🔴

⏱️ **30 segundos.** Que se marque al encolar, la cola (en Python, `deque`; en Java, sin boxeo) y que el grafo no se construya explícitamente.

🗣️ **2 minutos.** Con `10⁶` casillas, un BFS bien escrito son unos `4·10⁶` pasos: tiene que caber. Si no cabe, casi siempre es una de estas: marcar al sacar (la cola crece), `list.pop(0)`, objetos por casilla (pares, `Integer`), o un `if` que vuelve a recorrer la rejilla dentro del bucle (buscar la salida o los portales en cada paso).

🔬 **El detalle.** Aplanar la casilla a `r · C + c` y tener `dist` en un arreglo de una dimensión suele ganar un factor 2–3 en Java y Python.

**02 → Problema: Capas de la red.**

**Pista 2:** BFS desde 1 y un histograma de las distancias.

**Pista 3:** la distancia máxima es como mucho `n − 1`; recorre `dist` contando por valor, y los `-1` aparte.

**02 → Problema: Cuántos caminos mínimos.**

**Pista 2:** BFS que lleva, además de `dist`, el número de caminos mínimos `ways` hasta cada vértice.

**Pista 3:** al mirar la arista `u → v`: si `v` es nuevo, `ways[v] = ways[u]`; si `dist[v] = dist[u] + 1`, suma `ways[u]`; si no, nada. Módulo `10⁹ + 7`.

**02 → Problema: El interruptor.**

**Pista 2:** BFS sobre `(fila, columna, modo)`, con el modo en `{0, 1}`.

**Pista 3:** una casilla `x` se puede pisar en modo 1 y una `o` en modo 0; al entrar en `*`, el modo cambia. Arreglo plano de `2 · R · C` distancias; responde al sacar la primera `T`.

**02 → Problema: Message Route.**

**Pista 2:** BFS desde 1 con `parent`.

**Pista 3:** si `dist[n] = -1`, `IMPOSSIBLE`; si no, imprime `dist[n] + 1` y el camino siguiendo `parent` desde `n`, invertido.

**02 → Problema: Shortest Path in Binary Matrix.**

**Pista 2:** BFS en rejilla con ocho direcciones.

**Pista 3:** si la casilla inicial o la final están bloqueadas, `-1`; la longitud cuenta casillas, no pasos: la distancia de la inicial es 1.

**02 → Problema: Nearest Exit from Entrance in Maze.**

**Pista 2:** BFS desde la entrada; una salida es una casilla vacía del borde.

**Pista 3:** la entrada no cuenta como salida aunque esté en el borde; devuelve la distancia de la primera salida que se saque.

**02 → Problema: Rotting Oranges.**

**Pista 2:** BFS multifuente desde todas las naranjas podridas.

**Pista 3:** la respuesta es la mayor distancia; si queda alguna fresca sin alcanzar, `-1`; si no hay frescas, 0.

**02 → Problema: Open the Lock.**

**Pista 2:** BFS sobre las `10⁴` combinaciones; cada una tiene 8 vecinas.

**Pista 3:** las combinaciones prohibidas se marcan como visitadas de antemano; si `0000` está prohibida, `-1`.

**02 → Problema: Jump Game III.**

**Pista 2:** grafo implícito: de `i` salen aristas a `i + arr[i]` e `i − arr[i]`.

**Pista 3:** BFS o DFS desde `start` con visitados; responde en cuanto encuentres un `arr[i] = 0`.

**02 → Problema: Labyrinth.**

**Pista 2:** BFS desde `A` guardando, en cada casilla, la dirección por la que se llegó.

**Pista 3:** reconstruye desde `B` retrocediendo con la dirección opuesta, e invierte la cadena; con `10⁶` casillas, todo en arreglos planos.

**02 → Problema: Minimum Obstacle Removal to Reach Corner.**

**Pista 2:** 0-1 BFS: entrar en una casilla libre cuesta 0 y en una con obstáculo, 1.

**Pista 3:** cola doble, relajar con `<`; la respuesta es la distancia de la esquina.

**02 → Problema: Minimum Cost to Make at Least One Valid Path in a Grid.**

**Pista 2:** 0-1 BFS: moverse en la dirección de la flecha cuesta 0; en cualquier otra, 1.

**Pista 3:** desde cada casilla, las cuatro direcciones con su coste; cola doble y relajar con `<`.

**02 → Problema: Monsters.**

**Pista 2:** BFS multifuente desde todos los monstruos (su tiempo de llegada a cada casilla) y BFS desde `A`.

**Pista 3:** `A` puede pisar una casilla solo si llega estrictamente antes que cualquier monstruo; gana si alcanza el borde. Reconstruye el camino con las direcciones.

**02 → Problema: Word Ladder.**

**Pista 2:** BFS sobre las palabras; los vecinos son las que difieren en una letra.

**Pista 3:** genera los vecinos cambiando cada posición por las 26 letras y preguntando en un conjunto (o agrupa por patrones `h*t`); el resultado cuenta palabras, no pasos.

**02 → Problema: Shortest Path to Get All Keys.**

**Pista 2:** BFS sobre `(fila, columna, máscara de llaves)`.

**Pista 3:** como mucho 6 llaves: `R · C · 64` estados. Una puerta mayúscula exige su llave en la máscara; termina cuando la máscara está completa.

---

# 03 — DFS

**03 → 1.** ¿Qué significan los colores blanco, gris y negro en un DFS? 🟢

⏱️ **30 segundos.** Blanco: no descubierto. Gris: descubierto y todavía en la pila (no terminó con sus vecinos). Negro: terminado.

🗣️ **2 minutos.** Los grises en cada instante son exactamente el camino del árbol desde la raíz hasta el vértice actual. Por eso una arista a un gris vuelve a un antecesor (ciclo en dirigido) y una arista a un negro va a algo ya cerrado.

🔬 **El detalle.** Con `tin` y `tout` no hace falta un arreglo de color: blanco es `tin = 0`, gris es `tin ≠ 0` y `tout = 0`, negro es `tout ≠ 0`.

**03 → 2.** ¿Cómo cuentas las componentes conexas de un grafo no dirigido? 🟢

⏱️ **30 segundos.** Recorriendo los vértices en orden y lanzando un recorrido (DFS o BFS) desde cada uno sin etiqueta; cada lanzamiento es una componente.

🗣️ **2 minutos.** Cada recorrido etiqueta exactamente lo alcanzable desde su origen, que es su componente. El total es `Θ(n + m)`, porque cada vértice se etiqueta una vez y cada arista se mira dos veces.

🔬 **El detalle.** Con aristas que llegan en línea y preguntas intercaladas, Union-Find (`08/04`) evita recorrer de nuevo.

**03 → 3.** ¿Qué condición indica un ciclo en un grafo no dirigido? 🟢

⏱️ **30 segundos.** Una arista a un vértice ya visitado que no es el padre del actual.

🗣️ **2 minutos.** En un DFS no dirigido solo hay aristas del árbol y de retroceso; la arista de vuelta al padre es la misma arista del árbol vista desde el otro lado, y no es un ciclo. Cualquier otra a un visitado cierra un ciclo con el camino del árbol.

🔬 **El detalle.** Con aristas repetidas, dos aristas entre `u` y su padre sí forman un ciclo de longitud 2: se compara el índice de la arista, no el vértice.

**03 → 4.** ¿Por qué no basta «visitado» para detectar un ciclo en un dirigido? 🟡

⏱️ **30 segundos.** Porque llegar a un vértice ya visitado puede ser llegar por dos caminos distintos a algo terminado, sin ciclo: en D, `A → B → E` y `A → C → E`.

🗣️ **2 minutos.** Un ciclo exige volver a un vértice desde el que se sigue bajando: uno gris, todavía en la pila. Un negro terminó todos sus caminos y ninguno volvía al actual (si volviera, el actual habría sido descubierto desde él). Por eso hacen falta tres estados.

🔬 **El detalle.** Con solo dos estados, el algoritmo diría «ciclo» en cualquier DAG con caminos que confluyen: falla en todos los grafos de dependencias reales.

**03 → 5.** Enuncia el teorema del paréntesis. 🟡

⏱️ **30 segundos.** Los intervalos `[tin, tout]` de dos vértices son disjuntos o uno contiene al otro; y `v` es descendiente de `u` si y solo si el de `v` está dentro del de `u`.

🗣️ **2 minutos.** Se debe a que la pila es LIFO: si `v` se descubre mientras `u` está en la pila, sale antes que `u`; si se descubre con `u` ya fuera, su intervalo empieza después de que el de `u` acabó.

🔬 **El detalle.** Es lo que permite responder «¿es `u` antecesor de `v`?» en `O(1)` en un árbol, con dos comparaciones ([`07/05`](../07-arboles/05-lca.md)).

**03 → 6.** ¿Cómo escribes un DFS iterativo que dé los mismos tiempos que el recursivo? 🟡

⏱️ **30 segundos.** Con una pila de vértices y un índice `it[u]` del próximo vecino por mirar: el vértice se queda en la pila hasta agotar sus vecinos, y sale con su `tout`.

🗣️ **2 minutos.** En cada paso se mira la cima `u`: si le quedan vecinos, se avanza `it[u]` y, si el vecino es blanco, se apila con su `tin`; si no le quedan, se desapila con su `tout`. Es exactamente la recursión, con el «por dónde iba» explícito.

🔬 **El detalle.** La versión «sacar y apilar todos los vecinos» alcanza lo mismo pero cambia el orden y no tiene un instante de salida: no sirve para tiempos, orden topológico ni puentes.

**03 → 7.** ¿Cómo compruebas si un grafo es bipartito, y qué olvida la gente? 🟡

⏱️ **30 segundos.** Propagando dos colores con un recorrido: cada vecino recibe el color contrario, y si una arista une dos del mismo color, no es bipartito. Lo que se olvida: recorrer **todas** las componentes.

🗣️ **2 minutos.** Por componente, la coloración está obligada salvo el intercambio de colores, así que el recorrido la encuentra o encuentra un conflicto. El conflicto es la prueba de un ciclo impar. Coste `Θ(n + m)`.

🔬 **El detalle.** Is Graph Bipartite? de LeetCode trae grafos no conexos justamente para castigar el recorrido desde 0 solo.

**03 → 8.** ¿Qué hace cada lenguaje con un DFS recursivo de profundidad `2·10⁵`, y cómo lo resuelves? 🟡

⏱️ **30 segundos.** C++: suele caber (muchos jueces dan tanta pila como memoria). Java: `StackOverflowError`. Python: `RecursionError` a los 1 000 niveles, y si se sube el límite, puede romper la pila de C.

🗣️ **2 minutos.** La solución que vale en los tres es el DFS iterativo con pila explícita y `it[u]`. En Java, la alternativa es lanzar el código en un `Thread` con pila de 256 MB ([`03/03`](../03-biblioteca-estandar/03-java-colecciones.md)); en Python, no hay alternativa fiable: iterativo.

🔬 **El detalle.** En C++ con `10⁶` niveles y marcos grandes (vectores locales), incluso los jueces generosos pueden fallar; el iterativo nunca.

**03 → 9.** Demuestra que un dirigido tiene ciclo si y solo si el DFS encuentra una arista de retroceso. 🟠

⏱️ **30 segundos.** (⇐) Una arista `u → v` a un gris vuelve a un antecesor: el camino del árbol más la arista es un ciclo. (⇒) Si hay ciclo, su primer vértice descubierto `v` tiene el resto del ciclo blanco; por el camino blanco, su predecesor `u` en el ciclo será descendiente, y `u → v` se examina con `v` gris.

🗣️ **2 minutos.** La dirección difícil es (⇒): hay que garantizar que la arista que cierra el ciclo se examina mientras `v` sigue en la pila. El teorema del camino blanco lo da: todo el ciclo cuelga de `v` en el árbol, así que `u` termina antes que `v`, y al examinar `u → v`, `v` aún es gris.

🔬 **El detalle.** Es el lema 22.11 de CLRS; también prueba que «no hay retroceso» equivale a que el postorden invertido es un orden topológico ([`14/04`](04-orden-topologico.md)).

**03 → 10.** Demuestra que un grafo es bipartito si y solo si no tiene ciclos impares. 🟠

⏱️ **30 segundos.** (⇒) En un bipartito, un ciclo alterna lados y tiene longitud par. (⇐) Coloreando por paridad de profundidad en el DFS, una arista entre dos del mismo color une un vértice con un antecesor a distancia par: cierra un ciclo impar.

🗣️ **2 minutos.** Si no hay ciclos impares, la coloración por paridad no tiene conflictos: las aristas del árbol unen profundidades consecutivas, y las de retroceso unen profundidades de paridad distinta (si fuera igual, habría ciclo impar). Por tanto la coloración es válida.

🔬 **El detalle.** El algoritmo da un certificado en los dos sentidos: la coloración si es bipartito, y el ciclo impar (el camino del árbol más la arista en conflicto) si no.

**03 → 11.** ¿Qué tipos de arista hay en un DFS de un dirigido, y por qué en un no dirigido solo dos? 🟠

⏱️ **30 segundos.** Del árbol (a blanco), de retroceso (a gris), de avance (a negro descendiente) y de cruce (a negro de otra rama). En un no dirigido, solo del árbol y de retroceso.

🗣️ **2 minutos.** En un no dirigido, una arista `{u, v}` con `v` negro ya habría sido examinada desde `v` cuando `u` era blanco o gris: si `u` era blanco, la habría hecho del árbol; si gris, de retroceso. No queda ninguna para avance ni cruce.

🔬 **El detalle.** El avance y el cruce se distinguen con `tin`: avance si `tin[u] < tin[v]`, cruce si no.

**03 → 12.** ¿Cuándo prefieres Union-Find a un DFS para componentes o ciclos? 🟠

⏱️ **30 segundos.** Cuando las aristas llegan una a una y hay preguntas entre medias, o solo interesa la conectividad no dirigida y es más corto de escribir.

🗣️ **2 minutos.** Union-Find responde «¿están conectados?» y «¿esta arista cierra un ciclo?» en casi `O(1)` por operación, sin construir listas. Pero no sirve para ciclos dirigidos, ni da tiempos ni el ciclo en sí (sin más trabajo), ni maneja borrados.

🔬 **El detalle.** Para bipartición en línea, Union-Find con paridad: cada nodo guarda si tiene el mismo color que su raíz.

**03 → 13.** ¿Cómo reconstruyes el ciclo que encontró el DFS? 🔴

⏱️ **30 segundos.** Con `parent`: al encontrar la arista `u → v` a un gris, se sigue `parent` desde `u` hasta `v` y se invierte.

🗣️ **2 minutos.** En el iterativo, la pila misma es el camino del árbol: el ciclo es el tramo de la pila desde `v` hasta la cima. En un no dirigido, igual con la arista a un visitado que no es el padre. Para imprimir un circuito cerrado (como piden los CSES), se repite `v` al final.

🔬 **El detalle.** El ciclo que sale no es necesariamente el más corto: para el más corto, BFS desde cada vértice, `Θ(n · (n + m))`.

**03 → 14.** Cuentas las formas de repartir a `n` personas en dos turnos con conflictos. ¿Cuál es la fórmula? 🔴

⏱️ **30 segundos.** `2^c` módulo `10⁹ + 7`, con `c` el número de componentes, si el grafo es bipartito; 0 si no.

🗣️ **2 minutos.** En cada componente, el turno del primer empleado decide todos los demás: 2 opciones por componente, y las componentes son independientes. Si alguna tiene un ciclo impar, no hay ninguna asignación.

🔬 **El detalle.** Los vértices aislados son componentes: cada uno multiplica por 2.

**03 → Problema: Grupos aislados.**

**Pista 2:** componentes con un recorrido iterativo por vértice sin etiqueta, contando lo que marca.

**Pista 3:** cada recorrido devuelve su tamaño; lleva el número de recorridos y el máximo. Los vértices aislados son componentes de tamaño 1.

**03 → Problema: Repartos en dos turnos.**

**Pista 2:** bipartición por componentes: cada componente bipartita aporta un factor 2.

**Pista 3:** si alguna arista une dos del mismo color, imprime 0; si no, `2^c` módulo `10⁹ + 7` con exponenciación rápida o multiplicando `c` veces.

**03 → Problema: La primera dependencia circular.**

**Pista 2:** la propiedad «hay ciclo con las `k` primeras» es monótona en `k`: búsqueda binaria sobre `k`.

**Pista 3:** cada prueba construye el grafo con las `k` primeras aristas y busca un ciclo con tres colores (o con Kahn, `14/04`): `Θ((n + m) log m)`.

**03 → Problema: Number of Islands.**

**Pista 2:** componentes en rejilla: un recorrido desde cada `1` sin visitar.

**Pista 3:** marca al apilar; con rejillas grandes, iterativo.

**03 → Problema: Max Area of Island.**

**Pista 2:** componentes en rejilla, con el recorrido devolviendo cuántas casillas marca.

**Pista 3:** el máximo de los tamaños; 0 si no hay islas.

**03 → Problema: Is Graph Bipartite?.**

**Pista 2:** bipartición con dos colores.

**Pista 3:** recorre todas las componentes: el grafo no tiene por qué ser conexo.

**03 → Problema: Building Teams.**

**Pista 2:** bipartición por componentes, imprimiendo el color + 1 de cada vértice.

**Pista 3:** si hay conflicto, `IMPOSSIBLE`; con `10⁵` vértices, iterativo.

**03 → Problema: Round Trip.**

**Pista 2:** ciclo en no dirigido: arista a un visitado que no es el padre.

**Pista 3:** reconstruye con `parent` desde el actual hasta el visitado y repite el primero al final; el ciclo tiene al menos 3 ciudades.

**03 → Problema: Round Trip II.**

**Pista 2:** ciclo dirigido con tres colores.

**Pista 3:** al encontrar un gris `v` desde `u`, el ciclo es el tramo de la pila de `v` a `u`, más `v` otra vez; recorre todos los vértices como origen.

**03 → Problema: All Paths From Source to Target.**

**Pista 2:** DFS con vuelta atrás desde 0, guardando el camino actual.

**Pista 3:** en un DAG no hay que marcar visitados: ningún camino repite vértice. Al llegar a `n − 1`, copia el camino.

**03 → Problema: Surrounded Regions.**

**Pista 2:** recorrido desde las `O` del borde: esas y las conectadas a ellas no se capturan.

**Pista 3:** márcalas con un carácter temporal; después, las `O` restantes pasan a `X` y las marcadas vuelven a `O`.

**03 → Problema: Pacific Atlantic Water Flow.**

**Pista 2:** dos recorridos multifuente inversos, uno desde cada océano, subiendo a casillas de altura mayor o igual.

**Pista 3:** la respuesta son las casillas marcadas por los dos.

**03 → Problema: Find Eventual Safe States.**

**Pista 2:** tres colores: un vértice es seguro si su DFS termina (negro) sin encontrar un gris.

**Pista 3:** si encuentras un gris, el vértice actual y todos los de la pila quedan inseguros; devuelve los negros en orden. Alternativa: Kahn sobre el grafo invertido (`14/04`).

**03 → Problema: Detect Cycles in 2D Grid.**

**Pista 2:** ciclo no dirigido en la rejilla, por casillas de la misma letra.

**Pista 3:** recuerda de qué casilla vienes (el padre) y no la cuentes; cualquier otra visitada de la misma letra cierra un ciclo de longitud al menos 4.

**03 → Problema: Roads and Libraries.**

**Pista 2:** en cada componente de tamaño `k`, o una biblioteca por ciudad (`k · c_lib`) o una biblioteca y `k − 1` carreteras.

**Pista 3:** si `c_lib ≤ c_road`, todo bibliotecas; si no, por componente `c_lib + (k − 1) · c_road`. Totales en 64 bits.

---

# 04 — Orden topológico y DP sobre DAG

**04 → 1.** ¿Qué es un orden topológico y cuándo existe? 🟢

⏱️ **30 segundos.** Una permutación de los vértices en la que toda arista va de uno anterior a uno posterior. Existe si y solo si el grafo dirigido no tiene ciclos.

🗣️ **2 minutos.** Un ciclo lo impide, porque cada vértice del ciclo tendría que ir antes que el siguiente y el último antes que el primero. Sin ciclos siempre hay una fuente, se pone primera y se repite con el resto.

🔬 **El detalle.** En un no dirigido la noción no tiene sentido: cada arista va en los dos sentidos.

**04 → 2.** Describe el algoritmo de Kahn. 🟢

⏱️ **30 segundos.** Contar grados de entrada, encolar los de grado 0, y repetir: sacar uno, añadirlo al orden y restar 1 a sus sucesores, encolando los que llegan a 0.

🗣️ **2 minutos.** Cada vértice entra cuando todos sus predecesores ya están en el orden, que es justo la condición del orden topológico. Coste `Θ(n + m)`: cada vértice entra una vez y cada arista se resta una vez.

🔬 **El detalle.** Es la prueba constructiva de que todo DAG tiene orden, convertida en algoritmo.

**04 → 3.** ¿Cómo detecta Kahn que hay un ciclo? 🟢

⏱️ **30 segundos.** Si al vaciarse la cola el orden tiene menos de `n` vértices, hay un ciclo.

🗣️ **2 minutos.** Los vértices que no salen tienen siempre grado de entrada positivo contando solo los que quedan; si ese resto no tuviera ciclo, tendría una fuente y Kahn la habría sacado. Por tanto el resto contiene un ciclo.

🔬 **El detalle.** No devuelve el ciclo; y los vértices que quedan no son solo los del ciclo, sino también todo lo que depende de él.

**04 → 4.** ¿Por qué el orden topológico no es único? Da un ejemplo con cuatro vértices. 🟡

⏱️ **30 segundos.** Porque cuando hay dos fuentes a la vez, cualquiera puede ir primero. Ejemplo: `A → B`, `A → C`, `B → D`, `C → D` tiene `ABCD` y `ACBD`.

🗣️ **2 minutos.** Solo las parejas unidas por un camino tienen el orden fijado; las incomparables pueden ir en cualquier orden relativo. D tiene cinco órdenes. El número de órdenes puede ser `n!` (sin aristas).

🔬 **El detalle.** Contar los órdenes topológicos es #P-completo en general; con `n ≤ 20`, DP con máscaras ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)).

**04 → 5.** ¿Cómo obtienes el orden topológico lexicográficamente menor, y cuánto cuesta? 🟡

⏱️ **30 segundos.** Kahn con un montículo de mínimos en lugar de la cola: `Θ(n log n + m)`.

🗣️ **2 minutos.** En cada paso, el menor vértice disponible es la mejor elección para esa posición, y elegirlo no impide nada después: los demás disponibles siguen disponibles. Por intercambio, cualquier orden que no empiece por la menor fuente es mayor.

🔬 **El detalle.** «El vértice 1 lo antes posible, luego el 2…» no es lo mismo: se resuelve con el grafo invertido, un montículo de máximos y el resultado invertido (CSES Course Schedule II).

**04 → 6.** ¿Cómo calculas el número mínimo de rondas si cada ronda hace en paralelo todo lo disponible? 🟡

⏱️ **30 segundos.** Kahn por niveles: la ronda de un vértice es 1 + la mayor ronda de sus predecesores; el número de rondas es la mayor.

🗣️ **2 minutos.** Equivale al camino más largo contado en vértices. Se puede calcular procesando la cola ronda a ronda (todo lo que está en la cola al empezar una ronda es esa ronda), o con `ronda[v] = max(ronda[v], ronda[u] + 1)` al restar el grado.

🔬 **El detalle.** Si las tareas tienen duración, es la ruta crítica: el mismo máximo con pesos (Parallel Courses III).

**04 → 7.** ¿Qué cola o montículo usas en C++, Java y Python para Kahn y su versión lexicográfica? 🟡

⏱️ **30 segundos.** Cola: `std::queue`, el arreglo del orden en Java, `collections.deque` en Python. Montículo de mínimos: `priority_queue<int, vector<int>, greater<int>>`, `PriorityQueue<Integer>`, `heapq`.

🗣️ **2 minutos.** En Java, el truco de usar el arreglo del orden como cola evita estructuras; para el lexicográfico, `PriorityQueue<Integer>` boxea pero con `2·10⁵` va bien. En Python, `heapq` sobre una lista de enteros.

🔬 **El detalle.** El error típico en C++ es olvidar `greater<int>` y obtener el orden **mayor**.

**04 → 8.** Demuestra que todo DAG tiene una fuente y que, por tanto, tiene orden topológico. 🟠

⏱️ **30 segundos.** Si ningún vértice tuviera grado de entrada 0, retrocediendo por aristas de entrada desde cualquiera, a los `n + 1` pasos se repetiría un vértice: un ciclo. Con la fuente primero y el resto por inducción sale el orden.

🗣️ **2 minutos.** El paso inductivo funciona porque quitar un vértice de un DAG deja un DAG. La fuente no tiene aristas entrantes, así que ponerla primera no viola ninguna arista.

🔬 **El detalle.** Por simetría, todo DAG tiene también un sumidero (grado de salida 0), y el DFS lo encuentra primero en el postorden.

**04 → 9.** Demuestra que el postorden invertido de un DFS es un orden topológico. 🟠

⏱️ **30 segundos.** Para toda arista `u → v` de un DAG, `tout[v] < tout[u]`. Al examinarla, `v` es blanco (será descendiente y termina antes) o negro (ya terminó); gris sería un ciclo.

🗣️ **2 minutos.** Ordenando por `tout` decreciente, todo `u` va antes que todo `v` con `u → v`. El paréntesis de [`14/03`](03-dfs.md) da el caso blanco; el negro es inmediato.

🔬 **El detalle.** El preorden (`tin`) no funciona: en `A → B`, `C → B`, empezando por `A`, el preorden es `A B C` y la arista `C → B` va hacia atrás.

**04 → 10.** ¿Cómo sabes si el orden topológico es único sin enumerarlos? 🟠

⏱️ **30 segundos.** Con Kahn: si en algún momento la cola tiene dos o más vértices, no es único; si siempre tiene uno, sí.

🗣️ **2 minutos.** Con dos fuentes simultáneas, se puede sacar cualquiera primero: dos órdenes distintos. Si nunca pasa, cada posición tenía una sola opción. Equivale a que el orden encontrado tenga una arista entre cada par de consecutivos (un camino hamiltoniano).

🔬 **El detalle.** La comprobación de las aristas consecutivas vale con cualquier algoritmo: se ordena y se mira si `vᵢ → vᵢ₊₁` existe para todo `i`.

**04 → 11.** Te dan palabras ordenadas en un alfabeto desconocido. ¿Cómo reconstruyes el orden de las letras y qué casos dan «imposible»? 🔴

⏱️ **30 segundos.** Cada par de palabras consecutivas da, en su primera letra distinta, una arista «letra de la primera antes que letra de la segunda». Después, orden topológico sobre las letras.

🗣️ **2 minutos.** Imposible si hay ciclo, o si una palabra es prefijo estricto de la anterior (`abc` antes que `ab`): ningún alfabeto lo permite. Solo se comparan palabras consecutivas: las demás relaciones se deducen por transitividad.

🔬 **El detalle.** Las letras que no aparecen en ninguna arista pueden ir en cualquier lugar; si se pide el orden completo del alfabeto, se incluyen como vértices aislados.

**04 → 12.** ¿Por qué el camino más largo es lineal en un DAG si es NP-difícil en general? 🔴

⏱️ **30 segundos.** Porque en un DAG el orden topológico permite una DP: el camino más largo hasta `v` es el máximo, entre sus predecesores `u`, de `largo[u] + w(u, v)`, y todos los predecesores están calculados.

🗣️ **2 minutos.** Lo que hace difícil el caso general son los ciclos: un camino simple no puede repetir vértices, y eso exige recordar cuáles se usaron (es el problema del camino hamiltoniano). En un DAG, ningún camino puede repetir vértices, así que la restricción desaparece.

🔬 **El detalle.** Por la misma razón, en un DAG el camino más corto admite pesos negativos sin Bellman-Ford: basta la DP en orden.

**04 → Problema: ¿Es un orden válido?.**

**Pista 2:** la posición de cada vértice en la permutación.

**Pista 3:** `pos[perm[i]] = i`; recorre las aristas y responde `NO` en cuanto una tenga `pos[u] > pos[v]`.

**04 → Problema: Semestres.**

**Pista 2:** Kahn llevando el semestre de cada curso: `sem[v] = max(sem[v], sem[u] + 1)`.

**Pista 3:** las fuentes empiezan en 1; la respuesta es el máximo; si Kahn no saca todos, `-1`.

**04 → Problema: El orden menor.**

**Pista 2:** Kahn con un montículo de mínimos.

**Pista 3:** si el orden tiene menos de `n` vértices, `IMPOSSIBLE`; con la cola, el 5 entra antes que el 1 porque se libera antes, y la cola no lo reordena.

**04 → Problema: Course Schedule.**

**Pista 2:** Kahn y comprobar si salen todos los cursos.

**Pista 3:** el par `[a, b]` es la arista `b → a`.

**04 → Problema: Course Schedule II.**

**Pista 2:** Kahn devolviendo el orden.

**Pista 3:** arista `b → a` para `[a, b]`; si salen menos de `n`, lista vacía.

**04 → Problema: Course Schedule.**

**Pista 2:** Kahn con lectura rápida.

**Pista 3:** si el orden tiene menos de `n` cursos, `IMPOSSIBLE`; si no, imprímelo con índices desde 1.

**04 → Problema: Find All Possible Recipes from Given Supplies.**

**Pista 2:** grafo de ingrediente a receta; los suministros son las fuentes iniciales de Kahn.

**Pista 3:** el grado de entrada de una receta es su número de ingredientes; las que llegan a 0 se pueden hacer y pasan a ser ingredientes.

**04 → Problema: All Ancestors of a Node in a Directed Acyclic Graph.**

**Pista 2:** recorre en orden topológico propagando conjuntos: `anc[v] ⊇ anc[u] ∪ {u}` para `u → v`.

**Pista 3:** con `n ≤ 1000`, conjuntos de bits o conjuntos ordenados al final. Alternativa: un DFS desde cada vértice marcando a quién alcanza.

**04 → Problema: Loud and Rich.**

**Pista 2:** grafo del más rico al menos rico; en orden topológico, cada persona hereda el candidato más callado de los más ricos.

**Pista 3:** `ans[v]` empieza en `v`; al procesar `u → v`, si `quiet[ans[u]] < quiet[ans[v]]`, `ans[v] = ans[u]`.

**04 → Problema: Course Schedule IV.**

**Pista 2:** alcanzabilidad: el conjunto de prerrequisitos (directos e indirectos) de cada curso.

**Pista 3:** con `n ≤ 100`, una matriz booleana `n × n` llenada en orden topológico, o Floyd-Warshall booleano en `n³ = 10⁶`.

**04 → Problema: Parallel Courses III.**

**Pista 2:** ruta crítica: el fin más temprano de cada curso es su duración más el máximo fin de sus prerrequisitos.

**Pista 3:** Kahn calculando `ini[v] = max(ini[v], fin[u])` y `fin[v] = ini[v] + time[v]` al sacarlo; la respuesta es el máximo de los `fin`.

**04 → Problema: Largest Color Value in a Directed Graph.**

**Pista 2:** DP sobre Kahn: `cnt[v][c]` = máximo de nodos de color `c` en un camino que termina en `v`.

**Pista 3:** al procesar `u → v`, `cnt[v][c] = max(cnt[v][c], cnt[u][c])` para los 26 colores, y al sacar `v`, suma 1 a su color. Si hay ciclo, `-1`.

**04 → Problema: Fox And Names.**

**Pista 2:** aristas entre letras por la primera diferencia de nombres consecutivos y orden topológico sobre las 26.

**Pista 3:** `Impossible` si hay ciclo o si un nombre es prefijo estricto del anterior; imprime las 26 letras.

**04 → Problema: Course Schedule II.**

**Pista 2:** no es el lexicográfico menor: invierte el grafo, haz Kahn con un montículo de **máximos** e invierte el resultado.

**Pista 3:** sacar el mayor disponible y ponerlo al final deja los pequeños lo antes posible. Contraejemplo del directo: con `3 → 1` y el 2 libre, el lexicográfico menor es `2 3 1`, pero `3 1 2` pone antes el 1.

**04 → Problema: Sort Items by Groups Respecting Dependencies.**

**Pista 2:** dos órdenes topológicos: uno entre grupos y otro entre elementos dentro de cada grupo.

**Pista 3:** los elementos sin grupo reciben un grupo nuevo cada uno; las dependencias entre grupos distintos van al grafo de grupos y las internas al de elementos. Si alguno tiene ciclo, lista vacía.

---

# 05 — Componentes fuertemente conexas y 2-SAT

**05 → 1.** ¿Qué es una componente fuertemente conexa? 🟢

⏱️ **30 segundos.** Un conjunto maximal de vértices de un dirigido en el que cada uno alcanza a todos los demás.

🗣️ **2 minutos.** «Se alcanzan mutuamente» es una relación de equivalencia, y sus clases son las SCC: parten los vértices. Un vértice que no está en ningún ciclo es una SCC de un solo vértice; un DAG tiene `n` SCC.

🔬 **El detalle.** En un no dirigido, SCC y componente conexa coinciden, porque alcanzar es simétrico.

**05 → 2.** ¿Por qué el grafo condensado es siempre un DAG? 🟢

⏱️ **30 segundos.** Porque un ciclo entre SCC distintas haría que sus vértices se alcanzaran mutuamente, y serían una sola SCC.

🗣️ **2 minutos.** Si `X → Y → … → X` en el condensado, desde cualquier vértice de `X` se llega a cualquiera de `Y` (dentro de cada SCC todo se alcanza, y las aristas del ciclo conectan) y viceversa: `X ∪ Y` sería fuertemente conexo, contra la maximalidad.

🔬 **El detalle.** Por eso el condensado admite orden topológico y DP: es la herramienta para llevar a un DAG los problemas de caminos en dirigidos con ciclos.

**05 → 3.** Describe Kosaraju en tres pasos. 🟡

⏱️ **30 segundos.** DFS sobre el grafo guardando el postorden; transponer; DFS sobre el transpuesto en orden de postorden decreciente, y cada árbol es una SCC.

🗣️ **2 minutos.** El vértice con mayor tiempo de salida está en una SCC fuente del condensado; en el transpuesto esa SCC es sumidero, y el DFS desde él no sale de ella. Al marcarla, la siguiente con mayor `tout` es fuente de lo que queda, y así sucesivamente.

🔬 **El detalle.** Las SCC salen numeradas en orden topológico del condensado.

**05 → 4.** ¿Qué es `low[v]` en Tarjan y cuándo se cierra una SCC? 🟡

⏱️ **30 segundos.** El menor `tin` alcanzable desde el subárbol de `v` usando una arista a un vértice que siga en la pila. Una SCC se cierra cuando un vértice termina con `low[v] = tin[v]`: es su raíz y la SCC es la pila desde él.

🗣️ **2 minutos.** `low[v] < tin[v]` significa que el subárbol de `v` vuelve a algo abierto antes que `v`, así que `v` pertenece a la SCC de ese antecesor. Si no vuelve a nada anterior, todo lo que quedó en la pila por encima de `v` solo alcanza dentro: es su SCC.

🔬 **El detalle.** Las SCC salen en orden topológico inverso del condensado: la primera en cerrarse es un sumidero.

**05 → 5.** ¿Por qué en Tarjan una arista a un vértice ya visitado que no está en la pila no actualiza `low`? 🟡

⏱️ **30 segundos.** Porque ese vértice pertenece a una SCC ya cerrada, de la que no se puede volver al actual: no forma parte de su SCC.

🗣️ **2 minutos.** En D′, la arista `C → E` llega a `E`, que ya salió de la pila con `{B, D, E, F}`. Si actualizara `low[C]` con `tin[E] = 5 < 6`, `C` no se cerraría como SCC propia y se mezclaría con `A`.

🔬 **El detalle.** Es la diferencia entre aristas de cruce a SCC cerradas (se ignoran) y aristas a vértices abiertos (de retroceso o de cruce dentro de la misma SCC, cuentan).

**05 → 6.** ¿Cómo se traduce una cláusula `(a ∨ b)` al grafo de implicaciones? 🟡

⏱️ **30 segundos.** Dos aristas: `¬a → b` y `¬b → a`.

🗣️ **2 minutos.** «`a` o `b`» significa «si no `a`, entonces `b`» y «si no `b`, entonces `a`». Se añaden las dos para que el grafo sea simétrico: si `u → v`, también `¬v → ¬u`. Esa simetría es la que permite construir la asignación.

🔬 **El detalle.** Con la codificación `xᵢ = 2i`, `¬xᵢ = 2i + 1`, la negación es `v ^ 1`.

**05 → 7.** ¿Cómo implementas Kosaraju sin recursión en Java o Python? 🟡

⏱️ **30 segundos.** El primer DFS iterativo con el índice `it[u]` para obtener el postorden; el segundo, con una pila simple sobre el transpuesto, porque solo etiqueta.

🗣️ **2 minutos.** El primer recorrido necesita el instante de salida exacto, así que no vale «sacar y apilar todos los vecinos»: hace falta `it[u]`. El segundo solo marca lo alcanzable desde cada inicio, y cualquier recorrido sirve. Todo en arreglos de enteros.

🔬 **El detalle.** Tarjan iterativo existe pero hay que simular la actualización de `low` del padre al volver de un hijo; es más propenso a errores.

**05 → 8.** Demuestra el lema de Kosaraju sobre los tiempos de salida máximos. 🟠

⏱️ **30 segundos.** Si hay arista de la SCC `X` a la `Y`, el mayor `tout` de `X` supera al de `Y`. Si el DFS entra antes en `X`, todo `Y` cuelga del primer vértice de `X`; si entra antes en `Y`, termina `Y` entera sin tocar `X`.

🗣️ **2 minutos.** Caso 1: sea `x` el primer vértice descubierto de `X ∪ Y`, en `X`; en ese instante, todo `X ∪ Y` es blanco y alcanzable desde `x`, así que todo es descendiente y termina antes que `x`. Caso 2: el primero está en `Y`; desde `Y` no se alcanza `X` (habría ciclo en el condensado), así que `Y` termina entera antes de descubrir nada de `X`.

🔬 **El detalle.** Es el lema 22.14 de CLRS; el corolario 22.15 es la versión para el transpuesto.

**05 → 9.** Demuestra que 2-SAT es satisfacible si y solo si ninguna variable comparte SCC con su negación. 🟠

⏱️ **30 segundos.** Si `x` y `¬x` están en la misma SCC, `x` implica `¬x` y `¬x` implica `x`: imposible. Si ninguna variable cumple eso, la asignación por el orden topológico de las SCC satisface todo.

🗣️ **2 minutos.** La asignación: `x` verdadero si su SCC va después que la de `¬x` en el orden topológico. Si una implicación `u → v` llevara de `u` verdadero a `v` falso, por la simetría `¬v → ¬u` y los órdenes de las SCC darían una contradicción con la regla. La prueba completa compara posiciones topológicas de `u`, `v`, `¬u`, `¬v`.

🔬 **El detalle.** Es el resultado de Aspvall, Plass y Tarjan (1979), que dio 2-SAT lineal.

**05 → 10.** ¿Cómo obtienes la asignación de 2-SAT, y qué cambia entre Kosaraju y Tarjan? 🟠

⏱️ **30 segundos.** Con Tarjan (orden topológico inverso), `x` es verdadero si `comp[x] < comp[¬x]`. Con Kosaraju (orden topológico), si `comp[x] > comp[¬x]`.

🗣️ **2 minutos.** La regla común es «elige el literal cuya SCC va más tarde en el orden topológico»: de él no sale ninguna implicación hacia su negación. Como los dos algoritmos numeran en órdenes opuestos, la comparación se invierte.

🔬 **El detalle.** Equivocarse de dirección da una asignación que viola cláusulas, sin error visible: se comprueba siempre sobre los ejemplos.

**05 → 11.** ¿Cómo expresas «exactamente uno de `a` y `b`» y «`a` es obligatorio» como cláusulas? 🟠

⏱️ **30 segundos.** Exactamente uno: `(a ∨ b)` y `(¬a ∨ ¬b)`. `a` obligatorio: `(a ∨ a)`, que da la arista `¬a → a`.

🗣️ **2 minutos.** La arista `¬a → a` hace imposible que `¬a` sea verdadero sin que `a` lo sea; con la regla de asignación, `a` queda verdadero. «Iguales» son `(¬a ∨ b)` y `(a ∨ ¬b)`; «distintos» es exactamente uno.

🔬 **El detalle.** «Como mucho uno de `k`» con `k` grande genera `k²` cláusulas; hay codificaciones con variables auxiliares por prefijos que lo dejan en `O(k)`.

**05 → 12.** ¿Cuántas aristas hay que añadir, como mínimo, para que un dirigido sea fuertemente conexo? 🔴

⏱️ **30 segundos.** 0 si ya es fuertemente conexo; si no, `max(fuentes, sumideros)` del condensado.

🗣️ **2 minutos.** Cada SCC fuente necesita una arista entrante nueva y cada sumidero una saliente, así que hace falta al menos el máximo. Que basta lo prueba el teorema de Eswaran y Tarjan (1976), uniendo sumideros con fuentes en un orden cuidadoso.

🔬 **El detalle.** Un vértice aislado cuenta como fuente y como sumidero a la vez; con una sola SCC la respuesta es 0, no 1.

**05 → 13.** ¿Por qué 2-SAT es polinómico y 3-SAT no? ¿Qué se rompe? 🔴

⏱️ **30 segundos.** Porque una cláusula de dos literales es una implicación entre literales, y las implicaciones se componen en un grafo. Una de tres, `(a ∨ b ∨ c)`, solo dice «si no `a` y no `b`, entonces `c`»: necesita dos premisas, y eso no es una arista.

🗣️ **2 minutos.** En 2-SAT, fijar un literal propaga consecuencias sin ramificar: la alcanzabilidad lo dice todo. En 3-SAT, fijar un literal deja cláusulas de dos que pueden satisfacerse de varias formas: hay que ramificar, y 3-SAT es NP-completo (Cook-Levin).

🔬 **El detalle.** MAX-2-SAT (cumplir el máximo número de cláusulas) es NP-difícil aunque 2-SAT sea lineal ([`22/04`](../22-teoria-de-la-computacion/04-p-np-y-reducciones.md)).

**05 → Problema: Barrios.**

**Pista 2:** Kosaraju o Tarjan, y contar cuántos vértices tiene cada etiqueta.

**Pista 3:** con `10⁵` vértices, la versión iterativa (Kosaraju) en Java o Python; el máximo de los conteos.

**05 → Problema: Calles que faltan.**

**Pista 2:** colapsa las SCC y cuenta, en el condensado, las fuentes (sin aristas entrantes) y los sumideros (sin salientes).

**Pista 3:** si hay una sola SCC, 0; si no, el máximo de los dos conteos. Una arista solo cuenta si une SCC distintas.

**05 → Problema: Banderas en la costa.**

**Pista 2:** 2-SAT: la variable `i` dice si la bandera `i` va en `aᵢ`. Cada par de posiciones incompatibles de dos banderas da la cláusula «no las dos a la vez».

**Pista 3:** para cada par `i < j` y cada combinación de posiciones a distancia menor que `D`, añade `(¬pᵢ ∨ ¬pⱼ)` con los literales que correspondan: `O(n²)` cláusulas, unas `2·10⁶`; después, Tarjan o Kosaraju.

**05 → Problema: Planets and Kingdoms.**

**Pista 2:** las SCC con su etiqueta.

**Pista 3:** imprime el número de SCC y la etiqueta + 1 de cada planeta; cualquier numeración vale.

**05 → Problema: Flight Routes Check.**

**Pista 2:** sí basta: si 1 alcanza a todos en el grafo y en el transpuesto, es fuertemente conexo.

**Pista 3:** si falla en el grafo, `NO` y `1 v` con `v` no alcanzado; si falla en el transpuesto, `NO` y `v 1`.

**05 → Problema: Dominos.**

**Pista 2:** el número de SCC fuente del condensado.

**Pista 3:** etiqueta las SCC, marca las que reciben alguna arista de otra SCC y cuenta las no marcadas. Varios casos por entrada: limpia entre casos.

**05 → Problema: Checkposts.**

**Pista 2:** en cada SCC basta un puesto, en el cruce más barato.

**Pista 3:** el coste es la suma de los mínimos por SCC; las formas, el producto de cuántos cruces alcanzan ese mínimo en cada SCC, módulo `10⁹ + 7`.

**05 → Problema: Coin Collector.**

**Pista 2:** dentro de una SCC se recogen todas sus monedas; colapsa y haz la DP del camino de suma máxima en el condensado.

**Pista 3:** con Kosaraju, las SCC ya salen en orden topológico: `best[c] = monedas[c] + max(best de predecesores)`. Sumas en 64 bits.

**05 → Problema: Giant Pizza.**

**Pista 2:** 2-SAT: cada familia da una cláusula con sus dos deseos.

**Pista 3:** `+x` es el literal `x`, `-x` su negación; si alguna variable comparte SCC con su negación, `IMPOSSIBLE`; si no, la regla de asignación.

**05 → Problema: The Road to Berland is Paved With Good Intentions.**

**Pista 2:** asfaltar dos veces es no asfaltar: cada ciudad se elige 0 o 1 veces. Una carretera asfaltada exige que se elija exactamente uno de sus extremos si ahora no lo está, o ninguno o los dos si ya lo está.

**Pista 3:** son restricciones de igualdad o desigualdad entre pares: 2-SAT (o bipartición con paridad). Imprime las ciudades verdaderas.

**05 → Problema: The Door Problem.**

**Pista 2:** cada puerta depende de exactamente dos interruptores: la puerta cerrada exige que se active exactamente uno; la abierta, ninguno o los dos.

**Pista 3:** son restricciones de XOR entre pares de variables: 2-SAT con dos cláusulas por puerta, o Union-Find con paridad.

**05 → Problema: Catowice City.**

**Pista 2:** si un residente es jurado, todos los que conoce tienen que serlo: el conjunto de jurados es cerrado por alcanzabilidad.

**Pista 3:** una SCC sumidero del condensado sirve como jurado si no es todo el grafo; si solo hay una SCC, `No`.

---

# 06 — Puentes, puntos de articulación y Euler

**06 → 1.** ¿Qué es un puente y qué es un punto de articulación? 🟢

⏱️ **30 segundos.** Un puente es una arista cuya eliminación desconecta el grafo; un punto de articulación, un vértice cuya eliminación (con sus aristas) lo desconecta.

🗣️ **2 minutos.** Son los puntos únicos de fallo de una red. Una arista es puente si y solo si no está en ningún ciclo. En G no hay ninguno; en G⁻, `A–B` y `A–C` son puentes y `A` y `B`, articulaciones.

🔬 **El detalle.** Un grafo sin puntos de articulación (con al menos 3 vértices) es biconexo: entre cada par hay dos caminos sin vértices intermedios comunes.

**06 → 2.** Enuncia el teorema de Euler para no dirigidos. 🟢

⏱️ **30 segundos.** Con todas las aristas en una componente, hay circuito de Euler si y solo si todos los grados son pares, y camino si y solo si hay 0 o 2 vértices de grado impar.

🗣️ **2 minutos.** Con 2 impares, el camino empieza en uno y acaba en el otro. Los vértices aislados no importan: la conectividad se exige solo a los que tienen aristas.

🔬 **El detalle.** Es el resultado de Euler sobre los puentes de Königsberg (1736): cuatro zonas de grado impar, sin recorrido posible.

**06 → 3.** ¿Qué es `low[v]` y cómo se actualiza? 🟢

⏱️ **30 segundos.** El menor `tin` alcanzable desde el subárbol de `v` con como mucho una arista de retroceso, sin usar la arista por la que se llegó a `v`.

🗣️ **2 minutos.** Se inicializa con `tin[v]`; con cada arista de retroceso `v – w`, `low[v] = min(low[v], tin[w])`; al volver de cada hijo `c`, `low[v] = min(low[v], low[c])`.

🔬 **El detalle.** Es el mismo `low` de Tarjan para SCC ([`14/05`](05-componentes-fuertes-y-2sat.md)), en su versión no dirigida.

**06 → 4.** ¿Por qué el criterio de puente usa `>` y el de articulación `≥`? 🟡

⏱️ **30 segundos.** Porque una arista se salva si el subárbol vuelve a `u` (otro camino que llega a `u`), pero un vértice solo se salva si el subárbol sube **por encima** de `u`.

🗣️ **2 minutos.** Si `low[v] = tin[u]`, el subárbol de `v` tiene una arista de retroceso a `u` mismo: hay un ciclo que contiene `u – v`, así que la arista no es puente; pero todos los caminos del subárbol al resto pasan por `u`, así que `u` sí es articulación.

🔬 **El detalle.** En dos triángulos que comparten un vértice `u` (una pajarita), con el DFS empezando en el primero, el segundo cuelga de `u` con `low = tin[u]`: ninguna arista es puente, pero `u` es articulación.

**06 → 5.** ¿Por qué la raíz del DFS necesita un criterio distinto para ser articulación? 🟡

⏱️ **30 segundos.** Porque la raíz no tiene nada por encima: el criterio `low[v] ≥ tin[raíz]` se cumple siempre. La raíz es articulación si y solo si tiene dos o más hijos en el árbol del DFS.

🗣️ **2 minutos.** Dos hijos del DFS de la raíz no están conectados entre sí salvo a través de ella (si lo estuvieran, el DFS del primero habría descubierto al segundo). Con un solo hijo, quitar la raíz deja el resto unido por el árbol.

🔬 **El detalle.** El error típico es aplicar el criterio general a la raíz y marcarla siempre.

**06 → 6.** ¿Qué cambia en las condiciones de Euler para un dirigido? 🟡

⏱️ **30 segundos.** Se cuentan grados de entrada y de salida. Circuito: iguales en todos. Camino: un inicio con una salida de más, un final con una entrada de más, el resto iguales.

🗣️ **2 minutos.** La conectividad se pide débil (ignorando la dirección) para los vértices con aristas; con los grados equilibrados, débil implica fuerte en lo que tiene aristas. El recorrido empieza en el vértice con salida de más, o en cualquiera con aristas si es circuito.

🔬 **El detalle.** En Hierholzer dirigido no hace falta marcar aristas usadas: avanzar el puntero de la lista ya la consume.

**06 → 7.** ¿Por qué se salta la arista del padre por índice y no por vértice? 🟡

⏱️ **30 segundos.** Porque con aristas repetidas, la otra copia entre `u` y su padre es un desvío legítimo: comparar el vértice la saltaría y declararía puente una arista que no lo es.

🗣️ **2 minutos.** Se pasa al DFS el índice de la arista por la que se entró y se salta solo esa. Las demás aristas al padre (copias) cuentan como de retroceso y bajan `low` a `tin[padre]`, con lo que la arista deja de ser puente.

🔬 **El detalle.** Para articulación no cambia nada (una copia no salva al vértice), pero conviene la misma plantilla para los dos.

**06 → 8.** Demuestra el criterio de puente `low[v] > tin[u]`. 🟠

⏱️ **30 segundos.** El subárbol de `v` solo puede salir por la arista `u – v` o por aristas de retroceso. Si `low[v] > tin[u]`, ninguna de retroceso llega a `u` o más arriba: quitar `u – v` aísla el subárbol. Si `low[v] ≤ tin[u]`, hay desvío.

🗣️ **2 minutos.** La clave es que en un DFS no dirigido no hay aristas de cruce: toda arista que no es del árbol une un vértice con un antecesor. Por eso las únicas salidas del subárbol de `v` son hacia sus antecesores, y `low[v]` mide hasta dónde suben.

🔬 **El detalle.** Las aristas de retroceso nunca son puentes: cierran un ciclo con el camino del árbol.

**06 → 9.** Demuestra que un camino de Euler exige 0 o 2 vértices de grado impar. 🟠

⏱️ **30 segundos.** Cada vez que el camino pasa por un vértice intermedio entra por una arista y sale por otra: suma 2 a su grado. Solo el inicio y el final de un camino abierto reciben una arista sin pareja.

🗣️ **2 minutos.** Por tanto, en un camino de Euler, todo vértice salvo los extremos tiene grado par; los extremos, impar si son distintos y par si coinciden. Son 0 o 2 impares. La suficiencia la da Hierholzer.

🔬 **El detalle.** Por el lema de los grados ([`14/01`](01-representaciones.md)), el número de impares es siempre par: nunca puede haber exactamente 1.

**06 → 10.** ¿Cómo funciona Hierholzer y por qué el recorrido sale invertido? 🟠

⏱️ **30 segundos.** Pila desde el inicio; si la cima tiene una arista libre, se usa y se apila el vecino; si no, se desapila y se añade al recorrido. El recorrido es el orden de salida, invertido.

🗣️ **2 minutos.** Un vértice sale de la pila cuando ya no tiene aristas libres, es decir, cuando todo lo que se podía hacer desde él ya está hecho: es lo último que se visita a partir de ese punto. Los circuitos que se dejaron sin recorrer se insertan al desapilar.

🔬 **El detalle.** Con el puntero por vértice, cada arista se mira un número constante de veces: `Θ(n + m)`.

**06 → 11.** ¿En qué se diferencian Euler y Hamilton, y por qué uno es lineal y el otro NP-completo? 🟠

⏱️ **30 segundos.** Euler usa cada arista una vez y se decide con los grados, en tiempo lineal. Hamilton usa cada vértice una vez y es NP-completo.

🗣️ **2 minutos.** La diferencia es que la condición de Euler es local (cada vértice, su paridad) y Hierholzer puede corregir sobre la marcha insertando circuitos. Hamilton no tiene una condición local: decidir si hay un ciclo que toque cada vértice exige, en el peor caso, explorar combinaciones; con `n ≤ 20`, DP con máscaras en `2ⁿ · n²`.

🔬 **El detalle.** El ciclo hamiltoniano está en la lista de Karp (1972) de problemas NP-completos.

**06 → 12.** ¿Cuántas aristas hay que añadir para que un grafo conexo no tenga puentes? 🔴

⏱️ **30 segundos.** Colapsar las componentes 2-arista-conexas da un árbol (el árbol de puentes); la respuesta es `⌈hojas / 2⌉`, o 0 si es un solo nodo.

🗣️ **2 minutos.** Cada hoja necesita una arista nueva que la saque del árbol por otro lado; una arista nueva sirve como mucho a dos hojas: al menos `⌈hojas / 2⌉`. Uniendo las hojas en el orden de un DFS, cada una con la que está a «media vuelta», se alcanza.

🔬 **El detalle.** La versión para articulación (2-vértice-conexo) usa el árbol de bloques y cortes y tiene casos especiales.

**06 → 13.** ¿Cómo construyes la secuencia más corta que contiene todas las cadenas binarias de longitud `k`? 🔴

⏱️ **30 segundos.** Grafo de De Bruijn: vértices, las `2^(k−1)` cadenas de `k − 1` bits; aristas, de cada cadena a la que resulta de añadir un bit y quitar el primero. Un circuito de Euler recorre las `2^k` cadenas de longitud `k`.

🗣️ **2 minutos.** Cada vértice tiene grado de entrada y de salida 2, así que hay circuito de Euler. La secuencia es el vértice inicial seguido del bit de cada arista: longitud `2^k + k − 1`, la mínima posible.

🔬 **El detalle.** Con alfabeto de `d` símbolos, el mismo grafo con `d` aristas por vértice: Cracking the Safe.

**06 → Problema: Lo que no se puede cortar.**

**Pista 2:** el DFS con `low` y los dos criterios: `low[v] > tin[u]` para puentes, `≥` (o raíz con dos hijos) para articulación.

**Pista 3:** salta la arista del padre por índice (hay repetidas); cuenta los puentes y los vértices marcados. Recorre todas las componentes.

**06 → Problema: Fila de dominó.**

**Pista 2:** cada número es un vértice y cada ficha una arista (puede ser un bucle): la fila es un camino de Euler.

**Pista 3:** 0 o 2 vértices de grado impar, y todas las fichas en una misma componente (Union-Find sobre los números usados). Un bucle suma 2 al grado.

**06 → Problema: Red sin cables críticos.**

**Pista 2:** colapsa las componentes sin puentes: queda un árbol cuyas aristas son los puentes.

**Pista 3:** cuenta las hojas de ese árbol (componentes con un solo puente); la respuesta es `⌈hojas / 2⌉`, o 0 si no hay puentes.

**06 → Problema: Critical Connections in a Network.**

**Pista 2:** puentes con `low[v] > tin[u]`.

**Pista 3:** sin aristas repetidas, saltar el padre por vértice basta aquí; con `10⁵` nodos, en Python, iterativo.

**06 → Problema: Necessary Roads.**

**Pista 2:** puentes.

**Pista 3:** imprime su número y cada uno; el grafo es conexo, pero sé cuidadoso con la recursión en Java.

**06 → Problema: Necessary Cities.**

**Pista 2:** puntos de articulación.

**Pista 3:** la raíz es articulación solo con dos o más hijos; imprime los vértices marcados, sin repetir.

**06 → Problema: Mail Delivery.**

**Pista 2:** circuito de Euler no dirigido desde 1.

**Pista 3:** si algún grado es impar o el recorrido no tiene `m + 1` vértices, `IMPOSSIBLE`; marca las aristas usadas por índice.

**06 → Problema: Teleporters Path.**

**Pista 2:** camino de Euler dirigido de 1 a `n`.

**Pista 3:** 1 con una salida de más, `n` con una entrada de más, el resto equilibrados; Hierholzer desde 1 y comprobar que tiene `m + 1` vértices y acaba en `n`.

**06 → Problema: Reconstruct Itinerary.**

**Pista 2:** camino de Euler dirigido desde `JFK`, con los destinos en orden lexicográfico.

**Pista 3:** ordena las listas de vecinos y usa Hierholzer: avanzar siempre por el menor destino libre y desapilar al quedarse sin salidas da el menor itinerario.

**06 → Problema: De Bruijn Sequence.**

**Pista 2:** circuito de Euler en el grafo de De Bruijn de cadenas de `n − 1` bits.

**Pista 3:** la secuencia es el vértice inicial (`n − 1` ceros) seguido del bit de cada arista; para `n = 1`, `01`.

**06 → Problema: Valid Arrangement of Pairs.**

**Pista 2:** cada par es una arista dirigida; el orden pedido es un camino de Euler.

**Pista 3:** empieza en el vértice con salida mayor que entrada (o en cualquiera si todos están equilibrados); los valores son grandes: mapas en lugar de arreglos.

**06 → Problema: Cracking the Safe.**

**Pista 2:** De Bruijn con alfabeto de `k` dígitos y vértices de `n − 1` dígitos.

**Pista 3:** Hierholzer sobre `k^(n−1)` vértices con `k` aristas cada uno; la contraseña tiene `kⁿ + n − 1` dígitos.

**06 → Problema: Bertown roads.**

**Pista 2:** si hay un puente, `0`; si no, orientar cada arista del árbol del DFS hacia abajo y cada de retroceso hacia arriba da un grafo fuertemente conexo.

**Pista 3:** el mismo DFS con `low` detecta los puentes y orienta las aristas en el orden en que las recorre; recursión profunda en Java: hilo con pila.

**06 → Problema: We Need More Bosses.**

**Pista 2:** colapsa las componentes 2-arista-conexas: el árbol de puentes. La respuesta es su diámetro.

**Pista 3:** el diámetro con dos BFS ([`07/06`](../07-arboles/06-tecnicas-sobre-arboles.md)) sobre el árbol colapsado.

**06 → Problema: One-Way Reform.**

**Pista 2:** solo los vértices de grado par pueden quedar con entrada igual a salida, y todos ellos pueden.

**Pista 3:** une los vértices de grado impar a un vértice ficticio, busca un circuito de Euler en cada componente y orienta las aristas en el sentido del recorrido; las ficticias no se imprimen.

---

# 07 — Simulación

**07 → S1.** ¿Qué representación eliges para un grafo de `2·10⁵` vértices y `2·10⁵` aristas, y cuánta memoria usa? 🟢

⏱️ **30 segundos.** Listas de adyacencia: `Θ(n + m)`, unas `6·10⁵` entradas en un no dirigido. La matriz serían `4·10¹⁰` celdas.

🗣️ **2 minutos.** El grafo es disperso y los algoritmos de recorrido piden los vecinos de cada vértice: listas. En Java, mejor `int[][]` construido contando grados, o la estrella hacia delante, que una lista de objetos.

🔬 **El detalle.** Es el lema de los grados el que dice que las listas de un no dirigido tienen `2m` entradas (`14/01`).

**07 → S2.** ¿Por qué BFS da distancias mínimas sin pesos y DFS no? 🟢

⏱️ **30 segundos.** BFS visita por capas: cada vértice se descubre desde la capa anterior, por un camino mínimo. DFS llega por el camino que la recursión eligió y no lo corrige.

🗣️ **2 minutos.** El invariante de la cola (distancias `d` seguidas de `d + 1`) es lo que da la prueba. DFS no tiene ese orden: en un triángulo puede llegar a un vecino directo dando la vuelta.

🔬 **El detalle.** En un árbol, DFS sí da las distancias, porque hay un solo camino.

**07 → S3.** ¿Cuándo usas 0-1 BFS en lugar de Dijkstra? 🟡

⏱️ **30 segundos.** Cuando todas las aristas pesan 0 o 1: la cola doble sustituye al montículo y se quita el logaritmo.

🗣️ **2 minutos.** Con pesos 0 y 1, el montículo de Dijkstra solo tiene dos valores distintos a la vez; la cola doble los mantiene ordenados metiendo los de 0 delante y los de 1 detrás. Se relaja con `<`, porque un vértice puede mejorar después de encolado.

🔬 **El detalle.** Con pesos pequeños `0..k`, la generalización son `k + 1` colas por distancia (algoritmo de Dial).

**07 → S4.** ¿Cuál es el estado de un BFS en una rejilla donde puedes romper como mucho `k` paredes? 🟡

⏱️ **30 segundos.** `(fila, columna, paredes rotas)`, con las paredes rotas de 0 a `k`: `R · C · (k + 1)` estados.

🗣️ **2 minutos.** Dos llegadas a la misma casilla con distinto número de paredes rotas tienen futuros distintos. Pisar una pared aumenta el contador; si supera `k`, la transición no existe. BFS normal sobre ese grafo.

🔬 **El detalle.** Si se pide el mínimo de paredes rotas (sin límite), no es estado: es peso, y el problema es 0-1 BFS.

**07 → S5.** ¿Qué distingue, en un DFS de un dirigido, una arista que cierra un ciclo de una que no? 🟢

⏱️ **30 segundos.** La que cierra un ciclo llega a un vértice gris (todavía en la pila); las demás llegan a blancos o a negros.

🗣️ **2 minutos.** Un negro ya terminó y no lleva de vuelta al actual; llegar a él es un camino que confluye, no un ciclo. Por eso hacen falta tres colores: con «visitado» solo, todo DAG con caminos que confluyen parecería tener ciclos.

🔬 **El detalle.** Esas aristas a grises son las de retroceso; un dirigido tiene ciclo si y solo si existen (`14/03`).

**07 → S6.** ¿Cómo compruebas que un grafo es bipartito, y qué evidencia devuelves si no lo es? 🟡

⏱️ **30 segundos.** Propagando dos colores por componentes; si una arista une dos del mismo color, no es bipartito, y el camino del árbol más esa arista es un ciclo impar.

🗣️ **2 minutos.** El color del primer vértice de cada componente decide todos los demás; un conflicto no se arregla cambiando nada. El ciclo impar es el certificado: un grafo es bipartito si y solo si no tiene ciclos impares.

🔬 **El detalle.** El olvido clásico es recorrer solo desde el vértice 0 y no las demás componentes.

**07 → S7.** ¿Qué dos algoritmos dan un orden topológico y qué ventaja tiene cada uno? 🟢

⏱️ **30 segundos.** Kahn (grados de entrada y cola) y el postorden invertido de un DFS. Kahn da el lexicográfico menor y las rondas cambiando una línea; el DFS encuentra el ciclo además de detectarlo.

🗣️ **2 minutos.** Los dos son `Θ(n + m)` y detectan el ciclo: Kahn porque saca menos de `n` vértices, el DFS por una arista a un gris. Kahn no necesita recursión, que en Java y Python es una ventaja.

🔬 **El detalle.** Kosaraju usa el postorden del DFS: si ya hay un DFS en marcha, el orden sale gratis.

**07 → S8.** ¿Qué es el grafo condensado y por qué es un DAG? 🟡

⏱️ **30 segundos.** El grafo con un vértice por componente fuertemente conexa y una arista entre dos si hay alguna arista entre sus vértices. Es un DAG porque un ciclo entre componentes las fundiría en una.

🗣️ **2 minutos.** Es la forma de llevar a un DAG cualquier dirigido: dentro de cada SCC todo se alcanza, y entre SCC el orden es estricto. Sobre el condensado funcionan el orden topológico y la DP.

🔬 **El detalle.** Kosaraju numera las SCC en orden topológico del condensado; Tarjan, en el inverso.

**07 → S9.** ¿Qué condición sobre `low` hace de una arista un puente? 🟢

⏱️ **30 segundos.** La arista del árbol `u – v`, con `v` hijo, es puente si `low[v] > tin[u]`.

🗣️ **2 minutos.** `low[v]` dice hasta dónde sube el subárbol de `v` con una arista de retroceso. Si no llega a `u` ni más arriba, la única salida del subárbol es `u – v`.

🔬 **El detalle.** Con aristas paralelas hay que saltar la del padre por índice de arista, no por vértice.

**07 → S10.** ¿Cuándo tiene un no dirigido un camino de Euler? 🟢

⏱️ **30 segundos.** Si tiene 0 o 2 vértices de grado impar y todas las aristas están en una misma componente.

🗣️ **2 minutos.** Con 0 impares hay circuito; con 2, el camino va de uno al otro. Cada paso por un vértice intermedio usa dos aristas, de ahí la paridad. Hierholzer lo construye en `Θ(n + m)`.

🔬 **El detalle.** Los vértices aislados no cuentan para la conectividad.

**07 → S11.** Te piden la distancia entre dos nodos de un **árbol** con pesos y alguien propone Dijkstra. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que en un árbol hay un solo camino entre dos nodos: cualquier recorrido (DFS o BFS) desde uno acumula la distancia, en `Θ(n)`.

🗣️ **2 minutos.** Dijkstra da la respuesta correcta, pero con un `log` y un montículo que no hacen falta: no hay que elegir entre caminos. Con muchas consultas de pares, la distancia es `d(u) + d(v) − 2·d(LCA)` (`07/05`).

🔬 **El detalle.** Es la «Fuerza» del problema Túneles: reconocer que la estructura elimina la decisión.

**07 → S12.** Tu detector de ciclos en un grafo de dependencias dice «ciclo» en todos los casos con caminos que confluyen. ¿Qué miras? 🟠

⏱️ **30 segundos.** Que use tres colores: está tratando como ciclo la llegada a un vértice ya terminado (negro).

🗣️ **2 minutos.** En un DAG como `A → B → D`, `A → C → D`, el DFS llega dos veces a `D`; la segunda vez `D` es negro y no hay ciclo. Solo la llegada a un gris lo es.

🔬 **El detalle.** La prueba rápida es el diamante de cuatro vértices: si el detector dice «ciclo», tiene dos colores.

**07 → S13.** Tu BFS en rejilla da la respuesta correcta en los ejemplos y TLE en el caso grande. Marcas al sacar. ¿Qué pasa? 🟠

⏱️ **30 segundos.** Al marcar al sacar, una casilla entra en la cola una vez por cada vecina que la ve antes de que salga: la cola crece varias veces más y el tiempo y la memoria se multiplican.

🗣️ **2 minutos.** Las distancias siguen bien (la primera salida es la buena), por eso pasan los ejemplos; pero en la rejilla grande la cola tiene millones de entradas repetidas. Marcando al encolar, cada casilla entra una vez.

🔬 **El detalle.** En 0-1 BFS y Dijkstra no se puede marcar al encolar, pero allí se relaja con `<` y las copias viejas se ignoran.

**07 → S14.** «Pasar por todas las ciudades una vez» y «pasar por todas las carreteras una vez»: ¿cuál es lineal? 🟠

⏱️ **30 segundos.** «Todas las carreteras una vez» (Euler) es lineal; «todas las ciudades una vez» (Hamilton) es NP-completo.

🗣️ **2 minutos.** Euler se decide por la paridad de los grados y se construye con Hierholzer; Hamilton no tiene una condición local, y con `n ≤ 20` se resuelve con máscaras en `2ⁿ · n²`.

🔬 **El detalle.** El viajante (`13/01`) es Hamilton con pesos.

**07 → S15.** Tu código de puentes declara puente una de dos aristas paralelas. ¿Qué miras? 🟠

⏱️ **30 segundos.** Que salte la arista del padre por vértice: así ignora la copia paralela, que es un desvío legítimo.

🗣️ **2 minutos.** Se pasa al DFS el índice de la arista por la que se llegó y se salta solo esa; la otra copia cuenta como arista de retroceso y baja `low[v]` a `tin[u]`, con lo que ya no es puente.

🔬 **El detalle.** Por eso la plantilla guarda `{vecino, índice}` en las listas.

**07 → S16.** Tu 2-SAT dice «satisfacible» y la asignación que imprime viola cláusulas. ¿Qué miras? 🟠

⏱️ **30 segundos.** La dirección de la regla de asignación: con Tarjan, `x` verdadero si `comp[x] < comp[¬x]`; con Kosaraju, al revés.

🗣️ **2 minutos.** Si la comparación está invertida, la asignación elige el literal del que salen implicaciones hacia su negación. Lo segundo que se mira: que cada cláusula añada sus **dos** implicaciones.

🔬 **El detalle.** Siempre se comprueba la asignación contra las cláusulas en los ejemplos: el error no da otro síntoma.

**07 → S17.** Kahn y el DFS te dan órdenes topológicos distintos para el mismo grafo. ¿Hay un error? 🟠

⏱️ **30 segundos.** No necesariamente: un DAG puede tener muchos órdenes topológicos. Lo que hay que comprobar es que los dos cumplan todas las aristas.

🗣️ **2 minutos.** D tiene cinco órdenes; Kahn con cola da `ABCDEF` y el DFS, `ACBEDF`. Si el enunciado exige uno concreto (el lexicográfico menor), solo Kahn con montículo lo garantiza.

🔬 **El detalle.** El orden es único si y solo si Kahn nunca tiene dos vértices en la cola a la vez.

**07 → S18.** Un DFS recursivo en Java pasa todos los casos menos uno, que es una cadena de `2·10⁵` nodos. ¿Qué haces sin reescribir el algoritmo? 🟠

⏱️ **30 segundos.** Ejecutar el código en un hilo con pila grande: `new Thread(null, runnable, "main", 1L << 28)`, `start` y `join`.

🗣️ **2 minutos.** La pila por defecto de la JVM no da para `2·10⁵` marcos; el hilo con 256 MB sí. La alternativa es el DFS iterativo con `it[u]`, que da los mismos tiempos, pero eso sí es reescribir.

🔬 **El detalle.** En Python no hay arreglo equivalente fiable: siempre iterativo ([`03/04`](../03-biblioteca-estandar/04-python-para-competir.md)).

**07 → S19.** Demuestra que un grafo dirigido tiene orden topológico si y solo si no tiene ciclos. 🔴

⏱️ **30 segundos.** Con un ciclo no hay orden: cada vértice tendría que ir antes que el siguiente y el último antes que el primero. Sin ciclos hay una fuente; se pone primera y se repite.

🗣️ **2 minutos.** La fuente existe porque, si todos tuvieran una arista de entrada, retrocediendo `n + 1` veces se repetiría un vértice: un ciclo. Quitar la fuente deja un DAG y la inducción termina. Esa prueba es el algoritmo de Kahn.

🔬 **El detalle.** La otra prueba es la del postorden: en un DAG, `tout[v] < tout[u]` para toda arista `u → v`.

**07 → S20.** Diseña cómo contar, en un grafo no dirigido de `10⁵` vértices, cuántos vértices quedan aislados del vértice 1 si se corta cada arista por separado, y di el coste. 🔴

⏱️ **30 segundos.** Solo los puentes desconectan algo. Con un DFS desde 1, cortar el puente `u – v` (con `v` hijo) aísla exactamente el subárbol de `v`: la respuesta es su tamaño; para las demás aristas, 0.

🗣️ **2 minutos.** Un DFS con `tin`, `low` y el tamaño de cada subárbol, todo en la misma pasada: `Θ(n + m)`. Los vértices que ya no estaban conectados con 1 no cuentan, porque no están en el árbol del DFS desde 1.

🔬 **El detalle.** Con `10⁵` vértices, en Java el DFS va en un hilo con pila grande o iterativo.

**07 → Problema: Los guardias.**

**Pista 2:** BFS sobre `(fila, columna, t mod 4)`: el instante solo importa por su resto, y quedarse quieto es una transición más.

**Pista 3:** una casilla `d` se puede ocupar en el instante `t + 1` si `(t + 1) mod 4 ≠ d`; `4 · R · C` estados; responde al sacar la primera `T`.

**07 → Problema: Paquetes bloqueados.**

**Pista 2:** Kahn con las aristas `v → u` (de la dependencia al dependiente): los que no salen son los bloqueados.

**Pista 3:** la respuesta es `n` menos los vértices que saca Kahn; incluye los del ciclo y todo lo que depende de ellos.

**07 → Problema: Dos salas.**

**Pista 2:** bipartición por componentes: cada componente aporta `(a, b)` estudiantes a las dos salas, en un orden o en el otro.

**Pista 3:** subconjunto de sumas sobre las componentes (con `n ≤ 2 000`, un arreglo de booleanos o un `bitset`): el tamaño alcanzable `x` más cercano a `n / 2` da `|n − 2x|`. Si hay conflicto, `-1`.

**07 → Problema: Túneles.**

**Pista 2:** un solo recorrido desde 1 acumulando la distancia: en un árbol hay un único camino.

**Pista 3:** listas de hijos y un DFS iterativo desde 1; un padre puede tener índice mayor que su hijo, así que un bucle en orden de índices no basta. Distancias en 64 bits.

**07 → Problema: Number of Closed Islands.**

**Pista 2:** quita primero las islas que tocan el borde (recorrido desde cada `0` del borde) y cuenta las demás.

**Pista 3:** después, componentes de `0` en lo que queda; con rejillas de `100 × 100`, recursión o pila, da igual.

**07 → Problema: Shortest Bridge.**

**Pista 2:** marca una isla entera con un recorrido y lanza un BFS multifuente desde todas sus casillas.

**Pista 3:** la respuesta es la distancia a la que el BFS toca la otra isla, menos 1 (las casillas de agua cruzadas).

**07 → Problema: Graph Girth.**

**Pista 2:** un BFS desde cada vértice: el ciclo más corto que pasa por la raíz se detecta con una arista entre dos vértices ya descubiertos que no es la del árbol.

**Pista 3:** para la arista `u – v` no del árbol, el ciclo mide `dist[u] + dist[v] + 1`; el mínimo sobre todas las raíces es exacto. `n · (n + m)` con `n = 2 500`: unos `10⁷`.

**07 → Problema: Directing Edges.**

**Pista 2:** si las dirigidas tienen ciclo, `NO`; si no, toma un orden topológico de ellas y orienta cada no dirigida de la que va antes a la que va después.

**Pista 3:** Kahn con todos los vértices (las no dirigidas no cuentan en los grados) y la posición de cada uno; orientar según la posición nunca crea un ciclo.

**07 → Problema: Bus Routes.**

**Pista 2:** el número de autobuses es la distancia en un grafo cuyos vértices son las rutas (o un BFS que alterna paradas y rutas).

**Pista 3:** índice de parada a rutas; BFS desde las rutas que contienen el origen, marcando cada ruta y cada parada una sola vez para no recorrer listas repetidas.
