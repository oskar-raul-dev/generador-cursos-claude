# 03 — Almacenamiento y bases SQL

> **Objetivo:** distinguir los tres modelos de almacenamiento y saber cuándo una base SQL
> administrada es la respuesta correcta y cuándo no.
> **Se asume leído:** [`01` — infraestructura global y redes](01-infraestructura-global-y-redes.md).
> **Se toca sobre todo con:** [`04` — Firestore, Bigtable y NoSQL](04-firestore-bigtable-nosql.md) y
> [`13` — BigQuery y analítica](13-bigquery-analitica.md).
> **Dónde se practica:** no tiene lab propio. Cloud SQL factura por hora y sin cuota gratuita, así
> que la serie práctica lo deja como drill opcional —ver
> [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)—; el bucket de Cloud
> Storage sí se crea en [`L03`](l03-terraform-desde-la-cli.md).
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Tres modelos de almacenamiento

```text
Object Storage   → Cloud Storage
Block Storage    → Persistent Disk
File Storage     → Filestore
```

Analogía:

```text
Persistent Disk ≈ disco
Filestore        ≈ filesystem compartido
Cloud Storage     ≈ almacén de objetos accesible mediante API
```

```text
Cloud Storage vs Persistent Disk vs Filestore
```

| | Cloud Storage | Persistent Disk | Filestore |
|---|---|---|---|
| Modelo | Objetos vía API HTTP | Bloques adjuntados a una VM | Filesystem NFS compartido |
| Alcance típico | Global (bucket con ubicación configurable) | Zonal o regional | Regional |
| Acceso concurrente desde múltiples VMs | ✅ (vía API) | Solo lectura compartida en ciertos modos | ✅ (nativo, NFS) |
| Uso típico | Archivos, backups, assets estáticos, data lake | Disco de arranque/datos de una VM | Home directories compartidos, cargas HPC/render |

---

# Parte I — Cloud Storage

## 2. 🧱 Buckets y objects

Un **bucket** contiene **objects**. Cada object tiene datos, un nombre
(key) único dentro del bucket, y **metadata**.

```text
Bucket: app-uploads
└── Object: users/123/avatar.png
    └── metadata: content-type, tamaño, custom metadata
```

## 3. 🧱 Versioning

Cuando está habilitado, cada sobrescritura o borrado de un object
conserva versiones anteriores en lugar de perderlas, permitiendo
recuperar un object borrado o sobrescrito por error. Tiene costo de
almacenamiento adicional por cada versión conservada.

## 4. 🧱 Lifecycle rules

Automatizan transiciones y eliminación de objects según condiciones (edad
del object, número de versiones no actuales, storage class actual).

```text
Regla: objetos con más de 30 días → mover a Nearline
Regla: versiones no actuales con más de 90 días → eliminar
```

## 5. 💰 Storage classes

| Clase | Uso típico | Disponibilidad relativa | Costo de acceso |
|---|---|---|---|
| Standard | Acceso frecuente | Alta | Bajo costo de acceso, mayor costo de almacenamiento |
| Nearline | Acceso ~mensual | Alta | Costo de acceso más alto que Standard |
| Coldline | Acceso ~trimestral | Alta | Costo de acceso mayor que Nearline |
| Archive | Acceso muy infrecuente | Alta | Menor costo de almacenamiento, mayor costo/latencia de acceso |

Todas las storage classes ofrecen la misma durabilidad y baja latencia de
primer byte; lo que cambia es el costo de almacenamiento frente al costo
y mínimo de retención al acceder.

## 6. 🧱 Replicación multi-región

Un bucket puede ubicarse en una sola región, en un par dual-region, o en
un ámbito multi-region (ej. `US`, `EU`), replicando datos entre múltiples
ubicaciones geográficas de forma administrada, a nivel introductorio.
Mayor alcance geográfico mejora disponibilidad ante fallo regional, a
cambio de mayor costo y de latencia de escritura potencialmente mayor.

## 7. 🧱 Encryption y signed URLs

