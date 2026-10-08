# 🧩 100 preguntas de entrevista — Microservicios

> Enfoque práctico de arquitecto: decisión, fronteras, comunicación, datos, resiliencia y operación.
> El catálogo de patrones con nombre propio está en `preguntas_06_patrones_microservicios.md`.
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

---

## 🎯 Parte 1 — Decisión y fundamentos (1–16)

**1. 🟢 ¿Qué es un microservicio y qué NO lo es?**
Un servicio desplegable de forma independiente, con su propio ciclo de vida, dueño de sus datos y alineado a una capacidad de negocio. **No** lo es: un servicio pequeño que comparte base de datos con otros (eso es un monolito distribuido), ni uno que solo puede desplegarse coordinado con otros, ni una capa técnica extraída (un "servicio de validaciones"). El criterio decisivo es la **independencia de despliegue**.

**2. 🟡 ¿Cuál es el beneficio real de los microservicios?**
Autonomía de equipos: varios equipos pueden desplegar a ritmos distintos sin coordinarse. Todo lo demás (escalado independiente, aislamiento de fallos, libertad tecnológica) es secundario y a menudo alcanzable de otras formas. Si tienes un solo equipo, el beneficio principal no aplica y estás pagando el coste sin recibir el pago.

**3. 🟡 ¿Cuáles son los costes de los microservicios?**
Latencia de red donde antes había llamadas en memoria, consistencia eventual, depuración distribuida, complejidad operativa (despliegues, observabilidad, secretos, certificados), pruebas de integración difíciles, y un coste de infraestructura mayor. Es honesto decir que el coste es **organizativo** tanto como técnico: necesitas madurez de CI/CD y de on-call.

**4. 🟠 ¿Cuándo NO usarías microservicios?**
Equipo pequeño (menos de dos o tres equipos reales), dominio poco entendido (aún no sabes dónde están las fronteras, y equivocarte es carísimo), sin CI/CD ni observabilidad maduras, requisitos de transaccionalidad fuerte entre módulos, o una startup buscando encaje de producto. El monolito modular es la respuesta correcta mucho más a menudo de lo que se admite.

**5. 🟠 ¿Qué es un monolito distribuido y cómo lo reconoces?**
Servicios separados con todos los costes de la distribución y ninguno de los beneficios. Señales: base de datos compartida, despliegues que deben coordinarse, una cadena de llamadas síncronas donde cualquier servicio caído tumba el flujo, y librerías compartidas con el modelo de dominio. Es el peor resultado posible y el más común en migraciones apresuradas.

**6. 🟡 ¿Qué es el "monolito primero" y estás de acuerdo?**
La recomendación de Fowler: empieza con un monolito bien modularizado y extrae servicios cuando las fronteras se hayan revelado. Estoy de acuerdo con un matiz: solo funciona si el monolito se construye con **fronteras internas reales** (Spring Modulith, ArchUnit verificando que un módulo no importa las entrañas de otro). Un monolito sin disciplina interna no se puede trocear después.

**7. 🟠 ¿Qué tamaño debe tener un microservicio?**
No se mide en líneas de código. Criterios útiles: que un equipo pequeño pueda entenderlo y mantenerlo completo, que corresponda a un bounded context, que se pueda reescribir en pocas semanas si hiciera falta, y que tenga una razón de cambio coherente. Si dos áreas de negocio distintas piden cambios sobre él cada sprint, es demasiado grande o está mal cortado.

**8. 🟡 ¿Qué significa "smart endpoints, dumb pipes"?**
La lógica vive en los servicios, no en la infraestructura de integración. Es la reacción explícita al ESB, donde el bus acumulaba reglas de negocio y se convertía en un monolito de integración con un cuello organizativo. El broker debe transportar, no decidir.

**9. 🟠 ¿Qué relación tiene la Ley de Conway con los microservicios?**
Un sistema refleja la estructura de comunicación de la organización. Consecuencia: si defines microservicios pero mantienes un equipo de base de datos central que controla todos los esquemas, no tendrás autonomía real. La "maniobra Conway inversa" es organizar los equipos según la arquitectura deseada, y es la palanca más potente y menos usada de una transformación.

**10. 🟠 ¿Qué es un equipo "two-pizza" y por qué importa?**
Un equipo lo bastante pequeño para coordinarse sin sobrecarga (típicamente 5 a 9 personas), dueño de sus servicios de punta a punta, incluido el on-call. Importa porque el límite real de los microservicios no es técnico: es cuántos servicios puede operar responsablemente un equipo.

**11. 🟡 ¿Qué es "you build it, you run it"?**
El equipo que construye el servicio lo opera y responde por él en producción. Alinea incentivos: quien sufre la guardia a las 3 a.m. escribe mejores logs, mejores alertas y mejores despliegues. Sin esto, los microservicios producen un equipo de operaciones sepultado bajo sistemas que no entiende.

**12. 🟠 ¿Cómo mides si tu arquitectura de microservicios está funcionando?**
Métricas DORA: frecuencia de despliegue, lead time, tasa de fallo en cambios y tiempo de recuperación. Si tras adoptar microservicios despliegas menos y tardas más en recuperarte, la arquitectura está fallando por mucho que el diagrama sea bonito. Añade indicadores de acoplamiento: cuántos servicios hay que desplegar juntos para entregar una funcionalidad.

**13. 🟠 ¿Cuántos microservicios son demasiados?**
Cuando el coste de coordinación supera al de la autonomía: nadie entiende el flujo completo, un cambio de negocio toca ocho servicios, y la observabilidad no alcanza a explicar un incidente. Señal concreta y práctica: si tu equipo de cinco personas mantiene veinte servicios, has cambiado complejidad de código por complejidad operativa sin ganar nada.

