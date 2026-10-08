# Respuestas — bloque 17: Matemática

> Solucionario del bloque `17`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--bits) · [02](#02--divisibilidad) · [03](#03--aritmética-modular) · [04](#04--primos) · [05](#05--combinatoria) · [06](#06--probabilidad-y-esperanza) · [07](#07--matrices-y-eliminación-de-gauss) · [08](#08--teoría-de-juegos) · [09](#09--fft-y-ntt) · [10](#10--teoría-de-números-avanzada) · [11](#11--funciones-generadoras-y-berlekamp-massey) · [12](#12--simulación)

---

# 01 — Bits

**01 → 1.** ¿Qué hacen `x & -x` y `x & (x − 1)`? 🟢

⏱️ **30 segundos.** `x & -x` aísla el bit encendido más bajo; `x & (x − 1)` lo apaga.

🗣️ **2 minutos.** En complemento a dos, `−x = ~x + 1`: invertir y sumar 1 deja igual el bit más bajo encendido y lo de debajo, e invierte lo de arriba; el `&` se queda solo con ese bit. Restar 1 apaga el bit más bajo y enciende los ceros de debajo; el `&` con `x` borra los dos efectos salvo el apagado.

🔬 **El detalle.** `x & -x` es el paso de Fenwick ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)); `x & (x − 1)` en bucle recorre los unos.

**01 → 2.** ¿Cómo compruebas si un número es potencia de 2? 🟢

⏱️ **30 segundos.** `x > 0 && (x & (x − 1)) == 0`.

🗣️ **2 minutos.** Una potencia de 2 tiene exactamente un bit encendido; apagarlo deja 0. El `x > 0` excluye el 0 y, en tipos con signo, el valor más negativo.

🔬 **El detalle.** Alternativas: `popcount(x) == 1`, o `Integer.highestOneBit(x) == x` en Java.

**01 → 3.** ¿Cómo cuentas los bits encendidos en C++, Java y Python? 🟢

⏱️ **30 segundos.** C++: `__builtin_popcountll` (o `std::popcount` en C++20). Java: `Long.bitCount` / `Integer.bitCount`. Python: `x.bit_count()` (3.10+) o `bin(x).count('1')`.

🗣️ **2 minutos.** Las tres usan la instrucción de la CPU cuando existe. A mano, `x &= x − 1` en bucle cuenta en `O(popcount)`.

🔬 **El detalle.** En C++, `__builtin_popcount` (sin `ll`) trunca a 32 bits: un error silencioso con `long long`.

**01 → 4.** ¿Por qué `1 << 40` puede dar un resultado incorrecto, y cómo se escribe bien en cada lenguaje? 🟡

⏱️ **30 segundos.** Porque el literal `1` es `int` (32 bits) y desplazarlo 40 posiciones desborda. C++: `1ULL << 40`; Java: `1L << 40`; Python: no hay problema.

🗣️ **2 minutos.** En C++ es comportamiento indefinido; en Java el desplazamiento se reduce módulo 32 y `1 << 40` vale `1 << 8 = 256`. El tipo del resultado es el del operando izquierdo, no el de la variable donde se guarda.

🔬 **El detalle.** El mismo error aparece con `x * y` de dos `int` guardado en un `long` ([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)).

**01 → 5.** ¿Qué diferencia hay entre `>>` y `>>>` en Java, y qué pasa en C++ y Python? 🟡

⏱️ **30 segundos.** `>>` replica el bit de signo (aritmético); `>>>` mete ceros (lógico). C++ no tiene `>>>`: se usa un tipo sin signo. Python solo tiene `>>` aritmético, sobre enteros ilimitados.

🗣️ **2 minutos.** Para tratar un `long` negativo como 64 bits sin signo en Java (invertir bits, hashes), `>>>`. En C++, `>>` sobre negativos es aritmético desde C++20 (antes, definido por la implementación).

🔬 **El detalle.** En JavaScript, `>>>` además convierte a 32 bits sin signo.

**01 → 6.** ¿Cuánto vale el XOR de `1..n` sin recorrer, y por qué? 🟡

⏱️ **30 segundos.** `n` si `n mod 4 = 0`, `1` si es 1, `n + 1` si es 2, `0` si es 3.

🗣️ **2 minutos.** El XOR de cuatro consecutivos `4k, 4k + 1, 4k + 2, 4k + 3` es 0 (los dos bits bajos recorren todas las combinaciones y los altos se cancelan por pares). Queda el XOR de los que sobran del último bloque.

🔬 **El detalle.** Con la fórmula, el XOR de `[l, r]` es `f(r) ^ f(l − 1)`.

**01 → 7.** ¿Cómo recorres todas las submáscaras de una máscara? 🟡

⏱️ **30 segundos.** `for (sub = mask; ; sub = (sub − 1) & mask) { …; if (sub == 0) break; }`.

🗣️ **2 minutos.** Restar 1 apaga el bit más bajo de `sub` y enciende los de debajo; el `&` con `mask` deja solo los que pertenecen a la máscara. Recorre los `2^popcount(mask)` subconjuntos en orden decreciente.

🔬 **El detalle.** Sobre todas las máscaras de `n` bits, el total es `3ⁿ` ([`13/01`](../13-dp-avanzada/01-mascaras-de-bits.md)).

**01 → 8.** ¿Por qué `−7 >> 1` y `−7 / 2` dan resultados distintos? 🟡

⏱️ **30 segundos.** Porque `>>` redondea hacia `−∞` y la división entera de C++ y Java hacia 0: `−7 >> 1 = −4` y `−7 / 2 = −3`.

🗣️ **2 minutos.** Con positivos coinciden. En Python, `//` también redondea hacia `−∞`: `−7 // 2 = −4`, igual que `>>`. Sustituir una división por un desplazamiento solo es seguro con no negativos.

🔬 **El detalle.** Es un error típico en búsquedas binarias con índices negativos y en el «punto medio» de rangos negativos.

**01 → 9.** ¿Cómo encuentras, en `Θ(n)` y memoria constante, el repetido y el que falta del 1 al `n`? 🟠

⏱️ **30 segundos.** El XOR de valores e índices da `dup ^ missing`; un bit encendido suyo separa los dos; el XOR de cada mitad da uno de ellos, y una pasada decide cuál es el repetido.

🗣️ **2 minutos.** Todo lo demás aparece una vez como valor y una como índice y se cancela. El repetido aparece dos veces como valor (se cancela consigo) y una como índice: queda. El que falta solo aparece como índice: queda. `Θ(n)` y `Θ(1)` de memoria.

🔬 **El detalle.** Con sumas también sale (suma y suma de cuadrados), pero hay que cuidar el desbordamiento.

**01 → 10.** ¿Cómo usas un `bitset` para la mochila de factibilidad, y cuánto ganas? 🟠

⏱️ **30 segundos.** `reach |= reach << a` por cada objeto, con `reach` un `bitset` de sumas alcanzables. Se gana un factor 64: `Θ(n · S / 64)`.

🗣️ **2 minutos.** El bit `s` de `reach` dice si la suma `s` se alcanza. Añadir el objeto `a` desplaza todo `a` posiciones y lo une. Con `n = 1 000` y `S = 10⁵`, `1,5·10⁶` operaciones de palabra en lugar de `10⁸`.

🔬 **El detalle.** Solo vale para la factibilidad (sí o no); si la DP lleva un valor (máximo, conteo), no.

**01 → 11.** ¿Qué es la base XOR y por qué hay `2^rango` XOR distintos? 🟠

⏱️ **30 segundos.** Una base del subespacio de los XOR de subconjuntos sobre `GF(2)`, con un vector por bit pivote. Cada XOR alcanzable es la combinación de un subconjunto único de la base: `2^rango`.

🗣️ **2 minutos.** Los vectores de la base son linealmente independientes y generan todo; cada combinación (subconjunto de la base) da un XOR distinto y no hay otros. Por eso, con `[5, 2, 9, 1, 5, 6]` y rango 4, hay 16 XOR distintos.

🔬 **El detalle.** Cada XOR alcanzable se obtiene de `2^(n − rango)` subconjuntos distintos del arreglo.

**01 → 12.** ¿Por qué el voraz desde el pivote más alto da el mayor XOR? 🔴

⏱️ **30 segundos.** Porque con pivotes distintos, decidir el bit más alto primero nunca se deshace: un vector con pivote más bajo no toca los bits más altos.

🗣️ **2 minutos.** Desde el pivote más alto, si `r ^ basis[b]` es mayor que `r`, es porque enciende el bit `b`; los vectores de pivote menor no pueden cambiar el bit `b`, así que cualquier resultado con el bit `b` apagado es menor. Por inducción, el voraz es óptimo.

🔬 **El detalle.** Con la base en forma escalonada reducida, el máximo es simplemente el XOR de toda la base.

**01 → 13.** ¿Qué diferencia hay entre «XOR máximo de dos elementos» y «XOR máximo de un subconjunto», y qué estructura resuelve cada uno? 🔴

⏱️ **30 segundos.** De dos elementos: trie binario ([`07/04`](../07-arboles/04-tries.md)) o voraz por bits con conjuntos de prefijos, `Θ(n · B)`. De un subconjunto: base XOR, `Θ(n · B)`.

🗣️ **2 minutos.** Con dos elementos solo se combinan pares, y el trie busca para cada número el que más bits altos le invierte. Con subconjuntos, cualquier combinación lineal vale, y el espacio de resultados es un subespacio: la base.

🔬 **El detalle.** El XOR máximo de un tramo **contiguo** es otra cosa: prefijos XOR y trie de prefijos.

**01 → Problema: Radiografía de un número.**

**Pista 2:** `popcount`, el número de ceros al final y el número de ceros al principio (o `bit_length`).

**Pista 3:** C++: `__builtin_popcountll`, `__builtin_ctzll`, `63 − __builtin_clzll`; Java: `Long.bitCount`, `numberOfTrailingZeros`, `63 − numberOfLeadingZeros`; Python: `bit_count`, `(n & −n).bit_length() − 1`, `bit_length() − 1`.

**01 → Problema: XOR de tramos de enteros.**

**Pista 2:** la fórmula del XOR de `1..n` según `n mod 4`.

**Pista 3:** cada consulta es `f(r) ^ f(l − 1)`; `r` hasta `10¹⁸`, en 64 bits.

**01 → Problema: El mayor XOR.**

**Pista 2:** base XOR: el máximo voraz desde el pivote más alto y `2^rango` valores distintos.

**Pista 3:** `rango ≤ 60`; el número de valores cabe en 64 bits sin signo (o en Python sin problema).

**01 → Problema: Number of 1 Bits.**

**Pista 2:** `popcount` de la biblioteca, o `n &= n − 1` en bucle.

**Pista 3:** en Java, el argumento es `int` con signo: `Integer.bitCount(n)` cuenta bien también los negativos.

**01 → Problema: Power of Two.**

**Pista 2:** `n > 0 && (n & (n − 1)) == 0`.

**Pista 3:** cuidado con `n ≤ 0`: no son potencias de 2.

**01 → Problema: Counting Bits.**

**Pista 2:** `bits[i] = bits[i >> 1] + (i & 1)`.

**Pista 3:** o `bits[i] = bits[i & (i − 1)] + 1`; `Θ(n)` en total.

**01 → Problema: Reverse Bits.**

**Pista 2:** saca el bit más bajo de `n` y mételo por la derecha del resultado, 32 veces.

**Pista 3:** en Java, `n >>>= 1`; o `Integer.reverse(n)`.

**01 → Problema: Sum of Two Integers.**

**Pista 2:** `a ^ b` es la suma sin acarreos y `(a & b) << 1` los acarreos; repite hasta que no haya acarreo.

**Pista 3:** en Python, simula 32 bits con una máscara `0xFFFFFFFF` y convierte el resultado a con signo al final.

**01 → Problema: Single Number II.**

**Pista 2:** para cada uno de los 32 bits, cuenta cuántos números lo tienen encendido; módulo 3 queda el bit del único.

**Pista 3:** reconstruye el número con esos bits; en Python, ajusta el signo si el bit 31 queda encendido. Alternativa con dos máscaras `ones` y `twos`.

**01 → Problema: Counting Bits.**

**Pista 2:** cuenta, para cada bit `k`, cuántos números de `0..n` lo tienen encendido: el patrón se repite cada `2^(k+1)`.

**Pista 3:** `(n + 1) / 2^(k+1) · 2^k + max(0, (n + 1) % 2^(k+1) − 2^k)`, sumado sobre `k`; 64 bits.

**01 → Problema: Maximum XOR of Two Numbers in an Array.**

**Pista 2:** voraz bit a bit desde el más alto con un conjunto de prefijos, o un trie binario.

**Pista 3:** con el trie, para cada número baja por el hijo contrario a su bit siempre que exista; el máximo de esos XOR.

**01 → Problema: Minimum Flips to Make a OR b Equal to c.**

**Pista 2:** decide bit a bit: si el bit de `c` es 1, hace falta que alguno de `a`, `b` lo tenga; si es 0, los dos tienen que estar apagados.

**Pista 3:** con `c` a 1 y ambos a 0, un cambio; con `c` a 0, tantos cambios como unos tengan `a` y `b` en ese bit.

**01 → Problema: Square Subsets.**

**Pista 2:** a cada número (hasta 70), el vector de paridades de sus factores primos (19 primos); un subconjunto con producto cuadrado tiene XOR 0.

**Pista 3:** con la base XOR de los `n` vectores y rango `r`, hay `2^(n − r)` subconjuntos con XOR 0; resta el vacío. Módulo `10⁹ + 7`.

**01 → Problema: Mahmoud and Ehab and yet another xor task.**

**Pista 2:** procesa las consultas por `l`; con la base de los `l` primeros y su rango `r`, si `x` se puede formar hay `2^(l − r)` subconjuntos.

**Pista 3:** inserta los elementos de uno en uno guardando el rango tras cada inserción; potencias de 2 precalculadas módulo `10⁹ + 7`.

**01 → Problema: Ivan and Burgers.**

**Pista 2:** base XOR de prefijos que guarda, en cada pivote, el vector con la posición más reciente.

**Pista 3:** al insertar `a[i]` con posición `i`, si choca con un vector de posición menor, intercámbialos y sigue con el antiguo; la consulta `[l, r]` usa la base del prefijo `r` con los vectores de posición `≥ l`.

---

# 02 — Divisibilidad

**02 → 1.** ¿Por qué `gcd(a, b) = gcd(b, a mod b)`? 🟢

⏱️ **30 segundos.** Porque `a mod b = a − qb`: todo divisor común de `a` y `b` divide a `a mod b`, y todo divisor común de `b` y `a mod b` divide a `a = qb + (a mod b)`. Los dos pares tienen los mismos divisores comunes.

🗣️ **2 minutos.** Si los conjuntos de divisores comunes coinciden, sus máximos también. Con `gcd(a, 0) = a` como caso base y `b` decreciente, el algoritmo termina.

🔬 **El detalle.** La versión con restas (`gcd(a − b, b)`) es la misma idea, pero puede tardar `Θ(a/b)` pasos.

**02 → 2.** ¿Cómo calculas el mcm sin desbordar? 🟢

⏱️ **30 segundos.** `a / gcd(a, b) · b`: dividir antes de multiplicar.

🗣️ **2 minutos.** `a · b` puede desbordar aunque el mcm quepa; `a / g` es exacto (`g` divide a `a`) y el resultado final es el mcm. Con números hasta `10⁹`, el mcm cabe en 64 bits pero no en 32.

🔬 **El detalle.** El mcm de muchos números crece muy deprisa: el de `1..40` ya pasa de `10¹⁶`.

**02 → 3.** ¿Cuándo tiene solución entera `ax + by = c`? 🟢

⏱️ **30 segundos.** Si y solo si `gcd(a, b)` divide a `c`.

🗣️ **2 minutos.** Todo `ax + by` es múltiplo de `g`, así que `c` tiene que serlo; y si lo es, multiplicando los coeficientes de Bézout por `c / g` se obtiene una solución.

🔬 **El detalle.** Con `a = b = 0`, solo hay solución si `c = 0`.

**02 → 4.** ¿Qué dice la cota de Lamé y cuál es el peor caso de Euclides? 🟡

⏱️ **30 segundos.** Si Euclides da `k` pasos, `b ≥ F_{k+1}`: el número de pasos es logarítmico. El peor caso son dos Fibonacci consecutivos.

🗣️ **2 minutos.** Con Fibonacci consecutivos, cada cociente es 1 y el par baja al Fibonacci anterior: el mínimo avance posible. `gcd(89, 55)` da 9 pasos. En 64 bits, como mucho unos 92.

🔬 **El detalle.** En promedio, el número de pasos es `≈ 0,84 ln b` (resultado de Heilbronn y Porter).

**02 → 5.** Enuncia la identidad de Bézout. 🟡

⏱️ **30 segundos.** Para `a`, `b` no ambos nulos existen enteros `x`, `y` con `ax + by = gcd(a, b)`, y el gcd es el menor positivo de esa forma.

🗣️ **2 minutos.** Con 252 y 105: `252 · (−2) + 105 · 5 = 21`. Los coeficientes no son únicos: se les puede sumar `(105/21, −252/21) · t`.

🔬 **El detalle.** En particular, `a` tiene inverso módulo `m` si y solo si `gcd(a, m) = 1`.

**02 → 6.** Si `(x₀, y₀)` es una solución de `ax + by = c`, ¿cuáles son todas? 🟡

⏱️ **30 segundos.** `x = x₀ + (b/g) t`, `y = y₀ − (a/g) t` para `t` entero, con `g = gcd(a, b)`.

🗣️ **2 minutos.** La diferencia de dos soluciones cumple `a Δx = −b Δy`; dividiendo por `g`, `a/g` y `b/g` son coprimos, así que `b/g` divide a `Δx`. De ahí el paso `(b/g, −a/g)`.

🔬 **El detalle.** Para `252x + 105y = 63`, desde `(−6, 15)`: `x = −6 + 5t`, `y = 15 − 12t`.

**02 → 7.** ¿Qué pasa con `%` y `/` con negativos en C++, Java y Python, y cómo afecta al gcd y a las diofánticas? 🟡

