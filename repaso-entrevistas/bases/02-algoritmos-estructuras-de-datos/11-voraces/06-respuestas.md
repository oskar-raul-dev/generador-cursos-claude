# Respuestas — bloque 11: Voraces

> Solucionario del bloque `11`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--cuándo-funciona-un-voraz) · [02](#02--intervalos) · [03](#03--plazos-huffman-mochila-fraccionaria-y-monedas) · [04](#04--matroides-y-cómo-romper-un-voraz) · [05](#05--simulación)

---

# 01 — Cuándo funciona un voraz

**01 → 1.** ¿Qué dos propiedades necesita un problema para que un voraz sea correcto? 🟢

⏱️ **30 segundos.** La propiedad de la elección voraz —existe una óptima que contiene la primera elección voraz— y la subestructura óptima —lo que queda tras elegir es un subproblema del mismo tipo, resuelto de forma óptima dentro de la óptima global—.

🗣️ **2 minutos.** Con las dos, la corrección sale por inducción sobre el número de decisiones. La subestructura óptima sola no basta: la tiene también la DP, que por eso prueba todas las primeras decisiones. La elección voraz es lo que permite quedarse con una.

🔬 **El detalle.** CLRS, §16.2, las enuncia así. Las matroides ([`11/04`](04-matroides-y-contraejemplos.md)) son una estructura que garantiza las dos a la vez para toda función de pesos.

**01 → 2.** ¿Qué dice el teorema del intercambio de vecinos? 🟢

⏱️ **30 segundos.** Si intercambiar dos elementos consecutivos que están «al revés» según una clave nunca empeora el coste, ordenar por esa clave es óptimo.

🗣️ **2 minutos.** Cualquier ordenación se convierte en la ordenada con intercambios de vecinos en orden malo (es lo que hace la burbuja), y cada uno no empeora. Por tanto la ordenada no es peor que ninguna, en particular que una óptima.

🔬 **El detalle.** Exige que la relación «va antes» sea un orden total consistente (transitiva). Con claves como `p/w` lo es; con reglas que dependen del par concreto, hay que comprobarlo.

**01 → 3.** ¿Qué tres pasos tiene una prueba de «el voraz se adelanta»? 🟢

⏱️ **30 segundos.** Definir una medida del progreso tras `k` pasos; probar por inducción que la del voraz nunca es menor que la de cualquier otra solución; concluir que el voraz termina en tantos pasos o menos.

🗣️ **2 minutos.** En las gasolineras, la medida es la posición tras la parada `k`. El caso base es `k = 0` (los dos en el origen). El paso usa que desde más lejos se alcanza al menos lo mismo.

🔬 **El detalle.** El nombre viene de Kleinberg y Tardos, §4.1 (*greedy stays ahead*). La parte difícil es elegir una medida que haga el paso inductivo inmediato.

**01 → 4.** ¿En qué se diferencian el argumento de intercambio y «el voraz se adelanta», y cuándo encaja cada uno? 🟡

⏱️ **30 segundos.** El intercambio transforma una óptima en la voraz sin empeorarla; «el voraz se adelanta» compara el progreso paso a paso. El primero encaja en ordenación y selección; el segundo, en problemas de avance y cobertura.

🗣️ **2 minutos.** En la selección de actividades sirven los dos: por intercambio, se cambia el primer intervalo de una óptima por el que termina antes; adelantándose, el `k`-ésimo intervalo voraz termina no después que el `k`-ésimo de cualquier otra. En ordenaciones con coste acumulado, el intercambio de vecinos es lo natural.

🔬 **El detalle.** Hay una tercera prueba, por **cota inferior estructural**: demostrar que ninguna solución puede ser mejor que un valor y que el voraz lo alcanza (el número de salas es la profundidad máxima, [`11/02`](02-intervalos.md)).

**01 → 5.** ¿Qué tienen en común un voraz y una DP, y qué tiene el voraz que la DP no necesita? 🟡

⏱️ **30 segundos.** Los dos necesitan subestructura óptima. El voraz añade la elección voraz: sabe cuál es la primera decisión correcta sin probarlas todas.

🗣️ **2 minutos.** La DP resuelve los subproblemas de todas las primeras decisiones y elige la mejor; el voraz elige una y no mira atrás. Por eso, cuando el voraz es correcto, es más barato; y cuando no, la DP es la red de seguridad.

🔬 **El detalle.** Muchos problemas tienen las dos soluciones, y la DP sirve de oráculo para comprobar el voraz con un *stress test* ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).

**01 → 6.** ¿Por qué la regla de Smith compara `pₓ · w_y` con `p_y · wₓ` y no las razones? 🟡

⏱️ **30 segundos.** Porque las razones en coma flotante pueden empatar o desempatar mal por redondeo, y dividir enteros trunca. Los productos cruzados son exactos si caben en 64 bits.

🗣️ **2 minutos.** `pₓ / wₓ < p_y / w_y` equivale a `pₓ · w_y < p_y · wₓ` con pesos positivos. Con `p, w ≤ 10⁹`, el producto llega a `10¹⁸`, que cabe en `long`. Un comparador con `double` puede no ser transitivo en los empates, y `Collections.sort` puede lanzar «Comparison method violates its general contract».

🔬 **El detalle.** Si los valores llegan a `10¹⁸`, el producto necesita `__int128` en C++ o `Math.multiplyHigh`/`BigInteger` en Java; en Python, `Fraction` o los productos, que son exactos.

**01 → 7.** Compara cómo escribirías el comparador de la regla de Smith en C++, Java y Python sin errores de desbordamiento ni de coma flotante. 🟡

⏱️ **30 segundos.** C++: una lambda `a.p * b.w < b.p * a.w` con `long long`. Java: `Long.compare(a[0] * b[1], b[0] * a[1])`. Python: `cmp_to_key` con la misma resta de productos, o `key=lambda j: Fraction(j[0], j[1])`.

🗣️ **2 minutos.** En Java, nunca `return (int)(a[0] * b[1] − b[0] * a[1])`: la conversión a `int` corta y el signo puede salir mal. En C++, el comparador tiene que ser un orden estricto (`<`, no `<=`) o `std::sort` tiene comportamiento indefinido. En Python, la clave con `Fraction` es exacta y más clara que `cmp_to_key`, a cambio de algo de velocidad.

🔬 **El detalle.** En JavaScript, `p * w` pasa de `2⁵³` con valores de `10⁹`, y el comparador pierde exactitud: hace falta `BigInt` o comparar con cuidado.

**01 → 8.** Haz la cuenta del intercambio de dos vecinos para el taller y deriva la regla de Smith. 🟠

⏱️ **30 segundos.** Con `x` e `y` seguidos desde el instante `T`, el resto no cambia; `x` primero cuesta `wₓ(T + pₓ) + w_y(T + pₓ + p_y)` y `y` primero `w_y(T + p_y) + wₓ(T + p_y + pₓ)`. La diferencia es `w_y pₓ − wₓ p_y`, así que conviene `x` primero si `pₓ/wₓ < p_y/w_y`.

🗣️ **2 minutos.** Desarrollando, los términos con `T` y los `wₓ pₓ`, `w_y p_y` se cancelan; queda la comparación de productos cruzados. Por el teorema de vecinos, ordenar por `p/w` creciente es óptimo.

🔬 **El detalle.** Con todos los pesos iguales, la regla se reduce a «el más corto primero» (SPT); con todas las duraciones iguales, a «el de más peso primero».

**01 → 9.** Demuestra con «el voraz se adelanta» que parar en la última gasolinera alcanzable da el mínimo de paradas. 🟠

⏱️ **30 segundos.** Medida: la posición tras la parada `k`. Si el voraz está en `g_k ≥ o_k`, desde `g_k` alcanza todo lo que alcanza `o_k`; la parada `o_{k+1}` era alcanzable desde `o_k`, así que `g_{k+1}`, la última alcanzable desde `g_k`, está en `≥ o_{k+1}`.

🗣️ **2 minutos.** Caso base: `g₀ = o₀ = 0`. Paso: `o_{k+1} ≤ o_k + R ≤ g_k + R`, y el voraz elige la mayor gasolinera `≤ g_k + R`, luego `g_{k+1} ≥ o_{k+1}`. Si `O` llega a `L` tras `m` paradas, `L ≤ o_m + R ≤ g_m + R`: el voraz llega con `m` paradas o menos.

🔬 **El detalle.** Si el voraz no encuentra gasolinera nueva alcanzable, ninguna estrategia puede pasar de ahí, porque ninguna está más adelantada: la respuesta es `−1`.

**01 → 10.** ¿Por qué el voraz de las gasolineras deja de funcionar si cada una da una cantidad distinta de combustible? 🟠

⏱️ **30 segundos.** Porque estar más lejos deja de ser siempre mejor: una gasolinera cercana con mucho combustible puede valer más que una lejana con poco, y la medida «posición» ya no captura el progreso.

🗣️ **2 minutos.** La versión correcta pasa por las gasolineras y guarda las alcanzadas en un montículo de máximos por combustible; cuando falta, «para» retroactivamente en la de más combustible de las pasadas. Es otro voraz, con otra prueba (intercambio sobre qué paradas hacer).

🔬 **El detalle.** Es LeetCode Minimum Number of Refueling Stops: el mismo enunciado con un dato más cambia la técnica.

**01 → 11.** ¿Por qué quitar el primer dígito mayor que su siguiente es la elección voraz correcta, y qué haces si no hay ninguno? 🔴

⏱️ **30 segundos.** Porque la cifra más significativa domina: si el dígito `i` es mayor que el `i + 1`, quitarlo baja la cifra en la posición `i`, y ninguna otra elección consigue un número menor. Si no hay ninguno (los dígitos son no decrecientes), se quita el último.

🗣️ **2 minutos.** Por intercambio: una solución que conserve ese dígito y quite otro más a la derecha tiene en la posición `i` una cifra mayor (o igual hasta ahí y mayor después), así que no es menor. Si la secuencia es no decreciente, quitar el último deja el prefijo más pequeño posible.

