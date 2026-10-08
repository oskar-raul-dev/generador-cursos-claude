# 03 — Bloqueante, no bloqueante y asíncrono

> Tres palabras que casi todo el mundo usa como dos, y que en realidad son **dos ejes
> independientes**. Qué hace tu hilo mientras espera, por qué un hilo por petición deja de escalar y
> a partir de dónde, y qué modelo usa de verdad cada uno de los cinco lenguajes — todo medido con el
> mismo servidor y la misma carga.
>
> **Asume leído:** [`02` — Todo es un archivo](02-todo-es-un-archivo.md) y
> [`06/03` §6 — Los cinco modelos de concurrencia](../06-numeros-tiempo-concurrencia/03-estructuras-y-concurrencia.md).
>
> **Vigencia:** 2026-09-18. Todas las medidas de este capítulo están **ejecutadas**.

---

## 1. 🎯 El problema

Un servidor atiende peticiones que tardan 100 ms. Llegan 50 a la vez. ¿Cuánto tarda en responder a
todas? La respuesta depende de una sola decisión de diseño, y el rango es enorme. Medido con el mismo
servidor escrito de siete formas:

```text
Python, un solo hilo (secuencial)     5131 ms
Java, pool acotado de 8 hilos          727 ms
Java, hilos de plataforma              177 ms
Python, hilos del sistema              133 ms
Node, bucle de eventos                 125 ms
Java, hilos virtuales                  122 ms
Python, asyncio                        121 ms
Go, goroutines                         116 ms
```

De 5 131 ms a 116 ms: **cuarenta y cuatro veces**, con el mismo trabajo y la misma máquina. Y el
segundo renglón es el más instructivo de todos: un pool de ocho hilos con entrada y salida
bloqueante tarda 727 ms, que es `50/8 × 100 ms`. **El pool no protege: serializa.**

---

## 2. 🧱 Dos ejes, no uno

**Qué es.** Las tres palabras describen dos cosas distintas, y por eso no forman una escala:

```text
BLOQUEANTE / NO BLOQUEANTE   → ¿la llamada espera a que haya datos, o vuelve enseguida?
SÍNCRONO   / ASÍNCRONO       → ¿tú preguntas por el resultado, o te avisan cuando está?
```

Cruzándolos salen cuatro combinaciones, y las cuatro existen:

| | Síncrono | Asíncrono |
|---|---|---|
| **Bloqueante** | `read()` normal: el hilo se para hasta que haya datos | Poco común: se inicia y se espera a que avisen |
| **No bloqueante** | `read()` con `EAGAIN` en bucle: sondeo activo, quema CPU | `epoll` + notificación; `io_uring`: **el modelo de los servidores** |

- **"No bloqueante" no significa "asíncrono".** Un bucle que llama a `read` y recibe `EAGAIN` una y
  otra vez no bloquea el hilo y aun así es síncrono — y es la peor combinación de las cuatro, porque
  gasta CPU sin hacer nada.
- **Lo que hace útil al modelo de los servidores** es combinar descriptores no bloqueantes con un
  mecanismo de notificación (`epoll`, `kqueue`): el hilo se duerme en **una sola llamada** que vigila
  miles de descriptores y despierta solo cuando alguno tiene datos.
- **El bucle de eventos es eso**, y nada más: un hilo, una llamada a `epoll`, y un despachador que
  ejecuta el trozo de código correspondiente al descriptor que despertó.

> **Veredicto:** la pregunta correcta nunca es "¿es asíncrono?". Es **"¿qué hace mi hilo mientras
> espera?"**, y solo hay tres respuestas: se para, gira en vano, o atiende otra cosa.

---

## 3. 🧱 Los modelos de servidor, y dónde muere cada uno

**Qué es.** Cinco formas de organizar el mismo trabajo, en orden histórico:

```text
1. SECUENCIAL              una conexión cada vez
2. HILO POR CONEXIÓN       un hilo del SO por cliente
3. POOL ACOTADO            N hilos fijos, las conexiones esperan turno
4. BUCLE DE EVENTOS        un hilo, IO no bloqueante, notificación
5. HILOS LIGEROS           el runtime multiplexa: goroutines, hilos virtuales
```

