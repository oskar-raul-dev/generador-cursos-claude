# Respuestas — bloque 02: Análisis

> Solucionario del bloque `02`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-03.

**Salto rápido:** [01](#01--notación-asintótica-y-casos) · [02](#02--recurrencias-y-teorema-maestro) · [03](#03--análisis-amortizado) · [04](#04--corrección-invariante-de-bucle-inducción-y-argumento-de-intercambio) · [05](#05--el-coste-real) · [06](#06--tipos-abstractos-de-datos) · [07](#07--simulación)

---

# 01 — Notación asintótica y casos

**01 → 1.** Escribe la definición de `f ∈ O(g)` con sus constantes. 🟢

⏱️ **30 segundos.** `f ∈ O(g)` si existen una constante `c > 0` y un `n₀` tales que `f(n) ≤ c · g(n)` para todo `n ≥ n₀`.

🗣️ **2 minutos.** Las dos constantes tienen papeles distintos: `c` absorbe los factores constantes (por eso `O(2n) = O(n)`), y `n₀` permite ignorar los valores pequeños de `n`, donde una función «más lenta» puede ir por debajo. La definición habla de funciones no negativas desde algún punto.

🔬 **El detalle.** Es una definición de conjunto: `O(g)` son todas las funciones que cumplen eso. Por eso lo preciso es `f ∈ O(g)` y no `f = O(g)`. `Ω` cambia `≤` por `≥`, y `Θ` pide las dos con dos constantes `c₁` y `c₂`.

**01 → 2.** ¿Por qué `n ∈ O(n²)` es cierto, y por qué casi nunca se dice así? 🟢

⏱️ **30 segundos.** Porque `O` es solo un techo: `n ≤ 1 · n²` para todo `n ≥ 1`. No se dice así porque la cota no es ajustada, y lo útil es la ajustada: `n ∈ Θ(n)`.

🗣️ **2 minutos.** Decir que un algoritmo lineal es `O(n²)` es verdadero y casi inútil, igual que decir que un viaje de 10 minutos dura «menos de un día». En la práctica, cuando alguien dice «es `O(n)`» quiere decir «es `Θ(n)`», y es mejor usar la notación precisa.

🔬 **El detalle.** Hay contextos donde `O` sin `Θ` es lo correcto: cuando solo se sabe el techo, o cuando el coste varía con la entrada y se da la cota del caso peor («la búsqueda binaria hace `O(log n)` comparaciones»: en el caso mejor hace una).

**01 → 3.** ¿Cuántas veces se ejecuta el cuerpo de `for (i = 1; i < n; i *= 2)`, y en qué `Θ` queda? 🟢

⏱️ **30 segundos.** `⌈log₂ n⌉` veces: `i` vale `1, 2, 4, …` y se pasa de `n` tras ese número de duplicaciones. Queda en `Θ(log n)`.

🗣️ **2 minutos.** Tras `k` vueltas, `i = 2ᵏ`. El bucle sigue mientras `2ᵏ < n`, es decir, mientras `k < log₂ n`; el número de vueltas es el primer `k` con `2ᵏ ≥ n`, que es `⌈log₂ n⌉`. Con `n = 6`: `i = 1, 2, 4`, tres vueltas.

🔬 **El detalle.** Con `n = 1` no da ninguna vuelta, y `⌈log₂ 1⌉ = 0`: la fórmula funciona en el borde. El mismo razonamiento da `Θ(log n)` para cualquier bucle que multiplique o divida su índice por una constante mayor que 1.

**01 → 4.** ¿Qué diferencia hay entre caso promedio y caso esperado? 🟡

⏱️ **30 segundos.** El promedio es sobre una distribución de las **entradas**; el esperado es sobre el **azar del algoritmo**, para cada entrada fija.

🗣️ **2 minutos.** El caso promedio de *quicksort* con pivote fijo supone que la entrada es una permutación aleatoria; si no lo es —una entrada ya ordenada—, la garantía desaparece. El caso esperado de *quicksort* con pivote aleatorio vale para **toda** entrada, porque el azar lo pone el algoritmo y la entrada no puede anticiparlo.

🔬 **El detalle.** En un juez con casos adversarios, solo el esperado protege: el autor del caso de prueba elige la entrada, pero no tu generador aleatorio. Por eso se aleatorizan los pivotes y los *hashes* ([`06/03`](../06-lineales-y-hashing/03-tablas-hash.md)).

**01 → 5.** ¿Qué diferencia hay entre `O`, `Ω` y `Θ`, y cuál se quiere decir casi siempre que se dice «es `O(…)`»? 🟡

⏱️ **30 segundos.** `O` es una cota superior, `Ω` una inferior y `Θ` las dos a la vez. Casi siempre que se dice «es `O(…)`» se quiere decir `Θ`.

🗣️ **2 minutos.** `O(g)` contiene todo lo que crece como `g` o más despacio; `Ω(g)`, todo lo que crece como `g` o más deprisa; `Θ(g)`, exactamente lo que crece como `g`. «La ordenación por mezcla es `Θ(n log n)`» dice que no es más rápida ni más lenta que eso, en orden.

🔬 **El detalle.** `Ω` aparece sobre todo en cotas inferiores de problemas: «ninguna ordenación por comparación baja de `Ω(n log n)` comparaciones en el caso peor» ([`05/01`](../05-orden-y-busqueda/01-ordenacion-por-comparacion.md)). Ahí no se habla de un algoritmo sino de todos.

**01 → 6.** ¿Por qué la base del logaritmo no se escribe dentro de una `O`? 🟡

⏱️ **30 segundos.** Porque los logaritmos en bases distintas difieren en una constante: `log_a n = log_b n / log_b a`, y la constante se absorbe.

🗣️ **2 minutos.** `log₂ n` y `log₁₀ n` son proporcionales, con factor `log₂ 10 ≈ 3,32`. Para la notación asintótica, que descarta constantes, son la misma función. Por eso se escribe `O(log n)` sin base.

🔬 **El detalle.** La base sí importa fuera de la notación: en la cuenta de pasos (`log₂ 10⁶ ≈ 20`) y dentro de un exponente, donde ya no es una constante multiplicativa: `2^(log₂ n) = n`, pero `2^(log₁₀ n) = n^0,301`.

**01 → 7.** ¿Qué diferencia hay entre el coste amortizado de una operación y su caso peor? 🟡

⏱️ **30 segundos.** El caso peor es lo que puede costar una operación suelta; el amortizado es el coste medio por operación en el caso peor de **toda una secuencia**.

🗣️ **2 minutos.** El `push_back` de un arreglo dinámico cuesta `O(n)` cuando hay que copiar todo al crecer, pero eso pasa tan pocas veces que `n` operaciones cuestan `O(n)` en total: `O(1)` amortizado por operación. No es un promedio sobre entradas aleatorias: vale para cualquier secuencia.

🔬 **El detalle.** La diferencia importa cuando una operación suelta tiene un límite de tiempo propio (un sistema de tiempo real, una petición con *timeout*): ahí manda el caso peor por operación. Los métodos para demostrarlo están en [`02/03`](03-analisis-amortizado.md).

**01 → 8.** ¿Por qué el doble bucle `for (i = 1..n) for (j = i; j ≤ n; j += i)` es `Θ(n log n)` y no `Θ(n²)`? 🟠

⏱️ **30 segundos.** Porque el interno no da `n` vueltas sino `⌊n/i⌋`, y la suma `Σ n/i` es `n` por el número armónico `H(n) ≈ ln n`.

🗣️ **2 minutos.** Para `i = 1` el interno da `n` vueltas; para `i = 2`, `n/2`; para `i = n`, una. La suma `n(1 + 1/2 + 1/3 + … + 1/n)` es `n · H(n)`, y `H(n) = ln n + γ + o(1)`, con `γ ≈ 0,577`. Total: `Θ(n log n)`.

🔬 **El detalle.** La cota `H(n) ≤ 1 + ln n` sale de comparar la suma con la integral de `1/x`. El patrón aparece en la criba de Eratóstenes y en recorrer los múltiplos de cada número ([`17/04`](../17-matematica/04-primos.md)).

**01 → 9.** Un juez tiene casos diseñados por un adversario. ¿Qué garantía prefieres, la del *hash* o la de ordenar, y por qué? 🟠

⏱️ **30 segundos.** La de ordenar: `Θ(n log n)` en el caso peor, que ningún caso de prueba puede romper. El *hash* es `O(1)` esperado solo si la función *hash* no la puede atacar quien diseña la entrada.

🗣️ **2 minutos.** Con una función *hash* fija y conocida, un adversario puede construir claves que caen todas en la misma cubeta y degradar cada operación. Ordenar no depende de nada que el adversario controle. La alternativa que conserva el *hash* es aleatorizarlo con una semilla del momento de ejecución, que convierte el promedio en esperado.

🔬 **El detalle.** En Java, desde la 8, una cubeta muy llena se convierte en un árbol rojo-negro y el caso peor por operación baja a `O(log n)` con claves comparables; el ataque deja de ser cuadrático pero sigue siendo más lento. En C++, `unordered_map` no tiene esa protección. Los *anti-hash tests* se tratan en `06/03`.

**01 → 10.** «*Quicksort* es `O(n log n)`»: corrige la frase con los tres casos que corresponden. 🟠

⏱️ **30 segundos.** Con pivote fijo, `Θ(n²)` en el caso peor y `Θ(n log n)` en promedio sobre permutaciones uniformes; con pivote aleatorio, `Θ(n log n)` esperado para cualquier entrada.

🗣️ **2 minutos.** El caso peor del pivote fijo es una entrada ordenada: cada partición deja un lado vacío y el otro con `n − 1`, y la suma `n + (n−1) + …` es cuadrática. El promedio sobre entradas aleatorias da unas `1,39 · n log₂ n` comparaciones. Con pivote aleatorio, esa misma cuenta vale como esperanza para cualquier entrada.

🔬 **El detalle.** Incluso con pivote aleatorio existe un caso peor cuadrático, con probabilidad ínfima. Las implementaciones de librería evitan el problema de otra forma: `std::sort` usa *introsort*, que cambia a *heapsort* si la recursión se hace demasiado profunda, y garantiza `O(n log n)` en el caso peor (`05/01`).

**01 → 11.** Compara cómo cambia el tiempo real de un mismo `Θ(n log n)` entre C++, Java con `List<Integer>` y Python. ¿Qué parte de la diferencia ve la notación? 🟠

⏱️ **30 segundos.** La notación ve que los tres son `Θ(n log n)`; no ve que el tiempo real puede variar en un factor de 10 o más entre ellos, por la constante.

🗣️ **2 minutos.** En C++, ordenar `10⁶` enteros primitivos es rápido y amigable con la caché. En Java con `List<Integer>`, cada elemento es un objeto en el *heap*, las comparaciones desempaquetan y los accesos saltan por memoria. En Python, cada operación del intérprete cuesta decenas de instrucciones, salvo lo que hace `sorted` en C.

🔬 **El detalle.** La notación es la herramienta correcta para comparar algoritmos; para comparar implementaciones del mismo algoritmo hay que medir o razonar sobre la memoria ([`02/05`](05-el-coste-real.md)). Por eso [`01/02`](../01-oficio-del-competidor/02-leer-las-restricciones.md) dice que Python pierde una fila de la tabla y Java media con objetos.

**01 → 12.** Demuestra con la definición, dando `c` y `n₀`, que `5n² + 3n log₂ n ∈ Θ(n²)`. 🔴

⏱️ **30 segundos.** Con `c₁ = 5`, `c₂ = 8` y `n₀ = 1`: para `n ≥ 1`, `log₂ n ≤ n`, así que `5n² ≤ 5n² + 3n log₂ n ≤ 5n² + 3n² = 8n²`.

🗣️ **2 minutos.** La cota inferior es inmediata porque el segundo término es no negativo para `n ≥ 1`. Para la superior hace falta acotar `n log₂ n` por un múltiplo de `n²`, y basta con `log₂ n ≤ n`, cierto para todo `n ≥ 1`. Entonces `3n log₂ n ≤ 3n²`.

🔬 **El detalle.** Con la regla del límite es aún más corto: `lim (5n² + 3n log₂ n)/n² = 5 + lim 3 log₂ n / n = 5`, porque `log n / n → 0`. Un límite finito y positivo da `Θ` directamente.

**01 → 13.** Usa la regla del límite para ordenar `n^{0,001}`, `(log n)¹⁰⁰⁰` y `√n`, y explica por qué el resultado contradice la intuición con `n` pequeño. 🔴

⏱️ **30 segundos.** `(log n)¹⁰⁰⁰ ≺ n^{0,001} ≺ √n`: cualquier potencia del logaritmo es `o` de cualquier potencia positiva de `n`. Contradice la intuición porque con `n` pequeño `(log n)¹⁰⁰⁰` es astronómicamente mayor.

🗣️ **2 minutos.** `lim (log n)ᵏ / n^ε = 0` para todo `k` y todo `ε > 0`: con el cambio `n = eᵗ` queda `tᵏ / e^{εt}`, y una exponencial domina a cualquier polinomio. Y `n^{0,001} / n^{0,5} = n^{−0,499} → 0`. Pero con `n = 10⁶`, `(log₂ n)¹⁰⁰⁰ ≈ 20¹⁰⁰⁰`, mientras que `n^{0,001} ≈ 1,014`.

🔬 **El detalle.** El cruce entre `(log n)¹⁰⁰⁰` y `n^{0,001}` ocurre en valores de `n` con miles de millones de dígitos: la jerarquía es cierta y completamente irrelevante para cualquier entrada real. Es la ilustración extrema de que la notación asintótica habla del límite, y que con `n` acotado manda la constante.

**01 → Problema: Cuántas veces se ejecuta.**

- **Pista 2 — patrón:** **conteo combinatorio**: el fragmento cuenta las ternas `i < j < k` de `{0, …, n−1}`.
- **Pista 3 — diseño:** la respuesta es `C(n, 3) = n(n−1)(n−2)/6`; con `n = 10⁶` el producto llega a `10¹⁸`, que cabe en 64 bits con signo, y la división es exacta.

**01 → Problema: El doble bucle armónico.**

- **Pista 2 — patrón:** **conteo por filas**: el interno da `⌊n/i⌋` vueltas.
- **Pista 3 — diseño:** suma `⌊n/i⌋` para `i` de 1 a `n` en un bucle de `n` vueltas, en 64 bits; el total es del orden de `n ln n`, unos `1,4·10⁷` con `n = 10⁶`.

**01 → Problema: ¿Cuál crece más?.**

- **Pista 2 — patrón:** **jerarquía de funciones**: exponencial domina a polinomio, y polinomio domina a logaritmo.
- **Pista 3 — diseño:** compara primero `c₁` con `c₂`; si son iguales, `a₁` con `a₂`; si también, `b₁` con `b₂`; si los tres coinciden, `=`. El primer criterio que difiere decide.

**01 → Problema: FrogJmp.**

- **Pista 2 — patrón:** **fórmula** en vez de simulación.
- **Pista 3 — diseño:** el número de saltos es `⌈(Y − X) / D⌉`, que en enteros es `(Y − X + D − 1) / D`.

**01 → Problema: Find Pivot Index.**

- **Pista 2 — patrón:** **suma total y prefijo** en un recorrido.
- **Pista 3 — diseño:** calcula el total; recorre llevando la suma de la izquierda; en `i`, la derecha es `total − izquierda − nums[i]`; devuelve el primer `i` donde coinciden.

**01 → Problema: Squares of a Sorted Array.**

- **Pista 2 — patrón:** **dos punteros** desde los extremos: los cuadrados mayores están en los bordes.
- **Pista 3 — diseño:** llena el resultado de atrás hacia delante; en cada paso compara los valores absolutos de los dos extremos, coloca el cuadrado del mayor y mueve ese puntero.

**01 → Problema: Maximum Average Subarray I.**

- **Pista 2 — patrón:** **ventana deslizante** de tamaño fijo.
- **Pista 3 — diseño:** suma los primeros `k`; al desplazar la ventana, suma el que entra y resta el que sale; guarda la suma máxima y divide por `k` al final.

**01 → Problema: Find All Numbers Disappeared in an Array.**

- **Pista 2 — patrón:** **marcar en el sitio** usando el signo de los elementos como bit de presencia.
- **Pista 3 — diseño:** para cada valor `v`, haz negativo el elemento en la posición `|v| − 1`; al final, las posiciones con valor positivo corresponden a los números que faltan.

**01 → Problema: Ice Cream Parlor.**

- **Pista 2 — patrón:** **leer la cota**: con las restricciones del enunciado, la fuerza bruta de parejas cabe; el complemento con un mapa es la mejora.
- **Pista 3 — diseño:** recorre guardando en un mapa el índice de cada precio visto; para cada precio, busca `m − precio` entre los anteriores; los índices de la salida empiezan en 1.

**01 → Problema: Pairs.**

- **Pista 2 — patrón:** **conjunto** u **ordenación con búsqueda binaria**: cada valor necesita encontrar `valor + k`.
- **Pista 3 — diseño:** mete todos los valores en un conjunto y cuenta cuántos `v` tienen `v + k` dentro; o ordena y busca cada `v + k` con búsqueda binaria.

**01 → Problema: Subarray Sums I.**

- **Pista 2 — patrón:** **dos punteros**: con valores positivos, la suma crece al mover el derecho y baja al mover el izquierdo.
- **Pista 3 — diseño:** avanza el derecho sumando; mientras la suma pase de `x`, avanza el izquierdo restando; cuenta cada vez que la suma sea exactamente `x`.

**01 → Problema: Subarray Sums II.**

- **Pista 2 — patrón:** **prefijos con un mapa de frecuencias**: con negativos, los dos punteros no sirven.
- **Pista 3 — diseño:** recorre llevando el prefijo `P`; la cantidad de subarreglos que terminan aquí con suma `x` es cuántas veces apareció antes el prefijo `P − x`; suma eso y registra `P`. El mapa empieza con el prefijo 0 una vez.

**01 → Problema: Sum of Two Values.**

- **Pista 2 — patrón:** **ordenar con índices y dos punteros**, que da un caso peor garantizado; el mapa de complementos funciona pero puede ser atacado.
- **Pista 3 — diseño:** ordena pares `(valor, índice original)`; con un puntero en cada extremo, si la suma es menor que `x` avanza el izquierdo, si es mayor retrocede el derecho, y si es igual imprime los dos índices originales.

---

# 02 — Recurrencias y teorema maestro

**02 → 1.** Enuncia el teorema maestro con sus tres casos y la condición de regularidad. 🟢

⏱️ **30 segundos.** Para `T(n) = a·T(n/b) + f(n)` con `p = log_b a`: si `f` es polinómicamente menor que `nᵖ`, `Θ(nᵖ)`; si es `Θ(nᵖ)`, `Θ(nᵖ log n)`; si es polinómicamente mayor y cumple `a·f(n/b) ≤ c·f(n)` con `c < 1`, `Θ(f(n))`.

🗣️ **2 minutos.** Los tres casos comparan el trabajo de partir y combinar, `f(n)`, con el número de hojas del árbol, `nᵖ`. Caso 1: mandan las hojas. Caso 2: los dos pesan igual y cada uno de los `log n` niveles cuesta `nᵖ`. Caso 3: manda la raíz, y la regularidad garantiza que el coste baja geométricamente al bajar de nivel.

🔬 **El detalle.** «Polinómicamente» significa con un `nᵉ` de diferencia, `ε > 0`: `n / log n` frente a `n` no lo es, y cae en el hueco entre los casos 1 y 2. Con `f(n) = nᵈ` la regularidad se cumple sola cuando aplica el caso 3. La prueba completa está en CLRS, 3.ª ed., §4.6.

**02 → 2.** Resuelve `T(n) = 2T(n/2) + n` y `T(n) = T(n/2) + 1`. 🟢

⏱️ **30 segundos.** `2T(n/2) + n` es `Θ(n log n)`; `T(n/2) + 1` es `Θ(log n)`. Las dos son el caso 2 del teorema maestro.

🗣️ **2 minutos.** En la primera, `a = 2`, `b = 2`, `p = 1` y `f(n) = n = n¹`: caso 2, `Θ(n log n)`. En la segunda, `a = 1`, `b = 2`, `p = 0` y `f(n) = 1 = n⁰`: caso 2, `Θ(n⁰ log n) = Θ(log n)`. Son la ordenación por mezcla y la búsqueda binaria.

🔬 **El detalle.** Por el árbol: la primera tiene `log₂ n` niveles y cada uno suma `n`; la segunda tiene `log₂ n` niveles de un solo nodo con coste 1.

**02 → 3.** ¿Qué diferencia hay entre el árbol de recursión y el método de sustitución, en para qué sirve cada uno? 🟡

⏱️ **30 segundos.** El árbol sirve para **adivinar** la solución sumando el coste por niveles; la sustitución, para **demostrarla** por inducción.

🗣️ **2 minutos.** El árbol hace visible qué domina —la raíz, las hojas o todos los niveles por igual— y da una suma que se puede calcular. Pero sus pasos suelen ser aproximados (suelos, techos, el último nivel). La sustitución toma esa suposición y la prueba por inducción fuerte con constantes explícitas.

🔬 **El detalle.** La sustitución es delicada: hay que probar la forma exacta de la cota con la misma constante. A veces la forma ingenua no cierra la inducción y hay que restar un término de orden menor (probar `T(n) ≤ cn − d` en vez de `T(n) ≤ cn`).

**02 → 4.** ¿Por qué `T(n) = T(n−1) + n` no es `Θ(n log n)`? 🟡

⏱️ **30 segundos.** Porque restar uno no divide el tamaño: al desenrollar sale `n + (n−1) + … + 1 = n(n+1)/2`, que es `Θ(n²)`.

🗣️ **2 minutos.** El `log n` aparece cuando el tamaño se divide en cada nivel, porque entonces hay `log n` niveles. Aquí hay `n` niveles, y el nivel `k` cuesta `n − k`. La suma aritmética es cuadrática. Es la recurrencia de la ordenación por selección o de una recursión que quita un elemento y recorre el resto.

🔬 **El detalle.** El error es confundir la forma de la recursión (una llamada y un trabajo lineal) con la de la ordenación por mezcla. La diferencia está en el argumento de la llamada: `n − 1` o `n / 2`.

**02 → 5.** ¿Qué diferencia hay entre una recurrencia que divide el tamaño y una que lo resta, en cuanto al orden que suele dar? 🟡

⏱️ **30 segundos.** Dividir el tamaño da árboles de profundidad `log n` y órdenes polinómicos o con logaritmos; restar da profundidad `n` y órdenes que son sumas (polinómicos de un grado más) o exponenciales si hay varias llamadas.

🗣️ **2 minutos.** `T(n/2) + 1` es `log n`, pero `T(n−1) + 1` es `n`. `2T(n/2) + 1` es `n`, pero `2T(n−1) + 1` es `2ⁿ`. Con la misma forma, restar convierte cada logaritmo en un lineal y cada polinomio en una exponencial cuando hay ramificación.

🔬 **El detalle.** La profundidad también es la de la pila: una recursión que resta uno tiene `n` marcos de pila, y con `n = 10⁵` revienta en Java y en Python. Una que divide tiene `log n`, inofensiva.

**02 → 6.** ¿Por qué `power(x, n/2) * power(x, n/2)` no mejora a la versión ingenua, y la versión con una sola llamada sí? 🟠

⏱️ **30 segundos.** Porque con dos llamadas la recurrencia es `2T(n/2) + 1`, que es `Θ(n)`; con una sola es `T(n/2) + 1`, que es `Θ(log n)`. Lo que cambia es `a`.

🗣️ **2 minutos.** Escribir el mismo cálculo dos veces hace que el árbol se ramifique: cada nivel duplica los nodos y el número de hojas vuelve a ser `n`. Guardar el resultado en una variable y elevarlo al cuadrado deja un árbol de un solo camino. Es el mismo principio que la memoización: no recalcular lo que ya se calculó.

🔬 **El detalle.** Con el teorema maestro: `a = 2`, `b = 2`, `p = 1`, `f = 1 = n⁰`, caso 1, `Θ(n)`. Y `a = 1`, `p = 0`, `f = n⁰`, caso 2, `Θ(log n)`.

**02 → 7.** ¿Por qué el teorema maestro no se aplica a `T(n) = 2T(n/2) + n / log n`, y cuánto vale? 🟠

⏱️ **30 segundos.** Porque `n / log n` es menor que `n¹` pero no polinómicamente menor: no hay `ε > 0` con `n / log n ∈ O(n^{1−ε})`. Cae entre los casos 1 y 2. La solución es `Θ(n log log n)`.

🗣️ **2 minutos.** Por el árbol: el nivel `j` tiene `2ʲ` nodos de tamaño `n/2ʲ`, y cada uno cuesta `(n/2ʲ) / log(n/2ʲ)`. El nivel cuesta `n / (log n − j)`. Sumando sobre `j` de 0 a `log n − 1` sale `n · Σ 1/k` con `k` de 1 a `log n`, que es `n · H(log n) ≈ n ln log n`.

🔬 **El detalle.** El caso 2 extendido de CLRS (ejercicio 4.6-2) cubre `f(n) = Θ(nᵖ logᵏ n)` con `k ≥ 0` y da `Θ(nᵖ log^{k+1} n)`; con `k = −1` deja de aplicar y aparece el `log log n`.

**02 → 8.** Karatsuba pasa de cuatro multiplicaciones a tres. ¿Qué parte de la recurrencia cambia y cuánto baja el exponente? 🟠

⏱️ **30 segundos.** Cambia `a`, de 4 a 3. El exponente baja de `log₂ 4 = 2` a `log₂ 3 ≈ 1,585`.

🗣️ **2 minutos.** La multiplicación escolar por divide y vencerás parte cada número en dos mitades y hace cuatro productos de mitades: `4T(n/2) + n`, caso 1, `Θ(n²)`. Karatsuba consigue lo mismo con tres productos y algunas sumas extra: `3T(n/2) + n`, caso 1, `Θ(n^{log₂ 3})`. Las sumas extra solo tocan `f(n)`, que sigue siendo lineal.

🔬 **El detalle.** Es una lección general del teorema maestro: en el caso 1, el exponente lo decide `a/b`, no `f`. Reducir el número de subproblemas vale más que abaratar la combinación. Strassen hace lo mismo con matrices, de 8 a 7.

**02 → 9.** Un código Java recursivo con recurrencia `T(n) = T(n−1) + O(1)` y `n = 10⁶` da RE, y el mismo en C++ no. ¿Qué tiene que ver la recurrencia con eso, y qué cambia entre lenguajes? 🟠

⏱️ **30 segundos.** La recurrencia `T(n−1) + O(1)` significa profundidad de recursión `n`: un millón de marcos de pila. La pila de un hilo de Java se desborda mucho antes; los jueces suelen dar a C++ una pila mayor.

🗣️ **2 minutos.** El coste en tiempo es lineal y entraría, pero cada llamada sin terminar ocupa un marco en la pila. En Java el hilo principal tiene del orden de 1 MB y el error es un `StackOverflowError`, que el juez informa como RE. En C++ muchos jueces configuran la pila del proceso con varios cientos de MB o sin límite, así que el mismo código pasa.

🔬 **El detalle.** Las soluciones: convertir la recursión en un bucle (siempre posible con recursión de cola o con una pila explícita), o en Java ejecutar la recursión en un `Thread` con pila grande. En Python, el límite de 1000 llamadas obliga a subirlo y a ampliar la pila del hilo ([`03/04`](../03-biblioteca-estandar/04-python-para-competir.md), [`10/01`](../10-busqueda-completa-y-divide-y-venceras/01-recursion.md)).

**02 → 10.** Esboza la prueba del caso 2 del teorema maestro con el árbol de recursión. 🔴

⏱️ **30 segundos.** En el caso 2, cada nivel del árbol cuesta `Θ(nᵖ)` y hay `log_b n` niveles, así que el total es `Θ(nᵖ log n)`.

🗣️ **2 minutos.** El nivel `j` tiene `aʲ` nodos de tamaño `n/bʲ`, y cada uno cuesta `f(n/bʲ) = Θ((n/bʲ)ᵖ) = Θ(nᵖ / bʲᵖ)`. Como `bᵖ = a`, eso es `Θ(nᵖ / aʲ)`, y por `aʲ` nodos el nivel cuesta `Θ(nᵖ)`. Hay `log_b n` niveles internos más las hojas, que suman `Θ(nᵖ)`: total `Θ(nᵖ log n)`.

🔬 **El detalle.** El esbozo esconde dos cosas: que las constantes del `Θ` son uniformes en todos los niveles (lo son porque es la misma `f`), y el efecto de suelos y techos, que CLRS trata aparte en §4.6.2 y no cambia el orden.

**02 → 11.** Encuentra el error de esta prueba: «`T(n) = 2T(n/2) + n ≤ 2c(n/2) + n = cn + n = O(n)`». 🔴

⏱️ **30 segundos.** Que la inducción tiene que probar la **misma** cota, `T(n) ≤ cn`, y lo que se obtuvo es `T(n) ≤ cn + n`, que no es `≤ cn`. Decir «`cn + n` es `O(n)`» hace crecer la constante en cada nivel.

🗣️ **2 minutos.** La hipótesis inductiva es «`T(k) ≤ c·k` para todo `k < n`» con una `c` fija. Para cerrar el paso hay que llegar a `T(n) ≤ c·n` con esa misma `c`. Tras aplicar la hipótesis queda `cn + n`, y para ningún `c` se cumple `cn + n ≤ cn`. La inducción no cierra, y de hecho la cota es falsa: `T(n) ∈ Θ(n log n)`.

🔬 **El detalle.** Usar `O` dentro de una inducción es la forma de cometer este error sin verlo: cada paso multiplica la constante por algo, y tras `log n` pasos la «constante» es `log n`. Por eso la sustitución se escribe siempre con constantes explícitas.

**02 → 12.** Resuelve `T(n) = T(n/3) + T(2n/3) + n` con el árbol de recursión y comprueba el resultado con Akra-Bazzi. 🔴

⏱️ **30 segundos.** `Θ(n log n)`. Por el árbol, cada nivel completo suma `n` y hay entre `log₃ n` y `log_{3/2} n` niveles. Por Akra-Bazzi, `(1/3)ᵖ + (2/3)ᵖ = 1` da `p = 1`, y la integral de `u / u²` es `ln n`.

🗣️ **2 minutos.** En el árbol, el nivel `j` tiene subproblemas cuyos tamaños suman `n` mientras ninguna rama haya llegado a la hoja, así que cuesta como mucho `n`. La rama más corta (siempre `n/3`) tiene `log₃ n` niveles y la más larga (siempre `2n/3`) `log_{3/2} n`. Así que el total está entre `n log₃ n` y `n log_{3/2} n`: `Θ(n log n)`. Akra-Bazzi da `Θ(n¹(1 + ∫₁ⁿ u/u² du)) = Θ(n(1 + ln n)) = Θ(n log n)`.

🔬 **El detalle.** Es la recurrencia de un *quicksort* cuyo pivote siempre deja un tercio a un lado. La lección es que no hace falta partir por la mitad: cualquier proporción constante da `n log n`, con otra constante.

**02 → Problema: Clasificar por el teorema maestro.**

- **Pista 2 — patrón:** **regla corta del teorema maestro** con `f(n) = nᵈ`: comparar `a` con `bᵈ`.
- **Pista 3 — diseño:** calcula `bᵈ` multiplicando paso a paso y deteniéndote en cuanto pase de `a` (así no desborda); si `a < bᵈ`, caso 3; si son iguales, caso 2; si `a > bᵈ`, caso 1. Con `d = 0`, `bᵈ = 1`.

**02 → Problema: Evaluar la recurrencia.**

- **Pista 2 — patrón:** **recursión con memoización**: los argumentos que aparecen son `⌊n/2ᵏ⌋`, solo `O(log n)` valores distintos.
- **Pista 3 — diseño:** implementa la recursión tal cual; como cada llamada hace una sola llamada recursiva, la profundidad es `log₂ n ≤ 50` y ni siquiera hace falta memoria; el resultado llega a unos `5·10¹⁶`, en 64 bits.

**02 → Problema: Llamadas de Fibonacci.**

- **Pista 2 — patrón:** **recurrencia del número de llamadas**: `C(n) = 1 + C(n−1) + C(n−2)`, con `C(0) = C(1) = 1`.
- **Pista 3 — diseño:** calcula `C` de abajo arriba con un bucle (no con la recursión ingenua, que tardaría lo mismo que el número que cuenta); o usa `C(n) = 2F(n+1) − 1`. Con `n = 85` el valor ronda `8,4·10¹⁷` y cabe en 64 bits.

**02 → Problema: Fibonacci Number.**

- **Pista 2 — patrón:** **memoización** o **iteración** de abajo arriba.
- **Pista 3 — diseño:** guarda los dos últimos valores y avanza `n` veces; la recursión ingenua también pasa aquí por lo pequeño de `n`, pero escribe su recurrencia y compárala.

**02 → Problema: Sort an Array.**

- **Pista 2 — patrón:** **ordenación por mezcla**, `2T(n/2) + n`; el enunciado pide no usar la de la librería.
- **Pista 3 — diseño:** parte en mitades, ordena cada una recursivamente y mezcla con dos índices sobre un arreglo auxiliar; o un *heapsort* en el sitio. Evita el *quicksort* con pivote fijo: hay casos que lo hacen cuadrático.

**02 → Problema: Different Ways to Add Parentheses.**

- **Pista 2 — patrón:** **divide y vencerás por el último operador**, con memoización por subcadena.
- **Pista 3 — diseño:** para cada operador de la expresión, calcula recursivamente todos los resultados de su izquierda y de su derecha y combínalos con ese operador; el caso base es un número solo. El número de resultados crece como los números de Catalan.

**02 → Problema: Search a 2D Matrix II.**

- **Pista 2 — patrón:** **recorrido en escalera** desde una esquina, que descarta una fila o una columna por comparación.
- **Pista 3 — diseño:** empieza arriba a la derecha; si el valor es mayor que el objetivo, descarta la columna (izquierda); si es menor, descarta la fila (abajo). Son como mucho `m + n` pasos; el divide y vencerás en cuadrantes da una recurrencia peor.

**02 → Problema: Recursive Digit Sum.**

- **Pista 2 — patrón:** **reducir antes de recursar**: la primera suma colapsa el número enorme.
- **Pista 3 — diseño:** suma los dígitos de `n` una vez y multiplica por `k` (no concatenes `k` copias); a partir de ahí el número tiene pocos dígitos y la recursión es corta. Equivale a la raíz digital, `1 + (s − 1) mod 9`.

**02 → Problema: The Power Sum.**

- **Pista 2 — patrón:** **recursión sobre la siguiente base** con poda por el valor restante.
- **Pista 3 — diseño:** `contar(restante, base)` suma las formas que usan `base^N` y las que no, y se corta cuando `base^N` pasa del restante; las bases van en orden creciente para no contar dos veces el mismo conjunto.

**02 → Problema: Merge Sort: Counting Inversions.**

- **Pista 2 — patrón:** **ordenación por mezcla con conteo**: `2T(n/2) + n`.
- **Pista 3 — diseño:** al mezclar, cada vez que tomas un elemento de la mitad derecha antes que los que quedan en la izquierda, suma cuántos quedan en la izquierda; el total llega a `n²/2`, así que va en 64 bits.

**02 → Problema: Tower of Hanoi.**

- **Pista 2 — patrón:** **recursión** `H(n) = 2H(n−1) + 1`.
- **Pista 3 — diseño:** mueve `n − 1` discos a la torre auxiliar, el mayor a la de destino, y los `n − 1` de la auxiliar al destino; imprime cada movimiento. Son `2ⁿ − 1`.

**02 → Problema: Gray Code.**

- **Pista 2 — patrón:** **construcción recursiva por reflexión**.
- **Pista 3 — diseño:** el código de `n` bits es el de `n − 1` con un 0 delante, seguido del de `n − 1` en orden inverso con un 1 delante; equivalentemente, el `i`-ésimo es `i ⊕ (i >> 1)`.

**02 → Problema: Exponentiation.**

- **Pista 2 — patrón:** **exponenciación rápida modular**, `T(b/2) + 1`.
- **Pista 3 — diseño:** eleva al cuadrado la potencia de la mitad y multiplica por `a` si `b` es impar, reduciendo módulo `10⁹ + 7` tras cada producto en 64 bits; `0⁰ = 1` en este problema.

---

# 03 — Análisis amortizado

**03 → 1.** ¿Qué es un coste amortizado, y qué desigualdad tienen que cumplir los costes amortizados? 🟢

⏱️ **30 segundos.** Es un coste asignado a cada operación tal que, para toda secuencia y todo prefijo, la suma de los amortizados es mayor o igual que la suma de los costes reales.

🗣️ **2 minutos.** La desigualdad `Σ cᵢ ≤ Σ ĉᵢ` para todo prefijo garantiza que el total real nunca supera el total amortizado. Si cada `ĉᵢ` es `O(1)`, cualquier secuencia de `n` operaciones cuesta `O(n)`, aunque alguna operación suelta cueste mucho más.

🔬 **El detalle.** «Para todo prefijo» es lo que impide hacer trampas cobrando después: si en algún momento lo gastado superara lo cobrado, una secuencia que se cortara ahí rompería la cota. En el método contable eso es «el crédito nunca es negativo»; en el del potencial, «`Φ(Dₖ) ≥ Φ(D₀)`».

**03 → 2.** ¿Cuántas copias hace en total un arreglo dinámico que duplica, con `n` `push` desde capacidad 1? 🟢

⏱️ **30 segundos.** `1 + 2 + 4 + … + 2ᵏ` con `2ᵏ < n`, que es `2^{⌈log₂ n⌉} − 1`: menos de `2n`.

🗣️ **2 minutos.** Se copia en los `push` que encuentran el arreglo lleno, de capacidad `1, 2, 4, …`, y cada uno copia tantos elementos como la capacidad. La serie geométrica suma menos que el doble de su último término, y el último término es menor que `n`. Con `n = 9`, son `1 + 2 + 4 + 8 = 15`.

🔬 **El detalle.** Sumando las `n` escrituras, el coste total es menor que `3n`, que es lo que da `O(1)` amortizado. Es el problema propio «Copias del arreglo dinámico».

**03 → 3.** ¿Qué factor de crecimiento usan `std::vector` en libstdc++, `ArrayList` y `list` de CPython? 🟢

⏱️ **30 segundos.** libstdc++ duplica (factor 2); `ArrayList` de OpenJDK crece un 50 % (factor 1,5); `list` de CPython sobreasigna alrededor de un octavo (factor ~1,125).

🗣️ **2 minutos.** En libstdc++ la nueva capacidad es `size + max(size, n)`. En `ArrayList`, `oldCapacity + (oldCapacity >> 1)`, con capacidad 10 al primer `add`. En CPython 3.12, `newsize + (newsize >> 3) + 6`, redondeado a múltiplo de 4. Los tres son factores mayores que 1, así que los tres dan `O(1)` amortizado.

🔬 **El detalle.** El estándar de C++ no fija el factor, solo la complejidad amortizada, y otras implementaciones usan 1,5. El factor pequeño de Python ahorra memoria a cambio de copiar más a menudo. Se comprobó en el código fuente de cada librería el 2026-10-03.

**03 → 4.** ¿Qué diferencia hay entre coste amortizado y coste promedio? 🟡

⏱️ **30 segundos.** El amortizado es una garantía de caso peor sobre cualquier secuencia; el promedio es una media sobre una distribución de entradas y puede fallar con una entrada mala.

🗣️ **2 minutos.** «`push` es `O(1)` amortizado» vale para la peor secuencia de `push` imaginable. «La búsqueda lineal hace `(n+1)/2` comparaciones en promedio» solo vale si la posición buscada es uniforme. Ninguna probabilidad interviene en el amortizado.

🔬 **El detalle.** Por eso el amortizado no se rompe con casos adversarios en un juez, y el promedio sí. Lo que sí rompe el amortizado es necesitar una cota por operación suelta.

**03 → 5.** ¿Qué diferencia hay entre los métodos agregado, contable y del potencial, en qué contabilizan? 🟡

⏱️ **30 segundos.** El agregado acota el total y divide; el contable cobra tarifas y guarda crédito en la estructura; el del potencial mide con una función del estado cuánto trabajo queda acumulado.

🗣️ **2 minutos.** Los tres demuestran lo mismo. El agregado da un solo coste para todas las operaciones. El contable permite tarifas distintas por tipo de operación y sitúa el crédito en elementos concretos. El potencial reúne todo el crédito en un número que depende solo del estado, lo que lo hace más fácil de manejar en estructuras complejas.

🔬 **El detalle.** El contable y el del potencial son equivalentes: el potencial es el crédito total. La elección es de comodidad: para un arreglo dinámico basta el agregado; para un árbol *splay*, el potencial es casi obligatorio.

**03 → 6.** ¿Qué diferencia hay entre el caso peor de un `push` y su coste amortizado, y cuándo importa el primero? 🟡

⏱️ **30 segundos.** El caso peor de un `push` suelto es `O(n)`, cuando copia todo; su amortizado es `O(1)`. El primero importa cuando hay un límite de tiempo por operación.

🗣️ **2 minutos.** En un programa que hace `n` `push` y después mira el total, solo importa el amortizado. En un sistema que tiene que responder cada petición en pocos milisegundos, una copia de un millón de elementos en mitad de una petición es un pico de latencia, aunque el total sea bajo.

🔬 **El detalle.** Las estructuras para tiempo real convierten el amortizado en caso peor repartiendo el trabajo caro: copian unos pocos elementos en cada operación en vez de todos de golpe.

**03 → 7.** ¿Por qué crecer sumando una constante deja el total en `Θ(n²)`, aunque la constante sea un millón? 🟠

⏱️ **30 segundos.** Porque cada copia sigue siendo del tamaño actual: con crecimiento de `c` en `c`, se copia cada `c` operaciones `c + 2c + 3c + …`, que suma unos `n²/(2c)`. Es `Θ(n²)` dividido por `c`.

🗣️ **2 minutos.** Con `n = 10⁹` y `c = 10⁶`, son unas `5·10¹¹` copias: el millón divide, pero no cambia el orden. Multiplicar la capacidad por `r > 1` hace que las copias formen una serie geométrica que suma unas `n/(r − 1)`, lineal.

🔬 **El detalle.** El factor `r` elige el compromiso entre memoria y copias: con `r = 2` se desperdicia hasta la mitad de la memoria y cada elemento se copia de media una vez; con `r = 1,125` se desperdicia poco y se copia unas ocho veces.

**03 → 8.** Compara `ArrayList<Integer>.add` en Java, `push_back` en C++ y `append` en Python: ¿son los tres `O(1)` amortizados, y qué los distingue? 🟠

⏱️ **30 segundos.** Los tres son `O(1)` amortizados, porque los tres crecen por un factor. Los distingue la constante: `ArrayList<Integer>` guarda punteros a objetos `Integer`, y `list` de Python guarda punteros a objetos `int`; `std::vector<int>` guarda los `int` directamente.

🗣️ **2 minutos.** La complejidad es la misma, y el tiempo real no. En C++ los enteros están contiguos y una copia es un `memmove`. En Java cada `add` de un `int` lo empaqueta en un `Integer` (salvo los cacheados de −128 a 127), y en Python cada entero es un objeto. Además, los factores difieren: 2, 1,5 y ~1,125.

🔬 **El detalle.** Para listas grandes de enteros en Java, `int[]` con crecimiento manual (la plantilla de §3) evita el *boxing*; en Python, el módulo `array` guarda enteros compactos, aunque cada acceso vuelve a crear un objeto. El coste real se trata en `02/05`.

**03 → 9.** Si el arreglo dinámico además encoge a la mitad cuando queda medio vacío, ¿qué secuencia rompe el amortizado, y cómo se arregla? 🟠

⏱️ **30 segundos.** Una secuencia que alterna `push` y `pop` justo en el borde: si al llenarse duplica y al quedar a la mitad encoge, cada operación copia todo. Se arregla encogiendo solo cuando queda a un cuarto.

🗣️ **2 minutos.** Con capacidad `2m` y `m` elementos, un `push` lleno duplica; un `pop` posterior deja `m` en capacidad `2m`… si el umbral de encoger es la mitad, encoge y el siguiente `push` vuelve a duplicar. Cada operación cuesta `Θ(m)`. Con el umbral de un cuarto, entre un cambio de tamaño y el siguiente hay al menos `m/2` operaciones baratas que lo pagan.

🔬 **El detalle.** Es el ejemplo de las tablas dinámicas de CLRS, 3.ª ed., §17.4, resuelto con un potencial que cambia de forma según la carga esté por encima o por debajo de la mitad.

**03 → 10.** Demuestra con el método del potencial que el `increment` del contador binario es `O(1)` amortizado. 🔴

⏱️ **30 segundos.** Con `Φ` = número de bits a 1: un `increment` que pone `t` bits a 0 y uno a 1 cuesta `t + 1` reales, y el potencial cambia en `1 − t`. El amortizado es `2`.

🗣️ **2 minutos.** El incremento recorre los bits desde el menos significativo: cada 1 se convierte en 0 hasta encontrar el primer 0, que se convierte en 1. Si había `t` unos al final, el coste real es `t + 1` y el número de unos pasa de `b` a `b − t + 1`. `ĉ = (t + 1) + (b − t + 1 − b) = 2`. Como `Φ ≥ 0` y `Φ(D₀) = 0` empezando en cero, el teorema del potencial da que `n` incrementos cuestan como mucho `2n`.

🔬 **El detalle.** Si el contador puede llegar al máximo y desbordarse a cero, el último incremento pone todos los bits a 0 sin ninguno a 1: `ĉ = k + (−k) = 0`, y la prueba sigue valiendo. Lo que la rompe es permitir decrementos.

**03 → 11.** Demuestra con el método agregado que una cola hecha con dos pilas tiene `O(1)` amortizado por operación. 🔴

⏱️ **30 segundos.** Cada elemento se apila una vez en la pila de entrada, se mueve como mucho una vez a la de salida y se desapila una vez de ella: como mucho cuatro operaciones de pila por elemento. Con `n` operaciones, el total es `O(n)`.

🗣️ **2 minutos.** La cola encola apilando en `entrada`. Para desencolar, si `salida` está vacía se vuelcan todos los de `entrada` en `salida` (invirtiendo el orden), y se desapila de `salida`. El volcado puede costar `O(n)`, pero ningún elemento se vuelca dos veces, porque una vez en `salida` solo sale desapilado. Sumando por elementos, el total está acotado por `4n`.

🔬 **El detalle.** El invariante que garantiza el orden FIFO: todos los elementos de `salida` llegaron antes que todos los de `entrada`, y `salida` tiene en su cima el más antiguo. Por eso solo se vuelca cuando `salida` está vacía; volcar con elementos en `salida` rompería el orden.

**03 → 12.** Un servicio con un `HashMap` enorme tiene picos de latencia cada cierto tiempo, aunque la media sea buena. Explica la causa con el vocabulario del capítulo y propón un diseño que acote el caso peor. 🔴

⏱️ **30 segundos.** Cuando el `HashMap` supera su factor de carga, duplica la tabla y reubica todas las entradas de golpe: es `O(1)` amortizado pero `O(n)` en esa operación, y con millones de claves eso es un pico de latencia. Se arregla repartiendo el redimensionado.

🗣️ **2 minutos.** El diseño que acota el caso peor mantiene dos tablas durante la transición: las inserciones van a la nueva, las búsquedas miran las dos, y cada operación mueve unas pocas cubetas de la vieja a la nueva. Cuando la vieja queda vacía, se libera. El coste por operación queda acotado por una constante; el total sigue siendo el mismo.

🔬 **El detalle.** Alternativas más simples: dimensionar el mapa al crearlo con la capacidad esperada (`new HashMap<>(capacidad)`) para que no crezca en caliente, o usar una estructura con caso peor acotado. Redis usa el redimensionado incremental en sus diccionarios.

**03 → Problema: Copias del arreglo dinámico.**

- **Pista 2 — patrón:** **método agregado**: las copias ocurren en las potencias de dos y suman una serie geométrica.
- **Pista 3 — diseño:** se copia al hacer el `push` número `2ʲ + 1`, y se copian `2ʲ` elementos; la respuesta es la suma de las potencias de dos menores que `n`, que vale `2^{⌈log₂ n⌉} − 1` (0 si `n = 1`). Con `n` hasta `10¹⁸`, recorre las potencias en 64 bits sin pasarte.

**03 → Problema: El contador binario.**

- **Pista 2 — patrón:** **método agregado** por bits: el bit `i` cambia `⌊n / 2ⁱ⌋` veces.
- **Pista 3 — diseño:** la respuesta es `Σᵢ ⌊n / 2ⁱ⌋`, que es igual a `2n` menos el número de bits a 1 de `n`; con `n` hasta `10¹⁸`, `2n` cabe en 64 bits con signo.

**03 → Problema: Pila con vaciado.**

- **Pista 2 — patrón:** **simulación directa con análisis amortizado**: cada elemento sale como mucho una vez, así que sacar uno a uno es `O(q)` en total.
- **Pista 3 — diseño:** una pila en un arreglo; `M k` saca `min(k, tamaño)` elementos sumándolos en 64 bits; no hace falta ninguna estructura especial, porque el trabajo total de todos los `M` está acotado por el número de `P`.

**03 → Problema: Implement Queue using Stacks.**

- **Pista 2 — patrón:** **dos pilas** con volcado perezoso, `O(1)` amortizado.
- **Pista 3 — diseño:** apila en `entrada`; para `pop` y `peek`, si `salida` está vacía, vuelca toda `entrada` en ella; después opera sobre la cima de `salida`.

**03 → Problema: Maximum Element.**

- **Pista 2 — patrón:** **pila de pares** (valor, máximo hasta aquí).
- **Pista 3 — diseño:** al apilar `x`, guarda junto a él `max(x, máximo de la cima anterior)`; la consulta del máximo es la segunda componente de la cima, en `O(1)`.

**03 → Problema: Fish.**

- **Pista 2 — patrón:** **pila** de peces que nadan corriente abajo; cada pez se apila y se desapila como mucho una vez.
- **Pista 3 — diseño:** recorre los peces; los que van río abajo se apilan; uno que va río arriba se come a los de la pila mientras sean más pequeños, y sobrevive si la vacía; al final sobreviven los de la pila más los que la vaciaron.

**03 → Problema: Min Stack.**

- **Pista 2 — patrón:** **pila auxiliar de mínimos**, o pares (valor, mínimo).
- **Pista 3 — diseño:** junto a cada valor guarda el mínimo de la pila hasta ese punto; `getMin` es el de la cima y `pop` lo restaura solo.

**03 → Problema: Queue using Two Stacks.**

- **Pista 2 — patrón:** **dos pilas** con volcado solo cuando la de salida está vacía.
- **Pista 3 — diseño:** el mismo diseño que la cola con pilas: encolar apila en la de entrada; desencolar e imprimir el frente operan sobre la de salida, volcando antes si está vacía. Con la entrada grande, usa E/S rápida.

**03 → Problema: Online Stock Span.**

- **Pista 2 — patrón:** **pila monótona** de (precio, tramo), decreciente.
- **Pista 3 — diseño:** al llegar un precio, desapila mientras la cima tenga precio menor o igual, sumando sus tramos al tramo actual (que empieza en 1); apila el precio con su tramo. Cada precio se apila y desapila una vez.

**03 → Problema: Daily Temperatures.**

- **Pista 2 — patrón:** **pila monótona** de índices con temperaturas decrecientes.
- **Pista 3 — diseño:** recorre los días; mientras el día actual sea más cálido que el de la cima, la respuesta de la cima es la diferencia de índices y se desapila; después apila el actual. Los que quedan en la pila al final tienen respuesta 0.

**03 → Problema: StoneWall.**

- **Pista 2 — patrón:** **pila monótona** de alturas de bloques abiertos.
- **Pista 3 — diseño:** para cada altura, desapila mientras la cima sea mayor; si la cima es igual, el bloque continúa y no cuenta; si no, apila la altura y cuenta un bloque nuevo.

**03 → Problema: Nearest Smaller Values.**

- **Pista 2 — patrón:** **pila monótona** creciente de posiciones.
- **Pista 3 — diseño:** recorre de izquierda a derecha; desapila mientras la cima tenga valor mayor o igual que el actual; la respuesta es la posición de la cima (o 0 si está vacía); apila la posición actual.

**03 → Problema: Sum of Subarray Minimums.**

- **Pista 2 — patrón:** **contribución de cada elemento** con dos pilas monótonas: a la izquierda y a la derecha.
- **Pista 3 — diseño:** para cada `i`, cuenta los subarreglos donde `arr[i]` es el mínimo: `(i − izquierda) · (derecha − i)`, con el menor estricto a un lado y el menor o igual al otro para no contar dos veces los empates; suma `arr[i]` por eso, módulo `10⁹ + 7`.

**03 → Problema: Largest Rectangle in Histogram.**

- **Pista 2 — patrón:** **pila monótona** creciente de índices: al desapilar una barra se conoce su extensión máxima.
- **Pista 3 — diseño:** recorre las barras (con una barra de altura 0 al final); mientras la actual sea menor que la de la cima, desapila: la altura es la de la barra desapilada y el ancho va desde el nuevo tope de la pila más uno hasta la posición actual menos uno; guarda el área máxima.

---

# 04 — Corrección: invariante de bucle, inducción y argumento de intercambio

**04 → 1.** ¿Cuáles son las tres partes de un invariante de bucle? 🟢

⏱️ **30 segundos.** Inicialización: es cierto antes de la primera vuelta. Mantenimiento: si es cierto antes de una vuelta, lo sigue siendo después. Terminación: al salir, junto con la condición de salida, implica el resultado.

🗣️ **2 minutos.** Es una inducción sobre el número de vueltas: la inicialización es el caso base y el mantenimiento el paso. La tercera parte conecta el invariante con la postcondición: en la búsqueda binaria, el invariante más `lo = hi` dice que `lo` es exactamente la frontera.

🔬 **El detalle.** CLRS llama «terminación» a la tercera parte, pero que el bucle **termine** es otra prueba, con una función de cota. Un invariante perfecto en un bucle infinito no demuestra nada.

**04 → 2.** ¿Qué es una función de cota y para qué sirve? 🟢

⏱️ **30 segundos.** Una cantidad entera y no negativa que baja estrictamente en cada vuelta del bucle. Sirve para demostrar que el bucle termina.

🗣️ **2 minutos.** Si una cantidad entera empieza en un valor finito, nunca es negativa y baja al menos uno por vuelta, el bucle da como mucho ese número de vueltas. En la búsqueda binaria es `hi − lo`, que baja porque `mid` está en `[lo, hi)` y cada rama excluye a `mid` del intervalo o lo usa como nuevo `hi`.

🔬 **El detalle.** El fallo clásico de terminación en la búsqueda binaria es `lo = mid` con `mid = (lo + hi) / 2` redondeando hacia abajo: con `hi = lo + 1`, `mid = lo` y el intervalo no cambia. La función de cota lo detecta: no baja.

**04 → 3.** Enuncia el esquema del argumento de intercambio en cuatro pasos. 🟢

⏱️ **30 segundos.** Toma una óptima; busca la primera decisión en que difiere del voraz; cámbiala por la del voraz y demuestra que sigue siendo válida y no peor; repite hasta convertirla en la voraz.

🗣️ **2 minutos.** El paso clave es el 3: el intercambio tiene que preservar la validez (por ejemplo, no crear solapamientos) y no empeorar el valor. Cada intercambio hace que la óptima coincida con la voraz en una decisión más, así que tras un número finito de pasos son iguales, y la voraz es óptima.

🔬 **El detalle.** Una variante equivalente es «el voraz va por delante»: demostrar por inducción que tras `k` decisiones el voraz está al menos tan bien como cualquier otra solución. Kleinberg y Tardos, §4.1, usan las dos con la selección de intervalos.

**04 → 4.** ¿Qué diferencia hay entre corrección parcial y corrección total? 🟡

⏱️ **30 segundos.** La parcial dice que, **si** termina, el resultado es correcto; la total añade que termina siempre.

🗣️ **2 minutos.** El invariante de bucle y la inducción, sin más, dan corrección parcial. La total pide además la terminación: una función de cota en los bucles, un tamaño que baja en la recursión. Un algoritmo parcialmente correcto que a veces no termina da TLE en el juez, no WA.

🔬 **El detalle.** La distinción importa más de lo que parece en búsquedas binarias y en bucles con dos punteros, donde un índice que no avanza en un borde convierte una prueba de corrección parcial impecable en un bucle infinito.

**04 → 5.** ¿Qué diferencia hay entre inducción débil y fuerte, y cuál pide un algoritmo que se llama con `n/2`? 🟡

⏱️ **30 segundos.** La débil supone `P(n − 1)` para probar `P(n)`; la fuerte supone `P(k)` para todo `k < n`. Un algoritmo que se llama con `n/2` necesita la fuerte.

🗣️ **2 minutos.** La exponenciación rápida llama a `power(x, ⌊n/2⌋)`, no a `power(x, n − 1)`: para probar `P(n)` hay que suponer que la llamada con `⌊n/2⌋` es correcta, y eso es la hipótesis fuerte. Las dos formas son equivalentes en poder, pero la fuerte es la natural para la recursión.

🔬 **El detalle.** La forma más cómoda de usarla en algoritmos es «inducción sobre el tamaño de la entrada»: el caso base son los tamaños donde no hay llamada recursiva, y el paso supone correctas todas las llamadas, que tienen tamaño menor.

**04 → 6.** Compara lo que devuelven `std::lower_bound`, `Arrays.binarySearch` y `bisect_left` cuando el valor no está. ¿Qué contrato cumple cada una? 🟡

⏱️ **30 segundos.** `std::lower_bound` devuelve el iterador al primer elemento `≥ x` (el final si no hay); `bisect_left` devuelve el índice equivalente; `Arrays.binarySearch` devuelve **algún** índice si está, y si no, `−(punto de inserción) − 1`.

🗣️ **2 minutos.** C++ y Python tienen el contrato del «primer `≥ x`», que sirve para insertar manteniendo el orden y para contar. Java promete encontrar **un** índice con ese valor, sin decir cuál si hay repetidos, y codifica el punto de inserción en un negativo para no confundirlo con un índice válido.

🔬 **El detalle.** Para «el primer índice» en Java hay que escribir la búsqueda propia (§3) o ajustar el resultado de `binarySearch` recorriendo, lo que con muchos repetidos es lineal. Es la razón por la que el corpus da su propia plantilla en [`05/04`](../05-orden-y-busqueda/04-busqueda-binaria.md).

**04 → 7.** ¿Por qué el voraz «la reunión más corta primero» no es correcto? Da el contraejemplo mínimo. 🟠

⏱️ **30 segundos.** Porque la reunión más corta puede solaparse con dos que, juntas, caben. Con `[0,5) [4,6) [5,10)`, elige `[4,6)` y descarta las otras dos; el óptimo es `[0,5)` y `[5,10)`.

🗣️ **2 minutos.** El argumento de intercambio falla: si la óptima no contiene la más corta, cambiar una de sus reuniones por la más corta puede crear un solapamiento con otra, porque ser corta no dice nada de dónde termina. Lo que sí funciona es «la que termina antes», porque el intercambio solo puede liberar tiempo.

🔬 **El detalle.** Buscar el contraejemplo con tres intervalos es el primer paso ante cualquier voraz: si con tres o cuatro no aparece, se intenta la prueba; si aparece, se descarta el voraz. El *stress test* de [`01/05`](../01-oficio-del-competidor/05-probar-sin-ide-y-stress-test.md) contra la fuerza bruta de subconjuntos lo encuentra solo.

**04 → 8.** En la partición de §3, ¿por qué el invariante sigue siendo cierto cuando `i = j` y se intercambia un elemento consigo mismo? 🟠

⏱️ **30 segundos.** Porque cuando `i = j`, la zona de mayores o iguales `[i, j)` está vacía, y el intercambio de `a[j]` consigo mismo no mueve nada: la zona de menores crece en uno y la otra sigue vacía.

🗣️ **2 minutos.** El invariante dice `a[0..i) < p` y `a[i..j) ≥ p`. Si `i = j` y `a[j] < p`, tras el intercambio y `i++` queda `a[0..j] < p` y `[i, j+1)` vacío: las dos partes se cumplen. El caso aparece al principio, mientras todos los elementos vistos son menores.

🔬 **El detalle.** Es un caso borde típico de las pruebas: el invariante tiene que cubrir las zonas vacías. Si lo escribes con intervalos semiabiertos, las zonas vacías no necesitan tratamiento especial.

**04 → 9.** ¿Por qué `hi = n − 1` con condición `lo < hi` no puede devolver `n`, y qué parte del invariante falla? 🟠

⏱️ **30 segundos.** Porque con `hi = n − 1` el intervalo de búsqueda nunca incluye la posición `n`, y la respuesta «todos son menores» no se puede representar. Falla la inicialización: no es cierto que `a[n−1..n)` sea `≥ x`.

🗣️ **2 minutos.** El invariante del primer `≥ x` exige que todo índice `≥ hi` tenga valor `≥ x`. Con `hi = n − 1` eso afirma que `a[n−1] ≥ x` antes de mirar nada, que es falso cuando `x` es mayor que todos. El bucle termina con `lo = hi ≤ n − 1` y devuelve un índice cuyo valor es menor que `x`.

🔬 **El detalle.** Hay versiones correctas con intervalo cerrado `[lo, hi]` y condición `lo ≤ hi`, pero su invariante es otro y su resultado se lee de otra variable. El error es mezclar la inicialización de una convención con la condición de la otra.

**04 → 10.** ¿Por qué un comparador escrito como `(p, q) -> p[1] - q[1]` puede romper una ordenación, y qué propiedad de un orden viola? 🟠

⏱️ **30 segundos.** Porque `p[1] − q[1]` desborda cuando los valores son grandes y de signo opuesto, y el signo del resultado deja de reflejar el orden. Viola la consistencia que exige un orden: puede decir `a < b`, `b < c` y `c < a`.

🗣️ **2 minutos.** Un comparador tiene que definir un orden total consistente: antisimétrico y transitivo. Con `2·10⁹ − (−2·10⁹)` la resta da la vuelta en `int` y sale negativa, así que el comparador afirma que el mayor es menor. La ordenación, que confía en la transitividad, puede devolver un arreglo mal ordenado o, en Java, lanzar «*Comparison method violates its general contract*».

🔬 **El detalle.** La forma correcta es `Integer.compare(p[1], q[1])` o `Comparator.comparingInt`. En C++, el comparador de `std::sort` además tiene que ser un orden estricto (`<`, nunca `<=`): con `<=` la ordenación puede salirse del arreglo ([`03/02`](../03-biblioteca-estandar/02-cpp-algoritmos-ranges-y-pbds.md)).

**04 → 11.** Escribe el invariante de la ordenación por inserción y demuestra que se mantiene en cada vuelta del bucle exterior. 🔴

⏱️ **30 segundos.** Invariante: al empezar la vuelta `j`, `a[0..j)` contiene los mismos elementos que había al principio en esas posiciones, ordenados. Al insertar `a[j]` en su sitio, `a[0..j]` queda ordenado con los mismos elementos.

🗣️ **2 minutos.** Inicialización: con `j = 1`, `a[0..1)` tiene un elemento y está ordenado. Mantenimiento: la vuelta guarda `a[j]`, desplaza una posición a la derecha los elementos de `a[0..j)` mayores que él y lo coloca en el hueco; como `a[0..j)` estaba ordenado, los desplazados son un sufijo contiguo, y el resultado `a[0..j]` está ordenado y contiene los mismos elementos. Terminación: con `j = n`, todo el arreglo está ordenado.

🔬 **El detalle.** El bucle interno tiene su propio invariante: los elementos entre la posición del hueco y `j` son mayores que el valor guardado. Y la condición «mayores» estricta, no «mayores o iguales», es la que hace la ordenación estable. CLRS, 3.ª ed., §2.1.

**04 → 12.** Demuestra por inducción que la exponenciación rápida devuelve `xⁿ` y que termina. 🔴

⏱️ **30 segundos.** Caso base: `power(x, 0) = 1 = x⁰`. Paso, con inducción fuerte: si `power(x, ⌊n/2⌋) = x^{⌊n/2⌋}`, para `n` par devuelve `(x^{n/2})² = xⁿ` y para `n` impar `(x^{(n−1)/2})² · x = xⁿ`. Termina porque `⌊n/2⌋ < n` para `n ≥ 1`.

🗣️ **2 minutos.** La hipótesis que se usa es sobre `⌊n/2⌋`, no sobre `n − 1`: por eso es inducción fuerte. La aritmética es `2·⌊n/2⌋ = n` si `n` es par y `n − 1` si es impar. La terminación es la función de cota «el exponente», que baja estrictamente y no es negativa; además da la profundidad, `⌊log₂ n⌋ + 1` llamadas.

🔬 **El detalle.** La prueba es sobre los enteros matemáticos. Con tipos de tamaño fijo la «corrección» además exige que nada desborde, que es otra prueba: con módulo, cada producto de restos tiene que caber en 64 bits ([`01/04`](../01-oficio-del-competidor/04-tipos-desbordamiento-y-modulo.md)).

**04 → 13.** Demuestra por contradicción que encontrar el mínimo de `n` elementos por comparaciones exige `n − 1` comparaciones en el caso peor. 🔴

⏱️ **30 segundos.** Cada comparación declara perdedor como mucho a un elemento. Con menos de `n − 1` comparaciones, al menos dos elementos nunca perdieron, y el algoritmo no puede saber cuál de los dos es el mínimo: un adversario puede hacer menor al que no eligió.

🗣️ **2 minutos.** Supón un algoritmo que siempre acierta con menos de `n − 1` comparaciones. El mínimo nunca pierde una comparación, y todo elemento que no es el mínimo tiene que haber perdido alguna para que el algoritmo lo descarte con certeza. Si dos elementos `u` y `v` no perdieron nunca y el algoritmo devuelve `u`, se puede bajar el valor de `v` por debajo de todos sin cambiar el resultado de ninguna comparación hecha (`v` solo ganó las suyas). El algoritmo devolvería `u`, que ya no es el mínimo: contradicción.

🔬 **El detalle.** El argumento es de adversario: el adversario responde a las comparaciones de forma coherente y construye la entrada al final. La cota es ajustada: el recorrido lineal hace exactamente `n − 1`. La cota de `Ω(n log n)` para ordenar (`05/01`) usa la misma idea con un árbol de decisión.

**04 → Problema: Último índice no mayor.**

- **Pista 2 — patrón:** **búsqueda binaria con invariante semiabierto**; «el último `≤ x`» es «el primero `> x`» menos uno.
- **Pista 3 — diseño:** invariante `a[0..lo) ≤ x` y `a[hi..n) > x`, con `lo = 0` y `hi = n`; si `a[mid] ≤ x`, `lo = mid + 1`, si no, `hi = mid`; al salir, la respuesta es `lo − 1`, que vale `−1` cuando ninguno cumple.

**04 → Problema: Pinchar todas las reuniones.**

- **Pista 2 — patrón:** **voraz por el final**, con argumento de intercambio.
- **Pista 3 — diseño:** ordena por final; lanza un aviso en el final de la primera reunión no cubierta y marca cubiertas todas las que empiezan en ese minuto o antes; repite. El intercambio: cualquier aviso que cubra la primera reunión se puede mover a su final sin dejar de cubrir nada de lo que cubría.

**04 → Problema: Contraejemplo de monedas.**

- **Pista 2 — patrón:** **comparar el voraz con el óptimo** para cada cantidad pequeña; el óptimo sale de una tabla de mínimo de monedas ([`12/03`](../12-dp-clasica/03-mochilas.md)).
- **Pista 3 — diseño:** calcula `mínimo[v]` para `v` hasta la suma de las dos monedas mayores con `mínimo[v] = 1 + min sobre monedas c ≤ v de mínimo[v − c]`; calcula el número de monedas del voraz para cada `v`; la respuesta es el primer `v` donde difieren, o 0.

**04 → Problema: Binary Search.**

- **Pista 2 — patrón:** **búsqueda binaria** con su invariante.
- **Pista 3 — diseño:** con `[lo, hi)` semiabierto, busca el primer índice `≥ target` y comprueba si su valor es `target`; o con `[lo, hi]` cerrado y `lo ≤ hi`, devolviendo en cuanto `nums[mid] == target`.

**04 → Problema: First Bad Version.**

- **Pista 2 — patrón:** **búsqueda binaria de frontera** sobre un predicado monótono.
- **Pista 3 — diseño:** invariante «antes de `lo` todas buenas, desde `hi` todas malas», con `lo = 1` y `hi = n`; `mid = lo + (hi − lo)/2` para no desbordar (aquí `n` llega a `2³¹ − 1`).

**04 → Problema: Remove Element.**

- **Pista 2 — patrón:** **dos índices con invariante de zonas**.
- **Pista 3 — diseño:** un índice de escritura `k`: invariante «`nums[0..k)` son los conservados»; recorre y copia en `k` cada valor distinto de `val`; devuelve `k`.

**04 → Problema: Assign Cookies.**

- **Pista 2 — patrón:** **voraz con intercambio**: la galleta más pequeña que sirve al niño menos exigente.
- **Pista 3 — diseño:** ordena niños y galletas; con dos punteros, si la galleta actual satisface al niño actual, asígnala y avanza los dos; si no, avanza solo la galleta.

**04 → Problema: Sort Colors.**

- **Pista 2 — patrón:** **partición en tres zonas** (bandera holandesa) con su invariante.
- **Pista 3 — diseño:** tres índices `lo`, `mid`, `hi`: invariante `[0, lo)` ceros, `[lo, mid)` unos, `(hi, n)` doses; según `nums[mid]`, intercambia con `lo` y avanza los dos, avanza `mid`, o intercambia con `hi` y retrocede `hi` **sin** avanzar `mid`.

**04 → Problema: Correctness and the Loop Invariant.**

- **Pista 2 — patrón:** **invariante de la ordenación por inserción** y su caso borde.
- **Pista 3 — diseño:** el bucle interno tiene que poder llegar a la posición 0; la condición que lo para antes es el error que el problema esconde.

**04 → Problema: Insertion Sort - Part 2.**

- **Pista 2 — patrón:** **ordenación por inserción** con su invariante de prefijo ordenado.
- **Pista 3 — diseño:** para cada `i` desde 1, inserta `arr[i]` en el prefijo ordenado desplazando los mayores, e imprime el arreglo tras cada vuelta.

**04 → Problema: Dominator.**

- **Pista 2 — patrón:** **voto de Boyer-Moore** y comprobación.
- **Pista 3 — diseño:** candidato y contador con el invariante «descartar parejas de valores distintos conserva el dominante»; al final, cuenta las apariciones del candidato para confirmar que pasa de `n/2` y devuelve un índice suyo, o `−1`.

**04 → Problema: TieRopes.**

- **Pista 2 — patrón:** **voraz**: cerrar el grupo en cuanto alcanza `K`.
- **Pista 3 — diseño:** acumula longitudes consecutivas; cuando la suma llega a `K` o más, cuenta una cuerda y reinicia la suma. El intercambio: cerrar antes nunca deja peor a lo que viene detrás.

**04 → Problema: EquiLeader.**

- **Pista 2 — patrón:** **líder global y prefijos de conteo**: si las dos partes tienen el mismo líder, es el líder del total.
- **Pista 3 — diseño:** encuentra el líder del total y su número de apariciones; recorre los cortes llevando cuántas veces aparece a la izquierda; el corte vale si aparece más de la mitad en cada parte.

**04 → Problema: Lemonade Change.**

- **Pista 2 — patrón:** **voraz con argumento**: para dar 15, primero el billete de 10.
- **Pista 3 — diseño:** cuenta billetes de 5 y de 10; con 20, devuelve 10 + 5 si puedes, y si no, tres de 5; los de 5 son más versátiles, por eso se guardan.

**04 → Problema: Tasks and Deadlines.**

- **Pista 2 — patrón:** **argumento de intercambio** sobre el orden: las tareas más cortas primero.
- **Pista 3 — diseño:** la recompensa total es `Σ plazos − Σ momentos de fin`; el primer término es fijo y el segundo se minimiza ordenando por duración (intercambiar dos vecinas mal ordenadas reduce la suma); usa 64 bits.

---

# 05 — El coste real

**05 → 1.** ¿Qué es una línea de caché y cuánto mide en la mayoría de los procesadores x86? 🟢

⏱️ **30 segundos.** Es el bloque de tamaño fijo en que la memoria se mueve entre la RAM y la caché. En la mayoría de los procesadores x86 mide 64 bytes.

🗣️ **2 minutos.** Cuando lees un `int`, no se trae solo ese valor: se trae la línea entera, 16 `int` contiguos. Si los siguientes accesos son a esos vecinos, ya están en caché. Por eso un recorrido secuencial usa cada transferencia entera y uno con saltos grandes desperdicia casi todo.

🔬 **El detalle.** Los Apple M usan líneas de 128 bytes. El tamaño afecta también a la concurrencia: dos hilos que escriben variables distintas en la misma línea se estorban (*false sharing*), aunque no compartan datos.

**05 → 2.** ¿Qué diferencia hay entre localidad espacial y temporal? 🟢

⏱️ **30 segundos.** Espacial: si accedes a una dirección, pronto accederás a las cercanas. Temporal: si accedes a un dato, pronto volverás a él.

🗣️ **2 minutos.** La espacial la aprovecha la línea de caché: recorrer un arreglo de izquierda a derecha la tiene. La temporal la aprovecha el tamaño de la caché: un bucle que trabaja una y otra vez sobre un bloque pequeño de datos lo mantiene en L1.

🔬 **El detalle.** Las optimizaciones de caché clásicas atacan una u otra: recorrer en el orden de la memoria (espacial) y partir el trabajo en bloques que quepan en la caché (temporal, el *blocking* de la multiplicación de matrices).

**05 → 3.** ¿Cuántos bytes ocupa aproximadamente un `int` en un `int[]` y en una `ArrayList<Integer>` de Java? 🟢

⏱️ **30 segundos.** 4 bytes en un `int[]`; unos 20 en una `ArrayList<Integer>`: unos 16 del objeto `Integer` y la referencia que guarda la lista.

🗣️ **2 minutos.** El `Integer` tiene una cabecera de objeto (unos 12 bytes con punteros comprimidos) más los 4 del valor, alineado a 16. La lista guarda además una referencia de 4 bytes (con punteros comprimidos) u 8. Total, unas cinco veces el `int`, y con los objetos dispersos por el *heap*.

🔬 **El detalle.** Las cifras exactas dependen de la JVM y de sus opciones; lo que importa es el orden: varias veces más memoria y un acceso indirecto por elemento. Los valores de −128 a 127 se comparten por la caché de `Integer.valueOf`, así que una lista de valores pequeños gasta algo menos.

**05 → 4.** ¿Qué diferencia hay entre el modelo de la regla de `10⁸` operaciones y el modelo de memoria externa, en qué cuentan? 🟡

⏱️ **30 segundos.** La regla de `10⁸` cuenta operaciones; el modelo de memoria externa cuenta transferencias de bloques entre una memoria rápida y pequeña y otra lenta y grande.

🗣️ **2 minutos.** En el primero, recorrer por filas o por columnas cuesta lo mismo: `n²` sumas. En el segundo, por filas cuesta `n²/B` transferencias y por columnas, con la matriz grande, `n²`. El modelo de memoria externa explica la diferencia que la regla de `10⁸` no ve.

🔬 **El detalle.** El modelo nació para el disco, donde la diferencia entre acceso secuencial y aleatorio es enorme, y es el que justifica los árboles B y la ordenación externa. Para la caché, la misma idea vale con bloques de 64 bytes.

**05 → 5.** ¿Por qué `int[][]` en Java recorrido por columnas es aún peor que una matriz contigua de C++ recorrida por columnas? 🟡

⏱️ **30 segundos.** Porque en Java cada fila es un arreglo independiente en el *heap*: al recorrer por columnas, además de saltar de línea en cada acceso, se sigue un puntero distinto para cada fila.

🗣️ **2 minutos.** En C++, una matriz aplanada es un solo bloque: el salto entre `a[i][j]` y `a[i+1][j]` es de `n` elementos, regular, y el procesador al menos puede predecirlo. En Java, `m[i+1]` es una referencia a otro arreglo que puede estar en cualquier sitio; cada acceso por columnas es una indirección y un posible fallo de caché.

🔬 **El detalle.** Por eso, cuando el rendimiento importa en Java, también se aplana: un `int[]` de `n·m` con índice `i * m + j`. Las filas como arreglos separados tienen la ventaja de permitir filas de distinto tamaño.

**05 → 6.** ¿Por qué `==` entre dos `Integer` funciona con 100 y falla con 1000? 🟡

⏱️ **30 segundos.** Porque `==` compara referencias, y `Integer.valueOf` reutiliza los objetos de −128 a 127: con 100, las dos variables apuntan al mismo objeto; con 1000, a dos objetos distintos.

🗣️ **2 minutos.** El *autoboxing* llama a `Integer.valueOf`, que devuelve un objeto de una caché para los valores pequeños y uno nuevo para el resto. `a == b` con dos `Integer` compara si son el mismo objeto, no si valen lo mismo. Funciona con valores pequeños por casualidad.

🔬 **El detalle.** La comparación correcta es `a.equals(b)` o desempaquetar uno de los dos (`a.intValue() == b`). El rango alto de la caché se puede ampliar con una opción de la JVM, así que el comportamiento ni siquiera es fijo entre ejecuciones: otra razón para no depender de él ([`03/03`](../03-biblioteca-estandar/03-java-colecciones.md)).

**05 → 7.** Compara cómo representan una lista de un millón de enteros C++, Java y Python, y qué cuesta recorrerla en cada uno. 🟡

⏱️ **30 segundos.** C++ guarda un millón de `int` contiguos, 4 MB; Java con `ArrayList<Integer>` guarda un millón de referencias a objetos dispersos, unos 20 MB; Python guarda un millón de punteros a objetos `int`, más de 30 MB. Recorrerlos cuesta en ese orden.

🗣️ **2 minutos.** En C++ el recorrido es secuencial y la precarga lo hace casi gratis. En Java, cada elemento es una indirección y un desempaquetado. En Python, además de la indirección, cada iteración del bucle ejecuta varias operaciones del intérprete. Con `int[]` Java se acerca a C++; con `sum()` Python evita el bucle del intérprete.

🔬 **El detalle.** Los números son órdenes de magnitud y dependen de la versión y de la máquina. La tabla de equivalencias entre los tres lenguajes, con sus costes, está en [`03/05`](../03-biblioteca-estandar/05-equivalencias-entre-lenguajes.md).

**05 → 8.** «La lista enlazada inserta en `O(1)`». ¿Cuándo es cierto, y por qué en la práctica un arreglo suele ganar al insertar en el medio? 🟠

⏱️ **30 segundos.** Es cierto si ya tienes el nodo donde insertar: enlazar es `O(1)`. Pero encontrar la posición es `O(n)` de accesos dispersos, y un arreglo encuentra la posición al instante y desplaza memoria contigua, que es muy rápido.

🗣️ **2 minutos.** Insertar en mitad de un arreglo de `n` elementos mueve `n/2` elementos contiguos con una copia que la caché y el procesador hacen muy deprisa. Insertar en mitad de una lista exige recorrer `n/2` nodos, cada uno un posible fallo de caché de unos 100 ns. Con la misma complejidad lineal, el arreglo gana por mucho.

🔬 **El detalle.** La lista enlazada sí gana cuando ya se tiene una referencia al nodo por otra vía, como en una caché LRU con un mapa que apunta a los nodos ([`06/02`](../06-lineales-y-hashing/02-listas-enlazadas.md)), o cuando los elementos no se pueden mover de sitio.

**05 → 9.** Tu solución Java `Θ(n log n)` con `n = 10⁶` da TLE usando `ArrayList<Integer>` y `Collections.sort`. ¿Qué cambias primero, y por qué no la complejidad? 🟠

⏱️ **30 segundos.** La representación: paso a `int[]` y `Arrays.sort`. La complejidad ya es la correcta; lo que sobra es la constante del *boxing* y de ordenar objetos.

🗣️ **2 minutos.** Un millón de `Integer` son un millón de objetos, y `Collections.sort` los compara llamando a `compareTo` sobre referencias dispersas. Con `int[]` los valores están contiguos y la ordenación de primitivos no crea objetos. También reviso la E/S, que con `10⁶` valores es la otra causa típica ([`01/03`](../01-oficio-del-competidor/03-entrada-salida-y-plantilla.md)).

🔬 **El detalle.** `Arrays.sort(int[])` es un *quicksort* de doble pivote que en Java 21 cambia a *heapsort* si la recursión se hace demasiado profunda, así que es `O(n log n)` en el caso peor; en Java 8 y 11 no tenía ese respaldo y había entradas adversarias que lo hacían cuadrático. Si el juez corre una versión antigua, se baraja antes de ordenar (`03/03`).

**05 → 10.** ¿Por qué el recorrido contiguo de `N` elementos cuesta `Θ(N/B)` transferencias en el modelo de memoria externa y el recorrido con salto grande cuesta `Θ(N)`? 🟠

⏱️ **30 segundos.** Porque en el contiguo cada bloque transferido sirve a `B` accesos seguidos; con salto de `B` o más, cada acceso cae en un bloque distinto, y si los datos no caben en la memoria rápida, ese bloque ya no está cuando se vuelve.

🗣️ **2 minutos.** El recorrido contiguo de `N` elementos toca `⌈N/B⌉` bloques, y cada uno se trae una vez. El de salto grande toca un bloque por acceso, `N` en total; para reutilizar un bloque haría falta que siguiera en la memoria rápida hasta la próxima vuelta, y con `N` mucho mayor que `M` ya fue desalojado.

🔬 **El detalle.** El factor entre los dos es `B`, que con líneas de 64 bytes y `int` es 16. En la práctica la precarga y los niveles intermedios suavizan la diferencia, pero el orden de magnitud se ve.

**05 → 11.** En el *buddy system*, ¿por qué el compañero de un bloque de tamaño `2ᵏ` en la dirección `a` está en `a XOR 2ᵏ`? 🔴

⏱️ **30 segundos.** Porque los bloques de tamaño `2ᵏ` están alineados a múltiplos de `2ᵏ`, y los dos compañeros salen de partir un bloque de `2^{k+1}`: solo difieren en el bit `k` de la dirección. `XOR 2ᵏ` cambia exactamente ese bit.

🗣️ **2 minutos.** Un bloque de tamaño `2^{k+1}` alineado empieza en una dirección cuyo bit `k` es 0; al partirlo, la mitad baja empieza ahí y la alta en esa dirección más `2ᵏ`, que tiene el bit `k` a 1. Dado cualquiera de los dos, invertir el bit `k` da el otro. Por eso el compañero se calcula sin buscar.

🔬 **El detalle.** La alineación es el invariante del *buddy system*: todo bloque de tamaño `2ᵏ` empieza en un múltiplo de `2ᵏ`. Se mantiene al partir (las dos mitades quedan alineadas a su tamaño) y al fusionar (solo se fusionan compañeros, cuyo bloque padre está alineado).

**05 → 12.** Tienes que calcular el máximo de cada columna de una matriz enorme que se genera fila a fila. Diseña el recorrido para que sea amigable con la caché y di cuánta memoria usa. 🔴

⏱️ **30 segundos.** Genero la matriz fila a fila y mantengo un arreglo `maxCol` de `m` posiciones: cada valor de la fila actualiza el máximo de su columna. Recorro la memoria en orden y uso `O(m)` memoria, sin guardar la matriz.

🗣️ **2 minutos.** El recorrido «natural» del enunciado sería por columnas, que con una matriz guardada por filas salta en cada acceso. Pero el máximo por columna se puede acumular en cualquier orden: al procesar la fila `i`, cada `a[i][j]` actualiza `maxCol[j]`. Tanto la generación de la fila como `maxCol` se recorren de forma contigua.

🔬 **El detalle.** Es el patrón de cambiar el orden de los bucles para seguir la memoria (*loop interchange*), y el problema propio «Máximos por columna» de este capítulo. La memoria baja de `n·m` a `m`, que con `5000 × 5000` es la diferencia entre 100 MB y 20 KB.

**05 → Problema: Líneas de caché tocadas.**

- **Pista 2 — patrón:** **aritmética de direcciones**: el acceso `j` está en el byte `j·k·e`, y su línea es ese byte dividido por `L`.
- **Pista 3 — diseño:** sea `m = ⌈n/k⌉` el número de accesos y `s = k·e` el salto en bytes; si `s ≥ L`, cada acceso toca una línea distinta y la respuesta es `m`; si no, las líneas tocadas son todas las de `0` a `⌊(m−1)·s / L⌋`, sin huecos. Con `n` hasta `10¹²`, el producto cabe en 64 bits.

**05 → Problema: Máximos por columna.**

- **Pista 2 — patrón:** **intercambio del orden de los bucles** para recorrer la memoria en orden, sin guardar la matriz.
- **Pista 3 — diseño:** un arreglo `maxCol` de `m` enteros; para cada fila `i` y cada columna `j`, calcula `a[i][j]` en 64 bits y actualiza `maxCol[j]`; al final, suma `maxCol` en 64 bits (llega a `m·P ≈ 5·10¹²`).

**05 → Problema: Asignador por compañeros.**

- **Pista 2 — patrón:** ***buddy system*** con una lista de bloques libres por tamaño, ordenada por dirección.
- **Pista 3 — diseño:** para cada orden `k` de `0` a `K`, un conjunto ordenado de direcciones libres; para asignar, busca el menor orden `≥` el pedido con algún bloque, toma la menor dirección y pártela bajando de orden (la mitad alta vuelve a los libres). Para liberar, mientras el compañero `dirección XOR 2ᵏ` esté en los libres del mismo orden, quítalo, fusiona (la dirección es el mínimo de los dos) y sube de orden.

**05 → Problema: 2D Array - DS.**

- **Pista 2 — patrón:** **recorrido de matriz por filas** con una ventana fija de 3×3.
- **Pista 3 — diseño:** para cada esquina superior izquierda `(i, j)` con `i, j ≤ 3`, suma las siete celdas del reloj de arena y guarda el máximo; empieza el máximo con un valor menor que cualquier suma posible, porque hay negativos.

**05 → Problema: Transpose Matrix.**

- **Pista 2 — patrón:** **recorrido doble** donde el origen y el destino tienen órdenes opuestos.
- **Pista 3 — diseño:** crea la matriz `n × m` y asigna `t[j][i] = a[i][j]`; recorrer el origen por filas escribe el destino por columnas, y al revés; con matrices pequeñas da igual, con grandes conviene hacerlo por bloques.

**05 → Problema: Rotate Image.**

- **Pista 2 — patrón:** **composición de dos transformaciones en el sitio**: transponer y reflejar.
- **Pista 3 — diseño:** transpone intercambiando `a[i][j]` con `a[j][i]` para `j > i`, y después invierte cada fila; o rota por capas, moviendo cuatro elementos a la vez.

**05 → Problema: Spiral Matrix.**

- **Pista 2 — patrón:** **recorrido con cuatro fronteras** que se estrechan.
- **Pista 3 — diseño:** mantén `top`, `bottom`, `left`, `right`; recorre la fila de arriba, la columna derecha, la fila de abajo y la columna izquierda, estrechando la frontera correspondiente tras cada lado, y comprueba que no se han cruzado antes de los lados tercero y cuarto.

**05 → Problema: Set Matrix Zeroes.**

- **Pista 2 — patrón:** **usar la propia matriz como memoria auxiliar**: la primera fila y la primera columna como marcas.
- **Pista 3 — diseño:** guarda aparte si la primera fila y la primera columna tenían ceros; marca en ellas las filas y columnas a anular; anula el resto según las marcas; al final, anula la primera fila y columna si hacía falta.

**05 → Problema: Range Sum Query 2D - Immutable.**

- **Pista 2 — patrón:** **prefijos en dos dimensiones** ([`04/01`](../04-secuencias/01-prefijos-y-diferencias.md)), construidos por filas.
- **Pista 3 — diseño:** `P[i][j]` es la suma del rectángulo `[0, i) × [0, j)`; se construye con `P[i+1][j+1] = a[i][j] + P[i][j+1] + P[i+1][j] − P[i][j]`; cada consulta es una inclusión-exclusión de cuatro valores.

**05 → Problema: Concert Tickets.**

- **Pista 2 — patrón:** **conjunto ordenado con repetidos** (el mayor precio `≤` la oferta), que en Java es un `TreeMap` de conteos.
- **Pista 3 — diseño:** para cada cliente, `floorKey(oferta)`; si existe, vende ese billete y decrementa su conteo, borrando la clave al llegar a 0. En Java, con `2·10⁵` claves y E/S rápida entra; con E/S lenta o estructuras de objetos de más, no.

**05 → Problema: Traffic Lights.**

- **Pista 2 — patrón:** **procesar al revés**: quitar semáforos en vez de ponerlos, con un arreglo ordenado y la mayor distancia entre vecinos.
- **Pista 3 — diseño:** pon todos los semáforos, ordena las posiciones y calcula el mayor hueco; recorre los semáforos en orden inverso de colocación, anotando el mayor hueco antes de quitar cada uno y actualizándolo con el hueco que se fusiona. Usa una lista doblemente enlazada sobre arreglos de índices, sin objetos.

**05 → Problema: Room Allocation.**

- **Pista 2 — patrón:** **montículo de habitaciones por hora de salida**, con los clientes ordenados por llegada.
- **Pista 3 — diseño:** ordena los clientes por llegada; mantén un montículo de mínimos con `(salida, habitación)`; si la habitación que sale antes ya está libre a la llegada, reutilízala, si no, abre una nueva. En Java, codifica `(salida, habitación)` en un `long` para no crear objetos.

---

# 06 — Tipos abstractos de datos

**06 → 1.** ¿Qué es un tipo abstracto de datos y qué lo distingue de una estructura de datos? 🟢

⏱️ **30 segundos.** Un TDA es un contrato: un conjunto de operaciones y lo que promete cada una, sin decir cómo se representa. Una estructura de datos es una forma concreta de cumplirlo, con su representación y su coste.

🗣️ **2 minutos.** «Cola» es un TDA: encolar al final, desencolar el primero. El arreglo circular y la lista enlazada son estructuras que lo implementan. El cliente programa contra el contrato y no depende de la representación, así que la implementación se puede cambiar sin tocar el cliente.

🔬 **El detalle.** El contrato no fija el coste, y por eso el mismo programa puede ser cuadrático o lineal según la implementación, como la cola con `remove(0)` de §1. En la práctica, las librerías documentan el coste junto al contrato, y forma parte de lo que el cliente espera.

**06 → 2.** ¿Qué es el invariante de representación de una implementación? 🟢

⏱️ **30 segundos.** Es la condición que la representación cumple siempre entre operaciones, y que cada operación tiene que conservar.

🗣️ **2 minutos.** En el arreglo circular: `0 ≤ size ≤ capacidad`, `head` dentro del arreglo, y los elementos en las `size` posiciones desde `head` con vuelta. Si alguna operación lo rompe, las demás ya no funcionan, aunque cada una por separado parezca correcta. El constructor lo establece y cada operación lo mantiene.

🔬 **El detalle.** Escribirlo encima de la clase es lo que permite demostrar la corrección con el teorema de §2, y comprobarlo con una aserción en cada operación es una de las herramientas de depuración más baratas que hay.

**06 → 3.** ¿Qué diferencia hay entre una precondición y una postcondición, con un ejemplo de la cola? 🟡

⏱️ **30 segundos.** La precondición es lo que tiene que ser cierto al llamar a la operación; la postcondición, lo que es cierto después. `dequeue` tiene como precondición que la cola no esté vacía, y como postcondición que devuelve el primero y la cola queda sin él.

🗣️ **2 minutos.** El contrato reparte la responsabilidad: si el cliente llama a `dequeue` con la cola vacía, la culpa es del cliente; si la cola devuelve otro elemento que el primero, es de la implementación. En código, la precondición violada suele convertirse en una excepción (`NoSuchElementException`).

🔬 **El detalle.** El principio de sustitución dice que una implementación puede **debilitar** las precondiciones (aceptar más) y **fortalecer** las postcondiciones (prometer más), nunca al revés. `ArrayDeque.poll` debilita la precondición de `dequeue`: con la cola vacía devuelve `null` en vez de fallar.

**06 → 4.** ¿Qué diferencia hay entre el invariante de representación y la función de abstracción? 🟡

⏱️ **30 segundos.** El invariante dice qué representaciones son válidas; la función de abstracción dice qué valor abstracto representa cada representación válida.

🗣️ **2 minutos.** En el arreglo circular, el invariante es `0 ≤ size ≤ capacidad` y `head` en rango; la función de abstracción lee la secuencia `data[head], data[head+1], …` con vuelta, `size` elementos. Muchas representaciones distintas dan el mismo valor: la cola `⟨2, 9⟩` puede estar con `head = 1` o con `head = 3`.

🔬 **El detalle.** Para probar una operación se usan las dos: partiendo de una representación válida (invariante), hay que llegar a otra válida cuya abstracción sea la que pide la postcondición. Es el esquema del teorema de §2.

**06 → 5.** ¿Qué diferencia hay entre `List` y `ArrayList` en Java, y por qué se declara la variable con la primera? 🟡

⏱️ **30 segundos.** `List` es la interfaz, el contrato de una secuencia indexada; `ArrayList` es una implementación con arreglo dinámico. Se declara con `List` para poder cambiar la implementación sin tocar el resto del código.

🗣️ **2 minutos.** `List<Integer> xs = new ArrayList<>()` deja que el resto del código use solo el contrato. Si mañana conviene otra implementación, se cambia el `new`. Si se declara `ArrayList`, el código puede acabar usando métodos propios de esa clase (`ensureCapacity`) y la sustitución ya no es gratis.

🔬 **El detalle.** Las implementaciones de `List` tienen costes muy distintos: `get(i)` es `O(1)` en `ArrayList` y `O(n)` en `LinkedList`. Por eso Java marca con la interfaz `RandomAccess` las listas con acceso por índice rápido, para que los algoritmos genéricos elijan cómo recorrerlas.

**06 → 6.** Compara cómo expresan el contrato de una cola Java, C++ y Python: interfaz, adaptador y *duck typing*. 🟡

⏱️ **30 segundos.** Java declara el contrato con una interfaz (`Queue`, `Deque`) que las clases implementan; C++ usa un adaptador, `std::queue`, que impone el contrato sobre un contenedor elegido como parámetro de plantilla; Python usa *duck typing*: cumple el contrato quien tenga los métodos.

🗣️ **2 minutos.** En Java la sustitución es en tiempo de ejecución, por polimorfismo. En C++ es en compilación: `std::queue<int, std::deque<int>>` funciona con cualquier contenedor que tenga `push_back`, `pop_front`, `front` y `back`, sin llamadas virtuales. En Python, `collections.deque` es la cola y nadie declara nada, aunque `collections.abc` permite declararlo si se quiere.

🔬 **El detalle.** Desde C++20 existen los *concepts*, que permiten escribir el contrato de un parámetro de plantilla de forma explícita y con errores de compilación legibles. Es la forma moderna de lo que antes era implícito.

**06 → 7.** ¿Por qué `grow()` en el arreglo circular copia en orden lógico y no el arreglo tal cual? 🟠

⏱️ **30 segundos.** Porque la posición de cada elemento depende de la capacidad: con la nueva capacidad, `(head + i) mod cap` ya no apunta al mismo sitio. Copiar en orden lógico y poner `head = 0` restablece el invariante.

🗣️ **2 minutos.** Si la cola ha dado la vuelta (`head` en mitad del arreglo y los últimos elementos al principio), copiar el arreglo tal cual a uno más grande deja los elementos del principio separados de los del final por el hueco nuevo. La función de abstracción leería basura en ese hueco. Copiar `data[(head + i) mod cap]` a `bigger[i]` reconstruye la secuencia contigua desde 0.

🔬 **El detalle.** `ArrayDeque` de Java resuelve lo mismo copiando los dos tramos con `System.arraycopy`, que es más rápido que el bucle con módulo; el resultado es el mismo invariante.

**06 → 8.** ¿Por qué `Stack` no es una buena pila en Java, y qué contrato rompe? 🟠

⏱️ **30 segundos.** Porque `Stack` hereda de `Vector`: además de `push` y `pop` permite acceder e insertar por índice, que no forman parte del contrato de una pila, y todas sus operaciones son sincronizadas, lo que las hace más lentas sin necesidad.

🗣️ **2 minutos.** Una pila solo debería permitir tocar la cima. `Stack` deja hacer `add(0, x)` o `get(i)`, y un cliente puede romper el orden LIFO sin darse cuenta. La documentación de Java recomienda usar `Deque` (con `ArrayDeque`) para una pila, que solo expone las operaciones de los extremos.

🔬 **El detalle.** Es un caso clásico de herencia mal usada: una pila «es un» vector según la jerarquía de clases, pero no según el contrato. La versión correcta compone: una pila **tiene** un arreglo, no **es** un arreglo.

**06 → 9.** Un problema necesita insertar, borrar y «el menor elemento mayor o igual que `x`». ¿Qué TDA es, y por qué una tabla *hash* no sirve? 🟠

⏱️ **30 segundos.** Es un diccionario ordenado (o conjunto ordenado): necesita la operación «sucesor», el menor `≥ x`. Una tabla *hash* no guarda orden y no puede responder eso sin recorrerlo todo.

🗣️ **2 minutos.** La tabla *hash* reparte las claves por cubetas según su *hash*, que destruye el orden a propósito; encontrar el menor `≥ x` exige mirar todas las claves, `O(n)`. Un árbol balanceado (`TreeSet.ceiling` en Java, `std::set::lower_bound` en C++) lo da en `O(log n)`, junto con la inserción y el borrado.

🔬 **El detalle.** Python no tiene conjunto ordenado en la librería estándar; las alternativas son un arreglo ordenado con `bisect` (inserción `O(n)`) o escribir un árbol. Es el problema propio «Agenda con siguiente».

**06 → 10.** En `LinkedQueue`, ¿qué invariante se rompe si se omite `if (head == null) tail = null`, y con qué secuencia de operaciones falla? 🟠

⏱️ **30 segundos.** Se rompe «`tail` es el último nodo, o `null` si la cola está vacía». Falla con `enqueue`, `dequeue`, `enqueue`: tras vaciar, `tail` apunta al nodo viejo, y el nuevo se enlaza a él en vez de convertirse en la cabeza.

🗣️ **2 minutos.** Tras `enqueue(5)` y `dequeue()`, `head` es `null` pero `tail` sigue apuntando al nodo del 5. El siguiente `enqueue(2)` ve `tail != null`, hace `tail.next = nodo` y mueve `tail`, pero `head` sigue en `null`. La cola tiene un elemento según `size` y `peek` lanza una excepción o devuelve basura.

🔬 **El detalle.** Es el patrón típico de los errores de invariante: el caso general funciona y el borde (cola que se vacía) no. Una aserción del invariante al final de cada operación lo detecta en la primera ejecución.

**06 → 11.** Demuestra, con el teorema de §2, que `RingBufferQueue` es una implementación correcta de la cola: escribe el invariante y comprueba que `enqueue` y `dequeue` lo conservan. 🔴

⏱️ **30 segundos.** Invariante: `0 ≤ size ≤ data.length`, `0 ≤ head < data.length`, y la cola abstracta es `data[(head + i) % data.length]` para `i` en `[0, size)`. El constructor lo establece con `size = 0`; `enqueue` escribe en la posición `size` lógica y suma uno; `dequeue` avanza `head` y resta uno.

🗣️ **2 minutos.** `enqueue(x)`: si `size == data.length`, `grow` copia en orden lógico a un arreglo doble con `head = 0`, y el invariante se conserva con la misma secuencia; después se escribe en la posición lógica `size`, que es `(head + size) % cap`, y la abstracción pasa a ser la secuencia anterior con `x` al final. `dequeue()`: con la precondición `size > 0`, devuelve `data[head]`, que es el primero; `head` avanza con módulo y `size` baja: la abstracción es la secuencia sin su primero.

🔬 **El detalle.** Los rangos se conservan: `head` sigue en `[0, cap)` por el módulo, y `size` no pasa de `cap` porque `grow` actúa antes. La inducción sobre la secuencia de operaciones del teorema de §2 completa la prueba.

**06 → 12.** Diseña un TDA con `insert(x)`, `remove(x)` y `getRandom()` en `O(1)` esperado: elige la representación, escribe su invariante y explica `remove`. 🔴

⏱️ **30 segundos.** Un arreglo con los valores y un mapa de valor a su índice en el arreglo. `getRandom` elige un índice al azar; `remove(x)` mueve el último elemento al hueco de `x`, actualiza su índice en el mapa y acorta el arreglo.

🗣️ **2 minutos.** Invariante: el mapa contiene exactamente los valores del arreglo, y para cada valor `v`, `arreglo[mapa[v]] = v`. `insert` añade al final y registra el índice. `remove` es el truco: borrar del medio de un arreglo es `O(n)`, pero si el orden no importa, se sobrescribe con el último y se quita el último, que es `O(1)`, y solo hay que actualizar el índice del elemento movido.

🔬 **El detalle.** Es un ejemplo de componer dos TDA para que cada uno cubra lo que el otro no puede: el mapa da la búsqueda en `O(1)` esperado, el arreglo da el acceso por posición que necesita la elección al azar. El cuidado está en el orden de las actualizaciones cuando `x` es justo el último.

**06 → 13.** Diseña una caché que guarde como mucho `k` pares clave-valor y, al llenarse, expulse el usado hace más tiempo, con `get` y `put` en `O(1)`. Di qué dos TDA compones y el invariante que los une. 🔴

⏱️ **30 segundos.** Un diccionario de clave a nodo, más una lista doblemente enlazada ordenada por uso. `get` mueve el nodo al frente; `put` inserta al frente y, si se pasa de `k`, expulsa el del final y lo borra del diccionario.

🗣️ **2 minutos.** Invariante: el diccionario y la lista tienen exactamente las mismas claves; la lista está ordenada de más reciente a menos reciente, y su tamaño no pasa de `k`. La lista doble permite quitar un nodo de cualquier posición en `O(1)` si se tiene su referencia, y el diccionario es lo que da esa referencia sin recorrer.

🔬 **El detalle.** Es el caso en que la lista enlazada sí gana a un arreglo (`02/05`): el diccionario resuelve el «encontrar el nodo», que es lo que la lista hace mal. En Java, `LinkedHashMap` con orden de acceso y `removeEldestEntry` ya implementa este contrato.

**06 → Problema: Cola de turnos.**

- **Pista 2 — patrón:** **TDA cola** con una implementación `O(1)` por operación: arreglo circular o la deque de la librería.
- **Pista 3 — diseño:** `ArrayDeque` en Java, `std::queue` en C++, `collections.deque` en Python; o un arreglo de tamaño `q` con dos índices, cabeza y final, que solo avanzan. Con E/S rápida, porque son `2·10⁵` líneas.

**06 → Problema: Agenda con siguiente.**

- **Pista 2 — patrón:** **conjunto ordenado** con la operación sucesor.
- **Pista 3 — diseño:** `TreeSet` con `ceiling(x)` en Java, `std::set` con `lower_bound(x)` en C++; en Python, si todas las operaciones se conocen de antemano, se pueden comprimir los valores y usar un árbol de Fenwick o un árbol de segmentos sobre la presencia ([`09/02`](../09-consultas-sobre-rangos/02-fenwick.md)).

**06 → Problema: El más frecuente.**

- **Pista 2 — patrón:** **componer dos TDA**: un diccionario de conteos y un conjunto ordenado de pares `(conteo, valor)`.
- **Pista 3 — diseño:** al meter o sacar `x`, quita del conjunto el par `(conteo viejo, x)` e inserta `(conteo nuevo, x)` si es mayor que 0; ordena los pares por conteo descendente y valor ascendente, y `M` es el primero del conjunto, o `-1` si está vacío.

**06 → Problema: Design HashSet.**

- **Pista 2 — patrón:** **implementar un contrato** con la representación más simple que cumple las cotas.
- **Pista 3 — diseño:** con claves hasta `10⁶`, un arreglo de booleanos indexado por la clave cumple las tres operaciones en `O(1)`; la versión general es un arreglo de cubetas con listas.

**06 → Problema: Design HashMap.**

- **Pista 2 — patrón:** **tabla *hash* con encadenamiento** (`06/03`).
- **Pista 3 — diseño:** un arreglo de cubetas, cada una con una lista de pares `(clave, valor)`; la cubeta es `clave mod número de cubetas`; `put` actualiza si la clave existe en su cubeta y si no añade; `remove` la quita de la lista.

**06 → Problema: Implement Stack using Queues.**

- **Pista 2 — patrón:** **un TDA sobre otro**: reordenar la cola en cada inserción.
- **Pista 3 — diseño:** al hacer `push(x)`, encola `x` y rota la cola pasando al final los `n − 1` elementos anteriores, para que `x` quede al frente; así `pop` y `top` son el frente de la cola. `push` es `O(n)`.

**06 → Problema: Jesse and Cookies.**

- **Pista 2 — patrón:** **cola de prioridad** (montículo de mínimos).
- **Pista 3 — diseño:** mete todas las galletas en un montículo de mínimos; mientras la menor sea menor que `k` y haya al menos dos, saca las dos menores, mete la combinada y cuenta una operación; si queda una sola y sigue por debajo, la respuesta es `−1`. Los valores combinados pueden pasar de 32 bits.

**06 → Problema: Design Circular Queue.**

- **Pista 2 — patrón:** **arreglo circular** con su invariante de representación.
- **Pista 3 — diseño:** guarda `head` y `size` (no `head` y `tail`): llena es `size == k` y vacía `size == 0`, sin ambigüedad; el final es `(head + size − 1) mod k`.

**06 → Problema: Design Browser History.**

- **Pista 2 — patrón:** **elegir la representación** del contrato «atrás, adelante, visitar»: un arreglo con un índice actual y un límite.
- **Pista 3 — diseño:** un arreglo de páginas, el índice actual y el índice de la última página válida; visitar escribe en `actual + 1` y fija ese como el último válido (borra el «adelante»); atrás y adelante mueven el actual dentro de `[0, último]`.

**06 → Problema: Time Based Key-Value Store.**

- **Pista 2 — patrón:** **diccionario de clave a lista ordenada** por tiempo, con búsqueda binaria.
- **Pista 3 — diseño:** como los `set` llegan con marcas crecientes, cada clave guarda una lista de `(marca, valor)` ya ordenada; `get` busca con binaria la última marca `≤` la pedida.

**06 → Problema: Simple Text Editor.**

- **Pista 2 — patrón:** **pila de estados** o de operaciones inversas para deshacer.
- **Pista 3 — diseño:** guarda en una pila, por cada operación de añadir o borrar, lo necesario para revertirla (cuántos caracteres quitar, o qué texto devolver); deshacer desapila y aplica la inversa. Construye el texto con un `StringBuilder` para no copiar cadenas.

**06 → Problema: Kth Largest Element in a Stream.**

- **Pista 2 — patrón:** **cola de prioridad acotada** a `k` elementos.
- **Pista 3 — diseño:** un montículo de mínimos con como mucho `k` elementos; al añadir, mete y, si pasa de `k`, saca el mínimo; la respuesta es el mínimo del montículo.

**06 → Problema: Design Linked List.**

- **Pista 2 — patrón:** **lista enlazada con nodo centinela** y su invariante de tamaño.
- **Pista 3 — diseño:** un nodo ficticio antes del primero hace que insertar en la posición 0 sea igual que en cualquier otra; lleva `size` para validar índices; para llegar a la posición `i`, avanza `i` nodos desde el centinela.

**06 → Problema: Snapshot Array.**

- **Pista 2 — patrón:** **componer TDA**: por cada posición, un historial de `(instantánea, valor)` ordenado.
- **Pista 3 — diseño:** cada índice guarda una lista de pares con el número de instantánea en que cambió y el valor; `snap` solo incrementa un contador; `get(i, s)` busca con binaria el último cambio de `i` con instantánea `≤ s`.

**06 → Problema: Find Median from Data Stream.**

- **Pista 2 — patrón:** **dos colas de prioridad**: un montículo de máximos con la mitad baja y uno de mínimos con la alta.
- **Pista 3 — diseño:** invariante: todo elemento de la mitad baja es `≤` que todo elemento de la alta, y los tamaños difieren como mucho en uno; al añadir, mete en la baja, pasa su máximo a la alta, y si la alta queda mayor, devuelve su mínimo a la baja; la mediana sale de las cimas.

---

# 07 — Simulación

**07 → S1.** ¿Qué diferencia hay entre decir que un algoritmo es `O(n²)` y decir que es `Θ(n²)`? 🟢

⏱️ **30 segundos.** `O(n²)` es solo un techo: el algoritmo no crece más rápido que `n²`. `Θ(n²)` dice además que no crece más despacio: es exactamente cuadrático.

🗣️ **2 minutos.** Un algoritmo lineal también es `O(n²)`, y decirlo es cierto e inútil. Cuando se describe el coste de un algoritmo se quiere decir casi siempre `Θ`. `O` sin más tiene sentido cuando solo se conoce el techo o cuando el coste varía según la entrada y se da la cota del caso peor.

🔬 **El detalle.** Las definiciones con sus constantes están en [`02/01`](01-notacion-asintotica.md), §2; la regla del límite decide entre las dos en una línea.

**07 → S2.** ¿Qué caso das cuando te preguntan cuánto cuesta buscar en un `HashMap`, y qué añades? 🟢

⏱️ **30 segundos.** `O(1)` esperado con una buena función *hash*. Y añado el caso peor: `O(n)` por operación si las claves colisionan, u `O(log n)` en Java desde la 8 con claves comparables.

🗣️ **2 minutos.** El «esperado» depende de que las claves se repartan bien por las cubetas. Con una función *hash* fija, un adversario puede elegir claves que caigan todas juntas. La defensa es aleatorizar el *hash* o usar una estructura con garantía de caso peor.

🔬 **El detalle.** Los *anti-hash tests* y cómo se aleatoriza en cada lenguaje son de `06/03`. En una entrevista, la respuesta completa en una línea es «`O(1)` esperado, `O(n)` en el caso peor».

**07 → S3.** ¿Por qué `Σ_{i=1}^{n} ⌊n/i⌋` es `Θ(n log n)` y no `Θ(n²)`? 🟡

⏱️ **30 segundos.** Porque el término `⌊n/i⌋` decrece: `n + n/2 + n/3 + … + 1 = n · H(n)`, y el número armónico `H(n)` es `Θ(log n)`.

🗣️ **2 minutos.** Si cada término fuera `n`, serían `n²`; pero solo el primero lo es. La suma de `1/i` hasta `n` se acota por arriba con `1 + ∫₁ⁿ dx/x = 1 + ln n`, y por abajo con `ln(n + 1)`. Multiplicando por `n`, `Θ(n log n)`.

🔬 **El detalle.** Es el patrón de recorrer los múltiplos de cada número, que aparece en la criba de Eratóstenes (`17/04`) y en el problema propio «Bucles con raíz» de esta simulación.

**07 → S4.** Un algoritmo aleatorizado tiene caso esperado `Θ(n log n)` y caso peor `Θ(n²)`. ¿Puede un caso de prueba adversario forzar el caso peor? 🟠

⏱️ **30 segundos.** No de forma fiable: el caso esperado vale para toda entrada porque el azar lo pone el algoritmo, y el caso de prueba no lo controla. El peor caso sigue existiendo, pero con probabilidad ínfima.

🗣️ **2 minutos.** La diferencia con un algoritmo determinista es que ahí el adversario elige la entrada que lo hace cuadrático; con azar, la misma entrada da el caso malo solo si los números aleatorios salen mal, y eso no depende de quien diseña la prueba.

🔬 **El detalle.** La garantía se rompe si el azar es predecible: una semilla fija conocida, o un generador que el adversario puede reproducir. Por eso los *hashes* aleatorizados se siembran con algo del momento de ejecución.

**07 → S5.** Resuelve `T(n) = 4T(n/2) + n²` y `T(n) = 4T(n/2) + n`. 🟢

⏱️ **30 segundos.** `4T(n/2) + n²` es `Θ(n² log n)` (caso 2); `4T(n/2) + n` es `Θ(n²)` (caso 1).

🗣️ **2 minutos.** Con `a = 4` y `b = 2`, `p = log₂ 4 = 2`. En la primera, `f(n) = n² = nᵖ`: caso 2, `Θ(n² log n)`. En la segunda, `f(n) = n` es polinómicamente menor que `n²`: caso 1, mandan las hojas, `Θ(n²)`.

🔬 **El detalle.** La segunda es la multiplicación de números por divide y vencerás con cuatro productos: no gana nada frente a la escolar. Karatsuba baja `a` a 3 y el exponente a `log₂ 3` ([`02/02`](02-recurrencias-y-teorema-maestro.md)).

**07 → S6.** ¿Por qué la exponenciación rápida tiene que hacer una sola llamada recursiva y no dos? 🟡

⏱️ **30 segundos.** Porque con dos llamadas la recurrencia es `2T(n/2) + O(1)`, que es `Θ(n)`; con una es `T(n/2) + O(1)`, que es `Θ(log n)`.

🗣️ **2 minutos.** Escribir `power(x, n/2) * power(x, n/2)` calcula dos veces lo mismo y el árbol se ramifica hasta tener `n` hojas. Guardar el resultado de una llamada y elevarlo al cuadrado deja un árbol de un solo camino de profundidad `log n`.

🔬 **El detalle.** Es el mismo principio que la memoización: no recalcular un subproblema que ya se resolvió. En el teorema maestro, lo que cambia es `a`, que pasa de 2 a 1.

**07 → S7.** ¿Qué recurrencia tiene una búsqueda que descarta un tercio en cada paso, y cuánto vale? 🟡

⏱️ **30 segundos.** `T(n) = T(2n/3) + O(1)`, que es `Θ(log n)`: el teorema maestro con `a = 1`, `b = 3/2` y caso 2.

🗣️ **2 minutos.** Si cada paso descarta un tercio y sigue con los dos tercios restantes, el tamaño se multiplica por `2/3` en cada paso, y llega a 1 tras `log_{3/2} n` pasos. `p = log_{3/2} 1 = 0` y `f(n) = 1 = n⁰`: caso 2, `Θ(log n)`.

🔬 **El detalle.** Cualquier fracción constante descartada da `Θ(log n)`; solo cambia la base, que es una constante. Es la idea de la búsqueda ternaria sobre funciones unimodales ([`05/05`](../05-orden-y-busqueda/05-ternaria-y-exponencial.md)).

**07 → S8.** Una recursión parte en `n/3` y `2n/3` y combina en lineal. ¿Por qué no puedes usar el teorema maestro y qué usas? 🟠

⏱️ **30 segundos.** Porque el teorema maestro pide subproblemas del mismo tamaño. Uso el árbol de recursión, que da `Θ(n log n)`, o Akra-Bazzi.

🗣️ **2 minutos.** En el árbol, cada nivel completo suma `n`, porque los tamaños de los subproblemas de un nivel suman `n`. La rama más corta tiene `log₃ n` niveles y la más larga `log_{3/2} n`. El total queda entre `n log₃ n` y `n log_{3/2} n`. Akra-Bazzi lo confirma: `(1/3)ᵖ + (2/3)ᵖ = 1` da `p = 1` y la integral da `log n`.

🔬 **El detalle.** Es la recurrencia del problema propio «Recurrencia desequilibrada» de esta simulación, que además pide el valor exacto.

**07 → S9.** ¿Por qué el `push_back` de un arreglo dinámico es `O(1)` amortizado y no `O(1)`? 🟢

⏱️ **30 segundos.** Porque un `push_back` suelto puede copiar todo el arreglo, `O(n)`; pero como la capacidad crece por un factor, las copias de toda la secuencia suman `O(n)`, y el coste por operación es `O(1)` amortizado.

🗣️ **2 minutos.** Con duplicación, las copias son `1 + 2 + 4 + … < 2n` para `n` operaciones. El amortizado es una garantía sobre la secuencia: ninguna secuencia de `n` operaciones cuesta más de `3n`. No dice nada de una operación aislada.

🔬 **El detalle.** El estándar de C++ exige el amortizado y no fija el factor; libstdc++ duplica. Los métodos para demostrarlo son de `02/03`.

**07 → S10.** ¿Qué potencial usarías para la pila con vaciado múltiple, y qué amortizado da cada operación? 🟡

⏱️ **30 segundos.** El número de elementos de la pila. `push` cuesta `1 + 1 = 2` amortizado, y `pop` y `multipop`, `0`.

🗣️ **2 minutos.** `push` cuesta 1 real y sube el potencial en 1. `multipop(k)` saca `k'` elementos, cuesta `k'` real y baja el potencial en `k'`: amortizado 0. Como el potencial empieza en 0 y nunca es negativo, `n` operaciones cuestan como mucho `2n`.

🔬 **El detalle.** Es el método contable con el crédito sumado: cada elemento lleva el 1 que pagará su salida, y el potencial es el total de esos créditos.

**07 → S11.** Un bucle `while` interno saca elementos de una pila dentro de un `for` de `n` vueltas. ¿Cómo justificas que el total es `O(n)`? 🟠

⏱️ **30 segundos.** Por el método agregado: cada elemento se apila una vez y se desapila como mucho una vez, así que todas las vueltas del `while`, sumadas, no pasan de `n`.

🗣️ **2 minutos.** Acotar el `while` por su caso peor en cada vuelta del `for` daría `n²`. Pero cada vuelta del `while` saca un elemento distinto, y solo se metieron `n`. El total del `while` es `≤ n` y el del `for`, `n`: `O(n)`.

🔬 **El detalle.** Es el argumento de todas las pilas monótonas ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)) y de los dos punteros ([`04/02`](../04-secuencias/02-dos-punteros-y-ventana.md)). En una entrevista se dice así: «cada elemento entra y sale una vez».

