# Respuestas — bloque 06: Lineales y hashing

> Solucionario del bloque `06`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--pila-cola-deque-y-sus-versiones-monótonas) · [02](#02--listas-enlazadas) · [03](#03--tablas-hash-por-dentro-y-los-anti-hash-tests) · [04](#04--hashing-de-secuencias) · [05](#05--simulación)

---

# 01 — Pila, cola, deque y sus versiones monótonas

**01 → 1.** ¿Qué diferencia hay entre pila, cola y deque, y qué usarías en Java para cada una? 🟢

⏱️ **30 segundos.** La pila saca el último que entró; la cola, el primero; la deque mete y saca por los dos extremos. En Java, `ArrayDeque` para las tres.

🗣️ **2 minutos.** `ArrayDeque` es un arreglo circular que crece: `push`/`pop`/`peek` para pila, `offer`/`poll`/`peek` para cola, y las versiones `First`/`Last` para deque, todas en `O(1)` amortizado. `Stack` y `LinkedList` funcionan, pero son más lentas.

🔬 **El detalle.** `ArrayDeque` no admite `null`: `poll` devuelve `null` para decir «vacía», y por eso no puede guardarlo.

**01 → 2.** ¿Por qué `list.pop(0)` es una mala cola en Python? 🟢

⏱️ **30 segundos.** Porque `pop(0)` desplaza todos los elementos una posición: `O(n)` por operación, `O(n²)` para vaciar una cola de `n`.

🗣️ **2 minutos.** `list` es un arreglo dinámico contiguo: quitar del final es `O(1)`, quitar del principio obliga a mover todo lo demás. `collections.deque` es una lista doblemente enlazada de bloques, con `append`, `appendleft`, `pop` y `popleft` en `O(1)`.

🔬 **El detalle.** El precio de `deque` es el acceso por índice en mitad, que es `O(n)`. Para una cola con muchos accesos por posición, un `list` y un índice de cabeza que avanza.

**01 → 3.** ¿Qué se guarda en la pila monótona, índices o valores, y por qué? 🟢

⏱️ **30 segundos.** Índices: con el índice se tiene el valor (`a[i]`) y además la posición, que hace falta para distancias, para anotar la respuesta y para saber si un elemento salió de una ventana.

🗣️ **2 minutos.** Si se guardaran valores, al sacar un elemento no se sabría a qué posición anotarle la respuesta, ni cuántos días hay hasta ella. En la cola monótona, sin índices no hay forma de saber si el de delante salió de la ventana.

🔬 **El detalle.** En los problemas en que solo importan los valores (el máximo de la pila, por ejemplo) se pueden guardar valores, pero los índices nunca estorban.

**01 → 4.** Enuncia el invariante de la pila monótona para «el siguiente mayor». 🟡

⏱️ **30 segundos.** Los índices de la pila, de abajo arriba, tienen valores estrictamente decrecientes y son exactamente los ya vistos que aún no tienen un mayor a su derecha.

🗣️ **2 minutos.** Al procesar `i`: se sacan los de la cima con valor `< a[i]` y se les anota `i`, que es su primer mayor, porque todo lo que había entre ellos e `i` era menor o igual (si no, ya habrían salido). Los que quedan tienen valor `≥ a[i]`, así que apilar `i` mantiene el orden decreciente. Y siguen sin mayor a su derecha.

🔬 **El detalle.** Con la comparación `<`, los iguales se quedan en la pila: el orden es decreciente en sentido amplio. Es la diferencia entre «estrictamente mayor» y «mayor o igual».

**01 → 5.** Demuestra con el análisis agregado que la pila monótona es `Θ(n)`. 🟡

⏱️ **30 segundos.** Cada índice se apila una vez y se desapila como mucho una vez: como mucho `2n` operaciones de pila en total, sin importar cómo se repartan entre las vueltas.

🗣️ **2 minutos.** El `while` de dentro puede hacer `n` vueltas en una sola iteración del `for`, pero entonces vacía la pila, y esos índices ya no vuelven. Sumando sobre todo el recorrido, el número de vueltas del `while` es el número de desapilados, que no pasa de `n`. Con el método del potencial, `Φ = tamaño de la pila` da el mismo resultado ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

🔬 **El detalle.** El argumento falla si un elemento puede volver a entrar: por eso la versión circular (dos vueltas) es `O(2n)` y no más.

**01 → 6.** ¿Cómo cambia la plantilla para obtener «el anterior menor» en lugar del «siguiente mayor»? 🟡

⏱️ **30 segundos.** Recorriendo de izquierda a derecha y sacando mientras la cima sea `≥ a[i]`: lo que queda en la cima tras sacar es el anterior menor de `i`.

🗣️ **2 minutos.** La pila guarda, de abajo arriba, valores estrictamente crecientes. Al llegar `a[i]`, se sacan los mayores o iguales, que no pueden ser «anterior menor» de nadie posterior porque `a[i]` es menor o igual y está más cerca. La cima, si existe, es el anterior estrictamente menor. Después se apila `i`.

🔬 **El detalle.** Las cuatro variantes salen de dos decisiones: el sentido del recorrido y el sentido de la comparación. En cada pasada se puede calcular a la vez el «siguiente» de los que salen y el «anterior» del que entra.

**01 → 7.** En la cola monótona, ¿por qué se puede descartar un índice cuando llega otro posterior con valor menor o igual? 🟡

⏱️ **30 segundos.** Porque el posterior está en todas las ventanas futuras en las que esté el anterior, y es menor o igual: el anterior no será nunca el mínimo de una ventana que aún no se ha calculado.

🗣️ **2 minutos.** Sean `j < i` con `a[i] ≤ a[j]`. Toda ventana futura empieza después de la actual y acaba en `i` o más tarde: si contiene a `j`, contiene también a `i`. Su mínimo es entonces `≤ a[i] ≤ a[j]`, y si hay empate basta con `i`. Así que `j` puede descartarse sin perder ninguna respuesta.

🔬 **El detalle.** El argumento usa que las ventanas avanzan: si una consulta futura pudiera acabar antes de `i`, descartar `j` sería un error. Por eso la cola monótona no sirve para rangos arbitrarios.

**01 → 8.** ¿Qué diferencia hay entre usar `<` y `<=` en la pila monótona con valores repetidos? Da un ejemplo. 🟠

⏱️ **30 segundos.** Con `<` se busca el siguiente **estrictamente** mayor; con `<=`, el siguiente mayor **o igual**. En `[2, 2, 3]`, el siguiente estrictamente mayor del primer 2 es el 3 (índice 2); el siguiente mayor o igual es el otro 2 (índice 1).

🗣️ **2 minutos.** Con `<=`, el segundo 2 saca al primero de la pila y se le anota como respuesta. En los problemas de contribuciones (en cuántos subarreglos es cada elemento el mínimo), usar `<` en un sentido y `<=` en el otro es lo que evita contar dos veces los subarreglos con mínimos repetidos.

🔬 **El detalle.** Muchos WA de este tipo de problema son exactamente esto: los ejemplos no tienen repetidos y el caso 7 sí.

**01 → 9.** Compara `Stack`, `ArrayDeque` y `LinkedList` como pila en Java, y `list` y `deque` en Python. 🟠

⏱️ **30 segundos.** Java: `ArrayDeque` es la buena; `Stack` sincroniza y hereda de `Vector`; `LinkedList` crea un nodo por elemento. Python: `list` es una buena pila; `deque` también, y además es una buena cola.

🗣️ **2 minutos.** `Stack` funciona, pero cada operación adquiere un cerrojo y su API mezcla operaciones de lista que rompen la abstracción de pila. `LinkedList` tiene `O(1)` en los extremos, pero con una asignación por elemento y mala localidad ([`02/05`](../02-analisis/05-el-coste-real.md)). `ArrayDeque` es un arreglo circular: rápido y compacto. En Python, `list.append/pop` son `O(1)` amortizado; `deque` es casi igual de rápido como pila y además ofrece `popleft`.

🔬 **El detalle.** La documentación de `Stack` recomienda expresamente usar `Deque` en su lugar.

**01 → 10.** Calcula el anterior y el siguiente menor de cada barra del histograma `[3, 1, 3, 2, 2]`, y con ellos el mayor rectángulo. 🟠

⏱️ **30 segundos.** Anterior estrictamente menor: `[−1, −1, 1, 1, 1]`; siguiente estrictamente menor: `[1, 5, 3, 5, 5]`. Áreas `h[i] · (R[i] − L[i] − 1)`: `[3, 5, 3, 6, 6]`. El mayor rectángulo es 6.

🗣️ **2 minutos.** Para cada barra, el rectángulo más ancho de su altura se extiende hasta justo antes de la primera barra menor por cada lado. La barra 1 (altura 1) se extiende a todo el histograma: `1 · 5 = 5`. Las barras 3 y 4 (altura 2) van de la posición 2 a la 4: `2 · 3 = 6`.

🔬 **El detalle.** Con dos barras iguales, las dos calculan el mismo rectángulo: no importa para el máximo, pero sí cuando se cuentan rectángulos o subarreglos.

**01 → 11.** ¿Cómo implementas una cola que dé su mínimo en `O(1)` usando dos pilas? 🟠

⏱️ **30 segundos.** Dos pilas que guardan, junto a cada valor, el mínimo de la pila hasta ese punto: se mete en la de entrada y se saca de la de salida; si la de salida está vacía, se vuelca la de entrada. El mínimo es el menor de los dos mínimos de las cimas.

🗣️ **2 minutos.** Una pila con mínimo es fácil: cada elemento guarda `min(valor, mínimo de debajo)`. La cola se simula con dos pilas: la de salida tiene los más antiguos en la cima. Volcar invierte el orden y recalcula los mínimos. Cada elemento se vuelca una sola vez: `O(1)` amortizado por operación (`02/03`).

🔬 **El detalle.** La cola monótona da el mínimo de una ventana con más sencillez; la de dos pilas sirve también cuando los elementos salen sin que la «ventana» sea un rango de índices.

**01 → 12.** ¿Cómo construye una pila monótona el árbol cartesiano de un arreglo en `O(n)`, y qué tiene que ver ese árbol con el mínimo de un rango? 🔴

⏱️ **30 segundos.** Recorriendo de izquierda a derecha con una pila que guarda la rama derecha del árbol: cada nuevo elemento saca los mayores, el último sacado pasa a ser su hijo izquierdo, y él pasa a ser hijo derecho de la nueva cima. En el árbol cartesiano, el mínimo de `[l, r]` es el ancestro común más bajo de `l` y `r`.

🗣️ **2 minutos.** El árbol cartesiano de mínimos tiene la raíz en el mínimo del arreglo, el subárbol izquierdo construido con lo que queda a la izquierda y el derecho con lo de la derecha. La pila monótona lo construye en `Θ(n)` con el mismo argumento de entrada y salida. Como el mínimo de un rango es el primer nodo que lo separa, el RMQ se reduce a LCA ([`07/05`](../07-arboles/05-lca.md)); el árbol cartesiano tiene su capítulo en [`09/06`](../09-consultas-sobre-rangos/06-arbol-cartesiano-y-wavelet.md).

🔬 **El detalle.** Es la base de la reducción RMQ ↔ LCA que da consultas `O(1)` tras un preproceso lineal (Bender y Farach-Colton); en concurso, la tabla dispersa ([`09/01`](../09-consultas-sobre-rangos/01-sparse-table.md)) es más simple.

**01 → 13.** ¿Cómo calculas el máximo de cada submatriz `k × k` de una matriz `R × C` combinando colas monótonas, y con qué coste? 🔴

⏱️ **30 segundos.** Primero, el máximo de cada ventana de ancho `k` en cada fila; después, sobre esa matriz, el máximo de cada ventana de alto `k` en cada columna. `Θ(R · C)`.

🗣️ **2 minutos.** El máximo de una submatriz `k × k` es el máximo de los máximos de sus `k` filas recortadas a las `k` columnas. La primera pasada (colas monótonas por filas) da `R × (C − k + 1)` valores en `Θ(R · C)`; la segunda (por columnas) da `(R − k + 1) × (C − k + 1)` en `Θ(R · C)`.

🔬 **El detalle.** La misma descomposición vale para sumas (con prefijos 2D, [`04/05`](../04-secuencias/05-matrices.md)) y para cualquier operación asociativa con ventana deslizante.

**01 → Problema: Etiquetas bien anidadas.**

- **Pista 2 — patrón:** **pila** de nombres abiertos.
- **Pista 3 — diseño:** apila cada apertura; ante un cierre, la pila no puede estar vacía y la cima debe tener el mismo nombre; si falla, esa posición. Al final, si quedan abiertas, `n + 1`.

**01 → Problema: Recuento de dominados.**

- **Pista 2 — patrón:** **siguiente mayor o igual** con pila monótona.
- **Pista 3 — diseño:** la cuenta de `i` para en el primer `j > i` con `a[j] ≥ a[i]`; la respuesta es `j − i − 1`, o `n − i − 1` si no hay. La plantilla con `<=` como condición de salida.

**01 → Problema: Mínimos con ventana elástica.**

- **Pista 2 — patrón:** **cola monótona** con los dos extremos avanzando.
- **Pista 3 — diseño:** mantén la deque de índices con valores crecientes; para cada consulta, mete por detrás los índices hasta `r` (sacando los mayores o iguales) y saca por delante con un `while` los menores que `l`. El frente es el mínimo. Cada índice entra y sale una vez: `O(n + q)`.

**01 → Problema: Valid Parentheses.**

- **Pista 2 — patrón:** **pila** de aperturas.
- **Pista 3 — diseño:** apila cada apertura; con un cierre, comprueba que la cima es su pareja y desapila; al final, la pila debe estar vacía.

**01 → Problema: Nesting.**

- **Pista 2 — patrón:** **contador** en lugar de pila.
- **Pista 3 — diseño:** con un solo tipo de paréntesis, la pila solo necesita su tamaño: suma con `(`, resta con `)`, falla si baja de 0, y al final debe ser 0.

**01 → Problema: Evaluate Reverse Polish Notation.**

- **Pista 2 — patrón:** **pila de operandos**.
- **Pista 3 — diseño:** apila los números; con un operador, desapila dos (el primero que sale es el operando derecho), opera y apila el resultado. La división trunca hacia cero.

**01 → Problema: Asteroid Collision.**

- **Pista 2 — patrón:** **pila** de los que siguen vivos.
- **Pista 3 — diseño:** un asteroide hacia la izquierda solo choca con los de la cima que van hacia la derecha; mientras la cima sea positiva y menor en tamaño, desapila; si son iguales, desaparecen los dos; si la cima es mayor, el nuevo desaparece.

**01 → Problema: Next Greater Element II.**

- **Pista 2 — patrón:** **pila monótona** con dos vueltas.
- **Pista 3 — diseño:** recorre los índices `0..2n−1` usando `i mod n`; apila solo en la primera vuelta; en la segunda, solo resuelves los que siguen esperando.

**01 → Problema: Remove K Digits.**

- **Pista 2 — patrón:** **pila monótona voraz**.
- **Pista 3 — diseño:** mientras queden borrados y la cima sea mayor que el dígito actual, desapila; al final, si quedan borrados, quítalos del final; elimina los ceros iniciales y devuelve `"0"` si queda vacío.

**01 → Problema: Longest Continuous Subarray With Absolute Diff Less Than or Equal to Limit.**

- **Pista 2 — patrón:** **ventana variable** con **dos colas monótonas** (máximo y mínimo).
- **Pista 3 — diseño:** amplía por la derecha actualizando las dos deques; mientras `max − min > limit`, avanza la izquierda y saca de cada deque el frente si quedó fuera. La longitud máxima de la ventana es la respuesta.

**01 → Problema: Car Fleet.**

- **Pista 2 — patrón:** **ordenar** por posición y comparar **tiempos de llegada**.
- **Pista 3 — diseño:** ordena de más cerca a más lejos de la meta; calcula el tiempo de cada coche; un coche forma flota nueva si su tiempo es mayor que el de la flota de delante (el máximo visto); si no, se une a ella.

**01 → Problema: 132 Pattern.**

- **Pista 2 — patrón:** **pila monótona de derecha a izquierda** que guarda el mejor «2».
- **Pista 3 — diseño:** recorre de derecha a izquierda con una pila decreciente; al sacar los menores que el actual, el mayor de ellos es el mejor «2» para un «3» igual al actual; si en algún momento el actual es menor que ese «2», hay patrón.

**01 → Problema: Trapping Rain Water.**

- **Pista 2 — patrón:** **pila monótona** (por capas) o **dos punteros** con los máximos.
- **Pista 3 — diseño:** con dos punteros, avanza el lado con el máximo menor: el agua sobre esa posición es `maxLado − altura`, porque el otro lado tiene seguro una pared al menos igual de alta.

**01 → Problema: Maximal Rectangle.**

- **Pista 2 — patrón:** **histograma por filas** y el mayor rectángulo con pila monótona.
- **Pista 3 — diseño:** para cada fila, la altura de cada columna es el número de unos consecutivos que acaban en ella; aplica el mayor rectángulo del histograma a cada fila. `O(R · C)`.

**01 → Problema: Shortest Subarray with Sum at Least K.**

- **Pista 2 — patrón:** **cola monótona sobre los prefijos**.
- **Pista 3 — diseño:** con prefijos `P`, para cada `j` busca el mayor `i < j` con `P[j] − P[i] ≥ K`; mantén una deque de índices con `P` creciente: saca por delante mientras se cumpla (anotando la longitud), y por detrás los `P ≥ P[j]`.

**01 → Problema: Poisonous Plants.**

- **Pista 2 — patrón:** **pila** que guarda, con cada planta, el día en que muere.
- **Pista 3 — diseño:** recorre de izquierda a derecha; cada planta muere un día después del máximo de los días de muerte de las plantas que saca (las de la cima con pesticida mayor o igual); si la pila queda vacía, no muere. La respuesta es el mayor día de muerte.

---

# 02 — Listas enlazadas

**02 → 1.** ¿Qué es un nodo centinela y qué casos especiales elimina? 🟢

⏱️ **30 segundos.** Un nodo ficticio delante de la cabeza. Hace que todo nodo real tenga un anterior, así que borrar la cabeza, insertar delante o construir una lista desde cero no son casos especiales.

🗣️ **2 minutos.** Sin centinela, cada función que puede cambiar la cabeza necesita un `if` para ese caso y devolver la cabeza nueva con cuidado. Con él, se opera siempre sobre `prev.next` y se devuelve `dummy.next`. En listas dobles se usan dos: cabeza y cola, y la lista vacía es «los dos centinelas enlazados entre sí».

🔬 **El detalle.** En C++ el centinela puede vivir en la pila de la función (`ListNode dummy(0)`), sin asignación ni liberación.

**02 → 2.** ¿Qué pasa si al invertir una lista cambias `cur.next` antes de guardarlo? 🟢

⏱️ **30 segundos.** Se pierde el resto de la lista: `cur.next` apunta ya a `prev` y no queda ninguna referencia al nodo que venía después.

🗣️ **2 minutos.** La inversión tiene que guardar el siguiente en una variable antes de reescribir el enlace. El orden correcto es: guardar `next`, apuntar `cur.next` a `prev`, avanzar `prev` a `cur`, avanzar `cur` al `next` guardado. Cualquier otro orden pierde nodos o crea un ciclo.

🔬 **El detalle.** En Java o Python, los nodos perdidos los recoge el recolector; en C++ quedan como fuga de memoria, además del resultado incorrecto.

**02 → 3.** ¿Cuándo es `O(1)` insertar en una lista enlazada y cuándo no? 🟢

⏱️ **30 segundos.** Es `O(1)` si ya tienes el nodo junto al que insertas (o el anterior, en una lista simple). Si hay que llegar a una posición, cuesta `O(n)` llegar.

🗣️ **2 minutos.** Insertar es cambiar dos punteros; encontrar el sitio es recorrer, y cada paso es un acceso disperso a memoria. Por eso un arreglo, que inserta desplazando en `O(n)` pero con copias contiguas muy rápidas, suele ganar en la práctica (`02/05`).

🔬 **El detalle.** La lista brilla cuando el nodo ya está a mano por otra vía: un mapa a nodos (la LRU), o un recorrido que va insertando donde está.

**02 → 4.** ¿Por qué el puntero rápido, al llegar al final, deja al lento en la mitad? ¿Qué devuelve con `n` par? 🟢

⏱️ **30 segundos.** Porque el rápido da dos pasos por cada uno del lento: cuando el rápido ha recorrido toda la lista, el lento ha recorrido la mitad. Con `n` par, la plantilla devuelve el primero de la segunda mitad.

🗣️ **2 minutos.** Tras `t` vueltas, el lento está en la posición `t` y el rápido en la `2t`. El bucle para cuando el rápido no puede avanzar dos más: `2t ≥ n − 1`. Con `n = 6`, para con `t = 3`, posición 3, el primero de la segunda mitad. Para el último de la primera mitad (útil para cortar), se empieza con el rápido en `head.next`.

🔬 **El detalle.** Para cortar la lista en dos para la mezcla, se necesita el nodo **anterior** a la segunda mitad, para poner su `next` a nulo.

**02 → 5.** ¿Por qué el lento y el rápido se encuentran si hay un ciclo, y en cuántos pasos como mucho? 🟡

⏱️ **30 segundos.** Porque, una vez los dos están en el ciclo, el rápido se acerca al lento un paso por vuelta: la distancia entre ellos baja de uno en uno hasta cero. Se encuentran en como mucho `μ + λ` pasos.

🗣️ **2 minutos.** El lento entra en el ciclo tras `μ` pasos. En ese momento, el rápido ya está dentro, a cierta distancia `d < λ` por detrás (en el sentido del recorrido). Cada vuelta la distancia baja en 1 (el rápido avanza 2, el lento 1), así que se encuentran en `d < λ` vueltas más. Total, menos de `μ + λ`.

🔬 **El detalle.** No pueden «saltarse»: como la distancia baja exactamente de 1 en 1, pasa por 0. Con velocidades 1 y 3, sí podrían cruzarse sin coincidir en algunos ciclos.

**02 → 6.** Explica las tres operaciones de la LRU y qué estructura hace cada una en `O(1)`. 🟡

⏱️ **30 segundos.** Buscar una clave (mapa *hash*), marcarla como la más reciente (mover su nodo al frente de la lista doble) y expulsar la menos reciente (quitar el último nodo de la lista). Todo `O(1)`.

🗣️ **2 minutos.** El mapa guarda, para cada clave, su nodo en la lista: así se llega al nodo en `O(1)` sin recorrer. La lista doble permite desenlazar un nodo del medio en `O(1)`, porque conoce el anterior y el siguiente. La expulsión necesita además quitar la clave del mapa: por eso el nodo guarda su clave.

🔬 **El detalle.** Con una lista simple no se puede desenlazar un nodo del medio sin su anterior; con una cola o un montículo no se puede mover un elemento arbitrario.

**02 → 7.** ¿Qué hace el tercer argumento `true` del constructor de `LinkedHashMap`? 🟡

⏱️ **30 segundos.** Activa el orden **de acceso**: cada `get` o `put` sobre una clave la mueve al final del orden de iteración. Sin él, el orden es el de inserción.

🗣️ **2 minutos.** Con orden de acceso, la primera entrada es siempre la usada hace más tiempo. `removeEldestEntry` se llama tras cada inserción con esa primera entrada; devolviendo `size() > cap`, el mapa la quita solo. Es la LRU completa en unas líneas.

🔬 **El detalle.** El ejemplo de la documentación de `LinkedHashMap` es exactamente una caché con `removeEldestEntry`. Con orden de acceso, hasta un `get` es una modificación estructural para los iteradores.

**02 → 8.** Demuestra que la fase 2 de Floyd termina exactamente en el inicio del ciclo. 🟠

⏱️ **30 segundos.** Se encuentran en un paso `t` múltiplo de `λ`. El lento está a `t − μ` del inicio del ciclo; avanzando `μ` más, estará a `t`, múltiplo de `λ`: en el inicio. El que sale del principio llega al inicio en esos mismos `μ` pasos.

🗣️ **2 minutos.** Para `t ≥ μ`, el lento está en `x_t` y el rápido en `x_{2t}`; coinciden si `t ≡ 2t (mod λ)`, es decir, `λ` divide a `t`. Desde el encuentro, tras `μ` pasos más el lento está en `x_{t+μ}`, y como `t` es múltiplo de `λ`, `x_{t+μ} = x_μ`. El otro puntero, desde `x₀`, está en `x_μ` tras `μ` pasos. Coinciden ahí; antes no pueden coincidir, porque el que viene de `x₀` aún está en la cola, fuera del ciclo.

🔬 **El detalle.** Si `μ = 0`, el encuentro de la fase 2 es inmediato: el principio ya es el inicio del ciclo.

**02 → 9.** Compara cómo escribes una LRU en C++, Java y Python con la biblioteca estándar. 🟠

⏱️ **30 segundos.** C++: `std::list` con `splice` más un `unordered_map` de clave a iterador. Java: `LinkedHashMap` con orden de acceso y `removeEldestEntry`. Python: `OrderedDict` con `move_to_end` y `popitem(last=False)`.

🗣️ **2 minutos.** C++ no tiene una LRU hecha, pero `splice` mueve un nodo dentro de la lista en `O(1)` sin invalidar el iterador guardado. En Java y Python, la estructura existe: es un mapa *hash* con una lista doble interna. En una entrevista conviene decir que existe y escribir también la versión a mano.

🔬 **El detalle.** `functools.lru_cache` memoriza llamadas a funciones con la misma política; no sirve como caché genérica de claves y valores.

**02 → 10.** ¿Cómo calculas la longitud del ciclo una vez encontrado su inicio? ¿Y con el algoritmo de Brent? 🟠

⏱️ **30 segundos.** Desde el inicio del ciclo (o desde el punto de encuentro), avanzar de uno en uno contando hasta volver: `λ` pasos. Brent da `λ` directamente: el puntero que espera se teletransporta en potencias de 2 y el número de pasos desde el último salto es `λ`.

🗣️ **2 minutos.** En Brent, un puntero se queda fijo y el otro avanza; cada vez que el número de pasos alcanza una potencia de 2, el fijo salta a la posición del que avanza y la cuenta se reinicia. Cuando el que avanza vuelve a encontrar al fijo, la cuenta desde el último salto es `λ`. Después, con dos punteros separados `λ` pasos que avanzan juntos desde el principio, se encuentra `μ`.

🔬 **El detalle.** Brent evalúa `f` en promedio menos veces que Floyd (unas 36 % menos, según el análisis de Brent), lo que importa cuando `f` es cara, como en la factorización rho de Pollard ([`17/04`](../17-matematica/04-primos.md)).

**02 → 11.** ¿Qué condición necesita una función `f` para que la secuencia `x, f(x), f(f(x)), …` tenga siempre un ciclo y Floyd termine? Da una `f` en la que no termina. 🟠

⏱️ **30 segundos.** Que `f` vaya de un conjunto **finito** en sí mismo: entonces algún valor se repite, y desde ahí la secuencia es periódica. Con `f(x) = x + 1` sobre los enteros, nunca se repite y Floyd no termina.

🗣️ **2 minutos.** Por el principio del palomar, entre `x₀, …, x_N` (con `N` el tamaño del conjunto) hay dos iguales; como cada valor determina el siguiente, a partir del primer repetido la secuencia cicla. Sobre un conjunto infinito no hay garantía.

🔬 **El detalle.** En una lista enlazada, el conjunto finito son los nodos más el `null`: si se llega a `null`, no hay ciclo y la plantilla lo detecta por la condición del bucle.

**02 → 12.** Diseña una lista doble sin punteros, con arreglos `next[]` y `prev[]`, y explica qué ganas. 🔴

⏱️ **30 segundos.** Arreglos `val[]`, `next[]` y `prev[]` indexados por el número de nodo, con un índice reservado (por ejemplo 0) como centinela. Se gana localidad de caché, cero asignaciones dinámicas y la posibilidad de copiar o reiniciar la estructura de golpe.

🗣️ **2 minutos.** Insertar el nodo `x` tras `p` es `next[x] = next[p]; prev[x] = p; prev[next[p]] = x; next[p] = x`, igual que con punteros. Los nodos se reservan de un arreglo preasignado. Con `n = 10⁶` nodos, se evitan `10⁶` asignaciones y los fallos de caché dispersos (`02/05`).

🔬 **El detalle.** Es la forma habitual en competición y la que usan los *dancing links*: quitar `x` es `next[prev[x]] = next[x]; prev[next[x]] = prev[x]`, y reponerlo es deshacer esas dos asignaciones porque `x` aún recuerda a sus vecinos.

**02 → 13.** Demuestra que la lista doble con dos centinelas de la LRU mantiene su invariante tras `get` y `put`, incluido un `put` de una clave que ya existe con la caché llena. 🔴

⏱️ **30 segundos.** Invariante: la lista entre los dos centinelas contiene exactamente las claves del mapa, sin repetir, ordenadas de la más reciente a la menos reciente, y su tamaño es como mucho la capacidad.

🗣️ **2 minutos.** `get` de una clave presente: desenlaza su nodo y lo enlaza tras la cabeza; el conjunto no cambia y el orden refleja el uso. `put` de una clave nueva con la caché llena: quita el nodo anterior a la cola y su clave del mapa, y enlaza el nuevo tras la cabeza; el tamaño queda en la capacidad. `put` de una clave existente: actualiza el valor y la mueve al frente, **sin** expulsar a nadie aunque la caché esté llena, porque el tamaño no crece.

🔬 **El detalle.** El error típico es expulsar antes de comprobar si la clave ya estaba: con la caché llena, se expulsa a otra clave sin necesidad.

**02 → Problema: El corro.**

- **Pista 2 — patrón:** **lista circular** con borrado, o un arreglo con el índice de la siguiente salida.
- **Pista 3 — diseño:** con `n ≤ 5000`, mantén los jugadores en una lista y el índice actual; el siguiente en salir está `(k − 1) mod tamaño` posiciones más allá; bórralo y sigue desde ahí. `O(n²)` desplazamientos, que entran.

**02 → Problema: Editor con cursor.**

- **Pista 2 — patrón:** **lista doble** con el cursor como nodo, o **dos pilas** (lo de la izquierda y lo de la derecha del cursor).
- **Pista 3 — diseño:** con dos pilas, escribir apila en la izquierda; `<` pasa la cima de la izquierda a la derecha; `>` al revés; `-` desapila de la izquierda. Al final, la izquierda en orden y la derecha invertida.

**02 → Problema: El bucle del generador.**

- **Pista 2 — patrón:** **Floyd** sobre la función `x ↦ (a x² + b) mod m`.
- **Pista 3 — diseño:** el producto necesita `__int128` en C++, `Math.multiplyHigh` o `BigInteger` en Java, o una multiplicación modular por partes. Fase 1 hasta el encuentro, fase 2 desde `x₀` contando `μ`, y una vuelta desde el inicio contando `λ`.

**02 → Problema: Middle of the Linked List.**

- **Pista 2 — patrón:** **lento y rápido**.
- **Pista 3 — diseño:** la plantilla tal cual: con `n` par, devuelve el primero de la segunda mitad, que es lo que pide el enunciado.

**02 → Problema: Palindrome Linked List.**

- **Pista 2 — patrón:** **punto medio**, **inversión** de la segunda mitad y comparación.
- **Pista 3 — diseño:** encuentra la mitad, invierte desde ahí, compara nodo a nodo con la primera mitad; si te piden no modificar la lista, vuelve a invertir al acabar.

**02 → Problema: Intersection of Two Linked Lists.**

- **Pista 2 — patrón:** **dos punteros que cambian de lista** al acabar la suya.
- **Pista 3 — diseño:** cada puntero recorre su lista y después la otra; los dos recorren `a + b` nodos y llegan a la vez al nodo común (o a `null` los dos).

**02 → Problema: Remove Nth Node From End of List.**

- **Pista 2 — patrón:** **dos punteros con separación fija** y centinela.
- **Pista 3 — diseño:** desde el centinela, adelanta el primero `n + 1` pasos; avanza los dos hasta que el primero sea `null`; el segundo está justo antes del que hay que borrar.

**02 → Problema: Reverse Linked List II.**

- **Pista 2 — patrón:** **inversión de un tramo** con centinela.
- **Pista 3 — diseño:** llega al nodo anterior al tramo; invierte `right − left` veces moviendo cada siguiente al frente del tramo; el anterior y el primer nodo original del tramo se reenganchan solos.

**02 → Problema: Reorder List.**

- **Pista 2 — patrón:** **mitad**, **inversión** y **mezcla alterna**.
- **Pista 3 — diseño:** corta por la mitad, invierte la segunda mitad y entrelaza un nodo de cada una.

**02 → Problema: Find the Duplicate Number.**

- **Pista 2 — patrón:** **Floyd** sobre la función `i ↦ nums[i]`.
- **Pista 3 — diseño:** con valores en `[1, n]` y `n + 1` posiciones, la secuencia desde el índice 0 entra en un ciclo; el inicio del ciclo es un valor al que apuntan dos índices: el duplicado. Las dos fases de la plantilla.

**02 → Problema: Copy List with Random Pointer.**

- **Pista 2 — patrón:** **mapa de original a copia**, o copias intercaladas.
- **Pista 3 — diseño:** con mapa: primera pasada crea las copias; segunda enlaza `next` y `random` consultando el mapa. Sin memoria extra: inserta cada copia tras su original, enlaza los `random` y separa las dos listas.

**02 → Problema: Odd Even Linked List.**

- **Pista 2 — patrón:** **dos listas** que se construyen a la vez y se unen.
- **Pista 3 — diseño:** dos punteros, `odd` y `even`, que saltan de dos en dos; guarda la cabeza de los pares y engánchala al final de los impares.

**02 → Problema: Add Two Numbers.**

- **Pista 2 — patrón:** **recorrido paralelo con acarreo** y centinela.
- **Pista 3 — diseño:** mientras quede algún nodo o acarreo, suma los dígitos disponibles más el acarreo, crea el nodo con la unidad y lleva la decena.

**02 → Problema: Rotate List.**

- **Pista 2 — patrón:** **cerrar en anillo y cortar**.
- **Pista 3 — diseño:** calcula la longitud `n` y `k mod n`; une el último con la cabeza; avanza `n − k` nodos desde la cabeza, corta tras el último de ellos; el siguiente es la cabeza nueva.

**02 → Problema: Flatten a Multilevel Doubly Linked List.**

- **Pista 2 — patrón:** **lista múltiple** recorrida con una **pila** de continuaciones.
- **Pista 3 — diseño:** al encontrar un nodo con hijo, apila su `next`, enlaza el hijo como siguiente (y su `prev`) y pon el hijo a nulo; al llegar al final de una sublista, desapila y engancha.

**02 → Problema: Reverse Nodes in k-Group.**

- **Pista 2 — patrón:** **inversión por tramos** con centinela.
- **Pista 3 — diseño:** comprueba que quedan `k` nodos; invierte el tramo; engancha el anterior al tramo con la nueva cabeza y la vieja cabeza (ahora final) con el resto; el final del tramo es el «anterior» del siguiente.

**02 → Problema: LFU Cache.**

- **Pista 2 — patrón:** **listas por frecuencia** y mapa a nodos.
- **Pista 3 — diseño:** un mapa de clave a nodo, un mapa de frecuencia a lista doble (en orden de uso dentro de la frecuencia) y la frecuencia mínima; al usar una clave, pásala a la lista de `f + 1`, y si la de `f` era la mínima y queda vacía, sube la mínima. La expulsión quita el último de la lista mínima.

---

# 03 — Tablas hash por dentro y los *anti-hash tests*

**03 → 1.** ¿Qué es una colisión, y cuáles son las dos formas de resolverlas? 🟢

⏱️ **30 segundos.** Dos claves distintas que caen en la misma cubeta. Se resuelven por encadenamiento (una lista por cubeta) o por direccionamiento abierto (buscar otra cubeta libre según una secuencia de sondeo).

🗣️ **2 minutos.** Las colisiones son inevitables: hay más claves posibles que cubetas. El encadenamiento es simple y tolera factores de carga altos; el direccionamiento abierto guarda todo en un arreglo, con mejor localidad, pero se degrada rápido al llenarse y complica el borrado.

🔬 **El detalle.** C++ y Java encadenan; Python usa direccionamiento abierto con una secuencia de sondeo que mezcla los bits altos del *hash* (la perturbación).

**03 → 2.** ¿Qué es el factor de carga, y qué valor por defecto usa Java? 🟢

⏱️ **30 segundos.** El número de elementos por cubeta, `α = n / m`. Java usa 0,75 por defecto.

🗣️ **2 minutos.** El coste esperado de las operaciones crece con `α`. Mantenerlo acotado, creciendo la tabla cuando lo supera, es lo que da el `O(1)` esperado. 0,75 es un compromiso entre memoria y longitud de las cadenas.

🔬 **El detalle.** C++ usa `max_load_factor() = 1,0` por defecto y Python redimensiona el `dict` al llenarse en 2/3.

**03 → 3.** ¿Por qué hay que redefinir `hashCode` cuando se redefine `equals`? 🟢

⏱️ **30 segundos.** Porque la tabla busca primero por `hashCode` (la cubeta) y después por `equals`: dos objetos iguales con *hash* distinto caen en cubetas distintas y la tabla no los ve como la misma clave.

🗣️ **2 minutos.** El contrato es: si `a.equals(b)`, entonces `a.hashCode() == b.hashCode()`. Con el `hashCode` heredado de `Object` (basado en la identidad), dos objetos iguales tienen *hash* distinto: `contains` devuelve `false` para un objeto igual al que se metió, y se acumulan duplicados.

🔬 **El detalle.** Los `record` de Java generan `equals` y `hashCode` coherentes. En Python, definir `__eq__` sin `__hash__` deja la clase sin *hash* (no se puede usar como clave), que es un error más visible.

**03 → 4.** ¿Por qué el caso peor de una tabla *hash* es `Θ(n)` por operación? 🟡

⏱️ **30 segundos.** Porque nada impide que todas las claves caigan en la misma cubeta: entonces cada operación recorre una cadena (o una secuencia de sondeo) de longitud `n`.

🗣️ **2 minutos.** El `O(1)` es un resultado sobre la **distribución** de las claves (o sobre la elección aleatoria de la función). Para una función fija y conocida, existe una entrada que la hace degenerar, y un adversario puede construirla.

🔬 **El detalle.** En Java, con claves comparables, la cubeta se convierte en árbol y el peor caso baja a `O(log n)`.

**03 → 5.** ¿Por qué el *rehash* es `O(1)` amortizado si copia toda la tabla? 🟡

⏱️ **30 segundos.** Porque la capacidad se duplica: entre dos *rehash* hay tantas inserciones como elementos se copiaron. El total de copias tras `n` inserciones es menor que `2n`.

🗣️ **2 minutos.** Las copias son `1 + 2 + 4 + … + n/2 < n` (con el umbral en `α = 1`), una suma geométrica. Repartida entre las `n` inserciones, cada una paga `O(1)`. Con crecimiento en una cantidad fija, la suma sería aritmética y el total cuadrático (`02/03`).

🔬 **El detalle.** La inserción que dispara el *rehash* sí cuesta `Θ(n)`: si importa la latencia de cada operación (tiempo real), hay *rehash* incremental, que mueve unas pocas claves por operación.

**03 → 6.** ¿Por qué en direccionamiento abierto no se puede borrar dejando un hueco? 🟡

⏱️ **30 segundos.** Porque el hueco cortaría la secuencia de sondeo de otras claves: una búsqueda posterior pararía en el hueco y no encontraría claves que están más allá.

🗣️ **2 minutos.** Con sondeo lineal, una clave puede estar varias posiciones después de su cubeta porque las anteriores estaban ocupadas. Si se borra una de esas intermedias dejando el hueco, la búsqueda de la clave desplazada para antes de llegar. Se usan lápidas (marcas de «borrado» que la búsqueda salta y la inserción reutiliza), o se recolocan las claves siguientes del grupo.

🔬 **El detalle.** Con muchas lápidas, la tabla se llena de basura y hay que reconstruirla; por eso las implementaciones cuentan lápidas en el factor de carga.

**03 → 7.** ¿Qué cambió en el `HashMap` de Java 8 para las cubetas con muchas colisiones, y qué garantiza? 🟡

⏱️ **30 segundos.** Desde Java 8, una cubeta con más de 8 claves (si la tabla tiene al menos 64 cubetas) se convierte en un árbol rojinegro. Con claves comparables, el peor caso por operación baja de `O(n)` a `O(log n)`.

🗣️ **2 minutos.** El cambio responde a los ataques de colisiones (por ejemplo, con cadenas cuyos `hashCode` coinciden, fáciles de fabricar). El árbol ordena por `hashCode` y, si las claves implementan `Comparable`, por `compareTo`. Si la tabla es pequeña, primero crece en lugar de convertir.

🔬 **El detalle.** Con claves no comparables y *hash* idénticos, el árbol no puede decidir el lado y la búsqueda recorre ambos: vuelve a ser lineal.

**03 → 8.** Demuestra que, bajo *hash* uniforme simple, una búsqueda sin éxito con encadenamiento cuesta `Θ(1 + α)` esperado. 🟠

⏱️ **30 segundos.** La clave buscada cae en una cubeta uniforme; la longitud esperada de cualquier cubeta es `n/m = α`; recorrerla y calcular `h` cuesta `1 + α`.

🗣️ **2 minutos.** Sea `nⱼ` la longitud de la cubeta `j`; `Σ nⱼ = n`, así que `E[nⱼ] = α` bajo *hash* uniforme simple. Una búsqueda sin éxito de `k` calcula `h(k)` (`Θ(1)`) y recorre la cubeta entera: `E[n_{h(k)}] = α`. Total `Θ(1 + α)`. CLRS, 3.ª ed., teorema 11.1.

🔬 **El detalle.** La búsqueda con éxito cuesta `1 + α/2 − α/(2n)` comparaciones esperadas (teorema 11.2): en promedio se recorre la mitad de la cadena anterior al elemento.

**03 → 9.** Explica cómo se construye un *anti-hash test* contra `unordered_map` de libstdc++ con enteros. 🟠

⏱️ **30 segundos.** `std::hash` de un entero es la identidad y la cubeta es `x mod m`, con `m` de una lista fija de primos. Se insertan muchos múltiplos de uno de esos primos: caen todos en la cubeta 0.

🗣️ **2 minutos.** El atacante calcula, para el tamaño de la entrada, qué número de cubetas alcanzará la tabla (la política de crecimiento es conocida) y genera múltiplos de ese primo. Cada inserción recorre la cadena entera: `Θ(n²)` para `n` inserciones, TLE con `n ≈ 10⁵`. Como la tabla pasa por varios tamaños, se elige el primo del tamaño final o se combinan.

🔬 **El detalle.** La defensa es un *hash* con semilla aleatoria (`splitmix64` con el reloj), o usar `std::map` con `O(log n)` garantizado.

**03 → 10.** Compara cómo se protegen de una entrada adversaria `unordered_map`, `HashMap` y `dict`, y qué haces en cada lenguaje. 🟠

⏱️ **30 segundos.** `unordered_map` no se protege: hace falta un *hash* propio con semilla. `HashMap` limita el daño con árboles si las claves son comparables. `dict` aleatoriza las cadenas pero no los enteros.

🗣️ **2 minutos.** En C++, `unordered_map<K, V, SafeHash>`. En Java, con `Long` o `String` el árbol da `O(log n)`, que suele bastar; si no, mezclar las claves con una semilla antes de usarlas. En Python, con enteros adversarios, usar `x ^ R` con `R` aleatorio como clave, o pasar a cadena.

🔬 **El detalle.** En los tres, la alternativa sin aleatoriedad es el mapa ordenado: `O(log n)` en el peor caso, que con `n = 2·10⁵` sobra.

**03 → 11.** ¿Por qué se mezcla la clave antes de quedarse con sus bits bajos cuando la capacidad es potencia de 2? 🟠

⏱️ **30 segundos.** Porque con capacidad potencia de 2, la cubeta son los bits bajos de la clave. Si las claves solo difieren en los bits altos (múltiplos de `2¹⁰`, por ejemplo), caerían todas en la misma cubeta.

🗣️ **2 minutos.** Una máscara `& (m − 1)` descarta todos los bits altos. Mezclar (multiplicar por una constante impar grande y bajar los bits altos con un *xor*) hace que cada bit de la clave afecte a los bits bajos. Java hace `h ^ (h >>> 16)` por esa razón.

🔬 **El detalle.** Con `mod p` para un primo `p`, la mezcla importa menos, pero `mod` es más lento que una máscara; las tablas modernas prefieren potencia de 2 con mezcla.

**03 → 12.** ¿Qué es una familia universal de funciones de *hash*, y por qué elegir la función al azar al ejecutar protege de cualquier entrada? 🔴

⏱️ **30 segundos.** Una familia `H` en la que, para dos claves distintas cualesquiera, la probabilidad de que una función elegida al azar de `H` las haga colisionar es como mucho `1/m`. Como la función se elige al ejecutar, después de fijada la entrada, ninguna entrada es mala en esperanza.

🗣️ **2 minutos.** Con una familia universal, la longitud esperada de la cubeta de cualquier clave es `≤ 1 + α`, para **toda** entrada, porque la esperanza es sobre la elección de la función. El adversario conoce la familia pero no la función elegida. Ejemplo clásico: `h(x) = ((a x + b) mod p) mod m` con `p` primo y `a, b` aleatorios.

🔬 **El detalle.** CLRS, 3.ª ed., §11.3.3. `splitmix64` con semilla no es una familia universal demostrada, pero en la práctica cumple el mismo papel; el análisis formal es de [`19/02`](../19-aleatorizados-y-probabilisticos/02-hashing-universal-y-analisis-esperado.md).

**03 → 13.** ¿Qué es el agrupamiento primario del sondeo lineal, y por qué aun así suele ser más rápido que el encadenamiento en la práctica? 🔴

⏱️ **30 segundos.** Las claves se agrupan en tramos ocupados contiguos, y cualquier clave que caiga en un tramo lo alarga: los tramos largos crecen más deprisa. Aun así, recorrer un tramo contiguo en un arreglo es muy rápido por la caché, mientras que una cadena son saltos dispersos.

🗣️ **2 minutos.** Por eso el sondeo lineal pide factores de carga bajos (`≤ 0,5`–`0,7`): con ellos, las búsquedas recorren uno o dos huecos de un bloque de caché. El encadenamiento tolera `α = 1` o más, pero cada nodo es una asignación y un fallo de caché posible (`02/05`).

🔬 **El detalle.** Variantes como el *Robin Hood hashing* reducen la varianza de las distancias de sondeo, y muchas tablas de alto rendimiento (por ejemplo, las de tipo *Swiss table*) son de direccionamiento abierto.

**03 → Problema: Votos repetidos.**

- **Pista 2 — patrón:** **contador con tabla *hash***.
- **Pista 3 — diseño:** un mapa de identificador a cuenta; recorre al final buscando la mayor cuenta y, a igualdad, el menor identificador. En C++ con semilla aleatoria si temes un ataque; identificadores en 64 bits.

**03 → Problema: Matrículas en las dos listas.**

- **Pista 2 — patrón:** **conjunto** de la segunda lista y **conjunto** de las ya impresas.
- **Pista 3 — diseño:** mete la segunda lista en un conjunto; recorre la primera e imprime las que estén en él y no estén en el conjunto de impresas, añadiéndolas.

**03 → Problema: Distintos por ventana.**

- **Pista 2 — patrón:** **contador en una ventana deslizante** ([`04/02`](../04-secuencias/02-dos-punteros-y-ventana.md)).
- **Pista 3 — diseño:** al entrar un valor, si su cuenta pasa de 0 a 1, suma un distinto; al salir, si baja de 1 a 0, resta uno (y borra la clave o deja el 0). `O(n)` esperado.

**03 → Problema: Ransom Note.**

- **Pista 2 — patrón:** **contador de letras**.
- **Pista 3 — diseño:** 26 contadores con las letras de la revista; resta las de la nota; si alguno baja de 0, no se puede.

**03 → Problema: Isomorphic Strings.**

- **Pista 2 — patrón:** **dos mapas**, uno en cada sentido.
- **Pista 3 — diseño:** para cada posición, comprueba que `s[i]` se asigna siempre a `t[i]` y que `t[i]` viene siempre de `s[i]`; un solo mapa permitiría que dos letras distintas fueran a la misma.

**03 → Problema: Brick Wall.**

- **Pista 2 — patrón:** **contar posiciones de juntas**.
- **Pista 3 — diseño:** para cada fila, acumula los anchos (sin el último ladrillo) y cuenta cada posición en un mapa; la respuesta es el número de filas menos la mayor cuenta.

**03 → Problema: 4Sum II.**

- **Pista 2 — patrón:** **encuentro en el medio** con un mapa de sumas.
- **Pista 3 — diseño:** cuenta en un mapa todas las sumas `a + b`; para cada `c + d`, suma la cuenta de `−(c + d)`. `O(n²)` esperado.

**03 → Problema: Insert Delete GetRandom O(1).**

- **Pista 2 — patrón:** **mapa de valor a índice** en un arreglo.
- **Pista 3 — diseño:** el arreglo guarda los valores y el mapa su posición; para borrar, mueve el último al hueco, actualiza su índice en el mapa y quita el último. `getRandom` elige un índice al azar.

**03 → Problema: Frequency Queries.**

- **Pista 2 — patrón:** **dos mapas**: valor a frecuencia y frecuencia a número de valores.
- **Pista 3 — diseño:** al insertar o borrar, actualiza la frecuencia del valor y mueve una unidad de la cuenta de la frecuencia vieja a la nueva; la consulta mira si la cuenta de `f` es positiva.

**03 → Problema: Registration System.**

- **Pista 2 — patrón:** **mapa de cadena a contador**.
- **Pista 3 — diseño:** si el nombre no está, `OK` y cuenta 0; si está, incrementa su cuenta e imprime el nombre seguido de la cuenta.

**03 → Problema: Valid Sudoku.**

- **Pista 2 — patrón:** **conjuntos** por fila, columna y caja.
- **Pista 3 — diseño:** la caja de `(i, j)` es `(i / 3) · 3 + j / 3`; para cada cifra, comprueba y marca en sus tres conjuntos (o en tres arreglos de 9×9 booleanos).

**03 → Problema: Contiguous Array.**

- **Pista 2 — patrón:** **prefijos** y **primera aparición** de cada valor de prefijo en un mapa.
- **Pista 3 — diseño:** con 0 → −1, un tramo equilibrado tiene suma 0: dos prefijos iguales. Guarda el primer índice de cada prefijo (con el prefijo 0 en el índice −1) y maximiza la distancia.

**03 → Problema: Powers of Two.**

- **Pista 2 — patrón:** **contar complementos** con un mapa.
- **Pista 3 — diseño:** recorre el arreglo; para cada elemento y cada potencia `2ᵏ` hasta `2³¹`, suma cuántos anteriores valen `2ᵏ − a[i]`; después cuenta el actual. Respuesta en 64 bits; en C++, con *hash* propio, porque el problema es atacable.

**03 → Problema: Count Triplets.**

- **Pista 2 — patrón:** **dos mapas** recorridos de izquierda a derecha: valores vistos y pares pendientes.
- **Pista 3 — diseño:** para cada `x`, suma los pares que esperan a `x` como tercer término (`pares[x]`); añade a `pares[x · r]` los vistos con valor `x / r` (si `x` es divisible); añade `x` a vistos. Cuentas en 64 bits.

---

# 04 — Hashing de secuencias

**04 → 1.** ¿Cómo se calcula el *hash* de `s[l, r)` a partir de los prefijos? 🟢

⏱️ **30 segundos.** `H(s[l, r)) = (P[r] − P[l] · b^{r−l}) mod p`, con `P` los *hashes* de los prefijos y las potencias de `b` precalculadas.

🗣️ **2 minutos.** `P[r]` es el *hash* de `s[0, r)`, que contiene el de `s[0, l)` multiplicado por `b^{r−l}` (desplazado `r − l` posiciones) más el de `s[l, r)`. Restando, queda el de la subcadena. Es la misma idea que las sumas de prefijos ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)), con un desplazamiento.

