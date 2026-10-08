# Respuestas — bloque 04: Secuencias

> Solucionario del bloque `04`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--sumas-de-prefijos-y-arreglos-de-diferencias) · [02](#02--dos-punteros-y-ventana-deslizante) · [03](#03--kadane-y-subarreglos) · [04](#04--compresión-de-coordenadas-y-barrido-de-eventos) · [05](#05--matrices) · [06](#06--simulación)

---

# 01 — Sumas de prefijos y arreglos de diferencias

**01 → 1.** ¿Cómo se calcula la suma de `a[l..r]` con el arreglo de prefijos, y por qué `P` tiene `n + 1` posiciones? 🟢

⏱️ **30 segundos.** `P[r + 1] − P[l]`. `P` tiene `n + 1` posiciones con `P[0] = 0` para que el prefijo vacío exista y el rango que empieza en 0 no sea un caso especial.

🗣️ **2 minutos.** `P[k]` es la suma de los `k` primeros elementos. La suma de `a[l..r]` es la de los `r + 1` primeros menos la de los `l` primeros. Con `P` del mismo tamaño que `a`, el rango `[0, r]` necesitaría restar «el prefijo de −1», que no existe.

🔬 **El detalle.** Es la misma decisión que el intervalo semiabierto de la búsqueda binaria: índices que van de 0 a `n` incluido hacen desaparecer los bordes. Los prefijos van en 64 bits.

**01 → 2.** ¿Qué dos posiciones cambia «suma `v` a `[l, r]`» en un arreglo de diferencias? 🟢

⏱️ **30 segundos.** `D[l] += v` y `D[r + 1] −= v`.

🗣️ **2 minutos.** Al reconstruir con prefijos, el `+v` se arrastra desde `l` hasta el final y el `−v` lo cancela desde `r + 1`: solo las posiciones `l..r` quedan con `+v`. Por eso `D` tiene `n + 1` posiciones, para que `r + 1 = n` exista.

🔬 **El detalle.** Cada operación cuesta `O(1)` sin importar la longitud del rango; el arreglo real solo existe tras la reconstrucción, `O(n)`.

**01 → 3.** Escribe la fórmula de construcción de los prefijos 2D. 🟢

⏱️ **30 segundos.** `S[i+1][j+1] = M[i][j] + S[i][j+1] + S[i+1][j] − S[i][j]`.

🗣️ **2 minutos.** El rectángulo hasta `(i, j)` es la celda más el rectángulo de arriba más el de la izquierda; los dos se solapan en el rectángulo de arriba a la izquierda, que se ha contado dos veces y se resta una. Es inclusión-exclusión.

🔬 **El detalle.** Con una fila y una columna de ceros delante, las celdas del borde no necesitan casos especiales; se construye recorriendo por filas.

**01 → 4.** ¿Por qué hacer prefijos y hacer diferencias son operaciones inversas? 🟡

⏱️ **30 segundos.** Porque los prefijos de las diferencias de `b` devuelven `b`, y las diferencias de los prefijos de `a` devuelven `a`: cada operación deshace la otra.

🗣️ **2 minutos.** `P[i+1] − P[i] = a[i]`: las diferencias de los prefijos son el arreglo original. Y si `D[i] = b[i] − b[i−1]`, sumar `D[0..i]` telescopa a `b[i]`. Es la versión discreta de que derivar deshace integrar.

🔬 **El detalle.** Por eso el arreglo de diferencias es «el arreglo cuyos prefijos son el resultado»: cambiar un rango del resultado equivale a cambiar dos puntos de las diferencias, igual que cambiar un rango de una suma acumulada equivale a cambiar dos puntos.

**01 → 5.** ¿Qué diferencia hay entre usar diferencias y usar un Fenwick para sumas de rango? 🟡

⏱️ **30 segundos.** Las diferencias sirven si todas las escrituras van antes que todas las lecturas; un Fenwick permite mezclarlas, con `O(log n)` por operación.

🗣️ **2 minutos.** Con diferencias, leer un valor exige reconstruir los prefijos, `O(n)`; hacerlo después de cada escritura es cuadrático. Un Fenwick mantiene los prefijos de las diferencias dinámicamente: actualizar un rango son dos actualizaciones puntuales y leer un valor es una consulta de prefijo, las dos `O(log n)`.

🔬 **El detalle.** Si todas las operaciones se conocen de antemano, a veces se pueden reordenar para separar escrituras y lecturas y volver a las diferencias. Ver [`09/02`](../09-consultas-sobre-rangos/02-fenwick.md).

**01 → 6.** ¿Por qué los prefijos no sirven para el mínimo de un rango, y para el XOR sí? 🟡

⏱️ **30 segundos.** Porque el mínimo no tiene operación inversa: conocer el mínimo de `[0, r]` y el de `[0, l−1]` no dice el de `[l, r]`. El XOR sí la tiene, porque `x ⊕ x = 0`, y `P[r+1] ⊕ P[l]` es el XOR del rango.

🗣️ **2 minutos.** Los prefijos funcionan con cualquier operación de grupo: asociativa, con neutro e invertible (suma con resta, XOR consigo mismo, producto con división si no hay ceros). El mínimo es asociativo y tiene neutro, pero no inversa.

🔬 **El detalle.** Para mínimos de rango sobre datos fijos está la *sparse table* ([`09/01`](../09-consultas-sobre-rangos/01-sparse-table.md)), que aprovecha que el mínimo es idempotente; con actualizaciones, el árbol de segmentos ([`09/03`](../09-consultas-sobre-rangos/03-segment-tree.md)).

**01 → 7.** Demuestra el teorema de la suma telescópica. 🟠

⏱️ **30 segundos.** `P[r+1] − P[l] = (a[0] + … + a[r]) − (a[0] + … + a[l−1])`: los términos de `0` a `l − 1` están en los dos y se cancelan, y queda `a[l] + … + a[r]`.

🗣️ **2 minutos.** Formalmente, por la definición `P[k] = Σ_{i<k} a[i]`, la diferencia es `Σ_{i<r+1} a[i] − Σ_{i<l} a[i] = Σ_{l≤i≤r} a[i]`, porque el segundo conjunto de índices está contenido en el primero. Para `l = 0`, `P[0] = 0` y la fórmula sigue valiendo.

🔬 **El detalle.** El nombre viene de las sumas telescópicas `Σ (P[i+1] − P[i])`, donde los términos intermedios se cancelan de dos en dos: `P[r+1] − P[l] = Σ_{i=l}^{r} (P[i+1] − P[i]) = Σ_{i=l}^{r} a[i]`.

**01 → 8.** Compara cómo construyes los prefijos en C++, Java y Python, y qué detalle de tipos o de rendimiento tiene cada uno. 🟠

⏱️ **30 segundos.** En C++, un `vector<long long>` de `n + 1` y un bucle (o `partial_sum` con cuidado del tipo); en Java, un `long[]` de `n + 1`; en Python, `[0] + list(accumulate(a))`. El detalle es el tipo de 64 bits en C++ y Java y la velocidad en Python.

🗣️ **2 minutos.** En C++ y en Java los prefijos desbordan `int` con `2·10⁵` valores de `10⁹`, así que el arreglo es de 64 bits aunque los datos sean `int`. En Python no hay desbordamiento, y `accumulate` corre en C: es mucho más rápido que un bucle propio.

🔬 **El detalle.** `std::partial_sum` escribe en el tipo del destino: si el destino es `vector<long long>`, acumula en `long long`. `std::accumulate`, en cambio, usa el tipo del valor inicial ([`03/02`](../03-biblioteca-estandar/02-cpp-algoritmos-ranges-y-pbds.md)).

**01 → 9.** Tienes `10⁵` operaciones de suma por rango mezcladas con `10⁵` consultas de un valor puntual. ¿Por qué no basta con diferencias, y qué usas? 🟠

⏱️ **30 segundos.** Porque leer un valor puntual con diferencias exige reconstruir los prefijos, `O(n)`, y con `10⁵` lecturas intercaladas son `10¹⁰`. Uso un Fenwick sobre las diferencias: suma de rango en dos actualizaciones puntuales y lectura como prefijo, `O(log n)` cada una.

🗣️ **2 minutos.** El valor en `i` es el prefijo de las diferencias hasta `i`. Un Fenwick mantiene prefijos con actualizaciones puntuales en `O(log n)`, así que `add(l, v)`, `add(r+1, −v)` y `prefix(i)` resuelven las dos operaciones. Total `O((n + q) log n)`.

🔬 **El detalle.** Es el problema «Range Update Queries» de la ampliación, y el patrón «rango/puntual» de `09/02`.

**01 → 10.** En la consulta 2D, ¿por qué la esquina `S[r1][c1]` se suma y no se resta? 🟠

⏱️ **30 segundos.** Porque los dos rectángulos que se restan, el de arriba y el de la izquierda, se solapan en `S[r1][c1]`: esa esquina se ha restado dos veces y hay que devolverla una.

🗣️ **2 minutos.** `S[r2+1][c2+1]` cuenta todo hasta la esquina inferior derecha. Restar `S[r1][c2+1]` quita las filas de arriba; restar `S[r2+1][c1]` quita las columnas de la izquierda. La zona de arriba a la izquierda está en las dos restas, y se suma una vez para compensar.

🔬 **El detalle.** Un error de signo en esa esquina da resultados que solo fallan cuando `r1` y `c1` son mayores que 0, así que los ejemplos con la esquina en el origen no lo detectan.

**01 → 11.** Diseña cómo contar, para cada punto de `0` a `10⁶`, cuántos de `n` intervalos lo cubren, con su coste. 🔴

⏱️ **30 segundos.** Un arreglo de diferencias de `10⁶ + 2` posiciones: cada intervalo `[l, r]` suma 1 en `l` y resta 1 en `r + 1`; los prefijos dan la cobertura de cada punto. `O(n + 10⁶)` tiempo y `O(10⁶)` memoria.

🗣️ **2 minutos.** Contar a mano cada intervalo punto a punto cuesta la suma de las longitudes, hasta `n · 10⁶`. Con diferencias, cada intervalo es `O(1)` y la reconstrucción un solo recorrido. Si las coordenadas llegaran a `10⁹`, el arreglo no cabría: se comprimen las coordenadas o se ordenan los eventos ([`04/04`](04-compresion-y-barrido.md)).

🔬 **El detalle.** El tipo del contador es `int`, porque la cobertura no pasa de `n`. Los extremos semiabiertos o cerrados deciden si el `−1` va en `r` o en `r + 1`.

**01 → 12.** Una solución con prefijos da WA solo en los casos grandes. Da dos causas posibles y cómo descartarlas. 🔴

⏱️ **30 segundos.** El desbordamiento de los prefijos en `int`, y un error de índice en los bordes (`l = 0` o `r = n − 1`) que los ejemplos pequeños no tocan.

🗣️ **2 minutos.** Los prefijos llegan a `n · max|a|`, que con los máximos pasa de `2·10⁹`: los casos grandes desbordan y los pequeños no. El otro sospechoso es la convención de índices: consultas desde 1 en el enunciado y prefijos desde 0 en el código, o `P[r] − P[l−1]` mezclado con `P[r+1] − P[l]`.

🔬 **El detalle.** Se descartan con un caso máximo generado (todos los valores en el tope) y con un *stress test* contra la suma directa con rangos que tocan los bordes ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).

**01 → 13.** Escribe las cuatro anotaciones de una diferencia 2D y demuestra que, tras los prefijos 2D, solo la submatriz recibe `v`. 🔴

⏱️ **30 segundos.** `+v` en `(r1, c1)`, `−v` en `(r1, c2+1)`, `−v` en `(r2+1, c1)` y `+v` en `(r2+1, c2+1)`. Tras los prefijos 2D, una celda `(i, j)` recibe la suma de las anotaciones con fila `≤ i` y columna `≤ j`.

🗣️ **2 minutos.** Para una celda dentro de la submatriz, solo la anotación `(r1, c1)` cumple las dos condiciones: recibe `+v`. Para una celda a la derecha (`j > c2`) dentro de las filas, cumplen `(r1, c1)` y `(r1, c2+1)`: `+v − v = 0`. Debajo, igual con `(r2+1, c1)`. Abajo a la derecha, las cuatro: `+v − v − v + v = 0`. Fuera por arriba o por la izquierda, ninguna.