**14. 🟡 ¿Microservicios significa que cada uno puede usar un lenguaje distinto?**
Técnicamente sí, y es uno de los argumentos de venta. En la práctica, la poliglotía sin control multiplica el coste: cada stack necesita pipeline, librerías corporativas, observabilidad, parcheo de seguridad y gente que lo mantenga a las 3 a.m. Postura sensata: un stack principal estándar, con excepciones justificadas y aprobadas.

**15. 🟠 ¿Qué es una plataforma interna de desarrollo y por qué la necesitas?**
Un conjunto de capacidades listas (plantillas de servicio, pipeline, observabilidad, secretos, despliegue) para que un equipo cree un servicio productivo en horas y no en semanas. Sin ella, cada equipo reinventa lo mismo con distinta calidad, y la seguridad se vuelve inconsistente. En una organización con muchos servicios, la plataforma es la diferencia entre escalar y ahogarse.

**16. 🔴 Un director te dice "queremos microservicios porque somos lentos entregando". ¿Qué respondes?**
Que la lentitud rara vez la causa el monolito por sí mismo: suele venir de pruebas manuales, ausencia de CI/CD, aprobaciones seriales, o un equipo único sobrecargado. Propón medir primero (lead time, dónde se van los días), y arreglar lo que salga: automatizar pruebas y despliegue, modularizar el monolito, reorganizar equipos por dominio. Si tras eso el cuello sigue siendo la coordinación entre equipos para desplegar, entonces sí extraes servicios. Cambiar de arquitectura sin arreglar el proceso produce los mismos retrasos con más piezas.

---

## ✂️ Parte 2 — Descomposición y fronteras (17–30)

**17. 🟡 ¿Cómo decides las fronteras de un microservicio?**
Por capacidad de negocio o bounded context, no por capa técnica ni por entidad de base de datos. Herramienta práctica: event storming con expertos de negocio para descubrir eventos, comandos y agregados, y ver dónde cambian los términos de significado. La frontera correcta es aquella donde un cambio de negocio se queda dentro de un solo servicio.

**18. 🟠 ¿Por qué "un servicio por entidad" es un error?**
Porque produce servicios anémicos que no hacen nada solos y requieren llamadas constantes entre sí para cualquier caso de uso: acoplamiento máximo, latencia acumulada y transacciones imposibles. Un servicio debe contener un caso de uso completo, no una tabla.

**19. 🟠 ¿Qué es un bounded context y cómo lo identificas en banca?**
La frontera donde un término tiene un único significado. En banca es evidente: "cliente" significa cosas distintas en originación (un solicitante con documentos), en core bancario (un titular con productos) y en cobranza (una deuda con historial de contacto). Cada uno merece su modelo, y forzar un modelo único de "cliente" para todo el banco es el proyecto que nunca termina.

**20. 🟠 ¿Qué haces cuando dos servicios necesitan los mismos datos?**
Primero pregunta qué necesitan exactamente: a menudo uno necesita un subconjunto pequeño y estable. Opciones: consultar al dueño de forma síncrona (acoplamiento temporal), replicar por eventos manteniendo una copia local de solo lectura (consistencia eventual, es la opción habitual), o reconsiderar la frontera si ambos modifican el mismo dato — eso indica que el corte está mal.

**21. 🟡 ¿Qué es la propiedad de los datos y por qué es innegociable?**
Cada dato tiene **un** servicio dueño que lo escribe; los demás lo leen por API o por réplica derivada. Es innegociable porque, sin dueño único, ninguna invariante puede garantizarse y nadie puede evolucionar el esquema. La base de datos compartida es lo que convierte microservicios en un monolito distribuido.

**22. 🟠 ¿Cómo descompones un monolito existente? Da un orden concreto.**
Strangler fig: primero identifica costuras (módulos con poco acoplamiento), empieza por lo periférico y de bajo riesgo (notificaciones, reportes, catálogos), no por el core transaccional. Pasos por servicio: extraer el módulo dentro del monolito con una interfaz clara, separar sus tablas, desplegarlo aparte con una fachada que enrute, y solo entonces retirar el código viejo. Cada paso reversible, y el monolito sigue funcionando en todo momento.

**23. 🟠 ¿Cómo separas tablas que están unidas por foreign keys entre dos futuros servicios?**
Eliminas la FK y la sustituyes por referencia lógica (guardas el id sin restricción). La integridad deja de garantizarla la base de datos y pasa a garantizarla el proceso: validación en el servicio, y un proceso de conciliación que detecta huérfanos. Duele decirlo, pero es inevitable: **renuncias a la integridad referencial entre servicios** a cambio de autonomía, y hay que declararlo abiertamente ante el DBA y ante negocio.

**24. 🟠 ¿Qué es una librería compartida y cuándo es peligrosa?**
Es peligrosa cuando contiene modelo de dominio o lógica de negocio: se convierte en acoplamiento en tiempo de compilación, y actualizarla obliga a redesplegar todos los servicios de forma coordinada — justo lo que querías evitar. Es aceptable para cosas técnicas y estables: clientes de observabilidad, utilidades de logging, convenciones de seguridad. Regla: si cambiarla obliga a desplegar todo, deja de ser una librería y es un monolito disfrazado.

**25. 🟠 ¿Qué es un servicio "orquestador" y cuándo está justificado?**
Un servicio que coordina un proceso de negocio que atraviesa varios servicios. Está justificado cuando el flujo es complejo, tiene compensaciones, timeouts y debe ser auditable — como una originación de crédito. No está justificado cuando solo agrega respuestas: eso es un BFF o una composición de API, y no debe acumular reglas.

**26. 🟠 ¿Qué haces si una funcionalidad nueva no encaja en ningún servicio existente?**
Es una señal valiosa, no un problema. Puede significar un bounded context nuevo (crea el servicio), o que tus fronteras actuales están mal y la funcionalidad revela el corte correcto. Lo que **no** debes hacer es meterla en el servicio "que más se le parece" por comodidad: así es como los servicios se convierten en monolitos pequeños.

