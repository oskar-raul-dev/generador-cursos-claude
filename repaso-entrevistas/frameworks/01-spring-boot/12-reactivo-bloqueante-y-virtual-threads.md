# 12 — Reactivo, bloqueante y virtual threads

> **Objetivo:** elegir modelo de ejecución con argumentos y sostener la elección delante de
> alguien que ya tiene una opinión. Es un capítulo de decisión: no enseña API, enseña a
> comparar.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md) y [`11`](11-webflux-y-reactor.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 La pregunta está mal planteada

*"¿Es mejor reactivo o bloqueante?"* no tiene respuesta porque no es una pregunta sobre
velocidad. Los tres modelos ejecutan el mismo código de negocio a la misma velocidad: lo
que cambia es **qué hace el proceso mientras espera**.

Y esperar es casi todo lo que hace un servicio de banca. Una petición típica de `inv-api`
son 5 ms de CPU y 300 ms de espera: la base de datos, el proveedor externo, la caché. La
pregunta útil, entonces, es esta:

> **🧠 Modelo mental.** ¿Cuánto cuesta **una espera concurrente**? Ese es el único eje en
> el que los tres modelos se diferencian de verdad, y todo lo demás del capítulo se deriva
> de ahí.

---

## 2. 🧱 Los tres modelos sobre el mismo caso

`inv-api` recibe 1 000 peticiones simultáneas y cada una llama a `inv-supplier`, que tarda
300 ms.

```text
thread-per-request (Tomcat, 200 hilos de plataforma)
  200 peticiones esperando · 800 en la cola · ~1 MB de pila cada una
  latencia del percentil alto = 300 ms × (1000/200) = 1,5 s
  el cuello es el NÚMERO DE HILOS

WebFlux (Netty, ~8 hilos de event loop)
  1 000 peticiones esperando, ninguna con hilo propio
  latencia ≈ 300 ms para todas
  el cuello es NO BLOQUEAR NUNCA el event loop

virtual threads (Tomcat, un hilo virtual por petición)
  1 000 hilos virtuales esperando, ~1 KB de pila cada uno
  latencia ≈ 300 ms para todas
  el cuello es EL RECURSO DE ABAJO (el pool de conexiones)
```

- **El código de los modelos 1 y 3 es idéntico.** Los virtual threads no cambian cómo
  escribes: cambian lo que cuesta bloquear. Se activan con una propiedad:

```yaml
spring:
  threads:
    virtual:
      enabled: true      # Boot 3.2+, requiere Java 21
```

- **Eso afecta a más de lo que parece**: Tomcat atiende cada petición en un hilo virtual,
  y también `@Async` y `@Scheduled` pasan a usarlos ([`18`](18-asincronia-scheduling-y-eventos.md)).
- **El código del modelo 2 es otro lenguaje.** Cadenas de operadores, nada se ejecuta hasta
  la suscripción, y cualquier llamada bloqueante metida por descuido tumba el event loop
  entero — el mecanismo está en [`11`](11-webflux-y-reactor.md).

---

## 3. ⚖ La comparación, por criterios

| Criterio | Thread-per-request | WebFlux | Virtual threads |
|---|---|---|---|
| Coste de una espera | ~1 MB y un cupo del pool | casi cero | ~1 KB |
| Concurrencia realista | cientos | decenas de miles | decenas de miles |
| Latencia con CPU libre | igual | igual | igual |
| Forma del código | secuencial | cadenas de operadores | secuencial |
| Stack trace útil | ✅ | ❌ salvo `checkpoint()` | ✅ |
| Depurar con breakpoints | ✅ | ❌ incómodo | ✅ |
| Ecosistema bloqueante (JDBC, JPA, la mayoría de librerías) | ✅ nativo | ❌ hay que aislarlo | ✅ nativo |
| Backpressure de extremo a extremo | ❌ | ✅ | ❌ |
| Streaming y SSE | limitado | ✅ natural | limitado |
| Curva del equipo | ninguna | alta y permanente | ninguna |

La fila que decide la mayoría de los casos reales no es ninguna de las de rendimiento: es
**la del ecosistema**. Si tu servicio habla con Postgres por JDBC y usa JPA, el modelo
reactivo te obliga a aislar cada llamada bloqueante en un `boundedElastic` —es decir, a
reintroducir un pool de hilos— y pierdes buena parte de lo que fuiste a buscar.

---

## 4. ⚖ Lo que los virtual threads no arreglan

Aquí es donde se cae la respuesta entusiasta de entrevista:

- **El pool de conexiones sigue siendo el techo.** Puedes tener 10 000 hilos virtuales y
  10 conexiones en Hikari: la concurrencia real sigue siendo 10 ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md)). Los virtual threads
  quitan el límite de los hilos, no el del recurso de abajo — y muchas veces el hilo nunca
  fue el límite.
