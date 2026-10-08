# 🧬 100 preguntas de entrevista — Patrones de microservicios

> Catálogo de patrones con nombre propio (referencia: microservices.io de Chris Richardson, más los
> patrones de nube de Azure/AWS que se preguntan habitualmente). Para cada uno: **qué resuelve, qué cuesta
> y cuándo NO usarlo** — que es lo que realmente evalúan.
> Complementa a `preguntas_05_microservicios.md`, que cubre los conceptos y la práctica.
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

---

## ✂️ Parte 1 — Patrones de descomposición (1–12)

**1. 🟢 Decompose by Business Capability: ¿en qué consiste?**
Definir servicios según lo que el negocio **hace** (originación de crédito, gestión de tarjetas, cobranza), tomando el organigrama y el mapa de capacidades como guía. Ventaja: estable en el tiempo, porque las capacidades de negocio cambian mucho menos que la tecnología. Límite: el organigrama puede reflejar historia y política más que el dominio real.

**2. 🟡 Decompose by Subdomain: ¿en qué se diferencia del anterior?**
Usa los subdominios de DDD (core, de soporte, genérico) y sus bounded contexts en lugar del organigrama. Suele dar mejores fronteras porque se basa en el lenguaje y el modelo, no en la estructura organizativa. En la práctica se combinan: capacidad de negocio para el mapa grueso, subdominio para afinar.

**3. 🟠 Self-Contained Service: ¿qué promete y qué cuesta?**
Un servicio que atiende una petición **sin llamadas síncronas a otros**, replicando localmente los datos que necesita. Promete disponibilidad y latencia mucho mejores. Cuesta duplicación de datos, consistencia eventual, y complejidad de mantener las réplicas actualizadas. Es el patrón que más mejora la resiliencia real y el menos aplicado por pereza.

**4. 🟡 Service per Team: ¿por qué se considera un patrón?**
Porque alinea la propiedad del código con la unidad organizativa que despliega. Un servicio sin dueño único acumula cambios descoordinados y nadie responde por él en producción. Es un patrón organizativo, y en microservicios esos pesan tanto como los técnicos.

**5. 🟠 Strangler Fig Application: describe su ejecución paso a paso.**
Se interpone una fachada delante del sistema legacy que enruta cada funcionalidad al viejo o al nuevo. Pasos: elegir una funcionalidad periférica y de bajo riesgo, implementarla en el servicio nuevo, enrutar a través de la fachada, mantener consistencia de datos durante la convivencia, verificar, y retirar el código viejo. Repetir hasta vaciar el legacy. Su virtud: entregas valor desde el primer mes y cada paso es reversible.

**6. 🟠 Anti-Corruption Layer: ¿cuándo lo construyes y cuánto cuesta?**
Cuando el modelo de un sistema externo o legacy contaminaría tu dominio (códigos crípticos, semántica histórica, campos reutilizados con varios significados). Traduces en la frontera para que dentro se hable tu lenguaje. Cuesta una capa de mapeo que hay que mantener sincronizada con el sistema ajeno. En la integración con un core bancario es de las inversiones más rentables que existen.

**7. 🟡 Sidecar: ¿qué responsabilidades le delegas?**
Un contenedor auxiliar junto a la aplicación, con su mismo ciclo de vida, que asume funciones transversales: proxy del mesh (mTLS, reintentos, telemetría), recolección de logs, agente de secretos. Permite que la aplicación se concentre en negocio y que la capacidad sea homogénea entre lenguajes. Coste: más recursos por pod y una capa más que depurar.

**8. 🟠 Ambassador: ¿en qué se diferencia del sidecar?**
Es un tipo de sidecar especializado en **salida**: encapsula las llamadas del servicio hacia fuera, aplicando reintentos, circuit breaking, enrutamiento y monitorización sin que el código lo sepa. Es una forma de dar resiliencia uniforme a servicios escritos en lenguajes que no tienen una buena librería.

**9. 🟡 Adapter / Anti-pattern "distributed monolith": ¿cómo reconoces el segundo?**
El monolito distribuido se reconoce por: base de datos compartida, despliegues que deben coordinarse, librería común con el modelo de dominio, y una cadena síncrona donde cualquier caída tumba el flujo. Tiene todos los costes de la distribución y ninguno de sus beneficios; es el resultado más habitual de una descomposición apresurada.

**10. 🟠 Bounded Context como patrón de frontera: ¿qué relaciones pueden existir entre dos contextos?**
Del context map de DDD: partnership, shared kernel, customer-supplier, conformist, anti-corruption layer, open host service, published language y separate ways. Cada una describe también la relación entre **equipos**, no solo entre sistemas, y elegir la equivocada genera fricción organizativa permanente.

**11. 🟠 Shared Kernel entre microservicios: ¿aceptable o anti-patrón?**
Aceptable solo para conceptos muy estables y pequeños, con acuerdo explícito de que nadie lo cambia unilateralmente. Se convierte en anti-patrón en cuanto contiene modelo de dominio o lógica: entonces cualquier cambio exige desplegar varios servicios a la vez y perdiste la autonomía, que era el único motivo para tener microservicios.

**12. 🔴 ¿Qué patrón de descomposición aplicarías a un sistema de tarjetas de crédito y por qué?**
Por subdominio, porque el dominio de tarjetas tiene contextos muy marcados: emisión, autorización (tiempo real, latencia crítica, alta disponibilidad), compensación y liquidación (batch, contable), disputas y contracargos (proceso largo con estados), y fidelización (no crítico, puede degradar). Cada uno tiene requisitos de latencia, consistencia y disponibilidad radicalmente distintos, y eso es precisamente lo que justifica separarlos: autorización necesita milisegundos y cinco nueves; disputas necesita trazabilidad y puede tardar días.

