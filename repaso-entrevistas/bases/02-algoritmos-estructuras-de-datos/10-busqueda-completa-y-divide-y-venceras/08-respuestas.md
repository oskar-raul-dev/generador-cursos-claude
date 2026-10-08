# Respuestas — bloque 10: Búsqueda completa y divide y vencerás

> Solucionario del bloque `10`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--recursión) · [02](#02--generar-subconjuntos-permutaciones-y-combinaciones) · [03](#03--backtracking-con-poda-y-ramificación-y-poda) · [04](#04--meet-in-the-middle-iddfs-y-dancing-links) · [05](#05--divide-y-vencerás) · [06](#06--juegos-y-búsqueda-adversarial) · [07](#07--simulación)

---

# 01 — Recursión

**01 → 1.** ¿Qué dos partes tiene toda función recursiva correcta, y qué pasa si falta cada una? 🟢

⏱️ **30 segundos.** Un caso base, que se resuelve sin llamarse, y un caso recursivo que reduce la entrada a otras más pequeñas según una medida que baja estrictamente. Sin base, la recursión no termina; sin medida que baje, tampoco.

🗣️ **2 minutos.** Si falta el caso base (o no se alcanza), cada llamada genera otra y la pila se agota: `StackOverflowError`, `RecursionError` o un fallo de segmentación. Si el caso recursivo no reduce la medida —llamar con `n` en vez de `n − 1`, o con un tramo que no encoge—, el efecto es el mismo aunque el caso base exista.

🔬 **El detalle.** La medida tiene que ser un natural, o algo bien fundado: «baja estrictamente» sobre los naturales garantiza terminar; sobre los reales no (`1, 1/2, 1/4, …` baja siempre y no llega a 0).

**01 → 2.** ¿Qué guarda un marco de pila, y de qué depende la memoria que usa una recursión? 🟢

⏱️ **30 segundos.** Los parámetros, las variables locales y la dirección de retorno de una llamada en curso. La memoria de pila es la profundidad máxima por el tamaño del marco, no el número total de llamadas.

🗣️ **2 minutos.** En cada momento solo están abiertas las llamadas de una rama del árbol de recursión, desde la raíz hasta la llamada activa; las ramas ya terminadas liberaron sus marcos. Por eso la memoria es la altura del árbol. A eso se suma lo que cada marco reserve aparte (una copia del arreglo, por ejemplo).

🔬 **El detalle.** En Java los objetos que crea una llamada van al *heap*, y en el marco solo queda la referencia; en C++ un arreglo local grande (`int buf[100000]`) va **en** el marco y agota la pila en pocos niveles.

**01 → 3.** ¿Cuántos movimientos y cuántas llamadas hace `hanoi(n)`, y cuál es su profundidad máxima? 🟢

⏱️ **30 segundos.** `2ⁿ − 1` movimientos, `2ⁿ⁺¹ − 1` llamadas contando las de `n = 0`, y profundidad `n + 1` marcos.

🗣️ **2 minutos.** `M(n) = 2M(n − 1) + 1` con `M(0) = 0`; desplegando, `M(n) = 1 + 2 + … + 2ⁿ⁻¹ = 2ⁿ − 1`. Las llamadas cumplen `L(n) = 2L(n − 1) + 1` con `L(0) = 1`, que da `2ⁿ⁺¹ − 1`. La profundidad baja `n` en uno por nivel hasta 0.

🔬 **El detalle.** `2ⁿ − 1` es también el mínimo posible: el disco mayor tiene que moverse al menos una vez, y antes los `n − 1` de arriba tienen que estar todos en la tercera varilla, y después volver encima; eso da la misma recurrencia como cota inferior.

**01 → 4.** ¿Qué es una llamada de cola, y cuál de los tres lenguajes la elimina de forma garantizada? 🟡

⏱️ **30 segundos.** Una llamada que es lo último que hace la función, cuyo resultado se devuelve sin operar. Ninguno de los tres la elimina de forma garantizada: C++ a menudo con `-O2`, sin garantía; Java y Python nunca.

🗣️ **2 minutos.** `return f(n − 1, acc + n)` es de cola; `return n + f(n − 1)` no, porque falta la suma al volver. En C++, GCC y Clang la convierten en salto con optimización si no hay destructores pendientes, pero el estándar no lo exige. La JVM conserva todos los marcos. Python lo descarta por diseño, para conservar las trazas de error completas.

🔬 **El detalle.** Por eso la regla práctica es convertir a mano toda recursión de cola de profundidad grande en un bucle. Lenguajes como Scheme sí garantizan la eliminación; Scala la comprueba con `@tailrec`.

**01 → 5.** Da una recursión cuyo tiempo sea exponencial y su pila lineal, y explica por qué los dos costes no coinciden. 🟡

⏱️ **30 segundos.** Hanoi: `Θ(2ⁿ)` de tiempo y `Θ(n)` de pila. El tiempo es el tamaño del árbol de recursión; la pila, su altura.

🗣️ **2 minutos.** El árbol de `hanoi(n)` es binario y completo, con `2ⁿ⁺¹ − 1` nodos, pero en cada momento solo está abierta una rama, de `n + 1` marcos. Lo mismo pasa con el Fibonacci ingenuo: `Θ(φⁿ)` llamadas y profundidad `n`.

🔬 **El detalle.** El caso contrario también existe: una recursión con poco tiempo y mucha pila es la lineal sobre una cadena, con `n` llamadas y `n` marcos; ahí la pila es el problema aunque el tiempo sea ínfimo.

**01 → 6.** Compara cómo se amplía la profundidad máxima de recursión en C++, Java y Python, y qué límite queda después. 🟡

⏱️ **30 segundos.** C++: la pila del sistema o del juez, sin control desde el código; Java: un `Thread` con tamaño de pila; Python: `setrecursionlimit` **más** un hilo con `threading.stack_size`. Después, el límite es la memoria que el juez deje para la pila.

🗣️ **2 minutos.** En C++ la pila del hilo principal es la del proceso (8 MB por omisión en Linux); muchos jueces la suben, otros no, y no se puede cambiar desde el programa sin trucos no portables. En Java, `new Thread(null, r, "solve", 1L << 28)` pide 256 MB. En Python, el contador de 1000 se sube con `setrecursionlimit`, y la pila real con `threading.stack_size` antes de crear el hilo.

🔬 **El detalle.** Incluso con 256 MB, una recursión de `10⁷` niveles con marcos de 64 bytes ya pide 640 MB: la receta del hilo tiene techo, y por encima solo queda el iterativo.

**01 → 7.** ¿Por qué `sys.setrecursionlimit(10**6)` puede bastar con una recursión de Python puro desde 3.11 y tumbar el proceso si la función está decorada con `@cache`? 🟠

⏱️ **30 segundos.** Porque desde 3.11 las llamadas entre funciones de Python no gastan pila de C, pero el envoltorio de `@cache` está escrito en C, y cada nivel que pasa por él vuelve a gastarla.

🗣️ **2 minutos.** Con Python puro, los marcos viven en el *heap* del intérprete y el único freno es el contador de `setrecursionlimit`: subirlo basta. Con `@cache`, cada llamada entra al código C de `functools`, que llama de nuevo al intérprete: eso consume pila de C por nivel. Con el límite alto, la pila del sistema se agota antes que el contador y el proceso muere con un fallo de segmentación, sin `RecursionError`.

🔬 **El detalle.** Lo mismo pasa con recursiones que atraviesan `map`, `sorted` con `key`, o métodos especiales llamados desde C. La receta robusta —el hilo con `threading.stack_size`— funciona en todos los casos; la iterativa, también y más rápido.

**01 → 8.** ¿Por qué pasar una copia del subarreglo en cada llamada cambia el coste de una recursión lineal, y cuánto? 🟠

⏱️ **30 segundos.** Porque cada llamada paga la copia del resto: una recursión lineal pasa de `Θ(n)` a `Θ(n²)` en tiempo, y la memoria también, porque todas las copias viven a la vez en la pila.

🗣️ **2 minutos.** `count(a[1:])` copia `n − 1`, luego `n − 2`…: `Σ k = n(n − 1)/2`. Y como cada marco conserva su copia hasta volver, en el punto más profundo conviven todas: `Θ(n²)` de memoria. Pasar un índice `i` deja cada llamada en `O(1)`.

🔬 **El detalle.** En una recursión que parte por la mitad, la copia cuesta menos de lo que parece: la búsqueda binaria con copias cumple `T(n) = T(n/2) + Θ(n)`, que es `Θ(n)` por el teorema maestro, frente al `Θ(log n)` de la versión con índices: sigue siendo un desastre relativo.

**01 → 9.** ¿Cuándo basta un bucle para quitar la recursión, y cuándo hace falta una pila de marcos con etapa? 🟠

⏱️ **30 segundos.** Basta un bucle cuando la llamada es de cola: los parámetros se reasignan y se vuelve al principio. Hace falta una pila de marcos con etapa cuando hay varias llamadas, o trabajo entre ellas, que obliga a recordar por dónde seguir.

🗣️ **2 minutos.** Hay un caso intermedio: una sola llamada con trabajo **después** (sumar al volver) se resuelve con dos fases, bajando y apilando lo que falta por hacer y subiendo al desapilar, sin etapas. Con dos o más llamadas, el marco necesita saber cuál de ellas se hizo ya: esa es la etapa.

🔬 **El detalle.** Una recursión no de cola a veces se vuelve de cola con un acumulador (`n + f(n − 1)` → `f(n − 1, acc + n)`), si la operación es asociativa. Es la transformación que hace un compilador funcional, y la que se hace a mano antes de escribir el bucle.

**01 → 10.** Demuestra por inducción que `hanoi(n, from, to, via)` mueve la torre sin poner nunca un disco sobre otro menor. 🟠

⏱️ **30 segundos.** Inducción sobre `n`: con 0 no se mueve nada; si `hanoi(n − 1)` es correcto, aparta los `n − 1` menores a la varilla libre, el mayor pasa a una varilla vacía de menores, y los `n − 1` vuelven encima de él.

🗣️ **2 minutos.** La hipótesis dice que `hanoi(n − 1, x, y, z)` mueve correctamente una torre de `n − 1` discos de `x` a `y` aunque haya discos mayores debajo en cualquier varilla, porque nunca toca esos discos y todos los suyos son menores. Primer paso: los `n − 1` pasan a `via`. Segundo: el disco `n` está solo en `from` (nada encima) y `to` no tiene ningún disco menor que él (todos los menores están en `via`), así que se mueve legalmente. Tercero: los `n − 1` van de `via` a `to`, encima del disco `n`, que es mayor que todos ellos.

🔬 **El detalle.** El paso delicado es fortalecer la hipótesis: «mueve la torre aunque haya discos mayores en las varillas». Sin esa versión fuerte, la inducción no se aplica a las llamadas internas, que trabajan con el disco `n` presente. Es la lección general de las pruebas por inducción de recursiones: a veces hay que probar algo más fuerte de lo que se pide.

**01 → 11.** ¿Qué invariante relaciona la pila explícita de la versión iterativa con la pila de llamadas de la recursiva, y por qué basta para la corrección? 🟠

⏱️ **30 segundos.** Que en cada vuelta la pila explícita contiene los mismos marcos que tendría abiertos la recursiva, en el mismo orden, y la etapa de cada uno dice dónde se reanudaría. Basta porque así la iterativa ejecuta las mismas operaciones en el mismo orden.

🗣️ **2 minutos.** Inicialización: un solo marco, la llamada inicial en la etapa 0, como al empezar la recursiva. Mantenimiento: cada vuelta hace exactamente una de las transiciones de la recursiva —llamar (apilar en etapa 0), avanzar (ejecutar hasta la siguiente llamada y subir la etapa) o volver (desapilar)—. Terminación: la pila vacía corresponde a la llamada inicial terminada.

🔬 **El detalle.** Es una prueba por simulación: se demuestra que dos máquinas pasan por estados equivalentes. Si la función devuelve valores, el invariante se amplía con «la pila de valores contiene los resultados de los hijos ya terminados del marco de la cima».

**01 → 12.** Tu solución recursiva pasa todos los ejemplos y da RE en el caso 9, con `n = 2·10⁵`. ¿Qué miras primero y qué cambias en cada lenguaje? 🔴

⏱️ **30 segundos.** La profundidad de la recursión con `n = 2·10⁵`: casi seguro es la pila. En Java, un `Thread` con pila grande o iterativo; en Python, el límite y el hilo, o iterativo; en C++, iterativo si el juez no da pila suficiente.

🗣️ **2 minutos.** Primero confirmo: genero un caso del peor tipo (una cadena, un árbol degenerado) y lo corro en local; si es la pila, sale `StackOverflowError` o `RecursionError`. Después elijo: el hilo es el arreglo más rápido de escribir en Java y Python; el iterativo, el más robusto. Antes de enviar, compruebo que no haya otra causa de RE: índices fuera de rango con el `n` máximo, o división por cero.

🔬 **El detalle.** En Python, si ya subiste el límite y la función usa `@cache`, el RE puede ser un fallo de segmentación por la pila de C, no el contador. Y en algunos jueces la pila cuenta como memoria: un hilo de 1 GB puede dar MLE.

**01 → 13.** Convierte a iterativa con pila explícita el recorrido en orden de un árbol binario (izquierdo, nodo, derecho) y di qué guarda cada marco y cuántas etapas tiene. 🔴

⏱️ **30 segundos.** Marco `(nodo, etapa)` con dos etapas útiles: en la 0 se marca 1 y se apila el hijo izquierdo; en la 1 se visita el nodo, se marca 2 y se apila el derecho; en la 2 se desapila.

🗣️ **2 minutos.** El cuerpo recursivo es `inorden(izq); visitar(v); inorden(der)`: dos llamadas y trabajo entre ellas, así que tres etapas. Un nodo nulo se desapila de inmediato, como el caso base. La pila nunca pasa de la altura del árbol más uno.

🔬 **El detalle.** La versión clásica sin etapas —bajar por la izquierda apilando, desapilar, visitar e ir al derecho— es esta misma simulación con una optimización: como tras visitar el nodo la última llamada es de cola, el marco se desapila **antes** de bajar al derecho, y la etapa deja de hacer falta.

**01 → 14.** Da una recursión con profundidad `Θ(n)` y tiempo `Θ(n log n)`, y otra con profundidad `Θ(log n)` y tiempo `Θ(n)`. 🔴

⏱️ **30 segundos.** Profundidad `n` y tiempo `n log n`: recorrer los elementos uno por llamada haciendo en cada una una búsqueda binaria de `log n`. Profundidad `log n` y tiempo `n`: el máximo de un arreglo partiéndolo por la mitad, con trabajo `O(1)` por llamada.

🗣️ **2 minutos.** La primera es `f(i) = buscar(a[i]) + f(i + 1)`: `n` llamadas encadenadas, cada una con `O(log n)` propio. La segunda cumple `T(n) = 2T(n/2) + O(1) = Θ(n)` (hay `2n − 1` llamadas), pero el árbol es equilibrado y su altura es `⌈log₂ n⌉`.

🔬 **El detalle.** El ejemplo muestra que tiempo y profundidad son independientes: el primero es el tamaño del árbol ponderado por el trabajo, la segunda su altura. Mergesort tiene tiempo `n log n` y profundidad `log n`; el *quicksort* con mal pivote, tiempo `n²` y profundidad `n`, que es por lo que las implementaciones serias recurren primero sobre la mitad pequeña.

**01 → Problema: Conjunto de Cantor.**

- **Pista 2 — patrón:** **recursión directa sobre la definición**, con caso base el nivel 0.
- **Pista 3 — diseño:** `dibujo(k) = dibujo(k − 1) + espacios(3ᵏ⁻¹) + dibujo(k − 1)`; la profundidad es `n ≤ 12` y la salida mide `3¹² = 531 441`. Construye con un `StringBuilder` (o rellena un arreglo de caracteres de tamaño `3ⁿ`, poniendo guiones solo en las posiciones que sobreviven), e imprime una vez.

**01 → Problema: Pliegues de papel.**

- **Pista 2 — patrón:** **recursión sobre la posición**, que solo baja por la mitad que contiene `i`.
- **Pista 3 — diseño:** en `Sₖ`, el centro es `2ᵏ⁻¹` y es `V`; si `i` es menor, la respuesta es la de `Sₖ₋₁` en `i`; si es mayor, es la **contraria** de la de `Sₖ₋₁` en `2ᵏ − i`. Profundidad `k ≤ 60` por consulta; o un bucle con una bandera de inversión. Usa enteros de 64 bits sin signo o `long`: `2⁶⁰` cabe.

**01 → Problema: Calculadora prefija.**

- **Pista 2 — patrón:** **descenso recursivo convertido en pila explícita**: la anidación de `5·10⁵` niveles desborda la recursión en Java y Python.
- **Pista 3 — diseño:** recorre los símbolos **de derecha a izquierda** con una pila de valores: un número se apila; un operador saca dos valores `a` (cima) y `b`, apila `a op b`. Al final queda un valor. La versión recursiva (`eval()` lee un símbolo; si es operador, evalúa dos subexpresiones) es correcta y vale en C++ si el juez da pila; en Java y Python, o el hilo o la pila.

**01 → Problema: Recursion: Fibonacci Numbers.**

- **Pista 2 — patrón:** **recursión con dos casos base**, `F(0) = 0` y `F(1) = 1`.
- **Pista 3 — diseño:** `F(n) = F(n − 1) + F(n − 2)`. Con las restricciones del problema la recursión ingenua pasa; cuenta cuántas llamadas hace para `n = 30` (más de un millón) y anota por qué la memoización de [`12/01`](../12-dp-clasica/01-de-la-recursion-a-la-tabla.md) las baja a `n`.

**01 → Problema: K-th Symbol in Grammar.**

- **Pista 2 — patrón:** **recursión sobre la posición**: el símbolo `k` de la fila `n` sale del símbolo `⌈k/2⌉` de la fila `n − 1`.
- **Pista 3 — diseño:** si `k` es impar, es igual a su padre; si es par, es el contrario. Profundidad `n ≤ 30`. Equivalente: la paridad del número de unos de `k − 1` en binario.

**01 → Problema: Find Kth Bit in Nth Binary String.**

- **Pista 2 — patrón:** **recursión con reflejo**: `Sₙ = Sₙ₋₁ + "1" + reverse(invert(Sₙ₋₁))`.
- **Pista 3 — diseño:** con longitud `2ⁿ − 1` y centro `2ⁿ⁻¹`: si `k` es el centro, es `1`; si es menor, recurre en `Sₙ₋₁` con `k`; si es mayor, recurre con `2ⁿ − k` e invierte el resultado. Profundidad `n`.

**01 → Problema: Find the Winner of the Circular Game.**

- **Pista 2 — patrón:** **recurrencia de Josefo**: el ganador con `n` se obtiene del ganador con `n − 1`.
- **Pista 3 — diseño:** con índices desde 0, `J(1) = 0` y `J(n) = (J(n − 1) + k) mod n`; la respuesta es `J(n) + 1`. Escrita como bucle de `2` a `n`, sin pila: es una recursión de un solo hijo con trabajo después.

**01 → Problema: Score of Parentheses.**

- **Pista 2 — patrón:** **recursión sobre la anidación** (o pila por niveles).
- **Pista 3 — diseño:** un `()` en profundidad `d` aporta `2ᵈ`, y la puntuación es la suma de esos aportes; recursivamente, `score(cadena) = Σ` sobre sus bloques de primer nivel, con `score("()") = 1` y `score("(A)") = 2 · score(A)`.

**01 → Problema: Flatten Nested List Iterator.**

- **Pista 2 — patrón:** **recursión convertida en pila explícita** que se avanza de forma perezosa.
- **Pista 3 — diseño:** guarda una pila de iteradores (o de listas con su índice); `hasNext` desapila listas agotadas y, mientras la cima apunte a una lista, la abre y apila su iterador, hasta dejar un entero en la cima o la pila vacía. `next` lo consume. Es el marco `(lista, índice)` de la plantilla, sin etapas.

**01 → Problema: Elimination Game.**

- **Pista 2 — patrón:** **recursión sobre el problema reducido**, con simetría de sentido.
- **Pista 3 — diseño:** tras la pasada de izquierda a derecha quedan los pares `2, 4, …`, que son `2 · (1..⌊n/2⌋)`; la siguiente pasada va de derecha a izquierda, y por simetría el resultado de `n/2` empezando por la derecha es `⌊n/2⌋ + 1 −` el de empezar por la izquierda. Así `f(n) = 2 · (⌊n/2⌋ + 1 − f(⌊n/2⌋))` con `f(1) = 1`. Profundidad `log n`.

**01 → Problema: Mini Parser.**

- **Pista 2 — patrón:** **descenso recursivo** o, equivalente, **pila de listas abiertas**.
- **Pista 3 — diseño:** con pila: al ver `[`, apila una lista nueva; al ver un número completo, añádelo a la cima; al ver `]`, desapila y añade la lista cerrada a la nueva cima. Con recursión: `parse(i)` devuelve el elemento que empieza en `i` y la posición donde acaba.

**01 → Problema: Number of Atoms.**

- **Pista 2 — patrón:** **descenso recursivo** donde cada paréntesis devuelve un mapa de cuentas.
- **Pista 3 — diseño:** `parse()` lee elementos (mayúscula + minúsculas + número opcional) y, al ver `(`, se llama para obtener el mapa interior, lee el multiplicador tras `)` y lo suma multiplicado al mapa actual. Al final, ordena por nombre. La versión con pila de mapas evita la recursión.

**01 → Problema: Parsing A Boolean Expression.**

- **Pista 2 — patrón:** **descenso recursivo** sobre una gramática de cuatro reglas (`t`, `f`, `!(…)`, `&(…)`, `|(…)`).
- **Pista 3 — diseño:** `eval(i)` devuelve `(valor, posición siguiente)`: si ve `t` o `f`, lo devuelve; si ve un operador, salta `(`, evalúa subexpresiones separadas por comas hasta `)`, y combina. Con una pila: apila caracteres hasta `)`, desapila los operandos hasta `(`, aplica el operador y apila el resultado.

**01 → Problema: Special Binary String.**

- **Pista 2 — patrón:** **recursión sobre bloques** «primos» de la cadena, con ordenación.
- **Pista 3 — diseño:** parte la cadena en especiales mínimas (el saldo de unos menos ceros vuelve a 0); cada una es `1 + interior + 0`; resuelve el interior recursivamente, ordena las piezas resultantes en orden decreciente y concaténalas.

---

# 02 — Generar subconjuntos, permutaciones y combinaciones

**02 → 1.** ¿Cuántos subconjuntos, permutaciones y combinaciones de tamaño `k` tiene un conjunto de `n` elementos, y hasta qué `n` cabe enumerar cada uno en un segundo? 🟢

⏱️ **30 segundos.** `2ⁿ` subconjuntos, `n!` permutaciones y `C(n, k)` combinaciones. En un segundo caben subconjuntos con `n ≤ 20` (hasta 25 con trabajo `O(1)`), permutaciones con `n ≤ 10`, y combinaciones mientras `C(n, k)` no pase de unos `10⁷`.

🗣️ **2 minutos.** La cuenta es el número de casos por el coste de procesar cada uno, contra unas `10⁸` operaciones por segundo. `2²⁰ · 20 = 2·10⁷`; `10! · 10 = 3,6·10⁷`; `11!` ya son `4·10⁷` casos antes de procesarlos. Las combinaciones dependen de `k`: `C(30, 3) = 4 060`, `C(30, 15) ≈ 1,55·10⁸`.

🔬 **El detalle.** En Python, divide entre 30–50: `2²⁰` vueltas de un bucle con poco dentro ya rondan el segundo, y `n ≤ 18` es más seguro.

**02 → 2.** ¿Qué subconjunto representa la máscara `13` sobre `[5, 2, 9, 1]`, y qué máscara representa `{2, 1}`? 🟢

⏱️ **30 segundos.** `13 = 1101₂`: bits 0, 2 y 3, es decir `{5, 9, 1}`. `{2, 1}` son los índices 1 y 3: máscara `2 + 8 = 10`.

🗣️ **2 minutos.** El bit `i` corresponde al elemento de índice `i`, y se lee de derecha a izquierda: el bit 0 es el de menor peso. Leer la máscara al revés (de izquierda a derecha) es el error típico.

🔬 **El detalle.** La convención es arbitraria pero tiene que ser fija en todo el programa: `(m >> i) & 1` para leer y `1 << i` para escribir.

**02 → 3.** ¿Qué hace `m & (m − 1)` y para qué sirve al calcular las sumas de los subconjuntos? 🟢

⏱️ **30 segundos.** Apaga el bit encendido más bajo de `m`. Da la máscara «sin el último elemento», que es menor que `m` y por eso ya tiene su suma calculada.

🗣️ **2 minutos.** Restar 1 convierte el bit más bajo en 0 y los ceros de su derecha en unos; el `&` con `m` borra esos unos. Con `sum[m] = sum[m & (m − 1)] + a[bit más bajo]`, cada suma sale en `O(1)` y el total es `Θ(2ⁿ)`.

🔬 **El detalle.** Lo mismo funciona para cualquier operación que se combine elemento a elemento: OR, XOR, máximo, producto. Es la base de muchas DP sobre máscaras ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)).

