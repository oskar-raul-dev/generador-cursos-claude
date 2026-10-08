# ✍️ Guía de estilo, tono y convenciones
## Azure Core Refresh — repaso para entrevistas y serie práctica de labs

Esta guía es la fuente de verdad editorial de `repaso-entrevistas/cloud/03-azure/`. Cualquier
chat que produzca o edite un `.md` de este curso la sigue. Su objetivo es que todos los
documentos —capítulos teóricos, solucionario, labs, apéndices, el encuadre de la serie
práctica y el README— se lean como escritos por la misma mano y apunten al mismo lugar:
**que el lector pueda explicar y defender una decisión de arquitectura en Azure, no que
recuerde nombres de servicios**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que
mañana tiene una entrevista de arquitectura y pasado mañana tiene que diseñar de
verdad el sistema del que habló.

> 📝 **Linaje y divergencias.** Esta guía desciende de la de `02-gcp/` —que a su vez
> desciende de la de `01-aws/` y del curso `docker-container-legacy`— y hereda de ella
> todo lo que no se declara aquí. Diverge de su madre en seis puntos, y cada uno se
> desarrolla en la sección indicada:
>
> 1. **La unidad de destrucción es el resource group**, no el proyecto ni la suscripción
>    (§7.1). Cambia cómo se escriben todos los teardowns.
> 2. **La IaC del curso es Bicep**, nativa del proveedor, como CloudFormation en AWS; Terraform
>    aparece solo en la sección comparativa de `15-bicep-iac.md` (§4.4, §10.1).
> 3. **El nombre de recurso no siempre puede ser kebab-case**: varios tipos de recurso de
>    Azure prohíben el guion o exigen unicidad global, y el baseline lo asume (§5).
> 4. **El puente CLI→API se enseña con `--debug` y `az rest`**, no con `--log-http` (§8.1).
> 5. **La regla de "no traducir desde otra nube" se extiende a AWS y a GCP** (§3.1).
> 6. **Los emuladores oficiales existen y son varios** (Azurite, Cosmos DB, Service Bus),
>    así que la doctrina de reparto tiene más que decir sobre qué miente cada uno (§7.1).

> 📝 **Inventario del curso.** Diecisiete capítulos teóricos (`01`–`17`), la simulación de
> entrevista (`18`), el solucionario (`19-respuestas.md`), la serie práctica (`L00`–`L09`) y
> cinco apéndices (`A01`–`A05`). El inventario con nombres de archivo vive en
> `README.md`; el alcance de cada capítulo, en `prompt-base.md` §2.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca, explique, compare y decida.**

