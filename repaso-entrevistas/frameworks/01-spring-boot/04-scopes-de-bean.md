# 04 — Scopes de bean

> **Objetivo:** elegir scope con criterio, reconocer al instante el bug de mezclar scopes
> y no volver a guardar estado de un request en un singleton.
> **Asume:** [`02`](02-contenedor-ioc-y-ciclo-de-vida.md), [`03`](03-inyeccion-de-dependencias.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: cuántas instancias hay de tu servicio

Un bean es una receta (`02`). El scope decide **cuántos objetos se cocinan con ella y
cuánto viven**. Suena administrativo hasta que produce el bug más silencioso de una
aplicación Spring:

```java
@Service
class InvoiceService {
    private String currentUser;          // ojo: un campo mutable en un singleton

    void process(Invoice invoice, String user) {
        this.currentUser = user;         // dos requests simultáneos, un solo objeto
        validate(invoice);
        audit(this.currentUser);         // puede auditar al usuario del OTRO request
    }
}
```

No lanza excepción. No aparece en los tests, que corren un request por vez. Aparece en
producción, bajo carga, como una auditoría que atribuye una operación a la persona
equivocada — y en banca eso no es un bug, es un incidente.

La causa es que **hay un solo `InvoiceService` para toda la aplicación** y muchos hilos
entrando a la vez ([`08`](08-modelo-de-ejecucion-web.md)). Entender los scopes es entender exactamente cuándo pasa eso.

---

## 2. 🧱 El catálogo

| Scope | Cuántas instancias | Vive mientras | Cuándo se usa |
|---|---|---|---|
| `singleton` | **una por `ApplicationContext`** | el contexto | por defecto; servicios, repositorios, clientes |
| `prototype` | una por cada petición al contenedor | lo que la guarde quien la pidió | objetos con estado, no compartibles |
| `request` | una por request HTTP | el request | datos del request; requiere stack web |
| `session` | una por sesión HTTP | la sesión | carritos, asistentes multipaso |
| `application` | una por `ServletContext` | la aplicación web | casi nunca |
| `websocket` | una por sesión WebSocket | la sesión | apps con WebSocket |

```java
@Service
@Scope("prototype")     // o @Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
class ImportJobState { … }
```

- **La constante es preferible a la cadena** por la razón de siempre: `"prototipe"` mal
  escrito no es un error de compilación ni de arranque — el bean se queda singleton y nadie
  se entera. `ConfigurableBeanFactory.SCOPE_PROTOTYPE` no admite esa errata.
- **`@Scope` en una clase `@Component` se combina con `proxyMode`**, que es lo que decide
  si el punto de inyección recibe la instancia o un proxy que la busca en cada llamada. Sin
  eso, un bean de vida corta inyectado en un singleton se congela en la primera instancia
  (§5).

> Nunca respondas: ~~"los beans de Spring son singletons"~~
>
> Mejor: "por defecto son singleton **por contexto**, que no es el patrón Singleton: no
> hay constructor privado, no es uno por JVM, y puedes tener dos contextos en el mismo
> proceso con una instancia cada uno — que es justamente lo que pasa en los tests ([`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos))."

---

## 3. 🧱 `singleton`: uno por contexto, y qué exige a cambio

El precio del singleton es una regla que no admite excepciones:

> **🧠 Modelo mental.** Un bean singleton debe ser **stateless**: sin campos mutables. Sus
> campos son sus colaboradores, `final`, fijados en el constructor. Todo lo que cambia por
> request viaja en los argumentos del método o en el valor de retorno.

Si necesitas estado por request, tienes tres salidas honestas, en orden de preferencia:
pasarlo como parámetro (siempre la mejor), usar una variable local dentro del método —que
ya es por hilo—, o, si de verdad tiene que atravesar capas sin ensuciar las firmas,
`ThreadLocal` con sus advertencias ([`08`](08-modelo-de-ejecucion-web.md)) o un bean de scope `request`.

- **Se crean en el arranque**, no al primer uso: un error de construcción revienta al
  desplegar y no a las tres de la mañana (`02`).
- **Hay uno por contexto, no por JVM.** En una suite de tests con varios contextos
  cacheados hay varias instancias vivas a la vez, y eso explica bugs de test que no se
  reproducen en producción.

---

## 4. 🧱 `prototype`: y quién limpia después

Cada vez que alguien pide el bean, el contenedor construye uno nuevo, lo inyecta… y se
olvida de él.

> **⚠️ El contenedor no destruye los beans prototype.** No guarda referencia, así que
> **no ejecuta su `@PreDestroy`** ni ningún `destroyMethod`. Si el objeto abre un fichero,
> una conexión o un executor, liberarlo es responsabilidad de quien lo pidió. Es la
> diferencia más importante frente al singleton y la que más se falla en entrevistas.

Y la trampa que lo acompaña:

```java
@Service                                  // singleton
class ImportService {
    private final ImportJobState state;   // prototype

    ImportService(ImportJobState state) { // se inyecta UNA vez, en el arranque
        this.state = state;               // …y esa instancia se queda para siempre
    }
}
```

El `prototype` se comporta como singleton, porque quien lo inyectó es singleton y solo lo
pidió una vez. El scope del bean no manda: manda **cuántas veces se pide**.

---

## 5. 🧱 Las tres salidas al problema de scopes mixtos

Inyectar un scope corto en uno largo tiene tres soluciones, y conviene saber cuál usar:

```java
// 1. ObjectProvider — explícito y sin proxies. La preferida del curso.
@Service
class ImportService {
    private final ObjectProvider<ImportJobState> states;

    ImportService(ObjectProvider<ImportJobState> states) { this.states = states; }

    void run() {
        ImportJobState state = states.getObject();  // una nueva en cada llamada
    }
}

// 2. @Lookup — el contenedor sobreescribe el método por ti
@Service
abstract class ImportService {
    @Lookup
    protected abstract ImportJobState newState();  // devuelve una instancia nueva cada vez
}

// 3. scoped proxy — transparente en el punto de uso
@Component
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)
class RequestContext { … }
```

- **`ObjectProvider<T>`** hace visible en la firma que la resolución es tardía. No hay
  magia y se lee solo; por eso es la opción por defecto en este curso.
- **`@Lookup`** obliga a que la clase sea abstracta o el método sobreescribible, porque
  el contenedor genera una subclase. Se ve en código heredado.
- **`proxyMode = TARGET_CLASS`** inyecta un **proxy** en lugar del bean: un objeto del
  mismo tipo que, en cada llamada a un método, busca la instancia que corresponde al
  request o a la sesión actual y le delega. Es lo que permite inyectar un bean `request`
  dentro de un singleton sin que nadie se entere. El mecanismo del proxy es el de [`05`](05-proxies-y-aop.md).

> **🩺 Diagnóstico.** Si inyectas un bean `request` sin `proxyMode` en un singleton, el
> arranque falla con un mensaje que dice que no hay request activo — porque lo intenta
> resolver en el arranque, cuando no hay ninguno. Ese error, leído bien, es el diagrama
> entero del problema.

---

## 6. 🧱 Los scopes web, y dónde no existen

`request`, `session` y `application` necesitan un stack web servlet y un request en curso.
Eso tiene dos consecuencias que hay que tener claras:

> **⏱️ Lo que cuesta un bean `session`, con su unidad.** Es memoria retenida por usuario
> activo: *(usuarios con sesión viva) × (tamaño del bean)*, y la sesión no muere cuando el
> usuario se va, sino cuando expira `server.servlet.session.timeout` —30 minutos por
> defecto—. Diez mil sesiones vivas con 20 KB de estado cada una son 200 MB de heap que no
> se liberan durante media hora, y que además hay que replicar si hay más de una
> instancia. Es el argumento real contra `session` en una API, antes que el estético.

- **Fuera de un request no existen.** En un `@Async` ([`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)), en un `@Scheduled` o en un
  hilo propio, un bean `request` no se puede resolver: el `RequestContextHolder` es un
  `ThreadLocal` y el hilo nuevo no lo hereda.