🔬 **El detalle.** Con la pila monótona, «quitar el primer descenso» se hace para todos los `k` a la vez en `Θ(n)`; y hay que quitar los ceros a la izquierda y devolver `"0"` si no queda nada.

**01 → 12.** Da el contraejemplo más pequeño que encuentres para «primero el encargo de más peso» en el taller. 🔴

⏱️ **30 segundos.** Dos encargos: `(1, 1)` y `(3, 2)`. El de más peso primero cuesta `2 · 3 + 1 · 4 = 10`; al revés, `1 · 1 + 2 · 4 = 9`.

🗣️ **2 minutos.** La razón de `(1, 1)` es 1 y la de `(3, 2)` es 1,5: Smith pone primero el de razón menor, que es el de menos peso. El peso solo no mira cuánto retrasa un encargo largo a los demás.

🔬 **El detalle.** Se encuentra con una fuerza bruta sobre todos los pares con duraciones y pesos de 1 a 4: es el procedimiento de `11/04`.

**01 → 13.** Tu voraz da WA en el caso 23 y pasa todos los ejemplos. Describe el procedimiento para decidir si el fallo es del voraz o del código. 🔴

⏱️ **30 segundos.** Escribir la fuerza bruta (exhaustiva sobre `n` pequeño), un generador aleatorio y comparar con el voraz. Si aparece una diferencia, mirar a mano ese caso: si la fuerza bruta tiene razón, el fallo es del voraz (la regla); si no, del código.

🗣️ **2 minutos.** Con el caso mínimo delante, se traza el voraz: si hace lo que la regla dice y el resultado es peor que el óptimo, la regla es falsa y hay que cambiar de técnica. Si no hace lo que la regla dice (un desempate, un `<=` por `<`, un desbordamiento), el fallo es de implementación.

🔬 **El detalle.** El arnés es el de `01/05`; generar entradas muy pequeñas (`n ≤ 6`, valores ≤ 5) encuentra antes los contraejemplos y los deja legibles.

**01 → Problema: Paquetes en la furgoneta.**

- **Pista 2 — patrón:** **voraz por el más ligero**, con argumento de intercambio.
- **Pista 3 — diseño:** ordena por peso y mete mientras quepa. Intercambio: si una óptima lleva un paquete más pesado y deja uno más ligero, cambiarlos no aumenta el peso ni cambia la cuenta. Suma en 64 bits.

**01 → Problema: Retraso máximo mínimo.**

- **Pista 2 — patrón:** **plazo más próximo primero** (EDD), con intercambio de vecinos.
- **Pista 3 — diseño:** ordena por plazo y calcula los fines acumulados; la respuesta es el máximo de `fin − plazo` (o 0). Intercambio: dos consecutivos con plazos invertidos se pueden cambiar sin aumentar el mayor retraso de los dos. Todo en 64 bits.

**01 → Problema: Dos máquinas en cadena.**

- **Pista 2 — patrón:** **regla de Johnson**, con argumento de intercambio.
- **Pista 3 — diseño:** primero las piezas con `a ≤ b`, ordenadas por `a` creciente; después las de `a > b`, ordenadas por `b` decreciente. Simula: `finA += a`; `finB = max(finB, finA) + b`. La prueba es de intercambio sobre `min(aₓ, b_y) ≤ min(a_y, bₓ)`.

**01 → Problema: Luck Balance.**

- **Pista 2 — patrón:** **elección voraz tras ordenar**.
- **Pista 3 — diseño:** suma la suerte de todos los no importantes; de los importantes, ordena por suerte y pierde (suma) los `k` mayores; gana (resta) el resto.

**01 → Problema: TieRopes.**

- **Pista 2 — patrón:** **el voraz se adelanta**: cerrar una cuerda en cuanto alcanza `K`.
- **Pista 3 — diseño:** recorre sumando longitudes; cuando la suma llega a `K`, cuenta una cuerda y reinicia. Medida: cuerdas cerradas tras procesar `i` trozos; el voraz nunca lleva menos y su trozo abierto nunca es más largo.

**01 → Problema: Greedy Florist.**

- **Pista 2 — patrón:** **intercambio**: las flores caras deben comprarse cuando el multiplicador es menor.
- **Pista 3 — diseño:** ordena los precios de mayor a menor; la flor `i` (desde 0) la compra el amigo `i mod k` con multiplicador `⌊i / k⌋ + 1`. Intercambiar una cara con multiplicador alto por una barata con multiplicador bajo nunca empeora.

**01 → Problema: Jump Game II.**

- **Pista 2 — patrón:** **el voraz se adelanta** por capas (como un BFS sobre índices).
- **Pista 3 — diseño:** mantén el final de la capa actual y el alcance máximo de la siguiente; al llegar al final de la capa, salta (cuenta uno) y la nueva capa acaba en ese alcance.

**01 → Problema: Gas Station.**

- **Pista 2 — patrón:** **elección voraz con prueba**: si desde `i` te quedas sin gasolina en `j`, ningún inicio entre `i` y `j` sirve.
- **Pista 3 — diseño:** si la suma total de `gas − cost` es negativa, `−1`; si no, recorre acumulando, y cuando el acumulado se hace negativo, el candidato pasa a `j + 1` y el acumulado vuelve a 0.

**01 → Problema: Two City Scheduling.**

- **Pista 2 — patrón:** **intercambio**: ordenar por la diferencia `costA − costB`.
- **Pista 3 — diseño:** los `n` con menor `costA − costB` van a A y el resto a B. Intercambiar una persona de A con una de B solo mejora si sus diferencias están en el orden contrario.

**01 → Problema: Partition Labels.**

- **Pista 2 — patrón:** **el voraz se adelanta**: cortar en cuanto el trozo contiene todas las apariciones de sus letras.
- **Pista 3 — diseño:** precalcula la última aparición de cada letra; recorre ampliando el final del trozo con la última aparición de cada letra vista; cuando el índice alcanza ese final, corta.

**01 → Problema: Queue Reconstruction by Height.**

- **Pista 2 — patrón:** **ordenar con la clave correcta e insertar**.
- **Pista 3 — diseño:** ordena por altura decreciente y, a igual altura, por `k` creciente; inserta cada persona en la posición `k` de la lista resultado. Los más bajos no afectan a la cuenta de los más altos.

**01 → Problema: Reading Books.**

- **Pista 2 — patrón:** **cota inferior estructural** y su construcción.
- **Pista 3 — diseño:** la respuesta es `max(suma, 2 · máximo)`: si el libro más largo dura más que todos los demás juntos, alguien espera; si no, se puede entrelazar sin esperas.

**01 → Problema: Candy.**

- **Pista 2 — patrón:** **dos pasadas voraces**, una por cada vecino.
- **Pista 3 — diseño:** de izquierda a derecha, `c[i] = c[i − 1] + 1` si la nota sube, si no 1; de derecha a izquierda, `c[i] = max(c[i], c[i + 1] + 1)` si la nota sube hacia la izquierda. La suma es el mínimo.

**01 → Problema: Course Schedule III.**

- **Pista 2 — patrón:** **plazos con arrepentimiento**: un montículo de máximos con las duraciones tomadas.
- **Pista 3 — diseño:** ordena por plazo; añade cada curso; si el tiempo acumulado supera su plazo, quita el curso más largo tomado. La cuenta final del montículo es la respuesta.

---

# 02 — Intervalos

**02 → 1.** ¿Por qué orden se resuelve cada uno de los cuatro problemas del capítulo? 🟢

⏱️ **30 segundos.** Máximo de disjuntos y mínimo de puntos: por final. Mezcla: por inicio. Mínimo de salas: inicios y finales ordenados por separado, con un barrido.

🗣️ **2 minutos.** Los dos primeros eligen primero el intervalo más restrictivo, el que termina antes. La mezcla necesita ver seguidos los que pueden unirse, y eso lo da el inicio. Las salas solo necesitan contar cuántos hay en curso en cada evento.

🔬 **El detalle.** Las cuatro son `Θ(n log n)` por la ordenación; el recorrido es lineal en todas.

**02 → 2.** ¿Qué es la profundidad de un conjunto de intervalos y qué tiene que ver con las salas? 🟢

⏱️ **30 segundos.** El máximo número de intervalos que contienen un mismo instante. Es exactamente el mínimo número de salas.

🗣️ **2 minutos.** Los intervalos que contienen el instante de máxima profundidad se solapan todos entre sí y necesitan salas distintas: es una cota inferior. El barrido por inicio con reutilización de salas libres la alcanza.

🔬 **El detalle.** Es un teorema minimax en pequeño: el mínimo de salas (colores de un grafo de intervalos) es igual al máximo de una clique; los grafos de intervalos son perfectos.

**02 → 3.** ¿Qué cambia en cada plantilla si los intervalos son cerrados en lugar de semiabiertos? 🟢

⏱️ **30 segundos.** La comparación de la frontera: en selección, `s >= fin` pasa a `s > fin`; en salas, `ends[j] <= s` pasa a `<`; en la mezcla, unir con `s <= fin` es lo natural en cerrados.

🗣️ **2 minutos.** Con semiabiertos, `[1,4)` y `[4,6)` no se tocan; con cerrados, comparten el 4. En cubrimiento con puntos la plantilla ya está escrita para cerrados (`s > last`). La regla es leer el enunciado: «de 9 a 10» puede ser cualquiera de las dos.

🔬 **El detalle.** Un truco para unificar: con enteros, el cerrado `[s, f]` es el semiabierto `[s, f + 1)`.

**02 → 4.** ¿En qué se diferencian la selección de actividades y el cubrimiento con puntos, si se ordenan igual? 🟡

⏱️ **30 segundos.** Las dos ordenan por final y recorren igual; difieren en la frontera (`>=` frente a `>`) y en lo que cuentan: intervalos elegidos o puntos colocados. En la recta, sus respuestas coinciden.