🔬 **El detalle.** La matriz de diferencias tiene `(R + 1) × (C + 1)` posiciones para que las anotaciones en `r2 + 1` y `c2 + 1` existan siempre. Es la inversa exacta de los prefijos 2D.

**01 → Problema: Ventas por periodo.**

- **Pista 2 — patrón:** **prefijos 1D**.
- **Pista 3 — diseño:** construye `P` de `n + 1` en 64 bits; con índices desde 1, la suma de `[l, r]` es `P[r] − P[l − 1]` (o pasa a índices desde 0 y usa `P[r+1] − P[l]`). Con E/S rápida.

**01 → Problema: Ocupación del hotel.**

- **Pista 2 — patrón:** **arreglo de diferencias** y un recorrido final que busca el máximo.
- **Pista 3 — diseño:** por cada reserva, `D[l] += k` y `D[r + 1] −= k`; recorre acumulando y guarda la primera noche con el máximo (actualiza solo con «estrictamente mayor»); la ocupación llega a `2·10¹⁴`: 64 bits.

**01 → Problema: Parcelas del vivero.**

- **Pista 2 — patrón:** **prefijos 2D** con inclusión-exclusión.
- **Pista 3 — diseño:** construye `S` de `(R+1) × (C+1)` en 64 bits; con índices desde 1, la consulta es `S[r2][c2] − S[r1−1][c2] − S[r2][c1−1] + S[r1−1][c1−1]`. Los totales llegan a `10¹⁵`.

**01 → Problema: Range Sum Query - Immutable.**

- **Pista 2 — patrón:** **prefijos** precalculados en el constructor.
- **Pista 3 — diseño:** el constructor construye `P` de `n + 1`; `sumRange(l, r)` devuelve `P[r+1] − P[l]`.

**01 → Problema: Static Range Sum Queries.**

- **Pista 2 — patrón:** **prefijos 1D**.
- **Pista 3 — diseño:** `P` en 64 bits (la suma llega a `2·10¹⁴`); cada consulta, una resta; E/S rápida.

**01 → Problema: GenomicRangeQuery.**

- **Pista 2 — patrón:** **un arreglo de prefijos por categoría** (A, C, G, T).
- **Pista 3 — diseño:** para cada letra, `cuenta[letra][k]` = apariciones en los `k` primeros; para cada consulta, el menor factor de impacto es la primera letra, en orden A, C, G, T, con cuenta positiva en el rango.

**01 → Problema: MinAvgTwoSlice.**

- **Pista 2 — patrón:** **observación** sobre las medias, con prefijos o sin ellos.
- **Pista 3 — diseño:** todo tramo de longitud 4 o más se puede partir en tramos de longitud 2 o 3, y alguno tiene media menor o igual; basta comprobar los tramos de longitud 2 y 3 y devolver el inicio del de menor media.

**01 → Problema: Corporate Flight Bookings.**

- **Pista 2 — patrón:** **arreglo de diferencias**.
- **Pista 3 — diseño:** por cada reserva `[first, last, seats]` (desde 1), suma `seats` en `first − 1` y resta en `last`; los prefijos dan los asientos de cada vuelo.

**01 → Problema: Forest Queries.**

- **Pista 2 — patrón:** **prefijos 2D** contando árboles.
- **Pista 3 — diseño:** `S` con 1 por cada `*`; cada consulta, inclusión-exclusión de cuatro esquinas con índices desde 1.

**01 → Problema: Matrix Block Sum.**

- **Pista 2 — patrón:** **prefijos 2D** con recorte de los bordes.
- **Pista 3 — diseño:** para cada celda, el bloque va de `max(0, i − k)` a `min(m − 1, i + k)` en filas y lo mismo en columnas; con esos límites, una consulta de prefijos 2D.

**01 → Problema: Increment Submatrices by One.**

- **Pista 2 — patrón:** **diferencias 2D**.
- **Pista 3 — diseño:** cuatro anotaciones por consulta en una matriz de `(n+1) × (n+1)`; al final, prefijos 2D sobre las anotaciones y recorta la última fila y columna.

**01 → Problema: Range Update Queries.**

- **Pista 2 — patrón:** **Fenwick sobre las diferencias** (rango/puntual, `09/02`).
- **Pista 3 — diseño:** inicializa con las diferencias del arreglo; una suma de rango son `add(a, u)` y `add(b + 1, −u)`; el valor en `k` es el prefijo hasta `k`. Todo en 64 bits.

**01 → Problema: Array Manipulation.**

- **Pista 2 — patrón:** **arreglo de diferencias** con el máximo calculado durante la reconstrucción.
- **Pista 3 — diseño:** dos anotaciones por operación en un arreglo de `n + 2` de 64 bits; recorre acumulando y guarda el máximo, sin construir el arreglo final aparte.

---

# 02 — Dos punteros y ventana deslizante

**02 → 1.** ¿Por qué un bucle `while` dentro de un `for` puede ser `O(n)` en total? 🟢

⏱️ **30 segundos.** Porque si el índice que avanza dentro del `while` nunca retrocede, en todo el programa se mueve como mucho `n` veces; sumado a las `n` vueltas del `for`, son `2n` pasos.

🗣️ **2 minutos.** Acotar el `while` por su caso peor en cada vuelta daría `n²`, pero esa cota es muy pesimista: las vueltas largas del `while` «gastan» movimientos del índice que ya no estarán disponibles después. Contar los movimientos totales, en vez de por vuelta, es el análisis agregado ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

🔬 **El detalle.** El argumento falla en cuanto el índice interno se reinicia en cada vuelta (`l = 0` dentro del `for`): entonces sí es cuadrático. Es la diferencia entre una ventana y una fuerza bruta escrita con el mismo aspecto.

**02 → 2.** ¿Qué condición tiene que cumplir el arreglo para usar dos punteros desde los extremos? 🟢

⏱️ **30 segundos.** Tiene que estar ordenado (o poder ordenarse sin perder lo que pide el problema).

🗣️ **2 minutos.** El descarte de un extremo se apoya en el orden: si `a[l] + a[r]` es demasiado grande, todos los `l' > l` dan sumas aún mayores con ese `r`, y `r` se puede descartar. Sin orden, esa implicación no existe.

🔬 **El detalle.** Si el problema pide los índices originales, se ordenan pares `(valor, índice)`. Si no se puede ordenar (el orden de los índices es parte de la condición), los dos punteros no sirven y la alternativa es una tabla *hash*.

**02 → 3.** ¿Qué diferencia hay entre ventana fija y ventana variable? 🟢

⏱️ **30 segundos.** En la fija, el tamaño `k` lo da el enunciado y la ventana avanza de uno en uno; en la variable, el tamaño lo decide la condición, y los dos extremos avanzan a ritmos distintos.

🗣️ **2 minutos.** La fija entra un elemento y saca otro en cada paso. La variable entra uno por la derecha y saca por la izquierda tantos como haga falta para recuperar la condición. Las dos son `O(n)`.

🔬 **El detalle.** La fija no necesita monotonía: solo un estado que se pueda actualizar con lo que entra y lo que sale. La variable sí la necesita.

**02 → 4.** ¿Qué significa que una condición sea monótona respecto de la inclusión? Da un ejemplo que lo sea y otro que no. 🟡

⏱️ **30 segundos.** Que si un tramo cumple la condición, todos sus subtramos también. «Suma `≤ S` con valores no negativos» lo es; «suma exactamente `S`» con negativos, no.

🗣️ **2 minutos.** La monotonía permite descartar inicios para siempre: si `[l, r]` falla, ningún tramo que lo contenga cumple, así que con un `r` mayor tampoco sirve ese `l`. «Como mucho `k` distintos» y «sin repetidos» también son monótonas.

🔬 **El detalle.** La dirección importa: para «el más corto con suma `≥ S`», la propiedad útil es la contraria, que si un tramo cumple, todo tramo que lo contiene también. Las dos versiones necesitan valores no negativos cuando la condición es sobre la suma.

**02 → 5.** ¿Qué diferencia hay entre buscar «el tramo más largo con suma `≤ S`» y «el más corto con suma `≥ S`» en la forma de mover los punteros? 🟡

⏱️ **30 segundos.** En «el más largo con `≤ S`», se encoge mientras la ventana **no** cumple y se anota después; en «el más corto con `≥ S`», se anota y se encoge mientras la ventana **sí** cumple.

🗣️ **2 minutos.** En el primero, cada ventana válida al final de la vuelta es la más larga que termina en `r`. En el segundo, cada vez que la ventana cumple, se anota su longitud y se intenta acortar desde la izquierda, porque buscamos la más corta.

🔬 **El detalle.** Confundir las dos formas es un error típico: el código compila y da el valor de la otra pregunta.

**02 → 6.** ¿Por qué en la ventana fija `best` empieza en la suma de la primera ventana y no en 0? 🟡

⏱️ **30 segundos.** Porque con valores negativos todas las sumas pueden ser negativas, y un `best` que empieza en 0 devolvería 0, que no es la suma de ninguna ventana.

🗣️ **2 minutos.** La respuesta tiene que ser la suma de una ventana real. Inicializar con la primera ventana garantiza que `best` siempre corresponde a alguna. Es el mismo error que el Kadane que permite el subarreglo vacío (`01/05`).

🔬 **El detalle.** La regla general: el máximo se inicializa con un valor del dominio (la primera ventana, `a[0]`) o con el mínimo del tipo, nunca con un neutro inventado como 0.

**02 → 7.** Escribe el invariante de la ventana variable y demuestra que `l` nunca tiene que retroceder. 🟠

⏱️ **30 segundos.** Invariante: al terminar la vuelta de `r`, `l` es el menor índice con `[l, r]` válido. Si `l' < l`, `[l', r]` es inválido, y `[l', r+1]` lo contiene, así que también es inválido por la monotonía: `l` no retrocede.

🗣️ **2 minutos.** Inicialización: con `r = 0`, el `while` deja `l` en el menor válido (o en 1 si `a[0]` sola no cumple). Mantenimiento: al entrar `a[r+1]`, los inicios `< l` siguen siendo inválidos por el argumento anterior, y el `while` avanza `l` hasta el primero válido. Al terminar cada vuelta, `[l, r]` es el tramo válido más largo que termina en `r`.

🔬 **El detalle.** La terminación es trivial (`r` llega a `n`), y el coste sale de que `l` solo avanza. Laaksonen, cap. 8.

**02 → 8.** Compara la plantilla de dos punteros en C++, Java y Python: ¿qué tipos tienen que ser de 64 bits en cada uno y por qué? 🟠

⏱️ **30 segundos.** En C++ y Java, la suma `a[l] + a[r]` y el contador tienen que ser de 64 bits: la suma de dos `10⁹` desborda `int` y el contador llega a `n²/2`. En Python no hace falta nada.

🗣️ **2 minutos.** En C++ se convierte un operando antes de sumar (`static_cast<long long>(a[l]) + a[r]`); en Java, `(long) a[l] + a[r]`. El contador, `long long` o `long`. Python no desborda, y su coste es la velocidad del bucle, que con `2·10⁵` va bien.