**07 → S12.** Escribe el invariante de la búsqueda del primer índice con `a[i] ≥ x`. 🟢

⏱️ **30 segundos.** Todo índice menor que `lo` tiene valor menor que `x`, y todo índice mayor o igual que `hi` tiene valor mayor o igual que `x`.

🗣️ **2 minutos.** Con `lo = 0` y `hi = n` es cierto por vacío. Si `a[mid] < x`, `lo = mid + 1` lo mantiene; si no, `hi = mid` lo mantiene. Al salir, `lo = hi`, y el invariante dice que es exactamente la frontera: el primer índice con valor `≥ x`, o `n`.

🔬 **El detalle.** El intervalo semiabierto `[lo, hi)` es lo que permite devolver `n` cuando todos son menores. La plantilla anotada está en [`02/04`](04-correccion-invariantes-induccion-intercambio.md) y en los tres lenguajes en `05/04`.

**07 → S13.** ¿Qué parte de la prueba de un bucle demuestra que termina, y qué la demuestra en la búsqueda binaria? 🟡

⏱️ **30 segundos.** La función de cota: una cantidad entera, no negativa, que baja estrictamente en cada vuelta. En la búsqueda binaria es `hi − lo`.

🗣️ **2 minutos.** El invariante da corrección parcial: si termina, acierta. La terminación es aparte. En la búsqueda binaria, `mid` está en `[lo, hi)`, así que `lo = mid + 1` sube `lo` y `hi = mid` baja `hi`: en las dos ramas `hi − lo` disminuye.

