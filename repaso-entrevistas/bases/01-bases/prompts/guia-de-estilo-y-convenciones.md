# ✍️ Guía de estilo, tono y convenciones

## Bases: algoritmos y estructuras de datos — repaso para entrevistas de Backend Senior y Tech Lead

Esta guía es la fuente de verdad editorial de `repaso-bases-entrevistas/` y manda sobre
**los ocho bloques del hilo principal** (`01-fundamentos`, `02-texto`, `03-orden-busqueda`,
`04-arboles-grafos`, `05-dp-y-tecnicas`, `06-numeros-tiempo-concurrencia`, `07-formatos-de-datos`,
`08-entrada-salida-y-recursos`) y sobre el **bloque opcional** `09-implementaciones`. Cualquier chat que produzca o edite un `.md` de este corpus la
sigue. Su objetivo es que todos los documentos se lean como escritos por la misma mano y
apunten al mismo lugar: **que puedas elegir la estructura correcta, justificar su coste en
voz alta y escribirla sin titubear delante de alguien que te está mirando teclear**.

Desciende de la guía de
[`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/prompts/guia-de-estilo-y-convenciones.md),
que a su vez desciende de la de
[`repaso-aws-entrevistas`](../../../cloud/01-aws/prompts/guia-de-estilo-y-convenciones.md).
Hereda el tono, la pedagogía del andamio, el vocabulario visual, la plantilla de capítulo,
las tres capas de respuesta y las reglas de enlace. **Diverge en cinco puntos declarados**
—§4.2, §4.4, §5, §7.4 y §10.1— por una razón de fondo: aquel corpus enseña a razonar un
sistema, y este enseña a **elegir y escribir el mecanismo**. Aquí sí hay código que
compila, sí hay cinco lenguajes, y el precio no se paga en latencia de red sino en tiempo,
memoria y casos borde. Un **sexto punto, de forma y no de fondo**, se añadió en la revisión
del 2026-10-05: **los diagramas de estructura van en Mermaid** (§3, "Diagramas"), a pedido
explícito del autor; las trazas, los arreglos con índices y las listas de decisión siguen en
`text`.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana
tiene una entrevista técnica con un editor compartido abierto y pasado mañana tiene que
elegir de verdad entre un `HashMap` y un `TreeMap` en producción.

> **Vigencia:** 2026-09-18.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca el patrón, elija la estructura,
justifique el coste y lo escriba —y pueda decirlo en voz alta mientras lo teclea.**

No enseñamos algoritmia "completa". El catálogo tiene cientos de entradas y recitar la
tabla de complejidades no hace a nadie mejor ingeniero; de hecho es la señal más clara de
que alguien estudió para el examen y no sabe cuándo la tabla miente. Repasamos el
vocabulario, los mecanismos y los matices que separan a quien entiende el modelo de coste
de quien memorizó la lista.

```text
Un curso de algoritmos → te enseña a demostrar la cota.
Este repaso            → te enseña a elegir la estructura, decir qué te cuesta,
                         y escribirla sin bug de índice delante de alguien.
```

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, elegir, costear o
escribir?** Si no, sobra. Aunque esté muy bien escrito y aunque sea cierto.

Y el corolario, repetido tantas veces como haga falta:

> Cada estructura cierra con un veredicto. Cada algoritmo se nombra con su coste en tiempo
> **y** en espacio. Cada decisión responde a "¿por qué esta y no la otra, y qué pierdo al
> elegirla?".

Una estructura descrita sin su coste no está explicada: está anunciada. Y un algoritmo que
no se puede escribir de memoria después de leer la sección está mal escrito para este
corpus, por correcta que sea la explicación.

### 1.1 Qué NO es este corpus

Tres cosas quedan fuera por decisión editorial, y se declaran aquí para que ningún
documento las prometa:

- **No es preparación de competitive programming.** No hay segment trees con lazy
  propagation, ni flujo máximo, ni geometría computacional. El criterio de inclusión es
  "sale en una entrevista de backend senior", no "sale en un contest".
- **No son demostraciones formales.** Se da la intuición de por qué una cota es la que es,
  y se cita dónde está la demostración. No se demuestra el teorema maestro: se usa.
- **No es un libro.** Compite con el calendario de alguien que tiene la entrevista cerca.
  El techo de longitud de §4.6 es real y se respeta.

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que ya
pasó por esto —la entrevista donde escribió la búsqueda binaria con el `mid` mal y lo vio
en directo, el `HashMap` que se degradó a lista porque el `hashCode` devolvía una
constante, el `Collections.sort` que lanzó `IllegalArgumentException` en producción y no en
test— y te lo explica con paciencia y sin solemnidad de manual universitario.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"cuando te pidan
  ordenar, lo primero que quieren saber es si necesitas estabilidad"*, *"si esto te suena a
  trámite académico, aguanta dos secciones"*. Nada de voseo, nada de "usted", nada de
  impersonal permanente ("se debe utilizar un montículo…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero
  abreviaturas de mensajería.
- **Humor mínimo y seco.** Como mucho **un desdramatizador por documento**, y si no fluye
  solo, se borra. Este corpus se lee antes de una entrevista: el registro es de repaso
  serio.
- **Honesto sobre la ceremonia.** Cuando una estructura sobra, se dice que sobra. *"Un trie
  para autocompletar mil productos es ceremonia: un `TreeMap` con `subMap` te da el prefijo
  y ya lo tienes escrito"* es contenido; *"el trie es eficiente para prefijos"* es un
  folleto.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es una
  sobregeneralización —"el `HashMap` es O(1)", "quicksort es O(n log n)", "la lista enlazada
  inserta en O(1)", "Dijkstra encuentra el camino más corto"— **se nombra la simplificación
  y se da la versión precisa**. Este es el recurso pedagógico central del corpus, por encima
  de la analogía y del ejemplo. La sección `## ⚠️ Errores frecuentes` de cada capítulo
  existe para esto.
- **Honesto sobre el precio.** Todo mecanismo se nombra con lo que cuesta, en las cuatro
  monedas de §4.2. No hay eufemismos tipo "es un poco más lento": se dice cuánto, en qué
  caso y contra qué se compara.
- **Sin absolutos falsos.** Nada de "siempre" ni "nunca" salvo cuando es literalmente
  cierto (*ninguna ordenación por comparación baja de Ω(n log n)*; *un `hashCode` que
  incumple el contrato rompe el `HashSet`, no lo ralentiza*).
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos. "Como
  para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar los algoritmos". Quien
  lee ya sabe por qué está repasando, y probablemente tiene la entrevista cerca.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código.
- **Los nombres de algoritmo, estructura y término del oficio se quedan en inglés** cuando
  son el nombre real de la cosa: *quicksort*, *merge sort*, *heap*, *hash table*, *trie*,
  *sliding window*, *two pointers*, *backtracking*, *memoization*, *load factor*, *open
  addressing*, *tail call*, *rolling hash*, *cache locality*. Traducirlos a la fuerza
  ("ordenamiento rápido", "tabla de dispersión", "ventana corrediza") confunde y no es lo
  que el lector va a oír en la entrevista ni leer en la bibliografía. Los que ya tienen
  traducción asentada —árbol, nodo, arista, cola, pila, montículo, recorrido, complejidad—
  se usan en español con naturalidad; lo importante es no inventar vocabulario.
  **La primera vez que aparece un término en inglés, se da su traducción entre
  paréntesis**; después ya no.
- **Markdown siempre.** Nada de HTML embebido. La única excepción es `<br/>` dentro de la
  etiqueta de un nodo Mermaid, que es sintaxis de Mermaid y no llega al HTML del documento.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de
  preferencia es diagrama (Mermaid o `text`, según la regla siguiente) → tabla → lista →
  párrafo *para exponer una relación entre cosas*. Pero el **porqué** de una decisión se escribe en prosa: una tabla no puede
  explicar por qué una lista enlazada pierde contra un array aunque la tabla de
  complejidades diga que gana.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos lados,
  es un buen golpe de ritmo. Tres seguidas son un telegrama, y el lector deja de encontrar
  el argumento porque no hay párrafo donde buscarlo. Regla práctica: **una frase aislada por
  sección, dos si la sección es larga**.
- **Diagramas: la estructura en Mermaid, el resto en `text`.** El diagrama es el recurso
  visual principal del corpus y se usa sin timidez. El formato lo decide lo que se dibuja:
  - **En ` ```mermaid `** todo lo que es **nodos y aristas**: árboles (BST, heap visto como
    árbol, trie, árbol de recursión), grafos, árboles de decisión que ramifican en más de un
    nivel, flujos entre componentes (proceso → núcleo → disco) y los mapas de lectura de los
    README.
  - **En ` ```text `** todo lo que es **posición o tiempo**: trazas de ejecución, arreglos con
    índices, ventanas y punteros sobre un arreglo, tablas de DP, salidas de consola y
    mediciones, pseudocódigo, y las listas planas `¿…? → X` de §9.1. Mermaid no alinea
    columnas ni índices, y una traza dibujada como grafo se lee peor que como texto.
  - **Bloque mixto, dos bloques.** Si un dibujo ASCII traía al lado su traza o su arreglo (el
    grafo con la tabla de Dijkstra, el heap con sus índices), el dibujo pasa a Mermaid y lo
    demás queda justo debajo en su propio bloque `text`, sin prosa entre los dos.
- **Convenciones de Mermaid.** Para que todos los diagramas parezcan de la misma mano:
  - **Solo `flowchart`**: `TD` para árboles, jerarquías, decisiones y mapas; `LR` para grafos,
    flujos entre componentes y decisiones que abren más de cuatro ramas desde un mismo nodo
    (en `TD` se vuelven tan anchas que GitHub las encoge hasta no leerse). Otros tipos (`sequenceDiagram`, `stateDiagram`) solo si el
    contenido es de verdad una secuencia de mensajes o una máquina de estados, y se declara.
  - **Etiquetas entre comillas dobles** siempre que lleven algo distinto de letras y números:
    `A["¿Los subproblemas se repiten?"]`. Salto de línea dentro de la etiqueta con `<br/>`.
    Comillas dentro de la etiqueta con `#quot;`.
  - **Identificadores de nodo cortos y en inglés o neutros** (`A`, `n5`, `root`, `fd3`); el
    texto que ve el lector va en la etiqueta, en español.
  - **Grafo no dirigido con `---`**, dirigido con `-->`; el peso va en la arista:
    `A ---|2| B`, `A -->|-10| B`. Las aristas de decisión llevan su respuesta: `-->|sí|`.
  - **Cuando el lado importa, se dice.** Mermaid no garantiza que el primer hijo quede a la
    izquierda, así que en un BST o en un trie cuyo dibujo depende del lado la arista se
    etiqueta `izq` o `der`. Un hijo vacío que el texto menciona se dibuja como nodo `∅`.
  - **Nada de color ni de tema**: sin `style`, `classDef`, `linkStyle` ni `%%{init}%%`. El
    diagrama tiene que leerse igual en el tema claro y en el oscuro de GitHub. Para resaltar
    un nodo se usa su forma (`{…}` para una decisión, `([…])` para un resultado o para el
    nodo que el texto señala) o el texto de la etiqueta.
  - **Las anotaciones van dentro del nodo o de la arista**, no en un nodo-nota unido con
    `-.-`: el nodo suelto descoloca el diagrama y en un árbol puede cambiar qué hijo queda a
    la izquierda. El "← esto es lo que falla" del ASCII pasa a la etiqueta del nodo afectado,
    tras un `<br/>`.
  - **Pequeños**: unos quince nodos como techo. Si pasa, se parte o se resume.
  - **Un grafo de ejemplo se define una sola vez** y se repite idéntico allí donde aparezca:
    el grafo A–F de `04-arboles-grafos` tiene la misma definición en todos los documentos.
  - **Los nombres coinciden.** Cuando el bloque `text` de una traza nombra los nodos del
    diagrama que tiene encima, los nombra con las mismas etiquetas, letra por letra.
  - **Se valida antes de cerrar.** Todo `.md` con bloques Mermaid se dibuja con
    `mmdc -i archivo.md -o salida.md` en un directorio de `zz-code/` creado para la sesión; un
    diagrama que no dibuja es un error, igual que un enlace roto.
- **Trazas de ejecución.** Cuando un algoritmo tiene un invariante que se ve mejor
  corriéndolo, se traza sobre una entrada de juguete de §5.3, paso a paso, en bloque `text`.
  Es el recurso que más rinde en este corpus y la razón por la que muchos capítulos se
  entienden sin ejecutar nada.
- **Tablas solo para comparar o mapear**, con tres a cinco columnas como norma: "array vs
  lista", "se dice / lo preciso", coste por operación, la tabla de los cinco lenguajes de
  §5.2. **Si necesitas explicar una celda, ya no es una tabla**: es una lista con subtítulos
  o un par de párrafos. Nunca se narra en tabla.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, **ninguno en las
  subsecciones `###`**, sin excepciones en este corpus. El emoji es funcional: señala de qué
  tipo es la sección (🎯 el problema, 🧱 estructura o mecanismo, ⏱️ coste y complejidad, ⚖️
  comparación, 🧭 criterio de elección, 🩺 diagnóstico, 🔭 dónde aparece en la vida real, 🪦
  lo que ya no se usa, ⚠️ errores frecuentes, 🧠 preguntas, 📚 referencias). Un documento que
  parece un teclado de emojis pierde autoridad.

---

## 4. 🎓 Pedagogía: "como para un bebé"

El principio se enuncia igual que en los corpus de los que desciende:

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar. Se
explica por qué `mid = (lo + hi) / 2` desborda, qué valor exacto tiene `lo` cuando el bucle
termina, y qué devuelve la función cuando el elemento no está. No se dice "la búsqueda
binaria es O(log n)" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la estructura, muestra el dolor que resuelve.
   *"Tienes 200 000 productos y por cada línea de pedido recorres la lista entera buscando
   el precio. Son 40 000 millones de comparaciones para facturar un día. El proceso nocturno
   ya no cabe en la noche."*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para
   usarlo hoy, no el capítulo completo del libro.
3. **El código o la traza que lo demuestra.** El fragmento más pequeño que fija el punto,
   con la viñeta que dice qué mirar en él.

Presentar la estructura antes que el problema produce gente que sabe recitar "el trie es
eficiente para prefijos" y no sabe cuándo *no* usarlo — que es exactamente lo que la
entrevista pregunta.

Por eso **`## 1. 🎯 El problema` es la sección de apertura obligatoria de todo capítulo**.

### 4.2 Ningún bloque de código queda sin desglose, y ningún mecanismo sin coste

**Divergencia declarada respecto de arquitectura.** Allí el código era ilustrativo y el
precio se pagaba en latencia, consistencia, operación y dinero. Aquí el código **es el
contenido** —el lector va a tener que escribirlo— y el precio se paga en otras monedas.

**Primera mitad: el código.** Ningún bloque aparece sin una frase antes que diga qué
demuestra y sin viñetas después que digan qué mirar en él. Un bloque `java` suelto es un
error de estilo igual que lo era un bloque `bash` suelto en el curso de AWS.

```java
// Búsqueda binaria: devuelve el índice, o -(punto de inserción) - 1 si no está.
int lo = 0, hi = datos.length - 1;
while (lo <= hi) {
    int mid = lo + (hi - lo) / 2;   // así no desborda: lo + hi puede pasarse de int
    if (datos[mid] < objetivo) lo = mid + 1;
    else if (datos[mid] > objetivo) hi = mid - 1;
    else return mid;
}
return -(lo + 1);
```

- Fíjate en **`lo + (hi - lo) / 2`**: con `(lo + hi) / 2` y arreglos de más de mil millones
  de elementos la suma desborda `int` y el índice sale negativo. Es el bug que estuvo nueve
  años en la JDK.
- Fíjate en **qué vale `lo` al salir**: es el punto de inserción, y por eso la firma puede
  devolver información útil en vez de un simple `-1`.
- El `hi` es **inclusivo** (`length - 1`) y por eso la condición es `<=`. Mezclar el
  convenio inclusivo con el exclusivo es el origen del 90 % de los off-by-one.

Ese nivel es el estándar. Y los bloques se mantienen **mínimos**: el bucle y las tres líneas
que importan, nunca una clase completa con su `main`. Si un bloque introduce tres cosas
desconocidas, se parte en tres bloques.

**Segunda mitad: el coste.** Toda afirmación de beneficio lleva su contrapartida en la misma
sección, en las cuatro monedas de la algoritmia:

```text
tiempo · espacio · legibilidad · casos borde
```

*"El `HashMap` te da acceso en O(1) amortizado, y lo pagas con memoria extra por el factor
de carga, con orden de iteración impredecible, con un rehash que es O(n) y cae en la
inserción que te toque, y con la obligación de mantener el contrato `equals`/`hashCode`"*
está completo. *"El `HashMap` es O(1)"* no lo está.

> ⚠️ **Advertencia.** La moneda que más se olvida es **casos borde**. Un algoritmo que es
> más rápido pero falla con el arreglo vacío, con un solo elemento, con duplicados o con
> `Integer.MIN_VALUE` no es más rápido: está mal. En entrevista, nombrarla tú antes de que
> te la pregunten vale más que la optimización.

### 4.3 Explica el porqué, no solo el cómo

Una regla sin justificación es una regla que el lector no puede adaptar cuando su caso real
difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media línea entre
paréntesis: por qué el `heapify` de abajo hacia arriba es O(n) y no O(n log n), por qué el
factor de carga por defecto es 0.75 y no 0.9, por qué Dijkstra no admite pesos negativos.

Cuando el porqué es histórico y no técnico —que en algoritmia pasa seguido— se dice también:
*"quicksort se impuso sobre merge sort en los ochenta porque la memoria era cara y el
segundo necesita un arreglo auxiliar; hoy la memoria es barata y TimSort la gasta sin
complejos"*.

### 4.4 Ancla en la librería estándar, no en la pizarra

**Divergencia declarada respecto de arquitectura**, que anclaba todo en Spring. Aquí el
anclaje es **la librería estándar del lenguaje**, y el corpus lo hace **en el mismo párrafo
en que introduce el concepto**:

- Un heap binario es `PriorityQueue` en Java y `heapq` en Python.
- Un árbol rojo-negro es `TreeMap`, y es también lo que hay dentro de un `HashMap` cuando un
  bucket se degrada.
- La búsqueda binaria de libro es `Arrays.binarySearch` y `bisect_left`, y ambas devuelven
  el punto de inserción.
- El orden topológico viene hecho en Python: `graphlib.TopologicalSorter`.
- La memoización es `@functools.cache` en Python y un `HashMap` a mano en Java.

Un concepto que no tiene equivalente en ninguna librería estándar —un trie, el algoritmo de
Kruskal— se explica igual, **pero se declara que no lo tiene y se dice quién lo trae**
(`networkx` en Python, JGraphT en Java). Lo que no se hace es dejarlo flotando.

Este anclaje tiene un motivo de entrevista, no de comodidad: **la respuesta cara casi
siempre es "no lo implemento, uso esto"**, y la segunda parte de la respuesta cara es saber
implementarlo igual porque te lo van a pedir.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo
dónde se rompen. Una tabla hash se parece a un archivador con cajones *hasta que descubres
que el cajón se reorganiza entero cuando se llena al 75 %*. Una analogía que no se cierra
genera bugs conceptuales que aparecen tres capítulos después.

Cuidado especial con las cuatro más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **O grande no es velocidad** (es cómo crece, y para n pequeño la constante manda);
- **una lista enlazada no "inserta en O(1)"** (inserta en O(1) *si ya tienes el nodo*, y
  llegar a él es O(n));
- **el `HashMap` no es O(1)** (es O(1) amortizado y con buen `hashCode`; con uno malo es
  O(n), y desde Java 8 O(log n) si las claves son comparables);
- **recursión no es elegancia gratis** (cada llamada es un marco de pila, y la JVM no
  elimina la recursión de cola).

### 4.6 Densidad calibrada, con techo de longitud

- **Banda objetivo: 200 a 350 líneas por capítulo.** Un capítulo que pasa de 400 se poda o
  se parte, y la decisión se declara en el README del bloque.
- Un concepto nuevo por vez.
- Repetir lo importante está bien. Los conceptos que sostienen el corpus —el coste
  amortizado, la localidad de caché, el invariante de bucle, qué pasa cuando el elemento no
  está— reaparecen con otras palabras. La repetición espaciada funciona; la enciclopedia no.
- Ninguna sección supera las dos pantallas sin un diagrama, una tabla, un bloque de código,
  una traza o un veredicto.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2). Por
  definición, los solucionarios y los documentos de `09-implementaciones`.

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto se ve en `03`"*, *"el Union-Find está en
`04-arboles-grafos`"*— tiene que cerrarse en algún documento del corpus, y con enlace real.
Un pendiente que nunca se resuelve es ruido y el lector deja de confiar en las promesas del
texto.

