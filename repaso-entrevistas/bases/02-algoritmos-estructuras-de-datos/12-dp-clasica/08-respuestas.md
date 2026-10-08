# Respuestas — bloque 12: DP clásica

> Solucionario del bloque `12`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--de-la-recursión-a-la-tabla) · [02](#02--dp-lineal-y-lis) · [03](#03--mochilas) · [04](#04--dp-sobre-cadenas) · [05](#05--dp-en-rejillas-y-de-intervalos) · [06](#06--conteo-con-dp) · [07](#07--simulación)

---

# 01 — De la recursión a la tabla

**01 → 1.** ¿Qué dos propiedades necesita un problema para resolverse con DP? 🟢

⏱️ **30 segundos.** Subestructura óptima —la solución se construye con soluciones óptimas de subproblemas— y subproblemas solapados —la recursión vuelve a los mismos subproblemas—.

🗣️ **2 minutos.** Sin solape, guardar no ahorra nada y es divide y vencerás. Sin subestructura, combinar óptimos de las partes no da el óptimo del todo y la recurrencia es falsa.

🔬 **El detalle.** Para problemas de conteo, «subestructura óptima» se lee como «la cuenta del todo es una combinación de cuentas de subproblemas disjuntos»; la idea es la misma.

**01 → 2.** ¿Qué cinco piezas tiene una DP? 🟢

⏱️ **30 segundos.** El estado, la transición, los casos base, el orden de cálculo y la respuesta.

🗣️ **2 minutos.** El estado dice qué identifica a un subproblema; la transición, cómo se calcula a partir de otros; los casos base, dónde se para; el orden, en qué secuencia las dependencias ya están; la respuesta, qué estado se devuelve. Con eso, el coste es estados × transición.

🔬 **El detalle.** El método SRTBOT de MIT 6.006 es la misma lista con otros nombres: subproblemas, relación, orden topológico, base, original, tiempo.

**01 → 3.** ¿Cuántas llamadas hace el Fibonacci recursivo para `n = 40`, y cuántas con memoización? 🟢

⏱️ **30 segundos.** Sin memoización, 331 160 281 llamadas para `n = 40`; con memoización, 79 (`2n − 1`).

🗣️ **2 minutos.** El número de llamadas sin memo cumple `C(n) = 1 + C(n − 1) + C(n − 2)`, que crece como `φⁿ`. Con memo, cada `F(k)` con `k ≥ 2` se calcula una vez y hace dos llamadas, una de las cuales encuentra el valor guardado.

🔬 **El detalle.** `C(n) = 2F(n + 1) − 1`: con `F(41) = 165 580 141`, sale 331 160 281.

**01 → 4.** ¿Qué dice el principio de optimalidad de Bellman, dicho para programar? 🟢

⏱️ **30 segundos.** Que el estado tiene que contener todo lo que el futuro necesita saber del pasado: lo que queda por decidir debe ser óptimo para el estado al que se llegó, sea cual sea el camino.

🗣️ **2 minutos.** Si dos caminos llegan al mismo estado y el mejor futuro depende de cuál se tomó, al estado le falta información y hay que ampliarlo (por ejemplo, con «la última decisión» o «cuánto queda»).

🔬 **El detalle.** El enunciado original de Bellman (1957) habla de políticas; la versión práctica es la de diseñar el estado.

**01 → 5.** ¿En qué se diferencian memoización y tabulación, y qué tienen en común? 🟡

⏱️ **30 segundos.** La memoización es la recursión con una tabla, de arriba abajo, y solo calcula los estados que visita; la tabulación rellena la tabla en orden, de abajo arriba, sin recursión. Las dos tienen el mismo estado y la misma transición.

🗣️ **2 minutos.** La memoización no necesita conocer el orden, pero usa pila; la tabulación necesita un orden válido, pero no usa pila y permite filas rodantes. El coste asintótico es el mismo si se visitan todos los estados.

🔬 **El detalle.** Pasar de una a otra es mecánico: el orden de la tabla es un orden topológico del grafo de dependencias que la recursión recorre en profundidad.

**01 → 6.** ¿Cuándo la memoización es más rápida que la tabulación? 🟡

⏱️ **30 segundos.** Cuando la recursión solo visita una fracción pequeña de los estados posibles: la tabla los recorrería todos.

🗣️ **2 minutos.** Ejemplo: `f(n) = f(n/2) + f(n/3)` con `n` hasta `10¹⁸` visita unos pocos miles de estados, pero una tabla de `10¹⁸` no cabe. Con un diccionario como memo, solo se guardan los alcanzables.

🔬 **El detalle.** También en DP sobre estados con restricciones (muchas combinaciones inalcanzables), la memo con diccionario es más rápida aunque cada acceso cueste más.

**01 → 7.** Compara cómo memoizas en C++, Java y Python, y qué límite de pila tiene cada uno. 🟡

⏱️ **30 segundos.** C++: un `vector` con centinela, y la pila del sistema (8 MB o la del juez). Java: un arreglo con centinela y la pila de ~1 MB por hilo, ampliable con un `Thread`. Python: `@cache`, cómodo, con límite de 1000 llamadas y pila de C si pasa por el envoltorio.

🗣️ **2 minutos.** En Java, la memo de profundidad `10⁵` desborda sin el hilo con pila grande; en C++ suele caber. En Python, `@cache` sobre una recursión de profundidad `10⁵` revienta la pila de C aunque se suba el límite, porque el envoltorio está en C: hace falta el hilo con `threading.stack_size` o tabular.

🔬 **El detalle.** [`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md), §3, tiene la tabla de profundidades por lenguaje.

**01 → 8.** ¿Por qué el voraz «divide entre 3 si puedes, si no entre 2, si no resta 1» falla, y qué DP lo resuelve? 🟠

⏱️ **30 segundos.** Porque una división temprana puede dejar un número peor: con 10, dividir entre 2 da `10 → 5 → 4 → 2 → 1` (4), y restar primero da `10 → 9 → 3 → 1` (3). La DP prueba las tres opciones: `ops(x) = 1 + min(ops(x − 1), ops(x/2), ops(x/3))`.

🗣️ **2 minutos.** El voraz decide mirando solo el paso actual; el óptimo depende de lo que viene después. La DP sobre `x` de 1 a `n` tiene `n` estados con transición `O(1)`: `Θ(n)`.

🔬 **El detalle.** Es la misma lección de [`11/04`](../11-voraces/04-matroides-y-contraejemplos.md): antes de confiar en un voraz, compararlo con la fuerza bruta (aquí, la DP) en `n` pequeños encuentra el 10 enseguida.

**01 → 9.** Demuestra por inducción que la tabulación calcula bien todos los estados. 🟠

⏱️ **30 segundos.** Inducción sobre el orden de cálculo: los casos base son correctos por definición; al calcular un estado, todos los que usa están antes en el orden y son correctos por hipótesis, y la transición es correcta por la subestructura.

🗣️ **2 minutos.** El invariante del bucle es «`dp[j]` es correcto para todo `j` ya procesado». Se inicializa con los casos base, se mantiene porque la transición solo lee estados procesados, y al terminar cubre todos.

🔬 **El detalle.** La hipótesis que hay que comprobar en cada DP es «solo lee estados procesados»: es la definición de orden válido.

**01 → 10.** ¿Por qué guardar la solución completa en cada estado es mala idea, y qué guardas en su lugar? 🟠

⏱️ **30 segundos.** Porque copiar la solución en cada estado cuesta tanto como su longitud, y en el peor caso eso es `Θ(n²)` de tiempo y memoria. Se guarda la **última decisión** (el padre) y se reconstruye siguiendo la cadena.

🗣️ **2 minutos.** La solución de un estado es la del estado padre más una decisión: guardarla entera repite lo que el padre ya guarda. Con el arreglo de padres, la reconstrucción cuesta `O(longitud)` una sola vez al final.

🔬 **El detalle.** Es la misma idea que el arreglo `parent` de BFS o de Dijkstra ([`14/02`](../14-grafos-recorridos/02-bfs.md), [`15/01`](../15-grafos-pesos-y-flujos/01-dijkstra.md)): árbol de caminos guardado como padres.

**01 → 11.** ¿Qué es un orden válido de cálculo y qué tiene que ver con el orden topológico? 🟠

⏱️ **30 segundos.** Un orden en que cada estado aparece después de todos los estados de los que depende. Es un orden topológico del grafo cuyos vértices son los estados y cuyas aristas son las dependencias.

🗣️ **2 minutos.** El grafo de dependencias de una DP correcta es acíclico (si no, la recursión no terminaría). Cualquier orden topológico vale; en una DP lineal es `i` creciente, en intervalos es por longitud, en rejillas por filas y columnas.

🔬 **El detalle.** Por eso la DP sobre un DAG explícito ([`14/04`](../14-grafos-recorridos/04-orden-topologico.md)) es la forma más general de DP: los estados son los vértices.

**01 → 12.** Tu DP con memo da TLE con la respuesta correcta en los ejemplos. ¿Qué tres cosas miras? 🔴

⏱️ **30 segundos.** Que el resultado se guarda de verdad (`return memo[i] = …`), que el centinela no coincide con un valor válido (si el resultado puede ser 0 o −1, la memo nunca «acierta»), y que el estado no incluye algo que no hace falta y multiplica los estados.

🗣️ **2 minutos.** Si la memo no se guarda o el centinela es un valor posible, la recursión vuelve a ser exponencial y da la respuesta correcta lentamente. Si el estado lleva información de más (un índice que no se usa, una lista), hay muchos más estados de los necesarios. Y si es Python con `@cache`, la constante: tabular.

🔬 **El detalle.** El tercer sospechoso es un diccionario con claves compuestas (tuplas, cadenas) donde un arreglo bastaba: la constante multiplica por 10.

**01 → 13.** Diseña la reconstrucción de la secuencia lexicográficamente menor entre todas las óptimas de un problema de DP lineal. 🔴

⏱️ **30 segundos.** Calcular la DP «hacia atrás»: `best[i]` = el óptimo desde el estado `i` hasta el final. Después, reconstruir hacia delante: en cada estado, elegir la menor decisión `d` con `coste(d) + best[siguiente] = best[i]`.

🗣️ **2 minutos.** Con la DP hacia delante (óptimo desde el inicio hasta `i`) los padres dan **una** solución óptima, pero no se puede elegir la menor lexicográfica de izquierda a derecha, porque al decidir el primer elemento no se sabe si el resto es óptimo. Con `best` hacia el final sí: cada decisión que conserva el óptimo deja un sufijo óptimo.

🔬 **El detalle.** Es la técnica del problema propio «Partir en palabras»: el óptimo hacia el final y el desempate por la primera palabra más corta.

**01 → Problema: Baldosas de 2 × n.**

- **Pista 2 — patrón:** **DP lineal de conteo** sobre la longitud del pasillo.
- **Pista 3 — diseño:** la última columna es una baldosa de pie (queda `n − 1`), dos tumbadas (queda `n − 2`) o una de 2 × 2 (queda `n − 2`): `f(n) = f(n − 1) + 2f(n − 2)`, `f(0) = f(1) = 1`. Módulo en cada paso; dos variables bastan.

**01 → Problema: Saltos de la rana.**

- **Pista 2 — patrón:** **DP lineal de mínimo** con ventana de `k`.
- **Pista 3 — diseño:** `dp[1] = 0`; `dp[i] = min_{1 ≤ s ≤ k, s < i} dp[i − s] + |hᵢ − hᵢ₋ₛ|`. `O(n · k)` = `10⁷`. Valores en 64 bits.

**01 → Problema: Partir en palabras.**

- **Pista 2 — patrón:** **DP hacia el final con reconstrucción** del óptimo lexicográfico.
- **Pista 3 — diseño:** `best[i]` = mínimo de palabras para partir el texto desde `i` (`best[n] = 0`), probando las palabras que encajan en `i` (con un conjunto de palabras por longitud, o un *trie*). Si `best[0]` es infinito, `-1`. Reconstruye desde 0 eligiendo la palabra más corta que encaje con `best[i + |w|] = best[i] − 1`.

**01 → Problema: Climbing Stairs.**

- **Pista 2 — patrón:** **DP lineal** (Fibonacci).
- **Pista 3 — diseño:** `dp[i] = dp[i − 1] + dp[i − 2]`, con `dp[0] = dp[1] = 1`; dos variables.

**01 → Problema: Min Cost Climbing Stairs.**

- **Pista 2 — patrón:** **DP lineal de mínimo**.
- **Pista 3 — diseño:** `dp[i]` = coste mínimo de llegar al escalón `i` (se puede empezar en 0 o en 1); `dp[i] = min(dp[i − 1] + cost[i − 1], dp[i − 2] + cost[i − 2])`; la respuesta es `dp[n]`.

**01 → Problema: Ladder.**

- **Pista 2 — patrón:** **tabla de Fibonacci** con módulo `2ᴮ`.
- **Pista 3 — diseño:** las formas de subir `N` escalones son `F(N + 1)`; precalcula la tabla hasta el `L` máximo módulo `2³⁰` (el mayor `B`) y responde con `F(N + 1) & ((1 << B) − 1)`, porque reducir módulo `2³⁰` y después módulo `2ᴮ` es lo mismo.

**01 → Problema: FibFrog.**

- **Pista 2 — patrón:** **DP sobre las posiciones** (o BFS) con saltos de Fibonacci.
- **Pista 3 — diseño:** genera los números de Fibonacci hasta `N + 1` (unos 25); `dp[p]` = el mínimo de saltos para llegar a la posición `p` (las hojas y la orilla); para cada `p` alcanzable, prueba cada salto `f` hacia `p + f`.

**01 → Problema: Decode Ways.**

- **Pista 2 — patrón:** **DP lineal** con dos transiciones condicionadas.
- **Pista 3 — diseño:** `dp[i]` = formas de decodificar el prefijo de longitud `i`; suma `dp[i − 1]` si `s[i − 1] ≠ '0'`, y `dp[i − 2]` si los dos últimos forman un número entre 10 y 26.

**01 → Problema: Word Break.**

- **Pista 2 — patrón:** **DP sobre prefijos**.
- **Pista 3 — diseño:** `ok[0] = true`; `ok[j]` es cierto si existe `i < j` con `ok[i]` y `s[i..j)` en el diccionario. Limita `j − i` a la longitud máxima de palabra.

**01 → Problema: Perfect Squares.**

- **Pista 2 — patrón:** **DP de mínimo** sobre la suma.
- **Pista 3 — diseño:** `dp[0] = 0`; `dp[x] = 1 + min dp[x − k²]` sobre los `k` con `k² ≤ x`. `O(n √n)`.

**01 → Problema: Dice Combinations.**

- **Pista 2 — patrón:** **DP de conteo** sobre la suma.
- **Pista 3 — diseño:** `dp[0] = 1`; `dp[s] = Σ_{d=1..6} dp[s − d]` módulo `10⁹ + 7`.

**01 → Problema: Removing Digits.**

- **Pista 2 — patrón:** **DP de mínimo** sobre el número.
- **Pista 3 — diseño:** `dp[0] = 0`; `dp[x] = 1 + min dp[x − d]` sobre los dígitos `d ≠ 0` de `x`. Tabla de 0 a `n`.

**01 → Problema: Fibonacci Modified.**

- **Pista 2 — patrón:** **tabulación con enteros de precisión arbitraria**.
- **Pista 3 — diseño:** `t[i + 2] = t[i] + t[i + 1]²`; los valores crecen doblemente exponencial: en Java, `BigInteger`; en Python, `int`; en C++, hay que escribir la multiplicación de números grandes.

---

# 02 — DP lineal y LIS

**02 → 1.** ¿Qué es `d[i]` en la LIS cuadrática, y por qué la respuesta es su máximo? 🟢

⏱️ **30 segundos.** La longitud de la subsecuencia estrictamente creciente más larga que **acaba en la posición `i`**. La respuesta es el máximo porque la LIS puede acabar en cualquier posición.

🗣️ **2 minutos.** Fijar el final hace la recurrencia posible: la penúltima posición es un `j < i` con `a[j] < a[i]`. Si el estado fuera «la LIS del prefijo», no se sabría con qué valor acaba y no se podría extender.

🔬 **El detalle.** Es el patrón de «fijar el último elemento» que se repite en casi todas las DP de subsecuencias.

**02 → 2.** ¿Qué guarda `tails[k]` en la LIS de `O(n log n)`? 🟢

⏱️ **30 segundos.** El menor valor con que puede acabar una subsecuencia estrictamente creciente de longitud `k + 1` entre los elementos ya procesados.

🗣️ **2 minutos.** Un final menor es mejor porque deja más sitio para extender. Por eso, para cada longitud, solo interesa el mínimo final, y con eso `tails` es creciente y admite búsqueda binaria.

🔬 **El detalle.** La longitud de `tails` al terminar es la de la LIS; su contenido no tiene por qué ser una subsecuencia.

**02 → 3.** ¿Qué dos estados lleva el robo de casas, y cuál es su transición? 🟢

⏱️ **30 segundos.** `coge`, la mejor suma que coge el elemento actual, y `deja`, la mejor que no lo coge. `coge = deja_anterior + a[i]`, `deja = max(coge_anterior, deja_anterior)`.

🗣️ **2 minutos.** Con los dos, la decisión de cada posición solo depende del paso anterior: coger exige no haber cogido el anterior. La respuesta es el máximo de los dos al final.

🔬 **El detalle.** Con «no tres seguidos» (el problema de las guardias) hacen falta tres estados: cuántas noches seguidas llevo (0, 1 o 2).

**02 → 4.** ¿Por qué el arreglo `tails` no es la LIS? Da un ejemplo. 🟡

⏱️ **30 segundos.** Porque cada entrada es el mejor final de su longitud por separado, y pueden venir de subsecuencias distintas. Con `[5, 2, 9, 1]`, `tails` queda `[1, 9]`, y el 1 va después del 9.

🗣️ **2 minutos.** Al procesar el 1, sustituye al 2 como mejor final de longitud 1, pero el 9 sigue siendo el final de longitud 2 de la subsecuencia `2, 9`. `tails` mezcla las dos.

🔬 **El detalle.** Para reconstruir, se guarda en cada posición el índice del final de longitud `k` que había cuando se insertó (el padre).

**02 → 5.** ¿Qué cambia entre la LIS estricta y la no decreciente en la versión rápida? 🟡

⏱️ **30 segundos.** La búsqueda: `lower_bound` (`bisect_left`) para la estricta, `upper_bound` (`bisect_right`) para la no decreciente.

🗣️ **2 minutos.** Con la estricta, un valor igual a un final existente lo sustituye (no puede extenderlo). Con la no decreciente, un valor igual sí extiende, y por eso se busca el primer final **mayor**.

🔬 **El detalle.** En la cuadrática, lo mismo es cambiar `a[j] < a[i]` por `a[j] <= a[i]`.

**02 → 6.** ¿Por qué hace falta una variable temporal al actualizar las dos variables del robo? 🟡

⏱️ **30 segundos.** Porque el nuevo `skip` necesita el `take` del paso **anterior**; si `take` ya se actualizó, se lee el valor nuevo y la transición mezcla dos pasos.

🗣️ **2 minutos.** El error da resultados mayores de lo posible (coge dos vecinos). La variable temporal guarda el nuevo `take` hasta que se ha calculado `skip`. En Python, `take, skip = skip + x, max(take, skip)` evalúa la derecha entera antes de asignar.

🔬 **El detalle.** Con más estados, se calculan todos los nuevos en temporales y se asignan al final, o se usan dos filas.

**02 → 7.** Compara cómo haces el *lower bound* de la LIS rápida en C++, Java y Python. 🟡

⏱️ **30 segundos.** C++: `std::lower_bound` sobre el `vector` de colas. Python: `bisect_left`. Java: una binaria escrita a mano sobre `tails[0..len)`.

🗣️ **2 minutos.** Java tiene `Arrays.binarySearch(arr, 0, len, x)`, pero devuelve **algún** índice si hay iguales y `−(inserción) − 1` si no está; corregirlo es más error-prone que escribir el *lower bound*. En Python, `bisect_left` está en C y es muy rápido.

🔬 **El detalle.** [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md), §3, tiene la plantilla del *lower bound* y la tabla de la biblioteca de cada lenguaje.

**02 → 8.** Demuestra que `tails` es estrictamente creciente. 🟠

⏱️ **30 segundos.** Si existe una subsecuencia de longitud `k + 2` que acaba en `v`, su prefijo de longitud `k + 1` acaba en un valor `< v`; así que el menor final de longitud `k + 1` es menor que el de longitud `k + 2`.

🗣️ **2 minutos.** Tomando la subsecuencia de longitud `k + 2` con final mínimo `tails[k + 1]`, su elemento anterior es un final válido de longitud `k + 1` y es estrictamente menor; `tails[k]` es el mínimo de esos finales, así que `tails[k] < tails[k + 1]`.

🔬 **El detalle.** La monotonía es la que permite la binaria; sin ella, la versión rápida no existiría.

**02 → 9.** ¿Por qué al procesar `x` solo cambia una entrada de `tails`? 🟠

⏱️ **30 segundos.** Porque `x` solo puede extender subsecuencias cuyo final es menor que `x`: las de longitud `≤ k`, con `k` el primer índice con `tails[k] ≥ x`. Con eso crea una de longitud `k + 1` que acaba en `x ≤ tails[k]`, y solo mejora esa entrada.

🗣️ **2 minutos.** Para longitudes `≤ k`, ya hay finales `< x`, así que `x` no los mejora. Para longitudes `> k + 1`, `x` necesitaría extender una de longitud `≥ k + 1`, que acaba en `≥ tails[k] ≥ x`: imposible.

🔬 **El detalle.** Es el paso de mantenimiento del invariante; junto con la monotonía, prueba la corrección.

**02 → 10.** ¿Cómo reconstruyes la LIS en la versión rápida, y por qué hace falta `tailIdx`? 🟠

⏱️ **30 segundos.** Guardando, además de `tails`, el índice de cada final (`tailIdx`) y, para cada posición, el padre: el índice del final de longitud `k` cuando se insertó en la posición `k + 1`. Al final, se sigue la cadena desde el último de `tailIdx`.

🗣️ **2 minutos.** `tails` guarda valores, que se sobrescriben y no dicen de dónde vienen. `tailIdx[k − 1]` en el momento de insertar es el elemento concreto que se extendió, y queda fijado en `parent[i]` aunque después se sustituya.

🔬 **El detalle.** La subsecuencia reconstruida es una LIS válida, no necesariamente la lexicográficamente menor.

**02 → 11.** ¿Cuándo usas la cuadrática aunque `n` permita la rápida? 🟠

⏱️ **30 segundos.** Cuando la relación entre consecutivos no es un orden (divisibilidad, «es predecesor de»), cuando se pide una suma o un conteo en lugar de la longitud y no apetece un Fenwick, o cuando `n` es pequeño y la claridad importa.

🗣️ **2 minutos.** La rápida depende de que «mejor final» tenga sentido y sea comparable; con divisibilidad, un final menor no es necesariamente mejor. La cuadrática solo pide una comparación.

🔬 **El detalle.** El número de LIS se cuenta con la cuadrática llevando a la vez longitud y número; con la rápida, haría falta una estructura por longitud.

**02 → 12.** Da una entrada en la que la LIS cuadrática escrita con `<=` en lugar de `<` da más que la estrictamente creciente, y explica qué cuenta de más. 🔴

⏱️ **30 segundos.** `[2, 2, 2]`: con `<=` da 3, la estrictamente creciente es 1. Cuenta como crecientes las parejas de valores iguales.

🗣️ **2 minutos.** `a[j] <= a[i]` acepta extender con un valor igual; para la estricta, cada valor repetido debería empezar de nuevo o sustituir. Es el mismo error que usar `upper_bound` en la rápida cuando se pide la estricta.

🔬 **El detalle.** El caso de prueba mínimo con repetidos es lo primero que hay que probar en cualquier LIS: decide qué comparación lleva el código.

**02 → 13.** Diseña una DP lineal para comprar y vender una acción con, como mucho, dos compras en total: estados y transiciones. 🔴

⏱️ **30 segundos.** Cuatro estados por día: tras la primera compra, tras la primera venta, tras la segunda compra, tras la segunda venta. Cada uno es el máximo entre quedarse igual y venir del anterior con la operación del día.

🗣️ **2 minutos.** `c1 = max(c1, −p)`, `v1 = max(v1, c1 + p)`, `c2 = max(c2, v1 − p)`, `v2 = max(v2, c2 + p)`; la respuesta es `v2`. Actualizarlos en este orden dentro del mismo día permite comprar y vender el mismo día, que no cambia el resultado.

🔬 **El detalle.** Con `k` compras, `2k` estados: `Θ(n · k)`. Si `k ≥ n/2`, el límite no restringe y basta sumar todas las subidas.

**02 → Problema: Turnos de guardia.**

- **Pista 2 — patrón:** **DP lineal con un estado extra**: cuántas noches seguidas llevas.
- **Pista 3 — diseño:** tres estados por noche: `r0` (no trabajo esta), `r1` (trabajo esta y no la anterior), `r2` (trabajo esta y la anterior). `r0 = max(r0, r1, r2)`, `r1 = r0_ant + p`, `r2 = r1_ant + p`. Con temporales. En 64 bits.

**02 → Problema: Pila de libros.**

- **Pista 2 — patrón:** **LIS en dos dimensiones**: ordenar por ancho y buscar la LIS estricta en el alto.
- **Pista 3 — diseño:** ordena por ancho creciente y, a igual ancho, por alto **decreciente**, para que dos del mismo ancho no puedan formar parte de la misma subsecuencia creciente; después, LIS estricta sobre los altos con la versión rápida.

**02 → Problema: Mínimo de pistas de despegue.**

- **Pista 2 — patrón:** **Dilworth**: el mínimo de subsecuencias estrictamente decrecientes que cubren es la longitud de la subsecuencia **no decreciente** más larga.
- **Pista 3 — diseño:** dos aviones con `peso_i ≤ peso_j` e `i < j` no pueden compartir pista, así que una subsecuencia no decreciente necesita pistas distintas; y el voraz que pone cada avión en la pista con el último peso más pequeño que lo supere alcanza esa cota. Calcula la no decreciente más larga con `upper_bound`.

**02 → Problema: The Maximum Subarray.**

- **Pista 2 — patrón:** **Kadane** para el subarreglo y **suma de positivos** para la subsecuencia.
- **Pista 3 — diseño:** subarreglo: `best = x + max(0, best)` y el máximo; subsecuencia: la suma de los positivos, o el máximo si todos son negativos.

**02 → Problema: Longest Increasing Subsequence.**

- **Pista 2 — patrón:** **LIS** (cuadrática o con colas).
- **Pista 3 — diseño:** con `n ≤ 2 500` cabe la cuadrática; la de colas con `lower_bound` da la longitud en `O(n log n)`.

**02 → Problema: Maximum Sum Circular Subarray.**

- **Pista 2 — patrón:** **Kadane dos veces**: el máximo normal y el total menos el mínimo.
- **Pista 3 — diseño:** si el mejor da la vuelta, deja fuera un subarreglo contiguo, que es el de suma mínima. La respuesta es `max(máximo, total − mínimo)`, salvo si todos son negativos (entonces, el máximo).

**02 → Problema: Best Time to Buy and Sell Stock with Cooldown.**

- **Pista 2 — patrón:** **máquina de estados por día**.
- **Pista 3 — diseño:** tres estados: con acción, recién vendido (enfriamiento), sin acción y libre. `hold = max(hold, free − p)`, `sold = hold + p`, `free = max(free, sold_ant)`. La respuesta es `max(sold, free)`.

**02 → Problema: Number of Longest Increasing Subsequence.**

- **Pista 2 — patrón:** **LIS cuadrática con conteo**.
- **Pista 3 — diseño:** para cada `i`, `len[i]` y `cnt[i]`; para `j < i` con `a[j] < a[i]`: si `len[j] + 1 > len[i]`, copia (`len[j] + 1`, `cnt[j]`); si es igual, suma `cnt[j]`. La respuesta suma los `cnt` de las posiciones con la longitud máxima.

**02 → Problema: Largest Divisible Subset.**

- **Pista 2 — patrón:** **LIS cuadrática** con la relación «divide a», tras ordenar.
- **Pista 3 — diseño:** ordenados, si `a` divide a `b` y `b` divide a `c`, `a` divide a `c`: basta comprobar entre consecutivos. `d[i] = 1 + max d[j]` con `a[i] % a[j] == 0`; reconstruye con padres.

**02 → Problema: Increasing Subsequence.**

- **Pista 2 — patrón:** **LIS en `n log n`**.
- **Pista 3 — diseño:** colas con `lower_bound` (estricta); la respuesta es la longitud final.

**02 → Problema: Longest String Chain.**

- **Pista 2 — patrón:** **LIS sobre palabras ordenadas por longitud**, con un mapa.
- **Pista 3 — diseño:** ordena por longitud; para cada palabra, prueba quitar cada letra y busca la resultante en un mapa `palabra → mejor cadena`; `dp[w] = 1 + max dp[w sin una letra]`.

**02 → Problema: Wiggle Subsequence.**

- **Pista 2 — patrón:** **DP lineal con dos estados**: la mejor que acaba subiendo y la que acaba bajando.
- **Pista 3 — diseño:** si `a[i] > a[i − 1]`, `up = down + 1`; si `a[i] < a[i − 1]`, `down = up + 1`; si son iguales, nada. La respuesta es `max(up, down)`.

**02 → Problema: Russian Doll Envelopes.**

- **Pista 2 — patrón:** **LIS en dos dimensiones** con desempate.
- **Pista 3 — diseño:** ordena por ancho creciente y, a igual ancho, alto decreciente; LIS estricta sobre los altos con la versión rápida. El desempate impide meter un sobre en otro del mismo ancho.

---

# 03 — Mochilas

**03 → 1.** ¿Cuál es la recurrencia de la mochila 0/1 y cuántos estados tiene? 🟢

⏱️ **30 segundos.** `dp[i][c] = max(dp[i−1][c], dp[i−1][c − wᵢ] + vᵢ)` si `wᵢ ≤ c`. Tiene `(n + 1)(W + 1)` estados.

🗣️ **2 minutos.** El estado es (objetos considerados, capacidad). La transición decide si se coge el objeto `i`: si no, queda el mismo problema con `i − 1`; si sí, con `i − 1` y la capacidad reducida. Caso base: sin objetos, valor 0.

🔬 **El detalle.** La respuesta es `dp[n][W]` si la mochila no tiene que llenarse; si tiene que llenarse exactamente, se inicializa a `−∞` salvo `dp[0][0] = 0`.

**03 → 2.** ¿En qué sentido se recorre la capacidad en la 0/1 de una fila, y en la ilimitada? 🟢

⏱️ **30 segundos.** Descendente en la 0/1; ascendente en la ilimitada.

🗣️ **2 minutos.** Descendente, `dp[c − w]` todavía es de la fila anterior (el objeto no se ha usado); ascendente, ya puede incluir el objeto actual, que así se repite.

🔬 **El detalle.** Es la misma línea de código; solo cambia el `for`. Conviene comentarlo en la plantilla.

**03 → 3.** ¿Cómo se reconstruyen los objetos elegidos a partir de la tabla completa? 🟢

⏱️ **30 segundos.** Desde `(n, W)` hacia atrás: si `dp[i][c] ≠ dp[i−1][c]`, el objeto `i` se cogió y la capacidad baja `wᵢ`; si son iguales, no se cogió.

🗣️ **2 minutos.** No hacen falta padres: la tabla completa ya dice qué opción dio el valor. Con empates, el criterio elegido (aquí, no coger si da lo mismo) decide cuál de las soluciones óptimas sale.

🔬 **El detalle.** Con la fila única se pierde esta información; si hace falta reconstruir con poca memoria, se guarda una tabla de bits «se cogió» de `n · W` bits.

**03 → 4.** ¿Qué cambia entre contar combinaciones y contar sucesiones de monedas? 🟢

⏱️ **30 segundos.** El anidamiento de los bucles: con las monedas por fuera, cada combinación se cuenta una vez; con las sumas por fuera, cada sucesión ordenada. Con `{1, 3, 4}` y 6: 4 combinaciones, 9 sucesiones.

🗣️ **2 minutos.** Con monedas por fuera, cuando se procesa la moneda `c`, las formas ya contadas solo usan monedas anteriores: cada combinación se construye en un orden fijo. Con sumas por fuera, la última moneda puede ser cualquiera, y `1+3` y `3+1` se cuentan por separado.

🔬 **El detalle.** Las sucesiones son «composiciones» con partes en el conjunto; las combinaciones, «particiones». [`12/06`](06-conteo.md) y [`17/05`](../17-matematica/05-combinatoria.md) vuelven sobre esta distinción.

**03 → 5.** ¿Por qué `O(n · W)` no contradice que la mochila sea NP-difícil? 🟡

⏱️ **30 segundos.** Porque `O(n · W)` es polinomial en el valor de `W`, no en su tamaño: `W` ocupa `log W` bits, y `W = 2^(log W)` es exponencial en la entrada. Es pseudopolinomial.

🗣️ **2 minutos.** Con `W = 10¹⁸` la tabla no cabe aunque la entrada mida 60 bits. La mochila es NP-difícil: si hubiera un algoritmo polinomial en `n` y `log W`, P = NP. La DP solo es rápida con números pequeños.

🔬 **El detalle.** Es débilmente NP-difícil (tiene algoritmo pseudopolinomial); los fuertemente NP-difíciles siguen siendo difíciles con números pequeños ([`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md)).

