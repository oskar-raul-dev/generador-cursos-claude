# Respuestas — bloque 03: Biblioteca estándar

> Solucionario del bloque `03`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--c-contenedores-de-la-stl-y-su-coste) · [02](#02--c-algoritmos-ranges-y-ordered_set) · [03](#03--java-las-colecciones-para-competir-y-sus-trampas) · [04](#04--python-collections-heapq-bisect-itertools-recursión-y-pypy) · [05](#05--la-tabla-de-equivalencias) · [06](#06--competir-sin-arsenal-go-y-javascript) · [07](#07--simulación)

---

# 01 — C++: contenedores de la STL y su coste

**01 → 1.** ¿Qué estructura de datos hay debajo de `std::map` y debajo de `std::unordered_map`, y qué coste tiene cada una? 🟢

⏱️ **30 segundos.** Debajo de `std::map` hay un árbol rojo-negro: `O(log n)` por operación en el caso peor. Debajo de `std::unordered_map`, una tabla *hash* con encadenamiento: `O(1)` esperado y `O(n)` en el caso peor.

🗣️ **2 minutos.** El árbol mantiene las claves ordenadas, y eso permite recorrerlas en orden y preguntar por sucesores y rangos. La tabla *hash* reparte las claves por cubetas sin orden, y por eso es más rápida en el caso típico pero no responde nada que dependa del orden.

🔬 **El detalle.** El estándar no obliga a un árbol rojo-negro, pero sí a las complejidades y a la estabilidad de iteradores que solo un árbol balanceado da; libstdc++, libc++ y la de MSVC usan rojo-negro. La teoría del árbol está en [`07/02`](../07-arboles/02-bst-y-balanceados.md) y la de la tabla en [`06/03`](../06-lineales-y-hashing/03-tablas-hash.md).

**01 → 2.** ¿Qué diferencia hay entre `ms.erase(5)` y `ms.erase(ms.find(5))` en un `multiset`? 🟢

⏱️ **30 segundos.** `ms.erase(5)` borra **todas** las copias de 5 y devuelve cuántas; `ms.erase(ms.find(5))` borra **una**, la que apunta el iterador.

🗣️ **2 minutos.** Son dos sobrecargas con semánticas distintas: por clave y por posición. En un `set` dan el mismo resultado porque no hay repetidos; en un `multiset`, no. Y `ms.erase(ms.find(5))` con 5 ausente es comportamiento indefinido, porque `find` devuelve `end()`: hay que comprobar antes.

🔬 **El detalle.** El patrón seguro es `auto it = ms.find(x); if (it != ms.end()) ms.erase(it);`. Es la autopsia de §4 del capítulo y el bug clásico de la taquilla.

**01 → 3.** ¿Cómo se declara un montículo de mínimos con `std::priority_queue`? 🟢

⏱️ **30 segundos.** `std::priority_queue<T, std::vector<T>, std::greater<>> heap;`: el tercer parámetro invierte el orden y deja el menor arriba.

🗣️ **2 minutos.** Por defecto la comparación es `std::less`, y el montículo deja arriba el mayor. Para cambiarla hay que dar también el contenedor, porque los parámetros de plantilla van en orden. `std::greater<>` (sin tipo, desde C++14) deduce los tipos al comparar.

🔬 **El detalle.** La alternativa sin tocar la plantilla es meter los valores negados y negarlos al sacar, que funciona con números pero no con pares mezclados ni con valores que desbordan al negar (`INT_MIN`).

**01 → 4.** ¿Qué diferencia hay entre `reserve` y `resize` en un `vector`? 🟡

⏱️ **30 segundos.** `reserve(n)` solo asegura capacidad para `n` elementos sin cambiar el tamaño; `resize(n)` cambia el tamaño, creando o destruyendo elementos.

🗣️ **2 minutos.** Tras `reserve(10)`, `size()` sigue siendo el de antes y `v[5]` es un acceso inválido; tras `resize(10)`, hay diez elementos inicializados y `v[5]` vale. `reserve` sirve para evitar copias en una serie de `push_back`; `resize`, para escribir por índice.

🔬 **El detalle.** El error típico es `reserve` seguido de escritura por índice: compila, a veces «funciona», y es comportamiento indefinido. Con `-fsanitize=address` se detecta.

**01 → 5.** ¿Qué diferencia hay entre el `lower_bound` miembro de un `set` y `std::lower_bound` aplicado a ese `set`? 🟡

⏱️ **30 segundos.** El miembro `s.lower_bound(x)` baja por el árbol en `O(log n)`; `std::lower_bound(s.begin(), s.end(), x)` es una búsqueda binaria genérica que, con iteradores que no son de acceso aleatorio, avanza paso a paso: `O(n)`.

🗣️ **2 minutos.** El algoritmo libre necesita saltar al medio de un rango, y los iteradores de un `set` solo avanzan de uno en uno. Hace `O(log n)` comparaciones pero `O(n)` avances. Con `10⁵` consultas sobre un `set` de `10⁵`, la diferencia es `10¹⁰` pasos: TLE.

🔬 **El detalle.** La regla es usar siempre el método miembro cuando el contenedor lo tiene (`lower_bound`, `find`, `count`). Sobre un `vector` ordenado, en cambio, el libre es lo correcto y es `O(log n)`.

**01 → 6.** ¿Qué operaciones de `vector` invalidan los iteradores, y por qué guardar un iterador antes de un `push_back` es peligroso? 🟡

⏱️ **30 segundos.** Toda operación que haga crecer la capacidad invalida todos los iteradores, punteros y referencias; insertar o borrar invalida los de esa posición en adelante. Un `push_back` puede reubicar el arreglo entero.

🗣️ **2 minutos.** Cuando el `vector` crece, reserva memoria nueva, mueve los elementos y libera la vieja: un iterador guardado apunta a memoria liberada. Si el `push_back` no tuvo que crecer, el iterador sigue valiendo, y por eso el error aparece solo a veces, según la capacidad del momento.

🔬 **El detalle.** El caso clásico es recorrer un `vector` con un iterador y hacer `push_back` dentro del bucle. Con índices en vez de iteradores el problema desaparece, porque el índice no depende de la dirección.

**01 → 7.** ¿Por qué consultar un `map` con `operator[]` puede cambiar el resultado de un programa? 🟠

⏱️ **30 segundos.** Porque `operator[]` inserta la clave con el valor por defecto si no existe: consultar llena el mapa de entradas, cambia su tamaño y, si después se recorre o se cuenta, cambia el resultado.

🗣️ **2 minutos.** `if (m[k] > 0)` parece una consulta, pero deja `k` con valor 0 en el mapa. Si el programa luego imprime `m.size()` o recorre las claves, aparecen claves que nunca se insertaron. En un mapa grande, además, cuesta memoria y tiempo.

🔬 **El detalle.** Para consultar: `m.find(k) != m.end()`, `m.count(k)` o `m.contains(k)` desde C++20. Y `operator[]` no se puede usar sobre un `const map`, precisamente porque puede modificarlo; ahí está `at(k)`, que lanza si no existe.

**01 → 8.** Compara el montículo de C++, Java y Python: ¿cuál da el máximo por defecto y cuál el mínimo, y cómo se consigue el otro en cada uno? 🟠

⏱️ **30 segundos.** C++ da el máximo por defecto; Java (`PriorityQueue`) y Python (`heapq`) dan el mínimo. En C++ se invierte con `std::greater<>`; en Java con `Comparator.reverseOrder()`; en Python negando las claves.

🗣️ **2 minutos.** Es la diferencia que más errores produce al traducir un Dijkstra de un lenguaje a otro: el mismo código sacaría el nodo más lejano. Además, `heapq` no es una clase sino funciones sobre una lista, y Java y C++ son clases con su comparador.

🔬 **El detalle.** En Python, negar funciona con números; con tuplas se niega el componente que ordena. Ninguno de los tres tiene `decrease-key`: los tres usan reinserción y eliminación perezosa. La tabla completa está en [`03/05`](05-equivalencias-entre-lenguajes.md).

**01 → 9.** Tu `unordered_map` da TLE solo en los últimos casos de un concurso con *hacks*. ¿Qué sospechas y por qué? 🟠

⏱️ **30 segundos.** Un caso anti-*hash*: claves elegidas para caer todas en la misma cubeta, que convierten cada operación en `O(n)`. El *hash* de enteros de libstdc++ es la identidad, y las cubetas son el valor módulo un primo conocido.

🗣️ **2 minutos.** Con *hacks*, otros participantes ven tu código y diseñan una entrada contra él. Elegir claves múltiplos del primo que usa la tabla para su número de cubetas mete todas las claves en una, y `10⁵` inserciones pasan a costar `10¹⁰`. Por eso el TLE aparece en los últimos casos, los añadidos por los *hacks*.

🔬 **El detalle.** La defensa es un *hash* propio no predecible, como `splitmix64` con una semilla del reloj, o usar `map`. Los detalles y el código son de `06/03`.

**01 → 10.** ¿Cuándo un `vector` ordenado con búsqueda binaria es mejor que un `set`? 🟠

⏱️ **30 segundos.** Cuando los datos no cambian después de construirlos: se ordena una vez en `O(n log n)` y cada consulta es `O(log n)` sobre memoria contigua, con menos memoria y constante que un `set`.

🗣️ **2 minutos.** Un `set` paga en cada nodo un objeto con tres punteros y un color, disperso por la memoria; un `vector` ordenado guarda solo los valores, contiguos. Las búsquedas tocan menos líneas de caché. Pero insertar en un `vector` ordenado es `O(n)`, así que solo compensa si las inserciones son raras o van todas al principio.

🔬 **El detalle.** Es el patrón «construir, ordenar, consultar»: compresión de coordenadas ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)), búsquedas binarias sobre listas fijas. Con inserciones y consultas mezcladas, el `set`.

**01 → 11.** Escribe el fragmento que, dado un `multiset` de precios y un presupuesto, vende el billete más caro que no lo supera, incluido el caso en que no hay ninguno. 🔴

⏱️ **30 segundos.** `upper_bound(presupuesto)` da el primer precio mayor; si es `begin()`, no hay ninguno que sirva; si no, retrocedo uno, leo el precio y borro **ese iterador**.

🗣️ **2 minutos.** El fragmento es: `auto it = prices.upper_bound(budget); if (it == prices.begin()) { /* -1 */ } else { --it; int paid = *it; prices.erase(it); }`. La comprobación de `begin()` es obligatoria: retroceder desde `begin()` es comportamiento indefinido.

🔬 **El detalle.** Alternativa equivalente con `lower_bound` sobre los valores negados, o con un `std::map<int,int>` de conteos y `prev(upper_bound)`. Es el problema propio «Taquilla» y la autopsia de §4.

**01 → 12.** Diseña con contenedores de la STL una estructura que mantenga los números que se insertan y responda en `O(log n)` «el menor número mayor o igual que `x`» y «cuántas veces aparece `x`». Di el contenedor y el coste de cada operación. 🔴

⏱️ **30 segundos.** Un `std::multiset<int>`: insertar con `insert` en `O(log n)`, «el menor `≥ x`» con el `lower_bound` miembro en `O(log n)`, y «cuántas veces aparece `x`» con `count` en `O(log n + c)`, o con un `map` de conteos en `O(log n)`.

🗣️ **2 minutos.** El `multiset` responde las dos consultas, pero `count` recorre las `c` copias. Si `c` puede ser grande, conviene un `std::map<int, int>` de valor a conteo: el menor `≥ x` es `lower_bound(x)` sobre las claves, y el conteo es el valor asociado; las dos en `O(log n)`.

🔬 **El detalle.** El `map` de conteos es además lo que se haría en Java, que no tiene *multiset* ([`03/03`](03-java-colecciones.md)). Borrar una copia es decrementar el conteo y borrar la clave cuando llega a cero.

**01 → Problema: Taquilla.**

- **Pista 2 — patrón:** **`multiset` con `upper_bound`** y borrado por iterador.
- **Pista 3 — diseño:** mete los precios en un `multiset`; para cada presupuesto, `upper_bound`; si es `begin()`, imprime `-1`; si no, retrocede uno, imprime el precio y bórralo con `erase(it)`. Con E/S rápida.

**01 → Problema: El menor de los últimos k.**

- **Pista 2 — patrón:** **ventana deslizante** con una estructura que da el mínimo y permite borrar una copia: `multiset`, o la cola monótona.
- **Pista 3 — diseño:** con `multiset`: inserta cada lectura, y cuando la ventana pasa de `k`, borra **una** copia de la lectura que sale con `erase(find(x))`; el mínimo es `*begin()`. Con la cola monótona de índices ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)) baja de `O(n log k)` a `O(n)`.

**01 → Problema: Clasificación en vivo.**

- **Pista 2 — patrón:** **mapa de puntos más conjunto ordenado** de pares `(−puntos, nombre)`.
- **Pista 3 — diseño:** un `unordered_map` o `map` de nombre a puntos; un `set` de pares `(−puntos, nombre)` cuyo primer elemento es el líder; al sumar, borra el par viejo, actualiza los puntos e inserta el nuevo. Los puntos llegan a `2·10¹⁴`: 64 bits.

**01 → Problema: Vector-Erase.**

- **Pista 2 — patrón:** **`vector::erase`** por posición y por rango.
- **Pista 3 — diseño:** las posiciones del enunciado empiezan en 1; el primer `erase` es en `begin() + x − 1`, y el segundo es un rango `[begin() + a − 1, begin() + b − 1)` sobre el vector ya reducido.

**01 → Problema: Sets-STL.**

- **Pista 2 — patrón:** **`set`** con inserción, borrado y búsqueda.
- **Pista 3 — diseño:** según el tipo de consulta, `insert`, `erase` o `find` comparado con `end()` para imprimir si está.

**01 → Problema: Maps-STL.**

- **Pista 2 — patrón:** **`map`** de nombre a nota con acumulación.
- **Pista 3 — diseño:** sumar con `m[nombre] += nota` está bien porque crea la clave en 0; para consultar, usa `find` o `count` y no `[]`, aunque aquí el resultado esperado sea 0 igualmente.

**01 → Problema: Lower Bound-STL.**

- **Pista 2 — patrón:** **`std::lower_bound`** sobre un `vector` ordenado.
- **Pista 3 — diseño:** el iterador devuelto apunta al primer `≥ y`; si apunta a `y`, está; la posición es `it − begin() + 1` en ambos casos, porque el enunciado pide la del primer mayor o igual.

**01 → Problema: Last Stone Weight.**

