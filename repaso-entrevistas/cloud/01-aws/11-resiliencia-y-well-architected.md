# 11 — Resiliencia, Well-Architected y continuidad

> **Objetivo:** tener un marco para contestar la pregunta más abierta de una entrevista
> de arquitectura —"¿cómo evaluarías este diseño?"— y sostenerlo con RTO, RPO y números.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) a
> [`08`](08-observabilidad-auditoria-gobierno.md).
> **Se conecta con:** [`12`](12-orquestacion-y-cicd.md) (reintentos y compensación en
> una State Machine).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

---

## 1. 🧭 AWS Well-Architected Framework — los 6 pilares

Ante "¿cómo evaluarías si este diseño está bien?", la respuesta estructurada es el Well-Architected Framework: seis pilares con los que se audita cualquier arquitectura, no una checklist de servicios.

```text
Operational Excellence
Security
Reliability
Performance Efficiency
Cost Optimization
Sustainability
```

No es un framework que se aplica una sola vez: AWS lo posiciona como una práctica continua (Well-Architected Reviews), y ninguno de los seis pilares es "el más importante" en abstracto — depende del sistema y su contexto de negocio.

---

## 2. 🧭 Qué evalúa cada pilar

| Pilar | Pregunta central |
|---|---|
| Operational Excellence | ¿Puedo operar, monitorear y mejorar este sistema con confianza? |
| Security | ¿Los datos y sistemas están protegidos con el menor privilegio posible? |
| Reliability | ¿El sistema se recupera de fallas y cumple su función esperada? |
| Performance Efficiency | ¿Los recursos se usan eficientemente frente a la demanda? |
| Cost Optimization | ¿Se logra el resultado de negocio al menor costo posible? |
| Sustainability | ¿Se minimiza el impacto ambiental del uso de recursos? |

Cada pilar tiene sus propios design principles documentados por AWS; para entrevista, lo esencial es reconocer el nombre, la pregunta que responde y un ejemplo de decisión asociada a cada uno.

---

## 3. ⚖ Trade-offs entre pilares

Los seis pilares compiten entre sí. Optimizar uno sin mirar los demás es la forma más común de fallar esta pregunta en entrevista.

```text
Más réplicas Multi-AZ/Multi-Region → ↑ Reliability, ↑ Cost
Menos capacidad reservada          → ↑ Cost Optimization, ↓ Performance bajo pico
Más logging/tracing detallado      → ↑ Operational Excellence, ↑ Cost
Menos revisiones/aprobaciones      → ↑ velocidad operativa, ↓ Security
```

Regla de entrevista:

```text
No respondas "optimizo todos los pilares".
Nombra explícitamente cuál priorizas para ESTE sistema y qué pilar sacrificas parcialmente, y por qué.
```

---

## 4. 🧱 Timeout budgets

Vocabulario de resiliencia a nivel aplicación, transversal a cualquier arquitectura con llamadas entre servicios.

Un timeout budget reparte el tiempo total tolerable de una request entre cada salto de la cadena de llamadas.

```text
Request total tolerable: 2000 ms
  │
  ├── API Gateway/ALB overhead: ~50 ms
  ├── Servicio A → Servicio B: 800 ms budget
  ├── Servicio B → DB: 400 ms budget
  └── margen para retries: 750 ms
```

Sin presupuesto explícito, cada servicio define su propio timeout "a ojo": la suma puede superar lo que el cliente está dispuesto a esperar, o un timeout aguas abajo puede terminar siendo más largo que el de quien lo llama, lo que anula el propósito del timeout.

---

## 5. 🧱 Retry con backoff exponencial + jitter

Reintentar una llamada fallida está implícito en otros documentos de este curso (retry en SQS, DLQ); aquí se nombra el patrón general.

```text
intento 1 falla → esperar ~100 ms
intento 2 falla → esperar ~200 ms
intento 3 falla → esperar ~400 ms
```

Backoff exponencial simple: si muchos clientes fallan al mismo tiempo — por ejemplo, tras recuperarse un servicio caído — todos reintentan sincronizados en los mismos instantes, generando un nuevo pico ("thundering herd") sobre el servicio que se está recuperando. El **jitter** agrega aleatoriedad al tiempo de espera para desincronizar esos reintentos.

