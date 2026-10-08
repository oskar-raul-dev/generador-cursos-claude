# Respuestas — bloque 18: Geometría

> Solucionario del bloque `18`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--vectores-productos-y-orientación) · [02](#02--rectas-y-segmentos) · [03](#03--polígonos) · [04](#04--envolvente-convexa) · [05](#05--barrido-geométrico) · [06](#06--geometría-avanzada) · [07](#07--simulación)

---

# 01 — Vectores, productos y orientación

**01 → 1.** ¿Qué miden el producto punto y el producto cruz de dos vectores del plano? 🟢

⏱️ **30 segundos.** El punto, `|a| |b| cos θ`, mide cuánto apuntan en la misma dirección; el cruz, `|a| |b| sen θ`, el área del paralelogramo que forman, con signo.

🗣️ **2 minutos.** Con `u = (4,0)` y `v = (4,3)`: `u · v = 16` (ángulo agudo) y `u × v = 12` (de `u` a `v` se gira en sentido antihorario; el paralelogramo mide 12).

🔬 **El detalle.** En 3D el producto cruz es un vector; en el plano se usa su componente `z`, que es el número que da la fórmula.

**01 → 2.** ¿Cómo decides si tres puntos giran a la izquierda, a la derecha o están alineados? 🟢

⏱️ **30 segundos.** Con el signo de `orient(a, b, c) = (b − a) × (c − a)`: positivo, izquierda; negativo, derecha; cero, alineados.

🗣️ **2 minutos.** Son dos multiplicaciones y una resta, exactas en enteros. Con `(0,0)`, `(4,0)`, `(4,3)` vale 12: giro a la izquierda.

🔬 **El detalle.** La plantilla devuelve el signo y no el valor, para que nadie lo compare con un umbral.

**01 → 3.** ¿Cómo calculas el área de un triángulo a partir de sus vértices? 🟢

⏱️ **30 segundos.** La mitad del valor absoluto del producto cruz de dos lados: `|orient(a, b, c)| / 2`.

🗣️ **2 minutos.** Con `(0,0)`, `(4,0)`, `(4,3)`: `12 / 2 = 6`. Se guarda el doble, que es entero, y se divide al imprimir.

🔬 **El detalle.** Herón, con tres raíces, da 0 para `(0,0)`, `(10⁹,1)`, `(2·10⁹,3)`, cuya área es `5·10⁸`.

**01 → 4.** ¿Qué responde el signo del producto punto y qué responde el del producto cruz? 🟡

⏱️ **30 segundos.** El punto dice si el ángulo es agudo, recto u obtuso; el cruz, hacia qué lado se gira, o si son paralelos.

🗣️ **2 minutos.** Juntos clasifican la posición relativa de dos vectores: cruz 0 y punto positivo, misma dirección; cruz 0 y punto negativo, direcciones opuestas; cruz distinto de 0, el punto da el tipo de ángulo.

🔬 **El detalle.** El punto es simétrico (`a · b = b · a`); el cruz, antisimétrico (`b × a = −a × b`).

**01 → 5.** ¿Hasta qué coordenadas cabe el producto cruz en 64 bits con signo? 🟡

⏱️ **30 segundos.** Con coordenadas de valor absoluto hasta `10⁹`: las diferencias llegan a `2·10⁹` y el producto cruz a `8·10¹⁸`, por debajo de `2⁶³ ≈ 9,2·10¹⁸`.

🗣️ **2 minutos.** La cota es `2 · (2c)² = 8c²`, que cabe en 64 bits con signo mientras `c` no pase de unos `1,07·10⁹`.

🔬 **El detalle.** Por encima: `__int128` en C++, `Math.multiplyHigh` o `BigInteger` en Java; Python no tiene límite.

**01 → 6.** ¿Por qué se comparan distancias por su cuadrado? 🟡

⏱️ **30 segundos.** Porque la raíz es creciente: comparar `d²` da el mismo orden que comparar `d`, y es exacto en enteros.

🗣️ **2 minutos.** La raíz en `double` redondea: dos distancias distintas pueden salir iguales, y además cuesta más. La raíz se hace una vez, al imprimir.

🔬 **El detalle.** Con coordenadas de `10⁹`, `d²` llega a `8·10¹⁸`: cabe en 64 bits.

**01 → 7.** ¿Por qué el producto cruz en `double` puede decir «alineados» cuando no lo están? 🟠

⏱️ **30 segundos.** Porque un `double` tiene 53 bits de mantisa: los productos de `10¹⁸` se redondean al múltiplo de 128 más cercano, y una resta de dos números casi iguales puede dar 0.

🗣️ **2 minutos.** Con `(0,0)`, `(10⁹, 10⁹ − 1)`, `(10⁹ − 1, 10⁹ − 2)`: `999 999 998 000 000 001` se redondea a `…000`, igual que el otro producto, y la resta da 0. En `long long`, `−1`.

🔬 **El detalle.** No es mala suerte: cerca de `10¹⁸`, los `double` representables están separados por 128.

**01 → 8.** ¿Cuándo hace falta un épsilon, y de qué depende su valor? 🟠

⏱️ **30 segundos.** Cuando el resultado no es un polinomio de las coordenadas (distancias, ángulos, puntos de corte) o la entrada es real. Su valor depende de la magnitud de los datos.

🗣️ **2 minutos.** Con coordenadas de `10⁴`, los productos son de `10⁸` y `1e-9` sirve; con `10⁶`, los productos son de `10¹²` y el error de redondeo ya ronda `10⁻⁴`. Se razona en error relativo: unos `10⁻¹⁵` del mayor valor intermedio.

🔬 **El detalle.** La alternativa exacta son las fracciones: `Fraction` en Python, numerador y denominador en enteros en C++ y Java.

**01 → 9.** ¿Qué cambia entre C++, Java y Python al calcular un producto cruz con coordenadas de hasta `10⁹`? 🟠

⏱️ **30 segundos.** En C++, `long long` y el desbordamiento con signo es indefinido; en Java, `long` y el desbordamiento da la vuelta en silencio; en Python, enteros sin límite.

🗣️ **2 minutos.** La trampa común en C++ y Java es el tipo de las coordenadas: si son `int`, el producto se hace en 32 bits y desborda antes de guardarse en el `long`. En Python no hay trampa, pero cada operación es 30–50 veces más lenta.

🔬 **El detalle.** Con coordenadas de `10⁹`, el producto llega a `8·10¹⁸`: cabe en 64 bits, sin margen.

**01 → 10.** ¿Por qué no se decide un giro con `atan2`? 🟠

⏱️ **30 segundos.** Porque `atan2` es aproximado: con puntos casi alineados, la diferencia de ángulos sale 0 o con el signo equivocado.

🗣️ **2 minutos.** Con `(0,0)`, `(117 721 111, 259 577 155)` y `(232 542 314, 512 759 961)`, las dos direcciones salen iguales en `double` en Java y en Python, y el producto cruz exacto es 1. Además hay que normalizar la diferencia a `(−π, π]`.

🔬 **El detalle.** El fallo depende de la librería matemática: un mismo trío puede fallar en un lenguaje y no en otro. El producto cruz en enteros no depende de nada.

**01 → 11.** Demuestra que el signo de `(b − a) × (c − a)` dice hacia qué lado gira `a → b → c`. 🔴

⏱️ **30 segundos.** Trasladando `a` al origen y girando para que `b − a` quede sobre el eje `x` positivo: el producto cruz no cambia, y vale `d · y_c` con `d > 0`.

🗣️ **2 minutos.** El producto cruz es un determinante; la traslación no cambia los vectores diferencia y el giro tiene determinante 1. Con `b − a = (d, 0)`, `orient = d · y_c`, positivo si y solo si `c` queda por encima del eje, es decir, a la izquierda de la dirección `a → b`.

🔬 **El detalle.** Otra forma: `u × v = |u| |v| sen θ`, con `θ ∈ (−π, π]` el ángulo de `u` a `v`; el seno es positivo si y solo si `θ ∈ (0, π)`, el giro antihorario.

**01 → 12.** Da tres puntos con coordenadas menores que `10⁹` cuyo producto cruz en `double` salga 0 sin estar alineados, y explica por qué ocurre. 🔴

⏱️ **30 segundos.** `(0,0)`, `(10⁹, 10⁹ − 1)` y `(10⁹ − 1, 10⁹ − 2)`: el producto cruz exacto es `−1` y en `double` sale 0.

🗣️ **2 minutos.** `10⁹ · (10⁹ − 2) = 999 999 998 000 000 000` es múltiplo de 128 y se representa exacto; `(10⁹ − 1)² = 999 999 998 000 000 001` no, y se redondea al anterior. La resta da 0.

🔬 **El detalle.** Cerca de `10¹⁸ ≈ 2⁵⁹·⁸`, el exponente es 59 y la separación entre `double` consecutivos es `2⁵⁹⁻⁵² = 128`.

**01 → Problema: Las esquinas del repartidor.**

**Pista 2:** `orient` de cada trío de esquinas consecutivas, `i − 1`, `i`, `i + 1`, y contar por signo.

**Pista 3:** productos en 64 bits; la media vuelta sobre la misma recta da 0 y cuenta como recto; lectura rápida para `2·10⁵` esquinas.

**01 → Problema: El ángulo del brazo.**

**Pista 2:** cruz y punto de `A − B` y `C − B`: con cruz 0, `NULO` si el punto es positivo y `LLANO` si es negativo; si no, el signo del punto da `AGUDO`, `RECTO` u `OBTUSO`.

**Pista 3:** los vectores salen de `B`; con coordenadas de `10⁹`, los dos productos llegan a `8·10¹⁸`: 64 bits.

**01 → Problema: Triángulos de área entera.**

**Pista 2:** el área es entera si y solo si el doble (`orient`) es par, y la paridad de `orient` solo depende de las coordenadas módulo 2: hay cuatro clases de puntos.

**Pista 3:** cuenta los puntos de cada clase `(x mod 2, y mod 2)` (con `& 1` para los negativos en C++ y Java); para cada multiconjunto de tres clases (20), comprueba con representantes si el doble del área es par y suma el producto de combinaciones. La respuesta llega a `C(2·10⁵, 3) ≈ 1,3·10¹⁵`: 64 bits.

**01 → Problema: Valid Boomerang.**

**Pista 2:** tres puntos forman un bumerán si el producto cruz de dos lados no es 0 (eso descarta también los repetidos).

**Pista 3:** una sola comprobación: `cross(p₂ − p₁, p₃ − p₁) ≠ 0`.

**01 → Problema: Check If It Is a Straight Line.**

**Pista 2:** el producto cruz de `p₁ − p₀` con cada `pᵢ − p₀` tiene que ser 0.

**Pista 3:** sin pendientes, que fallan con las verticales; `O(n)`.

**01 → Problema: Find the Point.**

**Pista 2:** la reflexión de `p` respecto de `q` es `2q − p`.

**Pista 3:** `(2·qx − px, 2·qy − py)` por consulta.

**01 → Problema: Largest Triangle Area.**

**Pista 2:** todos los tríos, con el área como la mitad del valor absoluto del producto cruz.

**Pista 3:** `C(50, 3) ≈ 2·10⁴` tríos; guarda el máximo del doble y divide al final.

**01 → Problema: Point Location Test.**

**Pista 2:** el signo de `orient(p₁, p₂, p₃)`.

**Pista 3:** `LEFT` si es positivo, `RIGHT` si es negativo y `TOUCH` si es 0; en 64 bits.

**01 → Problema: Valid Square.**

**Pista 2:** las seis distancias al cuadrado entre los cuatro puntos: cuatro iguales (lados) y dos iguales al doble (diagonales), con el lado mayor que 0.

**Pista 3:** ordena las seis: `d[0] > 0`, `d[0] = d[1] = d[2] = d[3]` y `d[4] = d[5] = 2·d[0]`.

**01 → Problema: Trojke.**

**Pista 2:** todos los tríos de letras y el producto cruz igual a 0.

**Pista 3:** guarda las coordenadas de cada letra de la rejilla; como mucho `C(26, 3) = 2 600` tríos.

**01 → Problema: Polar Angles.**

**Pista 2:** un comparador por semiplano y, dentro de cada uno, por producto cruz; los empates, por distancia al origen.

**Pista 3:** semiplano «de arriba»: `y > 0`, o `y = 0` y `x > 0`; dentro, `a` antes que `b` si `cross(a, b) > 0`; con cruz 0, el de menor norma al cuadrado.

**01 → Problema: Max Points on a Line.**

**Pista 2:** para cada punto, la dirección hacia los demás normalizada, `(dx, dy) / gcd`, con un signo canónico, como clave de un mapa.

**Pista 3:** `O(n²)` con un mapa por punto; signo canónico: `dx > 0`, o `dx = 0` y `dy > 0`; los repetidos se suman a todas las rectas del punto.

**01 → Problema: Maximum Number of Visible Points.**

**Pista 2:** ángulos con `atan2` respecto a tu posición, ordenados, duplicados sumando 360°, y una ventana deslizante de ancho `angle`.

**Pista 3:** los puntos en tu misma posición se cuentan aparte, siempre; en la ventana, una tolerancia pequeña (`1e-9`) al comparar ángulos.


---

# 02 — Rectas y segmentos

**02 → 1.** ¿Cómo decides si un punto está sobre un segmento? 🟢

⏱️ **30 segundos.** Con `orient(a, b, p) = 0` (está en la recta) y sus coordenadas entre las de `a` y `b` (está en el tramo).

🗣️ **2 minutos.** La segunda condición es la caja de `a` y `b`, o, equivalente, `(a − p) · (b − p) ≤ 0`. Todo en enteros.

🔬 **El detalle.** Sin la primera, un punto de la caja fuera de la recta pasaría; sin la segunda, cualquier punto de la recta.

**02 → 2.** ¿Qué cuatro orientaciones se calculan para saber si dos segmentos se cortan? 🟢

⏱️ **30 segundos.** `orient(a, b, c)`, `orient(a, b, d)`, `orient(c, d, a)` y `orient(c, d, b)`: de qué lado de cada segmento quedan los extremos del otro.

🗣️ **2 minutos.** Si los dos primeros tienen signos opuestos estrictos y los dos últimos también, se cortan en un punto interior. Si alguno es 0, se mira si ese extremo está dentro del otro segmento.

🔬 **El detalle.** Con las diagonales `(0,0)–(4,3)` y `(4,0)–(0,3)` salen `−1, +1, +1, −1`: se cortan.

**02 → 3.** ¿Cómo se calcula la distancia de un punto a una recta? 🟢

⏱️ **30 segundos.** `|(b − a) × (p − a)| / |b − a|`: el área del paralelogramo entre la base.

🗣️ **2 minutos.** Con `p = (2,1)` y la recta `(0,0)–(4,3)`: `|4 − 6| / 5 = 0,4`. El numerador es entero; la raíz, solo en el denominador.

🔬 **El detalle.** Para comparar distancias a la misma recta basta comparar los productos cruz.

**02 → 4.** ¿Qué diferencia hay entre la distancia de un punto a una recta y a un segmento? 🟡

⏱️ **30 segundos.** La de la recta es la perpendicular; la del segmento coincide con ella solo si la proyección cae dentro del tramo, y si no, es la distancia al extremo más cercano.

🗣️ **2 minutos.** Se proyecta con `t = ((p − a) · (b − a)) / |b − a|²`: si `t ≤ 0`, `|p − a|`; si `t ≥ 1`, `|p − b|`; si no, la de la recta. Con `(5,5)` y `(0,0)–(4,3)`, `t = 35/25 > 1`: `√5`.

🔬 **El detalle.** Los dos topes se deciden en enteros comparando el producto punto con 0 y con `|b − a|²`.

**02 → 5.** ¿Qué casos aparecen cuando alguna de las cuatro orientaciones vale 0? 🟡

⏱️ **30 segundos.** El contacto en un extremo (un 0 con el extremo dentro del otro segmento) y los colineales, que pueden solaparse o estar separados (cuatro ceros).

🗣️ **2 minutos.** Por eso el caso general exige signos opuestos **estrictos**, y todo lo que tenga un 0 se resuelve con `onSegment`: `(0,0)–(4,0)` y `(4,0)–(4,3)` se tocan; `(0,0)–(4,0)` y `(2,0)–(6,0)` se solapan; `(0,0)–(1,0)` y `(2,0)–(3,0)` no se tocan.

🔬 **El detalle.** Un 0 dice que el extremo está en la **recta** del otro; solo la caja dice si está en el **tramo**.

**02 → 6.** ¿Por qué el punto de corte de dos segmentos con extremos enteros no es, en general, entero? 🟡

⏱️ **30 segundos.** Porque es `a + t (b − a)` con `t` cociente de dos productos cruz: un número racional.

🗣️ **2 minutos.** Las diagonales del rectángulo de juguete se cortan en `(2, 1,5)`. Se imprime en `double` o se guarda como fracción.

🔬 **El detalle.** Para una fracción exacta con coordenadas de `10⁹`, el numerador `t·Δx` necesita 128 bits.

**02 → 7.** ¿Por qué se multiplican los signos de las orientaciones y no los productos cruz? 🟡

⏱️ **30 segundos.** Porque los productos cruz llegan a `8·10¹⁸` y su producto desbordaría 64 bits; los signos solo valen `−1`, `0` o `1`.

🗣️ **2 minutos.** `orient` devuelve el signo precisamente para esto: `o₁ · o₂ < 0` es seguro y legible.

🔬 **El detalle.** Multiplicar los productos cruz en `double` también funcionaría casi siempre, pero el signo de un `double` cercano a 0 es justo lo que no se puede fiar.

**02 → 8.** ¿Qué cambia entre C++, Java y Python para representar el punto de corte exacto? 🟠

⏱️ **30 segundos.** En C++ y Java, numerador y denominador en enteros, con `__int128` o `BigInteger` porque pasan de 64 bits; en Python, `Fraction`.

🗣️ **2 minutos.** Lo habitual es imprimir en `double`. Si hay que comparar puntos de corte o deduplicarlos, la fracción reducida (dividiendo por el `gcd` y con el denominador positivo) da una clave exacta.

🔬 **El detalle.** `Fraction` reduce sola y no desborda, a cambio de ser lenta.

**02 → 9.** ¿Cómo calculas la distancia entre dos segmentos, y por qué basta mirar los extremos? 🟠

⏱️ **30 segundos.** Si se cortan, 0; si no, el mínimo de las cuatro distancias de cada extremo al otro segmento.

🗣️ **2 minutos.** Entre dos segmentos que no se cortan, la distancia mínima se alcanza con al menos uno de los dos puntos en un extremo: si los dos fueran interiores, se podría deslizar uno de ellos y acercarse, salvo en el caso paralelo, donde también vale en un extremo.

🔬 **El detalle.** Por eso la distancia entre dos polígonos es el mínimo sobre pares de lados, si no se cortan.

**02 → 10.** ¿Cómo comparas dos distancias punto-recta sin raíces ni `double`? 🟠

⏱️ **30 segundos.** Comparando `cross₁² / len2₁` con `cross₂² / len2₂` en cruz: `cross₁² · len2₂` frente a `cross₂² · len2₁`.

🗣️ **2 minutos.** Son enteros exactos, pero con coordenadas de `10⁹` el cruz llega a `10¹⁸` y su cuadrado a `10³⁶`: hace falta `__int128` (que llega a `1,7·10³⁸`) o `BigInteger`.

🔬 **El detalle.** Si las distancias son a la misma recta, `len2` es igual y basta comparar los `|cross|`.

**02 → 11.** Demuestra que si `c` y `d` quedan a lados estrictamente distintos de la recta `ab`, y `a` y `b` a lados estrictamente distintos de la recta `cd`, los segmentos se cortan en un punto interior de los dos. 🔴

⏱️ **30 segundos.** Si `c` y `d` están a lados estrictos distintos de la recta `ab`, el segmento `cd` corta esa recta en un único punto `q`; si `a` y `b` están a lados distintos de la recta `cd`, el segmento `ab` corta la recta `cd` en un único punto `q′`. Como las dos rectas no son paralelas y se cortan en un solo punto, `q = q′`, que está en los dos segmentos.

🗣️ **2 minutos.** El paso clave es que `orient` es una función continua y lineal a lo largo de un segmento: pasa de negativo a positivo y se anula una sola vez, en el punto de corte con la recta. Los signos estrictos garantizan que ese punto es interior.

🔬 **El detalle.** Si algún signo es 0, el argumento no sirve: por eso el caso degenerado tiene su propia regla.

**02 → 12.** Da el par de segmentos más simple en el que «se cortan si `o₁·o₂ ≤ 0` y `o₃·o₄ ≤ 0`» da un falso positivo, y el más simple en el que la versión con `< 0` estricto y sin más casos da un falso negativo. 🔴

⏱️ **30 segundos.** Falso positivo de `≤ 0`: `(0,0)–(1,0)` y `(2,0)–(3,0)`, colineales y separados. Falso negativo de `< 0` sin más casos: `(0,0)–(4,0)` y `(4,0)–(4,3)`, que se tocan en `(4,0)`.

🗣️ **2 minutos.** En el primero las cuatro orientaciones son 0 y `0 ≤ 0` es cierto; en el segundo, `orient((0,0), (4,0), (4,0)) = 0` y `0 < 0` es falso, así que el caso general no lo ve.

🔬 **El detalle.** La versión correcta combina el `< 0` estricto con las cuatro comprobaciones `onSegment`.

**02 → Problema: La casa más cerca del camino.**

**Pista 2:** distancia de cada casa a cada tramo con la proyección y sus dos topes, y el mínimo.

**Pista 3:** `n · q = 10⁶` distancias; los topes en enteros, la raíz al final, `printf` con 6 decimales.

**02 → Problema: El trazo que se cruza.**

**Pista 2:** intersección entre todos los pares de tramos no consecutivos con la función de los tres casos; los consecutivos solo pueden compartir su esquina común.

**Pista 3:** para dos tramos consecutivos `ab` y `bc`, se cortan de más si `c` está en la recta de `ab` y vuelve hacia `a`: `orient(a, b, c) = 0` y `(a − b) · (c − b) > 0`. Unos `2·10⁶` pares, en 64 bits.

**02 → Problema: Goat Rope.**

**Pista 2:** si el poste está a la izquierda del rectángulo (en `x`), la distancia en `x` es al lado izquierdo; igual por la derecha, arriba y abajo; en una esquina, las dos a la vez.

**Pista 3:** `dx = max(x₁ − x, 0, x − x₂)`, `dy` igual, y la distancia es `√(dx² + dy²)`.

**02 → Problema: Circle and Rectangle Overlapping.**

**Pista 2:** el punto del rectángulo más cercano al centro se obtiene recortando cada coordenada al rango del rectángulo.

**Pista 3:** se solapan si la distancia al cuadrado de ese punto al centro es `≤ r²`; todo en enteros.

**02 → Problema: Line Segment Intersection.**

**Pista 2:** la función de intersección con el caso general estricto y `onSegment` para todo lo que tenga un 0.

**Pista 3:** `YES` o `NO` por consulta; productos en 64 bits.

**02 → Problema: Imperfect GPS.**

**Pista 2:** en el instante `t`, localiza el tramo en el que está el corredor (por tiempos acumulados) e interpola linealmente dentro de él.

**Pista 3:** la fracción recorrida del tramo es `(t − t₀) / (t₁ − t₀)`; con las posiciones del GPS cada `k` segundos, suma las distancias entre ellas y compáralas con la longitud real.

**02 → Problema: White Water Rafting.**

**Pista 2:** la distancia mínima entre dos polígonos que no se cortan es el mínimo de las distancias de cada vértice de uno a cada lado del otro.

**Pista 3:** `O(n · m)` distancias punto-segmento en los dos sentidos; la respuesta es la mitad de esa distancia (el radio de la balsa).

**02 → Problema: Counting Triangles.**

**Pista 2:** tres segmentos forman un triángulo si se cortan dos a dos en tres puntos distintos.

**Pista 3:** con 50 segmentos, `C(50, 3) ≈ 2·10⁴` tríos; precalcula qué pares se cortan y comprueba que los tres puntos de corte no coinciden.

**02 → Problema: Line Segment Intersection.**

**Pista 2:** intersección con sus tres casos y, si son colineales y se solapan, el tramo común: el máximo de los inicios y el mínimo de los finales al ordenar los extremos sobre la recta.

**Pista 3:** si el tramo común es un punto, se imprime como punto; el punto de corte del caso general con `lineIntersection` en `double`; cuida el formato (dos decimales y `-0.00`).

**02 → Problema: Self Crossing.**

**Pista 2:** con giros siempre a la izquierda, el tramo `i` solo puede chocar con el `i − 3`, el `i − 4` o el `i − 5`.

**Pista 3:** tres condiciones sobre las longitudes: con `i − 3` (`d[i] ≥ d[i−2]` y `d[i−1] ≤ d[i−3]`), con `i − 4` (`d[i−1] = d[i−3]` y `d[i] + d[i−4] ≥ d[i−2]`) y con `i − 5` (`d[i−2] ≥ d[i−4]`, `d[i] + d[i−4] ≥ d[i−2]`, `d[i−1] ≤ d[i−3]` y `d[i−1] + d[i−5] ≥ d[i−3]`); `O(n)`.


---

# 03 — Polígonos

**03 → 1.** ¿Qué es la fórmula del cordón y qué dice su signo? 🟢

⏱️ **30 segundos.** `2A = Σ pᵢ × p_{i+1}`, con el último unido al primero. El área es la mitad del valor absoluto; el signo es positivo si los vértices van en sentido antihorario.

🗣️ **2 minutos.** Con `R` da 24 (área 12); con `R` recorrido al revés, `−24`. Con el pentágono `C`, 16 (área 8).

🔬 **El detalle.** Se guarda el doble, entero; el área de un polígono con vértices enteros es múltiplo de `1/2`.

**03 → 2.** ¿Cómo decides si un punto está dentro de un polígono con un rayo? 🟢

⏱️ **30 segundos.** Se lanza un rayo horizontal desde el punto hacia la derecha y se cuentan los lados que cruza: impar, dentro; par, fuera.

🗣️ **2 minutos.** Cada lado se trata como semiabierto en `y` para que un vértice cuente una sola vez, y antes se comprueba si el punto está en el borde, porque el rayo no lo distingue.

🔬 **El detalle.** Con `C`: `(1,1)` cruza un lado (dentro); `(2,2)` cruza dos (fuera, en la muesca).

**03 → 3.** ¿Qué dice el teorema de Pick? 🟢

⏱️ **30 segundos.** Para un polígono simple con vértices enteros: `A = I + B/2 − 1`, con `I` los puntos enteros interiores y `B` los del borde.

🗣️ **2 minutos.** `B` es la suma, por lados, de `gcd(|Δx|, |Δy|)`. Con `R`: `B = 14`, `A = 12`, `I = 6`.

🔬 **El detalle.** En enteros: `2I = 2A − B + 2`.

**03 → 4.** ¿Cuándo se solapan dos rectángulos alineados con los ejes, y cuánto mide su intersección? 🟢

⏱️ **30 segundos.** Cuando se solapan sus intervalos en `x` **y** en `y`. La intersección mide `max(0, min(x₂) − max(x₁)) · max(0, min(y₂) − max(y₁))`.

🗣️ **2 minutos.** Con `[0,4]×[0,3]` y `[2,6]×[1,5]`: ancho 2, alto 2, intersección 4. Con `[4,8]×[0,1]`, el ancho es 0: se tocan y no se solapan.

🔬 **El detalle.** El ancho y el alto se comprueban por separado: con los dos negativos, el producto sería positivo.

**03 → 5.** ¿Por qué la fórmula del cordón funciona también con polígonos no convexos? 🟡

⏱️ **30 segundos.** Porque suma áreas con signo de triángulos desde un punto fijo, y las que caen fuera del polígono aparecen dos veces con signos opuestos y se cancelan.

🗣️ **2 minutos.** Cada punto del plano queda contado tantas veces como el número de vueltas del borde a su alrededor: 1 dentro de un polígono simple antihorario, 0 fuera. No hace falta convexidad.

🔬 **El detalle.** Si el polígono se corta a sí mismo, las regiones con número de vueltas 2 o −1 cuentan así, y el resultado ya no es el área que se ve.

**03 → 6.** ¿Qué diferencia hay entre la paridad de cortes del rayo y el número de vueltas? 🟡

⏱️ **30 segundos.** La paridad dice dentro o fuera; el número de vueltas suma `+1` por cada cruce subiendo y `−1` bajando, y dice cuántas veces rodea el borde al punto.

🗣️ **2 minutos.** Para polígonos simples dan lo mismo. Para polígonos que se cortan, el número de vueltas distingue regiones rodeadas dos veces; la paridad las da por fuera.

🔬 **El detalle.** Es la diferencia entre las reglas *even-odd* y *nonzero* de los programas de dibujo vectorial.

**03 → 7.** ¿Cuántos puntos enteros tiene el segmento entre dos puntos enteros? 🟡

⏱️ **30 segundos.** `gcd(|x₂ − x₁|, |y₂ − y₁|) + 1`, contando los dos extremos.

🗣️ **2 minutos.** El vector se divide en `gcd` pasos iguales de coordenadas enteras. Sumando por lados sin contar uno de los extremos, sale el `B` de Pick.

🔬 **El detalle.** Con un lado de `(0,0)` a `(4,6)`: `gcd = 2`, tres puntos enteros: `(0,0)`, `(2,3)`, `(4,6)`.

**03 → 8.** ¿Por qué el rayo cuenta mal si pasa por un vértice, y cómo se evita? 🟠

⏱️ **30 segundos.** Porque el vértice pertenece a dos lados y se contaría dos veces, o ninguna, según cómo se trate. Se evita con lados semiabiertos en `y`.

🗣️ **2 minutos.** La condición `(a.y > p.y) != (b.y > p.y)` cuenta el vértice para uno solo de sus dos lados si el rayo lo atraviesa, y para ninguno o para los dos si solo lo toca. Los lados horizontales nunca cuentan.

🔬 **El detalle.** Sumar un épsilon a la `y` del rayo es la versión frágil de lo mismo.

**03 → 9.** ¿Qué cambia entre C++, Java y Python al calcular el área de un polígono de `10⁵` vértices con coordenadas de `10⁹`? 🟠

⏱️ **30 segundos.** En C++, las sumas parciales pueden pasar de `2⁶³` aunque el total quepa, y eso es comportamiento indefinido: `__int128`. En Java el desbordamiento da la vuelta de forma definida y el total sale bien. En Python no hay límite.

🗣️ **2 minutos.** Con coordenadas de `10⁹`, cada término llega a `2·10¹⁸` y el total, `2A`, a `8·10¹⁸`. En Java, la aritmética módulo `2⁶⁴` garantiza que, si el total cabe, el resultado es correcto.

🔬 **El detalle.** En Python, la suma de `10⁵` enteros grandes es más lenta pero exacta.

**03 → 10.** ¿Cómo decides en `O(log n)` si un punto está dentro de un polígono convexo? 🟠

⏱️ **30 segundos.** Con búsqueda binaria por ángulo desde un vértice: se encuentra el sector `(p₀, pᵢ, p_{i+1})` que contiene la dirección del punto y se comprueba un solo triángulo.

🗣️ **2 minutos.** Los vértices de un polígono convexo en orden antihorario están ordenados por ángulo vistos desde `p₀`: la binaria usa `orient(p₀, pᵢ, q)`. Después, `orient(pᵢ, p_{i+1}, q)` decide dentro o fuera.

🔬 **El detalle.** Los casos borde son los dos lados que salen de `p₀`: el punto puede estar justo sobre ellos.

**03 → 11.** Demuestra la fórmula del cordón a partir de las áreas con signo de triángulos. 🔴

⏱️ **30 segundos.** Fijando un punto `O` y sumando `pᵢ × p_{i+1}`, el doble del área con signo del triángulo `(O, pᵢ, p_{i+1})`; cada punto del plano queda contado tantas veces como su número de vueltas, que es 1 dentro y 0 fuera.

🗣️ **2 minutos.** Cada triángulo `(O, pᵢ, p_{i+1})` cubre con signo `+` o `−` según el sentido del lado visto desde `O`. Un punto `q` interior queda en una cantidad de triángulos positivos que supera en uno a la de negativos; uno exterior, en tantos de cada signo. La suma es el área.

🔬 **El detalle.** Con `O` en un vértice, la suma es la de una triangulación en abanico, que es la prueba clásica para convexos.

**03 → 12.** Diseña cómo contar los puntos enteros estrictamente dentro de un polígono simple con vértices enteros de hasta `10⁹`, y aplícalo al pentágono `C`. 🔴

⏱️ **30 segundos.** Con Pick: `2I = 2A − B + 2`, con `2A` por el cordón y `B` como suma de `gcd` por lados. Con `C`: `2A = 16`, `B = 14`, `I = 2`.

🗣️ **2 minutos.** `B = gcd(4,0) + gcd(0,3) + gcd(2,2) + gcd(2,2) + gcd(0,3) = 4 + 3 + 2 + 2 + 3 = 14`. Los dos interiores son `(1,1)` y `(3,1)`.

🔬 **El detalle.** Todo en enteros, `Θ(n log C)`; con coordenadas de `10⁹`, el área doble con `__int128` en C++.

**03 → Problema: Salas que se solapan.**

**Pista 2:** dos salas comparten área si se solapan sus intervalos en `x` y en `y`, con desigualdades estrictas.

**Pista 3:** todos los pares: `2·10⁶` comprobaciones; ancho y alto positivos por separado.

**03 → Problema: Boyas en el lago.**

**Pista 2:** rayo horizontal con lados semiabiertos, y el borde comprobado antes con `onSegment`.

**Pista 3:** `n · q = 10⁶` comprobaciones; da igual el sentido en que vengan los vértices.

**03 → Problema: Rectangle Overlap.**

**Pista 2:** no se solapan si uno termina antes de que empiece el otro en algún eje.

**Pista 3:** se solapan si `max(x₁) < min(x₂)` y `max(y₁) < min(y₂)`, con `<` estricto: tocarse no cuenta.

**03 → Problema: Polygon Area.**

**Pista 2:** la fórmula del cordón; el enunciado pide el doble porque es entero.

**Pista 3:** suma de productos cruz en 64 bits (o `__int128` en C++).

**03 → Problema: Polygon Area.**

**Pista 2:** cordón con su signo: el signo dice el sentido.

**Pista 3:** `CCW` si es positivo y `CW` si es negativo; el área con un decimal es la mitad del valor absoluto.

**03 → Problema: Rectangle Area.**

**Pista 2:** unión de dos = suma de áreas menos la intersección.

**Pista 3:** intersección con `max(0, …)` en cada eje; productos en 64 bits si las coordenadas lo piden.

**03 → Problema: Find the Largest Area of Square Inside Two Rectangles.**

**Pista 2:** la intersección de dos rectángulos mide `w × h`; el mayor cuadrado dentro tiene lado `min(w, h)`.

**Pista 3:** todos los pares (`n ≤ 10³`): el máximo de `min(w, h)²` con `w, h > 0`.

**03 → Problema: Minimum Area Rectangle.**

**Pista 2:** con dos puntos como esquinas opuestas de una diagonal, las otras dos esquinas son `(x₁, y₂)` y `(x₂, y₁)`.

**Pista 3:** conjunto de puntos para consultar en `O(1)`; todos los pares de diagonales con `x₁ ≠ x₂` e `y₁ ≠ y₂`, `O(n²)`.

**03 → Problema: Jabuke.**

**Pista 2:** el área del triángulo es la mitad del valor absoluto del producto cruz, y un manzano es suyo si las tres orientaciones respecto a los lados no tienen signos opuestos.

**Pista 3:** área con un decimal; `inTriangle` con el borde incluido para cada manzano; todo en enteros.

**03 → Problema: Polygon Lattice Points.**

**Pista 2:** Pick: el área (cordón) y los puntos del borde (suma de `gcd`) determinan los interiores.

**Pista 3:** `2I = 2A − B + 2`; imprime `I` y `B`; el área doble en 64 bits (o 128 en C++).

**03 → Problema: Cookie Cutters.**

**Pista 2:** escalar un polígono por `k` multiplica el área por `k²`: `k = √(A_deseada / A_actual)`.

**Pista 3:** escala respecto a un punto (por ejemplo, el vértice de menor `x` e `y`) y traslada para que el mínimo de `x` y de `y` quede en 0.

**03 → Problema: Perfect Rectangle.**

**Pista 2:** las piezas forman un rectángulo exacto si la suma de sus áreas es la del rectángulo envolvente y las esquinas que aparecen un número impar de veces son exactamente las cuatro del envolvente.

**Pista 3:** conjunto de esquinas con inserción y borrado (XOR); al final, cuatro y las del envolvente; área en 64 bits.


---

# 04 — Envolvente convexa

**04 → 1.** ¿Qué es la envolvente convexa de un conjunto de puntos? 🟢

⏱️ **30 segundos.** El menor polígono convexo que contiene todos los puntos; sus vértices son algunos de ellos.

🗣️ **2 minutos.** Es la forma de una goma elástica soltada alrededor de clavos. Con los puntos de juguete, el rectángulo `(0,0) (4,0) (4,3) (0,3)`; `(2,1)` queda dentro.

🔬 **El detalle.** Formalmente, la intersección de todos los convexos que contienen los puntos.

**04 → 2.** ¿Cuánto cuesta la cadena monótona de Andrew y qué paso domina? 🟢

⏱️ **30 segundos.** `Θ(n log n)`, y lo domina la ordenación; el recorrido con la pila es `Θ(n)` amortizado.

🗣️ **2 minutos.** Cada punto se apila una vez y se desapila como mucho una vez en cada cadena. Si los puntos ya vienen ordenados, la envolvente sale en lineal.

🔬 **El detalle.** No se puede bajar de `n log n` en general: ordenar se reduce a la envolvente.

**04 → 3.** ¿Qué es el diámetro de un conjunto de puntos y entre qué puntos se alcanza? 🟢

⏱️ **30 segundos.** La mayor distancia entre dos de los puntos; se alcanza entre dos vértices de la envolvente.

🗣️ **2 minutos.** Con los puntos de juguete, 5, entre `(0,0)` y `(4,3)` (y entre `(4,0)` y `(0,3)`). Los dos extremos forman un par antipodal.

🔬 **El detalle.** Con calipers sale en lineal sobre la envolvente; con `n ≤ 2 000`, todos los pares.

**04 → 4.** ¿Qué cambia en el algoritmo si los puntos alineados del borde deben quedarse? 🟡

⏱️ **30 segundos.** La condición de desapilar: con `≤ 0` se quitan los alineados; con `< 0` se quedan.

🗣️ **2 minutos.** Además hay que quitar antes los duplicados, que darían orientación 0 y se quedarían, y tratar aparte el caso de todos alineados, en el que cada punto aparece en las dos cadenas.

🔬 **El detalle.** Es la diferencia entre Convex Hull de Kattis (solo esquinas) y Erect the Fence (todos los del borde).

**04 → 5.** ¿Por qué Andrew construye la envolvente en dos cadenas? 🟡

⏱️ **30 segundos.** Porque ordenados por `x`, los puntos de abajo y los de arriba se recorren en sentidos opuestos: la inferior de izquierda a derecha y la superior de derecha a izquierda, y en las dos se gira siempre a la izquierda.

🗣️ **2 minutos.** El primero y el último en `x` están siempre en la envolvente: son los puntos donde se unen las dos cadenas. Cada cadena es una pila monótona en giro.

🔬 **El detalle.** Graham evita las dos cadenas ordenando por ángulo alrededor de un punto extremo, a cambio de un comparador más delicado.

**04 → 6.** ¿Qué diferencia hay entre Andrew y Graham? 🟡

⏱️ **30 segundos.** Andrew ordena por `(x, y)` y construye dos cadenas; Graham ordena por ángulo alrededor del punto más bajo y hace una sola pasada.

🗣️ **2 minutos.** Los dos son `Θ(n log n)` con la misma pila. Andrew evita el comparador angular, que con puntos alineados respecto al pivote es fuente de errores.

🔬 **El detalle.** Graham es el de CLRS (§33.3); Andrew, el que se escribe en concursos.

**04 → 7.** ¿Qué es un par antipodal? 🟡

⏱️ **30 segundos.** Dos vértices de un polígono convexo por los que pasan dos rectas paralelas de apoyo, una por cada uno, con todo el polígono entre ellas.

🗣️ **2 minutos.** Un polígono convexo de `h` vértices tiene `O(h)` pares antipodales, y el diámetro se alcanza en uno de ellos. Los calipers los recorren con dos punteros que solo avanzan.

🔬 **El detalle.** En el rectángulo de juguete, `(0,0)` y `(4,3)` son antipodales (por ejemplo, con dos rectas paralelas a la diagonal opuesta).

**04 → 8.** ¿Por qué la envolvente convexa no se puede calcular en `o(n log n)` con comparaciones? 🟠

⏱️ **30 segundos.** Porque ordenar se reduce a ella: la envolvente de los puntos `(xᵢ, xᵢ²)` los devuelve todos, en orden de `x`.

🗣️ **2 minutos.** Los puntos sobre una parábola están en posición convexa: todos son vértices, y recorrer la envolvente desde el de menor `x` los da ordenados. Una envolvente en `o(n log n)` ordenaría en `o(n log n)`, contra la cota de las comparaciones.

🔬 **El detalle.** La reducción cuesta `Θ(n)`, así que no cambia el orden del coste.

**04 → 9.** ¿Qué cambia entre C++, Java y Python al quitar duplicados y ordenar los puntos para la envolvente? 🟠

⏱️ **30 segundos.** En C++, `sort` con un comparador por `(x, y)` y `unique` sobre el vector ordenado; en Java, `distinct()` usa el `equals` del `record`; en Python, `set` y `sorted` sobre tuplas.

🗣️ **2 minutos.** En Java, con arreglos `long[]` en lugar de `record`, `distinct()` no serviría: los arreglos se comparan por identidad. En Python, las tuplas se ordenan ya por `(x, y)`.

🔬 **El detalle.** El comparador tiene que ser un orden estricto débil; uno por ángulo con `atan2` puede no serlo con puntos alineados.

**04 → 10.** ¿Qué devuelve la plantilla si todos los puntos están alineados, con y sin `keepCollinear`? 🟠

⏱️ **30 segundos.** Sin `keepCollinear`, los dos extremos; con `keepCollinear`, todos los puntos, pero los interiores repetidos, porque cada uno aparece en las dos cadenas.

🗣️ **2 minutos.** Con `(0,0) (1,1) (2,2)`: sin la opción, `(0,0) (2,2)`; con ella, `(0,0) (1,1) (2,2) (1,1)`. Por eso la plantilla exige que no estén todos alineados para esa opción.

🔬 **El detalle.** Se arregla detectando el caso (todos los `orient` respecto a los dos extremos son 0) y devolviendo los puntos ordenados una sola vez.

**04 → 11.** Demuestra que el recorrido de la pila de Andrew es `Θ(n)` aunque haya un bucle dentro de otro. 🔴

⏱️ **30 segundos.** Cada punto entra en la pila una vez por cadena, y cada iteración del `while` saca uno: el total de iteraciones del `while` no supera el de entradas.

🗣️ **2 minutos.** Argumento de potencial: el número de elementos en la pila sube uno por punto y baja uno por cada desapilado; como nunca es negativo, los desapilados son como mucho `n` por cadena. El bucle interior suma `O(n)` en todo el recorrido.

🔬 **El detalle.** Es el mismo argumento que la pila monótona ([`06/01`](../06-lineales-y-hashing/01-pilas-colas-y-monotonas.md)) y la función de prefijo de KMP.

**04 → 12.** Traza la cadena superior de Andrew sobre los puntos de juguete y di qué puntos se desapilan y con qué orientación. 🔴

⏱️ **30 segundos.** Con el orden inverso `(4,3) (4,0) (2,1) (0,3) (0,0)`: `(2,1)` desapila `(4,0)` con orientación `−6`; `(0,3)` desapila `(2,1)` con `−8`; `(0,0)` se queda con `+12`. Queda `(4,3) (0,3) (0,0)`.

🗣️ **2 minutos.** La pila pasa por `(4,3)`; `(4,3) (4,0)`; `(4,3) (2,1)`; `(4,3) (0,3)`; `(4,3) (0,3) (0,0)`. Unida a la inferior `(0,0) (4,0) (4,3)` sin repetir los extremos: `(0,0) (4,0) (4,3) (0,3)`.

🔬 **El detalle.** `orient((4,3), (4,0), (2,1)) = −6`, `orient((4,3), (2,1), (0,3)) = −8`, `orient((4,3), (0,3), (0,0)) = 12`.

**04 → Problema: Postes en la valla.**

**Pista 2:** la envolvente que conserva los puntos alineados de los lados (desapilar solo con giro estrictamente a la derecha).

**Pista 3:** quita duplicados (aquí no los hay) y cuenta los vértices de la envolvente con `< 0`; `Θ(n log n)`.

**04 → Problema: El pasillo más estrecho.**

**Pista 2:** el pasillo más estrecho tiene una de sus dos rectas apoyada sobre un lado de la envolvente, y la otra en el vértice más lejano a ese lado.

**Pista 3:** envolvente y, para cada lado, el vértice más lejano con un puntero que solo avanza (calipers); el ancho es el mínimo de `|cross| / |lado|`; `Θ(n log n)`.

**04 → Problema: Robot Protection.**

**Pista 2:** la envolvente convexa de los faros, y su área.

**Pista 3:** Andrew y cordón; el área con el formato que pide el enunciado.

**04 → Problema: Dart Scoring.**

**Pista 2:** el perímetro de la envolvente convexa.

**Pista 3:** Andrew y la suma de las longitudes de los lados; aplica la fórmula de puntuación del enunciado.

**04 → Problema: Convex Hull.**

**Pista 2:** Andrew con los alineados del borde.

**Pista 3:** desapila solo con `< 0`; quita duplicados; imprime en el orden que pide el enunciado.

**04 → Problema: Convex Hull.**

**Pista 2:** Andrew sin los alineados, con varios casos por entrada.

**Pista 3:** quita repetidos; con un solo punto distinto, la envolvente es ese punto; imprime el número de vértices y los vértices.

**04 → Problema: Erect the Fence.**

**Pista 2:** Andrew con los alineados del borde (los árboles sobre la valla cuentan).

**Pista 3:** desapila con `< 0`; el caso de todos alineados devuelve todos los árboles una sola vez.

**04 → Problema: Board Wrapping.**

**Pista 2:** cada tabla aporta sus cuatro esquinas, calculadas girando el rectángulo alrededor de su centro; la envolvente de todas ellas es el molde.

**Pista 3:** esquinas con seno y coseno en `double`; Andrew; la razón es la suma de las áreas de las tablas entre el área de la envolvente.

**04 → Problema: Robert Hood.**

**Pista 2:** el par más lejano está entre los vértices de la envolvente.

**Pista 3:** envolvente y todos los pares de sus vértices (pocos en la práctica) o calipers; la raíz al final.

**04 → Problema: Fence Orthogonality.**

**Pista 2:** la caja de perímetro mínimo tiene un lado sobre un lado de la envolvente; para cada lado, el ancho y el alto salen de los puntos extremos en esa dirección y la perpendicular.

**Pista 3:** calipers con tres punteros (el más lejano, el extremo por un lado y por el otro), avanzando a la vez; `Θ(h)` tras la envolvente; en `double`.


---

# 05 — Barrido geométrico

**05 → 1.** ¿Qué es un barrido geométrico y cuáles son sus tres piezas? 🟢

⏱️ **30 segundos.** Una recta imaginaria que recorre el plano y se detiene en los eventos. Sus piezas: los eventos ordenados, el estado (una estructura sobre `y`) y el invariante que se mantiene en cada parada.

🗣️ **2 minutos.** Los eventos son puntos, extremos de segmentos o lados de rectángulos, ordenados por `x`. El estado guarda lo que la recta corta: un conjunto ordenado, un *segment tree* o un Fenwick.

🔬 **El detalle.** Convierte un problema de dos dimensiones en una secuencia de problemas de una.

**05 → 2.** ¿Cuánto cuesta el par más cercano por barrido, y qué estructura lo permite? 🟢

⏱️ **30 segundos.** `Θ(n log n)`, con un conjunto ordenado por `y` de los puntos activos.

🗣️ **2 minutos.** Se ordenan por `x`; cada punto entra y sale del conjunto una vez y mira como mucho 8 vecinos en la ventana, con operaciones `O(log n)`.

🔬 **El detalle.** En C++, `std::set`; en Java, `TreeSet`; en Python no hay en la librería estándar.

**05 → 3.** ¿Cuánto cuesta el área de la unión de `n` rectángulos con un barrido? 🟢

⏱️ **30 segundos.** `Θ(n log n)`, con un *segment tree* sobre las `y` comprimidas.

🗣️ **2 minutos.** Los eventos son los lados verticales; el árbol guarda, por nodo, cuántas veces está cubierto entero y la longitud cubierta. Entre dos eventos se suma `longitud × Δx`.

🔬 **El detalle.** No necesita propagación perezosa: un nodo cubierto aporta su tramo entero; si no, la suma de los hijos.

**05 → 4.** ¿Qué resuelve Bentley-Ottmann y cuánto cuesta? 🟢

⏱️ **30 segundos.** Todas las intersecciones de `n` segmentos, en `O((n + k) log n)` con `k` intersecciones.

🗣️ **2 minutos.** Los eventos son los extremos y las intersecciones que se descubren; el estado, los segmentos ordenados por su `y` en la `x` actual. Solo se comprueban segmentos vecinos.

🔬 **El detalle.** Para saber solo si hay alguna, Shamos-Hoey se detiene en la primera: `O(n log n)`.

**05 → 5.** ¿Qué diferencia hay entre el par más cercano por divide y vencerás y por barrido? 🟡

⏱️ **30 segundos.** Divide y vencerás parte por la mitad y combina con el lema de la franja; el barrido recorre por `x` con un conjunto ordenado por `y`. Los dos son `Θ(n log n)`.

🗣️ **2 minutos.** El de divide y vencerás enseña la combinación y es el de las entrevistas ([`10/05`](../10-busqueda-completa-y-divide-y-venceras/05-divide-y-venceras.md)); el barrido es más corto de escribir bien en un juez, porque la estructura ordenada hace el trabajo de la mezcla.

🔬 **El detalle.** Los dos usan el mismo lema geométrico: en un rectángulo de `d × 2d` caben pocos puntos a distancia mutua `≥ d`.

**05 → 6.** ¿Por qué la ventana del barrido contiene como mucho 8 puntos? 🟡

⏱️ **30 segundos.** Porque la ventana de `d × 2d` se parte en 8 cuadrados de lado `d/2`, y en cada uno cabe como mucho un activo: dos estarían a menos de `d`.

🗣️ **2 minutos.** La diagonal de un cuadrado de lado `d/2` mide `d/√2 < d`, y los activos ya se compararon entre sí, así que están a distancia `≥ d`.

🔬 **El detalle.** La cota de 8 es holgada; lo que importa es que es constante.

**05 → 7.** ¿Qué tiene en común este barrido con el de intervalos de `04/04`, y qué cambia? 🟡

⏱️ **30 segundos.** Los dos ordenan eventos por una coordenada y llevan un estado. En `04/04` el estado es un contador o una suma; aquí, una estructura ordenada sobre la otra coordenada.

🗣️ **2 minutos.** En una dimensión, «cuántos intervalos activos» basta; en el plano, hace falta saber **cuáles** y en qué orden de `y`, para consultar solo los cercanos.

🔬 **El detalle.** La compresión de coordenadas de `04/04` es también el primer paso de la unión de rectángulos.

**05 → 8.** ¿Qué cambia entre C++, Java y Python para guardar el conjunto activo ordenado por `y`? 🟠

⏱️ **30 segundos.** C++ tiene `std::set` con `lower_bound`; Java, `TreeSet` con `tailSet` o `ceiling`; Python no tiene conjunto ordenado en la librería estándar.

🗣️ **2 minutos.** En Java, con `long[]` como elemento, el comparador hace de igualdad (los arreglos no tienen `equals` por contenido). En Python, la alternativa es una rejilla de celdas de lado `d` en un diccionario, o `sortedcontainers` si el juez lo trae.

🔬 **El detalle.** `bisect.insort` en una lista de Python inserta en `O(n)`: el barrido se vuelve cuadrático.

**05 → 9.** ¿Por qué la ventana se redondea hacia arriba, y qué pasa si no? 🟠

⏱️ **30 segundos.** Porque el ancho `d` sale de una raíz en `double` de la mejor distancia al cuadrado: si se redondea hacia abajo, un punto justo en el borde de la ventana se pierde.

🗣️ **2 minutos.** La distancia que se guarda es `d²`, exacta en enteros. La ventana se calcula como `⌊√d²⌋ + 1`: un poco más ancha de lo necesario, sin coste apreciable.

🔬 **El detalle.** Vale para cualquier raíz en `double` que se use como cota entera: o se corrige hacia arriba, o se suma un margen.

**05 → 10.** ¿Cuándo basta comparar todos los pares, y cuándo una rejilla es mejor que el barrido? 🟠

⏱️ **30 segundos.** Todos los pares bastan con `n ≤ 3 000`. La rejilla es mejor con puntos repartidos al azar, porque da tiempo esperado lineal y no necesita estructura ordenada.

🗣️ **2 minutos.** Con la rejilla, cada punto mira las celdas vecinas de lado `d`; si `d` baja mucho, se rehace. Con datos adversarios (muchos puntos en una celda) degrada; el barrido no.

🔬 **El detalle.** La rejilla es también la alternativa natural en Python, que no tiene conjunto ordenado.

**05 → 11.** Demuestra que dos segmentos que se cortan son vecinos en el orden de la recta de barrido justo antes del punto de corte (suponiendo que no hay tres segmentos por un mismo punto). 🔴

⏱️ **30 segundos.** Justo antes del corte, entre los dos segmentos no hay ningún otro en el orden de la recta: si lo hubiera, tendría que cortar a uno de los dos antes, o pasar por el punto de corte.

🗣️ **2 minutos.** Sea `q` el punto de corte de `s` y `t`, y `x` un poco menor que `q.x`, sin eventos entre `x` y `q.x`. En `x`, `s` y `t` están muy cerca en `y`; un segmento `u` entre ellos en `x` tiene que salir del hueco antes de `q.x` cortando a `s` o a `t` (un evento intermedio, contra la elección de `x`) o pasar por `q` (tres segmentos por un punto, excluido).

🔬 **El detalle.** Por eso basta comprobar los pares vecinos al insertar, al borrar y al intercambiar dos segmentos en un cruce.

**05 → 12.** Traza el barrido del área de la unión de `[0,4]×[0,3]` y `[2,6]×[1,5]`: los eventos, la longitud cubierta entre ellos y el área acumulada. 🔴

⏱️ **30 segundos.** Eventos en `x = 0, 2, 4, 6`. Entre 0 y 2 se cubre `[0,3]`: `3 · 2 = 6`. Entre 2 y 4, `[0,5]`: `5 · 2 = 10`. Entre 4 y 6, `[1,5]`: `4 · 2 = 8`. Total 24.

🗣️ **2 minutos.** En `x = 0` entra `[0,3]`; en `x = 2` entra `[1,5]` y la cubierta es `[0,5]`; en `x = 4` sale `[0,3]` y queda `[1,5]`; en `x = 6` sale `[1,5]`.

🔬 **El detalle.** Coincide con `12 + 16 − 4 = 24` de [`18/03`](03-poligonos.md).

**05 → Problema: El enchufe más cercano.**

**Pista 2:** barrido de todos los puntos por `x` con **dos** conjuntos activos, uno de máquinas y otro de enchufes: cada máquina consulta el de enchufes y cada enchufe el de máquinas.

**Pista 3:** la ventana con la mejor distancia hasta ahora, como en el par más cercano; distancias al cuadrado en 64 bits; `Θ((n + m) log(n + m))`.

**05 → Problema: El contorno de los puestos.**

**Pista 2:** compresión de coordenadas en los dos ejes y una rejilla de unas `2n × 2n` celdas, cada una cubierta o no; el contorno son los lados de celdas cubiertas cuya vecina no lo está.

**Pista 3:** marca la cobertura con diferencias en dos dimensiones (`O(n²)`); para cada celda cubierta, suma la longitud real de cada lado cuya celda vecina (o el exterior) no está cubierta.

**05 → Problema: The Rectangles Are Surrounding Us!.**

**Pista 2:** con coordenadas pequeñas, una rejilla de celdas unitarias marcadas.

**Pista 3:** marca las celdas de cada rectángulo y cuenta las marcadas; varios casos por entrada.

**05 → Problema: Closest Pair (Uniform).**

**Pista 2:** con puntos al azar, una rejilla de celdas del tamaño de la respuesta tiene pocos puntos por celda.

**Pista 3:** celdas en un diccionario; cada punto mira su celda y las vecinas; el tamaño de celda, una estimación de la distancia (por ejemplo, con los primeros puntos).

**05 → Problema: Rectangle Area II.**

**Pista 2:** compresión de coordenadas y, por franjas verticales entre lados consecutivos, la longitud de `y` cubierta.

**Pista 3:** con 200 rectángulos, 400 franjas por 200 rectángulos: `O(n²)` o `O(n² log n)`; el área módulo `10⁹ + 7` al final.

**05 → Problema: Minimum Euclidean Distance.**

**Pista 2:** el par más cercano por barrido o por divide y vencerás.

**Pista 3:** imprime la distancia al cuadrado, en 64 bits.

**05 → Problema: Closest Pair.**

**Pista 2:** el par más cercano, con varios casos y puntos repetidos (distancia 0).

**Pista 3:** barrido o divide y vencerás; imprime el par, no la distancia; coordenadas reales.

**05 → Problema: Intersection Points.**

**Pista 2:** barrido por `x`: las horizontales entran en un Fenwick sobre `y` al empezar y salen al terminar; cada vertical pregunta cuántas activas hay entre sus `y`.

**Pista 3:** eventos ordenados por `x`, con las entradas antes que las consultas y las salidas después en la misma `x`; `y` comprimidas; `O(n log n)`.

**05 → Problema: Area of Rectangles.**

**Pista 2:** barrido con un *segment tree* sobre las `y` que guarda cobertura y longitud cubierta.

**Pista 3:** eventos de lados verticales con `+1` y `−1`; área en 64 bits.

**05 → Problema: Robot Path.**

**Pista 2:** búsqueda binaria sobre el número de tramos `k`, comprobando si los primeros `k` se cortan con un barrido de Shamos-Hoey.

**Pista 3:** con segmentos de ejes, el barrido usa estructuras sobre `y`; cuidado con los tramos consecutivos, que comparten extremo, y con los que vuelven sobre sí mismos.

**05 → Problema: Simple Polygon.**

**Pista 2:** Shamos-Hoey: un barrido con los lados ordenados por `y` en la `x` actual, comprobando solo vecinos; el polígono no es simple si dos lados no consecutivos se tocan.

**Pista 3:** eventos en los extremos de cada lado; al insertar, compara con los vecinos; al borrar, compara los dos que quedan juntos; los lados consecutivos comparten un vértice y se excluyen de la comprobación.


---

# 06 — Geometría avanzada

**06 → 1.** ¿Qué forma tiene la intersección de `n` semiplanos? 🟢

⏱️ **30 segundos.** Un polígono convexo, que puede ser vacío o no acotado, con como mucho `n` lados.

🗣️ **2 minutos.** Cada semiplano es convexo y la intersección de convexos es convexa. Cada lado del resultado viene de una de las rectas.

🔬 **El detalle.** Es la región factible de un programa lineal de dos variables.

**06 → 2.** ¿Qué es el diagrama de Voronoi de un conjunto de puntos? 🟢

⏱️ **30 segundos.** La partición del plano en celdas, una por punto, con la región más cercana a ese punto que a cualquier otro.

🗣️ **2 minutos.** Cada celda es convexa: la intersección de los semiplanos de las mediatrices con los demás puntos. El diagrama tiene tamaño lineal.

🔬 **El detalle.** Con la distancia euclídea los bordes son rectos; con otras distancias, no tienen por qué.

**06 → 3.** ¿Qué relación hay entre la triangulación de Delaunay y el diagrama de Voronoi? 🟢

⏱️ **30 segundos.** Son duales: Delaunay une dos puntos si sus celdas de Voronoi comparten una arista.

🗣️ **2 minutos.** Los vértices de Voronoi son los centros de los círculos circunscritos de los triángulos de Delaunay. Uno se obtiene del otro en tiempo lineal.

🔬 **El detalle.** Con cuatro o más puntos cocirculares, Voronoi tiene un vértice de grado mayor y Delaunay no es única.

**06 → 4.** ¿Cuánto cuestan la intersección de semiplanos y la triangulación de Delaunay? 🟡

⏱️ **30 segundos.** `O(n log n)` los dos.

🗣️ **2 minutos.** Semiplanos: ordenar por ángulo y una *deque*. Delaunay: divide y vencerás o incremental aleatorizado (esperado); Voronoi, con el barrido de Fortune.

🔬 **El detalle.** La programación lineal en dos variables tiene además un algoritmo aleatorizado de tiempo esperado lineal.

**06 → 5.** ¿Qué propiedad del círculo circunscrito caracteriza a Delaunay? 🟡

⏱️ **30 segundos.** El círculo circunscrito de cada triángulo no contiene ningún otro punto en su interior.

🗣️ **2 minutos.** Con puntos en posición general, esa condición determina la triangulación de forma única, y equivale a maximizar el menor ángulo entre todas las triangulaciones.

🔬 **El detalle.** El test del círculo es un determinante `4 × 4` con términos de grado 4 en las coordenadas.

**06 → 6.** ¿Qué calcula el producto mixto de tres vectores de `ℝ³` y qué dice su signo? 🟡

⏱️ **30 segundos.** `(b − a) · ((c − a) × (d − a))`: seis veces el volumen con signo del tetraedro `abcd`. Su signo dice a qué lado del plano `abc` está `d`; si es 0, son coplanares.

🗣️ **2 minutos.** Es el determinante `3 × 3` de los tres vectores, la generalización directa de `orient` del plano.

🔬 **El detalle.** Con coordenadas de `10⁶`, los términos llegan a `10¹⁸`: en el límite de 64 bits.

**06 → 7.** ¿Por qué el árbol de expansión mínima euclídeo cabe en Delaunay, y qué se gana con eso? 🟠

⏱️ **30 segundos.** Porque para cada arista `pq` del árbol mínimo, el círculo de diámetro `pq` está vacío, y eso la hace arista de Delaunay. Se gana pasar de `n²/2` aristas candidatas a `O(n)`.

🗣️ **2 minutos.** Si un punto `r` estuviera dentro de ese círculo, `pr` y `rq` serían más cortas que `pq`, y `pq` no estaría en el árbol mínimo (propiedad del ciclo). Kruskal sobre Delaunay da el árbol en `O(n log n)`.

🔬 **El detalle.** Lo mismo vale para el grafo de vecinos más cercanos.

**06 → 8.** ¿Qué escribirías para la intersección de semiplanos con `n ≤ 3 000`, y cuánto cuesta? 🟠

⏱️ **30 segundos.** Recortar una caja grande por cada semiplano, en `O(n²)`.

🗣️ **2 minutos.** Cada recorte recorre el polígono actual (como mucho `n + 4` vértices), conserva los que quedan del lado bueno y añade los puntos de corte. Con `n = 3 000`, unos `10⁷` pasos.

🔬 **El detalle.** Es el algoritmo de Sutherland-Hodgman con un solo semiplano cada vez.

**06 → 9.** ¿Cuántos vértices y aristas tiene, como mucho, el diagrama de Voronoi de `n` puntos? 🟠

⏱️ **30 segundos.** Como mucho `2n − 5` vértices y `3n − 6` aristas, para `n ≥ 3`.

🗣️ **2 minutos.** Sale de la fórmula de Euler para grafos planares (`V − E + F = 2`), con `F = n` celdas y cada vértice de grado al menos 3.

🔬 **El detalle.** Por eso Voronoi y Delaunay tienen tamaño lineal aunque haya `n²` pares de puntos.

**06 → 10.** «Voronoi es solo para mapas.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que Voronoi es la estructura de «quién está más cerca de quién», y eso aparece en muchos sitios.

🗣️ **2 minutos.** Vecino más cercano de cada punto, árbol mínimo euclídeo, el punto más alejado de todos los sitios (en un vértice de Voronoi), mallas para simulación, interpolación espacial, cobertura de antenas.

🔬 **El detalle.** En un mapa es solo una de sus caras: la asignación de cada casa al hospital más cercano.

**06 → 11.** Demuestra que el vecino más cercano de cada punto es adyacente a él en la triangulación de Delaunay. 🔴

⏱️ **30 segundos.** Si `q` es el vecino más cercano de `p`, el círculo de diámetro `pq` no contiene otro punto, y una arista con un círculo vacío que pasa por sus extremos es de Delaunay.

🗣️ **2 minutos.** Un punto `r` dentro del círculo de diámetro `pq` ve el segmento `pq` con un ángulo mayor de 90°, así que `|pr| < |pq|`, contra que `q` sea el más cercano. Y en Delaunay, `pq` es arista si y solo si existe un círculo vacío por `p` y `q`.

🔬 **El detalle.** Con empates (varios a la misma distancia) basta tomar uno; con puntos cocirculares, alguna triangulación de Delaunay lo contiene.

**06 → 12.** Diseña cómo decidir si un punto está dentro de un poliedro convexo dado por sus caras, y di el coste. 🔴

⏱️ **30 segundos.** Con cada cara dada por tres vértices en sentido antihorario visto desde fuera, el punto está dentro si y solo si el producto mixto respecto a cada cara no es positivo. `O(F)` por consulta.

🗣️ **2 minutos.** El producto mixto `(b − a) · ((c − a) × (p − a))` dice de qué lado del plano de la cara `abc` está `p`. Dentro de un convexo es estar del lado interior de todas a la vez; con alguno 0, en el borde.

🔬 **El detalle.** Con muchas consultas sobre el mismo poliedro, hay estructuras de localización en `O(log F)`.

**06 → Problema: La zona segura.**

**Pista 2:** recortar un cuadrado enorme por cada semiplano, quedándose con la parte de la izquierda.

**Pista 3:** caja de `±10⁹`; en cada recorte, recorre los lados del polígono actual, conserva los vértices con `orient ≥ 0` y añade el punto de corte cuando un lado cruza la recta; `O(n²)`; el área con el cordón en `double`.

**06 → Problema: Volumen del tetraedro.**

**Pista 2:** el producto mixto de `b − a`, `c − a` y `d − a`, que es un determinante `3 × 3`.

**Pista 3:** su valor absoluto; con coordenadas de `10⁵`, los productos llegan a `8·10¹⁵`: 64 bits.

**06 → Problema: Airline Hub.**

**Pista 2:** cada aeropuerto como vector unitario `(cos φ cos λ, cos φ sen λ, sen φ)`; la distancia en la esfera es proporcional al ángulo entre vectores, `arccos(u · v)`.

**Pista 3:** para cada candidato, la máxima distancia a los demás; el hub es el de menor máximo, con tolerancia al comparar y el desempate que diga el enunciado.

**06 → Problema: Asteroids.**

**Pista 2:** la intersección de dos polígonos convexos, que en cada instante es una intersección de semiplanos; mientras ningún vértice cruza un lado, su área es un polinomio de grado 2 en el tiempo.

**Pista 3:** los instantes en que un vértice de uno cruza la recta de un lado del otro parten el tiempo en tramos; en cada tramo, maximiza la cuadrática; el área por recorte en `double`.

**06 → Problema: Euclidean MST.**

**Pista 2:** el árbol mínimo euclídeo está contenido en Delaunay, que tiene `O(n)` aristas; después, Kruskal.

**Pista 3:** Delaunay por divide y vencerás o incremental, con el test del círculo en enteros de 128 bits; Kruskal con *union-find*; `O(n log n)`.

**06 → Problema: Stars in a Can.**

**Pista 2:** la envolvente convexa 3D; la base del cilindro mínimo se apoya en una de sus caras.

**Pista 3:** para cada cara: altura = máxima distancia al plano de la cara; radio = el del círculo mínimo que contiene las proyecciones de los puntos sobre ese plano; volumen `π r² h`; el mínimo sobre las caras.


---

# 07 — Simulación

**07 → S1.** ¿Qué dice el signo de `(b − a) × (c − a)`? 🟢

⏱️ **30 segundos.** Hacia qué lado gira `a → b → c`: positivo, izquierda; negativo, derecha; cero, alineados.

🗣️ **2 minutos.** Es el producto cruz de los vectores `b − a` y `c − a`; su valor absoluto es el doble del área del triángulo. Exacto en enteros de 64 bits con coordenadas de `10⁹`.

🔬 **El detalle.** Se demuestra trasladando y girando: el producto cruz no cambia y queda `d · y_c` con `d > 0`.

**07 → S2.** ¿Cómo calculas el área de un polígono simple dados sus vértices en orden? 🟢

⏱️ **30 segundos.** Con la fórmula del cordón: la mitad del valor absoluto de `Σ pᵢ × p_{i+1}`.

🗣️ **2 minutos.** Vale para polígonos no convexos; el signo dice si los vértices van en sentido antihorario. Se guarda el doble, entero.

🔬 **El detalle.** Con coordenadas de `10⁹`, las sumas parciales pueden pasar de `2⁶³`: `__int128` en C++.

**07 → S3.** ¿Cuándo se solapan dos rectángulos alineados con los ejes? 🟢

⏱️ **30 segundos.** Cuando se solapan sus intervalos en `x` y en `y`: `max(x₁) < min(x₂)` y `max(y₁) < min(y₂)`.

🗣️ **2 minutos.** El área común es el producto de los dos solapes, si los dos son positivos. Tocarse por un lado da solape 0.

🔬 **El detalle.** Comprobar `w > 0` y `h > 0` por separado: con los dos negativos, el producto es positivo.

**07 → S4.** ¿Cuánto cuesta construir la envolvente convexa, y qué paso domina? 🟡

⏱️ **30 segundos.** `Θ(n log n)`, dominado por la ordenación; el recorrido con la pila es lineal amortizado.

🗣️ **2 minutos.** Andrew ordena por `(x, y)` y construye las cadenas inferior y superior desapilando los giros que no van a la izquierda. Cada punto entra y sale una vez por cadena.

🔬 **El detalle.** No se puede bajar de `n log n`: ordenar se reduce a la envolvente de puntos sobre una parábola.

**07 → S5.** ¿Cómo decides si un punto está sobre un segmento? 🟡

⏱️ **30 segundos.** `orient(a, b, p) = 0` y `p` dentro de la caja de `a` y `b`.

🗣️ **2 minutos.** La primera dice que está en la recta; la segunda, que está en el tramo. Todo en enteros.

🔬 **El detalle.** Equivale a `orient = 0` y `(a − p) · (b − p) ≤ 0`.

**07 → S6.** ¿Qué dice el teorema de Pick? 🟢

⏱️ **30 segundos.** Para un polígono simple de vértices enteros, `A = I + B/2 − 1`.

🗣️ **2 minutos.** `B` es la suma de `gcd(|Δx|, |Δy|)` por lados y `A` sale del cordón: así se cuentan los puntos interiores sin recorrerlos.

🔬 **El detalle.** En enteros: `2I = 2A − B + 2`.

**07 → S7.** ¿Cuánto cuesta encontrar el par más cercano de `n` puntos? 🟢

⏱️ **30 segundos.** `Θ(n log n)`.

🗣️ **2 minutos.** Con divide y vencerás y el lema de la franja (`10/05`), o con un barrido por `x` y un conjunto ordenado por `y` ([`18/05`](05-barrido-geometrico.md)).

🔬 **El detalle.** Con `n ≤ 3 000`, todos los pares; con puntos al azar, una rejilla da tiempo esperado lineal.

**07 → S8.** ¿Cómo se calcula la distancia de un punto a un segmento? 🟡

⏱️ **30 segundos.** Se proyecta el punto sobre la recta del segmento; si la proyección cae fuera del tramo, la distancia es al extremo más cercano.

🗣️ **2 minutos.** `t = ((p − a) · (b − a)) / |b − a|²`: si `t ≤ 0`, `|p − a|`; si `t ≥ 1`, `|p − b|`; si no, `|cross| / |b − a|`.

🔬 **El detalle.** Los topes se deciden en enteros; la raíz, al final.

**07 → S9.** ¿Qué diferencia hay entre desapilar con `< 0` y con `≤ 0` en Andrew? 🟡

⏱️ **30 segundos.** Con `≤ 0` se quitan los puntos alineados de los lados; con `< 0` se conservan.

🗣️ **2 minutos.** La segunda exige quitar antes los duplicados y tratar aparte el caso de todos alineados, en el que la salida repite los puntos interiores.

🔬 **El detalle.** Qué usar lo decide el enunciado: «esquinas» o «todos los puntos sobre la valla».

**07 → S10.** ¿Qué relación hay entre el diagrama de Voronoi y la triangulación de Delaunay? 🟡

⏱️ **30 segundos.** Son duales: dos puntos están unidos en Delaunay si sus celdas de Voronoi comparten una arista.

🗣️ **2 minutos.** Los vértices de Voronoi son los centros de los círculos circunscritos de los triángulos de Delaunay, que están vacíos. Los dos tienen tamaño lineal y se construyen en `O(n log n)`.

🔬 **El detalle.** Delaunay contiene el árbol mínimo euclídeo y el grafo de vecinos más cercanos.

**07 → S11.** «La geometría es con `double`.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que no: con coordenadas enteras, productos cruz, productos punto, áreas dobles y distancias al cuadrado son exactos en enteros. El `double` solo donde el resultado no es entero.

🗣️ **2 minutos.** El `double` tiene 53 bits de mantisa: con coordenadas de `10⁹` los productos se redondean y un giro real sale 0. Donde hace falta (distancias, puntos de corte), con un épsilon a la escala de los datos.

🔬 **El detalle.** El ejemplo: `(0,0)`, `(10⁹, 10⁹ − 1)`, `(10⁹ − 1, 10⁹ − 2)` da 0 en `double` y `−1` en enteros.

**07 → S12.** Tu intersección de segmentos dice que `(0,0)–(1,0)` y `(2,0)–(3,0)` se cortan. ¿Qué línea miras? 🟠

⏱️ **30 segundos.** La del caso general: usa `≤ 0` en lugar de `< 0`, o no tiene el caso colineal aparte.

🗣️ **2 minutos.** Con dos segmentos colineales y separados las cuatro orientaciones son 0, y `0 ≤ 0` es cierto. El caso general va con `< 0` estricto y todo lo que tenga un 0 se resuelve con `onSegment`.

🔬 **El detalle.** Es la autopsia de [`18/02`](02-rectas-y-segmentos.md).

**07 → S13.** Tu punto en polígono falla solo cuando el punto está a la altura de un vértice. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** El rayo pasa por un vértice y lo cuenta dos veces (o ninguna). Faltan los lados semiabiertos.

🗣️ **2 minutos.** La condición `(a.y > p.y) != (b.y > p.y)` cuenta un vértice para uno solo de sus dos lados si el rayo lo atraviesa, y no cuenta los lados horizontales.

🔬 **El detalle.** Si además falla en el borde, falta comprobar `onSegment` antes del rayo.

**07 → S14.** El área de tu polígono sale negativa. ¿Está mal? 🟠

⏱️ **30 segundos.** No necesariamente: el signo del cordón dice la orientación. Negativo es que los vértices vienen en sentido horario.

🗣️ **2 minutos.** El área es el valor absoluto. El signo es útil: dice el sentido, que algunos problemas piden o que hay que normalizar.

🔬 **El detalle.** Si el polígono se corta a sí mismo, el valor ya no es un área, pero eso es otro problema.

**07 → S15.** Tu producto cruz en Java da resultados absurdos con coordenadas de `10⁹`, aunque guardas el resultado en un `long`. ¿Por qué? 🟠

⏱️ **30 segundos.** Porque las coordenadas son `int`: el producto se calcula en 32 bits y desborda antes de convertirse en `long`.

🗣️ **2 minutos.** En Java, `int * int` es `int` aunque el resultado vaya a un `long`. Las coordenadas tienen que ser `long` (o hacer el *cast* antes de multiplicar).

🔬 **El detalle.** En C++ pasa lo mismo con `int`, y además el desbordamiento con signo es comportamiento indefinido.

**07 → S16.** Piden el par más lejano de `n = 2 000` puntos y alguien propone envolvente y *rotating calipers*. ¿Qué dices? 🟠

⏱️ **30 segundos.** Que no hace falta: con `2 000` puntos, todos los pares son `2·10⁶` distancias al cuadrado. Envolvente y calipers solo compensan con `n` grande.

🗣️ **2 minutos.** El doble bucle es corto, exacto en 64 bits y sin casos degenerados. La técnica avanzada añade riesgo sin ganancia.

🔬 **El detalle.** Con `n = 2·10⁵`, en cambio, la envolvente y los calipers (o los pares de vértices de la envolvente) son necesarios.

**07 → S17.** Tu envolvente que conserva los alineados devuelve puntos repetidos. ¿Qué entradas lo provocan? 🟠

⏱️ **30 segundos.** Puntos duplicados sin quitar, o todos los puntos alineados.

🗣️ **2 minutos.** Con duplicados, `orient` da 0 y la condición `< 0` no los desapila; con todos alineados, cada punto interior aparece en las dos cadenas.

🔬 **El detalle.** Se quitan los duplicados antes de ordenar y el caso de todos alineados se trata aparte.

**07 → S18.** Comparas pendientes en `double` para ver si tres puntos están alineados, y falla un caso oculto. ¿Por qué? 🟠

⏱️ **30 segundos.** Porque comparar pendientes en `double` redondea: con coordenadas de `10⁹`, dos pendientes distintas pueden salir iguales. Y las verticales dividen por 0.

🗣️ **2 minutos.** Comparar `Δy₁/Δx₁` con `Δy₂/Δx₂` es comparar fracciones: multiplicando en cruz queda `Δy₁ Δx₂ = Δy₂ Δx₁`, el producto cruz igual a 0, en enteros.

🔬 **El detalle.** El caso oculto típico tiene coordenadas grandes o una recta vertical.

**07 → S19.** Demuestra que la envolvente convexa no se puede calcular en `o(n log n)` en el modelo de comparaciones. 🔴

⏱️ **30 segundos.** Porque ordenar se reduce a ella: dados `x₁, …, xₙ`, la envolvente de `(xᵢ, xᵢ²)` los devuelve en orden de `x`, y ordenar necesita `Ω(n log n)` comparaciones.

🗣️ **2 minutos.** Los puntos de una parábola son todos vértices de su envolvente. Construir los puntos y leer la envolvente desde el de menor `x` cuesta `Θ(n)`: si la envolvente costara `o(n log n)`, ordenar también.

🔬 **El detalle.** La cota es para el modelo de comparaciones (y de árboles de decisión algebraicos); con la salida ya ordenada, la envolvente es lineal.

**07 → S20.** Diseña cómo calcular el área de la unión de `10⁵` rectángulos alineados con los ejes, y di el coste. 🔴

⏱️ **30 segundos.** Un barrido por `x` con los lados verticales como eventos y un *segment tree* sobre las `y` comprimidas que guarda cobertura y longitud cubierta. `Θ(n log n)`.

🗣️ **2 minutos.** En cada evento se suma `longitud cubierta × Δx` desde el anterior y se actualiza el árbol con `+1` (lado izquierdo) o `−1` (derecho) sobre el tramo de `y`. Un nodo cubierto al menos una vez aporta su tramo entero; si no, la suma de sus hijos.

🔬 **El detalle.** Sin propagación perezosa: las actualizaciones vienen en pares `+1`/`−1` sobre el mismo tramo.

**07 → Problema: El terreno con estanque.**

**Pista 2:** el cordón con valor absoluto para cada polígono: el área es `|2A_terreno| / 2 − |2A_estanque| / 2`.

**Pista 3:** dobles en enteros (`__int128` en C++ para las sumas parciales); la resta en el doble y la división al imprimir, con `.0` o `.5`.

**07 → Problema: Capas de cebolla.**

**Pista 2:** repetir la envolvente que conserva los alineados, quitar sus puntos y contar capas hasta que no quede ninguno.

**Pista 3:** como mucho `n/3` capas de `O(n log n)`: `O(n² log n)`, unos `4·10⁷` con `n = 2 000`; el caso de todos alineados (o uno o dos puntos) cierra la última capa sin llamar a la envolvente.

**07 → Problema: Cables cruzados.**

**Pista 2:** la intersección de segmentos con sus tres casos para todos los pares.

**Pista 3:** `2·10⁶` pares; caso general con `< 0` estricto y `onSegment` para el resto; productos en 64 bits.

**07 → Problema: Los dos faros más lejanos.**

**Pista 2:** todos los pares con distancias al cuadrado.

**Pista 3:** `2·10⁶` pares; con coordenadas de `10⁹`, la distancia al cuadrado llega a `8·10¹⁸`: 64 bits.

**07 → Problema: Beehives.**

**Pista 2:** todos los pares de colmenas a distancia `≤ d`.

**Pista 3:** marca las dos de cada par cercano como agrias; compara distancias al cuadrado con `d²`; varios casos por entrada.

**07 → Problema: Queries on Number of Points Inside a Circle.**

**Pista 2:** un punto está dentro del círculo si `(x − cx)² + (y − cy)² ≤ r²`.

**Pista 3:** para cada consulta, recorre los puntos: `500 · 500` comprobaciones, en enteros.

**07 → Problema: Number of Boomerangs.**

**Pista 2:** para cada punto como vértice del medio, agrupa los demás por distancia al cuadrado; un grupo de `k` da `k (k − 1)` bumeranes ordenados.

**Pista 3:** un mapa por punto, `O(n²)`; distancias al cuadrado en enteros.

**07 → Problema: Detect Squares.**

**Pista 2:** guarda cuántas veces aparece cada punto; para una consulta, recorre los puntos que forman diagonal con ella (`|dx| = |dy| ≠ 0`).

**Pista 3:** para cada diagonal, las otras dos esquinas son `(x, qy)` y `(qx, y)`: suma el producto de las tres cuentas.

**07 → Problema: Maximum Number of Darts Inside of a Circular Dartboard.**

**Pista 2:** un círculo óptimo de radio `r` se puede mover hasta que dos dardos queden en su borde (o tiene un solo dardo).

**Pista 3:** para cada par de dardos a distancia `≤ 2r`, los dos centros de los círculos de radio `r` que pasan por ellos; cuenta los dardos dentro de cada uno con tolerancia `1e-9`; `O(n³)`.

