# A01 — `az` de supervivencia

> **Objetivo:** manejar la CLI de Azure sin pelearte con ella: el perfil aislado con
> `AZURE_CONFIG_DIR`, el login y la suscripción activa, los defaults, `--output`, `--query`, las
> operaciones de larga duración, `--debug`, `az rest` y los tokens a mano. Es el apéndice que se
> consulta desde cualquier lab.
> **Se asume leído:** nada. Si sabes abrir una terminal, alcanza. El porqué de cada pieza está en
> [`01`](01-infraestructura-global-y-resource-manager.md) (control plane, resource IDs) y
> [`09`](09-identidad-entra-id-y-managed-identities.md) (tokens).
> **Estado:** redactado, pendiente de corrida. Los bloques
> `[PENDIENTE DE CORRIDA]` dicen qué debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. CLI de referencia: **2.90.0**, la vigente en Learn a esa
> fecha.

**Salto rápido:** [Qué es `az`](#1--qué-es-az-y-qué-no-es) ·
[Instalación](#2--instalación-y-versión-fija) ·
[Perfil aislado](#3--el-perfil-aislado-azure_config_dir) ·
[Login y suscripción](#4--login-tenant-y-suscripción-activa) ·
[Defaults](#5--configuración-defaults-y-precedencia) ·
[`--output`](#6----output-la-salida-la-eliges-tú) ·
[`--query`](#7----query-jmespath-en-tu-máquina) ·
[Filtrar en el servidor](#8--filtrar-en-el-servidor-tags-tipos-y-resource-graph) ·
[Operaciones largas](#9--operaciones-de-larga-duración---no-wait-y-wait) ·
[`--debug`](#10----debug-y---verbose-el-microscopio) ·
[`az rest`](#11--az-rest-la-api-sin-intermediarios) ·
[Tokens](#12--tokens-a-mano-az-account-get-access-token) ·
[Extensiones](#13--extensiones) ·
[Errores de la CLI](#14--errores-que-son-de-la-cli-y-no-de-azure) ·
[Chuleta](#15--chuleta-de-una-página) ·
[Preguntas](#-preguntas-rápidas)

Este apéndice no tiene orden ni prerrequisitos: se entra por la sección que necesitas. Todo lo que
aparece aquí se usa en [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md)–[`L09`](l09-costos-y-destruccion-verificada.md), y casi todo en el primero.

---

## 1. 🧭 Qué es `az` y qué no es

`az` es un **cliente de las APIs REST de Azure** escrito en Python. Cada comando que gestiona un
recurso se traduce en una o varias peticiones HTTP a **Azure Resource Manager**
(`management.azure.com`), el control plane de [`01` §9](01-infraestructura-global-y-resource-manager.md#9--azure-resource-manager-y-el-resource-id):
`az group create` es un `PUT` sobre un resource ID, `az group show` un `GET`, `az group delete` un
`DELETE`. No hay magia ni un canal privado: lo que hace la CLI lo puedes hacer tú con `curl` y un
token, y §11 lo demuestra.

Dos matices que conviene fijar desde el principio:

- **Algunos comandos no hablan con ARM sino con el data plane del servicio.** `az storage blob upload`
  va a `invlab472913.blob.core.windows.net`; `az keyvault secret show`, a
  `inv-lab-kv-472913.vault.azure.net`. Son otros hosts, con otra audiencia de token y otros permisos
  (las `dataActions` de [`10` §3](10-autorizacion-rbac-policy-y-gobierno.md#3--role-definitions-actions-y-dataactions)).
  Cuando un comando de datos falla con `403` siendo Owner, casi siempre es eso.
- **Otros hablan con Microsoft Graph**, el API de Entra ID: `az ad app create`, `az ad sp show`. Las
  app registrations no son recursos de ARM y no viven en ninguna suscripción.

```text
az group / vm / containerapp / ...   →  management.azure.com       (control plane, ARM)
az storage blob / keyvault secret    →  <recurso>.<servicio>.net    (data plane del servicio)
az ad app / sp / user                →  graph.microsoft.com         (Entra ID)
```

> 🧠 **Modelo mental.** `az` no es "otra forma" de usar Azure distinta de la API: es la API con
> autocompletado. Todo lo que aprendes en la CLI se traduce uno a uno al SDK de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md).

---

## 2. 🧱 Instalación y versión fija

La [documentación de instalación para macOS](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos)
usa Homebrew:

```bash
brew update && brew install azure-cli
az version
```

- `brew install azure-cli` instala la CLI con su propio intérprete de Python empaquetado; no toca el
  Python de tu sistema. En Linux hay paquetes `apt` y `dnf`; en Windows, un MSI.
- `az version` imprime en JSON la versión de `azure-cli`, de su núcleo y de cada extensión instalada.
  Es lo primero que se pega en cualquier reporte de un fallo, porque los flags y los mensajes cambian
  entre versiones.

```text
[PENDIENTE DE CORRIDA] JSON con "azure-cli": "2.90.0", "azure-cli-core": "2.90.0",
"azure-cli-telemetry" y un objeto "extensions" (vacío si no instalaste ninguna).
```

Si prefieres no instalar nada en tu máquina, Microsoft publica la CLI como imagen de contenedor, con
la [misma versión etiquetada](https://learn.microsoft.com/en-us/cli/azure/run-azure-cli-docker):

```bash
docker run --rm -it \
  -v "$HOME/.azure-inv-lab:/root/.azure" \
  mcr.microsoft.com/azure-cli:2.90.0
```

- `mcr.microsoft.com/azure-cli:2.90.0` fija la versión exacta; **nunca `latest`**, por la misma razón
  que no se fija ninguna otra versión del curso con un comodín: el lab tiene que dar el mismo
  resultado el mes que viene. Hay variantes por arquitectura (`-amd64`, `-arm64`) si las necesitas.
- `-v "$HOME/.azure-inv-lab:/root/.azure"` monta el perfil aislado de §3 en el directorio donde la
  CLI del contenedor guarda su configuración, así la sesión sobrevive a `--rm`.
- `--rm -it` borra el contenedor al salir y te deja una shell interactiva dentro.

> 💡 **Truco.** `az upgrade` actualiza la CLI y, con `--all`, también las extensiones. En un lab que
> fija la versión no conviene usarlo a mitad de la serie: una actualización que cambia un flag entre
> [`L03`](l03-bicep-desde-la-cli.md) y [`L04`](l04-red-vnet-nsg-private-endpoint-y-dns.md) es un error que no es tuyo pero sí tienes que diagnosticar.

---

## 3. 🧱 El perfil aislado: `AZURE_CONFIG_DIR`

La CLI de Azure **no tiene perfiles con nombre**. Guarda la sesión, la lista de suscripciones, la
suscripción activa, los defaults y los logs en un único directorio, que por defecto es `~/.azure`. Si
usas la CLI para tu trabajo y para el lab con el mismo directorio, un `az account set` del lab cambia
la suscripción activa de tu trabajo, y un `az group delete` escrito con prisa puede caer donde no
debe.

La [variable `AZURE_CONFIG_DIR`](https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration)
apunta la CLI a otro directorio. El curso usa uno dedicado:

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
az account show
```

- `export` deja la variable fijada para todos los comandos de **esa terminal**. Otra pestaña, sin el
  `export`, vuelve a `~/.azure`: es exactamente lo que quieres, y también la forma más fácil de
  equivocarte de sesión. Por eso cada lab lo repite al empezar.
- La primera vez, el directorio no existe y la CLI lo crea. `az account show` falla pidiendo
  `az login`, porque es una sesión nueva y vacía.

```text
[PENDIENTE DE CORRIDA] Un error que pide ejecutar 'az login' para configurar la cuenta,
porque el perfil recién creado no tiene sesión.
```

Qué vive dentro de ese directorio, y por qué importa:

| Archivo o carpeta | Qué guarda | Por qué te importa |
|---|---|---|
| `config` | Los valores de `az config set` (§5), en formato INI | Los defaults del lab no contaminan tu perfil de trabajo |
| `azureProfile.json` | Las suscripciones conocidas y cuál está activa | Es lo que cambia `az account set` |
| Caché de tokens de MSAL | Los refresh tokens de tu sesión | **Es una credencial**: no se copia, no se versiona, no se comparte |
| `logs/`, `commands/` | Logs de cada comando | Útiles para diagnosticar; pueden llevar IDs de tu suscripción |

> ⚠️ **El directorio del perfil contiene tu sesión.** Quien copie ese directorio tiene tus refresh
> tokens hasta que caduquen o los revoques. No lo metas en un repositorio ni en una imagen de
> contenedor; si lo montas en Docker como en §2, que sea con un volumen local.

La [documentación de extensiones](https://learn.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview)
ubica las extensiones en `$HOME/.azure/cliextensions` salvo que la variable `AZURE_EXTENSION_DIR`
diga otra cosa. Con un perfil aislado, comprueba con `az extension list` (campo `path`) dónde
quedaron antes de dar por hecho que están separadas de las de tu trabajo.

---

## 4. 🧱 Login, tenant y suscripción activa

```bash
az login
```

- En macOS y Linux abre el navegador y hace un flujo authorization code con tu cuenta de Entra ID;
  si no puede abrir un navegador, cae al flujo device code. Con `--use-device-code` lo fuerzas: la
  CLI te da un código para introducir en `https://aka.ms/devicelogin` desde cualquier dispositivo.
- Desde la versión 2.61.0, si tu cuenta ve varias suscripciones, **te muestra un selector** para
  elegir la activa al terminar el login. Se desactiva con
  `az config set core.login_experience_v2=off`.
- `--tenant <id o dominio>` fuerza el tenant. Hace falta cuando tu cuenta es invitada en varios
  tenants y el login "entra" en el que no era: el síntoma es no ver la suscripción del lab.

> 📝 **Contexto.** Desde septiembre de 2025 Microsoft exige MFA en la CLI y en las demás
> herramientas de línea de comandos para las **identidades de usuario**; las identidades de carga
> (service principals, managed identities) no se ven afectadas. Por eso `az login --user ...
> --password ...` ya no es una opción para automatizar: un pipeline se autentica con OIDC
> ([`16` §5](16-orquestacion-y-cicd.md#5--github-actions-con-oidc)), no con tu usuario.

Después del login, la pregunta que evita la mitad de los sustos:

```bash
az account show --query "{name:name, id:id, tenantId:tenantId, user:user.name}" --output table
```

- `az account show` devuelve la **suscripción activa**: la que usará todo comando que no reciba
  `--subscription`. El `--query` de §7 recorta la respuesta a los cuatro campos que importan.

```text
[PENDIENTE DE CORRIDA] Una fila con el nombre de la suscripción del lab, su id
(anonimizado como 11112222-3333-4444-5555-666677778888), el tenant
(aaaabbbb-0000-cccc-1111-dddd2222eeee) y tu usuario.
```

Si no es la del lab:

```bash
az account list --output table
az account set --subscription 11112222-3333-4444-5555-666677778888
```

- `az account list` enseña las suscripciones que la sesión conoce, con una columna `IsDefault`. Con
  `--refresh` vuelve a pedirlas a Azure, útil si te acaban de dar acceso a una.
- `az account set --subscription` acepta el id o el nombre. **Usa el id**: dos suscripciones pueden
  llamarse igual, y el id no cambia si alguien la renombra.

> 🧠 **Modelo mental.** La sesión de `az` tiene dos niveles: **quién eres** (el usuario y su tenant)
> y **dónde operas** (la suscripción activa). `az login` fija los dos; `az account set` solo el
> segundo. Casi todos los "el recurso no existe" de un lab son el segundo nivel equivocado.

`az logout` cierra la sesión del perfil activo; `az account clear` borra además la lista de
suscripciones en caché y obliga a volver a iniciar sesión.

---

## 5. 🧱 Configuración, defaults y precedencia

`az config set` guarda valores en el archivo `config` del perfil. Los que más se usan son los
defaults de argumentos:

```bash
az config set defaults.group=inv-lab-rg defaults.location=eastus2
az config get defaults
```

- `defaults.group` y `defaults.location` hacen que `--resource-group` y `--location` dejen de ser
  obligatorios: si no los pasas, la CLI usa estos.
- `az config get defaults` muestra lo que quedó guardado. `az config unset defaults.group` lo quita.

La [precedencia](https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration) es fija, de
más fuerte a más débil:

```text
1. El argumento en la línea de comandos        --resource-group otro-rg
2. La variable de entorno                      AZURE_DEFAULTS_GROUP=otro-rg
3. El archivo de configuración (az config)     defaults.group=inv-lab-rg
```

Cualquier clave del archivo tiene su variable de entorno con la forma `AZURE_{SECCIÓN}_{NOMBRE}` en
mayúsculas: `core.output` es `AZURE_CORE_OUTPUT`, `defaults.location` es `AZURE_DEFAULTS_LOCATION`.

> ⚠️ **Los labs del curso escriben `--resource-group` y `--location` siempre, aunque tengas
> defaults.** Un default es invisible: el comando que copias de un lab funciona en tu terminal y
> falla —o peor, cae en otro grupo— en la de otra persona. Los defaults son para tu comodidad
> interactiva, no para un documento.

Otras claves útiles de la sección `core`:

| Clave | Efecto |
|---|---|
| `core.output` | Formato de salida por defecto (§6) |
| `core.only_show_errors` | Oculta los avisos de comandos en preview o deprecados |
| `core.collect_telemetry` | Activa o desactiva la telemetría anónima de uso de la CLI |
| `core.login_experience_v2` | El selector de suscripción de `az login` |
| `core.disable_confirm_prompt` | Quita las confirmaciones (`Are you sure?`). **No en un lab** |

---

## 6. 🧱 `--output`: la salida la eliges tú

Todo comando acepta `--output` (o `-o`) con siete valores: `json` (por defecto), `jsonc` (JSON con
color), `yaml`, `yamlc`, `table`, `tsv` y `none`.

```bash
az group list --output table
az group show --name inv-lab-rg --query id --output tsv
az group create --name inv-lab-rg --location eastus2 --output none
```

- `table` es para leer. Muestra solo algunas columnas y **no es estable**: no la parsees nunca.
- `tsv` es para scripts: valores separados por tabuladores, sin comillas ni cabecera. Combinado con
  un `--query` que devuelve un solo valor, da exactamente el string que quieres guardar en una
  variable.
- `none` no imprime nada. Útil en comandos cuyo JSON de respuesta es largo y no te interesa; los
  errores siguen saliendo por `stderr`.

El patrón que más vas a repetir en la serie:

```bash
# el resource ID completo del resource group, en una variable
RG_ID=$(az group show --name inv-lab-rg --query id --output tsv)
echo "$RG_ID"
```

```text
[PENDIENTE DE CORRIDA] /subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/inv-lab-rg
```

> ⚠️ **`--output json` con `jq` funciona, pero no lo necesitas.** `--query` hace lo mismo sin otra
> dependencia y con la misma sintaxis en todos los labs. Si usas `jq`, que sea para algo que JMESPath
> no hace bien, como modificar un documento.

---

## 7. 🧱 `--query`: JMESPath en tu máquina

`--query` recibe una expresión [JMESPath](https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-query)
que se aplica a la respuesta JSON **en tu máquina, después de recibirla**. No filtra en el servidor:
si la respuesta tiene diez mil elementos, los diez mil viajan por la red. §8 explica cuándo importa.

Cinco formas cubren casi todo:

```bash
# 1. un campo
az group show --name inv-lab-rg --query location

# 2. el mismo campo de todos los elementos de una lista
az group list --query "[].name"

# 3. filtrar con una condición: [?...]
az resource list --query "[?tags.project=='inv-lab'].name"

# 4. proyectar varios campos con nombre: {alias:campo}
az resource list --query "[].{name:name, type:type, rg:resourceGroup}" --output table

# 5. contar
az resource list --query "length([?tags.project=='inv-lab'])"
```

- En la forma 3, las comillas simples van **dentro** de las dobles: el literal de JMESPath es
  `'inv-lab'` y la shell necesita las dobles para no partir la expresión. En zsh y bash esto funciona
  igual; en PowerShell el escapado cambia.
- En la forma 4, el alias es el nombre de la columna con `--output table`. Es la forma legible de
  inspeccionar recursos sin la columna gigante de `id`.
- `[?...]` acepta `==`, `!=`, `<`, `>`, `&&`, `||` y funciones como `contains(name, 'inv')` o
  `starts_with(name, 'inv-')`.

```text
[PENDIENTE DE CORRIDA] Forma 1: "eastus2". Forma 2: una lista JSON con los nombres de los
resource groups. Forma 5: un número entero.
```

> 💡 **Truco.** Para diseñar una consulta, corre el comando con `--output json` una vez, mira la
> forma real del documento y escribe el `--query` sobre eso. La documentación a veces enseña un
> campo que tu versión de la API devuelve con otro nombre o anidado en `properties`.

---

## 8. 🧱 Filtrar en el servidor: tags, tipos y Resource Graph

Cuando la lista es grande, lo correcto es pedirle menos al servidor en vez de filtrar después. Varios
comandos tienen filtros propios que viajan en la petición:

```bash
az resource list --tag project=inv-lab --output table
az resource list --resource-group inv-lab-rg --resource-type Microsoft.Storage/storageAccounts
az group list --tag project=inv-lab --output table
```

- `--tag project=inv-lab` devuelve solo los recursos con ese tag, en **toda la suscripción**. Es el
  barrido de cierre de cada lab y del plan §6.5: lo que no lleve el tag no aparece, y por eso los tags
  son obligatorios desde [`L01`](l01-suscripcion-cli-aislada-y-blindaje-de-costos.md).
- `--resource-type` usa el tipo completo `Proveedor/tipo`, el mismo que aparece en el resource ID.

> ⚠️ **Un barrido por tag demuestra lo que etiquetaste, no lo que existe.** Un recurso que Azure creó
> por ti —el workspace aleatorio de un Container Apps environment, el `NetworkWatcherRG`— no lleva tu
> tag. El barrido completo de [`L09`](l09-costos-y-destruccion-verificada.md) combina el tag con
> `az group list` y con lo soft-deleted.

Para consultas sobre todo el inventario, en todas tus suscripciones y en segundos, está **Azure
Resource Graph**, que usa KQL ([`14` §9](14-observabilidad-monitor-log-analytics-app-insights.md#9--resource-graph-service-health-y-resource-health)).
Su comando vive en una extensión (§13):

```bash
az extension add --name resource-graph --version 2.1.1
az graph query --graph-query "Resources | where tags.project == 'inv-lab' | project name, type, location"
```

- `az extension add --name resource-graph --version 2.1.1` instala la extensión que aporta `az graph`,
  con la versión fija que publicaba el índice oficial de extensiones a la fecha de vigencia.
- `--graph-query` recibe KQL, no JMESPath: filtra en el servidor, sobre el índice de Resource Graph,
  que puede ir unos segundos por detrás del estado real tras un cambio.

---

## 9. 🧱 Operaciones de larga duración: `--no-wait` y `wait`

Muchas operaciones de ARM no terminan en la respuesta: un `PUT` o un `DELETE` devuelven `201` o `202`
con una URL para consultar el estado, y el recurso se crea o se borra después. `az` **espera por ti**
consultando esa URL hasta que termina, por eso parece síncrono. Con `--no-wait` no espera:

```bash
az group delete --name inv-drill-rg --yes --no-wait
az group wait --name inv-drill-rg --deleted --timeout 1800
```

- `--yes` se salta la confirmación interactiva de `az group delete`. Se usa en un lab porque el
  comando está escrito y revisado; **nunca en un alias ni en un script que no hayas leído**.
- `--no-wait` devuelve el control en cuanto ARM acepta la petición. El borrado sigue en Azure.
- `az group wait --deleted` bloquea hasta que el grupo deja de existir. `--timeout` está en segundos;
  si se agota, el comando falla pero el borrado sigue.

> 🧠 **Modelo mental.** `--no-wait` no hace nada más rápido: solo te devuelve la terminal. Úsalo para
> lanzar varias operaciones independientes en paralelo y después esperar a todas; no lo uses para
> "terminar antes" un teardown que tienes que verificar.

---

## 10. 🩺 `--debug` y `--verbose`: el microscopio

`--verbose` añade información de progreso. `--debug` imprime en `stderr` **todo** lo que hace la CLI,
y lo que importa está en las líneas de la
[política HTTP del SDK](https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-troubleshooting):

```bash
az group show --name inv-lab-rg --debug 2>&1 | grep -E "Request URL|Request method|Response status"
```

- `2>&1` junta `stderr` con `stdout` para poder filtrar con `grep`, porque `--debug` escribe en
  `stderr`.
- `Request URL` es la URL completa sobre `management.azure.com`, con el resource ID y el
  `api-version`. `Request method` es el verbo HTTP. `Response status` es el código que devolvió ARM.

```text
[PENDIENTE DE CORRIDA] Tres líneas: la URL GET sobre
https://management.azure.com/subscriptions/11112222-3333-4444-5555-666677778888/resourcegroups/inv-lab-rg
con su ?api-version=..., el método 'GET' y el estado 200.
```

Con eso ves tres cosas que ninguna documentación te dice tan rápido: **a qué host habla** el comando
(control plane o data plane), **qué versión de API** usa tu CLI para ese tipo de recurso, y **qué
código devolvió** de verdad antes de que la CLI lo convirtiera en un mensaje.

> ⚠️ **Nunca pegues una salida de `--debug` sin revisarla.** Lleva los IDs de tu suscripción y tu
> tenant, tu usuario, y los cuerpos de las peticiones, que pueden llevar secretos. La CLI enmascara la
> cabecera `Authorization`, pero no todo lo demás.

---

## 11. 🧱 `az rest`: la API sin intermediarios

`az rest` hace una petición HTTP arbitraria **con el token de tu sesión ya puesto**. Sirve para dos
cosas: repetir a mano lo que viste en `--debug`, y llamar a una API para la que no hay comando, como
ocurre con Microsoft Graph en [`L06`](l06-identidad-de-aplicaciones-api-protegida.md).

```bash
SUB=$(az account show --query id --output tsv)
az rest --method get \
  --url "https://management.azure.com/subscriptions/$SUB/resourceGroups/inv-lab-rg?api-version=2022-09-01"
```

- `--method` es el verbo HTTP: `get`, `put`, `patch`, `post` o `delete`.
- `--url` es la URL completa, y en ARM el `api-version` es **obligatorio**. Aquí se fija `2022-09-01`
  para `resourceGroups`; en un recurso nuevo, sale de `--debug` o de la referencia de la API.
- Si la URL empieza por un endpoint conocido de la nube (`management.azure.com`,
  `graph.microsoft.com`), `az rest` **deduce la audiencia del token** a partir de ella. Para otro
  servicio se la dices con `--resource`.
- `--body` lleva el JSON de la petición en un `put`, `patch` o `post`; si es JSON válido, la cabecera
  `Content-Type: application/json` se pone sola.

```text
[PENDIENTE DE CORRIDA] El mismo JSON que devuelve az group show: id, name, type
"Microsoft.Resources/resourceGroups", location "eastus2", tags y provisioningState.
```

> 🧠 **Modelo mental.** `az group show` y este `az rest` son la misma petición. Cuando lo ves con tus
> propios ojos, escribir la llamada en el SDK de [`A04`](a04-rutina-de-recurso-cli-api-y-destruccion.md) deja de ser leer documentación y pasa a ser
> traducir.

---

## 12. 🧱 Tokens a mano: `az account get-access-token`

Antes de dejar que `DefaultAzureCredential` lo haga por ti, conviene ver un token de verdad, como
pide [`09` §7](09-identidad-entra-id-y-managed-identities.md#7--tokens):

```bash
az account get-access-token --resource https://storage.azure.com/ --query accessToken --output tsv \
  | cut -d. -f2 \
  | python3 -c "import sys,base64,json; p=sys.stdin.read().strip(); p+='='*(-len(p)%4); print(json.dumps({k:v for k,v in json.loads(base64.urlsafe_b64decode(p)).items() if k in ('aud','iss','oid','scp','roles','exp')}, indent=2))"
```

- `--resource https://storage.azure.com/` pide un token **para el data plane de Storage**. Sin
  `--resource`, el token es para ARM (`https://management.azure.com/`), y el data plane lo rechaza
  aunque la firma sea válida: esa es la pregunta 14 de `09`. `--scope` es la forma moderna de pedir lo
  mismo (`https://storage.azure.com/.default`).
- `cut -d. -f2` se queda con el payload, la parte central de las tres del JWT.
- El `python3` decodifica el payload, que va en base64url sin relleno (de ahí el `'='*(-len(p)%4)`),
  y **filtra solo los claims que interesan**. El token entero no se imprime nunca.

```text
[PENDIENTE DE CORRIDA] Un JSON con "aud": "https://storage.azure.com", "iss" terminado en el
tenant, tu "oid", "scp" con user_impersonation y "exp" como timestamp POSIX.
```

> ⚠️ **Un access token es una credencial al portador.** Quien lo tenga lo usa hasta que caduque, sin
> más pruebas. No lo pegues en un chat, en un issue ni en un decodificador web: el `python3` de arriba
> lo decodifica en tu máquina.

---

## 13. 🧱 Extensiones

Parte de los comandos de `az` no viene en la instalación base: se añaden como
[extensiones](https://learn.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview), paquetes de
Python que la CLI carga como si fueran propios.

```bash
az extension list-available --output table
az extension add --name resource-graph --version 2.1.1
az extension list --output table
```

- `az extension list-available` lista las extensiones que publica Microsoft.
- `az extension add --name` instala una; `--version` fija una versión concreta, que es lo que hace un
  lab reproducible.
- `az extension list` muestra las instaladas, su versión y su ruta.

La CLI puede **instalar una extensión sola** la primera vez que usas uno de sus comandos, según el
valor de `extension.use_dynamic_install` (`no`, `yes_prompt` o `yes_without_prompt`). El curso
prefiere la instalación explícita: un lab que instala cosas sin decirlo no es reproducible.

> 📝 **Contexto.** Una misma familia de comandos puede tener una parte en el núcleo y otra en una
> extensión. `az containerapp create` es parte del núcleo de la CLI; la extensión `containerapp`
> añade comandos y argumentos en preview. Si un flag de la documentación "no existe" en tu terminal,
> mira en la referencia si la página lo marca como *Extension* y *Preview*.

---

## 14. 🩺 Errores que son de la CLI y no de Azure

No todo error viene de Azure. Estos nacen en tu terminal, antes de que salga ninguna petición, y se
reconocen porque `--debug` no muestra ninguna `Request URL`:

| Síntoma | Causa típica | Qué haces |
|---|---|---|
| `unrecognized arguments` | Un flag mal escrito, de otra versión, o una continuación de línea `\` con un espacio detrás | `az <comando> --help` y `az version` |
| `the following arguments are required` | Falta un argumento obligatorio y no hay default que lo cubra | Pásalo explícito (§5) |
| `Invalid jmespath_type value` | Comillas mal anidadas en `--query` | Comillas simples dentro de dobles (§7) |
| Pide `az login` aunque ya lo hiciste | Otra terminal, sin el `export AZURE_CONFIG_DIR`: estás en otro perfil | `echo $AZURE_CONFIG_DIR` |
| El recurso "no existe" y sabes que existe | Suscripción activa equivocada | `az account show` (§4) |
| `Interactive authentication is needed` | La sesión caducó o una política exige MFA | `az login` otra vez |

Y los que sí vienen de Azure tienen su catálogo, con la causa y el comando que la confirma, en
[`A03`](a03-catalogo-de-errores-y-diagnostico.md).

---

## 15. 🧭 Chuleta de una página

```text
Perfil y sesión
  export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"     perfil aislado (en cada terminal)
  az login [--tenant <id>] [--use-device-code]       quién eres
  az account show / list / set --subscription <id>   dónde operas
  az logout / az account clear                       cerrar y olvidar

Configuración
  az config set defaults.group=... defaults.location=...
  az config get / unset                              AZURE_{SECCION}_{NOMBRE} en variables

Salida
  --output json|jsonc|yaml|table|tsv|none            tsv para scripts, table para leer
  --query "[?tags.project=='inv-lab'].{n:name,t:type}"   JMESPath, en tu máquina

Inventario
  az resource list --tag project=inv-lab             filtro en el servidor
  az graph query --graph-query "Resources | ..."     Resource Graph (extensión)

Largas y diagnóstico
  --no-wait  +  az <grupo> wait --created|--deleted
  --debug 2>&1 | grep -E "Request URL|Request method|Response status"
  az rest --method get --url "https://management.azure.com/...?api-version=..."
  az account get-access-token --resource <audiencia> --query accessToken -o tsv

Extensiones
  az extension add --name <nombre> [--version x.y.z]
```

---

## 🧠 Preguntas rápidas

1. ¿Por qué el curso usa `AZURE_CONFIG_DIR` en vez de un perfil con nombre, y qué deja de funcionar si abres otra terminal sin el `export`?
2. ¿Qué guarda el directorio del perfil que lo convierte en una credencial?
3. ¿Qué diferencia hay entre lo que fija `az login` y lo que fija `az account set`?
4. Tienes `defaults.group=inv-lab-rg` y exportas `AZURE_DEFAULTS_GROUP=otro-rg`. ¿En qué grupo cae un comando sin `--resource-group`?
5. ¿Por qué no debes parsear `--output table` en un script, y qué usas en su lugar?
6. ¿`--query` filtra en el servidor? ¿Qué usas cuando la lista es enorme?
7. ¿Qué te enseña un barrido con `az resource list --tag project=inv-lab` y qué no puede enseñarte?
8. ¿Qué hace exactamente `--no-wait` y qué no hace?
9. ¿Qué tres datos buscas en la salida de `--debug` y por qué no la pegas tal cual?
10. ¿Cómo sabe `az rest` para qué audiencia pedir el token, y cuándo tienes que decírselo?
11. Pides un token con `az account get-access-token` sin `--resource` y el data plane de Storage lo rechaza. ¿Por qué?
12. Un flag que aparece en la documentación da `unrecognized arguments` en tu terminal. ¿Qué dos cosas revisas?

---

## 📚 Referencias oficiales

- Instalar la CLI en macOS: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos
- Ejecutar la CLI en un contenedor Docker: https://learn.microsoft.com/en-us/cli/azure/run-azure-cli-docker
- Configuración de la CLI (`AZURE_CONFIG_DIR`, `az config`, variables de entorno): https://learn.microsoft.com/en-us/cli/azure/azure-cli-configuration
- Iniciar sesión de forma interactiva: https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively
- Administrar suscripciones con la CLI: https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
- Formatos de salida: https://learn.microsoft.com/en-us/cli/azure/format-output-azure-cli
- Consultas JMESPath con `--query`: https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-query
- Consejos de uso (operaciones asíncronas, `--ids`): https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-tips
- Troubleshooting y `--debug`: https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-successfully-troubleshooting
- Usar la API REST con `az rest`: https://learn.microsoft.com/en-us/cli/azure/use-azure-cli-rest-command
- Referencia de comandos globales (`az rest`, `az login`, parámetros globales): https://learn.microsoft.com/en-us/cli/azure/reference-index
- Referencia de `az account`: https://learn.microsoft.com/en-us/cli/azure/account
- Referencia de `az resource`: https://learn.microsoft.com/en-us/cli/azure/resource
- Referencia de `az group`: https://learn.microsoft.com/en-us/cli/azure/group
- Extensiones de la CLI: https://learn.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview
- Referencia de `az graph`: https://learn.microsoft.com/en-us/cli/azure/graph