🔬 **El detalle.** Con `lo = mid` en vez de `mid + 1`, y `mid` redondeado hacia abajo, la cota no baja cuando `hi = lo + 1` y el bucle es infinito. La función de cota lo detecta antes que el juez.

**07 → S14.** Da el contraejemplo mínimo del voraz «la reunión que empieza antes». 🟡

⏱️ **30 segundos.** `[0,10) [1,2) [3,4)`: el voraz toma `[0,10)` y descarta las otras dos; el óptimo son `[1,2)` y `[3,4)`.

🗣️ **2 minutos.** Empezar antes no dice nada de cuánto tiempo ocupa la reunión: una que empieza la primera puede tapar todo el día. El voraz correcto elige la que **termina** antes, porque deja libre el mayor tiempo posible para las siguientes, y eso se demuestra por intercambio.

🔬 **El detalle.** El contraejemplo de «la más corta» también tiene tres reuniones: `[0,5) [4,6) [5,10)`. Los dos son el primer paso ante cualquier voraz: buscar el contraejemplo pequeño (`02/04`, §5).

**07 → S15.** ¿Por qué un algoritmo recursivo que se llama con `n/2` necesita inducción fuerte? 🟠

⏱️ **30 segundos.** Porque la hipótesis que necesita es sobre `n/2`, no sobre `n − 1`: hay que suponer cierta la propiedad para todos los tamaños menores, que es la inducción fuerte.

