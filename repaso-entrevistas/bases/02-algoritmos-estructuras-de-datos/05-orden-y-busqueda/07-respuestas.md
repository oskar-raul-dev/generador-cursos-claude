# Respuestas — bloque 05: Orden y búsqueda

> Solucionario del bloque `05`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--ordenación-por-comparación) · [02](#02--ordenación-lineal) · [03](#03--inversiones-selección-y-mediana) · [04](#04--búsqueda-binaria) · [05](#05--búsqueda-ternaria-unimodales-y-exponencial) · [06](#06--simulación)

---

# 01 — Ordenación por comparación

**01 → 1.** ¿Qué es una ordenación estable? Da un algoritmo estable y otro que no lo sea. 🟢

⏱️ **30 segundos.** Estable es la que deja dos elementos de clave igual en el mismo orden relativo que en la entrada. La mezcla y la inserción lo son; *quicksort* y *heapsort*, no.

🗣️ **2 minutos.** La estabilidad importa cuando el orden de entrada ya codifica un criterio: si los registros llegan por orden alfabético y se ordenan de forma estable por puntuación, los empates quedan en orden alfabético. Con una ordenación no estable, el orden de los empates es arbitrario.

🔬 **El detalle.** La estabilidad depende de detalles de implementación: la inserción con `>=` en lugar de `>` deja de serlo, y la mezcla que toma de la derecha en los empates también.

**01 → 2.** ¿Cuánto cuesta la ordenación por mezcla en el caso peor y cuánta memoria usa? 🟢

⏱️ **30 segundos.** `Θ(n log n)` en el caso peor, y también en el mejor y el promedio; `Θ(n)` de memoria auxiliar para el búfer de la mezcla, más `Θ(log n)` de pila.

🗣️ **2 minutos.** La recurrencia es `T(n) = 2T(n/2) + Θ(n)`: dos mitades y una mezcla lineal. Es el caso 2 del teorema maestro ([`02/02`](../02-analisis/02-recurrencias-y-teorema-maestro.md)): `log n` niveles con `Θ(n)` de trabajo cada uno. No depende de cómo vengan los datos.

🔬 **El detalle.** Sobre una lista enlazada, la mezcla se hace reenlazando nodos sin búfer: la memoria queda en la pila de la recursión, o en `Θ(1)` con la versión de abajo arriba.

**01 → 3.** ¿Qué algoritmo usan `std::sort`, `Arrays.sort` sobre objetos y `sorted` de Python? 🟢

⏱️ **30 segundos.** `std::sort` usa *introsort* (no estable); `Arrays.sort` sobre objetos, TimSort (estable); `sorted` de Python, TimSort (estable).

🗣️ **2 minutos.** *Introsort* es *quicksort* con un respaldo de *heapsort* cuando la recursión se hace demasiado profunda y con inserción en los tramos pequeños: `O(n log n)` garantizado. TimSort detecta tramos ya ordenados y los mezcla: estable, `O(n log n)` en el caso peor y lineal con datos ordenados.

🔬 **El detalle.** `Arrays.sort` sobre primitivos es otra cosa: *quicksort* de doble pivote, con respaldo de *heapsort* desde Java 14 ([`03/03`](../03-biblioteca-estandar/03-java-colecciones.md)). Como dos `int` iguales son indistinguibles, la estabilidad no importa ahí.

**01 → 4.** ¿Qué diferencia hay entre el caso promedio de *quicksort* con pivote fijo y el caso esperado con pivote aleatorio? 🟡

⏱️ **30 segundos.** El caso promedio supone que la **entrada** es aleatoria; el esperado con pivote aleatorio es un promedio sobre las **elecciones del algoritmo**, y vale para cualquier entrada.

🗣️ **2 minutos.** Con pivote fijo, el `n log n` promedio depende de que nadie elija la entrada: un adversario, o simplemente una entrada ya ordenada, provoca el `n²`. Con pivote aleatorio no hay entradas malas: la mala suerte depende de las monedas del algoritmo, no de los datos ([`02/01`](../02-analisis/01-notacion-asintotica.md)).

🔬 **El detalle.** Con una semilla fija y conocida, el adversario vuelve a poder preparar la entrada: por eso en jueces con *hacks* se siembra con el reloj.

**01 → 5.** ¿Qué diferencia hay entre las particiones de Lomuto y de Hoare, en intercambios y en lo que devuelven? 🟡

⏱️ **30 segundos.** Lomuto recorre con un índice y deja el pivote en su sitio final, que devuelve; Hoare recorre con dos índices desde los extremos, hace menos intercambios y devuelve un corte `j` que no es la posición del pivote.

🗣️ **2 minutos.** Con Lomuto, las llamadas son `[lo, p−1]` y `[p+1, hi]`. Con Hoare, `[lo, j]` y `[j+1, hi]`: todo lo de la izquierda es `≤` pivote y todo lo de la derecha `≥`, pero el pivote puede estar en cualquiera de las dos. Hoare hace en promedio unas tres veces menos intercambios.

🔬 **El detalle.** Con todos los elementos iguales, Lomuto con `<` deja una partición vacía en cada paso: cuadrático. Hoare para los dos índices en cada igual y corta por la mitad.

**01 → 6.** ¿Por qué el coste de la inserción depende del número de inversiones? 🟡

⏱️ **30 segundos.** Porque cada desplazamiento corrige exactamente una inversión: el par formado por la clave que se inserta y un mayor que estaba delante.

🗣️ **2 minutos.** Al insertar `a[j]`, se desplazan los elementos de delante que son estrictamente mayores, que son exactamente los que forman inversión con él. Sumando sobre todos los `j`, el total de desplazamientos es el número de inversiones `I`, y el coste es `Θ(n + I)`.

🔬 **El detalle.** `I` va de 0 (ordenado) a `n(n−1)/2` (al revés). Contar `I` sin ejecutar la inserción se hace en `O(n log n)` con la mezcla ([`05/03`](03-inversiones-y-seleccion.md)).

**01 → 7.** Demuestra la cota inferior `Ω(n log n)` con el árbol de decisión. 🟠

⏱️ **30 segundos.** El árbol de decisión tiene al menos `n!` hojas; un árbol binario de altura `h` tiene como mucho `2ʰ`; luego `h ≥ log₂ n! = Θ(n log n)`.

🗣️ **2 minutos.** Cada ejecución sobre `n` elementos distintos sigue un camino del árbol; cada comparación es un nodo y cada hoja produce una permutación. Si dos entradas distintas llegaran a la misma hoja, recibirían la misma permutación y una de las dos saldría mal ordenada: hacen falta al menos `n!` hojas. Como `n! ≥ (n/2)^{n/2}`, `log₂ n! ≥ (n/2) log₂(n/2)`, que es `Ω(n log n)`.

🔬 **El detalle.** La cota vale también para el caso promedio: en un árbol binario con `n!` hojas, la profundidad media de las hojas es al menos `log₂ n!`. Y vale para algoritmos aleatorios en esperanza.

**01 → 8.** Compara la estabilidad de las ordenaciones de librería de C++, Java y Python, y qué haces en C++ si la necesitas. 🟠

⏱️ **30 segundos.** C++: `std::sort` no es estable, `std::stable_sort` sí. Java: primitivos no (da igual), objetos sí. Python: siempre estable. En C++, si la necesito, `std::stable_sort`.

🗣️ **2 minutos.** La otra salida en C++ es hacer la clave única añadiendo el índice original como último criterio de desempate: ordenar pares `(clave, índice)` con `std::sort` da el mismo resultado que ordenar de forma estable por la clave.

🔬 **El detalle.** `std::stable_sort` intenta reservar un búfer; si no puede, cae a una versión `O(n log² n)` en el sitio. En Python, la estabilidad permite ordenar por varios criterios en pasadas sucesivas, del menos al más importante.

**01 → 9.** ¿Por qué *quicksort* con Hoare usa comparaciones estrictas, y qué pasa con muchos valores repetidos si no? 🟠

⏱️ **30 segundos.** Para que los iguales al pivote detengan los dos índices y se repartan entre las dos mitades; sin eso, con muchos repetidos, las particiones salen desequilibradas y el coste se va a `n²`.

🗣️ **2 minutos.** Con `<` y `>` estrictos, cada índice se para en cualquier elemento igual al pivote y se intercambian: con todos los valores iguales, los índices se encuentran en el centro y el corte es equilibrado. Con `<=`, el índice izquierdo correría hasta el final y la partición dejaría un lado vacío.

🔬 **El detalle.** El pivote mismo actúa de centinela: como está en el arreglo, cada índice encuentra un elemento que lo detiene sin salirse del rango. La alternativa con muchos iguales es la partición de tres vías (menores, iguales, mayores).

**01 → 10.** ¿Por qué *heapsort* no es estable? Da un ejemplo de dos elementos iguales que cambian de orden. 🟠

⏱️ **30 segundos.** Porque el intercambio de la raíz con el último del montículo mueve elementos a larga distancia, por encima de sus iguales.

🗣️ **2 minutos.** Con `[1a, 1b]` (dos claves 1, distinguidas por su etiqueta), el montículo de máximos ya es `[1a, 1b]`. La primera extracción intercambia la raíz con el último: `[1b, 1a]`, y la salida es `1b, 1a`. Los dos iguales cambiaron de orden.

🔬 **El detalle.** La misma razón vale para *quicksort*: todo algoritmo que intercambia a distancia sin mirar los iguales intermedios pierde la estabilidad. Se recupera desempatando por el índice original.

**01 → 11.** Escribe el invariante de la mezcla y demuestra que tomar de la izquierda en caso de empate la hace estable. 🔴

⏱️ **30 segundos.** Invariante: la salida contiene, ordenados, los `k` menores de las dos mitades. Tomar de la izquierda en los empates mantiene antes a los iguales que venían antes.

🗣️ **2 minutos.** Inicio: salida vacía. Mantenimiento: las cabezas `L[i]` y `R[j]` son las menores de lo que queda en cada mitad; la menor de las dos es la menor de todo lo que queda, y añadirla mantiene la salida ordenada con los `k + 1` menores. Terminación: cuando una mitad se agota, el resto de la otra es mayor o igual que todo lo de la salida. Estabilidad: todo elemento de la mitad izquierda iba antes, en la entrada, que todo elemento de la derecha; si `L[i] = R[j]` se toma `L[i]`, y dentro de cada mitad el orden se conserva por inducción.

🔬 **El detalle.** Con `<=` para tomar de la derecha, en un empate saldría primero el de la derecha: sigue ordenando bien, pero ya no es estable.

**01 → 12.** Calcula el número esperado de comparaciones de *quicksort* aleatorio con el argumento de los pares, y di dónde aparece el `2 n ln n`. 🔴

⏱️ **30 segundos.** Los elementos `i`-ésimo y `j`-ésimo del orden final se comparan si y solo si uno de ellos es el primer pivote elegido de los `j − i + 1` que hay entre ellos: probabilidad `2/(j − i + 1)`. La suma es `≈ 2n ln n`.

🗣️ **2 minutos.** Sea `X` el número de comparaciones y `X_ij` el indicador de que se comparan. Mientras ningún elemento entre `z_i` y `z_j` sea pivote, siguen juntos; el primero de ese tramo en ser pivote decide: si es `z_i` o `z_j`, se comparan; si es otro, los separa para siempre. Por linealidad, `E[X] = Σ_{i<j} 2/(j−i+1) = Σ_i Σ_{k=1}^{n−i} 2/(k+1) < 2n·H_n`, y `H_n ≈ ln n`.

🔬 **El detalle.** `2n ln n = 2 ln 2 · n log₂ n ≈ 1,39 n log₂ n`: unas 39 % más comparaciones que la cota inferior. CLRS, 3.ª ed., §7.4.

**01 → 13.** Demuestra que un *quicksort* que toma como pivote la mediana exacta (calculada en lineal, `05/03`) es `Θ(n log n)` en el caso peor, y explica por qué las librerías no lo hacen. 🔴

⏱️ **30 segundos.** Con la mediana como pivote, cada partición deja dos mitades de `⌊n/2⌋` como mucho: `T(n) ≤ 2T(n/2) + Θ(n)`, que es `Θ(n log n)` en el caso peor. No se usa porque la mediana lineal tiene una constante enorme.

🗣️ **2 minutos.** La partición cuesta `Θ(n)` y la selección determinista de la mediana (mediana de medianas, `05/03`) también `Θ(n)`: el trabajo por nivel sigue siendo lineal, y la recursión tiene `log₂ n` niveles por el teorema maestro, caso 2 (`02/02`). Pero la mediana de medianas hace varias pasadas y muchas comparaciones por elemento: el resultado es varias veces más lento que el *quicksort* aleatorio en todas las entradas, para evitar un caso peor que el pivote aleatorio ya hace improbable.

🔬 **El detalle.** Las librerías consiguen la misma garantía más barato: *introsort* corre *quicksort* normal y solo cambia a *heapsort* cuando detecta que la recursión se degenera.

**01 → Problema: Clasificación estable.**

- **Pista 2 — patrón:** **ordenación estable** por una clave, o **desempate por el índice** de inscripción.
- **Pista 3 — diseño:** en Python o Java (objetos), una ordenación por puntuación descendente ya conserva los empates; en C++, `std::stable_sort` o `std::sort` sobre `(−puntuación, índice)`.

**01 → Problema: El adversario del pivote.**

- **Pista 2 — patrón:** **simular** la partición contando: cada llamada sobre `[lo, hi]` hace exactamente `hi − lo` comparaciones.
- **Pista 3 — diseño:** con `n ≤ 2000`, simular es `O(n²)` en el peor caso y entra; usa una pila explícita en lugar de recursión, porque con entrada ordenada la profundidad es `n`. Comprueba que la entrada ordenada da `n(n−1)/2`.

**01 → Problema: Quicksort 1 - Partition.**

- **Pista 2 — patrón:** **partición** en tres grupos respecto del primer elemento.
- **Pista 3 — diseño:** recorre una vez repartiendo en menores, iguales y mayores, conservando el orden dentro de cada grupo, y concatena.

**01 → Problema: Running Time of Algorithms.**

- **Pista 2 — patrón:** **contar desplazamientos** de la inserción.
- **Pista 3 — diseño:** ejecuta la inserción de §3 y suma uno en cada copia `a[i] = a[i−1]`; con el tamaño del enunciado, la versión cuadrática entra.

**01 → Problema: Sort the People.**

- **Pista 2 — patrón:** **ordenar índices por una clave**.
- **Pista 3 — diseño:** ordena los índices `0..n−1` por altura descendente y recorre los nombres en ese orden.

**01 → Problema: Distinct.**

- **Pista 2 — patrón:** **ordenar y comparar vecinos**.
- **Pista 3 — diseño:** tras ordenar, cuenta las posiciones `i` con `a[i] ≠ a[i−1]`, más una si el arreglo no está vacío.

**01 → Problema: Largest Number.**

- **Pista 2 — patrón:** **comparador propio** sobre cadenas.
- **Pista 3 — diseño:** ordena las cadenas con `a` antes que `b` si `a + b > b + a`; concatena; si el resultado empieza por `0`, la respuesta es `"0"`.

**01 → Problema: Sort List.**

- **Pista 2 — patrón:** **mezcla sobre una lista enlazada**.
- **Pista 3 — diseño:** puntero lento y rápido para cortar por la mitad, recursión en cada mitad y mezcla reenlazando con un nodo centinela.

**01 → Problema: Insertion Sort List.**

- **Pista 2 — patrón:** **inserción** con una lista de salida y un **nodo centinela**.
- **Pista 3 — diseño:** saca cada nodo de la entrada y recórrelo en la salida desde el centinela hasta el primer nodo mayor; insértalo antes de él.

**01 → Problema: Custom Sort String.**

- **Pista 2 — patrón:** **clave de ordenación** dada por un orden, o **conteo** por letra.
- **Pista 3 — diseño:** cuenta las letras de `s`; recorre `order` emitiendo cada letra tantas veces como aparezca; añade al final las que no estén en `order`.

**01 → Problema: Triangle.**

- **Pista 2 — patrón:** **ordenar y mirar vecinos**: si hay triángulo, hay uno con tres consecutivos.
- **Pista 3 — diseño:** ordena y comprueba `a[i] + a[i+1] > a[i+2]` para cada `i`, con aritmética de 64 bits.

**01 → Problema: Closest Numbers.**

- **Pista 2 — patrón:** **ordenar y comparar vecinos**: la menor diferencia está entre consecutivos.
- **Pista 3 — diseño:** ordena, calcula la menor diferencia entre consecutivos y, en una segunda pasada, emite todos los pares que la alcanzan.

**01 → Problema: Lily's Homework.**

- **Pista 2 — patrón:** **ciclos de una permutación**: un ciclo de longitud `L` se ordena con `L − 1` intercambios.
- **Pista 3 — diseño:** calcula la posición de destino de cada elemento en el orden creciente, cuenta `n − ciclos`; repite con el orden decreciente y toma el mínimo.

---

# 02 — Ordenación lineal

**02 → 1.** ¿Cuánto cuesta el *counting sort*, y de qué depende? 🟢

⏱️ **30 segundos.** `Θ(n + k)` en tiempo y en memoria, donde `k` es el tamaño del rango de valores.

🗣️ **2 minutos.** Una pasada de `n` para contar, una de `k` para los prefijos y otra de `n` para colocar. Si `k = O(n)`, es lineal; si `k` es mucho mayor que `n`, el término `k` manda, en tiempo y en memoria.

🔬 **El detalle.** Si solo hace falta el histograma (contar, no reordenar registros), sobra el arreglo de salida y la memoria es `Θ(k)`.

**02 → 2.** ¿Por qué el *counting sort* no contradice la cota `Ω(n log n)`? 🟢

⏱️ **30 segundos.** Porque no es una ordenación por comparación: usa el valor como índice, y la cota del árbol de decisión solo vale para algoritmos que obtienen información comparando pares.

🗣️ **2 minutos.** El árbol de decisión supone operaciones con dos salidas (`<` o no). Indexar `cuenta[x]` es una operación con `k` salidas distintas, y además el algoritmo exige que las claves sean enteros acotados: con esa información extra, la cota `log₂ n!` no se aplica.

🔬 **El detalle.** Si las claves fueran objetos arbitrarios accesibles solo por un comparador, no habría índice que usar y la cota volvería a valer.

**02 → 3.** ¿Qué hace el arreglo de prefijos en el *counting sort*? 🟢

⏱️ **30 segundos.** Convierte las cuentas en posiciones: `inicio[v]` es cuántos elementos son menores que `v`, es decir, dónde empieza `v` en la salida.

🗣️ **2 minutos.** Es el prefijo exclusivo de las cuentas ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)). Al colocar, cada valor escribe en `inicio[v]` y avanza ese puntero, así que los iguales ocupan posiciones consecutivas en el orden en que llegan: eso da la estabilidad.