- **Pista 2 — patrón:** **montículo de máximos**.
- **Pista 3 — diseño:** mete todas las piedras en un `priority_queue`; mientras haya dos o más, saca las dos mayores y, si difieren, mete la diferencia; la respuesta es la que queda, o 0.

**01 → Problema: Contains Duplicate II.**

- **Pista 2 — patrón:** **mapa de la última posición** de cada valor.
- **Pista 3 — diseño:** recorre guardando en un `unordered_map` el último índice de cada valor; si el actual ya estaba y la distancia es `≤ k`, devuelve verdadero; actualiza siempre la última posición.

**01 → Problema: Distinct.**

- **Pista 2 — patrón:** **ordenar y contar cambios**, o un conjunto.
- **Pista 3 — diseño:** ordena una copia y cuenta las posiciones donde el valor difiere del anterior (más uno si no está vacía); o mete todos en un `unordered_set` y devuelve su tamaño.

**01 → Problema: Seat Reservation Manager.**

- **Pista 2 — patrón:** **montículo de mínimos** de asientos libres.
- **Pista 3 — diseño:** empieza con todos los asientos en un montículo de mínimos (o con un contador del siguiente nunca usado más un montículo de los liberados); reservar saca el mínimo; liberar lo vuelve a meter.

**01 → Problema: Deque-STL.**

- **Pista 2 — patrón:** **cola monótona** sobre un `deque` de índices.
- **Pista 3 — diseño:** mantén índices con valores decrecientes; al entrar uno, quita por detrás los menores o iguales; quita por delante el que sale de la ventana; el máximo es el del frente.

**01 → Problema: Towers.**

- **Pista 2 — patrón:** **`multiset` de cimas** con `upper_bound`, voraz.
- **Pista 3 — diseño:** para cada cubo, busca la torre con la menor cima estrictamente mayor que el cubo; si existe, pon el cubo encima (borra esa cima, inserta el cubo); si no, abre una torre nueva. La respuesta es el número de torres.

**01 → Problema: Playlist.**

- **Pista 2 — patrón:** **ventana deslizante** con un mapa de últimas posiciones.
- **Pista 3 — diseño:** recorre llevando el inicio de la ventana; si la canción actual apareció dentro de la ventana, el inicio salta a una posición después de esa aparición; guarda la última posición de cada canción y la mayor anchura.

**01 → Problema: Sliding Window Median.**

- **Pista 2 — patrón:** **dos `multiset`** que mantienen la mitad baja y la alta de la ventana.
- **Pista 3 — diseño:** invariante: todo elemento de la baja es `≤` que todo elemento de la alta, y la baja tiene uno más o el mismo número; al entrar y salir, inserta o borra una copia en la mitad correcta y rebalancea moviendo un extremo; la mediana es el máximo de la baja.

---

# 02 — C++: algoritmos, *ranges* y `ordered_set`

**02 → 1.** ¿Qué cuatro propiedades tiene que cumplir el comparador de `std::sort`? 🟢

⏱️ **30 segundos.** Irreflexivo (`comp(a, a)` falso), asimétrico, transitivo, y que la equivalencia —«ni `a` antes que `b` ni `b` antes que `a`»— también sea transitiva. Es un orden estricto débil.

🗣️ **2 minutos.** Las tres primeras son las de un orden estricto, como `<`. La cuarta permite que haya elementos «iguales» para la ordenación sin ser idénticos, y exige que esa igualdad se comporte como tal: si `a ~ b` y `b ~ c`, entonces `a ~ c`. Con eso, el rango se puede partir en clases de iguales ordenadas entre sí.

🔬 **El detalle.** `<=` viola la irreflexividad; un comparador de `double` con tolerancia viola la transitividad de la equivalencia (`a ≈ b` y `b ≈ c` no implican `a ≈ c`); un comparador que mira campos distintos según el caso suele violar la transitividad. Cualquiera de las tres da comportamiento indefinido en `sort`, `set` y `map`.

**02 → 2.** ¿Qué devuelven `lower_bound` y `upper_bound`, y cómo cuentas las apariciones de `x` con ellas? 🟢

⏱️ **30 segundos.** `lower_bound` devuelve el primero `≥ x` y `upper_bound` el primero `> x`. Las apariciones de `x` son `upper_bound − lower_bound`.

🗣️ **2 minutos.** Sobre un rango ordenado, todos los `x` están juntos, entre esos dos iteradores. Su diferencia es el número de apariciones, y si es cero, `x` no está. Con los dos también se cuentan los valores de un rango `[L, R]`: `upper_bound(R) − lower_bound(L)`.

🔬 **El detalle.** `equal_range` devuelve los dos a la vez con una sola búsqueda compartida. Y la condición es que el rango esté ordenado con el mismo criterio que se usa al buscar.

**02 → 3.** ¿Qué hace `nth_element` con los elementos que no son el `n`-ésimo? 🟢

⏱️ **30 segundos.** Los deja partidos: todos los anteriores a la posición `n` son `≤` que el `n`-ésimo, y todos los posteriores `≥`, pero sin ordenar dentro de cada parte.

🗣️ **2 minutos.** `nth_element` es una selección: solo garantiza que el elemento de la posición `n` es el que habría ahí si se ordenara todo, y la partición alrededor de él. Por eso cuesta `O(n)` en promedio y no `O(n log n)`.

🔬 **El detalle.** La partición sirve: tras `nth_element(..., begin + k, ...)`, los `k` primeros son los `k` menores, en algún orden. Es la forma de obtener los `k` menores en `O(n)` si no hace falta ordenarlos.

**02 → 4.** ¿Qué diferencia hay entre `sort` y `stable_sort`, en garantías y en coste? 🟡

⏱️ **30 segundos.** `stable_sort` conserva el orden relativo de los elementos iguales y `sort` no. `stable_sort` usa memoria auxiliar `O(n)`; `sort`, ninguna.

🗣️ **2 minutos.** Los dos son `O(n log n)` en el caso peor. `sort` es un *introsort* en el sitio; `stable_sort` es una ordenación por mezcla, que necesita un búfer; si no consigue la memoria, baja a `O(n log² n)`. La estabilidad importa cuando se ordena por una clave y el orden previo codifica otra.

🔬 **El detalle.** El patrón «ordenar por la clave secundaria y después, de forma estable, por la primaria» da un orden lexicográfico sin escribir un comparador compuesto. Con `sort` no funciona.

**02 → 5.** ¿Por qué hay que ordenar antes de recorrer las permutaciones con `next_permutation`, y qué pasa con los repetidos? 🟡

⏱️ **30 segundos.** Porque `next_permutation` da la **siguiente** en orden lexicográfico: si no empiezas por la primera, te saltas las anteriores. Con repetidos, cada permutación distinta sale una sola vez.

🗣️ **2 minutos.** Cuando llega a la última (orden decreciente), devuelve `false` y deja el rango en la primera. Empezando ordenado, el bucle `do`/`while` recorre todas exactamente una vez. Con `"aab"`, salen `"aab"`, `"aba"` y `"baa"`: tres, no seis, porque intercambiar las dos `a` no produce una cadena distinta.

🔬 **El detalle.** El número de permutaciones distintas de un multiconjunto es `n! / (c₁! · c₂! · …)`, con `cᵢ` las repeticiones de cada valor. `next_permutation` las genera sin duplicados por cómo busca el siguiente: el sufijo decreciente más largo y el menor elemento mayor que su pivote.

**02 → 6.** ¿Qué diferencia hay entre `find_by_order` y `order_of_key` en un `ordered_set`? 🟡

⏱️ **30 segundos.** `find_by_order(k)` devuelve un iterador al elemento de posición `k` (desde 0); `order_of_key(x)` devuelve cuántos elementos son estrictamente menores que `x`.

🗣️ **2 minutos.** Son operaciones inversas: una va de posición a valor y la otra de valor a posición. Las dos son `O(log n)` porque cada nodo del árbol guarda el tamaño de su subárbol, y basta con bajar comparando esos tamaños.

🔬 **El detalle.** Si `x` está en el conjunto, `order_of_key(x)` es su posición desde 0; si no, es la posición donde se insertaría. Para el rango descendente («cuántos tienen más»), `size() − order_of_key(x) − 1` con `x` presente.

**02 → 7.** ¿Por qué `std::accumulate(v.begin(), v.end(), 0)` puede dar un resultado incorrecto con `v` de `long long`? 🟠

⏱️ **30 segundos.** Porque el tipo de la suma lo fija el valor inicial, `0`, que es `int`: cada suma parcial se convierte a `int` y desborda en silencio si pasa de `2·10⁹`.

🗣️ **2 minutos.** `accumulate` es una plantilla cuyo acumulador tiene el tipo del tercer argumento. Con `0` es `int`, y cada `acc + *it` se calcula como `long long` y se guarda de vuelta en `int`, truncando. El resultado parece razonable y es incorrecto. Con `0LL`, el acumulador es `long long`.