🔬 **El detalle.** En aritmética modular, la resta puede dar negativo: se suma `p` antes de reducir.

**04 → 2.** ¿Por qué ningún carácter debe valer 0 en el *hash* polinomial? 🟢

⏱️ **30 segundos.** Porque un carácter 0 a la izquierda no cambia el *hash*: `"a"` y `"\0a"` darían lo mismo, igual que `07` y `7` en decimal.

🗣️ **2 minutos.** El *hash* es un número en base `b`; los ceros a la izquierda no cuentan. Si se compara solo subcadenas de la misma longitud, el problema no aparece, pero codificando cada carácter como `c + 1` (o desde 1) se evita del todo.

🔬 **El detalle.** También hay que elegir la base mayor que el mayor código de carácter, para que dos caracteres distintos no se confundan en una posición.

**04 → 3.** ¿Qué diferencia hay entre un *hash* Zobrist con *xor* y uno de multiconjunto con suma? 🟢

⏱️ **30 segundos.** El *xor* solo registra si un elemento está un número impar de veces (presencia); la suma registra cuántas veces está (multiplicidad).

🗣️ **2 minutos.** Con *xor*, añadir y quitar son la misma operación, perfecto para un tablero donde las piezas aparecen y desaparecen. Con suma, `{x, x}` da `2·r[x]`, distinto de `{}`: sirve para comparar multiconjuntos de subarreglos con prefijos.