**Cuánto cuesta cada uno.** Y aquí está el dato que no se ve en la latencia. Con **2 000 conexiones
simultáneas**:

| Servidor | hilos del SO | memoria | total |
|---|---|---|---|
| Python, hilos del sistema | 1 780 | 78 MB | **4 458 ms** |
| Java, hilos de plataforma | **2 014** | **240 MB** | 490 ms |
| Java, hilos virtuales | **35** | 64 MB | 419 ms |
| Python, asyncio | 1 | 34 MB | 377 ms |
| Go, goroutines | **12** | **14 MB** | 371 ms |
| Node, bucle de eventos | 8 | 35 MB | 258 ms |

Tres lecturas, y las tres se preguntan:

- **2 014 hilos del sistema operativo contra 35 para el mismo trabajo.** La latencia es parecida; el
  coste no. Cada hilo de plataforma reserva su pila —del orden de un mega de espacio de direcciones—
  y además el planificador del sistema tiene que repartir tiempo entre todos.
- **Hilo por conexión no cuesta lo mismo en todos los lenguajes.** Python con hilos tarda **doce veces
  más** que Python con `asyncio`, y no es por los descriptores: es el bloqueo global del intérprete
  más el coste de cambiar de contexto entre 1 780 hilos.
- **Node muestra ocho hilos, no uno.** Son el bucle de eventos más el pool de `libuv` del capítulo
  `02`. "Un solo hilo" es una simplificación útil y literalmente falsa.

**Cuándo sí** cada modelo:

- **Secuencial:** herramientas de línea de comandos, procesos por lotes, y cualquier cosa sin
  concurrencia. Es el más simple y el más fácil de depurar; no hay ninguna vergüenza en usarlo.
- **Hilo por conexión:** hasta unos cientos de conexiones concurrentes. Código lineal, depuración
  normal, trazas legibles.
- **Pool acotado:** cuando el cuello de botella es CPU y no entrada/salida. Ahí acotar es correcto.
- **Bucle de eventos:** miles de conexiones con poco trabajo de CPU por cada una.
- **Hilos ligeros:** lo mismo que el bucle de eventos, con código que se lee como el bloqueante.

**Cuándo no:**

- **Pool acotado con entrada y salida bloqueante** es la combinación que produce el incidente de la
  sección 5. Nunca acotes un pool que va a pasar la mayor parte del tiempo esperando red.
- **Bucle de eventos con trabajo de CPU dentro** bloquea a todos los clientes a la vez: un cálculo de
  200 ms en el manejador para el servidor entero.

> **Veredicto:** hilo por conexión es correcto y perfectamente defendible **hasta unos cientos de
> conexiones**; ahí no hay que justificarse. El argumento a favor de hilos virtuales o goroutines es
> que mueven ese techo dos órdenes de magnitud **sin cambiar cómo se escribe el código**, que es lo
> que los distingue del bucle de eventos.

---

## 4. 🧱 Qué modelo usa cada lenguaje

| | Modelo | Cómo se escribe | La trampa |
|---|---|---|---|
| **Java ≤ 20** | Hilos de plataforma, pool | Bloqueante, lineal | El pool acotado serializa la espera |
| **Java 21+** | Hilos virtuales | **Igual que el bloqueante** | `synchronized` puede fijar el hilo portador |
| **Go** | Goroutines + `netpoller` | Bloqueante, lineal | Una goroutine que no termina nunca es una fuga |
| **Node** | Bucle de eventos + pool de `libuv` | `async`/`await`, callbacks | CPU en el manejador bloquea a todos |
| **Python** | `asyncio`, o hilos con GIL | `async`/`await`, o bloqueante | Mezclar bloqueante dentro de `async` para el bucle |
| **TypeScript** | El de Node | `async`/`await` con tipos | `Promise` sin `await` es un error silencioso |

Lo que hay que saber decir de cada uno:

- **Go y Java 21 convergieron en la misma idea desde lados opuestos**: el código se escribe como si
  fuera bloqueante y el runtime lo convierte en no bloqueante. En Go eso existe desde el principio;
  Java tardó veinticinco años en llegar.