**27. 🟠 ¿Cómo evitas el acoplamiento por contrato entre servicios?**
Contratos explícitos y versionados (OpenAPI, schema registry), cambios solo aditivos, compatibilidad hacia atrás y hacia adelante, pruebas de contrato en el pipeline, y **nunca** exponer el modelo interno como contrato público. El evento de integración debe ser deliberadamente más pobre y estable que el modelo de dominio interno.

**28. 🟡 ¿Qué es un "servicio conformista" y cuándo lo aceptas?**
Cuando un contexto adopta el modelo de otro tal cual, sin traducirlo, porque no tiene poder de negociación (típicamente ante un core bancario o un proveedor externo). Se acepta cuando el coste de traducir supera al de conformarse y el modelo ajeno es tolerable. Si el modelo ajeno es tóxico, construyes un anti-corruption layer.

**29. 🟠 ¿Cómo gestionas funcionalidad transversal (auditoría, autorización, feature flags) sin duplicarla?**
Tres opciones con distinto coste: librería compartida (acoplamiento de compilación, pero simple), sidecar o service mesh (sin acoplamiento de código, más complejidad operativa), o un servicio dedicado (llamada de red, punto de fallo). Criterio: lo puramente técnico y de red al mesh; lo que necesita contexto de dominio, en el servicio; y la librería solo para convenciones estables.

**30. 🔴 Te piden dividir un core bancario de 2 millones de líneas en microservicios. ¿Por dónde empiezas?**
No por dividir. Primero: entender qué flujos existen y cuáles cambian de verdad (el 80% del código suele estar congelado), y medir dónde duele — si nada cambia ahí, dividirlo no aporta valor. Después: strangler fig por los bordes, empezando por canales digitales y consultas, dejando el motor transaccional al final o incluso sin tocar. El core puede seguir siendo la fuente de verdad durante años detrás de un anti-corruption layer. Y una verdad que hay que decir en la entrevista: **el objetivo no es "tener microservicios", es reducir el tiempo de entrega de los cambios que el negocio pide**; si eso se logra sin partir el core, es un éxito, no una rendición.

---

## 📡 Parte 3 — Comunicación entre servicios (31–48)

**31. 🟢 Síncrono vs asíncrono: ¿cómo decides?**
Síncrono cuando el llamador necesita la respuesta para continuar y el usuario está esperando. Asíncrono cuando puedes desacoplar en el tiempo. El argumento decisivo: cada llamada síncrona en cadena **multiplica** la probabilidad de fallo y **suma** latencias. Cinco servicios al 99.9% dan 99.5% de disponibilidad combinada.

**32. 🟡 ¿Cuáles son los estilos de comunicación y sus trade-offs?**
Uno a uno síncrono (REST, gRPC): simple, acoplamiento temporal. Uno a uno asíncrono (cola con respuesta): desacoplado, más complejo. Uno a muchos asíncrono (pub/sub de eventos): máximo desacoplamiento, consistencia eventual. La regla: **comandos** punto a punto, **eventos** a pub/sub.

**33. 🟡 REST vs gRPC: ¿cuándo cada uno?**
REST/JSON: universal, legible, cacheable por HTTP, ideal para APIs públicas o consumidas por navegadores. gRPC: binario, contrato fuerte con Protobuf, HTTP/2 con multiplexación y streaming, mucho más eficiente — ideal para comunicación interna de alto volumen y baja latencia. Coste de gRPC: menos legible al depurar, peor soporte en navegador, y necesita generación de código en el pipeline.

**34. 🟠 ¿Qué es GraphQL y cuándo tiene sentido entre microservicios?**
Permite al cliente pedir exactamente los campos que necesita, agregando varias fuentes. Tiene sentido en la capa de borde (BFF) cuando hay muchos clientes con necesidades distintas. Costes que hay que nombrar: dificultad para cachear, consultas costosas o maliciosas (necesitas límite de profundidad y de complejidad), el problema N+1 en los resolvers (se mitiga con dataloaders), y autorización campo a campo. No es un reemplazo de la comunicación interna entre servicios.

**35. 🟡 ¿Qué es el acoplamiento temporal y cómo lo eliminas?**
Que el llamador y el llamado deban estar disponibles **al mismo tiempo**. Se elimina con mensajería: el productor publica y sigue, el consumidor procesa cuando puede. El coste es consistencia eventual y una experiencia de usuario distinta: en vez de "listo", dices "en proceso", y eso hay que diseñarlo en la UI, no solo en el backend.

**36. 🟠 ¿Qué es la comunicación dirigida por eventos y qué problema introduce?**
Los servicios publican hechos y otros reaccionan, sin que el productor conozca a los consumidores. Máximo desacoplamiento. El problema que introduce: **nadie tiene el flujo completo escrito en ninguna parte**. Entender por qué ocurrió algo requiere reconstruir la cadena desde trazas y logs. Por eso los flujos críticos y auditables suelen orquestarse, aunque el resto sea coreografía.

**37. 🟠 Coreografía vs orquestación: defiende ambas.**
Coreografía: desacoplada, sin punto central, cada servicio autónomo; difícil de depurar y de auditar, y el flujo es implícito. Orquestación: flujo explícito, testeable, con timeouts y compensaciones visibles; introduce un componente que conoce a todos y puede convertirse en cuello de acoplamiento. En banca, donde hay que demostrarle a un auditor cómo se ejecuta un proceso, la orquestación suele ganar en lo crítico.

**38. 🟡 ¿Qué garantías de entrega existen y cuál es realista?**
At-most-once (puedes perder), at-least-once (puedes duplicar), exactly-once (ideal). La realista en sistemas distribuidos es **at-least-once + consumidores idempotentes**, que es funcionalmente equivalente a exactly-once. El "exactly-once" que ofrecen algunas plataformas aplica dentro de sus fronteras, no de punta a punta con tu base de datos y tus efectos externos.