🔬 **El detalle.** Las dos son conmutativas: el orden de los elementos no afecta, que es justo lo que se busca en conjuntos y multiconjuntos.

**04 → 4.** ¿Por qué la base tiene que ser aleatoria? 🟡

⏱️ **30 segundos.** Porque con una base fija y conocida, un adversario puede buscar dos cadenas distintas con el mismo *hash* y meterlas en la entrada. Con base aleatoria, la cota de probabilidad vale para cualquier entrada.

🗣️ **2 minutos.** La cota `(L − 1)/p` del teorema es una probabilidad sobre la elección de la base. Si la base es fija, no hay nada aleatorio: o colisionan o no, y alguien puede elegir que sí. Al elegir la base al ejecutar, después de fijada la entrada, el adversario no puede apuntar a las raíces del polinomio diferencia.

🔬 **El detalle.** En Codeforces con *hacks* esto es literal: hay soluciones atacadas por usar la base 31 o 131 fija.

**04 → 5.** Con `10⁵` *hashes* en un conjunto y `p = 10⁹ + 7`, ¿cuántas colisiones esperas? Justifica con la paradoja del cumpleaños. 🟡

⏱️ **30 segundos.** Unas 5: el número esperado de pares que colisionan es `≈ n² / (2p) = 10¹⁰ / (2 · 10⁹) = 5`.