**Mientras un documento no exista, el enlace apunta al README de su bloque**, nunca a un
archivo que no está escrito. Un enlace roto dentro del propio corpus es peor que un enlace
externo caído: el externo tiene disculpa, el interno no.

---

## 5. 💻 Idioma del código y los cinco lenguajes

> **Regla normativa: el nombre canónico del algoritmo y de la estructura va en inglés; las
> variables de dominio van en español; los comentarios van siempre en español.**

**Divergencia declarada respecto de arquitectura.** Allí todo el modelo iba en español
porque el contenido *era* el dominio y el corpus predicaba lenguaje ubicuo. Aquí el
contenido es **algorítmico y sin dominio**: `siftDown`, `lowerBound`, `visited` y `parent`
son los nombres que el lector va a leer en toda la bibliografía y va a teclear en la
entrevista. Traducirlos a `hundir`, `cotaInferior` y `visitados` le haría un flaco favor.
Cuando el ejemplo **sí** necesita dominio, ese dominio va en español y se toma de §5.3.

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de algoritmo y estructura | Inglés (nombre canónico) | *quicksort*, *heap*, *trie*, *union-find* |
| Funciones y variables del algoritmo | Inglés | `siftDown()`, `lo`, `hi`, `mid`, `visited`, `dist`, `parent` |
| Tipos y métodos de la librería estándar | Inglés (son API real) | `PriorityQueue`, `heapq.heappush`, `Comparator` |
| Clases y campos cuando hay dominio | **Español** | `Pedido`, `Producto`, `precio`, `fechaDeAlta` |
| Comentarios dentro del código | Español | `// así no desborda` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos del oficio consolidados | Inglés sin traducir | *cache locality*, *load factor*, *amortized* |