🔬 **El detalle.** CLRS usa el prefijo inclusivo (dónde acaba cada valor) y recorre la entrada de derecha a izquierda decrementando; es la misma idea, también estable.

**02 → 4.** ¿Por qué el *radix* LSD necesita que cada pasada sea estable? Da un ejemplo de dos números en que una pasada no estable rompe el resultado. 🟡

⏱️ **30 segundos.** Porque cada pasada debe respetar el orden que dejaron las anteriores entre claves de igual dígito actual. Con 21 y 25: tras las unidades, `[21, 25]`; una pasada por decenas no estable podría dejar `[25, 21]`.

🗣️ **2 minutos.** La prueba por inducción usa la estabilidad exactamente en el caso de dígitos iguales: es lo que transmite el orden por los dígitos bajos. Sin ella, cada pasada ordena por su dígito y destruye lo anterior, y el resultado solo está ordenado por el dígito más significativo.

🔬 **El detalle.** El *radix* MSD (del más significativo al menos) no necesita estabilidad de la misma forma, porque parte el problema en cubetas y ordena cada una por separado; a cambio es recursivo.

**02 → 5.** Con `n = 10⁵` claves en `[0, 10⁹]`, ¿usarías *counting sort*? ¿Qué harías? 🟡

⏱️ **30 segundos.** No: el arreglo de cuentas tendría `10⁹` posiciones, unos 4 GB, para solo `10⁵` valores. Usaría `sort` (`n log n` con `n = 10⁵` es inmediato) o compresión de coordenadas si necesito índices.

🗣️ **2 minutos.** El coste `Θ(n + k)` con `k = 10⁹` y `n = 10⁵` está dominado por `k` diez mil veces. Un *radix* en base `2¹⁶` haría dos pasadas y funcionaría, pero con `n = 10⁵`, `sort` es más simple y igual de rápido. La compresión ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)) da los rangos `0..n−1` si el problema necesita indexar por valor.

🔬 **El detalle.** Si en lugar de ordenar solo hubiera que contar repeticiones, un mapa hash ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)) da el histograma de valores dispersos en `O(n)` esperado.

**02 → 6.** ¿Cómo adaptas el *counting sort* a valores negativos? 🟡

⏱️ **30 segundos.** Desplazando por el mínimo: se cuenta `x − min` en un arreglo de `max − min + 1` posiciones y al escribir se suma `min` de vuelta.

🗣️ **2 minutos.** El rango que importa es `max − min + 1`, no el valor absoluto: valores entre −50 y 50 caben en 101 posiciones. Encontrar `min` y `max` es una pasada lineal más.

🔬 **El detalle.** En C++ y Java, `max − min` puede desbordar `int` si los extremos son de signo opuesto y grandes; ahí el rango no cabría en memoria de todos modos.

**02 → 7.** ¿Cuántas pasadas hace un *radix* en base 256 sobre enteros de 64 bits, y cuánta memoria auxiliar? 🟡

⏱️ **30 segundos.** Ocho pasadas (64 bits / 8 bits por dígito), con `Θ(n + 256)` de memoria auxiliar: un búfer del tamaño de la entrada y el arreglo de cuentas.

🗣️ **2 minutos.** Cada pasada es un *counting sort* estable con `k = 256`: `Θ(n + 256)`. Total `Θ(8(n + 256))`. Con dígitos de 16 bits serían cuatro pasadas, pero con cuentas de `65 536` posiciones, que dejan de caber en la caché L1.

🔬 **El detalle.** El búfer se alterna con la entrada en cada pasada; con un número par de pasadas, el resultado acaba en el arreglo original sin copia final.

**02 → 8.** Demuestra por inducción que el *radix* LSD con pasadas estables ordena. 🟠

⏱️ **30 segundos.** Inducción sobre el número de pasadas `t`: tras la pasada `t`, el arreglo está ordenado por los `t` dígitos bajos. El caso de dígitos iguales usa la estabilidad.

🗣️ **2 minutos.** Base: tras la primera pasada, ordenado por el último dígito. Paso: sean `x` e `y` con `x` antes que `y` tras la pasada `t`. Si sus dígitos `t` difieren, la pasada `t` los ordenó por él, y ese dígito es el más significativo de los `t` bajos. Si coinciden, la pasada (estable) mantuvo su orden de la pasada `t − 1`, que por hipótesis respetaba los `t − 1` dígitos bajos; con el dígito `t` igual, también respeta los `t`. Con `t = d`, ordenado del todo.

🔬 **El detalle.** CLRS, 3.ª ed., lema 8.3. El mismo argumento justifica ordenar tuplas por campos, del menos importante al más importante, con una ordenación estable.

**02 → 9.** ¿Por qué el *bucket sort* es lineal en esperanza con datos uniformes, y qué pasa si no lo son? 🟠

⏱️ **30 segundos.** Con `n` cubetas y datos uniformes, cada cubeta tiene en promedio un elemento y la inserción dentro de cada una cuesta `O(1)` esperado; si no son uniformes, todo puede caer en una cubeta y el coste es el de la inserción, `Θ(n²)`.

🗣️ **2 minutos.** Si `nᵢ` es el número de elementos de la cubeta `i`, el coste es `Θ(n) + Σ O(nᵢ²)`. Con uniformidad, `E[nᵢ²] = 2 − 1/n`, así que la suma esperada es `Θ(n)`. La linealidad depende de la distribución, no del algoritmo.

🔬 **El detalle.** CLRS, 3.ª ed., §8.4. Basta con que la suma de los cuadrados de los tamaños de cubeta sea lineal, lo que se cumple con distribuciones más generales que la uniforme.

**02 → 10.** Compara qué ofrecen C++, Java y Python para una ordenación lineal de enteros, y qué escribirías tú en cada uno. 🟠

⏱️ **30 segundos.** Ninguno de los tres trae una ordenación lineal en la biblioteca estándar: `std::sort`, `Arrays.sort` y `sorted` comparan. En C++ y Java escribo el *counting* de la plantilla; en Python, el histograma con una lista de cuentas o `collections.Counter`.

🗣️ **2 minutos.** En C++ y Java el *counting* escrito a mano corre a velocidad nativa y gana claramente a `sort` cuando `k` es pequeño. En Python, un bucle de `n` iteraciones es lento; `sorted` sobre enteros corre en C y a menudo gana a un *counting* en Python puro hasta tamaños grandes. Lo que sí vale en Python es usar el histograma cuando el problema solo pide contar.