🗣️ **2 minutos.** La selección elige intervalos que no se tocan; el cubrimiento coloca un punto en el final del primer intervalo sin pinchar. Los intervalos que abren punto nuevo son disjuntos dos a dos, y por eso el número de puntos es a la vez cota superior del máximo de disjuntos y alcanzado.

🔬 **El detalle.** La coincidencia es un teorema de dualidad (König para grafos de intervalos); en el plano, con rectángulos, ya no se cumple.

**02 → 5.** ¿Por qué la mezcla se ordena por inicio y no por final? Da el contraejemplo. 🟡

⏱️ **30 segundos.** Porque para unir hay que saber si un intervalo empieza antes de que el bloque acabe, y eso solo es fiable si los que pueden unirse aparecen seguidos. Por final: `[1,10] [2,3] [4,5]` se procesa como `[2,3]`, `[4,5]`, `[1,10]`, y el `[2,3]` queda como bloque separado aunque `[1,10]` lo contenga.

🗣️ **2 minutos.** Con el orden por inicio, el invariante es que ningún intervalo posterior puede tocar un bloque ya cerrado, porque empieza después de su inicio y el bloque se cerró al ver un inicio mayor que su final. Por final, un intervalo largo que empieza muy pronto aparece tarde y tendría que unirse a bloques ya cerrados.

🔬 **El detalle.** Se podría arreglar por final mezclando hacia atrás con una pila, pero es reinventar el orden por inicio con más código.

**02 → 6.** ¿Por qué en la mezcla el final del bloque se actualiza con `max`? 🟡

⏱️ **30 segundos.** Porque un intervalo contenido en el bloque tiene el final menor que el bloque, y asignarle su final lo encogería: `[9,12]` y después `[10,11]` darían `[9,11]`.

🗣️ **2 minutos.** El bloque es la unión de los intervalos vistos que lo tocan; su final es el máximo de sus finales, no el del último procesado. Es el error más frecuente de la mezcla, y el ejemplo con un intervalo contenido lo delata.

🔬 **El detalle.** El inicio no necesita `min` porque el orden por inicio garantiza que el primero del bloque es el de menor inicio.

**02 → 7.** Compara cómo ordenas intervalos por su final en C++, Java y Python, y qué trampa tiene cada uno. 🟡

⏱️ **30 segundos.** C++: `std::sort` con una lambda que compare `.second` (orden estricto). Java: `Arrays.sort` con `Integer.compare(p[1], q[1])` o `Comparator.comparingInt`, nunca la resta. Python: `sorted(intervals, key=lambda iv: iv[1])`.

🗣️ **2 minutos.** En C++, un comparador con `<=` rompe el requisito de orden estricto débil y `std::sort` puede salirse del rango. En Java, `p[1] − q[1]` desborda con valores de signo opuesto cercanos a los límites, y el comparador deja de ser un orden. En Python, la clave es lo más claro; ordenar tuplas sin clave ordena por inicio, no por final.

🔬 **El detalle.** En Java, ordenar `int[][]` usa un *mergesort* estable de objetos (TimSort); con `n = 2·10⁵` va bien, pero es más lento que ordenar primitivos: si solo hace falta el orden de los finales, se pueden empaquetar los dos valores en un `long`.

**02 → 8.** Demuestra que el mínimo de puntos que pinchan unos intervalos en la recta es igual al máximo de intervalos disjuntos. 🟠

⏱️ **30 segundos.** Los intervalos que hacen que el voraz coloque un punto nuevo son disjuntos dos a dos (cada uno empieza después del punto anterior, que es el final del anterior). Así que el número de puntos no supera el máximo de disjuntos; y nunca puede ser menor, porque intervalos disjuntos necesitan puntos distintos.

🗣️ **2 minutos.** Cota inferior: `k` intervalos disjuntos necesitan `k` puntos, porque un punto está en a lo sumo uno de ellos. Cota superior: el voraz usa tantos puntos como intervalos «abridores», que forman un conjunto disjunto, luego como mucho el máximo. Las dos dan la igualdad, y de paso demuestran que el voraz es óptimo para los dos problemas.

🔬 **El detalle.** Es un caso de dualidad de programación lineal donde la matriz es de intervalos (unos consecutivos), que es totalmente unimodular: los óptimos enteros coinciden.

**02 → 9.** Demuestra que el mínimo de salas es igual a la profundidad. 🟠

⏱️ **30 segundos.** Cota inferior: las reuniones que contienen el instante de máxima profundidad `d` necesitan `d` salas distintas. Construcción: asignando por inicio a una sala libre, solo se abre una sala nueva cuando todas las abiertas tienen una reunión en curso, así que nunca hay más de `d`.

🗣️ **2 minutos.** Si al llegar la reunión `x` hay que abrir la sala `k + 1`, las `k` abiertas tienen reuniones en curso en el inicio de `x`; con `x`, son `k + 1` reuniones que contienen ese instante: `k + 1 ≤ d`. Luego el voraz usa como mucho `d` salas, y la cota inferior dice que no se puede con menos.

🔬 **El detalle.** Kleinberg y Tardos, §4.1, *interval partitioning*. El voraz de los dos punteros calcula `d` sin construir la asignación.

**02 → 10.** ¿Por qué el voraz por final falla si los intervalos tienen peso, y qué técnica usas? 🟠

⏱️ **30 segundos.** Porque el voraz cuenta intervalos, no valor: un intervalo largo y valioso puede pesar más que los dos cortos que el voraz elige en su lugar. Se resuelve con DP sobre los intervalos ordenados por final y una búsqueda binaria del último compatible.

🗣️ **2 minutos.** `dp[i] = max(dp[i − 1], peso[i] + dp[p(i)])`, con `p(i)` el último intervalo que termina antes de que empiece el `i`, por binaria: `Θ(n log n)`. Contraejemplo del voraz: `[0,10)` con peso 10 frente a `[0,1)` y `[2,3)` con peso 1.

🔬 **El detalle.** Es el *weighted interval scheduling* de Kleinberg y Tardos, §6.1, y el primer ejemplo de DP del libro; en el corpus, [`12/02`](../12-dp-clasica/02-dp-lineal-y-lis.md).

**02 → 11.** ¿Cuándo usas el montículo de finales para las salas en lugar de los dos punteros? 🟠

⏱️ **30 segundos.** Cuando además de cuántas salas hay que decir **qué sala** recibe cada reunión, o cuando las reuniones llegan en línea por orden de inicio y hay que asignarlas al vuelo.

🗣️ **2 minutos.** El montículo de pares `(final, sala)` de las salas ocupadas da en `O(log n)` la sala que antes se libera; si su final es `≤` el inicio actual, se reutiliza; si no, se abre una nueva. Los dos punteros solo cuentan.

🔬 **El detalle.** El coste es el mismo, `Θ(n log n)`; los dos punteros tienen mejor constante y menos código.

**02 → 12.** Te piden cuántos intervalos quitar para que no se solapen y respondes `n − maxDisjoint`. Demuestra que es correcto. 🔴

⏱️ **30 segundos.** Quitar el mínimo para que no se solapen es lo mismo que conservar el máximo de disjuntos: un conjunto de conservados es válido si y solo si es disjunto, y se maximiza lo que se conserva cuando se minimiza lo que se quita.

🗣️ **2 minutos.** La biyección «conjunto conservado ↔ conjunto quitado» (complementarios) transforma un problema en el otro; los tamaños suman `n`. El óptimo de uno da el del otro, y la selección por final da el máximo de conservados.

🔬 **El detalle.** Atención a la frontera: si el enunciado considera que `[1,2]` y `[2,3]` se solapan, la selección tiene que usar `>` en lugar de `>=`.

**02 → 13.** Tu mínimo de salas da uno más de lo esperado en el caso 7. ¿Qué miras primero? 🔴

⏱️ **30 segundos.** La frontera: si una reunión que termina en `t` y otra que empieza en `t` deben compartir sala, el barrido tiene que liberar antes de ocupar (`ends[j] <= s`). Con `<`, se cuenta una sala de más en cada contacto.

🗣️ **2 minutos.** El enunciado decide si los intervalos son cerrados o semiabiertos. Un caso mínimo para comprobarlo: `[1,2] [2,3]`: ¿1 sala o 2? Si la respuesta esperada es 1 y das 2, la condición está al revés. Después miro que inicios y finales estén ordenados por separado y que los finales no se hayan desplazado con la limpieza.

🔬 **El detalle.** En el barrido por eventos de [`04/04`](../04-secuencias/04-compresion-y-barrido.md), la misma decisión es el orden de desempate entre una salida y una entrada en el mismo instante.

**02 → Problema: Sesiones del congreso.**

- **Pista 2 — patrón:** **selección de actividades** por final.
- **Pista 3 — diseño:** ordena por final y elige cada sesión que empiece en o después del final de la última elegida (son semiabiertas). Intercambio: la que termina antes nunca es peor primera elección.

**02 → Problema: Andenes de la estación.**

- **Pista 2 — patrón:** **mínimo de salas** con intervalos **cerrados**.
- **Pista 3 — diseño:** ordena llegadas y salidas por separado; al procesar una llegada, libera solo los andenes cuya salida es **estrictamente** menor que la llegada (`<`, porque comparten el instante). La respuesta es el máximo de ocupados.

**02 → Problema: Calendario compacto.**

- **Pista 2 — patrón:** **mezcla** y después **prefijos con búsqueda binaria** sobre los bloques.
- **Pista 3 — diseño:** mezcla los ocupados en bloques disjuntos ordenados; calcula prefijos de días ocupados. Para `[a, b]`, la respuesta es `ocupados(≤ b) − ocupados(≤ a − 1)`, donde `ocupados(≤ x)` = prefijo de los bloques que acaban antes de `x` más la parte del bloque que contiene `x`, encontrado por binaria.

**02 → Problema: Interval List Intersections.**

- **Pista 2 — patrón:** **dos punteros** sobre dos listas ordenadas y disjuntas.
- **Pista 3 — diseño:** la intersección de los dos actuales es `[max(inicios), min(finales)]` si no es vacía; avanza el puntero del que termina antes, porque ya no puede cortar a nada más.

