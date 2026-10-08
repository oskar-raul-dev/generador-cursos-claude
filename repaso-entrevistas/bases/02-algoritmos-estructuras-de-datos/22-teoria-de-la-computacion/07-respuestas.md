# Respuestas — bloque 22: Teoría de la computación

> **Opcional.** Solucionario del bloque `22`, que ningún capítulo del hilo principal necesita: las respuestas
> de las preguntas de cada capítulo en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el
> enunciado copiado literalmente, y las pistas 2 y 3 de los problemas de `22/02` y `22/06`, los únicos del bloque
> que traen problemas. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--lenguajes-y-gramáticas) · [02](#02--autómatas-de-pila) · [03](#03--máquinas-de-turing-y-decidibilidad) · [04](#04--p-np-y-reducciones) · [05](#05--np-completitud) · [06](#06--análisis-léxico-y-gramáticas-simples)

---

# 01 — Lenguajes y gramáticas

**01 → 1.** ¿Qué es un lenguaje formal, y qué diferencia hay entre una gramática y el lenguaje que genera? 🟢

⏱️ **30 segundos.** Un lenguaje formal es un conjunto de cadenas sobre un alfabeto finito. Una gramática es un conjunto finito de reglas que lo genera; el lenguaje es todo lo que esas reglas derivan.

🗣️ **2 minutos.** La gramática es finita y el lenguaje puede ser infinito: `S → ( S ) S | ε` tiene dos producciones y genera infinitas cadenas equilibradas. Un mismo lenguaje tiene muchas gramáticas, y por eso se distingue entre propiedades del lenguaje (ser regular) y de la gramática (ser ambigua).

🔬 **El detalle.** La equivalencia de dos gramáticas libres de contexto (¿generan el mismo lenguaje?) es indecidible; la de dos DFA se decide con el producto de §3.

**01 → 2.** Nombra los cuatro niveles de la jerarquía de Chomsky con la máquina que reconoce cada uno. 🟢

⏱️ **30 segundos.** Tipo 3, regulares, con autómatas finitos; tipo 2, libres de contexto, con autómatas de pila; tipo 1, sensibles al contexto, con autómatas linealmente acotados; tipo 0, recursivamente enumerables, con máquinas de Turing.

🗣️ **2 minutos.** Cada nivel contiene estrictamente al de abajo, y en cada frontera hay un testigo: `aⁿbⁿ` es libre de contexto y no regular; `aⁿbⁿcⁿ` es sensible al contexto y no libre de contexto; el problema de la parada es recursivamente enumerable y no decidible.

🔬 **El detalle.** Los decidibles (recursivos) quedan entre el tipo 1 y el tipo 0: todo sensible al contexto es decidible, pero hay decidibles que no son sensibles al contexto.

**01 → 3.** Enuncia el lema de bombeo para lenguajes regulares. 🟢

⏱️ **30 segundos.** Si `L` es regular, existe `p` tal que toda `w ∈ L` con `|w| ≥ p` se parte en `xyz` con `|xy| ≤ p`, `|y| ≥ 1` y `xyᵏz ∈ L` para todo `k ≥ 0`.

🗣️ **2 minutos.** `p` es el número de estados de un DFA de `L`. Leyendo los primeros `p` símbolos el DFA pasa por `p + 1` estados, y por el palomar alguno se repite: el tramo entre las dos apariciones es `y`, un ciclo que se puede recorrer cualquier número de veces.

🔬 **El detalle.** Se usa en contrapositivo y como juego: el adversario elige `p` y la partición, tú eliges `w` y `k`. Tu elección de `w` es la que deja al adversario sin salida.

**01 → 4.** ¿Por qué los lenguajes regulares son cerrados bajo complemento, y qué tiene que cumplir el DFA para que la construcción funcione? 🟡

⏱️ **30 segundos.** Porque basta con intercambiar estados finales y no finales de un DFA. Funciona solo si el DFA es completo: con transición para todo símbolo en todo estado.

🗣️ **2 minutos.** En un DFA completo cada cadena termina en exactamente un estado, así que «no acaba en un final» es «acaba en un no final». Si falta una transición, la cadena se rechaza por quedarse sin camino, y al intercambiar finales seguiría rechazada: hay que añadir antes un estado sumidero no final que recoja todo lo que falta.

🔬 **El detalle.** Con un NFA no vale: intercambiar finales en un NFA no da el complemento, porque una cadena puede tener caminos que acaban en final y otros que no. Hay que pasar antes a DFA, quizá con explosión exponencial.

**01 → 5.** ¿Qué diferencia hay entre una derivación por la izquierda y un árbol de derivación, y qué significa que una gramática sea ambigua? 🟡

⏱️ **30 segundos.** Una derivación por la izquierda reescribe siempre la variable más a la izquierda; el árbol olvida el orden y guarda solo qué producción se usó en cada nodo. Una gramática es ambigua si alguna cadena tiene dos árboles distintos.

🗣️ **2 minutos.** Cada árbol corresponde a exactamente una derivación por la izquierda, así que «dos árboles» y «dos derivaciones por la izquierda» son lo mismo. Con `E → E + E | E * E | a`, `a + a * a` tiene dos árboles: uno multiplica primero y otro suma primero.

🔬 **El detalle.** Dos derivaciones cualesquiera (no por la izquierda) distintas no prueban ambigüedad: la misma estructura se puede derivar en distinto orden. Por eso se cuenta con árboles o con derivaciones canónicas.

**01 → 6.** ¿Por qué los lenguajes libres de contexto no son cerrados bajo intersección? Da el ejemplo. 🟡

⏱️ **30 segundos.** Porque la intersección de dos libres de contexto puede no serlo: `aⁿbⁿcᵐ ∩ aᵐbⁿcⁿ = aⁿbⁿcⁿ`, que no es libre de contexto.

🗣️ **2 minutos.** Cada uno de los dos es libre de contexto (un autómata de pila compara las `a` con las `b`, o las `b` con las `c`), pero su intersección exige comparar tres cantidades, y una sola pila no puede. Como sí son cerrados bajo unión, tampoco lo son bajo complemento (De Morgan).

🔬 **El detalle.** La intersección de un libre de contexto con un **regular** sí es libre de contexto: el producto de un autómata de pila con un DFA sigue teniendo una sola pila.

**01 → 7.** Demuestra con el lema de bombeo que los paréntesis equilibrados no son un lenguaje regular. 🟠

⏱️ **30 segundos.** Por contradicción con `w = (ᵖ)ᵖ`: como `|xy| ≤ p`, `y` son solo paréntesis abiertos, y con `k = 0` queda una cadena con menos `(` que `)`, que no está en el lenguaje.

🗣️ **2 minutos.** Los pasos: el adversario elige `p`; tú `w = (ᵖ)ᵖ`, que está en `L` y mide `2p`; el adversario parte `w = xyz` con `|xy| ≤ p` y `|y| ≥ 1`, así que `y = (ʲ` con `j ≥ 1`; tú eliges `k = 0` y `xz = (^(p−j) )ᵖ` no está equilibrada. Ningún `p` funciona: no es regular.

🔬 **El detalle.** La elección de `w` es todo: con `w = ()ᵖ` el adversario toma `y = ()` y bombear la deja equilibrada. Hay que elegir una cadena donde los primeros `p` símbolos sean todos del mismo tipo.

**01 → 8.** ¿Por qué la cadena más corta que distingue dos DFA mide menos de `n₁ · n₂`, y qué algoritmo se sigue de eso? 🟠

⏱️ **30 segundos.** Porque si la más corta pasara por un mismo par de estados del producto dos veces, quitar el tramo entre las dos daría otra distintiva más corta. Así que recorre pares distintos: menos de `n₁ · n₂` símbolos. De ahí, un BFS sobre los pares.

🗣️ **2 minutos.** El producto tiene `n₁ · n₂` pares; un camino sin repeticiones visita como mucho todos, con `n₁ · n₂ − 1` transiciones. Eso da dos algoritmos: probar todas las cadenas hasta esa longitud (exponencial pero correcto) y, mejor, el BFS sobre pares desde `(0, 0)` buscando uno con un final en un solo autómata: `O(n₁ · n₂ · σ)`, y la primera que encuentra es la más corta.

🔬 **El detalle.** Una cota más fina, `n₁ + n₂ − 2`, sale de minimizar la unión disjunta de los dos autómatas; el BFS no la necesita, porque visita solo los pares alcanzables.

**01 → 9.** Escribe una gramática no ambigua para las expresiones con `+`, `*`, paréntesis y `a`, con la precedencia habitual. ¿Qué la hace no ambigua? 🟠

⏱️ **30 segundos.** `E → E + T | T`, `T → T * F | F`, `F → ( E ) | a`. No es ambigua porque cada nivel de precedencia es una variable y cada operador está asociado a la izquierda por la recursión.

🗣️ **2 minutos.** `E` suma términos, `T` multiplica factores y `F` son átomos o paréntesis. Un `+` solo puede estar en un nodo `E`, por encima de todos los `*` de sus términos: la multiplicación se agrupa antes. Y `E → E + T` obliga a que el operando derecho sea un término, así que `a + a + a` solo se lee `(a + a) + a`.

🔬 **El detalle.** La prueba de no ambigüedad es por inducción: para cada cadena, el `+` de más a la derecha que no está entre paréntesis es necesariamente el de la raíz, y eso fija el árbol. Para descenso recursivo se quita la recursión por la izquierda (`22/06`).

**01 → 10.** ¿Por qué el cálculo de las anulables por punto fijo termina, y por qué da el menor conjunto y no otro? 🟠

⏱️ **30 segundos.** Termina porque cada vuelta útil añade al menos una variable y solo hay `|V|`. Da el menor conjunto porque empieza en el vacío y solo añade variables con un cuerpo hecho de variables ya justificadas.

🗣️ **2 minutos.** Por inducción sobre las vueltas, todo lo que entra deriva `ε` de verdad. Y al revés, si una variable deriva `ε`, entra en la vuelta igual a la altura de su árbol de derivación de `ε`. Un conjunto «cerrado» más grande, como `{A, B, S, C}` en el ejemplo, se sostiene en un ciclo (`S` necesita a `C` y `C` a `S`) que ninguna derivación finita recorre.

🔬 **El detalle.** Es un punto fijo mínimo en el sentido del teorema de Knaster-Tarski: la operación «añadir lo justificado» es monótona, y su menor punto fijo es la unión de sus iteraciones desde el vacío. El mismo esquema da las variables generadoras y las alcanzables.

**01 → 11.** Un lenguaje cumple el lema de bombeo. ¿Puedes concluir que es regular? Justifica con un ejemplo. 🔴

⏱️ **30 segundos.** No. El lema es necesario, no suficiente: `{aⁱbʲcᵏ : i = 0 o j = k}` lo cumple y no es regular.

🗣️ **2 minutos.** Con `p = 1`, cualquier cadena larga se bombea en su primer símbolo: si empieza por `a`, cambiar cuántas `a` hay mantiene `j = k` (o lleva a `i = 0`, que también vale); si empieza por `b` o `c`, `i = 0` y todo vale. Pero no es regular: su intersección con `ab*c*` es `{abⁿcⁿ}`, que no lo es, y los regulares son cerrados bajo intersección.

🔬 **El detalle.** La caracterización exacta es Myhill-Nerode: `L` es regular si y solo si la relación «`u` y `v` no se distinguen por ningún sufijo» tiene un número finito de clases.

**01 → 12.** ¿Cuántos árboles de derivación tiene `a + a * a + a` con `E → E + E | E * E | a`? Da la fórmula para `k` operadores y de dónde sale. 🔴

⏱️ **30 segundos.** Cinco. Con `k` operadores, el número de Catalan `Cₖ = C(2k, k) / (k + 1)`: 1, 1, 2, 5, 14…

🗣️ **2 minutos.** El operador de la raíz parte la expresión en dos subexpresiones con `i` y `k − 1 − i` operadores, y cada mitad se lee de forma independiente: `Cₖ = Σ Cᵢ · Cₖ₋₁₋ᵢ`, que es la recurrencia de Catalan. Con tres operadores, `C₃ = 5`; con cuatro, 14.

🔬 **El detalle.** Es la misma recurrencia que cuenta árboles binarios de `k` nodos internos y formas de parentizar un producto de `k + 1` factores (`17/05`). CYK contando sobre la gramática en FNC lo confirma (`22/02`).

---

# 02 — Autómatas de pila

**02 → 1.** ¿Qué tres cosas hace una transición de un autómata de pila? 🟢

⏱️ **30 segundos.** Cambia de estado, consume (o no) un símbolo de la entrada y sustituye la cima de la pila por una cadena.

🗣️ **2 minutos.** La transición depende del estado, del símbolo de entrada (o de ninguno, si es ε) y de la cima. Sustituir la cima por la cadena vacía es desapilar; por la misma cima, no tocarla; por una cadena más larga, apilar. Por eso una sola regla basta para las tres operaciones de pila.

🔬 **El detalle.** Un PDA no puede mirar debajo de la cima sin desapilar: es lo que limita su poder a los libres de contexto.

**02 → 2.** ¿Qué forma tienen las producciones en la forma normal de Chomsky? 🟢

⏱️ **30 segundos.** Cada producción es `A → B C`, con dos variables, o `A → a`, con un terminal; además se permite `S → ε` si el lenguaje contiene la vacía.

🗣️ **2 minutos.** En FNC, una cadena de longitud `n` se deriva en `2n − 1` pasos y su árbol es binario. Eso permite partir cualquier subcadena en dos por un punto de corte, que es lo que hace CYK.

🔬 **El detalle.** Para que `S → ε` no interfiera, `S` no puede aparecer en ningún cuerpo; por eso el primer paso de la conversión es la variable inicial nueva.

**02 → 3.** ¿Cuánto cuesta CYK en tiempo y en memoria, y de dónde sale cada factor? 🟢

⏱️ **30 segundos.** `O(n³ · |R|)` en tiempo y `O(n² · |V|)` en memoria: `n²/2` celdas, hasta `n` cortes por celda y `|R|` producciones binarias por corte.

🗣️ **2 minutos.** La tabla tiene una celda por subcadena `[i, j]`. Rellenarla prueba cada corte `k` entre `i` y `j` y cada producción `A → B C`. Cada celda guarda un conjunto de variables: con máscaras de bits, una palabra de 64 bits por celda.

🔬 **El detalle.** El número exacto de ternas `(i, k, j)` es `C(n + 1, 3) ≈ n³/6`. Valiant lo baja a la multiplicación de matrices booleanas, `O(n^2,37…)`, sin interés práctico.

**02 → 4.** ¿Qué diferencia hay entre aceptar por estado final y por pila vacía, y cuándo son equivalentes? 🟡

⏱️ **30 segundos.** Por estado final, acepta si al acabar la entrada está en un estado final; por pila vacía, si la pila queda vacía. En los no deterministas son equivalentes; en los deterministas no.

🗣️ **2 minutos.** De estado final a pila vacía: al llegar a un final se pasa a un estado que vacía la pila. De pila vacía a estado final: se pone un símbolo de fondo nuevo, y cuando vuelve a quedar en la cima se pasa a un final. En los deterministas, aceptar por pila vacía obliga a que ningún prefijo de una palabra aceptada sea también aceptado.

🔬 **El detalle.** Por eso los DPDA se definen casi siempre con estado final: con pila vacía reconocen una clase todavía más pequeña (los lenguajes con la propiedad del prefijo).

**02 → 5.** ¿Por qué `{w c wᴿ}` se reconoce con un autómata de pila determinista y `{w wᴿ}` no? 🟡

⏱️ **30 segundos.** En `w c wᴿ` la `c` marca la mitad: se apila hasta verla y se compara después. En `w wᴿ` no hay marca, y el autómata tiene que adivinar dónde está la mitad: eso es no determinismo.

🗣️ **2 minutos.** Un PDA no determinista prueba todas las mitades a la vez y acepta si alguna funciona. Uno determinista tiene que decidir en cada símbolo si sigue apilando o empieza a comparar, sin ver lo que viene, y no hay forma de hacerlo bien para todas las cadenas.

🔬 **El detalle.** La prueba formal es más delicada que la intuición; el argumento está en Hopcroft, Motwani y Ullman, §6.4.

**02 → 6.** ¿Qué diferencia hay entre CYK y un analizador de descenso recursivo en lo que aceptan y en lo que cuestan? 🟡

⏱️ **30 segundos.** CYK acepta cualquier gramática libre de contexto, incluso ambigua, en `O(n³)`; el descenso recursivo acepta solo gramáticas sin recursión por la izquierda que se deciden con un token, pero en `Θ(n)`.

🗣️ **2 minutos.** CYK es una DP de intervalos que no necesita decidir nada: prueba todos los cortes. El descenso recursivo decide la producción mirando el token siguiente, y por eso es lineal y da buenos mensajes de error, pero exige preparar la gramática.

🔬 **El detalle.** Para un lenguaje de programación con millones de tokens, `n³` es inviable; para una gramática ambigua de reglas de combinación con cadenas de cien símbolos, CYK es lo natural.

**02 → 7.** Compara la plantilla de CYK en C++, Java y Python: ¿qué representa cada celda, y qué cambia en Python cuando la cadena mide 100 símbolos? 🟡

⏱️ **30 segundos.** Una celda es el conjunto de variables que generan esa subcadena: en C++ y Java, una máscara en un entero de 64 bits; en Python, un entero sin límite. Con 100 símbolos, Python hace unos `10⁷` pasos interpretados por cadena y tarda segundos.

🗣️ **2 minutos.** La operación decisiva es «¿`B` está a la izquierda y `C` a la derecha?», un desplazamiento y un `&`. En C++ y Java eso es una instrucción; en Python, varias operaciones del intérprete. `C(101, 3) · 100 ≈ 1,7·10⁷` comprobaciones por cadena caben en una fracción de segundo en C++, y en Python cuestan segundos.

🔬 **El detalle.** En Python se gana agrupando las producciones por `(B, C)` y recorriendo solo los bits encendidos de las dos celdas, o precalculando para cada par de máscaras qué variables producen.

**02 → 8.** ¿Por qué el orden de los bucles de CYK, con la longitud por fuera, es el que garantiza la corrección? 🟠

⏱️ **30 segundos.** Porque `T[i][j]` depende de `T[i][k]` y `T[k+1][j]`, que son subcadenas más cortas; recorriendo por longitudes crecientes, cuando se calcula una celda todas las que necesita ya están completas.

🗣️ **2 minutos.** Es el invariante de la DP de intervalos (`12/05`): al empezar la longitud `ℓ`, todas las celdas de longitud menor tienen su conjunto definitivo. Recorrer por `i` y luego por `j` con `j` creciente también funciona si `i` va de derecha a izquierda; lo que no funciona es un orden que use una celda antes de terminarla.

🔬 **El detalle.** Un orden incorrecto no da error: da conjuntos incompletos, y CYK responde «no» a cadenas que sí están. Es un WA silencioso.

**02 → 9.** ¿Por qué conviene partir los cuerpos largos (BIN) antes de quitar las producciones ε (DEL)? 🟠

⏱️ **30 segundos.** Porque DEL genera, por cada cuerpo con `k` variables anulables, hasta `2ᵏ` versiones; si los cuerpos ya tienen dos símbolos, cada uno da como mucho tres.

🗣️ **2 minutos.** Con BIN primero, un cuerpo de longitud `k` se convierte en `k − 1` producciones binarias, y DEL añade a cada una sus versiones sin el primer símbolo, sin el segundo o sin ninguno (descartando la vacía): crecimiento lineal. Al revés, un cuerpo `A₁ A₂ … Aₖ` con todas anulables da `2ᵏ − 1` cuerpos.

🔬 **El detalle.** UNIT puede seguir siendo cuadrático en el número de variables; el orden INICIO, BIN, DEL, UNIT, TERM deja la gramática en tamaño `O(|G|²)`.

**02 → 10.** Enuncia el teorema que relaciona las gramáticas libres de contexto con los autómatas de pila y esboza la dirección de gramática a autómata. 🟠

⏱️ **30 segundos.** Un lenguaje es libre de contexto si y solo si lo acepta un autómata de pila no determinista. De gramática a autómata: el PDA apila el cuerpo de una producción cuando ve una variable en la cima, y compara con la entrada cuando ve un terminal.

🗣️ **2 minutos.** El autómata tiene un solo estado de trabajo. Empieza con `S` en la pila; si la cima es una variable `A`, elige de forma no determinista una producción `A → α` y sustituye `A` por `α`; si la cima es un terminal igual al siguiente símbolo, lo consume y desapila. Acepta con la pila vacía. Simula una derivación por la izquierda, con la pila como la parte de la forma sentencial que falta por leer.

🔬 **El detalle.** La dirección contraria construye una variable `[p X q]` por cada «el autómata va de `p` a `q` y en el camino desapila `X`», y es la parte larga de la prueba (Hopcroft, Motwani y Ullman, §6.3).

**02 → 11.** Rellena la tabla de CYK de `aabb` con `S → A X | A B`, `X → S B`, `A → a`, `B → b`. 🔴

⏱️ **30 segundos.** Longitud 1: `A A B B`; longitud 2: `-`, `S`, `-`; longitud 3: `-`, `X`; longitud 4: `S`. `S` está en la celda de la cadena entera: la genera.

🗣️ **2 minutos.** Paso a paso: `ab` en las posiciones 1–2 da `S` por `S → A B`. `abb` desde la 1 da `X` por `X → S B` con el corte tras `ab`. `aabb` entera da `S` por `S → A X` con el corte tras la primera `a`. Las demás celdas quedan vacías: `aa`, `bb`, `aab` no las genera ninguna variable.

🔬 **El detalle.** Con `abab` la celda final queda vacía: `ab` genera `S`, pero `S` seguida de `ab` no tiene producción, y ningún corte encaja.

**02 → 12.** Modifica CYK para que cuente cuántos árboles tiene una cadena, y di cuántos tiene `a+a*a` con `E → E + E | E * E | a`. 🔴

⏱️ **30 segundos.** Se cambia el conjunto por un contador por variable y el `|=` por `+= cuenta(B) · cuenta(C)`. Pasando `E → E + E | E * E | a` a FNC, `a+a*a` tiene 2 árboles.

🗣️ **2 minutos.** `cnt[i][j][A] = Σ` sobre producciones `A → B C` y cortes `k` de `cnt[i][k][B] · cnt[k+1][j][C]`, con `cnt[i][i][A] = 1` si `A → w[i]`. En FNC: `E → E P | E M | a`, `P → O E`, `M → T E`, `O → +`, `T → *`. Con tres operadores sale 5, con cuatro 14: Catalan.

🔬 **El detalle.** Contar exige que la conversión a FNC no cree ni destruya árboles: con producciones unitarias o ε que se eliminan, el número de árboles puede cambiar. Con la gramática del ejemplo, que no tiene ninguna, se conserva.

**02 → Problema: ¿Lo genera?.**

**Pista 2:** CYK sobre la gramática dada, que ya está en FNC: una tabla de conjuntos de variables por subcadena.

**Pista 3:** `T[i][j]` = variables que generan `w[i..j]`; `T[i][i]` sale de las reglas `A → a`; para longitudes crecientes, `A ∈ T[i][j]` si hay `A → B C` y un corte `k` con `B ∈ T[i][k]` y `C ∈ T[k+1][j]`. Responde `YES` si `S ∈ T[0][n−1]`. Con 26 variables, una máscara de bits por celda.

**02 → Problema: Cuántas lecturas.**

**Pista 2:** CYK contando: en lugar de un conjunto, un contador por variable y subcadena.

**Pista 3:** `cnt[i][j][A] = Σ cnt[i][k][B] · cnt[k+1][j][C]` sobre las reglas `A → B C` y los cortes `k`, módulo `10⁹ + 7`; `cnt[i][i][A] = 1` por cada regla `A → w[i]`. La respuesta es `cnt[0][n−1][S]`. `O(n³ · r)`.

---

# 03 — Máquinas de Turing y decidibilidad

**03 → 1.** ¿Qué es una configuración de una máquina de Turing? 🟢

⏱️ **30 segundos.** El estado, el contenido de la cinta y la posición de la cabeza. Con eso, el futuro de la máquina queda determinado.

🗣️ **2 minutos.** Una configuración es una fotografía completa: aplicando `δ` se obtiene la siguiente. Una ejecución es una sucesión de configuraciones, y la prueba de Cook-Levin (`22/05`) la escribe como una tabla con una fila por configuración.

🔬 **El detalle.** Como la cinta es infinita, se representa solo la parte no blanca. Con memoria acotada el número de configuraciones es finito, y de ahí sale la decisión por el palomar de §5.

**03 → 2.** ¿Qué diferencia hay entre un lenguaje decidible y uno semidecidible? 🟢

⏱️ **30 segundos.** Decidible: una máquina de Turing lo acepta y para siempre, con sí o con no. Semidecidible: una máquina para y acepta en las cadenas del lenguaje, aunque en las otras pueda no parar.

🗣️ **2 minutos.** La parada es semidecidible: simular y decir sí si termina. No es decidible: no hay forma de decir siempre que no. Un lenguaje es decidible exactamente cuando él y su complemento son semidecidibles: se corren las dos máquinas en paralelo y una de las dos para.

🔬 **El detalle.** Por ese teorema, el complemento de la parada no es ni siquiera semidecidible: si lo fuera, la parada sería decidible.

**03 → 3.** ¿Qué dice la tesis de Church-Turing, y por qué no es un teorema? 🟡

⏱️ **30 segundos.** Que todo lo calculable por un procedimiento efectivo lo calcula una máquina de Turing. No es un teorema porque «procedimiento efectivo» es una noción intuitiva, sin definición formal que demostrar.

🗣️ **2 minutos.** Lo que sí son teoremas son las equivalencias entre modelos concretos: cálculo λ, funciones recursivas, máquinas de varias cintas, máquinas RAM. Todos calculan lo mismo, y eso es la evidencia de la tesis.

🔬 **El detalle.** Sirve para pasar de «ninguna MT lo decide» a «ningún programa lo decide», que es la frase que importa en la práctica. No dice nada de eficiencia más allá de que las simulaciones son polinomiales.

**03 → 4.** ¿Qué diferencia hay entre «indecidible» y «NP-difícil»? 🟡

⏱️ **30 segundos.** Indecidible es que no hay ningún algoritmo que responda bien para todas las entradas. NP-difícil es que hay algoritmo, pero probablemente no polinomial.

🗣️ **2 minutos.** La cobertura de vértices se resuelve siempre, en tiempo exponencial. La parada no se resuelve en general con ningún tiempo. Hay problemas que son las dos cosas (la parada es NP-difícil e indecidible), pero son conceptos de mundos distintos: computabilidad frente a complejidad.

🔬 **El detalle.** Un caso particular de un indecidible puede ser fácil (la parada con memoria acotada), y uno de un NP-difícil también (cobertura en un árbol).

**03 → 5.** ¿Por qué la cinta de un simulador se implementa con dos pilas, y qué cuesta hacerlo con una cadena? 🟡

⏱️ **30 segundos.** Porque la cinta crece por los dos lados: con dos pilas, mover la cabeza es un `push` y un `pop`, `O(1)`. Con una cadena, ir a la izquierda del borde inserta al principio y mueve todo: `O(T²)` en el peor caso.

🗣️ **2 minutos.** La pila izquierda guarda lo que hay a la izquierda de la cabeza con la cima pegada a ella; la derecha, lo de la derecha. Una pila vacía se lee como blanco. Con una cadena y un índice, cada `insert(0, …)` copia la cinta entera, y una máquina que avanza a la izquierda `T` veces suma `1 + 2 + … + T` copias.

🔬 **El detalle.** Un `ArrayDeque` o un arreglo circular que crece por los dos extremos también da `O(1)` amortizado; las dos pilas son lo más corto de escribir.

**03 → 6.** Compara cómo representa la cinta la plantilla en C++, en Java y en Python. ¿Qué evita el `StringBuilder` de Java? 🟡

⏱️ **30 segundos.** C++ usa dos `vector<char>`; Java, dos `StringBuilder`; Python, dos listas. El `StringBuilder` evita el *boxing* de un `ArrayDeque<Character>`, que crearía un objeto por celda.

🗣️ **2 minutos.** Las tres representaciones son pilas con `push` y `pop` al final en `O(1)` amortizado. En Java, `ArrayDeque<Character>` funcionaría, pero cada `char` se envuelve en un `Character`, con más memoria y presión sobre el recolector; `StringBuilder.append`, `charAt` y `setLength` hacen de pila de `char` primitivos.

🔬 **El detalle.** En Python cada elemento de la lista es un objeto de todas formas (una cadena de un carácter, compartida por el intérprete); el coste es la constante, no la complejidad.

**03 → 7.** ¿Por qué el complemento del problema de la parada no es ni siquiera semidecidible? 🟠

⏱️ **30 segundos.** Porque un lenguaje es decidible si él y su complemento son semidecidibles, y la parada es semidecidible pero no decidible. Si el complemento también lo fuera, la parada sería decidible.

🗣️ **2 minutos.** La prueba: con dos máquinas, una que para en las cadenas de `L` y otra que para en las de su complemento, se simulan alternando pasos; una de las dos termina siempre, y se sabe qué responder. Para la parada, la primera existe (simular); si existiera la segunda, tendríamos un decisor, que no existe.

🔬 **El detalle.** En la práctica: se puede confirmar que un programa termina (verlo terminar), pero no hay procedimiento que confirme siempre que no termina.

**03 → 8.** ¿Por qué la parada de una máquina con un registro de 8 bits y `L` instrucciones es decidible, y en cuántos pasos? 🟠

⏱️ **30 segundos.** Porque hay como mucho `256 · L` configuraciones (contador de programa y registro). Una ejecución de más de `256 · L` pasos repitió una, y la máquina es determinista: está en un bucle. Basta con simular `256 · L + 1` pasos.

🗣️ **2 minutos.** El palomar: `256 · L + 1` configuraciones visitadas no pueden ser todas distintas. Al repetirse una, todo lo que viene después se repite. Por eso la simulación con ese límite decide la parada en `O(256 · L)` tiempo y `O(1)` memoria, y no se equivoca ni con el programa que parece infinito y para por desbordamiento.

🔬 **El detalle.** No contradice a Turing: su teorema habla de memoria sin límite. Con `b` bits de memoria, la cota es `2^b` multiplicado por el tamaño del programa, y en un ordenador real eso no sirve de nada.

**03 → 9.** Reduce el problema de la parada a «¿imprime este programa la palabra `hola`?». 🟠

⏱️ **30 segundos.** Dados `P` y `x`, se construye `P'` que ignora su entrada, ejecuta `P(x)` y después imprime `hola`. `P'` imprime `hola` si y solo si `P` para con `x`.

🗣️ **2 minutos.** Si existiera un decisor de «¿imprime `hola`?», aplicado a `P'` decidiría la parada. Un detalle: `P` podría imprimir `hola` por su cuenta; para evitarlo, `P'` ejecuta `P` con la salida desviada a ningún sitio. La transformación de `(P, x)` en `P'` es computable: es escribir un programa.

🔬 **El detalle.** Es el patrón de casi todas las pruebas de indecidibilidad: «primero simula `P(x)`, y después haz lo que la propiedad pide».

**03 → 10.** ¿Qué dice el teorema de Rice? Da una propiedad de programas que es decidible y otra que no. 🟠

⏱️ **30 segundos.** Toda propiedad no trivial y semántica de los programas es indecidible. «¿El código tiene más de diez líneas?» es decidible (sintáctica); «¿la función devuelve siempre un número positivo?» no (semántica).

🗣️ **2 minutos.** No trivial: la cumplen algunos programas y otros no. Semántica: depende solo de lo que calcula el programa, no de cómo está escrito. «¿Usa la variable `x`?» o «¿tiene un bucle `while`?» son sintácticas y un *linter* las comprueba; «¿termina siempre?», «¿calcula lo mismo que este otro?», «¿puede lanzar esta excepción?» son semánticas.

🔬 **El detalle.** Las herramientas de análisis estático viven en ese hueco: responden aproximaciones conservadoras de propiedades semánticas, con falsos positivos o con casos que callan.

**03 → 11.** Escribe la prueba de que el problema de la parada es indecidible, con el programa diagonal. 🔴

⏱️ **30 segundos.** Supón `halts(P, x)`. Construye `diagonal(P)`: si `halts(P, P)` es verdadero, entra en un bucle infinito; si no, termina. Con `diagonal(d)`, `halts` se equivoca en los dos casos: no existe.

🗣️ **2 minutos.** Si `halts(d, d)` dice «para», `diagonal(d)` entra en el bucle y no para: `halts` mintió. Si dice «no para», `diagonal(d)` termina: mintió otra vez. Como `halts` era arbitraria, ningún programa decide la parada. Es diagonalización: `diagonal` difiere de cada programa `P` en su comportamiento sobre la entrada `P`.

🔬 **El detalle.** Hace falta que los programas puedan recibir su propio código como entrada, que es la máquina universal: cualquier lenguaje con un intérprete de sí mismo lo cumple.

**03 → 12.** Diseña una máquina de Turing que reconozca `{aⁿbⁿ : n ≥ 0}` y di cuántos pasos da con `aⁿbⁿ`, en orden de magnitud. 🔴

⏱️ **30 segundos.** Marcar la primera `a` como `X`, ir a la derecha hasta la primera `b`, marcarla como `Y`, volver, y repetir; acepta si se acaban las `a` y las `b` a la vez. Hace `Θ(n²)` pasos con `aⁿbⁿ`.

🗣️ **2 minutos.** Estados: `q₀` busca una `a` (si ve `Y` o blanco, pasa a comprobar); `q₁` va a la derecha saltando `a` e `Y` hasta una `b`, que marca; `q₂` vuelve a la izquierda hasta la `X`; `q₃` comprueba que solo quedan `Y` y acepta en el blanco. Cada vuelta cuesta `O(n)` pasos y hay `n` vueltas.

🔬 **El detalle.** Una MT de una cinta no puede hacerlo mejor que `Θ(n log n)` para este lenguaje, y para los palíndromos necesita `Θ(n²)`: el modelo es lento, y por eso la complejidad se mide hasta un polinomio, no exactamente.

**03 → 13.** Un compañero propone rechazar en el *pipeline* todo cambio con un bucle infinito. ¿Qué le respondes, qué ofreces en su lugar y qué error comete cada alternativa? 🔴

⏱️ **30 segundos.** Que es el problema de la parada: no se puede decidir para todo programa. Ofrezco un límite de tiempo en las pruebas y un análisis estático que avisa de los bucles evidentes; el primero da falsos positivos con lo lento, el segundo se calla casos reales.

🗣️ **2 minutos.** El límite de tiempo declara colgado a todo lo que tarda más que el umbral, aunque termine (el programa C de §5 con un umbral de 500 pasos). El análisis estático encuentra `while (true)` sin `break` o bucles cuya variable no cambia, pero no puede detectar todos los bucles infinitos sin rechazar programas correctos. Combinados, cubren lo práctico.

🔬 **El detalle.** Si el sistema es de estado finito y pequeño (una máquina de estados del negocio, un autómata de protocolo), entonces sí se decide: explorando sus configuraciones. Es la base de la verificación de modelos.

---

# 04 — P, NP y reducciones

**04 → 1.** ¿Qué es un problema de decisión, y cómo se obtiene el óptimo a partir de su versión de decisión? 🟢

⏱️ **30 segundos.** Un problema cuya respuesta es sí o no. El óptimo se obtiene con una búsqueda binaria sobre el umbral `k` de la versión de decisión, y la solución misma, quitando elementos y volviendo a preguntar.

🗣️ **2 minutos.** «¿Hay una cobertura de tamaño `≤ k`?» se pregunta `O(log n)` veces para encontrar el mínimo. Para la cobertura misma: se prueba a quitar cada vértice y a forzarlo, preguntando si sigue existiendo una de tamaño `k`. Es la autorreducibilidad, y dice que la versión de decisión no es más fácil que la de optimización salvo un factor polinomial.

🔬 **El detalle.** Por eso la teoría se hace con decisiones: es más limpia, y no pierde nada para los problemas NP-completos clásicos.

**04 → 2.** Define NP con certificados. ¿Qué significan las siglas? 🟢

⏱️ **30 segundos.** Los problemas de decisión con un verificador polinomial: si la respuesta es sí, existe un certificado de tamaño polinomial que el verificador acepta. NP es *nondeterministic polynomial*.

🗣️ **2 minutos.** Para la cobertura, el certificado es el conjunto y el verificador comprueba su tamaño y cada arista. Equivale a decir que una máquina de Turing no determinista lo resuelve en tiempo polinomial: adivina el certificado y lo verifica.

🔬 **El detalle.** El certificado solo se pide para el «sí». Para el «no» haría falta otro tipo de certificado, y esa es la clase co-NP.

**04 → 3.** ¿Qué diferencia hay entre NP-difícil y NP-completo? 🟢

⏱️ **30 segundos.** NP-difícil: todo problema de NP se reduce a él. NP-completo: NP-difícil y además en NP.

🗣️ **2 minutos.** Un NP-completo es de los más difíciles **dentro** de NP. Un NP-difícil puede estar fuera de NP: la versión de optimización de la cobertura (no es de decisión) o la parada (ni siquiera decidible).

🔬 **El detalle.** Para demostrar que algo es NP-completo hacen falta las dos partes: la reducción y el certificado.

**04 → 4.** ¿Por qué P ⊆ NP, y por qué NP ⊆ EXP? 🟡

⏱️ **30 segundos.** P ⊆ NP porque un problema de P se verifica resolviéndolo, sin certificado. NP ⊆ EXP porque se pueden probar todos los certificados, que miden `p(n)` bits: `2^p(n)` verificaciones.

🗣️ **2 minutos.** La segunda inclusión da el algoritmo exponencial obvio de todo NP-completo: fuerza bruta sobre el certificado. La pregunta abierta es si la primera inclusión es estricta (P ≠ NP). Se sabe que P ≠ EXP (teorema de la jerarquía de tiempo), así que alguna de las dos inclusiones es estricta.

🔬 **El detalle.** Si P = NP, encontrar sería tan fácil como verificar: buscar una demostración matemática sería tan fácil como comprobarla.

**04 → 5.** Si `A ≤ₚ B`, ¿qué se deduce si `B ∈ P`? ¿Y si `A` es NP-difícil? 🟡

⏱️ **30 segundos.** Si `B ∈ P`, entonces `A ∈ P`. Si `A` es NP-difícil, entonces `B` también lo es.

🗣️ **2 minutos.** Con `A ≤ₚ B` mediante `f`: para resolver `A`, se calcula `f(x)` y se resuelve `B`. Las dos cosas son polinomiales, y la composición también. Al revés, si todo NP se reduce a `A`, y `A` a `B`, todo NP se reduce a `B` (transitividad).

🔬 **El detalle.** Lo que no se deduce es nada sobre `A` a partir de que `B` sea difícil: reducir a un problema difícil no dice que el tuyo lo sea.

**04 → 6.** Compara el verificador de cobertura en C++, Java y Python: ¿qué estructura marca los vértices del certificado en cada uno y cuánta memoria usa? 🟡

⏱️ **30 segundos.** Un `vector<bool>` en C++, un `boolean[]` en Java y una lista en Python. `vector<bool>` empaqueta un bit por vértice; `boolean[]` usa un byte; la lista de Python, un puntero de 8 bytes por posición a un objeto `bool` compartido.

🗣️ **2 minutos.** El algoritmo es idéntico: marcar los vértices del certificado y recorrer las aristas. Lo que cambia es la memoria por vértice: `n/8` bytes, `n` bytes y `8n` bytes. Para un verificador eso rara vez importa; en una DP sobre muchas marcas, sí.

🔬 **El detalle.** `vector<bool>` no es un contenedor normal: sus elementos no son direccionables (`&v[i]` no compila), por eso algunas guías prefieren `vector<char>`.

**04 → 7.** ¿Por qué 2-SAT está en P y 3-SAT no se sabe? ¿Qué se rompe al pasar a tres literales? 🟠

⏱️ **30 segundos.** Porque una cláusula de dos literales es una implicación entre literales, y el grafo de implicaciones lo resuelve con componentes fuertes en lineal. Con tres, `¬a → (b ∨ c)` tiene una disyunción a la derecha: ya no es una arista.

🗣️ **2 minutos.** En 2-SAT, la fórmula es insatisfacible si y solo si `x` y `¬x` están en la misma componente fuerte para alguna variable; y si no lo están, el orden topológico de las componentes da la asignación (`14/05`). En 3-SAT, falsificar un literal deja dos opciones abiertas, y esas ramas se multiplican.

🔬 **El detalle.** 3-SAT es NP-completo (`22/05`), así que si fuera polinomial, P = NP. Que no se sepa resolver no está demostrado: es la conjetura P ≠ NP.

**04 → 8.** Demuestra que `S` es un conjunto independiente de `G` si y solo si `V − S` es una cobertura de vértices. 🟠

⏱️ **30 segundos.** Si `S` es independiente, ninguna arista tiene sus dos extremos en `S`, así que toda arista tiene al menos uno en `V − S`: cobertura. Y al revés: si `V − S` cubre toda arista, ninguna arista tiene los dos extremos en `S`.

🗣️ **2 minutos.** La prueba es una doble negación sobre cada arista `(u, v)`: «no están los dos en `S`» es lo mismo que «alguno está en `V − S`». Por eso `|independiente máximo| + |cobertura mínima| = n` en todo grafo, y en G, `3 + 3 = 6`.

🔬 **El detalle.** La relación con la clique es el complemento del grafo: `S` es independiente en `G` si y solo si es clique en `Ḡ`.

**04 → 9.** ¿Por qué el árbol de búsqueda acotado para la cobertura de vértices no contradice que el problema sea NP-completo? 🟠

⏱️ **30 segundos.** Porque `O(2ᵏ · m)` es exponencial en `k`, y la NP-completitud habla del caso con `k` arbitrario. Con `k` proporcional a `n`, vuelve a ser exponencial en `n`.

🗣️ **2 minutos.** El algoritmo es eficiente cuando el parámetro es pequeño: con `k = 20` y un millón de aristas, `10¹²` es demasiado, pero con `k = 10`, `10⁹`, y con reglas de reducción mucho menos. Es la idea de la complejidad parametrizada: confinar la explosión a un parámetro.

🔬 **El detalle.** La clique, en cambio, no se cree parametrizable de esta forma (es W[1]-difícil): no se espera un `f(k) · nᶜ`.

**04 → 10.** Un compañero dice «reduje mi problema a SAT, así que es NP-difícil». ¿Qué está mal? 🟠

⏱️ **30 segundos.** Que la dirección está al revés: reducir tu problema a SAT dice que tu problema no es más difícil que SAT. Para demostrar que es NP-difícil hay que reducir SAT (o otro NP-completo) a tu problema.

🗣️ **2 minutos.** `A ≤ₚ SAT` dice «si SAT fuera fácil, `A` también». Eso lo cumple cualquier problema de NP, incluidos los de P: ordenar se puede reducir a SAT, y ordenar es fácil. La dificultad viaja en la dirección de la reducción: de lo difícil conocido hacia lo nuevo.

🔬 **El detalle.** Lo que sí prueba su reducción es que su problema está en NP (o, en la práctica, que se puede resolver con un resolvedor SAT).

**04 → 11.** ¿Por qué la parada es NP-difícil pero no NP-completa? 🟠

⏱️ **30 segundos.** Porque todo NP se reduce a ella (es NP-difícil), pero no está en NP: ni siquiera es decidible, y todo problema de NP es decidible.

🗣️ **2 minutos.** Reducción de SAT a la parada: dada una fórmula, construir un programa que prueba todas las asignaciones y termina si alguna la satisface, y si no entra en un bucle. Para que esté en NP haría falta un verificador polinomial, y un problema indecidible no tiene ningún algoritmo.

🔬 **El detalle.** Es el ejemplo estándar de que NP-difícil no implica estar en NP.

**04 → 12.** Traza el árbol de búsqueda acotado sobre G con `k = 3`, eligiendo siempre la primera arista sin cubrir en el orden `A-B, A-C, B-D, B-E, C-E, D-F, E-F`. ¿Cuántos nodos visita? 🔴

⏱️ **30 segundos.** Ocho nodos: la raíz; `A`; con `{A, B}` las ramas `C` y `E` fallan; con `{A, D}`, la primera arista abierta es `B-E`; `B` falla y `E` cubre todo: `{A, D, E}`.

🗣️ **2 minutos.** Desde la raíz, la primera arista sin cubrir es `A-B`: se prueba `A`. Con `{A}`, la primera abierta es `B-D`: se prueba `B`, y con `{A, B}` queda `C-E`, pero con `k = 1` ni `C` ni `E` cubren también `D-F`: fallan. Se vuelve y se prueba `D`: con `{A, D}` la primera abierta es `B-E`; `{A, D, B}` deja `C-E` sin cubrir, `{A, D, E}` cubre las siete.

🔬 **El detalle.** Los nodos: raíz, `{A}`, `{A, B}`, `{A, B, C}`, `{A, B, E}`, `{A, D}`, `{A, D, B}`, `{A, D, E}`. La ingenua probaba hasta 20 subconjuntos de tamaño 3.

**04 → 13.** Te piden la menor cantidad de cámaras para 10⁵ cruces de una ciudad cuyo plano es un árbol, y después para una con ciclos. ¿Qué respondes en cada caso? 🔴

⏱️ **30 segundos.** Para el árbol, una DP lineal da el óptimo exacto. Para el plano con ciclos, el problema es NP-completo: si el número de cámaras es pequeño, el árbol de búsqueda acotado; si no, la 2-aproximación con emparejamiento maximal o una heurística, diciendo qué se garantiza.

🗣️ **2 minutos.** En el árbol, `dp[v][0/1]` (con o sin cámara en `v`) se calcula en postorden: `Θ(n)` con `10⁵` nodos (`13/03`). Con ciclos, si el grafo es bipartito, König da el óptimo en polinomial (`15/06`); si no, y la respuesta es de miles, no hay exacto razonable: un emparejamiento maximal da una cobertura a lo sumo el doble del óptimo en lineal, y una búsqueda local la mejora.

🔬 **El detalle.** La respuesta buena incluye las preguntas: ¿es bipartito?, ¿cuántas cámaras se esperan?, ¿vale el doble del óptimo? Cada respuesta cambia el algoritmo.

---

# 05 — NP-completitud

**05 → 1.** Enuncia el teorema de Cook-Levin. 🟢

⏱️ **30 segundos.** SAT es NP-completo: toda pregunta de NP se transforma en tiempo polinomial en una fórmula que es satisfacible si y solo si la respuesta es sí.

🗣️ **2 minutos.** La fórmula describe con variables booleanas una tabla de `p(n) × p(n)` que es la ejecución de una máquina de Turing no determinista que acepta. Cuatro familias de cláusulas fuerzan que cada celda tenga un símbolo, que la primera fila sea la entrada, que cada paso sea legal y que se acepte.

🔬 **El detalle.** Es el único NP-completo que se prueba desde la definición. Cook (1971) y Levin (1973) lo publicaron por separado.

**05 → 2.** ¿Qué dos cosas hay que demostrar para que un problema sea NP-completo? 🟢

⏱️ **30 segundos.** Que está en NP (un certificado y un verificador polinomial) y que es NP-difícil (una reducción polinomial desde un NP-completo conocido hacia él).

🗣️ **2 minutos.** La reducción tiene tres piezas: la transformación polinomial, y las dos direcciones de la prueba (una solución de lo conocido da una del nuevo, y al revés). Olvidar una dirección es el error más común: la reducción puede crear soluciones que no corresponden a ninguna del original.

🔬 **El detalle.** Si solo se hace la reducción, se ha demostrado NP-difícil, que puede ser más que NP-completo.

**05 → 3.** ¿Qué diferencia hay entre NP-completo en sentido débil y en sentido fuerte? Da un ejemplo de cada uno. 🟡

⏱️ **30 segundos.** Débil: hay un algoritmo pseudo-polinomial, polinomial en el valor de los números, como la suma de subconjuntos. Fuerte: sigue siendo NP-completo con números pequeños, como 3-partición o el empaquetado.

🗣️ **2 minutos.** La suma de subconjuntos tiene la DP `O(n · S)`: con `S` acotado por un polinomio en `n`, es polinomial. 3-partición (partir `3m` números en `m` tríos de igual suma) es NP-completo aunque los números estén escritos en unario, así que no admite un algoritmo pseudo-polinomial salvo que P = NP.

🔬 **El detalle.** La diferencia importa en la práctica: ante un problema de números, mirar si los valores son pequeños decide si hay DP.

**05 → 4.** ¿Por qué la DP de la suma de subconjuntos no demuestra P = NP? 🟡

⏱️ **30 segundos.** Porque `O(n · S)` es polinomial en el valor de `S` pero exponencial en su número de bits, y el tamaño de la entrada se mide en bits.

🗣️ **2 minutos.** `S` se escribe con unos `log₂ S` bits, así que `S = 2^(log S)`: con números de 60 bits, `S ≈ 10¹⁸` y la DP es inviable. Un algoritmo polinomial de verdad tendría que ser polinomial en `n · log S`.

🔬 **El detalle.** Por eso las restricciones de un problema de mochila deciden la técnica: `S ≤ 10⁵`, DP; `S ≤ 10¹⁸` y `n ≤ 40`, *meet in the middle*.

**05 → 5.** Compara la plantilla del ciclo hamiltoniano en C++, Java y Python: ¿hasta qué `n` llega cada una y qué la limita? 🟡

⏱️ **30 segundos.** Las tres guardan `2ⁿ` enteros de 32 bits: C++ y Java llegan a `n ≈ 24` (64 MB); Python, a `n ≈ 18`, porque lo limita el tiempo del intérprete y cada entero de la lista es un objeto.

🗣️ **2 minutos.** El trabajo es `2ⁿ · n` operaciones de bits. En C++ y Java, `2²⁴ · 24 ≈ 4·10⁸` operaciones sencillas caben en un par de segundos y `2²⁴` enteros en 64 MB. En Python, `2¹⁸ · 18 ≈ 4,7·10⁶` iteraciones interpretadas ya cuestan segundos, y la lista de `2²⁴` objetos pesaría cientos de megabytes.

🔬 **El detalle.** En Python se puede ganar algo con `array('I')` para la memoria; el tiempo solo baja vectorizando, que con esta DP no es natural.

**05 → 6.** ¿Qué es la «ventana» en la prueba de Cook-Levin y por qué basta con restricciones locales? 🟠

⏱️ **30 segundos.** Una ventana es un rectángulo de 2 × 3 celdas de la tabla de la ejecución. Basta con restricciones locales porque un paso de máquina de Turing solo cambia la celda bajo la cabeza y sus vecinas.

🗣️ **2 minutos.** Si todas las ventanas son legales (compatibles con `δ`), cada fila sigue correctamente de la anterior. El número de ventanas legales es una constante que depende de la máquina, no de la entrada, así que cada ventana se expresa con un número constante de cláusulas, y la fórmula tiene `O(p(n)²)` cláusulas.

🔬 **El detalle.** Es la misma idea que hace que la vida de Conway o cualquier autómata celular se pueda describir con reglas locales.

**05 → 7.** ¿Cómo se parte una cláusula de cinco literales en cláusulas de tres? ¿Por qué se conserva la satisfacibilidad? 🟠

⏱️ **30 segundos.** Con dos variables nuevas: `(l₁ ∨ l₂ ∨ y₁) ∧ (¬y₁ ∨ l₃ ∨ y₂) ∧ (¬y₂ ∨ l₄ ∨ l₅)`. Si un `lᵢ` es verdadero, se eligen los `y` para satisfacer las demás; si ninguno lo es, la cadena de `y` no se puede cerrar.

🗣️ **2 minutos.** Dirección uno: si `l₃` es verdadero, `y₁ = V` satisface la primera, `y₂ = F` la tercera, y la segunda ya está. Dirección dos: si todos los `lᵢ` son falsos, la primera obliga a `y₁ = V`, la segunda a `y₂ = V`, y la tercera queda falsa: insatisfacible. En general, `k − 2` cláusulas y `k − 3` variables nuevas.

🔬 **El detalle.** Las cláusulas de uno o dos literales se rellenan repitiendo un literal (`(a ∨ b) → (a ∨ b ∨ b)`).

**05 → 8.** Demuestra las dos direcciones de la reducción de 3-SAT a conjunto independiente. 🟠

⏱️ **30 segundos.** Si `φ` se satisface, se toma un literal verdadero por cláusula: uno por triángulo y nunca `x` y `¬x`, así que es independiente de tamaño `m`. Si hay un independiente de tamaño `m`, tiene un vértice por triángulo, y sus literales no se contradicen: hacerlos verdaderos satisface `φ`.

🗣️ **2 minutos.** La primera dirección usa que los literales elegidos son todos verdaderos en la misma asignación, así que no hay `x` y `¬x` entre ellos: ninguna arista de conflicto. La segunda, que un independiente no puede tener dos vértices del mismo triángulo, así que tamaño `m` es exactamente uno por cláusula; las variables que no aparecen se asignan como sea.

🔬 **El detalle.** La reducción es de Karp (1972), y produce `3m` vértices y `O(m²)` aristas: polinomial.

**05 → 9.** ¿Por qué la DP del ciclo hamiltoniano guarda un conjunto de finales por máscara, y qué ganas frente a un booleano por par? 🟠

⏱️ **30 segundos.** Porque así cada máscara se calcula con `n` operaciones `&` (¿llega a `w` desde algún vecino?), en lugar de `n²` (cada par final anterior, final nuevo). Se pasa de `O(2ⁿ · n²)` a `O(2ⁿ · n)`.

🗣️ **2 minutos.** Con un booleano por par `(máscara, v)`, para saber si `w` es final de `mask` hay que mirar cada `v` de `mask − {w}`. Con el conjunto de finales como máscara, esa pregunta es un `&` con los vecinos de `w`: un solo ciclo de máquina.

🔬 **El detalle.** Es el mismo truco de paralelismo de bits que `bitset` en `17/01`. Con pesos (el viajante) no sirve, porque hay que minimizar y no solo saber si existe.

**05 → 10.** Enumera las seis respuestas posibles ante un problema NP-difícil, con un ejemplo de cada una. 🟠

⏱️ **30 segundos.** Exacto exponencial (DP de máscaras), parametrizado (cobertura con `k`), estructura especial (DP en árboles), aproximación con garantía (2-aproximación de la cobertura), heurística (recocido) y resolvedor externo (SAT o programación lineal entera).

🗣️ **2 minutos.** Cada una cede algo: las dos primeras, tiempo exponencial (pequeño o en un parámetro); la tercera, generalidad; la cuarta, exactitud con garantía; la quinta, toda garantía; la sexta, control sobre el tiempo. Elegir depende de las restricciones: `n ≤ 20`, parámetro pequeño, forma de la entrada, tolerancia al error.

🔬 **El detalle.** En un juez casi siempre es la primera o la tercera, a propósito; en producción, la sexta es la más infravalorada.

**05 → 11.** Construye el grafo de la reducción para `φ = (x₁ ∨ x₂ ∨ ¬x₃) ∧ (¬x₁ ∨ x₂ ∨ x₃) ∧ (¬x₂ ∨ ¬x₃ ∨ x₁)` y da un independiente de tamaño 3 con su asignación. 🔴

⏱️ **30 segundos.** Nueve vértices en tres triángulos y seis aristas de conflicto, quince en total. Un independiente: `x₁` de la primera, `x₂` de la segunda y `¬x₃` de la tercera, que corresponde a `x₁ = V`, `x₂ = V`, `x₃ = F`.

🗣️ **2 minutos.** Conflictos: `x₁(1)–¬x₁(2)`, `¬x₃(1)–x₃(2)`, `x₂(1)–¬x₂(3)`, `¬x₁(2)–x₁(3)`, `x₂(2)–¬x₂(3)`, `x₃(2)–¬x₃(3)`. Los tres elegidos no comparten triángulo ni son complementarios. Con esa asignación: la primera cláusula por `x₁`, la segunda por `x₂`, la tercera por `¬x₃`.

🔬 **El detalle.** La fórmula tiene cinco asignaciones que la satisfacen y el grafo, doce independientes de tamaño 3: varios independientes dan la misma asignación, porque una cláusula puede tener más de un literal verdadero.

**05 → 12.** Te piden la ruta óptima por 18 almacenes y después por 300. ¿Qué entregas en cada caso y qué garantizas? 🔴

⏱️ **30 segundos.** Con 18, la DP de máscaras da la ruta óptima exacta en `2¹⁸ · 18²` pasos, en milisegundos. Con 300, una heurística (2-opt, recocido) o, si las distancias son métricas, una aproximación con garantía; prometo una ruta buena y su cota, no el óptimo.

🗣️ **2 minutos.** Con 18: Held-Karp (`13/01`), `O(2ⁿ · n²)`, unos `8,5·10⁷` pasos. Con 300 no hay exacto general; Christofides garantiza a lo sumo 1,5 veces el óptimo si hay desigualdad triangular, y una búsqueda local parte de ahí y suele quedarse a pocos puntos del óptimo. Si de verdad hace falta el óptimo, un resolvedor de programación lineal entera lo encuentra en muchas instancias de ese tamaño, sin garantía de tiempo.

🔬 **El detalle.** La respuesta incluye medir: dar la longitud de la ruta y una cota inferior (por ejemplo, el árbol de expansión mínima) dice cuán lejos del óptimo se puede estar.

---

# 06 — Análisis léxico y gramáticas simples

**06 → 1.** ¿Qué diferencia hay entre token, lexema y patrón? 🟢

⏱️ **30 segundos.** El token es la categoría (número, identificador); el lexema, el texto concreto (`42`); el patrón, la expresión regular que describe los lexemas de un token (`[0-9]+`).

🗣️ **2 minutos.** El lexer lee lexemas y emite tokens, normalmente con el lexema y la posición. El parser solo mira la categoría para decidir; el lexema importa al evaluar (el valor del número, el nombre de la variable).

🔬 **El detalle.** Las palabras reservadas son lexemas con su propio token aunque encajen en el patrón de identificador: lo resuelve la regla de prioridad, o una tabla consultada después.

**06 → 2.** ¿Qué es la coincidencia más larga y qué regla desempata cuando dos patrones dan el mismo lexema? 🟢

⏱️ **30 segundos.** Entre todos los prefijos que encajan con algún patrón, se toma el más largo. Si dos patrones dan el mismo lexema más largo, gana el de mayor prioridad, normalmente el primero de la lista.

🗣️ **2 minutos.** La coincidencia más larga hace que `<=` sea un token y `precio2` un identificador. La prioridad, que `let` sea palabra reservada aunque también encaje como identificador. Con las dos reglas, el lexer no es ambiguo.

🔬 **El detalle.** En un DFA del lexer, la coincidencia más larga se implementa recordando el último estado final pasado y retrocediendo hasta él cuando no hay transición.

**06 → 3.** ¿Por qué el análisis léxico es regular y el sintáctico no? 🟢

⏱️ **30 segundos.** Porque los tokens no se anidan: son patrones regulares, y un DFA los reconoce. La sintaxis sí se anida (paréntesis, bloques), y eso exige una gramática libre de contexto.

🗣️ **2 minutos.** Separar las dos fases es una decisión de diseño que aprovecha la jerarquía: la parte regular se hace con la máquina más simple y rápida, y el parser trabaja con una secuencia de tokens mucho más corta que la de caracteres, sin preocuparse de blancos ni comentarios.

🔬 **El detalle.** Hay lenguajes donde la separación se complica (el `>>` de las plantillas de C++, los lexers que dependen del contexto), y se resuelve con un lexer que el parser informa.

**06 → 4.** ¿Por qué la recursión por la izquierda impide el descenso recursivo, y cómo se elimina? 🟡

⏱️ **30 segundos.** Porque `expr()` empezaría llamándose a sí misma sin consumir ningún token: recursión infinita. Se elimina reescribiendo `A → A α | β` como `A → β {α}`, un bucle.

🗣️ **2 minutos.** La función de `E → E + T` tendría que llamar a `E` antes de mirar nada, y la nueva llamada haría lo mismo. La reescritura genera el mismo lenguaje (`β α α … α`) y se programa como «lee un `β` y, mientras veas el inicio de `α`, lee un `α`».

🔬 **El detalle.** La recursión por la izquierda indirecta (`A → B x`, `B → A y`) se elimina igual tras sustituir; los generadores LL lo hacen automáticamente.

**06 → 5.** ¿Dónde vive la precedencia de los operadores en un parser de descenso recursivo? 🟡

⏱️ **30 segundos.** En quién llama a quién: la función del operador de menor precedencia llama a la del siguiente nivel, y lo que está más abajo en la cadena se agrupa antes.

🗣️ **2 minutos.** `expr` (suma y resta) llama a `term` (producto y división), que llama a `unary`, que llama a `power`. Así, en `2 + 3 * 4`, `term` consume `3 * 4` entero antes de que `expr` vea el `+` siguiente. Añadir un nivel es añadir una función entre dos.

🔬 **El detalle.** Con muchos niveles (C tiene quince), el algoritmo de Pratt sustituye la cadena de funciones por una tabla de precedencias y una sola función.

**06 → 6.** ¿Qué diferencia hay entre resolver la asociatividad con un bucle y con recursión? Da un operador de cada tipo. 🟡

⏱️ **30 segundos.** Con un bucle que acumula de izquierda a derecha, el operador es asociativo por la izquierda, como la resta; con una llamada recursiva al mismo nivel por la derecha, asociativo por la derecha, como la potencia.

🗣️ **2 minutos.** `10 - 2 - 3`: el bucle de `expr` calcula `10 - 2 = 8` y luego `8 - 3 = 5`. `2 ^ 3 ^ 2`: `power` lee el `2`, ve `^` y llama a `unary`, que vuelve a `power` y calcula `3 ^ 2 = 9` primero: `2 ^ 9 = 512`.

🔬 **El detalle.** La asignación `a = b = c` es el otro ejemplo clásico de asociatividad por la derecha.

**06 → 7.** ¿Cuánto vale `-7 / 2` en C++, Java y Python con `//`, y qué hace la plantilla de Python para dar lo mismo que las otras dos? 🟡

⏱️ **30 segundos.** En C++ y Java, `-3`; en Python, `-7 // 2` es `-4`. La plantilla de Python divide los valores absolutos y pone el signo a mano.

🗣️ **2 minutos.** C++ (desde C++11) y Java truncan hacia cero; `//` de Python redondea hacia menos infinito, que es lo que hace que `a == (a // b) * b + a % b` se cumpla con un `%` siempre del signo de `b`. Para que el evaluador dé lo mismo en los tres, Python calcula `abs(v) // abs(d)` y niega si los signos difieren.

🔬 **El detalle.** `int(v / d)` también trunca, pero pasa por `float` y pierde precisión con enteros grandes: no sirve con 64 bits.

**06 → 8.** ¿Cuánto vale `-3 ^ 2` con la gramática de §4, y qué cambio de la gramática daría `9`? 🟠

⏱️ **30 segundos.** `-9`, porque `^` liga más fuerte que el menos unario: `-(3 ^ 2)`. Para obtener `9`, el menos unario tendría que estar por debajo de la potencia: `power → unary [ '^' power ]` y `unary → '-' unary | atom`.

🗣️ **2 minutos.** Con la gramática de §4, `unary` ve el `-` y llama a `unary`, que llama a `power`, que consume `3 ^ 2`. Si se intercambian los niveles, `power` empieza por `unary`, que consume `-3` como átomo con signo, y luego eleva: `(-3) ^ 2 = 9`.

🔬 **El detalle.** La convención matemática, y Python con `**`, dan `-9`; Excel da `9`. Es una decisión de diseño que hay que documentar.

**06 → 9.** ¿Por qué el descenso recursivo de §5 es lineal en el número de tokens? 🟠

⏱️ **30 segundos.** Porque cada token se consume exactamente una vez, y entre dos consumos cada función hace un trabajo constante; el número de llamadas está acotado por el número de tokens por el número de niveles, una constante.

🗣️ **2 minutos.** Cada llamada a `atom` consume al menos un token, y cada nivel por encima hace un número constante de llamadas por token que consume. No hay vuelta atrás: ninguna función prueba una alternativa y retrocede. Por eso el total es `Θ(número de tokens)`.

🔬 **El detalle.** Con vuelta atrás (un parser que prueba producciones y retrocede), el coste puede ser exponencial; la preparación de la gramática de §4 es lo que la evita.

**06 → 10.** ¿Qué pasa con la plantilla si la entrada tiene `10⁵` paréntesis anidados, y cómo lo resolverías? 🟠

⏱️ **30 segundos.** Desborda la pila: cada paréntesis añade unas cinco llamadas. En Python, el límite por defecto de mil marcos salta con unos doscientos paréntesis (`RecursionError`); en Java, `StackOverflowError` con unos miles. Se resuelve con una pila explícita o con el algoritmo de la estación de maniobras.

🗣️ **2 minutos.** Subir el límite (`sys.setrecursionlimit`, `-Xss` o un hilo con pila grande en Java) funciona hasta cierto punto. La solución robusta es iterativa: la estación de maniobras de Dijkstra evalúa expresiones con dos pilas explícitas, una de operandos y otra de operadores, sin recursión.

🔬 **El detalle.** Para un formato como JSON, el descenso recursivo se convierte en iterativo con una pila de contextos (dentro de un objeto, dentro de una lista) y un bucle sobre los tokens.

**06 → 11.** Escribe la gramática de `let x = expr` y de las variables, y di qué funciones de la plantilla cambian. 🔴

⏱️ **30 segundos.** `stmt → 'let' IDENT '=' expr | expr` y `atom → NUM | IDENT | '(' expr ')'`. Cambian `atom`, que busca la variable en un mapa, y una función nueva `stmt` por encima de `expr`.

🗣️ **2 minutos.** `stmt` mira el primer token: si es el identificador `let`, consume `let`, el nombre y `=`, evalúa `expr` y guarda el valor; si no, evalúa `expr`. `atom` acepta un `IDENT` y lo busca; si no está, error con la posición. El resto de funciones no cambia: la precedencia sigue igual.

🔬 **El detalle.** Si `let` no fuera palabra reservada, `let = 3` sería ambiguo con un token de anticipación; reservarla es lo que deja la gramática decidible mirando uno.

**06 → 12.** Diseña la gramática y el parser de un JSON mínimo (objetos, listas, cadenas sin escapes, enteros, `true`, `false`, `null`). ¿Qué decide cada función con un solo token? 🔴

⏱️ **30 segundos.** `value → object | array | STRING | NUMBER | true | false | null`; `object → '{' [pair {',' pair}] '}'`; `pair → STRING ':' value`; `array → '[' [value {',' value}] ']'`. `value` decide por el primer token; `object` y `array`, por si lo siguiente es el cierre o una coma.

🗣️ **2 minutos.** Cada forma de valor empieza por un token distinto (`{`, `[`, cadena, número, palabra), así que `value` elige con un `switch`. Dentro de un objeto, tras `{` se mira si viene `}` (vacío) o una cadena (primer par); tras cada par, `,` (otro par) o `}` (fin). Una coma seguida de `]` es un error, que es como se rechaza `[1, 2,]`.

🔬 **El detalle.** El lexer reconoce las cadenas, los números y las palabras con coincidencia más larga; `nul` es un error léxico, no sintáctico. Con anidamiento profundo, la versión con pila explícita.

**06 → Problema: Calculadora con variables.**

**Pista 2:** Lexer y descenso recursivo por niveles, con un mapa de variables y una regla `stmt` que mira si la línea empieza por `let`.

**Pista 3:** `stmt → 'let' IDENT '=' expr | expr`; `expr → term {(+|-) term}`; `term → unary {(*|/) unary}`; `unary → '-' unary | atom`; `atom → NUM | IDENT | '(' expr ')'`. Un error (división por cero, variable sin asignar) se propaga como excepción hasta `stmt`: si la línea era una expresión, imprime `ERROR`; si era una asignación, no guarda nada. División truncada hacia cero, con cuidado en Python.

**06 → Problema: JSON mínimo.**

**Pista 2:** Lexer de cadenas, números, palabras y símbolos, y una gramática de valores, objetos y listas; con anidamiento de `5·10⁴`, el parser va con pila explícita.

**Pista 3:** Una pila de contextos (objeto o lista, y en qué punto está: esperando clave, dos puntos, valor, coma o cierre) y un bucle sobre los tokens. Cada `{` o `[` apila y actualiza la profundidad máxima; cada cierre desapila y comprueba que coincide; cada `:` válido suma una clave. Al final, la pila vacía y sin tokens sobrantes. Recursivo también vale si se sube el límite de pila (un hilo con pila grande en Java, `sys.setrecursionlimit` y `threading.stack_size` en Python).

**06 → Problema: Evaluate the Bracket Pairs of a String.**

**Pista 2:** Un lexer de una pasada con dos estados (dentro y fuera de un corchete) y un mapa de las claves.

**Pista 3:** Recorre la cadena: fuera, copia el carácter; al ver `(`, empieza a acumular la clave; al ver `)`, busca la clave en el mapa y escribe su valor o `?`. Con un `StringBuilder` (o lista y `join`), `Θ(n + suma de las claves)`.

**06 → Problema: Remove Comments.**

**Pista 2:** Un lexer con estados: código normal y dentro de un comentario de bloque, que puede cruzar líneas.

**Pista 3:** Recorre carácter a carácter llevando el estado. En código normal, `//` descarta el resto de la línea y `/*` cambia al estado de bloque; en bloque, solo `*/` vuelve a código normal. La línea en construcción no se emite mientras estás en un bloque que viene de otra línea; al terminar una línea en estado normal, se emite si no está vacía.

**06 → Problema: Solve the Equation.**

**Pista 2:** Tokenizar cada lado en términos con signo y resumirlo en dos números: coeficiente de `x` y constante.

**Pista 3:** Para cada lado, acumula `a·x + b` recorriendo términos (`+2x`, `-x`, `+5`); un `x` sin número es coeficiente 1. Resta los lados: `(a₁ − a₂)·x = b₂ − b₁`. Si el coeficiente es 0, «Infinite solutions» si la constante también lo es, «No solution» si no; si no, `x = constante / coeficiente`.

**06 → Problema: Basic Calculator.**

**Pista 2:** Descenso recursivo (o una pila de signos) sobre `+`, `-`, paréntesis y el menos unario.

**Pista 3:** Con la gramática `expr → unary {(+|-) unary}`, `unary → '-' unary | atom`, `atom → NUM | '(' expr ')'`, la plantilla de §5 sin `*` ni `/`. La versión iterativa lleva una pila con el signo acumulado de cada paréntesis abierto: cada número se suma con el signo actual por el de su contexto.

**06 → Problema: Parse Lisp Expression.**

**Pista 2:** Descenso recursivo sobre las expresiones `(let …)`, `(add …)`, `(mult …)`, con una pila de ámbitos para las variables.

**Pista 3:** `eval(tokens, ámbito)`: si el token es un número, su valor; si es un nombre, búscalo del ámbito más interior al exterior; si es `(`, mira la palabra: `add` y `mult` evalúan dos subexpresiones; `let` abre un ámbito nuevo, asigna pares en orden (cada valor puede usar las asignaciones anteriores) y evalúa la última expresión. Al cerrar el `let`, se descarta el ámbito.

**06 → Problema: Brace Expansion II.**

**Pista 2:** Una gramática con dos operaciones, unión (la coma) y concatenación (la yuxtaposición), donde la concatenación liga más fuerte; descenso recursivo con conjuntos.

**Pista 3:** `union → concat {',' concat}`; `concat → item {item}`; `item → letras | '{' union '}'`. Cada función devuelve un conjunto de palabras: la unión junta conjuntos, la concatenación hace el producto cartesiano de cadenas. Al final, ordenar el conjunto. El tamaño puede crecer mucho: las restricciones lo acotan.