🔬 **El detalle.** En Python, `[v for v in range(k) for _ in range(cuenta[v])]` escribe la salida, pero una línea por cada valor repetido; `out.extend([v] * cuenta[v])` delega la repetición a C.

**02 → 11.** ¿Por qué un *radix* puede ser más lento que `std::sort` para `n = 10⁶`, aunque sea lineal? 🔴

⏱️ **30 segundos.** Por la constante y la memoria: cuatro pasadas con lecturas secuenciales pero escrituras dispersas en 256 destinos y un búfer auxiliar, frente a una ordenación en el sitio con buena localidad y `log₂ n ≈ 20` niveles.

🗣️ **2 minutos.** La notación `Θ` esconde cuántos accesos a memoria hace cada paso ([`02/05`](../02-analisis/05-el-coste-real.md)). *Introsort* trabaja en el sitio y, al bajar por la recursión, sus subarreglos caben en la caché. *Radix* recorre el arreglo entero en cada pasada y escribe en el búfer de forma dispersa; con `n = 10⁶`, son ocho recorridos completos de `4 MB` más los fallos de las escrituras dispersas. La diferencia depende de la máquina y de los datos: hay que medir.

🔬 **El detalle.** Para `n` del orden de `10⁷` o más y claves de 32 bits, los *radix* bien escritos suelen ganar; por debajo, el resultado varía. Es el motivo de que ninguna librería estándar de las tres use *radix* por defecto.

**02 → 12.** Ordena `n` enteros en `[0, n³)` en `Θ(n)`, y di por qué ni el *counting* directo ni `sort` lo consiguen. 🔴

⏱️ **30 segundos.** *Radix* en base `n`: cada número en `[0, n³)` tiene tres dígitos en base `n`; tres pasadas de *counting* con `k = n`, `Θ(3(n + n)) = Θ(n)`.

🗣️ **2 minutos.** El *counting* directo tendría `k = n³`, imposible en memoria y tiempo. `sort` es `Θ(n log n)`. El truco es elegir la base igual a `n`: el número de dígitos es `log_n(n³) = 3`, constante, y cada pasada es lineal porque la base es `n`. Los dígitos son `x mod n`, `(x / n) mod n` y `x / n²`.

🔬 **El detalle.** En general, `n` enteros en `[0, nᶜ)` se ordenan en `Θ(c · n)` con base `n`. Es el ejercicio 8.3-4 de CLRS, 3.ª ed.

**02 → Problema: Edades del censo.**

- **Pista 2 — patrón:** **histograma**: con 131 valores posibles, contar y escribir.
- **Pista 3 — diseño:** un arreglo de 131 contadores; recorre la entrada sumando; recorre los valores de 0 a 130 imprimiendo cada uno tantas veces como su cuenta. Con `10⁷` números, lectura y escritura rápidas ([`03/01`](../03-biblioteca-estandar/01-cpp-contenedores.md), [`03/02`](../03-biblioteca-estandar/02-cpp-algoritmos-ranges-y-pbds.md), [`03/04`](../03-biblioteca-estandar/04-python-para-competir.md)).

**02 → Problema: Radix a mano.**

- **Pista 2 — patrón:** **radix LSD** con un *counting sort* estable por dígito decimal.
- **Pista 3 — diseño:** para `t` de 0 a `d − 1`, el dígito es `(x / 10ᵗ) mod 10`; haz un *counting* con `k = 10` que coloque en orden de llegada e imprime tras cada pasada.

**02 → Problema: Fechas en formato local.**

- **Pista 2 — patrón:** **radix por campos**: día, después mes, después año, con pasadas estables; o una clave compuesta `(año, mes, día, índice)`.
- **Pista 3 — diseño:** convierte cada fecha a un entero `AAAAMMDD` y ordénalo de forma estable (o con el índice como desempate); con `10⁶` fechas, un *counting* por campo (31, 12 y 201 valores) también es lineal.

**02 → Problema: Counting Sort 1.**

- **Pista 2 — patrón:** **histograma** de valores acotados.
- **Pista 3 — diseño:** un arreglo de 100 contadores, uno por valor posible, incrementado en una pasada.

**02 → Problema: Counting Sort 2.**

- **Pista 2 — patrón:** **counting sort**: histograma y escritura en orden.
- **Pista 3 — diseño:** cuenta y después recorre los valores en orden escribiendo cada uno tantas veces como aparece.

**02 → Problema: Height Checker.**

- **Pista 2 — patrón:** **counting sort** para obtener el orden esperado.
- **Pista 3 — diseño:** construye la versión ordenada con un histograma de 100 alturas y cuenta las posiciones donde difiere de la original.

**02 → Problema: Relative Sort Array.**

- **Pista 2 — patrón:** **conteo por valor** con un orden dado.
- **Pista 3 — diseño:** cuenta los valores de `arr1`; recorre `arr2` emitiendo cada valor tantas veces como su cuenta y poniéndola a cero; después emite los restantes en orden creciente de valor.

**02 → Problema: The Full Counting Sort.**

- **Pista 2 — patrón:** **counting sort estable con registros**.
- **Pista 3 — diseño:** una lista de cadenas por clave; recorre la entrada añadiendo a la lista de su clave (sustituyendo por `-` las de la primera mitad); concatena las listas en orden de clave. Con muchos registros, construye la salida de una vez.

**02 → Problema: Sort Colors.**

- **Pista 2 — patrón:** **conteo** de tres valores, o **partición de tres vías** en una pasada.
- **Pista 3 — diseño:** con dos pasadas, cuenta y reescribe. En una pasada, tres punteros: `lo`, `mid` y `hi`; el 0 va a `lo`, el 2 a `hi`, el 1 se queda; ojo con no avanzar `mid` tras traer un elemento desde `hi`.

**02 → Problema: H-Index.**

- **Pista 2 — patrón:** **cubetas acotadas**: el índice está entre 0 y `n`.
- **Pista 3 — diseño:** cuenta las citas en `n + 1` cubetas, con las mayores que `n` en la última; recorre de `n` hacia abajo acumulando y para en el primer `h` con acumulado `≥ h`.

**02 → Problema: Sort Array by Increasing Frequency.**

- **Pista 2 — patrón:** **conteo** y ordenación por **clave compuesta**.
- **Pista 3 — diseño:** cuenta las frecuencias; ordena con la clave `(frecuencia, −valor)`.

**02 → Problema: Sort Characters By Frequency.**

- **Pista 2 — patrón:** **cubetas por frecuencia**: la frecuencia está entre 1 y `n`.
- **Pista 3 — diseño:** cuenta cada carácter; pon cada uno en la cubeta de su frecuencia; recorre las cubetas de `n` a 1 emitiendo cada carácter repetido su frecuencia.

**02 → Problema: Maximum Gap.**

- **Pista 2 — patrón:** **cubetas y palomar**: con `n` valores, el hueco máximo es al menos `⌈(max − min)/(n − 1)⌉`.
- **Pista 3 — diseño:** cubetas de ese ancho; guarda solo el mínimo y el máximo de cada una; el hueco máximo está entre el máximo de una cubeta no vacía y el mínimo de la siguiente no vacía.

**02 → Problema: Contains Duplicate III.**

- **Pista 2 — patrón:** **cubetas de ancho `t + 1`** sobre una ventana de tamaño `k`.
- **Pista 3 — diseño:** la cubeta de `x` es `⌊x / (t + 1)⌋` (con cuidado con los negativos); dos valores en la misma cubeta distan `≤ t`; mira también las cubetas vecinas; quita de la tabla el elemento que sale de la ventana.

---

# 03 — Inversiones, selección y mediana

**03 → 1.** ¿Qué es una inversión, y cuántas tiene un arreglo ordenado al revés? 🟢

⏱️ **30 segundos.** Un par de posiciones `i < j` con `a[i] > a[j]`. Un arreglo de `n` elementos distintos ordenado al revés tiene `n(n−1)/2`: todos los pares.

🗣️ **2 minutos.** Es la medida natural del desorden: 0 en un arreglo ordenado, el máximo en uno al revés. Coincide con los desplazamientos de la inserción y con el mínimo de intercambios adyacentes que ordenan.

🔬 **El detalle.** Con repetidos, los pares iguales no cuentan: `[2, 2, 1]` tiene 2 inversiones, no 3.

**03 → 2.** ¿Qué hace `std::nth_element`, y cómo queda el arreglo después? 🟢

⏱️ **30 segundos.** Reordena el rango para que en la posición `k` quede el valor que tendría en el orden completo, con todos los anteriores `≤` y todos los posteriores `≥`. `O(n)` en promedio.

🗣️ **2 minutos.** No ordena ni la parte izquierda ni la derecha: solo garantiza la partición alrededor de `k`. Por eso sirve para la mediana, el percentil o los `k` menores sin orden. libstdc++ lo implementa con *introselect*: *quickselect* con un respaldo cuando la recursión se degenera.

🔬 **El detalle.** El estándar exige complejidad lineal en promedio; la garantía de caso peor depende de la implementación.

**03 → 3.** ¿Por qué el número de inversiones es el mínimo de intercambios adyacentes que ordenan el arreglo? 🟡

⏱️ **30 segundos.** Porque un intercambio de vecinos cambia el orden relativo de un solo par: quita o crea exactamente una inversión. Para llegar a 0 hacen falta al menos `I` intercambios, y la inserción (o la burbuja) usa exactamente `I`.

🗣️ **2 minutos.** Cota inferior: cada intercambio adyacente baja `I` como mucho en 1. Cota superior: mientras el arreglo no esté ordenado, hay dos vecinos fuera de orden; intercambiarlos baja `I` en exactamente 1. Los dos argumentos dan `I`.

🔬 **El detalle.** Con intercambios arbitrarios (no adyacentes), el mínimo es `n − ciclos` de la permutación, que puede ser mucho menor que `I`.

**03 → 4.** Al contar inversiones con la mezcla, ¿cuándo se suma y cuánto? 🟡

⏱️ **30 segundos.** Al tomar un elemento de la **derecha**: se suman los que quedan en la izquierda, `mid − i`.

🗣️ **2 minutos.** Los que quedan en la izquierda son mayores que el elemento derecho que sale (los menores o iguales ya salieron), y todos están antes que él en el arreglo original: cada uno es una inversión que cruza. Al tomar de la izquierda no se suma nada.

🔬 **El detalle.** Equivalentemente, se puede sumar al tomar de la izquierda el número de elementos de la derecha que ya salieron, `j − mid`: cuenta las mismas inversiones desde el otro extremo. Es la forma útil cuando se quiere el conteo por elemento.

**03 → 5.** ¿Por qué *quickselect* recursa en un solo lado y *quicksort* en los dos, y cómo cambia eso el coste? 🟡

⏱️ **30 segundos.** Porque *quicksort* necesita ordenar los dos lados y *quickselect* solo necesita el que contiene `k`. El coste pasa de `T(n) = 2T(n/2) + n`, que es `n log n`, a `T(n) = T(n/2) + n`, que es `n`.

🗣️ **2 minutos.** La suma de *quickselect* es geométrica: `n + n/2 + n/4 + … = 2n`. La de *quicksort* tiene `log n` niveles con `n` de trabajo cada uno. Con particiones desequilibradas, los dos son cuadráticos en el caso peor.

🔬 **El detalle.** El análisis esperado con pivote aleatorio da `≤ 4n` comparaciones con el argumento de las particiones buenas, y una constante más fina (`≈ 3,4n` para la mediana) con un análisis exacto.

**03 → 6.** ¿Qué pasa con el conteo de inversiones si cambias `a[j] < a[i]` por `a[j] <= a[i]`? 🟡

⏱️ **30 segundos.** Contaría también los pares iguales: `[2, 2]` daría 1 inversión en lugar de 0.

🗣️ **2 minutos.** Con `<=`, en un empate se toma de la derecha y se suman los que quedan en la izquierda, que incluyen al igual. El resultado es inversiones más pares iguales, y además la mezcla deja de ser estable.

🔬 **El detalle.** Con valores distintos, las dos versiones dan lo mismo: el fallo solo aparece con repetidos, y por eso suele escapar a los ejemplos.

**03 → 7.** ¿Cuándo ordenar una vez es mejor que llamar a *quickselect* varias veces? 🟡

⏱️ **30 segundos.** Cuando se piden muchas posiciones: `m` llamadas a *quickselect* cuestan `O(m · n)`; ordenar una vez, `O(n log n + m)`. A partir de unas `log n` consultas, ordenar sale más barato.

🗣️ **2 minutos.** También si después hace falta el orden completo, o si los datos se reutilizan. *Quickselect* compensa con una o pocas posiciones sobre datos que no se van a reutilizar.

🔬 **El detalle.** Hay variantes de selección múltiple que reparten varias posiciones en una sola recursión, pero en la práctica, ordenar es la respuesta.