**39. 🟠 ¿Cómo haces idempotente a un consumidor?**
Identificador único de mensaje persistido en una tabla de procesados (con la misma transacción que el efecto), o restricción única sobre una clave natural del negocio, o condition expression en el almacén. Alternativa elegante cuando aplica: diseñar la operación como naturalmente idempotente (establecer un estado en vez de incrementarlo).

**40. 🟠 ¿Cómo garantizas el orden de los eventos y qué sacrificas?**
Particionando por clave de negocio (todos los eventos de una cuenta a la misma partición) con un consumidor por partición. Sacrificas paralelismo: el orden pone techo al escalado, y una clave caliente se vuelve cuello de botella. Alternativa: diseñar operaciones conmutativas o incluir número de secuencia y descartar eventos viejos, de modo que el orden deje de importar.

**41. 🟡 Kafka vs RabbitMQ vs SQS: ¿cómo eliges?**
Kafka: log distribuido con retención, permite reprocesar desde el pasado y múltiples consumidores independientes; ideal para streaming de eventos de alto volumen. RabbitMQ: broker tradicional con enrutamiento sofisticado, bueno para colas de trabajo y RPC. SQS: gestionado, simple, sin operación; una vez consumido el mensaje se acabó. El diferenciador principal de Kafka es la **retención y la relectura**.

**42. 🟠 ¿Qué es una Dead Letter Queue y qué política le pones?**
Destino de los mensajes que no se pudieron procesar tras agotar reintentos. Política obligatoria: alerta al primer mensaje (una DLQ silenciosa es un incidente invisible), conservar el mensaje original y la causa, y un procedimiento de reproceso probado. En banca, cada mensaje en la DLQ representa una instrucción que no se ejecutó: alguien debe responder por ella.

**43. 🟠 ¿Cómo manejas el envenenamiento de cola (poison message)?**
Límite de reintentos por mensaje, backoff exponencial para no saturar, y envío a DLQ al agotarse. Sin límite, un solo mensaje malformado bloquea la partición indefinidamente y detiene todo el flujo de esa clave. Complementa con validación de esquema en el borde, para que el mensaje inválido no entre.

**44. 🟠 ¿Cómo versionas eventos que otros servicios consumen?**
Schema registry con Avro o Protobuf y reglas de compatibilidad verificadas automáticamente; solo cambios aditivos; campos nuevos opcionales con valor por defecto; nunca reutilizar un nombre de campo con otro significado. Lo que la gente olvida: **los eventos viejos siguen en el topic**, así que cualquier cambio semántico rompe el reprocesamiento histórico.

**45. 🟡 ¿Qué es un API Gateway y qué responsabilidades tiene?**
Punto único de entrada: enrutamiento, terminación TLS, autenticación, rate limiting, transformación ligera y agregación simple. Lo que **no** debe tener: lógica de negocio — ese es el camino de vuelta al ESB. Y ojo con que se convierta en un cuello de despliegue si todos los equipos deben modificarlo para publicar un endpoint.

**46. 🟠 ¿Qué es un BFF y cuándo lo justificas?**
Un backend por tipo de cliente (móvil, web, cajero, IVR) que agrega y adapta para ese canal. Se justifica cuando los canales tienen necesidades de datos muy distintas y meterlas en los servicios de dominio los contaminaría con lógica de presentación. Su coste: un componente más por canal, con su despliegue y su equipo dueño.

**47. 🟠 ¿Cómo evitas la "cascada de llamadas" en una petición de usuario?**
Diseño de fronteras para que un caso de uso se resuelva dentro de un servicio siempre que sea posible; agregación en el borde con llamadas **paralelas** en vez de secuenciales; réplicas locales de datos de referencia para no consultar a otro servicio en cada petición; y presupuesto de latencia explícito por salto. Si un caso de uso necesita seis llamadas encadenadas, el problema es el corte, no la red.

**48. 🔴 Diseña la comunicación para un flujo de apertura de cuenta que toca 6 servicios.**
Orquestación con saga: un process manager dirige los pasos (validación de identidad, consulta a listas restrictivas, evaluación de riesgo, creación en core, emisión de producto, notificación), con compensación por paso y timeouts explícitos. Estado persistido y consultable, porque el proceso dura minutos u horas y el usuario preguntará. Idempotencia en cada paso por clave de solicitud. Respuesta 202 con identificador de seguimiento en vez de bloquear al usuario. Eventos de dominio hacia los canales para notificar avances. Y la decisión que hay que declarar: qué pasos son obligatorios para "abrir" y cuáles pueden completarse después, porque de eso depende toda la experiencia.

---

## 🗄️ Parte 4 — Datos y consistencia (49–64)

**49. 🟢 ¿Qué es "database per service" y por qué es fundamental?**
Cada servicio es dueño exclusivo de su almacén; nadie más lo lee ni lo escribe directamente. Es fundamental porque es lo que permite evolucionar el esquema, elegir la tecnología adecuada y desplegar sin coordinar. Sin esto, no hay autonomía y por tanto no hay microservicios.

**50. 🟡 ¿Significa una base de datos física por servicio?**
No necesariamente. Puede ser un esquema separado en la misma instancia, siempre que el acceso esté realmente restringido por permisos y ningún servicio consulte tablas ajenas. Lo esencial es la **propiedad lógica** y que nadie pueda saltársela; compartir instancia es una decisión de coste, con el riesgo de que un servicio ruidoso afecte a los demás.

**51. 🟠 ¿Cómo haces un join entre datos de dos servicios?**
No lo haces en base de datos. Opciones: composición en el borde (pedir a ambos y unir en memoria, aceptable para volúmenes pequeños), replicar los datos de referencia en el consumidor mediante eventos (la opción habitual), o mantener una vista materializada específica para esa consulta (CQRS). Si necesitas joins complejos y frecuentes entre dos servicios, probablemente sean uno solo.