- **El color de las funciones.** En Node y en Python, una función `async` solo se puede llamar desde
  otra `async`: el modelo "tiñe" toda la pila de llamadas. En Go y en Java 21 no ocurre, y por eso no
  hace falta duplicar bibliotecas.
- **La trampa de Java 21** merece nombrarse: un bloque `synchronized` que espera puede **fijar** el
  hilo virtual a su hilo portador y anular la ventaja. La recomendación oficial es sustituirlo por
  `ReentrantLock` en las secciones que hagan entrada y salida.
- **La trampa de Python** es que un `time.sleep` o una consulta bloqueante dentro de una corrutina
  para el bucle entero: hay que usar la versión `async` o delegar a un ejecutor.

---

## 5. ⚠️ El incidente del pool acotado

**Qué pasa.** Un servicio con un pool de N hilos llama a un proveedor externo que se vuelve lento.
Cada hilo se queda esperando una respuesta que tarda. Con N hilos ocupados esperando, **el servicio
deja de atender a todo el mundo**, incluidas las peticiones que no tocan ese proveedor.

Está medido arriba en pequeño: 50 conexiones y un pool de 8 dan 727 ms, seis veces más que cualquier
modelo que no acote. Con un proveedor que pasa de 100 ms a 5 s, el mismo cálculo da una caída total.

- **El síntoma engaña**: el servicio responde a todo con timeout, y el proveedor lento solo afecta al
  10 % del tráfico. Parece un problema general y es un problema de un solo integrante.
- **Es el mismo fenómeno del mamparo** (*bulkhead*) de arquitectura, visto desde el recurso: si todos
  los tipos de petición comparten el mismo pool, un integrante lento se lleva a todos por delante.
- Las tres defensas, en orden de eficacia: **timeouts agresivos** en cada llamada externa —sin ellos
  nada más funciona—, **pools separados por dependencia**, y **no bloquear** (hilos virtuales,
  goroutines, reactivo), que elimina la clase entera.

> 💡 **La frase para la entrevista.** *"Un pool acotado protege la CPU y no protege la espera. Si mis
> hilos se van a pasar el tiempo esperando red, acotarlos convierte la lentitud de un proveedor en
> una caída mía."*

---

## 6. ⏱️ La tabla de costes

| Modelo | Coste por conexión | Techo práctico | Cómo se escribe |
|---|---|---|---|
| Secuencial | 0 | 1 a la vez | Trivial |
| Hilo por conexión | ~1 MB de pila + planificación | Cientos | Lineal |
| Pool acotado | 0 extra | N en paralelo, el resto espera | Lineal |
| Bucle de eventos | unos pocos KB | Decenas de miles | Teñido de `async` |
| Hilos ligeros | unos pocos KB | Decenas de miles | **Lineal** |

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "No bloqueante y asíncrono son lo mismo" | Son dos ejes: se puede ser no bloqueante y síncrono, y es la peor opción |
| "Un pool acotado protege el servicio" | Protege la CPU; ante espera de red, serializa y lo tumba |
| "Node es de un solo hilo" | Bucle de eventos más el pool de `libuv`: medidos, ocho |
| "Hilo por conexión no escala, punto" | Escala hasta cientos, y ahí es la opción más simple y depurable |
| "Los hilos virtuales son más rápidos" | Igual de rápidos; lo que cambia es **cuántos caben** |
| "Con hilos virtuales ya no hace falta pensar" | `synchronized` puede fijarlos y anular la ventaja |
| "Reactivo es más rápido que bloqueante" | Con poca concurrencia suele ser igual o peor, y mucho más difícil de depurar |
| "`asyncio` usa varios núcleos" | Un solo hilo: paraleliza espera, no cálculo |

---

## 📚 Para profundizar

- **Libro** — Stevens y Rago, *Advanced Programming in the UNIX Environment*, capítulo 14; y para el
  lado de red, *UNIX Network Programming* del mismo autor, capítulo 6, que compara los cinco modelos
  de entrada y salida uno a uno.
