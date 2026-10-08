# 03 — Estructuras de datos y concurrencia

> Qué le pasa a una estructura de datos cuando hay varios hilos, por qué sincronizar cada método
> **no** la hace segura, cuánto cuesta protegerla de verdad, y los cinco modelos de concurrencia de
> los cinco lenguajes — que son cinco respuestas distintas a la misma pregunta.
> Asume leídos [`01-fundamentos/02` — TDAs](../01-fundamentos/02-tdas-contrato-e-implementacion.md) y
> [`03-orden-busqueda/04` — Hashing](../03-orden-busqueda/04-hashing-y-tablas-hash.md).
>
> **Este capítulo es de estructuras, no de concurrencia en Java.** El modelo de memoria, `volatile`,
> los locks y el dimensionado de pools están en
> [`preguntas-entrevista/04-java-11-17.md`](../../../../preguntas-entrevista/04-java-11-17.md), preguntas
> 69 a 76. Aquí se enlaza y no se repite.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Ocho hilos incrementan un contador dentro de un mapa, 50 000 veces cada uno. El total esperado es
400 000. Esto es lo que sale de verdad, en una ejecución real:

```text
esperado:                   400000
HashMap sin sincronizar   →  71965    se perdieron 328 035
synchronizedMap + get/put →  128351   se perdieron 271 649
ConcurrentHashMap + merge →  400000   ✅
```

La primera línea no sorprende a nadie. **La segunda es la que importa**: el mapa está sincronizado,
cada llamada a `get` y a `put` es atómica, y aun así se pierde el 68 % de los incrementos.

El motivo es que la secuencia **leer, sumar, escribir** no es atómica aunque cada paso lo sea. Entre
el `get` y el `put` de un hilo, otro hilo hace su propio `get` y ambos escriben el mismo valor. La
sincronización protegía cada operación y el problema estaba en la **composición**.

> **Regla de entrevista:** "usé una colección sincronizada" no responde nada. La pregunta es **qué
> operación es atómica**: si tu unidad de trabajo son dos llamadas, sincronizar cada una por separado
> no te protege.

---

## 2. 🧱 Qué significa que una estructura sea segura

**Qué es.** Que su invariante interno se mantiene aunque varios hilos la usen a la vez, y que las
operaciones que declara atómicas lo son.

**Lo que no significa**, y es el malentendido central:

```text
Segura entre hilos  ≠  tus secuencias de operaciones son atómicas
Segura entre hilos  ≠  el orden de las operaciones es el que esperas
Segura entre hilos  ≠  puedes iterarla mientras otro la modifica
```

**Los tres niveles** que hay que distinguir al hablar de una estructura:

- **No segura.** `HashMap`, `ArrayList`. Con escrituras concurrentes puede perder datos, ver un
  estado a medio redimensionar o —en versiones anteriores a Java 8— entrar en un bucle infinito
  dentro de un bucket, con una CPU al 100 % y ninguna excepción.
- **Segura por operación.** `Collections.synchronizedMap`, `Vector`. Cada método está protegido por
  un bloqueo; las **secuencias** no. Es el caso de la sección 1.
- **Segura y con operaciones compuestas atómicas.** `ConcurrentHashMap` con `merge`, `compute`,
  `putIfAbsent`. Aquí la unidad atómica es la que tú necesitas.

**Cuánto cuesta.** El coste no es el bloqueo en sí: es la **contención**. Un bloqueo sin
competencia es muy barato; el mismo bloqueo con ocho hilos peleando por él serializa el trabajo y
puede hacer que ocho núcleos rindan menos que uno.

> **Veredicto:** elegir una estructura concurrente no es elegir "la versión segura de la que ya
> usabas". Es elegir **qué operación quieres que sea atómica**, y esa decisión es de diseño, no de
> biblioteca.

---

## 3. 🧱 `ConcurrentHashMap` y las operaciones atómicas

**Qué es.** Un mapa de hash diseñado para acceso concurrente: las lecturas no bloquean y las
escrituras bloquean solo el bucket afectado.

