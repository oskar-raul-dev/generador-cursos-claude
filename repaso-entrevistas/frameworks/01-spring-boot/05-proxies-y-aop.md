# 05 — Proxies y AOP

> **Objetivo:** poder explicar **por qué una anotación declarativa a veces no hace nada**,
> sin tener que probarlo. Este es el capítulo al que remiten [`16`](16-transacciones.md), [`17`](17-cache.md), [`18`](18-asincronia-scheduling-y-eventos.md), [`19`](19-resiliencia.md), [`20`](20-spring-security-el-mecanismo.md)
> y [`22`](22-spring-batch.md): todo lo que Spring hace "solo" pasa por aquí.
> **Asume:** [`02`](02-contenedor-ioc-y-ciclo-de-vida.md), [`03`](03-inyeccion-de-dependencias.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: añadir comportamiento sin tocar la clase

Tienes cuarenta métodos de servicio que deben ejecutarse dentro de una transacción,
registrar cuánto tardaron y reintentarse si el proveedor externo falla. Escribirlo a mano
significa el mismo `try/catch/commit/rollback` cuarenta veces, mezclado con la lógica de
negocio, y un bug de copia y pega en la número treinta y uno.

Lo que quieres es **envolver** el método: que alguien haga algo antes, algo después, y
llame a tu código en medio. Sin que tu código lo sepa.

```text
         llamada                    ┌─────────────────────┐
  otro bean ──────────────────────► │ proxy               │
                                    │  abre transacción   │
                                    │  ┌───────────────┐  │
                                    │  │ tu objeto     │  │  ← tu código, intacto
                                    │  │ .record(...)  │  │
                                    │  └───────────────┘  │
                                    │  commit / rollback  │
                                    └─────────────────────┘
```

Eso es un **proxy**: un objeto del mismo tipo que el tuyo, que se pone en medio. Y eso es
lo que el contenedor inyecta en tus otros beans cuando tu clase lleva `@Transactional`,
`@Cacheable`, `@Async`, `@Retryable` o `@PreAuthorize`.

> **🧠 Modelo mental.** Cuando el contenedor te entrega un bean, no te entrega
> necesariamente **tu** objeto: te entrega lo que salió de la fase 6 del arranque (`02`),
> que puede ser tu objeto envuelto en una o varias capas. Todas las rarezas de este
> capítulo salen de ahí.

---

## 2. 🧱 Quién crea el proxy, y cuándo

El proxy lo crea un `BeanPostProcessor` durante el arranque, después de construir el
objeto y de inyectarle sus dependencias:

```text
3. constructor          ──►  tu objeto existe
4. inyección de campos  ──►  tu objeto está completo
6. BeanPostProcessor    ──►  ¿alguna anotación pide interceptar?
                             sí → se crea el proxy y SE REGISTRA EL PROXY
                             no → se registra tu objeto
```

Dos consecuencias inmediatas, y las dos se preguntan:

- **La decisión se toma una sola vez, en el arranque.** Un método al que le añades
  `@Transactional` en caliente no existe: no hay caliente.
- **`@PostConstruct` corre sobre el objeto interno**, no sobre el proxy, porque ocurre en
  la fase 7 sobre la instancia que el proxy envuelve. Llamar desde ahí a un método
  `@Transactional` de la propia clase no abre transacción. No avisa.

---

## 3. ⚖ JDK dynamic proxy vs CGLIB

Spring tiene dos formas de fabricar el proxy, y conocerlas explica media docena de
errores:

| | **JDK dynamic proxy** | **CGLIB** |
|---|---|---|
| Cómo lo hace | Implementa las **interfaces** del bean | Genera una **subclase** del bean |
| Requiere | Que la clase implemente al menos una interfaz | Que la clase no sea `final` |
| El proxy es asignable a | La interfaz, **no** a la clase concreta | La clase concreta |
| No puede interceptar | Métodos que no están en la interfaz | Métodos `final`, `private` o `static` |

**En Spring Boot, CGLIB es el default**: Boot activa `spring.aop.proxy-target-class=true`,
así que proxya por subclase aunque haya interfaces. Es una decisión deliberada, porque el
proxy JDK produce un error desconcertante:

```text
BeanNotOfRequiredTypeException: Bean named 'inventoryService' is expected to be of type
'com.invlab.invapi.inventory.InventoryService' but was actually of type
'jdk.proxy2.$Proxy142'
```

- **Qué pasó:** el bean implementa `InventoryRepository`, Spring hizo un proxy JDK que
  implementa esa interfaz, y alguien intentó inyectarlo declarando **la clase concreta**.
  El proxy no es de esa clase: es un objeto que implementa la misma interfaz.
- **La lección de diseño** está en el error: **inyecta por interfaz**. Es la regla que
  hace que el tipo de proxy deje de importarte.

Y la trampa propia de CGLIB, que sorprende incluso a gente con años:

> **⚠️ El proxy CGLIB no ejecuta el constructor de tu clase** —Spring lo instancia con
> Objenesis— así que **sus campos quedan a `null`**. No pasa nada mientras todo el acceso
> sea por métodos, porque el proxy delega en el objeto real. Rompe en cuanto algo accede a
> un campo directamente a través del proxy: `protected` leído desde una subclase, o
> reflexión de una librería. El síntoma es un `NullPointerException` sobre un campo que
> "claramente" se asignó en el constructor.

---

## 4. 🧱 El vocabulario de AOP, en una pantalla

```text
aspect      la unidad que agrupa el comportamiento transversal     @Aspect
join point  un punto donde se puede intervenir                      en Spring: SIEMPRE
                                                                    la ejecución de un método
pointcut    la expresión que selecciona join points                 execution(...), @annotation(...)
advice      el código que se ejecuta en ese punto                   @Before, @After…
weaving     el momento de unir advice y código                      en Spring: runtime, vía proxy
```

- **Quién enciende esto.** En un proyecto Boot no escribes `@EnableAspectJAutoProxy`: la
  autoconfiguración de AOP la activa en cuanto `spring-boot-starter-aop` está en el
  classpath, y `spring.aop.proxy-target-class` decide JDK o CGLIB. Se escribe a mano solo
  en un contexto de Spring Framework sin Boot, o para forzar `proxyTargetClass = true` en
  una configuración concreta.
- **En Spring, el único join point es la ejecución de un método de un bean.** No hay
  interceptación de campos, ni de constructores, ni de llamadas internas. AspectJ real sí
  puede, a cambio de tejer en tiempo de compilación o de carga.
- **Los cinco advices:** `@Before`, `@AfterReturning`, `@AfterThrowing`, `@After` (sale
  siempre, como un `finally`) y `@Around`, que los engloba a todos y es el único que
  decide si la llamada llega a ocurrir. `@Transactional` es conceptualmente un `@Around`.

Un aspecto mínimo, completo y explicado:

```java
@Aspect
@Component
class TimingAspect {

    private static final Logger log = LoggerFactory.getLogger(TimingAspect.class);

    // selecciona: cualquier método público de cualquier clase del paquete inventory
    @Around("execution(public * com.invlab.invapi.inventory..*(..))")
    Object time(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.nanoTime();
        try {
            return pjp.proceed();               // sin esto, el método nunca se ejecuta
        } finally {
            // se registra igual si el método lanzó: el finally es el punto del ejercicio
            log.debug("{} tardó {} ms", pjp.getSignature().toShortString(),
                      (System.nanoTime() - start) / 1_000_000);
        }
    }
}
```

- **`@Aspect` no crea el bean**: hace falta `@Component` (o un `@Bean`) además. Un aspecto
  sin registrar es el error más tonto de este capítulo y no da ninguna señal.
- **`execution(public * com.invlab.invapi.inventory..*(..))`**: `public` la visibilidad,
  `*` cualquier tipo de retorno, `inventory..*` el paquete y sus subpaquetes, `(..)`
  cualquier lista de argumentos.
- **`pjp.proceed()`** invoca al siguiente eslabón —otro advice o tu método—. Olvidarlo
  hace que el método nunca se ejecute y que devuelva `null` sin error, que es de los
  fallos más difíciles de diagnosticar del framework.
- **`throws Throwable`** es obligatorio: el advice tiene que poder propagar cualquier cosa
  que lance el método envuelto.

---

## 5. ⚠️ Self-invocation: el fallo silencioso número uno

```java
@Service
class InventoryService {

    public void importAll(List<InventoryEvent> events) {
        for (InventoryEvent event : events) {
            record(event);           // ojo: llamada interna, this.record(...)
        }
    }

    @Transactional
    public void record(InventoryEvent event) { … }
}
```

**No hay transacción.** Ninguna. Y no hay error, ni log, ni aviso.

```text
otro bean ──► [ proxy ] ──► importAll()  ──► this.record()  ──► el objeto, directo
                  ▲                                                   │
                  └───────────── el proxy ya no está en medio ─────────┘
```

El proxy envuelve al objeto **desde fuera**. En cuanto la ejecución entra en tu clase,
`this` es el objeto real, no el proxy, y cualquier llamada interna se salta la capa
entera.

> **Regla mental:**
>
> ```text
> misma clase  → no hay proxy  → no hay transacción, ni caché, ni retry, ni async
> otro bean    → hay proxy     → la anotación hace lo que promete
> ```

Las tres salidas, en orden de preferencia:

1. **Separar el bean.** Mueve `record()` a otro `@Service` e inyéctalo. Es la solución
   correcta el 90 % de las veces, y además suele revelar que la clase hacía dos cosas.
2. **Auto-inyectarse el proxy.** Inyectar `InventoryService` en sí mismo —o usar
   `AopContext.currentProxy()` con `exposeProxy = true`— y llamar a `self.record(event)`.
   Funciona, se lee fatal, y deja un ciclo de dependencia que hay que declarar.
3. **AspectJ real** con weaving en tiempo de carga: intercepta de verdad la llamada
   interna. Resuelve el caso general y añade una capa de build y de operación que rara vez
   vale la pena.

> **⚠️ Esto no es exclusivo de `@Transactional`.** Exactamente el mismo fallo, con el
> mismo silencio, afecta a `@Cacheable` (`17`), `@Async` (`18`), `@Retryable` y
> `@CircuitBreaker` (`19`) y a `@PreAuthorize` ([`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero)). Cuando una anotación declarativa
> "no hace nada", esta es la primera hipótesis, siempre.

---

## 6. 🧱 Lo que un proxy no puede interceptar

| Modificador | Qué pasa | Señal |
|---|---|---|
| `private` | La anotación se ignora | ninguna |
| `final` (método) | La anotación se ignora | ninguna, salvo un `INFO` de CGLIB |
| `static` | La anotación se ignora | ninguna |
| `final` (clase) | No se puede proxyar | error en el arranque |
| llamada interna | El proxy no participa | ninguna |

Lo importante de esa tabla es la columna de la derecha: **cuatro de los cinco casos no
producen ninguna señal**. El compilador no se queja, el arranque no falla, el log calla.
El código se ve correcto y no lo es.

> **💡 Truco de revisión de código.** Un `@Transactional`, `@Cacheable` o `@Async` sobre un
> método que no sea `public` de una clase no `final`, invocado desde otro bean, es
> sospechoso por defecto. Es una de las cosas que más rápido se revisan y más caro cuestan.

---

## 7. ⚖ Cuando hay varios proxies sobre el mismo método

Un método puede estar anotado con `@Transactional`, `@Cacheable` y `@Retryable` a la vez.
Spring no crea tres proxies: crea uno con una **cadena de interceptores**, y el orden en
que se apilan cambia el resultado.

```text
retry( cache( transacción( tu método ) ) )      el retry reintenta la transacción entera
transacción( retry( cache( tu método ) ) )      una sola transacción, abierta durante
                                                todos los reintentos
```

La segunda versión mantiene una conexión de base de datos retenida mientras se espera el
backoff de los reintentos. Con veinte requests concurrentes, el pool se agota ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md)) y el
servicio cae por un mecanismo que se puso para hacerlo más resistente.

> **⏱️ Lo que retiene el orden malo.** Una conexión del pool × la duración total del
> backoff × las peticiones concurrentes. Con tres intentos, un segundo de espera entre
> ellos y veinte peticiones a la vez, son veinte conexiones retenidas durante dos
> segundos: un Hikari por defecto tiene **diez**. El pool se agota antes que el proveedor
> se recupere.

Y este es el orden por defecto de cada mecanismo, que es lo que gobierna cuando no dices
nada. **Menor `order` = más precedencia = más afuera en la cadena:**

| Mecanismo | Orden por defecto | Dónde se cambia |
|---|---|---|
| `@Transactional` | `Ordered.LOWEST_PRECEDENCE` — el más interno posible | `@EnableTransactionManagement(order = …)` |
| `@Cacheable`, `@CacheEvict` | `Ordered.LOWEST_PRECEDENCE`, igual que el anterior | `@EnableCaching(order = …)` |
| `@Async` | `Ordered.LOWEST_PRECEDENCE`, igual que los dos anteriores | `@EnableAsync(order = …)` |
| Resilience4j | orden propio y documentado: `Retry( CircuitBreaker( RateLimiter( TimeLimiter( Bulkhead ))))` | `resilience4j.retry.retry-aspect-order` y sus hermanas |
| Tu `@Aspect` | `Ordered.LOWEST_PRECEDENCE` si no declaras nada | `@Order` sobre la clase del aspecto |

- **Las tres primeras filas empatan a propósito.** Spring registra `@Transactional`,
  `@Cacheable` y `@Async` con la misma precedencia, y un empate no define quién queda
  fuera: el resultado depende del orden de registro, que no es contrato.
- **Resilience4j es la excepción**: trae un orden relativo entre sus propios mecanismos,
  y lo respeta. Lo que no define es dónde queda respecto de `@Transactional`, que es
  justo el cruce peligroso del ejemplo de arriba.
- **La regla práctica:** si dos de estas anotaciones conviven en el mismo método, declara
  el orden. Si te da pereza, sepáralas en dos beans y el problema desaparece con ellas.

> **⚠️ El orden por defecto entre estos interceptores no está garantizado**: varios se
> registran con la precedencia más baja posible, y coincidir en precedencia deja el
> resultado sin definir. Si te importa —y en el ejemplo de arriba te importa—, se declara
> explícitamente con `@Order` sobre tus aspectos, o con las propiedades de orden que
> exponga la librería. El caso concreto del apilado de resiliencia se decide en `19`, que
> es donde tiene su contexto.

---

## 8. 🩺 Cómo saber si un bean está proxyado

Tres comprobaciones, de la más barata a la más concluyente:

1. **Imprime la clase**: `log.info("{}", service.getClass())`. Un
   `InventoryService$$SpringCGLIB$$0` es un proxy CGLIB; un `jdk.proxy2.$Proxy142` es uno
   JDK; el nombre limpio significa que **no hay proxy** — y si esperabas uno, ahí está tu
   bug.
2. **`AopUtils.isAopProxy(bean)`** y sus hermanos `isCglibProxy` / `isJdkDynamicProxy`,
   que es lo mismo pero comprobable en un test.
3. **Sube el log a `DEBUG`** en `org.springframework.transaction.interceptor` (o en el
   paquete del mecanismo que estés investigando) y mira si aparece la línea de apertura.
   Si no aparece, el interceptor no corrió. Esto es lo que se practica en
   [`L04`](l04-datos-y-transacciones.md).

---

## 9. ⚠️ Errores frecuentes

- **"Las anotaciones de Spring son magia del compilador."** Son metadatos leídos en el
  arranque para decidir a quién envolver. Nada se genera al compilar.
- **"`@Transactional` abre una transacción."** Le dice a un proxy que le pida al
  `TransactionManager` que abra una. Sin proxy en medio, la anotación es un comentario.
- **"Si el método es `public` ya está."** También tiene que llamarse desde fuera del bean.
- **"`@Aspect` basta para que el aspecto funcione."** Falta registrarlo como bean.
- **"Da igual el orden de las anotaciones en el método."** El orden del código fuente no
  significa nada; el que cuenta es el de los interceptores, y se declara aparte.

---

## 🧠 Preguntas rápidas

1. "`@Transactional` abre una transacción": corrige la frase. ¿Qué te entrega realmente
   el contenedor al inyectar ese bean, y en qué fase del arranque se decidió?
2. Explica la diferencia entre un proxy JDK y uno CGLIB, y di cuál usa Spring Boot por
   defecto y por qué.
3. Lees `BeanNotOfRequiredTypeException: … but was actually of type jdk.proxy2.$Proxy142`.
   ¿Qué ocurrió y cuál es la corrección de diseño?
4. ¿Por qué los campos de un proxy CGLIB están a `null`, y cuándo se convierte eso en un
   problema real?
5. ¿Cuál es el único join point que soporta Spring AOP, y qué implica esa limitación?
6. ¿Qué pasa si un `@Around` olvida llamar a `proceed()`?
7. Dibuja o describe por qué una llamada interna se salta el proxy.
8. Nombra las tres salidas a la self-invocation y di cuál es la correcta por defecto.
9. Cinco anotaciones distintas del curso sufren exactamente el mismo fallo de
   self-invocation. Nómbralas.
10. ¿En cuáles de estos casos se ignora la anotación **sin ninguna señal**: método
    `private`, método `final`, clase `final`, método `static`?
11. Un método lleva `@Transactional` y `@Retryable`. Describe los dos órdenes posibles y
    qué recurso se agota con el orden equivocado.
12. ¿Cómo compruebas en treinta segundos si un bean está proxyado?
13. ¿Por qué un método `@Transactional` llamado desde `@PostConstruct` no abre
    transacción?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Aspect Oriented Programming: https://docs.spring.io/spring-framework/reference/6.2/core/aop.html
- Spring Framework 6.2 — Mecanismos de proxy (JDK vs CGLIB): https://docs.spring.io/spring-framework/reference/6.2/core/aop/proxying.html
- Spring Framework 6.2 — Limitaciones de los proxies: https://docs.spring.io/spring-framework/reference/6.2/core/aop/introduction-proxies.html
- Spring Framework 6.2 — Declarar un `@Aspect`: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/at-aspectj.html
- Spring Framework 6.2 — Pointcuts: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/pointcuts.html
- Spring Framework 6.2 — Tipos de advice: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/advice.html
- Spring Framework 6.2 — Habilitar el soporte de `@AspectJ`: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/aspectj-support.html
- Spring Framework 6.2 — AspectJ con weaving real: https://docs.spring.io/spring-framework/reference/6.2/core/aop/aspectj-programmatic.html
- Spring Boot 3.5 — Propiedades de configuración (`spring.aop.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