⏱️ **30 segundos.** En C++ y Java, `/` trunca hacia 0 y `%` tiene el signo del dividendo; en Python, `//` redondea hacia `−∞` y `%` tiene el signo del divisor.

🗣️ **2 minutos.** Para el gcd basta trabajar con valores absolutos. En las diofánticas, los extremos del rango de `t` son `⌈·⌉` y `⌊·⌋` de cocientes que pueden ser negativos: en C++ y Java hacen falta `floorDiv` y su equivalente para el techo; en Python, `//` ya sirve.

🔬 **El detalle.** `Math.floorDiv` y `Math.floorMod` existen en Java desde la 8.

**02 → 8.** Demuestra la identidad de Bézout. 🟠

⏱️ **30 segundos.** El menor positivo `d` de la forma `ax + by` divide a `a`: el resto de `a` entre `d` también es de esa forma y es menor que `d`, así que es 0. Igual con `b`. Y todo divisor común divide a `d`.

🗣️ **2 minutos.** El conjunto `{ax + by}` es cerrado por restas y múltiplos; su menor positivo divide a todos sus elementos. Como `a` y `b` están en él, `d` es divisor común; y como cualquier divisor común divide a toda combinación, es el máximo.

🔬 **El detalle.** La prueba no construye `x`, `y`: eso lo hace el algoritmo extendido.

**02 → 9.** Deduce la recurrencia de los coeficientes del Euclides extendido. 🟠

⏱️ **30 segundos.** Si `g = b x′ + (a mod b) y′` y `a mod b = a − ⌊a/b⌋ b`, entonces `g = a y′ + b (x′ − ⌊a/b⌋ y′)`.

🗣️ **2 minutos.** Se resuelve recursivamente el par `(b, a mod b)` y se sustituye. En la versión iterativa, se llevan dos pares de coeficientes que expresan los dos últimos restos como combinación de `a` y `b`, y se actualizan con el cociente de cada paso.

🔬 **El detalle.** El caso base es `(g, 1, 0)` cuando `b = 0`.

**02 → 10.** ¿Cómo cuentas las soluciones no negativas de `ax + by = c` sin recorrerlas? 🟠

⏱️ **30 segundos.** Con una solución particular y el paso, las no negativas son un tramo de `t`: `t ≥ ⌈−x₀/(b/g)⌉` y `t ≤ ⌊y₀/(a/g)⌋`. Son `max(0, hi − lo + 1)`.

🗣️ **2 minutos.** `x ≥ 0` y `y ≥ 0` dan dos desigualdades lineales en `t`; su intersección es un intervalo de enteros. Lo delicado son los redondeos con negativos y que `x₀` puede necesitar 128 bits.

🔬 **El detalle.** En el ejemplo de 6 y 10 con `c = 100`, cuatro valores de `t`.

**02 → 11.** ¿Cuántos puntos distintos visitas saltando de `s` en `s` en un círculo de `n` posiciones? 🟠

⏱️ **30 segundos.** `n / gcd(n, s)`.

🗣️ **2 minutos.** Las posiciones visitadas son los múltiplos de `s` módulo `n`, que son exactamente los múltiplos de `gcd(n, s)`; hay `n / gcd` de ellos, y el recorrido vuelve al inicio tras ese número de saltos.

🔬 **El detalle.** Es ChocolatesByNumbers, y la razón de que una permutación por rotación se descomponga en `gcd(n, k)` ciclos.

**02 → 12.** ¿Por qué los coeficientes de Bézout que da el extendido no desbordan? 🔴

⏱️ **30 segundos.** Porque el extendido devuelve coeficientes con `|x| ≤ b/g` y `|y| ≤ a/g`: si `a` y `b` caben, los coeficientes también.

🗣️ **2 minutos.** Se demuestra por inducción sobre los pasos: los coeficientes intermedios están acotados por los cocientes de los restos. Lo que sí puede desbordar es multiplicarlos por `c/g` para la solución particular.

🔬 **El detalle.** Por eso, con `c` hasta `10¹⁸`, se pasa a `__int128` o `BigInteger` justo en esa multiplicación.

**02 → 13.** Entre las soluciones no negativas de `ax + by = c`, ¿cómo eliges la de menos monedas? 🔴

⏱️ **30 segundos.** `x + y = x₀ + y₀ + t (b − a)/g` es lineal en `t`: el mínimo está en un extremo del rango de `t` válidos (el mayor `t` si `a > b`, el menor si `a < b`).

🗣️ **2 minutos.** Si la moneda `a` vale más que la `b`, conviene usar el mayor número posible de monedas de `a`: el `t` más grande del rango. Se calcula el rango como en la pregunta 10 y se evalúa el extremo adecuado.

🔬 **El detalle.** Con `a = b`, todas las soluciones usan el mismo número de monedas.

**02 → Problema: Máximo y mínimo.**

**Pista 2:** Euclides y `a / g · b`.

**Pista 3:** el mcm puede llegar a `10¹⁸`: 64 bits.

**02 → Problema: Puntos en el segmento.**

**Pista 2:** el vector `(dx, dy)` se divide en `gcd(|dx|, |dy|)` pasos iguales de coordenadas enteras.

**Pista 3:** la respuesta es `gcd(|dx|, |dy|) + 1`; si los dos extremos coinciden, 1.

**02 → Problema: Pagar con menos monedas.**

**Pista 2:** solución particular con el extendido, el rango de `t` con `x, y ≥ 0`, y `x + y` lineal en `t`.

**Pista 3:** evalúa los dos extremos del rango y quédate con el menor `x + y`; `x₀` en 128 bits (o `BigInteger`). Si no hay `t`, `-1`.

**02 → Problema: ChocolatesByNumbers.**

**Pista 2:** se comen `N / gcd(N, M)` chocolates.

**Pista 3:** un gcd y una división; con `N` hasta `10⁹`, sin bucles.

**02 → Problema: Find Greatest Common Divisor of Array.**

**Pista 2:** el gcd del mínimo y del máximo del arreglo.

**Pista 3:** una pasada para el mínimo y el máximo, y Euclides.

**02 → Problema: Greatest Common Divisor of Strings.**

**Pista 2:** si `s + t = t + s`, el divisor es el prefijo de longitud `gcd(|s|, |t|)`; si no, no hay.

**Pista 3:** compara las dos concatenaciones y devuelve `s[0 : gcd]` o la cadena vacía.

**02 → Problema: X of a Kind in a Deck of Cards.**

**Pista 2:** el gcd de todas las frecuencias tiene que ser al menos 2.

**Pista 3:** cuenta con un mapa y pliega el gcd sobre los valores.

**02 → Problema: CommonPrimeDivisors.**

**Pista 2:** `a` y `b` tienen los mismos primos si, tras quitarles repetidamente su gcd con `g = gcd(a, b)`, ambos quedan en 1.

**Pista 3:** para `a`, mientras `gcd(a, g) > 1`, divide `a` por él; igual con `b`. Sin factorizar.

**02 → Problema: Water and Jug Problem.**

**Pista 2:** se pueden medir exactamente las cantidades múltiplo de `gcd(x, y)` que no superan `x + y`.

**Pista 3:** responde `target ≤ x + y` y `target % gcd(x, y) == 0` (con cuidado si `target = 0`).

**02 → Problema: Common Divisors.**

**Pista 2:** para cada `d` de mayor a menor, cuenta cuántos números del arreglo son múltiplos de `d`; el primero con al menos dos es la respuesta.

**Pista 3:** un arreglo de frecuencias por valor y, para cada `d`, recorrer sus múltiplos: `Σ n/d = O(n log n)` con `n = 10⁶`.

**02 → Problema: Check If It Is a Good Array.**

**Pista 2:** Bézout con varios números: se puede formar 1 si y solo si el gcd de todo el arreglo es 1.

**Pista 3:** pliega el gcd y para en cuanto llegue a 1.

**02 → Problema: Candy Distribution.**

**Pista 2:** buscas `X` con `C · Y = K · X + 1`: es el inverso de `C` módulo `K`, con el extendido.

**Pista 3:** si `gcd(C, K) ≠ 1`, imposible; ajusta `Y` al menor válido (mayor que 0 y con `X ≥ 1`) y comprueba el límite de `10⁹`.

**02 → Problema: Nth Magical Number.**

**Pista 2:** búsqueda binaria sobre `x`, contando `x/a + x/b − x/mcm(a, b)` múltiplos.

**Pista 3:** el menor `x` con `n` o más; módulo `10⁹ + 7` al final. El mcm, dividiendo antes de multiplicar.

**02 → Problema: Billiard.**

**Pista 2:** despliega la mesa por reflexiones: la bola va en línea recta en la diagonal y llega a una tronera cuando sus coordenadas son múltiplos de `n` y `m` a la vez.

**Pista 3:** queda una diofántica `n·i − m·j = c` en el número de mesas recorridas; la paridad de `i` y `j` dice qué tronera. Los casos con velocidad 0 en un eje, aparte.

---

# 03 — Aritmética modular

**03 → 1.** ¿Cómo calculas `a^e mod m` en `O(log e)`? 🟢

⏱️ **30 segundos.** Con exponenciación binaria: recorrer los bits de `e`, elevando la base al cuadrado en cada paso y multiplicando al resultado cuando el bit es 1.

🗣️ **2 minutos.** `a^e` es el producto de las `a^(2^i)` de los bits encendidos de `e`; cada una es el cuadrado de la anterior. Como mucho `2 log₂ e` multiplicaciones, reduciendo módulo `m` en cada una.

🔬 **El detalle.** El valor inicial `1 % m` cubre `m = 1`.

**03 → 2.** ¿Cuándo tiene inverso `a` módulo `m`? 🟢

⏱️ **30 segundos.** Si y solo si `gcd(a, m) = 1`.

🗣️ **2 minutos.** `a x ≡ 1 (mod m)` equivale a `a x + m y = 1`, que tiene solución entera exactamente cuando el gcd es 1 (Bézout). Si existe, es único módulo `m`.

🔬 **El detalle.** Con `m` primo, todos los no múltiplos de `m` tienen inverso: los restos forman un cuerpo.

**03 → 3.** ¿Cómo calculas el inverso módulo un primo? 🟢

⏱️ **30 segundos.** `a^(p−2) mod p` por Fermat, con exponenciación rápida; o con Euclides extendido.

🗣️ **2 minutos.** Fermat da `a^(p−1) ≡ 1`, así que `a · a^(p−2) ≡ 1`. Exige que `p` sea primo y `a` no múltiplo de `p`. El extendido sirve con cualquier módulo y detecta si no existe.

🔬 **El detalle.** En Python, `pow(a, -1, m)` (3.8+).

**03 → 4.** ¿Por qué no se puede dividir y luego aplicar el módulo? Da un ejemplo. 🟢

⏱️ **30 segundos.** Porque la división entera no respeta los restos: `10/5 = 2`, pero `(10 mod 7)/(5 mod 7) = 3/5`, que ni siquiera es entero. Se multiplica por el inverso: `3 · 5⁻¹ ≡ 3 · 3 = 9 ≡ 2`.

🗣️ **2 minutos.** Suma, resta y producto conmutan con el módulo; la división no. Por eso, en un cálculo con divisiones módulo `p`, cada división se sustituye por un producto con el inverso del divisor.

🔬 **El detalle.** Solo si el resultado exacto es un entero y no se ha reducido nada antes se puede dividir sin inverso.

**03 → 5.** ¿Qué tipos usas para multiplicar dos restos en C++, Java y Python según el tamaño del módulo? 🟡

⏱️ **30 segundos.** Con módulos `< 2³¹`: `long long` / `long` para el producto, y Python sin preocuparse. Con módulos de hasta `10¹⁸`: `__int128` en C++, `Math.multiplyHigh` o `BigInteger` en Java, y Python igual.

🗣️ **2 minutos.** El producto de dos restos ocupa el doble de bits que el módulo. Con `10⁹ + 7`, `10¹⁸` cabe en 64 bits con signo; con `998 244 353`, también. Con módulos de 60 bits, hacen falta 120.

🔬 **El detalle.** En JavaScript, ni siquiera los de `10⁹` son seguros en `Number`: `BigInt`.

**03 → 6.** ¿Cómo calculas los inversos de `1..n` módulo `p` en lineal? 🟡

⏱️ **30 segundos.** `inv[1] = 1` y `inv[i] = −⌊p/i⌋ · inv[p mod i] mod p`, para `i` de 2 a `n`.

🗣️ **2 minutos.** `p mod i < i`, así que su inverso ya está calculado. Una multiplicación por número: `Θ(n)` frente a `Θ(n log p)` con Fermat para cada uno.

🔬 **El detalle.** Exige `p` primo y `n < p`.

**03 → 7.** ¿Cómo reduces el exponente de `a^(b^c) mod p`? 🟡

⏱️ **30 segundos.** Por Fermat, si `p ∤ a`: `a^(b^c) ≡ a^(b^c mod (p − 1)) (mod p)`. Se calcula `b^c mod (p − 1)` y luego la potencia.

🗣️ **2 minutos.** Como `a^(p−1) ≡ 1`, los exponentes se pueden reducir módulo `p − 1`. Si `p | a`, el resultado es 0 (salvo exponente 0).

🔬 **El detalle.** Con módulos compuestos, el teorema de Euler generalizado (reducir módulo `φ(m)` y sumar `φ(m)` si el exponente es grande) es el de Tetration Mod.

**03 → 8.** Demuestra el pequeño teorema de Fermat. 🟠

⏱️ **30 segundos.** `a, 2a, …, (p − 1)a` son una permutación de `1, …, p − 1` módulo `p`; multiplicándolos, `a^(p−1) (p − 1)! ≡ (p − 1)!`, y se cancela `(p − 1)!`.

🗣️ **2 minutos.** Son distintos porque `ia ≡ ja` implica `i ≡ j` (multiplicando por el inverso de `a`), y ninguno es 0. `(p − 1)!` es invertible porque es producto de invertibles.

🔬 **El detalle.** El teorema de Wilson añade que `(p − 1)! ≡ −1 (mod p)`.

**03 → 9.** ¿Qué dice el teorema chino del resto con módulos coprimos, y qué cambia si no lo son? 🟠

⏱️ **30 segundos.** Con módulos coprimos dos a dos, el sistema tiene solución única módulo su producto. Si no son coprimos, dos congruencias son compatibles si y solo si `a₁ ≡ a₂ (mod gcd(m₁, m₂))`, y la solución es única módulo el mcm.

🗣️ **2 minutos.** Se combinan de dos en dos: `x = a₁ + m₁ t` en la segunda da `m₁ t ≡ a₂ − a₁ (mod m₂)`, una diofántica que exige `gcd | a₂ − a₁`.

🔬 **El detalle.** En el ejemplo, `x ≡ 0 (mod 4)` y `x ≡ 1 (mod 6)` son incompatibles: `gcd = 2` no divide a 1.

**03 → 10.** Deduce la recurrencia `inv[i] = −⌊p/i⌋ · inv[p mod i]`. 🟠

⏱️ **30 segundos.** De `p = ⌊p/i⌋ · i + (p mod i)`, módulo `p`: `0 ≡ ⌊p/i⌋ · i + (p mod i)`. Multiplicando por `i⁻¹ · (p mod i)⁻¹`: `i⁻¹ ≡ −⌊p/i⌋ · (p mod i)⁻¹`.

🗣️ **2 minutos.** Es despejar `i⁻¹` en la identidad de la división. Como `p mod i` está entre 1 e `i − 1` (es distinto de 0 porque `p` es primo e `i < p`), su inverso ya se calculó.

🔬 **El detalle.** El `−` se resuelve sumando `p` para quedar en `[0, p)`.

**03 → 11.** ¿Cómo calculas los inversos de todos los factoriales hasta `n` con una sola exponenciación? 🟠

⏱️ **30 segundos.** Se calculan los factoriales, el inverso del último con Fermat, y los demás hacia atrás: `invFact[i − 1] = invFact[i] · i`.

🗣️ **2 minutos.** `(i − 1)!⁻¹ = i!⁻¹ · i`. Una exponenciación y `n` productos: `Θ(n + log p)`. Es la preparación de `nCr` módulo `p` ([`17/05`](05-combinatoria.md)).

🔬 **El detalle.** También sirve para obtener todos los `i⁻¹ = invFact[i] · (i − 1)!`.

**03 → 12.** ¿Qué haces si tienes que dividir módulo un número compuesto y el divisor no es coprimo con él? 🔴

⏱️ **30 segundos.** No hay inverso: o se cancelan los factores comunes antes de reducir, o se factoriza el módulo y se trabaja módulo cada potencia de primo, combinando con el TCR.

🗣️ **2 minutos.** Si se sabe que el resultado exacto es entero, se pueden llevar aparte los factores primos comunes al módulo (contando sus exponentes) y operar con inversos en el resto. Con `m = Π pᵢ^kᵢ`, el cálculo módulo cada `pᵢ^kᵢ` y el TCR dan el resultado módulo `m`.

🔬 **El detalle.** Es el esquema de `nCr` módulo un compuesto (Lucas generalizado, Granville).

**03 → 13.** ¿Cómo calcularías `n! mod m` para `m` compuesto pequeño y `n` enorme, combinando resultados? 🔴

⏱️ **30 segundos.** Factorizando `m` en potencias de primos, calculando `n!` módulo cada `pᵏ` (con la parte sin factores `p` y el exponente de `p` aparte) y combinando con el TCR.

🗣️ **2 minutos.** Si `n ≥` algún primo de `m`, `n!` es 0 módulo `p` pero no necesariamente módulo `pᵏ`; los productos de los bloques de `pᵏ` números coprimos con `p` se repiten, lo que permite `O(pᵏ + log n)` por factor.

🔬 **El detalle.** Si `n ≥ m`, `n! ≡ 0 (mod m)` directamente.

**03 → Problema: Las últimas cifras.**

**Pista 2:** `aᵉ mod 10ᵏ` con exponenciación binaria.

**Pista 3:** imprime el resultado con `k` cifras rellenando con ceros (`printf("%0*lld")`, `String.format`, `str.zfill`); con `e = 0`, la respuesta es `1` con ceros delante.

**03 → Problema: Todos los inversos.**

**Pista 2:** la recurrencia lineal `inv[i] = −⌊p/i⌋ · inv[p mod i]`.