**Lo que hay que usar de él**, que es lo que casi nadie usa:

```java
mapa.merge("clave", 1, Integer::sum);        // leer-sumar-escribir, ATÓMICO
mapa.computeIfAbsent(clave, k -> caro(k));   // calcula e inserta si falta, atómico
mapa.putIfAbsent(clave, valor);              // inserta solo si no estaba
```

- **`merge` es la respuesta al problema de la sección 1** y por eso la tercera línea de la tabla da
  400 000: la operación compuesta es atómica por contrato.
- `computeIfAbsent` garantiza además que la función de cálculo **se ejecuta una sola vez** por clave
  aunque varios hilos la pidan a la vez, lo que lo convierte en el idioma correcto para una caché
  perezosa.
- El aviso que ya está en
  [`01-fundamentos/04`](../01-fundamentos/04-recursion-y-backtracking.md): dentro de
  `computeIfAbsent` **no se puede modificar el mismo mapa**, ni siquiera recursivamente. Lanza
  excepción desde Java 9, y en versiones anteriores corrompía la estructura en silencio.

**Cuándo sí.** Prácticamente siempre que un mapa se comparta entre hilos.

**Cuándo no.** Cuando el mapa se llena al arrancar y después **solo se lee**: ahí un `HashMap`
publicado de forma segura —`final`, o `Map.copyOf`— es correcto, más rápido y más simple. Decir esto
es importante, porque el reflejo de "concurrente por si acaso" tiene un coste real.

> ⚠️ **Advertencia.** `size()` e `isEmpty()` en un mapa concurrente son **aproximados** mientras hay
> escrituras: no bloquean toda la estructura para contar. Y la iteración es *débilmente consistente*:
> no lanza `ConcurrentModificationException`, pero puede o no ver las modificaciones hechas durante
> el recorrido. Contar con `size()` para una decisión de negocio bajo carga es un bug.

---

## 4. 🧱 Copiar al escribir, y las colas

**`CopyOnWriteArrayList`.** Cada escritura **copia el arreglo entero**; las lecturas no bloquean
nunca y nunca ven un estado intermedio.

```text
lectura   → O(1), sin bloqueo, sobre una instantánea inmutable
escritura → O(n), copia completa
```

- Es excelente con **muchas lecturas y casi ninguna escritura**: listas de listeners, configuración
  recargable, conjuntos de reglas. Es el caso para el que se diseñó.
- Es catastrófico con escrituras frecuentes: mil escrituras sobre una lista de mil elementos son un
  millón de copias.
- Su iterador trabaja sobre la instantánea del momento de crearlo, así que **nunca lanza
  `ConcurrentModificationException`** y tampoco ve lo que se añadió después. Eso es una garantía, no
  un defecto, y hay que saber si te sirve.

**Las colas bloqueantes.** `BlockingQueue` es el TDA cola de
[`01-fundamentos/02`](../01-fundamentos/02-tdas-contrato-e-implementacion.md) con dos operaciones
más: `put` espera si está llena y `take` espera si está vacía.

- Es **la estructura de comunicación entre hilos** por excelencia: resuelve productor-consumidor sin
  que nadie escriba un `wait`/`notify`.
- **La capacidad acotada es la característica, no una limitación**: es lo que da *backpressure*. Con
  una cola ilimitada, un productor más rápido que el consumidor acaba en `OutOfMemoryError`, y ese es
  el fallo clásico de un `ThreadPoolExecutor` mal configurado.
- `ArrayBlockingQueue` es acotada y justa; `LinkedBlockingQueue` puede ser ilimitada —cuidado—;
  `SynchronousQueue` no almacena nada y obliga a un encuentro entre productor y consumidor.

---

## 5. 🧱 Lo inmutable no necesita protección

**La observación que ahorra la mitad del capítulo:** un objeto que no cambia es seguro entre hilos
**gratis**, sin bloqueos, sin copias y sin contención.

```java
List<Producto> catalogo = List.copyOf(productos);    // inmutable de verdad
record Money(long centimos, Currency divisa) { }     // valor inmutable
```