- **En WebFlux no hay scope `request`.** El modelo reactivo no ata el trabajo a un hilo,
  así que no hay dónde colgarlo; el equivalente es el `Context` de Reactor ([`11`](11-webflux-y-reactor.md)). Es una
  de las diferencias que más duele al migrar, y casi nunca se menciona.

> **⚠️ El scope `session` guarda estado en el servidor**, y eso es una decisión de
> arquitectura, no de comodidad: rompe el escalado horizontal salvo que uses sticky
> sessions o un almacén compartido (`08`). En una API stateless con JWT no tiene sitio.

---

## 7. 🧱 Scopes propios

Se pueden registrar scopes nuevos implementando `Scope` y registrándolos en el
contenedor: es la vía por la que existen los scopes de tenant en aplicaciones
multi-inquilino. Se nombra aquí para que sepas que existe y que un `Scope` es una
interfaz con cuatro métodos, no una palabra reservada del framework. En una entrevista
basta con saber eso.

---

## 8. ⚠️ Errores frecuentes

- **"Singleton de Spring = patrón Singleton."** Uno por contexto, no por JVM, y sin
  constructor privado.
- **"`prototype` es como hacer `new`."** Lo es en la creación; no lo es en la destrucción
  —nadie lo destruye— ni cuando lo inyecta un singleton, que lo pide una sola vez.