**Pista 3:** productos en 64 bits y salida con un búfer: `10⁶` números.

**03 → Problema: Congruencias.**

**Pista 2:** combina de dos en dos con el TCR general, empezando por `x ≡ 0 (mod 1)`.

**Pista 3:** en cada combinación, si `gcd(m, mᵢ)` no divide a la diferencia, `-1`; los productos intermedios, en 128 bits (o `BigInteger`).

**03 → Problema: Modular Arithmetic.**

**Pista 2:** suma, resta y producto módulo `n`; la división, con el inverso por el extendido.

**Pista 3:** si `gcd(y, n) ≠ 1`, imprime `-1`; restos no negativos; los productos de hasta `10¹⁸` en 64 bits o `__int128`.

**03 → Problema: Count Collisions of Monkeys on a Polygon.**

**Pista 2:** solo hay dos formas sin colisión (todos a un lado o todos al otro): la respuesta es `2ⁿ − 2`.

**Pista 3:** potencia modular y resta con `+ MOD` para no quedar negativo.

**03 → Problema: Power of large numbers.**

**Pista 2:** reduce la base módulo `p` dígito a dígito, y el exponente módulo `p − 1` (Fermat).

**Pista 3:** si la base es múltiplo de `p`, la respuesta es 0; cuidado con el exponente reducido a 0.

**03 → Problema: Chinese Remainder.**

**Pista 2:** TCR con dos módulos coprimos.

**Pista 3:** el producto de los módulos llega a `10¹⁸` y los productos intermedios lo superan: 128 bits o `BigInteger`.

**03 → Problema: Chinese Remainder Theorem (non-relatively prime moduli).**

**Pista 2:** TCR general: compatibilidad módulo el gcd y solución módulo el mcm.

**Pista 3:** si no hay solución, `no solution`; si la hay, `x` y el mcm.

**03 → Problema: Divisor Analysis.**

**Pista 2:** número, suma y producto de divisores desde la factorización; el producto es `n^(d/2)`.

**Pista 3:** para el producto, el exponente se reduce módulo `p − 1`; si `d` es impar, `n` es cuadrado: usa `√n^d`, o lleva `d` módulo `2(p − 1)`.

**03 → Problema: Remainders Game.**

**Pista 2:** conocer `x mod cᵢ` para todos los `i` da `x mod mcm(cᵢ)` (TCR); hace falta que `k` divida a ese mcm.

**Pista 3:** sin calcular el mcm (puede ser enorme): `k` divide al mcm si para cada potencia de primo de `k` hay algún `cᵢ` divisible por ella; o mcm reducido con `gcd` con `k`.

**03 → Problema: Discrete Logarithm.**

**Pista 2:** paso de bebé, paso de gigante: `x = i·s − j` con `s ≈ √m`; guarda `a^j · y` en una tabla y prueba `a^(i·s)`.

**Pista 3:** con `gcd(a, m) ≠ 1`, primero hay que extraer factores comunes; el menor `x ≥ 0`.

**03 → Problema: Tetration Mod.**

**Pista 2:** el teorema de Euler generalizado: `a^e ≡ a^(e mod φ(m) + φ(m))` si `e ≥ log₂ m`.

**Pista 3:** recursión sobre `m → φ(m)`, que llega a 1 en `O(log m)` pasos; lleva aparte si el exponente es «grande».

---

# 04 — Primos

**04 → 1.** ¿Por qué basta probar divisores hasta `√n`? 🟢

⏱️ **30 segundos.** Porque si `n = a · b` con `1 < a ≤ b`, entonces `a ≤ √n`: todo compuesto tiene un divisor (y por tanto un primo) `≤ √n`.

🗣️ **2 minutos.** Si los dos factores fueran mayores que `√n`, su producto superaría `n`. Por eso la división por tentativa se para en `√n`, y si no encuentra divisor, lo que queda es primo.

🔬 **El detalle.** Al factorizar, lo que queda tras dividir por todos los `d ≤ √n` es 1 o un primo.

**04 → 2.** ¿Por qué la criba empieza a tachar en `p²`? 🟢

⏱️ **30 segundos.** Porque los múltiplos `k · p` con `k < p` tienen un factor primo menor que `p` y ya los tachó ese primo.

🗣️ **2 minutos.** `k · p` con `k < p` es múltiplo de algún primo `q ≤ k < p`, que se procesó antes. Empezar en `p²` no cambia el resultado y ahorra trabajo; además, el bucle exterior solo llega hasta `√n`.

🔬 **El detalle.** Por eso `p * p` debe calcularse en 64 bits.

**04 → 3.** ¿Cómo factorizas un número con el arreglo `spf`? 🟢

⏱️ **30 segundos.** Dividiendo `x` por `spf[x]` una y otra vez hasta llegar a 1, y agrupando los primos iguales.

🗣️ **2 minutos.** Cada división deja un número cuyo menor factor primo también está en la tabla. Como cada paso divide al menos entre 2, son `O(log x)` divisiones.

🔬 **El detalle.** La tabla tiene que llegar hasta el mayor `x` que se vaya a factorizar.

**04 → 4.** ¿Cuántos divisores tiene `360`, y cómo se calcula desde la factorización? 🟢

⏱️ **30 segundos.** 24: `360 = 2³ · 3² · 5¹` y el número de divisores es `(3 + 1)(2 + 1)(1 + 1)`.

🗣️ **2 minutos.** Un divisor elige, para cada primo, un exponente entre 0 y el de `n`: `Π (eᵢ + 1)` combinaciones. La suma de divisores es `Π (1 + p + … + p^e)`: `15 · 13 · 6 = 1 170`.

🔬 **El detalle.** El número de divisores de `n ≤ 10¹⁸` no pasa de unos `10⁵`; de `n ≤ 10⁹`, de 1 344.

**04 → 5.** ¿Cuánto cuesta la criba de Eratóstenes y de dónde sale el `log log n`? 🟡

⏱️ **30 segundos.** `Θ(n log log n)`: cada primo `p` tacha `n/p` números, y `Σ 1/p` sobre los primos hasta `n` crece como `log log n` (Mertens).

🗣️ **2 minutos.** El trabajo total es `n · Σ_{p ≤ √n} 1/p`. La suma de los inversos de los primos crece doblemente logarítmica: en la práctica, la criba es casi lineal.

🔬 **El detalle.** La criba lineal es `Θ(n)` exacta, pero con más trabajo por número; en tiempo real, Eratóstenes con bits suele ganar.

**04 → 6.** ¿Qué hace la criba lineal para tachar cada compuesto una sola vez? 🟡

⏱️ **30 segundos.** Tacha cada compuesto `i · p` solo con el primo `p ≤ spf(i)`: así cada compuesto se genera una vez, por su menor factor primo.

🗣️ **2 minutos.** Un compuesto `x` con menor factor `p` se escribe de forma única como `p · i` con `spf(i) ≥ p`. El bucle interior recorre los primos hasta `spf(i)` y para: no genera `x` desde otro `i`.

🔬 **El detalle.** Por eso es `Θ(n)` exacto y deja `spf` como subproducto.

**04 → 7.** ¿Cómo criba Python hasta `10⁷` en menos de un segundo? 🟡

⏱️ **30 segundos.** Con un `bytearray` y tachando por cortes: `is_prime[p*p::p] = bytes(...)`, que hace el bucle interior en C.

🗣️ **2 minutos.** El bucle interior en Python puro haría unos `2,5·10⁷` asignaciones de intérprete. La asignación por cortes copia un bloque de ceros en una sola operación. El bucle exterior solo llega a `√n`.

🔬 **El detalle.** Con NumPy, `is_prime[p*p::p] = False` sobre un arreglo booleano es igual de rápido.

**04 → 8.** ¿Cómo encuentras los primos de `[10¹², 10¹² + 10⁶]`? 🟡

⏱️ **30 segundos.** Criba segmentada: los primos hasta `√(10¹² + 10⁶) ≈ 10⁶` y, con ellos, tachar sus múltiplos dentro del intervalo.

🗣️ **2 minutos.** El primer múltiplo de `p` en `[L, R]` es `max(p², ⌈L/p⌉ · p)`. Un arreglo de `R − L + 1` marcas y unos `78 000` primos base. `Θ(√R + (R − L) log log R)`.

🔬 **El detalle.** Si `L ≤ 1`, hay que desmarcar el 0 y el 1 a mano.

**04 → 9.** ¿Por qué el test de Fermat no basta, y qué añade Miller-Rabin? 🟠

⏱️ **30 segundos.** Porque los números de Carmichael cumplen `a^(n−1) ≡ 1` para toda base coprima. Miller-Rabin exige además que la cadena de cuadrados desde `a^d` llegue a 1 pasando por `−1`.

🗣️ **2 minutos.** En un primo, `x² ≡ 1` solo tiene las raíces `±1`. En 561, la cadena de la base 2 es `263, 166, 67, 1`: `67² ≡ 1` con `67 ≠ ±1` es una raíz no trivial de 1, que delata un compuesto.

🔬 **El detalle.** Para todo compuesto impar, al menos 3/4 de las bases son testigos: la versión aleatoria con `k` bases falla con probabilidad `≤ 4^(−k)`.

**04 → 10.** ¿Por qué Miller-Rabin con las 12 primeras bases primas es determinista en 64 bits? 🟠

⏱️ **30 segundos.** Porque se ha comprobado por cómputo que ningún compuesto menor que `3,3·10²⁴` pasa el test con esas 12 bases a la vez.

🗣️ **2 minutos.** El resultado es empírico-computacional (listas de pseudoprimos fuertes), no un teorema general. Para 64 bits hay incluso conjuntos de 7 bases que bastan. Con las 12 primeras, el margen cubre `2⁶⁴` de sobra.

🔬 **El detalle.** Bajo la hipótesis de Riemann generalizada, bastaría probar las bases hasta `2 ln² n`.

**04 → 11.** Calcula `φ(360)` y explica la fórmula. 🟠

⏱️ **30 segundos.** `φ(360) = 360 · (1 − 1/2)(1 − 1/3)(1 − 1/5) = 96`.

🗣️ **2 minutos.** `φ` es multiplicativa y `φ(p^e) = p^e − p^(e−1)`; juntando, `φ(n) = n Π (1 − 1/p)` sobre los primos que dividen a `n`. Cuenta los `k ≤ n` coprimos con `n`.

🔬 **El detalle.** Para todos los `n ≤ N`, la criba `φ[q] −= φ[q]/p` sobre los múltiplos de cada primo.

**04 → 12.** ¿Cómo factorizarías `q = 100` números de hasta `10¹⁸`? 🔴

⏱️ **30 segundos.** Pollard rho para encontrar un factor, Miller-Rabin para saber cuándo parar, y recursión sobre los dos factores.

🗣️ **2 minutos.** Rho da un factor en `O(n^(1/4))` esperado: unos `3·10⁴` pasos con `n ≈ 10¹⁸`. Con 100 números, sobra. Los productos módulo `n`, en 128 bits.

🔬 **El detalle.** Antes de rho conviene quitar los factores pequeños por división (hasta unos miles).

**04 → 13.** ¿Cómo cuentas los divisores de un `n ≤ 10¹⁸` sin factorizarlo del todo? 🔴

⏱️ **30 segundos.** División por tentativa hasta `n^(1/3)` y, para lo que queda `r`, decidir con Miller-Rabin y una raíz cuadrada si es 1, primo, cuadrado de primo o producto de dos primos distintos.

🗣️ **2 minutos.** Tras quitar los primos `≤ n^(1/3)`, el resto tiene como mucho dos factores primos. Si es primo, aporta `×2`; si es `p²`, `×3`; si es `p · q`, `×4`. `O(n^(1/3))` divisiones: `10⁶`.

🔬 **El detalle.** Es el truco de Codeforces para contar divisores de números hasta `10¹⁸` sin Pollard rho.

**04 → Problema: Primos gemelos.**

**Pista 2:** criba hasta `n` y recorrer los `p` con `p` y `p + 2` primos.

**Pista 3:** con `10⁷`, criba de bytes o bits; en Python, con cortes.

**04 → Problema: Divisores de muchos.**

**Pista 2:** criba lineal con `spf` hasta `10⁶` y, para cada número, su factorización.

**Pista 3:** número `Π (e + 1)` y suma `Π (p^(e+1) − 1)/(p − 1)`; la suma de divisores de `10⁶` cabe en 64 bits.

**04 → Problema: Primos en una ventana.**

**Pista 2:** criba segmentada con los primos hasta `10⁶`.

**Pista 3:** marca el intervalo, desmarca 0 y 1 si caen dentro, y cuenta.

**04 → Problema: CountFactors.**

**Pista 2:** recorre `d` de 1 a `√N`: cada divisor `d < √N` aporta 2 (`d` y `N/d`), y `√N`, si es entero, 1.

**Pista 3:** cuidado con `d * d` en 32 bits cerca de `2³¹`.

**04 → Problema: MinPerimeterRectangle.**

**Pista 2:** el perímetro mínimo es `2(d + N/d)` con `d` el mayor divisor `≤ √N`.

**Pista 3:** recorre `d` de `⌊√N⌋` hacia abajo hasta el primer divisor.

**04 → Problema: Largest Prime Factor.**

**Pista 2:** divide `n` por cada `d` mientras se pueda, de 2 hacia arriba hasta `√n`.

**Pista 3:** lo que queda al final, si es mayor que 1, es el mayor factor primo.

**04 → Problema: CountSemiprimes.**

**Pista 2:** `x` es semiprimo si `spf[x]` y `x / spf[x]` son primos.

**Pista 3:** prefijos de cuántos semiprimos hay hasta cada `x`; cada consulta es una resta.

**04 → Problema: CountNonDivisible.**

**Pista 2:** cuenta las apariciones de cada valor; para cada valor `v`, los divisores del arreglo son los `d` que dividen a `v`.

**Pista 3:** recorre los divisores de cada valor distinto hasta `√v` sumando apariciones; la respuesta es `N −` esa suma.

**04 → Problema: Closest Prime Numbers in Range.**

**Pista 2:** criba hasta `right` y recorre los primos del rango comparando consecutivos.

**Pista 3:** el par más cercano son dos primos consecutivos; en empate, el primero.

**04 → Problema: Peaks.**

**Pista 2:** prueba los tamaños de bloque que dividen a `N`, de menor a mayor, y comprueba si cada bloque tiene un pico.

**Pista 3:** con prefijos del número de picos, cada comprobación es `O(N / tamaño)`; la suma sobre los divisores es pequeña.

**04 → Problema: Two Divisors.**

**Pista 2:** si `a` tiene al menos dos primos distintos, `d₁ = p^e` (la potencia de su menor primo) y `d₂ = a / d₁` son coprimos y su suma es coprima con `a`.

**Pista 3:** con `spf` hasta `10⁷`; si `a` es potencia de un primo, `-1 -1`.

**04 → Problema: Primality Test.**

**Pista 2:** Miller-Rabin determinista con productos de 128 bits.

**Pista 3:** `10⁵` consultas de hasta `10¹⁸`: 12 exponenciaciones cada una.

**04 → Problema: Sum of Divisors.**

**Pista 2:** `Σ σ(i) = Σ_d d · ⌊n/d⌋`, y `⌊n/d⌋` toma `O(√n)` valores distintos.

**Pista 3:** para cada bloque de `d` con el mismo cociente `q`, suma `q` por la suma de los `d` del bloque (fórmula de la serie aritmética) módulo `10⁹ + 7`.

**04 → Problema: Factorize.**

**Pista 2:** Pollard rho con Miller-Rabin, recursivo.

**Pista 3:** quita antes los factores pequeños por división; la variante de Brent con productos acumulados antes del `gcd` acelera mucho.

---

# 05 — Combinatoria

**05 → 1.** ¿Cómo calculas `C(n, k) mod p` en `O(1)` por consulta? 🟢

⏱️ **30 segundos.** Precalculando `fact[i]` e `invFact[i]` hasta el máximo `n`, y respondiendo `fact[n] · invFact[k] · invFact[n − k] mod p`.

🗣️ **2 minutos.** Con `p` primo y `n < p`, los factoriales son invertibles. El preproceso es `Θ(N)` más una exponenciación; cada consulta, dos productos.

🔬 **El detalle.** Fuera de rango (`k < 0` o `k > n`) se devuelve 0, y muchas fórmulas lo necesitan.

**05 → 2.** ¿Cuántas soluciones tiene `x₁ + … + x_k = n` con `xᵢ ≥ 0`, y con `xᵢ ≥ 1`? 🟢

⏱️ **30 segundos.** Con `xᵢ ≥ 0`: `C(n + k − 1, k − 1)`. Con `xᵢ ≥ 1`: `C(n − 1, k − 1)`.

🗣️ **2 minutos.** Una solución es una fila de `n` estrellas y `k − 1` barras; se eligen las posiciones de las barras. Con mínimos, se reparten primero los mínimos y se cuenta el resto con `≥ 0`.

🔬 **El detalle.** En el ejemplo, 10 caramelos entre 3 niños: 66 con `≥ 0` y 36 con `≥ 1`.

**05 → 3.** ¿Cuántos caminos monótonos hay en una rejilla de `R × C`? 🟢

⏱️ **30 segundos.** `C(R + C − 2, R − 1)`: se eligen cuáles de los `R + C − 2` movimientos van hacia abajo.

🗣️ **2 minutos.** Todo camino monótono tiene `R − 1` movimientos abajo y `C − 1` a la derecha, en algún orden. En una rejilla de `3 × 4`, `C(5, 2) = 10`.

🔬 **El detalle.** Con una casilla obligatoria, producto de dos binomiales; con varias prohibidas, inclusión-exclusión ordenándolas.

**05 → 4.** ¿Por qué basta un Fermat para todos los inversos de los factoriales? 🟡

⏱️ **30 segundos.** Porque `invFact[i − 1] = invFact[i] · i`: con el inverso del mayor factorial (un Fermat) salen todos los demás hacia atrás.

🗣️ **2 minutos.** `(i − 1)!⁻¹ = (i!)⁻¹ · i` porque `i! = i · (i − 1)!`. Una exponenciación y `n` productos, frente a `n` exponenciaciones.

🔬 **El detalle.** Los inversos de los propios números salen gratis: `i⁻¹ = invFact[i] · (i − 1)!`.

