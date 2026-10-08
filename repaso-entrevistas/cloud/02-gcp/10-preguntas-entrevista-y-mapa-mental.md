# 10 — GCP Core: preguntas de entrevista y mapa mental

> **Objetivo:** simular una entrevista completa. Las preguntas `P#` van sin respuesta inline —están
> en [`14`](14-respuestas.md)—; los escenarios de arquitectura del final sí conservan su solución
> desarrollada, porque son ejemplos resueltos y no autochequeo de memoria.
> **Se asume leído:** los documentos [`01`](01-infraestructura-global-y-redes.md) a
> [`09`](09-terraform-iac.md) y [`11`](11-resiliencia-y-well-architected.md) a
> [`13`](13-bigquery-analitica.md).
> **Dónde se practica:** toda la serie [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md)–[`L08`](l08-costos-y-destruccion-verificada.md).
> Varias de estas preguntas se responden mucho mejor después de haber roto algo a propósito.
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Las asociaciones obligatorias

```text
Region                      → geografía
Zone                        → aislamiento de fallos
VPC                         → red virtual global
Subnet                      → segmento de red regional
Firewall rule                → firewall stateful de VPC (allow y deny)
Hierarchical firewall policy  → guardrail a nivel Organization/Folder
Cloud Router                 → routing dinámico BGP, prerequisito de Cloud NAT
Cloud NAT                    → salida a Internet para recursos sin IP externa
Compute Engine               → VM
Image                       → plantilla de disco de arranque
Persistent Disk              → block storage
Cloud Storage                → object storage
Filestore                   → shared file storage
Artifact Registry             → container/package registry
Cloud Run                   → compute serverless para containers (default)
GKE                         → Kubernetes administrado
Cloud Functions              → functions serverless (sobre Cloud Run 2nd gen)
API Gateway / Apigee          → API management (ligero / enterprise)
Cloud CDN                    → edge cache
Google-managed SSL certificates → certificados TLS administrados
Cloud Load Balancing (HTTP(S))  → L7 load balancing global
Network Load Balancing         → L4 load balancing
Cloud SQL / AlloyDB            → SQL administrado
Firestore                    → NoSQL document, operacional
Bigtable                     → NoSQL wide-column, volumen/throughput extremos
Memorystore                  → cache administrado (Redis/Memcached)
Pub/Sub                      → mensajería unificada (queue + fan-out)
Cloud Tasks                  → cola de tareas HTTP controlada por el productor
Eventarc                     → event routing entre servicios GCP
Cloud DNS                    → DNS
Cloud IAM                    → identidad y autorización
Organization → Folder → Project → jerarquía de recursos
Cloud KMS                    → claves/cifrado
Secret Manager                → secretos
Cloud Logging / Cloud Monitoring → logs/métricas/alertas
Cloud Audit Logs              → auditoría de actividad
Cloud Asset Inventory          → inventario/compliance de recursos
Terraform                    → IaC de facto en GCP
Google Cloud Architecture Framework → pilares para evaluar arquitectura
Workflows                    → orquestación explícita de pasos
BigQuery                     → data warehouse analítico serverless
```

---

# Junior refresher

## P1. ¿VPC es global o regional?

## P2. ¿Subnet es zonal o regional?

## P3. ¿Qué es una Zone y qué problema aísla?

## P4. ¿Qué hace Cloud NAT?

## P5. ¿Cloud Run escala a cero por defecto?

## P6. ¿Qué diferencia a Cloud Storage de Persistent Disk?

## P7. ¿Qué es un Project dentro de la jerarquía de GCP?

## P8. ¿Qué diferencia a un registro DNS tipo A de uno AAAA?

## P9. ¿Qué es Pub/Sub, en una frase?

## P10. ¿Qué permite revisar `terraform plan` antes de aplicar cambios?

---

# Mid

## P11. ¿Qué diferencia a una VPC auto-mode de una custom-mode?