### 5.1 Los cinco lenguajes y su reparto

El corpus compara **cinco lenguajes, siempre en este orden**: **Java · Python · JavaScript ·
TypeScript · Go**. El orden es fijo en todas las tablas y en todos los bloques de código, y
no se altera aunque en un capítulo concreto uno de ellos sea más interesante.

Cada uno tiene un papel declarado, y el papel explica cuánto espacio recibe:

| Lenguaje | Papel en el corpus | Cuánto espacio |
|---|---|---|
| **Java** | El lenguaje del perfil base del corpus. Se implementa **a pie**: es lo que te van a pedir que escribas en el editor compartido. | El grueso |
| **Python** | El contraste: casi todo **ya viene hecho** (`heapq`, `bisect`, `collections`, `graphlib`, `functools.cache`). Enseña la respuesta cara: "no lo implemento, uso esto". | Alto en estructuras |
| **JavaScript** | El lenguaje donde **falta lo obvio**: no hay heap, no hay deque, no hay ordenación numérica por defecto. Sus ausencias enseñan. | Medio |
| **TypeScript** | No cambia el runtime: aporta **qué garantiza el tipo y qué no**. Solo aparece cuando el sistema de tipos cambia la respuesta. | Bajo, y declarado |
| **Go** | El contraste más fuerte: strings como **bytes**, `rune` para code points, genéricos solo desde 1.18, `sort` con interfaz y `slices` desde 1.21. | Medio |