**02 → 4.** ¿Qué devuelve `next_permutation` cuando la permutación es la última, y por qué hay que ordenar antes del bucle? 🟢

⏱️ **30 segundos.** Devuelve `false` y deja el rango en la **primera** permutación (ordenado). Hay que ordenar antes porque solo recorre las permutaciones posteriores a la inicial.

🗣️ **2 minutos.** Con `do { … } while (next_permutation(…))` empezando en `[2, 1, 3]` se procesan solo `[2, 1, 3]`, `[2, 3, 1]`, `[3, 1, 2]` y `[3, 2, 1]`: faltan las dos que empiezan por 1. Ordenar primero garantiza empezar en la menor.

🔬 **El detalle.** El `do`/`while` (y no un `while`) es para procesar también la primera. La versión de Java del capítulo devuelve `false` sin tocar el arreglo; la de C++ lo deja ordenado, que es útil para volver a empezar.

**02 → 5.** ¿En qué se diferencian `itertools.permutations` y la siguiente permutación cuando hay elementos repetidos? 🟡

⏱️ **30 segundos.** `itertools.permutations` permuta **posiciones**: con repetidos genera tuplas iguales. La siguiente permutación genera cada permutación **distinta** una vez.

🗣️ **2 minutos.** `permutations("aab")` da 6 tuplas, de las que solo 3 son distintas. `next_permutation` sobre `"aab"` da `"aab"`, `"aba"`, `"baa"` y para, porque usa comparaciones estrictas y nunca intercambia dos iguales. Para quitar duplicados con `itertools` hace falta un `set`, que guarda todas en memoria.

🔬 **El detalle.** Con `n` elementos y multiplicidades `c₁, …, c_r`, hay `n! / (c₁! ⋯ c_r!)` permutaciones distintas; con `"aaaaaaaaab"`, 10 frente a 3,6 millones de tuplas.

**02 → 6.** ¿Por qué la recursión de combinaciones pasa `i + 1` y no `start + 1` como nuevo inicio? 🟡

⏱️ **30 segundos.** Porque el siguiente elemento tiene que ser mayor que el **último elegido**, que es `i`, no que el inicio de este nivel. Con `start + 1` se repetirían combinaciones y saldrían secuencias no crecientes.

🗣️ **2 minutos.** Si en el nivel actual se eligió `i = 4` con `start = 1`, pasar `start + 1 = 2` dejaría elegir después el 2 o el 3, y `{4, 2}` saldría además de `{2, 4}`. Pasar `i + 1` fuerza el orden creciente, que es la escritura única de cada combinación.

🔬 **El detalle.** Pasar `i` (sin el `+ 1`) da las **combinaciones con repetición**: secuencias no decrecientes, como en «suma de monedas usando cada una las veces que quieras» ([`10/03`](03-backtracking-y-poda.md)).

**02 → 7.** Compara qué traen C++, Java y Python para permutaciones y combinaciones, y qué tienes que escribir en cada uno. 🟡

⏱️ **30 segundos.** C++ trae `next_permutation` y `prev_permutation`; Python, `itertools.permutations` y `combinations`; Java, nada. En Java se escriben las dos; en Python, la siguiente permutación si hay repetidos.

🗣️ **2 minutos.** Para combinaciones, C++ no trae una función directa; se usa `prev_permutation` sobre un vector con `k` unos y `n − k` ceros, o la recursión. Python tiene `combinations`, en C y en orden lexicográfico. Java obliga a escribir la recursión con índice de inicio y la siguiente permutación, que son diez líneas cada una.

🔬 **El detalle.** En Go y JavaScript tampoco hay nada; en JavaScript, además, los operadores de bits trabajan con 32 bits con signo, así que las máscaras de más de 30 bits necesitan `BigInt` o partirse.

**02 → 8.** ¿Por qué recorrer las `n!` permutaciones con la siguiente permutación cuesta `Θ(n!)` y no `Θ(n · n!)`? 🟠

⏱️ **30 segundos.** Porque cada llamada solo toca el sufijo que cambia, y el sufijo largo cambia muy pocas veces: el coste amortizado es constante, unos `e − 1 ≈ 1,72` pasos de media.

🗣️ **2 minutos.** El sufijo invertido mide `k` cuando los últimos `k` elementos estaban en su última ordenación, lo que pasa en una de cada `k!` permutaciones aproximadamente. Sumando `k · n! / k!` para `k = 1..n` sale `n! · Σ 1/(k − 1)! ≈ e · n!`.

🔬 **El detalle.** El `Θ(n · n!)` aparece al **procesar** cada permutación (leerla entera para evaluarla), no al generarla. Si la evaluación se puede actualizar solo en el sufijo que cambió, el total baja.

**02 → 9.** Elegir 3 de 30: ¿por qué recorrer máscaras y filtrar por `popcount` es mala idea, y qué haces con `k = 15`? 🟠

⏱️ **30 segundos.** Porque recorre `2³⁰ ≈ 10⁹` máscaras para quedarse con 4 060. Con `k = 15`, `C(30, 15) ≈ 1,55·10⁸`: enumerar ya no cabe cómodo, y hay que buscar otra técnica (mitades, DP, o contar sin enumerar).

🗣️ **2 minutos.** El coste del filtro es el tamaño del espacio recorrido, no el de la respuesta. La recursión con índice de inicio y poda recorre solo las combinaciones. Con `k` cercano a `n/2` y `n = 30`, el número de combinaciones es comparable a `2ⁿ`, y ningún generador lo salva.

🔬 **El detalle.** Para `k` pequeño y fijo, los bucles anidados `i < j < l` son lo más claro. El truco de Gosper ([`17/01`](../17-matematica/01-bits.md)) recorre solo las máscaras con `k` bits en orden creciente, en `O(1)` por paso.

**02 → 10.** ¿Por qué materializar los `2²⁰` subconjuntos como listas da MLE, si recorrerlos cabe? 🟠

⏱️ **30 segundos.** Porque guardar un millón de subconjuntos con sus elementos ocupa memoria exponencial —unos `10⁷` objetos en Java—, mientras que recorrerlos al vuelo usa `O(n)` o una tabla de `2ⁿ` números.

🗣️ **2 minutos.** La suma de los tamaños de todos los subconjuntos es `n · 2ⁿ⁻¹`: con `n = 20`, unos `10⁷` elementos. En Java cada uno es un `Integer` de 16 bytes más la referencia, y cada lista su cabecera: centenares de MB. El límite habitual es 256 MB. La máscara representa el mismo subconjunto en 4 bytes.

🔬 **El detalle.** El patrón general es «procesar al vuelo en lugar de materializar»: aplica a permutaciones (40 320 listas con `n = 8` caben; 3,6 millones con `n = 10`, no) y a cualquier generador.

**02 → 11.** Demuestra que la siguiente permutación produce la sucesora lexicográfica inmediata. 🟠

⏱️ **30 segundos.** El sufijo tras `i` es la última ordenación de sus valores, así que la sucesora debe cambiar la posición `i`; ahí va el menor valor del sufijo que supera a `a[i]`, y detrás lo menor posible, que es el sufijo en orden creciente.

🗣️ **2 minutos.** (1) Ninguna permutación con prefijo `a[0..i]` es mayor que `a`, porque el sufijo ya está en orden no creciente; y cambiar una posición anterior a `i` saltaría todas las que comparten el prefijo `a[0..i−1]`. (2) La sucesora tiene en `i` el menor valor mayor que `a[i]` disponible en el sufijo: es `a[j]`, el de más a la derecha que lo supera. (3) Tras el intercambio el sufijo sigue siendo no creciente (`a[j]` era el último mayor que `a[i]`, así que `a[i]` encaja en su sitio), e invertirlo da el orden creciente, el menor.

🔬 **El detalle.** Entre `a` y la permutación construida no cabe ninguna otra: cualquier permutación mayor que `a` con el mismo prefijo `a[0..i−1]` tiene en `i` un valor `≥ a[j]`, y si es `a[j]`, su sufijo es `≥` el creciente. La prueba completa está en Knuth, Vol. 4A, §7.2.1.2.

**02 → 12.** Si en el primer bucle de la siguiente permutación escribes `a[i] > a[i + 1]` en lugar de `>=`, ¿qué pasa con `[2, 1, 1]`? Traza el fallo y di qué le pasa al bucle `do`/`while`. 🔴

⏱️ **30 segundos.** Con `>`, el primer bucle se para en `i = 1` porque `1 > 1` es falso, cuando `[2, 1, 1]` es la última. El segundo bucle baja hasta `j = 0`, intercambia y produce `[1, 2, 1]`: una permutación **anterior**. El `do`/`while` no termina.

