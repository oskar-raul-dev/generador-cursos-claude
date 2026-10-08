# 01 — Patrones en Spring

> Reconocer en Spring los patrones del corpus —Proxy, Template Method, Chain of Responsibility, Observer, Factory, Strategy
> y el "singleton" del contenedor— y **las trampas que cada uno produce**. Es un capítulo de mapa: cada sección dice dónde
> está el patrón, cómo se ve en el código y qué muerde. **Lenguaje:** solo Java (§5.2 de la guía), contra la referencia de
> **Spring Framework 7.0**. **Ruta corta**: se lee solo. Lo que asume, en una línea: un **proxy** es un objeto que se pone
> delante de otro con la misma interfaz y añade algo antes y después de delegar; un **bean** es un objeto que crea y conecta
> el contenedor de Spring; y la **inyección de dependencias** es recibir los colaboradores por constructor en lugar de
> buscarlos. El detalle de cada patrón está en su capítulo, enlazado en su sección.
>
> **Vigencia:** 2026-10-04.
>
> **Versiones ejecutadas:** JDK 21.0.12, 17.0.20 y 25.0.4 · Spring Boot 4.1.1 (Spring Framework 7.0.9, Hibernate 7.4.5, H2 2.4.240) · Spring Security 7.1.1 (2026-10-04).

---

## 1. 🎯 El problema

Tres incidencias de la misma semana, en el mismo servicio:

```java
// no compila: esquema, con los cuerpos omitidos
@Service
public class ServicioCuentas {
    public void cerrarMes(List<CuentaId> cuentas) {
        cuentas.forEach(this::cobrarComision);                 // 1. ¿se cobra cada una en su transacción?
    }
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cobrarComision(CuentaId id) { ... }

    @Cacheable("tarifas")
    public Tarifas tarifas() { ... }
    public Dinero comision(Cuenta c) { return tarifas().para(c); }   // 2. ¿por qué consulta la base cada vez?
}
```

- La comisión de cada cuenta no corre en su propia transacción: si falla la cuenta 300, se deshacen las 299 anteriores.
- Las tarifas se consultan en cada llamada, aunque el método tiene `@Cacheable`.
- Y en la revisión de diseño alguien dijo "Spring usa el patrón Singleton, así que nuestros servicios son Singletons", y nadie
  supo responder si eso era cierto.

Las tres tienen la misma raíz: no saber **qué patrón** está usando Spring por debajo. Las dos primeras son el Proxy; la tercera
es confundir un alcance del contenedor con un patrón del GoF.

---

## 2. 🔭 Proxy: `@Transactional`, `@Cacheable`, `@Async`

**Dónde está.** Cada anotación de comportamiento transversal funciona porque Spring pone un **proxy** delante del bean: quien
inyecta `ServicioCuentas` recibe el proxy, que abre la transacción, mira la caché o lanza el hilo, y después llama al objeto
real. La referencia de Spring AOP dice que usa proxies dinámicos del JDK si el objeto implementa interfaces, o CGLIB si no; Spring
Boot usa CGLIB por defecto. Es el Proxy de [`05/03`](../05-estructurales/03-proxy.md).

**La trampa: la autoinvocación.** `this.cobrarComision(id)` llama al objeto real, **no al proxy**: la anotación no se aplica. La
documentación de la caché lo dice igual que la de transacciones: en modo proxy, solo se interceptan las llamadas externas que
entran por el proxy, y la autoinvocación no produce caché aunque el método esté anotado. Lo mismo vale para los métodos `final` y
`private`, que el proxy de subclase no puede sobrescribir.

**La salida.** Mover el método anotado a otro bean, y llamarlo a través de su referencia inyectada:

```java
@Service
public class CierreMensual {
    private final CobroComisiones cobros;                        // otro bean: la llamada pasa por su proxy
    public CierreMensual(CobroComisiones cobros) { this.cobros = cobros; }

    public void cerrarMes(List<CuentaId> cuentas) {
        cuentas.forEach(cobros::cobrar);                         // cada una en su transacción
    }
}

@Service
public class CobroComisiones {
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cobrar(CuentaId id) { /* carga, cobra y guarda la cuenta */ }
}
```

- Inyectarse a sí mismo o pedir el proxy actual también funcionan, y esconden el problema en lugar de resolverlo: dos
  responsabilidades en una clase. La separación es mejor diseño además de funcionar.

---

