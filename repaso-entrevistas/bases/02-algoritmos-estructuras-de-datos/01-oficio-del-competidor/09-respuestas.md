# Respuestas — bloque 01: Oficio del competidor

> Solucionario del bloque `01`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--el-juez-los-veredictos-y-las-plataformas) · [02](#02--leer-las-restricciones-de-n-a-la-complejidad) · [03](#03--entrada-salida-y-la-plantilla-en-c-java-y-python) · [04](#04--tipos-desbordamiento-y-el-primer-contacto-con-el-módulo) · [05](#05--probar-sin-ide-casos-borde-depuración-y-stress-test) · [06](#06--el-protocolo-de-resolución-la-repetición-y-el-concurso) · [07](#07--programar-en-vivo) · [08](#08--simulación)

---

# 01 — El juez, los veredictos y las plataformas

**01 → 1.** ¿Qué significan AC, WA, TLE, MLE y RE, y en qué etapa del juez se produce cada uno? 🟢

⏱️ **30 segundos.** AC es que la salida coincide en todos los casos; WA, que terminó a tiempo pero imprimió otra cosa; TLE, que no terminó dentro del límite; MLE, que pasó el pico de memoria; RE, que el proceso murió. WA se decide al comparar; TLE, MLE y RE, al ejecutar.

🗣️ **2 minutos.** El juez compila, ejecuta un proceso por caso con límites de tiempo y memoria, y compara la salida. CE sale de la compilación; RE, TLE y MLE salen de la ejecución, porque son el proceso muriendo, pasándose de tiempo o de memoria; WA (y PE donde existe) sale de la comparación, porque el proceso terminó bien pero la salida no es la esperada.

🔬 **El detalle.** Las etiquetas no son excluyentes en la causa: un `OutOfMemoryError` de Java es memoria agotada, pero muchas plataformas lo reportan como RE porque el proceso termina con una excepción. Y un bucle infinito que imprime sin parar puede acabar en WA, en TLE o en un límite de salida, según dónde corte la plataforma.

**01 → 2.** ¿Qué compara el juez cuando compara «por *tokens*», y qué diferencias de formato ignora? 🟢

⏱️ **30 segundos.** Compara la secuencia de palabras separadas por espacios y saltos de línea, no los caracteres. Ignora cuántos espacios hay entre *tokens* y los saltos de línea del final.

🗣️ **2 minutos.** Parte las dos salidas por cualquier blanco y compara las dos listas resultantes. Por eso `1  2\n3` y `1 2 3` se consideran iguales. Lo que no ignora es el contenido del *token*: `1.0` y `1` son distintos salvo que el problema use comparación de reales con tolerancia, y `YES` y `Yes` son distintos salvo que el enunciado diga lo contrario.

🔬 **El detalle.** Algunos jueces antiguos comparaban carácter a carácter y devolvían *Presentation Error* cuando solo cambiaba el formato. Hoy casi todos tokenizan, así que PE prácticamente ha desaparecido; si no lo ves en la plataforma, un formato mal puesto suele llegar como WA solo cuando cambia los *tokens*.

**01 → 3.** ¿Qué campo de la API de LeetCode decide si un problema entra en este corpus, y por qué? 🟢

⏱️ **30 segundos.** `isPaidOnly`: si vale `true`, el problema es de pago y no entra, porque el corpus solo enlaza lo que cualquier lector puede abrir gratis.

🗣️ **2 minutos.** La API GraphQL de LeetCode devuelve, para un `titleSlug`, el título, la dificultad y `isPaidOnly`; si el problema no existe, devuelve `null`. Cada enlace de LeetCode del corpus se comprueba así al escribirlo y otra vez en la pasada de verificación.

🔬 **El detalle.** La página web de LeetCode responde `403` a una petición automática, así que el código de estado no sirve para verificar un enlace: hay que preguntar a la API. Es el mismo motivo por el que el corpus tiene una tabla de métodos de verificación por plataforma.

**01 → 4.** ¿Qué diferencia hay entre la puntuación de una prueba de empresa y la de un concurso? 🟡

⏱️ **30 segundos.** En la prueba de empresa la nota es parcial, por casos superados; en el concurso cada problema es todo o nada, y los envíos fallidos penalizan.

🗣️ **2 minutos.** En HackerRank o Codility, 9 de 15 casos valen el 60 % de ese problema, y reenviar no cuesta casi nada. En ICPC un envío fallido suma 20 minutos al tiempo; en AtCoder y LeetCode, 5; en una ronda de Codeforces, 50 puntos. Por eso la estrategia se invierte: en la empresa envías pronto la fuerza bruta correcta; en el concurso no envías nada sin probarlo.

🔬 **El detalle.** Hay formatos intermedios: los concursos tipo IOI puntúan por subtareas, que es parcial pero a bloques (una subtarea se gana entera o no se gana), y Codility pondera aparte corrección y rendimiento. El problema propio «Puntuación parcial» de este capítulo calcula exactamente esa diferencia.

**01 → 5.** ¿En qué se distingue un caso de corrección de uno de rendimiento en Codility? 🟡

⏱️ **30 segundos.** Los de corrección son pequeños y apuntan a los bordes; los de rendimiento son grandes y apuntan a la complejidad. Una solución correcta pero lenta pasa los primeros y cae en los segundos.

🗣️ **2 minutos.** Codility muestra el resultado separado en dos bloques, *correctness* y *performance*, y la nota combina ambos. Eso hace visible algo que en otros jueces es implícito: que la complejidad es parte de la corrección. Una solución cuadrática suele quedarse cerca de la mitad de la nota.

🔬 **El detalle.** Por eso en Codility conviene mirar la cota de `N` antes de escribir: si es `100 000`, el bloque de rendimiento traerá casos de ese tamaño, y `N²` son `10¹⁰` operaciones. El capítulo [`01/02`](02-leer-las-restricciones.md) convierte esa lectura en una tabla.

**01 → 6.** ¿Por qué un *checker* propio del problema no es lo mismo que comparar con una salida fija? 🟡

⏱️ **30 segundos.** Porque cuando el problema admite varias respuestas válidas, no hay una única salida con la que comparar: el *checker* comprueba que la tuya cumple las condiciones del enunciado.

🗣️ **2 minutos.** Si el problema dice «imprime cualquier camino más corto» o «cualquier permutación que cumpla…», comparar con una salida fija rechazaría respuestas correctas. El *checker* es un programa del problema que lee la entrada, tu salida y a veces la del autor, y valida la tuya: que el camino exista, que tenga la longitud mínima, que la permutación cumpla la propiedad.

🔬 **El detalle.** Lo mismo pasa con los reales: el *checker* compara con tolerancia. Y en los problemas interactivos ([`20/03`](../20-ad-hoc-constructivos-e-interactivos/03-interactivos.md)) el *checker* conversa con tu programa. Para quien resuelve, la consecuencia es leer con cuidado si el enunciado dice «cualquiera» o «la menor lexicográficamente»: lo segundo sí exige una salida concreta.

**01 → 7.** Tu envío da TLE en el caso 3 de 40. ¿Qué sospechas primero, y por qué distinto que si fuera el caso 38? 🟠

⏱️ **30 segundos.** En el caso 3, sospecho de un bucle infinito o de una lectura de entrada que se queda esperando, no de la complejidad: el caso 3 casi nunca es grande. En el 38 sospecharía primero de la complejidad o de la E/S lenta.

🗣️ **2 minutos.** Los casos se ordenan de pequeños a grandes, así que un TLE temprano en un caso pequeño apunta a algo que no termina: una condición de salida mal puesta, un `while` cuyo índice no avanza en algún borde, o leer más datos de los que hay. Un TLE en los últimos casos, en cambio, es lo esperable de un algoritmo cuya complejidad no cabe en las restricciones, o de una E/S lenta con entrada grande.

🔬 **El detalle.** La regla es orientativa: algunos problemas meten un caso grande pronto, y en una prueba de empresa ni siquiera ves el número. Lo que sí es fiable es el razonamiento: compara la complejidad de tu solución con la cota de `n` antes de culpar al juez, y si encaja, busca el bucle que no termina.

**01 → 8.** En una prueba de empresa de 90 minutos tienes una fuerza bruta correcta a los 20 minutos y una idea óptima sin probar. ¿Qué haces, y por qué al revés en un concurso? 🟠

⏱️ **30 segundos.** En la prueba de empresa envío ya la fuerza bruta, porque asegura los casos pequeños, y después trabajo la óptima. En un concurso no enviaría la óptima sin probarla, porque un envío fallido penaliza y no da puntos.

🗣️ **2 minutos.** En la empresa la nota es parcial y reenviar no penaliza: la fuerza bruta correcta convierte 20 minutos de trabajo en puntos seguros, y si la óptima sale mal, esos puntos siguen ahí. En el concurso la nota es todo o nada y cada envío fallido cuesta minutos o puntos; ahí lo racional es probar la óptima contra la fuerza bruta (el *stress test* de [`01/05`](05-probar-sin-ide-y-stress-test.md)) antes de enviarla.

🔬 **El detalle.** La fuerza bruta no se tira en ningún formato: en el concurso es el oráculo con el que pruebas la óptima. Y en la prueba de empresa conviene guardar una copia antes de reescribir: algunas plataformas puntúan el último envío, no el mejor.

**01 → 9.** ¿Por qué un código C++20 válido puede dar CE en HackerRank, y cómo lo evitas? 🟠

⏱️ **30 segundos.** Porque la opción «C++20» de HackerRank compila con G++ 8.3, que casi no implementa C++20. Se evita eligiendo la opción «C++23», que usa G++ 14.2.

🗣️ **2 minutos.** El nombre de la opción indica el estándar que se pide al compilador, no que el compilador lo implemente. G++ 8.3 es de 2019: `std::ranges`, `<numbers>` y casi todo C++20 no existen ahí, así que un código válido da CE. La opción «C++23» usa un G++ moderno que compila C++20 sin problema, y el corpus fija C++20 como estándar justo para compilar en las tres plataformas.

🔬 **El detalle.** La regla general es leer la página de entorno de cada plataforma antes de usarla. Codility ofrece G++ 10.3 y 13.3, y lo de C++23 que 13.3 no trae, como `std::print`, tampoco se usa en el corpus.

**01 → 10.** Compara C++, Java y Python ante el mismo problema con límite de 1 segundo en un concurso y en HackerRank: ¿qué cambia para cada lenguaje? 🟠

⏱️ **30 segundos.** En un concurso el límite suele ser el mismo para todos, así que C++ va holgado, Java pierde algo por el arranque y la E/S, y Python puede no entrar. En HackerRank el límite crece con el lenguaje: 2 segundos para C++, 4 para Java y 10 para Python.

🗣️ **2 minutos.** HackerRank compensa la lentitud de cada lenguaje, pero solo a medias: Python recibe 5 veces más tiempo que C++ y en bucles puede ser 30–50 veces más lento. En un concurso no hay compensación, y una solución correcta en la complejidad justa puede dar TLE en Python. Java está en medio: con E/S rápida y tipos primitivos se acerca a C++; con `Scanner` y `List<Integer>` se aleja.

🔬 **El detalle.** La conclusión práctica es leer la cota con el lenguaje en mente (`01/02`): con `n = 10⁶` y un algoritmo lineal, los tres entran; con `n = 10⁷` o `n log n` sobre `10⁶` en Python, la duda es real. Las cifras de HackerRank se comprobaron en su página de entorno el 2026-10-03.

**01 → 11.** Un envío en Java da RE en el caso 25, el más grande, y el código no tiene accesos a arreglos sospechosos. Da dos causas posibles y cómo distinguirlas. 🔴

⏱️ **30 segundos.** Una pila desbordada por recursión profunda, que en Java es un `StackOverflowError`, o memoria agotada, que es un `OutOfMemoryError`. Las dos son excepciones, y por eso llegan como RE.

🗣️ **2 minutos.** Que falle solo el caso más grande apunta al tamaño. Si el código es recursivo y la profundidad crece con `n` —un DFS sobre una lista de `10⁵` nodos—, es la pila: la de Java es pequeña por defecto. Si crea estructuras proporcionales a `n` con objetos (`List<Integer>`, mapas de cajas), es el *heap*. Se distinguen reproduciendo el caso grande en local y leyendo la excepción, o generando una entrada máxima con la forma que lleva a la recursión más profunda.

🔬 **El detalle.** El arreglo de la pila es lanzar el trabajo en un `Thread` con pila grande o convertir la recursión en iterativa ([`03/03`](../03-biblioteca-estandar/03-java-colecciones.md) y [`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md)); el de la memoria, tipos primitivos en vez de objetos ([`02/05`](../02-analisis/05-el-coste-real.md)). Hay una tercera causa menos frecuente: una división por cero o un `NumberFormatException` que solo aparece con los valores extremos del caso grande.

**01 → 12.** Diseña la regla de comparación de un juez para un problema cuya respuesta es un real: qué tolerancia, absoluta o relativa, y un ejemplo de salida que una comparación exacta rechazaría injustamente. 🔴

⏱️ **30 segundos.** Tolerancia combinada: acepto si el error absoluto **o** el relativo es menor que `10⁻⁶`. Una comparación exacta rechazaría `0.30000000000000004` frente a `0.3`, que es la misma respuesta.

🗣️ **2 minutos.** El error absoluto solo funciona bien si las respuestas son de magnitud moderada: con respuestas de orden `10⁹`, un `double` no tiene precisión absoluta de `10⁻⁶`. El relativo solo funciona lejos de cero: si la respuesta esperada es `0`, cualquier error relativo es infinito. Por eso la regla estándar es `|tuya − esperada| ≤ ε · max(1, |esperada|)`, que es absoluta cerca de cero y relativa para valores grandes.

🔬 **El detalle.** El enunciado debe decir la tolerancia y el participante debe imprimir suficientes decimales: con 6 decimales y tolerancia `10⁻⁶` se queda al borde por redondeo, así que se imprimen 9 o 10. La comparación de reales con tolerancia dentro de tu propio código es otra cosa, y es de [`01/04`](04-tipos-desbordamiento-y-modulo.md).

**01 → Problema: Suma de la jornada.**

- **Pista 2 — patrón:** es un problema de **tipos**: el algoritmo es una suma, y lo único que puede fallar es que el resultado no quepa en un entero de 32 bits.
- **Pista 3 — diseño:** la suma máxima es `2·10⁵ · 10⁹ = 2·10¹⁴`, que no cabe en `int` (tope ~`2,1·10⁹`) y sí en un entero de 64 bits; el acumulador tiene que ser de 64 bits **desde el principio**, no solo el resultado.

**01 → Problema: El comparador del juez.**

- **Pista 2 — patrón:** es **procesamiento de cadenas** en dos normalizaciones distintas: partir por blancos para comparar *tokens*, y borrar todos los blancos para detectar el PE.
- **Pista 3 — diseño:** lee las `a` y las `b` líneas sin perder las vacías; construye dos listas de *tokens* y compáralas; si son iguales, `AC`; si no, concatena los *tokens* de cada salida sin separador y compara las dos cadenas: iguales, `PE`; distintas, `WA`.

**01 → Problema: Puntuación parcial.**

- **Pista 2 — patrón:** es **simulación directa**: dos recorridos sobre los mismos datos con dos reglas de agregación distintas, una por caso y otra por grupo.
- **Pista 3 — diseño:** acumula el total de casos y el de casos `AC` para la regla de empresa, y calcula `⌊100 · AC / total⌋` con aritmética entera al final; para las subtareas, una bandera por subtarea que empieza en verdadero y se apaga con el primer veredicto distinto de `AC`.

**01 → Problema: Solve Me First.**

- **Pista 2 — patrón:** formato de **función con plantilla**: la plataforma lee la entrada y llama a tu función.
- **Pista 3 — diseño:** solo devuelves la suma de los dos parámetros; no leas ni imprimas nada fuera de lo que la plantilla ya hace.

**01 → Problema: Simple Array Sum.**

- **Pista 2 — patrón:** función con plantilla que recibe un arreglo ya leído.
- **Pista 3 — diseño:** un acumulador que recorre el arreglo; el tipo del acumulador es el que pide la firma.

**01 → Problema: Running Sum of 1d Array.**

- **Pista 2 — patrón:** formato **clase `Solution`** de LeetCode: devuelves una estructura, no imprimes.
- **Pista 3 — diseño:** el elemento `i` del resultado es el anterior más `nums[i]`; un solo recorrido, y puedes escribir sobre el propio arreglo si la firma lo permite.

**01 → Problema: Fizz Buzz.**

- **Pista 2 — patrón:** simulación directa con **orden de condiciones**.
- **Pista 3 — diseño:** comprueba primero la condición más restrictiva (divisible por 3 y por 5), después las otras dos, y si ninguna, el número como cadena.

**01 → Problema: BinaryGap.**

- **Pista 2 — patrón:** recorrido de los **bits** de `N` con un estado mínimo.
- **Pista 3 — diseño:** recorre los bits de menor a mayor; el contador de ceros solo empieza después del primer 1 y solo cuenta como hueco cuando lo cierra otro 1; guarda el máximo de los huecos cerrados.

**01 → Problema: CyclicRotation.**

- **Pista 2 — patrón:** aritmética de **índices módulo `N`**, con los bordes primero.
- **Pista 3 — diseño:** con `N = 0` devuelves el arreglo tal cual; si no, el elemento `i` va a la posición `(i + K) mod N`, y `K` mayor que `N` se reduce solo con el módulo.

**01 → Problema: Weird Algorithm.**

- **Pista 2 — patrón:** **simulación** con cuidado de tipos.
- **Pista 3 — diseño:** aplica la regla hasta llegar a 1 e imprime cada valor; los valores intermedios pasan de `2³¹`, así que la variable es de 64 bits.

**01 → Problema: Watermelon.**

- **Pista 2 — patrón:** **caso borde** de paridad.
- **Pista 3 — diseño:** hacen falta dos partes pares y positivas: el peso tiene que ser par **y** mayor que 2; el 2 es par y no se puede partir así.

**01 → Problema: A - Product.**

- **Pista 2 — patrón:** **propiedad de la paridad** del producto.
- **Pista 3 — diseño:** el producto es par si y solo si alguno de los dos factores es par; no hace falta multiplicar.

**01 → Problema: Hello World!.**

- **Pista 2 — patrón:** formato exacto de salida.
- **Pista 3 — diseño:** copia la cadena del enunciado carácter por carácter, con mayúsculas y signos, y termina con un salto de línea.

---

# 02 — Leer las restricciones: de `n` a la complejidad

**02 → 1.** ¿Cuántas operaciones simples por segundo asume la regla de bolsillo, y qué cuenta como «simple»? 🟢

⏱️ **30 segundos.** Del orden de 10⁸ por segundo. «Simple» es una suma, una comparación o un acceso a un arreglo que está en caché.

🗣️ **2 minutos.** Se usa así: calculas los pasos de tu algoritmo con el `n` máximo y los comparas con `10⁸` por segundo de límite. Por debajo de `10⁷` vas holgado en cualquier lenguaje; entre `10⁷` y `10⁸` cabe en C++ y Java; por encima de `10⁹` no cabe.

🔬 **El detalle.** Lo que no es simple cuesta varias «operaciones»: una división entera, un fallo de caché (del orden de cien sumas), una llamada a un `HashMap` con *boxing*. Por eso un algoritmo de `10⁸` pasos con accesos aleatorios a memoria puede tardar varios segundos y otro de `5·10⁸` con acceso secuencial entrar en uno.

**02 → 2.** ¿Qué complejidad cabe en un segundo con `n ≤ 20`, con `n ≤ 5 000` y con `n ≤ 2·10⁵`? 🟢

⏱️ **30 segundos.** Con `n ≤ 20`, exponencial: `2ⁿ · n`. Con `n ≤ 5 000`, cuadrática. Con `n ≤ 2·10⁵`, `n log n`.

🗣️ **2 minutos.** Las cuentas: `2²⁰ · 20 ≈ 2·10⁷`; `5000² = 2,5·10⁷`; `2·10⁵ · 18 ≈ 3,6·10⁶`. Las tres quedan bajo `10⁸`. La siguiente fila de cada una no cabe: `2²⁵·25` ya pasa de `8·10⁸`, `n²` con `2·10⁵` son `4·10¹⁰`, y `n log n` con `10⁷` son `2,3·10⁸`.

🔬 **El detalle.** Las cotas también se leen como intención del autor: `n ≤ 20` pide subconjuntos o máscaras, `n ≤ 5 000` suele pedir una DP en dos dimensiones, y `n ≤ 2·10⁵` pide ordenar, un heap, una búsqueda binaria o un árbol de segmentos.

**02 → 3.** ¿Cuántos `int` caben en 256 MB, y cuántos `long long`? 🟢

⏱️ **30 segundos.** Unos 6,7·10⁷ `int` y unos 3,3·10⁷ `long long`: 256 MB son 268 435 456 bytes, entre 4 y entre 8.

🗣️ **2 minutos.** La cuenta es elementos por bytes: `int` ocupa 4 bytes y `long long` 8. En la práctica no se usa el límite entero, porque el programa tiene más cosas en memoria; con la mitad para la estructura grande vas tranquilo.

🔬 **El detalle.** En Java un `Integer` dentro de una colección cuesta unos 16 bytes más el puntero, cuatro o cinco veces un `int`; en Python un entero cuesta unos 28 bytes más el puntero de la lista. Por eso el «cabe» de C++ no se traslada a esos lenguajes si usas objetos.

**02 → 4.** ¿Qué diferencia hay entre una cota de tamaño y una cota de valor, y qué decide cada una? 🟡

⏱️ **30 segundos.** La de tamaño (`n`, `m`, `q`) decide la complejidad; la de valor (`a[i] ≤ 10⁹`) decide los tipos y si puedes indexar por valor.

🗣️ **2 minutos.** `n ≤ 10⁵` te deja `n log n`; que los valores lleguen a `10⁹` te prohíbe un arreglo de conteo indexado por valor y te obliga a sumar en 64 bits. El mismo problema con valores `≤ 10⁵` admite el arreglo de conteo y suele volverse lineal.

🔬 **El detalle.** Una cota de valor enorme, como `x ≤ 10¹⁸`, también decide la complejidad: no puedes recorrer hasta `x`, así que necesitas algo en `log x` o `√x`. Ahí el valor hace de tamaño.

**02 → 5.** Un enunciado tiene `t ≤ 10⁴` casos con `n ≤ 2·10⁵` cada uno. ¿Qué línea del enunciado buscas antes de calcular, y por qué cambia todo? 🟡

⏱️ **30 segundos.** La que acota **la suma de `n` sobre todos los casos**. Si existe, el trabajo total depende de esa suma, no de `t · n`.

🗣️ **2 minutos.** Sin esa línea, el peor caso son `10⁴` casos de `2·10⁵`: `2·10⁹` elementos, que ni siquiera se leen a tiempo. Con ella, el total de elementos es `2·10⁵`, y un algoritmo `O(n log n)` por caso suma `O(N log N)` con `N` la suma.

🔬 **El detalle.** La trampa clásica es inicializar en cada caso una estructura del tamaño **máximo** de `n` (un `memset` de `2·10⁵` por caso): con `10⁴` casos eso son `2·10⁹` operaciones aunque la suma de `n` sea pequeña. Se inicializa solo lo que el caso usa.

**02 → 6.** ¿Por qué la regla de los 10⁸ es orientativa, si un procesador ejecuta miles de millones de instrucciones por segundo? 🟡

⏱️ **30 segundos.** Porque una operación del análisis no es una instrucción: un fallo de caché, una división o una llamada con objetos cuestan decenas o cientos de instrucciones.

🗣️ **2 minutos.** El procesador hace miles de millones de instrucciones simples por segundo cuando los datos están en caché y el código es predecible. El código real mezcla accesos a memoria dispersos, saltos difíciles de predecir y llamadas; `10⁸` es el promedio honesto de todo eso.

🔬 **El detalle.** La misma complejidad puede variar un orden de magnitud por la localidad: recorrer una matriz por filas es mucho más rápido que por columnas. Ese es el tema de `02/05`.

**02 → 7.** Compara C++, Java y Python ante `n log n` con `n = 10⁶`: ¿cabe en un segundo en cada uno, y qué detalle de cada lenguaje decide? 🟡

⏱️ **30 segundos.** `n log n` con `10⁶` son unos `2·10⁷` pasos: cabe en C++ con holgura, en Java cabe con primitivos y se aprieta con objetos, y en Python va justo o no entra si el bucle es tuyo.

🗣️ **2 minutos.** En C++ la constante es la referencia. En Java decide si usas `int[]` y `Arrays.sort` o `List<Integer>` y `Collections.sort`, y si la entrada se lee con `Scanner`. En Python decide si el trabajo lo hace `sorted` o `heapq`, que están en C, o un bucle tuyo de `2·10⁷` iteraciones, que tarda varios segundos.

🔬 **El detalle.** Por eso en Python se dice que pierdes una fila de la tabla. Y en Java hay un matiz más: `Arrays.sort` sobre primitivos es un *quicksort* de doble pivote, que desde Java 14 cambia a *heapsort* si la recursión se hace demasiado profunda y garantiza `n log n`, mientras que sobre objetos es TimSort; en Java 8 y 11, que algunos jueces aún ofrecen, el de primitivos se podía forzar a cuadrático (`03/03`).

**02 → 8.** Con `n ≤ 10⁵` y `q ≤ 10⁵` consultas sobre rangos, ¿por qué no basta con responder cada consulta recorriendo el rango? 🟠

⏱️ **30 segundos.** Porque son `n · q = 10¹⁰` pasos en el caso peor: cien veces lo que cabe. Hay que preprocesar para responder cada consulta en `O(1)` o `O(log n)`.

🗣️ **2 minutos.** Cada parámetro entra en la cuenta: el coste es preproceso más `q` veces el coste de una consulta. Con prefijos, la suma de un rango sale en `O(1)` tras `O(n)` de preproceso; si hay actualizaciones, un Fenwick o un árbol de segmentos da `O(log n)` por operación.

🔬 **El detalle.** El caso peor lo fija el autor: si los rangos fueran siempre cortos, el recorrido iría bien, pero un caso adversario pondrá todos los rangos de `1` a `n`. Se razona siempre con el peor caso que permiten las cotas.

**02 → 9.** Un enunciado dice `n ≤ 40`. ¿Qué te está diciendo el autor, y por qué no es ni `2ⁿ` ni `n²`? 🟠

⏱️ **30 segundos.** Que espera algo del orden de `2^(n/2)`: partir en dos mitades de 20, enumerar cada una y combinarlas. `2⁴⁰` no cabe, y `n²` sería absurdo para un `n` tan pequeño.

🗣️ **2 minutos.** `2⁴⁰ ≈ 10¹²` es inalcanzable; `2²⁰ ≈ 10⁶` por mitad sí. Si el problema fuera polinomial, el autor habría puesto `n ≤ 10⁵`. La cota de 40 es casi una firma de la técnica de partir en mitades (*meet in the middle*), que el corpus trata en [`10/04`](../10-busqueda-completa-y-divide-y-venceras/04-meet-in-the-middle-iddfs-y-dancing-links.md).

🔬 **El detalle.** No es una regla absoluta: a veces `n ≤ 40` es una búsqueda con poda muy agresiva o una DP con un estado raro. Pero la lectura correcta es «exponencial, y no en `n` sino en `n/2`».

**02 → 10.** Tu solución recursiva tiene la complejidad correcta, cabe en memoria y da RE en el caso grande. ¿Qué cota olvidaste mirar? 🟠

⏱️ **30 segundos.** La profundidad de la recursión contra el tamaño de la pila. La pila es mucho más pequeña que la memoria total.

🗣️ **2 minutos.** Una recursión de profundidad `10⁵` necesita `10⁵` marcos de pila. En Java la pila de un hilo es del orden de 1 MB y se desborda con un `StackOverflowError`; en Python el límite por defecto es de 1000 llamadas. El juez lo informa como RE, aunque la memoria total sobre.

🔬 **El detalle.** El arreglo depende del lenguaje: en Java, ejecutar en un `Thread` con pila grande; en Python, subir el límite de recursión y la pila del hilo, o pasar a iterativo; en C++ la pila suele ser más generosa en los jueces, pero no ilimitada. El bloque `03` da cada receta.

**02 → 11.** Calcula si cabe una matriz de `long long` de `n × n` con `n = 10⁴` en 256 MB, y propone qué harías si no cabe. 🔴

⏱️ **30 segundos.** `10⁸` celdas por 8 bytes son 800 MB: no cabe en 256. Necesito no guardar la matriz entera.

🗣️ **2 minutos.** Las salidas, por orden: ¿basta con la fila anterior? Entonces guardo dos filas, `O(n)` memoria. ¿Los valores caben en `int` o en menos? Pasar a 4 bytes deja 400 MB, que sigue sin caber, así que no basta. ¿Es dispersa? Guardo solo las celdas no nulas en un mapa. ¿Solo importan sumas por fila y columna? Guardo dos arreglos de tamaño `n`.

🔬 **El detalle.** Es el patrón de la DP con «rodar» filas ([`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md)) y de las matrices dispersas ([`04/05`](../04-secuencias/05-matrices.md)). La cuenta de memoria va antes que el código: si la idea necesita `n²` con `n = 10⁴` en 64 bits, la idea hay que cambiarla.

**02 → 12.** Con `n ≤ 10⁵` y valores `a[i] ≤ 10⁹`, el problema pide contar parejas con cierta propiedad. Decide el tipo de la respuesta y justifica la cota que usas. 🔴

⏱️ **30 segundos.** Entero de 64 bits. El número de parejas llega a `n(n−1)/2 ≈ 5·10⁹`, que pasa de `2³¹ − 1 ≈ 2,1·10⁹`.

🗣️ **2 minutos.** La cota que importa no es la de los valores sino la del número de parejas: `10⁵ · (10⁵ − 1) / 2 = 4 999 950 000`. Eso no cabe en `int` (ni siquiera en un `unsigned` de 32 bits, tope ~`4,29·10⁹`). En C++ `long long`, en Java `long`, en Python no hace falta nada.

🔬 **El detalle.** Y el contador tiene que ser de 64 bits **mientras cuentas**, no al final: si acumulas en `int` y conviertes al terminar, ya desbordó. Si además la propiedad implica sumar valores, `a[i] + a[j]` llega a `2·10⁹`, que también pasa de `int`.

**02 → 13.** Para el problema de §1 (contar parejas que suman `K`), escribe la cuenta de pasos de la fuerza bruta con el `n` máximo, decide qué complejidad necesitas y nombra dos técnicas que la dan. 🔴

⏱️ **30 segundos.** La fuerza bruta son `n(n−1)/2 ≈ 2·10¹⁰` pasos con `n = 2·10⁵`: unas 200 veces lo que cabe. Necesito `O(n log n)` o `O(n)`: ordenar y dos punteros, o una tabla hash de conteos.

🗣️ **2 minutos.** Con la tabla de §3, `2·10⁵` pide `n log n`. Ordenando, cada valor busca su complemento con búsqueda binaria o con dos punteros que se cruzan, y se cuentan los iguales en bloque. Con un mapa de conteos, se recorre una vez sumando, para cada `a[j]`, cuántas veces apareció antes `K − a[j]`: `O(n)` esperado.

🔬 **El detalle.** La respuesta llega a `2·10¹⁰`, así que el contador es de 64 bits, y `K − a[j]` llega a `2·10⁹`, así que el cálculo también. El mapa es esperado `O(1)` por operación, y un caso adversario puede atacarlo ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)); ordenar da `O(n log n)` en caso peor sin ese riesgo.