🔬 **El detalle.** Es la autopsia de [`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md) escondida en una llamada de librería. El compilador puede avisar de la conversión con `-Wconversion`, que no está en `-Wall -Wextra`.

**02 → 8.** ¿Por qué un comparador de `double` con tolerancia puede romper `std::sort`? 🟠

⏱️ **30 segundos.** Porque con tolerancia, «iguales» deja de ser transitivo: `a ≈ b` y `b ≈ c` no implican `a ≈ c`. El comparador viola el orden estricto débil y `sort` tiene comportamiento indefinido.

🗣️ **2 minutos.** Si `comp(a, b)` es `a < b − ε`, tres valores separados por `0,6ε` dan `a ~ b`, `b ~ c` y `a < c`: la equivalencia no es transitiva. `sort` supone que puede partir el rango en clases de iguales, y con este comparador esas clases no existen.

🔬 **El detalle.** Lo correcto es ordenar con `<` exacto sobre los `double` y aplicar la tolerancia después, al comparar resultados; o, mejor, trabajar con enteros (`01/04`).

**02 → 9.** Compara cómo ordenas una lista de reuniones por su hora de fin en C++ con `std::ranges`, en Java y en Python. 🟠

⏱️ **30 segundos.** En C++, `std::ranges::sort(ms, {}, &Meeting::end)`; en Java, `ms.sort(Comparator.comparingInt(Meeting::end))`; en Python, `ms.sort(key=lambda m: m.end)`. Los tres ordenan por una clave sin escribir un comparador de dos argumentos.

🗣️ **2 minutos.** La proyección de C++, el `comparingInt` de Java y el `key` de Python son la misma idea: extraer la clave de cada elemento y ordenar por ella. En Python, `key` se calcula una vez por elemento y es lo idiomático; el comparador de dos argumentos existe pero obliga a `functools.cmp_to_key`.

🔬 **El detalle.** El `sort` de Java sobre objetos y el `sort` de Python son estables (TimSort); `std::ranges::sort` no, y para estabilidad está `std::ranges::stable_sort`. La tabla completa de equivalencias está en `03/05`.

**02 → 10.** ¿Por qué un `ordered_set` con `std::less_equal` no funciona como *multiset*, y qué se hace en su lugar? 🔴

⏱️ **30 segundos.** Porque `less_equal` no es un orden estricto: `comp(a, a)` es verdadero, y el árbol ya no puede decidir si un elemento está, así que `find` y `erase` fallan. Para un *multiset* se guardan pares `(valor, identificador único)`.

🗣️ **2 minutos.** El árbol busca bajando por la izquierda si `comp(x, nodo)` y por la derecha si `comp(nodo, x)`; con `<=` las dos son ciertas para el mismo valor, y la búsqueda nunca «encuentra» igualdad. Insertar funciona por casualidad; borrar por valor no. Con pares, cada copia es distinta y el orden por pares es estricto.

🔬 **El detalle.** Con pares, `order_of_key({x, −∞})` cuenta los menores que `x`, y `order_of_key({x, +∞})` los menores o iguales. El identificador puede ser el índice de llegada.

**02 → 11.** Explica por qué `std::sort` con `>=` puede leer fuera del arreglo en libstdc++, relacionándolo con el contrato del comparador. 🔴

⏱️ **30 segundos.** El bucle interno de la partición avanza mientras `comp(elemento, pivote)` sea cierto, sin comprobar el límite, porque el contrato garantiza que el pivote lo detiene. Con `>=`, `comp(pivote, pivote)` es cierto y nada lo detiene.

🗣️ **2 minutos.** libstdc++ coloca el pivote de forma que, con un comparador estricto, siempre hay un elemento que hace falsa la condición antes de salirse del rango: es lo que le permite omitir la comprobación de índices en el bucle más caliente. Con un comparador reflexivo, si todo el tramo es igual al pivote, la condición es cierta siempre y el índice sigue avanzando fuera del arreglo.

🔬 **El detalle.** Es un ejemplo de por qué el contrato importa: la implementación usa la irreflexividad para ser más rápida. Con `-D_GLIBCXX_DEBUG`, libstdc++ comprueba el comparador y avisa; con `-fsanitize=address`, se ve la lectura fuera de rango.

**02 → 12.** Diseña la solución a «para cada uno de `q` rangos `[L, R]`, cuántos valores de un arreglo fijo caen dentro», di su coste y por qué no hace falta ninguna estructura más que un `vector`. 🔴

⏱️ **30 segundos.** Ordeno el arreglo una vez y para cada consulta respondo `upper_bound(R) − lower_bound(L)`. Coste `O(n log n + q log n)`. No hace falta más porque el arreglo no cambia.

🗣️ **2 minutos.** Sobre el arreglo ordenado, los valores de `[L, R]` forman un tramo contiguo que empieza en el primero `≥ L` y termina antes del primero `> R`. Las dos búsquedas binarias dan los extremos y la resta, el tamaño. Una estructura dinámica (un árbol de Fenwick, un `ordered_set`) solo hace falta si hay inserciones o borrados entre consultas.

🔬 **El detalle.** Es el problema propio «Precios en un rango». La versión con actualizaciones se resuelve con compresión de coordenadas y un Fenwick ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)), o con un `ordered_set` contando con `order_of_key`.

**02 → Problema: Los k más baratos.**

- **Pista 2 — patrón:** **selección** con `nth_element`: los `k` menores sin ordenarlos.
- **Pista 3 — diseño:** `nth_element(a.begin(), a.begin() + k − 1, a.end())` deja en las `k` primeras posiciones los `k` menores; súmalos en 64 bits (llegan a `10¹⁵`). Con E/S rápida, porque `n` llega a `10⁶`.

**02 → Problema: Precios en un rango.**

- **Pista 2 — patrón:** **ordenar y dos búsquedas binarias** por consulta.
- **Pista 3 — diseño:** ordena una vez; la respuesta a `[L, R]` es `upper_bound(R) − lower_bound(L)`.

**02 → Problema: Posición en vivo.**

- **Pista 2 — patrón:** **conjunto con estadísticos de orden**: contar cuántos de los anteriores son mayores.
- **Pista 3 — diseño:** con un `ordered_set`, inserta cada puntuación y responde `tamaño − order_of_key(x)`, que es uno más que los mayores que `x`. Sin PBDS, *offline*: comprime las puntuaciones y usa un árbol de Fenwick que cuenta los ya insertados por encima de cada una.

**02 → Problema: Vector-Sort.**

- **Pista 2 — patrón:** **`sort`** sobre todo el rango.
- **Pista 3 — diseño:** `std::sort(v.begin(), v.end())` y escribe los valores separados por espacios.

**02 → Problema: Relative Sort Array.**

- **Pista 2 — patrón:** **comparador por clave** construida a partir de la segunda lista.
- **Pista 3 — diseño:** asigna a cada valor de `arr2` su posición; ordena `arr1` por la clave `(posición si está en arr2, si no un valor mayor que todas; y después el propio valor)`. Con valores pequeños, un conteo es aún más simple.

**02 → Problema: Triangle.**

- **Pista 2 — patrón:** **ordenar y mirar ternas consecutivas**.
- **Pista 3 — diseño:** ordena; si existe un triángulo, existe uno con tres valores consecutivos, así que basta comprobar `a[i] + a[i+1] > a[i+2]`, sumando en 64 bits porque los valores llegan a `2³¹ − 1`.

**02 → Problema: Sorting: Comparator.**

- **Pista 2 — patrón:** **comparador con desempate**: puntuación descendente y nombre ascendente.
- **Pista 3 — diseño:** compara primero las puntuaciones en orden inverso; si son iguales, los nombres en orden normal; devuelve un comparador estricto (nunca «igual» como «menor»).

**02 → Problema: Next Permutation.**

- **Pista 2 — patrón:** **la operación de `next_permutation`**: sufijo decreciente, pivote, intercambio e inversión.
- **Pista 3 — diseño:** busca desde el final el primer `i` con `a[i] < a[i+1]`; si no hay, invierte todo; si hay, busca desde el final el primer `j` con `a[j] > a[i]`, intercámbialos e invierte el sufijo desde `i + 1`.

**02 → Problema: Permutations.**

- **Pista 2 — patrón:** **ordenar y `next_permutation`** (o *backtracking*, [`10/02`](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md)).
- **Pista 3 — diseño:** ordena y recoge cada permutación en un bucle `do`/`while`; con valores distintos, salen `n!`.

**02 → Problema: Kth Largest Element in an Array.**

- **Pista 2 — patrón:** **selección** con `nth_element`, o un montículo de tamaño `k`.
- **Pista 3 — diseño:** el `k`-ésimo mayor es el de posición `n − k` en orden creciente: `nth_element(begin, begin + n − k, end)` y lee esa posición.

**02 → Problema: NumberOfDiscIntersections.**

- **Pista 2 — patrón:** **ordenar inicios y finales por separado** y contar con búsqueda binaria o con dos punteros.
- **Pista 3 — diseño:** calcula `i − A[i]` e `i + A[i]` en 64 bits (desborda en 32); ordena los inicios; para cada disco, cuenta los discos con inicio `≤` su final y resta los ya contados y él mismo; si el total pasa de `10⁷`, devuelve `−1`.

**02 → Problema: Creating Strings.**

- **Pista 2 — patrón:** **ordenar y `next_permutation`**, que ya omite los repetidos.
- **Pista 3 — diseño:** ordena la cadena, cuenta y guarda las permutaciones en un bucle `do`/`while`; imprime el número y después cada una, en orden.

**02 → Problema: List Removals.**

- **Pista 2 — patrón:** **`k`-ésimo dinámico**: `ordered_set` de índices, o árbol de Fenwick con búsqueda del `k`-ésimo.
- **Pista 3 — diseño:** guarda las posiciones originales aún presentes; para cada consulta, el `k`-ésimo presente (desde 1) es `find_by_order(k − 1)`; imprime su valor y bórralo.

**02 → Problema: Josephus Problem II.**

- **Pista 2 — patrón:** **`k`-ésimo dinámico** con aritmética modular sobre los que quedan.
- **Pista 3 — diseño:** con un `ordered_set` de los niños presentes, la posición del siguiente eliminado es `(posición actual + k) mod tamaño`; sácalo con `find_by_order` y bórralo.

**02 → Problema: Nested Ranges Count.**

- **Pista 2 — patrón:** **ordenar los rangos y contar con una estructura de rango** (`ordered_set` o Fenwick con compresión).
- **Pista 3 — diseño:** ordena por inicio creciente y, a igual inicio, por final decreciente; recorriendo en ese orden, los rangos que contienen al actual son los ya vistos con final `≥` el suyo; recorriendo al revés, los contenidos son los vistos con final `≤`. Cuenta con `order_of_key` sobre pares `(final, índice)`.

---

# 03 — Java: las colecciones para competir y sus trampas

**03 → 1.** ¿Qué colección de Java usas como pila y como cola, y por qué no `Stack`? 🟢

⏱️ **30 segundos.** `ArrayDeque` para las dos: como pila con `push`, `pop` y `peek`, y como cola con `offer` y `poll`. `Stack` hereda de `Vector`: está sincronizada y permite acceso por índice, que rompe el contrato de pila.

🗣️ **2 minutos.** `ArrayDeque` es un arreglo circular con todas las operaciones de los extremos en `O(1)`. `Stack` es una clase antigua que la propia documentación de Java desaconseja en favor de `Deque`. `LinkedList` también implementa `Deque`, pero con un nodo por elemento y peor localidad.

🔬 **El detalle.** `ArrayDeque` no admite `null`, y por eso `poll` puede usar `null` para decir «vacía». Si guardas el resultado en un `int`, ese `null` se desempaqueta y lanza `NullPointerException`.

**03 → 2.** ¿Qué devuelve `TreeMap.floorKey(x)` y qué devuelve si no hay ninguna clave que sirva? 🟢

⏱️ **30 segundos.** La mayor clave menor o igual que `x`, como `Integer`; si no hay ninguna, `null`.

🗣️ **2 minutos.** Es la operación de predecesor no estricto, en `O(log n)`. Las cuatro hermanas son `floorKey` (`≤`), `lowerKey` (`<`), `ceilingKey` (`≥`) y `higherKey` (`>`). Todas devuelven `null` cuando no hay ninguna, y por eso el resultado se compara con `null` antes de usarlo.

🔬 **El detalle.** Asignar el resultado directamente a un `int` (`int k = map.floorKey(x);`) compila, por el desempaquetado automático, y lanza `NullPointerException` justo en el caso borde. Las versiones `floorEntry` y compañía devuelven el par clave-valor.

**03 → 3.** ¿`PriorityQueue` da el mínimo o el máximo, y cómo consigues lo otro? 🟢

⏱️ **30 segundos.** El mínimo. Para el máximo, `new PriorityQueue<>(Collections.reverseOrder())` o un comparador invertido.

🗣️ **2 minutos.** Es lo contrario de C++, cuyo `priority_queue` da el máximo, y lo mismo que `heapq` de Python. Con objetos o arreglos, el comparador se escribe con `Integer.compare` o `Long.compare` sobre el campo que ordena.

🔬 **El detalle.** La tabla de los tres lenguajes está en `03/05`. Al traducir un Dijkstra de C++ a Java, el error típico es invertir sin querer el orden: en Java no hay que poner nada para sacar la distancia mínima.

**03 → 4.** ¿Qué diferencia hay entre `list.remove(5)` y `list.remove(Integer.valueOf(5))` en una `List<Integer>`? 🟡

⏱️ **30 segundos.** `list.remove(5)` llama a `remove(int index)` y quita el elemento de la **posición** 5; `list.remove(Integer.valueOf(5))` llama a `remove(Object)` y quita la **primera aparición del valor** 5.

🗣️ **2 minutos.** Java elige la sobrecarga en compilación por el tipo del argumento: un `int` literal coincide exactamente con `remove(int)` y no se empaqueta. Con una lista de seis elementos, `remove(5)` quita el último, que puede no ser un 5; con menos de seis, lanza `IndexOutOfBoundsException`.

🔬 **El detalle.** El error es silencioso cuando el índice existe: la lista pierde un elemento equivocado y el programa sigue. Pasa igual con `remove(i)` cuando `i` es una variable `int` que en realidad guarda un valor.

**03 → 5.** ¿Qué diferencia hay entre `Arrays.sort` sobre `int[]` y sobre `Integer[]`, en algoritmo y en garantías? 🟡

⏱️ **30 segundos.** Sobre `int[]` es un *quicksort* de doble pivote, no estable, con respaldo de *heapsort* desde Java 14; sobre `Integer[]` es TimSort, estable. Los dos son `O(n log n)` en el caso peor en Java 21.

🗣️ **2 minutos.** Con primitivos la estabilidad no importa, porque dos `5` son indistinguibles, y el *quicksort* tiene mejor constante. Con objetos importa, porque dos objetos que comparan igual pueden ser distintos, y por eso se usa TimSort. Además, ordenar objetos compara llamando a `compareTo` sobre referencias dispersas.

🔬 **El detalle.** El respaldo de *heapsort* se añadió en Java 14; en Java 8 y 11 el *quicksort* de primitivos no tenía garantía de caso peor y había entradas que lo hacían cuadrático. Comprobado en el código fuente de OpenJDK 11, 13, 14 y 21.

**03 → 6.** ¿Qué cambió en `HashMap` en Java 8 respecto del caso peor? 🟡

⏱️ **30 segundos.** Que una cubeta con muchas colisiones (más de 8, en una tabla de al menos 64 cubetas) se convierte en un árbol rojo-negro, y el caso peor por operación pasa de `O(n)` a `O(log n)` cuando las claves son comparables.

🗣️ **2 minutos.** Antes, una cubeta era siempre una lista enlazada, y un ataque que metiera todas las claves en una cubeta hacía cada operación lineal. Con el árbol, la misma situación cuesta `O(log n)`. Además, el *hash* se mezcla con `h ^ (h >>> 16)` para que los bits altos influyan en la cubeta.

🔬 **El detalle.** El árbol solo ordena bien si las claves implementan `Comparable`; si no, desempata con otros criterios y la mejora es menor. Y con el *hash* de `Integer`, que es el propio valor, sigue siendo posible concentrar claves en una cubeta: el árbol limita el daño, no lo evita (`06/03`).

**03 → 7.** ¿Por qué `a == b` con dos `Integer` funciona con 100 y falla con 500? 🟠

⏱️ **30 segundos.** Porque `==` entre dos `Integer` compara referencias, y `Integer.valueOf` reutiliza los objetos de −128 a 127: con 100 los dos son el mismo objeto; con 500 son objetos distintos.

🗣️ **2 minutos.** El *autoboxing* llama a `Integer.valueOf`, que devuelve objetos de una caché para los valores pequeños. Fuera del rango crea objetos nuevos. Comparar con `equals`, o desempaquetar uno de los dos, compara valores.

🔬 **El detalle.** El límite superior de la caché se puede ampliar con una opción de la JVM, así que el comportamiento ni siquiera es fijo: el código que funciona por casualidad en local puede fallar en el juez. Es el problema de §1 y el propio «Votos iguales».

**03 → 8.** Compara cómo escribes un *multiset* en C++, en Java y en Python, y qué hay que cuidar al quitar una copia en cada uno. 🟠

⏱️ **30 segundos.** En C++, `std::multiset` y quitar una copia con `erase(find(x))`; en Java, un `TreeMap` de conteos y borrar la clave al llegar a cero; en Python, un `Counter` si no hace falta orden, y sin orden no hay *multiset* ordenado en la librería.

🗣️ **2 minutos.** C++ es el único con *multiset* nativo, y su trampa es `erase(x)`, que borra todas. Java lo simula con conteos, y su trampa es dejar claves con conteo 0, que `firstKey` o `floorKey` seguirían devolviendo. Python tiene `collections.Counter` para conteos sin orden; para orden, un arreglo con `bisect` o una estructura escrita a mano.

🔬 **El detalle.** La tabla completa de equivalencias, con lo que falta en cada lenguaje y su sustituto, está en `03/05`.

**03 → 9.** ¿Por qué un comparador `(p, q) -> p[0] - q[0]` para una `PriorityQueue` puede romper Dijkstra con distancias grandes? 🟠

⏱️ **30 segundos.** Porque la resta desborda con distancias grandes y cambia de signo: el comparador dice que la distancia mayor es menor, y la `PriorityQueue` saca nodos en un orden incorrecto.

🗣️ **2 minutos.** Con `p[0]` y `q[0]` del orden de `10¹⁰`, la diferencia puede no caber en `int` tras el *cast*, o con `long` puede desbordar si los valores son de signo opuesto cerca de los extremos. Un comparador que no es un orden rompe el invariante del montículo, y Dijkstra deja de sacar el nodo más cercano: da distancias incorrectas.

🔬 **El detalle.** La forma correcta es `(p, q) -> Long.compare(p[0], q[0])`, o `Comparator.comparingLong(p -> p[0])`. Es el mismo error que el comparador de [`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md), en el sitio donde más daño hace.

**03 → 10.** Tu DFS recursivo en Java da RE solo en el caso más grande, que es una cadena de `2·10⁵` nodos. ¿Qué pasa y cómo lo arreglas sin reescribirlo? 🟠

⏱️ **30 segundos.** La recursión tiene profundidad `2·10⁵` y desborda la pila del hilo principal: `StackOverflowError`, que el juez informa como RE. Se arregla ejecutando el programa en un `Thread` con pila grande.

🗣️ **2 minutos.** En una cadena, cada llamada del DFS es hija de la anterior, y la profundidad es `n`. La pila por defecto, del orden de 1 MB, no da para tantos marcos. `new Thread(null, Main::solve, "solve", 1L << 28)` pide 256 MB de pila; con `start` y `join`, el resto del código no cambia.

🔬 **El detalle.** La alternativa portable es el DFS iterativo con una pila explícita, que no depende de lo que la JVM acepte. En Python el problema es el mismo con un límite de 1000 llamadas, y la receta, parecida ([`03/04`](04-python-para-competir.md)).