---

## 🗄️ Parte 2 — Patrones de datos (13–34)

**13. 🟢 Database per Service: ¿qué garantiza y qué rompe?**
Garantiza autonomía de esquema, de tecnología y de despliegue. Rompe los joins entre servicios, la integridad referencial entre ellos y las transacciones ACID que los abarquen. Es la decisión fundacional: sin ella no hay microservicios, con ella heredas todos los patrones de datos que siguen.

**14. 🟡 Shared Database: ¿existe algún caso legítimo?**
Como estado transitorio durante una migración, con fecha límite y plan de salida documentado. Fuera de eso es un anti-patrón: el esquema se convierte en una API implícita que nadie puede cambiar, las reglas se dispersan y ningún equipo puede desplegar sin coordinar. Lo peligroso es que "temporal" se vuelve permanente si no hay plan escrito.

**15. 🟠 Saga: explica coreografía vs orquestación con sus trade-offs.**
Saga coreografiada: cada servicio reacciona a eventos y emite los suyos; simple con pocos pasos, sin punto central, pero el flujo no está escrito en ninguna parte y depurarlo con siete pasos es muy difícil. Saga orquestada: un coordinador dirige la secuencia; el flujo es explícito, testeable y auditable, a costa de un componente que conoce a todos. Regla práctica: hasta tres o cuatro pasos, coreografía; más allá, o si hay que auditarlo, orquestación.

**16. 🟠 ¿Cómo diseñas las transacciones compensatorias de una saga?**
Cada paso necesita una compensación semánticamente correcta, no un "deshacer" técnico. Clasifica los pasos: **compensables** (pueden revertirse), **pivote** (el punto sin retorno) y **reintentables** (después del pivote solo se puede avanzar, nunca retroceder). Diseñar la saga es elegir dónde está el pivote. En banca, compensar un débito es emitir un contra-asiento, nunca borrar el movimiento.

**17. 🟠 ¿Qué es el bloqueo semántico en una saga?**
Marcar un registro como "en proceso" o "pendiente" para que otras operaciones sepan que hay una saga en curso, compensando la pérdida de aislamiento. Ejemplo: reservar fondos (saldo disponible menor que el contable) mientras se completa una transferencia. Es la contramedida más usada frente a las anomalías que introduce la falta de aislamiento.

**18. 🟠 Transactional Outbox: ¿qué problema resuelve exactamente?**
La imposibilidad de hacer atómicos un commit en la base de datos y una publicación en el broker. Escribes el evento en una tabla dentro de la misma transacción y un proceso aparte lo publica. Garantiza que **si el cambio ocurrió, el evento se publicará** (at-least-once). Es el patrón que más se omite y el que más incidencias de "eventos perdidos" causa cuando falta.

**19. 🟡 Transaction Log Tailing vs Polling Publisher: ¿cómo eliges?**
Polling: un proceso consulta la tabla de outbox periódicamente; simple, sin dependencias, con latencia de segundos y carga extra sobre la base. Log tailing (CDC con Debezium): lee el log de transacciones; latencia menor y sin carga de consulta, a costa de acoplarse al motor, requerir permisos especiales y añadir una pieza operativa. Con volumen moderado, polling es suficiente y mucho más simple.

**20. 🟠 Idempotent Consumer: ¿cómo lo implementas correctamente?**
Registrando los identificadores de mensajes procesados en la misma transacción que el efecto (patrón inbox), o mediante una restricción única sobre una clave natural, o con una condition expression en el almacén. Lo incorrecto: comprobar primero y escribir después sin atomicidad, porque dos consumidores concurrentes pasan ambos la comprobación.

**21. 🟠 API Composition: ¿cuándo funciona y cuándo no?**
Un componente consulta a varios servicios y une los resultados en memoria. Funciona para conjuntos pequeños, pocas fuentes y consultas simples. No funciona cuando hay que unir grandes volúmenes, paginar u ordenar por campos de servicios distintos — ahí la unión en memoria es inviable y necesitas CQRS con una vista materializada.

**22. 🟠 CQRS en microservicios: ¿qué problema resuelve y qué introduce?**
Resuelve consultas que atraviesan varios servicios o que necesitan un modelo distinto al de escritura, mediante vistas materializadas alimentadas por eventos. Introduce consistencia eventual visible, un almacén más que mantener, y la necesidad de poder **reconstruir** la proyección desde cero. Si no tienes reconstrucción probada, la proyección se convierte en una fuente de verdad no declarada.

**23. 🟠 Event Sourcing: ¿qué te da y cuál es su coste real?**
Da auditoría perfecta por construcción, capacidad de responder preguntas no previstas y depuración exacta del camino a un estado. Cuesta: versionado de eventos inmutables, snapshots para agregados largos, proyecciones obligatorias para consultar, curva de aprendizaje alta, y el conflicto con el derecho al olvido (se resuelve con cifrado por sujeto y destrucción de la clave). En banca el argumento de auditoría es fuerte, pero conviene aplicarlo a los agregados que lo justifican, no a todo el sistema.

**24. 🟡 ¿Qué es un snapshot en event sourcing y cuándo lo necesitas?**
Una foto del estado del agregado en un punto, para no reproducir miles de eventos al cargarlo. Lo necesitas cuando la reproducción empieza a dominar la latencia. Detalle importante: el snapshot es una optimización, **no** la fuente de verdad — debe poder descartarse y regenerarse.