🗣️ **2 minutos.** La inducción débil solo permite usar `P(n − 1)` para probar `P(n)`. La función se llama con `⌊n/2⌋`, que no es `n − 1`. Con la fuerte, se supone `P(k)` para todo `k < n`, y en particular para `⌊n/2⌋`.

🔬 **El detalle.** Las dos inducciones son equivalentes en lo que pueden demostrar, pero la fuerte es la que encaja con la forma de los algoritmos recursivos: «suponiendo que las llamadas recursivas aciertan».

**07 → S16.** ¿Por qué recorrer una matriz por columnas es más lento que por filas, si hacen las mismas operaciones? 🟢

⏱️ **30 segundos.** Porque la matriz está guardada por filas: por filas se usa cada línea de caché entera, y por columnas cada acceso salta a una línea distinta.

🗣️ **2 minutos.** La memoria se mueve en líneas de 64 bytes. Recorriendo una fila, 16 `int` consecutivos llegan juntos. Recorriendo una columna, el siguiente elemento está `n` posiciones más allá, en otra línea, y con una matriz grande esa línea ya no estará cuando se vuelva a ella.

🔬 **El detalle.** En el modelo de memoria externa, `n²/B` transferencias frente a `n²`. El problema propio «Máximos por columna» de `02/05` lo resuelve cambiando el orden de los bucles.