## P12. ¿Las firewall rules de VPC admiten reglas DENY?

## P13. ¿Qué diferencia a una Instance Template de un Managed Instance Group?

## P14. ¿Cloud Run vs Cloud Functions (2nd gen)?

## P15. ¿GKE Autopilot vs GKE Standard?

## P16. ¿External HTTP(S) Load Balancing vs Internal HTTP(S) Load Balancing?

## P17. ¿Alta disponibilidad regional de Cloud SQL vs Read Replica?

## P18. ¿Cloud SQL vs AlloyDB?

## P19. ¿Por qué en Firestore se diseña primero a partir de access patterns?

## P20. ¿Cuándo necesita Firestore un índice compuesto declarado explícitamente?

## P21. ¿Primitive role vs Predefined role vs Custom role?

## P22. ¿Qué es envelope encryption?

## P23. ¿Push subscription vs Pull subscription en Pub/Sub?

## P24. ¿Qué hace un dead-letter topic?

## P25. ¿Qué diferencia a Cloud Logging de Cloud Monitoring?

---

# Senior

## P26. ¿Qué problema resuelve Shared VPC que VPC Peering no resuelve igual de bien?

## P27. ¿VPC Peering es transitivo?

## P28. ¿Qué diferencia a Private Service Connect de Private Google Access?

## P29. ¿Cuándo usarías Network Connectivity Center en lugar de un mesh de peering?

## P30. ¿Firestore es siempre fuertemente consistente para cualquier tipo de consulta?

## P31. ¿Cuándo Bigtable es mejor opción que Firestore?

## P32. ¿Las allow policies de IAM son aditivas? ¿Cómo se niega algo explícitamente entonces?

## P33. ¿Qué resuelve Workload Identity Federation frente a una key de Service Account descargada?

## P34. ¿Pub/Sub garantiza exactly-once delivery por defecto?

## P35. ¿Qué diferencia de propósito hay entre Cloud Tasks y Pub/Sub?

## P36. ¿Qué resuelve un timeout budget que un timeout aislado por servicio no resuelve?

## P37. ¿Qué estados tiene un circuit breaker?

## P38. ¿Qué problema resuelve un bulkhead?

## P39. ¿Particionado vs Clustering en BigQuery?

## P40. ¿On-demand pricing vs capacidad reservada en BigQuery?

---

# Software Architect

## P41. ¿Cómo diseñarías Disaster Recovery con RTO de 5 minutos y RPO de 1 minuto?

## P42. ¿Cuándo justificarías GKE sobre Cloud Run en una decisión de arquitectura real?

## P43. ¿Cómo estructurarías IAM y Organization Policies entre proyectos dev/test/prod?

## P44. ¿Cómo decidirías entre BigQuery y Firestore para una nueva feature de reporting?

## P45. ¿Qué trade-offs entre pilares del Architecture Framework nombrarías al justificar una arquitectura multi-región?

## P46. ¿Cuándo usarías Workflows en lugar de un diseño Eventarc + Cloud Run?

## P47. ¿Cómo decidirías entre Cloud VPN y Cloud Interconnect para conectividad on-premises?

## P48. ¿Qué justifica introducir Apigee en lugar de quedarte con API Gateway?

## P49. ¿Cómo diseñarías el particionado y clustering de una tabla de eventos de alto volumen en BigQuery?

## P50. ¿Qué revisarías antes de aprobar un cambio de Terraform que fuerza replacement en una base de datos de producción?

---

# Troubleshooting

## P51. Una VM sin IP externa no puede llegar a Internet — ¿qué revisas?

## P52. Un servicio en Cloud Run no puede conectar a una VM dentro de la VPC — ¿qué falta?

## P53. Una query en Firestore falla pidiendo crear un índice — ¿qué significa y qué haces?

## P54. El throughput de una tabla Bigtable se degrada bajo carga — ¿qué revisas primero?

## P55. `terraform apply` falló a mitad de camino — ¿qué haces a continuación?

