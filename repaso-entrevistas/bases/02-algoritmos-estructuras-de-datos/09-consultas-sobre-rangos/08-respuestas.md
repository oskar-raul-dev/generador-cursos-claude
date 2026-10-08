# Respuestas — bloque 09: Consultas sobre rangos

> Solucionario del bloque `09`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--sparse-table-y-rmq) · [02](#02--fenwick) · [03](#03--segment-tree) · [04](#04--segment-tree-avanzado) · [05](#05--raíz-cuadrada-y-mo) · [06](#06--árbol-cartesiano-y-wavelet-tree) · [07](#07--simulación)

---

# 01 — *Sparse table* y RMQ

**01 → 1.** ¿Qué guarda `st[k][i]`? 🟢

⏱️ **30 segundos.** El mínimo del bloque de longitud `2ᵏ` que empieza en `i`: `min(a[i .. i + 2ᵏ − 1])`.

🗣️ **2 minutos.** El nivel 0 es el arreglo; cada nivel combina dos bloques consecutivos del anterior. Hay `⌊log₂ n⌋ + 1` niveles, y el nivel `k` tiene `n − 2ᵏ + 1` entradas.

🔬 **El detalle.** Algunas implementaciones guardan la tabla transpuesta (`st[i][k]`); por localidad, la forma `st[k][i]` suele ser mejor al construir.

**01 → 2.** ¿Qué dos bloques cubren el tramo `[l, r]`, y por qué cubren todo? 🟢

⏱️ **30 segundos.** Con `k = ⌊log₂(r − l + 1)⌋`, los bloques `[l, l + 2ᵏ − 1]` y `[r − 2ᵏ + 1, r]`. Cubren todo porque cada uno mide `2ᵏ`, más de la mitad del tramo.

🗣️ **2 minutos.** El primero empieza en `l` y el segundo acaba en `r`. Como `2 · 2ᵏ > r − l + 1`, se solapan o se tocan, sin dejar huecos. Los dos están dentro de `[l, r]` porque `2ᵏ ≤ r − l + 1`.

🔬 **El detalle.** Con `L` potencia de 2, los dos bloques coinciden.

**01 → 3.** ¿Cuánto cuestan el preproceso, la consulta y la memoria? 🟢

⏱️ **30 segundos.** Preproceso `Θ(n log n)` en tiempo y memoria; consulta `O(1)`.

🗣️ **2 minutos.** Cada entrada se calcula en `O(1)` a partir de dos del nivel anterior. La consulta son dos lecturas y un mínimo, más la tabla `lg`. La memoria es lo que más pesa: `n log n` enteros.

🔬 **El detalle.** Con `n = 10⁶`, `2·10⁷` enteros, 80 MB: en el límite de muchos jueces.

**01 → 4.** ¿Por qué la *sparse table* no sirve para sumas? Da un ejemplo. 🟡

⏱️ **30 segundos.** Porque los dos bloques se solapan y la suma cuenta dos veces la intersección. En `[5, 2, 9]`, la suma de `[0, 2]` con bloques `[0, 1]` y `[1, 2]` da `7 + 11 = 18`, no 16.

🗣️ **2 minutos.** El mínimo de `{2}` combinado dos veces sigue siendo 2; la suma de `{2}` combinada dos veces es 4. Para sumas, los prefijos dan `O(1)` con `O(n)` de preproceso, que es mejor en todo.

🔬 **El detalle.** La *sparse table* disjunta sí admite sumas en `O(1)`, partiendo en bloques que no se solapan (pregunta 12).

**01 → 5.** ¿Qué operaciones son idempotentes, y cuáles de las habituales no? 🟡

⏱️ **30 segundos.** Idempotentes: `min`, `max`, `gcd`, `and`, `or` (`x ⊕ x = x`). No lo son la suma, el producto ni el *xor*.

🗣️ **2 minutos.** Las idempotentes «no notan» repetir un elemento. El *xor* es un buen contraejemplo: `x ⊕ x = 0`, así que el solapamiento borra la intersección.

🔬 **El detalle.** También son idempotentes `lcm` (con cuidado con el desbordamiento) y la unión de conjuntos.

**01 → 6.** ¿Cómo calculas `⌊log₂ L⌋` sin coma flotante en C++ y en Java? 🟡

⏱️ **30 segundos.** Con una tabla `lg[L] = lg[L / 2] + 1` precalculada, o con instrucciones de bits: en C++, `31 − __builtin_clz(L)` o `std::__lg(L)`; en Java, `31 − Integer.numberOfLeadingZeros(L)`.

🗣️ **2 minutos.** `log2` en coma flotante puede redondear mal justo en potencias de 2 y es más lento. La posición del bit más alto encendido es exactamente `⌊log₂ L⌋`. En C++20 también existe `std::bit_width(L) − 1`.

🔬 **El detalle.** En Python, `L.bit_length() − 1`.

**01 → 7.** ¿Cómo devuelves el **índice** del mínimo en lugar del valor, y qué haces con los empates? 🟠

⏱️ **30 segundos.** Guardando índices en la tabla y comparando por el valor: `st[k][i]` es el índice del mínimo del bloque. Con empates, se elige con un criterio fijo (el menor índice) en todas las comparaciones.

🗣️ **2 minutos.** La combinación es `a[x] < a[y] ? x : y` (o `≤` para preferir el de la izquierda). Para que la respuesta sea, por ejemplo, el primer mínimo del tramo, el criterio tiene que ser coherente también en la consulta, que combina dos bloques solapados.

🔬 **El detalle.** Con pares `(valor, índice)` y la comparación de pares, el desempate sale solo.

**01 → 8.** Demuestra que la consulta con dos bloques solapados es correcta si y solo si la operación es idempotente. 🟠

⏱️ **30 segundos.** Los dos bloques cubren `[l, r]` con una intersección no vacía. Si `x ⊕ x = x`, combinar la intersección dos veces equivale a una: resultado correcto. Si no, para algún arreglo la intersección cambia el resultado.

🗣️ **2 minutos.** Con `⊕` asociativa y conmutativa, `B₁ ⊕ B₂ = (B₁ \ I) ⊕ I ⊕ I ⊕ (B₂ \ I)`. Si `⊕` es idempotente, `I ⊕ I = I` y queda `⊕` del tramo. Recíprocamente, si existe `x` con `x ⊕ x ≠ x`, el arreglo `[x]` consultado con dos bloques de longitud 1 que coinciden da `x ⊕ x`, incorrecto.

🔬 **El detalle.** La idempotencia de cada elemento basta para la de cualquier subconjunto, por asociatividad y conmutatividad.

**01 → 9.** Compara la memoria de la *sparse table* en C++, Java y Python para `n = 10⁶`, y qué harías si no cabe. 🟠

⏱️ **30 segundos.** `n · (⌊log₂ n⌋ + 1) = 2·10⁷` entradas: en C++ y Java, unos 80 MB con `int`; en Python, listas de enteros de varios cientos de MB. Si no cabe: segment tree (`O(n)` de memoria y `O(log n)` por consulta) o RMQ por bloques.

🗣️ **2 minutos.** En Java, las filas con su longitud justa ahorran algo. En Python, la tabla es inviable con `10⁶`; un segment tree iterativo o el procesamiento *offline* (ordenar consultas, pila monótona) son las alternativas.

🔬 **El detalle.** Con valores pequeños, tipos más estrechos (`short`, arreglos de `array` en Python) reducen la memoria.

**01 → 10.** ¿Por qué el LCA por el recorrido de Euler encaja con la *sparse table*? 🟠

⏱️ **30 segundos.** Porque el LCA es el nodo de menor profundidad entre las primeras apariciones de `u` y `v` en el recorrido de Euler: un RMQ sobre un arreglo estático, que es lo que la tabla responde en `O(1)`.

🗣️ **2 minutos.** El árbol no cambia, el recorrido de Euler tampoco, y hay muchas consultas: el caso ideal. Se guarda en la tabla el par `(profundidad, nodo)` y se compara por profundidad.

🔬 **El detalle.** [`07/05`](../07-arboles/05-lca.md), §4.

**01 → 11.** ¿Cómo encuentras, para cada `i`, el tramo más largo que empieza en `i` con `gcd > 1`, combinando la tabla con otra técnica? 🟠

⏱️ **30 segundos.** Con una tabla de `gcd` y, para cada `i`, una búsqueda binaria sobre el final: el `gcd` de `a[i..j]` solo puede bajar al alargar el tramo, así que «`gcd > 1`» es monótono. `O(n log n · log V)`.

🗣️ **2 minutos.** Cada paso de la binaria consulta un `gcd` en `O(1)` (más el coste del `gcd` de dos números). Alternativa: dos punteros, porque el mejor final no retrocede al avanzar `i`.

🔬 **El detalle.** Problemas como Integers Have Friends aplican esto a las diferencias entre consecutivos.

**01 → 12.** ¿Qué es una *sparse table* disjunta y qué operaciones admite en `O(1)` por consulta? 🔴

⏱️ **30 segundos.** Una variante que, para cada nivel, guarda los agregados desde el centro de cada bloque hacia sus extremos; cualquier tramo que cruza un centro se responde con **dos** valores que no se solapan. Admite cualquier operación asociativa (suma, producto, composición) en `O(1)` por consulta.

🗣️ **2 minutos.** Para cada nivel, el arreglo se parte en bloques de tamaño `2ᵏ`; en cada bloque se precalculan los agregados de sufijos de la mitad izquierda y de prefijos de la derecha. El nivel de una consulta `[l, r]` es el del bit más alto en que difieren `l` y `r`. Preproceso `O(n log n)`.

🔬 **El detalle.** Es útil cuando la operación no es invertible ni idempotente y no hay actualizaciones, como la composición de funciones.

**01 → 13.** ¿Cómo se consigue RMQ con preproceso `O(n)` y consulta `O(1)`? Esboza la idea por bloques. 🔴

⏱️ **30 segundos.** Partiendo el arreglo en bloques de tamaño `b ≈ (log₂ n) / 4`: una *sparse table* sobre los mínimos de bloque (`O(n)` en total, porque hay `n / log n` bloques) y, dentro de cada bloque, tablas precalculadas para cada «forma» de bloque, que son pocas.

🗣️ **2 minutos.** Una consulta se parte en el sufijo de su primer bloque, los bloques completos intermedios (con la *sparse table*) y el prefijo del último. Las consultas dentro de un bloque se resuelven con tablas por tipo de bloque (su árbol cartesiano): hay como mucho `4ᵇ = √n` tipos, cada uno con una tabla de `b²` respuestas, `o(n)` en total. Es el resultado de Bender y Farach-Colton.

🔬 **El detalle.** En la práctica, la variante con máscaras de bits por bloque (una pila monótona codificada en un entero) es más simple y también `O(n)`/`O(1)`.

**01 → Problema: Amplitud térmica.**

- **Pista 2 — patrón:** **dos sparse tables**, de máximos y de mínimos.
- **Pista 3 — diseño:** construye las dos y responde `max(l, r) − min(l, r)`; con `|t| ≤ 10⁹`, la diferencia cabe en 64 bits (en 32 podría no caber).

**01 → Problema: Racha sin bajar del umbral.**

- **Pista 2 — patrón:** **binaria sobre el final** con una **sparse table** de mínimos.
- **Pista 3 — diseño:** si `a[i] < x`, la respuesta es 0; si no, busca el mayor `j` con `min(a[i..j]) ≥ x` (el predicado es monótono en `j`); la respuesta es `j − i + 1`. `O(log n)` por consulta.

**01 → Problema: Number of Subarrays With GCD Equal to K.**

- **Pista 2 — patrón:** **gcd de tramos** que solo baja al alargar.
- **Pista 3 — diseño:** con `n ≤ 1000`, para cada inicio, alarga el tramo acumulando el `gcd` y cuenta los que valen `k`; corta en cuanto el `gcd` deje de ser múltiplo de `k`.

**01 → Problema: Static Range Minimum Queries.**

- **Pista 2 — patrón:** **sparse table** de mínimos.
- **Pista 3 — diseño:** la plantilla con índices de 1 a `n` del enunciado convertidos a 0; lectura y escritura rápidas.

**01 → Problema: Static RMQ.**

- **Pista 2 — patrón:** **sparse table** de mínimos.
- **Pista 3 — diseño:** el tramo es semiabierto `[l, r)`: consulta `[l, r − 1]`. `5·10⁵` consultas: lectura rápida.

**01 → Problema: Integers Have Friends.**

- **Pista 2 — patrón:** **diferencias** y **gcd de tramos** con dos punteros o binaria.
- **Pista 3 — diseño:** con `d[i] = |a[i+1] − a[i]|`, un tramo de `a` es «amigo» si el `gcd` de sus diferencias es `> 1`; busca el tramo más largo de `d` con `gcd > 1` (sparse table de `gcd` y dos punteros) y súmale 1.

**01 → Problema: Find Building Where Alice and Bob Can Meet.**

- **Pista 2 — patrón:** **máximo de tramos** + **búsqueda del primer mayor**.
- **Pista 3 — diseño:** si uno puede ir directamente al edificio del otro, esa es la respuesta; si no, busca el primer edificio a la derecha del más lejano con altura mayor que la máxima de los dos: binaria con una *sparse table* de máximos (o *offline* con pila monótona).

**01 → Problema: Pair of Numbers.**

- **Pista 2 — patrón:** **gcd y mínimo de tramos** iguales.
- **Pista 3 — diseño:** un tramo vale si su `gcd` coincide con su mínimo; para cada longitud (binaria sobre la longitud, que es monótona), comprueba si algún tramo lo cumple con dos *sparse tables*; recoge los inicios de la longitud máxima.

**01 → Problema: Friends and Subsequences.**

- **Pista 2 — patrón:** **máximo y mínimo** de tramos + **binaria** para cada inicio.
- **Pista 3 — diseño:** fijado `l`, `max(a[l..r]) − min(b[l..r])` es no decreciente en `r`; busca con dos binarias el primer `r` donde vale 0 y el primero donde pasa de 0; suma la diferencia. Respuesta en 64 bits.

**01 → Problema: CGCDSSQ.**

- **Pista 2 — patrón:** **gcd de tramos** con pocos valores distintos por final.
- **Pista 3 — diseño:** para cada final, los `gcd` de los tramos que acaban ahí forman como mucho `log V` valores distintos; mantén la lista de `(gcd, cuántos)` y actualízala al avanzar, acumulando en un mapa las cuentas por valor. Responde cada consulta con el mapa.

---

# 02 — Fenwick

**02 → 1.** ¿Qué vale `i & −i`, y qué tramo guarda `tree[i]`? 🟢

⏱️ **30 segundos.** `i & −i` es la potencia de 2 del bit más bajo encendido de `i`. `tree[i]` guarda la suma de `(i − (i & −i), i]`: los `i & −i` elementos que acaban en `i`.

🗣️ **2 minutos.** En complemento a 2, `−i = ~i + 1`: invierte todos los bits y suma 1, lo que deja igual el bit más bajo encendido y los ceros de debajo, e invierte el resto. El `&` aísla ese bit. Por eso `tree[6]` (`110`) cubre 2 elementos (`[5, 6]`) y `tree[4]` (`100`) cubre 4 (`[1, 4]`).

🔬 **El detalle.** Los índices impares cubren solo su propio elemento.

**02 → 2.** ¿Por qué Fenwick empieza en el índice 1? 🟢

⏱️ **30 segundos.** Porque con `i = 0`, `i & −i = 0`: la actualización no avanzaría nunca (bucle infinito) y el prefijo no tendría tramo que sumar.

🗣️ **2 minutos.** La estructura se basa en el bit más bajo de `i`; el 0 no tiene ninguno. Si los datos vienen desde 0, se suma 1 a cada índice al llamar. Hay variantes con índices desde 0 (`i | (i + 1)` y `(i & (i + 1)) − 1`), pero mezclar convenciones es la fuente habitual de errores.

🔬 **El detalle.** cp-algorithms presenta las dos variantes.

**02 → 3.** ¿Cómo obtienes la suma de `[l, r]` con dos prefijos? 🟢

⏱️ **30 segundos.** `suma(l, r) = prefijo(r) − prefijo(l − 1)`.

🗣️ **2 minutos.** Es la misma resta de prefijos de [`04/01`](../04-secuencias/01-prefijos-y-diferencias.md); por eso la operación tiene que ser invertible. Con `l = 1`, `prefijo(0) = 0`.

🔬 **El detalle.** Con *xor*, la «resta» es otro *xor*: `prefijo(r) ⊕ prefijo(l − 1)`.

**02 → 4.** ¿Cuántas celdas toca una actualización y una consulta, y por qué? 🟡

⏱️ **30 segundos.** Como mucho `⌊log₂ n⌋ + 1` en cada una: la consulta apaga un bit por paso y la actualización sube al menos un bit por paso.

🗣️ **2 minutos.** En el prefijo, `i −= i & −i` quita el bit más bajo: tantos pasos como bits encendidos tenga `i`. En la actualización, `i += i & −i` hace que el bit más bajo suba de posición: como mucho tantos pasos como bits tiene `n`.

🔬 **El detalle.** En la práctica, la consulta hace en promedio la mitad de pasos que la actualización.

**02 → 5.** ¿Cómo fijas `a[p] = v` (no sumar) con un Fenwick? 🟡

⏱️ **30 segundos.** Sumando la diferencia: `add(p, v − a[p])`, y actualizando `a[p] = v` en un arreglo guardado aparte.

🗣️ **2 minutos.** El Fenwick solo sabe sumar. Si no se guarda `a`, se puede obtener `a[p]` con `range(p, p)`, a costa de una consulta más.

🔬 **El detalle.** Es el error del primer envío en muchos problemas: llamar a `add(p, v)` en una orden de «fijar».

**02 → 6.** ¿Cómo sumas a un tramo y consultas un punto con un solo Fenwick? 🟡

⏱️ **30 segundos.** Con el Fenwick sobre el arreglo de diferencias: sumar `v` a `[l, r]` es `add(l, v)` y `add(r + 1, −v)`; el valor de `a[i]` es `prefix(i)`.

🗣️ **2 minutos.** El arreglo de diferencias convierte un cambio de tramo en dos cambios puntuales, y un valor puntual en un prefijo. El Fenwick hace los dos en `O(log n)`.

🔬 **El detalle.** El Fenwick necesita tamaño `n + 1` para la marca de `r + 1`.

**02 → 7.** ¿Cómo cuentas las inversiones de un arreglo con un Fenwick y valores comprimidos? 🟡

⏱️ **30 segundos.** Recorriendo el arreglo y, para cada valor (comprimido a `1..m`), sumando cuántos ya vistos son mayores: `vistos − prefix(valor)`; después, `add(valor, 1)`. `O(n log n)`.

🗣️ **2 minutos.** El Fenwick guarda cuántos elementos de cada valor han aparecido. Al llegar `x`, los ya vistos mayores que `x` forman inversión con él. Se comprimen los valores ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)) para que el Fenwick tenga tamaño `n`.