**52. 🟠 ¿Qué es una vista materializada en microservicios y qué riesgo tiene?**
Un modelo de lectura construido a partir de eventos de varios servicios, optimizado para una consulta concreta. Riesgos: consistencia eventual visible al usuario, y necesidad de un mecanismo **probado** para reconstruirla desde cero cuando se corrompe o cambia el esquema. Si no puedes reconstruirla, tienes una fuente de verdad no declarada.

**53. 🟡 ¿Por qué no usar transacciones distribuidas (2PC)?**
Porque bloquean recursos en todos los participantes durante toda la transacción, el coordinador es un punto único de fallo, escalan mal, y muchos almacenes modernos (DynamoDB, Kafka, servicios externos) simplemente no lo soportan. La industria se movió a sagas: acepta la realidad en vez de pelearse con ella.

**54. 🟠 Explica el patrón Saga con un ejemplo bancario.**
Secuencia de transacciones locales, cada una con su compensación. Ejemplo de transferencia entre dos bancos: debitar origen → enviar a compensación → acreditar destino; si el tercer paso falla definitivamente, la compensación **no borra** el débito, emite un **contra-asiento** que lo revierte contablemente. Ese detalle es el que demuestra que entiendes el dominio, no solo el patrón.

**55. 🟠 ¿Qué garantías pierde una saga frente a una transacción ACID?**
El aislamiento. Durante la saga hay estados intermedios visibles para otros: alguien puede leer una cuenta ya debitada cuando la operación completa aún no terminó. Mitigaciones: bloqueo semántico (marcar el registro como "en proceso"), campos de saldo disponible frente a saldo contable, y diseño de la UI para mostrar operaciones pendientes.

**56. 🟠 ¿Qué es el patrón Outbox y por qué es imprescindible?**
Escribir el evento en una tabla dentro de la **misma transacción** que el cambio de estado, y publicarlo después con un proceso aparte (polling o CDC con Debezium). Resuelve la imposibilidad de hacer atómicos un commit en base de datos y un envío al broker. Sin outbox: o el commit ocurre y el evento se pierde, o el evento se envía y la transacción se revierte.

**57. 🟠 ¿Qué es CDC y cuándo lo prefieres al outbox por polling?**
Change Data Capture lee el log de transacciones de la base de datos (Debezium) y publica los cambios. Lo prefieres cuando quieres latencia baja sin castigar la base con consultas repetidas, o cuando necesitas capturar cambios de un sistema legacy que no puedes modificar. Coste: acopla al log del motor, requiere permisos especiales y una pieza operativa más.

**58. 🟠 ¿Qué es el patrón Inbox / deduplicación en el consumidor?**
La contraparte del outbox: el consumidor registra los identificadores de mensajes procesados en su propia base, en la misma transacción que el efecto, para descartar duplicados. Es la implementación concreta de la idempotencia frente a la entrega at-least-once.

**59. 🟠 ¿Cómo manejas una consulta que necesita datos de cinco servicios?**
Primero cuestiona el requisito: ¿es una pantalla real o un reporte? Si es reporte, va a un almacén analítico alimentado por eventos, no a llamadas en vivo. Si es una pantalla, considera una vista materializada mantenida por eventos, o agregación en el BFF con llamadas paralelas y degradación parcial (mostrar lo que llegó). Lo que no debe hacerse: cinco llamadas encadenadas con el usuario esperando.

**60. 🟡 ¿Cómo gestionas los datos de referencia compartidos (países, monedas, tipos de producto)?**
Un servicio dueño que los publica, y réplicas locales de solo lectura en los consumidores actualizadas por eventos o por sincronización periódica. Consultarlos en vivo en cada petición añade latencia y un punto de fallo para un dato que cambia una vez al año. Es uno de los casos donde replicar es claramente correcto.

**61. 🟠 ¿Cómo haces una migración de datos entre servicios sin downtime?**
Escritura dual durante la transición (el sistema viejo y el nuevo reciben la escritura), backfill histórico en background, verificación de consistencia entre ambos, cambio de lecturas al nuevo con feature flag, período de observación, y retiro del viejo. Cada paso reversible y medido. El punto crítico es la verificación: necesitas un proceso que compare ambos y reporte diferencias antes de confiar.

**62. 🟠 ¿Cómo manejas el borrado de datos personales (derecho al olvido) en una arquitectura distribuida?**
Es de las preguntas más difíciles y más valoradas. Necesitas un inventario de dónde vive cada dato personal (incluidas réplicas, proyecciones, logs, backups y data lake), un evento de borrado propagado a todos los consumidores con confirmación, y una estrategia para los almacenes inmutables: cifrado por sujeto y destrucción de la clave (crypto-shredding), que hace el dato irrecuperable sin borrar el log. Los backups requieren política de retención documentada y acordada con cumplimiento.

**63. 🟠 ¿Cómo detectas y corriges inconsistencias entre servicios?**
Conciliación periódica: procesos que comparan los estados de servicios relacionados, clasifican las diferencias y alertan. Es la red de seguridad que asume que la propagación fallará alguna vez, y siempre falla. Complementa con métricas de retraso de replicación y alertas cuando supera el umbral acordado con negocio.

**64. 🔴 El negocio exige que el saldo mostrado sea siempre exacto. ¿Cómo lo diseñas con microservicios?**
Primero acota el requisito: "exacto" en consulta informativa y "exacto" en autorización de una transacción son cosas distintas y con coste distinto. Diseño: la autorización lee siempre la fuente autoritativa (el servicio dueño del saldo, con bloqueo o condición atómica), sin caché; la consulta informativa puede servirse de una proyección con retraso de segundos, mostrando además las operaciones pendientes para que el usuario entienda la diferencia. Si el negocio insiste en exactitud absoluta en toda lectura, el saldo no debe estar distribuido: es un agregado con dueño único y consistencia fuerte, y hay que decirlo claramente con su coste de escalado.