🔬 **El detalle.** El contador desborda con `n ≥ 65 536` aunque los valores sean pequeños: es el `n(n−1)/2` de [`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md).

**02 → 9.** Con `[5, −10, 4, 6]` y «el subarreglo más corto con suma `≥ 10`», ¿qué da la ventana variable y qué da la respuesta correcta? 🟠

⏱️ **30 segundos.** La ventana da «no hay» (`-1`): la suma nunca llega a 10 con su forma de avanzar. La respuesta correcta es 2, el tramo `[4, 6]`.

🗣️ **2 minutos.** La ventana acumula `5`, luego `−5`, luego `−1`, luego `5`: nunca llega a 10, porque no puede saltar el `−10` sin dejar fuera el `5`, y nunca encoge por la izquierda (solo encoge cuando cumple). El tramo bueno empieza después del negativo, y la ventana no lo ve.

🔬 **El detalle.** La solución correcta usa los prefijos: el tramo `(i, j]` tiene suma `P[j] − P[i]`, y para cada `j` se busca el `i` más cercano con `P[i] ≤ P[j] − S`, manteniendo una cola de prefijos crecientes ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)). Es el problema propio «El más corto, con pérdidas».

**02 → 10.** ¿Por qué ordenar no cambia el número de pares con suma `≤ K`, y cuándo ordenar sí te hace perder información? 🟠

⏱️ **30 segundos.** Porque contar pares `{i, j}` con `a[i] + a[j] ≤ K` no depende del orden de los índices: es un conjunto de valores. Ordenar hace perder información cuando el problema pide índices originales o pone condiciones sobre su orden, como `i < j` con `a[i] > a[j]`.

🗣️ **2 minutos.** Si el problema es «cuántos pares», reordenar el arreglo es una biyección entre pares, y la cuenta no cambia. Si es «qué pareja» y pide sus posiciones, se ordenan pares valor-índice. Si la condición mezcla valor y posición (inversiones, «el siguiente mayor»), ordenar destruye justo lo que se pregunta.

🔬 **El detalle.** Contar inversiones se puede hacer ordenando, pero contando durante la mezcla, no antes ([`05/03`](../05-orden-y-busqueda/03-inversiones-y-seleccion.md)).

**02 → 11.** Diseña con una ventana el «subarreglo más largo con como mucho `k` valores distintos»: el estado, la entrada, la salida y el coste. 🔴

⏱️ **30 segundos.** Estado: un mapa de conteos de la ventana y el número de valores distintos. Entra `a[r]`: si su conteo pasa de 0 a 1, sube el número de distintos. Mientras haya más de `k`, sale `a[l]`, y si su conteo llega a 0, baja. `O(n)` con mapa *hash*.

🗣️ **2 minutos.** La condición «como mucho `k` distintos» es monótona: quitar elementos no aumenta los distintos. Por eso basta con avanzar `l` mientras la ventana se pase, y en cada `r` la ventana es la más larga válida que termina ahí. La respuesta es el máximo de `r − l + 1`.

🔬 **El detalle.** Si los valores son pequeños (letras, valores hasta `10⁶`), el mapa se cambia por un arreglo de conteos y desaparece el riesgo del *hash* ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)). Es la generalización de Fruit Into Baskets.

**02 → 12.** Da un caso de prueba que rompa una ventana variable aplicada a «subarreglos con suma exactamente `S`» cuando hay ceros, y explica qué parte del razonamiento falla. 🔴

⏱️ **30 segundos.** Con `[1, 0, 0, 1]` y `S = 1`, hay seis subarreglos con suma exactamente 1, y una ventana que encoge en cuanto llega a 1 cuenta menos: pierde los que empiezan o terminan con ceros.

🗣️ **2 minutos.** «Suma exactamente `S`» no es monótona respecto de la inclusión: `[1, 0]` cumple y su subtramo `[0]` no. Con ceros, para un mismo final hay varios inicios válidos, y la ventana solo examina uno. El razonamiento que falla es el del teorema de §2: la condición no se conserva al quitar elementos.

🔬 **El detalle.** Con valores no negativos, «exactamente `S`» se cuenta como «`≤ S`» menos «`≤ S − 1`», cada una con una ventana. Con negativos, prefijos con un mapa de conteos ([`04/03`](03-kadane-y-subarreglos.md)).

**02 → Problema: Combinar dos listas de precios.**

- **Pista 2 — patrón:** **dos punteros sobre dos listas ordenadas**, uno avanzando y otro retrocediendo.
- **Pista 3 — diseño:** un índice en el entrante más barato y otro en el principal más caro; si suman `≤ K`, ese entrante forma menú con todos los principales hasta el índice actual (suma `j + 1` y avanza el entrante); si no, retrocede el principal. El total llega a `4·10¹⁰`: 64 bits.

**02 → Problema: Tramos dentro del presupuesto.**

- **Pista 2 — patrón:** **ventana variable** que cuenta en vez de maximizar.
- **Pista 3 — diseño:** para cada `r`, encoge `l` hasta que la suma no pase de `S`; todos los tramos `[l', r]` con `l ≤ l' ≤ r` son válidos por la monotonía: suma `r − l + 1`. Total en 64 bits (hasta `n²/2`).

**02 → Problema: El más corto, con pérdidas.**

- **Pista 2 — patrón:** **prefijos con una cola monótona**: con negativos, la ventana no sirve.
- **Pista 3 — diseño:** con prefijos `P`, el tramo `(i, j]` cumple si `P[j] − P[i] ≥ S`. Mantén una cola de índices con prefijos crecientes: para cada `j`, saca por delante mientras `P[j] − P[frente] ≥ S` (anotando `j − frente`), y saca por detrás los índices con prefijo `≥ P[j]`, que nunca serán mejores; después mete `j`.

**02 → Problema: AbsDistinct.**

- **Pista 2 — patrón:** **dos punteros desde los extremos** sobre valores absolutos.
- **Pista 3 — diseño:** compara los valores absolutos de los extremos; cuenta el mayor como un valor distinto y avanza todos los índices de ese lado que tengan el mismo valor absoluto; si son iguales, avanza los dos lados.

**02 → Problema: CountDistinctSlices.**

- **Pista 2 — patrón:** **ventana sin repetidos** que cuenta.
- **Pista 3 — diseño:** un arreglo de «visto»; para cada `r`, mientras `a[r]` ya esté en la ventana, saca `a[l]`; suma `r − l + 1`; si el total pasa de `10⁹`, devuelve `10⁹`.

**02 → Problema: CountTriangles.**

- **Pista 2 — patrón:** **ordenar y dos punteros** dentro de un bucle sobre el primer lado.
- **Pista 3 — diseño:** ordena; para cada `i`, recorre `j > i` con un índice `k` que solo avanza mientras `a[i] + a[j] > a[k]`; para cada `j`, suma `k − j − 1`. Es `O(n²)`, que con `n ≤ 1000` cabe.

**02 → Problema: 3Sum.**

- **Pista 2 — patrón:** **fijar un elemento y dos punteros** sobre el resto, con salto de repetidos.
- **Pista 3 — diseño:** ordena; para cada `i` (saltando valores repetidos de `i`), busca pares con suma `−nums[i]` en `i+1..n−1` con dos punteros; al encontrar uno, avanza los dos punteros saltando repetidos.

**02 → Problema: Container With Most Water.**

- **Pista 2 — patrón:** **dos punteros con argumento de descarte**: se mueve la pared más baja.
- **Pista 3 — diseño:** el área la limita la pared más baja; moverla es la única opción que puede mejorar, porque mover la alta reduce la anchura sin subir el límite; anota el área en cada paso.

**02 → Problema: Minimum Size Subarray Sum.**

- **Pista 2 — patrón:** **ventana variable** para el más corto con suma `≥ objetivo`.
- **Pista 3 — diseño:** entra cada elemento; mientras la suma cumpla, anota la longitud y saca por la izquierda; si nunca cumplió, la respuesta es 0.

**02 → Problema: Max Consecutive Ones III.**

- **Pista 2 — patrón:** **ventana con un contador de ceros**.
- **Pista 3 — diseño:** la ventana vale si tiene como mucho `k` ceros; entra cada elemento, y mientras haya más de `k` ceros, saca por la izquierda; la respuesta es la mayor anchura.

**02 → Problema: Permutation in String.**

- **Pista 2 — patrón:** **ventana fija** del tamaño de `s1` con conteos de letras.
- **Pista 3 — diseño:** compara los 26 conteos de `s1` con los de cada ventana de `s2`, actualizando la ventana con la letra que entra y la que sale; o lleva cuántas de las 26 letras coinciden y actualízalo en `O(1)`.

**02 → Problema: Fruit Into Baskets.**

- **Pista 2 — patrón:** **ventana con como mucho dos tipos distintos**.
- **Pista 3 — diseño:** conteos por tipo en la ventana y número de tipos con conteo positivo; mientras pase de 2, saca por la izquierda; la respuesta es la mayor anchura.

**02 → Problema: Longest Repeating Character Replacement.**

- **Pista 2 — patrón:** **ventana** cuya validez depende de su letra más frecuente.
- **Pista 3 — diseño:** una ventana vale si `anchura − frecuencia de su letra más frecuente ≤ k`; lleva los conteos y el máximo de frecuencia visto; mientras no valga, saca por la izquierda. No hace falta bajar el máximo al sacar, porque solo una frecuencia mayor puede mejorar la respuesta.

**02 → Problema: Sum of Three Values.**

- **Pista 2 — patrón:** **fijar uno y dos punteros**, con los índices originales.
- **Pista 3 — diseño:** ordena pares `(valor, índice)`; para cada `i`, dos punteros sobre `i+1..n−1` buscando `x − valor[i]`; imprime los tres índices originales. Es `O(n²)` con `n ≤ 5000`.

**02 → Problema: MinAbsSumOfTwo.**

- **Pista 2 — patrón:** **ordenar y dos punteros** buscando la suma más cercana a cero (se permite el mismo índice dos veces).
- **Pista 3 — diseño:** ordena; con `l` y `r` en los extremos (pudiendo coincidir), anota `|a[l] + a[r]|`; si la suma es positiva, baja `r`; si es negativa, sube `l`; si es 0, la respuesta es 0.

---

# 03 — Kadane y subarreglos

**03 → 1.** Escribe la recurrencia de Kadane y di qué significa `best_end(i)`. 🟢

⏱️ **30 segundos.** `best_end(i) = max(a[i], best_end(i−1) + a[i])`, con `best_end(0) = a[0]`: la mayor suma de un subarreglo no vacío que termina exactamente en `i`. La respuesta es el máximo de todos.

🗣️ **2 minutos.** El mejor tramo que termina en `i` o empieza en `i` o extiende al mejor que terminaba en `i − 1`; no hay más opciones. En código, `cur` es `best_end(i)` y `best` el máximo visto.

🔬 **El detalle.** Es una programación dinámica con un estado por posición y una transición de dos opciones ([`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md)). Que solo haga falta el estado anterior es lo que la deja en `O(1)` de memoria.

**03 → 2.** ¿Cuál es la fórmula del subarreglo máximo circular, y cuál es su excepción? 🟢

⏱️ **30 segundos.** `max(Kadane(a), total − mínimo subarreglo(a))`, salvo cuando todos los valores son negativos, donde la respuesta es `Kadane(a)`.

🗣️ **2 minutos.** El segundo término es el mejor tramo que da la vuelta: todo menos el peor tramo que no la da. Si todos son negativos, el peor tramo es el arreglo entero y `total − mínimo = 0` correspondería al tramo vacío, que no está permitido.

🔬 **El detalle.** En código, la condición se escribe `best < 0 ? best : max(best, total − worst)`: si el mejor Kadane es negativo, todos lo son.

**03 → 3.** ¿Por qué el mapa de prefijos empieza con `{0: 1}`? 🟢

⏱️ **30 segundos.** Porque representa el prefijo vacío, `P[0] = 0`: sin él no se cuentan los tramos que empiezan en la posición 0.

🗣️ **2 minutos.** Un tramo `a[0..j]` tiene suma `P[j+1] − P[0]`. Si `P[0]` no está registrado, ese par de prefijos nunca se encuentra. Registrar el 0 con una aparición antes de empezar es lo mismo que haber recorrido el prefijo vacío.

🔬 **El detalle.** El orden también importa: se cuenta antes de registrar el prefijo actual. Al revés, con `k = 0` cada prefijo se emparejaría consigo mismo y se contaría el tramo vacío.

**03 → 4.** ¿Qué diferencia hay entre el Kadane con `max(0, cur + x)` y el de `max(x, cur + x)`? 🟡

⏱️ **30 segundos.** La de `max(0, cur + x)` permite el subarreglo vacío y devuelve 0 cuando todos son negativos; la de `max(x, cur + x)` con `best = a[0]` nunca lo permite y devuelve el mayor elemento.

🗣️ **2 minutos.** Las dos coinciden cuando hay algún valor positivo. Si el enunciado admite el tramo vacío (suma 0), la primera es correcta; si exige no vacío, solo la segunda. El error de la primera es el ejemplo trabajado de `01/05`.

