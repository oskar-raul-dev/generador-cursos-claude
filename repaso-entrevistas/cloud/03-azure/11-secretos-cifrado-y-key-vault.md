# 11 — Secretos, cifrado y Key Vault

> **Objetivo:** saber dónde vive lo que no puede vivir en el código —secretos, claves y certificados—,
> cómo se protege contra el borrado y el acceso indebido, cómo lo consume una aplicación Spring Boot y
> qué significa "cifrado con claves del cliente" en Azure.
> **Se asume leído:** [`09`](09-identidad-entra-id-y-managed-identities.md) (managed identities) y
> [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (roles de datos y control plane frente a data
> plane).
> **Se toca más con:** [`06`](06-almacenamiento-storage-accounts.md) y
> [`07`](07-bases-relacionales-y-cache.md), cuyos datos cifra una customer-managed key, y el [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md)
> (identidad de aplicaciones), que explica por qué la mejor credencial es la que no existe.
> **Se practica en:** [`L02`](l02-entra-id-rbac-y-managed-identities.md) (un vault con Azure RBAC y el rol de lectura para la managed identity),
> [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) (el secreto leído por la managed identity como Key Vault reference) y
> [`L09`](l09-costos-y-destruccion-verificada.md) (soft-delete y purge en el teardown). Ver
> [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [El problema](#1--el-problema-la-mejor-credencial-es-la-que-no-existe) ·
[Key Vault](#2--key-vault-secretos-claves-y-certificados) · [Autorización](#3--autorización-azure-rbac-frente-a-access-policies) ·
[Crear el vault](#4--crear-el-vault-del-laboratorio) · [Soft-delete y purge protection](#5--soft-delete-y-purge-protection) ·
[Red](#6--red-firewall-y-private-endpoint) · [Consumo desde la app](#7--consumir-secretos-desde-la-aplicación) ·
[Rotación](#8--rotación-y-expiración) · [Cifrado en reposo](#9--cifrado-en-reposo-y-customer-managed-keys) ·
[App Configuration](#10--app-configuration) · [Defender for Cloud](#11--defender-for-cloud-y-sentinel) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: la mejor credencial es la que no existe

Antes de hablar de Key Vault conviene fijar el orden de preferencia, porque es lo que distingue una
respuesta de arquitecto:

```text
1. No tener secreto:  managed identity + rol de datos (capítulos 09 y 10)
2. Si el secreto es inevitable (API de un tercero, una contraseña heredada):
   guardarlo en Key Vault, leerlo con la managed identity, rotarlo
3. Nunca: en el código, en el repositorio, en una variable de entorno escrita a mano en el pipeline
```

Key Vault no elimina el secreto: lo **centraliza**, lo audita y controla quién lo lee. Sigue siendo
algo que caduca, que hay que rotar y que un proceso comprometido puede leer. Por eso el hilo del curso
es que `inv-api` llegue a Cosmos DB, Service Bus y Storage **sin ningún secreto**, y que Key Vault quede
para lo que no admite Entra ID.

> Nunca respondas: "guardamos las credenciales en Key Vault, así que estamos seguros". Mejor:
> "primero eliminamos las credenciales que se pueden eliminar con managed identities; las que quedan,
> como la API key de un tercero, viven en Key Vault, se leen con la managed identity y tienen fecha de
> expiración y rotación".

---

## 2. 🧱 Key Vault: secretos, claves y certificados

Un **Key Vault** guarda tres tipos de objeto, todos versionados:

- **secretos**: cualquier valor opaco, como una contraseña, una API key o una connection string. Key
  Vault lo guarda y lo devuelve;
- **claves**: claves criptográficas RSA o EC que **no salen del vault**; la aplicación le pide a Key
  Vault que firme, cifre o envuelva (*wrap*) con ellas. Es lo que usan las customer-managed keys (§9);
- **certificados**: un certificado X.509 con su clave privada, con renovación automática si lo emite
  una CA integrada.

Dos tiers y un servicio aparte:

| Opción | Qué da | Cuándo |
|---|---|---|
| **Standard** | Claves protegidas por software (módulos FIPS 140 Level 1) | Secretos y claves de aplicación |
| **Premium** | Además, claves **HSM-protected**, en HSM con validación FIPS 140-3 Level 3 | Requisito regulatorio de HSM, CMK en banca |
| **Managed HSM** | Un pool de HSM **single-tenant** dedicado, con su propio modelo de roles | Control exclusivo del HSM; cumplimiento estricto |

El precio de un vault es por operación, no por existir.

> 💰 **Costo.** En `eastus2`, las operaciones de secretos y claves de software cuestan **$0.03 por
> cada 10.000** en Standard y en Premium; una clave RSA 2048 HSM-protected en Premium, **$1 por
> clave y mes**. Un vault con un par de secretos leídos al arrancar cuesta fracciones de centavo. El
> Managed HSM, en cambio, cobra por hora: **$3.20/h** el pool Standard B1, unos $2.300 al mes; nunca
> se crea en un laboratorio.

---

## 3. 🧱 Autorización: Azure RBAC frente a access policies

Key Vault tiene **dos modelos de autorización para el data plane**, y elegir mal es una vulnerabilidad:

- **Azure RBAC** (recomendado): los permisos sobre secretos, claves y certificados son role assignments
  como los del [`10`](10-autorizacion-rbac-policy-y-gobierno.md), con roles de datos como `Key Vault Secrets User` (leer secretos),
  `Key Vault Secrets Officer` (gestionarlos), `Key Vault Crypto User` o `Key Vault Administrator`. Se
  pueden asignar sobre el vault o sobre **un secreto concreto**;
- **access policies** (legado): permisos propios de Key Vault, definidos en una propiedad del vault.

La razón de fondo para preferir RBAC es una escalada de privilegios:

> ⚠️ **Con access policies, cualquiera con `Contributor` o `Key Vault Contributor` sobre el vault puede
> darse acceso a todos sus secretos**, porque las access policies son una propiedad del recurso y
> modificarla es una acción de control plane (`Microsoft.KeyVault/vaults/write`). Con Azure RBAC, dar
> acceso a los datos exige `Owner` o `User Access Administrator`, y queda integrado con PIM y con las
> conditions.

Desde la versión de API `2026-02-01`, **Azure RBAC es el modelo por defecto para los vaults nuevos**,
alineado con el portal y con la CLI. Una plantilla vieja que fijaba access policies sin declarar el
modelo puede cambiar de comportamiento al subir de versión de API.

---

## 4. 🧱 Crear el vault del laboratorio

```bash
az keyvault create \
  --name inv-lab-kv-472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku standard \
  --enable-rbac-authorization true \
  --retention-days 7 \
  --tags project=inv-lab env=lab
```

- `--name inv-lab-kv-472913` es el nombre global del vault: forma su URL,
  `https://inv-lab-kv-472913.vault.azure.net`. El sufijo numérico evita chocar con los nombres
  retenidos por soft-delete de otros usuarios (§5).
- `--sku standard` elige el tier; el laboratorio no necesita claves HSM.
- `--enable-rbac-authorization true` fija Azure RBAC como modelo de autorización del data plane. Ya es
  el valor por defecto en la CLI, pero se escribe explícito porque el laboratorio depende de él y una
  plantilla no debe depender de defaults que cambian.
- `--retention-days 7` fija la retención del soft-delete en el mínimo permitido. **Solo se puede
  fijar al crear el vault**; después no se cambia. Siete días acortan el tiempo que el nombre queda
  retenido tras el teardown.
- `--tags` etiqueta el vault como todo el resto del laboratorio.
- **No** se pasa `--enable-purge-protection`, a propósito: con purge protection, el nombre quedaría
  retenido 7 días sin remedio después de borrar el vault (§5).

Crear el vault con RBAC **no te da acceso a sus secretos**, aunque seas Owner de la suscripción: el
Owner no tiene `DataActions` ([`10` §3](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions)). Hay que asignarse un rol de datos:

```bash
az role assignment create \
  --assignee-object-id "$(az ad signed-in-user show --query id --output tsv)" \
  --assignee-principal-type User \
  --role "Key Vault Secrets Officer" \
  --scope "$(az keyvault show --name inv-lab-kv-472913 --query id --output tsv)"

az keyvault secret set \
  --vault-name inv-lab-kv-472913 \
  --name partner-api-key \
  --value "replace-me" \
  --expires "2026-12-31T00:00:00Z"
```

- `az ad signed-in-user show --query id` devuelve el object ID de tu usuario en Entra ID, que es quien
  recibe el rol.
- `--role "Key Vault Secrets Officer"` permite crear, leer y borrar secretos. A `inv-api-id` se le da
  solo `Key Vault Secrets User`, que únicamente los lee.
- `--scope` es el resource ID del vault: el rol vale para ese vault, no para los demás.
- `az keyvault secret set` crea el secreto o, si ya existe, **una versión nueva**; las anteriores se
  conservan.
- `--expires` fija la fecha de expiración. Es **informativa**: la operación `get` sigue devolviendo un
  secreto expirado (sirve para recuperaciones), pero la expiración dispara eventos (§8) y aparece en
  las recomendaciones de seguridad.
  Un secreto sin fecha es un secreto que nadie rotará.

> 🩺 **Diagnóstico.** Un `403 Forbidden` con el código `ForbiddenByRbac` recién creado el vault, o
> recién asignado el rol, es casi siempre propagación de RBAC: hasta 10 minutos ([`10` §7](10-autorizacion-rbac-policy-y-gobierno.md#7--propagación-caché-y-límites)).
> Si persiste, el mensaje trae el `Caller` y la acción de datos que faltó.

---

## 5. 🧱 Soft-delete y purge protection

**El problema:** alguien borra el vault de producción, o un secreto, por error o con mala intención.
Si con el vault se van las claves que cifran tus bases, perdiste los datos.

- **Soft-delete**: un vault o un objeto borrado queda **recuperable** durante la retención, de 7 a 90
  días (90 por defecto), fijada al crear el vault. Está **activado por defecto** en todo vault nuevo y,
  una vez activo, **no se puede desactivar**. Borrar definitivamente exige dos pasos: borrar y luego
  **purgar**, y purgar requiere un permiso especial (el rol `Key Vault Purge Operator`, por ejemplo);
- **purge protection**: opcional y desactivada por defecto. Con ella, **nadie puede purgar** antes de
  que acabe la retención, ni siquiera el Owner. Una vez activada, **no se puede desactivar**. Es
  obligatoria para usar el vault con customer-managed keys de Storage o de Azure SQL (§9).

Tres consecuencias que se preguntan:

- **el nombre queda retenido**: mientras el vault está soft-deleted, no se puede crear otro con el mismo
  nombre. Sin purge protection se purga y se libera; con ella, se espera;
- **recuperar no lo restaura todo**: al soft-deletear un vault se borran los servicios integrados, como
  sus **role assignments** y sus suscripciones de Event Grid; recuperarlo no los devuelve y hay que
  recrearlos;
- un objeto soft-deleted **no cobra** operaciones, salvo el recover y el purge mismos, y las claves HSM
  usadas en los últimos 30 días.

```bash
az keyvault delete --name inv-lab-kv-472913 --resource-group inv-lab-rg
az keyvault list-deleted --query "[].name" --output tsv
az keyvault purge --name inv-lab-kv-472913 --location eastus2
```

- `az keyvault delete` pasa el vault a soft-deleted. `az group delete` hace lo mismo con los vaults
  del resource group: **no los purga**.
- `az keyvault list-deleted` lista los vaults soft-deleted de la suscripción; es la comprobación del
  teardown, porque `az resource list` ya no los muestra.
- `az keyvault purge` lo borra definitivamente y libera el nombre. `--location` indica la región del
  vault borrado, que ya no vive en el resource group sino como un recurso *proxy* de la suscripción en
  esa región. Con purge protection, este comando falla hasta que acaba la retención.
- `az keyvault recover --name inv-lab-kv-472913` sería la operación inversa: devuelve el vault con sus
  objetos, pero no sus role assignments.

> Nunca respondas: "borré el vault, así que puedo recrearlo con el mismo nombre". Mejor: "el vault
> queda soft-deleted con el nombre retenido durante la retención; sin purge protection lo purgo, y con
> purge protection tengo que esperar a que termine, por diseño".

---

## 6. 🧱 Red: firewall y private endpoint

Por defecto, el endpoint del vault es público y la autorización (Entra ID + RBAC) es la única barrera.
En producción se añade la barrera de red:

- el **firewall del vault** restringe el acceso a rangos de IP y a subnets con service endpoint, con la
  excepción opcional de los *trusted Microsoft services*;
- un **private endpoint** le da al vault una IP privada en tu VNet y, con `--public-network-access
  Disabled`, cierra el endpoint público. La resolución DNS pasa por la zona privada
  `privatelink.vaultcore.azure.net`, con la cadena de CNAME del [`03` §4](03-conectividad-privada-y-dns.md#4--service-endpoint-frente-a-private-endpoint).

> ⚠️ **Un vault cerrado a la red pública también se cierra para ti.** Con el acceso público
> deshabilitado, `az keyvault secret show` desde tu portátil falla con un `403` que dice que la red no
> está permitida, aunque tengas el rol correcto. Y lo mismo le pasa al pipeline de despliegue si corre
> en un runner público.

---

## 7. 🧱 Consumir secretos desde la aplicación

Tres formas, de menos a más código:

**1. Key Vault references en la plataforma.** Container Apps (y App Service) resuelven el secreto por
ti con la managed identity y lo exponen como variable de entorno. La app ni sabe que existe Key Vault:

```bash
az containerapp secret set \
  --name inv-api \
  --resource-group inv-lab-rg \
  --secrets "partner-api-key=keyvaultref:https://inv-lab-kv-472913.vault.azure.net/secrets/partner-api-key,identityref:$(az identity show --name inv-api-id --resource-group inv-lab-rg --query id --output tsv)"
```

- `--secrets nombre=keyvaultref:<uri>,identityref:<id>` declara un secreto de la app cuyo valor vive en
  Key Vault. `keyvaultref` es la URI del secreto; `identityref` es el **resource ID** de la
  user-assigned identity con la que Container Apps lo lee, que necesita `Key Vault Secrets User`. El
  nombre del secreto en Container Apps no puede pasar de 20 caracteres.
- La URI **sin versión** apunta a la última: cuando se crea una versión nueva, Container Apps la recoge
  **en un plazo de hasta 30 minutos** y reinicia las revisiones que la usan en variables de entorno.
  Con la versión en la URI, el valor queda fijo hasta que cambies la referencia.
- Después se usa en el contenedor como variable de entorno con `secretref:partner-api-key`.

**2. Spring Cloud Azure como property source.** Carga los secretos del vault en el `Environment` de
Spring **antes de construir el contexto**, así que sirven para propiedades que se necesitan al
arrancar, como la contraseña de un datasource:

```properties
# application.properties — con spring-cloud-azure-starter-keyvault
spring.cloud.azure.keyvault.secret.property-sources[0].endpoint=https://inv-lab-kv-472913.vault.azure.net/
spring.cloud.azure.keyvault.secret.property-sources[0].credential.managed-identity-enabled=true
spring.cloud.azure.keyvault.secret.property-sources[0].credential.client-id=${AZURE_CLIENT_ID}
partner.api-key=${partner-api-key}
```

- `property-sources[0].endpoint` es la URL del vault. Cada secreto aparece como una propiedad con su
  nombre.
- `credential.managed-identity-enabled=true` con `credential.client-id` usa **esa** user-assigned
  identity, igual que `managedIdentityClientId` en el [`09` §8](09-identidad-entra-id-y-managed-identities.md#8--defaultazurecredential-en-java).
- `partner.api-key=${partner-api-key}` enlaza el secreto con una propiedad propia de la aplicación.

La versión se fija con el BOM `com.azure.spring:spring-cloud-azure-dependencies`: **7.4.0 para Spring
Boot 4.0.x**, según la tabla de compatibilidad de Learn a la fecha de vigencia. El [`12`](12-identidad-de-aplicaciones-oauth-con-entra-id.md) usa
la misma combinación.

**3. El SDK directamente** (`SecretClient`, [`09` §8](09-identidad-entra-id-y-managed-identities.md#8--defaultazurecredential-en-java)), cuando la app necesita leer el secreto
en el momento de usarlo, por ejemplo para recoger una rotación sin reiniciar.

> 💡 **Tip.** Las tres formas usan la misma managed identity y el mismo rol. Lo que cambia es **cuándo
> se lee** el secreto: la plataforma y el property source lo leen al arrancar; el SDK, cuando el código
> quiere. Eso decide cómo se recoge una rotación.

---

## 8. 🧱 Rotación y expiración

Un secreto sin rotación es un secreto que se filtra una vez y vale para siempre. El patrón en Azure:

- el secreto tiene **fecha de expiración**;
- Key Vault publica eventos en **Event Grid**: `SecretNearExpiry` (**30 días antes** de expirar),
  `SecretExpired` y `SecretNewVersionCreated`, y los equivalentes para claves y certificados;
- una Function o un Logic App suscritos a `SecretNearExpiry` generan la credencial nueva en el sistema
  de origen y la guardan como **versión nueva** del secreto;
- las apps que referencian la URI sin versión la recogen (Container Apps en hasta 30 minutos).

Para las **claves**, Key Vault tiene rotación automática nativa con una política (cada tantos días
genera una versión nueva). Para los secretos no, porque Key Vault no sabe cambiar la contraseña en el
sistema de origen: esa parte es tuya.

> ⚠️ Los eventos solo se emiten para **versiones nuevas** de un objeto y solo si hay una suscripción de
> Event Grid **antes**; un secreto creado sin nadie escuchando no avisa de que va a expirar.

---

## 9. 🧱 Cifrado en reposo y customer-managed keys

**Todo** lo que Azure guarda en Storage, Azure SQL, Cosmos DB o discos está **cifrado en reposo por
defecto**, con **claves administradas por la plataforma** (*platform-managed* o *Microsoft-managed
keys*). No se desactiva y no cuesta nada. Por eso "¿los datos están cifrados?" no es la pregunta
interesante; la interesante es **quién controla la clave**.

Con **customer-managed keys** (CMK), la clave que envuelve las claves de datos del servicio está en
**tu** Key Vault (o Managed HSM):

```text
Datos ──cifrados con──► clave de datos del servicio ──envuelta con──► tu CMK en Key Vault
                                                     (wrapKey/unwrapKey con una managed identity)
```

- el servicio accede a la clave con una **managed identity** que necesita permisos de `get`,
  `wrapKey` y `unwrapKey` sobre ella;
- el vault **debe tener soft-delete y purge protection**; Storage y Azure SQL rechazan la configuración
  si no;
- **revocar la clave es cortar el acceso a los datos**: con la clave deshabilitada, las lecturas y
  escrituras de blobs fallan con `403` para todos. En Azure SQL con **TDE con CMK**, perder el acceso
  al *TDE protector* hace que la base empiece a rechazar conexiones en hasta 10 minutos y pase a estado
  *Inaccessible*; si el acceso vuelve dentro de los 30 minutos se recupera sola, y si no, la
  recuperación es manual y se pierden configuraciones como los failover groups;
- la **rotación** es crear una versión nueva de la clave. Storage, con la URI de clave sin versión,
  comprueba **una vez al día** si hay versión nueva: hay que esperar 24 horas antes de deshabilitar la
  anterior.

**Doble cifrado**: algunos servicios (Storage con *infrastructure encryption*, por ejemplo) añaden una
segunda capa de cifrado en la infraestructura, con otra clave y otro algoritmo, para requisitos que
exigen dos capas independientes.

> Nunca respondas: "usamos CMK, así que Microsoft no puede leer los datos". Mejor: "con CMK controlo el
> ciclo de vida de la clave: la roto, la audito y puedo revocarla, lo que deja los datos inaccesibles.
> El servicio sigue descifrando en tiempo de ejecución con mi clave; es control y revocabilidad, no un
> cifrado que Azure no pueda usar". Lo segundo, en Azure, es *confidential computing* o cifrado del
> lado del cliente.

---

## 10. 🧱 App Configuration

**El problema:** tienes cuarenta propiedades de configuración compartidas por seis microservicios, con
valores distintos por ambiente, y quieres activar una funcionalidad para el 10 % de los usuarios sin
redesplegar.

**Azure App Configuration** es un almacén central de **configuración** y **feature flags**:

- claves jerárquicas con **labels** (típicamente, el ambiente o el perfil de Spring: el proveedor de
  Spring carga por defecto las claves con el label del perfil activo);
- **feature flags** con filtros (porcentaje, ventana de tiempo, usuarios concretos);
- **Key Vault references**: la clave de App Configuration guarda **la URI** del secreto, no su valor;
  la aplicación lo resuelve contra Key Vault con su propia identidad;
- historial de cambios, snapshots y refresco dinámico sin reiniciar.

| | Key Vault | App Configuration |
|---|---|---|
| Qué guarda | Secretos, claves, certificados | Configuración y feature flags |
| Protección | HSM, soft-delete, purge protection | Cifrado en reposo; soft-delete en Standard y Premium |
| Tamaño y consultas | Objetos individuales | Consultas por prefijo y label, lotes |
| Secretos | ✅ su función | ❌ se guardan como referencia a Key Vault |

Se usan **juntos**: App Configuration para qué valores tiene la app, Key Vault para los que son
secretos.

> 💰 **Costo.** App Configuration tiene cuatro tiers. **Free** no cuesta nada, con 1.000 peticiones al
> día y sin SLA; **Developer** cuesta **$0.12/día**; **Standard**, **$1.20/día** (unos $36 al mes) con
> 200.000 peticiones diarias incluidas; **Premium**, **$9.60/día** con una réplica incluida. Precios de
> `eastus2`. Un Standard olvidado cobra por día aunque nadie lo lea, y el laboratorio no lo crea.

---

## 11. 🧱 Defender for Cloud y Sentinel

A nivel conceptual, que es lo que se pregunta a un perfil de backend:

- **Microsoft Defender for Cloud** evalúa la postura de seguridad de tus suscripciones (y de AWS y GCP
  conectados) contra el *Microsoft Cloud Security Benchmark* y da **recomendaciones** y un **secure
  score**. Tiene un plan gratuito, **Foundational CSPM**, y planes de pago: **Defender CSPM** (análisis
  de rutas de ataque, priorización de riesgo, cumplimiento normativo) y los planes de protección por
  carga (servidores, contenedores, bases de datos, Key Vault…), que detectan amenazas en tiempo de
  ejecución;
- **Microsoft Sentinel** es el SIEM de Microsoft: recibe logs de muchas fuentes, los correlaciona y
  gestiona incidentes. Es territorio del equipo de seguridad, no del backend.

> 📝 **Contexto.** Desde el **27 de octubre de 2026**, Foundational CSPM deja de habilitarse por
> defecto en las suscripciones de Azure nuevas: pasa a ser opt-in, sigue siendo gratuito y las
> suscripciones que ya lo tienen lo conservan.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Si el secreto está en Key Vault, estamos seguros" | Sigue siendo un secreto; primero se eliminan los que se pueden sustituir por managed identities |
| "Soy Owner, así que puedo leer los secretos del vault" | Con Azure RBAC hace falta un rol de datos como `Key Vault Secrets User` |
| "Las access policies son equivalentes a RBAC" | Con access policies, un Contributor puede darse acceso a los datos |
| "Borrar el vault libera el nombre" | Queda soft-deleted con el nombre retenido hasta purgarlo o hasta que acabe la retención |
| "Purge protection se puede desactivar después" | Es irreversible; y la retención solo se fija al crear el vault |
| "`az group delete` borra el vault" | Lo deja soft-deleted; hay que purgarlo aparte |
| "Recuperar el vault lo deja como estaba" | Sus role assignments y suscripciones de Event Grid no vuelven |
| "Con CMK Microsoft no puede leer mis datos" | CMK da control y revocabilidad de la clave; el servicio descifra con ella |
| "Guardo los secretos en App Configuration" | Se guarda una referencia a Key Vault, no el valor |

---

## 🧠 Preguntas rápidas

1. ¿Qué orden de preferencia sigues para las credenciales de una aplicación y dónde entra Key Vault?
2. ¿Qué diferencia hay entre un secreto y una clave en Key Vault?
3. ¿Qué te da el tier Premium de Key Vault que no da Standard, y cuándo pensarías en Managed HSM?
4. ¿Por qué Azure RBAC es más seguro que las access policies en Key Vault?
5. Creaste el vault con Azure RBAC y eres Owner de la suscripción, pero `az keyvault secret show` devuelve `403`. ¿Por qué y qué haces?
6. ¿Qué diferencia hay entre soft-delete y purge protection, y cuál de las dos es reversible?
7. Borraste el vault con `az group delete` y al recrearlo con el mismo nombre falla. ¿Por qué y cómo lo resuelves?
8. Recuperaste un vault soft-deleted y la aplicación sigue sin poder leer sus secretos. ¿Qué pasó?
9. ¿Por qué `--retention-days` hay que decidirlo al crear el vault?
10. ¿Cómo lee Container Apps un secreto de Key Vault y cuándo recoge una versión nueva?
11. ¿Cuándo usarías Spring Cloud Azure como property source y cuándo `SecretClient` directamente?
12. ¿Cómo automatizas la rotación de un secreto que no puede sustituirse por una managed identity?
13. ¿Qué es una customer-managed key, qué exige del vault y qué pasa si revocas el acceso a ella?
14. ¿Qué diferencia hay entre Key Vault y App Configuration, y cómo se combinan?
15. ¿Qué ofrece Defender for Cloud gratis y qué cambia el 27 de octubre de 2026?

---

## 📚 Referencias oficiales

- ¿Qué es Azure Key Vault?: https://learn.microsoft.com/en-us/azure/key-vault/general/overview
- Azure RBAC frente a access policies: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-access-policy
- Roles de Azure RBAC para Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide
- Soft-delete y purge protection: https://learn.microsoft.com/en-us/azure/key-vault/general/soft-delete-overview
- Recuperar y purgar con la CLI: https://learn.microsoft.com/en-us/azure/key-vault/general/key-vault-recovery
- Seguridad de red de Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/network-security
- Key Vault con Private Link: https://learn.microsoft.com/en-us/azure/key-vault/general/private-link-service
- Key Vault y Event Grid: https://learn.microsoft.com/en-us/azure/key-vault/general/event-grid-overview
- Rotación automática de claves: https://learn.microsoft.com/en-us/azure/key-vault/keys/how-to-configure-key-rotation
- ¿Qué es Managed HSM?: https://learn.microsoft.com/en-us/azure/key-vault/managed-hsm/overview
- Secretos en Container Apps y Key Vault references: https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets
- Cargar secretos de Key Vault en Spring Boot: https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/configure-spring-boot-starter-java-app-with-azure-key-vault
- Guía de Spring Cloud Azure (BOM y versiones): https://learn.microsoft.com/en-us/azure/developer/java/spring-framework/developer-guide-overview
- Customer-managed keys en Storage: https://learn.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview
- TDE con customer-managed key en Azure SQL: https://learn.microsoft.com/en-us/azure/azure-sql/database/transparent-data-encryption-byok-overview
- Preguntas frecuentes de App Configuration (tiers y límites): https://learn.microsoft.com/en-us/azure/azure-app-configuration/faq
- CSPM en Defender for Cloud: https://learn.microsoft.com/en-us/azure/defender-for-cloud/concept-cloud-security-posture-management
- ¿Qué es Microsoft Sentinel?: https://learn.microsoft.com/en-us/azure/sentinel/overview
- `az keyvault`: https://learn.microsoft.com/en-us/cli/azure/keyvault
- `az keyvault secret`: https://learn.microsoft.com/en-us/cli/azure/keyvault/secret
- `az containerapp secret`: https://learn.microsoft.com/en-us/cli/azure/containerapp/secret
- Precios de Key Vault: https://azure.microsoft.com/en-us/pricing/details/key-vault/
- Precios de App Configuration: https://azure.microsoft.com/en-us/pricing/details/app-configuration/