No enseñamos Azure "completo": el catálogo pasa de los doscientos servicios, cambia de
nombre con frecuencia y memorizarlo no hace a nadie mejor arquitecto. Repasamos el
vocabulario, los mecanismos y los matices que separan a quien entiende el modelo de quien
aprendió la lista. En la serie práctica, además, formamos una capacidad concreta:
**encender infraestructura desde la CLI y desde Bicep, romperla a propósito,
diagnosticarla y destruirla con certeza**.

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, explicar, comparar o
decidir?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada comando se explica. Cada flag se explica. Cada decisión responde a
> "¿por qué estamos haciendo esto y qué pasaría si no?".

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que
ya se quemó con esto —un `AuthorizationFailed` que no era falta de rol sino un role
assignment que todavía no había propagado, un `MissingSubscriptionRegistration` por un
resource provider sin registrar, un `az group delete` que terminó bien y aun así dejó el
nombre del Key Vault secuestrado noventa días por el soft-delete— y te lo explica con
paciencia y sin solemnidad de manual corporativo.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"fíjate en qué
  recursos marca el `what-if` con `-` antes de confirmar"*, *"si esto te suena raro, es
  porque todavía no vimos la diferencia entre los roles de Entra ID y los de Azure RBAC;
  aguanta dos secciones"*. Nada de voseo, nada de "usted", nada de impersonal permanente
  ("se debe configurar…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero
  abreviaturas de mensajería.
- **Humor mínimo y seco.** Un 😉 bien puesto para desdramatizar una fricción real —la
  fe ciega en `--yes`, el enésimo "espera cinco minutos y vuelve a intentar"— y nada más.
  Regla práctica: **como mucho un desdramatizador por documento**, y si no fluye solo, se
  borra.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es una
  sobregeneralización —"Service Bus garantiza exactly-once", "Cosmos DB es multi-modelo,
  así que eliges la API al consultar", "Azure AD y Azure RBAC son lo mismo", "un resource
  group es una carpeta", "una VM sin IP pública no sale a Internet"— se nombra la
  simplificación y se da la versión precisa. **Este es el recurso pedagógico central del
  curso**, por encima de la analogía y del ejemplo.
- **Honesto sobre el dinero.** Cada recurso que cobra por hora se nombra con su precio y
  su unidad. No hay eufemismos tipo "costo reducido": o entra en una oferta gratuita y se
  dice cuál y con qué cuota exacta, o cuesta tanto por hora, o se dice que no se verificó.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
  "Como para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar Azure". Quien lee
  ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código o
  salida de terminal.
- **Los nombres de productos, features y términos del stack se quedan en inglés** cuando
  son el nombre real de la cosa: *Region*, *Availability Zone*, *resource group*, *role
  assignment*, *managed identity*, *service principal*, *private endpoint*, *partition
  key*, *Request Units*, *peek-lock*, *eventually consistent*, *cold start*, *drift*.
  Traducirlos forzadamente ("identidad administrada", "punto de conexión privado")
  confunde y no es lo que el lector va a ver en `az`, en Bicep ni en los mensajes de
  error — aunque sea lo que muestra la traducción automática de la documentación y del
  portal en español. Los que ya tienen traducción asentada —región, cola, rol,
  suscripción, inquilino— pueden alternar con naturalidad; lo importante es no inventar
  vocabulario.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de
  preferencia es diagrama ASCII → tabla → lista → párrafo *para exponer una relación entre
  cosas*. Pero el **porqué** de una decisión se escribe en prosa: una tabla no puede
  explicar por qué un `az group delete` exitoso te deja un Key Vault en estado
  soft-deleted que te impide reutilizar el nombre, ni por qué borrar un role assignment no
  corta el acceso de un token ya emitido.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos lados,
  es un buen golpe de ritmo. Tres seguidas ya no son ritmo: son un telegrama. Regla
  práctica: **una frase aislada por sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Es el recurso visual principal del curso, y
  se usa sin timidez para la jerarquía Management group → Subscription → Resource group →
  Resource, flujos de tráfico, la resolución DNS de un private endpoint y máquinas de
  estados. Simples: cajas, flechas, texto. Sin arte ASCII elaborado.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma: "App
  Service vs Container Apps", "Azure SQL Database vs PostgreSQL Flexible Server", "qué
  cobra por hora y qué entra en una oferta gratuita", necesidad→servicio. **La excepción
  legítima es la matriz que enfrenta cuatro alternativas a un criterio** —Storage Queues vs
  Service Bus vs Event Grid vs Event Hubs, los cinco niveles de consistencia de Cosmos DB,
  Load Balancer vs Application Gateway vs Front Door vs Traffic Manager—, donde cinco o
  seis columnas son la forma natural del contenido. **Si necesitas explicar una celda, ya
  no es una tabla.** Nunca se narra en tabla.
- **Salida de terminal literal.** Cuando se muestra lo que imprime un comando, se muestra
  tal como sale, en bloque ` ```text ` o ` ```json `, sin embellecer y sin recortar la
  parte incómoda. Los identificadores se anonimizan siempre con los valores del baseline
  de §5.1 —suscripción `11112222-3333-4444-5555-666677778888`, tenant
  `aaaabbbb-0000-cccc-1111-dddd2222eeee`— y los resource IDs completos
  (`/subscriptions/…/resourceGroups/…/providers/Microsoft.App/containerApps/…`) mantienen
  su forma real, porque leerlos es una habilidad que el curso entrena.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, ninguno en las
  subsecciones `###`. El emoji es funcional: señala de qué tipo es la sección
  (🧭 encuadre, 🧱 mecanismo, ⚖ comparación, 🩺 diagnóstico, 💰 costo, 🧪 verificación,
  📚 referencias).

### 3.1 El curso es autocontenido y no traduce desde otra nube

Este curso **no asume que el lector sabe AWS ni GCP**, aunque viva junto a `01-aws/` y
`02-gcp/`. Cada concepto se explica desde cero. **No se agregan tablas de mapeo
AWS→Azure ni GCP→Azure, ni frases del tipo "esto es como el IAM de AWS" o "el resource
group es el proyecto de GCP".** Cuando un concepto de Azure diverge de la intuición típica
de quien viene de otra nube —que la identidad vive en un servicio aparte (Entra ID) y no
dentro de la plataforma de recursos, que la VNet es regional, que el resource group tiene
una región propia que no restringe la de sus recursos, que la DLQ de Service Bus viene
incluida en cada entidad— se explica como una propiedad de Azure en sí misma, no como
contraste con otro proveedor.

La única excepción admitida está en `l00-idea-lab-practico.md`, en la sección que sitúa
esta serie dentro del repositorio, que puede nombrar los otros cursos por su nombre.
Nombrarlos no es traducir conceptos.

> 🧠 **Por qué la regla es más importante aquí que en los cursos hermanos.** Azure es la
> nube donde la analogía importada rompe más cosas: quien piensa "el IAM de Azure" no ve
> que hay dos planos de autorización (Entra ID y Azure RBAC), y quien piensa "la VPC de
> Azure" no entiende por qué el peering hace falta entre dos regiones propias.

---

## 4. 🎓 Pedagogía: "como para un bebé"

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar.
Se explica qué es una managed identity, en qué se diferencia de un service principal con
secreto, en qué scope se hace el role assignment y qué error exacto sale cuando lo haces
en el scope equivocado. No se dice "asigna el rol correcto" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el servicio, muestra el dolor que resuelve.
   *"Tu app en Container Apps escribe en Cosmos DB, Service Bus vuelve a entregar el
   mensaje porque el lock expiró antes del `complete`, y ahora tienes el mismo movimiento
   de inventario contado dos veces. ¿Qué le pones delante?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para
   usarlo hoy, no el capítulo completo de la documentación.
3. **El comando, el Bicep o la salida que corre.** El fragmento más pequeño que demuestra
   el punto, con su salida esperada.

Presentar el servicio antes que el problema produce gente que sabe recitar "Event Grid es
para eventos y Service Bus para mensajes" y no sabe cuál elegir cuando el consumidor
necesita procesar en orden por cliente.

### 4.2 Ningún comando ni ningún flag queda sin explicar

Esta es la regla más importante de la sección y no admite excepciones.

Cada comando de `az`, cada bloque de Bicep y cada `az deployment` que aparezca en un lab o
en un apéndice se acompaña de qué hace, qué significan sus flags no obvios y qué pasa si
los omites o los pones mal. Los flags ya explicados (`--resource-group`, `--location`) no
se repiten en cada aparición, pero **el primero de su tipo en el curso se explica
entero**.

```bash
az storage account create \
  --name invlab472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku Standard_LRS \
  --allow-blob-public-access false \
  --allow-shared-key-access false
```

- `--name invlab472913` no lleva guiones porque **el nombre de una storage account solo
  admite de 3 a 24 minúsculas y dígitos, y es único en todo Azure**: se convierte en el
  host `invlab472913.blob.core.windows.net`. Si pones un guion, la CLI falla antes de
  llamar a la API; si el nombre ya existe en otra suscripción de otra persona, falla la
  API con un error de nombre no disponible.
- `--sku Standard_LRS` guarda tres copias dentro de un único datacenter. Es la redundancia
  más barata y la única razonable en un lab, pero **no sobrevive a la caída de una zona**:
  para eso existen `ZRS`, `GRS` y `GZRS`, que se discuten en
  `06`.
- `--allow-blob-public-access false` impide que un contenedor se marque como público,
  aunque alguien lo intente después. Hoy es el valor por defecto en cuentas nuevas, pero
  el curso lo declara igual: lo explícito sobrevive a los cambios de default.
- `--allow-shared-key-access false` es el flag que más se olvida. **Sin él, la cuenta
  acepta sus dos access keys, y cada una da control total sobre todos los datos de la
  cuenta**, sin role assignment ni auditoría por identidad: es el equivalente a una
  contraseña de root pegada en un `application.yml`. Con `false`, solo se entra con un
  token de Entra ID y un rol de datos como `Storage Blob Data Contributor`. El precio es
  que los comandos de datos piden `--auth-mode login` y fallan con `KeyBasedAuthenticationNotPermitted`
  si lo olvidas.

Ese nivel es el estándar. Un bloque de comandos sin desglose posterior es un error de
estilo, por más correcto que sea el comando.

### 4.3 Explica el porqué, no solo el cómo

Un paso sin justificación es un paso que el lector no puede adaptar cuando su caso real
difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media línea entre
paréntesis: por qué el lab usa una user-assigned managed identity y no la system-assigned,
por qué el role assignment se hace en el scope del recurso y no del resource group, por qué
el lab evita Application Gateway en lugar de enseñarlo.

Cuando el porqué es económico y no técnico —que en la nube pasa seguido— se dice
también: *"el lab no pone Front Door delante de Container Apps porque su perfil tiene un
cargo base que corre aunque no llegue ni un request, y Container Apps ya te da un FQDN
HTTPS con certificado administrado sin cobrar nada por él"* (con la cifra verificada al
escribir el documento, §10.1).

