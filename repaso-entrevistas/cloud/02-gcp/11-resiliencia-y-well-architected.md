# 11 — Resiliencia y Google Cloud Architecture Framework

> **Objetivo:** poner nombre a los patrones de resiliencia que se preguntan en entrevista y saber
> elegir una estrategia de DR con RTO y RPO como criterio, no por costumbre.
> **Se asume leído:** [`02`](02-computo-contenedores-y-balanceo.md) y
> [`03`](03-almacenamiento-y-bases-sql.md).
> **Se toca sobre todo con:** [`08` — observabilidad y gobierno](08-observabilidad-auditoria-gobierno.md) y
> [`07` — Pub/Sub e integración](07-pubsub-eventarc-integracion.md).
> **Dónde se practica:** no tiene lab propio: montar un DR real cuesta dinero de verdad. Lo que sí
> se practica es el reintento con backoff de la `retry_policy` de
> [`L06` §7](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md#7--reintentos-ack-deadline-y-at-least-once).
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Google Cloud Architecture Framework

El **Google Cloud Architecture Framework** es el equivalente de GCP a un
framework de buenas prácticas de arquitectura: un conjunto de pilares
para evaluar y guiar decisiones de diseño.

```text
System design
Operational excellence
Security, privacy y compliance
Reliability
Cost optimization
Performance optimization
```

## 2. ⚖ Trade-offs entre pilares

Ningún diseño optimiza los seis pilares simultáneamente al máximo. Por
ejemplo:

- Más **Reliability** (réplicas adicionales, multi-región) casi siempre
  cuesta más en **Cost optimization**.
- Más **Performance optimization** (cachés agresivos, más cómputo
  reservado) puede complicar **Operational excellence** (más piezas que
  operar) o **Cost optimization**.
- Más controles de **Security, privacy y compliance** (revisión manual,
  cifrado adicional, segmentación) suele añadir latencia o fricción
  operativa, en tensión con **Performance optimization** y **Operational
  excellence**.

> Una respuesta de arquitectura madura no dice simplemente "prioricé
> Reliability". Nombra explícitamente qué pilar sacrificó parcialmente y
> por qué esa fue la decisión correcta para el contexto del problema.

---

# Parte I — Patrones de resiliencia

## 3. 🧱 Circuit breaker

Evita seguir llamando a una dependencia que falla de forma sostenida.

```text
CLOSED → llamadas normales
   │ (tasa de error supera umbral)
   ▼
OPEN → llamadas fallan rápido, sin llamar a la dependencia
   │ (pasa un tiempo de espera)
   ▼
HALF-OPEN → deja pasar algunas llamadas de prueba
   │
   ├── éxito → vuelve a CLOSED
   └── fallo → vuelve a OPEN
```

Protege al llamador de bloquearse esperando timeouts contra un servicio
caído, y protege al servicio caído de recibir más tráfico mientras se
recupera.

## 4. 🧱 Retry con backoff y jitter

Un retry ingenuo (reintentar inmediatamente) puede empeorar una
sobrecarga. Un **backoff exponencial** espacia los reintentos cada vez
más; el **jitter** (aleatoriedad añadida al tiempo de espera)
desincroniza los reintentos entre múltiples clientes, evitando que todos
reintenten al mismo tiempo y generen un nuevo pico sobre el servicio que
se está recuperando.

```text
intento 1 → falla → espera ~1s + jitter
intento 2 → falla → espera ~2s + jitter
intento 3 → falla → espera ~4s + jitter
```

## 5. 🧱 Bulkhead

Aísla recursos (pools de conexión, threads, capacidad) entre distintas
dependencias, de forma que la saturación de una dependencia no consuma
toda la capacidad disponible del sistema y arrastre con ella a llamadas
hacia dependencias sanas.

```text
Sin bulkhead:
Pool compartido de 100 threads
   → Dependencia A lenta consume 100 threads
   → Dependencia B (sana) también queda bloqueada

Con bulkhead:
Pool A: 50 threads dedicados a Dependencia A
Pool B: 50 threads dedicados a Dependencia B
   → Dependencia A lenta agota su propio pool
   → Dependencia B sigue funcionando
```

## 6. 🧱 Timeout budgets

Reparte el tiempo total tolerable de una request entre cada salto de la
cadena de llamadas, en lugar de que cada servicio defina su timeout "a
ojo" de forma aislada — evitando que la suma de timeouts individuales
supere lo tolerable para el cliente final.

```text
Cliente tolera 3s total
   │
API Gateway (timeout 3s)
   │
   Service A (timeout 2s)
       │
       Service B (timeout 1s)
```

---

# Parte II — Disaster Recovery

## 7. 🧱 RTO y RPO

- **RTO (Recovery Time Objective)**: cuánto tiempo puede estar el sistema
  caído.
- **RPO (Recovery Point Objective)**: cuántos datos puede permitirse
  perder, medido en tiempo (ej. "hasta 5 minutos de datos").

## 8. 🧱 Estrategias de DR aplicadas a servicios GCP

| Estrategia | RTO típico | RPO típico | Costo | Ejemplo GCP |
|---|---|---|---|---|
| Backup & Restore | Horas | Horas | Bajo | Backups automatizados de Cloud SQL, buckets multi-región de Cloud Storage como destino |
| Pilot Light | Decenas de minutos | Minutos | Medio-bajo | Read replica cross-region de Cloud SQL, sin cómputo activo en la región secundaria |
| Warm Standby | Minutos | Minutos | Medio-alto | Cloud Run/GKE desplegado con capacidad reducida en región secundaria, escalando al fallar |
| Multi-site Active/Active | Segundos | Segundos o menor | Alto | Cloud Load Balancing global sirviendo tráfico activo en ambas regiones, con datos sincronizados |

```text
Pilot Light vs Warm Standby
```

Pilot Light solo mantiene los **datos** replicando en la región
secundaria, sin cómputo activo; Warm Standby mantiene el sistema completo
corriendo con capacidad reducida, con mejor RTO a mayor costo.

## 9. ⚖ Elegir la estrategia correcta

> No respondas automáticamente "Multi-site Active/Active" porque suena
> más robusto. Con un RTO objetivo de 5 minutos, Warm Standby ya cumple
> el objetivo sin pagar el costo y la complejidad de datos multi-región
> de Active/Active — elegir la estrategia más cara sin que el RTO/RPO
> real lo exija es sobre-ingeniería, no buena arquitectura.

---

# Parte III — Cómo se relacionan resiliencia y DR con el framework

## 10. ⚖ Ambos niveles pertenecen al pilar Reliability

Los patrones de resiliencia (circuit breaker, retry+jitter, bulkhead,
timeout budgets) manejan fallas **parciales en tiempo real**. La
estrategia de DR maneja la pérdida de **una región completa**. Ambos son
el detalle técnico del pilar **Reliability** del Architecture Framework
— una respuesta de arquitectura bien calibrada nombra el pilar primero y
después desarrolla ambos niveles.

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son los seis pilares del Google Cloud Architecture Framework?
2. ¿Por qué optimizar un pilar sin mirar los demás es una respuesta débil en una entrevista de arquitectura?
3. ¿Qué estados tiene un circuit breaker?
4. ¿Para qué sirve el jitter en un backoff exponencial?
5. ¿Qué problema resuelve un bulkhead?
6. ¿Qué resuelve un timeout budget que un timeout aislado por servicio no resuelve?
7. ¿Qué mide RTO y qué mide RPO?
8. ¿Cuál es la estrategia de DR más barata y cuál la más cara?
9. ¿Qué diferencia a Pilot Light de Warm Standby?
10. ¿Por qué Multi-site Active/Active tiene el RPO más bajo de las cuatro estrategias?
11. ¿Cómo se relacionan los patrones de resiliencia y la estrategia de DR con el pilar Reliability?

---

## 📚 Referencias oficiales

- Google Cloud Architecture Framework overview: https://cloud.google.com/architecture/framework
- Reliability pillar: https://cloud.google.com/architecture/framework/reliability
- Disaster recovery planning guide: https://cloud.google.com/architecture/dr-scenarios-planning-guide
- Disaster recovery building blocks: https://cloud.google.com/architecture/dr-scenarios-building-blocks
- Cloud SQL high availability and disaster recovery: https://cloud.google.com/sql/docs/postgres/high-availability