🗣️ **2 minutos.** Hay `n(n−1)/2 ≈ 5·10⁹` pares, y cada uno colisiona con probabilidad `≈ 1/p`. Por linealidad de la esperanza, `≈ 5` colisiones. Para bajar a una probabilidad pequeña de **alguna** colisión hace falta `p ≫ n²`: con `n = 10⁵`, `p ≫ 10¹⁰`, es decir, `2⁶¹ − 1` o doble módulo.

🔬 **El detalle.** Es la paradoja del cumpleaños: con 23 personas y 365 días, la probabilidad de que dos compartan cumpleaños pasa de 1/2.

**04 → 6.** ¿Qué hace Rabin-Karp y cómo consigue un resultado exacto? 🟡

⏱️ **30 segundos.** Busca un patrón en un texto comparando el *hash* del patrón con el de cada ventana del texto, que se actualiza en `O(1)`. Es exacto si, cuando los *hashes* coinciden, se comparan los caracteres.

🗣️ **2 minutos.** El *hash* de la ventana `[i + 1, i + m + 1)` sale del de `[i, i + m)` quitando el primer carácter (multiplicado por `b^{m−1}`), multiplicando por `b` y sumando el nuevo. Con verificación en cada coincidencia, los falsos positivos se descartan; el coste esperado sigue siendo `O(n + m)` porque los falsos positivos son raros.