- **"Si necesito datos por request, uso `session`."** `session` sobrevive al request y se
  comparte entre pestañas del mismo usuario: es otro ciclo de vida y otro problema de
  escalado.
- **"Un campo mutable en un `@Service` está bien si solo lo uso dentro del método."** Si
  se escribe en un campo, dos hilos lo comparten. La variable local es gratis y correcta.

---

## 🧠 Preguntas rápidas

1. ¿Por qué el singleton de Spring no es el patrón Singleton? Da dos diferencias.
2. ¿Cuántas instancias de un bean singleton puede haber vivas en el mismo proceso, y en
   qué situación real ocurre?
3. ¿Qué le pasa al `@PreDestroy` de un bean `prototype` y qué implica para un bean que
   abre recursos?
4. Inyectas un bean `prototype` en el constructor de un singleton. ¿Cuántas instancias se
   crean durante la vida de la aplicación?
5. Nombra las tres formas de obtener una instancia nueva de un `prototype` desde un
   singleton, y di cuál prefieres y por qué.
6. ¿Qué hace exactamente `proxyMode = ScopedProxyMode.TARGET_CLASS`?
7. Inyectas un bean de scope `request` en un singleton sin `proxyMode`. ¿Qué pasa y
   cuándo?
8. ¿Por qué un bean `request` no se puede resolver dentro de un método `@Async`?
9. ¿Por qué no existe el scope `request` en WebFlux, y qué ocupa su lugar?
10. Un `@Service` guarda el usuario actual en un campo antes de validarlo. Describe el
    fallo, por qué no aparece en los tests y cómo se corrige.
11. ¿Qué implicación de escalado tiene usar el scope `session`?
12. ¿Cuál es el scope por defecto y por qué esa elección obliga a que tus servicios sean
    stateless?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Bean Scopes: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html
- Spring Framework 6.2 — Singleton y prototype juntos: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html#beans-factory-scopes-sing-prot-interaction
- Spring Framework 6.2 — Scopes web (request, session, application): https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html#beans-factory-scopes-other
- Spring Framework 6.2 — Scoped proxies: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html#beans-factory-scopes-other-injection-proxies
- Spring Framework 6.2 — Scopes propios: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html#beans-factory-scopes-custom