🔬 **El detalle.** La diferencia es una línea y casi nunca aparece en los ejemplos, que suelen tener positivos. Un *stress test* con valores en `[−5, 5]` la encuentra enseguida.

**03 → 5.** ¿Qué diferencia hay entre contar subarreglos con suma `k` usando una ventana y usando prefijos con mapa? 🟡

⏱️ **30 segundos.** La ventana solo funciona con valores no negativos, porque necesita que la suma crezca al alargar; los prefijos con mapa funcionan con cualquier signo.

🗣️ **2 minutos.** Con negativos, para un mismo final puede haber inicios válidos separados por inválidos, y la ventana, que solo avanza, los pierde. El mapa no recorre inicios: pregunta directamente cuántos prefijos anteriores valen `P[j] − k`.

🔬 **El detalle.** Con valores no negativos, las dos sirven; la ventana usa `O(1)` memoria y la de prefijos `O(n)`. Con ceros, la ventana para «suma exacta» necesita el truco de «`≤ k` menos `≤ k−1`» ([`04/02`](02-dos-punteros-y-ventana.md)).

**03 → 6.** ¿Por qué Boyer-Moore necesita una segunda pasada? 🟡

⏱️ **30 segundos.** Porque el candidato final solo es el mayoritario **si existe** uno; si no existe, el candidato es un valor cualquiera, y solo contándolo se sabe.

🗣️ **2 minutos.** El argumento de las parejas garantiza que el mayoritario sobrevive, pero no dice nada cuando no lo hay. Con `[1, 2, 3]`, el candidato final es 3, que aparece una vez. La segunda pasada cuenta sus apariciones y compara con `n/2`.

🔬 **El detalle.** Si el enunciado garantiza que existe mayoritario (como en algunos problemas de LeetCode), la segunda pasada sobra; si no lo garantiza, es parte de la corrección.

**03 → 7.** Demuestra por inducción que la recurrencia de Kadane calcula la mejor suma que termina en cada posición. 🟠

⏱️ **30 segundos.** Caso base: `best_end(0) = a[0]`, el único tramo que termina en 0. Paso: un tramo que termina en `i` es `[i]` o un tramo que termina en `i − 1` seguido de `a[i]`; el mejor de los segundos es `best_end(i−1) + a[i]` por hipótesis. El máximo de las dos clases es `best_end(i)`.

🗣️ **2 minutos.** La clave del paso es que sumar la misma cantidad `a[i]` a todos los tramos que terminan en `i − 1` no cambia cuál es el mejor; por eso basta con el mejor anterior y no hace falta recordar los demás. Con eso la recurrencia queda probada para todo `i`, y el máximo global es el máximo sobre los finales.