**05 → 5.** ¿Qué dice el teorema de Lucas y cuándo hace falta? 🟡

⏱️ **30 segundos.** `C(n, k) ≡ Π C(nᵢ, kᵢ) (mod p)` con `nᵢ`, `kᵢ` las cifras en base `p`. Hace falta cuando `n ≥ p` (los factoriales son 0 módulo `p`).

🗣️ **2 minutos.** Típico con `p` pequeño: 2, 3, `10⁴ + 7`. Se precalculan factoriales hasta `p − 1` y cada consulta es `O(log_p n)`.

🔬 **El detalle.** Con `p = 2`: `C(n, k)` es impar si y solo si los bits de `k` son subconjunto de los de `n` (`k & n == k`).

**05 → 6.** ¿Qué cuentan los números de Catalan? Da tres ejemplos. 🟡

⏱️ **30 segundos.** Las secuencias bien formadas de `n` pares de paréntesis, los árboles binarios de `n` nodos y las triangulaciones de un polígono de `n + 2` lados.

🗣️ **2 minutos.** También los caminos monótonos de `(0, 0)` a `(n, n)` que no cruzan la diagonal, las formas de multiplicar `n + 1` matrices con paréntesis y las montañas de `n` subidas. Todos cumplen `Cₙ₊₁ = Σ Cᵢ Cₙ₋ᵢ`.

🔬 **El detalle.** `1, 1, 2, 5, 14, 42, 132`: reconocer la sucesión en los primeros valores es la pista más rápida.

**05 → 7.** ¿Cómo cuentas los números `≤ N` divisibles por al menos uno de `k` números? 🟡

⏱️ **30 segundos.** Inclusión-exclusión sobre los subconjuntos de los `k` números: sumar `±⌊N / mcm(subconjunto)⌋` con signo según el tamaño.

🗣️ **2 minutos.** Los múltiplos comunes de un subconjunto son los múltiplos de su mcm. Con `k ≤ 20`, `10⁶` subconjuntos. El mcm se corta en cuanto pasa de `N` (aporta 0 y evita desbordar).

🔬 **El detalle.** Con 4 y 6 hasta 100: `25 + 16 − 8 = 33` (el mcm es 12, no 24).

**05 → 8.** Demuestra la fórmula de Catalan con el argumento de la reflexión. 🟠

⏱️ **30 segundos.** De los `C(2n, n)` caminos, los que bajan de 0 se reflejan desde el primer punto en `−1` y quedan en biyección con los caminos de `n + 1` bajadas y `n − 1` subidas: hay `C(2n, n + 1)`. Los buenos son la diferencia.

🗣️ **2 minutos.** Reflejar el tramo inicial hasta el primer `−1` (cambiando subidas por bajadas) es una biyección entre caminos malos y caminos que terminan en `−2`. Así `Cₙ = C(2n, n) − C(2n, n + 1) = C(2n, n)/(n + 1)`.

🔬 **El detalle.** La misma reflexión cuenta caminos que no tocan cualquier línea horizontal.

**05 → 9.** ¿Por qué un elemento que cumple `t` condiciones se cuenta una vez en la inclusión-exclusión? 🟠

⏱️ **30 segundos.** Porque aparece en `C(t, i)` intersecciones de tamaño `i`, con signo `(−1)^(i+1)`, y `Σ (−1)^(i+1) C(t, i) = 1` para `t ≥ 1`.

🗣️ **2 minutos.** Por el binomio, `Σ_{i=0}^{t} (−1)^i C(t, i) = (1 − 1)^t = 0`; quitando el término `i = 0` (que vale 1) y cambiando el signo, la suma de `i = 1` a `t` es 1.

🔬 **El detalle.** Un elemento que no cumple ninguna condición se cuenta 0 veces: de ahí la versión «ninguna = total − unión».

**05 → 10.** ¿Cómo cuentas repartos con máximos por caja? 🟠

⏱️ **30 segundos.** Inclusión-exclusión sobre el conjunto de cajas que se pasan: para cada subconjunto `S`, restar `(máx + 1)` a cada caja de `S` y contar con estrellas y barras, con signo `(−1)^|S|`.

🗣️ **2 minutos.** Forzar que una caja se pase de `m` es darle de entrada `m + 1`; las demás quedan libres. Con todas las cajas con el mismo máximo, el término depende solo de `|S|`: `Σ (−1)^j C(k, j) C(n − j(m + 1) + k − 1, k − 1)`.

🔬 **El detalle.** Es Distribute Candies Among Children II.

**05 → 11.** ¿Cuántos desarreglos de `n` hay y cómo se calcula? 🟠

⏱️ **30 segundos.** `D(n) = n! Σ_{i=0}^{n} (−1)^i / i!`, o la recurrencia `D(n) = (n − 1)(D(n − 1) + D(n − 2))` con `D(0) = 1`, `D(1) = 0`.

🗣️ **2 minutos.** Por inclusión-exclusión sobre los puntos fijos: fijar `i` puntos deja `(n − i)!` permutaciones. La recurrencia sale de dónde va el elemento `n` y si forma un intercambio. `D(4) = 9`, y `D(n)/n! → 1/e`.

🔬 **El detalle.** Es Christmas Party, con módulo.

**05 → 12.** ¿Cómo calculas `C(n, k)` módulo un número compuesto? 🔴

⏱️ **30 segundos.** Factorizando el módulo en potencias de primos, calculando módulo cada `pᵏ` (Lucas para `k = 1`, Granville o factoriales sin `p` para `k > 1`) y combinando con el TCR.

🗣️ **2 minutos.** Con `n` pequeño (hasta unos miles), el triángulo de Pascal no necesita divisiones y vale con cualquier módulo. Con `n` grande, hay que separar los factores `p` de los factoriales y contar su exponente aparte (Legendre).

🔬 **El detalle.** El exponente de `p` en `C(n, k)` es el número de acarreos al sumar `k` y `n − k` en base `p` (Kummer).

**05 → 13.** ¿Cuántos collares distintos de `n` cuentas con `k` colores hay salvo rotación? Justifica con Burnside. 🔴

⏱️ **30 segundos.** `(1/n) Σ_{i=0}^{n−1} k^gcd(i, n)`: el giro de `i` posiciones deja fijas las coloraciones constantes en sus `gcd(i, n)` ciclos.

🗣️ **2 minutos.** Burnside: el número de clases es la media de los puntos fijos sobre el grupo de rotaciones. El giro de `i` descompone las `n` posiciones en `gcd(i, n)` ciclos, y cada ciclo tiene que ser de un solo color. Para `n = 4`, `k = 2`: 6.

🔬 **El detalle.** Agrupando por `d = gcd(i, n)`: `(1/n) Σ_{d | n} φ(n/d) k^d`; la división por `n` módulo `p`, con el inverso.

**05 → Problema: Repartos con mínimos.**

**Pista 2:** resta los mínimos: quedan `r = n − Σ aᵢ` caramelos sin restricción, y la respuesta es `C(r + k − 1, k − 1)`.

**Pista 3:** si `r < 0`, 0; factoriales hasta `n + k`, que puede ser `2·10⁶`; la suma de mínimos en 64 bits.

**05 → Problema: Múltiplos de alguno.**

**Pista 2:** inclusión-exclusión sobre los subconjuntos con el mcm de cada uno.

**Pista 3:** corta el mcm en cuanto pase de `N` (sin desbordar: compara `l / g > N / x`); signo según el número de elementos.

**05 → Problema: Pulseras.**

**Pista 2:** Burnside con el grupo diédrico: los `n` giros (`k^gcd(i, n)`) y los `n` volteos.

**Pista 3:** con `n` impar, cada volteo fija `k^((n+1)/2)`; con `n` par, la mitad fijan `k^(n/2 + 1)` y la otra mitad `k^(n/2)`. Divide por `2n` con el inverso módulo `p`.

**05 → Problema: Pascal's Triangle.**

**Pista 2:** cada fila empieza y termina en 1, y el interior es la suma de los dos de arriba.

**Pista 3:** construye fila a fila a partir de la anterior.

**05 → Problema: Binomial Coefficients.**

**Pista 2:** factoriales e inversos hasta `10⁶`.

**Pista 3:** cada consulta, tres productos módulo `10⁹ + 7`; lectura y escritura rápidas.

**05 → Problema: Creating Strings II.**

**Pista 2:** el multinomial `n! / (c₁! c₂! … c₂₆!)` con las frecuencias de cada letra.

**Pista 3:** multiplica `n!` por los `invFact` de cada frecuencia.

**05 → Problema: Distributing Apples.**

**Pista 2:** estrellas y barras con `xᵢ ≥ 0`.

**Pista 3:** `C(m + n − 1, n − 1)` con factoriales hasta `2·10⁶`.

**05 → Problema: Unique Binary Search Trees.**

**Pista 2:** el número de árboles con `n` nodos es el Catalan `Cₙ`.

**Pista 3:** recurrencia `G(n) = Σ G(i − 1) G(n − i)` con `n ≤ 19`, o la fórmula cerrada sin módulo.

**05 → Problema: Christmas Party.**

**Pista 2:** desarreglos con la recurrencia `D(n) = (n − 1)(D(n − 1) + D(n − 2))`.

**Pista 3:** módulo `10⁹ + 7` en cada paso; `D(1) = 0`, `D(2) = 1`.

**05 → Problema: Bracket Sequences I.**

**Pista 2:** si `n` es impar, 0; si no, el Catalan `C_{n/2}`.

**Pista 3:** `C(n, n/2) − C(n, n/2 + 1)` con factoriales hasta `10⁶`.

**05 → Problema: Distribute Candies Among Children II.**

**Pista 2:** inclusión-exclusión sobre cuántos de los tres niños se pasan del límite.

**Pista 3:** `Σ_{j=0}^{3} (−1)^j C(3, j) C(n − j(limit + 1) + 2, 2)`, con 0 si el primer argumento es negativo.

**05 → Problema: Counting Necklaces.**

**Pista 2:** Burnside con las rotaciones: `(1/n) Σ m^gcd(i, n)`.

**Pista 3:** potencias rápidas y el inverso de `n` módulo `10⁹ + 7`.

**05 → Problema: Count Ways to Make Array With Product.**

**Pista 2:** factoriza `k`; cada primo con exponente `e` reparte ese exponente entre `n` posiciones: `C(e + n − 1, n − 1)`, y se multiplica sobre los primos.

**Pista 3:** factoriales hasta `n + 13` (el exponente máximo de `k ≤ 10⁴`); `10⁴` consultas.

**05 → Problema: Bracket Sequences II.**

**Pista 2:** valida el prefijo; si deja `d` abiertos y faltan `r` caracteres, cuenta los caminos de longitud `r` de `d` a 0 que no bajan de 0, por reflexión.

**Pista 3:** con `u = (r − d)/2` aperturas por poner, la respuesta es `C(r, u) − C(r, u − 1)`; 0 si `r − d` es impar o negativo.

**05 → Problema: Counting Grids.**

**Pista 2:** Burnside con los 4 giros de 90°: cuenta las órbitas de casillas de cada giro.

**Pista 3:** giro de 0°: `n²` casillas libres; de 180°: `⌈n²/2⌉`; de 90° y 270°: `⌈n²/4⌉`. La respuesta es `(2^(n²) + 2^⌈n²/2⌉ + 2 · 2^⌈n²/4⌉)/4` módulo `p`.

---

# 06 — Probabilidad y esperanza

**06 → 1.** ¿Qué dice la linealidad de la esperanza? 🟢

⏱️ **30 segundos.** `E[aX + bY] = a E[X] + b E[Y]` para cualesquiera variables, independientes o no.

🗣️ **2 minutos.** Permite calcular la esperanza de una suma pieza a pieza. Es lo que hace que «número esperado de…» se resuelva sin enumerar el espacio de resultados.

🔬 **El detalle.** Vale también para sumas infinitas de variables no negativas (convergencia monótona).

**06 → 2.** ¿Qué es una variable indicadora y cuál es su esperanza? 🟢

⏱️ **30 segundos.** Una variable que vale 1 si ocurre un suceso y 0 si no. Su esperanza es la probabilidad del suceso.

🗣️ **2 minutos.** Si una cantidad cuenta cuántos sucesos ocurren, es la suma de sus indicadoras, y su esperanza, la suma de las probabilidades. Es la forma de aplicar la linealidad a conteos.

🔬 **El detalle.** `𝟙_A · 𝟙_B = 𝟙_{A∩B}`: con productos de indicadoras se calculan varianzas.

**06 → 3.** ¿Cuántos puntos fijos tiene en promedio una permutación al azar? 🟢

⏱️ **30 segundos.** Uno, para cualquier `n`.

🗣️ **2 minutos.** La posición `i` es fija con probabilidad `1/n` (el valor `i` cae en ella); hay `n` posiciones; por linealidad, `n · 1/n = 1`. Los sucesos no son independientes, y da igual.

🔬 **El detalle.** La probabilidad de que no haya ninguno tiende a `1/e` (desarreglos, `17/05`).

**06 → 4.** ¿Cómo imprimes una esperanza `P/Q` módulo `p`? 🟡

⏱️ **30 segundos.** `P · Q⁻¹ mod p`, con el inverso por Fermat.

🗣️ **2 minutos.** Si la esperanza es una suma de fracciones, se trabaja módulo `p` desde el principio: cada fracción `a/b` es `a · b⁻¹`, y se suman. El enunciado garantiza que `Q` no es múltiplo de `p`.

🔬 **El detalle.** `(MOD + 1)/2` es el inverso de 2; útil para el `1/2` de los pares.

**06 → 5.** ¿Cuántas inversiones tiene en promedio una permutación al azar de `n` valores distintos? ¿Y con repetidos? 🟡

⏱️ **30 segundos.** `n(n − 1)/4` con valores distintos. Con repetidos, `(C(n, 2) − pares iguales)/2`.

🗣️ **2 minutos.** Cada par de valores distintos está invertido con probabilidad `1/2` por simetría; los pares de valores iguales nunca. En `[5, 2, 9, 1, 5, 6]`: `(15 − 1)/2 = 7`.

🔬 **El detalle.** Los pares iguales se cuentan por frecuencias: `Σ c(c − 1)/2`.

**06 → 6.** ¿Cuál es el número esperado de récords en una permutación al azar? 🟡

⏱️ **30 segundos.** `H(n) = 1 + 1/2 + … + 1/n`, que crece como `ln n`.

🗣️ **2 minutos.** El elemento en la posición `i` es récord si es el máximo de los `i` primeros, y por simetría eso ocurre con probabilidad `1/i`. Sumando las indicadoras, `H(n)`.

🔬 **El detalle.** Es también el número esperado de actualizaciones del máximo en un recorrido de un arreglo al azar.

**06 → 7.** ¿Cuántas tiradas hacen falta en promedio para ver todas las caras de un dado de `n` caras? 🟡

⏱️ **30 segundos.** `n H(n)`: con `n = 6`, `14,7`.

🗣️ **2 minutos.** Con `i` caras ya vistas, una tirada da una nueva con probabilidad `(n − i)/n`; el tiempo hasta la siguiente es geométrico con esperanza `n/(n − i)`. Sumando para `i = 0..n − 1`, `n (1/n + … + 1)`.

🔬 **El detalle.** Es el coleccionista de cupones; crece como `n ln n`.

**06 → 8.** Demuestra la linealidad de la esperanza y señala por qué no hace falta independencia. 🟠

⏱️ **30 segundos.** `E[X + Y] = Σ_ω (X(ω) + Y(ω)) P(ω)`, y se separa en dos sumas. Ningún paso usa que `X` e `Y` sean independientes.

🗣️ **2 minutos.** La esperanza es una suma ponderada sobre los resultados, y las sumas se reparten. La independencia aparece al calcular `E[XY]`, porque ahí hay que factorizar `P`.

🔬 **El detalle.** Para variables continuas, la misma prueba con integrales.

**06 → 9.** ¿Cuántas caras distintas se ven en promedio en `k` tiradas de un dado de `n` caras? 🟠

⏱️ **30 segundos.** `n (1 − ((n − 1)/n)^k)`.

🗣️ **2 minutos.** Indicadora por cara: la cara `j` aparece al menos una vez con probabilidad `1 − ((n − 1)/n)^k`. Con `n = 6` y `k = 3`, `91/36`.

🔬 **El detalle.** Con `k = n` grande, la proporción de caras vistas tiende a `1 − 1/e ≈ 0,63`.

**06 → 10.** ¿Por qué `E[XY] ≠ E[X]E[Y]` en general? Da un ejemplo. 🟠

⏱️ **30 segundos.** Porque `E[XY]` depende de cómo se relacionan `X` e `Y`. Con `Y = X` y `X` un dado: `E[X²] = 91/6 ≈ 15,17`, pero `E[X]² = 12,25`.

🗣️ **2 minutos.** La diferencia `E[XY] − E[X]E[Y]` es la covarianza; con independencia vale 0. La linealidad no tiene nada que ver con eso.

🔬 **El detalle.** Por eso la varianza de una suma necesita las covarianzas de los pares.

**06 → 11.** ¿Cómo calculas la esperanza de un máximo de variables enteras? 🔴

⏱️ **30 segundos.** Con `E[X] = Σ_{t ≥ 1} P(X ≥ t)` para variables enteras no negativas, y `P(max ≥ t) = 1 − P(todos < t)`.

🗣️ **2 minutos.** Si las variables son independientes, `P(todos < t)` es el producto. Por ejemplo, el máximo de `k` dados: `Σ_{t=1}^{6} (1 − ((t − 1)/6)^k)`.

🔬 **El detalle.** Es la forma de «linealizar» un máximo: indicadoras de «el máximo es al menos `t`».

**06 → 12.** ¿Cuándo la linealidad no basta y hace falta una DP de esperanza? 🔴

⏱️ **30 segundos.** Cuando la cantidad depende de un proceso con estado (hasta llegar a una casilla, con decisiones, con reinicios): ahí se plantea una ecuación por estado y se resuelve hacia atrás ([`13/04`](../13-dp-avanzada/04-probabilidad-y-esperanza.md)).

🗣️ **2 minutos.** La linealidad sigue usándose dentro (`E[pasos] = 1 + Σ p · E[siguiente]`), pero las esperanzas de los estados dependen unas de otras. Con ciclos, hace falta despejar o un sistema lineal ([`17/07`](07-matrices-y-gauss.md)).

