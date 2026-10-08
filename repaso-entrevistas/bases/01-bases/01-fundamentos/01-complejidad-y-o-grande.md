# 01 — Complejidad y O grande

> La notación que sostiene todo el corpus: qué mide realmente, cómo se calcula sin
> demostrar nada, qué es el coste amortizado y por qué la cota teórica y el cronómetro
> discrepan tan seguido. Es el capítulo dueño de esta notación: los demás la usan y no la
> redefinen.
> No asume nada leído. Es el primero por una razón.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tienes un proceso nocturno que factura los pedidos del día. Por cada línea de pedido busca
el precio recorriendo la lista de productos entera. Con 500 productos y 2 000 líneas nadie
notó nada: el proceso tardaba ocho segundos.

El catálogo creció a 200 000 productos y las líneas a 40 000. El proceso ahora tarda **seis
horas** y no cabe en la noche. Nadie tocó una línea de código.

```text
500 × 2 000        =      1 000 000 comparaciones   →  8 segundos
200 000 × 40 000   =  8 000 000 000 comparaciones   →  6 horas
```

El código no se degradó: **siempre fue cuadrático**, y lo cuadrático no se nota hasta que se
nota de golpe. O grande es el vocabulario que te permite ver eso en la revisión de código, un
año antes de la llamada a las tres de la mañana.

Y es, además, la primera pregunta de toda entrevista técnica después de que escribas algo:
*"¿cuál es la complejidad?"*. No es una pregunta de trivia. Es la pregunta de si entiendes lo
que acabas de escribir.

> **Regla de entrevista:** di la complejidad **antes** de que te la pregunten, y di las dos:
> tiempo y espacio. Quien solo dice la de tiempo parece que solo sabe la de tiempo.

---

## 2. ⏱️ Qué mide O grande, y qué no

**Qué es.** O grande describe **cómo crece** el trabajo de un algoritmo cuando crece el
tamaño de la entrada, ignorando las constantes y los términos de menor orden.

**Cómo va.** Se queda con el término dominante y tira el resto:

```text
3n² + 500n + 9000   →   O(n²)
```

Tirar el `500n` y el `9000` no es descuido: es la definición. Para `n` suficientemente
grande, el `n²` los aplasta. El problema es que **"suficientemente grande" puede estar muy
lejos**: con n = 10, ese `9000` es el 90 % del trabajo real.

**Cuánto cuesta creértelo demasiado.** Tres cosas que O grande no te dice, y que deciden el
resultado en producción:

- **La constante.** O(n) con una constante de 200 pierde contra O(n log n) con constante 2
  hasta un n bastante alto.
- **El caso.** O grande sin decir *qué caso* es ambiguo. Quicksort es O(n²) en el peor caso y
  O(n log n) en el medio, y esa diferencia es toda la conversación.
- **La máquina.** Recorrer un arreglo y recorrer una lista enlazada son ambos O(n), y el
  arreglo puede ser diez veces más rápido por localidad de caché. Esto es de
  [`03` — Arrays, listas y secuencias](03-arrays-listas-y-secuencias.md) y es el ejemplo
  favorito de este corpus.

**Cuándo sí.** Siempre que compares cómo escalan dos soluciones, y siempre que la entrada
pueda crecer sin que tú controles cuánto.

**Cuándo no.** Cuando n está acotado y es pequeño por contrato —los 12 meses del año, los 50
estados, las 8 estrategias de cobro—. Ahí la complejidad es irrelevante y elegir el código
más claro es la decisión correcta. Decir esto en una entrevista es una respuesta cara, no una
excusa.

> **Veredicto:** O grande responde "¿aguanta si crece?", no "¿es rápido?". Confundir las dos
> es el error conceptual más común del tema, y se detecta en la primera repregunta.

---

## 3. 🧱 Las tres cotas: O, Ω y Θ

Se usan mal a diario, incluso por gente que las conoce. La distinción es de **cota**, no de
caso, y ese es justo el punto que confunde a todo el mundo.

| Notación | Qué acota | Se lee |
|---|---|---|
| **O(f)** | Por arriba | "no crece más rápido que f" |
| **Ω(f)** | Por abajo | "no crece más lento que f" |
| **Θ(f)** | Por ambos lados | "crece exactamente como f" |

**El malentendido clásico.** Mucha gente dice "O es el caso peor y Ω el caso mejor". Es
falso, aunque funcione por accidente casi siempre. Las cotas y los casos son **dos ejes
independientes**: puedes hablar de la cota superior del caso mejor sin contradecirte.