**03 → 8.** Demuestra que *quickselect* aleatorio hace `O(n)` comparaciones esperadas. 🟠

⏱️ **30 segundos.** Con probabilidad `1/2` el pivote cae entre los cuartiles y el lado restante tiene `≤ 3n/4`; hacen falta en esperanza 2 particiones por cada reducción de `3/4`, y la suma geométrica da `O(n)`.

🗣️ **2 minutos.** Divide la ejecución en fases: la fase `t` dura mientras el tamaño está entre `(3/4)^{t+1}·n` y `(3/4)^t·n`. Cada partición de la fase cuesta `O((3/4)^t·n)`, y como cada una es buena con probabilidad `≥ 1/2`, el número esperado de particiones de la fase es `≤ 2`. Por linealidad de la esperanza, el coste esperado es `Σ_t 2 · c · (3/4)^t · n = 8cn`.

🔬 **El detalle.** CLRS, 3.ª ed., §9.2, hace el análisis exacto con una recurrencia de la esperanza; Kleinberg y Tardos, §13.5, usan el argumento de fases.

**03 → 9.** Compara cómo obtienes el `k`-ésimo menor en C++, Java y Python con la biblioteca estándar, y su coste. 🟠

⏱️ **30 segundos.** C++: `std::nth_element`, `O(n)` en promedio. Java: no hay; `Arrays.sort` y leer la posición, `O(n log n)`, o un `PriorityQueue` de tamaño `k`, `O(n log k)`. Python: `sorted(a)[k]`, `O(n log n)`, o `heapq.nsmallest(k + 1, a)[-1]`, `O(n log k)`.

🗣️ **2 minutos.** En Java y Python, escribir el *quickselect* es la opción lineal. En Java compensa; en Python, el bucle en Python puro es tan lento que `sorted`, que corre en C, suele ganar hasta tamaños grandes. En entrevista: «en C++ `nth_element`; en Java y Python, *quickselect* a mano si piden lineal».

🔬 **El detalle.** `heapq.nsmallest` con `k` pequeño es muy rápido; con `k ≥ n` ordena directamente, y con `k` cercano a `n` el montículo cuesta casi lo mismo que ordenar.

**03 → 10.** ¿Por qué la mediana minimiza la suma de distancias `Σ |x − c|`? 🟠

⏱️ **30 segundos.** Porque al mover `c` hacia la derecha, la distancia a cada punto de la izquierda crece y a cada punto de la derecha decrece: la suma baja mientras haya más puntos a la derecha que a la izquierda, y en la mediana están equilibrados.

🗣️ **2 minutos.** Si `c` avanza `δ` sin cruzar ningún punto, la suma cambia en `δ · (L − R)`, con `L` los puntos a la izquierda y `R` a la derecha. Mientras `L < R`, conviene avanzar; mientras `L > R`, retroceder. El mínimo está donde `L ≤ n/2` y `R ≤ n/2`: la mediana. Con `n` par, cualquier punto entre las dos medianas vale.

🔬 **El detalle.** Para la suma de cuadrados `Σ (x − c)²`, el mínimo es la media, no la mediana: la derivada es `2Σ(c − x)`.

**03 → 11.** En la mediana de medianas, ¿por qué grupos de 5 y no de 3? Justifica con la recurrencia. 🔴

⏱️ **30 segundos.** Con grupos de 3, la recurrencia es `T(n) = T(n/3) + T(2n/3) + O(n)`, cuyas fracciones suman 1: da `Θ(n log n)`. Con grupos de 5, `1/5 + 7/10 = 9/10 < 1`, y da `O(n)`.

🗣️ **2 minutos.** La mediana de medianas con grupos de `g` deja a cada lado al menos la mitad de los grupos por la mitad de sus elementos, unos `n/4` con `g = 3`, `3n/10` con `g = 5`. La recursión para el pivote trabaja sobre `n/g`. La suma de las fracciones tiene que ser menor que 1 para que la suma geométrica de los niveles converja a `O(n)`: con 3, es `1/3 + 2/3 = 1`; con 5, `1/5 + 7/10 < 1`.

🔬 **El detalle.** Con grupos de 7 o más también es lineal. Hay variantes con grupos de 3 o 4 que recuperan la linealidad cambiando cómo se elige el pivote.

**03 → 12.** Con todos los elementos iguales, ¿cuánto cuesta *quickselect* con Lomuto y con Hoare? Demuestra que con Hoare los cortes quedan equilibrados. 🔴

⏱️ **30 segundos.** Con Lomuto y comparación estricta, `Θ(n²)`: ningún elemento es menor que el pivote, el corte queda en un extremo y el tramo baja de uno en uno. Con Hoare, `Θ(n)`: los cortes quedan en el centro.

🗣️ **2 minutos.** Con todos iguales, en Hoare cada `do i++ while (a[i] < p)` para en el primer paso, y cada `do j-- while (a[j] > p)` también: los índices avanzan uno por vuelta desde los dos extremos y se cruzan en el centro. El corte divide el tramo por la mitad, y *quickselect* hace `n + n/2 + … = O(n)`.

🔬 **El detalle.** Hoare hace muchos intercambios inútiles (iguales con iguales), pero mantiene el equilibrio. La partición de tres vías consigue lo mismo y además termina en cuanto `k` cae entre los iguales.

**03 → 13.** ¿Cómo encuentras la mediana de `10⁹` enteros que no caben en memoria, con varias pasadas sobre el disco? 🔴

⏱️ **30 segundos.** Con histogramas por bits altos: una pasada cuenta cuántos valores hay por cada prefijo de 16 bits; con los prefijos acumulados se sabe en qué cubeta cae la posición de la mediana; una segunda pasada cuenta, dentro de esa cubeta, por los 16 bits bajos.

🗣️ **2 minutos.** Para enteros de 32 bits, dos pasadas y dos arreglos de `2¹⁶` contadores de 64 bits, medio megabyte cada uno. La primera pasada localiza el prefijo alto y cuántos valores quedan por debajo; la segunda, el valor exacto. Es *radix* ([`05/02`](02-ordenacion-lineal.md)) usado para seleccionar en lugar de ordenar.

🔬 **El detalle.** Con valores de 64 bits, cuatro pasadas de 16 bits. Alternativa: muestrear para estimar un rango que contiene la mediana, contar en una pasada cuántos quedan por debajo y por encima, y seleccionar en memoria los que caen dentro del rango.

**03 → 14.** ¿Cuántas inversiones cambian al intercambiar dos elementos adyacentes, y al intercambiar dos cualesquiera? Demuéstralo. 🔴

⏱️ **30 segundos.** Un intercambio adyacente cambia el número de inversiones en exactamente 1. Un intercambio de dos elementos cualesquiera lo cambia en un número **impar**: la paridad siempre cambia.

🗣️ **2 minutos.** Adyacente: solo cambia el orden relativo del par intercambiado; los demás pares conservan su orden. Cualesquiera, posiciones `i < j` con valores `x` e `y` y `m` elementos entre ellas: cada elemento `z` del medio forma dos pares, `(x, z)` y `(z, y)`, que pasan a ser `(y, z)` y `(z, x)`; el cambio de esos dos pares es par (−2, 0 o +2). El par `(x, y)` cambia en ±1. Total: impar.

🔬 **El detalle.** Es la base de la paridad de una permutación: una permutación es par o impar según la paridad de sus inversiones, y cada transposición la cambia. Por eso la mitad de las configuraciones del 15-puzzle son irresolubles.

**03 → Problema: Intercambios adyacentes.**

- **Pista 2 — patrón:** **contar inversiones** con la mezcla.
- **Pista 3 — diseño:** la plantilla de §3 sobre una copia del arreglo, con contador de 64 bits; los iguales no cuentan, así que la comparación es estricta.

**03 → Problema: El peso del medio.**

- **Pista 2 — patrón:** **selección**: *quickselect* o `nth_element`.
- **Pista 3 — diseño:** la posición es `(n − 1) / 2`; en C++, `nth_element`; en Java, la plantilla iterativa; en Python, `sorted` también entra con `10⁶`.

**03 → Problema: Rotaciones de una permutación.**

- **Pista 2 — patrón:** **inversiones iniciales** más un **cambio en `O(1)`** por rotación.
- **Pista 3 — diseño:** cuenta las inversiones de la permutación con la mezcla. Cuando el primero, de valor `x`, pasa al final, pierde las `x − 1` inversiones con los menores (que tenía detrás) y gana `n − x` con los mayores (que ahora tiene delante): el cambio es `n − 2x + 1`. Recorre las `n` rotaciones actualizando y guarda el mínimo.

**03 → Problema: Find the Median.**

- **Pista 2 — patrón:** **selección** de la posición central.
- **Pista 3 — diseño:** con `n` impar, la posición `n / 2` del orden; ordena o usa *quickselect*.

**03 → Problema: Kth Largest Element in an Array.**

- **Pista 2 — patrón:** **quickselect** sobre la posición `n − k`.
- **Pista 3 — diseño:** la plantilla iterativa con pivote aleatorio; ojo con los casos adversarios de muchos iguales, que Hoare resuelve. Alternativa `O(n log k)`: un montículo de mínimos de tamaño `k`.

**03 → Problema: K Closest Points to Origin.**

- **Pista 2 — patrón:** **quickselect por clave**: la distancia al cuadrado.
- **Pista 3 — diseño:** selecciona la posición `k − 1` comparando `x² + y²` sin raíces; los `k` primeros tras la selección son la respuesta, en cualquier orden.

**03 → Problema: Minimum Moves to Equal Array Elements II.**

- **Pista 2 — patrón:** **mediana**.
- **Pista 3 — diseño:** lleva todos a la mediana y suma las distancias; con `n` par, cualquiera de las dos medianas da lo mismo.

**03 → Problema: Global and Local Inversions.**

- **Pista 2 — patrón:** **inversiones con estructura**: las globales igualan a las locales si no hay inversiones a distancia `≥ 2`.
- **Pista 3 — diseño:** comprueba que `|nums[i] − i| ≤ 1` para todo `i`, o lleva el máximo de `nums[0..i−2]` y verifica que nunca supera a `nums[i]`.

**03 → Problema: Stick Lengths.**

- **Pista 2 — patrón:** **la mediana minimiza la suma de distancias**.
- **Pista 3 — diseño:** halla la mediana (ordenar o seleccionar) y suma `|p − mediana|` en 64 bits.

**03 → Problema: Wiggle Sort II.**

- **Pista 2 — patrón:** **mediana** y reparto de mayores y menores en posiciones alternas.
- **Pista 3 — diseño:** la versión `O(n log n)`: ordena una copia; llena las posiciones impares con la mitad mayor tomada de mayor a menor y las pares con la mitad menor de mayor a menor. La versión `O(n)` usa *quickselect* para la mediana y una partición de tres vías con índices virtuales.

**03 → Problema: Insertion Sort Advanced Analysis.**

- **Pista 2 — patrón:** **contar inversiones**.
- **Pista 3 — diseño:** mezcla con conteo o Fenwick sobre los valores; contador de 64 bits; con varios casos, reutiliza el búfer.

**03 → Problema: Reverse Pairs.**

- **Pista 2 — patrón:** **mezcla con un conteo aparte** antes de mezclar.
- **Pista 3 — diseño:** con las dos mitades ya ordenadas, recorre la izquierda con un puntero sobre la derecha que avanza mientras `left[i] > 2 · right[j]` (en 64 bits); suma `j − mid` por cada `i`; después, mezcla normal.

**03 → Problema: Count of Smaller Numbers After Self.**

- **Pista 2 — patrón:** **conteo por elemento** con la mezcla sobre índices.
- **Pista 3 — diseño:** ordena índices por valor con la mezcla; al tomar un índice de la izquierda, súmale cuántos de la derecha ya salieron (`j − mid`). Alternativa: Fenwick sobre valores comprimidos de derecha a izquierda.

**03 → Problema: Count of Range Sum.**

- **Pista 2 — patrón:** **prefijos** y **mezcla con conteo** sobre los prefijos.
- **Pista 3 — diseño:** con los prefijos `P[0..n]`, cuenta los pares `i < j` con `lower ≤ P[j] − P[i] ≤ upper`. Con las mitades ordenadas, para cada `i` de la izquierda dos punteros sobre la derecha delimitan los `j` válidos; los punteros solo avanzan.

---

# 04 — Búsqueda binaria

**04 → 1.** ¿Qué devuelven *lower bound* y *upper bound*, y qué significa que devuelvan `n`? 🟢

⏱️ **30 segundos.** El *lower bound* de `x` es el primer índice con `a[i] ≥ x`; el *upper bound*, el primero con `a[i] > x`. Devolver `n` significa que ningún elemento cumple: todos son menores (o menores o iguales).