🔬 **El detalle.** Con decisiones óptimas (parar o seguir), la ecuación lleva un `max` y deja de ser lineal.

**06 → Problema: Inversiones esperadas.**

**Pista 2:** cada par de valores distintos está invertido con probabilidad `1/2`; los iguales, nunca.

**Pista 3:** `(C(n, 2) − Σ c(c − 1)/2) · 2⁻¹` módulo `10⁹ + 7`, con las frecuencias de cada valor.

**06 → Problema: Caras distintas.**

**Pista 2:** indicadora por cara: aparece al menos una vez con probabilidad `1 − ((n − 1)/n)^k`.

**Pista 3:** `n · (1 − ((n − 1) · n⁻¹)^k)` módulo `p`, con exponenciación rápida para `k` hasta `10¹⁸`.

**06 → Problema: Airplane Seat Assignment Probability.**

**Pista 2:** por simetría, el último pasajero acaba en su asiento o en el del primero, con la misma probabilidad.

**Pista 3:** la respuesta es 1 para `n = 1` y `0,5` para `n ≥ 2`.

**06 → Problema: Journey.**

**Pista 2:** con `i` vértices visitados, el siguiente nuevo se alcanza en `N/(N − i)` operaciones en promedio.

**Pista 3:** suma `N/(N − i)` para `i = 1..N − 1` en `double`.

**06 → Problema: increment of coins.**

**Pista 2:** `E(a, b, c) = 1 + (a E(a+1, b, c) + b E(a, b+1, c) + c E(a, b, c+1))/(a + b + c)`, con `E = 0` si alguna llega a 100.

**Pista 3:** memoiza sobre `(a, b, c)` entre 0 y 100: `10⁶` estados.

**06 → Problema: Throwing the Die.**

**Pista 2:** `E_k` = valor esperado con `k` tiradas restantes jugando óptimo: en cada tirada, te quedas con el valor si supera `E_{k−1}`.

**Pista 3:** `E_1 = 3,5` y `E_k = Σ_{v=1}^{6} max(v, E_{k−1}) / 6`.

**06 → Problema: Critical Hit.**

**Pista 2:** `E[n] = 1 + p E[n − 2] + (1 − p) E[n − 1]`, con `p = P/100` como inverso módulo `998 244 353`.

**Pista 3:** casos base `E[0] = 0` y `E[1] = 1`; recorre `n` de 2 en adelante.

**06 → Problema: Sugoroku 3.**

**Pista 2:** desde la casilla `i`, el dado da `0..Aᵢ` pasos: el caso 0 te deja donde estás y aparece en tu propia ecuación.

**Pista 3:** despeja `E[i] = (1 + Σ_{j=1}^{Aᵢ} E[i + j]/(Aᵢ + 1)) · (Aᵢ + 1)/Aᵢ`, con sumas de sufijos módulo `998 244 353`.

**06 → Problema: Sugoroku 4.**

**Pista 2:** DP de probabilidad sobre `(tiradas hechas, casilla)`, con el rebote al pasarse de `N`.

**Pista 3:** `K · N · M` transiciones; las probabilidades como inversos de `M` módulo `998 244 353`.

**06 → Problema: Sugoroku2.**

**Pista 2:** escribe cada `E[i]` como `a_i + b_i · E[0]` (las casillas trampa devuelven a 0), recorriendo hacia atrás.

**Pista 3:** al final, `E[0] = a_0 + b_0 E[0]` da `E[0] = a_0 / (1 − b_0)`; si `b_0 ≈ 1` (no se puede ganar), `-1`. Sumas de ventana para no recorrer `M` casillas cada vez.

---

# 07 — Matrices y eliminación de Gauss

**07 → 1.** ¿Cuánto cuesta multiplicar dos matrices `n × n` y elevar una a la `k`? 🟢

⏱️ **30 segundos.** El producto, `Θ(n³)`. La potencia `Aᵏ`, `Θ(n³ log k)` con exponenciación binaria.

🗣️ **2 minutos.** Cada entrada del producto es una suma de `n` términos, y hay `n²` entradas. La potencia hace `O(log k)` productos por la asociatividad.

🔬 **El detalle.** Strassen (`O(n^2,81)`) y los algoritmos más rápidos no compensan en los tamaños de concurso.

**07 → 2.** ¿Qué operaciones de fila no cambian las soluciones de un sistema? 🟢

⏱️ **30 segundos.** Intercambiar dos filas, multiplicar una por un escalar no nulo y sumar a una fila un múltiplo de otra.

🗣️ **2 minutos.** Cada una es invertible y transforma ecuaciones en combinaciones de ecuaciones: el conjunto de soluciones no cambia. Gauss solo usa esas tres.

🔬 **El detalle.** Las mismas operaciones sobre columnas no conservan las soluciones (cambian las variables).

**07 → 3.** ¿Cómo sabes, al terminar Gauss, si el sistema no tiene solución? 🟢

⏱️ **30 segundos.** Si queda una fila con todos los coeficientes 0 y término independiente distinto de 0.

🗣️ **2 minutos.** Esa fila dice `0 = c`. Si no aparece ninguna, el sistema es compatible: con una solución si todas las columnas tienen pivote, con infinitas si hay columnas libres.

🔬 **El detalle.** Con `double`, «0» significa «menor que una tolerancia».

**07 → 4.** ¿Qué es el pivote parcial y por qué hace falta con `double`? 🟡

⏱️ **30 segundos.** Elegir como pivote, en cada columna, el elemento de mayor valor absoluto de las filas restantes. Con `double`, dividir por un pivote pequeño amplifica el error de redondeo.

🗣️ **2 minutos.** En `[[10⁻²⁰, 1], [1, 1]] x = [1, 2]`, sin pivote parcial el factor `10²⁰` destruye la segunda ecuación y sale `x₁ = 0`; con él, `x₁ ≈ x₂ ≈ 1`.

🔬 **El detalle.** Con aritmética modular o racional no hace falta: cualquier pivote no nulo es exacto.

**07 → 5.** ¿Cómo calculas el determinante con Gauss? 🟡

⏱️ **30 segundos.** Haciendo la eliminación y multiplicando los pivotes, con un cambio de signo por cada intercambio de filas.

🗣️ **2 minutos.** Sumar a una fila un múltiplo de otra no cambia el determinante; intercambiar filas lo cambia de signo; la matriz triangular final tiene como determinante el producto de su diagonal. Si alguna columna no tiene pivote, es 0.

🔬 **El detalle.** Módulo un número compuesto, se usa una variante con Euclides entre filas (sin divisiones).

**07 → 6.** ¿Cuántas soluciones tiene un sistema compatible sobre `GF(2)` con `m` incógnitas y rango `r`? 🟡

⏱️ **30 segundos.** `2^(m − r)`.

🗣️ **2 minutos.** Las `m − r` variables libres pueden tomar cualquier valor, y cada elección determina las demás. Sobre un cuerpo de `q` elementos, `q^(m − r)`.

🔬 **El detalle.** En el ejemplo de las luces, rango 2 con 3 interruptores: 2 formas.

**07 → 7.** ¿Por qué el orden `i-k-j` de los bucles es más rápido? 🟡

⏱️ **30 segundos.** Porque el bucle interior recorre una fila de `B` y una de `C` de forma contigua, aprovechando la caché.

🗣️ **2 minutos.** En `i-j-k`, el bucle interior recorre una **columna** de `B`, saltando una fila entera en cada paso. En `i-k-j`, `A[i][k]` queda fijo y se recorren filas: varias veces más rápido con matrices grandes.

🔬 **El detalle.** Saltarse `A[i][k] = 0` acelera además las matrices dispersas.

**07 → 8.** Da un sistema de 2 × 2 donde Gauss sin pivote parcial falla con `double`. 🟠

⏱️ **30 segundos.** `10⁻²⁰ x₁ + x₂ = 1`, `x₁ + x₂ = 2`. Sin intercambiar filas, se resta `10²⁰` veces la primera a la segunda y el redondeo da `x₁ = 0`; la solución es `x₁ ≈ x₂ ≈ 1`.

🗣️ **2 minutos.** El factor enorme hace que `1 − 10²⁰` y `2 − 10²⁰` se redondeen igual: se pierde la información de la segunda ecuación. Con el pivote 1 (la fila 2 primero), el factor es `10⁻²⁰` y todo va bien.

🔬 **El detalle.** Es el ejemplo clásico de por qué la estabilidad depende del pivote, no del algoritmo.

**07 → 9.** ¿Cómo calculas la inversa de una matriz? 🟠

⏱️ **30 segundos.** Gauss-Jordan sobre la matriz ampliada `[A | I]`: al terminar, si hay `n` pivotes, la parte derecha es `A⁻¹`.

🗣️ **2 minutos.** Las operaciones que llevan `A` a la identidad, aplicadas a `I`, la llevan a `A⁻¹`. `Θ(n³)`. Si falta algún pivote, `A` no es invertible (determinante 0).

🔬 **El detalle.** Para resolver muchos sistemas con la misma `A`, mejor la descomposición LU que la inversa.

**07 → 10.** ¿Cómo se usa Gauss para la esperanza de pasos en un paseo aleatorio con ciclos? 🟠

⏱️ **30 segundos.** Una ecuación por estado, `E[v] = 1 + Σ p(v, w) E[w]` (y `E[salida] = 0`), y resolver el sistema con Gauss.

🗣️ **2 minutos.** Con ciclos, las esperanzas dependen unas de otras en círculo y no hay un orden para calcularlas. El sistema tiene `n` incógnitas: `Θ(n³)`, bien con `n` de unos cientos. Módulo `p` si las probabilidades son fracciones.

🔬 **El detalle.** Con estructura (un solo ciclo, autolazos), se puede despejar sin Gauss (`13/04`).

**07 → 11.** ¿Qué relación hay entre Gauss sobre `GF(2)` y la base XOR de `17/01`? 🔴

⏱️ **30 segundos.** Son el mismo algoritmo: la base XOR inserta vectores de uno en uno y los reduce con los pivotes ya presentes; Gauss sobre `GF(2)` hace lo mismo con toda la matriz a la vez.

🗣️ **2 minutos.** El rango de la base es el rango de la matriz de los vectores; un vector se puede formar si al reducirlo queda 0, que es la compatibilidad del sistema. La base es la versión incremental.

🔬 **El detalle.** La base con pivotes por bit más alto es la forma escalonada de la matriz con columnas ordenadas de mayor a menor bit.

**07 → 12.** ¿Cómo resolverías un sistema módulo un número compuesto? 🔴

⏱️ **30 segundos.** Factorizando el módulo y resolviendo módulo cada potencia de primo, o con eliminación sin divisiones (Euclides entre filas) y TCR.

🗣️ **2 minutos.** Módulo un compuesto, los pivotes pueden no ser invertibles. Una técnica es eliminar con un algoritmo de Euclides entre dos filas (restando múltiplos hasta que una tenga 0 en la columna); otra, resolver módulo cada `pᵏ` y combinar.

🔬 **El detalle.** Library Checker tiene «Determinant of Matrix (Arbitrary Mod)» para practicar la variante de Euclides.

**07 → Problema: Sistema módulo p.**

**Pista 2:** Gauss-Jordan con inversos por Fermat; cualquier pivote no nulo.

**Pista 3:** reduce los coeficientes negativos módulo `p` al leer; al final, `NONE` si hay fila `0 … 0 | c ≠ 0`, `MANY` si falta algún pivote.

**07 → Problema: Apagar las luces.**

**Pista 2:** una ecuación por luz sobre `GF(2)`: la suma XOR de los interruptores que la conmutan es su estado inicial.

**Pista 3:** Gauss con filas en `bitset`; si es compatible, la respuesta es `2^(m − rango)` módulo `10⁹ + 7`, si no, 0.

**07 → Problema: Matrix Product.**

**Pista 2:** el producto con el orden `i-k-j` y módulo `998 244 353`.

**Pista 3:** acumula en 64 bits sin signo y reduce cada pocos productos para ahorrar módulos.

**07 → Problema: Pow of Matrix.**

**Pista 2:** exponenciación binaria de la matriz.

**Pista 3:** `k = 0` es la identidad; `log₂ 10¹⁸ ≈ 60` productos de `200³`.

**07 → Problema: Linear Equation Solver.**

**Pista 2:** Gauss con `double` y pivote parcial.

**Pista 3:** distingue `inconsistent` (fila `0 = c`) y `multiple` (variables libres) con una tolerancia; varios casos por entrada.

**07 → Problema: Determinant of Matrix.**

**Pista 2:** eliminación módulo `998 244 353`, producto de pivotes y signo por intercambio.

**Pista 3:** si una columna no tiene pivote, 0; inversos por Fermat.

**07 → Problema: Rank of Matrix.**

**Pista 2:** eliminación módulo `998 244 353` y contar pivotes.

**Pista 3:** la matriz puede ser rectangular: recorre columnas hasta agotar filas o columnas.

**07 → Problema: System of Linear Equations.**

**Pista 2:** Gauss-Jordan: una solución particular (libres a 0) y, por cada variable libre, un vector de la base del núcleo.

**Pista 3:** el vector de la libre `j` tiene 1 en `j` y, en cada variable pivote, el opuesto de su coeficiente en la columna `j`.

**07 → Problema: Partial Linear Equation Solver.**

**Pista 2:** tras Gauss-Jordan, una variable pivote está determinada si su fila no tiene coeficientes en columnas libres.

**Pista 3:** imprime su valor; las demás, `?`; si es incompatible, `inconsistent`.

**07 → Problema: Inverse Matrix.**

**Pista 2:** Gauss-Jordan sobre `[A | I]` módulo `998 244 353`.

**Pista 3:** si no hay `n` pivotes, `-1`.

**07 → Problema: System of Linear Equations (Mod 2).**

**Pista 2:** Gauss sobre `GF(2)` con filas en `bitset` o palabras de 64 bits.

**Pista 3:** además de una solución, la base del núcleo con una fila por variable libre; `n, m ≤ 4 096`.

---

# 08 — Teoría de juegos

**08 → 1.** ¿Qué es una posición P y una posición N? 🟢

⏱️ **30 segundos.** P: pierde quien mueve (todos sus movimientos llevan a N). N: gana quien mueve (algún movimiento lleva a P). Las finales son P con la regla normal.

🗣️ **2 minutos.** La definición es recursiva y se calcula hacia atrás sobre el DAG de estados. En el DAG D con una ficha, `F` es P, `D` y `E` son N, `B` y `C` son P y `A` es N.

🔬 **El detalle.** P viene de *previous player* (gana el que acaba de mover) y N de *next player*.

**08 → 2.** ¿Quién gana en Nim, según el teorema de Bouton? 🟢

⏱️ **30 segundos.** Gana quien empieza si y solo si el XOR de los montones es distinto de 0.

🗣️ **2 minutos.** Las posiciones con XOR 0 son P: cualquier movimiento rompe el 0, y desde XOR no nulo siempre hay un movimiento que lo devuelve a 0. Con `[5, 2, 9, 1, 5, 6]`, XOR 12: gana el primero.

🔬 **El detalle.** La suma de las piedras no decide nada.

**08 → 3.** ¿Qué es el mex y cómo se calcula el número de Grundy? 🟢

⏱️ **30 segundos.** `mex(S)` es el menor natural que no está en `S`. El Grundy de una posición es el mex de los Grundy de sus sucesores; las finales valen 0.

🗣️ **2 minutos.** Se calcula hacia atrás como P/N, pero con números: una posición vale 0 si y solo si es P. Para el juego de restar `{1, 3, 4}`: `0 1 0 1 2 3 2 0 …`.

🔬 **El detalle.** En Nim, el Grundy de un montón es su tamaño.

**08 → 4.** ¿Cómo encuentras la jugada ganadora en Nim? 🟡

⏱️ **30 segundos.** Con `s` = XOR de los montones, se busca un montón con `aᵢ ⊕ s < aᵢ` y se reduce a `aᵢ ⊕ s`.

🗣️ **2 minutos.** Cualquier montón que tenga encendido el bit más alto de `s` cumple la condición. Tras el movimiento, el XOR es `s ⊕ aᵢ ⊕ (aᵢ ⊕ s) = 0`. En el ejemplo, el 9 pasa a 5.

🔬 **El detalle.** Puede haber varios montones válidos; el número de jugadas ganadoras es el de montones con ese bit.

**08 → 5.** ¿Qué dice el teorema de Sprague-Grundy sobre la suma de juegos? 🟡

⏱️ **30 segundos.** Que una suma de juegos imparciales independientes tiene como número de Grundy el XOR de los de sus componentes; gana quien empieza si no es 0.

🗣️ **2 minutos.** Cada componente equivale a un montón de Nim de tamaño su Grundy. Así, varios montones con reglas distintas, varias fichas en un grafo o varios tableros se resuelven calculando el Grundy de cada uno por separado.

🔬 **El detalle.** El teorema exige que en cada turno se mueva en exactamente una componente.

**08 → 6.** ¿Por qué el número de Grundy está acotado por el número de movimientos? 🟡

⏱️ **30 segundos.** Porque el mex de un conjunto de `k` valores es como mucho `k`: el Grundy no supera el número de movimientos.

🗣️ **2 minutos.** Si hay `k` sucesores, entre `0` y `k` hay `k + 1` números y alguno falta. Por eso, para calcular el mex, basta un arreglo de vistos de tamaño `k + 1`.

🔬 **El detalle.** En juegos con pocos movimientos, los Grundy son pequeños y los patrones aparecen pronto.

**08 → 7.** ¿Qué cambia en Misère Nim? 🟡

⏱️ **30 segundos.** Que pierde quien hace el último movimiento. La estrategia es la de Nim salvo cuando todos los montones tienen una piedra: ahí gana quien empieza si el número de montones es par.

🗣️ **2 minutos.** Mientras haya un montón de más de una piedra, se juega como en Nim; el jugador ganador ajusta su último movimiento sobre ese montón para dejar un número impar de montones de 1 al rival.

🔬 **El detalle.** Las versiones misère de otros juegos no tienen una teoría tan limpia como Sprague-Grundy.

