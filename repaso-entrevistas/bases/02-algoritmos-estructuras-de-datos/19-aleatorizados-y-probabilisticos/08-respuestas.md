# Respuestas — bloque 19: Aleatorizados y probabilísticos

> Solucionario del bloque `19`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--las-vegas-y-monte-carlo) · [02](#02--hashing-universal-y-análisis-esperado) · [03](#03--estructuras-probabilísticas) · [04](#04--muestreo-y-cadenas-de-markov) · [05](#05--estructuras-espaciales) · [06](#06--datos-masivos) · [07](#07--simulación)

---

# 01 — Las Vegas y Monte Carlo

**01 → 1.** ¿Qué diferencia hay entre un algoritmo Las Vegas y uno Monte Carlo? 🟢

⏱️ **30 segundos.** Las Vegas siempre acierta y su tiempo es aleatorio; Monte Carlo tiene el tiempo acotado y acierta con probabilidad al menos `1 − ε`.

🗣️ **2 minutos.** *Quicksort* con pivote aleatorio es Las Vegas: ordena siempre bien, en `Θ(n log n)` esperado. Freivalds es Monte Carlo: `Θ(n²)` por repetición, con error `1/2` que se amplifica.

🔬 **El detalle.** Un Las Vegas se corta en Monte Carlo con Markov; un Monte Carlo verificable se repite hasta acertar y se vuelve Las Vegas.

**01 → 2.** ¿Qué es un error unilateral, y qué algoritmo del capítulo lo tiene? 🟢

⏱️ **30 segundos.** El que solo se equivoca en un sentido: Freivalds y Miller-Rabin solo pueden decir «sí» por error.

🗣️ **2 minutos.** Si Freivalds rechaza, `AB ≠ C` seguro; si acepta, puede equivocarse. Si Miller-Rabin dice «compuesto», lo es; si dice «primo», puede no serlo.

🔬 **El detalle.** Con error unilateral, `k` repeticiones dan `εᵏ`; con bilateral hace falta votar por mayoría.

**01 → 3.** ¿Cuánto cuesta Freivalds y qué probabilidad de error tiene? 🟢

⏱️ **30 segundos.** `Θ(n²)` por repetición, con error unilateral `1/2`: `k` repeticiones, error `2⁻ᵏ`.

🗣️ **2 minutos.** Cada repetición son tres productos matriz-vector: `Br`, `A(Br)` y `Cr`. Con `n = 1 000`, unas `3·10⁶` operaciones frente a `10⁹`.

🔬 **El detalle.** Con `r` uniforme en un cuerpo de `p` elementos, en lugar de en `{0, 1}`, el error por repetición baja a `1/p`.

**01 → 4.** ¿Cómo se reduce el error de un Monte Carlo de error unilateral? 🟡

⏱️ **30 segundos.** Repitiendo con monedas independientes y respondiendo «no» si alguna repetición dice «no»: el error pasa de `ε` a `εᵏ`.

🗣️ **2 minutos.** Con `ε = 1/2`, 20 repeticiones dan menos de `10⁻⁶` y 60, unos `10⁻¹⁸`. El coste crece lineal en `k`; el error baja exponencial.

🔬 **El detalle.** Con error bilateral, el voto por mayoría y la cota de Chernoff dan una caída exponencial parecida.

**01 → 5.** ¿Qué diferencia hay entre el caso promedio de *quicksort* con pivote fijo y el esperado con pivote aleatorio? 🟡

⏱️ **30 segundos.** El caso promedio con pivote fijo promedia sobre las entradas; el esperado con pivote aleatorio promedia sobre los pivotes, para cada entrada.

🗣️ **2 minutos.** Con pivote fijo existe una entrada (la ordenada, con el último como pivote) que da `Θ(n²)` siempre. Con pivote aleatorio, ninguna entrada es mala: la esperanza es `2n ln n` para todas.

🔬 **El detalle.** Es la diferencia entre suponer algo sobre los datos y no suponer nada.

**01 → 6.** ¿Cómo se convierte un Las Vegas en Monte Carlo, y al revés? 🟡

⏱️ **30 segundos.** Las Vegas → Monte Carlo: cortarlo a los `c` veces su tiempo esperado (falla con probabilidad `≤ 1/c` por Markov). Monte Carlo → Las Vegas: repetir hasta que una verificación pase.

🗣️ **2 minutos.** La segunda conversión exige poder **verificar** la respuesta en tiempo razonable. El número esperado de repeticiones es `1/(1 − ε)`.

🔬 **El detalle.** Por eso los problemas cuya respuesta se verifica fácil (un factor, una solución de una ecuación) admiten Las Vegas.

**01 → 7.** ¿Por qué una semilla fija hace atacable un algoritmo aleatorizado, y cómo se siembra en C++, Java y Python? 🟠

⏱️ **30 segundos.** Porque un adversario que conoce el código y la semilla puede simular las monedas y fabricar la entrada mala. Se siembra con el reloj o con la entropía del sistema.

🗣️ **2 minutos.** En C++, `mt19937_64` con `steady_clock::now()` o `random_device`; en Java, `new Random()` o `SplittableRandom()` sin argumento; en Python, `random` ya se siembra del sistema al importarse.

🔬 **El detalle.** En los jueces con *hacks* (Codeforces) es la diferencia entre aceptado y TLE tras el *hack*.

**01 → 8.** ¿Cuántas repeticiones de Freivalds necesitas para un error menor que `10⁻⁹`? 🟠

⏱️ **30 segundos.** 30: `2⁻³⁰ ≈ 9,3·10⁻¹⁰ < 10⁻⁹`.

🗣️ **2 minutos.** Con error `1/2` por repetición, hace falta `k ≥ log₂(10⁹) ≈ 29,9`. Con `r` uniforme módulo un primo de `10⁹`, bastarían 2.

🔬 **El detalle.** El coste es `30 · 3n²`: con `n = 1 000`, `9·10⁷` operaciones.

**01 → 9.** ¿Qué probabilidad tiene de comparar `zᵢ` y `zⱼ` el *quicksort* aleatorio, y por qué? 🟠

⏱️ **30 segundos.** `2 / (j − i + 1)`: se comparan si y solo si uno de los dos es el primer pivote elegido entre `zᵢ, …, zⱼ`.

🗣️ **2 minutos.** Mientras no se elija un pivote de ese tramo, los dos siguen en el mismo subproblema. El primer pivote del tramo los separa, salvo que sea uno de ellos; y cada uno de los `j − i + 1` es igual de probable.

🔬 **El detalle.** Sumando por linealidad, `Σ 2/(j − i + 1) ≤ 2n Hₙ ≈ 2n ln n`.

**01 → 10.** ¿Por qué Miller-Rabin deja de ser aleatorizado en 64 bits? 🟠

⏱️ **30 segundos.** Porque para enteros de 64 bits basta con las 12 primeras bases primas: con ellas el test no tiene falsos positivos, y deja de hacer falta elegir bases al azar.

🗣️ **2 minutos.** El error de `4⁻ᵏ` es para bases al azar. Se ha comprobado que ningún compuesto menor que unos `3,2·10²⁴` engaña a la vez a las bases `2, 3, …, 37`, y eso cubre de sobra los `1,8·10¹⁹` de 64 bits.

🔬 **El detalle.** Para números mayores (criptografía), se vuelve a las bases al azar.

**01 → 11.** Demuestra que, si `AB ≠ C`, Freivalds acepta con probabilidad como mucho `1/2`. 🔴

⏱️ **30 segundos.** Si `D = AB − C` tiene `d_{ij} ≠ 0`, fijados los demás `r`, `(Dr)ᵢ = d_{ij} rⱼ + s`; como mucho uno de los dos valores de `rⱼ` la anula, así que `P(Dr = 0) ≤ 1/2`.

🗣️ **2 minutos.** Se condiciona sobre todas las coordenadas de `r` menos la `j`. Si `s = 0`, solo `rⱼ = 0` anula; si `s = −d_{ij}`, solo `rⱼ = 1`; si no, ninguno. En cualquier caso, la probabilidad es `≤ 1/2`, y también sin condicionar.

🔬 **El detalle.** Es el principio de las decisiones diferidas: se sortea `rⱼ` al final.

**01 → 12.** Diseña un algoritmo para decidir si un arreglo de `10⁶` enteros tiene un valor que aparece en al menos la mitad de las posiciones, usando muestreo, y acota su error. 🔴

⏱️ **30 segundos.** Elegir posiciones al azar y contar cuántas veces aparece su valor: si hay un valor en la mitad o más, cada intento lo encuentra con probabilidad `≥ 1/2`. Con 30 intentos, error `≤ 2⁻³⁰`.

🗣️ **2 minutos.** Cada intento cuesta `Θ(n)` (contar). Si ningún candidato llega a la mitad, se responde «no hay»; esa respuesta solo es errónea si los 30 intentos fallaron. Total `Θ(30 n)`.

🔬 **El detalle.** Existe un determinista lineal (Boyer-Moore), pero la idea del muestreo es la que generalizan problemas como Cut and Stick o Ghd.

**01 → Problema: Polinomios iguales.**

**Pista 2:** comparar los dos polinomios en un punto `x` elegido al azar módulo un primo grande: si son distintos, coinciden en como mucho `n` puntos (Schwartz-Zippel).

**Pista 3:** evalúa el producto de factores y el polinomio de `Q` (con Horner) módulo un primo de unos `2⁶¹` elegido al azar o fijo con varias repeticiones; error `≤ n/p` por punto. El primo aleatorio impide que un adversario fabrique una diferencia múltiplo de `p`.

**01 → Problema: Mismos valores en dos tramos.**

**Pista 2:** asigna a cada valor distinto un número aleatorio de 64 bits y compara la suma de esos números en los dos tramos, con sumas de prefijo.

**Pista 3:** un mapa de valor a número aleatorio; prefijos módulo `2⁶⁴` (el desbordamiento natural); dos tramos con la misma suma son permutación con probabilidad de error `≈ 2⁻⁶⁴` por consulta.

**01 → Problema: Implement Rand10() Using Rand7().**

**Pista 2:** con dos llamadas, `7 · (a − 1) + b` da 49 valores equiprobables; usa los 40 primeros (`1 + v mod 10`) y repite si sale de 41 a 49.

**Pista 3:** Las Vegas: `49/40` pares de llamadas esperados; se pueden reciclar los 9 sobrantes para la siguiente tirada y bajar las llamadas.

**01 → Problema: Generate Random Point in a Circle.**

**Pista 2:** punto uniforme en el cuadrado que rodea al círculo, y repetir mientras caiga fuera.

**Pista 3:** acierta con probabilidad `π/4`; esperanza `4/π ≈ 1,27` intentos. La alternativa con radio `√u` y ángulo uniforme evita el rechazo.

**01 → Problema: Cut and Stick.**

**Pista 2:** si un valor ocupa más de la mitad de un tramo, una posición al azar lo encuentra con probabilidad `> 1/2`; su frecuencia se cuenta con búsqueda binaria en sus posiciones.

**Pista 3:** unos 25 intentos por consulta; para cada candidato, frecuencia en el tramo con las listas de posiciones ordenadas; la respuesta es `max(1, 2f − len)`.

**01 → Problema: Interactive LowerBound.**

**Pista 2:** con unas 1 000 preguntas a posiciones al azar se obtiene un punto de partida cercano al valor buscado; después se recorre la lista hacia delante.

**Pista 3:** entre los valores preguntados, toma el mayor que sea `< x` y avanza desde él; el número esperado de pasos hasta superar `x` es pequeño porque las posiciones preguntadas reparten la lista.

**01 → Problema: Kuroni and the Punishment.**

**Pista 2:** en la respuesta óptima, al menos la mitad de los elementos cambian en como mucho 1: un elemento al azar está en ese grupo con probabilidad `≥ 1/2`.

**Pista 3:** elige unos 20 elementos al azar; para cada uno, los factores primos de `a − 1`, `a` y `a + 1` son candidatos a divisor común; para cada primo candidato, el coste total en `O(n)`.

**01 → Problema: Love-Hate.**

**Pista 2:** un amigo al azar pertenece al grupo óptimo (de al menos la mitad) con probabilidad `≥ 1/2`, y la respuesta es un subconjunto de sus como mucho 15 monedas.

**Pista 3:** repite unas 20 veces: con las 15 monedas del elegido, cuenta para cada submáscara cuántos amigos la contienen (suma sobre superconjuntos); quédate con la mayor máscara con cuenta `≥ ⌈n/2⌉`.

**01 → Problema: Kazaee.**

**Pista 2:** si cada valor aparece un múltiplo de `k` veces, la suma de cualquier subconjunto de valores repetidos también es múltiplo de `k`.

**Pista 3:** unas 30 rondas con un subconjunto aleatorio de valores; un Fenwick por ronda con la suma de los elementos del subconjunto; la consulta es «sí» si en todas las rondas la suma del tramo es múltiplo de `k`.

**01 → Problema: Ghd.**

**Pista 2:** la respuesta divide a al menos la mitad de los números: un número al azar es múltiplo de ella con probabilidad `≥ 1/2`, y la respuesta es uno de sus divisores.

**Pista 3:** unas 10 elecciones al azar; para cada una, sus divisores (como mucho unos 7 000) y, para cada divisor, cuántos números son múltiplos, agrupando por el `gcd` con el elegido.


---

# 02 — Hashing universal y análisis esperado

**02 → 1.** ¿Qué es una familia universal de funciones de *hash*? 🟢

⏱️ **30 segundos.** Un conjunto de funciones de *hash* en el que, eligiendo una al azar, dos claves distintas cualesquiera chocan con probabilidad como mucho `1/m`.

🗣️ **2 minutos.** La garantía es para cada par de claves, sobre el sorteo de la función. Ejemplo: `((a·x + b) mod p) mod m`, con `a` y `b` al azar y `p` primo mayor que las claves.

🔬 **El detalle.** No dice nada de una función concreta: dice cuántas funciones de la familia son malas para un par dado.

**02 → 2.** ¿Cuál es la longitud esperada de una cadena con *hashing* universal? 🟢

⏱️ **30 segundos.** `1 + α` esperado, con `α = n/m`, para cualquier conjunto de claves.

🗣️ **2 minutos.** El número esperado de otras claves en la cubeta de una dada es como mucho `(n − 1)/m < α`, por linealidad sobre los indicadores de choque. Buscar cuesta `O(1 + α)`.

🔬 **El detalle.** Con *rehash* que mantiene `α ≤ 1`, es `O(1)` esperado por operación.

**02 → 3.** ¿Cuál es la altura esperada de una *skip list* de `n` elementos? 🟢

⏱️ **30 segundos.** `log₂ n + O(1)` niveles en esperanza, y con alta probabilidad.

🗣️ **2 minutos.** Que pase de `log₂ n + c` tiene probabilidad como mucho `2⁻ᶜ` (unión de los `n` elementos). Con `n = 10⁶`, unos 21 niveles.

🔬 **El detalle.** La altura exacta esperada es `Σ_k (1 − (1 − 2^{−(k−1)})ⁿ)`.

**02 → 4.** ¿Por qué ninguna función de *hash* fija resiste a un adversario? 🟡

⏱️ **30 segundos.** Porque, con un universo mucho mayor que el número de cubetas, alguna cubeta recibe al menos `|U|/m` claves, y el atacante elige sus `n` claves de ahí.

🗣️ **2 minutos.** Es el principio del palomar. Con una función pública (la de la librería), el atacante calcula esa cubeta; [`06/03`](../06-lineales-y-hashing/03-tablas-hash.md) muestra el ataque contra `std::hash`.

🔬 **El detalle.** Por eso la defensa no puede ser una función mejor, sino una función que el atacante no conoce.

**02 → 5.** ¿Qué diferencia hay entre «sin colisiones» y «universal»? 🟡

⏱️ **30 segundos.** «Sin colisiones» es imposible si hay más claves que cubetas; «universal» acota la probabilidad de colisión de cada par por `1/m`, sobre el sorteo de la función.

🗣️ **2 minutos.** Un *hash* perfecto (sin colisiones) existe para un conjunto fijo conocido de antemano; para claves arbitrarias, lo alcanzable es el comportamiento de una función al azar.

🔬 **El detalle.** El *hashing* perfecto de dos niveles (FKS) usa familias universales para construir uno sin colisiones para un conjunto estático.

**02 → 6.** ¿Cuántos punteros ocupa en esperanza una *skip list*, y por qué? 🟡

⏱️ **30 segundos.** `2n` punteros: cada elemento ocupa en esperanza 2 niveles.

🗣️ **2 minutos.** El número de niveles de un elemento es geométrico de parámetro `1/2`: `E = Σ_k P(≥ k) = 1 + 1/2 + 1/4 + … = 2`.

🔬 **El detalle.** Con probabilidad de subida `p`, `1/(1 − p)` niveles por elemento: menos memoria, búsquedas más largas.

**02 → 7.** ¿Qué cambia entre C++, Java y Python para implementar Carter-Wegman con claves de 64 bits? 🟠

⏱️ **30 segundos.** En C++, el producto `a·x` en `__int128`; en Java, `Math.multiplyHigh` para la parte alta (o `BigInteger`); en Python, enteros sin límite.

🗣️ **2 minutos.** Con `p = 2⁶¹ − 1`, el producto de dos números de 61 bits ocupa 122 y la reducción se puede hacer con desplazamientos (`(x >> 61) + (x & p)`). En Python basta `%`, más lento.

🔬 **El detalle.** Con claves de 31 bits y `p = 2³¹ − 1`, todo cabe en 64 bits en los tres lenguajes.

**02 → 8.** ¿Por qué el análisis hacia atrás da `2 log₂ n` para la búsqueda en una *skip list*? 🟠

⏱️ **30 segundos.** Porque, recorrido al revés, el camino sube un nivel con probabilidad `1/2` en cada paso o va a la izquierda: subir cuesta 2 pasos esperados, y hay `log₂ n` niveles.

🗣️ **2 minutos.** Un nodo del camino se visitó porque en ese nivel era el último antes del objetivo; al retroceder, sube si el nodo tiene un nivel más (probabilidad `1/2`). Los pasos por nivel son geométricos de media 2.

🔬 **El detalle.** Más los niveles por encima de `log₂ n`, que aportan `O(1)` en esperanza.

**02 → 9.** ¿Qué relación hay entre el pivote aleatorio de *quicksort* y el *hashing* universal? 🟠

⏱️ **30 segundos.** Los dos defienden de un adversario con la misma idea: las monedas se tiran después de fijar la entrada, así que ninguna entrada es mala para muchas elecciones.

🗣️ **2 minutos.** El pivote aleatorio hace que el `n log n` sea esperado para toda entrada; la función universal, que la cadena `1 + α` sea esperada para todo conjunto de claves.

🔬 **El detalle.** Ninguno elimina el caso malo: lo vuelve improbable para cualquier entrada.

**02 → 10.** ¿Qué garantiza «con alta probabilidad» que no garantiza «en esperanza»? 🟠

⏱️ **30 segundos.** Que la probabilidad de pasarse de la cota es pequeña (como una potencia negativa de `n`), no solo que el promedio sea bueno.

🗣️ **2 minutos.** En esperanza, la altura del *treap* es `≈ 1,39 log₂ n`, pero podría tener mucha varianza; «con alta probabilidad» dice que pasar de `c log n` ocurre con probabilidad `n^{−Ω(c)}`. Para muchas operaciones, es lo que importa.

🔬 **El detalle.** Se demuestra con cotas de Chernoff sobre sumas de indicadores independientes.

**02 → 11.** Demuestra que la familia `((a·x + b) mod p) mod m` es universal. 🔴

⏱️ **30 segundos.** Para `x ≠ y`, el par `(r, s)` de restos módulo `p` recorre los pares con `r ≠ s` exactamente una vez al variar `(a, b)`; para cada `r`, como mucho `(p − 1)/m` valores de `s` tienen el mismo resto módulo `m`. La fracción de choques es `≤ 1/m`.

🗣️ **2 minutos.** El sistema `r = ax + b`, `s = ay + b` (módulo `p`) tiene solución única `a = (r − s)(x − y)⁻¹`, `b = r − ax`, y `a ≠ 0` si y solo si `r ≠ s`. Hay `p(p − 1)` funciones y `p(p − 1)` pares con `r ≠ s`: biyección. Contando los `s ≡ r (mod m)` con `s ≠ r`: como mucho `⌈p/m⌉ − 1 ≤ (p − 1)/m`.

🔬 **El detalle.** Es la prueba de CLRS, §11.3.3.

**02 → 12.** Demuestra que, con *hashing* universal, el número esperado de claves en la cubeta de una clave dada es menor que `1 + α`. 🔴

⏱️ **30 segundos.** Con indicadores `X_y = [h(y) = h(x)]` para cada otra clave `y`: `E[Σ X_y] = Σ P(h(y) = h(x)) ≤ (n − 1)/m < α`. Más la propia, `< 1 + α`.

🗣️ **2 minutos.** La linealidad de la esperanza no necesita independencia entre los indicadores: basta la cota de cada par, que es la definición de familia universal.

🔬 **El detalle.** Si `x` no está en la tabla, el resultado es `≤ n/m = α` sin el 1.

**02 → Problema: Colisiones esperadas.**

**Pista 2:** hay `C(n, 2)` pares y cada uno aporta su probabilidad de choque, `1/m`: la esperanza es `C(n, 2)/m`.

**Pista 3:** `n(n − 1)/2` cabe en 64 bits con `n ≤ 10⁹`; reduce con el `gcd` de numerador y `m`.

**02 → Problema: ¿Cumple la cota?.**

**Pista 2:** fuerza bruta: hay `p(p − 1)` funciones y `C(p, 2)` pares; con `p ≤ 47`, unos `10³` pares por `2·10³` funciones: `2·10⁶` comprobaciones.

**Pista 3:** para cada par `(x, y)`, cuenta las funciones con choque; la mayor cuenta entre `p(p − 1)` es la respuesta, reducida con el `gcd`. Debe salir `≤ 1/m`.

**02 → Problema: Altura esperada.**

**Pista 2:** `E[altura] = Σ_{k ≥ 1} P(altura ≥ k)`, y `P(altura ≥ k) = 1 − (1 − 2^{−(k−1)})ⁿ`.

**Pista 3:** suma hasta que el término sea despreciable (unos 130 términos con `n = 10¹⁸`); calcula `(1 − q)ⁿ` como `exp(n · log1p(−q))` para no perder precisión con `q` diminuto.

**02 → Problema: The Untended Antiquity.**

**Pista 2:** valores aleatorios por rectángulo sumados en un Fenwick 2D: dos celdas con la misma suma están, con alta probabilidad, rodeadas por los mismos rectángulos.

**Pista 3:** al poner una barrera, suma su valor aleatorio en su rectángulo (cuatro actualizaciones del Fenwick 2D); al quitarla, réstalo; la consulta compara las sumas puntuales de las dos celdas.


---

# 03 — Estructuras probabilísticas

**03 → 1.** ¿Qué responde un filtro de Bloom, y qué tipo de error tiene? 🟢

⏱️ **30 segundos.** Si un elemento **puede** estar en el conjunto: «seguro que no» o «quizá». Su error son los falsos positivos; nunca da falsos negativos.

🗣️ **2 minutos.** Insertar pone a 1 los `k` bits del elemento; consultar mira si los `k` están a 1. Un «quizá» puede ser de otro elemento que puso esos bits; un «no» es seguro.

🔬 **El detalle.** La tasa de falsos positivos es `≈ (1 − e^{−kn/m})ᵏ`.

**03 → 2.** ¿Cuántos bits por elemento hacen falta para un 1 % de falsos positivos, y cuántas funciones? 🟢

⏱️ **30 segundos.** Unos 9,6 bits por elemento y 7 funciones.

🗣️ **2 minutos.** `m/n = −ln ε / (ln 2)² = 9,59` y `k = (m/n) ln 2 = 6,64 → 7`. Con mil millones de elementos, 1,2 GB.

🔬 **El detalle.** Cada factor 10 menos de error cuesta unos 4,8 bits más por elemento.

**03 → 3.** ¿Qué estima Count-Min y en qué sentido se equivoca? 🟢

⏱️ **30 segundos.** La frecuencia de un elemento en un flujo, siempre por exceso: como mucho `εN` de más con probabilidad `1 − δ`.

🗣️ **2 minutos.** Cada fila suma la cuenta del elemento más las de los que chocan con él; el mínimo de las filas es la estimación. Con `w = ⌈e/ε⌉` y `d = ⌈ln(1/δ)⌉`.

🔬 **El detalle.** `N` es la suma total del flujo: el error es grande para los elementos raros.

**03 → 4.** ¿Qué pregunta responde HyperLogLog, y con qué error? 🟢

⏱️ **30 segundos.** Cuántos elementos **distintos** hay en un flujo, con un error estándar de `1,04/√m` y `m` registros.

🗣️ **2 minutos.** Con `m = 2¹⁴` registros de 6 bits: 12 KB y un 0,81 % de error, para miles de millones de elementos. Se unen tomando el máximo por registro.

🔬 **El detalle.** Es lo que usan `PFADD` y `PFCOUNT` en Redis.

**03 → 5.** ¿Por qué un Bloom no puede dar falsos negativos? 🟡

⏱️ **30 segundos.** Porque un elemento insertado pone sus `k` bits a 1 y nada los vuelve a poner a 0: al consultarlo, los encuentra todos.

🗣️ **2 minutos.** Las únicas operaciones sobre los bits son ponerlos a 1. La respuesta «no» exige un bit a 0, que no puede ser de un elemento insertado.

🔬 **El detalle.** Por eso no se puede borrar poniendo bits a 0: se crearían falsos negativos.

**03 → 6.** ¿Por qué hay un número óptimo de funciones de *hash* en un Bloom? 🟡

⏱️ **30 segundos.** Porque más funciones dan más bits que comprobar (menos falsos positivos) pero también llenan más el filtro (más falsos positivos). El óptimo, `k = (m/n) ln 2`, deja la mitad de los bits a 1.

🗣️ **2 minutos.** La tasa `(1 − e^{−kn/m})ᵏ` como función de `k` tiene un mínimo; derivando su logaritmo se llega a `e^{−kn/m} = 1/2`.

🔬 **El detalle.** En la práctica `k` es entero: se redondea, y la tasa queda un poco por encima del mínimo continuo.

**03 → 7.** ¿Qué diferencia hay entre el error de Count-Min y un error relativo a cada frecuencia? 🟡

⏱️ **30 segundos.** El de Count-Min es aditivo y relativo al total, `εN`; un error relativo a cada frecuencia sería `ε f(x)`.

🗣️ **2 minutos.** Con `N = 10⁹` y `ε = 0,1 %`, el error es de hasta un millón: irrelevante para los elementos que aparecen cien millones de veces, enorme para los que aparecen diez.

🔬 **El detalle.** Para errores relativos a cada frecuencia hacen falta otras estructuras (*count sketch* con medianas, o más memoria).

**03 → 8.** ¿Qué cambia entre C++ y Java al implementar el Bloom sobre enteros de 64 bits sin signo? 🟠

⏱️ **30 segundos.** En C++, `uint64_t` y `%` sin signo; en Java no hay `unsigned long`: `>>>` en lugar de `>>` y `Long.remainderUnsigned` para el módulo.

🗣️ **2 minutos.** Con `long` de Java, un *hash* con el bit alto encendido es negativo y `%` daría un índice negativo. Las constantes de `splitmix64` se escriben igual; la aritmética con desbordamiento coincide bit a bit.

🔬 **El detalle.** En Python, los enteros no desbordan: hay que enmascarar con `& (2**64 − 1)` tras cada multiplicación.

**03 → 9.** ¿Por qué no se puede borrar de un Bloom, y qué variante lo permite? 🟠

⏱️ **30 segundos.** Porque un bit puede ser de varios elementos: ponerlo a 0 borraría también a los otros, que pasarían a dar falsos negativos. El Bloom con contadores (4 bits por posición) sí borra.

🗣️ **2 minutos.** Con contadores, insertar suma 1 y borrar resta 1 en las `k` posiciones; consultar mira que ninguna sea 0. Cuesta unas cuatro veces la memoria.

🔬 **El detalle.** Los *cuckoo filters* y *quotient filters* también borran, con menos memoria.

**03 → 10.** ¿Por qué Count-Min toma el mínimo de las filas y no la media? 🟠

⏱️ **30 segundos.** Porque cada fila solo puede sumar de más: el mínimo es la fila con menos colisiones, y sigue siendo una cota superior. La media mezclaría las filas malas.

🗣️ **2 minutos.** La garantía `≤ f + εN` con probabilidad `1 − δ` sale de que **todas** las filas se pasen a la vez es improbable; con el mínimo basta que una no se pase.

🔬 **El detalle.** Con cuentas negativas, el mínimo deja de ser cota y se usa la mediana.

**03 → 11.** Deduce la tasa de falsos positivos de un Bloom y el `k` que la minimiza. 🔴

⏱️ **30 segundos.** Un bit concreto sigue a 0 tras `kn` intentos con probabilidad `(1 − 1/m)^{kn} ≈ e^{−kn/m}`; un falso positivo exige `k` bits a 1: `(1 − e^{−kn/m})ᵏ`. Derivando, el mínimo está en `k = (m/n) ln 2`.

🗣️ **2 minutos.** Con `p = e^{−kn/m}`, `ln(tasa) = k ln(1 − p) = −(m/n) ln p · ln(1 − p)`, simétrico en `p` y `1 − p`: mínimo en `p = 1/2`, es decir `k = (m/n) ln 2`, y tasa `2⁻ᵏ ≈ 0,6185^{m/n}`.

🔬 **El detalle.** La aproximación supone bits independientes; para `m` grande es muy precisa.

**03 → 12.** Diseña cómo contar los usuarios distintos por día de 100 servidores, con memoria fija por servidor, y di el error. 🔴

⏱️ **30 segundos.** Un HyperLogLog por servidor y día, con `m = 2¹⁴` registros (12 KB): al final del día se unen los 100 tomando el máximo por registro. Error de un 0,8 %.

🗣️ **2 minutos.** La unión es exacta para HyperLogLog: el registro de la unión es el máximo de los registros. Así se cuentan los distintos globales sin mover los identificadores.

🔬 **El detalle.** Con conjuntos exactos habría que enviar todos los identificadores de cada servidor: gigabytes en lugar de 1,2 MB.

**03 → Problema: Tasa de falsos positivos.**

**Pista 2:** la fórmula directa, con cuidado con la precisión: cuando `kn/m` es diminuto, `1 − e^{−x}` pierde dígitos.

**Pista 3:** usa `-expm1(-x)` para `1 − e^{−x}`, y la potencia con `pow` (o `exp(k · log(…))`); imprime con 6 decimales.

**03 → Problema: El contador aproximado.**

**Pista 2:** cada valor toca la celda `hᵢ(x)` de cada fila; la estimación es el mínimo de las `d` celdas.

**Pista 3:** una tabla de `d × w` en 64 bits; productos `aᵢ · x` de hasta `10¹⁸`, que caben en 64 bits antes del módulo; lectura rápida para `10⁶` valores.


---

# 04 — Muestreo y cadenas de Markov

**04 → 1.** ¿Qué hace Fisher-Yates y cuánto cuesta? 🟢

⏱️ **30 segundos.** Baraja un arreglo de forma uniforme, en el sitio, en `Θ(n)`: para `i` de `n − 1` a 1, intercambia `a[i]` con `a[j]`, `j` uniforme en `[0, i]`.

🗣️ **2 minutos.** Cada una de las `n!` secuencias de elecciones produce una permutación distinta, así que todas salen con probabilidad `1/n!`. Usa `n − 1` números aleatorios.

🔬 **El detalle.** Es `std::shuffle`, `Collections.shuffle` y `random.shuffle`.

**04 → 2.** ¿Qué resuelve el *reservoir sampling*? 🟢

⏱️ **30 segundos.** Elegir `k` elementos uniformes de un flujo de longitud desconocida, en una pasada y con memoria `O(k)`.

🗣️ **2 minutos.** Los `k` primeros entran; el `i`-ésimo entra con probabilidad `k/i` sustituyendo a uno al azar. Al final, cada elemento está con probabilidad `k/n`.

🔬 **El detalle.** Con `k = 1`, un elemento al azar de una lista enlazada en una pasada.

**04 → 3.** ¿Qué es la distribución estacionaria de una cadena de Markov? 🟢

⏱️ **30 segundos.** Una distribución `π` sobre los estados que no cambia al dar un paso: `π = πP`.

🗣️ **2 minutos.** Si la cadena es finita, irreducible y aperiódica, es única y la cadena converge a ella desde cualquier estado. La fracción de tiempo en cada estado tiende a `π`.

🔬 **El detalle.** PageRank es la estacionaria de un paseo por la web con teletransporte.

**04 → 4.** ¿Qué diferencia hay entre elegir `j` en `[0, i]` y en `[0, n − 1]` al barajar? 🟡

⏱️ **30 segundos.** Con `[0, i]` cada permutación sale con probabilidad `1/n!`; con `[0, n − 1]` hay `nⁿ` secuencias equiprobables, que no se reparten por igual entre las `n!` permutaciones.

🗣️ **2 minutos.** Para `n = 3`, 27 secuencias sobre 6 órdenes: tres salen 5 veces y tres, 4. Como 27 no es múltiplo de 6, no hay forma de que sea uniforme.

🔬 **El detalle.** En una prueba de 600 000 barajados de `[1, 2, 3]`, los órdenes «de 5» salieron unas 111 000 veces y los «de 4», unas 89 000.

**04 → 5.** ¿Qué diferencia hay entre Fisher-Yates y el algoritmo de Sattolo? 🟡

⏱️ **30 segundos.** Fisher-Yates elige `j` en `[0, i]`; Sattolo, en `[0, i − 1]`. Sattolo genera solo permutaciones cíclicas (un único ciclo), uniformemente entre ellas.

🗣️ **2 minutos.** Quitar la opción de que un elemento se quede en su sitio parece inofensivo y cambia el resultado: con `n = 3` solo salen `(2,3,1)` y `(3,1,2)`.

🔬 **El detalle.** Sattolo sirve para generar un recorrido que visita todos los nodos una vez (un ciclo de Hamilton aleatorio sobre una lista).

**04 → 6.** ¿Cuál es la estacionaria de un paseo aleatorio en un grafo no dirigido conexo? 🟡

⏱️ **30 segundos.** `π(v) = grado(v) / 2|E|`.

🗣️ **2 minutos.** Se comprueba que `π = πP`: lo que entra a `v` es `Σ_{u vecino} (grado(u)/2|E|) · (1/grado(u)) = grado(v)/2|E|`. En `G`, `B` y `E` (grado 3) tienen `3/14`; los demás, `1/7`.

🔬 **El detalle.** Si el grafo es bipartito, el paseo no converge (oscila), pero la fracción de tiempo sí tiende a `π`.

**04 → 7.** ¿Qué cambia entre C++, Java y Python para obtener un entero uniforme en `[0, i]`? 🟠

⏱️ **30 segundos.** En C++, `uniform_int_distribution<int>(0, i)` sobre un `mt19937_64`; en Java, `rng.nextInt(i + 1)`; en Python, `random.randint(0, i)` o `random.randrange(i + 1)`.

🗣️ **2 minutos.** El error típico es `rng() % (i + 1)` en C++: sesgado salvo que `i + 1` divida al rango del generador. Y en Java, `nextInt(i)` excluye `i`; en Python, `randint` lo incluye.

🔬 **El detalle.** Con rangos de 64 bits, Java 17 trae `nextLong(bound)` en `RandomGenerator`.

**04 → 8.** ¿Cómo eliges un nodo al azar de una lista enlazada en una sola pasada? 🟠

⏱️ **30 segundos.** Con *reservoir* de `k = 1`: guardar el primero y, en el nodo `i`, sustituirlo con probabilidad `1/i`.

🗣️ **2 minutos.** Por inducción, tras `i` nodos cada uno es el elegido con probabilidad `1/i`. Una pasada, memoria `O(1)`, sin conocer la longitud.

🔬 **El detalle.** Si se puede recorrer dos veces, contar la longitud y elegir un índice es igual de bueno.

**04 → 9.** ¿Por qué un paseo aleatorio en un grafo bipartito no converge a su estacionaria? 🟠

⏱️ **30 segundos.** Porque la cadena es periódica: el paseo alterna entre los dos lados, y la distribución en el paso `t` depende de la paridad de `t`.

🗣️ **2 minutos.** Desde un vértice del lado izquierdo, en los pasos pares está siempre a la izquierda. La estacionaria existe, pero la cadena no converge a ella; añadir un lazo (quedarse con probabilidad `1/2`) la hace aperiódica.

🔬 **El detalle.** La versión «perezosa» del paseo se usa precisamente para garantizar la convergencia.

**04 → 10.** ¿Para qué sirve MCMC si ya se conoce la distribución salvo una constante? 🟠

⏱️ **30 segundos.** Para muestrear de ella: MCMC construye una cadena cuya estacionaria es la distribución buscada, y solo necesita cocientes `π(y)/π(x)`, donde la constante se cancela.

🗣️ **2 minutos.** En estadística bayesiana, la posterior se conoce salvo una constante imposible de calcular; Metropolis-Hastings la muestrea igual. Con muestras, se estiman medias y probabilidades.

🔬 **El detalle.** Las muestras están correladas: hay que descartar las primeras (calentamiento) y espaciar.

**04 → 11.** Demuestra que el *reservoir sampling* deja cada elemento en el depósito con probabilidad `k/n`. 🔴

⏱️ **30 segundos.** Por inducción: tras `i` elementos, cada uno está con probabilidad `k/i`. Llega el `i + 1`: entra con `k/(i + 1)`; uno antiguo sigue con `(k/i) · (1 − (k/(i + 1)) · (1/k)) = k/(i + 1)`.

🗣️ **2 minutos.** La base, `i = k`, es trivial: todos están. En el paso, un antiguo se queda si estaba y no lo sustituye el nuevo: el nuevo entra con `k/(i + 1)` y elige su casilla con `1/k`. El producto da `(k/i) · (i/(i + 1))`.

🔬 **El detalle.** Con `n` total, cada elemento acaba con `k/n`, y además todos los subconjuntos de tamaño `k` son equiprobables.

**04 → 12.** Demuestra que el barajado que intercambia cada posición con una de todo el arreglo no es uniforme para `n = 3`, y generaliza el argumento. 🔴

⏱️ **30 segundos.** Con `[1, 2, 3]` hay `3³ = 27` secuencias de elecciones equiprobables; un reparto uniforme sobre `3! = 6` órdenes exigiría que 6 dividiera a 27. En general, `n!` no divide a `nⁿ` para `n ≥ 3`.

🗣️ **2 minutos.** Para `n ≥ 3`, `n − 1` divide a `n!` y es primo con `nⁿ`: `n!` no puede dividir a `nⁿ`. Así que ningún reparto de las `nⁿ` secuencias da a cada permutación el mismo número.

🔬 **El detalle.** Las cuentas exactas para `n = 3` son `4, 5, 5, 5, 4, 4`.

**04 → Problema: Barajado reproducible.**

**Pista 2:** Fisher-Yates de atrás hacia delante, con el generador dado para cada `j`.

**Pista 3:** `x` en 64 bits: `1 103 515 245 · x` con `x < 2³¹` cabe; `j = x mod (i + 1)`; el primer `x` que se usa es el siguiente a `s`.

**04 → Problema: El paseo del cartero.**

**Pista 2:** la fracción de tiempo en cada esquina es `grado(v) / 2m`.

**Pista 3:** cuenta el grado de cada esquina; imprime `grado(v)/2m` reducido con el `gcd`.

**04 → Problema: Muestra con pesos.**

**Pista 2:** un *heap* de mínimos con los `k` de mayor clave vistos; un nuevo elemento entra si su clave supera al mínimo.

**Pista 3:** compara `ln(uᵢ)/wᵢ` en lugar de `uᵢ^{1/wᵢ}` (el logaritmo es creciente); `O(n log k)`; ordena los índices al final.

**04 → Problema: Shuffle an Array.**

**Pista 2:** Fisher-Yates, con `j` en `[0, i]`.

**Pista 3:** guarda el original para `reset`; en `shuffle`, copia y baraja de atrás hacia delante.

**04 → Problema: Linked List Random Node.**

**Pista 2:** *reservoir* con `k = 1`: el nodo `i` sustituye al elegido con probabilidad `1/i`.

**Pista 3:** una pasada por la lista en cada llamada; `O(1)` de memoria extra.

**04 → Problema: Random Pick Index.**

**Pista 2:** *reservoir* restringido a las posiciones con el valor buscado: la `c`-ésima que aparece se elige con probabilidad `1/c`.

**Pista 3:** recorre el arreglo; cuenta las coincidencias; sustituye con probabilidad `1/cuenta`.

**04 → Problema: Random Pick with Weight.**

**Pista 2:** prefijos de los pesos y búsqueda binaria de un número uniforme en `[1, total]`.

**Pista 3:** `pickIndex`: `r` uniforme en `[1, total]` y el primer prefijo `≥ r` con `lower_bound`; `O(log n)` por llamada.

**04 → Problema: Random Point in Non-overlapping Rectangles.**

**Pista 2:** elegir un rectángulo con probabilidad proporcional a su número de puntos enteros, `(x₂ − x₁ + 1)(y₂ − y₁ + 1)`, y después un punto uniforme dentro.

**Pista 3:** prefijos de esos tamaños y binaria; dentro del rectángulo, `x` e `y` uniformes; o un índice global y su descomposición.

**04 → Problema: Random Flip Matrix.**

**Pista 2:** Fisher-Yates perezoso sobre el arreglo virtual de las `m · n` celdas: un mapa guarda solo las posiciones intercambiadas.

**Pista 3:** en cada `flip`, `j` uniforme en `[0, restantes)`; la celda es `mapa[j]` (o `j`), y `mapa[j] = mapa[restantes − 1]`; `reset` vacía el mapa.

**04 → Problema: Insert Delete GetRandom O(1) - Duplicates allowed.**

**Pista 2:** un arreglo con los valores y, para cada valor, el conjunto de sus posiciones; borrar intercambia con el último y actualiza las posiciones.

**Pista 3:** `getRandom` es un índice uniforme del arreglo, que respeta las multiplicidades; al borrar, mueve el último a la posición liberada y corrige su conjunto.

**04 → Problema: Random Pick with Blacklist.**

**Pista 2:** se elige uniforme en `[0, n − b)`; los de la lista negra que caen en ese rango se remapean a valores permitidos de `[n − b, n)`.

**Pista 3:** un mapa de remapeo construido una vez: recorre los vetados `< n − b` y asígnales los permitidos `≥ n − b` en orden; `pick` es `O(1)`.


---

# 05 — Estructuras espaciales

**05 → 1.** ¿Cómo se construye un árbol k-d? 🟢

⏱️ **30 segundos.** Partiendo recursivamente por la mediana de una coordenada que alterna en cada nivel (`x`, `y`, `x`, …). `O(n log n)`.

🗣️ **2 minutos.** Cada nodo representa un rectángulo del plano y lo divide en dos. Con la mediana, la altura es `⌈log₂ n⌉`. La mediana de cada nivel sale con selección lineal o preordenando.

🔬 **El detalle.** Con los puntos de juguete, la raíz parte por `x = 2`.

**05 → 2.** ¿Cuánto cuesta una consulta de rango ortogonal en un árbol k-d del plano? 🟢

⏱️ **30 segundos.** `O(√n + k)`, con `k` los puntos que devuelve.

🗣️ **2 minutos.** Lo caro son las regiones cortadas por el borde del rectángulo: una recta corta `O(√n)` regiones. Las que caen enteras dentro se devuelven sin bajar.

🔬 **El detalle.** En `d` dimensiones, `O(n^{1 − 1/d} + k)`.

**05 → 3.** ¿Qué es un R-tree y dónde se usa? 🟢

⏱️ **30 segundos.** Un árbol equilibrado, como un árbol B, cuyos nodos guardan cajas que contienen a sus hijos. Se usa para índices espaciales en bases de datos (PostGIS, SQLite).

🗣️ **2 minutos.** Sirve para rectángulos y objetos con extensión, en disco y con inserciones. Las cajas de hermanos pueden solaparse.

🔬 **El detalle.** Sus variantes (R*-tree) mejoran las divisiones para reducir el solapamiento.

**05 → 4.** ¿Qué diferencia hay entre un árbol k-d y un árbol de rangos? 🟡

⏱️ **30 segundos.** El k-d tiene memoria `O(n)` y consulta `O(√n + k)`; el de rangos, memoria `O(n log n)` y consulta `O(log² n + k)`.

🗣️ **2 minutos.** El árbol de rangos guarda en cada nodo del árbol por `x` su subconjunto ordenado por `y`: más memoria a cambio de consultas logarítmicas.

🔬 **El detalle.** Con *fractional cascading*, el de rangos baja a `O(log n + k)`.

**05 → 5.** ¿Cómo poda la búsqueda del vecino más cercano en un árbol k-d? 🟡

⏱️ **30 segundos.** Visita primero la rama donde caería el punto y, al volver, solo entra en la otra si la distancia del punto a su región es menor que la mejor encontrada.

🗣️ **2 minutos.** La distancia de un punto a un rectángulo es la de su punto más cercano (recortando las coordenadas). Con puntos bien repartidos, casi todas las ramas se podan.

🔬 **El detalle.** Para los `k` más cercanos, la misma poda con un *heap* de tamaño `k`.

**05 → 6.** ¿Qué es la maldición de la dimensión? 🟡

⏱️ **30 segundos.** Que en muchas dimensiones las distancias entre puntos se parecen todas, y las técnicas que podan por distancia dejan de podar.

🗣️ **2 minutos.** Una bola alrededor del punto toca casi todas las regiones; el árbol k-d acaba visitando casi todo. Para que la poda funcione hace falta `n ≫ 2^d`.

🔬 **El detalle.** Por eso las bases de datos vectoriales usan métodos aproximados (grafos de proximidad, LSH).

**05 → 7.** ¿Por qué una consulta de rango en el plano visita `O(√n)` regiones? 🟠

⏱️ **30 segundos.** Porque una recta vertical, cada dos niveles, solo puede bajar por dos de los cuatro nietos: `Q(n) = 2Q(n/4) + O(1) = O(√n)`.

🗣️ **2 minutos.** En un nivel que parte por `x`, la recta vertical está en un solo hijo; en el siguiente, que parte por `y`, corta los dos. Cada dos niveles el tamaño se divide entre 4 y las ramas se multiplican por 2.

🔬 **El detalle.** Los cuatro lados del rectángulo dan `O(√n)` regiones cortadas en total.

**05 → 8.** ¿Qué harías si las consultas de rango se conocen todas de antemano? 🟠

⏱️ **30 segundos.** Responderlas fuera de línea: barrido por `x` con un Fenwick sobre `y` y cada rectángulo como combinación de cuatro «esquinas». `O((n + q) log n)`.

🗣️ **2 minutos.** La cuenta de `[x₁, x₂] × [y₁, y₂]` es `F(x₂, y₂) − F(x₁ − 1, y₂) − F(x₂, y₁ − 1) + F(x₁ − 1, y₁ − 1)`, con `F(X, Y)` los puntos con `x ≤ X` e `y ≤ Y`. Las `4q` esquinas se responden en el barrido.

🔬 **El detalle.** Es la técnica de [`18/05`](../18-geometria/05-barrido-geometrico.md) y [`09/02`](../09-consultas-sobre-rangos/02-fenwick.md), sin árbol espacial.

**05 → 9.** ¿Por qué el R-tree no tiene una buena cota de peor caso? 🟠

⏱️ **30 segundos.** Porque las cajas de hermanos pueden solaparse, y una consulta que cae en la zona común tiene que bajar por todas las ramas.

🗣️ **2 minutos.** Con mucho solapamiento, una consulta puede visitar gran parte del árbol. En la práctica, las heurísticas de inserción y división lo mantienen bajo.

🔬 **El detalle.** Es la diferencia con un árbol k-d, cuyas regiones son disjuntas.

**05 → 10.** ¿Qué usarías para el vecino más cercano en vectores de 512 dimensiones, y qué pierdes? 🟠

⏱️ **30 segundos.** Un método aproximado (grafos de proximidad tipo HNSW, o LSH): devuelven vecinos casi más cercanos en tiempo sublineal. Se pierde la garantía de exactitud.

🗣️ **2 minutos.** Con 512 dimensiones, un k-d visita casi todo. Los métodos aproximados aceptan un pequeño porcentaje de fallos a cambio de órdenes de magnitud de velocidad.

🔬 **El detalle.** Si hace falta el exacto, recorrer todos los vectores con instrucciones vectoriales suele ganar a cualquier árbol.

**05 → 11.** Deduce la recurrencia `Q(n) = 2Q(n/4) + O(1)` del árbol k-d y resuélvela. 🔴

⏱️ **30 segundos.** En dos niveles consecutivos, uno por `x` y otro por `y`, una recta vertical baja por un hijo y después por sus dos nietos: 2 de 4 subárboles de tamaño `n/4`. `Q(n) = 2Q(n/4) + O(1)`, que por el teorema maestro es `Θ(n^{log₄ 2}) = Θ(√n)`.

🗣️ **2 minutos.** Con `a = 2`, `b = 4`, `f(n) = O(1)`: `log_b a = 1/2` y gana el término de las hojas, `n^{1/2}`. El `O(1)` de cada nodo es comprobar si su región corta la recta.

🔬 **El detalle.** En `d` dimensiones, `Q(n) = 2^{d−1} Q(n/2^d) + O(1) = O(n^{1 − 1/d})`.

**05 → 12.** Diseña el servicio que encuentra el conductor más cercano entre un millón que se mueven cada pocos segundos. 🔴

⏱️ **30 segundos.** Una rejilla de celdas (o *geohash*) en memoria, actualizada en cada posición nueva; la consulta mira la celda del pasajero y las vecinas, ampliando si hace falta. Repartida por zonas en varios servidores.

🗣️ **2 minutos.** Un k-d estático no sirve con un millón de actualizaciones por pocos segundos: la rejilla actualiza en `O(1)` (quitar de una celda, poner en otra). El tamaño de celda se elige para que haya unos pocos conductores en cada una.

🔬 **El detalle.** Lo que se usa en producción: índices por celdas (*geohash*, H3, S2) y bases con índices espaciales.

**05 → Problema: La antena más cercana.**

**Pista 2:** con puntos repartidos al azar, una rejilla de celdas de lado parecido a la distancia típica: cada casa mira su celda y las vecinas.

**Pista 3:** celdas de lado `≈ L / √n` con `L = 10⁶`; para cada casa, anillos de celdas crecientes hasta que el anillo esté más lejos que la mejor distancia; o un árbol k-d con poda.

**05 → Problema: Restaurantes en la pantalla.**

**Pista 2:** fuera de línea: cada rectángulo es combinación de cuatro cuentas de «esquina» `x ≤ X, y ≤ Y`, que se responden con un barrido por `x` y un Fenwick sobre `y`.

**Pista 3:** comprime las `y`; ordena puntos y esquinas por `x`; al pasar por cada esquina, consulta el prefijo del Fenwick; combina con signos `+ − − +`; `O((n + q) log n)`.

**05 → Problema: Cell Towers.**

**Pista 2:** con pocas torres y marcas, para cada marca la torre más cercana comparando con todas.

**Pista 3:** recorre la carretera tramo a tramo calculando la posición de cada marca (y de la final si corresponde); imprime cuando cambia la torre; cuidado con los empates de distancia que fije el enunciado.


---

# 06 — Datos masivos

**06 → 1.** ¿Qué se cuenta como coste en el modelo de memoria externa? 🟢

⏱️ **30 segundos.** El número de bloques que se leen y escriben entre memoria y disco, no el de operaciones.

🗣️ **2 minutos.** Con memoria de `M` elementos y bloques de `B`, recorrer cuesta `N/B` y ordenar `(N/B) log_{M/B}(N/B)`. Lo que no esté en memoria cuesta un bloque por acceso.

🔬 **El detalle.** Es el modelo de Aggarwal y Vitter (1988).

**06 → 2.** ¿Qué tres fases tiene MapReduce? 🟢

⏱️ **30 segundos.** *Map*, *shuffle* y *reduce*.

🗣️ **2 minutos.** *Map* transforma cada registro en pares clave-valor en la máquina donde están los datos; *shuffle* agrupa por clave a través de la red; *reduce* combina los valores de cada clave.

🔬 **El detalle.** Un *combiner* hace un *reduce* local antes del *shuffle*.

**06 → 3.** ¿Qué garantiza Misra-Gries con `k` contadores? 🟢

⏱️ **30 segundos.** Todo elemento con frecuencia mayor que `n/(k + 1)` acaba con contador, y cada contador subestima la frecuencia en como mucho `n/(k + 1)`.

🗣️ **2 minutos.** Con memoria `O(k)` y una pasada, determinista. Da candidatos: para las frecuencias exactas, una segunda pasada contándolos.

🔬 **El detalle.** Con `k = 1` es el algoritmo de la mayoría de Boyer-Moore.

**06 → 4.** ¿Cuántas pasadas necesita ordenar 100 GB con 4 GB de memoria, y por qué? 🟡

⏱️ **30 segundos.** Dos pasadas completas: una para crear 25 *runs* ordenados de 4 GB, y una de mezcla de 25 vías.

🗣️ **2 minutos.** Con bloques de 1 MB, la mezcla admite hasta unas 4 000 vías: 25 caben de sobra. Cada dato se lee dos veces y se escribe dos: 400 GB de E/S.

🔬 **El detalle.** Con `N/M` mayor que el número de vías posible, harían falta más pasadas de mezcla: `⌈log_{vías}(N/M)⌉`.

**06 → 5.** ¿Qué diferencia hay entre el modelo de flujo y el de memoria externa? 🟡

⏱️ **30 segundos.** En el de flujo, cada dato se ve una vez y la memoria es sublineal; en el de memoria externa, los datos están en disco, se pueden releer, y lo que se cuenta son las E/S.

🗣️ **2 minutos.** El flujo da respuestas aproximadas (o muestras) porque no puede guardar los datos; la memoria externa da respuestas exactas a costa de pasadas por el disco.

🔬 **El detalle.** Un mismo problema (los más frecuentes) tiene versión exacta en memoria externa y aproximada en flujo.

**06 → 6.** ¿Para qué sirve un *combiner*, y cuándo no se puede usar? 🟡

⏱️ **30 segundos.** Para reducir en cada máquina lo que viajará por la red: en contar palabras, cada máquina envía su mapa de cuentas, no un par por aparición. No se puede usar si la operación no es asociativa y conmutativa.

🗣️ **2 minutos.** Una media no se combina tal cual (la media de medias no es la media): se envían suma y cuenta. Una mediana no tiene *combiner* exacto.

🔬 **El detalle.** Con un buen *combiner*, el *shuffle* pasa de proporcional a los datos a proporcional a las claves distintas.

**06 → 7.** ¿Por qué «más máquinas es más rápido» es falso, con la ley de Amdahl? 🟠

⏱️ **30 segundos.** Porque la parte que no se reparte limita la aceleración: con una fracción secuencial `s`, la aceleración con `p` máquinas es como mucho `1 / (s + (1 − s)/p)`.

🗣️ **2 minutos.** Con `s = 10 %`, ni infinitas máquinas pasan de 10 veces. Además, el *shuffle* crece con las máquinas y la más lenta marca el final de cada fase.

🔬 **El detalle.** Hay tareas que empeoran al repartirlas: si el coste es de red, más máquinas es más red.

**06 → 8.** ¿Por qué un árbol B tiene nodos grandes, y qué tiene que ver con `B`? 🟠

⏱️ **30 segundos.** Para que cada nodo ocupe un bloque del disco: con `B` claves por nodo, la altura es `log_B N` y cada búsqueda lee `log_B N` bloques.

🗣️ **2 minutos.** Con `B = 1 000`, mil millones de claves caben en un árbol de altura 3; un binario tendría 30 niveles y 30 lecturas.

🔬 **El detalle.** Es la estructura de casi todos los índices de bases de datos ([`07/02`](../07-arboles/02-bst-y-balanceados.md)).

**06 → 9.** ¿Cómo encuentras las 100 palabras más frecuentes de 1 TB en un clúster? 🟠

⏱️ **30 segundos.** Contando por palabra en cada máquina (*map* con *combiner*), enviando cada palabra a la máquina que le toca por *hash* (*shuffle*), sumando allí (*reduce*), y quedándose cada máquina con su top 100; al final, un top 100 de los 100 tops.

🗣️ **2 minutos.** El top global está en la unión de los tops locales de los *reducers*, porque cada palabra está entera en un solo *reducer*. Lo que viaja es el vocabulario de cada máquina, no el texto.

🔬 **El detalle.** Si basta una aproximación, Count-Min por máquina (se suman celda a celda) y un *heap*.

**06 → 10.** ¿Qué harías para tener las frecuencias exactas de los candidatos de Misra-Gries? 🟠

⏱️ **30 segundos.** Una segunda pasada por el flujo contando solo los `k` candidatos.

🗣️ **2 minutos.** Si el flujo se puede releer (está en disco), la segunda pasada da las frecuencias exactas de los candidatos y permite descartar los que no llegan al umbral.

🔬 **El detalle.** Si no se puede releer, las cuentas son estimaciones con error de hasta `n/(k + 1)`.

**06 → 11.** Demuestra que Misra-Gries subestima cada frecuencia en como mucho `n/(k + 1)`. 🔴

⏱️ **30 segundos.** Cada vez que se resta 1 a todos, se descartan `k + 1` apariciones (las `k` de los contadores y la que llega). Eso puede pasar como mucho `n/(k + 1)` veces, y cada vez el contador de `x` baja como mucho 1.

🗣️ **2 minutos.** Sea `d` el número de restas. Cada resta elimina `k + 1` unidades del total de apariciones contadas, que nunca pasa de `n`: `d (k + 1) ≤ n`. El contador de `x` pierde como mucho una unidad por resta: `f(x) − contador(x) ≤ d ≤ n/(k + 1)`.

🔬 **El detalle.** Si `f(x) > n/(k + 1)`, el contador final es positivo: `x` sobrevive.

**06 → 12.** Diseña la ordenación externa de 100 GB con 4 GB de memoria y bloques de 1 MB: *runs*, vías de la mezcla, búferes y volumen de E/S. 🔴

⏱️ **30 segundos.** 25 *runs* de 4 GB ordenados en memoria; una mezcla de 25 vías con 25 búferes de entrada de unos 150 MB y uno de salida; 400 GB de E/S, unos 13 minutos a 500 MB/s.

🗣️ **2 minutos.** Fase 1: leer 4 GB, ordenar en memoria, escribir; 25 veces (200 GB de E/S). Fase 2: un *heap* con la cabeza de cada *run*; búferes grandes para leer en secuencias largas (200 GB de E/S).

🔬 **El detalle.** Con búferes de un bloque (1 MB) también funcionaría, pero con más saltos del disco; con discos mecánicos, búferes grandes.

**06 → Problema: Los candidatos del flujo.**

**Pista 2:** Misra-Gries tal cual, con un mapa de como mucho `k` contadores.

**Pista 3:** la resta a todos cuesta `O(k)`, pero ocurre como mucho `n/(k + 1)` veces: total `O(n)` amortizado. Imprime ordenado por valor.

**06 → Problema: Ordenar lo que no cabe.**

**Pista 2:** *runs* del tamaño de la memoria y una mezcla de tantas vías como búferes quepan.

**Pista 3:** `100/4 = 25` *runs*; mezcla de 25 vías en una pasada; búferes de unos 150 MB; E/S `4 × 100 GB = 400 GB`, unos 800 s a 500 MB/s.

**06 → Problema: Las palabras más frecuentes.**

**Pista 2:** contar en cada máquina (*combiner*), repartir por *hash* de la palabra, sumar y sacar un top 100 por *reducer*, y un top final.

**Pista 3:** lo que viaja es el vocabulario de cada máquina con sus cuentas (cientos de MB, no 10 GB); el top global está entre los tops de los *reducers*. Aproximado: Count-Min por máquina, sumado celda a celda, y un *heap*.


---

# 07 — Simulación

**07 → S1.** ¿Qué diferencia hay entre un algoritmo Las Vegas y uno Monte Carlo? 🟢

⏱️ **30 segundos.** Las Vegas siempre acierta y su tiempo es aleatorio; Monte Carlo tarda un tiempo acotado y acierta con probabilidad al menos `1 − ε`.

🗣️ **2 minutos.** *Quicksort* con pivote aleatorio frente a Freivalds. El error de Monte Carlo se baja repitiendo; el tiempo de Las Vegas se acota en esperanza.

🔬 **El detalle.** Uno se convierte en el otro cortando por tiempo (Markov) o repitiendo hasta verificar.

**07 → S2.** ¿Qué garantiza una familia universal de funciones de *hash*? 🟢

⏱️ **30 segundos.** Que dos claves distintas cualesquiera chocan con probabilidad como mucho `1/m`, sobre el sorteo de la función.

🗣️ **2 minutos.** De ahí, la cadena esperada `1 + α` para cualquier conjunto de claves: ninguna entrada es mala para muchas funciones de la familia.

🔬 **El detalle.** La función se sortea después de fijada la entrada, con una semilla que el adversario no conoce.

**07 → S3.** ¿Qué responde un filtro de Bloom, y qué error puede cometer? 🟢

⏱️ **30 segundos.** «Seguro que no está» o «quizá está». Puede dar falsos positivos, nunca falsos negativos.

🗣️ **2 minutos.** Con `m/n` bits por elemento y `k` funciones, la tasa es `≈ (1 − e^{−kn/m})ᵏ`; con 9,6 bits y 7 funciones, un 1 %.

🔬 **El detalle.** No borra ni enumera.

**07 → S4.** ¿Cómo se baraja un arreglo de forma uniforme en `Θ(n)`? 🟢

⏱️ **30 segundos.** Con Fisher-Yates: para `i` de `n − 1` a 1, intercambiar `a[i]` con `a[j]`, `j` uniforme en `[0, i]`.

🗣️ **2 minutos.** Cada una de las `n!` secuencias de elecciones da una permutación distinta. Con `j` en `[0, n − 1]` el resultado está sesgado.

🔬 **El detalle.** En las librerías: `std::shuffle`, `Collections.shuffle`, `random.shuffle`.

**07 → S5.** ¿Cuánto cuesta una consulta de rango ortogonal en un árbol k-d del plano? 🟡

⏱️ **30 segundos.** `O(√n + k)`, con `k` los puntos que devuelve.

🗣️ **2 minutos.** Una recta corta `O(√n)` regiones del árbol: cada dos niveles baja por dos de los cuatro nietos.

🔬 **El detalle.** Con un árbol de rangos, `O(log² n + k)` a cambio de `O(n log n)` memoria.

**07 → S6.** ¿Qué estima Count-Min y en qué sentido se equivoca? 🟢

⏱️ **30 segundos.** La frecuencia de un elemento en un flujo, siempre por exceso: como mucho `εN` de más con probabilidad `1 − δ`.

🗣️ **2 minutos.** Cada fila suma también las cuentas de los que chocan; el mínimo de las filas es la estimación. `w = ⌈e/ε⌉`, `d = ⌈ln(1/δ)⌉`.

🔬 **El detalle.** El error es relativo al total `N`, no a cada frecuencia.

**07 → S7.** ¿Qué resuelve el *reservoir sampling*? 🟢

⏱️ **30 segundos.** Elegir `k` elementos uniformes de un flujo de longitud desconocida en una pasada, con memoria `O(k)`.

🗣️ **2 minutos.** El elemento `i` entra con probabilidad `k/i` en una casilla al azar; por inducción, al final cada uno está con probabilidad `k/n`.

🔬 **El detalle.** Con `k = 1`, un nodo al azar de una lista enlazada.

**07 → S8.** ¿Cuántos bits por elemento necesita un Bloom con un 1 % de falsos positivos? 🟡

⏱️ **30 segundos.** Unos 9,6 bits por elemento, con 7 funciones.

🗣️ **2 minutos.** `m/n = −ln ε / (ln 2)²` y `k = (m/n) ln 2`. Con `k` entero, el menor `m` que cumple el 1 % para `n = 1 000` es 9 593 bits.

🔬 **El detalle.** Cada décima parte menos de error cuesta unos 4,8 bits más por elemento.

**07 → S9.** ¿Qué garantiza Misra-Gries con `k` contadores? 🟡

⏱️ **30 segundos.** Que todo elemento con frecuencia mayor que `n/(k + 1)` sobrevive, y que cada contador subestima en como mucho `n/(k + 1)`.

🗣️ **2 minutos.** Cada resta general elimina `k + 1` apariciones, así que hay como mucho `n/(k + 1)` restas. Es determinista y de una pasada.

🔬 **El detalle.** Para las frecuencias exactas de los candidatos, una segunda pasada.

**07 → S10.** ¿Cuál es la distribución estacionaria de un paseo aleatorio en un grafo no dirigido conexo? 🟡

⏱️ **30 segundos.** `π(v) = grado(v) / 2|E|`.

🗣️ **2 minutos.** Se comprueba que `πP = π`. En el grafo de juguete `G`, `3/14` para `B` y `E` y `1/7` para los demás.

🔬 **El detalle.** Si el grafo es bipartito, la cadena no converge, pero la fracción de tiempo sí tiende a `π`.

**07 → S11.** «Aleatorizado significa que a veces falla.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que Las Vegas no falla nunca: lo aleatorio es el tiempo. Y Monte Carlo falla con una probabilidad que se elige, tan pequeña como se quiera.

🗣️ **2 minutos.** *Quicksort* aleatorio ordena siempre bien. Freivalds con 60 repeticiones se equivoca con probabilidad `10⁻¹⁸`, menos que el *hardware*.

🔬 **El detalle.** Lo que aporta la aleatoriedad es que ningún adversario elige la entrada mala.

**07 → S12.** Tu solución con `unordered_map` pasa los ejemplos y da TLE tras un *hack*. ¿Qué ha pasado y qué cambias? 🟠

⏱️ **30 segundos.** Un *anti-hash test*: la función de la librería es pública, y el *hack* manda todas las claves a la misma cubeta. Se cambia por un *hash* con semilla del reloj (`splitmix64`).

🗣️ **2 minutos.** En libstdc++, el *hash* de un entero es la identidad y la cubeta es `x mod` un primo de una lista fija: múltiplos de ese primo colisionan todos. Con una semilla aleatoria, el atacante no sabe qué claves chocan.

🔬 **El detalle.** La defensa demostrable es una familia universal; `splitmix64` con semilla es la práctica.

**07 → S13.** Tu barajado intercambia cada posición con una de todo el arreglo. ¿Qué tiene de malo? 🟠

⏱️ **30 segundos.** Que está sesgado: hay `nⁿ` secuencias equiprobables para `n!` órdenes, y `n!` no divide a `nⁿ`.

🗣️ **2 minutos.** Con tres elementos, unos órdenes salen 5 de cada 27 veces y otros 4. La corrección es elegir `j` en `[0, i]` recorriendo de atrás hacia delante.

🔬 **El detalle.** Es la autopsia de [`19/04`](04-muestreo-y-markov.md).

**07 → S14.** Alguien propone un filtro de Bloom para detectar identificadores repetidos entre `10⁶`. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que no hace falta: `10⁶` enteros de 64 bits son 8 MB, y un conjunto *hash* (u ordenar) da la respuesta exacta. El Bloom se justifica cuando la estructura exacta no cabe.

🗣️ **2 minutos.** Con un Bloom, un falso positivo diría «repetido» sin serlo. Aceptar error solo tiene sentido si se gana algo que haga falta: memoria o red.

🔬 **El detalle.** Es el problema de la simulación «¿Hay repetidos?».

**07 → S15.** Tu árbol k-d con vectores de 300 dimensiones no es más rápido que recorrerlos todos. ¿Por qué? 🟠

⏱️ **30 segundos.** Por la maldición de la dimensión: con 300 dimensiones, las distancias se parecen y la poda por regiones no descarta casi nada.

🗣️ **2 minutos.** Hace falta `n ≫ 2^d` para que el árbol gane; con `d = 300` es imposible. Se usan métodos aproximados (grafos de proximidad, LSH) o la fuerza bruta vectorizada.

🔬 **El detalle.** Reducir la dimensión antes (PCA, proyecciones aleatorias) también ayuda.

**07 → S16.** «Para ordenar 100 GB hace falta una máquina con 100 GB de memoria.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que no: la ordenación externa ordena 100 GB con 4 GB en dos pasadas por el disco, leyendo y escribiendo en secuencia.

🗣️ **2 minutos.** 25 *runs* de 4 GB y una mezcla de 25 vías con un *heap*. El coste son unos 400 GB de E/S, minutos en un disco moderno.

🔬 **El detalle.** Es lo que hace `sort` de Unix con ficheros grandes.

**07 → S17.** «Con más máquinas, un trabajo MapReduce termina antes.» ¿Siempre? 🟠

⏱️ **30 segundos.** No: la fracción secuencial, el *shuffle* por la red y la máquina más lenta limitan la aceleración (ley de Amdahl).

🗣️ **2 minutos.** Con un 10 % secuencial, el límite es 10 veces. Si el *shuffle* domina, más máquinas pueden empeorar el total.

🔬 **El detalle.** Un buen *combiner* y un reparto equilibrado de claves importan más que el número de máquinas.

**07 → S18.** Tu Count-Min da frecuencias altas a elementos que casi no aparecen. ¿Es un error de programación? 🟠

⏱️ **30 segundos.** No necesariamente: Count-Min sobrestima en hasta `εN`, y para los elementos raros ese error es mayor que su frecuencia real.

🗣️ **2 minutos.** Con `N = 10⁹` y `ε = 0,1 %`, un elemento que aparece 10 veces puede estimarse en un millón. Es el contrato de la estructura, no un fallo.

🔬 **El detalle.** Si importan los raros, más columnas (menos `ε`), otra estructura o el conteo exacto.

**07 → S19.** Demuestra que Freivalds acepta una `C` incorrecta con probabilidad como mucho `1/2`. 🔴

⏱️ **30 segundos.** Si `D = AB − C ≠ 0` con `d_{ij} ≠ 0`, fijado el resto de `r`, `(Dr)ᵢ = d_{ij} rⱼ + s`; como mucho uno de los dos valores de `rⱼ` la anula. `P(Dr = 0) ≤ 1/2`.

🗣️ **2 minutos.** Por decisiones diferidas: se sortean todas las coordenadas de `r` salvo `rⱼ`; con `s` fijo, solo un valor de `rⱼ` (o ninguno) hace `d_{ij} rⱼ + s = 0`. Como `Dr = 0` exige `(Dr)ᵢ = 0`, la cota pasa a la aceptación.

🔬 **El detalle.** Con `k` repeticiones, `2⁻ᵏ`.

**07 → S20.** Diseña cómo detectar, con memoria fija, las IP que generan más del 1 % del tráfico de un enlace que recibe `10⁹` paquetes por hora, y di qué garantiza tu diseño. 🔴

⏱️ **30 segundos.** Misra-Gries con `k = 100` contadores (umbral `n/101 < 1 %` de `n`): todas las IP de más del 1 % sobreviven; una segunda pasada o un Count-Min confirma las cuentas. Memoria fija.

🗣️ **2 minutos.** Con `10⁹` paquetes, una IP del 1 % aparece `10⁷` veces y el error de Misra-Gries es como mucho `≈ 9,9·10⁶`: su contador queda positivo. Para descartar falsos candidatos, se cuentan exactamente en la ventana siguiente o con un Count-Min en paralelo.

🔬 **El detalle.** Por ventanas (cada hora), un Misra-Gries por ventana; distribuido por enlaces, se suman los resúmenes.

**07 → Problema: El depósito del registro.**

**Pista 2:** *reservoir sampling*: el elemento `i` entra si `j = rᵢ mod i < k`, en la casilla `j`.

**Pista 3:** los `k` primeros entran directos; `rᵢ` y `i` en 64 bits; una pasada.

**07 → Problema: Dimensionar el filtro.**

**Pista 2:** buscar el menor `m` (búsqueda binaria) tal que algún entero `k` cerca de `(m/n) ln 2` cumpla la tasa.

**Pista 3:** para cada `m`, prueba `k = ⌊(m/n) ln 2⌋` y los vecinos; la tasa es creciente al bajar `m`; con `n = 1 000` y `ε = 1 %` sale `9 593` con `k = 7`.

**07 → Problema: ¿Es el producto?.**

**Pista 2:** Freivalds módulo `10⁹ + 7`: comparar `A(Br)` con `Cr` para `r` aleatorio.

**Pista 3:** `r` uniforme en `[0, 10⁹ + 7)`: error `≤ 1/p` por repetición; 2 o 3 repeticiones; productos módulo `p` en 64 bits; lectura rápida de `3·10⁶` números.

**07 → Problema: ¿Hay repetidos?.**

**Pista 2:** con `10⁶` identificadores, 8 MB: ordenar o un conjunto *hash* da la respuesta exacta.

**Pista 3:** ordena y compara vecinos, `O(n log n)`; o un `HashSet` con semilla si hay riesgo de *hack*.

**07 → Problema: Same Differences.**

**Pista 2:** `aⱼ − j = aᵢ − i`: los pares buscados comparten el valor `aᵢ − i`.

**Pista 3:** un mapa de cuentas de `aᵢ − i`; cada grupo de tamaño `c` aporta `c(c − 1)/2`; en 64 bits.

**07 → Problema: Remove Two Letters.**

**Pista 2:** los borrados en las posiciones `i` e `i + 1` dan la misma cadena si y solo si `s[i] = s[i + 2]`.

**Pista 3:** la respuesta es `n − 1` menos el número de `i` con `s[i] = s[i + 2]`; sin *hashing*.

**07 → Problema: Andrey and Problem.**

**Pista 2:** ordena por probabilidad descendente y añade amigos mientras la probabilidad de exactamente un éxito aumente.

**Pista 3:** con el conjunto `S`, `P = Π(1 − pᵢ) · Σ pᵢ/(1 − pᵢ)`; si algún `pᵢ = 1`, la respuesta es 1.

**07 → Problema: Tourism.**

**Pista 2:** *color coding*: con un reparto aleatorio de las ciudades en dos grupos, un camino sin ciclos impares alterna grupos; se busca el mejor camino alterno con una DP.

**Pista 3:** en cada reparto, DP de `k` pasos alternando grupos, `O(k · n²)`; un reparto al azar acierta con el camino óptimo con probabilidad al menos `2⁻⁹` (con `k ≤ 10`), así que hacen falta unos miles de repartos para fallar con probabilidad despreciable.