**03 → 11.** Escribe con un `TreeMap` el fragmento que vende el billete más caro que no supera un presupuesto, en un *multiset* de precios, y di qué línea es la que más se olvida. 🔴

⏱️ **30 segundos.** `Integer k = counts.floorKey(budget);` si es `null`, no hay billete; si no, se vende `k`: `counts.merge(k, -1, Integer::sum)` y, si queda en 0, `counts.remove(k)`. La línea que más se olvida es ese `remove`.

🗣️ **2 minutos.** El `TreeMap<Integer, Integer>` hace de *multiset*: clave el precio, valor las copias. `floorKey` da el mayor precio que no pasa del presupuesto. Decrementar con `merge` deja el conteo; si llega a 0 y no se borra, el siguiente `floorKey` puede devolver un precio sin billetes.

🔬 **El detalle.** La comprobación del `null` es la otra línea olvidada: asignar `floorKey` a un `int` lanza `NullPointerException` cuando ningún precio sirve. Es la versión Java del problema «Taquilla» de [`03/01`](01-cpp-contenedores.md).

**03 → 12.** Un envío Java con `Arrays.sort(int[])` da TLE en un juez que corre Java 11 y pasa en uno con Java 21. Explica por qué es posible y cómo lo blindas en los dos. 🔴

⏱️ **30 segundos.** Porque en Java 11 el *quicksort* de primitivos no tenía respaldo de *heapsort* y hay entradas construidas para hacerlo cuadrático; en Java 21, sí lo tiene. Se blinda barajando el arreglo antes de ordenar, o ordenando objetos.

🗣️ **2 minutos.** El respaldo entró en Java 14: cuando la recursión pasa de cierta profundidad, cambia a *heapsort* y garantiza `O(n log n)`. Antes, un adversario que conociera el algoritmo podía diseñar una entrada que eligiera siempre pivotes malos. Barajar con un generador aleatorio rompe la relación entre la entrada y los pivotes.

🔬 **El detalle.** Otra salida es ordenar un `Integer[]` o una `List`, que usan TimSort y no tienen ese caso malo, a cambio del *boxing*. Y una más: si los valores caben, empaquetar cada valor con su índice en un `long` y ordenar `long[]` en Java 14 o posterior.

**03 → Problema: Votos iguales.**

- **Pista 2 — patrón:** **conteo con mapas** y comparación de valores con `equals`.
- **Pista 3 — diseño:** cuenta cada urna en un `HashMap<Integer, Integer>` con `merge`; los mapas son iguales si `primero.equals(segundo)`, que compara entradas con `equals`; nunca con `==` entre los `Integer` de `get`.

**03 → Problema: El turno anterior.**

- **Pista 2 — patrón:** ***multiset* con `TreeMap` de conteos** y `floorKey`.
- **Pista 3 — diseño:** `A x` hace `merge(x, 1, Integer::sum)`; `B x` decrementa y borra la clave si llega a 0; `P x` es `floorKey(x)`, imprimiendo `-1` si es `null`.

**03 → Problema: Tamaño de los equipos.**

- **Pista 2 — patrón:** **suma por subárbol** en un árbol enraizado, con cuidado de la profundidad de recursión.
- **Pista 3 — diseño:** construye las listas de hijos; el tamaño de un empleado es 1 más la suma de los de sus hijos. Recursivo, dentro de un `Thread` con pila grande; o iterativo: un recorrido con pila explícita desde el director que anota el orden de visita, y después se suman los tamaños recorriendo ese orden al revés, de forma que cada empleado se procesa antes que su jefe.

**03 → Problema: Java Arraylist.**

- **Pista 2 — patrón:** **lista de listas** con comprobación de rangos.
- **Pista 3 — diseño:** guarda cada fila en una `ArrayList<Integer>`; para una consulta `(x, y)`, si la fila `x` tiene al menos `y` elementos, imprime `get(y − 1)`; si no, `ERROR!`.

**03 → Problema: Java Hashset.**

- **Pista 2 — patrón:** **`HashSet` de una clave canónica** para el par.
- **Pista 3 — diseño:** combina las dos cadenas en una sola con un separador que no puede aparecer en ellas; añade al conjunto y tras cada par imprime su tamaño.

**03 → Problema: Java Map.**

- **Pista 2 — patrón:** **`HashMap`** con consulta que puede fallar.
- **Pista 3 — diseño:** guarda nombre → teléfono; para cada consulta, `get` y, si es `null`, imprime `Not found`. La entrada se lee línea a línea hasta el final.

**03 → Problema: Java BitSet.**

- **Pista 2 — patrón:** **operaciones de conjunto sobre `BitSet`**.
- **Pista 3 — diseño:** dos `BitSet` de tamaño `N`; cada orden se traduce a `and`, `or`, `xor`, `set` o `flip` sobre el que corresponda, e imprime `cardinality()` de los dos.

**03 → Problema: Java Dequeue.**

- **Pista 2 — patrón:** **ventana deslizante** con una `ArrayDeque` y un mapa de conteos.
- **Pista 3 — diseño:** mete cada número por detrás y súmalo al mapa; cuando la ventana pasa de `m`, saca el del frente y decrementa su conteo, borrándolo si llega a 0; el número de distintos es el tamaño del mapa, y la respuesta su máximo.

**03 → Problema: Java Stack.**

- **Pista 2 — patrón:** **pila** de aperturas sobre `ArrayDeque`.
- **Pista 3 — diseño:** apila las aperturas; con un cierre, la pila no puede estar vacía y la cima tiene que ser su apertura; al terminar la línea, la pila tiene que estar vacía.

**03 → Problema: Java Priority Queue.**

- **Pista 2 — patrón:** **`PriorityQueue` con un comparador de tres criterios**.
- **Pista 3 — diseño:** compara primero por nota de mayor a menor (con `Double.compare` invertido), después por nombre en orden alfabético y después por identificador de menor a mayor; los eventos `SERVED` hacen `poll`.

**03 → Problema: Java Comparator.**

- **Pista 2 — patrón:** **comparador con desempate**.
- **Pista 3 — diseño:** puntuación descendente con `Integer.compare(b.score, a.score)`; si es 0, nombre ascendente con `a.name.compareTo(b.name)`.

**03 → Problema: Java Sort.**

- **Pista 2 — patrón:** **ordenar objetos con un comparador compuesto**.
- **Pista 3 — diseño:** `Comparator.comparingDouble` de la nota invertida, después el nombre y después el identificador, encadenados con `thenComparing`; usa `Double.compare`, nunca una resta.

**03 → Problema: Sort Characters By Frequency.**

- **Pista 2 — patrón:** **conteo y orden por conteo**, o cubetas por frecuencia.
- **Pista 3 — diseño:** cuenta cada carácter; ordena los caracteres distintos por conteo descendente y construye la cadena repitiendo cada uno tantas veces como aparece, con un `StringBuilder`.

**03 → Problema: Contains Duplicate III.**

- **Pista 2 — patrón:** **ventana deslizante con un conjunto ordenado** (`TreeSet`), o cubetas de ancho `valueDiff + 1`.
- **Pista 3 — diseño:** mantén en un `TreeSet<Long>` los valores de los últimos `indexDiff` elementos; para cada nuevo `x`, mira `ceiling(x − valueDiff)` y comprueba si es `≤ x + valueDiff`; en `long` para no desbordar; después añade `x` y quita el que sale de la ventana.

---

# 04 — Python: `collections`, `heapq`, `bisect`, `itertools`, recursión y PyPy

**04 → 1.** ¿Cuánto cuestan `list.pop()` y `list.pop(0)`, y por qué son distintos? 🟢

⏱️ **30 segundos.** `pop()` es `O(1)`: quita el último y no mueve nada. `pop(0)` es `O(n)`: quita el primero y desplaza todos los demás una posición.

🗣️ **2 minutos.** Una `list` es un arreglo contiguo de punteros. Quitar del final solo cambia el tamaño; quitar del principio obliga a que el resto ocupe el hueco. Por eso `list` sirve de pila y no de cola: un BFS con `pop(0)` es cuadrático.

🔬 **El detalle.** El desplazamiento es una copia de memoria en C, rápida por elemento, y con listas pequeñas no se nota. Con `10⁵` o más elementos y una extracción por iteración, el total de `n²/2` movimientos sí da TLE.

**04 → 2.** ¿Qué estructura usas como cola en Python? 🟢

⏱️ **30 segundos.** `collections.deque`, con `append` para encolar y `popleft` para desencolar, las dos en `O(1)`.

🗣️ **2 minutos.** `deque` está hecho de bloques enlazados y trabaja en `O(1)` por los dos extremos. Sirve igual de pila (`append` y `pop`) y de cola doble. Con `maxlen`, además, mantiene una ventana de tamaño fijo expulsando el más viejo.

🔬 **El detalle.** `queue.Queue` también existe, pero es una cola para hilos, con cerrojos: más lenta y pensada para otra cosa. En competitiva, `deque`.

**04 → 3.** ¿Qué hace `heapq.heapify` y cuánto cuesta? 🟢

⏱️ **30 segundos.** Reordena una lista en el sitio para que cumpla la propiedad de montículo de mínimos, con el mínimo en la posición 0. Cuesta `O(n)`.

🗣️ **2 minutos.** No ordena la lista: solo garantiza que cada elemento es menor o igual que sus hijos (`2i + 1` y `2i + 2`). Construir así es más barato que meter `n` elementos uno a uno, que costaría `O(n log n)`.

🔬 **El detalle.** El `O(n)` sale de que la mayoría de los nodos están cerca de las hojas y bajan poco; la suma está en [`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md). Después de `heapify`, la lista se maneja solo con `heappush` y `heappop`, o el invariante se rompe.

**04 → 4.** ¿Qué diferencia hay entre consultar una clave ausente en un `Counter` y en un `defaultdict`? 🟡

⏱️ **30 segundos.** `Counter` devuelve 0 para una clave ausente sin crearla; `defaultdict` crea la entrada con su valor por defecto al consultarla.

🗣️ **2 minutos.** Con `Counter`, `freq[7]` vale 0 y `len(freq)` no cambia. Con `defaultdict(int)`, `d[7]` también vale 0, pero `7` pasa a estar en el diccionario. Si después se recorren las claves o se cuenta el tamaño, aparecen entradas que nunca se insertaron.

🔬 **El detalle.** Es la misma trampa que el `operator[]` de un `map` de C++ (`03/01`). Para consultar sin crear en un `defaultdict`, `d.get(k, 0)` o `k in d`.

**04 → 5.** ¿Qué diferencia hay entre `bisect_left` y `bisect_right`? 🟡

⏱️ **30 segundos.** `bisect_left` devuelve el primer índice con valor `≥ x`; `bisect_right`, el primero con valor `> x`. Son el `lower_bound` y el `upper_bound` de C++.

🗣️ **2 minutos.** En `[1, 2, 5, 5, 6, 9]`, `bisect_left(v, 5)` es 2 y `bisect_right(v, 5)` es 4: la diferencia, 2, es el número de cincos. Para insertar manteniendo el orden, `insort_left` e `insort_right` deciden si el nuevo va antes o después de los iguales.

🔬 **El detalle.** Desde Python 3.10 aceptan `key=` para buscar por una clave de los elementos. La lista tiene que estar ordenada con esa misma clave.

**04 → 6.** ¿Por qué `sys.setrecursionlimit` no basta para una recursión de `10⁵` niveles? 🟡

⏱️ **30 segundos.** Porque `setrecursionlimit` solo cambia el contador de Python; la pila real del hilo es finita, y una recursión de `10⁵` niveles la desborda: el proceso muere con un fallo de segmentación.

🗣️ **2 minutos.** Cada llamada de Python ocupa también marcos en la pila de C del intérprete. Con el límite alto, Python deja de proteger y la pila del sistema se agota antes. La receta es crear un hilo con `threading.stack_size` grande y ejecutar el programa dentro, con el límite subido.

🔬 **El detalle.** La alternativa más robusta, y más rápida en Python, es la recursión convertida en un bucle con pila explícita ([`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md)).

**04 → 7.** ¿Por qué `grid = [[0] * 3] * 3` seguido de `grid[0][0] = 1` cambia tres celdas? 🟡

⏱️ **30 segundos.** Porque `[[0] * 3] * 3` crea una lista con tres referencias a la **misma** fila: modificar una es modificar las tres.

🗣️ **2 minutos.** `*` sobre una lista repite sus elementos, y aquí el elemento es una lista, así que se repite la referencia, no una copia. La matriz correcta se crea con una comprensión, que evalúa `[0] * 3` en cada vuelta: `[[0] * 3 for _ in range(3)]`.

🔬 **El detalle.** `[0] * 3` sí está bien, porque los enteros son inmutables: «compartir» el 0 no tiene consecuencias. El problema solo aparece con elementos mutables.

**04 → 8.** ¿Cómo haces un montículo de máximos con `heapq` en Python 3.12, y qué cuidado hay con las tuplas? 🟠

⏱️ **30 segundos.** Negando las prioridades: se mete `-p` y se niega al sacar. Con tuplas, si las prioridades empatan se compara el segundo componente, que tiene que ser comparable; si no lo es, se intercala un contador único.

🗣️ **2 minutos.** `heapq` en 3.12 solo tiene montículo de mínimos, así que el mayor se obtiene como el mínimo de los negados. Las tuplas se comparan componente a componente; `(5, obj1)` y `(5, obj2)` comparan `obj1` con `obj2`, y si los objetos no definen `<`, lanza `TypeError`. `(-p, contador, dato)` lo evita.

🔬 **El detalle.** Python 3.14 añade funciones públicas de máximos (`heappush_max` y compañía), pero el techo del corpus es 3.12. Negar falla con objetos que no son números; ahí, se niega solo la clave numérica de la tupla.

**04 → 9.** Compara cómo resuelves «el mayor elemento menor o igual que `x`, con inserciones» en C++, Java y Python. 🟠

⏱️ **30 segundos.** En C++, `std::set` con `upper_bound` y retroceder; en Java, `TreeSet.floor` o `TreeMap.floorKey`; en Python no hay estructura en la librería: `insort` y `bisect` si `n` es pequeño, o una solución *offline* o a mano si no.

🗣️ **2 minutos.** C++ y Java tienen árboles balanceados con la operación de predecesor en `O(log n)`. Python solo tiene listas ordenadas con inserción `O(n)`. Si las inserciones se conocen de antemano, se comprimen los valores y se usa un árbol de Fenwick (`09/02`) para encontrar el mayor presente `≤ x`; si no, un *treap* escrito a mano ([`07/03`](../07-arboles/03-arboles-aleatorizados.md)).