**07 → S17.** ¿Qué TDA necesitas para «insertar, borrar y el menor elemento mayor que `x`», y qué implementación? 🟡

⏱️ **30 segundos.** Un diccionario o conjunto ordenado, con la operación sucesor. En Java, `TreeSet` con `higher(x)`; en C++, `std::set` con `upper_bound(x)`.

🗣️ **2 minutos.** El contrato pide insertar, borrar y sucesor, y las tres en `O(log n)` las da un árbol balanceado. Una tabla *hash* no tiene orden y no responde el sucesor sin recorrerlo todo.

🔬 **El detalle.** «Mayor que `x`» es `higher` en Java y `upper_bound` en C++; «mayor o igual», `ceiling` y `lower_bound`. Python no trae conjunto ordenado en la librería estándar (`03/04`).

**07 → S18.** ¿Por qué `LinkedList` no es la mejor cola en Java, si encola y desencola en `O(1)`? 🟠

⏱️ **30 segundos.** Porque `ArrayDeque` cumple el mismo contrato con un arreglo circular: contiguo, sin un objeto nodo por elemento y más rápido en la práctica.

🗣️ **2 minutos.** Las dos son `O(1)` por operación, pero `LinkedList` crea un nodo con dos referencias por cada elemento, dispersos por el *heap*, y recorrerla es seguir punteros. `ArrayDeque` guarda las referencias en un arreglo y solo copia al crecer, `O(1)` amortizado.