```text
espera = base * 2^intento ± aleatorio
```

No digas "ya reintento con backoff, así que ya soy resiliente". Mejor:

> El backoff exponencial evita retries agresivos que empeoran un servicio degradado; el jitter evita que esos retries se sincronicen entre clientes y generen un nuevo pico.

---

## 6. 🧱 Circuit breaker

Un circuit breaker deja de intentar una operación que viene fallando de forma sostenida, en vez de seguir reintentando contra un servicio caído.

```text
CLOSED (normal)
   │ fallas superan umbral
   ▼
OPEN (falla rápido, sin llamar al servicio)
   │ pasa un tiempo de espera
   ▼
HALF-OPEN (deja pasar algunas llamadas de prueba)
   │
   ├── funcionan → CLOSED
   └── fallan    → OPEN
```

Objetivo doble: proteger al llamador (evita bloquear threads/conexiones esperando el timeout de un servicio caído) y proteger al servicio que falla (evita seguir recibiendo tráfico mientras se recupera).

---

## 7. 🧱 Bulkhead

Aísla recursos (pools de conexión, threads, capacidad) entre distintos consumidores o dependencias, para que la saturación de uno no consuma toda la capacidad disponible del sistema.

```text
Sin bulkhead:
   pool compartido de 100 conexiones
   dependencia lenta consume las 100 → todo el sistema se bloquea

Con bulkhead:
   dependencia A → pool de 30
   dependencia B → pool de 30
   dependencia C → pool de 40
   dependencia lenta A satura su propio pool; B y C siguen funcionando
```

Nombre tomado de los compartimentos estancos de un barco: una vía de agua en un compartimento no hunde el barco completo.

---

## 8. 🧱 Disaster Recovery — RTO y RPO como eje de decisión

Toda estrategia de DR se decide en función de dos números, no de qué tan sofisticada suene la arquitectura:

```text
RTO (Recovery Time Objective)  → cuánto tiempo puede estar el sistema caído
RPO (Recovery Point Objective) → cuántos datos puede permitirse perder, medido en tiempo
```

```text
Última copia/replicación exitosa         Falla          Sistema recuperado
        │                                  │                    │
        ├──────────── RPO ─────────────────┤                    │
        │                                  ├──────── RTO ───────┤
```

Regla de arquitectura:

```text
RTO/RPO más agresivos (más cerca de cero) → más costo y complejidad de la estrategia DR
No existe estrategia "gratis" con RTO/RPO cercanos a cero
```

---

## 9. 🧱 Backup & Restore

La estrategia DR más económica y más lenta.

```text
Backups (S3/AWS Backup) en region secundaria
   │ ante desastre en region primaria
   ▼
provisionar infraestructura desde cero
   │
   ▼
restaurar datos desde backup
```

- RTO: horas — aprovisionar infraestructura completa toma tiempo.
- RPO: depende de la frecuencia de backup, típicamente horas.
- Costo: el más bajo de las cuatro estrategias — casi no hay infraestructura corriendo en la region secundaria.

---

## 10. 🧱 Pilot Light

Una versión mínima del sistema corre siempre en la region secundaria — normalmente solo los componentes de datos, sin capacidad de cómputo activa.

```text
Region primaria:   sistema completo activo
Region secundaria: DB replicando, cómputo apagado/escalado a cero
   │ ante desastre
   ▼
escalar cómputo en la region secundaria
   │
   ▼
promover DB / redirigir tráfico
```

- RTO: menor que Backup & Restore — no hay que restaurar datos desde cero, solo escalar cómputo.
- RPO: mejor, ligado al lag de replicación de datos, no a la frecuencia de backup.
- Costo: mayor que Backup & Restore, menor que Warm Standby.

---

## 11. 🧱 Warm Standby

Una versión reducida pero funcional del sistema corre activamente en la region secundaria, con capacidad menor a producción.

```text
Region primaria:   100% de capacidad
Region secundaria: sistema completo corriendo, capacidad reducida (ej. 20%)
   │ ante desastre
   ▼
escalar capacidad en region secundaria
   │
   ▼
redirigir tráfico (Route 53)
```

