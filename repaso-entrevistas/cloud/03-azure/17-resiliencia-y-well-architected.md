# 17 — Resiliencia y Azure Well-Architected Framework

> **Objetivo:** razonar sobre disponibilidad y recuperación como lo hace un arquitecto: separar alta
> disponibilidad de recuperación ante desastres, calcular un SLA compuesto, elegir entre zonas y regiones
> con su costo, aplicar los patrones de resiliencia en código y hablar el idioma de los cinco pilares del
> Well-Architected Framework.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (regiones, zonas y
> parejas), [`05`](05-balanceo-entrega-global-y-api-management.md) (Front Door),
> [`06`](06-almacenamiento-storage-accounts.md), [`07`](07-bases-relacionales-y-cache.md) y
> [`08`](08-cosmos-db.md) (la replicación de cada almacén).
> **Se toca más con:** [`13`](13-mensajeria-y-eventos.md) (colas como amortiguador) y
> [`16`](16-orquestacion-y-cicd.md) (despliegues que se revierten rápido).
> **Se practica en:** ningún lab; es un capítulo de diseño. Los escenarios de diseño de [`18`](18-preguntas-entrevista-y-mapa-mental.md#parte-vi--escenarios-de-arquitectura) lo ponen a
> prueba.
> **Vigencia:** 28 de septiembre de 2026.

**Salto rápido:** [HA frente a DR](#1--el-problema-alta-disponibilidad-no-es-recuperación) ·
[Los cinco pilares](#2--los-cinco-pilares) · [SLA compuesto](#3--el-sla-compuesto) ·
[⚖ Zonas frente a regiones](#4--zonas-frente-a-regiones) · [Patrones](#5--patrones-de-resiliencia-en-código) ·
[RTO y RPO](#6--rto-rpo-y-las-cuatro-estrategias-de-dr) · [DR por servicio](#7--dr-servicio-por-servicio) ·
[Probar y vigilar](#8--probar-y-vigilar-chaos-studio-y-advisor) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: alta disponibilidad no es recuperación

Dos preguntas que suenan igual y tienen respuestas distintas:

- **alta disponibilidad** (HA): ¿el sistema sigue funcionando cuando falla **un componente** —una
  instancia, un disco, un centro de datos—? Se resuelve con **redundancia dentro de la región**, sobre todo
  con zonas, y el cambio es automático y en segundos;
- **recuperación ante desastres** (DR): ¿cómo vuelvo a funcionar cuando se pierde **una región entera**,
  o cuando un error propio (un despliegue, un borrado, un ransomware) corrompe los datos? Se resuelve con
  **copias en otra región y backups**, y se mide con **RTO** y **RPO** (§6).

Un sistema zone-redundant perfecto no sobrevive a un `DELETE` sin `WHERE` replicado en tres zonas en
milisegundos. Por eso la DR incluye backups con retención, no solo réplicas.

> Nunca respondas: "tenemos réplicas en tres zonas, así que tenemos DR". Mejor: "las zonas nos dan alta
> disponibilidad frente a la caída de un centro de datos; la DR es otra región con RTO y RPO acordados, y
> backups con retención, porque una réplica copia también los errores".

---

## 2. 🧱 Los cinco pilares

El **Azure Well-Architected Framework** organiza las decisiones de arquitectura en cinco pilares, cada uno
con sus principios, su lista de revisión y sus **trade-offs** con los demás:

| Pilar | La pregunta | Trade-off típico |
|---|---|---|
| **Reliability** | ¿Sigue funcionando y se recupera? | Más redundancia = más costo y más complejidad |
| **Security** | ¿Está protegido y es auditable? | Más controles = más fricción operativa y a veces más latencia |
| **Cost Optimization** | ¿Pagamos solo lo que aporta valor? | Menos recursos = menos margen ante picos y fallos |
| **Operational Excellence** | ¿Se despliega, observa y opera con seguridad? | Automatizar cuesta al principio y ahorra después |
| **Performance Efficiency** | ¿Escala y responde con lo justo? | Optimizar para latencia puede sacrificar costo o simplicidad |

En una entrevista de arquitecto, los pilares sirven para **estructurar una respuesta**: ante "diseña X",
recorrer cada pilar obliga a hablar de identidad sin secretos, observabilidad, costo y recuperación, que
es lo que se evalúa. Microsoft ofrece además la **Azure Well-Architected Review**, un cuestionario que
evalúa una carga contra los cinco pilares.

---

## 3. 🧱 El SLA compuesto

Cada servicio de Azure publica su **SLA**: el porcentaje de disponibilidad mensual que Microsoft se
compromete a dar (y el crédito si no). Un sistema es una **cadena** de servicios, y la disponibilidad de
una cadena en serie es el **producto** de sus disponibilidades:

```text
Cifras ilustrativas (los SLA reales se consultan en la página de SLA de cada servicio):

Front Door 99.99 %  ×  Container Apps 99.95 %  ×  Cosmos DB 99.99 %  ×  Service Bus 99.9 %
= 0.9999 × 0.9995 × 0.9999 × 0.999 = 0.9983  →  ≈ 99.83 %
```

Lo que dice el cálculo:

- **encadenar servicios baja la disponibilidad**: ningún sistema es más disponible que su eslabón más
  débil, y en la práctica es menos;
- **en paralelo, sube**: dos regiones independientes con 99.83 % cada una dan
  `1 − (1 − 0.9983)² ≈ 99.9997 %`, siempre que el failover funcione y las regiones fallen de forma
  independiente;
- **un eslabón que no es crítico se saca de la cadena**: si la API sigue funcionando cuando Service Bus
  falla (encola en local, degrada), Service Bus no multiplica el SLA de la operación.

La escala de los números, según Learn:

| Disponibilidad | Indisponibilidad al mes | Al año |
|---|---|---|
| 99.9 % | 43.2 minutos | 8.76 horas |
| 99.95 % | 21.6 minutos | 4.38 horas |
| 99.99 % | 4.32 minutos | 52.56 minutos |
| 99.999 % | 25.9 segundos | 5.26 minutos |

> Nunca respondas: "usamos servicios con SLA de 99.99 %, así que nuestro sistema tiene 99.99 %". Mejor:
> "el SLA de un servicio es un compromiso sobre ese servicio; el de mi sistema es el producto de la cadena
> crítica, más mis propios errores y despliegues. Por eso defino un SLO de negocio y diseño la redundancia
> y la degradación para alcanzarlo".

---

## 4. ⚖ Zonas frente a regiones

| Criterio | Zone-redundant (una región, varias zonas) | Multi-región |
|---|---|---|
| Protege de | Caída de un centro de datos o de una zona | Caída de una región; desastres; errores regionales de un servicio |
| Latencia de replicación | Muy baja: se puede replicar **sincrónicamente** | Alta: la replicación suele ser **asincrónica** (RPO > 0) |
| Failover | Automático, transparente | Automático o manual; exige probarlo |
| Costo | Moderado; en muchos servicios, sin recargo o poco | Alto: capacidad duplicada, tráfico entre regiones |
| Complejidad | Baja: suele ser una opción del servicio | Alta: datos, DNS, configuración, despliegues en dos sitios |
| Residencia de datos | Dentro de la región | Hay que elegir la segunda región (su pareja o no) según regulación |

```text
Regla de arquitectura:
Zone-redundant es el punto de partida de todo lo productivo en una región con zonas.
Multi-región se justifica por un RTO/RPO o un requisito regulatorio que la zona no cumple,
no por defecto: duplica el costo y multiplica lo que puede fallar.
```

> Nunca respondas: "multi-región siempre es más resiliente". Mejor: "multi-región protege de más
> escenarios, pero añade replicación asincrónica, failover que hay que probar y el doble de superficie de
> error. Un multi-región que nunca se probó suele ser menos resiliente que un zone-redundant bien
> operado".

---

## 5. 🧱 Patrones de resiliencia en código

Los fallos transitorios —un `503`, un timeout, un `429` de throttling— son normales en la nube. El código
tiene que esperarlos:

- **retry con backoff exponencial y jitter**: reintentar esperando cada vez más, con una componente
  aleatoria para que mil clientes no reintenten a la vez. Solo operaciones **idempotentes**, y respetando
  la cabecera `Retry-After` de un `429`. **El SDK de Azure para Java ya reintenta** los errores
  transitorios de cada servicio: añadir un retry propio encima multiplica los intentos (3 × 3 = 9) y
  agrava la sobrecarga. Se configura el del SDK, no se apila otro;
- **timeout y presupuesto de tiempo**: cada llamada tiene un timeout, y la suma de timeouts y reintentos de
  una cadena cabe en el tiempo que el cliente de arriba está dispuesto a esperar. Un reintento que llega
  después de que el llamante se rindió es trabajo tirado;
- **circuit breaker**: tras N fallos seguidos, dejar de llamar a la dependencia durante un tiempo y fallar
  rápido (o degradar), en vez de acumular hilos esperando a algo caído. En Java, Resilience4j;
- **bulkhead**: aislar recursos (pools de conexiones, hilos) por dependencia, para que una dependencia
  lenta no consuma los hilos de todas;
- **queue-based load leveling**: poner una cola (Service Bus, [`13`](13-mensajeria-y-eventos.md)) entre quien produce y quien
  procesa, para absorber picos y sobrevivir a caídas del consumidor;
- **throttling**: limitar lo que acepta el sistema (en API Management, [`05` §8](05-balanceo-entrega-global-y-api-management.md#8--políticas-de-api-management)) para proteger lo
  que hay detrás.

> ⚠️ **Reintentos sin control son un ataque de denegación de servicio contra ti mismo.** Una dependencia
> que se recupera de una caída recibe de golpe todos los reintentos acumulados y vuelve a caer. Backoff,
> jitter, límite de intentos y circuit breaker existen para eso.

---

## 6. 🧱 RTO, RPO y las cuatro estrategias de DR

- **RTO** (*Recovery Time Objective*): cuánto tiempo puede estar caído el sistema tras un desastre;
- **RPO** (*Recovery Point Objective*): cuántos datos, medidos en tiempo, se pueden perder. Un RPO de 5
  minutos significa que perder los últimos 5 minutos de transacciones es aceptable.

Los dos los fija **el negocio**, y cuanto más bajos, más caros. Las cuatro estrategias clásicas, de más
barata y lenta a más cara y rápida:

| Estrategia | Qué hay en la región secundaria | RTO | RPO | Costo |
|---|---|---|---|---|
| **Backup & restore** | Solo backups (geo-redundantes) | Horas o días | El del último backup | Bajo |
| **Pilot light** | Datos replicados; cómputo apagado o mínimo, desplegable con IaC | Decenas de minutos a horas | Minutos | Medio-bajo |
| **Warm standby** | Todo desplegado a escala reducida, recibiendo datos | Minutos | Segundos a minutos | Medio-alto |
| **Active-active** | Todo desplegado y sirviendo tráfico en las dos regiones | Casi cero | Casi cero (según la replicación) | Alto |

La IaC del [`15`](15-bicep-iac.md) es lo que hace viable un pilot light: la infraestructura de la región secundaria
se despliega desde el mismo Bicep en minutos.

---

## 7. 🧱 DR servicio por servicio

Lo que ofrece cada almacén del curso, con remisión a su capítulo:

- **Azure SQL** ([`07` §6](07-bases-relacionales-y-cache.md#6--backups-pitr-y-retención-larga) y §7): **failover groups** con un listener que no cambia tras el failover;
  replicación asincrónica (RPO de segundos) y, con la política administrada por el cliente, el failover lo
  decide tu runbook. Backups con PITR y geo-restore como red de seguridad;
- **Storage** ([`06` §3](06-almacenamiento-storage-accounts.md#3--redundancia) y §4): **GRS/GZRS** replican de forma asincrónica a la región pareja;
  **RA-GRS/RA-GZRS** permiten leer de la secundaria sin esperar al failover; el failover de la cuenta lo
  lanza el cliente;
- **Cosmos DB** ([`08` §7](08-cosmos-db.md#7--los-cinco-niveles-de-consistencia) y §10): **multi-región** con escrituras en una región y failover automático, o
  **escrituras multi-región** para active-active, con la consistencia elegida decidiendo el RPO;
- **Front Door** ([`05` §4](05-balanceo-entrega-global-y-api-management.md#4--front-door)) delante de dos regiones: sondas de salud y enrutamiento a la región
  sana, que convierte dos despliegues regionales en un servicio global;
- **Service Bus Premium**: geo-replicación y geo-DR del namespace, para que la mensajería no sea el
  eslabón regional que queda.

> 🧠 **Modelo mental.** Un failover de región no es un botón: es un **runbook** con orden (datos primero,
> luego cómputo, luego DNS), responsables y una prueba periódica. El RTO real es el de la última prueba,
> no el de la diapositiva.

---

## 8. 🧱 Probar y vigilar: Chaos Studio y Advisor

- **Azure Chaos Studio** inyecta fallos controlados —apagar una VM, cortar la red de una zona, forzar el
  failover de Cosmos DB, llenar la CPU— para comprobar que la resiliencia diseñada funciona. Es la forma
  de convertir "creemos que el failover funciona" en "lo probamos el martes".
- **Azure Advisor** analiza la configuración y el uso y da recomendaciones de los cinco pilares:
  recursos sin redundancia de zona, VMs infrautilizadas, reservas que ahorrarían, configuraciones
  inseguras. Es gratuito y es el primer sitio que mirar en una revisión.
- **Service Health** ([`14` §9](14-observabilidad-monitor-log-analytics-app-insights.md#9--resource-graph-service-health-y-resource-health)) avisa de los incidentes de la plataforma, y sus alertas deben
  llegar al mismo action group que las de la aplicación.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Tenemos réplicas en tres zonas, así que tenemos DR" | Zonas = HA; DR es otra región y backups, porque la réplica copia los errores |
| "El SLA de un servicio es el SLA de mi sistema" | El del sistema es el producto de la cadena crítica, más tus propios fallos |
| "Multi-región es siempre más resiliente" | Y más caro y complejo; sin pruebas de failover, puede ser menos |
| "Añado un retry alrededor de la llamada del SDK" | El SDK ya reintenta; apilar retries multiplica la carga |
| "Reintentamos cualquier operación" | Solo las idempotentes, con backoff, jitter y límite |
| "RTO y RPO los decide el equipo técnico" | Los fija el negocio; el equipo dice cuánto cuesta cada valor |
| "El failover de región está automatizado, no hace falta probarlo" | El RTO real es el de la última prueba |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre alta disponibilidad y recuperación ante desastres, y por qué las réplicas no bastan para la DR?
2. ¿Cuáles son los cinco pilares del Well-Architected Framework y qué trade-off típico tiene cada uno?
3. ¿Cómo se calcula el SLA compuesto de una cadena de servicios y qué conclusión práctica sale de él?
4. ¿Cómo cambia el SLA al desplegar en dos regiones en paralelo y qué condición hace falta para que el cálculo sea cierto?
5. ¿Cuántos minutos al mes de indisponibilidad admiten 99.9 % y 99.99 %?
6. ¿Qué te protege una arquitectura zone-redundant y qué no?
7. ¿Cuándo justificas pasar de zone-redundant a multi-región?
8. ¿Por qué no conviene envolver en un retry propio una llamada del SDK de Azure?
9. ¿Qué es un presupuesto de tiempo (timeout budget) y por qué importa en una cadena de llamadas?
10. ¿Qué problema resuelven el circuit breaker y el bulkhead?
11. ¿Qué son RTO y RPO, y quién los fija?
12. Describe las cuatro estrategias de DR y su relación costo/RTO.
13. ¿Qué ofrecen Azure SQL, Storage y Cosmos DB para DR entre regiones?
14. ¿Para qué sirve Azure Chaos Studio y por qué es importante probar el failover?
15. ¿Qué aporta Azure Advisor en una revisión de arquitectura?

---

## 📚 Referencias oficiales

- Los pilares del Well-Architected Framework: https://learn.microsoft.com/en-us/azure/well-architected/pillars
- Métricas de fiabilidad y SLO compuestos: https://learn.microsoft.com/en-us/azure/well-architected/reliability/metrics
- Redundancia y diseño multi-región: https://learn.microsoft.com/en-us/azure/well-architected/reliability/redundancy
- Estrategia de recuperación ante desastres: https://learn.microsoft.com/en-us/azure/well-architected/reliability/disaster-recovery
- Manejo de fallos transitorios: https://learn.microsoft.com/en-us/azure/well-architected/design-guides/handle-transient-faults
- Fiabilidad en Azure: https://learn.microsoft.com/en-us/azure/reliability/overview
- Availability zones: https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview
- Replicación entre regiones y parejas: https://learn.microsoft.com/en-us/azure/reliability/regions-paired
- Patrón retry: https://learn.microsoft.com/en-us/azure/architecture/patterns/retry
- Patrón circuit breaker: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- Patrón bulkhead: https://learn.microsoft.com/en-us/azure/architecture/patterns/bulkhead
- Patrón queue-based load leveling: https://learn.microsoft.com/en-us/azure/architecture/patterns/queue-based-load-leveling
- Patrón throttling: https://learn.microsoft.com/en-us/azure/architecture/patterns/throttling
- Buenas prácticas ante fallos transitorios: https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults
- Arquitectura de referencia zone-redundant de App Service: https://learn.microsoft.com/en-us/azure/architecture/web-apps/app-service/architectures/baseline-zone-redundant
- SDK de Azure para Java: https://learn.microsoft.com/en-us/azure/developer/java/sdk/overview
- ¿Qué es Azure Chaos Studio?: https://learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview
- ¿Qué es Azure Advisor?: https://learn.microsoft.com/en-us/azure/advisor/advisor-overview