- **`synchronized` fija el hilo portador.** En Java 21, un hilo virtual que se bloquea
  dentro de un bloque `synchronized` **no se desmonta**: retiene el hilo de plataforma que
  lo transporta. Con suficientes, agotas los portadores y el servicio se para de una forma
  difícil de diagnosticar. La solución es `ReentrantLock` en las rutas que bloquean.
- **No ayudan con CPU.** Un servicio que calcula no espera: ahí el límite son los núcleos,
  y mil hilos virtuales compitiendo por ocho núcleos solo añaden cambios de contexto.
- **`ThreadLocal` sigue funcionando, pero ya no se reutiliza el hilo**, así que los
  patrones de caché por hilo (buffers reutilizables) dejan de tener sentido y consumen más.

> **📝 Qué cambia después de Java 21.** El pinning por `synchronized` se corrigió en
> **Java 24, con JEP 491**: desde ahí un hilo virtual que se bloquea dentro de un
> `synchronized` ya no clava su carrier thread. El curso fija Java 21 (§5.2 de la guía),
> así que aquí el aviso aplica entero; si tu proyecto corre sobre 24 o posterior, el
> argumento del `ReentrantLock` deja de ser obligatorio y conviene decir la versión al
> darlo en una entrevista.

---

## 5. ⏱️ Los números que justifican una decisión