🔬 **El detalle.** [`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md) da la alternativa con la mezcla; el Fenwick además permite contar por elemento.

**02 → 8.** Demuestra que el prefijo de Fenwick suma tramos disjuntos que cubren exactamente `[1, i]`. 🟠

⏱️ **30 segundos.** Los tramos `(i − lowbit(i), i]`, `(i' − lowbit(i'), i']` con `i' = i − lowbit(i)`, etc., van uno detrás de otro hacia la izquierda sin huecos ni solapes, y el último acaba en 0.

🗣️ **2 minutos.** El primer tramo empieza justo después de `i' = i − lowbit(i)`, y el siguiente acaba en `i'`: son contiguos y disjuntos. Cada paso apaga un bit, así que el proceso llega a 0 en tantos pasos como bits encendidos tiene `i`. La unión de los tramos es `(0, i] = [1, i]`.

🔬 **El detalle.** Es la descomposición de `i` en potencias de 2 distintas, leídas de la más baja a la más alta.

**02 → 9.** ¿Por qué Fenwick no sirve para el mínimo de un tramo, y en qué caso particular sí sirve para mínimos de prefijos? 🟠

⏱️ **30 segundos.** Porque el mínimo no es invertible: no se puede «restar» el prefijo izquierdo para quedarse con un tramo. Sí sirve para mínimos de **prefijos** si los valores solo bajan (`a[p] = min(a[p], v)`).

🗣️ **2 minutos.** El prefijo de mínimos combina tramos con `min`, que funciona igual que la suma; el problema es solo la consulta de tramo y las actualizaciones que suben un valor (no se puede deshacer un mínimo). Con valores que solo bajan, cada celda se actualiza con `min` y todo es correcto.

🔬 **El detalle.** Es el caso de la DP de la subsecuencia creciente más larga con Fenwick de máximos de prefijos ([`12/02`](../12-dp-clasica/02-dp-lineal-y-lis.md)).

**02 → 10.** Compara la implementación de Fenwick en C++, Java y Python: tipos, índices y coste real. 🟠

⏱️ **30 segundos.** El código es casi igual en los tres; cambian los tipos (`long long`, `long`, enteros sin límite) y la constante: en Python, cada operación son unos 18 pasos interpretados, y `2·10⁵` operaciones pueden rozar el límite.

🗣️ **2 minutos.** En C++ y Java, un arreglo de enteros de 64 bits y bucles de tres líneas: muy rápido. En Python, conviene guardar la lista en una variable local dentro del bucle y evitar la clase en el código caliente. Los índices desde 1 son igual de necesarios en los tres.

🔬 **El detalle.** En Java, `long[]` y no `Long[]`.

**02 → 11.** Deduce la fórmula del Fenwick rango/rango a partir del arreglo de diferencias. 🟠

⏱️ **30 segundos.** `Σ_{j≤i} a[j] = Σ_{j≤i} Σ_{k≤j} d[k] = Σ_{k≤i} d[k] · (i − k + 1) = (i + 1) · Σ_{k≤i} d[k] − Σ_{k≤i} k · d[k]`.

🗣️ **2 minutos.** Cada `d[k]` contribuye a los `a[j]` con `j ≥ k`, y en el prefijo hasta `i` hay `i − k + 1` de ellos. Separando, aparecen dos prefijos: el de `d` y el de `k · d[k]`, cada uno en su Fenwick. Sumar `v` a `[l, r]` es `d[l] += v`, `d[r+1] −= v`, que en el segundo Fenwick son `l · v` y `−(r + 1) · v`.

🔬 **El detalle.** Con índices desde 1 sale `(i + 1)`; con otras convenciones, la fórmula cambia en una unidad.

**02 → 12.** ¿Cómo construyes un Fenwick en `O(n)` en lugar de `O(n log n)`? 🔴

⏱️ **30 segundos.** Copiando el arreglo en `t` y, para cada `i` de 1 a `n`, sumando `t[i]` a `t[i + lowbit(i)]` si no se sale: `O(n)`.

🗣️ **2 minutos.** Cada celda `i` contribuye a su «padre» inmediato `i + lowbit(i)`, cuyo tramo contiene al de `i`. Procesando en orden creciente, cuando se propaga `t[i]` ya contiene la suma de todo su tramo. Alternativa: con prefijos `P`, `t[i] = P[i] − P[i − lowbit(i)]`.

🔬 **El detalle.** Con `n = 10⁶` y muchas consultas, la diferencia entre `O(n)` y `O(n log n)` de construcción se nota poco; en Python, sí.

**02 → 13.** Demuestra que la búsqueda por bits encuentra la menor posición con prefijo `≥ k` en `O(log n)`. 🔴

⏱️ **30 segundos.** Bajando por los bits de mayor a menor con el invariante `prefijo(pos) < k`: si `tree[pos + 2ᵇ]` (la suma de `(pos, pos + 2ᵇ]`) no alcanza lo que falta, se avanza. Al acabar, `pos + 1` es la menor posición con prefijo `≥ k`.

🗣️ **2 minutos.** Como `pos` solo tiene bits más altos que `b`, el tramo de la celda `pos + 2ᵇ` es exactamente `(pos, pos + 2ᵇ]`. Avanzar mantiene `prefijo(pos) < k`; no avanzar significa que la respuesta está en `(pos, pos + 2ᵇ]`. Es una búsqueda binaria que construye `pos` bit a bit; con valores no negativos, los prefijos son monótonos. `O(log n)` pasos.

🔬 **El detalle.** Es el mismo esquema que el «salto» del *binary lifting* (`07/05`): construir la respuesta por bits de mayor a menor.

**02 → Problema: Saldos de las cuentas.**

- **Pista 2 — patrón:** **Fenwick puntual/rango**.
- **Pista 3 — diseño:** construye el Fenwick con los saldos; `+` hace `add`; `?` imprime `range(l, r)`. Sumas en 64 bits.

**02 → Problema: Bonificaciones.**

- **Pista 2 — patrón:** **Fenwick sobre las diferencias**.
- **Pista 3 — diseño:** `+ l r v` es `add(l, v)` y `add(r + 1, −v)` en un Fenwick de tamaño `n + 1`; `? i` es `prefix(i)`. 64 bits.

**02 → Problema: El `k`-ésimo asiento libre.**

- **Pista 2 — patrón:** **Fenwick de libres + búsqueda por bits**.
- **Pista 3 — diseño:** un 1 por asiento libre; `ocupa k` busca la menor posición con prefijo `≥ k`, la imprime y hace `add(pos, −1)`; `libera s` hace `add(s, 1)`.

**02 → Problema: Range Sum Query - Mutable.**

- **Pista 2 — patrón:** **Fenwick puntual/rango**.
- **Pista 3 — diseño:** guarda `nums`; `update(i, v)` suma `v − nums[i]` en la posición `i + 1`; `sumRange` con dos prefijos.

**02 → Problema: Queries on a Permutation With Key.**

- **Pista 2 — patrón:** **Fenwick de posiciones ocupadas** con huecos delante.
- **Pista 3 — diseño:** coloca los `m` valores en las posiciones `m + 1 … 2m` y reserva las `m` primeras; la posición actual de un valor es el número de ocupadas antes de él (un prefijo); para moverlo al principio, quita su marca y ponla en el siguiente hueco libre por la izquierda.

**02 → Problema: Create Sorted Array through Instructions.**

- **Pista 2 — patrón:** **Fenwick de cuentas por valor**.
- **Pista 3 — diseño:** para cada valor, menores = `prefix(v − 1)` y mayores = `insertados − prefix(v)`; suma el mínimo de los dos módulo `10⁹ + 7` y haz `add(v, 1)`.

**02 → Problema: Count Good Triplets in an Array.**

- **Pista 2 — patrón:** **Fenwick** sobre las posiciones en la otra permutación.
- **Pista 3 — diseño:** reescribe `nums1` como posiciones en `nums2`; para cada elemento central, cuenta con un Fenwick cuántos anteriores son menores (a la izquierda) y deduce los mayores a la derecha; suma los productos en 64 bits.

**02 → Problema: Dynamic Range Sum Queries.**

- **Pista 2 — patrón:** **Fenwick puntual/rango** con «fijar».
- **Pista 3 — diseño:** guarda el arreglo; la orden de tipo 1 suma `u − a[k]` y actualiza `a[k]`; la de tipo 2 resta dos prefijos. 64 bits.

**02 → Problema: Point Add Range Sum.**

- **Pista 2 — patrón:** **Fenwick puntual/rango** con construcción lineal.
- **Pista 3 — diseño:** construye en `O(n)` propagando cada celda a `i + lowbit(i)`; las consultas son semiabiertas `[l, r)`, con índices desde 0: ajusta a `[l + 1, r]`.

**02 → Problema: Forest Queries II.**

- **Pista 2 — patrón:** **Fenwick 2D**.
- **Pista 3 — diseño:** un 1 por árbol; cambiar una celda suma `±1`; un rectángulo por inclusión-exclusión de cuatro prefijos.

**02 → Problema: Enemy is weak.**

- **Pista 2 — patrón:** **dos Fenwick de cuentas** (izquierda y derecha).
- **Pista 3 — diseño:** con valores comprimidos, para cada posición central cuenta los mayores a su izquierda y los menores a su derecha; suma los productos en 64 bits.

**02 → Problema: Vertex Add Subtree Sum.**

- **Pista 2 — patrón:** **recorrido de Euler + Fenwick**.
- **Pista 3 — diseño:** numera con `tin` en preorden (iterativo); el subárbol de `v` es `[tin[v], tin[v] + size[v] − 1]`; sumar a un vértice es un `add` en `tin`; la consulta, una suma de tramo.

---

# 03 — Segment tree

**03 → 1.** ¿Qué tres cosas definen el nodo genérico de un segment tree? 🟢

⏱️ **30 segundos.** El tipo del valor, una operación de combinación asociativa y su elemento neutro (un monoide).

🗣️ **2 minutos.** Con esas tres piezas, el mismo código sirve para suma (neutro 0), mínimo (`+∞`), máximo (`−∞`), `gcd` (0) o composición de funciones (la identidad). La asociatividad permite combinar los nodos del árbol en cualquier agrupación; el neutro, empezar los acumuladores y responder fuera del tramo.

🔬 **El detalle.** No hace falta conmutatividad si se combinan los resultados en orden (izquierda y derecha por separado).

**03 → 2.** ¿Dónde están las hojas y el padre de `i` en el segment tree iterativo? 🟢

⏱️ **30 segundos.** Las hojas en `[n, 2n)` (la hoja de `a[i]` es `n + i`) y el padre de `i` en `i / 2`; los hijos de `i`, en `2i` y `2i + 1`.

🗣️ **2 minutos.** El nodo 1 es la raíz; el 0 no se usa. Se construye de `n − 1` a 1 combinando hijos. Actualizar es cambiar la hoja y subir con `p >>= 1` recalculando.

🔬 **El detalle.** `p ^ 1` es el hermano de `p`: así se recalcula el padre con los dos hijos sin saber cuál es cuál.

**03 → 3.** ¿Qué operaciones admite un segment tree que Fenwick no? 🟢

⏱️ **30 segundos.** Cualquier operación asociativa con neutro: mínimo, máximo, `gcd`, composición de funciones, productos de matrices. Fenwick necesita además que sea invertible (suma, *xor*).

🗣️ **2 minutos.** Fenwick responde tramos restando prefijos; el segment tree los compone con `O(log n)` nodos sin restar. Por eso admite el mínimo con cambios, la subsecuencia de suma máxima (nodos de varios campos) o la composición de transformaciones.

🔬 **El detalle.** A cambio, el segment tree es más largo, usa más memoria y tiene más constante.

**03 → 4.** ¿Por qué la versión iterativa acumula `resl` y `resr` por separado? 🟡

⏱️ **30 segundos.** Para conservar el orden: lo que se recoge por la izquierda va antes que lo de la derecha. Con operaciones no conmutativas, mezclarlos daría un resultado incorrecto.

🗣️ **2 minutos.** El bucle recoge nodos del extremo izquierdo de izquierda a derecha (`resl = op(resl, t[l])`) y del derecho de derecha a izquierda (`resr = op(t[r], resr)`). Al final, `op(resl, resr)`. Con suma o mínimo da igual, pero la plantilla sirve también para composición.

🔬 **El detalle.** Es el patrón de la biblioteca de AtCoder (`segtree`), que solo exige un monoide.

**03 → 5.** ¿Cuánta memoria necesita el segment tree recursivo para `n` cualquiera, y por qué? 🟡

⏱️ **30 segundos.** `4n` posiciones: con `n` que no es potencia de 2, la numeración `2v`, `2v + 1` puede llegar a índices cercanos a `4n`.

🗣️ **2 minutos.** Si `n` fuera potencia de 2, `2n` bastaría. Con `n = 2ᵏ + 1`, el árbol tiene altura `k + 1` y la numeración por niveles llega hasta `2^{k+2}`, casi `4n`. Reservar `4n` cubre todos los casos.

🔬 **El detalle.** La versión iterativa usa `2n` siempre, porque no necesita que los nodos internos sean tramos contiguos.

**03 → 6.** ¿Qué es `push` y cuándo hay que llamarlo? 🟡

⏱️ **30 segundos.** Bajar la etiqueta sin aplicar de un nodo a sus dos hijos (aplicándola a sus valores y componiéndola con sus etiquetas) y vaciarla. Se llama antes de entrar en los hijos de un nodo, en actualizaciones y consultas.

🗣️ **2 minutos.** El valor del nodo ya refleja su etiqueta, pero los de sus hijos no. Si una operación va a leer o modificar a los hijos, primero tienen que recibirla. Los nodos cubiertos por completo no necesitan `push`: se usan o se etiquetan enteros.

🔬 **El detalle.** Olvidar `push` en la consulta es el error clásico: la actualización funciona y la consulta lee hijos desactualizados.

**03 → 7.** ¿Qué tienen que cumplir las etiquetas para que la propagación perezosa funcione? 🟠

⏱️ **30 segundos.** Que se compongan (dos etiquetas seguidas equivalen a una) y que aplicar una etiqueta **distribuya** sobre la operación: aplicarla al nodo da lo mismo que aplicarla a los hijos y combinar.

🗣️ **2 minutos.** «Sumar `x`» sobre sumas: el nodo suma `x · L`, y la combinación de los hijos tras sumar `x` a cada uno da lo mismo. «Sumar `x`» sobre mínimos: el mínimo sube `x`. «Multiplicar» sobre sumas: la suma se multiplica. Si no distribuye (por ejemplo, «elevar al cuadrado» sobre sumas), no se puede hacer perezoso.

🔬 **El detalle.** Formalmente, las etiquetas forman un monoide que actúa sobre el monoide de los valores por homomorfismos.

**03 → 8.** Demuestra que una consulta de tramo visita `O(log n)` nodos. 🟠

⏱️ **30 segundos.** En cada nivel, como mucho dos nodos están cortados por el tramo (los que contienen sus extremos); solo esos se exploran, así que se visitan como mucho 4 nodos por nivel: `O(log n)`.

🗣️ **2 minutos.** Los nodos de un nivel cubren tramos disjuntos que forman el arreglo. Un tramo contiguo `[l, r)` corta como mucho al nodo que contiene `l` y al que contiene `r − 1`; los demás están dentro o fuera por completo. Los de dentro se usan sin bajar; los de fuera se descartan. Por inducción, cada nivel recibe como mucho dos nodos cortados del anterior, que generan como mucho 4 visitas.

🔬 **El detalle.** El número de nodos usados enteros es como mucho `2 log₂ n`.

**03 → 9.** ¿Cómo se componen las etiquetas «asignar» y «sumar» cuando las dos aparecen? 🟠

⏱️ **30 segundos.** La etiqueta es un par (asignar opcional `s`, sumar `a`). Componer «asignar `x`» después de cualquier cosa da «asignar `x`»; componer «sumar `y`» después de «asignar `x`» da «asignar `x + y`»; después de «sumar `a`», «sumar `a + y`».

🗣️ **2 minutos.** Aplicar `(s, a)` a un nodo de longitud `L`: si hay `s`, el valor es `(s + a) · L`; si no, `valor + a · L`. Representar la etiqueta normalizada (asignación ya con la suma incorporada) simplifica el código.

🔬 **El detalle.** Las dos son casos de la etiqueta afín `x ↦ b·x + c`: asignar es `b = 0`; sumar, `b = 1`.

**03 → 10.** Compara el segment tree en C++, Java y Python: qué versión escribirías en cada uno y por qué. 🟠

⏱️ **30 segundos.** C++ y Java: iterativo para actualizaciones puntuales, recursivo con *lazy* para tramos. Python: solo el iterativo, y con cuidado; el recursivo con *lazy* suele ser demasiado lento.

🗣️ **2 minutos.** En Python, cada llamada recursiva cuesta mucho; un segment tree con *lazy* sobre `2·10⁵` operaciones hace millones de llamadas. Las alternativas en Python: el iterativo, dos Fenwick para suma/suma, o procesar *offline*. En Java, los arreglos de primitivos y la recursión de profundidad `log n` van bien.

🔬 **El detalle.** Existe un *lazy* iterativo (bajando etiquetas por los caminos de `l` y `r`), más rápido pero más difícil de escribir.

**03 → 11.** ¿Por qué el descenso «primer índice con valor `≥ x`» es `O(log n)` y no `O(log² n)` como una binaria con consultas? 🟠

⏱️ **30 segundos.** Porque el descenso baja por un solo camino (más un desvío que se descarta enseguida) usando el máximo guardado en cada nodo, en lugar de hacer `O(log n)` consultas de `O(log n)` cada una.

🗣️ **2 minutos.** Una binaria sobre el final, con una consulta de máximo en cada paso, cuesta `O(log² n)`. El descenso decide en cada nodo si la respuesta está en el hijo izquierdo mirando su máximo: si es `≥ x` (y está en el rango), baja a él; si no, al derecho. Con el límite «`≥ i`», como mucho se exploran dos caminos.

🔬 **El detalle.** Es la misma idea que la búsqueda por bits de Fenwick ([`09/02`](02-fenwick.md)).

**03 → 12.** ¿Qué información guarda cada nodo para la subsecuencia de suma máxima de un tramo, y cómo se combinan dos nodos? 🔴

⏱️ **30 segundos.** Cuatro campos: la suma total, el mejor prefijo, el mejor sufijo y el mejor tramo. Al combinar `L` y `R`: suma `= L.suma + R.suma`; prefijo `= max(L.pref, L.suma + R.pref)`; sufijo `= max(R.suf, R.suma + L.suf)`; mejor `= max(L.mejor, R.mejor, L.suf + R.pref)`.

🗣️ **2 minutos.** El mejor tramo de la unión está entero en una mitad o cruza el corte; si cruza, es un sufijo de la izquierda más un prefijo de la derecha. La operación es asociativa, así que el segment tree la admite tal cual.

🔬 **El detalle.** Es el Kadane de [`04/03`](../04-secuencias/03-kadane-y-subarreglos.md) convertido en una operación de monoide; [`09/04`](04-segment-tree-avanzado.md) lo desarrolla.

**03 → 13.** ¿Cómo responderías «cuántos valores distintos hay en `a[l..r]`» con un segment tree y consultas *offline*? 🔴

⏱️ **30 segundos.** *Offline*: ordenando las consultas por `r`, recorriendo el arreglo y manteniendo un 1 solo en la **última** aparición de cada valor (en un Fenwick o segment tree de sumas); la respuesta de `[l, r]` es la suma de `[l, r]` cuando se llega a `r`.

🗣️ **2 minutos.** Al procesar `a[i]`, se pone un 1 en `i` y se quita el de su aparición anterior. Así, para el `r` actual, cada valor distinto aparece una sola vez (en su última posición `≤ r`), y contar los de `[l, r]` es sumar. `O((n + q) log n)`.

🔬 **El detalle.** *Online*, hace falta un segment tree persistente (`09/04`) o Mo ([`09/05`](05-raiz-cuadrada-y-mo.md)) con otro coste.

**03 → Problema: Temperaturas corregidas.**

- **Pista 2 — patrón:** **segment tree de máximos** con actualización puntual.
- **Pista 3 — diseño:** el iterativo con `max` y neutro `−∞`; `=` es `set(p, v)` y `?` es `query(l, r + 1)`.

**03 → Problema: Subidas por tramos.**

- **Pista 2 — patrón:** **lazy de suma** con suma de tramo (o dos Fenwick).
- **Pista 3 — diseño:** la plantilla `LazySum` con tramos `[l, r + 1)`; inicializa con los precios (actualizaciones de un elemento o un `build`). Sumas en 64 bits.

**03 → Problema: El primero que llega al umbral.**

- **Pista 2 — patrón:** **descenso** en un segment tree de máximos.
- **Pista 3 — diseño:** `firstAtLeast(1, 0, n, i, x)` de la plantilla recursiva; `=` es `set`.

**03 → Problema: Handling Sum Queries After Update.**

- **Pista 2 — patrón:** **lazy de inversión** sobre un arreglo de bits.
- **Pista 3 — diseño:** cada nodo guarda cuántos unos tiene; invertir un tramo deja `longitud − unos`, y dos inversiones se cancelan (etiqueta booleana con *xor*). La suma de `nums2` crece en `p · (unos totales)` con cada consulta de tipo 2; acumúlala en 64 bits.

**03 → Problema: Longest Increasing Subsequence II.**

- **Pista 2 — patrón:** **segment tree de máximos sobre los valores**.
- **Pista 3 — diseño:** `dp[v]` = la LIS más larga que acaba en el valor `v`; al procesar `v`, `dp[v] = 1 + max(dp[v − k .. v − 1])` con una consulta de máximo; actualiza la posición `v`.

**03 → Problema: My Calendar III.**

- **Pista 2 — patrón:** **lazy de suma con máximo** (o barrido con mapa ordenado).
- **Pista 3 — diseño:** sobre coordenadas comprimidas o un segment tree dinámico, cada reserva suma 1 al tramo `[inicio, fin)`; la respuesta es el máximo global. Con pocas reservas, un mapa de diferencias y un barrido también entra.

**03 → Problema: Falling Squares.**

- **Pista 2 — patrón:** **lazy de asignación con máximo** sobre coordenadas comprimidas.
- **Pista 3 — diseño:** para cada cuadrado, la altura base es el máximo de su tramo; asigna `base + lado` a todo el tramo; tras cada caída, la respuesta es el máximo global.

**03 → Problema: Dynamic Range Minimum Queries.**

- **Pista 2 — patrón:** **segment tree de mínimos**.
- **Pista 3 — diseño:** el iterativo con `min`; tipo 1 es `set` y tipo 2 una consulta `[a − 1, b)`.

**03 → Problema: Xenia and Bit Operations.**

- **Pista 2 — patrón:** **nodo según la altura**: `or` y `xor` alternos.
- **Pista 3 — diseño:** con `2ⁿ` hojas, el nivel justo encima de las hojas usa `or`, el siguiente `xor`, y así; guarda la operación por nivel y recalcula el camino en cada cambio.

**03 → Problema: Hotel Queries.**

- **Pista 2 — patrón:** **descenso por el máximo**.
- **Pista 3 — diseño:** para cada grupo, baja desde la raíz al hijo izquierdo si su máximo alcanza, si no al derecho; resta el grupo a esa hoja y recalcula; si la raíz no alcanza, imprime 0.

**03 → Problema: Circular RMQ.**

- **Pista 2 — patrón:** **lazy de suma con mínimo** y tramos circulares partidos en dos.
- **Pista 3 — diseño:** si `l ≤ r`, un tramo; si no, `[l, n)` y `[0, r]`. La etiqueta suma, y el mínimo de un nodo sube lo mismo. Lectura de líneas con 2 o 3 números.

**03 → Problema: Range Updates and Sums.**

- **Pista 2 — patrón:** **lazy de suma y asignación**.
- **Pista 3 — diseño:** etiqueta `(asignar opcional, sumar)` compuesta como en la pregunta 9; la suma de un nodo se recalcula con su longitud. 64 bits.

**03 → Problema: Range Affine Range Sum.**

- **Pista 2 — patrón:** **lazy afín** `x ↦ b·x + c` módulo `998244353`.
- **Pista 3 — diseño:** aplicar `(b, c)` a un nodo de longitud `L`: `suma = b · suma + c · L`; componer `(b₂, c₂)` tras `(b₁, c₁)`: `(b₂b₁, b₂c₁ + c₂)`. Todo módulo; con `5·10⁵` operaciones, iterativo o recursivo bien escrito en C++.

---

# 04 — Segment tree avanzado

**04 → 1.** ¿Qué guarda cada nodo de un *merge sort tree*? 🟢

⏱️ **30 segundos.** La lista ordenada de los valores de su tramo.

🗣️ **2 minutos.** La raíz guarda todo el arreglo ordenado; cada hijo, su mitad ordenada; las hojas, un elemento. Se construye de abajo arriba mezclando las listas de los hijos, como la ordenación por mezcla.

🔬 **El detalle.** Cada nivel guarda los `n` elementos: `O(n log n)` de memoria.

**04 → 2.** ¿Qué es una estructura persistente? 🟢

⏱️ **30 segundos.** Una que conserva todas sus versiones: tras cada modificación, las versiones anteriores siguen disponibles para consultas (persistencia parcial) o incluso para modificaciones (total).

🗣️ **2 minutos.** No se copian enteras: se comparten las partes que no cambian. En un árbol, solo se copian los nodos del camino modificado.

🔬 **El detalle.** Las estructuras funcionales (inmutables) son persistentes por diseño.

**04 → 3.** ¿Qué guarda cada nodo de un árbol de Li Chao? 🟢

⏱️ **30 segundos.** Una recta: la que da el menor valor en el punto medio del tramo de abscisas del nodo, entre las que han llegado a él.

🗣️ **2 minutos.** Las demás rectas que pasaron por el nodo bajaron a uno de sus hijos. La consulta en `x` baja por el camino de `x` y toma el mínimo de las rectas de los nodos visitados.

🔬 **El detalle.** No guarda la envolvente: guarda lo justo para que el mínimo en cualquier `x` esté en algún nodo de su camino.

**04 → 4.** ¿Cómo se encuentra el `k`-ésimo menor en un segment tree sobre valores? 🟢

⏱️ **30 segundos.** Bajando desde la raíz: si el hijo izquierdo cuenta `≥ k` elementos, se baja a él; si no, se resta su cuenta a `k` y se baja al derecho. La hoja a la que se llega es el valor.

🗣️ **2 minutos.** Cada nodo cuenta cuántos elementos tienen un valor en su tramo de valores. El descenso es una búsqueda binaria sobre los valores guiada por las cuentas: `O(log V)`.

🔬 **El detalle.** Es lo mismo que la búsqueda por bits de Fenwick (`09/02`).

**04 → 5.** ¿Por qué una consulta en el *merge sort tree* cuesta `O(log² n)`? 🟡

⏱️ **30 segundos.** Porque el tramo se descompone en `O(log n)` nodos y en cada uno hay que hacer una búsqueda binaria en su lista ordenada.

🗣️ **2 minutos.** `O(log n)` nodos por `O(log n)` de búsqueda: `O(log² n)`. Con *fractional cascading* (enlazar las listas de cada nodo con las de sus hijos) baja a `O(log n)`, a costa de memoria y complejidad.

🔬 **El detalle.** En la práctica, con `n = 2·10⁵`, unos 300 pasos por consulta.

**04 → 6.** ¿Cuántos nodos nuevos crea una actualización en un segment tree persistente, y por qué? 🟡

⏱️ **30 segundos.** `⌈log₂ n⌉ + 1`: uno por nivel en el camino de la hoja a la raíz.

🗣️ **2 minutos.** Solo los nodos de ese camino cambian de valor; se crea una copia de cada uno que apunta al hijo nuevo por el lado del camino y al hijo viejo por el otro. Todo lo demás se comparte con la versión anterior.

🔬 **El detalle.** Una actualización de tramo con *lazy* también es persistente, copiando los nodos que toca y los hijos a los que se baja una etiqueta.

**04 → 7.** ¿Por qué, al insertar en Li Chao, la recta perdedora en el punto medio baja solo a una mitad? 🟠

⏱️ **30 segundos.** Porque dos rectas se cortan como mucho en un punto: si la nueva pierde en el medio, puede ganar solo en la mitad donde está el corte, y en la otra mitad pierde entera.

🗣️ **2 minutos.** Se compara en el medio y se deja en el nodo la ganadora. La perdedora gana, si acaso, en el lado donde está el corte; mirando quién gana en el extremo izquierdo se sabe si el corte está a la izquierda o a la derecha. Esa perdedora baja a esa mitad, y el proceso sigue: `O(log C)`.

🔬 **El detalle.** Lo mismo vale para cualquier familia de funciones que se cruzan como mucho una vez entre sí.

**04 → 8.** Demuestra que `q` actualizaciones persistentes crean `O(q log n)` nodos. 🟠

⏱️ **30 segundos.** Cada actualización copia solo los nodos de un camino raíz-hoja, uno por nivel: `⌈log₂ n⌉ + 1` nodos. `q` actualizaciones, `O(q log n)` nodos nuevos.

🗣️ **2 minutos.** La copia de un nodo apunta a la copia del hijo del camino y al hijo original del otro lado, de modo que la versión nueva es un árbol completo sin tocar la vieja. No se crea ningún otro nodo.

🔬 **El detalle.** Con `n = q = 2·10⁵`, unos `4·10⁶` nodos más los `4·10⁵` iniciales.

**04 → 9.** ¿Cómo responde un segment tree persistente sobre valores «el `k`-ésimo de `a[l..r]`»? 🟠

⏱️ **30 segundos.** Con versiones de prefijos: la versión `i` cuenta los valores de `a[0..i−1]`; bajando a la vez por las versiones `r + 1` y `l`, la diferencia de cuentas de cada nodo es la de `a[l..r]`, y el descenso del `k`-ésimo usa esa diferencia.

🗣️ **2 minutos.** Insertar `a[i]` en la versión `i` crea la versión `i + 1` con `O(log V)` nodos nuevos. La consulta no construye la diferencia: la calcula en cada nodo del camino. `O(log V)` por consulta, *online*.

🔬 **El detalle.** El *wavelet tree* ([`09/06`](06-arbol-cartesiano-y-wavelet.md)) responde lo mismo con menos memoria.

**04 → 10.** Compara la memoria que necesitan el *merge sort tree* y el persistente para `n = q = 2·10⁵` en C++ y en Java. 🟠

⏱️ **30 segundos.** *Merge sort tree*: `n log n ≈ 3,6·10⁶` enteros. Persistente: unos `4,4·10⁶` nodos, cada uno con dos hijos y un valor (tres enteros). En C++ y Java con arreglos planos: decenas de MB.

🗣️ **2 minutos.** En Java, el *merge sort tree* con un arreglo por nodo crea `4n` objetos; mejor un solo arreglo por nivel. El persistente con objetos `Node` añade cabeceras: con arreglos `izq[]`, `der[]`, `val[]` se evita. En C++, vectores de enteros.

🔬 **El detalle.** Con valores de 64 bits, la memoria se duplica en las sumas.

**04 → 11.** ¿Cuándo prefieres un Fenwick *offline* a un *merge sort tree*? 🟠

⏱️ **30 segundos.** Cuando las consultas se conocen de antemano: ordenándolas por `x` y activando los elementos `≤ x` en un Fenwick de posiciones, cada consulta es una suma de tramo. `O((n + q) log n)` con memoria `O(n)`.

🗣️ **2 minutos.** El *merge sort tree* responde *online* pero gasta `O(n log n)` de memoria y `O(log² n)` por consulta. Si el juez da todas las consultas juntas y no exige responder en orden con dependencia de la anterior, el *offline* es más corto y rápido.

🔬 **El detalle.** Es la técnica de `09/05` para consultas *offline*.

**04 → 12.** ¿Cómo cuentas los valores distintos de `a[l..r]` *online* con un segment tree persistente? 🔴

⏱️ **30 segundos.** Con versiones por posición: la versión `r` marca con un 1 la última aparición de cada valor hasta `r` (y quita la anterior); los distintos de `[l, r]` son la suma de `[l, r]` en la versión `r`.

🗣️ **2 minutos.** Es el método *offline* de [`09/03`](03-segment-tree.md) (pregunta 13) hecho persistente: cada posición `i` genera una versión que pone un 1 en `i` y un 0 en la aparición anterior de `a[i]`. Como cada versión queda guardada, las consultas se responden en cualquier orden. `O(log n)` por consulta, `O(n log n)` de memoria.

🔬 **El detalle.** Con dos actualizaciones por posición, la versión `r` se forma en dos pasos.

**04 → 13.** ¿Por qué Li Chao con segmentos (no rectas) cuesta `O(log² C)` por inserción? 🔴

⏱️ **30 segundos.** Porque un segmento solo existe en una parte de las abscisas: se descompone en `O(log C)` nodos del árbol (como un tramo en un segment tree), y en cada uno se inserta como una recta en `O(log C)`.

🗣️ **2 minutos.** En los nodos cuyo tramo está dentro del dominio del segmento, se comporta como una recta y baja según la regla de Li Chao. Son `O(log C)` nodos con `O(log C)` de bajada cada uno: `O(log² C)`.

🔬 **El detalle.** La consulta sigue siendo `O(log C)`.

**04 → Problema: Cuántos no superan el límite.**

- **Pista 2 — patrón:** **offline ordenando por `x`** con un Fenwick de posiciones (o *merge sort tree*).
- **Pista 3 — diseño:** ordena los elementos por valor y las consultas por `x`; para cada consulta, activa en el Fenwick las posiciones de los elementos `≤ x` que falten y responde la suma de `[l, r]`; guarda la respuesta en su índice original.

**04 → Problema: Versiones del inventario.**

- **Pista 2 — patrón:** **segment tree persistente** de sumas.
- **Pista 3 — diseño:** nodos en arreglos (`izq`, `der`, `suma`); la versión 0 se construye entera; cada `=` copia el camino a la hoja `p` desde la raíz de la versión `v` y guarda la raíz nueva; cada `?` consulta desde la raíz de su versión. Sumas en 64 bits.

**04 → Problema: Range Kth Smallest.**

- **Pista 2 — patrón:** **persistente sobre valores** con versiones de prefijos.
- **Pista 3 — diseño:** comprime los valores; la versión `i + 1` añade `a[i]`; cada consulta `[l, r)` baja a la vez por las versiones `r` y `l` usando la diferencia de cuentas del hijo izquierdo. `k` empieza en 0 en este juez.

**04 → Problema: Line Add Get Min.**

- **Pista 2 — patrón:** **Li Chao** sobre abscisas.
- **Pista 3 — diseño:** como todas las consultas y rectas se leen al principio, comprime las abscisas de las consultas y construye el Li Chao sobre ellas; valores en 64 bits (o `__int128` para los productos si hace falta).

**04 → Problema: Army Creation.**

- **Pista 2 — patrón:** **persistente sobre posiciones** con «la aparición `k` anterior».
- **Pista 3 — diseño:** para cada `i`, sea `prev[i]` la posición de la aparición de `a[i]` que está `k` apariciones antes (o −1); `i` cuenta en `[l, r]` si `prev[i] < l`. Con un persistente por posición que guarda los `prev`, cuenta en la versión `r` cuántos `prev < l` hay en `[l, r]`. *Online* por el cifrado de las consultas.

**04 → Problema: Segment Add Get Min.**

- **Pista 2 — patrón:** **Li Chao con segmentos**.
- **Pista 3 — diseño:** descompón el dominio de cada segmento en los nodos del árbol que lo cubren y aplica en cada uno la inserción de Li Chao; consultas como siempre. Abscisas comprimidas de las consultas.

**04 → Problema: Escape Through Leaf.**

- **Pista 2 — patrón:** **Li Chao + small-to-large** sobre el árbol.
- **Pista 3 — diseño:** `dp[v] = min sobre los descendientes u de (a[v] · b[u] + dp[u])`: un mínimo de rectas `y = b[u] · x + dp[u]` evaluado en `x = a[v]`. Cada nodo mantiene un Li Chao de las rectas de su subárbol; fusiona los de los hijos insertando las rectas del menor en el mayor.

---

# 05 — Raíz cuadrada y Mo

**05 → 1.** ¿Por qué el tamaño de bloque óptimo es `√n` en la descomposición en raíz? 🟢

⏱️ **30 segundos.** Porque una consulta cuesta `O(B)` por los trozos de los extremos más `O(n/B)` por los bloques enteros, y `B + n/B` es mínimo cuando `B = √n`.

🗣️ **2 minutos.** Si los bloques son grandes, los trozos de los extremos cuestan mucho; si son pequeños, hay muchos bloques que recorrer. El equilibrio está donde las dos partes valen lo mismo: `B = n/B`, es decir `B = √n`, y cada consulta cuesta `O(√n)`.

🔬 **El detalle.** Si las dos partes tienen costes distintos por elemento, el óptimo se desplaza (pregunta 9).

**05 → 2.** ¿Cuándo es legítimo procesar las consultas *offline*? 🟢

⏱️ **30 segundos.** Cuando todas las consultas se conocen antes de responder la primera y ninguna depende de la respuesta de otra.

🗣️ **2 minutos.** Si el enunciado da la lista completa de consultas, se pueden reordenar y responder en cualquier orden, guardando cada respuesta en su índice. No es legítimo si las consultas están «cifradas» con la respuesta anterior o si el problema es interactivo.

🔬 **El detalle.** Algunos jueces obligan al modo *online* precisamente para impedir Mo o el procesamiento por orden.

**05 → 3.** ¿En qué orden ordena Mo las consultas? 🟢

⏱️ **30 segundos.** Por el bloque del extremo izquierdo (`l / B`) y, dentro de cada bloque, por el extremo derecho `r`.

🗣️ **2 minutos.** Así `r` solo avanza dentro de cada bloque (`O(n)` por bloque) y `l` se mueve poco entre consultas consecutivas (`O(B)`). Con el zigzag, en los bloques impares `r` va en sentido contrario.

🔬 **El detalle.** Hay órdenes mejores (curva de Hilbert) que reducen el movimiento total en la práctica.

**05 → 4.** ¿Qué tiene que cumplir una pregunta de tramo para poder usar Mo? 🟡

⏱️ **30 segundos.** Que las consultas se puedan reordenar (*offline*) y que la respuesta de un tramo se pueda mantener al añadir o quitar un elemento por cualquiera de los dos extremos, idealmente en `O(1)`.

🗣️ **2 minutos.** Contar distintos, pares iguales o apariciones son añadir y quitar en `O(1)` con un arreglo de cuentas. Si quitar es imposible o caro (por ejemplo, el máximo), hace falta una variante (Mo con *rollback*, pregunta 13) o una estructura extra.

🔬 **El detalle.** Con añadir y quitar en `O(log n)`, Mo cuesta `O((n + q)√n log n)`, que suele ser demasiado.

**05 → 5.** ¿Por qué en Mo hay que ampliar el tramo antes de reducirlo? 🟡

⏱️ **30 segundos.** Para que el tramo nunca quede vacío «al revés» (`curL > curR + 1`), donde se quitarían elementos que no se han añadido y las cuentas pasarían por negativos.

🗣️ **2 minutos.** Si primero se reduce, puede que `curL` avance más allá de `curR` y se quiten elementos que no estaban en la estructura. Con cuentas que bajan de 0, el número de distintos se corrompe. Ampliando primero (`curR` hacia la derecha, `curL` hacia la izquierda), el tramo intermedio siempre contiene al nuevo.

🔬 **El detalle.** Con estructuras que toleran cuentas negativas temporales el orden importa menos, pero es más seguro fijarlo.

**05 → 6.** ¿Qué es el orden en zigzag y qué ahorra? 🟡

⏱️ **30 segundos.** Ordenar `r` creciente en los bloques pares y decreciente en los impares, para que `r` no tenga que volver al principio al cambiar de bloque.

🗣️ **2 minutos.** Sin zigzag, al acabar un bloque `r` está cerca de `n` y al empezar el siguiente baja hasta el `r` más pequeño de ese bloque: un recorrido completo por bloque desperdiciado. Con zigzag, ese tramo se recorre ya respondiendo consultas. En la práctica, casi la mitad del movimiento de `r`.

🔬 **El detalle.** No cambia la cota asintótica, solo la constante.

**05 → 7.** ¿Cómo cuentas los valores distintos de `[l, r]` *offline* con un Fenwick? 🟡

⏱️ **30 segundos.** Ordenando las consultas por `r` y recorriendo el arreglo: en cada posición `i`, un 1 en `i` y quitar el 1 de la aparición anterior de `a[i]`; las consultas con extremo `r = i` son sumas de `[l, r]` en el Fenwick.

🗣️ **2 minutos.** Con el extremo derecho fijo en `i`, cada valor distinto de `[l, i]` se cuenta una sola vez, en su última aparición; esa última aparición está en `[l, i]` si y solo si el valor aparece en el tramo. `O((n + q) log n)`.

🔬 **El detalle.** `09/03`, pregunta 13; la versión *online* usa persistencia (`09/04`).

**05 → 8.** Demuestra que Mo hace `O((n + q)√n)` movimientos de puntero. 🟠

⏱️ **30 segundos.** `r` se mueve `O(n)` por bloque de `l`, con `n/B` bloques: `O(n²/B)`. `l` se mueve `O(B)` por consulta: `O(qB)`. Con `B = √n` (o `n/√q`), `O((n + q)√n)`.

🗣️ **2 minutos.** Dentro de un bloque, las consultas están ordenadas por `r`, así que `r` es monótono y recorre como mucho `n` posiciones; al cambiar de bloque, otra vuelta como mucho. `l` siempre está dentro del bloque actual o pasa al siguiente: cada movimiento entre consultas consecutivas es `O(B)`. Sumando, `n · (n/B) + q · B`, mínimo con `B = n/√q`, que da `O(n√q)`, y con `q ≈ n`, `O(n√n)`.

🔬 **El detalle.** La cota exacta con `B = n/√q` es `O(n√q + q)`; se suele escribir `O((n + q)√n)`.

**05 → 9.** ¿Cómo eliges el tamaño de bloque si una parte de la consulta cuesta `O(log n)` por bloque? 🟠

⏱️ **30 segundos.** Igualando los costes de las dos partes: si los trozos cuestan `O(B)` y los bloques `O((n/B) log n)`, el óptimo es `B = √(n log n)`, con consultas en `O(√(n log n))`.

🗣️ **2 minutos.** En «cuántos `≥ x` en `[l, r]`» con bloques ordenados, cada bloque entero cuesta una búsqueda binaria (`log B`) y cada elemento de los trozos `O(1)`. Minimizar `B + (n/B) log B` da `B ≈ √(n log n)`. Las actualizaciones (reordenar un bloque) cuestan `O(B)` o `O(B log B)`, y entran en el balance si son frecuentes.

🔬 **El detalle.** En la práctica se prueba con varias constantes y se mide.

**05 → 10.** Compara si Mo es viable en C++, Java y Python con `n = q = 2·10⁵`, y qué harías en Python. 🟠

⏱️ **30 segundos.** En C++ sí, con margen; en Java sí, con arreglos de primitivos y lectura rápida; en Python casi nunca: `2·10⁸` pasos interpretados son minutos.

🗣️ **2 minutos.** En Python, se busca una solución `O((n + q) log n)` *offline* (orden por extremo + Fenwick) o se usan bibliotecas numéricas, que los jueces no siempre tienen. Con `n, q ≈ 10⁴`, Mo en Python sí entra.

🔬 **El detalle.** En Java, el `Comparator` con cajas de `Integer` para ordenar las consultas es lo de menos; el bucle de los punteros tiene que trabajar sobre `int[]`.

**05 → 11.** ¿Cómo mantiene Mo la **frecuencia máxima** del tramo, si quitar un elemento puede bajarla? 🟠

⏱️ **30 segundos.** Con dos arreglos: `cnt[v]` (apariciones de cada valor) y `cntOfCnt[f]` (cuántos valores aparecen `f` veces). Al quitar, si `cntOfCnt[maxf]` queda en 0, `maxf` baja en 1, porque la frecuencia del valor solo bajó en 1.

🗣️ **2 minutos.** Al añadir, `maxf = max(maxf, cnt[v])`. Al quitar un `v` con `cnt[v] = maxf`, ese valor pasa a `maxf − 1`, así que hay al menos un valor con frecuencia `maxf − 1`: si nadie queda con `maxf`, el nuevo máximo es `maxf − 1`. Todo `O(1)`.

🔬 **El detalle.** Para el **valor** más frecuente (la moda) en lugar de su frecuencia, hace falta más: Mo con *rollback* o descomposición en raíz con precálculo.

**05 → 12.** ¿Cómo funciona Mo con actualizaciones (una tercera dimensión, el tiempo), y con qué coste? 🔴

⏱️ **30 segundos.** Se añade el tiempo como tercera coordenada: las consultas se ordenan por `(bloque de l, bloque de r, t)` con bloques de `n^{2/3}`, y moverse en el tiempo aplica o deshace actualizaciones. Coste `O(n^{5/3})` con `n ≈ q`.

🗣️ **2 minutos.** Cada consulta lleva el número de actualizaciones anteriores a ella. Al pasar de una consulta a otra se mueven `l`, `r` y `t`; aplicar una actualización que cae dentro de `[curL, curR]` es quitar el valor viejo y añadir el nuevo. Con bloques de `n^{2/3}`, los tres movimientos suman `O(n^{5/3})`.

🔬 **El detalle.** Con `n = 10⁵`, `n^{5/3} ≈ 2·10⁸`: entra con constantes pequeñas.

**05 → 13.** ¿Cómo mantiene «Mo con *rollback*» operaciones que solo saben añadir? 🔴

⏱️ **30 segundos.** Para cada bloque de `l`, se reinicia la estructura con `curL` al final del bloque; `r` solo crece (añadir); para cada consulta, se añaden los elementos de `l` hasta el final del bloque, se responde y se **deshacen** esos añadidos con una pila. Nunca se quita nada «de verdad».

🗣️ **2 minutos.** Sirve cuando quitar es difícil (máximo, moda, Union-Find) pero deshacer los últimos añadidos es fácil. Las consultas con `l` y `r` en el mismo bloque se resuelven aparte por fuerza bruta (`O(B)`). El coste es el mismo `O((n + q)√n)`.

🔬 **El detalle.** Es la misma idea del Union-Find con *rollback* ([`08/04`](../08-heaps-y-union-find/04-union-find.md)): solo uniones y deshacer en orden inverso.

**05 → Problema: Pares iguales en el tramo.**

- **Pista 2 — patrón:** **Mo** con un arreglo de cuentas.
- **Pista 3 — diseño:** comprime los valores; al añadir `x`, los pares crecen en `cnt[x]` y después `cnt[x]++`; al quitar, `cnt[x]−−` y los pares bajan en `cnt[x]`. Respuestas en 64 bits.

**05 → Problema: Contar por encima con cambios.**

- **Pista 2 — patrón:** **descomposición en raíz** con una copia ordenada por bloque.
- **Pista 3 — diseño:** bloques de unos `√(n log n)`; cada bloque guarda sus valores ordenados; una consulta recorre los trozos de los extremos y hace una búsqueda binaria en cada bloque entero; una actualización cambia el valor y reordena (o recoloca con inserción) la copia de su bloque.

**05 → Problema: Range Frequency Queries.**

- **Pista 2 — patrón:** **lista de posiciones por valor** + **búsqueda binaria**.
- **Pista 3 — diseño:** un mapa de valor a la lista ordenada de sus posiciones; la respuesta es `upper_bound(right) − lower_bound(left)` en la lista del valor ([`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)).