**02 → Problema: ¿Cabe o no cabe?.**

- **Pista 2 — patrón:** es **estimación por restricciones**, pero con números que desbordan cualquier tipo: no puedes calcular `2ⁿ` ni `n!` y luego comparar.
- **Pista 3 — diseño:** compara sin calcular el número grande: para `2n` y `nfact`, multiplica paso a paso y corta en cuanto el producto pase de `10⁸ · s`; para `n2` y `n3`, compara `n` con la raíz cuadrada o cúbica del umbral (o multiplica en 64 bits con cuidado de no pasar de `10¹⁸`); para `logn` y `nlogn`, `⌈log₂ n⌉` se obtiene contando bits.

**02 → Problema: Parejas que suman K.**

- **Pista 2 — patrón:** **conteo de complementos** con una tabla hash de frecuencias, o **ordenación** y conteo de bloques iguales; la cota descarta `n²`.
- **Pista 3 — diseño:** recorre de izquierda a derecha manteniendo `veces[v]` = cuántas veces apareció `v` antes de la posición actual; al llegar a `a[j]`, suma `veces[K − a[j]]` a la respuesta y después incrementa `veces[a[j]]`. La respuesta y `K − a[j]` van en 64 bits.

**02 → Problema: Filas y columnas vigiladas.**

- **Pista 2 — patrón:** **inclusión-exclusión** sobre conjuntos de filas y columnas; la matriz de `10¹⁰` celdas no cabe, así que no se construye.
- **Pista 3 — diseño:** sea `f` el número de filas distintas con al menos un guardia y `c` el de columnas distintas; las celdas vigiladas son `f·C + c·R − f·c`. Hay que contar distintos (dos guardias en la misma fila no la cuentan dos veces) y hacer la cuenta en 64 bits, porque llega a `10¹⁰`.

**02 → Problema: Two Sum.**

- **Pista 2 — patrón:** **leer la cota**: con el `n` de este enunciado la fuerza bruta cabe, y la versión con tabla hash de complementos es la mejora que te van a pedir en una entrevista.
- **Pista 3 — diseño:** recorre guardando cada valor visto con su índice en un mapa; para cada `nums[i]`, busca `target − nums[i]` entre los vistos antes de insertarlo.

**02 → Problema: Contains Duplicate.**

- **Pista 2 — patrón:** **conjunto hash** u **ordenación**; la cota de `n` descarta comparar todas las parejas.
- **Pista 3 — diseño:** un conjunto de los vistos, y en cuanto un valor ya está, devuelves verdadero; o bien ordenas y miras si dos vecinos son iguales.

**02 → Problema: Maximum Subarray.**

- **Pista 2 — patrón:** **subarreglo de suma máxima**, un recorrido lineal (algoritmo de Kadane, [`04/03`](../04-secuencias/03-kadane-y-subarreglos.md)); la cota pide `O(n)` o `O(n log n)`.
- **Pista 3 — diseño:** mantén la mejor suma de un subarreglo que **termina** en la posición actual: o extiende el anterior o empieza de nuevo aquí; la respuesta es el máximo de esos valores.

**02 → Problema: Sherlock and Array.**

- **Pista 2 — patrón:** **sumas de prefijos**: la suma total menos la izquierda menos el elemento da la derecha.
- **Pista 3 — diseño:** calcula el total una vez; recorre manteniendo la suma de la izquierda; en la posición `i`, la derecha es `total − izquierda − a[i]`; responde en cuanto coincidan.

**02 → Problema: TapeEquilibrium.**

- **Pista 2 — patrón:** **prefijos** con un barrido del punto de corte.
- **Pista 3 — diseño:** el corte va de `1` a `N − 1` (las dos partes no vacías); mantén la suma de la izquierda y obtén la de la derecha como total menos izquierda; el mínimo de las diferencias absolutas es la respuesta.

**02 → Problema: CountDiv.**

- **Pista 2 — patrón:** **fórmula** en vez de recorrido: el valor de `B` impide iterar.
- **Pista 3 — diseño:** los múltiplos de `K` en `[0, x]` son `⌊x / K⌋ + 1`; la respuesta es la diferencia entre los de `[0, B]` y los de `[0, A − 1]`, con cuidado cuando `A = 0`.

**02 → Problema: Array Manipulation.**

- **Pista 2 — patrón:** **arreglo de diferencias** ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)): cada operación de rango se registra en `O(1)`.
- **Pista 3 — diseño:** suma `k` en el inicio del rango y resta `k` justo después del final; al terminar, un recorrido de prefijos reconstruye los valores y da el máximo. Los valores llegan a `m · k`, así que van en 64 bits.

**02 → Problema: Count Number of Bad Pairs.**

- **Pista 2 — patrón:** **contar el complemento**: el total de parejas menos las buenas, y las buenas se agrupan por una clave.
- **Pista 3 — diseño:** `j − i = nums[j] − nums[i]` equivale a `nums[i] − i = nums[j] − j`; agrupa por `nums[i] − i` con un mapa de conteos, cuenta las parejas buenas de cada grupo y réstalas de `n(n−1)/2`, todo en 64 bits.

**02 → Problema: Number Spiral.**

- **Pista 2 — patrón:** **fórmula cerrada** por capas; el valor de las coordenadas impide construir nada.
- **Pista 3 — diseño:** la capa es `max(y, x)`; el número más grande de la capa `k` es `k²`, y el sentido en que se recorre depende de la paridad de `k`; con eso se calcula la posición dentro de la capa. Los valores llegan a `10¹⁸`.

**02 → Problema: Missing Number.**