**TypeScript solo aparece cuando aporta.** Repetir el bloque de JavaScript con anotaciones
de tipo no aporta: cuando ese sea el caso, la fila de la tabla dice *"igual que JS"* y no se
escribe el bloque. Esto es una regla, no una licencia para omitirlo por pereza: cuando el
tipo **sí** cambia la respuesta —genéricos con `extends`, tipos literales como claves,
`readonly` frente a inmutabilidad real— se escribe y se explica.

### 5.2 La tabla comparativa de los cinco

Cuando un capítulo compara el comportamiento de los cinco lenguajes, el formato es fijo:
una tabla con el lenguaje en la primera columna, el orden de §5.1, y **una fila por
lenguaje, nunca una columna por lenguaje** (cinco columnas no caben legibles).

```markdown
| Lenguaje | Qué te da | El detalle que muerde |
|---|---|---|
| **Java** | `PriorityQueue`, min-heap | No es estable; `poll()` con empates no garantiza orden |
| **Python** | `heapq` sobre una lista | Solo min-heap: para max, se niegan las claves |
| ...
```

**Nunca más de tres columnas además del lenguaje.** Si necesitas cuatro, el contenido no es
una tabla: son cinco subsecciones.

### 5.3 Datos de ejemplo estables

El equivalente aquí de los dominios de ejemplo del corpus de arquitectura. **No se inventan
datos nuevos por capítulo.** Una traza se sigue mucho mejor cuando el arreglo es el mismo
que el lector ya vio dos capítulos atrás.

**Arreglo de juguete para ordenación y búsqueda:**

```text
[5, 2, 9, 1, 5, 6]        sin ordenar, con un duplicado a propósito (prueba la estabilidad)
[1, 2, 5, 5, 6, 9]        el mismo, ordenado
```

**Cadena de juguete para algoritmos de texto:**

```text
texto:  "abracadabra"
patrón: "abra"           aparece en 0 y en 7, y comparte prefijo con su propio sufijo
```

**Grafo de juguete**, dirigido y con pesos, el mismo para BFS, DFS, topológico y Dijkstra:

```text
     A ──2── B ──3── D
     │       │       │
     4       1       2
     │       │       │
     C ──7── E ──5── F
```