🗣️ **2 minutos.** Traza: `i = 1` (debía seguir, porque `a[1] = a[2]`). `j` empieza en 2: `a[2] = 1 ≤ a[1] = 1`, baja a 1: `a[1] ≤ a[1]`, baja a 0: `a[0] = 2 > 1`, para. Intercambia `a[1]` y `a[0]`: `[1, 2, 1]`; invierte `a[2..]`, que es un elemento. Devuelve `true`, y desde `[1, 2, 1]` el recorrido vuelve a `[2, 1, 1]` y se repite: ciclo infinito.

🔬 **El detalle.** El error solo aparece con repetidos: sin ellos, `>` y `>=` coinciden. Es un ejemplo de por qué los generadores se prueban con multiconjuntos y contando cuántos casos salen (`n! / Π cᵢ!`).

**02 → 13.** Diseña la generación de las permutaciones **distintas** de un multiconjunto con la versión recursiva, sin usar un `set`, y explica por qué no repite. 🔴

⏱️ **30 segundos.** Ordenar y, en cada posición, no elegir `a[i]` si es igual a `a[i − 1]` y `a[i − 1]` **no** está usado. Así, entre iguales, siempre se usa primero el de índice menor, y cada permutación distinta sale una vez.

🗣️ **2 minutos.** Los iguales son intercambiables; la regla fija un orden canónico entre ellos: el segundo `5` solo puede colocarse si el primero ya está colocado antes. Con eso, de cada grupo de permutaciones que solo difieren en qué copia va dónde, sobrevive exactamente una: la que coloca las copias en orden de índice.

🔬 **El detalle.** La variante con «`a[i − 1]` **sí** usado» también es correcta (fija el orden contrario) pero poda mucho menos. Alternativa: contar las multiplicidades en un mapa y recorrer los **valores distintos** en cada posición, decrementando su cuenta; es más clara y poda igual.

**02 → Problema: Mochila de capacidad enorme.**

- **Pista 2 — patrón:** **enumerar los subconjuntos con máscaras**: con `W` hasta `10⁹`, la tabla de la mochila no cabe, pero `2²⁰` sí.
- **Pista 3 — diseño:** para cada máscara, peso y valor totales (incrementales con `m & (m − 1)`, o leídos bit a bit); si el peso no pasa de `W`, actualiza el máximo. Usa 64 bits: 20 valores de `10⁹` suman `2·10¹⁰`.

**02 → Problema: El menor número divisible.**

- **Pista 2 — patrón:** **siguiente permutación desde la ordenada**: la primera válida en orden lexicográfico es la menor.
- **Pista 3 — diseño:** ordena los dígitos; recorre con la siguiente permutación (que no repite con dígitos iguales), salta las que empiezan por `0` si tienen más de un dígito, y devuelve la primera con `valor mod k = 0`. Diez dígitos caben en 64 bits. `10! = 3,6·10⁶` en el caso peor.

**02 → Problema: Comités sin rencillas.**

- **Pista 2 — patrón:** **combinaciones con índice de inicio y poda**: cortar en cuanto el comité parcial contiene un par prohibido.
- **Pista 3 — diseño:** guarda para cada persona la máscara de sus incompatibles; mantén la máscara del comité parcial; al añadir `i`, comprueba `incompatibles[i] & comité == 0` en `O(1)`. La poda de huecos (`n − i ≥ k − tamaño`) completa el corte.

**02 → Problema: Sum of All Subset XOR Totals.**

- **Pista 2 — patrón:** **enumerar los subconjuntos** con máscaras.
- **Pista 3 — diseño:** para cada máscara, el XOR de sus elementos (o incremental con `m & (m − 1)`), y suma. Con `n ≤ 12`, `4 096` máscaras. Hay una fórmula cerrada con el OR de todos, pero no hace falta.

**02 → Problema: Subsets.**

- **Pista 2 — patrón:** **máscaras de bits** (o recursión «tomar o no tomar»).
- **Pista 3 — diseño:** para `m` de `0` a `2ⁿ − 1`, construye la lista con los `nums[i]` de los bits encendidos. El vacío es `m = 0` y no se salta.

**02 → Problema: Combinations.**

- **Pista 2 — patrón:** **combinaciones con índice de inicio**.
- **Pista 3 — diseño:** `combine(start, actual)`: si `actual` tiene `k` elementos, guárdalo; si no, para `i` desde `start` mientras queden huecos, añade `i`, recurre con `i + 1` y quita `i`.

**02 → Problema: Permutations II.**

- **Pista 2 — patrón:** **permutaciones de un multiconjunto**: siguiente permutación desde la ordenada, o recursión saltando iguales.
- **Pista 3 — diseño:** ordena; en la recursión, en cada posición salta `nums[i]` si está usado, o si es igual a `nums[i − 1]` y `nums[i − 1]` no está usado. Con la siguiente permutación, el bucle sale solo sin duplicados.

**02 → Problema: Letter Case Permutation.**

- **Pista 2 — patrón:** **subconjuntos de las posiciones con letra**: cada letra es un bit (minúscula o mayúscula).
- **Pista 3 — diseño:** junta los índices de las letras (`L` de ellas) y, para cada máscara de `L` bits, construye la cadena poniendo en mayúscula las letras de los bits encendidos. `2^L` resultados.

**02 → Problema: Bigger is Greater.**

- **Pista 2 — patrón:** **siguiente permutación** de los caracteres.
- **Pista 3 — diseño:** el algoritmo de §2 sobre la cadena; si no hay posición `i` con `w[i] < w[i + 1]`, la palabra ya es la mayor y la respuesta es `no answer`.

**02 → Problema: Forming a Magic Square.**

- **Pista 2 — patrón:** **enumerar todos los candidatos**: los cuadrados mágicos de 3 × 3 con 1..9.
- **Pista 3 — diseño:** genera las `9!` permutaciones de 1..9, quédate con las que tienen las ocho sumas iguales a 15 (son 8), y para cada una calcula el coste `Σ |s[i] − m[i]|`; la respuesta es el mínimo. También puedes escribir los 8 a mano, pero generarlos es más seguro.

**02 → Problema: Apple Division.**

- **Pista 2 — patrón:** **máscaras**: cada manzana va a un grupo u otro.
- **Pista 3 — diseño:** con el total `T`, para cada máscara el peso `s` del primer grupo; la diferencia es `|T − 2s|`. `2²⁰` máscaras y pesos hasta `10⁹`: 64 bits.

**02 → Problema: Next Greater Element III.**

- **Pista 2 — patrón:** **siguiente permutación** de los dígitos.
- **Pista 3 — diseño:** aplica el algoritmo a los dígitos; si no hay sucesora, `-1`; si la hay, conviértela a número en 64 bits y devuelve `-1` si pasa de `2³¹ − 1`.

**02 → Problema: Count Number of Maximum Bitwise-OR Subsets.**

- **Pista 2 — patrón:** **máscaras con OR incremental**.
- **Pista 3 — diseño:** el máximo posible es el OR de todos; `or[m] = or[m & (m − 1)] | nums[bit más bajo]`; cuenta las máscaras no vacías con `or[m]` igual al máximo.

**02 → Problema: Maximum Length of a Concatenated String with Unique Characters.**

- **Pista 2 — patrón:** **subconjuntos** (o recursión tomar/no tomar), con el conjunto de letras de cada palabra como máscara de 26 bits.
- **Pista 3 — diseño:** descarta las palabras con letras repetidas; recurre por las palabras llevando la máscara acumulada; una palabra se puede tomar si `máscara & letras(palabra) == 0`. La respuesta es el mayor `popcount` alcanzado.

**02 → Problema: Permutation Sequence.**

- **Pista 2 — patrón:** **permutación `k`-ésima por bloques factoriales**, sin enumerar.
- **Pista 3 — diseño:** con `k − 1` en base factorial: la primera cifra es el elemento de índice `⌊(k − 1) / (n − 1)!⌋` entre los disponibles; se quita, `k − 1` se queda con el resto, y se repite con `(n − 2)!`.

---

# 03 — *Backtracking* con poda y ramificación y poda

**03 → 1.** ¿Qué es un nodo del árbol de estados, y qué representan la raíz y las hojas? 🟢

⏱️ **30 segundos.** Un nodo es una solución parcial: las primeras decisiones tomadas. La raíz es la solución vacía, y las hojas son las soluciones completas candidatas.

🗣️ **2 minutos.** Los hijos de un nodo son sus extensiones con una decisión más: la columna de la siguiente reina, si se toma o no el siguiente objeto. Un camino de la raíz a una hoja es una secuencia completa de decisiones. La búsqueda completa recorre el árbol; el *backtracking* lo recorre en profundidad y poda subárboles.

🔬 **El detalle.** El árbol es implícito: nunca se construye en memoria. Solo existe el camino actual, en la pila de la recursión, y por eso la memoria es la profundidad.

**03 → 2.** ¿Qué son las tres operaciones del patrón aplicar–recurrir–deshacer, y qué invariante mantiene el deshacer? 🟢

⏱️ **30 segundos.** Aplicar la decisión al estado compartido, recurrir, y deshacerla al volver. El deshacer mantiene que, al entrar en un nodo, el estado describe exactamente la solución parcial de ese nodo.

🗣️ **2 minutos.** Sin el deshacer, la segunda hija de un nodo hereda las marcas de la primera: una columna sigue marcada como usada, una letra sigue marcada como visitada, y se pierden soluciones o se generan falsas. Cuando el estado va en los parámetros (una suma restante, un índice), el deshacer es implícito: al volver, el padre tiene su copia.

🔬 **El detalle.** Es el mismo invariante que la pila de marcos de [`10/01`](01-recursion.md): el estado compartido es parte del «marco» del nodo actual, y volver a un marco anterior exige restaurar su parte.

**03 → 3.** ¿Qué marcas usas para comprobar en `O(1)` que una reina nueva no está atacada? 🟢

⏱️ **30 segundos.** Tres arreglos de booleanos: columnas, diagonales `r + c` y diagonales `r − c + n`. Una casilla está atacada si cualquiera de sus tres marcas está puesta.

🗣️ **2 minutos.** En una diagonal descendente `r − c` es constante; en una ascendente, `r + c`. Se suma `n` a `r − c` para que el índice no sea negativo. Las filas no hacen falta porque se coloca una reina por fila.

🔬 **El detalle.** Con máscaras de bits en vez de arreglos (tres enteros que se desplazan al bajar de fila), la versión clásica de Richards cuenta las reinas de 14 o 15 en segundos: es la misma poda con constante más baja.

**03 → 4.** ¿En qué se diferencia el *backtracking* de la enumeración de `10/02`, si los dos recorren el mismo árbol? 🟡

⏱️ **30 segundos.** La enumeración genera cada hoja y la comprueba al final; el *backtracking* comprueba cada solución parcial al formarse y no extiende las que ya fallan.

🗣️ **2 minutos.** Recorren el mismo árbol de estados, pero el *backtracking* poda subárboles enteros en cuanto un prefijo viola una restricción. En las 8 reinas: 40 320 hojas comprobadas frente a 2 057 nodos visitados.

🔬 **El detalle.** La diferencia solo existe si la restricción se puede evaluar sobre parciales. Si una restricción solo se sabe al final (una suma total exacta con pesos de cualquier signo), el *backtracking* degenera en enumeración.

**03 → 5.** ¿En qué se diferencia una poda por factibilidad de una poda por cota? 🟡

⏱️ **30 segundos.** La de factibilidad poda lo que no puede llevar a ninguna solución válida; la de cota, lo que no puede llevar a una **mejor** que la ya encontrada.

🗣️ **2 minutos.** La de factibilidad no depende de lo encontrado antes: una reina atacada es inválida siempre. La de cota sí: depende del mejor valor actual, que mejora durante la búsqueda, y por eso el orden de exploración cambia cuánto se poda.

🔬 **El detalle.** La de cota solo existe en problemas de optimización, y su corrección exige que la cota sea **segura** (optimista): nunca peor que lo que realmente da el subárbol.

**03 → 6.** ¿Por qué las dos podas de la suma de subconjuntos son `break` y no `continue`, y qué exigen de la entrada? 🟡

⏱️ **30 segundos.** Porque con los pesos ordenados de menor a mayor, si `a[j]` ya se pasa, los siguientes también; y si lo que queda desde `j` no llega, desde `j + 1` llega aún menos. Exigen pesos positivos y ordenados.

🗣️ **2 minutos.** `continue` sería correcto pero inútil: seguiría probando índices que fallan por la misma razón. El `break` corta el bucle entero de ese nivel. Sin orden, ninguna de las dos implicaciones vale; con pesos negativos, tampoco la primera.

🔬 **El detalle.** La segunda poda necesita los sufijos precalculados (`suffix[j]`), `O(n)` una vez. Es una cota de factibilidad: «ni sumando todo lo que queda llego».

**03 → 7.** Compara cómo se lleva el mejor valor encontrado en una ramificación y poda en C++, Java y Python. 🟡

⏱️ **30 segundos.** En C++, una referencia `long long& best`; en Java, un campo estático o un arreglo de un elemento; en Python, `nonlocal` en una función anidada o un atributo.

🗣️ **2 minutos.** Java pasa los primitivos por valor, así que una variable local no sobrevive a la recursión: hace falta un contenedor mutable o un campo. Python permite cerrar sobre una variable con `nonlocal`, o usar una lista de un elemento. C++ pasa la referencia y no hay más.

🔬 **El detalle.** En Python, además, la recursión cuesta cara: con un árbol de `10⁶` nodos ya se notan los segundos, y conviene reducir los nodos con mejores cotas antes que optimizar el código.

**03 → 8.** ¿Por qué la poda «la suma parcial ya supera el objetivo» falla con pesos negativos? Da un ejemplo. 🟠

⏱️ **30 segundos.** Porque una suma que hoy se pasa puede volver a bajar si después se elige un peso negativo. Con `[3, −2]` y objetivo 1: tras elegir el 3, la suma 3 supera 1, y la poda corta; pero `3 + (−2) = 1` es solución.

🗣️ **2 minutos.** La hipótesis del lema de factibilidad es que la violación no se puede arreglar más abajo. Con pesos no negativos, la suma solo sube, y la hipótesis vale; con negativos, falla. La corrección: ordenar, y usar como cota la suma de los negativos restantes («aun sumando todos los negativos que quedan, ¿bajo hasta el objetivo?»).

🔬 **El detalle.** Es el ejemplo de manual de una poda que parece obvia y es incorrecta. Antes de escribir una poda, se enuncia la implicación que la justifica y se busca su contraejemplo.

**03 → 9.** ¿Por qué el orden de las decisiones (MRV en el sudoku) cambia el tiempo y no la corrección? 🟠

⏱️ **30 segundos.** Porque el árbol que se recorre depende del orden de las decisiones, pero las hojas válidas son las mismas: rellenar primero la casilla con menos candidatos ramifica menos y descubre antes las contradicciones.

🗣️ **2 minutos.** Una casilla con un candidato no ramifica; una sin candidatos poda en el acto. Si se elige primero una casilla con nueve candidatos, se multiplican por nueve las ramas antes de descubrir la contradicción que la casilla vacía de candidatos ya delataba. El conjunto de soluciones no cambia, porque toda solución sigue siendo una hoja de cualquier orden.

🔬 **El detalle.** MRV (*minimum remaining values*) viene de la satisfacción de restricciones (Russell y Norvig, cap. 6). Su gemela para valores es probar primero el valor que menos restringe a los vecinos.

**03 → 10.** ¿Por qué la mochila fraccionaria es una cota válida para la mochila 0/1, y por qué conviene explorar primero el objeto con mejor razón? 🟠

⏱️ **30 segundos.** Porque permitir fracciones relaja el problema: toda solución entera es también fraccionaria, así que el óptimo fraccionario es mayor o igual. Explorar primero el objeto con mejor razón encuentra pronto una buena solución, que poda más.

🗣️ **2 minutos.** La cota de un nodo es su valor más la mochila fraccionaria del resto, que se resuelve con un voraz por razón en `O(n)` ([`11/03`](../11-voraces/03-plazos-huffman-y-monedas.md)). Al explorar en ese orden, la primera hoja suele estar cerca del óptimo, y con un `mejor` alto casi todas las cotas quedan por debajo.

🔬 **El detalle.** Es el patrón general: la cota sale de una **relajación** (quitar una restricción) que se resuelve rápido. Para el viajante, el árbol de expansión mínima; para problemas enteros, la programación lineal.

**03 → 11.** Demuestra el lema de la poda por factibilidad: podar los nodos con `P` falso no pierde ninguna solución. 🟠

⏱️ **30 segundos.** Toda solución válida es una hoja cuyo camino desde la raíz solo pasa por nodos con `P` cierto, porque si alguno tuviera `P` falso, ninguna de sus extensiones —incluida esa hoja— sería válida. Ese camino nunca se poda.

