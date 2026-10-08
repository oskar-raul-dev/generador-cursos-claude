# 02 — El contenedor IoC: definición de beans y ciclo de vida

> **Objetivo:** poder describir qué pasa entre `main()` y el primer request, saber en qué
> fase nace cada cosa y no confundir nunca más la **definición** de un bean con su
> instancia.
> **Asume:** [`01`](01-spring-boot-y-el-ecosistema.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: quién crea tus objetos

Escribe un servicio sin contenedor y el problema aparece en la tercera línea:

```java
class TransferService {
    private final AccountRepository accounts = new JdbcAccountRepository(dataSource);
    // ¿y de dónde sale dataSource? ¿y quién decide que es JDBC y no otro?
}
```

Ese `new` tiene tres consecuencias que no se ven hasta que duelen. **Acopla** el servicio
a una implementación concreta, así que cambiarla obliga a tocar esta clase. **Propaga la
construcción**: para crear el repositorio necesitas el `DataSource`, para el `DataSource`
necesitas la configuración, y acabas con un constructor que construye medio sistema.
Y **mata la prueba**: no hay forma de instanciar `TransferService` con un repositorio
falso sin tocar su código.

La salida es sacar la construcción fuera de la clase y dársela a alguien que sepa el
grafo entero. Ese alguien es el contenedor.

> **🧠 Modelo mental.** El contenedor no es un `Map<String, Object>` con objetos dentro.
> Es un **grafo de recetas** —qué construir, con qué, en qué orden y con qué envoltorios—
> que se resuelve una vez en el arranque. Casi todo lo raro que hace Spring se explica
> mirando la receta, no el objeto.

---

## 2. 🧱 `BeanFactory` y `ApplicationContext`

Son dos interfaces y una relación de herencia, y la pregunta sale en entrevistas:

| | `BeanFactory` | `ApplicationContext` |
|---|---|---|
| Qué es | El contenedor mínimo: registro y resolución de beans | `BeanFactory` + todo lo que hace útil a Spring |
| Añade | — | Eventos, i18n, `Environment`, carga de recursos, integración AOP |
| Instanciación | Perezosa por diseño | **Ansiosa** para los singletons |

En una aplicación Spring Boot **siempre** trabajas con un `ApplicationContext`; el
`BeanFactory` aparece cuando extiendes el contenedor (`BeanFactoryPostProcessor`). La
distinción importa por una sola razón práctica, y es la que sigue.

---

## 3. 🧱 Bean definition vs instancia

Esta es la distinción que sostiene el capítulo entero, y casi nadie la nombra en una
entrevista.

```text
bean definition                          instancia
─────────────────                        ─────────
clase, scope, dependencias,              el objeto (o el proxy) que vive
init/destroy, lazy, primary              en el contenedor
        │                                        ▲
        └──── el contenedor la usa para ─────────┘
              construir, una o muchas veces
```

Una **bean definition** es metadato: de qué clase, con qué constructor, qué scope, si es
`@Primary`, qué método de init tiene. Se registra en el arranque —desde el component
scan, desde una `@Configuration`, desde una autoconfiguración— y **antes de que exista
ningún objeto**.

La instancia viene después, y cuántas haya lo decide el scope ([`04`](04-scopes-de-bean.md)).

> **💡 Truco.** Toda la configuración de Spring es, en el fondo, manipulación de bean
> definitions: `@Profile` decide si se registra, `@Conditional` también,
> `@ConditionalOnMissingBean` mira si ya hay otra, y `@Primary` marca una para desempatar.
> Si piensas en términos de definiciones, la autoconfiguración de [`06`](06-arranque-y-autoconfiguracion.md) deja de ser magia.

---

## 4. 🧱 Las fases del arranque

Este diagrama es el que conviene poder dibujar en una pizarra:

```text
1. Registro de bean definitions      component scan, @Bean, autoconfiguración
            ▼
2. BeanFactoryPostProcessor          modifica DEFINICIONES, no objetos
            ▼                        (aquí resuelve ${...} el PropertySourcesPlaceholderConfigurer)
3. Instanciación                     se llama al constructor (aquí entra la inyección
            ▼                         por constructor)
4. Inyección de campos y setters     @Autowired, @Value
            ▼
5. Aware callbacks                   BeanNameAware, ApplicationContextAware
            ▼
6. BeanPostProcessor.before          ◄── aquí se crean LOS PROXIES (ver 05)
            ▼
7. @PostConstruct → InitializingBean.afterPropertiesSet → initMethod
            ▼
8. BeanPostProcessor.after
            ▼
9. Contexto listo → ApplicationReadyEvent
```

Tres lecturas que salen de ahí y que valen una entrevista:

- **El constructor corre antes que la inyección de campos.** Por eso un `@Value` en un
  campo es `null` dentro del constructor, y por eso la lógica de inicialización va en
  `@PostConstruct` y no en el constructor — y por eso la inyección por constructor es la
  única que te entrega el bean completo, que es el argumento entero de
  [`03`](03-inyeccion-de-dependencias.md).
- **Los proxies se crean en el paso 6, envolviendo un objeto ya construido.** De ahí sale
  todo lo de [`05`](05-proxies-y-aop.md): lo que el contenedor entrega a tus otros beans no es necesariamente el
  objeto que tu constructor creó.
- **`@PostConstruct` corre sobre el objeto interno, no sobre el proxy.** Llamar desde ahí
  a un método `@Transactional` de la propia clase no abre transacción, y no avisa.

> **🩺 Diagnóstico.** Cuando dudes de qué beans hay y de dónde salieron, no lo supongas:
> el endpoint `/actuator/beans` lista cada bean con su tipo, su scope y quién lo declaró.
> Se activa en [`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura) y es la herramienta que cierra el 80 % de estas discusiones.

---

## 5. 🧱 `@Component` y `@Bean`: no son lo mismo

Los dos producen una bean definition. Se diferencian en **quién escribió la clase**.

```java
// @Component: la clase es tuya, Spring la encuentra y la instancia él
@Service
class InventoryService {
    private final InventoryRepository repository;

    InventoryService(InventoryRepository repository) {
        this.repository = repository;
    }
}

// @Bean: la clase es de un tercero, tú escribes la receta de construcción
@Configuration
class HttpClientConfig {

    @Bean
    RestClient supplierClient(RestClient.Builder builder) {
        // sin timeout explícito esto se queda colgado para siempre; ver 13
        return builder.baseUrl("https://inv-supplier.invlab.example").build();
    }
}
```

- **`@Service`** es un `@Component` con estereotipo. Para el contenedor son equivalentes;
  la diferencia es semántica y que algunas herramientas y aspectos filtran por él. Los
  otros estereotipos son `@Repository` —que además traduce las excepciones del driver a
  la jerarquía `DataAccessException` ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md)), y eso **sí** es comportamiento, no
  decoración— y `@Controller`.
- **El nombre del bean** sale del nombre de la clase con la primera letra en minúscula
  (`inventoryService`) o, con `@Bean`, del **nombre del método** (`supplierClient`).
  Renombrar un método `@Bean` renombra el bean, y eso rompe cualquier `@Qualifier` que lo
  buscara por nombre.
- **El parámetro `RestClient.Builder`** del método `@Bean` se inyecta igual que en un
  constructor: los argumentos de un método `@Bean` son puntos de inyección.

> Nunca respondas: ~~"`@Component` y `@Bean` son lo mismo"~~
>
> Mejor: "los dos registran una bean definition, pero `@Component` requiere que la clase
> sea tuya y anotable, y `@Bean` te deja construir cualquier objeto —incluido uno de una
> librería— con lógica de por medio."

---

## 6. 🧱 `@Configuration` y `proxyBeanMethods`

Aquí hay un comportamiento que sorprende a todo el mundo la primera vez. Mira este código
y predice cuántos `ObjectMapper` se crean:

```java
@Configuration
class SerializationConfig {

    @Bean
    ObjectMapper objectMapper() {
        return new ObjectMapper();
    }

    @Bean
    InventoryMapper inventoryMapper() {
        return new InventoryMapper(objectMapper());  // ¿otra instancia?
    }
}
```

**Se crea uno solo.** Una clase `@Configuration` se registra en el contenedor como un
proxy CGLIB, y ese proxy intercepta las llamadas entre métodos `@Bean`: cuando
`inventoryMapper()` invoca a `objectMapper()`, el proxy no ejecuta el método, sino que
devuelve el bean que ya existe en el contenedor. Es el llamado **modo full**.

- **`@Configuration(proxyBeanMethods = false)`** apaga ese proxy —el **modo lite**— y
  entonces sí obtienes dos instancias: la llamada entre métodos es una llamada Java
  normal. Se usa cuando los métodos `@Bean` no se llaman entre sí, y ahorra la creación
  del proxy en el arranque. **Las autoconfiguraciones de Boot lo usan casi siempre**, y
  por eso lo verás mucho al leer su código fuente.
- **`@Bean` dentro de una clase `@Component`** también funciona, pero es modo lite: sin
  proxy y sin esa protección. Es una fuente de duplicados silenciosos.

> **⚠️ Esta es la primera vez que un proxy cambia el significado de tu código, y no es la
> última.** El mismo mecanismo explica por qué `@Transactional`, `@Cacheable` y `@Async`
> funcionan —y por qué a veces no hacen nada—. Ese es el capítulo `05`, y es el más
> enlazado del curso por una razón.

---

## 7. 🧱 Component scan: el paquete base

`@SpringBootApplication` incluye `@ComponentScan` sin argumentos, lo que significa
**escanear desde el paquete de la clase anotada, hacia abajo**.

```text
com.invlab.invapi            ← InvApiApplication vive aquí
├── inventory                ✅ escaneado
├── supplier                 ✅ escaneado
└── config                   ✅ escaneado

com.invlab.shared            ❌ NO escaneado: está fuera del subárbol
```

- **El síntoma de equivocarse** es `NoSuchBeanDefinitionException` en el arranque sobre
  una clase que *claramente* tiene `@Service`. La causa casi nunca es la anotación: es que
  la clase está fuera del subárbol.
- **Las tres salidas**, en orden de preferencia: mover la clase, declarar
  `@ComponentScan(basePackages = ...)`, o —para una librería compartida— darle su propia
  autoconfiguración ([`06`](06-arranque-y-autoconfiguracion.md)), que es lo correcto y lo
  que casi nadie hace.
- **`@Import` es la cuarta salida y la que nadie recuerda**: trae una clase
  `@Configuration` —o un `ImportSelector`— sin escanear nada, esté donde esté. Es el
  mecanismo sobre el que se apoyan las autoconfiguraciones de Boot, y la forma limpia de
  componer configuraciones de una librería sin abrir el escaneo a su paquete.
- **No pongas la clase de arranque en el paquete raíz** (`com` o sin paquete): escanearía
  medio mundo, incluidas las librerías del classpath, y el arranque se va a los segundos.

> **⏱️ Costo en runtime.** Cada bean cuesta arranque: escaneo, definición, instanciación,
> inyección y evaluación de proxies. Un servicio con 300 beans arranca en el entorno de
> los dos segundos; uno con 3 000 —típico de un monolito bancario— se va a los veinte o
> treinta. En un contenedor que escala bajo demanda, eso es latencia de usuario, y es la
> razón por la que existen `@Lazy`, la AOT y las imágenes native (`L09`).

---

## 8. 🧱 Registro condicional: `@Profile` y `@Conditional`

Una bean definition puede registrarse o no según el entorno. Son dos mecanismos con la
misma raíz:

- **`@Profile("local")`** registra el bean solo si ese profile está activo. Es el caso
  fácil y se ve entero en [`07`](07-configuracion-externalizada.md).
- **`@Conditional(MiCondicion.class)`** evalúa una clase que implementa `Condition` y
  decide. Sobre este mecanismo Boot construye toda su familia `@ConditionalOnClass`,
  `@ConditionalOnMissingBean`, `@ConditionalOnProperty` — es decir, **la autoconfiguración
  entera es `@Conditional` bien usado** ([`06`](06-arranque-y-autoconfiguracion.md)).

> **⚠️ La condición se evalúa en el registro, no en cada uso.** Un bean que no se registró
> no aparece luego porque cambie una propiedad en caliente. Y un `@Profile("!prod")` sobre
> un bean de seguridad que desactiva la autenticación es una bomba: basta con que alguien
> arranque sin el profile correcto.

---

## 9. 🧱 Destrucción, y lo que el contenedor no destruye

El cierre ordenado importa más de lo que parece: conexiones, pools, executors y clientes
HTTP tienen recursos que liberar.

- **`@PreDestroy`** se ejecuta al cerrar el contexto, en orden inverso al de creación.
- **`DisposableBean.destroy()`** y el atributo `destroyMethod` de `@Bean` son las otras
  dos formas; `@Bean` además **detecta por convención** un método público llamado
  `close()` o `shutdown()` y lo llama solo. Si tu bean tiene un `close()` que no quieres
  que se llame, hay que declarar `destroyMethod = ""`.
- **Los beans `prototype` no se destruyen nunca.** El contenedor los crea y los entrega,
  pero no guarda referencia, así que no ejecuta su `@PreDestroy`. Liberar sus recursos es
  tuyo. Es la mitad del capítulo `04`.
- **El hook de la JVM.** Boot registra un shutdown hook, así que un `SIGTERM` cierra el
  contexto ordenadamente. Un `SIGKILL` no: ahí no corre nada. La diferencia con las
  peticiones en vuelo es el `graceful shutdown` de [`L09` §7](l09-empaquetado-imagen-y-limpieza.md#7--graceful-shutdown-con-una-petición-en-vuelo).

---

## 10. ⚠️ Errores frecuentes

- **"Los beans se crean cuando se usan."** Los singletons se crean **en el arranque**, y
  eso es deliberado: un error de configuración revienta al desplegar y no a las tres de la
  mañana con el primer request. `@Lazy` invierte eso bean a bean, y
  `spring.main.lazy-initialization=true` lo invierte entero — cómodo en desarrollo, mala
  idea en producción por la misma razón.
- **"El contenedor me devuelve mi objeto."** Te devuelve tu objeto **o un proxy que lo
  envuelve**, y no puedes saberlo mirando el tipo declarado.
- **"`@PostConstruct` es como el constructor pero mejor."** Corren en fases distintas: en
  el constructor no hay inyección de campos, y en `@PostConstruct` todavía no hay proxy
  aplicado a la propia instancia.
- **"Si la clase tiene `@Service`, el bean existe."** Existe si además está bajo el
  paquete base del scan y ninguna condición lo excluyó.

---

## 🧠 Preguntas rápidas

1. Explica la diferencia entre una bean definition y una instancia, y nombra tres cosas
   que viven en la definición.
2. ¿En qué fase del arranque se crean los proxies, y qué implica eso para el código que
   escribes en `@PostConstruct`?
3. ¿Por qué un `@Value` sobre un campo vale `null` dentro del constructor?
4. Tienes una clase de una librería de terceros que necesitas como bean. ¿`@Component` o
   `@Bean`? ¿Por qué no tienes elección?
5. ¿Qué diferencia de comportamiento real —no semántica— tiene `@Repository` frente a
   `@Component`?
6. Un método `@Bean` llama a otro método `@Bean` de la misma clase `@Configuration`.
   ¿Cuántas instancias se crean, y qué lo decide?
7. ¿Qué hace `proxyBeanMethods = false` y por qué las autoconfiguraciones de Boot lo usan?
8. Tu clase tiene `@Service` y el arranque falla con `NoSuchBeanDefinitionException`.
   ¿Cuál es la causa más probable y cómo lo confirmas?
9. ¿Qué pasa si pones la clase `@SpringBootApplication` en el paquete raíz del proyecto?
10. ¿Cuándo se evalúa un `@Conditional`, y por qué eso hace imposible activar un bean
    cambiando una propiedad en caliente?
11. ¿Qué beans **no** ejecutan su `@PreDestroy`, y de quién es entonces la
    responsabilidad de liberar sus recursos?
12. `spring.main.lazy-initialization=true` acelera el arranque. ¿Por qué el curso
    desaconseja usarlo en producción?
13. ¿Qué comando o endpoint usarías para saber qué beans existen y quién los declaró?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — The IoC Container: https://docs.spring.io/spring-framework/reference/6.2/core/beans.html
- Spring Framework 6.2 — Bean Definition: https://docs.spring.io/spring-framework/reference/6.2/core/beans/definition.html
- Spring Framework 6.2 — Ciclo de vida y callbacks: https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-nature.html
- Spring Framework 6.2 — Configuración con Java (`@Bean`, `@Configuration`): https://docs.spring.io/spring-framework/reference/6.2/core/beans/java/basic-concepts.html
- Spring Framework 6.2 — Classpath scanning y estereotipos: https://docs.spring.io/spring-framework/reference/6.2/core/beans/classpath-scanning.html
- Spring Framework 6.2 — Extensión del contenedor (`BeanPostProcessor`): https://docs.spring.io/spring-framework/reference/6.2/core/beans/factory-extension.html
- Spring Framework 6.2 — Inicialización perezosa: https://docs.spring.io/spring-framework/reference/6.2/core/beans/dependencies/factory-lazy-init.html
- Spring Boot 3.5 — Estructura del código y paquete base: https://docs.spring.io/spring-boot/3.5/reference/using/structuring-your-code.html