🔬 **El detalle.** Es una de las razones por las que un problema que en C++ es de diez líneas en Python puede pedir otro diseño. La tabla completa de equivalencias está en `03/05`.

**04 → 10.** Tu solución `O(n log n)` con `n = 10⁶` en Python da TLE. ¿Qué cambias antes de cambiar de algoritmo? 🟠

⏱️ **30 segundos.** La E/S (leer todo de golpe y escribir una vez), mover los bucles a funciones de la librería, usar variables locales dentro de `main`, y si el juez ofrece PyPy, probarlo.

🗣️ **2 minutos.** Con `n = 10⁶` y `n log n` son unos `2·10⁷` pasos: si cada paso es una operación del intérprete, no entra. `sorted` hace su `n log n` en C; un bucle propio que compara elementos, no. Las comprensiones son más rápidas que los bucles con `append`, y las variables locales más que las globales.

🔬 **El detalle.** Si todo eso no basta, la complejidad correcta en Python simplemente no cabe: se cambia de lenguaje o se busca un algoritmo de menor constante. Es lo que [`01/02`](../01-oficio-del-competidor/02-leer-las-restricciones.md) llama perder una fila de la tabla.

**04 → 11.** Diseña con `heapq` una cola de tareas que saque siempre la de **mayor** prioridad y, a igual prioridad, la que llegó antes, donde las tareas son objetos que no se pueden comparar. Escribe qué tupla metes y por qué. 🔴

⏱️ **30 segundos.** Meto la tupla `(-prioridad, contador, tarea)`, con un contador que crece en cada inserción: la prioridad negada da el máximo, el contador desempata por llegada y evita comparar las tareas.

🗣️ **2 minutos.** `heapq` saca el mínimo; negar la prioridad lo convierte en el máximo. Si dos tareas tienen la misma prioridad, la tupla compara el segundo componente: el contador, distinto para cada inserción y creciente, deja primero a la que llegó antes. Como el contador nunca empata, la comparación nunca llega a la tarea.

🔬 **El detalle.** Es el patrón que la documentación de `heapq` propone para colas de prioridad con elementos no comparables. Cada inserción y extracción cuesta `O(log n)`.

**04 → 12.** Una DP recursiva con `@cache` y `n = 10⁵` da RE. Explica la causa y propone dos soluciones con su coste. 🔴

⏱️ **30 segundos.** La recursión de la DP baja `10⁵` niveles en la primera llamada, aunque esté memoizada, y desborda el límite o la pila. Soluciones: límite alto en un hilo con pila grande, o reescribir la DP como una tabla de abajo arriba.

🗣️ **2 minutos.** `@cache` evita recalcular, pero no evita la profundidad: `ways(10⁵)` llama a `ways(10⁵ − 1)` antes de devolver nada. La solución con hilo conserva el código y cuesta la pila; la tabla iterativa cambia el orden de cálculo, no usa pila y en Python es varias veces más rápida.