**05 → Problema: Online Majority Element In Subarray.**

- **Pista 2 — patrón:** **candidato aleatorio** (o por bloques) y **comprobación** con posiciones por valor.
- **Pista 3 — diseño:** elige unas 20 posiciones al azar del tramo; para cada valor, cuenta sus apariciones en el tramo con dos búsquedas binarias en su lista de posiciones; si alguno llega al umbral, es la respuesta. La probabilidad de fallar es `≤ 2⁻²⁰`.

**05 → Problema: Distinct Values Queries.**

- **Pista 2 — patrón:** **offline por `r`** con un Fenwick (o Mo).
- **Pista 3 — diseño:** la plantilla de §5: un 1 en la última aparición de cada valor, quitando el de la anterior; cada consulta, al llegar a su `r`, suma `[l, r]`.

**05 → Problema: Static Range Count Distinct.**

- **Pista 2 — patrón:** **offline por `r`**.
- **Pista 3 — diseño:** la plantilla de §5 con tramos semiabiertos `[l, r)`: responde al procesar la posición `r − 1`; los tramos vacíos dan 0.

**05 → Problema: Little Elephant and Array.**

- **Pista 2 — patrón:** **Mo**, o **pocos candidatos**: solo los valores `x ≤ n` que aparecen al menos `x` veces en todo el arreglo.
- **Pista 3 — diseño:** hay como mucho `O(√n)` valores candidatos (los de suma de frecuencias acotada por `n`); para cada uno, prefijos de apariciones y respuesta por consulta en `O(1)`: `O((n + q)√n)` sin Mo.

