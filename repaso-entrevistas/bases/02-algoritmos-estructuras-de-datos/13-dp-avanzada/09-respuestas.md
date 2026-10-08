# Respuestas — bloque 13: DP avanzada

> Solucionario del bloque `13`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--dp-con-máscaras-de-bits) · [02](#02--digit-dp) · [03](#03--dp-en-árboles-y-en-dag) · [04](#04--dp-de-probabilidad-y-esperanza) · [05](#05--optimizaciones-de-dp) · [06](#06--recurrencias-lineales-y-exponenciación-de-matrices) · [07](#07--trucos-de-nivel-alto) · [08](#08--simulación)

---

# 01 — DP con máscaras de bits

**01 → 1.** ¿Qué estado usa Held-Karp y cuántos estados hay? 🟢

⏱️ **30 segundos.** `dp[S][v]`: el coste mínimo de un camino que sale de 0, visita exactamente `S` y acaba en `v`. Hay `2ⁿ · n` estados.

🗣️ **2 minutos.** El conjunto visitado y el vértice actual son todo lo que el futuro necesita; el orden de la visita no. Cada estado prueba `n` siguientes: `Θ(2ⁿ · n²)`.

🔬 **El detalle.** Con el vértice de partida fijo, solo cuentan las máscaras que lo contienen: la mitad.

**01 → 2.** ¿Cuánto cuesta recorrer todas las submáscaras de todas las máscaras de `n` bits, y por qué? 🟢

⏱️ **30 segundos.** `Θ(3ⁿ)`: cada bit está fuera de la máscara, dentro de la máscara y no en la submáscara, o en las dos; tres situaciones por bit.

🗣️ **2 minutos.** `Σ_m 2^popcount(m) = Σ_k C(n, k) 2ᵏ = 3ⁿ` por el binomio. Con `n = 16`, `4,3·10⁷`; con `n = 20`, `3,5·10⁹`, que ya no cabe.

🔬 **El detalle.** El bucle `s = (s − 1) & m` da cada submáscara en `O(1)`, así que el total es exactamente el número de pares.

**01 → 3.** ¿Qué calcula la SOS DP y en cuánto tiempo? 🟢

⏱️ **30 segundos.** Para cada máscara `m`, la suma de `f` sobre todas sus submáscaras. En `Θ(2ⁿ · n)`.

🗣️ **2 minutos.** Se procesa bit a bit: con el bit `b` encendido, `F[m] += F[m sin b]`. Tras los `n` bits, cada `F[m]` contiene exactamente una vez cada submáscara.

🔬 **El detalle.** Es una suma de prefijos en un hipercubo de `n` dimensiones con dos valores por dimensión; sirve también con máximos, mínimos y OR.

**01 → 4.** ¿Por qué en la asignación por máscaras el estado no necesita guardar qué persona toca? 🟡

⏱️ **30 segundos.** Porque la persona que toca es `popcount(m)`: si se asignan en orden, el número de tareas usadas dice cuántas personas ya tienen una.

🗣️ **2 minutos.** Fijar el orden de las personas hace que cada asignación completa tenga un único camino en la DP, y elimina una dimensión del estado: `2ⁿ` estados en lugar de `2ⁿ · n`.

🔬 **El detalle.** Es el mismo truco de «orden canónico» que evita contar dos veces en [`12/06`](../12-dp-clasica/06-conteo.md).

**01 → 5.** ¿Por qué el orden numérico de las máscaras es un orden válido de cálculo? 🟡

⏱️ **30 segundos.** Porque la transición solo añade elementos, y añadir un bit hace la máscara numéricamente mayor: las dependencias siempre apuntan a máscaras menores.

🗣️ **2 minutos.** `m | (1 << j) > m` si `j ∉ m`. Así el recorrido de 0 a `2ⁿ − 1` es un orden topológico. Si la transición quitara elementos, el recorrido iría al revés.

🔬 **El detalle.** También vale recorrer por número de bits (todas las de 1 bit, luego las de 2…), que a veces se usa para reducir memoria.

**01 → 6.** ¿Por qué en SOS el bucle de bits va por fuera? 🟡

⏱️ **30 segundos.** Para que cada submáscara llegue a cada máscara por un único camino. Con las máscaras por fuera, una submáscara que difiere en varios bits llegaría por varios órdenes y se sumaría de más.

🗣️ **2 minutos.** Con el bit por fuera, cuando se procesa el bit `b`, `F[m]` ya agrupa las submáscaras que difieren en los bits `< b`; el paso añade las que además difieren en `b`. El orden de los bits fija un camino canónico.

🔬 **El detalle.** Es el mismo principio de la suma de prefijos en dos dimensiones: primero por filas, después por columnas, nunca mezclado.

**01 → 7.** Compara cómo cuentas los bits de una máscara y cómo representas `2ⁿ` estados en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `__builtin_popcount` (o `std::popcount` desde C++20) y `std::vector` de `1 << n`. Java: `Integer.bitCount` y arreglos de `1 << n`. Python: `bin(m).count("1")` o `m.bit_count()` (desde 3.10), y listas de `1 << n`, que con `n = 20` ya pesan.

🗣️ **2 minutos.** En Python, `2²⁰ · 20` operaciones de Held-Karp tardan minutos: es un algoritmo de C++ o Java. Una lista de `2²⁰` enteros ocupa 8 MB de referencias más los objetos.

🔬 **El detalle.** En JavaScript, los operadores de bits trabajan con 32 bits con signo: hasta `n = 30` funcionan, pero `1 << 31` es negativo.

**01 → 8.** Deriva la recurrencia de Held-Karp y explica por qué el principio de optimalidad se cumple. 🟠

⏱️ **30 segundos.** `dp[S ∪ {u}][u] = min_v dp[S][v] + w(v, u)`. El principio se cumple porque el coste de completar un recorrido desde «visité `S` y estoy en `v`» no depende del orden en que se visitó `S`.

🗣️ **2 minutos.** Dos recorridos parciales con el mismo `S` y el mismo final tienen exactamente las mismas continuaciones válidas y con los mismos costes; por tanto basta guardar el más barato de los dos. Eso es lo que hace la tabla.

🔬 **El detalle.** El estado `(S, v)` es mínimo: sin `v` no se sabría el coste de la siguiente arista; sin `S`, qué vértices faltan.

**01 → 9.** ¿Cómo cambias Held-Karp para un camino que puede acabar en cualquier vértice, o empezar en cualquiera? 🟠

⏱️ **30 segundos.** Para un camino sin vuelta, la respuesta es `min_v dp[todos][v]`, sin sumar la arista de regreso. Para empezar en cualquier vértice, se inicializan todos los `dp[{v}][v] = 0`.

🗣️ **2 minutos.** La recurrencia no cambia; solo cambian los casos base y la respuesta. Con inicio libre, ya no se pueden saltar las máscaras sin el 0.

🔬 **El detalle.** Es CSES Hamiltonian Flights con inicio y fin fijos, contando caminos en lugar de minimizando.

**01 → 10.** ¿Cómo calculas la suma sobre **supermáscaras** en lugar de submáscaras? 🟠

⏱️ **30 segundos.** Igual que SOS pero con el bit **apagado**: si `m` no tiene el bit `b`, `F[m] += F[m | (1 << b)]`.

🗣️ **2 minutos.** Las supermáscaras de `m` son las submáscaras de su complemento, vistas al revés. El bucle de bits sigue por fuera.

🔬 **El detalle.** Con las dos sumas se resuelven problemas como «cuántos `y` cumplen `x | y = x`, `x & y = x` y `x & y ≠ 0`» (CSES SOS Bit Problem).

**01 → 11.** Demuestra que `s = (s − 1) & m` recorre exactamente las submáscaras de `m`. 🔴

⏱️ **30 segundos.** `s − 1` apaga el bit más bajo de `s` y enciende los de debajo; el `& m` deja solo los de `m`. El resultado es la mayor submáscara de `m` menor que `s`. Empezando en `m`, se recorren todas en orden decreciente.

🗣️ **2 minutos.** Si se ven las submáscaras de `m` como números de `popcount(m)` bits (comprimiendo los bits de `m`), la operación es exactamente restar 1 en ese número comprimido. Por eso pasa por todos los valores de `2^popcount − 1` a 0.

🔬 **El detalle.** El bucle `for (s = m; s > 0; …)` no incluye la vacía; si hace falta, se trata aparte.

**01 → 12.** Partir `n ≤ 16` tareas en grupos que caben en un camión de capacidad `C`, minimizando los viajes: diseña la DP y di su coste. 🔴

⏱️ **30 segundos.** `dp[m]` = el mínimo de viajes para llevar los objetos de `m`; `dp[m] = min dp[m \ s] + 1` sobre las submáscaras `s` de `m` que caben en el camión. `Θ(3ⁿ)`, con `n = 16` unos `4·10⁷`.

🗣️ **2 minutos.** Precalcular el peso de cada máscara (`2ⁿ`) hace la comprobación `O(1)`. Una alternativa en `Θ(2ⁿ · n)` guarda en cada estado el par (viajes, peso del último viaje), que es CSES Elevator Rides.

🔬 **El detalle.** Para no contar cada partición en todos sus órdenes, se puede obligar a que `s` contenga el bit más bajo de `m`.

**01 → 13.** Tu Held-Karp en Java da MLE con `n = 20`. ¿Qué cambias? 🔴

⏱️ **30 segundos.** La representación de la tabla: un único `long[]` (o `int[]` si cabe) de tamaño `(1 << n) · n` en lugar de `long[1 << n][n]`, y saltar o no reservar las máscaras sin el 0.

🗣️ **2 minutos.** `long[1 << 20][20]` son un millón de arreglos con su cabecera (~16 bytes cada uno) más 160 MB de datos. Con un arreglo plano de `int` (si los costes caben), 80 MB; y como solo cuentan las máscaras con el bit 0, se puede indexar con `S >> 1` y quedarse en 40 MB.

🔬 **El detalle.** El tiempo también mejora: un arreglo plano es contiguo en memoria.

**01 → Problema: Asignación de turnos.**

- **Pista 2 — patrón:** **asignación por máscaras**: el trabajador que toca es el número de turnos ya dados.
- **Pista 3 — diseño:** `dp[m]` = la mejor satisfacción dando los turnos de `m` a los trabajadores `0..|m| − 1`; empuja `dp[m | bit] = max(dp[m] + g[|m|][j])`. `2²⁰ · 20 ≈ 2·10⁷`.

**01 → Problema: Ruta por todas las tiendas.**

- **Pista 2 — patrón:** **Held-Karp** para un camino que empieza en 0 y no vuelve.
- **Pista 3 — diseño:** `dp[S][v]` con `dp[{0}][0] = 0`; la respuesta es `min_v dp[todos][v]`. `2¹⁸ · 18² ≈ 8,5·10⁷`. Con `n = 1`, 0.

**01 → Problema: Submáscaras de cada consulta.**

- **Pista 2 — patrón:** **SOS DP** sobre las cuentas de cada valor.
- **Pista 3 — diseño:** `F[x]` = cuántas veces aparece `x`; aplica SOS (bit por fuera) sobre `2²⁰` máscaras y responde cada consulta con `F[x]`. Lectura y escritura rápidas: `10⁶` números.

**01 → Problema: Hamiltonian Flights.**

- **Pista 2 — patrón:** **caminos hamiltonianos por máscaras**, contando.
- **Pista 3 — diseño:** `dp[S][v]` = número de rutas de 1 a `v` que visitan exactamente `S`; empuja por las aristas; la respuesta es `dp[todos][n]`. Poda: solo extender estados con el 1 y sin el `n` salvo en la máscara completa.

**01 → Problema: Elevator Rides.**

- **Pista 2 — patrón:** **máscara con un estado extra**: el par (viajes, peso del último).
- **Pista 3 — diseño:** `best[m]` = el par mínimo (viajes, peso del viaje en curso) para subir a las personas de `m`; al añadir una persona, si cabe en el viaje en curso se suma al peso; si no, abre un viaje nuevo. Orden lexicográfico del par.

**01 → Problema: Matching.**

- **Pista 2 — patrón:** **asignación por máscaras** contando emparejamientos.
- **Pista 3 — diseño:** `dp[m]` = formas de emparejar a los hombres `0..|m| − 1` con las mujeres de `m`; `dp[m | 1 << j] += dp[m]` si el hombre `|m|` es compatible con `j`; módulo `10⁹ + 7`.

**01 → Problema: Shortest Path Visiting All Nodes.**

- **Pista 2 — patrón:** **BFS sobre estados (máscara, nodo)**.
- **Pista 3 — diseño:** empieza en todos los `({v}, v)` a distancia 0; los vecinos de `(m, v)` son `(m | {u}, u)`; la primera vez que aparece la máscara completa es la respuesta.

**01 → Problema: Minimum XOR Sum of Two Arrays.**

- **Pista 2 — patrón:** **asignación por máscaras**.
- **Pista 3 — diseño:** `dp[m]` = la mínima suma emparejando los `|m|` primeros de `nums1` con los elementos de `nums2` de `m`; `dp[m | bit] = min(dp[m] + (nums1[|m|] ^ nums2[j]))`.

**01 → Problema: Parallel Courses II.**

- **Pista 2 — patrón:** **submáscaras** de los cursos disponibles.
- **Pista 3 — diseño:** `dp[m]` = semestres mínimos para haber hecho `m`; los disponibles son los no hechos cuyos prerrequisitos están en `m`; si son `≤ k`, se hacen todos; si no, se recorren sus submáscaras de tamaño `k`.

**01 → Problema: Number of Ways to Wear Different Hats to Each Other.**

- **Pista 2 — patrón:** **máscara sobre el lado pequeño** (las personas) y bucle sobre los sombreros.
- **Pista 3 — diseño:** `dp[h][m]` = formas de repartir los sombreros `1..h` entre las personas de `m`; para el sombrero `h`, o nadie lo lleva, o lo lleva una persona de `m` que lo admite. `40 · 2¹⁰ · 10`.

**01 → Problema: SOS Bit Problem.**

- **Pista 2 — patrón:** **SOS** sobre submáscaras y sobre supermáscaras.
- **Pista 3 — diseño:** `x | y = x` cuenta las submáscaras de `x` (SOS); `x & y = x`, las supermáscaras (SOS al revés); `x & y ≠ 0` es `n` menos las `y` que son submáscaras del complemento de `x`.

**01 → Problema: Compatible Numbers.**

- **Pista 2 — patrón:** **SOS con un testigo**: `a & b = 0` si y solo si `b` es submáscara del complemento de `a`.
- **Pista 3 — diseño:** `T[m]` = algún elemento que sea submáscara de `m` (o −1); propaga con SOS guardando un testigo en lugar de una suma; para cada `a`, mira `T[~a & (2²² − 1)]`.

**01 → Problema: Counting Tilings.**

- **Pista 2 — patrón:** **DP de perfil**: máscara de la columna siguiente ya ocupada.
- **Pista 3 — diseño:** columna a columna, el estado es qué casillas de la columna actual ya están cubiertas por fichas horizontales de la anterior; se rellena la columna por recursión fila a fila decidiendo ficha vertical u horizontal, y se obtiene la máscara de la siguiente. `m · 4ⁿ` en el peor caso, con `n ≤ 10`.

---

# 02 — *Digit DP*

**02 → 1.** ¿Por qué la cuenta de `[a, b]` es `f(b) − f(a − 1)`? 🟢

⏱️ **30 segundos.** Porque los números de `[a, b]` son los de `[0, b]` menos los de `[0, a − 1]`, y contar hasta un límite es lo que sabe hacer la DP.

🗣️ **2 minutos.** `f(N)` cuenta en `[0, N]`; el rango es una diferencia de dos prefijos, como las sumas de prefijos de [`04/01`](../04-secuencias/01-prefijos-y-diferencias.md). Con `a = 0`, `f(−1) = 0`.

🔬 **El detalle.** Si `a` y `b` vienen como cadenas de cientos de cifras, `a − 1` se calcula como resta de cadenas, o se cuenta `f(b) − f(a)` y se suma 1 si `a` cumple.

**02 → 2.** ¿Qué significa el indicador `tight` y cuándo se apaga? 🟢

⏱️ **30 segundos.** Que las cifras puestas hasta ahora coinciden exactamente con las del límite, así que la cifra actual no puede pasar de la del límite. Se apaga en cuanto se pone una cifra menor que la del límite, y ya no vuelve.

🗣️ **2 minutos.** Con `tight`, la cifra actual va de 0 a `d_pos`; si se elige `d_pos`, el siguiente sigue con `tight`; si se elige menos, todas las siguientes son libres (0–9). Es lo que garantiza no pasar de `N`.

🔬 **El detalle.** Algunos lo escriben al revés, con un indicador «ya es menor»; es lo mismo negado.

**02 → 3.** ¿Cuántos estados tiene la *digit DP* de la suma de dígitos módulo `k` con `N = 10¹⁸`? 🟢

⏱️ **30 segundos.** `L · k` estados libres (con `L = 19` cifras), más el camino pegado; con `k = 200`, unos 3 800, por 10 transiciones cada uno.

🗣️ **2 minutos.** `tight` duplica nominalmente los estados, pero los pegados forman un único camino de `L` nodos. El coste total es unos `L · k · 10`, insignificante.

🔬 **El detalle.** Por eso la *digit DP* llega a `10¹⁸`: el número de cifras es logarítmico en `N`.

**02 → 4.** ¿Por qué solo se memoizan los estados con `tight` apagado? 🟡

⏱️ **30 segundos.** Porque con `tight` encendido hay un único camino (el prefijo de `N`) y su valor depende de `N`; los libres, en cambio, se repiten muchas veces y no dependen de `N` más que por la posición.

🗣️ **2 minutos.** Si se guardaran en la misma tabla sin distinguir `tight`, un estado pegado contaminaría la cuenta de uno libre con la misma `(pos, extra)`. Memoizar solo los libres es la forma más simple de evitarlo; la otra es incluir `tight` en el estado.

🔬 **El detalle.** Indexando por «cifras que quedan» en lugar de por posición, los estados libres valen para cualquier `N` con el mismo número de cifras restantes.

**02 → 5.** ¿Cuándo hacen falta los ceros a la izquierda en el estado, y qué indicador se añade? 🟡

⏱️ **30 segundos.** Cuando la propiedad cambia con los ceros iniciales: contar cifras, mirar la primera, «sin cifras repetidas», «no decrecientes». Se añade `started`: si el número aún no ha empezado, un 0 no es una cifra.

🗣️ **2 minutos.** Con `started = no`, poner 0 deja `started = no` y no toca `extra`; poner otra cifra lo enciende. La suma de dígitos no lo necesita porque sumar ceros no cambia nada.

🔬 **El detalle.** El número 0 es el camino con `started = no` hasta el final; se decide aparte si cuenta.

**02 → 6.** ¿Qué `extra` lleva el estado para «divisible por `m`»? 🟡

⏱️ **30 segundos.** El resto del número formado hasta ahora módulo `m`: al añadir la cifra `c`, pasa a `(resto · 10 + c) mod m`.

🗣️ **2 minutos.** Es la regla de Horner: el valor se construye de izquierda a derecha multiplicando por la base. Con `m ≤ 100`, son `L · m` estados libres.

🔬 **El detalle.** Combinado con la suma de dígitos («divisible por la suma de sus cifras»), se itera sobre la suma objetivo `s` y se lleva `(suma, resto mod s)`.

**02 → 7.** Compara cómo obtienes las cifras de un `long` de 18 cifras en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `std::to_string(N)`. Java: `Long.toString(N).toCharArray()`. Python: `str(N)`. En los tres, la cifra es `c − '0'` o `int(c)`.

🗣️ **2 minutos.** También se pueden extraer con `% 10` y `/ 10` en un bucle, que da las cifras al revés. `10¹⁸` cabe en `long long` y `long` (hasta `9,2·10¹⁸`); si el límite viene como cadena más larga, se trabaja directamente con la cadena.

🔬 **El detalle.** En JavaScript, `10¹⁸` no es exacto en `number`: se lee como cadena o como `BigInt`.

**02 → 8.** Demuestra que cada número de `[0, N]` corresponde a exactamente un camino de la DP. 🟠

⏱️ **30 segundos.** Cada número de `[0, N]`, escrito con `L` cifras con ceros a la izquierda, define una cifra por posición; la DP sigue esas elecciones, y `tight` se apaga justo en la primera posición donde el número baja del límite. Un camino distinto daría otro número, y un número mayor que `N` no tiene camino.

🗣️ **2 minutos.** Inyectividad: dos números distintos difieren en alguna cifra, luego en algún paso. Sobreyectividad sobre `[0, N]`: mientras sus cifras coinciden con las de `N`, la cifra está permitida (`≤ d_pos`); en la primera menor, `tight` se apaga y las siguientes son libres. Un número `> N` necesitaría una cifra mayor que la del límite con `tight`: prohibida.

🔬 **El detalle.** Es la biyección de `12/06`: por eso la suma de los caminos que acaban cumpliendo la propiedad es la cuenta exacta.

**02 → 9.** ¿Qué cambia si la propiedad es «no hay dos dígitos iguales seguidos»? 🟠

⏱️ **30 segundos.** El estado necesita la última cifra puesta (y `started`, porque el 0 inicial no es una cifra), y la transición prohíbe poner la misma.

🗣️ **2 minutos.** `(pos, tight, última, started)`: con `started = no`, el 0 no cuenta como «última»; en cuanto empieza, cada cifra tiene que ser distinta de la anterior. Es CSES Counting Numbers.

🔬 **El detalle.** Son `L · 11 · 2` estados libres por 10 transiciones.

**02 → 10.** ¿Cómo reutilizas la memo entre varias consultas con `N` distintos? 🟠

⏱️ **30 segundos.** Indexando la memo por «cifras que quedan» en lugar de por posición desde la izquierda, y memoizando solo los estados libres: así no depende de `N`.

🗣️ **2 minutos.** El valor de un estado libre es «cuántas formas de completar `r` cifras libres con este `extra`», que no depende de qué número sea el límite. Se reutiliza en todas las consultas sin reiniciar.

🔬 **El detalle.** Con muchas consultas (`10⁵`), reiniciar la memo cada vez puede costar más que la propia DP.

**02 → 11.** ¿Qué pasa si `a = 0`, y cómo lo maneja la fórmula de prefijos? 🟠

⏱️ **30 segundos.** `f(a − 1) = f(−1) = 0`, que la plantilla devuelve con `N < 0`. Si el 0 cumple la propiedad, entra en la cuenta como cualquier otro número.

🗣️ **2 minutos.** El cero se cuenta en `f(N)` para todo `N ≥ 0`. Si el enunciado pide `[1, b]`, `f(b) − f(0)` lo excluye. El error típico es olvidarlo y contar el 0 de más.

🔬 **El detalle.** Con `started`, el 0 es un caso especial que el enunciado decide.

**02 → 12.** Diseña la *digit DP* para contar los números de `[a, b]` cuyos dígitos son no decrecientes. 🔴

⏱️ **30 segundos.** El estado lleva la última cifra puesta, y la transición solo permite cifras mayores o iguales que ella. Los ceros a la izquierda no estorban: empezando con «última = 0», cualquier cifra vale al principio, así que no hace falta `started`.

🗣️ **2 minutos.** `(pos, tight, última)`: al poner `c ≥ última`, el nuevo estado lleva `c`. Los ceros a la izquierda no estorban porque `0 ≤` cualquier cifra, así que el estado inicial «última = 0» funciona. La cuenta es `f(b) − f(a − 1)`.

🔬 **El detalle.** Sin límite, los números de `L` cifras no decrecientes son `C(L + 9, 9)` (combinaciones con repetición, [`17/05`](../17-matematica/05-combinatoria.md)): la DP es la versión con techo.

**02 → 13.** Tu *digit DP* da 1 más de lo esperado en todos los casos. ¿Qué miras primero? 🔴

⏱️ **30 segundos.** El 0 o el extremo del rango: si siempre sobra 1, casi seguro se cuenta el 0 sin querer, o se hizo `f(b) − f(a)` + algo mal, o el caso `pos == L` cuenta el número vacío.

🗣️ **2 minutos.** Compruebo con un rango pequeño contra la fuerza bruta (`[1, 100]`): si la diferencia es exactamente 1 en todos, es el 0 o el `a − 1`. Después miro `started`: un número formado solo por ceros iniciales puede contarse como un número válido.

🔬 **El detalle.** La fuerza bruta sobre `[0, 10⁵]` es el oráculo natural de cualquier *digit DP* ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).

