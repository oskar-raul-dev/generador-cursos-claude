# 🏛️ 100 preguntas de entrevista — Patrones enterprise

> Cubre el catálogo de **PoEAA** (Fowler), los **Enterprise Integration Patterns** (Hohpe & Woolf),
> los patrones tácticos de **DDD** y los patrones arquitectónicos que un arquitecto Java debe defender en entrevista.
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

---

## 🧠 Parte 1 — Lógica de dominio (1–16)

**1. 🟢 ¿Qué es un Transaction Script y cuándo es la opción correcta?**
Un procedimiento por caso de uso que hace todo: valida, calcula y persiste. Es la opción correcta cuando la lógica es simple, hay poca reutilización entre casos de uso y el equipo es pequeño. Su ventaja es que es obvio de leer y depurar; su problema aparece cuando la lógica crece y empieza a duplicarse entre scripts.

**2. 🟡 ¿Qué es un Domain Model y cuál es su punto de equilibrio frente a Transaction Script?**
Un grafo de objetos con datos **y** comportamiento, donde cada objeto protege sus invariantes. El punto de equilibrio: si las reglas de negocio son ricas, cambian a menudo y se comparten entre casos de uso, el Domain Model paga su coste. Si es un CRUD con validaciones triviales, es sobrediseño. La honestidad sobre esta frontera es lo que evalúan.

**3. 🟡 ¿Qué es un Table Module y en qué se diferencia del Domain Model?**
Una clase por tabla que opera sobre un conjunto de registros a la vez (típico del mundo .NET con DataSets), no una instancia por fila. Es intermedio entre Transaction Script y Domain Model. En Java es poco común, pero el concepto reaparece en procesamiento por lotes donde operas sobre colecciones, no sobre entidades individuales.

**4. 🟡 ¿Qué es la Service Layer y qué debe y no debe contener?**
Una frontera de casos de uso que define la API de la aplicación y coordina transacciones, seguridad y orquestación. **Debe** contener coordinación; **no debe** contener reglas de negocio (esas van en el dominio). El anti-patrón habitual es el servicio de 2.000 líneas que es en realidad un Transaction Script disfrazado sobre un modelo anémico.

**5. 🟠 ¿Cómo distingues lógica de aplicación de lógica de dominio?**
Lógica de dominio es la que existiría aunque el sistema fuera de papel: "no se puede debitar más que el saldo disponible". Lógica de aplicación es la que existe por ser software: transacciones, autorización, notificaciones, orquestación de pasos, idempotencia. Si una regla cambia porque cambió el negocio, es dominio; si cambia porque cambió la tecnología o el flujo de la app, es aplicación.

**6. 🟠 ¿Qué es un Domain Service y cuándo lo creas?**
Una operación de dominio que no pertenece naturalmente a ninguna entidad ni value object, típicamente porque involucra a varias (una transferencia entre dos cuentas, un cálculo de tarifa que consulta varias políticas). Regla: crea un domain service solo cuando forzar la operación dentro de una entidad produciría un diseño artificial. No es el basurero de lo que no supiste ubicar.

**7. 🟡 ¿Qué es el patrón Specification en contexto empresarial?**
Encapsular un criterio de negocio como objeto componible y reutilizable, usable para validar en memoria, para seleccionar de una colección y para traducirse a una consulta. Spring Data lo implementa sobre JPA Criteria. Su valor: el vocabulario de negocio ("cliente elegible para crédito") vive como código nombrado, no como un `where` disperso.

**8. 🟠 Modelo anémico vs modelo rico: defiende ambos.**
A favor del rico: invariantes garantizadas, lógica localizada, dominio expresivo y testeable sin infraestructura. A favor del anémico: menor fricción con ORM y frameworks, curva de aprendizaje baja, y perfectamente adecuado en CRUDs. La respuesta de arquitecto: **es una decisión por bounded context**, no global. El core transaccional merece modelo rico; el módulo de configuración de catálogos, probablemente no.

**9. 🟡 ¿Qué es un Aggregate en DDD y para qué sirve la raíz?**
Un grupo de objetos que se tratan como una unidad de consistencia, con una **raíz** que es el único punto de entrada. Toda invariante que debe cumplirse de forma inmediata vive dentro del agregado; lo de fuera se sincroniza por eventos y consistencia eventual. La raíz es también la unidad de bloqueo y de transacción.

**10. 🟠 ¿Cómo decides el tamaño de un agregado?**
Regla práctica: **una transacción, un agregado**. Agregados pequeños reducen contención y deadlocks; agregados grandes simplifican invariantes pero se convierten en cuellos de botella de bloqueo. Si necesitas modificar dos agregados atómicamente, o el corte está mal o necesitas consistencia eventual entre ellos. Referencias entre agregados: **por identidad**, nunca por objeto.

**11. 🟡 ¿Qué es un Domain Event y cuándo se publica?**
Un hecho de negocio ya ocurrido, nombrado en pasado (`FondosDebitados`, `PrestamoAprobado`). Se publica cuando la invariante ya se cumplió, y lo natural es entregarlo **después del commit** para no notificar algo que luego se revierte. En Spring, `@TransactionalEventListener(phase = AFTER_COMMIT)`; entre servicios, el patrón Outbox.

**12. 🟠 Diferencia entre domain event, integration event y command.**
El **command** es una intención ("transferir fondos"), puede rechazarse, va dirigido a un destinatario. El **domain event** es un hecho interno del contexto, con el modelo rico del dominio. El **integration event** es la versión pública y estable que publicas hacia otros contextos, deliberadamente más pobre y versionada. Mezclar los dos últimos es el error que acopla todos tus servicios a tu modelo interno.