- **Encryption at rest**: Cloud Storage cifra los datos por defecto, sin
  configuración adicional (ver también sección de KMS en el documento
  [`05`](05-seguridad-iam-jerarquia-kms-secretos.md)).
- **Signed URLs**: URLs con firma criptográfica que otorgan acceso
  temporal y con permisos acotados a un object específico, sin requerir
  que el cliente tenga credenciales de GCP.

```text
App genera signed URL con expiración de 15 minutos
     │
     ▼
Cliente descarga/sube el object directamente a Cloud Storage
```

---

# Parte II — Persistent Disk y Filestore

## 8. 🧱 Persistent Disk

Ver también documento [`02`](02-computo-contenedores-y-balanceo.md) para el detalle de tipos zonal/regional en el
contexto de Compute Engine. Aquí importa como una de las tres familias de
almacenamiento: block storage adjuntable a una VM, con distintos tipos de
rendimiento (estándar, balanceado, SSD) según la carga.

## 9. 🧱 Filestore

Servicio de **file storage** administrado (NFS) para acceso compartido
concurrente desde múltiples VMs o Pods de GKE. Útil para cargas que
esperan un filesystem POSIX compartido (home directories, render farms,
ciertas cargas legacy migradas sin reescribir su capa de I/O).

---

# Parte III — Bases de datos SQL

## 10. 🧱 Cloud SQL

**Cloud SQL** es el servicio administrado de bases relacionales de GCP,
con motores:

```text
PostgreSQL
MySQL
SQL Server
```

Administra provisioning, patching, backups automatizados y failover,
dejando el diseño de esquema, índices y queries como responsabilidad del
equipo.