🔬 **El detalle.** Es la «subestructura óptima» de la programación dinámica: la solución óptima del subproblema `i` usa la óptima del `i − 1`. La forma de la prueba es la de [`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md), inducción sobre `i`.

**03 → 8.** Compara las tres plantillas de conteo: ¿qué cambia en el mapa entre C++, Java y Python, y qué riesgo tiene el de C++ con datos adversarios? 🟠

⏱️ **30 segundos.** En C++ es `unordered_map<long long, long long>` con `reserve`; en Java, `HashMap<Long, Long>` con `merge` y `getOrDefault`; en Python, `defaultdict(int)`. El de C++ es atacable: con prefijos elegidos por un adversario, todas las claves pueden caer en una cubeta.

🗣️ **2 minutos.** Los tres son tablas *hash* con `O(1)` esperado. En Java cada clave y cada valor son objetos `Long`, que cuesta memoria; en Python, la `defaultdict` crea entradas al consultar, por eso se consulta con `get`. En C++, el *hash* de enteros de libstdc++ es la identidad y se puede atacar en un concurso con *hacks*.

🔬 **El detalle.** La defensa en C++ es un *hash* propio con semilla aleatoria (`06/03`), o un `map` ordenado con `O(log n)`. En Java, el árbol en las cubetas limita el daño.

**03 → 9.** ¿Por qué un tramo circular que da la vuelta es el complemento de uno normal, y qué pasa con el arreglo entero? 🟠

⏱️ **30 segundos.** Porque los elementos que no están en un tramo circular que da la vuelta forman un tramo contiguo que no la da. El arreglo entero es un caso aparte: su complemento es vacío.

🗣️ **2 minutos.** Si un tramo circular empieza en `i` y termina en `j` con `j < i` (dando la vuelta), los elementos fuera son exactamente `a[j+1..i−1]`, contiguos. Maximizar la suma del tramo circular es minimizar la de ese complemento. Si el mínimo subarreglo es el arreglo entero, el complemento es vacío, y eso solo ocurre si todos son negativos (o el mínimo coincide con el total).

🔬 **El detalle.** Por eso la fórmula excluye el caso de todos negativos: el «tramo» de suma `total − total = 0` no existe.

**03 → 10.** Para «subarreglos con suma divisible por `m`», ¿qué guardas en el mapa y por qué hay que normalizar el resto? 🟠

⏱️ **30 segundos.** El resto de cada prefijo módulo `m`, normalizado a `[0, m)`; dos prefijos con el mismo resto delimitan un tramo divisible. En C++ y Java el `%` de un negativo es negativo, y sin normalizar, `−1` y `2` (módulo 3) serían claves distintas siendo el mismo resto.

🗣️ **2 minutos.** `P[j] − P[i] ≡ 0 (mod m)` si y solo si `P[i] ≡ P[j]`. Se cuenta, para cada `j`, cuántos prefijos anteriores tienen el mismo resto. La normalización es `((p % m) + m) % m`.

🔬 **El detalle.** En Python el `%` ya devuelve un valor en `[0, m)` para `m > 0`. Con `m` pequeño, el mapa puede ser un arreglo de `m` contadores.

**03 → 11.** Escribe el invariante del voto de Boyer-Moore y demuestra que el mayoritario, si existe, es el candidato final. 🔴

⏱️ **30 segundos.** Invariante: los elementos ya procesados se pueden partir en `cnt` copias del candidato sin emparejar y en parejas de valores distintos. Si existe mayoritario, no puede quedar completamente emparejado, así que es el candidato final.

🗣️ **2 minutos.** Inicialmente, `cnt = 0` y no hay nada. Si `cnt = 0`, el nuevo elemento pasa a candidato sin emparejar. Si coincide con el candidato, se suma a los sin emparejar. Si no, se empareja con una copia del candidato y `cnt` baja. Las parejas siempre son de valores distintos. Al final, cada pareja contiene como mucho una copia del mayoritario, y como tiene más de `n/2` copias, al menos una queda sin emparejar: es el candidato.

🔬 **El detalle.** La prueba no dice nada si no hay mayoritario; de ahí la segunda pasada. Es el ejemplo clásico de algoritmo cuya corrección solo se ve escribiendo el invariante.

**03 → 12.** Diseña cómo obtener la suma máxima de un subarreglo de longitud al menos `L`, con su coste. 🔴

⏱️ **30 segundos.** Con prefijos: la suma de `a[i..j−1]` es `P[j] − P[i]`, y con longitud al menos `L`, `i ≤ j − L`. Para cada `j`, se resta el mínimo de `P[0..j−L]`, que se lleva acumulado. `O(n)` tiempo.

🗣️ **2 minutos.** Recorre `j` de `L` a `n`; antes de usar `j`, actualiza `minPrefijo = min(minPrefijo, P[j − L])`; la mejor suma que termina en `j − 1` con longitud `≥ L` es `P[j] − minPrefijo`. El máximo de esas es la respuesta.

🔬 **El detalle.** Es el «mínimo acumulado» de [`01/06`](../01-oficio-del-competidor/06-protocolo-de-resolucion.md) aplicado a prefijos, con un retraso de `L` posiciones. Con «longitud como mucho `L`», el mínimo es de una ventana y hace falta una cola monótona (`06/01`). Es el problema propio «Al menos L días».

**03 → 13.** El divide y vencerás del subarreglo máximo: escribe su recurrencia, resuélvela y explica qué calcula el paso de combinar. 🔴

⏱️ **30 segundos.** `T(n) = 2T(n/2) + Θ(n)`, que es `Θ(n log n)`. El paso de combinar calcula el mejor tramo que cruza el centro: la mejor suma que termina en el centro por la izquierda más la mejor que empieza en él por la derecha.

🗣️ **2 minutos.** El subarreglo máximo está entero en la mitad izquierda, entero en la derecha o cruza el centro. Los dos primeros son las llamadas recursivas; el tercero se calcula en `Θ(n)` recorriendo desde el centro hacia cada lado y acumulando el mejor. Por el teorema maestro, caso 2 ([`02/02`](../02-analisis/02-recurrencias-y-teorema-maestro.md)).

🔬 **El detalle.** Kadane es `Θ(n)` y más simple; el divide y vencerás se estudia porque ilustra la técnica, y porque se puede mejorar a `Θ(n)` haciendo que cada llamada devuelva también el mejor prefijo, el mejor sufijo y el total. CLRS, 3.ª ed., §4.1.

**03 → Problema: El mejor periodo, con desempate.**

- **Pista 2 — patrón:** **Kadane con reconstrucción** y una regla de desempate explícita.
- **Pista 3 — diseño:** lleva el inicio del tramo actual; empieza de nuevo cuando `cur + a[i] < a[i]` (con `≤` empezarías de nuevo también en empates, que alarga menos pero cambia el inicio); actualiza el mejor si la suma es mayor, o si es igual con inicio más temprano, o igual inicio y menor longitud. Comprueba la regla con los tres ejemplos.

**03 → Problema: Al menos L días.**

- **Pista 2 — patrón:** **prefijos con el mínimo acumulado retrasado `L` posiciones**.
- **Pista 3 — diseño:** para cada final `j` desde `L`, el mejor inicio es el de prefijo mínimo entre `P[0..j−L]`; lleva ese mínimo actualizándolo con `P[j − L]` antes de usarlo; la respuesta es el máximo de `P[j] − mínimo`, en 64 bits.

**03 → Problema: Restos de los tramos.**

- **Pista 2 — patrón:** **prefijos módulo `m` con un mapa de conteos**.
- **Pista 3 — diseño:** el tramo entre dos prefijos tiene resto `(P[j] − P[i]) mod m`; para cada `j`, cuenta cuántos prefijos anteriores tienen resto `(P[j] − r) mod m`, normalizado a `[0, m)`; registra el resto de `P[j]` después de contar; empieza con el prefijo vacío.

**03 → Problema: MaxSliceSum.**

- **Pista 2 — patrón:** **Kadane** sin tramo vacío.
- **Pista 3 — diseño:** `best = A[0]`, `cur = max(x, cur + x)`; devuelve `best`.

**03 → Problema: MaxProfit.**

- **Pista 2 — patrón:** **mínimo acumulado** (o Kadane sobre las diferencias diarias).
- **Pista 3 — diseño:** recorre llevando el menor precio visto; la ganancia de vender hoy es el precio menos ese mínimo; si nunca hay ganancia, 0.

**03 → Problema: Best Time to Buy and Sell Stock.**

- **Pista 2 — patrón:** **mínimo acumulado**.
- **Pista 3 — diseño:** el mismo recorrido: la mejor ganancia vendiendo en `i` es `prices[i]` menos el mínimo de los anteriores; actualiza el mínimo después de usarlo.

**03 → Problema: MaxDoubleSliceSum.**

- **Pista 2 — patrón:** **Kadane hacia la derecha y hacia la izquierda**, combinados en el elemento central.
- **Pista 3 — diseño:** `izq[i]` = mejor suma (con 0 permitido) de un tramo que termina en `i − 1` y empieza después del extremo `X`; `der[i]` = lo mismo hacia la derecha; la respuesta es el máximo de `izq[Y] + der[Y]` para cada centro `Y`.

**03 → Problema: Maximum Sum Circular Subarray.**

- **Pista 2 — patrón:** **Kadane circular**: el máximo o el total menos el mínimo.
- **Pista 3 — diseño:** dos Kadane en una pasada (máximo y mínimo) y el total; si el máximo es negativo, devuélvelo; si no, el mayor entre él y `total − mínimo`.

**03 → Problema: Maximum Product Subarray.**

- **Pista 2 — patrón:** **Kadane con dos estados**: el mayor y el menor producto que terminan en `i`.
- **Pista 3 — diseño:** al llegar `x`, los nuevos máximo y mínimo salen de `x`, `max·x` y `min·x` (un negativo intercambia los papeles); la respuesta es el mayor máximo visto.

**03 → Problema: Subarray Sum Equals K.**

- **Pista 2 — patrón:** **prefijos con un mapa de frecuencias**.
- **Pista 3 — diseño:** el mapa empieza con `{0: 1}`; para cada prefijo, suma las apariciones de `prefijo − k` y después registra el prefijo.

**03 → Problema: The Maximum Subarray.**

- **Pista 2 — patrón:** **Kadane** para el contiguo y **suma de positivos** para la subsecuencia.
- **Pista 3 — diseño:** el subarreglo, con Kadane sin tramo vacío; la subsecuencia, sumando todos los positivos, o el mayor elemento si no hay ninguno.

**03 → Problema: Maximum Subarray Sum.**

- **Pista 2 — patrón:** **Kadane**.
- **Pista 3 — diseño:** la plantilla en 64 bits, porque la suma llega a `2·10¹⁴`; con E/S rápida.

**03 → Problema: Subarray Divisibility.**

- **Pista 2 — patrón:** **prefijos módulo `n`** con conteo de restos.
- **Pista 3 — diseño:** un arreglo de `n` contadores de restos (normalizados a `[0, n)`), empezando con el resto 0 contado una vez; cada prefijo suma los anteriores con su mismo resto.

**03 → Problema: Subarray Sums Divisible by K.**

- **Pista 2 — patrón:** **prefijos módulo `k`**.
- **Pista 3 — diseño:** el mismo conteo con `k` contadores; en Java y C++, normaliza el resto de los prefijos negativos con `((p % k) + k) % k`.

---

# 04 — Compresión de coordenadas y barrido de eventos

**04 → 1.** ¿Qué conserva y qué pierde la compresión de coordenadas? 🟢

⏱️ **30 segundos.** Conserva el orden y la igualdad entre valores; pierde las distancias.

🗣️ **2 minutos.** Cada valor pasa a ser su posición en la lista ordenada de distintos: `x < y` si y solo si sus rangos cumplen lo mismo. Pero el rango no sabe cuánto espacio había entre dos valores: 5 y `10⁹` pueden quedar como 1 y 2.

🔬 **El detalle.** Si el problema mide longitudes (la unión de intervalos, el tiempo con al menos `k` reuniones), las distancias se recuperan de la lista de distintos: el tramo entre los rangos `i` e `i + 1` mide `distintos[i+1] − distintos[i]`.

**04 → 2.** ¿Qué dos eventos genera cada intervalo en un barrido? 🟢

⏱️ **30 segundos.** Una apertura en el inicio, que suma uno, y un cierre en el final, que resta uno.

🗣️ **2 minutos.** El barrido ordena todos los eventos por instante y los procesa en orden, llevando un contador de intervalos abiertos. Entre dos eventos consecutivos, el contador no cambia.

🔬 **El detalle.** Los eventos pueden llevar más información que ±1: el peso del intervalo (pasajeros en Car Pooling), su identificador para insertarlo o quitarlo de una estructura, o el tipo de punto en geometría.

**04 → 3.** ¿Qué orden de empates usas con intervalos semiabiertos, y cuál con cerrados? 🟢

⏱️ **30 segundos.** Con semiabiertos `[s, e)`, los cierres antes que las aperturas en el mismo instante; con cerrados `[s, e]`, las aperturas antes que los cierres.

🗣️ **2 minutos.** Un semiabierto que termina en 3 ya no contiene el 3, así que no coincide con uno que empieza en 3: hay que quitarlo antes de añadir el otro. Un cerrado sí contiene el 3, así que los dos tienen que contarse a la vez.

🔬 **El detalle.** Con pares `(instante, delta)` y orden natural, `−1` va antes que `+1`: es el orden de los semiabiertos. Para cerrados basta con codificar la apertura como `−1` y el cierre como `+1`, o ordenar por `(t, −delta)`.

**04 → 4.** ¿Qué diferencia hay entre barrer eventos y usar un arreglo de diferencias indexado por instante? 🟡

⏱️ **30 segundos.** El arreglo de diferencias necesita una posición por instante posible; el barrido solo procesa los `2n` instantes donde algo cambia. Con instantes hasta `10⁹`, el arreglo no cabe y el barrido sí.

🗣️ **2 minutos.** Las dos calculan lo mismo: el contador en cada instante es la suma de las diferencias hasta ahí. El arreglo recorre todos los instantes, `O(n + T)`; el barrido ordena los eventos, `O(n log n)`. Con `T` pequeño, el arreglo es más simple y no necesita ordenar.

🔬 **El detalle.** Comprimir los instantes y usar el arreglo de diferencias sobre los rangos es la tercera forma, equivalente al barrido.

**04 → 5.** ¿Qué diferencia hay entre fusionar con `<` y con `≤` en la unión de intervalos? 🟡

⏱️ **30 segundos.** Con `<`, dos intervalos que solo se tocan (`[1,3)` y `[3,5)`) quedan en bloques distintos; con `≤`, se fusionan.

🗣️ **2 minutos.** La comparación codifica qué dice el enunciado de los extremos. Con semiabiertos y la pregunta «¿se solapan?», `<`. Con cerrados, o si lo que se pide es la cobertura continua («¿hay huecos?»), `≤`, porque `[1,3]` y `[3,5]` comparten el 3.

🔬 **El detalle.** Con enteros y cerrados, a veces se quiere fusionar también `[1,3]` y `[4,5]`, porque no hay entero libre entre ellos: la condición pasa a ser `s ≤ e_anterior + 1`.

**04 → 6.** ¿Por qué ordenar por inicio garantiza que un intervalo solo puede solaparse con el último bloque fusionado? 🟡

⏱️ **30 segundos.** Porque todos los bloques anteriores al último terminaron antes de que empezara el último, y el siguiente intervalo empieza después que todos: no puede llegar a ellos.

🗣️ **2 minutos.** Invariante: los bloques fusionados son disjuntos, ordenados, y cada uno termina antes de que empiece el siguiente. Un intervalo nuevo empieza en un instante `≥` que todos los inicios anteriores; si no alcanza al último bloque, tampoco alcanza a los anteriores, que terminan antes.

🔬 **El detalle.** La prueba usa que se ordenó por **inicio**. Ordenar por final no garantiza lo mismo: `[5,6)` puede ir antes que `[1,10)`.

**04 → 7.** Compara cómo quitas repetidos tras ordenar en C++, Java y Python, y la trampa de cada forma. 🟡

⏱️ **30 segundos.** En C++, `sort` más `unique` y `erase`; en Java, un recorrido que compacta los distintos; en Python, `sorted(set(a))`. La trampa de C++ es olvidar el `erase`; la de Java, usar `binarySearch` sobre una lista con repetidos.

🗣️ **2 minutos.** `std::unique` no borra: mueve los distintos al principio y devuelve el nuevo final lógico; sin `erase`, el `vector` conserva basura al final. En Java no hay `unique`, y si se busca con `binarySearch` en el arreglo con repetidos, devuelve algún índice entre los iguales. `set` en Python es lo más corto, a costa de crear un conjunto.

🔬 **El detalle.** En Python, un `dict` de valor a rango hace cada consulta `O(1)` esperado; en C++ y Java, una búsqueda binaria por consulta, `O(log n)`.

**04 → 8.** Demuestra que la compresión no cambia el resultado de un algoritmo que solo compara valores. 🟠

⏱️ **30 segundos.** Porque el algoritmo solo observa los valores a través de comparaciones, y `rank` es una biyección que conserva el resultado de toda comparación: la ejecución sobre los rangos toma las mismas decisiones.

🗣️ **2 minutos.** Por inducción sobre los pasos del algoritmo: si en cada paso se comparan dos valores `x` e `y`, sobre los rangos se comparan `rank(x)` y `rank(y)`, con el mismo resultado; así que el siguiente paso es el mismo en las dos ejecuciones. La salida, si depende solo de esas decisiones y de los índices, es idéntica.

🔬 **El detalle.** Falla si el algoritmo hace aritmética con los valores (sumas, diferencias, medias): ahí la compresión cambia el resultado y hay que usar los valores originales para esas operaciones.

**04 → 9.** Un barrido da 3 reuniones a la vez y la respuesta esperada es 2. ¿Qué miras primero? 🟠

⏱️ **30 segundos.** El orden de los empates: con intervalos semiabiertos, un cierre y una apertura en el mismo instante se están procesando con la apertura primero.

🗣️ **2 minutos.** Un contador que sube a 3 en el instante donde una reunión termina y otra empieza es el síntoma típico. Se comprueba mirando el comparador de eventos y la codificación de los deltas, y probando con `[1,3) [3,5) [2,4)`, que da 2 bien ordenado y 3 mal ordenado.

🔬 **El detalle.** Si el enunciado dice extremos cerrados, el 3 es la respuesta correcta y el error estaría al revés. Leer los extremos del enunciado es el primer paso.

**04 → 10.** ¿Por qué el final del bloque fusionado es el máximo de los finales y no el del último intervalo? Da un ejemplo. 🟠

⏱️ **30 segundos.** Porque un intervalo anterior puede terminar más tarde que el siguiente: con `[1,10)` y luego `[2,3)`, el bloque es `[1,10)`, no `[1,3)`.

🗣️ **2 minutos.** Los intervalos están ordenados por inicio, no por final. Un intervalo largo puede contener a varios de los siguientes; si el final del bloque se sustituyera por el del último fusionado, se acortaría y se perdería cobertura.

🔬 **El detalle.** El error típico es `out.back().second = e` en vez de `max(out.back().second, e)`. Pasa los ejemplos con intervalos que se encadenan y falla con uno que contiene a otro.

**04 → 11.** Diseña cómo contar, para cada elemento de un arreglo con valores hasta `10⁹`, cuántos elementos a su derecha son menores, con su coste. 🔴

⏱️ **30 segundos.** Comprimo los valores a `[0, k)`, recorro de derecha a izquierda, y para cada elemento consulto en un Fenwick cuántos valores con rango menor ya vi, y después lo inserto. `O(n log n)`.

🗣️ **2 minutos.** Los «elementos a la derecha» son los ya vistos al recorrer de derecha a izquierda. Contar los menores es una suma de prefijo sobre un arreglo de conteos indexado por rango, que con valores de `10⁹` solo cabe comprimido. El Fenwick da la suma de prefijo y la inserción en `O(log n)` (`09/02`).

🔬 **El detalle.** La alternativa es la ordenación por mezcla contando durante la mezcla (`05/03`), que no necesita compresión. Las dos son `O(n log n)`.

**04 → 12.** Demuestra el teorema del orden de los empates para intervalos semiabiertos. 🔴

⏱️ **30 segundos.** Tras procesar todos los eventos de los instantes `≤ t`, el contador es el número de intervalos `[s, e)` con `s ≤ t < e`, es decir, los que contienen a `t`. Procesar los cierres primero hace que en ningún momento intermedio se cuenten a la vez uno que termina en `t` y otro que empieza en `t`.

🗣️ **2 minutos.** El máximo se toma después de cada evento, incluidos los intermedios de un mismo instante. Si en `t` hay cierres y aperturas, procesar primero los cierres hace que el contador baje antes de subir, y el valor más alto alcanzado en `t` es exactamente el número de intervalos que contienen a `t`. Con las aperturas primero, habría un valor intermedio que cuenta intervalos que no coexisten en ningún instante.

🔬 **El detalle.** Para cerrados el argumento es el simétrico: un intervalo `[s, e]` sigue conteniendo a `e`, y hay que añadir los que empiezan en `e` antes de quitar los que terminan.

**04 → Problema: Puntos cubiertos.**

- **Pista 2 — patrón:** **unión de intervalos** cerrados, con la longitud en enteros.
- **Pista 3 — diseño:** ordena por inicio y fusiona cuando `s ≤ e_bloque` (o `≤ e_bloque + 1` si quieres unir los que se tocan sin hueco entero); cada bloque `[s, e]` aporta `e − s + 1`; el total llega a `10⁹ + 1`, en 64 bits si sumas varios.

**04 → Problema: Hora punta con empates.**

- **Pista 2 — patrón:** **barrido de eventos** con la regla de empates de los intervalos cerrados.
- **Pista 3 — diseño:** eventos `(t, abre)` y `(t, cierra)` ordenados por instante con las aperturas primero; actualiza el máximo después de cada apertura y guarda el instante solo cuando el contador supera estrictamente el máximo anterior, para quedarte con el primero.

**04 → Problema: Pintar la valla.**

- **Pista 2 — patrón:** **compresión** de los extremos y tramos elementales.
- **Pista 3 — diseño:** reúne y ordena todos los `l` y `r`; cada par de extremos consecutivos es un tramo elemental; su color es el de la última operación que lo cubre (recorriendo las operaciones al revés, la primera que lo cubre); suma su longitud real a ese color. Con `q ≤ 2000`, recorrer operaciones por tramo cabe.

**04 → Problema: Rank Transform of an Array.**

- **Pista 2 — patrón:** **compresión** con rangos desde 1.
- **Pista 3 — diseño:** ordena los valores distintos; el rango de cada valor es su posición más uno; con un mapa o con búsqueda binaria.

**04 → Problema: Merge Intervals.**

- **Pista 2 — patrón:** **ordenar por inicio y fusionar** con el último bloque.
- **Pista 3 — diseño:** aquí los extremos son cerrados (`[1,4]` y `[4,5]` se fusionan): la condición es `s ≤ final del bloque`, y el final pasa a ser el máximo.

**04 → Problema: Insert Interval.**

- **Pista 2 — patrón:** **unión** aprovechando que la lista ya está ordenada y es disjunta.
- **Pista 3 — diseño:** copia los intervalos que terminan antes del nuevo; fusiona con el nuevo todos los que lo tocan (actualizando inicio mínimo y final máximo); copia el resto.

**04 → Problema: Interval List Intersections.**

- **Pista 2 — patrón:** **dos punteros** sobre dos listas de intervalos ordenadas.
- **Pista 3 — diseño:** la intersección de los dos actuales es `[max inicios, min finales]` si no es vacía; después avanza el que termina antes, que ya no puede cruzarse con nada más de la otra lista.

**04 → Problema: Car Pooling.**

- **Pista 2 — patrón:** **barrido** (o diferencias, porque las paradas son pequeñas) con pesos.
- **Pista 3 — diseño:** en cada parada, los que bajan antes que los que suben (el pasajero baja en `to` y su asiento queda libre); suma pasajeros al subir y resta al bajar; si en algún momento pasa de la capacidad, `false`.

**04 → Problema: NumberOfDiscIntersections.**

- **Pista 2 — patrón:** **barrido** de extremos con contador de discos abiertos.
- **Pista 3 — diseño:** eventos de apertura en `i − A[i]` y de cierre en `i + A[i]` (en 64 bits), con las aperturas antes que los cierres en empate porque los discos cerrados se tocan; al abrir uno, suma los abiertos; si pasa de `10⁷`, `−1`.

**04 → Problema: Salary Queries.**

- **Pista 2 — patrón:** **compresión de todos los valores posibles** (iniciales y de las actualizaciones) y **Fenwick de conteos**.
- **Pista 3 — diseño:** lee todas las consultas antes de responder para conocer todos los salarios que aparecerán; comprímelos; un cambio de salario resta 1 en el rango viejo y suma 1 en el nuevo; una consulta `[a, b]` es una diferencia de prefijos en el Fenwick, con los rangos de `a` y `b` por búsqueda binaria.

**04 → Problema: Count of Smaller Numbers After Self.**

- **Pista 2 — patrón:** **compresión + Fenwick** recorriendo de derecha a izquierda, o mezcla con conteo.
- **Pista 3 — diseño:** comprime; de derecha a izquierda, la respuesta de `i` es la suma de prefijo hasta `rank(a[i]) − 1`; después suma 1 en `rank(a[i])`.

**04 → Problema: Number of Flowers in Full Bloom.**

- **Pista 2 — patrón:** **dos listas ordenadas y búsqueda binaria** (un barrido con consultas).
- **Pista 3 — diseño:** ordena los inicios y los finales por separado; para cada persona en el instante `t`, las flores abiertas son las que empezaron en `t` o antes menos las que terminaron antes de `t`: `upper_bound(inicios, t) − lower_bound(finales, t)`.

---

# 05 — Matrices

**05 → 1.** ¿Qué dos operaciones componen una rotación de 90° en sentido horario? 🟢

⏱️ **30 segundos.** Transponer (`(i, j) → (j, i)`) y después reflejar cada fila (`(i, j) → (i, n−1−j)`).

🗣️ **2 minutos.** La composición lleva `(i, j)` a `(j, n−1−i)`, que es exactamente el giro horario. Las dos operaciones son intercambios de pares, así que se hacen en el sitio sin matriz auxiliar.

🔬 **El detalle.** El giro antihorario es la composición en el otro orden (reflejar filas y después transponer), o transponer y reflejar las columnas. Girar 180° es reflejar filas y columnas.

**05 → 2.** ¿Desde qué esquina empieza la búsqueda en escalera, y por qué esa? 🟢

⏱️ **30 segundos.** Desde la superior derecha (o la inferior izquierda): ahí el valor es el mayor de su fila y el menor de su columna, así que cada comparación descarta una fila o una columna.

🗣️ **2 minutos.** Si el valor de la esquina es mayor que el buscado, toda su columna hacia abajo también lo es: se descarta la columna. Si es menor, toda su fila hacia la izquierda también lo es: se descarta la fila. Los dos casos reducen el problema.

🔬 **El detalle.** Desde la inferior izquierda el argumento es simétrico: el valor es el menor de su fila y el mayor de su columna.

**05 → 3.** ¿Qué guardan los tres arreglos del formato CSR? 🟢

⏱️ **30 segundos.** `values` y `cols` con los valores no nulos y su columna, ordenados por fila; y `rowStart`, de tamaño `R + 1`, que dice dónde empieza cada fila en los otros dos.

🗣️ **2 minutos.** Los valores de la fila `i` ocupan las posiciones `[rowStart[i], rowStart[i+1])`. `rowStart` es un arreglo de prefijos del número de celdas por fila. Con eso, recorrer una fila es un tramo contiguo y multiplicar por un vector es un recorrido lineal.

🔬 **El detalle.** CSC es el mismo formato por columnas. Las bibliotecas numéricas usan uno u otro según si la operación dominante recorre filas o columnas.

**05 → 4.** ¿Qué diferencia hay entre una matriz con filas y columnas ordenadas y una cuya versión aplanada está ordenada, en cómo se busca? 🟡

⏱️ **30 segundos.** Con filas y columnas crecientes se usa la escalera, `O(R + C)`; si la matriz aplanada está ordenada (cada fila empieza después de que termine la anterior), una sola búsqueda binaria sobre `R · C` posiciones, `O(log(R·C))`.

🗣️ **2 minutos.** La segunda condición es más fuerte: implica la primera. Con ella, la posición `k` del arreglo aplanado es la celda `(k / C, k mod C)`, y la búsqueda binaria trabaja sobre `k` sin construir nada.

🔬 **El detalle.** Con solo la primera condición, la binaria global no sirve, porque el último de una fila puede ser mayor que el primero de la siguiente.

**05 → 5.** ¿Por qué la transposición en el sitio recorre solo el triángulo superior? 🟡

⏱️ **30 segundos.** Porque intercambiar `m[i][j]` con `m[j][i]` para todo par `(i, j)` intercambia cada par dos veces —una desde cada lado— y deja la matriz como estaba.

🗣️ **2 minutos.** Recorriendo solo `j > i` (el triángulo superior), cada pareja de posiciones simétricas se visita una vez. La diagonal (`i = j`) no se mueve.

🔬 **El detalle.** Es el mismo error que invertir un arreglo recorriéndolo entero: hay que parar en la mitad.

**05 → 6.** ¿Qué diferencia hay entre un mapa de coordenadas y CSR, y para qué operación es mejor cada uno? 🟡

⏱️ **30 segundos.** El mapa de coordenadas da acceso y modificación de una celda en `O(1)` esperado; CSR da recorridos por fila y multiplicación por un vector en `O(R + nnz)`, pero modificar su estructura es caro.

🗣️ **2 minutos.** El mapa no tiene orden ni localidad: recorrer una fila exige buscar sus celdas. CSR guarda cada fila contigua, ideal para operaciones que recorren, y casi imposible de modificar sin reconstruir. Lo habitual es construir con un mapa o con tripletas y convertir a CSR para calcular.

🔬 **El detalle.** Las listas múltiples de Brassard y Bratley permiten recorrer filas y columnas y modificar, a costa de punteros por celda.

**05 → 7.** Compara cómo escribes los cuatro vecinos de una celda en C++, Java y Python con arreglos de direcciones. 🟡

⏱️ **30 segundos.** En los tres, dos arreglos `DR` y `DC` (o una lista de pares) y un bucle de cuatro vueltas con una sola comprobación de bordes. En C++ y Java son arreglos constantes; en Python, una tupla de pares y un generador.

🗣️ **2 minutos.** C++ puede recibir una lambda que procese cada vecino; Java suele escribir el bucle en línea; Python con un generador `yield` queda corto y legible. La comprobación es `0 <= nr < R and 0 <= nc < C` en Python, que permite la comparación encadenada.

🔬 **El detalle.** Para ocho vecinos se amplían los arreglos a ocho pares, sin cambiar nada más. En rejillas grandes se codifica la celda como `r · C + c` para guardarla en un solo entero.

**05 → 8.** ¿Por qué buscar desde la esquina superior izquierda no permite descartar nada? 🟡

⏱️ **30 segundos.** Porque desde la superior izquierda los valores crecen en las dos direcciones: si el valor es menor que el buscado, no sabes si bajar o ir a la derecha, y no se descarta ninguna línea.

🗣️ **2 minutos.** La escalera funciona porque en su esquina una dirección sube y la otra baja: cada comparación decide sin ambigüedad. En la superior izquierda, las dos suben, y la comparación no distingue entre ellas.

🔬 **El detalle.** Lo mismo pasa desde la inferior derecha, donde las dos direcciones bajan.

**05 → 9.** Demuestra que la búsqueda en escalera hace como mucho `R + C − 1` comparaciones y que no se salta el valor. 🟠

⏱️ **30 segundos.** Cada paso descarta una fila o una columna, y hay `R` filas y `C` columnas: como mucho `R + C − 1` pasos antes de salirse. Y no se salta el valor porque lo descartado nunca puede contenerlo.

🗣️ **2 minutos.** Invariante: si `x` está, está en las filas `≥ i` y las columnas `≤ j`. Si `M[i][j] > x`, la columna `j` desde `i` hacia abajo es `> x` por las columnas crecientes, y no lo contiene: se puede bajar `j`. Si `M[i][j] < x`, la fila `i` hasta `j` es `< x`, y no lo contiene: se puede subir `i`. Cuando `i` o `j` se salen, la región es vacía y `x` no está.

🔬 **El detalle.** La función de cota es `(R − i) + (j + 1)`, que baja en uno en cada paso: es la terminación del invariante, como en `02/04`.

**05 → 10.** ¿Por qué la espiral necesita comprobar `top <= bottom` antes del tercer lado? Da una matriz que falla sin la comprobación. 🟠

⏱️ **30 segundos.** Porque tras recorrer la primera fila y la última columna, puede no quedar ninguna fila; sin la comprobación, el tercer lado recorre de nuevo la fila que ya se recorrió. Falla con una matriz de una sola fila, como `[[1, 2, 3]]`.

🗣️ **2 minutos.** Con `[[1, 2, 3]]`: el primer lado da `1 2 3` y `top` pasa a 1; el segundo no hace nada (`top > bottom`) y `right` pasa a 1; sin comprobar, el tercer lado recorre `m[0]` de `right` a `left` y añade `2 1`. Con la comprobación, se termina.

🔬 **El detalle.** El cuarto lado tiene el problema simétrico con una sola columna, como `[[1], [2], [3]]`.

**05 → 11.** Diseña cómo multiplicar dos matrices dispersas de `10⁶ × 10⁶` con `2·10⁵` valores cada una, y su coste en función de las celdas no nulas. 🔴

⏱️ **30 segundos.** Con la primera en CSR y la segunda también en CSR: para cada fila `i` de `A` y cada no nulo `A[i][k]`, recorrer la fila `k` de `B` y acumular `A[i][k] · B[k][j]` en un acumulador disperso de la fila `i`. El coste es la suma, sobre los no nulos de `A`, del tamaño de la fila correspondiente de `B`.

🗣️ **2 minutos.** Es el algoritmo de Gustavson: no toca ninguna celda nula. El acumulador de una fila puede ser un mapa o un arreglo denso de `C` posiciones con una lista de columnas tocadas para limpiarlo. El coste depende de la estructura: en el peor caso, una fila densa de `A` contra muchas filas densas de `B`, puede acercarse a `nnz²`.

🔬 **El detalle.** El resultado puede ser mucho más denso que las entradas. Antes de multiplicar conviene estimar el número de no nulos del resultado.

**05 → 12.** Escribe en palabras cómo girar una matriz rectangular `R × C` (no cuadrada), y por qué no se puede en el sitio con el mismo truco. 🔴

⏱️ **30 segundos.** El elemento `(i, j)` de una `R × C` va a la posición `(j, R−1−i)` de una `C × R`. Hay que crear la matriz nueva: no se puede en el sitio con transponer y reflejar, porque la forma cambia.

🗣️ **2 minutos.** El truco en el sitio supone que la matriz y su transpuesta tienen la misma forma. Con `R ≠ C`, la transpuesta es otra matriz. Con la matriz guardada como un arreglo plano de `R · C`, se puede hacer en el sitio siguiendo los ciclos de la permutación de posiciones, pero es complicado y casi nunca compensa.

🔬 **El detalle.** La transposición en el sitio de una matriz rectangular plana es un problema clásico (los ciclos de `k → k · R mod (R·C − 1)`), útil en bibliotecas numéricas con memoria escasa.

**05 → Problema: Picos de la rejilla.**

- **Pista 2 — patrón:** **recorrido con arreglos de direcciones**.
- **Pista 3 — diseño:** para cada celda, recorre sus cuatro vecinos con `DR` y `DC` y una sola comprobación de bordes; es pico si ningún vecino existente es mayor o igual. `O(R·C)`, con E/S rápida para `10⁶` valores.

**05 → Problema: Girar k veces.**

- **Pista 2 — patrón:** **rotación en el sitio** con `k` reducido módulo 4.
- **Pista 3 — diseño:** cuatro giros devuelven la matriz original: aplica `k mod 4` giros (transponer y reflejar filas cada uno); `k` llega a `10¹⁸`, así que se lee en 64 bits antes de reducir.

**05 → Problema: Dispersa por un vector.**

- **Pista 2 — patrón:** **representación dispersa** con las filas en un mapa (o comprimidas).
- **Pista 3 — diseño:** acumula `valor · x[columna]` en un mapa de fila a suma (o comprime las filas presentes y usa un arreglo); recorre las filas en orden e imprime las de suma distinta de cero. Las sumas llegan a `2·10⁵ · 10⁸`: 64 bits.

**05 → Problema: Diagonal Difference.**

- **Pista 2 — patrón:** **índices de las diagonales**: `i = j` y `i + j = n − 1`.
- **Pista 3 — diseño:** un recorrido de `i` sumando `m[i][i]` y `m[i][n−1−i]`; la respuesta es el valor absoluto de la diferencia.

**05 → Problema: Toeplitz Matrix.**

- **Pista 2 — patrón:** **comparar cada celda con su vecina de arriba a la izquierda**.
- **Pista 3 — diseño:** para todo `i, j ≥ 1`, comprueba `m[i][j] == m[i−1][j−1]`.

**05 → Problema: Reshape the Matrix.**

- **Pista 2 — patrón:** **índice plano** compartido por las dos formas.
- **Pista 3 — diseño:** si `R·C ≠ r·c`, devuelve la original; si no, la celda `k`-ésima por filas está en `(k / C, k mod C)` en la original y va a `(k / c, k mod c)` en la nueva.

**05 → Problema: Flood Fill.**

- **Pista 2 — patrón:** **recorrido de la región** con vecinos en cuatro direcciones (DFS o BFS, [`14/02`](../14-grafos-recorridos/02-bfs.md)).
- **Pista 3 — diseño:** si el color nuevo coincide con el viejo, devuelve la imagen tal cual (si no, el recorrido no termina); si no, pinta y visita los vecinos con el color viejo.

**05 → Problema: CyclicRotation.**

- **Pista 2 — patrón:** **rotación con módulo**.
- **Pista 3 — diseño:** el elemento `i` va a `(i + K) mod N`; con el arreglo vacío, devuélvelo tal cual.

**05 → Problema: Search a 2D Matrix.**

- **Pista 2 — patrón:** **búsqueda binaria sobre la matriz aplanada**.
- **Pista 3 — diseño:** busca en `[0, R·C)` con la celda `(k / C, k mod C)`; no hace falta construir el arreglo plano.

**05 → Problema: Spiral Matrix II.**

- **Pista 2 — patrón:** **espiral con cuatro fronteras**, escribiendo en vez de leyendo.
- **Pista 3 — diseño:** el mismo esquema que la plantilla, con un contador que va de 1 a `n²` y se escribe en cada celda recorrida.

**05 → Problema: Diagonal Traverse.**

- **Pista 2 — patrón:** **recorrido por diagonales** `i + j = d`, alternando el sentido.
- **Pista 3 — diseño:** para cada `d` de 0 a `R + C − 2`, las celdas con `i + j = d` van de `(max(0, d − C + 1), …)` a `(min(d, R − 1), …)`; en las `d` pares se recorren subiendo y en las impares bajando.

**05 → Problema: Game of Life.**

- **Pista 2 — patrón:** **vecinos en ocho direcciones** con dos estados por celda en el sitio.
- **Pista 3 — diseño:** codifica en cada celda el estado viejo en el bit 0 y el nuevo en el bit 1; cuenta los vecinos vivos mirando solo el bit 0; al final, desplaza todo un bit a la derecha.

**05 → Problema: Kth Smallest Element in a Sorted Matrix.**

- **Pista 2 — patrón:** **búsqueda binaria sobre el valor** con un conteo en escalera.
- **Pista 3 — diseño:** para un valor `v`, cuenta las celdas `≤ v` recorriendo desde la esquina inferior izquierda en `O(n)`; busca el menor `v` con conteo `≥ k` ([`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)). O un montículo de las cabezas de fila.

