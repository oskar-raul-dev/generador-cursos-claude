# 02 — Spring Security por dentro

> La cadena de filtros, el `SecurityContext` y su relación con el hilo, cómo se configura hoy, y
> los tres fallos que explican el 90 % de los "no funciona": el orden de las reglas, el contexto
> perdido en un hilo nuevo, y el método interno que no pasa por el proxy.
> Asume leído [`01` — Autenticación, autorización y amenazas](01-autenticacion-autorizacion-y-amenazas.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Spring Security se pregunta en casi toda entrevista de backend Java, y la pregunta que separa no es "¿cómo se
configura?" sino *"¿qué pasa exactamente entre que llega la petición y que se ejecuta tu
controlador?"*.

Quien no lo sabe describe Spring Security como una caja de anotaciones, y se queda sin respuesta
ante los tres síntomas clásicos:

```text
"La ruta pública pide login"           → orden de las reglas
"En el @Async el usuario es null"      → el contexto vive en el hilo
"@PreAuthorize no se aplica"           → la llamada no pasó por el proxy
```

Los tres tienen la misma raíz: **Spring Security no es magia declarativa, es una cadena de filtros
de servlet con estado atado al hilo**.

> **Regla:** si entiendes la cadena de filtros y dónde vive el `SecurityContext`, los tres
> síntomas se diagnostican en un minuto. Si no, se depuran a ciegas.

---

## 2. ⛓️ La cadena de filtros

**Qué es.** Spring Security se inserta en el contenedor de servlets como **un solo filtro**
—`DelegatingFilterProxy`, registrado como `springSecurityFilterChain`— que delega en una cadena
de filtros internos. Cada uno tiene una responsabilidad y un orden fijo.

```text
petición
   ↓
DelegatingFilterProxy  →  FilterChainProxy  →  elige la SecurityFilterChain que corresponde
   ↓
SecurityContextPersistenceFilter   carga el contexto (de la sesión, o vacío)
CsrfFilter                         valida el token CSRF si aplica
[Authentication filters]           form login, Basic, BearerTokenAuthenticationFilter…
ExceptionTranslationFilter         convierte excepciones en 401 / 403 y dispara el punto de entrada
AuthorizationFilter                aplica las reglas de authorizeHttpRequests
   ↓
DispatcherServlet → tu controlador
```

- **Cada filtro decide si continúa o corta.** Un filtro que no llama a `chain.doFilter` termina la
  petición ahí: eso es lo que hace un 401.
- **`ExceptionTranslationFilter` va antes que `AuthorizationFilter`** a propósito: tiene que estar
  envolviendo a quien lanza la excepción para poder traducirla. De ahí que un acceso denegado
  produzca un 403 con cuerpo controlado y no una traza.
- **Puede haber varias cadenas.** Un `SecurityFilterChain` por patrón de rutas permite tener la API
  sin estado con Bearer y la consola de administración con sesión y formulario, cada una con sus
  reglas.

**Cómo se ve en el código moderno.** Desde Spring Security 6 se configura con beans, sin extender
`WebSecurityConfigurerAdapter` —que está eliminado— y con la API de lambdas:

```java
@Bean
SecurityFilterChain api(HttpSecurity http) throws Exception {
    return http
        .securityMatcher("/api/**")                       // esta cadena solo aplica a /api
        .csrf(csrf -> csrf.disable())                     // API sin estado: ver §5
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .authorizeHttpRequests(a -> a
            .requestMatchers("/api/publico/**").permitAll()
            .requestMatchers("/api/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated())                // SIEMPRE el último
        .oauth2ResourceServer(o -> o.jwt(withDefaults()))
        .build();
}
```

- `securityMatcher` limita la cadena entera a esas rutas; sin él, esta cadena intentaría atender
  todo.
- **El orden de `requestMatchers` importa y es el fallo número uno**: se evalúan de arriba abajo y
  gana el primero que coincide. Poner `anyRequest().authenticated()` antes de las reglas
  específicas hace que ninguna se aplique.
- `STATELESS` significa que no se crea ni se consulta sesión: el contexto se reconstruye del token
  en cada petición.

> ⚠️ **Advertencia.** *"La ruta pública pide login"* es casi siempre una regla más general colocada
> antes que la específica. Con `.anyRequest()` primero, todo lo demás es decorativo.

> **Veredicto:** Spring Security es una cadena de filtros, no un conjunto de anotaciones. Poder
> nombrar tres filtros y qué hace cada uno es lo que distingue en una entrevista.

---

## 3. 🧵 El `SecurityContext` y el hilo

**Qué es.** Dónde vive la identidad durante la petición. Y su implementación explica un síntoma
clásico:

```text
SecurityContextHolder  →  ThreadLocal<SecurityContext>
                              ↓
                          Authentication  →  principal · credentials · authorities
```

- **Es un `ThreadLocal`.** La identidad está atada al hilo que atiende la petición, y **no se
  propaga sola** a otros hilos.
- Por eso en un `@Async`, en un `CompletableFuture` o en un pool propio,
  `SecurityContextHolder.getContext().getAuthentication()` devuelve `null`.
- `SecurityContextPersistenceFilter` lo carga al principio de la petición y **lo limpia al final**,
  que es esencial: si no se limpiara, el siguiente uso de ese hilo del pool heredaría la identidad
  del anterior. Es exactamente la fuga entre peticiones que vimos en multi-tenancy.

**Cómo se propaga a otros hilos**, que es lo que se pregunta:

```java
// Estrategia heredable: el hilo hijo recibe el contexto del padre
SecurityContextHolder.setStrategyName(MODE_INHERITABLETHREADLOCAL);

// O, mejor, delegar el ejecutor: envuelve cada tarea propagando el contexto
new DelegatingSecurityContextExecutorService(pool);
```

- La primera funciona con hilos creados directamente y **falla con pools reutilizados**, porque el
  hilo del pool ya existía cuando se heredó.
- La segunda es la correcta: envuelve el ejecutor y propaga el contexto por tarea, no por hilo.
- Con **virtual threads** el `ThreadLocal` sigue funcionando, y el problema del pool desaparece
  porque cada tarea tiene su hilo.

> 🩺 **Diagnóstico.** "En el proceso asíncrono el usuario es null": no es un bug de Spring
> Security, es que el contexto es un `ThreadLocal` y nadie lo propagó. Saber decir eso es la
> respuesta completa.

> **Veredicto:** el `ThreadLocal` explica a la vez la comodidad —no pasas el usuario por
> parámetro— y los tres problemas más comunes. Es el detalle de implementación que más rinde
> conocer.

---

## 4. 🔒 Autorización a nivel de método

**Qué es.** La segunda capa, dentro del servicio, que es donde vive la decisión fina de
[`01` §4](01-autenticacion-autorizacion-y-amenazas.md#4--dónde-se-decide-y-dónde-se-aplica).

```java
@EnableMethodSecurity                      // activa el soporte; no viene por defecto

@PreAuthorize("hasRole('GESTOR') and #cuentaId.startsWith(authentication.name)")
Cuenta consultar(String cuentaId) { ... }

@PostAuthorize("returnObject.titular == authentication.name")
Cuenta porId(String id) { ... }            // decide sobre el resultado: ojo al coste
```

- `@PreAuthorize` evalúa **antes** de ejecutar y es lo que quieres casi siempre.
- `@PostAuthorize` evalúa **después**, sobre el objeto devuelto. Es útil cuando la decisión depende
  del contenido, y peligroso: el método **ya se ejecutó**, así que si tenía efectos secundarios,
  ocurrieron.
- `@PreFilter` y `@PostFilter` filtran colecciones. `@PostFilter` sobre un listado paginado es un
  error frecuente: filtra después de paginar, así que las páginas quedan incompletas.

**El mecanismo, que explica el tercer síntoma.** La seguridad de métodos funciona **por proxy**,
igual que `@Transactional` de [`01-bases/04`](../01-bases/04-patrones-gof.md). Y de ahí:

```text
@PreAuthorize en un método llamado con this.metodo()  → NO se aplica
@PreAuthorize en un método private o final            → NO se aplica
@PreAuthorize en una clase que no es un bean          → NO se aplica
```

> ⚠️ **Advertencia.** La autorización que no se aplica **no falla ruidosamente**: simplemente deja
> pasar. Es el modo de fallo peor posible, porque no hay error que investigar. Por eso conviene un
> test que verifique que un usuario sin permiso recibe 403 en cada método sensible.

> **Veredicto:** `@PreAuthorize` es el PEP dentro del servicio, y su talón de Aquiles es el mismo
> que el de `@Transactional`. Quien conoce una conoce la otra.

---

## 5. 🛡️ CSRF, CORS y el sinsentido habitual

**Qué es.** Dos mecanismos que se confunden y que producen la configuración copiada más peligrosa
del ecosistema.

**CSRF.** Protege contra que otro sitio haga que **tu navegador** envíe una petición autenticada
con tus cookies. El token CSRF, que el atacante no puede leer, rompe el ataque.

```text
¿Hay cookies de sesión?   → CSRF es necesario
¿API sin estado con Bearer en cabecera? → CSRF no aporta: el navegador no adjunta
                                          cabeceras automáticamente
```

- **Desactivar CSRF en una API sin estado con Bearer es correcto** y es la configuración normal.
- **Desactivarlo en una aplicación con sesión por cookie es un agujero**, y es lo que pasa cuando
  alguien copia la línea `.csrf(csrf -> csrf.disable())` de un tutorial de API a una aplicación web.
- Matiz moderno: con `SameSite=Lax` o `Strict` en la cookie, gran parte del ataque se mitiga, pero
  no sustituye al token.

**CORS.** No protege nada del servidor: **relaja** la política del navegador para permitir que un
origen distinto llame a tu API. Es una autorización que tú concedes, no una defensa.

- `allowedOrigins("*")` junto con `allowCredentials(true)` es una combinación que los navegadores
  rechazan, y el intento de forzarla es la señal de que alguien no entendió el mecanismo.
- CORS no sustituye a la autenticación: un cliente que no sea un navegador ignora CORS por completo.

> **Veredicto:** CSRF protege al usuario de su propio navegador; CORS permite que otro origen te
> llame. Confundirlos produce el clásico "desactivé CSRF y CORS para que funcionara", que es
> renunciar a una defensa y abrir la otra.

---

## 6. 🧭 Cómo se elige

```text
¿Qué tipo de cliente?
    Navegador con sesión por cookie  → CSRF activo, SameSite, cadena con formulario
    API consumida por móvil o SPA con token → STATELESS, Bearer, CSRF desactivado
    Ambos en el mismo sistema        → DOS SecurityFilterChain con securityMatcher distinto

¿Dónde pongo las reglas?
    Por ruta y rol       → authorizeHttpRequests, de lo MÁS específico a lo más general
    Por objeto concreto  → @PreAuthorize en el servicio, o comprobación explícita en el dominio
    ¿Decide sobre el resultado? → @PostAuthorize, sabiendo que el método ya se ejecutó

¿Hay trabajo asíncrono?
    → DelegatingSecurityContextExecutorService. Nunca confíes en que el contexto viaje solo.

Y siempre:
    → anyRequest().authenticated() AL FINAL
    → un test por método sensible que verifique el 403
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Spring Security es anotaciones" | Es una cadena de filtros de servlet; las anotaciones son la segunda capa |
| "La ruta pública pide login" | Hay una regla más general antes; el orden se evalúa de arriba abajo |
| "En el `@Async` el usuario es null, es un bug" | El contexto es un `ThreadLocal`: hay que propagarlo |
| "`@PreAuthorize` no se aplica" | La llamada no pasó por el proxy: autoinvocación, `private` o `final` |
| "Desactivé CSRF para que funcionara" | Correcto en API sin estado; agujero en aplicación con cookie |
| "CORS protege la API" | CORS **relaja** la política del navegador; no defiende nada |
| "`@PostFilter` sobre el listado" | Filtra después de paginar: páginas incompletas |

---

## 📚 Para profundizar

- **Libro** — Laurentiu Spilca, *Spring Security in Action*, 2ª ed. (Manning, 2024). Capítulos 2 a
  9: la cadena de filtros, el contexto, la autorización por método y OAuth2. **Es el libro de este
  capítulo** y cubre la versión moderna sin `WebSecurityConfigurerAdapter`.
- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos 4 y 5: cómo encaja Spring Security en una arquitectura distribuida.
- **Libro** — Ross Anderson, *Security Engineering*, 3ª ed. (Wiley, 2020). Para el porqué de CSRF
  y del modelo de confianza del navegador.
- [Spring Security — Architecture](https://docs.spring.io/spring-security/reference/servlet/architecture.html):
  la cadena de filtros explicada por el proyecto, con el diagrama canónico.
- [Spring Security — Authorization Architecture](https://docs.spring.io/spring-security/reference/servlet/authorization/architecture.html):
  cómo se materializan las decisiones y dónde encaja `@PreAuthorize`.
- [Spring Security — Reference](https://docs.spring.io/spring-security/reference/index.html): el
  índice, para localizar CSRF, CORS y gestión de sesión.
- **Tutorial** — Baeldung, «Spring Security Filter Chain»: el recorrido filtro a filtro con
  ejemplos ejecutables.
- **Video** — Spring I/O y Devoxx, charlas sobre la configuración moderna de Spring Security 6.
  Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué es la cadena de filtros de Spring Security? 🟢
2. ¿Dónde vive el `SecurityContext`? 🟢
3. ¿Qué diferencia hay entre `@PreAuthorize` y `@PostAuthorize`? 🟢
4. ¿Qué protege CSRF? 🟢
5. ¿Qué hace CORS? 🟢
6. ¿Por qué una ruta pública puede acabar pidiendo login? 🟡
7. ¿Por qué en un `@Async` el usuario aparece como null? 🟡
8. ¿Por qué `@PreAuthorize` no se aplica en una llamada interna? 🟡
9. ¿Para qué sirve `securityMatcher`? 🟡
10. ¿Qué hace `SessionCreationPolicy.STATELESS`? 🟡
11. ¿Cuándo es correcto desactivar CSRF? 🟡
12. ¿Por qué `SecurityContextPersistenceFilter` limpia el contexto al final? 🟠
13. ¿Cómo se propaga el contexto a un pool de hilos? 🟠
14. ¿Por qué `MODE_INHERITABLETHREADLOCAL` falla con pools reutilizados? 🟠
15. ¿Qué peligro tiene `@PostAuthorize`? 🟠
16. ¿Por qué `@PostFilter` sobre un listado paginado es un error? 🟠
17. ¿Por qué `ExceptionTranslationFilter` va antes que `AuthorizationFilter`? 🟠
18. ¿Cuándo tendrías dos `SecurityFilterChain` y cómo las separas? 🟠
19. ¿Por qué una autorización que no se aplica es peor que una que falla? 🟠
20. ¿Qué problema tiene copiar `.csrf().disable()` de un tutorial de API? 🟠
21. Diseña la configuración de un sistema con API para móvil y consola de
    administración web en el mismo despliegue. 🔴
22. Un endpoint con `@PreAuthorize` deja pasar a usuarios sin permiso. Da tres
    hipótesis en orden y di cómo las confirmas. 🔴
23. Tras migrar a virtual threads, ¿qué cambia y qué no en la propagación del
    contexto de seguridad? Justifica. 🔴

---

**Anterior:** [`01` — Autenticación, autorización y amenazas](01-autenticacion-autorizacion-y-amenazas.md) ·
**Siguiente:** [`03` — OAuth2, OIDC y JWT](03-oauth2-oidc-y-jwt.md) ·
**Relacionado:** [`01-bases/04` — Patrones GoF](../01-bases/04-patrones-gof.md)