🔬 **El detalle.** La documentación de Java dice que `ArrayDeque` es probablemente más rápida que `LinkedList` usada como cola. `LinkedList` solo gana si hace falta borrar en mitad con un iterador.

**07 → S19.** Tu solución es `O(n log n)` con `n = 10⁶` en Java y da TLE. La complejidad es la correcta. ¿Qué miras primero? 🟠

⏱️ **30 segundos.** La constante: la E/S (`Scanner`, `println` en bucle) y la representación (`List<Integer>`, objetos en el montículo). Con `10⁶` elementos, cualquiera de las dos da TLE con la complejidad correcta.

🗣️ **2 minutos.** Primero la E/S, que es lo más frecuente y lo más barato de arreglar (`01/03`). Después el *boxing*: `int[]` y `Arrays.sort` en vez de colecciones de `Integer` (`02/05`). Por último, la recursión profunda, que en Java puede dar RE antes que TLE.

🔬 **El detalle.** Si con todo eso sigue sin entrar, se revisa si el `log n` viene de una estructura con mucha constante (un `TreeMap` con millones de operaciones) que se pueda cambiar por ordenar una vez y recorrer.

**07 → S20.** Te dicen «tu voraz pasa todos los ejemplos, ¿por qué no lo envías?». ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que pasar los ejemplos no demuestra nada: un voraz es correcto si tiene argumento de intercambio. Antes de enviar busco el contraejemplo pequeño, o lo pruebo contra una fuerza bruta.