**Cuando el ejemplo necesita dominio de negocio**, se toman los de
[`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/prompts/guia-de-estilo-y-convenciones.md):
comercio electrónico por defecto (`Pedido`, `Producto`, `Cliente`, `LineaPedido`), banca
cuando hacen falta reglas reguladas (`Cuenta`, `Transferencia`). Mantener los mismos nombres
que el corpus hermano no es capricho: quien estudia los dos no tiene que recalibrar.

**Nunca uses `foo`, `bar`, `arr`, `tmp`, `MyClass` ni `doSomething()`.** Un nombre sin
significado destruye la traza: si el arreglo se llama `arr` y el auxiliar `tmp`, el lector no
puede seguir qué pasó a cuál.

---

## 6. 🧱 Plantilla de los capítulos (`NN-tema.md`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — qué cubre el documento en una o dos líneas, qué asume
   leído con enlace, y **`Vigencia:`** con la fecha en que se verificaron los enlaces. Ese
   campo es obligatorio: quien abre `03` sin pasar por el README tiene que saber qué tan
   reciente es lo que lee.
3. **Índice de salto rápido** — solo si el documento pasa de ~400 líneas (§6.2).
4. **`## 1. 🎯 El problema`** — apertura obligatoria. El dolor antes que el nombre (§4.1).
5. **Secciones `##` numeradas**, una por concepto, con emoji funcional. **Numeración arábiga
   continua**, incluido el problema, que siempre es la `1`.
6. **`## N. ⏱️ La tabla de costes`** — obligatoria en todo capítulo que presente estructuras
   o algoritmos alternativos. Es la tabla de complejidad en tiempo y espacio, con una
   columna final de **"lo que la tabla no dice"**, que es donde va la localidad de caché, la
   constante oculta y el caso degenerado. Una tabla de complejidades sin esa columna es
   exactamente el material que produce candidatos que eligen mal.
7. **`## N. 🧭 Cómo se elige`** — recomendada en todo capítulo que presente alternativas
   entre las que hay que decidir. Es una lista de decisión `¿…? → X` en bloque `text` (§9.1),
   seguida de la frase que se dice en voz alta. Si la decisión ramifica en más de un nivel
   —una pregunta cuya respuesta abre otras preguntas—, va como `flowchart TD` de Mermaid (§3).
8. **`## N. 🔭 Dónde aparece de verdad`** — recomendada. Dónde se topa un backend senior con
   esto fuera de una entrevista: el índice B+tree de Postgres, el heap del scheduler, el
   orden topológico del arranque de beans de Spring, el grafo de dependencias de Maven, el
   rolling hash de `rsync`. Es la sección que convierte "me lo estudié" en "lo he visto".
9. **`## ⚠️ Errores frecuentes`** — obligatoria. Tabla de dos columnas, **"Se dice" contra
   "Lo preciso"**, con entre cinco y ocho entradas. Es donde se cumple la regla de §2 sobre
   nombrar las sobregeneralizaciones, y es de las secciones que más rinden del corpus.
10. **`## 📚 Para profundizar`** — cierre obligatorio (§10), máximo ocho entradas.
11. **`## 🧠 Preguntas`** — cierre obligatorio, sin respuestas visibles (§8).
12. **Pie de navegación** — una línea con **Anterior**, **Siguiente** y **Relacionado**.

### 6.1 El patrón fijo de cada concepto

Dentro de una sección `##` de concepto, el orden no varía. **Es el punto donde más diverge
del corpus de arquitectura**, porque incorpora el coste como paso obligatorio:

```text
Qué es      → la definición mínima, en una o dos frases
Cómo va     → el mecanismo: el bucle, el invariante, la traza
Cuánto      → tiempo y espacio, con el caso peor Y el caso real. NUNCA se omite.
Cuándo sí   → los casos donde se paga solo
Cuándo no   → los casos donde es ceremonia. NUNCA se omite.
Veredicto   → la frase que resume el criterio, en blockquote
```

**"Cuánto", "Cuándo no" y "Veredicto" son obligatorios**, y son lo que distingue a este
corpus de un tutorial. Una estructura sin "cuándo no" sugiere que siempre se usa, que es
falso para prácticamente todo lo que hay en el temario. La forma del veredicto:

```markdown
> **Veredicto:** la lista enlazada gana en la pizarra y pierde en el perfilador. Úsala
> cuando necesites splice en O(1) con el nodo en la mano; para todo lo demás, `ArrayList`.
```

Las secciones que no presentan un concepto elegible —el problema, la tabla de costes, el
árbol de decisión, los errores frecuentes— no llevan veredicto.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [01](#01--complejidad-y-o-grande) · [02](#02--tdas-contrato-e-implementación) ·
[05 — escenarios](#05--simulación-problemas-de-pizarra)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio, guion
o guion bajo —lo que se lleva por delante el punto de la numeración, el emoji, los backticks
y los paréntesis— y por último los espacios restantes se convierten en guiones. Cada carácter
borrado **deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Montículo binario` | `#2--montículo-binario` |
| `## 4. ⏱️ La tabla de costes` | `#4--la-tabla-de-costes` |
| `## 🧠 Preguntas` | `#-preguntas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza por
guion**. Verifica las anclas al escribirlas.

### 6.3 Excepciones declaradas a la plantilla

- **`README.md` de cada bloque** — índice, orden de lectura, mapa mental y la sección "Qué NO
  está aquí" que remite a los otros bloques.
- **`NN-simulacion-de-entrevista.md`** — el examen del bloque (§7.2).
- **`NN-respuestas.md`** — el solucionario (§7.3). No lleva preguntas propias, ni
  referencias, ni errores frecuentes.
- **`09-implementaciones/`** — el bloque opcional (§7.4), que lleva las soluciones inline y
  no alimenta ningún solucionario.

---

## 7. 📐 Los tipos de documento

Cada bloque del hilo principal tiene exactamente tres tipos de documento y ningún otro. El
bloque `09-implementaciones` es la cuarta y última excepción, declarada en §7.4.

**No hay laboratorio contra ninguna nube ni contra ningún servicio.** Todo lo de este corpus
corre en local, en un archivo, en segundos. Esa es la razón por la que `09-implementaciones`
puede existir aquí y no podía existir en el corpus de arquitectura.

### 7.1 Capítulos `NN-tema.md`

El grueso del corpus. Siguen la plantilla de §6 sin desviaciones. Son **independientes entre
sí en lectura** pero acumulativos en vocabulario: cada uno declara en su encabezado qué asume
leído, y no vuelve a explicar lo que ya explicó otro. En particular, **`01-fundamentos/01`
es dueño único de la notación O grande** y ningún otro capítulo la redefine.

### 7.2 Simulación `NN-simulacion-de-entrevista.md`

El examen del bloque, y el documento que más se parece a la entrevista real. Lleva:

- **Una sección de método** que fija cómo se usa: cronómetro, en voz alta, tecleando de
  verdad, y solo después el solucionario.
- **Preguntas `S#` transversales**, agrupadas en bloques temáticos que cruzan capítulos.
  Entre 30 y 45. Incluyen un bloque final de **"las que descolocan"**: las de criterio
  personal, las de conflicto con el entrevistador, las de "esto no se resuelve con el
  algoritmo que estás pensando".
- **Problemas de pizarra**, entre cuatro y seis, de veinte minutos y tecleados. **Cada
  problema se elige para forzar una decisión distinta** y lo declara explícitamente en una
  línea `**Fuerza:**`. Uno de ellos, obligatoriamente, es un caso donde **la respuesta
  correcta es la fuerza bruta** porque n es pequeño y el código claro vale más.
- **Las frases que hay que tener listas** como cierre: dos o tres, en blockquote, que
  resumen el bloque y sirven de ancla cuando el lector se queda en blanco.

Las `S#` no llevan respuesta propia en el solucionario si ya están cubiertas por una pregunta
de capítulo: el solucionario lo declara y remite. Los problemas de pizarra **sí** llevan
solución desarrollada —enunciado, fuerza bruta, solución buena, complejidad, casos borde—
porque son ejemplos resueltos y no autochequeo de memoria.

### 7.3 Solucionario `NN-respuestas.md`

Uno por bloque, y es el documento que hace útil a todo lo demás: **es lo que permite estudiar
sin ver la respuesta al lado de la pregunta**.

- Abre con índice de salto rápido, siempre: pasa de 400 líneas por definición.
- Se organiza por capítulo, con encabezado `# NN — Tema` por cada uno.
- **El enunciado se copia literalmente**, no se parafrasea: es lo que permite localizar una
  respuesta buscando el texto de la pregunta.
- Formato de cada entrada: `**NN → P.** Enunciado literal en negrita.`
- **Respuesta en tres capas, siempre las tres y en este orden** (§8.3).

### 7.4 El bloque opcional `09-implementaciones/`

**Divergencia declarada, y la única parte del corpus que está fuera del hilo principal.**
Existe porque un corpus de algoritmos sin código ejecutable sería deshonesto, y no está en el
hilo principal porque **nadie necesita leerlo para aprobar una entrevista**.

Reglas propias, que no aplican a ningún otro documento:

- **Todo documento abre declarando que es opcional**, en la primera línea del blockquote de
  encabezado, y dice qué capítulo del hilo principal cubre la teoría.
- **Las soluciones van inline**, no en un solucionario. No hay `🧠 Preguntas` en este bloque.
- **El código compila y corre, y se declara con qué versión.** Lo que se escribe aquí se ejecuta
  antes de publicarse, y el README del bloque lista las versiones exactas usadas y **qué lenguaje no
  se pudo ejecutar**, si es el caso. Publicar una salida esperada como si fuera real es la única
  falta grave de este bloque: si no se ejecutó, se dice.
- **Java implementa a pie; Python muestra lo prehecho.** Es el reparto de §5.1 llevado al
  extremo: el mismo problema resuelto dos veces, una construyendo y otra importando, con la
  comparación explícita de cuántas líneas y cuántos bugs se ahorran.
- **Ningún capítulo del hilo principal depende de este bloque.** Lo enlaza como "si quieres
  verlo implementado", nunca como "el resto está en".

---

## 8. 🧠 Preguntas y respuestas

**Todo el peso evaluador vive en las preguntas.** No hay sección de 🧪 Ejercicios en ningún
documento del hilo principal; los ejercicios prácticos, cuando los hay, viven en
`09-implementaciones` con su solución al lado, porque allí el lector tiene el editor abierto.

```text
capítulo             →  20 a 30 preguntas numeradas. Sin respuesta visible.
simulación           →  30 a 45 preguntas S# transversales + 4 a 6 problemas de pizarra.
solucionario         →  todas las respuestas, en tres capas, enunciado literal.
09-implementaciones  →  ejercicios con solución inline. No cuentan para el solucionario.
```

### 8.1 Las preguntas de capítulo

- **Cantidad: 20 a 30**, calibrada por cuántas cosas distintas enseña el capítulo y se pueden
  comprobar por separado — nunca por su longitud. Subir de 30 exige poder decir qué comprueba
  cada pregunta nueva que no comprobara ya otra.
- **Numeración arábiga continua dentro del capítulo**, reiniciada en cada capítulo.
- **Dificultad marcada al final del enunciado** con un solo emoji, siguiendo el formato de
  `preguntas-entrevista/` y del corpus de arquitectura, con los niveles adaptados a este
  temario:

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Definición o coste | Reproducir un concepto o dar la complejidad de algo que el capítulo enunció |
  | 🟡 | Distinción | Diferenciar dos estructuras o dos algoritmos que se confunden |
  | 🟠 | Decisión | Elegir entre alternativas y justificar el coste, o explicar un porqué no obvio |
  | 🔴 | Diseño o diagnóstico | Abierto: un algoritmo que diseñar, un código que corregir, un fallo que explicar |

- **Reparto orientativo:** alrededor de 25 % 🟢, 25 % 🟡, 30 % 🟠 y 20 % 🔴, con un escalón de
  margen. Un capítulo de vocabulario y coste —complejidad, TDAs— carga hacia 🟢 y 🟡; uno de
  decisión —ordenación, elección de estructura— carga hacia 🟠 y 🔴. **Que dos capítulos
  vecinos tengan idéntico reparto es señal de que el segundo se copió en vez de calibrarse.**
- **Orden: de menor a mayor dificultad.** El lector debe poder parar donde se le acabe el
  tiempo y haber cubierto lo esencial. Las 🔴 van al final, siempre.
- **Directas y verificables.** Cada pregunta tiene respuesta localizable en el propio capítulo
  o derivable de él. Nunca "reflexiona sobre…".
- **Las 🔴 piden un artefacto o una secuencia**, no una opinión: *"escribe el bucle y di qué
  vale `lo` al salir"*, *"da tres hipótesis en orden de probabilidad"*, *"traza el algoritmo
  sobre el grafo de juguete y di en qué paso se equivoca"*.
- **Al menos dos preguntas por capítulo comparan lenguajes**, porque es la aportación propia
  de este corpus frente a cualquier libro de algoritmos: *"¿qué devuelve `[10, 9, 1].sort()`
  en JavaScript y por qué?"*.
- **Sin respuesta en el documento.** Va todo al solucionario del bloque.

### 8.2 La regla de sincronía

**Quien agregue, elimine o reordene una pregunta refleja el mismo cambio en el solucionario
del bloque en la misma edición**, con el enunciado copiado literalmente. Un solucionario
desincronizado es peor que no tenerlo: el lector busca la respuesta 14 y encuentra la de otra
pregunta.

La comprobación es mecánica y se corre antes de cerrar:

```bash
# desde el directorio del bloque
for f in 0[1-9]-*.md; do
  case "$f" in *respuestas*) continue;; esac
  n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
  printf '%-45s %s\n' "$f" "$n"
done
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' *-respuestas.md   # debe igualar la suma
```

### 8.3 Las tres capas de la respuesta

Es lo que hace útil al solucionario, y no es negociable: **siempre las tres, siempre en este
orden, siempre con su emoji**.

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan. Una o dos frases.
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más". Tres a cinco frases.
🔬 El detalle   → para estudiar, no para decir en voz alta. El matiz, la excepción,
                  el número que solo usas si te aprietan.
```

- **La capa de 30 segundos se escribe como se diría**, no como se escribiría. Si no cabe en
  una respiración, está mal. En este corpus casi siempre empieza por la complejidad: *"O(n
  log n) en tiempo, O(n) en espacio, y es estable"*.
- **La capa de 2 minutos añade, no repite.** Si parafrasea la primera, sobra. Es donde va el
  mecanismo y el porqué.
- **El detalle es donde va la honestidad incómoda**: el caso degenerado, la constante que
  invierte el resultado para n pequeño, la diferencia entre lenguajes, el número que nadie
  recuerda.
- En las 🔴 de diseño, la capa de 2 minutos suele llevar un bloque de código mínimo o una
  traza, y el detalle enumera los casos borde que el entrevistador preguntará después.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

Vocabulario deliberadamente reducido, heredado de la guía de arquitectura sin cambios salvo
los que se indican.

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación,
ecuación corta o árbol de decisión. Se etiqueta antes con una línea breve: "Regla:", "Regla
mental:" o "Regla de entrevista:".

```text
¿Necesitas orden?          → TreeMap / sorted
¿Solo pertenencia?         → HashSet
¿El máximo, repetidas veces? → heap
```

### 9.2 Frase de respuesta correcta (blockquote)

Para la única frase que deberías decir en voz alta, normalmente después de mostrar la
simplificación incorrecta. Sirve igual para blindar contra la mala respuesta ("Nunca
respondas: > …") que para dar la buena ("Mejor: > …"). También admite etiqueta corta de
énfasis —"Regla importante:", "Punto importante:"— cuando lo que sigue es una única frase
definitoria.

El **veredicto** de §6.1 es un caso particular de este recurso y usa siempre la etiqueta
`**Veredicto:**`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento. **Como mucho uno por sección `##`, y nunca dos seguidos.**

- ⚠️ **Advertencia.** Ignorarlo produce una respuesta de entrevista objetivamente incorrecta,
  o un bug real. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco.** El matiz que casi nadie dice y que sube la nota de la respuesta.
- 🩺 **Diagnóstico.** Cómo se confirma o descarta la hipótesis: qué mirarías primero.
- ⏱️ **Coste.** La complejidad en tiempo y espacio cuando no es obvia, o cuando la cota
  teórica y el comportamiento real no coinciden. **Obligatorio la primera vez que un
  capítulo introduce una estructura cuyo coste amortizado difiere del caso peor.**
- 📝 **Contexto.** Por qué la respuesta "clásica" que el lector encontrará en fuentes viejas
  ya no aplica, o qué cambió en el lenguaje o la librería.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al cierre.

**Escala de dificultad 🟢🟡🟠🔴.** Se usa **solo** en el enunciado de las preguntas (§8.1).
Fuera de ahí no aparece.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques `text` de
comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌, de la escala de dificultad y de los emojis de encabezado de §3,
**no se usan otros emojis**. Nada de 🚨, 💸, ⭐ ni 🎉. Las excepciones declaradas son 🪦 para el
encabezado de la sección "lo que ya no se usa", 🔭 para "dónde aparece de verdad", y los tres
de las capas de respuesta ⏱️ 🗣️ 🔬 en los solucionarios.

### 9.4 Autopsia de un bug

El equivalente aquí de la "autopsia de una respuesta mala" del corpus de arquitectura, y el
recurso que mejor aprovecha que este corpus prepara código y no solo conversación. Cuando un
capítulo documenta un error de implementación frecuente, la estructura es:

1. **El código que escribe todo el mundo**, citado tal cual y sin caricaturizar.
2. **Por qué parece correcto.** Casi siempre pasa los casos que el candidato prueba, y
   reconocerlo es lo que hace creíble la corrección.
3. **La entrada que lo rompe.** Concreta, mínima, tecleable: el arreglo exacto, el valor
   exacto.
4. **El código correcto**, con la línea que cambió señalada.
5. **La generalización**, si la hay: qué clase de error es y dónde más aparece.

La tabla de `## ⚠️ Errores frecuentes` es la versión comprimida de esto, para los errores que
no merecen cinco pasos. Cuando un error sí los merece —el `mid` que desborda, el
`Comparator` que no cumple la transitividad, el `hashCode` sin `equals`, la mutación de una
clave dentro de un `HashSet`— se desarrolla en su propia sección.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos y orden de autoridad

**Divergencia declarada respecto de AWS/GCP**, que admitía solo documentación oficial del
proveedor, **y respecto de arquitectura**, cuyo orden de autoridad era bibliográfico puro.
Aquí hay dos fuentes canónicas a la vez: el **libro** para el algoritmo, que no cambia desde
hace treinta años, y la **documentación del lenguaje** para lo que tu librería estándar
realmente hace, que sí cambia. El cierre `## 📚 Para profundizar` admite, **en este orden y
marcando el tipo**:

1. **Libro**, con autor, título, editorial, año y **capítulo o sección concreta**. Sin URL:
   un libro se identifica por su ficha, no por un enlace que caduca. **Todo capítulo cita al
   menos uno**, y cuando hay uno que destaca se dice cuál: *"si solo lees uno de todo el
   bloque, lee este"*.
2. **Documentación oficial del lenguaje o de la librería estándar**, con URL específica:
   `docs.oracle.com`, `docs.python.org`, `developer.mozilla.org`, `go.dev`, `pkg.go.dev`,
   `typescriptlang.org`. Es la fuente que dice qué hace **tu** `sort`, no el `sort` del libro.
3. **Especificación o propuesta con autoridad**, cuando el detalle está ahí y no en la doc:
   `openjdk.org/jeps`, `docs.oracle.com/javase/specs`, `go.dev/ref/spec`, `unicode.org`.
4. **Referencia algorítmica establecida**, con URL por concepto: `cp-algorithms.com`,
   `algs4.cs.princeton.edu`, material de curso universitario publicado (`web.stanford.edu`,
   MIT OCW). Es el equivalente a la fuente primaria del corpus de arquitectura.
5. **Visualización interactiva**, marcada como tal: `visualgo.net`. Vale su entrada en los
   capítulos de estructuras, donde ver el árbol rotar enseña más que dos párrafos. **Máximo
   una por capítulo.**
6. **Tutorial aplicado** — GeeksforGeeks, Baeldung, Refactoring Guru. Van **al final y
   marcados como tutorial**, nunca mezclados con la fuente primaria. **Baeldung se cita por
   título entre comillas angulares y sin URL** (`Baeldung, «Guide to Java PriorityQueue»`):
   su CDN responde `403` a cualquier verificación automática, así que un enlace suyo no se
   puede comprobar por código de estado y la regla de abajo lo prohíbe.
7. **Video o curso en video**, solo por **canal o institución y título, sin URL**. Los
   enlaces de video se rompen y se reemplazan; el título se busca. Admitidos: MIT
   OpenCourseWare (*Introduction to Algorithms*, 6.006), Abdul Bari, WilliamFiset, NeetCode,
   Computerphile, Coursera (Sedgewick, *Algorithms Part I/II*).

**Máximo ocho entradas por capítulo.** Es un repaso, no una bibliografía.

**Los libros del canon de este corpus**, para que no se cite uno distinto en cada capítulo:

| Libro | Para qué, exactamente |
|---|---|
| Cormen, Leiserson, Rivest y Stein, *Introduction to Algorithms*, 4ª ed. (MIT Press, 2022) | La referencia. Se consulta por capítulo, no se lee entero. Para la demostración que aquí no está |
| Sedgewick y Wayne, *Algorithms*, 4ª ed. (Addison-Wesley, 2011) | El más legible, y el único del canon **con el código en Java**. El del sitio `algs4` |
| Skiena, *The Algorithm Design Manual*, 3ª ed. (Springer, 2020) | La parte I, para **elegir** el algoritmo. El "catálogo" de la parte II es oro para reconocer el problema |
| Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018) | Ítems 10–14: `equals`, `hashCode`, `toString`, `Comparable`. Lo que rompe las estructuras de Java |
| McDowell, *Cracking the Coding Interview*, 6ª ed. (CareerCup, 2015) | El formato de entrevista y los problemas clásicos. Para practicar, no para aprender |
| Aziz, Lee y Prakash, *Elements of Programming Interviews in Java* (2018) | Más duro que CtCI y con mejor Java. Para cuando CtCI se queda corto |

Reglas duras, heredadas sin cambios:

- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el
  nombre exacto de la página y se omite el enlace. Inventar una ruta plausible de
  `docs.oracle.com` es el error más caro de este corpus, porque parece correcta hasta que
  alguien la abre delante de un entrevistador.
- **Se comprueban por código de estado, no a ojo**, y en la misma edición en que se escriben.
  Aterrizar en la portada del sitio en vez de en la página concreta cuenta como roto.
- **Una URL por concepto**, específica. Si el capítulo explica `heapq`, el enlace es a la
  página de `heapq`, no a la portada de la documentación de Python.
- **`docs.oracle.com` fija la versión en la ruta.** Este corpus cita **Java 21** en todos los
  enlaces de la API (`/en/java/javase/21/docs/api/...`). No se mezclan versiones entre
  capítulos, y cuando el comportamiento cambió con la versión se dice en qué versión cambió.

### 10.2 Enlaces internos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo, con el número del documento en el texto visible:

  ```markdown
  ver [`03` — Búsqueda](03-busqueda.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  ver [`04` §3 — colisiones](04-hashing-y-tablas-hash.md#3--colisiones)
  ```

- **Entre bloques, con ruta relativa al bloque:**

  ```markdown
  ver [`04-arboles-grafos`](../04-arboles-grafos/)
  ```

- **Cada capítulo enlaza al menos a los dos capítulos con los que más se toca**, y cierra con
  el pie de navegación de §6, punto 12.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma
  edición.**

Verificación mecánica de enlaces internos, que se corre antes de cerrar:

```bash
# desde el directorio del bloque: archivos referenciados que no existen
grep -oh '](\([0-9]\{2\}-[^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done
```

### 10.3 Vigencia

El README de cada bloque declara la fecha de revisión general y **cada documento la repite en
su blockquote de encabezado**. Cuando un documento incorpora algo reciente —`slices` y
`maps` en la stdlib de Go, `Sequenced Collections` en Java 21, el `sort` estable por
especificación en JavaScript desde ES2019— se marca con 📝 en el propio texto, para que quien
repasa sepa que puede no coincidir con las respuestas "clásicas" de fuentes más viejas.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `01-fundamentos/01` establece que O grande
  describe crecimiento y no velocidad, `03-orden-busqueda/01` puede matizarlo con constantes
  reales, nunca contradecirlo.
- **Terminología estable.** Si `01` dice "caso peor", el resto del corpus no lo llama "peor
  caso" ni alterna con "worst case" sin motivo. Si `02` dice "TDA", no aparece "ADT" en otro
  capítulo.
- **Los datos de ejemplo de §5.3 mandan.** Cualquier desviación se declara en el documento que
  la introduce, con su porqué.
- **Un concepto tiene un solo dueño.** El capítulo que lo introduce lo explica entero; los
  demás lo usan y enlazan. El coste amortizado es de `01-fundamentos/01`; el contrato
  `equals`/`hashCode` es de `03-orden-busqueda/04`; la recursión es de `01-fundamentos/04` y
  la DP de `05-dp-y-tecnicas/01` la asume leída.
- **Los bloques no se repiten entre sí.** `01-fundamentos` da el vocabulario común; `02` a
  `05` lo asumen leído y profundizan. Cuando un bloque roza el territorio de otro, lo declara
  y enlaza en vez de duplicar.
- **El corpus no invade a sus hermanos.** La complejidad de una consulta SQL, el diseño de un
  índice o la elección de un broker son de
  [`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/); los detalles
  del lenguaje Java más allá de sus estructuras son de
  [`preguntas-entrevista/04-java-11-17.md`](../../../../preguntas-entrevista/04-java-11-17.md).
  Aquí se enlaza, no se duplica.
- **Fuentes de verdad, en orden:**
  1. **Esta guía y los demás documentos de `prompts/`**, que según la regla de precedencia de
     `CLAUDE.md` mandan sobre las normas por defecto del repositorio en todo lo que declaren
     explícitamente.
  2. **`CLAUDE.md` de la raíz**, para todo lo que esta guía no toca.
  3. **`README.md` del corpus**, para el alcance de los bloques.
  4. **`README.md` del bloque**, para orden de lectura y mapa.
  5. **Documentos ya publicados** — no se contradicen, se matizan.
  6. Decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

**Estructura**

- [ ] Sigue la plantilla de §6, o está declarado como excepción (README, simulación,
      solucionario, `09-implementaciones`).
- [ ] Encabezado con objetivo, qué asume leído **con enlace**, y **`Vigencia:`**.
- [ ] Índice de salto rápido si pasa de ~400 líneas (§6.2).
- [ ] Abre con `## 1. 🎯 El problema`, no con una definición (§4.1).
- [ ] Numeración `##` arábiga y continua; emoji funcional en `##`, **ninguno en `###`**.
- [ ] Cierra con pie de navegación: Anterior, Siguiente y Relacionado.

**Contenido**

- [ ] Cada concepto sigue **qué es → cómo va → cuánto → cuándo sí → cuándo no → veredicto**
      (§6.1), y **ninguno se queda sin coste, sin "cuándo no" ni sin veredicto**.
- [ ] Hay `## N. ⏱️ La tabla de costes` con su columna de "lo que la tabla no dice".
- [ ] Toda afirmación de beneficio lleva su precio en tiempo, espacio, legibilidad o casos
      borde (§4.2).
- [ ] Ningún bloque de código sin frase antes y viñetas después; bloques mínimos.
- [ ] Todo concepto anclado en la librería estándar donde exista anclaje, y declarado cuando
      no (§4.4).
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una
      sobregeneralización (§2).
- [ ] Hay sección `## ⚠️ Errores frecuentes` con tabla "Se dice / Lo preciso", 5–8 entradas.
- [ ] Hay `## N. 🧭 Cómo se elige` si el capítulo presenta alternativas.
- [ ] Datos de ejemplo de §5.3 respetados; sin `foo`, sin `arr`, sin `tmp`.
- [ ] Orden de lenguajes de §5.1 respetado; TypeScript solo donde aporta, y declarado.
- [ ] Entre 200 y 350 líneas. Si pasa de 400, se poda o se parte.

**Forma**

- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, sin celdas que necesiten explicación.
- [ ] Árboles, grafos, flujos y decisiones de varios niveles en Mermaid; trazas, arreglos con
      índices, tablas de DP y listas `¿…? → X` en `text` (§3). Sin `style` ni `classDef`, y
      todos los diagramas dibujados con `mmdc` sin error en esta edición.
- [ ] Como mucho un callout por sección `##`, nunca dos seguidos, y solo los de §9.3.
- [ ] Nombres canónicos en inglés, dominio y comentarios en español (§5).

**Evaluación**

- [ ] Entre 20 y 30 preguntas, graduadas 🟢🟡🟠🔴, **ordenadas de menor a mayor dificultad**,
      sin respuesta visible (§8.1).
- [ ] Al menos dos preguntas comparan lenguajes.
- [ ] Reparto de dificultad distinto al del capítulo vecino.
- [ ] **Si tocaste alguna pregunta, actualizaste el solucionario del bloque en la misma
      edición** (§8.2), con el enunciado copiado literal.
- [ ] En el solucionario: las tres capas ⏱️ 🗣️ 🔬 en todas las respuestas, sin excepción.

**Referencias y enlaces**

- [ ] `## 📚 Para profundizar` presente, máximo ocho entradas, ordenadas por autoridad
      (§10.1), con al menos un libro con capítulo concreto.
- [ ] Todas las URLs verificadas por código de estado **en esta edición**.
- [ ] Java citado siempre contra la API de Java 21; sin mezclar versiones.
- [ ] Baeldung citado por título sin URL; video citado por canal y título sin URL.
- [ ] Al menos dos enlaces internos a los capítulos vecinos, y ningún enlace interno roto.
- [ ] Ningún enlace a un documento que todavía no existe: mientras tanto, al README del
      bloque (§4.7).

**Coherencia**

- [ ] No contradice ningún documento anterior, y la terminología coincide con la ya fijada
      (§11).
- [ ] Ningún bucle abierto sin cerrar: toda promesa de "esto se ve en X" tiene su enlace.