**08 → 8.** Demuestra el teorema de Bouton. 🟠

⏱️ **30 segundos.** La final tiene XOR 0; desde XOR 0 todo movimiento lo rompe (cambia un solo montón); desde XOR `s ≠ 0`, reducir el montón con el bit más alto de `s` a `aᵢ ⊕ s` lo deja en 0.

🗣️ **2 minutos.** Las posiciones con XOR 0 cumplen la definición de P (todo lleva a XOR no nulo) y las demás la de N (hay un movimiento a XOR 0). Como la clasificación P/N es única, coinciden.

🔬 **El detalle.** `aᵢ ⊕ s < aᵢ` porque el bit más alto de `s` está encendido en `aᵢ` y se apaga, y los de arriba no cambian.

**08 → 9.** Calcula los primeros números de Grundy del juego de restar `{1, 3, 4}` y di su periodo. 🟠

⏱️ **30 segundos.** `0 1 0 1 2 3 2 0 1 0 1 2 3 2 0 …`: periódico de periodo 7.

🗣️ **2 minutos.** `g(n) = mex{g(n−1), g(n−3), g(n−4)}`. A partir de `n = 7` se repite el bloque `0 1 0 1 2 3 2`. Con un periodo, el Grundy de un montón de `10¹⁸` es `g(n mod 7)`.

🔬 **El detalle.** Todo juego de restar con un conjunto finito es periódico a partir de algún punto, porque el estado relevante (los últimos `max S` valores) es finito.

**08 → 10.** ¿Cómo calculas el Grundy de un juego en el que un movimiento parte un montón en dos? 🟠

⏱️ **30 segundos.** El sucesor «partir en `a` y `b`» es la suma de dos juegos, y su Grundy es `g(a) ⊕ g(b)`. El Grundy del montón es el mex de esos XOR sobre todas las formas de partir.

🗣️ **2 minutos.** Es el caso de Grundy's Game (partir en dos montones distintos). Con `n` grande, se calcula hasta un límite y se usa el patrón observado.

🔬 **El detalle.** Si un movimiento quita y además parte (juegos de Kayles), los sucesores son XOR de las partes restantes.

**08 → 11.** ¿Qué haces si el juego puede tener ciclos y empates? 🔴

⏱️ **30 segundos.** Análisis retrógrado: desde las posiciones finales, propagar hacia atrás con un contador de sucesores no resueltos; lo que nunca se resuelve es empate.

🗣️ **2 minutos.** Una posición es ganadora si algún sucesor es perdedor; perdedora si todos sus sucesores son ganadores (el contador llega a 0). Con ciclos, las posiciones que no cumplen ninguna de las dos quedan en tablas.

🔬 **El detalle.** Es el algoritmo de Cat and Mouse ([`10/06`](../10-busqueda-completa-y-divide-y-venceras/06-juegos-y-busqueda-adversarial.md)) y de las bases de finales de ajedrez.

**08 → 12.** ¿Por qué Sprague-Grundy no sirve para juegos partisanos como el ajedrez? 🔴

⏱️ **30 segundos.** Porque en un juego partisano los dos jugadores tienen movimientos distintos: una posición no tiene un único conjunto de sucesores y no equivale a un montón de Nim.

🗣️ **2 minutos.** Para los partisanos existe la teoría de Conway (números surreales), mucho más compleja. En la práctica, los juegos partisanos de concurso se resuelven con minimax y poda (`10/06`).

🔬 **El detalle.** El ajedrez además puede tener ciclos y empates.

**08 → Problema: Nim con jugada.**

**Pista 2:** el XOR `s` de todos los montones; si es 0, `Second`.

**Pista 3:** el primer montón con `aᵢ ⊕ s < aᵢ` y su nuevo tamaño `aᵢ ⊕ s`; montones de hasta `10¹⁸` en 64 bits.

**08 → Problema: Restar de un conjunto.**

**Pista 2:** Grundy del juego de restar `S` para cada tamaño hasta el máximo, y XOR de los Grundy de los montones.

**Pista 3:** `g(n) = mex{g(n − s) : s ∈ S, s ≤ n}`, con el mex en un arreglo de `|S| + 1`; `10⁵ · 100 = 10⁷` operaciones.

**08 → Problema: Fichas en un DAG.**

**Pista 2:** Grundy de cada vértice por orden topológico inverso (mex de los Grundy de sus sucesores), y XOR sobre las fichas.

**Pista 3:** las fichas en el mismo vértice se cancelan por pares; con `10⁵` vértices, sin recursión.

**08 → Problema: Nim Game.**

**Pista 2:** las posiciones perdedoras son los múltiplos de 4.

**Pista 3:** `n % 4 != 0`.

**08 → Problema: Divisor Game.**

**Pista 2:** gana Alice si y solo si `n` es par.

**Pista 3:** desde par se puede restar 1 y dejar impar; desde impar, todo divisor es impar y se deja par.

**08 → Problema: Game of Stones.**

**Pista 2:** calcula P/N para los primeros valores con movimientos `{2, 3, 5}`.

**Pista 3:** las P son `n mod 7 ∈ {0, 1}`.

**08 → Problema: Stick Game.**

**Pista 2:** P/N hasta `n` con los movimientos del conjunto dado.

**Pista 3:** `dp[i]` = gana si algún `i − p` es perdedor; `n · k` operaciones.

**08 → Problema: Nim Game I.**

**Pista 2:** el XOR de los montones.

**Pista 3:** `first` si no es 0; varios casos por entrada.

**08 → Problema: Nim Game II.**

**Pista 2:** con movimientos `{1, 2, 3}`, el Grundy de un montón es `aᵢ mod 4`.

**Pista 3:** XOR de los `aᵢ mod 4`.

**08 → Problema: Stair Game.**

**Pista 2:** solo cuentan los escalones de posición par (con la numeración del enunciado): mover desde un escalón impar se puede deshacer.

**Pista 3:** XOR de los escalones que cuentan; si es 0, `second`.

**08 → Problema: Misère Nim.**

**Pista 2:** si todos los montones son 1, gana quien empieza si su número es par; si no, Nim normal.

**Pista 3:** comprueba primero si todos valen 1; si no, el XOR.

**08 → Problema: Poker Nim.**

**Pista 2:** añadir piedras no ayuda: el rival puede quitarlas; es Nim normal.

**Pista 3:** XOR de los montones; el límite de añadidos es irrelevante.

**08 → Problema: Chessboard Game, Again!.**

**Pista 2:** Grundy de cada casilla para una moneda (los movimientos van hacia la esquina) y XOR sobre las monedas.

**Pista 3:** tablero de `15 × 15`: tabla de 225 Grundy por memoización.

**08 → Problema: Grundy's Game.**

**Pista 2:** calcula el Grundy hasta unos miles: es 0 solo en unos pocos valores, y a partir de 1 222 nunca más.

**Pista 3:** para `n` grande, `first`; para los pequeños, la tabla calculada (partir en dos montones distintos).

**08 → Problema: Another Game.**

**Pista 2:** gana quien empieza si y solo si algún montón tiene un número impar de monedas.

**Pista 3:** si todos son pares, cualquier movimiento deja alguno impar y el rival puede devolverlos todos a pares.

**08 → Problema: Chalkboard XOR Game.**

**Pista 2:** si el XOR ya es 0, Alice gana; si no, gana si y solo si el número de elementos es par.

**Pista 3:** con un número par de elementos y XOR no nulo, siempre hay un número que se puede borrar sin dejar XOR 0.

---

# 09 — FFT y NTT

**09 → 1.** ¿Qué es la convolución de dos arreglos y qué tiene que ver con multiplicar polinomios? 🟢

⏱️ **30 segundos.** `c[s] = Σ a[i] · b[s − i]`: para cada `s`, la suma de los productos de los pares de índices que suman `s`. Son los coeficientes del producto `A(x) · B(x)`.

🗣️ **2 minutos.** El coeficiente de `xˢ` en el producto junta todos los pares de términos cuyos exponentes suman `s`. En `(1 + 2x + 3x²)(4 + 5x) = 4 + 13x + 22x² + 15x³`, el `13` es `1 · 5 + 2 · 4`.

🔬 **El detalle.** Contar sumas de pares, multiplicar números grandes y combinar distribuciones son convoluciones disfrazadas.

**09 → 2.** ¿Cuánto cuesta multiplicar dos polinomios de grado `n` de forma directa, con Karatsuba y con FFT? 🟢

⏱️ **30 segundos.** Directo, `Θ(n²)`; Karatsuba, `Θ(n^{1,585})`; FFT, `Θ(n log n)`.

🗣️ **2 minutos.** Con `n = 5·10⁵`: unos `2,5·10¹¹`, `10⁹` y `2·10⁷` pasos. Karatsuba ya es subcuadrático; la FFT baja hasta casi lineal.

🔬 **El detalle.** La FFT tiene una constante mayor: con unos miles de coeficientes, la cuenta directa suele ganar.

**09 → 3.** ¿Cuáles son los tres pasos de la multiplicación por FFT? 🟢

⏱️ **30 segundos.** Evaluar `A` y `B` en `N` raíces de la unidad, multiplicar los valores punto a punto e interpolar con la transformada inversa.

🗣️ **2 minutos.** `N` es una potencia de 2 con `N ≥ n + m − 1`. La evaluación y la interpolación son FFT de `Θ(N log N)`; el producto punto a punto, `Θ(N)`.

🔬 **El detalle.** Son tres transformadas: dos de ida y una de vuelta.

**09 → 4.** ¿Por qué el producto de dos polinomios de grado `< n` necesita una transformada de tamaño `≥ 2n − 1`? 🟢

⏱️ **30 segundos.** El producto tiene grado `2n − 2`, es decir `2n − 1` coeficientes, y un polinomio con `k` coeficientes necesita `k` puntos para quedar determinado.

🗣️ **2 minutos.** Con menos puntos, la transformada calcula la convolución **cíclica**: los coeficientes de grado `≥ N` se suman a los de grado `− N` (se «enrollan»), y el resultado sale mal sin ningún aviso.

🔬 **El detalle.** En la práctica se redondea a la potencia de 2 siguiente a `n + m − 1`.

**09 → 5.** ¿Qué propiedad de las raíces de la unidad hace que la FFT sea `Θ(N log N)`? 🟡

⏱️ **30 segundos.** Los cuadrados de las raíces `N`-ésimas son las raíces `N/2`-ésimas: evaluar en `N` puntos se reduce a dos evaluaciones de la mitad de tamaño en `N/2` puntos.

🗣️ **2 minutos.** Con `A(x) = A_par(x²) + x · A_impar(x²)` y `ω^{k + N/2} = −ω^k`, cada par de valores de las mitades da dos valores del total (la «mariposa»). `T(N) = 2 T(N/2) + Θ(N) = Θ(N log N)`.

🔬 **El detalle.** Por eso la versión básica exige que `N` sea potencia de 2.

**09 → 6.** ¿Cómo se calcula la transformada inversa? 🟡

⏱️ **30 segundos.** Con la misma FFT, usando `ω⁻¹` en lugar de `ω`, y dividiendo el resultado entre `N`.

🗣️ **2 minutos.** La matriz de evaluación en las raíces (de Vandermonde) tiene como inversa la de entradas `ω^{−jk} / N`. En el ejemplo del capítulo, el término independiente es `(54 − 18 − 2i − 2 − 18 + 2i) / 4 = 4`.

🔬 **El detalle.** En la NTT, dividir entre `N` es multiplicar por el inverso de `N` módulo `p`.

**09 → 7.** ¿Por qué 998 244 353 sirve para la NTT y `10⁹ + 7` no? 🟡

⏱️ **30 segundos.** `998 244 353 − 1 = 119 · 2²³`: hay raíces de la unidad de orden `2ᵏ` hasta `k = 23`. `10⁹ + 7 − 1 = 2 · 500 000 003`: solo de orden 2.

🗣️ **2 minutos.** En `ℤ_p` hay raíces `N`-ésimas de la unidad si y solo si `N` divide a `p − 1`; la NTT con potencias de 2 necesita un factor `2ᵏ` grande. Con la raíz primitiva `3`, `ω = 3^{(p−1)/N} mod p`.

🔬 **El detalle.** Otros primos de la misma familia: `167 772 161 = 5 · 2²⁵ + 1` y `469 762 049 = 7 · 2²⁶ + 1`, también con raíz primitiva 3.

**09 → 8.** ¿Cuándo da un resultado incorrecto la FFT con `double` al multiplicar enteros? 🟠

⏱️ **30 segundos.** Cuando los coeficientes del producto son tan grandes que el error de redondeo llega a `0,5`: con `10⁶` coeficientes aleatorios, los primeros fallos aparecen hacia `6·10¹⁴`.

🗣️ **2 minutos.** La medición del capítulo: con `10⁶` coeficientes, productos de `2,5·10¹³` dan un error de `0,02`; de `2·10¹⁴`, `0,19`; de `2,5·10¹⁵`, más de 2, con cerca de la mitad de los coeficientes mal. El fallo es silencioso: no hay excepción, solo números equivocados.

🔬 **El detalle.** Se evita partiendo cada valor en dos mitades de unos 15 bits y combinando varios productos, o con NTT y el teorema chino.

**09 → 9.** ¿Cómo haces una convolución módulo `10⁹ + 7` de arreglos de `10⁵`? 🟠

⏱️ **30 segundos.** Tres NTT con tres primos amigables y reconstruir cada coeficiente con el teorema chino del resto; o una FFT con los valores partidos en mitades.

🗣️ **2 minutos.** Sin reducir, un coeficiente vale como mucho `10⁵ · (10⁹)² = 10²³`. Tres primos de unos 30 bits tienen producto de unos `10²⁶`, mayor que eso: el chino recupera el valor exacto, que después se reduce módulo `10⁹ + 7`.

🔬 **El detalle.** La reconstrucción se hace con el método de Garner para no salir de 64 bits.

**09 → 10.** Te piden, para cada `s`, cuántos pares `(i, j)` cumplen `a[i] + b[j] = s`, con `n = 10⁵` y valores `≤ 10⁵`. ¿Qué haces? 🟠

⏱️ **30 segundos.** Histogramas de los valores y una convolución de los dos histogramas por FFT, de tamaño `2·10⁵`.

🗣️ **2 minutos.** `c[s] = Σ_v cnt_a[v] · cnt_b[s − v]` es exactamente la convolución de los histogramas. Directo, `10¹⁰`; con FFT, unos `4·10⁶`. Los coeficientes valen como mucho `10¹⁰`, que el `double` redondea bien.

🔬 **El detalle.** Si los valores fueran pequeños (unos miles), bastaría la convolución directa de los histogramas.

**09 → 11.** ¿Cómo multiplicas dos números de `10⁶` cifras decimales con una FFT? 🔴

⏱️ **30 segundos.** Cifras como coeficientes de un polinomio en `x = 10`, convolución por FFT y propagación de acarreos.

🗣️ **2 minutos.** Cada coeficiente del producto vale como mucho `81 · 10⁶ ≈ 8·10⁷`, muy por debajo del límite del `double`. Agrupando tres cifras por coeficiente (base `10³`), `N` se divide entre 3 y los coeficientes llegan a unos `3·10¹¹`, todavía seguros.

🔬 **El detalle.** Con bloques de 4 cifras los coeficientes llegan a `2,5·10¹³`: entra, pero sin margen.

**09 → 12.** ¿Cómo cuentas, para cada desplazamiento, cuántas letras coinciden entre un texto y un patrón? 🔴

⏱️ **30 segundos.** Una convolución por letra: el indicador de la letra en el texto con el indicador en el patrón invertido; se suman las 26.

🗣️ **2 minutos.** Invertir el patrón convierte la correlación `Σ_j T[i + j] · P[j]` en una convolución. Son 26 FFT de tamaño `|T| + |P|`, frente a `|T| · |P|` comparaciones.

🔬 **El detalle.** Con comodines, `Σ_j P[j] · T[i + j] · (P[j] − T[i + j])²` vale 0 exactamente donde el patrón encaja: tres convoluciones.

**09 → Problema: Todas las sumas.**

**Pista 2:** los histogramas de las dos listas (`cnt[v]` para `v ≤ m`); la respuesta para `s` es `Σ cnt_a[v] · cnt_b[s − v]`.

**Pista 3:** dos bucles sobre los valores: `(m + 1)² ≈ 4·10⁶` operaciones; los conteos llegan a `10¹⁰`, en 64 bits.

**09 → Problema: Producto de gigantes.**

**Pista 2:** la convolución de las cifras, de menor a mayor peso, y la propagación de los acarreos; o la biblioteca: `BigInteger` en Java, `int` en Python.

**Pista 3:** en Python, `sys.set_int_max_str_digits(0)` antes de leer y de imprimir; en C++, FFT con bloques de 3 cifras, imprimiendo los ceros de relleno de cada bloque salvo el primero.

**09 → Problema: Convolution.**

**Pista 2:** NTT con `p = 998 244 353` y raíz primitiva 3.

**Pista 3:** tamaño potencia de 2 `≥ n + m − 1`; la inversa con `ω⁻¹` y multiplicando por `N⁻¹ mod p`.

**09 → Problema: Convolution (Mod 1,000,000,007).**

**Pista 2:** tres NTT con `998 244 353`, `167 772 161` y `469 762 049`, y el chino del resto para cada coeficiente.

**Pista 3:** Garner para reconstruir sin pasar de 64 bits, reduciendo módulo `10⁹ + 7` al final.

**09 → Problema: Convolution (Large).**

**Pista 2:** parte cada polinomio en bloques que quepan en `2²²` y convoluciona los pares de bloques, sumando cada producto desplazado.

**Pista 3:** transforma cada bloque una sola vez y suma los productos en el dominio transformado: así haces `Θ(k)` transformadas en lugar de `Θ(k²)`.

**09 → Problema: Bitwise Xor Convolution.**

**Pista 2:** la transformada de Walsh-Hadamard: para cada bit, el par `(u, v)` pasa a `(u + v, u − v)`.

**Pista 3:** transforma los dos arreglos, multiplica punto a punto, transforma otra vez y divide entre `2ⁿ` (multiplicando por su inverso módulo `p`).


---

# 10 — Teoría de números avanzada

**10 → 1.** ¿Qué es una función multiplicativa? Da tres ejemplos. 🟢