🗣️ **2 minutos.** Los dos están en `[0, n]` porque son la frontera de un predicado sobre un intervalo semiabierto. `n` es también la posición donde habría que insertar `x` para mantener el orden. Entre los dos queda el tramo de los iguales a `x`.

🔬 **El detalle.** Si `x` no está, los dos coinciden: es la posición de inserción.

**04 → 2.** ¿Por qué el bucle es `while (lo < hi)` y la actualización `hi = mid`, y no `hi = mid − 1`? 🟢

⏱️ **30 segundos.** Porque el intervalo es semiabierto `[lo, hi)`: `hi` es el primer índice que ya se sabe que cumple, y no se puede descartar. Con `lo = hi` el intervalo está vacío y se acaba.

🗣️ **2 minutos.** Si `P(mid)` es cierto, `mid` puede ser la respuesta: `hi = mid` lo conserva fuera del tramo por explorar pero como candidato. `hi = mid − 1` lo perdería. Con `while (lo <= hi)` y `hi = mid`, cuando `lo = hi = mid` el bucle no avanza y no termina.

🔬 **El detalle.** La versión con intervalo cerrado (`while lo <= hi`, `hi = mid − 1`) es correcta si se guarda la respuesta aparte; mezclar las dos convenciones es la fuente habitual del *off-by-one*.

**04 → 3.** ¿Qué devuelve `Arrays.binarySearch` si el valor está repetido, y si no está? 🟢

⏱️ **30 segundos.** Con repetidos, **algún** índice con ese valor, sin garantía de cuál. Si no está, `−(punto de inserción) − 1`, que es negativo.

🗣️ **2 minutos.** El punto de inserción es el *lower bound*; la codificación `−p − 1` hace que el resultado sea negativo incluso cuando `p = 0`. Para la primera o la última aparición hay que escribir la búsqueda propia.

🔬 **El detalle.** `Collections.binarySearch` sobre listas tiene el mismo contrato; sobre una `LinkedList` grande es lineal en recorridos.

**04 → 4.** ¿Cómo cuentas cuántas veces aparece `x` en un arreglo ordenado en `O(log n)`? 🟢

⏱️ **30 segundos.** `upperBound(a, x) − lowerBound(a, x)`.

🗣️ **2 minutos.** Los iguales a `x` forman un tramo contiguo en un arreglo ordenado: empieza en el *lower bound* y acaba justo antes del *upper bound*. Dos búsquedas, `O(log n)`. En C++, `std::equal_range` da los dos; en Python, `bisect_right(a, x) − bisect_left(a, x)`.

🔬 **El detalle.** La misma resta cuenta los elementos de un rango `[L, R]`: `upperBound(R) − lowerBound(L)`.

**04 → 5.** ¿Qué es un predicado monótono, y por qué la binaria sobre la respuesta lo necesita? 🟡

⏱️ **30 segundos.** Un predicado `P` sobre los valores tal que, si `P(v)` es cierto, también `P(v + 1)`: falso, …, falso, cierto, …, cierto. La binaria encuentra la frontera solo si existe una única frontera.

🗣️ **2 minutos.** La binaria descarta la mitad del rango tras mirar un punto. Eso es válido porque, por la monotonía, el resultado en `mid` dice el resultado en toda una mitad. Sin monotonía, mirar `mid` no informa sobre sus vecinos, y la binaria devuelve una frontera cualquiera, o ninguna.

🔬 **El detalle.** La monotonía se demuestra, normalmente con un argumento de «si se puede con `v`, la misma solución sirve para `v + 1`».

**04 → 6.** ¿Cuándo desborda `(lo + hi) / 2`, y qué tres formas tienes de evitarlo? 🟡

⏱️ **30 segundos.** Cuando `lo + hi` pasa de `2³¹ − 1` en `int`, aunque los dos quepan. Se evita con `lo + (hi − lo) / 2`, con `(lo + hi) >>> 1` en Java (índices no negativos), o usando 64 bits.

🗣️ **2 minutos.** Con arreglos de más de `2³⁰` elementos, o con binaria sobre la respuesta en `int` cerca de `10⁹`, `lo + hi` desborda y el resultado es negativo: un índice fuera de rango o un bucle que no termina. Bloch documentó en 2006 que el `Arrays.binarySearch` de la JDK lo tenía.

🔬 **El detalle.** `lo + (hi − lo) / 2` exige `lo ≤ hi`, que el invariante garantiza. En C++, `std::midpoint` (C++20) calcula el punto medio sin desbordamiento.

**04 → 7.** ¿Por qué en reales se para por número de vueltas y no por `hi − lo > ε`? 🟡

⏱️ **30 segundos.** Porque con valores grandes la distancia entre dos `double` consecutivos supera `ε`: el intervalo deja de encoger y el bucle no termina.

🗣️ **2 minutos.** Un `double` tiene 53 bits de mantisa, unos 16 dígitos decimales. Cerca de `10¹⁵`, dos `double` consecutivos distan `0,125`. Cuando `lo` y `hi` son vecinos, `mid` redondea a uno de ellos y no hay progreso. Con 100 vueltas fijas el bucle termina siempre, y el intervalo baja hasta la precisión que el tipo puede representar.

🔬 **El detalle.** Una alternativa es parar por error relativo, `hi − lo > ε · max(1, |lo|)`, pero el número fijo de vueltas es más simple y no tiene casos raros.

**04 → 8.** Para «el máximo valor que funciona», ¿qué predicado usas con `firstTrue` y qué devuelves? 🟡

⏱️ **30 segundos.** `P(v) = «v no funciona»`, que es falso…cierto si «funciona» es cierto…falso. La respuesta es `firstTrue − 1`.

🗣️ **2 minutos.** Para «el máximo `v` que funciona», «funciona» es cierto en los valores pequeños y falso a partir de uno: su negación es el predicado monótono que espera `firstTrue`. La frontera es el primer valor que **no** funciona; el anterior es la respuesta. Si `firstTrue` devuelve `lo`, ningún valor funciona.

🔬 **El detalle.** Escribir una sola plantilla (`firstTrue`) y adaptar el predicado evita mantener dos binarias con condiciones de parada distintas.

**04 → 9.** Demuestra con el invariante que la plantilla de `firstTrue` devuelve la frontera y termina. 🟠

⏱️ **30 segundos.** Invariante: `P` falso en `[lo₀, lo)` y cierto en `[hi, hi₀)`. Se cumple al inicio (tramos vacíos), se mantiene en cada rama por la monotonía, y `hi − lo` baja estrictamente. Al salir, `lo = hi` es la frontera.

🗣️ **2 minutos.** Mantenimiento: `mid` está en `[lo, hi)` porque `lo < hi`. Si `P(mid)` es falso, por la monotonía `P` es falso en todo `[lo₀, mid]`, y `lo = mid + 1` mantiene la primera parte. Si es cierto, `P` es cierto en `[mid, hi₀)` y `hi = mid` mantiene la segunda. Terminación: en las dos ramas, `hi − lo` baja al menos en 1 porque `lo ≤ mid < hi`. Postcondición: con `lo = hi = f`, `P` es falso antes de `f` y cierto desde `f`.

🔬 **El detalle.** El punto clave es `mid < hi`, que garantiza `lo + (hi − lo) / 2` con redondeo hacia abajo. Con redondeo hacia arriba, `mid` podría ser `hi`, fuera del tramo.

**04 → 10.** Compara lo que ofrecen C++, Java y Python para el *lower bound* sobre un arreglo y sobre un conjunto ordenado. 🟠

⏱️ **30 segundos.** C++: `std::lower_bound` sobre el arreglo y `set::lower_bound` sobre el conjunto. Java: nada para el arreglo (`Arrays.binarySearch` no lo da) y `TreeSet.ceiling` sobre el conjunto. Python: `bisect_left` sobre la lista, y no hay conjunto ordenado en la biblioteca estándar.

🗣️ **2 minutos.** En Java, el *lower bound* sobre un arreglo se escribe a mano con la plantilla; `TreeSet.ceiling(x)` devuelve el menor `≥ x` y `higher(x)` el menor `> x`, en `O(log n)`. En Python, una lista ordenada con `bisect` sirve si no hay inserciones frecuentes; con inserciones, `insort` es `O(n)` por el desplazamiento.

🔬 **El detalle.** El hueco de Python se cubre en competición con estructuras propias (`03/04`) o con Fenwick sobre valores comprimidos.

**04 → 11.** ¿Por qué `std::lower_bound` sobre un `std::set` es lineal, y qué usas en su lugar? 🟠

⏱️ **30 segundos.** Porque los iteradores de `std::set` no son de acceso aleatorio: `std::lower_bound` hace `O(log n)` comparaciones, pero avanzar al punto medio cuesta recorrer los nodos, `O(n)` en total. Se usa `s.lower_bound(x)`, que baja por el árbol en `O(log n)`.

🗣️ **2 minutos.** El algoritmo genérico solo sabe avanzar el iterador de uno en uno (`std::advance`). La función miembro conoce la estructura del árbol rojinegro y baja por él. Es un TLE clásico: el código compila, da la respuesta correcta y es lineal por consulta.

🔬 **El detalle.** Lo mismo vale para `std::map` y `std::multiset`. Con `std::ranges::lower_bound` pasa igual.

**04 → 12.** ¿Cuántas evaluaciones del predicado hace la binaria sobre `[1, 10¹⁸]`, y qué riesgo de desbordamiento hay dentro del predicado? 🟠

⏱️ **30 segundos.** `⌈log₂ 10¹⁸⌉ = 60` evaluaciones. El riesgo es que dentro del predicado `mid` multiplicado por algo desborde 64 bits.

🗣️ **2 minutos.** Con `mid` cerca de `10¹⁸`, `mid · n` o `mid · mid` pasan de `9,2·10¹⁸`. Soluciones: cortar la suma en cuanto supere el objetivo, dividir en lugar de multiplicar (`mid > objetivo / n`), o usar `__int128` en C++ y `Math.multiplyHigh` o `BigInteger` en Java ([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)).

🔬 **El detalle.** En Python no hay desbordamiento, pero un predicado que construye enteros enormes se vuelve lento.

**04 → 13.** Da un problema en el que el predicado parece monótono y no lo es, y explica qué devuelve la binaria. 🔴

⏱️ **30 segundos.** «¿Existe un tramo de longitud exactamente `k` con suma `≤ −4`?» en `[−3, −3, 3, −3]`: falso con `k = 1`, cierto con `k = 2`, falso con `k = 3`, cierto con `k = 4`. La binaria devuelve una frontera cualquiera.

🗣️ **2 minutos.** Con negativos, alargar un tramo puede subir o bajar la suma, así que la existencia con longitud `k` no implica nada sobre `k + 1`. Una binaria «la menor `k` con un tramo así» sobre `[1, 5)` mira `k = 3` (falso), sube a `[4, 5)` y devuelve 4, cuando la respuesta es 2. No hay error de ejecución: solo un resultado equivocado.

🔬 **El detalle.** «Al menos `k`» en lugar de «exactamente `k`» no lo arregla aquí, pero sí en problemas donde la condición de «al menos» se hereda; la monotonía depende de la formulación exacta.

**04 → 14.** ¿Cómo haces una binaria sobre la respuesta cuando la respuesta es una fracción `p/q` exacta y no un real aproximado? 🔴

⏱️ **30 segundos.** Con aritmética exacta sobre fracciones: binaria sobre el árbol de Stern–Brocot, o binaria en reales seguida de recuperar la fracción con denominador acotado.

🗣️ **2 minutos.** Si el denominador está acotado por `Q`, dos fracciones distintas con denominador `≤ Q` distan al menos `1/Q²`. Una binaria en reales hasta esa precisión deja un intervalo con una sola candidata, que se recupera con fracciones continuas. Alternativa exacta: comparar fracciones con productos cruzados (`p₁ · q₂ < p₂ · q₁`, en 64 bits o `__int128`) y descender por Stern–Brocot, donde cada paso aproxima por la izquierda o por la derecha.

🔬 **El detalle.** Es el caso de la «fracción `k`-ésima» y de los problemas de razón óptima («maximiza `Σ aᵢ / Σ bᵢ`»): se hace binaria sobre la razón `r` con el predicado lineal `Σ (aᵢ − r · bᵢ) ≥ 0`. El método de Dinkelbach sustituye esa binaria por una iteración que suele converger en menos pasos.

**04 → Problema: Primera lectura tardía.**

- **Pista 2 — patrón:** **lower bound**.
- **Pista 3 — diseño:** la plantilla con `long`; si devuelve `n`, imprime `-1`. Lectura y escritura rápidas para `2·10⁵` consultas (`03/01`).

**04 → Problema: Altura de corte.**

