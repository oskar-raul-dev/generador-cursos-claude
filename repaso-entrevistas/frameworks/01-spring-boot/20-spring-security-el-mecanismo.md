# 20 — Spring Security: el mecanismo

> **Objetivo:** dibujar la cadena de filtros de memoria y decir **en qué filtro exacto** se
> toma cada decisión: quién eres, qué puedes hacer, y quién escribe el 401 o el 403.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md) —la cadena de filtros de Servlet, sin la
> cual este capítulo no se sostiene— y [`05`](05-proxies-y-aop.md).
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Spring Security 6.5.11 (la versión que arrastra el BOM de Boot 3.5.16) · Java 21.

**Salto rápido:** [El problema](#1--el-problema-dos-preguntas-distintas-que-casi-todos-mezclan) · [Un solo filtro](#2--security-es-un-solo-filtro-y-por-dentro-son-veinte) · [La cadena como bean](#3--la-cadena-se-declara-como-bean) · [Autenticación](#4--autenticación-quién-compara-la-credencial) · [`PasswordEncoder`](#5--passwordencoder-y-el-prefijo-bcrypt) · [`SecurityContextHolder`](#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) · [Autorización HTTP](#7--autorización-http-y-el-prefijo-role_) · [Method security](#8--method-security-el-proxy-de-05-con-otro-sombrero) · [401 frente a 403](#9--401-frente-a-403-quién-los-escribe) · [Actuator](#10--asegurar-actuator-sin-escribir-rutas-a-mano) · [CSRF, CORS y sesión](#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api) · [Probarlo](#12--probarlo-sin-levantar-un-proveedor-de-identidad) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 El problema: dos preguntas distintas que casi todos mezclan

Tu `inv-api` expone `POST /api/inventory/adjustments`. Dos cosas tienen que pasar antes de
que el controller se ejecute, y **no son la misma**:

```text
autenticación  → ¿quién eres?          → falla con 401 Unauthorized
autorización   → ¿puedes hacer esto?   → falla con 403 Forbidden
```

La primera se resuelve una vez por petición y produce un objeto: un `Authentication` con tu
identidad y tus `GrantedAuthority`. La segunda se resuelve tantas veces como haga falta —una en
la URL, otra en el método de servicio— y solo produce un sí o un no. Escrito a mano dentro del
controller acaba en un `if` de seguridad por endpoint: olvidas uno y no falla ningún test.

> **🧠 Modelo mental.** Spring Security no es una capa que envuelve tu aplicación: es un
> filtro de Servlet que corre delante del `DispatcherServlet`, más un proxy AOP para los
> métodos. Todo lo demás son detalles de esos dos mecanismos.

De dónde sale la identidad cuando la emite un proveedor externo —OAuth2, OIDC, JWT, resource
server, mapeo de claims— es el capítulo [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md), que continúa este y se practica en [`L08`](l08-security-y-batch.md); el
diseño —zero-trust, confianza entre servicios— vive en el corpus de arquitectura, en [`04-seguridad` §05 — mTLS, zero-trust y service mesh](../../arquitectura/01-bases/04-seguridad/05-mtls-zero-trust-y-mesh.md#3--zero-trust).

---

## 2. 🧱 Security es un solo filtro, y por dentro son veinte

Cuando añades `spring-boot-starter-security`, el contenedor de servlets no ve veinte filtros:
ve uno. La cadena real está dentro.

```text
Tomcat
  └─ Filter #1  RequestIdFilter            (el tuyo, de 08 §4)
  └─ Filter #2  DelegatingFilterProxy      ← registrado como "springSecurityFilterChain"
        └─ FilterChainProxy                ← bean de Spring; elige la cadena
              └─ SecurityFilterChain que matchea la URL
                    SecurityContextHolderFilter  carga el contexto si ya existía
                    HeaderWriterFilter           cabeceras de seguridad
                    CorsFilter                   preflight (§11)
                    CsrfFilter                   valida el token (§11)
                    UsernamePasswordAuthenticationFilter  login por formulario
                    BearerTokenAuthenticationFilter       token (capítulo 20)
                    AnonymousAuthenticationFilter  Authentication "anónimo"
                    ExceptionTranslationFilter     traduce a 401/403 (§9)
                    AuthorizationFilter            decide sí o no ← última palabra
  └─ DispatcherServlet → tu @RestController
```

- **`DelegatingFilterProxy`** es la pieza de [`08` §4](08-modelo-de-ejecucion-web.md#4--la-cadena-de-filtros)
  que permite que un filtro sea un bean: Tomcat registra el proxy, el proxy delega en el bean.
  Boot lo registra con orden `-100` (`SecurityProperties.DEFAULT_FILTER_ORDER`): tus filtros con
  orden mayor corren después de Security y los menores antes —uno de correlación que etiquete
  también los 401 va antes; uno que lea el usuario, después—. Ese orden **no tiene relación** con
  el `@Order` de un `SecurityFilterChain` (§3).
- **`FilterChainProxy`** no es un filtro más: **elige** qué `SecurityFilterChain` aplica a esta
  URL, ejecuta su lista interna y limpia el `SecurityContextHolder` en un `finally` —eso impide
  que el usuario de una petición se filtre a la siguiente por reutilización de hilo—.
- **El orden de la lista interna lo fija Security, no tú.** Lo que decides es dónde insertas un
  filtro propio, con `addFilterBefore(...)` / `addFilterAfter(...)` nombrando al vecino.
- **`ExceptionTranslationFilter` está justo antes del `AuthorizationFilter`**, y esa vecindad
  es todo el §9: solo traduce lo que explote **por dentro** de él.

> **🩺 Diagnóstico.** `logging.level.org.springframework.security=DEBUG` imprime, por petición,
> qué cadena se eligió y por qué filtros pasó. Es lo primero cuando "la regla no se aplica":
> casi siempre matcheó otra cadena.

---

## 3. 🧱 La cadena se declara como bean

Necesitas reglas distintas para la API, para Actuator y para el login, y una sola lista no lo
expresa sin volverse ilegible.

```java
@Bean
@Order(1)
SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher("/api/**")                        // esta cadena solo ve /api/**
        .authorizeHttpRequests(auth -> auth
            .requestMatchers(HttpMethod.GET, "/api/inventory/**").hasAuthority("inventory.read")
            .anyRequest().authenticated())
        .csrf(csrf -> csrf.disable())                      // justificado en §11
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    return http.build();
}
```

- **El bean vive en una `@Configuration` con `@EnableWebSecurity`**, que activa la
  infraestructura; con el starter en el classpath Boot ya la activa y se escribe para dejarlo
  explícito. Lo que sí apaga la autoconfiguración es **declarar este bean**: en cuanto existe,
  Boot deja de crear el suyo, el que pedía login para todo con la contraseña aleatoria que
  imprime a nivel `WARN` en el arranque.
- **`securityMatcher`** decide **qué peticiones entran a esta cadena**; `requestMatchers`,
  dentro de `authorizeHttpRequests`, decide **qué se exige a las que entraron**. Confundirlos
  es el error de configuración más caro: si ninguna cadena matchea una URL, esa URL sale sin
  ninguna regla aplicada.
- **`@Order(1)`** importa porque `FilterChainProxy` elige **la primera cadena que matchea** y las
  demás no se evalúan: una cadena sin `securityMatcher` declarada primero deja muertas al resto.
- **`anyRequest().authenticated()`** es el cierre obligatorio y va al final: las reglas se evalúan
  en orden de declaración, gana la primera que matchea, y lo no listado queda permitido.

> Nunca respondas: ~~"Spring Security se configura con `antMatchers` y
> `WebSecurityConfigurerAdapter`"~~. Mejor: "`WebSecurityConfigurerAdapter` se eliminó en
> Security 6, y `antMatchers`, `mvcMatchers` y `authorizeRequests` con él; hoy se declara un
> `@Bean SecurityFilterChain` y todo es `requestMatchers`."

> **📝 Qué cambia en 4.x.** Boot 4 arrastra Spring Security 7: el estilo lambda deja de ser
> opcional y las clases deprecadas en 6.x se retiran. La forma de este capítulo sobrevive; la
> migración completa es del apéndice `A04`.

---

## 4. 🧱 Autenticación: quién compara la credencial

Llega un usuario y una contraseña. ¿Quién decide si son correctas y dónde enchufas tu tabla?

```text
UsernamePasswordAuthenticationFilter
  → AuthenticationManager            (interfaz: un método, authenticate)
      → ProviderManager              (la implementación normal: una lista de providers)
          → DaoAuthenticationProvider
              → UserDetailsService.loadUserByUsername("analyst@invlab.example")
              → PasswordEncoder.matches(cruda del request, hasheada de la base)
  → Authentication autenticado, con sus GrantedAuthority
```

- **`Authentication`** es el objeto de entrada **y** el de salida: entra sin autenticar, con la
  credencial cruda, y sale autenticado con `principal`, `authorities` y la credencial borrada.
- **`ProviderManager`** recorre sus `AuthenticationProvider` hasta que uno diga que soporta ese
  tipo de `Authentication`. Por eso conviven login por contraseña y por token en la misma
  aplicación: son providers distintos, no cadenas distintas.
- **`UserDetailsService`** es tu punto de extensión: devuelve un `UserDetails` o lanza
  `UsernameNotFoundException`. **No** valida la contraseña; solo trae los datos.
- **`GrantedAuthority`** es un `String` con semántica: `ROLE_ANALYST` es un rol,
  `inventory.read` es un permiso, y para Security son la misma cosa (§7).

> **⏱️ Costo en runtime.** Sin sesión, `loadUserByUsername` corre **en el hilo del request y en
> cada petición**: una consulta y una conexión del pool antes de tu controller. Es una razón de
> peso para validar un token firmado en vez de consultar usuarios (`21`).

---

## 5. 🧱 `PasswordEncoder` y el prefijo `{bcrypt}`

Migras de un algoritmo a otro y tienes hashes viejos en la base. Con un encoder único no
puedes leer los viejos sin forzar a todos a cambiar la contraseña el mismo día.

```java
@Bean
PasswordEncoder passwordEncoder() {
    // delega según el prefijo guardado; codifica las nuevas con bcrypt
    return PasswordEncoderFactories.createDelegatingPasswordEncoder();
}
```

- **`DelegatingPasswordEncoder`** guarda el algoritmo **dentro** del hash, como prefijo `{id}`
  al principio: `{bcrypt}$2a$10$…`, `{noop}password`, `{scrypt}…`. Al validar lee el prefijo y
  delega en ese encoder; al codificar usa el `idForEncode` actual —bcrypt en la fábrica por
  defecto—. Así conviven hashes viejos y nuevos sin migración big-bang.
- **No hay `PasswordEncoder` por defecto, a propósito.** Si el hash de la base no lleva prefijo
  —o está en texto plano— el id se resuelve a `null` y la validación termina así:

```text
java.lang.IllegalArgumentException: There is no PasswordEncoder mapped for the id "null"
```

> **⏱️ Costo en runtime.** bcrypt está diseñado para ser lento: con el `strength` por defecto
> (10) son decenas de milisegundos de CPU por validación, en el hilo del request, y cada punto
> duplica ese costo. Es tiempo bien gastado en un login y una denegación de servicio regalada si
> alguien puede golpear ese endpoint mil veces por segundo.

---

## 6. 🧱 `SecurityContextHolder`: un `ThreadLocal` y sus dos fugas

Autenticado el usuario, ¿cómo llega a un `@Service` tres capas abajo sin pasarlo como
parámetro? Por el mecanismo de `08`: un `ThreadLocal`.

```java
Authentication auth = SecurityContextHolder.getContext().getAuthentication();
String user = auth.getName();          // "analyst@invlab.example"
```

- **Tres niveles, y los tres salen en entrevista:** el holder es el `ThreadLocal`, el
  `SecurityContext` es el contenedor mutable y el `Authentication` es el dato. Lo llena el
  filtro de autenticación que corresponda; lo leen el `AuthorizationFilter`, los proxies de
  method security y tu código; lo limpia el `FilterChainProxy`, en un `finally`.
- **En un controller no se lee así:** `Authentication` como parámetro del método, o
  `@AuthenticationPrincipal`, son testeables y no atan tu servicio a un `ThreadLocal`.

Las dos formas de perderlo son las de siempre:

- **Saltas de hilo y el contexto no va contigo.** Un `@Async`, un `CompletableFuture` con executor
  propio o un `parallelStream()` estrenan un hilo sin `SecurityContext`, y el síntoma es una
  `AccessDeniedException` dentro de un método asíncrono **con el mismo usuario que sí tenía el
  rol**. Se propaga con `DelegatingSecurityContextAsyncTaskExecutor` sobre el pool, en
  [`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request),
  y propagar **copia**, no comparte.
- **`MODE_INHERITABLETHREADLOCAL` no es la solución.** Hereda el contexto a hilos hijos, pero
  con un pool no sirve: el hilo del pool no es hijo de nadie, lo creó el pool al arrancar.

En WebFlux no hay `ThreadLocal` que valga: el contexto viaja en la suscripción, con
`ReactiveSecurityContextHolder`.

---

## 7. 🧱 Autorización HTTP, y el prefijo `ROLE_`

El `AuthorizationFilter` es el último de la cadena y el que dice sí o no: consulta un
`AuthorizationManager` y lanza `AccessDeniedException` cuando la decisión es no.

```java
.authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/inventory/**").hasRole("ANALYST")          // exige ROLE_ANALYST
    .requestMatchers("/api/admin/**").hasAuthority("inventory.write") // exige el literal
    .requestMatchers("/api/public/**").permitAll()
    .anyRequest().authenticated())
```

- **`hasRole("ANALYST")` y `hasAuthority("ANALYST")` no son lo mismo**, y es la pregunta de
  entrevista número uno de la sección: `hasRole` es un atajo de `hasAuthority` que **añade el
  prefijo `ROLE_`** —o el que configures con un bean `GrantedAuthorityDefaults`— y compara contra
  `ROLE_ANALYST`; `hasAuthority` compara el literal. Si tu base guarda `ANALYST` a secas y la
  regla dice `hasRole("ANALYST")`, obtienes un 403 perfecto y silencioso.
- **`permitAll()` no es "sin pasar por Security"**: la regla no exige nada, pero los filtros de
  la cadena —CSRF, cabeceras, CORS— siguen corriendo. Para que una URL ni entre, se la deja
  fuera del `securityMatcher` (§3).
- **`authenticated()` rechaza al anónimo**, aunque el anónimo también tiene un `Authentication`
  —se lo pone `AnonymousAuthenticationFilter`—; lo que no tiene es identidad real.

---

## 8. 🧱 Method security: el proxy de `05` con otro sombrero

La autorización por URL no alcanza cuando la regla depende del dato: "puede ver el ajuste **si es
suyo**" no se expresa en una ruta.

```java
@Service
class AdjustmentService {

    @PreAuthorize("hasAuthority('inventory.write') and #adjustment.warehouse == authentication.name")
    public void apply(Adjustment adjustment) { /* ... */ }
}
```

- **`@EnableMethodSecurity`** lo activa —el starter no lo activa solo— y en Security 6 ya trae
  `prePostEnabled = true`. Sustituye a `@EnableGlobalMethodSecurity`, retirado.
- **`@PreAuthorize`** evalúa **antes**, en SpEL, con acceso a los argumentos (`#adjustment`) y a
  `authentication`. **`@PostAuthorize`** evalúa **después**, sobre `returnObject`: sirve para
  "devuélvelo solo si es suyo" y es peligroso si el método ya escribió, porque ya corrió.
  `@PreFilter` y `@PostFilter` filtran colecciones **en memoria**: con una colección grande se
  filtra en la consulta, no aquí.
- **Esto es un proxy AOP**, el de [`05` §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo),
  con todas sus consecuencias: sobre método `private`, `final` o `static` no hay interceptación, y
  si otro método de la misma clase llama a `apply()`, **la anotación no se evalúa** —la
  self-invocation de [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)—.
  Aquí el fallo silencioso no es una transacción perdida: es una comprobación que no ocurrió.
- **Qué lanza al denegar:** desde Security 6.3, `AuthorizationDeniedException`, que extiende
  `AccessDeniedException`. Importa porque no se lanza donde el `AuthorizationFilter`, y eso cambia
  quién la ve (§9).

> **⚠️ Method security no sustituye a la de URL, la complementa.** La de URL rechaza antes de
> entrar; la de método protege aunque la llamada venga de un `@Scheduled` o de otro controller.

---

## 9. ⚖ 401 frente a 403: quién los escribe

| | 401 Unauthorized | 403 Forbidden |
|---|---|---|
| Significa | no sé quién eres | sé quién eres y no puedes |
| Lo dispara | `AuthenticationException` | `AccessDeniedException` |
| Lo escribe | `AuthenticationEntryPoint` | `AccessDeniedHandler` |
| Qué hacer | reintentar con credencial | no reintentar: falta un permiso |

El que elige es **`ExceptionTranslationFilter`**, y su pseudocódigo está en la documentación:
envuelve el resto de la cadena en un `try`, captura `AuthenticationException` y
`AccessDeniedException`, y si la excepción es de autenticación **o el usuario no está
autenticado** llama al entry point —tiene sentido pedirle credenciales—; si ya estaba autenticado
va al `AccessDeniedHandler`, y el 403 se queda 403.

- **Tu `@ControllerAdvice` no ve lo que pasa en los filtros.** Esas excepciones ocurren antes de
  que el `DispatcherServlet` intervenga, así que el manejo centralizado de
  [`10` §4](10-diseno-de-api-validacion-errores-e-hipermedia.md#4--manejo-centralizado-y-lo-que-se-le-escapa)
  no las toca y tu API responde sin el `ProblemDetail` de
  [`10` §5](10-diseno-de-api-validacion-errores-e-hipermedia.md#5--problemdetail-y-rfc-9457). Para
  que lo haga se registran un `AuthenticationEntryPoint` y un `AccessDeniedHandler` propios.
- **La de method security sí puede llegar a tu `@ControllerAdvice`**, porque el proxy corre dentro
  del `DispatcherServlet`: si declaraste un `@ExceptionHandler(AccessDeniedException.class)` la
  atrapa él y Security no llega a verla; si no, la excepción sube y el `ExceptionTranslationFilter`
  la traduce igual. De ahí la asimetría que desconcierta: la misma excepción se maneja en dos
  sitios según dónde se lanzó y qué handlers declaraste.
- **Un 403 sin log es el peor de los dos.** Un 401 se diagnostica solo —falta o caducó la
  credencial—; un 403 tiene diez causas (prefijo `ROLE_`, cadena equivocada, contexto perdido en un
  `@Async`, authority mal mapeada) y **Security no dice cuál**: el cuerpo llega vacío. La cura son
  las dos cosas juntas: `DEBUG` en `org.springframework.security` (§2) y un `AccessDeniedHandler`
  propio que registre qué regla denegó y con qué authorities.

---

## 10. 🧱 Asegurar Actuator sin escribir rutas a mano

[`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura)
manda expresamente aquí: Actuator no autentica nada, y `/actuator/env` o `/actuator/heapdump`
abiertos son una filtración.

```java
@Bean
@Order(0)
SecurityFilterChain actuatorChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher(EndpointRequest.toAnyEndpoint()
            .excluding(HealthEndpoint.class))                 // el probe queda abierto
        .authorizeHttpRequests(auth -> auth.anyRequest().hasRole("OPS"))
        .httpBasic(Customizer.withDefaults());
    return http.build();
}
```

- **`EndpointRequest.toAnyEndpoint()`** resuelve las rutas reales **en tiempo de ejecución**,
  respetando `management.endpoints.web.base-path` y el puerto de management separado
  ([`23` §3](23-actuator-y-observabilidad.md#3--el-puerto-de-management-separado)). Esa es toda la
  razón para no escribir `/actuator/**` a mano.
- **`.excluding(HealthEndpoint.class)`** deja lo mínimo para que el balanceador sondee sin
  credencial; lo correcto es abrir el grupo de probes, no el `health` detallado, porque
  `show-details` fuera de `never` publica el estado de tu base a quien pregunte.
- **`@Order(0)`** la evalúa antes que la cadena de la API (§3), y **`httpBasic`** basta porque a
  Actuator lo consume una herramienta: una sesión no le aporta nada a un scraper.

---

## 11. 🧱 CSRF, CORS y sesión: las tres que rompen una API

Las tres se tocan en el mismo sitio y producen el mismo ticket —"funciona con curl y no desde el
navegador"—, así que van juntas.

**CSRF** va activado por defecto y protege contra que otro sitio haga que **tu navegador** envíe
una petición con tu cookie adjunta; el ataque depende de que el navegador adjunte la credencial
solo. El `CsrfFilter` valida los métodos **no seguros** —todo lo que no sea `GET`, `HEAD`, `TRACE`
u `OPTIONS`—. Una API stateless con `Authorization: Bearer` no está expuesta —esa cabecera no se
adjunta sola— y ahí `csrf.disable()` es una decisión justificada, no un atajo; una aplicación con
cookie de sesión sí lo está, y desactivarlo es abrir el agujero. Un handshake WebSocket hereda esa
misma cookie, y por eso `@EnableWebSocketSecurity` exige el token en cada `CONNECT` ([`14` §7](14-tiempo-real-sse-y-websocket.md#7--seguridad-el-principal-se-decide-en-el-handshake)).

**CORS** falla antes de llegar a tu configuración de MVC: el navegador manda un `OPTIONS` de
preflight **sin credenciales**, y si la cadena exige autenticación para todo, ese `OPTIONS` recibe
un 401 y el navegador reporta un error de CORS que no es un error de CORS. Por eso se registra en
Security —`http.cors(Customizer.withDefaults())` con un `CorsConfigurationSource` como bean— y no
solo en `WebMvcConfigurer`.

**Sesión:** `SessionCreationPolicy.STATELESS` hace que Security use un
`NullSecurityContextRepository` —ni crea ni consulta `HttpSession` para guardar el contexto—, lo
que cierra el session fixation por definición y es lo correcto con token. Es el motivo de que la
autenticación se repita en cada petición (§4, con su ⏱️).

---

## 12. 🧪 Probarlo sin levantar un proveedor de identidad

Levantar un IdP por test es caro y prueba el IdP, no tus reglas. `spring-security-test` —en scope
`test`, dentro del BOM de Boot— inyecta un `Authentication` ya construido.

```java
@Test
@WithMockUser(username = "analyst@invlab.example", roles = "ANALYST")
void analystPuedeLeerInventario() throws Exception {
    mockMvc.perform(get("/api/inventory/items"))
           .andExpect(status().isOk());
}
```

- **`@WithMockUser(roles = "ANALYST")` prefija `ROLE_` a cada valor; `authorities = "..."` no lo
  prefija**, y si declaras `authorities`, `roles` se ignora. Es el par de §7, y explica el test que
  pasa mientras producción da 403 con la misma regla.
- **`MockMvc` no ejecuta la cadena de filtros por sí solo:** hace falta `@AutoConfigureMockMvc`,
  que la registra, o el post-processor `springSecurity()` en el setup manual. Sin eso los tests
  pasan porque Security nunca corrió, que es el falso verde más peligroso del capítulo.
- **`SecurityMockMvcRequestPostProcessors`** hace lo mismo por petición —`with(user(...))`— y
  `with(csrf())` es lo que arregla los `POST` que dan 403 con CSRF activo.

---

## 🧠 Preguntas rápidas

1. ¿Cuántos filtros registra Spring Security en el contenedor de servlets, y quién ejecuta a
   los demás?
2. Distingue `securityMatcher` de `requestMatchers`. ¿Qué pasa si ninguna cadena matchea una URL?
3. "Spring Security se configura con `antMatchers`": corrige la afirmación con precisión y di
   desde qué versión.
4. Tu regla dice `hasRole("ANALYST")` y el usuario tiene la authority `ANALYST`. ¿Qué código
   HTTP recibe y por qué?
5. ¿Quién decide si una petición denegada sale como 401 o como 403, y con qué criterio?
6. Tu `@RestControllerAdvice` devuelve `ProblemDetail` para todo, pero los 403 llegan con cuerpo
   vacío. ¿Por qué, y qué dos beans lo arreglan?
7. ¿Por qué un 403 es más difícil de diagnosticar que un 401, y qué miras primero?
8. Un `@PreAuthorize` no se evalúa nunca y el método corre igual. Nombra las dos causas más
   probables.
9. Un método `@Async` lanza `AccessDeniedException` con un usuario que sí tiene el rol. ¿Qué
   pasó y cómo se corrige?
10. ¿Por qué `MODE_INHERITABLETHREADLOCAL` no resuelve el problema anterior cuando hay un pool?
11. ¿Qué guarda el prefijo `{bcrypt}` dentro del hash y qué problema operativo resuelve?
12. ¿Por qué `EndpointRequest.toAnyEndpoint()` y no `/actuator/**`?
13. Una API con `Authorization: Bearer` desactiva CSRF y una con cookie de sesión no. ¿Cuál es
    el argumento exacto?
14. Tu test con `@WithMockUser` pasa y producción da 403 con la misma regla. ¿Qué diferencia hay
    entre `roles` y `authorities`?

---

## 📚 Referencias oficiales

- Spring Security 6.5 — Arquitectura: `DelegatingFilterProxy`, `FilterChainProxy` y el pseudocódigo de `ExceptionTranslationFilter`: https://docs.spring.io/spring-security/reference/6.5/servlet/architecture.html
- Spring Security 6.5 — Configuración Java y múltiples cadenas: https://docs.spring.io/spring-security/reference/6.5/servlet/configuration/java.html
- Spring Security 6.5 — Arquitectura de autenticación (`AuthenticationManager`, `ProviderManager`, entry point): https://docs.spring.io/spring-security/reference/6.5/servlet/authentication/architecture.html
- Spring Security 6.5 — `UserDetailsService`: https://docs.spring.io/spring-security/reference/6.5/servlet/authentication/passwords/user-details-service.html
- Spring Security 6.5 — Almacenamiento de contraseñas: formato `{id}`, `DelegatingPasswordEncoder` y el error del id `null`: https://docs.spring.io/spring-security/reference/6.5/features/authentication/password-storage.html
- Spring Security 6.5 — Persistencia del `SecurityContext` y `SessionCreationPolicy`: https://docs.spring.io/spring-security/reference/6.5/servlet/authentication/session-management.html
- Spring Security 6.5 — Arquitectura de autorización y `AuthorizationManager`: https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/architecture.html
- Spring Security 6.5 — `authorizeHttpRequests`, `hasRole` y el prefijo `ROLE_`: https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/authorize-http-requests.html
- Spring Security 6.5 — Method security (`@PreAuthorize`, `@PostAuthorize`, `@PreFilter`): https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/method-security.html
- Spring Security 6.5 — CSRF: https://docs.spring.io/spring-security/reference/6.5/servlet/exploits/csrf.html
- Spring Security 6.5 — CORS: https://docs.spring.io/spring-security/reference/6.5/servlet/integrations/cors.html
- Spring Security 6.5 — Propagación del `SecurityContext` a otros hilos: https://docs.spring.io/spring-security/reference/6.5/features/integrations/concurrency.html
- Spring Security 6.5 — Testing con `MockMvc` y `@WithMockUser`: https://docs.spring.io/spring-security/reference/6.5/servlet/test/index.html
- Spring Boot 3.5 — Autoconfiguración de Spring Security: https://docs.spring.io/spring-boot/3.5/reference/web/spring-security.html
- Spring Boot 3.5 — Endpoints de Actuator y su aseguramiento: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
