# L01 — Suscripción, CLI aislada y blindaje de costos

> **Objetivo:** dejar una CLI aislada de tu sesión de trabajo, la suscripción del lab con los
> resource providers que la serie necesita, un resource group etiquetado y un budget que avise antes
> de que la factura sorprenda. Es el lab que se hace **antes** de crear el primer recurso que cobra, y
> el único cuyo entregable es una red de seguridad.
> **Se asume leído:** [`L00`](l00-idea-lab-practico.md) (el contrato y el presupuesto) y
> [`01`](01-infraestructura-global-y-resource-manager.md) (suscripción, resource group, providers y
> tags). La mecánica de `az` está en [`A01`](a01-az-de-supervivencia.md).
> **Costo:** **$0.00**. Un resource group, unos providers registrados, un action group y un budget no
> cobran por existir; los primeros 1.000 correos al mes de un action group son gratis.
> **Duración:** 60–90 minutos.
> **Prerrequisitos:** una suscripción de Azure propia (cuenta gratuita o pay-as-you-go) en la que seas
> Owner, y la CLI 2.90.0 instalada ([`A01` §2](a01-az-de-supervivencia.md#2--instalación-y-versión-fija)).
> **Qué queda encendido al terminar:** el perfil `~/.azure-inv-lab`, los providers registrados, el
> resource group `inv-lab-rg` con el action group `inv-lab-ag` dentro, y el budget `inv-lab-budget`
> sobre la suscripción. **Nada de eso factura.**
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Por qué va primero](#1--por-qué-este-lab-va-primero) ·
[La suscripción](#2--la-suscripción-y-lo-que-la-cuenta-gratuita-protege) ·
[Perfil aislado](#3--el-perfil-aislado-y-el-login) ·
[Providers](#4--resource-providers-y-provocar-missingsubscriptionregistration) ·
[Resource group](#5--el-resource-group-con-tags-obligatorios) ·
[Action group](#6--el-action-group-a-quién-avisar) ·
[Budget](#7--el-budget-y-lo-que-de-verdad-hace) ·
[Cost Management](#8--cost-management-dónde-se-mira-el-gasto) ·
[Teardown](#9--teardown-de-este-lab) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Por qué este lab va primero

El instinto dice empezar desplegando algo que se vea: un contenedor, una storage account, cualquier
cosa. Y es exactamente el orden que produce los dos problemas más comunes de un laboratorio en la
nube: recursos repartidos por una suscripción que ya usabas para otra cosa, y una factura que
descubres a los treinta días.

Este lab compra cuatro cosas, en este orden de importancia:

```text
1. Una CLI que no toca tu trabajo      → perfil aislado con AZURE_CONFIG_DIR
2. Un contenedor de borrado            → todo el lab vive en inv-lab-rg, que se borra entero
3. Una etiqueta de gasto               → project=inv-lab en todo lo que crees
4. Un aviso                            → un budget de $5 que te escribe si algo se quedó encendido
```

> 🧠 **Modelo mental.** En Azure la **suscripción** es la frontera de facturación, de cuotas y de
> acceso, y el **resource group** es la unidad de ciclo de vida y de borrado
> ([`01` §7–§8](01-infraestructura-global-y-resource-manager.md#7--la-suscripción)). El laboratorio
> usa una suscripción que sea tuya y un resource group dedicado: al final de la serie, borrar ese
> grupo se lleva casi todo lo que hiciste, y [`L09`](l09-costos-y-destruccion-verificada.md) se encarga del "casi".

---

## 2. 🧱 La suscripción, y lo que la cuenta gratuita protege

Este lab no crea la suscripción: la necesitas antes de empezar, y hay dos caminos.

| Tipo | Qué te protege | Qué pasa a los 30 días |
|---|---|---|
| Cuenta gratuita | $200 de crédito y un **spending limit** que deshabilita los servicios cuando el crédito se agota | Hay que pasarla a pay-as-you-go para seguir usando las ofertas gratuitas, y el spending limit desaparece |
| Pay-as-you-go | Nada automático: tu disciplina de teardown y el budget de este lab | Nada; factura desde el primer día |

El desarrollo completo está en [`L00` §1](l00-idea-lab-practico.md#1--las-dos-restricciones-de-partida).
Lo que importa hoy es una frase:

> Regla importante: un budget avisa, no detiene. El único mecanismo que detiene el gasto es el
> spending limit de la cuenta gratuita, y solo mientras dure el crédito.

> ⚠️ **No uses la suscripción de tu empresa ni una compartida.** El lab registra providers, crea role
> assignments y en [`L06`](l06-identidad-de-aplicaciones-api-protegida.md) escribe app registrations en el tenant. En una suscripción corporativa, o no
> tienes permiso para eso, o lo tienes y no deberías usarlo para practicar.

---

## 3. 🧱 El perfil aislado y el login

La CLI de Azure guarda la sesión y la suscripción activa en un solo directorio. El lab usa uno propio
para no heredar ni contaminar tu sesión de trabajo ([`A01` §3](a01-az-de-supervivencia.md#3--el-perfil-aislado-azure_config_dir)):

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
az login
```

- `export AZURE_CONFIG_DIR=...` vale para esta terminal. **Cada sesión de la serie empieza con esta
  línea**; si abres otra pestaña sin ella, estás en tu perfil de trabajo.
- `az login` abre el navegador, autentica tu usuario (con MFA, obligatorio en la CLI desde septiembre
  de 2025) y, si tu cuenta ve varias suscripciones, te muestra el selector para elegir la del lab.

```text
[PENDIENTE DE CORRIDA] Tras el login en el navegador, la tabla del selector de suscripciones
(si hay más de una) y el resumen con el tenant y la suscripción elegidos.
```

Ahora fija la suscripción del lab en una variable y confirma dónde estás:

```bash
SUB=$(az account show --query id --output tsv)
TENANT=$(az account show --query tenantId --output tsv)
az account show --query "{name:name, state:state, user:user.name}" --output table
```

- `SUB` y `TENANT` se reutilizan en todo el lab. Guárdalas en tus notas: los labs siguientes las
  vuelven a definir igual al empezar.
- `state` tiene que ser `Enabled`. Una suscripción `Disabled` (por ejemplo, una cuenta gratuita que
  agotó su crédito) acepta lecturas pero rechaza toda creación.

```text
[PENDIENTE DE CORRIDA] Una fila con el nombre de la suscripción, state Enabled y tu usuario.
```

> 💡 **Truco.** Si tienes varias suscripciones, deja la del lab fijada por id con
> `az account set --subscription "$SUB"`. En este perfil aislado no cambia nada de tu trabajo, y te
> protege si el selector de `az login` eligió otra.

---

## 4. 🩺 Resource providers, y provocar `MissingSubscriptionRegistration`

Cada servicio de Azure lo implementa un **resource provider** —`Microsoft.Storage`, `Microsoft.App`,
`Microsoft.ServiceBus`— y una suscripción tiene que estar **registrada** en él antes de crear sus
recursos ([`01` §11](01-infraestructura-global-y-resource-manager.md#11--resource-providers-y-su-registro)).
Una suscripción nueva solo trae registrados por defecto unos pocos providers de núcleo, entre ellos
`Microsoft.Resources`, `Microsoft.Authorization`, `Microsoft.Consumption` y `Microsoft.CostManagement`.

Mira primero el estado del que vas a usar para provocar el error:

```bash
az provider show --namespace Microsoft.ManagedIdentity --query registrationState --output tsv
```

- `az provider show` devuelve el provider con sus tipos de recurso; el `--query` se queda con
  `registrationState`, que vale `NotRegistered`, `Registering`, `Registered` o `Unregistering`.

```text
[PENDIENTE DE CORRIDA] NotRegistered en una suscripción nueva.
```

> ⚠️ Si ya sale `Registered` —porque la suscripción no es nueva o porque creaste antes una managed
> identity—, elige otro provider de la tabla de más abajo que salga `NotRegistered` y usa su tipo de
> recurso en el paso siguiente. El error es el mismo.

Ahora el error, y se provoca antes de arreglarlo, que es el método de toda la serie práctica. La
[documentación](https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider)
advierte que el portal y la CLI registran por ti **la mayoría** de los providers al crear un recurso,
pero no todos. Para ver el error sin que ningún cliente lo tape, la petición va directa a ARM con
`az rest` ([`A01` §11](a01-az-de-supervivencia.md#11--az-rest-la-api-sin-intermediarios)):

```bash
az group create --name inv-lab-rg --location eastus2 --tags project=inv-lab env=lab --output none

az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-lab-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/inv-probe-id?api-version=2023-01-31" \
  --body '{"location": "eastus2", "tags": {"project": "inv-lab", "env": "lab"}}'
```

- El `az group create` crea el grupo que la sección 5 explica entero; hace falta ya porque la
  identidad de prueba tiene que vivir en algún sitio.
- La URL es el resource ID de una user-assigned managed identity más su `api-version`, `2023-01-31`,
  la misma que fija [`15` §3](15-bicep-iac.md#3--un-archivo-bicep-del-laboratorio) y que la
  referencia de plantillas lista como estable.
- `--body` es el recurso: una identidad solo necesita `location`; los tags van por disciplina.

```text
[PENDIENTE DE CORRIDA] Error de ARM con código MissingSubscriptionRegistration y el mensaje
"The subscription is not registered to use namespace 'Microsoft.ManagedIdentity'".
```

Léelo entero, porque dice tres cosas:

- **El código es `MissingSubscriptionRegistration`, no `AuthorizationFailed`.** Ese detalle te ahorra
  media hora de revisar roles cuando el problema no eran los roles. El catálogo completo está en
  [`A03`](a03-catalogo-de-errores-y-diagnostico.md).
- **El namespace viene en el mensaje.** Es exactamente lo que hay que registrar.
- **La variante `NoRegisteredProviderFound`** es otra cosa: el provider existe, pero no admite esa
  `api-version` o esa región para ese tipo. Se lee igual y se arregla distinto.

La corrección, registrando de una vez todo lo que la serie va a necesitar:

```bash
for ns in Microsoft.ManagedIdentity Microsoft.Storage Microsoft.KeyVault \
          Microsoft.Network Microsoft.Compute Microsoft.ContainerRegistry Microsoft.App \
          Microsoft.OperationalInsights Microsoft.Insights Microsoft.DocumentDB \
          Microsoft.ServiceBus Microsoft.PolicyInsights; do
  az provider register --namespace "$ns"
done
```

- `az provider register` pide el registro y **devuelve el control sin esperar**: el registro se hace
  región por región y puede tardar minutos. Con `--wait` bloquearía hasta terminar cada uno, uno
  detrás de otro; el bucle sin `--wait` los lanza todos en paralelo.
- Registrar necesita la acción `*/register/action` del provider, que está en Owner y Contributor.
- **Registrar no crea nada ni cobra nada.** Lo que sí hace es añadir a tu tenant las aplicaciones del
  provider: por eso la documentación recomienda registrar solo lo que vas a usar.

| Provider | Para qué lo usa la serie | Lab |
|---|---|---|
| `Microsoft.ManagedIdentity` | `inv-api-id`, `inv-projector-id` | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| `Microsoft.Storage` | `invlab472913` | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| `Microsoft.KeyVault` | `inv-lab-kv-472913` | [`L02`](l02-entra-id-rbac-y-managed-identities.md) |
| `Microsoft.PolicyInsights` | Estado de cumplimiento de Azure Policy | [`L03`](l03-bicep-desde-la-cli.md) |
| `Microsoft.Network` | VNet, NSG, private endpoint, Private DNS zone, Network Watcher | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) |
| `Microsoft.Compute` | La VM de diagnóstico | [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) |
| `Microsoft.ContainerRegistry` | `invlabacr472913` | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) |
| `Microsoft.App` | Container Apps environment y apps | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) |
| `Microsoft.OperationalInsights` | Log Analytics workspace | [`L05`](l05-container-apps-revisiones-trafico-y-escala.md), [`L08`](l08-observabilidad-kql-y-auditoria.md) |
| `Microsoft.DocumentDB` | Cosmos DB | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) |
| `Microsoft.ServiceBus` | Namespace, topic y subscription | [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) |
| `Microsoft.Insights` | Action group (este lab), diagnostic settings, alertas, Application Insights | `L01`, [`L08`](l08-observabilidad-kql-y-auditoria.md) |

Comprueba el estado:

```bash
az provider list \
  --query "sort_by([?registrationState!='NotRegistered'].{ns:namespace, state:registrationState}, &ns)" \
  --output table
```

- El filtro `[?registrationState!='NotRegistered']` deja solo lo registrado o en proceso;
  `sort_by(..., &ns)` ordena por namespace para que la lista se lea.

```text
[PENDIENTE DE CORRIDA] La tabla con los doce providers de la serie en Registering o Registered,
junto con los que la suscripción trae por defecto.
```

> 🩺 **Diagnóstico.** Un provider en `Registering` **no bloquea**: la documentación pide que el código
> no espere a que termine en todas las regiones, porque para crear un recurso basta con que esté
> listo en la región que usas. Si un comando falla con `MissingSubscriptionRegistration` justo después
> de registrar, espera un minuto y repite; si a la tercera sigue, mira `registrationState` antes de
> dudar de otra cosa.

Ahora sí, la misma petición funciona. Repite el `az rest` de arriba y después bórralo, que era solo
una sonda:

```bash
az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-lab-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/inv-probe-id?api-version=2023-01-31" \
  --body '{"location": "eastus2", "tags": {"project": "inv-lab", "env": "lab"}}' \
  --query "{name:name, principalId:properties.principalId}"

az identity delete --name inv-probe-id --resource-group inv-lab-rg
```

- `--query` recorta la respuesta a lo que prueba que la identidad existe: su nombre y el `principalId`
  del service principal que Azure creó para ella en Entra ID ([`09` §5](09-identidad-entra-id-y-managed-identities.md#5--managed-identities)).
- `az identity delete` la borra con el comando de primera clase. Una managed identity borrada se
  lleva su service principal; no queda soft-deleted.

```text
[PENDIENTE DE CORRIDA] Un objeto con name "inv-probe-id" y un principalId (GUID). El delete no
imprime nada.
```

**Teardown de lo creado en esta sección:** la identidad de sonda ya está borrada. Los providers **no
se desregistran**: no cobran, y desregistrar falla mientras quede algún recurso de ese tipo en la
suscripción.

---

## 5. 🧱 El resource group con tags obligatorios

El grupo ya existe desde la sección 4. Aquí se explica qué creaste y por qué cada flag:

```bash
az group create --name inv-lab-rg --location eastus2 --tags project=inv-lab env=lab
```

- `--name inv-lab-rg` sigue la regla de nombre de un resource group: de 1 a 90 caracteres, letras,
  dígitos, guiones, guiones bajos, puntos y paréntesis, y sin terminar en punto. Es único **dentro de
  la suscripción**, no en todo Azure.
- `--location eastus2` es la región de los **metadatos** del grupo, no una restricción para sus
  recursos ([`01` §8](01-infraestructura-global-y-resource-manager.md#8--el-resource-group)). La
  serie pone todo en `eastus2` igualmente, por la decisión D5 de [`L00`](l00-idea-lab-practico.md).
- `--tags project=inv-lab env=lab` pone los dos tags de rastreo del baseline. **Los recursos no los
  heredan**: cada comando de la serie los repite, y [`L03`](l03-bicep-desde-la-cli.md) añade una Azure Policy que rechaza lo que
  llegue sin ellos.
- `az group create` sobre un grupo que ya existe **no falla**: lo actualiza con lo que le pases. Por
  eso repetirlo es seguro, y por eso un typo en `--tags` sobrescribe los tags buenos.

```text
[PENDIENTE DE CORRIDA] JSON del grupo: id /subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/inv-lab-rg,
location eastus2, properties.provisioningState Succeeded y los dos tags.
```

Verifica los tags desde el lado que los usa, el filtro por tag:

```bash
az group list --tag project=inv-lab --query "[].{name:name, tags:tags}" --output json
```

```text
[PENDIENTE DE CORRIDA] Una lista con un único elemento: inv-lab-rg y sus dos tags.
```

> ⚠️ **Las claves de tag no distinguen mayúsculas; los valores sí.** `Project=inv-lab` y
> `project=inv-lab` son la misma clave para Azure, pero `project=Inv-Lab` es otro valor y no aparece en
> un filtro por `project=inv-lab`. El curso usa minúsculas en ambos para no tener que pensarlo.

---

## 6. 🧱 El action group: a quién avisar

Un budget puede mandar correos directamente, pero la forma de que un aviso **dispare algo** —un
correo hoy, un webhook o una Function mañana— es un **action group**: un recurso de Azure Monitor que
agrupa receptores y que reutilizan budgets, alertas de métrica y alertas de log. El de la serie se
crea ahora y lo vuelve a usar la alerta de la DLQ en [`L08`](l08-observabilidad-kql-y-auditoria.md).

**Teardown antes que el despliegue:** el action group vive en `inv-lab-rg` y muere con él; el budget de
la sección 7 lo referencia, así que [`L09`](l09-costos-y-destruccion-verificada.md) borra primero el budget y después el grupo.

```bash
az monitor action-group create \
  --name inv-lab-ag \
  --resource-group inv-lab-rg \
  --short-name invlab \
  --action email owner tu-correo@example.com \
  --tags project=inv-lab env=lab
```

- `--name inv-lab-ag` admite de 1 a 260 caracteres, sin `:<>+/&%\?|` y sin terminar en espacio o
  punto.
- `--short-name invlab` es el nombre corto que aparece en los SMS y en algunos correos; tiene un
  límite de 12 caracteres.
- `--action email owner tu-correo@example.com` añade un receptor de tipo correo, con el nombre
  `owner` dentro del grupo y la dirección a la que avisa. **Pon la tuya**: el lab la anonimiza en las
  salidas.
- No hace falta `--location`: un action group es un recurso **global**, y la CLI usa `Global` por
  defecto.

```text
[PENDIENTE DE CORRIDA] JSON del action group con location "Global", groupShortName "invlab",
enabled true y un emailReceivers con el receptor "owner".
```

> 💰 **Costo.** El action group no cobra por existir. Sus notificaciones por correo tienen los
> primeros **1.000 al mes gratis** y después $0.00002 por correo en `eastus2`, según la Retail Prices
> API. Un lab no se acerca a ese número.

Al crearlo, Azure manda a la dirección un correo avisando de que fue añadida al action group, y **una
dirección nueva tiene que verificarse con un código de un solo uso (OTP) en los 30 minutos siguientes
a guardar el action group**; la verificación vale después para todos los action groups del mismo
tenant. Si el código caduca, se reenvía desde el propio action group. Sin verificar, la dirección no
recibe avisos: revisa el spam, porque es el mismo remitente que te enviará las alertas del budget.

---

## 7. 💰 El budget, y lo que de verdad hace

La decisión D8 de [`L00` §6](l00-idea-lab-practico.md#6--presupuesto-y-de-dónde-sale-el-gasto-que-no-esperabas)
fija el budget en **$5 al mes sobre la suscripción**, con alertas al 20 %, 50 % y 100 % del costo
real y al 100 % del pronosticado. Cinco veces el costo de la serie completa: si salta la primera
alerta, algo se quedó encendido.

**Por qué con `az rest` y no con un comando de primera clase.** El comando `az consumption budget
create` está en preview y no admite notificaciones, que es lo único que hace útil a un budget. La
API de `Microsoft.Consumption/budgets` sí, así que el budget se crea con un `PUT` directo. Es,
además, la mejor demostración del curso de que `az` y la API son lo mismo.

```bash
AG_ID=$(az monitor action-group show --name inv-lab-ag --resource-group inv-lab-rg --query id --output tsv)
START=$(date -u +%Y-%m-01)

az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Consumption/budgets/inv-lab-budget?api-version=2024-08-01" \
  --body "{
    \"properties\": {
      \"category\": \"Cost\",
      \"amount\": 5,
      \"timeGrain\": \"Monthly\",
      \"timePeriod\": { \"startDate\": \"${START}T00:00:00Z\" },
      \"notifications\": {
        \"actual20\":      { \"enabled\": true, \"operator\": \"GreaterThanOrEqualTo\", \"threshold\": 20,  \"thresholdType\": \"Actual\",     \"contactEmails\": [\"tu-correo@example.com\"], \"contactGroups\": [\"$AG_ID\"] },
        \"actual50\":      { \"enabled\": true, \"operator\": \"GreaterThanOrEqualTo\", \"threshold\": 50,  \"thresholdType\": \"Actual\",     \"contactEmails\": [\"tu-correo@example.com\"], \"contactGroups\": [\"$AG_ID\"] },
        \"actual100\":     { \"enabled\": true, \"operator\": \"GreaterThanOrEqualTo\", \"threshold\": 100, \"thresholdType\": \"Actual\",     \"contactEmails\": [\"tu-correo@example.com\"], \"contactGroups\": [\"$AG_ID\"] },
        \"forecasted100\": { \"enabled\": true, \"operator\": \"GreaterThanOrEqualTo\", \"threshold\": 100, \"thresholdType\": \"Forecasted\", \"contactEmails\": [\"tu-correo@example.com\"], \"contactGroups\": [\"$AG_ID\"] }
      }
    }
  }"
```

Cada pieza, porque el cuerpo es el recurso entero:

- **La URL es el scope.** `…/subscriptions/$SUB/providers/Microsoft.Consumption/budgets/inv-lab-budget`
  pone el budget sobre **la suscripción**, no sobre el resource group: vigila también lo que se
  cree fuera de `inv-lab-rg`, que es justo lo que se escapa. El nombre admite de 1 a 63 caracteres,
  letras, dígitos, guiones y guiones bajos.
- **`api-version=2024-08-01`** es una versión estable de la API, verificada en la referencia de
  plantillas de `Microsoft.Consumption/budgets`.
- **`category: Cost`** vigila dinero; **`amount: 5`** son dólares en la moneda de facturación.
- **`timeGrain: Monthly`** reinicia el conteo cada mes.
- **`timePeriod.startDate`** tiene que ser **el primer día de un mes**; se admite el mes en curso. El
  `date -u +%Y-%m-01` lo calcula. Sin `endDate`, la API lo fija a diez años después.
- **`notifications`** es un diccionario de hasta **cinco** avisos. Cada uno lleva un `threshold` en
  **porcentaje** del `amount` (de 0 a 1000), un `operator` y un `thresholdType`:
  `Actual` compara con lo gastado; `Forecasted`, con la **proyección** de gasto a fin de mes.
- **`contactEmails` y `contactGroups`** son los destinatarios. En el scope de suscripción basta uno de
  los dos; el lab pone ambos para no depender solo del action group. `contactGroups` exige el
  **resource ID completo** del action group, no su nombre.

```text
[PENDIENTE DE CORRIDA] JSON del budget con id .../providers/Microsoft.Consumption/budgets/inv-lab-budget,
amount 5, timeGrain Monthly, el startDate del mes en curso y las cuatro notificaciones.
```

Compruébalo leyendo lo que quedó:

```bash
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/providers/Microsoft.Consumption/budgets/inv-lab-budget?api-version=2024-08-01" \
  --query "{amount:properties.amount, grain:properties.timeGrain, alerts:keys(properties.notifications)}"
```

- `keys(...)` es la función de JMESPath que devuelve las claves de un objeto: aquí, los nombres de las
  cuatro notificaciones.

```text
[PENDIENTE DE CORRIDA] {"amount": 5.0, "grain": "Monthly", "alerts": ["actual20", "actual50",
"actual100", "forecasted100"]} (el orden de las claves puede variar).
```

Y ahora lo que el budget **no** hace, que es lo que se pregunta en una entrevista:

> ⚠️ **Un budget no es un tope de gasto.** Los recursos no se ven afectados y el consumo no se
> detiene. Los datos de costo tardan de 8 a 24 horas en aparecer, el budget se evalúa cada 24 horas,
> y en una suscripción nueva Cost Management puede tardar hasta 48 horas en estar disponible. Un
> budget te avisa de lo que olvidaste **ayer**, no de lo que estás encendiendo ahora.

Por eso la alerta que más vale en un lab es la de **pronóstico**: si un recurso olvidado cobra por
hora, la proyección a fin de mes cruza los $5 días antes de que lo haga el gasto real. Y por eso la
defensa de verdad sigue siendo el teardown escrito junto a cada recurso y el barrido de [`L09`](l09-costos-y-destruccion-verificada.md).

> 🧠 **Modelo mental.** Budget = alarma de humo. Spending limit = cortar el gas, y solo lo tienes con
> crédito. El teardown = no dejar la sartén en el fuego.

---

## 8. 🧱 Cost Management: dónde se mira el gasto

El budget avisa; **Cost analysis**, en el portal, explica. Es la vista de Cost Management que agrupa
el costo acumulado del mes por servicio, por resource group, por recurso o **por tag**, y es la que
usa [`L09`](l09-costos-y-destruccion-verificada.md) para atribuir el gasto de la serie. Hoy no hay
nada que ver: una suscripción nueva puede tardar hasta 48 horas en mostrar datos, y el lab no ha
gastado un centavo.

Lo que sí conviene saber desde hoy, porque condiciona cómo se etiqueta todo lo demás:

- **Los tags solo acompañan al costo mientras están puestos.** Cost Management los recibe en cada
  registro de uso, y la [documentación](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/understand-cost-mgt-data)
  es explícita: no se aplican a datos históricos. El costo de un recurso creado sin tag y etiquetado
  después no se reasigna hacia atrás. Por eso los tags van en el comando de creación, no "luego".
- **Lo que Azure crea por ti no lleva tu tag** —el workspace aleatorio de un Container Apps environment,
  `NetworkWatcherRG`—, así que agrupar solo por tag deja fuera justo lo inesperado. La vista por
  resource group y por servicio lo cubre.

---

## 9. 🧪 Teardown de este lab

Lo que dejaste montado, y qué hacer con cada cosa:

| Recurso | ¿Cobra? | Qué hacer al terminar la serie |
|---|---|---|
| Perfil `~/.azure-inv-lab` | No (es local) | `az logout` con el perfil activo y borrar el directorio a mano ([`L09`](l09-costos-y-destruccion-verificada.md)) |
| Providers registrados | No | Nada; no se desregistran |
| `inv-lab-rg` | No | Se borra en [`L09`](l09-costos-y-destruccion-verificada.md), con todo lo que contenga |
| `inv-lab-ag` | No, salvo más de 1.000 correos al mes | Muere con `inv-lab-rg` |
| `inv-lab-budget` | No | **Borrarlo aparte, antes que el grupo:** vive en la suscripción, no en el resource group |

Como nada de esto factura, el teardown **no es urgente**: el blindaje se queda puesto toda la serie,
que es para lo que sirve. Lo que sí se verifica ya es que no se coló nada:

```bash
az resource list --resource-group inv-lab-rg --query "[].{name:name, type:type}" --output table
az identity list --resource-group inv-lab-rg --output table
```

- El primero lista todo lo que hay en el grupo; el segundo confirma que la identidad de sonda de la
  sección 4 no sigue ahí.

```text
[PENDIENTE DE CORRIDA] Una sola fila en el primero: inv-lab-ag, de tipo
microsoft.insights/actionGroups. El segundo, vacío.
```

> ⚠️ **La letra pequeña del borrado, que hay que conocer desde hoy aunque se use en [`L09`](l09-costos-y-destruccion-verificada.md):**
> `az group delete` **no borra el budget**, porque está en el scope de la suscripción, y el budget se
> queda apuntando por `contactGroups` a un action group que ya no existe. El orden correcto es budget
> primero, grupo después.

---

## 📋 Checklist de salida

- [ ] `echo $AZURE_CONFIG_DIR` devuelve `~/.azure-inv-lab` en la terminal del lab.
- [ ] `az account show --query state -o tsv` devuelve `Enabled` y el id es el de la suscripción del lab.
- [ ] Provocaste `MissingSubscriptionRegistration` a propósito y sabes distinguirlo de `AuthorizationFailed` y de `NoRegisteredProviderFound`.
- [ ] `az provider list` muestra los doce providers de la serie en `Registered`.
- [ ] `az group show --name inv-lab-rg --query tags` devuelve `project=inv-lab` y `env=lab`.
- [ ] `az monitor action-group show --name inv-lab-ag --resource-group inv-lab-rg --query "emailReceivers[].emailAddress"` devuelve tu correo, y verificaste el código OTP que te llegó.
- [ ] El `GET` de la sección 7 devuelve el budget con sus cuatro notificaciones, una de ellas `Forecasted`.
- [ ] `az resource list --resource-group inv-lab-rg` devuelve **solo** el action group.

## 🏁 La señal de que quedó bien

`az resource list --tag project=inv-lab` devuelve un único recurso —`inv-lab-ag`—, el budget
`inv-lab-budget` existe sobre la suscripción con una alerta de pronóstico, y puedes explicar por qué
ese budget no va a impedir que gastes.

---

## 🧠 Preguntas rápidas

1. ¿Por qué el lab empieza con `export AZURE_CONFIG_DIR` y qué pasa si abres otra pestaña sin él?
2. ¿Qué diferencia hay entre el spending limit de la cuenta gratuita y un budget, y cuál de los dos existe en una suscripción pay-as-you-go?
3. ¿Qué es un resource provider y por qué una suscripción nueva no puede crear una managed identity sin más?
4. ¿Por qué el lab provoca `MissingSubscriptionRegistration` con `az rest` y no con `az identity create`?
5. ¿En qué se diferencia `MissingSubscriptionRegistration` de `NoRegisteredProviderFound`?
6. Registraste el provider y el siguiente comando falla con el mismo error. ¿Qué haces?
7. ¿Qué efecto secundario tiene registrar un provider que no vas a usar?
8. ¿Qué pasa si ejecutas `az group create` sobre un resource group que ya existe con otros tags?
9. ¿Los recursos de `inv-lab-rg` heredan sus tags? ¿Qué pone el curso en su lugar?
10. ¿Por qué el budget se crea en el scope de la suscripción y no en el del resource group?
11. ¿Por qué el budget se crea con `az rest` y qué exige el campo `contactGroups`?
12. ¿Qué diferencia hay entre una notificación `Actual` y una `Forecasted`, y cuál sirve más en un lab?
13. ¿Por qué un budget no te avisa del recurso que encendiste hace una hora?
14. ¿Qué sobrevive a `az group delete --name inv-lab-rg` de lo que creó este lab, y en qué orden se borra?

---

## 📚 Referencias oficiales

- Configuración de la CLI (`AZURE_CONFIG_DIR`): https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration
- Iniciar sesión de forma interactiva: https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively
- Administrar suscripciones con la CLI: https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
- Resource providers y tipos de recurso: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types
- Providers por servicio y los registrados por defecto: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-services-resource-providers
- Errores de registro de resource providers: https://learn.microsoft.com/en-us/azure/azure-resource-manager/troubleshooting/error-register-resource-provider
- Reglas de nombre de los recursos: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules
- Referencia de `az provider`: https://learn.microsoft.com/en-us/cli/azure/provider
- Referencia de `az group`: https://learn.microsoft.com/en-us/cli/azure/group
- Tags de recursos y resource groups: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources
- Action groups: https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups
- Referencia de `az monitor action-group`: https://learn.microsoft.com/en-us/cli/azure/monitor/action-group
- Crear y administrar budgets: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- Plantilla de `Microsoft.Consumption/budgets`: https://learn.microsoft.com/en-us/azure/templates/microsoft.consumption/budgets
- Spending limit: https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/spending-limit
- Cost analysis: https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/quick-acm-cost-analysis
- Precios de Azure Monitor (notificaciones): https://azure.microsoft.com/en-us/pricing/details/monitor/