```text
Quicksort, caso peor:   Θ(n²)      ← exacto, no solo "O(n²)"
Quicksort, caso medio:  Θ(n log n)
Ordenación por comparación, cualquier algoritmo: Ω(n log n)   ← cota inferior del PROBLEMA
```

Esa última línea es la que vale dinero en una entrevista: **Ω(n log n) no es una propiedad de
un algoritmo, es del problema**. Ninguna ordenación basada en comparar pares puede bajar de
ahí, y por eso counting sort y radix sort —que no comparan— sí bajan. Se ve en
[`03-orden-busqueda/01`](../03-orden-busqueda/01-ordenacion.md).

**Cuándo sí usar Θ.** Cuando la cota es ajustada y quieres decirlo. Decir "merge sort es
O(n²)" es técnicamente **cierto** y suena a que no lo sabes.

**Cuándo no.** En conversación normal, nadie dice Θ. Se dice O y se asume ajustada. La
distinción se saca cuando el entrevistador te la busca, no antes.

> **Veredicto:** en voz alta usa O. Pero si te preguntan si merge sort es O(n²), la respuesta
> es "sí, y además es Θ(n log n), que es lo que querías saber".

---

## 4. 🧱 Cómo se calcula sin demostrar nada

Cuatro reglas prácticas cubren el 95 % de lo que vas a necesitar delante de un entrevistador.

**Regla 1: bucles anidados multiplican, bucles secuenciales suman.**

```java
for (Producto p : catalogo) {        // n
    for (LineaPedido l : lineas) {   // m
        // ...                       // O(1)
    }
}
```

- Son **O(n·m)**, no O(n²): usar `n²` cuando hay dos colecciones distintas es impreciso y el
  entrevistador lo nota.
- Si los bucles fueran uno detrás de otro, sería O(n + m), que se simplifica a O(máximo de
  los dos).

**Regla 2: dividir el problema a la mitad cada vez introduce un log.** Búsqueda binaria,
altura de un árbol balanceado, `heapify` de un nodo. El logaritmo es base 2, pero la base no
importa en O grande: cambiar de base es multiplicar por una constante.

**Regla 3: recorrer n elementos haciendo trabajo logarítmico da n log n.** Es el coste de
insertar n elementos en un heap, o de ordenar por comparación. Cuando veas `n log n`, busca
ese patrón: algo que se hace n veces y cuesta log cada vez.

**Regla 4: la complejidad la manda la llamada más cara.** Si un método hace una búsqueda
binaria y luego una ordenación, es O(n log n): el log n desaparece dentro.

> 💡 **Truco.** Cuenta cuántas veces se ejecuta la **línea más interna**, no cuántos bucles
> hay. Un bucle que va `i *= 2` parece un bucle y es un log. Un `while` que avanza dos
> punteros que nunca retroceden parece anidado y es lineal. Este es el error que más gente
> comete en las 🔴.

---

## 5. ⏱️ La tabla de costes

El zoo completo, de mejor a peor, con la única columna que casi ninguna tabla trae:

| Complejidad | Nombre | Ejemplo típico | Lo que la tabla no dice |
|---|---|---|---|
| **O(1)** | Constante | Acceso a un índice, `push` a una pila | "Constante" puede ser lenta: un `hashCode` caro es O(1) y duele |
| **O(log n)** | Logarítmica | Búsqueda binaria, `TreeMap.get` | Con n = mil millones son 30 pasos. Es prácticamente gratis |
| **O(n)** | Lineal | Recorrer, buscar sin índice | La constante manda: un arreglo vence a una lista enlazada por 5–10× |
| **O(n log n)** | Linearítmica | Ordenar por comparación | Es el **techo práctico** de lo que aguanta un backend con datos grandes |
| **O(n²)** | Cuadrática | Dos bucles anidados, burbuja | Con n = 10 000 son 100 millones: el límite de lo tolerable |
| **O(2ⁿ)** | Exponencial | Subconjuntos, fuerza bruta | Con n = 40 ya no termina. La DP existe para matar esto |
| **O(n!)** | Factorial | Permutaciones, viajante por fuerza bruta | Con n = 20 supera la edad del universo |

Los números que hacen la tabla concreta, asumiendo mil millones de operaciones por segundo, y
**los umbrales que conviene memorizar**, porque permiten deducir el algoritmo esperado a partir
del tamaño del problema:

```text
n = 1 000 000     O(n)         ~ 1 ms          n ≤ 10          →  O(n!) o O(2ⁿ)
n = 1 000 000     O(n log n)   ~ 20 ms         n ≤ 25          →  O(2ⁿ) con poda
n = 1 000 000     O(n²)        ~ 11 días       n ≤ 5 000       →  O(n²)
n = 50            O(2ⁿ)        ~ 13 días       n ≤ 1 000 000   →  O(n log n) o mejor
n = 20            O(n!)        ~ 77 años       n > 10 000 000  →  O(n), y piensa en streaming
```

> 💡 **Truco.** Si el enunciado te dice el tamaño de la entrada, te está diciendo la
> complejidad esperada. "Hasta 10⁵ elementos" significa "quiero n log n". Decirlo en voz alta
> —*"con 10⁵ asumo que buscas n log n, no n²"*— es de las frases que mejor impresión causan.

---

## 6. 🧱 Coste amortizado

**El problema.** `ArrayList.add` es O(1)… salvo cuando el arreglo interno se llena, y
entonces copia todo a uno nuevo del doble de tamaño, que es O(n). ¿Cuál de las dos es la
respuesta correcta?

**Qué es.** El coste amortizado es el coste **promedio por operación en una secuencia larga**,
no el promedio estadístico sobre entradas aleatorias. La diferencia importa: amortizado es una
garantía sobre la secuencia, el caso medio es una apuesta sobre los datos.

**Cómo va.** Duplicar en vez de crecer de uno en uno es lo que lo hace funcionar:

```text
Inserciones:  1  2  3  4  5  6  7  8  9 ...
Copias:       1  2  -  4  -  -  -  8  -      ← solo en potencias de 2
Total de copias tras n inserciones: 1+2+4+...+n ≈ 2n
Coste por inserción: 2n/n = O(1) amortizado
```

La serie geométrica es toda la magia: **cada elemento se copia, en promedio, dos veces en
toda su vida**. Si en vez de duplicar creciera de 10 en 10, el total sería O(n²) y el
amortizado O(n).

**Cuándo sí.** Es la respuesta correcta para `ArrayList.add`, `HashMap.put`, `StringBuilder`
y el redimensionado de cualquier estructura que duplique.

**Cuándo no.** En sistemas de latencia acotada —un motor de trading, un lazo de control— el
amortizado miente donde más duele: esa inserción concreta que dispara el rehash de un mapa de
diez millones de entradas **sí** tarda. Si tu SLA es de p99, el amortizado no es tu métrica.

> **Veredicto:** *"O(1) amortizado"* es la respuesta completa; *"O(1)"* es la incompleta.
> Y saber que la palabra existe es lo que te separa de quien memorizó la tabla.

---

## 7. 🧱 Complejidad espacial, y la pila que nadie cuenta

La complejidad en espacio se responde con la misma notación, contando **la memoria auxiliar**:
la que el algoritmo pide además de la entrada.

```text
Ordenación in-place (quicksort, heapsort)  →  O(1) auxiliar... casi
Merge sort                                 →  O(n) auxiliar, siempre
```

Ese "casi" del quicksort es la trampa favorita de los entrevistadores: quicksort **no usa
arreglo auxiliar, pero sí usa pila de recursión**. Son O(log n) marcos si la partición es
equilibrada y O(n) si es pésima. Un quicksort sin la optimización de recursión al lado menor
puede desbordar la pila con un arreglo ya ordenado.

**La regla que nadie aplica:** en un algoritmo recursivo, **la profundidad de la recursión es
espacio**. Se ve entero en [`04` — Recursión y backtracking](04-recursion-y-backtracking.md),
pero la consecuencia se declara aquí porque es de complejidad:

```text
Recorrido en profundidad de un árbol equilibrado  →  O(log n) de pila
Recorrido en profundidad de una lista disfrazada  →  O(n) de pila  →  StackOverflowError
```

> ⚠️ **Advertencia.** Responder "O(1) de espacio" sobre un algoritmo recursivo es un fallo
> objetivo, no un matiz. La pila cuenta, y el entrevistador que preguntó espacio casi siempre
> preguntó por eso.

---

## 8. 🧱 Recurrencias y el teorema maestro

Cuando el algoritmo es divide y vencerás, su coste se escribe como una recurrencia:

```text
T(n) = a · T(n/b) + f(n)

a    = en cuántos subproblemas se divide
n/b  = de qué tamaño es cada subproblema
f(n) = lo que cuesta dividir y recombinar
```