**25. 🟠 Event Sourcing vs Change Data Capture: ¿en qué se diferencian conceptualmente?**
Event sourcing publica **intenciones y hechos de negocio** decididos por el dominio (`FondosDebitados`). CDC publica **cambios de filas** derivados de la implementación (`UPDATE en tabla cuentas`). CDC acopla a los consumidores a tu esquema interno, que es justo lo que querías evitar. CDC es excelente para integrar sistemas que no puedes modificar; no es un sustituto de eventos de dominio bien diseñados.

**26. 🟠 Domain Event vs Integration Event: ¿por qué separarlos?**
El domain event es interno, rico y refleja tu modelo; el integration event es público, deliberadamente pobre y estable, y se versiona. Separarlos evita que todos tus consumidores queden acoplados a tu modelo interno y que cualquier refactorización del dominio rompa a medio mundo. Es una de las decisiones más rentables y menos aplicadas.

**27. 🟠 Aggregate como unidad de consistencia: ¿cómo afecta al diseño de microservicios?**
Determina el límite de la transacción: dentro del agregado, consistencia fuerte e inmediata; fuera, consistencia eventual. De ahí la regla "una transacción, un agregado". Si un caso de uso necesita modificar dos agregados atómicamente, o el corte está mal o necesitas una saga. Es la traducción directa del diseño táctico a la arquitectura distribuida.

**28. 🟡 Replica / Data Replication pattern: ¿cuándo replicar datos de otro servicio?**
Cuando necesitas un subconjunto pequeño, estable y de solo lectura para responder sin llamadas síncronas (datos de referencia, catálogos, atributos básicos del cliente). Reglas: la réplica es de **solo lectura**, se actualiza por eventos, y nunca se convierte en una segunda fuente de verdad. Debes poder reconstruirla completa.

**29. 🟠 ¿Qué es el patrón de Materialized View y cómo garantizas que no se desincronice?**
Un modelo de lectura precalculado alimentado por eventos. Garantías: consumidor idempotente, control de secuencia para detectar huecos, métrica de retraso con alerta, y proceso de reconstrucción completa probado periódicamente (no solo documentado). Si nunca has reconstruido la vista, no sabes si puedes.

**30. 🟠 ¿Qué es el patrón de Reconciliación y por qué es imprescindible en banca?**
Un proceso periódico que compara los estados de dos sistemas, clasifica las diferencias y las reporta para su resolución. Es imprescindible porque en un sistema distribuido la propagación fallará alguna vez, y en banca cada diferencia es dinero. Es la red de seguridad que asume el fallo en vez de confiar en que no ocurrirá.

**31. 🟡 Command Query Responsibility Segregation ligero: ¿qué versión recomiendas por defecto?**
La ligera: mismo almacén, modelos distintos. Las consultas van directo a DTOs con SQL optimizado, sin pasar por el modelo de dominio ni por el ORM; las escrituras pasan por el agregado. Obtienes la mayor parte del beneficio con casi ninguno de los costes, y no introduces consistencia eventual.

**32. 🟠 ¿Qué es el patrón Claim Check y en qué caso lo has visto en banca?**
Cuando el mensaje es demasiado grande (documentos, imágenes de cheques, archivos de compensación), se guarda el contenido en almacenamiento de objetos y se envía solo la referencia. Reduce coste y respeta los límites del broker. Requiere gestionar el ciclo de vida del objeto y los permisos de acceso.

**33. 🟠 ¿Cómo versionas el esquema de eventos sin romper consumidores?**
Schema registry con reglas de compatibilidad verificadas en el pipeline, solo cambios aditivos, campos nuevos opcionales con valor por defecto, nunca reutilizar un nombre con otra semántica, y un tipo de evento nuevo cuando el cambio es incompatible. Recuerda que los eventos antiguos permanecen en el topic: el consumidor debe poder leer versiones viejas indefinidamente.

**34. 🔴 Diseña la estrategia de datos para un servicio de autorización de transacciones con requisito de 20 ms p99.**
Datos necesarios para decidir en el propio servicio (self-contained): límites, estado de la tarjeta, reglas vigentes, replicados localmente y actualizados por eventos. Saldo o cupo disponible en un almacén de muy baja latencia con operación atómica de reserva (DynamoDB con condition expression, o Redis con persistencia y respaldo). Nada de llamadas síncronas a otros servicios en el camino crítico. Escritura del movimiento asíncrona vía outbox. Y la decisión de negocio que hay que plantear explícitamente: **si la fuente de verdad no responde a tiempo, ¿se aprueba o se rechaza?** — hay bancos que prefieren aprobar y asumir el riesgo (stand-in processing) y otros que rechazan; esa política debe estar escrita, no improvisada.

---

## 📡 Parte 3 — Comunicación, API y descubrimiento (35–56)

**35. 🟢 Remote Procedure Invocation: ¿qué implica elegir este estilo?**
Comunicación síncrona petición-respuesta (REST, gRPC). Implica acoplamiento temporal: ambos deben estar vivos. Ventaja: simple de razonar y de depurar, resultado inmediato. Desventaja: la disponibilidad combinada se degrada multiplicativamente con cada salto de la cadena.

**36. 🟡 Messaging pattern: ¿qué garantías necesitas definir?**
Al elegir mensajería debes decidir explícitamente: durabilidad (¿sobrevive a la caída del broker?), garantía de entrega (at-least-once en la práctica), orden (global, por partición o ninguno), política de reintentos y DLQ, y retención. Un diseño de mensajería que no responde estas cinco preguntas está incompleto.

