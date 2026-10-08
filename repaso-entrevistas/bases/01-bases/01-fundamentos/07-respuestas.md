# 07 — Respuestas

> Solucionario centralizado del bloque `01-fundamentos`. Cada respuesta en tres capas:
> **⏱️ 30 segundos** (lo que dices primero, sin que te lo pidan), **🗣️ 2 minutos** (lo que
> añades cuando dicen "cuéntame más") y **🔬 El detalle** (para estudiar, no para recitar).
> Los enunciados están copiados literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--complejidad-y-o-grande) · [02](#02--tdas-contrato-e-implementación) ·
[03](#03--arrays-listas-y-secuencias) · [04](#04--recursión-y-backtracking) ·
[05](#05--bits-y-aritmética-binaria) ·
[06 — transversales](#06--simulación-preguntas-transversales) ·
[06 — pizarra](#06--simulación-problemas-de-pizarra)

---

# 01 — Complejidad y O grande

**01 → 1. ¿Qué mide exactamente la notación O grande?**

⏱️ Cómo crece el trabajo de un algoritmo cuando crece la entrada, ignorando constantes y
términos de menor orden.
🗣️ No mide velocidad ni tiempo: mide escalabilidad. Por eso `3n² + 500n + 9000` es O(n²): para
n grande, el término cuadrático aplasta a los demás. La pregunta que responde es "¿aguanta si
crece?", no "¿es rápido hoy?".
🔬 "Para n grande" puede estar muy lejos: con n = 10, ese `9000` es el 90 % del trabajo real.
Por eso la complejidad es mala guía cuando la entrada está acotada y es pequeña.

**01 → 2. ¿Cuál es la complejidad de dos bucles anidados sobre colecciones de tamaño n y m?**

⏱️ O(n·m).
🗣️ No es O(n²): usar n² cuando las dos colecciones son distintas es impreciso, y un
entrevistador lo nota. Solo colapsa a O(n²) si ambas tienen el mismo tamaño o si m está acotado
por n.
🔬 Si los bucles fueran secuenciales en vez de anidados, sería O(n + m), que se simplifica al
mayor de los dos.

**01 → 3. ¿Cuál es la complejidad de la búsqueda binaria y por qué aparece el logaritmo?**

⏱️ O(log n), porque cada paso descarta la mitad del espacio de búsqueda.
🗣️ Partir n a la mitad repetidamente hasta llegar a 1 requiere log₂(n) pasos. Con mil millones
de elementos son 30 comparaciones, que es prácticamente gratis. El patrón "divido a la mitad
cada vez" es siempre un logaritmo: también la altura de un árbol balanceado.
🔬 La base del logaritmo no aparece en la notación porque cambiar de base es multiplicar por
una constante, y las constantes se descartan.

**01 → 4. ¿Por qué `O(2n)` y `O(n)` son la misma cosa?**

⏱️ Porque O grande descarta las constantes multiplicativas por definición.
🗣️ Recorrer un arreglo dos veces crece igual de rápido que recorrerlo una vez: al duplicar n,
ambos duplican el trabajo. Escribir O(2n) no es más preciso, es incorrecto en notación.
🔬 Lo que sí importa es que en la práctica dos recorridos tardan el doble. La notación lo
oculta a propósito, y por eso las constantes se discuten aparte, con perfilador.

**01 → 5. ¿Qué complejidad esperarías que te pidan si el enunciado dice "hasta 10⁶ elementos"?**

⏱️ O(n) o O(n log n). Con un millón, O(n²) serían 10¹² operaciones: días.
🗣️ El tamaño de la entrada en el enunciado es una pista deliberada sobre el algoritmo
esperado. n ≤ 10 admite factorial; n ≤ 25 admite exponencial con poda; n ≤ 5 000 admite
cuadrático; a partir de 10⁶ hace falta lineal o linearítmico.
🔬 Decirlo en voz alta —*"con 10⁶ asumo que buscas n log n, no n²"*— es de las frases que mejor
impresión causan, porque demuestra que sabes leer el enunciado y no solo resolverlo.

**01 → 6. ¿Qué significa que un algoritmo sea Θ(n log n) y no solo O(n log n)?**

⏱️ Que la cota es ajustada por los dos lados: no crece ni más rápido ni más lento.
🗣️ O acota por arriba, Ω por abajo y Θ por ambos. Decir que merge sort es O(n²) es
técnicamente cierto y suena a que no lo sabes; decir que es Θ(n log n) afirma que esa es su
tasa exacta de crecimiento.
🔬 En conversación normal nadie dice Θ: se dice O y se asume ajustada. La distinción se saca
cuando el entrevistador te la busca, no antes.

**01 → 7. ¿En qué se diferencian el coste amortizado y el caso medio?**

⏱️ El amortizado es una garantía sobre una secuencia de operaciones; el caso medio es una
apuesta sobre la distribución de los datos.
🗣️ `ArrayList.add` es O(1) amortizado: en cualquier secuencia de n inserciones el total es
O(n), sin depender de qué datos metas. Quicksort es O(n log n) en el caso medio: depende de que
los datos no estén en el peor orden posible. Uno es matemática sobre la secuencia; el otro,
probabilidad sobre la entrada.
🔬 La consecuencia práctica: contra un adversario que elige los datos, el caso medio se puede
provocar; el amortizado no.

**01 → 8. ¿Por qué la base del logaritmo no aparece en la notación?**

⏱️ Porque cambiar de base es multiplicar por una constante, y las constantes se descartan.
🗣️ log₂(n) = log₁₀(n) / log₁₀(2), y ese divisor es fijo. Da igual si el algoritmo divide en dos
o en diez: la forma de la curva es la misma.
🔬 Donde sí importa es en la constante real: un B-tree con factor 100 hace muchos menos accesos
a disco que un árbol binario con la misma n, y esa es la razón de existir del B-tree.

**01 → 9. ¿Cuál es la complejidad en espacio de merge sort y cuál la de quicksort?**

⏱️ Merge sort, O(n) auxiliar siempre. Quicksort, O(log n) de pila si la partición es
equilibrada, O(n) si es pésima.
🗣️ Merge sort necesita un arreglo auxiliar para la fusión y no hay forma barata de evitarlo.
Quicksort trabaja in-place, pero "in-place" no significa O(1): la recursión ocupa pila, y esa
pila cuenta como espacio.
🔬 Las implementaciones serias de quicksort recursan primero sobre la partición **menor** y
convierten la mayor en un bucle, con lo que acotan la pila a O(log n) incluso en el peor caso.

**01 → 10. ¿Por qué se dice que Ω(n log n) es una propiedad del problema de ordenar y no de un algoritmo?**

⏱️ Porque ningún algoritmo basado en comparar pares puede bajar de ahí: es una cota inferior
del problema.
🗣️ El argumento es de teoría de la información: hay n! ordenaciones posibles y cada
comparación da un bit, así que hacen falta al menos log₂(n!) ≈ n log n comparaciones para
distinguirlas. No es que no se haya encontrado un algoritmo mejor: es que no puede existir.
🔬 Por eso counting sort y radix sort **sí** bajan de ahí: no comparan elementos entre sí, sino
que usan el valor como índice. La cota no les aplica porque juegan a otro juego.

**01 → 11. ¿Qué complejidad tiene `ArrayList.add` y por qué la respuesta tiene dos partes?**

⏱️ O(1) amortizado, y O(n) en la inserción concreta que dispara el redimensionado.
🗣️ Cuando el arreglo interno se llena, se reserva otro más grande y se copia todo. Como la
capacidad se multiplica en vez de sumarse, esas copias son cada vez más raras y el total en n
inserciones es O(n), de donde sale O(1) por operación.
🔬 La respuesta de una parte —"O(1)"— es la incompleta, y la de "O(n)" es la alarmista. La
palabra "amortizado" es lo que demuestra que entiendes por qué ambas son ciertas.

**01 → 12. ¿Qué diferencia hay entre complejidad en espacio auxiliar y espacio total?**

⏱️ El auxiliar es lo que el algoritmo pide además de la entrada; el total incluye la entrada.
🗣️ Un algoritmo in-place tiene espacio auxiliar O(1) y espacio total O(n), porque la entrada
ocupa n. Cuando alguien dice "espacio O(1)" casi siempre se refiere al auxiliar, y conviene
decir cuál estás dando.
🔬 En una entrevista, lo que preguntan es el auxiliar: es lo que depende de tu decisión de
diseño. El total lo fija el enunciado.

**01 → 13. ¿Por qué duplicar la capacidad da O(1) amortizado y crecer de diez en diez no?**

⏱️ Porque duplicar hace que las copias sean cada vez más raras: la serie geométrica suma 2n.
🗣️ Con duplicación, tras n inserciones has copiado 1+2+4+…+n ≈ 2n elementos en total, o sea dos
copias por elemento en toda su vida: O(1) por operación. Creciendo de diez en diez hay n/10
redimensionados y cada uno copia hasta n elementos, lo que da O(n²) total y O(n) amortizado.
🔬 El factor concreto no importa mientras sea multiplicativo: 1.5 (Java), 2 (Go hasta 256
elementos) o 1.125 (Python) dan todos O(1) amortizado, con distinta constante y distinto
desperdicio de memoria.

**01 → 14. Un `while` avanza dos punteros que nunca retroceden sobre el mismo arreglo. ¿Es cuadrático? Justifica.**

⏱️ No: es O(n). Cada iteración mueve un puntero y ninguno vuelve atrás, así que hay como mucho
n movimientos en total.
🗣️ La intuición engaña porque hay dos variables de bucle y parece anidado. La forma correcta de
contar no es "cuántos bucles hay", sino "cuántas veces se ejecuta la línea más interna". Aquí,
la suma de los avances de ambos punteros está acotada por n.
🔬 Es el mismo argumento que hace lineal a la pila monótona, donde un `while` vive dentro de un
`for`: cada elemento entra una vez y sale como mucho una vez.

**01 → 15. ¿Por qué `T(n) = 2T(n/2) + O(1)` da Θ(n) y `T(n) = 2T(n/2) + O(n)` da Θ(n log n)?**

⏱️ Porque en la primera el trabajo está en las hojas y en la segunda está repartido por igual
en cada nivel.
🗣️ En ambas hay log n niveles y el nivel k tiene 2ᵏ subproblemas. Con O(1) de combinación, el
trabajo por nivel se duplica hacia abajo y lo domina el último nivel, que tiene n hojas: total
Θ(n). Con O(n) de combinación, cada nivel hace exactamente n trabajo y hay log n niveles:
total Θ(n log n).
🔬 Esa es la intuición del teorema maestro sin enunciarlo: compara el trabajo de la raíz con el
de las hojas y quédate con el mayor; si empatan, multiplicas por el número de niveles.

**01 → 16. ¿Cuándo es correcto elegir deliberadamente un algoritmo O(n²)?**

⏱️ Cuando n está acotado y es pequeño por contrato, y el código cuadrático es más claro.
🗣️ Doce meses, cincuenta estados, ocho estrategias de cobro: ahí la complejidad es irrelevante
y la legibilidad no. También cuando la constante del algoritmo "bueno" es tan alta que pierde
para tu n real, que es el caso de `insertion sort` para subarreglos pequeños dentro de
TimSort.
🔬 Lo que convierte esto en una respuesta cara es decirlo explícitamente: *"elijo el cuadrático
a propósito porque n ≤ 50 por contrato de negocio"*. Sin esa frase, parece descuido.

**01 → 17. ¿Por qué el coste amortizado es mala métrica para un sistema con SLA de p99?**

⏱️ Porque el amortizado promedia sobre la secuencia, y el p99 pregunta justo por la operación
cara que el promedio esconde.
🗣️ Esa inserción concreta que dispara el rehash de un mapa de diez millones de entradas tarda
de verdad. Si tu SLA es de latencia por petición, esa petición incumple aunque el promedio esté
perfecto.
🔬 Las salidas son dimensionar la capacidad desde el inicio para que no haya redimensionados,
o usar estructuras que crecen incrementalmente en vez de de golpe. Es el mismo razonamiento
que lleva a los recolectores de basura de pausa acotada.

**01 → 18. ¿Por qué recorrer un arreglo puede ser mucho más rápido que recorrer una lista enlazada si ambos son O(n)?**

⏱️ Por la localidad de caché: el arreglo es contiguo y el procesador trae 16 enteros por cada
lectura de memoria.
🗣️ La CPU lee líneas de 64 bytes, no valores sueltos. En un arreglo, 15 de cada 16 accesos ya
están en caché; en una lista enlazada, cada `next` es un salto impredecible a otra zona del
montón y la CPU espera. En Java hay un agravante: `LinkedList<Integer>` guarda punteros a
objetos, así que son dos saltos por elemento.
🔬 El factor real ronda 5–10× y no aparece en ninguna tabla de complejidades, porque el modelo
de coste de O grande asume que todos los accesos a memoria valen lo mismo.

**01 → 19. ¿Qué mide realmente un `System.nanoTime()` alrededor de un bucle en la JVM, y qué usarías en su lugar?**

⏱️ Mide el intérprete, el GC y la caché mezclados con tu algoritmo. Se usa JMH.
🗣️ Las primeras miles de ejecuciones corren interpretadas porque el JIT aún no ha compilado;
una pausa de GC en medio se atribuye a tu código; y si no usas el resultado, el JIT puede
eliminar el bucle entero y medirás cero. Además, el segundo recorrido del mismo arreglo es más
rápido porque ya está en caché, así que el orden en que mides cambia el resultado.
🔬 JMH (`org.openjdk.jmh`) resuelve las tres cosas: hace warmup, aísla iteraciones y evita la
eliminación de código muerto con `Blackhole`. Sin warmup declarado, un número de `nanoTime` no
es evidencia de nada.

**01 → 20. En Python, `lista.insert(0, x)` y `deque.appendleft(x)` hacen lo mismo. ¿Tienen la misma complejidad? ¿Por qué?**

⏱️ No: `list.insert(0, x)` es O(n) y `deque.appendleft(x)` es O(1).
🗣️ El `list` de Python es un arreglo dinámico, así que insertar al principio desplaza todos los
elementos una posición. El `deque` es una lista doblemente enlazada de bloques, diseñada
exactamente para operar en los dos extremos.
🔬 La consecuencia real: un bucle que hace `insert(0, x)` n veces es cuadrático y es un bug de
rendimiento clásico en Python. La documentación de `collections` lo advierte explícitamente.

**01 → 21. En JavaScript, `array.shift()` se documenta como que elimina el primer elemento. ¿Qué coste tiene y por qué existe una alternativa?**

⏱️ Es O(n), porque reindexa todos los elementos restantes.
🗣️ Un `Array` de JavaScript es un arreglo indexado: quitar la posición 0 obliga a mover todo un
lugar. Implementar una cola con `push`/`shift` sobre un millón de elementos es, por tanto,
cuadrático.
🔬 JavaScript no trae un deque en la stdlib. Las alternativas reales son mantener un índice de
cabeza y no borrar nunca (a costa de memoria), o usar una lista enlazada propia. Los motores
optimizan `shift` para arreglos pequeños, lo que hace que el bug no se vea en pruebas.

**01 → 22. Un método hace una búsqueda binaria dentro de un bucle sobre n elementos, y después ordena el resultado. ¿Cuál es su complejidad total?**

⏱️ O(n log n): el bucle con la binaria da n log n y la ordenación también, así que se suman dos
términos del mismo orden.
🗣️ La regla es que la complejidad la manda la fase más cara. Aquí empatan, y sumar dos O(n log
n) sigue siendo O(n log n) porque la constante se descarta.
🔬 El matiz que se pregunta después: si en vez de buscar en un arreglo ordenado usaras un
`HashMap`, el bucle bajaría a O(n) y el total quedaría dominado por la ordenación. La pregunta
siguiente suele ser si la ordenación hace falta de verdad.

**01 → 23. Te dan el proceso de facturación del problema inicial: 200 000 productos, 40 000 líneas, seis horas. Propón la solución, di su nueva complejidad y qué pagas por ella.**

⏱️ Indexar el catálogo en un `HashMap<ProductoId, Money>` una sola vez y consultar por línea:
de O(n·m) a O(n + m).
🗣️ La construcción del mapa es O(n) sobre los 200 000 productos; cada línea consulta en O(1)
amortizado. De ocho mil millones de comparaciones se baja a 240 000 operaciones, o sea de horas
a milisegundos. Lo pagas con memoria: el mapa ocupa del orden de decenas de MB.
🔬 La repregunta esperada es "¿y si el catálogo no cabe en memoria?". Ahí la respuesta cambia de
estructura a arquitectura: ordenar ambas fuentes por `ProductoId` y hacer un *merge join* en un
solo recorrido, que es O(n log n + m log m) y usa memoria constante. Es exactamente lo que hace
el optimizador de una base de datos al elegir entre hash join y merge join.

**01 → 24. Un compañero demuestra con `nanoTime` que su `LinkedList` gana al `ArrayList`. Da tres hipótesis en orden de probabilidad.**

⏱️ Sin warmup, midiendo el intérprete; el `ArrayList` está pagando redimensionados que la
`LinkedList` no tiene; o el caso medido es precisamente inserción en medio con el iterador en
la mano.
🗣️ La primera es la más probable con diferencia: las primeras miles de iteraciones corren
interpretadas y el orden de ejecución decide. La segunda se descarta preasignando capacidad. La
tercera es el único escenario donde `LinkedList` gana de verdad, y hay que comprobar si el
benchmark lo representa o si es un caso irreal.
🔬 Cuarta hipótesis, menos probable pero real: el benchmark no usa el resultado y el JIT
eliminó parte del bucle del `ArrayList`. La respuesta profesional no es discutir el número, es
pedir que se repita con JMH.

**01 → 25. Escribe un algoritmo O(n) que encuentre el segundo elemento más grande de un arreglo, y di qué hace con duplicados y con un arreglo de un solo elemento.**

⏱️ Un solo recorrido con dos variables, `mayor` y `segundo`, actualizando en ese orden.
🗣️ En cada elemento: si es mayor que `mayor`, `segundo = mayor` y `mayor = elemento`; si no, si
es mayor que `segundo` **y distinto de `mayor`**, actualiza `segundo`. Una sola pasada, O(1) de
espacio.

```java
long mayor = Long.MIN_VALUE, segundo = Long.MIN_VALUE;
for (int x : datos) {
    if (x > mayor) { segundo = mayor; mayor = x; }
    else if (x > segundo && x != mayor) { segundo = x; }
}
```

🔬 Los casos borde son la pregunta real. Con `[5, 5, 5]` no existe segundo distinto: hay que
decidir y declarar si devuelves 5 o un error, y el `x != mayor` es lo que separa las dos
semánticas. Con un solo elemento no hay segundo: devuelve `Optional.empty()` en vez de
`MIN_VALUE`, porque `MIN_VALUE` es un valor legítimo del arreglo. Con el arreglo vacío, lo
mismo. Nombrar estos tres casos sin que te los pregunten es lo que puntúa.

---

# 02 — TDAs: contrato e implementación

**02 → 1. ¿Qué diferencia hay entre un TDA y una estructura de datos?**

⏱️ El TDA es el contrato —qué operaciones hay y qué significan—; la estructura es la
implementación —cuánto cuesta cada una—.
🗣️ "Una pila es algo donde metes y sacas por arriba" es un TDA completo y no dice si por dentro
hay un arreglo o nodos enlazados. En Java la separación es visible en el lenguaje: las
interfaces de `java.util` son los TDAs y las clases son las implementaciones.
🔬 La consecuencia práctica es la regla de declarar por la interfaz: `List<Producto> catalogo =
new ArrayList<>()` te deja cambiar de implementación tocando una línea.

**02 → 2. ¿Qué operación define a una pila y cuál a una cola?**

⏱️ La pila es LIFO: sale el último que entró. La cola es FIFO: sale el primero que entró.
🗣️ En Java ambas se implementan hoy con `ArrayDeque`, que es un deque y por tanto las contiene
a las dos: `push`/`pop` para pila, `offer`/`poll` para cola.
🔬 El detalle que se pregunta: la pila de llamadas de la JVM es literalmente un TDA pila, y una
cola de mensajes de un broker es el TDA cola con durabilidad encima.

**02 → 3. ¿Qué garantiza un conjunto que no garantiza una lista?**

⏱️ Que no hay duplicados. A cambio pierde el orden posicional y el acceso por índice.
🗣️ No es "una lista sin duplicados": es otro contrato. Un `Set` no tiene `get(i)` porque la
posición no forma parte de su semántica, y por eso `HashSet` puede permitirse no guardar orden
ninguno.
🔬 Lo que decide si dos elementos son "el mismo" es `equals`, apoyado en `hashCode` para las
implementaciones de hash. Un objeto mutable cuyo `hashCode` cambia después de insertarlo queda
inalcanzable dentro del conjunto: ni se encuentra ni se puede borrar.

**02 → 4. ¿Por qué `Map` no extiende `Collection` en Java?**

⏱️ Porque su elemento es un par clave-valor, no un valor suelto: no encaja en el contrato de
`Collection<E>`.
🗣️ `Collection` promete operaciones sobre elementos individuales —`add(E)`, `contains(E)`,
`iterator()`— y un mapa no tiene un "elemento" único que satisfaga esas firmas. Java resuelve
la tensión con las tres vistas: `keySet()`, `values()` y `entrySet()`, que **sí** son
colecciones.
🔬 Esas vistas están respaldadas por el mapa, no copiadas: borrar de `keySet()` borra del mapa.
Es un detalle que sorprende y que se pregunta.

**02 → 5. ¿Qué complejidad tiene `get(i)` en `ArrayList` y en `LinkedList`?**

⏱️ O(1) en `ArrayList`, O(n) en `LinkedList`.
🗣️ El `ArrayList` calcula la dirección aritméticamente; la `LinkedList` tiene que recorrer los
nodos uno a uno hasta la posición i.
🔬 `LinkedList` optimiza a medias: empieza por el extremo más cercano al índice pedido, lo que
da n/4 en promedio. Sigue siendo O(n), y el bucle `for (int i = 0; i < lista.size(); i++)
lista.get(i)` sobre una `LinkedList` es cuadrático. Ese bucle existe en producción, en algún
sitio, ahora mismo.

**02 → 6. ¿Qué estructura usarías para un historial con "atrás" y "adelante"?**

⏱️ Dos pilas, implementadas con `ArrayDeque`.
🗣️ La pila de atrás guarda lo visitado; al ir atrás, la página actual pasa a la pila de
adelante. Al navegar a una página nueva, la pila de adelante se vacía, que es exactamente lo
que hace un navegador.
🔬 La respuesta buena nombra los dos niveles: el TDA (dos pilas) y la implementación
(`ArrayDeque`, no `Stack`). Responder "un `ArrayList`" contesta la pregunta equivocada.

**02 → 7. ¿Por qué se declara `List<T> x = new ArrayList<>()` y no `ArrayList<T> x = ...`?**

⏱️ Porque el tipo declarado es el contrato: te deja cambiar de implementación tocando una sola
línea.
🗣️ Es el ítem 64 de *Effective Java*. El código que consume la variable solo depende de las
operaciones, no de cómo están implementadas, lo que además hace los tests más fáciles de
escribir con dobles.
🔬 La excepción legítima es necesitar un método que solo existe en la clase concreta —
`descendingMap()` de `TreeMap`, por ejemplo—. Y una trampa real: `ArrayDeque` no admite `null` y
`LinkedList` sí, así que cambiar la implementación puede romper en ejecución aunque el contrato
de la interfaz se respete.

**02 → 8. ¿Qué diferencia a `HashMap` de `LinkedHashMap` y qué cuesta la diferencia?**

⏱️ `LinkedHashMap` conserva el orden de inserción; cuesta dos punteros extra por entrada.
🗣️ Por dentro es un `HashMap` con una lista doblemente enlazada que atraviesa todas las
entradas. El acceso sigue siendo O(1) amortizado y la iteración es incluso más rápida, porque
recorre la lista y no los buckets vacíos.
🔬 Su uso menos conocido y más valioso: con el constructor de `accessOrder = true` y
sobrescribiendo `removeEldestEntry`, es una caché LRU completa en cinco líneas.

**02 → 9. ¿Cuándo prefieres `TreeMap` a `HashMap`? Da dos operaciones que solo el primero ofrece.**

⏱️ Cuando necesitas orden por clave. `subMap(desde, hasta)` y `floorKey(k)` no existen en un
mapa de hash.
🗣️ `TreeMap` implementa `NavigableMap`: consultas de rango, el vecino más cercano por arriba o
por abajo, primera y última clave, e iteración ordenada. Todo eso es imposible en O(1) sobre un
hash, porque el hash destruye el orden por diseño.
🔬 El precio es O(log n) en todas las operaciones básicas y más memoria por nodo. La regla:
si nunca preguntas por rangos ni por vecinos, `TreeMap` solo te está cobrando.

**02 → 10. ¿Por qué `Stack` está desaconsejada y qué se usa en su lugar?**

⏱️ Porque extiende `Vector`: está sincronizada sin que la pidas y su iteración va del fondo
hacia arriba. Se usa `ArrayDeque`.
🗣️ Heredar de `Vector` le da además todos los métodos de lista —`get(i)`, `add(i, x)`— que no
tienen sentido en una pila y permiten violar su contrato. La documentación de `ArrayDeque` la
recomienda explícitamente como sustituta.
🔬 Es un ejemplo de manual de por qué la herencia rompe encapsulamiento: `Stack` **es un**
`Vector` cuando debería **tener un** arreglo. El argumento completo está en
`repaso-arquitectura-entrevistas`.

**02 → 11. ¿Qué es un multiset y cómo se emula en Java?**

⏱️ Un conjunto que cuenta repeticiones. En Java se emula con `Map<T, Integer>`.
🗣️ El idioma moderno es `mapa.merge(clave, 1, Integer::sum)`, que inserta 1 la primera vez y
suma después. Guava trae un `Multiset` de verdad si ya dependes de ella.
🔬 La asimetría que se pregunta: Python sí lo trae en la stdlib, `collections.Counter`, con
`most_common(k)` incluido. Saber que Java no lo tiene y Python sí es una respuesta de
entrevista políglota.

**02 → 12. ¿En qué se parecen `HashSet` y `HashMap` por dentro?**

⏱️ `HashSet` **es** un `HashMap`: guarda tus elementos como claves y un objeto centinela
compartido como valor.
🗣️ Literalmente: el campo interno es un `HashMap<E, Object>` y la constante es un `PRESENT`
estático. Por eso `HashSet` tiene exactamente las mismas propiedades de coste y los mismos
requisitos de `equals`/`hashCode`.
🔬 Lo mismo pasa con `TreeSet`, que envuelve un `TreeMap`. Decirlo demuestra que has mirado
dentro de la biblioteca, que es una señal distinta a saberte la tabla de complejidades.

**02 → 13. ¿`PriorityQueue` está ordenada? ¿Qué devuelve iterarla?**

⏱️ No. Solo garantiza que la cabeza es el mínimo. Iterarla devuelve los elementos en el orden
del arreglo interno del heap, que no es el orden de prioridad.
🗣️ El heap solo mantiene el invariante padre ≤ hijos, que es mucho más débil que el orden
total. Por eso `toString()` de una `PriorityQueue` desconcierta a todo el mundo la primera vez:
sale "desordenada" y está perfectamente correcta.
🔬 Para recorrerla en orden hay que ir haciendo `poll()`, lo que la vacía y cuesta O(n log n).
Y `contains` y `remove(Object)` son O(n), porque hay que buscar linealmente en el arreglo.

**02 → 14. ¿Qué pasa si metes `null` en un `ArrayDeque` y por qué se diseñó así?**

⏱️ Lanza `NullPointerException`. Se diseñó así porque `null` es el valor centinela que devuelven
`poll()` y `peek()` para decir "está vacía".
🗣️ Si se admitieran nulos, un `poll()` que devuelve `null` sería ambiguo: no sabrías si la cola
está vacía o si sacaste un `null` legítimo. Prohibirlos convierte esa ambigüedad en un fallo
inmediato en la inserción.
🔬 `LinkedList` sí los admite por razones históricas, y esa es justamente la trampa de cambiar
una implementación por otra: el código compila y revienta en ejecución.

**02 → 15. ¿Conserva `dict` de Python el orden de inserción? ¿Desde cuándo y con qué garantía?**

⏱️ Sí, desde Python 3.7, y **por especificación del lenguaje**, no por casualidad.
🗣️ En 3.6 el orden ya se conservaba como efecto secundario de una nueva implementación más
compacta, pero era un detalle no garantizado. En 3.7 se elevó a garantía del lenguaje, así que
ya se puede depender de ello.
🔬 La consecuencia es que `collections.OrderedDict` quedó casi redundante. Casi: sigue teniendo
`move_to_end()` y una comparación de igualdad que **sí** tiene en cuenta el orden, cosa que
`dict` no hace.

**02 → 16. ¿Por qué el recorrido de un `map` en Go es aleatorio?**

⏱️ Para que ningún programa pueda depender de un orden que el runtime no promete.
🗣️ Es una decisión de diseño de lenguaje, no de rendimiento: el runtime empieza la iteración en
un bucket aleatorio a propósito. Así, un código que asumiera orden falla en la primera
ejecución en vez de fallar en producción dos años después, cuando cambie la implementación.
🔬 Es el contraste perfecto con Java: `HashMap` **no garantiza** orden, que es distinto de
**garantizar** que no lo hay. En Java un código que dependa del orden puede funcionar durante
años y romperse al cambiar de versión.

**02 → 17. ¿Cómo implementas una caché LRU en Java sin escribir una lista doblemente enlazada?**

⏱️ Con `LinkedHashMap`, el constructor de `accessOrder = true` y sobrescribiendo
`removeEldestEntry`.
🗣️ El tercer parámetro del constructor pone el mapa en orden de acceso en vez de inserción, con
lo que cada `get` mueve la entrada al final. Sobrescribiendo `removeEldestEntry` para que
devuelva `true` cuando el tamaño pase del máximo, el mapa expulsa solo la entrada menos usada.

```java
new LinkedHashMap<ProductoId, Money>(capacidad, 0.75f, true) {
    @Override protected boolean removeEldestEntry(Map.Entry<ProductoId, Money> eldest) {
        return size() > capacidad;   // expulsa la menos usada recientemente
    }
};
```

🔬 La versión de cincuenta líneas —`HashMap` más lista doblemente enlazada a mano— es la que te
van a pedir si el enunciado dice "sin usar bibliotecas". Conviene saber las dos y empezar
diciendo que la corta existe: demuestra que conoces la plataforma antes de reinventarla.

**02 → 18. ¿Por qué `array.shift()` en JavaScript no sirve para implementar una cola grande?**

⏱️ Porque es O(n): reindexa todos los elementos restantes en cada llamada.
🗣️ Procesar un millón de eventos con `push`/`shift` es cuadrático. El bug es especialmente
traicionero porque los motores optimizan `shift` para arreglos pequeños, así que las pruebas
pasan y producción se arrastra.
🔬 JavaScript no trae deque en la stdlib. Las salidas reales son mantener un índice de cabeza y
no borrar nunca —a costa de memoria, compactando de vez en cuando— o implementar una lista
enlazada. Es la ausencia más notoria de las cinco bibliotecas estándar que compara este corpus.

**02 → 19. Ninguno de los otros cuatro lenguajes tiene `TreeMap`. ¿Cómo resuelves "dame las claves entre A y B" en Python y en Go?**

⏱️ En Python, con una lista ordenada y `bisect`; en Go, con un slice ordenado y `sort.Search`.
🗣️ En ambos casos mantienes las claves ordenadas y usas búsqueda binaria para localizar los dos
extremos del rango; lo de en medio es un corte contiguo. La consulta sale O(log n) y el corte
O(k), que es lo mismo que daría un `TreeMap`.
🔬 El precio está en la **inserción**: en una lista ordenada es O(n) porque hay que desplazar,
mientras que un árbol balanceado inserta en O(log n). Si el conjunto cambia mucho, en Python se
usa `sortedcontainers` (externa, con listas por bloques) y en Go se implementa un árbol o se
cambia de enfoque. Decir "no está en la stdlib y por eso el ecosistema tiene esta biblioteca" es
la respuesta completa.

**02 → 20. ¿Por qué `contains` es O(n) en `PriorityQueue` si `poll` es O(log n)?**

⏱️ Porque el heap solo ordena la relación padre-hijo: para saber si un elemento cualquiera está,
hay que mirarlos todos.
🗣️ El invariante del heap es local —cada padre es menor que sus hijos— y no dice nada sobre el
orden entre hermanos ni entre ramas. No hay forma de descartar media estructura como haría un
árbol de búsqueda, así que la búsqueda es lineal sobre el arreglo.
🔬 Lo mismo afecta a `remove(Object)`: O(n) para encontrarlo y O(log n) para restaurar el
invariante. Si necesitas borrar por clave con frecuencia, el patrón correcto es un heap más un
mapa de posiciones, o marcar como borrado y descartar al hacer `poll`.

**02 → 21. Tienes que elegir entre `HashSet` y `TreeSet` para 10 millones de IDs de los que solo consultas pertenencia. Elige y di qué pagas.**

⏱️ `HashSet`: la pertenencia es O(1) amortizado contra O(log n), y no necesitas orden.
🗣️ Con 10 millones, log n son 23 comparaciones por consulta contra una sola operación de hash.
Lo que pagas es memoria: el `HashSet` reserva capacidad de sobra por el factor de carga, y sin
orden no puedes contestar rangos ni vecinos si el requisito cambia.
🔬 La respuesta cara añade una tercera opción: si solo necesitas pertenencia aproximada y puedes
tolerar falsos positivos, un **filtro de Bloom** hace lo mismo con una fracción de la memoria.
Es el tipo de alternativa que convierte una respuesta correcta en una buena.

**02 → 22. ¿En qué caso concreto `LinkedList` sí gana a `ArrayList`, y por qué casi nunca se da?**

⏱️ Cuando insertas o borras en medio **teniendo ya el nodo o el iterador posicionado**, y lo
haces muchas veces.
🗣️ Ese "ya lo tienes" es la clave: si recorres para llegar al punto, ya pagaste O(n) y perdiste
el beneficio. En código de aplicación casi siempre se llega por índice o por búsqueda, así que
el caso favorable no se da.
🔬 Donde sí se da es dentro de otras estructuras: la lista de una caché LRU, donde el mapa te
entrega el nodo directamente; el encadenamiento de un bucket de tabla hash; la lista de bloques
libres de un asignador de memoria. Todos son estructuras internas, no modelos de dominio.

**02 → 23. Diseña la estructura para un ranking en vivo de los 10 mejores de un millón de jugadores, con actualizaciones constantes. Nombra TDA e implementación.**

⏱️ Un heap de tamaño 10 como TDA cola de prioridad, implementado con `PriorityQueue`, más un
`HashMap` de jugador a puntuación.
🗣️ El mapa mantiene la puntuación actual de cada jugador en O(1). Para el top 10 se mantiene un
**min-heap acotado a 10**: cada puntuación nueva se compara con la cabeza —el peor de los diez—
y solo entra si la supera, expulsando a la cabeza. Cada actualización cuesta O(log 10), que es
constante en la práctica.

```text
actualizar(jugador, puntos):
   mapa.put(jugador, puntos)
   si heap.size() < 10       → heap.offer(puntos)
   si no si puntos > heap.peek() → heap.poll(); heap.offer(puntos)
```

🔬 Lo que el entrevistador preguntará después: qué pasa si un jugador que ya está en el top
mejora su puntuación —hay que borrarlo del heap, y eso es O(n) en `PriorityQueue`—. La solución
real es un `TreeSet` ordenado por (puntuación, id) con borrado e inserción en O(log n), o
delegar en un sorted set de Redis, que es exactamente para esto. Ordenar el millón entero en
cada actualización, que es la primera respuesta de mucha gente, es O(n log n) por evento y no
aguanta.

**02 → 24. Te dan un método que recibe `ArrayList` en la firma y hace `remove(0)` dentro de un bucle. Explica el problema y propón dos arreglos distintos.**

⏱️ Dos problemas: la firma pide una clase en vez de una interfaz, y `remove(0)` es O(n), lo que
hace el bucle cuadrático.
🗣️ Cada `remove(0)` desplaza los n-1 elementos restantes una posición. Con 100 000 elementos son
5 000 millones de movimientos. Además, la firma `void procesar(ArrayList<Pedido> pedidos)`
impide pasar cualquier otra `List`, incluida una inmutable o la vista de un test.
🔬 Los dos arreglos, con distinto coste: **(a)** cambiar la estructura a `ArrayDeque` y usar
`poll()`, que es O(1) —lo correcto si de verdad es una cola—; **(b)** no borrar y recorrer con
un índice, procesando en orden y descartando la lista al final, que es O(n) y no necesita otra
estructura. La firma se cambia a `List<Pedido>` o a `Queue<Pedido>` en ambos casos.

**02 → 25. Diseña la estructura de un carrito de compras que necesita: orden de agregado, acceso por `ProductoId`, y total acumulado. Justifica cada elección.**

⏱️ Un `LinkedHashMap<ProductoId, LineaPedido>` y un total mantenido incrementalmente.
🗣️ El `LinkedHashMap` resuelve dos requisitos a la vez: acceso por clave en O(1) y orden de
inserción al iterar, que es lo que el usuario espera ver. Cada `LineaPedido` guarda cantidad y
precio; al agregar un producto que ya está, se incrementa la cantidad en vez de duplicar la
línea, que es lo que hace cualquier carrito real.

```text
Map<ProductoId, LineaPedido>  →  LinkedHashMap    acceso O(1) + orden de agregado
total                         →  Money acumulado  se actualiza al agregar y al quitar
```

🔬 Lo que preguntarán después: **si el total se recalcula o se mantiene**. Recalcular es O(n) y
siempre correcto; mantenerlo es O(1) y se desincroniza en cuanto alguien modifica una línea sin
pasar por el método. La respuesta defendible es mantenerlo **y** encapsular la mutación para que
no haya forma de saltárselo — que es la invariante de agregado de DDD aplicada a una estructura
de datos. Y si el carrito se persiste, el orden de inserción del mapa no sobrevive: hay que
guardar una posición explícita.

---

# 03 — Arrays, listas y secuencias

**03 → 1. ¿Por qué el acceso por índice en un arreglo es O(1)?**

⏱️ Porque el arreglo es un bloque contiguo y la dirección del elemento i se calcula:
`base + i × tamaño`.
🗣️ Es una operación aritmética, no una búsqueda: da igual si pides la posición 0 o la 999 999,
cuesta lo mismo. Eso exige dos cosas: que los elementos ocupen todos lo mismo y que estén
pegados en memoria.
🔬 Es también la razón de que insertar en medio sea O(n): mantener la contigüidad obliga a
desplazar todo lo que hay a la derecha.

**03 → 2. ¿Qué es una línea de caché y cuántos `int` caben en una?**

⏱️ El bloque mínimo que el procesador trae de memoria: 64 bytes en las arquitecturas actuales,
o sea 16 `int`.
🗣️ La CPU nunca lee un byte suelto. Cuando pides `datos[0]`, el hardware trae también los 15
enteros siguientes. Si tu recorrido es secuencial, 15 de cada 16 accesos ya están en caché y no
tocan la memoria principal.
🔬 De ahí sale el factor 5–10× entre arreglo y lista enlazada, que ninguna tabla de
complejidades refleja porque el modelo de O grande asume que todos los accesos valen lo mismo.

**03 → 3. ¿Qué complejidad tiene `add(0, x)` en un `ArrayList`?**

⏱️ O(n): hay que desplazar todos los elementos una posición a la derecha.
🗣️ Es la operación que el arreglo dinámico hace mal por diseño. Hacerlo dentro de un bucle n
veces da O(n²), que es un bug de rendimiento frecuente y silencioso.
🔬 Si necesitas insertar por el principio, la estructura correcta es `ArrayDeque` con
`addFirst`, que es O(1) amortizado.

**03 → 4. ¿Cuál es el requisito imprescindible de la técnica de dos punteros?**

⏱️ Que el arreglo esté **ordenado**.
🗣️ El invariante que la justifica es "si la suma es menor que el objetivo, ningún par con el
puntero izquierdo actual sirve", y eso solo es cierto si el derecho ya es el mayor disponible.
Sin orden, descartar una fila entera de candidatos no está justificado.
🔬 Si el arreglo no está ordenado y necesitas los índices originales, ordenar los destruye: ahí
la respuesta es un `HashSet` o un `HashMap` en una sola pasada, que es O(n) en tiempo y O(n) en
espacio.

**03 → 5. ¿Qué palabra en un enunciado delata una ventana deslizante?**

⏱️ "Contiguo". También "subcadena" y "subarreglo", que implican contigüidad.
🗣️ Si el subconjunto no tiene que ser contiguo, la ventana no aplica y el problema casi siempre
es de ordenación o de programación dinámica. La palabra vale por media solución.
🔬 El segundo requisito, menos visible, es que la condición sea **incremental**: que puedas
actualizarla al entrar y salir un elemento. "Suma ≤ límite" lo es; "la mediana de la ventana"
no, y por eso ese problema necesita dos heaps.

**03 → 6. ¿Por qué el arreglo de sumas de prefijos tiene n+1 posiciones?**

⏱️ Para que `prefijo[0] = 0` y la fórmula del rango funcione sin casos especiales.
🗣️ Con `prefijo[i]` = suma de los i primeros, la suma del rango `[a, b]` es `prefijo[b+1] -
prefijo[a]`, y eso es válido también cuando `a = 0`. Sin el cero inicial harías falta un `if (a
== 0)` en cada consulta.
🔬 Es el mismo truco del nodo centinela en una lista enlazada: una posición extra que elimina el
caso borde en vez de tratarlo.

**03 → 7. ¿Por qué un `ArrayList` crece multiplicando y no sumando?**

⏱️ Porque multiplicar da O(1) amortizado y sumar da O(n) amortizado.
🗣️ Con duplicación, las copias son cada vez más raras y el total tras n inserciones es ~2n
elementos copiados. Creciendo de diez en diez, hay n/10 redimensionados y cada uno copia hasta n
elementos: O(n²) total.
🔬 El factor concreto varía: Java usa ~1.5, Go duplica hasta 256 elementos, Python crece de
forma más suave (~1.125). Todos son multiplicativos y todos dan O(1) amortizado; lo que cambia
es cuánta memoria desperdician.

**03 → 8. ¿En qué se diferencia `int[]` de `List<Integer>` en memoria?**

⏱️ Un millón de `int` son 4 MB contiguos; un millón de `Integer` en una lista son unos 20 MB en
objetos dispersos.
🗣️ `List<Integer>` guarda referencias a objetos `Integer`, cada uno con su cabecera. Son dos
saltos de puntero por elemento y muchísima menos localidad. En un bucle caliente la diferencia
es de un orden de magnitud.
🔬 Java cachea los `Integer` de -128 a 127, así que con valores pequeños el coste baja. Es
también la razón de una trampa famosa: `==` entre dos `Integer` de 1000 es `false` y entre dos
de 100 es `true`.

**03 → 9. ¿Por qué dos punteros es O(n) si tiene un bucle con dos variables?**

⏱️ Porque en cada iteración se mueve un puntero y ninguno retrocede: como mucho n movimientos
en total.
🗣️ La forma correcta de contar no es "cuántas variables de bucle hay", sino cuántas veces se
ejecuta la línea más interna. Aquí la suma de los avances de ambos punteros está acotada por la
longitud del arreglo.
🔬 Es el mismo argumento que hace lineal a la pila monótona y a la ventana deslizante: cada
elemento se toca un número constante de veces en toda la ejecución.

**03 → 10. ¿Qué diferencia hay entre ventana de tamaño fijo y de tamaño variable?**

⏱️ La fija avanza los dos extremos a la vez; la variable avanza el derecho siempre y el
izquierdo solo mientras se viole la condición.
🗣️ La fija resuelve "suma máxima de k elementos consecutivos" y es la fácil. La variable
resuelve "la subcadena más larga que cumple X" y es donde está la dificultad real, porque hay
que mantener el estado de la ventana al contraerla.
🔬 Ambas son O(n) por el mismo argumento: cada elemento entra una vez y sale como mucho una vez.
El coste extra está en el espacio, que pasa de O(1) a O(k) si hay que llevar frecuencias.

**03 → 11. ¿Por qué las sumas de prefijos no sirven para consultas de máximo?**

⏱️ Porque el máximo no es invertible: no puedes "restar" el máximo de un prefijo del de otro.
🗣️ La técnica funciona con operaciones asociativas **y con inverso**: suma (resta), producto
(división, si no hay ceros), XOR (el propio XOR). El máximo es asociativo pero no invertible, así
que no hay forma de despejar el rango.
🔬 Para máximos de rango se usa una tabla dispersa (sparse table) si los datos no cambian, o un
segment tree si cambian. Ambos quedan fuera del alcance de este corpus, y decir su nombre es
suficiente en una entrevista de backend.

**03 → 12. ¿Qué se guarda en una pila monótona: valores o índices? ¿Por qué?**

⏱️ Índices, porque casi siempre necesitas la **distancia** entre posiciones, no solo el valor.
🗣️ "Cuántos días faltan hasta que suba la temperatura" pide `j - i`, y con el valor solo no
puedes calcularlo. Teniendo el índice, el valor se obtiene con un acceso al arreglo, así que
guardar índices no pierde nada.
🔬 Es el mismo criterio que en dos punteros y en la búsqueda binaria: trabajar con posiciones te
deja responder tanto "cuál" como "dónde".

**03 → 13. ¿Cuál es el único caso en que una lista enlazada gana de verdad?**

⏱️ Cuando insertas o borras en medio teniendo **ya el nodo** en la mano, muchas veces.
🗣️ Si tienes que recorrer para llegar al punto, ya pagaste O(n) y perdiste el beneficio. En
código de aplicación se llega casi siempre por índice o por búsqueda, así que el caso favorable
no se da.
🔬 Donde sí se da es dentro de otras estructuras: la lista de una caché LRU, el encadenamiento
de un bucket de tabla hash, la lista de bloques libres de un asignador. Nunca en el modelo de
dominio.

**03 → 14. ¿Qué pico de memoria tiene el redimensionado de un `ArrayList` de 8 GB?**

⏱️ Unos 20 GB: durante la copia coexisten el arreglo viejo y el nuevo, que es ~1.5 veces mayor.
🗣️ El viejo no se puede liberar hasta que la copia termine, así que el pico es viejo + nuevo. Con
factor 1.5, son 8 + 12 = 20 GB de pico para una estructura que "ocupa" 8.
🔬 Es la razón por la que preasignar capacidad no es micro-optimización cuando las estructuras
son grandes: `new ArrayList<>(tamañoEsperado)` elimina el pico y todos los redimensionados
intermedios.

**03 → 15. ¿Por qué `list.pop(0)` en Python es O(n) y `deque.popleft()` es O(1)?**

⏱️ Porque `list` es un arreglo dinámico y `deque` es una lista doblemente enlazada de bloques.
🗣️ Quitar el primer elemento de un arreglo obliga a desplazar el resto; en un deque solo hay que
mover un puntero. La documentación de `collections` lo advierte explícitamente.
🔬 El `deque` de Python no es una lista enlazada nodo a nodo: usa bloques de 64 elementos, lo que
le da buena localidad de caché además de las operaciones O(1) en los extremos. Es un diseño más
inteligente que la `LinkedList` de Java.

**03 → 16. ¿Por qué la pila monótona es O(n) si tiene un `while` dentro de un `for`?**

⏱️ Porque cada elemento entra en la pila exactamente una vez y sale como mucho una vez: 2n
operaciones en total.
🗣️ El `while` interno puede desapilar muchos elementos en una iteración concreta, pero esos
elementos ya no volverán a estar. El trabajo total está acotado por el número de entradas, no
por el producto de los dos bucles.
🔬 Es un análisis amortizado, igual que el del `ArrayList`: la operación cara es rara y se paga
con las baratas que la precedieron. Reconocer que es amortizado y decirlo así es lo que
distingue la respuesta.

**03 → 17. ¿Por qué `LinkedList` pierde contra `ArrayList` incluso donde la tabla dice que gana?**

⏱️ Por la localidad de caché y por la sobrecarga de objeto: cada nodo es un salto impredecible y
tres objetos por valor.
🗣️ La tabla dice que insertar en medio es O(1) contra O(n), pero llegar al punto de inserción
es O(n) en la lista y el desplazamiento del arreglo es una copia de bloque contigua que el
hardware hace a enorme velocidad. En la práctica el arreglo gana hasta tamaños sorprendentes.
🔬 El propio autor de las colecciones de Java ha dicho públicamente que `LinkedList` casi nunca
es la elección correcta. Si la propones en una entrevista, más vale que el caso sea el de la
pregunta 13.

**03 → 18. En Go, `b := a[1:3]` y luego `b[0] = 99`. ¿Qué le pasa a `a` y por qué?**

⏱️ `a[1]` pasa a valer 99: el slice no copia, comparte el arreglo de respaldo.
🗣️ Un slice de Go es un trío puntero-longitud-capacidad sobre un arreglo subyacente. Cortarlo
crea una vista nueva sobre la misma memoria, así que escribir por una se ve por la otra.
🔬 Lo que lo hace peligroso de verdad es `append`: si hay capacidad sobrante, escribe en el
arreglo compartido y afecta al original; si no la hay, reasigna y deja de compartir. El mismo
código, por tanto, a veces comparte y a veces no, según el estado. La solución explícita es
`slices.Clone`.

**03 → 19. ¿Por qué una cola implementada con `push`/`shift` en JavaScript es cuadrática?**

⏱️ Porque `shift()` es O(n): reindexa todo el arreglo. Hacerlo n veces da O(n²).
🗣️ Un `Array` de JavaScript es indexado, así que quitar la posición 0 mueve todo un lugar.
Procesar un millón de eventos así se arrastra, y el bug no se ve en pruebas porque los motores
optimizan `shift` para arreglos pequeños.
🔬 La salida sin bibliotecas es mantener un índice de cabeza y no borrar nunca, compactando cuando
la parte consumida pase de la mitad. Eso da O(1) amortizado a costa de memoria transitoria.

**03 → 20. Tienes un millón de consultas de suma de rango sobre un arreglo que cambia cada mil consultas. ¿Sigue conviniendo el prefijo? Justifica.**

⏱️ Sí, holgadamente: 1 000 reconstrucciones de O(n) contra un millón de consultas de O(1).
🗣️ El cálculo es directo: reconstruir cuesta O(n) y ocurre mil veces, o sea 1 000·n; las
consultas cuestan O(1) y son un millón. Frente a la alternativa de recorrer en cada consulta
—1 000 000·n—, el prefijo gana por tres órdenes de magnitud.
🔬 El umbral está donde el número de actualizaciones se acerca al de consultas. Si fuera una
actualización por consulta, el prefijo pierde y la respuesta correcta es un Fenwick tree (BIT),
que da actualización y consulta en O(log n). Nombrarlo aunque no lo implementes es la respuesta
completa.

**03 → 21. ¿Cómo detectas un ciclo en una lista enlazada con O(1) de memoria?**

⏱️ Con dos punteros a distinta velocidad: uno avanza de uno y otro de dos. Si hay ciclo, se
encuentran.
🗣️ Es el algoritmo de la liebre y la tortuga de Floyd. Si no hay ciclo, el rápido llega al final
y termina. Si lo hay, el rápido entra en el ciclo y acaba alcanzando al lento, porque la
distancia entre ambos se reduce en uno por iteración.
🔬 La segunda parte del problema —encontrar **dónde** empieza el ciclo— tiene una solución
bonita: cuando se encuentran, mueves uno de los punteros al inicio y avanzas ambos de uno en
uno; se vuelven a encontrar exactamente en el nodo de entrada al ciclo. La alternativa obvia,
un `HashSet` de nodos visitados, resuelve lo mismo en O(n) de memoria.

**03 → 22. `readonly T[]` en TypeScript, ¿congela el arreglo en runtime? ¿Qué garantiza entonces?**

⏱️ No congela nada: es una garantía **de compilación**. En runtime el arreglo sigue siendo
mutable.
🗣️ TypeScript se borra al compilar: `readonly` y `ReadonlyArray<T>` impiden que **tu código
tipado** llame a `push` o asigne por índice, pero cualquier JavaScript sin tipos, un `as any` o
un dato que venga de la red pueden mutarlo igual.
🔬 La inmutabilidad real en runtime la da `Object.freeze()`, que es superficial —congela el
arreglo, no los objetos dentro— y tiene coste. Es el mismo malentendido que `final` en Java:
`final List` impide reasignar la variable, no modificar la lista. La demostración, comprobada con
`tsc --strict` y con Node 24:

```text
datos.push(7)             → error TS2339: Property 'push' does not exist on type 'readonly number[]'
datos[0] = 99             → error TS2542: Index signature in type 'readonly number[]' only permits reading
(datos as number[]).push(7)  → tsc lo acepta, y en runtime el arreglo pasa a [5,2,9,1,5,6,7]
Object.freeze([...]).push(7) → TypeError: Cannot add property 3, object is not extensible
```

Las dos primeras líneas son la garantía de compilación; la tercera es lo que la anula con un solo
`as`; la cuarta es la única que actúa de verdad en ejecución.

**03 → 23. Escribe la ventana deslizante de tamaño variable para "la subcadena más larga sin caracteres repetidos" y di su complejidad en tiempo y espacio.**

⏱️ O(n) en tiempo y O(k) en espacio, con k el tamaño del alfabeto.
🗣️ El extremo derecho avanza siempre; cuando el carácter que entra ya está en la ventana, el
izquierdo avanza hasta expulsarlo. Un mapa de carácter a última posición permite saltar el
izquierdo de golpe en vez de uno a uno.

```java
Map<Character, Integer> ultimaPos = new HashMap<>();
int izq = 0, mejor = 0;
for (int der = 0; der < texto.length(); der++) {
    char c = texto.charAt(der);
    Integer visto = ultimaPos.get(c);
    if (visto != null && visto >= izq) izq = visto + 1;  // salta, no avanza de uno en uno
    ultimaPos.put(c, der);
    mejor = Math.max(mejor, der - izq + 1);
}
```

🔬 El `visto >= izq` es el detalle que casi todo el mundo olvida: sin él, un carácter repetido
que quedó **fuera** de la ventana actual haría retroceder el extremo izquierdo, y el algoritmo
devuelve resultados menores de los correctos. Casos borde: cadena vacía (devuelve 0), un solo
carácter (1), todos iguales (1). Sobre `"abracadabra"` la respuesta es 4, por `"brac"`.

**03 → 24. Te dan un bucle que hace `lista.remove(0)` n veces sobre un `ArrayList`. Explica la complejidad real y da dos arreglos con distinto coste.**

⏱️ Es O(n²): cada `remove(0)` desplaza los n-1 restantes.
🗣️ Con 100 000 elementos son unos 5 000 millones de movimientos de memoria. El síntoma típico es
un proceso que va bien en pruebas con cien elementos y se arrastra en producción.
🔬 Los dos arreglos, con coste distinto: **(a)** cambiar a `ArrayDeque` y usar `poll()`, O(1)
por operación, que es lo correcto si la semántica es realmente de cola —el cambio es de una
línea si la firma declaraba `List` y pasa a `Queue`—; **(b)** no borrar en absoluto y recorrer
con un índice, descartando la colección al final, que es O(n) y no introduce otra estructura.
La (b) es preferible si nadie más observa la lista mientras se consume; la (a), si el consumo es
concurrente o incremental.

**03 → 25. Diseña la solución para "cuántos días faltan hasta que la temperatura suba" sobre un año de datos, y traza tu algoritmo sobre `[5, 2, 9, 1, 5, 6]`.**

⏱️ Pila monótona decreciente de índices, un recorrido, O(n) en tiempo y O(n) en espacio.
🗣️ Recorres de izquierda a derecha. Mientras la temperatura actual sea mayor que la del índice
en la cima de la pila, ese día ya tiene respuesta: `actual - índiceCima`. Se desapila y se
repite. Después se apila el índice actual.

```text
[5, 2, 9, 1, 5, 6]
i=0 (5) → pila [0]
i=1 (2) → 2<5, pila [0,1]
i=2 (9) → 9>2: resp[1]=2-1=1, desapila; 9>5: resp[0]=2-0=2, desapila; pila [2]
i=3 (1) → pila [2,3]
i=4 (5) → 5>1: resp[3]=4-3=1; pila [2,4]
i=5 (6) → 6>5: resp[4]=5-4=1; pila [2,5]
fin     → 9 y 6 sin respuesta → 0

resultado: [2, 1, 0, 1, 1, 0]
```

🔬 Con 365 datos, la fuerza bruta O(n²) son 133 000 operaciones y también vale: decirlo es
honesto y demuestra criterio. La pila monótona se justifica cuando n crece —lecturas horarias de
diez años son 87 600 puntos— o cuando el entrevistador pide explícitamente mejor que cuadrático.
Casos borde: arreglo vacío, todos iguales (todo ceros, porque "mayor" es estricto) y
estrictamente decreciente (todo ceros también).

---

# 04 — Recursión y backtracking

**04 → 1. ¿Cuáles son las tres piezas obligatorias de una función recursiva?**

⏱️ Caso base alcanzable, paso recursivo sobre un problema estrictamente menor, y confiar en que
la llamada devuelve lo correcto.
🗣️ El caso base es lo que hace que termine; el decrecimiento es lo que garantiza que se llega a
él; y el "salto de fe" es la disciplina mental de no intentar desplegar los niveles en la
cabeza, que es lo que hace que la recursión parezca difícil.
🔬 Una recursión sin caso base alcanzable no se cuelga: lanza `StackOverflowError` en
milisegundos. Y "menor" tiene que ser menor **hacia el caso base**: `factorial(n-1)` con n
negativo decrece y nunca llega.

**04 → 2. ¿Qué es un marco de pila y qué guarda?**

⏱️ El bloque que ocupa una llamada en curso: sus parámetros, sus variables locales y la
dirección de retorno.
🗣️ Los marcos se apilan al llamar y se desapilan al retornar. Es el TDA pila implementado por la
máquina, y su tamaño total es lo que limita la profundidad de recursión.
🔬 Cuántos caben depende de cuántas locales tenga cada marco: una función con veinte variables
agota la pila mucho antes que una con dos. Por eso el límite práctico de la JVM se da como un
rango, 10 000–20 000, y no como un número.

**04 → 3. ¿Qué complejidad en espacio tiene una recursión de profundidad n?**

⏱️ O(n), por la pila de llamadas.
🗣️ Es el espacio que nadie cuenta porque no lo reservas tú. Responder "O(1) de espacio" sobre un
algoritmo recursivo es un fallo objetivo, no un matiz, y es justo lo que el entrevistador quería
comprobar al preguntar por el espacio.
🔬 Si cada marco guarda además estructuras —una lista parcial en backtracking— el espacio es
O(profundidad × tamaño del marco), que puede ser bastante más.

**04 → 4. ¿Qué complejidad tiene el Fibonacci recursivo sin memoización?**

⏱️ O(2ⁿ) en tiempo, O(n) en espacio.
🗣️ Cada llamada genera dos, y el árbol de llamadas tiene profundidad n: son del orden de 2ⁿ
nodos. `fib(40)` hace más de dos mil millones de llamadas, y casi todas recalculan algo ya
calculado.
🔬 El espacio es solo O(n) porque en cada momento hay un único camino de la raíz a una hoja
abierto: el árbol es ancho en el tiempo, no en la pila. Es una disociación que se pregunta y que
mucha gente falla.

**04 → 5. ¿Cuáles son los tres pasos del esqueleto de backtracking?**

⏱️ Elegir, explorar, deshacer.
🗣️ Se aplica una opción al estado, se recursa, y se revierte para que la siguiente rama parta de
un estado limpio. Alrededor van la condición de solución y la poda de viabilidad.
🔬 El `deshacer` es el paso que todos olvidan y produce soluciones contaminadas entre ramas. Hay
una variante que lo evita: pasar estado **inmutable** en cada llamada, a costa de copiar y de
más asignaciones.

**04 → 6. ¿Qué significa que una recursión sea "de cola"?**

⏱️ Que la llamada recursiva es la **última** operación: no queda nada pendiente con su
resultado.
🗣️ `return n * factorial(n-1)` no es de cola, porque hay una multiplicación esperando. `return
factorial(n-1, n*acumulado)` sí lo es: el acumulado viaja como parámetro y el marco actual ya no
hace falta.
🔬 Un compilador con optimización de llamada de cola reutiliza el marco y la convierte en un
bucle: O(1) de pila. Scala lo hace con `@tailrec` y Kotlin con `tailrec`.

**04 → 7. ¿Por qué la JVM no elimina la recursión de cola?**

⏱️ Porque el modelo de seguridad y las trazas de excepción dependen de que los marcos estén
ahí.
🗣️ La inspección de la pila se usa históricamente para decidir permisos, y una traza de
excepción con marcos elididos sería incompleta para depurar. Se ha discutido repetidamente en
OpenJDK y sigue sin implementarse en Java 21.
🔬 La consecuencia práctica es que en Java escribir la versión de cola **no ahorra un solo
byte**: es una transformación estilística. Si el problema es la profundidad, la única salida es
convertirla en iteración con un bucle o con una pila explícita.

**04 → 8. ¿En qué se diferencian divide y vencerás y programación dinámica?**

⏱️ En si los subproblemas se solapan: si son independientes, es divide y vencerás; si se
repiten, es DP.
🗣️ Merge sort parte el arreglo en dos mitades que no comparten nada, así que resolverlas por
separado no repite trabajo. Fibonacci recursivo parte en `n-1` y `n-2`, que comparten casi todo,
y por eso explota exponencialmente hasta que memoizas.
🔬 La DP es, en ese sentido, divide y vencerás más una tabla. Y al revés: si aplicas memoización
a un divide y vencerás con subproblemas independientes, la tabla nunca acierta y solo gastas
memoria.

**04 → 9. ¿Dónde hace el trabajo merge sort y dónde lo hace quicksort?**

⏱️ Merge sort trabaja al **combinar**; quicksort trabaja al **dividir**.
🗣️ Merge sort parte por la mitad sin mirar los datos —trivial— y la fusión ordenada es donde
está el O(n) de cada nivel. Quicksort hace la partición alrededor del pivote —ahí está el
O(n)— y después no tiene que combinar nada, porque las partes ya quedan en su sitio.
🔬 De esa asimetría salen sus propiedades: merge sort es estable y necesita O(n) auxiliar;
quicksort es in-place y su peor caso depende de la elección del pivote. Se desarrolla entero en
`03-orden-busqueda/01`.

**04 → 10. ¿Qué diferencia hay entre memoización y tabulación?**

⏱️ La memoización es descendente y perezosa; la tabulación es ascendente y calcula todo.
🗣️ Memoizar es escribir la recursión natural y guardar resultados en un mapa: solo se calculan
los subproblemas que hacen falta, pero se paga pila. Tabular es llenar un arreglo desde los
casos base hacia arriba: no hay pila, pero se calculan todos los estados aunque no se usen.
🔬 La tabulación permite además la optimización de espacio: si el estado i solo depende de i-1 e
i-2, basta con dos variables y el espacio baja de O(n) a O(1). Con memoización eso no se puede
hacer.

**04 → 11. ¿Cuántos niveles de recursión permite Python por defecto, y qué lanza al pasarse?**

⏱️ Mil, y lanza `RecursionError`.
🗣️ Es un límite del intérprete, no de la memoria: `sys.setrecursionlimit` lo sube. Python eligió
un tope bajo a propósito, para fallar pronto y con un mensaje claro en vez de agotar la pila
real del sistema operativo.
🔬 Subirlo mucho es peligroso: si el límite supera la pila real del hilo, el intérprete se cae
con una violación de segmento en vez de con una excepción. En Java el límite es de decenas de
miles y el error es `StackOverflowError`, que es un `Error` y no una `Exception` — no se captura
como parte del flujo normal.

**04 → 12. ¿Por qué el `deshacer` del backtracking no es opcional?**

⏱️ Porque sin él el estado se contamina entre ramas y las soluciones salen mezcladas.
🗣️ El estado es compartido entre todas las ramas de la exploración. Si eliges una opción,
recursas y no la revocas, la siguiente iteración del bucle parte de un estado sucio y explora
combinaciones que no existen.
🔬 La alternativa es no mutar: crear un estado nuevo en cada llamada. Es más fácil de razonar y
cuesta asignaciones, lo que en Java importa en bucles calientes y en Python casi no se nota.

**04 → 13. ¿Qué complejidad en espacio tiene una recursión sobre un árbol equilibrado? ¿Y sobre uno degenerado?**

⏱️ O(log n) en el equilibrado, O(n) en el degenerado.
🗣️ El espacio de una recursión sobre un árbol es su **altura**, no su número de nodos. Un árbol
equilibrado tiene altura log n; uno degenerado —insertando claves ya ordenadas en un BST sin
balanceo— es una lista enlazada disfrazada y su altura es n.
🔬 De ahí que el recorrido recursivo de un BST sin balanceo sobre un millón de claves ordenadas
desborde la pila, mientras que el mismo recorrido sobre un `TreeMap` no lo haga nunca: el árbol
rojo-negro garantiza altura logarítmica.

**04 → 14. ¿Por qué hay que añadir una **copia** del estado a la lista de soluciones?**

⏱️ Porque el estado se sigue mutando después: si añades la referencia, todas las soluciones
apuntan al mismo objeto.
🗣️ El síntoma clásico es una lista de resultados donde todos los elementos son iguales, y
normalmente vacíos, porque al terminar la exploración el estado volvió a su valor inicial por
efecto del `deshacer`.
🔬 En Java es `new ArrayList<>(actual)`; en Python, `list(actual)` o `actual[:]`. Y ojo con que
la copia es **superficial**: si el estado contiene objetos mutables, hay que copiar en
profundidad o el bug reaparece un nivel más abajo.

**04 → 15. ¿Qué efecto tiene la poda sobre la complejidad asintótica del backtracking?**

⏱️ Ninguno sobre la cota: sigue siendo exponencial. Cambia la constante, y la cambia tanto que
decide si termina.
🗣️ En N reinas con n=8, sin poda se exploran unos 16 millones de tableros; con poda por columna y
diagonal, unos 15 000. Son tres órdenes de magnitud sin mover la O.
🔬 Es un buen ejemplo de que la complejidad asintótica no es la única métrica que importa.
Decirlo así —*"la poda no baja la cota, pero es lo que hace que termine hoy"*— es la respuesta
completa.

**04 → 16. Te dan un `StackOverflowError` en producción con 20 000 líneas idénticas de traza. ¿Cuál es tu primera hipótesis y por qué no es subir `-Xss`?**

⏱️ Un ciclo en los datos. Subir `-Xss` retrasa el fallo sin arreglarlo.
🗣️ Una recursión correcta sobre datos correctos rara vez pasa de unos cientos de niveles: un
árbol de categorías con veinte mil de profundidad no es un árbol, es un ciclo o una cadena
corrupta. El patrón de traza —los mismos dos o tres métodos repetidos— lo confirma.
🔬 La secuencia de diagnóstico: mirar la traza para identificar el ciclo de métodos, reproducir
con los datos del incidente, y añadir detección de ciclos con un conjunto de visitados o un
límite de profundidad explícito. La corrección de fondo es validar al insertar, para que la
referencia circular no llegue a existir.

**04 → 17. ¿Por qué `computeIfAbsent` con una llamada recursiva dentro falla en Java 9+?**

⏱️ Porque la función de mapeo modifica el mapa mientras `computeIfAbsent` lo está recorriendo:
lanza `ConcurrentModificationException`.
🗣️ `HashMap` detecta desde Java 9 la modificación reentrante durante `compute`, `merge` y
`computeIfAbsent`. Antes no lo detectaba y el resultado era peor: corrupción silenciosa de la
estructura interna, incluidos bucles infinitos en un bucket.
🔬 La versión correcta separa lectura y escritura: `Long v = cache.get(n); if (v != null) return
v; long r = fib(n-1) + fib(n-2); cache.put(n, r); return r;`. En Python el decorador
`@functools.cache` hace lo mismo sin este problema porque gestiona el diccionario fuera de la
llamada.

**04 → 18. ¿Por qué Go puede recursar mucho más profundo que Java?**

⏱️ Porque las pilas de las goroutines **crecen**: empiezan en unos pocos KB y el runtime las
reasigna hasta el límite configurado, del orden de 1 GB.
🗣️ En la JVM la pila de un hilo se reserva al crearlo y es fija. En Go, cuando una goroutine
necesita más, el runtime asigna una pila mayor y copia la existente, ajustando los punteros.
Eso permite tener millones de goroutines baratas y recursiones muy profundas.
🔬 El precio es que el compilador inserta una comprobación de crecimiento en cada llamada, y que
la copia invalida punteros a variables de pila —por eso Go no permite aritmética de punteros
libre—. Cuando se agota el límite, el mensaje es `goroutine stack exceeds limit`.

**04 → 19. Escribir `factorial` en versión de cola en Java, ¿ahorra memoria? Justifica.**

⏱️ No. La JVM no elimina la recursión de cola, así que consume exactamente la misma pila.
🗣️ La forma de cola es una condición **necesaria** para que un compilador pueda reutilizar el
marco, pero no suficiente: hace falta que el compilador lo implemente. Java no lo hace, ni en la
versión 21.
🔬 La respuesta cara añade dónde sí funciona: Scala con `@tailrec` —que además falla la
compilación si la función no es realmente de cola— y Kotlin con `tailrec`. Y cierra con lo que
sí sirve en Java: reescribirlo como bucle, que es trivial en este caso.

**04 → 20. ¿Cuándo convertirías una recursión en iteración con pila explícita en vez de en un bucle simple?**

⏱️ Cuando necesitas conservar el **orden de un recorrido en profundidad** y la recursión no es
lineal.
🗣️ Una recursión lineal —`f(n-1)`— se convierte en un bucle directamente. Una recursión que se
ramifica —recorrer un árbol o un grafo— necesita recordar dónde volver, y eso es exactamente una
pila. Un `ArrayDeque` la implementa.
🔬 El detalle que muerde: al pasar de recursivo a pila explícita, **el orden de los hijos se
invierte**, porque el último que apilas es el primero que sacas. Si el orden importa, hay que
apilarlos al revés. Es la pregunta 25 de este capítulo.

**04 → 21. La memoización cuesta O(n) de espacio en el mapa. ¿Cuánto cuesta en total contando la pila, y cómo lo bajas a O(1)?**

⏱️ O(n) de mapa más O(n) de pila: dos veces O(n). Se baja a O(1) con tabulación y ventana
deslizante de estados.
🗣️ La versión descendente memoizada llega hasta el caso base antes de empezar a devolver, así
que la pila alcanza profundidad n. La versión ascendente llena un arreglo con un bucle: sin
pila, O(n) de tabla. Y si cada estado solo depende de los dos anteriores, dos variables bastan.

```java
long anterior = 0, actual = 1;
for (int i = 2; i <= n; i++) { long siguiente = anterior + actual; anterior = actual; actual = siguiente; }
```

🔬 Esa reducción de espacio es la ventaja estructural de la tabulación sobre la memoización, y
se generaliza: en la mochila 0/1, recorrer la capacidad al revés permite usar un solo arreglo en
vez de una matriz. Se desarrolla en `05-dp-y-tecnicas/01`.

**04 → 22. En JavaScript, ¿existe la optimización de llamada de cola? Responde con matiz.**

⏱️ Está en la especificación desde ES6 y prácticamente ningún motor la implementa. En la
práctica, no.
🗣️ V8 —Chrome y Node— la implementó tras una bandera y la retiró, por el impacto en las trazas
de depuración. Safari (JavaScriptCore) es el único motor importante que la tiene activa.
Escribir recursión de cola confiando en ella es, por tanto, un error de portabilidad.
🔬 Es un buen ejemplo de que "está en el estándar" y "funciona" son cosas distintas, y de que la
respuesta correcta a una pregunta de lenguaje a veces es "depende del motor". El error al
pasarse es `RangeError: Maximum call stack size exceeded`.

**04 → 23. Escribe el backtracking que genera todos los subconjuntos de un conjunto de n elementos y di su complejidad en tiempo y espacio.**

⏱️ O(2ⁿ) subconjuntos por O(n) de copiar cada uno: O(n·2ⁿ) en tiempo, O(n) de pila más la
salida.
🗣️ En cada posición hay dos decisiones: incluir el elemento o no. El árbol de decisión tiene 2ⁿ
hojas y cada una produce un subconjunto.

```java
void explorar(int i, List<Producto> actual, List<List<Producto>> resultado) {
    if (i == productos.size()) { resultado.add(new ArrayList<>(actual)); return; }  // copia
    explorar(i + 1, actual, resultado);              // no incluir
    actual.add(productos.get(i));
    explorar(i + 1, actual, resultado);              // incluir
    actual.remove(actual.size() - 1);                // deshacer
}
```

🔬 Los dos detalles que se preguntan: la **copia** al añadir al resultado, sin la cual todas las
soluciones son la misma lista vacía; y el hecho de que el espacio de la **salida** es O(n·2ⁿ) y
domina al de la pila, que es solo O(n). Con n=20 son un millón de subconjuntos; con n=30, mil
millones y ya no cabe en memoria. La alternativa sin recursión es iterar de 0 a 2ⁿ-1 y usar los
bits del contador como máscara de inclusión.

**04 → 24. Te dan un recorrido recursivo de un árbol de categorías que falla en producción y no en test. Da tres hipótesis en orden de probabilidad.**

⏱️ Ciclo en los datos reales; profundidad legítima mayor que en los datos de prueba; o pila del
hilo menor en producción que en desarrollo.
🗣️ La primera es la más probable: un proceso de importación que permitió que una categoría fuera
descendiente de sí misma. La segunda se distingue porque la traza no muestra un ciclo corto de
métodos, sino una bajada real. La tercera aparece cuando el código corre en un hilo de un pool
—servidor de aplicaciones, `ForkJoinPool`— configurado con pila más pequeña que el hilo
principal.
🔬 Cuarta hipótesis, menos probable: la recursión es correcta pero se ejecuta dentro de otra,
como un serializador JSON que recursa sobre la estructura que tu método ya recursó. La
comprobación barata para las tres primeras es registrar la profundidad máxima alcanzada y
comparar entornos. La corrección de fondo, en todos los casos, es acotar la profundidad
explícitamente y validar los ciclos al insertar.

**04 → 25. Convierte el recorrido en profundidad recursivo de un árbol binario a iterativo, y di qué estructura usas y por qué el orden sale al revés si no tienes cuidado.**

⏱️ Una pila (`ArrayDeque`). El orden se invierte porque lo último que apilas es lo primero que
sacas, así que hay que apilar el hijo derecho antes que el izquierdo.
🗣️ La versión recursiva visita la raíz, después el izquierdo y después el derecho. Para
reproducirlo con una pila explícita, se apila la raíz y en cada paso se saca un nodo, se visita,
y se apilan sus hijos **derecho primero**: así el izquierdo queda arriba y se procesa antes.

```java
Deque<Nodo> pila = new ArrayDeque<>();
pila.push(raiz);
while (!pila.isEmpty()) {
    Nodo actual = pila.pop();
    visitar(actual);
    if (actual.derecho != null) pila.push(actual.derecho);   // derecho PRIMERO
    if (actual.izquierdo != null) pila.push(actual.izquierdo);
}
```

🔬 Esto vale para el recorrido en **preorden**. El inorden iterativo es notablemente más
difícil: hay que bajar por la izquierda apilando, y al desapilar visitar y saltar al hijo
derecho. El postorden iterativo es aún peor y suele resolverse con dos pilas, o haciendo el
preorden invertido y dando la vuelta al resultado. Si te piden "iterativo" sin decir cuál, di
que preorden es el fácil y pregunta cuál quieren: la pregunta en sí puntúa. Y si cambias la pila
por una cola, ya no es recorrido en profundidad: es BFS, y está en
`04-arboles-grafos/03`.

---

# 05 — Bits y aritmética binaria

**05 → 1. ¿Por qué el rango de un `int` es asimétrico?**

⏱️ Porque hay 2³² combinaciones y el cero ocupa una del lado positivo: queda un valor más en el
negativo.
🗣️ El rango es [-2 147 483 648, 2 147 483 647]. La consecuencia es que **`MIN_VALUE` no tiene
opuesto representable**, y de ahí salen todos los casos raros de este capítulo.
🔬 Es una propiedad del complemento a dos, no de Java: Go, C y C# tienen exactamente la misma
asimetría. La alternativa histórica —magnitud con signo— tenía dos ceros y aritmética más cara.

**05 → 2. ¿Qué devuelve `Math.abs(Integer.MIN_VALUE)`?**

⏱️ `-2147483648`. El valor absoluto de un número es **negativo**.
🗣️ No es un bug: negar `MIN_VALUE` requiere un valor que no existe en el rango, así que la operación
da la vuelta y devuelve el mismo número. Está documentado en la API de `Math`.
🔬 La consecuencia práctica es el bug latente de la pregunta 14: `Math.abs(hash) % n` puede devolver
un índice negativo. La forma correcta de normalizar es enmascarar el bit de signo:
`hash & 0x7fffffff`.

**05 → 3. ¿Qué diferencia hay entre `>>` y `>>>`?**

⏱️ `>>` es aritmético y conserva el signo; `>>>` es lógico y rellena con ceros.
🗣️ Verificado: `-8 >> 1` es `-4`, y `-8 >>> 1` es `2147483644`. Con números positivos ambos hacen lo
mismo; la diferencia solo se ve con el bit de signo activo.
🔬 `>>>` existe en Java y JavaScript **porque ninguno tiene enteros sin signo**. Go y Python no lo
tienen: en Go el desplazamiento lógico sale de usar `uint32`, que es más explícito.

**05 → 4. ¿Cómo se comprueba que un número es potencia de dos?**

⏱️ `n & (n - 1) == 0`, con `n > 0`.
🗣️ Restar uno a una potencia de dos apaga su único bit activo y enciende todos los de debajo, así
que el AND se anula. Verificado: `16 & 15` es 0 y `12 & 11` es 8.
🔬 Es la comprobación que hace un `HashMap` al dimensionar su capacidad, y la razón de que pueda
usar `hash & (n-1)` en lugar del módulo. El caso borde: con `n = 0` la fórmula dice "sí" y hay que
excluirlo aparte.

**05 → 5. ¿Qué pasa en Java cuando una suma de enteros desborda?**

⏱️ Da la vuelta **en silencio**: `Integer.MAX_VALUE + 1` es `Integer.MIN_VALUE`.
🗣️ No hay excepción ni aviso. Es el comportamiento definido por la especificación, y es el mismo en
Go. Para que avise hay que pedirlo: `Math.addExact` lanza `ArithmeticException: integer overflow`.
🔬 De aquí salen dos bugs que ya aparecen en este corpus: el `(lo + hi) / 2` de la búsqueda binaria
y el `a - b` del comparador. Ambos son la misma causa con dos síntomas distintos.

**05 → 6. ¿Qué es una máscara de bits y qué operaciones la definen?**

⏱️ Un entero donde cada bit representa la pertenencia de un elemento. Unión con `|`, intersección
con `&`, pertenencia con `& != 0`, y quitar con `& ~`.
🗣️ Un `long` almacena un conjunto de hasta 64 elementos en 8 bytes, con todas las operaciones de
conjunto en una sola instrucción. Ninguna estructura se le acerca en coste.
🔬 Su límite es el tamaño —64 elementos en un `long`— y su problema es la legibilidad: nadie sabe qué
significa el bit 5 dos años después. Por eso en código de dominio se usa `EnumSet`.

**05 → 7. ¿Por qué `EnumSet` es preferible a un `int` de banderas?**

⏱️ Porque **es** una máscara de bits por dentro, con la misma velocidad, pero con nombres, tipos y
la API de un `Set`.
🗣️ Cuando el enum tiene 64 valores o menos, `EnumSet` usa un único `long` internamente. Obtienes
seguridad de tipos, un `toString` legible y la imposibilidad de mezclar dos conjuntos de banderas
distintos, que con `int` es un error silencioso.
🔬 Es el ítem 36 de *Effective Java*. La regla práctica: máscara explícita solo cuando el **formato
externo** te obliga —un protocolo, un archivo binario—; en todo lo demás, `EnumSet`.

**05 → 8. ¿Por qué en Python no hace falta preocuparse por el desbordamiento?**

⏱️ Porque sus enteros son de **precisión arbitraria**: crecen mientras quepan en memoria.
🗣️ `2**200` se calcula sin problema y sin pérdida. Es una decisión deliberada de diseño que elimina
toda una clase de bugs.
🔬 No es gratis: un entero de Python es un objeto con cabecera y un arreglo de dígitos, no una
palabra de máquina, así que la aritmética es órdenes de magnitud más lenta y ocupa mucho más. Es el
compromiso que el lenguaje eligió a propósito.

**05 → 9. ¿Por qué Go no tiene `>>>`?**

⏱️ Porque **sí tiene enteros sin signo**, y el desplazamiento lógico sale de usar `uint32`.
🗣️ En Java, `>>>` existe precisamente porque el lenguaje no tiene tipos sin signo —salvo `char`— y
hacía falta una forma de desplazar sin propagar el bit de signo. Go resuelve la misma necesidad en
el sistema de tipos en vez de en la sintaxis.
🔬 Es un buen ejemplo para una conversación de diseño de lenguajes: la misma necesidad, un operador
más en un caso y un tipo más en el otro. La versión de Go es más explícita porque el tipo declara la
intención.

**05 → 10. ¿Qué devuelve `5 ^ 3 ^ 5` y por qué?**

⏱️ `3`, porque `x ^ x == 0` y el XOR es conmutativo y asociativo.
🗣️ Los dos cincos se cancelan entre sí independientemente de su posición, y queda el que no tiene
pareja. De ahí el algoritmo para encontrar el único elemento no repetido de una secuencia: O(n) en
tiempo y **O(1) en espacio**.
🔬 El uso real no es el acertijo: es la paridad. Un RAID 5 reconstruye el contenido de un disco
perdido aplicando XOR al resto, por exactamente esta propiedad.

**05 → 11. ¿Por qué `hash & (n - 1)` puede sustituir al módulo, y con qué condición?**

⏱️ Con la condición de que `n` sea **potencia de dos**. Entonces `n - 1` es una máscara de unos y el
AND se queda con los bits bajos, que es justo el resto.
🗣️ El AND es una instrucción y la división es varias, así que la diferencia es medible en un camino
caliente. Es lo que hace `HashMap`, y la razón de que su capacidad sea siempre potencia de dos.
🔬 El efecto secundario es que **solo influyen los bits bajos** del hash, así que dos claves que
difieran solo en los altos colisionarían siempre. Por eso Java aplica antes la mezcla
`h ^ (h >>> 16)`. Está en `03-orden-busqueda/04`.

**05 → 12. ¿Qué hace `Math.addExact` y por qué existe?**

⏱️ Suma y **lanza `ArithmeticException`** si el resultado no cabe, en vez de dar la vuelta en
silencio.
🗣️ Existe porque el desbordamiento silencioso es el comportamiento por defecto y casi nunca es lo
que quieres en lógica de negocio: un importe que da la vuelta y se convierte en negativo es un
incidente contable, no un redondeo.
🔬 La familia completa es `addExact`, `subtractExact`, `multiplyExact`, `negateExact`, `incrementExact`
y `toIntExact` —esta última para detectar la pérdida al estrechar de `long` a `int`—. Go no tiene
equivalente en la stdlib.

**05 → 13. ¿Por qué `x >> 1` y `x / 2` no son equivalentes con números negativos?**

⏱️ Porque `>>` redondea hacia abajo y la división entera redondea hacia cero.
🗣️ Con `-7`: `-7 >> 1` es `-4` —hacia menos infinito— y `-7 / 2` es `-3` —hacia el cero—. Con
positivos coinciden, y por eso el error pasa desapercibido hasta que llega un negativo.
🔬 Es la misma familia de discrepancias que el operador módulo: en Java `-7 % 3` es `-1` y en Python
es `2`, porque Python define el módulo con el signo del divisor. Al portar una fórmula de un
lenguaje a otro, es una fuente real de bugs.

**05 → 14. ¿Por qué `Math.abs(hash) % n` es un bug latente y cómo se escribe bien?**

⏱️ Porque si `hash` es `Integer.MIN_VALUE`, `Math.abs` devuelve un negativo y el índice sale
negativo. Se escribe `(hash & 0x7fffffff) % n`.
🗣️ La máscara apaga el bit de signo, lo que garantiza un valor no negativo sin depender de ninguna
negación. Con potencias de dos se puede ir más allá: `hash & (n - 1)`, que evita también el módulo.
🔬 El bug se manifiesta una vez cada 2³² valores de hash: en un sistema con tráfico real, una vez
cada pocos días, con un `ArrayIndexOutOfBoundsException` que nadie consigue reproducir. Es el
arquetipo del fallo que solo se entiende si conoces la representación.

**05 → 15. ¿Por qué en JavaScript `MAX_SAFE_INTEGER + 1 === MAX_SAFE_INTEGER + 2` es `true`?**

⏱️ Porque todos los números de JavaScript son `double` de 64 bits, y a partir de 2⁵³ la mantisa ya no
puede representar todos los enteros.
🗣️ `MAX_SAFE_INTEGER` es 9 007 199 254 740 991 = 2⁵³ - 1. Más allá, los enteros representables van de
dos en dos, luego de cuatro en cuatro: dos valores distintos se redondean al mismo `double` y la
comparación da `true`.
🔬 La consecuencia real y frecuente: un identificador `bigint` de base de datos serializado como
número JSON **pierde precisión** al pasar por JavaScript, sin ningún error. Por eso la convención de
transportar identificadores de 64 bits como `string`, y por eso existe `BigInt`.

**05 → 16. Un `id` de tipo `bigint` llega corrupto al front. Explica el mecanismo y la corrección.**

⏱️ JSON no tiene tipo entero: el front lo lee como `double` y pierde los dígitos por encima de 2⁵³.
Se corrige transportándolo como `string`.
🗣️ El mecanismo exacto: la base genera un `id` de 64 bits (por ejemplo, un snowflake que empieza por
el timestamp, así que son números grandes); el backend lo serializa como número; `JSON.parse` lo
convierte a `double`; los últimos dígitos se redondean. El `id` sigue pareciendo válido y apunta a
otro registro o a ninguno.
🔬 Las correcciones, en orden: **serializar como string** —en Jackson, `@JsonSerialize(using =
ToStringSerializer.class)` sobre el campo, o configurarlo globalmente para `Long`—; usar `BigInt` en
el front si el valor debe operarse; o cambiar a identificadores que quepan en 2⁵³, que es renunciar a
64 bits. La primera es la estándar. Y el detalle que lo hace difícil de detectar: **funciona
perfectamente con identificadores pequeños**, así que pasa todos los entornos hasta que la tabla
crece.

**05 → 17. ¿Por qué escribir `x << 1` en vez de `x * 2` no es una optimización?**

⏱️ Porque el compilador ya genera la misma instrucción para las dos.
🗣️ La sustitución de multiplicaciones por potencias de dos con desplazamientos es una de las
optimizaciones más antiguas y universales que existen; escribirla a mano no cambia el código máquina
y sí empeora la legibilidad.
🔬 Peor aún: con negativos **no son equivalentes**, como dice la pregunta 13, así que la
"optimización" puede cambiar el resultado. Es folclore heredado de compiladores de hace cuarenta
años.

**05 → 18. ¿En qué caso `<<` sí expresa mejor la intención que una multiplicación?**

⏱️ Cuando lo que expresas **es** una potencia de dos, no una multiplicación.
🗣️ `1 << 20` para un megabyte, `1 << bit` para construir una máscara, `1 << n` para el tamaño de un
espacio de estados en una DP sobre máscaras. En esos casos el desplazamiento dice "el bit n" y la
multiplicación diría otra cosa.
🔬 La regla general es la de siempre: **el código expresa la intención**, no el atajo. `capacidad * 2`
para duplicar una tabla; `1 << 20` para una constante de tamaño; nunca `x << 1` donde la semántica es
"el doble".

**05 → 19. ¿Por qué TypeScript no puede protegerte del desbordamiento de JavaScript?**

⏱️ Porque su tipo `number` no distingue entero de decimal ni acota el rango: es el `double` de
JavaScript con otro nombre.
🗣️ No hay `int32` ni `int64` en TypeScript, así que el compilador no tiene información con la que
avisar de que un valor va a pasar de 2⁵³. El error ocurre en runtime y el sistema de tipos no lo ve.
🔬 Es uno de los pocos puntos del corpus donde TypeScript **no aporta nada**, y conviene decirlo tal
cual. Lo más cerca que se puede estar es usar `bigint` —que sí es un tipo distinto— o un tipo
nominal envuelto que obligue a pasar por un validador, que es disciplina de diseño y no del
compilador.

**05 → 20. ¿Cómo empaquetarías timestamp, nodo y secuencia en un `long` de 64 bits?**

⏱️ Con desplazamientos y máscaras, repartiendo los 64 bits entre los tres campos. Es el esquema
snowflake.

```text
 1 bit  signo (siempre 0, para que el id sea positivo y ordenable)
41 bits timestamp en milisegundos desde una época propia  → ~69 años
10 bits identificador de nodo                             → 1024 nodos
12 bits secuencia dentro del mismo milisegundo            → 4096 ids/ms/nodo

id = (timestamp << 22) | (nodo << 12) | secuencia
```

🗣️ Al reconstruir: `timestamp = id >>> 22`, `nodo = (id >>> 12) & 0x3FF`, `secuencia = id & 0xFFF`.
El bit de signo se deja a cero para que el identificador sea positivo y **ordenable por tiempo**, que
es la propiedad que lo hace valioso como clave primaria.
🔬 Los cuatro detalles que preguntan. **La época propia** —no 1970— para exprimir los 41 bits; con
epoch Unix se agotarían en 2039. **El reloj hacia atrás**: si el NTP retrasa el reloj, se pueden
generar identificadores duplicados, y la implementación tiene que detectarlo y esperar. **El
desbordamiento de la secuencia** dentro del mismo milisegundo: hay que bloquear hasta el siguiente
ms. Y **el transporte a JavaScript**, que es la pregunta 16: 64 bits no caben en un `double`, así que
viaja como string. Las alternativas modernas —UUIDv7, ULID— resuelven lo mismo con 128 bits y sin
coordinación de nodos.

**05 → 21. Te dan un arreglo donde todos los números aparecen dos veces salvo uno. Da dos soluciones y compara su espacio.**

⏱️ XOR de todos los elementos, O(n) en tiempo y **O(1) en espacio**; o un `HashSet`/mapa de conteos,
O(n) en tiempo y **O(n) en espacio**.
🗣️ El XOR funciona porque `x ^ x == 0` y la operación es conmutativa: los pares se cancelan sin
importar el orden y queda el impar. El mapa es más general pero paga memoria proporcional a los
elementos distintos.

```java
int unico = 0;
for (int x : datos) unico ^= x;      // O(1) de espacio
```

🔬 Lo que hay que saber decir es **dónde deja de servir el XOR**: solo funciona si los repetidos
aparecen un número **par** de veces y el único aparece una. Si aparecieran tres veces, hay que contar
bits por posición módulo 3, que es otro algoritmo. Y si hubiera **dos** elementos únicos, se separa
el conjunto en dos grupos usando un bit donde el XOR total sea 1. Reconocer que la solución elegante
tiene precondiciones estrictas es lo que distingue la respuesta.

**05 → 22. Un método de reparto en cubetas falla con `ArrayIndexOutOfBoundsException` una vez cada varios millones de peticiones. Da tu diagnóstico.**

⏱️ `Math.abs(hash) % n` con un hash igual a `Integer.MIN_VALUE`: el valor absoluto es negativo y el
índice también.
🗣️ La frecuencia lo delata: un fallo cada 2³² valores posibles de hash, que con tráfico real son días
o semanas. La traza apunta a un acceso por índice, el índice es negativo, y el código que lo calcula
usa `Math.abs`.

```java
int indice = Math.abs(clave.hashCode()) % cubetas;        // bug latente
int indice = (clave.hashCode() & 0x7fffffff) % cubetas;   // correcto
```

🔬 Cómo se confirma sin esperar a que vuelva a pasar: un test con una clave cuyo `hashCode` sea
`Integer.MIN_VALUE` —se puede fabricar, o usar directamente el valor— y comprobar el índice. Las
hipótesis alternativas, por si el `Math.abs` no está: un `hashCode` que devuelve valores negativos y
un `%` con divisor negativo; o una condición de carrera que lee el tamaño del arreglo mientras otro
hilo lo redimensiona. La primera es con diferencia la más probable, y la corrección de fondo es no
calcular índices a mano: delegar en la estructura.

---

# 06 — Simulación: preguntas transversales

Las `S#` que ya están cubiertas por una pregunta de capítulo no se repiten: se remite. Las
demás llevan sus tres capas.

**06 → S1. Escribes un método y el entrevistador pregunta "¿cuál es la complejidad?". ¿Qué contestas exactamente, y cuántas cosas nombras?**

⏱️ Tres cosas: tiempo, espacio y el caso al que te refieres.
🗣️ "O(n log n) en tiempo, O(n) en espacio por el arreglo auxiliar, y es el caso peor, no solo el
medio." Quien contesta solo el tiempo parece que solo sabe el tiempo, y la repregunta siempre es
el espacio.
🔬 Si el algoritmo tiene casos distintos, nómbralos los tres: mejor, medio y peor. Y si hay coste
amortizado, la palabra "amortizado" tiene que aparecer.

**06 → S2. ¿Por qué un algoritmo O(n) puede ser más lento que uno O(n log n) sobre datos reales?**

⏱️ Por la constante y por la localidad de memoria, que O grande descarta por definición.
🗣️ O(n) con una constante de 200 —saltos de puntero, fallos de caché, asignaciones— pierde
contra O(n log n) con constante 2 hasta un n bastante alto. El caso canónico es recorrer una
`LinkedList` contra ordenar un `int[]`.
🔬 El otro factor es el patrón de acceso: un algoritmo lineal que salta aleatoriamente por la
memoria puede ser más lento que uno logarítmico que recorre bloques contiguos. Es la razón de que
los B-trees existan.

**06 → S3. Te dicen "hasta 10⁵ elementos". ¿Qué acabas de aprender sobre la solución esperada?**

⏱️ Que esperan O(n log n) o mejor: con 10⁵, un O(n²) son 10¹⁰ operaciones.
🗣️ El tamaño en el enunciado es una pista deliberada. La escala útil: n ≤ 25 admite exponencial
con poda; n ≤ 5 000 admite cuadrático; 10⁵ pide linearítmico; más de 10⁷ pide lineal o
streaming.
🔬 Decirlo en voz alta antes de empezar —*"con 10⁵ descarto el cuadrático"*— demuestra que sabes
leer el enunciado, y te ahorra escribir la solución que iban a rechazar.

**06 → S4. ¿Qué diferencia hay entre coste amortizado, caso medio y caso peor? Da un ejemplo de cada uno.**

⏱️ Amortizado es una garantía sobre la secuencia; caso medio, una apuesta sobre los datos; caso
peor, la garantía absoluta.
🗣️ `ArrayList.add` es O(1) amortizado: en cualquier secuencia de n inserciones el total es O(n).
Quicksort es O(n log n) en el caso medio: depende de que los datos no vengan en el peor orden.
Heapsort es O(n log n) en el caso peor: pase lo que pase.
🔬 Contra un adversario que elige los datos, el caso medio se puede provocar —es la base de los
ataques de colisión de hash— y el amortizado no. Por eso los sistemas expuestos a entrada
hostil prefieren garantías de caso peor.

**06 → S5. Un compañero propone cambiar `ArrayList` por `LinkedList` "porque inserta en O(1)". ¿Qué le preguntas antes de aceptar?**

⏱️ "¿Ya tienes el nodo, o llegas por índice?" Si llega por índice, el O(1) no existe.
🗣️ La inserción es O(1) solo teniendo la referencia al punto. Si recorre para llegar, ya pagó
O(n) y perdió el beneficio. La segunda pregunta es si ha medido, porque la localidad de caché
suele invertir el resultado aunque la cuenta de operaciones diga lo contrario.
🔬 Y la tercera, más incómoda: "¿qué proporción hay entre inserciones y recorridos?". Si el
recorrido domina, la `LinkedList` pierde aunque las inserciones ganen.

**06 → S6. ¿Cuándo eliges deliberadamente el algoritmo con peor complejidad?**

Cubierta por **01 → 16**.

**06 → S7. Te piden optimizar un método y no tienes perfilador. ¿Por dónde empiezas y qué NO haces?**

⏱️ Empiezo por buscar lo superlineal dentro de bucles; no empiezo tocando micro-optimizaciones.
🗣️ El orden es: buscar llamadas O(n) dentro de bucles —`contains` sobre una lista, una consulta a
base de datos por iteración, una concatenación de `String`—, después revisar si hay trabajo
repetido que se pueda cachear, y solo entonces pensar en constantes. Lo que no se hace es
reescribir bucles en estilo "eficiente" sin saber dónde está el tiempo.
🔬 El patrón que más veces aparece en código real es el N+1: una consulta dentro de un bucle. Su
arreglo no es algorítmico, es de acceso a datos, y cambia órdenes de magnitud. Sin perfilador, la
aproximación barata es instrumentar con marcas de tiempo por fase, no por línea.

**06 → S8. "¿Qué estructura de datos usarías?" Da el método de respuesta, no una estructura.**

⏱️ Primero el contrato —qué operaciones necesito y con qué frecuencia—, después la
implementación —cuánto cuesta cada una—.
🗣️ Las preguntas que me hago, en orden: ¿necesito orden? ¿qué orden? ¿acceso por clave o por
posición? ¿admite duplicados? ¿cuál es la operación más frecuente? Solo con esas respuestas
elijo la clase, y digo en voz alta cuál fue la operación que decidió.
🔬 El árbol completo está en `02` §7. Responder directamente con una clase contesta la pregunta
equivocada y se nota.

**06 → S9. Necesitas saber si un elemento ya apareció, sobre diez millones de elementos. Elige y di qué pagas.**

Cubierta por **02 → 21**.

**06 → S10. Necesitas los 10 mayores de un flujo continuo de un millón de eventos. Elige y justifica.**

⏱️ Un min-heap acotado a 10: cada evento se compara con la cabeza y solo entra si la supera.
🗣️ Coste O(log 10) por evento, que es constante en la práctica, y O(10) de memoria
independientemente del tamaño del flujo. Ordenar el millón sería O(n log n) y además exige
tenerlo todo en memoria, que en un flujo continuo no es una opción.
🔬 El detalle contraintuitivo es que para los **mayores** se usa un **min**-heap: la cabeza es el
peor de los que están dentro, y es justo el que hay que expulsar cuando entra uno mejor. Se
desarrolla en `04-arboles-grafos/02`.

**06 → S11. ¿Cuándo `TreeMap` vence a `HashMap` aunque sea O(log n) contra O(1)?**

Cubierta por **02 → 9**.

**06 → S12. Te piden una caché LRU. ¿Cuál es la respuesta de cinco líneas y cuál la de cincuenta, y cuándo das cada una?**

⏱️ La de cinco es `LinkedHashMap` con `accessOrder` y `removeEldestEntry`; la de cincuenta es
`HashMap` más lista doblemente enlazada a mano.
🗣️ Se empieza siempre por la corta, porque demuestra que conoces la plataforma antes de
reinventarla. Si el enunciado dice "sin usar bibliotecas" o "explica la estructura interna", se
pasa a la larga: mapa de clave a nodo para el O(1) de búsqueda, lista doblemente enlazada para
mover al frente y expulsar por la cola en O(1).
🔬 La lista tiene que ser **doblemente** enlazada: para desenlazar un nodo en O(1) hace falta su
anterior. Con lista simple, cada movimiento sería O(n) y la estructura pierde su razón de ser.
Y los centinelas de cabeza y cola eliminan todos los casos borde de nodo único o lista vacía.

**06 → S13. Diseña la estructura de un carrito: orden de agregado, acceso por ID, total.**

Cubierta por **02 → 25**.

**06 → S14. Te dicen que en su sistema usan un `HashMap` compartido entre hilos sin sincronizar y "nunca ha fallado". ¿Qué respondes?**

⏱️ Que "nunca ha fallado" no es una propiedad de corrección: es una observación sobre el tráfico
que han tenido.
🗣️ Un `HashMap` con escrituras concurrentes puede perder actualizaciones, ver un mapa a medio
redimensionar o —en versiones anteriores a Java 8— entrar en un bucle infinito dentro de un
bucket, con una CPU al 100 % y ninguna excepción. El fallo depende del entrelazado de hilos, así
que puede tardar años en aparecer y aparecer bajo carga máxima.
🔬 La respuesta constructiva, sin sermón: si hay escrituras concurrentes, `ConcurrentHashMap`, que
cuesta prácticamente lo mismo en lectura. Si el mapa se llena al arrancar y después solo se lee,
un `HashMap` publicado de forma segura —`final`, o `Map.copyOf`— es correcto y hay que decirlo,
porque ese caso sí es legítimo y es probablemente el suyo.

**06 → S15. Enumera las cuatro técnicas sobre secuencias y la palabra del enunciado que delata a cada una.**

⏱️ Dos punteros → "ordenado". Ventana deslizante → "contiguo". Sumas de prefijos → "muchas
consultas de rango". Pila monótona → "el siguiente mayor".
🗣️ Las cuatro convierten un cuadrático obvio en lineal, y las cuatro se reconocen por la forma
del enunciado antes que por el dominio del problema. Reconocer el patrón es más rentable que
saberse un algoritmo más.
🔬 La quinta señal, que no es técnica sino táctica: si ninguna encaja y n es pequeño, la fuerza
bruta es la respuesta correcta y decirlo a propósito puntúa.

**06 → S16. ¿Por qué dos punteros y pila monótona son lineales si ambos parecen anidados?**

Cubierta por **03 → 9** y **03 → 16**.

**06 → S17. ¿Cuándo dejan de servir las sumas de prefijos?**

Cubierta por **03 → 11** y **03 → 20**.

**06 → S18. Tienes un arreglo sin ordenar y te piden pares que sumen X. Da dos soluciones con distinta complejidad y di cuál eliges.**

⏱️ Ordenar y dos punteros, O(n log n) y O(1) de espacio; o un `HashSet` en una pasada, O(n) y
O(n) de espacio.
🗣️ El `HashSet` gana en tiempo: por cada elemento, buscas si `X - elemento` ya apareció. Ordenar
destruye los índices originales, así que si te piden las posiciones y no los valores, la primera
opción necesita guardar pares (valor, índice) antes de ordenar.
🔬 Elijo el `HashSet` salvo que la memoria esté acotada o que el arreglo ya venga ordenado.
Y hay un detalle que se pregunta: con duplicados, `[3, 3]` y X=6 requiere contar ocurrencias, no
solo pertenencia — ahí el `HashSet` se convierte en un `HashMap<valor, cuenta>`.

**06 → S19. ¿Por qué `int[]` puede ser diez veces más rápido que `List<Integer>` si ambos son O(n)?**

Cubierta por **03 → 8** y **01 → 18**.

**06 → S20. Te dan código que hace `lista.remove(0)` dentro de un bucle. Explícalo y arréglalo de dos formas distintas.**

Cubierta por **03 → 24**.

**06 → S21. ¿Qué tres cosas dices sin que te las pidan después de escribir una función recursiva?**

⏱️ Cuál es el caso base, por qué el problema se reduce en cada paso, y cuánta pila consume en el
peor caso.
🗣️ Las tres en ese orden, en veinte segundos. Adelantarlas evita las tres repreguntas que iban a
venir y cambia el tono de la conversación: dejas de estar siendo examinado y pasas a estar
explicando.
🔬 La tercera es la que casi nadie dice, y es la que más puntúa: "profundidad log n porque el
árbol está equilibrado" o "profundidad n, así que con más de diez mil elementos lo reescribiría
iterativo".

**06 → S22. ¿Cuánta pila consume una recursión sobre un árbol de un millón de nodos? Depende de algo: ¿de qué?**

Cubierta por **04 → 13**.

**06 → S23. ¿Por qué escribir recursión de cola en Java no ahorra memoria?**

Cubierta por **04 → 7** y **04 → 19**.

**06 → S24. Producción lanza `StackOverflowError`. Da tu secuencia de diagnóstico.**

Cubierta por **04 → 16** y **04 → 24**.

**06 → S25. ¿Cuándo conviertes una recursión en iteración, y con qué estructura?**

Cubierta por **04 → 20**.

**06 → S26. Explica la diferencia entre backtracking y programación dinámica a alguien que confunde los dos.**

⏱️ El backtracking **enumera** todas las soluciones válidas; la DP **cuenta u optimiza** sin
enumerarlas, aprovechando que los subproblemas se repiten.
🗣️ Si te piden "dame todas las combinaciones", tiene que ser backtracking: la salida misma es
exponencial. Si te piden "cuántas hay" o "cuál es la mejor", casi siempre es DP, porque no hace
falta construir cada una.
🔬 La frontera práctica está en n: hasta 20–25, el backtracking con poda termina; por encima, hay
que encontrar la estructura de subproblemas solapados. Y hay un punto medio, la DP sobre máscaras
de bits, que es exactamente backtracking memoizado y aguanta hasta n ≈ 20 con estados de 2ⁿ.

**06 → S27. ¿Qué devuelve `[10, 9, 1].sort()` en JavaScript y por qué?**

⏱️ `[1, 10, 9]`, porque `sort()` sin comparador convierte los elementos a **string** y ordena
lexicográficamente.
🗣️ `"10" < "9"` porque compara carácter a carácter y `'1' < '9'`. Es el comportamiento
especificado, no un bug, y sorprende a todo el mundo la primera vez. La forma correcta es
`sort((a, b) => a - b)`.
🔬 Además, `sort()` **muta el arreglo original** y devuelve la misma referencia. Desde ES2023
existe `toSorted()`, que devuelve una copia ordenada sin mutar. Y desde ES2019 la ordenación está
garantizada como estable por especificación; antes dependía del motor.

**06 → S28. ¿Qué lenguajes de los cinco garantizan el orden de iteración de su mapa, y qué garantiza cada uno?**

⏱️ Python y JavaScript garantizan orden de inserción; Go garantiza que es aleatorio; Java no
garantiza nada.
🗣️ `dict` de Python lo garantiza por especificación desde 3.7; el `Map` de JavaScript siempre lo
ha hecho. Go aleatoriza a propósito el punto de inicio de la iteración. `HashMap` de Java no
promete orden, que es distinto de prometer desorden.
🔬 Esa diferencia entre "no garantiza" y "garantiza que no" tiene consecuencias reales: en Java un
código que dependa del orden puede funcionar durante años y romperse al cambiar de versión de la
JDK; en Go falla en la primera ejecución. `LinkedHashMap` es la forma de pedir la garantía en
Java explícitamente.

**06 → S29. ¿Por qué simular una cola con `push`/`shift` en JavaScript es un bug de rendimiento?**

Cubierta por **02 → 18** y **03 → 19**.

**06 → S30. Ninguno de los cinco salvo Java trae un mapa ordenado por clave en la stdlib. ¿Cómo lo resuelves en Python y en Go?**

Cubierta por **02 → 19**.

**06 → S31. ¿Qué hace `b := a[1:3]` en Go y qué bug produce con más frecuencia?**

Cubierta por **03 → 18**.

**06 → S32. Un candidato dice "en Python no me preocupo, `list` es una lista enlazada". ¿Qué corriges?**

⏱️ Que `list` es un **arreglo dinámico**, no una lista enlazada: acceso O(1) por índice,
inserción al principio O(n).
🗣️ El nombre engaña. Por dentro es un arreglo de punteros con capacidad de sobra, igual que
`ArrayList`. Lo que sí es una lista enlazada —de bloques— es `collections.deque`, y por eso es la
respuesta cuando hay que operar en los dos extremos.
🔬 La consecuencia concreta: `lista.insert(0, x)` y `lista.pop(0)` son O(n), y hacerlo en un bucle
es cuadrático. Es un bug de rendimiento frecuente en Python, y la documentación de `collections`
lo advierte de forma explícita.

**06 → S33. ¿Cuándo has elegido la estructura equivocada y cómo te diste cuenta?**

⏱️ Es una pregunta de experiencia: responde con un caso concreto, el síntoma y la medición.
🗣️ La estructura de una buena respuesta tiene cuatro partes: qué elegiste y por qué parecía
razonable entonces; qué síntoma apareció —lentitud bajo carga, memoria, un bug de orden—; cómo lo
confirmaste, con datos y no con intuición; y qué cambiaste. Los casos más creíbles son pequeños y
específicos.
🔬 Lo que se está evaluando no es el error, es si tienes el hábito de medir. Una respuesta que
termina en "lo cambié y midió tres veces menos" vale mucho más que una que termina en "lo
cambié". Y decir que no te ha pasado nunca es la peor respuesta posible.

**06 → S34. El entrevistador afirma que tu solución es O(n²) y tú crees que es O(n). ¿Cómo manejas el desacuerdo?**

⏱️ Pido el caso concreto: "¿sobre qué entrada crees que es cuadrática?", y trazo el conteo con él.
🗣️ No se defiende una complejidad afirmándola más fuerte. Se cuenta cuántas veces se ejecuta la
línea más interna, en voz alta y sobre un ejemplo pequeño. Si el desacuerdo está en un `while`
anidado, el argumento es el amortizado: cada elemento entra y sale una vez.
🔬 Y si al trazarlo resulta que tiene razón, decirlo rápido y sin ceremonia es una señal
excelente. La habilidad que se está midiendo aquí no es la complejidad: es cómo discutes con
alguien que va a ser tu colega. Muchas veces la pregunta es deliberadamente una afirmación falsa,
justo para ver eso.

**06 → S35. "¿Para qué sirve saber esto si nunca implementas un heap a mano?" Responde.**

⏱️ Para **elegir** el que ya está implementado, y para reconocer cuándo el que elegiste no
aguanta.
🗣️ Nadie escribe un `TreeMap`, pero alguien tiene que decidir si el índice va por hash o por
árbol, si el ranking se mantiene en memoria o en Redis, si esa consulta de rango es barata. Todas
esas decisiones son exactamente este temario, y se toman en diseño, no en una entrevista.
🔬 Y hay un segundo motivo, menos elegante y perfectamente honesto: cuando algo se degrada en
producción, el que puede leer un volcado de hilos o un plan de ejecución y decir "esto es un
nested loop join sobre 200 000 filas" es el que resuelve el incidente. No es conocimiento
académico: es el vocabulario del diagnóstico.

**06 → S36. Te piden optimizar un algoritmo que ya es O(n log n) y tarda 40 minutos sobre 10 millones de registros. ¿Dónde buscas?**

⏱️ Si la complejidad ya es buena, el tiempo está en la constante: E/S, asignaciones, boxing o
acceso a datos.
🗣️ Diez millones por log n son unos 230 millones de operaciones: milisegundos si fueran
operaciones puras. Cuarenta minutos significan que cada "operación" no es una operación: es una
consulta, una lectura de disco, una deserialización o una asignación de objeto. Busco ahí, no en
el algoritmo.
🔬 Los sospechosos habituales, en orden: una consulta por registro (N+1); `List<Integer>` en vez
de `int[]`, con boxing y fallos de caché; concatenación de `String` en un bucle; log por registro
en modo `DEBUG`; y presión de GC por objetos temporales. Ninguno se arregla cambiando de
algoritmo, y todos aparecen en un perfilador en cinco minutos.

---

# 06 — Simulación: problemas de pizarra

Cada uno con la misma estructura: fuerza bruta primero, solución buena después, complejidad y
casos borde. Es también el orden en que conviene narrarlos en voz alta.

**06 → P1. El precio del producto.**

**Fuerza bruta.** Por cada línea, recorrer el catálogo: O(n·m) = 8 000 millones de
comparaciones. Es el código que tarda seis horas.

**Solución.** Indexar una vez y consultar:

```java
// Una sola pasada por el catálogo: n operaciones
Map<ProductoId, Money> precios = new HashMap<>(300_000);
for (Producto p : catalogo) precios.put(p.id(), p.precio());

// Una consulta O(1) por línea: m operaciones
for (LineaPedido linea : lineas) {
    Money precio = precios.get(linea.productoId());
    if (precio == null) throw new ProductoNoEncontrado(linea.productoId());
    // ...
}
```

**Complejidad.** O(n + m) en tiempo frente a O(n·m); O(n) en espacio, del orden de decenas de MB
para 200 000 entradas. De seis horas a milisegundos.

**Casos borde.** Producto que no está en el catálogo —hay que decidir si es error o precio
cero, y decirlo—; productos duplicados en el catálogo, donde `put` se queda con el último y
convendría detectarlo; y `ProductoId` como clave, que obliga a tener `equals` y `hashCode`
correctos, o el mapa no encuentra nada aunque los valores sean iguales.

**La repregunta: "¿y si el catálogo no cabe en memoria?"** Cambia la respuesta de estructura a
algoritmo: ordenar ambas fuentes por `ProductoId` y hacer un **merge join** en un solo recorrido
simultáneo. Es O(n log n + m log m) si hay que ordenar, y usa memoria constante. Es exactamente
la elección que hace el optimizador de una base de datos entre *hash join* y *merge join*, y
decirlo con ese nombre cierra la pregunta.

**06 → P2. Subarreglo de suma máxima.**

**Fuerza bruta.** Dos bucles anidados probando cada par de inicio y fin, acumulando: O(n²). Se
dice en voz alta antes de optimizar, porque establece la referencia.

**Solución (Kadane).** Un recorrido. En cada posición decides si el subarreglo mejor que termina
aquí extiende al anterior o empieza de nuevo:

```java
long mejorAqui = datos[0], mejorGlobal = datos[0];
for (int i = 1; i < datos.length; i++) {
    mejorAqui = Math.max(datos[i], mejorAqui + datos[i]);   // ¿extiendo o reinicio?
    mejorGlobal = Math.max(mejorGlobal, mejorAqui);
}
```

- La línea que lo resume: **si lo que traías es negativo, no vale la pena arrastrarlo**.
- Es programación dinámica con espacio O(1): el estado `mejorAqui` es la tabla, reducida a una
  variable.

**Complejidad.** O(n) en tiempo, O(1) en espacio.

**Casos borde.** El importante es **todos negativos**: si inicializas `mejorGlobal` a 0, el
algoritmo devuelve 0, que sería el subarreglo vacío. Inicializar con `datos[0]` devuelve el
menos malo, que es lo que casi siempre se quiere. Hay que **preguntar cuál de las dos semánticas
quieren**: es la repregunta obligatoria y el motivo por el que este problema es clásico. Otros
casos: arreglo vacío (lanzar o `Optional`), un solo elemento, y desbordamiento si los valores son
`int` grandes — de ahí el `long`.

**06 → P3. La cola de un millón de eventos.**

**La decisión.** Son 500 eventos, una vez, al arrancar. Un `ArrayDeque` con pool de objetos es
complejidad sin comprador.

**Solución.**

```java
for (EventoConfiguracion evento : eventos) {   // 500 elementos, orden de llegada
    aplicar(evento);
}
```

**Complejidad.** O(n) con n = 500. En cualquier estructura razonable el tiempo total es de
microsegundos.

**Cómo se defiende.** Con números, no con opiniones: 500 elementos son medio kilobyte de
referencias; el pool de objetos ahorra 500 asignaciones, que el recolector generacional hace en
un tiempo indistinguible de cero. A cambio cuesta código que hay que mantener, entender y probar,
y un pool mal cerrado es una fuga de memoria.

**Casos borde.** Que el orden importe de verdad —conviene confirmarlo, porque si los eventos son
conmutativos ni siquiera hace falta orden—, y que aplicar un evento pueda fallar: ahí la decisión
real no es la estructura, es si se aborta el arranque o se continúa, y esa sí es una pregunta de
diseño.

**Lo que este problema evalúa.** Que sepas **no** optimizar. Un candidato que monta el pool
demuestra que conoce la técnica y que no sabe cuándo aplicarla, que es peor que no conocerla.

**06 → P4. Paréntesis válidos.**

**Solución.** Una pila. Los de apertura se apilan; los de cierre tienen que corresponder con la
cima:

```java
Deque<Character> pila = new ArrayDeque<>();
Map<Character, Character> pares = Map.of(')', '(', ']', '[', '}', '{');
for (char c : texto.toCharArray()) {
    if (pares.containsValue(c)) pila.push(c);
    else if (pares.containsKey(c)) {
        if (pila.isEmpty() || pila.pop() != pares.get(c)) return false;
    }
}
return pila.isEmpty();   // sobran aperturas si no está vacía
```

- El `pila.isEmpty()` antes del `pop` cubre `")("`, que es el caso que casi todos olvidan.
- El `return pila.isEmpty()` final cubre `"(("`. Devolver `true` sin esa comprobación es el
  segundo error más común.

**Complejidad.** O(n) en tiempo, O(n) en espacio en el peor caso —todo aperturas—.

**Casos borde, enumerados antes de que los pregunten.** Cadena vacía (válida por convención, y
conviene decirlo); solo aperturas `"((("`; solo cierres `")))"`; cierre antes que apertura `")("`;
tipos cruzados `"([)]"`, que es el que distingue esta solución de contar caracteres; y caracteres
que no son paréntesis, que hay que decidir si se ignoran o invalidan.

**La repregunta: "¿y la posición del primer error?"** Se apilan **índices** en vez de caracteres,
consultando el carácter en el texto. Es el mismo criterio de la pila monótona: guardar posiciones
te deja responder "cuál" y "dónde". Si al final quedan aperturas sin cerrar, el índice del error
es el que quedó al fondo de la pila.

**06 → P5. Combinaciones de un menú.**

**Solución.** El esqueleto de backtracking, con poda por presupuesto y copia al añadir:

```java
void explorar(int i, List<Plato> actual, Money gastado,
              Money presupuesto, List<List<Plato>> resultado) {
    if (i == menu.size()) { resultado.add(new ArrayList<>(actual)); return; }  // copia

    explorar(i + 1, actual, gastado, presupuesto, resultado);                  // no incluir

    Money nuevo = gastado.mas(menu.get(i).precio());
    if (nuevo.compareTo(presupuesto) <= 0) {          // poda: rama inviable, no se explora
        actual.add(menu.get(i));                      // elegir
        explorar(i + 1, actual, nuevo, presupuesto, resultado);   // explorar
        actual.remove(actual.size() - 1);             // deshacer
    }
}
```

- La **poda** es la línea del `if`: en cuanto el total se pasa, toda esa rama se descarta sin
  explorarla. Como los precios son positivos, añadir más nunca va a arreglarlo.
- El **deshacer** y la **copia** son los dos pasos que, omitidos, producen los dos bugs clásicos:
  soluciones contaminadas y todas las soluciones iguales.

**Complejidad.** O(2ⁿ) combinaciones en el peor caso, cada una copiada en O(n): O(n·2ⁿ) en tiempo.
Espacio: O(n) de pila más el tamaño de la salida, que también es exponencial.

**Casos borde.** Presupuesto menor que el plato más barato —la única solución es el conjunto
vacío, que hay que decidir si se devuelve—; platos de precio cero, que no podan nunca; y precios
en coma flotante, que es la razón de usar un `Money` con enteros y no `double`.

**La repregunta: "¿hasta qué n aguanta, y qué harías con n = 200?"** Aguanta hasta n ≈ 25:
2²⁵ son 33 millones de ramas, ya en el límite. Con 200 no hay backtracking que valga, y la
respuesta es que **el problema cambia**: si lo que quieren es enumerar todas las combinaciones, la
salida misma es astronómica y la pregunta está mal planteada — hay que preguntar qué se hace con
ellas. Si lo que quieren es la mejor combinación bajo presupuesto, eso es el **problema de la
mochila** y se resuelve con DP en O(n · presupuesto), que con 200 platos es inmediato. Está en
[`05-dp-y-tecnicas/01`](../05-dp-y-tecnicas/01-programacion-dinamica.md). Detectar que la
pregunta cambió de familia es exactamente lo que se está evaluando.

---

**Vuelta a:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**README del bloque:** [`01-fundamentos`](README.md)

---

**Anterior:** [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) ·
**Bloque:** [README](README.md)