- `List.of`, `Map.of` y `List.copyOf` devuelven colecciones **realmente inmutables** —lanzan
  `UnsupportedOperationException` al modificarlas—, a diferencia de
  `Collections.unmodifiableList`, que es una **vista**: si alguien conserva la referencia original,
  puede modificarla por debajo.
- Los `record` son el vehículo natural: inmutables por construcción, con `equals` y `hashCode`
  coherentes —lo que los hace además buenas claves, como dice
  [`03-orden-busqueda/04`](../03-orden-busqueda/04-hashing-y-tablas-hash.md)—.
- El patrón completo: **estructuras inmutables compartidas, y una referencia atómica que se
  sustituye entera** cuando hay que actualizar. Es cómo se recarga una configuración en caliente sin
  bloquear a los lectores, y es lo mismo que hace `CopyOnWriteArrayList` a menor escala.

> 💡 **Truco.** Ante "¿cómo harías esto seguro entre hilos?", la primera respuesta a considerar no es
> un bloqueo: es **"¿puede ser inmutable?"**. Si el dato no cambia, el problema desaparece en vez de
> gestionarse. Solo cuando la respuesta es no, se elige estructura concurrente.

---

## 6. ⚖️ Los cinco modelos de concurrencia

Aquí está la aportación propia de este capítulo: **cada lenguaje respondió de forma distinta a la
misma pregunta**, y la elección condiciona qué estructuras necesitas.

| Lenguaje | Modelo | Estado compartido | Consecuencia para las estructuras |
|---|---|---|---|
| **Java** | Hilos con memoria compartida | Sí, y hay que protegerlo | Todo un paquete `java.util.concurrent`. **Virtual threads** desde 21 |
| **Python** | Hilos con **GIL** | Sí, pero solo uno ejecuta bytecode a la vez | Las estructuras nativas son atómicas de facto; el paralelismo real exige procesos |
| **JavaScript** | **Un solo hilo** + bucle de eventos | No hay | **No existen estructuras concurrentes**, porque no hacen falta |
| **TypeScript** | Igual que JS | No | Sin aportación |
| **Go** | Goroutines + **canales** | Desaconsejado por cultura | `sync.Map` existe y se usa poco: se prefiere pasar por canal |

Las cuatro observaciones que valen como respuesta:

- **JavaScript no tiene este problema en absoluto.** Un solo hilo significa que ninguna secuencia se
  interrumpe a mitad, así que el bug de la sección 1 no puede ocurrir. Lo paga con que **una
  operación lenta bloquea todo**, y de ahí que su modelo entero sea asíncrono. Los *Web Workers* sí
  dan paralelismo, y por eso comunican **copiando mensajes**, no compartiendo memoria.
- **El GIL de Python** hace que sus estructuras nativas sean atómicas para operaciones simples —un
  `dict[k] = v` no se corrompe—, pero **no** para secuencias: `d[k] += 1` sigue siendo leer-sumar-
  escribir y sigue perdiendo incrementos. Es exactamente el mismo bug con otra causa.
- **Go invierte la recomendación.** Su lema es *"no comuniques compartiendo memoria; comparte memoria
  comunicando"*: en vez de proteger una estructura, se le pasa la propiedad del dato a una goroutine
  por un canal. El `sync.Map` existe para casos concretos —muchas lecturas, claves estables— y
  usarlo por defecto se considera mal estilo.
- **Los virtual threads de Java 21** cambian el dimensionado, no el modelo: siguen siendo memoria
  compartida y siguen necesitando las mismas estructuras. Lo que cambia es que bloquear deja de ser
  caro, y por tanto el argumento del *bulkhead* por número de hilos pierde fuerza.

---

## 7. ⏱️ La tabla de costes

