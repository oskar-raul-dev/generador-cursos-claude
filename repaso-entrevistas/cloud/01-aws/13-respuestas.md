# 13 — Respuestas

> **Objetivo:** ser el único lugar del curso donde vive una respuesta. Reúne,
> explicadas, las de las "Preguntas rápidas" de `01`–`09` y `11`–`12`, las de las `P#`
> de [`10`](10-preguntas-entrevista-y-mapa-mental.md) y las de la serie práctica
> `L00`–`L04` y `A01`–`A02`.
> **Cómo se usa:** contesta primero, comprueba después. Una respuesta leída antes de
> intentarla no se recuerda en una entrevista.
> **Regla de mantenimiento:** quien agregue, elimine o reordene una pregunta en
> cualquier documento actualiza este archivo en la misma edición.
> **Qué no está aquí:** los ejercicios de los labs y los apéndices. Esos se verifican con
> su `Objetivo:` y con la salida real del comando, no contra una respuesta escrita.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [01](#01--infraestructura-global-y-redes) · [02](#02--cómputo-contenedores-y-balanceo) · [03](#03--almacenamiento-y-bases-sql) · [04](#04--dynamodb-y-nosql) · [05](#05--seguridad-iam-kms-y-secretos) · [06](#06--route-53-dns-y-conectividad) · [07](#07--mensajería-eventos-e-integración) · [08](#08--observabilidad-auditoría-y-gobierno) · [09](#09--cloudformation-e-infrastructure-as-code) · [11](#11--resiliencia-y-well-architected) · [12](#12--orquestación-y-cicd) · [10](#10--preguntas-de-entrevista) · [L00](#l00--introducción-a-la-serie-práctica) · [L01](#l01--preparación-cli-identidad-y-blindaje-de-costos) · [L02](#l02--cloudformation-desde-la-cli) · [L03](#l03--backend-serverless-lambda-http-api-y-eventos) · [L04](#l04--observabilidad-y-destrucción-verificada) · [A01](#a01--aws-cli-de-supervivencia) · [A02](#a02--catálogo-de-costos-trampas-y-recursos-huérfanos)

Los escenarios de arquitectura de [`10`](10-preguntas-entrevista-y-mapa-mental.md#escenarios-de-arquitectura)
no están aquí porque ya traen su solución desarrollada en el propio documento: son
ejemplos resueltos, no autochequeo.

---

## 01 — Infraestructura global y redes

1. **¿VPC es regional o zonal?** Regional. Pertenece a una sola Region y puede abarcar varias AZ de esa Region.
2. **¿Subnet puede abarcar dos AZ?** No. Una subnet pertenece a una sola Availability Zone.
3. **¿Qué hace realmente pública a una subnet?** Que su route table tenga una ruta hacia un Internet Gateway (`0.0.0.0/0 → IGW`).
4. **¿Public subnet garantiza que una EC2 sea alcanzable desde Internet?** No. Además de la ruta a IGW, la instancia necesita IP pública/EIP, Security Group y NACL que permitan el tráfico, y un proceso escuchando en el puerto.
5. **¿SG tiene reglas DENY?** No. Un Security Group solo admite reglas ALLOW; todo lo no permitido queda denegado implícitamente.
6. **¿Por qué SG es stateful y NACL stateless?** Porque SG rastrea el estado de la conexión y permite automáticamente el tráfico de retorno de una conexión permitida; NACL evalúa cada paquete de forma independiente, por lo que hay que permitir explícitamente inbound y outbound.
7. **¿VPC Peering es transitivo?** No. Si B↔A y A↔C, eso no implica B↔C.
8. **¿Qué problema resuelve Transit Gateway?** Evita la complejidad de un mesh de peering al ofrecer un hub administrado (hub-and-spoke) para conectar muchas VPC y redes externas.
9. **¿Cuándo usarías VPC Endpoint en lugar de NAT?** Cuando necesitas acceso privado a un servicio AWS compatible (S3, DynamoDB, u otros vía PrivateLink) sin exponer tráfico a Internet ni depender de un NAT Gateway.
10. **¿Cómo depurarías una conexión EC2 → RDS que falla?** Siguiendo el orden mental de troubleshooting: DNS, IP, route table, gateway/peering/endpoint, NACL, Security Group, listener/puerto y, por último, si el proceso realmente escucha; apoyándote en VPC Flow Logs y Reachability Analyzer.

---

## 02 — Cómputo, contenedores y balanceo

1. **¿EC2 vs container?** EC2 virtualiza una máquina completa (VM); un container empaqueta y aísla procesos sobre un mismo host/kernel. Un container puede ejecutarse sobre una instancia EC2.
2. **¿AMI vs EBS?** AMI es la plantilla para lanzar instancias EC2 (SO, software, configuración); EBS es el volumen de block storage persistente que usa esa instancia.
3. **¿Scale up vs scale out?** Scale up (vertical) es usar una instancia más grande; scale out (horizontal) es agregar más instancias. En cloud suele preferirse scale out cuando el workload lo permite.
4. **¿ECR ejecuta containers?** No. ECR es solo el registry de imágenes; el runtime/orquestación lo hacen ECS, EKS u otro compute.
5. **¿Task Definition vs Task vs Service?** Task Definition es el blueprint declarativo; Task es una instancia en ejecución de esa definición; Service mantiene un desired count de tasks activo en el tiempo.
6. **¿Fargate reemplaza a ECS?** No. Fargate es compute administrado para ejecutar tasks; ECS sigue siendo el orquestador/control plane.
7. **¿ECS vs EKS?** ECS es el orquestador nativo de AWS; EKS es Kubernetes administrado. EKS se justifica cuando necesitas el ecosistema/API de Kubernetes, no solo porque sea popular.
8. **¿Cuándo usarías Lambda en vez de un servicio ECS permanente?** Para funciones event-driven, automatización o cargas que encajen con su modelo de ejecución por invocación; no para todo workload long-running.
9. **¿API Gateway vs ALB?** API Gateway ofrece gestión de APIs (routing, auth, throttling, stages); ALB hace balanceo Layer 7 hacia targets. Pueden coexistir.
10. **¿ALB vs NLB?** ALB opera en Layer 7 (HTTP/HTTPS, routing por path/host); NLB opera en Layer 4 (TCP/UDP/TLS, alto rendimiento y baja latencia).
11. **¿Qué ocurre cuando falla un health check del target?** El ALB deja de enviarle tráfico a ese target hasta que vuelva a reportarse healthy.
12. **¿Qué es un cold start y qué lo dispara?** Es la latencia extra de inicializar un nuevo execution environment de Lambda; ocurre en la primera invocación tras un deploy, un escalado a más concurrencia o inactividad prolongada.
13. **¿Provisioned Concurrency elimina el costo de Lambda en reposo?** No. Mantiene execution environments inicializados y los cobra estén o no en uso; elimina el cold start, no el costo en reposo.
14. **¿Qué resuelven las Layers y qué NO resuelven?** Resuelven reutilizar dependencias/librerías compartidas entre funciones sin duplicar el paquete; no resuelven el versionado ni la compatibilidad de esas dependencias, que sigue siendo responsabilidad del equipo.
15. **¿Empaquetar Lambda como container image la vuelve equivalente a ECS?** No. Sigue siendo el mismo modelo de ejecución event-driven de Lambda con sus mismos límites; el container es solo el formato de empaquetado.

---

## 03 — Almacenamiento y bases SQL

1. **¿S3 vs EBS vs EFS?** S3 es object storage vía API; EBS es block storage para una instancia; EFS es un filesystem compartido (NFS) entre múltiples instancias.
2. **¿Qué aporta S3 Versioning?** Conserva versiones anteriores de un objeto, permitiendo recuperar borrados accidentales o overwrites, a costo de almacenamiento adicional por versión.
3. **¿Lifecycle rule elimina inmediatamente todos los datos versionados?** No necesariamente; una lifecycle rule puede transicionar, archivar o expirar según reglas configuradas, incluyendo tratamiento distinto para versiones no actuales, no un borrado inmediato de todo.
4. **¿Qué administra RDS y qué sigue siendo responsabilidad del equipo?** RDS administra provisioning, infraestructura, backups automatizados, patching y failover en HA; el equipo sigue siendo responsable del diseño de índices, queries y modelo relacional.
5. **¿RDS PostgreSQL vs Aurora PostgreSQL?** RDS PostgreSQL es PostgreSQL administrado estándar; Aurora es un motor/arquitectura propia de AWS compatible con PostgreSQL, con almacenamiento y replicación distribuidos propios.
6. **¿Multi-AZ DB instance vs Multi-AZ DB cluster?** DB instance clásico tiene un writer y una standby no legible destinada a failover; DB cluster moderno tiene un writer, dos readers y tres AZ, con réplicas legibles.
7. **¿Multi-AZ vs read replica?** Multi-AZ resuelve failover/alta disponibilidad; read replica resuelve escalar lecturas. No son sustitutos entre sí.
8. **¿Una replica sustituye backup?** No. La replicación también propaga errores lógicos; backup y replicación resuelven problemas distintos.
9. **¿Qué problema resuelve RDS Proxy?** Administra un pool de conexiones entre la aplicación y la base de datos, útil para workloads con alta volatilidad de conexiones como Lambda.
10. **¿Cuándo introducirías cache?** Cuando necesitas reducir carga de lecturas repetidas sobre la base de datos o servir sesiones, aceptando a cambio los problemas de invalidación/expiración/consistencia que el cache introduce.
11. **¿Qué resuelve AWS Backup que los backups por servicio no resuelven?** Centraliza la política de backup (schedule, retención, copia cross-Region/cross-account) sobre múltiples servicios en un solo lugar auditable, en vez de que cada servicio tenga su propio mecanismo aislado.
12. **¿Qué es un backup vault?** El almacén administrado donde AWS Backup guarda los backups de un plan, con la opción de Vault Lock para retención inmutable.
13. **¿Por qué un backup sin restore probado no es una garantía?** Porque solo un restore real verifica que los datos guardados efectivamente se pueden recuperar; sin esa prueba, el backup es una promesa no verificada.

---

## 04 — DynamoDB y NoSQL

1. **¿Partition key vs sort key?** La partition key determina la distribución de los datos; la sort key ordena y agrupa items dentro del mismo valor de partition key en una primary key compuesta.
2. **¿Por qué diseñar desde access patterns?** Porque en DynamoDB las keys e índices determinan qué consultas serán eficientes; no hay joins ni consultas ad hoc equivalentes a SQL para rescatar un modelo genérico después.
3. **¿Query vs Scan?** Query accede de forma dirigida por partition key (y opcionalmente sort key); Scan recorre toda la tabla o índice.
4. **¿Por qué FilterExpression no arregla un Scan costoso?** Porque el filtro se aplica después de leer los datos que el Scan ya evaluó; sigues pagando/consumiendo la lectura completa antes de filtrar.
5. **¿GSI vs LSI?** GSI puede tener partition key y sort key distintas de la tabla base; LSI mantiene la misma partition key con una sort key alternativa.
6. **¿GSI soporta strongly consistent reads?** No. Las lecturas desde un GSI son siempre eventually consistent.
7. **¿On-demand vs provisioned?** On-demand ajusta capacidad automáticamente para tráfico impredecible; provisioned requiere definir capacidad de lectura/escritura (con auto scaling opcional) para tráfico predecible y control de costos.
8. **¿Qué es hot partition?** Concentración de tráfico sobre un mismo valor (o pocos valores) de partition key, generada por baja cardinalidad o mal diseño de la key.
9. **¿TTL borra exactamente al alcanzar el timestamp?** No. TTL marca el item como elegible para expirar; el borrado real ocurre de forma asíncrona, no exactamente al segundo.
10. **¿DynamoDB tiene transacciones?** Sí, soporta transacciones ACID sobre múltiples items mediante APIs transaccionales dedicadas.
11. **¿Qué resuelve Streams?** Captura una secuencia temporal de modificaciones de items para alimentar procesamiento event-driven, proyecciones, notificaciones o integración/CDC.
12. **¿Cuándo escogerías RDS en lugar de DynamoDB?** Cuando hay relaciones complejas, joins dinámicos, consultas ad hoc variadas o necesitas integridad relacional fuerte y natural.

---

## 05 — Seguridad: IAM, KMS y secretos

1. **¿IAM User vs Role?** User es una identidad de largo plazo con credenciales persistentes; Role es una identidad asumible con credenciales temporales emitidas por STS.
2. **¿Trust policy vs permission policy?** La trust policy define quién puede asumir el role; las permission policies definen qué puede hacer una vez asumido.
3. **¿Por qué preferir temporary credentials?** Porque reducen el riesgo frente a credenciales permanentes: tienen vida limitada y no quedan expuestas de forma indefinida si se filtran.
4. **¿Qué significa default deny?** Que, salvo un Allow explícito aplicable, toda acción está denegada por defecto.
5. **¿Qué ocurre con explicit deny?** Tiene prioridad sobre cualquier Allow: un explicit deny siempre gana en la evaluación de políticas.
6. **¿Identity-based vs resource-based policy?** Identity-based se adjunta a un user/group/role y dice qué puede hacer esa identidad; resource-based se adjunta al recurso y dice qué principals pueden operar sobre él.
7. **¿Qué es least privilege?** Otorgar solamente las acciones necesarias, sobre los recursos necesarios, bajo las condiciones necesarias — nunca `Action: "*", Resource: "*"`.
8. **¿IAM vs Security Group?** IAM autoriza llamadas a la API/recursos AWS; Security Group controla el tráfico de red hacia/desde un recurso. Se necesitan ambas capas.
9. **¿KMS key policy vs IAM policy?** La key policy de KMS es la base y determina cómo pueden participar las IAM policies y principals; no basta con configurar solo la IAM policy del lado de la identidad.
10. **¿Qué es envelope encryption?** Un patrón donde una KMS key protege (cifra) una data key, y esa data key es la que cifra los datos en volumen, en vez de mandar todos los datos directamente a KMS.
11. **¿Qué resuelve Secrets Manager que no resuelve un secreto escrito en el código?** Secrets Manager almacena y permite rotar secretos de forma administrada; hardcodear un secreto en código/imagen/repositorio es la mala práctica que ese servicio existe para evitar.
12. **¿SCP concede permisos?** No. Un SCP no otorga permisos por sí solo, solo establece el máximo conjunto de permisos posible (guardrail); la identidad todavía necesita un Allow aplicable dentro de la cuenta.
13. **¿Qué diferencia a un Cognito User Pool de un Identity Pool?** El User Pool autentica al usuario final y emite JWT; el Identity Pool convierte esa identidad en credenciales temporales de AWS (vía STS) para invocar servicios directamente.
14. **¿Un JWT authorizer de API Gateway reemplaza a IAM authorization (`AWS_IAM`)?** No. Son mecanismos distintos: el JWT authorizer valida tokens de usuarios finales; `AWS_IAM` autoriza llamadas firmadas con SigV4 de principals IAM, típico de comunicación servicio a servicio.
15. **¿Qué agrega OIDC sobre OAuth2?** Agrega una capa de identidad: el ID token (JWT que identifica al usuario), además del access token de OAuth2 que solo autoriza el acceso a recursos.
16. **¿Por qué usar múltiples cuentas AWS en vez de una sola?** Por blast radius (aislar incidentes), billing (separar costo por equipo/producto), compliance (aislar cargas reguladas) y autonomía operativa de los equipos.
17. **¿Control Tower reemplaza a Organizations?** No. Control Tower automatiza y acelera el establecimiento de una landing zone construida sobre Organizations; no sustituye la primitiva de administración multi-cuenta.

---

## 06 — Route 53, DNS y conectividad

1. **¿Public vs Private Hosted Zone?** Public responde DNS público de Internet; Private resuelve nombres solo dentro de las VPC asociadas.
2. **¿A vs AAAA?** A mapea un nombre a una dirección IPv4; AAAA lo mapea a una dirección IPv6.
3. **¿CNAME vs Alias?** CNAME es un registro DNS estándar que apunta a otro nombre; Alias es una extensión propia de Route 53 que puede apuntar a recursos AWS compatibles y sí puede usarse en el zone apex.
4. **¿Por qué Alias es útil en zone apex?** Porque un CNAME estándar no puede existir en el zone apex (`example.com`), y Alias sí lo permite para recursos AWS compatibles.
5. **¿Weighted garantiza exactamente 90/10 por requests?** No. Es una distribución relativa aproximada; el comportamiento observado se ve afectado por DNS y caching.
6. **¿Latency vs Geolocation?** Latency elige el endpoint con menor latencia estimada; Geolocation enruta según la ubicación geográfica del usuario, sin considerar latencia.
7. **¿Qué patrón implementa la routing policy Failover?** Active/passive: responde con el registro Primary mientras esté healthy, y conmuta a Secondary si falla el health check.
8. **¿Qué hace Evaluate Target Health?** Permite que un Alias use la salud del recurso AWS target directamente, evitando mantener un health check duplicado en ciertos casos.
9. **¿Route 53 reemplaza un ALB?** No. Route 53 resuelve DNS (decide a qué endpoint enviar); el ALB balancea solicitudes Layer 7 request-by-request hacia targets.
10. **¿CloudFront vs ALB?** CloudFront es CDN/edge cache que responde cerca del usuario; ALB hace balanceo Layer 7 hacia backends de origen.
11. **¿ACM vs KMS?** ACM administra certificados TLS; KMS administra claves y operaciones criptográficas de cifrado de datos/servicios.
12. **¿VPN vs Direct Connect?** VPN son túneles cifrados (IPsec) sobre Internet/red pública; Direct Connect es conectividad dedicada/privada, que no implica cifrado automático.
13. **¿Qué problema resuelve PrivateLink?** Permite consumir servicios de forma privada mediante interface endpoints, sin exponerlos públicamente ni depender de Internet.
14. **¿Route 53 replica tu DB multi-Region?** No. Route 53 solo resuelve DNS/routing/health checking; la replicación de datos multi-Region hay que diseñarla aparte.

---

## 07 — Mensajería, eventos e integración

1. **¿SQS vs SNS?** SQS es una queue durable para trabajo asíncrono (pull); SNS es pub/sub con fan-out (push) hacia múltiples subscribers.
2. **¿Por qué se combina un topic SNS con varias colas SQS?** Para fan-out durable: cada consumer recibe copia en su propia cola y procesa a su ritmo, sin que un consumer caído bloquee a los demás.
3. **¿Standard vs FIFO?** Standard prioriza throughput muy alto con entrega at-least-once y orden best-effort; FIFO garantiza orden estricto y deduplicación, orientado a exactly-once processing.
4. **¿Qué es visibility timeout?** La ventana durante la cual un mensaje recibido queda oculto a otros consumers mientras se procesa.
5. **¿Por qué un mensaje puede reprocesarse?** Porque si el procesamiento tarda más que el visibility timeout, o el consumer falla antes de confirmar (DeleteMessage), el mensaje vuelve a ser visible y otro consumer puede recibirlo.
6. **¿Qué hace una DLQ?** Recibe los mensajes que superan el número de intentos de procesamiento configurado, para investigación, alertas y reprocesamiento controlado.
7. **¿Qué significa idempotencia?** Que repetir la misma solicitud/mensaje no produce efectos adicionales incorrectos, aunque se reciba o procese más de una vez.
8. **¿EventBridge vs SNS?** SNS es pub/sub de topic con fan-out directo; EventBridge es un event bus con matching/routing por contenido y fuerte integración con eventos AWS/SaaS/custom.
9. **¿Qué es backpressure?** El efecto de que el productor genera trabajo más rápido de lo que el consumer puede procesar, generando backlog en la cola; se resuelve escalando consumers, limitando el producer o investigando downstream.
10. **¿Cómo escalarías workers según backlog?** Usando la profundidad/antigüedad de la cola (queue depth/age) como métrica de autoscaling, no solo CPU.
11. **¿Qué diferencia a Kinesis Data Streams de SQS?** Kinesis es un stream ordenado con retención donde varios consumers leen el mismo dato de forma independiente; SQS es una queue donde un mensaje se entrega a un consumer lógico y desaparece al confirmarse.
12. **¿Qué problema resuelve Firehose que Data Streams no resuelve directamente?** Entregar datos de streaming hacia destinos (S3, OpenSearch, Redshift, HTTP) con buffering/transformación administrados, sin operar consumers propios para esa carga.
13. **¿Por qué varios consumers pueden leer el mismo Kinesis stream sin "competir" por el mensaje?** Porque Kinesis retiene los registros durante una ventana configurable y cada consumer lleva su propio puntero de lectura, a diferencia de SQS, donde un mensaje se entrega y desaparece para los demás.

---

## 08 — Observabilidad, auditoría y gobierno

1. **¿CloudWatch vs CloudTrail?** CloudWatch responde cómo está funcionando el sistema (metrics/logs/alarms); CloudTrail responde quién hizo qué llamada/actividad en la cuenta.
2. **¿CloudTrail vs Config?** CloudTrail dice quién ejecutó un cambio y cuándo; Config dice cómo está/estuvo configurado un recurso y si cumple una regla.
3. **¿Qué es una metric dimension?** Un atributo que identifica variantes/recursos específicos de una métrica, por ejemplo a qué instancia o load balancer corresponde el valor.
4. **¿Qué estados puede tener una alarm?** OK, ALARM e INSUFFICIENT_DATA.
5. **¿Para qué sirve Logs Insights?** Para consultar interactivamente CloudWatch Logs: buscar excepciones, agrupar por endpoint, encontrar request IDs o calcular estadísticas durante un incident response.
6. **¿Flow Logs contienen payload HTTP?** No. Solo registran metadata del tráfico IP (origen/destino, puertos, protocolo, acción), no el contenido de la aplicación.
7. **¿Reachability Analyzer manda tráfico real?** No. Analiza estáticamente la configuración de red para determinar si existe un path y dónde se bloquearía, sin enviar paquetes reales.
8. **¿Qué métrica usarías para autoscaling de workers SQS?** La profundidad/antigüedad de la cola (backlog/age), correlacionada con el trabajo real pendiente, no solo CPU.
9. **¿Por qué tags son importantes?** Habilitan cost allocation, automatización, ownership, ABAC e inventario; funcionan mucho mejor con una convención organizacional consistente.
10. **¿Cómo investigarías quién abrió un SG al mundo?** Revisando CloudTrail para identificar quién ejecutó `AuthorizeSecurityGroupIngress`, y AWS Config para ver el historial de configuración y el estado de compliance del SG.
11. **¿Qué es un segment dentro de un trace de X-Ray?** El trabajo realizado por un servicio/componente específico dentro del recorrido completo (trace) de una request.
12. **¿Qué pasa con la visibilidad del trace si un servicio en el medio no reporta sus segments?** Se pierde visibilidad de esa porción del recorrido: el trace queda incompleto en ese tramo aunque el resto de los servicios sí reporten.
13. **¿Por qué un log por servicio no es lo mismo que un trace distribuido?** Porque los logs muestran eventos aislados por servicio; un trace correlaciona esos eventos a través de todos los servicios que participaron en la misma request, con la latencia de cada segmento.

---

## 09 — CloudFormation e Infrastructure as Code

1. **¿Template vs Stack?** El template es el documento que describe la infraestructura deseada; el stack es la instancia desplegada y administrada de ese template con sus parámetros/estado.
2. **¿Qué sección es obligatoria?** `Resources`.
3. **¿`Ref` vs `Fn::GetAtt`?** `Ref` devuelve el valor principal/ID del parameter o resource; `GetAtt` obtiene un atributo específico expuesto por el resource.
4. **¿Para qué sirve `Fn::Sub`?** Para interpolar strings, combinando texto fijo con referencias a parameters/pseudo parameters de forma legible.
5. **¿Parameter vs Mapping?** Parameter es una entrada que se provee en create/update; Mapping es una tabla de lookup estática consultada según un valor conocido, como la Region.
6. **¿Qué es una Condition?** Una expresión booleana que determina si un recurso (u otra parte del template) se crea/configura según el valor de parameters u otras condiciones.
7. **¿Qué es `AWS::NoValue`?** Un pseudo parameter útil junto con Conditions para omitir una propiedad de un recurso.
8. **¿Cuándo usar `DependsOn`?** Cuando necesitas expresar una dependencia explícita de ordering que no queda reflejada por una referencia (`Ref`/`GetAtt`) suficiente.
9. **¿`DeletionPolicy` vs `UpdateReplacePolicy`?** DeletionPolicy controla qué pasa con el recurso cuando se elimina del stack o se elimina el stack; UpdateReplacePolicy controla el destino del recurso físico antiguo cuando una actualización requiere reemplazo.
10. **¿Qué es replacement?** Que una actualización de propiedad obliga a crear un nuevo recurso físico y eliminar/reemplazar el anterior, con riesgo de downtime, cambio de identificador o pérdida de datos.
11. **¿Qué hace un Change Set?** Muestra una previsualización de los cambios que CloudFormation aplicaría antes de ejecutarlos, sin garantizar por sí solo que la ejecución tendrá éxito.
12. **¿Qué es drift?** La diferencia entre el estado real de un recurso y el estado esperado por el template, causada por cambios hechos fuera de CloudFormation.
13. **¿Qué revisarías si UPDATE_ROLLBACK ocurre?** Los Events del stack, para identificar el primer resource que falló y por qué.
14. **¿Nested Stack vs StackSet?** Nested Stack compone templates dentro de un mismo stack/cuenta/Region; StackSet despliega stacks coordinadamente en múltiples cuentas y/o Regions.
15. **¿Por qué IaC no garantiza seguridad por sí sola?** Porque una policy insegura (`Action: "*", Resource: "*"`) declarada en IaC sigue siendo insegura; IaC versiona y repite la infraestructura, no corrige por sí sola decisiones de diseño incorrectas.

---

## 11 — Resiliencia y Well-Architected

1. **¿Cuáles son los 6 pilares del Well-Architected Framework?** Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization y Sustainability.
2. **¿Por qué optimizar un pilar sin mirar los demás es una respuesta débil?** Porque los pilares compiten entre sí (trade-offs); ignorar eso produce diseños que solo se ven bien desde un ángulo, a costa de otro.
3. **¿Qué resuelve un timeout budget que un timeout aislado por servicio no resuelve?** Reparte el tiempo total tolerable de una request entre cada salto de la cadena de llamadas, evitando que cada servicio defina su timeout "a ojo" y que la suma supere lo tolerable para el cliente.
4. **¿Para qué sirve el jitter en un backoff exponencial?** Para desincronizar los reintentos entre clientes, evitando que todos reintenten al mismo tiempo y generen un nuevo pico sobre el servicio que se está recuperando.
5. **¿Qué estados tiene un circuit breaker?** CLOSED, OPEN y HALF-OPEN.
6. **¿Qué problema resuelve un bulkhead?** Aísla recursos (pools de conexión, threads, capacidad) entre distintas dependencias, para que la saturación de una no consuma toda la capacidad disponible del sistema.
7. **¿Qué mide RTO y qué mide RPO?** RTO mide cuánto tiempo puede estar el sistema caído; RPO mide cuántos datos puede permitirse perder, en tiempo.
8. **¿Cuál es la estrategia DR más barata y cuál la más cara?** Backup & Restore es la más barata; Multi-site Active/Active es la más cara.
9. **¿Qué diferencia a Pilot Light de Warm Standby?** Pilot Light solo mantiene los datos replicando en la region secundaria, sin cómputo activo; Warm Standby mantiene el sistema completo corriendo con capacidad reducida, con mejor RTO a mayor costo.
10. **¿Por qué Multi-site Active/Active tiene el RPO más bajo de las cuatro estrategias?** Porque ambas regiones sirven tráfico activo con datos sincronizados/replicados de forma continua, sin depender de un proceso de recuperación posterior a la falla.
11. **¿Cómo se relacionan la resiliencia de aplicación y la estrategia DR con el pilar Reliability?** Ambas son el detalle técnico de ese pilar: los patrones de resiliencia manejan fallas parciales en tiempo real, y la estrategia DR maneja la pérdida de una region completa; una respuesta de arquitectura bien calibrada nombra el pilar y después ambos niveles.

---

## 12 — Orquestación y CI/CD

1. **¿Qué señal indica que un Lambda necesita un orquestador en vez de más `try/catch`?** Múltiples `try/catch` anidados, lógica de reintento manual entre pasos, o un flujo que combina llamadas a distintos servicios con ramificación condicional compleja.
2. **¿Standard vs Express workflow en Step Functions?** Standard dura hasta un año con semántica exactly-once y auditoría detallada por ejecución; Express dura minutos con semántica at-least-once orientada a alto volumen.
3. **¿Qué hace un estado `Map` en una state machine?** Aplica el mismo procesamiento a cada elemento de una colección.
4. **¿Cuándo usarías Step Functions en vez de EventBridge?** Cuando conoces de antemano la secuencia de pasos y quieres orquestarla explícitamente, en vez de que varios consumidores desacoplados reaccionen a un evento sin conocer el flujo completo.
5. **¿Por qué IaC no es lo mismo que CI/CD?** IaC describe qué infraestructura debería existir; CI/CD decide cuándo y cómo se aplica ese cambio de forma segura y repetible.
6. **¿Qué produce CodeBuild y qué NO hace?** Produce artefactos de build/test según `buildspec.yml`; no administra por sí solo el despliegue, solo entrega el artefacto a la siguiente etapa.
7. **¿Blue/Green vs Canary?** Blue/Green despliega el entorno nuevo en paralelo y corta el tráfico de una vez cuando está validado; Canary desplaza el tráfico gradualmente monitoreando señales antes de completar.
8. **¿Por qué in-place tiene rollback más lento?** Porque actualiza directamente las instancias/tasks existentes, sin un entorno paralelo al que volver de inmediato.
9. **¿Es CodePipeline la única opción válida de CI/CD en un shop AWS?** No. Muchos equipos usan GitHub Actions, GitLab CI o Jenkins junto con, o en vez de, las herramientas nativas de AWS.
10. **¿Qué aprobaciones tendría un pipeline entre non-prod y prod?** Normalmente automática en non-prod, y manual (con revisión de Change Set/plan) antes de aplicar en prod.

---

## 10 — Preguntas de entrevista

### Parte I — Networking

- **P1. ¿Region vs AZ?** Region es un área geográfica; una Region contiene múltiples AZ aisladas.
- **P2. ¿VPC es zonal?** No. VPC es regional; las subnets son zonales.
- **P3. ¿Qué hace pública a una subnet?** Que su route table tenga una ruta hacia un Internet Gateway. Para que una EC2 IPv4 sea accesible también necesita public IP/EIP y controles de seguridad compatibles.
- **P4. ¿Security Group vs NACL?** SG actúa a nivel de recurso/ENI, es stateful y solo permite Allow; NACL actúa a nivel de subnet, es stateless y admite Allow y Deny con reglas ordenadas.
- **P5. ¿NAT permite Internet → EC2 privada?** No como conexión iniciada directamente. Se usa principalmente para conexiones salientes iniciadas por workloads privados.
- **P6. ¿VPC Peering es transitivo?** No.
- **P7. ¿Cuándo Transit Gateway?** Cuando necesitas hub-and-spoke para muchas VPC/redes y un mesh de peering sería demasiado complejo.
- **P8. ¿Por qué VPC Endpoint?** Para acceder privadamente a servicios/recursos sin necesitar exposición pública o egress por NAT/Internet en muchos escenarios.

### Parte II — Compute/containers

- **P9. ¿EC2 vs Docker?** EC2 virtualiza compute/VM; Docker empaqueta y aísla procesos en containers. Docker puede correr sobre EC2.
- **P10. ¿ECS vs Fargate?** ECS orquesta; Fargate proporciona compute administrado para las tasks/pods compatibles.
- **P11. ¿ECS vs EKS?** ECS es orquestador AWS-native; EKS es Kubernetes administrado.
- **P12. ¿ALB vs NLB?** ALB es Layer 7, HTTP/HTTPS, con routing por host/path; NLB es Layer 4, TCP/UDP/TLS.
- **P13. ¿Task vs Service?** Task es la ejecución de una task definition; Service mantiene el desired count de tasks y su lifecycle continuo.
- **P14. ¿API Gateway vs ALB?** API Gateway ofrece gestión de API e integraciones específicas; ALB hace balanceo Layer 7 hacia targets. Pueden coexistir.
- **P15. ¿Cómo modernizar monolito Spring Boot en EC2?** Containerizar, publicar en ECR, desplegar en ECS/Fargate detrás de un ALB, distribuido en Multi-AZ, con RDS/Aurora, IAM roles, CloudWatch y autoscaling. No responder automáticamente "Kubernetes" sin justificar por qué se necesita ese ecosistema.

### Parte III — Storage/database

- **P16. ¿S3 vs EBS vs EFS?** S3 es object storage; EBS es block storage; EFS es filesystem compartido.
- **P17. ¿Multi-AZ vs read replica?** Multi-AZ resuelve HA/failover; read replica resuelve read scaling. Matiz: los Multi-AZ DB cluster modernos incluyen readers, mientras que el Multi-AZ DB instance clásico usa una standby no legible para tráfico normal.
- **P18. ¿Aurora vs RDS PostgreSQL?** Aurora es un motor/arquitectura de AWS compatible con PostgreSQL; RDS PostgreSQL es PostgreSQL administrado bajo RDS.
- **P19. ¿Replica = backup?** No. Replicación y backup resuelven problemas diferentes.

### Parte IV — DynamoDB

- **P20. ¿Partition key vs sort key?** La partition key determina agrupación/distribución primaria; la sort key ordena/identifica items dentro del mismo valor de partition key en una primary key compuesta.
- **P21. ¿Query vs Scan?** Query usa key conditions; Scan recorre tabla/índice. Un Scan frecuente puede ser costoso y síntoma de un access pattern no modelado.
- **P22. ¿GSI vs LSI?** GSI admite partition key alternativa (y sort key opcional); LSI mantiene la misma partition key con una sort key alternativa.
- **P23. ¿GSI tiene strongly consistent reads?** No. Las lecturas de GSI son eventually consistent.
- **P24. ¿DynamoDB tiene transacciones?** Sí, APIs transaccionales ACID sobre múltiples items.
- **P25. ¿TTL borra exactamente al segundo?** No. La expiración marca elegibilidad, y el borrado ocurre de forma asíncrona.
- **P26. ¿Por qué access patterns primero?** Porque las keys e índices determinan qué consultas serán eficientes; no hay joins ni ad-hoc querying equivalente a SQL para rescatar un modelo genérico después.

### Parte V — Messaging

- **P27. ¿SQS vs SNS?** SQS es una queue durable orientada a backlog de trabajo; SNS es un topic pub/sub con fan-out.
- **P28. ¿Por qué SNS + múltiples SQS?** Cada consumer recibe copia del mensaje en su propia cola y procesa a su propio ritmo, sin bloquear a los demás.
- **P29. ¿Por qué consumer idempotente?** Porque retries/at-least-once pueden producir entregas repetidas o efectos parciales.
- **P30. ¿Qué es visibility timeout?** La ventana durante la cual un mensaje recibido queda invisible a otros consumers mientras se procesa.
- **P31. ¿Qué es una DLQ?** El destino de los mensajes que superan el número de intentos configurado; sirve para investigación y recuperación controlada.
- **P32. ¿EventBridge vs SNS?** SNS es topic/fan-out; EventBridge es un event bus con routing basado en contenido y múltiples fuentes/targets.

### Parte VI — Security

- **P33. ¿IAM User vs Role?** User es una identidad long-lived; Role es una identidad asumible con credenciales temporales.
- **P34. ¿Trust policy vs permission policy de un Role?** Trust policy define quién puede asumirlo; las permission policies definen qué puede hacer una vez asumido.
- **P35. ¿Cuál es la regla de policy evaluation?** Default deny; un explicit allow permite si nada superior lo bloquea; un explicit deny siempre gana. La evaluación completa puede incluir múltiples tipos de policy/guardrails.
- **P36. ¿IAM Role o access key en Docker image?** IAM Role. Nunca hardcodear claves en la imagen/repositorio.
- **P37. ¿KMS vs Secrets Manager?** KMS administra claves/operaciones criptográficas; Secrets Manager almacena y administra secretos, normalmente cifrados con KMS por debajo.
- **P38. ¿IAM vs Security Group?** IAM controla la autorización de API/recursos; SG controla el tráfico de red.

### Parte VII — Route 53

- **P39. ¿CNAME vs Alias?** Alias es una extensión de Route 53 que integra recursos AWS compatibles y puede usarse en zone apex; CNAME es un estándar DNS que no puede estar en zone apex.
- **P40. ¿Weighted vs Latency?** Weighted divide respuestas por pesos relativos; Latency elige el endpoint con menor latencia estimada.
- **P41. ¿Qué patrón implementa Failover?** Active/passive, basado en el estado de salud del registro Primary.
- **P42. ¿Route 53 vs ALB?** Route 53 resuelve DNS y decide el endpoint; ALB balancea solicitudes L7 hacia targets.

### Parte VIII — Edge/TLS

- **P43. ¿CloudFront vs Route 53 vs ALB?** Route 53 resuelve DNS; CloudFront cachea/distribuye en el edge; ALB balancea tráfico L7 hacia backends.
- **P44. ¿ACM vs KMS?** ACM administra certificados TLS; KMS administra claves y operaciones criptográficas para cifrado de datos/servicios.

### Parte IX — Observability

- **P45. ¿CloudWatch vs CloudTrail?** CloudWatch cubre performance/metrics/logs/alarms; CloudTrail cubre auditoría de actividad de API/cuenta.
- **P46. ¿CloudTrail vs Config?** CloudTrail dice quién hizo el cambio; Config dice cuál fue/es la configuración y su compliance.
- **P47. ¿Flow Logs vs Reachability Analyzer?** Flow Logs observa metadata de tráfico real; Reachability Analyzer analiza estáticamente configuración/path, sin tráfico real.

### Parte X — CloudFormation

- **P48. ¿Template vs Stack?** Template es la definición IaC; Stack es la instancia desplegada y gestionada.
- **P49. ¿Cuál es la sección obligatoria de un template?** `Resources`.
- **P50. ¿Ref vs GetAtt?** Ref obtiene el valor principal/ID de un parameter/resource; GetAtt obtiene un atributo específico del resource.
- **P51. ¿Qué es un Change Set?** Una previsualización de los cambios que CloudFormation pretende aplicar antes de ejecutarlos.
- **P52. ¿Qué es drift?** La diferencia entre la configuración real y la esperada por CloudFormation, debido a cambios hechos fuera del stack management.
- **P53. ¿Por qué replacement importa?** Porque una actualización puede requerir crear un nuevo recurso y eliminar/reemplazar el anterior, generando downtime, cambio de endpoint o riesgo de pérdida de datos según el recurso/policies.

### Parte XI — Resiliencia, Well-Architected y orquestación

- **P54. ¿Cuáles son los 6 pilares del Well-Architected Framework?** Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability.
- **P55. ¿RTO vs RPO?** RTO mide cuánto tiempo puede estar el sistema caído; RPO mide cuántos datos puede permitirse perder, en tiempo.
- **P56. ¿Pilot Light vs Warm Standby?** Pilot Light mantiene solo los datos replicando en la region secundaria, sin cómputo activo; Warm Standby mantiene el sistema completo corriendo con capacidad reducida. Warm Standby tiene mejor RTO, a mayor costo.
- **P57. ¿Qué resuelve un circuit breaker?** Evita seguir llamando a un servicio que falla de forma sostenida: protege al llamador de bloquearse esperando timeouts, y protege al servicio caído de recibir más tráfico mientras se recupera.
- **P58. ¿Cómo evitas un Lambda gigante con lógica de orquestación adentro?** Step Functions: cada Lambda hace una sola cosa y la state machine coordina el orden, los reintentos y el manejo de errores entre pasos.
- **P59. ¿Cognito User Pool vs Identity Pool?** User Pool autentica al usuario final y emite JWT; Identity Pool convierte esa identidad en credenciales temporales de AWS (STS) para llamar servicios directamente.
- **P60. ¿Kinesis vs SQS?** Kinesis es un stream ordenado con retención, donde varios consumers leen el mismo dato de forma independiente; SQS es una queue donde un mensaje se entrega a un consumer lógico y desaparece al confirmarse.

---

# Serie práctica: labs y apéndices

Respuestas al encuadre [`L00`](l00-idea-lab-practico.md), a los labs
[`L01`](l01-preparacion-cli-y-blindaje-de-costos.md),
[`L02`](l02-cloudformation-desde-la-cli.md),
[`L03`](l03-backend-serverless-lambda-api-y-eventos.md) y
[`L04`](l04-observabilidad-y-destruccion-verificada.md), y a los apéndices
[`A01`](a01-cli-de-supervivencia.md) y
[`A02`](a02-costos-trampas-y-recursos-huerfanos.md). Misma regla que el resto del solucionario: la pregunta vive
en su documento, la respuesta vive aquí.

## L00 — Introducción a la serie práctica

1. **¿Qué condición tiene que cumplir un tema para entrar al laboratorio de pago?** Al menos una de cuatro: que lo haga cumplir AWS y nadie más (IAM, routing de VPC), que el fallo real difiera del emulado (`ROLLBACK_COMPLETE`, `DELETE_FAILED`, throttling), que solo se conozca pagando (Cost Explorer, budgets) o que sea la costura entre tu código y AWS (execution role, resource-based policy).
2. **¿Por qué el curso practica Kubernetes en local y no en EKS?** Porque de los ocho aprendizajes que se esperan de "un microservicio en EKS", cinco se obtienen gratis con `kind` en cuarenta segundos por iteración. Solo tres son específicos de AWS, y caben en un drill dirigido de una sesión.
3. **¿Cuánto cuesta un cluster de EKS completamente vacío y por qué?** $0.10/hora de control plane, facturado por existir aunque no haya un solo pod desplegado. Es el único servicio del temario que cobra por existencia y el recurso huérfano más caro de una cuenta de práctica.
4. **De los ocho aprendizajes que se esperan de "un microservicio en EKS", ¿cuáles son realmente específicos de AWS?** Tres: IRSA/Pod Identity, el AWS Load Balancer Controller y el agotamiento de IPs del VPC CNI. Los otros cinco —ciclo de vida de contenedores, Deployments/Services/Ingress, rolling updates, ConfigMaps y Secrets, HPA— son Kubernetes puro.
5. **¿Qué pregunta decide si un servicio dudoso merece un lab de nube, un drill o un contenedor local?** "¿Qué me enseña este servicio que no me enseñe el mismo software corriendo en un contenedor en mi máquina?". Si la respuesta cabe en dos conceptos, es un drill; si es "nada", es un contenedor local; si es "el modelo entero", es un lab de nube.
6. **¿Por qué el laboratorio evita el NAT Gateway en lugar de enseñarlo?** Porque cuesta $0.045/h más $0.045 por GB procesado y es completamente evitable: el lab no mete las Lambdas en la VPC, y para hablar con S3 o DynamoDB desde dentro de una VPC existen los Gateway endpoints, que no tienen cargo.
7. **¿De dónde sale el gasto real de una cuenta de práctica, si no es del lab?** De tres sitios: log groups sin retención (nacen con retención indefinida), recursos huérfanos de sesiones anteriores que sobrevivieron a un `delete-stack`, y drills opcionales que quedaron encendidos.
8. **¿Qué le falta a DynamoDB Local respecto de DynamoDB real, y por qué importa?** La fidelidad de la API es alta, pero no reproduce throttling ni el comportamiento de particiones reales. Importa porque las hot partitions y los `ProvisionedThroughputExceededException` son justamente lo que se pregunta en entrevista.
9. **¿Por qué el lab usa DynamoDB Streams en vez de Kinesis para la proyección?** Porque el Stream de una tabla que ya existe no añade cargo por hora, mientras que un stream de Kinesis on-demand cobra del orden de $0.04/h por existir, y la semántica de log ordenado con múltiples lectores se aprende igual de bien con Redpanda en local.
10. **¿Qué estado deja `L02` y qué asume `L03` sobre él?** `L02` deja el stack `inv-lab-data` con la tabla `inv-lab-events`, un bucket y un parámetro SSM, todo sin cargo. `L03` asume que esa tabla y ese parámetro existen y construye el backend encima.
11. **¿Por qué el teardown de un drill de EKS se escribe antes que el despliegue?** Porque un cluster arrastra nodegroups, security groups creados por el controller, ENIs, un ALB y volúmenes EBS de los PVC, y varios de ellos no se borran al borrar el cluster. Escribir el teardown después es descubrir los residuos en la factura.
12. **¿Qué cambió en el free tier de AWS en julio de 2025 y cómo afecta a un tutorial de 2023?** Desde el 15 de julio de 2025 una cuenta nueva ya no recibe doce meses de recursos gratis, sino créditos ($100, ampliables a $200) y un plan Free que se cierra a los seis meses. Un tutorial de 2023 que dice "levanta una `t2.micro`, es gratis" te genera un cargo real.

## L01 — Preparación: CLI, identidad y blindaje de costos

1. **¿Qué permisos requiere `sts get-caller-identity`?** Ninguno. Si falla, el problema es de credenciales, de sesión expirada o de red, nunca de IAM.
2. **¿Cuál es el orden de precedencia con que la CLI resuelve credenciales?** Parámetros de línea de comandos, variables de entorno, archivos `~/.aws/credentials` y `~/.aws/config`, credenciales de contenedor y, por último, credenciales de instancia.
3. **¿Por qué un tag recién creado no aparece de inmediato como dimensión en Cost Explorer?** Porque el tag existe en el recurso, pero la clave debe activarse aparte como cost allocation tag en facturación, y la activación tarda hasta 24 horas en propagarse.
4. **¿La activación de un cost allocation tag es retroactiva?** No. Solo etiqueta el costo generado a partir del momento de la activación.
5. **¿Un AWS Budget puede detener el gasto automáticamente?** Por sí solo no: notifica. Detener requiere una budget action, o un tema SNS con una Lambda que aplique la contención.
6. **¿Qué diferencia hay entre una notificación de budget `ACTUAL` y una `FORECASTED`?** `ACTUAL` se dispara sobre gasto ya incurrido; `FORECASTED` sobre la proyección del periodo, y por eso avisa antes.
7. **¿Cuánto retraso tienen los datos de Cost Explorer y qué implica para verificar un teardown?** Aproximadamente 24 horas. Implica que la certeza inmediata viene de enumerar recursos, y la confirmación económica se hace a las 48 horas.
8. **¿Por qué conviene fijar explícitamente la región en la shell del lab?** Porque un recurso creado por error en otra región no aparece en los listados de la región configurada, y porque varios servicios globales tienen su plano de control en `us-east-1`.
9. **¿Qué tipo de credencial entrega IAM Identity Center y por qué se prefiere a las access keys?** Credenciales temporales obtenidas por STS, que caducan solas; evita access keys de larga duración guardadas en texto plano.
10. **¿Por qué el rastreo por tags no basta por sí solo para garantizar que no quedaron recursos vivos?** Porque no todos los tipos de recurso soportan tags, la API de tagging es regional, y hay recursos creados por servicios de AWS (como los log groups de Lambda) que nacen sin tag.

## L02 — CloudFormation desde la CLI

1. **¿Qué hace `aws cloudformation deploy` que no hacen `create-stack` ni `update-stack`?** Crea un change set, lo ejecuta y espera; es idempotente, así que sirve tanto para crear como para actualizar sin que tengas que saber si el stack ya existe.
2. **¿Qué valida realmente `validate-template` y qué no valida?** Solo la sintaxis del documento y la forma de las funciones intrínsecas. No valida nombres de propiedades, tipos de recurso, límites de servicio ni permisos.
3. **¿Qué significa `Replacement: True` en un change set?** Que CloudFormation creará un recurso nuevo y eliminará el actual. En recursos con estado equivale a pérdida de datos.
4. **¿Un change set garantiza que la actualización va a tener éxito?** No. Describe la intención; los fallos de permisos, límites o estado del recurso aparecen al ejecutar.
5. **¿Qué operaciones admite un stack en `ROLLBACK_COMPLETE`?** Solo `delete-stack`. Es un estado terminal de una creación fallida y no se puede actualizar.
6. **¿Para qué sirve `--disable-rollback` al crear un stack?** Para conservar los recursos que sí se crearon y poder inspeccionar la causa del fallo; el stack queda en `CREATE_FAILED`, desde donde se puede reintentar.
7. **¿Cuál es el `DeletionPolicy` por defecto y en qué tipo de recurso cambia?** `Delete` para la mayoría de recursos, y `Snapshot` para `AWS::RDS::DBCluster` y para `AWS::RDS::DBInstance` sin `DBClusterIdentifier`.
8. **¿Por qué falla el borrado de un stack que contiene un bucket S3 con objetos?** Porque CloudFormation no vacía buckets; la API de S3 rechaza borrar un bucket no vacío y el stack queda en `DELETE_FAILED`.
9. **¿Qué riesgo introduce `--retain-resources`?** Deja el recurso vivo y fuera del control de CloudFormation: se convierte en un huérfano que seguirá facturando y que ningún `delete-stack` posterior encontrará.
10. **¿Por qué `Export`/`Fn::ImportValue` es mala idea entre stacks de distinto ciclo de vida?** Porque mientras exista una importación, el stack exportador no puede borrarse ni modificar ese valor. SSM Parameter Store desacopla sin ese bloqueo.
11. **¿La detección de drift es continua? ¿Corrige lo que encuentra?** No y no. Es una operación bajo demanda, no cubre todos los tipos de recurso y solo informa; corregir es volver a desplegar el template.
12. **¿Qué hace `AWS::NoValue` y para qué se combina con `Fn::If`?** Elimina por completo la propiedad del recurso cuando la condición no se cumple, permitiendo un único template válido en varios modos.

## L03 — Backend serverless: Lambda, HTTP API y eventos

1. **¿Qué diferencia hay entre una fuente de eventos push y una pull para Lambda?** En push el servicio invoca la función y necesita una resource-based policy; en pull Lambda hace polling con su propio execution role y no hay resource policy.
2. **¿Qué documento autoriza que API Gateway invoque tu función?** Un `AWS::Lambda::Permission`, es decir la resource-based policy de la función, no el execution role.
3. **¿Qué rol usa Lambda para leer un DynamoDB Stream?** Su execution role, que debe incluir los permisos de lectura del stream (`GetRecords`, `GetShardIterator`, `DescribeStream`, `ListStreams`).
4. **¿Qué pasa con un lote de SQS o de Streams si un solo registro falla y no usas `ReportBatchItemFailures`?** Se reintenta el lote completo, incluidos los registros ya procesados; sin idempotencia, eso duplica efectos.
5. **¿Cuál es la relación recomendada entre el visibility timeout de una cola y el timeout de la función?** El visibility timeout debe ser al menos seis veces el timeout de la función; si es menor, el mensaje reaparece mientras aún se procesa.
6. **¿Qué hace `BisectBatchOnFunctionError`?** Ante un error, divide el lote en dos y reintenta cada mitad, para aislar el registro problemático en vez de descartar o reprocesar todo.
7. **¿Cómo se implementa idempotencia en una escritura a DynamoDB sin tabla auxiliar?** Con una escritura condicional (`ConditionExpression: attribute_not_exists(...)`) sobre una clave derivada del identificador de idempotencia; el segundo intento falla de forma controlada.
8. **¿Qué diferencia hay entre reserved concurrency y provisioned concurrency, y cuál cobra por hora?** Reserved aparta y limita concurrencia sin cargo adicional; provisioned mantiene entornos inicializados para eliminar el cold start y sí cobra por hora aunque no haya tráfico.
9. **¿Cómo detienes las invocaciones de una función sin borrarla?** Fijando su reserved concurrency en 0.
10. **¿Por qué el log group de una Lambda sobrevive al borrado del stack?** Porque lo crea CloudWatch al primer log, no CloudFormation; no forma parte del stack salvo que lo declares explícitamente.
11. **¿Cuándo hace falta poner una Lambda dentro de una VPC y qué costo introduce?** Solo cuando debe alcanzar recursos privados de esa VPC. Introduce ENIs, y salida a Internet requiere NAT Gateway o Interface endpoints, ambos con cargo por hora.
12. **¿Qué cambia en el objeto `event` entre payload format 1.0 y 2.0 de API Gateway?** En 2.0 desaparecen `httpMethod` y `path` y aparecen `routeKey` y `rawPath`, además de cambios en headers y en el formato de respuesta simplificado.
13. **¿Qué relación hay entre la memoria asignada a una Lambda y su CPU?** La CPU asignada es proporcional a la memoria configurada: subir memoria sube CPU, y a veces reduce el costo total porque la función termina antes.
14. **¿Qué diferencia hay entre la trust policy y la permissions policy de un rol IAM?** La trust policy define quién puede asumir el rol; la permissions policy define qué puede hacer quien lo asumió.

## L04 — Observabilidad y destrucción verificada

1. **¿Qué le pasa a un log group sin `RetentionInDays` y por qué importa económicamente?** Conserva los logs indefinidamente y factura por GB almacenado todos los meses; es un cargo pequeño, permanente e invisible.
2. **¿Qué ventaja tiene EMF frente a `PutMetricData` dentro de una Lambda?** EMF es una línea de log: no añade una llamada de red sincrónica dentro de la función, no puede fallar por red y no requiere permisos de CloudWatch adicionales.
3. **¿Qué campo del log `REPORT` mide el cold start?** `@initDuration`, que solo aparece en invocaciones que inicializaron un entorno nuevo.
4. **¿Por qué una alarma sobre una cola sin tráfico se queda en `INSUFFICIENT_DATA`?** Porque sin métricas publicadas la alarma no puede evaluarse; se corrige con `--treat-missing-data notBreaching` (o el valor que corresponda al caso).
5. **¿Qué responde CloudTrail que el log de la aplicación no responde?** Quién hizo la llamada, con qué identidad, desde dónde y con qué parámetros; el log de la aplicación solo dice que falló.
6. **¿Qué retraso típico tiene CloudTrail y qué herramienta usarías para depurar en caliente?** Hasta unos 15 minutos para eventos de gestión; para depurar en caliente sirve el IAM Policy Simulator, que evalúa sin ejecutar.
7. **¿Por qué la API de Resource Groups Tagging no basta para verificar un teardown?** Porque es regional y solo cubre recursos etiquetables y soportados; los recursos creados por servicios de AWS o sin tag no aparecen.
8. **Nombra cuatro recursos que sobreviven a un `delete-stack` exitoso.** Log groups creados por Lambda, snapshots de RDS por `DeletionPolicy: Snapshot`, imágenes en ECR, y cualquier recurso abandonado con `--retain-resources`. También volúmenes EBS y Elastic IP si se retuvo la instancia.
9. **¿Por qué hay que barrer varias regiones y no solo la del lab?** Porque un recurso creado por error en otra región no aparece en los listados de la región del lab y sigue facturando en silencio.
10. **¿Cuánto tarda Cost Explorer en reflejar el gasto y qué implica para el orden de verificación?** Aproximadamente 24 horas, así que primero se enumera (mismo día) y después se confirma económicamente (48 horas).
11. **¿Qué hace `aws cloudformation wait stack-delete-complete` y por qué conviene encadenarlo?** Bloquea hasta que el borrado termina y devuelve un código de salida distinto de cero si expira o falla, lo que permite encadenar con `&&` y `||` en un script de teardown.
12. **¿Cuál es la red de seguridad si el barrido se te olvida por completo?** El budget de gasto cero creado en `L01`, que avisa por correo ante cualquier cargo.

## A01 — AWS CLI de supervivencia

1. **¿Qué muestra `aws configure list` que no muestra `aws sts get-caller-identity`?** El valor efectivo de cada ajuste y su origen (variable de entorno, archivo de configuración, rol de instancia), que es lo que revela por qué estás usando otra identidad.
2. **¿Qué gana en la precedencia: una variable de entorno o el perfil de `~/.aws/config`?** La variable de entorno, salvo que se pase `--profile` explícitamente en la línea de comandos.
3. **¿Cuál es la diferencia funcional y económica entre `--query` y `--filters`?** `--filters` lo aplica el servicio y reduce lo transferido y la paginación; `--query` lo aplica la CLI localmente tras recibir toda la respuesta, así que no reduce llamadas ni riesgo de throttling.
4. **¿Por qué `[?Enabled=='true']` puede no devolver nada sobre un campo booleano?** Porque las comillas simples denotan un string y el campo es booleano; el literal correcto es `` `true` `` entre comillas invertidas.
5. **¿Qué hace `--page-size` que no hace `--max-items`?** `--page-size` cambia el tamaño de cada llamada a la API; `--max-items` solo limita cuántos elementos devuelve la CLI en total.
6. **¿Qué código de salida devuelve un waiter que expira y qué significa realmente?** Distinto de cero, pero eso significa que se agotaron los reintentos del waiter, no necesariamente que la operación haya fallado.
7. **¿Qué mensaje devuelve un `--dry-run` exitoso y por qué no es un error?** El error `DryRunOperation` con el texto "Request would have succeeded": indica que tienes permisos y los parámetros son válidos.
8. **¿Para qué sirve `--generate-cli-skeleton`?** Para generar la estructura JSON de una llamada compleja, editarla en un archivo y enviarla con `--cli-input-json`, evitando el escapado de comillas en la shell.
9. **¿Qué error produce olvidar `--cli-binary-format raw-in-base64-out` en `lambda invoke`?** La CLI v2 interpreta el payload como base64 y devuelve un error de codificación inválida.
10. **¿Qué aporta `AWS_RETRY_MODE=adaptive` frente a `standard`?** Añade limitación del lado del cliente ante respuestas de throttling, además de los reintentos con backoff del modo `standard`.

## A02 — Catálogo de costos, trampas y recursos huérfanos

1. **¿Cuáles son las cuatro categorías de cobro y cuál sobrevive al apagado?** Por hora encendida, por uso real, por almacenamiento y por transferencia. El almacenamiento sobrevive al apagado.
2. **¿Por qué apagar una instancia EC2 no detiene todo su costo?** Porque los volúmenes EBS asociados, los snapshots y cualquier Elastic IP siguen facturando aunque la instancia esté detenida.
3. **¿Cuál es el `DeletionPolicy` por defecto y en qué recursos cambia?** `Delete` en general; `Snapshot` en `AWS::RDS::DBCluster` y en `AWS::RDS::DBInstance` sin `DBClusterIdentifier`.
4. **¿Por qué un log group de Lambda sobrevive al borrado del stack?** Porque lo crea CloudWatch, no el stack, y nace con retención indefinida.
5. **¿Qué diferencia de costo hay entre un Gateway endpoint y un Interface endpoint?** Los Gateway endpoints (S3 y DynamoDB) no tienen cargo; los Interface endpoints cobran por hora y por AZ, además del tráfico procesado.
6. **¿Cuánto cuesta una dirección IPv4 pública y desde cuándo se cobra siempre?** Unos $0.005 por hora y dirección, cobrada desde 2024 esté asociada o no.
7. **¿Por qué un stream de Kinesis on-demand puede salir más caro que uno provisionado en un lab?** Porque cobra un cargo fijo por stream y hora ($0.04) frente a $0.015 por shard-hora en provisionado; con tráfico casi nulo, el fijo domina.
8. **¿Qué son los multipart uploads incompletos y por qué no aparecen en un listado normal?** Partes de subidas nunca finalizadas que ocupan almacenamiento y facturan, pero no aparecen en un listado normal de objetos; se eliminan con una regla de ciclo de vida.
9. **¿Por qué se prefiere SSM Parameter Store a Secrets Manager en una cuenta de práctica?** Porque los parámetros estándar no tienen cargo y Secrets Manager cobra por secreto y mes, además de por llamadas a la API.
10. **¿Qué dimensión de Cost Explorer responde "qué línea exacta me está cobrando"?** `USAGE_TYPE`, que distingue por ejemplo horas de NAT Gateway de bytes procesados por el NAT Gateway.
11. **¿Qué pasos sigues para localizar un cargo inesperado?** Agrupar por `SERVICE`, después por `USAGE_TYPE`, después por `REGION`, barrer esa región y ese servicio, borrar el recurso y confirmar a las 48 horas.
12. **¿Cuál es el elemento serverless que, pese a serlo, cobra por hora?** La provisioned concurrency de Lambda.