🗣️ **2 minutos.** Por contradicción: si una solución válida `s` se perdiera, algún ancestro `x` de `s` se habría podado, así que `P(x)` es falso. Por la hipótesis sobre `P`, ninguna extensión de `x` es válida; pero `s` extiende a `x` y es válida. Contradicción.

🔬 **El detalle.** El lema traslada la carga de la prueba a la hipótesis sobre `P`: «si `P(x)` es falso, ninguna extensión es válida». Eso es lo que se demuestra en cada problema, y lo que falla con pesos negativos (pregunta 8).

**03 → 12.** Da una familia de entradas de suma de subconjuntos en la que las dos podas de la plantilla no evitan recorrer un árbol exponencial. 🔴

⏱️ **30 segundos.** `n` pesos iguales a 2 y un objetivo impar menor que la suma, por ejemplo `n − 1` con `n` par. Ninguna rama alcanza el objetivo, y las podas solo cortan cuando la suma se pasa o lo que queda no llega.

🗣️ **2 minutos.** Con `a = [2, 2, …, 2]` y `target = n − 1`, la poda por exceso corta cuando el resto es 1 (todo peso es 2 > 1), y la poda por defecto, cuando lo que queda no alcanza. Entre medias, se visitan todos los subconjuntos de tamaño `≤ (n − 2)/2` que no se pasan: del orden de `2ⁿ⁻¹` nodos.

🔬 **El detalle.** Una comprobación de paridad lo resolvería, pero siempre hay otra familia adversaria: la suma de subconjuntos es NP-completa, y ninguna poda la vuelve polinomial salvo que P = NP. Lo que sí la vuelve manejable es una DP en `n · target` cuando el objetivo es pequeño ([`12/03`](../12-dp-clasica/03-mochilas.md)).

**03 → 13.** Tu *backtracking* de sopa de letras encuentra palabras que no existen en la rejilla. ¿Qué miras primero y por qué? 🔴

⏱️ **30 segundos.** Que cada casilla se **marca** como usada al entrar en ella. Si no se marca, el camino puede volver sobre una casilla y usar la misma letra dos veces: «ABA» aparece con una sola `A` y una `B` al lado.

🗣️ **2 minutos.** Las palabras falsas indican caminos que reutilizan casillas, es decir, que falta la marca o se comprueba tarde. El fallo simétrico, no **desmarcar** al volver, da lo contrario: palabras que existen y no se encuentran, porque las casillas quedan bloqueadas para las ramas hermanas.

🔬 **El detalle.** El caso de prueba que delata los dos errores es la rejilla de una fila `A B` con las palabras «ABA» (no debe estar) y, partiendo de la otra punta, «BA» (debe estar aunque una búsqueda anterior pasara por la `A`).

**03 → Problema: Sumandos distintos.**

- **Pista 2 — patrón:** **combinaciones con índice de inicio y poda por la suma**: el siguiente sumando siempre es mayor que el anterior.
- **Pista 3 — diseño:** `backtrack(siguiente mínimo, faltan, resto)`: si `faltan = 0`, imprime si `resto = 0`. Poda por exceso: el menor valor posible para los `faltan` sumandos es `x + (x + 1) + …`, y si supera `resto`, corta. Poda por defecto: si ni con los mayores posibles se llega, corta.

**03 → Problema: Cuadro latino incompleto.**

- **Pista 2 — patrón:** ***backtracking* con marcas por fila y por columna**, probando los valores de menor a mayor.
- **Pista 3 — diseño:** recorre las casillas en orden de filas; en una vacía, prueba `v = 1..n` si `v` no está en su fila ni en su columna (dos matrices de booleanos), marca, recurre, desmarca. La primera rejilla completa es la menor lexicográfica porque se prueban los valores en orden. Comprueba antes que las casillas dadas no se contradigan.

**03 → Problema: Exámenes en pocos días.**

- **Pista 2 — patrón:** **coloración de grafos por *backtracking***, probando `d = 1, 2, …` días.
- **Pista 3 — diseño:** para cada `d`, intenta asignar a cada examen, en orden, un día que no use ningún vecino ya asignado; deshaz al volver. El primer `d` con éxito es la respuesta. Poda por simetría: el examen `i` no necesita probar más que un día «nuevo» (el menor no usado todavía).

**03 → Problema: Generate Parentheses.**

- **Pista 2 — patrón:** ***backtracking* con dos contadores**, abiertos y cerrados.
- **Pista 3 — diseño:** puedes añadir `(` si quedan por abrir; puedes añadir `)` si hay más abiertos que cerrados. Con las dos reglas, toda hoja de longitud `2n` es válida y no hace falta comprobar al final.

**03 → Problema: Combination Sum.**

- **Pista 2 — patrón:** **combinaciones con repetición** y poda por exceso.
- **Pista 3 — diseño:** ordena; `backtrack(start, rem)`: para `j` desde `start`, si `c[j] > rem` corta; si no, recurre con `j` (no `j + 1`, porque se puede repetir) y `rem − c[j]`.

**03 → Problema: Combination Sum II.**

- **Pista 2 — patrón:** **la plantilla de la suma de subconjuntos** con la regla de iguales.
- **Pista 3 — diseño:** ordena; recurre con `j + 1`; en un mismo nivel, salta `c[j]` si `j > start` y `c[j] = c[j − 1]`. Las dos podas de la plantilla valen porque los valores son positivos.

**03 → Problema: Word Search.**

- **Pista 2 — patrón:** ***backtracking* en rejilla con marcas**.
- **Pista 3 — diseño:** desde cada casilla con la primera letra, `dfs(f, c, k)`: si `k` es la longitud, éxito; si la casilla no coincide con `palabra[k]` o está marcada, falla; marca, prueba los cuatro vecinos con `k + 1`, desmarca.

**03 → Problema: Palindrome Partitioning.**

- **Pista 2 — patrón:** ***backtracking* sobre el siguiente corte**.
- **Pista 3 — diseño:** `backtrack(i)`: para cada `j ≥ i` con `s[i..j]` palíndromo, añade el trozo, recurre en `j + 1` y quítalo. Precalcular una tabla `pal[i][j]` evita repetir comprobaciones.

**03 → Problema: Restore IP Addresses.**

- **Pista 2 — patrón:** ***backtracking* sobre cortes con poda por longitud**.
- **Pista 3 — diseño:** cuatro trozos de 1 a 3 dígitos, cada uno en `[0, 255]` y sin ceros a la izquierda salvo el propio `0`. Poda: con `r` dígitos y `t` trozos por poner, hace falta `t ≤ r ≤ 3t`.

**03 → Problema: Crossword Puzzle.**

- **Pista 2 — patrón:** ***backtracking* sobre las palabras**, colocando cada una en un hueco compatible y deshaciendo.
- **Pista 3 — diseño:** extrae los huecos (posición, dirección, longitud); para la siguiente palabra, prueba cada hueco libre de su longitud donde las letras ya puestas coincidan; escribe, recurre y restaura las casillas que eran `-`. Con 10 palabras como mucho, el árbol es pequeño.

**03 → Problema: Sudoku Solver.**

- **Pista 2 — patrón:** ***backtracking* con marcas** por fila, columna y caja, y orden MRV.
- **Pista 3 — diseño:** tres matrices `fila[r][v]`, `col[c][v]`, `caja[b][v]` con `b = 3(r/3) + c/3`. Elige la casilla vacía con menos candidatos, prueba cada candidato marcando y desmarcando, y para en la primera solución.

**03 → Problema: Path with Maximum Gold.**

- **Pista 2 — patrón:** ***backtracking* en rejilla** desde cada casilla con oro.
- **Pista 3 — diseño:** `dfs(f, c)` devuelve el máximo oro desde ahí: guarda el valor, pon la casilla a 0 (la marca), toma el máximo de los vecinos con oro, restaura el valor. Con a lo sumo 25 casillas con oro, cabe.

**03 → Problema: Matchsticks to Square.**

- **Pista 2 — patrón:** **repartir en cuatro lados con *backtracking*** y podas.
- **Pista 3 — diseño:** el lado es `suma / 4` (si no es entero, falso); ordena de mayor a menor; coloca cada cerilla en un lado que no se pase; poda por simetría: si dos lados tienen la misma longitud actual, prueba solo uno.

**03 → Problema: Partition to K Equal Sum Subsets.**

- **Pista 2 — patrón:** **repartir en `k` cubos con *backtracking***, el mismo de Matchsticks generalizado.
- **Pista 3 — diseño:** objetivo `suma / k`; números de mayor a menor (las podas actúan antes); para cada número, cubos con hueco suficiente, saltando cubos con la misma carga ya probada en ese nivel; si un cubo vacío falla, los demás vacíos también.

**03 → Problema: Expression Add Operators.**

- **Pista 2 — patrón:** ***backtracking* sobre los operadores** llevando el valor y el **último término**.
- **Pista 3 — diseño:** `backtrack(i, valor, último)`: para cada corte del siguiente número `x` (sin ceros a la izquierda), prueba `+` (`valor + x`, último `x`), `−` (`valor − x`, último `−x`) y `*` (`valor − último + último · x`, último `último · x`). Usa 64 bits.

**03 → Problema: Grid Path Description.**

- **Pista 2 — patrón:** ***backtracking* con podas topológicas** fuertes; sin ellas, el árbol es enorme.
- **Pista 3 — diseño:** además de respetar los caracteres fijos: llegar a la casilla final antes del último paso, corta; si el camino choca con una pared (o casilla visitada) delante y puede girar a izquierda y derecha, partió la rejilla en dos y corta; marca y desmarca con una matriz con borde.

---

# 04 — *Meet in the middle*, IDDFS y *Dancing Links*

**04 → 1.** ¿Cuántos pasos cuesta *meet in the middle* con `n = 40`, y cuánta memoria? 🟢

⏱️ **30 segundos.** Unos `2·10⁷` pasos: dos mitades de `2²⁰ ≈ 10⁶` sumas, ordenar una y una búsqueda binaria de 20 pasos por cada suma de la otra. Memoria, `2 · 2²⁰` enteros de 64 bits: 16 MB.

🗣️ **2 minutos.** Enumerar cada mitad cuesta `2²⁰` con las sumas incrementales; ordenar, `2²⁰ · 20`; combinar, otras `2²⁰ · 20`. Frente a `2⁴⁰ ≈ 1,1·10¹²`, es un factor de unas `5·10⁴`.

🔬 **El detalle.** La memoria es el límite real: con `n = 50` serían `2²⁵ ≈ 3,3·10⁷` sumas por mitad, 270 MB en `long`, por encima del límite habitual.

**04 → 2.** ¿Qué garantiza IDDFS con coste unitario, y cuánta memoria usa? 🟢

⏱️ **30 segundos.** Encuentra una meta a la menor profundidad, igual que un BFS, y usa la memoria de un DFS: `O(d)` para el camino actual, o `O(b · d)` si se guardan los hermanos pendientes.

🗣️ **2 minutos.** Cada iteración es un DFS con límite `L` que recorre todos los nodos a profundidad `≤ L`; la primera con éxito es la de la profundidad mínima. No guarda visitados ni la frontera de un nivel, que en un BFS puede ser de `bᵈ` estados.

🔬 **El detalle.** La garantía exige coste unitario por arista; con costes distintos, la versión análoga es IDA\*, que itera sobre un umbral de `f = g + h` en lugar de la profundidad ([`15/03`](../15-grafos-pesos-y-flujos/03-a-estrella.md)).

**04 → 3.** ¿Qué es la cobertura exacta, y cómo se escribe un sudoku como cobertura exacta? 🟢

⏱️ **30 segundos.** Elegir filas de una matriz 0/1 tal que cada columna tenga exactamente un 1 entre las filas elegidas. En el sudoku, cada fila es «el número `v` en la casilla `(r, c)`» y las columnas son las 324 restricciones.

🗣️ **2 minutos.** Hay 729 filas (`9 · 9` casillas por 9 números) y cuatro familias de 81 columnas: «la casilla `(r, c)` tiene número», «la fila `r` tiene el `v`», «la columna `c` tiene el `v`», «la caja `b` tiene el `v`». Cada fila de la matriz tiene exactamente cuatro unos. Las casillas dadas fijan filas de antemano.

🔬 **El detalle.** La misma traducción vale para las N reinas, con columnas «secundarias» para las diagonales (que se cubren como mucho una vez), y para teselar con pentominós.

**04 → 4.** ¿Qué condición tiene que cumplir un problema para poder partirlo en dos mitades? Da uno que se parta y uno que no. 🟡

⏱️ **30 segundos.** Que la solución se descomponga en dos partes independientes y que, fijada una parte, la mejor pareja se pueda **buscar** en las soluciones de la otra con una tabla o una búsqueda ordenada. Se parte: «suma ≤ S», «XOR igual a x». No se parte: «ningún par de elegidos son vecinos en un grafo» con aristas entre las dos mitades.

🗣️ **2 minutos.** La consulta para cada `x` tiene que depender de `x` a través de un resumen pequeño: su suma, su XOR, su resto. Si la compatibilidad depende de qué elementos concretos tiene `x` (y hay muchas aristas cruzadas), el resumen es el subconjunto entero y no hay nada que buscar.

🔬 **El detalle.** El caso intermedio se arregla con estado de frontera: si solo importa qué elementos de la izquierda están junto a la derecha, se agrupa por esa frontera (pocos bits) y se busca dentro de cada grupo.

**04 → 5.** ¿En qué se diferencian IDDFS y BFS en tiempo, memoria y estados repetidos? 🟡

⏱️ **30 segundos.** En tiempo, los dos son `O(bᵈ)`, con IDDFS un factor `(b/(b − 1))²` más lento. En memoria, BFS `O(bᵈ)` e IDDFS `O(d)`. BFS detecta estados repetidos con su conjunto de visitados; IDDFS no.

🗣️ **2 minutos.** Si el espacio de estados es un grafo con muchos ciclos y los estados caben en memoria, BFS gana: no repite. Si es un árbol enorme o infinito y la solución es poco profunda, IDDFS gana porque BFS se queda sin memoria.

🔬 **El detalle.** IDDFS puede evitar los ciclos cortos sin memoria global (no volver al padre, o al camino actual); los repetidos por caminos distintos no los evita.

**04 → 6.** ¿Qué hace barato el «restaurar» en *Dancing Links*? 🟡

⏱️ **30 segundos.** Que un nodo quitado de una lista doblemente enlazada conserva sus propios punteros, así que se reinserta con `x.left.right = x` y `x.right.left = x`, en `O(1)`, si se restaura en orden inverso al de la eliminación.

🗣️ **2 minutos.** El *backtracking* elimina columnas y filas al elegir, y las restaura al volver en el orden exactamente inverso; con ese orden, los vecinos a los que apuntan los punteros del nodo quitado vuelven a estar en su sitio cuando le toca. No hace falta copiar la matriz en cada nivel.

🔬 **El detalle.** El truco es de Hitotumatu y Noshita (1979); Knuth lo popularizó en «Dancing Links» (2000). Funciona porque el deshacer es estrictamente en pila.

**04 → 7.** ¿Por qué buscar con dos punteros sobre las dos mitades ordenadas quita el `log` de la combinación? 🟠

⏱️ **30 segundos.** Porque con las dos mitades ordenadas, cuando `x` crece la mejor pareja `y` solo puede bajar: un puntero recorre la izquierda hacia arriba y otro la derecha hacia abajo, y cada uno avanza `2^(n/2)` veces en total.

🗣️ **2 minutos.** Para «la mayor `x + y ≤ S`»: `i` al principio de la izquierda, `j` al final de la derecha; mientras `x[i] + y[j] > S`, baja `j`; registra `x[i] + y[j]`; sube `i`. La combinación es lineal, y el coste total queda en ordenar: `O(2^(n/2) · n)` igual, pero con la constante más baja.

🔬 **El detalle.** Las sumas de una mitad se pueden generar ya ordenadas, sin `sort`, mezclando: al añadir el elemento `a`, se mezclan la lista ordenada `L` y `L + a`, que también está ordenada. Así enumerar y ordenar cuesta `O(2^(n/2))` en total.

**04 → 8.** ¿Cómo cuentas los subconjuntos con suma exacta `S` con *meet in the middle*, y qué cambia en C++, Java y Python? 🟠

⏱️ **30 segundos.** Se ordena la derecha y, para cada `x` de la izquierda, se suman las apariciones de `S − x` con `upper_bound − lower_bound`; o se cuentan las sumas de la derecha en un mapa hash. En C++ con `equal_range`, en Java con dos binarias propias o un `HashMap<Long, Integer>`, en Python con `bisect` o `Counter`.

🗣️ **2 minutos.** El mapa hash es `O(1)` esperado por consulta pero con `2²⁰` claves en Java pesa por el *boxing* (decenas de MB) y es atacable con *anti-hash* en jueces con *hacks* ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)). La versión ordenada es determinista y compacta. En Python, `Counter` sobre un millón de sumas cabe, pero la enumeración ya cuesta un segundo: conviene la mezcla ordenada.