**37. 🟠 API Gateway: responsabilidades legítimas y línea roja.**
Legítimas: enrutamiento, terminación TLS, autenticación, rate limiting, transformación de protocolo y agregación simple. Línea roja: lógica de negocio. En cuanto el gateway toma decisiones de dominio, se convierte en un ESB moderno con cuello organizativo — todos los equipos dependiendo de un mismo componente para desplegar.

**38. 🟡 Backends for Frontends: ¿qué problema resuelve que el gateway no resuelve?**
Que cada canal tiene necesidades de datos y de forma muy distintas. El gateway es genérico; el BFF es específico de un canal y lo mantiene el equipo de ese canal, lo que elimina la negociación constante con los servicios de dominio. Coste: un componente por canal y posible duplicación de lógica de agregación entre BFFs.

**39. 🟠 Client-side discovery vs Server-side discovery.**
Client-side: el cliente consulta el registro y elige la instancia (Eureka + Ribbon clásico); más control y menos saltos, pero requiere librería en cada lenguaje. Server-side: un balanceador o el propio Kubernetes resuelve (Service + kube-proxy, o el mesh); transparente para el cliente y políglota, a costa de un salto más y de depender de la plataforma. En Kubernetes, server-side es lo natural.

**40. 🟡 Service Registry: ¿sigue siendo necesario con Kubernetes?**
El registro existe, pero lo provee la plataforma (etcd y los Endpoints de Kubernetes) en vez de un componente de aplicación como Eureka o Consul. La necesidad de registro no desaparece; se desplaza a la infraestructura. Consul sigue teniendo sentido en entornos híbridos con cargas fuera del cluster.

**41. 🟠 Self Registration vs 3rd Party Registration.**
Self: el servicio se registra y envía latidos; simple pero acopla el código al registro. Third-party: un componente externo detecta y registra las instancias (lo que hace Kubernetes con los probes). La segunda es preferible porque el servicio no necesita saber nada del registro, y es lo que permite políglota sin librerías.

**42. 🟠 Circuit Breaker: parámetros que hay que decidir y error frecuente.**
Umbral de fallo (porcentaje o número), ventana de medición (por conteo o por tiempo), duración del estado abierto, y número de pruebas en semiabierto. Error frecuente: configurarlo con los valores por defecto y no definir **qué se devuelve cuando está abierto**. Sin respuesta de degradación definida, el circuit breaker solo cambia un error lento por uno rápido.

**43. 🟠 Retry pattern: ¿cuáles son sus condiciones de uso?**
Solo sobre operaciones idempotentes, solo ante fallos transitorios (timeout, 503, error de red — nunca ante un 400 o un 409), con backoff exponencial y jitter, límite de intentos, y presupuesto global para que la amplificación entre capas no multiplique la carga. Un reintento ciego sobre una transferencia duplica dinero: en banca esta es una pregunta con consecuencias.

**44. 🟠 Bulkhead: ¿cómo lo implementas en una aplicación Java?**
Pools de hilos o semáforos separados por dependencia (Resilience4j ofrece ambos). El de semáforo limita concurrencia sin hilos extra; el de pool aísla completamente a costa de más recursos y cambio de contexto. El objetivo es que una dependencia degradada consuma solo su cuota y no agote los recursos comunes.

**45. 🟡 Timeout pattern: ¿por qué es el primero de todos?**
Porque sin timeout, una dependencia lenta retiene tus hilos indefinidamente y el fallo se propaga hacia arriba como saturación, no como error. Circuit breakers y bulkheads no sirven de nada si la llamada nunca termina. Además el timeout debe ser coherente con el presupuesto de latencia de toda la cadena.

**46. 🟠 Rate Limiting y Throttling: ¿dónde los aplicas?**
Preferentemente en el borde (gateway, ingress, WAF), donde detienes el tráfico antes de que consuma recursos internos. Dentro, para proteger dependencias frágiles (un core legacy) con límites de concurrencia. Decide la clave del límite —API key, usuario, IP— sabiendo qué fuga tiene cada una, y responde 429 con `Retry-After` para que el cliente coopere.

**47. 🟠 ¿Qué es el patrón Fallback y cómo decides qué devolver?**
La respuesta alternativa cuando la operación falla: valor cacheado, valor por defecto, respuesta parcial o error explícito. **La decisión es de negocio, no técnica**: mostrar un saldo desactualizado puede ser aceptable o inaceptable según el contexto, y eso lo define producto y cumplimiento, no el desarrollador. Documenta el fallback de cada dependencia.

**48. 🟠 Cache-Aside: ¿cómo funciona y qué problemas tiene?**
La aplicación consulta la caché; si falla, va a la fuente y almacena el resultado. Problemas: stampede al expirar una clave caliente (mutex, refresco anticipado o TTL con jitter), datos obsoletos, e invalidación correcta ante escrituras. Y la pregunta que siempre sigue: qué pasa cuando la caché no está disponible — ¿degradas o fallas?

**49. 🟡 Write-through, write-behind y read-through: ¿en qué se diferencian?**
Read-through: la caché consulta la fuente por ti al fallar. Write-through: escribes en caché y fuente sincrónicamente (consistente, más lento). Write-behind: escribes en caché y la persistencia se hace asíncrona (rápido, con riesgo de pérdida si la caché cae). En banca, write-behind sobre datos financieros es inaceptable salvo con garantías de durabilidad explícitas.

**50. 🟠 Competing Consumers: ¿qué escala y qué rompe?**
Escala el procesamiento repartiendo mensajes entre varios consumidores. Rompe el orden global. Compatible con orden solo por partición, con un consumidor por partición, lo que convierte el número de particiones en el techo de paralelismo — y ese número es difícil de aumentar después en Kafka sin alterar el reparto por clave.