| Estructura | Lectura | Escritura | Cuándo gana | Lo que la tabla no dice |
|---|---|---|---|---|
| `HashMap` | O(1), **insegura** | O(1), insegura | Solo lectura tras publicar | Con escrituras concurrentes corrompe en silencio |
| `Collections.synchronizedMap` | Bloqueo global | Bloqueo global | Casi nunca | **Las secuencias siguen sin ser atómicas** |
| `ConcurrentHashMap` | Sin bloqueo | Bloqueo por bucket | Caso general | `size()` es aproximado; iteración débilmente consistente |
| `CopyOnWriteArrayList` | O(1), sin bloqueo | **O(n)**, copia entera | Muchas lecturas, casi ninguna escritura | Mil escrituras sobre mil elementos: un millón de copias |
| `BlockingQueue` acotada | O(1) | O(1), espera si llena | Productor-consumidor | La cota **es** el backpressure: ilimitada = `OutOfMemoryError` |
| Inmutable + referencia atómica | O(1), sin bloqueo | Copia y sustituye | Configuración, catálogos | El coste se paga solo al actualizar |

---

## 8. 🧭 Cómo se elige

```text
¿El dato puede ser inmutable?                 → hazlo inmutable y olvídate del resto
¿Se llena al arrancar y luego solo se lee?    → HashMap publicado de forma segura (final, Map.copyOf)
¿Escrituras concurrentes sobre un mapa?       → ConcurrentHashMap, con merge/compute/putIfAbsent
¿Tu unidad de trabajo son dos operaciones?    → necesitas UNA operación atómica, no dos sincronizadas
¿Muchas lecturas y casi ninguna escritura?    → CopyOnWriteArrayList
¿Comunicar entre hilos?                       → BlockingQueue ACOTADA (o un canal, en Go)
¿Contadores?                                  → LongAdder si hay contención; AtomicLong si no
¿Estás en JavaScript?                         → no hay problema: un solo hilo
```

> **Regla de entrevista:** la secuencia correcta es **inmutable → publicado de forma segura →
> concurrente → bloqueado a mano**, y se baja un escalón solo cuando el anterior no sirve. Empezar
> por el bloqueo es empezar por el final.

---

## 9. 🔭 Dónde aparece de verdad

En el mapa de sesiones o de conexiones de cualquier servidor, que es el caso canónico de
`ConcurrentHashMap`; en la cola de un `ThreadPoolExecutor`, donde una `LinkedBlockingQueue` sin cota
convierte un pico de carga en `OutOfMemoryError` en vez de en rechazo; en la lista de listeners de un
framework, que es `CopyOnWriteArrayList`; en la caché recargable en caliente, que es una referencia
atómica a una estructura inmutable; en los contadores de métricas, donde `LongAdder` existe porque
`AtomicLong` se degrada con contención alta; y en la caché LRU de
[`09-implementaciones/03`](../09-implementaciones/03-ejercicios-comparativos.md), cuyo `get` **muta**
la estructura y por eso `synchronizedMap` no la salva.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Uso `synchronizedMap`, ya es seguro" | Cada método lo es; **tu secuencia `get`+`put` no**. Verificado: pierde el 68 % |
| "`ConcurrentHashMap` hace mi código seguro" | Hace atómicas **sus** operaciones. Usa `merge`/`compute`, no `get`+`put` |
| "`size()` me dice cuántos hay" | Es aproximado mientras hay escrituras concurrentes |
| "`CopyOnWriteArrayList` es la lista segura" | Solo con lecturas dominantes: cada escritura copia el arreglo entero |
| "Uso una cola ilimitada para no perder trabajo" | Pierdes el proceso entero: la cota **es** el backpressure |
| "En Python el GIL me protege" | Protege las operaciones simples; `d[k] += 1` sigue perdiendo incrementos |
| "`unmodifiableList` es inmutable" | Es una **vista**: quien tenga la original puede modificarla. Usa `List.copyOf` |

---

## 📚 Para profundizar

- **Libro** — Goetz et al., *Java Concurrency in Practice* (Addison-Wesley, 2006). Capítulos 4 y 5,
  sobre composición de objetos y bloques de construcción concurrentes. **Es el libro de este tema**;
  sigue siendo válido salvo en lo que añadió Java 8 en adelante.