**02 → Problema: Remove Covered Intervals.**

- **Pista 2 — patrón:** **orden por inicio con desempate** por final descendente.
- **Pista 3 — diseño:** ordena por inicio creciente y, a igual inicio, final decreciente; recorre llevando el mayor final visto: un intervalo con final `≤` ese máximo está cubierto.

**02 → Problema: Car Pooling.**

- **Pista 2 — patrón:** **profundidad con pesos** por barrido de eventos.
- **Pista 3 — diseño:** eventos `(desde, +pasajeros)` y `(hasta, −pasajeros)`; en el mismo punto, primero las bajadas; si el acumulado supera la capacidad, falso. Con posiciones ≤ 1000, un arreglo de diferencias basta.

**02 → Problema: My Calendar I.**

- **Pista 2 — patrón:** **mapa ordenado** de reservas.
- **Pista 3 — diseño:** guarda las reservas en un `TreeMap` o `std::map` por inicio; para la nueva `[s, e)`, la reserva anterior (`floor`) tiene que acabar en `≤ s` y la siguiente (`ceiling`) empezar en `≥ e`.

**02 → Problema: Video Stitching.**

- **Pista 2 — patrón:** **cubrir un tramo con el mínimo de intervalos**, el voraz se adelanta.
- **Pista 3 — diseño:** con lo cubierto hasta `c`, de los clips que empiezan en `≤ c` elige el de final máximo; cuenta uno y `c` pasa a ese final; si no avanza, `-1`. Es Jump Game II con intervalos.

**02 → Problema: Hackerland Radio Transmitters.**

- **Pista 2 — patrón:** **cubrimiento con puntos**: cada casa necesita una antena a distancia `≤ k`.
- **Pista 3 — diseño:** ordena las casas; para la primera sin cubrir en `x`, pon la antena en la casa más lejana `≤ x + k`; esa antena cubre hasta `posición + k`; salta las cubiertas y repite.

**02 → Problema: Maximum Number of Events That Can Be Attended.**

- **Pista 2 — patrón:** **plazos con montículo**: cada día, el evento disponible que acaba antes.
- **Pista 3 — diseño:** ordena por inicio; recorre los días añadiendo al montículo de finales los eventos que empiezan ese día; quita los vencidos; si queda alguno, asiste al de final mínimo. Intercambio: el que vence antes es el más urgente.

**02 → Problema: Room Allocation.**

- **Pista 2 — patrón:** **mínimo de salas con asignación**: montículo de `(salida, habitación)`.
- **Pista 3 — diseño:** ordena por llegada guardando el índice original; si la habitación que antes se libera tiene salida `<` llegada, reutilízala; si no, abre una nueva. Guarda la habitación de cada cliente en su índice original.

**02 → Problema: Movie Festival II.**

- **Pista 2 — patrón:** **selección con `k` personas**: por final, y cada película a quien la pueda ver y haya acabado más tarde.
- **Pista 3 — diseño:** ordena por final; mantén en un `multiset` los instantes en que cada persona queda libre; para cada película, busca la persona libre con el mayor instante `≤` inicio (*upper bound* menos uno); si existe, asígnala y actualiza su instante.

**02 → Problema: Minimum Number of Taps to Open to Water a Garden.**

- **Pista 2 — patrón:** **cubrir un tramo con intervalos**, tras convertir cada grifo en `[i − r, i + r]`.
- **Pista 3 — diseño:** para cada posición izquierda, el mayor alcance; después, el voraz de Video Stitching (o de Jump Game II) desde 0 hasta `n`; `-1` si se queda sin avanzar.

**02 → Problema: Set Intersection Size At Least Two.**

- **Pista 2 — patrón:** **cubrimiento con puntos** cuando cada intervalo necesita dos.
- **Pista 3 — diseño:** ordena por final creciente y, a igual final, inicio decreciente; lleva los dos últimos puntos elegidos `a < b`; si el intervalo contiene los dos, nada; si contiene solo `b`, añade su final; si ninguno, añade sus dos últimos enteros.

---

# 03 — Plazos, Huffman, mochila fraccionaria y monedas

**03 → 1.** ¿Qué une Huffman en cada paso, y cómo se calcula el coste total del código? 🟢

⏱️ **30 segundos.** Los dos nodos de **menor** frecuencia. El coste total es la suma de los nodos internos creados, que es igual a `Σ frecuencia · profundidad`.

🗣️ **2 minutos.** Cada unión crea un nodo cuyo valor es la suma de los dos; un símbolo contribuye con su frecuencia a cada nodo interno que lo contiene, es decir, una vez por nivel. Con `abracadabra`: `2 + 4 + 6 + 11 = 23` bits.

🔬 **El detalle.** Con las frecuencias ordenadas, dos colas (las hojas y los nodos creados, que salen ya ordenados) dan `Θ(n)` sin montículo.

**03 → 2.** ¿Qué es un sistema de monedas canónico? Da uno que lo sea y uno que no. 🟢

⏱️ **30 segundos.** Uno en el que el voraz de la moneda mayor da siempre el mínimo número de monedas. `{1, 5, 10, 25}` lo es; `{1, 3, 4}` no, porque con 6 da `4 + 1 + 1` en lugar de `3 + 3`.

🗣️ **2 minutos.** Casi todos los sistemas monetarios reales son canónicos, y por eso la intuición «el cambio es voraz» está tan extendida. Un sistema inventado en un enunciado no tiene por qué serlo.

🔬 **El detalle.** El euro (`1, 2, 5, 10, 20, 50, 100, 200` céntimos) es canónico; `{1, 5, 12}` falla en 15.

**03 → 3.** ¿Cuándo es factible un conjunto de tareas unitarias con plazos? 🟢

⏱️ **30 segundos.** Si, ordenadas por plazo, la `k`-ésima tarea tiene plazo `≥ k`: se pueden hacer en ese orden, una por instante, todas a tiempo.

🗣️ **2 minutos.** Si alguna tiene plazo `< k`, hay `k` tareas con plazo `≤ k − 1` que necesitan `k` instantes antes de `k`: imposible. Si todas cumplen, el orden por plazo es una planificación válida.

🔬 **El detalle.** Con cupo de `c` tareas por día, la condición pasa a `plazo ≥ ⌈k / c⌉`: la generalización del problema propio del capítulo.

**03 → 4.** ¿Por qué la mochila fraccionaria es voraz y la 0/1 no? Da el contraejemplo de la 0/1. 🟡

⏱️ **30 segundos.** Porque en la fraccionaria se puede partir el último material y el intercambio por razón siempre mejora; en la 0/1 no. Con `W = 10` y `(6, 9)`, `(5, 7)`, `(5, 7)`: el voraz toma el de razón 1,5 y se queda en 9; los dos de 7 dan 14.

🗣️ **2 minutos.** El argumento de intercambio de la fraccionaria cambia una cantidad `ε` de un material por la misma de otro mejor; con objetos enteros, ese cambio no siempre cabe, y el hueco que deja un objeto grande no se aprovecha.

🔬 **El detalle.** La 0/1 es NP-completa (débilmente: DP en `O(n · W)`, [`12/03`](../12-dp-clasica/03-mochilas.md)); la fraccionaria es un problema de programación lineal, y el voraz es su solución por el vértice.

**03 → 5.** ¿Qué invariante mantiene el montículo en la planificación con plazos? 🟡

⏱️ **30 segundos.** Tras procesar las tareas con plazo `≤ d`, el montículo contiene las de mayor beneficio entre ellas que forman un conjunto factible, como mucho `d`.

🗣️ **2 minutos.** Al añadir una tarea de plazo `d`, si el montículo pasa de `d`, el conjunto no es factible; quitar la de menor beneficio lo devuelve a factible y deja el mejor posible. Como los plazos se procesan en orden, las condiciones de plazos menores siguen cumpliéndose.

🔬 **El detalle.** Es un voraz «con arrepentimiento»: decide tomar y corrige después. La prueba formal es la de la matroide de `11/04`.

**03 → 6.** ¿Por qué el coste de Huffman es la suma de los nodos internos? 🟡

⏱️ **30 segundos.** Porque cada símbolo suma su frecuencia en cada unión que lo contiene, y el número de uniones que lo contienen es su profundidad en el árbol.

🗣️ **2 minutos.** `Σ nodos internos = Σ_símbolo frecuencia · (número de ancestros internos) = Σ frecuencia · profundidad`, que es la longitud total del texto codificado.

🔬 **El detalle.** Por eso «unir montones pagando la suma» es Huffman aunque no hable de códigos.

**03 → 7.** Compara cómo escribes el montículo de mínimos de la planificación con plazos en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `std::priority_queue<long long, std::vector<long long>, std::greater<>>`. Java: `PriorityQueue<Long>`, que ya es de mínimos. Python: `heapq` sobre una lista, que también es de mínimos.

🗣️ **2 minutos.** El error típico de C++ es olvidar el comparador: el `priority_queue` por defecto es de máximos y soltaría la tarea de mayor beneficio. En Java, el *boxing* de `Long` cuesta pero con `2·10⁵` elementos no importa. En Python, `heapq` no tiene clase: se pasan la lista y el elemento a cada función.

🔬 **El detalle.** [`08/01`](../08-heaps-y-union-find/01-monticulo-binario.md) y [`03/05`](../03-biblioteca-estandar/05-equivalencias-entre-lenguajes.md) tienen la tabla completa de montículos por lenguaje.

**03 → 8.** Esboza la prueba de optimalidad de Huffman: las dos partes y qué demuestra cada una. 🟠

⏱️ **30 segundos.** Primero, elección voraz: en algún óptimo, los dos menos frecuentes son hermanos al fondo. Segundo, subestructura: uniendo esos dos en un símbolo, un óptimo del problema reducido da un óptimo del original, porque el coste solo cambia en la suma de los dos.