El teorema maestro resuelve los casos habituales sin que tengas que desarrollar nada. Los
tres que salen en entrevista:

| Recurrencia | Resultado | Quién es |
|---|---|---|
| `T(n) = 2T(n/2) + O(n)` | **Θ(n log n)** | Merge sort, quicksort en el caso medio |
| `T(n) = T(n/2) + O(1)` | **Θ(log n)** | Búsqueda binaria |
| `T(n) = 2T(n/2) + O(1)` | **Θ(n)** | Recorrer un árbol binario, `heapify` completo |

La intuición sin teorema, que es lo que conviene poder explicar: **compara el trabajo de la
raíz con el de las hojas**. En merge sort cada nivel hace O(n) trabajo y hay log n niveles, de
ahí el n log n. En la búsqueda binaria solo hay un camino de la raíz a la hoja, de ahí el log
n solo.

**Cuándo sí.** Para justificar un coste que no es obvio, sobre todo el O(n) del `heapify`
completo, que a todo el mundo le parece n log n.

**Cuándo no.** Para demostrar. Nadie te va a pedir la demostración formal del teorema maestro
en una entrevista de backend; si te la piden, están entrevistando para otra cosa.

> **Veredicto:** memoriza las tres recurrencias de la tabla y la intuición de "trabajo por
> nivel × número de niveles". Es todo lo que este temario necesita del teorema maestro.

---

## 9. 🩺 Por qué el cronómetro te contradice en la JVM

Vas a medir con `System.nanoTime()` para comprobar que tu O(n log n) gana, y te va a salir al
revés. Hay cuatro razones, y todas son de la plataforma, no del algoritmo: **el JIT no ha
compilado todavía** —las primeras miles de ejecuciones corren interpretadas—; **el recolector
de basura entra cuando quiere** y su pausa se atribuye a tu algoritmo; **el JIT elimina código
muerto**, así que si no usas el resultado puede que tu bucle no se ejecute y midas cero; y **la
caché decide**, porque el segundo recorrido del mismo arreglo es más rápido y el orden en que
mides cambia lo que mides.

La salida correcta es un armazón que controle todo eso: **JMH** (`org.openjdk.jmh`), que hace
warmup, aísla las iteraciones y evita la eliminación de código muerto con `Blackhole`.

> 🩺 **Diagnóstico.** Si un compañero te enseña un `nanoTime` que "demuestra" que la lista
> enlazada gana, la primera pregunta no es sobre el algoritmo: es *"¿cuántas iteraciones de
> warmup?"*. Sin JMH, el número no significa nada.

---

## 10. 🔭 Dónde aparece de verdad

Fuera de la entrevista, esta notación se usa en cuatro sitios y conviene poder nombrarlos: en
la **revisión de código** ("este `contains` dentro del `for` te hace el método cuadrático" es
el comentario más rentable que existe); en el **plan de ejecución** de una consulta, donde un
*nested loop join* es O(n·m) y un *hash join* es O(n + m), y el optimizador elige entre ellos
con este mismo razonamiento; en el **dimensionado**, porque "¿aguanta si multiplicamos por diez
los usuarios?" es una pregunta de complejidad disfrazada de capacidad; y en el **incidente**,
porque el sistema que iba bien y dejó de ir sin que nadie tocara código casi siempre tiene
dentro algo superlineal que cruzó su umbral.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "O grande mide velocidad" | Mide crecimiento. Para n pequeño, la constante decide |
| "O es el caso peor, Ω el mejor" | Son cotas, no casos. Puedes acotar por arriba el caso mejor |
| "El `HashMap` es O(1)" | O(1) **amortizado** y con buen `hashCode`; degenerado es O(n), o O(log n) desde Java 8 |
| "Quicksort es O(n log n)" | En el caso medio. En el peor es O(n²), y ese peor era el arreglo ordenado |
| "Este algoritmo recursivo usa O(1) de espacio" | La pila de recursión es espacio: O(profundidad) |
| "Medí con `nanoTime` y es más rápido" | Sin warmup mides el intérprete y el GC, no el algoritmo |
| "O(2n) es peor que O(n)" | Son lo mismo: las constantes se descartan por definición |

---

## 📚 Para profundizar

- **Libro** — Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT
  Press, 2022). Capítulos 3 (crecimiento de funciones), 4 (divide y vencerás y teorema
  maestro) y 17 (análisis amortizado). **Si solo consultas un capítulo, que sea el 17**: el
  análisis amortizado es lo que peor se explica en todas partes.