> 💰 **Costo.** Cloud SQL **no tiene cuota Always Free**: factura por hora de instancia y por GiB de
> almacenamiento, y **el almacenamiento sigue cobrando con la instancia detenida**. Detener no es
> apagar el gasto; borrar sí. Es la razón de que la serie práctica lo deje fuera del tronco —el
> motor se aprende mejor en un contenedor— y lo trate como drill opcional: ver
> [`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones).

## 11. 🧱 AlloyDB

**AlloyDB** es un motor propio de GCP compatible con PostgreSQL, diseñado
para alto rendimiento (arquitectura de almacenamiento distribuido y
separación de cómputo/almacenamiento) frente al PostgreSQL administrado
estándar de Cloud SQL.

```text
Cloud SQL vs AlloyDB
```

| | Cloud SQL (PostgreSQL) | AlloyDB |
|---|---|---|
| Motor | PostgreSQL administrado estándar | Motor propio de GCP, compatible con PostgreSQL |
| Rendimiento en cargas analíticas/transaccionales mixtas | Bueno | Optimizado, mayor throughput |
| Uso típico | Cargas relacionales generales, migraciones directas de PostgreSQL | Cargas relacionales con alta demanda de rendimiento, transaccionales + analíticas embebidas |

## 12. 🧱 Alta disponibilidad regional

La configuración de HA de Cloud SQL usa un disco persistente **regional**
y failover automático hacia una instancia standby en otra Zone de la
misma Region.

```text
Zone A: instancia primaria
Zone B: instancia standby (failover automático)
Disco persistente regional replicado entre ambas Zones
```

## 13. 🧱 Read Replicas

Copias de solo lectura de una instancia primaria, orientadas a escalar
**lecturas**, no a proveer failover automático de escritura.

```text
Alta disponibilidad regional vs Read Replica
```

| | HA regional | Read Replica |
|---|---|---|
| Resuelve | Failover ante falla de la Zone primaria | Escalar carga de lectura |
| Failover automático de escritura | ✅ | No, por defecto |
| Réplica legible para tráfico normal | No (standby no sirve tráfico normal) | ✅ |

```text
Primary vs Replica
HA vs Scaling
```

> Una read replica no sustituye un backup: la replicación también
> propaga borrados o corrupciones lógicas hacia la réplica. Backup y
> replicación resuelven problemas distintos.

## 14. 🧱 Backups

- **Automated backups**: backups programados administrados por Cloud SQL.
- **Snapshots**: copias puntuales, también disponibles manualmente.
- **Point-in-time recovery**: permite restaurar la base a un instante
  específico dentro de la ventana de retención de logs de transacciones,
  no solo al momento del último backup completo.

## 15. 🧱 Cloud SQL Auth Proxy

Un proxy que administra la conexión cifrada y la autenticación IAM hacia
una instancia de Cloud SQL, sin necesitar exponer la instancia con IP
pública ni administrar certificados TLS manualmente en la aplicación.

```text
App (Spring Boot)
    │
Cloud SQL Auth Proxy
    │
Cloud SQL (conexión cifrada + IAM)
```

## 16. 🧱 Connection pooling

Una base relacional tiene un límite de conexiones concurrentes. Un
connection pool en la aplicación (ej. HikariCP en Spring Boot) reutiliza
conexiones en lugar de abrir una nueva por request, evitando agotar ese
límite bajo carga.

## 17. 🧱 Memorystore

**Memorystore** ofrece Redis y Memcached administrados, como
complemento introductorio a las bases SQL: cache de sesiones, resultados
de queries costosas, rate limiting, o estructuras de datos en memoria de
baja latencia.

---

## 18. ⚖ Cuándo usar una base SQL

Una base relacional (Cloud SQL/AlloyDB) es la elección correcta cuando la
carga tiene:

- relaciones complejas entre entidades;
- joins frecuentes;
- integridad referencial fuerte;
- transacciones multi-fila/multi-tabla;
- consultas ad hoc/flexibles que no se conocen todas de antemano;
- reporting **operacional** (no analítico a gran escala — para eso está
  BigQuery, ver documento [`13`](13-bigquery-analitica.md)).

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a Cloud Storage de Persistent Disk y de Filestore?
2. ¿Qué aporta el versioning de Cloud Storage frente a una lifecycle rule?
3. ¿Todas las storage classes de Cloud Storage tienen la misma durabilidad?
4. ¿Para qué sirve una signed URL?
5. ¿Qué administra Cloud SQL y qué sigue siendo responsabilidad del equipo?
6. ¿Qué diferencia a Cloud SQL de AlloyDB?
7. ¿HA regional de Cloud SQL y Read Replica resuelven el mismo problema?
8. ¿Una read replica sustituye a un backup?
9. ¿Qué permite el point-in-time recovery que un backup diario no permite por sí solo?
10. ¿Para qué sirve el Cloud SQL Auth Proxy?
11. ¿Por qué una aplicación necesita connection pooling frente a una base relacional?
12. ¿Cuándo usarías Memorystore en una arquitectura backend típica?
13. ¿Cuándo elegirías una base SQL en lugar de NoSQL?

---

## 📚 Referencias oficiales

- Cloud Storage overview: https://cloud.google.com/storage/docs/introduction
- Object versioning: https://cloud.google.com/storage/docs/object-versioning
- Lifecycle management: https://cloud.google.com/storage/docs/lifecycle
- Storage classes: https://cloud.google.com/storage/docs/storage-classes
- Signed URLs: https://cloud.google.com/storage/docs/access-control/signed-urls
- Persistent Disk: https://cloud.google.com/compute/docs/disks
- Filestore overview: https://cloud.google.com/filestore/docs/overview
- Cloud SQL documentation: https://cloud.google.com/sql/docs
- Cloud SQL high availability: https://cloud.google.com/sql/docs/postgres/high-availability
- Cloud SQL read replicas: https://cloud.google.com/sql/docs/postgres/replication
- Cloud SQL backups: https://cloud.google.com/sql/docs/postgres/backup-recovery/backups
- Point-in-time recovery: https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr
- Cloud SQL Auth Proxy: https://cloud.google.com/sql/docs/postgres/sql-proxy
- AlloyDB overview: https://cloud.google.com/alloydb/docs/overview
- Memorystore overview: https://cloud.google.com/memorystore/docs/redis/overview