🔬 **El detalle.** El resultado puede pasar de `2³¹`: con todas las sumas iguales, hay `2⁴⁰` subconjuntos que cuentan. Acumula en 64 bits.

**04 → 9.** Deriva el sobrecoste de IDDFS frente a BFS para un factor de ramificación `b`. 🟠

⏱️ **30 segundos.** El nodo a profundidad `i` se genera en las iteraciones `L = i, …, d`, es decir `d − i + 1` veces. El total `Σ (d − i + 1) bⁱ` es `bᵈ · Σ_k (k + 1) b⁻ᵏ ≤ bᵈ · (b/(b − 1))²`.

🗣️ **2 minutos.** Con `k = d − i`, la suma es `bᵈ · Σ_{k ≥ 0} (k + 1)(1/b)ᵏ`, y `Σ (k + 1) rᵏ = 1/(1 − r)²` con `r = 1/b`. Para `b = 10`, `(10/9)² ≈ 1,23`; para `b = 2`, 4.

🔬 **El detalle.** Un BFS genera `Σ bⁱ ≈ bᵈ · b/(b − 1)` nodos, así que la razón IDDFS/BFS es `b/(b − 1)`: 1,11 con `b = 10`. Lo que se compra con ese 11 % es pasar de memoria exponencial a lineal.

**04 → 10.** ¿Por qué la poda «ni doblando se llega» de la cadena de sumas es una cota inferior válida? 🟠

⏱️ **30 segundos.** Porque el mayor término que se puede añadir es el doble del último, así que tras `r` pasos el último término vale como mucho `último · 2ʳ`. Si eso no llega al objetivo, ninguna extensión dentro del límite llega.

🗣️ **2 minutos.** Cada nuevo término es `cᵢ + cⱼ ≤ 2 · último`, y la cadena es creciente, así que el máximo crece a lo sumo al doble por paso. Es una cota optimista de lo alcanzable: si la optimista no llega, la real tampoco. Es el lema de la poda por cota de `10/03` aplicado a la profundidad.

🔬 **El detalle.** Con esta poda, las iteraciones con `L < ⌈log₂ n⌉` mueren en la raíz; las cotas más finas (por el número de unos en binario de `n`) podan más y son las que usan las búsquedas serias de cadenas óptimas.

**04 → 11.** ¿Qué tiene en común el BFS bidireccional con *meet in the middle*, y cuánto ahorra? 🟠

⏱️ **30 segundos.** Los dos parten el problema por la mitad: el BFS bidireccional busca desde el inicio y desde la meta hasta que las fronteras se tocan. Explora `2 · b^(d/2)` estados en lugar de `bᵈ`.

🗣️ **2 minutos.** Un camino de longitud `d` es la unión de uno de longitud `⌈d/2⌉` desde el inicio y uno de `⌊d/2⌋` hacia atrás desde la meta; la «búsqueda de pareja» es comprobar si un estado está en la frontera del otro lado, con una tabla hash. Con `b = 10` y `d = 10`, de `10¹⁰` a `2·10⁵`.

🔬 **El detalle.** Exige poder generar los predecesores (movimientos reversibles) y conocer el estado meta concreto. Knights in Fen es el ejemplo típico: profundidad máxima 10, cinco desde cada lado.

**04 → 12.** Repartir 30 números en dos grupos de 15 con sumas lo más parecidas posible: diseña la solución y di su coste. 🔴

⏱️ **30 segundos.** *Meet in the middle* agrupado por tamaño: para cada mitad de 15 números, las sumas de sus subconjuntos agrupadas por cuántos elementos usan. Si la izquierda pone `k` en el primer grupo, la derecha pone `15 − k`. Coste `O(2¹⁵ · 15)` aproximadamente.

🗣️ **2 minutos.** Con `T` la suma total, se busca la suma `s` del primer grupo más cercana a `T/2`. Para cada `k` y cada suma `x` de la izquierda con `k` elementos, se busca en la lista ordenada de la derecha con `15 − k` elementos la suma más cercana a `T/2 − x`. Las listas suman `2¹⁵` entradas por lado; ordenarlas y buscar cuesta `2¹⁵ · 15`.

🔬 **El detalle.** La diferencia es `|T − 2s|`; para minimizarla se busca `s` cerca de `T/2`, y con `T` impar las dos vecinas cuentan. Es el problema de LeetCode Partition Array Into Two Arrays to Minimize Sum Difference.

**04 → 13.** Tu *meet in the middle* da una respuesta mayor que la de la fuerza bruta en entradas con negativos. ¿Qué pasa? 🔴

⏱️ **30 segundos.** Que la plantilla asume que la suma vacía (0) es la menor de la derecha y siempre cabe. Con negativos, `right[0]` puede ser negativo y la búsqueda puede no encontrar ninguna `y ≤ S − x`, y `prev(it)` lee fuera del arreglo.

🗣️ **2 minutos.** Si `upper_bound` devuelve el principio, no hay pareja válida para ese `x`, y hay que saltarlo; leer `*prev(begin)` es comportamiento indefinido en C++ y en Java un índice `−1`. Además, `if (x > S) continue` ya no es correcto: con negativos en la derecha, una `x > S` sí puede tener pareja.

🔬 **El detalle.** La regla general: cada atajo de una plantilla lleva una hipótesis (aquí, pesos no negativos), y el *stress test* contra la fuerza bruta con entradas fuera de la hipótesis es lo que la delata ([`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md)).

**04 → Problema: Balanza de pesas.**

- **Pista 2 — patrón:** ***meet in the middle* con tres opciones por elemento**: `3²⁴` no cabe, `3¹²` sí.
- **Pista 3 — diseño:** para cada mitad, todas las diferencias posibles (cada peso con `+`, `−` o `0`): `3¹² = 531 441` valores. Ordena la derecha y, para cada diferencia `l` de la izquierda, cuenta las `r = D − l` con `upper_bound − lower_bound`. Diferencias y resultado en 64 bits.

**04 → Problema: Subconjuntos con XOR dado.**

- **Pista 2 — patrón:** ***meet in the middle* con una tabla de frecuencias** de los XOR de la derecha.
- **Pista 3 — diseño:** cuenta en un mapa (o en un arreglo ordenado) los XOR de los `2²⁰` subconjuntos de la derecha; para cada XOR `l` de la izquierda, suma la frecuencia de `l ⊕ x`. Respuesta en 64 bits. Alternativa sin enumerar: la base lineal sobre GF(2) ([`17/07`](../17-matematica/07-matrices-y-gauss.md)) da `2^(n − rango)` si `x` está en el espacio generado.

**04 → Problema: Tortitas.**

- **Pista 2 — patrón:** **búsqueda del camino más corto en el espacio de estados**: BFS sobre las `8!` ordenaciones, o IDDFS con una cota.
- **Pista 3 — diseño:** el estado es la tupla de la pila; los vecinos, los `n − 1` volteos. Con BFS y un mapa de visitados, `8! = 40 320` estados. Con IDDFS, una cota inferior es el número de pares adyacentes que no son vecinos en el orden final (cada volteo arregla como mucho uno). Con tamaños repetidos, la meta es la tupla ordenada.

**04 → Problema: Meet in the Middle.**

- **Pista 2 — patrón:** ***meet in the middle* para contar sumas exactas**.
- **Pista 3 — diseño:** sumas de cada mitad (`2²⁰`); ordena la derecha y cuenta las apariciones de `x − l` para cada `l`, o recorre las dos ordenadas con dos punteros agrupando iguales. Evita los mapas hash (son lentos con un millón de claves). Respuesta en 64 bits.

**04 → Problema: Closest Subsequence Sum.**

- **Pista 2 — patrón:** ***meet in the middle*** con búsqueda de la suma más cercana.
- **Pista 3 — diseño:** sumas de las dos mitades; ordena la derecha; para cada `l`, busca con *lower bound* `goal − l` y mira el candidato encontrado y el anterior. Con dos punteros sobre las dos ordenadas, la combinación es lineal.

**04 → Problema: Partition Array Into Two Arrays to Minimize Sum Difference.**

- **Pista 2 — patrón:** ***meet in the middle* agrupado por tamaño**.
- **Pista 3 — diseño:** para cada mitad, listas de sumas por número de elementos usados; para cada `k`, combina la lista `k` de la izquierda con la `n − k` de la derecha buscando la suma más cercana a `total/2`. La diferencia es `|total − 2s|`.

**04 → Problema: Sliding Puzzle.**

- **Pista 2 — patrón:** **camino más corto en el espacio de estados**, con BFS (o IDDFS / IDA\*).
- **Pista 3 — diseño:** el estado es la cadena de 6 caracteres; el vecino, intercambiar el `0` con una casilla adyacente; BFS con visitados sobre los `6! = 720` estados. Si la meta no se alcanza, `-1`.

**04 → Problema: Split Array With Same Average.**

- **Pista 2 — patrón:** **suma por tamaño** (DP o *meet in the middle*): una parte de `k` elementos tiene la media global si suma `total · k / n`.
- **Pista 3 — diseño:** para cada `k` de 1 a `n/2` con `total · k mod n = 0`, hace falta un subconjunto de `k` elementos con suma `total · k / n`. Con *meet in the middle*, sumas por tamaño en cada mitad y búsqueda de la pareja; o una DP de conjuntos de sumas por tamaño con poda.

**04 → Problema: Maximum Subsequence.**

- **Pista 2 — patrón:** ***meet in the middle* con restos**.
- **Pista 3 — diseño:** restos módulo `m` de las sumas de cada mitad; ordena la derecha. Para cada resto `l`, la mejor pareja es la mayor `r ≤ m − 1 − l` (sin dar la vuelta), o si no la mayor de todas (dando la vuelta, que nunca es mejor que la otra si existe). Dos candidatos por `l`.

**04 → Problema: Knights in Fen.**

- **Pista 2 — patrón:** **búsqueda bidireccional** (o IDDFS con poda) con profundidad máxima 10.
- **Pista 3 — diseño:** desde el tablero inicial y desde el tablero meta, todos los estados a ≤ 5 movimientos del hueco, en mapas de distancia; la respuesta es el mínimo de `d₁ + d₂` sobre estados comunes, si es ≤ 10. Con IDDFS, la cota inferior es el número de piezas fuera de su sitio.

**04 → Problema: Xor-Paths.**

- **Pista 2 — patrón:** ***meet in the middle* sobre caminos** en la rejilla.
- **Pista 3 — diseño:** los caminos de `(1,1)` a `(n,m)` cruzan la antidiagonal `i + j = (n + m)/2 + 1` una vez. Recorre desde el inicio hasta esa antidiagonal guardando, por casilla, un mapa XOR → cuenta; recorre hacia atrás desde el final hasta ella y suma las cuentas del XOR complementario, cuidando de no contar dos veces el valor de la casilla de cruce.

**04 → Problema: Anya and Cubes.**

- **Pista 2 — patrón:** ***meet in the middle* con tres opciones** y número de pegatinas.
- **Pista 3 — diseño:** cada cubo: fuera, dentro, o dentro con pegatina (valor `aᵢ!`, solo si `aᵢ ≤ 18`, porque `19! > 10¹⁶`). Enumera cada mitad guardando (suma, pegatinas usadas); en la derecha, agrupa por suma un arreglo de cuentas por número de pegatinas acumulado; para cada estado de la izquierda, consulta `S − suma` con `≤ k − pegatinas`.

**04 → Problema: Sudokunique.**

- **Pista 2 — patrón:** **cobertura exacta** (algoritmo X) **contando hasta dos soluciones**.
- **Pista 3 — diseño:** traduce el sudoku a la matriz de 324 columnas; corre el algoritmo X con MRV y para en cuanto encuentre la segunda solución. Si hay una, imprímela; si hay dos, «Non-unique»; si ninguna, «Find another job».

---

# 05 — Divide y vencerás

**05 → 1.** ¿Qué tres pasos tiene el esquema de divide y vencerás, y cuál es el que se diseña? 🟢

⏱️ **30 segundos.** Partir en subproblemas del mismo tipo, resolverlos recursivamente y combinar sus respuestas. El que se diseña es la combinación.

🗣️ **2 minutos.** Partir suele ser trivial (por la mitad, por la mediana) y resolver es la recursión. La combinación decide el coste y la corrección: qué tiene que devolver cada parte para que el todo salga barato. En el subarreglo máximo, cada mitad devuelve su mejor, y la combinación calcula el que cruza.

🔬 **El detalle.** A menudo la mejora viene de que cada parte devuelva **más información** de la pedida (suma total, mejor prefijo, mejor sufijo): con eso la combinación baja de `O(n)` a `O(1)` y el total de `n log n` a `n`.

**05 → 2.** ¿Qué recurrencias tienen el par más cercano, Karatsuba y la exponenciación rápida, y qué da cada una? 🟢

⏱️ **30 segundos.** Par más cercano: `2T(n/2) + O(n)`, `O(n log n)`. Karatsuba: `3T(n/2) + O(n)`, `O(n^log₂3) ≈ O(n^1,585)`. Exponenciación: `T(n/2) + O(1)`, `O(log n)`.

🗣️ **2 minutos.** Por el teorema maestro: en el primero `f(n) = n = n^(log₂ 2)`, caso del empate, `n log n`; en Karatsuba `n^(log₂ 3)` domina a `n`, gana la recursión; en la exponenciación `n^(log₂ 1) = 1 = f(n)`, empate, `log n`.

🔬 **El detalle.** El par más cercano sin mezclar por `y` es `2T(n/2) + O(n log n)`, que el teorema maestro básico no cubre y da `O(n log² n)`.

**05 → 3.** ¿Qué significan P, NP, NP-difícil y NP-completo? 🟢

⏱️ **30 segundos.** P: decidibles en tiempo polinomial. NP: con certificado verificable en tiempo polinomial. NP-difícil: todo NP se reduce a él. NP-completo: NP-difícil y en NP.

🗣️ **2 minutos.** P ⊆ NP, porque si se resuelve rápido, se verifica rápido. NP-difícil no exige estar en NP: el problema de la parada es NP-difícil y ni siquiera es decidible. Los NP-completos son los «más difíciles de NP»: resolver uno en tiempo polinomial resolvería todos.

🔬 **El detalle.** Las clases son de problemas de **decisión**; la versión de optimización («el camino más corto que visita todas») se dice NP-difícil porque su decisión («¿hay uno de coste ≤ K?») es NP-completa.

**05 → 4.** ¿Por qué la plantilla del subarreglo máximo empieza los mejores sufijo y prefijo en `−∞` y no en 0? 🟡

⏱️ **30 segundos.** Porque el subarreglo que cruza tiene que tener al menos un elemento de cada lado. Empezando en 0, la combinación admite un «cruce» vacío, y con todos los valores negativos devolvería 0 en lugar del máximo negativo.

🗣️ **2 minutos.** El cruce es `mejor sufijo no vacío de la izquierda + mejor prefijo no vacío de la derecha`. Con `[−3, −1]`, el correcto es −1; con los mejores empezando en 0, el cruce valdría 0, que no corresponde a ningún subarreglo no vacío.

🔬 **El detalle.** Es el mismo error que el Kadane con `max(0, …)` de `01/05`: con «subarreglo no vacío» en el enunciado, el neutro no puede ser el vacío.

**05 → 5.** ¿En qué se diferencian divide y vencerás y programación dinámica? 🟡

⏱️ **30 segundos.** En divide y vencerás las partes son disjuntas y cada una se resuelve una vez; en DP los subproblemas se repiten, y se guardan para no recalcularlos.

🗣️ **2 minutos.** El *mergesort* parte en mitades que no comparten nada; Fibonacci recursivo pide `F(n − 1)` y `F(n − 2)`, y `F(n − 1)` vuelve a pedir `F(n − 2)`: subproblemas solapados. Si se aplicara divide y vencerás puro a Fibonacci, el árbol tendría `Θ(φⁿ)` nodos; con memoización, `n`.

🔬 **El detalle.** La frontera es el número de subproblemas **distintos**: en divide y vencerás es del orden del tamaño del árbol; en DP es mucho menor que el árbol, y eso es lo que se explota (`12/01`).

**05 → 6.** ¿Qué invariante mantiene la exponenciación rápida iterativa y por qué termina con la respuesta? 🟡

⏱️ **30 segundos.** `resultado · baseᵉ = aⁿ`, con `e` lo que queda del exponente. Al terminar, `e = 0`, así que `resultado = aⁿ`.

🗣️ **2 minutos.** Al empezar, `1 · aⁿ = aⁿ`. Si `e` es impar, `resultado · baseᵉ = (resultado · base) · base^(e−1)`; después, con `e` par, `baseᵉ = (base²)^(e/2)`. Las dos transformaciones conservan el producto. Termina porque `e` se divide entre 2 en cada vuelta: `⌊log₂ n⌋ + 1` vueltas.

🔬 **El detalle.** El invariante solo usa asociatividad (para reagrupar las potencias) y el neutro (el 1 inicial): por eso vale en cualquier monoide, conmutativo o no, como las matrices.

**05 → 7.** Compara qué te da cada lenguaje para `aⁿ mod m` y hasta qué `m` es segura la plantilla en C++, Java y Python. 🟡

⏱️ **30 segundos.** Python trae `pow(a, n, m)` sin límite de `m`. C++ y Java no traen potencia modular entera: la plantilla es segura con `m ≤ ~3·10⁹`, porque `base * base` tiene que caber en 64 bits con signo.

🗣️ **2 minutos.** En Java, `BigInteger.modPow` existe pero es lento para muchas consultas; con `m` hasta `10¹⁸` se usa `Math.multiplyHigh` o la multiplicación por duplicación. En C++, `__int128` en GCC y Clang (no estándar). `Math.pow` y `std::pow` son de coma flotante y no sirven para enteros exactos.

🔬 **El detalle.** En JavaScript, `a * b % m` pierde precisión por encima de `2⁵³`: con `m = 10⁹ + 7`, el producto llega a `10¹⁸` y hace falta `BigInt` ([`03/06`](../03-biblioteca-estandar/06-sin-arsenal-go-y-javascript.md)).

**05 → 8.** ¿Por qué Karatsuba hace tres multiplicaciones y no cuatro, y qué le pasa al exponente? 🟠

⏱️ **30 segundos.** Porque el término cruzado `x₁y₀ + x₀y₁` sale de `(x₁ + x₀)(y₁ + y₀) − x₁y₁ − x₀y₀`, reusando los dos productos que ya hay. El exponente baja de `log₂ 4 = 2` a `log₂ 3 ≈ 1,585`.

🗣️ **2 minutos.** Con cuatro productos de mitades, `T(n) = 4T(n/2) + O(n) = Θ(n²)`: lo mismo que el escolar. Con tres, el número de hojas del árbol de recursión pasa de `4^(log₂ n) = n²` a `3^(log₂ n) = n^(log₂ 3)`. Las sumas y restas extra son `O(n)` por nivel y no cambian el exponente.

🔬 **El detalle.** Toom-Cook generaliza partiendo en `k` trozos con `2k − 1` productos (`n^(log_k (2k−1))`), y la FFT llega a `O(n log n)`.

**05 → 9.** Enuncia el lema de la franja del par más cercano y explica por qué basta comparar con 7 vecinos. 🟠

⏱️ **30 segundos.** Si `δ` es la mejor distancia de las mitades, los pares que cruzan y mejoran están en la franja de ancho `2δ`, y ordenados por `y` cada punto solo tiene que compararse con los 7 siguientes: en un rectángulo `δ × 2δ` caben como mucho 8 puntos a distancia `≥ δ` entre sí.

🗣️ **2 minutos.** El rectángulo se parte en ocho cuadrados de lado `δ/2`; cada uno tiene diagonal `δ/√2 < δ`, así que contiene como mucho un punto (dos puntos del mismo lado de la línea están a `≥ δ`). Un punto con `dy ≥ δ` respecto del actual ya no puede mejorar, y por el orden en `y`, tampoco los siguientes.

🔬 **El detalle.** La constante 7 depende de la prueba; versiones más finas bajan a 5 o 6, pero da igual: lo que importa es que es constante y la combinación es lineal. Kleinberg y Tardos, §5.4.

**05 → 10.** ¿Por qué la mochila con DP `O(n · W)` no demuestra que P = NP? 🟠

⏱️ **30 segundos.** Porque `O(n · W)` es polinomial en el **valor** de `W`, no en el **tamaño** de la entrada: `W` se escribe con `log W` bits, y `W = 2^(log W)` es exponencial en ese tamaño. Es pseudopolinomial.

🗣️ **2 minutos.** Una entrada con `W = 10¹⁸` ocupa 60 bits y la DP haría `10¹⁸` pasos por objeto. La mochila es NP-completa en su versión de decisión; la DP solo es rápida cuando los números son pequeños.

🔬 **El detalle.** Los problemas NP-completos que admiten algoritmos pseudopolinomiales se llaman débilmente NP-completos (mochila, partición, suma de subconjuntos); los que siguen siendo difíciles con números pequeños, fuertemente NP-completos (3-partición, el viajante).

**05 → 11.** Te piden el camino simple más largo de un grafo con `n ≤ 16`. ¿Qué dices y qué escribes? 🟠

⏱️ **30 segundos.** Que es NP-difícil (contiene al camino hamiltoniano), así que no busco un voraz; con `n ≤ 16`, DP sobre máscaras: `dp[S][v]` = la mayor longitud de un camino que visita exactamente `S` y acaba en `v`, `O(2ⁿ · n²)`.

🗣️ **2 minutos.** Primero lo digo y explico por qué: si existiera un algoritmo polinomial, decidiría si hay un camino que pasa por todos. Después elijo el exacto exponencial en `n`: `2¹⁶ · 16² ≈ 1,7·10⁷`. O *backtracking* desde cada vértice, que con 16 vértices también cabe si el grafo no es denso.

🔬 **El detalle.** Si el grafo es un DAG, el camino más largo es polinomial con orden topológico ([`14/04`](../14-grafos-recorridos/04-orden-topologico.md)): la estructura del grafo cambia la clase del problema.

**05 → 12.** Da dos pares de problemas gemelos, uno polinomial y otro NP-difícil, y di qué cambia entre ellos. 🟠

⏱️ **30 segundos.** Euler (cada arista una vez) es polinomial y Hamilton (cada vértice una vez) es NP-completo. 2-SAT es polinomial y 3-SAT es NP-completo.

🗣️ **2 minutos.** Euler se decide con una condición local: grados pares y conexión. Hamilton no tiene condición local conocida. 2-SAT se resuelve con componentes fuertes del grafo de implicaciones ([`14/05`](../14-grafos-recorridos/05-componentes-fuertes-y-2sat.md)); con tres literales por cláusula, ese grafo no existe.

🔬 **El detalle.** Otros pares: camino más corto frente a camino simple más largo; 2-colorear (bipartito) frente a 3-colorear; árbol de expansión mínima frente a Steiner.

**05 → 13.** Demuestra que el esquema del subarreglo máximo es correcto: que la combinación cubre todos los subarreglos. 🔴

⏱️ **30 segundos.** Por inducción sobre la longitud: todo subarreglo de `[lo, hi)` está entero en `[lo, mid)`, entero en `[mid, hi)`, o contiene `mid − 1` y `mid`. Los dos primeros los cubre la hipótesis; el tercero es un sufijo de la izquierda más un prefijo de la derecha, y la combinación toma el mejor de cada uno.

🗣️ **2 minutos.** Caso base: un elemento, el único subarreglo es él. Paso: si el subarreglo óptimo cruza, se escribe como `a[i..mid−1] + a[mid..j]` con `i ≤ mid − 1 < mid ≤ j`; su suma es la de ese sufijo más la de ese prefijo, que son a lo sumo `leftBest` y `rightBest`; y la pareja `leftBest + rightBest` corresponde a un subarreglo que cruza. Luego el máximo de los tres candidatos es el óptimo.

🔬 **El detalle.** La clave es que sufijo y prefijo se eligen **independientemente**: el mejor cruce es la suma de los dos mejores. Si la condición los acoplara (por ejemplo, longitud total fija), la combinación necesitaría más información.

**05 → 14.** Diseña un algoritmo `O(log n)` para `1 + a + a² + … + aⁿ⁻¹ mod m` cuando `m` no es primo y no puedes dividir por `a − 1`. 🔴

⏱️ **30 segundos.** Divide y vencerás sobre `n`: `S(2k) = S(k) · (1 + aᵏ)` y `S(k + 1) = 1 + a · S(k)`. Con `aᵏ` por exponenciación rápida (o llevándolo junto), son `O(log n)` pasos sin dividir.

🗣️ **2 minutos.** `1 + a + … + a^(2k−1) = (1 + … + a^(k−1)) + aᵏ (1 + … + a^(k−1))`. Si `n` es impar, se quita un término. La recursión devuelve el par `(S(k), aᵏ)` para no recalcular la potencia: `O(log n)` en total.

🔬 **El detalle.** La alternativa es una potencia de la matriz `[[a, 1], [0, 1]]`, que lleva el par `(aᵏ, S(k))` en una columna ([`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md)). La fórmula `(aⁿ − 1)/(a − 1)` exige inverso de `a − 1` módulo `m`, que no existe si no son coprimos.