**51. 🟠 Priority Queue: ¿cómo la implementas y qué riesgo tiene?**
Colas separadas por prioridad con consumidores asignados, o soporte nativo del broker. Riesgo principal: **inanición** de la cola de baja prioridad si la alta nunca se vacía. Mitigación: reservar capacidad mínima para la baja prioridad o promover mensajes por antigüedad.

**52. 🟠 Pipes and Filters: ¿cuándo lo aplicas?**
Descomponer un procesamiento complejo en etapas independientes conectadas por canales, cada una escalable por separado. Aplica bien a enriquecimiento, validación y transformación de flujos (un pipeline de transacciones que valida, enriquece, evalúa fraude y contabiliza). Coste: latencia acumulada por etapa y necesidad de idempotencia en cada una.

**53. 🟡 Scatter-Gather: ¿qué decisión de diseño exige?**
Exige decidir qué hacer con los que no responden a tiempo: ¿esperas a todos (latencia del más lento), respondes con lo que llegó (resultado parcial), o fallas? Es una decisión de producto. Sin timeout y respuesta parcial, el patrón hereda la disponibilidad del peor de sus participantes.

**54. 🟠 Request-Reply sobre mensajería: ¿cuándo vale la pena?**
Cuando necesitas respuesta pero quieres la durabilidad y el desacoplamiento de la cola (un flujo largo con reintentos garantizados). Su problema: reintroduces el acoplamiento temporal con más piezas (cola de respuesta, correlación, timeout). Si el usuario está esperando, una llamada HTTP bien protegida suele ser más simple y honesta.

**55. 🟠 ¿Qué es el patrón Choreography-based approval chain y dónde falla?**
Una cadena de aprobaciones donde cada servicio reacciona al evento del anterior. Falla en la visibilidad: nadie puede responder "¿en qué paso está la solicitud?" sin reconstruirlo desde trazas, y los timeouts entre pasos no tienen dueño. Para procesos de negocio con SLA y auditoría, la orquestación con estado explícito es la opción correcta.

**56. 🔴 Un equipo propone comunicar todos los servicios solo por eventos, sin ninguna llamada síncrona. ¿Qué opinas?**
Que el desacoplamiento total tiene un precio que hay que nombrar: toda lectura requiere réplicas locales mantenidas por eventos (más almacenamiento y más complejidad), la experiencia de usuario pasa a ser "en proceso" en vez de "hecho", y depurar un flujo requiere observabilidad madura. Es una arquitectura válida y muy resiliente, pero no es gratis ni es universalmente superior. Postura defendible: eventos para propagación de hechos y procesos largos; llamadas síncronas bien protegidas donde el usuario espera una respuesta inmediata y el dato debe ser autoritativo. El dogma en cualquiera de las dos direcciones es la señal de alarma.

---

## 🚀 Parte 4 — Despliegue y operación (57–76)

**57. 🟢 Service Instance per Container: ¿por qué se impuso?**
Aislamiento de recursos y dependencias, empaquetado uniforme independiente del lenguaje, arranque rápido y densidad. Frente a "instancia por VM" (más aislamiento, más lento y caro) y "múltiples servicios por host" (barato, con interferencias y conflictos de dependencias). El contenedor ganó por la combinación de aislamiento suficiente y coste bajo.

**58. 🟡 Serverless Deployment: ¿cuándo es la mejor opción para un microservicio?**
Cargas esporádicas o muy variables, procesamiento dirigido por eventos, y equipos que quieren cero operación de infraestructura. No es la mejor opción para servicios de latencia crítica (arranque en frío), procesos largos, o cuando necesitas conexiones persistentes a base de datos — los pools no encajan bien con el modelo de invocación, y ahí hacen falta proxies de conexión.

**59. 🟠 Sidecar vs librería para capacidades transversales: ¿cómo decides?**
Librería: menos latencia y menos recursos, pero acopla en compilación y obliga a versión por lenguaje; actualizar la librería implica redesplegar todos los servicios. Sidecar: independiente del lenguaje y actualizable sin tocar el código, con coste de recursos y de operación. Con un solo stack y pocos servicios, librería; con políglota y escala, sidecar o mesh.

**60. 🟠 Service Mesh: ¿qué te da y cuál es su curva de coste?**
mTLS automático, reintentos y timeouts declarativos, circuit breaking, enrutamiento por porcentaje (canary), y telemetría uniforme sin tocar el código. La curva de coste: consumo de recursos por sidecar, latencia adicional, y una plataforma compleja que alguien debe entender cuando falle. Con menos de diez o quince servicios homogéneos, rara vez compensa.

**61. 🟡 Blue-Green Deployment: ¿qué resuelve y qué no?**
Resuelve el rollback instantáneo cambiando el tráfico entre dos entornos completos. No resuelve la migración de esquema: la base de datos es compartida y no tiene "verde" y "azul", así que los cambios de datos deben ser compatibles hacia atrás igualmente. Cuesta el doble de infraestructura durante la transición.

**62. 🟠 Canary Release: ¿qué necesitas tener antes de poder usarlo?**
Métricas confiables y comparables entre la versión nueva y la vieja (tasa de error, latencia, métricas de negocio), y automatización que decida promover o revertir. Sin métricas fiables, un canary es solo un despliegue lento. Añade un criterio de salida explícito y un tiempo mínimo de observación.

**63. 🟡 Feature Toggle: ¿qué disciplina exige?**
Cada flag con dueño, propósito y **fecha de retiro**. Sin eso, la aplicación acumula un espacio de estados combinatorio que nadie puede probar ni razonar — riesgo operacional real en banca. Distingue tipos: release (temporales), operacionales (kill switch), de permiso (permanentes por diseño) y de experimento.