**02 → Problema: Solo cifras pares.**

- **Pista 2 — patrón:** ***digit DP*** sin `extra` (o la cuenta directa con potencias de 5).
- **Pista 3 — diseño:** recorre las cifras de `N` con `tight`: en cada posición pegada, las cifras pares menores que la del límite dejan libres las siguientes (`5^restantes` cada una); si la cifra del límite es impar, se acaba ahí; si es par, se sigue pegado. El 0 cuenta.

**02 → Problema: Suma múltiplo de k.**

- **Pista 2 — patrón:** ***digit DP*** con la suma módulo `k`.
- **Pista 3 — diseño:** la plantilla del capítulo con `f(b) − f(a − 1)`; estados libres `(pos, resto)`.

**02 → Problema: Exactamente k sietes.**

- **Pista 2 — patrón:** ***digit DP*** con el número de sietes puestos.
- **Pista 3 — diseño:** estado `(pos, tight, sietes)` con `sietes ≤ k` (poda si se pasa); los ceros a la izquierda no son sietes, así que no hace falta `started` para esta propiedad. Rango por diferencia de prefijos.

**02 → Problema: Count Numbers with Unique Digits.**

- **Pista 2 — patrón:** **conteo cifra a cifra** sin límite superior (o *digit DP* con máscara).
- **Pista 3 — diseño:** para longitud `L ≥ 1`, `9 · 9 · 8 · … · (11 − L)` números de `L` cifras distintas; suma para `L = 1..n` y añade el 0.

**02 → Problema: Rotated Digits.**

- **Pista 2 — patrón:** ***digit DP*** con un indicador «ya cambió».
- **Pista 3 — diseño:** cifras prohibidas 3, 4, 7; cifras que cambian 2, 5, 6, 9; estado `(pos, tight, cambió)`; cuenta los que acaban con `cambió`. Con `n ≤ 10⁴`, recorrer también vale.

**02 → Problema: Digit Sum.**

- **Pista 2 — patrón:** ***digit DP*** con la suma módulo `D`, sobre una cadena.
- **Pista 3 — diseño:** `K` llega como cadena de hasta `10⁴` cifras; estado `(pos, tight, resto)`; resta 1 al final por el 0, que el enunciado excluye.

**02 → Problema: Counting Numbers.**

- **Pista 2 — patrón:** ***digit DP*** con la última cifra y `started`.
- **Pista 3 — diseño:** estado `(pos, tight, última, started)`; con `started`, la cifra nueva tiene que ser distinta de `última`. Rango `f(b) − f(a − 1)`, con `f(−1) = 0`.

**02 → Problema: Number of Digit One.**

- **Pista 2 — patrón:** **contar apariciones por posición** (o *digit DP* sumando unos).
- **Pista 3 — diseño:** para cada posición `10ᵖ`, el número de unos es `(N / 10^(p+1)) · 10ᵖ + min(max(N mod 10^(p+1) − 10ᵖ + 1, 0), 10ᵖ)`; o la *digit DP* que lleva cuántos unos se han puesto y suma.

**02 → Problema: Numbers At Most N Given Digit Set.**