**05 → Problema: Powerful array.**

- **Pista 2 — patrón:** **Mo** con la suma de `K² · s`.
- **Pista 3 — diseño:** al añadir `s` con `K` apariciones previas, la suma crece en `(2K + 1) · s`; al quitar, decrece en `(2K − 1) · s` con `K` las apariciones antes de quitar. 64 bits; lectura rápida.

**05 → Problema: XOR and Favorite Number.**

- **Pista 2 — patrón:** **Mo sobre los prefijos XOR**.
- **Pista 3 — diseño:** con prefijos `P`, el tramo `[l, r]` tiene XOR `k` si `P[r] ⊕ P[l − 1] = k`; Mo sobre los índices de prefijos `[l − 1, r]` contando pares con XOR `k` mediante `cnt[P ⊕ k]` al añadir y quitar. 64 bits.

**05 → Problema: Static Range Inversions Query.**

- **Pista 2 — patrón:** **Mo + Fenwick** de cuentas.
- **Pista 3 — diseño:** valores comprimidos; al añadir por la derecha un `x`, las inversiones crecen en los mayores que `x` ya presentes; por la izquierda, en los menores; al quitar, al revés. Cada paso es una consulta al Fenwick: `O((n + q)√n log n)`, que entra en C++.

---

# 06 — Árbol cartesiano y *wavelet tree*