- **Pista 2 — patrón:** **binaria sobre la respuesta**: «maximiza `H`».
- **Pista 3 — diseño:** la madera a altura `H` decrece con `H`; con `firstTrue(0, max + 1, H -> madera(H) < M) − 1`. La suma puede pasar de `2³¹`: 64 bits.

**04 → Problema: Raíz cúbica.**

- **Pista 2 — patrón:** **binaria sobre enteros** para la parte entera y **binaria en reales** para la aproximada.
- **Pista 3 — diseño:** para la entera, `firstTrue(0, 10⁶ + 2, v -> v³ > x) − 1`; el `hi` pequeño evita que `v³` desborde. Para la real, 100 vueltas en `[0, 10⁶ + 1]` con `m³ ≥ x`. Comprueba los cubos perfectos.

**04 → Problema: Find Smallest Letter Greater Than Target.**

- **Pista 2 — patrón:** **upper bound** con vuelta al principio.
- **Pista 3 — diseño:** el primer índice con letra `> target`; si es `n`, devuelve la primera letra.

**04 → Problema: Find First and Last Position of Element in Sorted Array.**

- **Pista 2 — patrón:** **lower bound** y **upper bound**.
- **Pista 3 — diseño:** la primera posición es el *lower bound* si ahí está el valor; la última, el *upper bound* menos uno.

**04 → Problema: Koko Eating Bananas.**

- **Pista 2 — patrón:** **binaria sobre la respuesta**: la menor velocidad que alcanza.
- **Pista 3 — diseño:** a velocidad `v`, las horas son `Σ ⌈pᵢ / v⌉`, que decrece con `v`; `firstTrue(1, max + 1, v -> horas(v) <= h)`. Suma en 64 bits.

**04 → Problema: Capacity To Ship Packages Within D Days.**

- **Pista 2 — patrón:** **binaria sobre la capacidad** con un predicado voraz.
- **Pista 3 — diseño:** el rango va de `max(pesos)` a `Σ pesos`; fijada la capacidad, llena cada día con los paquetes en orden mientras quepan y cuenta los días.

**04 → Problema: Search in Rotated Sorted Array.**

- **Pista 2 — patrón:** **binaria con dos tramos ordenados**.
- **Pista 3 — diseño:** compara `nums[lo]` con `nums[mid]` para saber qué mitad está ordenada; si el objetivo cae dentro de su rango, sigue por ella; si no, por la otra.

**04 → Problema: Find Minimum in Rotated Sorted Array.**

- **Pista 2 — patrón:** **frontera sobre índices** con el predicado `nums[i] ≤ nums[n − 1]`.
- **Pista 3 — diseño:** ese predicado es falso…cierto (falso en el tramo alto, cierto desde el mínimo); el primer índice cierto es el mínimo.

**04 → Problema: Magnetic Force Between Two Balls.**

- **Pista 2 — patrón:** **maximizar el mínimo** con binaria sobre la distancia.
- **Pista 3 — diseño:** ordena las posiciones; fijada la distancia `d`, coloca voraz cada bola en la primera posición a distancia `≥ d` de la anterior y cuenta; la mayor `d` con al menos `m` bolas.

**04 → Problema: MinMaxDivision.**

- **Pista 2 — patrón:** **minimizar el máximo** con binaria sobre la suma.
- **Pista 3 — diseño:** el rango va de `max(A)` a `Σ A`; fijada la suma máxima, forma bloques voraces y comprueba que no pasan de `K`.

**04 → Problema: Factory Machines.**

- **Pista 2 — patrón:** **binaria sobre el tiempo**.
- **Pista 3 — diseño:** en tiempo `T` se fabrican `Σ ⌊T / kᵢ⌋` productos; el `hi` es `min(kᵢ) · t`, hasta `10¹⁸`. Corta la suma en cuanto llegue a `t` para no desbordar.

**04 → Problema: NailingPlanks.**

- **Pista 2 — patrón:** **binaria sobre el número de clavos** con un predicado de prefijos.
- **Pista 3 — diseño:** para un `k`, marca las posiciones de los `k` primeros clavos y haz los prefijos de las marcas (`04/01`); cada tabla `[a, b]` tiene clavo si `pref[b + 1] − pref[a] > 0`. `O((n + m) log m)`.

**04 → Problema: The Meeting Place Cannot Be Changed.**

- **Pista 2 — patrón:** **binaria en reales sobre el tiempo**.
- **Pista 3 — diseño:** en tiempo `T`, el amigo `i` alcanza `[xᵢ − vᵢT, xᵢ + vᵢT]`; se pueden reunir si la intersección de todos es no vacía (`max` de los extremos izquierdos `≤` `min` de los derechos). 100 vueltas en `[0, 10⁹]`.

**04 → Problema: Kth Smallest Number in Multiplication Table.**

- **Pista 2 — patrón:** **binaria sobre el valor** con un conteo.
- **Pista 3 — diseño:** en la fila `i` hay `min(⌊v / i⌋, n)` números `≤ v`; el conteo total es `O(m)`; el menor `v` con conteo `≥ k`.

**04 → Problema: Median of Two Sorted Arrays.**

- **Pista 2 — patrón:** **binaria sobre el corte** del arreglo más corto.
- **Pista 3 — diseño:** si se toman `i` del primero y `j = (m + n + 1)/2 − i` del segundo, el corte es válido cuando `A[i−1] ≤ B[j]` y `B[j−1] ≤ A[i]`; binaria sobre `i` con centinelas `±∞` en los bordes.

---

# 05 — Búsqueda ternaria, unimodales y exponencial

**05 → 1.** ¿Qué es una función estrictamente unimodal? 🟢

⏱️ **30 segundos.** Una función que es estrictamente decreciente hasta un punto `p` y estrictamente creciente desde él (para un mínimo): un solo valle, sin mesetas.

🗣️ **2 minutos.** «Estrictamente» es lo que importa: excluye tramos planos fuera del mínimo, que son los que impiden saber de qué lado está el valle comparando dos puntos. Para un máximo, la definición es la simétrica.

🔬 **El detalle.** Las funciones convexas son un caso más amplio que también sirve para la ternaria: pueden tener una meseta, pero solo en el mínimo.

**05 → 2.** ¿Cuántas evaluaciones hace la búsqueda exponencial si la respuesta está en la posición `p`? 🟢

⏱️ **30 segundos.** `O(log p)`: unas `⌈log₂ p⌉` sondas para encontrar el rango y otras tantas para la binaria dentro.

🗣️ **2 minutos.** La duplicación para en el primer `2ᵏ ≥ p`, con `k = ⌈log₂ p⌉`. La binaria trabaja sobre `(2^{k−1}, 2ᵏ]`, un intervalo de tamaño `2^{k−1} < p`. En total, como mucho unas `2 log₂ p` comparaciones.

🔬 **El detalle.** No depende del tamaño total: con un registro de `10¹⁸` elementos y la respuesta en la posición 5, son media docena de accesos.

**05 → 3.** En la ternaria, si `f(m₁) < f(m₂)`, ¿qué parte se descarta y por qué? 🟡

⏱️ **30 segundos.** Se descarta lo que está a la derecha de `m₂`: si el mínimo estuviera en `p ≥ m₂`, `m₁` y `m₂` estarían los dos en el tramo decreciente y sería `f(m₁) > f(m₂)`.

🗣️ **2 minutos.** Es una prueba por contradicción con la definición. En enteros, también se descarta `m₂` mismo, porque `f(m₂) > f(m₁)` y no puede ser el mínimo: por eso `hi = m₂ − 1`. En reales, `hi = m₂`.

🔬 **El detalle.** El caso simétrico, `f(m₁) > f(m₂)`, descarta lo que está a la izquierda de `m₁`; con igualdad y unimodalidad estricta, el mínimo está entre los dos y cualquiera de las dos ramas es válida.

**05 → 4.** ¿Por qué la ternaria sobre enteros para con `hi − lo > 2` y recorre el resto? 🟡

⏱️ **30 segundos.** Porque con intervalos de tres o menos elementos, `m₁` y `m₂` coinciden o se cruzan y la regla deja de reducir el intervalo; recorrer hasta tres candidatos es más simple que razonar los bordes.

🗣️ **2 minutos.** Con `hi − lo = 2`, `(hi − lo)/3 = 0`, así que `m₁ = lo` y `m₂ = hi`; las actualizaciones `lo = m₁ + 1` o `hi = m₂ − 1` aún avanzan, pero con `hi − lo = 1` ya `m₁ = lo` y `m₂ = hi` sin margen. Parar en `> 2` y comparar los restantes elimina esa clase de errores.

🔬 **El detalle.** La binaria sobre la diferencia no tiene este problema: es la plantilla `firstTrue`, con su invariante y su parada habituales.

**05 → 5.** ¿Qué predicado usas para encontrar el mínimo de una función unimodal con la binaria de `05/04`? 🟡

⏱️ **30 segundos.** `P(x) = f(x + 1) ≥ f(x)`, falso mientras la función baja y cierto desde el mínimo. El primer `x` con `P` cierto es el mínimo.

🗣️ **2 minutos.** Con `f` estrictamente unimodal con mínimo en `p`: para `x < p`, `f(x + 1) < f(x)` y `P` es falso; para `x ≥ p`, `f(x + 1) > f(x)` y `P` es cierto. Es monótono y `firstTrue(lo, hi, P)` devuelve `p`. Cada paso evalúa `f` dos veces.

🔬 **El detalle.** Es lo que resuelven los problemas de «pico» (Find Peak Element): hacia dónde sube la función en `mid` dice de qué lado hay un pico.

**05 → 6.** Da una función con un único mínimo global en la que la ternaria falla, y explica qué devuelve. 🟠

⏱️ **30 segundos.** `[1, 4, 4, 4, 4, 4, 4, 5]`: único mínimo en la posición 0, pero con `m₁ = 2` y `m₂ = 5` los dos valen 4; la ternaria hace `lo = 3` y devuelve la posición 5, con valor 4.

🗣️ **2 minutos.** La función no es estrictamente unimodal: tiene una meseta lejos del mínimo. Con `f(m₁) = f(m₂)`, la ternaria supone que el mínimo está entre los dos, y aquí está a la izquierda. No hay error de ejecución: devuelve un valor que no es el mínimo.

🔬 **El detalle.** En este ejemplo la binaria sobre la diferencia acierta por casualidad (el predicado es cierto en todas las posiciones), pero falla con una meseta **antes** del mínimo: en `[5, 4, 4, 4, 1, 6]` el predicado es F, C, C, F, C, no es monótono, y la binaria devuelve la posición 1 en lugar de la 4.

**05 → 7.** ¿Por qué una función convexa con una meseta en el mínimo no rompe la ternaria? 🟠

⏱️ **30 segundos.** Porque en una función convexa la meseta solo puede estar en el mínimo: si `f(m₁) = f(m₂)`, el mínimo está en `[m₁, m₂]`, y descartar `[lo, m₁)` no lo pierde.

🗣️ **2 minutos.** Por convexidad, si `f(m₁) = f(m₂)`, todo punto fuera de `[m₁, m₂]` tiene un valor mayor o igual: la recta entre `m₁` y `m₂` es horizontal y la función queda por encima fuera del segmento. El mínimo está dentro, y la rama `lo = m₁ + 1` conserva `m₂`, que tiene el valor mínimo o mayor que el del mínimo interior.

🔬 **El detalle.** Por eso los costes de la forma `Σ wᵢ |x − xᵢ|` o `Σ (x − xᵢ)²`, que son sumas de convexas, son terreno seguro para la ternaria.

**05 → 8.** Demuestra que la búsqueda exponencial hace `O(log p)` comparaciones. 🟠

⏱️ **30 segundos.** La duplicación hace `⌈log₂ p⌉ + 1` sondas y la binaria sobre `(2^{k−1}, 2ᵏ]` hace `O(log 2^{k−1}) = O(log p)`; la suma es `O(log p)`.

🗣️ **2 minutos.** Sea `k` el primer exponente con `a[2ᵏ] ≥ x`. Como `a[2^{k−1}] < x`, la respuesta `p` cumple `p > 2^{k−1}`, luego `k − 1 < log₂ p` y `k ≤ ⌈log₂ p⌉`. La duplicación hace `k + 1` sondas. El intervalo de la binaria tiene `2^{k−1}` elementos, que es menor que `p`, y la binaria hace `⌈log₂ 2^{k−1}⌉ = k − 1` pasos. Total `2k = O(log p)`.

🔬 **El detalle.** Con `p = 0` se devuelve en la primera comprobación. Hay variantes que duplican más rápido (`2^{2ᵏ}`) para respuestas enormes, con un coste `O(log p)` igual y menos sondas en la primera fase.