**13. 🟡 ¿Qué es una Factory en DDD y en qué se diferencia de un constructor?**
Encapsula la creación compleja de un agregado garantizando que nace válido, especialmente cuando la construcción requiere lógica, datos externos o elegir un subtipo. Diferencia con el constructor: tiene nombre del dominio (`Prestamo.originarDesde(solicitud)`) y puede fallar con una excepción de negocio, no técnica.

**14. 🟠 ¿Qué es la consistencia eventual y cómo se la explicas a negocio?**
Que el sistema converge a un estado correcto, pero no de forma instantánea en todos los puntos. A negocio se explica con su propio lenguaje: "el movimiento se registra al instante, el saldo consolidado y los reportes reflejan el cambio en segundos". Lo importante es acordar **la ventana aceptable** y qué pasa si algo se lee dentro de esa ventana.

**15. 🟠 ¿Qué es el patrón Money y por qué es un ejemplo clásico?**
Un value object que encapsula monto **y** moneda, con aritmética segura, redondeo explícito y prohibición de sumar monedas distintas. Es el ejemplo canónico porque demuestra tres cosas a la vez: obsesión por primitivos resuelta, invariantes en el constructor, e inmutabilidad. En un banco, no tener un tipo `Money` es una decisión que se paga.

**16. 🔴 Diseña la lógica de dominio para el cálculo de intereses de un producto de crédito con múltiples modalidades.**
Domain Model con `Prestamo` como agregado; Strategy o Policy por modalidad de cálculo; `Money` y `Tasa` como value objects; un `CalendarioDeAmortizacion` generado por una factoría. Las reglas regulatorias que cambian van en políticas configurables, no en `if`. Y la parte que distingue al senior: el cálculo debe ser **determinista y reproducible** (mismo input, mismo output, con la tasa y el calendario vigentes en la fecha de cálculo), porque alguien lo va a auditar.

---

## 🗃️ Parte 2 — Acceso a datos y persistencia (17–40)

**17. 🟢 ¿Qué es el patrón Repository y en qué se diferencia de un DAO?**
El **DAO** es una abstracción de acceso a datos orientada a la tabla/almacén. El **Repository** es una abstracción de **colección de agregados** expresada en el lenguaje del dominio: `cuentas.deTitular(id)`, no `cuentaDao.selectByTitularId(id)`. En la práctica muchos equipos los usan como sinónimos; que tú marques la diferencia demuestra lectura real de DDD.

**18. 🟡 Active Record vs Data Mapper: ventajas de cada uno.**
**Active Record**: la entidad sabe persistirse (`usuario.save()`). Simple, rápido de escribir, ideal para CRUD; acopla dominio y persistencia y complica el testing. **Data Mapper**: una capa traduce entre el modelo de dominio y el esquema (JPA/Hibernate). Permite un dominio puro a costa de complejidad de mapeo. Java eligió Data Mapper; Rails, Active Record.

**19. 🟡 ¿Qué es Unit of Work y dónde lo tienes sin saberlo?**
Mantiene la lista de objetos afectados por una transacción de negocio y coordina la escritura y el control de concurrencia. En Java es el `EntityManager` de JPA: el contexto de persistencia acumula cambios y los vuelca en el flush. Por eso modificar una entidad gestionada persiste sin llamar a `save()` — comportamiento que sorprende a quien no conoce el patrón.

**20. 🟡 ¿Qué es Identity Map y qué problema evita?**
Garantiza que cada objeto se cargue una sola vez por transacción, devolviendo siempre la misma instancia. Evita inconsistencias por tener dos copias de la misma fila en memoria y ahorra consultas. Es la caché de primer nivel de Hibernate. Consecuencia práctica: dentro de una misma transacción, `==` entre dos cargas del mismo id es `true`.

**21. 🟠 ¿Qué es Lazy Load y cuáles son sus cuatro variantes?**
Retrasar la carga de un dato hasta que se necesite. Variantes de Fowler: lazy initialization (comprobar null al acceder), virtual proxy (un sustituto que carga al primer uso, lo que hace Hibernate), value holder, y ghost (el objeto se carga parcialmente y se completa al tocar un campo). Su peligro clásico es el N+1 y la `LazyInitializationException`.

**22. 🟠 ¿Qué es el problema del N+1 y cómo lo detectas antes de producción?**
Una consulta para la colección padre más una por cada hijo. Detección: activar estadísticas de Hibernate y contar consultas en las pruebas de integración (con `datasource-proxy` o assertions sobre el número de sentencias), no esperar a la alerta de latencia. Soluciones: `JOIN FETCH`, `@EntityGraph`, `@BatchSize`, o proyecciones a DTO.

**23. 🟡 ¿Qué es un Query Object?**
Una representación de una consulta como objeto, componible y agnóstica del SQL final. JPA Criteria, QueryDSL y `Specification` de Spring Data son implementaciones. Ventaja sobre concatenar strings: seguridad de tipos y composición; desventaja: verbosidad y planes de ejecución más difíciles de prever.

**24. 🟠 Optimistic Offline Lock: ¿cómo lo implementas y cuándo falla?**
Una columna de versión (`@Version`): al actualizar se verifica que la versión no cambió; si cambió, se lanza `OptimisticLockException` y el llamador decide (reintentar, mostrar conflicto, mergear). Funciona con baja contención. Falla —en el sentido de degradar— cuando hay alta concurrencia sobre la misma fila: los reintentos se disparan y el rendimiento cae por debajo del bloqueo pesimista.

