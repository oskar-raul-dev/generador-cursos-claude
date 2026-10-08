# 03 — Inyección de dependencias y resolución de candidatos

> **Objetivo:** defender la inyección por constructor con argumentos, y resolver cualquier
> ambigüedad entre candidatos sin ensayo y error.
> **Asume:** [`01`](01-spring-boot-y-el-ecosistema.md), [`02`](02-contenedor-ioc-y-ciclo-de-vida.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 Las tres formas, y por qué solo una sobrevive a una revisión

Spring admite inyectar por constructor, por setter y por campo. Las tres funcionan. Solo
una hace que el problema se vea.

```java
// antipatrón, por campo: corto, cómodo, y esconde todo lo que importa
@Service
class InventoryService {
    @Autowired private InventoryRepository repository;
    @Autowired private SupplierClient supplier;
    @Autowired private AuditService audit;
}

// preferido, por constructor: el mismo código, con la factura a la vista
@Service
class InventoryService {
    private final InventoryRepository repository;
    private final SupplierClient supplier;
    private final AuditService audit;

    // sin @Autowired: hay un solo constructor, y desde Spring 4.3 eso basta
    InventoryService(InventoryRepository repository, SupplierClient supplier, AuditService audit) {
        this.repository = repository;
        this.supplier = supplier;
        this.audit = audit;
    }
}
```

Las tres razones por las que gana el constructor, en orden de peso real:

1. **Los campos pueden ser `final`.** El objeto queda inmutable y completo desde que
   existe: no hay ventana en la que un colaborador sea `null`, y eso elimina una familia
   entera de `NullPointerException` en `@PostConstruct`.
2. **La clase se puede instanciar sin contenedor.** `new InventoryService(mock1, mock2,
   mock3)` en un test unitario, sin levantar un `ApplicationContext` que tarda segundos.
   Con inyección por campo necesitas reflexión o Spring, y la suite se va a los minutos
   ([`24` §2](24-testing.md#2--el-test-unitario-sin-contenedor-y-por-qué-puedes-escribirlo)).
3. **El constructor se vuelve incómodo cuando la clase hace demasiado.** Ocho parámetros
   duelen al leerlos, y ese dolor es la señal de que la clase viola responsabilidad única.
   La inyección por campo anestesia justo esa señal: da igual tener tres dependencias que
   quince.

> **⚠️ El argumento "por campo es más corto" es real y no basta.** Escribes cuatro líneas
> menos y pierdes la inmutabilidad, la testabilidad sin contenedor y el único indicador
> de diseño que el compilador te regala. Si lo que molesta es el boilerplate, la respuesta
> del mundo real es Lombok con `@RequiredArgsConstructor` — legítimo en un proyecto, pero
> fuera de este curso, porque esconde exactamente lo que estamos explicando.

**La inyección por setter** tiene un nicho estrecho y honesto: dependencias genuinamente
opcionales o reconfigurables después de la construcción. En la práctica, casi nunca.

---

## 2. 🧱 `@Autowired`: cuándo hace falta escribirlo

```text
un solo constructor          → @Autowired es opcional (y se omite)
dos o más constructores      → @Autowired marca CUÁL usar, o falla el arranque
campos y setters             → @Autowired es obligatorio
```

- **Con dos constructores y ninguno anotado**, el contenedor no adivina: busca el
  constructor sin argumentos y, si no existe, el arranque falla. El mensaje habla de que
  no encuentra un constructor por defecto y no menciona la ambigüedad, que es lo que
  despista.
- **`@Autowired(required = false)`** deja el punto de inyección vacío si no hay candidato.
  En un constructor eso no tiene sentido —o construyes o no—, así que para dependencias
  opcionales se usa `Optional<T>` o `ObjectProvider<T>`.
- **`ObjectProvider<T>`** es la versión completa: permite `getIfAvailable()`,
  `getIfUnique()`, iterar todos los candidatos y **resolver tarde** en vez de en el
  arranque. Es la herramienta correcta para inyectar un bean de scope corto en uno largo
  ([`04`](04-scopes-de-bean.md)).

---

## 3. 🧱 Cómo elige el contenedor entre candidatos

Aquí está la pregunta que se falla constantemente. El algoritmo, en orden:

```text
1. buscar por TIPO          todos los beans asignables al tipo del punto de inyección
2. ¿uno solo?               → resuelto
3. ¿varios?                 → filtrar por @Qualifier
4. ¿sigue habiendo varios?  → ¿alguno es @Primary?
5. ¿sigue habiendo varios?  → desempatar por NOMBRE (el del campo o el del parámetro)
6. ¿sigue habiendo varios?  → NoUniqueBeanDefinitionException
```

> Nunca respondas: ~~"`@Autowired` inyecta por nombre"~~
>
> Mejor: "resuelve **por tipo**; el nombre es solo el último desempate cuando hay varios
> candidatos del mismo tipo."

Esa diferencia tiene una consecuencia práctica que muerde: **si hay un único candidato,
el nombre del parámetro da exactamente igual**. Y si hay dos, renombrar un parámetro
cambia qué bean se inyecta, sin tocar ninguna anotación. Es un cambio invisible en una
revisión de código.

```text
Parameter 0 of constructor in com.invlab.invapi.inventory.InventoryService required a
single bean, but 2 were found:
	- jdbcInventoryRepository: defined in file [...]
	- mongoInventoryRepository: defined in file [...]
```

- El mensaje **nombra a los candidatos**, y eso es lo primero que hay que leer: casi
  siempre uno de los dos no debería existir.
- Las salidas son cuatro, en orden de preferencia: eliminar el candidato sobrante, marcar
  uno con `@Primary`, cualificar el punto de inyección con `@Qualifier`, o —si de verdad
  quieres los dos— inyectar la colección (§5).

---

## 4. 🧱 `@Primary`, `@Qualifier` y los qualifiers propios

```java
@Configuration
class RepositoryConfig {

    @Bean
    @Primary                      // el candidato por defecto para todo el contexto
    InventoryRepository jdbcInventoryRepository(JdbcClient client) { … }

    @Bean
    @Qualifier("readModel")       // este solo se inyecta si lo piden por nombre cualificado
    InventoryRepository mongoInventoryRepository(MongoTemplate template) { … }
}

@Service
class ProjectionService {
    ProjectionService(@Qualifier("readModel") InventoryRepository repository) { … }
}
```

- **`@Primary` es una propiedad del bean**: dice "si hay duda, yo". Es la herramienta
  correcta cuando hay un default obvio y una excepción rara.
- **`@Qualifier` es una propiedad del punto de inyección**: dice "quiero exactamente
  este". Se usa cuando **no** hay default obvio, y entonces conviene cualificar los dos
  lados en vez de tener uno primario.
- **`@Qualifier` con un `String`** es una cadena mágica: un renombrado la rompe y el
  compilador no dice nada. La versión robusta es un **qualifier propio**, que es una
  anotación anotada con `@Qualifier`:

```java
@Qualifier
@Retention(RUNTIME)
@interface ReadModel {}
```

- **`@Fallback` es el inverso de `@Primary`** y llegó en Spring Framework 6.2: marca un
  bean como el candidato **de reserva**, el que solo se inyecta si no hay ningún otro. Es
  lo que quieres en una autoconfiguración —un `Clock` de sistema, un `ObjectMapper`
  razonable— para que el bean de la aplicación gane sin tener que declararse `@Primary`.

> **📝 Lo que cambia en 4.x.** La resolución de candidatos se afinó en la línea 6.2/6.3 y
> `@Fallback` es la pieza visible: material anterior a 2024 no la menciona y resuelve el
> mismo problema con `@Primary` al revés o con `@ConditionalOnMissingBean`. Si tu proyecto
> corre sobre una línea más nueva, revisa su nota de versión antes de repetir la receta
> vieja en una entrevista.

  Se pone en el `@Bean` y en el punto de inyección, y a partir de ahí el compilador y el
  IDE participan: renombrar es seguro y el autocompletado la encuentra.

> **💡 Truco.** Si acabas con más de dos o tres `@Qualifier("cadena")` en un servicio,
> casi siempre el modelo correcto era una colección de estrategias (§5) y no una lista de
> beans cualificados a mano.

---

## 5. 🧱 Inyectar varios: el Strategy que sale gratis

El contenedor sabe inyectar **todos** los beans de un tipo. Es una de las cosas más
útiles de Spring y una de las menos usadas:

```java
interface InventoryValidator {
    void validate(InventoryEvent event);
}

@Service
class ValidationChain {
    private final List<InventoryValidator> validators;
    private final Map<String, InventoryValidator> byName;

    ValidationChain(List<InventoryValidator> validators, Map<String, InventoryValidator> byName) {
        this.validators = validators;   // todos los beans del tipo, en orden
        this.byName = byName;           // clave = nombre del bean
    }
}
```

- **`List<T>`** recibe todos los candidatos. Si no hay ninguno, falla el arranque salvo
  que el punto sea `@Autowired(required = false)` o la lista venga de un `ObjectProvider`.
- **El orden no es el del classpath ni el alfabético.** Lo decide `@Order(n)` (menor
  primero) o implementar `Ordered`. **Sin orden explícito, el orden es indefinido**, y
  apoyarse en el que salió hoy es un bug esperando a un refactor.
- **`Map<String, T>`** te da los mismos beans indexados por nombre. Es el patrón para
  seleccionar una estrategia por un valor de configuración o por un campo del request.
- **Añadir una estrategia** pasa a ser añadir una clase con `@Component`: cero cambios en
  el código que la usa. Ese es el Open/Closed del que hablan las entrevistas de SOLID,
  con el contenedor haciendo el trabajo.

**Los genéricos también cualifican.** Si tienes `Validator<Invoice>` y
`Validator<Payment>` como beans, un punto de inyección de tipo `Validator<Invoice>`
resuelve sin ambigüedad: Spring compara los tipos genéricos, no solo el tipo crudo.

---

## 6. 🧱 `@Value` y lo que no debe hacer

```java
@Service
class SupplierService {
    private final Duration timeout;

    SupplierService(@Value("${inv.supplier.timeout:2s}") Duration timeout) {
        this.timeout = timeout;
    }
}
```

- **`${...}`** es un placeholder resuelto contra el `Environment` en el arranque.
  `:2s` es el valor por defecto si la propiedad no existe; **sin él, la propiedad ausente
  rompe el arranque**, que casi siempre es lo que quieres.
- **La conversión a `Duration`** la hace el sistema de conversión de Spring: `2s`, `500ms`
  y `PT2S` funcionan. Inyectar un `String` y parsearlo a mano es trabajo tirado.
- **`#{...}`** es SpEL —expresiones evaluadas en tiempo de ejecución— y es una puerta
  abierta a la complejidad. Úsalo para lo trivial y nada más.

> **⚠️ Tres o más `@Value` en la misma clase es la señal de que eso era un
> `@ConfigurationProperties`**: tipado, validable, agrupado y documentado, en vez de
> cadenas sueltas repartidas por el código. Se ve entero en [`07`](07-configuracion-externalizada.md).

---

## 7. 🩺 Dependencias circulares

`A` necesita `B` y `B` necesita `A`. Con inyección por constructor, el contenedor no
puede construir ninguno de los dos y el arranque falla:

```text
The dependencies of some of the beans in the application context form a cycle:

┌─────┐
|  inventoryService defined in file [...]
↑     ↓
|  auditService defined in file [...]
└─────┘
```

Lo importante de este error es que **es una buena noticia**: te avisa al desplegar, con un
diagrama, y no en producción.

- **Con inyección por campo el ciclo "funcionaba"** porque el contenedor creaba ambos
  objetos vacíos y rellenaba los campos después. El ciclo seguía ahí, solo que invisible.
- **`spring.main.allow-circular-references=true`** restaura ese comportamiento. Es una
  deuda declarada, no una solución: úsalo para desbloquear un legacy mientras arreglas el
  diseño, con fecha.
- **`@Lazy` en uno de los dos lados** también rompe el ciclo, inyectando un proxy que
  resuelve el bean al primer uso. Funciona, y sigue sin arreglar el diseño.
- **La solución real** es casi siempre extraer lo compartido a un tercer bean, o darle la
  vuelta a la dependencia con un evento ([`18` §8](18-asincronia-scheduling-y-eventos.md#8--eventos-de-aplicación-síncronos-por-defecto)): en vez de que `inventoryService` llame a
  `auditService`, publica un evento que el segundo escucha.

---

## 8. ⚠️ Errores frecuentes

- **"`@Autowired` inyecta por nombre."** Por tipo; el nombre es el último desempate.
- **"`@Primary` y `@Qualifier` hacen lo mismo."** Uno marca al bean, el otro al punto de
  inyección. Elegir mal se nota cuando aparece el tercer candidato.
- **"El orden de una `List<T>` inyectada es el de declaración."** Es indefinido sin
  `@Order`.
- **"`@Resource` es igual que `@Autowired`."** `@Resource` (de Jakarta) resuelve **primero
  por nombre** y después por tipo — exactamente al revés. Verlo en código heredado y
  suponer que se comporta igual es una fuente de bugs silenciosos.
- **"Las dependencias circulares se arreglan con `@Lazy`."** Se ocultan. La pregunta
  siguiente en una entrevista es por qué existía el ciclo.

---

## 🧠 Preguntas rápidas

1. Da las tres razones para inyectar por constructor, ordenadas por peso, y di cuál de
   ellas es un argumento de diseño y no de mecánica.
2. ¿Cuándo es obligatorio escribir `@Autowired` y cuándo se omite?
3. Una clase tiene dos constructores y ninguno anotado. ¿Qué pasa en el arranque?
4. Describe el algoritmo de resolución de candidatos en orden. ¿En qué paso entra el
   nombre?
5. Tienes un único bean de un tipo y renombras el parámetro del constructor. ¿Cambia algo?
   ¿Y si tuvieras dos beans de ese tipo?
6. ¿Qué diferencia hay entre `@Primary` y `@Qualifier`, y en qué situación es preferible
   cada uno?
7. ¿Por qué un qualifier propio es más seguro que `@Qualifier("cadena")`?
8. ¿Qué recibe un parámetro declarado como `Map<String, InventoryValidator>` y qué son las
   claves?
9. ¿Qué determina el orden de una `List<T>` inyectada, y qué pasa si no lo declaras?
10. `@Value("${inv.supplier.timeout}")` sin valor por defecto y sin la propiedad definida:
    ¿qué ocurre, y por qué suele ser lo deseable?
11. ¿A partir de cuántos `@Value` en una clase deberías cambiar a
    `@ConfigurationProperties`, y qué ganas?
12. Un ciclo de dependencias rompe el arranque con inyección por constructor pero
    "funcionaba" con inyección por campo. ¿Qué hacía distinto el contenedor?
13. Nombra las tres salidas de un ciclo y di cuál es deuda técnica y cuál es solución.
14. ¿En qué se diferencia `@Resource` de `@Autowired` al resolver?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Dependency Injection: https://docs.spring.io/spring-framework/reference/6.2/core/beans/dependencies/factory-collaborators.html
- Spring Framework 6.2 — `@Autowired`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/annotation-config/autowired.html
- Spring Framework 6.2 — Qualifiers y `@Primary`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/annotation-config/autowired-qualifiers.html
- Spring Framework 6.2 — Modos de autowiring: https://docs.spring.io/spring-framework/reference/6.2/core/beans/dependencies/factory-autowire.html
- Spring Framework 6.2 — `@Value`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/annotation-config/value-annotations.html
- Spring Framework 6.2 — SpEL: https://docs.spring.io/spring-framework/reference/6.2/core/expressions.html
- Spring Boot 3.5 — Beans e inyección de dependencias: https://docs.spring.io/spring-boot/3.5/reference/using/spring-beans-and-dependency-injection.html