🔬 **El detalle.** En el caso peor (muchas coincidencias reales, como buscar `aaa` en `aaaa…`), verificar cada una cuesta `O(n · m)`; KMP no tiene ese caso.

**04 → 7.** Demuestra que dos cadenas distintas de longitud `L` colisionan con probabilidad `≤ (L − 1)/p` si la base es aleatoria. 🟠

⏱️ **30 segundos.** `H(s) − H(t)` es un polinomio no nulo en `b` de grado `≤ L − 1` sobre `ℤ_p`, que tiene como mucho `L − 1` raíces; la base aleatoria es una raíz con probabilidad `≤ (L − 1)/p`.

🗣️ **2 minutos.** Los coeficientes del polinomio son `s[i] − t[i]`; como `s ≠ t`, alguno es no nulo (y, al ser menor que `p` en valor absoluto, no nulo módulo `p`). En un cuerpo, un polinomio no nulo de grado `d` tiene a lo sumo `d` raíces (factor teorema). Colisión ⇔ `b` es raíz. Con `b` uniforme en `ℤ_p`: `≤ (L − 1)/p`.

🔬 **El detalle.** Hace falta que `p` sea primo para que `ℤ_p` sea un cuerpo; con `2⁶⁴` no lo es, y la cota no vale.

**04 → 8.** ¿Por qué el módulo `2⁶¹ − 1` permite reducir con desplazamientos, y por qué el producto cabe en 128 bits? 🟠