🗣️ **2 minutos.** Lo primero, por intercambio: en un árbol óptimo, el nivel más profundo tiene dos hermanos; cambiarlos por los dos menos frecuentes no aumenta el coste (los frecuentes suben, los raros bajan). Lo segundo: si `T'` es óptimo para las frecuencias con `x` e `y` unidos en `z`, abrir `z` en dos hojas suma exactamente `f(x) + f(y)` al coste, y cualquier árbol para el original con `x`, `y` hermanos se obtiene así.

🔬 **El detalle.** CLRS, §16.3, lemas 16.2 y 16.3. La inducción sobre `n` cierra la prueba.

**03 → 9.** ¿Qué dice el teorema de Kozen y Zaks y cómo lo usas para decidir si el voraz de monedas sirve? 🟠

⏱️ **30 segundos.** Que si un sistema no es canónico, su menor contraejemplo es menor que la suma de las dos monedas mayores. Así, basta comparar el voraz con la DP en las cantidades hasta ahí.

🗣️ **2 minutos.** Con `{1, 5, 12}`, se comprueba hasta `5 + 12 = 17` y sale 15. Con el euro, hasta `100 + 200 = 300`, y no sale nada: es canónico, y el voraz sirve para cualquier cantidad, aunque sea `10¹⁸`.

🔬 **El detalle.** Hay un algoritmo de Pearson (1994) que decide la canonicidad en `O(k³)` sin depender del valor de las monedas.

**03 → 10.** ¿Por qué en la planificación con plazos conviene soltar la tarea de menor beneficio y no la última añadida? 🟠

⏱️ **30 segundos.** Porque el objetivo es el beneficio total, y lo que sobra es una tarea: la que menos aporta es la que hay que perder. La última añadida puede ser la más valiosa.

🗣️ **2 minutos.** Todas las del montículo tienen plazo `≤ d`, así que cualquiera puede salir sin romper la factibilidad de las demás; entre ellas, quitar la mínima deja la máxima suma. Quitar la última sería el voraz «primero llegado, primero servido», que pierde con una tarea muy valiosa al final.

🔬 **El detalle.** En Course Schedule III, donde se maximiza el **número** de cursos con duraciones distintas, lo que se suelta es el más **largo**: libera más tiempo.

**03 → 11.** ¿Qué cambia si las tareas tienen duraciones distintas, y qué voraz sigue funcionando para maximizar su número? 🔴

⏱️ **30 segundos.** Con duraciones distintas y beneficios, el problema es NP-difícil (contiene a la mochila). Para maximizar el **número** de tareas, sigue funcionando un voraz: por plazo, y si el tiempo acumulado supera el plazo, soltar la más larga.

🗣️ **2 minutos.** Con duraciones, la factibilidad ya no es «la `k`-ésima tiene plazo `≥ k`» sino «el tiempo acumulado no pasa del plazo». Soltar la más larga libera más tiempo y conserva la cuenta. Con beneficios, ninguna regla local sirve: DP sobre el tiempo si es pequeño.

🔬 **El detalle.** Es el algoritmo de Moore y Hodgson (1968) para minimizar el número de tareas tardías.

**03 → 12.** Demuestra que `{1, 5, 10, 25}` es canónico. 🔴

⏱️ **30 segundos.** En un óptimo no hay cinco monedas de 1, ni dos de 5, ni tres de 10, ni dos de 10 con una de 5: cada caso se cambia por menos monedas. Con eso, lo pagado con monedas menores que 25 es como mucho 24, y el voraz coincide con el óptimo nivel a nivel.

🗣️ **2 minutos.** Sin esas configuraciones, el máximo pagable con 1, 5 y 10 es `4 + 5 + 10 + 10 = 24` (cuatro de 1, una de 5, dos de 10 sin otra de 5) o `4 + 10 + 10 = 24`. Luego el número de monedas de 25 del óptimo es `⌊x / 25⌋`, como el del voraz. Repitiendo con el resto y las monedas menores, coinciden todas.

🔬 **El detalle.** Por Kozen y Zaks también basta comprobar con la DP las cantidades hasta `10 + 25 = 35`.

**03 → 13.** Unir montones de piedras **vecinos** pagando la suma: ¿sirve Huffman? Da un contraejemplo o una prueba. 🔴

⏱️ **30 segundos.** No: Huffman une los dos menores estén donde estén, y con vecinos no siempre se puede. Con `[1, 10, 1]`, Huffman uniría los dos 1 (coste 14), pero no son vecinos; lo mínimo uniendo vecinos es 23.

🗣️ **2 minutos.** Con la restricción de vecindad, el orden de los montones importa y la elección local deja de ser segura. Es la DP de intervalos de [`12/05`](../12-dp-clasica/05-rejillas-e-intervalos.md): `dp[i][j] = min_k (dp[i][k] + dp[k+1][j]) + suma(i..j)`, `O(n³)`.

🔬 **El detalle.** Existe un algoritmo `O(n log n)` para esta variante (Garsia-Wachs), que no es un voraz simple y casi nunca se pide.

**03 → Problema: Llenar el depósito.**

- **Pista 2 — patrón:** **mochila fraccionaria** al revés: minimizar coste comprando por precio creciente.
- **Pista 3 — diseño:** ordena por precio; compra de cada proveedor `min(stock, lo que falta)`; si se acaban los proveedores sin llegar a `L`, `-1`. Coste en 64 bits: con `L ≤ 10⁹` y precios de `10⁹`, llega a `10¹⁸`, que cabe.

**03 → Problema: Pedidos con plazo y cupo diario.**

- **Pista 2 — patrón:** **plazos con montículo**, con capacidad `c · d` en lugar de `d`.
- **Pista 3 — diseño:** ordena por plazo; añade cada pago al montículo de mínimos; si su tamaño pasa de `c · plazo`, suelta el mínimo. La suma del montículo es la respuesta. Cuidado: `c · plazo` llega a `10¹⁴`, en 64 bits.

**03 → Problema: Mezclar de tres en tres.**

- **Pista 2 — patrón:** **Huffman ternario**: unir siempre los tres menores, tras rellenar con ficheros vacíos.
- **Pista 3 — diseño:** cada mezcla quita dos ficheros, así que se acaba en uno si `(n − 1)` es par; si no, añade un fichero de tamaño 0. Después, montículo de mínimos y unir los tres menores hasta que quede uno, sumando el coste.

**03 → Problema: Jim and the Orders.**

- **Pista 2 — patrón:** **ordenar por la clave correcta** (instante de entrega) con desempate por índice.
- **Pista 3 — diseño:** la entrega de cada pedido es `orden + preparación`; ordena por ese valor y, a igualdad, por número de cliente.

**03 → Problema: Tree: Huffman Decoding.**

- **Pista 2 — patrón:** **recorrer el árbol de Huffman** bit a bit.
- **Pista 3 — diseño:** desde la raíz, `0` va a la izquierda y `1` a la derecha; al llegar a una hoja, emite su carácter y vuelve a la raíz. Lineal en el número de bits.

**03 → Problema: Reduce Array Size to The Half.**

- **Pista 2 — patrón:** **elección voraz por frecuencia**: borrar primero los valores más frecuentes.
- **Pista 3 — diseño:** cuenta frecuencias, ordénalas de mayor a menor y acumula hasta llegar a `n/2`; la respuesta es cuántas has usado. Intercambio: cambiar un valor elegido por uno más frecuente no empeora.

**03 → Problema: Minimum Deletions to Make Character Frequencies Unique.**

- **Pista 2 — patrón:** **voraz sobre las frecuencias ordenadas** de mayor a menor.
- **Pista 3 — diseño:** recorre las frecuencias de mayor a menor manteniendo el máximo permitido (uno menos que la anterior asignada); cada una baja a `min(frecuencia, permitido)` (o a 0); suma lo borrado.

**03 → Problema: Minimum Number of Coins to be Added.**

- **Pista 2 — patrón:** **alcance de sumas**: si se forma todo `[1, r]`, una moneda `c ≤ r + 1` amplía a `[1, r + c]`.
- **Pista 3 — diseño:** ordena; recorre con `r = 0`; si la siguiente moneda es `≤ r + 1`, úsala; si no, añade la moneda `r + 1` (la que más amplía) y cuenta. Termina cuando `r ≥ target`.

**03 → Problema: Furthest Building You Can Reach.**

- **Pista 2 — patrón:** **voraz con arrepentimiento**: las escaleras para las subidas más grandes.
- **Pista 3 — diseño:** mantén un montículo de mínimos con las subidas cubiertas por escalera; si hay más subidas que escaleras, la menor del montículo pasa a ladrillos; si los ladrillos se acaban, has llegado al máximo.

**03 → Problema: Maximum Subsequence Score.**

- **Pista 2 — patrón:** **ordenar por el mínimo y montículo de los `k` mejores**.
- **Pista 3 — diseño:** ordena los pares por `nums2` decreciente; recorre manteniendo un montículo de mínimos con los `k` mayores `nums1` vistos y su suma; con el actual como mínimo de `nums2`, el candidato es `suma · nums2[i]` cuando hay `k`.

**03 → Problema: Patching Array.**

- **Pista 2 — patrón:** **alcance de sumas**, el mismo de Minimum Number of Coins to be Added.
- **Pista 3 — diseño:** con `[1, r)` alcanzable, si el siguiente número es `≤ r`, amplía a `[1, r + num)`; si no, añade `r` (parche) y amplía a `[1, 2r)`. Cuenta parches hasta que `r > n`. Usa 64 bits.

**03 → Problema: Maximum Performance of a Team.**

- **Pista 2 — patrón:** **ordenar por eficiencia y montículo de velocidades**.
- **Pista 3 — diseño:** ordena por eficiencia decreciente; recorre manteniendo las `k` mayores velocidades en un montículo de mínimos y su suma; con el actual como eficiencia mínima, el candidato es `suma · eficiencia`. El módulo se aplica solo al final.

---

# 04 — Matroides y cómo romper un voraz

**04 → 1.** ¿Qué dos propiedades definen una matroide? 🟢