### 4.4 Nada de cajas negras prematuras

El curso enseña primero el mecanismo y después la comodidad:

- primero `az` crudo (`az provider register`, `az role assignment create`,
  `az resource list`), **después** —y solo si simplifica de verdad— el portal;
- primero Bicep escrito a mano con `az deployment group what-if` antes de cada despliegue,
  **después** módulos, Azure Verified Modules, Deployment Stacks o `azd`;
- primero entender que **Bicep compila a una plantilla ARM y que el estado es Azure
  Resource Manager mismo**, sin archivo de state, **después** comparar con Terraform, que
  sí lo tiene;
- primero leer el evento crudo que llega a un endpoint —el esquema de Event Grid o el
  CloudEvent, con el handshake de validación del webhook—, **después** el SDK que lo
  abstrae;
- primero obtener un token a mano con `az account get-access-token` y ver qué `aud` y qué
  `roles` trae, **después** `DefaultAzureCredential`.

No es que esas herramientas sean malas. Es que ocultan exactamente lo que el curso quiere
enseñar, y quien entiende el mecanismo aprende la capa de arriba en una tarde.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo
dónde se rompen. Un resource group se parece a una carpeta de recursos *hasta que
descubres que también es la unidad de ciclo de vida, de scope de RBAC y de Azure Policy,
de locks y de borrado en cascada, que tiene una región propia donde solo viven sus
metadatos, y que sus recursos pueden estar en otras regiones*. Una analogía que no se
cierra genera bugs conceptuales que aparecen cinco documentos después.

Cuidado especial con las seis más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **una read replica no es un backup**;
- **Cosmos DB no es "una base multi-modelo donde eliges la API al consultar"**: la API se
  fija al crear la cuenta, y cada una es un motor con su propio contrato;
- **un rol de Entra ID no es un rol de Azure RBAC**: el Global Administrator no ve ni un
  recurso de tus suscripciones hasta que eleva su acceso, y el Owner de una suscripción no
  puede crear un usuario;
- **Azure RBAC no tiene un deny que tú escribas**: los deny assignments existen, pero los
  crean Azure Managed Applications o los Deployment Stacks, no un `az role` cualquiera;
- **un NSG no es un firewall centralizado**: es un filtro stateful que se asocia a una
  subnet o a una NIC —y si están los dos, se evalúan los dos—; Azure Firewall es otro
  producto, con otro precio;
- **una managed identity no es "una cuenta de servicio sin contraseña" a secas**: es un
  service principal cuyo ciclo de vida y credencial administra Azure, y la system-assigned
  muere con su recurso.

### 4.6 Densidad calibrada y sin techo de longitud

Un documento dura lo que necesite para no dejar huecos. A cambio:

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas desconocidas, se
  parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —zonal vs regional
  vs no regional, control plane vs data plane, la jerarquía de scopes, quién administra
  qué, qué cobra por hora y qué entra en una oferta gratuita— reaparecen con otras
  palabras. La repetición espaciada funciona; la enciclopedia no.
- Ninguna sección teórica supera las dos pantallas sin un diagrama, una tabla, un comando
  o una salida real.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2).

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto lo vemos en `10`"*, *"el purge de esto está en `L09`"*—
tiene que cerrarse en algún documento del curso, y con enlace real. Un pendiente que nunca
se resuelve es ruido y el lector deja de confiar en las promesas del texto. El mapa de
referencias cruzadas entre documentos es parte del producto.

---

## 5. 💻 Idioma del código, comandos y recursos

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —nombres de
> recurso, símbolos de Bicep, tags, variables de entorno, identidades, topics y apps— y
> todos los comentarios van en español.**

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Nombres de producto, feature y recurso Azure | Inglés (nombre oficial) | `Network Security Group`, `Private Endpoint`, `Partition key` |
| Símbolos, parámetros y outputs de Bicep | Inglés, `camelCase` | `param location string`, `resource apiApp 'Microsoft.App/containerApps@…'` |
| Nombres de recurso desplegado | Inglés, kebab-case **cuando el tipo lo admite** | `inv-api`, `inv-events`, `inv-lab-rg` |
| Tags | Inglés, minúsculas y guiones | `project=inv-lab`, `env=lab` |
| Comentarios dentro de bloques de código | Español | `// la cuenta no acepta access keys; solo tokens de Entra ID` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos técnicos consolidados | Inglés sin traducir | *stateful*, *eventually consistent*, *drift* |