⏱️ **30 segundos.** Porque `2⁶¹ ≡ 1 (mod 2⁶¹ − 1)`: los bits por encima del 61 se pueden sumar a los de abajo. Y el producto de dos valores menores que `2⁶¹` es menor que `2¹²²`, que cabe en 128 bits.

🗣️ **2 minutos.** Si `x = alto · 2⁶¹ + bajo`, entonces `x ≡ alto + bajo`. Con `x < 2¹²²`, `alto < 2⁶¹` y la suma es menor que `2⁶²`: una resta condicional la deja en rango. Sin divisiones, que son lo más lento de la aritmética entera.

🔬 **El detalle.** `2⁶¹ − 1` es un primo de Mersenne; con `2⁶⁴` no se puede reducir así y además no es primo.

**04 → 9.** Compara cómo calculas `a · b mod (2⁶¹ − 1)` en C++, Java y JavaScript. 🟠

⏱️ **30 segundos.** C++: `__uint128_t` para el producto y la reducción con desplazamientos. Java: `Math.multiplyHigh` (Java 9+) para los 64 bits altos y la misma reducción. JavaScript: `BigInt`, o partir los factores en trozos que quepan en 53 bits.

🗣️ **2 minutos.** En C++, `__uint128_t` es una extensión de GCC y Clang, disponible en los jueces habituales. En Java no hay entero de 128 bits, pero `multiplyHigh` y el producto normal dan las dos mitades. En JavaScript, los `Number` son `double` con 53 bits exactos: un producto de 61 × 61 bits se pierde; `BigInt` es exacto pero lento.

🔬 **El detalle.** Con doble módulo de `≈ 10⁹`, los productos caben en 64 bits en C++ y Java, pero en JavaScript (`10¹⁸ > 2⁵³`) siguen sin caber en un `Number`.

**04 → 10.** ¿Por qué el módulo `2⁶⁴` es atacable para cualquier base, y por qué no lo es la suma de valores aleatorios? 🟠

⏱️ **30 segundos.** Con módulo `2⁶⁴`, para cualquier base las cadenas de Thue–Morse de longitud suficiente colisionan, porque la estructura polinomial se anula en potencias altas de 2. La suma de valores aleatorios no es un polinomio en una base: no hay estructura que explotar.

🗣️ **2 minutos.** El ataque construye dos cadenas cuya diferencia de *hashes* es un producto de muchos factores `(b^{2ᵏ} − 1)`, cada uno par para `b` impar; el producto acumula tantos factores 2 que se anula módulo `2⁶⁴` (para `b` par, `b⁶⁴ ≡ 0` y es aún más fácil). En la suma de valores aleatorios, la diferencia de dos multiconjuntos es una combinación de valores independientes y uniformes, que es 0 con probabilidad despreciable.

🔬 **El detalle.** Por eso el *hash* polinomial necesita un módulo primo, y el de multiconjuntos puede desbordar libremente.

**04 → 11.** ¿Cómo decides, con prefijos de *hash* de multiconjunto, si `a[l..r]` es una permutación de `1..(r − l + 1)`? 🟠

⏱️ **30 segundos.** Con `r[v]` aleatorio por valor, prefijos `pre[i] = Σ r[a[j]]` para `j < i`, y `E[k] = r[1] + … + r[k]`; `a[l..r]` es permutación si `pre[r + 1] − pre[l] = E[r − l + 1]`.

🗣️ **2 minutos.** El multiconjunto de `a[l..r]` es `{1, …, k}` si y solo si sus *hashes* coinciden, salvo colisión (probabilidad despreciable con 64 bits). `pre` y `E` se calculan en `O(n)`, y cada consulta es `O(1)`.

🔬 **El detalle.** Una alternativa determinista combina el máximo del rango (tabla dispersa) con «sin repetidos en el rango», pero es más larga de escribir.

**04 → 12.** Con `Q = 10⁶` comparaciones de subcadenas de longitud `10⁵`, ¿qué módulo necesitas para una probabilidad de error menor que `10⁻⁶`? 🔴

⏱️ **30 segundos.** La unión de sucesos da `Q · (L − 1)/p < 10⁻⁶`, es decir, `p > 10⁶ · 10⁵ · 10⁶ = 10¹⁷`. `2⁶¹ − 1 ≈ 2,3·10¹⁸` lo cumple (`≈ 4·10⁻⁸`); un módulo de `10⁹`, no.

🗣️ **2 minutos.** Cada comparación falla con probabilidad `≤ (L − 1)/p`; la probabilidad de que falle alguna es como mucho la suma. Con `p = 10⁹ + 7`, la cota es 100: no garantiza nada. Con doble módulo de `≈ 10⁹` cada uno y bases independientes, la cota por comparación es `(L/p)² ≈ 10⁻⁸` y la total `≈ 10⁻²`, insuficiente para `10⁻⁶`.

🔬 **El detalle.** La cota `(L − 1)/p` es pesimista: en la práctica las colisiones son mucho más raras, pero la cota es lo que se puede demostrar.

**04 → 13.** ¿Cómo combinas *hash* y búsqueda binaria para comparar lexicográficamente dos subcadenas en `O(log n)`? 🔴

⏱️ **30 segundos.** Binaria sobre la longitud del prefijo común: la mayor `k` con `H(s[i, i+k)) = H(s[j, j+k))`; después se compara el carácter siguiente. `O(log n)` comparaciones de *hash*.

🗣️ **2 minutos.** El predicado «los prefijos de longitud `k` coinciden» es monótono (si coinciden en `k`, coinciden en todo `k' < k`), así que vale la binaria de [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md). Con el prefijo común `k`, el orden lo decide `s[i + k]` frente a `s[j + k]`, o la longitud si uno se acaba.

🔬 **El detalle.** Es la pieza de la rotación mínima (comparar rotaciones de `s + s`) y de ordenar sufijos con *hash* en `O(n log² n)`; los arreglos de sufijos ([`16/06`](../16-cadenas/06-suffix-array-y-automaton.md)) lo hacen sin probabilidad.

**04 → Problema: Subcadenas iguales.**

- **Pista 2 — patrón:** **hash polinomial con prefijos**.
- **Pista 3 — diseño:** la plantilla de §3 con `2⁶¹ − 1`; cada consulta compara `get(l₁, r₁ + 1)` con `get(l₂, r₂ + 1)`. Lectura rápida para `2·10⁵` consultas.