⏱️ **30 segundos.** Una con `f(1) = 1` y `f(ab) = f(a) f(b)` cuando `gcd(a, b) = 1`. Ejemplos: `φ`, el número de divisores, la suma de divisores y `μ`.

🗣️ **2 minutos.** Basta conocerla en las potencias de primos: `φ(pᵏ) = pᵏ − pᵏ⁻¹`, `d(pᵏ) = k + 1`. Con la factorización de `n`, se multiplica; con la criba lineal, salen todas hasta `n` en `Θ(n)`.

🔬 **El detalle.** Es **completamente** multiplicativa si vale para todo par: `id` lo es; `φ` no (`φ(4) = 2`, pero `φ(2)² = 1`).

**10 → 2.** ¿Cuánto vale `μ(n)`? 🟢

⏱️ **30 segundos.** `1` si `n = 1`; `0` si `n` tiene un primo al cuadrado; `(−1)ᵏ` si es producto de `k` primos distintos.

🗣️ **2 minutos.** De 1 a 12: `1, −1, −1, 0, −1, 1, −1, 0, 0, 1, −1, 0`. Por ejemplo, `μ(6) = 1` (dos primos), `μ(12) = 0` (tiene `2²`).

🔬 **El detalle.** `Σ_{d | n} μ(d)` vale 1 para `n = 1` y 0 en el resto: es la inclusión-exclusión sobre los primos de `n`.

**10 → 3.** ¿Qué es una raíz primitiva módulo un primo? 🟢

⏱️ **30 segundos.** Un `g` cuyas potencias recorren todos los residuos no nulos módulo `p`; su orden es `p − 1`.

🗣️ **2 minutos.** Módulo 7, las potencias de 3 son `1, 3, 2, 6, 4, 5`: es raíz primitiva. También lo es 5. Siempre existe módulo un primo.

🔬 **El detalle.** Módulo `p` hay exactamente `φ(p − 1)` raíces primitivas: 2 módulo 7, 8 módulo 17.

**10 → 4.** ¿Qué es la convolución de Dirichlet y cuál es su neutro? 🟡

⏱️ **30 segundos.** `(f * g)(n) = Σ_{d | n} f(d) · g(n/d)`. Su neutro es `ε`, que vale 1 en `n = 1` y 0 en el resto.

🗣️ **2 minutos.** Es conmutativa y asociativa, y la convolución de dos multiplicativas es multiplicativa. Identidades útiles: `φ * 1 = id`, `μ * 1 = ε`, `1 * 1 = d`.

🔬 **El detalle.** Toda `f` con `f(1) ≠ 0` tiene inversa para esta convolución; `μ` es la inversa de la constante 1.

**10 → 5.** ¿Qué dice la inversión de Möbius? 🟡

⏱️ **30 segundos.** `g(n) = Σ_{d | n} f(d)` si y solo si `f(n) = Σ_{d | n} μ(d) · g(n/d)`: `g = f * 1` equivale a `f = g * μ`.

🗣️ **2 minutos.** Se demuestra convolucionando con `μ`: `g * μ = f * 1 * μ = f * ε = f`. Sirve para despejar una función de sus sumas sobre divisores.

🔬 **El detalle.** Hay una versión sobre múltiplos: si `g(n) = Σ_{n | m} f(m)`, entonces `f(n) = Σ_{n | m} μ(m/n) · g(m)`.

**10 → 6.** ¿Cuántas cadenas binarias primitivas de longitud 6 hay, y cómo lo calculas? 🟡

⏱️ **30 segundos.** 54: `Σ_{d | 6} μ(d) · 2^{6/d} = 64 − 8 − 4 + 2`.

🗣️ **2 minutos.** Cada cadena de longitud 6 es la repetición de exactamente una primitiva de longitud `d | 6`, así que `2⁶ = Σ_{d | 6} P(d)`. La inversión de Möbius despeja `P(6)`. Comprobación: `P(1) + P(2) + P(3) + P(6) = 2 + 2 + 6 + 54 = 64`.

🔬 **El detalle.** Las cadenas primitivas vienen en grupos de 6 rotaciones distintas: hay `54 / 6 = 9` collares aperiódicos (palabras de Lyndon) de longitud 6.

**10 → 7.** ¿Cómo funciona *baby-step giant-step* y cuánto cuesta? 🟠

⏱️ **30 segundos.** Con `s = ⌈√m⌉` se escribe `x = i·s − j`; se guarda `b · aʲ` para `j < s` y se buscan coincidencias con `a^{i·s}`. `Θ(√m)`.

🗣️ **2 minutos.** En `3ˣ ≡ 13 (mod 17)`, `s = 5`: los pasos de bebé dan `13, 5, 15, 11, 16`; el primer paso de gigante, `3⁵ ≡ 5`, coincide con `j = 1`, y `x = 5 − 1 = 4`. Necesita `gcd(a, m) = 1` para poder cancelar `aʲ`.

🔬 **El detalle.** Para el **menor** `x`, se recorre `i` de menor a mayor y la tabla guarda, para cada valor, el mayor `j`.

**10 → 8.** ¿Cómo compruebas si `g` es raíz primitiva módulo `p` sin calcular todas sus potencias? 🟠

⏱️ **30 segundos.** Se factoriza `p − 1` y se comprueba que `g^{(p−1)/q} ≢ 1 (mod p)` para cada primo `q` que divide a `p − 1`.

🗣️ **2 minutos.** El orden de `g` divide a `p − 1`; si no es `p − 1`, divide a algún `(p − 1)/q`, y esa potencia daría 1. Con `3` módulo 7: `p − 1 = 6`, `3³ ≡ 6` y `3² ≡ 2`, ninguno 1: es raíz primitiva.

🔬 **El detalle.** Son tantas exponenciaciones como primos distintos tenga `p − 1`, unos pocos.

**10 → 9.** ¿Por qué el logaritmo discreto no es como el real? 🟠

⏱️ **30 segundos.** Porque `aˣ mod p` no es monótono ni continuo: no hay búsqueda binaria ni aproximación posible.

🗣️ **2 minutos.** Las potencias de 3 módulo 17 son `1, 3, 9, 10, 13, 5, 15, 11, 16, 14, …`: saltan sin orden. No se conoce un algoritmo polinómico general, y criptosistemas como Diffie-Hellman se apoyan en esa dificultad.

🔬 **El detalle.** Puede no tener solución, o tener infinitas: si `x` sirve, también `x` más cualquier múltiplo del orden de `a`.

**10 → 10.** ¿Cómo calculas `Σ_{i=1}^{n} gcd(i, n)` sin calcular `n` `gcd`? 🟠

⏱️ **30 segundos.** `Σ_{d | n} d · φ(n/d)`, que con `n = 12` da 40.

🗣️ **2 minutos.** Se agrupan los `i` por `d = gcd(i, n)`: son `i = d · k` con `k ≤ n/d` y `gcd(k, n/d) = 1`, es decir `φ(n/d)` valores. Es `(id * φ)(n)`, multiplicativa: basta calcularla en las potencias de primos de `n`.

🔬 **El detalle.** El coste es el de factorizar `n`: `Θ(√n)` por división de prueba.

**10 → 11.** ¿Cómo resuelves `xᵏ ≡ a (mod p)` con una raíz primitiva? 🔴

⏱️ **30 segundos.** Con una raíz primitiva `g`: `x = gʸ` y `a = gᵗ` (logaritmo discreto), y la ecuación queda `k·y ≡ t (mod p − 1)`, una congruencia lineal.

🗣️ **2 minutos.** Tiene solución si y solo si `gcd(k, p − 1)` divide a `t`, y entonces tiene `gcd(k, p − 1)` soluciones. Se resuelve con Euclides extendido ([`17/02`](02-divisibilidad.md)).

🔬 **El detalle.** El coste lo domina el logaritmo discreto: `Θ(√p)`.

**10 → 12.** ¿Cómo calcularías `Σ_{i ≤ n} φ(i)` con `n = 10¹⁰`? 🔴

⏱️ **30 segundos.** Con el método de Dirichlet por bloques: `φ * 1 = id` relaciona la suma de prefijo de `φ` con sus valores en los `⌊n/k⌋`, que son `Θ(√n)` distintos.

🗣️ **2 minutos.** Se calcula recursivamente sobre esos valores, con memoización, agrupando los `k` que dan el mismo `⌊n/k⌋`. Cribando de antemano `φ` hasta `n^{2/3}` (unos `2·10⁶` para `10¹⁰`), el total es `Θ(n^{2/3})`.

🔬 **El detalle.** Con `n ≤ 10⁷` basta la criba lineal y una suma; la técnica solo hace falta cuando la criba hasta `n` no cabe.

**10 → Problema: Pares coprimos.**

**Pista 2:** los pares con los dos elementos múltiplos de `d` son `⌊n/d⌋²`; Möbius da los de `gcd` exactamente 1: `Σ_d μ(d) · ⌊n/d⌋²`. O con `φ`: `2 · Σ_{k ≤ n} φ(k) − 1`.

**Pista 3:** criba lineal de `μ` o de `φ` hasta `10⁷`; la respuesta llega a unos `6·10¹³`: 64 bits.

**10 → Problema: El orden de un elemento.**

**Pista 2:** el orden divide a `p − 1`: factoriza `p − 1` y, partiendo de `k = p − 1`, divide `k` entre cada primo `q` mientras `a^{k/q} ≡ 1`.

**Pista 3:** división de prueba hasta `√p ≈ 31 623` por consulta; exponenciación rápida con productos en 64 bits.

**10 → Problema: Primitive Root.**

**Pista 2:** factoriza `p − 1` con Miller-Rabin y Pollard rho ([`17/04`](04-primos.md)) y prueba candidatos `g = 2, 3, …` con la condición de los `(p − 1)/q`.

**Pista 3:** productos de 64 × 64 bits con `__int128` o `Math.multiplyHigh`; los candidatos pequeños aciertan pronto en la práctica.

**10 → Problema: Sum of Totient Function.**

**Pista 2:** sumando `φ * 1 = id` para todos los `n ≤ N`: `Σ_{k=1}^{N} Φ(⌊N/k⌋) = N(N + 1)/2`, con `Φ` la suma de prefijo de `φ`.

**Pista 3:** despeja `Φ(N)`, recorre por bloques los `k` con el mismo `⌊N/k⌋`, memoiza y criba `φ` hasta `N^{2/3}`; cuidado con `N(N + 1)/2` módulo 998 244 353.

**10 → Problema: Counting Square-free Integers.**

**Pista 2:** `Σ_{d ≤ √n} μ(d) · ⌊n/d²⌋`.

**Pista 3:** con `n = 10¹⁸`, `√n = 10⁹` no cabe en una criba: agrupa los `d` con el mismo `⌊n/d²⌋` y usa sumas de prefijo de `μ` (la función de Mertens) por Dirichlet.

**10 → Problema: Squarefree Numbers.**

**Pista 2:** `Σ_{d ≤ 2²⁵} μ(d) · ⌊2⁵⁰/d²⌋`.

**Pista 3:** criba de `μ` hasta `2²⁵ ≈ 3,4·10⁷`, con un byte por valor para no gastar memoria.

**10 → Problema: Gcd Sum.**

**Pista 2:** agrupando por el valor del `gcd`: `Σ_d d · Φ(⌊N/d⌋)`, con `Φ` la suma de prefijo de `φ`.

**Pista 3:** `N = 10¹¹`: `Φ` por Dirichlet por bloques y la suma exterior agrupada por bloques de `⌊N/d⌋`; módulo 998 244 353.


---

# 11 — Funciones generadoras y Berlekamp-Massey

**11 → 1.** ¿Qué es la función generadora de una sucesión? 🟢

⏱️ **30 segundos.** La serie formal `G(x) = Σ aₙ xⁿ`, que guarda la sucesión en sus coeficientes.

🗣️ **2 minutos.** No se evalúa en ningún `x` ni importa si converge: es una forma de manipular la sucesión entera. Sumar, desplazar o multiplicar la serie mueve todos los términos a la vez.

🔬 **El detalle.** Para objetos etiquetados (permutaciones, grafos con vértices numerados) se usa la exponencial, `Σ aₙ xⁿ / n!`.

**11 → 2.** ¿Qué operación sobre sucesiones corresponde a multiplicar dos funciones generadoras? 🟢

⏱️ **30 segundos.** La convolución: `[xⁿ] F · G = Σ fᵢ g_{n−i}`.

🗣️ **2 minutos.** Es «elegir de dos grupos independientes con tamaño total `n`»: el producto de las series del primer y el segundo grupo cuenta las combinaciones.

🔬 **El detalle.** Por eso la NTT de [`17/09`](09-fft-y-ntt.md) es la herramienta para multiplicar series largas.

**11 → 3.** ¿Cuál es la función generadora de la sucesión constante 1, y la de `cⁿ`? 🟢

⏱️ **30 segundos.** `1/(1 − x)` para la constante 1, y `1/(1 − c·x)` para `cⁿ`.

🗣️ **2 minutos.** `(1 − x)(1 + x + x² + …) = 1`: los términos se cancelan de dos en dos. Con `c·x` en lugar de `x`, el término `n` es `cⁿ`.

🔬 **El detalle.** `1/(1 − x)ᵏ` da `C(n + k − 1, k − 1)`: las formas de repartir `n` en `k` grupos.

**11 → 4.** ¿Qué hace Berlekamp-Massey? 🟢

⏱️ **30 segundos.** A partir de los primeros términos de una sucesión, encuentra la recurrencia lineal más corta que los genera.

🗣️ **2 minutos.** Trabaja sobre un cuerpo, en concursos los enteros módulo un primo, en `Θ(N²)` para `N` términos. Con `1, 1, 3, 5, 11, 21` devuelve `aₙ = aₙ₋₁ + 2aₙ₋₂`.

🔬 **El detalle.** Nació para decodificar códigos BCH y sintetizar registros de desplazamiento lineales.

**11 → 5.** ¿Por qué la función generadora de una recurrencia lineal es una fracción de polinomios? 🟡

⏱️ **30 segundos.** Porque al multiplicar `G` por `Q(x) = 1 − c₁x − … − c_k xᵏ` se anulan todos los coeficientes desde el `k`: queda un polinomio `P` de grado `< k`, y `G = P/Q`.

🗣️ **2 minutos.** El coeficiente `n ≥ k` de `G · Q` es `aₙ − c₁aₙ₋₁ − … − c_k aₙ₋ₖ`, que la recurrencia hace 0. Factorizando `Q` y separando en fracciones simples sale la forma cerrada.

🔬 **El detalle.** Al revés también: toda `P/Q` con `Q(0) = 1` es la serie de una sucesión que cumple una recurrencia lineal.

**11 → 6.** ¿De cuántas formas se paga `n` con monedas de 1 y de 2, según su función generadora? 🟡

⏱️ **30 segundos.** `⌊n/2⌋ + 1`: el coeficiente de `xⁿ` en `1 / ((1 − x)(1 − x²))`.

🗣️ **2 minutos.** Las monedas de 1 aportan `1/(1 − x)` y las de 2, `1/(1 − x²)`. Directamente: se elige cuántas de 2 (de 0 a `⌊n/2⌋`) y el resto se paga con monedas de 1.

🔬 **El detalle.** La DP de la mochila «de cuántas formas» hace la misma multiplicación de series, un factor cada vez.

**11 → 7.** ¿Cuántos términos necesita Berlekamp-Massey para encontrar una recurrencia de orden `k`? 🟡

⏱️ **30 segundos.** `2k`.

🗣️ **2 minutos.** Con menos, varias recurrencias de orden `k` explican los términos dados; con `2k`, la más corta es única si existe alguna de orden `≤ k`.

🔬 **El detalle.** En la práctica se dan algunos términos de margen y se comprueba que el orden obtenido queda claramente por debajo de `N/2`.

**11 → 8.** ¿Cómo calculas el término `10¹⁸` de una sucesión de la que solo sabes calcular los primeros 1 000? 🟠

⏱️ **30 segundos.** Con Berlekamp-Massey sobre los 1 000 términos (módulo un primo) para obtener la recurrencia, y Kitamasa o la matriz de [`13/06`](../13-dp-avanzada/06-recurrencias-lineales-y-matrices.md) para el término `10¹⁸`.

🗣️ **2 minutos.** Solo funciona si la sucesión cumple alguna recurrencia lineal de orden `≤ 500`; una DP lineal con pocos estados lo garantiza. Hay que comprobar que el orden encontrado es pequeño.

🔬 **El detalle.** El coste: `Θ(N²) = 10⁶` para la recurrencia y `Θ(k² log n)` para el término.

**11 → 9.** ¿Qué pasa si aplicas Berlekamp-Massey a una sucesión que no cumple ninguna recurrencia lineal corta? 🟠

⏱️ **30 segundos.** Devuelve una recurrencia de orden cercano a `N/2` que encaja con los `N` términos y no predice nada.

🗣️ **2 minutos.** Por eso un orden `≈ N/2` es una señal de alarma: o faltan términos, o la sucesión no es lineal. Se comprueba con términos extra.

🔬 **El detalle.** Los primos o el número de particiones no cumplen ninguna recurrencia lineal de coeficientes constantes.

**11 → 10.** Obtén la forma cerrada de `aₙ = aₙ₋₁ + 2aₙ₋₂` con `a₀ = a₁ = 1`. 🔴

⏱️ **30 segundos.** `aₙ = (2ⁿ⁺¹ + (−1)ⁿ) / 3`.

🗣️ **2 minutos.** `Q(x) = 1 − x − 2x² = (1 − 2x)(1 + x)` y `P(x) = 1`. Fracciones simples: `1 = A(1 + x) + B(1 − 2x)`; con `x = −1`, `B = 1/3`; con `x = 1/2`, `A = 2/3`. Cada `1/(1 − c·x)` aporta `cⁿ`: `(2/3)·2ⁿ + (1/3)(−1)ⁿ`.

🔬 **El detalle.** Comprobación: `a₁₀ = (2 048 + 1)/3 = 683`, y la recurrencia da `1, 1, 3, 5, 11, 21, 43, 85, 171, 341, 683`.

**11 → 11.** ¿Por qué Kitamasa es más rápido que la exponenciación de matrices? 🔴