**03 → 6.** ¿Por qué el mínimo de monedas no depende del orden de los bucles y el conteo sí? 🟡

⏱️ **30 segundos.** Porque el mínimo de un conjunto no depende del orden en que se recorre, y el conteo sí cuenta cosas distintas según el orden: combinaciones o sucesiones.

🗣️ **2 minutos.** Una sucesión y su combinación tienen el mismo número de monedas, así que el mínimo sobre sucesiones es el mínimo sobre combinaciones. En el conteo, cada combinación corresponde a varias sucesiones, y el orden de bucles decide cuál de los dos conjuntos se enumera.

🔬 **El detalle.** Lo mismo pasa con «¿se puede pagar?» (booleano): da igual el orden.

**03 → 7.** Compara cómo representas «infinito» en el mínimo de monedas en C++, Java y Python, y qué trampa tiene cada uno. 🟡

⏱️ **30 segundos.** C++: `INT_MAX` o `LLONG_MAX` y comprobar antes de sumar 1. Java: `Integer.MAX_VALUE`, igual. Python: `float("inf")`, que admite `+ 1` sin desbordar.

🗣️ **2 minutos.** `INT_MAX + 1` desborda a `INT_MIN` en C++ (comportamiento indefinido) y en Java (a `−2147483648`), y el mínimo se vuelve basura. La alternativa es usar un «infinito» moderado (`10⁹`) que al sumar no desborde. En Python, `inf` es un `float` y mezclar con enteros es lento pero correcto.