🗣️ **2 minutos.** Los ejemplos del enunciado son pocos y del centro; los voraces que fallan lo hacen con configuraciones concretas de tres o cuatro elementos. Un *stress test* contra la fuerza bruta de subconjuntos con `n ≤ 10` encuentra el contraejemplo si existe; si no lo encuentra, escribo el intercambio.

🔬 **El detalle.** Es el problema propio «¿Falla el voraz?» de esta simulación: con `n ≤ 15`, la fuerza bruta da el óptimo exacto y el voraz se compara contra ella.

**07 → S21.** ¿Y si `n` fuera `10¹²`? Para «cuántas veces se ejecuta este doble bucle», ¿qué cambia? 🟠

⏱️ **30 segundos.** Que no puedo ejecutar el bucle: hay que contar sus vueltas con una fórmula. Si el doble bucle es armónico, hay que sumar `⌊n/i⌋` agrupando los `i` con el mismo cociente, en `O(√n)`.

🗣️ **2 minutos.** Con `n = 10¹²`, cualquier cosa lineal en `n` son `10¹²` pasos. La suma `Σ ⌊n/i⌋` toma solo unos `2√n` valores distintos: para cada cociente `q`, los `i` que lo dan forman un intervalo, y se suman de golpe. Además, el resultado pasa de `10¹³` y va en 64 bits.