⏱️ **30 segundos.** Porque trabaja con polinomios de grado `< k` en lugar de matrices `k × k`: cada paso cuesta `Θ(k²)` y no `Θ(k³)`.

🗣️ **2 minutos.** `aₙ` es combinación lineal de `a₀ … a_{k−1}` con los coeficientes de `xⁿ` módulo el polinomio característico. `xⁿ` se calcula por exponenciación rápida reduciendo en cada paso: `log n` pasos de `Θ(k²)`.

🔬 **El detalle.** Con NTT, cada paso baja a `Θ(k log k)`; el algoritmo de Bostan-Mori hace lo mismo directamente sobre `P/Q`.

**11 → Problema: Dados.**

**Pista 2:** un dado es el polinomio `x + x² + … + x⁶`; la respuesta es el coeficiente de `xˢ` en su potencia `n`.

**Pista 3:** multiplica `n` veces como DP: `dp[i][t] = Σ_{f=1}^{6} dp[i−1][t−f]`, `6 · n · s ≈ 3,6·10⁷`; con sumas de prefijo, `n · s`.

**11 → Problema: La regla escondida.**

**Pista 2:** Berlekamp-Massey sobre los `2k` términos; sin él, prueba órdenes `r = 1, 2, …` y resuelve por Gauss módulo `p` los `r` coeficientes, quedándote con el menor `r` que reproduce todos los términos.

**Pista 3:** si `n < 2k`, imprime el término dado; si no, Kitamasa o la matriz `r × r` (`r ≤ 10`) elevada a la `n`.

**11 → Problema: Find Linear Recurrence.**

**Pista 2:** Berlekamp-Massey módulo 998 244 353, directo.

**Pista 3:** imprime el orden y los coeficientes con el signo que pide el enunciado; `Θ(N²)` entra.

**11 → Problema: Kth term of Linearly Recurrent Sequence.**

**Pista 2:** con `G = P/Q`, el método de Bostan-Mori: multiplicar arriba y abajo por `Q(−x)` deja abajo una serie en `x²`, y el coeficiente `N` pasa a ser el `⌊N/2⌋` de un problema del mismo tamaño.

**Pista 3:** `log N` pasos con dos productos de polinomios de grado `d`; con `d` grande, por NTT.

**11 → Problema: Inv of Formal Power Series.**

**Pista 2:** Newton: si `g` es la inversa módulo `xᵐ`, `g · (2 − f · g)` es la inversa módulo `x²ᵐ`.

**Pista 3:** duplica `m` desde 1 con productos por NTT; el total es `Θ(n log n)`.

**11 → Problema: Partition Function.**

**Pista 2:** el teorema de los números pentagonales: `Π (1 − xᵏ) = Σ_{k ∈ ℤ} (−1)ᵏ x^{k(3k−1)/2}`, con solo `Θ(√n)` términos no nulos.

**Pista 3:** invierte esa serie con Newton y NTT, o usa la recurrencia de Euler que sale de ella, `Θ(n√n)`.


---

# 12 — Simulación

**12 → S1.** ¿Cómo compruebas con una sola operación de bits si `n > 0` es potencia de 2? 🟢

⏱️ **30 segundos.** `(n & (n − 1)) == 0`.

🗣️ **2 minutos.** Una potencia de 2 tiene un solo bit encendido; `n & (n − 1)` apaga el más bajo y deja 0 solo si no había otro.

🔬 **El detalle.** `n = 0` también pasa la prueba: por eso el enunciado pide `n > 0`.

**12 → S2.** ¿Por qué `gcd(a, b) = gcd(b, a mod b)`, y cuántos pasos da Euclides? 🟢

⏱️ **30 segundos.** Porque `a mod b = a − q·b`: los divisores comunes de `a` y `b` son los mismos que los de `b` y `a mod b`. Euclides da `O(log min(a, b))` pasos.

🗣️ **2 minutos.** Cada dos pasos el menor de los dos números se reduce al menos a la mitad. El peor caso son dos Fibonacci consecutivos (teorema de Lamé): unos 90 pasos para números de 64 bits.

🔬 **El detalle.** Euclides extendido devuelve además `x, y` con `a·x + b·y = gcd(a, b)`.

**12 → S3.** ¿Cómo calculas `a⁻¹ mod p` con `p` primo? 🟢

⏱️ **30 segundos.** Con el pequeño teorema de Fermat: `a⁻¹ ≡ a^{p−2} (mod p)`, por exponenciación rápida en `Θ(log p)`.

🗣️ **2 minutos.** Vale para `a` no múltiplo de `p`. Euclides extendido también lo da, y sirve además para módulos compuestos cuando `gcd(a, m) = 1`.

🔬 **El detalle.** Para muchos inversos seguidos (`1 … n`) hay una recurrencia lineal que evita `n` exponenciaciones.

**12 → S4.** ¿Cuánto cuesta la criba hasta `n`, y factorizar `q` números con la criba del menor factor primo? 🟡

⏱️ **30 segundos.** La criba de Eratóstenes, `Θ(n log log n)` (la lineal, `Θ(n)`). Con el menor factor primo precalculado, cada número se factoriza en tantos pasos como factores tenga: `O(log x)`.

🗣️ **2 minutos.** Total para `q` números hasta `n`: `Θ(n log log n + q log n)`. Sin la criba, la división de prueba costaría `Θ(√x)` por número.

🔬 **El detalle.** La tabla del menor factor primo hasta `10⁷` ocupa 40 MB en `int`: hay que comprobar que cabe.

**12 → S5.** ¿Cómo respondes muchas consultas de `C(n, k) mod p` con `n ≤ 10⁶`? 🟡

⏱️ **30 segundos.** Precalculando factoriales y factoriales inversos hasta `n`; cada consulta es `n! · (k!)⁻¹ · ((n − k)!)⁻¹`, `O(1)`.

🗣️ **2 minutos.** Los inversos se obtienen con una sola exponenciación (la de `n!`) y bajando: `((i − 1)!)⁻¹ = (i!)⁻¹ · i`. Total `Θ(n + log p)` de preparación.

🔬 **El detalle.** Exige `p` primo y mayor que `n`; si no, Lucas o el chino del resto.

**12 → S6.** ¿Qué dice la linealidad de la esperanza, y por qué no exige independencia? 🟢

⏱️ **30 segundos.** `E[X + Y] = E[X] + E[Y]`, siempre.

🗣️ **2 minutos.** La esperanza es una suma ponderada por probabilidades, y la suma se puede reordenar sin mirar cómo dependen las variables. De ahí el truco de los indicadores: el número esperado de cosas es la suma de sus probabilidades.

🔬 **El detalle.** Para el producto, `E[XY] = E[X] E[Y]`, sí hace falta independencia.

**12 → S7.** ¿Cuántos intentos se esperan hasta el primer éxito, si cada uno sale bien con probabilidad `p`? 🟢

⏱️ **30 segundos.** `1/p`.

🗣️ **2 minutos.** Con `E` intentos esperados: se gasta uno, y con probabilidad `1 − p` se vuelve a empezar, `E = 1 + (1 − p) E`, de donde `E = 1/p`.

🔬 **El detalle.** Sacar un 6 con un dado lleva 6 tiradas de media.

**12 → S8.** ¿Qué hace la eliminación de Gauss y cuánto cuesta? 🟡

⏱️ **30 segundos.** Lleva un sistema lineal a forma triangular con operaciones de fila; resuelve sistemas, calcula rango, determinante e inversa, en `Θ(n³)`.

🗣️ **2 minutos.** Módulo un primo es exacta; con `double` hace falta pivote parcial y épsilon; módulo 2, con *bitsets*, `Θ(n³/64)`.

🔬 **El detalle.** Con `n = 500` son `10⁸` operaciones: el límite práctico.

**12 → S9.** ¿Cuándo gana quien empieza en una suma de juegos imparciales? 🟡

⏱️ **30 segundos.** Si el XOR de los números de Grundy de las componentes no es 0 (teorema de Sprague-Grundy).

🗣️ **2 minutos.** Cada componente equivale a un montón de Nim de su número de Grundy; la suma de juegos es un Nim con esos montones.

🔬 **El detalle.** El teorema exige que en cada turno se mueva en exactamente una componente.

**12 → S10.** ¿Qué es una convolución y cuándo se calcula en `Θ(n log n)`? 🟡

⏱️ **30 segundos.** `c[s] = Σ a[i] · b[s − i]`, el producto de dos polinomios. Con FFT o NTT sale en `Θ(n log n)`.

🗣️ **2 minutos.** Compensa con tamaños de `10⁴`–`10⁵` o más; por debajo, dos bucles. Con valores pequeños, la convolución de histogramas puede bastar.

🔬 **El detalle.** Módulo 998 244 353, NTT exacta; con `double`, solo mientras los coeficientes queden lejos de `2⁵³`.

**12 → S11.** Tu `a * b % m` da negativo en Java, con `a, b < m = 10⁹ + 7`. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** `a` y `b` son `int`: el producto desborda 32 bits antes del `%` y da un número negativo.

🗣️ **2 minutos.** Con residuos menores que `10⁹ + 7`, el producto llega a `10¹⁸`, que cabe en `long`: `(long) a * b % m`. El *cast* va antes de multiplicar, no después.

🔬 **El detalle.** Con módulos cercanos a `10¹⁸` ni `long` basta: `Math.multiplyHigh`, `__int128` o `BigInteger`.

**12 → S12.** «Para dividir módulo `m`, divido y después tomo el módulo.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que no funciona: la división entera no respeta el módulo. Se multiplica por el inverso de `b`, que existe si `gcd(b, m) = 1`.

🗣️ **2 minutos.** Ejemplo: `6 / 3 = 2`. Módulo 5, `6 ≡ 1` y `1 / 3` entero es 0, no 2; con el inverso, `1 · 3⁻¹ ≡ 1 · 2 = 2`.

🔬 **El detalle.** Si `b` no tiene inverso módulo `m`, hay que cambiar de enfoque (dividir antes de reducir, o factorizar).

**12 → S13.** Hay que decir si un único `n ≤ 10¹²` es primo y alguien propone una criba hasta `n`. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que no: una criba hasta `10¹²` no cabe en memoria ni en tiempo. Con una sola consulta, división de prueba hasta `√n = 10⁶`.

🗣️ **2 minutos.** Un millón de divisiones es instantáneo. La criba compensa cuando hay muchas consultas sobre números pequeños.

🔬 **El detalle.** Para `n` hasta `10¹⁸`, Miller-Rabin determinista con bases fijas.

**12 → S14.** «`-7 % 3` da lo mismo en Python que en Java.» ¿Es cierto, y qué haces para no depender de ello? 🟠

⏱️ **30 segundos.** No: Python da `2` (el signo del divisor) y Java `−1` (el del dividendo, como C++).

🗣️ **2 minutos.** Para no depender de ello: `((x % m) + m) % m`, o `Math.floorMod(x, m)` en Java. En Python, `%` ya da un resultado no negativo con `m > 0`.

🔬 **El detalle.** La división entera tiene la misma diferencia: Python redondea hacia abajo y Java y C++ hacia cero.

**12 → S15.** Tu Gauss con `double` dice que un sistema de enteros no tiene solución, y sí la tiene. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** Errores de redondeo: un pivote que debería ser 0 sale `10⁻¹⁷` (o al revés) y se compara con 0 exacto.

🗣️ **2 minutos.** Con `double`: pivote parcial (el de mayor valor absoluto) y un épsilon para decidir qué es 0. Con coeficientes enteros, mejor trabajar módulo un primo grande o con fracciones exactas.

🔬 **El detalle.** «Gauss con `double` es exacto» es justo lo que desmonta `17/07`.

**12 → S16.** «Para saber quién gana hay que simular todas las partidas.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que no hace falta: las posiciones ganadoras y perdedoras se calculan una vez por estado, hacia atrás, no por partida.

🗣️ **2 minutos.** Con Sprague-Grundy, cada componente por separado y un XOR. En Nim, ni eso: el XOR de los montones decide.

🔬 **El detalle.** El número de partidas crece exponencialmente; el de estados, a menudo, no.

**12 → S17.** Un problema pide una probabilidad «como `P · Q⁻¹ mod 998 244 353`». ¿Por qué ese formato, y cómo trabajas con él? 🟠

⏱️ **30 segundos.** Porque la probabilidad `P/Q` puede tener numerador y denominador enormes; el formato pide el elemento de `ℤ_p` que representa la fracción, único si `Q` no es múltiplo de `p`.

🗣️ **2 minutos.** Se trabaja todo módulo `p`: sumas y productos normales, y cada división como multiplicación por el inverso. El resultado coincide con reducir la fracción exacta al final.

🔬 **El detalle.** En ese formato no se pueden comparar probabilidades: `ℤ_p` no tiene orden.

**12 → S18.** Calculas `C(n, k) mod m` con factoriales e inversos y falla con `m = 10⁶`. ¿Por qué? 🟠

⏱️ **30 segundos.** Porque `10⁶` no es primo: los factoriales comparten factores con `m` y sus inversos no existen.

🗣️ **2 minutos.** Además, `k!` es múltiplo de `10⁶` para todo `k ≥ 25`. Alternativas: el triángulo de Pascal si `n` es pequeño; si no, factorizar `m`, calcular módulo cada potencia de primo y juntar con el chino del resto.

🔬 **El detalle.** Con `m` primo pero menor que `n`, el teorema de Lucas.

**12 → S19.** Demuestra que dejar el XOR de los montones en 0 es una estrategia ganadora en Nim. 🔴

⏱️ **30 segundos.** Desde XOR 0, todo movimiento deja XOR distinto de 0; desde XOR `s ≠ 0`, siempre hay un movimiento que lo deja en 0. Quien deja 0 nunca se queda sin movimiento.

🗣️ **2 minutos.** (1) Cambiar un montón cambia su valor, y por tanto el XOR: de 0 pasa a algo no nulo. (2) Con `s ≠ 0`, un montón con el bit más alto de `s` encendido cumple `aᵢ ⊕ s < aᵢ`; reducirlo a `aᵢ ⊕ s` deja XOR 0. (3) La posición final, todo a 0, tiene XOR 0: la alcanza quien juega la estrategia, y el rival se queda sin movimiento.

🔬 **El detalle.** El juego termina porque cada movimiento quita al menos una piedra: no hay ciclos.

**12 → S20.** Una DP de 5 estados con transiciones lineales da la respuesta; piden el término `10¹⁸` y escribir la matriz a mano es incómodo. ¿Qué haces? 🔴

⏱️ **30 segundos.** Calcular los primeros términos con la DP, sacar la recurrencia con Berlekamp-Massey módulo un primo, y el término `10¹⁸` con Kitamasa o con la matriz de la recurrencia encontrada.

🗣️ **2 minutos.** Una DP lineal de 5 estados cumple una recurrencia de orden `≤ 5`: bastan 10 términos, y se calculan unos 30 por margen. Si el orden sale mayor que 5, algo está mal.

🔬 **El detalle.** Todo en `Θ(N²)` para la recurrencia y `Θ(k² log n)` para el término.

**12 → Problema: Fracciones elevadas.**

**Pista 2:** reduce `a` y `b` módulo `p` antes de nada; la respuesta es `(a mod p)ᶜ · ((b mod p)^{p−2})ᶜ`, o `(a · b⁻¹)ᶜ`.

**Pista 3:** si `a` es múltiplo de `p`, el resultado es 0 (salvo `c = 0`, que da 1); los productos de residuos caben en 64 bits.

**12 → Problema: El factor más grande.**

**Pista 2:** criba del menor factor primo hasta `10⁷` y factorizar cada número dividiendo por él.

**Pista 3:** el último primo que sale es el mayor; los distintos se cuentan al cambiar de primo. La tabla en `int` ocupa 40 MB; lectura rápida para `10⁶` números.

**12 → Problema: Fichas que se acercan.**

**Pista 2:** el hueco `r − l − 1` de cada fila es un montón de Nim: cualquier movimiento lo reduce en una cantidad cualquiera `≥ 1`.

**Pista 3:** XOR de los huecos; `first` si no es 0.

**12 → Problema: La mesa del banquete.**

**Pista 2:** busca el mayor `d ≤ √n` que divide a `n`, bajando desde `⌊√n⌋`; el perímetro `2(d + n/d)` es menor cuanto más cerca de `√n` está `d`.

**Pista 3:** raíz entera exacta (no `sqrt` en `double` sin corregir); como mucho `31 623` divisiones.

**12 → Problema: Distinct Prime Factors of Product of Array.**

**Pista 2:** factoriza cada elemento (`≤ 1 000`) por división de prueba y guarda los primos en un conjunto.

**Pista 3:** la respuesta es el tamaño del conjunto; no hace falta el producto.

**12 → Problema: Nimble Game.**

**Pista 2:** una moneda en la casilla `i` es un montón de Nim de tamaño `i`.

**Pista 3:** XOR de los `i` cuyo número de monedas es impar; `First` si no es 0.

**12 → Problema: Ugly Number III.**

**Pista 2:** búsqueda binaria sobre `x` con el conteo por inclusión-exclusión: `⌊x/a⌋ + ⌊x/b⌋ + ⌊x/c⌋ − ⌊x/mcm(a,b)⌋ − ⌊x/mcm(a,c)⌋ − ⌊x/mcm(b,c)⌋ + ⌊x/mcm(a,b,c)⌋`.

**Pista 3:** el menor `x` con conteo `≥ n`; los `mcm` en 64 bits.

**12 → Problema: Prime Multiples.**

**Pista 2:** inclusión-exclusión sobre los `2ᵏ` subconjuntos de primos: `⌊n / producto⌋` con signo según el tamaño.

**Pista 3:** el producto puede desbordar: deja de multiplicar en cuanto supere `n` (comprueba con una división antes de multiplicar).

**12 → Problema: Counting Coprime Pairs.**

**Pista 2:** `cnt[d]` = cuántos números son múltiplos de `d`; los pares con `gcd` múltiplo de `d` son `C(cnt[d], 2)`, y Möbius da los de `gcd` 1: `Σ_d μ(d) · C(cnt[d], 2)`.

**Pista 3:** `cnt[d]` recorriendo los múltiplos de cada `d`, `Θ(V log V)` con `V = 10⁶`; `μ` con la criba.