**05 → Problema: Counting Rooms.**

- **Pista 2 — patrón:** **componentes en una rejilla**: recorrer cada región libre una vez.
- **Pista 3 — diseño:** recorre todas las celdas; cada vez que encuentres una libre sin visitar, cuenta una habitación y márcala con todas las conectadas por un BFS o un DFS iterativo (`14/02`); con `10⁶` celdas, la recursión profunda es un riesgo.

**05 → Problema: Matrix Layer Rotation.**

- **Pista 2 — patrón:** **capas como anillos** que rotan por separado.
- **Pista 3 — diseño:** extrae cada capa como una lista en el orden del recorrido, rótala `r mod (longitud de la capa)` posiciones y vuelve a escribirla en el mismo orden.

---

# 06 — Simulación

**06 → S1.** ¿Qué fórmula da la suma de `a[l..r]` con prefijos, y por qué el arreglo tiene `n + 1` posiciones? 🟢

⏱️ **30 segundos.** `P[r + 1] − P[l]`. `P` tiene `n + 1` posiciones con `P[0] = 0` para que el prefijo vacío exista y los rangos que empiezan en 0 no sean un caso especial.

🗣️ **2 minutos.** `P[k]` es la suma de los `k` primeros; la diferencia entre los `r + 1` primeros y los `l` primeros es exactamente `a[l..r]`. Es la suma telescópica de [`04/01`](01-prefijos-y-diferencias.md).