- RTO: minutos — el sistema ya está corriendo, solo escala.
- RPO: bajo, replicación de datos activa y continua.
- Costo: mayor que Pilot Light — hay cómputo corriendo permanentemente, aunque reducido.

---

## 12. 🧱 Multi-site Active/Active

Ambas (o más) regiones sirven tráfico de producción simultáneamente, a capacidad completa.

```text
Region A (activa) ◄── tráfico ──► Region B (activa)
        │                              │
        └──────── datos sincronizados/replicados ────────┘
```

- RTO: segundos a casi cero — la otra region ya está sirviendo tráfico real.
- RPO: el más bajo de las cuatro estrategias, sujeto al modelo de consistencia de datos multi-region elegido.
- Costo: el más alto — capacidad completa duplicada (o más) corriendo permanentemente, y la complejidad de mantener datos consistentes entre regiones activas.

---

## 13. ⚖ Tabla comparativa de las 4 estrategias DR

| Estrategia | RTO | RPO | Costo relativo | Cómputo en secundaria |
|---|---|---|---|---|
| Backup & Restore | horas | horas | muy bajo | ninguno |
| Pilot Light | decenas de minutos | minutos | bajo | ninguno/mínimo |
| Warm Standby | minutos | segundos-minutos | medio-alto | reducido, activo |
| Multi-site Active/Active | segundos | casi cero | alto | completo, activo |

Regla de entrevista:

```text
No hay "mejor estrategia DR" en abstracto.
Se elige la estrategia más barata que cumpla el RTO/RPO que el negocio realmente necesita.
```

---

## 14. 🧭 Cómo se conectan Well-Architected + resiliencia + DR en una respuesta de entrevista de arquitectura

Estos tres temas no son independientes: son la misma conversación en distintos niveles de detalle.

```text
Well-Architected → framework para evaluar el diseño completo (6 pilares)
   │
   └── pilar Reliability
           │
           ├── patrones de resiliencia a nivel aplicación (circuit breaker, retry+jitter, bulkhead, timeout budgets)
           └── estrategia de continuidad ante desastre (RTO/RPO → Backup&Restore/Pilot Light/Warm Standby/Active-Active)
```

Ante "¿cómo diseñarías esto para que sea confiable?", una respuesta bien calibrada nombra el pilar (Reliability), después el patrón de resiliencia aplicable al problema puntual, y cierra con la estrategia DR justificada por el RTO/RPO real del negocio — no la más sofisticada posible.

---

## 🧠 Preguntas rápidas

1. ¿Cuáles son los 6 pilares del Well-Architected Framework?
2. ¿Por qué optimizar un pilar sin mirar los demás es una respuesta débil?
3. ¿Qué resuelve un timeout budget que un timeout aislado por servicio no resuelve?
4. ¿Para qué sirve el jitter en un backoff exponencial?
5. ¿Qué estados tiene un circuit breaker?
6. ¿Qué problema resuelve un bulkhead?
7. ¿Qué mide RTO y qué mide RPO?
8. ¿Cuál es la estrategia DR más barata y cuál la más cara?
9. ¿Qué diferencia a Pilot Light de Warm Standby?
10. ¿Por qué Multi-site Active/Active tiene el RPO más bajo de las cuatro estrategias?
11. ¿Cómo se relacionan la resiliencia de aplicación y la estrategia DR con el pilar Reliability?

---

## 📚 Referencias oficiales

- AWS Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
- Reliability Pillar: https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html
- Sustainability Pillar: https://docs.aws.amazon.com/wellarchitected/latest/sustainability-pillar/sustainability-pillar.html
- Disaster recovery options in the cloud: https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html
- AWS Backup: https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html
- Operational Excellence Pillar: https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/welcome.html
- Security Pillar: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
- Performance Efficiency Pillar: https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html
- Cost Optimization Pillar: https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html
- Whitepaper de Disaster Recovery: https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html
- Comportamiento de reintentos en los SDK: https://docs.aws.amazon.com/sdkref/latest/guide/feature-retry-behavior.html
- AWS Fault Injection Service: https://docs.aws.amazon.com/fis/latest/userguide/what-is.html
- Amazon Builders' Library — timeouts, retries y backoff con jitter: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