- **Artículo** — [Dan Kegel — *The C10K problem*](http://www.kegel.com/c10k.html): el texto que
  planteó el problema en 1999. Histórico y todavía la mejor introducción al porqué.
- **Java** — [JEP 444 — *Virtual Threads*](https://openjdk.org/jeps/444): la propuesta, con la
  sección de fijación (*pinning*) que explica la trampa de `synchronized`.
- **Go** — [*The Go scheduler*, documentación del runtime](https://pkg.go.dev/runtime): cómo se
  multiplexan goroutines sobre hilos del sistema.
- **Node** — [*The Node.js Event Loop*](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick):
  las fases del bucle, que es lo que hay que saber para explicar por qué un cálculo largo lo bloquea.
- **Python** — [`asyncio` — *Developing with asyncio*](https://docs.python.org/3/library/asyncio-dev.html):
  la lista de errores típicos, empezando por llamar a código bloqueante desde una corrutina.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`07` — Respuestas](07-respuestas.md).

1. ¿Qué significa que una llamada sea bloqueante? 🟢
2. ¿Qué significa que sea no bloqueante? 🟢
3. ¿Qué es un bucle de eventos? 🟢
4. ¿Qué es un hilo virtual? 🟢
5. ¿Qué es una goroutine? 🟢
6. ¿Cuántos hilos usa `asyncio`? 🟢
7. ¿Qué modelo usa Node? 🟢
8. ¿Cuánto ocupa la pila de un hilo del sistema operativo? 🟢
9. ¿Por qué "no bloqueante" y "asíncrono" no son sinónimos? 🟡
10. ¿Cuál de las cuatro combinaciones es la peor y por qué? 🟡
11. ¿Qué hace `epoll` que no hace un bucle de sondeo? 🟡
12. ¿Hasta dónde escala hilo por conexión? 🟡
13. ¿Por qué Python con hilos tarda doce veces más que con `asyncio`? 🟡
14. ¿Qué es el color de las funciones y qué lenguajes lo sufren? 🟡
15. ¿Qué tienen en común Go y Java 21 frente a Node? 🟡
16. ¿Qué pasa si haces un cálculo de 200 ms dentro de un manejador de Node? 🟡
17. ¿Qué diferencia hay entre paralelizar espera y paralelizar cálculo? 🟡
18. ¿Por qué un pool acotado serializa la espera? 🟠
19. Un proveedor externo se vuelve lento y cae todo el servicio. Explica el mecanismo. 🟠
20. ¿Son más rápidos los hilos virtuales? Responde con precisión. 🟠
21. ¿Qué es la fijación de un hilo virtual y cómo se evita? 🟠
22. ¿Cuándo elegirías hilo por conexión pudiendo usar hilos virtuales? 🟠
23. ¿Por qué reactivo puede ser peor que bloqueante con poca concurrencia? 🟠
24. ¿Qué mide realmente la tabla de 2 000 conexiones: latencia o coste? 🟠
25. Te dicen que suban el pool de 8 a 200 hilos para arreglar la latencia. ¿Qué contestas? 🟠
26. Diseña el servidor de un servicio que atiende 20 000 conexiones de larga duración con poco
    trabajo por conexión. Elige modelo y justifica el coste. 🔴
27. Migras un servicio Java 17 con hilo por conexión a Java 21 con hilos virtuales. Enumera qué
    revisarías antes, qué medirías después y qué podría empeorar. 🔴
28. Escribe el diagnóstico de un servicio que responde bien con 100 usuarios y da timeout con
    300, con la CPU al 15 %. 🔴
29. Tu equipo quiere reescribir en reactivo un servicio con 200 usuarios concurrentes. Escribe
    el argumento en contra y qué propondrías en su lugar. 🔴
30. Diseña la prueba de carga que demuestra el techo de cada modelo, y di qué métricas recoges
    además de la latencia. 🔴
31. Explica a un equipo de producto, sin jerga, por qué añadir más hilos no arregla la lentitud.
    🔴

---

**Anterior:** [`02` — Todo es un archivo, y dónde se rompe](02-todo-es-un-archivo.md) ·
**Siguiente:** [`04` — Búferes y el coste de la frontera](04-buferes-y-el-coste-de-la-frontera.md) ·
**Bloque:** [README](README.md)