**64. 🟠 ¿Cómo combinas feature flags con despliegue continuo en banca?**
Desplegar no es liberar: el código llega a producción desactivado y negocio decide cuándo activar, incluso por segmento de clientes. Eso reduce el riesgo del despliegue y permite kill switch inmediato sin rollback. Requisito: el código desactivado debe ser seguro y estar probado en ambos estados, no solo en el activo.

**65. 🟡 Externalized Configuration: ¿cuál es la regla?**
Nada específico del entorno dentro del artefacto: la misma imagen debe poder ejecutarse en desarrollo, preproducción y producción cambiando solo variables externas. Secretos en un gestor dedicado con rotación. Si necesitas recompilar para cambiar de entorno, has roto el principio y con él la trazabilidad del artefacto.

**66. 🟡 Health Check API: ¿qué debe y qué no debe comprobar?**
Readiness: lo que impide atender **ahora** (base de datos propia, dependencias críticas), con timeout corto. Liveness: solo si el proceso está irrecuperable. Nunca metas dependencias externas en el liveness: un fallo transitorio del proveedor provocaría reinicios masivos y empeoraría el incidente. Los health checks deben ser baratos porque se ejecutan constantemente.

**67. 🟠 Application Metrics: ¿qué modelo usas y qué peligro tiene?**
Micrometer o OpenTelemetry exportando a Prometheus. Peligro principal: **cardinalidad**. Etiquetar métricas con identificadores de usuario, de cuenta o de petición multiplica las series y hace explotar el coste y el rendimiento del backend de métricas. Las etiquetas deben ser de cardinalidad acotada y conocida.

**68. 🟠 Distributed Tracing: ¿qué decisiones de diseño requiere?**
Propagación de contexto (W3C Trace Context), instrumentación automática más spans manuales en los puntos de negocio, y estrategia de muestreo: 100% es caro, un muestreo bajo pierde los casos raros que justamente investigas. Solución habitual: muestreo adaptativo con captura forzada de los errores y de las peticiones lentas.

**69. 🟡 Log Aggregation: ¿qué prácticas lo hacen útil?**
Logs estructurados en JSON, identificador de correlación en cada línea, niveles usados con criterio, enmascaramiento de datos sensibles, y retención definida por coste y por regulación. El anti-patrón es loguear todo "por si acaso": encarece, ralentiza y entierra la señal en ruido.

**70. 🟠 Exception Tracking: ¿en qué se diferencia del logging?**
Agrupa excepciones idénticas, las deduplica, cuenta ocurrencias y notifica solo lo nuevo o lo que cambia de frecuencia (Sentry y similares). Frente al log plano, convierte diez mil líneas iguales en un incidente con tendencia. Útil para detectar regresiones tras un despliegue.

**71. 🟠 Audit Logging: ¿qué lo diferencia del logging técnico?**
Los logs técnicos se rotan y se borran; la auditoría es un requisito legal con retención definida, almacenamiento inmutable append-only, y contenido obligatorio: actor, acción, recurso, momento y resultado. Nunca deben mezclarse en el mismo pipeline ni con la misma política de retención.

**72. 🟠 Health Check + Circuit Breaker + Service Discovery: ¿cómo interactúan?**
El health check hace que la plataforma retire la instancia enferma del balanceo (discovery); el circuit breaker protege al llamador mientras esa retirada ocurre, porque nunca es instantánea. Sin health checks, el circuit breaker trabaja de más; sin circuit breaker, los segundos de retraso en la retirada se traducen en errores para los usuarios. Son complementarios, no alternativos.

**73. 🟠 Sidecar de logs y agentes: ¿qué patrón prefieres hoy?**
DaemonSet que recolecta de los nodos, frente a un sidecar por pod. El DaemonSet consume muchos menos recursos y es lo habitual en Kubernetes; el sidecar solo se justifica cuando un servicio necesita un procesamiento de logs particular. Y la aplicación debe escribir a stdout, no a archivos, para no acoplarse al mecanismo de recolección.

**74. 🟠 ¿Qué es el patrón de Service Template / plantilla de servicio?**
Un esqueleto generado que ya trae pipeline, observabilidad, health checks, seguridad, estructura y convenciones. Su valor: hace que el camino correcto sea también el más rápido, que es la única forma realista de que los estándares se cumplan. Sin plantilla, cada equipo reinventa lo mismo con calidad desigual.

**75. 🟡 ¿Qué es el Service Catalog / Developer Portal?**
Registro de servicios con dueño, dependencias, documentación, criticidad y enlaces operativos (Backstage). Necesario a partir de unos quince servicios, cuando nadie tiene ya el mapa completo. En un incidente, la primera pregunta siempre es "¿de quién es esto y a quién llamo?".

**76. 🔴 ¿Qué patrones de despliegue exigirías como estándar mínimo en un banco?**
Externalized configuration con secretos gestionados y rotados; health checks con readiness y liveness bien separados; despliegue progresivo (canary o rolling) con rollback automático por métricas; migraciones expand/contract obligatorias; feature flags con dueño y fecha; GitOps para trazabilidad y separación de funciones; y artefacto inmutable con trazabilidad hasta el commit y el ticket. Todo verificado automáticamente en el pipeline, porque un estándar que vive en una wiki se incumple en tres sprints.

---

## 🔐 Parte 5 — Seguridad, pruebas y patrones transversales (77–100)