**05 → 9.** Compara el número de evaluaciones de la ternaria y de la binaria sobre la diferencia para `n = 10⁹`. 🟠

⏱️ **30 segundos.** La ternaria, unas `2 log_{3/2} 10⁹ ≈ 102` evaluaciones; la binaria sobre la diferencia, `2 log₂ 10⁹ ≈ 60`.

🗣️ **2 minutos.** La ternaria evalúa dos puntos por vuelta y conserva `2/3` del intervalo: `log_{3/2} n` vueltas. La binaria sobre la diferencia también evalúa dos puntos por paso, pero conserva `1/2`: `log₂ n` pasos. El cociente es `log₂(3/2)⁻¹ ≈ 1,71`.

🔬 **El detalle.** Si `f` es barata, la diferencia no importa; si cada evaluación es un recorrido de `O(n)`, la binaria sobre la diferencia ahorra un 40 % del tiempo.

**05 → 10.** ¿Cómo escribirías la ternaria en reales en Java y en C++ para que dé el mismo resultado, y qué parte depende del redondeo? 🟠

⏱️ **30 segundos.** Con la misma fórmula para los puntos (`lo + (hi − lo)/3`), el mismo número de vueltas y `double` en los dos. La aritmética IEEE 754 de `+ − × /` da los mismos resultados; lo que puede cambiar es la evaluación de `f`.

🗣️ **2 minutos.** Java garantiza IEEE 754 estricto en las operaciones básicas (desde Java 17, siempre). En C++, el compilador puede fusionar `a · b + c` en una sola instrucción FMA con un redondeo menos, según las opciones. Y las funciones matemáticas (`Math.sin` frente a `std::sin`) pueden diferir en el último bit. Con 100 vueltas, esas diferencias quedan muy por debajo de la precisión pedida.

🔬 **El detalle.** Si hace falta reproducibilidad bit a bit, en Java `StrictMath` y en C++ desactivar la contracción (`-ffp-contract=off`).

**05 → 11.** ¿Qué es la búsqueda de la sección áurea y qué ahorra respecto de la ternaria? 🔴

⏱️ **30 segundos.** Es la ternaria con los dos puntos colocados en las proporciones de la razón áurea: así uno de los dos puntos de la vuelta siguiente coincide con uno de la actual, y cada vuelta hace **una** evaluación nueva en lugar de dos.

🗣️ **2 minutos.** Con `φ = (1 + √5)/2`, los puntos están a `1/φ² ≈ 0,382` y `1/φ ≈ 0,618` del intervalo. Tras descartar un lado, el punto que queda dentro está justo en la posición áurea del intervalo nuevo. Cada evaluación reduce el intervalo a `0,618`: `log_φ n ≈ 1,44 log₂ n` evaluaciones, frente a `≈ 3,4 log₂ n` de la ternaria.

🔬 **El detalle.** Compensa cuando `f` es cara; en reales, los errores de redondeo pueden desplazar el punto reutilizado, y hay que recalcularlo de vez en cuando. La búsqueda de Fibonacci es la versión entera.

**05 → 12.** La suma de dos funciones unimodales, ¿es unimodal? ¿Y la de dos convexas? Demuestra o da un contraejemplo. 🔴

⏱️ **30 segundos.** La suma de dos unimodales no es unimodal en general: con los valles separados, la suma tiene dos mínimos locales. La suma de dos convexas sí es convexa.

🗣️ **2 minutos.** Contraejemplo: `f(x) = −e^{−x²}` y `g(x) = −e^{−(x−10)²}` son estrictamente unimodales (valles en 0 y en 10), pero `f + g` tiene dos valles, cerca de 0 y de 10, con una loma en medio. Para convexas: `(f + g)(tx + (1−t)y) ≤ t(f + g)(x) + (1−t)(f + g)(y)` sumando las dos desigualdades de convexidad.

🔬 **El detalle.** Es la razón práctica para preferir argumentar convexidad: los costes suelen ser sumas, y la convexidad se conserva al sumar y al tomar máximos.

**05 → Problema: Coste de transporte.**

- **Pista 2 — patrón:** **ternaria sobre una función convexa** de enteros, o **mediana ponderada**.
- **Pista 3 — diseño:** el coste es suma de convexas: ternaria sobre `c` en `[min xᵢ, max xᵢ]`, con cada evaluación en `O(n)` y el coste en 64 bits. Alternativa `O(n log n)`: ordena por posición y busca la primera posición donde el peso acumulado alcanza la mitad del total.

**05 → Problema: Registro sin tamaño.**

- **Pista 2 — patrón:** **búsqueda exponencial** y binaria en el último tramo.
- **Pista 3 — diseño:** comprueba `get(0)`; duplica `hi` desde 1 mientras `get(hi) < x`; binaria en `[hi/2 + 1, hi]`. Cuidado con `hi · 2` cerca de `2⁶³`: con `n ≤ 10¹⁸`, `hi` no pasa de `2⁶⁰`.

**05 → Problema: Peak Index in a Mountain Array.**

- **Pista 2 — patrón:** **binaria sobre la diferencia**.
- **Pista 3 — diseño:** el primer `i` con `arr[i] > arr[i + 1]` es el pico: `firstTrue` con ese predicado sobre `[0, n − 1)`.

**05 → Problema: Find Peak Element.**

- **Pista 2 — patrón:** **binaria sobre la diferencia**.
- **Pista 3 — diseño:** si `nums[mid] < nums[mid + 1]`, hay un pico a la derecha (la secuencia sube y en el borde vale `−∞`); si no, a la izquierda o en `mid`. Es la misma plantilla que el pico de la montaña, aunque la función no sea unimodal.

**05 → Problema: Meeting on the Line.**

- **Pista 2 — patrón:** **ternaria en reales** sobre el punto de reunión.
- **Pista 3 — diseño:** el tiempo máximo `max(tᵢ + |xᵢ − y|)` es convexo en `y` (máximo de convexas); ternaria en `[min x, max x]`. Alternativa exacta: el punto medio entre `max(xᵢ + tᵢ)` y `min(xᵢ − tᵢ)`.

**05 → Problema: Devu and his Brother.**

- **Pista 2 — patrón:** **ternaria sobre el umbral** `t`.
- **Pista 3 — diseño:** el coste de subir todos los de `a` a al menos `t` y bajar todos los de `b` a como mucho `t` es convexo en `t`; ternaria sobre enteros en `[min, max]` de todos los valores, con cada evaluación en `O(n + m)` y en 64 bits.

**05 → Problema: Searching Local Minimum.**

- **Pista 2 — patrón:** **binaria sobre la diferencia** con un invariante sobre los extremos.
- **Pista 3 — diseño:** mantén `[lo, hi]` con la garantía de que hay un mínimo local dentro (los bordes «suben» hacia fuera); consulta `mid` y `mid + 1` y quédate con la mitad hacia la que baja. Unas 34 consultas para `10⁵`.

**05 → Problema: Ruler (hard version).**

- **Pista 2 — patrón:** **ternaria interactiva**: cada consulta distingue tres casos.
- **Pista 3 — diseño:** consulta un rectángulo de lados `a` y `b` con `lo < a < b < hi` repartidos en tercios; el área respondida dice si el valor buscado está por debajo de `a`, entre `a` y `b`, o por encima de `b`. `log₃ 1000 ≈ 7` consultas.

**05 → Problema: Maximize!.**

- **Pista 2 — patrón:** **ternaria sobre el número de elementos pequeños** que se toman junto al máximo.
- **Pista 3 — diseño:** el último añadido es el máximo; con él, conviene tomar un prefijo de los menores; la función `máximo − media` sobre la longitud del prefijo es unimodal. Con prefijos de sumas, cada evaluación es `O(1)`; o dos punteros porque el óptimo avanza con el máximo.

**05 → Problema: Weakness and Poorness.**

- **Pista 2 — patrón:** **ternaria en reales** con **Kadane** dentro.
- **Pista 3 — diseño:** la debilidad de `a − x` es el máximo de la suma de un tramo en valor absoluto: Kadane para el máximo y para el mínimo ([`04/03`](../04-secuencias/03-kadane-y-subarreglos.md)). Es convexa en `x` (máximo de funciones lineales); 100 vueltas en `[−10⁴, 10⁴]` con salida a seis decimales.

---

# 06 — Simulación

**06 → S1.** ¿Qué algoritmo usa `sorted` de Python y qué garantiza? 🟢

⏱️ **30 segundos.** TimSort: estable, `O(n log n)` en el caso peor y `O(n)` con datos ya ordenados.

🗣️ **2 minutos.** Detecta tramos ya ordenados (o al revés, que invierte), los alarga con inserción hasta un tamaño mínimo y los mezcla con reglas que mantienen equilibrada la pila de tramos. La estabilidad permite ordenar por varios criterios en pasadas sucesivas.

🔬 **El detalle.** [`05/01`](01-ordenacion-por-comparacion.md), §7. Java usa el mismo algoritmo para ordenar objetos.

**06 → S2.** ¿Por qué *quicksort* con pivote aleatorio no tiene entradas malas, y qué sigue pudiendo pasar? 🟡

⏱️ **30 segundos.** Porque el caso peor depende de las elecciones del algoritmo, no de la entrada: ningún adversario puede preparar una entrada mala. Sigue pudiendo pasar que la suerte sea mala, con probabilidad ínfima.

🗣️ **2 minutos.** El coste esperado es `Θ(n log n)` para **toda** entrada. La probabilidad de alejarse mucho de él es exponencialmente pequeña. Lo que sí puede ocurrir: con una semilla fija y conocida, el adversario vuelve a poder preparar la entrada; y sin partición que reparta los iguales, muchos repetidos llevan al caso cuadrático aunque el pivote sea aleatorio.

🔬 **El detalle.** Por eso la plantilla usa Hoare con comparaciones estrictas, y en jueces con *hacks*, semilla del reloj.

**06 → S3.** ¿Qué condición necesita un comparador de `std::sort` y qué pasa si no la cumple? 🟡

⏱️ **30 segundos.** Un orden débil estricto: irreflexivo (`comp(a, a)` falso), transitivo, y con la incomparabilidad transitiva. Si no la cumple, el comportamiento es indefinido: resultados incorrectos o lecturas fuera del rango.

🗣️ **2 minutos.** El error típico es usar `<=` en lugar de `<`: `comp(a, a)` es cierto y la partición de `std::sort` puede salirse del arreglo buscando un elemento que la detenga. Otro: comparadores que no son transitivos, como comparar puntos por ángulo con tolerancia.

🔬 **El detalle.** En Java, un comparador inconsistente puede lanzar `IllegalArgumentException: Comparison method violates its general contract` desde TimSort (`03/03`).

**06 → S4.** ¿Cuándo un *counting sort* es peor idea que `sort`? 🟢

⏱️ **30 segundos.** Cuando el rango de valores `k` es mucho mayor que `n`: el arreglo de cuentas cuesta más que ordenar, en tiempo y memoria.

🗣️ **2 minutos.** Con `n = 10⁵` y valores hasta `10⁹`, el *counting* necesita `10⁹` contadores. También cuando las claves no son enteras o se ordena con un comparador complejo. Y en Python, un *counting* en Python puro puede perder contra `sorted`, que corre en C.

🔬 **El detalle.** `05/02`, §7.

**06 → S5.** ¿Qué relación hay entre las inversiones y la ordenación por inserción? 🟢

⏱️ **30 segundos.** El número de desplazamientos de la inserción es exactamente el número de inversiones: su coste es `Θ(n + I)`.

🗣️ **2 minutos.** Al insertar `a[j]`, se desplazan los anteriores estrictamente mayores, que son los que forman inversión con él. Sumando sobre `j`, todas las inversiones se cuentan una vez.

🔬 **El detalle.** Por eso la inserción es tan rápida con datos casi ordenados y está dentro de TimSort e *introsort*.

**06 → S6.** ¿Por qué *quickselect* es lineal en esperanza y *quicksort* no? 🟡

⏱️ **30 segundos.** Porque *quickselect* solo sigue por un lado: la suma de los tamaños es geométrica, `n + 3n/4 + …`, mientras que *quicksort* procesa los dos lados en cada nivel.

🗣️ **2 minutos.** Con particiones razonables, *quicksort* tiene `Θ(log n)` niveles con `Θ(n)` de trabajo por nivel; *quickselect* tiene los mismos niveles, pero el trabajo de cada uno es el tamaño de un solo tramo, que decrece geométricamente.

🔬 **El detalle.** `05/03`, §2.

**06 → S7.** ¿Cuál es el tipo correcto para un contador de inversiones con `n = 2·10⁵`, y por qué? 🟢

⏱️ **30 segundos.** `long long` en C++ o `long` en Java: el máximo, `n(n−1)/2 ≈ 2·10¹⁰`, pasa de `2³¹ − 1`.