⏱️ **30 segundos.** Ser hereditaria —todo subconjunto de un independiente es independiente— y cumplir el intercambio —si `A` y `B` son independientes y `|A| < |B|`, algún elemento de `B` se puede añadir a `A` sin perder la independencia—.

🗣️ **2 minutos.** La primera dice que quitar elementos nunca rompe la factibilidad. La segunda es la que hace funcionar al voraz: un independiente pequeño siempre se puede ampliar con lo que tiene uno mayor.

🔬 **El detalle.** De las dos sale que todas las bases (independientes maximales) tienen el mismo tamaño, el **rango** de la matroide.

**04 → 2.** ¿Qué dice el teorema de Rado-Edmonds? 🟢

⏱️ **30 segundos.** Que, en una familia hereditaria, el voraz por peso decreciente da un independiente de peso máximo para **toda** función de pesos no negativos si y solo si la familia es una matroide.

🗣️ **2 minutos.** La ida da corrección gratis: si reconoces una matroide, no hace falta prueba. La vuelta explica los fracasos: si la familia no es matroide, existen pesos con los que el voraz falla.

🔬 **El detalle.** El teorema es de Rado (1957) y Edmonds (1971). CLRS, §16.4, prueba la ida.

**04 → 3.** ¿Qué pasos tiene el método para buscar un contraejemplo a un voraz? 🟢

⏱️ **30 segundos.** Fuerza bruta correcta, generador de entradas pequeñas al azar, comparación con el voraz, minimización de la primera diferencia y lectura del caso mínimo.

🗣️ **2 minutos.** Entradas con `n ≤ 8` y valores pequeños; muchas, de `10⁴` a `10⁶`. Al aparecer una diferencia, se quitan elementos y se bajan valores mientras siga fallando. El caso mínimo suele señalar la hipótesis que falta.

🔬 **El detalle.** Es el *stress test* de `01/05` con el voraz como solución rápida. Fijar la semilla hace reproducible el caso.

**04 → 4.** ¿Por qué Kruskal es un voraz sobre una matroide, y cuál? 🟡

⏱️ **30 segundos.** Porque recorre las aristas por peso y añade cada una si no cierra un ciclo, que es el voraz genérico sobre la **matroide gráfica**: los independientes son los bosques.

🗣️ **2 minutos.** Kruskal busca el de peso **mínimo**: con pesos `M − w` (o recorriendo de menor a mayor) es el mismo teorema. La consulta de independencia («¿cierra ciclo?») la responde Union-Find en `O(α(n))`.

🔬 **El detalle.** Las bases de la matroide gráfica de un grafo conexo son sus árboles de expansión, todos con `n − 1` aristas.

**04 → 5.** ¿Por qué los conjuntos de intervalos disjuntos no son una matroide? Da los dos conjuntos que rompen el intercambio. 🟡

⏱️ **30 segundos.** Porque falla el intercambio: `A = {[0,10)}` y `B = {[0,5), [5,10)}` son disjuntos por dentro y `|A| < |B|`, pero ninguno de los dos de `B` se puede añadir a `A` sin solaparse.

🗣️ **2 minutos.** Equivalente: hay conjuntos maximales de tamaños distintos (`A` es maximal con 1 elemento, `B` con 2). Por Rado-Edmonds, entonces hay pesos que rompen el voraz por peso: dar a `[0,10)` peso 3 y a los otros 2 cada uno.

🔬 **El detalle.** Por eso los intervalos **con peso** son una DP (`12/02`), y los intervalos **sin peso** se resuelven con un voraz que no es el genérico por peso, sino por final.

**04 → 6.** ¿Por qué conviene generar entradas pequeñas y no grandes para buscar contraejemplos? 🟡

⏱️ **30 segundos.** Porque hay muchas menos entradas pequeñas, así que el patrón que rompe el voraz tiene más probabilidad por caso, y el contraejemplo encontrado se puede leer y entender.

🗣️ **2 minutos.** Con `n = 50` y valores hasta `10⁹`, el espacio es astronómico y el caso que falla tiene mucho ruido; con `n ≤ 8` y valores ≤ 5, en pocos miles de casos se cubre una parte grande del espacio. Además, la fuerza bruta exhaustiva solo es viable con `n` pequeño.

🔬 **El detalle.** El contraejemplo de los intervalos «que menos chocan» es una excepción: necesita 10 elementos, y por eso conviene subir `n` poco a poco si con `n ≤ 8` no aparece nada.

**04 → 7.** Compara cómo escribirías el generador aleatorio del arnés en C++, Java y Python para que sea reproducible. 🟡

⏱️ **30 segundos.** C++: `std::mt19937` con semilla fija y `std::uniform_int_distribution`. Java: `new Random(semilla)` y `nextInt(bound)`. Python: `random.seed(semilla)` y `random.randint(a, b)`.

🗣️ **2 minutos.** La semilla fija hace que el mismo arnés reproduzca el mismo contraejemplo. En C++, `rand() % k` tiene sesgo y un rango pequeño en algunas bibliotecas; `mt19937` no. En Java, `Random` basta para esto (no es criptográfico, no hace falta).

🔬 **El detalle.** Imprimir la semilla de cada iteración (o el índice del caso) permite volver a generar el caso que falló sin guardar todos.

**04 → 8.** ¿Por qué la selección por final es correcta si los intervalos disjuntos no forman una matroide? 🟠

⏱️ **30 segundos.** Porque Rado-Edmonds habla del voraz **por peso** sobre una familia de independientes, y garantiza optimalidad para todos los pesos. La selección por final resuelve solo la versión sin pesos, y su corrección viene de otra prueba (intercambio o «se adelanta»).

🗣️ **2 minutos.** Sin pesos, todos los intervalos valen 1 y el voraz no los recorre «por peso» sino por final, que es un orden que el problema concreto justifica. Con pesos, ese orden deja de servir, y la falta de matroide se nota.

🔬 **El detalle.** Hay estructuras más generales que las matroides (*greedoides*) que explican otros voraces, pero en la práctica basta con la prueba directa.

**04 → 9.** ¿Qué dice la propiedad de intercambio sobre el tamaño de las bases, y por qué importa para reconocer una matroide? 🟠

⏱️ **30 segundos.** Que todas las bases tienen el mismo tamaño. Si en un problema hay dos soluciones maximales de tamaños distintos, no es una matroide.

🗣️ **2 minutos.** Si una base `A` fuera más pequeña que otra `B`, el intercambio permitiría añadir a `A` un elemento de `B`, contra que `A` es maximal. Comprobar con un ejemplo que hay maximales de distinto tamaño es la forma rápida de descartar una matroide.

🔬 **El detalle.** La implicación inversa no vale: que todas las bases tengan el mismo tamaño no basta para ser matroide.

**04 → 10.** Encuentra el contraejemplo mínimo del voraz por razón para la mochila 0/1 y explica qué hipótesis rompe. 🟠

⏱️ **30 segundos.** Con dos objetos: `W = 10`, `(6, 9)` y `(10, 14)`. El voraz toma el de razón 1,5 y el otro ya no cabe (9); el óptimo es 14. Rompe la hipótesis de que se puede partir el último objeto.

🗣️ **2 minutos.** Se encuentra con el arnés y se minimiza quitando objetos. La lectura: el objeto de mejor razón deja un hueco de 4 que no se puede usar; en la fraccionaria se llenaría con 4/5 de otro.

🔬 **El detalle.** Con un solo objeto el voraz siempre acierta, así que dos es el mínimo. El de tres objetos del capítulo, `(6, 9)`, `(5, 7)`, `(5, 7)`, muestra la otra forma típica: dos objetos medianos que juntos llenan la mochila.

**04 → 11.** ¿Qué técnica usas cuando el problema es la intersección de dos matroides, como el emparejamiento bipartito? 🟠

⏱️ **30 segundos.** Algoritmos de caminos aumentantes: en el emparejamiento bipartito, Kuhn o Hopcroft-Karp, o flujo máximo ([`15/05`](../15-grafos-pesos-y-flujos/05-flujo-maximo.md), [`15/06`](../15-grafos-pesos-y-flujos/06-emparejamientos.md)). El voraz deja de servir.

🗣️ **2 minutos.** Un emparejamiento es un conjunto de aristas independiente en dos matroides a la vez (como mucho una arista por vértice de cada lado). La intersección de dos matroides se resuelve en tiempo polinomial con caminos aumentantes; la de tres ya es NP-difícil.

🔬 **El detalle.** El voraz sobre la intersección de `k` matroides da una aproximación de factor `k`, que a veces es lo que se pide.

**04 → 12.** Demuestra que los bosques de un grafo cumplen la propiedad de intercambio. 🔴

⏱️ **30 segundos.** Un bosque con `k` aristas en `n` vértices tiene `n − k` componentes. Si `|A| < |B|`, `A` tiene más componentes que `B`, así que alguna arista de `B` une dos componentes distintas de `A`, y añadirla no cierra ciclo.

🗣️ **2 minutos.** Si todas las aristas de `B` estuvieran dentro de componentes de `A`, cada componente de `B` estaría dentro de una de `A`, y `B` tendría al menos tantas componentes como `A`: `n − |B| ≥ n − |A|`, contra `|A| < |B|`. La herencia es inmediata: quitar aristas a un bosque deja un bosque.

🔬 **El detalle.** CLRS, teorema 16.5. Es la prueba que hace de Kruskal un corolario.

**04 → 13.** Tu arnés no encuentra contraejemplo en un millón de casos con `n ≤ 6`, y el voraz da WA en el juez. ¿Qué cambias en la búsqueda? 🔴

⏱️ **30 segundos.** Subir `n` y la variedad de valores, y cambiar la distribución: algunos voraces solo caen con estructuras concretas (diez intervalos, valores repetidos, extremos iguales). Y revisar que el arnés compara lo mismo que el juez.

🗣️ **2 minutos.** Con `n ≤ 6` no caben contraejemplos que necesitan más elementos. Pruebo `n` hasta 12, valores con muchos empates y casos límite (todos iguales, ceros). Si sigue sin aparecer, el fallo puede ser de implementación con valores grandes (desbordamiento) o de lectura, y el arnés con valores pequeños nunca lo verá.

