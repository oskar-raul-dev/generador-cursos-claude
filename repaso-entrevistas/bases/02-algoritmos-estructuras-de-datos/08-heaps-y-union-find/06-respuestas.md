# Respuestas — bloque 08: Heaps y Union-Find

> Solucionario del bloque `08`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--montículo-binario) · [02](#02--patrones-con-heap) · [03](#03--montículos-fusionables) · [04](#04--union-find) · [05](#05--simulación)

---

# 01 — Montículo binario

**01 → 1.** ¿En qué posiciones están los hijos y el padre del índice `i` en un montículo binario guardado en un arreglo? 🟢

⏱️ **30 segundos.** Hijos en `2i + 1` y `2i + 2`; padre en `(i − 1) / 2` con división entera.

🗣️ **2 minutos.** El árbol completo se guarda por niveles, de izquierda a derecha, sin huecos. Por eso no hacen falta punteros: la posición determina la relación. Con índices desde 1, las fórmulas son `2i`, `2i + 1` y `i / 2`.

🔬 **El detalle.** Un índice `i` es hoja si `2i + 1 ≥ n`: las hojas son la segunda mitad del arreglo, desde `⌊n/2⌋`.

**01 → 2.** ¿Qué garantiza el invariante del montículo, y qué no garantiza sobre los hermanos? 🟢

⏱️ **30 segundos.** Que todo nodo es menor o igual que sus hijos (en un montículo de mínimos), y por tanto la raíz es el mínimo. No dice nada del orden entre hermanos ni entre primos.

🗣️ **2 minutos.** Es un orden parcial: cada camino de la raíz a una hoja está ordenado, pero dos nodos de ramas distintas pueden estar en cualquier orden. Por eso el arreglo no está ordenado, y por eso mantenerlo es más barato que mantener un orden total.

🔬 **El detalle.** El segundo menor es uno de los dos hijos de la raíz; el tercero puede estar en el nivel 1 o en el 2.

**01 → 3.** ¿Qué devuelve por defecto `std::priority_queue`, `PriorityQueue` y `heapq`: el mínimo o el máximo? 🟢

⏱️ **30 segundos.** `std::priority_queue`: el **máximo**. `PriorityQueue` de Java y `heapq` de Python: el **mínimo**.

🗣️ **2 minutos.** En C++, para mínimos: `std::priority_queue<int, std::vector<int>, std::greater<int>>`. En Java, para máximos: `new PriorityQueue<>(Comparator.reverseOrder())`. En Python 3.12, para máximos se guardan valores negados.

🔬 **El detalle.** Con pares en C++, `greater<pair<…>>` ordena por el primer componente y desempata por el segundo, lo que a veces se olvida.

**01 → 4.** ¿Por qué al bajar se elige el hijo menor y no cualquiera? 🟡

⏱️ **30 segundos.** Porque el que suba tiene que ser menor o igual que el otro hijo, que quedará debajo de él. Si subiera el mayor, el menor quedaría como hijo de uno mayor: invariante roto.

🗣️ **2 minutos.** Tras el intercambio, el hijo que sube es el nuevo padre de los dos subárboles; tiene que ser `≤` que la raíz del otro subárbol. Solo el menor de los dos lo cumple siempre.

🔬 **El detalle.** Con iguales da igual cuál se elija; la plantilla elige el izquierdo.

**01 → 5.** ¿Por qué `heapify` se aplica de los últimos nodos internos hacia la raíz, y no al revés? 🟡

⏱️ **30 segundos.** Porque `siftDown(i)` solo deja un montículo si los dos subárboles de `i` ya lo son. Procesando de abajo arriba, cuando se llega a `i` sus hijos ya están arreglados.

🗣️ **2 minutos.** Las hojas (la segunda mitad) son montículos triviales. Empezando por `⌊n/2⌋ − 1` y bajando el índice, cada nodo se procesa después de sus dos hijos. Si se empezara por la raíz, al bajarla se compararía con hijos que aún no son el mínimo de su subárbol.

🔬 **El detalle.** Construir de arriba abajo con `siftUp` de cada nodo también funciona, pero cuesta `O(n log n)`.

**01 → 6.** ¿Cómo se simula un montículo de máximos con `heapq` en Python 3.12? 🟡

⏱️ **30 segundos.** Guardando `−x` en lugar de `x`: el mínimo de los negados es el máximo de los originales. Al sacar, se vuelve a negar.

🗣️ **2 minutos.** Con tuplas, se niega la componente por la que se ordena: `(−prioridad, desempate, dato)`. Con objetos, se envuelven en una clase con `__lt__` invertido, aunque es más lento.

🔬 **El detalle.** Desde Python 3.14, `heapq` tiene funciones para montículos de máximos; el corpus fija 3.12.

**01 → 7.** Demuestra que `heapify` es `O(n)`. 🟠

⏱️ **30 segundos.** Un `siftDown` desde altura `h` cuesta `O(h)` y hay como mucho `⌈n/2^{h+1}⌉` nodos de altura `h`; la suma `Σ h · n/2^{h+1}` es `O(n)` porque `Σ h/2^h = 2`.

🗣️ **2 minutos.** La mitad de los nodos son hojas (altura 0, no se mueven); un cuarto tiene altura 1 (bajan como mucho 1); un octavo, altura 2… El total es `n · (0/2 + 1/4 + 2/8 + 3/16 + …) = n · Σ h/2^{h+1} = n`. La serie `Σ h xʰ = x/(1 − x)²` con `x = 1/2` da 2.

🔬 **El detalle.** CLRS, 3.ª ed., §6.3. La cota inferior también es lineal (hay que mirar todos), así que `heapify` es `Θ(n)`.

**01 → 8.** ¿Por qué ninguna cola de prioridad de biblioteca tiene `decrease-key`, y qué dos alternativas hay? 🟠

⏱️ **30 segundos.** Porque para cambiar la prioridad de un elemento hay que saber dónde está, y el montículo no guarda esa información: buscarlo es `O(n)`. Las alternativas: borrado perezoso (meter una copia nueva y descartar las viejas) o cola indexada (guardar la posición de cada índice).

🗣️ **2 minutos.** La interfaz genérica de las bibliotecas acepta valores, no identificadores, y los valores pueden repetirse. Con borrado perezoso, la cola crece hasta el número de inserciones, no de elementos vivos; en Dijkstra eso es `O(m)` y suele bastar. La cola indexada exige que los elementos sean índices `0..n−1`.

🔬 **El detalle.** Java tiene `remove(Object)`, pero es lineal.

**01 → 9.** Compara `std::priority_queue`, `PriorityQueue` y `heapq`: interfaz, orden por defecto y cómo se pasa un comparador. 🟠

⏱️ **30 segundos.** C++: adaptador `priority_queue` con `push`, `top`, `pop`, máximos por defecto, comparador como tercer parámetro de plantilla. Java: clase `PriorityQueue` con `offer`, `peek`, `poll`, mínimos, comparador en el constructor. Python: funciones `heapq` sobre una lista, mínimos, sin comparador (se usan tuplas o claves negadas).

🗣️ **2 minutos.** En C++, `pop` no devuelve el elemento: hay que leer `top` antes. En Java, los elementos son objetos (`Integer`), con el coste de las cajas. En Python, la lista es visible y se puede romper el invariante tocándola a mano; `heapq` confía en que no se haga.

🔬 **El detalle.** [`03/05`](../03-biblioteca-estandar/05-equivalencias-entre-lenguajes.md) tiene la tabla de equivalencias completa.

**01 → 10.** ¿Qué cuesta Dijkstra con un montículo binario y con uno `d`-ario, y cómo se elige `d`? 🟠

⏱️ **30 segundos.** Binario: `O((n + m) log n)`. `d`-ario: `O(n · d · log_d n + m · log_d n)`; con `d ≈ m/n`, `O(m log_{m/n} n)`, que en grafos densos es casi lineal.

🗣️ **2 minutos.** Dijkstra hace `n` extracciones (`pop`, que bajan) y hasta `m` `decrease-key` (que suben). En un `d`-ario, subir es más barato (`log_d n`) y bajar más caro (`d log_d n`). Equilibrando, `d = max(2, m/n)`.

🔬 **El detalle.** Con borrado perezoso no hay `decrease-key`: cada relajación es un `push`, y el montículo puede llegar a `m` elementos: `O(m log m) = O(m log n)`.

**01 → 11.** Demuestra que `siftDown` aplicado a la raíz restaura el invariante si los dos subárboles ya eran montículos. 🟠

⏱️ **30 segundos.** Si los dos subárboles son montículos, el único sitio donde puede fallar el invariante es la raíz. `siftDown` la intercambia con el hijo menor, que es el mínimo de todo el subárbol salvo quizá la raíz, y el problema baja un nivel al subárbol de ese hijo, que sigue siendo montículo salvo en su raíz.

🗣️ **2 minutos.** Inducción sobre la altura. Si la raíz es `≤` que sus dos hijos, ya es montículo. Si no, el hijo menor `c` es el mínimo de los tres y sube; el otro subárbol queda intacto y bajo un padre `≤` que su raíz; el subárbol de `c` tiene ahora en su raíz el valor que bajó, con sus dos subárboles intactos (montículos): por hipótesis, `siftDown` lo arregla.

🔬 **El detalle.** Es el invariante que usa la prueba de `heapify`.

**01 → 12.** ¿Por qué el iterador de `PriorityQueue` no está ordenado, y cómo obtendrías sus elementos en orden? 🔴

⏱️ **30 segundos.** Porque el iterador recorre el arreglo interno del montículo en el orden en que está guardado, que solo garantiza el invariante, no el orden total. Para tenerlos en orden: sacar con `poll` uno a uno (destruye la cola) o copiar a un arreglo y ordenarlo.

🗣️ **2 minutos.** La documentación de `PriorityQueue` lo dice expresamente: el iterador no recorre en ningún orden particular. `toString` usa el iterador, por eso imprime algo «casi ordenado» que confunde al depurar.

🔬 **El detalle.** Lo mismo pasa con `heapq`: la lista no está ordenada, y `sorted(h)` o `heapq.nsmallest(len(h), h)` la dan en orden.

**01 → 13.** ¿Cómo implementarías `remove(i)` (borrar un índice cualquiera) en la cola indexada en `O(log n)`? 🔴

⏱️ **30 segundos.** Intercambiar el índice `i` con el último, quitar el último, y en la posición donde quedó el que vino del final, aplicar `up` **o** `down` según sea menor que su padre o mayor que algún hijo.

🗣️ **2 minutos.** El elemento que se trae del final puede ser menor que el padre de esa posición (si venía de otra rama) o mayor que sus hijos: hay que probar los dos. `pos[i] = −1` al quitarlo. Todo `O(log n)`.

🔬 **El detalle.** Si `i` era el último, no hay nada que recolocar; olvidar ese caso lee una posición que ya no existe.

**01 → Problema: Cola de urgencias.**

- **Pista 2 — patrón:** **montículo de mínimos**.
- **Pista 3 — diseño:** `priority_queue` con `greater`, `PriorityQueue` o `heapq`; `+` hace `push` y `-` imprime y quita la cima. Lectura rápida para `2·10⁵` órdenes.

**01 → Problema: Montículo desde cero.**

- **Pista 2 — patrón:** **heapify** con `siftDown`.
- **Pista 3 — diseño:** la plantilla de §4 con la regla de empate del enunciado (`a[c + 1] < a[c]` estricto para preferir el izquierdo, y parar si `a[i] ≤ a[c]`).

**01 → Problema: Rebajas.**

- **Pista 2 — patrón:** **cola indexada** con `decrease-key`, o borrado perezoso.
- **Pista 3 — diseño:** clave `(precio, producto)` para desempatar por número; con la cola indexada, `decrease` en cada rebaja; con borrado perezoso, mete la pareja nueva y, al consultar, descarta la cima mientras su precio no sea el actual del producto.

**01 → Problema: QHEAP1.**

- **Pista 2 — patrón:** **montículo con borrado perezoso**, o conjunto ordenado.
- **Pista 3 — diseño:** un montículo de valores y otro de «borrados pendientes»; al consultar el mínimo, mientras las dos cimas coincidan, quítalas de los dos.

**01 → Problema: Take Gifts From the Richest Pile.**

- **Pista 2 — patrón:** **montículo de máximos**.
- **Pista 3 — diseño:** `k` veces: saca el mayor, mete `⌊√x⌋`; al final, suma todo. Cuidado con la raíz entera (`isqrt` en Python).

**01 → Problema: Remove Stones to Minimize the Total.**

- **Pista 2 — patrón:** **montículo de máximos**.
- **Pista 3 — diseño:** `k` veces: saca el mayor `x` y mete `x − ⌊x/2⌋`; la respuesta es la suma final. `heapify` al principio.

**01 → Problema: Maximal Score After Applying K Operations.**

- **Pista 2 — patrón:** **montículo de máximos**.
- **Pista 3 — diseño:** `k` veces: saca el mayor, súmalo a la puntuación (64 bits) y mete `⌈x/3⌉`.

**01 → Problema: Minimum Operations to Halve Array Sum.**

- **Pista 2 — patrón:** **montículo de máximos** con reales.
- **Pista 3 — diseño:** mientras lo reducido no llegue a la mitad de la suma original, saca el mayor, suma su mitad a lo reducido y mete la mitad; cuenta las operaciones.

**01 → Problema: Smallest Number in Infinite Set.**

- **Pista 2 — patrón:** **montículo** de los devueltos más un **contador** del resto.
- **Pista 3 — diseño:** un entero `next` con el menor número nunca sacado; los devueltos menores que `next` van a un montículo (con un conjunto para no repetir); `popSmallest` saca del montículo si no está vacío y, si no, devuelve `next++`.

**01 → Problema: Find Score of an Array After Marking All Elements.**

- **Pista 2 — patrón:** **montículo de pares** `(valor, índice)` con marcas.
- **Pista 3 — diseño:** `heapify` de los pares; saca el menor; si está marcado, ignóralo; si no, súmalo y marca él y sus dos vecinos. Puntuación en 64 bits.

**01 → Problema: Ugly Number II.**

- **Pista 2 — patrón:** **montículo de candidatos** con un conjunto de vistos (o tres punteros).
- **Pista 3 — diseño:** empieza con 1; `n` veces: saca el menor `x` y mete `2x`, `3x`, `5x` si no se habían metido. La versión de tres punteros es `O(n)` sin montículo.

**01 → Problema: Super Ugly Number.**

- **Pista 2 — patrón:** **montículo de punteros**, uno por primo.
- **Pista 3 — diseño:** guarda en el montículo `(valor candidato, primo, índice en la lista de feos)`; saca el menor, añádelo si no es repetido, y avanza el puntero de ese primo metiendo el siguiente candidato.

**01 → Problema: Total Cost to Hire K Workers.**

- **Pista 2 — patrón:** **dos montículos** con los candidatos de cada extremo.
- **Pista 3 — diseño:** un montículo con los `candidates` primeros y otro con los últimos (sin solaparse); en cada ronda, elige el menor de las dos cimas (a igualdad, el de la izquierda) y repón desde su lado si quedan. Suma en 64 bits.

**01 → Problema: Minimum Cost to Hire K Workers.**

- **Pista 2 — patrón:** **ordenar por razón** salario/calidad y **montículo de máximos** de calidades.
- **Pista 3 — diseño:** el que tiene la mayor razón del grupo fija el pago: coste = razón · suma de calidades. Recorre por razón creciente manteniendo las `k` calidades menores (montículo de máximos y su suma); en cada paso con `k` elementos, prueba `razón · suma`.

---

# 02 — Patrones con heap

**02 → 1.** ¿Qué montículo usas para los `k` mayores, de mínimos o de máximos, y de qué tamaño? 🟢

⏱️ **30 segundos.** Un montículo de **mínimos** de tamaño `k`: su cima es el menor de los `k` retenidos, el que sale si llega uno mayor.

🗣️ **2 minutos.** Si se usara uno de máximos, la cima sería el mayor, que es justo el que hay que conservar; para saber a quién echar habría que buscar el menor, `O(k)`. Con el de mínimos, la decisión es comparar con la cima.

🔬 **El detalle.** Para los `k` menores, al revés: montículo de máximos de tamaño `k`.

**02 → 2.** ¿Qué guarda el montículo al mezclar `k` listas? 🟢

⏱️ **30 segundos.** La cabeza de cada lista no agotada: su menor elemento todavía no emitido, junto con de qué lista es y su posición.

🗣️ **2 minutos.** El montículo nunca tiene más de `k` elementos. Al sacar la menor cabeza, se mete la siguiente de la misma lista, si queda. La identificación de la lista es imprescindible para saber de dónde reponer.

🔬 **El detalle.** Con listas enlazadas, basta guardar el nodo: su `next` es la siguiente cabeza.

**02 → 3.** ¿Dónde está la mediana en el esquema de dos montículos? 🟢

⏱️ **30 segundos.** En la cima de `lo`, el montículo de máximos con la mitad menor (para la mediana inferior). Con `n` par y la mediana como media, es la media de las dos cimas.

🗣️ **2 minutos.** Con `|lo| = |hi|` o `|lo| = |hi| + 1` y todo `lo ≤` todo `hi`, la cima de `lo` es el elemento de posición `⌊(n − 1)/2⌋` en orden. Leerla es `O(1)`.

🔬 **El detalle.** Si se prefiere la mediana superior, se equilibra dejando el sobrante en `hi`.

**02 → 4.** ¿Por qué la mezcla de `k` listas cuesta `O(N log k)` y no `O(N log N)`? 🟡

⏱️ **30 segundos.** Porque el montículo nunca tiene más de `k` elementos: cada una de las `N` extracciones e inserciones cuesta `O(log k)`.

🗣️ **2 minutos.** Ordenar todo junto cuesta `O(N log N)` e ignora que las listas ya estaban ordenadas. La mezcla aprovecha ese orden: solo compite una cabeza por lista. Con `k = N` (listas de un elemento) es `O(N log N)`, como ordenar; con `k` pequeño, mucho menos.

🔬 **El detalle.** Alternativa sin montículo: mezclar por parejas en `log k` rondas, también `O(N log k)`.

**02 → 5.** ¿Qué invariantes mantienen los dos montículos de la mediana, y cómo se restauran tras insertar? 🟡

⏱️ **30 segundos.** `max(lo) ≤ min(hi)` y `|lo| − |hi| ∈ {0, 1}`. Al insertar, el valor va al lado que corresponde por su valor; si los tamaños se descompensan, se pasa una cima al otro lado.

🗣️ **2 minutos.** Meter `x` en `lo` si `x ≤ max(lo)` (o en `hi` si no) mantiene el orden entre los dos. Los tamaños pueden quedar desequilibrados en 1 más de lo permitido; mover la cima de `lo` a `hi` (o la de `hi` a `lo`) corrige el tamaño sin romper el orden, porque la cima es justo el elemento del borde.

🔬 **El detalle.** El orden de las dos comprobaciones de tamaño no importa porque solo una puede cumplirse tras una inserción.

**02 → 6.** ¿Qué es el borrado perezoso y por qué no cambia el coste amortizado? 🟡

⏱️ **30 segundos.** Borrar o actualizar sin buscar: se anota el elemento como muerto y se descarta cuando llega a la cima. Cada elemento entra y sale una sola vez, así que el total de operaciones sobre el montículo es proporcional a las inserciones.

🗣️ **2 minutos.** Un `top` puede tener que descartar muchos muertos de golpe, pero cada muerto se descarta una vez en toda la vida de la estructura: la suma es `O(inserciones · log(tamaño))`. El precio es la memoria: el montículo guarda también los muertos que aún no han subido.

🔬 **El detalle.** El análisis es agregado, como el de la pila monótona ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)).