**05 → Problema: Serie geométrica.**

- **Pista 2 — patrón:** **divide y vencerás sobre `n`**, con la potencia al lado: no se puede dividir por `a − 1` porque `m` no es primo.
- **Pista 3 — diseño:** una función que devuelva el par `(S(n), aⁿ mod m)`: `S(0) = 0`; si `n` es par, `S(n) = S(n/2) · (1 + a^(n/2))`; si es impar, `S(n) = 1 + a · S(n − 1)`. Productos en 64 bits con `m ≤ 10⁹`.

**05 → Problema: Equipo de guardia.**

- **Pista 2 — patrón:** **cubrir conjuntos**, NP-difícil; el parámetro pequeño es `e ≤ 20`: **enumerar subconjuntos de empleados** con máscaras.
- **Pista 3 — diseño:** la habilidad de cada empleado como máscara de 64 bits (`k ≤ 60`); para cada máscara de empleados, el OR incremental de sus habilidades; la respuesta es el menor `popcount` cuya unión es la máscara completa. `2²⁰` máscaras.

**05 → Problema: Power - Mod Power.**

- **Pista 2 — patrón:** **potencia modular de la biblioteca**.
- **Pista 3 — diseño:** `pow(a, b)` y `pow(a, b, m)`; el tercer argumento hace la exponenciación rápida con módulo sin construir el número entero.

**05 → Problema: Maximum Subarray.**

- **Pista 2 — patrón:** **divide y vencerás con cruce** (o Kadane, que es mejor).
- **Pista 3 — diseño:** la plantilla de §3; para el seguimiento del enunciado, la versión que devuelve cuatro valores por mitad (total, mejor prefijo, mejor sufijo, mejor) combina en `O(1)`.

**05 → Problema: Super Pow.**

- **Pista 2 — patrón:** **exponenciación modular sobre un exponente en dígitos**.
- **Pista 3 — diseño:** recorre los dígitos de `b`: `r = r¹⁰ · a^d mod 1337` para cada dígito `d`, con la potencia rápida. Reduce `a` módulo 1337 al principio.

**05 → Problema: Longest Substring with At Least K Repeating Characters.**

- **Pista 2 — patrón:** **divide y vencerás por los caracteres imposibles**.
- **Pista 3 — diseño:** cuenta las letras del tramo; si alguna aparece menos de `k` veces, ninguna respuesta la contiene: parte el tramo por sus apariciones y resuelve cada trozo. Si todas aparecen al menos `k`, el tramo entero vale. Profundidad como mucho 26.

**05 → Problema: Beautiful Array.**

- **Pista 2 — patrón:** **construcción por divide y vencerás**: impares a un lado, pares al otro.
- **Pista 3 — diseño:** si `A` es bonito, `2A − 1` y `2A` también (la propiedad se conserva con transformaciones afines); para `n`, une `2 · bonito(⌈n/2⌉) − 1` (impares) con `2 · bonito(⌊n/2⌋)` (pares). Un par de impar y par nunca tiene su punto medio entero.

**05 → Problema: Find a Peak Element II.**

- **Pista 2 — patrón:** **descartar media matriz** por columnas.
- **Pista 3 — diseño:** en la columna central, el máximo `M`; si su vecino izquierdo es mayor, hay un pico a la izquierda (sube desde ahí y nunca cruzas la columna); si el derecho, a la derecha; si ninguno, `M` es pico. `O(filas · log columnas)`.

**05 → Problema: Minimum Non-Zero Product of the Array Elements.**

- **Pista 2 — patrón:** **exponenciación rápida** con exponente enorme, tras un argumento voraz.
- **Pista 3 — diseño:** el producto mínimo empareja `2ᵖ − 2` con `1` repetidamente: queda `(2ᵖ − 1) · (2ᵖ − 2)^(2^(p−1) − 1)`. Reduce la base módulo `10⁹ + 7` antes de potenciar; el exponente cabe en 64 bits.

**05 → Problema: a-Good String.**

- **Pista 2 — patrón:** **divide y vencerás con coste**: dos opciones por nivel.
- **Pista 3 — diseño:** `coste(tramo, c)` = mínimo entre (cambiar la mitad izquierda a `c`, contado directamente, más `coste(derecha, c + 1)`) y lo simétrico. `T(n) = 2T(n/2) + O(n)`: `O(n log n)`.

**05 → Problema: Painting Fence.**

- **Pista 2 — patrón:** **divide y vencerás por el mínimo**.
- **Pista 3 — diseño:** `f(l, r, base)` = mínimo entre `r − l + 1` (todo en vertical) y `(min − base)` pasadas horizontales más la suma de `f` sobre los trozos separados por las tablas que llegan al mínimo. Con `n ≤ 5000`, `O(n²)`.

**05 → Problema: Smallest Sufficient Team.**

- **Pista 2 — patrón:** **cubrir conjuntos** con parámetro pequeño: hasta 16 habilidades, **DP sobre máscaras de habilidades**.
- **Pista 3 — diseño:** `dp[mask]` = el equipo más pequeño que cubre `mask`; para cada persona y cada máscara, `dp[mask | habilidades(persona)]` mejora con `dp[mask] + persona`. `2¹⁶ · 60` pasos.

**05 → Problema: Find the Shortest Superstring.**

- **Pista 2 — patrón:** **viajante disfrazado** (NP-difícil) con `n ≤ 12`: **DP sobre máscaras**.
- **Pista 3 — diseño:** `ganancia[i][j]` = el solapamiento máximo de `i` seguido de `j`; `dp[S][j]` = la mayor ganancia de un orden que usa `S` y acaba en `j`; reconstruye el orden con un arreglo de padres y concatena quitando solapamientos.

---

# 06 — Juegos y búsqueda adversarial

**06 → 1.** ¿Qué es un juego de suma cero con información perfecta, y qué devuelve minimax en cada tipo de nodo? 🟢

⏱️ **30 segundos.** Dos jugadores por turnos, sin azar, viendo todo el estado, y lo que gana uno lo pierde el otro. Minimax devuelve la utilidad en las hojas, el máximo de los hijos donde mueve MAX y el mínimo donde mueve MIN.

🗣️ **2 minutos.** El valor de la raíz es lo que MAX se asegura contra cualquier rival y lo que MIN impide superar (teorema de minimax). «Suma cero» permite usar una sola utilidad; «información perfecta», que cada nodo sea un estado conocido.

🔬 **El detalle.** Con azar (dados) aparecen nodos de esperanza (*expectiminimax*); con información oculta (cartas), el árbol pasa a ser de conjuntos de información y minimax deja de aplicarse tal cual.

**06 → 2.** ¿Qué representan `α` y `β`, y cuándo se poda? 🟢

⏱️ **30 segundos.** `α` es lo mínimo que MAX ya tiene asegurado por un camino explorado; `β`, lo máximo que MIN ya tiene asegurado. Se poda cuando `α ≥ β`.

🗣️ **2 minutos.** En un nodo de MIN, si un hijo da un valor `≤ α`, MAX nunca entrará en ese nodo porque ya tiene algo mejor: el resto de hijos sobra. En un nodo de MAX, si un hijo da `≥ β`, MIN no le dejará llegar ahí. En *negamax*, las dos reglas son la misma: `alpha ≥ beta` tras actualizar `alpha`.

🔬 **El detalle.** La ventana `(α, β)` es el intervalo de valores que todavía pueden influir en la raíz; fuera de ella, el valor exacto de un nodo no interesa.

**06 → 3.** ¿Cuántas hojas examina alfa-beta en el mejor caso y en el peor? 🟢

⏱️ **30 segundos.** En el mejor caso, `Θ(b^(d/2))` (unas `2b^(d/2)`); en el peor, `Θ(bᵈ)`, lo mismo que minimax.

🗣️ **2 minutos.** El mejor caso exige que en cada nodo el primer movimiento explorado sea el mejor: entonces cada «refutación» se demuestra con un solo hijo. Con orden aleatorio, el número esperado ronda `b^(3d/4)`.

🔬 **El detalle.** La cota exacta de Knuth y Moore para el orden perfecto es `b^⌈d/2⌉ + b^⌊d/2⌋ − 1` hojas.

**06 → 4.** ¿En qué se diferencian minimax y *negamax*, y qué exige *negamax* de la utilidad? 🟡

⏱️ **30 segundos.** Minimax distingue nodos de MAX y de MIN; *negamax* escribe una sola función que devuelve el valor para quien mueve, negando el del rival. Exige utilidad simétrica: lo que vale `v` para uno vale `−v` para el otro.