🔬 **El detalle.** El infinito moderado tiene que ser mayor que cualquier respuesta posible: con `x ≤ 10⁵` y monedas `≥ 1`, cualquier valor `> 10⁵` sirve.

**03 → 8.** ¿Qué pasa si recorres la 0/1 de una fila en sentido ascendente? Da el resultado con los objetos del capítulo. 🟠

⏱️ **30 segundos.** Resuelve la mochila **ilimitada**: cada objeto puede usarse varias veces. Con los objetos del capítulo da 20 (`(5,10)` dos veces) en lugar de 18.

🗣️ **2 minutos.** Ascendente, al llegar a `c` ya se actualizó `dp[c − w]` con este mismo objeto, y la transición lo suma otra vez. No falla con error: devuelve una respuesta de otro problema, que puede pasar los ejemplos.

🔬 **El detalle.** Un ejemplo con un objeto de peso `w ≤ W/2` y razón alta lo delata siempre.

**03 → 9.** Demuestra que el bucle descendente de la fila única implementa la recurrencia de la 0/1. 🟠

⏱️ **30 segundos.** Al procesar el objeto `i` con `c` descendente, las celdas `> c` ya son de la fila `i` y las `≤ c`, de la `i − 1`. La transición lee `dp[c]` y `dp[c − w]`, ambas `≤ c`: lee la fila anterior, que es la recurrencia 0/1.

🗣️ **2 minutos.** Es un invariante del bucle interno: se inicializa con toda la fila de la `i − 1`, se mantiene porque cada paso solo escribe `dp[c]` tras leer posiciones `≤ c` sin modificar, y al terminar toda la fila es la `i`.

🔬 **El detalle.** El mismo razonamiento explica la ilimitada: ascendente, `dp[c − w]` ya es de la fila `i`, y la recurrencia ilimitada usa `dp[i][c − w]`.

**03 → 10.** ¿Cómo partirías un objeto con 13 copias en la mochila acotada, y por qué basta? 🟠

⏱️ **30 segundos.** En paquetes de 1, 2, 4 y 6 unidades. Con ellos se forma cualquier cantidad de 0 a 13 eligiendo un subconjunto, y ninguna combinación pasa de 13.

🗣️ **2 minutos.** Con 1, 2 y 4 se forma todo de 0 a 7 (binario); sumando el 6, todo de 6 a 13; juntos, de 0 a 13. Cada paquete se trata como un objeto 0/1 de peso `k · w` y valor `k · v`.

🔬 **El detalle.** El número de paquetes es `⌊log₂ c⌋ + 1`: el coste pasa de `W · c` a `W · log c` por objeto.

**03 → 11.** ¿Qué haces si `W = 10⁹` pero los valores son pequeños (`Σv ≤ 10⁵`)? 🟠

⏱️ **30 segundos.** La DP **por valor**: `dp[v]` = el menor peso para conseguir valor exactamente `v`. La respuesta es el mayor `v` con `dp[v] ≤ W`. `Θ(n · Σv)`.

🗣️ **2 minutos.** Se intercambian los papeles de peso y valor: la dimensión de la tabla pasa a ser la que es pequeña. Con `Σv ≤ 10⁵` y `n = 100`, `10⁷` pasos, aunque `W` sea `10⁹`.

🔬 **El detalle.** Es la base del esquema de aproximación (FPTAS) de la mochila: redondear los valores para que `Σv` sea polinomial.

**03 → 12.** ¿Cómo decides si un problema de partición en dos grupos de igual suma cabe en una DP de mochila, y con qué tabla? 🔴

⏱️ **30 segundos.** Si la suma total `S` es par y `S/2` es pequeña (`n · S/2 ≤ 10⁸`), con una fila de booleanos hasta `S/2`: ¿alcanza un subconjunto exactamente `S/2`? Si `S` es impar, no hay partición.

🗣️ **2 minutos.** Un grupo suma `S/2` si y solo si el otro también: el problema es la suma de subconjuntos. Con valores grandes y `n ≤ 40`, *meet in the middle*; con `n` grande y valores grandes, no cabe en general (es NP-completo).

🔬 **El detalle.** En C++, `bitset<S/2 + 1>` y `reach |= reach << a` hacen cada objeto en `S / 64` operaciones.

**03 → 13.** Tu conteo de formas de pagar da 9 cuando el enunciado esperaba 4. ¿Qué pasó y cómo lo arreglas? 🔴

⏱️ **30 segundos.** Que los bucles estaban anidados al revés: con las sumas por fuera se cuentan sucesiones ordenadas (9 para `{1, 3, 4}` y 6) en lugar de combinaciones (4). Se pone el bucle de monedas por fuera.

🗣️ **2 minutos.** El enunciado decide: si `1+3` y `3+1` son la misma forma, combinaciones; si no, sucesiones. El ejemplo pequeño con dos órdenes de los mismos valores (`1+1+4`) es el que delata la confusión.