🔬 **El detalle.** Una tercera forma es «calentar» la memoización llamando a `ways(k)` para `k` creciente, de 0 a `n`, de modo que cada llamada solo baje un nivel. Funciona, pero es una tabla disfrazada ([`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md)).

**04 → Problema: Atención por orden de llegada.**

- **Pista 2 — patrón:** **cola** con `collections.deque`.
- **Pista 3 — diseño:** `append` para cada llegada y `popleft` para cada atención, comprobando antes si está vacía; con E/S en bloque, porque son `5·10⁵` operaciones.

**04 → Problema: Las tres más caras.**

- **Pista 2 — patrón:** **montículo de mínimos de tamaño 3**: guarda los tres mayores, y el mínimo de ellos es el que sale.
- **Pista 3 — diseño:** mete cada importe con `heappush` y, si el montículo pasa de 3, saca el mínimo con `heappop`; lleva la suma de lo que hay dentro sumando al meter y restando al sacar.

**04 → Problema: Llamadas en cadena.**

- **Pista 2 — patrón:** **propagación por orden**: como `p[i] < i`, el coste de `p[i]` ya está calculado al llegar a `i`.
- **Pista 3 — diseño:** recorre `i` de 1 a `n` con `total[i] = c[i] + total[p[i]]` y `total[1] = c[1]`; sin recursión no hay límite que subir. Los totales llegan a `2·10¹⁴`, que Python maneja sin problema.

**04 → Problema: collections.Counter().**

- **Pista 2 — patrón:** **`Counter`** de tallas disponibles.
- **Pista 3 — diseño:** cuenta las tallas; para cada cliente, si su talla tiene conteo positivo, suma el precio y decrementa.

**04 → Problema: DefaultDict Tutorial.**

- **Pista 2 — patrón:** **`defaultdict(list)`** de palabra a posiciones.
- **Pista 3 — diseño:** guarda las posiciones (desde 1) de cada palabra del grupo A; para cada palabra de B, imprime sus posiciones o `-1` si no está; consulta con `in` para no crear entradas.

**04 → Problema: Collections.deque().**

- **Pista 2 — patrón:** **`deque`** y despacho de órdenes.
- **Pista 3 — diseño:** lee cada orden y llama al método del mismo nombre con `getattr(d, orden)(*argumentos)`, o con un `if` por orden; al final, imprime los elementos separados por espacios.

**04 → Problema: itertools.permutations().**

- **Pista 2 — patrón:** **`itertools.permutations`** sobre la cadena ordenada.
- **Pista 3 — diseño:** ordena la cadena; `permutations(cadena, k)` da las permutaciones de longitud `k` en orden lexicográfico; únelas con `"".join`.

**04 → Problema: Number of Recent Calls.**

- **Pista 2 — patrón:** **ventana con `deque`**: los tiempos llegan crecientes.
- **Pista 3 — diseño:** mete cada tiempo por la derecha y saca por la izquierda los que son menores que `t − 3000`; la respuesta es el tamaño.

**04 → Problema: Word Order.**

- **Pista 2 — patrón:** **`dict` o `Counter`**, que conservan el orden de inserción.
- **Pista 3 — diseño:** cuenta las palabras en un `Counter`; imprime el número de claves y después los conteos en el orden en que se insertaron.

**04 → Problema: Piling Up!.**

- **Pista 2 — patrón:** **`deque` y voraz**: siempre el extremo más grande que no pase del último apilado.
- **Pista 3 — diseño:** mientras queden cubos, toma el mayor de los dos extremos; si es mayor que el último apilado, la respuesta es `No`; si no, pasa a ser el último. Si se terminan, `Yes`.

**04 → Problema: Top K Frequent Words.**

- **Pista 2 — patrón:** **`Counter` y ordenación por clave compuesta**, o montículo de tamaño `k`.
- **Pista 3 — diseño:** cuenta y ordena las palabras por `(-conteo, palabra)`, y toma las `k` primeras; con `heapq.nsmallest(k, ...)` y esa misma clave queda en `O(n log k)`.

**04 → Problema: Find K Pairs with Smallest Sums.**

- **Pista 2 — patrón:** **`heapq` con tuplas `(suma, i, j)`**, expandiendo solo los vecinos del par sacado.
- **Pista 3 — diseño:** empieza con `(nums1[i] + nums2[0], i, 0)` para los primeros `min(k, n)` valores de `i`; al sacar `(i, j)`, mete `(i, j + 1)` si existe; repite `k` veces.

**04 → Problema: Find the Running Median.**

- **Pista 2 — patrón:** **dos montículos**: uno de máximos (negado) con la mitad baja y uno de mínimos con la alta.
- **Pista 3 — diseño:** invariante: todo de la baja `≤` todo de la alta, y la baja con uno más o el mismo número; al llegar un número, mételo en la baja, pasa su máximo a la alta y rebalancea; la mediana es el máximo de la baja o la media de las dos cimas, con un decimal.

**04 → Problema: Sliding Window Maximum.**

- **Pista 2 — patrón:** **cola monótona** con `deque` de índices (`06/01`).
- **Pista 3 — diseño:** mantén índices con valores decrecientes; al entrar uno, saca por la derecha los de valor menor o igual; saca por la izquierda el índice que sale de la ventana; el máximo es el del frente.

---

# 05 — La tabla de equivalencias

**05 → 1.** ¿Qué extremo da por defecto la cola de prioridad de C++, la de Java y la de Python? 🟢

⏱️ **30 segundos.** C++ da el máximo; Java y Python, el mínimo.

🗣️ **2 minutos.** `std::priority_queue` usa `std::less` y deja arriba el mayor; para el mínimo, `std::greater<>`. `PriorityQueue` de Java y `heapq` de Python son montículos de mínimos; para el máximo, `Collections.reverseOrder()` en Java y negar las prioridades en Python.

🔬 **El detalle.** Es la diferencia que más errores silenciosos produce al traducir un Dijkstra o una mediana con dos montículos: el código compila y saca el extremo contrario. Python 3.14 añade funciones de máximos a `heapq`, fuera del techo del corpus.

**05 → 2.** ¿Qué estructura usas como *multiset* en Java? 🟢

⏱️ **30 segundos.** Un `TreeMap<T, Integer>` de valor a número de copias.

🗣️ **2 minutos.** Java no tiene *multiset*. Con el `TreeMap` de conteos se mantienen el orden y las consultas de vecino (`floorKey`, `ceilingKey`), y las copias se llevan en el valor: insertar es `merge(x, 1, Integer::sum)` y quitar una copia es decrementar y borrar la clave al llegar a 0.

🔬 **El detalle.** Si se olvida borrar la clave con conteo 0, `firstKey` y `floorKey` siguen devolviendo un valor que ya no está. Es el error típico de la traducción.

**05 → 3.** ¿Qué devuelve `TreeMap.floorKey` si no hay ninguna clave que sirva, y qué hace el equivalente de C++? 🟡

⏱️ **30 segundos.** `floorKey` devuelve `null`. En C++, el equivalente es `prev(m.upper_bound(x))`, y si `upper_bound` es `begin()` no hay ninguno: retroceder desde ahí es comportamiento indefinido.

🗣️ **2 minutos.** Java señala la ausencia con `null`, que hay que comprobar antes de desempaquetar. C++ no tiene una operación directa de predecesor: se busca el primero mayor y se retrocede uno, comprobando que no se esté en el principio. Python no tiene estructura: con una lista ordenada, `bisect_right(v, x) − 1`, que vale `−1` si no hay.

🔬 **El detalle.** Las tres comprobaciones son distintas y las tres se olvidan: el `null` en Java, el `begin()` en C++ y el índice `−1` en Python, que además es un índice válido que apunta al último elemento.

**05 → 4.** ¿Qué diferencia hay entre el orden del `dict` de Python y el de un `std::map`? 🟡

⏱️ **30 segundos.** El `dict` de Python conserva el orden de **inserción**; el `std::map` mantiene las claves ordenadas por su **valor**.

🗣️ **2 minutos.** Recorrer un `dict` da las claves en el orden en que entraron, y no ofrece ni mínimo ni sucesor. Un `std::map` (y un `TreeMap`) da las claves de menor a mayor y responde sucesor y predecesor en `O(log n)`.

🔬 **El detalle.** El `LinkedHashMap` de Java es el equivalente del `dict` en orden de inserción. Para ordenar un `dict` por clave hay que hacer `sorted(d)`, `O(n log n)` cada vez.

**05 → 5.** ¿Qué diferencia hay entre `Arrays.binarySearch` y `bisect_left` cuando hay valores repetidos? 🟡

⏱️ **30 segundos.** `bisect_left` devuelve siempre el **primer** índice con el valor; `Arrays.binarySearch` devuelve **alguno**, sin garantizar cuál.

🗣️ **2 minutos.** El contrato de Java es «encontrar», no «encontrar el primero»: con repetidos puede devolver cualquiera de ellos. Si el valor no está, devuelve `−(punto de inserción) − 1`. `bisect_left` es exactamente el `lower_bound` de C++.

🔬 **El detalle.** Para contar repeticiones o para el primero en Java, se escribe la búsqueda propia con su invariante (`02/04`, [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)).

**05 → 6.** ¿Por qué la pila de C++ no devuelve el elemento en `pop()`, y cómo se traduce `x = stack.pop()` de Java? 🟡

⏱️ **30 segundos.** Porque `pop()` devolviendo por valor no podría dar una garantía fuerte ante excepciones al copiar el elemento; por eso se separan `top()` y `pop()`. `x = stack.pop()` se traduce como `x = st.top(); st.pop();`.

🗣️ **2 minutos.** Si `pop()` quitara el elemento y lo devolviera por copia, y la copia lanzara una excepción, el elemento se habría perdido. Separar la lectura de la eliminación evita ese caso. En la práctica, al traducir, cada `pop()` de Java o Python que usa el valor se convierte en dos líneas.

🔬 **El detalle.** Lo mismo pasa con `std::queue`, `std::priority_queue` y `std::stack`: los tres tienen `pop()` sin valor de retorno.

**05 → 7.** Traduces a Java una solución C++ que usa `ms.erase(ms.find(x))` sobre un `multiset`. ¿Qué escribes y qué línea no puedes olvidar? 🟠

⏱️ **30 segundos.** `counts.merge(x, -1, Integer::sum);` y, si el conteo queda en 0, `counts.remove(x);`. La línea que no se puede olvidar es el `remove`.

🗣️ **2 minutos.** `erase(find(x))` en C++ quita una copia de `x`. En el `TreeMap` de conteos, quitar una copia es decrementar. Pero la clave sigue existiendo con valor 0, y cualquier consulta de orden la vería; por eso, al llegar a 0, se borra.

🔬 **El detalle.** Si en C++ el autor hubiera escrito `erase(x)` (todas las copias), la traducción fiel sería `counts.remove(x)` directamente. Antes de traducir hay que entender cuál de las dos quería.

**05 → 8.** ¿Qué sustituto del mapa ordenado eliges en Python si todas las operaciones se conocen de antemano, y por qué ese? 🟠

⏱️ **30 segundos.** Compresión de coordenadas más un árbol de Fenwick de conteos: con todas las operaciones conocidas, los valores posibles se conocen y caben en un arreglo.

🗣️ **2 minutos.** Se reúnen todos los valores que aparecen, se ordenan y se les asigna un índice. Un Fenwick sobre esos índices guarda cuántas copias hay de cada valor; insertar y borrar son sumar ±1, y «el menor `≥ x`» es una búsqueda del primer índice con conteo acumulado mayor que el de los menores que `x`. Todo `O(log n)`, sin estructuras con punteros.

🔬 **El detalle.** Es más rápido en Python que un *treap* escrito a mano, porque trabaja sobre listas de enteros. La técnica completa está en `04/04` y `09/02`.

**05 → 9.** Compara cómo se recorren los bits a 1 de un conjunto en C++, Java y Python, y el coste de cada forma. 🟠

⏱️ **30 segundos.** En C++, con `std::bitset` y `_Find_first`/`_Find_next` de GCC, o recorriendo palabras con `__builtin_ctzll`; en Java, `BitSet.nextSetBit`; en Python, con una máscara entera, `x & -x` para el bit más bajo. Las tres saltan los ceros.

🗣️ **2 minutos.** `nextSetBit(i)` en Java avanza palabra a palabra y es `O(N/64 + unos)`. En Python, `while x: b = x & -x; …; x ^= b` visita solo los unos, pero cada operación sobre un entero grande cuesta proporcional a su tamaño en palabras. En C++, `std::bitset` no tiene un iterador estándar de unos; GCC añade `_Find_first` y `_Find_next`, no estándar.

🔬 **El detalle.** Para recorrer los unos de una palabra de 64 bits en C++20 está `std::countr_zero` de `<bit>`, que es estándar y sustituye a `__builtin_ctzll`. Los trucos de bits son de [`17/01`](../17-matematica/01-bits.md).

**05 → 10.** Una solución de Dijkstra pasa de C++ a Java y da distancias incorrectas sin errores de compilación. ¿Qué miras primero? 🟠

⏱️ **30 segundos.** La cola de prioridad: el `priority_queue` de C++ da el máximo y la `PriorityQueue` de Java el mínimo. Si el código C++ metía distancias negadas o usaba `std::greater<>`, la traducción literal invierte el orden.

🗣️ **2 minutos.** En C++ es habitual meter `-dist` en un montículo de máximos para sacar la menor distancia. Traducido literal a Java, `-dist` en una `PriorityQueue` de mínimos saca primero la **mayor** distancia. La regla es una convención por lenguaje: en Java, la distancia tal cual en un montículo de mínimos, y revisar cada `push` y cada lectura.

🔬 **El detalle.** El segundo sospechoso es el comparador: `(a, b) -> a[0] - b[0]` desborda con distancias grandes. Y el tercero, el tipo: distancias en `int` en Java donde en C++ eran `long long`.

**05 → 11.** Te piden resolver en Python un problema de «para cada consulta online, el menor valor guardado mayor o igual que `x`, con inserciones y borrados, `n = 2·10⁵`». Diseña la solución y justifica por qué no basta `insort`. 🔴

⏱️ **30 segundos.** Un *treap* (o una *skip list*) escrito a mano, con `O(log n)` esperado por operación. `insort` no basta porque cada inserción y cada borrado desplazan la lista: con `2·10⁵` operaciones online, hasta `2·10¹⁰` movimientos.

🗣️ **2 minutos.** Como las consultas son *online*, no se pueden conocer de antemano los valores para comprimirlos y usar un Fenwick. Un *treap* con `split` y `merge` da inserción, borrado y sucesor en `O(log n)` esperado (`07/03`). En Python, la constante es alta, pero con `2·10⁵` operaciones suele entrar.

🔬 **El detalle.** Una alternativa con menos código es la «lista de raíz cuadrada»: una lista de bloques ordenados de tamaño `~√n`, con `bisect` dentro de cada bloque; inserción y borrado `O(√n)` pero con constantes de C. Es lo que hace por dentro `sortedcontainers`.

**05 → 12.** Escribe la tabla de huecos de §8 de memoria y, para cada hueco, el sustituto con su coste. 🔴

⏱️ **30 segundos.** C++: enteros de precisión arbitraria y un *hash* seguro por defecto, sustituidos por `__int128` y un *hash* con semilla. Java: *multiset*, colecciones sin *boxing* y `ordered_set`, sustituidos por `TreeMap` de conteos, arreglos primitivos y Fenwick. Python: mapa ordenado y montículo de máximos, sustituidos por los de §5 y por negar.

🗣️ **2 minutos.** Los costes: `__int128` es casi gratis hasta `10³⁸`; el *hash* con semilla, una función más por operación. El `TreeMap` de conteos es `O(log n)`; los arreglos primitivos, una reescritura; el Fenwick con compresión, `O(log n)` y exige operaciones conocidas. En Python, `insort` es `O(n)` por inserción, el Fenwick `O(log n)` *offline* y el *treap* `O(log n)` esperado con constante alta.

🔬 **El detalle.** La lección práctica es elegir el lenguaje de una prueba sabiendo sus huecos, y llevar en el cuaderno (`23`) el sustituto ya escrito.

**05 → Problema: El menor que alcanza.**

- **Pista 2 — patrón:** ***multiset* con sucesor**: `multiset::lower_bound` en C++, `TreeMap.ceilingKey` con conteos en Java; en Python, compresión y Fenwick, o una lista ordenada si cabe.
- **Pista 3 — diseño:** para cada pedido, busca la menor pieza `≥ x`; si no hay, `-1`; si hay, imprímela y quita **una** copia: `erase(iterador)` en C++, decrementar y borrar al llegar a 0 en Java, restar uno en el Fenwick en Python. Con los pedidos conocidos de antemano, en Python cabe la versión *offline*.

**05 → Problema: Los dos extremos de la urgencia.**

- **Pista 2 — patrón:** **cola de prioridad doble**: un `multiset` en C++, un `TreeMap` de conteos en Java, y en Python dos montículos (uno negado) con borrado perezoso.
- **Pista 3 — diseño:** en Python, cada tarea lleva un identificador; al atender por un extremo, saca de ese montículo descartando los identificadores ya atendidos por el otro (un `set` de atendidos o un arreglo de banderas); en C++, `begin()` y `prev(end())`; en Java, `firstKey` y `lastKey` con conteos.

**05 → Problema: Valid Anagram.**

- **Pista 2 — patrón:** **conteo** con la estructura más corta de cada lenguaje.
- **Pista 3 — diseño:** un arreglo de 26 enteros en los tres, o `Counter(s) == Counter(t)` en Python y `unordered_map` en C++; distinto largo implica distinto.

**05 → Problema: Find the Difference.**

- **Pista 2 — patrón:** **XOR** o **suma de códigos** de todos los caracteres.
- **Pista 3 — diseño:** el XOR de todos los caracteres de `s` y de `t` deja solo el añadido, porque los demás aparecen dos veces; en Python, `chr(reduce(xor, map(ord, s + t)))`.

**05 → Problema: Minimum Absolute Difference.**

- **Pista 2 — patrón:** **ordenar y comparar vecinos**.
- **Pista 3 — diseño:** ordena, calcula la menor diferencia entre vecinos y recoge todos los pares vecinos con esa diferencia, en orden.

**05 → Problema: Mark and Toys.**

- **Pista 2 — patrón:** **voraz tras ordenar**: los más baratos primero.
- **Pista 3 — diseño:** ordena los precios y suma mientras no pases del presupuesto; la respuesta es cuántos sumaste.

**05 → Problema: K Closest Points to Origin.**

- **Pista 2 — patrón:** **montículo de tamaño `k`** que guarda los más cercanos y expulsa el más lejano.
- **Pista 3 — diseño:** necesitas sacar el **más lejano** de los `k`: un montículo de máximos por distancia al cuadrado (sin raíz); en Java, `PriorityQueue` con comparador invertido; en Python, `heapq` con la distancia negada.

**05 → Problema: Longest Consecutive Sequence.**

- **Pista 2 — patrón:** **conjunto *hash***, empezando solo desde el inicio de cada secuencia.
- **Pista 3 — diseño:** mete todos en un conjunto; para cada `x` cuyo `x − 1` no está, cuenta hacia arriba mientras `x + 1`, `x + 2`… estén; cada número se visita como mucho dos veces: `O(n)` esperado.

**05 → Problema: Design Front Middle Back Queue.**

- **Pista 2 — patrón:** **dos deques** que se mantienen balanceadas.
- **Pista 3 — diseño:** la mitad izquierda y la derecha, con la izquierda igual o con uno menos; el medio está en el final de la izquierda o el principio de la derecha según la paridad; tras cada operación, rebalancea moviendo un elemento.

**05 → Problema: Merge k Sorted Lists.**

- **Pista 2 — patrón:** **montículo de las cabezas** de las `k` listas.
- **Pista 3 — diseño:** mete la cabeza de cada lista no vacía; saca la menor, engánchala al resultado y mete su siguiente. En Python, la tupla es `(valor, contador, nodo)`, porque los nodos no se comparan.

**05 → Problema: Apartments.**

- **Pista 2 — patrón:** **ordenar y dos punteros**: no hace falta ninguna estructura ordenada.
- **Pista 3 — diseño:** ordena solicitantes y apartamentos; avanza el que esté por debajo de la tolerancia del otro y empareja cuando caben; la misma solución se escribe igual en los tres lenguajes.

---

# 06 — Competir sin arsenal: Go y JavaScript

**06 → 1.** ¿Qué cinco métodos exige `container/heap` en Go? 🟢

⏱️ **30 segundos.** `Len`, `Less`, `Swap`, `Push` y `Pop`: los tres primeros de `sort.Interface` y dos para añadir y quitar del final.

🗣️ **2 minutos.** `Len`, `Less` y `Swap` dejan al paquete comparar e intercambiar elementos; `Push(x any)` añade al final y `Pop() any` quita el último. Las funciones `heap.Init`, `heap.Push` y `heap.Pop` usan esos métodos para mantener el invariante.

🔬 **El detalle.** `Push` y `Pop` reciben el puntero (`*IntHeap`) porque cambian la longitud del *slice*; `Len`, `Less` y `Swap` pueden recibir el valor. Mezclar receptores de valor y puntero es la causa típica de que «no compile la interfaz».

**06 → 2.** ¿Hasta qué entero es exacto un `Number` de JavaScript? 🟢

⏱️ **30 segundos.** Hasta `Number.MAX_SAFE_INTEGER = 2⁵³ − 1`, unos `9·10¹⁵`.

🗣️ **2 minutos.** `Number` es un `double` con 53 bits de mantisa: todos los enteros hasta `2⁵³` se representan exactos; por encima, dos enteros consecutivos pueden compartir representación y las operaciones redondean sin avisar. `Number.isSafeInteger(x)` comprueba si un valor está en el rango seguro.

🔬 **El detalle.** El producto de dos números de `10⁹` ya está fuera, y por eso el producto modular necesita `BigInt` o partirse. Las sumas de `10⁵` valores de `10⁹` (`10¹⁴`) todavía son exactas.

**06 → 3.** ¿Qué da `[10, 9, 1].sort()` y por qué? 🟢

⏱️ **30 segundos.** `[1, 10, 9]`: sin comparador, `sort` convierte los elementos a cadenas y los ordena como texto, y `"10"` va antes que `"9"`.

🗣️ **2 minutos.** El comportamiento por defecto de `Array.prototype.sort` es comparar las representaciones de texto en orden de unidades de código UTF-16. Para números hay que pasar un comparador: `(x, y) => x - y`, que devuelve un negativo si `x` va antes.

🔬 **El detalle.** La resta como comparador es segura con números exactos, porque no desborda; con `BigInt` hay que devolver `-1`, `0` o `1` explícitamente (`x < y ? -1 : x > y ? 1 : 0`), porque `sort` espera un `Number`.

**06 → 4.** ¿Qué diferencia hay entre llamar a `heap.Pop(h)` y a `h.Pop()` en Go? 🟡

⏱️ **30 segundos.** `heap.Pop(h)` saca el mínimo y reordena; `h.Pop()` solo quita el último elemento del *slice*, que no es el mínimo, y rompe el invariante si se usa directamente.

🗣️ **2 minutos.** La función del paquete intercambia la raíz con el último, baja la nueva raíz con `Less` y `Swap`, y después llama a tu `Pop` para recortar el *slice*. Tu método es una pieza interna; llamarlo desde fuera es como hacer `pop_back` sobre el `vector` de un `priority_queue`.

🔬 **El detalle.** Lo mismo con `Push`: `heap.Push(h, x)` añade y sube; `h.Push(x)` solo añade al final. El error compila sin aviso, porque los dos son métodos válidos.

**06 → 5.** ¿Por qué `shift()` hace cuadrático un BFS en JavaScript, y qué se usa en su lugar? 🟡

⏱️ **30 segundos.** Porque `shift()` quita el primero y reindexa todo el arreglo, `O(n)`; un BFS que lo llama una vez por nodo es `O(V²)`. Se usa un arreglo con un índice de cabeza.

🗣️ **2 minutos.** El arreglo de JavaScript es indexado desde 0, y quitar el primero obliga a renumerar el resto. Con un índice `head` que avanza, sacar es leer `items[head++]`, `O(1)`, sin mover nada.

🔬 **El detalle.** Algunos motores optimizan `shift` en arreglos pequeños, pero no hay garantía, y con `10⁵` elementos el coste lineal aparece. La memoria de la cola con índice se recupera compactando cuando `head` pasa de la mitad.

**06 → 6.** ¿Qué diferencia hay entre `sort.Slice` y `sort.SliceStable` en Go? 🟡

⏱️ **30 segundos.** `sort.Slice` no es estable: los elementos iguales pueden cambiar de orden relativo; `sort.SliceStable` lo conserva.

🗣️ **2 minutos.** Los dos reciben el *slice* y una función `less(i, j)`. La estabilidad importa cuando se ordena por una clave y el orden previo codifica otra, como ordenar por puntuación conservando el orden de llegada.

🔬 **El detalle.** Desde Go 1.21, `slices.Sort` y `slices.SortFunc` son la forma moderna y genérica, más rápida que `sort.Slice` porque no usa reflexión; `slices.SortStableFunc` es la estable.

**06 → 7.** Compara cómo se obtiene un montículo de máximos en C++, Java, Python, Go y JavaScript. 🟠

⏱️ **30 segundos.** C++ lo da por defecto; Java, con `Collections.reverseOrder()`; Python, negando las prioridades; Go, con `Less` que devuelve `h[i] > h[j]`; JavaScript, con un comparador invertido en el montículo propio.

🗣️ **2 minutos.** C++ y Go eligen el orden en la definición del montículo; Java en el constructor; Python no puede, porque `heapq` solo hace mínimos hasta 3.13, y se invierte la clave; JavaScript no tiene montículo, así que el orden es el del comparador que escribes.

🔬 **El detalle.** Negar en Python falla con claves que no son números y con el valor mínimo de un tipo acotado; en Go y en JavaScript el comparador invertido no tiene ese problema.

**06 → 8.** ¿Por qué `(a * b) % MOD` da un resultado incorrecto en JavaScript con `a` y `b` cerca de `10⁹`, y qué dos alternativas hay? 🟠

⏱️ **30 segundos.** Porque `a * b` ronda `10¹⁸`, por encima de `2⁵³`, y el `double` ya lo redondeó antes del `%`. Alternativas: `BigInt`, o partir uno de los factores en dos mitades para que cada producto parcial quepa.

🗣️ **2 minutos.** Con `BigInt`: `Number(BigInt(a) * BigInt(b) % BigInt(MOD))`, exacto y más lento. Sin `BigInt`: escribir `b = bAlto · 2¹⁵ + bBajo`, multiplicar `a` por cada mitad (productos de unos `2⁴⁵`), reducir y combinar.

🔬 **El detalle.** El error es silencioso: el resultado es un número plausible en `[0, MOD)`. Es el mismo fallo que en `01/04`, con la diferencia de que en JavaScript ningún tipo de 64 bits lo evita.

**06 → 9.** ¿Qué puede pasar en Go si dos variables comparten un *slice* y una de ellas hace `append`? 🟠

⏱️ **30 segundos.** Que si el *slice* original tenía capacidad libre, `append` escribe en el mismo arreglo de respaldo y la otra variable ve el valor cambiado; si no la tenía, `append` crea un arreglo nuevo y ya no comparten.

🗣️ **2 minutos.** `b := a[:2]` comparte el arreglo con `a`. `b = append(b, 99)` escribe en la posición 2 del arreglo compartido, que es `a[2]`: `a` cambia sin que nadie la haya tocado. El comportamiento depende de la capacidad, que no se ve en el código.

🔬 **El detalle.** La defensa es copiar cuando hace falta independencia (`slices.Clone` desde 1.21, o `append([]int(nil), a...)`) o limitar la capacidad con la expresión de tres índices `a[:2:2]`, que obliga a `append` a reservar.

**06 → 10.** ¿Por qué `1 << 31` es negativo en JavaScript, y qué consecuencia tiene para un problema de máscaras de 40 bits? 🟠

⏱️ **30 segundos.** Porque los operadores de bits convierten a enteros de 32 bits con signo, y el bit 31 es el de signo. Con máscaras de 40 bits, `<<`, `&` y `|` sobre `Number` dan basura: hay que usar `BigInt` o partir la máscara.

🗣️ **2 minutos.** `1 << 31` es `−2147483648` y `1 << 32` es `1`, porque la cuenta del desplazamiento se toma módulo 32. Una máscara de 40 bits no cabe en esa conversión. Con `BigInt` (`1n << 39n`) los operadores de bits trabajan con precisión arbitraria; o se usan dos `Number` de 20 bits.

🔬 **El detalle.** `>>>` es el desplazamiento sin signo de 32 bits; no ayuda con más de 32 bits. Las máscaras de hasta 30 bits, que son las de las DP de [`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md) con `n ≤ 20`, sí son seguras.

**06 → 11.** Diseña en Go la estructura para un Dijkstra: el tipo del montículo, qué guarda cada elemento y cómo se descartan las entradas viejas. 🔴

⏱️ **30 segundos.** Un tipo `PQ []Item` con `Item{dist int64; node int}`, `Less` por `dist`, y los cinco métodos. Se mete `(dist, node)` cada vez que una distancia mejora, y al sacar se descarta si `dist` es mayor que la distancia guardada del nodo.

🗣️ **2 minutos.** Go no tiene `decrease-key`, igual que los demás: se reinserta y se usa eliminación perezosa. El bucle es: `for pq.Len() > 0 { it := heap.Pop(&pq).(Item); if it.dist > best[it.node] { continue }; relajar vecinos con heap.Push }`. Las distancias en `int64`.

🔬 **El detalle.** El montículo puede llegar a tener `O(E)` elementos por las reinserciones, y el coste queda en `O(E log E)`. La teoría está en [`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md), y el tipo se lleva escrito en el cuaderno de Go del bloque `23`.

**06 → 12.** Escribe cómo calcularías `a · b mod m` en JavaScript sin `BigInt`, con `a, b < m ≤ 10⁹ + 7`, y por qué ningún producto parcial pasa de `2⁵³`. 🔴

⏱️ **30 segundos.** Parto `b` en `bAlto = ⌊b / 2¹⁶⌋` y `bBajo = b mod 2¹⁶`; calculo `a · bAlto mod m`, lo multiplico por `2¹⁶` reduciendo, y le sumo `a · bBajo mod m`. Con `a < 2³⁰`, cada producto es menor que `2⁴⁶`.

🗣️ **2 minutos.** `a · b = a · bAlto · 2¹⁶ + a · bBajo`. `a · bAlto` es menor que `2³⁰ · 2¹⁴ = 2⁴⁴`, exacto; se reduce y queda menor que `2³⁰`. Multiplicarlo por `2¹⁶` da menos de `2⁴⁶`, exacto; se reduce. `a · bBajo` es menor que `2³⁰ · 2¹⁶ = 2⁴⁶`, exacto. La suma de dos restos es menor que `2³¹`. Ningún paso pasa de `2⁵³`.

🔬 **El detalle.** Con `m ≤ 10⁹ + 7 < 2³⁰`, los restos caben en 30 bits, y eso es lo que hace funcionar la cuenta. Es más rápido que `BigInt` en bucles largos y no necesita conversiones.

**06 → Problema: Suma sin redondeo.**

- **Pista 2 — patrón:** **tipo numérico** con el rango de la suma: llega a `2·10¹⁸`.
- **Pista 3 — diseño:** en Go, `int64` (el `int` de 64 bits también sirve) basta; en JavaScript, la suma pasa de `2⁵³` y hay que acumular en `BigInt` (`BigInt(x)` para cada valor leído como cadena).

**06 → Problema: Turnos por urgencia.**

- **Pista 2 — patrón:** **montículo de mínimos**, que ninguno de los dos lenguajes trae listo.
- **Pista 3 — diseño:** en Go, un `IntHeap` con `container/heap`; en JavaScript, el `MinHeap` de §6; `A` sobre el montículo vacío imprime `-1`. Con E/S rápida en los dos.

**06 → Problema: Producto modular.**

- **Pista 2 — patrón:** **multiplicación modular** que no puede desbordar el tipo.
- **Pista 3 — diseño:** en Go, multiplica en `int64` y reduce en cada paso (`10¹⁸ < 9,2·10¹⁸`); en JavaScript, `BigInt` en cada producto o la multiplicación partida en mitades de §5.

**06 → Problema: Big Sorting.**

- **Pista 2 — patrón:** **comparador propio** sobre cadenas numéricas, sin convertirlas.
- **Pista 3 — diseño:** sin ceros a la izquierda, un número con menos cifras es menor; a igual longitud, la comparación de texto coincide con la numérica. Ordena por `(longitud, cadena)`.

**06 → Problema: Last Stone Weight.**

- **Pista 2 — patrón:** **montículo de máximos** escrito a mano o con `container/heap`.
- **Pista 3 — diseño:** mete todas las piedras; mientras haya dos, saca las dos mayores y mete la diferencia si no es 0; en JavaScript, el `MinHeap` con comparador `(x, y) => x > y`.

**06 → Problema: Time Needed to Buy Tickets.**

- **Pista 2 — patrón:** **cola simulada** o una fórmula por persona.
- **Pista 3 — diseño:** cada persona antes de `k` aporta `min(tickets[i], tickets[k])`, y cada una después, `min(tickets[i], tickets[k] − 1)`; si simulas, la cola es un arreglo con índice de cabeza, no `shift()`.

**06 → Problema: Relative Ranks.**

- **Pista 2 — patrón:** **ordenar índices por puntuación** con comparador numérico.
- **Pista 3 — diseño:** ordena los índices por puntuación descendente con `(i, j) => score[j] - score[i]`; los tres primeros reciben las medallas y el resto su posición como texto.

**06 → Problema: Nesting.**

- **Pista 2 — patrón:** **contador de profundidad** en lugar de una pila.
- **Pista 3 — diseño:** suma uno con cada apertura y resta uno con cada cierre; si baja de cero, no está anidada; al final tiene que valer cero.

**06 → Problema: Extra Long Factorials.**

- **Pista 2 — patrón:** **enteros grandes**: `math/big` en Go, `BigInt` en JavaScript.
- **Pista 3 — diseño:** acumula el producto de 1 a `n` en un `big.Int` (con `Mul`) o en un `BigInt`, e imprímelo; `100!` tiene 158 cifras.

**06 → Problema: Reveal Cards In Increasing Order.**

- **Pista 2 — patrón:** **simulación con una cola de posiciones**.
- **Pista 3 — diseño:** ordena las cartas; mete las posiciones `0..n−1` en una cola; para cada carta en orden, saca una posición y le asigna la carta, y mueve la siguiente posición de la cola al final.

**06 → Problema: Dota2 Senate.**

- **Pista 2 — patrón:** **dos colas de índices**, una por partido.
- **Pista 3 — diseño:** en cada ronda compara los frentes: el de menor índice actúa, elimina al otro y vuelve a la cola con su índice más `n`; termina cuando una cola queda vacía.

**06 → Problema: Exponentiation II.**

- **Pista 2 — patrón:** **exponenciación modular** con el exponente reducido por el pequeño teorema de Fermat.
- **Pista 3 — diseño:** `a^(b^c) mod p` con `p = 10⁹ + 7` primo: calcula `e = b^c mod (p − 1)` y después `a^e mod p`; en JavaScript, los productos con `BigInt` o partidos.

**06 → Problema: Concert Tickets.**

- **Pista 2 — patrón:** **precios ordenados con «siguiente disponible»**: un Union-Find que salta vendidos, o *offline* con Fenwick.
- **Pista 3 — diseño:** ordena los precios; para cada cliente, busca con binaria el último precio `≤` su oferta y, si está vendido, salta al anterior disponible con un Union-Find que apunta de cada vendido a su vecino de la izquierda ([`08/04`](../08-heaps-y-union-find/04-union-find.md)).

---

# 07 — Simulación

**07 → S1.** ¿Qué devuelve `std::map::operator[]` con una clave que no existe, y qué efecto secundario tiene? 🟢

⏱️ **30 segundos.** Una referencia al valor por defecto, y como efecto secundario **inserta** la clave con ese valor.

🗣️ **2 minutos.** `m[k]` está pensado para escribir: si `k` no existe, la crea y devuelve una referencia a su valor recién construido. Si se usa para consultar, el mapa crece con claves que nunca se insertaron. Para consultar: `find`, `count` o `contains` (C++20).

🔬 **El detalle.** Por eso `operator[]` no existe en un `const map`; `at(k)` sí, y lanza `std::out_of_range` si no existe. Ver `03/01`, §5.

**07 → S2.** ¿Qué colección de Java usas como pila, y cuál como cola? 🟢

⏱️ **30 segundos.** `ArrayDeque` para las dos: `push`/`pop`/`peek` como pila y `offer`/`poll` como cola.

🗣️ **2 minutos.** `ArrayDeque` es un arreglo circular con `O(1)` en los dos extremos. `Stack` es una clase antigua, sincronizada y con acceso por índice; `LinkedList` funciona como cola pero crea un nodo por elemento.

🔬 **El detalle.** `poll` devuelve `null` con la cola vacía; guardarlo en un `int` lanza `NullPointerException`. Ver `03/03`, §3.

**07 → S3.** ¿Por qué `std::lower_bound(s.begin(), s.end(), x)` sobre un `std::set` es lento? 🟡

⏱️ **30 segundos.** Porque los iteradores de un `set` no son de acceso aleatorio: la búsqueda binaria genérica avanza paso a paso y queda en `O(n)`. Se usa el miembro `s.lower_bound(x)`, `O(log n)`.

🗣️ **2 minutos.** El algoritmo libre hace `O(log n)` comparaciones, pero para llegar al medio de un rango con iteradores bidireccionales tiene que avanzar uno a uno. El método miembro baja por el árbol directamente.

🔬 **El detalle.** Con `10⁵` consultas sobre un `set` de `10⁵`, la diferencia es `10¹⁰` pasos frente a `2·10⁶`. Ver `03/01`, §4.

**07 → S4.** ¿Qué diferencia hay entre `HashMap` y `TreeMap` en Java, en coste y en lo que permiten? 🟡

⏱️ **30 segundos.** `HashMap` es `O(1)` esperado y sin orden; `TreeMap` es `O(log n)` en el caso peor, ordenado, con sucesor, predecesor y rangos.

🗣️ **2 minutos.** `HashMap` reparte las claves por cubetas; desde Java 8, una cubeta llena se convierte en árbol y el caso peor baja a `O(log n)` con claves comparables. `TreeMap` es un árbol rojo-negro: `floorKey`, `ceilingKey`, `subMap` y el recorrido en orden.

🔬 **El detalle.** El *multiset* de Java es un `TreeMap` de conteos. Ver `03/03`, §4 y §5.

**07 → S5.** ¿Cuándo un `vector` ordenado gana a un `set`? 🟠

⏱️ **30 segundos.** Cuando los datos no cambian después de construirlos: se ordena una vez y las búsquedas son `O(log n)` sobre memoria contigua.

🗣️ **2 minutos.** El `vector` ordenado gasta menos memoria y toca menos líneas de caché que un árbol de nodos. Pero insertar en medio es `O(n)`, así que solo gana si las inserciones son raras o van todas antes de las consultas.

🔬 **El detalle.** Es el patrón «construir, ordenar, consultar» de la compresión de coordenadas (`04/04`).

**07 → S6.** ¿Qué condición tiene que cumplir el comparador de `std::sort`? 🟢

⏱️ **30 segundos.** Que sea un orden estricto débil: irreflexivo, asimétrico, transitivo y con la equivalencia transitiva.

🗣️ **2 minutos.** `<` lo cumple; `<=` no, porque `comp(a, a)` es cierto. Un comparador que viole el contrato produce comportamiento indefinido, y en libstdc++ puede salirse del arreglo.

🔬 **El detalle.** Un comparador de `double` con tolerancia rompe la transitividad de la equivalencia. Ver [`03/02`](02-cpp-algoritmos-ranges-y-pbds.md), §2.

**07 → S7.** ¿Qué diferencia hay entre `nth_element` y `partial_sort`? 🟡

⏱️ **30 segundos.** `nth_element` coloca un elemento en su sitio y parte el resto sin ordenar, en `O(n)` promedio; `partial_sort` deja ordenados los `k` primeros, en `O(n log k)`.

🗣️ **2 minutos.** Para la mediana o el `k`-ésimo, `nth_element`. Para los `k` menores **en orden**, `partial_sort`. Si solo hacen falta los `k` menores sin orden, `nth_element` y tomar los `k` primeros.

🔬 **El detalle.** `nth_element` es una selección rápida ([`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md)); su caso peor en libstdc++ está acotado porque cambia de estrategia si la recursión se hace profunda.

