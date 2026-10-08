# 04 — Patrones GoF que se preguntan de verdad

> No son veintitrés. En entrevista salen nueve, y salen siempre los mismos. De cada uno:
> el problema, la forma mínima en Java moderno, **dónde lo estás usando en Spring sin
> saberlo**, y el veredicto. Cierra con los que ya no se usan y por qué.
> Asume leído [`03` — Arquitecturas de aplicación](03-arquitecturas-de-aplicacion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La pregunta *"¿qué patrones de diseño conoces?"* tiene una trampa: recitar la lista de
veintitrés te pone en el grupo de los que estudiaron para el examen. Lo que separa es
responder con **dónde lo has usado** y **cuándo decidiste no usarlo**.

Y hay un segundo filtro que casi nadie pasa: la mitad del catálogo GoF existe porque
Java de 1994 no tenía funciones de primera clase. Con lambdas, `record` y `sealed`,
varios patrones se reducen a tres líneas o desaparecen. Saber cuáles es la respuesta
cara.

> **Regla de entrevista:** nombra el patrón, di dónde lo tiene Spring, y di su precio.
> Tres frases por patrón bastan.

---

## 2. 🎛️ Strategy

**El problema.** Un algoritmo que varía —cálculo de comisión por tipo de cuenta— resuelto
con un `switch` que crece en cada release y obliga a tocar la misma clase siempre.

**La forma mínima.** Una interfaz y sus implementaciones. En Java moderno, si tiene un
solo método, es una interfaz funcional y la estrategia puede ser una lambda.

```java
public interface CalculoDeComision {
    Money calcular(Cuenta cuenta, Money monto);
}

// Spring inyecta todas las implementaciones en un Map, con el nombre del bean como clave
public PagoService(Map<String, CalculoDeComision> estrategias) { ... }
```

- El `Map<String, T>` inyectado es el idioma de Spring para Strategy: **añadir una
  estrategia es añadir un bean**, sin tocar el consumidor.
- Si la estrategia no tiene estado ni dependencias, una lambda o un `enum` con método
  abstracto basta y ahorra tres archivos.

**Dónde está en Spring.** `PasswordEncoder`, `HandlerMethodArgumentResolver`,
`TaskExecutor`. Todo punto de extensión de Spring es Strategy.

> **Veredicto:** es el patrón más usado y el que mejor se defiende en entrevista. Si
> solo puedes preparar uno, prepara este.

---

## 3. 🏭 Factory Method y Abstract Factory

**El problema.** El código que usa un objeto no debería saber cómo se construye ni qué
subclase concreta recibe.

- **Factory Method**: un método que decide qué instancia devolver.
- **Abstract Factory**: una fábrica que produce **familias** de objetos que deben
  combinar entre sí (todos los widgets del mismo tema visual, todos los drivers del
  mismo motor de BD).

**Dónde está en Spring.** `BeanFactory` es literalmente el nombre. `FactoryBean<T>` es
el punto de extensión cuando construir un bean requiere lógica.

> ⚠️ **Advertencia.** La confusión clásica: Factory Method varía **un** producto por
> herencia; Abstract Factory varía **una familia** por composición. Si te piden la
> diferencia y dices "es lo mismo pero más grande", la fallas.

> **Veredicto:** en una aplicación Spring apenas escribes fábricas a mano, porque el
> contenedor **es** la fábrica. Decir eso demuestra que entiendes qué hace la inyección
> de dependencias.

---

## 4. 🧱 Builder

**El problema.** Un constructor con ocho parámetros, cinco opcionales, cuatro del mismo
tipo. Nadie recuerda el orden y el compilador no ayuda.

**La forma mínima.** En Java moderno casi siempre es `@Builder` de Lombok o un `record`
con fábricas estáticas nombradas. Escribirlo a mano solo se justifica cuando hay
**validación al construir**: el `build()` que rechaza un objeto inválido es la versión
que aporta.

**Dónde está en Spring.** `UriComponentsBuilder`, `MockMvcRequestBuilders`,
`WebClient.builder()`, `Jwts.builder()`.

> **Veredicto:** su valor real no es la legibilidad, es **garantizar que no existe un
> objeto a medio construir**. Esa frase lo conecta con invariantes y con DDD.

---

## 5. 🔌 Adapter

**El problema.** Necesitas usar una clase cuya interfaz no encaja con la que tu código
espera, y no puedes cambiar ninguna de las dos.

**Dónde está en Spring.** `HandlerAdapter`, `MessageConverter`, y sobre todo **todo el
lado derecho de una arquitectura hexagonal**: el `RepositorioDePedidosJpa` de
[`03` §3](03-arquitecturas-de-aplicacion.md#3--hexagonal-ports-and-adapters) es un
Adapter con nombre de arquitectura.

> 🧠 **Modelo mental.** Adapter es el puente entre GoF y la arquitectura: es el patrón
> que sostiene hexagonal y la capa anticorrupción de DDD. Decirlo eleva la respuesta de
> "patrón" a "decisión de arquitectura".

> **Veredicto:** el que más se usa sin llamarlo por su nombre.

---

## 6. 🎁 Decorator

**El problema.** Añadir comportamiento a un objeto —caché, logging, reintento— sin
tocar su clase ni heredar de ella.

**La forma mínima.** Implementa la misma interfaz, envuelve la instancia original,
delega y añade lo tuyo antes o después.

**Dónde está en Spring.** `BeanPostProcessor` envolviendo beans,
`HttpServletRequestWrapper`, los `Filter` de servlets encadenados, y los decoradores de
caché de Spring Cache.

> ⚠️ **Advertencia.** Decorator vs Proxy es la distinción que más se falla:
> **mismo mecanismo, distinta intención**. Decorator **añade** funcionalidad opcional y
> se apilan varios; Proxy **controla el acceso** al objeto y suele ser uno solo.

> **Veredicto:** es el argumento de por qué la composición gana a la herencia, y
> preguntarlo es casi siempre preguntar eso.

---

## 7. 👁️ Observer

**El problema.** Varios componentes deben reaccionar a un cambio sin que el emisor los
conozca.

**Dónde está en Spring.** `ApplicationEvent` con `@EventListener`, y
`@TransactionalEventListener` cuando el efecto debe ocurrir **después del commit** —que
es casi siempre lo que quieres y casi nadie usa.

```java
@TransactionalEventListener(phase = AFTER_COMMIT)
void alConfirmarPedido(PedidoConfirmado evento) { ... }
```

- Sin `AFTER_COMMIT`, el listener corre dentro de la transacción: si esta hace rollback,
  ya mandaste el correo de un pedido que no existe.
- Los eventos de Spring son **síncronos y en el mismo proceso** por defecto. No son
  mensajería: no hay durabilidad ni reintento.

> **Veredicto:** es el puente conceptual hacia [`02-eventos`](../02-eventos/). Pero deja
> clara la diferencia: Observer es en memoria, EDA es a través de un broker con
> garantías de entrega.

---

## 8. 📋 Template Method

**El problema.** Varios procesos comparten el esqueleto y difieren en un par de pasos.

**Dónde está en Spring.** `JdbcTemplate`, `RestTemplate`, `TransactionTemplate`,
`RabbitTemplate`. **El sufijo `Template` en Spring no es casualidad**: la clase pone el
esqueleto —abrir recurso, manejar errores, cerrar recurso— y tú pones el trozo variable.

> **Veredicto:** decir *"por eso se llaman `...Template`"* es la clase de detalle que
> demuestra que has leído el framework y no solo lo usas.

---

## 9. 📨 Command

**El problema.** Convertir una petición en un objeto, para poder encolarla, registrarla,
deshacerla o reintentarla.

**Dónde está.** `Runnable` y `Callable`; los mensajes de un broker; los comandos en
CQRS; los `Job` y `Step` de Spring Batch.

> **Veredicto:** es el patrón que hace posible CQRS, event sourcing y las colas de
> trabajo. Es GoF apuntando directamente a la arquitectura distribuida.

---

## 10. 🛡️ Proxy

**El problema.** Controlar el acceso a un objeto: carga perezosa, control de permisos,
caché, o ejecutar algo antes y después de cada llamada.

**Dónde está en Spring.** Es **el patrón más importante del framework** y el que explica
sus rarezas:

- `@Transactional`, `@Cacheable`, `@Async`, `@PreAuthorize` funcionan todos por proxy.
- Por eso **una llamada interna dentro de la misma clase no aplica la anotación**: la
  llamada no pasa por el proxy. Es la causa número uno de "`@Transactional` no funciona".
- Por eso `@Transactional` sobre un método `private` o `final` no hace nada.

> 🩺 **Diagnóstico.** Si te dicen "la transacción no se abre", el primer movimiento es
> preguntar si el método se llama desde **dentro de la misma clase**. Acertar esa
> pregunta vale más que cualquier definición.

> **Veredicto:** si solo entiendes un patrón de esta lista a fondo, que sea este. Explica
> la mitad del comportamiento de Spring.

---

## 11. 🪦 Los que ya no se usan, y por qué

Esta sección es la que más rinde: **nombrar tres patrones que no usarías y justificarlo
demuestra criterio, no memoria.**

| Patrón | Por qué ya no |
|---|---|
| **Singleton** | Estado global, imposible de sustituir en test, difícil con concurrencia. En Spring, el scope singleton del contenedor da lo mismo sin los defectos: una instancia, pero inyectable y reemplazable. |
| **Visitor** | Existía para simular *double dispatch*. Con `sealed` + pattern matching de `switch` (Java 21) el compilador verifica la exhaustividad, que era el único beneficio real. |
| **Flyweight** | El runtime ya lo hace: interning de `String`, caché de `Integer`, `record` inmutables. Implementarlo a mano hoy casi siempre pierde contra el JIT. |
| **Prototype** | `record` con `with`-style, `clone()` desaconsejado desde Bloch. Se resuelve con copia por constructor. |
| **Interpreter** | Salvo que escribas un motor de reglas, hay librerías mejores (SpEL, ANTLR, Drools). |

> 📝 **Contexto.** El GoF se escribió en 1994 contra C++ y Smalltalk. Varios patrones son
> **rodeos alrededor de limitaciones del lenguaje**, no verdades eternas. Decir eso —con
> un ejemplo concreto, como `sealed` matando a Visitor— es la mejor respuesta posible a
> "¿qué opinas de los patrones de diseño?".

---

## 12. 🧭 Cómo se elige

Las tres decisiones que este capítulo deja abiertas, resueltas:

```text
¿Añadir comportamiento opcional y apilable?        → Decorator
¿Controlar si la llamada llega, o cuándo?          → Proxy
   (mismo mecanismo; lo que cambia es la intención, y eso es lo que preguntan)

¿Varía UN producto por herencia?                   → Factory Method
¿Varía UNA FAMILIA que debe combinar entre sí?     → Abstract Factory
   (en una app Spring, casi nunca escribes ninguna: el contenedor ES la fábrica)

¿La estrategia tiene un método, sin estado ni dependencias?  → lambda
¿El conjunto es cerrado y conocido?                          → enum con método abstracto
¿Necesita dependencias inyectadas o crecer sin tocar código? → interfaz + beans en un Map
```

> **Regla de entrevista:** nombra el patrón, di dónde lo tiene Spring, y di su precio. Tres
> frases por patrón bastan, y la tercera es la que casi nadie dice.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Decorator y Proxy son lo mismo" | Mismo mecanismo, distinta intención: añadir vs controlar |
| "Factory Method = Abstract Factory" | Uno varía un producto, el otro una familia |
| "Uso Singleton para el servicio" | En Spring es scope, no patrón; sin estado global ni acoplamiento estático |
| "`@Transactional` en método privado" | No hace nada: el proxy no intercepta llamadas internas |
| "Strategy necesita una interfaz y tres clases" | Con un solo método, una lambda o un `enum` basta |
| "Los eventos de Spring son asíncronos" | Son síncronos por defecto, y sin durabilidad |

---

## 📚 Para profundizar

- **Libro** — Joshua Bloch, *Effective Java*, 3ª ed. (Addison-Wesley, 2018). Ítems 1–6
  (fábricas estáticas, builder, singleton), 18 (composición sobre herencia) y 13
  (`clone()`). **Más útil que el GoF original para una entrevista de Java.**
- **Libro** — Gamma, Helm, Johnson y Vlissides, *Design Patterns* (Addison-Wesley,
  1994). El original; se consulta, no se lee entero.
- **Libro** — Freeman y Robson, *Head First Design Patterns*, 2ª ed. (O'Reilly, 2021).
  Para fijar Strategy, Decorator y Observer si están flojos.
- [Refactoring Guru — Catálogo de patrones](https://refactoring.guru/design-patterns/catalog):
  la mejor referencia visual, con ejemplos en Java y la sección de "relaciones con otros
  patrones".
- [Spring Framework — Aspect Oriented Programming with Spring](https://docs.spring.io/spring-framework/reference/core/aop.html):
  cómo funcionan los proxies, y por qué la autoinvocación no los atraviesa.
- **Tutorial** — Baeldung, «Design Patterns series»:
  un artículo por patrón, en Java, con tests.
- **Video** — Devoxx y Spring I/O, charlas sobre *pattern matching* y `sealed` en Java
  moderno, para el argumento de la sección 11.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Por qué las clases `JdbcTemplate` y `RestTemplate` se llaman así? 🟢
2. ¿Qué diferencia a Decorator de Proxy? 🟡
3. ¿Qué diferencia a Factory Method de Abstract Factory? 🟡
4. ¿Qué patrón implementa `@Transactional` y qué consecuencia tiene? 🟡
5. ¿Por qué Singleton se considera hoy un antipatrón? 🟡
6. ¿Cómo inyecta Spring todas las implementaciones de una Strategy? 🟡
7. ¿Los eventos de Spring son síncronos o asíncronos? ¿Y durables? 🟡
8. ¿Qué patrón sostiene el lado derecho de una arquitectura hexagonal? 🟡
9. ¿Qué patrón GoF hace posible CQRS y las colas de trabajo? 🟡
10. ¿Por qué `@Transactional` no funciona en una llamada interna? 🟠
11. ¿Qué característica de Java 21 deja obsoleto a Visitor? 🟠
12. ¿Qué diferencia hay entre `@EventListener` y `@TransactionalEventListener`? 🟠
13. ¿Cuál es el valor real de Builder más allá de la legibilidad? 🟠
14. ¿Por qué Flyweight casi no se implementa a mano hoy en Java? 🟠
15. Nombra tres patrones que NO usarías y justifica cada uno. 🟠
16. ¿Cuándo una Strategy no merece una interfaz propia? 🟠
17. Te dicen "los patrones de diseño están obsoletos". ¿Qué respondes? 🟠
18. Tienes un `switch` de 12 casos que crece cada sprint. ¿Cómo lo atacas y qué
    pierdes al hacerlo? 🔴
19. `@Cacheable` no cachea y el método sí se ejecuta. Da tres hipótesis en
    orden de probabilidad. 🔴
20. Diseña el punto de extensión para que un banco añada un tipo de producto
    nuevo sin recompilar el core. ¿Qué patrones combinas? 🔴

---

**Anterior:** [`03` — Arquitecturas de aplicación](03-arquitecturas-de-aplicacion.md) ·
**Siguiente:** [`05` — Fowler PoEAA](05-fowler-poeaa.md) ·
**Relacionado:** [`07` — DDD táctico](07-ddd-tactico.md)