🗣️ **2 minutos.** Usa `max(a, b) = −min(−a, −b)`. La evaluación tiene que darse desde el punto de vista del jugador que mueve en ese estado, no siempre de MAX. Con alfa-beta, la ventana pasa como `(−β, −α)`.

🔬 **El detalle.** Si la utilidad no es de suma cero (cada jugador tiene su propia puntuación sin relación), ni minimax ni *negamax* modelan el juego; ahí se habla de equilibrios.

**06 → 5.** ¿Por qué un nodo podado por alfa-beta no tiene valor exacto, y qué consecuencia tiene para una tabla de transposición? 🟡

⏱️ **30 segundos.** Porque se dejó de explorar en cuanto se supo que su valor caía fuera de la ventana: solo se sabe una cota (`≤ α` o `≥ β`). Una tabla de transposición tiene que guardar si el valor es exacto, cota inferior o cota superior.

🗣️ **2 minutos.** Si se guarda la cota como si fuera exacta y el estado aparece después con otra ventana, se usa un valor que puede ser falso y el resultado de la raíz cambia. Al leer de la tabla, una cota inferior solo sirve para subir `α`, una superior para bajar `β`, y una exacta se devuelve.

🔬 **El detalle.** También importa la profundidad con que se calculó: un valor de profundidad 3 no sirve para una búsqueda que pide profundidad 5 desde ese estado.

**06 → 6.** ¿Qué cambia entre minimax hasta las hojas y minimax con límite de profundidad y evaluación? 🟡

⏱️ **30 segundos.** Hasta las hojas da el valor exacto del juego; con límite, da el valor de la función de evaluación propagado, que es tan bueno como la evaluación.

🗣️ **2 minutos.** El límite es lo que hace practicable minimax en juegos grandes, a cambio de no garantizar nada. Un error típico es el «efecto horizonte»: un desastre inevitable justo más allá del límite no se ve. La búsqueda de quietud (seguir explorando capturas) lo mitiga.

🔬 **El detalle.** Con profundización iterativa (límites 1, 2, 3…) se tiene siempre una respuesta y el mejor movimiento de la iteración anterior ordena la siguiente, que mejora la poda.

**06 → 7.** Compara cómo marcarías «no calculado» en la memoización del juego en C++, Java y Python, y qué cuesta cada forma. 🟡

⏱️ **30 segundos.** C++: un arreglo de valores y otro de `bool` (o un valor centinela imposible). Java: `Long[][]` con `null`, que cuesta *boxing*, o `long[][]` con centinela. Python: `@cache`, cómodo pero lento y con riesgo de pila.

🗣️ **2 minutos.** El centinela (por ejemplo `LLONG_MIN`) es lo más compacto, pero exige un valor que el juego nunca produzca. `Long[][]` duplica o triplica la memoria. En Python, `@cache` sobre una recursión de profundidad 2000 pasa por código en C y necesita el hilo con pila grande de `10/01`; una tabla iterativa por longitud del tramo evita todo eso.

🔬 **El detalle.** Con `n = 2000`, la tabla de tramos tiene `4·10⁶` entradas: 32 MB en `long`. Por longitudes, basta guardar la fila anterior: `O(n)` de memoria.

**06 → 8.** ¿Por qué el voraz «coge la moneda mayor de los extremos» no es óptimo? Da el contraejemplo más pequeño que encuentres. 🟠

⏱️ **30 segundos.** Porque mira solo su ganancia inmediata y no lo que destapa para el rival. El más pequeño tiene cuatro monedas: `[1, 1, 3, 2]`; el voraz coge el 2, el rival el 3, y el primero acaba con 3, cuando empezando por la izquierda se asegura 4.

🗣️ **2 minutos.** Con tres o menos monedas el voraz siempre acierta (lo comprueba la fuerza bruta sobre valores pequeños). Con cuatro, coger un extremo puede dejar a tiro la moneda grande del interior.

🔬 **El detalle.** Con un número par de monedas, el primero puede asegurarse todas las de posición par o todas las impares, así que nunca pierde; pero eso no dice cuánto gana, que es lo que pide el problema.

**06 → 9.** Explica por qué alfa-beta devuelve exactamente el valor de minimax. 🟠

⏱️ **30 segundos.** Porque solo poda un nodo cuando se demuestra que su valor no puede elegirse en el nodo de arriba: el jugador de arriba ya tiene una alternativa al menos tan buena. Las decisiones que llegan a la raíz son las mismas.

🗣️ **2 minutos.** Invariante: si el valor minimax real de un nodo está dentro de `(α, β)`, alfa-beta lo devuelve exacto; si está fuera, devuelve una cota del mismo lado. En la raíz la ventana es `(−∞, +∞)`, así que el valor es exacto. Se prueba por inducción sobre la altura, con la regla de poda: un hijo `≥ β` en un nodo de MAX hace que su valor sea `≥ β`, que es una cota del lado correcto.

🔬 **El detalle.** La prueba completa está en Knuth y Moore (1975). Lo que no se conserva es el valor de los nodos interiores podados, que por eso no se guardan como exactos.

**06 → 10.** ¿Por qué el orden de los movimientos cambia cuánto poda alfa-beta, y cómo se consigue un buen orden? 🟠

⏱️ **30 segundos.** Porque se poda cuando un hijo ya demuestra que el nodo no interesa, y eso pasa antes si el mejor hijo se explora primero. Un buen orden sale de heurísticas del juego (capturas, centro) o del mejor movimiento de una búsqueda menos profunda.

🗣️ **2 minutos.** Con orden perfecto, cada nodo de «refutación» necesita un solo hijo, y el árbol efectivo tiene ramificación `√b`. Las técnicas: ordenar por una evaluación rápida, guardar el mejor movimiento de cada estado en la tabla de transposición, la heurística de *killer moves* y la profundización iterativa.

🔬 **El detalle.** Ordenar cuesta: si la evaluación usada para ordenar es cara, se pierde lo que gana la poda. Por eso se ordena barato en los niveles profundos y con cuidado cerca de la raíz.

**06 → 11.** ¿Cuándo usarías MCTS en lugar de alfa-beta, y qué garantiza cada uno? 🟠

⏱️ **30 segundos.** MCTS cuando la ramificación es enorme, hay azar o no hay buena evaluación; alfa-beta cuando hay evaluación y orden razonables. Alfa-beta garantiza el valor minimax hasta su profundidad; MCTS solo converge con muchas iteraciones.

🗣️ **2 minutos.** Alfa-beta necesita una función de evaluación para los nodos del límite; MCTS la sustituye por partidas al azar hasta el final. MCTS crece de forma asimétrica, hacia las ramas prometedoras, y se puede parar en cualquier momento.

🔬 **El detalle.** El go se resolvió con MCTS guiado por redes neuronales (AlphaGo); el ajedrez, durante décadas, con alfa-beta y evaluaciones manuales. Hoy los dos enfoques conviven.

**06 → 12.** Traza alfa-beta sobre el árbol de §3 con las hojas del tercer nodo en orden `2, 5, 14` y di cuántas hojas visita. 🔴

⏱️ **30 segundos.** Visita 5 hojas: `3, 12, 8` en el primero; `2` en el segundo (poda 4 y 6); `2` en el tercero (poda 5 y 14). Valor 3.

🗣️ **2 minutos.** Tras el primer MIN, `α = 3` en la raíz. En el segundo, la primera hoja 2 hace que valga `≤ 2 ≤ α`: corte. En el tercero, con el nuevo orden, la primera hoja también es 2: el mismo corte. Con el orden original (`14, 5, 2`) hay que ver las tres.

🔬 **El detalle.** Es el ejemplo mínimo de por qué el orden importa: los mismos valores, 7 hojas o 5 según el orden en que se exploran.

**06 → 13.** Tu *negamax* con alfa-beta devuelve valores absurdos en cuanto la profundidad es impar. ¿Qué miras? 🔴

⏱️ **30 segundos.** El signo y el punto de vista de la evaluación: en *negamax*, `evaluate()` tiene que dar el valor para **quien mueve** en ese estado. Si siempre da el de MAX, a profundidad impar la hoja la evalúa el rival con el signo cambiado.

🗣️ **2 minutos.** A profundidad par, el jugador de la hoja es el de la raíz y el error no se ve; a profundidad impar, cada hoja tiene el signo al revés. Lo segundo que se mira es la ventana: tiene que pasarse como `(−β, −α)`, no `(−α, −β)`.

🔬 **El detalle.** Un *stress test* contra minimax sin poda sobre árboles aleatorios pequeños detecta los dos errores en segundos (`01/05`).

**06 → Problema: Tres en raya a mitad de partida.**

- **Pista 2 — patrón:** **minimax completo** (o *negamax*), opcionalmente con memoización del tablero.
- **Pista 3 — diseño:** valor para quien mueve: si el rival acaba de hacer línea, `−1`; si no quedan casillas, 0; si no, el máximo de `−valor(tablero con mi ficha en cada casilla libre)`. Quedan como mucho `9!` partidas; con memoización, `3⁹` tableros.

**06 → Problema: Monedas en los extremos.**

- **Pista 2 — patrón:** ***negamax* sobre tramos** con memoización (una DP de intervalos).
- **Pista 3 — diseño:** `d(i, j) = max(a[i] − d(i + 1, j), a[j] − d(i, j − 1))`, `d(i, j) = 0` si `i > j`; la respuesta es `(suma + d(0, n − 1)) / 2`. Recorre por longitudes de tramo y guarda solo la longitud anterior: `O(n²)` de tiempo, `O(n)` de memoria.

**06 → Problema: Dominó en una tira.**

- **Pista 2 — patrón:** **minimax con memoización sobre una máscara** de casillas ocupadas.
- **Pista 3 — diseño:** `gana(m)` = existe una posición `i` con `i` e `i + 1` libres en `m` tal que `gana(m | 3 << i)` es falso. `2²⁰` estados. Alternativa: los tramos libres son subjuegos independientes y Sprague-Grundy ([`17/08`](../17-matematica/08-teoria-de-juegos.md)) los combina con XOR.

**06 → Problema: Find Winner on a Tic Tac Toe Game.**

- **Pista 2 — patrón:** **evaluar un estado terminal**: no hace falta buscar.
- **Pista 3 — diseño:** coloca los movimientos alternando `A` y `B`; mira las ocho líneas; si alguna está completa, gana su dueño; si no, `Draw` con 9 movimientos y `Pending` con menos.

**06 → Problema: Predict the Winner.**

- **Pista 2 — patrón:** ***negamax* sobre tramos**.
- **Pista 3 — diseño:** `d(i, j)` = la mejor diferencia para quien mueve con `nums[i..j]`; el primero gana o empata si `d(0, n − 1) ≥ 0`.

**06 → Problema: Stone Game.**

- **Pista 2 — patrón:** ***negamax* sobre tramos**, o el argumento de paridad.
- **Pista 3 — diseño:** con la DP de tramos sale directo; el argumento: con un número par de pilas, el primero puede coger siempre todas las de índice par o todas las de índice impar, y una de las dos sumas es mayor (la suma total es impar, no hay empate). Así que siempre gana.

**06 → Problema: Can I Win.**

- **Pista 2 — patrón:** **minimax con memoización sobre la máscara** de números usados.
- **Pista 3 — diseño:** el total acumulado se deduce de la máscara, así que el estado es solo la máscara (`2²⁰`). `gana(m)` = algún número libre `x` alcanza el objetivo, o deja un estado `m | bit(x)` perdedor para el rival. Descarta primero el caso en que la suma de todos no llega al objetivo.

**06 → Problema: Stone Game II.**

- **Pista 2 — patrón:** ***negamax* con estado `(i, M)`**.
- **Pista 3 — diseño:** con los sufijos de piedras, `f(i, M)` = lo máximo que consigue quien mueve desde `i`; prueba `x` de 1 a `2M`: `sufijo(i) − f(i + x, max(M, x))`. Si `i + 2M ≥ n`, se lo lleva todo.

**06 → Problema: Simplified Chess Engine.**

- **Pista 2 — patrón:** **minimax con límite de profundidad** `m` y generación de movimientos.
- **Pista 3 — diseño:** las blancas ganan si existe un movimiento tal que, para toda respuesta negra, ganan en lo que queda; capturar la reina rival es la victoria. Genera movimientos de cada pieza (alfil, torre, dama, caballo; las negras igual), aplica y deshaz. Con `m ≤ 6` y pocas piezas cabe sin poda.

**06 → Problema: Stone Game III.**

- **Pista 2 — patrón:** ***negamax* sobre sufijos**.
- **Pista 3 — diseño:** `d(i) = max sobre k ∈ {1, 2, 3} de (suma de las k siguientes) − d(i + k)`; `d(n) = 0`. Gana Alice si `d(0) > 0`, Bob si `< 0`, empate si 0. Lineal, de derecha a izquierda.

**06 → Problema: Ultimate Tic-Tac-Toe.**

- **Pista 2 — patrón:** **alfa-beta con profundización iterativa**, o **MCTS**, con tiempo por turno.
- **Pista 3 — diseño:** representa los nueve tableros con máscaras; genera solo los movimientos legales (el tablero lo fija la última jugada); empieza por MCTS con *playouts* aleatorios rápidos, que no necesita evaluación, y ajusta la constante de UCB1.

**06 → Problema: Connect 4.**

- **Pista 2 — patrón:** **alfa-beta con orden central** y evaluación por líneas.
- **Pista 3 — diseño:** explora las columnas del centro hacia fuera; evalúa contando ventanas de cuatro con fichas de un solo color; profundización iterativa con el reloj; tabla de transposición con *bitboards* si quieres llegar más hondo.

**06 → Problema: Cat and Mouse.**

- **Pista 2 — patrón:** **retroanálisis** desde los estados terminales: la recursión con memoización no termina bien con ciclos.
- **Pista 3 — diseño:** estados `(ratón, gato, turno)`; marca los terminales (ratón en el agujero, gato con el ratón); propaga hacia atrás con una cola: un estado es ganador para quien mueve si algún sucesor es perdedor para el otro, y perdedor si todos sus sucesores son ganadores para el otro (lleva cuántos sucesores quedan por resolver). Lo que nunca se marca es empate.

---

# 07 — Simulación

**07 → S1.** ¿Qué dos costes tiene una recursión, y cuál de los dos tumba un envío con `n = 2·10⁵`? 🟢

⏱️ **30 segundos.** Tiempo, que es el tamaño del árbol de recursión por el trabajo de cada llamada, y pila, que es su profundidad. Con `n = 2·10⁵` y profundidad `n`, lo que tumba el envío es la pila.

🗣️ **2 minutos.** Una recursión lineal sobre una cadena hace `n` llamadas en `O(n)`: el tiempo sobra. Pero `2·10⁵` marcos no caben en la pila por defecto de Java (~10⁴) ni en el límite de Python (1000).

🔬 **El detalle.** `10/01`, §3.

**07 → S2.** ¿Por qué subir `sys.setrecursionlimit` no basta siempre en Python? 🟡

⏱️ **30 segundos.** Porque solo sube un contador. Si la recursión pasa por código en C —por ejemplo, una función con `@cache`—, cada nivel gasta pila de C y el proceso muere con un fallo de segmentación.

🗣️ **2 minutos.** Desde 3.11, las llamadas entre funciones de Python puro no gastan pila de C, y subir el límite basta; con `@cache`, `map` o `sorted` en el camino, no. La receta completa es el límite más un hilo con `threading.stack_size`, o pasar a iterativo.

🔬 **El detalle.** `10/01`, §3, y [`03/04`](../03-biblioteca-estandar/04-python-para-competir.md), §8.

**07 → S3.** ¿Qué guarda un marco de la pila explícita cuando la recursión tiene dos llamadas con trabajo entre ellas? 🟡

⏱️ **30 segundos.** Los parámetros de la llamada y una **etapa** que dice por dónde seguir: antes de la primera llamada, entre las dos, o después.

🗣️ **2 minutos.** Al reanudar un marco, la etapa decide qué trozo del cuerpo ejecutar. Con `k` llamadas hay `k + 1` etapas. Si la función devuelve valores, el marco guarda también los resultados parciales, o se usa una pila de valores.

🔬 **El detalle.** `10/01`, §4: el invariante es que la pila explícita coincide con la de llamadas de la recursiva.

**07 → S4.** ¿Hasta qué `n` se enumeran subconjuntos, permutaciones y combinaciones en un segundo? 🟢

⏱️ **30 segundos.** Subconjuntos hasta `n ≈ 20`; permutaciones hasta `n ≈ 10`; combinaciones mientras `C(n, k)` no pase de unos `10⁷`.

🗣️ **2 minutos.** `2²⁰ ≈ 10⁶`, `10! ≈ 3,6·10⁶`, y se multiplican por el coste de procesar cada caso. En Python, divide entre 30.

🔬 **El detalle.** `10/02`, §1.

**07 → S5.** ¿Por qué `next_permutation` necesita empezar con el arreglo ordenado? 🟢

