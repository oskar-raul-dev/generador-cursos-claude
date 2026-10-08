# A02 — Catálogo de anotaciones

> **Objetivo:** que puedas mirar una anotación del curso y contestar cuatro cosas sin
> abrirte el IDE: qué hace, dónde se pone, cuál es su trampa y en qué documento está
> explicada. No es un manual de referencia de Spring: es el **inventario de lo que este
> curso ya enseñó**, ordenado por familia.
> **Asume:** nada. Cada entrada es autosuficiente y cada una enlaza al sitio donde el
> mecanismo se desarrolla entero.
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Spring Security 6.5.11 · Spring Batch 5.2.6 · Resilience4j 2.2.0 · Java 21 (Temurin).

**Salto rápido:** [Cómo se usa](#1--cómo-se-usa-este-catálogo) ·
[Las que se parecen](#2--las-que-se-parecen-y-no-son-lo-mismo) ·
[Dónde no hace nada](#3-️-dónde-una-anotación-no-hace-nada) ·
[Contenedor](#4--contenedor-estereotipos-y-configuración) ·
[Inyección](#5--inyección-y-resolución-de-candidatos) ·
[Condicionales](#6--condicionales-y-autoconfiguración) ·
[Configuración](#7--configuración-externalizada) ·
[AOP](#8--aop-el-vocabulario-que-sostiene-lo-demás) ·
[Web y REST](#9--web-y-rest) ·
[Validación](#10--validación) ·
[Datos y transacciones](#11--datos-y-transacciones) ·
[Caché](#12--caché) ·
[Asincronía y eventos](#13--asincronía-scheduling-y-eventos) ·
[Resiliencia](#14--resiliencia) ·
[Seguridad](#15--seguridad) ·
[Batch](#16--batch) ·
[Testing](#17--testing) ·
[Actuator](#18--actuator-y-métricas) ·
[Alcance](#19-️-alcance-lo-que-este-catálogo-no-lista) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-10)

---

## 1. 🧭 Cómo se usa este catálogo

Este apéndice no se escribió: se **recolectó**. Cada anotación que vas a leer aquí sale de
un documento del curso donde el mecanismo está explicado con su ejemplo y su fallo, y la
última columna de cada fila te lleva exactamente a esa sección. Si una entrada te sabe a
poco, ahí está el desarrollo — y si una anotación que buscas no aparece, mira §19 antes de
suponer que se olvidó.

Todas las filas tienen la misma forma y siempre en el mismo orden:

```text
la anotación  →  qué hace y dónde se pone  →  la trampa  →  dónde se explica
```

**La trampa es la columna que justifica el apéndice.** Que `@Cacheable` cachea ya lo sabes;
lo que se olvida en una entrevista es que junto a `@CachePut` en el mismo método produce un
resultado indefinido y Spring no lo rechaza. Por eso aquí no hay una fila por cada anotación
que existe en Spring, sino una por cada anotación cuyo matiz el curso se tomó el trabajo de
explicar.

Antes de bajar a una familia, las dos preguntas que ordenan el catálogo entero.

**La primera: ¿de quién es la anotación?** Se pregunta en entrevista y casi todo el mundo
atribuye a Boot lo que es del Framework.

> **⚠️ Boot no tiene una sola anotación de negocio propia.** `@Service`, `@Transactional`,
> `@GetMapping`, `@Autowired` y `@Cacheable` son de Spring Framework. De Boot son las de
> arranque y configuración: `@SpringBootApplication`, `@ConfigurationProperties`, la familia
> `@ConditionalOn*` y los slices de test. El detalle, con el argumento completo, está en
> [`01` §3](01-spring-boot-y-el-ecosistema.md#3--qué-añade-spring-boot-exactamente).

**La segunda, que es la del curso:** *¿quién ejecuta esto, en qué hilo, y a través de qué
proxy?* Casi todo lo declarativo de este catálogo —`@Transactional`, `@Cacheable`, `@Async`,
`@Retry`, `@PreAuthorize`, `@Timed`— es **el mismo mecanismo con distinto sombrero**: un
`BeanPostProcessor` que envuelve tu bean en un proxy durante el arranque
([`05` §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo)). De ahí salen la mitad de
las trampas de este apéndice, y por eso §3 va antes que las familias.

> Nunca respondas: ~~"las anotaciones de Spring son magia del compilador"~~
>
> Mejor: "son metadatos que el contenedor lee **en el arranque** para decidir a quién
> envolver y con qué. No se genera nada al compilar, y por eso una anotación sobre un método
> que el proxy no puede interceptar no falla: simplemente no hace nada."

Los ejemplos usan los nombres fijos del laboratorio —`inv-api`, el paquete
`com.invlab.invapi`, las tablas `inventory_item` e `inventory_event`, la caché
`inventory-items`—, declarados en [`L00` §7](l00-idea-lab-practico.md#7--nombres-fijos-de-la-serie).

---

## 2. ⚖ Las que se parecen y no son lo mismo

Cinco pares que se confunden, y la confusión cuesta caro en los cinco casos. Es la tabla que
más conviene saber de memoria, porque son preguntas de entrevista literales.

| El par | La diferencia que de verdad importa | Dónde se explica |
|---|---|---|
| `@Valid` · `@Validated` | `@Valid` es de `jakarta.validation` y va en argumento o campo; `@Validated` es de Spring, va en la clase, activa la validación vía proxy y es la única que admite grupos | [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso) |
| Los dos `@Transactional` | el de Spring tiene `readOnly`, `isolation` y `timeout`; el de `jakarta.transaction` abre la transacción igual pero **no tiene esos atributos** | [`16` §7](16-transacciones.md#7--los-seis-silencios) |
| `@Component` · `@Bean` | los dos registran una bean definition; `@Component` exige que la clase sea tuya y anotable, `@Bean` construye cualquier objeto de terceros | [`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) |
| `@Mock` · `@MockitoBean` | `@Mock` te entrega a ti un objeto simulado, sin contenedor; `@MockitoBean` **sustituye un bean dentro del contexto** y cambia la clave de la caché de contextos | [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto) |
| `@RequestParam` · `@ModelAttribute` | `@RequestParam` lee un valor de la query y falla con 400 si no está; `@ModelAttribute` es lo que Spring **asume** cuando ningún resolver reconoce el tipo, y bindea por propiedades sin quejarse | [`09` §5](09-rest-con-spring-mvc.md#5--los-argumentos-del-método) |

Tres de esos cinco pares comparten la misma raíz y conviene decirla en voz alta: **el
proxy**. `@Validated` en un controller convierte un 400 de MVC en un 500 porque desvía la
validación al camino de AOP; el `@Transactional` de Jakarta funciona porque Spring lo
reconoce al construir el mismo proxy; y `@MockitoBean` sobre un bean anotado **sustituye
también su proxy**, así que el mock no tiene ni transacción, ni caché, ni reintento, y el
test pasa sin probar lo que creías.

Y dos pares más, menores pero con la misma mecánica de "se parecen y hacen lo contrario":
`@Primary` marca al **bean** como candidato por defecto mientras `@Qualifier` marca al
**punto de inyección**
([`03` §4](03-inyeccion-de-dependencias.md#4--primary-qualifier-y-los-qualifiers-propios)), y
`@Cacheable` se **salta** el método cuando hay entrada mientras `@CachePut` lo ejecuta
**siempre** ([`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato)).

---

## 3. ⚠️ Dónde una anotación no hace nada

Antes de las familias, la tabla que explica por qué una anotación correcta puede no producir
ningún efecto. Sale entera de
[`05` §6](05-proxies-y-aop.md#6--lo-que-un-proxy-no-puede-interceptar), y lo que hay que
llevarse es la columna de la derecha.

| Modificador o llamada | Qué le pasa a la anotación | ¿Hay alguna señal? |
|---|---|---|
| Método `private` | se ignora | ninguna |
| Método `final` | se ignora | ninguna, salvo un `INFO` de CGLIB |
| Método `static` | se ignora | ninguna |
| Clase `final` | no se puede proxyar | error en el arranque |
| Llamada desde la misma clase | el proxy no participa | ninguna |

**Cuatro de los cinco casos no avisan de nada**, y ese silencio es el tema. El compilador no
se queja, el arranque no falla y el log calla: el código se ve correcto y no lo es.

Y no es un problema de una anotación, sino de una lista entera. **Las mismas cinco líneas
afectan a `@Transactional`, `@Cacheable`, `@CachePut`, `@CacheEvict`, `@Async`,
`@Scheduled`, `@Retry`, `@CircuitBreaker`, `@Bulkhead`, `@PreAuthorize`, `@PostAuthorize`,
`@Timed` y `@Counted`** — cada una con su síntoma propio, que va en la fila
correspondiente de su familia. Cuando una de ellas "no hace nada", la primera hipótesis
siempre es la misma:

> **Regla mental:**
>
> ```text
> misma clase  → no hay proxy  → no hay transacción, ni caché, ni retry, ni async, ni permiso
> otro bean    → hay proxy     → la anotación hace lo que promete
> ```

Un matiz que sí cambió y que conviene tener fresco: **"solo funciona en métodos `public`" ya
no es exacto**. Desde Spring Framework 6.0, con proxies CGLIB —el default de Boot—, la
anotación se respeta también en métodos `protected` y package-private, porque la subclase
puede sobrescribirlos. Lo que nunca funciona es `private`
([`16` §7](16-transacciones.md#7--los-seis-silencios)). Y para comprobarlo en treinta
segundos, imprime la clase del bean: un `InventoryService$$SpringCGLIB$$0` es un proxy, un
nombre limpio significa que no hay ninguno
([`05` §8](05-proxies-y-aop.md#8--cómo-saber-si-un-bean-está-proxyado)).

---

## 4. 🧱 Contenedor: estereotipos y configuración

La familia de la que sale todo lo demás: quién registra un bean, cuántas instancias hay y
cuándo nace y muere cada una.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Component` | registra una bean definition de una clase tuya · clase | solo existe si la clase está bajo el paquete base del scan; si no, `NoSuchBeanDefinitionException` | [`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) |
| `@Service` | `@Component` con estereotipo · clase | para el contenedor es idéntico a `@Component`: la diferencia es semántica | [`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) |
| `@Repository` | estereotipo **con comportamiento**: traduce las excepciones del driver a `DataAccessException` · clase | es el único estereotipo que hace algo; en JDBC crudo esa traducción la aplica un proxy | [`15` §3](15-datos-jdbc-jpa-mongo-y-redis.md#3--jdbcclient-y-la-jerarquía-de-dataaccessexception) |
| `@Controller` | estereotipo web · clase | sin `@ResponseBody` un `String` devuelto es **el nombre de una vista**: 404 sobre una URL que sí mapeaste | [`09` §3](09-rest-con-spring-mvc.md#3--controller-vs-restcontroller) |
| `@Configuration` | clase de configuración, proxyada con CGLIB en modo full · clase | `proxyBeanMethods = false` apaga el proxy y una llamada entre métodos `@Bean` crea **otra** instancia | [`02` §6](02-contenedor-ioc-y-ciclo-de-vida.md#6--configuration-y-proxybeanmethods) |
| `@Bean` | escribe la receta de construcción de un objeto ajeno · método de una `@Configuration` | el nombre del bean es el **del método**: renombrarlo rompe cualquier `@Qualifier` que lo buscara | [`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) |
| `@ComponentScan` | fija desde qué paquete se escanea · clase | sin argumentos escanea desde el paquete de la clase anotada **hacia abajo**, y nada fuera de ese subárbol | [`02` §7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base) |
| `@Import` | trae una `@Configuration` esté donde esté, sin escanear · clase | es la salida que nadie recuerda cuando la clase vive fuera del paquete base | [`02` §7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base) |
| `@Scope` | cuántas instancias y cuánto viven · clase o método `@Bean` | `"prototipe"` mal escrito no falla: el bean se queda singleton y nadie se entera | [`04` §2](04-scopes-de-bean.md#2--el-catálogo) |
| `@Lookup` | el contenedor sobrescribe el método para devolver una instancia nueva · método | obliga a que la clase sea abstracta o el método sobrescribible | [`04` §5](04-scopes-de-bean.md#5--las-tres-salidas-al-problema-de-scopes-mixtos) |
| `@Lazy` | difiere la creación hasta el primer uso · clase o punto de inyección | rompe un ciclo de dependencias sin arreglar el diseño que lo produjo | [`03` §7](03-inyeccion-de-dependencias.md#7--dependencias-circulares) |
| `@PostConstruct` | inicialización después de la inyección · método | corre sobre el **objeto interno**, no sobre el proxy: un `@Transactional` llamado desde ahí no abre transacción | [`02` §4](02-contenedor-ioc-y-ciclo-de-vida.md#4--las-fases-del-arranque) |
| `@PreDestroy` | cierre ordenado del bean · método | los beans `prototype` **nunca lo ejecutan**: el contenedor no guarda referencia | [`04` §4](04-scopes-de-bean.md#4--prototype-y-quién-limpia-después) |
| `@Order` | precedencia entre beans del mismo tipo · clase, método `@Bean` o aspecto | ordena listas inyectadas, filtros y cadenas de Security, **no** los interceptores de un proxy | [`03` §5](03-inyeccion-de-dependencias.md#5--inyectar-varios-el-strategy-que-sale-gratis) |
| `@SpringBootApplication` | la clase de arranque · clase | son tres anotaciones en una, y `@SpringBootConfiguration` debe ser **única** en el subárbol | [`06` §3](06-arranque-y-autoconfiguracion.md#3--springbootapplication-son-tres-anotaciones) |
| `@SpringBootConfiguration` | marca la `@Configuration` principal · clase | es lo que busca `@SpringBootTest` para localizar tu configuración sin que se la digas | [`06` §3](06-arranque-y-autoconfiguracion.md#3--springbootapplication-son-tres-anotaciones) |
| `@EnableAutoConfiguration` | activa el catálogo de autoconfiguraciones · clase | se escribe a mano solo cuando separas las tres de arriba para poner filtros al scan | [`06` §3](06-arranque-y-autoconfiguracion.md#3--springbootapplication-son-tres-anotaciones) |
| `@AutoConfiguration` | sustituye a `@Configuration` en una autoconfiguración propia y añade `after` / `before` · clase | hay que declarar la clase en `AutoConfiguration.imports`, o **no se carga y no hay error** | [`06` §8](06-arranque-y-autoconfiguracion.md#8--escribir-tu-propia-autoconfiguración) |

Tres cosas que no caben en una celda y se preguntan seguido.

- **El scope no manda: manda cuántas veces se pide el bean.** Un `prototype` inyectado en el
  constructor de un singleton se comporta como singleton, porque quien lo inyectó lo pidió
  una sola vez. Las tres salidas —`ObjectProvider`, `@Lookup` y el scoped proxy— están en
  [`04` §5](04-scopes-de-bean.md#5--las-tres-salidas-al-problema-de-scopes-mixtos), y la
  preferida del curso es la primera porque hace visible en la firma que la resolución es
  tardía.
- **`@Scope` casi nunca va solo.** Para inyectar un bean `request` o `session` dentro de un
  singleton hace falta `proxyMode = ScopedProxyMode.TARGET_CLASS`; sin él, el arranque falla
  diciendo que no hay request activo, porque lo intenta resolver cuando no hay ninguno
  ([`04` §6](04-scopes-de-bean.md#6--los-scopes-web-y-dónde-no-existen)).
- **`@PostConstruct` no es "el constructor pero mejor".** Corre en la fase 7 del arranque,
  sobre la instancia que el proxy envuelve. El sitio correcto para el trabajo transaccional
  de arranque es un `ApplicationRunner`, que se ejecuta con el contexto ya completo y
  recibiendo proxies ([`06` §9](06-arranque-y-autoconfiguracion.md#9--código-que-corre-al-arrancar)).

---

## 5. 🧱 Inyección y resolución de candidatos

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Autowired` | marca un punto de inyección · constructor, campo o setter | con un solo constructor **se omite**; con dos y ninguno anotado el arranque falla hablando de un constructor por defecto, sin mencionar la ambigüedad | [`03` §2](03-inyeccion-de-dependencias.md#2--autowired-cuándo-hace-falta-escribirlo) |
| `@Qualifier` | cualifica el **punto de inyección** · parámetro, campo o método `@Bean` | con una cadena es magia: un renombrado la rompe y el compilador calla. La versión robusta es un qualifier propio | [`03` §4](03-inyeccion-de-dependencias.md#4--primary-qualifier-y-los-qualifiers-propios) |
| `@Primary` | marca el **bean** como candidato por defecto · clase o método `@Bean` | resuelve bien con un default obvio y una excepción rara; con tres candidatos iguales, el modelo correcto era otro | [`03` §4](03-inyeccion-de-dependencias.md#4--primary-qualifier-y-los-qualifiers-propios) |
| `@Fallback` | el inverso de `@Primary`: candidato **de reserva**, solo si no hay otro · clase o método `@Bean` | llegó en Spring Framework 6.2: todo el material anterior a 2024 resuelve lo mismo con `@Primary` al revés o con `@ConditionalOnMissingBean` | [`03` §4](03-inyeccion-de-dependencias.md#4--primary-qualifier-y-los-qualifiers-propios) |
| `@Value` | inyecta un valor del `Environment` o una expresión SpEL · parámetro o campo | **no tiene relaxed binding**: `${inv.supplier.readTimeout}` no encuentra la clave escrita con guion | [`07` §5](07-configuracion-externalizada.md#5--relaxed-binding) |
| `@Resource` | inyección estándar de Jakarta · campo o setter | resuelve **primero por nombre** y después por tipo, justo al revés que `@Autowired`: verla en código heredado y suponerlo igual es un bug silencioso | [`03` §8](03-inyeccion-de-dependencias.md#8-️-errores-frecuentes) |

La sobregeneralización de esta familia es una sola y se dice mal casi siempre:

> Nunca respondas: ~~"`@Autowired` inyecta por nombre"~~
>
> Mejor: "resuelve **por tipo**; el nombre del campo o del parámetro es solo el último
> desempate cuando quedan varios candidatos del mismo tipo, después de `@Qualifier` y de
> `@Primary`."

Eso tiene una consecuencia práctica que muerde: con un único candidato, renombrar el
parámetro del constructor no cambia nada; con dos, **cambia qué bean se inyecta sin tocar
ninguna anotación**. El algoritmo completo, en sus seis pasos, está en
[`03` §3](03-inyeccion-de-dependencias.md#3--cómo-elige-el-contenedor-entre-candidatos).

Y una ausencia deliberada: **el curso inyecta por constructor y sin `@Autowired`**, y la
inyección por campo solo aparece marcada como antipatrón. No es estética: es lo que permite
campos `final` y lo que hace que un test unitario se escriba con `new` y sin contenedor
([`03` §1](03-inyeccion-de-dependencias.md#1--las-tres-formas-y-por-qué-solo-una-sobrevive-a-una-revisión)).

---

## 6. 🧱 Condicionales y autoconfiguración

Toda la autoconfiguración de Boot es `@Conditional` bien usado sobre bean definitions. Estas
son las condiciones que verás al abrir el código fuente de cualquier `*AutoConfiguration`.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Conditional` | evalúa una clase `Condition` y decide si la definición se registra · clase o método `@Bean` | se evalúa **una vez, en el registro**: un bean que no se registró no aparece luego porque cambie una propiedad en caliente | [`02` §8](02-contenedor-ioc-y-ciclo-de-vida.md#8--registro-condicional-profile-y-conditional) |
| `@Profile` | registra el bean solo con ese profile activo · clase o método `@Bean` | `@Profile("!prod")` sobre algo que relaja la seguridad es una bomba: se activa en cuanto alguien arranca sin el profile correcto | [`07` §7](07-configuracion-externalizada.md#7--profiles) |
| `@ConditionalOnClass` | la clase está en el classpath · clase o método `@Bean` | mide el classpath, no tu intención: dos starters web a la vez cambian el tipo de contexto que se crea | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |
| `@ConditionalOnMissingClass` | la clase **no** está · clase o método `@Bean` | se usa para alternativas excluyentes; en tu código propio casi nunca hace falta | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |
| `@ConditionalOnBean` | ya existe un bean de ese tipo · método `@Bean` | **es frágil en tu propio código**: depende del orden de registro, que tú no controlas | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |
| `@ConditionalOnMissingBean` | **no** existe un bean de ese tipo · método `@Bean` | es la pieza que hace que "tu bean siempre gane"; por eso excluir una autoconfiguración casi nunca es la respuesta correcta | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |
| `@ConditionalOnProperty` | una propiedad tiene cierto valor · clase o método `@Bean` | `matchIfMissing = true` decide si la funcionalidad está activa por defecto, y esa elección es de diseño | [`06` §8](06-arranque-y-autoconfiguracion.md#8--escribir-tu-propia-autoconfiguración) |
| `@ConditionalOnWebApplication` | el contexto es web, servlet o reactivo · clase | condiciona beans de web en librerías que también se usan en aplicaciones de consola | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |
| `@ConditionalOnResource` | existe un fichero en el classpath · clase | configuración por convención; la menos usada de la familia | [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones) |

> **🧠 Modelo mental, y es la respuesta a media docena de preguntas de entrevista: tu bean
> siempre gana.** Las autoconfiguraciones se procesan **después** de tus `@Configuration`,
> así que en cuanto existe un bean tuyo del mismo tipo la condición
> `@ConditionalOnMissingBean` falla y la de Boot no se registra. No hay que excluir nada.

Y cuando quieras saber por qué existe —o por qué **no** existe— un bean concreto, no lo
supongas: arranca con `--debug` y lee el bloque `Negative matches`, que dice qué condición
falló ([`06` §6](06-arranque-y-autoconfiguracion.md#6--el-informe-de-condiciones-por-qué-existe-ese-bean)).
Se practica en vivo en [`L01` §10](l01-esqueleto-cli-y-autoconfiguracion.md#10--tu-bean-gana-conditionalonmissingbean-en-vivo).

---

## 7. 🧱 Configuración externalizada

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@ConfigurationProperties` | enlaza un grupo de propiedades a un objeto tipado · `record` o clase | **sin `@Validated` no valida nada**: arrancas con un timeout de cero y te enteras en producción | [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties) |
| `@EnableConfigurationProperties` | registra esa clase como bean · `@Configuration` | si no la registras por aquí ni con `@ConfigurationPropertiesScan`, el bean no existe | [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties) |
| `@ConfigurationPropertiesScan` | escanea las clases de propiedades del subárbol · clase de arranque | es la alternativa a enumerarlas una por una; escanea desde el paquete base, como el component scan | [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties) |
| `@Validated` sobre propiedades | activa Bean Validation sobre el objeto de configuración · clase de propiedades | **el arranque falla** si algo no cuadra, y eso es lo que quieres: mejor no arrancar que arrancar mal | [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties) |
| `@PropertySource` | añade una fuente de propiedades a una `@Configuration` · clase | está casi al final del orden de precedencia: cualquier variable de entorno la pisa | [`07` §3](07-configuracion-externalizada.md#3--el-orden-de-precedencia) |

El veredicto entre las dos formas de leer configuración está escrito y no se reabre: `@Value`
para un valor aislado y para cuando necesitas SpEL, `@ConfigurationProperties` para todo lo
demás. **Tres `@Value` en la misma clase ya son señal de que había un grupo**, y lo que ganas
al agruparlo es tipado, validación, relaxed binding y metadatos para el autocompletado del
IDE. La comparación completa, con la tabla de las cinco diferencias, está en
[`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties), y el
arranque que se rompe a propósito se reproduce en
[`L02` §6](l02-configuracion-y-profiles.md#6--configurationproperties-con-record-y-el-arranque-que-se-rompe).

---

## 8. 🧱 AOP: el vocabulario que sostiene lo demás

Esta familia casi no se escribe en un proyecto Boot —los aspectos los pone el framework—,
pero es la que hay que saber nombrar para explicar todas las demás.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Aspect` | agrupa comportamiento transversal · clase | **no crea el bean**: hace falta `@Component` o un `@Bean` además, y un aspecto sin registrar no da ninguna señal | [`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla) |
| `@Around` | envuelve la ejecución y decide si ocurre · método del aspecto | si olvidas `pjp.proceed()`, el método **nunca se ejecuta** y devuelve `null` sin error | [`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla) |
| `@Before` · `@After` | antes de la ejecución · después, pase lo que pase · método del aspecto | `@After` sale siempre, como un `finally`; no confundirlo con `@AfterReturning` | [`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla) |
| `@AfterReturning` · `@AfterThrowing` | solo si retornó · solo si lanzó · método del aspecto | el par que la gente cree que cubre todos los casos: no cubre el `finally` | [`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla) |
| `@EnableAspectJAutoProxy` | activa el soporte de `@AspectJ` · `@Configuration` | **en Boot no se escribe**: la autoconfiguración lo activa con `spring-boot-starter-aop` en el classpath | [`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla) |

En Spring el único join point es **la ejecución de un método de un bean**: no hay
interceptación de campos, ni de constructores, ni de llamadas internas. Esa limitación no es
un detalle de implementación, es la causa de §3 entera
([`05` §4](05-proxies-y-aop.md#4--el-vocabulario-de-aop-en-una-pantalla)).

Y cuando varias anotaciones declarativas conviven sobre el mismo método, **el orden en que se
apilan cambia el resultado**, no solo el rendimiento. `@Transactional`, `@Cacheable` y
`@Async` se registran con la misma precedencia a propósito, y un empate deja el resultado sin
definir: si te importa, se declara
([`05` §7](05-proxies-y-aop.md#7--cuando-hay-varios-proxies-sobre-el-mismo-método)).

> **⏱️ Lo que cuesta el orden equivocado, con su unidad.** Un retry por fuera de una
> transacción reintenta la transacción entera; un retry por **dentro** mantiene la conexión
> de base de datos retenida durante todos los backoffs. Con tres intentos, un segundo de
> espera entre ellos y veinte peticiones concurrentes son veinte conexiones tomadas durante
> dos segundos — y un Hikari por defecto tiene **diez**. El pool se agota antes de que el
> proveedor se recupere.

---

## 9. 🧱 Web y REST

### El controller

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@RestController` | `@Controller` + `@ResponseBody` · clase | no es "el que devuelve JSON": cambia el return value handler, y que salga JSON depende de los converters y del `Accept` | [`09` §3](09-rest-con-spring-mvc.md#3--controller-vs-restcontroller) |
| `@ResponseBody` | el retorno va a los `HttpMessageConverter` · clase o método | sin él, un `String` devuelto es el nombre de una vista | [`09` §3](09-rest-con-spring-mvc.md#3--controller-vs-restcontroller) |
| `@RequestMapping` | mapea una condición compuesta: path, método, `consumes`, `produces`, `params`, `headers` · clase o método | el de la clase es un **prefijo que se concatena**: `/api` arriba y `/api/items` abajo dan `/api/api/items` | [`09` §4](09-rest-con-spring-mvc.md#4--mapeos-qué-compara-de-verdad-el-handlermapping) |
| `@GetMapping` · `@PostMapping` · `@PutMapping` | atajos con el `method` fijado · método | no aportan nada más que eso; `consumes` mal escrito da **415** y `produces` mal escrito, **406** | [`09` §4](09-rest-con-spring-mvc.md#4--mapeos-qué-compara-de-verdad-el-handlermapping) |
| `@PathVariable` | extrae del patrón de la URL · parámetro | toma el nombre del parámetro Java: sin compilar con `-parameters` el arranque falla con `Name for argument of type [...] not specified` | [`09` §5](09-rest-con-spring-mvc.md#5--los-argumentos-del-método) |
| `@RequestParam` | lee query string o formulario · parámetro | es **obligatorio** salvo `defaultValue` o `required = false`; con `required = false` sobre un primitivo obtienes un `NullPointerException` en el binding | [`09` §5](09-rest-con-spring-mvc.md#5--los-argumentos-del-método) |
| `@RequestBody` | dispara un converter de lectura sobre el cuerpo · parámetro | **solo puede haber uno por método**: el cuerpo es un `InputStream` de un solo uso | [`09` §5](09-rest-con-spring-mvc.md#5--los-argumentos-del-método) |
| `@RequestHeader` | lee una cabecera · parámetro | sin `defaultValue` es obligatoria, y eso es justo lo que hace exigible una `Idempotency-Key` | [`10` §7](10-diseno-de-api-validacion-errores-e-hipermedia.md#7--idempotencia-el-mismo-post-dos-veces) |
| `@ModelAttribute` | bindea por propiedades · parámetro | **es el default cuando ningún resolver reconoce el tipo**: de ahí los objetos que llegan con todo a `null` en vez de fallar | [`09` §5](09-rest-con-spring-mvc.md#5--los-argumentos-del-método) |
| `@ResponseStatus` | fija el código de estado · método o clase de excepción | limpio con un solo desenlace, estorbo con dos: con dos salidas se devuelve `ResponseEntity` | [`09` §6](09-rest-con-spring-mvc.md#6--responseentity-el-objeto-pelado-y-responsestatus) |
| `@ControllerAdvice` · `@RestControllerAdvice` | manejo centralizado de excepciones · clase | **no ve lo que ocurre en un filtro**: los 401 y 403 de Security nacen fuera del `DispatcherServlet` y salen sin tu formato | [`10` §4](10-diseno-de-api-validacion-errores-e-hipermedia.md#4--manejo-centralizado-y-lo-que-se-le-escapa) |
| `@ExceptionHandler` | traduce una excepción concreta · método | si escribes uno para una excepción que `ResponseEntityExceptionHandler` ya maneja, el tuyo gana y el de la base queda muerto | [`10` §4](10-diseno-de-api-validacion-errores-e-hipermedia.md#4--manejo-centralizado-y-lo-que-se-le-escapa) |
| `@EnableWebMvc` | configuración manual de MVC · `@Configuration` | **apaga `WebMvcAutoConfiguration` entera**: pierdes converters, recursos estáticos y los defaults de Jackson. En Boot se implementa `WebMvcConfigurer` | [`09` §9](09-rest-con-spring-mvc.md#9--webmvcconfigurer-el-punto-de-extensión-de-mvc) |
| `@PageableDefault` | tamaño y orden por defecto de un `Pageable` · parámetro | el **techo** no lo pone ella: sin `spring.data.web.pageable.max-page-size`, un `?size=1000000` trae el millón de filas | [`10` §9](10-diseno-de-api-validacion-errores-e-hipermedia.md#9--paginación-page-slice-y-cursor) |
| `@JsonProperty` | nombre JSON distinto del componente Java · componente del `record` | con un `record` y el constructor canónico **no hace falta** salvo que los nombres difieran | [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson) |

### El cliente declarativo

Las de abajo declaran lo que **consumes**, no lo que expones, y esa es exactamente la
confusión que producen: los parámetros reutilizan las anotaciones del lado servidor, así que
**el import es lo único que distingue una interfaz de cliente de un controller**.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@HttpExchange` · `@GetExchange` | declara una llamada saliente; Spring genera el proxy · interfaz y sus métodos | lo declarativo no configura nada: **los timeouts y el pool siguen siendo los del `RestClient`** que le pasaste | [`13` §7](13-clientes-http.md#7--http-interfaces-declarativo-y-de-spring) |
| `@FeignClient` | cliente declarativo de Spring Cloud OpenFeign · interfaz | su `configuration` **no se anota con `@Configuration`**: si la anotas, sus beans se aplican a todos los clientes a la vez | [`13` §8](13-clientes-http.md#8--feign-que-es-lo-que-vas-a-encontrar) |
| `@EnableFeignClients` | dispara el escaneo de esas interfaces · clase de arranque | sin ella las interfaces no son beans y el arranque falla por candidato ausente | [`13` §8](13-clientes-http.md#8--feign-que-es-lo-que-vas-a-encontrar) |

### Tiempo real

Las de abajo viven fuera del ciclo petición-respuesta: un `SseEmitter` no lleva anotación propia
—es un tipo de retorno de `@GetMapping`—, y lo que sí se anota es el lado STOMP de WebSocket, donde
**ningún filtro, `@ControllerAdvice` ni `ProblemDetail` ve los mensajes** después del `101`.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@EnableWebSocket` | registra los `WebSocketHandler` de un `WebSocketConfigurer` · `@Configuration` | sin `setAllowedOrigins` solo acepta el mismo origen, y el `403` del handshake llega al navegador como "no conecta" | [`14` §4](14-tiempo-real-sse-y-websocket.md#4--websocket-crudo-websockethandler-y-la-sesión) |
| `@EnableWebSocketMessageBroker` | levanta STOMP: endpoints, prefijos y los tres canales · `@Configuration` | el broker simple es **en memoria y por instancia**: con dos réplicas, la mitad de los suscritos no recibe nada | [`14` §5](14-tiempo-real-sse-y-websocket.md#5--stomp-destinos-messagemapping-y-el-broker) |
| `@MessageMapping` | atiende un `SEND` a `/app/<destino>` · método de un `@Controller` | corre en `clientInboundChannel-N`, no en Tomcat: el `SecurityContextHolder` está vacío y la cola por defecto no tiene techo | [`14` §5](14-tiempo-real-sse-y-websocket.md#5--stomp-destinos-messagemapping-y-el-broker) |
| `@SendTo` · `@SendToUser` | publica el retorno en un destino del broker, o en el del usuario del handshake · método | `@SendToUser` depende de que el handshake haya dejado un `Principal` con nombre; sin él no hay `/user/{user}/…` que resolver | [`14` §5](14-tiempo-real-sse-y-websocket.md#5--stomp-destinos-messagemapping-y-el-broker) |
| `@MessageExceptionHandler` | traduce una excepción de un `@MessageMapping` a un frame `ERROR` · método | es el único punto de manejo: `@RestControllerAdvice` no existe para un frame | [`14` §5](14-tiempo-real-sse-y-websocket.md#5--stomp-destinos-messagemapping-y-el-broker) |
| `@EnableWebSocketSecurity` | autorización por destino con un bean `AuthorizationManager<Message<?>>` · `@Configuration` | exige token CSRF en **todo `CONNECT`**, y lo que no casa con ninguna regla **pasa**: se cierra con `anyMessage().denyAll()` | [`14` §7](14-tiempo-real-sse-y-websocket.md#7--seguridad-el-principal-se-decide-en-el-handshake) |

Dos cosas que conviene decir en voz alta y no caben en la tabla. **Feign no es de Spring**:
es de Netflix, y lo de Spring es Spring Cloud OpenFeign, en modo mantenimiento desde 2022; si
empiezas hoy, `@HttpExchange` hace lo mismo sin release train y con los timeouts de Boot
([`13` §8](13-clientes-http.md#8--feign-que-es-lo-que-vas-a-encontrar)). Y **ninguna de las
dos te protege de nada**: el timeout de lectura vive en la `ClientHttpRequestFactory`, no en
la anotación, y sin él el default es esperar para siempre
([`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool)).

---

## 10. 🧱 Validación

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Valid` | valida el objeto al resolver el argumento · parámetro o campo | **es de `jakarta.validation`**, no se puede poner en una clase y no acepta grupos; sobre un campo activa la validación anidada | [`10` §2](10-diseno-de-api-validacion-errores-e-hipermedia.md#2--validar-el-body-valid) |
| `@Validated` | activa la validación de parámetros vía proxy · clase | **en un controller convierte el 400 en un 500** desde Spring Framework 6.1: lanza `ConstraintViolationException`, que MVC no conoce. Su sitio son los `@Service` | [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso) |
| `@NotNull` · `@NotEmpty` · `@NotBlank` | rechaza `null` · también la cadena vacía · también la que solo tiene espacios · componente o campo | con `int` en vez de `Integer`, el campo ausente llega como `0` y el `@NotNull` nunca dispara | [`10` §2](10-diseno-de-api-validacion-errores-e-hipermedia.md#2--validar-el-body-valid) |
| `@Size` · `@Min` · `@Max` · `@PositiveOrZero` | restricciones de rango y longitud · componente, campo o parámetro | en un parámetro de controller las aplica MVC y salen 400; **con `@Validated` en la clase, 500** | [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso) |
| `@Null` con `groups` | prohíbe un valor en un grupo concreto · componente o campo | una restricción **sin** `groups` pertenece a `Default` y **no se evalúa** cuando pides un grupo concreto | [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso) |

Dos trampas de esta familia no son de ninguna anotación en particular y valen por todas. La
primera: **sin `spring-boot-starter-validation` en el `pom.xml` no hay error de arranque, las
anotaciones se ignoran en silencio**. La segunda es la tabla de qué excepción produce cada
fallo y con qué status sale —`MethodArgumentNotValidException` y
`HandlerMethodValidationException` en 400, `ConstraintViolationException` en 500—, que es lo
que convierte un "puse `@Max` y responde 500" en un diagnóstico de diez segundos
([`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso)).
Y las mismas restricciones sirven para validar la configuración al arrancar (§7).

---

## 11. 🧱 Datos y transacciones

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Transactional` | pide al proxy que abra y cierre la transacción · método o clase | **por defecto solo hace rollback ante `RuntimeException` y `Error`**: una excepción comprobada confirma. Y capturarla dentro cancela el rollback | [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal) |
| `@Transactional(propagation = …)` | decide qué pasa si ya hay una transacción · atributo | `REQUIRES_NEW` **no libera** la conexión de la externa: consumes dos del pool a la vez, y con 10 conexiones eso es un deadlock esperando | [`16` §4](16-transacciones.md#4--propagación) |
| `@Transactional(isolation = …)` | comunica el nivel de aislamiento a la base · atributo | `Isolation.DEFAULT` significa "el del motor": el mismo código se comporta distinto en Postgres y en MySQL | [`16` §5](16-transacciones.md#5--aislamiento) |
| `@Transactional(readOnly = true)` | evita el dirty checking de Hibernate · atributo | **no impide escribir**: es una pista de optimización, no un permiso | [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal) |
| `@Transactional(timeout = …)` | segundos que administra el `TransactionManager` · atributo | se aplica **por sentencia** y pide una cancelación: no sustituye al `socketTimeout` del driver ni al `statement_timeout` del motor | [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal) |
| `@Query` | JPQL o SQL nativo en un repositorio · método de la interfaz | el JPQL se valida en el arranque; con `nativeQuery = true` pierdes esa validación y las entidades | [`15` §4](15-datos-jdbc-jpa-mongo-y-redis.md#4--spring-data-el-repositorio-que-nadie-implementa) |
| `@Param` | nombra el parámetro de un `@Query` · parámetro | sin él, el nombre del parámetro Java tiene que sobrevivir a la compilación | [`15` §4](15-datos-jdbc-jpa-mongo-y-redis.md#4--spring-data-el-repositorio-que-nadie-implementa) |
| `@Modifying` | marca un `UPDATE`/`DELETE` de JPQL · método de la interfaz | es **obligatoria**, y sin `clearAutomatically = true` las entidades ya cargadas se quedan con el valor viejo | [`15` §4](15-datos-jdbc-jpa-mongo-y-redis.md#4--spring-data-el-repositorio-que-nadie-implementa) |
| `@EntityGraph` | declara qué asociaciones traer en la misma consulta · método derivado | `attributePaths` nombra **propiedades**, no columnas; es la primera corrección del N+1 | [`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas) |
| `@BatchSize` | agrupa los `SELECT` de una colección · entidad o asociación | **no elimina** los N `SELECT`: los agrupa en `N/20` con un `IN (...)` | [`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas) |
| `@ManyToOne` | asociación a uno · campo de la entidad | su `fetch` por defecto es **`EAGER` por especificación**; ponerlo `LAZY` es casi siempre lo correcto | [`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas) |
| `@Version` | bloqueo optimista · campo de la entidad | añade `WHERE version = ?` a cada `UPDATE`: si otro lo cambió, afecta cero filas y salta `OptimisticLockingFailureException`, que tu API traduce a 409 | [`15` §5](15-datos-jdbc-jpa-mongo-y-redis.md#5--el-persistence-context-de-donde-salen-las-sorpresas) |
| `@Document` | marca la clase como documento de Mongo · clase | **Boot no crea los índices por ti** desde Spring Data MongoDB 3.0: un `findBySku` sin índice es un scan completo | [`15` §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa) |

Los **seis silencios** de `@Transactional` merecen leerse enteros porque cinco de ellos son
el §3 de este apéndice con otro nombre —misma clase, `private`, `final`, `@PostConstruct`,
excepción capturada— y el sexto es de otra familia: **importar `jakarta.transaction` en vez
del `@Transactional` de Spring**. Ese sí abre la transacción, pero pierde `readOnly`,
`isolation` y `timeout`, y te enteras el día que vas a añadir uno de esos atributos y el
compilador lo rechaza ([`16` §7](16-transacciones.md#7--los-seis-silencios)).

Para diagnosticar cualquiera de los seis hay un solo comando, y no hace falta debugger: sube
`org.springframework.transaction.interceptor` a `TRACE` y mira si aparece la línea
`Getting transaction for [...]` antes de tu método. Si no aparece, no hubo transacción.

---

## 12. 🧱 Caché

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@EnableCaching` | registra el `CacheInterceptor` · `@Configuration` | **no crea ninguna caché**; sin ella las tres de abajo son comentarios de lujo y el método corre siempre, sin error ni log | [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato) |
| `@Cacheable` | si hay entrada, **no ejecuta el método** · método | guarda también el `null` salvo que lo vetes, y en self-invocation no acierta jamás sin dar ninguna señal | [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato) |
| `@CachePut` | **siempre ejecuta** y después escribe · método | junto a `@Cacheable` en el mismo método pide dos cosas incompatibles y **Spring no lo rechaza**: arranca y el resultado queda indefinido | [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato) |
| `@CacheEvict` | borra una entrada, o todas con `allEntries` · método | por defecto borra **después** de ejecutar: si el método lanza, la entrada vieja sobrevive. `beforeInvocation = true` lo arregla | [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato) |
| `@Caching` | agrupa varias de las anteriores · método | no tiene semántica propia: es solo un contenedor | [`17` §2](17-cache.md#2--la-abstracción-de-spring-anotaciones-sobre-un-contrato) |

Los atributos de `@Cacheable` son la mitad del trabajo y se confunden entre sí: **`condition`
se evalúa antes** de ejecutar y decide si participas, **`unless` se evalúa después** y decide
si guardas —es el único que puede mirar `#result`—, y **`key`** es SpEL sobre los argumentos.
Sin `key`, el `SimpleKeyGenerator` usa el argumento tal cual, así que un objeto sin
`equals`/`hashCode` genera una clave distinta en cada llamada y no aciertas nunca
([`17` §3](17-cache.md#3--la-clave-key-condition-unless-y-el-keygenerator)).

Y la trampa que no está en ninguna anotación: **el interceptor escribe cuando el método
retorna, no cuando la transacción hace commit**. Un `@CachePut` dentro de un `@Transactional`
puede dejar cacheado un dato que nunca existió; el punto correcto es después del commit
([`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea)).

> **🩺 "Mi `@Cacheable` no cachea", en orden.** ¿Está `@EnableCaching`? ¿La llamada viene de
> otro bean? ¿`condition` o `unless` la vetan? ¿La clave es estable? ¿La métrica
> `cache.gets` registra siquiera un `miss`? **Si no hay ni `miss`, el problema es el proxy,
> no la caché** ([`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)).

---

## 13. 🧱 Asincronía, scheduling y eventos

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@EnableAsync` | registra el interceptor de `@Async` · `@Configuration` | **Boot no lo activa por ti**: la autoconfiguración crea el executor, no el `@EnableAsync`. Sin él, el método corre en el hilo del llamante y no avisa | [`18` §2](18-asincronia-scheduling-y-eventos.md#2--async-quién-lo-ejecuta-y-qué-devuelve) |
| `@Async` | delega la ejecución a un executor · método | con retorno `void` **la excepción se la traga** todo el mundo menos el `AsyncUncaughtExceptionHandler`; y el `SecurityContext` y el `traceId` no cruzan al hilo nuevo | [`18` §3](18-asincronia-scheduling-y-eventos.md#3-️-las-dos-formas-de-que-async-no-haga-nada) |
| `@Async("nombre")` | elige el executor por nombre de bean · atributo | con dos `TaskExecutor` sin cualificar **no falla el arranque**: cae a un `SimpleAsyncTaskExecutor` sin pool, con un hilo por tarea, y lo dice en un log de nivel `INFO` | [`18` §2](18-asincronia-scheduling-y-eventos.md#2--async-quién-lo-ejecuta-y-qué-devuelve) |
| `@EnableScheduling` | registra el scheduler · `@Configuration` | mismo silencio que `@EnableAsync` si falta, y el método `@Scheduled` tiene que ser sin argumentos | [`18` §6](18-asincronia-scheduling-y-eventos.md#6--scheduled-el-reloj-y-el-pool-de-un-solo-hilo) |
| `@Scheduled(fixedDelay / fixedRate)` | dispara por reloj · método | `fixedRate` cuenta de inicio a inicio y **acumula retraso**; `fixedDelay` cuenta desde que termina y se autorregula | [`18` §6](18-asincronia-scheduling-y-eventos.md#6--scheduled-el-reloj-y-el-pool-de-un-solo-hilo) |
| `@Scheduled(cron = …, zone = …)` | expresión de seis campos · método | **el primer campo son segundos**: un cron de Unix de cinco campos revienta el arranque, y sin `zone` manda la zona de la JVM | [`18` §6](18-asincronia-scheduling-y-eventos.md#6--scheduled-el-reloj-y-el-pool-de-un-solo-hilo) |
| `@EventListener` | reacciona a un evento publicado · método | **es síncrono**: corre en el hilo del publicador, dentro de su transacción, y su excepción sube y provoca el rollback | [`18` §8](18-asincronia-scheduling-y-eventos.md#8--eventos-de-aplicación-síncronos-por-defecto) |
| `@TransactionalEventListener` | ejecuta el listener atado a una fase de la transacción · método | **sin transacción activa no se ejecuta en absoluto**, ni excepción ni warning: el test "pasa" sin haber probado nada. `fallbackExecution = true` lo salva | [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) |

Tres precisiones que se preguntan tal cual.

- **`@Async` no crea concurrencia, delega la ejecución.** Si el executor tiene un hilo, o si
  la llamada es interna y no pasa por el proxy, no hay nada paralelo. Y el executor por
  defecto **llena la cola antes de crecer hasta `max-size`**, así que con la cola ilimitada
  del default `max-size` nunca se alcanza: tu pool de "dos mil millones de hilos" son ocho
  hilos y una cola que crece hasta el heap
  ([`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera)).
- **`@Scheduled` es local al proceso.** Tres réplicas son tres relojes y tres ejecuciones; si
  el job no es idempotente, eso es tres veces el daño. Las salidas —idempotencia, lock
  distribuido con ShedLock, scheduler externo— están en
  [`18` §7](18-asincronia-scheduling-y-eventos.md#7-️-tres-réplicas-tres-ejecuciones) y se
  reproducen en [`L06` §9](l06-cache-y-asincronia.md#9-️-scheduled-por-duplicado-el-rlock-y-shedlock).
- **`AFTER_COMMIT` más `@Async` es la combinación que casi siempre quieres**, porque el
  commit ya ocurrió, el hilo del request queda libre y el efecto externo no retiene la
  conexión. Lo que ese mecanismo **no** te da es atomicidad entre el commit y el listener:
  si el proceso muere ahí, el evento se perdió, y la respuesta a eso es el outbox
  ([`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)).

---

## 14. 🧱 Resiliencia

Las cuatro primeras son de **Resilience4j**, no de Spring, y funcionan con el mismo mecanismo
de proxies que todo lo demás: requieren `spring-boot-starter-aop` y sufren la
self-invocation igual que el resto.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Retry(name = …)` | reintenta según la instancia del YAML · método | `max-attempts: 3` cuenta **el intento original**; y **no acepta `fallbackMethod`** como sus hermanas | [`L05` §4](l05-clientes-y-resiliencia.md#4-️-retry-con-backoff-y-el-ariete-sincronizado) |
| `@CircuitBreaker(name = …, fallbackMethod = …)` | abre el circuito y falla rápido sin tocar la red · método | si la firma del fallback no casa, **no falla nada**: un `WARN` en la primera llamada y sigue como si no lo hubieras configurado | [`19` §8](19-resiliencia.md#8--el-fallback-honesto) |
| `@Bulkhead(name = …)` | limita las llamadas concurrentes a una dependencia · método | sin `type` usa `Type.SEMAPHORE`; el de thread pool aísla la ejecución a costa de perder el contexto del hilo | [`L05` §7](l05-clientes-y-resiliencia.md#7--bulkhead-saturado-y-el-fallback-honesto) |
| `@TimeLimiter(name = …)` | pone techo al tiempo de una llamada asíncrona · método | en una llamada bloqueante el techo lo pone el `read-timeout` del cliente, no esta anotación | [`19` §6](19-resiliencia.md#6--bulkhead-y-rate-limiter) |
| `@Retryable` | el reintento de **Spring Retry** · método | el proyecto está **archivado en `spring-attic`**: es código heredado y no una opción defendible para algo nuevo | [`19` §4](19-resiliencia.md#4--con-qué-librería-resilience4j-y-qué-pasó-con-spring-retry) |

El orden de las líneas en el código fuente **no decide nada**: el apilado por defecto de
Resilience4j es `Retry( CircuitBreaker( RateLimiter( TimeLimiter( Bulkhead( llamada )))))`, y
se cambia con las propiedades `*-aspect-order` del YAML — salvo la del bulkhead, que en 2.2.0
es fija. Invertir retry y circuit breaker es el error caro: el breaker deja de ver cada
intento, tarda más peticiones en abrir y el proveedor recibe el triple de tráfico
([`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan), con la aritmética medida y
reproducida en [`L05` §6](l05-clientes-y-resiliencia.md#6--el-orden-de-los-decoradores-invertido-a-propósito)).

Y la regla que atraviesa esta familia entera: **sin timeout, ninguna de las cinco sirve**. Un
retry no dispara si la llamada no termina, un circuit breaker no cuenta un fallo que no
ocurrió y un bulkhead se llena de hilos que no vuelven
([`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)).

---

## 15. 🧱 Seguridad

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@EnableWebSecurity` | activa la infraestructura de Security · `@Configuration` | con el starter en el classpath Boot ya la activa; lo que apaga su autoconfiguración es **declarar un `SecurityFilterChain`** | [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean) |
| `@Order` sobre un `SecurityFilterChain` | decide qué cadena se evalúa primero · método `@Bean` | `FilterChainProxy` elige **la primera que matchea** y las demás no se evalúan: una cadena sin `securityMatcher` declarada primero deja muertas al resto | [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean) |
| `@EnableMethodSecurity` | activa los proxies de autorización por método · `@Configuration` | **el starter no la activa sola**; sustituye a `@EnableGlobalMethodSecurity`, retirada en Security 6 | [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero) |
| `@PreAuthorize` | evalúa una expresión SpEL **antes** del método, con acceso a los argumentos · método | es un proxy: en self-invocation **no se evalúa**, y aquí el fallo silencioso no es una transacción perdida sino una comprobación que no ocurrió | [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero) |
| `@PostAuthorize` | evalúa **después**, sobre `returnObject` · método | el método **ya corrió**: es peligrosa si escribió algo | [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero) |
| `@PreFilter` · `@PostFilter` | filtran colecciones · método | filtran **en memoria**: con una colección grande, el filtro va en la consulta | [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero) |
| `@AuthenticationPrincipal` | inyecta el principal en el handler · parámetro de controller | es la forma testeable de leer la identidad, en vez de atar el servicio al `ThreadLocal` del `SecurityContextHolder` | [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) |
| `@WithMockUser` | inyecta un `Authentication` ya construido en un test · método o clase de test | **`roles` prefija `ROLE_` y `authorities` no**, y si declaras `authorities` se ignora `roles`: de ahí el test verde con producción en 403 | [`20` §12](20-spring-security-el-mecanismo.md#12--probarlo-sin-levantar-un-proveedor-de-identidad) |
| `@AutoConfigureMockMvc` | registra la cadena de filtros en `MockMvc` · clase de test | **sin ella `MockMvc` no ejecuta Security**: los tests pasan porque las reglas nunca corrieron | [`20` §12](20-spring-security-el-mecanismo.md#12--probarlo-sin-levantar-un-proveedor-de-identidad) |

La pregunta número uno de esta familia no es sobre una anotación sino sobre su expresión:
**`hasRole("ANALYST")` y `hasAuthority("ANALYST")` no son lo mismo**. La primera es un atajo
que añade el prefijo `ROLE_` y compara contra `ROLE_ANALYST`; la segunda compara el literal.
Si tu base guarda `ANALYST` a secas y la regla dice `hasRole`, obtienes **un 403 perfecto y
silencioso**
([`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_)), y el
converter que mapea los claims del token a authorities es donde eso se decide de verdad
cuando la identidad la emite un IdP
([`21` §7](21-identidad-federada-oauth2-oidc-y-jwt.md#7--de-claims-a-authorities-el-converter-que-casi-todos-terminan-escribiendo)).

Dos ausencias que también son contenido. **Actuator no se asegura con anotaciones**: se
declara otra cadena con `EndpointRequest.toAnyEndpoint()`, que resuelve las rutas reales en
tiempo de ejecución respetando el `base-path` y el puerto de management
([`20` §10](20-spring-security-el-mecanismo.md#10--asegurar-actuator-sin-escribir-rutas-a-mano)).
Y **la configuración de Security no lleva anotaciones desde la versión 6**:
`WebSecurityConfigurerAdapter`, `antMatchers` y `authorizeRequests` se eliminaron, y hoy todo
es un `@Bean SecurityFilterChain` con `requestMatchers`. La cuarta aparición de la
self-invocation, ahora sobre `@PreAuthorize`, se reproduce en
[`L08` §6](l08-security-y-batch.md#6--method-security-y-la-self-invocation-por-cuarta-vez).

---

## 16. 🧱 Batch

Esta es la familia más corta del catálogo, y eso **es** la información: en Spring Batch 5 un
job se declara con builders —`new StepBuilder(nombre, jobRepository)`— y no con anotaciones,
así que aquí no hay tabla que rellenar sin inventar.

La única anotación de la familia es una que **no se escribe**:

> **⚠️ `@EnableBatchProcessing` no va en una aplicación Boot.** Esa anotación —o extender
> `DefaultBatchConfiguration`— **desactiva la autoconfiguración de Batch**, incluida la
> creación del esquema de metadatos. Es la trampa número uno al copiar ejemplos de la
> documentación de Spring Batch a secas, que sí la lleva porque no asume Boot
> ([`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco)).

Lo que sostiene un job son cosas que no son anotaciones y conviene no buscarlas aquí: el
`chunk(500, transactionManager)` que declara el commit interval y **quién abre la
transacción** ([`22` §3](22-spring-batch.md#3--el-chunk-leer-uno-procesar-uno-escribir-de-a-muchos)),
los `JobParameters` identificadores que son la clave primaria de la corrida, y las propiedades
`spring.batch.job.enabled` y `spring.batch.job.name` que deciden si el job arranca solo al
levantar el servicio ([`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)).

> **📝 Qué cambia en 4.x.** Spring Boot 4 trae Spring Batch 6, donde `@EnableBatchProcessing`
> se acompaña de `@EnableJdbcJobRepository` o `@EnableMongoJobRepository`. El modelo —job,
> step, chunk, `JobRepository`— sigue en pie; la migración completa es de
> [`A04` §8](a04-migracion-3-5-a-4-x.md#8--spring-batch-6-enablejdbcjobrepository-y-los-dos-absorbidos)
> ([`22` §11](22-spring-batch.md#11-️-errores-frecuentes)).

---

## 17. 🧱 Testing

La familia más numerosa, y la que más cambió de sitio entre versiones. Las de arriba eligen
**cuánto contexto levantas**; las de en medio, **qué bean sustituyes**; las de abajo, **qué
configuración aplica** — y esa última parte es la que decide si tu suite tarda uno o ocho
minutos.

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@SpringBootTest` | carga el contexto entero · clase de test | es el más caro y el único que contesta "¿arranca?"; sus cuatro `webEnvironment` no son intercambiables | [`24` §3](24-testing.md#3--springboottest-y-sus-cuatro-webenvironment) |
| `@LocalServerPort` | inyecta el puerto real · campo de test | solo tiene sentido con `RANDOM_PORT`, que es el único modo con socket | [`24` §3](24-testing.md#3--springboottest-y-sus-cuatro-webenvironment) |
| `@WebMvcTest` | slice web: `MockMvc`, controllers, advices, converters · clase de test | **no escanea servicios ni repositorios**: sin el `@MockitoBean` correspondiente el contexto no levanta | [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) |
| `@WebFluxTest` | lo mismo en el stack reactivo · clase de test | trae `WebTestClient` en vez de `MockMvc` | [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) |
| `@DataJpaTest` | slice de datos con `TestEntityManager` y repositorios · clase de test | **es transaccional y revierte**, y reemplaza tu `DataSource` por uno embebido: es la línea que te mete H2 sin pedirlo | [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) |
| `@JdbcTest` · `@DataMongoTest` · `@JsonTest` · `@RestClientTest` | slices de JDBC, Mongo, serialización y cliente HTTP · clase de test | `@DataMongoTest` **no es transaccional**: lo que escribes se queda. Y `@RestClientTest` no ejerce ni timeout ni pool, porque no hay socket | [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) |
| `@AutoConfigureTestDatabase` | decide si el `DataSource` se sustituye · clase de test | su `replace = NON_TEST` es el default dentro de `@DataJpaTest` | [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) |
| `@MockitoBean` | sustituye un bean del contexto por un mock · campo de test | al sustituir el bean **sustituyes su proxy**: el mock no tiene transacción, ni caché, ni reintento | [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto) |
| `@MockitoSpyBean` | envuelve el bean **real** y lo espía · campo de test | el trabajo de verdad ocurre; se resetea entre métodos, igual que el anterior | [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto) |
| `@TestBean` | sustituye un bean por uno que produce un método estático tuyo · campo de test | es el tercer mecanismo de bean override, y como los otros dos **cambia la clave de la caché de contextos** | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@MockBean` · `@SpyBean` | las antiguas, de Boot · campo de test | `@Deprecated(since = "3.4.0", forRemoval = true)` en el javadoc de 3.5.16, y **en 4.x ya no existen** | [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto) |
| `@Mock` · `@ExtendWith(MockitoExtension.class)` | mock y ciclo de vida de **Mockito**, sin contenedor · campo y clase de test | `@ExtendWith` aplica *strict stubs*: un `when(...)` que nadie usa falla con `UnnecessaryStubbingException` | [`24` §2](24-testing.md#2--el-test-unitario-sin-contenedor-y-por-qué-puedes-escribirlo) |
| `@TestConfiguration` | configuración que aplica solo a este test · clase anidada | **no es `@Configuration`**: una suelta la recoge el component scan y contamina **todos** los contextos | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@ActiveProfiles` | activa profiles en el test · clase de test | es la forma barata de configurar; cada combinación distinta es un contexto más en la caché | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@TestPropertySource` | sobrescribe claves sueltas con prioridad muy alta · clase de test | **un contexto nuevo por cada valor distinto**: es cómodo y se paga en arranques | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@DynamicPropertySource` | registra *suppliers* de propiedades · método `static` de test | es lo único que sirve para un puerto que no existe hasta que arranca el contenedor | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@DirtiesContext` | marca el contexto como corrupto y lo saca de la caché · clase o método | es el **último recurso**, no una limpieza preventiva: "por higiene" convierte la caché en decorado | [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) |
| `@Transactional` en un test | abre una transacción y hace **rollback** al terminar · clase o método de test | oculta todo lo que solo falla al confirmar, y con `RANDOM_PORT` no aplica: el servidor atiende en otro hilo | [`24` §8](24-testing.md#8-️-transactional-en-el-test-el-rollback-que-oculta-bugs) |
| `@Commit` · `@Rollback(false)` · `@Sql` | confirmar en vez de revertir · preparar o limpiar datos · clase o método | son la contrapartida de la fila anterior cuando lo que pruebas **es** el commit | [`24` §8](24-testing.md#8-️-transactional-en-el-test-el-rollback-que-oculta-bugs) |
| `@Testcontainers` · `@Container` | ciclo de vida de los contenedores del test · clase y campo | `@Container` sobre un campo **de instancia** arranca un contenedor por método: así se llega a una suite de veinte minutos | [`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2) |
| `@ServiceConnection` | deriva `spring.datasource.*` del contenedor · campo del contenedor | además **desactiva el reemplazo por H2**, y por eso `@DataJpaTest` con Testcontainers funciona sin anotaciones extra | [`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2) |

> **📝 `@MockBean` está deprecada y hay que saberlo con fecha y con proyecto.** El javadoc de
> Boot 3.5.16 la declara `@Deprecated(since = "3.4.0", forRemoval = true)`, igual que
> `@SpyBean`. Las sustitutas **no son de Boot**: viven en Spring Framework
> (`org.springframework.test.context.bean.override.mockito`) y su javadoc dice `Since: 6.2`,
> es decir, llegaron con Framework 6.2 y Boot 3.4. Decir "`@MockitoBean` es la nueva de Boot"
> es la media respuesta ([`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto)).

Lo que gobierna la duración de la suite no es el número de tests, sino **cuántos contextos
distintos levantas**, y la clave de esa caché la forman los bean overrides, los profiles, las
propiedades y el `@DynamicPropertySource`. Añadir un `@MockitoBean` en una clase y no en otra
ya son dos contextos y dos arranques
([`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos)).

---

## 18. 🧱 Actuator y métricas

| Anotación | Qué hace · dónde va | La trampa | Dónde se explica |
|---|---|---|---|
| `@Timed` | publica un `Timer` alrededor del método · método o clase | `management.observations.annotations.enabled` vale **`false` por defecto**: sin esa propiedad no se registra el aspecto y la anotación **se ignora en silencio** | [`23` §7](23-actuator-y-observabilidad.md#7--micrometer-meterregistry-los-cuatro-medidores-y-las-anotaciones) |
| `@Counted` | publica un `Counter` alrededor del método · método o clase | la misma propiedad, y además hace falta `spring-boot-starter-aop`: el aspecto se condiciona a `org.aspectj.weaver.Advice` | [`23` §7](23-actuator-y-observabilidad.md#7--micrometer-meterregistry-los-cuatro-medidores-y-las-anotaciones) |

Son dos entradas y las dos comparten la misma trampa doble —la propiedad apagada y el proxy—,
así que la lista de comprobación cuando "puse `@Timed` y no aparece la métrica" es corta:
¿está la propiedad?, ¿está AOP en el classpath?, ¿la llamada viene de otro bean? La tercera
es la self-invocation de siempre
([`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)).

Y la advertencia que acompaña a cualquier instrumentación a mano: **el identificador único
nunca es un tag**. Cada combinación de valores crea una serie de tiempo, así que etiquetar con
`sku` o `customerId` hace explotar la combinatoria y te quedas sin **todas** las métricas, no
solo sin la mal etiquetada
([`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)).
Casi todo lo que necesitas ya viene instrumentado —HTTP, JVM, Hikari, cachés, Resilience4j—:
a mano se instrumenta el dominio, no la plomería.

---

## 19. ⚠️ Alcance: lo que este catálogo no lista

Este apéndice **se compila a partir de lo que el curso explicó**, y esa regla tiene un precio
que se declara aquí en vez de disimularse rellenando huecos de memoria. Una ficha de
referencia con una anotación que nadie verificó vale menos que una ficha con un hueco
señalado.

- **La familia "web reactivo" no tiene anotaciones propias en este curso, y no es un olvido.**
  Un endpoint de WebFlux se declara con los **mismos** `@RestController` y `@GetMapping` de §9;
  lo que cambia es el tipo de retorno —`Mono` o `Flux`— y el `produces` cuando es un stream. El
  otro estilo, la `RouterFunction`, es un `@Bean` que declara las rutas **como datos** y por
  definición no lleva anotaciones
  ([`11` §6](11-webflux-y-reactor.md#6--el-stack-netty-webfilter-y-los-dos-estilos-de-endpoint)).
  Lo que sí desaparece en reactivo es el scope `request`, porque no hay hilo al que colgarlo
  ([`04` §6](04-scopes-de-bean.md#6--los-scopes-web-y-dónde-no-existen)).
- **El mapeo de JPA está fuera.** `@Entity`, `@Id`, `@Table`, `@Column` y `@GeneratedValue`
  aparecen en los ejemplos del curso pero **no se explican como mecanismo**, así que no tienen
  fila. Las que sí están en §11 son las que el curso usó para enseñar un problema concreto:
  `@Version` para el bloqueo optimista, `@EntityGraph` y `@BatchSize` para el N+1, `@ManyToOne`
  por su `fetch` por defecto.
- **El catálogo completo de Bean Validation está fuera.** §10 lista las restricciones que el
  curso usó en `inv-api`; Jakarta Validation define muchas más, y copiarlas aquí sería escribir
  un manual de referencia en vez de un inventario del curso.
- **Kafka, JMS, GraphQL y Spring Cloud no aparecen** porque el curso los excluyó a propósito y
  dice dónde se practican en su lugar
  ([`L00` §3](l00-idea-lab-practico.md#3--el-catálogo-de-exclusiones-una-por-una)). Lo único
  que entra de Spring Cloud es `@FeignClient`, y entra porque en banca hay que saber leerlo.
- **Dos documentos del curso no aportan filas, y aun así se enlazan desde aquí.** La simulación
  de entrevista ([`25`](25-simulacion-de-entrevista.md)) usa estas anotaciones pero no las
  cataloga: pregunta por ellas. Y el apéndice de migración
  ([`A04`](a04-migracion-3-5-a-4-x.md)) es donde vive, desarrollado, todo lo que aquí aparece
  resumido en un 📝: si una columna de "la trampa" cambia en la línea 4.x, la versión larga está
  ahí.

Lo que **sí** está completo es la regla de terminado de este apéndice: **ninguna entrada sin
enlace a su capítulo**. Si alguna vez añades una fila y no sabes a dónde apunta, la fila no va
aquí: va primero al capítulo que la explique.

---

## 🧠 Preguntas rápidas

1. Nombra tres anotaciones que sean de Spring Boot y tres que sean de Spring Framework, y di
   qué criterio las separa.
2. `@Component` y `@Bean` producen los dos una bean definition. ¿Qué te obliga a elegir una en
   vez de la otra, y de dónde sale el nombre del bean en cada caso?
3. ¿Cuál de los cuatro estereotipos añade comportamiento real y no solo semántica? ¿Qué
   comportamiento?
4. Un método lleva `@Transactional` y no se abre ninguna transacción, sin error ni log.
   Enumera las cinco situaciones de este catálogo que lo producen.
5. Distingue `@Valid` de `@Validated` en tres ejes: proyecto al que pertenece, dónde se pone y
   qué excepción provoca cuando falla un parámetro de controller.
6. ¿Qué diferencia hay entre `condition` y `unless` en un `@Cacheable`, y cuál de los dos puede
   mirar `#result`?
7. Tienes dos beans de tipo `TaskExecutor` sin cualificar y un método `@Async` sin nombre.
   ¿Falla el arranque? ¿Dónde acaba ejecutándose la tarea?
8. ¿Por qué `@EnableBatchProcessing` no se escribe en una aplicación Spring Boot, y qué se
   rompe si la escribes?
9. `@MockBean` está deprecada: di desde qué versión, qué anotación la sustituye y **de qué
   proyecto** es la sustituta.
10. "Puse `@Timed` y la métrica no aparece": da las tres comprobaciones, en orden, y di cuál de
    ellas es la misma que harías con un `@Cacheable` que no acierta.

---

## 🧪 Ejercicios (10)

Todos se hacen sobre `inv-api` y todos declaran cómo se comprueban. Los que piden romper algo
se deshacen al terminar: este apéndice no deja estado.

### 🟢 Fácil — leer el catálogo con las manos  (1–3)

#### 🟢 Ejercicio 1 — El inventario real de tu proyecto

Saca la lista de todas las anotaciones que hay hoy en `src/main/java` de `inv-api`, ordenadas
por frecuencia, y marca cuáles de ellas **no** aparecen en este catálogo.

**Objetivo:** distinguir lo que el curso enseñó de lo que copiaste sin explicación.
**Se comprueba:** para cada anotación no catalogada puedes decir en una línea qué hace, o la
borras del proyecto.

#### 🟢 Ejercicio 2 — Los cuatro silencios, uno por uno

Toma un método `@Transactional` que funcione y rómpelo cuatro veces: hazlo `private`, hazlo
`final`, llámalo desde otro método de la misma clase y llámalo desde un `@PostConstruct`. Con
`org.springframework.transaction.interceptor` en `TRACE`, anota en cuáles aparece
`Getting transaction for [...]`.

**Objetivo:** que el silencio del proxy sea una observación tuya y no una tabla que leíste.
**Se comprueba:** la línea del interceptor aparece en cero de los cuatro casos, y el
comportamiento de la aplicación no cambia en ninguno.

#### 🟢 Ejercicio 3 — El proxy, en una línea de log

Inyecta en un `ApplicationRunner` tres beans del proyecto —uno con `@Transactional`, uno con
`@Cacheable` y uno sin nada declarativo— e imprime `getClass()` de cada uno.

**Objetivo:** convertir §3 en una comprobación de treinta segundos.
**Se comprueba:** dos nombres traen el sufijo `$$SpringCGLIB$$` y el tercero es el nombre
limpio de tu clase.

### 🟡 Intermedio — llevarlo a otro sitio  (4–7)

#### 🟡 Ejercicio 4 — El 400 que se convierte en 500

Añade `@Validated` a la clase de un `@RestController` que tenga un `@RequestParam` con
`@Max(100)`, llama con `?size=500` y captura el código y la excepción. Quita la anotación y
repite.

**Objetivo:** ver con tus ojos que la anotación que creías que validaba es la que rompe el
status.
**Se comprueba:** la primera llamada responde 500 con `ConstraintViolationException` y la
segunda 400 con `HandlerMethodValidationException`.

#### 🟡 Ejercicio 5 — `@Cacheable` y `@CachePut` en el mismo método

Pon las dos anotaciones sobre el mismo método de `InventoryService`, arranca y llama dos veces
con el mismo `sku`. Anota si el contexto levanta, si el método se ejecuta y qué dice
`cache.gets`.

**Objetivo:** comprobar que Spring **no** rechaza la combinación y entender por qué eso es peor
que un fallo de arranque.
**Pregunta:** ¿qué valida exactamente `SpringCacheAnnotationParser` y por qué este caso no
entra ahí?

#### 🟡 Ejercicio 6 — Una fila nueva para el catálogo

Elige una anotación que uses en el proyecto y que no esté aquí —por ejemplo `@Bean` con
`destroyMethod`, o un `@Scope` con `proxyMode`— y escribe su fila completa con las cuatro
columnas de este apéndice, con el enlace con ancla al documento del curso que la explique.

**Objetivo:** que la ficha sea un procedimiento que sabes aplicar, no un texto que lees.
**Se comprueba:** el enlace abre en la sección exacta, no en la cabecera del documento.

#### 🟡 Ejercicio 7 — Dos anotaciones, un orden

Pon `@Retry` y `@Transactional` sobre el mismo método de servicio, provoca tres fallos seguidos
del proveedor y mide cuánto tiempo estuvo tomada una conexión de Hikari con
`/actuator/metrics/hikaricp.connections.usage`. Invierte el orden declarando las precedencias y
repite.

**Objetivo:** que el ⏱️ de §8 deje de ser una cifra del texto.
**Se comprueba:** los dos órdenes dan tiempos de retención distintos, y sabes decir cuál de los
dos agota el pool antes.

### 🟠 Difícil — combinar y decidir  (8–9)

#### 🟠 Ejercicio 8 — El mock que se comió el proxy

Escribe un test que verifique que un método `@Transactional` hace rollback, y después sustituye
ese bean por un `@MockitoBean`. Explica por escrito qué garantía perdió el test y por qué sigue
en verde.

**Objetivo:** unir §17 con §3: al sustituir un bean sustituyes su proxy.
**Se comprueba:** el test con el mock pasa aunque rompas a propósito la regla de rollback en el
bean real.

#### 🟠 Ejercicio 9 — Tres contextos donde debía haber uno

Toma tres clases de test que hoy comparten configuración y añade a una sola un `@MockitoBean`,
a otra un `@TestPropertySource` y deja la tercera como está. Con
`org.springframework.test.context.cache` en `DEBUG`, cuenta los contextos cargados antes y
después.

**Objetivo:** ver que la caché de contextos la rompen las anotaciones, no el número de tests.
**Se comprueba:** el log pasa de un contexto a tres y el tiempo total de la suite lo refleja.

### 🔴 Muy difícil — se entrega algo roto  (10)

#### 🔴 Ejercicio 10 — Cuatro anotaciones, ningún efecto

Se te entrega una clase de servicio con cuatro anotaciones declarativas —`@Transactional`,
`@Cacheable`, `@Async` y `@PreAuthorize`— y **ninguna de las cuatro produce efecto**. Cada una
falla por una razón distinta de este catálogo, y una de las cuatro falla por dos. Diagnostica
cada caso con la evidencia que corresponda —log del interceptor, `cache.gets`, nombre del hilo,
log de Security en `DEBUG`— y corrige solo lo mínimo.

**Objetivo:** que el triaje de §3 se aplique sin mirar la tabla, y que la evidencia sea distinta
para cada mecanismo.
**Se comprueba:** tienes cuatro evidencias distintas antes de tocar una línea, y después de la
corrección las cuatro cambian de valor.

### 🔥 Opcionales y ampliaciones

- **Un `@Fallback` de verdad.** Declara un `Clock` de sistema con `@Fallback` en una
  configuración propia y un `Clock` fijo en un test, y comprueba que el del test gana sin
  declararse `@Primary`.
- **El catálogo, en tu banco.** Toma un servicio real de tu trabajo y marca qué anotaciones de
  este apéndice usa, cuáles usa sin explicación y cuáles de las trampas de la tercera columna
  están hoy presentes en ese código.

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Anotaciones del contenedor (`@Component`, `@Bean`, `@Configuration`): https://docs.spring.io/spring-framework/reference/6.2/core/beans/java/basic-concepts.html
- Spring Framework 6.2 — `@Autowired`, `@Qualifier` y `@Primary`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/annotation-config/autowired-qualifiers.html
- Spring Framework 6.2 — Scopes de bean y scoped proxies: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-scopes.html
- Spring Framework 6.2 — AOP: declarar un `@Aspect` y los tipos de advice: https://docs.spring.io/spring-framework/reference/6.2/core/aop/ataspectj/advice.html
- Spring Framework 6.2 — Limitaciones de los proxies: https://docs.spring.io/spring-framework/reference/6.2/core/aop/introduction-proxies.html
- Spring Framework 6.2 — Controllers anotados y `@RequestMapping`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-requestmapping.html
- Spring Framework 6.2 — Validación en métodos de controller (`@Valid` y `@Validated`): https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-validation.html
- Spring Framework 6.2 — `@Transactional` y sus atributos: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/annotations.html
- Spring Framework 6.2 — Anotaciones de caché declarativa: https://docs.spring.io/spring-framework/reference/6.2/integration/cache/annotations.html
- Spring Framework 6.2 — `@Async`, `@Scheduled` y sus abstracciones: https://docs.spring.io/spring-framework/reference/6.2/integration/scheduling.html
- Spring Framework 6.2 — Eventos ligados a la transacción (`@TransactionalEventListener`): https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/event.html
- Spring Framework 6.2 — Bean overriding (`@MockitoBean`, `@MockitoSpyBean`, `@TestBean`): https://docs.spring.io/spring-framework/reference/6.2/testing/testcontext-framework/bean-overriding.html
- Spring Framework 6.2 — Anotaciones de test (`@ActiveProfiles`, `@TestPropertySource`, `@DirtiesContext`, `@Sql`): https://docs.spring.io/spring-framework/reference/6.2/testing/annotations.html
- Spring Boot 3.5 — Autoconfiguración y la familia `@ConditionalOn*`: https://docs.spring.io/spring-boot/3.5/reference/using/auto-configuration.html
- Spring Boot 3.5 — Configuración externalizada y `@ConfigurationProperties`: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html
- Spring Boot 3.5 — `@SpringBootTest`, slices y `@MockitoBean`: https://docs.spring.io/spring-boot/3.5/reference/testing/spring-boot-applications.html
- Spring Boot 3.5 — Testcontainers y `@ServiceConnection`: https://docs.spring.io/spring-boot/3.5/reference/testing/testcontainers.html
- Spring Boot 3.5 — Javadoc de `@MockBean`, con su `@Deprecated(since = "3.4.0")`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/test/mock/mockito/MockBean.html
- Spring Boot 3.5 — Aplicaciones batch y propiedades del job: https://docs.spring.io/spring-boot/3.5/how-to/batch.html
- Spring Security 6.5 — Method security (`@PreAuthorize`, `@PostAuthorize`, `@PreFilter`): https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/method-security.html
- Spring Security 6.5 — `authorizeHttpRequests`, `hasRole` y el prefijo `ROLE_`: https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/authorize-http-requests.html
- Spring Security 6.5 — Testing con `MockMvc` y `@WithMockUser`: https://docs.spring.io/spring-security/reference/6.5/servlet/test/index.html
- Spring Data JPA 3.5 — Query methods, `@Query`, `@Modifying` y `@EntityGraph`: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/query-methods.html

### Documentación de terceros

- Resilience4j — Getting started con Spring Boot 3 (`@Retry`, `@CircuitBreaker`, `@Bulkhead`): https://resilience4j.readme.io/docs/getting-started-3
- Micrometer — anotaciones `@Timed` y `@Counted`: https://docs.micrometer.io/micrometer/reference/concepts/timers.html
- Spring Cloud OpenFeign 4.3 — `@FeignClient` y su configuración: https://docs.spring.io/spring-cloud-openfeign/reference/4.3/spring-cloud-openfeign.html