---

## 🛡️ Parte 5 — Resiliencia y fallos (65–78)

**65. 🟢 ¿Qué es la falacia "la red es confiable" y cuáles son las otras?**
Las ocho falacias de la computación distribuida: la red es confiable, la latencia es cero, el ancho de banda es infinito, la red es segura, la topología no cambia, hay un solo administrador, el coste de transporte es cero, la red es homogénea. Cada microservicio nuevo es una oportunidad más de que cada una te muerda.

**66. 🟡 ¿Qué configuras siempre en una llamada entre servicios?**
Timeout explícito (lo primero y lo más importante: sin él, todo lo demás es cosmético), reintentos con backoff exponencial **y jitter**, solo sobre operaciones idempotentes, circuit breaker, y límite de concurrencia. Más métricas por dependencia para saber a quién culpar cuando algo se degrada.

**67. 🟠 ¿Cómo eliges el valor de un timeout?**
No a ojo: a partir del percentil 99 observado de esa dependencia más un margen, y siempre menor que el timeout de tu propio llamador, para que el presupuesto de latencia sea coherente en toda la cadena. Un timeout mayor que el del llamador es inútil: tu cliente ya se rindió. Documenta el presupuesto por salto.

**68. 🟠 ¿Por qué el jitter en los reintentos es imprescindible?**
Sin jitter, todos los clientes que fallaron al mismo tiempo reintentan al mismo tiempo, creando una onda que impide que el servicio caído se recupere (thundering herd). El jitter dispersa los reintentos. Es un detalle pequeño con impacto enorme y poca gente lo menciona.

**69. 🟠 Explica el circuit breaker y sus tres estados.**
Cerrado (pasa todo, contando fallos), abierto (rechaza inmediatamente sin llamar, dejando respirar al servicio caído) y semiabierto (deja pasar unas pocas peticiones de prueba para ver si se recuperó). Parámetros que hay que decidir: umbral de fallo, ventana de medición, tiempo en abierto. Y lo esencial: **qué devuelves cuando está abierto** — esa es la degradación elegante, y es una decisión de negocio.

**70. 🟠 ¿Qué es el patrón bulkhead?**
Aislar recursos por dependencia (pools de hilos o límites de concurrencia separados) para que un consumidor lento no agote los recursos compartidos y tumbe todo lo demás. El nombre viene de los compartimentos estancos de un barco: una vía de agua no hunde el buque. Sin bulkhead, una dependencia lenta produce un fallo total en lugar de uno parcial.

**71. 🟠 ¿Qué es la degradación elegante? Da un ejemplo bancario.**
Seguir ofreciendo valor parcial cuando algo falla. Ejemplo: si el servicio de categorización de gastos no responde, la app muestra los movimientos sin categoría en vez de una pantalla de error; si el de recomendaciones cae, se ocultan las recomendaciones. Lo que **no** puede degradar: nada que afecte a la exactitud del dinero. Distinguir qué puede degradar y qué no es una conversación con negocio, no una decisión técnica.

**72. 🟠 ¿Qué es un fallo en cascada y cómo lo previenes?**
Un servicio lento consume los hilos de su llamador, que a su vez satura al suyo, hasta que cae todo el sistema por un fallo en un componente secundario. Prevención: timeouts agresivos, bulkheads, circuit breakers, límites de carga (load shedding) y colas acotadas. Y una regla de diseño: una dependencia **no crítica** nunca debe poder tumbar un flujo crítico.

**73. 🟠 ¿Qué es load shedding y por qué es mejor que encolar?**
Rechazar peticiones deliberadamente cuando estás saturado (429 o 503), en vez de aceptarlas y encolarlas. Es mejor porque una cola creciente aumenta la latencia de todos hasta que nadie recibe respuesta útil y, además, esas peticiones ya expiraron para el cliente. Rechazar rápido preserva la capacidad de servir a una parte correctamente.

**74. 🟠 ¿Qué es el patrón de reintento en el cliente vs en el servidor?**
Reintentar en varias capas multiplica la carga: tres reintentos en tres niveles son 27 peticiones. La práctica correcta es definir **en qué capa** se reintenta (normalmente lo más cerca posible del fallo, o solo en el borde) y prohibirlo en las demás. Y propagar un presupuesto de reintentos en la cabecera para que nadie lo amplifique.

**75. 🟠 ¿Qué es chaos engineering y lo aplicarías en banca?**
Inyectar fallos controlados en producción o preproducción para validar que los mecanismos de resiliencia funcionan de verdad. En banca sí, con condiciones: empezar en preproducción, radio de impacto acotado, horario y aprobación, y con capacidad probada de abortar. El argumento para venderlo: el fallo va a ocurrir de todas formas; mejor que ocurra un martes a las 10 con todo el equipo mirando.

**76. 🟡 ¿Cómo pruebas la resiliencia de tu servicio?**
WireMock o Toxiproxy para simular latencia, errores y cortes; pruebas que verifiquen que el circuit breaker abre y que la degradación devuelve lo esperado; pruebas de carga que lleguen a la saturación para ver **cómo** falla. La pregunta clave no es "¿funciona?", sino "¿cómo se comporta cuando su dependencia tarda 30 segundos?".

**77. 🟠 ¿Cómo manejas un servicio del que dependes y que no puedes arreglar (un core legacy)?**
Circuit breaker y timeout agresivos, caché de lecturas para reducir la presión, límite de concurrencia hacia él para no saturarlo, cola para las escrituras cuando el negocio lo permita, y degradación definida. Y algo organizativo: un acuerdo de nivel de servicio explícito con su equipo y métricas compartidas, porque sin datos la conversación es una discusión de opiniones.

