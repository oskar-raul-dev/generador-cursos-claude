# 01 — Infraestructura global y Resource Manager

> **Objetivo:** saber dónde vive físicamente un recurso de Azure, a quién pertenece y cómo se habla
> con él: regions, Availability Zones, la jerarquía de scopes y Azure Resource Manager.
> **Se asume leído:** nada. Es el primer capítulo del curso.
> **Se toca más con:** [`02` — redes](02-redes-vnet-nsg-y-enrutamiento.md), que construye la red
> sobre estas regiones, y el [`10`](10-autorizacion-rbac-policy-y-gobierno.md) (autorización), que usa la jerarquía de scopes de este
> capítulo para decidir quién puede hacer qué.
> **Se practica en:** [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) (suscripción, providers, resource group y tags) y [`L03`](l03-bicep-desde-la-cli.md) (scopes de
> despliegue). Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 27 de septiembre de 2026.

**Salto rápido:** [Regions](#2--regions-y-geografías) · [Availability Zones](#3--availability-zones) ·
[Region pairs](#4--region-pairs-y-regiones-sin-pareja) ·
[Zonal, zone-redundant, no regional](#5--zonal-zone-redundant-no-zonal-y-no-regional) ·
[Jerarquía](#6--la-jerarquía-de-scopes) · [Suscripción](#7--la-suscripción) ·
[Resource group](#8--el-resource-group) · [Resource Manager](#9--azure-resource-manager-y-el-resource-id) ·
[Control plane y data plane](#10--control-plane-y-data-plane) ·
[Resource providers](#11--resource-providers-y-su-registro) · [Throttling](#12--throttling-de-resource-manager) ·
[Tags](#13--tags) · [Cuotas](#14--cuotas) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: "¿dónde está mi aplicación?"

Te preguntan en una entrevista: *"tu API Spring Boot está en Azure; si se cae un datacenter,
¿sigue respondiendo?"*. La respuesta honesta es "depende", y este capítulo existe para que sepas
de qué depende. Depende de tres cosas que en Azure son independientes entre sí:

- **dónde corre físicamente** cada pieza: en qué región y, dentro de ella, en qué zona;
- **a qué contenedor lógico pertenece**: qué suscripción la paga y en qué resource group vive su
  ciclo de vida;
- **cómo se habla con ella**: qué pasa por Azure Resource Manager y qué va directo al servicio.

La primera determina la resiliencia; la segunda, quién paga, quién tiene permisos y qué se borra
junto; la tercera, qué controles se aplican a cada operación. Mezclarlas es el error de fondo
detrás de media docena de respuestas incorrectas de entrevista, y por eso el capítulo se divide en
tres partes que las separan.

---

# Parte I — Dónde vive un recurso

## 2. 🧱 Regions y geografías

Una **region** es un conjunto de datacenters desplegados dentro de un perímetro de latencia y
conectados por una red regional de baja latencia. Tiene un nombre de programa (`eastus2`) y uno
visible (`East US 2`). Casi todo recurso de Azure se crea en una región, y **es la decisión más
difícil de cambiar después**: mover un recurso de región es, en la mayoría de los servicios,
recrearlo.

Las regiones se agrupan en **geografías** (Estados Unidos, Europa, Brasil…), que son la frontera de
residencia de datos: una región y su pareja casi siempre están en la misma geografía, y eso es lo que
permite cumplir con requisitos de soberanía sin salir del país.

Tres criterios deciden la región, en este orden:

1. **Cumplimiento y residencia**: dónde pueden vivir legalmente los datos. No es negociable.
2. **Disponibilidad del servicio y de las zonas**: no todos los servicios existen en todas las
   regiones, y no todas las regiones tienen Availability Zones.
3. **Latencia hacia los usuarios y precio**: el mismo SKU cuesta distinto según la región.

> 💡 **Truco.** El curso fija `eastus2` para el laboratorio. Si en una entrevista te preguntan por
> qué elegiste una región, la respuesta que suma puntos empieza por el cumplimiento, no por el
> precio.

---

## 3. 🧱 Availability Zones

**El problema:** un datacenter se queda sin energía. Si tus dos instancias están en ese
datacenter, tener dos instancias no te sirvió de nada.

Una **Availability Zone** es un grupo lógico de uno o más datacenters físicamente separados dentro
de una región, cada uno con energía, refrigeración y red independientes. Las zonas de una región
suelen estar a varios kilómetros entre sí y, por lo general, a menos de 100 km. Microsoft apunta a
una latencia de ida y vuelta de aproximadamente 2 ms entre zonas, lo que permite replicación
síncrona entre ellas.

Dos propiedades que casi nadie conoce y que separan una respuesta de manual de una de quien lo ha
operado:

- **Las zonas son lógicas por suscripción.** Cada datacenter pertenece a una zona física, pero la
  zona "1" que ves en tu suscripción está mapeada a una zona física que puede ser distinta de la
  zona "1" de otra suscripción. Si dos equipos con suscripciones distintas acuerdan "desplegamos todo
  en la zona 1", no tienen garantía de estar en el mismo edificio.
- **Azure no cobra por la transferencia de datos entre zonas de la misma región**, sea por IP
  privada o pública. El argumento "multi-zona es más caro por el tráfico" no aplica en Azure; lo que
  sí cuesta es la instancia extra.

Para ver cómo están mapeadas las zonas de tu suscripción:

```bash
az account list-locations \
  --query "[?name=='eastus2'].availabilityZoneMappings" \
  --output json
```

- `az account list-locations` lista las regiones disponibles **para la suscripción activa**, no el
  catálogo global: si tu suscripción tiene una región restringida, no aparece.
- `--query` recibe una expresión JMESPath que se evalúa en el cliente sobre la respuesta JSON.
  `[?name=='eastus2']` filtra la lista por la propiedad `name` (el nombre de programa, no el visible)
  y `.availabilityZoneMappings` proyecta solo el mapeo lógico → físico. Si pones `East US 2` en
  lugar de `eastus2`, el filtro no coincide y devuelve una lista vacía, sin error.
- `--output json` es el formato por defecto; se escribe explícito porque una lista anidada en
  `--output table` se imprime vacía o aplanada y confunde.

La salida de este comando contra la suscripción real aparece en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md). `eastus2` tiene hoy cuatro
zonas, una de ellas en preview; la mayoría de las regiones con zonas tiene tres.

> ⚠️ **Las zonas no protegen de la caída de una región entera.** Para eso hace falta una segunda
> región, y es una decisión de arquitectura con otro costo y otra complejidad que se discute en el
> [`17`](17-resiliencia-y-well-architected.md).

---

## 4. 🧱 Region pairs y regiones sin pareja

Microsoft asocia algunas regiones con otra de la misma geografía formando una **region pair**. La
pareja de `eastus2` es `centralus`. Una pareja da tres cosas concretas:

- **Secuencia de recuperación**: ante una caída de toda una geografía, una región de cada pareja se
  prioriza para recuperarse.
- **Actualizaciones escalonadas**: Microsoft intenta no actualizar las dos regiones de una pareja a
  la vez.
- **Residencia de datos**: casi todas las parejas están en la misma geografía.

Y aquí está la sobregeneralización que hay que desmontar. La respuesta común es *"si despliego en una
región con pareja, Azure replica mis datos a la pareja"*. Es falsa en general:

> Nunca respondas: "Azure replica mis recursos a la región pareja". Mejor: "La pareja solo importa
> para los servicios que la usan explícitamente —como el almacenamiento GRS— y para la prioridad de
> recuperación; la alta disponibilidad y el DR los diseño yo".

La documentación lo dice sin rodeos: desplegar en una región con pareja no hace a los recursos más
resilientes ni da failover automático. Incluso el failover de una storage account GRS administrado
por Microsoft solo ocurre en situaciones catastróficas y tras intentos fallidos de recuperación.

Dos matices que completan el cuadro:

- **Hay regiones sin pareja**, y cada vez más: muchas regiones nuevas (Italy North, Poland Central,
  Spain Central, Mexico Central, entre otras) no tienen pareja y usan las Availability Zones como su
  mecanismo principal de redundancia.
- **Hay parejas asimétricas**: West US 3 está emparejada en un sentido con East US, pero East US está
  emparejada con West US.

```text
Regla mental:
Availability Zone  = te protege de la caída de un datacenter, dentro de la región
Region pair        = una prioridad de recuperación, no un failover automático
Multi-región       = lo diseñas y lo pagas tú
```

---

## 5. ⚖ Zonal, zone-redundant, no zonal y no regional

Cada servicio soporta las zonas a su manera, y la palabra que usa la documentación dice quién hace el
trabajo:

| Tipo | Quién elige la zona | Qué pasa si cae una zona | Ejemplo |
|---|---|---|---|
| **Zonal** | Tú, una zona concreta | Ese recurso cae; el failover es tuyo | Una VM en la zona 2 |
| **Zone-redundant** | Azure, reparte entre varias | Azure sigue sirviendo desde las otras | Storage ZRS, frontend de un Load Balancer Standard |
| **No zonal (regional)** | Azure, sin decirte dónde | Puede caer si le tocó la zona afectada | Un recurso creado sin configuración de zonas |
| **No regional (global)** | No aplica | No depende de una región | Microsoft Entra ID, Front Door, Traffic Manager |

La fila que más se olvida es la tercera: **un recurso "regional" no es un recurso resiliente a zonas.**
Si no configuras zonas, Azure lo coloca donde quiere y, si cae esa zona, cae contigo.

Para ser *zone-resilient* tienes dos caminos: un recurso zone-redundant, o varios recursos zonales
repartidos en zonas distintas con el failover a tu cargo.

---

# Parte II — Quién es dueño de qué

## 6. 🧱 La jerarquía de scopes

Todo recurso de Azure vive en una jerarquía de cuatro niveles de gestión, colgada de un tenant de
Microsoft Entra ID:

```text
Tenant de Microsoft Entra ID           (identidades: usuarios, grupos, aplicaciones)
└── Root management group ("Tenant root group", ID = ID del tenant)
    └── Management groups              (hasta 6 niveles de profundidad)
        └── Subscription               ← facturación, cuotas, frontera de RBAC
            └── Resource group         ← ciclo de vida
                └── Resource           ← identificado por su resource ID
```

Todo lo que asignas en un nivel —un role assignment, una Azure Policy, un lock— **se hereda hacia
abajo**. Una policy asignada a un management group que prohíbe crear VMs fuera de dos regiones se
aplica a todas las suscripciones, resource groups y recursos que cuelgan de él, y el dueño de una
suscripción no puede saltársela.

Los datos que conviene tener a mano:

- un directorio admite hasta **10.000 management groups**, en un árbol de hasta **seis niveles**
  sin contar la raíz ni el nivel de suscripción;
- **cada management group y cada suscripción tiene un único padre**: una suscripción no puede estar
  en dos management groups a la vez;
- el **root management group** existe siempre, no se puede mover ni borrar, y **nadie tiene acceso
  por defecto a él**: ni siquiera el Global Administrator, que tiene que elevar su acceso
  explícitamente (se ve en el [`09`](09-identidad-entra-id-y-managed-identities.md));
- las suscripciones nuevas caen por defecto bajo el root management group;
- Resource Manager cachea la jerarquía hasta 30 minutos, así que un movimiento reciente puede no
  verse en el portal de inmediato.

> 🧠 **Modelo mental.** El tenant responde "quién eres"; la jerarquía de scopes responde "sobre qué
> actúas". Son dos árboles distintos, y confundirlos es el origen de la pregunta clásica de por qué
> el Global Administrator "no ve" los recursos. Lo desarrollan [`09`](09-identidad-entra-id-y-managed-identities.md) y [`10`](10-autorizacion-rbac-policy-y-gobierno.md).

---

## 7. 🧱 La suscripción

Una suscripción es, a la vez, tres fronteras:

- **de facturación**: todo lo que se crea dentro se factura a su medio de pago;
- **de cuotas**: los límites de vCPU por región, de cuentas de almacenamiento o de IPs públicas se
  cuentan por suscripción (§14);
- **de autorización**: es el scope más habitual para asignar roles de administración.

Una suscripción confía en **un único tenant** de Entra ID, del que toma sus identidades. Se puede
mover de tenant, pero es una operación con consecuencias: los role assignments se pierden.

La pregunta de diseño frecuente es *"¿una suscripción o varias?"*. La respuesta de arquitecto:
separa en suscripciones lo que necesita **fronteras distintas de facturación, cuota o
acceso** —producción frente a no producción, o un equipo frente a otro— y usa resource groups para
todo lo demás. Las cuotas son un argumento que se olvida: una prueba de carga en la misma suscripción
que producción puede agotar la cuota de vCPU de producción.

---

## 8. 🧱 El resource group

**El problema:** terminas una prueba y quieres borrar todo lo que creaste, sin buscar recurso por
recurso. Esa es la razón de existir del resource group.

Un resource group es el contenedor del **ciclo de vida** de un conjunto de recursos. Se parece a una
carpeta *hasta que descubres* todo lo que es además:

- **unidad de borrado en cascada**: borrar el resource group borra todo lo que contiene;
- **scope de RBAC, de Azure Policy y de locks**: lo que asignas en él se hereda a sus recursos;
- **unidad de despliegue**: una plantilla Bicep se despliega casi siempre contra un resource group.

Y hay cuatro reglas que rompen la analogía de la carpeta:

- **cada recurso vive en exactamente un resource group**, aunque puede conectarse con recursos de
  otros (una web app con una base de datos que tiene otro ciclo de vida);
- **los tags del resource group no se heredan** a sus recursos (§13);
- **el resource group tiene una región, y sus recursos pueden estar en otras.** La región del
  resource group es donde se guardan sus **metadatos** y por donde se enrutan las operaciones de
  control plane sobre sus recursos. No restringe dónde se crean los recursos;
- si la región del resource group no está disponible, Resource Manager redirige esas operaciones de
  control plane a una región de respaldo. Pero eso **no cubre el data plane**: si la región donde
  vive el recurso cae, el recurso cae, esté donde esté su resource group. Por eso la recomendación es
  poner recursos y resource group en la misma región.

```text
Regla mental:
Resource group = región propia solo para metadatos
               + frontera de ciclo de vida
               + scope de RBAC, Policy y locks
               ≠ carpeta
```

Crear el resource group del laboratorio:

```bash
az group create \
  --name inv-lab-rg \
  --location eastus2 \
  --tags project=inv-lab env=lab
```

- `--name` es el nombre del resource group: único dentro de la suscripción, no globalmente. Admite
  letras, dígitos, guiones, guiones bajos, puntos y paréntesis, y no puede terminar en punto.
- `--location` fija la región de los **metadatos** del resource group, no la de sus recursos. Si la
  omites, la CLI la pide o usa el default configurado con `az config set defaults.location`.
- `--tags` recibe pares `clave=valor` separados por espacio. Esos tags quedan **en el resource group,
  no en los recursos que crees dentro**: cada recurso lleva los suyos, o una policy los hereda.

`az group create` es idempotente: si el resource group ya existe con esa región, lo actualiza; si
existe con otra región, falla, porque la región no se puede cambiar.

---

# Parte III — Cómo se habla con Azure

## 9. 🧱 Azure Resource Manager y el resource ID

Toda operación de gestión en Azure —desde el portal, `az`, PowerShell, Bicep o un SDK— entra por el
mismo servicio: **Azure Resource Manager** (ARM). ARM autentica la petición, la autoriza, le aplica
Azure Policy y los locks, la registra en el Activity Log y solo entonces la reenvía al **resource
provider** del servicio (§11). Por eso cualquier capacidad del portal existe también en la CLI y en
la API: todas son clientes del mismo endpoint.

Cada recurso tiene un **resource ID**, que es su dirección completa en esa jerarquía:

```text
/subscriptions/11112222-3333-4444-5555-666677778888
  /resourceGroups/inv-lab-rg
    /providers/Microsoft.Storage
      /storageAccounts/invlab472913
```

Se lee de izquierda a derecha: suscripción, resource group, **namespace del resource provider**, tipo
de recurso y nombre. Leerlo con soltura es una habilidad que el curso entrena porque aparece en todos
los mensajes de error y en todos los role assignments.

Dos detalles que ARM impone a todos los servicios:

- **Recursos de extensión.** Algunos recursos no viven dentro de un resource group, sino *sobre* otro
  recurso: un role assignment, un lock o un diagnostic setting se crean con el resource ID del
  recurso al que se aplican como scope.
- **Concurrencia.** Si dos peticiones actualizan el mismo recurso a la vez, ARM deja completar una y
  devuelve `409 Conflict` a la otra. Un pipeline que falla con `409` no está roto: chocó consigo
  mismo o con alguien más.

---

## 10. 🧱 Control plane y data plane

Esta distinción sostiene los capítulos [`06`](06-almacenamiento-storage-accounts.md), [`10`](10-autorizacion-rbac-policy-y-gobierno.md) y [`11`](11-secretos-cifrado-y-key-vault.md), y conviene fijarla ahora.

- **Control plane**: las operaciones que **gestionan** recursos —crear una storage account, cambiar
  su SKU, borrarla—. Todas van a `https://management.azure.com` y pasan por ARM.
- **Data plane**: las operaciones que **usan** un recurso —leer un blob, enviar un mensaje, consultar
  Cosmos DB—. Van al endpoint propio de cada instancia, como `https://invlab472913.blob.core.windows.net`.

La consecuencia importante es qué controles se aplican a cada plano. ARM aplica automáticamente RBAC,
Azure Policy, locks y Activity Log **a las operaciones de control plane**. En el data plane, esos
controles pueden no aplicarse:

> Punto importante: un lock que impide borrar una base de datos no impide borrar sus datos con una
> consulta.

Y el corolario operativo, que parece raro hasta que lo ves: **el data plane sigue funcionando aunque
`management.azure.com` no esté disponible.** Tu aplicación puede seguir leyendo y escribiendo blobs
durante una incidencia de ARM, aunque tú no puedas cambiar la configuración de la cuenta.

```text
Regla mental:
management.azure.com       → control plane → ARM: RBAC (actions), Policy, locks, Activity Log
<recurso>.<servicio>.net    → data plane    → el servicio: RBAC (dataActions) o claves propias
```

Que Azure RBAC tenga permisos separados para cada plano —`actions` frente a `dataActions`— es lo que
explica que el Owner de una suscripción no pueda leer un blob sin un rol de datos. Se desarrolla en
el [`10`](10-autorizacion-rbac-policy-y-gobierno.md).

---

## 11. 🧱 Resource providers y su registro

**El problema:** despliegas tu primera app en Container Apps en una suscripción nueva y falla sin
haber tocado nada raro.

Un **resource provider** es el conjunto de operaciones REST de un servicio, identificado por un
namespace: `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.App` (Container Apps). El tipo de
un recurso se escribe `{namespace}/{tipo}`, como `Microsoft.KeyVault/vaults`.

Antes de usar un provider, **la suscripción tiene que estar registrada en él**. Algunos vienen
registrados por defecto; el portal suele registrar el que necesita al crear un recurso, y un
despliegue de Bicep registra los providers de los recursos que declara. Pero un recurso puede
necesitar otro provider que no aparece en la plantilla —monitoreo, seguridad—, y ahí sale el error:

```text
Code: MissingSubscriptionRegistration
Message: The subscription is not registered to use namespace {resource-provider-namespace}
```

La corrección:

```bash
az provider register --namespace Microsoft.App
az provider show --namespace Microsoft.App --query registrationState --output tsv
```

- `az provider register --namespace` pide el registro del provider indicado para la suscripción
  activa. Es asíncrono: vuelve enseguida y el registro sigue en segundo plano, región por región.
  Necesita el permiso `/register/action`, incluido en Contributor y Owner.
- `az provider show --namespace` devuelve el estado del provider; `--query registrationState` extrae
  solo esa propiedad, que pasa de `Registering` a `Registered`.
- `--output tsv` imprime el valor sin comillas ni formato JSON, que es lo que quieres para usarlo en
  un `if` de un script.

Tres matices que enseña el caso real:

- **Registrar solo lo que vas a usar es privilegio mínimo.** Un atacante no puede usar un provider no
  registrado, y cada registro puede añadir una aplicación de Microsoft a tu tenant.
- **No bloquees tu script esperando `Registered` en todas las regiones**: basta con que termine en la
  región donde vas a crear el recurso.
- **No puedes desregistrar un provider** mientras tengas recursos de sus tipos en la suscripción.

[`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md) provoca este error a propósito y lo corrige.

> 🩺 **Diagnóstico.** Un error parecido, `NoRegisteredProviderFound`, dice *"No registered resource
> provider found for location {location} and API version {api-version} for type {resource-type}"*.
> A pesar del nombre, casi nunca es un problema de registro: es una combinación de región y versión
> de API que ese tipo de recurso no soporta. El mensaje sugiere las válidas.

Cada tipo de recurso expone además **versiones de API** fechadas (`2024-03-01`). La versión fija el
contrato: qué propiedades existen y qué valores aceptan. El curso fija la versión de cada recurso en
Bicep y nunca usa "la última", por las razones de la guía de estilo; el [`15`](15-bicep-iac.md) lo desarrolla.

---

## 12. 🩺 Throttling de Resource Manager

**El problema:** un script que lista recursos en bucle para esperar a que algo termine empieza a
fallar con `429`.

Desde 2024, ARM limita las peticiones **por región** con un algoritmo de token bucket. Los valores
publicados para la nube pública son:

| Scope | Operación | Tamaño del bucket | Recarga por segundo |
|---|---|---|---|
| Suscripción | lecturas | 250 | 25 |
| Suscripción | escrituras | 200 | 10 |
| Suscripción | borrados | 200 | 10 |
| Tenant | lecturas | 250 | 25 |

Los límites de suscripción se aplican por suscripción, **por service principal** y por tipo de
operación, con un límite global de suscripción equivalente a 15 veces el individual. Pueden ser
menores en cuentas gratuitas o de prueba. Además, cada resource provider aplica sus propios límites
(Storage limita las escrituras de gestión a 10 por segundo, por ejemplo).

Cuando se agota el bucket, la respuesta es **`429 Too Many Requests`** con una cabecera
**`Retry-After`** que dice cuántos segundos esperar. Las cabeceras `x-ms-ratelimit-remaining-*`
dicen cuántas peticiones te quedan, y `az … --debug` las muestra.

> 💡 **Truco.** Los SDK de Azure ya reintentan respetando `Retry-After`. El error típico es envolver
> la llamada del SDK en un bucle de reintentos propio sin backoff: multiplicas las peticiones justo
> cuando ARM te pidió que bajaras el ritmo.

Cuidado con la ambigüedad: algunos providers devuelven `429` para un problema temporal que no es
throttling, como `RetryableErrorDueToAnotherOperation` en red cuando otra operación bloquea el
recurso. El código de error del cuerpo es el que lo distingue.

---

## 13. 🧱 Tags

Un tag es un par clave-valor en un recurso, un resource group o una suscripción —no en un management
group—. Sirven para atribuir costos, para automatizar y como criterio de Azure Policy. Lo que hay que
saber:

- **no se heredan**: los tags del resource group o de la suscripción no pasan a los recursos. Si
  quieres herencia, la consigues con una Azure Policy de tipo `modify` ([`10`](10-autorizacion-rbac-policy-y-gobierno.md));
- **las claves no distinguen mayúsculas en las operaciones, los valores sí**. `Project` y `project`
  son la misma clave para Azure, aunque el provider puede conservar el casing que usaste y así se ve
  en los informes de costos;
- como máximo **50 pares por recurso**, con clave de hasta 512 caracteres y valor de hasta 256 (128
  para la clave en storage accounts), y la clave no admite `<`, `>`, `%`, `&`, `\`, `?` ni `/`;
- **se guardan en texto plano** y aparecen en informes de costos, historiales de despliegue y
  plantillas exportadas: nunca pongas un secreto en un tag;
- no todos los tipos de recurso admiten tags, y algunos admiten solo 15.

Etiquetar exige permiso de escritura sobre el recurso o el rol **Tag Contributor**, que permite
etiquetar sin poder modificar el recurso en sí.

---

## 14. 🧱 Cuotas

**El problema:** tu despliegue de una VM falla con un error de cuota en una suscripción recién
creada, aunque no tienes nada encendido.

Las **cuotas** (antes llamadas límites) son el número de recursos que tu suscripción puede consumir:
vCPU por región y por familia de VM, cuentas de almacenamiento, IPs públicas. Hay dos tipos:

- **ajustables**: se pide un aumento desde el portal, sin costo, sujeto a revisión y a capacidad;
- **no ajustables**: límites duros, que solo se discuten con soporte.

Dos matices de entrevista:

- **una cuota no reserva capacidad**: tener cuota de 100 vCPU no garantiza que haya 100 vCPU
  disponibles en esa región cuando las pidas;
- **pedir una cuota no cuesta nada**: se paga por lo que se usa, no por la cuota asignada.

```bash
az vm list-usage --location eastus2 --output table
```

- `az vm list-usage` muestra, para la suscripción activa y la región indicada, el consumo actual y el
  límite de cada cuota de cómputo: vCPU totales, vCPU por familia, número de VMs.
- `--location` es obligatorio porque las cuotas de cómputo son **por región**: la cuota de `eastus2`
  no dice nada de `centralus`.
- `--output table` es aquí la opción legible, porque la respuesta es una lista plana de nombre,
  valor actual y límite.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Mi región tiene pareja, así que Azure replica mis datos" | Solo los servicios que usan la pareja explícitamente, como GRS; el DR lo diseñas tú |
| "Todos desplegamos en la zona 1, así que estamos juntos" | Las zonas son lógicas por suscripción; la zona 1 de otra suscripción puede ser otro edificio |
| "Un recurso regional es resiliente a zonas" | Un recurso sin configuración de zonas puede caer con la zona que le tocó |
| "El resource group limita la región de sus recursos" | Su región solo guarda metadatos y enruta el control plane |
| "Los recursos heredan los tags del resource group" | No se heredan; se consigue con Azure Policy |
| "Si tengo cuota, tengo capacidad" | La cuota no reserva capacidad |
| "Un lock protege los datos" | Protege del borrado por control plane, no de un `DELETE` en el data plane |
| "Si `management.azure.com` cae, mi app cae" | El data plane sigue funcionando; lo que pierdes es la gestión |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a una region de una Availability Zone?
2. ¿Por qué la zona "1" de tu suscripción puede no ser la misma zona física que la zona "1" de otra suscripción?
3. ¿Desplegar en una región con pareja hace que Azure replique tus recursos a la región pareja?
4. ¿Qué diferencia a un recurso zonal de uno zone-redundant, y qué le pasa a un recurso sin configuración de zonas si cae la zona donde Azure lo colocó?
5. ¿Una suscripción puede pertenecer a dos management groups a la vez?
6. ¿Qué guarda la región de un resource group y restringe la región de sus recursos?
7. ¿Los recursos heredan los tags de su resource group?
8. ¿Cuándo separarías cargas en suscripciones distintas en vez de en resource groups distintos?
9. ¿Qué controles aplica ARM a una operación de control plane que pueden no aplicarse en el data plane?
10. ¿Tu aplicación puede seguir leyendo blobs si `management.azure.com` no está disponible?
11. Tu primer despliegue de Container Apps en una suscripción nueva falla con `MissingSubscriptionRegistration`. ¿Qué pasó y cómo lo corriges?
12. Un script que consulta el estado de un recurso en bucle empieza a recibir `429`. ¿Qué significa y cómo debe responder el script?
13. ¿Tener cuota de vCPU en una región garantiza que haya capacidad para crear las VMs?

---

## 📚 Referencias oficiales

- ¿Qué son las Availability Zones?: https://learn.microsoft.com/en-us/azure/reliability/availability-zones-overview
- Region pairs y regiones sin pareja: https://learn.microsoft.com/en-us/azure/reliability/regions-paired
- Lista de regiones de Azure: https://learn.microsoft.com/en-us/azure/reliability/regions-list
- Management groups: https://learn.microsoft.com/en-us/azure/governance/management-groups/overview
- ¿Qué es Azure Resource Manager? (scopes y resource groups): https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview
- Control plane y data plane: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/control-plane-and-data-plane
- Resource providers y tipos de recurso: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types
- Errores de registro de resource providers: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider
- Throttling de Resource Manager: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling
- Tags en recursos, resource groups y suscripciones: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources
- Reglas de nombre de recursos: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
- Límites de suscripción y de servicio: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits
- Mover recursos a otro resource group o suscripción: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/move-resource-group-and-subscription
- Borrado de resource groups y recursos: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/delete-resource-group
- Cuotas de Azure: https://learn.microsoft.com/en-us/azure/quotas/quotas-overview
- `az account list-locations`: https://learn.microsoft.com/en-us/cli/azure/account#az-account-list-locations
- `az provider`: https://learn.microsoft.com/en-us/cli/azure/provider
- `az group`: https://learn.microsoft.com/en-us/cli/azure/group
- `az vm list-usage`: https://learn.microsoft.com/en-us/cli/azure/vm#az-vm-list-usage
- Consultas JMESPath en la CLI (`--query`): https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-query
