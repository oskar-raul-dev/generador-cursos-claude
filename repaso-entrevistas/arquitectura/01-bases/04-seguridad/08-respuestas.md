# 08 — Respuestas

> Solucionario centralizado del bloque `04-seguridad`. Cada respuesta en tres capas:
> **⏱️ 30 segundos**, **🗣️ 2 minutos** y **🔬 El detalle**. Los enunciados están copiados
> literalmente de su capítulo.
>
> **Vigencia:** 2026-09-18.

**Salto rápido:**
[01](#01--autenticación-autorización-y-amenazas) · [02](#02--spring-security-por-dentro) ·
[03](#03--oauth2-oidc-y-jwt) · [04](#04--propagación-de-identidad-entre-servicios) ·
[05](#05--mtls-zero-trust-y-service-mesh) · [06](#06--secretos-y-criptografía) ·
[07 — escenarios](#07--simulación-escenarios-de-diseño)

---

# 01 — Autenticación, autorización y amenazas

**01 → 1. ¿Qué diferencia hay entre autenticación y autorización?**

⏱️ La autenticación responde quién eres; la autorización, qué puedes hacer.
🗣️ La autenticación ocurre una vez, al entrar, y produce una credencial. La autorización ocurre en
**cada operación**, porque la respuesta depende del recurso concreto y puede cambiar a mitad de
sesión.
🔬 De esa asimetría sale todo el bloque: meter los permisos en el token los congela hasta que
caduque, y por eso revocar se vuelve imposible.

**01 → 2. ¿Qué son RBAC, ABAC y ReBAC?**

⏱️ Autorización por roles, por atributos y por relaciones.
🗣️ RBAC: el usuario tiene roles y los roles permisos. ABAC: la decisión se calcula con atributos del
sujeto, del recurso y del contexto. ReBAC: el permiso deriva de tu relación con el recurso —eres el
dueño, el gestor de esa cuenta—.
🔬 RBAC es el valor por defecto y explota cuando aparecen condiciones contextuales. ABAC las
resuelve y hace difícil auditar quién puede ver qué. ReBAC es lo que muchos dominios piden de
verdad y lo que RBAC simula con roles artificiales.

**01 → 3. ¿Qué son PEP y PDP?**

⏱️ El punto donde se **aplica** la decisión y el punto donde se **toma**.
🗣️ El PEP intercepta y deja pasar o no; el PDP evalúa la política y responde sí o no. Se completan
con el PIP, de donde salen los datos que la decisión necesita, y el PAP, donde se gestionan las
políticas.
🔬 Es vocabulario de XACML que se usa aunque no uses XACML, y sirve para razonar dónde vive cada
cosa: el gateway puede ser PEP y el servicio también, con un PDP externo compartido.

**01 → 4. ¿Cuáles son los tres factores de autenticación?**

⏱️ Algo que sabes, algo que tienes y algo que eres.
🗣️ Contraseña o PIN; móvil, llave física o tarjeta; huella o cara. Doble factor es combinar dos
**categorías distintas**, no dos elementos de la misma.
🔬 El SMS como segundo factor está desaconsejado por el intercambio de SIM; TOTP es aceptable y las
llaves WebAuthn/FIDO2 son superiores porque además resisten el phishing al estar ligadas al dominio.

**01 → 5. ¿Cuál es el primer puesto del OWASP Top 10?**

⏱️ Broken Access Control: el sistema no comprueba si este usuario puede ver **este** objeto.
🗣️ Su forma canónica es el IDOR: cambiar el identificador en la URL y acceder al recurso de otro. Es
el más frecuente y el más aburrido, y sigue siendo el primero precisamente porque depende de que
alguien escriba la comprobación en cada sitio.
🔬 Es el mismo fallo que la fuga entre tenants de
[`03-datos/08`](../03-datos/08-poliglota-y-multi-tenant.md), y se defiende igual: la comprobación no
puede depender de la disciplina.

**01 → 6. ¿Qué es un IDOR?**

⏱️ *Insecure Direct Object Reference*: acceder al recurso de otro cambiando su identificador.
🗣️ `/pedidos/771` → `/pedidos/772` y ves el pedido de otro cliente. El sistema autenticó
correctamente y no comprobó si ese usuario tenía relación con ese objeto.
🔬 La defensa no es ocultar el identificador —usar UUID lo hace más difícil de adivinar, no
imposible—: es comprobar la relación en el servidor, y hacerlo de forma que no se pueda olvidar
(filtro por propietario en la consulta, o política del motor).

**01 → 7. ¿Por qué contraseña más pregunta secreta no es doble factor?**

⏱️ Porque las dos son "algo que sabes": es un solo factor repetido.
🗣️ El doble factor existe para que comprometer un canal no baste. Si ambos elementos se obtienen de
la misma forma —phishing, filtración, ingeniería social—, no añaden una barrera independiente.
🔬 Y las preguntas secretas son especialmente débiles: sus respuestas suelen ser públicas o
adivinables, y no se pueden rotar. Están desaconsejadas incluso como mecanismo de recuperación.

**01 → 8. ¿Qué es la explosión de roles y cuándo aparece?**

⏱️ La multiplicación de roles cuando aparecen condiciones contextuales que RBAC no puede expresar.
🗣️ Empieza con `ANALISTA` y a los dos años hay `ANALISTA_SUCURSAL_MADRID`,
`ANALISTA_SENIOR_RIESGO_LIMITE_ALTO` y cuatrocientos más que nadie puede auditar ni retirar con
seguridad.
🔬 Aparece en cuanto el permiso deja de depender solo de quién eres. La salida es RBAC más atributos
para los pocos casos que lo necesitan, no migrar todo a ABAC, que hace imposible la pregunta de
auditoría más frecuente.

**01 → 9. ¿Qué significa "fallo cerrado"?**

⏱️ Que ante un error al evaluar la política, se **deniega**. Nunca se permite.
🗣️ Si el PDP no responde, si la consulta de permisos falla o si el token no se puede validar, la
respuesta es 403. Un error transitorio no puede convertirse en un acceso concedido.
🔬 Es el principio que más se incumple, y la forma concreta es un `catch` que devuelve `true` "para
no romper el flujo". Ese `catch` convierte una caída del PDP en un agujero abierto durante toda la
caída, sin que ninguna alerta lo diga.

**01 → 10. ¿Qué es SSRF y por qué es grave en microservicios?**

⏱️ El servidor hace una petición a una URL que controla el atacante y alcanza recursos internos.
🗣️ Grave porque en una arquitectura interna donde los servicios se confían, el atacante consigue que
un servicio legítimo llame por él a cualquier cosa de dentro: un servicio no expuesto, un panel de
administración, el endpoint de metadatos de la nube.
🔬 Ese último es el caso crítico: el endpoint de metadatos devuelve credenciales de la
infraestructura, y con ellas el atacante deja de necesitar la aplicación. Bloquear su acceso desde
los contenedores es una de las medidas con mejor relación coste/beneficio que existen.

**01 → 11. ¿Por qué la autenticación se delega a un proveedor de identidad?**

⏱️ Porque es un subdominio genérico: se compra, no se construye.
🗣️ La gestión de contraseñas, la recuperación, el doble factor, la federación, la rotación de
tokens y el cumplimiento normativo asociado son un producto entero. Construirlo gasta presupuesto
del núcleo en algo que Keycloak o Cognito hacen mejor, y añade superficie de ataque.
🔬 Además centraliza lo que debe estar centralizado: si mañana hay que exigir doble factor a todos,
se configura en un sitio en vez de desplegar catorce servicios. Lo que sí es trabajo tuyo es cómo se
propaga esa identidad hacia dentro.

**01 → 12. ¿Qué es la separación de deberes y por qué importa en banca?**

⏱️ Que quien aprueba una operación no sea quien la ejecuta. En banca no es buena práctica, es
exigencia regulatoria.
🗣️ Impide que una sola persona complete un circuito completo —crear un beneficiario y transferirle
dinero, por ejemplo—, que es el patrón del fraude interno.
🔬 Condiciona el diseño: el modelo de datos tiene que registrar quién aprobó, el de autorización
tiene que poder expresar "no puedes aprobar lo que tú creaste", y el flujo tiene que tener un estado
de "pendiente de aprobación" que no se pueda saltar.

**01 → 13. ¿Por qué el gateway no puede decidir la autorización fina?**

⏱️ Porque no conoce el recurso: solo ve la ruta, el método y los claims del token.
🗣️ Puede decidir "este rol puede llamar a `GET /cuentas/{id}`", y no puede decidir si **este
usuario** tiene relación con **esa cuenta**, porque esa información está en el dominio del servicio.
🔬 De ahí la regla: filtro grueso en el borde, decisión fina en el servicio. Y además es defensa en
profundidad: si el servicio confía en que "alguien delante ya validó", basta una ruta interna
expuesta por error para saltarse todo el control.

**01 → 14. ¿Qué pregunta decide entre RBAC y ABAC?**

⏱️ ¿El permiso depende solo de quién eres, o también del recurso concreto y del contexto?
🗣️ Si depende solo de quién eres, RBAC basta y es auditable. Si aparece "solo los de su sucursal",
"solo por debajo de cierto importe" o "solo en horario laboral", RBAC va a intentar expresarlo con
roles y va a explotar.
🔬 La respuesta madura no es elegir uno: es RBAC como base más atributos para los casos que lo
exigen. Eso conserva la auditabilidad —"¿quién tiene el rol GESTOR?" sigue teniendo respuesta— y
cubre lo contextual sin crear roles.

**01 → 15. ¿Por qué ABAC puro desde el día uno es sobre-ingeniería?**

⏱️ Porque paga expresividad que no necesitas y destruye la auditabilidad desde el principio.
🗣️ Con ABAC, la pregunta "¿quién puede ver este expediente?" deja de tener una respuesta consultable
y pasa a requerir evaluar la política contra todos los usuarios posibles. En un dominio auditado,
eso es un problema real.
🔬 Y depurar por qué alguien no tiene acceso se vuelve un ejercicio de evaluar expresiones. La ruta
sana es empezar por RBAC, medir dónde duele, y añadir atributos solo ahí — que además es reversible,
mientras que rediseñar la autorización entera no lo es.

**01 → 16. ¿Qué problema tiene un `catch` que devuelve `true` al fallar el PDP?**

⏱️ Convierte un error transitorio en un acceso concedido, durante todo el tiempo que dure el error.
🗣️ Es el incumplimiento de "fallo cerrado" en su forma más común, y se escribe con buena intención:
para que una caída del servicio de permisos no tumbe la aplicación. El resultado es que la caída
deja de ser visible y pasa a ser un agujero silencioso.
🔬 Lo correcto es devolver 403 y alertar, aceptando que la aplicación se degrada. Si eso es
inaceptable para el negocio, la salida es una caché de decisiones con TTL corto que permita seguir
decidiendo con datos recientes — no permitir a ciegas.

**01 → 17. ¿Cuándo usarías un PDP externo y qué cuesta?**

⏱️ Con muchos servicios y necesidad de política auditable en un sitio. Cuesta un salto más y un
punto crítico.
🗣️ Con doce servicios, tener la política de autorización escrita en doce sitios garantiza que
diverjan. Un PDP con políticas declarativas —OPA, Cedar— centraliza la escritura y la auditoría, y
cada servicio sigue siendo el PEP.
🔬 El coste: latencia por decisión, mitigable evaluando la política **localmente** con el motor
embebido y distribuyendo solo las políticas —que es como se usa OPA en la práctica—. Y el diseño
tiene que resolver de dónde salen los datos que la decisión necesita: si el PDP tiene que consultar
el dominio, la latencia se multiplica.

**01 → 18. ¿Por qué un permiso temporal sin caducidad no era temporal?**

⏱️ Porque nadie lo va a retirar: la retirada depende de que alguien se acuerde.
🗣️ Los permisos concedidos "para esta migración" o "mientras dure el incidente" se quedan. A los dos
años, el inventario de permisos no refleja quién necesita qué, y el principio de mínimo privilegio
existe solo en la documentación.
🔬 La solución es estructural: que la concesión lleve fecha de fin obligatoria y que el sistema la
aplique. Y una revisión periódica de accesos —recertificación— que en banca suele ser obligatoria y
que es la única forma de limpiar lo acumulado.

**01 → 19. ¿Qué es la confusión de deputado entre servicios?**

⏱️ Que un servicio con muchos permisos ejecute, en nombre de un usuario, algo que ese usuario no
podía hacer.
🗣️ `Pagos` puede consultar cualquier expediente en `Riesgo`. Un usuario sin permiso llama a `Pagos`,
`Pagos` no comprueba si ese usuario podía, y consulta con su propia credencial. `Riesgo` responde
porque confía en `Pagos`. El usuario obtuvo datos que no le correspondían.
🔬 El fallo no está en `Riesgo`: está en que `Pagos` actúa con sus permisos sin verificar los del
usuario en cuyo nombre actúa. Se resuelve llevando la identidad del usuario hasta el final, que es
[`04`](#04--propagación-de-identidad-entre-servicios).

**01 → 20. ¿Por qué la comprobación de acceso a objeto no puede depender de la disciplina del desarrollador?**

⏱️ Porque basta un olvido para una fuga, y el olvido no produce ningún error: simplemente deja
pasar.
🗣️ Una consulta nueva escrita con prisa, un informe de administración, una corrección manual, un
endpoint interno que alguien expuso. Ninguno falla ruidosamente: devuelven datos. Y los tests
normales no lo detectan porque prueban el camino feliz con un usuario que sí tiene permiso.
🔬 Las defensas estructurales: filtrar por propietario en el propio repositorio, de modo que la
consulta sin filtro no exista; Row-Level Security en el motor; y tests que verifiquen explícitamente
el 403 con un usuario que no debería poder. La regla general del bloque: cuando el modo de fallo es
silencioso, la defensa tiene que ser automática.

**01 → 21. Diseña el modelo de autorización de una banca en línea: consultar cuentas propias, operar, y que un gestor vea las de sus clientes.**

⏱️ RBAC como base para las capacidades, más comprobación de relación en el servicio para el objeto
concreto.
🗣️ El diseño:

```text
ROLES (capacidad, en el token):  CLIENTE · GESTOR · SUPERVISOR
SCOPES (de la app):              cuentas:leer · cuentas:operar

DECISIÓN, en el servicio de Cuentas:
  CLIENTE   → puede leer/operar SI cuenta.titular == token.sub
  GESTOR    → puede leer        SI cuenta.titular ∈ cartera(gestor)   ← relación, no rol
  SUPERVISOR→ puede leer        SI cuenta.sucursal == gestor.sucursal ← atributo
  Operar por encima de X importe → requiere segundo aprobador (separación de deberes)
```

🔬 Lo que hace buena esta respuesta. **El rol no basta**: `GESTOR` dice que puede gestionar, no
**qué** cuentas; la relación gestor–cliente es un dato del dominio y la comprobación vive en el
servicio de `Cuentas`. **La cartera del gestor no va en el token**: cambia, y meterla la congela
hasta la caducidad; se consulta. **El importe es un atributo**, y es el ejemplo de por qué RBAC solo
no llega. Y **la separación de deberes** por encima de cierto importe es requisito regulatorio, no
una opción: obliga a un estado "pendiente de aprobación" y a registrar quién aprobó. Añadiría que
toda consulta de un gestor sobre una cuenta ajena se registra en el log de auditoría con el motivo,
que es lo que exige el supervisor bancario.

**01 → 22. Un usuario cambió `/pedidos/771` por `/pedidos/772` y vio el de otro. Describe la investigación y las medidas, inmediatas y de fondo.**

⏱️ Es Broken Access Control en su forma IDOR. Contener, medir el alcance, corregir, y después
estructurar la defensa.
🗣️ La investigación: reproducir el caso; revisar los logs de acceso de ese endpoint para determinar
cuántas peticiones accedieron a pedidos que no eran del solicitante y desde qué cuentas —esa es la
cifra que negocio y legal van a pedir—; y revisar si el mismo patrón existe en otros endpoints, que
casi siempre sí, porque el fallo es de método y no de un sitio.
🔬 Medidas inmediatas: añadir la comprobación de propiedad y desplegar; si el alcance es amplio,
valorar desactivar el endpoint mientras tanto. Medidas de fondo, que son las que evitan la
repetición: que el repositorio **no exponga** una consulta por id sin propietario —`porIdYTitular`
en vez de `porId`—, de modo que escribir el fallo requiera esfuerzo; tests de autorización por
endpoint que verifiquen el 403; revisión de todos los endpoints que reciben un identificador; y, si
aplica, Row-Level Security. Y fuera de lo técnico: notificación a los clientes afectados y, según la
naturaleza del dato, a la autoridad de protección de datos en el plazo legal.

**01 → 23. Te piden "asegurar" un sistema de 12 microservicios que hoy confían entre sí. ¿Por dónde empiezas y en qué orden?**

⏱️ Por el inventario y el modelo de amenazas, luego por lo que más radio de daño reduce por menos
coste: autorización en el servicio y secretos fuera del código.
🗣️ El orden que propondría:

```text
0. Inventario: qué servicios hay, qué datos toca cada uno, qué llama a qué, qué está expuesto.
   Sin esto no se puede priorizar y la mayoría de los equipos no lo tiene.
1. Secretos fuera del código y rotados.       Barato, alto impacto, sin cambiar arquitectura.
2. Autorización de objeto EN CADA SERVICIO.   Es el fallo nº1 del OWASP y hoy no existe.
3. Validación completa del token en cada servicio (las seis, incluida aud).
4. Identidad de servicio: mTLS o Client Credentials. Aquí se acaba la confianza implícita.
5. Segmentación: qué puede llamar a qué. Acota el radio de daño.
6. Token exchange o dos identidades, si el dominio lo justifica.
7. Auditoría: sub y act en cada registro, log inmutable aparte.
```

🔬 Por qué ese orden y no otro. Los pasos 1 y 2 son los que más riesgo quitan por menos esfuerzo y no
requieren coordinación entre equipos. El 4 es el que más cambia la arquitectura y el que más
resistencia genera, así que va después de haber demostrado valor. Y el 0 no es burocracia: sin saber
qué servicio maneja datos regulados, la priorización es una opinión. Lo que **no** haría es empezar
por instalar una malla: es la medida más visible y no ataca el fallo más probable, que es la
autorización ausente dentro de cada servicio. Y mediría el avance con algo verificable: porcentaje
de endpoints con test de autorización, y número de secretos que quedan en el código.

---

# 02 — Spring Security por dentro

**02 → 1. ¿Qué es la cadena de filtros de Spring Security?**

⏱️ Una secuencia ordenada de filtros de servlet que procesan la petición antes de llegar al
controlador.
🗣️ Spring Security se registra como un solo filtro —`DelegatingFilterProxy`— que delega en un
`FilterChainProxy`, y este elige la `SecurityFilterChain` que corresponde a la ruta. Dentro, cada
filtro tiene una responsabilidad: cargar el contexto, validar CSRF, autenticar, traducir
excepciones, autorizar.
🔬 Un filtro que no llama a `chain.doFilter` corta la petición ahí: eso es lo que produce un 401. Y
puede haber varias cadenas, una por patrón de rutas, que es cómo conviven una API sin estado y una
consola web con sesión.

**02 → 2. ¿Dónde vive el `SecurityContext`?**

⏱️ En un `ThreadLocal`, atado al hilo que atiende la petición.
🗣️ `SecurityContextHolder` lo expone estáticamente, y dentro está el `Authentication` con el
principal y las autoridades. Por eso no hace falta pasar el usuario como parámetro por todas las
capas.
🔬 Y por eso **no se propaga solo** a otros hilos: en un `@Async` o en un pool propio, el contexto
está vacío. `SecurityContextPersistenceFilter` lo carga al principio y lo **limpia al final**, lo
cual es esencial: si no, el siguiente uso de ese hilo del pool heredaría la identidad anterior.

**02 → 3. ¿Qué diferencia hay entre `@PreAuthorize` y `@PostAuthorize`?**

⏱️ `@PreAuthorize` evalúa antes de ejecutar; `@PostAuthorize`, después, sobre el objeto devuelto.
🗣️ `@PreAuthorize` es lo que quieres casi siempre. `@PostAuthorize` sirve cuando la decisión depende
del contenido del resultado —"solo si eres el titular de la cuenta devuelta"—.
🔬 El peligro de `@PostAuthorize` es que **el método ya se ejecutó**: si tenía efectos secundarios,
ocurrieron aunque la autorización falle. Solo es seguro en métodos de consulta puros.

**02 → 4. ¿Qué protege CSRF?**

⏱️ Contra que otro sitio haga que tu navegador envíe una petición autenticada con tus cookies.
🗣️ El navegador adjunta las cookies automáticamente a cualquier petición hacia ese dominio, venga de
donde venga. El token CSRF, que el atacante no puede leer por la política del mismo origen, rompe el
ataque.
🔬 Es relevante cuando hay cookies de sesión. En una API sin estado con Bearer en cabecera no aporta,
porque el navegador no adjunta cabeceras automáticamente. `SameSite=Lax` mitiga buena parte del
ataque pero no sustituye al token.

**02 → 5. ¿Qué hace CORS?**

⏱️ **Relaja** la política del navegador para permitir que un origen distinto llame a tu API. No
protege nada.
🗣️ Es una autorización que tú concedes, no una defensa. El navegador pregunta al servidor si ese
origen puede leer la respuesta, y el servidor contesta con cabeceras.
🔬 Y no sustituye a la autenticación: un cliente que no sea un navegador —curl, un script, un
servidor— ignora CORS por completo. Confundirlo con una medida de seguridad produce el clásico
"desactivé CSRF y abrí CORS para que funcionara".

**02 → 6. ¿Por qué una ruta pública puede acabar pidiendo login?**

⏱️ Porque hay una regla más general colocada antes: se evalúan de arriba abajo y gana la primera que
coincide.
🗣️ Si `anyRequest().authenticated()` está antes que `requestMatchers("/publico/**").permitAll()`,
la primera captura todo y la segunda nunca se evalúa. Es el fallo de configuración número uno.
🔬 La regla: de lo **más específico a lo más general**, y `anyRequest()` siempre al final. Y si hay
varias `SecurityFilterChain`, comprobar también que el `securityMatcher` de cada una no se solape,
porque la primera cadena que coincide es la que atiende.

**02 → 7. ¿Por qué en un `@Async` el usuario aparece como null?**

⏱️ Porque el `SecurityContext` vive en un `ThreadLocal` y el hilo del pool no lo tiene.
🗣️ No es un bug: es cómo funciona. La identidad se cargó en el hilo de la petición y el `@Async`
ejecuta en otro hilo distinto, que nunca la recibió.
🔬 Se resuelve envolviendo el ejecutor con `DelegatingSecurityContextExecutorService`, que propaga el
contexto **por tarea**. La estrategia `MODE_INHERITABLETHREADLOCAL` funciona con hilos creados
directamente y falla con pools reutilizados, porque el hilo ya existía cuando se heredó.

**02 → 8. ¿Por qué `@PreAuthorize` no se aplica en una llamada interna?**

⏱️ Porque funciona por proxy, y `this.metodo()` llama directamente a la instancia sin pasar por él.
🗣️ Es exactamente el mismo mecanismo que `@Transactional` de
[`01-bases/04`](../01-bases/04-patrones-gof.md): Spring envuelve el bean en un proxy que intercepta
las llamadas que llegan desde fuera. Dentro de la clase, `this` es el objeto sin envolver.
🔬 Tampoco se aplica en métodos `private` ni —con proxies CGLIB— en `final`, ni en clases que no son
beans. Y el modo de fallo es silencioso: no lanza, simplemente deja pasar.

**02 → 9. ¿Para qué sirve `securityMatcher`?**

⏱️ Limita a qué rutas aplica esa `SecurityFilterChain` entera.
🗣️ Permite tener varias cadenas con configuraciones incompatibles: `/api/**` sin estado con Bearer y
CSRF desactivado, y `/admin/**` con sesión, formulario y CSRF activo, en el mismo despliegue.
🔬 Sin él, la cadena intenta atender todo, y la primera cadena que coincide es la que gana — así que
el **orden de los beans** también importa y se controla con `@Order`.

**02 → 10. ¿Qué hace `SessionCreationPolicy.STATELESS`?**

⏱️ No crea ni consulta sesión HTTP: el contexto se reconstruye del token en cada petición.
🗣️ Es lo correcto en una API consumida por móvil o por una SPA con token: no hay cookie de sesión,
no hay estado en el servidor, y cualquier instancia puede atender cualquier petición.
🔬 Y tiene consecuencia con CSRF: sin cookie de sesión, el ataque que CSRF previene no aplica, por
eso desactivarlo ahí es correcto. También implica que no puedes guardar nada en la sesión, lo que en
un sistema que escala horizontalmente es una ventaja y no una limitación.

**02 → 11. ¿Cuándo es correcto desactivar CSRF?**

⏱️ En una API sin estado donde la credencial viaja en una cabecera, no en una cookie.
🗣️ Si el token va en `Authorization: Bearer`, el navegador no lo adjunta automáticamente a
peticiones de otros orígenes, así que no hay nada que falsificar. Desactivarlo ahí es la
configuración normal y correcta.
🔬 Y es un agujero en cuanto haya cookies de sesión, que es lo que pasa cuando alguien copia esa
línea de un tutorial de API a una aplicación web con formulario. La pregunta que lo decide siempre
es: **¿el navegador adjunta la credencial automáticamente?**

**02 → 12. ¿Por qué `SecurityContextPersistenceFilter` limpia el contexto al final?**

⏱️ Porque el hilo vuelve al pool, y si no se limpiara, la siguiente petición heredaría esa
identidad.
🗣️ Los contenedores de servlets reutilizan hilos. Un `ThreadLocal` no limpiado es estado que
sobrevive entre peticiones de usuarios distintos, y el resultado sería que alguien opera con la
identidad de otro.
🔬 Es exactamente el mismo fallo que la conexión del pool que hereda el tenant de la petición
anterior en [`03-datos/08`](../03-datos/08-poliglota-y-multi-tenant.md). Es un patrón de error
recurrente: **todo estado atado al hilo debe limpiarse al devolverlo**.

**02 → 13. ¿Cómo se propaga el contexto a un pool de hilos?**

⏱️ Envolviendo el ejecutor con `DelegatingSecurityContextExecutorService`, que copia el contexto por
tarea.
🗣️ El envoltorio captura el contexto en el momento de enviar la tarea y lo establece en el hilo que
la ejecuta, limpiándolo al terminar. Funciona con cualquier pool, incluidos los reutilizados.
🔬 La alternativa `MODE_INHERITABLETHREADLOCAL` es global y frágil: hereda en el momento de **crear**
el hilo, así que con un pool que ya existe no hereda nada. Y al ser global, afecta a todo el
proceso. La delegación del ejecutor es explícita, local y correcta.

**02 → 14. ¿Por qué `MODE_INHERITABLETHREADLOCAL` falla con pools reutilizados?**

⏱️ Porque la herencia ocurre al crear el hilo, y los hilos del pool se crearon antes de la petición.
🗣️ `InheritableThreadLocal` copia el valor del hilo padre al hijo **en el momento de la creación**.
Un pool crea sus hilos al arrancar o bajo demanda, y a partir de ahí los reutiliza: la tarea que
envías se ejecuta en un hilo que ya existía y que heredó lo que hubiera entonces, que suele ser nada
—o, peor, el contexto de otra petición—.
🔬 Ese "peor" es el problema real: no solo falla, puede dar la identidad equivocada. Por eso la
recomendación es siempre la delegación del ejecutor.

**02 → 15. ¿Qué peligro tiene `@PostAuthorize`?**

⏱️ Que el método ya se ejecutó cuando se evalúa: si tenía efectos secundarios, ocurrieron.
🗣️ Si el método transfiere dinero y `@PostAuthorize` deniega, la transferencia ya se hizo y solo se
impide que el resultado se devuelva. La anotación protege la respuesta, no la ejecución.
🔬 Por eso solo es seguro en consultas puras. Y tiene un segundo coste: para decidir, necesita el
objeto completo, así que no puede evitar el trabajo de cargarlo. Cuando se usa sobre listados con
`@PostFilter`, además filtra después de paginar y deja páginas incompletas.

**02 → 16. ¿Por qué `@PostFilter` sobre un listado paginado es un error?**

⏱️ Porque filtra después de que la base de datos haya paginado: las páginas quedan incompletas y el
total es incorrecto.
🗣️ Pides 20 elementos, la consulta devuelve 20, `@PostFilter` elimina 7 por permisos y el usuario ve
13 en una página que dice tener 20. Y el número total de páginas está calculado sobre datos sin
filtrar.
🔬 La solución correcta es filtrar **en la consulta**: que el repositorio solo devuelva lo que el
usuario puede ver, con un `WHERE` por propietario o con Row-Level Security. Eso además es más
eficiente y elimina la posibilidad de olvidarlo.

**02 → 17. ¿Por qué `ExceptionTranslationFilter` va antes que `AuthorizationFilter`?**

⏱️ Porque tiene que estar envolviendo a quien lanza la excepción para poder capturarla y traducirla.
🗣️ `AuthorizationFilter` lanza `AccessDeniedException` cuando deniega. Si el traductor estuviera
después, esa excepción ya habría salido de la cadena y llegaría al contenedor como un error 500 con
traza.
🔬 Gracias a ese orden, un acceso denegado produce un 403 con cuerpo controlado, y una petición sin
autenticar dispara el `AuthenticationEntryPoint` —que redirige al formulario o devuelve 401 según la
cadena—. Es un ejemplo de que el orden de los filtros no es arbitrario: es una relación de
envoltura.

**02 → 18. ¿Cuándo tendrías dos `SecurityFilterChain` y cómo las separas?**

⏱️ Cuando conviven clientes con modelos de sesión incompatibles. Se separan con `securityMatcher` y
se ordenan con `@Order`.
🗣️ El caso típico: una API para móvil sin estado con Bearer y CSRF desactivado, y una consola de
administración web con sesión, formulario y CSRF activo. Son configuraciones contradictorias y no
caben en una sola cadena.
🔬 El detalle operativo: la **primera cadena cuyo matcher coincide** es la que atiende, así que el
orden importa y una cadena sin `securityMatcher` captura todo. Se pone la más específica primero y
la general al final, igual que las reglas dentro de una cadena.

**02 → 19. ¿Por qué una autorización que no se aplica es peor que una que falla?**

⏱️ Porque no produce ningún error: simplemente deja pasar, y nadie se entera.
🗣️ Una autorización que falla genera un 403, alguien lo reporta y se investiga. Una que no se aplica
—por autoinvocación, por `private`, porque falta `@EnableMethodSecurity`— produce respuestas
correctas para usuarios que no debían tenerlas, y los tests del camino feliz pasan.
🔬 De ahí la defensa: un test por método sensible que verifique explícitamente que un usuario sin
permiso recibe 403. Es el equivalente en seguridad a la regla general del corpus: **cuando el modo
de fallo es silencioso, la verificación tiene que ser automática**.

**02 → 20. ¿Qué problema tiene copiar `.csrf().disable()` de un tutorial de API?**

⏱️ Que en una aplicación con sesión por cookie desactiva una defensa real.
🗣️ En la API del tutorial era correcto porque la credencial viajaba en cabecera. En una aplicación
web con formulario y cookie de sesión, el navegador adjunta la credencial automáticamente, y sin
token CSRF cualquier sitio puede hacer que tu navegador ejecute operaciones en tu nombre.
🔬 Es el ejemplo canónico de configuración copiada sin entender el modelo de amenazas. La pregunta
que hay que hacerse siempre antes de desactivarlo: **¿el navegador adjunta la credencial solo?** Si
sí, CSRF hace falta.

**02 → 21. Diseña la configuración de un sistema con API para móvil y consola de administración web en el mismo despliegue.**

⏱️ Dos `SecurityFilterChain` separadas por `securityMatcher`, ordenadas, con modelos de sesión y
CSRF opuestos.
🗣️ El diseño:

```java
@Bean @Order(1)
SecurityFilterChain api(HttpSecurity http) {
    return http.securityMatcher("/api/**")
        .csrf(c -> c.disable())                      // sin cookie: no aplica
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .authorizeHttpRequests(a -> a
            .requestMatchers("/api/publico/**").permitAll()
            .anyRequest().authenticated())
        .oauth2ResourceServer(o -> o.jwt(withDefaults()))
        .build();
}

@Bean @Order(2)
SecurityFilterChain admin(HttpSecurity http) {       // sin matcher: captura el resto
    return http
        .csrf(withDefaults())                        // CON cookie: CSRF obligatorio
        .sessionManagement(s -> s.sessionCreationPolicy(IF_REQUIRED))
        .authorizeHttpRequests(a -> a
            .requestMatchers("/admin/**").hasRole("ADMIN")
            .anyRequest().authenticated())
        .formLogin(withDefaults())
        .build();
}
```

🔬 Detalles que el entrevistador buscará. El **orden** importa: la cadena de API va primero y la
general al final, porque la primera que coincide atiende. **CSRF opuesto en cada una**, y la razón
es la misma pregunta: ¿el navegador adjunta la credencial sola? **La cookie de administración** debe
llevar `HttpOnly`, `Secure` y `SameSite=Lax`, que es defensa en profundidad sobre el propio CSRF. Y
añadiría dos cosas: la sesión de administración con caducidad corta y expiración por inactividad,
porque un panel de administración abierto es un riesgo distinto al de una app móvil; y la
autorización de objeto en el servicio, que ninguna de las dos cadenas puede resolver.

**02 → 22. Un endpoint con `@PreAuthorize` deja pasar a usuarios sin permiso. Da tres hipótesis en orden y di cómo las confirmas.**

⏱️ Falta `@EnableMethodSecurity`; la llamada es interna y no pasa por el proxy; o la expresión
evalúa a verdadero por un error en ella.
🗣️ Primera y más probable: la seguridad de métodos **no viene activada por defecto**, y sin
`@EnableMethodSecurity` las anotaciones se ignoran en silencio en toda la aplicación. Segunda: el
método se llama desde otro método de la misma clase, o es `private`, o la clase no es un bean. Tercera:
la expresión SpEL está mal y siempre da verdadero — por ejemplo, un `hasRole('ADMIN')` con el prefijo
`ROLE_` duplicado o un `or` que cortocircuita.
🔬 Cómo las confirmo en ese orden: busco `@EnableMethodSecurity` en la configuración y compruebo si
**ninguna** anotación funciona, que es la firma de la primera; miro quién llama al método y si el bean
está proxiado; y pongo un log de la expresión evaluada o la sustituyo temporalmente por `denyAll()`
para ver si al menos se intercepta. Una cuarta hipótesis menos común: hay un `permitAll()` en la
cadena de filtros que hace que la petición ni siquiera llegue autenticada, y entonces la expresión se
evalúa sobre un principal anónimo de forma inesperada.

**02 → 23. Tras migrar a virtual threads, ¿qué cambia y qué no en la propagación del contexto de seguridad? Justifica.**

⏱️ El `ThreadLocal` sigue funcionando igual. Lo que desaparece es el problema del **pool
reutilizado**, porque cada tarea tiene su propio hilo.
🗣️ Los virtual threads soportan `ThreadLocal` con la misma semántica, así que
`SecurityContextHolder` sigue funcionando sin cambios en el camino normal de la petición. Y como no
se agrupan —se crea uno por tarea y se descarta—, desaparece el riesgo de que un hilo herede el
contexto de la petición anterior.
🔬 Lo que **no** cambia: un hilo virtual nuevo lanzado dentro de la petición sigue sin recibir el
contexto automáticamente, así que la delegación del ejecutor sigue haciendo falta si lanzas trabajo
concurrente. Y aparece un matiz nuevo: con muchísimos hilos virtuales, un `ThreadLocal` con un objeto
pesado se multiplica en memoria, lo que es uno de los motivos por los que existen los *scoped
values* —diseñados precisamente para propagar contexto inmutable a tareas hijas de forma eficiente—.
Como respuesta de arquitectura, diría que virtual threads elimina un modo de fallo y no elimina la
necesidad de ser explícito al propagar identidad.

---

# 03 — OAuth2, OIDC y JWT

**03 → 1. ¿Qué es OAuth2, qué es OIDC y qué es JWT?**

⏱️ Un marco de delegación de autorización, una capa de identidad encima, y un formato de token.
🗣️ OAuth2 responde "¿puede esta aplicación hacer esto en tu nombre?". OIDC añade el ID token y
responde "¿quién eres?". JWT es un JSON firmado: ni autentica ni autoriza, transporta.
🔬 Se combinan de todas las formas: OAuth2 con tokens opacos sin JWT, JWT sin OAuth2, OIDC con ID
token en JWT y access token opaco. Separar las tres capas en voz alta es media respuesta.

**03 → 2. Nombra los cuatro actores de OAuth2.**

⏱️ Resource owner, client, authorization server y resource server.
🗣️ El dueño de los datos —el usuario—, la aplicación que quiere acceder, quien emite los tokens, y
la API que los valida y guarda los datos.
🔬 El "client" es la aplicación, no el usuario, y confundirlos es lo que lleva a tratar los scopes
como permisos de usuario: el scope dice qué puede intentar la app, no qué puede ver esta persona.

**03 → 3. ¿Qué diferencia hay entre access token y refresh token?**

⏱️ El de acceso es corto y viaja en cada petición; el de refresco es largo y solo va al servidor de
autorización.
🗣️ El de acceso dura minutos, así que si se filtra el daño está acotado. El de refresco dura días o
meses y sirve para obtener accesos nuevos sin volver a autenticar, por lo que su filtración es mucho
más grave.
🔬 Por eso el de refresco se **rota**: cada uso emite uno nuevo e invalida el anterior, de modo que
un uso duplicado delata el robo y permite invalidar la familia entera.

**03 → 4. ¿Qué partes tiene un JWT?**

⏱️ Cabecera, cuerpo y firma, en Base64 y separadas por puntos.
🗣️ La cabecera lleva el algoritmo y el `kid` de la clave; el cuerpo, los claims; la firma permite
verificar que nadie lo modificó.
🔬 Está **firmado, no cifrado**: cualquiera puede decodificar el cuerpo y leerlo. Meter datos
personales o secretos en un JWT es publicarlos, y es un hallazgo frecuente en auditoría.

**03 → 5. ¿Qué flujo es el recomendado hoy para aplicaciones con usuario?**

⏱️ Authorization Code con PKCE, sea web, SPA o móvil.
🗣️ El servidor devuelve un código al cliente, no un token; el cliente lo canjea por los tokens
presentando el verificador que solo él conoce. El código viaja por el navegador y los tokens no.
🔬 El estándar actual (RFC 9700) lo declara como el único recomendado y exige PKCE incluso cuando
hay secreto de cliente. Implicit y el flujo de contraseña están retirados.

**03 → 6. ¿Qué es PKCE y qué problema resuelve?**

⏱️ Un secreto efímero que hace que un código de autorización interceptado no sirva de nada.
🗣️ El cliente genera un valor aleatorio, envía su hash al iniciar el flujo, y al canjear el código
presenta el valor original. Quien intercepte el código no tiene ese valor y no puede canjearlo.
🔬 Nació para aplicaciones móviles, donde el redirect podía ser capturado por otra app registrada
para el mismo esquema de URL. Hoy se exige también en web, porque protege contra la inyección de
código de autorización con o sin secreto de cliente.

**03 → 7. ¿Qué diferencia hay entre ID token y access token?**

⏱️ El ID token es para el cliente y dice quién eres; el access token es para la API y dice qué puede
hacer el portador.
🗣️ El ID token siempre es un JWT y su `aud` es el cliente. El access token puede ser opaco, y su
`aud` es la API.
🔬 Mandar el ID token a la API es un error real y frecuente: el servicio estaría aceptando un token
que no iba dirigido a él, lo que significa que no está validando `aud`. Si lo valida, lo rechaza —y
ese rechazo es la señal de que la validación funciona—.

**03 → 8. ¿Por qué un JWT no debe llevar datos sensibles?**

⏱️ Porque está firmado, no cifrado: cualquiera con el token lee su contenido.
🗣️ El token pasa por el navegador, por los logs de los proxies, por el almacenamiento del cliente y
a veces por sistemas de terceros. Todo lo que lleve dentro es visible en todos esos sitios.
🔬 Existe JWE para cifrar el contenido, pero añade complejidad y no resuelve que el token siga siendo
una credencial. La regla práctica: el token lleva identificadores y capacidades, y los datos se
consultan donde viven.

**03 → 9. ¿Para qué sirve el claim `kid`?**

⏱️ Identifica con qué clave se firmó el token, para poder validar cuando hay varias.
🗣️ El validador consulta el JWKS del emisor, busca la clave con ese `kid` y verifica la firma. Es lo
que permite **rotar claves sin romper los tokens en vuelo**: durante la transición conviven la
antigua y la nueva.
🔬 El JWKS se cachea con un TTL razonable y se recarga cuando aparece un `kid` desconocido. No
hacerlo significa una llamada al emisor por petición; hacerlo sin recarga significa que la rotación
rompe el servicio.

**03 → 10. ¿Por qué `sub` y no el email como identificador?**

⏱️ Porque `sub` es estable y único, y el email cambia y se reutiliza.
🗣️ Un usuario puede cambiar de correo, y una organización puede reasignar una dirección a otra
persona cuando alguien se va. Si usaste el email como clave, el nuevo titular hereda los datos del
anterior.
🔬 `sub` es único **dentro del emisor**, así que la clave real es la combinación `iss` + `sub`. En
sistemas con varios proveedores de identidad, usar solo `sub` puede producir colisiones.

**03 → 11. ¿Cuándo se usa Client Credentials?**

⏱️ En comunicación de máquina a máquina, sin usuario involucrado.
🗣️ Un trabajo por lotes que llama a una API, un servicio que consulta a otro por su cuenta. El
cliente se autentica con su propia credencial y recibe un token que representa a la **aplicación**,
no a una persona.
🔬 Es también la forma de dar identidad de servicio cuando no hay mTLS, y encaja con la primera de
las dos identidades de [`04`](#04--propagación-de-identidad-entre-servicios). Lo que no debe hacerse
es usarlo para actuar en nombre de un usuario: eso es token exchange.

**03 → 12. ¿Qué es la introspección de token?**

⏱️ Preguntar al servidor de autorización si un token sigue siendo válido y qué contiene.
🗣️ Es lo que hace posible el token opaco: el recurso no puede validarlo por sí mismo, así que
consulta. Y como consulta, la revocación es inmediata.
🔬 Su precio es una llamada por petición, mitigable con una caché de corta duración —que reintroduce
una ventana de revocación, ahora acotada y conocida—. Es el punto medio entre JWT autocontenido y
revocación inmediata.

**03 → 13. ¿Qué seis cosas se validan en un JWT?**

⏱️ Firma, `exp`, `nbf`, `iss`, `aud` y el algoritmo contra una lista blanca.
🗣️ La firma con la clave pública del emisor obtenida del JWKS; que no esté caducado ni sea
prematuro; que lo emitiera quien esperas; que estuviera dirigido a ti; y que el algoritmo sea el que
esperabas, no el que dice la cabecera.
🔬 La del algoritmo existe por un ataque real: `alg: none`, o cambiar RS256 por HS256 usando la clave
pública como secreto HMAC. Las librerías modernas lo bloquean, pero la validación explícita del
algoritmo esperado sigue siendo lo correcto.

**03 → 14. ¿Por qué validar `aud` es crítico?**

⏱️ Porque sin ella tu servicio acepta tokens emitidos para otra API del mismo proveedor.
🗣️ Si el emisor da tokens a diez APIs distintas y tu servicio solo comprueba la firma y la
caducidad, cualquier token válido de cualquiera de las diez entra. Un cliente con permiso para una
API de bajo riesgo puede usar su token contra la API crítica.
🔬 Es el vector de escalada entre servicios más directo que existe, y no deja rastro: el token es
legítimo y la firma correcta. Además es lo que hace que propagar el mismo token por toda la cadena
pierda el acotamiento: o el `aud` es genérico —y no acota— o hay que emitir uno por destino.

**03 → 15. ¿Por qué Implicit está obsoleto?**

⏱️ Porque devolvía el token de acceso en la URL, donde queda registrado en muchos sitios.
🗣️ En el historial del navegador, en los logs del servidor y de los proxies, en la cabecera
`Referer` al navegar a otra página. Un token en una URL es una credencial en los logs de media
infraestructura.
🔬 Existía porque las SPA no podían guardar un secreto de cliente y no había forma segura de canjear
un código. PKCE resolvió exactamente eso, así que Authorization Code + PKCE lo sustituye sin perder
nada.

**03 → 16. ¿Por qué el flujo password se retiró de la especificación?**

⏱️ Porque obliga a la aplicación a manejar la contraseña del usuario, que es justo lo que OAuth2
venía a evitar.
🗣️ Y tiene consecuencias prácticas: es incompatible con doble factor, con federación y con cualquier
flujo de autenticación que requiera interacción. Además entrena al usuario a escribir su contraseña
en pantallas de terceros, que es el patrón del phishing.
🔬 Se usaba por comodidad en aplicaciones propias, y la alternativa correcta es Authorization Code +
PKCE incluso ahí: el navegador embebido o la pestaña del sistema llevan al usuario al proveedor, y la
aplicación nunca ve la contraseña.

**03 → 17. ¿Por qué en un sistema distribuido se firma con clave asimétrica?**

⏱️ Porque con HMAC, todo el que puede validar también puede **emitir** tokens.
🗣️ Con HS256 hay un secreto compartido entre el emisor y todos los validadores. Cualquier servicio
comprometido —o cualquier desarrollador con acceso a la configuración— puede fabricar un token
válido para cualquier usuario y cualquier rol.
🔬 Con RS256 o ES256, los servicios solo tienen la clave **pública**: pueden verificar y no pueden
firmar. Y además permite rotar la clave privada en el emisor sin tocar a los validadores, que la
descubren por el JWKS.

**03 → 18. ¿Qué es el ataque de confusión de algoritmo?**

⏱️ Cambiar el algoritmo declarado en la cabecera para que el validador use la clave equivocada.
🗣️ Las dos variantes: `alg: none`, donde el token no lleva firma y un validador ingenuo lo acepta; y
cambiar RS256 por HS256, de modo que el validador use la **clave pública** —que es pública— como
secreto HMAC, permitiendo al atacante firmar sus propios tokens.
🔬 Las librerías modernas lo bloquean por defecto, pero la defensa correcta sigue siendo configurar
el algoritmo esperado y rechazar cualquier otro, en vez de confiar en lo que dice la cabecera del
token que estás validando.

**03 → 19. ¿Por qué "con JWT revocamos al instante" es contradictorio?**

⏱️ Porque el valor del JWT es validarse sin preguntar a nadie, y revocar exige que alguien pregunte.
🗣️ Un JWT autocontenido es válido hasta que caduca: el emisor no tiene forma de retirarlo porque
ningún validador lo consulta. Si añades introspección o lista de revocación, ya has reintroducido
estado y una dependencia, y la validación deja de ser autónoma.
🔬 Lo que sí se puede decir con precisión: *"caducidad de cinco minutos más refresco rotativo, así
que la revocación real ocurre al denegar el refresco y la ventana máxima es de cinco minutos"*. Eso
es honesto y a menudo suficiente. Reconocer el compromiso es lo que se evalúa.

**03 → 20. ¿Qué diferencia hay entre un scope y un permiso sobre un objeto?**

⏱️ El scope es un permiso de la **aplicación**; el permiso sobre el objeto es de dominio y lo decide
tu servicio.
🗣️ `scope: pagos:leer` dice que esta app puede intentar leer pagos. No dice que **este usuario**
pueda leer **ese** pago concreto. Confundirlos produce sistemas donde cualquiera con el scope accede
a cualquier objeto.
🔬 Es el mismo error que confiar en el gateway: el token acota la capacidad, y la relación con el
recurso la comprueba quien la conoce. Un token con `scope: pagos:leer` y una comprobación de
titularidad ausente es exactamente un IDOR.

**03 → 21. Diseña la revocación de sesiones para una banca donde despedir a un empleado debe cortarle el acceso en segundos.**

⏱️ Access token de vida muy corta —30 a 60 segundos— con introspección cacheada, o tokens opacos con
introspección directa. Y desactivación en el proveedor de identidad como fuente de verdad.
🗣️ El diseño:

```text
Fuente de verdad → el proveedor de identidad. Desactivar al empleado es UNA acción.
Access token     → 60 s de vida. La ventana máxima de acceso indebido es 60 s.
Refresh token    → al renovar, el proveedor comprueba el estado y deniega. Aquí muere la sesión.
Introspección    → en los servicios críticos, con caché de 10 s. Ventana de 10 s.
Sesiones web     → invalidación por back-channel logout del proveedor a las aplicaciones.
```

🔬 El compromiso que declaro: la vida corta multiplica las llamadas de refresco contra el proveedor,
que pasa a estar en el camino crítico y necesita alta disponibilidad. La introspección añade latencia
por petición, acotada por la caché. Y hay una tercera vía que mencionaría: una **marca de versión de
sesión** en el token comparada contra un valor por usuario en una caché compartida —revocar es
incrementar el número—, que da revocación en el tiempo de propagación de la caché y cuesta una
consulta rápida en vez de una llamada al proveedor. Lo que **no** propondría es una lista de tokens
revocados: crece sin límite y hay que consultarla igualmente. Y añadiría lo no técnico: el
procedimiento de baja debe incluir la desactivación en el proveedor como primer paso y con
verificación, porque de nada sirve el diseño si la baja tarda dos días en tramitarse.

**03 → 22. Un servicio acepta tokens emitidos para otra API del mismo proveedor. Diagnostica y explica el impacto.**

⏱️ No está validando `aud`. El impacto es escalada horizontal: cualquier token válido del proveedor
sirve contra este servicio.
🗣️ El diagnóstico es directo: el servicio comprueba firma, emisor y caducidad —todo correcto— y omite
el público. Como todos los tokens los firma el mismo proveedor, todos pasan. Se confirma pidiendo un
token para otra API y probándolo contra este servicio.
🔬 El impacto real depende de quién puede obtener tokens del proveedor. Si hay una aplicación pública
de bajo riesgo —un portal de consulta, una app de marketing— cuyo token sirve contra la API de
pagos, la barrera entre ambas desapareció. Y es especialmente grave porque **no deja rastro
anómalo**: el token es legítimo, la firma correcta, y los logs muestran una petición normal. Las
medidas: validar `aud` de inmediato en todos los servicios, no solo en este; revisar los logs para
estimar si ocurrió; y como medida de fondo, emitir tokens con `aud` específico por API —o token
exchange— en vez de un público genérico, para que la validación tenga algo que comprobar.

**03 → 23. Te piden migrar de flujo Implicit a Authorization Code + PKCE en una SPA con 40.000 usuarios activos. ¿Cómo lo haces sin cortar el servicio?**

⏱️ Los dos flujos conviven en el proveedor: despliego la SPA nueva con PKCE, migro por porcentaje, y
retiro Implicit cuando el uso llegue a cero.
🗣️ La secuencia:

```text
1. Habilitar Authorization Code + PKCE en el cliente del proveedor, SIN quitar Implicit.
2. Registrar las URI de redirección nuevas si cambian.
3. Desplegar la SPA con el flujo nuevo detrás de un feature flag, al 5 % de usuarios.
4. Medir: tasa de inicio de sesión correcto, errores de canje, tiempo hasta el primer token.
5. Subir por escalones hasta el 100 %, con vuelta atrás disponible en cada uno.
6. Medir el uso residual de Implicit en el proveedor. Cuando sea cero durante X días, deshabilitarlo.
```

🔬 Lo que hay que vigilar y que suele sorprender. **El almacenamiento del token cambia de
importancia**: con PKCE sigues teniendo el token en el navegador, así que la mejora es en el
transporte, no en el almacenamiento — y conviene aprovechar la migración para evaluar el patrón de
*backend for frontend*, donde el token vive en el servidor y el navegador solo tiene una cookie
`HttpOnly`. **Las sesiones en vuelo**: los usuarios con token vigente del flujo viejo lo siguen
teniendo hasta que caduque, así que no hay corte, pero el conteo de "uso residual" debe incluir los
refrescos. **Los clientes móviles o integraciones** que usen el mismo cliente del proveedor: hay que
inventariarlos antes, porque deshabilitar Implicit los rompería. Y mediría el avance por **porcentaje
de inicios de sesión por el flujo nuevo**, no por porcentaje de código desplegado.

---

# 04 — Propagación de identidad entre servicios

**04 → 1. ¿Cuáles son las tres estrategias de propagación de identidad?**

⏱️ Confianza implícita, propagar el token del usuario, y token exchange con identidad de servicio
aparte.
🗣️ La primera no propaga nada y confía en la red. La segunda pasa el mismo token por toda la cadena.
La tercera cambia el token por otro acotado en cada salto y separa la identidad del servicio de la
del usuario.
🔬 Las tres son legítimas en contextos distintos; lo que no es aceptable es elegir la primera sin
saber que un servicio comprometido hereda toda la identidad del usuario.

**04 → 2. ¿Qué es la confusión de deputado?**

⏱️ Que un servicio con muchos permisos ejecute, en nombre de un usuario, algo que ese usuario no
podía hacer.
🗣️ El servicio actúa con **su** credencial sin comprobar los permisos de quien se lo pidió, y el
destino responde porque confía en el servicio. El usuario obtiene datos o acciones que no le
correspondían.
🔬 El fallo no está en quien responde: está en el intermediario que no verificó. Se resuelve
llevando la identidad del usuario hasta el final, para que cada servicio pueda comprobar por sí
mismo en vez de confiar.

**04 → 3. ¿Qué es el token exchange?**

⏱️ Cambiar un token por otro acotado a un destino concreto y con menos permisos (RFC 8693).
🗣️ El servicio presenta el token que recibió al servidor de autorización y obtiene uno nuevo con
`aud` del siguiente destino, el scope reducido a lo necesario, el `sub` del usuario original y un
claim `act` que registra quién actúa.
🔬 Si el destino se compromete, lo que tiene solo sirve para lo que ese destino podía hacer. Es la
respuesta correcta al problema de propagar el mismo token, y casi nadie la nombra en entrevista.

**04 → 4. ¿Qué dos identidades hay en una llamada entre servicios?**

⏱️ La del servicio que llama y la del usuario en cuyo nombre actúa.
🗣️ La primera responde "¿tengo derecho a hablar con este servicio?" y se resuelve con mTLS o Client
Credentials. La segunda responde "¿en nombre de quién?" y viaja en el token del usuario.
🔬 Sirven para cosas distintas: la del servicio autoriza la **llamada**; la del usuario autoriza la
**operación sobre el objeto**. Un sistema que solo comprueba una tiene un agujero, y es la
combinación la que hace real la defensa en profundidad.

**04 → 5. ¿Qué claim registra que un servicio actúa en nombre del usuario?**

⏱️ El claim `act` (actor), definido en el RFC 8693.
🗣️ Lleva la identidad del servicio que está actuando, mientras `sub` sigue siendo el usuario
original. Permite a la vez trazabilidad y políticas del tipo "este usuario puede, pero no a través
de ese servicio".
🔬 Es también lo que distingue **delegación** de **suplantación**: con `act`, el destino sabe que
hay un intermediario; sin él, no puede distinguir una llamada directa del usuario de una hecha por
un servicio en su nombre.

**04 → 6. ¿Por qué "están en la red interna" no es una garantía?**

⏱️ Porque un solo componente comprometido o un SSRF atraviesan esa frontera.
🗣️ La red interna asume que todo lo que está dentro es legítimo. Basta un contenedor vulnerable, un
servicio expuesto por error en un despliegue, o una petición que un atacante consigue que un servicio
haga por él, para que esa suposición deje de valer.
🔬 Es el principio que zero-trust niega explícitamente: la ubicación en la red no otorga confianza.
Y es el equivalente en seguridad de `@Transactional`: parece una garantía y no lo es.

**04 → 7. ¿Qué se pierde con la confianza implícita entre servicios?**

⏱️ La trazabilidad y la posibilidad de autorizar sobre el objeto.
🗣️ El servicio destino registra "llamada de Pagos" y no sabe quién la ordenó, así que ante una
auditoría no hay respuesta. Y como no sabe quién es el usuario, no puede comprobar si podía: su única
defensa es lo que el intermediario haya hecho.
🔬 Se pierde además el acotamiento del daño: quien comprometa cualquier servicio puede llamar a
todos los demás, porque nadie verifica quién llama. Las tres pérdidas son independientes y las tres
son graves.

**04 → 8. ¿Qué cuesta propagar el token del usuario tal cual?**

⏱️ Que el token vale en todas partes: un servicio comprometido hereda la identidad completa del
usuario.
🗣️ Y el `aud` deja de acotar: o el token se emite para un público genérico, y entonces no distingue
destinos, o hay que emitir uno por servicio, que ya es token exchange. Además el token crece con lo
que cada servicio quiere dentro, y viaja en cada salto.
🔬 Hay un cuarto coste que se olvida: si algún servicio llama a un tercero, propagar significaría
entregarle una credencial válida en todo tu sistema. Ese caso hay que cortarlo siempre,
independientemente de la estrategia general.

**04 → 9. ¿Por qué no se registra el token completo en los logs?**

⏱️ Porque es una credencial, y los logs se replican, se agregan y tienen acceso más amplio que la
aplicación.
🗣️ Un token en un log llega al sistema de observabilidad, a sus backups, y a todo el que tenga
permiso de consulta — que suele ser mucha más gente que la que tiene acceso a producción. Y sigue
siendo válido hasta que caduque.
🔬 Lo que sí se registra: `sub`, `act`, `jti` —el identificador del token— y el resultado de la
decisión. Con eso se reconstruye qué pasó sin exponer la credencial. Es uno de los hallazgos más
frecuentes en una auditoría real.

**04 → 10. ¿Qué diferencia hay entre el correlation ID y la identidad en el registro?**

⏱️ El correlation ID dice que los saltos pertenecen a la misma petición; no dice quién la ordenó.
🗣️ Sirve para reconstruir el recorrido técnico y es imprescindible para depurar. Pero ante la
pregunta de auditoría "¿quién ordenó esta transferencia?", un identificador de traza no responde:
hace falta el `sub` del usuario en cada registro relevante.
🔬 Se complementan: el correlation ID une los saltos, la identidad dice de quién eran, y el `act`
dice a través de qué sistema pasó. Los tres juntos son lo que permite responder a un supervisor.

**04 → 11. ¿Qué acota un token obtenido por token exchange?**

⏱️ El público (`aud`) y el alcance (`scope`): sirve solo para el destino previsto y solo para lo
necesario.
🗣️ Si `Pedidos` intercambia su token por uno para `Pagos` con `scope: pagos:cobrar`, ese token no
sirve contra `Riesgo` ni permite nada más que cobrar. Un compromiso de `Pagos` queda acotado a eso.
🔬 Y conserva la identidad del usuario en `sub` más el actor en `act`, así que el acotamiento no se
paga con pérdida de trazabilidad: se gana en las dos cosas a la vez.

**04 → 12. ¿Qué responde la identidad de servicio y qué responde la de usuario?**

⏱️ La de servicio, "¿tengo derecho a hablar contigo?"; la de usuario, "¿en nombre de quién actúo?".
🗣️ La primera autoriza la llamada y se comprueba en el transporte —mTLS— o con un token de Client
Credentials. La segunda autoriza la operación sobre el objeto concreto y se comprueba en el dominio.
🔬 La consecuencia práctica: aunque alguien robe un token de usuario, no puede usarlo sin ser un
servicio autorizado; y aunque comprometa un servicio, no puede actuar sin identidad de usuario
válida. Cada una cubre el fallo de la otra.

**04 → 13. ¿Por qué el token exchange pone al servidor de autorización en el camino crítico?**

⏱️ Porque cada salto necesita un intercambio, y si el servidor no responde, la cadena se detiene.
🗣️ Deja de ser un sistema que se usa al iniciar sesión y pasa a ser una dependencia de cada
petición. Su disponibilidad se convierte en el techo de la disponibilidad de todo el sistema, y su
latencia se suma a cada salto.
🔬 Se mitiga con una caché por combinación de sujeto, destino y alcance, con TTL corto — lo que
reintroduce una ventana en la que un permiso revocado sigue valiendo, acotada y conocida. Y obliga a
tratar el servidor de autorización como componente crítico: alta disponibilidad, monitorización y
plan de recuperación.

**04 → 14. ¿Por qué nunca se propaga el token del usuario a un tercero?**

⏱️ Porque le entregas una credencial que vale en todo tu sistema, a una organización que no
controlas.
🗣️ El proveedor externo podría usarla contra cualquier servicio tuyo que acepte ese token, durante
toda su vigencia. Y si el proveedor la registra en sus logs —que lo hará—, la credencial queda en un
sistema fuera de tu perímetro y de tu auditoría.
🔬 Lo correcto: una credencial propia para ese proveedor —la identidad de tu sistema ante él— y, si
el proveedor necesita saber en nombre de quién actúas, un identificador opaco acordado, no tu token.
Es la misma razón por la que no se reenvían cookies de sesión a un tercero.

**04 → 15. Narra la confusión de deputado con tres servicios concretos.**

⏱️ Un usuario sin permiso pide algo a `Pagos`; `Pagos` consulta `Riesgo` con su propia credencial;
`Riesgo` responde porque confía en `Pagos`; el usuario obtiene datos que no podía ver.
🗣️ La secuencia completa: `Riesgo` permite a `Pagos` consultar cualquier expediente, porque `Pagos`
es un servicio interno de confianza. Un usuario llama a un endpoint de `Pagos` pasando el
identificador de un expediente que no le corresponde. `Pagos` no comprueba si ese usuario tiene
relación con ese expediente: solo comprueba que está autenticado. Llama a `Riesgo` con su credencial
de servicio. `Riesgo` ve una petición legítima de `Pagos` y responde. `Pagos` devuelve el resultado
al usuario.
🔬 Lo que hace este ataque difícil de detectar: **todos los pasos son legítimos por separado**. El
usuario está autenticado, `Pagos` tiene permiso, `Riesgo` confía correctamente. El fallo es la
ausencia de una comprobación que nadie tenía asignada. Y la corrección no es quitarle permisos a
`Pagos` —los necesita para otros casos— sino que `Pagos` verifique la relación usuario–expediente, o
que la identidad del usuario llegue hasta `Riesgo` para que verifique él.

**04 → 16. ¿Cuándo es aceptable propagar el token tal cual?**

⏱️ En sistemas internos con pocos servicios, confianza homogénea, y ninguna llamada a terceros —y
declarando el riesgo.
🗣️ Si los cinco servicios los mantiene el mismo equipo, tienen el mismo nivel de exposición y
ninguno llama fuera, el acotamiento por destino añade maquinaria sin reducir mucho el riesgo real. Es
una decisión legítima.
🔬 Lo que la hace legítima es haberla tomado: saber que un compromiso de cualquiera de los cinco da
acceso a los otros cuatro en nombre del usuario, y aceptarlo porque el radio de daño es tolerable.
Lo que no es aceptable es llegar ahí por inercia. Y el disparador para cambiar: el primer servicio
que llame a un tercero, o el primero con un nivel de exposición distinto.

**04 → 17. ¿Por qué el `aud` deja de acotar si propagas el mismo token?**

⏱️ Porque para que valga en todos los servicios, su público tiene que ser genérico — y entonces no
distingue ninguno.
🗣️ Si emites el token con `aud: pagos`, no sirve para llamar a `Riesgo`. Para que la propagación
funcione, el `aud` debe ser algo como `aud: api-interna`, que todos aceptan. En ese momento la
validación de público sigue existiendo formalmente y ya no acota nada.
🔬 Es el argumento técnico contra la propagación directa, y es más preciso que decir "es menos
seguro": la comprobación que debía limitar el alcance se vuelve tautológica. La alternativa que
conserva el acotamiento es emitir un token por destino, que es exactamente el token exchange.

**04 → 18. ¿Qué debe poder responder el sistema ante una auditoría?**

⏱️ Quién ordenó la operación, a través de qué sistemas pasó, cuándo y desde dónde, y con qué
autorización.
🗣️ El `sub` del token de usuario registrado en cada salto responde la primera; el `act` y el
correlation ID, la segunda; la marca de tiempo, la IP y el dispositivo, la tercera; y qué política
permitió la decisión y con qué datos, la cuarta.
🔬 La cuarta es la que más se olvida y la que más pide un supervisor bancario: no basta con saber que
se permitió, hay que poder explicar **por qué**. Eso implica registrar la decisión de autorización,
no solo el resultado de la operación.

**04 → 19. ¿Por qué los logs de auditoría van a un almacén aparte?**

⏱️ Porque tienen retención regulatoria, requisitos de inmutabilidad y control de acceso distintos a
los de aplicación.
🗣️ Los logs de aplicación rotan en días o semanas y los borra cualquiera con permiso de operación.
Los de auditoría tienen que conservarse años, no poder alterarse, y su acceso está restringido y a su
vez auditado.
🔬 Mezclarlos produce dos fallos: o se pierde evidencia cuando la rotación normal la borra, o se
guardan años de logs de depuración por aplicar la retención regulatoria a todo, con su coste. Y
técnicamente el almacén de auditoría suele ser de solo-anexado, con firma o marca temporal, que es
justo lo que un almacén de logs normal no garantiza.

**04 → 20. ¿Cómo se mitiga el coste del token exchange?**

⏱️ Con una caché por combinación de sujeto, destino y alcance, con TTL corto.
🗣️ El mismo usuario llamando repetidamente al mismo destino con el mismo alcance no necesita un
intercambio por petición: se reutiliza el token mientras sea válido. Eso reduce las llamadas al
servidor de autorización en un par de órdenes de magnitud.
🔬 El precio es la ventana: un permiso revocado sigue valiendo hasta que el token cacheado caduque.
Se acota eligiendo un TTL corto —del orden de un minuto— y aceptándolo explícitamente. Y la caché
debe ser por instancia o distribuida con cuidado: un token cacheado en un sitio compartido es una
credencial compartida.

**04 → 21. Diseña la propagación de identidad de una cadena gateway → pedidos → pagos → proveedor externo de tarjetas. Justifica cada salto.**

⏱️ mTLS entre servicios internos, token del usuario intercambiado en cada salto, y una credencial
propia hacia el proveedor externo — nunca el token del usuario.
🗣️ Salto a salto:

```text
usuario → gateway
    Token OIDC del usuario, aud=gateway. El gateway valida las seis comprobaciones.
    Filtro grueso: autenticado, rol compatible con la ruta.

gateway → pedidos
    mTLS (identidad de servicio) + token intercambiado: aud=pedidos, scope acotado,
    sub=usuario, act=gateway.
    Pedidos valida token Y comprueba que ESE usuario es dueño de ESE pedido.

pedidos → pagos
    mTLS + token intercambiado: aud=pagos, scope=pagos:cobrar, sub=usuario, act=pedidos.
    Pagos comprueba por sí mismo, no confía en que Pedidos ya validó.

pagos → proveedor externo
    NUNCA el token del usuario. Credencial propia de la organización ante el proveedor:
    mTLS con certificado emitido por ellos, o Client Credentials con su servidor.
    Si el proveedor necesita identificar al cliente final, un identificador opaco acordado.
```

🔬 Lo que justifica cada decisión. El **intercambio en cada salto** acota el daño: un compromiso de
`Pagos` da un token que solo sirve para cobrar. El **mTLS** responde la otra pregunta —qué servicio
llama— y evita gestionar credenciales en el código. El **corte hacia el exterior** es innegociable:
entregar el token del usuario a un tercero le da acceso a todo tu sistema y deja la credencial en sus
logs. Y añadiría dos cosas: **atar el token al certificado** (RFC 8705) en el salto externo, que es
lo que exige Open Banking y hace que robar el token no baste; y registrar `sub` y `act` en cada
servicio, porque en banca la pregunta de auditoría "¿quién ordenó este cobro y a través de qué?"
tiene que tener respuesta.

**04 → 22. Un servicio interno consultó expedientes de clientes que el usuario no podía ver, sin que nadie lo detectara. Reconstruye el fallo y las medidas.**

⏱️ Es confusión de deputado: el servicio actuó con su credencial sin verificar los permisos del
usuario, y el destino confió en él.
🗣️ La reconstrucción: el servicio intermedio recibió una petición de un usuario autenticado, no
comprobó la relación entre ese usuario y el expediente solicitado, y consultó al servicio de
expedientes con su propia identidad de servicio. El destino vio una petición legítima de un servicio
autorizado y respondió. **Nada falló**: por eso no se detectó. Los logs del destino muestran "consulta
de servicio X", correcta; los del intermedio muestran una petición autenticada, correcta.
🔬 Medidas inmediatas: añadir en el servicio intermedio la comprobación de relación usuario–expediente
y desplegar; revisar los logs para estimar cuántas consultas fueron indebidas —lo que exige cruzar
las peticiones con la relación real, porque el log solo no lo dice, y esa dificultad es en sí un
hallazgo—. Medidas de fondo: **propagar la identidad del usuario hasta el servicio de expedientes**,
para que compruebe él y no dependa de la diligencia del intermedio; registrar `sub` y `act` en cada
salto, de modo que la próxima vez la investigación sea una consulta y no una reconstrucción; tests
de autorización que verifiquen el 403 con un usuario sin relación; y revisar si el mismo patrón
—servicio que consulta con su credencial sin verificar al usuario— existe en otros sitios, que casi
siempre sí.

**04 → 23. Te piden pasar de confianza implícita a identidad verificada en 12 servicios sin parar el negocio. ¿Cómo lo haces y en qué orden?**

⏱️ Introduzco la identidad **en modo permisivo** primero, mido, y solo después la hago obligatoria.
Servicio a servicio, empezando por los críticos.
🗣️ El plan:

```text
0. Inventario del grafo de llamadas: quién llama a quién y con qué frecuencia.
   Sin esto no se puede saber qué se va a romper.
1. Cada servicio EMPIEZA A ENVIAR la identidad (token propagado o mTLS), sin que nadie
   la exija todavía. Cero riesgo: nada cambia de comportamiento.
2. Cada servicio EMPIEZA A VALIDAR en modo permisivo: si falta o es inválida, lo REGISTRA
   y deja pasar. Esto revela los llamantes que nadie había inventariado — siempre hay.
3. Cuando el registro de fallos llegue a cero durante un periodo, se pasa a modo estricto
   en ESE servicio. Con feature flag para volver atrás.
4. Se repite servicio a servicio, empezando por los que tocan datos sensibles.
5. Al final, autorización de objeto en cada servicio, que es el paso que de verdad cierra
   el agujero — los anteriores solo establecen quién llama.
```

🔬 Por qué ese orden. El **modo permisivo** es la pieza clave: convierte una migración arriesgada en
una observación, y descubre los llamantes fantasma —un trabajo por lotes olvidado, un script de
soporte, un panel interno— que en modo estricto habrían producido una caída. La **separación entre
enviar y exigir** permite que los dos lados avancen sin coordinarse en el tiempo. Y empezar por los
servicios sensibles, no por los fáciles, porque el objetivo es reducir riesgo y no completar una
lista. Lo que mediría: número de llamadas sin identidad por servicio, que debe ir a cero antes de
cada corte. Y declararía que el paso 5 es el que realmente importa: verificar quién llama no impide
que un usuario legítimo acceda a un objeto ajeno.

---

# 05 — mTLS, zero-trust y service mesh

**05 → 1. ¿Qué es mTLS?**

⏱️ TLS mutuo: además de que el cliente verifique al servidor, el servidor verifica al cliente.
🗣️ En HTTPS normal solo una parte prueba quién es. Con mTLS ambas presentan certificado, así que el
destino sabe criptográficamente qué servicio le está llamando.
🔬 Eso da identidad de servicio sin credenciales en el código, cifrado en tránsito dentro del
clúster, y la posibilidad de autorizar por identidad en el transporte: "solo acepto llamadas de
`Pagos`".

**05 → 2. ¿Qué dice el modelo zero-trust?**

⏱️ Nunca confíes, verifica siempre: la ubicación en la red no otorga confianza.
🗣️ Sustituye al modelo de perímetro, donde el cortafuegos separaba fuera de dentro y todo lo de
dentro se confiaba. Sus principios: sin confianza implícita por ubicación, verificación en cada
petición, mínimo privilegio con caducidad, asumir la brecha, y registrarlo todo.
🔬 Es un modelo, no un producto. Su consecuencia práctica más importante es que **la red deja de ser
un control de seguridad** y pasa a ser solo transporte.

**05 → 3. ¿Qué es un service mesh y qué es el sidecar?**

⏱️ Una capa de infraestructura que intercepta el tráfico entre servicios mediante un proxy junto a
cada instancia.
🗣️ El sidecar es ese proxy. Todo el tráfico entra y sale por él, y un plano de control le distribuye
políticas, certificados y configuración. El código de la aplicación no cambia.
🔬 Lo que da: mTLS automático con rotación, autorización de nivel 7, observabilidad uniforme,
resiliencia y control de tráfico. Lo que cuesta: latencia por salto, consumo por instancia, y un
plano de control que es un componente crítico nuevo.

**05 → 4. Nombra tres cosas que da una malla sin escribir código.**

⏱️ mTLS automático, autorización de nivel 7, y observabilidad uniforme.
🗣️ Y dos más: resiliencia —timeouts, reintentos, circuit breaker en el proxy— y control de tráfico,
que permite canario, espejo y división por porcentaje sin tocar la aplicación.
🔬 Los tres últimos solapan con lo que ya haces en el código con Resilience4j y trazas. Su valor real
es la **uniformidad entre lenguajes**: si hay Java, Go y Python, la malla les da lo mismo a todos sin
mantener tres librerías.

**05 → 5. ¿Qué es la segmentación de red?**

⏱️ Limitar qué servicios pueden alcanzar a cuáles, para acotar el radio de daño de una brecha.
🗣️ Si `Notificaciones` solo necesita hablar con el broker, no debería poder alcanzar la base de datos
de `Cuentas`. Se implementa con políticas de red del orquestador y, a nivel 7, con políticas de
autorización de la malla.
🔬 La pregunta que mide si existe: *si el servicio menos crítico se compromete, ¿qué alcanza?* Si la
respuesta es "todo", no hay segmentación. No impide la brecha: acota su alcance.

**05 → 6. ¿Por qué una IP no es una identidad?**

⏱️ Porque es una ubicación, y en un orquestador cambia con cada despliegue.
🗣️ Además se puede suplantar dentro de la red, y no prueba nada criptográficamente: que una petición
venga de cierta IP no demuestra qué proceso la envió. Una lista de IP permitidas es una regla de
enrutamiento disfrazada de control de acceso.
🔬 La identidad es algo que se puede **probar**, y en una red eso significa criptografía: un
certificado cuya clave privada solo tiene ese servicio. De ahí mTLS.

**05 → 7. ¿Qué tres problemas resuelve mTLS que las alternativas no?**

⏱️ Identidad criptográfica sin credenciales compartidas, cifrado en tránsito interno, y autorización
por identidad en el transporte.
🗣️ Frente a una credencial en variable de entorno: no hay secreto que distribuir ni que acabe en un
log. Frente a una lista de IP: la identidad se prueba y no depende de la ubicación. Frente a la red
de confianza: cada conexión se verifica.
🔬 Y añade algo que las alternativas no dan: la rotación puede ser automática y frecuente, porque la
infraestructura emite los certificados. Eso convierte la revocación en "dejar de renovar", que es
mucho más fiable que cualquier lista de revocación.

**05 → 8. ¿Por qué los certificados de mTLS son de vida corta?**

⏱️ Porque la vida corta sustituye a la revocación, que en la práctica no funciona bien.
🗣️ Las listas de revocación y OCSP son incómodos: hay que distribuirlos, consultarlos y decidir qué
hacer si no responden. Con certificados de una hora, revocar es simplemente dejar de renovar, y el
acceso se corta solo.
🔬 Es el mismo razonamiento que la caducidad corta del JWT: se cambia un mecanismo de retirada
explícita, frágil, por una ventana acotada y conocida. Y solo es viable si la emisión está
automatizada, que es justo lo que la malla aporta.

**05 → 9. ¿Qué modelo sustituye zero-trust y por qué falló?**

⏱️ El de perímetro —castillo y foso—, y falló porque una sola brecha daba acceso lateral a todo.
🗣️ El modelo asumía una frontera clara entre fuera y dentro, con el cortafuegos como control
principal. Falló por dos razones: una vez dentro, no había más barreras; y con nube, trabajo remoto y
servicios gestionados, la frontera dejó de existir.
🔬 El movimiento lateral es el patrón de los incidentes grandes: el atacante entra por el punto más
débil —una estación de trabajo, un servicio secundario— y se mueve hacia los datos. Zero-trust ataca
exactamente eso exigiendo verificación en cada salto.

**05 → 10. ¿Qué es atar un token a un certificado y qué resuelve?**

⏱️ Ligar el access token al certificado del cliente, de modo que robarlo no baste: hay que robar
también la clave privada.
🗣️ El servidor de autorización incluye la huella del certificado en el token. El recurso comprueba
que el certificado de la conexión mTLS coincide. Un token filtrado en un log o en una traza es
inútil para quien no tenga ese certificado.
🔬 Está en el RFC 8705 y es lo que exige Open Banking en Europa, donde se combina con certificados
específicos del sector. Convierte un token de portador —cualquiera que lo tenga lo usa— en uno ligado
a una identidad probada.

**05 → 11. ¿Cuál es el coste concreto de un sidecar?**

⏱️ Latencia de un salto adicional en cada dirección, más CPU y memoria multiplicadas por el número
de instancias.
🗣️ Cada llamada pasa por dos proxies —el del origen y el del destino—, lo que añade del orden de un
milisegundo y consume recursos en cada pod. Con cien instancias, son cien proxies que dimensionar y
actualizar.
🔬 Y un coste que no se mide en recursos: **depurar con un sidecar en medio es notablemente más
difícil**, porque un fallo puede estar en la aplicación, en el proxy, o en la política que el plano
de control le distribuyó. Las alternativas sin sidecar reducen parte de esto y no todo.

**05 → 12. ¿Por qué el endpoint de metadatos de la nube es un objetivo?**

⏱️ Porque devuelve credenciales de la infraestructura a quien pueda alcanzarlo desde la instancia.
🗣️ Un SSRF que consiga que un servicio haga una petición a esa dirección obtiene las credenciales del
rol asociado a la instancia. Con ellas el atacante actúa directamente contra la nube y deja de
necesitar la aplicación.
🔬 Las defensas: exigir la versión del servicio de metadatos que requiere un token previo —que un SSRF
simple no puede obtener—, bloquear su acceso desde los contenedores que no lo necesiten, y dar a cada
carga el rol mínimo. Es una de las medidas con mejor relación coste/beneficio que existen en la nube.

**05 → 13. ¿Cuál es el coste real de mTLS, más allá del protocolo?**

⏱️ El ciclo de vida de los certificados: emisión, distribución, rotación y renovación automáticas.
🗣️ Hace falta una autoridad de certificación interna, un proceso que emita un certificado a cada
instancia antes de arrancar, y renovación sin intervención. Con certificados de vida corta, hacerlo a
mano es directamente inviable.
🔬 Y el coste de depuración: un fallo de handshake es opaco comparado con un 401, y diagnosticarlo
requiere saber leer cadenas de certificados y errores de TLS. Todo eso es lo que automatiza una
malla, y es su argumento principal — no la resiliencia.

**05 → 14. ¿Por qué "hacemos zero-trust" sin mecanismos es una mala respuesta?**

⏱️ Porque zero-trust es un modelo, no un producto: sin nombrar cómo se materializa, no dice nada.
🗣️ La respuesta útil enumera: identidad de servicio con mTLS, token de usuario validado en cada
salto, autorización por petición en cada servicio, mínimo privilegio con caducidad, segmentación, y
registro completo. Eso es zero-trust; lo demás es la etiqueta.
🔬 Y es una etiqueta que los proveedores venden, así que en entrevista funciona como filtro: quien la
usa sin poder desarrollarla la ha oído en un folleto. La frase que la aterriza: *"significa que este
servicio verifica quién llama y en nombre de quién, en cada petición, aunque venga de dentro"*.

**05 → 15. ¿Qué autoriza la malla y qué sigue autorizando el servicio?**

⏱️ La malla autoriza la **llamada**; el servicio autoriza la **operación sobre el objeto**.
🗣️ La malla puede decir "solo `Pagos` puede hacer `POST /riesgo/evaluar`". No puede decir si **este
usuario** podía pedir la evaluación de **ese** expediente, porque no conoce el dominio ni la relación
entre usuario y recurso.
🔬 Es exactamente la misma distinción que gateway contra servicio en
[`01`](#01--autenticación-autorización-y-amenazas), un nivel más abajo. Creer que instalar una malla
resuelve la autorización es el error que más caro sale, porque da una falsa sensación de cobertura.

**05 → 16. ¿Cuándo NO usarías un service mesh?**

⏱️ Con pocos servicios, un solo lenguaje, o sin un equipo de plataforma que la opere.
🗣️ Con cinco servicios Java, una librería compartida da resiliencia y trazas, y mTLS se puede
resolver en el ingreso más Client Credentials hacia dentro. La malla añadiría un plano de control
crítico, latencia y una curva de aprendizaje sin resolver nada que no esté resuelto.
🔬 El criterio que más pesa es el tercero: **una malla sin quien la opere es un riesgo, no una
mejora**. Un error en una política de autorización corta tráfico de producción, y diagnosticarlo
exige saber cómo funciona el proxy. Si no hay nadie que lo sepa, la malla empeora la fiabilidad.

**05 → 17. ¿Cuál es el argumento real de una malla si todo es Java?**

⏱️ mTLS automático y autorización de nivel 7 uniforme. La resiliencia y las trazas ya las tienes en
la librería.
🗣️ Con un solo lenguaje, Resilience4j da circuit breaker y reintentos, y Micrometer con OpenTelemetry
da trazas y métricas. Lo que la librería **no** da es emisión y rotación automática de certificados
ni políticas de autorización aplicadas fuera del código.
🔬 Así que el argumento se reduce a: ¿necesito mTLS y no quiero construir el ciclo de vida de los
certificados? Si la respuesta es sí y hay equipo de plataforma, la malla se justifica. Si no, hay
alternativas más baratas —cert-manager con TLS en la aplicación, o terminación en el ingreso— que
conviene valorar antes.

**05 → 18. ¿Cómo se sustituye la revocación de certificados en la práctica?**

⏱️ Con certificados de vida muy corta: revocar es dejar de renovar.
🗣️ Las listas de revocación hay que distribuirlas y consultarlas, y OCSP añade una dependencia en
el camino de la conexión con la pregunta incómoda de qué hacer si no responde —si se permite, la
revocación no vale; si se deniega, el respondedor es un punto único de fallo—.
🔬 Con certificados de una hora, el peor caso de un certificado comprometido es una hora de uso, sin
ningún mecanismo adicional. Es el mismo patrón que la caducidad corta del JWT y que las credenciales
dinámicas de Vault: **la vida corta sustituye a la retirada explícita**, y es un principio recurrente
en seguridad moderna.

**05 → 19. ¿Qué pregunta mide si tu segmentación existe?**

⏱️ Si el servicio menos crítico se compromete, ¿qué alcanza?
🗣️ Si la respuesta es "cualquier cosa de la red interna", no hay segmentación aunque haya
cortafuegos perimetral. Si es "el broker y su propia base de datos", la segmentación es real y el
radio de daño está acotado.
🔬 Es una pregunta que se puede responder objetivamente mirando las políticas de red y las de
autorización de la malla, y conviene hacérsela por cada servicio, no en general. Suele revelar que
los servicios auxiliares —notificaciones, informes, herramientas internas— tienen mucho más alcance
del que necesitan, y son precisamente los menos vigilados.

**05 → 20. ¿Por qué la red deja de ser un control de seguridad en zero-trust?**

⏱️ Porque el control pasa a ser la identidad verificada en cada petición, no la ubicación del
llamante.
🗣️ La red sigue siendo útil para acotar el radio de daño —segmentación— pero deja de ser el
mecanismo que decide si algo está permitido. Eso lo deciden la identidad del servicio, la del
usuario y la política, en cada salto.
🔬 La consecuencia práctica es importante y a menudo incómoda: **no puedes justificar la ausencia de
autenticación entre servicios con que están en la misma VPC**. Y al revés: estar fuera de la red
interna deja de ser descalificante, lo que es lo que permite trabajo remoto y servicios gestionados
sin VPN para todo.

**05 → 21. Diseña la identidad de servicio de una plataforma bancaria de 15 servicios en Kubernetes, con cifrado interno exigido por normativa.**

⏱️ mTLS con certificados de vida corta emitidos automáticamente, identidad por cuenta de servicio, y
políticas de autorización de nivel 7. Con malla si hay equipo de plataforma; con cert-manager si no.
🗣️ El diseño:

```text
Identidad     → una por servicio, ligada a la cuenta de servicio de Kubernetes.
                El nombre del servicio va en el SAN del certificado.
Emisión       → CA interna, certificados de 1 a 24 h, renovación automática.
                Con malla: la emite el plano de control. Sin malla: cert-manager.
Autorización  → política por destino: "riesgo acepta llamadas de pagos y originacion,
                solo en POST /evaluar". Aplicada en el proxy o en el ingreso del servicio.
Segmentación  → NetworkPolicy que limite el grafo de llamadas al inventario real.
Auditoría     → registro de cada conexión rechazada, que es la señal de un intento
                o de una configuración incompleta.
```

🔬 La decisión de malla o no. Con 15 servicios y normativa de cifrado interno, la malla se justifica
**si hay equipo de plataforma**: automatiza el ciclo de vida de los certificados, que es el coste
real. Si no lo hay, propondría cert-manager emitiendo certificados y TLS configurado en la aplicación
—más trabajo en el código y mucho menos que operar—, y revisaría la decisión cuando el equipo crezca.
Y en los dos casos declararía lo mismo: **esto establece quién llama, no qué puede hacer el usuario**.
La autorización de objeto sigue viviendo en cada servicio, y sin ella el cifrado interno satisface a
la normativa y no cierra el agujero más probable.

**05 → 22. Te proponen Istio para cinco servicios Java mantenidos por un equipo de seis personas. ¿Qué respondes y qué propones?**

⏱️ Que no, y propongo resolver los tres problemas reales por separado a un coste mucho menor.
🗣️ Pregunto primero qué quieren conseguir. Si es observabilidad, ya la tienen con Micrometer y
OpenTelemetry, y uniforme porque todo es Java. Si es resiliencia, Resilience4j da circuit breaker,
reintentos y bulkhead con más control que el proxy. Si es mTLS —que suele ser el motivo real—,
cert-manager emitiendo certificados y TLS en la aplicación lo resuelve sin plano de control.
🔬 Lo que argumentaría sobre el coste: Istio añade un proxy por instancia, un plano de control que es
componente crítico, una curva de aprendizaje considerable, y un modo de fallo nuevo donde una
política mal escrita corta tráfico de producción. Con seis personas no hay equipo de plataforma, así
que a las tres de la mañana nadie va a saber diagnosticar un error de sidecar. Y añadiría el
disparador para cambiar de opinión: si aparece un segundo lenguaje, o si el número de servicios se
duplica, la uniformidad empieza a compensar y volvemos a evaluarlo. Reconocería también que el equipo
quiere aprender Istio, que es legítimo, y propondría separarlo del producto.

**05 → 23. Un SSRF en un servicio permitió obtener credenciales de la infraestructura. Reconstruye el fallo y las medidas, inmediatas y de fondo.**

⏱️ El servicio hizo una petición a una URL controlada por el atacante, alcanzó el endpoint de
metadatos y devolvió las credenciales del rol de la instancia.
🗣️ La reconstrucción típica: un endpoint acepta una URL del usuario —una imagen para previsualizar,
un webhook para registrar, una importación desde una dirección— y el servicio la solicita sin
validar. El atacante apunta a la dirección de metadatos, el servicio la consulta desde dentro de la
instancia, y la respuesta —que incluye credenciales temporales del rol— vuelve al atacante.
🔬 Medidas inmediatas, en este orden: **rotar las credenciales comprometidas**, porque siguen siendo
válidas; revisar los registros de la nube para determinar qué se hizo con ellas y desde dónde, que es
lo que acota el incidente; y bloquear el endpoint vulnerable. Medidas de fondo: **exigir la versión
del servicio de metadatos que requiere un token previo**, que un SSRF simple no puede obtener;
**bloquear el acceso a la dirección de metadatos** desde los contenedores que no la necesiten;
**validar las URL de salida con lista blanca** de destinos permitidos, nunca con lista negra —que se
evade con redirecciones, DNS y representaciones alternativas de la dirección—; **reducir el rol de la
instancia** al mínimo, porque el impacto fue proporcional a lo que ese rol podía hacer; y salida a
través de un proxy que aplique la política, para que la defensa no dependa de cada llamada del
código. Y fuera de lo técnico: notificación según lo que esas credenciales pudieran alcanzar.

---

# 06 — Secretos y criptografía

**06 → 1. ¿Por qué un secreto en el código no es un secreto?**

⏱️ Porque lo ve todo el que clona el repositorio, queda en el historial, y rotarlo exige desplegar.
🗣️ Borrarlo del archivo no lo borra del historial de Git. Lo han visto contratistas y equipos que ya
no están. Y como rotarlo requiere un despliegue coordinado, en la práctica no se rota nunca.
🔬 La prueba definitiva: si rotar la credencial da miedo o requiere planificación, no hay gestión de
secretos. La medida del éxito no es que estén guardados, es que rotarlos sea rutina.

**06 → 2. ¿Con qué se hashean las contraseñas?**

⏱️ Con funciones lentas y con sal: Argon2id, scrypt o bcrypt.
🗣️ Son lentas **a propósito** y con coste ajustable, para que probar millones de candidatas sea
inviable. Argon2id es el recomendado hoy; bcrypt sigue siendo aceptable y es el valor por defecto de
Spring Security.
🔬 No se **cifran**: cifrar implica poder descifrar, y eso es exactamente lo que no se quiere. Si un
sistema puede mostrarte tu contraseña olvidada, está mal por definición.

**06 → 3. ¿Qué es la sal y para qué sirve?**

⏱️ Un valor aleatorio único por usuario que se añade antes de hashear.
🗣️ Evita que dos usuarios con la misma contraseña tengan el mismo hash, y hace inútiles las tablas
precomputadas: habría que construir una por cada sal. Se guarda junto al hash y **no es secreta**.
🔬 Las funciones modernas la generan y la incorporan al resultado automáticamente, así que no hay que
gestionarla a mano. Y se complementa con la pimienta, que sí es secreta y vive fuera de la base de
datos.

**06 → 4. ¿Qué es el sobre criptográfico?**

⏱️ Cifrar el dato con una clave de datos, y cifrar esa clave con una clave maestra que nunca sale del
módulo de seguridad.
🗣️ Se guardan juntos el dato cifrado y la clave de datos cifrada. Para descifrar, se pide al KMS que
descifre la clave de datos, y con ella se descifra el dato. La clave maestra nunca abandona el HSM.
🔬 Su ventaja operativa: rotar la clave maestra solo obliga a recifrar las claves de datos, que son
pequeñas, no los datos. Y es el mecanismo del crypto-shredding: destruir la clave de datos de un
sujeto deja sus datos ilegibles sin tocarlos.

**06 → 5. ¿Qué tres niveles de cifrado en reposo existen?**

⏱️ De disco o volumen, de base de datos, y campo a campo en la aplicación.
🗣️ El de disco protege contra el robo del disco o del snapshot. El de base de datos protege los
archivos y los backups. El de campo protege incluso del administrador de base de datos.
🔬 Protegen contra amenazas distintas, y por eso "ciframos en reposo" no dice nada sin decir a qué
nivel. La pregunta que distingue: ¿protege contra el robo físico, o contra alguien con credenciales
válidas de base de datos?

**06 → 6. ¿Por qué SHA-256 no sirve para contraseñas?**

⏱️ Porque es rápida por diseño: una GPU prueba miles de millones de candidatas por segundo.
🗣️ Está pensada para resumir datos con velocidad, que es exactamente lo contrario de lo que se
necesita aquí. Ante una filtración de la base de datos, las contraseñas comunes caen en minutos.
🔬 Las funciones para contraseñas son lentas y con coste configurable —iteraciones, memoria,
paralelismo— para que el atacante tenga que gastar recursos reales por cada intento. Argon2id además
exige memoria, lo que penaliza el hardware especializado.

**06 → 7. ¿Cómo están guardados los Secret de Kubernetes?**

⏱️ En base64, que es codificación y no cifrado, salvo que actives cifrado en reposo en etcd.
🗣️ Cualquiera con permiso de lectura sobre el espacio de nombres los ve en claro con un comando. Y
sin cifrado en reposo configurado, están en texto plano en el almacén de etcd y en sus backups.
🔬 Es mejor que el código, porque al menos no está en el repositorio y el acceso se puede controlar
con RBAC. Pero no equivale a un gestor dedicado: no hay rotación automática, ni registro de acceso, ni
credenciales dinámicas.

**06 → 8. ¿Qué diferencia hay entre sal y pimienta?**

⏱️ La sal es única por usuario y no secreta; la pimienta es común y secreta, y vive fuera de la base
de datos.
🗣️ La sal impide las tablas precomputadas. La pimienta añade una capa más: si se filtra la base de
datos pero no el gestor de secretos, los hashes siguen siendo inatacables porque falta un valor que
el atacante no tiene.
🔬 Su coste: rotar la pimienta invalida todos los hashes, así que hay que versionarla y rehashear
progresivamente al iniciar sesión. Por eso se usa menos que la sal, y su valor depende de que
realmente esté en otro sistema.

**06 → 9. ¿Qué son las credenciales dinámicas?**

⏱️ Credenciales creadas al vuelo, con TTL, distintas para cada consumidor.
🗣️ Vault puede crear un usuario de base de datos con permisos acotados y una hora de vida cuando una
instancia lo pide, y borrarlo al caducar. No hay contraseña compartida que filtrar porque cada
instancia tiene la suya.
🔬 Es la función más infravalorada de un gestor de secretos y la que mejor resuelve el problema:
elimina el secreto de larga duración en lugar de protegerlo mejor. Y da trazabilidad: cada conexión
a la base de datos se puede atribuir a una instancia concreta.

**06 → 10. ¿Qué es el problema del secreto cero y cómo se resuelve hoy?**

⏱️ Si la aplicación necesita una credencial para autenticarse contra el gestor de secretos, ¿dónde
vive esa? Se resuelve con la identidad de la plataforma.
🗣️ La cuenta de servicio de Kubernetes, el rol de la instancia en la nube, o el certificado emitido
por la infraestructura. Son identidades que la plataforma ya proporciona y rota, así que no hay
ninguna credencial que guardar.
🔬 Es exactamente la identidad de servicio de [`05`](#05--mtls-zero-trust-y-service-mesh)
reutilizada, y es lo que cierra el círculo: la misma identidad que autoriza la llamada entre
servicios autoriza la obtención de secretos.

**06 → 11. ¿Por qué `Random` no sirve para generar un identificador de sesión?**

⏱️ Porque es predecible: conocidas unas pocas salidas, se puede calcular el estado interno y predecir
las siguientes.
🗣️ `Random` usa un generador congruencial lineal diseñado para simulaciones, no para seguridad. Un
atacante que obtenga algunos identificadores puede derivar los que se van a emitir y secuestrar
sesiones.
🔬 Lo correcto es `SecureRandom`, que toma entropía del sistema operativo. La misma regla aplica a
tokens de recuperación de contraseña, claves de idempotencia con valor de seguridad y cualquier valor
que no deba poder adivinarse.

**06 → 12. ¿Qué es un modo de cifrado autenticado y por qué importa?**

⏱️ Uno que además de cifrar detecta si el mensaje fue manipulado: AES-GCM, ChaCha20-Poly1305.
🗣️ Sin autenticación, un atacante puede alterar el texto cifrado y el receptor descifra basura —o,
peor, algo controlado— sin darse cuenta. Con autenticación, el descifrado falla y se detecta.
🔬 El contraejemplo clásico es `AES/ECB`, que además de no autenticar cifra cada bloque igual: los
patrones del original se ven en el resultado. Y en GCM hay una regla absoluta: **nunca reutilizar un
nonce con la misma clave**, porque rompe la confidencialidad por completo.

**06 → 13. ¿Cuál es el primer paso ante un secreto filtrado, y por qué?**

⏱️ Rotar. La credencial está comprometida desde el momento en que se subió, y borrarla del archivo no
la invalida.
🗣️ Mucha gente empieza por limpiar el historial de Git, que es cosmético: mientras la credencial siga
siendo válida, el riesgo sigue vivo. Y hay que asumir que el repositorio pudo clonarse.
🔬 Después: revisar el registro de acceso para ver si se usó desde algún sitio inesperado, limpiar el
historial si procede, notificar según la naturaleza del dato, y poner detección de secretos en el
pipeline para que no se repita. El orden importa y decirlo en ese orden demuestra haber pasado por
ello.

**06 → 14. ¿Contra qué NO protege el cifrado de disco?**

⏱️ Contra quien se conecte a la base de datos con credenciales válidas.
🗣️ El motor descifra de forma transparente al leer, así que cualquier consulta legítima —o cualquier
atacante con credenciales robadas— ve los datos en claro. Protege contra el robo del disco físico o
del snapshot, que es un riesgo real y mucho menos probable.
🔬 Es el nivel más común y el que menos protege contra el escenario realista. Por eso "ciframos en
reposo" satisface muchas casillas de cumplimiento y no cierra el riesgo principal, que es el acceso
indebido a la base de datos.

**06 → 15. ¿Qué precio tiene cifrar campo a campo?**

⏱️ Que no puedes buscar, filtrar ni indexar por ese campo.
🗣️ El valor cifrado es distinto cada vez —si el cifrado es correcto, con nonce aleatorio—, así que un
`WHERE` por igualdad no encuentra nada y un índice no sirve. También se pierden las comparaciones de
rango y la ordenación.
🔬 Añade además coste de cómputo y latencia por cada lectura y escritura, y complica los informes y
la analítica, que dejan de poder trabajar sobre esos campos. Es el nivel más fuerte y el más caro, y
por eso se aplica solo a los datos que lo exigen.

**06 → 16. ¿Cómo se busca por un campo cifrado?**

⏱️ Guardando además un hash determinista con sal secreta, que permite igualdad exacta sin exponer el
valor.
🗣️ El mismo valor produce siempre el mismo hash, así que se puede indexar y buscar por igualdad. La
sal secreta —común, guardada en el gestor de secretos— impide que alguien con la base de datos pueda
probar candidatos.
🔬 Sus límites hay que declararlos: solo sirve para igualdad exacta, no para rangos ni para búsqueda
parcial; y filtra la **repetición**, es decir, revela qué filas comparten el mismo valor, lo que
puede ser información sensible por sí misma. Para búsqueda parcial —los últimos cuatro dígitos— la
solución es guardar ese fragmento aparte, en claro, si el negocio lo permite.

**06 → 17. ¿Por qué rotar la clave maestra no obliga a recifrar los datos?**

⏱️ Porque la clave maestra solo cifra las claves de datos, que son pequeñas: se recifran esas y los
datos no se tocan.
🗣️ Es la ventaja operativa principal del sobre criptográfico. Recifrar terabytes de datos sería un
proyecto; recifrar unas claves de 256 bits es inmediato, y puede hacerse de forma perezosa a medida
que se accede.
🔬 Y permite rotación frecuente, que es lo que muchas normativas exigen. La contrapartida: hay que
versionar las claves y saber con cuál se cifró cada dato, que es información que se guarda junto al
propio dato.

**06 → 18. ¿Cómo se migra de bcrypt a Argon2id sin invalidar las contraseñas?**

⏱️ Con `DelegatingPasswordEncoder`: el hash lleva prefijo de algoritmo, y se rehashea en el siguiente
inicio de sesión correcto.
🗣️ El hash almacenado se guarda como `{bcrypt}$2a$...`. El codificador delegante lee el prefijo y usa
el algoritmo correspondiente para verificar. Cuando la verificación es correcta —momento en el que
tienes la contraseña en claro— se vuelve a hashear con el algoritmo nuevo y se actualiza.
🔬 Así la migración es progresiva y transparente, sin forzar cambios de contraseña. Los usuarios que
no vuelvan a entrar se quedan con el hash antiguo, lo que es aceptable y conviene medir: el
porcentaje migrado dice cuándo se puede retirar el algoritmo viejo. El mismo mecanismo sirve para
subir el factor de trabajo de bcrypt sin cambiar de algoritmo.

**06 → 19. ¿Por qué comparar un token con `equals` es un problema?**

⏱️ Porque `equals` sale en cuanto encuentra una diferencia, y el tiempo de respuesta filtra cuántos
caracteres acertó el atacante.
🗣️ Comparando cadenas cada vez más largas y midiendo el tiempo, se puede reconstruir el valor
carácter a carácter. Es un ataque de canal lateral y en redes reales es difícil pero demostrado.
🔬 Lo correcto es una comparación en tiempo constante: `MessageDigest.isEqual` en Java, que recorre
siempre la longitud completa. Aplica a tokens, firmas, códigos de un solo uso y cualquier secreto que
se compare. Es una línea de código y elimina una clase entera de ataques.

**06 → 20. ¿Cuál es la medida real del éxito en gestión de secretos?**

⏱️ Que rotar un secreto sea un evento rutinario y no un proyecto.
🗣️ No basta con que estén en un gestor: si rotarlos requiere coordinar despliegues, avisar a tres
equipos y elegir una ventana, en la práctica no se rotarán, y el gestor solo cambió dónde está el
problema.
🔬 El estado deseable es que la rotación sea automática y que la aplicación la absorba sin reiniciar
— idealmente con credenciales dinámicas, donde el secreto de larga duración ni siquiera existe. La
prueba: ¿cuándo se rotó por última vez la contraseña de producción, y quién se enteró? Si la
respuesta es "hace años" y "todos", queda trabajo.

**06 → 21. Diseña la gestión de secretos de una plataforma bancaria en Kubernetes: credenciales de base de datos, claves de firma y certificados.**

⏱️ Vault con autenticación por cuenta de servicio de Kubernetes; credenciales de base de datos
dinámicas; claves de firma en HSM que nunca salen; certificados emitidos por cert-manager o la malla.
🗣️ El diseño por tipo de secreto:

```text
Credenciales de BD  → DINÁMICAS. Vault crea un usuario por instancia, TTL de 1 h, permisos
                      acotados al servicio. No hay contraseña compartida que filtrar.
Claves de firma     → en HSM o KMS. La clave privada NUNCA sale: se envía el dato a firmar
                      y vuelve la firma. Rotación con solapamiento y `kid` en los tokens.
Certificados mTLS   → emitidos automáticamente, vida corta, renovación sin intervención.
Claves de cifrado
de datos            → sobre criptográfico: KEK en el KMS, DEK cifradas junto al dato.
Autenticación
contra Vault        → identidad de la cuenta de servicio de Kubernetes. Secreto cero resuelto.
```

🔬 Lo que declararía además. **Vault pasa a ser un componente crítico**: necesita alta
disponibilidad, plan de recuperación y ensayo, porque si cae, las instancias nuevas no arrancan.
**El registro de acceso** es parte del valor, no un extra: ante un incidente es lo que acota el
alcance, y en banca es exigible. **Segregación por entorno**: las credenciales de producción no deben
ser accesibles desde preproducción, ni siquiera por error de configuración. Y **detección en el
pipeline**: escaneo de secretos que falle el build, porque el mejor gestor no impide que alguien pegue
una clave en un archivo. Por último, un punto operativo que se olvida: los **backups** de la base de
datos y del propio Vault contienen material sensible y necesitan su propio cifrado y control de
acceso.

**06 → 22. Hay que guardar el número de tarjeta para poder cobrar recurrentemente, y además buscar por los últimos cuatro dígitos. Diseña el almacenamiento.**

⏱️ No guardaría el número: usaría **tokenización** del proveedor de pagos. Si hay que guardarlo,
cifrado de campo con sobre criptográfico, más los cuatro últimos en claro y un hash determinista para
detectar duplicados.
🗣️ La primera respuesta es la correcta y la que menos gente da: las pasarelas ofrecen un **token de
tarjeta** que sirve para cobrar y que no es el número. Guardando solo ese token, el dato sensible
nunca entra en tu sistema, y el alcance de cumplimiento PCI se reduce drásticamente. Es
además lo que la normativa empuja a hacer.
🔬 Si el negocio exige guardarlo —por ejemplo, porque opera con varias pasarelas—, el diseño:

```text
pan_cifrado      → AES-GCM con DEK propia; DEK cifrada con la KEK del HSM (sobre criptográfico)
ultimos4         → EN CLARO. No son sensibles por sí solos y resuelven la búsqueda de soporte.
bin              → los primeros 6, en claro si hace falta para enrutar por emisor
pan_hash         → hash determinista con pimienta secreta, para detectar que dos clientes
                   usan la misma tarjeta SIN descifrar nada
```

Lo que hay que declarar: el hash determinista **revela la repetición** —qué filas comparten tarjeta—,
que es justo lo que antifraude necesita y a la vez una filtración de información; es aceptable aquí
porque ese es el propósito. El descifrado del número solo ocurre en el momento del cobro, en un
servicio con alcance acotado y acceso auditado, nunca en el servicio que atiende al usuario. Y el
código de seguridad (CVV) **no se guarda nunca**, ni cifrado: la normativa lo prohíbe expresamente.

**06 → 23. Alguien subió la contraseña de producción al repositorio hace tres meses. Describe el procedimiento completo.**

⏱️ Rotar inmediatamente, medir el alcance con los registros de acceso, limpiar el historial, notificar
si procede, y poner detección para que no se repita.
🗣️ El procedimiento en orden:

```text
1. ROTAR la credencial. Ahora. Tres meses es tiempo suficiente para que se haya usado.
   Si rotarla requiere coordinación, eso es en sí un hallazgo.
2. ALCANCE: revisar los registros de acceso a la base de datos en esos tres meses buscando
   conexiones desde IP, horarios o patrones inesperados. Es lo que determina si fue
   exposición o incidente.
3. Inventariar quién tuvo acceso al repositorio en ese periodo, incluidos colaboradores
   externos y sistemas de CI con credenciales de clonado.
4. Limpiar el historial de Git y forzar la reescritura, asumiendo que los clones existentes
   la conservan. Invalidar tokens de acceso al repositorio por precaución.
5. NOTIFICAR según lo que esa credencial pudiera alcanzar y la normativa aplicable.
6. Prevención: escaneo de secretos en pre-commit y en CI que falle el build; mover ese y
   los demás secretos a un gestor; y si es posible, credenciales dinámicas para que la
   clase entera de problema desaparezca.
```

🔬 Los dos matices que marcan la diferencia. **El paso 2 es el que decide si esto es un incidente
notificable o una exposición sin uso conocido**, y solo se puede responder si existen registros de
acceso con suficiente retención — si no existen, hay que decir que no se puede descartar el uso, que
es una respuesta peor pero honesta. Y **el paso 4 no es urgente**: limpiar el historial sin haber
rotado es el error clásico, porque da sensación de haberlo resuelto mientras la credencial sigue
viva. Añadiría una revisión más amplia: si esta contraseña llegó ahí, probablemente haya otras, y un
escaneo retroactivo del historial completo suele encontrarlas.

---

# 07 — Simulación: escenarios de diseño

> Las preguntas `S#` del bloque 2 de [`07`](07-simulacion-de-entrevista.md) se responden con las
> entradas de los capítulos correspondientes, que están arriba. Aquí van los cinco escenarios.

## E1 — El que NO necesita service mesh

**Respuesta corta:** no instalo Istio. Resuelvo los tres problemas reales por separado, a un coste
mucho menor, y fijo el disparador que me haría cambiar de opinión.

**Lo que dicen que quieren y lo que realmente resuelve cada cosa.** Piden mTLS y observabilidad, que
son dos problemas independientes:

```text
Observabilidad → ya la tienen. Micrometer + OpenTelemetry da métricas y trazas, y es
                 uniforme porque los cinco servicios son Java. La malla no añade nada.
Resiliencia    → Resilience4j da circuit breaker, reintentos y bulkhead, con más control
                 que el proxy y depurable desde el código.
mTLS           → esto sí falta. Y es lo único que justifica la conversación.
```

**La alternativa para mTLS.** cert-manager emitiendo certificados de vida corta desde una CA interna,
y TLS mutuo configurado en la aplicación. Es más trabajo en el código y muchísimo menos que operar
que un plano de control. Para un producto interno de gestión documental sin datos financieros, la
autorización por identidad puede resolverse con `NetworkPolicy` y con Client Credentials.

**El coste que argumento.** Istio añade un proxy por instancia con su latencia y su consumo, un plano
de control que es componente crítico nuevo, una curva de aprendizaje considerable, y un modo de fallo
donde una política mal escrita corta tráfico de producción. Con seis personas no hay equipo de
plataforma: a las tres de la mañana nadie va a saber diagnosticar un error de sidecar, y ese es el
argumento decisivo.

**El disparador acordado.** Volvería a evaluarlo si aparece un segundo lenguaje —ahí la uniformidad
empieza a valer—, si el número de servicios se multiplica, o si el producto pasa a manejar datos
regulados que exijan cifrado interno auditable.

**La parte humana.** Reconocería que el equipo quiere aprender Istio, que es legítimo, y propondría
separarlo del producto: una prueba de concepto en un entorno aparte, sin convertirlo en dependencia
de algo que funciona.

## E2 — La cadena de confianza

**Respuesta corta:** hoy hay confianza implícita y tres agujeros concretos. Propongo dos identidades
en cada salto interno, token exchange, y corte estricto hacia el proveedor externo.

**Lo que falla hoy, con nombre:**

```text
1. Riesgo no sabe quién es el usuario → no puede autorizar sobre el expediente concreto.
   Su única defensa es lo que Cuentas haya comprobado. Confusión de deputado esperando.
2. Cualquier cosa dentro de la red puede llamar a Riesgo → un SSRF o un contenedor
   comprometido alcanza datos de riesgo crediticio sin ninguna barrera.
3. No hay trazabilidad → ante la pregunta "¿quién ordenó esta consulta de scoring?",
   el log dice "llamada de Cuentas". Eso no vale ante un supervisor bancario.
```

**El diseño, salto a salto**, con la estructura de [04 → 21](#04--propagación-de-identidad-entre-servicios)
y lo específico de este caso:

```text
usuario → gateway     Token OIDC, aud=gateway. Las seis validaciones. Filtro grueso por ruta y rol.
gateway → Cuentas     mTLS + token intercambiado (aud=cuentas, sub=usuario, act=gateway).
                      Cuentas comprueba que el usuario es titular de la cuenta.
Cuentas → Riesgo      mTLS + token intercambiado (aud=riesgo, scope=riesgo:evaluar,
                      sub=usuario, act=cuentas). RIESGO COMPRUEBA POR SÍ MISMO.
Riesgo → proveedor    NUNCA el token del usuario. Certificado propio ante el proveedor,
  externo             o Client Credentials contra su servidor. Si necesitan identificar al
                      cliente final, un identificador opaco acordado, no tu sub.
```

**El salto al tercero es el que más se falla.** Propagar el token del usuario a un proveedor externo
le entrega una credencial válida en todo tu sistema, que además quedará en sus logs, fuera de tu
perímetro y de tu auditoría. Y añadiría el detalle de banca: **token atado al certificado** (RFC
8705), que es lo que exige Open Banking y hace que interceptar el token no baste.

**La migración**, porque no se puede parar el negocio: modo permisivo primero —los servicios envían
identidad y la registran sin exigirla—, medir hasta que el registro de llamadas sin identidad sea
cero, y entonces modo estricto con feature flag. Empezando por `Riesgo`, que es el que toca los datos
más sensibles.

**Lo que mediría:** llamadas sin identidad por servicio, y porcentaje de endpoints de `Riesgo` con
comprobación de relación usuario–expediente. La segunda es la que de verdad cierra el agujero.

## E3 — Revocación en segundos

**Respuesta corta:** la validación sin estado y la revocación inmediata son incompatibles. Propongo
access token de 30–60 segundos más verificación de estado de sesión, y declaro el coste.

**El compromiso, dicho de entrada.** Un JWT autocontenido es válido hasta que caduca porque nadie
consulta al emisor. Con caducidad de una hora, la ventana es de una hora. Bajar a 30 segundos es la
palanca directa, y su precio es multiplicar las llamadas de refresco.

**El diseño:**

```text
Fuente de verdad    → el proveedor de identidad. Desactivar al empleado es UNA acción,
                      y el procedimiento de baja debe tenerla como primer paso, verificada.
Access token        → 60 s. Ventana máxima de acceso indebido: 60 s.
Refresh token       → al renovar, el proveedor comprueba el estado y deniega. Aquí muere la sesión.
Servicios críticos  → introspección con caché de 10 s. Ventana de 10 s donde importa.
Sesiones web        → back-channel logout: el proveedor notifica a las aplicaciones y estas
                      invalidan la sesión del lado servidor.
```

**La alternativa que mencionaría**, porque es más barata: una **marca de versión de sesión** en el
token, comparada contra un valor por usuario en una caché compartida. Revocar es incrementar el
número; la ventana es el tiempo de propagación de la caché, del orden de un segundo, y cuesta una
consulta rápida en vez de una llamada al proveedor.

**Lo que descartaría:** una lista de tokens revocados. Crece sin límite, hay que consultarla en cada
petición igualmente, y no aporta nada sobre las opciones anteriores.

**El coste que declaro.** El proveedor de identidad pasa a estar en el camino crítico de cada
renovación y necesita alta disponibilidad real. La introspección añade latencia acotada por la caché.
Y hay un coste organizativo: de nada sirve el diseño si la baja del empleado tarda dos días en
tramitarse, así que la medida incluye el procedimiento de recursos humanos, no solo el técnico.

## E4 — El dato que hay que cifrar y buscar

**Respuesta corta:** tokenización del proveedor de pagos como primera opción. Si hay que guardar el
número, cifrado de campo con sobre criptográfico, últimos cuatro en claro, y hash determinista para
antifraude.

**La primera respuesta, y la que menos gente da.** Las pasarelas ofrecen un token de tarjeta que
sirve para cobrar y que no es el número. Guardando solo ese token, el dato sensible nunca entra en tu
sistema y el alcance de cumplimiento se reduce drásticamente. La pregunta previa es si el negocio
opera con una sola pasarela: si sí, esto lo resuelve entero.

**Si hay que guardarlo**, el diseño está en [06 → 22](#06--secretos-y-criptografía) y lo repito
resumido: `pan_cifrado` con AES-GCM y sobre criptográfico, `ultimos4` en claro, `bin` en claro si hace
falta enrutar, y `pan_hash` determinista con pimienta secreta.

**Cómo se resuelve cada requisito:**

```text
Cobro recurrente      → descifrar el PAN en el momento del cobro, en un servicio con alcance
                        acotado, acceso auditado y sin exposición al usuario.
Búsqueda de soporte   → ultimos4 en claro. No son sensibles por sí solos y se indexan.
Antifraude: misma
tarjeta, dos clientes → pan_hash determinista. Compara sin descifrar nada.
No legible para el
DBA                   → cifrado de CAMPO. El de disco o el de base de datos NO cumple esto,
                        porque el motor descifra de forma transparente.
```

**Lo que declaro como coste.** El hash determinista **revela la repetición**: quién comparte tarjeta
con quién. Aquí es el propósito, pero es información y hay que reconocerlo. No se puede buscar por
rangos ni parcialmente sobre el campo cifrado. Y el CVV **no se guarda nunca**, ni cifrado: la
normativa lo prohíbe expresamente, y decirlo es de las cosas que más señalan conocimiento del
dominio.

**La rotación.** Con sobre criptográfico, rotar la clave maestra recifra solo las claves de datos, no
los millones de tarjetas. Eso es lo que hace viable cumplir un requisito de rotación anual.

## E5 — Sistema heredado sin ninguna medida

**Respuesta corta:** priorizo por riesgo dividido por coste. Secretos primero, contraseñas después,
transporte, y autorización al final porque es la más invasiva y la más lenta.

**El orden y el porqué de cada paso:**

```text
1. SECRETOS FUERA DEL CÓDIGO (semanas 1–2)
   Alto impacto, coste bajo, sin cambiar arquitectura. Y rotar todo lo que estuvo expuesto.
   Empezar aquí demuestra valor rápido, que es lo que compra permiso para lo siguiente.

2. CONTRASEÑAS: SHA-1 sin sal → bcrypt o Argon2id (semanas 2–4)
   Sin invalidar ninguna: DelegatingPasswordEncoder con prefijo, rehashear en el siguiente
   inicio de sesión correcto. Migración progresiva y transparente.
   Y forzar cambio SOLO a las cuentas privilegiadas, donde el riesgo lo justifica.

3. HTTPS INTERNO (semanas 3–6)
   Empezar por terminación TLS en el ingreso, que es rápido. mTLS entre componentes después,
   si la normativa lo exige; en un monolito puede no hacer falta.

4. AUTORIZACIÓN (meses 2–6)
   El `if` sobre `perfil` es un RBAC implícito y frágil. Se sustituye por comprobaciones
   explícitas, empezando por los endpoints que tocan dinero. Endpoint a endpoint,
   con un test de 403 por cada uno.

5. AUTENTICACIÓN PROPIA → proveedor de identidad (meses 4–12)
   Lo más caro y lo último. Coexistencia: el proveedor delega inicialmente contra el
   almacén de usuarios existente, y se migra sin que el usuario note nada.
```

**Por qué ese orden y no el intuitivo.** Lo intuitivo sería empezar por la autenticación, que es lo
más visible y lo que peor pinta tiene. Pero es lo más caro, lo más largo y lo que más riesgo de
interrupción tiene. Los pasos 1 y 2 quitan más riesgo por menos esfuerzo y no requieren coordinar con
nadie.

**Lo que haría en paralelo desde el día uno**, porque no interrumpe: escaneo de secretos en el
pipeline, inventario de endpoints y de qué datos toca cada uno, y registro de auditoría de las
operaciones sensibles — que además es lo que permitirá medir el avance y detectar si algo ya está
siendo explotado.

**Lo que mediría:** número de secretos en el código (debe llegar a cero), porcentaje de contraseñas
migradas, porcentaje de endpoints con comprobación de autorización y test de 403. Nada de "porcentaje
de plan completado".

**La conversación con negocio.** Doce años sin incidentes conocidos es el argumento que van a usar
para no invertir. La respuesta: SHA-1 sin sal significa que una filtración de la base de datos expone
las contraseñas de todos los clientes en horas, y que en banca eso es notificable al supervisor. No
es una mejora técnica: es riesgo regulatorio cuantificable.

---

**Anterior:** [`07` — Simulación de entrevista](07-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