> ⚠️ **Cada tipo de recurso de Azure tiene sus propias reglas de nombre, y varias no son
> negociables.** Una storage account admite solo minúsculas y dígitos, sin guiones, y su
> nombre es único en todo Azure; un Key Vault, un namespace de Service Bus y una cuenta de
> Cosmos DB también son únicos globalmente porque se convierten en un hostname. Por eso el
> baseline de §5.1 lleva el sufijo numérico `472913` donde hace falta unicidad global y
> rompe el kebab-case donde la API lo prohíbe: no es inconsistencia de estilo, es lo que
> la API acepta. Cada documento que introduce un tipo nuevo cita su regla de nombre la
> primera vez.

> ⚠️ **Las claves de los tags no distinguen mayúsculas; los valores sí.** `Project` y
> `project` son la misma clave para Azure, pero no para un filtro de Cost Management
> escrito con otro casing en otro lado. El curso usa minúsculas en ambos para no tener que
> pensarlo.

### 5.1 Nombres estables de la serie práctica

Estos valores son el baseline del laboratorio y no cambian entre documentos. Si un lab
necesita otro, lo declara y explica por qué. **Estado: congelado** el 27 de septiembre de
2026 por `l00-idea-lab-practico.md` §11, que justifica la región y el resto de decisiones.

| Elemento | Valor fijado |
|---|---|
| Región del lab | `eastus2` |
| Suscripción de ejemplo en salidas | `11112222-3333-4444-5555-666677778888` |
| Tenant de ejemplo en salidas | `aaaabbbb-0000-cccc-1111-dddd2222eeee` |
| Perfil aislado de la CLI | `AZURE_CONFIG_DIR=$HOME/.azure-inv-lab` |
| Resource group del lab | `inv-lab-rg` |
| Tags de rastreo obligatorios | `project=inv-lab`, `env=lab` |
| Storage account | `invlab472913` |
| Container Registry | `invlabacr472913` (Basic) |
| Container Apps environment y apps | `inv-lab-env`; `inv-api`, `inv-projector` |
| User-assigned managed identities | `inv-api-id`, `inv-projector-id` |
| VNet y subnet del lab | `inv-lab-vnet` (`10.20.0.0/16`), `inv-lab-snet` (`10.20.1.0/24`, privada) |
| NSG del lab | `inv-lab-nsg` |
| Private endpoint de blobs y su VNet link | `inv-lab-pe-blob`; `inv-lab-vnet-link` a `privatelink.blob.core.windows.net` |
| Namespace, topic y subscription de Service Bus | `inv-lab-sb-472913`; `inv-events`; `inv-projector` |
| Cuenta, base y contenedores de Cosmos DB | `inv-lab-cosmos-472913` (free tier, API for NoSQL); `inv`; `events`, `stock` |
| Key Vault | `inv-lab-kv-472913` |
| Log Analytics workspace y Application Insights | `inv-lab-law`; `inv-lab-appi` |
| VM de diagnóstico de `L04` | `inv-lab-vm` (B1ls, sin IP pública) |
| App registrations de `L06` | `inv-api` (la API), `inv-cli` (el cliente humano) |
| App role y scope de `inv-api` | `Inventory.Write` (app role), `Inventory.Read` (scope delegado) |
| Budget y action group | `inv-lab-budget` ($5 al mes); `inv-lab-ag` |
| Deployment Stack | `inv-lab-stack` |
| Resource group de los drills | `inv-drill-rg` |

> 📝 **Por qué un perfil aislado y no una "configuración con nombre".** La CLI de Azure no
> tiene perfiles con nombre: guarda la sesión, la suscripción activa y los defaults en un
> único directorio. `AZURE_CONFIG_DIR` apunta la CLI a un directorio distinto, y es la
> única forma limpia de que el lab no herede —ni contamine— la sesión de trabajo del
> lector. Se explica entero en `L01`.

**Nunca uses `latest`, `*` ni rangos donde el curso fija un valor exacto**: ni en tags de
imagen, ni en versiones de API de un recurso Bicep (`Microsoft.App/containerApps@2024-03-01`,
no la más nueva "que haya"), ni en runtimes, ni en la versión del provider si aparece
Terraform. La versión de API de cada tipo de recurso se fija, se verifica contra la
referencia de plantillas y se dice cuál.

---

## 6. 🧱 Plantilla de los documentos temáticos

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — objetivo del documento en una o dos líneas, qué se
   asume leído, con qué dos documentos se toca más, **en qué lab se practica** —o por qué
   no tiene lab— y **`Vigencia:`** con la fecha en que se verificaron los enlaces y el
   comportamiento de los servicios descritos. Ese campo es obligatorio: Azure renombra y
   retira servicios con frecuencia, y quien abre `04` sin pasar por el README tiene que
   saber qué tan reciente es lo que lee.
3. **Índice de salto rápido** — si el documento pasa de ~400 líneas (§6.2).
4. **Secciones `##` numeradas**, una por concepto o servicio, con emoji funcional. Cuando
   el documento cubre bloques claramente separables (almacenamiento frente a SQL, Entra ID
   frente a RBAC frente a Key Vault) se usan divisores `# Parte I — …` en romanos,
   **manteniendo la numeración arábiga de `##` continua** a través de las partes.
5. **⚠️ Errores frecuentes** — sección opcional pero recomendada: la confusión típica de
   entrevista sobre ese tema, con la versión precisa al lado.
6. **🧠 Preguntas rápidas** — cierre obligatorio, sin respuestas visibles (§8).
7. **📚 Referencias oficiales** — cierre obligatorio (§10).

**Excepciones declaradas a la plantilla:**

- `README.md` — índice, mapa mental, tabla de "dónde se practica cada capítulo" y
  asociaciones que conviene memorizar.
- `18-preguntas-entrevista-y-mapa-mental.md` — simulación de entrevista completa:
  preguntas `P#` sin respuesta inline (van al solucionario) y escenarios de arquitectura
  que **sí** conservan su solución desarrollada, porque son ejemplos resueltos y no
  autochequeo de memoria.