- **Pista 2 — patrón:** **suma conocida** de `1` a `n` menos la suma leída.
- **Pista 3 — diseño:** `n(n+1)/2` menos la suma de los `n − 1` números dados; con `n = 2·10⁵` el total pasa de `2·10¹⁰`, así que en 64 bits (o el XOR de todos, que no desborda).

---

# 03 — Entrada, salida y la plantilla en C++, Java y Python

**03 → 1.** ¿Qué diferencia hay entre el formato de completar una firma y el de escribir el programa entero? 🟢

⏱️ **30 segundos.** En la firma, la plataforma lee la entrada y llama a tu función, que **devuelve** el resultado. En el programa entero, tú lees de `stdin` y **imprimes**.

🗣️ **2 minutos.** LeetCode, Codility y el HackerRank moderno usan firmas: una clase `Solution` o una función `solution(A)`. Codeforces, CSES, AtCoder y el HackerRank clásico piden el programa entero. La consecuencia práctica: en la firma la E/S no es tuya y no puede darte TLE; en el programa sí, y por eso existe la plantilla.

🔬 **El detalle.** En algunas plataformas de firma la salida estándar también se mira: un `println` de depuración olvidado puede dar WA. Lo seguro es depurar por la salida de error, que el juez no compara (`01/05`).

**03 → 2.** ¿Qué hacen `std::ios::sync_with_stdio(false)` y `std::cin.tie(nullptr)`? 🟢

⏱️ **30 segundos.** La primera desacopla `iostream` de `stdio`, para que `cin` y `cout` usen su propio búfer; la segunda evita que cada lectura de `cin` vacíe `cout` antes.

🗣️ **2 minutos.** Por defecto C++ mantiene `cin`/`cout` sincronizados con `scanf`/`printf` para que puedan mezclarse, y eso los deja sin búfer propio. Y `cin` está atado a `cout` para que una pregunta se vea antes de leer la respuesta. En un juez no hace falta ninguna de las dos cosas, y apagarlas hace la E/S varias veces más rápida.

🔬 **El detalle.** El precio de la primera es no mezclar ya `cin` con `scanf` ni `cout` con `printf`. El de la segunda aparece solo en problemas interactivos (`20/03`), donde tienes que vaciar la salida a mano antes de leer la respuesta del juez.

**03 → 3.** ¿Qué hace `std::endl` además de escribir un salto de línea? 🟡

⏱️ **30 segundos.** Vacía el búfer de salida. Un `endl` por línea es una escritura al sistema operativo por línea.

🗣️ **2 minutos.** `'\n'` añade el salto al búfer, que se vacía cuando se llena o al terminar el programa. `std::endl` añade el salto y llama a `flush`. Con un millón de líneas, la diferencia es un millón de llamadas al sistema frente a unas pocas.

🔬 **El detalle.** Hay un caso donde el vaciado sí se quiere: los problemas interactivos, donde el juez no ve tu pregunta hasta que vacías. Ahí se usa `std::endl` o `std::cout.flush()` de forma deliberada, no por costumbre.

**03 → 4.** ¿Por qué `Scanner` es lento, y qué pareja de clases lo sustituye para leer? 🟡

⏱️ **30 segundos.** Porque reconoce cada *token* con expresiones regulares y trabaja con un búfer pequeño. Se sustituye por `BufferedReader` para leer líneas y `StringTokenizer` para partirlas.

🗣️ **2 minutos.** `Scanner` está diseñado para ser flexible: acepta formatos de número localizados, delimitadores configurables y validación. Esa flexibilidad se paga en cada `nextInt()`. `BufferedReader` lee bloques grandes, `StringTokenizer` parte por espacios sin regex e `Integer.parseInt` convierte; juntos van varias veces más rápido.

🔬 **El detalle.** Para escribir, la pareja es `PrintWriter` sobre `BufferedWriter` con un solo `flush` al final. Y si necesitas aún más velocidad, `StreamTokenizer` o un lector de *bytes* a mano, con la advertencia de que `StreamTokenizer` lee los números como `double`.

**03 → 5.** ¿Qué diferencia hay entre `sys.stdin.readline` y `sys.stdin.buffer.read().split()`, y cuándo usas cada una? 🟡

⏱️ **30 segundos.** `readline` lee una línea, con su `'\n'`; `read().split()` lee toda la entrada y la parte por blancos en una llamada. La primera para líneas con estructura; la segunda para listas de números.

🗣️ **2 minutos.** `sys.stdin.buffer.read().split()` es lo más rápido porque hace todo el trabajo en C y una sola vez, pero pierde dónde acaba cada línea: si un nombre tiene espacios, queda partido. `readline` conserva la línea, y por eso es la opción cuando la línea importa.

🔬 **El detalle.** `read().split()` sobre `buffer` devuelve *bytes*: `int()` los acepta, pero si necesitas texto hay que decodificar. Y `readline` devuelve `''` al final de la entrada, que es como se detecta el fin línea a línea.

**03 → 6.** Compara las tres plantillas: ¿qué línea de cada lenguaje, si se olvida, convierte la plantilla en lenta o en incorrecta? 🟠

⏱️ **30 segundos.** En C++, las dos líneas de desacoplar, o poner `endl`; en Java, el `flush` final; en Python, escribir dentro del bucle con `print` en vez de una sola vez.

🗣️ **2 minutos.** Sin las dos líneas, el C++ es varias veces más lento en E/S; con `endl` en el bucle, igual. En Java, olvidar `flush` no lo hace lento sino **incorrecto**: la salida se queda en el búfer y el juez ve nada. En Python, `print` en un bucle de un millón y lectura con `input()` lo hacen lento; leer fuera de una función, algo más lento.

🔬 **El detalle.** La asimetría importa: el olvido en C++ y en Python da TLE en los casos grandes y pasa los pequeños; el de Java da WA en **todos**, incluido el ejemplo, lo que paradójicamente lo hace más fácil de detectar si pruebas el programa tal cual se envía.

**03 → 7.** Después de `sync_with_stdio(false)` usas `printf` para una línea y `cout` para el resto. ¿Qué puede pasar, y por qué? 🟠

⏱️ **30 segundos.** La salida puede salir desordenada: `printf` y `cout` ya tienen búferes distintos, y cada uno se vacía cuando quiere.

🗣️ **2 minutos.** Con la sincronización activa, los dos escriben al mismo flujo de C sin búfer intermedio, y el orden se respeta. Al desactivarla, `cout` acumula en su búfer y `printf` en el de `stdio`; si el de `printf` se vacía antes, su línea aparece antes de líneas de `cout` que se escribieron primero. El juez ve el orden equivocado: WA.

🔬 **El detalle.** No siempre se manifiesta: con salidas pequeñas los dos búferes se vacían al terminar el programa en un orden fijo y puede salir bien por casualidad. Es el tipo de error que pasa el ejemplo y falla en el caso grande. La regla es elegir una familia y no mezclar.

**03 → 8.** ¿Por qué `StreamTokenizer` es peligroso para leer valores de hasta `10¹⁸`, y qué usarías en su lugar? 🟠

⏱️ **30 segundos.** Porque guarda el número en un `double`, que solo representa enteros exactos hasta `2⁵³ ≈ 9·10¹⁵`. Para valores de hasta `10¹⁸` uso `BufferedReader` con `StringTokenizer` y `Long.parseLong`.

🗣️ **2 minutos.** `StreamTokenizer` parsea números en su campo `nval`, que es `double`. Un `long` de 18 dígitos se redondea al `double` más cercano y pierde las últimas cifras sin avisar. El resultado es un WA en los casos con valores grandes, que suelen ser los últimos.

🔬 **El detalle.** Se puede usar `StreamTokenizer` en modo palabra y convertir con `Long.parseLong` el `sval`, pero entonces se pierde parte de la ventaja. Lo más simple es la pareja de la plantilla.

**03 → 9.** ¿Qué cuestan `<bits/stdc++.h>` y `using namespace std`, y por qué el corpus no los usa en sus plantillas? 🟠

⏱️ **30 segundos.** `<bits/stdc++.h>` alarga la compilación, no es estándar y no existe con la libc++ de Clang; `using namespace std` trae miles de nombres al espacio global y choca con los tuyos. El corpus prefiere que el código compile en cualquier sitio y diga de dónde sale cada cosa.

🗣️ **2 minutos.** En un concurso, ahorran teclear: una cabecera y ningún `std::`. Pero `bits/stdc++.h` es un archivo interno de GCC que incluye toda la librería; en macOS con el compilador de Apple no compila. Y `using namespace std` hace que una variable tuya llamada `count`, `next` o `distance` choque o, peor, que una llamada resuelva a la función de `std` que no querías.

🔬 **El detalle.** Las plantillas del corpus se copian al cuaderno del bloque `23` y se reutilizan en contextos que no son un juez; por eso van con cabeceras explícitas y `std::`. Si las usas en un concurso, es una decisión consciente, no una costumbre.

**03 → 10.** Un programa Java da WA en todos los casos, incluido el primero, y en tu máquina imprime bien. Da la causa más probable y cómo confirmarla. 🔴

⏱️ **30 segundos.** Un `PrintWriter` sin `flush` al final: la salida se queda en el búfer y el juez ve una salida vacía. Lo confirmo corriendo exactamente el código enviado y redirigiendo la salida a un archivo.

🗣️ **2 minutos.** WA en el caso 1, el ejemplo que en tu máquina pasa, apunta a algo que no depende de los datos sino del entorno. Si en local ejecutaste otra versión o el IDE vació el búfer al cerrar, no lo viste. Se confirma con el archivo enviado, sin IDE, con `java Main < ejemplo.txt > salida.txt`.

🔬 **El detalle.** Otras causas con el mismo síntoma: un mensaje de depuración impreso en la salida estándar (`System.out` en vez de `System.err`), un formato distinto (un espacio de más que sí cambia los *tokens*) o leer de un archivo en vez de `stdin`. Todas se ven con la misma prueba.

**03 → 11.** La entrada no dice cuántos valores vienen: hay que leer hasta el final. Escribe cómo detectas el final en cada uno de los tres lenguajes con la plantilla del capítulo. 🔴

⏱️ **30 segundos.** En C++, `while (std::cin >> x)` termina cuando falla la lectura; en Java, el `next()` del lector devuelve `null`; en Python, la lista de `read().split()` se acaba.

🗣️ **2 minutos.** En C++ el operador `>>` devuelve el flujo, que en una condición vale falso tras un fallo o el fin de archivo. En Java, `BufferedReader.readLine()` devuelve `null` al final, y el lector de la plantilla lo propaga. En Python, con todo leído de golpe, el número de valores es el largo de la lista; línea a línea, `readline()` devuelve la cadena vacía.

🔬 **El detalle.** El error típico es leer hasta el final con un formato que asume un `n`: si el enunciado no da `n`, cualquier bucle de `n` vueltas es incorrecto. Y en C++, comprobar `cin.eof()` antes de leer es un error clásico: la bandera solo se pone después de intentar leer y fallar.

**03 → 12.** Un problema tiene `t ≤ 10⁴` casos y tu solución pasa el ejemplo, que tiene un solo caso, y da WA. Propón dos causas relacionadas con la plantilla y cómo las descartas. 🔴

⏱️ **30 segundos.** Que el estado de un caso no se reinicia en el siguiente, o que la lectura se desfasa porque un caso no consume toda su parte de la entrada. Las dos se descartan con un ejemplo propio de dos o tres casos.

🗣️ **2 minutos.** Un acumulador, un contador o una estructura declarados fuera del bucle de casos arrastran datos del caso anterior. Y si en un caso sales temprano («si `n = 1`, responde ya») sin leer el resto de sus datos, el siguiente caso empieza a leer en mitad del anterior. El ejemplo con un solo caso no detecta ninguna de las dos.

🔬 **El detalle.** La regla de la plantilla es declarar el estado dentro del bucle de casos y leer **todos** los datos del caso antes de decidir nada. Si la estructura es grande y se reutiliza por velocidad, se limpia solo la parte usada, porque limpiarla entera en cada caso puede dar TLE (`01/02`).

**03 → Problema: Eco al revés.**

- **Pista 2 — patrón:** **E/S rápida**: el trabajo es invertir una lista, y el coste está en leer y escribir un millón de valores.
- **Pista 3 — diseño:** lee todo con la plantilla en un arreglo de 64 bits y construye la salida en un búfer (o en una lista unida con saltos de línea) que se escribe una sola vez.

**03 → Problema: Nombres con espacios.**

- **Pista 2 — patrón:** **lectura por líneas** mezclada con lectura de un número; el riesgo es el salto de línea que queda tras leer `n`.
- **Pista 3 — diseño:** lee `n` como **línea completa** y conviértela, o consume el resto de esa línea antes de empezar; después, para cada línea, cuenta los *tokens* separados por blancos (partir por «uno o más espacios», no por un espacio exacto).

**03 → Problema: Hasta el final.**

- **Pista 2 — patrón:** **leer hasta el fin de la entrada** con un estado de máximo y su primera posición.
- **Pista 3 — diseño:** lee de dos en dos hasta que la lectura falle; actualiza el máximo solo cuando el valor sea **estrictamente** mayor, así se conserva el primer momento; los momentos van en 64 bits.

**03 → Problema: Java Stdin and Stdout I.**

- **Pista 2 — patrón:** E/S básica en Java; aquí `Scanner` basta, pero practica la pareja rápida.
- **Pista 3 — diseño:** lee los tres enteros y escríbelos uno por línea; repítelo con `BufferedReader` y `PrintWriter` con su `flush`.

**03 → Problema: Java End-of-file.**

- **Pista 2 — patrón:** **leer hasta el final** sin saber cuántas líneas hay.
- **Pista 3 — diseño:** un bucle que lee línea a línea hasta que `readLine()` devuelva `null`, con un contador que numera cada línea en la salida.

**03 → Problema: Input and Output.**

- **Pista 2 — patrón:** E/S básica en C++.
- **Pista 3 — diseño:** lee los tres enteros con `std::cin` y escribe su suma; añade las dos líneas de desacoplar para practicarlas.

**03 → Problema: Print Function.**

- **Pista 2 — patrón:** construir una salida en Python sin un `print` por pieza.
- **Pista 3 — diseño:** genera los números del 1 al `n` como cadenas y únelos sin separador en una sola escritura.

**03 → Problema: OddOccurrencesInArray.**

- **Pista 2 — patrón:** **formato de firma** con un truco de bits: cada valor que aparece un número par de veces se cancela.
- **Pista 3 — diseño:** el XOR de todos los elementos deja solo el valor sin pareja, porque `x ⊕ x = 0` y el XOR es conmutativo y asociativo.

**03 → Problema: Concatenation of Array.**

- **Pista 2 — patrón:** formato de firma que **devuelve** un arreglo nuevo.
- **Pista 3 — diseño:** reserva un arreglo de `2n` y escribe `nums[i]` en las posiciones `i` e `i + n`.

**03 → Problema: Distinct Numbers.**

- **Pista 2 — patrón:** **ordenación** o **conjunto**, con E/S rápida porque la entrada es grande.
- **Pista 3 — diseño:** ordena y cuenta las posiciones donde el valor cambia respecto del anterior; con la E/S de la plantilla.

**03 → Problema: Enormous Input Test.**

- **Pista 2 — patrón:** **E/S rápida pura**; el algoritmo es un contador de divisibilidad.
- **Pista 3 — diseño:** lee con la forma más rápida de tu lenguaje (las dos líneas de C++, la pareja de Java, `read().split()` en Python) y cuenta los `tᵢ` divisibles por `k`.

**03 → Problema: Repetitions.**

- **Pista 2 — patrón:** un **recorrido** con racha actual y racha máxima, sobre una cadena larga.
- **Pista 3 — diseño:** lee la cadena completa de una vez; recorre comparando cada carácter con el anterior: si coincide, la racha crece; si no, vuelve a 1; guarda el máximo.

**03 → Problema: Way Too Long Words.**

- **Pista 2 — patrón:** procesamiento de **cadenas por línea**.
- **Pista 3 — diseño:** si la palabra tiene más de 10 letras, escribe la primera, el número de letras intermedias y la última; si no, la palabra tal cual.

---

# 04 — Tipos, desbordamiento y el primer contacto con el módulo

**04 → 1.** ¿Cuál es el máximo de un `int` de 32 bits con signo y el de un entero de 64 bits con signo, en órdenes de magnitud? 🟢

⏱️ **30 segundos.** El de 32 bits, unos `2,1·10⁹` (`2³¹ − 1`); el de 64 bits, unos `9,2·10¹⁸` (`2⁶³ − 1`).

🗣️ **2 minutos.** Con esos dos números se decide todo: una suma de `n` valores cabe en `int` si `n · V` no pasa de `2·10⁹`, y en 64 bits si no pasa de `9·10¹⁸`. El producto de dos valores de `10⁹` es `10¹⁸`: cabe en 64 bits, justo.

🔬 **El detalle.** Los valores exactos son `2 147 483 647` y `9 223 372 036 854 775 807`. El mínimo con signo es uno más en magnitud (`−2³¹`), y esa asimetría es la que hace que `−Integer.MIN_VALUE` no quepa.

**04 → 2.** ¿Qué pasa en Java, en C++ y en Python cuando un entero con signo se desborda? 🟢

⏱️ **30 segundos.** En Java da la vuelta en silencio, en complemento a dos; en C++ es comportamiento indefinido; en Python no pasa, porque los enteros crecen sin límite.

🗣️ **2 minutos.** Java define el resultado: `Integer.MAX_VALUE + 1` es `Integer.MIN_VALUE`, determinista y equivocado. C++ no lo define para enteros con signo, y el compilador optimiza asumiendo que no ocurre, así que el comportamiento puede cambiar con `-O2`. Python paga en tiempo: operar con números enormes no es `O(1)`.

🔬 **El detalle.** En C++ los enteros **sin** signo sí tienen el desbordamiento definido (dan la vuelta módulo `2ᵏ`), y por eso los *hashes* y algunos trucos de bits usan `unsigned`. En Java, `Math.addExact` y `Math.multiplyExact` convierten el desbordamiento en una excepción, útil para depurar.

**04 → 3.** ¿Por qué tantos enunciados piden la respuesta módulo `10⁹ + 7`? Da las tres razones. 🟢

⏱️ **30 segundos.** Porque es primo, porque cabe en un `int` con margen para sumar dos restos, y porque el producto de dos restos cabe en 64 bits.

🗣️ **2 minutos.** Ser primo garantiza que todo número no múltiplo de `m` tiene inverso modular, y eso permite dividir ([`17/03`](../17-matematica/03-aritmetica-modular.md)). Ser menor que `2³⁰` deja sumar dos restos sin pasar de `2³¹ − 1`. Y `(10⁹ + 7)² ≈ 10¹⁸ < 9,2·10¹⁸` deja multiplicar dos restos en 64 bits con signo y reducir después.