**25. 🟠 Pessimistic Offline Lock: ¿cuándo lo prefieres y qué riesgo asumes?**
Cuando el conflicto es probable y rehacer el trabajo es caro (por ejemplo, ajustar un saldo bajo alta concurrencia). Se implementa con `SELECT ... FOR UPDATE` o `PESSIMISTIC_WRITE`. Riesgos: deadlocks (se mitigan adquiriendo siempre en el mismo orden de id), y bloqueos largos que degradan a todo el sistema — de ahí que el lock deba ser lo más corto posible y nunca abarcar llamadas remotas.

**26. 🟠 ¿Qué es un Coarse-Grained Lock?**
Bloquear un conjunto de objetos relacionados con un único lock, típicamente en la raíz del agregado, en vez de bloquear cada objeto. Simplifica el razonamiento y evita deadlocks por adquisición parcial. Es la razón práctica por la que la versión suele vivir en la raíz del agregado.

**27. 🟡 ¿Qué es Implicit Lock y por qué importa en un equipo grande?**
Que el framework adquiera los locks automáticamente en vez de depender de que cada desarrollador recuerde hacerlo. Importa porque la seguridad que depende de la disciplina humana falla: basta un método que olvide el bloqueo para corromper datos. Prefiere siempre el mecanismo que no se puede olvidar.

**28. 🟠 Single Table Inheritance, Class Table Inheritance y Concrete Table Inheritance.**
Son las tres estrategias de mapear herencia a tablas, y corresponden a `SINGLE_TABLE`, `JOINED` y `TABLE_PER_CLASS` en JPA. Single Table: rápida, sin joins, pero con columnas nullable y esquema sucio. Class Table: normalizada y limpia, con joins en cada consulta. Concrete Table: sin joins, pero las consultas polimórficas son un `UNION` costoso. En banca suele ganar `SINGLE_TABLE` por rendimiento o `JOINED` por limpieza de auditoría.

**29. 🟡 ¿Qué es un Embedded Value?**
Mapear un value object a columnas de la tabla del padre (`@Embeddable`/`@Embedded`): una `Direccion` o un `Money` no tienen tabla propia, sus campos viven en la fila de la entidad. Permite tener un dominio rico sin fragmentar el esquema.

**30. 🟠 ¿Qué es Serialized LOB y qué riesgos tiene?**
Guardar un grafo de objetos serializado en una sola columna (hoy típicamente JSON o `jsonb`). Ventaja: flexibilidad de esquema y menos joins. Riesgos: no puedes consultar ni indexar fácilmente (salvo soporte nativo como `jsonb` en PostgreSQL), y la migración de estructura es manual. Úsalo para datos que siempre se leen completos y nunca se filtran por dentro.

**31. 🟡 ¿Qué es Metadata Mapping?**
Describir el mapeo objeto-relacional en metadatos (anotaciones o XML) en vez de código explícito. Es lo que hace JPA. Ventaja: menos código repetitivo. Desventaja: comportamiento implícito difícil de depurar — la queja eterna sobre Hibernate es exactamente el precio de este patrón.

**32. 🟠 ¿Qué es Foreign Key Mapping vs Association Table Mapping?**
Uno a muchos se mapea con clave foránea; muchos a muchos requiere una tabla de asociación. En DDD moderno se recomienda modelar la tabla de asociación como una entidad propia cuando la relación tiene atributos (fecha de vinculación, rol), porque casi siempre termina teniéndolos.

**33. 🟠 ¿Cuándo abandonarías el ORM y usarías SQL directo?**
Consultas analíticas o de reporting complejas, operaciones masivas (un `UPDATE` sobre millones de filas no debe pasar por entidades), casos donde necesitas control exacto del plan, y rutas ultra sensibles a latencia. Herramientas: `JdbcTemplate`, jOOQ, o consultas nativas. Un arquitecto que defiende el ORM como dogma pierde puntos; el criterio es "ORM para el modelo transaccional, SQL para conjuntos".

**34. 🟠 ¿Qué es un Data Transfer Object y cuál es su justificación real?**
Un objeto sin comportamiento que agrupa datos para cruzar una frontera (red, capa, proceso) en una sola llamada. Su justificación **original** era reducir llamadas remotas costosas. Su justificación **actual** es distinta y más importante: desacoplar el contrato público del modelo interno, para que refactorizar el dominio no rompa a los consumidores.

**35. 🟠 ¿Es un anti-patrón mapear entidad a DTO en cada endpoint?**
No, es el precio correcto de desacoplar el contrato. El anti-patrón es lo contrario: exponer entidades JPA como respuesta HTTP, lo que filtra el esquema, arrastra proxies lazy al serializar y convierte cualquier renombrado de columna en un cambio incompatible de API. Para reducir la fricción: MapStruct (mapeo en compilación) o proyecciones directas a DTO en la consulta, que además evitan cargar la entidad completa.

**36. 🟡 ¿Qué es el patrón Gateway?**
Un objeto que encapsula el acceso a un sistema o recurso externo tras una interfaz simple: pasarela de pagos, servicio SOAP del core, API de un buró de crédito. Permite sustituirlo por un doble en pruebas y concentra el manejo de errores, timeouts y reintentos en un solo lugar.

**37. 🟠 ¿Qué es el patrón Registry y por qué se desaconseja?**
Un objeto conocido globalmente donde otros buscan servicios o datos comunes. Se desaconseja por la misma razón que el Service Locator: oculta dependencias y es estado global. Fowler ya advertía que casi siempre hay una alternativa mejor mediante inyección.