🔬 **El detalle.** El error inverso (4 cuando se esperaba 9) es igual de frecuente en problemas de «escaleras» con pasos variables, que piden sucesiones.

**03 → Problema: Plantilla con presupuesto.**

- **Pista 2 — patrón:** **mochila 0/1 con dos dimensiones**: dinero y número de jugadores.
- **Pista 3 — diseño:** `dp[k][b]` = la mejor valoración con exactamente `k` jugadores y gasto `b` (o `−∞`); para cada jugador, recorre `k` y `b` **descendentes** y prueba ficharlo. La respuesta es el máximo de toda la tabla. `n · K · B ≤ 1,5·10⁷`.

**03 → Problema: Almacén con existencias.**

- **Pista 2 — patrón:** **mochila acotada con división binaria**.
- **Pista 3 — diseño:** parte cada tipo en paquetes de `1, 2, 4, …` unidades y un resto; cada paquete es un objeto 0/1 (bucle descendente). Los paquetes de peso mayor que `W` se saltan. Valores en 64 bits.

**03 → Problema: The Coin Change Problem.**

- **Pista 2 — patrón:** **contar combinaciones** de monedas.
- **Pista 3 — diseño:** `ways[0] = 1`; monedas por fuera, sumas ascendentes por dentro: `ways[s] += ways[s − c]`. Sin módulo, pero en 64 bits.

**03 → Problema: Partition Equal Subset Sum.**

- **Pista 2 — patrón:** **0/1 de booleanos** hasta `Σ/2`.
- **Pista 3 — diseño:** si la suma es impar, falso; si no, `reach[0] = true` y, para cada número, `reach[s] |= reach[s − x]` con `s` descendente; la respuesta es `reach[Σ/2]`.

**03 → Problema: Coin Change II.**

- **Pista 2 — patrón:** **contar combinaciones**: monedas por fuera.
- **Pista 3 — diseño:** `ways[0] = 1`; para cada moneda, `ways[s] += ways[s − c]` con `s` ascendente desde `c`.

**03 → Problema: Combination Sum IV.**

- **Pista 2 — patrón:** **contar sucesiones**: sumas por fuera.
- **Pista 3 — diseño:** `ways[0] = 1`; para `s` de 1 a `target`, `ways[s] = Σ ways[s − x]` sobre los `x ≤ s`. Los valores intermedios pueden pasar de 32 bits aunque la respuesta quepa.

**03 → Problema: Target Sum.**

- **Pista 2 — patrón:** **0/1 de conteo** tras transformar los signos en una partición.
- **Pista 3 — diseño:** con `P − N = target` y `P + N = S`, `P = (S + target) / 2` (si no es entero o es negativo, 0 formas). Cuenta los subconjuntos con suma `P` con una fila descendente: `ways[s] += ways[s − x]`.

**03 → Problema: Ones and Zeroes.**

- **Pista 2 — patrón:** **0/1 con dos capacidades** (ceros y unos).
- **Pista 3 — diseño:** `dp[i][j]` = el mayor número de cadenas con a lo sumo `i` ceros y `j` unos; para cada cadena, recorre `i` y `j` descendentes y prueba cogerla.

**03 → Problema: MinAbsSum.**

- **Pista 2 — patrón:** **sumas alcanzables hasta `Σ/2`** sobre los valores absolutos.
- **Pista 3 — diseño:** el signo se elige libremente, así que se trabaja con `|a|`; la respuesta es `Σ − 2s` con `s` la mayor suma alcanzable `≤ Σ/2`. Como los valores van de 0 a 100, cuenta cuántas veces aparece cada valor y usa una mochila acotada (o la versión con «cuántas copias quedan» por suma).

**03 → Problema: Minimizing Coins.**

- **Pista 2 — patrón:** **mínimo de monedas** (ilimitada con mínimo).
- **Pista 3 — diseño:** `mn[0] = 0`; `mn[s] = 1 + min mn[s − c]`; `-1` si queda infinito.

**03 → Problema: Coin Combinations II.**

- **Pista 2 — patrón:** **contar combinaciones** con módulo.
- **Pista 3 — diseño:** monedas por fuera, sumas por dentro, módulo `10⁹ + 7` en cada suma.

**03 → Problema: Two Sets II.**

- **Pista 2 — patrón:** **contar subconjuntos con suma `Σ/2`** (0/1 de conteo).
- **Pista 3 — diseño:** si `Σ = n(n+1)/2` es impar, 0. Si no, cuenta los subconjuntos de `{1..n}` con suma `Σ/2` y divide entre 2 (cada partición se cuenta por sus dos lados): con módulo primo, multiplica por el inverso de 2, o cuenta solo los que no contienen el `n`.

**03 → Problema: Last Stone Weight II.**

- **Pista 2 — patrón:** **partición de diferencia mínima**: sumas alcanzables hasta `Σ/2`.
- **Pista 3 — diseño:** cada piedra acaba sumando o restando; la respuesta es `Σ − 2s` con `s` la mayor suma alcanzable `≤ Σ/2`.

**03 → Problema: Book Shop II.**

- **Pista 2 — patrón:** **mochila acotada con división binaria**.
- **Pista 3 — diseño:** cada libro con `k` copias se parte en paquetes de potencias de 2; mochila 0/1 en una fila sobre el precio. `x · Σ log k` operaciones.

---

# 04 — DP sobre cadenas

**04 → 1.** ¿Qué diferencia hay entre una subsecuencia y una subcadena? Da un ejemplo con `abracadabra`. 🟢

⏱️ **30 segundos.** Una subsecuencia se obtiene borrando caracteres, sin exigir que lo que queda sea contiguo; una subcadena es un tramo contiguo. `aca` es las dos cosas en `abracadabra`; `abaca` es subsecuencia pero no subcadena.

🗣️ **2 minutos.** Hay `Θ(n²)` subcadenas y `2ⁿ` subsecuencias. Los problemas de subcadenas suelen resolverse con dos punteros, *hashing* o estructuras de sufijos; los de subsecuencias, con DP de prefijos.

🔬 **El detalle.** En inglés: *subsequence* frente a *substring*; los enunciados los confunden a veces, y el ejemplo del enunciado es el que decide.

**04 → 2.** ¿Cuál es la recurrencia de la LCS y qué guarda `L[i][j]`? 🟢

⏱️ **30 segundos.** `L[i][j]` = la longitud de la LCS de los prefijos `a[0..i)` y `b[0..j)`. Si `a[i−1] = b[j−1]`, `L[i−1][j−1] + 1`; si no, `max(L[i−1][j], L[i][j−1])`. Con `L[0][·] = L[·][0] = 0`.

🗣️ **2 minutos.** Se decide mirando los últimos caracteres de los dos prefijos: si coinciden, se emparejan; si no, alguno de los dos sobra. La respuesta es `L[n][m]`.

🔬 **El detalle.** `(n + 1)(m + 1)` estados con transición `O(1)`: `Θ(n · m)`.

**04 → 3.** ¿Qué tres movimientos tiene la distancia de edición, y qué valen los casos base? 🟢

⏱️ **30 segundos.** Borrar el último de `a`, insertar el último de `b`, o sustituir uno por otro (gratis si coinciden). Casos base: `D[i][0] = i` (borrar todo) y `D[0][j] = j` (insertar todo).

🗣️ **2 minutos.** Las tres opciones corresponden a las tres vecinas: arriba (`D[i−1][j] + 1`), izquierda (`D[i][j−1] + 1`) y diagonal (`D[i−1][j−1] + [a[i−1] ≠ b[j−1]]`). La respuesta es `D[n][m]`.

🔬 **El detalle.** Es la distancia de Levenshtein (1965). La de Damerau añade el intercambio de vecinos.

**04 → 4.** ¿En qué orden se llena la tabla de palíndromos, y por qué no por filas? 🟡

⏱️ **30 segundos.** Con `i` decreciente (o por longitud del intervalo creciente), porque `P[i][j]` depende de `P[i+1][j−1]` y de `P[i+1][j]`, que están en la fila de abajo.

🗣️ **2 minutos.** Por filas con `i` creciente, al calcular `P[i][j]` la fila `i + 1` todavía está a cero y el resultado es basura. El orden válido es cualquiera en que los intervalos más cortos estén antes que los que los contienen.

🔬 **El detalle.** Es la regla general de la DP de intervalos de [`12/05`](05-rejillas-e-intervalos.md): el orden de cálculo es la longitud.

**04 → 5.** ¿Por qué con dos filas se obtiene la distancia pero no la secuencia de operaciones? 🟡

⏱️ **30 segundos.** Porque la secuencia de operaciones se reconstruye recorriendo la tabla desde la esquina hacia atrás, y con dos filas las anteriores se han sobrescrito.

🗣️ **2 minutos.** El valor de la esquina solo depende de la última fila; las decisiones que llevaron a él están repartidas por toda la tabla. Opciones: guardar la tabla, guardar bits de decisión, o Hirschberg.

🔬 **El detalle.** Hirschberg reconstruye en memoria lineal con el doble de tiempo, partiendo la primera cadena por la mitad.

**04 → 6.** ¿Qué relación hay entre la subsecuencia palindrómica más larga y la LCS? 🟡

⏱️ **30 segundos.** Es la LCS de la cadena con su reverso.

🗣️ **2 minutos.** Una subsecuencia palindrómica se lee igual en los dos sentidos, así que es común a `s` y a `reverse(s)`; y una LCS de los dos se puede convertir en una palindrómica de la misma longitud. La DP de intervalos es la versión directa, con la mitad de estados útiles.

🔬 **El detalle.** El mínimo de inserciones (o de borrados) para hacer de `s` un palíndromo es `n` menos esa longitud.

**04 → 7.** Compara la memoria de una tabla de `5 000 × 5 000` enteros en C++, Java y Python. 🟡

⏱️ **30 segundos.** `25·10⁶` enteros: 100 MB en C++ y en Java con `int`; en Python, una lista de listas de enteros pequeños ocupa unos 8 bytes por referencia más las listas: unos 200 MB, y el bucle tarda minutos.

🗣️ **2 minutos.** Con 256 MB de límite, C++ y Java caben justos con `int`, y no con `long`. Si solo se pide el valor, dos filas: 40 KB. En Python, además de la memoria, `25·10⁶` iteraciones de bucle puro tardan decenas de segundos.

🔬 **El detalle.** En Java, `int[5000][5000]` son 5 000 objetos arreglo; un único `int[]` de `n · m` con índice `i · m + j` ahorra cabeceras y mejora la localidad.

**04 → 8.** Demuestra que, si los últimos caracteres coinciden, alguna LCS los empareja. 🟠

⏱️ **30 segundos.** Tomando una LCS cualquiera: si no usa `a[i−1]` o no usa `b[j−1]`, o los usa emparejados con otros caracteres, se puede cambiar su último emparejamiento por `(a[i−1], b[j−1])` sin perder longitud.

🗣️ **2 minutos.** Si la LCS no usa ninguno de los dos, añadir el par la alarga: contradicción. Si usa `a[i−1]` emparejado con `b[k]` con `k < j − 1`, se cambia por `b[j−1]`, que es el mismo carácter y está después de todos los demás emparejados: sigue siendo común y de la misma longitud. Igual en el otro caso.