**78. 🔴 Tu sistema tiene una caída total. Los 12 servicios están rojos. ¿Cómo lo abordas como líder técnico?**
Primero rol y comunicación: alguien coordina, alguien comunica a negocio, los demás investigan; sin eso, doce personas pisándose. Después, buscar la causa común en vez de doce causas: infraestructura compartida (red, DNS, base de datos, service mesh, certificados vencidos, cuota agotada) o un despliegue reciente. Rollback antes que diagnóstico si hay un cambio sospechoso. Restablecer por orden de dependencia, no todo a la vez. Y al día siguiente, post mortem sin culpables con acciones concretas y dueños. Mencionar el post mortem sin culpables es parte de la respuesta, no un adorno.

---

## 🚀 Parte 6 — Despliegue, operación y organización (79–100)

**79. 🟢 ¿Por qué contenedores y Kubernetes son el estándar para microservicios?**
Empaquetado uniforme independiente del lenguaje, densidad de recursos, orquestación declarativa, autoescalado, y recuperación automática. Kubernetes aporta además service discovery, gestión de configuración y secretos, y despliegues progresivos. Su coste real: es una plataforma compleja que alguien tiene que operar y entender.

**80. 🟡 ¿Qué estrategias de despliegue conoces y cuál usarías en banca?**
Rolling (gradual, la opción por defecto), blue-green (dos entornos completos, cambio instantáneo y rollback inmediato, cuesta el doble de infraestructura), canary (porcentaje creciente con métricas decidiendo el avance), y feature flags (despliegue desacoplado de la activación). En banca, canary con métricas automáticas más feature flags es la combinación más segura, con la advertencia de que **la base de datos no hace blue-green**.

**81. 🟠 ¿Cómo despliegas un cambio que requiere migración de esquema?**
Expand/contract en varios despliegues: añadir estructura compatible, desplegar código que escribe en ambos formatos, migrar datos en background, cambiar lecturas, y solo después eliminar lo viejo. Cada despliegue individualmente reversible. Es la única forma de que un rollback no destruya datos, y es de las preguntas que mejor separan a quien ha operado en producción.

**82. 🟡 ¿Qué es service discovery y cómo funciona en Kubernetes?**
El mecanismo por el que un servicio encuentra las instancias de otro sin direcciones cableadas. En Kubernetes, los `Service` con DNS interno y `Endpoints` actualizados automáticamente; fuera, Consul o Eureka. La parte interesante: el descubrimiento no basta, necesitas además balanceo con conciencia de salud y remoción rápida de instancias caídas.

**83. 🟠 ¿Qué es un service mesh y cuándo lo justificas?**
Una capa de infraestructura (Istio, Linkerd) que gestiona la comunicación entre servicios mediante sidecars: mTLS, reintentos, timeouts, circuit breaking, enrutamiento por tráfico y telemetría, sin tocar el código. Se justifica con muchos servicios y stacks heterogéneos, especialmente si necesitas mTLS obligatorio por cumplimiento. No se justifica con ocho servicios en un solo lenguaje: ahí una librería cuesta mucho menos que operar un mesh.

**84. 🟠 ¿Cómo gestionas la configuración y los secretos de 30 servicios?**
Configuración externalizada por entorno (ConfigMaps, Config Server, Parameter Store) y secretos en un gestor dedicado (Secrets Manager, Vault) con rotación e inyección en ejecución, nunca en la imagen ni en el repositorio. Añade escaneo de secretos en el pipeline y auditoría de accesos, que en banca se revisa.

**85. 🟡 ¿Qué es GitOps?**
El estado deseado del sistema vive en Git y un operador (ArgoCD, Flux) reconcilia el cluster con él. Ventajas: historial auditable de todo cambio de infraestructura, rollback por revert, y separación de funciones natural — quien aprueba el PR no es quien lo escribió. Esa auditabilidad es un argumento fuerte en banca.

**86. 🟠 ¿Cómo estructuras los repositorios: monorepo o repo por servicio?**
Repo por servicio: autonomía total, pipelines simples, pero refactorizar algo transversal es doloroso y las versiones de librerías divergen. Monorepo: cambios atómicos entre servicios, herramientas compartidas y visibilidad, pero requiere herramientas de build incremental y disciplina para no acoplar. Postura defendible: monorepo cuando los servicios los mantiene la misma organización con tooling adecuado; repo por servicio cuando los equipos son verdaderamente independientes.

**87. 🟠 ¿Cómo pruebas un sistema de microservicios de punta a punta?**
Con cuidado, porque las pruebas E2E completas son lentas, frágiles y caras de mantener. Estrategia por capas: muchas unitarias, pruebas de componente con las dependencias simuladas, **pruebas de contrato** para garantizar compatibilidad entre servicios, y muy pocas E2E cubriendo los flujos críticos de negocio. Las pruebas de contrato son las que sustituyen a la mayoría de E2E sin perder confianza.

**88. 🟠 ¿Qué es observabilidad y en qué se diferencia de monitorización?**
Monitorización responde preguntas que ya sabías formular (dashboards, alertas sobre métricas conocidas). Observabilidad es poder responder preguntas **nuevas** sobre el comportamiento del sistema sin desplegar código: correlacionar una traza con logs y métricas para entender un caso que nunca previste. En microservicios es imprescindible: sin trazas distribuidas, un incidente es adivinación.

**89. 🟡 ¿Qué instrumentas primero en un servicio nuevo?**
Las cuatro señales doradas (latencia con percentiles, tráfico, errores, saturación), identificador de correlación en todos los logs, traza distribuida, y métricas de negocio propias del servicio. Alertas sobre síntomas visibles para el usuario, no sobre causas internas: alertar por "uso de CPU al 80%" produce ruido; alertar por "p99 supera el SLO" produce acción.