**06 → 1.** ¿Qué dos propiedades tiene a la vez un árbol cartesiano? 🟢

⏱️ **30 segundos.** Es un BST por las posiciones (el inorden da el arreglo en su orden) y un montículo por los valores (cada nodo es menor que sus hijos, en el de mínimos).

🗣️ **2 minutos.** La raíz es el mínimo del arreglo; a su izquierda queda el árbol de lo que hay antes y a su derecha el de lo que hay después. Por eso el inorden recupera el arreglo y el camino de la raíz a un nodo tiene valores crecientes.

🔬 **El detalle.** Con valores repetidos, hay que fijar un desempate (por posición) para que el árbol sea único.

**06 → 2.** ¿Qué responde un *wavelet tree*? 🟢

⏱️ **30 segundos.** Sobre un arreglo estático: el `k`-ésimo menor de un tramo, cuántas veces aparece un valor en un tramo y cuántos valores de un tramo caen en un rango, todo en `O(log V)`.

🗣️ **2 minutos.** Es una estructura sobre el rango de valores (como un segment tree sobre valores) que conserva el orden original de las posiciones en cada nivel; por eso puede responder sobre tramos de posiciones y rangos de valores a la vez.

🔬 **El detalle.** En compresión de textos, el *wavelet tree* sobre el alfabeto es la base de los índices comprimidos (FM-index).