🔬 **El detalle.** El problema propio «Bucles con raíz» corta el bucle exterior en `√n` y no necesita la agrupación; con el bucle completo hasta `n`, sí. La técnica de agrupar cocientes es de [`17/02`](../17-matematica/02-divisibilidad.md).

**07 → S22.** «Amortizado es lo mismo que promedio, ¿no?». Corrige la frase con un ejemplo donde la diferencia importe. 🔴

⏱️ **30 segundos.** No: el amortizado es una garantía de caso peor sobre toda una secuencia; el promedio depende de una distribución de entradas. Un `push_back` es `O(1)` amortizado para cualquier secuencia; la búsqueda lineal es `(n+1)/2` en promedio solo si la posición buscada es uniforme.

🗣️ **2 minutos.** La diferencia importa con entradas adversarias: un *quicksort* con pivote fijo es `n log n` en promedio sobre permutaciones aleatorias, y un caso de prueba ordenado lo hace cuadrático. El arreglo dinámico no tiene entrada mala: la cota de `3n` vale siempre.

🔬 **El detalle.** Lo que sí rompe el amortizado es necesitar una cota por operación: en un sistema con límite de latencia por petición, el `push_back` que copia todo es un pico, aunque el total sea lineal.

**07 → S23.** Demuestra que una cola implementada con dos pilas es correcta: el invariante que garantiza el orden y por qué se conserva. 🔴

⏱️ **30 segundos.** Invariante: todos los elementos de la pila de salida llegaron antes que todos los de la de entrada, y la cima de la de salida es el más antiguo. Se conserva porque solo se vuelca cuando la de salida está vacía, y el volcado invierte el orden.

🗣️ **2 minutos.** Encolar apila en la de entrada: el nuevo es el más reciente de todos, y el invariante se mantiene. Desencolar con la de salida no vacía saca su cima, el más antiguo. Si está vacía, se vuelca toda la de entrada: los más antiguos quedan arriba, y el invariante pasa a ser cierto antes de sacar.

🔬 **El detalle.** Volcar con la de salida no vacía rompería el invariante: elementos más nuevos quedarían encima de los más antiguos. La eficiencia, `O(1)` amortizado, sale del agregado: cada elemento se vuelca una sola vez.

**07 → Problema: Bucles con raíz.**

- **Pista 2 — patrón:** **conteo por filas**: el bucle interno da `⌊n/i⌋` vueltas, y el externo solo llega a `⌊√n⌋`.
- **Pista 3 — diseño:** suma `⌊n/i⌋` para `i` de 1 mientras `i·i ≤ n`, en 64 bits; son hasta `10⁶` vueltas y el resultado ronda `1,4·10¹³`. La condición `i·i ≤ n` con `n = 10¹²` cabe en 64 bits.

**07 → Problema: Recurrencia desequilibrada.**

- **Pista 2 — patrón:** **recursión con memoización** sobre un mapa: los argumentos distintos son pocos.
- **Pista 3 — diseño:** guarda en un mapa cada `T(m)` calculado; los argumentos que aparecen son de la forma `⌊n·(1/3)ᵃ·(2/3)ᵇ⌋` con pequeñas variaciones por los suelos, y con `n = 10¹²` son del orden de mil; la profundidad es `log_{3/2} n ≈ 70` y el resultado ronda `4·10¹³`, en 64 bits.

**07 → Problema: ¿Falla el voraz?.**

- **Pista 2 — patrón:** **fuerza bruta sobre subconjuntos** para el óptimo, y **simulación** del voraz.
- **Pista 3 — diseño:** para cada máscara de `0` a `2ⁿ − 1`, ordena los intervalos elegidos por inicio y comprueba que cada uno termina antes o justo cuando empieza el siguiente; guarda el mayor tamaño válido. Para el voraz, ordena por `(f − s, s)` y toma cada intervalo que no se solape con los tomados. `2¹⁵ · 15` comprobaciones caben de sobra.

**07 → Problema: Guess Number Higher or Lower.**

- **Pista 2 — patrón:** **búsqueda binaria** con un oráculo de comparación.
- **Pista 3 — diseño:** intervalo `[lo, hi]` con `lo = 1` y `hi = n`; el `mid` sin desbordar (`n` llega a `2³¹ − 1`); según la respuesta, descarta la mitad que no puede contener el número.

**07 → Problema: Insertion Sort - Part 1.**

- **Pista 2 — patrón:** **inserción en un prefijo ordenado**, con su invariante.
- **Pista 3 — diseño:** guarda el último valor; desplaza a la derecha los mayores que él, imprimiendo el arreglo tras cada desplazamiento; colócalo en el hueco y vuelve a imprimir. El borde: que tenga que ir a la posición 0.

**07 → Problema: Peak Index in a Mountain Array.**

- **Pista 2 — patrón:** **búsqueda binaria sobre un predicado monótono**: «`arr[i] < arr[i+1]`» es cierto antes de la cima y falso desde ella.
- **Pista 3 — diseño:** busca el primer `i` con `arr[i] > arr[i+1]`; invariante: antes de `lo` sube, desde `hi` baja; la respuesta es esa frontera.

**07 → Problema: Boats to Save People.**

- **Pista 2 — patrón:** **ordenar y dos punteros**, con argumento de intercambio.
- **Pista 3 — diseño:** ordena; el más pesado va en un bote, con el más ligero si caben juntos; si no, solo. Mueve los punteros y cuenta botes. Intercambio: si en una óptima el más pesado va con otro, cambiar a ese otro por el más ligero sigue siendo válido.

**07 → Problema: Count Primes.**

- **Pista 2 — patrón:** **criba de Eratóstenes**, `Θ(n log log n)`.
- **Pista 3 — diseño:** un arreglo de booleanos hasta `n`; para cada `p` primo con `p·p < n`, tacha sus múltiplos empezando en `p·p`; cuenta los no tachados a partir de 2.

**07 → Problema: My Calendar I.**

- **Pista 2 — patrón:** **diccionario ordenado** de reservas por inicio: solo la anterior y la siguiente pueden chocar.
- **Pista 3 — diseño:** guarda las reservas en un `TreeMap` de inicio a fin; para `[s, e)`, la anterior (`floorEntry(s)`) no puede terminar después de `s`, y la siguiente (`ceilingEntry(s)`) no puede empezar antes de `e`; si las dos cumplen, inserta.