**04 → Problema: ¿Es una permutación?.**

- **Pista 2 — patrón:** **hash de multiconjunto** con prefijos.
- **Pista 3 — diseño:** valores aleatorios `r[1..n]`, prefijos de `r[a[i]]` y prefijos `E[k] = r[1] + … + r[k]`; cada consulta compara `pre[r+1] − pre[l]` con `E[r − l + 1]`, todo en 64 bits sin signo.

**04 → Problema: Tableros repetidos.**

- **Pista 2 — patrón:** **Zobrist** con un conjunto de estados vistos.
- **Pista 3 — diseño:** un valor aleatorio de 64 bits por casilla; cada jugada hace *xor* con el de su casilla; guarda los *hashes* vistos (empezando por 0) y para en el primero repetido. Con `10⁶` jugadas, un conjunto *hash* de enteros.

**04 → Problema: Find the Index of the First Occurrence in a String.**

- **Pista 2 — patrón:** **Rabin-Karp** con verificación.
- **Pista 3 — diseño:** *hash* del patrón y ventana deslizante sobre el texto; en cada coincidencia de *hash*, compara los caracteres; devuelve el primer índice.

**04 → Problema: String Matching.**

- **Pista 2 — patrón:** **Rabin-Karp** o KMP.
- **Pista 3 — diseño:** con prefijos de *hash* del texto y el *hash* del patrón, cuenta las posiciones con *hash* igual; con `2⁶¹ − 1`, sin verificación, el riesgo es despreciable.

**04 → Problema: Repeated DNA Sequences.**

- **Pista 2 — patrón:** **hash exacto de ventana** en un conjunto.
- **Pista 3 — diseño:** con 2 bits por letra, una ventana de 10 letras cabe en 20 bits: el *hash* es exacto. Desliza con desplazamiento y máscara; cuenta en un mapa y devuelve las que aparecen más de una vez.

**04 → Problema: Finding Borders.**

- **Pista 2 — patrón:** **comparar prefijo y sufijo** de cada longitud con *hash*.
- **Pista 3 — diseño:** para cada `k` de 1 a `n − 1`, compara `H(s[0, k))` con `H(s[n−k, n))`; imprime las `k` que coinciden. `O(n)`.

**04 → Problema: Sherlock and Anagrams.**

- **Pista 2 — patrón:** **firma de multiconjunto** de cada subcadena.
- **Pista 3 — diseño:** para cada subcadena, su firma es el vector de 26 cuentas (o la cadena ordenada); cuenta firmas en un mapa y suma `c(c − 1)/2` por firma. Con `n ≤ 100`, `O(n² · 26)` basta.

**04 → Problema: Good Substrings.**

- **Pista 2 — patrón:** **subcadenas distintas** con *hash* en un conjunto.
- **Pista 3 — diseño:** para cada inicio, extiende mientras el número de letras malas no pase de `k`, añadiendo el *hash* de cada subcadena a un conjunto; con `≈ 10⁶` *hashes*, módulo `2⁶¹ − 1` (el cumpleaños con `10⁹` daría colisiones).

**04 → Problema: Watto and Mechanism.**

- **Pista 2 — patrón:** **hash con un cambio** en `O(1)`.
- **Pista 3 — diseño:** guarda los *hashes* de las cadenas iniciales en un conjunto; para cada consulta y cada posición `i`, prueba los otros dos caracteres sumando `(c' − c) · b^{L−1−i}` al *hash*. Base aleatoria: el problema tiene tests contra bases fijas.

**04 → Problema: Finding Periods.**

- **Pista 2 — patrón:** **comparar la cadena con su desplazamiento**.
- **Pista 3 — diseño:** `p` es un periodo si `s[0, n − p) = s[p, n)`; compara los dos *hashes* para cada `p` de 1 a `n`.

**04 → Problema: Minimal Rotation.**

- **Pista 2 — patrón:** **comparación lexicográfica** con *hash* y binaria sobre `s + s`.
- **Pista 3 — diseño:** recorre las `n` rotaciones guardando la mejor; compara cada una con la mejor en `O(log n)` con el prefijo común más largo. `O(n log n)`. Hay algoritmos lineales (Booth, Duval), pero este basta.

**04 → Problema: Compress Words.**

- **Pista 2 — patrón:** **solapamiento sufijo-prefijo** con *hash*.
- **Pista 3 — diseño:** para cada palabra nueva de longitud `L`, mira solo los últimos `min(L, |res|)` caracteres del resultado; busca la mayor `k` con sufijo del resultado igual a prefijo de la palabra comparando *hashes*; añade lo que sobra. Mantén los prefijos de *hash* del resultado según crece.

**04 → Problema: Distinct Echo Substrings.**

- **Pista 2 — patrón:** **comparar mitades** con *hash*, y un conjunto de resultados.
- **Pista 3 — diseño:** para cada inicio `i` y cada mitad `k`, compara `H(s[i, i+k))` con `H(s[i+k, i+2k))`; si coinciden, añade el *hash* de la mitad a un conjunto. `O(n²)` comparaciones.

---

# 05 — Simulación

**05 → S1.** ¿Qué usarías como cola en Java y en Python, y por qué no `LinkedList` ni `list`? 🟢

⏱️ **30 segundos.** Java: `ArrayDeque`. Python: `collections.deque`. `LinkedList` crea un nodo por elemento y `list.pop(0)` es `O(n)`.

🗣️ **2 minutos.** `ArrayDeque` es un arreglo circular con `offer`/`poll` en `O(1)` amortizado y buena localidad. `LinkedList` también es `O(1)`, pero con una asignación y un fallo de caché posible por elemento. En Python, `list` desplaza todo al quitar del principio; `deque` no.

🔬 **El detalle.** [`06/01`](01-pilas-colas-y-monotonas.md), §3.

**05 → S2.** ¿Por qué la pila monótona es lineal aunque tenga un `while` dentro de un `for`? 🟡

⏱️ **30 segundos.** Porque cada índice se apila una vez y se desapila como mucho una vez: el `while` hace, en total, como mucho `n` vueltas en todo el recorrido.

🗣️ **2 minutos.** Es un análisis agregado: no se acota el `while` en cada vuelta del `for`, sino su suma, que es el número de desapilados. Con el potencial `Φ = tamaño de la pila`, cada operación cuesta `O(1)` amortizado (`02/03`).

🔬 **El detalle.** `06/01`, §2.

**05 → S3.** ¿Cuándo usas una cola monótona en lugar de una pila monótona? 🟡

⏱️ **30 segundos.** Cuando la consulta es sobre una ventana que avanza (los elementos «caducan» por la izquierda): la cola monótona saca por delante los que salen de la ventana. La pila monótona es para «el siguiente o el anterior» sin límite de distancia.

🗣️ **2 minutos.** Las dos descartan los elementos que ya no pueden ser respuesta. La diferencia es la caducidad: en una ventana de tamaño `k`, un elemento deja de valer al salir de ella, aunque siga siendo el mejor; eso exige sacar por el otro extremo.

🔬 **El detalle.** `06/01`, §5.

**05 → S4.** ¿Para qué sirve el nodo centinela? 🟢

⏱️ **30 segundos.** Para que todo nodo real tenga un anterior: borrar o insertar en la cabeza deja de ser un caso especial y se devuelve `dummy.next`.

🗣️ **2 minutos.** Sin centinela, cada manipulación que puede cambiar la cabeza necesita un `if` y cuidado con lo que se devuelve. Con él, el código es uniforme. En listas dobles, dos centinelas (cabeza y cola) simplifican también el final.

🔬 **El detalle.** [`06/02`](02-listas-enlazadas.md), §2.

**05 → S5.** ¿Cómo encuentra Floyd el inicio de un ciclo? 🟡

⏱️ **30 segundos.** Lento y rápido hasta encontrarse dentro del ciclo; después uno vuelve al principio y los dos avanzan de uno en uno: se encuentran en el inicio del ciclo.

🗣️ **2 minutos.** El primer encuentro ocurre en un paso `t` múltiplo de la longitud del ciclo. Desde ahí, el lento necesita `μ` pasos (la longitud de la cola) para llegar al inicio, los mismos que el que sale del principio. Memoria `O(1)`.

🔬 **El detalle.** `06/02`, §2 y §4; la prueba completa es la S18.

**05 → S6.** ¿Qué dos estructuras forman una LRU y qué aporta cada una? 🟢

⏱️ **30 segundos.** Un mapa *hash* de clave a nodo, que encuentra en `O(1)`, y una lista doblemente enlazada, que mueve un nodo al frente y quita el último en `O(1)`.

🗣️ **2 minutos.** El mapa sin la lista no sabe cuál es la menos reciente; la lista sin el mapa tiene que recorrerse para encontrar una clave. Juntos, las dos operaciones son `O(1)`. En Java, `LinkedHashMap` con orden de acceso; en Python, `OrderedDict`.

🔬 **El detalle.** `06/02`, §5.

**05 → S7.** ¿Qué significa que una tabla *hash* sea `O(1)` «esperado»? 🟡

⏱️ **30 segundos.** Que el promedio del coste, sobre la distribución de las claves o sobre la elección aleatoria de la función, es constante. Una entrada concreta puede costar `Θ(n)` por operación.

🗣️ **2 minutos.** Bajo *hash* uniforme simple, la longitud esperada de una cubeta es `α`, acotado por la política de crecimiento. Pero «esperado» no es «siempre»: con una función fija, un adversario puede meter todo en una cubeta.

🔬 **El detalle.** [`06/03`](03-tablas-hash.md), §2.

**05 → S8.** ¿Por qué el *rehash* no estropea el `O(1)`? 🟢

⏱️ **30 segundos.** Porque la capacidad se duplica: las copias totales tras `n` inserciones son menos de `2n`, `O(1)` amortizado por inserción.

🗣️ **2 minutos.** La inserción que dispara el *rehash* cuesta `Θ(n)`, pero ocurre cada vez más espaciada. Sumando, `1 + 2 + 4 + …` es geométrica. Si se conoce `n`, `reserve` lo evita del todo.

🔬 **El detalle.** `06/03`, §4.

**05 → S9.** ¿Qué pasa si una clase redefine `equals` pero no `hashCode`? 🟢

⏱️ **30 segundos.** Dos objetos iguales tienen *hash* distinto (el de la identidad), caen en cubetas distintas, y la tabla no los reconoce como la misma clave: `contains` falla y se acumulan duplicados.

🗣️ **2 minutos.** El contrato exige que objetos iguales tengan el mismo *hash*. La tabla compara con `equals` solo dentro de la cubeta, así que si la cubeta es otra, `equals` ni se llama.

🔬 **El detalle.** Un `record` genera los dos de forma coherente; en Python, definir `__eq__` sin `__hash__` deja la clase sin *hash*.