🔬 **El detalle.** Es un argumento de intercambio ([`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md)) dentro de una DP: justifica que en ese caso no hace falta probar las otras dos opciones.

**04 → 9.** ¿Cómo calculas la distancia si solo se permiten inserciones y borrados, sin rehacer la DP? 🟠

⏱️ **30 segundos.** Con la LCS: `n + m − 2 · LCS`. Lo que no se borra de ninguna de las dos es una subsecuencia común, y conviene que sea la más larga.

🗣️ **2 minutos.** Insertar en `a` equivale a borrar de `b` (al revés): la distancia solo con inserciones y borrados es el número de caracteres que no están en la LCS, en las dos cadenas.

🔬 **El detalle.** Es LeetCode Delete Operation for Two Strings; la distancia de Levenshtein siempre es menor o igual, porque una sustitución puede ahorrar un borrado y una inserción.

**04 → 10.** ¿Cómo cambia la recurrencia si sustituir cuesta 2 y borrar o insertar cuesta 1? ¿Qué distancia es esa? 🟠

⏱️ **30 segundos.** La diagonal pasa a `D[i−1][j−1] + 2 · [a[i−1] ≠ b[j−1]]`. Como sustituir cuesta lo mismo que borrar e insertar, la sustitución nunca hace falta: es la distancia de inserciones y borrados, `n + m − 2 · LCS`.

🗣️ **2 minutos.** La estructura de la tabla es la misma; solo cambia el coste de un movimiento. Con costes arbitrarios, la DP sigue siendo correcta mientras sean no negativos.

🔬 **El detalle.** Con costes que no cumplen la desigualdad triangular, la DP sigue dando el óptimo de la secuencia de operaciones; lo que deja de ser cierto es que la distancia sea una métrica.

**04 → 11.** ¿Qué hace Hirschberg y cuándo lo necesitas? 🟠

⏱️ **30 segundos.** Reconstruye la LCS o la alineación en memoria lineal: parte la primera cadena por la mitad, calcula con dos filas la DP de la mitad izquierda hacia delante y la de la derecha hacia atrás, elige el mejor corte de la segunda cadena y recurre en los dos trozos.

🗣️ **2 minutos.** Se necesita cuando las cadenas son largas (`10⁵`) y la tabla no cabe pero el tiempo `n · m` sí. El tiempo total es unas dos veces el de la DP simple.

🔬 **El detalle.** Kleinberg y Tardos, §6.7. Casi nunca sale en concursos de entrevista; sí en bioinformática.

**04 → 12.** Escribe la recurrencia de la **subcadena** común más larga y explica en qué se diferencia de la LCS. 🔴

⏱️ **30 segundos.** `C[i][j]` = la longitud de la subcadena común más larga que **acaba** en `a[i−1]` y `b[j−1]`: `C[i−1][j−1] + 1` si coinciden, 0 si no. La respuesta es el máximo de la tabla.

🗣️ **2 minutos.** En la LCS, cuando no coinciden se hereda el mejor de los vecinos; en la subcadena, la racha se rompe y vuelve a 0, porque tiene que ser contigua. Por eso el estado fija el final y la respuesta es un máximo, no la esquina.

🔬 **El detalle.** Con cadenas largas, la subcadena común más larga se hace en `O(n log n)` con *hashing* y búsqueda binaria, o en `O(n)` con un autómata de sufijos ([`16/06`](../16-cadenas/06-suffix-array-y-automaton.md)).

**04 → 13.** Tu tabla de palíndromos da resultados absurdos para intervalos de longitud 2. ¿Qué miras? 🔴

⏱️ **30 segundos.** Que `P[i+1][j−1]` con `j = i + 1` es un intervalo vacío (`i + 1 > j − 1`) y tiene que valer 0 (o «palíndromo», en la tabla booleana); y que el orden de cálculo sea `i` decreciente.

🗣️ **2 minutos.** En la tabla booleana, la condición es `s[i] == s[j] && (j − i < 2 || esPal[i+1][j−1])`; si falta el `j − i < 2`, se lee una celda que no se inicializó como cierta. En la de longitudes, la celda vacía tiene que ser 0 y la diagonal 1.

🔬 **El detalle.** Un caso de prueba con `aa` y `ab` delata los dos errores en un segundo.

**04 → Problema: Corrector ortográfico.**

- **Pista 2 — patrón:** **distancia de edición** contra cada palabra del diccionario.
- **Pista 3 — diseño:** `m · 20 · 20 = 4·10⁵` celdas: cabe calcular la distancia con cada palabra y quedarse con el mínimo, desempatando por orden alfabético (compara el par `(distancia, palabra)`).

**04 → Problema: Tres cadenas.**

- **Pista 2 — patrón:** **LCS en tres dimensiones**.
- **Pista 3 — diseño:** `L[i][j][k]`: si los tres últimos caracteres coinciden, `L[i−1][j−1][k−1] + 1`; si no, el máximo de quitar el último de cada una de las tres. `101³ ≈ 10⁶` estados.

**04 → Problema: Cortes en palíndromos.**

- **Pista 2 — patrón:** **tabla de palíndromos** más **DP lineal** de cortes.
- **Pista 3 — diseño:** precalcula `esPal[i][j]` con `i` decreciente; después `c[j]` = el mínimo de cortes para `s[0..j]`: 0 si `s[0..j]` es palíndromo, si no `min c[i−1] + 1` sobre los `i ≤ j` con `esPal[i][j]`. `Θ(n²)`.

**04 → Problema: Longest Common Subsequence.**

- **Pista 2 — patrón:** **LCS**.
- **Pista 3 — diseño:** la tabla de prefijos con diagonal si coinciden y máximo si no; dos filas bastan para la longitud.

**04 → Problema: Edit Distance.**

- **Pista 2 — patrón:** **distancia de edición**.
- **Pista 3 — diseño:** la recurrencia de los tres movimientos con los casos base `D[i][0] = i`, `D[0][j] = j`.

**04 → Problema: Delete Operation for Two Strings.**

- **Pista 2 — patrón:** **LCS**: lo que queda es una subsecuencia común.
- **Pista 3 — diseño:** la respuesta es `n + m − 2 · LCS`.

**04 → Problema: Longest Palindromic Subsequence.**

- **Pista 2 — patrón:** **DP sobre intervalos** (o LCS con el reverso).
- **Pista 3 — diseño:** `P[i][j] = P[i+1][j−1] + 2` si los extremos coinciden, si no `max(P[i+1][j], P[i][j−1])`; `i` decreciente.

**04 → Problema: Common Child.**

- **Pista 2 — patrón:** **LCS con dos filas**.
- **Pista 3 — diseño:** con 5 000 caracteres, la tabla de `int` son 100 MB: dos filas de `int` bastan para la longitud. En Python el bucle puro es lento: usa PyPy si el juez lo ofrece, o vectoriza.

**04 → Problema: The Longest Common Subsequence.**

- **Pista 2 — patrón:** **LCS con reconstrucción**.
- **Pista 3 — diseño:** la tabla completa y el recorrido desde la esquina: diagonal si coinciden, si no hacia el vecino mayor; imprime los elementos emparejados al revés.

**04 → Problema: Interleaving String.**

- **Pista 2 — patrón:** **DP de dos prefijos** con la tercera cadena determinada.
- **Pista 3 — diseño:** `ok[i][j]` = los prefijos de longitud `i` y `j` se intercalan para formar el prefijo `i + j` de `s3`; `ok[i][j] = (ok[i−1][j] && s1[i−1] = s3[i+j−1]) || (ok[i][j−1] && s2[j−1] = s3[i+j−1])`. Comprueba antes que las longitudes sumen.

**04 → Problema: Edit Distance.**

- **Pista 2 — patrón:** **distancia de edición** (la versión de CSES).
- **Pista 3 — diseño:** la misma recurrencia; con 5 000 caracteres por cadena, dos filas de `int` y un bucle sin objetos. En Python no cabe en tiempo: C++ o Java.

**04 → Problema: Uncrossed Lines.**

- **Pista 2 — patrón:** **LCS disfrazada**.
- **Pista 3 — diseño:** líneas que no se cruzan unen valores iguales en el mismo orden en los dos arreglos: es la LCS de los dos arreglos.

**04 → Problema: Distinct Subsequences.**

- **Pista 2 — patrón:** **DP de conteo sobre dos prefijos**.
- **Pista 3 — diseño:** `C[i][j]` = cuántas veces aparece `t[0..j)` como subsecuencia de `s[0..i)`; `C[i][j] = C[i−1][j] + (s[i−1] = t[j−1] ? C[i−1][j−1] : 0)`, con `C[i][0] = 1`.

**04 → Problema: Wildcard Matching.**

- **Pista 2 — patrón:** **DP de prefijos** con una transición especial para `*`.
- **Pista 3 — diseño:** `M[i][j]` = el prefijo `i` del texto encaja con el prefijo `j` del patrón; si `p[j−1] = '*'`, `M[i][j] = M[i][j−1]` (vacío) `|| M[i−1][j]` (consume uno más); si es `?` o coincide, `M[i−1][j−1]`. `M[0][j]` es cierto si el prefijo del patrón son solo `*`.

**04 → Problema: Regular Expression Matching.**

- **Pista 2 — patrón:** **DP de prefijos** donde `x*` es un bloque.
- **Pista 3 — diseño:** si `p[j−1] = '*'`, `M[i][j] = M[i][j−2]` (cero repeticiones) `|| (coincide(s[i−1], p[j−2]) && M[i−1][j])` (una más); si no, `coincide(s[i−1], p[j−1]) && M[i−1][j−1]`, con `.` coincidiendo con todo.

---

# 05 — DP en rejillas y de intervalos

**05 → 1.** ¿En qué orden se rellena una DP de rejilla, y por qué es válido? 🟢

⏱️ **30 segundos.** Fila a fila, de izquierda a derecha. Es válido porque cada casilla depende de la de arriba y la de la izquierda, que ya están calculadas.

🗣️ **2 minutos.** Con movimientos solo hacia abajo y a la derecha, el grafo de dependencias es un DAG y el orden por filas es un orden topológico. Con diagonales hacia delante, también.

🔬 **El detalle.** Por columnas también vale; lo que no vale es cualquier orden en que una casilla se calcule antes que sus predecesoras.

**05 → 2.** ¿Qué recurrencia tiene la cadena de matrices y cuánto cuesta? 🟢

⏱️ **30 segundos.** `m[i][j] = min_k m[i][k] + m[k+1][j] + p[i−1] · p[k] · p[j]`, con `m[i][i] = 0`. Cuesta `Θ(n³)` tiempo y `Θ(n²)` memoria.

🗣️ **2 minutos.** Hay `Θ(n²)` tramos y cada uno prueba `Θ(n)` cortes. La última multiplicación del tramo junta el resultado de `Aᵢ…Aₖ` (`p[i−1] × p[k]`) con el de `Aₖ₊₁…Aⱼ` (`p[k] × p[j]`).

🔬 **El detalle.** El arreglo `split[i][j]` guarda el `k` óptimo y permite escribir los paréntesis recursivamente.

**05 → 3.** ¿En qué orden se rellena una DP de intervalos? 🟢

⏱️ **30 segundos.** Por longitud del tramo creciente (o con `i` decreciente y `j` creciente), porque cada tramo depende de tramos estrictamente más cortos.

🗣️ **2 minutos.** El bucle exterior es la longitud, el siguiente el inicio, y el interior el corte. Con `i` creciente y `j` creciente, `d[i][j]` usaría `d[k+1][j]` con `k + 1 > i`, que todavía no se ha calculado.

🔬 **El detalle.** La memoización evita pensar el orden, a costa de la recursión; en DP de intervalos con `n ≤ 500` la profundidad es pequeña y la memo es una opción cómoda.

**05 → 4.** ¿Por qué en *burst balloons* el estado se define por el último globo y no por el primero? 🟡

⏱️ **30 segundos.** Porque cuando el último globo del tramo revienta, sus vecinos son exactamente los extremos fijos del tramo, y los dos lados son independientes. Si se elige el primero, los vecinos de los demás cambian y los lados no se separan.

🗣️ **2 minutos.** Tras reventar el primero, sus dos vecinos pasan a ser contiguos, y el subproblema de la izquierda depende de lo que pase en la derecha. Con el último, el globo `k` separa `(l, k)` y `(k, r)`, y la puntuación de `k` es `v[l] · v[k] · v[r]`, conocida.

🔬 **El detalle.** Es un patrón general: cuando una operación cambia la vecindad, se piensa en la última operación del tramo.

**05 → 5.** ¿Por qué basta una fila en la DP de rejilla con movimientos abajo y derecha? 🟡

⏱️ **30 segundos.** Porque `d[i][j]` solo usa `d[i−1][j]` (el valor anterior de la misma columna, todavía en la fila) y `d[i][j−1]` (ya actualizado en esta fila).

🗣️ **2 minutos.** Al recorrer `j` creciente, antes de escribir `d[j]` contiene el valor de la fila de arriba, y `d[j − 1]` ya es el de la fila actual. Las dos lecturas son las que pide la recurrencia.

🔬 **El detalle.** Con la diagonal abajo-derecha hace falta también `d[i−1][j−1]`, que en una fila ya se sobrescribió: se guarda en una variable antes de escribir `d[j−1]`.

**05 → 6.** ¿Cuándo una rejilla deja de ser una DP y pasa a ser un problema de caminos mínimos? 🟡

⏱️ **30 segundos.** Cuando los movimientos forman ciclos (arriba, abajo, izquierda y derecha): ya no hay orden topológico, y es un problema de caminos mínimos con BFS o Dijkstra.

🗣️ **2 minutos.** La DP necesita que las dependencias sean acíclicas. En una rejilla con las cuatro direcciones, una casilla puede depender de otra que depende de ella. BFS si todos los pasos valen igual, 0-1 BFS si valen 0 o 1, Dijkstra si tienen pesos no negativos.

🔬 **El detalle.** `14/02` y `15/01`. Algunos problemas mezclan: DP con un estado extra que impide volver atrás (por ejemplo, el número de pasos dados).

**05 → 7.** Compara cómo marcas una casilla inalcanzable en C++, Java y Python, y qué error evita cada forma. 🟡

⏱️ **30 segundos.** C++ y Java: un centinela como `LLONG_MIN` o `Long.MIN_VALUE`, comprobado antes de sumar. Python: `None` u `-inf`. Evitan que lo inalcanzable se trate como alcanzable con valor pequeño.

🗣️ **2 minutos.** Si se usa 0 como «inalcanzable» en un problema de máximos con valores no negativos, una casilla aislada parecerá alcanzable con 0. Sumar al centinela mínimo desborda en C++ (indefinido) y en Java (da la vuelta a valores enormes). En Python, `-inf + 5` sigue siendo `-inf`, que es cómodo.

🔬 **El detalle.** En conteo, el inalcanzable es simplemente 0: no hay centinela.

**05 → 8.** Demuestra la subestructura óptima de la cadena de matrices. 🟠

⏱️ **30 segundos.** En una parentización óptima de `Aᵢ…Aⱼ` con último corte `k`, la parentización de `Aᵢ…Aₖ` tiene que ser óptima: si hubiera una más barata, cambiarla abarataría el total, porque el coste del último producto no depende de cómo se parentizó cada lado.

🗣️ **2 minutos.** El coste total es `coste(izquierda) + coste(derecha) + p[i−1] · p[k] · p[j]`; el tercer término solo depende de las dimensiones de los extremos, no de la parentización interna. Por tanto, cada lado se optimiza por separado.

🔬 **El detalle.** CLRS, §15.2, paso 1. Es la prueba de cortar y pegar (*cut-and-paste*) que se usa en casi todas las DP de optimización.

**05 → 9.** ¿Por qué el voraz «multiplica primero el par más barato» no sirve en la cadena de matrices? 🟠

⏱️ **30 segundos.** Porque elegir el producto más barato ahora puede dejar dimensiones que encarecen los siguientes. No hay elección voraz: hay que probar todos los cortes.

🗣️ **2 minutos.** Contraejemplo: con `p = [10, 30, 5, 60]` el voraz por el producto más barato elige `AB` (1 500 frente a 9 000), que resulta ser bueno; pero hay cadenas donde el par barato deja una matriz enorme en medio. La forma segura es compararlo con la DP en casos pequeños (`11/04`).

🔬 **El detalle.** Existe un algoritmo `O(n log n)` de Hu y Shing basado en triangulaciones de polígonos, pero no es voraz y casi nunca se pide.

**05 → 10.** ¿Qué cambia si en la rejilla se puede mover también en diagonal abajo-derecha? 🟠

⏱️ **30 segundos.** Se añade una tercera dependencia, `d[i−1][j−1]`. Sigue siendo un DAG y el orden por filas sigue valiendo.

🗣️ **2 minutos.** Con una sola fila hay que guardar `d[i−1][j−1]` antes de sobrescribirlo (es el antiguo `d[j−1]`). Con la tabla entera no hace falta nada especial.

🔬 **El detalle.** Es el problema propio «Robot con tres movimientos».

**05 → 11.** ¿Qué dice la desigualdad de Knuth y qué consigue en una DP de intervalos? 🔴

⏱️ **30 segundos.** Que si el coste cumple la desigualdad del cuadrilátero y es monótono, el corte óptimo cumple `opt[i][j−1] ≤ opt[i][j] ≤ opt[i+1][j]`. Restringiendo `k` a ese rango, la DP baja de `Θ(n³)` a `Θ(n²)`.

🗣️ **2 minutos.** La suma de los rangos explorados a lo largo de una diagonal de longitud fija es `O(n)` (telescopio), y hay `n` diagonales. El ABB óptimo y la unión de montones vecinos lo cumplen; la cadena de matrices, no en general.

🔬 **El detalle.** [`13/05`](../13-dp-avanzada/05-optimizaciones.md) tiene la prueba y la plantilla; cp-algorithms, *Knuth's Optimization*.

**05 → 12.** Demuestra que el número de parentizaciones de `n` matrices crece al menos como `2ⁿ⁻²` y explica qué dice eso de la búsqueda completa. 🔴

⏱️ **30 segundos.** El número de parentizaciones cumple `P(n) = Σ_k P(k) · P(n − k)`, el número de Catalan, que crece como `4ⁿ / n^1,5`. Una cota sencilla: `P(n) ≥ 2 · P(n − 1)` para `n ≥ 3`, que da `2ⁿ⁻²`. La búsqueda completa es exponencial; la DP explora solo `Θ(n²)` tramos.

🗣️ **2 minutos.** `P(n) ≥ P(1)P(n−1) + P(n−1)P(1) = 2P(n−1)`, separando el primer y el último término de la suma. Con `P(2) = 1`, `P(n) ≥ 2ⁿ⁻²`. Con 20 matrices, más de 250 000 por esta cota, y en realidad más de mil millones.

🔬 **El detalle.** `P(n) = C(n−1) = (2n − 2)! / (n! (n − 1)!)`, `17/05`.

**05 → 13.** Tu DP de intervalos da un resultado distinto cada vez que cambias el orden de los bucles. ¿Qué miras? 🔴

⏱️ **30 segundos.** El orden de cálculo: si el resultado cambia con el orden de los bucles, alguna celda se está leyendo antes de calcularse. El bucle exterior tiene que ser la longitud del tramo.

🗣️ **2 minutos.** Compruebo que cada lectura `d[i][k]` y `d[k+1][j]` sea de un tramo más corto que `[i, j]`, y que las celdas base (`d[i][i]`) estén inicializadas. Una memoización de prueba con el mismo estado sirve de oráculo: no depende del orden.

🔬 **El detalle.** Otro sospechoso es la inicialización de `d[i][j]` antes del bucle de cortes (a infinito para mínimos, a menos infinito o 0 para máximos).

**05 → Problema: Robot con tres movimientos.**

- **Pista 2 — patrón:** **DP de rejilla** con tres predecesoras.
- **Pista 3 — diseño:** `d[i][j] = c[i][j] + min(d[i−1][j], d[i][j−1], d[i−1][j−1])` con los bordes tratados como infinito; fila a fila. Con una fila, guarda la diagonal antes de sobrescribirla. Suma en 64 bits.

**05 → Problema: Unir montones vecinos.**

- **Pista 2 — patrón:** **DP de intervalos** con prefijos de sumas.
- **Pista 3 — diseño:** `d[i][j] = min_k d[i][k] + d[k+1][j] + suma(i..j)`, con la suma por prefijos y `d[i][i] = 0`; por longitud creciente. `400³ ≈ 6,4·10⁷`. En 64 bits.

**05 → Problema: Paréntesis para el máximo.**

- **Pista 2 — patrón:** **DP de intervalos** que guarda **el mínimo y el máximo** de cada tramo.
- **Pista 3 — diseño:** para cada tramo y cada corte `k`, combina los cuatro pares (mín o máx de la izquierda con mín o máx de la derecha) con el operador `k`; el mínimo y el máximo del tramo son el menor y el mayor de esas combinaciones. Con negativos, el máximo de un producto puede venir de dos mínimos.

**05 → Problema: Unique Paths.**

- **Pista 2 — patrón:** **contar caminos en rejilla**.
- **Pista 3 — diseño:** `d[i][j] = d[i−1][j] + d[i][j−1]` con la primera fila y columna a 1; una fila basta. (También es `C(m + n − 2, m − 1)`.)

**05 → Problema: Unique Paths II.**

- **Pista 2 — patrón:** **contar caminos con obstáculos**.
- **Pista 3 — diseño:** lo mismo, con `d = 0` en las casillas bloqueadas; cuidado con un obstáculo en la casilla de inicio.

**05 → Problema: Minimum Path Sum.**

- **Pista 2 — patrón:** **rejilla de mínimo**.
- **Pista 3 — diseño:** `d[i][j] = g[i][j] + min(d[i−1][j], d[i][j−1])`, con los bordes acumulados.

**05 → Problema: Triangle.**

- **Pista 2 — patrón:** **rejilla triangular de abajo arriba**.
- **Pista 3 — diseño:** empieza con la última fila; cada fila superior toma `t[i][j] + min(d[j], d[j+1])`; al final `d[0]`. Una fila de memoria.

**05 → Problema: Maximal Square.**

- **Pista 2 — patrón:** **rejilla con mínimo de tres vecinas**.
- **Pista 3 — diseño:** `d[i][j]` = el lado del mayor cuadrado de unos con esquina inferior derecha en `(i, j)`: `1 + min(d[i−1][j], d[i][j−1], d[i−1][j−1])` si la casilla es 1, 0 si no. La respuesta es el máximo al cuadrado.

**05 → Problema: Minimum Score Triangulation of Polygon.**

- **Pista 2 — patrón:** **DP de intervalos** sobre los vértices.
- **Pista 3 — diseño:** `d[i][j] = min_{i<k<j} d[i][k] + d[k][j] + v[i] · v[k] · v[j]`, con `d[i][i+1] = 0`; por longitud.

**05 → Problema: Grid Paths I.**

- **Pista 2 — patrón:** **contar caminos con trampas**, módulo `10⁹ + 7`.
- **Pista 3 — diseño:** `d[i][j] = d[i−1][j] + d[i][j−1]` salvo en las trampas, que valen 0; si la casilla inicial es trampa, la respuesta es 0.

**05 → Problema: Rectangle Cutting.**

- **Pista 2 — patrón:** **DP sobre las dimensiones** del rectángulo.
- **Pista 3 — diseño:** `d[a][b] = 0` si `a = b`; si no, el mínimo de `d[k][b] + d[a−k][b] + 1` (corte horizontal) y `d[a][k] + d[a][b−k] + 1` (vertical). `500 · 500 · 1 000 ≈ 2,5·10⁸` operaciones simples: C++.

**05 → Problema: Dungeon Game.**

- **Pista 2 — patrón:** **rejilla de abajo arriba** sobre la vida necesaria al entrar.
- **Pista 3 — diseño:** `need[i][j] = max(1, min(need[i+1][j], need[i][j+1]) − g[i][j])`, empezando por la princesa; hacia delante no funciona porque la vida mínima depende del futuro.

**05 → Problema: Burst Balloons.**

- **Pista 2 — patrón:** **DP de intervalos por el último**.
- **Pista 3 — diseño:** añade un 1 en cada extremo; `d[l][r] = max_k d[l][k] + d[k][r] + v[l] · v[k] · v[r]` sobre los `k` del tramo abierto; por longitud.

**05 → Problema: Minimum Cost to Cut a Stick.**

- **Pista 2 — patrón:** **DP de intervalos** sobre los cortes ordenados.
- **Pista 3 — diseño:** añade 0 y `n` a los cortes y ordena; `d[i][j] = min_{i<k<j} d[i][k] + d[k][j] + (c[j] − c[i])`, por longitud.

**05 → Problema: Cherry Pickup.**

- **Pista 2 — patrón:** **dos caminos simultáneos**: ir y volver es lo mismo que dos personas bajando a la vez.
- **Pista 3 — diseño:** estado `(paso, fila1, fila2)` (las columnas se deducen del paso); en cada paso, las dos personas avanzan; si están en la misma casilla, la cereza cuenta una vez. `Θ(n³)`.

---

# 06 — Conteo con DP

**06 → 1.** ¿Qué dicen la regla de la suma y la del producto, y cuál aplica una DP de conteo en cada transición? 🟢

⏱️ **30 segundos.** Suma: si los objetos se parten en clases disjuntas, el total es la suma de las clases. Producto: si se forman con elecciones independientes sucesivas, el total es el producto. Cada transición de una DP de conteo aplica la regla de la suma sobre la última decisión.

🗣️ **2 minutos.** `cuenta(estado) = Σ cuenta(predecesor)`: los objetos que llegan al estado se clasifican por su último paso, y esas clases son disjuntas si cada objeto tiene un único último paso. El producto aparece al combinar subproblemas independientes (por ejemplo, los dos lados de un corte).

🔬 **El detalle.** La disyunción de las clases es lo que hay que comprobar; es la mitad de la condición de correspondencia de §2.

**06 → 2.** ¿Por qué se reduce el módulo en cada operación y no al final? 🟢

⏱️ **30 segundos.** Porque los valores crecen exponencialmente y desbordan cualquier tipo mucho antes del final; reducir en cada operación mantiene todo por debajo del módulo, y el resultado es el mismo por las propiedades de la aritmética modular.

🗣️ **2 minutos.** `(a + b) mod p = ((a mod p) + (b mod p)) mod p`, y lo mismo con el producto. Con valores menores que `p ≈ 10⁹`, una suma cabe en 32 bits con signo justo y un producto en 64 bits. Reducir solo al final es reducir un número que ya dio la vuelta.

🔬 **El detalle.** En Python no hay desbordamiento, pero los enteros enormes hacen cada operación más lenta: también se reduce.

**06 → 3.** ¿Qué es una partición de `n` y cuánto vale `p(5)`? 🟢

⏱️ **30 segundos.** Una forma de escribir `n` como suma de enteros positivos sin importar el orden. `p(5) = 7`: `5`, `4+1`, `3+2`, `3+1+1`, `2+2+1`, `2+1+1+1`, `1+1+1+1+1`.

🗣️ **2 minutos.** Se cuentan con la DP de monedas con valores `1..n` y las partes por fuera. `p(n)` crece como `e^(π√(2n/3)) / (4n√3)` (Hardy-Ramanujan).

🔬 **El detalle.** Las composiciones, que sí distinguen el orden, son `2ⁿ⁻¹`: 16 para `n = 5`.

**06 → 4.** ¿Por qué contar no es optimizar cambiando `max` por `+`? Da el ejemplo. 🟡

⏱️ **30 segundos.** Porque el máximo de un conjunto no cambia si un elemento aparece dos veces, y la suma sí. Con `aba`, «tomar o no cada letra» genera la subsecuencia `a` por dos caminos: el conteo dice 7 y son 6.

🗣️ **2 minutos.** En optimización da igual que la DP construya el mismo objeto de varias formas; en conteo, cada forma suma uno. La DP de conteo necesita una biyección entre objetos y caminos.

🔬 **El detalle.** El caso de prueba que lo delata siempre tiene elementos repetidos o decisiones que se pueden tomar en distinto orden.

**06 → 5.** ¿Qué distingue particiones de composiciones en el código? 🟡

⏱️ **30 segundos.** El anidamiento: con las partes por fuera (y las sumas por dentro), particiones; con las sumas por fuera (y las partes por dentro), composiciones.

🗣️ **2 minutos.** Con las partes por fuera, cada partición se construye con las partes en orden creciente, de una sola forma. Con las sumas por fuera, la última parte puede ser cualquiera, y `1+2` y `2+1` son caminos distintos.

🔬 **El detalle.** Es exactamente la distinción entre Coin Change II y Combination Sum IV de [`12/03`](03-mochilas.md).

**06 → 6.** ¿Qué estado usas para contar palabras con una regla sobre letras consecutivas, y cuál si la regla mira tres letras? 🟡

⏱️ **30 segundos.** La última letra. Si la regla mira tres letras seguidas, las dos últimas.

🗣️ **2 minutos.** El estado tiene que contener todo lo que la siguiente decisión necesita del pasado (Bellman). Con una regla sobre pares, la letra anterior; con una sobre tríos, el par anterior: `L²` estados. Si la regla es «no tres iguales», basta la última letra y la longitud de su racha (1 o 2).

🔬 **El detalle.** Con estados así y `n` enorme, la transición es una matriz fija y se eleva con exponenciación rápida ([`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md)).