**90. 🟠 ¿Cómo depuras un problema que solo ocurre en producción y atraviesa 7 servicios?**
Traza distribuida con identificador de correlación como punto de partida: te dice en qué salto se fue el tiempo o dónde apareció el error. Después, logs filtrados por ese identificador en todos los servicios, y métricas de la ventana temporal para ver si es general o puntual. Si el caso es raro, muestreo forzado ante errores para no perderlo. Sin esta instrumentación previa, el diagnóstico es imposible — y esa es justamente la respuesta: se prepara antes, no durante el incidente.

**91. 🟠 ¿Cómo aseguras la comunicación entre servicios?**
mTLS entre servicios (gestionado por el mesh o por la plataforma), autenticación de servicio con tokens de corta vida, autorización por política, y confianza cero también hacia dentro: un servicio interno **no** debe confiar en un header `X-User-Id` sin validar, porque cualquiera que alcance la red podría suplantarlo. Cifrado en tránsito y en reposo, y rotación automática de certificados.

**92. 🟠 ¿Cómo propagas la identidad del usuario entre servicios?**
Reenviando el token del usuario, con token exchange, o con un token de servicio que contenga el sujeto original firmado. Cada servicio valida por sí mismo, no delega la confianza. El riesgo que hay que nombrar es el "deputy confuso": un servicio que actúa con sus propios privilegios en nombre de un usuario que no tenía permiso.

**93. 🟡 ¿Cómo manejas el versionado de APIs entre equipos?**
Compatibilidad hacia atrás por defecto, versión explícita solo ante cambios incompatibles, política de deprecación con fechas comunicadas, y pruebas de contrato que impidan romper a un consumidor sin enterarse. En una organización grande, mantener dos versiones durante meses es parte del plan, no un fracaso.

**94. 🟠 ¿Cómo gestionas el on-call de 30 servicios con 4 equipos?**
Cada equipo responde por sus servicios, con rotación sostenible y alertas accionables. Runbooks por alerta (qué significa, qué verificar, qué hacer). Métrica de salud del proceso: número de alertas por guardia y cuántas requirieron acción — si la mayoría no requiere acción, el sistema de alertas está roto y quema al equipo. Y post mortems que generen acciones con dueño, no solo documentos.

**95. 🟠 ¿Qué es un catálogo de servicios y por qué lo necesitas?**
Un registro (Backstage, por ejemplo) de qué servicios existen, quién es su dueño, cuáles son sus dependencias, su documentación, su nivel de criticidad y sus enlaces operativos. Lo necesitas porque, superados los quince servicios, nadie tiene el mapa completo en la cabeza, y en un incidente la primera pregunta siempre es "¿de quién es esto?".

**96. 🟠 ¿Cómo controlas costes en una arquitectura de microservicios?**
Etiquetado por servicio y equipo para atribuir costes, right-sizing basado en uso real (no en el pico histórico), autoescalado bien configurado, revisión del coste de observabilidad —que suele dispararse y es donde más grasa hay—, y atención a la transferencia de datos entre zonas, que es el coste oculto favorito. Hacer visible el coste por equipo cambia comportamientos más que cualquier política.

**97. 🟠 ¿Qué gobierno técnico impondrías con 30 servicios y 6 equipos?**
Estándares mínimos obligatorios (observabilidad, seguridad, contrato documentado, health checks, runbook) verificados automáticamente en el pipeline, y libertad dentro de ese marco. Un grupo de arquitectura que **facilita** y decide lo transversal, no que aprueba cada PR. ADRs para decisiones significativas. Y plantillas de servicio que hagan que el camino correcto sea también el más fácil, que es la única forma de que se cumpla.

**98. 🔴 ¿Cuál es el error más común que ves en implementaciones de microservicios?**
Cortar por entidades o por capas técnicas en vez de por capacidades de negocio, lo que produce servicios que no hacen nada solos y se llaman constantemente. El segundo: mantener la base de datos compartida "temporalmente", que se vuelve permanente. El tercero: adoptar la arquitectura sin la madurez operativa —sin CI/CD, sin observabilidad, sin on-call— y descubrir en producción que ahora los mismos problemas son diez veces más difíciles de diagnosticar.

**99. 🔴 ¿Volverías de microservicios a un monolito? ¿En qué caso?**
Sí, y hay casos públicos conocidos de empresas que lo hicieron y mejoraron latencia y coste. El caso típico: servicios demasiado finos con alto chattiness, donde la mayor parte del tiempo y del coste se va en red y serialización, y donde la separación no aporta autonomía real porque el mismo equipo mantiene todo. La consolidación en un monolito modular bien estructurado es una decisión legítima de ingeniería, no un retroceso. Lo que importa es medir, no la moda.

**100. 🔴 Si te contratan como Tech Lead de una plataforma de microservicios existente, ¿qué evalúas en los primeros 90 días?**
Antes de proponer cambios, mide: métricas DORA, cuántos servicios hay que desplegar juntos para entregar una funcionalidad (el mejor indicador de acoplamiento real), estado de la observabilidad, cobertura de pruebas de contrato, y cuántas alertas por guardia. Habla con el equipo sobre qué les duele y con negocio sobre qué esperan. Entrega algo pequeño y visible pronto para ganar credibilidad. Y al final del trimestre presenta dos o tres mejoras priorizadas **con datos**, no con opiniones: en una plataforma existente, la credibilidad se gana midiendo antes de opinar.

---

> 🧭 **Cierre:** las respuestas que más puntúan en microservicios casi nunca son las que describen el patrón correcto. Son las que nombran **el coste** del patrón, **qué se rompe cuando falla**, y **qué decisión de negocio hay detrás**. Si además puedes contarlo con una historia propia de producción, ya no estás respondiendo una entrevista: estás conversando entre pares.