🔬 **El detalle.** Los prefijos van en 64 bits: con `2·10⁵` valores de `10⁹` llegan a `2·10¹⁴`.

**06 → S2.** ¿Cuándo usas diferencias y cuándo un Fenwick para sumas por rango? 🟡

⏱️ **30 segundos.** Diferencias si todas las escrituras van antes que todas las lecturas; Fenwick si se mezclan.

🗣️ **2 minutos.** Con diferencias, cada escritura es `O(1)` pero leer exige reconstruir en `O(n)`. Un Fenwick mantiene los prefijos de las diferencias: escrituras y lecturas en `O(log n)`.

🔬 **El detalle.** Ver `04/01`, §4, y `09/02`.

**06 → S3.** ¿Por qué los prefijos no sirven para el máximo de un rango? 🟡

⏱️ **30 segundos.** Porque el máximo no tiene operación inversa: los máximos de dos prefijos no permiten deducir el de su diferencia.

🗣️ **2 minutos.** Los prefijos funcionan con operaciones de grupo (suma, XOR). El máximo es asociativo pero no invertible. Para máximos de rango sobre datos fijos, la *sparse table* (`09/01`).

🔬 **El detalle.** Lo que sí funciona con el máximo son los prefijos de máximos para rangos que **empiezan en 0**, sin resta.

**06 → S4.** ¿Qué propiedad necesita una condición para que la ventana variable sea correcta? 🟢

⏱️ **30 segundos.** Que sea monótona respecto de la inclusión: si un tramo cumple, todos sus subtramos cumplen.

🗣️ **2 minutos.** Con esa propiedad, un inicio descartado no vuelve a ser válido con un final mayor, y el inicio solo avanza. «Suma `≤ S` con valores no negativos» la tiene; «suma exacta» con negativos, no.

🔬 **El detalle.** Ver el teorema de `04/02`, §2.

**06 → S5.** ¿Por qué un `while` dentro de un `for` en una ventana es `O(n)`? 🟡

⏱️ **30 segundos.** Porque el índice que avanza dentro del `while` nunca retrocede: en todo el programa se mueve como mucho `n` veces.

🗣️ **2 minutos.** Es el análisis agregado de `02/03`: se cuentan los movimientos totales de cada índice, no los de cada vuelta. Dos índices de `n` movimientos cada uno son `2n` pasos.

🔬 **El detalle.** Si el índice interno se reinicia en cada vuelta, el mismo código es `O(n²)`.

**06 → S6.** Da un ejemplo de tres elementos en el que la ventana para «suma `≥ S`» falla por los negativos. 🟠

⏱️ **30 segundos.** `[5, −10, 4, 6]` con `S = 10`: la ventana nunca llega a 10 y responde que no hay, y `[4, 6]` cumple. Con tres elementos: `[5, −10, 15]` y `S = 15`: la ventana entra al 5 y al −10 (suma −5), después al 15 (suma 10) y no ve el tramo `[15]` solo.

🗣️ **2 minutos.** La ventana para «el más corto con suma `≥ S`» solo encoge cuando la condición se cumple. Con un negativo dentro, quitar elementos por la izquierda puede subir la suma, y la ventana nunca lo intenta porque la condición no se cumplía.

🔬 **El detalle.** La solución correcta usa prefijos y una cola monótona (`04/02`, problema «El más corto, con pérdidas»).

**06 → S7.** ¿Cuál es la forma de Kadane que nunca devuelve el subarreglo vacío? 🟢

⏱️ **30 segundos.** `best = a[0]` y `cur = max(x, cur + x)` en cada paso, con `best = max(best, cur)`.

🗣️ **2 minutos.** Con `max(0, cur + x)` el tramo actual puede ser vacío y la respuesta 0 cuando todos son negativos. Con `max(x, …)`, el tramo siempre incluye al menos el elemento actual.

🔬 **El detalle.** Es la autopsia de `01/05` y la plantilla de `04/03`.

**06 → S8.** ¿Qué guardas en el mapa para contar subarreglos con suma `k`, y con qué valor empieza? 🟡

⏱️ **30 segundos.** Las veces que apareció cada prefijo; empieza con `{0: 1}`, el prefijo vacío.

🗣️ **2 minutos.** Para cada prefijo `P`, los tramos que terminan aquí con suma `k` son tantos como prefijos anteriores valgan `P − k`. Se cuenta antes de registrar el prefijo actual.