**06 → 7.** Compara cómo haces `(a − b) mod p` y `(a · b) mod p` en C++, Java, Python y JavaScript. 🟡

⏱️ **30 segundos.** C++ y Java: `((a − b) % p + p) % p` y `a * b % p` con `long long`/`long`. Python: `(a − b) % p` ya es no negativo y `a * b % p` no desborda. JavaScript: el producto de dos valores de `10⁹` pierde precisión en `number`; `BigInt` o partir el producto.

🗣️ **2 minutos.** El `%` de C++ y Java conserva el signo del dividendo, así que una resta puede dar negativo. El producto necesita 64 bits porque `(10⁹)² = 10¹⁸`. En JavaScript, `number` es un `double` con 53 bits de mantisa: `10¹⁸` no se representa exacto.

🔬 **El detalle.** [`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md) tiene los detalles de JavaScript; con `BigInt`, `(a * b) % p` es exacto pero más lento.

**06 → 8.** Enuncia la condición de correspondencia que hace correcta una DP de conteo, y las dos formas de romperla. 🟠

⏱️ **30 segundos.** Que haya una biyección entre los objetos y los caminos del grafo de estados. Se rompe por dos caminos para un mismo objeto (cuenta de más) o por un objeto sin camino (cuenta de menos).

🗣️ **2 minutos.** Para conseguirla se fija un orden canónico (las monedas en orden), se fija la última decisión, o se resta lo repetido. Para comprobarla, se compara con la fuerza bruta en casos con elementos repetidos.

🔬 **El detalle.** Es el mismo argumento que en combinatoria: probar una fórmula de conteo es exhibir una biyección.

**06 → 9.** ¿Cómo cuentas subconjuntos con suma divisible por `k` sin recorrerlos, y por qué cada uno se cuenta una vez? 🟠

⏱️ **30 segundos.** Con `cnt[r]` = número de subconjuntos de los procesados con suma de resto `r`: para cada número `a`, `nuevo[r] = cnt[r] + cnt[(r − a) mod k]`. Cada subconjunto tiene un único camino: su secuencia de decisiones tomar o no.

🗣️ **2 minutos.** El estado no necesita la suma, solo su resto, porque la pregunta solo mira el resto y la transición respeta los restos. Hay `k` estados por paso: `Θ(n · k)`.

🔬 **El detalle.** El vacío cuenta (resto 0); si el enunciado lo excluye, se resta 1 al final.

**06 → 10.** ¿Cómo divides por 2 una cuenta calculada módulo `10⁹ + 7`? 🟠

⏱️ **30 segundos.** Multiplicando por el inverso de 2 módulo `p`: `(p + 1) / 2`, que para `p = 10⁹ + 7` es `500 000 004`.

🗣️ **2 minutos.** En aritmética modular no se divide: se multiplica por el inverso, que existe porque 2 y `p` son coprimos. En general, el inverso de `a` es `a^(p−2) mod p` por el pequeño teorema de Fermat ([`17/03`](../17-matematica/03-aritmetica-modular.md)).

🔬 **El detalle.** Dividir la cuenta reducida entre 2 con `/` da un resultado incorrecto si la cuenta reducida es impar, aunque la cuenta real sea par.

**06 → 11.** ¿Qué cambia entre contar particiones en partes distintas y en partes repetibles? 🟠

⏱️ **30 segundos.** El sentido del bucle de sumas: descendente para partes distintas (cada parte una vez, como la mochila 0/1), ascendente para partes repetibles (como la ilimitada).

🗣️ **2 minutos.** Con el bucle descendente, al usar la parte `k` se lee la cuenta de antes de considerar `k`, así que no se puede repetir. El orden de las partes (por fuera) es el mismo en los dos casos.

🔬 **El detalle.** Euler demostró que las particiones en partes distintas son tantas como las particiones en partes impares: con `n = 10`, 10 y 10.

**06 → 12.** Diseña la DP que cuenta las subsecuencias **distintas** de una cadena y explica qué resta y por qué. 🔴

⏱️ **30 segundos.** `d[i]` = número de subsecuencias distintas (contando la vacía) del prefijo de longitud `i`: `d[i] = 2 · d[i − 1] − d[j − 1]`, donde `j` es la aparición anterior de la misma letra (si existe). Se resta lo que ya se había formado terminando en esa letra.

🗣️ **2 minutos.** Duplicar cuenta todas las subsecuencias anteriores con y sin la letra nueva; pero las que acaban en la letra nueva formadas desde `d[j − 1]` ya se habían contado al añadir la aparición anterior. Restándolas, cada subsecuencia distinta queda contada una vez, asociada a su aparición más a la derecha.

🔬 **El detalle.** Con `aba`: `d = 1, 2, 4`, y al llegar a la segunda `a`, `d[3] = 2 · 4 − d[0] = 8 − 1 = 7` contando la vacía: 6 no vacías. Sin la resta saldrían 8, es decir, 7 no vacías.

**06 → 13.** Tu DP de conteo da 9 donde esperabas 4. ¿Cuál es la primera hipótesis y cómo la compruebas? 🔴

⏱️ **30 segundos.** Que cuenta sucesiones ordenadas en lugar de combinaciones (o al revés): el orden de los bucles. Se comprueba con la fuerza bruta en un caso pequeño con dos órdenes de los mismos elementos.

🗣️ **2 minutos.** 9 y 4 son las cuentas de sucesiones y combinaciones de pagar 6 con `{1, 3, 4}`. Si la diferencia es esa, cambiar el anidamiento lo arregla. Si no, la segunda hipótesis es un estado que permite construir el mismo objeto de dos formas.

🔬 **El detalle.** `12/03`, pregunta 13, y §2 de este capítulo.

**06 → Problema: Sin tres iguales.**

- **Pista 2 — patrón:** **conteo con estado = longitud de la racha final** (1 o 2).
- **Pista 3 — diseño:** `uno` = cadenas que acaban en una racha de longitud 1; `dos` = de longitud 2. Al añadir una letra distinta (`k − 1` opciones), se pasa a `uno`; igual, de `uno` a `dos`. `uno' = (uno + dos)(k − 1)`, `dos' = uno`, con `uno = k`, `dos = 0` para `n = 1`. Módulo en cada producto.

**06 → Problema: Partes distintas.**

- **Pista 2 — patrón:** **particiones en partes distintas**: mochila 0/1 de conteo.
- **Pista 3 — diseño:** `p[0] = 1`; para cada parte de 1 a `n`, `p[s] += p[s − parte]` con `s` **descendente**. `Θ(n²) = 2,5·10⁷`.

**06 → Problema: Pocos sumandos.**

- **Pista 2 — patrón:** **particiones con a lo sumo `m` partes**, con la conjugación o quitando 1 a cada parte.
- **Pista 3 — diseño:** `q(n, m) = q(n, m − 1) + q(n − m, m)`: o tiene menos de `m` partes, o tiene exactamente `m` y, restando 1 a cada una, queda una partición de `n − m` en a lo sumo `m` partes. `q(0, m) = 1`. `Θ(n · m)`.

**06 → Problema: Construct the Array.**

- **Pista 2 — patrón:** **conteo con estado reducido**: solo importa si el último valor es `x` o no.
- **Pista 3 — diseño:** `a` = arreglos que acaban en `x`, `b` = que no; `a' = b` (desde cualquiera no `x`), `b' = a · (k − 1) + b · (k − 2)`. Se empieza en 1 y la respuesta es `a` tras `n` posiciones.

**06 → Problema: Red John is Back.**

- **Pista 2 — patrón:** **conteo lineal** de embaldosados y después **criba**.
- **Pista 3 — diseño:** `f(n) = f(n − 1) + f(n − 4)` (una baldosa vertical o cuatro horizontales apiladas), `f(0..3) = 1`; después, cuenta los primos `≤ f(n)` con una criba ([`17/04`](../17-matematica/04-primos.md)).

**06 → Problema: Number of Dice Rolls With Target Sum.**

- **Pista 2 — patrón:** **conteo por dados y suma**.
- **Pista 3 — diseño:** `d[i][s] = Σ_{c=1..k} d[i−1][s − c]` con `d[0][0] = 1`; módulo en cada suma. Con prefijos sobre `s`, cada transición es `O(1)`.

**06 → Problema: Knight Dialer.**

- **Pista 2 — patrón:** **conteo con estado = la última tecla**.
- **Pista 3 — diseño:** precalcula a qué teclas salta el caballo desde cada una; `d[c] = Σ d_ant[p]` sobre las `p` que saltan a `c`; diez estados por paso.

**06 → Problema: Domino and Tromino Tiling.**

- **Pista 2 — patrón:** **conteo con estados del borde**.
- **Pista 3 — diseño:** `full[n]` = tableros `2 × n` completos y `part[n]` = con una casilla sobrante arriba (o abajo, por simetría). `full[n] = full[n−1] + full[n−2] + 2 · part[n−1]`; `part[n] = part[n−1] + full[n−2]`.

**06 → Problema: Count Ways To Build Good Strings.**

- **Pista 2 — patrón:** **conteo por longitud**.
- **Pista 3 — diseño:** `d[0] = 1`; `d[L] = d[L − zero] + d[L − one]`; la respuesta suma `d[L]` de `low` a `high`, con módulo.

**06 → Problema: Coin Combinations I.**

- **Pista 2 — patrón:** **contar sucesiones**: sumas por fuera.
- **Pista 3 — diseño:** `d[0] = 1`; para cada suma `s`, `d[s] = Σ d[s − c]` sobre las monedas; módulo `10⁹ + 7`.

**06 → Problema: Array Description.**

- **Pista 2 — patrón:** **conteo con estado = el último valor**.
- **Pista 3 — diseño:** `d[i][v]` = arreglos válidos hasta `i` con `a[i] = v`; si `a[i]` es fijo, solo ese `v`; `d[i][v] = d[i−1][v−1] + d[i−1][v] + d[i−1][v+1]`. `n · m = 10⁷`.

**06 → Problema: Count Vowels Permutation.**

- **Pista 2 — patrón:** **palabras con transiciones**: la plantilla del capítulo.
- **Pista 3 — diseño:** invierte las reglas («qué vocal puede ir **antes** de cada una») y suma; cinco estados por paso, módulo.

**06 → Problema: Counting Towers.**

- **Pista 2 — patrón:** **conteo con dos estados por altura**: la fila superior unida o partida.
- **Pista 3 — diseño:** `u` = torres cuya fila de arriba es un solo bloque de ancho 2, `s` = dos bloques separados; `u' = 2u + s`, `s' = u + 4s`. Precalcula hasta `10⁶` y responde cada consulta.

**06 → Problema: Number of Ways to Stay in the Same Place After Some Steps.**

- **Pista 2 — patrón:** **conteo con estado acotado**: la posición nunca pasa de `pasos/2`.
- **Pista 3 — diseño:** `d[p]` por paso, con `p` hasta `min(arrLen − 1, pasos/2)`; cada paso, `d'[p] = d[p − 1] + d[p] + d[p + 1]`; módulo.

---

# 07 — Simulación

**07 → S1.** ¿Qué cinco piezas tiene una DP y cuánto cuesta? 🟢

⏱️ **30 segundos.** Estado, transición, casos base, orden de cálculo y respuesta. Cuesta estados por coste de la transición.

🗣️ **2 minutos.** El estado identifica un subproblema; la transición lo calcula a partir de otros; los casos base no dependen de nadie; el orden asegura que las dependencias estén listas; la respuesta es un estado o una combinación.

🔬 **El detalle.** [`12/01`](01-de-la-recursion-a-la-tabla.md), §2.

**07 → S2.** ¿Qué dice el principio de optimalidad, dicho para programar? 🟡

⏱️ **30 segundos.** Que el estado tiene que contener todo lo que el futuro necesita saber del pasado.

🗣️ **2 minutos.** Si dos caminos llegan al mismo estado y el mejor futuro depende de cuál se tomó, falta información en el estado y hay que ampliarlo.

🔬 **El detalle.** `12/01`, §2.

**07 → S3.** ¿Cuándo memoizas y cuándo tabulas? 🟡

⏱️ **30 segundos.** Memoizo cuando la recursión es fácil y se visita una parte pequeña de los estados, y la profundidad es pequeña. Tabulo cuando la profundidad es grande, cuando quiero filas rodantes o cuando se visitan casi todos los estados.

🗣️ **2 minutos.** Las dos tienen el mismo estado y la misma transición; la memo usa pila y no necesita orden; la tabla necesita un orden y no usa pila.

🔬 **El detalle.** `12/01`, §6 y §7.

**07 → S4.** ¿Cómo reconstruyes la solución sin guardarla entera en cada estado? 🟢

⏱️ **30 segundos.** Guardando la última decisión de cada estado (un padre) y siguiendo la cadena desde la respuesta; o, en la mochila, comparando `dp[i][c]` con `dp[i−1][c]`.

🗣️ **2 minutos.** La solución de un estado es la del estado del que vino más una decisión: guardarla entera repite información y cuesta `Θ(n²)`.

🔬 **El detalle.** `12/01`, §5.

**07 → S5.** ¿Qué guarda el arreglo de colas de la LIS, y por qué no es la LIS? 🟡

⏱️ **30 segundos.** Para cada longitud, el menor final de una subsecuencia creciente de esa longitud. No es la LIS porque mezcla finales de subsecuencias distintas: con `[5, 2, 9, 1]` queda `[1, 9]`.

🗣️ **2 minutos.** Es estrictamente creciente, y eso permite la binaria; su longitud es la de la LIS. Para la subsecuencia, índices y padres.

🔬 **El detalle.** [`12/02`](02-dp-lineal-y-lis.md), §2 y §5.

**07 → S6.** ¿En qué sentido va el bucle de capacidad en la 0/1 de una fila, y en la ilimitada? 🟢

⏱️ **30 segundos.** Descendente en la 0/1; ascendente en la ilimitada.

🗣️ **2 minutos.** Descendente, `dp[c − w]` es todavía de la fila anterior: el objeto no se repite. Ascendente, ya incluye el objeto actual.

🔬 **El detalle.** `12/03`, §4 y §5.

**07 → S7.** ¿Por qué `O(n · W)` es pseudopolinomial? 🟡

⏱️ **30 segundos.** Porque es polinomial en el valor de `W`, que ocupa `log W` bits: exponencial en el tamaño de la entrada.

🗣️ **2 minutos.** Con `W = 10¹⁸`, la tabla no cabe aunque la entrada sea pequeña. Por eso la mochila sigue siendo NP-difícil.

🔬 **El detalle.** `12/03`, §2, y `10/05`.

**07 → S8.** ¿Qué decide el anidamiento de los bucles al contar formas de pagar? 🟡

⏱️ **30 segundos.** Si se cuentan combinaciones (monedas por fuera) o sucesiones ordenadas (sumas por fuera).

🗣️ **2 minutos.** Con monedas por fuera, cada combinación se construye en un orden fijo de monedas; con sumas por fuera, la última moneda puede ser cualquiera y `1+2` y `2+1` cuentan aparte.

🔬 **El detalle.** `12/03`, §6, y `12/06`, §2.

**07 → S9.** ¿Qué diferencia hay entre la LCS y la subcadena común más larga? 🟢

⏱️ **30 segundos.** La LCS es de subsecuencias (no contiguas); la subcadena común es contigua. Sus recurrencias difieren en qué hacer si los caracteres no coinciden: heredar el máximo o volver a 0.

🗣️ **2 minutos.** En la subcadena, el estado fija el final y la respuesta es el máximo de la tabla; en la LCS, la respuesta es la esquina.

🔬 **El detalle.** [`12/04`](04-dp-sobre-cadenas.md), pregunta 12.

**07 → S10.** ¿En qué orden se rellena una DP de intervalos? 🟢

⏱️ **30 segundos.** Por longitud del intervalo creciente (o `i` decreciente), porque cada tramo depende de tramos más cortos.

🗣️ **2 minutos.** Por filas se leerían tramos más largos todavía sin calcular. El bucle exterior es la longitud.

🔬 **El detalle.** `12/05`, §2.

**07 → S11.** ¿Por qué *burst balloons* elige el último globo y no el primero? 🟡

⏱️ **30 segundos.** Porque el último en reventar dentro de un tramo tiene como vecinos los extremos fijos, y los dos lados quedan independientes. Con el primero, los vecinos de los demás cambian.

🗣️ **2 minutos.** `d[l][r] = max_k d[l][k] + d[k][r] + v[l] · v[k] · v[r]`. Es el patrón de «la última operación del tramo».

🔬 **El detalle.** `12/05`, §5.

**07 → S12.** ¿Por qué contar no es optimizar cambiando `max` por `+`? 🟡

⏱️ **30 segundos.** Porque el máximo tolera que la DP construya el mismo objeto de varias formas, y la suma no: cada forma cuenta uno. Contar exige un camino único por objeto.

🗣️ **2 minutos.** Con `aba`, «tomar o no cada letra» da 7 subsecuencias no vacías y son 6 distintas. Se arregla con un orden canónico o restando lo repetido.

🔬 **El detalle.** `12/06`, §1 y §2.

**07 → S13.** «Esto es DP: elige qué hacer con cada elemento.» Pero `n ≤ 15`. ¿Qué haces? 🟠

⏱️ **30 segundos.** Enumerar: `2¹⁵ ≈ 3·10⁴` subconjuntos. La DP sería correcta, pero la fuerza bruta es más corta, más segura y además reconstruye trivialmente.

🗣️ **2 minutos.** Con `W` hasta `10⁹` la mochila por capacidad ni siquiera cabe; con `n ≤ 15`, el exponente cae en `n` y cabe de sobra. Y si hay que elegir la solución lexicográficamente menor, enumerar en orden lo hace solo.

🔬 **El detalle.** La regla de [`10/02`](../10-busqueda-completa-y-divide-y-venceras/02-generar-subconjuntos-y-permutaciones.md): antes de buscar algo polinomial, hacer la cuenta con el `n` máximo.

**07 → S14.** Tu DP con memo da la respuesta correcta y TLE. ¿Qué tres cosas miras? 🟠

⏱️ **30 segundos.** Que el resultado se guarda de verdad; que el centinela no es un valor posible; y que el estado no lleva información de más.

🗣️ **2 minutos.** Si la memo no se guarda o el centinela coincide con un valor válido, la recursión vuelve a ser exponencial. Si el estado incluye algo innecesario, multiplica los estados. Y en Python, `@cache` con tuplas de claves es lento: tabular.

🔬 **El detalle.** `12/01`, pregunta 12.

**07 → S15.** «La mochila es voraz por valor/peso.» ¿Qué respondes, con números? 🟠

⏱️ **30 segundos.** Que la fraccionaria sí, la 0/1 no. Con capacidad 10 y `(6, 9)` y `(10, 14)`, el voraz da 9 y el óptimo es 14.

🗣️ **2 minutos.** El voraz por razón deja huecos que, sin poder partir objetos, no se aprovechan. La 0/1 se resuelve con la DP de `12/03`.

🔬 **El detalle.** `11/04`, pregunta 10.

**07 → S16.** Tu DP de intervalos cambia de resultado al reordenar los bucles. ¿Qué pasa? 🟠

⏱️ **30 segundos.** Que se lee alguna celda antes de calcularla: el orden tiene que ser por longitud del tramo, y el resultado no puede depender del orden si este es válido.

🗣️ **2 minutos.** Compruebo que cada lectura sea de un tramo más corto y que los casos base y las inicializaciones (infinito para mínimos) estén bien. Una memoización sirve de oráculo.

🔬 **El detalle.** `12/05`, pregunta 13.

**07 → S17.** Te piden emparejar trabajadores con puestos minimizando la suma de diferencias, y empiezas una DP sobre máscaras. ¿Hay algo mejor? 🟠

⏱️ **30 segundos.** Sí: ordenar los dos lados y emparejar en orden. Por intercambio, dos parejas cruzadas nunca son mejores que las descruzadas. `Θ(n log n)` frente a `Θ(2ⁿ · n)`.

🗣️ **2 minutos.** Con `x ≤ y` y `a ≤ b`, `|x − a| + |y − b| ≤ |x − b| + |y − a|`: descruzar no empeora. Aplicándolo repetidamente, el emparejamiento ordenado es óptimo.

🔬 **El detalle.** Es un voraz con argumento de intercambio ([`11/01`](../11-voraces/01-cuando-funciona-un-voraz.md)). La DP sobre máscaras sería correcta solo para `n ≤ 20`.

**07 → S18.** Tu memoización da RE en Java con `n = 10⁵` y AC en C++. ¿Qué cambias? 🟠

⏱️ **30 segundos.** La profundidad de la recursión: en Java, lanzar el trabajo en un `Thread` con pila grande, o pasar a tabulación.

🗣️ **2 minutos.** La pila de Java por hilo es de ~1 MB; `10⁵` marcos no caben. La tabulación es el arreglo de raíz.

🔬 **El detalle.** `10/01`, §3, y `12/01`, §3.

**07 → S19.** Demuestra que el bucle descendente de la mochila 0/1 en una fila es correcto. 🔴

⏱️ **30 segundos.** Al procesar el objeto `i` con `c` descendente, las celdas mayores que `c` ya son de la fila `i` y las demás todavía de la `i − 1`. La transición lee `dp[c]` y `dp[c − w]`, ambas de la fila anterior: es la recurrencia 0/1.

🗣️ **2 minutos.** Invariante del bucle interno: inicializado con la fila `i − 1`, mantenido porque solo se escribe `dp[c]` tras leer posiciones `≤ c` no modificadas, y al acabar toda la fila es la `i`.

🔬 **El detalle.** `12/03`, pregunta 9.

**07 → S20.** Diseña la DP para unir montones dispuestos en **círculo**, y di su coste. 🔴

⏱️ **30 segundos.** Duplicar el arreglo (`a + a`), hacer la DP de intervalos de unir vecinos sobre tramos de longitud hasta `n`, y tomar el mínimo de `d[i][i + n − 1]` para cada inicio `i`. `Θ(n³)` con `2n` posiciones.

🗣️ **2 minutos.** En el círculo, alguna pareja de vecinos nunca se une directamente (la última unión junta dos arcos); cortando por ahí, queda una fila. Duplicar el arreglo representa todos los cortes a la vez, y cada tramo de longitud `n` es una fila posible.

🔬 **El detalle.** Con `n ≤ 200`, `(2n)² · n ≈ 3·10⁷`. Con la optimización de Knuth (`13/05`), `Θ(n²)`.

**07 → Problema: Maleta pequeña.**

- **Pista 2 — patrón:** **fuerza bruta sobre subconjuntos** (`2¹⁵`), recorridos en un orden que favorezca el desempate.
- **Pista 3 — diseño:** para cada subconjunto, peso y valor en 64 bits; si cabe y mejora el valor, o empata y su lista de índices es menor lexicográficamente, guárdalo. Con capacidad hasta `10⁹`, la mochila por capacidad no cabe.

**07 → Problema: Corrector con costes.**

- **Pista 2 — patrón:** **distancia de edición con costes**.
- **Pista 3 — diseño:** la tabla de prefijos con `D[i][0] = i · cd`, `D[0][j] = j · ci`, y `D[i][j] = min(D[i−1][j] + cd, D[i][j−1] + ci, D[i−1][j−1] + (iguales ? 0 : cs))`; dos filas; en 64 bits.

**07 → Problema: Montones en círculo.**

- **Pista 2 — patrón:** **DP de intervalos sobre el arreglo duplicado**.
- **Pista 3 — diseño:** con `b = a + a` y prefijos de `b`, `d[i][j] = min_k d[i][k] + d[k+1][j] + suma(i..j)` para tramos de longitud `≤ n`; la respuesta es `min_i d[i][i + n − 1]`.

**07 → Problema: Parejas de turnos.**

- **Pista 2 — patrón:** **voraz con intercambio**: ordenar los dos y emparejar en orden.
- **Pista 3 — diseño:** ordena preferencias y turnos y suma `|a_i − b_i|`. La prueba: dos parejas cruzadas se descruzan sin empeorar. En 64 bits.

**07 → Problema: House Robber II.**

- **Pista 2 — patrón:** **DP lineal en círculo**: dos DP sin círculo.
- **Pista 3 — diseño:** el máximo de la DP del robo sin la última casa y sin la primera; con una sola casa, su valor.

**07 → Problema: Maximum Product Subarray.**

- **Pista 2 — patrón:** **DP lineal con dos estados**: el máximo y el mínimo producto que acaban en `i`.
- **Pista 3 — diseño:** con `x`, los nuevos máximo y mínimo están entre `x`, `máx · x` y `mín · x`; la respuesta es el mayor máximo visto.

**07 → Problema: Partition Array for Maximum Sum.**

- **Pista 2 — patrón:** **DP lineal sobre el último trozo**.
- **Pista 3 — diseño:** `d[i] = max_{1 ≤ L ≤ k} d[i − L] + L · máx(a[i−L..i−1])`, llevando el máximo mientras `L` crece.

**07 → Problema: Ugly Number II.**

- **Pista 2 — patrón:** **DP con tres punteros** (mezcla de tres secuencias ordenadas).
- **Pista 3 — diseño:** `u[0] = 1`; tres índices `i2, i3, i5`; el siguiente es `min(2u[i2], 3u[i3], 5u[i5])`; avanza **todos** los índices que lo producen, para no repetir.

**07 → Problema: Equal.**

- **Pista 2 — patrón:** **transformar la operación** y una pequeña DP de monedas.
- **Pista 3 — diseño:** dar a todos menos a uno equivale a quitarle a uno; hay que bajar todos a un objetivo `t` entre `mín − 4` y `mín`, y cada diferencia se paga con el mínimo de «monedas» `{1, 2, 5}` (voraz, canónico); prueba los cinco objetivos.