Ninguna de estas cifras se adivina: se miden, y [`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas) explica con qué.

| Qué mirar | Por qué decide |
|---|---|
| % de tiempo de petición esperando E/S | si es bajo, ningún modelo te salva: el problema es la CPU |
| Hilos ocupados vs `threads.max` | si nunca se acerca, no tienes un problema de concurrencia |
| `hikaricp.connections.pending` | si hay cola, el techo es el pool y no el hilo |
| p99 bajo carga, no la media | la media esconde exactamente el problema que buscas |
| Uso de memoria por petición concurrente | es el coste real de thread-per-request |

> **🩺 Diagnóstico antes de migrar.** Si `threads.max` está en 200 y el máximo observado es
> 40, migrar a un modelo de alta concurrencia no va a mejorar nada: tu cuello está en otro
> sitio. Es la comprobación de cinco minutos que evita un proyecto de seis meses.

---

## 6. ⚖ Dónde gana cada uno

**Thread-per-request con virtual threads** — el default razonable hoy para un servicio de
banca: CRUD transaccional, JDBC, JPA, lógica con `@Transactional`, equipo que rota. Código
secuencial, stack traces legibles, y el coste de la espera deja de importar. Activarlo es
una línea de configuración y una prueba de carga.

**WebFlux** — gana cuando el servicio es principalmente E/S y hay **mucha** concurrencia
con poca lógica: un gateway que agrega cinco llamadas, streaming o SSE, o un consumidor
que necesita backpressure real de extremo a extremo. También cuando ya estás en él y
funciona: migrar hacia atrás rara vez se justifica solo.

**Thread-per-request clásico** — sigue siendo correcto para servicios de concurrencia
moderada y previsible, que son la mayoría. No hay ninguna obligación de migrar nada.

> Nunca respondas: ~~"reactivo escala mejor"~~
>
> Mejor: "reactivo hace más barata la espera concurrente. Si tu servicio está limitado por
> el pool de conexiones o por la CPU, no cambia nada — y con virtual threads consigues el
> mismo beneficio sin cambiar el modelo de programación."

---

## 7. 🧭 El argumento que casi nadie dice: el coste de equipo

Un capítulo de decisión que solo mira rendimiento está incompleto. WebFlux tiene un coste
permanente que no aparece en ningún benchmark:

- **Todo el equipo tiene que leer cadenas de operadores**, no solo quien las escribió, y la
  diferencia entre `map` y `flatMap` no es intuitiva para quien llega.
- **Depurar cuesta más**: los stack traces no reflejan el flujo lógico, los breakpoints
  saltan entre hilos y hace falta `checkpoint()` para orientarse.
- **Un bloqueo por descuido no falla ruidosamente**: degrada el servicio entero, y quien lo
  introduce suele ser quien menos conoce el modelo.
- **La rotación lo amplifica.** En un banco, el equipo de dentro de dos años no es este.

Eso no es un argumento contra WebFlux: es parte del precio, y **decirlo en voz alta en una
entrevista de tech lead vale más que recitar benchmarks**, porque demuestra que has
mantenido sistemas y no solo arrancado prototipos.

---

## 8. 🧱 La migración parcial que sí es común

Usar `WebClient` dentro de una aplicación MVC es perfectamente legítimo y muy frecuente:
te da un cliente moderno sin cambiar el modelo del servidor. Pero conviene saber qué
compraste:

- **Tu aplicación no es reactiva por eso.** El controller sigue en un hilo del contenedor;
  si llamas `.block()` sobre el resultado, has vuelto al modelo bloqueante con pasos extra.
- **Cuidado con el tipo de contexto**: tener `spring-webflux` en el classpath junto a
  `spring-webmvc` no convierte la aplicación en reactiva —gana el stack servlet ([`06`](06-arranque-y-autoconfiguracion.md))—,
  pero sí arrastra Netty y sus hilos.
- **Con virtual threads activados**, ese `.block()` deja de ser caro, que es otra razón por
  la que la combinación funciona mejor de lo que suena.

> Nunca respondas: ~~"uso `WebClient`, así que mi aplicación es reactiva"~~
>
> Mejor: "uso un cliente reactivo dentro de un modelo bloqueante; el beneficio está en la
> API del cliente, no en el modelo de ejecución del servidor."

---

## 9. ⚠️ Errores frecuentes

- **"Los virtual threads hacen WebFlux innecesario."** Cubren casi todos los casos por los
  que se elegía WebFlux —concurrencia alta con código bloqueante y legible—, pero no dan
  backpressure de extremo a extremo ni el modelo de streaming.
- **"Reactivo consume menos memoria siempre."** Consume menos pila; a cambio mantiene
  estructuras de operadores y buffers que con alta concurrencia no son gratis.
- **"Si migro a WebFlux, JPA seguirá funcionando igual."** Funciona, pero bloquea: hay que
  aislarlo en un scheduler, y entonces vuelves a tener un pool de hilos.
- **"La prueba de carga con 10 peticiones demuestra que es más rápido."** Sin concurrencia
  alta, los tres modelos miden lo mismo. El benchmark que no satura no prueba nada.

---

## 🧠 Preguntas rápidas

1. ¿Cuál es el único eje en el que los tres modelos se diferencian de verdad, y por qué la
   velocidad del código de negocio no lo es?
2. Con 1 000 peticiones concurrentes de 300 ms contra un proveedor externo, ¿qué latencia
   ve el percentil alto en Tomcat con 200 hilos y por qué?
3. ¿Qué cuesta, en orden de magnitud, la pila de un hilo de plataforma frente a la de uno
   virtual?
4. ¿Qué cambia en tu código al activar `spring.threads.virtual.enabled=true`, y qué más
   afecta esa propiedad aparte del servidor web?
5. Tienes 10 000 hilos virtuales y un pool de 10 conexiones. ¿Cuál es tu concurrencia real
   y qué te dice eso sobre la migración?
6. Explica el pinning por `synchronized` en Java 21: qué ocurre, por qué es difícil de
   diagnosticar y cuál es la corrección.
7. Nombra dos cosas que WebFlux te da y los virtual threads no.
8. ¿Por qué la fila del ecosistema decide más casos reales que las de rendimiento?
9. Antes de proponer una migración, ¿qué dos métricas miras y qué te haría abandonar la
   idea en cinco minutos?
10. Da tres componentes del coste de equipo de WebFlux que no aparecen en un benchmark.
11. Tu aplicación es MVC y usa `WebClient` con `.block()`. ¿Qué modelo de ejecución tienes
    realmente, y qué cambia si activas virtual threads?
12. ¿Por qué un benchmark con baja concurrencia no puede distinguir los tres modelos?
13. ¿En qué caso concreto seguirías eligiendo WebFlux hoy, teniendo virtual threads
    disponibles?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Ejecución de tareas, scheduling y virtual threads: https://docs.spring.io/spring-boot/3.5/reference/features/task-execution-and-scheduling.html
- Spring Boot 3.5 — Aplicaciones web reactivas: https://docs.spring.io/spring-boot/3.5/reference/web/reactive.html
- Spring Boot 3.5 — Aplicaciones web servlet: https://docs.spring.io/spring-boot/3.5/reference/web/servlet.html
- Spring Boot 3.5 — Configurar el servidor embebido: https://docs.spring.io/spring-boot/3.5/how-to/webserver.html
- Spring Framework 6.2 — Por qué existe WebFlux: https://docs.spring.io/spring-framework/reference/6.2/web/webflux/new-framework.html

### Documentación de terceros

- JEP 444 — Virtual Threads: https://openjdk.org/jeps/444
- Java SE 21 — Guía de virtual threads: https://docs.oracle.com/en/java/javase/21/core/virtual-threads.html