**07 → S8.** ¿Por qué `std::accumulate(v.begin(), v.end(), 0)` puede desbordar con `v` de `long long`? 🟡

⏱️ **30 segundos.** Porque el tipo del acumulador es el del valor inicial: con `0` es `int`, y cada suma parcial se trunca a 32 bits.

🗣️ **2 minutos.** `accumulate` suma en el tipo de su tercer argumento. Con `0LL`, el acumulador es `long long` y la suma es correcta. El error compila sin aviso con `-Wall -Wextra`.

🔬 **El detalle.** Es el desbordamiento de `01/04` escondido en una llamada de librería. Ver `03/02`, §6.

**07 → S9.** ¿Qué garantiza `Arrays.sort` sobre `int[]` en Java 21, y qué cambia en Java 11? 🟠

⏱️ **30 segundos.** En Java 21 garantiza `O(n log n)` en el caso peor: el *quicksort* de doble pivote cambia a *heapsort* si la recursión se hace demasiado profunda. En Java 11 no tenía ese respaldo y había entradas que lo hacían cuadrático.

🗣️ **2 minutos.** El respaldo entró en Java 14. Si el juez corre Java 8 u 11 y hay casos adversarios, se baraja el arreglo antes de ordenar o se ordenan objetos, que usan TimSort.