**02 → 7.** ¿Cómo haces Dijkstra con la cola de prioridad de tu lenguaje, sin `decrease-key`? 🟡

⏱️ **30 segundos.** Metiendo `(distancia, nodo)` cada vez que una distancia mejora, y al sacar, descartando el par si su distancia es mayor que la mejor conocida del nodo.

🗣️ **2 minutos.** No hay `decrease-key`: en lugar de bajar la prioridad del nodo, se añade otra copia. Las copias viejas, al salir, tienen una distancia peor que `dist[nodo]` y se ignoran. El montículo llega a `O(m)` elementos, y el coste es `O(m log m) = O(m log n)`.

🔬 **El detalle.** [`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md) lo desarrolla; en C++ con `greater<pair<long long, int>>`.

**02 → 8.** Demuestra que el montículo de tamaño `k` retiene exactamente los `k` mayores. 🟠

⏱️ **30 segundos.** Invariante: tras `i` elementos, el montículo tiene los `min(i, k)` mayores. Si llega `x` mayor que la cima, la cima deja de estar entre los `k` mayores (hay `k` mayores que ella) y `x` sí; si no, `x` tiene `k` valores `≥` delante.

🗣️ **2 minutos.** Inducción sobre `i`. Con menos de `k`, se guardan todos. Con `k`: sea `c` la cima, el menor de los retenidos. Si `x > c`, entre los `i + 1` vistos hay `k` mayores que `c` (los otros `k − 1` retenidos y `x`), así que `c` no está entre los `k` mayores y `x` sí. Si `x ≤ c`, hay `k` valores `≥ x` retenidos, así que `x` no entra (con empates, cualquiera de los iguales vale).

🔬 **El detalle.** El invariante es el mismo que el de *quickselect* visto desde un flujo: el umbral de entrada sube monótonamente.

**02 → 9.** Compara cómo escribes la mediana de un flujo en C++, Java y Python. 🟠

⏱️ **30 segundos.** C++: `priority_queue<int>` para `lo` y `priority_queue<int, vector<int>, greater<int>>` para `hi`. Java: `PriorityQueue` con `Comparator.reverseOrder()` para `lo` y normal para `hi`. Python: `heapq` con negados en `lo`.

🗣️ **2 minutos.** La lógica es idéntica; cambia cómo se obtiene un montículo de máximos. En Java, los `Integer` y los `poll` devuelven objetos (cuidado con comparar con `==` fuera de la caché de enteros). En Python, olvidar volver a negar al sacar de `lo` es el error típico.

🔬 **El detalle.** Con `long` o reales, la media de las dos cimas necesita cuidado: en Java, `(a + b) / 2.0`; con enteros grandes, `a + (b − a) / 2`.

**02 → 10.** ¿Cómo calculas la mediana de cada ventana de tamaño `k` con dos montículos? ¿Qué cambia respecto del flujo? 🟠

⏱️ **30 segundos.** Con los mismos dos montículos más borrado perezoso: al salir un valor de la ventana, se anota como muerto en el montículo donde está (se sabe comparándolo con la cima de `lo`) y se ajustan los tamaños **vivos**; antes de leer o mover cimas, se limpian los muertos.

🗣️ **2 minutos.** Lo nuevo respecto del flujo es el borrado. El equilibrio tiene que usar los tamaños vivos, no los de las colas. Cada valor se anota y se descarta una vez: `O(n log n)` en total.

🔬 **El detalle.** Alternativa más directa en C++: dos `multiset` (uno por mitad), que sí permiten borrar un valor concreto en `O(log n)`.

**02 → 11.** ¿Cuándo es mejor ordenar o *quickselect* que un montículo de tamaño `k`? 🟠

⏱️ **30 segundos.** Cuando `k` es comparable a `n` (el montículo no ahorra nada), cuando todos los datos están en memoria y se necesitan varias posiciones, o cuando se pide el `k`-ésimo y no los `k` mayores: *quickselect* es `O(n)` esperado.

🗣️ **2 minutos.** El montículo de tamaño `k` es `O(n log k)`; ordenar es `O(n log n)`; *quickselect* es `O(n)` y además deja los `k` mayores a un lado (sin ordenar). El montículo gana en flujos y con `k` pequeño; *quickselect* gana con todo en memoria.

🔬 **El detalle.** [`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md) trata *quickselect* y `nth_element`.