## 3. 🔭 Template Method y *callbacks*: `JdbcTemplate`, `TransactionTemplate`

**Dónde está.** `JdbcTemplate` es, según su referencia, la clase central del núcleo JDBC: crea y libera los recursos, ejecuta el
flujo de JDBC y deja al código de la aplicación solo el SQL y la extracción de resultados. El algoritmo fijo (abrir, preparar,
ejecutar, cerrar, traducir excepciones) es de Spring; el paso variable lo pone el llamador como *callback*. Es el Template Method
de [`06/02`](../06-comportamiento/02-template-method.md) en su forma por composición: el paso no se hereda, se pasa.

```java
List<Cuenta> cuentas = jdbc.query(
        "SELECT numero, saldo, moneda FROM cuenta WHERE titular_id = ?",
        (rs, fila) -> new Cuenta(new CuentaId(rs.getString("numero")),                // el RowMapper: el paso variable
                                 new Dinero(rs.getBigDecimal("saldo"), Currency.getInstance(rs.getString("moneda")))),
        titular.valor());
```

- `TransactionTemplate` hace lo mismo con la transacción: `plantilla.execute(estado -> ...)` abre, ejecuta el *callback* y confirma
  o deshace. Es la alternativa programática a `@Transactional`, sin proxy y sin trampa de autoinvocación.

**La trampa.** Ninguna propia del patrón; el error habitual es abrir conexiones a mano dentro del *callback*, que el patrón existía
para evitar. Y `RestTemplate`, del mismo estilo, figura en la referencia actual como **obsoleto en favor de `RestClient`**, una API
fluida: el patrón cambió de forma, no de propósito.

---

## 4. 🔭 Chain of Responsibility: los filtros de seguridad y los interceptores

**Dónde está.** Cada petición HTTP atraviesa una cadena: los filtros del contenedor de *servlets*, el `FilterChainProxy` de Spring
Security —que usa un `SecurityFilterChain` para decidir qué filtros de seguridad se invocan en esa petición— y los
`HandlerInterceptor` de Spring MVC alrededor del controlador. Cada eslabón hace lo suyo y pasa al siguiente, o corta la cadena con
un `401` o un `403`. Es la Chain of Responsibility de [`06/05`](../06-comportamiento/05-chain-of-responsibility.md), en su variante
donde varios eslabones actúan.

```java
@Bean
SecurityFilterChain cadena(HttpSecurity http) throws Exception {
    return http
            .authorizeHttpRequests(a -> a.requestMatchers("/api/cuentas/**").authenticated())
            .httpBasic(Customizer.withDefaults())
            .build();
}
```

- Lo que la regla no nombra **no queda abierto**: con solo esta regla, una ruta como `/publico` responde `401` sin
  credenciales y `403` con ellas (Spring Security 7.1, comprobado). Lo público se declara con `permitAll()`, y la última
  regla de la lista suele ser `anyRequest()`, para que la decisión por defecto quede escrita.

