# 06 — Almacenamiento: storage accounts

> **Objetivo:** elegir redundancia, tier y modelo de acceso de una storage account, y proteger sus
> datos contra borrados, sobrescrituras y accesos que no debían existir.
> **Se asume leído:** [`01`](01-infraestructura-global-y-resource-manager.md) (zonas, parejas y data
> plane) y [`03`](03-conectividad-privada-y-dns.md) (private endpoints).
> **Se toca más con:** [`03`](03-conectividad-privada-y-dns.md), para el acceso privado, y el
> [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (autorización), que define los roles de datos con los que se entra sin claves.
> **Se practica en:** [`L02`](l02-entra-id-rbac-y-managed-identities.md) (roles de datos y `--allow-shared-key-access false`) y [`L03`](l03-bicep-desde-la-cli.md) (la cuenta
> declarada en Bicep). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [La storage account](#1--la-storage-account-cuatro-servicios-un-contenedor) ·
[Blobs](#2--blobs) · [Redundancia](#3--redundancia) · [Failover](#4--failover-de-la-cuenta) ·
[Access tiers](#5--access-tiers-y-lifecycle) · [Protección de datos](#6--protección-de-datos) ·
[Inmutabilidad](#7--inmutabilidad-worm) · [Acceso](#8--acceso-claves-sas-y-entra-id) ·
[Azure Files](#9--azure-files) · [Managed disks](#10--managed-disks) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 La storage account: cuatro servicios, un contenedor

Una **storage account** es el recurso de Azure que agrupa cuatro servicios de datos bajo un mismo
nombre, una misma redundancia y una misma configuración de red y de acceso:

| Servicio | Qué guarda | Endpoint |
|---|---|---|
| **Blob** | Objetos: documentos, imágenes, backups, logs | `<cuenta>.blob.core.windows.net` |
| **Files** | Recursos compartidos SMB y NFS | `<cuenta>.file.core.windows.net` |
| **Queue** | Mensajes simples, hasta 64 KiB cada uno | `<cuenta>.queue.core.windows.net` |
| **Table** | Pares clave-valor NoSQL sencillos | `<cuenta>.table.core.windows.net` |

Tres consecuencias de que todo cuelgue de la cuenta:

- **la redundancia es una propiedad de la cuenta, no del servicio**: si tus backups necesitan GRS y
  tus logs temporales LRS, van en cuentas distintas;
- **el nombre es único en todo Azure** y forma parte del hostname: de 3 a 24 minúsculas y dígitos,
  sin guiones (guía de estilo §5);
- **el tipo recomendado es Standard general-purpose v2** (`StorageV2`), que admite todos los servicios
  y todas las redundancias. Las cuentas Premium (block blobs o file shares en SSD) existen para
  latencias muy bajas y solo admiten LRS y ZRS.

---

## 2. 🧱 Blobs

Un blob vive en un **contenedor** dentro de la cuenta (`inv/2026/09/factura-001.pdf` es un nombre de
blob; las "carpetas" son prefijos del nombre, salvo que actives el namespace jerárquico). Hay tres
tipos:

- **block blob**: el caso general, cualquier archivo que se sube y se lee entero;
- **append blob**: optimizado para añadir al final, como un log;
- **page blob**: páginas de 512 bytes con escritura aleatoria; es lo que hay debajo de un disco de VM.

**Data Lake Storage** no es otro servicio: es una storage account con el **namespace jerárquico**
activado, que convierte los prefijos en directorios reales con operaciones atómicas de renombrado y
ACLs por directorio, pensada para analítica. Se nombra; el curso no la desarrolla.

---

## 3. 🧱 Redundancia

**El problema:** tus documentos de clientes tienen que sobrevivir a un incendio en un datacenter, y
quizá a la pérdida de una región entera. ¿Cuánto pagas por cada nivel de "sobrevivir"?

Azure Storage siempre guarda varias copias. La redundancia decide **dónde**:

```text
LRS    3 copias en UN datacenter                          11 nueves de durabilidad
ZRS    copias síncronas en 3 o más ZONAS de la región     12 nueves
GRS    LRS en la primaria + copia ASÍNCRONA a la pareja   16 nueves
GZRS   ZRS en la primaria + copia ASÍNCRONA a la pareja   16 nueves
RA-    (sobre GRS o GZRS) la secundaria se puede LEER siempre
```

Lo que cada una protege, que es lo que se pregunta de verdad:

| Escenario | LRS | ZRS | GRS / RA-GRS | GZRS / RA-GZRS |
|---|---|---|---|---|
| Falla un disco o un nodo | ✅ | ✅ | ✅ | ✅ |
| Cae un datacenter o una zona | ❌ | ✅ | ✅ tras failover | ✅ |
| Cae la región entera | ❌ | ❌ | ✅ tras failover | ✅ tras failover |
| Leer mientras la primaria está caída | ❌ | ❌ | ✅ solo RA-GRS | ✅ solo RA-GZRS |

Cuatro matices que separan una respuesta de manual de una de quien lo ha diseñado:

- **GRS no te deja leer la secundaria.** La copia existe, pero solo es accesible tras un failover.
  Para leerla siempre, con el endpoint `<cuenta>-secondary.blob.core.windows.net`, hace falta **RA-**GRS
  o **RA-**GZRS.
- **La replicación geográfica es asíncrona**, así que un desastre en la primaria puede perder las
  últimas escrituras. Para block blobs existe *geo priority replication*, que garantiza un RPO de 15
  minutos o menos.
- **La secundaria es la región pareja** ([`01` §4](01-infraestructura-global-y-resource-manager.md#4--region-pairs-y-regiones-sin-pareja)) y no se elige. Por eso GZRS solo existe en
  regiones con zonas **y** con pareja.
- **La redundancia no protege de un borrado.** Todas las réplicas reflejan el mismo estado: si borras
  o sobrescribes un blob, se borra en las tres, seis o doce copias. Eso lo cubre §6, no esta sección.

> Nunca respondas: "GRS me da lectura en la región secundaria". Mejor: "GRS replica a la secundaria de
> forma asíncrona; para leerla sin failover necesito RA-GRS, y para sobrevivir además a la caída de
> una zona sin failover, GZRS".

Microsoft recomienda ZRS en la primaria para alta disponibilidad, más replicación geográfica si hay
que sobrevivir a la pérdida de la región: es decir, **GZRS**, o **RA-GZRS** si además se quiere leer
durante la caída.

---

## 4. 🧱 Failover de la cuenta

Con GRS o GZRS, si la primaria cae puedes forzar un **failover administrado por el cliente**: Azure
actualiza el DNS para que los endpoints de la cuenta apunten a la secundaria, que pasa a ser la
primaria. Tres cosas que hay que decir en una entrevista:

- durante el failover **los datos no están accesibles**;
- un failover no planificado **puede perder datos**: lo escrito en la primaria después del último
  *last sync time* no llegó a la secundaria;
- tras el failover la cuenta queda **sin replicación geográfica** hasta que la reconfiguras, porque la
  nueva primaria no tiene a quién replicar.

Microsoft solo hace un failover por su cuenta en situaciones catastróficas, tras intentos fallidos de
recuperación: no es un plan de DR en el que apoyarse ([`01` §4](01-infraestructura-global-y-resource-manager.md#4--region-pairs-y-regiones-sin-pareja)).

---

## 5. 🧱 Access tiers y lifecycle

**El problema:** guardas siete años de facturas por regulación; casi nadie las lee después del
primer mes, y pagarlas al precio del almacenamiento caliente es tirar dinero.

Los block blobs tienen **tiers de acceso** que intercambian precio de almacenamiento por precio de
lectura y latencia:

| Tier | Uso | Retención mínima | Primer byte |
|---|---|---|---|
| **Hot** | Datos en uso activo | — | Milisegundos |
| **Cool** | Acceso infrecuente | 30 días | Milisegundos |
| **Cold** | Acceso raro, lectura inmediata | 90 días | Milisegundos |
| **Archive** | Casi nunca se lee | 180 días | **Horas** |

Lo que se pregunta:

- **la retención mínima es un cargo, no una prohibición**: borrar, sobrescribir o cambiar de tier un
  blob antes de tiempo cobra los días que faltaban (*early deletion*), prorrateado;
- **archive es offline**: un blob archivado no se puede leer ni modificar; hay que **rehidratarlo** a
  un tier online, lo que puede tardar hasta 15 horas según la prioridad elegida;
- **archive no existe con ZRS, GZRS ni RA-GZRS**, solo con LRS, GRS y RA-GRS;
- el tier por defecto de la cuenta es **hot**, y archive no puede serlo.

Las **lifecycle management policies** automatizan el movimiento: "mueve a cool a los 30 días sin
modificar, a archive a los 180, borra a los 2.555". Con una limitación: una policy de lifecycle
**no puede rehidratar** desde archive.

---

## 6. 🧱 Protección de datos

La redundancia protege del hardware; esto protege de las personas y del código.

- **Soft delete de blobs y de contenedores**: lo borrado queda recuperable durante el período de
  retención que configures. Un blob en soft delete no paga *early deletion* hasta que expira la
  retención.
- **Versioning**: cada sobrescritura guarda la versión anterior automáticamente. Protege de la
  sobrescritura accidental, que el soft delete no cubre, y cuesta el almacenamiento de las versiones.
- **Point-in-time restore**: devuelve un conjunto de blobs al estado de un momento anterior. Necesita
  versioning, change feed y soft delete activos.
- **Snapshots**: copias de solo lectura de un blob en un instante, manuales.
- **Resource lock** en la cuenta ([`10`](10-autorizacion-rbac-policy-y-gobierno.md)): impide borrar la **cuenta** por el control plane,
  pero no los blobs por el data plane ([`01` §10](01-infraestructura-global-y-resource-manager.md#10--control-plane-y-data-plane)).

> Nunca respondas: "tengo soft delete, así que tengo backup". Mejor: "soft delete me protege de un
> borrado dentro del período de retención; para sobrescrituras necesito versioning, y para un
> ransomware con permisos de borrado, inmutabilidad o un backup en otra cuenta".

---

## 7. 🧱 Inmutabilidad (WORM)

**El problema:** la regulación exige que los registros de operaciones no puedan ser alterados ni
borrados durante años, ni siquiera por un administrador.

La **inmutabilidad** de Blob Storage guarda datos en estado **WORM** (*write once, read many*): se
pueden crear y leer, no modificar ni borrar. Dos tipos de política, combinables:

- **retención por tiempo**: los datos son inmutables durante un intervalo (de 1 día a 400 años).
  Empieza **desbloqueada**, para probar; una vez **bloqueada** no se puede borrar ni acortar, solo
  extender. Solo la política bloqueada da el estado de cumplimiento;
- **legal hold**: inmutable hasta que alguien retire explícitamente el hold, para investigaciones o
  litigios cuyo plazo no se conoce.

Se aplican **a nivel de contenedor** o, con versioning activo, **a nivel de versión** (y heredadas
desde la cuenta o el contenedor). Microsoft encargó una evaluación independiente que valida su uso
para **SEC 17a-4(f), FINRA 4511 y CFTC 1.31(c)-(d)**: en una entrevista de banca, es la respuesta a
"¿cómo garantizas que un registro no se altera?".

---

## 8. 🧱 Acceso: claves, SAS y Entra ID

**El problema:** tu aplicación, un proceso nocturno y un cliente externo necesitan acceder a blobs,
cada uno con permisos distintos. ¿Con qué credencial entra cada uno?

Hay tres formas de autorizar el data plane de una storage account, de peor a mejor:

- **Access keys (Shared Key)**: dos claves por cuenta, cada una con **control total sobre todos los
  datos**, sin identidad ni auditoría por usuario. Quien tiene la clave es el dueño de los datos.
- **SAS (shared access signature)**: un token que se añade a la URL y concede permisos acotados
  (qué recursos, qué operaciones, hasta cuándo, desde qué IPs). Tres tipos:
  - **user delegation SAS**: firmada con una clave de delegación que se obtiene **con credenciales de
    Entra ID**; es la que Microsoft recomienda;
  - **service SAS**: firmada con la access key, para un servicio;
  - **account SAS**: firmada con la access key, para uno o varios servicios.
- **Entra ID con roles de datos**: la aplicación obtiene un token con su managed identity y RBAC
  decide qué puede hacer —`Storage Blob Data Reader`, `Storage Blob Data Contributor`—. Es lo que usa
  el laboratorio ([`10`](10-autorizacion-rbac-policy-y-gobierno.md)).

El punto débil de las SAS firmadas con clave es la revocación: **Azure Storage no registra las SAS
que se emiten**, así que no se puede revocar "esa SAS". Las salidas son rotar la access key que la
firmó (lo que invalida todas las SAS firmadas con ella), usar una *stored access policy* en el
contenedor para las service SAS, o, con user delegation SAS, revocar las claves de delegación o
retirar el rol de quien la generó.

La configuración que cierra la puerta a las claves:

```bash
az storage account update \
  --name invlab472913 \
  --resource-group inv-lab-rg \
  --allow-shared-key-access false \
  --min-tls-version TLS1_2
```

- `--allow-shared-key-access false` rechaza toda petición autorizada con Shared Key, **incluidas las
  service SAS y account SAS**, porque se firman con la clave. Solo quedan Entra ID y las user
  delegation SAS. El efecto secundario: herramientas que asumían la clave (algunas versiones de
  Terraform, scripts viejos) fallan con `KeyBasedAuthenticationNotPermitted`, y los comandos de datos
  de `az` necesitan `--auth-mode login`.
- `--min-tls-version TLS1_2` rechaza clientes con TLS anterior a 1.2. Es la línea base de cualquier
  auditoría de seguridad.

> ⚠️ **"Owner de la suscripción" no significa "puede leer los blobs".** Con la clave deshabilitada, el
> Owner solo puede leer datos si se asigna un rol de datos: `Owner` y `Contributor` son roles de
> control plane. Es la pregunta favorita de las entrevistas sobre Azure RBAC, y [`L02`](l02-entra-id-rbac-y-managed-identities.md) la reproduce.

---

## 9. 🧱 Azure Files

**Azure Files** ofrece recursos compartidos de archivos administrados por **SMB** (Windows, Linux,
macOS) y **NFS** (Linux), montables desde VMs, contenedores y equipos on-premises. Resuelve el caso
"la aplicación legacy espera una carpeta compartida" sin montar un servidor de archivos.

- tiers estándar (HDD) y premium (SSD, solo LRS y ZRS);
- con ZRS, si cae una zona los clientes no necesitan volver a montar el recurso;
- **no admite RA-GRS ni RA-GZRS**;
- Azure File Sync lo convierte en caché de servidores de archivos on-premises.

```text
Blob Storage   → objetos por HTTP; la aplicación usa el SDK o la API REST
Azure Files    → un sistema de archivos compartido; la aplicación usa rutas y montaje
Managed Disks  → un disco de bloque para UNA VM (o compartido en casos concretos)
```

---

## 10. 🧱 Managed disks

Los discos de las VMs son **managed disks**: Azure gestiona la cuenta de almacenamiento que hay
debajo. Tipos, de menor a mayor rendimiento:

- **Standard HDD**: pruebas y cargas poco exigentes;
- **Standard SSD**: servidores web y cargas ligeras de producción;
- **Premium SSD**: producción con IOPS sostenidas; el tamaño determina el rendimiento;
- **Premium SSD v2**: IOPS y throughput configurables independientemente del tamaño;
- **Ultra Disk**: latencia de submilisegundo para bases de datos exigentes.

Redundancia: LRS (en una zona) o **ZRS** (replicado entre zonas, con limitaciones por tipo). Dos
hechos de costo que se olvidan:

- **un disco factura por tamaño aprovisionado, esté la VM encendida, desasignada o borrada**, hasta
  que borras el disco;
- borrar una VM **no borra necesariamente su disco** ni sus snapshots: son el huérfano clásico que
  cataloga [`A02`](a02-costos-trampas-y-recursos-huerfanos.md).

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "GRS me deja leer la secundaria" | Solo RA-GRS o RA-GZRS; con GRS la secundaria solo es accesible tras un failover |
| "La redundancia protege de un borrado" | Todas las copias reflejan el borrado; eso lo cubren soft delete, versioning e inmutabilidad |
| "Soft delete es un backup" | Protege del borrado durante la retención, no de la sobrescritura ni de un atacante con permisos |
| "Una SAS se revoca borrándola" | No existe como objeto; se rota la clave, se usa una stored access policy o se revoca la clave de delegación |
| "Archive es un tier barato como los demás" | Es offline: leer exige rehidratar, hasta 15 horas |
| "El Owner puede leer cualquier blob" | Owner es de control plane; leer datos exige un rol de datos |
| "Mover a cool ahorra siempre" | Cambiar o borrar antes de 30 días paga early deletion |
| "Borré la VM, ya no pago el disco" | El disco y sus snapshots siguen hasta que se borran |

---

## 🧠 Preguntas rápidas

1. ¿Por qué la redundancia es una decisión de la storage account y no de cada servicio, y qué implica para el diseño?
2. ¿Qué diferencia a LRS, ZRS, GRS y GZRS en dónde viven las copias y en si son síncronas?
3. Con una cuenta GRS, ¿puedes leer la región secundaria mientras la primaria funciona?
4. ¿Qué redundancia elegirías para documentos que deben seguir disponibles si cae una zona y sobrevivir a la pérdida de la región, y cuál si además deben poder leerse durante la caída?
5. ¿Qué tres cosas pasan en un failover de cuenta no planificado?
6. Un blob en cool se borra a los 21 días. ¿Qué se cobra?
7. ¿Por qué no puedes leer inmediatamente un blob en archive, y con qué redundancias no está disponible ese tier?
8. ¿Qué te protege de una sobrescritura accidental que el soft delete no cubre?
9. ¿Cómo garantizas que un registro regulatorio no pueda ser alterado ni borrado ni por un administrador durante siete años?
10. ¿Qué tipo de SAS recomienda Microsoft y por qué es mejor que una service SAS?
11. Una SAS firmada con la access key se filtró. ¿Cómo la invalidas?
12. ¿Qué efecto tiene `--allow-shared-key-access false` sobre las service SAS y account SAS?
13. El Owner de la suscripción intenta leer un blob de una cuenta con Shared Key deshabilitado y recibe un error. ¿Por qué?
14. ¿Cuándo usarías Azure Files en lugar de Blob Storage?

---

## 📚 Referencias oficiales

- Introducción a las storage accounts: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview
- Redundancia de Azure Storage: https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy
- Recuperación ante desastres y failover de la cuenta: https://learn.microsoft.com/en-us/azure/storage/common/storage-disaster-recovery-guidance
- Geo priority replication: https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy-priority-replication
- Access tiers de blobs: https://learn.microsoft.com/en-us/azure/storage/blobs/access-tiers-overview
- Rehidratación desde archive: https://learn.microsoft.com/en-us/azure/storage/blobs/archive-rehydrate-overview
- Lifecycle management: https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-overview
- Protección de datos de blobs: https://learn.microsoft.com/en-us/azure/storage/blobs/data-protection-overview
- Soft delete de blobs: https://learn.microsoft.com/en-us/azure/storage/blobs/soft-delete-blob-overview
- Versioning de blobs: https://learn.microsoft.com/en-us/azure/storage/blobs/versioning-overview
- Point-in-time restore: https://learn.microsoft.com/en-us/azure/storage/blobs/point-in-time-restore-overview
- Almacenamiento inmutable (WORM): https://learn.microsoft.com/en-us/azure/storage/blobs/immutable-storage-overview
- Shared access signatures: https://learn.microsoft.com/en-us/azure/storage/common/storage-sas-overview
- Crear una user delegation SAS: https://learn.microsoft.com/en-us/rest/api/storageservices/create-user-delegation-sas
- Impedir la autorización con Shared Key: https://learn.microsoft.com/en-us/azure/storage/common/shared-key-authorization-prevent
- Autorizar el acceso a datos con Entra ID: https://learn.microsoft.com/en-us/azure/storage/blobs/authorize-access-azure-active-directory
- ¿Qué es Azure Files?: https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction
- Tipos de managed disks: https://learn.microsoft.com/en-us/azure/virtual-machines/disks-types
- Redundancia de managed disks: https://learn.microsoft.com/en-us/azure/virtual-machines/disks-redundancy
- Namespace jerárquico de Data Lake Storage: https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-namespace
- Precios de Blob Storage: https://azure.microsoft.com/en-us/pricing/details/storage/blobs/
- `az storage account`: https://learn.microsoft.com/en-us/cli/azure/storage/account