- **Libro** — Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020). Capítulo 2. La
  mejor explicación práctica de "cuánto es demasiado", con los umbrales por tamaño de entrada.
- **Libro** — Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011). Sección 1.4,
  con el modelo de costes medido de verdad sobre Java.
- [Stanford CS161 — Asymptotic notation (apuntes de clase, PDF)](https://web.stanford.edu/class/archive/cs/cs161/cs161.1168/lecture3.pdf):
  las definiciones formales de O, Ω y Θ en seis páginas, para cuando la intuición no basta.
- [Big-O Cheat Sheet](https://www.bigocheatsheet.com/): la tabla de complejidades de todas las
  estructuras en una página. Útil para repasar el día antes; insuficiente para entender.
- **Tutorial** — Baeldung, «Big O Notation in Java». Los ejemplos están en Java, que es lo que
  falta en casi toda la bibliografía del tema.
- **Video** — MIT OpenCourseWare, *Introduction to Algorithms* (6.006), clase 1: modelos de
  computación y análisis asintótico.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Qué mide exactamente la notación O grande? 🟢
2. ¿Cuál es la complejidad de dos bucles anidados sobre colecciones de tamaño n y m? 🟢
3. ¿Cuál es la complejidad de la búsqueda binaria y por qué aparece el logaritmo? 🟢
4. ¿Por qué `O(2n)` y `O(n)` son la misma cosa? 🟢
5. ¿Qué complejidad esperarías que te pidan si el enunciado dice "hasta 10⁶ elementos"? 🟢
6. ¿Qué significa que un algoritmo sea Θ(n log n) y no solo O(n log n)? 🟡
7. ¿En qué se diferencian el coste amortizado y el caso medio? 🟡
8. ¿Por qué la base del logaritmo no aparece en la notación? 🟡
9. ¿Cuál es la complejidad en espacio de merge sort y cuál la de quicksort? 🟡
10. ¿Por qué se dice que Ω(n log n) es una propiedad del problema de ordenar y no de un
    algoritmo? 🟡
11. ¿Qué complejidad tiene `ArrayList.add` y por qué la respuesta tiene dos partes? 🟡
12. ¿Qué diferencia hay entre complejidad en espacio auxiliar y espacio total? 🟡
13. ¿Por qué duplicar la capacidad da O(1) amortizado y crecer de diez en diez no? 🟠
14. Un `while` avanza dos punteros que nunca retroceden sobre el mismo arreglo. ¿Es
    cuadrático? Justifica. 🟠
15. ¿Por qué `T(n) = 2T(n/2) + O(1)` da Θ(n) y `T(n) = 2T(n/2) + O(n)` da Θ(n log n)? 🟠
16. ¿Cuándo es correcto elegir deliberadamente un algoritmo O(n²)? 🟠
17. ¿Por qué el coste amortizado es mala métrica para un sistema con SLA de p99? 🟠
18. ¿Por qué recorrer un arreglo puede ser mucho más rápido que recorrer una lista enlazada
    si ambos son O(n)? 🟠
19. ¿Qué mide realmente un `System.nanoTime()` alrededor de un bucle en la JVM, y qué usarías
    en su lugar? 🟠
20. En Python, `lista.insert(0, x)` y `deque.appendleft(x)` hacen lo mismo. ¿Tienen la misma
    complejidad? ¿Por qué? 🟠
21. En JavaScript, `array.shift()` se documenta como que elimina el primer elemento. ¿Qué
    coste tiene y por qué existe una alternativa? 🟠
22. Un método hace una búsqueda binaria dentro de un bucle sobre n elementos, y después
    ordena el resultado. ¿Cuál es su complejidad total? 🔴
23. Te dan el proceso de facturación del problema inicial: 200 000 productos, 40 000 líneas,
    seis horas. Propón la solución, di su nueva complejidad y qué pagas por ella. 🔴
24. Un compañero demuestra con `nanoTime` que su `LinkedList` gana al `ArrayList`. Da tres
    hipótesis en orden de probabilidad. 🔴
25. Escribe un algoritmo O(n) que encuentre el segundo elemento más grande de un arreglo, y
    di qué hace con duplicados y con un arreglo de un solo elemento. 🔴

---

**Siguiente:** [`02` — TDAs: contrato e implementación](02-tdas-contrato-e-implementacion.md) ·
**Relacionado:** [`03-orden-busqueda/01` — Ordenación](../03-orden-busqueda/01-ordenacion.md)
