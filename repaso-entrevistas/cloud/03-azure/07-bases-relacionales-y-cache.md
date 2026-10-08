# 07 — Bases relacionales y caché

> **Objetivo:** elegir y defender una base relacional administrada en Azure —Azure SQL o PostgreSQL
> Flexible Server—, su modelo de alta disponibilidad, backup y recuperación ante desastres, y la
> caché que va delante.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (zonas y parejas) y
> [`06`](06-almacenamiento-storage-accounts.md) (redundancia de almacenamiento).
> **Se toca más con:** [`06`](06-almacenamiento-storage-accounts.md), cuya redundancia usan los
> backups, y el [`17`](17-resiliencia-y-well-architected.md) (resiliencia), que convierte estas piezas en un plan de DR con RTO y
> RPO.
> **Se practica en:** ningún lab del tronco. Azure SQL tiene un drill gratuito en
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales); el motor, PostgreSQL y Redis se
> practican en contenedor. Los nombres de servidor de este capítulo son de ejemplo y quedan fuera del
> baseline por eso.
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [La familia Azure SQL](#1--la-familia-azure-sql) ·
[DTU y vCore](#2--modelos-de-compra-dtu-y-vcore) · [Tiers](#3--tiers-de-servicio) ·
[Serverless](#4--serverless-y-la-oferta-gratuita) · [Alta disponibilidad](#5--alta-disponibilidad-dentro-de-la-región) ·
[Backups](#6--backups-pitr-y-retención-larga) · [Geo-replicación y failover groups](#7--active-geo-replication-y-failover-groups) ·
[Sin contraseñas](#8--autenticación-con-entra-id-y-tde) · [PostgreSQL](#9--postgresql-flexible-server) ·
[Caché](#10--caché-azure-managed-redis) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 La familia Azure SQL

"Azure SQL" es el nombre de una familia, no de un producto, y confundirlos es la primera
imprecisión de muchas respuestas:

| Producto | Qué es | Cuándo |
|---|---|---|
| **Azure SQL Database** | Una base (o un *elastic pool* de bases) totalmente administrada, en un *logical server* | Aplicaciones nuevas; el caso por defecto |
| **Azure SQL Managed Instance** | Una instancia de SQL Server casi completa, inyectada en tu VNet | Migrar desde SQL Server con dependencias de instancia (SQL Agent, bases cruzadas, CLR) |
| **SQL Server en VM** | SQL Server instalado en una VM que administras tú | Control total del motor o versiones que PaaS no ofrece |

El **logical server** de SQL Database no es una máquina: es un contenedor lógico con un nombre DNS
(`<servidor>.database.windows.net`), reglas de firewall, administradores y configuración de
autenticación. Las bases que cuelgan de él no comparten recursos de cómputo entre sí, salvo que las
metas en un **elastic pool**, que reparte un presupuesto de cómputo entre muchas bases de uso
irregular, el patrón típico de SaaS con una base por cliente.

---

## 2. 🧱 Modelos de compra: DTU y vCore

- **DTU**: un paquete que mezcla CPU, memoria e IO en una sola unidad, con tiers Basic, Standard y
  Premium. Sencillo, pero opaco: no eliges cuánta memoria quieres, eliges "más DTU".
- **vCore**: eliges núcleos, generación de hardware y tier de servicio por separado, y pagas cómputo
  y almacenamiento aparte. Permite **Azure Hybrid Benefit** (reutilizar licencias de SQL Server) y
  es el modelo en el que existen Hyperscale y serverless.

Para una entrevista, basta con la frase: *"vCore es el modelo recomendado porque separa cómputo y
almacenamiento, admite serverless e Hyperscale y se puede comparar con lo que corre on-premises"*.

---

## 3. 🧱 Tiers de servicio

En vCore hay tres tiers, y la diferencia es de arquitectura, no solo de tamaño:

| Tier | Arquitectura | Para qué |
|---|---|---|
| **General Purpose** | Cómputo separado del almacenamiento remoto | La mayoría de las cargas; el mejor precio |
| **Business Critical** | Varias réplicas con almacenamiento SSD local y una réplica legible incluida | Latencia baja de IO, OLTP exigente, lecturas en réplica sin costo extra |
| **Hyperscale** | Almacenamiento distribuido en *page servers*, hasta 128 TB, réplicas de lectura rápidas | Bases muy grandes o crecimiento impredecible; backups por snapshots casi instantáneos |

**Read scale-out** permite mandar consultas de solo lectura a una réplica, sin tocar la primaria,
con `ApplicationIntent=ReadOnly` en la cadena de conexión. Viene incluido en Business Critical, y en
Hyperscale se basa en sus réplicas de alta disponibilidad o nombradas.

---

## 4. 🧱 Serverless y la oferta gratuita

**Serverless** es un tier de cómputo de SQL Database (General Purpose e Hyperscale) que escala el
cómputo entre un mínimo y un máximo de vCores y **factura por segundo**. En General Purpose, además,
**se pausa sola** tras un período sin actividad —entre 15 minutos y 7 días, 60 minutos por defecto— y
durante la pausa solo cobra el almacenamiento.

Dos consecuencias que se preguntan:

- **la primera conexión tras una pausa tarda**: la base se reanuda al llegar un login, y el cliente
  ve errores transitorios mientras tanto. La aplicación necesita **lógica de reintento**, que es una
  buena práctica en cualquier caso;
- **serverless no significa gratis en reposo**: el almacenamiento sigue cobrando, y algunas
  funcionalidades impiden la pausa automática.

> Nunca respondas: "serverless no cuesta nada cuando no se usa". Mejor: "cuando está pausada cobra
> solo almacenamiento; y la reanudación añade latencia a la primera conexión".

La **oferta gratuita de Azure SQL Database** ofrece hasta 10 bases General Purpose serverless por
suscripción, cada una con 100.000 vCore-segundos, 32 GB de datos y 32 GB de backup al mes, de por
vida; con la opción "pausar hasta el mes siguiente", nunca genera cargo. Es la base del drill de
[`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales).

---

## 5. 🧱 Alta disponibilidad dentro de la región

**El problema:** se cae el nodo donde corre tu base. ¿Cuánto tarda en volver y pierdes datos?

Toda base de Azure SQL Database tiene **alta disponibilidad incluida** sin configurar nada: la
plataforma detecta el fallo y reubica el cómputo o promueve una réplica. Lo que eliges es si esa alta
disponibilidad **cruza zonas**:

- **sin redundancia de zona**, las réplicas o el cómputo de reserva pueden estar en la misma zona;
- **con zone redundancy**, las réplicas se reparten entre zonas y la base sobrevive a la caída de
  una zona entera, con conmutación automática y sin pérdida de datos confirmados.

```text
Regla mental:
Alta disponibilidad (en la región)  → incluida; con zone redundancy sobrevive a una zona
Recuperación ante desastres (otra región) → la configuras tú: geo-replication o failover group
Backup                               → te protege de ti mismo: un DELETE sin WHERE
```

---

## 6. 🧱 Backups, PITR y retención larga

Azure SQL Database hace backups automáticos que no puedes desactivar: **completos semanales,
diferenciales cada 12 o 24 horas y de log cada 10 minutos aproximadamente**. Con ellos ofrece tres
formas de restaurar:

| Mecanismo | Retención | Dónde restaura |
|---|---|---|
| **Point-in-time restore (PITR)** | 7 días por defecto; configurable de 1 a 35 | Una base nueva en el mismo servidor |
| **Geo-restore** | La misma, si los backups son geo-redundantes | Una base nueva en **cualquier región** |
| **Long-term retention (LTR)** | Hasta **10 años**, con políticas semanales, mensuales y anuales | Una base nueva, en cualquier región |

Cuatro matices que se preguntan:

- **una restauración nunca sobrescribe**: crea una base nueva con otro nombre, y luego renombras;
- **los backups son geo-redundantes por defecto**. Si los pasas a LRS o ZRS para cumplir residencia
  de datos, **pierdes el geo-restore**;
- **puedes restaurar una base borrada** dentro de su período de retención; pero si borras el
  **logical server**, pierdes todas sus bases y sus backups de PITR, salvo los de LTR;
- los backups de LTR admiten **inmutabilidad**, útil para retención regulatoria.

> Nunca respondas: "tengo una réplica, así que tengo backup". Mejor: "una réplica replica también el
> `DELETE` sin `WHERE`; para eso está el PITR, y para años, la LTR".

---

## 7. 🧱 Active geo-replication y failover groups

**El problema:** si cae la región entera, tu base tiene que volver en otra región en minutos, y tu
aplicación no debería tener que cambiar la cadena de conexión.

Dos mecanismos, uno encima del otro:

- **Active geo-replication**: crea **secundarias legibles** de una base en otras regiones, con
  replicación asíncrona. Cada secundaria tiene **su propio nombre de servidor**, así que tras un
  failover la aplicación tiene que apuntar a otro host.
- **Failover group**: una abstracción declarativa **sobre** geo-replication que agrupa varias bases
  de un servidor y les da dos **listeners** con nombre fijo:
  - `<fog>.database.windows.net` → siempre la primaria (lectura y escritura);
  - `<fog>.secondary.database.windows.net` → la secundaria (solo lectura).

  Tras un failover, Azure actualiza el DNS del listener y **la cadena de conexión no cambia**. El
  TTL de esos registros es de 30 segundos.

Los tipos de failover, que es lo que se pregunta:

- **failover planificado**: sincroniza completamente antes de cambiar de rol, **sin pérdida de
  datos**; exige que la primaria esté accesible. Es el de los simulacros de DR y el del *failback*;
- **failover forzado**: promueve la secundaria de inmediato, **con posible pérdida** de lo que no
  había replicado; es el de una caída real de la primaria.

La **política de failover** puede ser *customer managed* (tú decides cuándo) o *Microsoft managed*
(Azure la dispara solo ante una caída extensa de la región, tras un período de gracia de al menos una
hora, y para todos los failover groups de la región con esa política). Microsoft **recomienda la
primera** y advierte que no se confíe en la segunda.

| Criterio | Read replica (read scale-out) | Active geo-replication | Failover group | Backup |
|---|---|---|---|---|
| Región | La misma | Otra | Otra | Cualquiera (geo-restore) |
| Para qué | Descargar lecturas | DR por base | DR de un grupo, sin cambiar la conexión | Recuperarse de errores lógicos |
| Endpoint tras failover | — | Cambia | No cambia (listener) | Base nueva |
| Protege de un `DELETE` accidental | ❌ | ❌ | ❌ | ✅ |

La cadena de conexión JDBC de una aplicación Spring Boot contra el listener, sin contraseña:

```text
jdbc:sqlserver://inv-fog.database.windows.net:1433;database=inv;encrypt=true;authentication=ActiveDirectoryManagedIdentity
```

- `inv-fog.database.windows.net` es el **listener de lectura y escritura** del failover group, no un
  servidor concreto: tras un failover apunta a la nueva primaria sin tocar la configuración.
- `encrypt=true` exige TLS; Azure SQL rechaza conexiones sin cifrar.
- `authentication=ActiveDirectoryManagedIdentity` le indica al driver JDBC de Microsoft que obtenga
  un token de Entra ID con la managed identity del host en vez de enviar usuario y contraseña (§8).
  Con una user-assigned identity se añade su client ID.

---

## 8. 🧱 Autenticación con Entra ID y TDE

**Autenticación con Entra ID**: el servidor tiene un administrador de Entra ID, y las aplicaciones se
autentican con un token de su managed identity. En la base se crea un usuario para esa identidad y se
le dan permisos de SQL:

```sql
CREATE USER [inv-api-id] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [inv-api-id];
ALTER ROLE db_datawriter ADD MEMBER [inv-api-id];
```

- `CREATE USER … FROM EXTERNAL PROVIDER` crea en la base un usuario ligado a una identidad de Entra ID
  por su nombre; no hay contraseña que guardar ni rotar.
- los `ALTER ROLE` le dan lectura y escritura con los roles fijos de base de datos. Es autorización
  **dentro del motor**, independiente de Azure RBAC: el rol `Contributor` sobre el servidor no da
  acceso a los datos.

Se puede ir más lejos y **deshabilitar la autenticación SQL** (solo Entra ID), que elimina de raíz
las contraseñas de base de datos.

**TDE** (*transparent data encryption*) cifra en reposo los datos, los logs y los backups, y está
activado por defecto en las bases nuevas. La clave puede ser administrada por el servicio o una
**customer-managed key** en Key Vault ([`11`](11-secretos-cifrado-y-key-vault.md)).

---

## 9. 🧱 PostgreSQL Flexible Server

**Azure Database for PostgreSQL – Flexible Server** es PostgreSQL de la comunidad administrado.
Tiene su propio vocabulario de disponibilidad:

- **alta disponibilidad con standby**: una réplica standby con **replicación síncrona**, en la misma
  zona o, mejor, en **otra zona** (*zone-redundant*), con failover automático y sin pérdida de datos
  confirmados. El standby **no es legible**: existe para conmutar, no para descargar lecturas;
- **read replicas**: réplicas **asíncronas** y **legibles**, en la misma región o en otras, para
  escalar lecturas o como pieza de DR; se promueven manualmente y pueden ir por detrás;
- **PgBouncer integrado**: un pool de conexiones incorporado al servidor, relevante porque las
  aplicaciones Java con muchos pods agotan rápido las conexiones de PostgreSQL;
- **backups automáticos** con PITR, y autenticación con **Entra ID**;
- **tiers**: Burstable (desarrollo y cargas pequeñas), General Purpose y Memory Optimized.

```text
Standby de HA   → síncrono, no legible, failover automático: disponibilidad
Read replica    → asíncrona, legible, promoción manual: escala de lectura y DR
```

**MySQL Flexible Server** comparte ese modelo; basta con saber que existe.

> 💰 **Costo.** El tier Burstable más pequeño (B1ms) cuesta **$0.017/h** en `eastus2`, más el
> almacenamiento, que **sigue cobrando con el servidor detenido**. Por eso PostgreSQL se practica en
> contenedor ([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)).

---

## 10. 🧱 Caché: Azure Managed Redis

**El problema:** cada petición de tu API consulta el catálogo de productos, que cambia una vez al
día, y la base sufre por ello.

La respuesta es una caché, y en Azure el producto es **Azure Managed Redis**:

> 📝 **Contexto.** **Azure Cache for Redis** está en retiro: sus tiers **Basic, Standard y Premium
> se retiran el 30 de septiembre de 2028** y los **Enterprise y Enterprise Flash el 31 de marzo de
> 2027**; a partir de esas fechas las instancias se deshabilitan. El sustituto es **Azure Managed
> Redis**, basado en Redis Enterprise: zone-redundant por defecto, **clusterizado por defecto** y
> pensado para autenticarse con Entra ID. Mucho material aún responde "Azure Cache for Redis".

La consecuencia práctica de "clusterizado por defecto": el cliente (Lettuce o Jedis en Java) tiene
que estar configurado para Redis en modo cluster, y los comandos que tocan varias claves en slots
distintos fallan.

Los patrones que se preguntan:

- **cache-aside**: la aplicación lee de la caché; si no está, lee de la base y la guarda con un TTL.
  Es el patrón por defecto, y el TTL es lo que acota cuánto tiempo sirves datos viejos;
- **write-through**: la aplicación escribe en la caché y en la base a la vez, con más complejidad y
  menos datos viejos;
- **sesiones y rate limiting**: estado efímero compartido entre instancias.

> 💰 **Costo.** El tier más pequeño (Balanced B0) cuesta **$0.016/h** en `eastus2`. El laboratorio
> usa Redis en contenedor, que enseña lo mismo sin cobrar.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Una read replica es un backup" | Replica también el `DELETE`; el backup es el PITR |
| "Geo-replication no cambia la conexión" | Cada secundaria tiene su servidor; el listener fijo lo da el failover group |
| "Serverless no cuesta nada cuando no se usa" | Pausada cobra almacenamiento; y la reanudación añade latencia |
| "Paso los backups a LRS y listo" | Pierdes el geo-restore |
| "Microsoft hará el failover a otra región" | Solo con política Microsoft managed, tras una hora como mínimo y para toda la región; se recomienda customer managed |
| "El standby de PostgreSQL sirve lecturas" | No es legible; para lecturas, read replicas |
| "Azure Cache for Redis es la caché de Azure" | Se retira en 2027-2028; el sustituto es Azure Managed Redis |
| "Contributor en el servidor lee los datos" | El acceso a datos se concede dentro del motor |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a Azure SQL Database de SQL Managed Instance y cuándo elegirías la segunda?
2. ¿Qué es un logical server de Azure SQL Database y qué comparten las bases que cuelgan de él?
3. ¿Por qué vCore es el modelo de compra recomendado frente a DTU?
4. ¿Qué cobra una base serverless cuando está pausada y qué efecto tiene la pausa en la aplicación?
5. ¿Qué te da la alta disponibilidad incluida de Azure SQL Database y qué añade la zone redundancy?
6. ¿Cuánto tiempo puedes volver atrás con PITR por defecto y hasta cuánto con retención larga?
7. Cambiaste la redundancia de los backups a LRS por residencia de datos. ¿Qué perdiste?
8. ¿Qué te da un failover group que no te da active geo-replication por sí sola?
9. ¿Qué diferencia hay entre un failover planificado y uno forzado en un failover group?
10. ¿Qué política de failover recomienda Microsoft y por qué no conviene confiar en la otra?
11. ¿Cómo se conecta una aplicación Spring Boot a Azure SQL sin guardar una contraseña?
12. En PostgreSQL Flexible Server, ¿qué diferencia hay entre el standby de alta disponibilidad y una read replica?
13. ¿Qué está pasando con Azure Cache for Redis y qué implica para el cliente Java migrar a Azure Managed Redis?
14. Un desarrollador ejecutó un `DELETE` sin `WHERE` en producción hace una hora. Tienes un failover group con una secundaria en otra región. ¿Te sirve para recuperar los datos? ¿Qué usas?

---

## 📚 Referencias oficiales

- ¿Qué es Azure SQL?: https://learn.microsoft.com/en-us/azure/azure-sql/azure-sql-iaas-vs-paas-what-is-overview
- ¿Qué es Azure SQL Database?: https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-database-paas-overview
- Logical servers: https://learn.microsoft.com/en-us/azure/azure-sql/database/logical-servers
- Elastic pools: https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-overview
- Modelos de compra DTU y vCore: https://learn.microsoft.com/en-us/azure/azure-sql/database/purchasing-models
- Tiers de servicio en vCore: https://learn.microsoft.com/en-us/azure/azure-sql/database/service-tiers-sql-database-vcore
- Hyperscale: https://learn.microsoft.com/en-us/azure/azure-sql/database/service-tier-hyperscale
- Read scale-out: https://learn.microsoft.com/en-us/azure/azure-sql/database/read-scale-out
- Tier serverless: https://learn.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview
- Oferta gratuita de Azure SQL Database: https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer
- Alta disponibilidad y zone redundancy: https://learn.microsoft.com/en-us/azure/azure-sql/database/high-availability-sla-local-zone-redundancy
- Backups automáticos: https://learn.microsoft.com/en-us/azure/azure-sql/database/automated-backups-overview
- Retención larga (LTR): https://learn.microsoft.com/en-us/azure/azure-sql/database/long-term-retention-overview
- Active geo-replication: https://learn.microsoft.com/en-us/azure/azure-sql/database/active-geo-replication-overview
- Failover groups: https://learn.microsoft.com/en-us/azure/azure-sql/database/failover-group-sql-db
- Autenticación con Entra ID en Azure SQL: https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-overview
- Conectar con Entra ID desde el driver JDBC: https://learn.microsoft.com/en-us/sql/connect/jdbc/connecting-using-azure-active-directory-authentication
- TDE en Azure SQL: https://learn.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-tde-overview
- PostgreSQL Flexible Server: https://learn.microsoft.com/en-us/azure/postgresql/overview
- Alta disponibilidad en PostgreSQL Flexible Server: https://learn.microsoft.com/en-us/azure/postgresql/high-availability/concepts-high-availability
- Read replicas en PostgreSQL Flexible Server: https://learn.microsoft.com/en-us/azure/postgresql/read-replica/concepts-read-replicas
- PgBouncer en PostgreSQL Flexible Server: https://learn.microsoft.com/en-us/azure/postgresql/connectivity/concepts-pgbouncer
- ¿Qué es Azure Managed Redis?: https://learn.microsoft.com/en-us/azure/redis/overview
- Retiro de Azure Cache for Redis: https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/retirement-faq
- Patrón cache-aside: https://learn.microsoft.com/en-us/azure/architecture/patterns/cache-aside
- Precios de Azure SQL Database: https://azure.microsoft.com/en-us/pricing/details/azure-sql-database/single/
- Precios de PostgreSQL Flexible Server: https://azure.microsoft.com/en-us/pricing/details/postgresql/flexible-server/
- Precios de Azure Managed Redis: https://azure.microsoft.com/en-us/pricing/details/managed-redis/