## P56. `terraform plan` reporta drift sobre un recurso — ¿qué decisión tomas?

## P57. Un consumer de Pub/Sub está procesando el mismo mensaje más de una vez — ¿qué revisas?

## P58. Una firewall rule bloquea tráfico que debería estar permitido — ¿cómo lo depuras con Connectivity Tests?

---

# Escenarios de arquitectura

## Escenario 1 — API Java altamente disponible

```text
Internet
   │
Cloud DNS
   │
Cloud Load Balancing (global)
   │
 ┌─┴──────────┐
 │            │
Cloud Run    Cloud Run
region-a     region-b
 │            │
 └─────┬──────┘
       ▼
  Cloud SQL (HA regional)
```

Diseño:

- **Cloud DNS** resuelve el dominio hacia el IP anycast de **Cloud Load
  Balancing** (External HTTP(S), global).
- El balanceador enruta hacia backends de **Cloud Run** desplegados en
  al menos dos regiones, vía Serverless NEG.
- Cada revisión de Cloud Run puede escalar horizontalmente por
  concurrencia; no hay servidores que administrar.
- **Cloud SQL** con alta disponibilidad regional (disco persistente
  regional + failover automático) sirve como base transaccional.
- **Cloud Armor** en el borde del balanceador filtra tráfico malicioso
  antes de llegar a Cloud Run.
- **Secret Manager** almacena las credenciales de base de datos;
  **Cloud SQL Auth Proxy** o conexión privada gestionan la conexión.

## Escenario 2 — Procesar 5000 órdenes/s sin bloquear la API

```text
Client
  │
  ▼
Order API (Cloud Run)
  │ persist order
  └──────────────► Pub/Sub
                    │
              ┌─────┼─────┐
              ▼     ▼     ▼
            Worker Worker Worker
          (Cloud Run jobs / services)
```

Respuesta posible:

```text
202 Accepted
```

Puntos a cubrir: desacoplamiento vía Pub/Sub, autoscaling de los workers
por concurrencia/backlog, idempotencia en el consumer (dado at-least-once
delivery por defecto), dead-letter topic para mensajes que agotan
reintentos, y backpressure — si el backlog crece sostenidamente, la
respuesta es escalar consumers o investigar la dependencia downstream, no
ignorar la señal.

## Escenario 3 — Qué servicio de datos usar para cada necesidad

Una aplicación necesita almacenar: usuarios, pedidos, sesiones,
documentos PDF, imágenes, eventos, e histórico analítico para reporting.

| Necesidad | Servicio | Justificación |
|---|---|---|
| Usuarios y pedidos (relaciones, transacciones) | Cloud SQL / AlloyDB | Integridad referencial, joins, transacciones multi-fila |
| Sesiones (baja latencia, TTL) | Firestore o Memorystore | Firestore si necesitas persistencia/consultas; Memorystore si es cache puro de muy baja latencia |
| Documentos PDF e imágenes | Cloud Storage | Object storage con metadata, lifecycle rules, signed URLs |
| Eventos | Pub/Sub → BigQuery | Pub/Sub para ingestión desacoplada en tiempo real, BigQuery como destino analítico |
| Histórico analítico para reporting | BigQuery | Data warehouse serverless, optimizado para escanear grandes volúmenes con SQL, no para transacciones |

> No respondas "Firestore para todo lo que no sea SQL". El criterio es el
> access pattern y el volumen de cada necesidad, no una regla genérica de
> "relacional vs NoSQL".

---

## Autoevaluación final

Si puedes explicar sin mirar:

1. VPC global / Subnet regional / Zone / Region.
2. Firewall rule (allow y deny) vs Hierarchical firewall policy.
3. VPC Peering vs Shared VPC vs Network Connectivity Center.
4. Private Google Access vs Serverless VPC Access vs Private Service Connect.
5. Compute Engine vs Cloud Run vs GKE vs Cloud Functions.
6. External HTTP(S) LB vs Internal HTTP(S) LB vs Network Load Balancing.
7. Cloud Storage vs Persistent Disk vs Filestore.
8. Cloud SQL vs AlloyDB, HA regional vs Read Replica.
9. Firestore (access patterns, índices compuestos, consistencia) vs Bigtable (row key, hot partitions).
10. Cloud IAM (allow policies aditivas, IAM Deny policies, jerarquía Organization/Folder/Project).
11. Cloud KMS vs Secret Manager, envelope encryption.
12. Cloud Armor vs firewall rule, Cloud CDN.
13. Cloud DNS (routing policies), API Gateway vs Apigee.
14. Pub/Sub (at-least-once, ordering keys, dead-letter) vs Cloud Tasks vs Eventarc.
15. Cloud Logging vs Cloud Monitoring vs Cloud Audit Logs vs Cloud Asset Inventory.
16. Terraform: resource/state/plan/apply, replacement, drift, por qué no Deployment Manager.
17. Google Cloud Architecture Framework y sus seis pilares.
18. Circuit breaker, retry+jitter, bulkhead, timeout budgets, RTO/RPO y las cuatro estrategias de DR.
19. Workflows vs Eventarc+Cloud Run, Cloud Build vs Cloud Deploy.
20. BigQuery: particionado vs clustering, on-demand vs capacidad reservada, vs Firestore.

Si alguna no sale de memoria, la respuesta explicada está en
[`14`](14-respuestas.md).

Ya tienes recuperado un núcleo sólido de GCP para una entrevista backend
Senior/Architect.

---

## 📚 Dónde ampliar cada bloque

Este documento no lleva referencias oficiales propias: es una simulación, y cada tema tiene su
capítulo, con su bibliografía verificada al final.

| Si fallaste en… | Vuelve a | Y practícalo en |
|---|---|---|
| VPC, subnets, firewall, NAT, PSC | [`01`](01-infraestructura-global-y-redes.md) | [`L04`](l04-red-vpc-firewall-y-diagnostico.md) |
| Cómputo, contenedores, balanceo | [`02`](02-computo-contenedores-y-balanceo.md) | [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) |
| Storage y bases SQL | [`03`](03-almacenamiento-y-bases-sql.md) | [`L03`](l03-terraform-desde-la-cli.md) |
| Firestore y Bigtable | [`04`](04-firestore-bigtable-nosql.md) | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) |
| IAM, KMS, secretos, gobierno | [`05`](05-seguridad-iam-jerarquia-kms-secretos.md) | [`L02`](l02-iam-allow-policies-service-accounts-e-impersonation.md) |
| DNS, CDN, API management | [`06`](06-cloud-dns-conectividad.md) | drill de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) |
| Pub/Sub, Cloud Tasks, Eventarc | [`07`](07-pubsub-eventarc-integracion.md) | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) |
| Observabilidad y auditoría | [`08`](08-observabilidad-auditoria-gobierno.md) | [`L07`](l07-observabilidad-logs-metricas-y-auditoria.md) |
| Terraform | [`09`](09-terraform-iac.md) | [`L03`](l03-terraform-desde-la-cli.md) |
| Resiliencia y DR | [`11`](11-resiliencia-y-well-architected.md) | [`L06`](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md) |
| Orquestación y CI/CD | [`12`](12-orquestacion-y-cicd.md) | [`L05`](l05-cloud-run-contrato-revisiones-y-trafico.md) |
| BigQuery | [`13`](13-bigquery-analitica.md) | drill de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales) |
| Costo, cuotas y teardown | [`A02`](a02-costos-trampas-y-recursos-huerfanos.md) | [`L01`](l01-proyecto-jerarquia-gcloud-y-blindaje-de-costos.md) y [`L08`](l08-costos-y-destruccion-verificada.md) |
| Errores concretos de GCP | [`A03`](a03-catalogo-de-errores-y-diagnostico.md) | todos los labs |