🔬 **El detalle.** Un segundo arnés con valores grandes y una fuerza bruta en Python (sin desbordamiento) distingue un voraz incorrecto de un voraz bien pensado y mal escrito.

**04 → Problema: ¿Voraz o no?.**

- **Pista 2 — patrón:** **fuerza bruta como oráculo** contra el voraz.
- **Pista 3 — diseño:** el voraz: ordena por razón decreciente con productos cruzados y desempate por índice (orden estable), mete si cabe. El óptimo: las `2ⁿ` máscaras con su peso y valor en 64 bits. Compara.

**04 → Problema: Monedas contadas.**

- **Pista 2 — patrón:** **el voraz falla**: DP de mochila acotada.
- **Pista 3 — diseño:** `dp[s]` = el mínimo de monedas para `s`; para cada tipo y cada una de sus monedas, recorre `s` de mayor a menor (`dp[s] = min(dp[s], dp[s − v] + 1)`). Con `k · cantidad · x ≤ 10⁶` cabe sin trucos.

**04 → Problema: Bosque más pesado.**

- **Pista 2 — patrón:** **voraz sobre la matroide gráfica** (Kruskal por peso decreciente) con Union-Find.
- **Pista 3 — diseño:** ordena las aristas de mayor a menor peso; para cada una con peso positivo, si une dos componentes distintas, súmala y únelas. Las de peso `≤ 0` nunca mejoran. Suma en 64 bits.

**04 → Problema: Best Time to Buy and Sell Stock II.**

- **Pista 2 — patrón:** **el voraz funciona**: sumar cada subida.
- **Pista 3 — diseño:** suma `max(0, precio[i] − precio[i − 1])`. Intercambio: cualquier compraventa larga es la suma de sus subidas diarias, y las bajadas nunca suman.

**04 → Problema: Jump Game.**

- **Pista 2 — patrón:** **el voraz funciona**: el voraz se adelanta con el alcance máximo.
- **Pista 3 — diseño:** recorre manteniendo el índice más lejano alcanzable; si en algún momento el índice actual supera ese alcance, `false`.

**04 → Problema: Coin Change.**

- **Pista 2 — patrón:** **el voraz falla** con sistemas no canónicos: DP de mochila no acotada.
- **Pista 3 — diseño:** `dp[0] = 0`; `dp[s] = 1 + min dp[s − c]` sobre las monedas `c ≤ s`; `-1` si queda infinito.

**04 → Problema: Minimum Cost For Tickets.**

- **Pista 2 — patrón:** **el voraz falla**: DP sobre los días.
- **Pista 3 — diseño:** `dp[d]` = el coste mínimo hasta el día `d`; en un día de viaje, el mínimo de `dp[d − 1] + p1`, `dp[d − 7] + p7` y `dp[d − 30] + p30` (con índices negativos como 0).

**04 → Problema: NumberSolitaire.**

- **Pista 2 — patrón:** **el voraz falla**: DP sobre la casilla.
- **Pista 3 — diseño:** `dp[i] = a[i] + max(dp[i − 1], …, dp[i − 6])` sobre las casillas alcanzables; la respuesta es `dp[n − 1]`.

**04 → Problema: House Robber.**

- **Pista 2 — patrón:** **el voraz falla**: DP lineal.
- **Pista 3 — diseño:** `dp[i] = max(dp[i − 1], dp[i − 2] + a[i])`; dos variables bastan.

**04 → Problema: Minimum Number of Refueling Stops.**

- **Pista 2 — patrón:** **el voraz funciona con arrepentimiento**: montículo de las gasolineras pasadas.
- **Pista 3 — diseño:** avanza con el combustible actual metiendo en un montículo de máximos las gasolineras que alcanzas; cuando no llegas a la siguiente, para (retroactivamente) en la de más combustible del montículo; si está vacío, `-1`.

**04 → Problema: Maximum Profit in Job Scheduling.**

- **Pista 2 — patrón:** **intervalos con peso**: el voraz falla; DP sobre los finales con búsqueda binaria.
- **Pista 3 — diseño:** ordena por final; `dp[i] = max(dp[i − 1], beneficio[i] + dp[p(i)])` con `p(i)` el último trabajo que termina antes de que empiece el `i`, por binaria.

---

# 05 — Simulación

**05 → S1.** ¿Qué dos propiedades necesita un voraz para ser correcto? 🟢

⏱️ **30 segundos.** La elección voraz —alguna óptima contiene la primera elección— y la subestructura óptima —lo que queda es el mismo problema, resuelto de forma óptima dentro de la óptima—.

🗣️ **2 minutos.** Juntas dan una inducción sobre el número de decisiones. La subestructura la comparte con la DP; la elección voraz es lo que permite no probar todas las primeras decisiones.

🔬 **El detalle.** [`11/01`](01-cuando-funciona-un-voraz.md), §2.

**05 → S2.** ¿Qué dos formas de prueba hay, y cuándo encaja cada una? 🟡

⏱️ **30 segundos.** El argumento de intercambio, para problemas de ordenación y selección, y «el voraz se adelanta», para problemas de avance y cobertura.

🗣️ **2 minutos.** El intercambio transforma una óptima en la voraz sin empeorarla; «se adelanta» prueba por inducción que una medida de progreso del voraz nunca va por detrás. Hay una tercera, la cota inferior estructural (salas y profundidad).

🔬 **El detalle.** `11/01`, §4 y §5.

**05 → S3.** ¿Cómo sacas el comparador de un problema de ordenación con la cuenta del intercambio de vecinos? 🟡

⏱️ **30 segundos.** Se toman dos elementos consecutivos, se escribe el coste con un orden y con el otro, y se restan: lo que no depende del orden se cancela, y la desigualdad que queda es el comparador.

🗣️ **2 minutos.** En el taller con pesos, la diferencia es `w_y pₓ − wₓ p_y`, que da la regla de Smith: ordenar por `p/w`. Se compara con productos cruzados, no con divisiones.

🔬 **El detalle.** `11/01`, §4. Hace falta que la relación sea transitiva; con `p/w` lo es.

**05 → S4.** ¿Por qué orden se resuelven la selección, el cubrimiento con puntos, la mezcla y las salas? 🟢

⏱️ **30 segundos.** Selección y cubrimiento con puntos, por final; mezcla, por inicio; salas, con inicios y finales ordenados por separado y un barrido.

🗣️ **2 minutos.** El final elige primero el intervalo más restrictivo; el inicio deja juntos los que se pueden unir; el barrido cuenta la profundidad.

🔬 **El detalle.** `11/02`, §1 y §2.

**05 → S5.** ¿Qué relación hay entre el mínimo de puntos que pinchan unos intervalos y el máximo de disjuntos? 🟡

⏱️ **30 segundos.** En la recta son iguales.

🗣️ **2 minutos.** Los intervalos que obligan al voraz a poner un punto nuevo son disjuntos dos a dos, así que el número de puntos no supera el máximo de disjuntos; y intervalos disjuntos necesitan puntos distintos, así que no puede ser menor.

🔬 **El detalle.** `11/02`, §4 y pregunta 8.

**05 → S6.** ¿Qué es la profundidad y por qué es el número de salas? 🟡

⏱️ **30 segundos.** El máximo número de intervalos que contienen un mismo instante. Es el número de salas porque esos intervalos necesitan salas distintas y el barrido nunca usa más.

🗣️ **2 minutos.** Cota inferior por los intervalos del instante más cargado; construcción asignando por inicio a una sala libre, que solo abre sala nueva cuando todas las abiertas están ocupadas.

🔬 **El detalle.** `11/02`, §6 y pregunta 9.

**05 → S7.** ¿Qué hace el montículo en la planificación con plazos, y qué tarea suelta? 🟢

⏱️ **30 segundos.** Guarda los beneficios de las tareas aceptadas; recorriendo por plazo, cuando hay más tareas que huecos, suelta la de **menor** beneficio.

🗣️ **2 minutos.** Tras procesar los plazos `≤ d`, el montículo tiene las mejores tareas factibles entre ellas. Soltar la mínima conserva la factibilidad y el máximo beneficio.

🔬 **El detalle.** [`11/03`](03-plazos-huffman-y-monedas.md), §3.

**05 → S8.** ¿Qué une Huffman y cuánto cuesta el código resultante? 🟢

⏱️ **30 segundos.** Los dos nodos de menor frecuencia. El coste es la suma de los nodos internos, igual a `Σ frecuencia · profundidad`.

🗣️ **2 minutos.** Con un montículo, `n − 1` uniones en `Θ(n log n)`. Con `abracadabra`, 23 bits frente a los 33 de un código fijo.

🔬 **El detalle.** `11/03`, §4.

**05 → S9.** ¿Por qué la mochila fraccionaria es voraz y la 0/1 no? 🟡

⏱️ **30 segundos.** Porque en la fraccionaria se puede partir el último objeto, y el intercambio por razón siempre mejora; en la 0/1 no se puede, y un objeto de buena razón puede dejar un hueco inútil.

🗣️ **2 minutos.** Contraejemplo mínimo: `W = 10`, `(6, 9)` y `(10, 14)`: el voraz da 9, el óptimo 14. La 0/1 es una DP (`12/03`).

🔬 **El detalle.** `11/03`, §5, y `11/04`, pregunta 10.

**05 → S10.** ¿Cómo sabes si un sistema de monedas es canónico? 🟡

⏱️ **30 segundos.** Comparando el voraz con la DP en todas las cantidades menores que la suma de las dos monedas mayores (Kozen y Zaks): si no hay diferencia ahí, no la hay en ninguna.

🗣️ **2 minutos.** `{1, 3, 4}` falla en 6; `{1, 5, 12}`, en 15; el euro no falla hasta 300 y es canónico.

🔬 **El detalle.** `11/03`, §6.

**05 → S11.** ¿Qué dice el teorema de Rado-Edmonds? 🟡