**38. 🟠 ¿Cómo manejas la auditoría de cambios sobre entidades?**
Opciones por coste creciente: campos de auditoría (`@CreatedBy`, `@LastModifiedDate` de Spring Data), tabla de historial por triggers, Hibernate Envers, o event sourcing completo. En banca la exigencia típica es saber **quién, qué, cuándo y el valor anterior**, con almacenamiento append-only. Elige según lo que el regulador exija, no según lo que sea elegante.

**39. 🟠 ¿Qué es el patrón Outbox y por qué es imprescindible con ORM + mensajería?**
Escribir el evento en una tabla dentro de la **misma transacción** que el cambio de datos, y publicarlo después con un proceso aparte (polling o CDC con Debezium). Resuelve la imposibilidad de hacer atómicos un commit en base de datos y un envío al broker. Sin outbox tienes el fallo clásico: la transacción hace commit y el evento se pierde, o el evento se envía y la transacción se revierte.

**40. 🔴 Diseña la capa de persistencia de un módulo de movimientos con alto volumen de escritura y consultas por cuenta y rango de fechas.**
Tabla append-only particionada por fecha, índice compuesto por (cuenta, fecha) con el orden pensado para el rango, escritura por lotes, y separación de caliente/frío con archivado. Nada de `UPDATE` sobre movimientos: las correcciones son contra-asientos. Saldo como proyección materializada y actualizada por evento, no como columna que todos bloquean. Menciona que probarías el plan con volumen realista antes de decidir el índice.

---

## 🖥️ Parte 3 — Presentación, distribución y sesión (41–58)

**41. 🟢 ¿Qué es MVC y qué significa en el mundo web actual?**
Separación entre modelo (datos y reglas), vista (presentación) y controlador (traduce entrada en acciones). En web moderno el patrón está partido entre servidor y cliente: Spring MVC es realmente un Front Controller + Application Controller, y la "V" suele ser una SPA independiente. Decirlo demuestra que entiendes el patrón, no solo el nombre del framework.

**42. 🟡 Front Controller vs Page Controller.**
Page Controller: un controlador por página o acción (servlets clásicos). Front Controller: un único punto de entrada que despacha a manejadores — el `DispatcherServlet` de Spring. La ventaja del Front Controller es centralizar lo transversal: seguridad, logging, resolución de vistas, manejo de errores.

**43. 🟡 ¿Qué es un Application Controller?**
La pieza que decide el flujo y la navegación, separada del controlador de entrada. Útil en flujos multipaso (un wizard de originación de crédito, por ejemplo) donde la lógica de "qué pantalla sigue" merece vivir aparte y ser testeable.

**44. 🟡 Template View vs Transform View.**
Template View incrusta marcadores en una plantilla (Thymeleaf, JSP). Transform View toma los datos y los transforma elemento por elemento (XSLT). La primera domina hoy; la segunda sobrevive en integraciones que producen documentos estructurados, algo aún común en banca con formatos regulatorios.

**45. 🟠 ¿Qué es un Remote Facade y cómo se relaciona con el diseño de APIs?**
Una interfaz de grano grueso sobre un modelo de grano fino, para evitar el coste de muchas llamadas remotas. Es el argumento original tras los DTO. Hoy reaparece con otros nombres: BFF (Backend For Frontend) y GraphQL son respuestas al mismo problema — el cliente necesita una vista agregada, no N llamadas.

**46. 🟠 ¿Qué es el patrón BFF y cuándo lo justificas?**
Un backend por tipo de cliente (móvil, web, cajero) que agrega y adapta las respuestas de los servicios de dominio. Se justifica cuando los clientes tienen necesidades de datos muy distintas y estarías contaminando los servicios de dominio con lógica de presentación. Su coste: un componente más que desplegar y versionar por canal.

**47. 🟡 ¿Qué es Server Session State, Client Session State y Database Session State?**
Dónde guardas el estado conversacional. En servidor (sesión HTTP): simple, pero rompe la escalabilidad horizontal salvo con sesiones replicadas o externalizadas. En cliente (cookie, JWT, estado en la SPA): escala perfecto, pero el tamaño y la confianza son un problema. En base de datos (o Redis): escala y sobrevive reinicios, a costa de latencia. Tu caso de Redis para sesiones es exactamente el tercero.

**48. 🟠 ¿Por qué los servicios sin estado escalan mejor?**
Porque cualquier instancia puede atender cualquier petición: no hay afinidad de sesión, el autoescalado es trivial, y matar un pod no pierde trabajo. El estado no desaparece, se **desplaza** a un almacén compartido diseñado para ello. La pregunta correcta no es "¿sin estado?", sino "¿dónde vive el estado y quién lo respalda?".

**49. 🟡 ¿Qué es el patrón Value List Handler / paginación de resultados?**
Devolver resultados en páginas en vez de conjuntos completos. Detalle que demuestra experiencia: la paginación por **offset** degrada con offsets grandes (la base de datos lee y descarta todo lo anterior) y produce resultados inconsistentes si hay inserciones. La alternativa es paginación por **cursor** (keyset), que es estable y de coste constante.

**50. 🟠 ¿Cómo diseñas una API para exportar un millón de registros?**
No por HTTP síncrono. Patrón de trabajo asíncrono: el cliente solicita la exportación, recibe un identificador, el backend genera el archivo en segundo plano y lo deja en almacenamiento de objetos, y el cliente consulta el estado o recibe una notificación con una URL prefirmada. Menciona streaming y compresión, y el límite de tiempo de vida del enlace.

**51. 🟡 ¿Qué es HATEOAS y por qué casi nadie lo implementa?**
Que la respuesta incluya los enlaces a las transiciones posibles, de modo que el cliente navegue el API sin conocer las URLs. Casi nadie lo implementa porque los clientes reales acoplan igual, aumenta el tamaño de las respuestas y las herramientas no lo aprovechan. Es el nivel 3 del modelo de madurez de Richardson, y reconocer que la industria se quedó en el nivel 2 es una respuesta honesta y bien vista.

