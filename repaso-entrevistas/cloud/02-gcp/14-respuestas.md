# 14 — Respuestas

> **Objetivo:** ser el solucionario centralizado del curso. Reúne, explicadas, las respuestas a las
> "Preguntas rápidas" de **todos** los documentos —los capítulos teóricos `01`–`09` y `11`–`13`, las
> preguntas `P#` de [`10`](10-preguntas-entrevista-y-mapa-mental.md), y la serie práctica completa
> `L00`–`L08` y `A01`–`A04`—. Ningún otro documento lleva la respuesta junto a la pregunta.
> **Se asume leído:** el documento cuya pregunta vienes a consultar.
> **Cómo se usa:** las entradas están numeradas **igual que en el original**. La pregunta 3 de [`04`](04-firestore-bigtable-nosql.md)
> se responde en la entrada 3 de la sección "04"; la pregunta 7 de [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md), en la entrada 7 de "L06".
> **Regla de mantenimiento:** quien agregue, elimine o reordene una pregunta debe reflejar el mismo
> cambio aquí **en la misma edición**.
> **Vigencia:** 6 de septiembre de 2026.

**Salto rápido:** [Parte I — capítulos teóricos](#parte-i--capítulos-teóricos) ·
[Parte II — serie práctica](#parte-ii--serie-práctica)

Los escenarios de arquitectura de [`10`](10-preguntas-entrevista-y-mapa-mental.md) no están aquí
porque ya traen su solución desarrollada en el propio documento.

---

# Parte I — Capítulos teóricos

---

## 01 — Infraestructura global y redes

1. **¿Una VPC es un recurso global o regional?** Global. La misma VPC puede tener subnets en varias regiones sin peering adicional entre ellas.
2. **¿Una subnet puede abarcar dos regiones?** No. Una subnet es regional y abarca todas las zonas de una única región.
3. **¿Qué diferencia a una Zone de una Region?** Region es un área geográfica; Zone es un dominio de aislamiento de fallos dentro de esa región.
4. **¿Un Persistent Disk zonal puede adjuntarse a una VM de otra zona?** No. Para eso existe el Persistent Disk regional, replicado entre dos zonas.
5. **¿Qué camino toma el tráfico bajo Premium Tier frente a Standard Tier?** Premium Tier entra/sale por la red privada de Google lo antes posible; Standard Tier se comporta como tránsito de Internet público típico.
6. **¿Auto-mode VPC es recomendable para producción?** No normalmente. Asigna rangos predefinidos en todas las regiones, lo que complica evitar solapamientos frente a custom-mode.
7. **¿Qué significa "longest prefix match"?** Que, entre rutas que coinciden con el destino, GCP selecciona la más específica (el prefijo más largo).
8. **¿Una VM sin IP externa tiene salida a Internet por definición?** No. Necesita Cloud NAT (u otra ruta de salida configurada) para iniciar conexiones salientes.
9. **¿Las firewall rules de VPC admiten reglas DENY?** Sí, admiten ALLOW y DENY, evaluadas según prioridad numérica.
10. **¿Qué diferencia una firewall rule de una hierarchical firewall policy?** La firewall rule se define a nivel VPC; la hierarchical firewall policy se aplica a nivel Organization/Folder y hereda hacia todos los proyectos debajo.
11. **¿Para qué sirve el Serverless VPC Access connector?** Permite que Cloud Run/Cloud Functions alcancen recursos con IP privada dentro de la VPC.
12. **¿VPC Peering es transitivo?** No. Si B↔A y A↔C, eso no implica B↔C.
13. **¿Qué problema resuelve Shared VPC que VPC Peering no resuelve igual de bien?** Permite que varios proyectos de servicio usen subnets de una sola VPC administrada centralmente por un proyecto host, sin necesitar peering entre cada proyecto.
14. **¿Cuándo usarías Network Connectivity Center en lugar de peering directo?** Cuando necesitas conectar muchas VPCs/redes a escala (hub-and-spoke), evitando un mesh manual de peering.
15. **¿Qué diferencia a Private Google Access de Private Service Connect?** Private Google Access permite a VMs sin IP externa alcanzar APIs públicas de Google; Private Service Connect permite consumir privadamente un servicio específico mediante un endpoint con IP interna.

---

## 02 — Cómputo, contenedores y balanceo

1. **¿Cloud Run reemplaza a GKE en todos los casos?** No. GKE sigue siendo necesario para control de red fino, sidecars complejos, DaemonSets o recursos de Kubernetes específicos.
2. **¿Qué diferencia a un Persistent Disk zonal de uno regional?** El zonal existe en una sola zone y se pierde si esa zone falla; el regional se replica síncronamente entre dos zonas.
3. **¿Cuándo preferirías scale out sobre scale up?** Cuando la carga lo permite (stateless, distribuible): evita el límite de una sola máquina y encaja con MIG + Cloud Load Balancing.
4. **¿Qué diferencia a la External HTTP(S) LB de la Internal HTTP(S) LB?** External es global y expone tráfico desde Internet; Internal es regional y sirve tráfico interno dentro de la VPC.
5. **¿HTTP(S) LB y Network LB operan en la misma capa OSI?** No. HTTP(S) LB es Layer 7; Network LB es Layer 4.
6. **¿Cómo conecta un backend service de Cloud LB con Cloud Run?** Mediante un Network Endpoint Group (NEG) serverless que apunta al servicio de Cloud Run.
7. **¿Cloud Run escala a cero por defecto?** Sí.
8. **¿Qué permite la concurrency por instancia de Cloud Run?** Que cada instancia atienda múltiples requests concurrentes, reduciendo el número de instancias necesarias para un mismo throughput.
9. **¿Para qué sirve dividir tráfico entre revisiones de Cloud Run?** Para despliegues graduales/canary sin infraestructura adicional.
10. **¿Qué diferencia a GKE Autopilot de GKE Standard?** Autopilot administra los nodos por completo; Standard da control total del node pool al equipo.
11. **¿Cloud Functions 2nd gen está construido sobre qué servicio?** Sobre Cloud Run.
12. **¿Artifact Registry es lo mismo que Docker Hub?** No. Artifact Registry es el registry nativo de GCP con integración de IAM/VPC-SC; Docker Hub es un registro público general.
13. **¿Qué le falta a Cloud Run frente a GKE cuando se necesitan DaemonSets o sidecars complejos?** No expone esos recursos/ese control de Kubernetes; para eso se necesita GKE.
14. **¿Qué hace Cloud Build en el flujo de CI de una imagen de contenedor?** Ejecuta los build steps (compilar, testear, construir la imagen) y publica el resultado en Artifact Registry.

---

## 03 — Almacenamiento y bases SQL

1. **¿Qué diferencia a Cloud Storage de Persistent Disk y de Filestore?** Cloud Storage es object storage vía API; Persistent Disk es block storage adjuntado a una VM; Filestore es un filesystem compartido (NFS).
2. **¿Qué aporta el versioning de Cloud Storage frente a una lifecycle rule?** Versioning conserva versiones anteriores para poder recuperarlas; lifecycle rule automatiza transiciones/eliminación según condiciones, no recuperación de versiones por sí sola.
3. **¿Todas las storage classes de Cloud Storage tienen la misma durabilidad?** Sí. Lo que cambia es el costo de almacenamiento frente al costo/mínimo de retención al acceder.
4. **¿Para qué sirve una signed URL?** Otorga acceso temporal y acotado a un object específico sin requerir credenciales de GCP en el cliente.
5. **¿Qué administra Cloud SQL y qué sigue siendo responsabilidad del equipo?** Administra provisioning, patching, backups automatizados y failover; el equipo sigue siendo responsable del diseño de esquema, índices y queries.
6. **¿Qué diferencia a Cloud SQL de AlloyDB?** AlloyDB es un motor propio de GCP compatible con PostgreSQL, optimizado para mayor rendimiento; Cloud SQL PostgreSQL es PostgreSQL administrado estándar.
7. **¿HA regional de Cloud SQL y Read Replica resuelven el mismo problema?** No. HA regional resuelve failover ante falla de zona; Read Replica resuelve escalar lecturas.
8. **¿Una read replica sustituye a un backup?** No. La replicación también propaga errores lógicos/borrados; backup y replicación resuelven problemas distintos.
9. **¿Qué permite el point-in-time recovery que un backup diario no permite por sí solo?** Restaurar la base a un instante específico dentro de la ventana de retención de logs de transacciones, no solo al último backup completo.
10. **¿Para qué sirve el Cloud SQL Auth Proxy?** Administra la conexión cifrada y la autenticación IAM hacia Cloud SQL sin exponer IP pública ni gestionar certificados TLS manualmente.
11. **¿Por qué una aplicación necesita connection pooling frente a una base relacional?** Porque la base tiene un límite de conexiones concurrentes; el pool reutiliza conexiones en lugar de abrir una nueva por request.
12. **¿Cuándo usarías Memorystore en una arquitectura backend típica?** Para cache de sesiones, resultados de queries costosas, rate limiting o estructuras de datos en memoria de baja latencia.
13. **¿Cuándo elegirías una base SQL en lugar de NoSQL?** Cuando hay relaciones complejas, joins frecuentes, integridad referencial fuerte, transacciones multi-fila/tabla, consultas ad hoc flexibles o reporting operacional.

---

## 04 — Firestore, Bigtable y NoSQL

1. **¿Qué diferencia al modelo de documentos del modelo wide-column?** Documentos agrupa datos flexibles en colecciones/documentos (Firestore); wide-column organiza filas por row key con columnas agrupadas en column families (Bigtable).
2. **¿Por qué en Firestore se diseña primero a partir de access patterns?** Porque las colecciones/subcolecciones/índices determinan qué consultas serán eficientes; no hay joins nativos para rescatar un modelo genérico después.
3. **¿Qué es una subcollection?** Una colección anidada bajo un documento específico.
4. **¿Qué diferencia una consulta simple de una compuesta en Firestore?** Simple filtra/ordena por un solo campo; compuesta combina condiciones sobre múltiples campos.
5. **¿Los índices compuestos de Firestore se crean automáticamente?** No. Solo los índices de campo único son automáticos; los compuestos deben declararse explícitamente.
6. **¿Firestore es siempre fuertemente consistente para cualquier tipo de consulta?** Es fuertemente consistente para lecturas por ID y la mayoría de queries, pero afirmarlo como regla absoluta sin excepción es una sobregeneralización — existen matices según el tipo de operación/configuración.
7. **¿Cómo factura Firestore sus operaciones?** Por operaciones de documento (lecturas, escrituras, eliminaciones), no por capacidad reservada tipo RCU/WCU.
8. **¿TTL en Firestore borra exactamente al alcanzar el timestamp?** No. La eliminación es asíncrona y eventual.
9. **¿Qué diferencia a Firestore Native mode de Datastore mode?** Native mode es el modo recomendado actual, con modelo de documentos/subcolecciones; Datastore mode es el modo original, legacy.
10. **¿Qué determina la row key en Bigtable?** Cómo Bigtable distribuye y ordena físicamente los datos.
11. **¿Qué es una hot partition en Bigtable y cómo se mitiga?** Concentración de tráfico en un rango estrecho de row keys (ej. timestamp creciente); se mitiga invirtiendo/hasheando parte de la key o anteponiendo un identificador de alta cardinalidad.
12. **¿Cuándo elegirías Bigtable en lugar de Firestore?** Cuando el volumen y throughput son extremos y el acceso es predominantemente por row key, sin necesitar el modelo de documentos ni consultas ricas por múltiples campos.
13. **¿Firestore reemplaza a BigQuery para reporting analítico?** No. Firestore está pensado para acceso transaccional por documento a baja latencia, no para escanear grandes volúmenes históricos con SQL analítico.

---

## 05 — Seguridad, IAM, jerarquía, KMS y secretos

1. **¿Qué unidad concentra la facturación y las APIs habilitadas en GCP?** El Project.
2. **¿Por qué evitar primitive roles en producción?** Porque otorgan permisos muy amplios (ej. Editor sobre casi todo el proyecto), más allá de lo que la mayoría de las cargas necesita.
3. **¿Las allow policies de IAM son aditivas o pueden negar lo que otro binding concedió?** Son aditivas; ningún allow policy puede quitar lo que otro concedió.
4. **¿Cómo se niega explícitamente un acceso en IAM si las allow policies no pueden hacerlo?** Mediante IAM Deny policies, evaluadas antes que cualquier allow policy.
5. **¿Qué debería usar una app en Cloud Run en lugar de una key de Service Account descargada?** Una Service Account adjunta al recurso (o Workload Identity en GKE).
6. **¿Qué resuelve Workload Identity Federation que una key de Service Account no resuelve de forma segura?** Permite que cargas fuera de GCP actúen como una identidad de GCP sin necesitar una key descargada de larga vida.
7. **¿Qué diferencia el cifrado at rest del cifrado in transit?** At rest protege datos almacenados; in transit protege datos moviéndose entre cliente/servicio (típicamente vía TLS).
8. **¿Qué es envelope encryption?** Un patrón donde una key de KMS cifra una data key más pequeña, y es esa data key la que cifra el volumen de datos.
9. **¿Cloud KMS reemplaza a Secret Manager?** No. KMS administra claves y operaciones criptográficas; Secret Manager almacena y administra secretos (y usa KMS por debajo).
10. **¿Por qué preferir Secret Manager sobre una variable de entorno plana para un dato sensible?** Porque una variable de entorno plana queda visible en consola/logs/historial de despliegue; Secret Manager controla el acceso vía IAM y cifra el secreto.
11. **¿Qué diferencia a Cloud Armor de una firewall rule de VPC?** La firewall rule opera a nivel de red VPC; Cloud Armor opera en el borde de Cloud Load Balancing con reglas WAF/rate limiting a nivel de aplicación.
12. **¿Cloud Armor y Cloud CDN resuelven el mismo problema?** No. Cloud Armor filtra/protege tráfico; Cloud CDN cachea contenido — son complementarios sobre el mismo backend service.
13. **¿Una Organization Policy otorga permisos a un member?** No. Es una restricción de configuración sobre un recurso, no un permiso otorgado a una identidad.
14. **¿Qué diferencia una Organization Policy de una IAM allow policy?** La allow policy define qué puede hacer un member; la Organization Policy define qué configuraciones están permitidas en un recurso, sin importar el member.
15. **¿Por qué separar proyectos por ambiente (dev/test/prod)?** Permite aplicar IAM y Organization Policies distintos por ambiente y limitar el blast radius de un incidente en un ambiente no productivo.

---

## 06 — Cloud DNS, CDN, API management y conectividad híbrida

1. **¿Qué diferencia una public zone de una private zone?** Public responde DNS público desde Internet; private resuelve nombres solo dentro de las VPC asociadas.
2. **¿Qué diferencia a un registro A de uno AAAA?** A mapea a una dirección IPv4; AAAA mapea a una dirección IPv6.
3. **¿Weighted routing policy garantiza una distribución exacta por request?** No, es una distribución relativa aproximada.
4. **¿De qué depende el health check de una routing policy de failover en Cloud DNS?** De los health checks de Cloud Load Balancing asociados a los backends, no de un chequeo DNS nativo independiente.
5. **¿Qué es el origin en el contexto de Cloud CDN?** El backend service que sirve el contenido original que Cloud CDN cachea.
6. **¿Cloud CDN reemplaza a Cloud Load Balancing?** No. Cloud CDN cachea contenido cacheable sobre el mismo backend service que balancea Cloud Load Balancing.
7. **¿Qué diferencia a Certificate Manager de Cloud KMS?** Certificate Manager administra certificados TLS; Cloud KMS administra claves y operaciones criptográficas de propósito general.
8. **¿Qué diferencia a API Gateway de Apigee?** API Gateway es API management ligero y serverless; Apigee es gestión de API a nivel enterprise (monetización, developer portal, analítica avanzada).
9. **¿API Gateway reemplaza a Cloud Load Balancing?** No. Agrega gestión de API sobre backends serverless; Cloud Load Balancing distribuye tráfico de forma general.
10. **¿Qué diferencia a Cloud VPN de Cloud Interconnect en cuanto a la ruta del tráfico?** Cloud VPN usa túneles IPsec sobre Internet; Cloud Interconnect usa conectividad privada dedicada sin atravesar Internet público.
11. **¿Por qué un endpoint de Private Service Connect suele resolverse mediante una private zone?** Para que los consumidores dentro de la VPC lo alcancen por un nombre estable en lugar de memorizar una IP interna.

---

## 07 — Pub/Sub, Cloud Tasks, Eventarc e integración

1. **¿Qué diferencia a Pub/Sub de un servicio que separa colas punto-a-punto de pub/sub fan-out?** Pub/Sub cubre ambos roles dentro del mismo servicio unificado.
2. **¿Push subscription y pull subscription entregan mensajes de la misma forma?** No. Push hace que Pub/Sub llame a un endpoint HTTP; pull hace que el subscriber solicite mensajes activamente.
3. **¿Pub/Sub garantiza exactly-once delivery por defecto?** No. Por defecto es at-least-once; exactly-once es una feature explícita que debe habilitarse, bajo condiciones específicas.
4. **¿Una ordering key garantiza orden global de todo el topic?** No, solo orden entre los mensajes que comparten esa misma ordering key.
5. **¿Qué es el acknowledgement deadline?** La ventana durante la cual un subscriber debe confirmar un mensaje antes de que Pub/Sub lo reentregue.
6. **¿Qué hace un dead-letter topic?** Recibe los mensajes que superan el número de intentos configurado, para investigación y recuperación controlada.
7. **¿Por qué un consumer de Pub/Sub debe ser idempotente?** Porque la entrega es at-least-once por defecto y el mismo mensaje puede procesarse más de una vez.
8. **¿Qué diferencia de propósito hay entre Cloud Tasks y Pub/Sub?** Cloud Tasks orquesta llamadas HTTP puntuales controladas por el productor; Pub/Sub es fan-out desacoplado entre productores y consumidores.
9. **¿Qué hace un trigger de Eventarc?** Enruta un evento desde una fuente de GCP hacia un destino (Cloud Run, Cloud Functions, Workflows).
10. **¿Qué significa backpressure en un flujo asíncrono?** Que el productor genera trabajo más rápido de lo que el consumidor puede procesar, generando backlog; se resuelve escalando consumers o limitando el productor.
11. **¿Por qué un endpoint síncrono respondería 202 Accepted en lugar de esperar?** Porque confirma que aceptó el trabajo para procesamiento asíncrono, no que ya terminó de procesarlo.

---

## 08 — Observabilidad, auditoría y gobierno

1. **¿Qué diferencia a Cloud Logging de Cloud Monitoring?** Logging responde qué eventos ocurrieron; Monitoring responde cómo está funcionando el sistema (métricas/alertas).
2. **¿Para qué sirve un log sink?** Para exportar logs (filtrados o no) hacia BigQuery, Cloud Storage o Pub/Sub.
3. **¿Qué tipos de Cloud Audit Logs existen?** Admin Activity, Data Access, System Event y Policy Denied.
4. **¿Data Access logs están habilitados por defecto para todos los servicios?** No, están deshabilitados por defecto para la mayoría de los servicios, por volumen.
5. **¿Qué diferencia a Cloud Audit Logs de Cloud Asset Inventory?** Audit Logs dice quién hizo el cambio; Asset Inventory dice cómo está/estuvo configurado el recurso y su historial.
6. **¿Qué mide un uptime check que una métrica interna de latencia no mide igual?** Disponibilidad desde la perspectiva de un cliente externo, verificada desde ubicaciones externas.
7. **¿Cómo investigarías quién abrió una firewall rule al mundo?** Revisando Cloud Audit Logs (Admin Activity) para identificar quién ejecutó el cambio, y Cloud Asset Inventory para el historial de configuración.
8. **¿VPC Flow Logs contiene el payload HTTP de las requests?** No, solo metadata del tráfico IP (origen, destino, puertos, protocolo, acción).
9. **¿Connectivity Tests envía tráfico real?** No, analiza estáticamente la configuración de red.
10. **¿Qué diferencia a una custom metric de una métrica estándar de infraestructura?** La custom metric es definida por la aplicación (señal de negocio); la estándar la recolecta Cloud Monitoring automáticamente de la infraestructura.

---

## 09 — Terraform e Infrastructure as Code

1. **¿Por qué este curso usa Terraform y no Deployment Manager?** Porque Deployment Manager está en modo mantenimiento y Terraform es el estándar de facto en equipos GCP reales, el que se pregunta en entrevistas de arquitectura.
2. **¿Qué bloque es obligatorio para definir infraestructura en Terraform?** `resource`.
3. **¿Qué diferencia al resource type del resource local name?** El resource type indica qué tipo de recurso GCP se crea; el local name es el identificador dentro de la configuración de Terraform, no el nombre real en GCP.
4. **¿Para qué sirve un bloque output más allá de mostrar resultados?** Para exponer valores a otros módulos o consumidores del state.
5. **¿Cómo se logra crear un recurso condicionalmente sin un bloque Conditions dedicado?** Con `count`/`for_each` y expresiones (ej. `count = condición ? 1 : 0`).
6. **¿Cuándo es realmente necesario depends_on?** Solo cuando una dependencia real no queda reflejada por ninguna referencia de atributo entre recursos.
7. **¿Qué hace prevent_destroy dentro de un bloque lifecycle?** Bloquea un destroy/replacement accidental de ese recurso.
8. **¿Qué permite revisar terraform plan antes de apply?** Los cambios propuestos, como una previsualización tipo change set, sin garantizar que la ejecución tendrá éxito.
9. **¿Qué implica que un cambio fuerce un replacement?** Que Terraform destruye el recurso existente y crea uno nuevo, con riesgo de downtime, cambio de identificador o pérdida de datos.
10. **¿Terraform hace rollback automático si apply falla a mitad de camino?** No. El state queda reflejando lo que realmente se aplicó; corregirlo requiere una nueva ejecución.
11. **¿Por qué es importante un remote state con locking?** Porque sin locking, ejecuciones concurrentes de apply pueden corromper el state al escribir sobre él al mismo tiempo.
12. **¿Qué reporta terraform plan cuando detecta drift?** Que el estado real difiere del esperado, y propone revertir el cambio manual al aplicar.
13. **¿Qué comando permite incorporar un recurso creado manualmente al control de Terraform?** `terraform import`.
14. **¿Qué diferencia a un módulo de un workspace?** Un módulo compone/reutiliza configuración; un workspace maneja múltiples instancias del mismo módulo (ej. dev/test/prod) con el mismo código, cada una con su propio state.

---

## 11 — Resiliencia y Google Cloud Architecture Framework

1. **¿Cuáles son los seis pilares del Google Cloud Architecture Framework?** System design, Operational excellence, Security/privacy/compliance, Reliability, Cost optimization y Performance optimization.
2. **¿Por qué optimizar un pilar sin mirar los demás es una respuesta débil?** Porque los pilares compiten entre sí (trade-offs); ignorar eso produce diseños que solo se ven bien desde un ángulo, a costa de otro.
3. **¿Qué estados tiene un circuit breaker?** CLOSED, OPEN y HALF-OPEN.
4. **¿Para qué sirve el jitter en un backoff exponencial?** Para desincronizar los reintentos entre clientes y evitar que todos reintenten al mismo tiempo.
5. **¿Qué problema resuelve un bulkhead?** Aísla recursos entre dependencias, para que la saturación de una no consuma toda la capacidad disponible del sistema.
6. **¿Qué resuelve un timeout budget que un timeout aislado por servicio no resuelve?** Reparte el tiempo total tolerable de una request entre cada salto de la cadena, evitando que la suma de timeouts individuales lo supere.
7. **¿Qué mide RTO y qué mide RPO?** RTO mide cuánto tiempo puede estar el sistema caído; RPO mide cuántos datos puede permitirse perder, en tiempo.
8. **¿Cuál es la estrategia de DR más barata y cuál la más cara?** Backup & Restore es la más barata; Multi-site Active/Active es la más cara.
9. **¿Qué diferencia a Pilot Light de Warm Standby?** Pilot Light solo mantiene los datos replicando en la región secundaria, sin cómputo activo; Warm Standby mantiene el sistema completo corriendo con capacidad reducida.
10. **¿Por qué Multi-site Active/Active tiene el RPO más bajo?** Porque ambas regiones sirven tráfico activo con datos sincronizados/replicados continuamente, sin depender de un proceso de recuperación posterior.
11. **¿Cómo se relacionan los patrones de resiliencia y la estrategia de DR con Reliability?** Ambos son el detalle técnico de ese pilar: resiliencia maneja fallas parciales en tiempo real, DR maneja la pérdida de una región completa.

---

## 12 — Orquestación y CI/CD

1. **¿Qué diferencia a Workflows de un flujo orquestado con Eventarc + Cloud Run?** Workflows orquesta explícitamente una secuencia conocida de pasos en un solo lugar; Eventarc+Cloud Run es event-driven, con servicios desacoplados que reaccionan sin conocer el flujo completo.
2. **¿Qué señal indica que un flujo necesita un Workflow explícito?** Un servicio con lógica de orquestación embebida (múltiples try/catch anidados, reintentos manuales entre llamadas a distintos servicios).
3. **¿Qué produce Cloud Build y qué no hace por sí solo?** Produce artefactos de build/test (y la imagen publicada en Artifact Registry); no administra por sí solo el despliegue a ambientes.
4. **¿Qué define un delivery pipeline de Cloud Deploy?** La secuencia de targets (ej. dev → staging → prod) por los que avanza un artefacto, con aprobaciones y validaciones entre etapas.
5. **¿Qué diferencia a un despliegue canary de uno blue/green?** Canary desplaza tráfico gradualmente monitoreando señales; blue/green despliega el entorno nuevo en paralelo y corta el tráfico de una vez cuando está validado.
6. **¿Cómo se apoya un despliegue canary en Cloud Run sin infraestructura adicional?** Usando el mecanismo nativo de revisiones y tráfico dividido de Cloud Run.
7. **¿Por qué IaC no es lo mismo que CI/CD?** IaC describe qué infraestructura debería existir; CI/CD decide cuándo y cómo se aplica ese cambio de forma segura y repetible.
8. **¿Qué aprobación tendría típicamente un pipeline entre non-prod y prod?** Automática en non-prod tras pasar tests, y manual (con revisión del cambio propuesto) antes de aplicar en prod.
9. **¿Con qué identidad corre un build de Cloud Build?** Con una service account propia del build, no con la tuya. Importa porque esa cuenta necesita exactamente los permisos de publicar en Artifact Registry y desplegar, y nada más: un build con permisos amplios es una vía de escalación desde cualquier cambio en el repositorio.
10. **¿Por qué construir la imagen una sola vez y promoverla?** Porque garantiza que lo que se validó en staging es **bit a bit** lo que llega a producción. Reconstruir en cada ambiente reintroduce diferencias —una dependencia que cambió, una capa base actualizada— y convierte las pruebas anteriores en no concluyentes.
11. **¿Por qué un rollback en Cloud Run es cuestión de segundos?** Porque no reconstruye ni redespliega: mueve el puntero de tráfico a una revisión que ya existe y ya está sana. Lo impediría haber borrado esa revisión, o que el rollback exija además revertir un cambio de datos o de esquema que la revisión anterior no entiende.

---

## 13 — BigQuery y analítica

1. **¿BigQuery necesita que aprovisiones clusters por adelantado bajo el modelo on-demand?** No, es serverless; solo se necesita aprovisionar si optas explícitamente por capacidad reservada.
2. **¿Qué diferencia a BigQuery de Cloud SQL en el tipo de carga?** BigQuery está optimizado para carga analítica (OLAP) sobre grandes volúmenes; Cloud SQL para carga operacional (OLTP) de baja latencia.
3. **¿Qué es una partición y qué columna se usa típicamente?** Un segmento de la tabla según una columna, típicamente de fecha/tiempo de ingestión, que permite escanear solo las particiones relevantes.
4. **¿Qué diferencia al particionado del clustering?** El particionado segmenta la tabla en bloques grandes (ej. por día); el clustering ordena físicamente los datos dentro de cada partición según columnas de alta cardinalidad.
5. **¿Qué es un slot?** Una unidad de capacidad de cómputo que BigQuery usa para ejecutar una query.
6. **¿Qué diferencia al pricing on-demand del de capacidad reservada?** On-demand cobra por bytes escaneados por query; capacidad reservada cobra por slots reservados durante un período, independiente de cuánto escanean las queries.
7. **¿Qué diferencia a un streaming insert de una carga batch en latencia?** Streaming hace el dato consultable casi en tiempo real; carga batch depende del job de carga (minutos a horas).
8. **¿Una vista almacena resultados?** No. Se re-ejecuta contra los datos base en cada acceso; una vista materializada sí almacena (y mantiene actualizado) el resultado.
9. **¿De dónde suelen venir los datos que terminan en BigQuery?** De Pub/Sub (streaming de eventos), Cloud Storage (carga batch) y Cloud Logging sinks (logs exportados).
10. **¿BigQuery reemplaza a Firestore para el estado operacional?** No. BigQuery está optimizado para analítica sobre grandes volúmenes, no para transacciones de baja latencia sobre un registro individual.

---

## 10 — Preguntas de entrevista

### Junior refresher

- **P1. ¿VPC es global o regional?** Global.
- **P2. ¿Subnet es zonal o regional?** Regional; abarca todas las zonas de su región.
- **P3. ¿Qué es una Zone y qué problema aísla?** Un dominio de aislamiento de fallos dentro de una Region.
- **P4. ¿Qué hace Cloud NAT?** Permite que recursos sin IP externa inicien conexiones salientes a Internet, sin exponer un endpoint entrante.
- **P5. ¿Cloud Run escala a cero por defecto?** Sí.
- **P6. ¿Qué diferencia a Cloud Storage de Persistent Disk?** Cloud Storage es object storage vía API; Persistent Disk es block storage adjuntado a una VM.
- **P7. ¿Qué es un Project en la jerarquía de GCP?** La unidad de facturación, cuotas, APIs habilitadas y contenedor de la mayoría de los recursos.
- **P8. ¿Qué diferencia a un registro A de uno AAAA?** A mapea a IPv4; AAAA mapea a IPv6.
- **P9. ¿Qué es Pub/Sub, en una frase?** El servicio unificado de mensajería de GCP, que cubre tanto cola punto-a-punto como pub/sub fan-out.
- **P10. ¿Qué permite revisar terraform plan antes de aplicar cambios?** Los cambios propuestos, como previsualización tipo change set.

### Mid

- **P11. ¿Auto-mode vs custom-mode VPC?** Auto-mode crea subnets automáticamente con rangos predefinidos en cada región; custom-mode deja el direccionamiento bajo control total del equipo.
- **P12. ¿Firewall rules admiten DENY?** Sí, junto con ALLOW, evaluadas por prioridad numérica.
- **P13. ¿Instance Template vs Managed Instance Group?** El Template define la configuración (machine type, image, disco); el MIG administra el conjunto de instancias creadas a partir de ese Template.
- **P14. ¿Cloud Run vs Cloud Functions (2nd gen)?** Cloud Run despliega cualquier container completo; Cloud Functions despliega una función individual, y está construido sobre Cloud Run.
- **P15. ¿GKE Autopilot vs GKE Standard?** Autopilot administra los nodos por completo; Standard da control total del node pool.
- **P16. ¿External HTTP(S) LB vs Internal HTTP(S) LB?** External es global y expone tráfico desde Internet; Internal es regional y sirve tráfico interno dentro de la VPC.
- **P17. ¿HA regional de Cloud SQL vs Read Replica?** HA regional resuelve failover; Read Replica resuelve escalar lecturas.
- **P18. ¿Cloud SQL vs AlloyDB?** AlloyDB es un motor propio de GCP compatible con PostgreSQL, optimizado para mayor rendimiento; Cloud SQL PostgreSQL es PostgreSQL administrado estándar.
- **P19. ¿Por qué diseñar Firestore desde access patterns?** Porque las colecciones/índices determinan qué consultas serán eficientes; no hay joins nativos para corregirlo después.
- **P20. ¿Cuándo Firestore necesita un índice compuesto declarado explícitamente?** Cuando una consulta combina condiciones sobre múltiples campos de una forma que el índice automático de campo único no cubre.
- **P21. ¿Primitive vs Predefined vs Custom role?** Primitive es muy amplio (Owner/Editor/Viewer); Predefined es curado por Google para un caso de uso; Custom combina exactamente los permisos necesarios.
- **P22. ¿Qué es envelope encryption?** Una key de KMS cifra una data key más pequeña, y esa data key cifra el volumen de datos.
- **P23. ¿Push vs Pull subscription?** Push hace que Pub/Sub llame a un endpoint HTTP; pull hace que el subscriber solicite mensajes activamente.
- **P24. ¿Qué hace un dead-letter topic?** Recibe mensajes que superan el número de intentos configurado, para investigación y recuperación controlada.
- **P25. ¿Cloud Logging vs Cloud Monitoring?** Logging responde qué eventos ocurrieron; Monitoring responde cómo está funcionando el sistema.

### Senior

- **P26. ¿Qué resuelve Shared VPC que VPC Peering no resuelve igual de bien?** Que varios proyectos de servicio usen subnets de una sola VPC administrada centralmente, sin peering entre cada proyecto.
- **P27. ¿VPC Peering es transitivo?** No.
- **P28. ¿Private Service Connect vs Private Google Access?** PSC consume privadamente un servicio específico mediante un endpoint con IP interna; Private Google Access permite a VMs sin IP externa alcanzar APIs públicas de Google.
- **P29. ¿Cuándo Network Connectivity Center en lugar de un mesh de peering?** Cuando necesitas conectar muchas VPCs/redes a escala (hub-and-spoke).
- **P30. ¿Firestore es siempre fuertemente consistente para cualquier consulta?** Es fuertemente consistente para lecturas por ID y la mayoría de queries, pero afirmarlo sin matices es una sobregeneralización.
- **P31. ¿Cuándo Bigtable es mejor que Firestore?** Con volumen y throughput extremos, y acceso predominantemente por row key.
- **P32. ¿Las allow policies de IAM son aditivas? ¿Cómo se niega algo explícitamente?** Sí, son aditivas; la negación explícita requiere una IAM Deny policy.
- **P33. ¿Qué resuelve Workload Identity Federation frente a una key descargada?** Permite que cargas fuera de GCP actúen como una identidad de GCP sin necesitar una credencial de larga vida descargada.
- **P34. ¿Pub/Sub garantiza exactly-once por defecto?** No; por defecto es at-least-once, y exactly-once es una feature explícita bajo condiciones específicas.
- **P35. ¿Qué diferencia de propósito hay entre Cloud Tasks y Pub/Sub?** Cloud Tasks orquesta llamadas HTTP puntuales controladas por el productor; Pub/Sub es fan-out desacoplado.
- **P36. ¿Qué resuelve un timeout budget?** Reparte el tiempo total tolerable de una request entre cada salto de la cadena de llamadas.
- **P37. ¿Estados de un circuit breaker?** CLOSED, OPEN, HALF-OPEN.
- **P38. ¿Qué resuelve un bulkhead?** Aísla recursos entre dependencias para que la saturación de una no consuma toda la capacidad del sistema.
- **P39. ¿Particionado vs Clustering en BigQuery?** Particionado segmenta la tabla en bloques grandes; clustering ordena físicamente dentro de cada segmento.
- **P40. ¿On-demand vs capacidad reservada en BigQuery?** On-demand cobra por bytes escaneados; capacidad reservada cobra por slots reservados en el tiempo.

### Software Architect

- **P41. ¿Cómo diseñarías DR con RTO 5 min / RPO 1 min?** Con esos números, Backup & Restore y Pilot Light quedan descartados. Warm Standby ya cumple RTO de minutos; Multi-site Active/Active lo supera pero a mayor costo — la decisión depende de si el RPO de 1 minuto exige datos sincronizados activamente en ambas regiones o si una réplica con failover rápido basta.
- **P42. ¿Cuándo justificarías GKE sobre Cloud Run?** Cuando la carga necesita control de red fino, sidecars complejos, DaemonSets o recursos de Kubernetes específicos que Cloud Run no expone.
- **P43. ¿Cómo estructurarías IAM/Organization Policies entre dev/test/prod?** Proyectos separados por ambiente, con Organization Policies y allow policies distintos por ambiente para limitar el blast radius de un incidente no productivo.
- **P44. ¿BigQuery o Firestore para una nueva feature de reporting?** BigQuery, si el reporting es analítico sobre grandes volúmenes históricos; Firestore solo si el "reporting" en realidad es una consulta operacional acotada por access pattern conocido.
- **P45. ¿Qué trade-offs entre pilares nombrarías al justificar multi-región?** Más Reliability (multi-región) generalmente cuesta más en Cost optimization y añade complejidad operativa (Operational excellence) — la respuesta debe nombrar explícitamente qué pilar se sacrifica parcialmente.
- **P46. ¿Cuándo Workflows en lugar de Eventarc + Cloud Run?** Cuando conoces de antemano la secuencia de pasos y quieres orquestarla explícitamente en un solo lugar.
- **P47. ¿Cloud VPN vs Cloud Interconnect para conectividad on-premises?** VPN para aprovisionamiento rápido sobre Internet con cifrado; Interconnect para throughput/consistencia dedicados cuando el compromiso de costo/tiempo de aprovisionamiento se justifica.
- **P48. ¿Qué justifica Apigee sobre API Gateway?** Necesidad de monetización, developer portal o analítica enterprise de APIs expuestas a terceros.
- **P49. ¿Cómo diseñarías particionado/clustering de una tabla de eventos de alto volumen?** Particionar por fecha/tiempo de ingestión, y clusterizar por la columna de alta cardinalidad más usada en filtros (ej. `user_id` o `device_id`).
- **P50. ¿Qué revisarías antes de aprobar un cambio de Terraform que fuerza replacement en una BD de producción?** El Change Set/plan completo, si existe backup/snapshot reciente, la `DeletionPolicy`/protección equivalente, el plan de downtime/cutover y el mecanismo de rollback.

### Troubleshooting

- **P51. VM sin IP externa no llega a Internet.** Revisar si tiene Cloud NAT configurado (o si el tráfico requiere Private Google Access, según el destino).
- **P52. Cloud Run no puede conectar a una VM dentro de la VPC.** Falta un Serverless VPC Access connector.
- **P53. Query en Firestore falla pidiendo un índice.** Significa que la consulta compuesta necesita un índice declarado explícitamente; se soluciona creando el índice indicado.
- **P54. Throughput de Bigtable degradado bajo carga.** Revisar si hay una hot partition por mal diseño de row key (ej. timestamp creciente sin prefijo de alta cardinalidad).
- **P55. terraform apply falló a mitad de camino.** El state refleja lo realmente aplicado; se corrige con una nueva ejecución, no con rollback automático.
- **P56. terraform plan reporta drift.** Decidir entre revertir el cambio manual (aplicando) o incorporarlo formalmente con `terraform import`/actualizando la configuración, en lugar de dejar la desviación sin resolver.
- **P57. Consumer de Pub/Sub reprocesa mensajes duplicados.** Revisar el diseño de idempotencia del consumer, dado que la entrega es at-least-once por defecto.
- **P58. Firewall rule bloquea tráfico esperado.** Usar Connectivity Tests para verificar estáticamente si existe un path válido y en qué punto (ruta, firewall, peering) se bloquea.

---

# Parte II — Serie práctica

Respuestas a las "Preguntas rápidas" de [`L00`](l00-idea-lab-practico.md), de los labs `LNN` y de los apéndices `ANN`.
Mismas reglas: numeración idéntica a la del documento original.

---

## L00 — Introducción a la serie práctica

1. **¿Qué condición tiene que cumplir un tema para entrar al laboratorio de pago?** Al menos una de cuatro: lo hace cumplir Google y nadie más, el fallo real difiere del emulado, solo se conoce pagando, o es la costura entre tu código y GCP.
2. **¿En qué se diferencian el crédito de bienvenida y el Free Tier?** El crédito son $300 que se agotan o vencen a los 90 días; el Always Free son cuotas mensuales por producto que no caducan. El lab se diseña contra el segundo para que no expire en tres meses.
3. **¿Por qué "el control plane de Kubernetes es caro" no sirve en GCP?** Porque el Free Tier de GKE aporta $74.40 mensuales, que cubren un cluster zonal encendido todo el mes. El argumento correcto es el riesgo de teardown incompleto (balanceo y PersistentVolumes huérfanos) y la latencia de iteración de 5–15 minutos frente a los 40 segundos de `kind`.
4. **De los ocho aprendizajes de "un microservicio en GKE", ¿cuáles son de GCP?** Tres: Workload Identity Federation, la integración Ingress/Gateway con Cloud Load Balancing y los clusters VPC-native con alias IP ranges. Los otros cinco se practican gratis en local.
5. **¿Qué pregunta decide el caso dudoso?** "¿Qué me enseña este producto que no me enseñe el mismo software en un contenedor en mi máquina?". Dos conceptos → drill; nada → contenedor local; el modelo entero → lab de nube.
6. **¿Por qué no hay un Application Load Balancer global delante de Cloud Run?** Porque un forwarding rule global cuesta del orden de $0.025/h (~$18/mes) y es evitable: Cloud Run ya publica una URL HTTPS con certificado administrado sin cobrar por ella.
7. **¿Por qué el lab evita Cloud NAT?** Porque cobra por hora de gateway y por GiB procesado, y no hace falta: para alcanzar las APIs de Google desde una subnet sin IP externa está Private Google Access, que no tiene cargo adicional.
8. **¿Cuál es el único cargo real del tronco?** Artifact Registry: la cuota gratuita es de 0,5 GB y cada despliegue deja una imagen más. Es acumulativo, no puntual.
9. **¿Un presupuesto detiene el gasto?** No: solo avisa. Para que ocurra algo automáticamente hay que publicar la notificación en un topic de Pub/Sub y actuar sobre ella —el patrón documentado llega a deshabilitar la facturación del proyecto—, o usar un spend cap budget donde exista.
10. **¿Qué le falta al emulador de Pub/Sub?** La autenticación OIDC del push, el IAM y varias políticas de entrega. Importa para [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) porque el 403 de una push subscription es justo lo que el emulador no reproduce.
11. **¿Qué tres cosas hay que saber antes de `gcloud projects delete`?** Que el proyecto queda 30 días en recuperación y sigue contando para tu cuota; que el borrado no corta la facturación al instante (hay que deshabilitarla antes); y que un lien lo bloquea hasta que lo quites.
12. **¿Qué sobrevive al borrado del proyecto?** Los presupuestos y alertas, que cuelgan de la cuenta de facturación, y las Organization Policies, que cuelgan de la jerarquía.
13. **¿Qué estado deja [`L03`](l03-terraform-desde-la-cli.md) y qué asume [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md)?** [`L03`](l03-terraform-desde-la-cli.md) deja el bucket de state, el bucket de datos y Firestore vacío; [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) asume esa infraestructura creada con Terraform y la amplía.
14. **¿Por qué BigQuery entra como drill y Cloud SQL no?** Porque BigQuery tiene cuota Always Free (1 TiB de consulta, 10 GiB de almacenamiento) que cubre el ejercicio entero, mientras que Cloud SQL no tiene cuota gratuita y factura por hora de instancia y por almacenamiento.
15. **¿Qué tres características de GCP dan ocho labs y no cuatro?** Que lo barato se practica en vez de contarse (la red sale $0.00), que el modelo de identidad no cabe en media sesión, y que el contrato de Cloud Run y el flujo de eventos son dos diagnósticos distintos.
16. **¿Por qué la red es lab del tronco?** Porque en GCP una VPC, sus subnets, sus firewall rules, Private Google Access y los Connectivity Tests no cuestan nada, y es un tema de toda entrevista de arquitectura.
17. **¿Por qué Cloud Run y los eventos van en labs separados?** Para que, cuando algo falle, puedas decir si el problema es del contenedor o de la entrega. Mezclarlos junta dos diagnósticos distintos en la misma sesión.
18. **¿Qué hace `--log-http`?** Imprime la petición y la respuesta HTTP completas del comando. Es el puente CLI→SDK porque te da URL, método y cuerpo exactos para escribir la misma llamada desde código.
19. **¿Por qué un `create` desde un SDK necesita código extra?** Porque casi todo `create` devuelve una `Operation`, no el recurso. `gcloud` hace el polling por ti; desde el SDK la espera es tuya y explícita.
20. **¿Por qué un barrido por labels no demuestra limpieza?** Porque los recursos que un controlador crea en tu nombre no llevan tus labels, y varios tipos de recurso no admiten labels. Sirven para atribuir gasto, no para demostrar teardown.
21. **¿En qué orden se borran los objetos de Kubernetes y el cluster?** Primero `kubectl delete` de `Ingress`, `Service` de tipo `LoadBalancer` y `PersistentVolumeClaim`; se espera a que el controlador termine; y solo entonces se borra el cluster. Al revés quedan forwarding rules, backend services, URL maps, NEGs y discos huérfanos.

---

## L01 — Proyecto, jerarquía, `gcloud` y blindaje de costos

1. **¿Qué cuatro cosas es un proyecto?** La unidad de aislamiento, de facturación, de cuota y de borrado, las cuatro a la vez.
2. **`projectId`, `name`, `projectNumber`.** El `projectId` es el identificador global e inmutable que usas en los comandos; el `name` es una etiqueta legible y cambiable; el `projectNumber` lo asigna Google y aparece en las direcciones de los service agents y en `--filter-projects` de un presupuesto.
3. **¿Cuenta personal de Gmail?** No tienes Organization: los proyectos cuelgan de "No organization". No podrás practicar la herencia entre niveles ni las Organization Policies; el resto del lab funciona igual.
4. **¿En qué dirección se heredan las allow policies?** Hacia abajo, de Organization a Folder a Project a recurso. Aditivas significa que el acceso efectivo es la unión de todo lo concedido en el recurso y por encima de él.
5. **¿Cuál usa Terraform?** Las Application Default Credentials, es decir `gcloud auth application-default login`. `gcloud auth login` solo autentica la CLI: por eso `gcloud` funciona y Terraform devuelve `PERMISSION_DENIED` con la misma persona.
6. **¿Por qué `compute/region` no basta para `gcloud run`?** Porque son propiedades de secciones distintas: `run/region` solo la leen los comandos de Cloud Run. Ningún comando lee las dos.
7. **¿Qué código devuelve la API apagada?** `FAILED_PRECONDITION` con `SERVICE_DISABLED`, no `PERMISSION_DENIED`. Esa distinción evita revisar IAM cuando el problema no es IAM.
8. **Habilitaste y sigue fallando.** La primera hipótesis es el retardo de propagación, que el propio mensaje anuncia. Espera y reintenta antes de dudar de los permisos.
9. **¿Por qué `project=inv_lab`?** Porque los labels de GCP solo aceptan minúsculas, números, guiones y guiones bajos en clave y valor. `Project=inv-lab` lo rechaza la API.
10. **¿Para qué sirven los labels?** Para atribuir gasto en el informe de facturación. **No** para demostrar que un teardown quedó limpio.
11. **¿Un presupuesto detiene el gasto?** No. Para que ocurra algo hay que enviarlo a un topic de Pub/Sub y actuar sobre esa notificación; el patrón documentado llega a deshabilitar la facturación del proyecto.
12. **¿Por qué `--filter-projects` pide el `projectNumber`?** Porque el filtro de un presupuesto se expresa con el nombre de recurso `projects/<projectNumber>`, que es la forma canónica en la API de facturación.
13. **`current-spend` frente a `forecasted-spend`.** El primero dispara sobre el gasto acumulado; el segundo, sobre la proyección del mes. En un lab sirve más el segundo: detecta en horas un recurso olvidado que cobra por hora.
14. **¿Dónde vive un presupuesto?** En la cuenta de facturación, no en el proyecto. Por eso sobrevive al borrado del proyecto y hay que borrarlo aparte.
15. **¿Qué saber antes de `projects delete`?** Los 30 días de recuperación consumiendo cuota, que la facturación no se corta al instante (deshabilítala antes) y que un lien bloquea el borrado.

---

## L02 — IAM: allow policies, service accounts e impersonation

1. **¿Qué compone un binding?** Un rol y una lista de principals. La allow policy es una lista de bindings adjunta a **un** recurso.
2. **Herencia y aditividad.** Se heredan hacia abajo por la jerarquía; aditivas significa que el acceso es la unión de todos los niveles, sin restas.
3. **¿Se puede quitar desde abajo un rol concedido arriba?** No dentro de una allow policy. Para eso existen las IAM Deny policies, que son otro objeto y se evalúan antes.
4. **Rol en el recurso equivocado.** El comando funciona y devuelve la policy actualizada: GCP no valida que el rol tenga sentido sobre ese recurso. La consecuencia es la certeza falsa de que "el rol está puesto" mientras la operación sigue fallando.
5. **¿Por qué `get-iam-policy` no muestra un permiso que tienes?** Porque devuelve solo los bindings adjuntos a ese recurso, nunca los heredados de niveles superiores.
6. **`roles/run.invoker` en el proyecto o en el servicio.** En el servicio, permite invocar ese servicio; en el proyecto, todos los servicios de Cloud Run del proyecto, incluidos los futuros.
7. **¿Qué da Policy Troubleshooter?** La evaluación explicada nivel por nivel de la jerarquía, no un sí/no. Se le pasa el **permiso atómico** (`pubsub.topics.publish`), no el rol.
8. **¿Cómo ves los permisos de un rol?** `gcloud iam roles describe roles/<nombre> --format='value(includedPermissions)'`.
9. **¿Identidad y recurso a la vez?** Como identidad, una service account aparece como miembro de bindings. Como recurso, tiene su propia allow policy que dice quién puede actuar en su nombre.
10. **¿Qué rol hace falta para impersonar?** `roles/iam.serviceAccountTokenCreator` **sobre esa service account**, no sobre el proyecto.
11. **¿Por qué la impersonation es mejor respuesta?** Porque el token es de corta duración y porque la acción queda registrada en los Audit Logs con **tu** identidad, no con la de la service account: hay trazabilidad de quién actuó.
12. **Costo del rol personalizado.** Lo mantienes tú: cuando Google agrega permisos nuevos a una API, el predefinido los recibe y el tuyo no.
13. **Orden de evaluación.** Primero las deny policies —si alguna deniega, se acabó—, después la unión de las allow policies.
14. **Keys de una service account.** Solo deben aparecer de tipo `SYSTEM_MANAGED`. Una `USER_MANAGED` significa que alguien descargó una clave y hay que borrarla.
15. **¿Por qué se evita la SA por defecto de Compute Engine?** Porque suele traer `roles/editor` sobre todo el proyecto: un servicio que la use corre como administrador y enseña lo contrario del privilegio mínimo.

---

## L03 — Terraform desde la CLI

1. **¿Qué da Terraform que no dé un script de `gcloud`?** El state: saber **qué creó**, que es lo único que permite destruir con certeza. Un script sabe crear; no sabe qué existe.
2. **El huevo y la gallina del bucket de state.** Para escribir el state necesita el bucket; para crear el bucket con ese backend necesitaría escribir el state. Se rompe creándolo con `gcloud` una sola vez.
3. **El versioning del bucket de state.** Conserva la versión anterior en cada escritura. Es la única protección real contra un `apply` que deja el state corrupto, y cuesta unos kilobytes.
4. **`version =` frente a `.terraform.lock.hcl`.** El primero es una restricción; el lock es el resultado, con versión exacta y hashes. **El lock se versiona en git**, como un `package-lock.json`.
5. **`~> 6.0` frente a versión exacta.** Un rango deja que mañana entre otra versión y que el mismo HCL produzca un plan distinto: destruye la reproducibilidad que el lab quiere enseñar.
6. **`(known after apply)`.** Valores que asigna el servidor y que nadie conoce hasta crear el recurso.
7. **`plan -out` + `apply tfplan`.** Aplica exactamente el plan que revisaste, sin recalcular y sin preguntar. Sin `-out`, entre el `plan` y el `apply` el mundo pudo cambiar.
8. **`# forces replacement`.** Marca un atributo inmutable: el cambio obliga a destruir y recrear. Impone no aplicar nunca un plan con `must be replaced` sin leer qué recurso y qué atributo lo fuerzan.
9. **Los dos bloques del plan con drift.** `has been changed` es lo que Terraform **descubrió** al refrescar; `will be updated in-place` es lo que **propone hacer**, que es deshacerlo.
10. **¿Decide Terraform quién tiene razón?** No: asume que el HCL es la verdad y propone devolver el mundo a él. La decisión sobre si el cambio externo era legítimo es humana.
11. **Por qué no se edita ni se comparte el state.** Contiene el inventario completo y, en varios recursos, valores sensibles **en claro**. Terraform no los cifra: el cifrado lo pone Cloud Storage y el control de acceso, el IAM del bucket.
12. **`delete_protection_state` frente a `deletion_policy`.** La primera es una protección del **servicio** que impide el borrado desde cualquier cliente; la segunda es una instrucción **para Terraform** (`ABANDON` lo saca del state sin borrar, `DELETE` lo borra).
13. **Por qué un `apply` antes del `destroy`.** Porque Terraform no puede modificar y borrar el mismo recurso en una sola operación: hay que abrir el candado del servicio en un `apply` previo.
14. **¿De quién es el candado?** Si el mensaje menciona un atributo del provider (`force_destroy`), es de Terraform y se abre en el HCL. Si trae un código de la API (`Error 400: The database is protected`), es del servicio y se abre con un `apply`.
15. **"No changes" con un bucket creado a mano.** No miente: dice que el mundo coincide con **su** configuración, y ese bucket nunca estuvo en ella. Se le escapan lo creado a mano, lo creado por un service agent y lo que quedó de un `apply` a medias.

---

## L04 — Red: VPC, firewall y diagnóstico

1. **Alcances.** VPC global, subnet regional, instancia zonal.
2. **Dos regiones en la misma VPC.** No necesitan peering: el enrutamiento entre subnets de la misma VPC es automático.
3. **Auto-mode frente a custom-mode.** Auto-mode crea una subnet por región con rangos predefinidos; custom-mode las creas tú. El lab usa custom-mode para controlar los rangos y evitar solapamientos.
4. **Las reglas implícitas.** Egress `allow` a `0.0.0.0/0` e ingress `deny` de `0.0.0.0/0`, ambas con prioridad 65535. Producen el comportamiento por defecto: sale todo, no entra nada.
5. **No es un security group.** La regla vive en la VPC, no en la instancia, y selecciona a qué cargas aplica por **target tags** o **target service accounts**. Añadir un tag cambia qué reglas afectan a una instancia sin tocar la regla.
6. **Prioridad 900 frente a 1000.** Gana la 900: **el número más bajo gana**.
7. **Regla sin targets.** Aplica a **toda la VPC**, que casi nunca es lo que quieres.
8. **Orden de evaluación.** Primero las hierarchical firewall policies (Organization/Folder), después las reglas de la VPC por prioridad ascendente, y al final las implícitas.
9. **`get-effective-firewalls`.** Devuelve el conjunto **ya combinado** de políticas jerárquicas, policies de red y reglas de VPC, en el orden en que se evalúan; `firewall-rules list` solo lista las de la VPC.
10. **Longest prefix match.** Entre rutas que coinciden con un destino gana **la más específica**, con independencia de la prioridad.
11. **Private Google Access.** Permite que una instancia sin IP externa alcance las APIs de Google por su IP interna. Se activa por subnet, no cuesta nada y el tráfico no sale a Internet, así que evita montar Cloud NAT.
12. **¿Cuándo sí hace falta Cloud NAT?** Cuando el destino es Internet de verdad —un paquete de PyPI, una API de terceros—, no cuando el destino es Google.
13. **Private Google Access frente a Private Service Connect.** El primero te lleva a las APIs públicas de Google por dentro; el segundo trae un servicio concreto a un endpoint con **IP interna dentro de tu VPC**. No son sustitutos.
14. **Flow Logs.** Registran metadatos de las conexiones —IPs, puertos, protocolo, bytes, latencia—, **no el contenido**. El volumen lo mueven `flow_sampling`, `aggregation_interval` y `metadata`.
15. **Connectivity Test frente a `ping`.** Hace análisis de configuración: simula el camino contra reglas y rutas reales y nombra el salto y la regla que dropea. Por eso funciona con la máquina apagada, y por eso dice **por qué** falla y no solo que falla.
16. **Sin conector de Serverless VPC Access.** Porque factura por instancia y por hora mientras exista, y los servicios del lab solo hablan con APIs de Google. Un conector hace falta cuando el destino tiene **IP privada dentro de tu red**: Cloud SQL privada, Memorystore, un servicio interno.

---

## L05 — Cloud Run: contrato, revisiones y tráfico

1. **Las cuatro cláusulas.** Escucha en `PORT` y en `0.0.0.0`; arranca dentro del timeout; responde por HTTP con la concurrencia que la plataforma decide; y acepta que te apaguen sin aviso cuando no haya tráfico.
2. **Sin estado en memoria.** Porque entre peticiones la instancia puede no existir: no hay tareas en segundo plano después de responder ni disco local que sobreviva.
3. **`127.0.0.1` frente a `0.0.0.0`.** Desde fuera del contenedor, escuchar en localhost es no escuchar. El mensaje es el mismo porque la plataforma solo comprueba si algo responde en `PORT`.
4. **Las tres causas, en los logs.** Arranque anunciando **otro puerto** → no lees `PORT`; arranque normal sin respuesta → escuchas en `127.0.0.1`; **stack trace** → revienta antes de escuchar.
5. **`exec` en el `CMD`.** Hace que tu proceso sea el PID 1 y reciba las señales. Sin él, la shell es PID 1 y **`SIGTERM` no llega**: no hay apagado ordenado.
6. **`--workers 1 --threads 8`.** Cloud Run escala **añadiendo instancias**, no procesos. Varios workers en 1 vCPU multiplican la memoria sin añadir throughput.
7. **Sin `--service-account`.** Corre con la service account por defecto de Compute Engine, que suele traer `roles/editor` sobre todo el proyecto: el servicio como administrador.
8. **Credenciales sin archivos.** La plataforma entrega tokens de la service account del servicio por el **metadata server**, y las librerías los encuentran por la cadena de ADC.
9. **Los dos tokens.** Un **identity token** (`print-identity-token`) invoca un servicio privado; el **access token** (`print-access-token`) llama a las APIs de Google y es el que la gente usa por error.
10. **`--allow-unauthenticated`.** Añade `allUsers` como principal con `roles/run.invoker`: publica la URL a Internet sin autenticación.
11. **Concurrencia.** Con `--concurrency 1`, 1000 peticiones simultáneas piden hasta 1000 instancias; con 80, unas 13. Como se factura por vCPU-s y GiB-s de instancia, es un dial directo de costo.
12. **`--min-instances 1`.** Compras la desaparición del cold start; pagas vCPU y memoria 24/7 aunque no llegue una sola petición.
13. **Timeout de `gunicorn` desactivado.** Para que mande el `--timeout` del servicio. Dos relojes compitiendo producen cortes que parecen aleatorios.
14. **`--no-traffic --tag canary`.** Crea la revisión sin darle tráfico y le asigna una URL propia y estable para probarla aislada antes de exponerla; sin `--no-traffic`, cada despliegue se lleva el 100 % al instante.
15. **Rollback en segundos.** Porque no reconstruye ni redespliega: mueve un puntero de tráfico a una revisión que ya existe y ya está sana.
16. **El valor del secreto fuera del HCL.** Porque acabaría **en claro en el state**, que es el problema que Secret Manager viene a resolver. El binding de `secretAccessor` va **sobre el secreto**, no sobre el proyecto.
17. **`--set-secrets`.** Guarda una referencia `nombre:versión`, no el valor; se resuelve al arrancar cada instancia con la identidad del servicio. `:latest` es cómodo y no determinista: añadir una versión cambia el comportamiento sin desplegar nada.
18. **El único cargo real.** Artifact Registry: 0,5 GB de cuota y una imagen nueva por despliegue. Crece solo porque nadie decide acumularla.

---

## L06 — Datos y eventos: Firestore, Pub/Sub y Eventarc

1. **Elegir el ID del documento.** Con un ID que tú controlas, el mismo evento produce el **mismo documento** por muchas veces que llegue; `add()` genera uno nuevo cada vez y convierte cada reintento en un duplicado.
2. **`create()` frente a `set()`.** `create()` falla si el documento existe; `set()` lo sobrescribe en silencio. Con `create()` te enteras del duplicado y respondes sin volver a publicar.
3. **¿Exactly-once?** No como garantía general: Pub/Sub es **at-least-once**, y su modo exactly-once tiene alcance y condiciones acotadas. La respuesta de arquitectura correcta es siempre **hacer idempotente al consumidor**.
4. **La transacción.** Hace atómicas la lectura del stock y las dos escrituras; si otro proceso toca el mismo documento, se reintenta sola. Sin ella, dos entregas simultáneas se pisan y el stock queda mal.
5. **El código de respuesta es el protocolo.** Un 2xx es un **ack**; un 4xx o 5xx cuenta como entrega fallida y dispara el reintento. Devolver 200 cuando algo falló hace desaparecer el mensaje para siempre.
6. **El sobre del push.** Pub/Sub manda `{"message": {"data": "<base64>", ...}}`: tu payload va dentro de `data` y en base64. El cuerpo del POST no es tu JSON.
7. **Emulador sí, servicio no.** Porque el emulador no exige índices compuestos y el servicio sí, para consultas que combinan igualdad con ordenamiento por otro campo.
8. **El orden de los campos del índice.** Sí importa: primero el campo de igualdad, después el de ordenamiento. Un índice con el orden invertido no sirve para esa consulta.
9. **Los cinco pasos del push.** (1) Pub/Sub toma la identidad de `oidc_token`; (2) pide un ID token en su nombre; (3) POSTea con `Authorization: Bearer`; (4) Cloud Run valida y comprueba `run.invoker`; (5) tu handler responde 2xx o se reintenta.
10. **Sin `run.invoker`.** El productor sigue devolviendo 202: **no se entera**. Te enteras por las métricas de la subscription y por el 403 en los logs del servicio de destino.
11. **`ack_deadline` y tu handler.** El deadline tiene que ser mayor que el peor tiempo de proceso, y coherente con el `--timeout` del servicio. Si no, Pub/Sub reintenta mientras tu handler sigue trabajando y genera duplicados que no son de red.
12. **DLQ sin subscription.** Un topic sin subscription **descarta** los mensajes: el veneno se pierde y el ejercicio no demuestra nada.
13. **Los dos bindings del service agent.** `roles/pubsub.publisher` en el DLQ para escribir, y `roles/pubsub.subscriber` en la subscription de origen para confirmar el original. Sin el segundo, el mensaje va al DLQ **y además se sigue reintentando**: un bucle.
14. **Firestore a nivel proyecto.** Porque Firestore **no expone allow policies por colección ni por documento** —el control fino son las Security Rules, otro sistema—, así que el proyecto es el nivel más específico disponible.
15. **Lo que crea Eventarc.** Un topic de Pub/Sub y una subscription en tu proyecto, más dos service agents implicados. Importa porque aparecen en el inventario sin estar en ningún HCL y hay que verificar que el `destroy` se los lleva.
16. **Sin ordering keys.** Porque los movimientos son incrementos y la suma es conmutativa: el orden no cambia el resultado. Serializar por clave tendría un costo de throughput sin beneficio, y saber justificar que **no** hace falta también es diseño.

---

## L07 — Observabilidad: logs, métricas y auditoría

1. **Los tres pilares.** Los logs responden "¿qué pasó?"; las métricas, "¿cuánto pasa y desde cuándo?"; los audit logs, "¿quién lo hizo?".
2. **`textPayload` frente a `jsonPayload`.** El primero solo se busca por subcadena; el segundo tiene cada campo indexado. Se obtiene escribiendo un **JSON válido** en stdout.
3. **Sin campo `severity`.** Todo lo de `stdout` aparece como `INFO` y **todo lo de `stderr` como `ERROR`**, lo que llena el panel de falsos errores.
4. **Alertar sobre un log.** No se puede: una alerta necesita una serie temporal. La log-based metric es el puente de log a número.
5. **`DELTA` frente a `GAUGE`.** `DELTA` cuenta cuántas veces ocurrió algo en un intervalo —lo correcto para un contador de eventos—; `GAUGE` es un valor instantáneo.
6. **`sku` sí, `event_id` no.** Por cardinalidad: un label con muchos valores distintos multiplica las series temporales y llega a los límites del servicio.
7. **¿Cuenta los logs de ayer?** No. Una log-based metric no es retroactiva: solo cuenta desde que existe.
8. **El prefijo del `metric.type`.** `logging.googleapis.com/user/`. Si lo olvidas, la política **no da error** y simplemente no dispara nunca.
9. **`aggregations`.** Alinea los puntos en ventanas y los agrega antes de compararlos con el umbral. Sin ellas comparas puntos sueltos y la alerta se comporta de forma errática.
10. **Las cuatro causas del silencio.** El filtro de la métrica no coincide con lo que escribe el código; el `metric.type` sin prefijo; faltan `aggregations`; la métrica se creó después de los logs que esperabas contar.
11. **`str(exc)` no basta.** Sin stack trace no hay firma con la que agrupar, así que Error Reporting registra un error más y no lo agrupa.
12. **Trazas en Cloud Run.** La plataforma genera un span por petición y un ID de traza que llega en `X-Cloud-Trace-Context`; los spans internos los añade tu código.
13. **El salto de Pub/Sub.** La traza no lo cruza sola: hay que **propagar el contexto como atributo del mensaje** y recogerlo en el consumidor, o quedan dos trazas inconexas.
14. **Admin Activity frente a Data Access.** El primero registra toda llamada que **modifica** configuración o metadatos y está siempre activo; el segundo registra lecturas y escrituras de **datos** y hay que habilitarlo.
15. **Cuál cobra.** Data Access, por volumen: cada lectura genera una entrada y en un servicio con tráfico eso multiplica la ingesta. Habilitarlo "por si acaso" en todo es de las formas más rápidas de disparar la factura de logs.
16. **Qué se paga en Logging.** La **ingesta**, no la consulta. Los primeros 50 GiB por proyecto al mes son gratis.
17. **Admin Activity.** 400 días en el bucket `_Required`, gratis y **no configurable**: no se puede acortar ni borrar.
18. **Bajar la factura de logs.** **Exclusiones**, para dejar de ingerir lo que no vas a mirar, y **sinks**, para enrutar a un destino más barato (Cloud Storage) o más analizable (BigQuery).

---

## L08 — Costos y destrucción verificada

1. **Por qué no basta borrar el proyecto.** Porque funciona sin enseñarte nada, y porque en un trabajo real casi nunca puedes borrar el proyecto: hay otras cosas dentro.
2. **Las tres capas.** `terraform destroy` es el ejercicio; el barrido de Cloud Asset Inventory es la verificación; borrar el proyecto es la red de seguridad.
3. **La granularidad de la factura.** El **SKU**, no el producto: "External IP address reserved but unused" te dice el recurso exacto; "Compute Engine" no dice nada.
4. **El `$0.00` diferido.** Porque los datos de facturación se consolidan con retraso, del orden de horas: lo de esta tarde puede no aparecer todavía.
5. **El orden del `destroy`.** Inverso al grafo de dependencias, y lo deduce Terraform solo. Un script de `gcloud` borra en el orden en que lo escribiste y falla cuando alguien añade una dependencia.
6. **Cloud Run a mano.** Porque en esta serie los servicios se despliegan con `gcloud` y no están en el state. Es el trade-off de haber ganado agilidad en [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) y [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md).
7. **Los cuatro supervivientes.** Las service accounts y el topic del presupuesto (creados con `gcloud`), el bucket de state (no puede estar en su propio state) y los recursos que Eventarc creó en tu nombre.
8. **El bucket de state.** No puede administrarse a sí mismo, y se borra **el último**: mientras contenga el state es la memoria de Terraform.
9. **El barrido por labels.** No demuestra nada porque los recursos que crea un controlador no llevan tus labels y varios tipos no admiten labels. Sirven para atribuir gasto.
10. **`status` en `addresses list`.** `RESERVED` es reservada y **no adjunta**, la tarifa más cara; `IN_USE` es la barata.
11. **El inventario recién borrado.** El índice de Asset Inventory no es instantáneo: puede seguir mostrando lo que ya no existe, y también puede parecer vacío demasiado pronto.
12. **Fuera del proyecto.** El presupuesto y sus alertas (cuelgan de la cuenta de facturación), las Organization Policies (de la jerarquía), y —fuera de GCP— tu configuración de `gcloud` y tus credenciales.
13. **El orden facturación/borrado.** Primero deshabilitar la facturación, después borrar: el borrado del proyecto **no corta la facturación al instante** y puede seguir acumulando cargos hasta el cierre del ciclo.
14. **Un lien.** Una protección explícita contra el borrado del proyecto. Te lo encuentras al heredar un proyecto ajeno, y bloquea el borrado hasta que lo quites.
15. **Los 30 días.** El proyecto queda en estado de recuperación, se puede restaurar con `undelete` y **sigue contando para tu cuota**. El `projectId` no se reutiliza nunca.
16. **Volver a levantarlo.** Demuestra que el HCL versionado basta para reconstruir desde cero **sin ningún paso manual recordado de memoria**, que es lo que de verdad significa "infraestructura como código".
17. **Un cargo a las 48 horas.** O es de antes del teardown y solo se consolidó ahora; o el proyecto se borró sin deshabilitar la facturación primero; o hay algo en **otro proyecto** de la misma cuenta de facturación.

---

## A01 — `gcloud` de supervivencia

1. **`auth login` frente a `auth application-default login`.** El primero guarda la credencial que usa la CLI; el segundo escribe el archivo de ADC que usan Terraform y las librerías `google-cloud-*`. Tu script de Python necesita el segundo.
2. **Si revocas una.** Sigue funcionando la otra: son dos credenciales en dos archivos con dos revocaciones distintas.
3. **¿Por qué impersonation en vez de key?** La key es una credencial de larga duración, sin rotación, en tu disco. La impersonation da un token efímero y deja rastro con tu identidad. Requiere `roles/iam.serviceAccountTokenCreator` sobre la service account.
4. **Región configurada y el comando la pide.** Porque `compute/region` y `run/region` son propiedades distintas, y hay grupos de comandos que no leen ninguna propiedad de región y exigen `--region` explícito.
5. **`value(...)` frente a `json`.** `value()` imprime solo el valor, sin comillas ni encabezado: se puede meter directamente en una variable de shell.
6. **¿De dónde sale el nombre del campo?** Del `--format=json`: la ruta es la del JSON de la API, no la de la tabla por defecto.
7. **`=` frente a `:` en un filtro.** `=` es igualdad exacta; `:` es "contiene" (`zone:us-central1` matchea `us-central1-a`).
8. **`--flatten='bindings[].members[]'`.** Convierte cada elemento de las listas anidadas en un registro propio, produciendo una fila por par (rol, miembro). Hace falta porque una allow policy es una lista de bindings con listas de miembros dentro.
9. **¿Por qué `create` parece síncrono?** Porque `gcloud` hace polling de la `Operation` por ti salvo que le pases `--async`. Desde un SDK la espera la escribes tú.
10. **`--log-http` frente a `--verbosity=debug`.** El primero muestra la petición y respuesta HTTP reales contra la API; el segundo, el rastro interno de la CLI. La salida de `--log-http` incluye el header `Authorization` con tu token: hay que recortarlo antes de compartirla.
11. **`SERVICE_DISABLED` recién habilitada.** La primera hipótesis es el retardo de propagación, no IAM.
12. **Los tres identificadores.** `projectId` global e inmutable, `name` legible y cambiable, `projectNumber` asignado por Google. Con el tercero te topas en las direcciones de los service agents y en el filtro de un presupuesto.
13. **¿Por qué comillas simples?** Para que las expresiones con paréntesis, comas y `$` las expanda `gcloud` y no el shell.
14. **Token para Cloud Run privado.** Un **identity token** (`gcloud auth print-identity-token`). El que la gente usa por error es el access token de `print-access-token`, que sirve para llamar a las APIs de Google pero no para invocar el servicio.

---

## A02 — Costos, trampas y recursos huérfanos

1. **Los tres mecanismos.** El crédito de bienvenida ($300, 90 días, casi cualquier producto), el Always Free (cuota mensual por producto, sin caducidad) y el crédito del Free Tier de GKE ($74.40 mensuales, solo para la tarifa de administración de clusters).
2. **Cobran por existir.** Forwarding rules, IP externas estáticas reservadas, Persistent Disks, snapshots, instancias de Cloud SQL, clusters de GKE, Cloud NAT, Memorystore y túneles de VPN, entre otros.
3. **IP reservada y no adjunta.** Google la cobra a tarifa mayor porque es un recurso escaso retenido sin uso; es un desincentivo deliberado.
4. **El único cargo real del tronco.** Artifact Registry, por acumulación: 0,5 GB de cuota y una imagen nueva por despliegue.
5. **Borras una VM.** Puede sobrevivir su Persistent Disk si no tenía `auto-delete`, y con él los snapshots que se hayan tomado.
6. **Borras un cluster de GKE sin tocar sus objetos.** Sobreviven los recursos de balanceo que creó el controlador (forwarding rules, backend services, URL maps, NEGs) y los PersistentVolume, tengan política `Delete` o `Retain`.
7. **¿Por qué el barrido por labels no demuestra limpieza?** Porque lo que crea un controlador en tu nombre no lleva tus labels, y hay tipos de recurso que no los admiten.
8. **¿Para qué sí sirven?** Para atribuir gasto por label en el informe de facturación.
9. **La columna `status` de `addresses list`.** `RESERVED` significa reservada y no adjunta —la tarifa cara—; `IN_USE`, en uso. Te preocupa `RESERVED`.
10. **¿Detiene un presupuesto el gasto?** No. Hay que enviar la notificación a un topic de Pub/Sub y actuar sobre ella.
11. **¿Dónde vive un presupuesto?** En la cuenta de facturación; por eso sobrevive al borrado del proyecto.
12. **Antes del borrado de proyecto.** 30 días de recuperación consumiendo cuota, la facturación no se corta al instante, y un lien lo bloquea.
13. **`terraform destroy` con éxito y recursos vivos.** Porque solo destruye lo que está en su state: lo creado a mano, lo creado por un service agent y lo que quedó de un `apply` a medias es invisible para él.
14. **`--min-instances`.** Mantiene instancias encendidas siempre, rompiendo el escalado a cero: vCPU y memoria facturando 24/7 aunque no llegue un solo request.
15. **¿Por qué `us-central1`?** Porque varias cuotas del Always Free —Cloud Storage y Compute Engine, entre otras— solo aplican en determinadas regiones de EE. UU. Crear lo mismo en otra región te saca de la cuota gratuita sin ningún aviso.

---

## A03 — Catálogo de errores y diagnóstico

1. **API no habilitada.** `FAILED_PRECONDITION` con `SERVICE_DISABLED`, y el mensaje enlaza a la página de habilitación. Un problema de permisos daría `PERMISSION_DENIED`.
2. **Sigue fallando tras habilitar.** Retardo de propagación: esperar y reintentar antes de tocar IAM.
3. **Un 403 ambiguo.** GCP devuelve el mismo error para "no tienes permiso" y "no existe" para no filtrar la existencia de recursos ajenos.
4. **Causa más frecuente.** El binding puesto en el recurso equivocado. Se confirma comparando `get-iam-policy` del proyecto con el del recurso concreto.
5. **Policy Troubleshooter.** Explica qué policy se evaluó en cada nivel de la jerarquía y por qué el resultado fue ese, en vez de mostrar una sola policy.
6. **Los cuatro eslabones del push.** (1) La subscription firma un token OIDC con la SA indicada —puede faltar `--push-auth-service-account`—; (2) el service agent de Pub/Sub necesita poder crear tokens en nombre de esa SA; (3) esa identidad necesita `roles/run.invoker` sobre el servicio; (4) tu código debe responder 2xx o habrá reintentos.
7. **¿Por qué `run.invoker` en el servicio?** Porque a nivel proyecto concede invocar todos los servicios de Cloud Run, presentes y futuros.
8. **Service agent.** Una service account que Google crea y administra para que un servicio actúe en tu proyecto. Su forma es `service-<PROJECT_NUMBER>@gcp-sa-<servicio>.iam.gserviceaccount.com`, con el número porque es el identificador estable que usa la infraestructura de Google.
9. **Los dos permisos del dead-letter.** `roles/pubsub.publisher` en el topic de DLQ y `roles/pubsub.subscriber` en la subscription. Sin el segundo, el mensaje se reenvía al DLQ y además se sigue reintentando: un bucle.
10. **"No escuchó en `PORT`".** Tres causas: el proceso escucha en un puerto fijo, escucha en `127.0.0.1` en vez de `0.0.0.0`, o revienta antes de llegar a escuchar. Se distinguen leyendo los logs de la revisión: si hay stack trace, es la tercera.
11. **Firestore: emulador sí, servicio no.** Porque el emulador no exige índices compuestos y el servicio sí, para consultas que combinan igualdad con ordenamiento o dos rangos.
12. **`# forces replacement`.** Marca un atributo inmutable: cambiarlo obliga a destruir y recrear. Impone la regla de no aplicar nunca un plan con `must be replaced` sin haber leído qué recurso y qué atributo lo fuerzan.
13. **`gcloud` sí, Terraform no.** Terraform usa las ADC, no la credencial de la CLI. Se resuelve con `gcloud auth application-default login`, no con más roles.
14. **`RESOURCE_EXHAUSTED` frente a 429.** El primero es una cuota administrativa por proyecto y API, muchas veces ampliable; el segundo es un límite de tasa del servicio, cuya respuesta correcta es reintentar con backoff exponencial y jitter.
15. **Connectivity Test frente a `ping`.** Hace un análisis de configuración —simula el camino contra reglas y rutas reales y nombra la regla que dropea— en vez de enviar paquetes; por eso funciona con la VM apagada.
16. **VM sin IP externa que no alcanza las APIs.** Comprobar `privateIpGoogleAccess` en la subnet antes de pensar en Cloud NAT.

---

## A04 — Rutina de recurso: CLI, API y destrucción

1. **¿Por qué `--format=json` en el paso 2?** Porque la tabla por defecto muestra los campos que alguien eligió; el JSON muestra el objeto que devuelve la API, con los defaults que aplicó el servicio.
2. **Resource name completo.** `projects/<id>/topics/inv-events` frente al `inv-events` que acepta `gcloud` por comodidad. La API y muchos SDK exigen la forma larga.
3. **`1d` que se guarda como `86400s`.** Que la API normaliza los valores: desde el SDK el campo espera una duración, no la cadena que aceptó la CLI.
4. **Campo inmutable.** Desde `gcloud`, como la ausencia del flag o un error de argumento no reconocido; desde Terraform, como `# forces replacement` en el plan.
5. **Las dos provocaciones del paso 4.** Primero, si el borrado es **en cascada o deja hijos** —la respuesta cambia por servicio—; segundo, **borrar dos veces**, porque en el paso 6 hay que decidir qué hace el código cuando el recurso ya no está: un teardown que revienta porque algo ya estaba borrado no se vuelve a ejecutar.
6. **`update_mask`.** La lista de campos que el servicio debe tomar en cuenta al actualizar. En `gcloud` estaba escondida detrás de cada flag `--algo`, que la componía por ti.
7. **`list_*` y el iterador.** Devuelve un iterador paginado: las llamadas siguientes se disparan al recorrerlo, no al invocarlo.
8. **Las tres cosas de `--log-http`.** El endpoint y la versión de la API, el método HTTP y la ruta, y la forma del cuerpo; además, si la respuesta trae el recurso o una `Operation`.
9. **La precaución.** La salida incluye el header `Authorization` con tu token: hay que recortarlo antes de compartirla.
10. **La línea extra del SDK.** El `operation.result()` que espera a la operación de larga duración; sin ella el programa continúa creyendo que el recurso ya existe.
11. **Credenciales dentro de Cloud Run.** Del metadata server, que entrega tokens de la service account del servicio. Por eso no hace falta ninguna key descargada.
12. **Qué queda al terminar.** El script anotado, el fragmento de SDK, las dos listas de campos mutables e inmutables, y la sorpresa del paso 5 si la hubo.