🗣️ **2 minutos.** El desbordamiento no da error: produce un número negativo o pequeño que pasa los ejemplos y falla en los casos grandes. Python no tiene el problema.

🔬 **El detalle.** El caso de prueba que lo detecta es el arreglo de tamaño máximo ordenado al revés.

**06 → S8.** ¿Cuál es el invariante de la plantilla `firstTrue`? 🟡

⏱️ **30 segundos.** `P` es falso en `[lo₀, lo)` y cierto en `[hi, hi₀)`.

🗣️ **2 minutos.** Al principio los dos tramos están vacíos. Si `P(mid)` es falso, por la monotonía todo `[lo₀, mid]` es falso y `lo = mid + 1`; si es cierto, `hi = mid`. `hi − lo` baja cada vuelta. Al salir, `lo = hi` es la frontera.

🔬 **El detalle.** `05/04`, §2, y la prueba completa en [`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md).

**06 → S9.** ¿Cómo obtienes «el último `≤ x`» con *upper bound*? 🟢

⏱️ **30 segundos.** Es `upperBound(x) − 1`; si da `−1`, no hay ninguno.

🗣️ **2 minutos.** El *upper bound* es el primero `> x`; el anterior es el último `≤ x`. Del mismo modo, el último `< x` es `lowerBound(x) − 1`.

🔬 **El detalle.** En C++, `std::prev(std::upper_bound(...))` tras comprobar que no es `begin()`; en Python, `bisect_right(a, x) − 1`.

**06 → S10.** ¿Por qué la binaria en reales no se para con `hi − lo > ε`? 🟡

⏱️ **30 segundos.** Porque con valores grandes dos `double` consecutivos distan más que `ε`: el intervalo deja de encoger y el bucle no acaba.

🗣️ **2 minutos.** Cerca de `10¹⁵`, la separación entre `double` vecinos es `0,125`. `mid` redondea a `lo` o a `hi` y la condición `hi − lo > 10⁻⁹` sigue siendo cierta para siempre. Con 100 vueltas fijas, termina siempre.

🔬 **El detalle.** `05/04`, §5.

**06 → S11.** ¿Qué condición necesita la ternaria y qué la rompe? 🟡

⏱️ **30 segundos.** Unimodalidad estricta (o convexidad). La rompen las mesetas fuera del mínimo y los mínimos locales múltiples.

🗣️ **2 minutos.** Con `f(m₁) = f(m₂)` en una meseta, la ternaria no sabe de qué lado está el mínimo y puede descartar el tramo que lo contiene. Con varios valles, compara dos puntos de valles distintos y se queda con uno cualquiera.

🔬 **El detalle.** [`05/05`](05-ternaria-y-exponencial.md), §2. Las sumas de convexas son convexas y por eso seguras.

**06 → S12.** ¿Cuándo usarías la búsqueda exponencial en lugar de la binaria? 🟢

⏱️ **30 segundos.** Cuando no se conoce el tamaño de la secuencia o no hay una cota razonable para la respuesta, y cuando la respuesta suele estar cerca del principio.

🗣️ **2 minutos.** La exponencial cuesta `O(log p)`, con `p` la posición de la respuesta: no depende del tamaño total. Con el tamaño conocido y la respuesta en cualquier sitio, la binaria directa hace lo mismo.

🔬 **El detalle.** La *galloping* de TimSort es una búsqueda exponencial.

**06 → S13.** Tu binaria sobre la respuesta pasa los ejemplos y da WA en el caso 14. ¿Qué dos cosas compruebas primero? 🟠

⏱️ **30 segundos.** La monotonía del predicado y el rango inicial (`lo`, `hi`). Después, el desbordamiento dentro del predicado.

🗣️ **2 minutos.** Si el predicado no es monótono, la binaria devuelve una frontera cualquiera: hay que demostrarlo o buscar un contraejemplo pequeño con fuerza bruta. Si `hi` es menor que la respuesta real, la binaria devuelve `hi` sin avisar. Y con valores grandes, una suma o un producto dentro del predicado desborda y cambia su valor.

🔬 **El detalle.** El *stress test* contra una fuerza bruta que prueba todos los valores del rango detecta los tres en minutos ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).

**06 → S14.** Un compañero ordena con `Comparator` que devuelve `a.x - b.x` y da WA solo con valores negativos grandes. ¿Qué pasa? 🟠

⏱️ **30 segundos.** `a.x − b.x` desborda en `int` cuando los signos son opuestos y los valores grandes: el signo sale al revés y el orden es incoherente.

🗣️ **2 minutos.** Con `a.x = 2·10⁹` y `b.x = −2·10⁹`, la resta da `4·10⁹`, que en `int` se convierte en un negativo: el comparador dice que `a < b`. Además, el comparador deja de ser transitivo y TimSort puede lanzar una excepción. La forma correcta es `Integer.compare(a.x, b.x)`.

🔬 **El detalle.** `Comparator.comparingInt(p -> p.x)` también es correcto y más legible.

**06 → S15.** «Para la mediana de un millón de valores, ordeno.» ¿Es mala respuesta en una entrevista? ¿Qué añadirías? 🟠

⏱️ **30 segundos.** No es mala: `n log n` con un millón es inmediato. Añadiría que se puede en `O(n)` esperado con *quickselect* (`nth_element` en C++), y cuándo merece la pena.

🗣️ **2 minutos.** En una entrevista se valora conocer la alternativa y su coste: «ordenar es `n log n` y simple; *quickselect* es lineal en esperanza, con caso peor cuadrático; la mediana de medianas da lineal garantizado con una constante alta». Si los datos llegan en flujo, dos montículos ([`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md)).

🔬 **El detalle.** Si hay que responder muchas medianas sobre los mismos datos, ordenar una vez es lo mejor.

**06 → S16.** Te piden «el mínimo de una función» y la ternaria da WA. Da dos causas posibles. 🟠

⏱️ **30 segundos.** La función no es estrictamente unimodal (mesetas o varios mínimos), o la ternaria sobre enteros tiene mal los bordes (no recorre los candidatos finales o descarta `m₂` en la igualdad).

🗣️ **2 minutos.** Lo primero es comprobar la unimodalidad: imprimir `f` sobre un caso pequeño. Si tiene mesetas, una binaria sobre la diferencia no lo arregla; hay que cambiar de técnica o de formulación. Si es unimodal, revisar la parada: `while (hi − lo > 2)` y recorrer el resto.

🔬 **El detalle.** En reales, una tercera causa es la precisión de `f`: si evalúa con errores mayores que la diferencia entre `f(m₁)` y `f(m₂)`, la comparación es ruido.

**06 → S17.** ¿Por qué `std::lower_bound` sobre un `std::set` da TLE aunque la respuesta sea correcta? 🟠

⏱️ **30 segundos.** Porque los iteradores de `std::set` no son de acceso aleatorio: el algoritmo genérico hace `O(log n)` comparaciones pero `O(n)` avances de iterador.

🗣️ **2 minutos.** La función miembro `s.lower_bound(x)` baja por el árbol en `O(log n)`. El genérico solo sabe avanzar de uno en uno. Con `10⁵` consultas sobre un `set` de `10⁵`, es la diferencia entre `2·10⁶` y `10¹⁰` operaciones.

🔬 **El detalle.** `05/04`, §6.

**06 → S18.** «Ningún algoritmo de ordenación baja de `n log n`.» Matiza la frase con precisión. 🔴

⏱️ **30 segundos.** Ningún algoritmo de ordenación **por comparación** baja de `Ω(n log n)` comparaciones en el caso peor. Los que usan la clave como índice (*counting*, *radix*) sí bajan, con claves enteras acotadas.

🗣️ **2 minutos.** La cota viene del árbol de decisión: `n!` permutaciones necesitan altura `log₂ n! = Θ(n log n)`. Es una cota sobre comparaciones en el modelo de comparación. Fuera de ese modelo, el *counting sort* es `Θ(n + k)`. Y dentro del modelo, con entradas especiales (casi ordenadas), TimSort o la inserción son lineales: la cota es del caso peor.

🔬 **El detalle.** La cota también vale para el caso promedio y para algoritmos aleatorios en esperanza.

**06 → S19.** Demuestra que el número mínimo de intercambios **adyacentes** para ordenar es el número de inversiones. 🔴

⏱️ **30 segundos.** Un intercambio adyacente cambia el orden relativo de un solo par: modifica las inversiones en exactamente 1. Hacen falta al menos `I`, y la inserción (o la burbuja) usa exactamente `I`.

🗣️ **2 minutos.** Cota inferior: cada intercambio adyacente reduce `I` como mucho en 1, y el arreglo ordenado tiene `I = 0`. Cota superior: mientras haya inversiones, hay dos vecinos en inversión (si no, el arreglo estaría ordenado); intercambiarlos reduce `I` en exactamente 1. Las dos cotas coinciden.

🔬 **El detalle.** `05/03`, pregunta 3. Con intercambios arbitrarios, el mínimo es `n − ciclos`.

**06 → Problema: Cobertura de *routers*.**

- **Pista 2 — patrón:** **binaria sobre la respuesta** con un predicado **voraz** sobre las casas ordenadas.
- **Pista 3 — diseño:** ordena las posiciones; fijado `r`, coloca un *router* en `x + r` para la primera casa sin cubrir, salta todas las casas `≤ x + 2r` y cuenta; `r` funciona si bastan `k`. `firstTrue(0, 5·10⁸ + 1, r -> routers(r) <= k)`.

**06 → Problema: Adelantamientos.**

- **Pista 2 — patrón:** **contar inversiones** de las velocidades en orden de posición.
- **Pista 3 — diseño:** ordena por posición de delante hacia atrás; un adelantamiento es un par donde el de detrás es estrictamente más rápido: inversiones (con el orden adecuado) en `O(n log n)` con la mezcla; contador de 64 bits.

**06 → Problema: Clasificación con extremos.**

- **Pista 2 — patrón:** **comparador** que no desborda y define un **orden total**.
- **Pista 3 — diseño:** en Java, nunca la resta: `Integer.compare(b.score, a.score)`, después `Integer.compare(a.time, b.time)` y `a.name.compareTo(b.name)`. En C++, ordena tuplas `(−score, time, name)` con `score` en 64 bits; en Python, la clave `(−score, time, name)`.

**06 → Problema: Emparejar tallas.**

- **Pista 2 — patrón:** **ordenar** las dos listas y emparejar en orden.
- **Pista 3 — diseño:** el argumento de intercambio (`02/04`): si dos parejas se cruzan, descruzarlas no empeora el coste. Ordena las dos y suma las diferencias en 64 bits.

**06 → Problema: Array Partition.**

- **Pista 2 — patrón:** **ordenar** y emparejar vecinos.
- **Pista 3 — diseño:** tras ordenar, la suma de los elementos en posiciones pares es la respuesta: el menor solo puede «salvar» a su pareja si esta es la siguiente.

**06 → Problema: Single Element in a Sorted Array.**

- **Pista 2 — patrón:** **frontera sobre índices** con la paridad.
- **Pista 3 — diseño:** antes del único, cada pareja empieza en índice par; después, en impar. Predicado sobre índices pares `i`: `nums[i] ≠ nums[i + 1]`; el primero cierto es el único.

**06 → Problema: H-Index II.**

- **Pista 2 — patrón:** **binaria sobre índices** con un predicado de conteo.
- **Pista 3 — diseño:** en la posición `i` hay `n − i` artículos con al menos `citations[i]` citas; busca el primer `i` con `citations[i] ≥ n − i`; la respuesta es `n − i`.

**06 → Problema: Find K Closest Elements.**

- **Pista 2 — patrón:** **binaria sobre el inicio** de la ventana de longitud `k`.
- **Pista 3 — diseño:** para un inicio `i`, compara `x − arr[i]` con `arr[i + k] − x`: si el primero es mayor, la ventana debe moverse a la derecha. Es monótono; binaria sobre `i` en `[0, n − k]`.

**06 → Problema: Minimum Number of Days to Make m Bouquets.**

- **Pista 2 — patrón:** **binaria sobre el día** con un predicado lineal.
- **Pista 3 — diseño:** fijado `d`, recorre las flores contando tramos consecutivos de florecidas (`bloomDay ≤ d`) y cuántos ramos de `k` salen de cada uno; si `m · k > n`, imposible.

**06 → Problema: Motarack's Birthday.**

- **Pista 2 — patrón:** **extremos de los vecinos** de los huecos.
- **Pista 3 — diseño:** el valor `k` solo afecta a los pares con un hueco; toma el mínimo y el máximo de los vecinos conocidos de los huecos; `k` es su punto medio; calcula la diferencia máxima con `k` colocado.