- `19-respuestas.md` — solucionario centralizado. No lleva "Preguntas rápidas" ni
  referencias propias.
- `l00-idea-lab-practico.md` — encuadre de la serie práctica (§7.1).

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [Regions](#2--regions) · [Availability Zones](#3--availability-zones) ·
[VNet — alcance regional](#4--vnet--alcance-regional) · [NSG](#6--nsg) ·
[Preguntas rápidas](#-preguntas-rápidas)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio,
guion o guion bajo —lo que se lleva por delante el punto de la numeración, el emoji, los
backticks y los dos puntos— y por último los espacios restantes se convierten en guiones.
Cada carácter borrado **deja su espacio**, y de ahí salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Regions` | `#2--regions` |
| `## 4. 🧱 VNet — alcance regional` | `#4--vnet--alcance-regional` |
| `## 8. 🧱 \`az deployment group what-if\`` | `#8--az-deployment-group-what-if` |
| `## 🧠 Preguntas rápidas` | `#-preguntas-rápidas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza por
guion**. Verifica los anclas al escribirlos; un índice con enlaces rotos es peor que no
tener índice.

---

## 7. 🧪 La serie práctica: labs (`lNN-`) y apéndices (`aNN-`)

Los labs y los apéndices siguen la plantilla de §6 con los añadidos de abajo, y sin ninguna
excepción de tono ni de pedagogía: aquí la regla de §4.2 se aplica con más rigor que en
ninguna otra parte, porque son los documentos que el lector ejecuta contra una suscripción
que le cobra.

### 7.1 La doctrina de reparto es materia editorial, no solo de alcance

**Regla de arquitectura del curso, y se enuncia en cada lab que la toque:**

> En la nube se practica lo que **solo** existe en la nube. Todo lo demás se practica en
> local con contenedores, gratis y con un ciclo de iteración de segundos.

Un tema entra en el laboratorio de pago solo si cumple al menos una condición:

| Criterio | Ejemplos en Azure |
|---|---|
| Lo hace cumplir Azure y nadie más | Entra ID y Azure RBAC, jerarquía de scopes, registro de resource providers, Azure Policy, cuotas |
| El fallo real difiere del emulado | Soft-delete y purge protection, resource locks, handshake de validación de Event Grid, DLQ y `MaxDeliveryCount` de Service Bus, propagación de role assignments |
| Solo se conoce pagando | Cost Management, budgets, qué consume de verdad una oferta gratuita |
| Es la costura entre tu código y Azure | Managed identities, `DefaultAzureCredential`, workload identity federation, tokens y audiencias |

Y la contrapartida se escribe con la misma claridad: **cuando el curso excluye algo —AKS,
VMs, Application Gateway, Front Door, Azure Firewall, un microservicio de negocio— dice por
qué, cuánto costaría y dónde se practica en su lugar.** Una exclusión sin justificación se
lee como un hueco del temario; una exclusión justificada es contenido. El desarrollo
completo vive en `l00-idea-lab-practico.md` y el resto de documentos remite ahí.

**Azure tiene emuladores oficiales** —Azurite para Storage, el emulador de Cosmos DB y el
de Service Bus—, y eso obliga a una precisión que los cursos hermanos no necesitaron: cada
vez que un lab o un capítulo mencione uno, dice **qué miente**. Ninguno evalúa RBAC,
ninguno cobra, y ninguno reproduce el throttling por Request Units ni la propagación de un
role assignment. Son andamio de desarrollo, no instrumento de enseñanza.

**La unidad de destrucción es el resource group.** `az group delete` borra en cascada todo
lo que contiene, y es la base de todos los teardowns del curso. Pero tiene letra pequeña y
se escribe siempre junto al recurso que la provoca, nunca al final:

- **Lo que sobrevive en estado soft-deleted** —Key Vault, y con él el nombre, retenido
  durante el período de retención; Log Analytics workspace; blobs con soft-delete— y cómo
  se purga.
- **Lo que Azure crea fuera de tu resource group** —`NetworkWatcherRG`, el resource group
  administrado de un Container Apps environment con VNet propia, los role assignments en
  scopes superiores— y que el borrado del tuyo no toca.
- **Lo que bloquea el borrado** —un resource lock `CanNotDelete`, una purge protection
  activada, que no se puede desactivar nunca—.

### 7.2 Labs `lNN-tema.md`

Título `# LNN — Tema`. Son acumulativos y se hacen en orden. Además de lo de §6:

> 🧭 **Cuántos labs tiene la serie lo decide Azure, no la simetría con otro curso.** Un lab
> es una sesión de dos o tres horas con un teardown propio, y se parte en dos en cuanto
> mezcla dos diagnósticos distintos o en cuanto un tema que en otra nube sería caro aquí
> resulta gratis y merece practicarse en vez de solo leerse. El recuento vigente y su
> justificación viven en `l00-idea-lab-practico.md`; esta guía no lo duplica.

- **Cabecera con contrato económico y temporal:** costo esperado con su unidad y su
  relación con las ofertas gratuitas, duración estimada, prerrequisitos (qué lab anterior
  debe estar hecho) y qué queda encendido al terminar.
- **Teardown escrito antes que el despliegue.** Ningún lab introduce un recurso sin que el
  documento diga, en ese mismo punto, cómo se destruye y cómo se verifica que murió. Si el
  recurso sobrevive a `az group delete` —o si un lock o una purge protection lo bloquean—,
  se dice ahí, no en el lab de teardown.
- **Reproducir el error antes de arreglarlo.** Cuando el lab enseña un fallo
  —`MissingSubscriptionRegistration` por un provider sin registrar, un
  `AuthorizationFailed` por un role assignment en el scope equivocado, un `ScopeLocked` por
  un lock olvidado, un nombre de Key Vault que no se puede reutilizar— se provoca a
  propósito, se muestra la salida literal y solo después la corrección.
- **📋 Checklist de salida** en formato `- [ ]` antes del cierre, con comprobaciones
  ejecutables. Es la única lista de tareas admitida en el curso y no son ejercicios: son
  criterios de terminado verificables.
- **🏁 La señal de que quedó bien** — una frase de cierre que describe el estado correcto:
  *"`az resource list --tag project=inv-lab` devuelve `[]`, `az keyvault list-deleted` no
  muestra `inv-lab-kv-472913` y Cost Management confirma $0.00 a las 48 horas"*.

### 7.3 Apéndices `aNN-tema.md`

Título `# ANN — Tema`. Material de consulta, sin orden ni prerrequisitos. No llevan costo,
duración ni checklist de salida —con la excepción declarada de `A04`, la rutina de recurso, que es
para ejecutar y sí los lleva (§8.1)—. Abren siempre con índice de salto rápido y organizan
el contenido en secciones cortas e independientes, cada una autosuficiente. Sí llevan
"Preguntas rápidas" y "Referencias oficiales".

### 7.4 Labs redactados sin corrida

El 2026-09-29 se decidió cerrar la redacción de `L01`–`L09` y `A01`–`A05` **sin correrlos contra
Azure**: no hay suscripción, y la serie no se corre con una tarjeta de crédito personal. Mientras no se
corran rigen cuatro reglas:

1. **Ninguna salida de terminal se inventa.** Donde iría la salida literal de un comando hay un bloque
   ` ```text ` que empieza por `[PENDIENTE DE CORRIDA]` y describe qué debe mostrar según la
   documentación citada. `rg -c 'PENDIENTE DE CORRIDA' *.md` da la deuda exacta: 159 bloques al cierre
   de la redacción.
2. **Todo lo que no necesita suscripción sí se verifica:** URLs, precios con la Retail Prices API,
   versiones de API de Bicep, flags de `az` contra la referencia de la CLI y versiones de librerías.
3. **Cada lab y apéndice ejecutable lo declara** en su blockquote con `Estado: redactado, pendiente de
   corrida`, y el README lo repite en su encabezado.
4. **Un documento sale de ese estado** solo cuando su último marcador se sustituye por salida real
   anonimizada, el error se provocó de verdad y el teardown se comprobó con:

```bash
AZURE_CONFIG_DIR=$HOME/.azure-inv-lab az resource list --tag project=inv-lab --output table
AZURE_CONFIG_DIR=$HOME/.azure-inv-lab az group list --output table
AZURE_CONFIG_DIR=$HOME/.azure-inv-lab az keyvault list-deleted --output table
AZURE_CONFIG_DIR=$HOME/.azure-inv-lab az monitor log-analytics workspace list-deleted-workspaces --output table
AZURE_CONFIG_DIR=$HOME/.azure-inv-lab az ad app list --filter "startswith(displayName,'inv-')" --output table
```

- `az resource list --tag project=inv-lab` busca en toda la suscripción lo que lleve la etiqueta del
  curso; tiene que volver vacía.
- `az group list` no debe contener `inv-lab-rg` ni `inv-drill-rg`. Si queda `NetworkWatcherRG` u otro
  grupo creado por Azure, se anota en el lab que lo provocó (`l00` §7.3).
- `az keyvault list-deleted` y `list-deleted-workspaces` muestran lo que sobrevive en soft-delete y
  sigue reservando el nombre.
- `az ad app list --filter` busca app registrations del curso, que viven en el tenant y no mueren con
  el resource group.

Entre labs **sí** puede quedar vivo lo que el lab declara que deja encendido; lo que no puede quedar es
nada que no esté declarado. Al correr la serie: CLI **2.90.0**, labs en orden, y dos puntos que hay que
confirmar contra la nube —el rol del scaler de KEDA con managed identity (`L07` §9) y el código literal
del error de lock (`L03` §8)—. Después se corre `bash prompts/verificar-curso.sh` desde `03-azure/`.

---

## 8. 🧠 Preguntas rápidas y la rutina de recurso

Este curso adopta el aparato de evaluación de `02-gcp/`, no el de `01-aws/`: **nada de
ejercicios graduados 🟢🟡🟠🔴 por documento**. Lleva dos cosas distintas y mucho más
pequeñas: las **Preguntas rápidas** que cierran cada documento, y **una única rutina
ejecutable** definida en `A04` y aplicada donde haga falta.

`CLAUDE.md` admite expresamente que la guía de cada curso reemplace el aparato por defecto
por otro formato de evaluación, siempre que lo diga y diga por qué. La razón es la
naturaleza del material: repaso para una entrevista, no un curso narrativo con proyecto
integrador, y cada ejercicio aquí correría contra una suscripción que factura. La regla, en
tres líneas:

```text
capítulos teóricos  →  SOLO preguntas rápidas. Nunca ejercicios.
apéndices y labs    →  preguntas rápidas + lo único ejecutable del curso
respuestas          →  SIEMPRE en 19-respuestas.md, nunca junto a la pregunta
```

**Si alguna vez entra un ejercicio, entra por apéndice o por lab, jamás por un capítulo
teórico**, y solo con estas dos formas: la **rutina de recurso** (§8.1) y el **`📋 Checklist
de salida`** de cada lab (§7.2). Cualquiera de las dos declara su costo y su teardown.

### 8.1 La rutina de recurso (`A04`)

Es la excepción declarada a "aquí no se ejecuta nada", y existe porque hay un aprendizaje
que ninguna pregunta de memoria produce: crear, inspeccionar, modificar y destruir un
recurso cualquiera desde cero, primero con `az` y después desde un SDK.

Reglas para escribirla:

- **La forma es fija y se repite idéntica para todos los servicios**: crear → inspeccionar
  con `--output json` y `--query` → modificar → destruir → verificar qué quedó vivo
  (incluido lo soft-deleted) → repetir desde el SDK.
- **El puente CLI→API se enseña con `--debug` y con `az rest`.** `--debug` muestra la
  petición HTTP que tu comando le hace a Azure Resource Manager —método, URL con su
  `api-version` y cuerpo—; `az rest` te deja repetirla a mano con tu token. El lector tiene
  que ver que **todo `az` es un `PUT`, `GET` o `DELETE` sobre un resource ID** antes de
  escribir la primera línea de código, y distinguir cuándo el comando habla con el control
  plane (`management.azure.com`) y cuándo con el data plane del servicio.
- **Cada vuelta declara su costo** con la misma honestidad que un lab (§7.2), y se eligen
  recursos cuyo ciclo completo sea gratis o de centavos.
- **El entregable es el script y el fragmento de código anotados**, no el recurso. Eso se
  dice explícitamente: lo que sobrevive a la sesión es el apunte.
- **Los ejemplos de SDK van en un solo lenguaje** —Java, con el Azure SDK for Java, salvo
  que `l00-idea-lab-practico.md` decida otra cosa— y se declara que el lector puede usar
  otro. No se escriben cuatro versiones del mismo fragmento.

### 8.2 Preguntas rápidas

Cierran todos los documentos. Son preguntas para contestar de memoria o razonando, no
trabajos para resolver con código.

- **Cantidad: 10 a 15 por documento temático o lab, y de 6 a 12 en un apéndice**,
  calibrada por cuántas cosas distintas enseña el documento y se pueden comprobar por
  separado — nunca por su longitud. La banda admite desbordarse **cuando el documento
  cubre varias Partes o es un catálogo**: `10` puede pasar de 15 porque abarca Azure RBAC,
  scopes, plano de datos, deny assignments, PIM, Azure Policy, locks y landing zones.
  Fuera de esos casos, subir de 15 exige poder decir qué comprueba cada pregunta nueva que
  no comprobara ya otra.
- **Directas y verificables.** Cada pregunta tiene respuesta corta y objetiva localizable
  en el propio documento. Nunca "reflexiona sobre…".
- **Reparto sugerido**: aproximadamente la mitad de definición o distinción ("¿una VNet
  puede abarcar dos regiones?"), un tercio de decisión o comparación ("¿cuándo usarías
  Service Bus en lugar de Event Grid?") y el resto de diagnóstico ("¿cómo depurarías una
  app que resuelve el FQDN de un private endpoint a su IP pública?"). **Dos documentos
  vecinos no deberían tener el mismo reparto.**
- **Sin respuesta en el documento, con solucionario centralizado.** Todas las respuestas,
  explicadas, viven en `19-respuestas.md`, agrupadas por documento, numeradas igual que la
  pregunta original (la pregunta 3 de `04` se responde en la entrada "04 → 3") **y con el
  enunciado copiado literalmente**, no parafraseado. Quien agregue, elimine o reordene una
  pregunta **debe reflejar el mismo cambio en el solucionario en la misma edición**.
- **Orden libre**, por relevancia de entrevista, no correlativo a las secciones.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación o
ecuación corta. Se etiqueta antes con una línea breve: "Regla:", "Regla mental:", "Regla
de entrevista:" o "Regla de arquitectura:".

```text
VNet            = regional
Subnet          = regional (abarca todas las zonas)
VM y disco      = zonales si eliges zona
Resource group  = región propia solo para sus metadatos
```

### 9.2 Frase de respuesta correcta (blockquote `>`)

Para la única frase que un entrevistado debería decir en voz alta, normalmente después de
mostrar la simplificación incorrecta. Sirve igual para blindar contra la mala respuesta
("Nunca respondas: > …") que para dar la buena ("Mejor: > …"). También admite etiqueta
corta de énfasis —"Regla importante:", "Punto importante:"—.

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en blockquote; si
es lista, ecuación o comparación de dos o más líneas, va en bloque `text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento.

- ⚠️ **Advertencia.** Ignorarlo rompe algo en producción, cuesta dinero o produce una
  respuesta de entrevista objetivamente incorrecta. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco o atajo** que ahorra tiempo real (un `--query` de JMESPath que evita cinco
  comandos, `az resource list --tag` en vez de recorrer resource groups a mano).
- 🩺 **Diagnóstico.** El comando que confirma o descarta una hipótesis.
- 💰 **Costo.** Lo que cobra ese recurso, con unidad y con qué lo dispara, o la oferta
  gratuita que lo cubre. Obligatorio la primera vez que un documento introduce algo que
  cobra por hora.
- 📝 **Contexto.** Por qué Microsoft hace algo así, o qué cambió recientemente y por qué la
  respuesta "clásica" de fuentes viejas ya no aplica. Azure ofrece más casos que nadie:
  Azure AD renombrado a Microsoft Entra ID, el retiro del acceso de salida por defecto de
  las VMs, el retiro de las Public IP de SKU Basic, servicios de hosting para Java que se
  anuncian como retirados.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al cierre.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques
` ```text ` de comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌ y de los emojis de encabezado de §3, **no se usan otros
emojis**. Nada de 🪦, 💸, 🔥, ⭐, 🚨 ni escalas de dificultad.

### 9.4 Autopsia de un fallo

Cuando un lab documenta un fallo real la estructura es:

1. Síntoma, con la salida literal del comando.
2. Qué lo provocó, hasta la línea del Bicep o el role assignment concreto.
3. La hipótesis y el comando que la confirma o la descarta.
4. La corrección, distinguiendo el parche que desbloquea hoy de la solución que uno haría
   con calma.
5. La prevención: la comprobación, el tag, la policy o el checklist que evita la
   repetición.

Dos reglas de método que atraviesan la serie práctica: **una variable a la vez** y
**reproducir antes de reparar**. Y los anti-patrones se nombran sin piedad: `Owner` sobre
la suscripción "para salir del paso", connection strings y access keys en app settings en
vez de una managed identity, el client secret de un service principal commiteado en el
repo en vez de una federated credential, `--allow-blob-public-access true` "porque el
`curl` no andaba", y tocar en el portal lo que Bicep administra.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos

- **Solo documentación oficial de Microsoft** en la sección de referencias:
  `learn.microsoft.com`, las páginas de pricing de `azure.microsoft.com`, la calculadora y
  Azure Updates. El curso no cita libros, blogs ni videos.
- **Locale fijo `en-us` en las URLs de Learn** (`https://learn.microsoft.com/en-us/azure/…`).
  La versión en español es traducción automática y traduce nombres de producto y de
  propiedad que el lector no va a ver en `az` ni en los mensajes de error.
- **Bicep no es excepción**: es de Microsoft y su documentación vive en Learn. **La única
  excepción es Terraform**, y solo en la sección comparativa de `15`, que puede
  citar `registry.terraform.io/providers/hashicorp/azurerm/…` y
  `developer.hashicorp.com/terraform/…`.
- **Herramientas de terceros que el laboratorio local usa** van en una **subsección aparte
  marcada como opcional**. Los emuladores oficiales de Microsoft no son terceros y van con
  la documentación oficial.
- **URLs completas y clicables**, nunca solo el dominio, y **una URL por concepto
  cubierto**, no la portada del producto cuando existe la página específica.
- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el
  nombre exacto de la página y se deja el enlace al índice del producto. Se comprueban por
  código de estado siguiendo redirecciones, y **aterrizar en la portada de un producto o
  en una página de búsqueda de Learn cuenta como roto**.
- **No se inventan precios.** Los precios de Azure cambian por región, por SKU y por
  tipo de oferta. Se cita el número solo cuando se verificó contra la página oficial de
  pricing o contra la **Azure Retail Prices API** (`https://prices.azure.com/api/retail/prices`,
  pública y sin autenticación, filtrable por servicio, SKU y región), con su unidad exacta;
  si no se verificó, se dice "verifica en la calculadora" y se enlaza.

### 10.2 Enlaces internos entre documentos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo al archivo, con el número del documento en el
  texto visible:

  ```markdown
  ver [`10` — scopes de Azure RBAC](10-autorizacion-rbac-policy-y-gobierno.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  [`15` §6 — what-if](15-bicep-iac.md#6--what-if)
  ```

- **Cada documento temático enlaza al menos a los dos documentos con los que más se
  toca**, y todo lab enlaza al documento teórico que sustenta lo que practica y al apéndice
  que lo complementa.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma
  edición.**

### 10.3 Vigencia

El README declara la fecha de revisión general y **cada documento la repite en su
blockquote de encabezado**. Cuando un documento incorpora un cambio reciente de Azure —un
renombre, un retiro anunciado, un default que cambió— se marca con 📝 en el propio texto,
y **si el cambio tiene fecha de efecto se escribe la fecha**, verificada contra Azure
Updates o la página de retiro oficial. En Azure un servicio "retirado" suele seguir vivo
años para los clientes existentes y cerrado para los nuevos: se distingue siempre cuál de
las dos cosas pasa.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `07` establece que una geo-replica de Azure
  SQL es para lectura y DR, `18` puede matizarlo, nunca contradecirlo.
- **Terminología estable.** Si `09` dice "Microsoft Entra ID", el resto del curso no vuelve
  a "Azure AD" salvo en el 📝 que explica el renombre. Si `02` dice "VNet", nadie escribe
  "red virtual" en otro capítulo.
- **Los labs son acumulativos y lo declaran.** Cada lab dice en su cabecera qué deja
  encendido y el siguiente asume exactamente ese estado.
- **Los nombres del baseline de §5.1 mandan.** Cualquier desviación se declara con ⚠️ en el
  documento que la introduce.
- **Fuentes de verdad, en orden:** (1) **esta guía y los demás documentos de `prompts/`**;
  (2) `CLAUDE.md` de la raíz, para todo lo que esta guía no toca; (3)
  `l00-idea-lab-practico.md` para el alcance y la doctrina de reparto; (4) `README.md` para
  orden de lectura y mapa; (5) documentos ya publicados; (6) decisiones explícitas del chat
  actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de §6 (o está declarado como excepción: README, `18`, `19`, `l00`).
- [ ] Encabezado con objetivo, documentos vecinos, dónde se practica y **`Vigencia:`**; índice de salto rápido si pasa de ~400 líneas.
- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Emoji funcional en `##`, ninguno en `###`, y solo los callouts de §9.3.
- [ ] **Ningún comando ni flag queda sin explicar** (§4.2). Ningún bloque de código sin desglose.
- [ ] El problema se plantea antes que el servicio (§4.1) y cada decisión lleva su porqué (§4.3).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, sin celdas que necesiten explicación.
- [ ] No asume que el lector conoce AWS ni GCP, ni introduce mapeos desde otra nube (§3.1).
- [ ] Nombres del baseline de §5.1 respetados; reglas de nombre de cada tipo citadas la primera vez; sin `latest`, sin `*`, versiones de API de Bicep fijas.
- [ ] Se nombra explícitamente cuando una respuesta común de entrevista es una sobregeneralización.
- [ ] Todo lo que cobra por hora aparece con precio y unidad, o con la oferta gratuita que lo cubre (💰), y toda exclusión del lab dice por qué y dónde se practica en su lugar (§7.1).
- [ ] Todo emulador mencionado dice qué miente (§7.1).
- [ ] Ningún precio ni URL sin verificar; URLs de Learn con `en-us` (§10.1).
- [ ] En labs: teardown escrito junto al recurso —incluido lo que queda soft-deleted o fuera del resource group—, errores reproducidos antes de corregirlos, checklist de salida ejecutable y cierre con **🏁 La señal de que quedó bien**.
- [ ] Cierra con **Preguntas rápidas** (10–15; apéndices 6–12), sin respuestas, con reparto distinto al del documento vecino (§8.2).
- [ ] No introduce ejercicios graduados 🟢🟡🟠🔴: lo único ejecutable del curso es la rutina de recurso (§8.1).
- [ ] Si tocaste alguna pregunta, actualizaste el solucionario en la misma edición.
- [ ] Cierra con **Referencias oficiales**: URLs completas, verificadas, una por concepto, solo documentación oficial de Microsoft (salvo la excepción de Terraform); terceros en subsección opcional aparte.
- [ ] Enlaces internos a los documentos con los que más se toca, y ningún enlace interno roto (§10.2).
- [ ] Todo cambio reciente de Azure marcado con 📝 y con fecha de efecto verificada (§10.3).
- [ ] No contradice ningún documento anterior (§11).
