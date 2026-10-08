# Respuestas — bloque 15: Grafos con pesos y flujos

> Solucionario del bloque `15`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--dijkstra) · [02](#02--bellman-ford-floyd-warshall-y-johnson) · [03](#03--a-y-heurísticas-admisibles) · [04](#04--árbol-de-expansión-mínima) · [05](#05--flujo-máximo-y-corte-mínimo) · [06](#06--emparejamientos) · [07](#07--grafos-de-nivel-experto) · [08](#08--simulación)

---

# 01 — Dijkstra

**01 → 1.** ¿Qué condición exige Dijkstra sobre los pesos, y qué pasa si no se cumple? 🟢

⏱️ **30 segundos.** Que los pesos sean no negativos. Si hay alguno negativo, Dijkstra puede fijar un vértice con una distancia que después bajaría, y da una respuesta incorrecta sin avisar.

🗣️ **2 minutos.** La prueba usa que el prefijo de un camino no cuesta más que el camino entero. Con `s → a` de 1, `s → b` de 2 y `b → a` de `−2`, fija `a` con 1 aunque la distancia real es 0. Con negativos, Bellman-Ford ([`15/02`](02-bellman-ford-floyd-y-johnson.md)).

🔬 **El detalle.** Algunas implementaciones que no fijan (permiten reinsertar vértices ya extraídos) dan la respuesta correcta con negativos sin ciclos negativos, pero en tiempo exponencial en el peor caso.

**01 → 2.** ¿Qué es el borrado perezoso y por qué hace falta con `priority_queue`, `PriorityQueue` y `heapq`? 🟢

⏱️ **30 segundos.** Meter una entrada nueva en cada mejora en lugar de actualizar la vieja, y descartar al sacar las entradas cuya distancia ya no es la vigente. Hace falta porque esas colas no tienen `decrease-key`.

🗣️ **2 minutos.** `priority_queue`, `PriorityQueue` y `heapq` no permiten localizar un elemento dentro: cambiar su prioridad exigiría buscarlo en `O(n)`. Con el borrado perezoso, el montículo llega a `m` entradas, y el coste es `Θ((n + m) log n)` igualmente.

🔬 **El detalle.** La alternativa es la cola indexada de [`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md), con `decrease-key` en `O(log n)` y montículo de `n` entradas.

**01 → 3.** ¿Cuánto cuesta Dijkstra con montículo binario, y cuánto sin montículo? 🟢

⏱️ **30 segundos.** Con montículo binario, `Θ((n + m) log n)`. Sin montículo, `Θ(n² + m)`.

🗣️ **2 minutos.** Con montículo, cada relajación exitosa es una inserción `O(log m) = O(log n)` y cada vértice se extrae una vez de forma útil. Sin montículo, cada una de las `n` extracciones recorre el arreglo: `n²`.

🔬 **El detalle.** Con montículo de Fibonacci es `Θ(m + n log n)`, mejor en teoría y casi nunca en la práctica.

**01 → 4.** ¿Cómo reconstruyes el camino mínimo? 🟢

⏱️ **30 segundos.** Guardando `parent[v] = u` en cada relajación exitosa y siguiendo los padres desde el destino; después se invierte.

🗣️ **2 minutos.** La última relajación exitosa de cada vértice es la de su distancia final, así que los padres forman un árbol de caminos mínimos. Si `dist[t]` es infinito, no hay camino.

🔬 **El detalle.** Si se piden todos los caminos mínimos, hay que guardar todos los predecesores con `dist[u] + w = dist[v]`: un DAG.

**01 → 5.** ¿Qué pasa si olvidas `greater<>` en la `priority_queue` de C++? 🟡

⏱️ **30 segundos.** La cola saca el elemento **mayor**: Dijkstra extrae primero el más lejano y fija distancias que no son mínimas.

🗣️ **2 minutos.** El programa no falla: termina con respuestas incorrectas, o correctas en ejemplos pequeños. La alternativa a `greater<>` es meter las distancias negadas.

🔬 **El detalle.** En Java, `PriorityQueue` es de mínimos por defecto; el error simétrico es invertir el comparador.

**01 → 6.** ¿Por qué hacen falta 64 bits en las distancias, y dónde puede desbordar la suma? 🟡

⏱️ **30 segundos.** Porque `2·10⁵` aristas de `10⁹` suman `2·10¹⁴`, que no cabe en 32 bits. Puede desbordar en `dist[u] + w` si `dist[u]` es el infinito.

🗣️ **2 minutos.** Con el borrado perezoso, `dist[u]` siempre es finito cuando se relaja, porque `u` salió del montículo. El riesgo está en las versiones sin montículo que relajan desde vértices no alcanzados: hay que comprobar el infinito antes de sumar.

🔬 **El detalle.** Un `INF` de `4·10¹⁸` permite sumar un peso de `10⁹` sin desbordar `long long`; `LLONG_MAX` no.

**01 → 7.** Enuncia el invariante de Dijkstra. 🟡

⏱️ **30 segundos.** Cuando un vértice se extrae (se fija), su distancia es la mínima.

🗣️ **2 minutos.** Los vértices se fijan en orden no decreciente de distancia, y ninguno fijado puede mejorar después. Es el mismo invariante que el de BFS por niveles, con distancias reales en lugar de capas.

🔬 **El detalle.** Es un algoritmo voraz: la elección local (el más cercano) es definitiva.

**01 → 8.** ¿Cuándo es mejor la versión `O(n²)` sin montículo? 🟡

⏱️ **30 segundos.** En grafos densos, con `m` del orden de `n²`: `Θ(n²)` contra `Θ(n² log n)`.

🗣️ **2 minutos.** Con `n = 3 000` y el grafo como matriz, la versión sin montículo hace `9·10⁶` pasos sobre arreglos contiguos; el montículo haría `m log m ≈ 10⁸` con mala localidad. Además es más corta de escribir.

🔬 **El detalle.** Prim tiene la misma dicotomía ([`15/04`](04-arbol-de-expansion-minima.md)).

**01 → 9.** Demuestra el invariante de Dijkstra y señala el paso que usa los pesos no negativos. 🟠

⏱️ **30 segundos.** Si `u` es el primero mal fijado, sea `y` el primer vértice sin fijar de un camino mínimo a `u`: `dist[y] = δ(y) ≤ δ(u) < dist[u]`, y se habría extraído `y` antes. El paso `δ(y) ≤ δ(u)` usa los pesos no negativos.

🗣️ **2 minutos.** `dist[y] = δ(y)` porque su predecesor en el camino ya estaba fijado (bien) y relajó la arista. `δ(y) ≤ δ(u)` porque el resto del camino de `y` a `u` cuesta `≥ 0`. Con un peso negativo en ese resto, la desigualdad se invierte y la prueba se cae.

🔬 **El detalle.** Es la prueba de CLRS (teorema 24.6), por inducción sobre los vértices fijados.

**01 → 10.** Da un contraejemplo de tres vértices con un peso negativo donde Dijkstra falla. 🟠

⏱️ **30 segundos.** `s → a` de 1, `s → b` de 2, `b → a` de `−2`. Dijkstra fija `a` con 1; la distancia real es 0, por `s → b → a`.

🗣️ **2 minutos.** Al sacar `a` (1) antes que `b` (2), `a` queda fijado; cuando `b` relaja `b → a`, `a` ya no se actualiza (o se actualiza pero sus sucesores ya se calcularon con el valor viejo).

🔬 **El detalle.** Sumar 2 a todos los pesos no lo arregla: el camino directo pasa a costar 3 y el otro 4, y el mínimo cambia.

**01 → 11.** ¿Qué pasa exactamente si quitas la comprobación de las entradas viejas? ¿Es incorrecto o lento? 🟠

⏱️ **30 segundos.** Sigue siendo correcto, pero puede ser lento: cada entrada vieja vuelve a recorrer los vecinos de su vértice sin mejorar nada.

🗣️ **2 minutos.** Las relajaciones desde una entrada vieja fallan, porque `dist[v] ≤ dist[u] + w < d_vieja + w`. El coste es `Σ (entradas de u) · grado(u)`: un vértice con `10⁵` vecinos y `10⁵` entradas viejas son `10¹⁰` pasos.

🔬 **El detalle.** Es un fallo de los que pasan todos los ejemplos y dan TLE en un caso diseñado: un vértice central que mejora muchas veces.

**01 → 12.** ¿Cómo adaptas Dijkstra para «minimizar el máximo peso del camino», y por qué sigue siendo correcto? 🔴

⏱️ **30 segundos.** Sustituyendo la suma por el máximo: `nuevo = max(dist[u], w)`. Sigue siendo correcto porque alargar un camino nunca reduce su máximo: la monotonía que usaba la prueba se conserva.

🗣️ **2 minutos.** La prueba de Dijkstra solo necesita que el coste de un camino no baje al añadirle aristas y que se compare bien. Con `max`, se cumple. Lo mismo con el producto de probabilidades en `[0, 1]` maximizando.

🔬 **El detalle.** Para el mínimo de los máximos (camino *minimax*) también vale el árbol de expansión mínima: el camino en el MST es óptimo (`15/04`).

**01 → 13.** Diseña el estado para el camino más barato con hasta `k` aristas gratis y di su coste. 🔴

⏱️ **30 segundos.** Estado `(vértice, aristas gratis usadas)`, con `k + 1` capas. Desde `(u, j)`, pagar lleva a `(v, j)` con coste `w`; usar una gratis, a `(v, j + 1)` con 0. Coste `Θ(k (n + m) log(k n))`.

🗣️ **2 minutos.** La respuesta es el mínimo sobre `j` del destino. Dos llegadas al mismo vértice con distinto número de gratis usadas tienen futuros distintos, por eso el contador va en el estado.

🔬 **El detalle.** Con `k` grande (cerca de `n`), basta saber que con `k ≥` el número de aristas del camino todo es gratis; el estado se puede acotar.

**01 → Problema: Tiempos desde el depósito.**

**Pista 2:** Dijkstra con montículo y borrado perezoso, en 64 bits.

**Pista 3:** imprime `-1` para los que quedan con infinito; con `2·10⁵` aristas, lectura rápida.

**01 → Problema: El más barato y el más corto.**

**Pista 2:** Dijkstra con la distancia como par `(coste, aristas)` comparado lexicográficamente.

**Pista 3:** relaja con `(dist[u].coste + w, dist[u].aristas + 1)` y compara el par entero; el montículo ordena por el par.

**01 → Problema: Trenes con horario.**

**Pista 2:** Dijkstra sobre el instante de llegada: llegar antes nunca es peor (puedes esperar), así que la relajación es monótona.

**Pista 3:** desde `u` con instante `t`, la línea sale en `⌈t / p⌉ · p` y llega `d` después; instantes en 64 bits.

**01 → Problema: Shortest Routes I.**

**Pista 2:** Dijkstra dirigido desde 1.

**Pista 3:** 64 bits, lectura rápida y el `continue` de las entradas viejas.

**01 → Problema: Network Delay Time.**

**Pista 2:** Dijkstra desde `k`; la respuesta es la mayor distancia.

**Pista 3:** si algún nodo queda en infinito, `-1`.

**01 → Problema: Dijkstra: Shortest Reach 2.**

**Pista 2:** Dijkstra no dirigido; con aristas repetidas, todas valen (Dijkstra elige sola la menor).

**Pista 3:** imprime las distancias sin el origen, `-1` los inalcanzables; varios casos por entrada.

**01 → Problema: Path With Minimum Effort.**

**Pista 2:** Dijkstra en rejilla con `max(dist[u], |altura[u] − altura[v]|)` como relajación.

**Pista 3:** la respuesta es la distancia de la esquina inferior derecha; alternativa: binaria sobre el esfuerzo con BFS.

**01 → Problema: Path with Maximum Probability.**

**Pista 2:** Dijkstra maximizando el producto: montículo de máximos sobre la probabilidad.

**Pista 3:** relaja con `p[u] · prob(u, v) > p[v]`; si no se alcanza, 0.

**01 → Problema: Cheapest Flights Within K Stops.**

**Pista 2:** estado `(aeropuerto, escalas)`, o Bellman-Ford con `k + 1` rondas sobre una copia del arreglo.

**Pista 3:** en las rondas, relaja desde la copia de la ronda anterior para no encadenar dos vuelos en la misma ronda.

**01 → Problema: Swim in Rising Water.**

**Pista 2:** Dijkstra con máximo: el instante en que puedes estar en una casilla es el máximo entre tu instante y su altura.

**Pista 3:** la respuesta es la distancia de la esquina; alternativa con Union-Find, añadiendo casillas por altura.

**01 → Problema: Full Tank?.**

**Pista 2:** Dijkstra sobre `(ciudad, combustible)`: echar una unidad es una arista al mismo lugar con el precio del litro; conducir, una arista gratis que gasta combustible.

**Pista 3:** `1 000 · 101` estados por consulta; responde al sacar el destino con cualquier combustible.

**01 → Problema: Minimum Cost to Reach Destination in Time.**

**Pista 2:** el estado es `(ciudad, tiempo)` con `tiempo ≤ maxTime`, o Dijkstra por coste guardando el mejor tiempo por ciudad.

**Pista 3:** DP sobre el tiempo: `cost[t][v]` para `t` de 0 a `maxTime`, relajando cada arista; `1 000 · 1 000` estados.

**01 → Problema: Dijkstra?.**

**Pista 2:** Dijkstra con padres, en 64 bits.

**Pista 3:** si `n` es inalcanzable, `-1`; si no, reconstruye desde `n` e imprime al revés.

**01 → Problema: Flight Routes.**

**Pista 2:** deja salir cada vértice del montículo hasta `k` veces: la `j`-ésima salida de `n` es la `j`-ésima ruta más barata.

**Pista 3:** cuenta las salidas por vértice y no expandas uno que ya salió `k` veces; el montículo llega a `k · m` entradas.

**01 → Problema: Second Minimum Time to Reach Destination.**

**Pista 2:** guarda las dos menores distancias (en aristas) distintas por vértice con un BFS.

**Pista 3:** convierte el número de aristas en tiempo simulando los semáforos al final; la segunda distancia estrictamente mayor.

---

# 02 — Bellman-Ford, Floyd-Warshall y Johnson

**02 → 1.** ¿Por qué Bellman-Ford necesita como mucho `n − 1` rondas? 🟢

⏱️ **30 segundos.** Porque, sin ciclos negativos, un camino mínimo es simple y tiene como mucho `n − 1` aristas, y cada ronda alarga en una arista los caminos ya correctos.

🗣️ **2 minutos.** Tras la ronda `k`, cada vértice tiene como mucho el coste del mejor camino de `k` aristas. Con `k = n − 1` se cubren todos los caminos simples. Si una ronda no cambia nada, se puede parar antes.

🔬 **El detalle.** El número real de rondas es la mayor cantidad de aristas de un camino mínimo, que puede ser mucho menor que `n − 1`, y depende del orden en que se recorran las aristas.

**02 → 2.** ¿Cómo detecta Bellman-Ford un ciclo negativo? 🟢

⏱️ **30 segundos.** Haciendo una ronda más, la `n`-ésima: si todavía se relaja alguna arista, hay un ciclo negativo alcanzable desde el origen.

🗣️ **2 minutos.** Sin ciclos negativos, tras `n − 1` rondas todo está en su valor final y nada puede mejorar. Si algo mejora, es porque hay caminos cada vez más baratos de longitud creciente: un ciclo negativo.

🔬 **El detalle.** El vértice que mejora en la ronda `n` no tiene por qué estar en el ciclo, pero siguiendo sus padres `n` veces se cae dentro.

**02 → 3.** ¿Cuánto cuestan Bellman-Ford y Floyd-Warshall? 🟢

⏱️ **30 segundos.** Bellman-Ford `Θ(n · m)`; Floyd-Warshall `Θ(n³)` tiempo y `Θ(n²)` memoria.

🗣️ **2 minutos.** Bellman-Ford hace `n − 1` rondas de `m` relajaciones; Floyd, `n` rondas sobre la matriz de `n²`. Con `n = 500`, Floyd son `1,25·10⁸` operaciones sencillas: cabe en C++ y Java.

🔬 **El detalle.** Con salida anticipada, Bellman-Ford suele ser mucho más rápido que su cota en grafos sin caminos mínimos largos.

**02 → 4.** ¿Qué indica `d[i][i] < 0` al terminar Floyd-Warshall? 🟡

⏱️ **30 segundos.** Que `i` está en un ciclo negativo.

🗣️ **2 minutos.** `d[i][i]` empieza en 0 y solo baja si hay un camino de `i` a `i` de coste negativo. Si existe, las distancias de cualquier par `(u, v)` con un camino `u → i → v` son `−∞`.

🔬 **El detalle.** Para marcar los pares `−∞`: `d[u][v] = −∞` si existe `k` con `d[u][k] < ∞`, `d[k][v] < ∞` y `d[k][k] < 0`.

**02 → 5.** ¿Por qué hay que comprobar `dist[u] != INF` antes de relajar? 🟡

⏱️ **30 segundos.** Porque `INF + w` con `w` negativo puede quedar por debajo de `INF` y «mejorar» un vértice inalcanzable.

🗣️ **2 minutos.** En Bellman-Ford se relajan aristas que salen de vértices todavía no alcanzados; si `INF` es un número, `INF − 5 < INF` y el vértice destino queda con una distancia falsa. Además, con `LLONG_MAX` la suma desborda.

🔬 **El detalle.** En Dijkstra con borrado perezoso no pasa, porque solo se relaja desde vértices extraídos, que tienen distancia finita.

**02 → 6.** ¿Qué es SPFA y por qué no es más rápido en el peor caso? 🟡

⏱️ **30 segundos.** Bellman-Ford con una cola: solo se relaja desde los vértices que cambiaron. En el peor caso cada vértice entra `Θ(n)` veces y el coste es `Θ(n · m)`, igual que Bellman-Ford.

🗣️ **2 minutos.** En grafos aleatorios suele ser rápido, de ahí su fama. Pero hay construcciones (rejillas con pesos elegidos) que obligan a reinsertar vértices una y otra vez; los jueces las incluyen. Con pesos no negativos, Dijkstra es mejor y garantizado.

🔬 **El detalle.** Las variantes con heurísticas de orden (SLF, LLL) también tienen casos adversarios.

**02 → 7.** ¿Cómo marcas los vértices con distancia `−∞`? 🟡

⏱️ **30 segundos.** Los que mejoran en la ronda `n` (o en `n` rondas más) y todo lo que se alcanza desde ellos con un recorrido.

🗣️ **2 minutos.** Un vértice tiene distancia `−∞` si hay un camino del origen a un ciclo negativo y del ciclo a él. Los que mejoran en la ronda `n` son alcanzables desde algún ciclo; un BFS o DFS desde todos ellos marca el resto.

🔬 **El detalle.** Si solo interesa un destino (como en High Score), basta saber si alguno de los vértices que mejoran alcanza el destino y es alcanzable desde el origen.

**02 → 8.** ¿Cómo escribes Floyd-Warshall en Python si `n = 500` y CPython no da? 🟡

⏱️ **30 segundos.** Con NumPy: cada ronda `k` es una operación vectorial `d = np.minimum(d, d[:, k, None] + d[None, k, :])`.

🗣️ **2 minutos.** Los tres bucles en CPython son `1,25·10⁸` pasos de intérprete: decenas de segundos. Con NumPy, el bucle interno pasa a C: `n` operaciones de `n²`. Si NumPy no está permitido, PyPy o cambiar de algoritmo (Dijkstra desde cada vértice si el grafo es disperso).

🔬 **El detalle.** En los jueces que no tienen NumPy, Floyd con `n = 500` en Python no pasa: es uno de los casos donde el lenguaje decide.

**02 → 9.** Demuestra el lema de las rondas de Bellman-Ford. 🟠

⏱️ **30 segundos.** Tras la ronda `k`, `dist[v]` es como mucho el coste del mejor camino con como mucho `k` aristas. Por inducción: el prefijo de `k − 1` aristas ya está, y la ronda `k` relaja la última.

🗣️ **2 minutos.** `dist[v] ≥ δ(v)` siempre, porque corresponde a un camino real. Con la desigualdad del lema y `k = n − 1`, y sin ciclos negativos (los caminos mínimos son simples), `dist = δ`.

🔬 **El detalle.** El lema no depende del orden de las aristas dentro de cada ronda: un orden afortunado solo adelanta el resultado.

**02 → 10.** Explica Floyd-Warshall como DP y por qué `k` tiene que ir por fuera. 🟠

⏱️ **30 segundos.** `d_k[i][j]` es el camino mínimo usando solo `1..k` como intermedios: o no pasa por `k`, o pasa una vez y se parte en `i → k` y `k → j`. La ronda `k` necesita la tabla completa de la ronda `k − 1`: por eso `k` va por fuera.

🗣️ **2 minutos.** Con `k` por dentro, al calcular `d[i][j]` se usan valores `d[i][k]` y `d[k][j]` que todavía no están terminados, y nadie vuelve a calcular `d[i][j]` después. Con `2 → 1`, `3 → 4` y `4 → 2`, el par `(3, 1)` queda en infinito.

🔬 **El detalle.** Se ha demostrado que repetir tres veces el orden incorrecto da el resultado correcto, pero es una curiosidad: se escribe con `k` por fuera.

**02 → 11.** ¿Cómo limitas Bellman-Ford a caminos de como mucho `k` aristas, y qué error típico evitas? 🟠

⏱️ **30 segundos.** `k` rondas en las que se relaja desde una **copia** de las distancias de la ronda anterior.

🗣️ **2 minutos.** Si se relaja sobre el mismo arreglo, en una ronda se pueden encadenar varias aristas (si están en orden favorable) y el límite se rompe. Con la copia, cada ronda añade exactamente una arista.

🔬 **El detalle.** Es el caso de Cheapest Flights Within K Stops: `k` escalas son `k + 1` aristas.

**02 → 12.** ¿Por qué la repesada de Johnson conserva los caminos mínimos y deja los pesos no negativos? 🔴

⏱️ **30 segundos.** Con `h` de distancias desde una superfuente, `h(v) ≤ h(u) + w(u, v)`, así que `w + h(u) − h(v) ≥ 0`. Cada camino de `s` a `t` cambia en `h(s) − h(t)`, la misma constante para todos.

🗣️ **2 minutos.** Al sumar a lo largo de un camino, los términos `h` intermedios se cancelan (telescópica): solo quedan los de los extremos. Por eso el orden de los caminos entre `s` y `t` no cambia, y los mínimos siguen siendo mínimos. Se corre Dijkstra con `w′` y se deshace la repesada.

🔬 **El detalle.** Es la misma idea que los potenciales de los flujos de coste mínimo ([`15/06`](06-emparejamientos.md)).

**02 → 13.** ¿Cómo detectas una oportunidad de arbitraje entre monedas con tasas de cambio? 🔴

⏱️ **30 segundos.** Con aristas de peso `−log(tasa)`: un ciclo con producto de tasas mayor que 1 es un ciclo de suma negativa. Bellman-Ford o Floyd lo detectan.

🗣️ **2 minutos.** `∏ tasas > 1` equivale a `Σ log(tasas) > 0`, es decir, `Σ −log(tasas) < 0`. Con pocos nodos (monedas), Floyd con `d[i][i] < 0`; con más, Bellman-Ford desde una superfuente.

🔬 **El detalle.** Con coma flotante hay que comparar con un margen (`< −1e−9`), o trabajar con productos directamente y comparar con `1 + ε`.

**02 → Problema: El par más lejano.**

**Pista 2:** Floyd-Warshall y el máximo de las distancias finitas.

**Pista 3:** distancias en 64 bits; los pares no conectados (infinito) no cuentan; si no hay ninguno conectado, 0.

**02 → Problema: Estaciones sin fondo.**

**Pista 2:** Bellman-Ford desde 1 con `n − 1` rondas y una más: los que mejoran están afectados por un ciclo negativo.

**Pista 3:** desde todos los que mejoran en la ronda `n`, un recorrido marca lo alcanzable; cuenta los marcados. Solo cuentan los alcanzables desde 1.

**02 → Problema: Pares alcanzables.**

**Pista 2:** cierre transitivo con Floyd booleano sobre `bitset`.

**Pista 3:** para cada `k` y cada `i` con `R[i][k]`, `R[i] |= R[k]`: `n³/64 ≈ 1,25·10⁸`. Al final, cuenta los unos fuera de la diagonal (la diagonal puede tener unos por los ciclos).

**02 → Problema: Shortest Routes II.**

**Pista 2:** Floyd-Warshall y respuestas en `O(1)`.

**Pista 3:** inicializa con el mínimo de las carreteras repetidas; distancias en 64 bits; `-1` si es infinito.

**02 → Problema: Find the City With the Smallest Number of Neighbors at a Threshold Distance.**

**Pista 2:** Floyd-Warshall y contar, por ciudad, cuántas están a distancia `≤ distanceThreshold`.

**Pista 3:** en empate, la de mayor índice: recorre en orden y usa `≤` al comparar.

**02 → Problema: Floyd : City of Blinding Lights.**

**Pista 2:** Floyd-Warshall; si una arista dirigida aparece varias veces, cuenta la **última**.

**Pista 3:** `-1` si no hay camino; la distancia de un nodo a sí mismo es 0.

**02 → Problema: Minimum Cost to Convert String I.**

**Pista 2:** Floyd sobre las 26 letras con los costes de conversión.

**Pista 3:** suma, posición a posición, el coste mínimo de `source[i]` a `target[i]`; si alguno es infinito, `-1`. Aristas repetidas: el mínimo.

**02 → Problema: High Score.**

**Pista 2:** niega los pesos y busca el camino mínimo con Bellman-Ford; un ciclo negativo importa solo si es alcanzable desde 1 y llega a `n`.

**Pista 3:** marca los que mejoran en la ronda `n`, propaga hacia delante, y comprueba alcanzabilidad hacia atrás desde `n`; si alguno cumple las dos, `-1`.

**02 → Problema: Cycle Finding.**

**Pista 2:** Bellman-Ford desde una superfuente (todas las distancias empiezan en 0) con padres.

**Pista 3:** si en la ronda `n` mejora `x`, sigue `n` veces los padres desde `x` para caer dentro del ciclo, y desde ahí recórrelo hasta volver.

**02 → Problema: Single source shortest path, negative weights.**

**Pista 2:** Bellman-Ford con la marca de `−∞` por alcanzabilidad desde los que mejoran en la ronda `n`.

**Pista 3:** `Impossible` para los inalcanzables, `-Infinity` para los marcados; varios casos por entrada.

**02 → Problema: All Pairs Shortest Path.**

**Pista 2:** Floyd-Warshall y, después, los pares que pasan por un `k` con `d[k][k] < 0` son `−∞`.

**Pista 3:** un segundo triple bucle: si `d[i][k] < ∞`, `d[k][j] < ∞` y `d[k][k] < 0`, `d[i][j] = −∞`.

**02 → Problema: Greg and Graph.**

**Pista 2:** añade los vértices en orden inverso al borrado; cada vértice añadido es el siguiente `k` de Floyd.

**Pista 3:** tras añadir el `k`-ésimo, suma las distancias entre los vértices ya añadidos; imprime las sumas al revés. 64 bits.

**02 → Problema: Arbitrage?.**

**Pista 2:** Floyd con productos (maximizando) o con `−log`: hay arbitraje si `d[i][i] > 1` (o `< 0` con logaritmos).

**Pista 3:** los nombres de moneda a índices con un mapa; las tasas vienen como fracciones `a:b`; compara con un margen.

---

# 03 — A\* y heurísticas admisibles

**03 → 1.** ¿Qué diferencia hay entre `g`, `h` y `f` en A\*? 🟢

⏱️ **30 segundos.** `g(v)` es el coste del mejor camino conocido de `S` a `v`; `h(v)`, la estimación de lo que falta hasta `T`; `f = g + h`, la estimación del camino total por `v`, que es la prioridad.

🗣️ **2 minutos.** `g` es exacto para lo recorrido (como la `dist` de Dijkstra); `h` es una predicción que no se recorre. A\* expande primero el vértice con menor `f`, el que promete el camino total más barato.

🔬 **El detalle.** Con `h = 0`, `f = g` y A\* es Dijkstra; con `h = h*`, solo expande vértices del camino óptimo.

**03 → 2.** ¿Qué es una heurística admisible? 🟢

⏱️ **30 segundos.** Una que nunca sobreestima: `h(v) ≤ h*(v)`, el coste real mínimo de `v` a `T`.

🗣️ **2 minutos.** Si `h` sobreestimara el camino bueno, A\* podría preferir uno peor que parece más prometedor y terminar con él. Admisible garantiza que el camino óptimo nunca parece peor de lo que es.

🔬 **El detalle.** Con reapertura de vértices, admisible basta para la optimalidad; sin reapertura, hace falta consistente.

**03 → 3.** ¿Por qué A\* con `h = 0` es Dijkstra? 🟢

⏱️ **30 segundos.** Porque con `h = 0`, `f = g`: la prioridad es la distancia provisional, que es la de Dijkstra.

🗣️ **2 minutos.** `h = 0` es admisible y consistente (los pesos son no negativos), así que A\* es correcto, pero no tiene información: expande lo mismo que Dijkstra.

🔬 **El detalle.** Por eso A\* «nunca es peor que Dijkstra» en número de expansiones con `h` consistente, salvo empates; en tiempo, puede serlo por el coste de calcular `h`.

**03 → 4.** ¿Qué es una heurística consistente y por qué implica admisible? 🟡

⏱️ **30 segundos.** `h(T) = 0` y `h(u) ≤ w(u, v) + h(v)` para toda arista. Sumando la desigualdad a lo largo de un camino mínimo de `v` a `T`, queda `h(v) ≤ h*(v)`.

🗣️ **2 minutos.** Es la desigualdad triangular: la estimación desde `u` no supera dar un paso más la estimación desde el vecino. Por eso `f` no decrece a lo largo de un camino, y los vértices salen en orden de `f` no decreciente, como en Dijkstra.

🔬 **El detalle.** Las heurísticas geométricas de rejilla (Manhattan, Chebyshev, euclídea) son consistentes por la desigualdad triangular de sus métricas.

**03 → 5.** ¿Por qué se para al extraer el destino y no al descubrirlo? 🟡

⏱️ **30 segundos.** Porque al descubrir `T` su `g` es provisional: puede haber otro camino más barato que todavía no se ha explorado. Al extraerlo, con `h` consistente, su `g` es final.

🗣️ **2 minutos.** Es la misma razón que en Dijkstra: las distancias solo son definitivas cuando el vértice sale del montículo. Parar al descubrirlo da caminos subóptimos en cuanto hay una arista cara que llega antes a `T`.

🔬 **El detalle.** En BFS con pasos iguales sí se puede parar al descubrir, porque la primera vez ya es la mínima.

**03 → 6.** ¿Qué heurística usas en una rejilla de 4 direcciones, en una de 8 y en un puzzle de 15? 🟡

⏱️ **30 segundos.** 4 direcciones: Manhattan. 8 direcciones con coste 1: Chebyshev (o octil si la diagonal cuesta `√2`). Puzzle de 15: suma de las distancias Manhattan de cada ficha a su sitio.

🗣️ **2 minutos.** Todas son la distancia en el problema relajado sin obstáculos, y por eso no sobreestiman. En el puzzle, cada movimiento mueve una sola ficha una casilla, así que hacen falta al menos tantos movimientos como la suma.

🔬 **El detalle.** Las bases de datos de patrones (precalcular el coste exacto de subconjuntos de fichas) dan heurísticas mucho más fuertes para el 15.

**03 → 7.** ¿Qué hace el desempate por mayor `g` y por qué no afecta a la corrección? 🟡

⏱️ **30 segundos.** A igual `f`, saca primero el de mayor `g` (más cerca de `T`); así avanza en profundidad hacia el destino en lugar de abrir un frente ancho de empates.

🗣️ **2 minutos.** No afecta a la corrección porque el invariante solo exige sacar el menor `f`; entre iguales, cualquier orden vale. En rejillas abiertas con Manhattan hay muchísimos empates, y el desempate reduce mucho las expansiones.

🔬 **El detalle.** Desempatar por menor `h` es equivalente a mayor `g` cuando `f` es igual.

**03 → 8.** Demuestra que con `h` consistente A\* es óptimo, usando la repesada. 🟠

⏱️ **30 segundos.** Con `w′(u, v) = w − h(u) + h(v) ≥ 0` (la consistencia), el coste repesado de un camino de `S` a `v` es `g(v) − h(S) + h(v) = f(v) − h(S)`. Ordenar por `f` es Dijkstra sobre `w′`, que es correcto.

🗣️ **2 minutos.** Como `h(S)` es una constante, minimizar `f` es minimizar la distancia repesada. Dijkstra sobre pesos no negativos fija cada vértice con su distancia final, y al fijar `T`, `g(T) = f(T) − h(T)` con `h(T) = 0` es la distancia real.

🔬 **El detalle.** Es la repesada de Johnson con `h` como potencial (`15/02`).

**03 → 9.** Da un ejemplo de heurística admisible pero no consistente donde A\* con conjunto cerrado falla. 🟠

⏱️ **30 segundos.** `S → A` 1, `S → B` 2, `A → C` 3, `B → C` 1, `C → T` 3, con `h(B) = 4` y 0 en el resto. A\* cierra `C` por `A` con `g = 4` antes de sacar `B` (`f = 6`), y devuelve 7 en lugar de 6.

🗣️ **2 minutos.** `h(B) = 4 = h*(B)` es admisible, pero `h(B) > w(B, C) + h(C) = 1`: no es consistente. La heurística retrasa a `B`, y cuando sale, `C` ya está cerrado y no se reabre.

🔬 **El detalle.** Permitiendo reabrir `C` (sacarlo de cerrados si mejora), A\* devuelve 6, al precio de expandir vértices varias veces.

**03 → 10.** ¿Por qué A\* no es siempre más rápido que Dijkstra? 🟠

⏱️ **30 segundos.** Porque su ventaja depende de lo informativa que sea `h`: con `h` pobre expande casi lo mismo que Dijkstra y además paga el cálculo de `h`.

🗣️ **2 minutos.** En laberintos donde la línea recta engaña, A\* explora pasillos que apuntan a `T` y no llevan a él. Y si se piden distancias a todos los vértices, A\* no tiene a dónde apuntar.

🔬 **El detalle.** En el peor caso tiene la misma complejidad que Dijkstra; la mejora es empírica y depende del dominio.

**03 → 11.** ¿Qué es IDA\* y cuándo lo prefieres a A\*? 🔴

⏱️ **30 segundos.** A\* en profundidad con un umbral sobre `f` que sube en cada iteración; usa memoria lineal. Se prefiere cuando A\* se queda sin memoria, como en el puzzle de 15.

🗣️ **2 minutos.** Cada iteración es un DFS que poda cuando `f` supera el umbral; el siguiente umbral es el menor `f` podado. Con `h` admisible, la primera solución es óptima. Repite trabajo, pero con costes enteros el número de iteraciones es pequeño.

🔬 **El detalle.** Es la profundización iterativa de [`10/04`](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md) con `f` en lugar de la profundidad.

**03 → 12.** Si tienes dos heurísticas admisibles, ¿cómo las combinas y por qué sigue siendo admisible? 🔴

⏱️ **30 segundos.** Con el máximo: `h = max(h₁, h₂)`. Si las dos no sobreestiman, su máximo tampoco.

🗣️ **2 minutos.** El máximo domina a las dos, así que expande como mucho lo que cada una; y si las dos son consistentes, el máximo también lo es. La suma, en cambio, puede sobreestimar.

🔬 **El detalle.** Las bases de datos de patrones disjuntas permiten sumar, porque cada movimiento solo afecta a un patrón.

**03 → Problema: Rejilla con pantanos.**

**Pista 2:** Dijkstra o A\* con Manhattan, porque el paso más barato cuesta 1.

**Pista 3:** el coste se paga al entrar en la casilla; con `10⁶` casillas, casilla aplanada y distancias en un arreglo.

**03 → Problema: ¿Sirve esta heurística?.**

**Pista 2:** Dijkstra desde `T` sobre el grafo con las aristas invertidas da `h*` de todos los vértices.

**Pista 3:** admisible si `h(v) ≤ h*(v)` en todos (con `h* = ∞` siempre se cumple); consistente si además `h(T) = 0` y `h(u) ≤ w + h(v)` en cada arista. Consistente implica admisible: compruébalo en ese orden.

**03 → Problema: A-star exercise.**

**Pista 2:** A\* con la heurística que da la entrada y el desempate que fija el enunciado.

**Pista 3:** imprime cada nodo al expandirlo con su `f`; un nodo ya cerrado no se vuelve a expandir.

**03 → Problema: N-Puzzle.**

**Pista 2:** la suma de las distancias Manhattan de cada ficha a su posición objetivo.

**Pista 3:** el hueco no cuenta; calcula la posición objetivo de cada letra a partir de su orden.

**03 → Problema: Sliding Puzzle.**

**Pista 2:** BFS (o A\*) sobre los `6! = 720` tableros como cadenas.

**Pista 3:** los vecinos intercambian el 0 con una casilla adyacente; precalcula las adyacencias de las 6 posiciones.

**03 → Problema: Cut Off Trees for Golf Event.**

**Pista 2:** ordena los árboles por altura y suma las distancias entre consecutivos, cada una con una búsqueda punto a punto.

**Pista 3:** BFS o A\* con Manhattan para cada tramo; si alguno es inalcanzable, `-1`.

**03 → Problema: Minimum Moves to Move a Box to Their Target Location.**

**Pista 2:** estado `(caja, jugador)`; cuenta solo los empujones (0-1 BFS o A\* con la Manhattan de la caja).

**Pista 3:** mover al jugador sin empujar cuesta 0; empujar, 1, y exige que el jugador pueda llegar detrás de la caja.

**03 → Problema: Minimum Moves to Reach Target with Rotations.**

**Pista 2:** BFS sobre `(fila, columna, orientación)` de la cola de la serpiente.

**Pista 3:** cuatro movimientos por estado (derecha, abajo y las dos rotaciones) con sus condiciones de casillas libres.

**03 → Problema: Death First Search - Episode 1.**

**Pista 2:** en cada turno, si el agente está junto a una salida, corta ese enlace; si no, corta cualquier enlace de una salida.

**Pista 3:** un BFS desde el agente da la salida más cercana y el enlace que conviene cortar.

**03 → Problema: The Labyrinth.**

**Pista 2:** explora con BFS hacia la casilla desconocida más cercana; al encontrar la sala de control, vuelve por el camino más corto conocido.

**Pista 3:** antes de entrar en la sala, comprueba que el camino de vuelta cabe en la cuenta atrás.

---

# 04 — Árbol de expansión mínima

**04 → 1.** ¿Qué es un árbol de expansión mínima y cuántas aristas tiene? 🟢

⏱️ **30 segundos.** Un árbol que conecta todos los vértices de un grafo con el menor peso total posible. Tiene `n − 1` aristas.

🗣️ **2 minutos.** Conectar sin ciclos (un ciclo tiene una arista que sobra) y con el mínimo peso. Si el grafo no es conexo no hay árbol de expansión, sino un bosque, uno por componente.

🔬 **El detalle.** Con todos los pesos distintos, el MST es único; con repetidos puede haber varios, todos del mismo peso.

**04 → 2.** Describe Kruskal en dos pasos. 🟢

⏱️ **30 segundos.** Ordenar las aristas por peso; recorrerlas añadiendo cada una que une dos componentes distintas (Union-Find), hasta tener `n − 1`.

🗣️ **2 minutos.** Las aristas que cerrarían un ciclo se saltan, porque sus extremos ya están en la misma componente. Cada arista añadida es la más ligera que cruza el corte entre su componente y el resto. Coste `Θ(m log m)`.

🔬 **El detalle.** Se puede parar al tener `n − 1` aristas sin mirar el resto.

**04 → 3.** Describe Prim y di qué prioridad usa el montículo. 🟢

⏱️ **30 segundos.** Crecer un árbol desde un vértice añadiendo siempre el vértice de fuera más barato de conectar. La prioridad del montículo es el peso de la arista que lo conecta al árbol.

🗣️ **2 minutos.** Con borrado perezoso, como Dijkstra: se mete `(peso, vértice)` por cada arista hacia fuera y se ignoran las entradas de vértices ya en el árbol. Coste `Θ(m log n)`.

🔬 **El detalle.** La prioridad no es la distancia acumulada: ese es el error que lo convierte en Dijkstra.

**04 → 4.** ¿Cuánto cuestan Kruskal y Prim, con y sin montículo? 🟢

⏱️ **30 segundos.** Kruskal `Θ(m log m)`; Prim con montículo `Θ(m log n)`; Prim sin montículo `Θ(n²)`.

🗣️ **2 minutos.** Kruskal está dominado por la ordenación; Union-Find es casi constante. Prim con montículo hace una inserción por arista. Sin montículo, `n` búsquedas lineales del mínimo, que es lo mejor en grafos densos.

🔬 **El detalle.** Con montículo de Fibonacci, Prim baja a `Θ(m + n log n)`.

**04 → 5.** ¿Qué detecta comprobar que Kruskal añadió `n − 1` aristas? 🟡

⏱️ **30 segundos.** Que el grafo es conexo. Si Kruskal termina con menos de `n − 1` aristas, hay varias componentes y no existe árbol de expansión.

🗣️ **2 minutos.** Lo que se obtiene en ese caso es el bosque de expansión mínima. Muchos enunciados piden `IMPOSSIBLE` justamente ahí; en Prim, la comprobación equivalente es que se añadieron `n` vértices.

🔬 **El detalle.** El número de componentes es `n −` aristas añadidas.

**04 → 6.** ¿Funciona el MST con pesos negativos? 🟡

⏱️ **30 segundos.** Sí: Kruskal y Prim solo comparan pesos, así que lo único que importa es su orden.

🗣️ **2 minutos.** A diferencia de Dijkstra, el MST no suma pesos a lo largo de caminos para tomar decisiones; las propiedades del corte y del ciclo valen para cualquier peso real.

🔬 **El detalle.** Por la misma razón, aplicar una función creciente a todos los pesos no cambia el MST.

**04 → 7.** ¿Cómo obtienes el árbol de expansión de peso **máximo**? 🟡

⏱️ **30 segundos.** Kruskal recorriendo las aristas de la más pesada a la más ligera (o negando los pesos).

🗣️ **2 minutos.** Las propiedades del corte y del ciclo valen con el orden invertido. Prim también sirve con un montículo de máximos.

🔬 **El detalle.** El árbol de peso máximo maximiza la arista más ligera del camino entre dos vértices: es el de «el camión más pesado que puede pasar».

**04 → 8.** Enuncia y demuestra la propiedad del corte. 🟠

⏱️ **30 segundos.** En cualquier corte, la arista más ligera que lo cruza está en algún MST. Si un MST `T` no la tiene, su camino entre los extremos cruza el corte por otra `f`; `T − f + e` no pesa más.

🗣️ **2 minutos.** El camino en `T` entre `u` y `v` empieza en un lado del corte y termina en el otro, así que cruza por alguna arista `f`. Quitar `f` parte `T` en dos componentes, una con `u` y otra con `v`, y `e` las vuelve a unir. Como `w(e) ≤ w(f)`, el nuevo árbol es también mínimo.

🔬 **El detalle.** Si `e` es la única más ligera (estrictamente), está en **todos** los MST.

**04 → 9.** Enuncia y demuestra la propiedad del ciclo. 🟠

⏱️ **30 segundos.** En un ciclo, la arista estrictamente más pesada no está en ningún MST. Si estuviera, quitarla y poner otra arista del ciclo que reconecte daría un árbol más ligero.

🗣️ **2 minutos.** Al quitar `f` de `T` quedan dos componentes; el resto del ciclo va de un extremo de `f` al otro y tiene que cruzar entre ellas por alguna arista `e`, más ligera que `f`. `T − f + e` pesa menos: contradicción.

🔬 **El detalle.** Es la base de los algoritmos «inversos» (borrar la arista más pesada mientras no desconecte).

**04 → 10.** ¿En qué se diferencian Prim y Dijkstra? Da un grafo donde den árboles distintos. 🟠

⏱️ **30 segundos.** Prim prioriza por el peso de la arista que conecta al árbol; Dijkstra, por la distancia acumulada desde el origen. En el triángulo `A–B 2`, `B–C 2`, `A–C 3`, Prim desde `A` da `A–B`, `B–C` (4) y Dijkstra `A–B`, `A–C` (5).

🗣️ **2 minutos.** Dijkstra construye el árbol de caminos mínimos desde un origen; Prim, el árbol más barato en total, que no depende del origen. Para `C`, Dijkstra prefiere la arista directa de 3 (distancia 3) a llegar por `B` (distancia 4); Prim prefiere `B–C` (2) a `A–C` (3).

🔬 **El detalle.** La diferencia en código es una sola expresión: `w` frente a `d + w`.

**04 → 11.** ¿Cómo decides si una arista está en algún MST? 🟠

⏱️ **30 segundos.** `(u, v, w)` está en algún MST si y solo si `u` y `v` no están conectados usando solo aristas de peso estrictamente menor que `w`.

🗣️ **2 minutos.** Si lo están, la arista cierra un ciclo donde es la más pesada (estrictamente) y la propiedad del ciclo la excluye. Si no, hay un corte que separa `u` y `v` sin aristas más ligeras que `w`, y la propiedad del corte la incluye en algún MST. Para todas las aristas a la vez: por grupos de igual peso con Union-Find.

🔬 **El detalle.** Para «en todos los MST» hay que mirar además, dentro de su grupo de peso, si es un puente del grafo de componentes ([`14/06`](../14-grafos-recorridos/06-puentes-articulacion-y-euler.md)).

**04 → 12.** ¿Cómo agrupas `n` puntos en `k` grupos maximizando la separación, y por qué es correcto? 🔴

⏱️ **30 segundos.** Kruskal hasta que queden `k` componentes; la separación es el peso de la siguiente arista que uniría dos componentes. Es correcto por un argumento de intercambio (Kleinberg y Tardos, §4.7).

🗣️ **2 minutos.** Cualquier otra partición en `k` grupos separa dos puntos que Kruskal unió con aristas de peso como mucho la separación de Kruskal; esos dos puntos, en grupos distintos, dan una separación no mayor. Equivale a quitar las `k − 1` aristas más pesadas del MST.

🔬 **El detalle.** Es el agrupamiento jerárquico de enlace simple; su defecto conocido es el «encadenamiento» de grupos alargados.

**04 → 13.** Tienes que conectar `5 000` puntos del plano. ¿Kruskal o Prim, y cuál de los dos Prim? Justifica con memoria y tiempo. 🔴

⏱️ **30 segundos.** Prim sin montículo, `Θ(n²)` tiempo y `Θ(n)` memoria, calculando las distancias al vuelo. Kruskal necesitaría guardar y ordenar `1,25·10⁷` aristas.

🗣️ **2 minutos.** Con `n = 5 000`, `n² = 2,5·10⁷` operaciones simples: decenas de milisegundos en C++ o Java. Kruskal: `1,25·10⁷` aristas de tres números son del orden de 300 MB y la ordenación cuesta `n² log n`. Prim con montículo sobre un grafo completo haría `n² log n` también.

🔬 **El detalle.** Para distancia euclídea en el plano, el MST está contenido en la triangulación de Delaunay (`O(n)` aristas), lo que da `Θ(n log n)` (bloque `18`).

**04 → Problema: El tramo más largo.**

**Pista 2:** el MST minimiza también la arista más pesada: la respuesta es su arista más pesada.

**Pista 3:** Kruskal guardando el máximo de las aristas añadidas; si no llega a `n − 1`, `-1`; con `n = 1`, 0.

**04 → Problema: Terreno.**

**Pista 2:** MST sobre el grafo de la rejilla, con `2RC` aristas como mucho.

**Pista 3:** genera las aristas a la derecha y abajo, ordénalas (`5·10⁵`) y Kruskal; el total en 64 bits.

**04 → Problema: ¿Entra en algún árbol?.**

**Pista 2:** procesa las aristas por grupos de igual peso: una arista del grupo entra si sus extremos están en componentes distintas **antes** de unir ninguna del grupo.

**Pista 3:** para cada grupo, primero decide todas sus aristas con `find`, y después une todas las del grupo. Imprime en el orden de la entrada.

**04 → Problema: Road Reparation.**

**Pista 2:** Kruskal y comprobar las `n − 1` aristas.

**Pista 3:** `IMPOSSIBLE` si no se llega; el total en 64 bits.

**04 → Problema: Kruskal (MST): Really Special Subtree.**

**Pista 2:** Kruskal con el desempate del enunciado.

**Pista 3:** el peso total no depende del desempate; imprime solo el total.

**04 → Problema: Prim's (MST) : Special Subtree.**

**Pista 2:** Prim desde el nodo indicado, con el peso de la arista como prioridad.

**Pista 3:** aristas repetidas entre dos nodos: Prim elige sola la más barata.

**04 → Problema: Minimum Spanning Tree.**

**Pista 2:** Kruskal guardando las aristas usadas.

**Pista 3:** imprime cada arista con el menor extremo primero y la lista ordenada; `Impossible` si no es conexo. Varios casos por entrada.

**04 → Problema: Make It Connected.**

**Pista 2:** sin oferta, la arista más barata desde cualquier vértice va al de menor `a`: basta añadir `n − 1` aristas implícitas `(v, mínimo)`.

**Pista 3:** Kruskal sobre las ofertas más esas `n − 1` aristas con peso `a_v + a_min`; total en 64 bits.

**04 → Problema: Shichikuji and Power Grid.**

**Pista 2:** vértice virtual: construir una central en `i` es la arista `(0, i)` de peso `c_i`; el cable entre `i` y `j` cuesta `(k_i + k_j) · distancia Manhattan`.

**Pista 3:** grafo completo de `2 001` vértices: Prim sin montículo en `n²`; guarda de qué vértice viene cada uno para imprimir centrales y cables.

**04 → Problema: Lost Map.**

**Pista 2:** la matriz de distancias de un árbol: su MST (sobre el grafo completo con esos pesos) es el árbol original.

**Pista 3:** Prim sin montículo sobre la matriz, `n ≤ 2 500`, imprimiendo cada arista al añadirla.

**04 → Problema: Find Critical and Pseudo-Critical Edges in Minimum Spanning Tree.**

**Pista 2:** crítica si prohibirla aumenta el peso del MST (o lo desconecta); pseudocrítica si no es crítica y forzarla no lo aumenta.

**Pista 3:** con `m ≤ 200`, un Kruskal por arista para prohibir y otro para forzar: `Θ(m² α)`.

**04 → Problema: Edges in MST.**

**Pista 2:** por grupos de igual peso: las aristas que unen componentes ya conectadas son `none`; entre las demás, las que son puentes en el multigrafo de componentes del grupo son `any`, el resto `at least one`.

**Pista 3:** para cada grupo, construye un grafo pequeño cuyas aristas unen las componentes de Union-Find y busca puentes con `low` (`14/06`), por índice de arista; luego une todo el grupo.

**04 → Problema: GCD and MST.**

**Pista 2:** recorre los índices de menor a mayor valor `a_i < p`: desde cada uno, extiende a izquierda y derecha mientras el valor sea múltiplo de `a_i` y sin cruzar aristas ya puestas.

**Pista 3:** las aristas que faltan entre consecutivos cuestan `p`; con Union-Find o marcas sobre los huecos `i, i + 1`, cada hueco se usa una vez.

---

# 05 — Flujo máximo y corte mínimo

**05 → 1.** ¿Qué dos condiciones cumple un flujo? 🟢

⏱️ **30 segundos.** Capacidad: en cada arista, `0 ≤ f ≤ c`. Conservación: en cada vértice distinto de `s` y `t`, lo que entra es igual a lo que sale.

🗣️ **2 minutos.** El valor del flujo es lo que sale neto de `s` (igual a lo que entra neto en `t`, por la conservación). Con aristas en los dos sentidos entre dos vértices, se suele trabajar con flujo neto.

🔬 **El detalle.** La conservación es lo que permite descomponer cualquier flujo en caminos de `s` a `t` y ciclos.

**05 → 2.** ¿Qué es la red residual y para qué sirven sus aristas de vuelta? 🟢

⏱️ **30 segundos.** La red de lo que aún se puede hacer: `u → v` con `c − f` (lo que cabe) y `v → u` con `f` (lo que se puede deshacer). Las de vuelta permiten redirigir flujo enviado por un camino peor.

🗣️ **2 minutos.** Sin ellas, Ford-Fulkerson es un voraz que se atasca: un primer camino mal elegido ocupa una arista que otros dos caminos necesitaban. Empujar por una arista de vuelta equivale a quitar flujo de la arista original y mandarlo por otro sitio.

🔬 **El detalle.** En la implementación, la vuelta de la arista `e` es `e ^ 1` si se añaden en pares.

**05 → 3.** Enuncia el teorema de flujo máximo y corte mínimo. 🟢

⏱️ **30 segundos.** El valor del flujo máximo de `s` a `t` es igual a la capacidad del corte mínimo que los separa.

🗣️ **2 minutos.** Más precisamente: son equivalentes que `f` sea máximo, que no haya camino aumentante en la residual, y que `|f|` sea la capacidad de algún corte. Cualquier flujo está acotado por cualquier corte, y el algoritmo termina con un flujo que iguala uno.

🔬 **El detalle.** Es un caso particular de la dualidad fuerte de la programación lineal.

**05 → 4.** ¿Cómo encuentras el corte mínimo después de calcular el flujo máximo? 🟡

⏱️ **30 segundos.** Con un BFS desde `s` en la red residual final: lo alcanzado es `S`; las aristas originales de `S` a `T` son el corte.

🗣️ **2 minutos.** Esas aristas están saturadas y su suma es el flujo máximo, por el teorema. Es el corte mínimo más cercano a `s`; desde `t` en la residual invertida sale el más cercano a `t`.

🔬 **El detalle.** Si los dos cortes coinciden, el corte mínimo es único.

**05 → 5.** ¿Qué cambia Edmonds-Karp respecto de Ford-Fulkerson, y qué cota gana? 🟡

⏱️ **30 segundos.** Elige siempre el camino aumentante más corto (BFS). Gana una cota independiente de las capacidades: `O(V · E²)`.

🗣️ **2 minutos.** Con caminos arbitrarios, el número de aumentos puede ser proporcional al valor del flujo (`O(E · |f|)` con enteros) o no terminar con capacidades irracionales. Con el más corto, las distancias desde `s` no decrecen y cada arista es cuello de botella `O(V)` veces.

🔬 **El detalle.** Es el lema 26.7 y el teorema 26.8 de CLRS (3.ª ed.).

**05 → 6.** ¿Cómo modelas capacidades en los vértices? 🟡

⏱️ **30 segundos.** Partiendo cada vértice en `v_in` y `v_out` con una arista `v_in → v_out` de la capacidad del vértice; las aristas que llegan van a `v_in` y las que salen, desde `v_out`.

🗣️ **2 minutos.** Todo flujo que atraviesa `v` pasa por esa arista, así que no puede superar su capacidad. `s` y `t` suelen quedarse sin partir (o con capacidad infinita). El grafo pasa a tener `2n` vértices.

🔬 **El detalle.** Con capacidad 1 en los vértices, el flujo cuenta caminos disjuntos en vértices (teorema de Menger).

**05 → 7.** ¿Por qué falla la suma de las capacidades que salen de la fuente? Da una red. 🟡

⏱️ **30 segundos.** Porque el cuello de botella puede estar más adelante. En R′ (`s→a 3`, `s→b 2`, `a→b 1`, `a→t 1`, `b→t 3`) salen 5 de `s`, pero el máximo es 4.

🗣️ **2 minutos.** El corte `{s, a} | {b, t}` tiene capacidad `a→b 1 + a→t 1 + s→b 2 = 4`: no puede pasar más. Lo que sale de `s` es la capacidad de un corte concreto, `{s}`, que no tiene por qué ser el mínimo.

🔬 **El detalle.** En R original, el corte `{s}` sí es mínimo (5), pero no es el único: `{s, a, b} | {t}` también vale 5.

**05 → 8.** Demuestra que, si no hay camino aumentante, el flujo es máximo. 🟠

⏱️ **30 segundos.** Sea `S` lo alcanzable desde `s` en la residual; `t ∉ S`. Las aristas de `S` a `T` están saturadas y las de `T` a `S` vacías, así que `|f| = c(S, T)`; y ningún flujo supera un corte.

🗣️ **2 minutos.** Si una arista `u → v` con `u ∈ S`, `v ∈ T` tuviera capacidad libre, `v` sería alcanzable. Si una `v → u` con `v ∈ T`, `u ∈ S` tuviera flujo, su vuelta `u → v` estaría en la residual y `v` sería alcanzable. El flujo neto que cruza el corte es entonces exactamente su capacidad, y como todo flujo es `≤` todo corte, `f` es máximo y el corte, mínimo.

🔬 **El detalle.** La prueba es constructiva: da el corte mínimo junto con el flujo.

**05 → 9.** ¿Qué es el grafo de niveles de Dinic y para qué sirve el puntero por vértice? 🟠

⏱️ **30 segundos.** El grafo de niveles conserva solo las aristas residuales de nivel `d` a `d + 1` (por distancia BFS desde `s`). El puntero por vértice salta las aristas ya agotadas durante la fase.

🗣️ **2 minutos.** En el grafo de niveles, todo camino de `s` a `t` es un camino más corto; el DFS los encuentra hasta bloquear (flujo bloqueante). Sin el puntero, el DFS volvería a probar aristas muertas una y otra vez; con él, cada arista se descarta una vez por fase: `O(V · E)` por fase.

🔬 **El detalle.** Tras el flujo bloqueante, la distancia de `s` a `t` aumenta estrictamente: como mucho `V` fases.

**05 → 10.** ¿Cómo cuentas el máximo de caminos disjuntos en aristas entre `s` y `t`? 🟠

⏱️ **30 segundos.** Flujo máximo con capacidad 1 en cada arista: su valor es el número máximo de caminos disjuntos en aristas.

🗣️ **2 minutos.** Por la integralidad, el flujo máximo es entero y se descompone en caminos de una unidad que no comparten aristas. Y por el teorema, es igual al mínimo de aristas que hay que cortar para separar `s` de `t` (Menger).

🔬 **El detalle.** Para recuperar los caminos, se sigue desde `s` cualquier arista con flujo 1, se baja a 0 y se repite hasta `t`.

**05 → 11.** Da una red donde el voraz sin aristas de vuelta no llega al máximo. 🟠

⏱️ **30 segundos.** `s→a 1`, `s→b 1`, `a→b 1`, `a→t 1`, `b→t 1`. Si el primer camino es `s a b t`, sin aristas de vuelta no queda camino: 1. El máximo es 2.

🗣️ **2 minutos.** Con la residual, aparece `s b a t`: usa la vuelta `b → a`, que deshace la unidad de `a → b`. El resultado neto son los caminos `s a t` y `s b t`.

🔬 **El detalle.** Edmonds-Karp no caería en esa trampa (los caminos de longitud 2 van antes), pero hay redes donde el más corto también necesita deshacer.

**05 → 12.** Modela como flujo la selección de proyectos con herramientas compartidas. 🔴

⏱️ **30 segundos.** `s → proyecto` con su beneficio, `herramienta → t` con su coste, `proyecto → herramienta` con capacidad infinita. Ganancia máxima = suma de beneficios − corte mínimo.

🗣️ **2 minutos.** En un corte finito, cada proyecto en el lado de `s` (hecho) arrastra sus herramientas al lado de `s` (compradas), porque las aristas infinitas no se pueden cortar. El corte paga los beneficios de los proyectos no hechos y los costes de las herramientas compradas; minimizarlo maximiza la ganancia.

🔬 **El detalle.** Es el problema del cierre de peso máximo (Kleinberg y Tardos, §7.11).

**05 → 13.** ¿Por qué Dinic es `O(E √V)` con capacidades unitarias, y dónde lo aprovechas? 🔴

⏱️ **30 segundos.** Con capacidades unitarias, cada fase es `O(E)` y hay `O(√V)` fases. Se aprovecha en el emparejamiento bipartito: es Hopcroft-Karp.

🗣️ **2 minutos.** Tras `√V` fases, la distancia es al menos `√V`, y el flujo que falta cabe en como mucho `√V` caminos disjuntos más (cada uno de longitud `≥ √V`, usando vértices distintos); cada fase añade al menos uno. Total `O(E √V)`.

🔬 **El detalle.** Por eso Dinic sobre la red de un bipartito tiene la misma cota que Hopcroft-Karp (`15/06`).

**05 → Problema: Estaciones con límite.**

**Pista 2:** parte cada estación intermedia en entrada y salida con una arista de capacidad `k_v`; flujo máximo de la 1 a la `n`.

**Pista 3:** la arista `u v c` va de `u_out` a `v_in`; la 1 y la `n` sin límite. Dinic o Edmonds-Karp, en 64 bits.

**05 → Problema: El lado de la fuente.**

**Pista 2:** flujo máximo y, después, un BFS desde 1 por aristas con capacidad residual positiva.

**Pista 3:** cuenta los alcanzados (incluida la 1). Si una arista tiene capacidad libre, su destino está en el lado de la fuente.

**05 → Problema: Proyectos y herramientas.**

**Pista 2:** cierre de peso máximo: `s → proyecto` (beneficio), `herramienta → t` (coste), `proyecto → herramienta` (infinito).

**Pista 3:** respuesta = suma de beneficios − flujo máximo; el infinito, mayor que la suma de todas las capacidades finitas.

**05 → Problema: Download Speed.**

**Pista 2:** flujo máximo de 1 a `n`.

**Pista 3:** capacidades de `10⁹` y `1 000` aristas: el resultado en 64 bits; aristas repetidas, todas.

**05 → Problema: Maximum Flow.**

**Pista 2:** flujo máximo y, al final, las aristas originales con flujo positivo.

**Pista 3:** el flujo de una arista es su capacidad original menos la residual; si hay aristas en los dos sentidos entre dos vértices, imprime el neto.

**05 → Problema: Minimum Cut.**

**Pista 2:** flujo máximo y los alcanzables desde `s` en la residual.

**Pista 3:** imprime el tamaño del conjunto y sus vértices, `s` incluido.

**05 → Problema: Police Chase.**

**Pista 2:** corte mínimo con capacidad 1 por calle, en los dos sentidos.

**Pista 3:** tras el flujo, las calles originales con un extremo alcanzable desde 1 en la residual y el otro no.

**05 → Problema: Distinct Routes.**

**Pista 2:** flujo con capacidad 1 por arista; el valor es el número de rutas.

**Pista 3:** recupera cada ruta siguiendo desde 1 aristas originales con flujo 1, poniéndolas a 0 al usarlas.

**05 → Problema: Soldier and Traveling.**

**Pista 2:** bipartito: `s → ciudad_antes` con `a_i`, `ciudad_después → t` con `b_i`, y `antes_i → después_j` infinito si `i = j` o hay carretera.

**Pista 3:** si las sumas no coinciden o el flujo no satura, `NO`; si no, la matriz con los flujos de las aristas del medio.

**05 → Problema: Delivery Bears.**

**Pista 2:** búsqueda binaria sobre la carga `w` por oso; con `w`, cada arista admite `⌊c / w⌋` osos.

**Pista 3:** factible si el flujo con esas capacidades es `≥ x`; binaria en reales con un número fijo de iteraciones, y la respuesta es `w · x`.

**05 → Problema: Fox And Dinner.**

**Pista 2:** como los números son `≥ 2`, la suma de dos vecinos primos tiene que ser impar: alternan par e impar. Cada número necesita exactamente dos vecinos.

**Pista 3:** flujo de `s` a los impares (capacidad 2), de impar a par si la suma es prima (capacidad 1), de par a `t` (capacidad 2); si satura, recorre los ciclos que forman las aristas con flujo.

---

# 06 — Emparejamientos

**06 → 1.** ¿Qué es un emparejamiento y qué lo hace máximo? 🟢

⏱️ **30 segundos.** Un conjunto de aristas que no comparten vértices. Es máximo si ningún otro tiene más aristas.

🗣️ **2 minutos.** No confundir máximo con maximal: maximal es que no se puede añadir ninguna arista sin quitar otra, y el voraz da uno maximal que puede no ser máximo. Perfecto es el que cubre todos los vértices.

🔬 **El detalle.** Un maximal tiene al menos la mitad de aristas que un máximo: el voraz es una 2-aproximación.

**06 → 2.** ¿Qué es un camino aumentante? 🟢

⏱️ **30 segundos.** Un camino que alterna aristas fuera y dentro del emparejamiento y empieza y termina en vértices libres. Intercambiar sus aristas aumenta el emparejamiento en uno.

🗣️ **2 minutos.** Tiene una arista más fuera que dentro; al intercambiar, las de fuera entran y las de dentro salen, y los extremos libres quedan emparejados. Es el camino aumentante de la red de flujo del emparejamiento.

🔬 **El detalle.** En el ejemplo, `2 → a → 1 → b` (con `1–a` dentro) es aumentante respecto de `{1–a}`.

**06 → 3.** ¿Cómo se modela el emparejamiento bipartito como flujo? 🟢

⏱️ **30 segundos.** `s → cada vértice izquierdo` con capacidad 1, `izquierdo → derecho` con 1 por arista, `cada derecho → t` con 1. El flujo máximo es el emparejamiento máximo.

🗣️ **2 minutos.** Por la integralidad, el flujo máximo es entero: cada arista del medio lleva 0 o 1, y como cada vértice recibe o envía como mucho 1, las aristas con flujo forman un emparejamiento.

🔬 **El detalle.** Cambiando las capacidades de `s → izquierdo` o `derecho → t` se modelan cupos.

**06 → 4.** Describe Kuhn y su coste. 🟡

⏱️ **30 segundos.** Para cada vértice izquierdo, un DFS que busca un camino aumentante: toma un vecino libre o pide a la pareja del vecino que busque otro. `O(V · E)`.

🗣️ **2 minutos.** Cada DFS cuesta `O(E)` y hay uno por vértice izquierdo. Las marcas de visitado se reinician por intento (o se usa el número de ronda). Con una pasada voraz previa, en la práctica es muy rápido.

🔬 **El detalle.** Ordenar los vértices izquierdos por grado creciente suele ayudar a la heurística voraz.

**06 → 5.** ¿Por qué en Kuhn no hace falta reintentar un vértice que falló? 🟡

⏱️ **30 segundos.** Porque si no hay camino aumentante desde `u` ahora, no lo habrá después: los emparejamientos posteriores no crean caminos nuevos desde `u`.

🗣️ **2 minutos.** El conjunto de vértices derechos alcanzables desde `u` por caminos alternantes solo puede quedar ocupado al seguir aumentando; si ninguno estaba libre, ninguno lo estará. Es un lema estándar de la prueba de Kuhn.

🔬 **El detalle.** Por eso basta una pasada; repetir hasta que no mejore es correcto pero innecesario.

**06 → 6.** ¿Qué relación hay entre Hopcroft-Karp y Dinic? 🟡

⏱️ **30 segundos.** Hopcroft-Karp es Dinic aplicado a la red unitaria del emparejamiento: BFS por niveles alternantes y un conjunto maximal de caminos aumentantes más cortos y disjuntos por fase.

🗣️ **2 minutos.** Los dos tienen `O(E √V)` en esa red. Con la plantilla de Dinic a mano, se obtiene Hopcroft-Karp sin escribir otro algoritmo.

🔬 **El detalle.** La versión directa evita construir la red y suele ser algo más rápida en constante.

**06 → 7.** Enuncia el teorema de König y di qué permite calcular. 🟡

⏱️ **30 segundos.** En un bipartito, el emparejamiento máximo tiene el mismo tamaño que la cobertura de vértices mínima. Permite calcular coberturas mínimas e independientes máximos (`n −` cobertura).

🗣️ **2 minutos.** Problemas como «mínimo de filas y columnas que cubren las marcas» o «máximo de votantes contentos a la vez» son coberturas o independientes en bipartitos: se resuelven con un emparejamiento.

🔬 **El detalle.** Es un caso del teorema de flujo máximo y corte mínimo: el corte mínimo de la red es la cobertura.

**06 → 8.** Demuestra el teorema de Berge. 🟠

⏱️ **30 segundos.** Si hay camino aumentante, `M` no es máximo. Si `M′` es mayor, `M ⊕ M′` se descompone en caminos y ciclos alternantes, y alguno tiene más aristas de `M′`: es aumentante para `M`.

🗣️ **2 minutos.** En `M ⊕ M′` cada vértice tiene grado como mucho 2 (una de cada emparejamiento), así que sus componentes son caminos y ciclos que alternan. Los ciclos son pares y equilibrados; como `|M′| > |M|`, algún camino tiene una arista más de `M′`, y sus extremos están libres en `M`.

🔬 **El detalle.** El teorema vale en cualquier grafo, no solo en bipartitos; lo difícil en general es **encontrar** el camino.

**06 → 9.** ¿Cómo construyes la cobertura mínima a partir del emparejamiento máximo? 🟠

⏱️ **30 segundos.** Marcar lo alcanzable desde los izquierdos libres por caminos alternantes; la cobertura son los izquierdos no marcados y los derechos marcados.

🗣️ **2 minutos.** Cada arista de `M` tiene exactamente un extremo en ese conjunto, así que su tamaño es `|M|`. Y cubre todo: una arista con izquierdo marcado tiene el derecho marcado (se alcanza por ella), y una con izquierdo no marcado ya está cubierta.

🔬 **El detalle.** Es exactamente el lado `S` del corte mínimo de la red de flujo, leído en el bipartito.

**06 → 10.** ¿Cómo calculas el mínimo de caminos disjuntos que cubren un DAG? 🟠

⏱️ **30 segundos.** `n −` emparejamiento máximo en el bipartito con una copia de salida y otra de entrada de cada vértice, y la arista `u_salida → v_entrada` por cada `u → v`.

🗣️ **2 minutos.** Cada arista del emparejamiento une el final de un camino con el principio de otro, ahorrando un camino; las restricciones del emparejamiento garantizan que cada vértice tiene como mucho un sucesor y un predecesor.

🔬 **El detalle.** Si los caminos pueden compartir vértices, primero se calcula el cierre transitivo.

**06 → 11.** ¿Qué resuelve el húngaro y cuándo te basta una DP con máscaras? 🟠

⏱️ **30 segundos.** La asignación: emparejar `n` con `n` minimizando la suma de costes, en `O(n³)`. Con `n ≤ 15`, una DP con máscaras de `2ⁿ · n` basta.

🗣️ **2 minutos.** La DP lleva qué tareas están ocupadas y asigna los trabajadores en orden. El húngaro mantiene potenciales duales para no explorar subconjuntos.

🔬 **El detalle.** Minimum XOR Sum of Two Arrays ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)) es una asignación con `n ≤ 14`.

**06 → 12.** ¿Por qué el método de caminos aumentantes de Kuhn no funciona en grafos no bipartitos? 🔴

⏱️ **30 segundos.** Porque en un grafo con ciclos impares, un camino alternante puede volver a un vértice ya visitado por el otro lado, y el DFS de Kuhn lo descarta o se confunde.

🗣️ **2 minutos.** En un bipartito, el lado de cada vértice en un camino alternante está fijado (izquierda por aristas fuera, derecha por aristas dentro). Con ciclos impares (*blossoms*) eso se rompe, y hace falta contraerlos: el algoritmo de Edmonds ([`15/07`](07-grafos-de-nivel-experto.md)).

🔬 **El detalle.** Berge sigue valiendo en general; lo que falla es la búsqueda.

**06 → 13.** Da un ejemplo donde el voraz de emparejamiento falla y explica qué hace Kuhn para corregirlo. 🔴

⏱️ **30 segundos.** Técnicos `1: a, b`, `2: a`, `3: b, c`: el voraz en orden da `1–a`, `3–b` y deja al 2 sin nada. Kuhn reasigna al 1 a `b` cuando llega el 2.

🗣️ **2 minutos.** El camino aumentante `2 → a → 1 → b` mueve al 1 a `b` y libera `a` para el 2; después, el 3 toma `c`. El voraz no tiene forma de deshacer una elección.

🔬 **El detalle.** Es la misma lección que las aristas de vuelta del flujo ([`15/05`](05-flujo-maximo.md)).

**06 → Problema: Fichas de dominó.**

**Pista 2:** emparejamiento bipartito entre casillas blancas y negras libres del tablero de ajedrez.

**Pista 3:** cada casilla blanca, unida a sus vecinas negras libres; Kuhn con `10⁴` casillas va sobrado.

**06 → Problema: Barridos.**

**Pista 2:** König: el bipartito filas–columnas con una arista por `X`; la respuesta es el emparejamiento máximo.

**Pista 3:** `R` izquierdos y `C` derechos; con `500 × 500`, Kuhn sobre `2,5·10⁵` aristas como mucho.

**06 → Problema: Rutas de reparto.**

**Pista 2:** cobertura por caminos disjuntos en vértices de un DAG: `n −` emparejamiento máximo.

**Pista 3:** bipartito con `u` a la izquierda y `v` a la derecha por cada arista `u → v`; Kuhn.

**06 → Problema: School Dance.**

**Pista 2:** Kuhn (o Dinic) y las parejas desde `matchR`.

**Pista 3:** imprime el número y cada pareja `chico chica` con índices desde 1.

**06 → Problema: Gopher II.**

**Pista 2:** arista topo–agujero si la distancia entre ellos es `≤ s · v`; la respuesta es los topos menos el emparejamiento.

**Pista 3:** compara distancias al cuadrado para evitar raíces; varios casos hasta fin de entrada.

**06 → Problema: Book Club.**

**Pista 2:** cada persona tiene una copia que da y otra que recibe; todos intercambian si hay un emparejamiento perfecto.

**Pista 3:** arista `dador_a → receptor_b` por cada «a quiere el libro de b»; Kuhn o Hopcroft-Karp con `10⁴` personas.

**06 → Problema: Paintball.**

**Pista 2:** emparejamiento perfecto entre tiradores y blancos (cada uno puede dar a quien ve).

**Pista 3:** si no es perfecto, `Impossible`; si lo es, imprime a quién dispara cada uno desde `matchR`.

**06 → Problema: Cat vs. Dog.**

**Pista 2:** dos votantes chocan si uno quiere quedarse con lo que el otro quiere echar; los amantes de gatos y los de perros forman un bipartito.

**Pista 3:** la respuesta es votantes menos el emparejamiento máximo (independiente máximo por König).

**06 → Problema: Maximum Compatibility Score Sum.**

**Pista 2:** asignación con `n ≤ 8`: permutaciones o DP con máscaras.

**Pista 3:** precalcula la compatibilidad de cada par y maximiza la suma sobre las asignaciones.

**06 → Problema: Escape Plan.**

**Pista 2:** para cada tiempo (5, 10, 20), emparejamiento entre robots y agujeros alcanzables a tiempo.

**Pista 3:** distancia al cuadrado `≤ (10 · t)²`; tres emparejamientos por escenario.

**06 → Problema: Maximum Students Taking Exam.**

**Pista 2:** los conflictos (izquierda, derecha y diagonales delanteras) unen columnas de paridad distinta: bipartito por paridad de columna.

**Pista 3:** respuesta = asientos válidos menos el emparejamiento máximo; con `8 × 8` también vale una DP por filas con máscaras.

**06 → Problema: Maximize Mex.**

**Pista 2:** procesa los días al revés, añadiendo alumnos; bipartito valor → club, y el *mex* crece mientras se pueda emparejar el siguiente valor.

**Pista 3:** Kuhn incremental: cada vez que el *mex* `k` se empareja, intenta `k + 1`; los aumentos totales son como mucho 5 000.

---

# 07 — Grafos de nivel experto

**07 → 1.** ¿Por qué Kuhn no sirve en grafos que no son bipartitos? 🟢

⏱️ **30 segundos.** Porque en un ciclo impar un vértice puede alcanzarse por un camino alternante con las dos paridades, y la búsqueda de Kuhn, que asume que cada vértice está en un lado fijo, lo descarta o lo trata mal.

🗣️ **2 minutos.** En un bipartito, los vértices a distancia par de un libre están siempre en la izquierda y los impares en la derecha. Con un triángulo, un mismo vértice aparece como par y como impar según el camino, y el DFS que marca visitados pierde caminos aumentantes que existen.

🔬 **El detalle.** El teorema de Berge sigue valiendo; lo que falla es la búsqueda, y las flores de Edmonds la arreglan.

**07 → 2.** ¿Qué es una flor en el algoritmo de Edmonds? 🟢

⏱️ **30 segundos.** Un ciclo impar de `2k + 1` vértices con `k` aristas del emparejamiento, que la búsqueda encuentra al ver una arista entre dos vértices pares del mismo árbol alternante.

🗣️ **2 minutos.** Edmonds la contrae a un solo vértice y sigue buscando en el grafo contraído; si encuentra un camino aumentante, lo expande a través de la flor eligiendo el lado del ciclo que mantiene la alternancia.

🔬 **El detalle.** La contracción puede anidarse: flores dentro de flores.

**07 → 3.** ¿Qué es un dominador y qué es el dominador inmediato? 🟢

⏱️ **30 segundos.** `d` domina a `v` si todo camino desde la raíz hasta `v` pasa por `d`. El dominador inmediato es el dominador estricto de `v` más cercano a él.

🗣️ **2 minutos.** Los dominadores de `v` están ordenados en una cadena desde la raíz hasta `v`; el último antes de `v` es el inmediato. Uniendo cada vértice con su inmediato sale el árbol de dominadores.

🔬 **El detalle.** La raíz domina a todos; cada vértice se domina a sí mismo.

**07 → 4.** ¿Cuánto cuestan Edmonds y Lengauer-Tarjan? 🟡

⏱️ **30 segundos.** Edmonds, `O(V³)` en la versión clásica. Lengauer-Tarjan, `O(E · α(E, V))`, casi lineal.

🗣️ **2 minutos.** Con implementaciones cuidadosas, Edmonds baja a `O(V · E)`, y Micali-Vazirani a `O(E √V)`, como Hopcroft-Karp. Lengauer-Tarjan usa un DFS, los semidominadores y un Union-Find con compresión especial.

🔬 **El detalle.** El algoritmo iterativo de Cooper, Harvey y Kennedy es `O(V · E)` en el peor caso pero suele ganar en grafos de flujo de programas.

**07 → 5.** ¿Qué alternativa escribes en una entrevista si te piden emparejamiento general con `n ≤ 16`? 🟡

⏱️ **30 segundos.** Una DP con máscaras: el menor vértice libre se empareja con alguno de sus vecinos libres o se queda solo. `O(2ⁿ · n)`.

🗣️ **2 minutos.** El estado es el conjunto de vértices aún por decidir; tomar siempre el menor evita contar el mismo emparejamiento varias veces. Con `n = 16`, `65 536 · 16` pasos.

🔬 **El detalle.** Es el patrón de «emparejar elementos de un conjunto» de `13/01`.

**07 → 6.** ¿Cómo calculas los dominadores en un DAG? 🟡

⏱️ **30 segundos.** En orden topológico: el dominador inmediato de `v` es el LCA, en el árbol de dominadores ya construido, de todos sus predecesores.

🗣️ **2 minutos.** En un DAG, todos los predecesores de `v` ya tienen su lugar en el árbol cuando se procesa `v`. Todo camino a `v` pasa por algún predecesor, así que los dominadores de `v` son los comunes a todos ellos: el LCA y sus antecesores.

🔬 **El detalle.** Con LCA por saltos binarios incremental ([`07/05`](../07-arboles/05-lca.md)), `O((n + m) log n)`.

**07 → 7.** ¿Qué dice la fórmula de Tutte-Berge con `U = ∅`? 🟡

⏱️ **30 segundos.** Que el emparejamiento máximo deja sin emparejar al menos un vértice por cada componente de tamaño impar.

🗣️ **2 minutos.** Con `U = ∅`, la fórmula da `½ (n − odd(G))`: cada componente impar tiene un vértice que no se empareja dentro de ella, y no puede emparejarse fuera porque no hay aristas. Con `U` no vacío, quitar vértices puede crear más componentes impares y dar una cota mejor.

🔬 **El detalle.** El teorema de Tutte (emparejamiento perfecto si y solo si `odd(G − U) ≤ |U|` para todo `U`) es el caso particular.

**07 → 8.** ¿Cómo se transforma una arista con cota inferior en un problema de flujo normal? 🟠

⏱️ **30 segundos.** La arista `u → v` con `[l, c]` pasa a tener capacidad `c − l`, y se anota que `v` recibe `l` de más y `u` envía `l` de más (excesos y déficits por vértice).

🗣️ **2 minutos.** Una superfuente `S` envía a cada vértice con exceso su exceso, y cada vértice con déficit envía su déficit a un supersumidero `T`. La red resultante solo tiene cotas superiores.

🔬 **El detalle.** El flujo real de la arista original es `l` más el flujo en la arista transformada.

**07 → 9.** ¿Cómo compruebas que existe un flujo factible con cotas inferiores? 🟠

⏱️ **30 segundos.** Flujo máximo de `S` a `T` en la red transformada: es factible si y solo si satura todas las aristas que salen de `S`.

🗣️ **2 minutos.** Saturar significa que todas las deudas se pagaron: cada vértice recibe y envía lo que exige la conservación con los mínimos incluidos. Si el problema es de `s` a `t` y no una circulación, se añade antes `t → s` con capacidad infinita.

🔬 **El detalle.** Para el flujo máximo factible de `s` a `t`, se quita después `t → s` y se sigue aumentando de `s` a `t` en la residual.

**07 → 10.** ¿Qué diferencia hay entre un dominador y un punto de articulación? 🟠

⏱️ **30 segundos.** Un dominador es una noción dirigida y con raíz: está en todos los caminos desde la raíz hasta un vértice concreto. Un punto de articulación es no dirigido y global: su eliminación desconecta el grafo.

🗣️ **2 minutos.** Un vértice puede dominar a otros sin desconectar el grafo no dirigido subyacente (si hay caminos de vuelta en sentido contrario), y un punto de articulación puede no dominar nada desde una raíz dada.

🔬 **El detalle.** En un grafo no dirigido visto como dirigido simétrico, los dominadores desde `r` son exactamente los puntos de articulación que separan `r` de cada vértice.

**07 → 11.** ¿Cómo cuentas, para cada nodo, a cuántos dejaría inalcanzables si cayera? 🔴

⏱️ **30 segundos.** Con el árbol de dominadores: los que quedan inalcanzables al caer `d` son exactamente los dominados por `d`, su subárbol. El tamaño del subárbol lo da.

🗣️ **2 minutos.** Construir el árbol (Lengauer-Tarjan o, en un DAG, LCA en orden topológico) y sumar tamaños de subárboles: `O(E α)` en total. La fuerza bruta es quitar cada vértice y recorrer, `O(n · (n + m))`.

🔬 **El detalle.** Es el núcleo de Team Rocket Rises Again, sobre el DAG de caminos mínimos.

**07 → 12.** ¿Por qué contraer una flor no destruye los caminos aumentantes? 🔴

⏱️ **30 segundos.** Porque un camino aumentante que entra en la flor puede salir por cualquiera de sus vértices recorriendo el ciclo por el lado adecuado, que mantiene la alternancia; contraerla no pierde esas opciones.

🗣️ **2 minutos.** El lema de Edmonds: hay camino aumentante en `G` respecto de `M` si y solo si lo hay en `G/B` respecto de `M/B`. La dirección difícil usa que la base de la flor es la única con arista libre hacia fuera del ciclo dentro del emparejamiento, y que el ciclo impar permite llegar a cualquier vértice con la paridad correcta.

🔬 **El detalle.** La prueba completa está en el artículo de Edmonds (1965) y en el cap. 9 de Tarjan.

**07 → Problema: Compañeros de cuarto.**

**Pista 2:** DP con máscaras sobre los estudiantes sin decidir: el menor se empareja con un vecino o se queda solo.

**Pista 3:** `f(máscara)` con memoización; `2¹⁸ = 262 144` estados por hasta 18 transiciones.

**07 → Problema: Paso obligado.**

**Pista 2:** para cada vértice `v` distinto de 1 y `n`, quítalo y comprueba con un recorrido si 1 sigue alcanzando a `n`.

**Pista 3:** `2 000 · (2 000 + 4 000)` pasos; si 1 no alcanza a `n` desde el principio, `-1`.

**07 → Problema: Matching on General Graph.**

**Pista 2:** Edmonds con contracción de flores.

**Pista 3:** imprime el tamaño y las aristas; `n ≤ 500`, `O(V³)` cabe.

**07 → Problema: Dominator Tree.**

**Pista 2:** Lengauer-Tarjan, o el iterativo de Cooper-Harvey-Kennedy en orden postorden inverso.

**Pista 3:** imprime el dominador inmediato de cada vértice (la raíz, a sí misma; los inalcanzables, `-1`).

**07 → Problema: Minimum Cost b-flow.**

**Pista 2:** cotas inferiores transformadas en demandas y flujo de coste mínimo con superfuente y supersumidero.

**Pista 3:** después del flujo, comprueba que todas las demandas se satisfacen; recupera los potenciales para el dual que pide la salida.

**07 → Problema: Team Rocket Rises Again.**

**Pista 2:** Dijkstra desde la capital; las aristas de caminos mínimos forman un DAG.

**Pista 3:** árbol de dominadores del DAG con LCA en orden de distancia; la respuesta es el mayor subárbol de un vértice distinto de la capital.

**07 → Problema: Incorrect Flow.**

**Pista 2:** flujo de coste mínimo con cotas inferiores: subir el flujo de una arista cuesta 1 por unidad hasta la capacidad y 2 por encima; bajarlo, 1 (y por encima de la capacidad, también hay que bajar la capacidad).

**Pista 3:** modela cada arista con varias aristas de costes distintos y equilibra los excesos con superfuente y supersumidero.

---

# 08 — Simulación

**08 → S1.** ¿Qué condición exige Dijkstra y qué pasa si no se cumple? 🟢

⏱️ **30 segundos.** Pesos no negativos. Con alguno negativo, puede fijar un vértice con una distancia que después bajaría: respuesta incorrecta, no solo lenta.

🗣️ **2 minutos.** La prueba del invariante usa que un prefijo de camino no cuesta más que el camino. Con `s → a` 1, `s → b` 2 y `b → a` −2, fija `a` con 1 y la distancia es 0.

🔬 **El detalle.** Con negativos y sin ciclos negativos, Bellman-Ford; o Johnson para todos los pares.

**08 → S2.** ¿Para qué sirve la ronda número `n` de Bellman-Ford? 🟢

⏱️ **30 segundos.** Para detectar un ciclo negativo alcanzable: si en la ronda `n` todavía mejora algo, lo hay.

🗣️ **2 minutos.** Sin ciclos negativos, `n − 1` rondas bastan para que todo esté en su valor final, porque un camino mínimo simple tiene como mucho `n − 1` aristas. Mejorar en la ronda `n` es imposible salvo que haya caminos cada vez más baratos.

🔬 **El detalle.** Los vértices que mejoran y lo que alcanzan tienen distancia `−∞`.

**08 → S3.** ¿Por qué el bucle de `k` va por fuera en Floyd-Warshall? 🟡

⏱️ **30 segundos.** Porque la DP es sobre el conjunto de intermedios permitidos `{1..k}`: cada ronda `k` necesita la tabla completa de la ronda anterior.

🗣️ **2 minutos.** Con `k` por dentro, al calcular `d[i][j]` se usan valores que aún no están terminados y nadie los recalcula. En `2 → 1`, `3 → 4`, `4 → 2`, el par `(3, 1)` queda en infinito.

🔬 **El detalle.** En el sitio funciona porque en la ronda `k` la fila y la columna `k` no cambian.

**08 → S4.** ¿Cuándo eliges Dijkstra sin montículo? 🟡

⏱️ **30 segundos.** En grafos densos (`m` cerca de `n²`) o dados como matriz: `Θ(n²)` contra `Θ(n² log n)`.

🗣️ **2 minutos.** Sin montículo, cada extracción recorre el arreglo de distancias; con `n = 3 000`, `9·10⁶` pasos sobre memoria contigua, frente a `m log m` con el montículo.

🔬 **El detalle.** Prim tiene la misma dicotomía, y en grafos completos implícitos la versión sin montículo además no guarda aristas.

**08 → S5.** ¿Qué tiene que cumplir la heurística de A\* para que el camino sea óptimo sin reabrir vértices? 🟡

⏱️ **30 segundos.** Que sea consistente: `h(T) = 0` y `h(u) ≤ w(u, v) + h(v)` en toda arista.

🗣️ **2 minutos.** Con consistencia, A\* es Dijkstra sobre pesos repesados no negativos y cada vértice sale una vez con su distancia final. Solo admisible, hace falta reabrir vértices para garantizar el óptimo.

🔬 **El detalle.** Manhattan en rejilla de 4 direcciones con coste 1 es consistente.

**08 → S6.** ¿Qué dice la propiedad del corte del árbol de expansión mínima? 🟢

⏱️ **30 segundos.** En cualquier corte, la arista más ligera que lo cruza está en algún árbol de expansión mínima.

🗣️ **2 minutos.** Es la razón de que Kruskal y Prim sean correctos: cada arista que añaden es la más ligera que cruza un corte concreto (la componente actual contra el resto, o el árbol contra el resto).

🔬 **El detalle.** Si es la única más ligera, está en todos los MST.

**08 → S7.** ¿En qué se diferencian Prim y Dijkstra? 🟢

⏱️ **30 segundos.** Prim prioriza por el peso de la arista que conecta al árbol; Dijkstra, por la distancia acumulada desde el origen.

🗣️ **2 minutos.** Dan árboles distintos: en el triángulo `A–B 2`, `B–C 2`, `A–C 3`, Prim desde `A` elige `A–B` y `B–C` (4), y el árbol de caminos mínimos es `A–B` y `A–C` (5).

🔬 **El detalle.** En código, la diferencia es `w` frente a `d + w` en la prioridad.

**08 → S8.** Enuncia el teorema de flujo máximo y corte mínimo. 🟢

⏱️ **30 segundos.** El valor del flujo máximo de `s` a `t` es igual a la capacidad del corte mínimo que los separa.

🗣️ **2 minutos.** Todo flujo está acotado por todo corte; cuando no hay camino aumentante, lo alcanzable desde `s` en la residual define un corte cuya capacidad es exactamente el flujo.

🔬 **El detalle.** Ese corte es el mínimo más cercano a `s`.

**08 → S9.** ¿Cómo se modela un emparejamiento bipartito como flujo? 🟡

⏱️ **30 segundos.** `s → izquierda` (1), `izquierda → derecha` por cada arista (1), `derecha → t` (1); el flujo máximo es el emparejamiento máximo.

🗣️ **2 minutos.** Por integralidad, el flujo máximo entero se lee como un conjunto de aristas sin vértices comunes. Dinic sobre esta red es Hopcroft-Karp, `O(E √V)`.

🔬 **El detalle.** Cambiando las capacidades de los extremos se modelan cupos.

**08 → S10.** ¿Qué dice el teorema de König y para qué sirve? 🟡

⏱️ **30 segundos.** En un bipartito, emparejamiento máximo = cobertura de vértices mínima. Sirve para «mínimo de filas y columnas», «máximo de elementos sin conflicto» (`n −` cobertura).

🗣️ **2 minutos.** La cobertura se construye desde el emparejamiento con un recorrido alternante desde los libres de la izquierda: izquierdos no alcanzados y derechos alcanzados.

🔬 **El detalle.** Fuera de los bipartitos, la cobertura mínima de vértices es NP-difícil.

**08 → S11.** Todas las aristas pesan 7 y alguien escribe Dijkstra. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que basta un BFS: con todos los pesos iguales, el camino más barato es el de menos aristas, y el coste es `7 ×` la distancia en aristas.

🗣️ **2 minutos.** Dijkstra da lo mismo, con un `log` y un montículo de más. BFS es `Θ(n + m)` y más corto de escribir.

🔬 **El detalle.** Es la «Fuerza» de Peaje único.

**08 → S12.** Tu Dijkstra da WA solo en los casos con algún peso negativo, aunque no hay ciclos negativos. ¿Qué propones? 🟠

⏱️ **30 segundos.** Bellman-Ford (o SPFA si el juez no es adversario), porque Dijkstra no garantiza nada con pesos negativos.

🗣️ **2 minutos.** Si además se necesitan muchas consultas o todos los pares, Johnson: Bellman-Ford una vez para los potenciales y Dijkstra con los pesos repesados. Si el grafo es un DAG, la DP en orden topológico admite negativos en lineal.

🔬 **El detalle.** Sumar una constante para hacerlos positivos no sirve: cambia qué camino es mínimo.

**08 → S13.** Te piden el árbol de expansión mínima que **contenga** una arista concreta. ¿Cómo lo adaptas? 🟠

⏱️ **30 segundos.** Añadir primero esa arista (unir sus extremos y sumar su peso) y seguir con Kruskal sobre el resto.

🗣️ **2 minutos.** Equivale a contraer la arista: el resto es el MST del grafo contraído, que con la arista obligatoria da el árbol más barato que la contiene. Por la propiedad del corte aplicada al grafo contraído, es óptimo.

🔬 **El detalle.** Para muchas consultas de «arista obligatoria», la respuesta es `MST − (máximo en el camino u–v del MST) + w`, con LCA (`07/05`).

**08 → S14.** Tu Dijkstra pasa todo salvo un caso con un vértice de grado `10⁵`, que da TLE. ¿Qué miras? 🟠

⏱️ **30 segundos.** El `continue` de las entradas viejas del montículo: sin él, cada entrada vieja de ese vértice vuelve a recorrer sus `10⁵` vecinos.

🗣️ **2 minutos.** El resultado sigue siendo correcto (las relajaciones desde entradas viejas fallan), pero si el vértice mejora muchas veces antes de fijarse, el coste es `entradas × grado`. Con la comprobación `d > dist[u]`, cada vértice expande una sola vez.

🔬 **El detalle.** Es un fallo que solo aparece en casos diseñados con un vértice central.

**08 → S15.** «El flujo máximo es lo que sale de la fuente.» ¿Qué respondes con un ejemplo? 🟠

⏱️ **30 segundos.** Que es una cota, no la respuesta: en R′ (`s→a 3`, `s→b 2`, `a→b 1`, `a→t 1`, `b→t 3`) salen 5 de `s`, pero el máximo es 4.

🗣️ **2 minutos.** El corte `{s, a} | {b, t}` tiene capacidad 4: no puede pasar más. Lo que sale de `s` es un corte concreto, no el mínimo.

🔬 **El detalle.** La misma confusión con lo que entra en `t`.

**08 → S16.** Tu emparejamiento da menos parejas que la respuesta. Usas un voraz «al primero libre». ¿Qué pasa? 🟠

⏱️ **30 segundos.** Que el voraz no puede reasignar: un primer emparejamiento mal elegido bloquea a otros. Hace falta Kuhn (caminos aumentantes).

🗣️ **2 minutos.** Con `1: a, b`, `2: a`, `3: b, c`, el voraz da 2 y el máximo es 3. Kuhn, al llegar el 2, mueve al 1 a `b` por un camino aumentante.

🔬 **El detalle.** El voraz da un emparejamiento maximal, que tiene al menos la mitad del máximo.

**08 → S17.** Te piden el camino más barato con un número **par** de tramos. ¿Cuál es el estado? 🟠

⏱️ **30 segundos.** `(estación, paridad de tramos)`: Dijkstra sobre `2n` estados; la respuesta es la distancia a `(n, par)`.

🗣️ **2 minutos.** Cada arista cambia la paridad. Dos llegadas a la misma estación con paridades distintas tienen futuros distintos. En un grafo bipartito, la paridad de llegada a cada vértice está fijada: si `n` está en el lado impar, `-1`.

🔬 **El detalle.** Es el problema Tramos pares; el segundo ejemplo es G, que es bipartito.

**08 → S18.** «A\* siempre explora menos que Dijkstra.» ¿Cuándo es falso? 🟠

⏱️ **30 segundos.** Cuando la heurística es pobre (`h = 0` es Dijkstra más el coste de `h`), cuando la línea recta engaña en un laberinto, o cuando se piden las distancias a todos.

🗣️ **2 minutos.** A\* solo ahorra si `h` informa de verdad hacia un único destino. En laberintos con pasillos que apuntan a `T` y no llevan a él, explora casi lo mismo que Dijkstra.

🔬 **El detalle.** Con `h` consistente, A\* nunca expande más vértices que Dijkstra (salvo empates); en tiempo, puede perder por calcular `h`.

**08 → S19.** Demuestra la propiedad del corte por intercambio. 🔴

⏱️ **30 segundos.** Sea `e` la más ligera que cruza el corte y `T` un MST sin `e`. El camino de `T` entre los extremos de `e` cruza el corte por alguna `f`; `T − f + e` es un árbol que no pesa más.

🗣️ **2 minutos.** Quitar `f` parte `T` en dos componentes, una con cada extremo de `e`, y `e` las reconecta. Como `w(e) ≤ w(f)`, el peso no sube: hay un MST con `e`.

🔬 **El detalle.** Con desigualdad estricta, `T` no era mínimo: `e` está en todos los MST.

**08 → S20.** Diseña cómo decidir si un grafo dirigido tiene un ciclo negativo en **cualquier** parte, no solo alcanzable desde un vértice dado, y di el coste. 🔴

⏱️ **30 segundos.** Bellman-Ford desde una superfuente unida a todos los vértices con peso 0 (o, lo mismo, todas las distancias empiezan en 0); si la ronda `n` mejora algo, hay ciclo negativo. `Θ(n · m)`.

🗣️ **2 minutos.** Desde la superfuente todo es alcanzable, así que cualquier ciclo negativo se detecta. Con `n ≤ 500`, Floyd y `d[i][i] < 0` también sirve.

🔬 **El detalle.** Es el primer paso de Johnson, y de Cycle Finding.

**08 → Problema: Tramos pares.**

**Pista 2:** Dijkstra sobre `(estación, paridad)`.

**Pista 3:** `2n` estados; cada arista va de `(u, p)` a `(v, 1 − p)`; la respuesta es la distancia a `(n, 0)`, o `-1`. 64 bits.

**08 → Problema: ¿Dinero infinito?.**

**Pista 2:** Bellman-Ford con todas las distancias iniciales a 0 (una superfuente implícita).

**Pista 3:** `n` rondas; si la última todavía relaja, `YES`. No compruebes `dist[u] != INF`: ya no hay infinitos.

**08 → Problema: Con esta arista dentro.**

**Pista 2:** une primero los extremos de la arista `k` y suma su peso; después, Kruskal con el resto.

**Pista 3:** cuenta las aristas añadidas (incluida la `k`); si no llegan a `n − 1`, `-1`. 64 bits.

**08 → Problema: Peaje único.**

**Pista 2:** BFS desde 1: el coste es `c` por la distancia en aristas.

**Pista 3:** `-1` si `n` no se alcanza; el producto en 64 bits.

**08 → Problema: Number of Restricted Paths From First to Last Node.**

**Pista 2:** Dijkstra desde `n` y, después, DP contando caminos que bajan estrictamente esa distancia.

**Pista 3:** procesa los vértices en orden creciente de distancia a `n`: `ways[u] = Σ ways[v]` sobre vecinos con `dist[v] < dist[u]`; módulo `10⁹ + 7`.

**08 → Problema: The Two Routes.**

**Pista 2:** si hay vía de tren directa de 1 a `n`, el tren llega en 1; el autobús hace un BFS en el grafo complementario (y viceversa).

**Pista 3:** la respuesta es el máximo de los dos BFS; si el vehículo que no va directo no llega, `-1`. Con `n ≤ 400`, la matriz de adyacencia basta.

**08 → Problema: Edge Deletion.**

**Pista 2:** el árbol de caminos mínimos de Dijkstra conserva la distancia de todos; quédate con sus primeras `k` aristas en el orden en que se fijaron los vértices.

**Pista 3:** guarda la arista padre de cada vértice al fijarlo; imprime las de los primeros `k` vértices fijados (sin contar el origen).

**08 → Problema: Reachable Nodes In Subdivided Graph.**

**Pista 2:** Dijkstra sobre los nodos originales, con la arista `u–v` de peso `cnt + 1`.

**Pista 3:** cuenta los originales con `dist ≤ maxMoves`; por cada arista, suma `min(cnt, sobra[u] + sobra[v])`, con `sobra = maxMoves − dist` si es positivo.

**08 → Problema: Minimum Weighted Subgraph With the Required Paths.**

**Pista 2:** tres Dijkstras: desde `src1`, desde `src2` y desde `dest` en el grafo invertido.

**Pista 3:** la respuesta es el mínimo sobre `v` de `d1[v] + d2[v] + d3[v]`; 64 bits y `-1` si ningún `v` tiene las tres finitas.