**05 → S10.** ¿Por qué la base del *hash* polinomial se elige al azar? 🟡

⏱️ **30 segundos.** Para que la probabilidad de colisión sea pequeña para cualquier entrada: con base fija, un adversario puede elegir cadenas que colisionen.

🗣️ **2 minutos.** La cota `(L − 1)/p` es una probabilidad sobre la base. Elegida al ejecutar, después de fijada la entrada, el adversario no puede apuntar a las raíces del polinomio diferencia.

🔬 **El detalle.** [`06/04`](04-hashing-de-secuencias.md), §2.

**05 → S11.** ¿Qué módulo usarías para meter `10⁶` *hashes* de subcadenas en un conjunto, y por qué? 🟡

⏱️ **30 segundos.** `2⁶¹ − 1` (o doble módulo), con base aleatoria. Con `10⁹ + 7`, el cumpleaños da unas `n²/2p = 5·10²` colisiones esperadas.

🗣️ **2 minutos.** Con `n = 10⁶` *hashes*, hay `5·10¹¹` pares; con `p ≈ 10⁹`, cientos colisionan. Con `p ≈ 2,3·10¹⁸`, el número esperado baja a `≈ 2·10⁻⁷`.

🔬 **El detalle.** `06/04`, §2 y §4.

**05 → S12.** ¿Qué diferencia hay entre un *hash* Zobrist y uno de multiconjunto? 🟢

⏱️ **30 segundos.** Zobrist combina con *xor* (registra presencia: añadir y quitar son lo mismo); el de multiconjunto suma (registra multiplicidades).

🗣️ **2 minutos.** Con *xor*, `{x, x}` y `{}` dan lo mismo; con suma, no. Zobrist es ideal para tableros que activan y desactivan; la suma, para comparar multiconjuntos de subarreglos con prefijos.

🔬 **El detalle.** `06/04`, §5.

**05 → S13.** Tu solución con `unordered_map` pasa en local y da TLE solo en el test 47 de Codeforces. ¿Qué ha pasado y qué cambias? 🟠

⏱️ **30 segundos.** Un caso preparado contra el *hash* por defecto: todas las claves en la misma cubeta y cada operación lineal. Cambio a un *hash* con semilla aleatoria (`splitmix64` con el reloj) o a `std::map`.

🗣️ **2 minutos.** En libstdc++, el *hash* de un entero es la identidad y las cubetas son un primo de una lista fija: el atacante genera múltiplos de ese primo. En local, con datos aleatorios, todo va bien. La semilla aleatoria hace que cada ejecución use una función distinta.

🔬 **El detalle.** `06/03`, §5.

**05 → S14.** «La lista enlazada es mejor que el arreglo para insertar en el medio.» ¿Qué le respondes al entrevistador? 🟠

⏱️ **30 segundos.** Que insertar es `O(1)` solo si ya tienes el nodo; llegar a la posición es `O(n)` de saltos dispersos en memoria, y un arreglo, que desplaza con copias contiguas, suele ganar en la práctica.

🗣️ **2 minutos.** La complejidad asintótica de «buscar e insertar» es `O(n)` en los dos. La diferencia está en la constante: la copia contigua de un arreglo es muy rápida, y el recorrido de una lista falla en la caché casi en cada nodo (`02/05`). La lista gana cuando el nodo ya está a mano, como en la LRU.

🔬 **El detalle.** Es la respuesta que espera un entrevistador senior: ni «la lista siempre» ni «el arreglo siempre», sino dónde está el coste.

**05 → S15.** Tu *hash* de subcadenas con base 31 y módulo `10⁹ + 7` falla en un caso enorme y pasa los pequeños. ¿Por qué, y qué cambias? 🟠

⏱️ **30 segundos.** Por colisiones: con muchos *hashes* y `p ≈ 10⁹`, el cumpleaños las hace probables, y con base fija el caso puede estar preparado. Cambio a módulo `2⁶¹ − 1` con base aleatoria.

🗣️ **2 minutos.** En los casos pequeños hay pocos *hashes* y las colisiones son improbables; en el enorme, con `10⁵`–`10⁶` *hashes*, se esperan varias. Además, la base 31 es conocida: un caso de prueba puede contener dos cadenas que colisionan a propósito.

🔬 **El detalle.** Un truco de depuración: si al cambiar de módulo cambia el veredicto, era una colisión.

**05 → S16.** Te piden «el máximo de cada ventana» y escribes una pila monótona. ¿Qué falla? 🟠

⏱️ **30 segundos.** La pila no puede sacar por el fondo los elementos que salen de la ventana: el máximo «caducado» se queda y se sigue respondiendo con él.

🗣️ **2 minutos.** La pila monótona responde «el siguiente mayor» sin límite de distancia. En una ventana, el elemento más antiguo sale aunque sea el mejor; eso exige acceso por el otro extremo: una deque.

🔬 **El detalle.** Con una deque, los que salen de la ventana se quitan por delante y los dominados por detrás.

**05 → S17.** «Uso `HashMap<int[], Integer>` para contar arreglos repetidos y no cuenta nada.» ¿Por qué? 🟠

⏱️ **30 segundos.** Porque los arreglos de Java usan `equals` y `hashCode` de identidad: dos arreglos con el mismo contenido son claves distintas.

🗣️ **2 minutos.** `int[]` no redefine `equals` ni `hashCode`. Hay que usar como clave algo con igualdad por contenido: `List<Integer>` (`Arrays.asList` sobre `Integer[]`), una cadena, un `record` que envuelva el arreglo con `Arrays.equals`/`Arrays.hashCode`, o un *hash* propio.

🔬 **El detalle.** En Python pasa lo contrario: las listas no se pueden usar como clave (no tienen *hash*); se convierten a `tuple`.

**05 → S18.** Demuestra que, tras el encuentro de Floyd, avanzar desde el principio y desde el encuentro a la vez acaba en el inicio del ciclo. 🔴

⏱️ **30 segundos.** El encuentro es en un paso `t` múltiplo de `λ`; desde ahí, `μ` pasos más dejan al lento en `x_{t+μ} = x_μ`, el inicio del ciclo, y el que sale de `x₀` llega a `x_μ` en esos mismos `μ` pasos.

🗣️ **2 minutos.** Para `t ≥ μ`, el lento está en `x_t` y el rápido en `x_{2t}`; coinciden si `λ` divide a `t`. Como `x_{i+λ} = x_i` para `i ≥ μ`, `x_{t+μ} = x_μ`. El otro puntero recorre la cola y llega a `x_μ` en `μ` pasos. Antes no pueden coincidir: el que viene de `x₀` está en la cola, fuera del ciclo.

🔬 **El detalle.** `06/02`, pregunta 8.

**05 → S19.** ¿Por qué una familia universal de funciones de *hash* protege de cualquier entrada, y una función fija no? 🔴

⏱️ **30 segundos.** Porque la probabilidad de colisión es sobre la elección de la función, que se hace después de fijada la entrada: para cualquier par de claves es `≤ 1/m`. Con una función fija no hay nada aleatorio y el adversario puede elegir claves que colisionan.

🗣️ **2 minutos.** Con una familia universal, la longitud esperada de cualquier cubeta es `≤ 1 + α` para **toda** entrada, porque la esperanza recorre las funciones de la familia. El adversario conoce la familia, no la función elegida.

🔬 **El detalle.** `06/03`, pregunta 12; el análisis formal es de `19/02`.

**05 → Problema: Torres en círculo.**

- **Pista 2 — patrón:** **pila monótona circular** con dos vueltas.
- **Pista 3 — diseño:** recorre los índices `0..2n−1` con `i mod n`; apila solo en la primera vuelta; al sacar un índice `j` con el índice actual `i`, su distancia es `i − j`. Los que queden sin respuesta tras las dos vueltas, `-1`.

**05 → Problema: Caché de miniaturas.**

- **Pista 2 — patrón:** **LRU**: mapa a nodos y lista doble, contando los fallos.
- **Pista 3 — diseño:** con `LinkedHashMap` en orden de acceso, `OrderedDict` o `std::list` con `splice`; cada petición ausente suma un fallo, se inserta y, si se pasa de `C`, se expulsa la menos reciente.

**05 → Problema: Pares de suma exacta.**

- **Pista 2 — patrón:** **contar complementos** con una tabla *hash* con semilla aleatoria.
- **Pista 3 — diseño:** para cada `a[j]`, suma cuántos anteriores valen `S − a[j]` y después cuenta `a[j]`; en C++, `unordered_map` con `splitmix64` y semilla del reloj; el resultado en 64 bits. Alternativa sin *hash*: ordenar y dos punteros contando bloques de iguales.

**05 → Problema: Primera letra repetida.**

- **Pista 2 — patrón:** **arreglo de 26 casillas**.
- **Pista 3 — diseño:** un arreglo de 26 booleanos; recorre la cadena y para en la primera letra ya marcada.

**05 → Problema: Happy Number.**

- **Pista 2 — patrón:** **ciclo de una función iterada** (Floyd o un conjunto).
- **Pista 3 — diseño:** la suma de los cuadrados de los dígitos es una función sobre un conjunto finito a partir del primer paso; aplica Floyd y comprueba si el ciclo es el del 1.

**05 → Problema: Word Pattern.**

- **Pista 2 — patrón:** **biyección** con dos mapas.
- **Pista 3 — diseño:** comprueba que hay tantas palabras como letras; para cada posición, la letra se asigna siempre a la misma palabra y la palabra viene siempre de la misma letra.

**05 → Problema: Minimum Add to Make Parentheses Valid.**

- **Pista 2 — patrón:** **contador** de abiertos pendientes.
- **Pista 3 — diseño:** suma con `(` y resta con `)`; si va a bajar de 0, cuenta un `(` añadido y no bajes; al final, suma los abiertos que quedan.

**05 → Problema: Partition List.**

- **Pista 2 — patrón:** **dos listas con centinela** y unión.
- **Pista 3 — diseño:** reparte los nodos en «menores que `x`» y «el resto» conservando el orden; une la primera con la segunda y pon a nulo el `next` del último.

**05 → Problema: Decode String.**

- **Pista 2 — patrón:** **pila** de (cadena acumulada, repeticiones).
- **Pista 3 — diseño:** al ver `[`, apila la cadena actual y el número leído y empieza una nueva; al ver `]`, desapila y concatena la anterior con la actual repetida.

**05 → Problema: Max Chunks To Make Sorted II.**

- **Pista 2 — patrón:** **pila monótona** de máximos de trozo.
- **Pista 3 — diseño:** recorre guardando en la pila el máximo de cada trozo; si llega un valor menor que la cima, fusiona trozos sacando mientras la cima sea mayor que él y vuelve a apilar el máximo de la fusión. La respuesta es el tamaño de la pila.