**77. 🟡 Access Token pattern: ¿cómo se propaga la identidad entre servicios?**
El borde autentica y emite un token que viaja en las llamadas internas; cada servicio lo **valida por sí mismo** en vez de confiar en que alguien ya lo hizo. Alternativas: reenvío del token original, token exchange para acotar audiencia y alcance, o un token de servicio que incluya el sujeto original firmado.

**78. 🟠 ¿Cuál es el riesgo del "confused deputy" y cómo lo evitas?**
Que un servicio interno actúe con sus propios privilegios en nombre de un usuario que no tenía permiso, típicamente porque confía en un header `X-User-Id` sin validar. Se evita con confianza cero hacia dentro: validación de token en cada servicio, mTLS para autenticar al llamante, y autorización evaluada con la identidad real del usuario, no con la del servicio.

**79. 🟡 ¿Qué es mTLS y por qué se considera un patrón de microservicios?**
Autenticación mutua por certificado entre servicios, de forma que ambos extremos se identifican criptográficamente y el tráfico interno va cifrado. Es patrón porque resuelve la premisa falsa de "la red interna es segura". Gestionarlo a mano es inviable: por eso lo asume el mesh o la plataforma, con rotación automática.

**80. 🟠 ¿Cómo aplicas autorización distribuida sin duplicar reglas en cada servicio?**
Motor de políticas centralizado con evaluación local (OPA como sidecar, por ejemplo): las políticas se definen y versionan en un lugar y se evalúan junto al servicio, sin llamada de red en el camino crítico. Alternativa más simple: claims en el token para decisiones gruesas y reglas de dominio en el servicio dueño para las finas, que es donde deben estar.

**81. 🟠 ¿Qué patrón usas para secretos y rotación?**
Secretos en un gestor dedicado (Vault, Secrets Manager) con inyección en ejecución y rotación automática; la aplicación debe soportar la recarga o el reinicio controlado. Nunca en la imagen, el repositorio o variables de entorno definidas en el manifiesto en claro. Añade escaneo en el pipeline y auditoría de accesos, que en banca se revisa.

**82. 🟡 Consumer-Driven Contract Testing: ¿qué problema resuelve?**
Que el productor rompa a un consumidor sin enterarse hasta producción. El consumidor publica sus expectativas y el productor las verifica en su pipeline. Sustituye a la mayoría de pruebas E2E, que son lentas y frágiles, manteniendo la confianza en la compatibilidad. Herramientas: Pact, Spring Cloud Contract.

**83. 🟠 Service Component Test: ¿qué alcance tiene?**
Probar un servicio completo de forma aislada, con sus dependencias externas simuladas (WireMock) y su base de datos real (Testcontainers). Es el nivel más rentable en microservicios: verifica el servicio de punta a punta sin necesitar todo el ecosistema levantado, y es determinista.

**84. 🟠 ¿Cómo pruebas una saga completa?**
Por niveles: unitarias de las transiciones y compensaciones; de componente para el orquestador con los participantes simulados, incluyendo escenarios de fallo en cada paso y de timeout; y una E2E sobre el flujo feliz más un flujo compensado. Lo que casi nadie prueba y siempre rompe: el camino de **compensación** y el mensaje duplicado.

**85. 🟠 ¿Qué es el patrón de "test in production" y cómo se hace responsablemente?**
Validar en producción con tráfico real mediante canary, shadow traffic (duplicar peticiones reales hacia la versión nueva sin usar su respuesta) y observabilidad fina. Responsablemente: radio de impacto acotado, sin efectos de escritura en el shadow, capacidad de abortar inmediata, y aprobación previa. Es reconocimiento de que ningún entorno de pruebas replica producción.

**86. 🟠 ¿Qué es shadow traffic y qué cuidado exige en banca?**
Duplicar peticiones reales hacia la versión nueva para comparar comportamiento, descartando su respuesta. Cuidado crítico: el servicio sombra **no puede escribir ni llamar a sistemas externos**, o duplicarías operaciones reales. Debe correr con dependencias aisladas o en modo solo lectura.

**87. 🟡 ¿Qué es el patrón de Compensating Transaction fuera de la saga?**
Cualquier operación que revierte un efecto ya confirmado, cuando no hay rollback posible: anular un cargo, emitir una nota crédito, reversar una transferencia. En banca es el mecanismo normal: el libro mayor no se edita, se corrige con asientos adicionales. Diseñar la compensación es parte de diseñar la operación, no un añadido.

**88. 🟠 ¿Qué es el patrón Leader Election y cuándo lo necesitas?**
Elegir una instancia entre varias para ejecutar una tarea que debe ocurrir **una sola vez** (un job programado, un consumidor único, un coordinador). Implementaciones: bloqueo distribuido en base de datos, Redis, ZooKeeper o etcd, o ShedLock en el mundo Spring. Sin él, cada réplica ejecuta el job — y en banca eso significa cobrar dos veces.

**89. 🟠 ¿Qué es el patrón Sharding y qué decides al aplicarlo?**
Repartir datos y carga por una clave (cliente, cuenta, región). Decides: la clave de sharding (irreversible en la práctica y determinante para el rendimiento), cómo manejar claves calientes, y cómo hacer consultas que crucen shards (normalmente vía un índice o una proyección global). Un mal criterio de sharding es de los errores más caros de corregir.

**90. 🟠 ¿Qué es el patrón Queue-Based Load Leveling?**
Interponer una cola entre el productor y el procesador para absorber picos: el consumidor procesa a su ritmo sostenible en vez de colapsar. Aplica muy bien a cargas con ráfagas (fin de mes, día de pago). Condición: el negocio debe aceptar latencia variable, y hay que vigilar la profundidad de la cola como métrica de salud.