⏱️ **30 segundos.** Porque genera las permutaciones **posteriores** a la actual en orden lexicográfico; sin ordenar, se pierden las anteriores.

🗣️ **2 minutos.** Cuando llega a la última (orden no creciente), devuelve `false` y deja el arreglo ordenado. El `do`/`while` procesa también la primera.

🔬 **El detalle.** `10/02`, §2 y §4.

**07 → S6.** ¿Qué te da `m & (m − 1)` y para qué lo usas? 🟢

⏱️ **30 segundos.** La máscara `m` sin su bit más bajo. Sirve para calcular cualquier agregado de un subconjunto a partir del de un subconjunto menor, ya calculado.

🗣️ **2 minutos.** `sum[m] = sum[m & (m − 1)] + a[ctz(m)]`: todas las sumas de subconjuntos en `Θ(2ⁿ)`. También para contar bits (cada vuelta apaga uno).

🔬 **El detalle.** `10/02`, §3.

**07 → S7.** ¿Qué hipótesis tiene que cumplir una poda para no perder soluciones? 🟡

⏱️ **30 segundos.** Que si un parcial viola la condición de poda, **ninguna** de sus extensiones pueda ser solución (o mejorar la mejor, en ramificación y poda).

🗣️ **2 minutos.** Con esa hipótesis, el camino a cualquier solución nunca pasa por un nodo podado. La hipótesis es lo que se demuestra en cada problema: «la suma ya supera el objetivo» solo la cumple con pesos no negativos.

🔬 **El detalle.** `10/03`, §2.

**07 → S8.** ¿Qué pasa si una rama del *backtracking* no deshace lo que hizo? 🟡

⏱️ **30 segundos.** Las ramas hermanas ven un estado que no es el suyo: aparecen soluciones falsas o se pierden verdaderas.

🗣️ **2 minutos.** El invariante del *backtracking* es que, al entrar en un nodo, el estado compartido describe su solución parcial. Sin deshacer, las marcas de una rama se quedan para las siguientes.

🔬 **El detalle.** `10/03`, §3, pregunta 13: la sopa de letras.

**07 → S9.** ¿Qué cota usa la ramificación y poda de la mochila 0/1, y por qué es válida? 🟡

⏱️ **30 segundos.** El valor del nodo más la **mochila fraccionaria** de los objetos restantes. Es válida porque permitir fracciones relaja el problema: ninguna solución entera la supera.

🗣️ **2 minutos.** Con los objetos ordenados por valor por unidad de peso, la fraccionaria es un voraz en `O(n)`. Si la cota no supera el mejor valor encontrado, el subárbol se poda.

🔬 **El detalle.** `10/03`, §4.

**07 → S10.** ¿Qué número del enunciado delata *meet in the middle*, y qué exige de la condición? 🟢

⏱️ **30 segundos.** `n ≤ 40` (o cerca). Exige que la condición se pueda consultar por mitades: fijada una mitad, la pareja de la otra se busca con una tabla o una búsqueda ordenada.

🗣️ **2 minutos.** Sumas, XOR y restos se parten. Una condición que acopla elementos concretos de las dos mitades no se parte salvo con un estado de frontera pequeño.

🔬 **El detalle.** [`10/04`](04-meet-in-the-middle-iddfs-y-dancing-links.md), §2 y §3.

**07 → S11.** ¿Qué gana IDDFS frente a BFS y qué paga? 🟡

⏱️ **30 segundos.** Gana memoria: `O(d)` frente a `O(bᵈ)`, con la misma optimalidad en coste unitario. Paga un factor de tiempo `(b/(b − 1))²` y no detecta estados repetidos.

🗣️ **2 minutos.** Repite las capas de arriba en cada iteración, pero la última capa domina. Si los estados se repiten mucho y caben en memoria, BFS con visitados es mejor.

🔬 **El detalle.** `10/04`, §2 y §4.

**07 → S12.** ¿Qué recurrencia tiene Karatsuba y qué da? 🟢

⏱️ **30 segundos.** `T(n) = 3T(n/2) + O(n)`, que da `Θ(n^(log₂ 3)) ≈ Θ(n^1,585)`.

🗣️ **2 minutos.** Tres productos de mitades en lugar de cuatro; el término cruzado sale de `(x₁ + x₀)(y₁ + y₀) − z₂ − z₀`.

🔬 **El detalle.** [`10/05`](05-divide-y-venceras.md), §5.

**07 → S13.** ¿Qué invariante mantiene la exponenciación rápida? 🟡

⏱️ **30 segundos.** `resultado · baseᵉ = aⁿ`, con `e` lo que queda del exponente; al acabar, `e = 0`.

🗣️ **2 minutos.** Si el bit bajo de `e` es 1, se mete `base` en el resultado; después `base` se eleva al cuadrado y `e` se divide entre 2. El producto se conserva en las dos operaciones.

🔬 **El detalle.** `10/05`, §6.

**07 → S14.** ¿Qué significa NP y qué **no** significa? 🟡

⏱️ **30 segundos.** NP es la clase de problemas de decisión cuyo «sí» tiene un certificado verificable en tiempo polinomial. No significa «no polinomial»: P está dentro de NP.

🗣️ **2 minutos.** El nombre viene de *nondeterministic polynomial*. Que un problema esté en NP no dice que sea difícil; que sea NP-completo dice que es de los más difíciles de NP, y que nadie conoce un algoritmo polinomial.

🔬 **El detalle.** `10/05`, §2.

**07 → S15.** ¿Por qué la mochila con DP `O(n · W)` es pseudopolinomial? 🟠

⏱️ **30 segundos.** Porque es polinomial en el **valor** de `W`, no en su número de bits: con `W = 10¹⁸` (60 bits) son `10¹⁸` pasos por objeto.

🗣️ **2 minutos.** El tamaño de la entrada cuenta los bits de los números. `W` es exponencial en su longitud. La mochila es NP-completa, y la DP solo es rápida cuando los números son pequeños.

🔬 **El detalle.** `10/05`, pregunta 10.

**07 → S16.** ¿Alfa-beta devuelve el mismo valor que minimax? ¿Por qué? 🟡

⏱️ **30 segundos.** Sí, exactamente el mismo en la raíz. Solo deja de explorar ramas que se demuestra que no pueden cambiar la decisión de arriba.

🗣️ **2 minutos.** Un nodo de MIN cuyo primer hijo ya vale `≤ α` nunca será elegido por MAX, que tiene algo mejor; su valor exacto no influye. Lo que cambia es el valor de nodos interiores podados, que queda solo acotado.

🔬 **El detalle.** [`10/06`](06-juegos-y-busqueda-adversarial.md), §2 y §4.

**07 → S17.** ¿Qué ventana pasa *negamax* con alfa-beta a la llamada del rival? 🟠

⏱️ **30 segundos.** `(−β, −α)`: la ventana del rival es la mía negada e invertida.

🗣️ **2 minutos.** Lo que para mí es «al menos `α`» para el rival es «como mucho `−α`», y viceversa. Pasar `(−α, −β)` invierte la ventana y la poda deja de ser correcta.

🔬 **El detalle.** `10/06`, §4, y pregunta 13 de ese capítulo.

**07 → S18.** «Es exponencial, así que no puede ser la solución.» El enunciado dice `n ≤ 18`. ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que con `n ≤ 18`, `2¹⁸ ≈ 2,6·10⁵`: lo exponencial cabe de sobra. Las restricciones están diciendo que se espera enumerar.

🗣️ **2 minutos.** El tamaño del enunciado es la pista principal de la complejidad esperada ([`01/02`](../01-oficio-del-competidor/02-leer-las-restricciones.md)). Un `n` tan pequeño en un problema que parece de optimización suele delatar uno NP-difícil y una solución exponencial en `n`.

🔬 **El detalle.** `10/02`, §1, y `10/05`, §7.

**07 → S19.** Tu *backtracking* de suma de subconjuntos da menos soluciones que la fuerza bruta en cuanto aparecen pesos negativos. ¿Qué miras? 🟠

⏱️ **30 segundos.** La poda por exceso («la suma ya supera el objetivo, corto»): con negativos, una suma que se pasa puede volver a bajar. Es una poda incorrecta para esa entrada.

🗣️ **2 minutos.** La hipótesis del lema de factibilidad deja de cumplirse. Arreglo: ordenar y acotar con la suma de los negativos que quedan, o desplazar los valores si el problema lo permite, o renunciar a esa poda.

🔬 **El detalle.** `10/03`, pregunta 8.

**07 → S20.** Te piden el recorrido más corto que visita 15 ciudades. ¿Por qué no un voraz, y qué haces? 🟠

⏱️ **30 segundos.** Porque es el viajante, NP-difícil: ningún voraz da el óptimo en general. Con 15 ciudades, DP sobre (ciudades visitadas, ciudad actual): `2¹⁵ · 15² ≈ 7·10⁶`.

🗣️ **2 minutos.** El vecino más cercano cae en trampas que un ejemplo pequeño delata. La DP de Held y Karp (`13/01`) es exacta y cabe. Si fueran 9 ciudades, las permutaciones bastan (`8! = 40 320` órdenes).

🔬 **El detalle.** `10/05`, §7.

**07 → S21.** «Uso divide y vencerás para Fibonacci: `F(n) = F(n − 1) + F(n − 2)`, se parte en dos.» ¿Qué falla? 🟠

⏱️ **30 segundos.** Que los subproblemas se solapan: `F(n − 1)` vuelve a pedir `F(n − 2)`. No es divide y vencerás, es programación dinámica, y sin guardar los resultados el árbol es exponencial.

🗣️ **2 minutos.** Divide y vencerás exige partes disjuntas. Fibonacci recursivo hace `Θ(φⁿ)` llamadas para solo `n` subproblemas distintos. Con memoización o una tabla, `Θ(n)`; con potencia de matrices, `Θ(log n)`.

🔬 **El detalle.** `10/05`, pregunta 5, y `12/01`.

**07 → S22.** Con `n = 40` y valores hasta `10¹²`, alguien propone la DP de la mochila. ¿Qué le dices? 🟠

⏱️ **30 segundos.** Que la DP es `O(n · W)` y `W` llega a `4·10¹³`: no cabe. Con `n = 40`, *meet in the middle*: `2²⁰` sumas por mitad.

🗣️ **2 minutos.** La DP de la mochila depende del valor de la capacidad; aquí lo pequeño es `n`. Partiendo en dos mitades de 20, se enumeran sus sumas, se ordena una y se busca la pareja de cada suma de la otra.

🔬 **El detalle.** `10/04`, §3.

**07 → S23.** Tu solución recursiva da RE en Java y AC en C++ con el mismo algoritmo. ¿Qué pasa y qué haces? 🟠

⏱️ **30 segundos.** La profundidad de la recursión: la pila de Java es más pequeña que la que el juez da a C++. Lanzar el programa en un `Thread` con pila grande, o pasar a iterativo.

🗣️ **2 minutos.** El mismo algoritmo con `n` marcos cabe en los 8 MB (o más) de C++ y no en el ~1 MB por hilo de Java. `new Thread(null, Main::solve, "solve", 1L << 28)` resuelve sin tocar el algoritmo.

🔬 **El detalle.** `10/01`, §3, y [`03/03`](../03-biblioteca-estandar/03-java-colecciones.md).

**07 → S24.** Demuestra por inducción que `pow(a, n)` recursivo (`a^(n/2)` al cuadrado, por `a` si `n` es impar) es correcto. 🔴

⏱️ **30 segundos.** Inducción fuerte sobre `n`: con `n = 0`, devuelve 1. Si es correcta para `⌊n/2⌋`, entonces `(a^⌊n/2⌋)² = a^(2⌊n/2⌋)`, que es `aⁿ` si `n` es par y `aⁿ⁻¹` si es impar, y la multiplicación extra por `a` lo completa.

🗣️ **2 minutos.** La medida `n` baja a `⌊n/2⌋ < n` para `n ≥ 1`, así que la recursión termina en `O(log n)` llamadas. El paso usa solo `a^(x + y) = aˣ · aʸ`, es decir, asociatividad.

🔬 **El detalle.** La profundidad es `⌊log₂ n⌋ + 1`: con `n = 10¹⁸`, 60 marcos. Aquí la recursión es inofensiva.

**07 → S25.** Diseña la búsqueda del menor número de volteos de prefijo que ordena una permutación de 10 elementos y justifica la técnica con la cuenta de estados. 🔴

⏱️ **30 segundos.** BFS sobre las permutaciones: `10! ≈ 3,6·10⁶` estados con 9 vecinos cada uno, unos `3·10⁷` pasos, que caben con un mapa de visitados compacto. O búsqueda bidireccional, que lo baja mucho más.

🗣️ **2 minutos.** El estado es la permutación; un volteo de los `k` primeros es una arista de coste 1; el camino más corto en un grafo sin pesos es BFS. Para guardar los visitados, se codifica cada permutación por su rango (código de Lehmer) en un arreglo de `10!` bytes. Si la memoria apretara, IDDFS con la cota de «pares adyacentes que no son vecinos en el orden final».

🔬 **El detalle.** La búsqueda bidireccional desde la permutación y desde la identidad explora unos `2 · 9^(d/2)` estados; con el diámetro de 11 volteos para `n = 10`, mucho menos que el espacio entero.

**07 → Problema: Grupo de estudio sin roces.**

- **Pista 2 — patrón:** **conjunto independiente máximo** (NP-difícil) con `n ≤ 25`: ***backtracking* con poda por cota**, o enumeración de máscaras con el chequeo en `O(1)`.
- **Pista 3 — diseño:** decide estudiante a estudiante (dentro / fuera); «dentro» solo si no choca con la máscara del grupo (`adj[i] & grupo == 0`); poda si `tamaño + restantes ≤ mejor`. La enumeración de `2²⁵` máscaras con validez incremental también cabe en C++.

**07 → Problema: Dos turnos parejos.**

- **Pista 2 — patrón:** ***meet in the middle*** sobre las diferencias con signo.
- **Pista 3 — diseño:** cada mitad de 20 tareas da `2²⁰` diferencias (mañana menos tarde). Ordena la derecha; para cada diferencia `l` de la izquierda, cuenta las `r` con `−D − l ≤ r ≤ D − l` con dos búsquedas binarias. Todo en 64 bits; la respuesta también.

**07 → Problema: Contraseñas con vocal.**

- **Pista 2 — patrón:** **complemento y exponenciación rápida**.
- **Pista 3 — diseño:** total `kⁿ` menos las que no tienen vocal, `(k − v)ⁿ`, módulo `10⁹ + 7`, con la potencia rápida y el resultado ajustado a no negativo. Reduce `k` antes de potenciar.

**07 → Problema: Ruta de reparto.**

- **Pista 2 — patrón:** **fuerza bruta sobre las permutaciones**: con `n ≤ 9`, `8! = 40 320` órdenes.
- **Pista 3 — diseño:** fija el almacén al principio y al final; recorre las permutaciones de los clientes con la siguiente permutación; suma `d` a lo largo del recorrido y guarda el mínimo. La DP sobre máscaras sería correcta, pero es más código para nada.

**07 → Problema: Beautiful Arrangement.**

- **Pista 2 — patrón:** ***backtracking* sobre permutaciones con poda por posición**.
- **Pista 3 — diseño:** coloca números en las posiciones `1..n`; en la posición `i`, solo los números no usados con `x mod i = 0` o `i mod x = 0`. Empezar por las últimas posiciones (más restrictivas) poda antes.

**07 → Problema: Fair Distribution of Cookies.**

- **Pista 2 — patrón:** ***backtracking* con poda por cota** (o DP sobre máscaras).
- **Pista 3 — diseño:** asigna cada bolsa a un niño; poda si un niño supera el mejor máximo encontrado; poda por simetría: si dos niños tienen la misma carga actual, prueba solo uno. Ordenar las bolsas de mayor a menor ayuda.

**07 → Problema: Password Cracker.**

- **Pista 2 — patrón:** ***backtracking* con memoización de fracasos** (partir una cadena en palabras).
- **Pista 3 — diseño:** desde la posición `i`, prueba cada contraseña que encaje ahí y recurre en `i + len`; guarda las posiciones desde las que ya se falló para no repetir. Reconstruye la partición con el camino de la recursión.

**07 → Problema: Maximum Score Words Formed by Letters.**

- **Pista 2 — patrón:** **subconjuntos de palabras** (`2¹⁴`) con poda.
- **Pista 3 — diseño:** enumera los subconjuntos (o recurre tomando / sin tomar) llevando las letras restantes en un arreglo de 26; si una palabra no cabe, esa rama se descarta; la puntuación es la suma de las letras usadas.

**07 → Problema: Stone Game IV.**

- **Pista 2 — patrón:** **minimax con memoización** sobre el número de piedras (juego ganador o perdedor).
- **Pista 3 — diseño:** `gana[x]` es cierto si existe un cuadrado `k² ≤ x` con `gana[x − k²]` falso. Tabla de 0 a `n`: `O(n √n)`.