- **Libro** — Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítems 17 (inmutabilidad), 78
  (sincronizar el acceso compartido) y 81 (preferir las utilidades de concurrencia a `wait`/`notify`).
- [Java 21 API — `ConcurrentHashMap`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html):
  las garantías exactas, incluida la nota de que `size()` es una estimación.
- [Java 21 API — `CopyOnWriteArrayList`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/CopyOnWriteArrayList.html):
  el contrato del iterador sobre instantánea y el caso de uso declarado.
- [Java 21 API — `BlockingQueue`](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/BlockingQueue.html):
  las cuatro familias de operaciones —lanzar, devolver especial, bloquear, esperar con tiempo—.
- [Go — `sync`](https://pkg.go.dev/sync): `Mutex`, `RWMutex`, `Once` y `Map`, con la nota de cuándo
  `sync.Map` merece la pena frente a un mapa con mutex.
- [Python — `threading`](https://docs.python.org/3/library/threading.html): el GIL, y por qué el
  paralelismo real de CPU pasa por `multiprocessing`.
- **Concurrencia en Java, en detalle** —
  [`preguntas-entrevista/04-java-11-17.md`](../../../../preguntas-entrevista/04-java-11-17.md), preguntas
  69 a 76: modelo de memoria, `volatile`, locks y dimensionado de pools.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md).

1. ¿Qué significa que una estructura sea segura entre hilos? 🟢
2. ¿Qué pasa si varios hilos escriben en un `HashMap` sin sincronizar? 🟢
3. ¿Qué operación de `ConcurrentHashMap` hace atómico un incremento? 🟢
4. ¿Cuál es el caso de uso de `CopyOnWriteArrayList`? 🟢
5. ¿Qué añade una `BlockingQueue` sobre una cola normal? 🟢
6. ¿Por qué una estructura inmutable es segura entre hilos? 🟢
7. ¿Por qué `Collections.synchronizedMap` no evita perder incrementos? 🟡
8. ¿Por qué `size()` de un `ConcurrentHashMap` es aproximado? 🟡
9. ¿Qué diferencia hay entre `unmodifiableList` y `List.copyOf`? 🟡
10. ¿Por qué una cola ilimitada es peligrosa en un pool de hilos? 🟡
11. ¿Qué garantiza `computeIfAbsent` que un `get` seguido de `put` no garantiza? 🟡
12. ¿Por qué en JavaScript no existen estructuras concurrentes? 🟡
13. ¿Qué protege el GIL de Python y qué no? 🟡
14. ¿Por qué el coste de un bloqueo no es el bloqueo sino la contención? 🟠
15. ¿Cuándo es correcto usar un `HashMap` normal compartido entre hilos? 🟠
16. ¿Por qué `d[k] += 1` en Python pierde incrementos pese al GIL? 🟠
17. ¿Cuál es la filosofía de Go sobre el estado compartido y qué implica para las estructuras? 🟠
18. ¿Qué cambian los virtual threads de Java 21 y qué **no** cambian? 🟠
19. ¿Por qué `LongAdder` existe si ya está `AtomicLong`? 🟠
20. ¿Por qué el `get` de una caché LRU impide protegerla con `synchronizedMap`? 🟠
21. Un contador compartido pierde el 68 % de los incrementos pese a usar un mapa sincronizado.
    Explica el mecanismo exacto y da dos correcciones. 🔴
22. Diseña una caché de configuración recargable en caliente, con miles de lecturas por segundo y
    una recarga cada diez minutos. 🔴
23. Diseña la política de concurrencia de un equipo: qué estructuras se permiten, cuáles se
    prohíben, qué se revisa y qué se prueba. 🔴
24. Un servicio pasa de 4 a 32 núcleos y su rendimiento no mejora, o empeora. Da tres hipótesis
    ordenadas y cómo distingues cada una. 🔴

---

**Anterior:** [`02` — Tiempo, fechas y relojes](02-tiempo-fechas-y-relojes.md) ·
**Siguiente:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Relacionado:** [`03-orden-busqueda/04` — Hashing](../03-orden-busqueda/04-hashing-y-tablas-hash.md)
