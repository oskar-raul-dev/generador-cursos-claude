# 08 — Observabilidad, auditoría y gobierno

> **Objetivo:** separar las tres preguntas de la observabilidad —qué pasó, cuánto pasa, quién lo
> hizo— y saber qué queda registrado sin que nadie active nada.
> **Se asume leído:** [`02` — cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md).
> **Se toca sobre todo con:** [`05` — seguridad, IAM y gobierno](05-seguridad-iam-jerarquia-kms-secretos.md) y
> [`11` — resiliencia y Architecture Framework](11-resiliencia-y-well-architected.md).
> **Dónde se practica:** [`L07` — observabilidad: logs, métricas y auditoría](l07-observabilidad-logs-metricas-y-auditoria.md),
> con una alerta que se dispara de verdad.
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Panorama

```text
Cloud Logging          → qué pasó (eventos/registros)
Cloud Monitoring        → cómo está funcionando el sistema (métricas/alertas)
Cloud Audit Logs        → quién hizo qué, cuándo y desde dónde
Cloud Asset Inventory    → qué recursos existen y cómo están configurados
```

```text
Cloud Logging vs Cloud Monitoring
Cloud Audit Logs vs Cloud Asset Inventory
Metrics vs Logs vs Audit Events
```

| | Cloud Logging | Cloud Monitoring | Cloud Audit Logs |
|---|---|---|---|
| Responde | ¿Qué eventos ocurrieron? | ¿Cómo está funcionando el sistema ahora/en el tiempo? | ¿Quién hizo qué cambio administrativo o accedió a qué dato? |
| Unidad | Log entry | Metric/data point | Entrada de audit log |
| Uso típico | Debugging, búsqueda de errores | Alertas, dashboards, SLOs | Investigación de seguridad/compliance |

---

# Parte I — Cloud Logging

## 2. 🧱 Logs, Log entries, Log buckets

- **Logs**: flujos nombrados de entradas (ej. el log de un servicio de
  Cloud Run).
- **Log entries**: cada registro individual, con severidad, timestamp,
  payload y metadata de recurso.
- **Log buckets**: dónde se almacenan las entradas, con su propia
  configuración de retención.

## 3. 🧱 Log sinks

Un **log sink** exporta logs (todos o filtrados) hacia un destino
externo al bucket por defecto: **BigQuery**, **Cloud Storage** o
**Pub/Sub**. Es el mecanismo típico para análisis de logs a largo plazo o
integración con pipelines propios.

```text
Cloud Logging
     │
  Log sink (filtro)
     │
     ├── BigQuery   (análisis SQL)
     ├── Cloud Storage (archivo/retención larga)
     └── Pub/Sub     (procesamiento en tiempo real)
```

## 4. 🧱 Retention

Cada log bucket tiene un período de retención configurable; distinto del
período de retención de un backup o de un audit log específico (ver
Parte III).

---

# Parte II — Cloud Monitoring

## 5. 🧱 Metrics

Datos numéricos con el tiempo (latencia, tasa de error, CPU, backlog de
una cola). Cloud Monitoring recolecta métricas de la mayoría de servicios
de GCP automáticamente.

## 6. 🧱 Alerting policies

Definen condiciones sobre métricas (ej. "latencia p99 > 500ms durante 5
minutos") que, al cumplirse, disparan notificaciones.

## 7. 🧱 Dashboards

Visualizaciones configurables de métricas, usadas para observar el
estado del sistema en tiempo real o durante un incidente.

## 8. 🧱 Custom metrics

Métricas definidas por la aplicación (ej. "órdenes procesadas por
minuto"), enviadas a Cloud Monitoring cuando las métricas estándar de
infraestructura no capturan una señal específica del negocio.

## 9. 🩺 Uptime checks

Verificaciones periódicas de disponibilidad de un endpoint desde
ubicaciones externas — detectan que un servicio está caído desde la
perspectiva de un cliente externo, no solo desde métricas internas.

---

# Parte III — Cloud Audit Logs

## 10. 🧱 Tipos de audit log

| Tipo | Contenido |
|---|---|
| Admin Activity | Cambios administrativos (crear/modificar/eliminar recursos) |
| Data Access | Lecturas y escrituras de datos (deshabilitado por defecto para la mayoría de servicios, por volumen) |
| System Event | Acciones administrativas realizadas por Google, no por un usuario |
| Policy Denied | Solicitudes rechazadas por una política de seguridad (ej. IAM Deny, Organization Policy, VPC Service Controls) |

Cloud Audit Logs responde: **quién hizo qué, cuándo y desde dónde** —
información que no se puede reconstruir de forma confiable a partir de
logs de aplicación.

---

# Parte IV — Cloud Asset Inventory

## 11. 🧱 Inventario y compliance

**Cloud Asset Inventory** mantiene un inventario de recursos y su
**historial de configuración** a través del tiempo, permitiendo consultar
qué recursos existen (o existieron) y validar compliance contra políticas
esperadas.

```text
Cloud Audit Logs        → quién ejecutó el cambio
Cloud Asset Inventory     → cómo quedó/estuvo configurado el recurso
```

---

# Parte V — Diagnóstico de red

## 12. 🧱 VPC Flow Logs

Registran metadata del tráfico IP real entre interfaces (origen,
destino, puertos, protocolo, acción) — no el contenido de la aplicación
(payload).

## 13. 🩺 Connectivity Tests

Parte de **Network Intelligence Center**: analiza estáticamente la
configuración de red (rutas, firewall, peering) para determinar si existe
un path válido y dónde se bloquearía, sin enviar tráfico real.

```text
VPC Flow Logs vs Application Logs
```

VPC Flow Logs observa tráfico de red real a nivel de paquete/conexión;
los logs de aplicación observan eventos a nivel de lógica de negocio —
ninguno sustituye al otro para diagnóstico de un incidente.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a Cloud Logging de Cloud Monitoring?
2. ¿Para qué sirve un log sink?
3. ¿Qué tipos de Cloud Audit Logs existen?
4. ¿Data Access logs están habilitados por defecto para todos los servicios?
5. ¿Qué diferencia a Cloud Audit Logs de Cloud Asset Inventory?
6. ¿Qué mide un uptime check que una métrica interna de latencia no mide igual?
7. ¿Cómo investigarías quién abrió una firewall rule al mundo (`0.0.0.0/0`)?
8. ¿VPC Flow Logs contiene el payload HTTP de las requests?
9. ¿Connectivity Tests envía tráfico real?
10. ¿Qué diferencia a una custom metric de una métrica estándar de infraestructura?

---

## 📚 Referencias oficiales

- Cloud Logging overview: https://cloud.google.com/logging/docs/overview
- Log sinks: https://cloud.google.com/logging/docs/export/configure_export_v2
- Log buckets and retention: https://cloud.google.com/logging/docs/buckets
- Cloud Monitoring overview: https://cloud.google.com/monitoring/docs/monitoring-overview
- Alerting policies: https://cloud.google.com/monitoring/alerts
- Uptime checks: https://cloud.google.com/monitoring/uptime-checks
- Cloud Audit Logs overview: https://cloud.google.com/logging/docs/audit
- Cloud Asset Inventory overview: https://cloud.google.com/asset-inventory/docs/overview
- VPC Flow Logs: https://cloud.google.com/vpc/docs/flow-logs
- Connectivity Tests: https://cloud.google.com/network-intelligence-center/docs/connectivity-tests/concepts/overview