🔬 **El detalle.** No es el único: `998 244 353` también es primo y es el de la transformada de Fourier sobre enteros ([`17/09`](../17-matematica/09-fft-y-ntt.md)), porque `998 244 352 = 119 · 2²³` tiene un factor potencia de dos grande. El módulo lo elige el autor para que la aritmética sea cómoda, no por la respuesta.

**04 → 4.** ¿Cuánto vale `-7 % 3` en C++, en Java y en Python, y por qué no coinciden? 🟢

⏱️ **30 segundos.** `-1` en C++ y en Java, `2` en Python. C++ y Java truncan la división hacia cero y el resto toma el signo del dividendo; Python redondea hacia abajo y el resto toma el signo del divisor.

🗣️ **2 minutos.** Las dos convenciones cumplen `a = (a / b) · b + a % b`, pero con divisiones distintas: en C++ y Java `-7 / 3` es `-2` y el resto `-1`; en Python `-7 // 3` es `-3` y el resto `2`. Para trabajar con módulos en C++ y Java hay que normalizar: `((a % m) + m) % m`.

🔬 **El detalle.** Java tiene `Math.floorMod` y `Math.floorDiv`, que dan los resultados de Python. Traducir código de Python a C++ o Java sin cuidar esto es una fuente clásica de WA con datos negativos.

**04 → 5.** ¿Qué diferencia hay entre `(long) a * b` y `(long) (a * b)` cuando `a` y `b` son `int`? 🟡

⏱️ **30 segundos.** En `(long) a * b` se convierte `a` antes de multiplicar, y la multiplicación se hace en 64 bits. En `(long) (a * b)` se multiplica en 32 bits, desborda, y se convierte el resultado ya roto.

🗣️ **2 minutos.** El tipo de una expresión lo deciden sus operandos, no la variable donde se guarda. El *cast* tiene mayor precedencia que la multiplicación, así que `(long) a * b` es `((long) a) * b`, y `b` se promociona a `long`. Con los paréntesis alrededor del producto, el *cast* llega tarde.

🔬 **El detalle.** El mismo error aparece con literales: `1 << 40` es un desplazamiento de `int`. En Java da `256`, porque solo usa los 5 bits bajos de la cuenta; en C++ es comportamiento indefinido. Se escribe `1L << 40` o `1LL << 40`.

**04 → 6.** ¿Por qué la suma, la resta y el producto respetan el módulo y la división no? 🟡

⏱️ **30 segundos.** Porque si `a ≡ a'` y `b ≡ b'`, sus sumas, restas y productos son congruentes; la división no tiene esa propiedad, y dividir exige el inverso modular.

🗣️ **2 minutos.** Escribe `a = a' + k·m` y `b = b' + l·m`. Entonces `a + b = a' + b' + (k + l)·m`, y lo mismo para la resta y el producto (los términos con `m` se van). Para la división no hay nada parecido: `6 / 2 = 3`, pero módulo 4, `6 ≡ 2` y `2 / 2 = 1`, que no es `3`.

🔬 **El detalle.** Lo que sí funciona es multiplicar por el inverso: `a / b ≡ a · b⁻¹ (mod m)` cuando `b` tiene inverso, que con `m` primo es siempre que `b` no sea múltiplo de `m`. El inverso se calcula con el pequeño teorema de Fermat o con Euclides extendido, en `17/03`.

**04 → 7.** ¿Qué diferencia hay entre una tolerancia absoluta y una relativa, y cuándo falla cada una? 🟡

⏱️ **30 segundos.** La absoluta acepta si `|a − b| ≤ ε`; la relativa, si `|a − b| ≤ ε · |b|`. La absoluta falla con valores grandes y la relativa falla cerca de cero.

🗣️ **2 minutos.** Con valores de `10¹²`, un `double` no tiene precisión de `10⁻⁹` absoluta: dos números que son el mismo resultado con distinto redondeo se rechazan. Con valores cerca de cero, la relativa exige un error proporcional a algo diminuto, o infinito si el valor esperado es cero. La combinación `ε · max(1, |a|, |b|)` es absoluta cerca de cero y relativa lejos.

🔬 **El detalle.** El `ε` se elige por la magnitud y por la cantidad de operaciones: tras millones de sumas, el error acumulado puede pasar de `10⁻⁹`. Y comparar con tolerancia no es transitivo: `a ≈ b` y `b ≈ c` no implican `a ≈ c`, lo que rompe ordenar con un comparador con épsilon.

**04 → 8.** ¿Por qué `(long) Math.sqrt(x)` puede fallar con `x` cerca de `10¹⁸`, y cómo lo corriges? 🟠

⏱️ **30 segundos.** Porque un `double` tiene 53 bits de mantisa y no distingue enteros consecutivos por encima de `2⁵³`: la raíz puede salir uno arriba o uno abajo. Se corrige ajustando con dos `while` que comprueban `r²` en enteros.

🗣️ **2 minutos.** Con `x` cerca de `10¹⁸`, convertir `x` a `double` ya redondea, y la raíz del valor redondeado puede quedar en `r + 1` cuando la exacta es `r`. Los dos bucles bajan mientras `r² > x` y suben mientras `(r + 1)² ≤ x`, y para `x ≤ 10¹⁸` se mueven como mucho una vez.

🔬 **El detalle.** En Python, `math.isqrt` es exacta y existe desde 3.8. En C++ algunos usan `sqrtl` con `long double`, que en x86 tiene 64 bits de mantisa y suele bastar, pero no en todas las plataformas: el ajuste en enteros es lo portable.

**04 → 9.** Un enunciado pide el número de formas módulo `10⁹ + 7`, y además cuál de dos estrategias da más formas. ¿Por qué el módulo no te sirve para lo segundo? 🟠

⏱️ **30 segundos.** Porque el módulo no conserva el orden: dos números enormes pueden tener restos en cualquier orden. Comparar restos no dice cuál es mayor.

🗣️ **2 minutos.** `10⁹ + 8` es mayor que `5`, pero su resto es `1`. Para comparar hay que trabajar con el valor real, con su logaritmo (sumando logaritmos en vez de multiplicar, con cuidado de la precisión) o con un argumento que no necesite los números: por ejemplo, que una estrategia domina a la otra término a término.

🔬 **El detalle.** Es una señal de diseño: si el enunciado pide «módulo» y «máximo» a la vez, la respuesta suele ser un argumento estructural (qué opción es mejor) seguido de un conteo modular de esa opción, no dos conteos comparados.

**04 → 10.** ¿Por qué en JavaScript `a * b % MOD` con `MOD = 10⁹ + 7` da resultados incorrectos, y qué alternativas hay? 🟠

⏱️ **30 segundos.** Porque en JavaScript todo número es un `double`, exacto solo hasta `2⁵³ ≈ 9·10¹⁵`, y el producto de dos restos llega a `10¹⁸`. Las salidas son `BigInt` o partir el producto.

🗣️ **2 minutos.** `a * b` se calcula en coma flotante y pierde las últimas cifras sin avisar; el `%` posterior opera sobre un valor ya redondeado. `BigInt` es exacto pero más lento. La alternativa sin `BigInt` es partir `b` en dos mitades de 15 bits, multiplicar cada mitad por `a` (cada producto queda bajo `2⁵³`) y recomponer reduciendo.