⏱️ **30 segundos.** Que en una familia hereditaria, el voraz por peso decreciente es óptimo para todos los pesos si y solo si la familia es una matroide.

🗣️ **2 minutos.** Si reconoces una matroide (bosques, tareas con plazos, vectores independientes), el voraz es correcto sin más prueba. Si no lo es, hay pesos que lo rompen.

🔬 **El detalle.** `11/04`, §2.

**05 → S12.** ¿Por qué se buscan contraejemplos con entradas pequeñas? 🟢

⏱️ **30 segundos.** Porque hay menos combinaciones, así que cada caso tiene más probabilidad de contener el patrón que rompe el voraz, y el contraejemplo se puede leer. Además la fuerza bruta solo cabe con `n` pequeño.

🗣️ **2 minutos.** `n ≤ 8` y valores ≤ 5 cubren mucho del espacio en pocos miles de casos. Si no aparece nada, se sube `n` poco a poco.

🔬 **El detalle.** `11/04`, §4.

**05 → S13.** «Funciona en los cinco ejemplos que probé, así que el voraz es correcto.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que cinco ejemplos no prueban nada: el voraz «la reunión que menos choca» pasa cualquier ejemplo a mano y tiene un contraejemplo de diez intervalos. O se demuestra, o se ataca con un arnés de miles de casos.

🗣️ **2 minutos.** La corrección es universal; los ejemplos son existenciales. Lo que hago es escribir la fuerza bruta, generar casos pequeños y comparar; si en un millón no aparece nada, busco la prueba.

🔬 **El detalle.** `11/04`, §1.

**05 → S14.** Te piden el máximo de **beneficio** con trabajos que no se solapan. ¿Por qué no ordenar por final? 🟠

⏱️ **30 segundos.** Porque con pesos un contrato largo y caro puede valer más que dos cortos baratos: `[0,10)` con 10 frente a `[0,5)` y `[5,10)` con 3 cada uno. Es una DP sobre los finales con búsqueda binaria.

🗣️ **2 minutos.** El orden por final maximiza el **número**, no la suma. Con pesos, `dp[i] = max(dp[i − 1], w[i] + dp[p(i)])`, `Θ(n log n)`.

🔬 **El detalle.** Por Rado-Edmonds: los intervalos disjuntos no son una matroide, así que hay pesos que rompen cualquier voraz por peso.

**05 → S15.** «El cambio de monedas es voraz.» ¿Cuándo es verdad y cuándo no? 🟠

⏱️ **30 segundos.** Es verdad en sistemas canónicos, como casi todos los monetarios reales. Es falso en general: `{1, 3, 4}` con 6.

🗣️ **2 minutos.** Para un sistema dado, la canonicidad se comprueba con la DP hasta la suma de las dos mayores. Si no se puede comprobar, la DP de `12/03`.

🔬 **El detalle.** `11/03`, §6.

**05 → S16.** Tu mínimo de salas da uno más que lo esperado cuando dos reuniones se tocan en un instante. ¿Qué cambias? 🟠

⏱️ **30 segundos.** La frontera: si las reuniones son semiabiertas, una que acaba en `t` libera la sala para la que empieza en `t`: hay que liberar antes de ocupar (`fin ≤ inicio`). Si son cerradas, al revés.

🗣️ **2 minutos.** El caso mínimo `[1,2]` y `[2,3]` decide si la respuesta es 1 o 2 según el enunciado. Cambiar `<` por `≤` en la condición de liberar corrige el «uno más».

🔬 **El detalle.** `11/02`, pregunta 13.

**05 → S17.** Unir montones **vecinos** pagando la suma: ¿Huffman? 🟠

⏱️ **30 segundos.** No. Huffman une los dos menores estén donde estén; con vecinos, `[1, 10, 1]` cuesta 23 y no 14. Es una DP de intervalos.

🗣️ **2 minutos.** La restricción de vecindad hace que el orden importe, y la elección local deja de ser segura. `dp[i][j] = min (dp[i][k] + dp[k+1][j]) + suma(i..j)`.

🔬 **El detalle.** `11/03`, pregunta 13, y `12/05`.

**05 → S18.** «Ordeno las tareas por duración y listo.» El coste tiene pesos. ¿Qué falla? 🟠

⏱️ **30 segundos.** Que con pesos el orden correcto es por duración entre peso (regla de Smith), no por duración. El de duración ignora que un encargo con mucho peso conviene adelantarlo.

🗣️ **2 minutos.** La cuenta del intercambio de vecinos lo dice: conviene `x` antes si `pₓ · w_y < p_y · wₓ`. Solo con pesos iguales coincide con el más corto primero.

🔬 **El detalle.** `11/01`, §1 y §4.

**05 → S19.** Demuestra con «el voraz se adelanta» que el voraz de saltos de Jump Game II da el mínimo de saltos. 🔴

⏱️ **30 segundos.** Medida: el índice más lejano alcanzable con `k` saltos. El voraz, al saltar a la capa siguiente, toma como nuevo alcance el máximo de los alcances de la capa actual; por inducción, su alcance con `k` saltos es mayor o igual que el de cualquier otra estrategia con `k` saltos.

🗣️ **2 minutos.** Caso base: con 0 saltos, todos están en 0. Paso: cualquier posición alcanzable con `k + 1` saltos sale de una alcanzable con `k`, que está en la capa del voraz (o antes), y su alcance está considerado en el máximo del voraz. Así que si alguien llega al final con `m` saltos, el voraz también.

🔬 **El detalle.** El voraz es un BFS por capas sobre los índices sin guardar la cola: cada capa es un intervalo contiguo.

**05 → S20.** Demuestra que la concatenación ordenada con `a + b < b + a` da la cadena lexicográficamente menor. 🔴

⏱️ **30 segundos.** Por intercambio de vecinos: si en una ordenación hay `x` antes que `y` consecutivos con `x + y > y + x`, cambiarlos da una cadena menor, porque el prefijo y el sufijo no cambian. Y la relación «`a + b ≤ b + a`» es transitiva, así que ordenar por ella es consistente.

🗣️ **2 minutos.** La cadena total es `P + x + y + S` frente a `P + y + x + S`; con el mismo prefijo `P` y el mismo sufijo `S`, manda la comparación de `x + y` con `y + x`. Por el teorema de vecinos, la ordenación sin pares «malos» es óptima. La transitividad se prueba viendo las cadenas como números en base 26: `a + b < b + a` equivale a `a / (26^|a| − 1) < b / (26^|b| − 1)`.

🔬 **El detalle.** Sin la transitividad, ordenar con ese comparador sería indefinido; es la parte de la prueba que casi todos se saltan.

**05 → Problema: Contratos.**

- **Pista 2 — patrón:** **intervalos con peso**: el voraz falla; **DP sobre los finales con búsqueda binaria**.
- **Pista 3 — diseño:** ordena por final; `dp[i]` = el mejor pago con los `i` primeros contratos; `dp[i] = max(dp[i − 1], w_i + dp[j])`, donde `j` es cuántos contratos terminan en `≤ s_i` (*upper bound* sobre los finales). Pagos en 64 bits.

**05 → Problema: Recuperaciones.**

- **Pista 2 — patrón:** **planificación con plazos**: minimizar la multa es maximizar la multa evitada.
- **Pista 3 — diseño:** el montículo de `11/03` con las multas como beneficio; la respuesta es la suma de todas las multas menos la suma del montículo. En 64 bits.

**05 → Problema: La concatenación más pequeña.**

- **Pista 2 — patrón:** **ordenar con el comparador del intercambio**: `a` antes que `b` si `a + b < b + a`.
- **Pista 3 — diseño:** ordena con ese comparador y concatena. En Java, `(a, b) -> (a + b).compareTo(b + a)`; en Python, `cmp_to_key`. Con cadenas largas, cada comparación cuesta su longitud; la suma de longitudes acotada lo deja en `O(L log n)` aproximadamente.

**05 → Problema: Turnos con preferencias.**

- **Pista 2 — patrón:** **fuerza bruta sobre las permutaciones**: con `n ≤ 9`, `9! = 362 880` asignaciones.
- **Pista 3 — diseño:** recorre las permutaciones de los turnos con la siguiente permutación y suma `g[i][p[i]]`. El voraz «cada uno su favorito» falla en el segundo ejemplo (10 frente a 16).

**05 → Problema: Boats to Save People.**

- **Pista 2 — patrón:** **dos punteros tras ordenar**, con argumento de intercambio.
- **Pista 3 — diseño:** el más pesado va en un bote; si cabe con el más ligero, van juntos. Avanza los punteros y cuenta botes.

**05 → Problema: Minimum Number of Arrows to Burst Balloons.**

- **Pista 2 — patrón:** **cubrimiento con puntos** por final.
- **Pista 3 — diseño:** ordena por final; dispara en el final del primer globo no reventado; los que empiezan en `≤` ese punto revientan. Con valores cercanos a los límites de `int`, compara sin restar.

**05 → Problema: Max Min.**

- **Pista 2 — patrón:** **ordenar y ventana de tamaño `k`**: la mejor elección son `k` consecutivos en orden.
- **Pista 3 — diseño:** ordena; la respuesta es el mínimo de `a[i + k − 1] − a[i]`. Intercambio: si una elección no es contigua, sustituir un extremo por un elemento interior no aumenta la diferencia.

**05 → Problema: Advantage Shuffle.**

- **Pista 2 — patrón:** **voraz de emparejamiento** (el del caballo de Tian Ji).
- **Pista 3 — diseño:** ordena tus cartas y las del rival (con sus índices); para cada carta del rival de mayor a menor, si tu mayor la gana, úsala; si no, sacrifica tu menor carta.

**05 → Problema: Bag of Tokens.**

- **Pista 2 — patrón:** **dos punteros tras ordenar**: comprar puntos con la ficha más barata, recuperar energía con la más cara.
- **Pista 3 — diseño:** mientras puedas, gasta la más barata y gana un punto; si no puedes y tienes un punto, cámbialo por la energía de la más cara; registra el máximo de puntos alcanzado.