**02 → 12.** Con `k` listas ordenadas de enteros, ¿cómo encuentras el `m`-ésimo menor sin mezclarlas enteras, y con qué coste? 🔴

⏱️ **30 segundos.** Con el montículo de cabezas, sacando `m` veces: `O(k + m log k)` (con `heapify` de las `k` cabezas). No hace falta mezclar el resto.

🗣️ **2 minutos.** La `m`-ésima extracción es el `m`-ésimo menor. Si `m` es grande y las listas son arreglos, hay una alternativa por búsqueda binaria sobre el valor: contar cuántos elementos `≤ v` hay sumando un *upper bound* por lista, `O(k log L)` por valor, `O(k log L log V)` en total ([`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)).

🔬 **El detalle.** Con dos listas, el `m`-ésimo se encuentra en `O(log m)` con una binaria sobre cuántos se toman de cada una.

**02 → 13.** Demuestra que ningún algoritmo por comparación mezcla `k` listas ordenadas de `N/k` elementos cada una en menos de `Ω(N log k)` comparaciones. 🔴

⏱️ **30 segundos.** El número de formas de intercalar `k` listas de `N/k` elementos es el multinomial `N! / ((N/k)!)ᵏ`; un algoritmo por comparación necesita al menos `log₂` de esa cantidad comparaciones, que es `≈ N log₂ k`.

🗣️ **2 minutos.** Es el argumento del árbol de decisión de [`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md): cada resultado posible de la mezcla es una hoja distinta. Con Stirling, `log₂(N!) − k log₂((N/k)!) ≈ N log₂ N − k · (N/k) log₂(N/k) = N log₂ k`. Así que `Ω(N log k)` comparaciones son necesarias, y el montículo de cabezas es óptimo.

🔬 **El detalle.** Con `k = N` se recupera la cota `Ω(N log N)` de ordenar; con `k = 2`, `Ω(N)`, que es lo que hace la mezcla de dos punteros.

**02 → Problema: Turnos de las atracciones.**

- **Pista 2 — patrón:** **montículo de operarios** por instante en que quedan libres.
- **Pista 3 — diseño:** pares `(libre, operario)` empezando en `(0, i)`; para cada atracción, saca el menor par, imprime `libre + duración` y vuelve a meterlo con el nuevo instante. Instantes en 64 bits.

**02 → Problema: Fusión de clasificaciones.**

- **Pista 2 — patrón:** **mezcla de `k` listas** parando en `m`.
- **Pista 3 — diseño:** montículo de cabezas `(tiempo, lista, posición)`; saca `m` veces reponiendo de la misma lista. `O(k + m log k)`.

**02 → Problema: Mediana con bajas.**

- **Pista 2 — patrón:** **dos montículos con borrado perezoso** y tamaños vivos.
- **Pista 3 — diseño:** al quitar `x`, decide si está en `lo` (si `x ≤` cima viva de `lo`) o en `hi`, anótalo como muerto en ese lado y resta su tamaño vivo; reequilibra con los tamaños vivos limpiando las cimas antes de moverlas. En C++, dos `multiset` lo simplifican.

**02 → Problema: Task Scheduler.**

- **Pista 2 — patrón:** **montículo de frecuencias** con una cola de espera (o fórmula por la más frecuente).
- **Pista 3 — diseño:** en cada instante, ejecuta la tarea con más repeticiones pendientes que no esté en espera; guárdala en una cola hasta que pasen `n` intervalos. La fórmula directa: `max(total, (fmax − 1)(n + 1) + #tareas con fmax)`.

**02 → Problema: Reorganize String.**

- **Pista 2 — patrón:** **montículo de frecuencias** sin repetir la anterior.
- **Pista 3 — diseño:** saca la letra más frecuente; si es la misma que la última puesta, saca la segunda y devuelve la primera; si no hay segunda, es imposible. Antes, si alguna letra pasa de `⌈n/2⌉`, imposible.

**02 → Problema: Single-Threaded CPU.**

- **Pista 2 — patrón:** **eventos ordenados por llegada** + **montículo de disponibles** por (duración, índice).
- **Pista 3 — diseño:** ordena los índices por llegada; con el tiempo actual, mete las llegadas `≤ t`; si no hay disponibles, salta `t` a la siguiente llegada; si hay, ejecuta la de menor `(duración, índice)` y avanza `t`. Tiempos en 64 bits.

**02 → Problema: Furthest Building You Can Reach.**

- **Pista 2 — patrón:** **montículo de los `ladders` mayores saltos**.
- **Pista 3 — diseño:** recorre los saltos positivos metiéndolos en un montículo de mínimos; si pasa de `ladders`, saca el menor y págalo con ladrillos; si los ladrillos no alcanzan, el edificio anterior es la respuesta.

**02 → Problema: Design Twitter.**

- **Pista 2 — patrón:** **mezcla de `k` listas** de tuits por tiempo.
- **Pista 3 — diseño:** cada usuario guarda sus tuits con una marca de tiempo creciente; el *feed* mezcla con un montículo los últimos de él y de los que sigue, sacando como mucho 10.

**02 → Problema: Design a Number Container System.**

- **Pista 2 — patrón:** **montículo por número con borrado perezoso**.
- **Pista 3 — diseño:** un mapa índice→número y, por número, un montículo de índices; `find` limpia la cima de su montículo mientras el índice ya no tenga ese número (según el mapa) y devuelve la cima o −1.

**02 → Problema: Minimum Average Waiting Time.**

- **Pista 2 — patrón:** **planificación por la más corta disponible**.
- **Pista 3 — diseño:** ordena por llegada; mete en un montículo por duración los pedidos llegados; cuando el cocinero queda libre, toma el más corto; si no hay ninguno, salta al siguiente pedido. Suma las esperas en 64 bits y divide al final.

**02 → Problema: Sliding Window Median.**

- **Pista 2 — patrón:** **dos montículos con borrado perezoso**.
- **Pista 3 — diseño:** el esquema de la mediana con tamaños vivos; al deslizar, mete el nuevo, anota el que sale en su lado, reequilibra y limpia. Media de las dos cimas con reales para `k` par.

**02 → Problema: Smallest Range Covering Elements from K Lists.**

- **Pista 2 — patrón:** **montículo de cabezas** con el **máximo** actual.
- **Pista 3 — diseño:** el rango de las `k` cabezas es `[mínimo del montículo, máximo guardado]`; saca el mínimo, avanza en su lista y actualiza el máximo; para cuando una lista se agota; guarda el rango más estrecho.

**02 → Problema: IPO.**

- **Pista 2 — patrón:** **ordenar por capital** + **montículo de beneficios** de los asequibles.
- **Pista 3 — diseño:** ordena los proyectos por capital requerido; en cada una de las `k` rondas, mete en un montículo de máximos los beneficios de los que ya son asequibles y toma el mayor; si no hay ninguno, para.

**02 → Problema: Minimum Number of Refueling Stops.**

- **Pista 2 — patrón:** **montículo de gasolineras ya pasadas** (voraz con arrepentimiento).
- **Pista 3 — diseño:** avanza por las gasolineras metiendo su combustible en un montículo de máximos; cuando no llegas a la siguiente (o al destino), «repostas» en la mejor ya pasada (saca el máximo) y cuentas una parada; si el montículo está vacío, imposible.

**02 → Problema: The Skyline Problem.**

- **Pista 2 — patrón:** **barrido** por coordenadas + **montículo de alturas** con borrado perezoso.
- **Pista 3 — diseño:** eventos de inicio y fin de cada edificio ordenados (inicios antes que finales en la misma coordenada, y entre inicios el más alto antes); mantén las alturas activas con borrado perezoso; emite un punto cuando la altura máxima cambia.

---

# 03 — Montículos fusionables

**03 → 1.** ¿Qué operación añaden los montículos fusionables? 🟢

⏱️ **30 segundos.** `meld` (o `union`): unir dos montículos en uno con todos sus elementos, más rápido que reconstruir.

🗣️ **2 minutos.** En un binario en arreglo, fusionar cuesta `O(n + m)`. Los fusionables usan árboles con punteros para unir en `O(log n)` (*leftist*, binomial) o `O(1)` (Fibonacci, *pairing*).

🔬 **El detalle.** Algunos fusionables también mejoran `decrease-key`, que es lo que interesa en Dijkstra.

**03 → 2.** ¿Cuánto cuesta fusionar dos montículos binarios en arreglo, y por qué? 🟢

⏱️ **30 segundos.** `O(n + m)`: no hay forma de unir dos arreglos con forma de montículo sin reconstruir; se concatenan y se aplica `heapify`.

🗣️ **2 minutos.** La forma del montículo binario está fijada por la posición en el arreglo: dos montículos completos no encajan en otro completo moviendo unos pocos punteros. Concatenar y `heapify` es lineal, y no se puede hacer mejor sin cambiar la representación.

🔬 **El detalle.** Por eso la fusión práctica con colas de biblioteca vuelca la menor en la mayor: `O(menor · log)` en lugar de `O(n + m)`.

**03 → 3.** ¿Cuál es la alternativa práctica para fusionar muchas colas de prioridad? 🟢

⏱️ **30 segundos.** Volcar los elementos de la cola menor en la mayor (*small-to-large*), intercambiando antes las colas si hace falta para no copiar la grande.

🗣️ **2 minutos.** Cada elemento movido acaba en una cola al menos el doble de grande, así que se mueve `O(log n)` veces; con `O(log n)` por inserción, `O(n log² n)` en total. No hay que escribir ninguna estructura nueva.

🔬 **El detalle.** En C++, `std::swap` de dos `priority_queue` es `O(1)`; en Java y Python, se intercambian referencias.

**03 → 4.** ¿Qué cota da Dijkstra con un montículo de Fibonacci, y de qué operación viene la mejora? 🟡

⏱️ **30 segundos.** `O(m + n log n)`: la mejora viene de `decrease-key`, que pasa de `O(log n)` a `O(1)` amortizado, y hay hasta `m` de ellas.

🗣️ **2 minutos.** Dijkstra hace `n` extracciones del mínimo (`O(log n)` amortizado cada una) y hasta `m` relajaciones (`decrease-key`). Con un binario, `(n + m) log n`; con Fibonacci, `n log n + m`. En grafos densos, el ahorro teórico es un factor `log n`.

🔬 **El detalle.** Lo mismo vale para Prim ([`15/04`](../15-grafos-pesos-y-flujos/04-arbol-de-expansion-minima.md)).

**03 → 5.** ¿Por qué el montículo binomial se parece a sumar en binario? 🟡

⏱️ **30 segundos.** Porque guarda un árbol binomial por cada bit 1 de `n`, de tamaños distintos potencias de 2; fusionar dos es unir árboles del mismo tamaño como un acarreo, igual que sumar dos números en binario.

🗣️ **2 minutos.** Dos árboles binomiales de orden `k` se unen en uno de orden `k + 1` colgando la raíz mayor de la menor, en `O(1)`. Recorrer las dos listas de árboles por orden creciente y unir los iguales, con acarreo, es la suma binaria: `O(log n)` árboles, `O(log n)` operaciones.

🔬 **El detalle.** Insertar es fusionar con un montículo de un elemento: como incrementar un contador binario, `O(1)` amortizado ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

**03 → 6.** ¿Por qué un *leftist* fusiona en `O(log n)`? 🟡

⏱️ **30 segundos.** Porque su espina derecha (el camino que siempre va a la derecha) tiene `O(log n)` nodos, y fusionar solo recorre las dos espinas derechas.

🗣️ **2 minutos.** El invariante *leftist* dice que, en cada nodo, la distancia al hueco más cercano por la izquierda es al menos la de la derecha. De ahí sale que un árbol con espina derecha de longitud `r` tiene al menos `2ʳ − 1` nodos, y `r = O(log n)`. La fusión mezcla las dos espinas como dos listas ordenadas y, al volver, intercambia hijos donde se haya roto el invariante.

🔬 **El detalle.** El montículo *skew* es la versión sin el invariante, con `O(log n)` amortizado.

**03 → 7.** ¿Por qué el montículo de Fibonacci casi nunca gana en la práctica? 🟠

⏱️ **30 segundos.** Por sus constantes y su localidad: muchos punteros por nodo, listas circulares, consolidaciones y cortes en cascada, frente a un arreglo contiguo con aritmética de índices.

🗣️ **2 minutos.** El factor `log n` que ahorra en teoría es pequeño (unos 20 con `n = 10⁶`) y se lo comen las constantes y los fallos de caché ([`02/05`](../02-analisis/05-el-coste-real.md)). Además, en grafos dispersos no hay ahorro asintótico, y en densos un Dijkstra `O(n²)` sin montículo ya es óptimo.

🔬 **El detalle.** Los estudios experimentales suelen encontrar que montículos binarios o `d`-arios con borrado perezoso ganan en grafos reales.

**03 → 8.** Demuestra que fusionar colas de la menor a la mayor mueve cada elemento `O(log n)` veces. 🟠

⏱️ **30 segundos.** Al volcar la cola menor en la mayor, cada elemento movido acaba en una cola de al menos el doble de tamaño que la suya; como no puede pasar de `n`, se mueve como mucho `log₂ n` veces.

🗣️ **2 minutos.** Si se fusionan colas de tamaños `a ≤ b` moviendo las `a`, cada elemento movido pasa de una cola de tamaño `a` a una de `a + b ≥ 2a`. Es el argumento de [`07/06`](../07-arboles/06-tecnicas-sobre-arboles.md) y de la unión por tamaño de [`08/04`](04-union-find.md).

🔬 **El detalle.** Si se moviera siempre la cola `b` a la `a` sin mirar tamaños, una secuencia adversaria haría mover `Θ(n²)` elementos.

**03 → 9.** Compara qué ofrecen C++, Java y Python para un montículo fusionable. 🟠

⏱️ **30 segundos.** C++: `__gnu_pbds::priority_queue` de *policy-based* con `join` (con `pairing_heap_tag` u otros). Java y Python: nada; se fusiona con *small-to-large* sobre `PriorityQueue` o `heapq`.

🗣️ **2 minutos.** El `join` de *policy-based* es `O(1)` o `O(log n)` según la etiqueta, y además ofrece `modify` (cambiar la prioridad con un iterador). En Java, `addAll` de la menor en la mayor; en Python, `heappush` de cada elemento o concatenar y `heapify` si la mayor no es mucho mayor.

🔬 **El detalle.** [`03/02`](../03-biblioteca-estandar/02-cpp-algoritmos-ranges-y-pbds.md) describe *policy-based*.

**03 → 10.** ¿Cuándo es mejor Dijkstra en `O(n²)` sin montículo que con uno binario? 🟠

⏱️ **30 segundos.** Cuando el grafo es denso (`m` cerca de `n²`): sin montículo, `n` búsquedas lineales del mínimo cuestan `O(n²)`, que es menos que `O(n² log n)` con montículo.

🗣️ **2 minutos.** Con `n = 3000` y `m ≈ 4,5·10⁶`, el binario con borrado perezoso haría del orden de `m log m ≈ 10⁸` operaciones con mala localidad; la versión `O(n²)` hace `9·10⁶` pasos sobre arreglos contiguos. El grafo suele venir como matriz, que encaja con la versión sin montículo.

🔬 **El detalle.** `15/01` da las dos versiones de Dijkstra.

**03 → 11.** ¿Qué garantiza «amortizado» en el montículo de Fibonacci, y por qué no sirve para tiempo real? 🔴

⏱️ **30 segundos.** Que la suma de los costes de cualquier secuencia de `m` operaciones está acotada por la suma de las cotas amortizadas; una operación concreta, en particular una extracción, puede costar `Θ(n)`.

🗣️ **2 minutos.** La extracción consolida todos los árboles acumulados por inserciones y cortes perezosos: tras muchas inserciones, una sola extracción puede recorrer `n` raíces. Para un juez basta; para un sistema de tiempo real que necesita acotar cada operación, no.

🔬 **El detalle.** Hay variantes con cotas de peor caso (Brodal, montículos de Fibonacci estrictos), muy complejas.

**03 → 12.** ¿Por qué los árboles del montículo de Fibonacci tienen al menos `F_{k+2}` nodos con grado `k`, y qué consecuencia tiene para la extracción? 🔴

⏱️ **30 segundos.** Porque los cortes en cascada impiden que un nodo pierda más de un hijo sin ser cortado él mismo; con eso, un nodo de grado `k` tiene al menos `F_{k+2}` descendientes, y el grado máximo es `O(log n)`. La extracción consolida en `O(grado máximo)`.

🗣️ **2 minutos.** Si los hijos de un nodo se ordenan por cuándo se enlazaron, el `i`-ésimo tenía grado `≥ i − 1` al enlazarse y puede haber perdido como mucho un hijo: grado `≥ i − 2`. Por inducción, el tamaño mínimo cumple la recurrencia de Fibonacci, `≥ F_{k+2} ≥ φᵏ`. Así el grado es `≤ log_φ n`, y la consolidación de la extracción trabaja con `O(log n)` grados distintos.

🔬 **El detalle.** CLRS, 3.ª ed., §19.4: de ahí viene el nombre del montículo.

**03 → Problema: Fusión de colas.**

- **Pista 2 — patrón:** **small-to-large** con colas de biblioteca.
- **Pista 3 — diseño:** guarda las colas en un arreglo indexable; en `m a b`, si la de `b` es mayor que la de `a`, intercámbialas (`O(1)`) y después vuelca la menor en la mayor; la cola `b` queda vacía. `O((n + q) log² n)`.

**03 → Problema: Caminos en un grafo denso.**

- **Pista 2 — patrón:** **Dijkstra sin montículo**, `O(n²)`.
- **Pista 3 — diseño:** arreglo de distancias y marcas; `n` veces, elige el no marcado de menor distancia recorriendo el arreglo, márcalo y relaja su fila de la matriz. Distancias en 64 bits; lectura rápida de `9·10⁶` enteros.

---

# 04 — Union-Find

**04 → 1.** ¿Qué hacen `find` y `union`, y qué representa la raíz de cada árbol? 🟢

⏱️ **30 segundos.** `find(x)` devuelve el representante del grupo de `x` (la raíz de su árbol); `union(a, b)` une los grupos de `a` y `b` colgando una raíz de la otra. La raíz representa al grupo entero.

🗣️ **2 minutos.** Dos elementos están en el mismo grupo si y solo si tienen la misma raíz. El bosque no refleja ninguna estructura del problema: solo sirve para llegar al representante.

🔬 **El detalle.** El representante puede cambiar tras una unión; lo único estable es la relación «mismo grupo».

**04 → 2.** ¿Qué es la compresión de caminos y qué es la unión por tamaño? 🟢

⏱️ **30 segundos.** Compresión: tras buscar la raíz de `x`, los nodos del camino pasan a apuntar a la raíz (o a su abuelo). Unión por tamaño: al unir, la raíz del árbol más pequeño se cuelga de la del más grande.

🗣️ **2 minutos.** La compresión acorta caminos para las búsquedas futuras; la unión por tamaño evita que se formen caminos largos. Juntas dan `O(α(n))` amortizado.

🔬 **El detalle.** La unión por rango (una cota de la altura) da la misma garantía que por tamaño; el tamaño tiene la ventaja de que además es un dato útil.

**04 → 3.** ¿Cómo detectas con Union-Find si una arista cierra un ciclo en un grafo no dirigido? 🟢

⏱️ **30 segundos.** Antes de unir los extremos de la arista, si `find(a) == find(b)` ya estaban conectados: la arista cierra un ciclo.

🗣️ **2 minutos.** En un grafo no dirigido, una arista entre dos vértices ya conectados crea un segundo camino entre ellos: un ciclo. `unite` devolviendo `false` lo detecta. Es lo que hace Kruskal para descartar aristas.

🔬 **El detalle.** En grafos dirigidos no vale: un ciclo dirigido no es «dos nodos ya conectados»; se usa DFS ([`14/03`](../14-grafos-recorridos/03-dfs.md)).

**04 → 4.** ¿Por qué `size[x]` solo es fiable si `x` es raíz? 🟡

⏱️ **30 segundos.** Porque solo se actualiza en las raíces: cuando una raíz se cuelga de otra, su `size` deja de actualizarse. Hay que leer `size[find(x)]`.

🗣️ **2 minutos.** Mantener el tamaño en todos los nodos costaría `O(n)` por unión. El de la raíz es el del grupo, y los demás quedan con valores viejos sin significado.

🔬 **El detalle.** Lo mismo pasa con cualquier agregado por grupo (suma, mínimo): vive en la raíz.

**04 → 5.** ¿Por qué la unión por tamaño sola garantiza altura `≤ log₂ n`? 🟡

⏱️ **30 segundos.** Porque la profundidad de un nodo solo aumenta cuando su árbol se cuelga de otro al menos igual de grande: cada aumento de profundidad duplica el tamaño de su árbol, que no pasa de `n`.

🗣️ **2 minutos.** Si `x` está a profundidad `h`, su árbol se ha colgado de otro `h` veces, y cada vez el árbol resultante tenía al menos el doble de nodos. Así que su árbol tiene al menos `2ʰ` nodos y `h ≤ log₂ n`.

🔬 **El detalle.** Es el mismo argumento de *small-to-large* (`07/06`).

**04 → 6.** ¿Cuánto cuesta Union-Find con solo compresión, y con las dos mejoras? 🟡

⏱️ **30 segundos.** Solo compresión: `O(log n)` amortizado por operación. Las dos mejoras: `O(α(n))` amortizado.

🗣️ **2 minutos.** La compresión sola puede encontrarse árboles altos creados por uniones malas, que se aplanan poco a poco: el análisis de Tarjan y van Leeuwen da `O(log n)` amortizado. Con unión por tamaño, los árboles ya son bajos y la compresión los deja casi planos: `α(n)`.

🔬 **El detalle.** CLRS, 3.ª ed., §21.4, hace el análisis de las dos juntas.

**04 → 7.** ¿Por qué en el Union-Find con pesos hay que comprimir el padre antes de sumar su `d`? 🟡

⏱️ **30 segundos.** Porque `d[padre]` solo es relativo a la raíz después de comprimir al padre; sumarlo antes daría un desplazamiento relativo a un nodo intermedio.

🗣️ **2 minutos.** `find(x)` llama primero a `find(padre)`, que deja `d[padre] = valor(padre) − valor(raíz)`. Entonces `d[x] + d[padre]` es `valor(x) − valor(raíz)`, y se puede colgar `x` de la raíz. En el orden contrario, se sumaría un `d[padre]` que aún era relativo a su propio padre.

🔬 **El detalle.** Una versión iterativa hace dos pasadas: primero sube acumulando la suma total, después baja reasignando.

**04 → 8.** Demuestra que con unión por tamaño todo árbol de altura `h` tiene al menos `2ʰ` nodos. 🟠

⏱️ **30 segundos.** Inducción sobre las uniones: si `x` pasa a estar a profundidad `h`, es porque su árbol (de tamaño `≥ 2^{h−1}`) se colgó de uno al menos igual de grande, y el resultado tiene `≥ 2ʰ` nodos.

🗣️ **2 minutos.** Base: un nodo solo, altura 0, `2⁰ = 1` nodo. Paso: al unir árboles de tamaños `s ≤ t`, los nodos del pequeño ganan un nivel; el árbol nuevo tiene altura `max(h_t, h_s + 1)` y tamaño `s + t`. Si la altura es `h_t`, ya cumplía; si es `h_s + 1`, `s + t ≥ 2s ≥ 2 · 2^{h_s} = 2^{h_s + 1}`.

🔬 **El detalle.** Consecuencia: `find` sin compresión cuesta `O(log n)`, que es lo que usa la versión con *rollback*.

**04 → 9.** ¿Cómo detectas con paridad que un grafo deja de ser bipartito al añadir una arista? 🟠

⏱️ **30 segundos.** Con un Union-Find con paridad (`d[x]` = 0 o 1 respecto de la raíz): al unir `a` y `b` como rivales, si ya están en el mismo grupo y `d[a] ⊕ d[b] = 0`, están en el mismo lado: ciclo impar, deja de ser bipartito.

🗣️ **2 minutos.** La paridad de `x` respecto de la raíz dice en qué equipo está. Una arista exige paridades distintas. Si los dos ya están en el mismo grupo, la paridad está fijada y se comprueba; si no, se cuelga una raíz de la otra con el desplazamiento que haga distintas las paridades.

🔬 **El detalle.** Alternativa sin pesos: dos nodos por persona (`x` y «no `x`») y unir `a` con «no `b`» y `b` con «no `a`»; conflicto si `a` y «no `a`» quedan juntos.

**04 → 10.** Compara cómo escribirías Union-Find en C++, Java y Python, y por qué `find` iterativo. 🟠

⏱️ **30 segundos.** Igual en los tres, con arreglos de enteros; `find` iterativo con *halving* para no depender de la recursión, que en Java y Python desborda con caminos largos.

🗣️ **2 minutos.** En C++ la recursión aguanta más, pero el iterativo es igual de corto. En Java, la recursión con `n = 10⁶` puede dar `StackOverflowError` antes de que la compresión aplane. En Python, además del límite de recursión, la llamada a función es cara: el bucle con la lista en una variable local es más rápido.

🔬 **El detalle.** En Python conviene evitar la clase y usar listas y funciones locales en el bucle principal si el tiempo es justo.

**04 → 11.** ¿Por qué el Union-Find con *rollback* no puede usar compresión de caminos? 🟠

⏱️ **30 segundos.** Porque la compresión modifica muchos punteros en cada `find`, fuera de las uniones registradas en la pila; al deshacer, esos punteros seguirían apuntando a raíces que ya no lo son.

🗣️ **2 minutos.** El *rollback* restaura exactamente los cambios de cada `unite`: un `parent` y un `size`. Si `find` también cambiara punteros, habría que registrarlos y deshacerlos, y el coste de `find` dejaría de ser `O(1)` de escritura. Sin compresión, la unión por tamaño mantiene `find` en `O(log n)`.

🔬 **El detalle.** El coste total pasa de `α(n)` a `log n` por operación, que es el precio de poder deshacer.

**04 → 12.** ¿Qué es `α(n)` y por qué se considera constante en la práctica? 🔴

⏱️ **30 segundos.** La inversa de la función de Ackermann: crece tan despacio que `α(n) ≤ 4` para todo `n` menor que un número astronómicamente grande. Por eso `O(α(n))` se trata como constante.

🗣️ **2 minutos.** La función de Ackermann crece más rápido que cualquier torre de exponentes; su inversa, en consecuencia, más despacio que `log* n` (las veces que hay que aplicar `log` para bajar de 1). Ningún `n` práctico pasa de 4 o 5.

🔬 **El detalle.** Tarjan demostró además que `Ω(α(n))` es una cota inferior para este problema en ciertos modelos: no se puede hacer mejor en general.

**04 → 13.** ¿Cómo combinas Union-Find con *rollback* y un *segment tree* sobre el tiempo para la conectividad con borrados *offline*, y con qué coste? 🔴

⏱️ **30 segundos.** Cada arista vive en un intervalo de tiempo; se inserta en los `O(log T)` nodos del *segment tree* que cubren el intervalo. Un DFS une las aristas de cada nodo al entrar, responde en las hojas y hace `rollback` al salir. `O(m log T log n)`.

🗣️ **2 minutos.** `snapshot` al entrar en un nodo y `rollback(snapshot)` al salir garantizan que en cada hoja solo están unidas las aristas vivas en ese instante. Cada arista se une `O(log T)` veces y cada unión cuesta `O(log n)`.

🔬 **El detalle.** [`07/07`](../07-arboles/07-arboles-dinamicos.md), §2 y pregunta 8.

**04 → Problema: El cable que sobra.**

- **Pista 2 — patrón:** **Union-Find**: la primera unión que falla.
- **Pista 3 — diseño:** recorre los cables; si `unite` devuelve `false`, imprime su número y termina; si ninguno falla, `0`.

**04 → Problema: Balanzas.**

- **Pista 2 — patrón:** **Union-Find con pesos** (diferencias).
- **Pista 3 — diseño:** `unite(a, b, w)` impone `peso(b) − peso(a) = w`; si ya están en el mismo grupo, comprueba `d[b] − d[a] == w`; la primera que falle es la respuesta. Diferencias en 64 bits; `find` sin recursión profunda (añade unión por tamaño o hazlo iterativo).

**04 → Problema: Equipos rivales.**

- **Pista 2 — patrón:** **Union-Find con paridad**.
- **Pista 3 — diseño:** `d[x] ∈ {0, 1}` respecto de la raíz con *xor*; cada par exige paridades distintas; el primero que lo contradiga (mismo grupo y misma paridad) es la respuesta.

**04 → Problema: Number of Provinces.**

- **Pista 2 — patrón:** **contar grupos** con Union-Find.
- **Pista 3 — diseño:** empieza con `n` grupos y resta uno por cada `unite` efectiva al recorrer la matriz de adyacencia.

**04 → Problema: Redundant Connection.**

- **Pista 2 — patrón:** **arista que cierra un ciclo**.
- **Pista 3 — diseño:** recorre las aristas en orden; la última (y única) que no se puede unir es la respuesta.

**04 → Problema: Satisfiability of Equality Equations.**

- **Pista 2 — patrón:** **igualdades primero, desigualdades después**.
- **Pista 3 — diseño:** une las variables de cada `==`; después, comprueba que ninguna `!=` tiene sus dos variables en el mismo grupo. 26 elementos.

**04 → Problema: Number of Operations to Make Network Connected.**

- **Pista 2 — patrón:** **grupos y aristas sobrantes**.
- **Pista 3 — diseño:** si hay menos de `n − 1` cables, imposible; si no, la respuesta es el número de grupos menos 1.

**04 → Problema: Accounts Merge.**

- **Pista 2 — patrón:** **Union-Find sobre correos** con un mapa correo→índice.
- **Pista 3 — diseño:** une todos los correos de cada cuenta con el primero; agrupa los correos por raíz, ordénalos y añade el nombre de cualquier cuenta del grupo.

**04 → Problema: Components in a graph.**

- **Pista 2 — patrón:** **tamaños de grupo** en las raíces.
- **Pista 3 — diseño:** une los pares; recorre las raíces y toma el menor y el mayor tamaño entre los grupos con al menos dos nodos.

**04 → Problema: Merging Communities.**

- **Pista 2 — patrón:** **unión por tamaño** consultando el tamaño de la raíz.
- **Pista 3 — diseño:** `M i j` une; `Q i` imprime `size[find(i)]`. Lectura rápida.

**04 → Problema: Evaluate Division.**

- **Pista 2 — patrón:** **Union-Find con cocientes** (pesos multiplicativos).
- **Pista 3 — diseño:** `w[x] = valor(x) / valor(raíz)`; al comprimir, multiplica; `a / b = w[a] / w[b]` si están en el mismo grupo, y `−1` si no (o si alguna variable no existe).

**04 → Problema: Possible Bipartition.**

- **Pista 2 — patrón:** **paridad** (o dos nodos por persona).
- **Pista 3 — diseño:** para cada aversión, exige paridades distintas; si dos con aversión acaban en el mismo grupo con la misma paridad, imposible.

**04 → Problema: Most Stones Removed with Same Row or Column.**

- **Pista 2 — patrón:** **unir filas y columnas** como nodos.
- **Pista 3 — diseño:** cada piedra une su fila con su columna (columnas desplazadas para no chocar con filas); la respuesta es el número de piedras menos el número de grupos que contienen alguna piedra.

**04 → Problema: Similar String Groups.**

- **Pista 2 — patrón:** **unir pares similares**.
- **Pista 3 — diseño:** compara todos los pares (`O(n² · L)`); dos cadenas son similares si son iguales o difieren en exactamente dos posiciones intercambiables; une y cuenta grupos.

**04 → Problema: Redundant Connection II.**

- **Pista 2 — patrón:** **dos casos**: un nodo con dos padres, o un ciclo.
- **Pista 3 — diseño:** busca un nodo con dos aristas entrantes (candidatas A y B, en ese orden); quita B y comprueba con Union-Find si queda un ciclo: si no, la respuesta es B; si sí, es A. Si no hay dos padres, la respuesta es la arista que cierra el ciclo.

---

# 05 — Simulación

**05 → S1.** ¿Qué cuesta construir un montículo con `heapify`, y por qué no `O(n log n)`? 🟡

⏱️ **30 segundos.** `O(n)`: los nodos que pueden bajar mucho son pocos; la mitad son hojas y no se mueven.

🗣️ **2 minutos.** `heapify` aplica `siftDown` desde los últimos nodos internos hacia la raíz; un nodo de altura `h` baja como mucho `h`, y hay `≈ n/2^{h+1}` de ellos. La suma `Σ h · n/2^{h+1}` es `O(n)`. Insertar uno a uno sí es `O(n log n)`.

🔬 **El detalle.** [`08/01`](01-monticulo-binario.md), §2; la prueba es la S17.

**05 → S2.** ¿Qué da por defecto `std::priority_queue`, `PriorityQueue` y `heapq`? 🟢

⏱️ **30 segundos.** `std::priority_queue`: el máximo. `PriorityQueue` y `heapq`: el mínimo.

🗣️ **2 minutos.** En C++, mínimos con `greater<T>`; en Java, máximos con `Comparator.reverseOrder()`; en Python, máximos negando los valores (hasta 3.14).

🔬 **El detalle.** `08/01`, §3.

**05 → S3.** ¿Qué haces cuando necesitas `decrease-key` con la cola de tu biblioteca? 🟡

⏱️ **30 segundos.** Borrado perezoso: meter la entrada con la prioridad nueva y, al sacar, descartar las que ya no coinciden con el valor vigente. O escribir una cola indexada.

🗣️ **2 minutos.** El borrado perezoso es lo habitual: no exige saber dónde está el elemento, a cambio de que la cola crezca hasta el número de inserciones. La cola indexada guarda la posición de cada índice y hace `decrease-key` en `O(log n)`.

🔬 **El detalle.** `08/01`, §5, y [`08/02`](02-patrones-con-heap.md), §6.

**05 → S4.** ¿Qué montículo y de qué tamaño usas para los `k` mayores de un flujo? 🟢

⏱️ **30 segundos.** Uno de **mínimos** de tamaño `k`: su cima es el menor de los retenidos y decide si entra cada nuevo.

🗣️ **2 minutos.** Si llega un valor mayor que la cima, sale la cima y entra él. `O(n log k)` en tiempo y `O(k)` en memoria.

🔬 **El detalle.** `08/02`, §3.

**05 → S5.** ¿Cuánto cuesta mezclar `k` listas ordenadas con `N` elementos en total? 🟢

⏱️ **30 segundos.** `O(N log k)`: el montículo de cabezas nunca tiene más de `k` elementos.

🗣️ **2 minutos.** Cada uno de los `N` elementos se saca una vez y provoca a lo sumo una inserción, las dos en `O(log k)`.

🔬 **El detalle.** `08/02`, §4; la cota inferior `Ω(N log k)` está en su pregunta 13.

**05 → S6.** ¿Qué invariantes mantienen los dos montículos de la mediana? 🟡

⏱️ **30 segundos.** Todo valor de `lo` (máximos) es `≤` que todo valor de `hi` (mínimos), y `|lo| − |hi| ∈ {0, 1}`.

🗣️ **2 minutos.** Con eso, la cima de `lo` es la mediana inferior. Tras insertar, si los tamaños se descompensan, se pasa una cima al otro montículo.

🔬 **El detalle.** `08/02`, §5.

**05 → S7.** ¿Por qué el montículo de Fibonacci casi nunca gana a un binario en Dijkstra? 🟡

⏱️ **30 segundos.** Por sus constantes y su localidad de caché: muchos punteros por nodo y operaciones perezosas costosas, frente a un arreglo contiguo.

🗣️ **2 minutos.** El ahorro teórico es un factor `log n` en grafos densos; en dispersos, ninguno. En densos, además, Dijkstra `O(n²)` sin montículo ya es óptimo.

🔬 **El detalle.** [`08/03`](03-monticulos-fusionables.md), §2.

**05 → S8.** ¿Qué dos mejoras necesita Union-Find para `O(α(n))`? 🟢

⏱️ **30 segundos.** Compresión de caminos y unión por tamaño (o por rango).

🗣️ **2 minutos.** Solo compresión: `O(log n)` amortizado. Solo unión por tamaño: `O(log n)` peor caso. Las dos: `O(α(n))` amortizado.

🔬 **El detalle.** `08/04`, §2.

**05 → S9.** ¿Cómo detectas con Union-Find la primera arista que cierra un ciclo? 🟢

⏱️ **30 segundos.** Antes de unir los extremos, si ya tienen la misma raíz, la arista cierra un ciclo.

🗣️ **2 minutos.** `unite` devuelve `false` cuando las raíces coinciden. Recorriendo las aristas en orden, la primera que devuelve `false` es la respuesta.

🔬 **El detalle.** Solo en grafos no dirigidos.

**05 → S10.** ¿Qué guarda el Union-Find con pesos y para qué sirve? 🟡

⏱️ **30 segundos.** El valor de cada nodo relativo a la raíz de su grupo (una diferencia, un cociente o una paridad). Sirve para responder «¿cuánto difieren `a` y `b`?» y detectar contradicciones.

🗣️ **2 minutos.** Al comprimir, se acumulan los pesos del camino; al unir, el desplazamiento entre raíces sale de la relación impuesta. Una relación entre dos del mismo grupo se comprueba con `d[b] − d[a]`.

🔬 **El detalle.** `08/04`, §4.

**05 → S11.** Tu Dijkstra con `PriorityQueue` da WA y metes la misma arista varias veces. ¿Qué te falta al sacar de la cola? 🟠

⏱️ **30 segundos.** Descartar las entradas viejas: al sacar `(distancia, nodo)`, si la distancia es mayor que la mejor conocida de ese nodo, se ignora.

🗣️ **2 minutos.** Sin esa comprobación, un nodo se procesa varias veces con distancias peores y relaja aristas con valores incorrectos o, como poco, repite trabajo. Con la comprobación, cada nodo se procesa una vez con su distancia definitiva.

🔬 **El detalle.** `08/02`, pregunta 7; `15/01`.

**05 → S12.** «Para los `k` mayores ordeno todo.» ¿Cuándo es la mejor respuesta y cuándo no? 🟠

⏱️ **30 segundos.** Es buena si todos los datos están en memoria y `k` es comparable a `n`, o si se piden muchas posiciones. No lo es con un flujo que no cabe en memoria o con `k ≪ n`: un montículo de tamaño `k` cuesta `O(n log k)` y `O(k)`.

🗣️ **2 minutos.** Ordenar es `O(n log n)` y simple; el montículo gana en memoria y en tiempo cuando `k` es pequeño; *quickselect* da los `k` mayores en `O(n)` esperado si están en memoria.

🔬 **El detalle.** `08/02`, pregunta 11.

**05 → S13.** Tu Union-Find en Java da `StackOverflowError` con `n = 10⁶`. ¿Por qué, si es casi constante? 🟠

⏱️ **30 segundos.** Porque `find` es recursivo y, antes de que la compresión aplane, puede haber caminos largos (por ejemplo, sin unión por tamaño, o la primera vez que se recorre una cadena). Se arregla con `find` iterativo y unión por tamaño.

🗣️ **2 minutos.** El `O(α(n))` es amortizado: una llamada concreta puede recorrer un camino largo. Con recursión, ese camino son marcos de pila. Con unión por tamaño la altura es `≤ log₂ n` y la recursión no pasaría de 20 niveles, pero el iterativo con *halving* evita la cuestión del todo.

🔬 **El detalle.** `08/04`, §3 y pregunta 10.

**05 → S14.** Imprimes una `PriorityQueue` para depurar y no sale ordenada. ¿Es un error? 🟠

⏱️ **30 segundos.** No: el iterador y `toString` recorren el arreglo interno del montículo, que solo garantiza que la cabeza es el mínimo.

🗣️ **2 minutos.** El montículo es un orden parcial. Para ver los elementos en orden, hay que sacarlos con `poll` (en una copia) o copiarlos y ordenarlos.

🔬 **El detalle.** `08/01`, pregunta 12.

**05 → S15.** Te piden «grupos que se separan» además de grupos que se unen. ¿Qué preguntas antes de elegir estructura? 🟠

⏱️ **30 segundos.** Si las operaciones se conocen de antemano. *Offline*: tiempo al revés o *segment tree* sobre el tiempo con Union-Find con *rollback*. *Online*: árboles dinámicos en bosques, o algo más complejo en grafos generales.

🗣️ **2 minutos.** Union-Find solo une. Si los borrados se conocen, se procesan al revés como uniones; si las aristas aparecen y desaparecen, el *segment tree* sobre el tiempo con *rollback*. Y si las restricciones son pequeñas, un recorrido por consulta.

🔬 **El detalle.** `07/07`, §5; `08/04`, §5.

**05 → S16.** Demuestra que con unión por tamaño la altura de los árboles de Union-Find es como mucho `log₂ n`. 🔴

⏱️ **30 segundos.** La profundidad de un nodo solo aumenta cuando su árbol se cuelga de otro al menos igual de grande: cada aumento duplica el tamaño de su árbol, que no pasa de `n`.

🗣️ **2 minutos.** Inducción: al unir árboles de tamaños `s ≤ t`, los nodos del de `s` bajan un nivel y quedan en un árbol de `s + t ≥ 2s` nodos. Un nodo a profundidad `h` ha bajado `h` veces: su árbol tiene `≥ 2ʰ` nodos, así que `h ≤ log₂ n`.

🔬 **El detalle.** `08/04`, pregunta 8.

**05 → S17.** Demuestra que `heapify` es `O(n)`. 🔴

⏱️ **30 segundos.** `Σ_h ⌈n/2^{h+1}⌉ · O(h) = O(n · Σ h/2^h) = O(2n)`.

🗣️ **2 minutos.** Un `siftDown` desde altura `h` hace como mucho `h` intercambios, y en un árbol completo hay como mucho `⌈n/2^{h+1}⌉` nodos de altura `h`. La serie `Σ h/2^h` converge a 2.

🔬 **El detalle.** `08/01`, pregunta 7.

**05 → Problema: Islas que crecen.**

- **Pista 2 — patrón:** **Union-Find** sobre las celdas con un contador de islas.
- **Pista 3 — diseño:** cada celda es el índice `fila · C + columna`; al hacerla tierra (si no lo era), suma 1 al contador y únela con sus vecinas de tierra, restando 1 por cada unión efectiva.

**05 → Problema: Mediana de las pujas.**

- **Pista 2 — patrón:** **dos montículos**.
- **Pista 3 — diseño:** `lo` de máximos y `hi` de mínimos; tras cada puja, coloca y equilibra; imprime la cima de `lo`.

**05 → Problema: Registros mezclados.**

- **Pista 2 — patrón:** **mezcla de `k` listas**.
- **Pista 3 — diseño:** montículo de `(marca, registro, posición)`; el desempate por registro lo da la tupla; saca, imprime y repón del mismo registro. Salida rápida para `10⁶` líneas.

**05 → Problema: Reparto de premios.**

- **Pista 2 — patrón:** **ordenar una vez** y **prefijos**.
- **Pista 3 — diseño:** ordena de mayor a menor y calcula los prefijos ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)) en 64 bits; cada consulta es `pref[k]`.