🔬 **El detalle.** Por eso el corpus trata JavaScript como caso de estudio ([`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)): el mismo algoritmo exige otra aritmética. Y la trampa es silenciosa: los ejemplos pequeños dan bien.

**04 → 11.** Tu código C++ tiene un bucle `for (int i = 1; i > 0; i *= 2)` que en tu máquina termina y en el juez no. Explica cómo es posible. 🟠

⏱️ **30 segundos.** El bucle depende de que `i` se desborde a negativo, y eso es comportamiento indefinido en C++. Con optimizaciones, el compilador puede suponer que `i > 0` es siempre cierto y quitar la condición.

🗣️ **2 minutos.** Si `i` empieza en 1 y solo se multiplica por 2, sin desbordamiento nunca sería negativo; como el desbordamiento con signo «no ocurre» según el estándar, el optimizador concluye que la condición nunca falla y el bucle se vuelve infinito. En tu máquina, compilado sin `-O2`, `i` da la vuelta a negativo y el bucle termina. En el juez, con `-O2`, no.

🔬 **El detalle.** La solución es no depender del desbordamiento: escribir la condición sobre algo que no desborde (`i <= límite / 2` antes de duplicar) o usar `unsigned`, cuyo desbordamiento sí está definido. GCC avisa de algunos de estos casos con `-Wall -Wextra`, y `-fsanitize=undefined` los detecta al ejecutar.

**04 → 12.** Escribe la condición exacta para comparar dos fracciones `a/b` y `c/d` sin divisiones, con `b` y `d` posiblemente negativos, y di qué cota necesitan los valores para que no desborde en 64 bits. 🔴

⏱️ **30 segundos.** Normalizo los denominadores a positivos (cambiando de signo numerador y denominador si hace falta) y comparo `a·d` con `c·b`. Para que no desborde en 64 bits, los valores tienen que cumplir `|a|·|d|` y `|c|·|b|` menores que `9·10¹⁸`: con todos por debajo de `3·10⁹` basta.

🗣️ **2 minutos.** `a/b < c/d` equivale a `a·d < c·b` **solo si `b·d > 0`**: multiplicar una desigualdad por un número negativo la invierte. Por eso primero se fuerza `b > 0` y `d > 0`. Con eso, la comparación es exacta en enteros. La cota sale de que cada producto tiene que caber: `|a|, |b|, |c|, |d| ≤ 3·10⁹` da productos de `9·10¹⁸`, en el borde.

🔬 **El detalle.** Con valores de hasta `10⁹`, los productos son `10¹⁸` y caben con holgura. Si pasan de eso, `__int128` en C++, `Math.multiplyHigh` o `BigInteger` en Java, o Python directamente. Es la versión entera que §5 recomienda frente a dividir en `double`.

**04 → 13.** Un envío calcula `n(n−1)/2` con `n = 10⁵` en `int` y da WA solo en los casos grandes. Haz la autopsia: el valor que debería dar, el que da en Java y la línea que cambia. 🔴

⏱️ **30 segundos.** Debería dar `4 999 950 000`; en Java, con `int`, el producto `n · (n − 1) = 9 999 900 000` da la vuelta a `1 409 965 408`, y al dividir por 2 sale `704 982 704`. La línea que cambia es el tipo: `(long) n * (n - 1) / 2`.

🗣️ **2 minutos.** El fallo solo aparece cuando `n(n−1)` pasa de `2³¹ − 1`, es decir, con `n` a partir de unos 46 341; los casos pequeños pasan. `9 999 900 000 − 2 · 2³² = 1 409 965 408`, que es positivo, y por eso el error ni siquiera se nota como un negativo raro.

🔬 **El detalle.** Es la generalización de la autopsia de §3: un error de tipo, no de algoritmo. Y es especialmente traicionero aquí porque el resultado erróneo es un número plausible. La prevención es la cuenta de máximos al leer el enunciado.

**04 → 14.** Demuestra que `(a · b) mod m = ((a mod m) · (b mod m)) mod m` para enteros no negativos. 🔴

⏱️ **30 segundos.** Escribo `a = q₁m + r₁` y `b = q₂m + r₂`, con `r₁ = a mod m` y `r₂ = b mod m`. Al multiplicar, todos los términos salvo `r₁r₂` son múltiplos de `m`, así que `ab` y `r₁r₂` tienen el mismo resto.

🗣️ **2 minutos.** `ab = q₁q₂m² + q₁r₂m + q₂r₁m + r₁r₂ = m·(q₁q₂m + q₁r₂ + q₂r₁) + r₁r₂`. Dos números que difieren en un múltiplo de `m` tienen el mismo resto al dividir por `m`. Por tanto `ab mod m = (r₁r₂) mod m`, que es lo que se quería.

🔬 **El detalle.** La prueba no usa que `m` sea primo: vale para cualquier `m ≥ 1`. Lo que sí usa la implementación es que `r₁r₂ < m²` quepa en el tipo, y por eso con `m = 10⁹ + 7` se multiplica en 64 bits. Con números negativos vale igual en la congruencia, pero el `%` de C++ y Java puede devolver un representante negativo.

**04 → Problema: Promedio hacia abajo.**

- **Pista 2 — patrón:** **tipos y división entera con signo**: la suma necesita 64 bits y la división del lenguaje puede redondear hacia cero, no hacia abajo.
- **Pista 3 — diseño:** suma en 64 bits; si la suma es negativa y no es múltiplo de `n`, la división truncada queda una unidad por encima del suelo, así que hay que restar 1 (o usar `Math.floorDiv` en Java, `//` en Python).

**04 → Problema: Producto con signo, módulo 10⁹+7.**

- **Pista 2 — patrón:** **aritmética modular** con normalización de negativos.
- **Pista 3 — diseño:** lleva el acumulador en `[0, MOD)`; antes de multiplicar, lleva cada valor a `[0, MOD)` con `((a % MOD) + MOD) % MOD`; multiplica en 64 bits y reduce.

**04 → Problema: ¿Cuadrado perfecto?.**

- **Pista 2 — patrón:** **raíz entera exacta**: la raíz del `double` corregida en enteros.
- **Pista 3 — diseño:** calcula `r` como la parte entera de la raíz del `double`, ajústala con dos bucles hasta que `r² ≤ x < (r + 1)²`, y responde según `r² = x`; todo en 64 bits (`r` no pasa de `10⁹ + 1`).

**04 → Problema: A Very Big Sum.**

- **Pista 2 — patrón:** **tipo del acumulador**: los valores caben en 32 bits, la suma no.
- **Pista 3 — diseño:** acumulador de 64 bits declarado así desde el principio, y el tipo de retorno de la función también de 64 bits.

**04 → Problema: Mini-Max Sum.**

- **Pista 2 — patrón:** tipo del acumulador y una observación: la suma de cuatro es la total menos uno.
- **Pista 3 — diseño:** suma los cinco en 64 bits; la mínima suma de cuatro es el total menos el máximo, y la máxima es el total menos el mínimo.

**04 → Problema: Java Datatypes.**

- **Pista 2 — patrón:** **rangos de los tipos** primitivos.
- **Pista 3 — diseño:** intenta leer el número como `long`; si falla, no cabe en ninguno; si cabe, compáralo con los mínimos y máximos de `byte`, `short`, `int` y `long` en ese orden.

**04 → Problema: Plus Minus.**

- **Pista 2 — patrón:** **reales e impresión con precisión fija**.
- **Pista 3 — diseño:** cuenta positivos, negativos y ceros en enteros; divide en `double` solo al final e imprime con 6 decimales, que es lo que el enunciado pide.

**04 → Problema: Reverse Integer.**

- **Pista 2 — patrón:** **detección de desbordamiento antes de que ocurra**, porque el enunciado prohíbe usar 64 bits.
- **Pista 3 — diseño:** antes de hacer `res = res · 10 + d`, comprueba si `res > (MAX − d) / 10` (y lo simétrico para negativos); si se pasaría, devuelve 0.

**04 → Problema: Sqrt(x).**

- **Pista 2 — patrón:** **búsqueda binaria sobre la respuesta** ([`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md)) con el cuadrado en 64 bits.
- **Pista 3 — diseño:** busca el mayor `r` con `r² ≤ x` en `[0, x]`; compara `r · r` en 64 bits, o compara `r` con `x / r` para no multiplicar.

**04 → Problema: Pow(x, n).**

- **Pista 2 — patrón:** **exponenciación rápida** con un borde de tipo: `n` puede ser `−2³¹`.
- **Pista 3 — diseño:** pasa `n` a 64 bits antes de negarlo; si es negativo, invierte `x` y usa `−n`; eleva por cuadrados sucesivos, multiplicando el resultado cuando el bit actual de `n` vale 1.

**04 → Problema: PermMissingElem.**

- **Pista 2 — patrón:** **suma conocida** con tipo de 64 bits.
- **Pista 3 — diseño:** la suma de `1` a `N + 1` es `(N + 1)(N + 2)/2`, calculada en 64 bits; resta la suma del arreglo. O haz el XOR de todos los índices y valores, que no desborda.

**04 → Problema: Bit Strings.**

- **Pista 2 — patrón:** **aritmética modular**: `2ⁿ` reduciendo en cada paso.
- **Pista 3 — diseño:** multiplica por 2 `n` veces módulo `10⁹ + 7`; con `n ≤ 10⁶` el bucle lineal sobra.

**04 → Problema: Increasing Array.**

- **Pista 2 — patrón:** recorrido voraz con un **acumulador de 64 bits**.
- **Pista 3 — diseño:** recorre manteniendo el máximo hasta ahora; si el actual es menor, suma la diferencia al total y súbelo; el total puede llegar a unos `2·10¹⁴`.

**04 → Problema: Theatre Square.**

- **Pista 2 — patrón:** **división hacia arriba** y producto en 64 bits.
- **Pista 3 — diseño:** las losas por lado son `⌈n / a⌉ = (n + a − 1) / a` y lo mismo con `m`; el producto llega a `10¹⁸`, así que va en 64 bits.

**04 → Problema: Count Good Numbers.**

- **Pista 2 — patrón:** **exponenciación modular rápida**: el exponente es enorme.
- **Pista 3 — diseño:** las posiciones pares tienen 5 opciones y las impares 4; la respuesta es `5^⌈n/2⌉ · 4^⌊n/2⌋` módulo `10⁹ + 7`, con cada potencia por cuadrados sucesivos en `O(log n)`.

**04 → Problema: PassingCars.**

- **Pista 2 — patrón:** **conteo con prefijos** y un tope de salida.
- **Pista 3 — diseño:** recorre de izquierda a derecha contando los coches hacia el este vistos; cada coche hacia el oeste suma ese contador; si el total pasa de `1 000 000 000`, devuelve `−1`. El total cabe en 32 bits solo porque cortas en el tope; sin el corte, no.

---

# 05 — Probar sin IDE: casos borde, depuración y *stress test*

**05 → 1.** ¿Qué casos borde de la lista fija probarías siempre, y cómo decides cuáles descartar? 🟢

⏱️ **30 segundos.** El elemento único, todos iguales, el máximo de las restricciones y la respuesta en la primera o la última posición; descarto los que las restricciones prohíben, como el vacío si `n ≥ 1`.

🗣️ **2 minutos.** La lista completa es vacío, uno, todos iguales, negativos o ceros, el máximo, la respuesta en un extremo, duplicados y la entrada ya ordenada o al revés. Se lee contra el enunciado: si los valores son positivos, los negativos sobran; si son distintos, los duplicados también. Lo que queda son tres o cuatro casos que se escriben en un archivo y se corren.

🔬 **El detalle.** El caso del máximo no se escribe a mano: se genera, y sirve para el tipo y el tiempo, no para comprobar la respuesta. Los bordes que más WA producen en la práctica son el tramo final que nunca se cierra y el máximo inicializado en `0`.

**05 → 2.** ¿Por qué la salida de error sirve para depurar en un juez sin romper la respuesta? 🟢

⏱️ **30 segundos.** Porque el juez solo compara la salida estándar; lo que se escribe en `stderr` no entra en la comparación.

🗣️ **2 minutos.** El proceso tiene dos flujos de salida. El juez captura la estándar y la compara con la esperada; la de error la ignora o la guarda aparte. Así puedes imprimir el estado interno sin cambiar la respuesta. En C++ es `std::cerr`, en Java `System.err` y en Python `sys.stderr`.

🔬 **El detalle.** Ignorarla no es lo mismo que no ejecutarla: el tiempo de escribir en `stderr` cuenta. Y en el formato de firma, algunas plataformas muestran `stderr` en la consola de depuración, lo que lo hace aún más útil allí.

**05 → 3.** ¿Qué tres piezas tiene un *stress test*, y qué papel cumple cada una? 🟢

⏱️ **30 segundos.** Un generador de entradas aleatorias con semilla, una fuerza bruta que hace de oráculo y un arnés que corre los dos y compara hasta encontrar una diferencia.

🗣️ **2 minutos.** El generador produce entradas pequeñas y reproducibles. La fuerza bruta es una solución lenta pero obviamente correcta, cuya respuesta se da por buena. El arnés repite: genera con la semilla `k`, corre tu solución y la fuerza bruta, compara por *tokens*, y si difieren imprime la entrada y las dos salidas y para.

🔬 **El detalle.** El arnés también detecta caídas si trata un código de salida distinto de cero como fallo, y puede añadir un límite de tiempo por ejecución para detectar bucles infinitos. Lo que no detecta es el TLE de los casos grandes.

**05 → 4.** ¿Por qué el generador recibe una semilla en vez de usar una aleatoria cada vez? 🟡

⏱️ **30 segundos.** Para poder reproducir el caso que falla: misma semilla, misma entrada.

🗣️ **2 minutos.** Si el generador usa una semilla distinta en cada ejecución, cuando el arnés encuentra una diferencia y tú corriges algo, no puedes volver a generar exactamente ese caso para comprobar la corrección. Con la semilla impresa, el caso se regenera cuando quieras.

🔬 **El detalle.** Además, recorrer las semillas en orden (`1, 2, 3…`) hace la prueba determinista: dos personas con el mismo generador ven los mismos casos. En C++, `std::mt19937` con la misma semilla da la misma secuencia en cualquier plataforma; `uniform_int_distribution`, en cambio, no está garantizado igual entre librerías distintas.

**05 → 5.** ¿Qué diferencia hay entre `assert` en C++, en Java y en Python en cuanto a cuándo se ejecuta? 🟡

⏱️ **30 segundos.** En C++, `assert` se ejecuta salvo que compiles con `-DNDEBUG`; en Java, solo se ejecuta con `java -ea`; en Python, se ejecuta salvo con `python -O`.

🗣️ **2 minutos.** La trampa está en Java: las aserciones vienen **desactivadas** por defecto, y una aserción que nunca se ejecuta no protege nada. En C++ y Python vienen activadas y se apagan con una opción. En los jueces, la configuración la elige la plataforma, así que en el envío no se debe contar con ellas.

🔬 **El detalle.** En C++ algunos jueces compilan con `-DNDEBUG` y otros no; un `assert` caro dentro de un bucle puede dar TLE donde se ejecuta. Para depurar en local, encenderlas siempre; para el envío, no depender de ellas.

**05 → 6.** ¿Qué hace `-fsanitize=address,undefined` y por qué no se usa en el envío? 🟡

⏱️ **30 segundos.** Instrumenta el programa para que se detenga con un mensaje en un acceso de memoria inválido o en un comportamiento indefinido, como un desbordamiento con signo. No se usa en el envío porque hace el programa varias veces más lento y el juez no lo activa.

🗣️ **2 minutos.** `address` detecta lecturas y escrituras fuera de los límites de un arreglo, uso después de liberar y fugas; `undefined` detecta desbordamiento de enteros con signo, desplazamientos inválidos y divisiones por cero. Sin ellos, esos errores dan basura silenciosa o un RE sin explicación; con ellos, una línea y una causa.

🔬 **El detalle.** LeetCode compila C++ con AddressSanitizer activado, y por eso allí un acceso fuera de rango da un error explícito donde otro juez daría un WA aleatorio. Es la razón para usarlo en local: reproduces ese comportamiento antes de enviar.

**05 → 7.** ¿Por qué un *stress test* con entradas pequeñas encuentra bugs que aparecen en el caso 14 de un juez con `n = 10⁵`? 🟠

⏱️ **30 segundos.** Porque casi todos los bugs de lógica dependen de la forma de los datos, no del tamaño: un borde, un duplicado, un negativo. Esa forma aparece también en entradas pequeñas, y entre miles de casos aleatorios alguno la tiene.

🗣️ **2 minutos.** Un bug que solo aparece con `n = 10⁵` suele ser de tipo (desbordamiento) o de tiempo, no de lógica. Los de lógica —el último tramo, el máximo en cero, el índice que no llega al final— se manifiestan con tres o cuatro elementos. Y una entrada de tres elementos se traza a mano, cosa imposible con `10⁵`.

🔬 **El detalle.** La excepción son los bugs que necesitan una estructura grande: una colisión de *hash*, una recursión profunda, un desbordamiento. Para esos, el *stress test* se complementa con un caso máximo generado y con la revisión de tipos de `01/04`.

**05 → 8.** Tu *stress test* corre 10 000 casos sin diferencias y el juez sigue dando WA. Da tres explicaciones posibles. 🟠

⏱️ **30 segundos.** Que el generador no produce la forma que rompe (por ejemplo, nunca genera `n = 1` o valores grandes), que la fuerza bruta tiene el mismo bug, o que el fallo es de tipo o de formato y solo aparece con valores grandes.

🗣️ **2 minutos.** El generador define el espacio que exploras: si los valores van de `−5` a `5`, nunca verás un desbordamiento. Si la fuerza bruta comparte la lectura de la entrada o una función auxiliar con tu solución, comparten también sus bugs. Y si el problema tiene varios casos de prueba por entrada, un estado que no se reinicia solo aparece si el generador produce varios casos.

🔬 **El detalle.** El remedio es variar el generador: ampliar rangos, forzar los bordes de §2, generar varios casos por entrada, y escribir la fuerza bruta de forma independiente, sin copiar código de la solución. Si nada de eso encuentra la diferencia, el sospechoso pasa a ser el formato de salida.

**05 → 9.** ¿Por qué un `cerr` olvidado puede convertir un AC en TLE, si el juez no compara la salida de error? 🟠

⏱️ **30 segundos.** Porque el juez no compara `stderr`, pero sí ejecuta el programa entero: escribir un millón de líneas de depuración cuesta tiempo.

🗣️ **2 minutos.** `std::cerr` no tiene búfer: cada escritura es una llamada al sistema. Dentro de un bucle de `10⁶` vueltas son un millón de llamadas, más que suficiente para pasar el límite. El programa es correcto, la salida estándar es la buena, y el veredicto es TLE.

🔬 **El detalle.** Algunos jueces además limitan el tamaño de `stderr` o lo descartan de formas costosas. La práctica sana es quitar la depuración antes de enviar, o envolverla en una condición que en el envío sea falsa.

**05 → 10.** Compara `rand() % k` en C++, `random.randint(a, b)` en Python y `nextInt(k)` en Java: ¿qué rango da cada uno y qué trampa tiene? 🟠

⏱️ **30 segundos.** `rand() % k` da `[0, k)` con sesgo; `random.randint(a, b)` da `[a, b]` con los dos extremos; `nextInt(k)` da `[0, k)` uniforme. La trampa de C++ es el sesgo y el rango pequeño; la de Python, que incluye el extremo superior.

🗣️ **2 minutos.** `rand()` devuelve hasta `RAND_MAX`, que en algunas plataformas es `32 767`, y el módulo favorece los restos bajos cuando `k` no divide `RAND_MAX + 1`. `std::mt19937` con `uniform_int_distribution` no tiene ninguno de los dos problemas. En Python, `randint` incluye `b` mientras `range(a, b)` no, y mezclarlos da un *off-by-one* en el generador.

🔬 **El detalle.** En Java, `Random` con semilla es determinista y `nextInt(k)` es uniforme. Para un generador de *stress test* el sesgo pequeño no suele importar; para un algoritmo aleatorizado de verdad ([`19/01`](../19-aleatorizados-y-probabilisticos/01-las-vegas-y-monte-carlo.md)), sí.

**05 → 11.** El *stress test* encuentra una diferencia con `n = 7`. Describe el procedimiento para reducirla y por qué conviene hacerlo antes de mirar el código. 🔴

⏱️ **30 segundos.** Quito elementos uno a uno y me quedo con la versión más pequeña que siga fallando; después achico los valores. Así el caso que miro tiene dos o tres elementos y el bug se ve.

🗣️ **2 minutos.** El procedimiento: guarda la entrada que falla; prueba a quitar cada elemento y vuelve a comparar solución y fuerza bruta; si sigue fallando, quédate con la versión reducida y repite. Cuando ya no puedes quitar nada, prueba a cambiar cada valor por uno más pequeño o por cero. El resultado es un caso mínimo.

🔬 **El detalle.** Se hace antes de mirar el código porque un caso de siete elementos invita a adivinar, y uno de dos elementos dice exactamente qué línea falla. Las bibliotecas de pruebas basadas en propiedades automatizan esta reducción (*shrinking*); a mano, son tres o cuatro iteraciones.

**05 → 12.** Escribe, en palabras, el generador y la fuerza bruta para un problema de «el primer índice con valor mayor o igual que `x` en un arreglo ordenado», incluyendo qué rangos usarías y por qué. 🔴

⏱️ **30 segundos.** El generador crea `n` entre 1 y 8, valores ordenados entre −5 y 5 con duplicados, y consultas entre −7 y 7, fuera del rango por los dos lados. La fuerza bruta recorre el arreglo de izquierda a derecha y devuelve el primer índice con `a[i] ≥ x`, o `n`.

🗣️ **2 minutos.** El generador produce `n` valores al azar en un rango pequeño y los ordena, para que el arreglo cumpla la precondición y tenga repetidos; las consultas salen de un rango algo más ancho para incluir `x` menor que todos (respuesta `0`) y mayor que todos (respuesta `n`). La fuerza bruta es un recorrido lineal que no puede equivocarse con los bordes.

🔬 **El detalle.** Los rangos pequeños garantizan duplicados, que es donde «primer índice» se distingue de «algún índice»; las consultas fuera del rango cubren el borde que el bug de la búsqueda binaria con `hi = n − 1` no ve. Es justo el problema propio de este capítulo.

**05 → Problema: La racha más larga.**

- **Pista 2 — patrón:** **caso borde**: el tramo final nunca se compara, y con `n = 1` el resultado es `0`.
- **Pista 3 — diseño:** la comparación con `best` tiene que hacerse también al terminar el bucle (o en cada paso, no solo al cambiar), y `best` debe empezar en 1 porque `n ≥ 1`; la entrada mínima que rompe la versión dada es un solo elemento.

**05 → Problema: Primer índice mayor o igual.**

- **Pista 2 — patrón:** **búsqueda binaria** con el intervalo mal elegido: con `hi = n − 1` cerrado no puede devolver `n`.
- **Pista 3 — diseño:** usa el intervalo semiabierto `[0, n)` (`hi = n`), con el invariante «todo índice `< lo` tiene valor `< x` y todo índice `≥ hi` tiene valor `≥ x`»; al salir, `lo` es la respuesta. La entrada mínima que rompe la versión dada es `n = 1` con una consulta mayor que el único valor.

**05 → Problema: Duración de un turno.**

- **Pista 2 — patrón:** **caso borde** de igualdad: la condición `d ≤ 0` trata el turno de duración cero como si cruzara la medianoche.
- **Pista 3 — diseño:** la duración es `(e − s + 1440) mod 1440`, que da 0 cuando las horas coinciden y suma un día solo cuando `e < s`; la entrada mínima que rompe la versión dada es un turno con las dos horas iguales.

**05 → Problema: Search Insert Position.**

- **Pista 2 — patrón:** **búsqueda binaria** del primer índice con valor `≥ target` (`05/04`).
- **Pista 3 — diseño:** intervalo semiabierto `[0, n)`; si todos son menores, la respuesta es `n`, que tiene que poder devolverse.

**05 → Problema: Plus One.**

- **Pista 2 — patrón:** **acarreo** desde el final, con el borde de que el resultado crezca.
- **Pista 3 — diseño:** recorre desde el último dígito: si es menor que 9, súmale uno y devuelve; si es 9, ponlo en 0 y sigue; si sales del bucle, todos eran 9 y el resultado es un 1 seguido de ceros, con un dígito más.

**05 → Problema: Merge Sorted Array.**

- **Pista 2 — patrón:** **mezcla desde el final** para no pisar elementos.
- **Pista 3 — diseño:** tres índices: el final de la parte útil de `nums1`, el de `nums2` y la posición de escritura al final de `nums1`; coloca siempre el mayor; cuando `nums2` se agota, terminaste; si `m = 0`, solo se copia `nums2`.

**05 → Problema: Valid Palindrome.**

- **Pista 2 — patrón:** **dos punteros** desde los extremos, saltando lo que no es alfanumérico.
- **Pista 3 — diseño:** avanza el izquierdo y retrocede el derecho mientras apunten a caracteres no alfanuméricos; compara en minúsculas; una cadena sin alfanuméricos es palíndromo.

**05 → Problema: Time Conversion.**

- **Pista 2 — patrón:** **conversión con dos bordes**: las 12 AM son las 00 y las 12 PM son las 12.
- **Pista 3 — diseño:** separa horas y sufijo; con `AM`, 12 pasa a 0 y el resto igual; con `PM`, 12 se queda y el resto suma 12; formatea con dos dígitos.

**05 → Problema: MissingInteger.**

- **Pista 2 — patrón:** **arreglo de presencia** indexado por valor, ignorando lo que está fuera de `[1, N]`.
- **Pista 3 — diseño:** marca los valores entre 1 y `N`; la respuesta es el primer índice sin marcar, o `N + 1`; con todos negativos, la respuesta es 1.

**05 → Problema: PermCheck.**

- **Pista 2 — patrón:** **arreglo de presencia** con dos condiciones: rango y no repetidos.
- **Pista 3 — diseño:** si algún valor está fuera de `[1, N]` o ya estaba marcado, no es permutación; si se marcan los `N` sin problema, sí.

**05 → Problema: Permutations.**

- **Pista 2 — patrón:** **construcción** con bordes pequeños que no tienen solución.
- **Pista 3 — diseño:** con `n = 1` la respuesta es `1`; con `n = 2` y `n = 3` no hay solución; para `n ≥ 4`, escribe primero todos los pares y después todos los impares.

**05 → Problema: Two Knights.**

- **Pista 2 — patrón:** **fórmula combinatoria** comprobada contra una **fuerza bruta** en tableros pequeños.
- **Pista 3 — diseño:** las parejas de casillas son `C(k², 2)`; resta las que se atacan, que son dos por cada rectángulo de 2×3 o 3×2 del tablero: `4(k − 1)(k − 2)`; verifica la fórmula contra el conteo directo para `k ≤ 6`, y usa 64 bits.

**05 → Problema: Candies and Two Sisters.**

- **Pista 2 — patrón:** **fórmula** con bordes de valores pequeños.
- **Pista 3 — diseño:** la mayor tiene que recibir estrictamente más y la menor al menos uno; el número de formas es `⌊(n − 1) / 2⌋`, que vale 0 con `n = 1` y `n = 2`.

---

# 06 — El protocolo de resolución, la repetición y el concurso

**06 → 1.** ¿Qué preguntas tiene la ficha de antes de programar y cuáles la de después? 🟢

⏱️ **30 segundos.** Antes: entrada y salida, restricciones, complejidad máxima, casos borde, fuerza bruta, qué se repite e idea optimizada. Después: patrón, error, pista que hizo falta y variante.

🗣️ **2 minutos.** La ficha de antes recorre el camino de Pólya: comprender (entrada, salida, restricciones), concebir un plan (complejidad, fuerza bruta, qué se repite, idea) y prever los bordes. La de después es su cuarto paso, examinar la solución: nombrar el patrón y el error, y pensar una variante.

🔬 **El detalle.** La pregunta que más rinde es «qué se repite»: casi todas las técnicas del corpus existen para no repetir un trabajo que la fuerza bruta repite. Si esa fila tiene respuesta clara, la idea optimizada suele estar a un paso.

**06 → 2.** ¿En qué fases se reparten los 30 minutos de un problema, y qué produce cada una? 🟢

⏱️ **30 segundos.** Entender (0–5), estimar (5–8), diseñar (8–15), implementar (15–25) y probar (25–30).

🗣️ **2 minutos.** Entender produce el enunciado en tus palabras y los ejemplos hechos a mano; estimar, la complejidad máxima y los tipos; diseñar, la fuerza bruta, lo que se repite y la idea con su invariante; implementar, el código sobre la plantilla; probar, los bordes y, si hay duda, el *stress test*.

🔬 **El detalle.** La regla de transición importa más que los minutos: no se implementa sin una idea con invariante, y si a los 15 minutos no la hay, se implementa la fuerza bruta. Los números son para un problema medio; con uno difícil se estiran, pero el orden no cambia.

**06 → 3.** ¿Qué diferencia hay entre la pista 1, la 2 y la 3, y por qué no hay pista 4? 🟢

⏱️ **30 segundos.** La 1 es una pregunta que reorienta sin nombrar la técnica; la 2 dice qué técnica es y por qué; la 3 da el estado, la transición o el invariante, sin código. No hay pista 4 porque la solución la escribe el lector.

🗣️ **2 minutos.** La pista 1 está junto al problema, y las otras dos en el solucionario del bloque. Se piden con reloj: 20 minutos sin idea, la 1; 10 más, la 2; 10 más, la 3. Con la 3 el diseño está hecho, y convertirlo en código es justo la habilidad que la prueba evalúa.

🔬 **El detalle.** Ningún problema del corpus lleva solución publicada, ni propio ni externo. Lo único resuelto son los ejemplos trabajados de cada técnica. La razón es la del capítulo: una solución leída activa el reconocimiento, no la producción.

**06 → 4.** ¿Qué diferencia hay entre entender una solución leída y saber producirla? 🟡

⏱️ **30 segundos.** Entender una solución leída es reconocerla; producirla es recuperarla y construirla sin verla. Son memorias distintas, y la prueba evalúa la segunda.

🗣️ **2 minutos.** Al leer una solución todo encaja y parece obvio, y esa sensación de fluidez se confunde con dominio. Una semana después, ante un problema parecido, no hay nada que reconocer: hay que producir, y eso no se practicó. Escribir la solución tú, aunque sea después de la pista 3, sí entrena la producción.

🔬 **El detalle.** La investigación sobre aprendizaje lo llama efecto de recuperación (*testing effect*): recuperar algo de memoria lo fija más que releerlo. Por eso el corpus no publica soluciones y el lineamiento de la IA pide cerrar sin ella.

**06 → 5.** ¿Qué diferencia hay entre un concurso virtual y el *upsolving*, y dónde está el aprendizaje? 🟡

⏱️ **30 segundos.** El concurso virtual es participar en un concurso pasado con su tiempo y su marcador; el *upsolving* es resolver después los problemas que no salieron. El aprendizaje está en el *upsolving*.

🗣️ **2 minutos.** El virtual mide: velocidad, nervios, gestión del tiempo, en condiciones reales. El *upsolving* enseña: los problemas que no saliste a resolver son justo los que están en el borde de lo que sabes, y trabajarlos con pistas o con el editorial, escribiéndolos tú, es donde se aprende algo nuevo.

🔬 **El detalle.** Quien solo hace concursos y no *upsolving* repite lo que ya sabe más rápido, pero no sube el techo. El *rating* acompaña la tendencia, y perseguirlo como objetivo empuja a trucos de concurso que no sirven fuera.

**06 → 6.** ¿Por qué la ficha de después es la que hace que un problema se recuerde? 🟡

⏱️ **30 segundos.** Porque nombra el patrón y el error, y eso convierte un problema concreto en una regla reutilizable: la próxima vez reconoces la señal y evitas el error.

🗣️ **2 minutos.** Sin ficha, un problema resuelto queda como un recuerdo difuso de «uno parecido». Con ella, queda como «mínimo acumulado; me equivoqué en el orden de actualizar; necesité la pista 1; si fueran varias compras, cambia». Además, la ficha dice qué problemas repetir: los que necesitaron pista 2 o 3.

🔬 **El detalle.** La fila «variante» es la más útil para entrevistas: es la pregunta de seguimiento que te van a hacer («¿y si…?»), respondida antes de que llegue.

**06 → 7.** ¿Qué problemas entran en la repetición espaciada y cuáles no, y con qué criterio? 🟡

⏱️ **30 segundos.** Entran los que necesitaron la pista 2 o la 3, o tuvieron más de un WA; los que salieron limpios no.

🗣️ **2 minutos.** La repetición espaciada es cara en tiempo, así que se gasta donde hay algo que fijar. Un problema que salió con la pista 1 o sin pistas ya está en la memoria de producción; uno que necesitó el patrón o el diseño, no. Se repite sin mirar la solución propia, al día siguiente, a los 3 y a los 7 días.

🔬 **El detalle.** Si en la repetición del día 7 vuelve a costar, se reinicia el ciclo. Y el criterio es la ficha de después, no la sensación: «me pareció fácil» después de leer la pista 3 es exactamente la ilusión de fluidez que el capítulo describe.

**06 → 8.** Llevas 15 minutos sin idea en una prueba de empresa de 90 minutos con dos problemas. ¿Qué haces, y por qué? 🟠

⏱️ **30 segundos.** Implemento la fuerza bruta ya, la envío para asegurar los casos pequeños, y sigo pensando la buena con algo que funciona.

🗣️ **2 minutos.** En una prueba de empresa la nota es parcial: la fuerza bruta correcta vale puntos y no penaliza reenviar después. Además, escribirla me obliga a ver qué se repite, que es la pista para la buena, y me da el oráculo para probarla. Con dos problemas en 90 minutos, no puedo dejar uno a cero esperando la idea perfecta.

🔬 **El detalle.** Conviene mirar antes el otro problema: si es más fácil, asegurarlo entero primero es mejor inversión. Y guardar la fuerza bruta aparte antes de reescribir, por si la optimizada no llega a tiempo.

**06 → 9.** ¿Por qué el lineamiento de la IA pide escribir la fuerza bruta antes de preguntarle nada? 🟠

⏱️ **30 segundos.** Porque obliga a entender el problema y a producir algo propio antes de recibir nada; sin eso, cualquier respuesta de la IA es una solución leída, que no se aprende.

🗣️ **2 minutos.** La fuerza bruta es lo mínimo que demuestra que entendiste el problema: qué entra, qué sale y cómo se obtendría a lo bruto. Con ella delante, las preguntas a la IA pasan a ser de *feedback* («¿es correcta?», «¿qué se repite?») y no de solución. Sin ella, la tentación es pedir directamente la respuesta.

🔬 **El detalle.** También cambia la calidad de la ayuda: una IA que ve tu intento puede señalar el error concreto o dar la pista exacta que falta; una que solo ve el enunciado tiende a escribir la solución entera.

**06 → 10.** Para la mayor subida de §4, ¿por qué importa el orden entre usar `minSoFar` y actualizarlo? 🟠

⏱️ **30 segundos.** Porque la subida que termina en `j` tiene que usar el mínimo de los días **anteriores** a `j`; si actualizo antes, el mínimo puede ser el propio `a[j]` y la subida sería `0` con `i = j`.

🗣️ **2 minutos.** El invariante dice que al empezar la vuelta `j`, `minSoFar` es el mínimo de `a[0..j−1]`. Primero se usa (calculando `a[j] − minSoFar`) y después se mantiene (incluyendo `a[j]` para la vuelta siguiente). Al revés, se rompe la condición `i < j` del enunciado.

🔬 **El detalle.** En este problema concreto el error no cambia el resultado final, porque `a[j] − a[j] = 0` y `best` empieza en `0`. Pero en una variante que exija subida estrictamente positiva, o con `best` inicializado de otra forma, sí lo cambia. Es el tipo de error que conviene evitar por el invariante, no por la suerte.

**06 → 11.** Rellena la ficha de antes para «contar los pares `i < j` con `a[i] = a[j]`, `n ≤ 2·10⁵`». 🔴

⏱️ **30 segundos.** Entrada, `n` valores; salida, el número de pares `i < j` iguales. Cabe `n log n` o `n`; la respuesta llega a unos `2·10¹⁰`, en 64 bits. Fuerza bruta `O(n²)`, no cabe. Se repite comparar cada valor con todos los anteriores; la idea es contar cuántas veces apareció cada valor.

🗣️ **2 minutos.** Casos borde: `n = 1` (0 pares), todos iguales (el máximo de pares, `n(n−1)/2`), todos distintos (0). Qué se repite: para cada `j`, contar cuántos `i < j` tienen el mismo valor, recorriéndolos. Idea: un mapa de frecuencias; al llegar a `a[j]`, sumar su frecuencia actual y después incrementarla. O ordenar y, por cada bloque de `c` iguales, sumar `c(c−1)/2`.

🔬 **El detalle.** El invariante del mapa: al empezar la vuelta `j`, `frec[v]` es el número de `i < j` con `a[i] = v`, así que sumar `frec[a[j]]` cuenta exactamente los pares que terminan en `j`. La versión ordenada da `O(n log n)` en caso peor sin depender del *hash*.

**06 → 12.** Una señal del mapa sugiere ventana deslizante para «el subarreglo más corto con suma ≥ S», pero los valores pueden ser negativos. Explica por qué la señal engaña aquí y qué propiedad le falta. 🔴

⏱️ **30 segundos.** La ventana deslizante necesita que, al mover el extremo izquierdo, la suma solo baje, y al mover el derecho, solo suba. Con negativos eso falla, y deja de ser cierto que si una ventana sirve, las que la contienen también.

🗣️ **2 minutos.** El argumento de la ventana es de monotonía: con valores no negativos, si `[l, r]` tiene suma `≥ S`, ampliarla no la hace bajar, así que para cada `r` el mejor `l` solo avanza. Con un negativo dentro, quitar elementos por la izquierda puede **aumentar** la suma, y el mejor `l` ya no se mueve en una sola dirección: la ventana descarta candidatos válidos.

🔬 **El detalle.** La versión correcta trabaja con los prefijos `P` y busca, para cada `r`, el mayor `l` con `P[r] − P[l] ≥ S`, manteniendo una cola de prefijos crecientes (una cola monótona, [`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)). Es el ejemplo canónico de señal que engaña: el enunciado dice «subarreglo» y la técnica correcta no es la ventana.

**06 → Problema: Días récord.**

- **Pista 2 — patrón:** **máximo acumulado**: un día es récord si supera el máximo de los anteriores.
- **Pista 3 — diseño:** recorre llevando el máximo hasta el día anterior; si el día actual es estrictamente mayor, cuenta uno y actualiza el máximo; el primer día cuenta siempre.

**06 → Problema: Los dos más cercanos.**

- **Pista 2 — patrón:** **ordenar**: tras ordenar, la menor diferencia está entre dos vecinos.
- **Pista 3 — diseño:** ordena y toma el mínimo de `a[i+1] − a[i]`; la diferencia llega a `2·10⁹`, así que se calcula en 64 bits.

**06 → Problema: La mejor semana con un día libre.**

- **Pista 2 — patrón:** **ventana deslizante** de tamaño fijo para la suma, más el **mínimo de una ventana**; la primera subtarea sale con fuerza bruta `O(n·k)`.
- **Pista 3 — diseño:** la suma de la ventana se mantiene sumando el que entra y restando el que sale; el mínimo de la ventana se mantiene con una cola doble de índices cuyos valores son crecientes, quitando por detrás los mayores que el que entra y por delante el que sale de la ventana (`06/01`). Todo en 64 bits.

**06 → Problema: Valid Anagram.**

- **Pista 2 — patrón:** **conteo de frecuencias** de caracteres.
- **Pista 3 — diseño:** un arreglo de 26 contadores; suma con la primera cadena y resta con la segunda; son anagramas si todo queda en cero (o si tienen distinta longitud, no lo son).

**06 → Problema: Move Zeroes.**

- **Pista 2 — patrón:** **dos índices** en el sitio: uno lee y otro marca dónde escribir.
- **Pista 3 — diseño:** recorre con el lector; cada distinto de cero se copia en la posición de escritura, que avanza; al final, rellena con ceros desde la posición de escritura hasta el final.

**06 → Problema: Majority Element.**

- **Pista 2 — patrón:** **voto de Boyer-Moore**, o conteo con un mapa.
- **Pista 3 — diseño:** un candidato y un contador: si el contador es 0, el actual pasa a candidato; si coincide, suma; si no, resta. El invariante: descartar parejas de distintos no cambia cuál es mayoritario.

**06 → Problema: Sales by Match.**

- **Pista 2 — patrón:** **conteo** por color.
- **Pista 3 — diseño:** cuenta cuántos calcetines hay de cada color y suma la mitad entera de cada conteo.

**06 → Problema: Counting Valleys.**

- **Pista 2 — patrón:** **simulación** con un nivel acumulado.
- **Pista 3 — diseño:** lleva la altura; un valle termina cuando subes y la altura vuelve exactamente a 0 desde −1; cuenta esos momentos.

**06 → Problema: FrogRiverOne.**

- **Pista 2 — patrón:** **conteo de cobertura** con un arreglo de presencia.
- **Pista 3 — diseño:** marca cada posición la primera vez que cae una hoja y lleva cuántas posiciones distintas de `1` a `X` están cubiertas; el primer segundo en que llegan a `X` es la respuesta, o `−1`.

**06 → Problema: MaxCounters.**

- **Pista 2 — patrón:** **actualización perezosa**: igualar todos al máximo no se hace de verdad.
- **Pista 3 — diseño:** guarda un «suelo» que vale el máximo en el último igualado; al incrementar un contador, súbelo primero al suelo si está por debajo; al final, sube al suelo los que quedaron por debajo. Cada operación es `O(1)` y el total `O(N + M)`.

**06 → Problema: Ferris Wheel.**

- **Pista 2 — patrón:** **ordenar y dos punteros** desde los extremos (voraz).
- **Pista 3 — diseño:** ordena; el más pesado va en una góndola, con el más liviano si caben juntos; si no, solo. Mueve los punteros y cuenta góndolas.

**06 → Problema: Apartments.**

- **Pista 2 — patrón:** **ordenar las dos listas y emparejar con dos punteros**.
- **Pista 3 — diseño:** ordena solicitantes y apartamentos; si el apartamento actual está dentro de la tolerancia del solicitante actual, empareja y avanza los dos; si es demasiado pequeño, avanza el apartamento; si es demasiado grande, avanza el solicitante.

**06 → Problema: Restaurant Customers.**

- **Pista 2 — patrón:** **barrido de eventos** ([`04/04`](../04-secuencias/04-compresion-y-barrido.md)): llegadas `+1`, salidas `−1`, en orden temporal.
- **Pista 3 — diseño:** crea un evento por llegada y otro por salida, ordénalos por tiempo y recórrelos acumulando; el máximo del acumulado es la respuesta.

---

# 07 — Programar en vivo

**07 → 1.** ¿Qué seis puntos tiene la rúbrica en vivo, y qué no se califica? 🟢

⏱️ **30 segundos.** Entender y preguntar, versión ingenua correcta, su coste en voz alta, la mejora nombrada, código legible y prueba a mano con un borde, cada uno de 0 a 2. No se califica que el juez dé verde.

🗣️ **2 minutos.** Los seis puntos miden lo que una persona puede ver en una sesión: si entendiste antes de teclear, si tienes algo correcto, si sabes lo que cuesta y cómo mejorarlo, si tu código se lee y si lo compruebas. El máximo es 12, y se puede alcanzar sin escribir la versión óptima.

🔬 **El detalle.** La rúbrica es la misma para los simulacros en vivo del bloque `21`. Su uso práctico es identificar el punto más bajo de cada sesión y practicar ese en la siguiente; mejorar el que ya está en 2 no mueve la nota.

**07 → 2.** ¿Qué preguntas haces antes de teclear, y por qué cada una puede cambiar la solución? 🟢

⏱️ **30 segundos.** Cuánto vale `n`, si hay negativos, ceros o duplicados, si la entrada puede estar vacía, si puedo modificarla, qué devuelvo si no hay respuesta y si importa el orden de la salida.

🗣️ **2 minutos.** `n` decide la complejidad que cabe. Los negativos rompen técnicas como la ventana deslizante o un máximo inicializado en cero; los duplicados cambian conteos. La entrada vacía es el primer borde. Poder modificar la entrada permite ordenar en el sitio. Y lo que se devuelve sin respuesta, y en qué orden, es parte de la firma.

🔬 **El detalle.** Los enunciados de entrevista suelen estar incompletos a propósito, para ver si preguntas. Si el enunciado ya lo dice todo, se resume en voz alta lo que se asume y se sigue; preguntar lo obvio no suma.

**07 → 3.** ¿Qué cuatro salidas tienes cuando te quedas en blanco? 🟢

⏱️ **30 segundos.** Volver al ejemplo y resolverlo a mano, simplificar el problema, pensar qué estructura haría trivial la operación repetida, y pedir una pista con una hipótesis.

🗣️ **2 minutos.** Lo que haces a mano con un ejemplo pequeño suele ser el algoritmo. Simplificar («¿y si fueran distintos?», «¿y si `n` fuera 3?») da una versión fácil que ilumina la difícil. Preguntar qué estructura abarataría lo que se repite lleva a mapas, montículos o prefijos. Y pedir ayuda con una hipótesis concreta muestra razonamiento.

🔬 **El detalle.** Las cuatro se hacen en voz alta. El silencio es lo único que no tiene salida, porque la persona no puede ayudarte ni puntuarte. Son, en esencia, las preguntas de Pólya para cuando no se ve el plan.

**07 → 4.** ¿Qué diferencia hay entre una mejora nombrada vagamente y una nombrada con precisión? Da un ejemplo de cada una. 🟡

⏱️ **30 segundos.** La vaga no dice ni técnica ni coste («se puede optimizar»); la precisa dice las dos («con un mapa de la última posición baja a `O(n)` esperado»).

🗣️ **2 minutos.** La rúbrica puntúa 2 solo si la mejora tiene nombre y coste, porque así se ve que sabes qué hace y por qué funciona. «Usaría programación dinámica» es 1; «memoización sobre `(i, restante)`, cada estado una vez, `O(n·k)`» es 2.

🔬 **El detalle.** La frase precisa sigue un orden fijo: el coste de la versión actual, lo que se repite, la técnica que lo evita y el coste nuevo. Si te falta alguna de las cuatro piezas, es señal de que la mejora aún no está clara.

**07 → 5.** ¿Qué diferencia hay entre lo que evalúa un juez y lo que evalúa una persona en una entrevista en vivo? 🟡

⏱️ **30 segundos.** El juez mide si la salida es correcta dentro del límite; la persona mide cómo llegas: si entiendes, si tienes algo correcto, si sabes lo que cuesta y si sabes mejorarlo.

🗣️ **2 minutos.** Un juez da AC a una solución copiada y WA a una muy bien razonada con un error de índice. Una persona hace casi lo contrario: puntúa alto una ingenua bien explicada con la mejora nombrada, y bajo un óptimo en silencio que no puede verificar.

🔬 **El detalle.** Muchas entrevistas en vivo ni siquiera ejecutan el código. Por eso la prueba a mano con un borde es un punto de la rúbrica: es la forma de mostrar corrección sin juez.

**07 → 6.** ¿Qué diferencia hay entre probar con el ejemplo y probar a mano con un borde? 🟡

⏱️ **30 segundos.** Probar con el ejemplo comprueba el caso del centro, que casi siempre pasa; probar a mano con un borde recorre el código en un extremo, donde están los errores.

🗣️ **2 minutos.** El ejemplo del enunciado suele estar pensado para ilustrar, no para romper. Un borde de la lista fija —un elemento, todos iguales, la respuesta al final— fuerza al código por las ramas que el ejemplo no visita: el bucle que no entra, la última iteración, el valor inicial.

🔬 **El detalle.** «A mano» significa como la máquina: línea a línea, con una tabla de variables, no como uno cree que funciona. Es la misma traza que el corpus usa para enseñar invariantes.

**07 → 7.** ¿Por qué una versión ingenua correcta puntúa más que un óptimo a medias? 🟠

⏱️ **30 segundos.** Porque demuestra que entendiste el problema, que sabes escribir código correcto y que tienes algo concreto que mejorar; un óptimo a medias no demuestra nada verificable.

🗣️ **2 minutos.** La ingenua completa suma en tres puntos de la rúbrica (versión correcta, su coste, y a menudo la mejora que aparece al escribirla). El óptimo a medias puede no compilar, no se puede probar, y si estaba en silencio, no deja razonamiento puntuable.

🔬 **El detalle.** Hay un efecto práctico: escribir la ingenua en voz alta hace visible el trabajo repetido, que es justo lo que la técnica buena elimina. Muchas veces la mejora aparece mientras se teclea la ingenua.

**07 → 8.** Llevas 30 minutos de 45, tienes la ingenua probada y sabes la mejora. ¿La escribes o no, y qué dices? 🟠

⏱️ **30 segundos.** Primero digo la mejora con nombre y coste; después la escribo si me da tiempo de terminarla y probarla. Si no, la dejo nombrada y pruebo bien la ingenua.

🗣️ **2 minutos.** Con 15 minutos, una mejora corta (un mapa en lugar de un bucle) cabe con su prueba. Una larga (una DP nueva) probablemente no, y una versión a medio escribir resta puntos de legibilidad y de prueba. La decisión se dice en voz alta: «la mejora es esta, con este coste; la escribo» o «prefiero dejarla descrita y recorrer la actual con un borde».

🔬 **El detalle.** Lo peor es borrar la ingenua para escribir la buena encima: si la buena no llega, no queda nada correcto. La buena se escribe aparte, o como una función nueva.

**07 → 9.** En el ejemplo de §7, ¿por qué el `put` va después de la comprobación y no antes? 🟠

⏱️ **30 segundos.** Porque si guardo primero la posición `j`, al buscar encontraría la propia `j` y compararía la posición consigo misma: con `k ≥ 0` devolvería `true` para cualquier arreglo.

🗣️ **2 minutos.** El invariante dice que al empezar la vuelta `j` el mapa tiene las últimas posiciones en `[0, j−1]`. Primero se usa (buscando una aparición anterior) y después se mantiene (añadiendo `j`). Invertir el orden mete `j` en el rango que se consulta, y la distancia `j − j = 0` cumple siempre `≤ k`.

🔬 **El detalle.** Es el mismo patrón de «usar antes de actualizar» de la mayor subida en [`01/06`](06-protocolo-de-resolucion.md), y aparece en casi todos los recorridos con estado acumulado: conteo de pares, prefijos con mapa, mínimos acumulados.

**07 → 10.** En el ejemplo de §7, ¿qué devuelve `lastSeen.get(a[j])` cuando el valor no se vio nunca, y qué pasaría si lo guardaras directamente en un `int`? 🟠

⏱️ **30 segundos.** Devuelve `null`. Si lo guardas en un `int`, Java intenta desempaquetar `null` y lanza `NullPointerException`: un RE.

🗣️ **2 minutos.** `Map.get` devuelve un `Integer`, que puede ser `null` cuando la clave no está. Asignarlo a `int` desempaqueta automáticamente, y desempaquetar `null` lanza la excepción. Por eso el código del capítulo lo guarda en un `Integer` y comprueba `!= null` antes de restar.

🔬 **El detalle.** Las alternativas son `getOrDefault(a[j], -k - 1)`, con un valor centinela que nunca cumple la distancia, o `containsKey` antes del `get`. Y la trampa vecina es comparar dos `Integer` con `==`, que compara referencias y falla fuera del rango `−128..127` (`03/03`).

**07 → 11.** Narra, en cinco o seis frases, la versión ingenua y la mejora para «¿hay dos números del arreglo que sumen `K`?», con su coste. 🔴

⏱️ **30 segundos.** «La directa prueba todas las parejas: `O(n²)`, que con `n = 10⁵` son `10¹⁰` pasos y no cabe. Lo que repito es buscar, para cada número, su complemento `K − a[i]`. Con un conjunto hash de los vistos, cada búsqueda es `O(1)` esperado y el total `O(n)`.»

🗣️ **2 minutos.** La narración completa añade las preguntas (¿la misma posición dos veces vale?, ¿hay negativos?, ¿qué devuelvo?), la prueba de la ingenua con un ejemplo, y la alternativa sin *hash*: ordenar y usar dos punteros desde los extremos, `O(n log n)` en caso peor. Y un detalle de tipos: `K − a[i]` puede desbordar `int` si los valores llegan a `10⁹`.

🔬 **El detalle.** El orden de insertar importa igual que en §7: buscar el complemento antes de insertar el actual evita emparejar un elemento consigo mismo cuando `K = 2·a[i]`.

**07 → 12.** Califica con la rúbrica esta sesión: el candidato no preguntó nada, escribió directamente la versión óptima, correcta, con variables `a`, `b`, `c`, dijo «es lineal» sin más, y no probó. Justifica cada punto. 🔴

⏱️ **30 segundos.** Entender y preguntar: 0. Ingenua correcta: 2, porque escribió una versión correcta y completa, aunque fuera la óptima. Coste: 1. Mejora nombrada: 0 o 1. Legibilidad: 0 o 1. Prueba a mano: 0. Entre 3 y 5 de 12.

🗣️ **2 minutos.** No preguntó nada: 0. La versión es correcta y completa: el punto de «versión correcta» se da aunque no fuera la ingenua, 2. «Es lineal» sin cuenta ni restricciones: 1. No hubo mejora que nombrar porque empezó por la óptima; si no explicó por qué es mejor que la directa, 0, y si lo insinuó, 1. Variables `a`, `b`, `c`: 0 o 1 según la estructura. No probó: 0.

🔬 **El detalle.** El caso enseña que llegar al óptimo no basta: el candidato resolvió el problema y saca menos de la mitad. Con las mismas líneas de código y diez minutos más de voz alta —preguntas, coste con la cuenta, por qué no la directa, un borde recorrido— habría sacado 10 o más.

**07 → 13.** Para el ejemplo de §7, propón una variante que use memoria `O(k)` en vez de `O(n)`, di su invariante y su coste. 🔴

⏱️ **30 segundos.** Mantengo un conjunto con los valores de las últimas `k` posiciones: al llegar a `j`, si `a[j]` está en el conjunto, hay un par; si no, lo añado y quito `a[j − k]` cuando el conjunto pasa de `k` elementos. Tiempo `O(n)` esperado, memoria `O(k)`.

🗣️ **2 minutos.** El invariante: al empezar la vuelta `j`, el conjunto contiene exactamente los valores de las posiciones `[j − k, j − 1]` (o desde 0 si `j < k`). Un par válido que termina en `j` tiene su otra posición en ese rango, así que basta con preguntar si `a[j]` está. Después se mantiene: entra `a[j]` y sale `a[j − k]`.

🔬 **El detalle.** Como dentro de la ventana no hay repetidos (si los hubiera, ya se habría devuelto `true`), quitar `a[j − k]` borra exactamente un elemento. Es una ventana deslizante de tamaño fijo, y se elige frente al mapa solo si la memoria importa más que la sencillez.

**07 → Problema: Rotación de una palabra.**

- **Pista 2 — patrón:** **búsqueda de subcadena**: toda rotación de `s` es una subcadena de `s + s`.
- **Pista 3 — diseño:** comprueba primero que las longitudes coinciden; después, si `t` aparece dentro de `s + s`. La versión ingenua prueba cada rotación en `O(n²)`; la búsqueda de subcadena con KMP o la función Z ([`16/02`](../16-cadenas/02-kmp.md), [`16/03`](../16-cadenas/03-funcion-z-y-manacher.md)) la deja en `O(n)`.

**07 → Problema: Compresión por rachas.**

- **Pista 2 — patrón:** **recorrido con racha actual**, con el borde del último tramo y la construcción eficiente de la cadena.
- **Pista 3 — diseño:** recorre llevando el carácter actual y su cuenta; al cambiar de carácter (y al terminar), añade el carácter y, si la cuenta es mayor que 1, el número; construye con un `StringBuilder` y compara longitudes al final.

**07 → Problema: Reuniones que se pisan.**

- **Pista 2 — patrón:** **ordenar por inicio y fusionar** con el último intervalo de la salida ([`11/02`](../11-voraces/02-intervalos.md)).
- **Pista 3 — diseño:** ordena por inicio; recorre: si el inicio del actual es **estrictamente menor** que el fin del último fusionado, se solapan y el fin pasa a ser el máximo de los dos; si no, el actual abre un intervalo nuevo. El «estrictamente» es por los intervalos semiabiertos.

**07 → Problema: Merge Two Sorted Lists.**

- **Pista 2 — patrón:** **mezcla** de dos secuencias ordenadas con un nodo centinela.
- **Pista 3 — diseño:** un nodo ficticio al que se cuelga la salida; en cada paso, enlaza el menor de las dos cabezas y avanza en esa lista; cuando una se acaba, enlaza el resto de la otra entero.

**07 → Problema: Longest Common Prefix.**

- **Pista 2 — patrón:** **recorrido por columnas**: la posición `i` de todas las palabras a la vez.
- **Pista 3 — diseño:** para cada posición `i` desde 0, compara el carácter de la primera palabra con el de todas las demás; para en cuanto una palabra se acaba o difiere, y el prefijo es lo recorrido hasta ahí.

**07 → Problema: Roman to Integer.**

- **Pista 2 — patrón:** **recorrido mirando el vecino**: un símbolo resta si el siguiente es mayor.
- **Pista 3 — diseño:** suma el valor de cada símbolo, salvo que el siguiente sea mayor, en cuyo caso lo restas; el último siempre suma.

**07 → Problema: Is Subsequence.**

- **Pista 2 — patrón:** **dos índices**, voraz: emparejar cada carácter de `s` con su primera aparición posible en `t`.
- **Pista 3 — diseño:** un índice en `s` y otro en `t`; el de `t` avanza siempre, el de `s` solo cuando coinciden; es subsecuencia si el de `s` llega al final.

**07 → Problema: Group Anagrams.**

- **Pista 2 — patrón:** **clave canónica** en un mapa: todos los anagramas comparten la misma clave.
- **Pista 3 — diseño:** la clave puede ser la palabra con sus letras ordenadas, o el vector de 26 conteos; agrupa en un mapa de clave a lista y devuelve los valores.

**07 → Problema: Balanced Brackets.**

- **Pista 2 — patrón:** **pila**: cada cierre tiene que emparejar con la última apertura sin cerrar (`06/01`).
- **Pista 3 — diseño:** apila las aperturas; ante un cierre, la pila no puede estar vacía y su cima tiene que ser la apertura correspondiente, que se desapila; al final, la pila tiene que quedar vacía.

**07 → Problema: MaxProductOfThree.**

- **Pista 2 — patrón:** **ordenar y mirar los extremos**.
- **Pista 3 — diseño:** tras ordenar, el máximo es el mayor entre el producto de los tres mayores y el del mayor con los dos menores (dos negativos dan positivo).

**07 → Problema: Product of Array Except Self.**

- **Pista 2 — patrón:** **prefijos y sufijos** de productos, sin división.
- **Pista 3 — diseño:** la respuesta en `i` es el producto de todo lo que está a la izquierda por el de todo lo que está a la derecha; calcula el primero en un recorrido hacia delante y multiplícalo por el segundo en un recorrido hacia atrás con un acumulador.

**07 → Problema: Top K Frequent Elements.**

- **Pista 2 — patrón:** **conteo** con un mapa y **selección** con un montículo de tamaño `k` o con cubetas por frecuencia.
- **Pista 3 — diseño:** cuenta frecuencias; o mantén un montículo de mínimos con `k` elementos ordenado por frecuencia, o crea cubetas indexadas por frecuencia (de 1 a `n`) y recórrelas de la más alta a la más baja hasta reunir `k`.

**07 → Problema: Longest Substring Without Repeating Characters.**

- **Pista 2 — patrón:** **ventana deslizante** con la última posición de cada carácter.
- **Pista 3 — diseño:** el extremo derecho avanza siempre; si el carácter que entra ya está dentro de la ventana, el inicio salta justo después de su última aparición (nunca hacia atrás); la respuesta es la mayor anchura de ventana vista.

---

# 08 — Simulación

**08 → S1.** ¿Qué te dice y qué no te dice el número del caso en que falla un envío? 🟢

⏱️ **30 segundos.** Te dice dónde falló, y eso orienta: casos tempranos sugieren la idea o un borde; casos tardíos, el tamaño o el desbordamiento. No te dice la entrada, ni la causa, ni si los casos siguientes pasarían.

🗣️ **2 minutos.** Los casos se ordenan de pequeños a grandes: ejemplos, bordes a mano, aleatorios, máximos y adversarios. Un WA en el caso 3 casi nunca es desbordamiento; un TLE en el 38 casi siempre es complejidad o E/S. El número es una pista sobre la etapa del problema, no un diagnóstico.

🔬 **El detalle.** En una prueba de empresa a veces ni siquiera ves el número, solo «9/15». Ahí la información está en el patrón: si fallan siempre los mismos casos, apunta a una categoría (los grandes, los de negativos) que se reproduce con un generador. Ver [`01/01`](01-el-juez-los-veredictos-y-las-plataformas.md).

**08 → S2.** ¿Por qué el juez solo te muestra el primer veredicto distinto de AC? 🟢

⏱️ **30 segundos.** Porque el juez para en el primer caso que falla: los siguientes no se ejecutan.

🗣️ **2 minutos.** Es una decisión de coste: ejecutar todos los casos de todos los envíos fallidos multiplicaría el trabajo del juez. La consecuencia es que un TLE en el caso 20 no dice nada de los casos 21 a 40, y que un programa con dos bugs distintos solo te enseña el primero.

🔬 **El detalle.** Algunas plataformas de empresa sí ejecutan todos los casos para dar puntuación parcial, y por eso muestran «9/15». En esas, el conjunto de casos fallidos sí es información completa.

**08 → S3.** ¿Qué cambia en tu estrategia entre una prueba de Codility y un concurso de Codeforces? 🟡

⏱️ **30 segundos.** En Codility la nota es parcial y separa corrección de rendimiento: envío pronto una versión correcta y después optimizo. En Codeforces cada envío fallido penaliza: pruebo antes de enviar.

🗣️ **2 minutos.** Codility puntúa por grupos de casos, y una solución correcta pero cuadrática se queda cerca de la mitad; asegurarla primero es racional. En una ronda de Codeforces un envío fallido cuesta 50 puntos y el problema es todo o nada; ahí se gana probando contra los bordes y, si hay duda, con un *stress test*.

🔬 **El detalle.** Además, Codility pide una función y Codeforces el programa entero: en Codeforces la E/S es tuya y puede dar TLE. Ver `01/01` y [`01/03`](03-entrada-salida-y-plantilla.md).

**08 → S4.** ¿Qué tres versiones de lenguaje fija el corpus y de dónde sale cada una? 🟡

⏱️ **30 segundos.** C++20, Java 21 y Python 3.12: la intersección de lo que ofrecen HackerRank, LeetCode y Codility.

🗣️ **2 minutos.** C++20 porque Codility corre G++ 10.3 y 13.3 y lo de C++23 que no está en 13.3 no se puede usar; Java 21 porque es lo que corren HackerRank y Codility, aunque LeetCode tenga 25; Python 3.12 porque es lo que corre Codility. En HackerRank, además, hay que elegir la opción «C++23», porque la de «C++20» es G++ 8.3.

🔬 **El detalle.** Lo posterior a esas versiones aparece solo en callouts 📝 («Desde Java 22», «Desde C++23»), y nunca en una plantilla. Las versiones se comprobaron el 2026-10-03.

**08 → S5.** Con `n ≤ 3 000`, ¿cabe `O(n²)`? ¿Y `O(n² log n)`? Haz las cuentas. 🟢

⏱️ **30 segundos.** `n² = 9·10⁶`: cabe con holgura. `n² log n ≈ 9·10⁶ · 12 ≈ 10⁸`: cabe justo, con constante baja.

🗣️ **2 minutos.** `3000² = 9 000 000`. `log₂ 3000 ≈ 11,6`, así que `n² log n` son unos `1,05·10⁸` pasos: en el borde de la regla de los `10⁸` por segundo. En C++ con operaciones simples entra; en Java con objetos o en Python, probablemente no.

🔬 **El detalle.** Es justo la zona donde deciden la constante y el lenguaje (`01/02`, §4). Si el `log n` viene de un `TreeMap` con *boxing*, la constante puede multiplicar por diez.

**08 → S6.** ¿Cuántos `long long` caben en 64 MB? 🟢

⏱️ **30 segundos.** Unos 8,4 millones: 64 MB son `67 108 864` bytes, entre 8.

🗣️ **2 minutos.** `64 · 2²⁰ = 67 108 864` bytes; dividido por 8 bytes por `long long` da `8 388 608` elementos. En la práctica, con el resto del programa en memoria, conviene quedarse por debajo de unos 6 millones.

🔬 **El detalle.** Con `int` serían el doble. Con `Long` en una colección de Java, entre una cuarta y una quinta parte, por el objeto y el puntero.

**08 → S7.** ¿Por qué `1 << 40` no vale `2⁴⁰` ni en C++ ni en Java, y qué da en cada uno? 🟡

⏱️ **30 segundos.** Porque `1` es un `int` de 32 bits. En Java el desplazamiento usa la cuenta módulo 32 y da `1 << 8 = 256`; en C++ es comportamiento indefinido.

🗣️ **2 minutos.** El tipo del literal decide el tipo de la operación. Java define que el desplazamiento de un `int` usa solo los 5 bits bajos de la cuenta, así que 40 se convierte en 8. C++ no define el resultado de desplazar 32 posiciones o más. En los dos, la solución es un literal de 64 bits: `1L << 40`, `1LL << 40`.

🔬 **El detalle.** Es la misma familia que `(long) a * b` frente a `(long) (a * b)`: el tipo grande tiene que estar antes de operar. Ver `01/04`.

**08 → S8.** ¿Qué diferencia hay entre desbordar en Java y desbordar en C++, en cuanto a lo que puedes predecir? 🟡

⏱️ **30 segundos.** En Java el resultado es predecible: da la vuelta en complemento a dos. En C++, con enteros con signo, es comportamiento indefinido: el compilador puede asumir que no ocurre y el programa puede hacer cualquier cosa.

🗣️ **2 minutos.** En Java, `Integer.MAX_VALUE + 1` es siempre `Integer.MIN_VALUE`: el error es determinista y se reproduce. En C++ el optimizador puede eliminar comprobaciones que dependen del desbordamiento, así que el mismo código se comporta distinto con `-O0` y con `-O2`, y en tu máquina y en el juez.

🔬 **El detalle.** En los dos casos la respuesta es incorrecta; lo que cambia es la facilidad de depurar. En C++, `-fsanitize=undefined` convierte el desbordamiento en un error con línea. Ver `01/04` y `01/05`.

**08 → S9.** Un problema pide «el número de caminos, módulo 10⁹+7» y tu fórmula tiene una división. ¿Qué haces? 🟠

⏱️ **30 segundos.** No divido: multiplico por el inverso modular del divisor, que existe porque `10⁹ + 7` es primo y el divisor no es múltiplo suyo.

🗣️ **2 minutos.** La división no respeta el módulo: `(a / b) mod m` no es `(a mod m) / (b mod m)`. Pero `a / b ≡ a · b⁻¹ (mod m)`, y con `m` primo el inverso se obtiene con el pequeño teorema de Fermat, `b⁻¹ ≡ b^(m−2)`, por exponenciación rápida en `O(log m)`.

🔬 **El detalle.** La teoría está en `17/03`. Si la fórmula es un coeficiente binomial, lo habitual es precalcular factoriales y sus inversos ([`17/05`](../17-matematica/05-combinatoria.md)). Si el divisor puede ser múltiplo de `m`, hace falta otra técnica.

**08 → S10.** Con `n ≤ 10⁵` y valores `≤ 10⁶`, ¿qué te permite el valor que no te permitiría con valores `≤ 10⁹`? 🟠

⏱️ **30 segundos.** Indexar por valor: con valores hasta `10⁶` cabe un arreglo de conteo de `10⁶ + 1` posiciones; con `10⁹`, no.

🗣️ **2 minutos.** El tamaño (`n ≤ 10⁵`) decide la complejidad, que en los dos casos es `n log n` o mejor. El valor decide la estructura: un arreglo de conteo da acceso `O(1)` sin *hash* y sin ordenar, pero solo si su tamaño cabe en memoria. Con `10⁹` hay que ordenar, comprimir coordenadas o usar un mapa.

🔬 **El detalle.** Un arreglo de `10⁶ + 1` `int` son 4 MB. Uno de `10⁹ + 1` serían 4 GB. Ver `01/02`, §6.

**08 → S11.** ¿Qué dos líneas van al principio de todo `main` de C++ del corpus, y cuándo una de ellas sobra? 🟢

⏱️ **30 segundos.** `std::ios::sync_with_stdio(false);` y `std::cin.tie(nullptr);`. La segunda sobra, y hay que pensarla, en los problemas interactivos.

🗣️ **2 minutos.** La primera desacopla `iostream` de `stdio` para que cada flujo tenga su búfer; la segunda evita que cada lectura vacíe la salida. En un problema interactivo el juez espera tu pregunta antes de responder, así que la salida se vacía a mano antes de leer.

🔬 **El detalle.** Tras la primera ya no se mezclan `cin` con `scanf` ni `cout` con `printf`. Ver `01/03`.

**08 → S12.** ¿Qué olvido convierte la plantilla de Java en un WA en todos los casos? 🟢

⏱️ **30 segundos.** Olvidar el `out.flush()` final del `PrintWriter`: la salida se queda en el búfer y el juez ve una salida vacía.

🗣️ **2 minutos.** El `PrintWriter` sobre un `BufferedWriter` acumula todo y solo escribe cuando se llena el búfer o se vacía explícitamente. Si el programa termina sin vaciarlo, lo que quedaba en el búfer se pierde. Da WA incluso en el ejemplo, lo que paradójicamente lo hace fácil de detectar si pruebas el archivo exacto que envías.

🔬 **El detalle.** Cerrar el `PrintWriter` con `close()` también vacía. Lo que no funciona es confiar en que la JVM lo haga al salir.

**08 → S13.** ¿Cuándo lees línea a línea en Python y cuándo todo de golpe? 🟡

⏱️ **30 segundos.** Todo de golpe, con `sys.stdin.buffer.read().split()`, cuando la entrada es una lista de números; línea a línea, con `sys.stdin.readline`, cuando las líneas tienen estructura que no se puede perder, como nombres con espacios.

🗣️ **2 minutos.** Leer todo de golpe es lo más rápido porque es una sola llamada que trabaja en C, pero pierde los saltos de línea. Si una línea es un nombre de varias palabras, partir por blancos la rompe; ahí se lee por líneas y se parte cada una como haga falta.

🔬 **El detalle.** `readline` devuelve la línea con su `'\n'`, así que para comparar cadenas hay que quitarlo. Ver `01/03`, §5.

**08 → S14.** Tu solución en Python es `O(n)` con `n = 10⁶` y da TLE. ¿Qué miras antes de cambiar de algoritmo? 🟠

⏱️ **30 segundos.** La E/S: si leo con `input()` y escribo con `print` en un bucle de un millón, eso solo puede dar TLE. Después, si el bucle principal es de Python puro y podría delegarse en funciones de la librería.

🗣️ **2 minutos.** Un algoritmo `O(n)` con `n = 10⁶` son un millón de iteraciones, que en Python ya rondan el segundo. Si además cada iteración llama a `input()` y a `print`, la E/S domina. La plantilla de `01/03` —leer todo de golpe, escribir una vez, código dentro de una función— suele bastar.

🔬 **El detalle.** Si con la E/S rápida sigue sin entrar, el siguiente paso es empujar el trabajo a operaciones en C (`sum`, `sorted`, `map`) o, si la plataforma lo ofrece, PyPy ([`03/04`](../03-biblioteca-estandar/04-python-para-competir.md)). Cambiar de algoritmo es lo último, porque el algoritmo ya es lineal.

**08 → S15.** ¿Qué hace un *stress test* que no hace probar con el ejemplo? 🟢

⏱️ **30 segundos.** Prueba miles de entradas pequeñas y distintas contra un oráculo, en vez de una entrada del centro elegida para ilustrar.

🗣️ **2 minutos.** El ejemplo del enunciado casi nunca toca los bordes. El generador aleatorio con rangos pequeños produce duplicados, negativos, ceros y tamaños mínimos con frecuencia, y la fuerza bruta da la respuesta correcta de cada uno. El arnés para en la primera diferencia y te deja un caso pequeño que se traza a mano.

🔬 **El detalle.** También detecta caídas si trata un código de salida distinto de cero como fallo. Ver `01/05`, §4.

**08 → S16.** ¿Por qué la fuerza bruta de un *stress test* no debe compartir código con la solución? 🟡

⏱️ **30 segundos.** Porque si comparten código, comparten bugs, y el *stress test* compara dos programas que fallan igual: no encuentra nada.

🗣️ **2 minutos.** El oráculo tiene que ser independiente. Si la fuerza bruta usa la misma función de lectura, la misma auxiliar o la misma inicialización que la solución, un error en esa pieza aparece en las dos salidas y la comparación dice «iguales».

🔬 **El detalle.** La fuerza bruta se escribe lo más directa posible, preferiblemente sin mirar la solución. Si el caso reducido sigue sin explicarse, conviene comprobar la fuerza bruta a mano con ese caso.

**08 → S17.** ¿Qué tipo de fallo no encuentra un *stress test* con entradas pequeñas, y cómo lo buscas? 🟠

⏱️ **30 segundos.** Los fallos que dependen del tamaño: TLE, desbordamiento y recursión profunda. Se buscan generando el caso máximo y revisando tipos y complejidad.

🗣️ **2 minutos.** Con `n ≤ 8` y valores entre `−5` y `5` nunca hay una suma que desborde ni un tiempo que se note. Para eso se genera una entrada con el `n` y los valores máximos, se mide el tiempo y se compara la salida con la de la fuerza bruta si esta termina, o con la suma de comprobación que puedas calcular.

🔬 **El detalle.** El caso máximo «malo» depende del algoritmo: para una recursión, una lista en cadena; para un *hash*, valores que colisionen; para un `quicksort`, la entrada ordenada. Ver `01/05` y `01/02`.

**08 → S18.** El *sanitizer* de C++ se detiene en una línea con «signed integer overflow». ¿Qué te está diciendo, y por qué sin él podrías no verlo? 🟠

⏱️ **30 segundos.** Que en esa línea una operación con enteros con signo se pasó del rango del tipo. Sin el *sanitizer*, el programa sigue con un valor basura o el compilador lo optimiza de forma impredecible, y el síntoma aparece lejos o no aparece.

🗣️ **2 minutos.** El desbordamiento con signo en C++ es comportamiento indefinido: no hay excepción ni aviso. `-fsanitize=undefined` instrumenta cada operación para comprobarlo y detenerse con la línea exacta. Sin él, el error puede manifestarse como un WA en otro sitio, o solo con `-O2`.

🔬 **El detalle.** La corrección casi siempre es de tipo: pasar a `long long` antes de operar. Ver `01/04`.

**08 → S19.** ¿Qué fila de la ficha de antes suele llevar a la idea optimizada? 🟢

⏱️ **30 segundos.** «Qué se repite»: el trabajo que la fuerza bruta hace muchas veces es lo que la técnica buena evita.

🗣️ **2 minutos.** La fila de la fuerza bruta da el punto de partida, y «qué se repite» da la dirección: si se repite buscar el mínimo de los anteriores, se lleva acumulado; si se repite buscar un complemento, un mapa; si se repite sumar rangos, prefijos.

🔬 **El detalle.** El mapa de señales (`01/06`, §8) complementa esa fila: la señal sugiere candidatas y «qué se repite» confirma cuál.

**08 → S20.** ¿Cuándo pides la pista 2, y qué anotas cuando lo haces? 🟡

⏱️ **30 segundos.** Cuando llevo 10 minutos sin idea después de la pista 1; y anoto en la ficha de después que necesité la 2, para que el problema entre en la repetición espaciada.

🗣️ **2 minutos.** El reloj del protocolo es 20 minutos para la 1, 10 más para la 2 y 10 más para la 3. Anotar la pista no es castigo: es el dato que dice qué repasar. Un problema que necesitó la 2 se repite sin mirar al día siguiente, a los 3 y a los 7.

🔬 **El detalle.** Pedir la 2 antes de tiempo quita el trabajo que fija el patrón; pedirla demasiado tarde gasta tiempo en un callejón. El reloj es una regla para no decidir con el ánimo.

**08 → S21.** ¿Qué dos frases dices después de escribir la versión ingenua en una entrevista en vivo? 🟡

⏱️ **30 segundos.** El coste de la ingenua con la cuenta («es `O(n²)`, con `n = 10⁵` son `10¹⁰` pasos») y la mejora con nombre y coste («con un mapa de vistos baja a `O(n)` esperado»).

🗣️ **2 minutos.** La primera muestra que sabes medir lo que escribiste y que entiendes por qué no basta. La segunda, que sabes qué técnica lo resuelve y cuánto cuesta. Juntas valen dos puntos de la rúbrica aunque no llegues a escribir la mejora.

🔬 **El detalle.** El orden de la segunda frase es fijo: lo que se repite, la técnica que lo evita y el coste nuevo. Ver [`01/07`](07-programar-en-vivo.md), §4.

**08 → S22.** ¿Qué haces con la IA cuando llevas 20 minutos atascado en un problema de práctica? 🟠

⏱️ **30 segundos.** Le enseño mi fuerza bruta y mi intento, y le pido *feedback* o la pista siguiente, nunca la solución.

🗣️ **2 minutos.** Primero escribo en mis palabras la versión ingenua y su coste, y el código que tenga, aunque sea incompleto. Después pregunto cosas verificables: «¿es correcta mi fuerza bruta?», «¿qué se repite?», «dame una pista que no nombre la técnica». Si sigo atascado, la siguiente pista, con los mismos niveles del corpus.

🔬 **El detalle.** El cierre es sin ella: explicar en voz alta el invariante y el coste de mi versión final, y anotar qué pista necesité. Ver el lineamiento entero en `01/06`, §6.

**08 → S23.** Tu solución pasa el ejemplo y da WA en el caso 2. ¿Qué miras primero? 🟠

⏱️ **30 segundos.** El formato y el estado: que la salida tenga exactamente el formato pedido y que no arrastre estado de un caso de prueba al siguiente.

🗣️ **2 minutos.** El caso 2 suele ser pequeño y de forma parecida al ejemplo, así que un fallo ahí rara vez es de complejidad o de tipo. Lo frecuente: una entrada con varios casos donde no reinicias un acumulador, un borde sencillo (`n = 1`), o un formato que difiere en algo que el ejemplo no muestra (mayúsculas, separadores, una línea por caso).

🔬 **El detalle.** Si nada de eso, el siguiente paso es el *stress test* con un generador que produzca varios casos por entrada.

**08 → S24.** ¿Y si `n` fuera `10¹²`? Para un problema de «suma de `1` a `n`», ¿qué cambia en tu solución? 🟠

⏱️ **30 segundos.** Ya no puedo recorrer de `1` a `n`: uso la fórmula `n(n+1)/2`. Y el resultado, unos `5·10²³`, no cabe en 64 bits: necesito `__int128`, `BigInteger`, Python, o el módulo que pida el enunciado.

🗣️ **2 minutos.** Con `n = 10¹²` un bucle de `n` vueltas son `10¹²` pasos: imposible. La fórmula es `O(1)`. Pero `n(n+1)` llega a `10²⁴`, muy por encima de `9,2·10¹⁸`. Si se pide módulo `10⁹+7`, se reduce `n` y `n+1` antes de multiplicar y se multiplica por el inverso de 2 en vez de dividir.

🔬 **El detalle.** El orden de las operaciones importa incluso sin módulo: dividir antes por 2 el factor par evita una parte del desbordamiento, pero con `10¹²` el producto sigue sin caber. Es una pregunta de lectura de restricciones (`01/02`) y de tipos (`01/04`) a la vez.

**08 → S25.** El entrevistador te dice «tu solución es correcta, ¿cuánta memoria usa?» y no lo habías pensado. Responde para una solución con un mapa de `n` enteros en Java. 🔴

⏱️ **30 segundos.** Un `HashMap<Integer, Integer>` con `n` entradas usa del orden de 50 a 80 bytes por entrada en Java: con `n = 10⁶`, entre 50 y 80 MB, mucho más que los 8 MB de dos `int[]`.

🗣️ **2 minutos.** Cada entrada tiene un nodo (con la clave, el valor, el *hash* y el puntero al siguiente) y dos objetos `Integer` para la clave y el valor, además de la tabla de cubetas, que se mantiene con holgura según el factor de carga. Todo eso multiplica el coste de un `int` de 4 bytes por más de diez.

🔬 **El detalle.** Si los valores son acotados, un arreglo indexado por valor es la alternativa compacta; si no, ordenar y trabajar con arreglos primitivos. Las cifras exactas dependen de la JVM y de la compresión de punteros; lo que importa en la entrevista es el orden de magnitud y saber de dónde sale. Ver `02/05`.

**08 → S26.** Te dan un problema con `n ≤ 15` y la idea óptima es una DP que no ves clara. Argumenta por qué escribirías otra cosa. 🔴

⏱️ **30 segundos.** Con `n ≤ 15` hay `2¹⁵ = 32 768` subconjuntos: una fuerza bruta que los enumere cabe de sobra, es correcta por construcción y se escribe en cinco minutos.

🗣️ **2 minutos.** La cota pequeña es una invitación del autor a la exponencial. Una DP que no veo clara tiene riesgo de bugs y de tiempo; la enumeración no tiene ideas que puedan fallar. En una prueba, la versión clara que cabe es la mejor solución, no una solución de segunda.

🔬 **El detalle.** Lo que sí se dice es la cuenta (`2ⁿ · n ≈ 5·10⁵` pasos) y que, si `n` subiera a 40 o a 10⁵, haría falta otra técnica. Es el problema propio «Equipos equilibrados» de esta simulación.

**08 → Problema: Registro de accesos.**

- **Pista 2 — patrón:** **E/S rápida**: son dos millones de números; el cálculo es una suma y un máximo.
- **Pista 3 — diseño:** lee con la plantilla de tu lenguaje (las dos líneas de C++, `BufferedReader` con `StringTokenizer`, o `read().split()`), acumula `salida − entrada` y guarda el máximo; el total cabe en `int` (como mucho `1,44·10⁹`), pero por poco.

**08 → Problema: Área de los terrenos.**

- **Pista 2 — patrón:** **aritmética modular** con productos que no caben en 32 bits.
- **Pista 3 — diseño:** reduce cada lado módulo `10⁹ + 7`, multiplícalos en 64 bits, reduce, y suma al acumulador reduciendo otra vez; el área sin reducir llega a `10¹⁸` y la suma de áreas pasaría de 64 bits.

**08 → Problema: Equipos equilibrados.**

- **Pista 2 — patrón:** **fuerza bruta sobre subconjuntos**: con `n ≤ 15` caben los `2ⁿ` repartos.
- **Pista 3 — diseño:** enumera las máscaras de `1` a `2ⁿ − 2` (los dos equipos no vacíos); para cada una, la suma de un equipo y la diferencia con el total menos esa suma; todo en 64 bits, porque la suma llega a `1,5·10¹⁰`.

**08 → Problema: Missing Number.**

- **Pista 2 — patrón:** **suma conocida** o XOR.
- **Pista 3 — diseño:** la suma de `0` a `n` menos la suma del arreglo; o el XOR de todos los índices y valores, que no desborda.

**08 → Problema: First Unique Character in a String.**

- **Pista 2 — patrón:** **conteo** de frecuencias en dos pasadas.
- **Pista 3 — diseño:** primera pasada, cuenta cada carácter en un arreglo de 26; segunda pasada, devuelve el primer índice cuyo carácter tiene cuenta 1, o `−1`.

**08 → Problema: Birthday Cake Candles.**

- **Pista 2 — patrón:** **máximo y conteo** en un recorrido.
- **Pista 3 — diseño:** lleva el máximo y cuántas veces apareció; si llega uno mayor, el contador vuelve a 1; si llega uno igual, suma.

**08 → Problema: Grading Students.**

- **Pista 2 — patrón:** **simulación** con una regla y una excepción.
- **Pista 3 — diseño:** si la nota es menor que 38, no cambia; si no, calcula el siguiente múltiplo de 5 y redondea solo si la diferencia es menor que 3.

**08 → Problema: Beautiful Matrix.**

- **Pista 2 — patrón:** **distancia de Manhattan** en una cuadrícula.
- **Pista 3 — diseño:** encuentra la fila y la columna del 1; la respuesta es `|fila − 3| + |columna − 3|` con índices desde 1.

**08 → Problema: Sum of Round Numbers.**

- **Pista 2 — patrón:** **descomposición por dígitos**.
- **Pista 3 — diseño:** cada dígito distinto de cero aporta un número redondo: el dígito por la potencia de 10 de su posición; cuenta cuántos hay e imprímelos.