🔬 **El detalle.** Sin el `{0: 1}` se pierden los tramos que empiezan en 0; registrando antes de contar, con `k = 0` se cuenta el tramo vacío.

**06 → S9.** ¿Qué excepción tiene la fórmula del subarreglo máximo circular? 🟡

⏱️ **30 segundos.** Si todos los valores son negativos, `total − mínimo` da 0, que corresponde al tramo vacío; la respuesta es el Kadane normal.

🗣️ **2 minutos.** El mínimo subarreglo es entonces el arreglo entero, y su complemento es vacío. En código: si el mejor Kadane es negativo, se devuelve; si no, el mayor entre él y `total − mínimo`.

🔬 **El detalle.** Ver `04/03`, §4.

**06 → S10.** ¿Qué pierde la compresión de coordenadas? 🟢

⏱️ **30 segundos.** Las distancias entre valores: conserva el orden y la igualdad, pero no cuánto espacio había entre dos valores.

🗣️ **2 minutos.** Si el algoritmo solo compara, el resultado no cambia. Si mide longitudes, hay que recuperar las distancias de la lista de distintos.

🔬 **El detalle.** Ver `04/04`, §2.

**06 → S11.** ¿Qué orden de empates usas en un barrido con intervalos semiabiertos? 🟡

⏱️ **30 segundos.** Los cierres antes que las aperturas en el mismo instante.

🗣️ **2 minutos.** Un intervalo `[s, e)` ya no contiene a `e`; si en `e` empieza otro, no coinciden, y hay que quitar el primero antes de añadir el segundo. Con pares `(t, delta)` y orden natural, `−1` va antes que `+1`.

🔬 **El detalle.** Con cerrados, al revés: aperturas primero.

**06 → S12.** Al unir intervalos, ¿por qué el final del bloque es el máximo de los finales? 🟡

⏱️ **30 segundos.** Porque un intervalo anterior puede terminar después que el último fusionado: con `[1, 10)` seguido de `[2, 3)`, el bloque sigue siendo `[1, 10)`.

🗣️ **2 minutos.** Ordenados por inicio, los finales no están ordenados. Sustituir el final del bloque por el del último intervalo lo acortaría y perdería cobertura.

🔬 **El detalle.** El error típico es `out.back().second = e` en vez del máximo.

**06 → S13.** ¿Desde qué esquina empieza la búsqueda en escalera, y cuántos pasos da como mucho? 🟢

⏱️ **30 segundos.** Desde la esquina superior derecha (o la inferior izquierda), y da como mucho `R + C − 1` pasos.

🗣️ **2 minutos.** En esa esquina el valor es el mayor de su fila y el menor de su columna, así que cada comparación descarta una fila o una columna entera.

🔬 **El detalle.** Ver el teorema de [`04/05`](05-matrices.md), §2.

**06 → S14.** ¿Cómo giras una matriz `n × n` 90° en el sitio? 🟡

⏱️ **30 segundos.** Transponiendo el triángulo superior y después reflejando cada fila.

🗣️ **2 minutos.** La composición lleva `(i, j)` a `(j, n−1−i)`, el giro horario. Las dos operaciones son intercambios de pares, en el sitio.

🔬 **El detalle.** Transponer la matriz entera, en vez del triángulo, intercambia cada par dos veces y no cambia nada.

**06 → S15.** Tu ventana deslizante pasa los ejemplos y da WA en el caso 9. ¿Qué miras primero en el enunciado? 🟠

⏱️ **30 segundos.** Si los valores pueden ser negativos o cero: la ventana necesita una condición monótona, y con negativos deja de serlo.

🗣️ **2 minutos.** Los ejemplos suelen tener valores positivos; los casos ocultos, negativos. Si el enunciado los permite, la ventana es incorrecta y la técnica es prefijos con un mapa o con una cola monótona.

🔬 **El detalle.** El segundo sospechoso es el desbordamiento de la suma de la ventana en `int`.

**06 → S16.** ¿Y si las coordenadas llegaran a `10¹⁸`? Para un barrido de intervalos, ¿qué cambia en tu código? 🟠

⏱️ **30 segundos.** Que los instantes y las longitudes van en 64 bits, y que no se puede indexar por instante: el barrido sobre eventos ordenados sigue funcionando igual.

🗣️ **2 minutos.** El barrido no depende del tamaño de las coordenadas, solo del número de eventos. Lo que cambia son los tipos: instantes en `long long`, y la longitud de la unión puede llegar a `10¹⁸`, en el borde de 64 bits con signo.

🔬 **El detalle.** Si además hay que sumar varias longitudes, `2·10⁵ · 10¹⁸` no cabe ni en 64 bits; en ese caso se piensa si la respuesta realmente puede crecer tanto o se usa `__int128`.

**06 → S17.** Te piden «el número de subarreglos con suma `≤ S`» y los valores pueden ser negativos. ¿Por qué no es una ventana, y qué complejidad esperas? 🟠

⏱️ **30 segundos.** Porque «suma `≤ S`» con negativos no es monótona respecto de la inclusión: quitar un negativo sube la suma. Con prefijos, es contar pares `i < j` con `P[i] ≥ P[j] − S`, que se hace en `O(n log n)` con un Fenwick sobre prefijos comprimidos o con una mezcla.

🗣️ **2 minutos.** Para cada `j`, hay que contar los prefijos anteriores mayores o iguales que `P[j] − S`. Es un conteo de orden sobre valores grandes: compresión de los prefijos y un Fenwick (`04/04`, `09/02`), o una variante de la ordenación por mezcla que cuenta pares (`05/03`).

🔬 **El detalle.** La complejidad esperada es `O(n log n)`; `O(n)` solo con valores no negativos, donde vuelve a ser una ventana.

**06 → S18.** Un barrido da 3 reuniones a la vez y el juez espera 2. ¿Qué dos explicaciones tiene, una de ellas correcta? 🟠

⏱️ **30 segundos.** O el orden de los empates está mal (abre antes de cerrar con semiabiertos), o el enunciado dice cerrados y el juez tiene razón con otra lectura. La correcta depende de los extremos del enunciado.

🗣️ **2 minutos.** Si los intervalos son semiabiertos y se procesa la apertura antes que el cierre en el mismo instante, se cuentan juntos dos que solo se tocan: 3 en vez de 2. Si son cerrados, se tocan y 3 sería correcto; entonces el error estaría en otro sitio.

🔬 **El detalle.** El caso mínimo para comprobarlo es `[1,3) [3,5) [2,4)` (`04/04`).

**06 → S19.** Una solución de prefijos 2D da WA solo en las consultas que no tocan el borde superior izquierdo. ¿Dónde está el error? 🟠

⏱️ **30 segundos.** En el signo o en el índice de la esquina `S[r1][c1]`: es el término que se suma, y solo importa cuando `r1` y `c1` son mayores que 0.

🗣️ **2 minutos.** Si la consulta toca el borde superior izquierdo, los términos `S[r1][·]` y `S[·][c1]` son cero y el error no se ve. En las demás, una esquina restada en vez de sumada, o un `r1 − 1` mezclado con índices desde 0, da un resultado incorrecto.

🔬 **El detalle.** Se descarta con un *stress test* contra la suma directa con consultas aleatorias en todo el rango (`01/05`).

**06 → S20.** «Los dos punteros son siempre `O(n)`.» Da el caso en que el mismo código con dos índices es `O(n²)`. 🔴

⏱️ **30 segundos.** Cuando el índice interno se reinicia en cada vuelta del externo: `for (l = 0; …) { r = l; while (…) r++; }` es `O(n²)`, aunque «tenga dos punteros».

🗣️ **2 minutos.** La garantía `O(n)` viene de que **los dos índices solo avanzan** en todo el programa. Si uno vuelve atrás, el análisis agregado ya no se aplica y el coste es la suma de las distancias recorridas en cada vuelta.

🔬 **El detalle.** Los «dos punteros» dentro de un bucle sobre un tercer índice (3Sum) son `O(n²)` en total, y está bien: es un `O(n)` por cada uno de los `n` valores fijados.

**06 → S21.** ¿Por qué Kadane es una programación dinámica, y cuál es su estado? 🔴

⏱️ **30 segundos.** Porque calcula la solución de cada subproblema —el mejor tramo que termina en `i`— a partir de la del anterior. El estado es `best_end(i)`.

🗣️ **2 minutos.** La recurrencia `best_end(i) = max(a[i], best_end(i−1) + a[i])` es una transición de DP con un estado por posición y dos opciones. Que solo dependa del estado anterior es lo que deja la memoria en `O(1)`.

🔬 **El detalle.** La subestructura óptima se demuestra por inducción (`04/03`, §2); es el ejemplo de entrada de `12/01` y [`12/02`](../12-dp-clasica/02-dp-lineal-y-lis.md).

**06 → Problema: La parcela más fértil.**

- **Pista 2 — patrón:** **prefijos 2D**: cada cuadrado es una consulta `O(1)`.
- **Pista 3 — diseño:** construye `S` de `(R+1) × (C+1)` en 64 bits; para cada esquina superior izquierda válida `(i, j)`, la suma del cuadrado es la consulta de `(i, j)` a `(i+k−1, j+k−1)`; guarda el máximo. Total `O(R·C)`.

**06 → Problema: Saldos a cero.**

- **Pista 2 — patrón:** **prefijos con un mapa de frecuencias**; con negativos no hay ventana.
- **Pista 3 — diseño:** empieza con `{0: 1}`; para cada prefijo `P`, suma las apariciones de `P − S` y después registra `P`; el contador llega a `n²/2`, en 64 bits.

**06 → Problema: Reservas que se tocan.**

- **Pista 2 — patrón:** **fuerza bruta de pares**: con `n ≤ 300` son unos 45 000 pares.
- **Pista 3 — diseño:** dos reservas cerradas comparten un día si `max(s₁, s₂) ≤ min(e₁, e₂)`; compara todos los pares con esa condición. Con `n` grande, sería un barrido con aperturas antes que cierres.

**06 → Problema: Find All Anagrams in a String.**

- **Pista 2 — patrón:** **ventana fija** del tamaño de `p` con conteos de letras.
- **Pista 3 — diseño:** compara los 26 conteos de la ventana con los de `p`, actualizando con la letra que entra y la que sale; anota el inicio cada vez que coinciden.

**06 → Problema: Grumpy Bookstore Owner.**

- **Pista 2 — patrón:** **ventana fija** sobre la ganancia extra de usar la técnica.
- **Pista 3 — diseño:** suma los clientes de los minutos sin mal humor; la técnica de `minutes` minutos añade los clientes de los minutos con mal humor dentro de la ventana; busca la ventana que más añade.

**06 → Problema: Continuous Subarray Sum.**

- **Pista 2 — patrón:** **prefijos módulo `k`** con la primera posición de cada resto.
- **Pista 3 — diseño:** guarda la primera posición en que aparece cada resto, empezando con el resto 0 en la posición −1; si un resto se repite a distancia al menos 2, hay un tramo válido.

**06 → Problema: My Calendar II.**

- **Pista 2 — patrón:** **dos listas de tramos**: las reservas y los solapamientos dobles.
- **Pista 3 — diseño:** una reserva nueva falla si se cruza con algún tramo doble; si no, sus intersecciones con las reservas existentes pasan a ser tramos dobles, y se añade. Con pocas reservas, cuadrático basta.

**06 → Problema: Maximum Subarray Sum II.**

- **Pista 2 — patrón:** **prefijos con el mínimo de una ventana** de inicios permitidos (cola monótona o `multiset`).
- **Pista 3 — diseño:** para cada final `j`, el inicio está entre `j − b` y `j − a`; la mejor suma es `P[j]` menos el mínimo de `P` en ese rango, que se mantiene con una cola monótona al deslizar `j`.

**06 → Problema: Minimum Window Substring.**

- **Pista 2 — patrón:** **ventana variable** con conteos y un contador de letras cubiertas.
- **Pista 3 — diseño:** cuenta cuántas letras distintas de `t` están cubiertas en la cantidad necesaria; amplía por la derecha hasta cubrirlas todas, y encoge por la izquierda mientras sigan cubiertas, anotando la ventana más corta.