- **Pista 2 — patrón:** ***digit DP*** con un conjunto de cifras.
- **Pista 3 — diseño:** los de menos cifras que `N` son `Σ |D|ᴸ`; para los de igual longitud, recorre `N` con `tight`: cifras de `D` menores que la del límite dejan libres `|D|^restantes`; si la del límite está en `D`, se sigue; si no, se para. Suma 1 si `N` entero se forma.

**02 → Problema: Non-negative Integers without Consecutive Ones.**

- **Pista 2 — patrón:** ***digit DP* en binario** con el bit anterior.
- **Pista 3 — diseño:** sobre los bits de `n`: si el bit del límite es 1, poner 0 deja libres los restantes (cuenta de Fibonacci para longitud `r`); poner 1 sigue pegado si el anterior no era 1. Los libres de longitud `r` sin unos seguidos son `F(r + 2)`.

**02 → Problema: Numbers With Repeated Digits.**

- **Pista 2 — patrón:** **complementario**: `n` menos los que tienen todas las cifras distintas.
- **Pista 3 — diseño:** cuenta los de cifras distintas `≤ n`: los de menos cifras por fórmula, y los de igual longitud recorriendo `n` con `tight` y una máscara de cifras usadas (permutaciones de las cifras restantes).

**02 → Problema: Count of Integers.**

- **Pista 2 — patrón:** ***digit DP*** sobre cadenas con suma acotada entre `min_sum` y `max_sum`.
- **Pista 3 — diseño:** estado `(pos, tight, suma)` con `suma ≤ max_sum`; `f(num2) − f(num1) + [num1 cumple]`, para no tener que restar 1 a una cadena. Módulo `10⁹ + 7`.

**02 → Problema: Count Special Integers.**

- **Pista 2 — patrón:** ***digit DP*** con máscara de cifras usadas.
- **Pista 3 — diseño:** estado `(pos, tight, máscara, started)`; la cifra nueva no puede estar en la máscara; con `started = no`, el 0 no se marca. Es el problema de las cifras distintas con límite.

---

# 03 — DP en árboles y en DAG

**03 → 1.** ¿En qué orden se calcula una DP de árbol, y por qué el preorden al revés sirve? 🟢

⏱️ **30 segundos.** Los hijos antes que el padre: un postorden. El preorden al revés sirve porque en el preorden todo hijo aparece después de su padre, así que al invertirlo aparece antes.

🗣️ **2 minutos.** El preorden iterativo con una pila da un orden en que cada nodo sigue a su padre; recorrerlo al revés garantiza que, al procesar un nodo, todos sus descendientes ya están. No hace falta el postorden exacto, solo un orden compatible.

🔬 **El detalle.** [`07/01`](../07-arboles/01-arboles-y-recorridos.md), §4: el preorden al revés es el truco para acumular de hijos a padres sin recursión.

**03 → 2.** ¿Qué dos estados lleva el conjunto independiente máximo en un árbol, y cuál es su transición? 🟢

⏱️ **30 segundos.** `in[v]`, el mejor conjunto del subárbol que incluye a `v`, y `out[v]`, el que no. `in[v] = w(v) + Σ out[c]`; `out[v] = Σ max(in[c], out[c])`.

🗣️ **2 minutos.** Si `v` está, ningún hijo puede estar; si no está, cada hijo elige lo mejor. La respuesta es el máximo de los dos en la raíz.

🔬 **El detalle.** Es la versión en árbol del robo de casas de [`12/02`](../12-dp-clasica/02-dp-lineal-y-lis.md): allí los vecinos son el anterior y el siguiente; aquí, el padre y los hijos.

**03 → 3.** ¿Por qué el camino más largo es lineal en un DAG? 🟢

⏱️ **30 segundos.** Porque en un DAG hay un orden topológico, y calculando en ese orden cada nodo toma el máximo sobre sus predecesores ya calculados: `Θ(V + E)`.

🗣️ **2 minutos.** En un grafo con ciclos, «el camino más largo simple» exige recordar qué nodos se visitaron, y es NP-difícil. En un DAG no se puede repetir un nodo, así que el estado «nodo actual» basta.