**05 → Problema: Smallest String With Swaps.**

- **Pista 2 — patrón:** **Union-Find** sobre posiciones y **ordenar dentro de cada grupo**.
- **Pista 3 — diseño:** une las posiciones de cada par; agrupa por raíz; ordena las letras de cada grupo y colócalas en sus posiciones en orden creciente.

**05 → Problema: Lexicographically Smallest Equivalent String.**

- **Pista 2 — patrón:** **Union-Find** sobre letras con el **menor como representante**.
- **Pista 3 — diseño:** al unir, cuelga siempre la raíz mayor de la menor; cada letra de la cadena base se sustituye por la raíz de su grupo.

**05 → Problema: Regions Cut By Slashes.**

- **Pista 2 — patrón:** **Union-Find** sobre cuatro triángulos por celda.
- **Pista 3 — diseño:** divide cada celda en norte, este, sur y oeste; `/` une norte-oeste y sur-este; `\` une norte-este y sur-oeste; un espacio une los cuatro; une cada triángulo con el vecino de la celda contigua; cuenta grupos.

**05 → Problema: Journey to the Moon.**

- **Pista 2 — patrón:** **tamaños de grupo** y conteo de pares.
- **Pista 3 — diseño:** une los pares del mismo país; con los tamaños de grupo `s₁, s₂, …`, la respuesta es `(n² − Σ sᵢ²) / 2`, en 64 bits.

**05 → Problema: K-th Smallest Prime Fraction.**

- **Pista 2 — patrón:** **mezcla de listas ordenadas** con un montículo (o binaria sobre el valor).
- **Pista 3 — diseño:** para cada denominador `arr[j]`, las fracciones `arr[i]/arr[j]` con `i < j` crecen con `i`: mete la primera de cada lista en un montículo y saca `k` veces reponiendo la siguiente de la misma lista. Compara con productos cruzados.

**05 → Problema: Maximum Subsequence Score.**

- **Pista 2 — patrón:** **ordenar por el mínimo** y **montículo de los `k` mayores** de la otra lista.
- **Pista 3 — diseño:** ordena los pares por `nums2` descendente; al recorrer, el actual es el mínimo de los elegidos; mantén las `k` mayores `nums1` vistas en un montículo de mínimos con su suma; con `k`, prueba `suma · nums2[actual]`.