**06 → 3.** ¿Cómo se construye el árbol cartesiano con una pila? 🟢

⏱️ **30 segundos.** De izquierda a derecha con una pila de la rama derecha: al llegar `a[i]`, se sacan los mayores; el último sacado es hijo izquierdo de `i`, e `i` es hijo derecho de la nueva cima.

🗣️ **2 minutos.** La pila contiene los nodos que pueden recibir un hijo derecho (la rama derecha del árbol construido hasta `i − 1`), con valores crecientes. Los que se sacan pasan a colgar por la izquierda de `i` (todos los sacados forman una cadena, y el último sacado es la raíz de ella).

🔬 **El detalle.** Es la pila monótona de «anterior menor» de [`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md): el padre de `i` es el mayor entre su anterior menor y su siguiente menor.

**06 → 4.** ¿Por qué el árbol cartesiano es un *treap*? 🟡

⏱️ **30 segundos.** Porque un *treap* es un BST por claves y un montículo por prioridades; el árbol cartesiano es exactamente eso con las posiciones como claves y los valores como prioridades.

🗣️ **2 minutos.** El *treap* elige prioridades al azar para que el árbol sea balanceado en esperanza; el cartesiano usa los valores del arreglo, así que su altura depende de ellos (un arreglo ordenado da una cadena). Las dos estructuras son el árbol único determinado por (clave, prioridad).

🔬 **El detalle.** [`07/03`](../07-arboles/03-arboles-aleatorizados.md), §2.

**06 → 5.** ¿Qué guarda cada nodo de un *wavelet tree* y cómo se baja un tramo de un nodo a su hijo? 🟡

⏱️ **30 segundos.** Un arreglo de bits (0 si el valor va a la mitad baja de su rango, 1 si va a la alta) sobre la subsecuencia de valores que le llega, y los prefijos de ceros. Un tramo `[l, r)` del nodo baja al hijo izquierdo como `[ceros(l), ceros(r))` y al derecho como `[l − ceros(l), r − ceros(r))`.

🗣️ **2 minutos.** El hijo izquierdo recibe, en el mismo orden, los valores con bit 0; la posición de un elemento allí es el número de ceros antes de él. Por eso los prefijos de ceros traducen posiciones en `O(1)`.

🔬 **El detalle.** En la versión compacta, los prefijos se calculan con operaciones de *rank* sobre vectores de bits en `O(1)`.

**06 → 6.** ¿Cómo se encuentra el `k`-ésimo menor de `a[l..r]` con un *wavelet tree*? 🟡

⏱️ **30 segundos.** Bajando desde la raíz: si en el tramo hay `c ≥ k` ceros, el `k`-ésimo está en la mitad baja y se baja a la izquierda con el tramo traducido; si no, se baja a la derecha con `k − c`. La hoja final es el valor.

🗣️ **2 minutos.** Los ceros del tramo son los elementos del tramo con valor en la mitad baja: si son al menos `k`, el `k`-ésimo está entre ellos. Cada nivel es `O(1)` con los prefijos: `O(log V)`.

🔬 **El detalle.** Es el mismo descenso que el segment tree persistente sobre valores (`09/04`), sin necesidad de versiones.

**06 → 7.** Demuestra que el mínimo de `a[l..r]` está en el LCA de `l` y `r` en el árbol cartesiano. 🟠

⏱️ **30 segundos.** El LCA de `l` y `r` es el primer nodo, desde la raíz, que no deja a `l` y `r` en el mismo subárbol; ese nodo es el mínimo de un tramo que contiene a `[l, r]` y su posición está entre `l` y `r`: es el mínimo de `[l, r]`.

🗣️ **2 minutos.** Cada nodo `v` es el mínimo del tramo de posiciones de su subárbol. Bajando desde la raíz, mientras `l` y `r` estén en el mismo lado del nodo actual, se baja; el primer nodo `v` con `l ≤ pos(v) ≤ r` los separa (o es uno de ellos). Su tramo contiene a `[l, r]`, así que `a[v] ≤ min(a[l..r])`, y como `pos(v) ∈ [l, r]`, es el mínimo.

🔬 **El detalle.** Con la otra reducción (LCA → RMQ por Euler, `07/05`), los dos problemas son equivalentes.

**06 → 8.** ¿Por qué la construcción con pila es `O(n)`? 🟠

⏱️ **30 segundos.** Porque cada posición entra en la pila una vez y sale como mucho una vez: el número total de `pop` es `≤ n`.

🗣️ **2 minutos.** El `while` que saca los mayores puede hacer muchas vueltas en un paso, pero en total no más que el número de elementos apilados. Es el análisis agregado de la pila monótona ([`02/03`](../02-analisis/03-analisis-amortizado.md), `06/01`).

🔬 **El detalle.** La alternativa recursiva (buscar el mínimo y recursar) es `O(n²)` en el peor caso, u `O(n log n)` con una *sparse table*.

**06 → 9.** ¿Cómo cuentas con un *wavelet tree* los valores de `a[l..r]` que caen en `[x, y]`? 🟠

⏱️ **30 segundos.** Bajando a la vez por las dos fronteras, como en un segment tree: los nodos cuyo rango de valores está dentro de `[x, y]` aportan la longitud de su tramo traducido; los que lo cortan, se exploran.

🗣️ **2 minutos.** Es una consulta de rango sobre los valores en la que, en cada nivel, el tramo de posiciones se traduce con los prefijos. Se visitan `O(log V)` nodos. Equivale a `cuenta(≤ y) − cuenta(≤ x − 1)`, cada una con un descenso.

🔬 **El detalle.** Las apariciones de `x` son el caso `[x, x]`.

**06 → 10.** Compara para el `k`-ésimo de un tramo el *wavelet tree*, el persistente y el *merge sort tree*: memoria y tiempo en C++ o Java. 🟠

⏱️ **30 segundos.** *Wavelet*: `O(log V)` por consulta y `O(n log V)` enteros. Persistente: `O(log V)` por consulta y `O(n log V)` nodos de tres enteros. *Merge sort tree*: `O(log³ n)` con binaria sobre el valor y `O(n log n)` enteros.

🗣️ **2 minutos.** El *wavelet* tiene la mejor constante de memoria y una consulta igual de rápida que el persistente. El *merge sort tree* es el más fácil de escribir, pero su consulta para el `k`-ésimo necesita una binaria externa sobre el valor. En Java, los tres con arreglos planos.

🔬 **El detalle.** Con `n = 2·10⁵` y `V` comprimido a `n`, `log V ≈ 18`: unos 3,6 millones de enteros en el *wavelet*.

**06 → 11.** Con el árbol cartesiano, ¿cómo calculas en cuántos subarreglos es mínimo cada elemento? 🟠

⏱️ **30 segundos.** El elemento `v` es el mínimo de los subarreglos que empiezan en su subárbol izquierdo (o en `v`) y acaban en su subárbol derecho (o en `v`): `(tamaño izquierdo + 1) · (tamaño derecho + 1)`.

🗣️ **2 minutos.** El tramo donde `v` es el mínimo es el de su subárbol en el árbol cartesiano; un subarreglo tiene a `v` como mínimo si contiene a `v` y no sale de ese tramo. Con valores repetidos, se fija un desempate para no contar dos veces.

🔬 **El detalle.** Es lo mismo que el producto de las distancias al anterior y al siguiente menor de `06/01`.

**06 → 12.** ¿Cómo se obtiene RMQ en `O(n)`/`O(1)` a partir del árbol cartesiano? 🔴

⏱️ **30 segundos.** Partiendo en bloques de `≈ log n / 4`: una *sparse table* sobre los mínimos de bloque y, dentro de cada bloque, tablas precalculadas por la **forma** de su árbol cartesiano, que con ese tamaño son `O(√n)` formas distintas.

🗣️ **2 minutos.** Dos bloques con el mismo árbol cartesiano tienen el mínimo de cualquier subtramo en la misma posición relativa, así que comparten tabla. La forma se codifica con la secuencia de `push` y `pop` de la pila de construcción (`2b` bits). El total es `O(n)` de preproceso y `O(1)` por consulta.

🔬 **El detalle.** cp-algorithms, *Linear RMQ*; la versión práctica usa máscaras de bits por posición en lugar de tablas por forma.

**06 → Problema: El árbol de los mínimos.**

- **Pista 2 — patrón:** **construcción con pila** del árbol cartesiano.
- **Pista 3 — diseño:** recorre con una pila de índices de valores crecientes; al sacar, recuerda el último sacado; su padre es `i`; el padre de `i` es la cima que queda (si la hay). Si no queda cima, `i` es raíz por ahora.

**06 → Problema: El `k`-ésimo del tramo.**

- **Pista 2 — patrón:** **wavelet tree** (o persistente sobre valores).
- **Pista 3 — diseño:** comprime los valores a `0..V−1`; construye los niveles con los prefijos de ceros; cada consulta baja `log V` niveles comparando los ceros del tramo con `k`.

**06 → Problema: Cartesian Tree.**

- **Pista 2 — patrón:** **construcción con pila** del árbol cartesiano de mínimos.
- **Pista 3 — diseño:** la pila monótona de §3 (los valores son distintos, así que no hay empates); imprime el padre de cada posición, con la raíz como su propia posición, que es lo que pide el formato de salida.

**06 → Problema: Static Range Frequency.**

- **Pista 2 — patrón:** **posiciones por valor** + **búsqueda binaria** (o *wavelet*).
- **Pista 3 — diseño:** un mapa de valor a la lista ordenada de posiciones; cada consulta `[l, r)` con valor `x` es `lower_bound(r) − lower_bound(l)` en su lista.

**06 → Problema: Destiny.**

- **Pista 2 — patrón:** **candidatos en posiciones fijas del tramo ordenado** + `k`-ésimo de tramo.
- **Pista 3 — diseño:** un valor que aparece más de `len/k` veces ocupa alguna de las posiciones `len/k, 2·len/k, …` del tramo ordenado: obtén esos `k − 1` candidatos con el `k`-ésimo de tramo (persistente o *wavelet*) y comprueba la frecuencia de cada uno; quédate con el menor que cumpla.

---

# 07 — Simulación

**07 → S1.** ¿Por qué la *sparse table* responde el mínimo en `O(1)` y no sirve para la suma? 🟡

⏱️ **30 segundos.** Porque cubre el tramo con dos bloques de longitud potencia de 2 que pueden solaparse, y el mínimo de algo contado dos veces no cambia; la suma contaría dos veces la intersección.

🗣️ **2 minutos.** La consulta es `min(st[k][l], st[k][r − 2ᵏ + 1])`: dos lecturas. La corrección exige `x ⊕ x = x` (idempotencia): mínimo, máximo, `gcd` sí; suma, producto, *xor* no.

🔬 **El detalle.** [`09/01`](01-sparse-table.md), §2.

**07 → S2.** ¿Qué usas para sumas de tramos sin actualizaciones? 🟢

⏱️ **30 segundos.** Prefijos: `O(n)` de preproceso y `O(1)` por consulta.

🗣️ **2 minutos.** `suma(l, r) = P[r + 1] − P[l]`. Ninguna estructura del bloque mejora eso sin actualizaciones.

🔬 **El detalle.** `04/01`.

**07 → S3.** ¿Qué tramo guarda `tree[i]` en un Fenwick? 🟢

⏱️ **30 segundos.** El tramo `(i − (i & −i), i]`: los `i & −i` elementos que acaban en `i`.

🗣️ **2 minutos.** `i & −i` es la potencia de 2 del bit más bajo de `i`. Los índices impares guardan un solo elemento; las potencias de 2, el prefijo entero.

🔬 **El detalle.** `09/02`, §2.

**07 → S4.** ¿Cómo sumas `v` a un tramo y consultas un punto con un Fenwick? 🟡

⏱️ **30 segundos.** Sobre el arreglo de diferencias: `add(l, v)` y `add(r + 1, −v)`; el valor de `a[i]` es `prefix(i)`.

🗣️ **2 minutos.** El arreglo de diferencias convierte el cambio de tramo en dos cambios puntuales y el valor puntual en un prefijo. El Fenwick necesita tamaño `n + 1`.

🔬 **El detalle.** `09/02`, §4.

**07 → S5.** ¿Por qué Fenwick empieza en el índice 1? 🟢

⏱️ **30 segundos.** Porque `0 & −0 = 0`: con el índice 0, la actualización no avanza nunca y entra en un bucle infinito.

🗣️ **2 minutos.** La estructura se basa en el bit más bajo del índice, y el 0 no tiene. Si los datos vienen desde 0, se suma 1 al índice al llamar.

🔬 **El detalle.** `09/02`, pregunta 2.

**07 → S6.** ¿Qué necesita una operación para poder usarse en un segment tree? 🟢

⏱️ **30 segundos.** Que sea asociativa y tenga un elemento neutro (un monoide).

🗣️ **2 minutos.** La asociatividad permite combinar los nodos de la descomposición del tramo; el neutro sirve de valor inicial y de respuesta fuera del tramo. No hace falta que sea conmutativa ni invertible.

🔬 **El detalle.** `09/03`, §2.

**07 → S7.** ¿Qué es `push` en la propagación perezosa y cuándo se llama? 🟡

⏱️ **30 segundos.** Bajar la etiqueta sin aplicar de un nodo a sus hijos (aplicándola a sus valores y componiéndola con sus etiquetas). Se llama antes de entrar en los hijos, en actualizaciones y consultas.

🗣️ **2 minutos.** Los nodos cubiertos por completo no necesitan `push`. Los cortados, sí: sus hijos van a leerse o modificarse y tienen que reflejar las actualizaciones pendientes del padre.

🔬 **El detalle.** `09/03`, §5.

**07 → S8.** ¿Cómo se componen «asignar» y «sumar» en una etiqueta *lazy*? 🟡

⏱️ **30 segundos.** La etiqueta es un par (asignar opcional, sumar). «Asignar `x`» después de cualquier cosa deja «asignar `x`»; «sumar `y`» después de «asignar `x`» deja «asignar `x + y`»; después de «sumar `a`», «sumar `a + y`».

🗣️ **2 minutos.** Las dos son casos de la afín `x ↦ b·x + c` (asignar: `b = 0`; sumar: `b = 1`), y la composición de afines es afín. Aplicarla a un nodo de suma con longitud `L`: `b · suma + c · L`.

🔬 **El detalle.** `09/03`, pregunta 9.

**07 → S9.** ¿Cuántos nodos crea una actualización en un segment tree persistente? 🟡

⏱️ **30 segundos.** `⌈log₂ n⌉ + 1`: una copia de cada nodo del camino de la hoja a la raíz.

🗣️ **2 minutos.** Las copias apuntan al hijo nuevo por el lado del camino y al viejo por el otro; todo lo demás se comparte con la versión anterior.

🔬 **El detalle.** `09/04`, §2.

**07 → S10.** ¿Qué exige Mo y cuánto cuesta? 🟡

⏱️ **30 segundos.** Consultas reordenables (*offline*) y una respuesta que se mantiene añadiendo y quitando elementos por los extremos. Cuesta `O((n + q)√n)` movimientos.

🗣️ **2 minutos.** Se ordenan por `(l / B, r)` y se mueven dos punteros. Con añadir y quitar en `O(1)`, el total es `O((n + q)√n)`.

🔬 **El detalle.** `09/05`, §2.

**07 → S11.** Tu Fenwick entra en un bucle infinito con la primera actualización. ¿Qué miras? 🟠

⏱️ **30 segundos.** Si alguna llamada usa el índice 0: `i & −i = 0` y `i += 0` no avanza.

🗣️ **2 minutos.** El fallo típico es pasar índices 0-indexados sin sumar 1, o llamar a `add(r + 1, …)` con un Fenwick demasiado pequeño, que se sale del arreglo (otro error, distinto del bucle).

🔬 **El detalle.** `09/02`, §3.

**07 → S12.** Te piden el mínimo de un tramo con actualizaciones y escribes un Fenwick. ¿Qué falla? 🟠

⏱️ **30 segundos.** Que el mínimo no es invertible: Fenwick responde tramos restando prefijos, y el mínimo no se resta. Hace falta un segment tree.

🗣️ **2 minutos.** Un Fenwick de mínimos solo sirve para mínimos de **prefijos** y si los valores solo bajan. Con tramos arbitrarios o valores que suben, un segment tree de mínimos.

🔬 **El detalle.** `09/02`, pregunta 9.

**07 → S13.** Tu segment tree con *lazy* pasa las actualizaciones y falla en las consultas que tocan nodos ya etiquetados. ¿Dónde está el error? 🟠

⏱️ **30 segundos.** En que la consulta no hace `push` antes de bajar a los hijos de un nodo con etiqueta: lee hijos desactualizados.

🗣️ **2 minutos.** La actualización etiqueta los nodos cubiertos y no baja; si después una consulta entra en uno de esos nodos para mirar sus hijos, primero tiene que propagar la etiqueta. Sin `push` en la consulta, las actualizaciones parecen funcionar (la raíz se recalcula bien) pero los tramos parciales salen mal.

🔬 **El detalle.** `09/03`, pregunta 6.

**07 → S14.** «Mo es lento porque es `√n`.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que `(n + q)√n` con `2·10⁵` son unos `2·10⁸` pasos sencillos, que entran en un segundo en C++ y Java. Lo importante es la constante de añadir y quitar.

🗣️ **2 minutos.** Si hay una solución *offline* por extremos en `O((n + q) log n)`, es mejor; si no, Mo es una herramienta perfectamente válida. En Python sí suele ser lento.

🔬 **El detalle.** `09/05`, §1.

**07 → S15.** Te dan un arreglo que no cambia y `10⁶` consultas de suma de tramo. Un compañero propone un segment tree. ¿Qué le dices? 🟠

⏱️ **30 segundos.** Que sin cambios basta con prefijos: `O(1)` por consulta y una línea de código; el segment tree es `O(log n)` y mucho más código.

🗣️ **2 minutos.** Con `10⁶` consultas, `O(log n)` son unos `2·10⁷` pasos, que también entran, pero los prefijos son más rápidos, más cortos y sin errores posibles. La estructura se elige por las operaciones que hay, no por las que podría haber.

🔬 **El detalle.** `09/01`, §5.

**07 → S16.** Demuestra que una consulta de tramo en un segment tree visita `O(log n)` nodos. 🔴

⏱️ **30 segundos.** En cada nivel, como mucho dos nodos están cortados por el tramo (los que contienen sus extremos); solo esos se exploran, así que se visitan como mucho 4 nodos por nivel.

🗣️ **2 minutos.** Los nodos de un nivel forman una partición del arreglo; un tramo contiguo corta como mucho al que contiene `l` y al que contiene `r − 1`. Los cubiertos se usan sin bajar; los de fuera se descartan. Por inducción, como mucho 2 nodos cortados por nivel y 4 visitas.

🔬 **El detalle.** `09/03`, pregunta 8.

**07 → S17.** Demuestra que Mo hace `O((n + q)√n)` movimientos de puntero. 🔴

⏱️ **30 segundos.** `r` se mueve `O(n)` por bloque de `l` (monótono dentro del bloque), con `n/B` bloques; `l` se mueve `O(B)` por consulta. Con `B = √n`, `O((n + q)√n)`.

🗣️ **2 minutos.** Sumando, `n · (n/B) + q · B`; el mínimo está en `B = n/√q`, que da `O(n√q)`, y con `q ≈ n`, `O(n√n)`.

🔬 **El detalle.** `09/05`, pregunta 8.

**07 → Problema: Pintar la valla.**

- **Pista 2 — patrón:** **lazy de asignación** con suma de tramo.
- **Pista 3 — diseño:** etiqueta «asignar `c`» (con una marca de «sin etiqueta»); aplicar a un nodo de longitud `L` deja su suma en `c · L`; componer: la nueva manda. Sumas en 64 bits.

**07 → Problema: Valores que se repiten dos veces.**

- **Pista 2 — patrón:** **Mo** con un arreglo de cuentas.
- **Pista 3 — diseño:** comprime los valores; al añadir `x`, si `cnt[x]` pasa de 1 a 2 la respuesta sube y si pasa de 2 a 3 baja; al quitar, al revés.

**07 → Problema: Caja registradora.**

- **Pista 2 — patrón:** **Fenwick** puntual/rango.
- **Pista 3 — diseño:** construye el Fenwick con las recaudaciones (índices + 1); `+` es `add`, `?` es `range`. 64 bits.

**07 → Problema: Ventas acumuladas.**

- **Pista 2 — patrón:** **prefijos**.
- **Pista 3 — diseño:** `P[0] = 0`, `P[i + 1] = P[i] + a[i]` en 64 bits; cada consulta, `P[r + 1] − P[l]`. Con `10⁶` consultas, lectura y escritura rápidas.

**07 → Problema: Static Range Sum.**

- **Pista 2 — patrón:** **prefijos**.
- **Pista 3 — diseño:** tramos semiabiertos `[l, r)`: `P[r] − P[l]`, en 64 bits.

**07 → Problema: Count Number of Teams.**

- **Pista 2 — patrón:** **contar por el elemento central**: menores y mayores a cada lado.
- **Pista 3 — diseño:** para cada `j`, cuenta menores y mayores a su izquierda y a su derecha (con `n ≤ 1000`, en `O(n)` cada uno; con más, Fenwick); suma `menIzq · mayDer + mayIzq · menDer`.

**07 → Problema: Point Set Range Composite.**

- **Pista 2 — patrón:** **segment tree de composición** de funciones afines.
- **Pista 3 — diseño:** cada nodo guarda la afín compuesta de su tramo; la composición no es conmutativa: el segment tree iterativo con `resl` y `resr` por separado; todo módulo `998244353`.

**07 → Problema: Subarray Sum Queries.**

- **Pista 2 — patrón:** **segment tree con nodo de cuatro campos**.
- **Pista 3 — diseño:** suma, mejor prefijo, mejor sufijo y mejor tramo (con el vacío permitido, mínimo 0); combina como en `09/03`, pregunta 12; tras cada cambio, la respuesta es el mejor tramo de la raíz.

**07 → Problema: Number of Pairs Satisfying Inequality.**

- **Pista 2 — patrón:** **contar pares** con un Fenwick sobre valores comprimidos (o mezcla).
- **Pista 3 — diseño:** con `d[i] = nums1[i] − nums2[i]`, la condición es `d[i] ≤ d[j] + diff` con `i < j`; recorre `j`, cuenta los `d[i] ≤ d[j] + diff` ya vistos con un Fenwick sobre los valores comprimidos y después añade `d[j]`.

**07 → Problema: Prefix Sum Queries.**

- **Pista 2 — patrón:** **segment tree con suma y mejor prefijo**.
- **Pista 3 — diseño:** cada nodo guarda la suma y el mejor prefijo (con el vacío, 0); combinar: `pref = max(L.pref, L.suma + R.pref)`; la consulta combina en orden los nodos del tramo.