**52. 🟠 ¿Cómo versionas un contrato empresarial consumido por sistemas que no controlas?**
Compatibilidad hacia atrás por defecto y cambios solo aditivos; versión explícita cuando el cambio es incompatible; política de deprecación con fechas y comunicación formal; pruebas de contrato automatizadas. En banca añade: un consumidor puede tardar un año en migrar, así que el coste de mantener dos versiones es parte del plan, no una sorpresa.

**53. 🟡 ¿Qué es Idempotent Receiver y cómo lo implementas en un endpoint?**
Un receptor que puede procesar el mismo mensaje varias veces sin efectos adicionales. Implementación: clave de idempotencia enviada por el cliente, almacenada con el resultado; si llega repetida, devuelves el resultado guardado sin reejecutar. Crítico: la clave se persiste en la misma transacción que el efecto, o con una restricción única que impida la segunda escritura.

**54. 🟠 ¿Qué es el patrón Claim Check?**
Cuando un mensaje es demasiado grande para el broker, guardas el contenido en un almacén (S3) y envías solo la referencia. El consumidor recupera el contenido con esa "ficha". Resuelve límites de tamaño de mensaje y reduce el coste del broker. En banca es habitual para documentos, imágenes de cheques o archivos de compensación.

**55. 🟠 ¿Qué es un Correlation Identifier y por qué es imprescindible?**
Un identificador que viaja por todos los mensajes y llamadas de un mismo flujo de negocio, permitiendo reconstruir la historia completa a través de N sistemas. Sin él, depurar un flujo distribuido es imposible. Se propaga por header, se incluye en cada log y se expone en las respuestas de error. Es la base del tracing distribuido.

**56. 🟡 ¿Qué es el patrón Return Address?**
El mensaje incluye a dónde debe enviarse la respuesta, en vez de que el receptor lo tenga cableado. Permite que el mismo servicio sirva a múltiples solicitantes con destinos distintos y desacopla la topología de la lógica.

**57. 🟠 ¿Qué es Request-Reply sobre mensajería y qué problema tiene?**
Simular una llamada síncrona sobre un canal asíncrono usando cola de respuesta y correlación. Problema: reintroduces el acoplamiento temporal que la mensajería venía a eliminar, y ahora con más piezas. Si de verdad necesitas respuesta inmediata, muchas veces una llamada HTTP con timeout y circuit breaker es más simple y honesta.

**58. 🔴 El equipo quiere exponer las entidades JPA directamente en la API "para ir más rápido". Eres el arquitecto. ¿Qué argumentas?**
Argumenta con consecuencias, no con dogma: cualquier renombrado de columna rompe clientes externos; la serialización de proxies lazy provoca errores y N+1 en runtime; se filtran campos internos y sensibles sin querer; y no puedes evolucionar el esquema sin coordinar con todos los consumidores. Ofrece la vía rápida legítima: MapStruct o proyecciones a DTO, que cuestan poco. Y reconoce el caso donde sí es aceptable: un endpoint interno, de un solo consumidor, que tú controlas y puedes desplegar a la vez.

---

## 🔌 Parte 4 — Integración empresarial (59–78)

**59. 🟢 ¿Cuáles son los cuatro estilos de integración y sus trade-offs?**
Transferencia de archivos (simple, universal, latencia alta — sigue siendo el estándar en compensación bancaria), base de datos compartida (consistencia fuerte, acoplamiento máximo), invocación remota (inmediato, acoplamiento temporal) y mensajería (desacoplado y resiliente, con consistencia eventual y complejidad operativa). En banca conviven los cuatro y hay que saber cuándo cada uno.

**60. 🟠 ¿Por qué la base de datos compartida entre sistemas es el peor acoplamiento?**
Porque el esquema se convierte en una API implícita que nadie puede cambiar: cualquier migración exige coordinar todos los sistemas a la vez, y ninguno puede evolucionar su modelo. Además dispersa las reglas de negocio (cada sistema valida a su manera) y hace imposible saber quién escribió qué. Es el anti-patrón que más frena la modernización de un core bancario.

**61. 🟡 Point-to-point vs publish-subscribe.**
Punto a punto (cola): un mensaje, un consumidor; ideal para trabajo distribuible. Publicación-suscripción (topic): un mensaje, N suscriptores independientes; ideal para notificar hechos. La regla de diseño: los **comandos** van punto a punto, los **eventos** van a pub/sub.

**62. 🟡 ¿Qué es un Message Router y qué variantes conoces?**
Dirige mensajes a destinos distintos según su contenido o contexto. Variantes: content-based router, filtro por mensaje, recipient list, dynamic router. En AWS, EventBridge es esencialmente un content-based router gestionado.

**63. 🟡 ¿Qué es un Message Translator y por qué es tan importante en banca?**
Convierte el formato de un sistema al de otro. Es importante porque un banco integra sistemas de décadas distintas: copybooks de mainframe, ISO 8583, ISO 20022, SWIFT MT, JSON moderno. El traductor aísla esa heterogeneidad en un solo lugar en vez de repartirla por toda la aplicación; es un anti-corruption layer en formato de mensaje.

**64. 🟠 Splitter y Aggregator: ¿cómo funcionan juntos?**
Splitter descompone un mensaje compuesto en partes procesables individualmente; Aggregator las recompone esperando a que lleguen todas. Lo difícil del Aggregator es lo que debes mencionar: la **estrategia de completitud** (¿cuándo dejo de esperar?) y el **timeout** (¿qué hago si falta una parte?). Sin esa respuesta, el patrón se cuelga en producción.