🔬 **El detalle.** Comprobado en el código fuente de OpenJDK 11, 13, 14, 17 y 21. Ver `03/03`, §7.

**07 → S10.** ¿Por qué `list.pop(0)` no sirve para una cola? 🟢

⏱️ **30 segundos.** Porque es `O(n)`: quita el primero y desplaza todos los demás. Una cola con `pop(0)` es cuadrática; la cola de Python es `collections.deque`.

🗣️ **2 minutos.** `list` es un arreglo contiguo; quitar del principio obliga a mover el resto. `deque.popleft()` es `O(1)` porque está hecha de bloques enlazados.

🔬 **El detalle.** El mismo error existe en JavaScript con `shift()` y en Java con `ArrayList.remove(0)`. Ver `03/04`, §2 y §4.

**07 → S11.** ¿Cómo haces un montículo de máximos con `heapq` en Python 3.12? 🟡

⏱️ **30 segundos.** Negando las prioridades: `heappush(h, -x)` y `-heappop(h)`.

🗣️ **2 minutos.** `heapq` solo hace mínimos hasta Python 3.13. Con tuplas, se niega el componente que ordena: `(-prioridad, contador, dato)`, con un contador de desempate si los datos no se comparan.

🔬 **El detalle.** Python 3.14 añade funciones públicas de máximos, fuera del techo del corpus. Ver `03/04`, §5.

**07 → S12.** ¿Qué haces en Python cuando necesitas un mapa ordenado con inserciones y borrados? 🟠

⏱️ **30 segundos.** No hay en la librería: lista ordenada con `insort` si `n` es pequeño, compresión y Fenwick si las operaciones se conocen antes, o un *treap* escrito a mano si son *online*.

🗣️ **2 minutos.** `insort` es `O(n)` por inserción y entra con unos `10⁵` elementos. La versión *offline* da `O(log n)` sobre listas de enteros. El *treap* da `O(log n)` esperado con constante alta.

🔬 **El detalle.** La «lista de raíz cuadrada» (bloques ordenados de tamaño `√n`) es otra opción con poco código. Ver `03/05`, §5.

**07 → S13.** Una recursión de profundidad `10⁵` da RE en Python con el límite subido. ¿Qué falta? 🟠

⏱️ **30 segundos.** La pila del hilo: hay que ejecutar el programa en un hilo creado después de `threading.stack_size` con un tamaño grande.

🗣️ **2 minutos.** `setrecursionlimit` solo cambia el contador de Python; la pila de C del intérprete sigue siendo la del hilo principal, y se desborda. Con un hilo de pila grande, la recursión cabe.

🔬 **El detalle.** La solución más robusta es convertir la recursión en un bucle con pila explícita. Ver `03/04`, §8.

**07 → S14.** ¿Qué da `[10, 9, 1].sort()` en JavaScript? 🟢

⏱️ **30 segundos.** `[1, 10, 9]`: sin comparador, ordena como texto.

🗣️ **2 minutos.** `sort` convierte los elementos a cadenas y compara unidades de código; `"10"` va antes que `"9"`. Para números, `sort((x, y) => x - y)`.

🔬 **El detalle.** Con `BigInt`, el comparador tiene que devolver un `Number` (`-1`, `0`, `1`). Ver [`03/06`](06-sin-arsenal-go-y-javascript.md), §6.

**07 → S15.** ¿Por qué no se llama a `h.Pop()` directamente sobre un montículo de `container/heap`? 🟡

⏱️ **30 segundos.** Porque tu `Pop` solo quita el último del *slice*; el que reordena es `heap.Pop(h)`, que llama a tu método como pieza interna.

🗣️ **2 minutos.** `heap.Pop` intercambia la raíz con el último, baja la nueva raíz y después llama a `h.Pop()` para recortar. Llamar a `h.Pop()` directamente saca un elemento cualquiera y deja el montículo inválido.

🔬 **El detalle.** El error compila sin aviso. Ver `03/06`, §3.

**07 → S16.** ¿Por qué `(a * b) % MOD` falla en JavaScript con `a` y `b` cerca de `10⁹`? 🟠

⏱️ **30 segundos.** Porque el producto ronda `10¹⁸`, por encima de `2⁵³`, y el `double` ya lo redondeó antes del `%`.

🗣️ **2 minutos.** `Number` es exacto solo hasta `2⁵³ − 1`. El resultado es un número plausible e incorrecto. Las salidas son `BigInt` o partir un factor en mitades de 16 bits.

🔬 **El detalle.** Ver `03/06`, §5, y la cuenta de que ningún producto parcial pasa de `2⁴⁶`.

**07 → S17.** Traduces de C++ a Java un Dijkstra con `priority_queue` y `-dist`. Compila y da distancias incorrectas. ¿Qué pasó? 🟠

⏱️ **30 segundos.** Que el `priority_queue` de C++ es de máximos y la `PriorityQueue` de Java de mínimos: con `-dist`, en Java sale primero la mayor distancia.

🗣️ **2 minutos.** En C++ se niega la distancia para sacar la menor de un montículo de máximos. Traducido literal, en Java se niega en un montículo de mínimos, y el orden queda invertido. La corrección es quitar la negación en Java.

🔬 **El detalle.** El segundo sospechoso es el comparador con resta, que desborda, y el tercero, el tipo de las distancias (`long`).

**07 → S18.** Tu solución Java compara dos conteos de un `HashMap` con `==` y pasa los ejemplos. ¿Por qué falla en el caso grande? 🟠

⏱️ **30 segundos.** Porque `==` entre dos `Integer` compara referencias, y la caché de `Integer.valueOf` solo comparte los objetos de −128 a 127: los conteos pequeños coinciden por casualidad, los grandes no.

🗣️ **2 minutos.** Los ejemplos tienen conteos pequeños; el caso grande tiene conteos de cientos o miles, y cada `get` devuelve un objeto distinto. Se compara con `equals`, o desempaquetando uno.

🔬 **El detalle.** Es el problema de `03/03`, §1, y el propio «Frecuencias gemelas» de esta simulación.

**07 → S19.** ¿Y si `n` fuera `10⁶` y tu lenguaje fuera Python? Para una cola con `10⁶` operaciones, ¿qué cambia en tu código? 🟠

⏱️ **30 segundos.** Que la cola tiene que ser un `deque` y la E/S en bloque: con `list.pop(0)`, `10⁶` extracciones son cuadráticas.

🗣️ **2 minutos.** Con `10⁶` operaciones, cualquier coste lineal por operación es fatal, y además cada operación del intérprete cuenta. `deque`, lectura con `sys.stdin.buffer.read().split()` y una sola escritura al final.

🔬 **El detalle.** Es el problema propio «Cola de la ventanilla». Si aun así va justo, se mueve el bucle a una función para usar variables locales (`03/04`, §9).

**07 → S20.** Un *multiset* de C++ con `erase(x)` da WA solo cuando hay repetidos. ¿Por qué no lo detectaron los ejemplos? 🟠

⏱️ **30 segundos.** Porque con valores distintos `erase(x)` y `erase(find(x))` hacen lo mismo, y los ejemplos suelen tener valores distintos.

🗣️ **2 minutos.** `erase(x)` borra todas las copias; el error solo se manifiesta cuando el valor borrado tenía repetidos, y casi nunca en un ejemplo pensado para ilustrar.

🔬 **El detalle.** Un *stress test* con valores en un rango pequeño ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)) lo encuentra enseguida, porque fuerza repetidos. Ver `03/01`, §4.

**07 → S21.** «Python no tiene `TreeMap`, así que no se puede usar en pruebas con mapas ordenados.» Corrige la frase con tres sustitutos y cuándo vale cada uno. 🔴

⏱️ **30 segundos.** Hay tres sustitutos: lista ordenada con `bisect.insort` si `n` ronda `10⁵`; compresión de coordenadas y Fenwick si las operaciones se conocen de antemano; un *treap* o una lista de bloques si son *online* y grandes.

🗣️ **2 minutos.** `insort` es `O(n)` por inserción con constante de C. El Fenwick *offline* es `O(log n)` sobre enteros y el más rápido en Python. El *treap* es `O(log n)` esperado y el más general, con constante alta.

🔬 **El detalle.** La frase correcta es «Python no tiene mapa ordenado en la librería estándar; hay que elegir el sustituto según las restricciones antes de empezar». Ver `03/05`, §5.

**07 → S22.** Escribe el patrón de eliminación perezosa para una cola de prioridad sin `decrease-key`, y por qué no rompe la corrección. 🔴

⏱️ **30 segundos.** Al cambiar la prioridad de un elemento, se mete de nuevo con la prioridad nueva; al sacar, se descarta si su prioridad ya no coincide con la guardada como vigente.

🗣️ **2 minutos.** En Dijkstra: se mete `(d, v)` cada vez que `dist[v]` mejora; al sacar `(d, v)`, si `d > dist[v]`, es una entrada vieja y se ignora. La primera vez que sale `v` con su distancia vigente, esa es la definitiva.

🔬 **El detalle.** No rompe la corrección porque las entradas viejas nunca se procesan, y la vigente sale antes que cualquier entrada vieja del mismo nodo, que tiene prioridad peor. El coste sube a `O(E log E)` por las reinserciones. Ver `15/01`.

**07 → Problema: Almacén de tallas.**

- **Pista 2 — patrón:** ***multiset* con sucesor**: `std::multiset` en C++, `TreeMap` de conteos en Java, sustituto en Python.
- **Pista 3 — diseño:** `+ x` inserta una copia; `- x` quita **una** (`erase(find(x))`, o decrementar y borrar al llegar a 0); `? x` es `lower_bound(x)` o `ceilingKey(x)`. En Python, como las operaciones se leen todas antes de responder, compresión de coordenadas y Fenwick de conteos.

**07 → Problema: Cola de la ventanilla.**

- **Pista 2 — patrón:** **simulación con una cola `O(1)`**: `deque`, `ArrayDeque` o `std::queue`.
- **Pista 3 — diseño:** mete pares `(persona, entradas que faltan)`; en cada turno, saca el primero, resta una; si llega a 0, anótalo en la salida; si no, vuelve al final. Son `Σ t ≤ 10⁶` turnos.

**07 → Problema: Frecuencias gemelas.**

- **Pista 2 — patrón:** **conteo** y comparación directa de pares, o agrupar por frecuencia.
- **Pista 3 — diseño:** cuenta cada valor; con `n ≤ 2000` hay como mucho 2000 valores distintos y compararlos todos son `2·10⁶` pares; o mejor, cuenta cuántos valores tienen cada frecuencia `f` y suma `c(c − 1)/2`. En Java, los conteos se comparan como `int`, no con `==` entre `Integer`.

**07 → Problema: Kth Largest Element in a Stream.**

- **Pista 2 — patrón:** **montículo de mínimos de tamaño `k`**.
- **Pista 3 — diseño:** guarda solo los `k` mayores; al añadir, mete y, si pasa de `k`, saca el mínimo; el `k`-ésimo mayor es el mínimo del montículo.

**07 → Problema: Collections.OrderedDict().**

- **Pista 2 — patrón:** **diccionario con orden de inserción** que acumula.
- **Pista 3 — diseño:** suma el precio de cada artículo en un `dict` (u `OrderedDict`); imprime en el orden de primera aparición, que el `dict` ya conserva desde 3.7.

**07 → Problema: Majority Element II.**

- **Pista 2 — patrón:** **voto de Boyer-Moore con dos candidatos**: como mucho dos valores pasan de `n/3`.
- **Pista 3 — diseño:** mantén dos candidatos con sus contadores; un valor que no es ninguno, si hay un contador en 0, ocupa ese hueco; si no, decrementa los dos; al final, cuenta de verdad las apariciones de los dos candidatos.

**07 → Problema: Minimum Number of Arrows to Burst Balloons.**

- **Pista 2 — patrón:** **voraz por el final** (`02/04`) con un comparador que no desborde.
- **Pista 3 — diseño:** ordena por extremo derecho con `Integer.compare`, no con una resta, porque los extremos llegan a `±2³¹`; dispara en el final del primero no reventado y salta todos los que empiezan antes o en ese punto.

**07 → Problema: Josephus Problem I.**

- **Pista 2 — patrón:** **simulación con una cola**: el niño que se salva vuelve al final.
- **Pista 3 — diseño:** mete `1..n` en una cola; repite: el primero vuelve al final, el siguiente sale y se imprime; son `2n` operaciones `O(1)`.

**07 → Problema: Sum of Two Values.**

- **Pista 2 — patrón:** **diccionario de valor a índice** con el complemento.
- **Pista 3 — diseño:** recorre guardando el índice de cada valor visto; para `a[i]`, busca `x − a[i]` entre los anteriores; si está, imprime los dos índices desde 1. Con un adversario, ordenar con dos punteros evita el *hash*.