🔬 **El detalle.** Es el ejemplo más claro de cómo la estructura del grafo cambia la clase del problema ([`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md), §7).

**03 → 4.** ¿En qué se diferencia contar caminos en un DAG de contar caminos en un grafo con ciclos? 🟡

⏱️ **30 segundos.** En un DAG el número de caminos es finito y se cuenta con una DP en orden topológico. Con ciclos, hay infinitos caminos (se puede dar vueltas), y si se piden caminos simples, contarlos es #P-difícil.

🗣️ **2 minutos.** La DP de conteo necesita que los caminos no se repitan en un mismo estado; con un ciclo, un camino puede volver a un nodo y la suma no termina. Con ciclos, se cuentan caminos de longitud fija con potencias de matrices ([`13/06`](06-recurrencias-lineales-y-matrices.md)).

🔬 **El detalle.** Kahn detecta el ciclo: si quedan nodos con grado de entrada positivo, la DP no tiene orden.

**03 → 5.** ¿Por qué la DP de árbol no necesita memoización? 🟡

⏱️ **30 segundos.** Porque cada subárbol se resuelve una sola vez si se procesan los nodos en un orden en que los hijos van antes: no hay subproblemas que se repitan entre hermanos.

🗣️ **2 minutos.** La memo hace falta cuando un subproblema se pide desde varios sitios; en un árbol, cada subárbol solo lo pide su padre. Con el orden correcto, una pasada basta.

🔬 **El detalle.** En un DAG un nodo sí lo piden varios predecesores; ahí el orden topológico hace el papel de la memo.

**03 → 6.** ¿Qué relación hay entre la cobertura de vértices mínima y el conjunto independiente máximo en un árbol? 🟡

⏱️ **30 segundos.** Son complementarios: un conjunto es independiente si y solo si su complemento es una cobertura de vértices. En cualquier grafo, cobertura mínima = `n −` independiente máximo.

🗣️ **2 minutos.** Si `S` es independiente, toda arista tiene un extremo fuera de `S`: el complemento cubre. Al revés igual. En un árbol las dos se calculan en `Θ(n)`; en grafos generales, las dos son NP-difíciles.

🔬 **El detalle.** En grafos bipartitos, por el teorema de Kőnig, la cobertura mínima es igual al emparejamiento máximo ([`15/06`](../15-grafos-pesos-y-flujos/06-emparejamientos.md)).

**03 → 7.** Compara cómo recorres un árbol de `2·10⁵` nodos en cadena en C++, Java y Python sin desbordar. 🟡

⏱️ **30 segundos.** En los tres, iterativo: un preorden con una pila explícita y recorrerlo al revés. En C++ la recursión suele caber si el juez da pila; en Java, solo con un `Thread` con pila grande; en Python, ni con el límite subido es seguro.

🗣️ **2 minutos.** La profundidad de una cadena es `n`. En Java, `2·10⁵` marcos desbordan la pila por defecto. En Python, `setrecursionlimit` sin hilo puede tumbar el proceso. La versión iterativa es lineal y sin riesgo.

🔬 **El detalle.** [`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md), §3 y §4.

**03 → 8.** Demuestra por inducción que la DP del conjunto independiente es correcta. 🟠

⏱️ **30 segundos.** Inducción sobre la altura del subárbol: en una hoja, `in = w`, `out = 0` son correctos. Si lo son para los hijos, `in[v]` es lo mejor con `v` dentro (los hijos fuera, cada uno con su mejor sin él) y `out[v]` lo mejor con `v` fuera (cada hijo libre).

🗣️ **2 minutos.** Los subárboles de los hijos son disjuntos y no hay aristas entre ellos, así que sus mejores conjuntos se combinan sumando. La única restricción que cruza es la arista padre-hijo, que es justo lo que distinguen los dos estados.

🔬 **El detalle.** Kleinberg y Tardos, §10.2, da además el voraz por hojas para el caso sin pesos.

**03 → 9.** ¿Por qué Kahn detecta ciclos, y qué haces con la DP si los hay? 🟠

⏱️ **30 segundos.** Porque un nodo de un ciclo nunca llega a grado de entrada 0: ninguno de sus predecesores del ciclo sale de la cola. Si al terminar el orden tiene menos de `n` nodos, hay un ciclo.

🗣️ **2 minutos.** Con un ciclo no hay orden topológico y la DP no tiene sentido tal cual. Se puede condensar el grafo en componentes fuertemente conexas ([`14/05`](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md)), que forman un DAG, y hacer la DP sobre él si el problema lo permite.

🔬 **El detalle.** Es lo que se hace, por ejemplo, para «el camino que recoge más monedas pudiendo repetir nodos»: dentro de una componente se recogen todas.

**03 → 10.** ¿Qué hace falta para que una DP de árbol admita *rerooting*? 🟠

⏱️ **30 segundos.** Que la combinación de los valores de los hijos permita **quitar** la contribución de uno: una suma (se resta), o un máximo si se guardan los dos mejores.

🗣️ **2 minutos.** Al mover la raíz de `p` a su hijo `c`, el valor de `p` visto desde `c` es el de `p` sin la contribución de `c`; si no se puede quitar, se guardan prefijos y sufijos de los hijos de cada nodo, a coste `Θ(grado)`.

🔬 **El detalle.** [`07/06`](../07-arboles/06-tecnicas-sobre-arboles.md), §3.

**03 → 11.** ¿Por qué el camino más corto en un DAG admite pesos negativos y Dijkstra no? 🔴

⏱️ **30 segundos.** Porque en un DAG se relaja cada nodo una sola vez y en orden: cuando se procesa, todos sus predecesores son definitivos. Dijkstra supone que el nodo más cercano de la cola ya es definitivo, y un peso negativo posterior puede mejorarlo.

🗣️ **2 minutos.** El orden topológico no depende de las distancias, así que los pesos negativos no lo rompen. Dijkstra sí depende del orden por distancia, que un peso negativo invalida.

🔬 **El detalle.** CLRS, §24.2: *DAG-SHORTEST-PATHS*, `Θ(V + E)` con cualquier peso.

**03 → 12.** Diseña la DP que cuenta **cuántos** conjuntos independientes tiene un árbol (módulo `10⁹ + 7`) y di en qué se diferencia de la del máximo. 🔴

⏱️ **30 segundos.** `a[v]` = conjuntos independientes del subárbol que incluyen a `v`; `b[v]` = los que no. `a[v] = Π b[c]`, `b[v] = Π (a[c] + b[c])`; la respuesta es `a + b` en la raíz. En T, 36 (contando el vacío).

🗣️ **2 minutos.** Es la misma DP con suma y producto en lugar de máximo y suma: los hijos se combinan multiplicando porque son independientes (regla del producto) y las dos opciones del padre se suman (regla de la suma). Módulo en cada producto.

🔬 **El detalle.** Es la frontera de `12/06`: el conteo exige que cada conjunto tenga un único camino, y aquí lo tiene, porque cada nodo decide una vez si está.

**03 → 13.** Tu DP sobre un DAG da números enormes en nodos a los que no se llega desde `s`. ¿Qué falta? 🔴

⏱️ **30 segundos.** Saltarlos: la propagación tiene que empezar solo en `s`, con un centinela para «no alcanzable» que no se propaga.

🗣️ **2 minutos.** Si todos los nodos empiezan con 0 (o con el valor inicial de `s`), los que no se alcanzan propagan valores falsos a sus sucesores. Con `longest[u] == NONE` se omite su transición.

🔬 **El detalle.** En conteo, empezar todo en 0 salvo `ways[s] = 1` ya es correcto: los no alcanzables propagan 0.

**03 → Problema: Fiesta de la empresa.**

- **Pista 2 — patrón:** **conjunto independiente de peso máximo en un árbol**.
- **Pista 3 — diseño:** la plantilla con los jefes como padres (índices desde 1 convertidos a 0); `in` y `out` por nodo, en preorden al revés; suma en 64 bits.

**03 → Problema: Ruta crítica.**

- **Pista 2 — patrón:** **camino más largo en un DAG** con pesos en los nodos.
- **Pista 3 — diseño:** orden de Kahn; `fin[v] = duración[v] + max(fin[u])` sobre sus dependencias (0 si no tiene); la respuesta es el máximo de `fin`. En 64 bits.

**03 → Problema: Colorear la jerarquía.**

- **Pista 2 — patrón:** **DP de árbol con `k` estados** (el color del nodo).
- **Pista 3 — diseño:** `d[v][c] = coste[v][c] + Σ_hijos min_{c' ≠ c} d[hijo][c']`; para no pagar `k²` por hijo, guarda de cada hijo el mínimo y el segundo mínimo con sus colores. `Θ(n · k)`.

**03 → Problema: Even Tree.**

- **Pista 2 — patrón:** **tamaños de subárbol**.
- **Pista 3 — diseño:** calcula el tamaño de cada subárbol; cada arista sobre un subárbol de tamaño par se puede cortar. La respuesta es cuántos subárboles (sin la raíz) tienen tamaño par.

**03 → Problema: Cut the Tree.**

- **Pista 2 — patrón:** **sumas de subárbol**.
- **Pista 3 — diseño:** con la suma total `T` y la suma `s` de cada subárbol, cortar la arista sobre él deja `|T − 2s|`; el mínimo sobre los nodos distintos de la raíz.

**03 → Problema: House Robber III.**

- **Pista 2 — patrón:** **conjunto independiente en árbol binario**.
- **Pista 3 — diseño:** cada nodo devuelve el par (robado, no robado): robado = valor + no robado de los hijos; no robado = suma de los máximos de cada hijo.

**03 → Problema: Tree Matching.**

- **Pista 2 — patrón:** **DP de árbol con dos estados**: el nodo libre o emparejado con un hijo.
- **Pista 3 — diseño:** `libre[v] = Σ max(libre[c], usado[c])`; `usado[v] = max sobre un hijo c de libre[v] − max(libre[c], usado[c]) + libre[c] + 1`. O el voraz por hojas: emparejar una hoja con su padre si ambos están libres, en postorden.

**03 → Problema: Longest Flight Route.**

- **Pista 2 — patrón:** **camino más largo en DAG con reconstrucción**.
- **Pista 3 — diseño:** orden topológico; `largo[v] = 1 + max largo[u]` desde los predecesores alcanzables desde 1, con padre; si `n` no es alcanzable, `IMPOSSIBLE`; reconstruye por padres.

**03 → Problema: Longest Increasing Path in a Matrix.**

- **Pista 2 — patrón:** **DP sobre el DAG implícito** de casillas (aristas hacia vecinos mayores).
- **Pista 3 — diseño:** memoización `largo(i, j) = 1 + max largo(vecino mayor)`; no hay ciclos porque los valores crecen. O procesa las casillas por valor decreciente.

**03 → Problema: Number of Ways to Arrive at Destination.**

- **Pista 2 — patrón:** **Dijkstra más conteo** sobre el DAG de caminos mínimos.
- **Pista 3 — diseño:** durante Dijkstra, si una arista iguala la distancia, suma las formas; si la mejora, las reemplaza. Al sacar los nodos en orden de distancia, el conteo sigue un orden topológico de ese DAG.

**03 → Problema: Kingdom Division.**

- **Pista 2 — patrón:** **DP de árbol con estados de vecindad**.
- **Pista 3 — diseño:** por nodo y color, lleva si ya tiene un vecino (hijo) del mismo color o no; un nodo sin vecino igual solo es válido si su padre lo salva. Cuenta las formas válidas con productos sobre los hijos y resta las que dejan al nodo aislado.

**03 → Problema: Binary Tree Cameras.**

- **Pista 2 — patrón:** **DP de árbol con tres estados** (o voraz desde las hojas).
- **Pista 3 — diseño:** estados: el nodo tiene cámara, está cubierto sin cámara, o no está cubierto (lo tendrá que cubrir su padre). El voraz equivalente: poner cámara en el padre de cada hoja no cubierta, en postorden.

**03 → Problema: Investigation.**

- **Pista 2 — patrón:** **DP sobre el DAG de caminos mínimos**, con cuatro valores.
- **Pista 3 — diseño:** con Dijkstra, cada vez que se fija la distancia de un nodo por una arista que la iguala o mejora, actualiza: número de caminos mínimos (suma), mínimo y máximo de vuelos (mín y máx + 1). El orden de extracción de Dijkstra es topológico para ese DAG.

---

# 04 — DP de probabilidad y esperanza

**04 → 1.** ¿Por qué las probabilidades se propagan hacia delante y las esperanzas hacia atrás? 🟢

⏱️ **30 segundos.** Porque lo que se conoce de partida es distinto: en las probabilidades, el estado inicial (probabilidad 1); en las esperanzas, el final (falta 0). Cada DP parte de lo conocido.

🗣️ **2 minutos.** La probabilidad de estar en `t` se arma con las de los estados anteriores; la esperanza de lo que falta desde `s` se arma con la de los estados siguientes. Se podría plantear la esperanza hacia delante sumando costes ponderados por la probabilidad de cada estado, pero hacia atrás la recurrencia es directa.

🔬 **El detalle.** Las dos son DP sobre el mismo DAG de estados, recorrido en sentidos opuestos.

**04 → 2.** ¿Qué dice la linealidad de la esperanza y qué no dice? 🟢

⏱️ **30 segundos.** Que `E[X + Y] = E[X] + E[Y]` siempre, sean o no independientes. No dice que `E[X · Y] = E[X] · E[Y]`: eso solo vale con independencia.

🗣️ **2 minutos.** La linealidad permite descomponer «el número esperado de cosas» en una suma de indicadores, cada uno con su probabilidad, aunque estén correlacionados. El producto necesita independencia (o la covarianza).

🔬 **El detalle.** [`17/06`](../17-matematica/06-probabilidad-y-esperanza.md) es el dueño del tema, con los indicadores y las desigualdades de Markov y Chebyshev.

**04 → 3.** ¿Cómo se calcula `p/q mod M` con `M` primo? 🟢

⏱️ **30 segundos.** Como `p · q⁻¹ mod M`, con `q⁻¹ = q^(M−2) mod M` por el pequeño teorema de Fermat.

🗣️ **2 minutos.** El inverso existe si `q` no es múltiplo de `M`, que con `M` primo y `q < M` siempre se cumple. Toda la DP se hace en aritmética modular: cada división es una multiplicación por un inverso.

🔬 **El detalle.** [`17/03`](../17-matematica/03-aritmetica-modular.md); con muchos inversos (de `1..n`), se precalculan en `O(n)` con `inv[i] = −(M/i) · inv[M mod i]`.

**04 → 4.** ¿Qué es un autolazo en una DP de esperanza y cómo se resuelve? 🟡

⏱️ **30 segundos.** Una transición de un estado a sí mismo: la ecuación de `E[s]` contiene a `E[s]`. Se despeja: `E[s] = (c + Σ_{t≠s} p(s,t) E[t]) / (1 − p(s,s))`.

🗣️ **2 minutos.** Ejemplo: «tira un dado; si sale 6, tira otra vez». El estado no avanza con probabilidad `1/6`, y la esperanza queda multiplicada por `6/5`. En módulo, la división por `1 − p` es un inverso.

🔬 **El detalle.** Si hay ciclos de longitud mayor que 1, ya no basta despejar: es un sistema de ecuaciones lineales ([`17/07`](../17-matematica/07-matrices-y-gauss.md)).

**04 → 5.** ¿En qué se diferencia una DP de probabilidad de una DP de conteo? 🟡

⏱️ **30 segundos.** La de probabilidad suma valores ponderados por probabilidades que suman 1; la de conteo suma números de objetos. Estructuralmente son iguales: una es la otra dividida por el total de casos, cuando los casos son equiprobables.

🗣️ **2 minutos.** Con dados justos, probabilidad = casos favorables / `6ⁿ`, y la DP de conteo bastaría. Con probabilidades distintas por transición (monedas sesgadas), hace falta la versión ponderada.

🔬 **El detalle.** En los dos casos se exige la biyección de `12/06`: cada resultado del proceso, un único camino.

**04 → 6.** Da un ejemplo en que `E[X · Y] ≠ E[X] · E[Y]`. 🟡

⏱️ **30 segundos.** `X = Y` = el resultado de un dado: `E[X] · E[Y] = 49/4` y `E[X · Y] = E[X²] = 91/6`.

🗣️ **2 minutos.** La diferencia es la covarianza: `E[XY] = E[X]E[Y] + Cov(X, Y)`. Con `X = Y`, la covarianza es la varianza, `35/12`.

🔬 **El detalle.** Con dos dados independientes, `E[XY] = 49/4` exacto.

**04 → 7.** Compara cómo calculas una probabilidad exacta en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++ y Java: aritmética modular (si el juez la pide) o `double`/`long double` con el error que se admita. Python: `fractions.Fraction`, exacto pero lento con miles de estados.

🗣️ **2 minutos.** En `double`, sumar muchas probabilidades pequeñas mantiene bien el error absoluto; el relativo de valores diminutos se pierde. `Fraction` crece en numerador y denominador y se vuelve lenta. La aritmética modular es exacta y rápida, pero solo da el resultado módulo `M`.

🔬 **El detalle.** En Java existe `BigInteger` para fracciones exactas, con el mismo problema de velocidad que `Fraction`.

**04 → 8.** ¿Por qué la ventana deslizante en la esperanza de las tiradas es correcta, y qué ahorra? 🟠

⏱️ **30 segundos.** Porque `E[i]` necesita la suma de los `m` siguientes, y al bajar `i` en uno la ventana pierde `E[i + m]` y gana `E[i]`. Ahorra el factor `m`: `Θ(n)` en lugar de `Θ(n · m)`.

🗣️ **2 minutos.** Es la suma de prefijos de `04/01` aplicada a la DP: la suma de un tramo que se desliza se actualiza en `O(1)`. Con `n, m` hasta `10⁶`, sin ventana serían `10¹²` operaciones.

🔬 **El detalle.** En módulo, la resta necesita `+ MOD` para no quedar negativa.

**04 → 9.** Deriva la esperanza del coleccionista de cromos con `n` cromos equiprobables con una DP hacia atrás. 🟠

⏱️ **30 segundos.** Con `i` cromos distintos, el siguiente sobre trae uno nuevo con probabilidad `(n − i)/n`; si no, se queda en `i`. Despejando el autolazo, `E[i] = n/(n − i) + E[i + 1]`, y `E[0] = n · (1 + 1/2 + … + 1/n)`.

🗣️ **2 minutos.** `E[i] = 1 + (i/n) E[i] + ((n − i)/n) E[i + 1]`, de donde `E[i] (n − i)/n = 1 + ((n − i)/n) E[i + 1]`. Sumando desde `E[n] = 0`, sale `n · H_n ≈ n ln n`.

🔬 **El detalle.** Por linealidad sale igual: el tiempo de pasar de `i` a `i + 1` cromos es geométrico de media `n/(n − i)`.

**04 → 10.** ¿Cuándo resuelves «número esperado de…» con indicadores en lugar de con una DP? 🟠

⏱️ **30 segundos.** Cuando la cantidad es una suma de sucesos simples cuya probabilidad se calcula aislada: «número esperado de pares en inversión», «de puntos fijos», «de récords». Entonces `E = Σ P(suceso)`.

🗣️ **2 minutos.** La linealidad no necesita independencia, así que cada indicador se analiza solo. Con la DP habría que llevar estados que describan todo el proceso; con indicadores, una cuenta por par o por posición.

🔬 **El detalle.** CSES Inversion Probability es el ejemplo: cada par de posiciones aporta su probabilidad de estar invertido.

**04 → 11.** ¿Qué haces si los estados de un proceso forman un ciclo general, no un autolazo? 🟠

⏱️ **30 segundos.** Plantear un sistema de ecuaciones lineales, una por estado, y resolverlo con eliminación de Gauss (`17/07`); o, si converge, iterar hasta que los valores dejen de cambiar.

🗣️ **2 minutos.** Con ciclos no hay orden topológico, así que la DP no tiene por dónde empezar. Gauss cuesta `Θ(n³)` con `n` estados. Para cadenas de Markov con estructura (un camino, un árbol), hay recurrencias que evitan el sistema.

🔬 **El detalle.** [`19/04`](../19-aleatorizados-y-probabilisticos/04-muestreo-y-markov.md) trata las cadenas de Markov y la iteración.

**04 → 12.** Lanzando un dado de 6 caras desde la casilla 0 hasta llegar a `n` o pasarla, ¿con qué probabilidad se cae **exactamente** en `n`? Diseña la DP y di su coste. 🔴

⏱️ **30 segundos.** `P[i]` = la probabilidad de caer en la casilla `i`: `P[0] = 1` y `P[i] = (P[i−1] + … + P[i−6]) / 6`, hacia delante. La respuesta es `P[n]`. `Θ(n)` con ventana deslizante.

🗣️ **2 minutos.** Se cae en `i` si se cayó en alguna de las seis anteriores y la tirada fue la diferencia exacta. Las casillas mayores que `n` no interesan. Con `n = 1`, `1/6`; con `n = 2`, `7/36`.

🔬 **El detalle.** Para `n` grande tiende a `2/7`, el inverso del avance medio `3,5`: es un resultado de renovación.

**04 → 13.** Tu esperanza módulo `10⁹ + 7` da un número que no coincide con el decimal esperado. ¿Cómo lo compruebas? 🔴

⏱️ **30 segundos.** Calculando la misma esperanza con `Fraction` (o en `double`) para un caso pequeño, y comparando: el valor modular `r` tiene que cumplir `r · q ≡ p (mod M)` para la fracción `p/q` exacta.

🗣️ **2 minutos.** Un número modular no se parece al decimal: `7/6` es `166 666 669`. La comprobación es convertir la fracción exacta del oráculo a módulo y comparar. Si no coinciden, lo primero es una división hecha con `/` en lugar de con inverso, o una resta sin `+ MOD`.

🔬 **El detalle.** El oráculo en `Fraction` de Python es la fuerza bruta natural de estas DP (`01/05`).

**04 → Problema: Exactamente k caras.**

- **Pista 2 — patrón:** **DP de probabilidad** sobre (monedas lanzadas, caras).
- **Pista 3 — diseño:** `P[j]` = probabilidad de `j` caras con las monedas vistas; con la moneda `pᵢ`, `P'[j] = P[j](1 − pᵢ) + P[j − 1]pᵢ`, recorriendo `j` de mayor a menor en una fila. `Θ(n²)`.

**04 → Problema: Hasta la meta.**

- **Pista 2 — patrón:** **esperanza hacia atrás** con ventana deslizante y módulo.
- **Pista 3 — diseño:** la plantilla del capítulo: `E[i] = 1 + m⁻¹ · Σ E[i+1..i+m]`, con `E[i] = 0` para `i ≥ n` y la suma de la ventana en `O(1)`.

**04 → Problema: El coleccionista.**

- **Pista 2 — patrón:** **esperanza hacia atrás con autolazo**.
- **Pista 3 — diseño:** `E[i] = n/(n − i) + E[i + 1]` con `E[n] = 0`; en módulo, `n · inv(n − i)`, con los inversos de `1..n` precalculados en `O(n)`.

**04 → Problema: Knight Probability in Chessboard.**

- **Pista 2 — patrón:** **probabilidad hacia delante** por pasos.
- **Pista 3 — diseño:** `P[k][r][c]` = probabilidad de estar en `(r, c)` tras `k` movimientos sin haber salido; cada paso reparte `1/8` a los ocho destinos dentro del tablero; la respuesta suma la última capa.

**04 → Problema: New 21 Game.**

- **Pista 2 — patrón:** **probabilidad con ventana deslizante**.
- **Pista 3 — diseño:** `P[i] = (Σ P[j] sobre j ∈ [i − maxPts, i − 1], j < k) / maxPts`; mantén esa suma deslizante; la respuesta suma `P[i]` para `k ≤ i ≤ n`.

**04 → Problema: Soup Servings.**

- **Pista 2 — patrón:** **probabilidad con memoización** sobre lo que queda de cada sopa.
- **Pista 3 — diseño:** en unidades de 25 ml, el estado es `(a, b)`; para `n` grande (más de unos 4 800), la respuesta es prácticamente 1 y se devuelve directamente.

**04 → Problema: Coins.**

- **Pista 2 — patrón:** **distribución del número de caras**.
- **Pista 3 — diseño:** la DP de «exactamente `k` caras» para todas las `k`, y suma las de `k > n/2`.

**04 → Problema: Dice Probability.**

- **Pista 2 — patrón:** **distribución de la suma** de `n` dados.
- **Pista 3 — diseño:** `P[i][s]` con `s ≤ 6n`; suma `P[n][s]` para `a ≤ s ≤ b` y redondea a seis decimales (con `long double` si hace falta).

**04 → Problema: Inversion Probability.**

- **Pista 2 — patrón:** **linealidad con indicadores** sobre los pares.
- **Pista 3 — diseño:** para cada par `i < j`, la probabilidad de que `xᵢ > xⱼ` con `xᵢ` uniforme en `[1, rᵢ]` y `xⱼ` en `[1, rⱼ]` es `Σ_v P(xⱼ = v) · P(xᵢ > v)`; suma sobre los pares (`n ≤ 100`).

**04 → Problema: Candy Lottery.**

- **Pista 2 — patrón:** **esperanza del máximo** con `P(máx ≤ x) = (x/k)ⁿ`.
- **Pista 3 — diseño:** `E[máx] = Σ_x x · (P(máx ≤ x) − P(máx ≤ x − 1))`; con `long double` y potencias.

**04 → Problema: Sushi.**

- **Pista 2 — patrón:** **esperanza hacia atrás con autolazo** sobre (platos con 1, 2 y 3 piezas).
- **Pista 3 — diseño:** `E[a][b][c] = (n + a E[a−1][b][c] + b E[a+1][b−1][c] + c E[a][b+1][c−1]) / (a + b + c)`, ya despejado el autolazo de elegir un plato vacío; el orden es por `c`, luego `b`, luego `a`, crecientes.

**04 → Problema: Moving Robots.**

- **Pista 2 — patrón:** **probabilidad por robot** y **linealidad**.
- **Pista 3 — diseño:** para cada robot, la distribución de su posición tras `k` pasos (DP de probabilidad sobre las 64 casillas); la casilla está vacía si ningún robot está: `Π (1 − pᵣ(casilla))` por independencia entre robots; la respuesta suma esas probabilidades.

---

# 05 — Optimizaciones de DP

**05 → 1.** ¿Qué forma tiene que tener la transición para usar una cola monótona? 🟢

⏱️ **30 segundos.** `dp[i] = c(i) + min (o max) de dp[j]` sobre una ventana de índices `j` que avanza con `i`, sin términos que mezclen `i` y `j`.

🗣️ **2 minutos.** La ventana puede ser `[i − R, i − L]`; lo importante es que sus extremos solo avancen. Si el coste depende de `i` y `j` por separado y se suma (`f(i) + g(j)`), `g(j)` entra en la clave de la deque.

🔬 **El detalle.** [`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md) tiene la estructura y su prueba; aquí cambia solo lo que se guarda en la deque: valores de la DP.

**05 → 2.** ¿Qué es la envolvente inferior de un conjunto de rectas? 🟢

⏱️ **30 segundos.** La función `x ↦ min_j (mⱼ x + bⱼ)`: el borde inferior del conjunto de rectas, cóncavo y a trozos.

🗣️ **2 minutos.** Cada recta aparece en la envolvente en un intervalo de `x` (o en ninguno). Ordenadas por pendiente decreciente, los intervalos van de izquierda a derecha. Una recta que no aparece se puede tirar.

🔬 **El detalle.** Es la dualidad de la envolvente convexa de puntos ([`18/04`](../18-geometria/04-envolvente-convexa.md)): rectas `y = mx + b` se corresponden con puntos `(m, b)`.

**05 → 3.** ¿Qué condiciones de monotonía exige el CHT con deque? 🟢

⏱️ **30 segundos.** Que las rectas se añadan con pendientes monótonas (decrecientes para el mínimo) y que las consultas lleguen con `x` monótonas (crecientes).

🗣️ **2 minutos.** Con pendientes monótonas, la nueva recta siempre va al final de la envolvente; con consultas monótonas, el óptimo solo avanza y las rectas de delante que dejan de ser mínimas salen para siempre. Las dos cosas hacen `O(1)` amortizado.

🔬 **El detalle.** Sin consultas monótonas, binaria sobre la deque: `O(log n)` por consulta.

**05 → 4.** ¿Cuándo sobra la recta del medio entre tres, y cómo se comprueba sin dividir? 🟢

⏱️ **30 segundos.** Cuando la tercera corta a la primera en un `x` menor o igual que donde la segunda corta a la primera: a partir de ahí la tercera ya está por debajo de la segunda. Se compara con productos cruzados: `(b₃ − b₁)(m₁ − m₂) ≤ (b₂ − b₁)(m₁ − m₃)`.

🗣️ **2 minutos.** El corte de `l₁` y `l₂` es `x₁₂ = (b₂ − b₁)/(m₁ − m₂)`, y el de `l₁` y `l₃`, `x₁₃ = (b₃ − b₁)/(m₁ − m₃)`. Con los denominadores positivos (pendientes decrecientes), `x₁₃ ≤ x₁₂` equivale a la desigualdad de productos.

🔬 **El detalle.** Los productos pueden pasar de 64 bits: `__int128` en C++, `BigInteger` o `Math.multiplyHigh` en Java.

**05 → 5.** Desarrolla `dp[j] + (hᵢ − hⱼ)² + C` para ver las rectas: ¿cuál es la pendiente y cuál la ordenada? 🟡

⏱️ **30 segundos.** `dp[j] + hᵢ² − 2hᵢhⱼ + hⱼ² + C`: pendiente `−2hⱼ`, ordenada `dp[j] + hⱼ²`, evaluada en `x = hᵢ`, más el término `hᵢ² + C` que no depende de `j`.

🗣️ **2 minutos.** Lo que solo depende de `i` sale del mínimo; lo que solo depende de `j` es la ordenada; el producto `hᵢ · hⱼ` da la pendiente. Con alturas crecientes, las pendientes `−2hⱼ` son decrecientes y las consultas `hᵢ` crecientes: CHT con deque.

🔬 **El detalle.** Es AtCoder Frog 3 con la notación del capítulo.

**05 → 6.** ¿En qué se diferencian el CHT con deque, el CHT con binaria y Li Chao? 🟡

⏱️ **30 segundos.** La deque exige pendientes y consultas monótonas (`O(1)` amortizado); la binaria, solo pendientes monótonas (`O(log n)` por consulta); Li Chao no exige nada (`O(log C)`).

🗣️ **2 minutos.** Li Chao es un segment tree sobre las abscisas que guarda en cada nodo la recta mejor en su punto medio; inserta y consulta en `O(log C)` sin ordenar nada ([`09/04`](../09-consultas-sobre-rangos/04-segment-tree-avanzado.md)). Es el más general y el más sencillo de escribir bien.

🔬 **El detalle.** Con abscisas hasta `10⁹`, Li Chao dinámico o con abscisas comprimidas de las consultas conocidas.

**05 → 7.** Compara cómo evitas el desbordamiento en la comparación de cortes en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `__int128` en la comparación. Java: `BigInteger`, `Math.multiplyHigh` o reordenar la comparación con `double` si las magnitudes lo permiten. Python: los enteros son de precisión arbitraria y no desbordan.

🗣️ **2 minutos.** Las diferencias de ordenadas pueden ser de `10¹⁸` y las de pendientes de `10⁶`: el producto pasa de `2⁶³`. Un desbordamiento hace que se tire una recta que sí era necesaria, y la respuesta sale mal solo en casos grandes.

🔬 **El detalle.** Comparar los cortes con `long double` funciona a menudo y falla en empates; los productos exactos no.

**05 → 8.** ¿Por qué un índice dominado nunca vuelve a ser el mínimo en la cola monótona? 🟠

⏱️ **30 segundos.** Porque si `j₁ < j₂` y `dp[j₁] ≥ dp[j₂]`, `j₁` sale de la ventana antes y nunca es mejor que `j₂` mientras los dos están dentro.

🗣️ **2 minutos.** En toda ventana futura que contenga a `j₁` también está `j₂` (la ventana avanza), y `j₂` es al menos tan bueno. Quitarlo no cambia ningún mínimo. Por eso la deque queda creciente en `dp`.

🔬 **El detalle.** Es el mismo argumento de dominancia de la pila monótona (`06/01`).

**05 → 9.** ¿Qué es la monotonía del óptimo, y qué permite en la optimización por divide y vencerás? 🟠

⏱️ **30 segundos.** Que el índice `j` que da el óptimo para `i` no disminuye al aumentar `i`. Permite calcular `opt` del punto medio y recurrir con rangos de `j` partidos: `Θ(n log n)` por capa en lugar de `Θ(n²)`.

🗣️ **2 minutos.** En cada nivel de la recursión, los rangos de `j` de los subproblemas suman `O(n)`, y hay `log n` niveles. La condición suficiente habitual es que el coste `C(j, i)` cumpla la desigualdad del cuadrilátero.

🔬 **El detalle.** Sin la monotonía, la recursión da resultados incorrectos sin avisar: hay que demostrarla o comprobarla contra la DP cuadrática.

**05 → 10.** ¿Qué dice la desigualdad del cuadrilátero, y para qué la necesita Knuth? 🟠

⏱️ **30 segundos.** `C(a, c) + C(b, d) ≤ C(a, d) + C(b, c)` para `a ≤ b ≤ c ≤ d`: «dos intervalos cruzados cuestan menos que el que los contiene y el contenido». Knuth la necesita para que el corte óptimo sea monótono.

🗣️ **2 minutos.** Con ella (y la monotonía por inclusión), `opt[i][j − 1] ≤ opt[i][j] ≤ opt[i + 1][j]`; recorriendo `k` solo en ese rango, la suma de los rangos por diagonal es `O(n)`, y la DP de intervalos baja a `Θ(n²)`.

🔬 **El detalle.** La suma de un tramo (`C(i, j) = suma(i..j)`) la cumple con igualdad; por eso unir montones vecinos y el ABB óptimo admiten Knuth.

**05 → 11.** ¿Cómo adaptas el CHT para maximizar en lugar de minimizar? 🟠

⏱️ **30 segundos.** Negando: el máximo de `mx + b` es menos el mínimo de `(−m)x + (−b)`. O invirtiendo las desigualdades y el orden de las pendientes.

🗣️ **2 minutos.** Negar es lo más seguro: se reutiliza la misma estructura. Para el máximo, las pendientes se añaden crecientes (que negadas son decrecientes).

🔬 **El detalle.** Muchas implementaciones guardan las rectas negadas y devuelven el valor negado en la consulta.

**05 → 12.** Diseña la DP con CHT para partir un arreglo en grupos consecutivos con coste `(suma del grupo)² + C`. 🔴

⏱️ **30 segundos.** Con prefijos `S`, `dp[i] = min_j dp[j] + (Sᵢ − Sⱼ)² + C = Sᵢ² + C + min_j (−2Sⱼ · Sᵢ + dp[j] + Sⱼ²)`. Rectas de pendiente `−2Sⱼ` (decreciente porque `S` crece) consultadas en `Sᵢ` (creciente): CHT con deque, `Θ(n)`.

🗣️ **2 minutos.** El estado es «los `i` primeros documentos impresos»; la transición elige el inicio del último lote. Desarrollando el cuadrado aparecen las rectas. Con páginas positivas, las dos monotonías se cumplen.

🔬 **El detalle.** Es el problema propio «Lotes de impresión»; el oráculo es la DP cuadrática con `n ≤ 2 000`.

**05 → 13.** Tu CHT da resultados correctos con `n ≤ 1 000` y WA con `n = 2·10⁵`. ¿Qué miras? 🔴

⏱️ **30 segundos.** Desbordamiento en la comparación de cortes, o una monotonía que no se cumple con datos grandes (pendientes iguales, consultas que retroceden).

🗣️ **2 minutos.** Con `n` pequeño, los valores son pequeños y los productos caben; con `n` grande, se desborda y se tiran rectas útiles. Segundo sospechoso: pendientes repetidas sin tratar, que dividen por cero en la versión con divisiones. Tercero: consultas no monótonas por un orden de procesamiento distinto.

🔬 **El detalle.** El *stress test* contra la DP cuadrática con valores grandes (no solo `n` grande) delata el desbordamiento.

**05 → Problema: Saltos con ventana.**

- **Pista 2 — patrón:** **cola monótona** sobre una ventana `[i − R, i − L]`.
- **Pista 3 — diseño:** el índice `i − L` entra en la deque al llegar a `i` (si es alcanzable), sacando por detrás los de `dp` mayor o igual; por delante salen los `< i − R`; `dp[i] = c[i] + dp[frente]` si la deque no está vacía.

**05 → Problema: Lotes de impresión.**

- **Pista 2 — patrón:** ***convex hull trick* monótono** sobre las sumas de prefijos.
- **Pista 3 — diseño:** rectas de pendiente `−2Sⱼ` y ordenada `dp[j] + Sⱼ²`, consultadas en `Sᵢ`; `dp[i] = Sᵢ² + C + consulta`. Con sumas hasta `2·10⁸`, los cuadrados caben en 64 bits, pero los productos de `bad` no: `__int128`.

**05 → Problema: Frog 3.**

- **Pista 2 — patrón:** ***convex hull trick* monótono**.
- **Pista 3 — diseño:** la recta de `j` es `(−2hⱼ, dp[j] + hⱼ²)`; las alturas crecen, así que las pendientes decrecen y las consultas crecen; `dp[i] = hᵢ² + C + mínimo`.

**05 → Problema: Monster Game I.**

- **Pista 2 — patrón:** ***convex hull trick* monótono**.
- **Pista 3 — diseño:** `dp[i] = min_j dp[j] + fⱼ · sᵢ` (con `f₀ = x` el factor inicial): rectas de pendiente `fⱼ` (decrecientes) consultadas en `sᵢ` (crecientes).

**05 → Problema: Max Value of Equation.**

- **Pista 2 — patrón:** **cola monótona** con clave `y − x`.
- **Pista 3 — diseño:** para el punto `j`, maximiza `yᵢ − xᵢ` entre los `i` anteriores con `xⱼ − xᵢ ≤ k`; la deque guarda índices con `y − x` decreciente y saca por delante los que quedan a más de `k`.

**05 → Problema: Kalila and Dimna in the Logging Industry.**

- **Pista 2 — patrón:** ***convex hull trick* monótono**.
- **Pista 3 — diseño:** `dp[i] = min_{j<i} dp[j] + b[j] · a[i]`: el último árbol cortado antes del `i` fija el coste de recarga; rectas `(b[j], dp[j])` con `b` decreciente y consultas en `a[i]` crecientes.

**05 → Problema: Monster Game II.**

- **Pista 2 — patrón:** **árbol de Li Chao** (sin monotonía en las pendientes).
- **Pista 3 — diseño:** la misma recurrencia de Monster Game I, pero los factores no son monótonos: inserta cada recta en un Li Chao sobre las abscisas posibles y consulta el mínimo.

**05 → Problema: The Fair Nut and Rectangles.**

- **Pista 2 — patrón:** ***convex hull trick*** tras ordenar por `x`.
- **Pista 3 — diseño:** ordenados por `x` creciente (y `y` decreciente), `dp[i] = xᵢ yᵢ − aᵢ + max_j (dp[j] − xⱼ yᵢ)`: rectas de pendiente `−xⱼ` consultadas en `yᵢ` decrecientes; máximo con la deque.

**05 → Problema: Ciel and Gondolas.**

- **Pista 2 — patrón:** **optimización por divide y vencerás** sobre `k` capas.
- **Pista 3 — diseño:** `dp[k][i] = min_j dp[k−1][j] + coste(j+1, i)`, con el coste de un grupo por sumas de prefijos en dos dimensiones; el corte óptimo es monótono, así que cada capa se calcula con la recursión sobre `opt`.

---

# 06 — Recurrencias lineales y exponenciación de matrices

**06 → 1.** ¿Qué matriz avanza la sucesión de Fibonacci un paso? 🟢

⏱️ **30 segundos.** `[[1, 1], [1, 0]]`: lleva `(F(n), F(n−1))` a `(F(n+1), F(n))`.

🗣️ **2 minutos.** La primera fila suma los dos términos; la segunda copia el primero. Elevada a `n`, `Tⁿ = [[F(n+1), F(n)], [F(n), F(n−1)]]`.

🔬 **El detalle.** De esa identidad salen las fórmulas de duplicación `F(2n) = F(n)(2F(n+1) − F(n))` y `F(2n+1) = F(n)² + F(n+1)²`, que calculan `F(n)` sin matrices.

**06 → 2.** ¿Cuánto cuesta calcular `Tⁿ` para una matriz `m × m`? 🟢

⏱️ **30 segundos.** `Θ(m³ log n)`: unos `2 log₂ n` productos de matrices, cada uno de `Θ(m³)`.

🗣️ **2 minutos.** Un cuadrado por bit del exponente y un producto más por cada bit encendido. Con `m = 2` y `n = 10¹⁸`, unas 120 multiplicaciones de 2 × 2; con `m = 100`, `6·10⁷` operaciones.

🔬 **El detalle.** Con un solo término y un vector, multiplicar el vector por las potencias que hagan falta cuesta `Θ(m² log n)` por consulta si las potencias `T^(2ⁱ)` están precalculadas.

**06 → 3.** ¿Qué cuenta `(Aᵏ)[i][j]` si `A` es la matriz de adyacencia? 🟢

⏱️ **30 segundos.** El número de paseos de longitud exactamente `k` de `i` a `j` (pueden repetir vértices y aristas).

🗣️ **2 minutos.** Por inducción: `(Aᵏ)[i][j] = Σ_t (Aᵏ⁻¹)[i][t] · A[t][j]`, que es contar los paseos de `k − 1` pasos hasta `t` y extenderlos por la arista `t → j`. Es la DP de conteo con la matriz como transición.

🔬 **El detalle.** Con pesos en las aristas (multiplicidades), cuenta paseos ponderados.

**06 → 4.** ¿Por qué basta la asociatividad para la exponenciación rápida de matrices, si el producto no es conmutativo? 🟡

⏱️ **30 segundos.** Porque el algoritmo solo reagrupa los factores (`T⁸ · T² = T¹⁰`), sin cambiar su orden: todos son la misma matriz `T`, y reagrupar productos de la misma matriz es asociatividad.

🗣️ **2 minutos.** La conmutatividad haría falta para reordenar factores distintos; aquí todos son potencias de `T`, que además conmutan entre sí. El invariante `resultado · baseᵉ = Tⁿ` se mantiene con asociatividad y el neutro.

🔬 **El detalle.** Por eso la exponenciación rápida funciona en cualquier monoide: matrices, permutaciones, el semianillo `(min, +)`.

**06 → 5.** ¿Cómo se escribe la matriz compañera de una recurrencia lineal de orden `m`? 🟡

⏱️ **30 segundos.** La primera fila con los coeficientes `c₁ … cₘ`, y debajo una identidad desplazada que copia `a(n−1), …, a(n−m+1)` una posición hacia abajo.

🗣️ **2 minutos.** El vector de estado tiene los `m` últimos términos; la primera fila calcula el nuevo, y las demás desplazan los anteriores. Es una matriz `m × m`.

🔬 **El detalle.** Su polinomio característico es el de la recurrencia, y eso es lo que usan los métodos de [`17/11`](../17-matematica/11-funciones-generadoras.md) para bajar de `m³ log n` a `m² log n` o `m log m log n`.

**06 → 6.** ¿Cómo incluyes un término constante en la recurrencia? 🟡

⏱️ **30 segundos.** Añadiendo la constante como una componente más del vector, que la matriz deja igual: `(a(n), a(n−1), 5)` con una última fila `(0, 0, 1)` y un 1 en la primera fila para sumarla.

🗣️ **2 minutos.** La recurrencia afín se vuelve lineal en un espacio con una dimensión más. Con un término `n`, se añaden `n` y `1` (`n` avanza sumando el 1); con la suma acumulada, se añade el acumulado.

🔬 **El detalle.** Es el truco de las coordenadas homogéneas de la geometría: una traslación es lineal con una coordenada extra.

**06 → 7.** Compara cómo evitas el desbordamiento en el producto de matrices módulo `10⁹ + 7` en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++ y Java: productos en 64 bits y `% MOD` tras cada término (o acumular con `unsigned __int128` en C++ y reducir al final de la fila). Python: los enteros no desbordan, pero conviene reducir para no trabajar con números enormes.

🗣️ **2 minutos.** `a · b < 10¹⁸` cabe en `long long`, pero sumar dos de esos ya no: por eso la reducción va dentro del bucle. En Python el producto de matrices puro es lento; con `m` grande, el bucle interior es el cuello de botella.

🔬 **El detalle.** Con módulo `998 244 353` (< 2³⁰), se pueden sumar hasta 8 productos antes de reducir sin desbordar 64 bits sin signo: una optimización que a veces se ve.

**06 → 8.** ¿Qué cambia para calcular el camino más barato con exactamente `k` aristas? 🟠

⏱️ **30 segundos.** El semianillo: la suma pasa a ser mínimo y el producto pasa a ser suma. `(Aᵏ)[i][j]` en `(min, +)` es el coste mínimo de un camino de exactamente `k` aristas.

🗣️ **2 minutos.** La «multiplicación» `C[i][j] = min_t (A[i][t] + B[t][j])` es asociativa, y el neutro es la matriz con 0 en la diagonal e infinito fuera. La exponenciación rápida sirve igual.

🔬 **El detalle.** Es CSES Graph Paths II. Con «como mucho `k` aristas» basta poner 0 en la diagonal de `A`.

**06 → 9.** ¿Por qué el orden de bucles `i-t-j` es más rápido que `i-j-t`? 🟠

⏱️ **30 segundos.** Porque recorre `B` por filas, en el orden en que está en memoria, y reutiliza `A[i][t]` en un registro; con `i-j-t`, `B` se recorre por columnas y cada acceso salta una fila.

🗣️ **2 minutos.** Con matrices de 100 × 100 de `long long`, cada fila son 800 bytes; recorrer por columnas falla en la caché a cada paso. El número de operaciones es el mismo; la constante cambia varias veces.

🔬 **El detalle.** Es el coste real de [`02/05`](../02-analisis/05-el-coste-real.md): la localidad importa tanto como el orden de complejidad.

**06 → 10.** ¿Cuándo es mejor la tabla de `12/01` que la potencia de la matriz? 🟠

⏱️ **30 segundos.** Cuando `n` es pequeño (`≤ 10⁷`) o hay que responder muchos términos consecutivos: la tabla es lineal y más simple. La potencia gana cuando `n` es enorme y se pide un solo término (o pocos).

🗣️ **2 minutos.** La tabla cuesta `Θ(n · m)`; la potencia, `Θ(m³ log n)`. Con `m = 10` y `n = 10⁶`, la tabla son `10⁷` y la potencia `2·10⁴`, pero la tabla da todos los términos y es imposible equivocarse en ella.

🔬 **El detalle.** Si la transición cambia con `n` (coeficientes variables), la potencia no se aplica y solo queda la tabla (o producto de matrices distintas con segment tree).

**06 → 11.** ¿Cómo calculas la suma `a(0) + a(1) + … + a(n)` de una recurrencia lineal con `n = 10¹⁸`? 🟠

⏱️ **30 segundos.** Añadiendo la suma acumulada `s(n) = s(n−1) + a(n)` al vector de estado: la nueva fila suma el acumulado y el término nuevo.

🗣️ **2 minutos.** Con Fibonacci: vector `(F(n+1), F(n), S(n))` y `S(n+1) = S(n) + F(n+1)`. La matriz pasa a 3 × 3. Para la suma de las potencias de una matriz se usa el mismo truco por bloques.

🔬 **El detalle.** Para Fibonacci hay atajo: `S(n) = F(n+2) − 1`.

**06 → 12.** Diseña la matriz para contar palabras de longitud `n = 10¹⁸` sobre `{a, b, c}` sin `aa` ni `bc`, y di su tamaño. 🔴

⏱️ **30 segundos.** Una matriz 3 × 3 con `T[c][p] = 1` si la letra `c` puede seguir a la letra `p` (es decir, si `pc` no es `aa` ni `bc`). La cuenta es la suma de las componentes de `Tⁿ⁻¹ · (1, 1, 1)`.

🗣️ **2 minutos.** Es la DP de palabras de `12/06` con la transición como matriz: el estado es la última letra, y cada paso multiplica por `T`. Con `n = 10¹⁸`, `log n` productos de 3 × 3.

🔬 **El detalle.** Los primeros valores son 3, 7, 16, 36, 81, los de `12/06`, §3.

**06 → 13.** Tu potencia de matrices da el resultado correcto para `n` pequeño y basura para `n = 10¹⁸`. ¿Qué miras? 🔴

⏱️ **30 segundos.** El desbordamiento: con `n` grande los valores llegan al módulo, y una suma de productos sin reducir pasa de 64 bits. También que el exponente se guarde en `int` en lugar de `long`.

🗣️ **2 minutos.** Con `n` pequeño, los valores son pequeños y no desbordan. Compruebo la reducción en cada término del producto, el tipo del exponente (`10¹⁸` no cabe en `int`) y la identidad inicial.

🔬 **El detalle.** Un oráculo con la tabla hasta `n = 10⁶` y comparando la potencia en varios `n` de ese rango delata el fallo en segundos.

**06 → Problema: Tribonacci gigante.**

- **Pista 2 — patrón:** **matriz compañera de orden 3**.
- **Pista 3 — diseño:** `T = [[1, 1, 1], [1, 0, 0], [0, 1, 0]]` sobre `(T(n), T(n−1), T(n−2))`; para `n ≥ 2`, `Tⁿ⁻²` aplicada a `(1, 0, 0)` da `T(n)` en la primera componente. Casos base aparte.

**06 → Problema: Paseos cerrados.**

- **Pista 2 — patrón:** **potencia de la matriz de adyacencia** y su traza.
- **Pista 3 — diseño:** `Aᵏ` con exponenciación rápida (`100³ · 60 ≈ 6·10⁷`), y la respuesta es la suma de la diagonal módulo `10⁹ + 7`. Las aristas repetidas suman multiplicidad.

**06 → Problema: Recurrencia con constante.**

- **Pista 2 — patrón:** **matriz aumentada** con la constante.
- **Pista 3 — diseño:** vector `(a(n), a(n−1), 5)`, matriz `[[2, 3, 1], [1, 0, 0], [0, 0, 1]]`; para `n ≥ 1`, `Tⁿ⁻¹ · (1, 0, 5)` da `a(n)` arriba.

**06 → Problema: Fibonacci Finding (easy).**

- **Pista 2 — patrón:** **matriz de Fibonacci** con condiciones iniciales `a` y `b`.
- **Pista 3 — diseño:** `(F(n+1), F(n)) = Tⁿ · (b, a)`; la respuesta es la segunda componente, módulo `10⁹ + 7`.

**06 → Problema: Fibonacci Numbers.**

- **Pista 2 — patrón:** **matriz de 2 × 2** (o las fórmulas de duplicación).
- **Pista 3 — diseño:** `Tⁿ[0][1]` con `T = [[1, 1], [1, 0]]`; `n` hasta `10¹⁸`, en 64 bits.

**06 → Problema: Throwing Dice.**

- **Pista 2 — patrón:** **matriz compañera de orden 6**.
- **Pista 3 — diseño:** `f(n) = f(n−1) + … + f(n−6)` con `f(0) = 1` y `f(<0) = 0`; matriz 6 × 6 con la primera fila de unos.

**06 → Problema: Graph Paths I.**

- **Pista 2 — patrón:** **potencia de la adyacencia**.
- **Pista 3 — diseño:** `(Aᵏ)[1][n]` con las aristas múltiples sumando; módulo `10⁹ + 7`.

**06 → Problema: Number of Ways to Paint N × 3 Grid.**

- **Pista 2 — patrón:** **pocos tipos de fila** y una transición fija (DP o matriz 2 × 2).
- **Pista 3 — diseño:** las filas válidas son de tipo «ABA» (6) o «ABC» (6); de una ABA salen 3 ABA y 2 ABC; de una ABC, 2 ABA y 2 ABC. Con `n ≤ 5 000` basta la DP; con `n` enorme, la matriz.

**06 → Problema: Plant.**

- **Pista 2 — patrón:** **matriz de 2 × 2** sobre (triángulos hacia arriba, hacia abajo).
- **Pista 3 — diseño:** cada triángulo hacia arriba da 3 hacia arriba y 1 hacia abajo; cada uno hacia abajo, 1 hacia arriba y 3 hacia abajo: `[[3, 1], [1, 3]]ⁿ` aplicada a `(1, 0)`.

**06 → Problema: Magic Gems.**

- **Pista 2 — patrón:** **matriz compañera de orden `M`**.
- **Pista 3 — diseño:** `f(n) = f(n − 1) + f(n − M)` (la última gema es normal o una mágica partida); matriz `M × M` con `M ≤ 100` y `n` hasta `10¹⁸`.

**06 → Problema: Graph Paths II.**

- **Pista 2 — patrón:** **potencia en el semianillo `(min, +)`**.
- **Pista 3 — diseño:** el «producto» es `C[i][j] = min_t A[i][t] + B[t][j]` con infinito para «no hay arista»; `Aᵏ[1][n]`, o `-1` si queda infinito. Cuidado con sumar infinitos.

**06 → Problema: Student Attendance Record II.**

- **Pista 2 — patrón:** **DP de pocos estados** (ausencias usadas, retrasos seguidos).
- **Pista 3 — diseño:** seis estados (0 o 1 ausencias × 0, 1 o 2 retrasos seguidos); transición fija por día; la respuesta suma los seis tras `n` días. Con `n ≤ 10⁵`, la DP; la matriz 6 × 6 también vale.

---

# 07 — Trucos de nivel alto

**07 → 1.** ¿Qué restricción quita el *Aliens trick* y qué exige de la respuesta? 🟢

⏱️ **30 segundos.** La restricción «exactamente (o como mucho) `k` elementos». Exige que la respuesta `f(k)` sea cóncava en `k` (convexa si se minimiza).

🗣️ **2 minutos.** En lugar de llevar `k` en el estado, se penaliza cada elemento con `λ` y se resuelve la DP sin restricción; con la concavidad, ajustando `λ` se consigue que el óptimo use exactamente `k`.

🔬 **El detalle.** Es la relajación lagrangiana de la optimización con restricciones, con la concavidad como condición de dualidad fuerte.

**07 → 2.** ¿Qué guarda el *slope trick* en lugar de la función entera? 🟢

⏱️ **30 segundos.** El multiconjunto de puntos donde la pendiente de la función convexa aumenta, más el valor (o la pendiente) en un punto de referencia.

🗣️ **2 minutos.** Una función convexa lineal a trozos con pendientes enteras queda determinada por esos puntos; las operaciones de la DP (sumar `|x − a|`, mínimo prefijo) se traducen en meter y sacar puntos de un montículo.

🔬 **El detalle.** A veces se guardan dos montículos, para los puntos a la izquierda y a la derecha del mínimo.

**07 → 3.** ¿Qué se busca con la búsqueda binaria del *Aliens trick*? 🟢

⏱️ **30 segundos.** La penalización `λ` por elemento con la que el óptimo del problema penalizado usa exactamente `k` elementos.

🗣️ **2 minutos.** Con `λ` mayor, conviene elegir menos elementos; la monotonía de `k(λ)` permite la binaria. Cada evaluación es la DP sin `k`, lineal.

🔬 **El detalle.** Con valores enteros, `λ` entero basta si `f` tiene diferencias enteras; si no, binaria en reales.

**07 → 4.** ¿Por qué la concavidad de `f(k)` hace que el `k` óptimo penalizado sea monótono en `λ`? 🟡

⏱️ **30 segundos.** Porque con `f` cóncava, el `k` que maximiza `f(k) − λk` es aquel donde el beneficio marginal `f(k) − f(k − 1)` cruza `λ`, y los beneficios marginales decrecen: al subir `λ`, el cruce se mueve a la izquierda.

🗣️ **2 minutos.** `f(k) − λk` es cóncava en `k` para cada `λ`, así que su máximo está donde la diferencia de consecutivos cambia de signo: `f(k) − f(k − 1) ≥ λ ≥ f(k + 1) − f(k)`. Como las diferencias decrecen, el `k` del máximo es no creciente en `λ`.

🔬 **El detalle.** Sin concavidad, algunos `k` no son óptimos para ningún `λ` y la binaria nunca los alcanza.

**07 → 5.** ¿Qué operación del *slope trick* corresponde a sumar `|x − a|`, y cuál al mínimo prefijo? 🟡

⏱️ **30 segundos.** Sumar `|x − a|` es añadir el punto `a` (dos veces si se guarda la pendiente completa); el mínimo prefijo es borrar los puntos que dejan pendiente positiva a la derecha del mínimo.

🗣️ **2 minutos.** `|x − a|` cambia la pendiente de −1 a +1 en `a`: dos unidades de pendiente en ese punto. Tomar `min_{y ≤ x} f(y)` aplana la parte creciente: se quitan los puntos de la derecha del mínimo.

🔬 **El detalle.** En el problema del arreglo no decreciente, las dos operaciones se combinan en «meter `a` en el montículo de máximos y, si el máximo supera a `a`, sustituirlo».

**07 → 6.** ¿Qué pasa con los empates en el *Aliens trick*, y cómo se tratan? 🟡

⏱️ **30 segundos.** Varios `k` pueden empatar en el óptimo penalizado para un mismo `λ`. Se rompen siempre igual: la DP penalizada elige, entre óptimos, el de menor (o mayor) número de elementos, y la binaria busca el primer `λ` con `k(λ) ≤ k`.

🗣️ **2 minutos.** Si el `k` pedido está dentro de un tramo de empate, no hay `λ` que dé exactamente ese `k`; pero en ese tramo `f` es lineal, y `f(k) = g(λ) + λ · k` sigue siendo correcto con el `λ` del tramo.

🔬 **El detalle.** Es el detalle que hace fallar las implementaciones apresuradas: en los empates, la fórmula usa el `k` pedido, no el que devolvió la DP.

**07 → 7.** Compara cómo implementarías el montículo de máximos del *slope trick* en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `std::priority_queue<long long>`, que ya es de máximos. Java: `PriorityQueue<Long>` con `Collections.reverseOrder()`. Python: `heapq` con los valores negados.

🗣️ **2 minutos.** La operación «sustituir el máximo» es `pop` + `push` en C++ y Java, y `heapq.heapreplace` en Python, más rápida. Los valores hasta `10⁹` y el coste acumulado en 64 bits.

🔬 **El detalle.** [`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md) tiene la tabla de montículos por lenguaje.

**07 → 8.** ¿Por qué hacer un arreglo no decreciente se resuelve metiendo cada valor en un montículo de máximos? 🟠

⏱️ **30 segundos.** Porque la DP `dp[i][v] = mín_{u ≤ v} dp[i−1][u] + |aᵢ − v|` es convexa en `v`, y su mínimo se mueve al meter `aᵢ`: si el máximo del montículo (el punto donde la pendiente pasa a positiva) supera `aᵢ`, hay que bajar ese valor a `aᵢ` pagando la diferencia.

🗣️ **2 minutos.** Intuitivamente, si un valor anterior es mayor que el actual, alguno de los dos tiene que moverse; el coste mínimo es la diferencia, y el valor que queda «disponible» es `aᵢ`. El montículo guarda los candidatos a ajustar.

🔬 **El detalle.** La prueba formal es el *slope trick*: los puntos del montículo son los puntos de quiebre de la función `dp[i][·]`.

**07 → 9.** ¿Cuándo no hace falta ningún truco y basta la DP directa? 🟠

⏱️ **30 segundos.** Cuando `n · k` (para *Aliens*) o `n²` sobre valores comprimidos (para *slope trick*) cabe: con `n ≤ 3 000`, unos `10⁷`.

🗣️ **2 minutos.** Los dos trucos son difíciles de escribir sin errores; si las restricciones permiten la DP directa, es la elección correcta. En una entrevista, la DP directa siempre.

🔬 **El detalle.** La DP directa sirve además como oráculo para comprobar el truco con `n` pequeño.

**07 → 10.** ¿Cómo reconocerías en un enunciado que la respuesta es cóncava en `k`? 🟠

⏱️ **30 segundos.** Cuando añadir un elemento más aporta cada vez menos (rendimientos decrecientes): «el `k`-ésimo subarreglo añade menos que el anterior», «abrir una tienda más ahorra menos».

🗣️ **2 minutos.** La forma práctica es calcular `f(k)` con la DP directa para `n` pequeño y comprobar que las diferencias decrecen. Muchos problemas de «elegir `k` grupos» con costes de tipo cuadrilátero lo cumplen.

🔬 **El detalle.** Formalmente suele venir de que el problema es un flujo de coste mínimo, cuyo coste es convexo en la cantidad de flujo.

**07 → 11.** ¿Cómo pasas de «estrictamente creciente» a «no decreciente» en el *slope trick*? 🔴

⏱️ **30 segundos.** Restando `i` a cada `aᵢ`: `b` estrictamente creciente con enteros equivale a `b[i] − i` no decreciente. Después se aplica el caso no decreciente.

🗣️ **2 minutos.** `bᵢ < bᵢ₊₁` con enteros es `bᵢ + 1 ≤ bᵢ₊₁`, es decir, `bᵢ − i ≤ bᵢ₊₁ − (i + 1)`. El coste no cambia porque se resta lo mismo a `aᵢ` y a `bᵢ`.

🔬 **El detalle.** Es CF 713C, la versión de curiosidad de la práctica.

**07 → 12.** Explica cómo recuperas `f(k)` a partir del valor penalizado `g(λ)`. 🔴

⏱️ **30 segundos.** `f(k) = g(λ) + λ · k`, donde `g(λ) = max_k' (f(k') − λk')` es el valor de la DP penalizada con el `λ` encontrado.

🗣️ **2 minutos.** Si el óptimo penalizado usa `k` elementos, `g(λ) = f(k) − λk`, y se despeja. Con empates, se usa el `k` pedido en la fórmula aunque la DP haya devuelto otro del mismo tramo, porque en el tramo `f` es lineal con pendiente `λ`.

🔬 **El detalle.** Por eso la DP penalizada tiene que devolver también cuántos elementos usó, con un criterio fijo de desempate.

**07 → Problema: Arreglo no decreciente.**

- **Pista 2 — patrón:** ***slope trick*** (o DP sobre los valores comprimidos con `n` pequeño).
- **Pista 3 — diseño:** recorre el arreglo con un montículo de máximos: mete `aᵢ`; si el máximo es mayor que `aᵢ`, suma la diferencia al coste, saca el máximo y mete `aᵢ` otra vez. El coste final, en 64 bits.

**07 → Problema: Exactamente k tramos.**

- **Pista 2 — patrón:** ***Aliens trick***: penaliza cada tramo con `λ` y busca `λ` por binaria.
- **Pista 3 — diseño:** la DP penalizada lleva dos estados (fuera o dentro de un tramo) con el par (valor, tramos usados) y empate por menos tramos; binaria sobre `λ` en `[0, 2·10¹⁴]` hasta que use `≤ k`; la respuesta es `g(λ) + λ · k`. Oráculo: la DP `Θ(n · k)` con `n` pequeño.

**07 → Problema: Sonya and Problem Wihtout a Legend.**

- **Pista 2 — patrón:** ***slope trick*** tras restar `i` a cada `aᵢ`.
- **Pista 3 — diseño:** con `bᵢ = aᵢ − i`, el problema pasa a «no decreciente», y el montículo de máximos lo resuelve en `O(n log n)`.

**07 → Problema: Buy Low Sell High.**

- **Pista 2 — patrón:** **montículo con arrepentimiento**, una forma del *slope trick*.
- **Pista 3 — diseño:** para cada precio, si es mayor que el mínimo del montículo, gana la diferencia y mete el precio **dos veces** (una para poder «deshacer» la venta y vender más tarde, otra como compra posible); si no, mételo una vez.

---

# 08 — Simulación

**08 → S1.** ¿Qué estado usa Held-Karp y cuánto cuesta? 🟢

⏱️ **30 segundos.** `dp[S][v]`: el coste mínimo de visitar exactamente `S` acabando en `v`. `Θ(2ⁿ · n²)` tiempo y `Θ(2ⁿ · n)` memoria.

🗣️ **2 minutos.** El futuro solo depende del conjunto visitado y del vértice actual, no del orden. Con `n = 16`, unos `1,7·10⁷`.

🔬 **El detalle.** [`13/01`](01-mascaras-de-bits.md), §4.

**08 → S2.** ¿Por qué recorrer todas las submáscaras de todas las máscaras cuesta `3ⁿ`? 🟡

⏱️ **30 segundos.** Porque cada bit está fuera de la máscara, dentro de la máscara y fuera de la submáscara, o en las dos: tres situaciones por bit.

🗣️ **2 minutos.** `Σ_m 2^popcount(m) = 3ⁿ` por el binomio. El bucle `s = (s − 1) & m` da cada submáscara en `O(1)`.

🔬 **El detalle.** `13/01`, §2.

**08 → S3.** ¿Qué significa `tight` en una *digit DP* y por qué solo se memoizan los estados libres? 🟡

⏱️ **30 segundos.** Que las cifras puestas coinciden con las del límite, así que la actual no puede pasar de la suya. Solo se memoizan los libres porque los pegados son un único camino que depende de `N`.

🗣️ **2 minutos.** Si se guardaran juntos sin distinguir `tight`, un estado pegado contaminaría la cuenta de uno libre con la misma posición y el mismo resto.

🔬 **El detalle.** [`13/02`](02-digit-dp.md), §3.

**08 → S4.** ¿En qué orden se calcula una DP de árbol sin recursión? 🟢

⏱️ **30 segundos.** Con un preorden iterativo recorrido al revés: los hijos quedan antes que el padre.

🗣️ **2 minutos.** El preorden con pila pone cada hijo después de su padre; invertido, es un orden válido de la DP, sin recursión.

🔬 **El detalle.** [`13/03`](03-dp-en-arboles-y-dag.md), §3, y `07/01`.

**08 → S5.** ¿Por qué el camino más largo es lineal en un DAG y NP-difícil en general? 🟡

⏱️ **30 segundos.** En un DAG hay un orden topológico y el estado «nodo actual» basta, porque no se puede volver a un nodo. En general, un camino simple largo exige recordar los visitados: NP-difícil.

🗣️ **2 minutos.** En un DAG, `largo(v) = max largo(u) + w` sobre los predecesores, en orden topológico: `Θ(V + E)`. Con ciclos, el problema contiene al del camino hamiltoniano.

🔬 **El detalle.** `13/03`, §4.

**08 → S6.** ¿Por qué las esperanzas se calculan hacia atrás? 🟢

⏱️ **30 segundos.** Porque lo que se conoce es el final: desde la meta faltan 0 pasos. Cada esperanza se arma con las de los estados siguientes.

🗣️ **2 minutos.** `E[s] = c(s) + Σ p(s, t) E[t]`: hacen falta los sucesores calculados. Las probabilidades, al revés, parten del inicio conocido.

🔬 **El detalle.** [`13/04`](04-probabilidad-y-esperanza.md), §2.

**08 → S7.** ¿Cómo se resuelve un autolazo en una DP de esperanza? 🟡

⏱️ **30 segundos.** Despejando: `E[s] = (c + Σ_{t≠s} p E[t]) / (1 − p(s, s))`. En módulo, la división es un inverso.

🗣️ **2 minutos.** El estado aparece a los dos lados de su propia ecuación; como es una ecuación lineal con una incógnita, se resuelve. Con ciclos más largos, sistema lineal.

🔬 **El detalle.** `13/04`, pregunta 4.

**08 → S8.** ¿Qué forma tiene que tener la transición para usar el *convex hull trick*? 🟡

⏱️ **30 segundos.** `dp[i] = a(i) + min_j (mⱼ · xᵢ + bⱼ)`: un término de `i`, más el mínimo de rectas que aporta cada `j`, evaluadas en un valor de `i`.

🗣️ **2 minutos.** Se reconoce desarrollando la transición: el término cruzado tiene que ser un producto `f(j) · g(i)`; lo que solo depende de `j` es la ordenada.

🔬 **El detalle.** [`13/05`](05-optimizaciones.md), §1 y §4.

**08 → S9.** ¿Qué condiciones exige el CHT con deque? 🟢

⏱️ **30 segundos.** Pendientes monótonas al añadir y consultas monótonas en `x`.

🗣️ **2 minutos.** Con las dos, cada recta entra y sale de la deque una vez: `O(n)`. Sin consultas monótonas, binaria; sin pendientes monótonas, Li Chao.

🔬 **El detalle.** `13/05`, §2.

**08 → S10.** ¿Cómo se calcula el término `10¹⁸` de una recurrencia lineal? 🟢

⏱️ **30 segundos.** Con la matriz de transición elevada a la potencia con exponenciación rápida: `Θ(m³ log n)`.

🗣️ **2 minutos.** El paso de la recurrencia es una multiplicación por una matriz fija; `n` pasos son su potencia, y la potencia sale con cuadrados repetidos porque el producto es asociativo.

🔬 **El detalle.** `13/06`, §2.

**08 → S11.** ¿Qué cambia para el camino más barato con exactamente `k` aristas? 🟡

⏱️ **30 segundos.** El semianillo: suma por mínimo y producto por suma. `(Aᵏ)[i][j]` en `(min, +)` es el coste mínimo con exactamente `k` aristas.

🗣️ **2 minutos.** El «producto» `C[i][j] = min_t A[i][t] + B[t][j]` es asociativo, y la exponenciación rápida sirve igual.

🔬 **El detalle.** `13/06`, pregunta 8.

**08 → S12.** El enunciado dice `n ≤ 3 000` y la DP es `Θ(n²)`. Alguien propone el CHT. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que con `n ≤ 3 000`, `n²/2 ≈ 4,5·10⁶`: la DP directa cabe de sobra, y el CHT añade código, riesgo de desbordamiento y nada de tiempo útil.

🗣️ **2 minutos.** Las restricciones dicen qué complejidad se espera. Optimizar sin necesidad cambia un algoritmo simple y verificable por uno frágil. Si el coste ni siquiera tiene forma de rectas, el CHT ni se aplica.

🔬 **El detalle.** Es el problema propio «Grupos de valores parecidos»: el coste `(máx − mín)²` no se desarrolla en rectas, y no hace falta.

**08 → S13.** «El viajante solo se resuelve por fuerza bruta.» ¿Qué respondes con números? 🟠

⏱️ **30 segundos.** Que con Held-Karp es `2ⁿ · n²`: con `n = 16`, `1,7·10⁷` frente a `15! ≈ 1,3·10¹²`. Sigue siendo exponencial, pero el exponente es otro.

🗣️ **2 minutos.** El viajante es NP-difícil, así que nada polinomial se conoce; pero la DP sobre subconjuntos explota que el orden de lo visitado no importa. Con `n ≤ 20`, cabe.

🔬 **El detalle.** `13/01`, §4.

**08 → S14.** Tu *digit DP* da uno más en todos los casos. ¿Qué miras? 🟠

⏱️ **30 segundos.** El 0 o el extremo del rango: casi siempre se cuenta el 0 sin querer, o se hace `f(b) − f(a)` en lugar de `f(b) − f(a − 1)`.

🗣️ **2 minutos.** Lo compruebo contra la fuerza bruta en `[1, 100]`; si sobra exactamente 1, es el 0 o `a − 1`. Después, el caso `pos == L` con `started` falso.

🔬 **El detalle.** `13/02`, pregunta 13.

**08 → S15.** «La esperanza de un producto es el producto de esperanzas.» ¿Cuándo es verdad? 🟠

⏱️ **30 segundos.** Cuando las variables son independientes. En general no: con `X = Y` = un dado, `49/4` frente a `91/6`.

🗣️ **2 minutos.** La suma sí es lineal siempre; el producto necesita independencia o la covarianza.

🔬 **El detalle.** `13/04`, §2.

**08 → S16.** Tu CHT pasa con `n` pequeño y falla con `n = 2·10⁵`. ¿Qué sospechas? 🟠

⏱️ **30 segundos.** Desbordamiento en la comparación de cortes, o pendientes iguales sin tratar.

🗣️ **2 minutos.** Los productos de la comparación crecen con los valores; con `n` grande pasan de 64 bits y se tiran rectas que sí eran necesarias. `__int128` o `BigInteger` en `bad`, y un caso aparte para pendientes iguales.

🔬 **El detalle.** `13/05`, pregunta 13.

**08 → S17.** Te piden «exactamente `k` grupos» con `n = k = 10⁵`. ¿Qué técnica nombrarías, y qué tendrías que comprobar antes? 🟠

⏱️ **30 segundos.** El *Aliens trick* (relajación lagrangiana). Antes, comprobar que la respuesta es cóncava (o convexa) en `k`: con la DP directa en casos pequeños, que las diferencias sean monótonas.

🗣️ **2 minutos.** Penalizando cada grupo con `λ`, la DP sin `k` es lineal, y una binaria sobre `λ` encuentra el que da `k` grupos. Sin concavidad, la binaria salta valores de `k`.

🔬 **El detalle.** [`13/07`](07-trucos-de-nivel-alto.md), §3.

**08 → S18.** Tu potencia de matrices da basura con `n = 10¹⁸`. ¿Qué miras? 🟠

⏱️ **30 segundos.** El desbordamiento en el producto (sumar productos sin reducir) y el tipo del exponente (`10¹⁸` no cabe en `int`).

🗣️ **2 minutos.** Con `n` pequeño los valores son pequeños y no desbordan. Reduzco en cada término y compruebo la identidad inicial.

🔬 **El detalle.** `13/06`, pregunta 13.

**08 → S19.** Demuestra que en SOS el bucle de bits tiene que ir por fuera. 🔴

⏱️ **30 segundos.** Con el bit por fuera, cada submáscara llega a cada máscara por un único camino: bajando los bits en orden. Con la máscara por fuera, una submáscara que difiere en dos bits llega por los dos órdenes y se suma dos veces.

🗣️ **2 minutos.** Invariante con el bit por fuera: tras procesar los bits `0..b`, `F[m]` suma las `s ⊆ m` que coinciden con `m` en los bits `> b`. Cada paso extiende el invariante un bit sin duplicar. Con las máscaras por fuera, `F[m ^ bit]` puede haber acumulado ya otras submáscaras por otros bits, y se mezclan.

🔬 **El detalle.** `13/01`, pregunta 6.

**08 → S20.** Diseña la DP que cuenta los conjuntos independientes de un árbol y explica por qué no cuenta de más. 🔴

⏱️ **30 segundos.** `a[v] = Π b[c]` (con `v`) y `b[v] = Π (a[c] + b[c])` (sin `v`); la respuesta es `a + b` en la raíz. No cuenta de más porque cada nodo decide una sola vez si está, y cada conjunto corresponde a un único camino de decisiones.

🗣️ **2 minutos.** Los hijos son subárboles disjuntos e independientes: sus cuentas se multiplican (regla del producto); las dos opciones de `v` son disjuntas: se suman. En el árbol T salen 36 contando el vacío.

🔬 **El detalle.** `13/03`, pregunta 12.

**08 → Problema: Ronda de inspección.**

- **Pista 2 — patrón:** **Held-Karp** (DP sobre subconjuntos con el vértice actual).
- **Pista 3 — diseño:** `dp[S][v]` con `dp[{0}][0] = 0`; la respuesta es `min_v dp[todos][v] + d[v][0]`; con `n = 1`, 0. `2¹⁶ · 16²`.

**08 → Problema: Suma de cifras prima.**

- **Pista 2 — patrón:** ***digit DP*** con la suma de las cifras, y criba de las sumas posibles.
- **Pista 3 — diseño:** las sumas van de 0 a `9 · 18 = 162`; estado `(pos, tight, suma)`; al final, cuenta si la suma es prima (tabla de primos hasta 162). Rango `f(b) − f(a − 1)`.

**08 → Problema: La rama más valiosa.**

- **Pista 2 — patrón:** **DP de árbol** con «lo mejor que cuelga de `v`».
- **Pista 3 — diseño:** `mejor[v] = valor[v] + Σ max(0, mejor[hijo])` (un hijo solo se incluye si aporta); la respuesta es el máximo de `mejor[v]` sobre todos los `v` (el nodo más alto del conjunto). Postorden iterativo; 64 bits.

**08 → Problema: Grupos de valores parecidos.**

- **Pista 2 — patrón:** **DP cuadrática sin optimizar**: `n ≤ 3 000` lo permite.
- **Pista 3 — diseño:** `dp[i] = min_j dp[j] + (máx − mín de (j, i])² + C`, recorriendo `j` de `i − 1` hacia atrás y manteniendo el máximo y el mínimo del grupo; `Θ(n²)`. Valores en 64 bits.

**08 → Problema: Independent Set.**

- **Pista 2 — patrón:** **DP de árbol de conteo** con dos estados.
- **Pista 3 — diseño:** `blanco[v] = Π (blanco[c] + negro[c])`, `negro[v] = Π blanco[c]`, módulo `10⁹ + 7`; postorden iterativo.

**08 → Problema: Candies.**

- **Pista 2 — patrón:** **DP de conteo con prefijos** sobre los caramelos repartidos.
- **Pista 3 — diseño:** `dp[i][k] = Σ_{x=0..aᵢ} dp[i−1][k − x]`; con la suma de prefijos de la fila anterior, cada celda en `O(1)`: `Θ(N · K)`.

**08 → Problema: Grouping.**

- **Pista 2 — patrón:** **DP sobre máscaras con submáscaras** (`3ⁿ`).
- **Pista 3 — diseño:** precalcula la puntuación de cada máscara como un grupo; `dp[m] = max_{s ⊆ m} dp[m \ s] + puntos(s)`, recorriendo las submáscaras que contienen el bit más bajo de `m` para no repetir.

**08 → Problema: Walk.**

- **Pista 2 — patrón:** **potencia de la matriz de adyacencia**.
- **Pista 3 — diseño:** la respuesta es la suma de todas las entradas de `Aᴷ` módulo `10⁹ + 7`; `50³ · 60` operaciones.

**08 → Problema: Subtree.**

- **Pista 2 — patrón:** ***rerooting*** con productos de los hijos.
- **Pista 3 — diseño:** `dp[v] = Π (dp[hijo] + 1)` hacia abajo; para el valor desde arriba, prefijos y sufijos de los productos de los hijos de cada nodo (el módulo `M` no es primo: no hay inversos). Segunda pasada de arriba abajo.
