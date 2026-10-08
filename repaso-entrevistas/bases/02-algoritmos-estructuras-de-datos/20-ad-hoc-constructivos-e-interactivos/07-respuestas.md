# Respuestas — bloque 20: Ad hoc, constructivos e interactivos

> Solucionario del bloque `20`: las respuestas de las preguntas de cada capítulo y de la
> simulación, en tres capas (⏱️ 30 segundos · 🗣️ 2 minutos · 🔬 el detalle), con el enunciado
> copiado literalmente, y las pistas 2 y 3 de cada problema. Ningún problema lleva solución.
>
> **Vigencia:** 2026-10-04.

**Salto rápido:** [01](#01--ad-hoc-y-simulación) · [02](#02--constructivos) · [03](#03--interactivos) · [04](#04--el-estilo-de-las-pruebas-de-empresa) · [05](#05--heurísticos-y-aproximados) · [06](#06--simulación)

---

# 01 — Ad hoc y simulación

**01 → 1.** ¿Qué es un invariante y qué permite demostrar? 🟢

⏱️ **30 segundos.** Una cantidad que ninguna operación cambia. Permite demostrar que un estado es **inalcanzable**: si el inicial y el objetivo tienen valores distintos, no hay camino.

🗣️ **2 minutos.** En la pizarra con los números del 1 al `n`, la paridad de la suma es invariante: si `n(n + 1)/2` es impar, el 0 es imposible sin probar ninguna jugada.

🔬 **El detalle.** No demuestra que algo sea posible: para eso hace falta una construcción.

**01 → 2.** ¿Qué es un monovariante y para qué sirve? 🟢

⏱️ **30 segundos.** Una cantidad que cada operación cambia siempre en el mismo sentido. Si está acotada, demuestra que el proceso termina.

🗣️ **2 minutos.** Es la función de cota de los bucles ([`02/04`](../02-analisis/04-correccion-invariantes-induccion-intercambio.md)): un entero no negativo que baja en cada paso no puede bajar para siempre.

🔬 **El detalle.** Ejemplo: en la búsqueda local, el coste baja estrictamente en cada movimiento aceptado.

**01 → 3.** ¿Por qué el tablero sin dos esquinas opuestas no se cubre con dominós? 🟢

⏱️ **30 segundos.** Porque cada dominó cubre una casilla blanca y una negra, y al quitar dos esquinas opuestas (del mismo color) quedan 32 de un color y 30 del otro.

🗣️ **2 minutos.** 31 dominós cubrirían 31 de cada color. El invariante «blancas cubiertas = negras cubiertas» lo hace imposible.

🔬 **El detalle.** Es el ejemplo clásico de coloración como invariante (Engel, cap. 2).

**01 → 4.** ¿Qué diferencia hay entre demostrar que algo es imposible y demostrar que es posible? 🟡

⏱️ **30 segundos.** Lo imposible se demuestra con un invariante (o una cuenta); lo posible, mostrando cómo se hace: una construcción.

🗣️ **2 minutos.** Un invariante que coincide en el inicio y el objetivo no dice nada. En la pizarra, la suma par no basta por sí sola: hay que construir las jugadas que llevan a 0.

🔬 **El detalle.** En los problemas de «¿se puede?», se suelen necesitar las dos mitades.

**01 → 5.** ¿Cómo se calcula la paridad de una permutación, y por qué funciona? 🟡

⏱️ **30 segundos.** Contando los ciclos: la paridad es `(n − ciclos) mod 2`, porque un ciclo de longitud `L` se deshace con `L − 1` intercambios y cada intercambio cambia la paridad.

🗣️ **2 minutos.** Recorrer cada ciclo marcando visitados es `O(n)`. Contar inversiones da la misma paridad en `O(n log n)`.

🔬 **El detalle.** Dos permutaciones de distinta paridad no se transforman una en otra con un número par de intercambios: es el argumento del 15-puzzle.

**01 → 6.** ¿Qué es el prefijo `μ` y el ciclo `λ` de un proceso determinista? 🟡

⏱️ **30 segundos.** `μ` es el número de pasos antes de entrar en el ciclo; `λ`, la longitud del ciclo. A partir del paso `μ`, el estado se repite cada `λ`.

🗣️ **2 minutos.** Con un número finito de estados `S`, un proceso determinista repite estado en como mucho `S` pasos: `μ + λ ≤ S`. El estado del paso `K` es el del paso `μ + (K − μ) mod λ`.

🔬 **El detalle.** En `x ← (x² + 1) mod 10` desde 0, `μ = 0` y `λ = 6`.

**01 → 7.** ¿Qué tiene que contener el estado para que la detección de ciclos sea correcta? 🟠

⏱️ **30 segundos.** Todo lo que influye en el paso siguiente: posición **y** dirección, tablero **y** turno, contador de algo que cambie las reglas.

🗣️ **2 minutos.** Si el estado está incompleto, dos «estados iguales» pueden evolucionar distinto, y el ciclo detectado es falso. El fallo no se ve en los ejemplos pequeños.

🔬 **El detalle.** Si se usa un *hash* del estado como clave, hay que confirmar la igualdad real al encontrar un repetido.

**01 → 8.** ¿Qué cambia entre guardar los estados en un mapa y usar el algoritmo de Floyd? 🟠

⏱️ **30 segundos.** Con el mapa, memoria `O(μ + λ)` y una evaluación por paso; con Floyd (liebre y tortuga), memoria `O(1)` y unas tres evaluaciones por paso.

🗣️ **2 minutos.** El mapa también da directamente `μ` y `λ` al primer repetido. Floyd es preferible cuando los estados son grandes y hay muchos pasos antes de repetir.

🔬 **El detalle.** Brent mejora a Floyd en el número de evaluaciones.

**01 → 9.** ¿Cómo decides si una simulación directa cabe en el tiempo? 🟠

⏱️ **30 segundos.** Multiplicando el número de pasos por el coste de cada uno y comparando con unos `10⁸` operaciones por segundo.

🗣️ **2 minutos.** Si el número de pasos depende de un valor de la entrada (un tiempo de `10⁹` segundos), la simulación paso a paso no cabe y hay que buscar ciclos o fórmulas.

🔬 **El detalle.** En Python, el umbral baja a unos `10⁷`.

**01 → 10.** ¿Qué cambia entre Java, C++ y Python para guardar estados grandes (un tablero) en un mapa? 🟠

⏱️ **30 segundos.** En Java, el estado se codifica como `String` o `long` (un `int[]` no sirve de clave: se compara por identidad); en C++, `std::map` o `unordered_map` con `string` o `vector<int>` (este último con un *hash* propio); en Python, una tupla o `bytes`.

🗣️ **2 minutos.** La trampa de Java es usar arreglos como clave de un `HashMap`. En C++, `std::vector` no tiene `std::hash`: o se usa `std::map`, o se escribe el *hash*. En Python, las listas no son *hashables*.

🔬 **El detalle.** Para tableros pequeños, codificar en bits dentro de un `long` es lo más rápido en los tres.

**01 → 11.** Demuestra que, en la pizarra con los números del 1 al `n`, el último número tiene la paridad de `n(n + 1)/2`. 🔴

⏱️ **30 segundos.** Porque `a + b` y `|a − b|` tienen la misma paridad: cada jugada conserva la paridad de la suma total, y al final queda un solo número con esa paridad.

🗣️ **2 minutos.** `(a + b) − |a − b| = 2 · min(a, b)`, que es par. Por inducción sobre las jugadas, la suma conserva su paridad; la suma inicial es `n(n + 1)/2`.

🔬 **El detalle.** Con suma par, el 0 se alcanza: los bloques `(k, k + 1, k + 2, k + 3)` dan `1 − 1 = 0`, y con `n ≡ 3 (mod 4)` se empieza por `1, 2, 3`.

**01 → 12.** Una ficha se mueve como un caballo de ajedrez. Demuestra que no puede volver a su casilla en un número impar de movimientos. 🔴

⏱️ **30 segundos.** Cada salto de caballo cambia el color de la casilla en un tablero de ajedrez: tras un número impar de saltos está en el color contrario, que no es el de su casilla.

🗣️ **2 minutos.** Un salto mueve `(±1, ±2)` o `(±2, ±1)`: la suma de las coordenadas cambia en 1 o en 3, siempre impar, así que su paridad (el color) se alterna.

🔬 **El detalle.** Es una coloración como invariante: el mismo argumento muestra que el grafo del caballo es bipartito.

**01 → Problema: Monedas de dos en dos.**

**Pista 2:** el número de cruces cambia en `−2`, `0` o `+2` en cada operación: su paridad es invariante. Con un número impar, `-1`.

**Pista 3:** con un número par, emparejar las cruces de izquierda a derecha (la 1.ª con la 2.ª, la 3.ª con la 4.ª…); el mínimo es la suma de las distancias de cada pareja.

**01 → Problema: El anillo de luces.**

**Pista 2:** con `n ≤ 20` hay como mucho `2²⁰` estados: la secuencia se repite pronto y se salta el ciclo.

**Pista 3:** estado como entero de `n` bits; un mapa (o un arreglo de `2²⁰`) con el primer paso de cada estado; al repetir, `(K − paso) mod ciclo` pasos más.

**01 → Problema: Number Line Jumps.**

**Pista 2:** la distancia entre los canguros cambia en `v₁ − v₂` en cada salto.

**Pista 3:** se encuentran si `v₁ ≠ v₂`, la diferencia de posiciones es divisible por la diferencia de velocidades y el más atrasado es el más rápido; con `v₁ = v₂`, solo si empiezan juntos.

**01 → Problema: Save the Prisoner!.**

**Pista 2:** repartir `m` caramelos desde la silla `s` en un círculo de `n` es avanzar `m − 1` posiciones módulo `n`.

**Pista 3:** `((s − 1 + m − 1) mod n) + 1`, con cuidado de no restar más de lo que hay; en 64 bits si hace falta.

**01 → Problema: Bulb Switcher.**

**Pista 2:** la bombilla `i` se toca una vez por cada divisor de `i`, y queda encendida si ese número es impar: solo los cuadrados perfectos.

**Pista 3:** la respuesta es `⌊√n⌋`, con raíz entera exacta.

**01 → Problema: Robot Bounded In Circle.**

**Pista 2:** tras una ejecución de las órdenes, el robot está en un círculo si vuelve al origen o si no mira al norte.

**Pista 3:** simula una vez; si la dirección final no es la inicial, en como mucho 4 repeticiones vuelve al origen.

**01 → Problema: Walking Robot Simulation.**

**Pista 2:** simular paso a paso con un conjunto de obstáculos para consultar en `O(1)`.

**Pista 3:** codifica cada obstáculo como un `long` o una cadena en un `HashSet`; guarda el máximo de la distancia al cuadrado en cada paso.

**01 → Problema: Prison Cells After N Days.**

**Pista 2:** con 8 celdas (y la primera y la última siempre a 0 tras el primer día), hay como mucho 64 estados: el ciclo aparece enseguida.

**Pista 3:** simula guardando el día de cada estado; al repetir, salta con el módulo del ciclo; ojo con el primer día, que no forma parte del ciclo.

**01 → Problema: Flip the Bits.**

**Pista 2:** un prefijo se puede invertir si tiene tantos ceros como unos; entre dos prefijos así, cada tramo tiene que estar entero igual o entero invertido.

**Pista 3:** marca las posiciones con prefijo equilibrado en `a`; recorre los tramos entre ellas comprobando que `a` y `b` coinciden en todo el tramo o difieren en todo.

**01 → Problema: Regolith Reservoir.**

**Pista 2:** simular cada grano de arena con las reglas de caída y un conjunto de casillas ocupadas.

**Pista 3:** rocas y arena en un conjunto; el grano cae abajo, abajo a la izquierda o abajo a la derecha; en la primera parte, se detiene cuando un grano cae por debajo de la roca más baja.

**01 → Problema: Parabolic Reflector Dish.**

**Pista 2:** en la segunda parte, mil millones de ciclos de inclinación: el tablero se repite al cabo de unos cientos.

**Pista 3:** codifica el tablero como cadena, guarda el ciclo en que apareció cada estado y salta con el módulo; la carga se calcula sobre el estado final.

**01 → Problema: Pyroclastic Flow.**

**Pista 2:** la segunda parte pide la altura tras `10¹²` piezas: hay que detectar un ciclo en un estado completo.

**Pista 3:** estado = (pieza actual, posición en la secuencia de viento, perfil de las últimas filas de la torre); al repetirse, se extrapola la altura ganada por ciclo.


---

# 02 — Constructivos

**02 → 1.** ¿Qué pide un problema constructivo y qué tiene que acompañar a la respuesta? 🟢

⏱️ **30 segundos.** Fabricar una salida que cumpla una condición, o decir que no existe. Tiene que acompañarla una prueba de que cumple (o al menos un verificador) y la explicación de los casos sin solución.

🗣️ **2 minutos.** No hay un algoritmo que copiar: se diseña la construcción, normalmente por inducción, y se comprueba con un verificador antes de enviar.

🔬 **El detalle.** El juez también usa un verificador: cualquier respuesta válida se acepta.

**02 → 2.** ¿Cuántas jornadas necesita una liga de `n` equipos, con `n` par, y por qué no menos? 🟢

⏱️ **30 segundos.** `n − 1` jornadas. Hay `n(n − 1)/2` partidos y en cada jornada caben como mucho `n/2`: no se puede con menos.

🗣️ **2 minutos.** El método del círculo alcanza la cota: fija un equipo y gira los demás; cada par se encuentra exactamente una vez.

🔬 **El detalle.** Con `n` impar, se añade un equipo ficticio y salen `n` jornadas con un descanso en cada una.

**02 → 3.** ¿Cómo comprueba un juez una respuesta constructiva? 🟢

⏱️ **30 segundos.** Con un verificador (*checker*): un programa que lee la entrada y tu salida y comprueba la condición del enunciado.

🗣️ **2 minutos.** Por eso no hace falta coincidir con la respuesta oficial. Y por eso un error de formato puede dar WA aunque la idea sea correcta.

🔬 **El detalle.** Si el enunciado dice «imprime cualquiera», casi seguro que hay verificador.

**02 → 4.** ¿Qué papel tiene la fuerza bruta en un problema constructivo? 🟡

⏱️ **30 segundos.** Encontrar el patrón y los casos sin solución: se calculan todas las respuestas para `n ≤ 8`, y la forma de las soluciones sugiere la construcción.

🗣️ **2 minutos.** También sirve para el *stress test*: el verificador comprueba la construcción para todos los `n` pequeños.

🔬 **El detalle.** Los casos pequeños suelen ser las excepciones (`n = 2, 3, 4` sin solución).

**02 → 5.** ¿Qué diferencia hay entre demostrar que tu construcción cumple y demostrar que no hay solución? 🟡

⏱️ **30 segundos.** Demostrar que cumple es razonar sobre **tu** construcción; demostrar que no existe es razonar sobre **todas**: con un invariante o una cuenta.

🗣️ **2 minutos.** La primera es una inducción o un argumento directo. La segunda no puede probar casos: tiene que encontrar algo que todas las soluciones tendrían que cumplir y que es imposible.

🔬 **El detalle.** En la mesa redonda con 4 personas, la imposibilidad sale de mirar los vecinos del 1.

**02 → 6.** ¿Por qué un verificador debe comprobar la condición y no la construcción? 🟡

⏱️ **30 segundos.** Porque si comprueba la construcción, repite sus errores; comprobando la condición del enunciado, detecta errores de la idea además de los del código.

🗣️ **2 minutos.** El verificador del calendario mira que cada par juegue una vez y nadie juegue dos veces por jornada; no sabe nada del círculo.

🔬 **El detalle.** Es la misma idea que comparar con una fuerza bruta en un *stress test*.

**02 → 7.** ¿Qué cambia entre C++, Java y Python al calcular `(r − k) mod m` en el calendario? 🟠

⏱️ **30 segundos.** En C++ y Java, `%` de un negativo es negativo: `(r − k + m) % m`. En Python, `%` ya devuelve un resultado no negativo con `m > 0`.

🗣️ **2 minutos.** `(r − k) % m` con `r < k` daría un índice negativo en C++ y Java: fuera del arreglo. Sumar `m` antes lo evita.

🔬 **El detalle.** `Math.floorMod(r − k, m)` en Java hace lo mismo.

**02 → 8.** ¿Cómo adaptas el calendario cuando `n` es impar? 🟠

⏱️ **30 segundos.** Se añade un equipo ficticio para tener `n + 1` (par), se construye el calendario y quien juega contra el ficticio descansa esa jornada.

🗣️ **2 minutos.** Salen `n` jornadas con `(n − 1)/2` partidos y un descanso cada una; es óptimo: con `n` impar, en cada jornada descansa al menos uno.

🔬 **El detalle.** Es lo que hacen las ligas reales con un número impar de equipos.

**02 → 9.** «Si hay muchas respuestas, es más fácil.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que es al revés: no hay una respuesta que calcular, así que hay que diseñar una y demostrarla, y además saber cuándo no existe.

🗣️ **2 minutos.** Los constructivos son a menudo más difíciles que los de respuesta única, porque no hay una técnica que reconocer. La libertad de elegir es libertad para equivocarse.

🔬 **El detalle.** Lo que sí facilita la libertad es que se puede elegir la construcción más cómoda de demostrar.

**02 → 10.** ¿Cómo construyes una secuencia de Gray de `n` bits por inducción? 🟠

⏱️ **30 segundos.** Reflejando: la secuencia de `n` bits es la de `n − 1` bits con un 0 delante, seguida de la misma al revés con un 1 delante.

🗣️ **2 minutos.** En la unión cambia solo el bit de delante; dentro de cada mitad, la inducción. Equivale a `i XOR (i >> 1)` para el `i`-ésimo código.

🔬 **El detalle.** Es la construcción de cp-algorithms; Gray Code de LeetCode la pide tal cual.

**02 → 11.** Demuestra que el método del círculo hace que cada par de equipos juegue exactamente una vez. 🔴

⏱️ **30 segundos.** Dos equipos `a` y `b` del círculo juegan en la jornada `r` con `a ≡ r + k` y `b ≡ r − k`, es decir `2r ≡ a + b (mod n − 1)`. Como `n − 1` es impar, el 2 es invertible y esa `r` existe y es única. El fijo juega contra `r` en la jornada `r`: contra cada uno, una vez.

🗣️ **2 minutos.** En cada jornada, el fijo juega contra `r` y los demás se emparejan como `(r + k, r − k)` con `k = 1, …, n/2 − 1`: cubren los `n − 2` equipos restantes sin repetir. Por la congruencia, cada par del círculo aparece en una sola jornada.

🔬 **El detalle.** El nombre viene de dibujar los equipos en un círculo con el fijo en el centro, y girarlos un paso por jornada.

**02 → 12.** Demuestra que no se pueden sentar 4 personas numeradas del 1 al 4 en una mesa redonda sin que dos números consecutivos queden juntos. 🔴

⏱️ **30 segundos.** En un ciclo de 4, el 1 tiene dos vecinos que no pueden ser el 2: son el 3 y el 4. El 2 queda enfrente del 1, y sus dos vecinos son el 3 y el 4: el 2 queda junto al 3, que es consecutivo.

🗣️ **2 minutos.** En un ciclo de cuatro posiciones, los dos vecinos de una posición no son vecinos entre sí, y la posición de enfrente es vecina de los dos. No hay escapatoria.

🔬 **El detalle.** Con 2 y 3 tampoco hay solución; desde 5, sí: pares en orden y después impares.

**02 → Problema: Ninguna es suma de otras dos.**

**Pista 2:** si todos los números están entre `m` y `2m − 1`, la suma de dos cualesquiera es al menos `2m + 1`: mayor que todos.

**Pista 3:** imprime `n, n + 1, …, 2n − 1`; con `n ≤ 10⁵`, todos por debajo de `10⁹`.

**02 → Problema: La mesa sin conocidos.**

**Pista 2:** pares en orden y después impares en orden, con los casos pequeños aparte.

**Pista 3:** `n = 1`: `1`; `n = 2, 3, 4`: `NO`; desde 5, `2 4 … 1 3 …`: las uniones (último par con 1, último impar con 2) no son consecutivas.

**02 → Problema: Gray Code.**

**Pista 2:** reflejar: la secuencia de `n − 1` bits, y después la misma al revés con el bit `n − 1` encendido.

**Pista 3:** o directamente `i XOR (i >> 1)` para `i` de `0` a `2ⁿ − 1`.

**02 → Problema: Circular Permutation in Binary Representation.**

**Pista 2:** una secuencia de Gray desde 0, con cada elemento combinado por XOR con `start`.

**Pista 3:** `start XOR i XOR (i >> 1)`: el XOR conserva que dos vecinos difieran en un bit, y el primero es `start`.

**02 → Problema: Beautiful Arrangement II.**

**Pista 2:** alternar el menor y el mayor de los que quedan da diferencias que bajan de una en una: `k` diferencias distintas con `k + 1` números alternados, y el resto en orden.

**Pista 3:** los primeros `k + 1` números alternando extremos de `1..k + 1`, y después `k + 2, …, n` en orden creciente (diferencia 1, ya contada).

**02 → Problema: Monotone Subsequences.**

**Pista 2:** bloques decrecientes de tamaño `k` puestos en orden creciente: la creciente más larga toma uno por bloque y la decreciente, un bloque entero.

**Pista 3:** con `⌈n/k⌉` bloques, la creciente mide `⌈n/k⌉`; existe si `k · k ≥ n` (Erdős–Szekeres); si no, `IMPOSSIBLE`.

**02 → Problema: Inverse Inversions.**

**Pista 2:** voraz por posiciones: poner primero el mayor que queda crea tantas inversiones como números quedan detrás.

**Pista 3:** recorre las posiciones; si las inversiones que faltan son al menos `restantes − 1`, coloca el mayor; si no, el menor.

**02 → Problema: Special Permutation.**

**Pista 2:** recorrer los impares de mayor a menor y después los pares de menor a mayor, cuidando la unión.

**Pista 3:** para `n ≥ 4`: `…, 5, 3, 1, 4, 2, 6, 8, …` (la unión `1, 4, 2` tiene diferencias 3 y 2); con `n ≤ 3`, `-1`.

**02 → Problema: Third Permutation.**

**Pista 2:** desplazar cíclicamente `1..n` por `s`: la permutación desplazada choca con una dada en una posición para pocos `s`.

**Pista 3:** cada posición descarta como mucho dos desplazamientos (uno por permutación dada): con `n ≥ 3` queda alguno válido; los casos pequeños, a mano.

**02 → Problema: Chess Tournament.**

**Pista 2:** voraz: el jugador que más partidas tiene pendientes las juega contra los que más tienen pendientes.

**Pista 3:** con una cola de prioridad por partidas pendientes; si en algún momento no hay suficientes rivales con partidas pendientes, `IMPOSSIBLE` (es el teorema de Havel-Hakimi).

**02 → Problema: Filling Trominos.**

**Pista 2:** rejillas de `2 × 3` y `3 × 2` se llenan con dos trominós en L; las demás se componen de ellas, salvo casos pequeños.

**Pista 3:** el área tiene que ser múltiplo de 3 y ningún lado 1; se parte el rectángulo en tiras de `2 × 3` y `3 × 3`/`3 × 2`, con casos especiales (`3 × 5`, `3 × impar`) a mano; colores distintos para piezas vecinas.

**02 → Problema: Grid Path Construction.**

**Pista 2:** con un tablero de ajedrez, cada paso cambia de color: la longitud del camino que visita todas las casillas fija qué colores pueden tener el inicio y el final.

**Pista 3:** si `n · m` es par, el inicio y el final tienen que ser de distinto color; si es impar, los dos del color mayoritario; además, casos de rejillas estrechas (`1 × m`, `2 × m`) aparte, y una construcción por bandas.


---

# 03 — Interactivos

**03 → 1.** ¿Qué es un problema interactivo? 🟢

⏱️ **30 segundos.** Uno en el que el juez responde a las preguntas del programa, una a una, en lugar de dar toda la entrada al principio.

🗣️ **2 minutos.** El programa escribe una pregunta, vacía la salida, lee la respuesta y decide la siguiente; al final da la respuesta con el formato pedido. Hay un límite de preguntas.

🔬 **El detalle.** Algunos jueces son adaptativos: eligen el secreto según tus preguntas.

**03 → 2.** ¿Qué es el veredicto *Idleness Limit Exceeded* y qué lo causa casi siempre? 🟢

⏱️ **30 segundos.** Que el programa no hizo nada durante demasiado tiempo: casi siempre porque espera una respuesta a una pregunta que no llegó al juez por no vaciar el búfer.

🗣️ **2 minutos.** El programa escribe la pregunta en su búfer y se queda leyendo; el juez, que no ve nada, también espera. Se bloquean los dos hasta que salta el límite.

🔬 **El detalle.** También pasa si el programa lee más de lo que el juez envía.

**03 → 3.** ¿Cuántas preguntas de sí o no hacen falta para adivinar un número entre 1 y `10⁹`? 🟢

⏱️ **30 segundos.** 30: `⌈log₂ 10⁹⌉ = 30`.

🗣️ **2 minutos.** Cada respuesta de sí o no parte las posibilidades como mucho a la mitad; con 29 preguntas se distinguen `2²⁹ ≈ 5,4·10⁸`, menos que `10⁹`.

🔬 **El detalle.** Con `10¹⁸`, 60 preguntas.

**03 → 4.** ¿Qué diferencia hay entre `'\n'` y `std::endl` en un interactivo? 🟡

⏱️ **30 segundos.** `'\n'` solo escribe el salto de línea; `std::endl` además vacía el búfer. En un interactivo, el vaciado es lo que hace que la pregunta llegue.

🗣️ **2 minutos.** Con `'\n'` y sin `flush`, la pregunta se queda en el búfer y el programa se bloquea leyendo: ILE. En un programa normal, `std::endl` en cada línea es lento.

🔬 **El detalle.** `cout << "? " << x << '\n' << flush` es equivalente a usar `endl`.

**03 → 5.** ¿Qué es un juez adaptativo y qué cambia para tu estrategia? 🟡

⏱️ **30 segundos.** Un juez que no fija el secreto al empezar: responde de la forma que más posibilidades deja abiertas, sin contradecirse.

🗣️ **2 minutos.** Contra un juez así, la estrategia tiene que funcionar en el peor caso: la cota de `log_b N` se cumple exactamente. Una estrategia que «suele» acertar con menos preguntas, falla.

🔬 **El detalle.** Para probar en local, el interactor propio también debería ser adaptativo.

**03 → 6.** ¿Por qué un programa que funciona en la terminal da ILE en el juez? 🟡

⏱️ **30 segundos.** Porque en la terminal la salida estándar va con búfer por líneas (cada salto de línea se envía), y en el juez va a una tubería con búfer completo.

🗣️ **2 minutos.** La librería de C decide el modo de búfer según el destino: terminal, por líneas; fichero o tubería, completo. Por eso el mismo programa se comporta distinto.

🔬 **El detalle.** Probar con un interactor por tuberías reproduce el comportamiento del juez.

**03 → 7.** ¿Cómo se vacía la salida en C++, Java y Python? 🟠

⏱️ **30 segundos.** En C++, `std::endl`, `std::cout.flush()` o `fflush(stdout)`; en Java, `flush()` del `PrintWriter` o `System.out.flush()`; en Python, `print(..., flush=True)` o `sys.stdout.flush()`.

🗣️ **2 minutos.** En C++, `ios::sync_with_stdio(false)` no exime del *flush*. En Java, `System.out.println` vacía al escribir el salto, pero es lento con muchas preguntas. En Python, `print` a una tubería tiene búfer.

🔬 **El detalle.** En todos, el *flush* va después de cada pregunta y de la respuesta final.

**03 → 8.** ¿Qué haces si el juez responde `-1`, y por qué? 🟠

⏱️ **30 segundos.** Terminar inmediatamente: el `-1` indica una pregunta inválida o el límite superado, y el juez ya no responderá más.

🗣️ **2 minutos.** Si el programa sigue, leerá algo inesperado o se bloqueará, y el veredicto será WA o ILE en lugar de la causa real.

🔬 **El detalle.** La función `ask` lo comprueba en un solo sitio.

**03 → 9.** ¿Cuántas pesadas hacen falta para encontrar la moneda más pesada entre 27, y cómo se reparten? 🟠

⏱️ **30 segundos.** 3 pesadas: `27 = 3³`. Se reparten en tres grupos de 9: dos en la balanza y uno fuera; el resultado dice en qué grupo está, y se repite con 3 y con 1.

🗣️ **2 minutos.** Cada pesada tiene tres resultados (izquierda, derecha, igual) y deja un tercio de las candidatas. Con 2 pesadas solo se distinguen 9 casos.

🔬 **El detalle.** Con `n` que no es potencia de 3, grupos de `⌈n/3⌉`, con los dos de la balanza del mismo tamaño.

**03 → 10.** ¿Cómo pruebas un interactivo en local? 🟠

⏱️ **30 segundos.** Con un interactor propio: un programa que hace de juez, conectado al tuyo por tuberías (dos procesos y `mkfifo`, o un *script* que lance los dos).

🗣️ **2 minutos.** El interactor cuenta las preguntas, comprueba el formato y, mejor, es adaptativo. Escribir las respuestas a mano en la terminal sirve para ver el diálogo, pero oculta los problemas de búfer.

🔬 **El detalle.** Codeforces publica a veces el interactor de ejemplo; si no, se escribe en diez minutos.

**03 → 11.** Demuestra que `⌈log_b N⌉` preguntas con `b` respuestas posibles son necesarias en el peor caso. 🔴

⏱️ **30 segundos.** `q` preguntas con `b` respuestas posibles producen como mucho `bᵠ` secuencias de respuestas distintas; para distinguir `N` casos hacen falta al menos `N` secuencias: `bᵠ ≥ N`, es decir `q ≥ ⌈log_b N⌉`.

🗣️ **2 minutos.** Se ve como un árbol de decisión: cada nodo es una pregunta con `b` hijos, cada hoja una respuesta final. Un árbol de altura `q` tiene como mucho `bᵠ` hojas. Contra un juez adaptativo, siempre se puede forzar el camino más largo.

🔬 **El detalle.** Es la misma cuenta que la cota `Ω(n log n)` de la ordenación por comparaciones.

**03 → 12.** Con dos huevos y un edificio de 100 pisos, ¿cuántos lanzamientos hacen falta en el peor caso para saber el piso más alto desde el que no se rompen, y con qué estrategia? 🔴

⏱️ **30 segundos.** 14 lanzamientos: `14 · 15 / 2 = 105 ≥ 100`. El primer huevo se lanza desde los pisos 14, 27, 39, 50, … (saltos de 14, 13, 12…); si se rompe, el segundo recorre piso a piso el tramo anterior.

🗣️ **2 minutos.** Si el primer huevo se rompe en su lanzamiento `i`, al segundo le quedan `q − i` lanzamientos, y el tramo tiene que medir como mucho eso: los saltos van `q, q − 1, q − 2…`, y cubren `q(q + 1)/2` pisos.

🔬 **El detalle.** Con 13 lanzamientos solo se cubren 91 pisos: no basta.

**03 → Problema: La moneda pesada.**

**Pista 2:** partir las candidatas en tres grupos lo más iguales posible, dos del mismo tamaño en la balanza y el tercero fuera.

**Pista 3:** con `c` candidatas, grupos de `⌈c/3⌉` en la balanza; `<` o `>` señalan el grupo pesado, `=` el de fuera; `⌈log₃ n⌉` pesadas incluso contra un juez adaptativo.

**03 → Problema: Dos huevos.**

**Pista 2:** con `q` lanzamientos, el primer huevo se lanza desde los pisos `q`, `q + (q − 1)`, `q + (q − 1) + (q − 2)`, …; si se rompe, el segundo recorre de uno en uno el tramo de debajo.

**Pista 3:** lleva el último piso seguro y los lanzamientos usados; el tramo del segundo huevo mide lo que quede de lanzamientos menos uno; no pases de `n`.

**03 → Problema: Hidden Integer.**

**Pista 2:** búsqueda binaria con la pregunta «¿es `y < x`?»: 30 preguntas para `10⁹`.

**Pista 3:** `lo = 1`, `hi = 10⁹`; si `YES`, el secreto es mayor que `y`; con *flush* tras cada pregunta.

**03 → Problema: Interview.**

**Pista 2:** binaria sobre los montones: la suma de una mitad dice si contiene el montón con la piedra especial (sale una unidad más de lo esperado).

**Pista 3:** con prefijos de los tamaños conocidos, compara la suma preguntada con la esperada; `⌈log₂ n⌉` preguntas más la final.

**03 → Problema: Bear and Prime 100.**

**Pista 2:** un compuesto menor o igual que 100 tiene un divisor primo menor o igual que 10, o es el cuadrado de un primo pequeño.

**Pista 3:** pregunta por 2, 3, 5, 7 y por 4, 9, 25, 49; si dos respuestas son «sí» (o un cuadrado lo es), es compuesto; unas 20 preguntas como mucho.

**03 → Problema: Lost Numbers.**

**Pista 2:** los productos de pares de los 6 números especiales son casi todos distintos: con 4 productos bien elegidos se reconstruyen.

**Pista 3:** pregunta `a₁a₂`, `a₂a₃`, `a₃a₄`, `a₄a₅`; prueba todas las permutaciones de los 6 especiales (720) y quédate con la que da esos productos.

**03 → Problema: Hidden Permutation.**

**Pista 2:** ordenar por comparaciones con un algoritmo de pocas comparaciones en el peor caso: mezcla con `ask` como comparador.

**Pista 3:** `n log₂ n` preguntas como mucho; la inserción con búsqueda binaria también entra; reconstruye la permutación a partir del orden.

**03 → Problema: Guess the K-th Zero (Easy version).**

**Pista 2:** binaria sobre la suma de un prefijo: el número de ceros en `[1, m]` es `m − suma`.

**Pista 3:** busca el menor `m` con `m − suma(1, m) ≥ k`; unas 20 preguntas.

**03 → Problema: Fixed Point Guessing.**

**Pista 2:** preguntar por un tramo `[l, m]` devuelve sus valores ordenados; los que siguen en el tramo y su paridad dicen en qué mitad está el punto fijo.

**Pista 3:** cuenta cuántos valores devueltos están en `[l, m]`: si es impar, el punto fijo está en esa mitad; si no, en la otra. `⌈log₂ n⌉` preguntas.

**03 → Problema: Colored Chairs.**

**Pista 2:** con `n` impar en círculo, hay dos vecinas del mismo color; en un tramo con un número impar de sillas y extremos de colores distintos, también.

**Pista 3:** si `1` y `n` son del mismo color, ya está; si no, binaria sobre `[1, n]` preguntando sillas a distancia par de un extremo para conservar el invariante.

**03 → Problema: Permuted Binary Strings.**

**Pista 2:** pregunta por la cadena del bit `j` de cada índice (`bᵢ` = bit `j` de `i`): la respuesta da el bit `j` del índice original de cada posición.

**Pista 3:** con `⌈log₂ n⌉` preguntas se reconstruye el índice de cada posición bit a bit.

**03 → Problema: K-th Highest Score.**

**Pista 2:** binaria sobre cuántos elementos tomar de cada país: comparar el `i`-ésimo de uno con el `(k − i)`-ésimo del otro descarta la mitad.

**Pista 3:** es la `k`-ésima de dos arreglos ordenados con preguntas: `O(log n)` preguntas, cuidando los bordes (`i = 0` o `k − i > n`).


---

# 04 — El estilo de las pruebas de empresa

**04 → 1.** ¿Qué buscas en la segunda lectura de un enunciado de empresa? 🟢

⏱️ **30 segundos.** Las reglas: formatos de entrada y salida, unidades, redondeos, casos especiales, orden de la salida y qué hacer con entradas inválidas.

🗣️ **2 minutos.** La primera lectura da la idea; la segunda convierte el texto en una lista de reglas que luego se comprueba una a una. Lo que no está claro se pregunta o se decide por escrito.

🔬 **El detalle.** Los ejemplos también son reglas: cada uno fija un detalle del formato.

**04 → 2.** ¿Por qué se pasan las horas a minutos desde la medianoche? 🟢

⏱️ **30 segundos.** Porque un número de minutos se compara, se resta y se ordena como un entero, y el cruce de la medianoche se trata sumando 1 440.

🗣️ **2 minutos.** `"08:30"` es `510`. Restar horas y minutos por separado obliga a «llevar» unidades y es fuente de errores.

🔬 **El detalle.** Lo mismo con segundos: `HH:MM:SS` a segundos desde la medianoche.

**04 → 3.** ¿Cuál es la regla completa de los años bisiestos? 🟢

⏱️ **30 segundos.** Es bisiesto si es múltiplo de 4, salvo que sea múltiplo de 100 y no de 400.

🗣️ **2 minutos.** 2024 lo es; 1900 no; 2000 sí. En el calendario gregoriano, desde 1582 (o 1918 en Rusia, que es lo que pregunta Day of the Programmer).

🔬 **El detalle.** En una prueba se deja a `java.time`, `datetime` o `<chrono>`.

**04 → 4.** ¿Qué diferencia hay entre `split(" ")` y `split("\\s+")` sobre una línea con dos espacios seguidos? 🟡

⏱️ **30 segundos.** `split(" ")` deja un campo vacío entre dos espacios seguidos; `split("\\s+")` trata cualquier secuencia de espacios como un solo separador.

🗣️ **2 minutos.** Con `"a  b"`, `split(" ")` da `["a", "", "b"]` y `split("\\s+")` da `["a", "b"]`. Con espacios al principio, `split("\\s+")` aún deja un campo vacío: se recorta antes.

🔬 **El detalle.** En Python, `str.split()` sin argumento hace ya las dos cosas.

**04 → 5.** ¿Qué diferencia hay entre redondear el valor binario de un `double` y redondear su representación decimal más corta? 🟡

⏱️ **30 segundos.** El valor binario de un `double` casi nunca es el decimal escrito: `0.105` es `0.10499999…`. Redondear ese valor da `0.10`; redondear su representación decimal más corta (`"0.105"`) da `0.11`.

🗣️ **2 minutos.** Python y C redondean el valor binario exacto; el `String.format` de Java parte de la representación decimal más corta. Por eso el mismo cálculo se imprime distinto.

🔬 **El detalle.** La solución no es elegir el lenguaje, sino no depender de ello: enteros o decimales exactos.

**04 → 6.** ¿Cómo calculas la duración de un turno que cruza la medianoche? 🟡

⏱️ **30 segundos.** Si el fin no es posterior al inicio, se suman 1 440 minutos al fin: `fin − inicio + 1 440`.

🗣️ **2 minutos.** `22:00`–`06:00`: `360 + 1 440 − 1 320 = 480` minutos. Si un turno puede durar exactamente 24 horas, el enunciado tiene que decir cómo se escribe.

🔬 **El detalle.** Para solapamientos con turnos que cruzan, se comparan también las copias desplazadas un día.

**04 → 7.** ¿Qué cambia entre Java, Python y C++ al imprimir `0.5 * 0.21` con dos decimales? 🟠

⏱️ **30 segundos.** Python imprime `0.10`, C++ con `printf` también `0.10`, y Java con `String.format` imprime `0.11`.

🗣️ **2 minutos.** Python y C redondean el `double` exacto, que está por debajo de `0.105`; Java redondea la representación decimal más corta, `0.105`, *half-up*.

🔬 **El detalle.** En céntimos enteros, `(50 · 21 + 50) / 100 = 11` en los tres.

**04 → 8.** ¿Por qué el *locale* puede cambiar la salida de `String.format`, y cómo lo evitas? 🟠

⏱️ **30 segundos.** Porque `String.format` usa el *locale* por defecto de la máquina, y en una configuración en español el separador decimal es la coma. Se evita con `String.format(Locale.ROOT, …)`.

🗣️ **2 minutos.** En el juez suele estar en inglés, así que el fallo aparece en local y no en el juez, o al revés si el juez está configurado distinto. Con el *locale* fijado, la salida es la misma en todas partes.

🔬 **El detalle.** `System.out.printf` tiene el mismo problema; `Double.toString` no, pero no controla los decimales.

**04 → 9.** ¿Cómo aseguras la puntuación parcial en una prueba de 90 minutos con tres problemas? 🟠

⏱️ **30 segundos.** Una versión correcta de cada problema primero (aunque sea lenta), enviada; después, las mejoras de la que más puntos pueda dar.

🗣️ **2 minutos.** Con 30 minutos por problema: unos 10–15 para una versión que pase los casos pequeños y bordes, y el resto para la eficiente. Nunca quedarse sin nada enviado en un problema.

🔬 **El detalle.** En Codility, la nota separa corrección y rendimiento: la versión lenta ya da la parte de corrección.

**04 → 10.** ¿Qué casos borde añadirías siempre a una prueba de Codility, si no ves los ocultos? 🟠

⏱️ **30 segundos.** Entrada mínima (vacía o de un elemento), valores en los extremos de los rangos, todos iguales, ya ordenado y al revés, y un caso grande para el rendimiento.

🗣️ **2 minutos.** Codility enseña uno o dos ejemplos y oculta el resto: los bordes los pone uno. Un caso grande generado comprueba que no hay nada cuadrático.

🔬 **El detalle.** También los negativos si el rango los permite, y el desbordamiento con valores máximos.

**04 → 11.** Diseña el cálculo de horas trabajadas por empleado a partir de un registro de fichajes desordenado, con turnos que cruzan la medianoche y salidas que faltan, y di qué preguntarías antes. 🔴

⏱️ **30 segundos.** Ordenar los fichajes por empleado y hora, recorrerlos emparejando cada ENTRADA con la SALIDA siguiente y sumar duraciones con cruce de medianoche; antes, preguntar qué hacer con una ENTRADA sin SALIDA, dos ENTRADAS seguidas y turnos de más de 24 horas.

🗣️ **2 minutos.** Fechas y horas con `LocalDateTime` (la diferencia con `Duration.between`), o minutos desde una época. Las horas, con el redondeo que fije el enunciado, en enteros (minutos) hasta el final.

🔬 **El detalle.** Escribir las interpretaciones elegidas en un comentario cuenta si no hay a quién preguntar.

**04 → 12.** Demuestra que `(c · p + 50) / 100` en división entera redondea *half-up* el `p %` de `c` céntimos, para `c, p ≥ 0`. 🔴

⏱️ **30 segundos.** `(c · p + 50) div 100 = ⌊c · p / 100 + 1/2⌋`, que es redondear `c · p / 100` al entero más cercano con los empates hacia arriba.

🗣️ **2 minutos.** Con `c · p = 100q + r`, `0 ≤ r < 100`: si `r < 50`, el resultado es `q` (redondeo hacia abajo); si `r ≥ 50`, `q + 1` (hacia arriba, incluido el empate `r = 50`). Es *half-up*.

🔬 **El detalle.** Con cantidades negativas, la división entera de C++ y Java trunca hacia cero y la fórmula deja de ser *half-up*: se trata el signo aparte.

**04 → Problema: Turnos que se pisan.**

**Pista 2:** cada turno como intervalo en minutos, con el fin más 1 440 si cruza la medianoche; dos turnos se solapan si alguna copia desplazada un día se solapa.

**Pista 3:** compara cada par con desplazamientos de `−1 440`, `0` y `+1 440`; solapamiento si `max(inicios) < min(fines)`; `2·10⁶` pares.

**04 → Problema: El ticket.**

**Pista 2:** todo en céntimos enteros: el precio `12.30` es `1230`, el IVA es `(suma · 21 + 50) / 100`.

**Pista 3:** parte el precio por el punto (sin `double`); suma en 64 bits; imprime con `cents / 100` y `cents % 100` a dos cifras.

**04 → Problema: Códigos de producto.**

**Pista 2:** primero la forma (3 mayúsculas, guion, 4 dígitos, guion, 1 mayúscula), después la letra de control.

**Pista 3:** recorta; una expresión regular `[A-Z]{3}-\d{4}-[A-Z]` o comprobación carácter a carácter; control `'A' + (suma de dígitos) mod 26`.

**04 → Problema: Day of the Programmer.**

**Pista 2:** antes de 1918, calendario juliano (bisiesto cada 4); 1918, el año del cambio, con 13 días menos en febrero; después, gregoriano.

**Pista 3:** el día 256 cae en septiembre: 12 o 13 según bisiesto, y el 26 en 1918.

**04 → Problema: Reformat Date.**

**Pista 2:** tabla de meses y quitar los dos últimos caracteres del día.

**Pista 3:** `"20th"` → `20`; el mes por su posición en una lista; formato `AAAA-MM-DD` con ceros a la izquierda.

**04 → Problema: Day of the Year.**

**Pista 2:** suma de los días de los meses anteriores más el día, con febrero de 29 si el año es bisiesto.

**Pista 3:** o `LocalDate.parse(fecha).getDayOfYear()`.

**04 → Problema: Number of Days Between Two Dates.**

**Pista 2:** convertir cada fecha a días desde una época y restar en valor absoluto.

**Pista 3:** `ChronoUnit.DAYS.between` en Java o `date` de Python; o la fórmula de días desde 1971 con la regla de bisiestos.

**04 → Problema: Reformat Phone Number.**

**Pista 2:** agrupar de tres en tres, y al final dos bloques de dos si quedan 4 dígitos.

**Pista 3:** quita espacios y guiones; mientras queden más de 4, bloques de 3; con 4, dos de 2; con 2 o 3, uno.

**04 → Problema: Count Days Spent Together.**

**Pista 2:** cada fecha `MM-DD` como día del año; la respuesta es la intersección de los dos intervalos.

**Pista 3:** `max(0, min(salidas) − max(llegadas) + 1)` con los días del año de 2021 (no bisiesto, como dice el enunciado).

**04 → Problema: Minimum Time Difference.**

**Pista 2:** minutos desde la medianoche, ordenados; la menor diferencia entre vecinos, y también entre el último y el primero más 1 440.

**Pista 3:** con más de 1 440 horas hay un repetido (respuesta 0); un arreglo de 1 440 posiciones evita ordenar.

**04 → Problema: Integer to English Words.**

**Pista 2:** bloques de tres cifras con el mismo procedimiento, y la escala (`Thousand`, `Million`, `Billion`) después de cada uno no nulo.

**Pista 3:** tablas para `0–19`, decenas y escalas; recursión sobre `n mod 1 000` y `n / 1 000`; el 0 es `Zero` solo si el número entero es 0; sin espacios dobles.

**04 → Problema: Text Justification.**

**Pista 2:** voraz por líneas: meter palabras mientras quepan con un espacio entre ellas; repartir los espacios sobrantes desde la izquierda.

**Pista 3:** con `g` huecos y `e` espacios extra, los `e mod g` primeros huecos reciben `e/g + 1`; la última línea y las de una palabra, alineadas a la izquierda y rellenas al final.


---

# 05 — Heurísticos y aproximados

**05 → 1.** ¿Qué es un óptimo local? 🟢

⏱️ **30 segundos.** Una solución que ningún movimiento de la vecindad mejora; puede estar lejos del óptimo global.

🗣️ **2 minutos.** Depende del movimiento: con 2-opt, un recorrido sin dos aristas que «se crucen» de forma mejorable. Otra vecindad (3-opt, Or-opt) puede mejorarlo.

🔬 **El detalle.** El óptimo global es también local para cualquier vecindad.

**05 → 2.** ¿Qué hace un movimiento 2-opt en el problema del viajante? 🟢

⏱️ **30 segundos.** Quita dos aristas del recorrido y reconecta los dos tramos al revés: invierte un tramo del recorrido.

🗣️ **2 minutos.** Con el recorrido `… a b … c d …`, cambia `(a, b)` y `(c, d)` por `(a, c)` y `(b, d)`. El cambio de longitud se calcula con esas cuatro distancias.

🔬 **El detalle.** En el plano, un 2-opt que mejora siempre deshace un cruce de aristas.

**05 → 3.** ¿Qué garantiza una `α`-aproximación? 🟢

⏱️ **30 segundos.** Que su solución nunca cuesta más que `α` veces el óptimo (en minimización), para cualquier entrada.

🗣️ **2 minutos.** Es una garantía de peor caso, demostrada. La cobertura de vértices tiene `α = 2`; la cobertura de conjuntos voraz, `α = Hₙ ≈ ln n`.

🔬 **El detalle.** En maximización, la solución es al menos `OPT/α`.

**05 → 4.** ¿Qué diferencia hay entre búsqueda local y recocido simulado? 🟡

⏱️ **30 segundos.** La búsqueda local solo acepta mejoras y se detiene en un óptimo local; el recocido acepta a veces empeorar, con probabilidad `e^{−Δ/T}`, y puede salir de él.

🗣️ **2 minutos.** El recocido elige movimientos al azar y la temperatura `T` baja con el tiempo: al principio explora, al final se comporta como búsqueda local.

🔬 **El detalle.** La búsqueda local con reinicios aleatorios es otra forma de no quedarse en el primer valle.

**05 → 5.** ¿Qué diferencia hay entre *beam search* y un voraz? 🟡

⏱️ **30 segundos.** El voraz elige la mejor opción en cada paso y se queda solo con ella; *beam search* conserva las `B` mejores y decide después.

🗣️ **2 minutos.** Con `B = 1`, *beam search* es el voraz. Con `B` mayor, tolera errores de la evaluación parcial a costa de `B` veces más trabajo.

🔬 **El detalle.** Con `B` infinito sería una búsqueda en anchura exhaustiva.

**05 → 6.** ¿Qué pasa si la temperatura del recocido es demasiado alta o demasiado baja? 🟡

⏱️ **30 segundos.** Demasiado alta: acepta casi todo y es un paseo al azar. Demasiado baja: no acepta empeoramientos y es una búsqueda local que se atasca.

🗣️ **2 minutos.** La temperatura se fija en las unidades del coste: al principio del orden de un `Δ` típico, al final del menor cambio que importa. Se ajusta probando con varias semillas.

🔬 **El detalle.** El enfriamiento geométrico (`T = t0 · (t1/t0)^progreso`) es el más usado.

**05 → 7.** ¿Por qué el recocido evalúa `Δ` y no el coste entero de cada vecino? 🟠

⏱️ **30 segundos.** Porque un movimiento cambia poco la solución y su efecto se calcula en `O(1)`; recalcular el coste entero cuesta `O(n)` y divide por `n` las iteraciones.

🗣️ **2 minutos.** En 2-opt, `Δ` son cuatro distancias. Con más iteraciones por segundo, el recocido explora mucho más en el mismo tiempo, y eso es lo que da la calidad.

🔬 **El detalle.** Aplicar el movimiento (invertir el tramo) sí es `O(n)`, pero solo cuando se acepta.

**05 → 8.** ¿Qué cambia entre C++, Java y Python para un recocido con un límite de dos segundos? 🟠

⏱️ **30 segundos.** En C++ se hacen decenas de millones de iteraciones por segundo; en Java, del mismo orden tras calentar la JVM; en Python, unas 50 veces menos.

🗣️ **2 minutos.** En los tres se mira el reloj cada pocas iteraciones (`steady_clock`, `System.nanoTime`, `time.perf_counter`) y no en cada una, porque leerlo cuesta.

🔬 **El detalle.** En Python compensa vectorizar o reducir la evaluación al mínimo; en concursos de heurísticos casi todos usan C++ o Rust.

**05 → 9.** ¿Por qué el recocido puede salir de un óptimo local y la búsqueda local no? 🟠

⏱️ **30 segundos.** Porque acepta movimientos que empeoran con probabilidad `e^{−Δ/T}`: puede subir una cresta y bajar a otro valle. La búsqueda local solo baja.

🗣️ **2 minutos.** Con `T` alta, cruzar crestas es frecuente; al bajar `T`, la búsqueda se queda en el valle más profundo que encontró. Por eso el enfriamiento lento da mejores resultados.

🔬 **El detalle.** Con enfriamiento logarítmico, la teoría garantiza converger al óptimo global; en la práctica es demasiado lento y se usa geométrico.

**05 → 10.** «Si no es óptimo, no sirve.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que en problemas NP-difíciles el óptimo no se puede calcular a tiempo, y una solución a pocos puntos del óptimo, ya, es lo que sirve.

🗣️ **2 minutos.** Con 500 ciudades, el exacto es imposible; el recocido con 2-opt queda a unos pocos por ciento del óptimo en segundos. Las empresas de logística viven de eso.

🔬 **El detalle.** Si además hace falta una garantía, un algoritmo de aproximación.

**05 → 11.** Demuestra que el emparejamiento maximal da una 2-aproximación de la cobertura de vértices. 🔴

⏱️ **30 segundos.** Las aristas de un emparejamiento maximal `M` no comparten extremos: cualquier cobertura tiene al menos un vértice de cada una, `OPT ≥ |M|`. El algoritmo toma `2|M| ≤ 2·OPT`, y cubre todo porque una arista sin cubrir se podría añadir a `M`.

🗣️ **2 minutos.** Sobre el grafo de juguete, el emparejamiento en el orden de las aristas da 6 vértices y la cobertura mínima tiene 3 (`B, C, F`): el factor 2 se alcanza.

🔬 **El detalle.** No se conoce una aproximación con factor constante menor que 2; con la conjetura de los juegos únicos, no existe.

**05 → 12.** Diseña una heurística para asignar 1 000 turnos a 50 empleados minimizando los turnos seguidos de cada uno, y di cómo evaluarías un cambio en `O(1)`. 🔴

⏱️ **30 segundos.** Recocido sobre asignaciones completas: el movimiento es reasignar un turno o intercambiar dos turnos entre empleados; el coste, los turnos seguidos. El cambio solo afecta a los vecinos en el tiempo de los turnos tocados.

🗣️ **2 minutos.** Para cada empleado se guarda qué turnos tiene ordenados por tiempo; reasignar un turno cambia solo sus vecinos en la lista del empleado que lo pierde y del que lo gana: `Δ` en `O(1)` (o `O(log n)` con un conjunto ordenado).

🔬 **El detalle.** Las restricciones duras (nadie con dos turnos a la vez) se pueden penalizar en el coste con un peso grande, o prohibir en el movimiento.

**05 → Problema: La cobertura del emparejamiento.**

**Pista 2:** recordar qué vértices están ya en la cobertura: una arista se toma si sus dos extremos están fuera.

**Pista 3:** un arreglo de booleanos; recorre las aristas una vez; ordena (o recorre) los vértices marcados al final.

**05 → Problema: Mejora por 2-opt.**

**Pista 2:** al invertir el tramo `tᵢ₊₁ … tⱼ`, solo cambian las aristas `(tᵢ, tᵢ₊₁)` y `(tⱼ, tⱼ₊₁)`; las de dentro del tramo se recorren al revés pero miden lo mismo.

**Pista 3:** compara `d(tᵢ, tⱼ) + d(tᵢ₊₁, tⱼ₊₁)` con `d(tᵢ, tᵢ₊₁) + d(tⱼ, tⱼ₊₁)`; si mejora más de `10⁻⁹`, invierte y reinicia; con `n ≤ 200`, las pasadas entran.

**05 → Problema: Code vs Zombies.**

**Pista 2:** simular el turno entero y probar muchas secuencias de movimientos al azar, quedándose con la mejor puntuación.

**Pista 3:** una simulación fiel de las reglas (orden de movimientos y muertes); en cada turno, unas miles de secuencias aleatorias con el tiempo disponible; guardar la mejor entre turnos.

**05 → Problema: Search Race.**

**Pista 2:** simular la física y buscar en cada turno el par (ángulo, empuje) que más acerca a los puntos de control, mirando algunos turnos por delante.

**Pista 3:** *beam search* o búsqueda aleatoria sobre secuencias de unos pocos turnos, con una evaluación que combine distancia al punto y orientación.

**05 → Problema: Mars Lander.**

**Pista 2:** buscar secuencias de controles (ángulo, potencia) que, simuladas, aterricen en la zona plana con velocidad baja; mejorar las que casi lo consiguen.

**Pista 3:** algoritmo genético o recocido sobre secuencias de controles, con un coste que penaliza la distancia a la zona y la velocidad al tocar el suelo.

**05 → Problema: Walking on Tiles.**

**Pista 2:** un camino voraz (siempre a la baldosa vecina de más valor) mejorado con recocido sobre tramos del camino.

**Pista 3:** movimiento: borrar un tramo y reconstruirlo por otra ruta sin repetir baldosas; o *beam search* con la puntuación acumulada.

**05 → Problema: Patrolling.**

**Pista 2:** elegir pocos puntos desde los que se ven todas las calles y recorrerlos con el menor coste: un viajante sobre esos puntos.

**Pista 3:** voraz para elegir los puntos, Dijkstra para las distancias entre ellos, y 2-opt o recocido para el orden.

**05 → Problema: SameGame.**

**Pista 2:** *beam search* sobre las jugadas, con una evaluación que premie las grandes agrupaciones de un color que aún se pueden formar.

**Pista 3:** en cada nivel, los `B` mejores tableros por puntuación acumulada más una estimación de lo que queda; tablas *hash* para no repetir tableros.

**05 → Problema: AtCoder Ad.**

**Pista 2:** rectángulos que crecen desde `1 × 1` en su punto, con recocido sobre los bordes de cada rectángulo.

**Pista 3:** movimiento: desplazar un borde de un rectángulo (crecer o encoger) sin solapar a otros; coste: la puntuación del enunciado según el área pedida.

**05 → Problema: Shortest Path Queries.**

**Pista 2:** estimar el coste de cada arista con los costes observados de los caminos devueltos, y usar esas estimaciones en Dijkstra.

**Pista 3:** repartir el error (observado − estimado) entre las aristas del camino, con más peso al principio; aprovechar que las aristas de una fila tienden a costar parecido.


---

# 06 — Simulación

**06 → S1.** ¿Qué es un invariante y qué permite demostrar? 🟢

⏱️ **30 segundos.** Una cantidad que ninguna operación cambia; demuestra que un estado es inalcanzable si su valor difiere del inicial.

🗣️ **2 minutos.** La paridad de una suma, del número de algo o de una permutación, el resto módulo `k`, una coloración. No demuestra que algo sea posible.

🔬 **El detalle.** Para el «sí», una construcción.

**06 → S2.** ¿Qué hay que hacer después de cada pregunta en un problema interactivo? 🟢

⏱️ **30 segundos.** Vaciar la salida (*flush*), para que la pregunta llegue al juez.

🗣️ **2 minutos.** `std::endl` o `fflush(stdout)` en C++, `flush()` en Java, `print(..., flush=True)` en Python. Sin eso, *Idleness Limit Exceeded*.

🔬 **El detalle.** Y comprobar si la respuesta es `-1` para terminar.

**06 → S3.** ¿Cómo comprueba un juez una respuesta constructiva? 🟢

⏱️ **30 segundos.** Con un verificador que comprueba la condición del enunciado: cualquier respuesta válida se acepta.

🗣️ **2 minutos.** Por eso no hace falta coincidir con la respuesta oficial; y por eso conviene escribir el propio verificador para probar.

🔬 **El detalle.** Si el enunciado dice «imprime cualquiera», casi seguro que lo hay.

**06 → S4.** ¿Cuántas preguntas de sí o no hacen falta para adivinar un número entre 1 y `10⁶`? 🟢

⏱️ **30 segundos.** 20: `⌈log₂ 10⁶⌉ = 20`.

🗣️ **2 minutos.** `2¹⁹ = 524 288 < 10⁶ ≤ 2²⁰ = 1 048 576`. Con 19 preguntas no se distinguen todos los casos.

🔬 **El detalle.** Con respuestas de tres valores (`<`, `=`, `>`), la cota es la misma en el peor caso si el `=` llega al final.

**06 → S5.** ¿Cómo calculas la duración de un turno de 22:00 a 06:00? 🟡

⏱️ **30 segundos.** Pasando las horas a minutos desde la medianoche y, como el fin es anterior al inicio, sumando 1 440 al fin: `360 + 1 440 − 1 320 = 480` minutos, 8 horas.

🗣️ **2 minutos.** La regla general: si `fin ≤ inicio`, el turno cruza la medianoche. Si hay fechas, `Duration.between` sobre `LocalDateTime`.

🔬 **El detalle.** Un turno de exactamente 24 horas necesita que el enunciado diga cómo se escribe.

**06 → S6.** ¿Qué es un óptimo local? 🟢

⏱️ **30 segundos.** Una solución que ningún movimiento de la vecindad mejora.

🗣️ **2 minutos.** La búsqueda local se detiene en uno; puede estar lejos del óptimo global.

🔬 **El detalle.** Depende de la vecindad: con otro movimiento, quizá se mejora.

**06 → S7.** ¿Cuándo se puede saltar un ciclo en una simulación de `10¹⁸` pasos? 🟡

⏱️ **30 segundos.** Cuando el proceso es determinista y tiene pocos estados posibles: se repite en como mucho `S` pasos y, a partir de ahí, es periódico.

🗣️ **2 minutos.** Se guarda el paso en que apareció cada estado; al repetirse, el estado del paso `K` es el del paso `μ + (K − μ) mod λ`. El estado tiene que ser completo.

🔬 **El detalle.** Si el estado crece sin límite (una posición), no hay ciclo y hace falta otra idea.

**06 → S8.** ¿Qué diferencia hay entre búsqueda local y recocido simulado? 🟡

⏱️ **30 segundos.** La búsqueda local solo acepta mejoras; el recocido acepta empeorar con probabilidad `e^{−Δ/T}`, y la temperatura baja con el tiempo.

🗣️ **2 minutos.** Por eso el recocido puede salir de un óptimo local. Con `T` muy baja es una búsqueda local; muy alta, un paseo al azar.

🔬 **El detalle.** En el viajante de 200 puntos de [`20/05`](05-heuristicos-y-aproximados.md), el recocido queda un 5 % por debajo de 2-opt.

**06 → S9.** ¿Qué garantiza la 2-aproximación de la cobertura de vértices? 🟡

⏱️ **30 segundos.** Que la cobertura que devuelve tiene como mucho el doble de vértices que la mínima.

🗣️ **2 minutos.** Toma los dos extremos de cada arista de un emparejamiento maximal; cualquier cobertura necesita uno por arista emparejada.

🔬 **El detalle.** En el grafo de juguete, el factor 2 se alcanza: 6 frente a 3.

**06 → S10.** ¿Por qué el dinero se calcula en céntimos y no en `double`? 🟡

⏱️ **30 segundos.** Porque los decimales como `0.10` no son exactos en binario, y el redondeo de un importe acaba dependiendo del lenguaje. En céntimos enteros, todo es exacto.

🗣️ **2 minutos.** `0.5 * 0.21` con dos decimales es `0.10` en Python y `0.11` en Java. En céntimos, `(50 · 21 + 50) / 100 = 11` en cualquier lenguaje.

🔬 **El detalle.** La alternativa es `BigDecimal` con `RoundingMode.HALF_UP`.

**06 → S11.** «Si no hay técnica, no hay método.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que sí hay método: buscar un invariante (qué no cambia), un monovariante (qué solo crece o decrece), o simular con un estado completo.

🗣️ **2 minutos.** Los problemas ad hoc no tienen nombre de técnica, pero se atacan con un procedimiento: casos pequeños, qué se conserva, qué cabe simular.

🔬 **El detalle.** Las tres primeras candidatas a invariante: paridad de una suma, paridad de un conteo, resto módulo algo.

**06 → S12.** Tu interactivo funciona en la terminal y da *Idleness Limit Exceeded* en el juez. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** Que falta el *flush*: en la terminal la salida va por líneas y llega; en el juez va por una tubería con búfer completo, y la pregunta se queda en el programa.

🗣️ **2 minutos.** El programa espera la respuesta y el juez espera la pregunta: se bloquean los dos. Con `std::endl`, `flush()` o `flush=True`, la pregunta sale.

🔬 **El detalle.** Para reproducirlo en local, un interactor conectado por tuberías.

**06 → S13.** «Si hay muchas respuestas válidas, el problema es más fácil.» ¿Qué respondes? 🟠

⏱️ **30 segundos.** Que es al revés: no hay una respuesta que calcular, hay que diseñar una, demostrarla y saber cuándo no existe.

🗣️ **2 minutos.** La libertad es para elegir la construcción más fácil de demostrar, no para no demostrar nada. El verificador del juez no perdona.

🔬 **El detalle.** Los constructivos suelen estar entre los problemas con menos aciertos de un concurso.

**06 → S14.** Tu simulación con detección de ciclo da una respuesta distinta de la simulación lenta. ¿Qué miras? 🟠

⏱️ **30 segundos.** Si el estado está completo (todo lo que influye en el siguiente paso) y si el salto usa bien `μ` y `λ`.

🗣️ **2 minutos.** Un estado incompleto produce un «ciclo» falso. Un error de uno en `(K − paso) mod λ` da un estado vecino del correcto. Comparar con la simulación lenta para `K` pequeños localiza el fallo.

🔬 **El detalle.** Con un *hash* del estado como clave, también una colisión.

**06 → S15.** Tu programa imprime `0,11` en tu máquina y el juez espera `0.11`. ¿Qué ha pasado? 🟠

⏱️ **30 segundos.** Que `String.format` usa el *locale* de tu máquina, que en español escribe la coma decimal. Se fija con `Locale.ROOT`.

🗣️ **2 minutos.** El juez suele estar en inglés; tu máquina, no. Con `String.format(Locale.ROOT, "%.2f", x)`, o en céntimos con `cents / 100` y `cents % 100`, la salida es la misma en todas partes.

🔬 **El detalle.** `printf` de Java tiene el mismo problema.

**06 → S16.** «Si no es óptimo, no sirve.» ¿Qué respondes, ante un viajante de 500 ciudades? 🟠

⏱️ **30 segundos.** Que con 500 ciudades el óptimo exacto no se puede calcular a tiempo, y un recocido con 2-opt da en segundos un recorrido a pocos puntos del óptimo, que es lo que se usa.

🗣️ **2 minutos.** La DP exacta del viajante llega a unas 20 ciudades. Para 500, heurísticas; y si hace falta garantía, la 2-aproximación con el árbol mínimo en el caso métrico.

🔬 **El detalle.** «Bueno ya» vale más que «óptimo nunca».

**06 → S17.** El invariante de tu problema vale lo mismo en el estado inicial y en el objetivo. ¿Ya sabes que se puede? 🟠

⏱️ **30 segundos.** No: un invariante que coincide no dice nada. Puede haber otro invariante que no coincida, o el objetivo puede ser alcanzable; hace falta construir el camino.

🗣️ **2 minutos.** En los camaleones, la condición módulo 3 no basta si todos ya son de otro color: ahí no hay movimientos. La construcción es la que demuestra el «sí».

🔬 **El detalle.** Una fuerza bruta sobre casos pequeños ayuda a ver si el invariante es suficiente.

**06 → S18.** En una prueba de 90 minutos te quedan 15 y el problema 3 no está. ¿Qué haces? 🟠

⏱️ **30 segundos.** Enviar lo que tenga del problema 3 que pase algún caso (fuerza bruta, casos borde), y revisar el formato de los otros dos.

🗣️ **2 minutos.** Con 15 minutos, la mejor inversión es asegurar puntos parciales, no empezar la solución eficiente. Una versión lenta y correcta suele pasar los casos pequeños.

🔬 **El detalle.** Antes de terminar, comprobar que todo lo enviado compila y que la salida tiene el formato exacto.

**06 → S19.** Demuestra que un caballo de ajedrez no puede volver a su casilla en un número impar de saltos. 🔴

⏱️ **30 segundos.** Cada salto del caballo mueve `(±1, ±2)` o `(±2, ±1)`: la suma de coordenadas cambia en un número impar, así que el color de la casilla cambia en cada salto. Tras un número impar de saltos, está en el color contrario.

🗣️ **2 minutos.** La paridad de `x + y` es el invariante que alterna. Volver a la casilla de partida exige la misma paridad: número par de saltos.

🔬 **El detalle.** Equivale a que el grafo de movimientos del caballo es bipartito.

**06 → S20.** Diseña una estrategia para encontrar la moneda más pesada entre 100 con una balanza, en el menor número de pesadas posible en el peor caso, y demuestra que no se puede con menos. 🔴

⏱️ **30 segundos.** Cinco pesadas: `3⁴ = 81 < 100 ≤ 3⁵ = 243`. En cada pesada, partir las candidatas en tres grupos lo más iguales posible (dos del mismo tamaño en la balanza); con cuatro pesadas solo se distinguen 81 casos.

🗣️ **2 minutos.** Grupos de 34, 34 y 32; después, de 12, 12 y 10 (o 11 y 11 y 12); y así. La cota: cada pesada tiene tres resultados, `q` pesadas distinguen `3ᵠ` casos, y hacen falta 100.

🔬 **El detalle.** Contra un juez adaptativo, la cota se alcanza en el peor caso.

**06 → Problema: Los camaleones.**

**Pista 2:** la diferencia entre dos recuentos cambia en `0` o en `±3` en cada encuentro: módulo 3 es invariante.

**Pista 3:** si todos ya son de un color, solo ese; si no, el color `c` es posible si y solo si los otros dos recuentos son congruentes módulo 3. En el orden `R G B`.

**06 → Problema: Récords.**

**Pista 2:** con `k = 0` o `k > n`, `-1`; si no, el número `n − k + 1` primero, después `1 … n − k`, y después `n − k + 2 … n` en orden creciente.

**Pista 3:** el primero es récord; los pequeños no; cada uno de los `k − 1` del final, sí: `k` récords.

**06 → Problema: Días hábiles.**

**Pista 2:** recorrer los días con la librería de fechas y contar los que no son sábado, domingo ni festivo.

**Pista 3:** `LocalDate` y `getDayOfWeek()`; festivos en un `HashSet`; como mucho unos 73 000 días, o una fórmula por semanas completas si hay muchas consultas.

**06 → Problema: La cola del banco.**

**Pista 2:** recorrer los clientes recordando el instante en que la ventanilla queda libre.

**Pista 3:** el cliente empieza en `max(libre, aᵢ)`, espera `inicio − aᵢ`, y la ventanilla queda libre en `inicio + sᵢ`; sumas en 64 bits.

**06 → Problema: Teemo Attacking.**

**Pista 2:** cada ataque suma `min(duración, siguiente ataque − este)`, y el último suma la duración entera.

**Pista 3:** un recorrido; sin simular segundo a segundo.

**06 → Problema: Different Differences.**

**Pista 2:** diferencias crecientes `1, 2, 3, …` mientras quepan en `n`, y el resto de uno en uno hasta llegar a `n`.

**Pista 3:** construye desde el final: el último elemento es `n`, y hacia atrás se restan diferencias crecientes mientras queden posiciones suficientes.

**06 → Problema: Binary Period.**

**Pista 2:** si `t` solo tiene ceros o solo unos, el periodo es 1 y `s = t`; si no, el periodo 2 es el menor posible, con `0101…` o `1010…`.

**Pista 3:** alterna `01` (o `10`) tantas veces como `|t|`: la longitud `2|t|` contiene a `t` como subsecuencia.

**06 → Problema: Seating System.**

**Pista 2:** cada paso calcula el estado nuevo a partir del viejo entero: hay que construir una copia y sustituir al final.

**Pista 3:** simula hasta que el estado no cambie; en la segunda parte, la regla mira la primera silla visible en cada dirección.

**06 → Problema: Beautiful Permutation II.**

**Pista 2:** el voraz que elige el menor número válido puede quedarse sin opción al final: hay que reservar los últimos.

**Pista 3:** para `n` grande, el voraz funciona salvo en las últimas posiciones, que se resuelven probando las pocas permutaciones de los que quedan; `n = 2, 3`: `NO SOLUTION`.