**La trampa.** El **orden**: un filtro propio registrado antes que la autenticación ve peticiones sin usuario. Y lo que un eslabón
pone en el contexto (el usuario, en un `ThreadLocal`) lo tiene que quitar la cadena al terminar, como en
[`10/01` §5](../10-concurrencia/01-inmutabilidad-y-confinamiento.md#5--thread-specific-storage).

---

## 5. 🔭 Observer: los eventos de la aplicación

**Dónde está.** `ApplicationEventPublisher.publishEvent(evento)` notifica a los métodos anotados con `@EventListener`; la referencia
lo presenta como el patrón Observer estándar. Es el Observer de [`06/03`](../06-comportamiento/03-observer.md), y la vía con que
Spring Data publica los eventos de dominio de [`09/02`](../09-ddd-tactico-y-otros/02-eventos-servicios-y-fabricas.md#2--domain-event).

```java
@Component
class AvisoVencimiento {
    @TransactionalEventListener                                  // AFTER_COMMIT por defecto
    void on(DocumentoVencido e) { correo.enviarA(e.persona(), "Tu " + e.tipo() + " venció"); }
}
```

**La trampa.** `@EventListener` es **síncrono** y corre dentro de la transacción del que publica: un correo enviado ahí sale aunque la
transacción se deshaga. Lo que no se puede deshacer va con `@TransactionalEventListener`, que por defecto corre después del
*commit*, y que **no se ejecuta** si no hay transacción activa, salvo que se pida con `fallbackExecution`.

---

## 6. 🔭 Factory: el contenedor, `@Bean` y `FactoryBean`

**Dónde está.** El contenedor entero es una fábrica: `BeanFactory` es la interfaz que crea y entrega los beans. Cada método `@Bean`
es un Factory Method ([`04/01`](../04-creacionales/01-factory-method.md)) que el contenedor llama una vez por alcance. Y
`FactoryBean` es, según la referencia, un punto de extensión de la lógica de creación del contenedor: un bean que **fabrica** otro,
para inicializaciones complejas.

```java
@Bean
Clock reloj() { return Clock.system(ZoneId.of("America/Bogota")); }    // un Factory Method que el contenedor llama
```

**La trampa.** Pedirle beans al contenedor desde el código de negocio (`contexto.getBean(...)`) convierte la fábrica en un Service
Locator ([`12/04` §3](../12-antipatrones/04-el-patron-mal-usado.md#3-️-service-locator)). La fábrica se usa en la configuración; el
negocio recibe sus dependencias por constructor.

---

## 7. 🔭 Strategy: las interfaces conectables

**Dónde está.** Casi todo lo que Spring permite cambiar es una interfaz con varias implementaciones elegidas por configuración:
`PlatformTransactionManager` (JDBC, JPA, JTA), `HttpMessageConverter` (JSON, XML), `PasswordEncoder`, `CacheManager`. El código que
las usa no sabe cuál le tocó. Es el Strategy de [`06/01`](../06-comportamiento/01-strategy.md), con el contenedor como quien elige.

**La trampa.** Dos implementaciones del mismo tipo en el contexto, y el arranque falla porque no sabe cuál inyectar: hay que decir
cuál con `@Primary` o con `@Qualifier`. Y lo inverso: una interfaz propia con una sola implementación "porque Spring es así" es
*patternitis* ([`12/04` §5](../12-antipatrones/04-el-patron-mal-usado.md#5-️-patternitis)).

---

## 8. 🔭 El "singleton" del contenedor no es el Singleton del GoF

**Dónde está.** El alcance por defecto de un bean es `singleton`: una instancia por bean y por contenedor. La referencia lo distingue
de forma explícita: el Singleton del GoF fija una sola instancia de una clase **por cargador de clases**; el de Spring es **por
contenedor y por bean**.

**Lo que cambia.** El de Spring no tiene acceso global (llega por inyección), puede haber dos beans de la misma clase, y en las pruebas
se da otra instancia sin trucos. Conserva lo útil del Singleton —una instancia compartida— y quita lo que cuesta
([`04/05`](../04-creacionales/05-singleton.md)).

- "Spring usa el patrón Singleton" es la simplificación. Usa un **alcance** singleton; el patrón del GoF es justo lo que el
  contenedor permite no escribir.

**La trampa.** Un bean `singleton` lo comparten todos los hilos: un campo mutable en un `@Service` (un contador, una lista de
"resultados de la petición actual") es estado compartido sin sincronizar. Los beans singleton van sin estado mutable, o con el de
[`10/01`](../10-concurrencia/01-inmutabilidad-y-confinamiento.md).

---

## 9. 🧭 Cómo se reconoce

| Pieza de Spring | Patrón | La trampa que produce |
|---|---|---|
| `@Transactional`, `@Cacheable`, `@Async` | Proxy | La autoinvocación y los métodos `final` o `private` no pasan por el proxy |
| `JdbcTemplate`, `TransactionTemplate` | Template Method con *callbacks* | `RestTemplate` está obsoleto: `RestClient` |
| `SecurityFilterChain`, `HandlerInterceptor` | Chain of Responsibility | El orden de los eslabones; limpiar el contexto al terminar |
| `ApplicationEventPublisher`, `@EventListener` | Observer | Síncrono y dentro de la transacción; lo irreversible, después del *commit* |
| `BeanFactory`, `@Bean`, `FactoryBean` | Factory | `getBean` en el negocio es un Service Locator |
| `PlatformTransactionManager`, `HttpMessageConverter` | Strategy | Dos candidatas sin `@Primary` o `@Qualifier` |
| Alcance `singleton` | Ninguno del GoF: un alcance | Estado mutable compartido entre hilos |

**La frase en voz alta:** *"`@Transactional` funciona porque Spring pone un proxy delante del bean; por eso la llamada interna con
`this` no abre transacción. Y Spring no usa el patrón Singleton: usa un alcance singleton, una instancia por contenedor que llega por
inyección, sin acceso global."*

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Spring usa el patrón Singleton" | Usa un alcance singleton, por contenedor y por bean; el Singleton del GoF es por cargador de clases y con acceso global |
| "`@Transactional` funciona en cualquier llamada" | Solo en las que entran por el proxy; la autoinvocación no |
| "`@Cacheable` en un método interno cachea" | La documentación lo dice: en modo proxy, la autoinvocación no produce caché |
| "`@EventListener` corre después del *commit*" | Es síncrono y corre dentro; después del *commit* es `@TransactionalEventListener` |
| "Un `@Service` puede tener campos mutables" | Lo comparten todos los hilos; sin estado mutable, o con estado seguro |
| "`RestTemplate` es la forma de llamar a un API" | La referencia actual lo marca obsoleto en favor de `RestClient` |
| "Pedir beans al contexto es inyección" | Es un Service Locator; la inyección es recibir por constructor |

---

## 📚 Para profundizar

- **Libro** — Seemann y van Deursen, *Dependency Injection Principles, Practices, and Patterns* (Manning, 2019), cap. 4, "DI
  patterns", y cap. 5, "DI anti-patterns": lo que el contenedor hace por ti y lo que no debe hacer el negocio con él. **El que
  destaca.**
- [Spring — *Proxying Mechanisms*](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html): JDK contra CGLIB y la
  autoinvocación.
- [Spring — *Using @Transactional*](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html)
- [Spring — *Declarative Annotation-based Caching*](https://docs.spring.io/spring-framework/reference/integration/cache/annotations.html)
- [Spring — *Using the JDBC Core Classes*](https://docs.spring.io/spring-framework/reference/data-access/jdbc/core.html): `JdbcTemplate`.
- [Spring Security — *Servlet Architecture*](https://docs.spring.io/spring-security/reference/servlet/architecture.html): `FilterChainProxy`
  y `SecurityFilterChain`.
- [Spring — *Bean Scopes*](https://docs.spring.io/spring-framework/reference/core/beans/factory-scopes.html): el singleton del
  contenedor frente al del GoF.
- [Spring — *REST Clients*](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html): `RestClient` y el
  estado de `RestTemplate`.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md#01--patrones-en-spring).

1. ¿Qué patrón hace funcionar a `@Transactional`? 🟢
2. ¿Qué patrón es `JdbcTemplate`? 🟢
3. ¿Qué patrón es la cadena de filtros de Spring Security? 🟢
4. ¿Qué es un `FactoryBean`? 🟢
5. ¿Qué diferencia hay entre el alcance singleton de Spring y el Singleton del GoF? 🟡
6. ¿Qué diferencia hay entre `@EventListener` y `@TransactionalEventListener`? 🟡
7. ¿Qué diferencia hay entre `@Transactional` y `TransactionTemplate`? 🟡
8. ¿Qué diferencia hay entre un proxy JDK y uno CGLIB? 🟡
9. ¿Qué diferencia hay entre un `@Bean` y un `getBean` en el código de negocio? 🟡
10. ¿Por qué la autoinvocación no abre transacción? 🟠
11. ¿Por qué `@Cacheable` en un método llamado desde la misma clase no cachea? 🟠
12. ¿Por qué "Spring usa el patrón Singleton" es una simplificación? 🟠
13. ¿Por qué un campo mutable en un `@Service` es un problema? 🟠
14. ¿Qué hace Spring cuando hay dos implementaciones de la misma estrategia, y cómo se resuelve? 🟠
15. Corrige el `cerrarMes` del §1 para que cada cuenta se cobre en su propia transacción. 🔴
16. Revisa este código y di qué falla: un `@EventListener` que envía un correo y una transacción que después se deshace. 🔴
17. Escribe con `JdbcTemplate` la consulta de las cuentas de un titular y señala el paso variable. 🔴
18. Revisa este código y di qué falla: un `@Service` con un campo `List<Movimiento> porConfirmar` que llenan las peticiones. 🔴

---

**Anterior:** [`12/06` — Simulación de entrevista](../12-antipatrones/06-simulacion-de-entrevista.md) ·
**Siguiente:** [`02` — Patrones en el JDK y en la STL](02-patrones-en-el-jdk-y-la-stl.md) ·
**Relacionado:** [`05/03` — Proxy, y los tres que se confunden](../05-estructurales/03-proxy.md)
