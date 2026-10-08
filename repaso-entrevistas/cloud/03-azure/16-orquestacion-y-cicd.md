# 16 — Orquestación y CI/CD

> **Objetivo:** coordinar procesos de varios pasos con Durable Functions o Logic Apps, desplegar en
> Azure desde GitHub Actions o Azure Pipelines **sin un solo secreto**, y elegir la estrategia de
> despliegue —slots, revisiones, blue/green, canary— según el servicio y el riesgo.
> **Se asume leído:** [`04`](04-computo-y-contenedores.md) (App Service con slots y Container Apps con
> revisiones), [`09`](09-identidad-entra-id-y-managed-identities.md) (workload identity federation) y
> [`15`](15-bicep-iac.md) (lo que el pipeline despliega).
> **Se toca más con:** [`10`](10-autorizacion-rbac-policy-y-gobierno.md), que decide qué roles necesita
> la identidad del pipeline, y el [`17`](17-resiliencia-y-well-architected.md) (resiliencia), que pide poder volver atrás rápido.
> **Se practica en:** el reparto de tráfico entre revisiones, en [`L05`](l05-container-apps-revisiones-trafico-y-escala.md); GitHub Actions con OIDC, en un
> drill gratuito de [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales). Ver
> [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 29 de septiembre de 2026.

**Salto rápido:** [Dos problemas](#1--dos-problemas-distintos) · [Durable Functions](#2--durable-functions) ·
[Logic Apps](#3--logic-apps) · [⚖ Durable frente a Logic Apps](#4--durable-functions-frente-a-logic-apps) ·
[GitHub Actions con OIDC](#5--github-actions-con-oidc) · [Azure Pipelines](#6--azure-pipelines) ·
[Estrategias de despliegue](#7--estrategias-de-despliegue) · [Ambientes](#8--promoción-entre-ambientes) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Dos problemas distintos

El capítulo junta dos temas que en una entrevista aparecen separados:

- **orquestación**: un proceso de negocio con varios pasos, esperas y compensaciones —abrir una cuenta
  implica validar identidad, esperar la aprobación de un analista, crear la cuenta en el core y notificar—
  que tiene que sobrevivir a reinicios y durar horas o días;
- **CI/CD**: llevar el código y la infraestructura de un commit a producción de forma repetible, segura y
  reversible.

Lo que los une es la **fiabilidad**: un proceso que se retoma donde quedó y un despliegue que se puede
revertir en segundos.

---

## 2. 🧱 Durable Functions

**El problema:** encadenar pasos en Functions normales obliga a guardar el estado a mano entre
invocaciones, reintentar lo que falló y saber dónde se quedó cada instancia tras un reinicio.

**Durable Functions** es una extensión de Azure Functions que permite escribir el flujo **como código
secuencial** y se encarga del estado:

- el **orquestador** describe el flujo: llama a actividades, espera eventos, pone temporizadores;
- las **actividades** hacen el trabajo real —llamar a una API, escribir en la base— y pueden hacer
  cualquier cosa;
- los **entities** mantienen pequeños estados con identidad (un contador, un carrito);
- el cliente arranca, consulta y termina instancias.

Los patrones que se preguntan:

- **encadenamiento**: A → B → C, cada paso con la salida del anterior;
- **fan-out/fan-in**: lanzar N actividades en paralelo y esperar a todas (procesar mil archivos y sumar);
- **interacción humana**: esperar un evento externo ("aprobado") con un temporizador de vencimiento
  ("si en 72 horas no hay respuesta, escalar");
- **monitor**: sondear algo periódicamente hasta que se cumple una condición.

El mecanismo que lo hace posible es el **replay**: el orquestador guarda cada paso en un historial
(*event sourcing*) y, cada vez que se reanuda, **vuelve a ejecutarse desde el principio**, tomando del
historial el resultado de lo que ya se hizo. De ahí la regla que todo entrevistador comprueba:

> ⚠️ **El código del orquestador tiene que ser determinista.** Como se re-ejecuta muchas veces, cada
> replay debe tomar las mismas decisiones. Nada de `Instant.now()`, `UUID.randomUUID()`, números
> aleatorios, variables de entorno, llamadas HTTP o `Thread.sleep()` dentro del orquestador. En Java se
> usan `ctx.getCurrentInstant()`, `ctx.newUUID()` y `ctx.createTimer(...)`, y todo el I/O va en
> actividades, cuyo resultado queda en el historial.

```java
// Orquestador de apertura de cuenta: determinista; el I/O vive en las actividades
public void run(TaskOrchestrationContext ctx) {
    Application app = ctx.getInput(Application.class);
    ctx.callActivity("ValidateIdentity", app, Void.class).await();

    Task<Approval> approval = ctx.waitForExternalEvent("AnalystDecision", Approval.class);
    Task<Void> timeout = ctx.createTimer(Duration.ofHours(72));
    if (ctx.anyOf(approval, timeout).await() == timeout) {
        ctx.callActivity("EscalateToSupervisor", app, Void.class).await();
        return;
    }
    ctx.callActivity("CreateAccountInCore", app, Void.class).await();
}
```

- `callActivity(...).await()` programa una actividad y espera su resultado; en un replay, el resultado sale
  del historial y la actividad **no** se ejecuta otra vez.
- `waitForExternalEvent("AnalystDecision", ...)` espera un evento que otro sistema envía a esta instancia;
  la instancia no consume cómputo mientras espera.
- `createTimer(Duration.ofHours(72))` crea un temporizador durable, que sobrevive a reinicios; `anyOf`
  sigue con lo que ocurra primero.

> 🧠 **Modelo mental.** El orquestador no "está esperando" 72 horas en memoria: se descarga, y cuando llega
> el evento o vence el temporizador, se re-ejecuta desde el principio en milisegundos, saltando lo que el
> historial ya tiene, hasta el siguiente punto de espera.

---

## 3. 🧱 Logic Apps

**Logic Apps** es la plataforma de flujos **visuales**, con más de 1.400 conectores (Office 365, SAP,
Salesforce, SFTP, bases de datos, colas). Es la respuesta cuando el problema es **integración** y el
flujo lo mantienen personas que no son desarrolladores Java.

| | Consumption | Standard |
|---|---|---|
| Entorno | Multitenant compartido | Single-tenant (o App Service Environment v3) |
| Workflows por recurso | Uno | Varios, *stateful* y *stateless* |
| Facturación | Por ejecución de acción | Por plan de hosting |
| Redes privadas | Limitadas | VNet y private endpoints integrados |
| Desarrollo local | No | Sí, con Visual Studio Code |
| Cuándo | Flujos esporádicos, empezar rápido | Integración empresarial, red privada, volumen |

---

## 4. ⚖ Durable Functions frente a Logic Apps

| Criterio | Durable Functions | Logic Apps |
|---|---|---|
| Se escribe en | Código (Java, C#, Python, JavaScript…) | Diseñador visual / JSON |
| Fuerte en | Lógica compleja, algoritmos, control fino, pruebas unitarias | Conectores SaaS y sistemas empresariales |
| Lo mantiene | Desarrolladores | Integradores, también no desarrolladores |
| Versionado | Como cualquier código; cuidado con instancias en vuelo | Versiones del workflow |

```text
Regla de arquitectura:
El flujo es lógica de negocio con reglas → Durable Functions (o una saga en el propio servicio).
El flujo es mover datos entre sistemas con conectores → Logic Apps.
```

---

## 5. 🧱 GitHub Actions con OIDC

**El problema:** el pipeline tiene que desplegar en Azure. La forma antigua era un service principal
con un client secret guardado en los secretos del repositorio: una credencial de larga duración, con
permisos de despliegue, que caduca, que hay que rotar y que un workflow comprometido puede filtrar.

La forma actual es **OpenID Connect**: GitHub emite un token para cada ejecución y Entra ID lo cambia por
uno de Azure gracias a una **federated credential** ([`09` §6](09-identidad-entra-id-y-managed-identities.md#6--workload-identity-federation)). No hay secreto en ningún sitio.

**1. La identidad del pipeline y su confianza con GitHub:**

```bash
az identity create --name inv-deploy-id --resource-group inv-lab-rg --location eastus2

az identity federated-credential create \
  --name github-production \
  --identity-name inv-deploy-id \
  --resource-group inv-lab-rg \
  --issuer https://token.actions.githubusercontent.com \
  --subject repo:banco/inv-api:environment:production \
  --audiences api://AzureADTokenExchange
```

- `az identity create` crea la user-assigned identity que usará el pipeline. Una identidad **distinta** de
  las de la aplicación: el pipeline despliega, la aplicación opera.
- `--issuer https://token.actions.githubusercontent.com` es el emisor de los tokens OIDC de GitHub.
- `--subject repo:banco/inv-api:environment:production` limita la confianza a los jobs del repositorio
  `banco/inv-api` que usen el **environment** `production`. Otros formatos: `ref:refs/heads/main` para una
  rama, `pull_request` para PRs. Tiene que coincidir **exactamente** con el claim `sub` del token.
- `--audiences api://AzureADTokenExchange` es la audiencia que la acción `azure/login` pide por defecto
  en la nube pública.

A la identidad se le asignan los roles mínimos **en el scope justo** ([`10`](10-autorizacion-rbac-policy-y-gobierno.md)): `Contributor` sobre
el resource group de la carga, y la delegación condicionada de roles si el Bicep crea role assignments.

**2. El workflow:**

```yaml
# .github/workflows/deploy.yml — despliegue sin secretos
name: deploy
on:
  push:
    branches: [main]

permissions:
  id-token: write   # permite pedir el token OIDC a GitHub
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: production
    steps:
      - uses: actions/checkout@v7.0.1
      - uses: azure/login@v3.1.0
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: |
          az deployment group what-if --resource-group inv-lab-rg --template-file infra/main.bicep --parameters infra/main.bicepparam
          az deployment group create --resource-group inv-lab-rg --template-file infra/main.bicep --parameters infra/main.bicepparam
```

- `permissions: id-token: write` es **imprescindible**: sin él, el job no puede pedir el token OIDC y
  `azure/login` falla. `contents: read` deja el resto de permisos al mínimo.
- `runs-on: ubuntu-24.04` fija la imagen del runner. `ubuntu-latest` es una etiqueta que GitHub mueve a
  la siguiente versión de Ubuntu cuando le conviene, y con ella cambian las herramientas preinstaladas: el
  mismo workflow puede romperse sin que nadie lo toque.
- `environment: production` hace que el claim `sub` sea `repo:banco/inv-api:environment:production`, el
  que la federated credential acepta, y activa las reglas de protección del environment (aprobadores).
- `azure/login@v3.1.0` con `client-id`, `tenant-id` y `subscription-id` hace el intercambio OIDC. Esos
  tres valores **no son secretos**: identifican, no autentican. Van como variables. La versión se fija
  exacta, la vigente a la fecha; el ejemplo de Learn todavía muestra la v2, y la v3 solo cambió el
  runtime de Node.js a la versión 24.
- `actions/checkout@v7.0.1` descarga el repositorio, también con versión exacta. En un banco, las
  acciones de terceros se fijan además por **SHA del commit**, porque una etiqueta se puede mover.
- Los pasos siguientes usan la sesión de `az` ya iniciada; aquí, `what-if` y el despliegue del capítulo
  [`15`](15-bicep-iac.md).

> 🩺 **Diagnóstico.** El error `AADSTS70021: No matching federated identity record found` significa que
> el `sub` o el `iss` del token no coinciden con ninguna federated credential. La causa típica: el job usa
> un `environment` y la credencial se creó para la rama (`ref:refs/heads/main`), o al revés. El `sub`
> cambia de forma en cuanto el job declara un environment.

> Nunca respondas: "el pipeline necesita un client secret del service principal". Mejor: "el pipeline se
> autentica por OIDC con una federated credential acotada al repositorio y al environment; no existe
> ningún secreto que guardar, rotar o filtrar, y la identidad solo tiene los roles del resource group que
> despliega".

---

## 6. 🧱 Azure Pipelines

**Azure Pipelines** (Azure DevOps) es la alternativa de Microsoft, habitual en bancos que ya usan Azure
DevOps para repositorios y tableros:

- **stages**, **jobs** y **steps** en YAML, con plantillas reutilizables;
- **service connections** a Azure con **workload identity federation**: el mismo modelo OIDC, sin secreto,
  y el tipo recomendado para conexiones nuevas;
- **environments** con **approvals and checks**: aprobación manual, ventanas horarias, validación de una
  consulta de Azure Monitor antes de seguir;
- agentes hospedados por Microsoft o propios, útiles para desplegar en recursos con red privada.

| Criterio | GitHub Actions | Azure Pipelines |
|---|---|---|
| Dónde vive el código | GitHub | Azure Repos o GitHub |
| Autenticación a Azure sin secretos | OIDC con federated credential | Service connection con workload identity federation |
| Aprobaciones | Environments con revisores | Environments con approvals and checks, más granular |
| Ecosistema | Marketplace de acciones, enorme | Tareas de Azure DevOps, integración con Boards y Test Plans |

---

## 7. 🧱 Estrategias de despliegue

El objetivo de todas es el mismo: que un despliegue malo afecte a pocos usuarios durante poco tiempo, y
volver atrás sea un cambio de configuración, no un redespliegue.

**Blue/green**: dos entornos idénticos; el nuevo (*green*) se valida y el tráfico se cambia **de golpe**.
Volver atrás es devolver el tráfico al *blue*.

**Canary**: la versión nueva recibe **un porcentaje** del tráfico (5 %, 25 %, 100 %), vigilando métricas
en cada paso. Detecta el problema con pocos usuarios afectados.

En Azure, cada servicio lo implementa a su manera:

- **App Service, deployment slots** ([`04` §4](04-computo-y-contenedores.md#4--app-service)): se despliega en el slot `staging`, que se calienta,
  y se hace **swap** con producción. Es blue/green, y con *traffic routing* de un porcentaje al slot, un
  canary. Volver atrás es otro swap;
- **Container Apps, revisiones** ([`04` §6](04-computo-y-contenedores.md#6--revisiones-y-reparto-de-tráfico)): con el modo de revisiones múltiples, la revisión
  nueva recibe un peso del tráfico (`--revision-weight inv-api--v1=90 inv-api--v2=10`) y se sube por
  pasos. [`L05`](l05-container-apps-revisiones-trafico-y-escala.md) lo practica;
- **Front Door o Traffic Manager** delante de dos despliegues completos, para blue/green entre regiones o
  entornos enteros.

> ⚠️ **El swap de slots no es downtime cero siempre.** Antes de cambiar, App Service aplica al slot de
> origen los settings del destino, lo que **reinicia sus instancias**, y lo calienta con una petición HTTP
> a la raíz (o a la ruta de `applicationInitialization`). **Cualquier respuesta HTTP cuenta como
> caliente**, también un `500`: si la aplicación arranca rota, el swap sigue. Y un setting que no se marcó
> como *deployment slot setting* viaja con el código: el staging acaba en producción apuntando a la base
> de pruebas, o al revés.

> Nunca respondas: "hacemos swap de slots, así que no hay downtime". Mejor: "hacemos swap con warm-up
> configurado en una ruta de salud que comprueba dependencias, con los settings de ambiente marcados como
> slot settings, y usamos *swap with preview* para validar el slot con la configuración de producción
> antes de completar".

---

## 8. 🧱 Promoción entre ambientes

- **Separar ambientes por suscripción** (desarrollo, pruebas, producción), no solo por resource group:
  permite RBAC, políticas, presupuestos y límites independientes, y es lo que proponen las landing zones
  ([`10` §13](10-autorizacion-rbac-policy-y-gobierno.md#13--tags-landing-zones-y-el-fin-de-blueprints)).
- **Construir una vez, desplegar muchas**: el mismo artefacto (la misma imagen, por digest) pasa por
  todos los ambientes; lo que cambia es la configuración. Reconstruir por ambiente rompe la garantía de que
  lo probado es lo desplegado.
- **Una identidad de despliegue por ambiente**, cada una con su federated credential ligada a su
  environment de GitHub o de Azure Pipelines: el pipeline de pruebas no puede tocar producción aunque
  alguien cambie el YAML.
- **Aprobación antes de producción**, en el environment, y el `what-if` publicado para quien aprueba.

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "El pipeline necesita un client secret" | OIDC con federated credential, sin secretos |
| "Los IDs de `azure/login` son secretos" | Client, tenant y subscription ID identifican, no autentican |
| "Olvidé `id-token: write`, pero da igual" | Sin ese permiso no hay token OIDC y el login falla |
| "La federated credential de `main` sirve para el job con environment" | Con environment el `sub` cambia; hace falta otra credencial |
| "Swap de slots es downtime cero siempre" | Reinicia el origen, cualquier respuesta cuenta como caliente y los settings no marcados viajan |
| "En el orquestador puedo llamar a la API directamente" | El I/O va en actividades; el orquestador se re-ejecuta en cada replay |
| "`Instant.now()` en el orquestador está bien" | No es determinista; se usa `ctx.getCurrentInstant()` |
| "Reconstruyo la imagen para producción" | Se promueve el mismo artefacto, por digest |

---

## 🧠 Preguntas rápidas

1. ¿Qué problema resuelve Durable Functions frente a encadenar Functions normales?
2. ¿Qué es el replay de un orquestador y qué reglas impone al código?
3. ¿Cómo implementas con Durable Functions una aprobación humana que vence a las 72 horas?
4. ¿Cuándo elegirías Logic Apps en lugar de Durable Functions?
5. ¿Qué diferencia hay entre Logic Apps Consumption y Standard?
6. ¿Por qué un pipeline no debería autenticarse en Azure con un client secret, y qué usa en su lugar?
7. ¿Qué tres campos tiene la federated credential de GitHub Actions y qué valor lleva el `subject` para un environment?
8. ¿Qué pasa si el workflow no declara `permissions: id-token: write`?
9. El login falla con `AADSTS70021`. ¿Qué revisas?
10. ¿Qué roles le das a la identidad del pipeline y en qué scope?
11. ¿Cómo se autentica Azure Pipelines en Azure sin secretos y qué aporta un environment con checks?
12. ¿Qué diferencia hay entre blue/green y canary, y cómo implementas cada uno en Container Apps?
13. ¿Por qué el swap de slots de App Service no garantiza downtime cero?
14. ¿Qué es un *deployment slot setting* y qué pasa si olvidas marcar la cadena de conexión?
15. ¿Por qué separar ambientes por suscripción y promover el mismo artefacto?

---

## 📚 Referencias oficiales

- ¿Qué es Durable Functions?: https://learn.microsoft.com/en-us/azure/durable-task/durable-functions/durable-functions-overview
- Restricciones del código del orquestador: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-code-constraints
- Patrón de interacción humana y temporizadores: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-timers
- ¿Qué es Azure Logic Apps?: https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview
- Logic Apps Standard frente a Consumption: https://learn.microsoft.com/en-us/azure/logic-apps/single-tenant-overview-compare
- Autenticarse en Azure desde GitHub Actions con OIDC: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- Federated credential en una user-assigned identity: https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust-user-assigned-managed-identity
- Workload identity federation: https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation
- Service connections de Azure Pipelines con workload identity federation: https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure
- Environments de Azure Pipelines: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments
- Approvals and checks: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/approvals
- Deployment slots de App Service: https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots
- Buenas prácticas de despliegue en App Service: https://learn.microsoft.com/en-us/azure/app-service/deploy-best-practices
- Reparto de tráfico en Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/traffic-splitting
- Blue/green en Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/blue-green-deployment
- `az identity federated-credential`: https://learn.microsoft.com/en-us/cli/azure/identity/federated-credential
