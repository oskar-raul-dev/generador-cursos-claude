# Respuestas — bloque 16: Cadenas

> Solucionario del bloque `16`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--cadenas-en-los-tres-lenguajes-y-patrones-básicos) · [02](#02--kmp-y-la-función-de-prefijo) · [03](#03--función-z-y-manacher) · [04](#04--hashing-de-cadenas-aplicado) · [05](#05--aho-corasick) · [06](#06--suffix-array-lcp-y-suffix-automaton) · [07](#07--autómatas-y-expresiones-regulares) · [08](#08--árbol-de-palíndromos-y-árbol-de-sufijos) · [09](#09--simulación)

---

# 01 — Cadenas en los tres lenguajes y patrones básicos

**01 → 1.** ¿Por qué `s += c` en un bucle es cuadrático en Java y en Python, y no en C++? 🟢

⏱️ **30 segundos.** Porque en Java y Python las cadenas son inmutables: cada `+=` crea una cadena nueva y copia la anterior entera. En C++ `std::string` es mutable y `+=` añade al final en `O(1)` amortizado.

🗣️ **2 minutos.** Añadir `n` caracteres copia `1 + 2 + … + n = n(n + 1)/2`: con `10⁵`, `5·10⁹` copias. `std::string` reserva capacidad de sobra como un `vector`, y solo copia al ampliar, lo que suma `Θ(n)`.

🔬 **El detalle.** CPython a veces optimiza `s += c` en el sitio si nadie más referencia `s`, pero no está garantizado ni en PyPy.

**01 → 2.** ¿Cómo construyes una cadena por partes en cada uno de los tres lenguajes? 🟢

⏱️ **30 segundos.** C++: `std::string` con `+=` o `push_back` (y `reserve`). Java: `StringBuilder` y `toString()` al final. Python: una lista de trozos y `''.join`.

🗣️ **2 minutos.** El patrón es el mismo: un búfer mutable y una sola conversión. Para la salida de un programa, todo en el búfer y un solo `print` (o `PrintWriter` con búfer en Java, `sys.stdout.write` en Python).

🔬 **El detalle.** En Java, `String.join` y `Collectors.joining` usan un `StringBuilder` por dentro.

**01 → 3.** ¿Cuándo son dos cadenas anagramas? 🟢

⏱️ **30 segundos.** Cuando tienen las mismas letras con las mismas multiplicidades: el mismo vector de frecuencias.

🗣️ **2 minutos.** Equivale a que una sea una permutación de la otra. Se comprueba con un arreglo de 26 contadores (sumar en una, restar en la otra, y ver que todo queda en 0) o comparando las cadenas ordenadas.

🔬 **El detalle.** Con distintas longitudes no pueden serlo: se descarta antes de contar.

**01 → 4.** ¿Cómo compruebas que una cadena es palíndromo sin crear su inversa? 🟢

⏱️ **30 segundos.** Con dos punteros desde los extremos que avanzan hacia el centro comparando `s[i]` y `s[j]`.

🗣️ **2 minutos.** `Θ(n)` y `Θ(1)` de memoria. `s == s[::-1]` en Python o `new StringBuilder(s).reverse()` en Java son correctos pero crean una copia.

🔬 **El detalle.** Con caracteres a ignorar (espacios, signos), los punteros saltan dentro del bucle.

**01 → 5.** ¿Qué devuelve `length()` en Java para una cadena con un emoji, y `len()` en Python? 🟡

⏱️ **30 segundos.** En Java, `length()` cuenta unidades UTF-16: un emoji fuera del plano básico cuenta 2. En Python, `len()` cuenta puntos de código: 1.

🗣️ **2 minutos.** En Java, para contar caracteres reales: `s.codePointCount(0, s.length())`; para recorrerlos, `s.codePoints()`. En C++, `size()` cuenta bytes: en UTF-8 una `ñ` son 2.

🔬 **El detalle.** Ni siquiera los puntos de código son «caracteres» visibles: hay letras formadas por varios (acentos combinados, banderas).

**01 → 6.** ¿Por qué en Java no se comparan cadenas con `==`? 🟡

⏱️ **30 segundos.** Porque `==` compara referencias (si son el mismo objeto), no el contenido. Para el contenido, `equals`.

🗣️ **2 minutos.** Los literales iguales suelen compartir objeto (el *pool* de cadenas), así que `==` funciona en pruebas pequeñas y falla con cadenas construidas en ejecución. Es un error que pasa los ejemplos y falla en el juez.

🔬 **El detalle.** Lo mismo con `Integer` fuera del rango `−128..127`.

**01 → 7.** ¿Arreglo de 26 o mapa para contar letras? ¿Cuándo cada uno? 🟡

⏱️ **30 segundos.** Arreglo de 26 con un alfabeto pequeño y conocido (minúsculas); mapa con alfabetos grandes o desconocidos (Unicode, palabras).

🗣️ **2 minutos.** El arreglo no tiene *hashing*, ni colisiones, ni objetos: es más rápido y comparar dos arreglos es `Θ(26)`. El mapa evita reservar memoria para símbolos que no aparecen.

🔬 **El detalle.** Con caracteres ASCII arbitrarios, un arreglo de 128 o 256 sigue siendo mejor que un mapa.

**01 → 8.** ¿Qué firma usas como clave para agrupar anagramas en cada lenguaje? 🟡

⏱️ **30 segundos.** La cadena ordenada (en los tres) o el vector de 26 frecuencias: `Arrays.toString(freq)` en Java, `tuple(freq)` en Python, el `std::array` en un `map` en C++.

🗣️ **2 minutos.** La cadena ordenada cuesta `Θ(L log L)`; el vector, `Θ(L + 26)`. Con palabras cortas, da igual; con palabras largas, el vector. En Python, las listas no son *hashables*: hace falta `tuple`.

🔬 **El detalle.** En C++, `std::array<int, 26>` no tiene `std::hash`: o `map`, o convertir a `string`.

**01 → 9.** Demuestra que construir con un búfer que duplica su capacidad cuesta `Θ(n)`. 🟠

⏱️ **30 segundos.** Las copias por ampliación suman como mucho `1 + 2 + 4 + … + n < 2n`, y cada carácter se escribe una vez más: total `Θ(n)`.

🗣️ **2 minutos.** El búfer solo copia cuando se llena, y entonces duplica la capacidad. Las ampliaciones copian `1, 2, 4, …, 2^k` elementos con `2^k < 2n`: una serie geométrica. Es el análisis amortizado del arreglo dinámico ([`02/03`](../02-analisis/03-analisis-amortizado.md)).

🔬 **El detalle.** Con un factor de crecimiento constante `> 1` cualquiera vale; con un incremento constante (añadir 100 cada vez), vuelve a ser cuadrático.

**01 → 10.** ¿Cuántos cambios de letra necesitas como mínimo para que una cadena sea palíndromo, y por qué? 🟠

⏱️ **30 segundos.** El número de pares simétricos distintos: cada cambio arregla exactamente un par.

🗣️ **2 minutos.** Un palíndromo exige `s[i] = s[n − 1 − i]` para cada `i < n/2`. Cada par distinto necesita al menos un cambio (en uno de sus dos extremos), y uno basta; los pares son independientes. En `abracadabra`, 3.

🔬 **El detalle.** Si en lugar de cambiar se puede **borrar**, el problema es otro: la subsecuencia palindrómica más larga ([`12/04`](../12-dp-clasica/04-dp-sobre-cadenas.md)).

**01 → 11.** ¿Cuánto cuesta obtener una subcadena en cada lenguaje, y cómo lo evitas en un bucle? 🟠

⏱️ **30 segundos.** En los tres, una subcadena de longitud `k` cuesta `Θ(k)`: copia. En un bucle se trabaja con índices.

🗣️ **2 minutos.** `substr` en C++, `substring` en Java (desde 7u6) y `s[i:j]` en Python copian. Un bucle que hace `s.substring(i)` en cada vuelta es `Θ(n²)`. Con índices, o con `std::string_view` en C++, no hay copia.

🔬 **El detalle.** En Python, `memoryview` sobre `bytes` evita copias para datos binarios.

**01 → 12.** Cuenta los pares de palabras que son anagramas en una lista de `10⁵` palabras. ¿Coste? 🔴

⏱️ **30 segundos.** Firma de cada palabra (ordenada o vector de 26) y un mapa de conteos; cada grupo de `k` palabras aporta `k(k − 1)/2`. `Θ(n · L log L)`.

🗣️ **2 minutos.** Comparar todos los pares sería `Θ(n² · L)`, `5·10⁹` comparaciones de pares con `n = 10⁵`. Agrupar por firma convierte la pregunta de pares en una de conteo.

🔬 **El detalle.** El total de pares puede superar `2³¹`: 64 bits.

**01 → 13.** ¿Qué subcadena más larga tiene todas sus letras un número par de veces, y cómo la encuentras en `Θ(n)`? 🔴

⏱️ **30 segundos.** Con la máscara de paridad de los prefijos (26 bits): una subcadena tiene todo par si y solo si los prefijos de sus extremos tienen la misma máscara. Se guarda la primera aparición de cada máscara.

🗣️ **2 minutos.** La paridad de la subcadena `s[i..j]` es la XOR de las máscaras de los prefijos `j + 1` e `i`. La subcadena más larga con XOR 0 es la mayor distancia entre dos posiciones con la misma máscara: un mapa de primera aparición, `Θ(n)`.

🔬 **El detalle.** Con «como mucho una letra impar» (palíndromo reordenable), se prueban además las 26 máscaras que difieren en un bit.

**01 → Problema: La letra que más se repite.**

**Pista 2:** un arreglo de 26 contadores.

**Pista 3:** recorre las letras de `a` a `z` y quédate con la primera de frecuencia máxima; con `10⁶` caracteres, lectura rápida.

**01 → Problema: ¿Palíndromo reordenando?.**

**Pista 2:** como mucho una letra puede aparecer un número impar de veces; con prefijos de frecuencias (o de paridades) por letra, cada consulta es `O(26)`.

**Pista 3:** `pre[i][c]` = apariciones de `c` en los `i` primeros; o la máscara de paridad del prefijo, y la consulta es `popcount(m[r] ^ m[l − 1]) ≤ 1`.

**01 → Problema: Todo en pares.**

**Pista 2:** máscara de paridad de los prefijos y la primera posición en que aparece cada máscara.

**Pista 3:** empieza con la máscara 0 en la posición `−1`; para cada prefijo, si su máscara ya apareció, la longitud es la diferencia de posiciones. Un arreglo de `2²⁶` es demasiado: mapa (o solo las máscaras que aparecen).

**01 → Problema: Alternating Characters.**

**Pista 2:** cuenta las posiciones `i` con `s[i] = s[i − 1]`: cada una exige un borrado.

**Pista 3:** un solo recorrido; varias consultas por entrada.

**01 → Problema: Making Anagrams.**

**Pista 2:** frecuencias de las dos cadenas.

**Pista 3:** la respuesta es `Σ |fa[c] − fb[c]|` sobre las 26 letras.

**01 → Problema: Valid Palindrome II.**

**Pista 2:** dos punteros; en el primer par distinto, prueba saltar el izquierdo o el derecho.

**Pista 3:** cada prueba es un recorrido de palíndromo sobre el resto: `Θ(n)` en total.

**01 → Problema: Longest Palindrome.**

**Pista 2:** frecuencias: cada letra aporta su parte par, y como mucho una letra puede poner una impar en el centro.

**Pista 3:** suma `f − f % 2` de cada letra y añade 1 si alguna era impar. Mayúsculas y minúsculas son distintas.

**01 → Problema: Palindrome Index.**

**Pista 2:** dos punteros; en el primer par distinto, uno de los dos índices es la respuesta.

**Pista 3:** comprueba si quitando el izquierdo el resto es palíndromo; si no, el derecho; si ya es palíndromo, `-1`.

**01 → Problema: Reverse Words in a String.**

**Pista 2:** separa por espacios ignorando los vacíos y une al revés con un solo espacio.

**Pista 3:** en Java, `trim().split("\\s+")` y `String.join` sobre la lista invertida; en el sitio, invertir todo y luego cada palabra.

**01 → Problema: Determine if Two Strings Are Close.**

**Pista 2:** las dos operaciones conservan el conjunto de letras presentes y el multiconjunto de frecuencias.

**Pista 3:** compara los conjuntos de letras y las listas de frecuencias ordenadas.

**01 → Problema: Sherlock and the Valid String.**

**Pista 2:** cuenta las frecuencias y después cuántas letras tienen cada frecuencia.

**Pista 3:** válido si hay una sola frecuencia, o dos donde una letra tiene frecuencia 1 (se borra) o una letra tiene la mayor y es una más que la otra.

**01 → Problema: String Compression.**

**Pista 2:** dos punteros: uno lee los grupos y otro escribe el carácter y el número.

**Pista 3:** el número de un grupo ocupa como mucho tantas posiciones como el grupo: la escritura nunca adelanta a la lectura.

**01 → Problema: Minimum Number of Steps to Make Two Strings Anagram.**

**Pista 2:** frecuencias de `s` y de `t`.

**Pista 3:** la respuesta es `Σ max(0, fs[c] − ft[c])`.

**01 → Problema: Longest Palindrome by Concatenating Two Letter Words.**

**Pista 2:** cuenta las palabras: cada `ab` se empareja con un `ba`; las `aa` se emparejan entre sí y una puede ir en el centro.

**Pista 3:** suma `4 · min(cnt[ab], cnt[ba])` (sin contar dos veces), `4 · ⌊cnt[aa]/2⌋`, y 2 si alguna `aa` queda impar.

---

# 02 — KMP y la función de prefijo

**02 → 1.** ¿Qué es un borde y qué guarda la función de prefijo? 🟢

⏱️ **30 segundos.** Un borde es una cadena que es a la vez prefijo propio y sufijo propio. `π[i]` guarda la longitud del borde más largo de `s[0..i]`.

🗣️ **2 minutos.** En `abracadabra`, `π = 0 0 0 1 0 1 0 1 2 3 4`: el último 4 es el borde `abra`. El arreglo entero permite saltar en la búsqueda sin retroceder en el texto.

🔬 **El detalle.** `π[i] < i + 1` siempre, porque el borde es propio.

**02 → 2.** ¿Cuánto cuesta la búsqueda ingenua en el peor caso, y con qué entrada se alcanza? 🟢

⏱️ **30 segundos.** `Θ(n · m)`. Se alcanza con un texto de muchas `a` y un patrón de muchas `a` terminado en `b`: cada posición compara casi `m` caracteres antes de fallar.

🗣️ **2 minutos.** Con textos naturales, la búsqueda ingenua falla pronto y es rápida; el peor caso aparece con repeticiones, que es justo lo que construyen los jueces.

🔬 **El detalle.** Las implementaciones de biblioteca usan trucos (saltos tipo Boyer-Moore) que mejoran la media pero no siempre el peor caso.

**02 → 3.** ¿Cómo se obtiene el periodo más corto de una cadena con la función de prefijo? 🟢

⏱️ **30 segundos.** `n − π[n − 1]`.

🗣️ **2 minutos.** Tener periodo `p` equivale a tener un borde de longitud `n − p`; el periodo más corto corresponde al borde más largo. En `abracadabra`, `11 − 4 = 7`.

🔬 **El detalle.** La cadena es repetición exacta de un trozo si y solo si ese periodo divide a `n`.

**02 → 4.** ¿Por qué el siguiente borde a probar es `π[k − 1]`? 🟡

⏱️ **30 segundos.** Porque el siguiente borde de un prefijo de longitud `k` es el borde más largo de ese prefijo, que termina en el índice `k − 1`: `π[k − 1]`.

🗣️ **2 minutos.** Si el borde actual de longitud `k` no se puede extender, se prueba el siguiente borde más largo de `s[0..i−1]`, que es un borde del borde: el borde más largo de `s[0..k−1]`. Su longitud está en `π[k − 1]`.

🔬 **El detalle.** Usar `π[k]` mira un carácter de más y produce bordes falsos.

**02 → 5.** ¿Cómo cuentas las apariciones solapadas y las no solapadas? 🟡

⏱️ **30 segundos.** Solapadas: tras una aparición, `k = π[m − 1]`. No solapadas: `k = 0`.

🗣️ **2 minutos.** Con `k = π[m − 1]`, el borde del patrón puede empezar la siguiente aparición: `aa` en `aaaaa` se cuenta 4 veces. Con `k = 0`, la siguiente empieza después de la marcada: 2 veces, que es el máximo de no solapadas (voraz por la izquierda).

🔬 **El detalle.** Que el voraz da el máximo de no solapadas es el argumento de selección de actividades ([`11/01`](../11-voraces/01-cuando-funciona-un-voraz.md)).

**02 → 6.** ¿Qué es el truco del separador `p + '#' + t`? 🟡

⏱️ **30 segundos.** Calcular la función de prefijo de `p + '#' + t`, con `#` fuera del alfabeto: cada posición con `π = |p|` es el final de una aparición.

🗣️ **2 minutos.** El separador impide que un borde cruce de `t` a `p`, así que `π` nunca supera `|p|`. Es más corto que escribir KMP aparte, a cambio de `n + m + 1` de memoria.

🔬 **El detalle.** La misma idea con la función Z da la búsqueda por Z ([`16/03`](03-funcion-z-y-manacher.md)).

**02 → 7.** ¿Qué hacen `indexOf`, `find` y `in` en el peor caso? 🟡

⏱️ **30 segundos.** Son búsquedas ingenuas o heurísticas: `O(n · m)` en el peor caso (o sin garantía documentada), aunque rápidas en la práctica.

🗣️ **2 minutos.** `String.indexOf` de Java compara posición a posición; `std::string::find` no tiene garantía lineal en el estándar; CPython usa en versiones recientes un algoritmo de dos vías para patrones largos, que sí es lineal, pero no en todas las versiones ni implementaciones.

🔬 **El detalle.** Con casos adversarios del juez, KMP o Z es la apuesta segura.

**02 → 8.** Demuestra que la función de prefijo se calcula en tiempo lineal. 🟠

⏱️ **30 segundos.** El valor `k` sube como mucho 1 por posición y cada vuelta del `while` lo baja al menos 1 sin bajar de 0; las bajadas totales no superan las subidas, `≤ n`.

🗣️ **2 minutos.** Es un análisis de potencial: `Φ = k`. Cada posición cuesta `1 + (bajadas)` y aumenta `Φ` como mucho 1. Sumando, el coste total es `≤ 2n`.

🔬 **El detalle.** Es el mismo argumento que la pila monótona: cada elemento entra y sale una vez.

**02 → 9.** Demuestra que los bordes de `s` son `π[n−1]`, `π[π[n−1]−1]`, … 🟠

⏱️ **30 segundos.** El borde de un borde es un borde, y no hay bordes intermedios entre un borde y el borde más largo de él.

🗣️ **2 minutos.** Si `b` es borde de `s` y `c` es borde de `b`, `c` es prefijo y sufijo de `s`. Y si `x` es un borde de `s` más corto que el más largo `B`, entonces `x` es prefijo y sufijo de `B` (ambos son prefijos y sufijos de `s`): es un borde de `B`. Por inducción, la cadena `π[n−1], π[π[n−1]−1], …` los enumera todos.

🔬 **El detalle.** Por eso los bordes forman una cadena (un camino en el «árbol de fallos»).

**02 → 10.** ¿Cómo compruebas si `b` es una rotación de `a` en lineal? 🟠

⏱️ **30 segundos.** Comprobar que tienen la misma longitud y buscar `b` en `a + a` con KMP.

🗣️ **2 minutos.** Toda rotación `yx` de `a = xy` es subcadena de `xyxy`, y toda subcadena de longitud `n` de `a + a` es una rotación. Coste `Θ(n)`.

🔬 **El detalle.** La rotación lexicográficamente mínima se obtiene también en lineal (Booth, o Duval).

**02 → 11.** ¿Cómo se construye el autómata de KMP y para qué DP sirve? 🟠

⏱️ **30 segundos.** `δ[q][c] = q + 1` si `p[q] = c`; si no, `δ[π[q − 1]][c]` (0 desde el estado 0). Sirve para las DP sobre `(posición, estado)` que cuentan cadenas que contienen o evitan `p`.

🗣️ **2 minutos.** Se construye en `Θ(m · σ)` reutilizando las filas ya calculadas. La DP «cadenas de longitud `n` que no contienen `p`» suma, para cada estado `q < m`, las transiciones a estados `< m`: `Θ(n · m · σ)`.

🔬 **El detalle.** Con `n` enorme, la DP se convierte en potencia de una matriz `m × m` ([`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md)).

**02 → 12.** ¿Cómo calculas cuántas veces aparece cada prefijo de `s` dentro de `s`? 🔴

⏱️ **30 segundos.** Contar, para cada `k`, cuántas posiciones tienen `π = k`, y propagar de cada `k` a `π[k − 1]` de mayor a menor; después sumar 1 por la aparición en la posición 0.

🗣️ **2 minutos.** Si el prefijo de longitud `k` termina en `i` (es sufijo de `s[0..i]`), también terminan ahí todos sus bordes. Por eso la cuenta de `k` se suma a la de `π[k − 1]`, en orden decreciente de `k`.

🔬 **El detalle.** Es la aplicación «número de apariciones de cada prefijo» de cp-algorithms.

**02 → 13.** ¿Qué relación hay entre tener periodo `p` y tener un borde de longitud `n − p`? Demuéstrala. 🔴

⏱️ **30 segundos.** `s` tiene periodo `p` si y solo si `s[0..n−p−1] = s[p..n−1]`, que es decir que el prefijo de longitud `n − p` es también sufijo: un borde.

🗣️ **2 minutos.** `s[i] = s[i + p]` para todo `i < n − p` dice exactamente que los `n − p` primeros caracteres coinciden con los `n − p` últimos. Así que cada borde da un periodo y viceversa, y el periodo más corto es `n −` el borde más largo.

🔬 **El detalle.** El lema de Fine y Wilf dice cuándo dos periodos `p` y `q` implican el periodo `gcd(p, q)`.

**02 → Problema: Sin solaparse.**

**Pista 2:** KMP, y al encontrar una aparición, contarla y reiniciar el estado a 0.

**Pista 3:** el voraz «marcar la primera que termina» es óptimo; lectura rápida con `10⁶` caracteres.

**02 → Problema: Encaje final.**

**Pista 2:** recorre `t` con el autómata (o el bucle) de KMP del patrón `p`; el estado final es la respuesta.

**Pista 3:** si `k` llega a `|p|`, baja a `π[|p| − 1]` y sigue, como en la búsqueda de solapadas; al final, `k`.

**02 → Problema: Cada prefijo, cuántas veces.**

**Pista 2:** cuenta cuántas posiciones tienen cada valor de `π` y propaga a los bordes.

**Pista 3:** `ans[π[i]]++`; luego, de `k = n − 1` a 1, `ans[π[k − 1]] += ans[k]`; finalmente suma 1 a cada `ans[k]`.

**02 → Problema: Repeated Substring Pattern.**

**Pista 2:** periodo más corto `p = n − π[n − 1]`.

**Pista 3:** la respuesta es sí si `p < n` y `n % p == 0`.

**02 → Problema: String Matching.**

**Pista 2:** KMP con todas las apariciones solapadas.

**Pista 3:** pares de líneas patrón y texto hasta el final de la entrada; imprime las posiciones separadas por espacios.

**02 → Problema: Power Strings.**

**Pista 2:** periodo más corto con la función de prefijo.

**Pista 3:** si divide a `n`, la respuesta es `n / p`; si no, 1. La entrada termina con un punto.

**02 → Problema: Repeated String Match.**

**Pista 2:** repite `a` hasta que su longitud sea al menos `|b|`, y prueba con una copia más.

**Pista 3:** busca `b` con KMP en esas dos candidatas; si no aparece en ninguna, `-1`.

**02 → Problema: Form Array by Concatenating Subarrays of Another Array.**

**Pista 2:** busca cada grupo en `nums` con KMP sobre arreglos de enteros, empezando donde terminó el anterior.

**Pista 3:** si un grupo no aparece desde la posición actual, `false`; tras encontrarlo, avanza al final de esa aparición.

**02 → Problema: Shortest Palindrome.**

**Pista 2:** el prefijo palindrómico más largo de `s` es el borde más largo de `s + '#' + inversa(s)`.

**Pista 3:** añade delante la inversa del resto: `inversa(s[k:]) + s` con `k = π` final.

**02 → Problema: Camp Schedule.**

**Pista 2:** tras colocar `t`, la siguiente aparición se puede solapar por su borde más largo: cada copia extra necesita `t[π:]`.

**Pista 3:** construye voraz con los ceros y unos disponibles: primero `t` y luego repeticiones de `t[π:]` mientras alcancen; el resto, al final.

**02 → Problema: MUH and Cube Walls.**

**Pista 2:** compara las diferencias entre torres consecutivas: subir o bajar el muro entero no las cambia.

**Pista 3:** KMP del arreglo de diferencias del muro pequeño sobre el del grande; con `w = 1`, la respuesta es `n`.

**02 → Problema: Password.**

**Pista 2:** los candidatos son los bordes de `s`; uno vale si aparece también en medio (sin ser prefijo ni sufijo).

**Pista 3:** un borde de longitud `k` aparece en medio si algún `π[i] ≥ k` con `i < n − 1`; prueba el borde más largo y, si no, `π[k − 1]`.

**02 → Problema: Minimum Time to Revert Word to Initial State II.**

**Pista 2:** tras `t` segundos, la palabra vuelve si el sufijo que queda (`word[k · t:]`) es prefijo: un borde (o `k · t ≥ n`).

**Pista 3:** con la función de prefijo (o Z), recorre los bordes y quédate con el menor `t` tal que `n − k · t` es longitud de un borde; si ninguno, `⌈n / k⌉`.

**02 → Problema: Required Substring.**

**Pista 2:** cuenta las cadenas que **evitan** el patrón con la DP sobre el autómata, y réstalas de `26ⁿ`.

**Pista 3:** `dp[i][q]` = cadenas de longitud `i` en el estado `q < m`; `Θ(n · m · 26)`, módulo `10⁹ + 7`.

---

# 03 — Función Z y Manacher

**03 → 1.** ¿Qué guarda `Z[i]`? 🟢

⏱️ **30 segundos.** La longitud del prefijo común más largo entre `s` y el sufijo que empieza en `i`.

🗣️ **2 minutos.** En `abracadabra`, `Z[7] = 4` porque `abra` empieza en 7 y es el prefijo; `Z[3] = 1` porque solo coincide la `a`. Por convenio, `Z[0]` es 0 o `n`.

🔬 **El detalle.** `Z[i] = n − i` significa que el sufijo entero es prefijo: `i` es un periodo.

**03 → 2.** ¿Qué es la caja `[l, r)` de la función Z? 🟢

⏱️ **30 segundos.** El segmento `[l, r)` más a la derecha ya verificado que coincide con un prefijo de `s`.

🗣️ **2 minutos.** Dentro de la caja, `s[i..r)` es copia de `s[i − l..r − l)`, así que `Z[i − l]` (ya calculado) da una cota inferior de `Z[i]`. Solo hay que comparar lo que pasa de `r`.

🔬 **El detalle.** Es la misma idea que el retroceso por bordes de KMP: no volver a leer lo ya leído.

**03 → 3.** ¿Cómo buscas un patrón con la función Z? 🟢

⏱️ **30 segundos.** Con la función Z de `p + '#' + t`: las posiciones de `t` con `Z = |p|` son inicios de apariciones.

🗣️ **2 minutos.** El separador garantiza que ninguna coincidencia con el prefijo se alarga más allá de `|p|`. Coste `Θ(n + m)`.

🔬 **El detalle.** Es la búsqueda más corta de escribir con garantía lineal.

**03 → 4.** ¿Por qué la función Z es lineal? 🟡

⏱️ **30 segundos.** Porque cada comparación con éxito mueve `r` a la derecha, y `r` nunca retrocede: como mucho `n` comparaciones con éxito, más una fallida por posición.

🗣️ **2 minutos.** Dentro de la caja, si `Z[i − l] < r − i`, no hay ninguna comparación (se copia el valor). Si llega al borde, las comparaciones nuevas extienden la caja. En total, `Θ(n)`.

🔬 **El detalle.** El mismo argumento de «el puntero derecho solo avanza» que en Manacher.

**03 → 5.** ¿Qué diferencia hay entre lo que dicen `π[i]` y `Z[i]`? 🟡

⏱️ **30 segundos.** `π[i]` es el borde más largo que **termina** en `i`; `Z[i]`, el prefijo común más largo que **empieza** en `i`.

🗣️ **2 minutos.** Llevan la misma información: si `Z[i] = k`, el prefijo de longitud `j` termina en `i + j − 1` para todo `j ≤ k`, lo que da cotas para `π`. Hay conversiones lineales en los dos sentidos.

🔬 **El detalle.** Para problemas «hacia delante» (cuánto coincide desde aquí) es más natural Z; para autómatas y DP, `π`.

**03 → 6.** ¿Para qué sirve intercalar `#` en Manacher? 🟡

⏱️ **30 segundos.** Para tratar igual los palíndromos pares e impares: en la cadena intercalada, todos tienen un centro que es un carácter.

🗣️ **2 minutos.** Un palíndromo par de `s` tiene su centro entre dos letras; en `#a#b#b#a#`, ese centro es un `#`. Con una sola pasada se obtienen los dos tipos, y el radio en la cadena intercalada menos 1 es la longitud en `s`.

🔬 **El detalle.** La versión sin separador calcula dos arreglos, `d1` (impares) y `d2` (pares).

**03 → 7.** ¿Cómo recuperas el palíndromo más largo a partir del arreglo de Manacher? 🟡

⏱️ **30 segundos.** Tomando el centro `i` con mayor longitud `len[i]`: el palíndromo empieza en `(i − len[i]) / 2` de `s` y mide `len[i]`.

🗣️ **2 minutos.** En la cadena intercalada, la posición `i` corresponde a la letra `(i − 1) / 2` (si `i` es impar) o al hueco entre letras (si es par). El inicio en `s` sale de restar el radio y dividir entre 2.

🔬 **El detalle.** Con empates, el enunciado suele pedir el primero: recorre en orden y usa `>`.

**03 → 8.** ¿Por qué Manacher es lineal? 🟠

⏱️ **30 segundos.** Porque el extremo derecho `r` del palíndromo más a la derecha solo avanza, y solo se compara fuera de él.

🗣️ **2 minutos.** Dentro de `[l, r]`, el radio de `i` se hereda del simétrico (recortado a la caja) sin comparar; cada comparación con éxito amplía `r`. Comparaciones con éxito `≤ n`, fallidas `≤` una por centro.

🔬 **El detalle.** Es el mismo esquema de amortización que la función Z.

**03 → 9.** ¿Cómo cuentas todas las subcadenas palindrómicas con Manacher, y de qué tipo es el resultado? 🟠

⏱️ **30 segundos.** Cada centro con longitud máxima `len` contiene `⌈len / 2⌉` palíndromos (los de longitudes `len`, `len − 2`, …); se suman. Resultado en 64 bits.

🗣️ **2 minutos.** En la cadena intercalada, con radio `d`, el centro aporta `⌊d / 2⌋` palíndromos de `s`. Con `n = 10⁶` letras iguales, el total es `n(n + 1)/2 ≈ 5·10¹¹`.

🔬 **El detalle.** En `abracadabra`, 13: once letras, `aca` y `ada`.

**03 → 10.** ¿Cómo encuentras las apariciones de un patrón con como mucho un error en lineal? 🟠

⏱️ **30 segundos.** Con la función Z de `p + '#' + t` (cuánto coincide hacia delante desde `i`) y la de las inversas (cuánto hacia atrás desde el final de la ventana): hay como mucho un error si suman `≥ m − 1`.

🗣️ **2 minutos.** Si los `x` primeros caracteres coinciden y los `y` últimos también, el único hueco posible es la posición `x`; con `x + y ≥ m − 1`, cubren todo menos como mucho una posición. Dos Z, `Θ(n + m)`.

🔬 **El detalle.** Con `k` errores, se repite el salto `k` veces con LCP en `O(1)` (sufijos o *hashing*): `O(n · k)`.

**03 → 11.** ¿Cuándo prefieres expandir desde los centros a Manacher? 🟠

⏱️ **30 segundos.** Con `n` pequeño (hasta unos miles) o en una entrevista: la expansión desde los centros es corta, sin trucos y `Θ(n²)`.

🗣️ **2 minutos.** Con `n = 1 000`, son `10⁶` pasos: sobra. Manacher compensa a partir de `10⁵`, y es más fácil equivocarse con los índices de la cadena intercalada.

🔬 **El detalle.** Escribir primero la expansión sirve además como fuerza bruta para probar Manacher.

**03 → 12.** ¿Cómo respondes `q` consultas «¿es `s[l..r]` palíndromo?» en `O(1)` cada una? 🔴

⏱️ **30 segundos.** Con Manacher: `s[l..r]` es palíndromo si el palíndromo maximal centrado en su centro mide al menos `r − l + 1`.

🗣️ **2 minutos.** El centro de `s[l..r]` en la cadena intercalada es `l + r + 1`; basta comparar `len[l + r + 1] ≥ r − l + 1`. Un preproceso `Θ(n)` y `O(1)` por consulta.

🔬 **El detalle.** Con modificaciones de letras, hace falta *hashing* en un árbol de segmentos o Fenwick ([`16/04`](04-hashing-de-cadenas.md)).

**03 → 13.** ¿Cómo calculas, en lineal, el prefijo palindrómico más largo de una cadena con la función Z? 🔴

⏱️ **30 segundos.** Con la función Z de `s + '#' + inversa(s)`: el prefijo palindrómico más largo es el mayor `k` tal que en la posición `n + 1 + (n − k)` la Z vale `k`.

🗣️ **2 minutos.** Un prefijo de longitud `k` es palíndromo si es igual a su inversa, es decir, si coincide con el sufijo de longitud `k` de `inversa(s)`. Con la Z de la concatenación, se comprueba cada `k` en `O(1)`.

🔬 **El detalle.** Con la función de prefijo es todavía más directo: el valor final de `π` sobre esa misma cadena.

**03 → Problema: Todos los palíndromos.**

**Pista 2:** Manacher y, por cada centro, la cantidad de palíndromos que contiene.

**Pista 3:** suma `⌈len[i] / 2⌉` sobre la cadena intercalada (o `d1[i] + d2[i]` en la versión de dos arreglos); 64 bits.

**03 → Problema: Con un error.**

**Pista 2:** `Z` de `p + '#' + t` y `Z` de `inversa(p) + '#' + inversa(t)`.

**Pista 3:** para la ventana que empieza en `i`, `pre = Z₁[m + 1 + i]` y `suf = Z₂[m + 1 + (n − i − m)]`; cuenta si `pre + suf ≥ m − 1`.

**03 → Problema: Longest Palindromic Substring.**

**Pista 2:** expansión desde los `2n − 1` centros, o Manacher.

**Pista 3:** para cada centro, expande mientras coincidan los extremos y guarda el mejor inicio y longitud.

**03 → Problema: Longest Palindrome.**

**Pista 2:** Manacher sobre `10⁶` caracteres.

**Pista 3:** imprime la subcadena del máximo; si hay varias, cualquiera.

**03 → Problema: Shortest String That Contains Three Strings.**

**Pista 2:** para cada orden de las tres, une dos a dos con el mayor solape (o metiendo una si ya contiene a la otra).

**Pista 3:** prueba las 6 permutaciones y quédate con la más corta y, en empate, la menor; con longitudes `≤ 100`, el solape por fuerza bruta basta.

**03 → Problema: Prefixes and Suffixes.**

**Pista 2:** los prefijos que son sufijos son las `i` con `Z[n − i] = i` (o la cadena de bordes); las apariciones de cada prefijo, contando `Z` con un acumulado.

**Pista 3:** `cnt[k]` = posiciones con `Z ≥ k` (acumula desde el final un histograma de `Z`), más 1 por la posición 0.

**03 → Problema: Prefix-Suffix Palindrome (Hard version).**

**Pista 2:** quita los extremos simétricos mientras coincidan; en lo que queda, busca el prefijo o el sufijo palindrómico más largo.

**Pista 3:** el prefijo palindrómico más largo con `π` (o Z) de `m + '#' + inversa(m)`; lo mismo para el sufijo con la inversa; elige el mayor.

**03 → Problema: Sum of Scores of Built Strings.**

**Pista 2:** la puntuación de cada cadena construida es el prefijo común con la final: `Z` de la cadena.

**Pista 3:** suma `Z[i]` para `i ≥ 1` más `n` (la cadena completa); 64 bits.

**03 → Problema: Maximum Product of the Length of Two Palindromic Substrings.**

**Pista 2:** Manacher de radios impares y, para cada posición, el palíndromo impar más largo que termina antes y el que empieza después.

**Pista 3:** propaga los máximos: si hay uno de longitud `L` terminando en `i`, hay uno de `L − 2` terminando en `i − 1`; prefijo y sufijo de máximos, y el producto en cada corte.

**03 → Problema: Find Beautiful Indices in the Given Array II.**

**Pista 2:** todas las apariciones de `a` y de `b` con Z (o KMP), en orden creciente.

**Pista 3:** para cada aparición de `a`, una búsqueda binaria (o dos punteros) en las de `b` comprueba si hay alguna a distancia `≤ k`.

---

# 04 — Hashing de cadenas aplicado

**04 → 1.** ¿Cómo se obtiene el *hash* de una subcadena a partir de los prefijos? 🟢

⏱️ **30 segundos.** `h(s[l..r)) = H[r] − H[l] · Bʳ⁻ˡ` módulo `M`, con `H` los *hashes* de los prefijos y las potencias de la base precalculadas.

🗣️ **2 minutos.** `H[r]` es `s₀ Bʳ⁻¹ + … + s_{r−1}`; quitarle `H[l]` desplazado `r − l` posiciones deja exactamente los términos de `s[l..r)`. Preproceso `Θ(n)` y consulta `O(1)`.

🔬 **El detalle.** La resta módulo `M` necesita sumar `M` si queda negativa.

**04 → 2.** ¿Por qué un *hash* igual no garantiza que las cadenas sean iguales? 🟢

⏱️ **30 segundos.** Porque hay muchas más cadenas que valores de *hash*: dos distintas pueden caer en el mismo valor (colisión).

🗣️ **2 minutos.** Lo que se garantiza es que, con base aleatoria y módulo primo, la probabilidad de colisión es pequeña: `≤ (L − 1)/M` por comparación. Hash distinto sí prueba que son distintas.

🔬 **El detalle.** Por eso en un algoritmo exacto se confirma con una comparación carácter a carácter cuando importa (Rabin-Karp «Las Vegas»).

**04 → 3.** ¿Qué es la búsqueda binaria + *hash* y qué propiedad necesita? 🟢

⏱️ **30 segundos.** Búsqueda binaria sobre la longitud `L` de la respuesta, comprobando cada `L` con los *hashes* de las ventanas de esa longitud. Necesita que la propiedad sea monótona en `L`.

🗣️ **2 minutos.** «Hay una subcadena repetida de longitud `L`» implica lo mismo para `L − 1`: la binaria encuentra el mayor `L`. Cada prueba recorre las `n − L + 1` ventanas: `Θ(n log n)` en total.

🔬 **El detalle.** Es la «binaria sobre la respuesta» de [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md) con un verificador por *hash*.

**04 → 4.** ¿Cómo calculas el LCP de dos sufijos con *hashes*? 🟡

⏱️ **30 segundos.** Con una búsqueda binaria sobre `L`, comparando los *hashes* de `s[a..a+L)` y `s[b..b+L)`: `O(log n)`.

🗣️ **2 minutos.** La igualdad de prefijos de longitud `L` es monótona: si coinciden `L` caracteres, coinciden los `L − 1` primeros. La binaria encuentra la mayor `L` con *hashes* iguales.

🔬 **El detalle.** Con muchas consultas, un *suffix array* con LCP y una tabla dispersa da `O(1)` por consulta ([`16/06`](06-suffix-array-y-automaton.md)).

**04 → 5.** ¿Cómo comparas lexicográficamente dos subcadenas con *hashes*? 🟡

⏱️ **30 segundos.** Calculando el LCP `l` con *hashes*; si `l` alcanza la longitud, son iguales; si no, decide el carácter `l`-ésimo de cada una.

🗣️ **2 minutos.** El orden lexicográfico lo fija el primer carácter distinto, que está justo después del prefijo común. `O(log n)` por comparación permite incluso ordenar sufijos con un `sort` (`O(n log² n)`).

🔬 **El detalle.** Si una es prefijo de la otra, la más corta va antes.

**04 → 6.** ¿Por qué se elige la base al azar? 🟡

⏱️ **30 segundos.** Porque la cota de colisión `(L − 1)/M` vale para una base elegida al azar después de conocer las cadenas; con una base fija, alguien puede construir cadenas que colisionen.

🗣️ **2 minutos.** Los jueces de concurso (y los ataques a servicios web) incluyen entradas diseñadas contra bases conocidas. Elegir la base con un generador sembrado por la hora hace imposible preparar la entrada.

🔬 **El detalle.** Con módulo `2⁶⁴` (desbordamiento) ni siquiera la base aleatoria salva: las cadenas de Thue-Morse colisionan para toda base impar.

**04 → 7.** ¿Cómo implementas el producto módulo `2⁶¹ − 1` en C++, en Java y en Python? 🟡

⏱️ **30 segundos.** C++: producto de 128 bits (`__uint128_t`) y reducción con `& MOD` y `>> 61`. Java: `Math.multiplyHigh` para la parte alta y la misma reducción. Python: `a * b % MOD`, porque sus enteros no desbordan.

🗣️ **2 minutos.** Como `2⁶¹ ≡ 1` módulo `2⁶¹ − 1`, el producto `alto · 2⁶¹ + bajo` se reduce sumando las dos mitades. En Java, la parte alta de 64 bits se multiplica por 8 (`2⁶⁴ ≡ 2³`).

🔬 **El detalle.** La alternativa portable son dos módulos de `10⁹` con productos en 64 bits, con el doble de operaciones.

**04 → 8.** Acota la probabilidad de que dos cadenas distintas de longitud `L` colisionen con base aleatoria. 🟠

⏱️ **30 segundos.** `≤ (L − 1)/M`: la diferencia de los dos *hashes* es un polinomio no nulo de grado `< L` en la base, con como mucho `L − 1` raíces entre los `M` valores posibles.

🗣️ **2 minutos.** Si las cadenas difieren, el polinomio `Σ (aᵢ − bᵢ) x^{L−1−i}` no es idénticamente 0 módulo `M` (primo). Colisionan solo si la base es una de sus raíces; con la base uniforme, la probabilidad es la proporción de raíces.

🔬 **El detalle.** Con `M = 2⁶¹ − 1` y `L = 10⁵`, del orden de `4·10⁻¹⁴` por comparación.

**04 → 9.** ¿Por qué meter `10⁵` *hashes* en un conjunto con módulo `10⁹` es arriesgado? Haz la cuenta. 🟠

⏱️ **30 segundos.** Porque hay `n²/2 = 5·10⁹` pares y cada uno colisiona con probabilidad del orden de `1/M = 10⁻⁹`: se esperan unas 5 colisiones. Es la paradoja del cumpleaños.

🗣️ **2 minutos.** Con `M ≈ 2⁶¹`, la esperanza baja a `5·10⁹ / 2,3·10¹⁸ ≈ 2·10⁻⁹`. Por eso los problemas de «todas las ventanas en un conjunto» piden un módulo grande o dos.

🔬 **El detalle.** La regla práctica: hacen falta `M ≫ (número de *hashes*)²`.

**04 → 10.** ¿Cómo compruebas si una subcadena es palíndromo con *hashes*, y cómo lo mantienes con modificaciones? 🟠

⏱️ **30 segundos.** Comparando el *hash* de `s[l..r)` con el del tramo simétrico de la inversa de `s`. Con modificaciones, los *hashes* de prefijos se guardan en un Fenwick o árbol de segmentos, uno para cada sentido.

🗣️ **2 minutos.** En la inversa, `s[l..r)` corresponde a `rev[n − r..n − l)`. Con un Fenwick sobre `sᵢ · Bⁱ`, cambiar una letra es una actualización puntual y el *hash* de un tramo, una resta de prefijos (normalizada por la potencia).

🔬 **El detalle.** Sin modificaciones, Manacher lo resuelve en `O(1)` por consulta y sin probabilidad.

**04 → 11.** ¿Cuándo prefieres KMP o Z a *hashing*? 🔴

⏱️ **30 segundos.** Siempre que el problema sea buscar un patrón fijo o calcular bordes, periodos o palíndromos estáticos: KMP, Z y Manacher son exactos y lineales.

🗣️ **2 minutos.** El *hash* se reserva para comparar subcadenas arbitrarias o para la binaria sobre la longitud, donde no hay un algoritmo exacto tan corto. Si existe uno lineal y exacto, el *hash* solo añade riesgo.

🔬 **El detalle.** En una entrevista, el *hash* es también la primera idea razonable cuando no se recuerda el algoritmo exacto; se dice explícitamente.

**04 → 12.** Calcula la subcadena común más larga de dos cadenas de `10⁵` y di el coste. 🔴

⏱️ **30 segundos.** Binaria sobre `L`: para cada `L`, los *hashes* de las ventanas de `a` en un conjunto (u ordenados) y buscar alguna ventana de `b`. `Θ((|a| + |b|) log)`.

🗣️ **2 minutos.** La propiedad «comparten una subcadena de longitud `L`» es monótona. Con el mismo módulo y la misma base para las dos cadenas, una coincidencia de *hashes* indica (con alta probabilidad) una subcadena común.

🔬 **El detalle.** La versión exacta: *suffix array* de `a + '#' + b` y el mayor LCP entre sufijos adyacentes de cadenas distintas (`16/06`).

**04 → Problema: ¿Antes o después?.**

**Pista 2:** prefijos de *hash* y LCP por binaria entre las dos posiciones.

**Pista 3:** si el LCP es `≥ L`, `=`; si no, compara el carácter siguiente al LCP. `O(log n)` por consulta.

**04 → Problema: La subcadena común más larga.**

**Pista 2:** binaria sobre la longitud `L` con los *hashes* de las ventanas de las dos cadenas.

**Pista 3:** para cada `L`, ordena los *hashes* de `a` y busca los de `b` con búsqueda binaria (o un conjunto); módulo `2⁶¹ − 1` y la misma base para las dos.

**04 → Problema: String Hashing.**

**Pista 2:** prefijos de *hash* y la fórmula de la subcadena.

**Pista 3:** sigue el módulo y la base que fija el enunciado; las potencias precalculadas.

**04 → Problema: Finding Patterns.**

**Pista 2:** agrupa los patrones por longitud; para cada longitud distinta, los *hashes* de las ventanas del texto en un conjunto.

**Pista 3:** hay como mucho `O(√(suma de longitudes))` longitudes distintas; cada una cuesta una pasada por el texto.

**04 → Problema: Longest Duplicate Substring.**

**Pista 2:** binaria sobre la longitud y los *hashes* de las ventanas.

**Pista 3:** guarda la posición junto al *hash* para devolver la subcadena; módulo `2⁶¹ − 1` (o doble) y base aleatoria.

**04 → Problema: Petr#.**

**Pista 2:** las subcadenas que empiezan con `sbegin` y terminan con `send` (sin solapar mal) se cuentan como distintas por su *hash*.

**Pista 3:** marca dónde empieza `sbegin` y dónde termina `send`; para cada par válido de inicio y fin con longitud suficiente, mete el *hash* en un conjunto: `O(n²)` *hashes* con `n ≤ 2 000`.

**04 → Problema: Palindrome Queries.**

**Pista 2:** dos Fenwick con los *hashes* de la cadena y de la inversa; una modificación cambia un punto en cada uno.

**Pista 3:** compara el *hash* de `s[a..b]` con el del tramo simétrico de la inversa, normalizando las potencias (multiplica el de menor exponente).

**04 → Problema: Longest Common Subpath.**

**Pista 2:** binaria sobre la longitud; para cada `L`, los *hashes* de las ventanas de cada camino, intersecados.

**Pista 3:** empieza con el conjunto del camino más corto e interseca con los demás; módulo grande (o doble), porque hay muchas ventanas.

**04 → Problema: Count Prefix and Suffix Pairs II.**

**Pista 2:** para cada palabra, los `k` tales que su prefijo de longitud `k` es también sufijo (bordes); cuenta cuántas palabras anteriores son exactamente ese borde.

**Pista 3:** un mapa de *hash* de palabra a número de apariciones; recorre los bordes con *hashes* (o con la función Z) y suma.

**04 → Problema: Double Profiles.**

**Pista 2:** el *hash* de un perfil es la suma de valores aleatorios de sus amigos; dos perfiles son dobles si sus *hashes* coinciden, con o sin incluirse a sí mismos.

**Pista 3:** cuenta pares con el mismo *hash* de vecinos (sin incluirse) y los pares adyacentes con el mismo *hash* incluyéndose; 64 bits aleatorios por vértice.

---

# 05 — Aho-Corasick

**05 → 1.** ¿Qué es el enlace de fallo de un nodo del trie? 🟢

⏱️ **30 segundos.** El nodo del sufijo propio más largo de la cadena del nodo que también está en el trie (es prefijo de algún patrón).

🗣️ **2 minutos.** Cuando el siguiente carácter no tiene hijo, se salta al fallo y se intenta desde ahí, sin retroceder en el texto. En el ejemplo, `fail(bra) = a` y `fail(ab) = b`.

🔬 **El detalle.** La raíz falla a sí misma, y los nodos de profundidad 1, a la raíz.

**05 → 2.** ¿Cuánto cuesta buscar `k` patrones con KMP uno a uno, y cuánto con Aho-Corasick? 🟢

⏱️ **30 segundos.** `k` veces KMP: `Θ(k · n + L)`. Aho-Corasick: `Θ(n + L · σ)` para contar, más las apariciones si se enumeran.

🗣️ **2 minutos.** Con `10⁴` patrones y `10⁶` caracteres, KMP uno a uno son `10¹⁰` pasos; Aho-Corasick recorre el texto una vez. La construcción depende solo de la suma de longitudes de los patrones.

🔬 **El detalle.** Con mapas por nodo en lugar del autómata completo, la construcción baja a `Θ(L)` (amortizado) a cambio de un `log σ` o un *hash* por transición.

**05 → 3.** ¿Por qué los enlaces de fallo se calculan por BFS? 🟢

⏱️ **30 segundos.** Porque el fallo de un nodo es menos profundo que él, y tiene que estar calculado antes; el BFS procesa por niveles.

🗣️ **2 minutos.** Para calcular `fail(u + c)` se sigue la cadena de fallos de `u`, que son nodos de menor profundidad. En un DFS, un nodo profundo de una rama podría necesitar el fallo de un nodo de otra rama todavía no visitado.

🔬 **El detalle.** El orden BFS sirve además, invertido, para propagar los conteos de los hijos de fallo a sus fallos.

**05 → 4.** ¿Qué relación hay entre Aho-Corasick con un patrón y KMP? 🟡

⏱️ **30 segundos.** Con un solo patrón, el trie es una línea y los enlaces de fallo son la función de prefijo: Aho-Corasick es KMP.

🗣️ **2 minutos.** El nodo de profundidad `k` es el prefijo de longitud `k` del patrón, y su fallo es su borde más largo: `π[k − 1]`. El autómata completo es el autómata de KMP.

🔬 **El detalle.** Por eso Aho y Corasick citan a Knuth, Morris y Pratt: es la misma idea en un árbol.

**05 → 5.** ¿Qué es el enlace de salida y para qué sirve? 🟡

⏱️ **30 segundos.** Un puntero de cada nodo al terminal más cercano en su cadena de fallos. Sirve para reportar todas las apariciones de una posición sin recorrer nodos que no son patrones.

🗣️ **2 minutos.** Sin él, en cada posición habría que subir por toda la cadena de fallos, que puede ser larga aunque haya pocos terminales. Con él, el coste es el número de apariciones reportadas.

🔬 **El detalle.** Se calcula en el BFS: `salida(v) = fail(v)` si es terminal, y si no, `salida(fail(v))`.

**05 → 6.** ¿Cómo cuentas las apariciones de cada patrón sin enumerarlas? 🟡

⏱️ **30 segundos.** Contando cuántas veces se visita cada nodo al recorrer el texto y propagando esas visitas por el árbol de fallos, de los nodos profundos a la raíz.

🗣️ **2 minutos.** Una visita al nodo `u` es una aparición de todos los patrones de su cadena de fallos. Sumar las visitas de cada nodo a su fallo, en BFS inverso, deja en cada terminal el número total de apariciones del patrón. `Θ(n + nodos)`.

🔬 **El detalle.** Los enlaces de fallo forman un árbol con raíz en la raíz del trie: es una suma por subárboles.

**05 → 7.** ¿Qué cambia en la implementación con un alfabeto grande? 🟡

⏱️ **30 segundos.** El autómata completo `nodos × σ` no cabe: se guardan mapas por nodo y la transición se calcula al vuelo siguiendo fallos, como en KMP.

🗣️ **2 minutos.** El coste por carácter pasa a ser amortizado (por el mismo potencial que KMP) y cada transición cuesta un acceso a un mapa. La memoria baja a `Θ(L)`.

🔬 **El detalle.** Un término medio: autómata completo solo para la raíz y los primeros niveles.

**05 → 8.** Explica por qué el estado tras leer `t[0..i]` es el sufijo más largo de lo leído que está en el trie. 🟠

⏱️ **30 segundos.** Por inducción: si el estado es el sufijo más largo en el trie de `t[0..i−1]`, el sufijo más largo en el trie de `t[0..i]` es una extensión por `t[i]` de alguno de sus sufijos en el trie, y la cadena de fallos los recorre de mayor a menor.

🗣️ **2 minutos.** Cualquier sufijo de `t[0..i]` en el trie, quitando su último carácter, es un sufijo de `t[0..i−1]` en el trie, es decir, el estado o alguno de su cadena de fallos. La transición `go` prueba esos candidatos en orden decreciente y se queda con el primero que se extiende.

🔬 **El detalle.** Es la misma prueba que la de la función de prefijo, con el conjunto de prefijos de todos los patrones en lugar de los de uno.

**05 → 9.** ¿Cuántas apariciones puede haber en total, y por qué enumerarlas puede ser caro? 🟠

⏱️ **30 segundos.** Hasta `Θ(n · √L)`: con patrones de longitudes distintas `1, 2, …, √L`, cada posición puede ser final de `√L` de ellos.

🗣️ **2 minutos.** El número de longitudes distintas está acotado por `√(2L)`, porque su suma es `L`; y en cada posición, como mucho termina un patrón de cada longitud. Enumerar todas las apariciones puede ser `10⁶ · 450`.

🔬 **El detalle.** Con patrones repetidos o un solo patrón muy repetido, el número de patrones distintos que terminan en una posición sigue acotado por las longitudes distintas.

**05 → 10.** ¿Cómo cuentas las cadenas de longitud `n` que no contienen ninguno de `k` patrones? 🟠

⏱️ **30 segundos.** DP sobre `(posición, nodo)` del autómata, prohibiendo los nodos «malos»: los que son terminales o tienen un terminal en su cadena de fallos. `Θ(n · nodos · σ)`.

🗣️ **2 minutos.** Un nodo es malo si la cadena actual termina en una palabra prohibida. Se marca en el BFS: `malo(v) = terminal(v) o malo(fail(v))`. La respuesta es la suma de la DP en la longitud `n` sobre los nodos buenos.

🔬 **El detalle.** Con `n` enorme, la DP es una potencia de la matriz de transiciones entre nodos buenos (`13/06`).

**05 → 11.** ¿Qué alternativa con *hashing* hay para muchos patrones, y cuánto cuesta? 🔴

⏱️ **30 segundos.** Agrupar los patrones por longitud: para cada longitud distinta, los *hashes* de las ventanas del texto de esa longitud en un conjunto. `Θ(n · √L)`, porque hay como mucho `√(2L)` longitudes distintas.

🗣️ **2 minutos.** Es más corto de escribir que Aho-Corasick y suele bastar con `L ≤ 10⁵`; tiene la probabilidad de colisión de `16/04`.

🔬 **El detalle.** Es la solución habitual de Finding Patterns por *hashing*.

**05 → 12.** ¿Cómo marcas (censuras) todas las posiciones del texto cubiertas por alguna aparición, en lineal? 🔴

⏱️ **30 segundos.** Con Aho-Corasick, en cada posición la longitud del patrón **más largo** que termina ahí; esa aparición tapa un tramo, y se marca con un arreglo de diferencias o barriendo de derecha a izquierda.

🗣️ **2 minutos.** El patrón más largo que termina en `i` contiene a todos los demás que terminan en `i` (son sufijos suyos), así que basta él. Se precalcula por nodo en el BFS: `largo(v) = longitud(v)` si es terminal, si no, `largo(fail(v))`. Después, recorriendo de derecha a izquierda con «cuántos caracteres quedan por tapar», cada posición se decide en `O(1)`.

🔬 **El detalle.** Es el problema Censura.

**05 → Problema: Censura.**

**Pista 2:** Aho-Corasick y, para cada nodo, la longitud de la palabra prohibida más larga en su cadena de fallos.

**Pista 3:** recorre el texto anotando en cada posición esa longitud; luego, de derecha a izquierda, lleva el máximo de «hasta dónde tapar» y sustituye por `*`.

**05 → Problema: Sin palabras prohibidas.**

**Pista 2:** DP sobre el autómata de Aho-Corasick con los nodos malos prohibidos.

**Pista 3:** `dp[i][v]` con transiciones `go[v][c]` para las `a` primeras letras; nodos malos = terminal o fallo malo. `Θ(n · nodos · a)`, módulo `10⁹ + 7`.

**05 → Problema: String Multimatching.**

**Pista 2:** Aho-Corasick con enlaces de salida para reportar todas las posiciones de cada patrón.

**Pista 3:** guarda por patrón la lista de posiciones de inicio (`i − |p| + 1`); patrones repetidos comparten nodo: repórtalos a todos.

**05 → Problema: Counting Patterns.**

**Pista 2:** visitas por nodo y propagación por el árbol de fallos en BFS inverso.

**Pista 3:** imprime, para cada patrón, las visitas acumuladas de su nodo terminal; 64 bits no hace falta, pero `int` justo.

**05 → Problema: Pattern Positions.**

**Pista 2:** la primera visita de cada nodo y el mínimo propagado por el árbol de fallos.

**Pista 3:** propaga el mínimo de la primera posición desde los hijos de fallo; la respuesta es `primera − |p| + 2` (desde 1) o `-1`.

**05 → Problema: Stream of Characters.**

**Pista 2:** Aho-Corasick de las palabras y el estado actual entre consultas; cada letra es una transición.

**Pista 3:** marca por nodo si algún terminal está en su cadena de fallos; la consulta responde esa marca del estado nuevo.

**05 → Problema: Determining DNA Health.**

**Pista 2:** Aho-Corasick de todos los genes; para cada cadena, las apariciones de genes con índice en `[first, last]`.

**Pista 3:** por nodo terminal, la lista de índices de gen con prefijos de salud; cada aparición suma la salud del rango con dos búsquedas binarias. Enumera con enlaces de salida.

**05 → Problema: Construct String with Minimum Cost.**

**Pista 2:** DP sobre la posición del objetivo: `dp[i]` = coste mínimo de construir `target[0..i)`, con las palabras que terminan en `i`.

**Pista 3:** las palabras que terminan en cada posición, con Aho-Corasick y enlaces de salida (para cada palabra, el mínimo coste si se repite); hay `O(√L)` longitudes distintas.

**05 → Problema: You Are Given Some Strings....**

**Pista 2:** `f[i]` = patrones que terminan en `i` y `g[i]` = patrones que empiezan en `i` (Aho-Corasick sobre las inversas); la respuesta es `Σ f[i] · g[i + 1]`.

**Pista 3:** cuenta con la propagación del número de terminales por la cadena de fallos; 64 bits.

**05 → Problema: Frequency of String.**

**Pista 2:** para cada consulta, las posiciones de su patrón y la ventana mínima que contiene `k` de ellas.

**Pista 3:** los patrones son distintos y suman `L`, así que el total de apariciones es `O(n √L)`; enuméralas con Aho-Corasick y recorre cada lista con dos punteros.

---

# 06 — *Suffix array*, LCP y *suffix automaton*

**06 → 1.** ¿Qué guarda el *suffix array* y qué guarda el arreglo LCP? 🟢

⏱️ **30 segundos.** `SA[k]` es la posición del `k`-ésimo sufijo en orden lexicográfico; `LCP[k]`, el prefijo común más largo entre los sufijos `SA[k − 1]` y `SA[k]`.

🗣️ **2 minutos.** En `abracadabra`, `SA = 10 7 0 3 5 8 1 4 6 9 2` y `LCP = 0 1 4 1 1 0 3 0 0 0 2`. El `4` es el prefijo `abra` que comparten los sufijos 7 y 0.

🔬 **El detalle.** El LCP de dos sufijos no adyacentes es el mínimo del LCP entre sus rangos.

**06 → 2.** ¿Cuántas subcadenas distintas tiene una cadena, en términos del LCP? 🟢

⏱️ **30 segundos.** `n(n + 1)/2 − Σ LCP[k]`.

🗣️ **2 minutos.** Cada subcadena es prefijo de algún sufijo; recorriendo los sufijos en orden, el sufijo `k` aporta sus prefijos menos los `LCP[k]` que ya aportó su predecesor. En `abracadabra`, `66 − 12 = 54`.

🔬 **El detalle.** En 64 bits: con `n = 10⁵`, el total ronda `5·10⁹`.

**06 → 3.** ¿Cuál es la subcadena repetida más larga, en términos del LCP? 🟢

⏱️ **30 segundos.** La de longitud `max LCP`, que empieza en cualquiera de los dos sufijos adyacentes donde se alcanza.

🗣️ **2 minutos.** Una subcadena repetida es prefijo común de dos sufijos; el mayor prefijo común de dos sufijos cualesquiera se alcanza entre dos adyacentes en el orden. En `abracadabra`, 4 (`abra`).

🔬 **El detalle.** Las apariciones pueden solaparse; si no deben, hace falta una condición sobre las posiciones.

**06 → 4.** ¿Por qué ordenar los sufijos con `sort` de cadenas es caro? 🟢

⏱️ **30 segundos.** Porque cada comparación entre dos sufijos puede costar `Θ(n)`, y un `sort` hace `Θ(n log n)` comparaciones: `Θ(n² log n)` en el peor caso (cadenas como `aaaa…`).

🗣️ **2 minutos.** Con textos aleatorios las comparaciones fallan pronto y va bien; con repeticiones largas, no. La duplicación compara en `O(1)` pares de rangos ya calculados.

🔬 **El detalle.** Con *hashing* y LCP por binaria, cada comparación es `O(log n)`: `Θ(n log² n)` con un `sort` normal.

**06 → 5.** Explica la duplicación: ¿qué par se ordena en cada ronda? 🟡

⏱️ **30 segundos.** En la ronda `j`, el par (rango del sufijo `i` por sus primeros `2^(j−1)` caracteres, rango del sufijo `i + 2^(j−1)` por los suyos).

🗣️ **2 minutos.** Comparar los primeros `2^j` caracteres es comparar la primera mitad y, si empatan, la segunda: justo el par de rangos. Con ordenación por conteo (dos pasadas estables), cada ronda es `Θ(n)`; hay `log n` rondas.

🔬 **El detalle.** Se para en cuanto todos los rangos son distintos, que en cadenas sin repeticiones largas ocurre pronto.

**06 → 6.** ¿Para qué sirve el `$` al final? 🟡

⏱️ **30 segundos.** Para que ningún sufijo se compare más allá de su final: el `$`, menor que todo, termina la comparación y pone primero al sufijo más corto.

🗣️ **2 minutos.** La implementación trata la cadena como cíclica; sin el `$`, el sufijo `abra` (posición 7) daría la vuelta y se compararía como `abraabra…`. Con `$`, `abra$` va antes que `abracadabra$`, como debe.

🔬 **El detalle.** Al final se quita el sufijo «`$`», que es siempre el primero.

**06 → 7.** ¿Cómo calculas el LCP de dos sufijos cualesquiera en `O(1)`? 🟡

⏱️ **30 segundos.** Con una tabla dispersa de mínimos sobre el arreglo LCP: el LCP de los sufijos `i` y `j` es el mínimo de `LCP` entre `rank[i] + 1` y `rank[j]`.

🗣️ **2 minutos.** La tabla dispersa da el mínimo de un tramo en `O(1)` tras `Θ(n log n)` de preproceso ([`09/01`](../09-consultas-sobre-rangos/01-sparse-table.md)). Entre dos sufijos del orden, el prefijo común es el del «cuello de botella» de los vecinos intermedios.

🔬 **El detalle.** Con esto se comparan subcadenas arbitrarias en `O(1)` y sin probabilidad de error, a diferencia del *hash*.

**06 → 8.** Demuestra que en Kasai el LCP baja como mucho uno de la posición `i` a la `i + 1`. 🟠

⏱️ **30 segundos.** Si el sufijo `i` comparte `h` con su predecesor `j`, quitando la primera letra los sufijos `i + 1` y `j + 1` comparten `h − 1` y `j + 1` va antes; su predecesor está entre ellos y comparte al menos `h − 1`.

🗣️ **2 minutos.** Con `h > 0`, `s[i] = s[j]` y `j < i` en el orden, así que `j + 1 < i + 1` en el orden y comparten `h − 1`. Todo sufijo entre ellos en el orden también comparte al menos `h − 1` con `i + 1`. Por eso Kasai empieza a comparar en `h − 1`; el total de subidas es `≤ 2n`.

🔬 **El detalle.** Es el lema central del artículo de Kasai y otros (2001).

**06 → 9.** ¿Cómo encuentras la subcadena común más larga de dos cadenas con un *suffix array*? 🟠

⏱️ **30 segundos.** *Suffix array* de `a + '#' + b` y el mayor LCP entre sufijos adyacentes que vienen de cadenas distintas (uno empieza antes del `#` y otro después).

🗣️ **2 minutos.** El separador, distinto de todo, impide que un prefijo común cruce de una cadena a la otra. La subcadena común más larga es prefijo de un sufijo de `a` y de uno de `b`, y el máximo de esos LCP se alcanza en algún par adyacente de orígenes distintos.

🔬 **El detalle.** Con `k` cadenas, ventana deslizante sobre el orden que contenga sufijos de todas, y el mínimo del LCP dentro.

**06 → 10.** ¿Cómo encuentras la subcadena más larga que aparece al menos `k` veces? 🟠

⏱️ **30 segundos.** Los `k` sufijos que empiezan con ella son consecutivos en el orden; la respuesta es el máximo, sobre ventanas de `k − 1` valores consecutivos de `LCP`, de su mínimo.

🗣️ **2 minutos.** Una subcadena de longitud `L` aparece `k` veces si y solo si hay `k` sufijos consecutivos con LCP mutuo `≥ L`, es decir, `k − 1` valores de LCP consecutivos `≥ L`. El mínimo en ventana con una cola monótona da `Θ(n)`.

🔬 **El detalle.** Con `k = 2` es el máximo LCP: la repetida más larga.

**06 → 11.** ¿Qué ofrece el *suffix automaton* que no ofrece el *suffix array*? 🟠

⏱️ **30 segundos.** Construcción en línea (carácter a carácter) y consultas de subcadena recorriendo el autómata en `O(|t|)`; además, es lineal sin el `log` de la duplicación.

🗣️ **2 minutos.** Sirve cuando la cadena crece por la derecha o cuando se recorre otra cadena contra ella (subcadena común más larga en lineal). El *suffix array* necesita la cadena completa de antemano.

🔬 **El detalle.** El árbol de enlaces de sufijo del autómata de la cadena invertida es el árbol de sufijos ([`16/08`](08-eertree-y-ukkonen.md)).

**06 → 12.** ¿Cómo encuentras la `k`-ésima subcadena distinta en orden lexicográfico? 🔴

⏱️ **30 segundos.** Recorriendo los sufijos en orden y restando a `k` las subcadenas nuevas de cada uno (`n − SA − LCP`) hasta que `k` cae dentro de uno; la respuesta es su prefijo de longitud `LCP + k`.

🗣️ **2 minutos.** En orden lexicográfico, las subcadenas distintas son, sufijo a sufijo, los prefijos de longitudes `LCP + 1` a `n − SA` de cada uno, ya ordenados. Encontrar la `k`-ésima es un recorrido con un contador. `Θ(n)` tras construir.

🔬 **El detalle.** Con repeticiones (Substring Order II) cada prefijo cuenta tantas veces como aparece, y hace falta una binaria sobre el LCP.

**06 → 13.** Justifica la fórmula de las subcadenas distintas: ¿por qué cada sufijo aporta exactamente `n − SA[k] − LCP[k]`? 🔴

⏱️ **30 segundos.** El sufijo `SA[k]` tiene `n − SA[k]` prefijos; los `LCP[k]` más cortos ya aparecieron como prefijos del sufijo anterior, y ninguno de los más largos apareció antes.

🗣️ **2 minutos.** Un prefijo más largo que `LCP[k]` no es prefijo del predecesor; tampoco de ningún sufijo anterior, porque el LCP con sufijos más lejanos es como mucho el del vecino. Así que cada subcadena distinta se cuenta exactamente una vez, en el primer sufijo del orden que la tiene como prefijo.

🔬 **El detalle.** Es la base de Substring Distribution: el sufijo `k` aporta una subcadena nueva de cada longitud entre `LCP[k] + 1` y `n − SA[k]`.

**06 → Problema: Distintas en un rango de longitudes.**

**Pista 2:** cada sufijo en orden aporta las longitudes `LCP[k] + 1 … n − SA[k]`; interseca ese intervalo con `[L, R]`.

**Pista 3:** suma `max(0, min(R, n − SA[k]) − max(L, LCP[k] + 1) + 1)` sobre todos los `k`; 64 bits.

**06 → Problema: Al menos `k` veces.**

**Pista 2:** *suffix array*, Kasai y el mínimo en ventanas de `k − 1` valores consecutivos de `LCP`.

**Pista 3:** cola monótona de mínimos sobre `LCP[1..n−1]`; la respuesta es el máximo de esos mínimos.

**06 → Problema: Suffix Array.**

**Pista 2:** la construcción por duplicación con ordenación por conteo.

**Pista 3:** con `5·10⁵` caracteres, la versión `n log² n` puede ir justa en Java y Python: la de conteo.

**06 → Problema: Number of Substrings.**

**Pista 2:** `n(n + 1)/2 − Σ LCP`.

**Pista 3:** *suffix array* + Kasai; resultado en 64 bits.

**06 → Problema: Suffix Sorting.**

**Pista 2:** construye el *suffix array* de cada cadena y responde las consultas leyendo `SA`.

**Pista 3:** las cadenas pueden contener espacios: lee la línea entera; varios casos hasta el final.

**06 → Problema: Distinct Substrings.**

**Pista 2:** `n(n + 1)/2 − Σ LCP`.

**Pista 3:** con `10⁵` caracteres, `n log² n` cabe; 64 bits.

**06 → Problema: Repeating Substring.**

**Pista 2:** el máximo LCP y la posición donde se alcanza.

**Pista 3:** imprime `s.substr(SA[k], LCP[k])` del máximo; si es 0, `-1`.

**06 → Problema: Substring Order I.**

**Pista 2:** recorre los sufijos en orden restando las subcadenas nuevas de cada uno.

**Pista 3:** el sufijo `k` aporta `n − SA[k] − LCP[k]`; cuando `k` cae dentro, la respuesta es el prefijo de longitud `LCP[k] + (lo que queda)`.

**06 → Problema: Substring Order II.**

**Pista 2:** las subcadenas con repeticiones en orden: cada prefijo de longitud `L` del sufijo `k` aparece tantas veces como sufijos consecutivos comparten `L`.

**Pista 3:** binaria sobre la respuesta, o recorrido con una pila de LCP; contar apariciones con el mínimo de LCP hacia delante.

**06 → Problema: Substring Distribution.**

**Pista 2:** el sufijo `k` aporta una subcadena distinta de cada longitud en `[LCP[k] + 1, n − SA[k]]`.

**Pista 3:** suma 1 en ese intervalo con un arreglo de diferencias; imprime las sumas de prefijo.

**06 → Problema: Longest Common Substring.**

**Pista 2:** *suffix array* de `a + '#' + b` y el mayor LCP entre vecinos de orígenes distintos.

**Pista 3:** imprime los intervalos de la subcadena en las dos cadenas; si la respuesta es 0, cualquier par de intervalos vacíos.

---

# 07 — Autómatas y expresiones regulares

**07 → 1.** ¿Qué diferencia hay entre un DFA y un NFA? 🟢

⏱️ **30 segundos.** En un DFA, cada estado y carácter llevan a **un** estado; en un NFA, a un conjunto (quizá vacío), y hay transiciones ε sin leer. El NFA acepta si algún camino acepta.

🗣️ **2 minutos.** Un DFA se ejecuta con un bucle y una tabla; un NFA hay que simularlo llevando el conjunto de estados posibles. Reconocen los mismos lenguajes, pero el NFA puede ser exponencialmente más pequeño.

🔬 **El detalle.** El DFA mínimo de un lenguaje regular es único salvo renombrar estados (Myhill-Nerode).

**07 → 2.** ¿Qué dice el teorema de Kleene? 🟢

⏱️ **30 segundos.** Que los DFA, los NFA y las expresiones regulares describen exactamente la misma clase de lenguajes: los regulares.

🗣️ **2 minutos.** Hay construcciones en los tres sentidos: expresión → NFA (Thompson), NFA → DFA (subconjuntos), DFA → expresión (eliminación de estados). Lo que no es regular (paréntesis equilibrados) no lo reconoce ninguno.

🔬 **El detalle.** Las «expresiones regulares» de los lenguajes de programación, con referencias hacia atrás, describen lenguajes que no son regulares.

**07 → 3.** ¿Cuánto cuesta reconocer una cadena con un DFA y con un NFA simulado? 🟢

⏱️ **30 segundos.** DFA: `Θ(n)` por cadena. NFA simulado: `O(n · m)`, con `m` el número de estados.

🗣️ **2 minutos.** En el DFA, una transición por carácter. En el NFA, por cada carácter se recorren los estados activos y su cierre ε, que son como mucho `m`.

🔬 **El detalle.** Con conjuntos en máscaras de bits y NFA pequeños, el paso del NFA es casi tan barato como el del DFA.

**07 → 4.** ¿Qué es el cierre ε y para qué sirve en la simulación? 🟡

⏱️ **30 segundos.** El conjunto de estados alcanzables desde uno dado sin leer caracteres, solo por transiciones ε. En la simulación, se aplica tras el inicio y tras cada carácter.

🗣️ **2 minutos.** Sin el cierre, el simulador no «vería» las alternativas y repeticiones que las ε conectan: un `*` que puede saltarse, una rama de `|`. Se calcula con un recorrido (DFS o BFS) desde los activos.

🔬 **El detalle.** En la construcción de subconjuntos, cada estado del DFA es un conjunto ya cerrado por ε.

**07 → 5.** ¿Cómo se traducen `*` y `|` en la construcción de Thompson? 🟡

⏱️ **30 segundos.** `x*`: ε del inicio de `x` al estado siguiente (saltarlo) y de vuelta del final de `x` a su inicio (repetirlo). `x|y`: ε del `(` al inicio de `y` y del final de `x` al `)`.

🗣️ **2 minutos.** En la versión de Sedgewick y Wayne, los estados son las posiciones de la expresión; una pila guarda los `(` y `|` abiertos para saber a dónde van las ε al cerrar un paréntesis. Cada operador añade un número constante de ε: `Θ(m)` en total.

🔬 **El detalle.** `+` y `?` se reescriben con `*` y `|`; las clases de caracteres son una letra que acepta un rango.

**07 → 6.** ¿Qué motores usan `std::regex`, `java.util.regex` y `re`, y qué consecuencia tiene? 🟡

⏱️ **30 segundos.** Motores con vuelta atrás: prueban alternativas y retroceden al fallar. Consecuencia: tiempo exponencial en el peor caso con ciertas expresiones.

🗣️ **2 minutos.** La vuelta atrás permite referencias hacia atrás y *lookaround*, que no son regulares; a cambio, `(a+)+$` sobre `aaaa…b` explora un número exponencial de repartos. `std::regex` es además lento en general.

🔬 **El detalle.** RE2 (C++), re2j (Java) y el paquete `regexp` de Go usan autómatas y garantizan tiempo lineal en la entrada.

**07 → 7.** ¿Qué es ReDoS y qué tipo de expresión lo provoca? 🟡

⏱️ **30 segundos.** Denegación de servicio por expresiones regulares: una entrada diseñada que hace que un motor con vuelta atrás tarde un tiempo exponencial. Lo provocan los cuantificadores anidados o las alternativas solapadas bajo un `*`.

🗣️ **2 minutos.** `(a+)+`, `(a|a)*`, `(\w+\s?)*$` sobre una cadena larga que **casi** encaja: el motor prueba todos los repartos antes de fallar. Ha tumbado servicios reales.

🔬 **El detalle.** Las defensas: reescribir la expresión, grupos atómicos o posesivos, límites de longitud y de tiempo, o un motor sin vuelta atrás.

**07 → 8.** ¿Por qué la construcción de subconjuntos puede dar `2^m` estados? Da una expresión. 🟠

⏱️ **30 segundos.** Porque cada estado del DFA es un subconjunto del NFA, y puede haber que distinguir todos. `(a|b)*a(a|b)^k` necesita `2^(k+1)` estados: hay que recordar las últimas `k + 1` letras.

🗣️ **2 minutos.** El DFA tiene que saber, tras leer cualquier prefijo, si la letra `k + 1` posiciones antes del final será una `a`; dos prefijos que difieren en alguna de las últimas `k + 1` letras tienen futuros distintos (Myhill-Nerode), así que ningún DFA tiene menos estados.

🔬 **El detalle.** El NFA de la misma expresión tiene `k + 2` estados: la diferencia es exponencial.

**07 → 9.** ¿Por qué la simulación del NFA nunca es exponencial? 🟠

⏱️ **30 segundos.** Porque lleva el **conjunto** de estados activos, que tiene como mucho `m` elementos, en lugar de recorrer caminos uno a uno.

🗣️ **2 minutos.** Dos caminos que llegan al mismo estado tras el mismo prefijo tienen el mismo futuro: basta recordar el estado una vez. La vuelta atrás los recorre por separado, y su número puede ser exponencial.

🔬 **El detalle.** Es la misma idea que la programación dinámica frente a la recursión: fusionar los estados repetidos.

**07 → 10.** ¿Cómo cuentas las cadenas de longitud `n` que acepta un DFA? 🟠

⏱️ **30 segundos.** DP sobre `(longitud, estado)`: `dp[i + 1][δ(q, c)] += dp[i][q]`; la respuesta es la suma sobre los estados finales en la longitud `n`.

🗣️ **2 minutos.** `Θ(n · estados · σ)`. Con `n` enorme, la DP es una potencia de la matriz de transiciones (`13/06`). Es el esquema de la *digit DP* y de las DP con patrones prohibidos ([`16/02`](02-kmp.md), [`16/05`](05-aho-corasick.md)).

🔬 **El detalle.** Con un NFA hay que determinizar antes, o se cuentan caminos (que pueden contar dos veces una misma cadena).

**07 → 11.** ¿Por qué las referencias hacia atrás obligan a la vuelta atrás? 🟠

⏱️ **30 segundos.** Porque una referencia hacia atrás (`\1`) exige recordar el texto exacto que capturó un grupo, que puede ser arbitrariamente largo: ningún autómata finito puede.

🗣️ **2 minutos.** `(a+)b\1` reconoce `aⁿbaⁿ`, que no es regular (bombeo, [`22/01`](../22-teoria-de-la-computacion/01-lenguajes-y-gramaticas.md)). El motor tiene que probar las longitudes posibles del grupo y retroceder si el resto no encaja.

🔬 **El detalle.** El problema de coincidencia con referencias hacia atrás es NP-completo en general.

**07 → 12.** ¿Qué relación hay entre el autómata de KMP y el DFA de `.*p`? 🔴

⏱️ **30 segundos.** Son el mismo autómata: el DFA mínimo de `.*p` tiene `|p| + 1` estados («cuánto de `p` llevo leído») y sus transiciones son las de KMP.

🗣️ **2 minutos.** La construcción de subconjuntos sobre el NFA de `.*p` da conjuntos que se corresponden con los bordes; la tabla `δ` de KMP (`16/02`) es ese DFA calculado directamente con la función de prefijo, sin pasar por subconjuntos.

🔬 **El detalle.** Con varios patrones, `.*(p₁|p₂|…)` da el autómata de Aho-Corasick (`16/05`).

**07 → 13.** ¿Cómo protegerías un servicio que evalúa expresiones regulares sobre entradas de usuarios? 🔴

⏱️ **30 segundos.** Acotar la longitud de la entrada antes de evaluar, usar un motor sin vuelta atrás (RE2 o equivalente) y revisar las expresiones en busca de cuantificadores anidados.

🗣️ **2 minutos.** Si hace falta la vuelta atrás, límites de tiempo o de pasos por evaluación (Java y .NET los permiten), grupos atómicos o cuantificadores posesivos, y pruebas con entradas adversarias en la integración continua.

🔬 **El detalle.** Las expresiones las escriben a veces los propios usuarios (filtros, búsquedas): ahí, motor sin vuelta atrás obligatorio.

**07 → Problema: Múltiplos de `k`.**

**Pista 2:** DP sobre el DFA de restos: `dp[i][r]` = cadenas de longitud `i` con resto `r`.

**Pista 3:** `dp[i + 1][(2r + b) % k] += dp[i][r]` para `b ∈ {0, 1}`; la respuesta es `dp[n][0]`, módulo `10⁹ + 7`. `Θ(n · k)`.

**07 → Problema: `grep` mínimo.**

**Pista 2:** NFA de Thompson y simulación con el conjunto de estados activos.

**Pista 3:** `O(|cadena| · |expresión|)` por consulta: `10⁷` en el peor caso, con `boolean[]` o `bitset` para los activos.

**07 → Problema: Matching Specific String.**

**Pista 2:** una búsqueda sin anclar de la palabra literal con la biblioteca de expresiones regulares.

**Pista 3:** cuenta las coincidencias con `findall` (Python) o un bucle `find()` (Java).

**07 → Problema: Number of Valid Words in a Sentence.**

**Pista 2:** valida cada palabra con un pequeño autómata: letras, como mucho un guion entre letras y como mucho un signo al final.

**Pista 3:** sin dígitos; el guion necesita letra a los dos lados; el signo (`!`, `.`, `,`) solo en la última posición.

**07 → Problema: String to Integer (atoi).**

**Pista 2:** máquina de estados: espacios, signo, dígitos, fin.

**Pista 3:** acumula en 64 bits (o comprueba el desbordamiento antes de multiplicar) y satura a los límites de 32 bits.

**07 → Problema: Validate IP Address.**

**Pista 2:** separa por `.` o `:` y valida cada tramo con sus reglas.

**Pista 3:** IPv4: 4 tramos decimales de 0 a 255 sin ceros a la izquierda; IPv6: 8 tramos de 1 a 4 hexadecimales. Cuidado con los separadores al principio o al final.

**07 → Problema: Detect HTML links.**

**Pista 2:** una expresión con grupos para el `href` y el texto del enlace.

**Pista 3:** cuantificadores perezosos (`.*?`) para no comerse varios enlaces a la vez; recorta los espacios del texto.

**07 → Problema: Valid Number.**

**Pista 2:** un DFA con estados para signo, dígitos, punto, decimales, exponente y su signo.

**Pista 3:** unos 9 estados; finales: tras dígitos enteros, tras decimales (con algún dígito antes o después del punto) y tras dígitos del exponente.

**07 → Problema: Detect the Email Addresses.**

**Pista 2:** una expresión para usuario y dominio, sin cuantificadores anidados.

**Pista 3:** extrae todas las coincidencias, elimina repetidas y ordénalas.

**07 → Problema: Find a Word.**

**Pista 2:** límites de palabra (`\b`) alrededor de la palabra buscada.

**Pista 3:** cuenta las coincidencias en todas las frases para cada palabra consultada.

**07 → Problema: Tag Validator.**

**Pista 2:** recorre con una pila de etiquetas abiertas; el `CDATA` se salta entero.

**Pista 3:** el nombre de etiqueta es de 1 a 9 mayúsculas; el código entero tiene que estar dentro de una etiqueta cerrada al final.

---

# 08 — Árbol de palíndromos y árbol de sufijos

**08 → 1.** ¿Qué guarda cada nodo de un *eertree*? 🟢

⏱️ **30 segundos.** Un palíndromo distinto de la cadena: su longitud, sus aristas (`c` a los dos lados) y su enlace de sufijo (el sufijo palindrómico propio más largo).

🗣️ **2 minutos.** Hay además dos raíces ficticias, de longitud `−1` y `0`, de las que cuelgan los palíndromos impares y pares. Con un contador por nodo se lleva cuántas veces termina ahí el palíndromo más largo.

🔬 **El detalle.** El nombre viene de leer *tree* al revés y al derecho: es un palíndromo.

**08 → 2.** ¿Cuántos palíndromos distintos puede tener, como mucho, una cadena de longitud `n`? 🟢

⏱️ **30 segundos.** `n` (sin contar el vacío): cada carácter añadido crea como mucho uno nuevo.

🗣️ **2 minutos.** En `abracadabra`, 7 de 11 posibles: las cinco letras distintas, `aca` y `ada`. Con todas las letras iguales, `n` exactamente: `a`, `aa`, `aaa`, …

🔬 **El detalle.** Es una de las cotas que hacen lineal al *eertree*: no puede haber más nodos.

**08 → 3.** ¿Qué es un árbol de sufijos y cuántos nodos tiene? 🟢

⏱️ **30 segundos.** El trie comprimido de todos los sufijos de `s$`: `n` hojas y como mucho `n − 1` nodos internos, con las aristas etiquetadas por tramos de `s`.

🗣️ **2 minutos.** Cada camino de la raíz a un punto del árbol es una subcadena; cada hoja, un sufijo. Comprimir las cadenas de nodos con un solo hijo deja `Θ(n)` nodos.

🔬 **El detalle.** El `$` final garantiza que ningún sufijo es prefijo de otro, y así cada sufijo acaba en una hoja.

**08 → 4.** ¿Por qué cada carácter añadido crea como mucho un palíndromo nuevo? 🟡

⏱️ **30 segundos.** Porque todo sufijo palindrómico más corto que el más largo es, por simetría, también un prefijo de este, y ya apareció antes en la cadena.

🗣️ **2 minutos.** Si `P` es el sufijo palindrómico más largo y `Q` uno más corto, `Q` es sufijo de `P`; como `P` es palíndromo, el reflejo de `Q` es prefijo de `P`, y el reflejo de un palíndromo es él mismo. Así que `Q` aparece terminando antes de la posición actual.

🔬 **El detalle.** Por eso el único candidato a nuevo es el más largo: el algoritmo solo tiene que encontrarlo.

**08 → 5.** ¿Por qué las aristas del árbol de sufijos se etiquetan con tramos y no con cadenas? 🟡

⏱️ **30 segundos.** Porque guardar las cadenas haría la memoria cuadrática (la suma de longitudes de los sufijos es `n²/2`); un tramo `[i, j)` ocupa dos enteros.

🗣️ **2 minutos.** Las etiquetas de las aristas son subcadenas de `s`, así que basta guardar dónde están. Con `Θ(n)` aristas y dos enteros por arista, la memoria es lineal.

🔬 **El detalle.** En Ukkonen, las hojas guardan un final «abierto» que se actualiza a la vez para todas al avanzar el texto.

**08 → 6.** ¿Qué relación hay entre el árbol de sufijos y el *suffix array* con LCP? 🟡

⏱️ **30 segundos.** El recorrido en profundidad con los hijos en orden visita las hojas en el orden del *suffix array*, y la profundidad del LCA de dos hojas es su LCP.

🗣️ **2 minutos.** Por eso casi todo lo que se hace con el árbol se hace con el *suffix array* + LCP: los nodos internos corresponden a intervalos del *suffix array* con LCP mínimo dado.

🔬 **El detalle.** Se puede construir el árbol desde el *suffix array* + LCP en lineal con una pila.

**08 → 7.** ¿Para qué sirven los enlaces de sufijo del *eertree*? 🟠

⏱️ **30 segundos.** Para encontrar, al añadir un carácter, el palíndromo que se puede extender: se baja por los enlaces de sufijo desde el más largo actual hasta uno con el mismo carácter antes. También para contar apariciones (propagando por ellos).

🗣️ **2 minutos.** Es la misma mecánica que los enlaces de fallo de Aho-Corasick: la cadena de enlaces enumera los sufijos palindrómicos de mayor a menor. Y el número de apariciones de cada palíndromo se obtiene sumando, al final, los contadores por el árbol de enlaces.

🔬 **El detalle.** Las «series» (cadenas de enlaces con diferencias de longitud iguales) son `O(log n)` por posición: base de la DP de particiones en palíndromos.

**08 → 8.** ¿Qué alternativa escribirías para contar palíndromos distintos sin *eertree*? 🟠

⏱️ **30 segundos.** Manacher para los palíndromos maximales de cada centro y *hashing*: el palíndromo nuevo de cada posición se identifica por su *hash*, en un conjunto.

🗣️ **2 minutos.** Con `n ≤ 3 000`, basta meter en un conjunto los *hashes* de todas las subcadenas palindrómicas (por centros, expandiendo). Con `n` grande, recortar por centro solo los candidatos nuevos y usar un conjunto: `O(n log n)`.

🔬 **El detalle.** El riesgo es la colisión de *hashes*, con el control de `16/04`.

**08 → 9.** ¿Qué tres ideas hacen lineal a Ukkonen? 🟠

⏱️ **30 segundos.** Hojas «abiertas» que crecen solas (una vez hoja, siempre hoja), enlaces de sufijo entre nodos internos para saltar de un sufijo al siguiente, y el punto activo con el truco del salto por longitudes (*skip/count*).

🗣️ **2 minutos.** Con las hojas abiertas, extender todos los sufijos que ya son hojas cuesta `O(1)` por fase; el punto activo recuerda dónde quedó la última extensión explícita; los enlaces de sufijo evitan bajar desde la raíz. El análisis amortizado da `Θ(n)` en total.

🔬 **El detalle.** La regla «si el carácter ya está, se para la fase» (*showstopper*) es la que acota el trabajo de cada fase.

**08 → 10.** ¿Cómo buscas un patrón en `O(|p|)` con un árbol de sufijos? 🔴

⏱️ **30 segundos.** Bajando desde la raíz por las aristas que coinciden con el patrón, carácter a carácter: si se consume entero, es subcadena. `O(|p|)`.

🗣️ **2 minutos.** Cada arista está etiquetada con un tramo de `s`; se compara el patrón con ese tramo. El número de apariciones es el número de hojas bajo el punto donde termina.

🔬 **El detalle.** Con un *suffix array*, la misma consulta es una binaria: `O(|p| log n)`.

**08 → 11.** ¿Cómo encuentras la subcadena común más larga de tres cadenas con un árbol de sufijos generalizado? 🔴

⏱️ **30 segundos.** Con el árbol de sufijos generalizado de las tres (con separadores distintos): el nodo interno más profundo que tiene en su subárbol hojas de las tres cadenas.

🗣️ **2 minutos.** Un recorrido marca, por nodo, qué cadenas tienen hojas debajo (un conjunto de bits); la respuesta es la mayor profundidad de cadena entre los nodos con las tres marcas.

🔬 **El detalle.** Con *suffix array*: ventana deslizante sobre el orden que contenga sufijos de las tres, y el mínimo del LCP dentro.

**08 → Problema: Palíndromos distintos.**

**Pista 2:** expande desde cada centro y mete en un conjunto los palíndromos (o sus *hashes*).

**Pista 3:** con `n = 3 000`, hay como mucho `n²/2` subcadenas palindrómicas por posición; con *hashes* de 64 bits, el conjunto cabe. Alternativa: *eertree*.

**08 → Problema: ¿Está dentro?.**

**Pista 2:** *suffix array* de `s` y búsqueda binaria del patrón sobre los sufijos ordenados.

**Pista 3:** compara el patrón con el sufijo del medio carácter a carácter: `O(|p| log n)` por patrón; la suma de longitudes acota el total.

**08 → Problema: Eertree.**

**Pista 2:** el *eertree* con las dos raíces y los enlaces de sufijo.

**Pista 3:** imprime, por nodo creado, su padre y su enlace de sufijo en el formato pedido, y el nodo del palíndromo sufijo más largo tras cada carácter.

**08 → Problema: Enumerate Palindromes.**

**Pista 2:** Manacher con la cadena intercalada.

**Pista 3:** imprime la longitud del palíndromo más largo de cada uno de los `2n − 1` centros.

**08 → Problema: Palindrome Partition.**

**Pista 2:** la condición sobre la partición equivale a partir `t = s₁ sₙ s₂ sₙ₋₁ …` en palíndromos de longitud par.

**Pista 3:** DP de particiones en palíndromos con el *eertree* y las series de enlaces de sufijo (`O(n log n)`), quedándote con los pares.

**08 → Problema: String.**

**Pista 2:** con `k ≤ 10⁵`, una cola de prioridad de subcadenas, empezando por cada carácter y extendiendo la extraída.

**Pista 3:** cada extracción mete la extensión en un carácter de la subcadena extraída (si existe); la `k`-ésima extraída es la respuesta. Alternativa: *suffix array* + LCP.

---

# 09 — Simulación

**09 → S1.** ¿Por qué `s += c` en un bucle es cuadrático en Java y Python? 🟢

⏱️ **30 segundos.** Porque sus cadenas son inmutables: cada `+=` crea una cadena nueva y copia la anterior. `n` añadidos copian `n²/2` caracteres.

🗣️ **2 minutos.** La solución es un búfer: `StringBuilder` en Java, una lista y `''.join` en Python. En C++, `std::string` es mutable y `+=` es amortizado `O(1)`.

🔬 **El detalle.** CPython a veces optimiza `+=` en el sitio, sin garantía; PyPy no.

**09 → S2.** ¿Qué guarda la función de prefijo y cuánto cuesta calcularla? 🟢

⏱️ **30 segundos.** Para cada posición `i`, la longitud del borde más largo de `s[0..i]` (prefijo propio que también es sufijo). `Θ(n)`.

🗣️ **2 minutos.** Lineal por el potencial del índice `k`: sube como mucho uno por posición y cada retroceso lo baja; las bajadas no superan a las subidas.

🔬 **El detalle.** El retroceso es `k = π[k − 1]`, no `π[k]`.

**09 → S3.** ¿Cómo obtienes el periodo más corto de una cadena? 🟢

⏱️ **30 segundos.** `n − π[n − 1]`.

🗣️ **2 minutos.** Tener periodo `p` equivale a tener un borde de longitud `n − p`, así que el periodo más corto corresponde al borde más largo.

🔬 **El detalle.** La cadena es repetición exacta de su periodo solo si este divide a `n`.

**09 → S4.** ¿Qué diferencia hay entre la función Z y la de prefijo? 🟡

⏱️ **30 segundos.** `π[i]` mira hacia atrás (el borde que **termina** en `i`); `Z[i]`, hacia delante (cuánto coincide con el prefijo lo que **empieza** en `i`).

🗣️ **2 minutos.** Llevan la misma información y se convierten una en otra en lineal. Z es más natural para «cuánto coincide desde aquí»; `π`, para autómatas y DP.

🔬 **El detalle.** Las dos sirven para buscar con el truco del separador.

**09 → S5.** ¿Por qué Manacher intercala un separador entre las letras? 🟡

⏱️ **30 segundos.** Para tratar los palíndromos pares e impares con un solo bucle: en la cadena intercalada todos tienen un carácter en el centro.

🗣️ **2 minutos.** Sin el separador hacen falta dos pasadas (`d1` y `d2`). La longitud en la cadena original es el radio en la intercalada menos uno.

🔬 **El detalle.** El separador tiene que ser un carácter que no esté en la cadena.

**09 → S6.** ¿Qué es un enlace de fallo en Aho-Corasick? 🟢

⏱️ **30 segundos.** El nodo del sufijo propio más largo de la cadena del nodo que también está en el trie de los patrones.

🗣️ **2 minutos.** Es la función de prefijo de KMP generalizada a un trie: si el siguiente carácter no continúa, se salta al fallo sin retroceder en el texto. Se calcula por BFS.

🔬 **El detalle.** Con un solo patrón, los enlaces de fallo son la función de prefijo.

**09 → S7.** ¿Cuántas subcadenas distintas tiene una cadena, en términos del *suffix array*? 🟡

⏱️ **30 segundos.** `n(n + 1)/2 − Σ LCP[k]`.

🗣️ **2 minutos.** Cada subcadena es prefijo de un sufijo; en orden, el sufijo `k` aporta sus prefijos menos los `LCP[k]` que comparte con el anterior.

🔬 **El detalle.** En 64 bits.

**09 → S8.** ¿Qué controla la probabilidad de colisión del *hashing* de cadenas? 🟡

⏱️ **30 segundos.** El tamaño del módulo frente al número de comparaciones (o de *hashes* guardados), y que la base sea aleatoria.

🗣️ **2 minutos.** Una comparación falla con probabilidad `≤ L/M`; un conjunto de `n` *hashes* tiene `n²/2` pares: hace falta `M ≫ n²`. Con `2⁶¹ − 1` y base aleatoria, despreciable.

🔬 **El detalle.** Con módulo `2⁶⁴` y base fija, las cadenas de Thue-Morse colisionan siempre.

**09 → S9.** ¿Por qué simular un NFA nunca es exponencial? 🟡

⏱️ **30 segundos.** Porque lleva el conjunto de estados activos, como mucho `m`, en lugar de recorrer caminos uno a uno: `O(n · m)`.

🗣️ **2 minutos.** Dos caminos que llegan al mismo estado tras el mismo prefijo tienen el mismo futuro; el conjunto los fusiona. La vuelta atrás no, y por eso puede ser exponencial.

🔬 **El detalle.** Es la misma idea que la DP frente a la recursión sin memoria.

**09 → S10.** ¿Cuántos palíndromos distintos puede tener una cadena de longitud `n`? 🟢

⏱️ **30 segundos.** `n`: cada carácter añadido crea como mucho un palíndromo nuevo.

🗣️ **2 minutos.** Solo el sufijo palindrómico más largo puede ser nuevo; los más cortos son, por simetría, prefijos suyos y ya habían aparecido.

🔬 **El detalle.** Es la cota que hace lineal al *eertree*.

**09 → S11.** «`indexOf` es `O(n)`.» ¿Qué respondes, y cuándo da igual? 🟠

⏱️ **30 segundos.** Que es `O(n · m)` en el peor caso. Da igual cuando las cadenas son cortas o el número de búsquedas es pequeño: `100 · 50 · 50` no es nada.

🗣️ **2 minutos.** El peor caso aparece con repeticiones (`aaaa…ab`); con textos normales, la búsqueda falla pronto. La decisión depende de las cotas del enunciado: con `10⁶` y casos adversarios, KMP; con 50 caracteres, la biblioteca.

🔬 **El detalle.** Es la «Fuerza» de Dentro de otra.

**09 → S12.** Tu KMP pierde apariciones solapadas. ¿Qué línea miras? 🟠

⏱️ **30 segundos.** La línea tras encontrar una aparición: tiene que ser `k = π[m − 1]`, no `k = 0`.

🗣️ **2 minutos.** Con `k = 0` se buscan apariciones no solapadas; con el borde del patrón, la siguiente puede empezar dentro de la anterior (`aa` en `aaaa`: 3 solapadas, 2 sin solapar).

🔬 **El detalle.** Con el truco del separador no hace falta: `π` sobre `p + '#' + t` cuenta todas.

**09 → S13.** Te dan `10⁴` patrones y un texto de `10⁶`, y alguien propone `10⁴` KMP. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que son `10¹⁰` pasos; Aho-Corasick recorre el texto una vez para todos los patrones: `Θ(n + L)` más las apariciones.

🗣️ **2 minutos.** El trie de los patrones con enlaces de fallo hace en una pasada lo que `10⁴` KMP. Para contar, se acumulan las visitas por nodo y se propagan por el árbol de fallos.

🔬 **El detalle.** Alternativa con *hashing*: agrupar por longitudes, `O(n √L)`.

**09 → S14.** «Con *hash* no hace falta KMP.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que el *hash* es probabilístico y KMP exacto y lineal: si KMP basta, se usa KMP.

🗣️ **2 minutos.** El *hash* es la herramienta para comparar subcadenas arbitrarias o para la binaria sobre la longitud, donde no hay un algoritmo exacto igual de corto. Para buscar un patrón fijo, KMP o Z.

🔬 **El detalle.** En una entrevista, el *hash* es una primera idea aceptable si se dice cómo se controlan las colisiones.

**09 → S15.** Una expresión regular cuelga un servidor con una entrada de 40 caracteres. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** ReDoS: la expresión tiene cuantificadores anidados o alternativas solapadas, y el motor con vuelta atrás prueba un número exponencial de repartos antes de fallar.

🗣️ **2 minutos.** `(a+)+$` sobre `aaaa…b` es el ejemplo clásico. Se arregla reescribiendo la expresión, con grupos atómicos o posesivos, acotando la entrada o usando un motor de autómatas (RE2).

🔬 **El detalle.** Las referencias hacia atrás obligan a la vuelta atrás; el resto no.

**09 → S16.** Tu *hashing* da WA solo en un caso y AC al cambiar la base. ¿Qué era? 🟠

⏱️ **30 segundos.** Una colisión: la base o el módulo no daban margen (base fija, módulo pequeño, o muchos *hashes* en un conjunto).

🗣️ **2 minutos.** Si cambiar la base cambia el veredicto, no es un error de lógica. Se arregla con módulo `2⁶¹ − 1` (o dos módulos) y base aleatoria por ejecución.

🔬 **El detalle.** Algunos jueces tienen pruebas anti-*hash* para las bases y módulos más comunes.

**09 → S17.** Ordenas los sufijos con `sort` y da TLE con `aaaa…`. ¿Por qué? 🟠

⏱️ **30 segundos.** Porque cada comparación de dos sufijos de `aaaa…` recorre casi toda la cadena: `Θ(n)` por comparación y `Θ(n² log n)` en total.

🗣️ **2 minutos.** La duplicación compara pares de rangos en `O(1)`: `Θ(n log n)` (o `n log² n` con un `sort` de pares). Con *hashing* y LCP por binaria, cada comparación es `O(log n)`.

🔬 **El detalle.** Con textos aleatorios el `sort` directo parece funcionar: el peor caso solo sale con repeticiones.

**09 → S18.** «El palíndromo más largo es cuadrático.» ¿Cuándo es verdad en la práctica y cuándo no? 🟠

⏱️ **30 segundos.** Es verdad para la expansión desde los centros en el peor caso (una sola letra repetida); no lo es con Manacher, que es lineal.

🗣️ **2 minutos.** En la práctica, la expansión desde los centros es rápida con textos sin muchas repeticiones y suficiente con `n ≤ 5 000`; con `10⁶` o casos adversarios, Manacher.

🔬 **El detalle.** Es la «Fuerza» de El espejo más largo.

**09 → S19.** Demuestra que la función de prefijo se calcula en tiempo lineal. 🔴

⏱️ **30 segundos.** El índice `k` sube como mucho 1 por posición y cada vuelta del `while` lo baja al menos 1, sin bajar de 0: las bajadas totales no superan `n`.

🗣️ **2 minutos.** Con potencial `Φ = k`, el coste amortizado de cada posición es constante: `1 +` bajadas `−` (caída de `Φ`). Sumando, el total es `≤ 2n`.

🔬 **El detalle.** El mismo argumento vale para KMP sobre el texto y para Aho-Corasick con transiciones al vuelo.

**09 → S20.** Diseña cómo contar cadenas de longitud `n` sobre `{a, b}` que no contengan ninguna de `k` palabras prohibidas, y di el coste. 🔴

⏱️ **30 segundos.** DP sobre `(longitud, nodo)` del autómata de Aho-Corasick de las palabras, prohibiendo los nodos con un terminal en su cadena de fallos. `Θ(n · L · 2)`.

🗣️ **2 minutos.** Un nodo es malo si es terminal o su fallo es malo (se marca en el BFS). `dp[i + 1][go(v, c)] += dp[i][v]` para nodos buenos; la respuesta es la suma en la longitud `n`.

🔬 **El detalle.** Con `n` enorme, potencia de la matriz de transiciones entre nodos buenos.

**09 → Problema: El trozo que se repite.**

**Pista 2:** el periodo más corto: `n − π[n − 1]`.

**Pista 3:** función de prefijo lineal; no hace falta que el periodo divida a `n`.

**09 → Problema: El espejo más largo.**

**Pista 2:** Manacher con la cadena intercalada.

**Pista 3:** recorre los centros guardando el primero con longitud máxima; el inicio en `s` es `(i − len) / 2`.

**09 → Problema: Cuáles aparecen.**

**Pista 2:** Aho-Corasick; marca los nodos visitados al recorrer el texto y propaga la marca por el árbol de fallos.

**Pista 3:** un patrón aparece si su nodo terminal queda marcado; palabras repetidas comparten nodo: cuéntalas todas.

**09 → Problema: Dentro de otra.**

**Pista 2:** para cada par, la búsqueda de la biblioteca (`find`, `indexOf`, `in`).

**Pista 3:** `100 · 99` pares por `50 · 50` comparaciones en el peor caso: `2,5·10⁷`, de sobra.

**09 → Problema: Remove All Occurrences of a Substring.**

**Pista 2:** una pila de caracteres con el estado de KMP de cada uno: al completar `part`, se desapilan sus caracteres y se recupera el estado anterior.

**Pista 3:** guarda en la pila el estado `k` tras cada carácter; con `|s| ≤ 1 000` también vale repetir `find` y borrar.

**09 → Problema: String Functions.**

**Pista 2:** la función Z y la función de prefijo.

**Pista 3:** imprime las dos; `Z[0]` como pida el enunciado.

**09 → Problema: Find Substring With Given Hash Value.**

**Pista 2:** recorre de derecha a izquierda: con la potencia mayor a la derecha, quitar un carácter por la derecha y añadir uno por la izquierda es una actualización simple.

**Pista 3:** `h = h · p + val(s[i]) − val(s[i + k]) · p^k` módulo `m`; guarda el índice más a la izquierda con `h = hashValue`.

**09 → Problema: Maximum Deletions on a String.**

**Pista 2:** DP desde el final: `dp[i]` = máximo de operaciones sobre `s[i..]`; con una tabla de LCP entre todas las posiciones sabes si `s[i..i+L) = s[i+L..i+2L)`.

**Pista 3:** `lcp[i][j]` en `O(n²)` (de abajo arriba: `lcp[i][j] = lcp[i + 1][j + 1] + 1` si `s[i] = s[j]`); `dp[i] = 1 + max dp[i + L]` sobre las `L` con `lcp[i][i + L] ≥ L`.

**09 → Problema: Prefix Function Queries.**

**Pista 2:** la función de prefijo de `s` es fija; para los caracteres de `t`, la transición desde un estado dentro de `s` se puede precalcular con el autómata de KMP de `s`.

**Pista 3:** autómata `δ[q][c]` para `q ≤ |s|`; para estados dentro de `t` (pocos, `|t| ≤ 10`), calcula al vuelo. Así cada consulta es `O(|t| · 26)`.