**91. 🟠 ¿Qué es el patrón Gateway Offloading?**
Delegar en el gateway lo transversal y costoso: terminación TLS, compresión, autenticación, WAF, rate limiting. Libera a los servicios de trabajo repetido y centraliza la configuración de seguridad. Riesgo: convertir el gateway en cuello de botella de rendimiento y de despliegue si todos los equipos deben modificarlo.

**92. 🟠 ¿Qué es el patrón Static Content Hosting y por qué aparece en arquitecturas de microservicios?**
Servir contenido estático desde almacenamiento de objetos y CDN en vez de desde la aplicación. Reduce carga, latencia y coste, y separa el ciclo de vida del frontend del backend. En banca aplica además a documentos generados (extractos, certificados) servidos con URLs prefirmadas de vida corta.

**93. 🟠 ¿Qué es el patrón Valet Key / URL prefirmada?**
Dar al cliente un token de acceso directo y limitado al almacenamiento, para que suba o descargue sin que el archivo atraviese tu aplicación. Ahorra ancho de banda, memoria y tiempo de tus servicios. Controles obligatorios: expiración corta, permisos mínimos y ruta específica, porque la URL es la credencial.

**94. 🟠 ¿Qué es el patrón Deployment Stamps / células?**
Replicar un conjunto completo e independiente de la arquitectura por grupo de clientes, región o segmento. Ventajas: aislamiento del radio de impacto (un fallo afecta a una célula), escalado por multiplicación y despliegue progresivo natural por células. Coste: más infraestructura y la necesidad de un enrutador que sepa a qué célula pertenece cada cliente.

**95. 🟠 ¿Qué es el patrón Anti-pattern "Nano-service" y cómo lo detectas?**
Servicios tan pequeños que el coste de comunicarlos supera al beneficio de separarlos: un servicio por operación o por tabla. Detección: alta proporción de llamadas de red por caso de uso, servicios que nunca se despliegan solos, y equipos que mantienen decenas de repositorios triviales. La corrección es consolidar, y es una decisión de ingeniería legítima.

**96. 🟠 ¿Qué patrones combinarías para un flujo de pago de punta a punta?**
API Gateway en el borde con rate limiting y autenticación; idempotencia por clave en el endpoint; saga orquestada con estado explícito y compensaciones por contra-asiento; outbox para publicar eventos de forma fiable; consumidores idempotentes con inbox; circuit breaker y timeout hacia el core y hacia la red de pagos; conciliación periódica como red de seguridad; y tracing distribuido con identificador de correlación en todo el flujo. Ese conjunto es prácticamente el estándar de facto.

**97. 🔴 ¿Qué patrón consideras más subestimado y cuál más sobreaplicado?**
Más subestimado: **Transactional Outbox** y la conciliación periódica — ambos poco glamurosos y ambos evitan la clase de incidente más cara (dinero que se movió sin que nadie lo registre, o al revés). Más sobreaplicado: **Event Sourcing** aplicado a todo el sistema en vez de a los agregados que lo justifican, y **Service Mesh** en organizaciones con ocho servicios homogéneos, donde una librería costaría una fracción.

**98. 🔴 ¿Cómo decides si un patrón aplica a tu caso?**
Tres preguntas obligatorias: ¿qué problema **medido** resuelve aquí y ahora?, ¿qué complejidad añade y quién la opera a las 3 a.m.?, ¿qué alternativa más simple descarté y por qué? Si no puedes responder las tres, todavía no es una decisión de arquitectura, es una preferencia. Documéntalo como ADR con las consecuencias, no solo con la elección.

**99. 🔴 Un equipo implementó saga, CQRS, event sourcing y service mesh para un sistema con 4 servicios y 200 usuarios. ¿Qué haces?**
Primero entender por qué: puede haber una razón válida (previsión de crecimiento acordada, requisito regulatorio de auditoría) o puede ser entusiasmo. Después medir el coste: tiempo de entrega, número de incidentes, cuánto tarda alguien nuevo en ser productivo, y cuánto del tiempo del equipo se va en operar la plataforma en vez de entregar valor. Si el coste es desproporcionado, propón simplificación incremental empezando por lo que más cuesta operar y menos aporta — probablemente el mesh —, no un rediseño total. Y hazlo sin humillar a nadie: el equipo tomó decisiones razonables con la información que tenía, y la conversación debe ser sobre coste y beneficio medidos, no sobre quién se equivocó.

**100. 🔴 Si tuvieras que enseñar patrones de microservicios a un equipo que viene de monolito, ¿en qué orden lo harías?**
Primero lo que evita pérdidas de datos y de dinero, porque es lo que más duele si falta: idempotencia, outbox, y consumidores idempotentes. Después lo que evita caídas: timeouts, reintentos con backoff y jitter, circuit breaker y degradación. Luego observabilidad, porque sin ella nada de lo anterior es diagnosticable. Y solo al final los patrones de datos avanzados (CQRS, event sourcing, saga), cuando ya duela un problema real que los justifique. El orden importa: enseñarlo al revés produce equipos que implementan event sourcing sin timeouts, que es exactamente cómo se cae un sistema en producción.

---

> 🧭 **Cierre:** ningún entrevistador senior espera que recites el catálogo. Esperan que, ante un problema concreto, nombres dos patrones candidatos, digas **qué cuesta cada uno**, elijas uno y expliques qué tendría que ocurrir para que cambiaras de opinión. Esa última parte —las condiciones de revisión de tu propia decisión— es la que casi nadie da y la que más distingue a un arquitecto.