**65. 🟠 ¿Qué es Scatter-Gather y qué latencia tiene?**
Enviar la misma petición a varios proveedores y agregar las respuestas (cotizaciones de seguros, tarifas de varias aerolíneas). Su latencia es la del **más lento**, no la media, salvo que apliques un timeout con respuesta parcial. Esa decisión —responder con lo que llegó a tiempo— es de negocio, y plantearla así te distingue.

**66. 🟡 ¿Qué es un Dead Letter Channel y qué política le pones?**
El destino de los mensajes que no se pudieron procesar tras agotar reintentos. Política mínima: alerta cuando entra algo (una DLQ silenciosa es un incidente invisible), conservación del mensaje original y su causa, y un procedimiento de reproceso. En banca, además, alguien debe responder por cada mensaje que cae ahí: es dinero o una instrucción que no se ejecutó.

**67. 🟠 ¿Qué es un Message Store y para qué sirve?**
Persistir todos los mensajes que pasan por el sistema para auditoría, reproceso y diagnóstico. En banca suele ser un requisito regulatorio más que una decisión técnica. Kafka lo da casi gratis por su retención; con colas tradicionales hay que construirlo.

**68. 🟠 ¿Qué es Guaranteed Delivery y qué garantiza realmente?**
Que el mensaje sobrevive a caídas del broker mediante persistencia y confirmaciones. Lo que **no** garantiza es que se procese exactamente una vez: la entrega garantizada es "al menos una vez", así que el consumidor debe ser idempotente. Esta distinción es de las que más separan a un senior de un intermedio.

**69. 🟠 ¿Cómo garantizas el orden de los mensajes y qué cuesta?**
Partición por clave (todos los mensajes de una cuenta a la misma partición) con un solo consumidor por partición. Cuesta paralelismo: el orden limita cuánto puedes escalar, y una clave caliente se convierte en cuello de botella. Alternativa: diseñar operaciones conmutativas para que el orden deje de importar — siempre que el dominio lo permita.

**70. 🟡 ¿Qué es un Channel Adapter y un Messaging Bridge?**
El adapter conecta una aplicación que no habla mensajería con el canal (por ejemplo, leer una tabla y publicar eventos). El bridge conecta dos sistemas de mensajería distintos (de IBM MQ a Kafka), algo muy habitual en la modernización de un banco.

**71. 🟠 ¿Qué diferencia hay entre ESB, broker y service mesh?**
El **ESB** centraliza enrutamiento, transformación y lógica de integración (smart pipes, dumb endpoints) — potente pero se convierte en un monolito de integración y un cuello organizativo. El **broker** moderno es tonto y rápido (dumb pipes, smart endpoints). El **service mesh** no transporta lógica de negocio: resuelve preocupaciones de red (mTLS, reintentos, observabilidad) fuera del código.

**72. 🟠 ¿Qué es el patrón Transactional Client y por qué es difícil?**
Que el cliente participe en una transacción con el sistema de mensajería. Es difícil porque una transacción distribuida entre base de datos y broker requiere XA/2PC, que es lento, frágil y poco soportado en la práctica. Por eso la industria se movió a Outbox + idempotencia: acepta la realidad en vez de pelearse con ella.

**73. 🟡 ¿Qué es un Competing Consumers?**
Varios consumidores leyendo de la misma cola para paralelizar el trabajo; el broker garantiza que cada mensaje va a uno solo. Es el modelo de escalado natural de las colas. Advertencia: destruye el orden global, así que solo aplica donde el orden no importa o está garantizado por partición.

**74. 🟠 ¿Qué es el Content Enricher y qué riesgo tiene?**
Añadir datos al mensaje consultando otra fuente antes de entregarlo. Riesgo: introduce una dependencia síncrona en medio de un flujo asíncrono, con su latencia y su posibilidad de fallo. Alternativa preferible cuando se puede: que el productor publique el evento ya completo, porque él tenía el dato en la mano.

**75. 🟠 Coreografía vs orquestación en integración.**
Coreografía: cada servicio reacciona a eventos, sin coordinador; muy desacoplado pero el flujo global no está escrito en ninguna parte y depurarlo es difícil. Orquestación: un componente dirige la secuencia; visible, testeable y fácil de auditar, a costa de un punto central de acoplamiento. En banca, donde hay que demostrar el flujo a un auditor, la orquestación suele ganar en los procesos críticos.

**76. 🟠 ¿Qué es un proceso de conciliación y cómo lo diseñas?**
Un batch que compara lo que registró tu sistema contra lo que reporta la contraparte, clasifica diferencias (faltantes, sobrantes, discrepancias de monto) y genera un reporte accionable. Diseño: idempotente, reejecutable, con almacenamiento de las diferencias y su resolución. Es la red de seguridad que asume que la integración fallará alguna vez — y siempre falla.

**77. 🟠 ¿Cómo integrarías un sistema moderno con un mainframe que solo habla archivos planos diarios?**
Adaptador de archivos con validación estructural, control de duplicados por nombre y hash, tabla de control de lotes procesados, y traducción a eventos de dominio. Todo idempotente y reprocesable. Y un punto que el entrevistador espera oír: **no intentes hacerlo en tiempo real si el origen es diario**; construye un modelo que exprese explícitamente la latencia del dato en vez de fingir que no existe.

