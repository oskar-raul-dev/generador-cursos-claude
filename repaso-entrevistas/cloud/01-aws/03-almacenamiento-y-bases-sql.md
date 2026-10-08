# 03 — Almacenamiento y bases de datos SQL

> **Objetivo:** distinguir los tres modelos de almacenamiento y no confundir nunca más
> alta disponibilidad con escalado de lecturas ni una réplica con un backup.
> **Se asume leído:** [`01`](01-infraestructura-global-y-redes.md) — subnets privadas y
> Security Groups.
> **Se conecta con:** [`04`](04-dynamodb-nosql.md) (cuándo la respuesta no es SQL) y
> [`11`](11-resiliencia-y-well-architected.md) (RTO/RPO de cada estrategia de backup).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Tres modelos de almacenamiento](#1--tres-modelos-de-almacenamiento) · [S3 — Simple Storage Service](#2--s3--simple-storage-service) · [S3 Versioning](#3--s3-versioning) · [S3 Lifecycle](#4--s3-lifecycle) · [S3 Storage Classes — mapa conceptual](#5--s3-storage-classes--mapa-conceptual) · [EBS](#6--ebs) · [EFS](#7--efs) · [RDS — Relational Database Service](#8--rds--relational-database-service) · [Motores RDS](#9--motores-rds) · [Aurora](#10--aurora) · [Multi-AZ: alta disponibilidad](#11--multi-az-alta-disponibilidad) · [Read Replicas](#12--read-replicas) · [Multi-AZ vs Read Replica](#13--multi-az-vs-read-replica) · [Backups vs snapshots](#14--backups-vs-snapshots) · [AWS Backup — política centralizada](#15--aws-backup--política-centralizada) · [RDS Proxy — idea base](#16--rds-proxy--idea-base) · [ElastiCache — idea base](#17--elasticache--idea-base) · [SQL vs DynamoDB — preview](#18--sql-vs-dynamodb--preview) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

# Parte I — Modelos de almacenamiento

## 1. 🧭 Tres modelos de almacenamiento

| Servicio | Modelo | Analogía |
|---|---|---|
| EBS | Block storage | disco virtual |
| EFS | File storage | filesystem compartido/NFS |
| S3 | Object storage | almacén de objetos vía API |

No son sustitutos directos.

---

## 2. 🧱 S3 — Simple Storage Service

S3 es **object storage**.

Modelo:

```text
Bucket
├── images/logo.png
├── invoices/2026/001.pdf
└── backups/database.dump
```

Conceptos:

- bucket;
- object;
- key;
- metadata;
- storage class;
- versioning;
- lifecycle;
- encryption;
- bucket policy;
- access control.

### No es un filesystem POSIX tradicional

No pienses primero en:

```text
mount + random block writes + rename semantics POSIX
```

Piensa en operaciones sobre objetos mediante API.

---

## 3. 🧱 S3 Versioning

Versioning conserva múltiples versiones de un objeto.

Si sobrescribes:

```text
invoice.pdf v1
invoice.pdf v2 ← current
```

La anterior puede conservarse.

Al borrar un objeto en un bucket versionado normalmente se introduce un **delete marker** como versión actual en lugar de destruir inmediatamente todas las versiones.

Útil para:

- recuperación de borrados accidentales;
- protección contra overwrites;
- gobierno de datos.

Tiene costo: cada versión ocupa almacenamiento.

---

## 4. 💰 S3 Lifecycle

Las Lifecycle Rules automatizan:

- transición a storage classes más económicas;
- archivado;
- expiración/borrado;
- tratamiento de versiones no actuales.

Ejemplo conceptual:

```text
0 días    → S3 Standard
30 días   → Standard-IA
365 días  → Glacier
7 años    → Expire
```

Las políticas reales dependen del patrón de acceso y costos de recuperación.

---

## 5. 💰 S3 Storage Classes — mapa conceptual

No memorices cada tarifa. Entiende el trade-off:

```text
más frecuente acceso
       │
       ▼
Standard
Intelligent-Tiering
Standard-IA / One Zone-IA
Glacier Instant Retrieval
Glacier Flexible Retrieval
Glacier Deep Archive
       ▲
       │
menos frecuente / más archivado
```

Lo que baja al bajar por esa lista es el precio del almacenamiento; lo que sube son dos
cosas que casi nadie mira al elegir, y que son las que producen la factura sorpresa.

La primera es el **costo de recuperación**: en las clases infrecuentes y de archivo pagas
por cada GB que lees, además del almacenamiento. Un dataset que resultó ser más consultado
de lo previsto puede costar en recuperaciones bastante más de lo que ahorró en
almacenamiento. La segunda es la **duración mínima facturable**: las clases IA facturan
como mínimo 30 días por objeto y las de Glacier entre 90 y 180, así que un objeto movido a
IA y borrado a la semana se cobra el mes completo. Una lifecycle rule agresiva sobre datos
de vida corta puede salir más cara que no hacer nada.

Y la latencia cambia de naturaleza, no solo de magnitud: Standard, IA y Glacier Instant
responden en milisegundos, pero Glacier Flexible y Deep Archive exigen **pedir** el objeto
y esperar de minutos a horas a que esté disponible. Ahí ya no es un ajuste de costos: es
un cambio en lo que tu aplicación puede prometer.

> 💡 **Truco.** Cuando el patrón de acceso es desconocido o irregular,
> **Intelligent-Tiering** mueve cada objeto entre niveles por ti según su uso real y cobra
> una pequeña tarifa de monitoreo por objeto. Es la opción sensata cuando la alternativa
> es adivinar.

---

## 6. 🧱 EBS

EBS ofrece **block storage** persistente.

Casos:

- filesystem de EC2;
- discos de aplicaciones;
- bases de datos sobre EC2;
- snapshots para backup/restore.

Piensa:

```text
EC2 ─── EBS volume
```

No confundir:

```text
EBS != instance store
```

Instance Store es almacenamiento efímero físicamente asociado al host para instance types compatibles.

---

## 7. 🧱 EFS

Filesystem elástico compartido basado en NFS para workloads compatibles.

```text
EC2 A ─┐
EC2 B ─┼── EFS
EC2 C ─┘
```

Útil cuando múltiples instancias necesitan un filesystem compartido, algo distinto de object storage S3 y block storage EBS.

---

# Parte II — SQL administrado

## 8. 🧱 RDS — Relational Database Service

RDS administra motores relacionales.

Conceptualmente:

```text
Tu app
  │ JDBC/driver
  ▼
RDS PostgreSQL/MySQL/etc.
```

Siguen existiendo conceptos SQL normales:

- tablas;
- índices;
- joins;
- constraints;
- transacciones;
- ACID según motor;
- query planner;
- conexiones.

AWS administra gran parte de:

- provisioning;
- infraestructura;
- backups automatizados;
- patching/mantenimiento dentro del modelo del servicio;
- monitoring/integración;
- failover en configuraciones HA.

No significa que AWS diseñe tus índices, queries o modelo relacional correctamente por ti.

---

## 9. 🧱 Motores RDS

RDS soporta varios motores. Para un perfil backend normalmente debes reconocer al menos:

```text
PostgreSQL
MySQL
MariaDB
Oracle
SQL Server
```

Aurora se estudia aparte porque es un motor/arquitectura de AWS compatible con PostgreSQL/MySQL.

---

## 10. 🧱 Aurora

Amazon Aurora es una base relacional cloud-native de AWS compatible con MySQL y PostgreSQL.

Modelo simplificado:

```text
Aurora Cluster
├── Writer
├── Reader
└── distributed cluster storage
```

No digas simplemente “Aurora = RDS PostgreSQL más rápido”.

Mejor:

> Aurora es un motor relacional administrado por AWS con compatibilidad MySQL/PostgreSQL y arquitectura de almacenamiento/replicación propia.

---

## 11. 🧱 Multi-AZ: alta disponibilidad

La frase histórica:

```text
Multi-AZ → High Availability
```

sigue siendo buena, pero RDS actual tiene más de una modalidad.

### Multi-AZ DB instance deployment

- writer/primary;
- una standby en otra AZ;
- standby destinada a failover, no a servir read traffic normal.

### Multi-AZ DB cluster deployment

La documentación actual describe:

- un writer;
- dos reader instances;
- tres AZ separadas;
- replicas legibles y failover.

Por eso hay que evitar la respuesta demasiado absoluta “Multi-AZ nunca sirve lecturas”: eso describe el modelo clásico de **Multi-AZ DB instance**, no todos los deployments modernos de RDS.

---

## 12. 🧱 Read Replicas

Propósito principal:

```text
scale reads
```

Modelo:

```text
           Primary
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
    Reader  Reader  Reader
```

La replicación para read replicas suele ser asíncrona, por lo que hay que contemplar replica lag y consistencia observable por la aplicación.

Read replica puede servir también en algunos motores/escenarios para DR/migración/promoción, pero su asociación mental primaria en entrevista es **read scaling**.

---

## 13. ⚖ Multi-AZ vs Read Replica

Las dos cosas copian tus datos a otra instancia, y por eso se confunden. Pero resuelven
preguntas distintas: Multi-AZ responde *"¿qué pasa si se cae la AZ?"* y la read replica
responde *"¿qué pasa si me sobran lecturas?"*.

| Necesidad | Concepto principal |
|---|---|
| Failover/HA | Multi-AZ |
| Escalar lecturas | Read Replica |
| Reducir RTO ante fallo zonal | Multi-AZ |
| Offload de consultas de lectura | Read Replica |

La diferencia técnica de fondo son dos: **quién promueve y con qué replicación**. La
standby de un Multi-AZ clásico se replica de forma síncrona —la escritura no se confirma
hasta estar en las dos AZ, de ahí que no pierdas datos en el failover— y AWS la promueve
sola, sin que nadie despierte a nadie. La read replica se replica de forma asíncrona
—por eso tiene lag, y por eso una consulta contra ella puede no ver lo que acabas de
escribir— y promoverla es una acción manual que además rompe la replicación para
siempre.

De ahí sale la respuesta a la pregunta capciosa habitual: una read replica **sí** puede
usarse como plan de recuperación, pero con RPO distinto de cero (lo que quepa en el lag)
y RTO manual, mientras que Multi-AZ da RPO cero y RTO automático. Son puntos distintos
de la misma curva, no lo mismo con otro nombre — la curva completa está en
[`11` §8](11-resiliencia-y-well-architected.md#8--disaster-recovery--rto-y-rpo-como-eje-de-decisión).

Matiz actual: Multi-AZ DB cluster dispone de readers; aun así, read replicas siguen
siendo un mecanismo separado para escalar lecturas y otros escenarios.

---

## 14. ⚖ Backups vs snapshots

Los dos producen una copia recuperable, y la diferencia es quién decide cuándo y hasta
cuándo vive.

- **automated backups / point-in-time recovery**: los hace RDS solo, según la ventana de
  retención que configuraste, y permiten restaurar a un instante concreto dentro de esa
  ventana. Se borran con la instancia.
- **manual snapshots**: los pides tú, y viven hasta que los borras. Sobreviven a la
  instancia, y esa es justamente la propiedad que los hace útiles antes de una migración
  y peligrosos después de un teardown, porque siguen facturando.
- replicas no sustituyen un backup.

Nunca respondas:

> “Tengo una read replica, entonces no necesito backup.”

El motivo es que la replicación es fiel, y esa fidelidad es el problema: un `DELETE`
sin `WHERE`, una migración que trunca la tabla equivocada o un bug que corrompe datos se
replican con la misma diligencia que los datos buenos, y en segundos. La réplica te
protege de que se rompa el hardware; el backup te protege de que se rompa el software
—o de que te equivoques tú—, y son fallos de naturaleza distinta.

> ⚠️ Un backup que nunca se ha restaurado no está verificado, está supuesto. Es la misma
> idea que cierra §15, y la única prueba válida es un restore real cronometrado: es de
> paso lo que te da el número que vas a citar como RTO.

---

## 15. 🧱 AWS Backup — política centralizada

La sección anterior distingue backups/snapshots dentro de un mismo servicio (RDS). **AWS Backup** resuelve un problema distinto: administrar backups de múltiples servicios bajo una sola política.

```text
RDS snapshot     ┐
EBS snapshot     ├── política y calendario distintos por servicio (sin AWS Backup)
DynamoDB backup  ┘
```

```text
AWS Backup
   │ backup plan
   ├── RDS
   ├── EBS
   ├── DynamoDB
   ├── EFS
   └── otros recursos compatibles
```

Conceptos:

- **backup plan**: schedule + lifecycle + retention, aplicado a los recursos seleccionados;
- **backup vault**: almacén administrado donde se guardan los backups, con Vault Lock opcional para retención inmutable;
- on-demand backup además de scheduled backup;
- copia cross-Region y cross-account dentro de un mismo plan;
- restore testing.

Regla mental:

```text
Backup por servicio → cada equipo configura su propio mecanismo, con su propia política
AWS Backup          → una política, aplicada a varios servicios, auditable centralmente
```

No sustituye la necesidad de probar restores: un backup nunca verificado con un restore real es una promesa, no una garantía.

---

## 16. 🧭 RDS Proxy — idea base

RDS Proxy administra un pool de conexiones entre aplicaciones y bases compatibles.

Útil para workloads con alta volatilidad de conexiones, por ejemplo funciones Lambda o microservicios que pueden abrir muchas conexiones simultáneas.

```text
App instances
   │
   ▼
RDS Proxy
   │
   ▼
RDS/Aurora
```

No reemplaza tuning SQL ni capacidad adecuada del servidor.

---

## 17. 🧭 ElastiCache — idea base

Servicio administrado de caching in-memory para motores soportados.

Uso conceptual:

```text
App
 │
 ├── cache hit → ElastiCache
 │
 └── cache miss → DB → populate cache
```

Casos:

- caché de lecturas;
- sesiones;
- reducción de carga DB;
- estructuras in-memory compatibles con el motor.

Un cache añade problemas de invalidación, expiración y consistencia. No es “DB gratis más rápida”.

---

## 18. ⚖ SQL vs DynamoDB — preview

| | RDS/Aurora | DynamoDB |
|---|---|---|
| Modelo | relacional | key-value/document |
| Joins | sí | no como SQL |
| Query flexibility | alta | access-pattern driven |
| Escala horizontal administrada | depende arquitectura | diseño nativo distribuido |
| Relaciones complejas | natural | denormalización/modelado específico |

DynamoDB se cubre entero en [`04`](04-dynamodb-nosql.md).

---

## 🧠 Preguntas rápidas

1. ¿S3 vs EBS vs EFS?
2. ¿Qué aporta S3 Versioning?
3. ¿Lifecycle rule elimina inmediatamente todos los datos versionados?
4. ¿Qué administra RDS y qué sigue siendo responsabilidad del equipo?
5. ¿RDS PostgreSQL vs Aurora PostgreSQL?
6. ¿Multi-AZ DB instance vs Multi-AZ DB cluster?
7. ¿Multi-AZ vs read replica?
8. ¿Una replica sustituye backup?
9. ¿Qué problema resuelve RDS Proxy?
10. ¿Cuándo introducirías cache?
11. ¿Qué resuelve AWS Backup que los backups por servicio no resuelven?
12. ¿Qué es un backup vault?
13. ¿Por qué un backup sin restore probado no es una garantía?

---

## 📚 Referencias oficiales

- S3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html
- S3 Versioning: https://docs.aws.amazon.com/AmazonS3/latest/userguide/versioning-workflows.html
- S3 Lifecycle: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
- EBS: https://docs.aws.amazon.com/ebs/latest/userguide/what-is-ebs.html
- EFS: https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html
- RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html
- RDS Multi-AZ: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html
- RDS read replicas: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html
- Aurora: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html
- RDS Proxy: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html
- ElastiCache: https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/WhatIs.html
- AWS Backup: https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html
- S3 Storage Classes: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
- Tipos de volumen EBS: https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html
- Snapshots de EBS: https://docs.aws.amazon.com/ebs/latest/userguide/ebs-snapshots.html
- Backups automáticos de RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html
