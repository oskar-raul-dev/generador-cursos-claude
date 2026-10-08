# 17 — Pistas

> Las pistas 2 y 3 de todos los problemas del bloque `21`: la técnica y el diseño, sin código. Se miran **al
> terminar** el simulacro, nunca durante. La pista 1 está en cada simulacro.
>
> **Qué está comprobado.** Las de los cuatro simulacros en vivo, contra una solución de referencia. Las de
> los problemas externos se escribieron leyendo su enunciado, con el enlace y el nombre comprobados, pero sin
> resolver cada problema en su plataforma: si una pista no lleva a la solución, manda el enunciado.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--simulacro-de-empresa-1) · [02](#02--simulacro-de-empresa-2) · [03](#03--simulacro-de-empresa-3) · [04](#04--simulacro-de-empresa-4) · [05](#05--simulacro-de-empresa-5) · [06](#06--simulacro-de-empresa-en-codility-1) · [07](#07--simulacro-de-empresa-en-codility-2) · [08](#08--simulacro-de-empresa-en-codility-3) · [09](#09--simulacro-en-vivo-1-ventas-por-hora) · [10](#10--simulacro-en-vivo-2-el-hueco-para-la-reunión) · [11](#11--simulacro-en-vivo-3-orden-de-compilación) · [12](#12--simulacro-en-vivo-4-el-tope-de-las-ayudas) · [13](#13--simulacro-de-concurso-1) · [14](#14--simulacro-de-concurso-2) · [15](#15--simulacro-de-concurso-3) · [16](#16--simulacro-de-concurso-4)

---

## 01 — Simulacro de empresa 1

**01 → Problema: Jumping on the Clouds.**

**Pista 2:** voraz: salta dos si se puede, si no, uno.

**Pista 3:** un recorrido contando saltos; el enunciado garantiza que siempre hay camino.

**01 → Problema: Repeated String.**

**Pista 2:** aes de `s` por el número de repeticiones completas, más las del prefijo que sobra.

**Pista 3:** `(n / |s|) · cuenta(s) + cuenta(s[0, n mod |s|))`, en 64 bits.

**01 → Problema: Non-overlapping Intervals.**

**Pista 2:** el voraz de selección de actividades: ordenar por final.

**Pista 3:** conserva un intervalo si empieza en o después del final del último conservado; la respuesta es lo que se descarta.


---

## 02 — Simulacro de empresa 2

**02 → Problema: New Year Chaos.**

**Pista 2:** cuenta, para cada persona, cuántos de número mayor tiene delante, mirando solo desde dos posiciones antes de su sitio original.

**Pista 3:** si alguien avanzó más de dos puestos, `Too chaotic`; si no, suma los mayores en `q[max(0, q[i] − 2) .. i − 1]`, `O(n)` en total.

**02 → Problema: Simplify Path.**

**Pista 2:** una pila de nombres de carpeta.

**Pista 3:** ignora `""` y `.`; `..` desapila si hay algo; el resto se apila; une con `/` y empieza por `/`.

**02 → Problema: Fraudulent Activity Notifications.**

**Pista 2:** ventana deslizante con un arreglo de 201 cuentas.

**Pista 3:** la mediana recorriendo las cuentas (dos posiciones si `d` es par); compara `gasto ≥ 2 · mediana` en enteros, sin decimales.


---

## 03 — Simulacro de empresa 3

**03 → Problema: Hand of Straights.**

**Pista 2:** voraz desde la carta menor con un mapa ordenado de cuentas.

**Pista 3:** mientras queden cartas, toma la menor `x` y resta una a `x, x + 1, …, x + groupSize − 1`; si falta alguna, falso.

**03 → Problema: Minimum Swaps 2.**

**Pista 2:** los ciclos de la permutación: un ciclo de longitud `L` necesita `L − 1` intercambios.

**Pista 3:** recorre cada ciclo marcando visitados y suma `L − 1`; `O(n)`.

**03 → Problema: LRU Cache.**

**Pista 2:** un mapa de clave a nodo y una lista doblemente enlazada por orden de uso.

**Pista 3:** `get` mueve el nodo al frente; `put` inserta al frente y, si se pasa de capacidad, quita el del final; en Java, `LinkedHashMap` con orden de acceso y `removeEldestEntry`.


---

## 04 — Simulacro de empresa 4

**04 → Problema: Climbing the Leaderboard.**

**Pista 2:** ranking denso sin duplicados y búsqueda binaria (o dos punteros, porque las puntuaciones de la jugadora crecen).

**Pista 3:** el puesto es el número de puntuaciones distintas mayores más uno; con dos punteros desde el final, `O(n + m)`.

**04 → Problema: Basic Calculator II.**

**Pista 2:** una pila de sumandos: `*` y `/` operan con la cima; `+` y `−` apilan.

**Pista 3:** una pasada con el último operador visto; la división trunca hacia cero; al final, suma la pila.

**04 → Problema: Special String Again.**

**Pista 2:** compresión en bloques (letra, longitud).

**Pista 3:** cada bloque de longitud `L` aporta `L(L + 1)/2`; cada bloque de longitud 1 entre dos bloques de la misma letra aporta `min(izquierdo, derecho)`.


---

## 05 — Simulacro de empresa 5

**05 → Problema: Palindromic Substrings.**

**Pista 2:** expandir desde cada uno de los `2n − 1` centros.

**Pista 3:** mientras los extremos coincidan, cuenta uno y expande; `O(n²)` con `n ≤ 1 000`; Manacher lo haría lineal.

**05 → Problema: Max Array Sum.**

**Pista 2:** DP lineal de «tomar o no tomar» sin elementos vecinos.

**Pista 3:** `dp[i] = max(dp[i − 1], dp[i − 2] + a[i], a[i])`; cuidado con los negativos según lo que permita el enunciado.

**05 → Problema: Split Array Largest Sum.**

**Pista 2:** búsqueda binaria sobre la respuesta con un voraz que cuenta trozos.

**Pista 3:** el máximo está entre `max(a)` y `suma(a)`; el voraz corta en cuanto el trozo se pasaría; la respuesta es el menor máximo con como mucho `k` trozos.


---

## 06 — Simulacro de empresa en Codility 1

**06 → Problema: Brackets.**

**Pista 2:** una pila de aperturas.

**Pista 3:** cada cierre tiene que casar con la cima; al final, la pila vacía; la cadena vacía está bien anidada.

**06 → Problema: Two Strings.**

**Pista 2:** basta una letra en común.

**Pista 3:** un conjunto (o 26 bits) con las letras de una y mirar las de la otra; `O(|s₁| + |s₂|)`.

**06 → Problema: Valid Parenthesis String.**

**Pista 2:** llevar el mínimo y el máximo de abiertos posibles.

**Pista 3:** `(` sube los dos; `)` baja los dos; `*` baja el mínimo y sube el máximo; el mínimo no baja de 0; si el máximo es negativo, falso; al final, mínimo 0.


---

## 07 — Simulacro de empresa en Codility 2

**07 → Problema: MaxNonoverlappingSegments.**

**Pista 2:** el voraz de selección de actividades.

**Pista 3:** elige un segmento si empieza después del final del último elegido; con 0 segmentos, 0.

**07 → Problema: Hash Tables: Ransom Note.**

**Pista 2:** un mapa de cuentas de las palabras de la revista.

**Pista 3:** resta cada palabra de la nota; si alguna cuenta queda negativa, `No`.

**07 → Problema: Multiply Strings.**

**Pista 2:** la multiplicación escolar sobre arreglos de cifras.

**Pista 3:** `res[i + j + 1] += a[i] · b[j]` y acarreos al final; quita los ceros de delante; si queda vacío, `"0"`.


---

## 08 — Simulacro de empresa en Codility 3

**08 → Problema: Flags.**

**Pista 2:** los picos, y probar cada `k` hasta `√N` saltando de pico en pico.

**Pista 3:** precalcula el siguiente pico de cada posición; para cada `k`, coloca banderas con saltos de al menos `k`; el máximo `k` que coloca `k` banderas; `O(N)`.

**08 → Problema: Minimum Absolute Difference in an Array.**

**Pista 2:** ordenar: el mínimo está entre vecinos.

**Pista 3:** una pasada por los vecinos; `O(n log n)`.

**08 → Problema: Search in Rotated Sorted Array II.**

**Pista 2:** binaria que decide qué mitad está ordenada.

**Pista 3:** si `nums[lo] = nums[mid] = nums[hi]`, avanza `lo` y retrocede `hi`: el peor caso es `O(n)` con muchos repetidos.


---

## 09 — Simulacro en vivo 1: Ventas por hora

**09 → Problema: Ventas por hora.**

**Pista 2:** un mapa de hora (`HH`) a total en céntimos, y ordenar las claves al final.

**Pista 3:** parte cada importe por el punto en euros y céntimos; imprime `total / 100` y `total % 100` a dos cifras; las horas sin ventas no salen.


---

## 10 — Simulacro en vivo 2: El hueco para la reunión

**10 → Problema: El hueco para la reunión.**

**Pista 2:** mezclar las dos listas ordenadas y fusionar los intervalos solapados; los huecos entre ellos son los tiempos libres comunes.

**Pista 3:** todo en minutos; recorre los intervalos fusionados con el «último final» empezando en `09:00`; el primer hueco de al menos `d` minutos (incluido el último, hasta `17:00`) es la respuesta; dos punteros, `O(a + b)`.


---

## 11 — Simulacro en vivo 3: Orden de compilación

**11 → Problema: Orden de compilación.**

**Pista 2:** orden topológico de Kahn con una cola de prioridad en lugar de una cola normal.

**Pista 3:** grado de entrada de cada módulo; empieza con los de grado 0 en un *heap* por nombre; al sacar uno, baja el grado de los que dependen de él; si al final no salieron todos, hay un ciclo. `O((n + m) log n)`.


---

## 12 — Simulacro en vivo 4: El tope de las ayudas

**12 → Problema: El tope de las ayudas.**

**Pista 2:** búsqueda binaria sobre el tope: el total es creciente en `C`.

**Pista 3:** rango `[0, max(r)]`; el total con el tope es `Σ min(rᵢ, C)` en 64 bits; o, ordenando y con prefijos, el tope exacto en `O(n log n)` sin binaria.


---

## 13 — Simulacro de concurso 1

**13 → Problema: A - N-choice question.**

**Pista 2:** buscar la opción igual a `A + B`.

**Pista 3:** imprime su índice desde 1.

**13 → Problema: B - Same Map in the RPG World.**

**Pista 2:** probar todos los desplazamientos `(s, t)`.

**Pista 3:** `30 · 30` desplazamientos por `900` comparaciones; índices `(i + s) mod H` y `(j + t) mod W`.

**13 → Problema: C - Cross.**

**Pista 2:** para cada posible centro, medir el brazo diagonal más corto.

**Pista 3:** el tamaño de la cruz es el mínimo de las cuatro longitudes; cuenta las de tamaño `≥ 1` por tamaño.

**13 → Problema: D - AABCC.**

**Pista 2:** criba de primos hasta `10⁶` y tres bucles que cortan en cuanto se pasan.

**Pista 3:** para `a < b < c`, corta `b` cuando `a² · b³ > N` y `c` cuando `a² · b · c² > N`; productos en 64 bits sin desbordar.

**13 → Problema: E - Dice Product 3.**

**Pista 2:** condicionar a que no sale 1: cada uno de 2–6 con probabilidad `1/5`.

**Pista 3:** memoización sobre los divisores de `N` de la forma `2ᵃ3ᵇ5ᶜ` (si `N` tiene otro primo, 0): `f(N) = 1`, `f(x) = (1/5) Σ_{d=2..6} f(x·d)`; módulo con el inverso de 5.


---

## 14 — Simulacro de concurso 2

**14 → Problema: A - Leyland Number.**

**Pista 2:** potencias directas.

**Pista 3:** `A^B + B^A` en 64 bits.

**14 → Problema: B - Longest Palindrome.**

**Pista 2:** probar todas las subcadenas.

**Pista 3:** `O(n³)` con `n = 100`, comprobando cada una.

**14 → Problema: C - Slot Strategy 2 (Easy).**

**Pista 2:** fuerza bruta sobre los tres instantes distintos en `[0, 3M)`.

**Pista 3:** para cada terna de instantes distintos con el mismo símbolo en los tres rodillos, el máximo; el mínimo de esos máximos; `(3M)³` combinaciones.

**14 → Problema: D - Relative Position.**

**Pista 2:** grafo con aristas en los dos sentidos y recorrido desde la persona 1.

**Pista 3:** BFS o DFS; la arista inversa lleva `(−X, −Y)`; los no alcanzados son indeterminados; coordenadas en 64 bits.

**14 → Problema: E - Somen Nagashi.**

**Pista 2:** simulación por eventos con dos colas de prioridad.

**Pista 3:** una cola por número para los que están en la fila y otra por instante de vuelta; antes de cada evento, devuelve a la fila a los que vuelven en un instante `≤ Tᵢ`; sumas en 64 bits.


---

## 15 — Simulacro de concurso 3

**15 → Problema: A - Arithmetic Progression.**

**Pista 2:** un bucle de `A` a `B` con paso `D`.

**Pista 3:** imprime los términos separados por espacios.

**15 → Problema: B - Append.**

**Pista 2:** un arreglo dinámico.

**Pista 3:** el `k`-ésimo desde el final es `a[tamaño − k]`.

**15 → Problema: C - Divide and Divide.**

**Pista 2:** recursión con memoización: `f(x) = x + f(⌊x/2⌋) + f(⌈x/2⌉)`.

**Pista 3:** aparecen `O(log N)` valores distintos; un mapa como memo; la respuesta cabe en 64 bits.

**15 → Problema: D - Super Takahashi Bros..**

**Pista 2:** Dijkstra con dos aristas por fase.

**Pista 3:** aristas `i → i + 1` de peso `Aᵢ` e `i → Xᵢ` de peso `Bᵢ` (puede ir hacia atrás); distancias en 64 bits.

**15 → Problema: E - Mancala 2.**

**Pista 2:** Fenwick de diferencias: suma a tramos y consulta puntual.

**Pista 3:** lee las bolas de `Bᵢ`, ponla a 0, suma `c div N` a todas y 1 a las `c mod N` siguientes (en dos tramos si da la vuelta).


---

## 16 — Simulacro de concurso 4

**16 → Problema: A - A Healthy Breakfast.**

**Pista 2:** comparar la posición de `R` con la de `M`.

**Pista 3:** `indexOf` o un recorrido.

**16 → Problema: B - Vertical Reading.**

**Pista 2:** probar todos los pares.

**Pista 3:** para cada `w`, parte en trozos; para cada `c ≤ w`, concatena el carácter `c` de los trozos que lo tengan y compara con `T`.

**16 → Problema: C - Move It.**

**Pista 2:** en cada caja se queda el más pesado; se mueven los demás.

**Pista 3:** suma total de pesos menos la suma de los máximos de cada caja no vacía.

**16 → Problema: D - Ghost Ants.**

**Pista 2:** una hacia la derecha y otra hacia la izquierda delante de ella a distancia `≤ 2T`.

**Pista 3:** ordena las posiciones de las que van a la izquierda; para cada una que va a la derecha en `x`, cuenta con binaria las de `(x, x + 2T]`.

**16 → Problema: E - Random Swaps of Balls.**

**Pista 2:** solo importa la probabilidad `p` de que la bola negra siga en la posición 1.

**Pista 3:** en cada paso, sale de la 1 con probabilidad `2(N − 1)/N²` y vuelve con `2/N²`; tras `K` pasos, `E = p + (1 − p)(N + 2)/2`, todo módulo con inversos.

---

**Anterior:** [`21/16` — Simulacro de concurso 4](16-simulacro-concurso-04.md) · **Siguiente:** — ·
**Relacionado:** [README del bloque](README.md).