**78. 🔴 Diseña la integración entre un core bancario legacy y una nueva capa de canales digitales.**
Anti-corruption layer como pieza central: traduce el modelo del core (códigos, copybooks, semántica histórica) al lenguaje del dominio nuevo. Fachada de servicios sobre el core, con caché para lecturas frecuentes y circuit breaker porque el core no escala. Escrituras siempre síncronas contra el core (es la fuente de verdad del dinero), lecturas servidas desde proyecciones cuando la latencia lo exija. Eventos hacia los canales para notificaciones. Y la decisión que hay que declarar explícitamente: **qué sistema es dueño de qué dato**, porque sin eso la integración se convierte en dos verdades en conflicto.

---

## 🧭 Parte 5 — Arquitectura empresarial y DDD estratégico (79–100)

**79. 🟡 ¿Qué es la arquitectura en capas y cuál es su principal defecto?**
Presentación, aplicación, dominio, infraestructura, con dependencias hacia abajo. Su defecto principal: el dominio termina dependiendo de la infraestructura (porque la capa de datos está "debajo"), lo que invierte lo que realmente importa. La arquitectura hexagonal corrige exactamente eso poniendo el dominio en el centro y las dependencias apuntando hacia dentro.

**80. 🟠 Hexagonal, Onion y Clean Architecture: ¿son lo mismo?**
Son variaciones de la misma idea: el dominio en el centro sin dependencias de framework, y las dependencias siempre hacia dentro (regla de dependencia). Difieren en vocabulario y en cuántos anillos definen. Decir que son la misma idea con distinto envoltorio, en vez de recitar las tres, es la respuesta de arquitecto.

**81. 🟠 ¿Cuál es el coste real de la arquitectura hexagonal?**
Más clases, mapeos entre modelo de dominio y de persistencia, y una curva de aprendizaje que un equipo junior no absorbe solo. En un CRUD produce peor relación coste/beneficio que una capa simple. Se justifica cuando hay lógica de dominio rica, larga vida del sistema, o necesidad real de sustituir infraestructura.

**82. 🟡 ¿Qué es CQRS y cuándo lo aplicas?**
Separar el modelo de escritura del de lectura. Se aplica cuando las necesidades de ambos divergen mucho: escrituras transaccionales normalizadas frente a lecturas que necesitan agregaciones, o cuando hay una asimetría enorme de volumen. **No** requiere event sourcing ni bases separadas: la versión ligera —DTOs de lectura con consultas propias, sin pasar por el modelo de dominio— cubre la mayoría de casos y cuesta muy poco.

**83. 🟠 ¿Cuáles son los costes de CQRS completo con dos almacenes?**
Consistencia eventual visible para el usuario (escribe y no lo ve al recargar), sincronización que puede fallar o atrasarse, doble modelo que mantener, y necesidad de reconstruir proyecciones. Debes poder decir cómo manejas cada uno: versión en la respuesta, lectura de tus propias escrituras, y un mecanismo de reconstrucción probado.

**84. 🟠 ¿Qué es Event Sourcing y qué te da que un modelo de estado no da?**
Guardar la secuencia de eventos como fuente de verdad y derivar el estado reproduciéndolos. Te da auditoría perfecta por construcción, la capacidad de responder preguntas que no habías previsto (viajar en el tiempo), y depuración exacta de cómo se llegó a un estado. En banca el argumento de auditoría es potentísimo — y además el libro mayor contable es, conceptualmente, event sourcing desde hace siglos.

**85. 🟠 ¿Cuáles son los problemas prácticos de Event Sourcing?**
Versionado de eventos (los viejos son inmutables y tienes que seguir leyéndolos), necesidad de snapshots para agregados con miles de eventos, consultas que obligan a mantener proyecciones, borrado de datos personales en un log inmutable (conflicto directo con derecho al olvido, se resuelve con cifrado por sujeto y destrucción de la clave), y una curva de aprendizaje alta. Nombrar el problema del borrado es lo que demuestra experiencia real.

**86. 🟡 ¿Qué es un Context Map y qué relaciones define?**
El mapa de bounded contexts y cómo se relacionan: partnership, shared kernel, customer-supplier, conformist, anti-corruption layer, open host service, published language, separate ways. Es una herramienta **organizativa** además de técnica: describe también la relación entre los equipos, y ese doble uso es lo que lo hace valioso.

**87. 🟠 ¿Qué es un Shared Kernel y por qué es peligroso?**
Un modelo compartido entre dos contextos, con acuerdo explícito de que ningún equipo lo cambia unilateralmente. Es peligroso porque el acoplamiento organizativo es alto: cada cambio requiere coordinación entre equipos y se convierte en cuello de botella. Úsalo solo para conceptos verdaderamente estables y pequeños.

**88. 🟠 ¿Qué es Open Host Service y Published Language?**
Un contexto expone un servicio con un protocolo estable y bien documentado para todos sus consumidores, en un lenguaje publicado y versionado, en vez de negociar una integración a medida con cada uno. Es lo que evita que un servicio central acumule N integraciones distintas. En banca, ISO 20022 es un published language de la industria completa.

**89. 🟠 ¿Qué es la Ley de Conway y cómo la usas a tu favor?**
Un sistema tiende a reflejar la estructura de comunicación de la organización que lo construye. Usarla a favor ("maniobra Conway inversa") significa organizar los equipos según la arquitectura que quieres, en vez de pelear contra la estructura existente. Si un equipo de base de datos separado controla el esquema, no vas a lograr microservicios con datos propios por mucho que lo diseñes.

**90. 🟠 ¿Qué es el patrón Strangler Fig y cómo lo ejecutas?**
Reemplazar un sistema legacy incrementalmente interponiendo una fachada que enruta cada funcionalidad al sistema viejo o al nuevo, hasta que el viejo queda vacío. Ejecución: empezar por lo periférico y de bajo riesgo, mantener ambos sistemas consistentes durante la convivencia, y tener rollback por ruta. Su virtud frente a la reescritura total: entregas valor desde el primer mes y el riesgo está acotado en cada paso.

