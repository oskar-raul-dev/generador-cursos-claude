# 06 — Simulación de entrevista

> El examen del bloque. Treinta y seis preguntas `S#` transversales que cruzan los cuatro
> capítulos, más cinco problemas de pizarra completos. Se contesta **en voz alta y
> cronometrado**, y los problemas se **teclean**: saber algo y saber escribirlo mientras
> alguien te mira son dos habilidades distintas, y la entrevista mide la segunda.
> Asume leídos [`01`](01-complejidad-y-o-grande.md) a
> [`05`](05-bits-y-aritmetica-binaria.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA, de pie si puedes. Grábate.
3. Los problemas de pizarra se TECLEAN, en un editor sin autocompletado, en 20 minutos.
4. Solo después vas a `07-respuestas.md`.
5. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** el objetivo no es acertar. Es detectar **qué sabes pero no puedes articular**,
> que es lo que se pierde en una entrevista real.

Los problemas de pizarra se trabajan distinto: veinte minutos, tecleando, narrando en voz
alta lo que haces. Su solución **sí** está desarrollada en [`06`](07-respuestas.md), porque
son ejemplos resueltos y no autochequeo de memoria.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Complejidad y criterio

**S1.** Escribes un método y el entrevistador pregunta "¿cuál es la complejidad?". ¿Qué
contestas exactamente, y cuántas cosas nombras? 🟢

**S2.** ¿Por qué un algoritmo O(n) puede ser más lento que uno O(n log n) sobre datos
reales? 🟡

**S3.** Te dicen "hasta 10⁵ elementos". ¿Qué acabas de aprender sobre la solución
esperada? 🟡

**S4.** ¿Qué diferencia hay entre coste amortizado, caso medio y caso peor? Da un ejemplo de
cada uno. 🟠

**S5.** Un compañero propone cambiar `ArrayList` por `LinkedList` "porque inserta en O(1)".
¿Qué le preguntas antes de aceptar? 🟠

**S6.** ¿Cuándo eliges deliberadamente el algoritmo con peor complejidad? 🟠

**S7.** Te piden optimizar un método y no tienes perfilador. ¿Por dónde empiezas y qué NO
haces? 🔴

### Bloque B — Elección de estructura

**S8.** "¿Qué estructura de datos usarías?" Da el método de respuesta, no una estructura. 🟡

**S9.** Necesitas saber si un elemento ya apareció, sobre diez millones de elementos. Elige y
di qué pagas. 🟡

**S10.** Necesitas los 10 mayores de un flujo continuo de un millón de eventos. Elige y
justifica. 🟠

**S11.** ¿Cuándo `TreeMap` vence a `HashMap` aunque sea O(log n) contra O(1)? 🟠

**S12.** Te piden una caché LRU. ¿Cuál es la respuesta de cinco líneas y cuál la de cincuenta,
y cuándo das cada una? 🟠

**S13.** Diseña la estructura de un carrito: orden de agregado, acceso por ID, total. 🟠

**S14.** Te dicen que en su sistema usan un `HashMap` compartido entre hilos sin sincronizar y
"nunca ha fallado". ¿Qué respondes? 🔴

### Bloque C — Secuencias y técnicas

**S15.** Enumera las cuatro técnicas sobre secuencias y la palabra del enunciado que delata a
cada una. 🟡

**S16.** ¿Por qué dos punteros y pila monótona son lineales si ambos parecen anidados? 🟠

**S17.** ¿Cuándo dejan de servir las sumas de prefijos? 🟠

**S18.** Tienes un arreglo sin ordenar y te piden pares que sumen X. Da dos soluciones con
distinta complejidad y di cuál eliges. 🟠

**S19.** ¿Por qué `int[]` puede ser diez veces más rápido que `List<Integer>` si ambos son
O(n)? 🟠

**S20.** Te dan código que hace `lista.remove(0)` dentro de un bucle. Explícalo y arréglalo de
dos formas distintas. 🔴

### Bloque D — Recursión

**S21.** ¿Qué tres cosas dices sin que te las pidan después de escribir una función
recursiva? 🟢

**S22.** ¿Cuánta pila consume una recursión sobre un árbol de un millón de nodos? Depende de
algo: ¿de qué? 🟡

**S23.** ¿Por qué escribir recursión de cola en Java no ahorra memoria? 🟠

**S24.** Producción lanza `StackOverflowError`. Da tu secuencia de diagnóstico. 🟠

**S25.** ¿Cuándo conviertes una recursión en iteración, y con qué estructura? 🟠

**S26.** Explica la diferencia entre backtracking y programación dinámica a alguien que
confunde los dos. 🟠

### Bloque E — Los cinco lenguajes

**S27.** ¿Qué devuelve `[10, 9, 1].sort()` en JavaScript y por qué? 🟡

**S28.** ¿Qué lenguajes de los cinco garantizan el orden de iteración de su mapa, y qué
garantiza cada uno? 🟠

**S29.** ¿Por qué simular una cola con `push`/`shift` en JavaScript es un bug de
rendimiento? 🟠

**S30.** Ninguno de los cinco salvo Java trae un mapa ordenado por clave en la stdlib. ¿Cómo
lo resuelves en Python y en Go? 🟠

**S31.** ¿Qué hace `b := a[1:3]` en Go y qué bug produce con más frecuencia? 🟠

**S32.** Un candidato dice "en Python no me preocupo, `list` es una lista enlazada". ¿Qué
corriges? 🟠

### Bloque F — Las que descolocan

**S33.** ¿Cuándo has elegido la estructura equivocada y cómo te diste cuenta? 🔴

**S34.** El entrevistador afirma que tu solución es O(n²) y tú crees que es O(n). ¿Cómo
manejas el desacuerdo? 🔴

**S35.** "¿Para qué sirve saber esto si nunca implementas un heap a mano?" Responde. 🔴

**S36.** Te piden optimizar un algoritmo que ya es O(n log n) y tarda 40 minutos sobre 10
millones de registros. ¿Dónde buscas? 🔴

---

## 3. 🧪 Problemas de pizarra

Veinte minutos cada uno, tecleando y narrando. La solución completa —fuerza bruta, solución
buena, complejidad y casos borde— está en [`06`](07-respuestas.md).

### P1 — El precio del producto

**Fuerza:** elegir la estructura correcta antes de escribir una línea.

Tienes un catálogo de 200 000 productos y 40 000 líneas de pedido a facturar. El código
actual busca cada precio recorriendo el catálogo y tarda seis horas. Escribe la solución,
di su complejidad antes y después, y qué memoria extra consume.

Cuando lo tengas, responde a la repregunta: *"¿y si el catálogo no cabe en memoria?"*.

### P2 — Subarreglo de suma máxima

**Fuerza:** reconocer la técnica y dar la fuerza bruta primero.

Dado un arreglo de enteros que pueden ser negativos, encuentra la suma máxima de un
subarreglo contiguo. Empieza por la solución O(n²) y dila en voz alta antes de optimizar.

Repregunta obligatoria: *"¿y si todos son negativos?"*.

### P3 — La cola de un millón de eventos

**Fuerza:** que la respuesta correcta es la fuerza bruta.

Necesitas procesar 500 eventos de configuración en orden de llegada, una sola vez al
arrancar la aplicación. Un compañero propone montar un `ArrayDeque` con un pool de objetos
para evitar asignaciones. Decide, implementa y defiende tu decisión.

### P4 — Paréntesis válidos

**Fuerza:** el TDA correcto, y los casos borde que casi todos olvidan.

Dada una cadena con `(`, `)`, `[`, `]`, `{` y `}`, di si está balanceada. Escríbelo, y
después enumera en voz alta cada caso borde antes de que te lo pregunten.

Repregunta: *"¿cómo lo cambias para que además diga la posición del primer error?"*.

### P5 — Combinaciones de un menú

**Fuerza:** el esqueleto de backtracking, con poda y con copia.

Dado un menú de n platos con su precio y un presupuesto, genera todas las combinaciones de
platos distintos cuyo total no supere el presupuesto. Escribe el esqueleto completo.

Repregunta: *"¿hasta qué n aguanta esto, y qué harías si n fuera 200?"*.

---

## 4. 🧠 Las frases que hay que tener listas

Tres, para cuando te quedes en blanco. Las tres son ciertas, cortas y compran tiempo:

> **Sobre complejidad:** *"O grande me dice si aguanta cuando crece, no si es rápido hoy. Para
> n pequeño la constante decide, y por eso el `ArrayList` gana casi siempre."*

> **Sobre estructuras:** *"Primero decido el contrato —qué operaciones necesito— y después la
> implementación —cuánto me cuestan—. Si no sé el patrón de acceso, `ArrayList` y `HashMap`
> son los defectos correctos."*

> **Sobre recursión:** *"Caso base, el problema se reduce, y la pila es O(profundidad). En
> Java son unos diez mil marcos y en Python mil, así que si la profundidad crece con los
> datos, lo convierto en iteración."*

---

**Anterior:** [`05` — Bits y aritmética binaria](05-bits-y-aritmetica-binaria.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`05-dp-y-tecnicas/03` — Protocolo de pizarra](../05-dp-y-tecnicas/03-protocolo-de-pizarra.md)