**91. 🔴 ¿Por qué las reescrituras completas suelen fracasar?**
Porque el sistema viejo contiene años de reglas de negocio no documentadas —muchas de ellas correcciones a casos reales— que nadie sabe enumerar; porque durante la reescritura el negocio sigue pidiendo cambios y hay que mantener dos sistemas; y porque el valor no se entrega hasta el final, lo que agota la paciencia del patrocinador. Cuando se justifica: plataforma sin soporte, imposibilidad de contratar gente, o coste de cambio ya insostenible — y aun así, mejor por olas.

**92. 🟠 ¿Qué es un Data Lake, un Data Warehouse y para qué sirve cada uno?**
Warehouse: datos estructurados, modelados para analítica (esquema al escribir), consultas de negocio y reportes regulatorios. Lake: datos crudos de cualquier formato, esquema al leer, para exploración y machine learning. El patrón que los conecta con el mundo transaccional es CDC o eventos, nunca consultas directas contra la base de producción.

**93. 🟠 ¿Qué es el Reporting Database y por qué existe?**
Una réplica optimizada para lectura donde corren reportes y analítica, para no castigar la base transaccional con consultas pesadas. Es CQRS a nivel de infraestructura, y es de los patrones más rentables y menos glamurosos que existen: resuelve un problema real con muy poca complejidad añadida.

**94. 🟠 ¿Qué es el Saga y en qué se diferencia de una transacción distribuida?**
Una secuencia de transacciones locales donde cada paso tiene una **compensación** si algo falla después. A diferencia de 2PC, no bloquea recursos entre servicios y no requiere coordinador transaccional, pero renuncia al aislamiento: un observador puede ver estados intermedios. En banca, la compensación no borra: emite un contra-asiento, y ese detalle es el que demuestra que entiendes el dominio y no solo el patrón.

**95. 🟠 ¿Qué es un Process Manager y cómo se relaciona con la saga orquestada?**
Un componente con estado que dirige un proceso de negocio largo: recibe eventos, decide el siguiente paso y maneja timeouts. Es la implementación típica de una saga orquestada, y también lo que hacen los motores BPM. Su ventaja en banca: el flujo está explícito y es auditable, y los timeouts —lo que pasa si el tercer paso nunca responde— tienen dueño.

**96. 🟠 ¿Cómo evalúas si un patrón enterprise aplica a tu caso?**
Tres preguntas: ¿qué problema concreto y medido resuelve aquí?, ¿qué complejidad añade y quién la va a operar a las 3 a.m.?, ¿qué alternativa más simple descarté y por qué? Si no puedes responder las tres, todavía no es una decisión, es una preferencia. Y documéntalo como ADR.

**97. 🟠 ¿Qué patrones enterprise consideras sobrevalorados hoy?**
Postura defendible: el **ESB** (centraliza lógica y se vuelve monolito de integración), el **Service Locator** (sustituido por DI), **Event Sourcing aplicado por defecto** a todo el sistema en vez de a los agregados que realmente lo necesitan, y las **capas de abstracción sobre el ORM** que solo renombran métodos. Lo importante no es la lista, es que justifiques cada una con el coste que impone.

**98. 🔴 Tu equipo quiere aplicar CQRS + Event Sourcing a todo el sistema. Eres el arquitecto. ¿Qué haces?**
Pregunta primero qué problema medido los lleva ahí: si la respuesta es "es lo moderno", no hay caso. Propón aplicarlo donde el beneficio es claro —el agregado con exigencia de auditoría fuerte— y no en el resto. Pon condiciones operativas antes de aprobar: estrategia de versionado de eventos, mecanismo probado de reconstrucción de proyecciones, plan para el borrado de datos personales, y quién lo opera. Si el equipo no puede responderlas, el patrón todavía no está listo para producción.

**99. 🔴 Un sistema empresarial de 15 años tiene lógica repartida entre procedimientos almacenados, triggers y código Java. ¿Cómo lo abordas?**
Primero inventario y trazabilidad: qué reglas viven dónde, y cuáles se contradicen (siempre hay contradicciones). Después, red de seguridad con pruebas de caracterización sobre los flujos críticos. Luego, migración por olas: mover primero la lógica de negocio que cambia con frecuencia hacia el código (versionable, testeable, revisable), dejar en base de datos lo que de verdad se beneficia de estar ahí por volumen. Los triggers son lo más peligroso porque el efecto es invisible desde el código: prioriza hacerlos explícitos. Y nada de big bang: cada ola desplegable y reversible.

**100. 🔴 ¿Cómo justificas ante un comité de negocio una inversión en arquitectura que no produce features?**
Traduce a su moneda: coste del cambio (cuánto tarda hoy una feature y cuánto tardaría después), coste del riesgo (probabilidad e impacto de una caída o un hallazgo de auditoría), y coste de oportunidad (features que hoy no se pueden hacer). Usa métricas que ya tienes: tasa de fallo de despliegues, tiempo de recuperación, porcentaje de bugs concentrados en un módulo. Y propón inversión incremental con resultados medibles cada trimestre, no un proyecto de un año con beneficio al final — eso último es lo que un comité rechaza, y con razón.

---

> 🧭 **Cierre:** los patrones enterprise no se memorizan, se **eligen y se justifican**. En una entrevista senior, por cada patrón que nombres deberías poder decir en una frase qué te cuesta y qué alternativa descartaste. Eso es lo que separa a un arquitecto de un catálogo andante.
