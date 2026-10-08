# L05 — Container Apps: revisiones, tráfico y escala

> **Objetivo:** desplegar `inv-api`, una API Spring Boot mínima, en Container Apps sin una sola
> credencial guardada: la imagen se construye en local para `linux/amd64`, se sube a un Container
> Registry que se tira con `AcrPull` y una managed identity, el secreto de Key Vault llega como Key
> Vault reference, y el tráfico se reparte entre revisiones para un canary. Por el camino se provocan
> tres fallos del contrato de la plataforma y se mide el cold start de la JVM.
> **Se asume leído:** [`04` §5–§7 y §10](04-computo-y-contenedores.md#5--container-apps) (Container
> Apps, revisiones, escala y registry) y [`11` §7](11-secretos-cifrado-y-key-vault.md#7--consumir-secretos-desde-la-aplicación)
> (Key Vault references). Complementa [`16` §7](16-orquestacion-y-cicd.md#7--estrategias-de-despliegue).
> **Costo:** **~$0.17 por cada día que exista el registry** (Container Registry Basic a $0.1666/día,
> cargo diario, no por hora). Container Apps queda dentro de su free grant mensual (180.000
> vCPU-segundos, 360.000 GiB-segundos y 2 millones de requests); el workspace, dentro de los 5 GB de
> ingesta gratuitos al mes.
> **Duración:** 3 horas.
> **Prerrequisitos:** [`L03`](l03-bicep-desde-la-cli.md) terminado (identidades y vault con sus roles),
> y en local **JDK 21, Maven 3.9 y Docker**.
> **Qué queda encendido al terminar:** `inv-lab-law`, `invlabacr472913` con tres imágenes,
> `inv-lab-env` y la app `inv-api` en modo de revisiones múltiples, **escalada a cero**. El único cargo
> que corre es el diario del registry, y se queda a propósito hasta [`L09`](l09-costos-y-destruccion-verificada.md).
> **Estado:** redactado, pendiente de corrida. Los bloques `[PENDIENTE DE CORRIDA]` dicen qué
> debe mostrar cada comando; la salida literal se pega al correrlo.
> **Vigencia:** 29 de septiembre de 2026. Java 21, Spring Boot **4.0.8**, imagen
> `mcr.microsoft.com/openjdk/jdk:21-distroless` fijada por digest.

**Salto rápido:** [Qué se practica](#1--qué-se-practica-y-qué-no) · [Arranque](#2--arranque-y-versiones-locales) ·
[Workspace](#3--el-log-analytics-workspace-declarado) · [Environment](#4--el-environment) ·
[Registry](#5--el-container-registry-sin-admin-user) · [La app](#6--la-aplicación-y-su-imagen) ·
[Primera revisión](#7--la-primera-revisión) · [Imagen arm64](#8--una-revisión-que-no-arranca-la-imagen-arm64) ·
[Puerto equivocado](#9--un-cambio-que-rompe-todas-las-revisiones-el-puerto) ·
[Key Vault reference](#10--el-secreto-de-key-vault-sin-una-línea-de-código) ·
[Canary](#11--canary-con-revisiones-múltiples) · [Escala a cero](#12--escala-a-cero-y-el-cold-start-de-la-jvm) ·
[Estado final](#13--teardown-y-lo-que-queda-encendido) · [Checklist](#-checklist-de-salida) ·
[Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 Qué se practica, y qué no

Este lab pasa la prueba de la doctrina de reparto por la razón inversa a AKS
([`L00` §3](l00-idea-lab-practico.md#3--el-caso-testigo-por-qué-no-montamos-un-microservicio-en-aks)):
**no hay nada de Container Apps que se aprenda en local**. Un `docker run` de la misma imagen corre el
mismo código, pero no tiene revisiones, reparto de tráfico, escala a cero con KEDA, identidad
administrada, Key Vault references ni el contrato de ingress.

Lo que **no** se practica aquí: Spring Boot. La app tiene un controlador y un endpoint; lo que importa
es la costura con la plataforma. La validación de tokens llega en
[`L06`](l06-identidad-de-aplicaciones-api-protegida.md), y los datos y mensajes, en
[`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md).

```text
   tu portátil                        Azure (inv-lab-rg)
   mvn package → docker build ──push──► invlabacr472913 (Basic)
   --platform linux/amd64                   │ AcrPull
                                            ▼
                              inv-lab-env ── inv-api (identidad inv-api-id)
                                  │            │ Key Vault reference
                                  │            ▼
                              inv-lab-law   inv-lab-kv-472913
```

---

## 2. 🧱 Arranque y versiones locales

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-inv-lab"
SUB=$(az account show --query id --output tsv)
java -version && mvn -version && docker version --format '{{.Server.Os}}/{{.Server.Arch}}'
```

- `java -version` tiene que decir 21; `mvn -version`, 3.9 y que usa ese JDK.
- `docker version --format ...` imprime el sistema y la arquitectura **del motor de Docker**. En un Mac
  con Apple silicon es `linux/arm64`, y eso es lo que decide la arquitectura de una imagen construida
  sin `--platform`: la sección 8 vive de este dato.

```text
[PENDIENTE DE CORRIDA] openjdk version "21.x", Apache Maven 3.9.x y linux/arm64 (Apple silicon) o
linux/amd64 (Intel o Linux).
```

Las variables que se usan en todo el lab:

```bash
API_ID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query id --output tsv)
API_PID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query principalId --output tsv)
API_CLIENT_ID=$(az identity show --name inv-api-id --resource-group inv-lab-rg --query clientId --output tsv)
```

- Los tres identificadores de la identidad de [`L02` §9](l02-entra-id-rbac-y-managed-identities.md#9--dos-user-assigned-managed-identities),
  cada uno para lo suyo: el `id` para asociarla, el `principalId` para darle roles, el `clientId` para
  que el código la elija.

---

## 3. 🧱 El Log Analytics workspace, declarado

[`04` §5](04-computo-y-contenedores.md#5--container-apps) avisa: **`az containerapp env create` sin
workspace crea uno nuevo con nombre aleatorio**, que nadie recuerda borrar. El lab crea el suyo antes.

**Teardown antes que el despliegue.** Un workspace borrado queda **14 días en soft-delete** con el
nombre reservado, salvo que se borre con `--force` ([`L00` §7.3](l00-idea-lab-practico.md#73-el-resource-group-es-la-unidad-de-destrucción-con-letra-pequeña)).
[`L09`](l09-costos-y-destruccion-verificada.md) lo borra así; `az group delete` no lo fuerza.

```bash
az monitor log-analytics workspace create \
  --workspace-name inv-lab-law \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku PerGB2018 \
  --retention-time 30 \
  --tags project=inv-lab env=lab \
  --query "{name:name, customerId:customerId, retention:retentionInDays}"
```

- `--workspace-name` admite de 4 a 63 caracteres alfanuméricos y guiones.
- `--sku PerGB2018` es el modelo de pago por GB ingerido: $2.76 por GB en tablas Analytics en
  `eastus2`, con los **primeros 5 GB al mes gratis** ([`14` §4](14-observabilidad-monitor-log-analytics-app-insights.md#4--el-log-analytics-workspace)).
- `--retention-time 30` fija 30 días de retención interactiva; el precio de ingesta ya incluye 31, así
  que bajar de ahí no ahorra nada.
- `customerId` es el **workspace ID**: un GUID distinto del resource ID, que es lo que pide el
  environment.

```text
[PENDIENTE DE CORRIDA] name inv-lab-law, un customerId (GUID) y retention 30.
```

---

## 4. 🧱 El environment

El **environment** es la frontera de red y de logs que comparten las apps ([`04` §5](04-computo-y-contenedores.md#5--container-apps)).

**Teardown:** el environment vive en `inv-lab-rg` y muere con él. Sin VNet propia —decisión D7 de
[`L00` §11](l00-idea-lab-practico.md#11--decisiones-las-cerradas-y-las-que-siguen-abiertas)— no crea
un resource group de infraestructura aparte.

```bash
LAW_CUSTOMER_ID=$(az monitor log-analytics workspace show --workspace-name inv-lab-law \
  --resource-group inv-lab-rg --query customerId --output tsv)
LAW_KEY=$(az monitor log-analytics workspace get-shared-keys --workspace-name inv-lab-law \
  --resource-group inv-lab-rg --query primarySharedKey --output tsv)

az containerapp env create \
  --name inv-lab-env \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --logs-destination log-analytics \
  --logs-workspace-id "$LAW_CUSTOMER_ID" \
  --logs-workspace-key "$LAW_KEY" \
  --tags project=inv-lab env=lab \
  --query "{name:name, state:properties.provisioningState, domain:properties.defaultDomain}"
unset LAW_KEY
```

- `get-shared-keys` devuelve las claves del workspace. **Son un secreto**: se guardan en una variable
  sin imprimirlas y se borran con `unset` al terminar.
- `--logs-destination log-analytics` con `--logs-workspace-id` y `--logs-workspace-key` manda los logs
  de consola y de sistema de las apps a `inv-lab-law`. La alternativa sin clave es `azure-monitor`, que
  delega el destino en diagnostic settings ([`14` §5](14-observabilidad-monitor-log-analytics-app-insights.md#5--diagnostic-settings)).
- No se pasa `--enable-workload-profiles`: su valor por defecto es `true`, y el environment nace con
  el perfil **Consumption**, el del free grant. Los perfiles Dedicated, que sí cobran un cargo de gestión,
  no se añaden.

```text
[PENDIENTE DE CORRIDA] name inv-lab-env, state Succeeded y un defaultDomain del estilo
<palabras>-<hash>.eastus2.azurecontainerapps.io. Tarda unos minutos.
```

---

## 5. 🧱 El Container Registry, sin admin user

> 💰 **Costo.** Container Registry Basic cuesta **$0.1666 al día** en `eastus2`, con 10 GiB
> incluidos. **La unidad es el día**: un registry que existe diez minutos cobra el día. Por eso se crea
> una vez aquí y se destruye en [`L09`](l09-costos-y-destruccion-verificada.md), sin recrearlo entre medias.

**Teardown:** el registry y sus imágenes mueren con `inv-lab-rg`.

```bash
az acr create \
  --name invlabacr472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku Basic \
  --admin-enabled false \
  --role-assignment-mode rbac \
  --tags project=inv-lab env=lab \
  --query "{loginServer:loginServer, admin:adminUserEnabled}"
ACR_ID=$(az acr show --name invlabacr472913 --query id --output tsv)
```

- `--name invlabacr472913` admite de 5 a 50 caracteres **solo alfanuméricos**, sin guiones, y es único
  en todo Azure: forma el host `invlabacr472913.azurecr.io`.
- `--admin-enabled false` deja deshabilitado el **admin user**, el usuario y contraseña compartidos
  del registry. Ya es el valor por defecto; se escribe porque es la credencial que el curso evita.
- `--role-assignment-mode rbac` fija el modo de permisos **clásico**, en el que el rol `AcrPull`
  funciona. En el modo `rbac-abac`, que la documentación anuncia como futuro valor por defecto,
  `AcrPull` y `AcrPush` **no se respetan** y hacen falta los roles *Container Registry Repository
  Reader/Writer*. El lab lo declara para no depender de cuándo cambie el default.

```text
[PENDIENTE DE CORRIDA] loginServer invlabacr472913.azurecr.io y admin false.
```

El rol de pull para la identidad de la app, **antes** de crear la app, para que haya propagado:

```bash
az role assignment create \
  --assignee-object-id "$API_PID" \
  --assignee-principal-type ServicePrincipal \
  --role AcrPull \
  --scope "$ACR_ID" \
  --description "L05: inv-api tira sus imagenes"
```

- `AcrPull` solo permite leer imágenes, en el data plane del registry. Nada de push ni de gestión.
- Si no lo asignas tú, `az containerapp create --registry-identity` **intenta crear esa asignación por
  su cuenta** cuando tus permisos lo permiten, según su referencia. El lab la crea antes y a la vista:
  un permiso que aparece solo es un permiso que nadie documenta, y así ya habrá propagado cuando la
  plataforma tire la primera imagen.
- En modo `rbac`, tu rol de Owner te permite hacer push sin otro rol. En producción, quien empuja es
  la identidad del pipeline con `AcrPush`.

---

## 6. 🧱 La aplicación y su imagen

Una app Spring Boot con un endpoint que dice qué versión y qué revisión atienden, y si recibió el
secreto (sin mostrarlo). Crea la estructura en `~/inv-lab/inv-api`:

```text
~/inv-lab/inv-api
├── pom.xml
├── Dockerfile
└── src/main
    ├── java/dev/invlab/api/InventoryApiApplication.java
    └── resources/application.properties
```

El `pom.xml`, con versiones exactas:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.8</version>
    <relativePath/>
  </parent>
  <groupId>dev.invlab</groupId>
  <artifactId>inv-api</artifactId>
  <version>0.1.0</version>
  <properties>
    <java.version>21</java.version>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
  </dependencies>
  <build>
    <finalName>inv-api</finalName>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

- `spring-boot-starter-parent` **4.0.8**, el último parche de la rama 4.0 en Maven Central a la fecha,
  fija las versiones de todas las dependencias de Spring.
- `spring-boot-starter-webmvc` es el starter de Spring MVC en Spring Boot 4; el antiguo
  `spring-boot-starter-web` sigue existiendo pero está deprecado en su favor.
- `<finalName>inv-api</finalName>` hace que el JAR se llame `inv-api.jar`, sin la versión, para que el
  Dockerfile no cambie en cada release.

El código:

```java
// InventoryApiApplication.java — lo justo para ver la plataforma desde dentro
package dev.invlab.api;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class InventoryApiApplication {

    @Value("${app.version}")
    private String version;

    // el valor llega de Key Vault como variable de entorno; la API nunca lo devuelve
    @Value("${PARTNER_API_KEY:}")
    private String partnerApiKey;

    public static void main(String[] args) {
        SpringApplication.run(InventoryApiApplication.class, args);
    }

    @GetMapping("/api/info")
    public Map<String, Object> info() {
        return Map.of(
                "version", version,
                // variable que Container Apps inyecta en cada réplica
                "revision", System.getenv().getOrDefault("CONTAINER_APP_REVISION", "local"),
                "partnerKeyLoaded", !partnerApiKey.isBlank());
    }
}
```

```properties
# application.properties
server.port=8080
app.version=@project.version@
management.endpoints.web.exposure.include=health
management.endpoint.health.probes.enabled=true
```

- `CONTAINER_APP_REVISION` es una de las variables que Container Apps **inyecta sola** en cada réplica,
  junto con `CONTAINER_APP_NAME` y `CONTAINER_APP_REPLICA_NAME`. Es lo que permite ver, desde fuera,
  qué revisión atendió cada petición.
- `@project.version@` lo sustituye Maven al construir: la versión del `pom.xml` viaja al JAR.
- `management.endpoint.health.probes.enabled=true` expone `/actuator/health/liveness` y `/readiness`,
  los endpoints que una plataforma usa para decidir si una réplica recibe tráfico.
- `server.port=8080` es el puerto que la sección 9 va a contradecir a propósito.

El Dockerfile, con la imagen base de Microsoft **fijada por digest**:

```dockerfile
# Dockerfile de inv-api: el JAR se construye fuera, la imagen solo lo empaqueta
FROM mcr.microsoft.com/openjdk/jdk:21-distroless@sha256:ea7cd567f254e745a9663e8bb8ed2d49f3728a76f9f48f22a0a88d86b1dd12bf
COPY target/inv-api.jar /app/inv-api.jar
USER app
# la imagen distroless ya trae "java" como ENTRYPOINT: aquí solo van sus argumentos
CMD ["-jar", "/app/inv-api.jar"]
```

- `mcr.microsoft.com/openjdk/jdk:21-distroless` es el Microsoft Build of OpenJDK 21 sobre Azure Linux
  3.0, sin shell ni gestor de paquetes. Sus etiquetas solo existen por versión mayor y **se mueven**
  con cada parche; el `@sha256:…` fija la imagen exacta, como recomienda la propia documentación. El
  digest es el del índice multiarquitectura a la fecha de vigencia: contiene una variante `amd64` y
  otra `arm64`.
- `USER app` ejecuta la JVM con el usuario sin privilegios que trae la imagen, no como root.
- `CMD` completa el `ENTRYPOINT` de la imagen, que ya es `java`.

Construye el JAR y la imagen **para la plataforma de Container Apps**, y súbela:

```bash
cd ~/inv-lab/inv-api
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-api:0.1.0 .
az acr login --name invlabacr472913
docker push invlabacr472913.azurecr.io/inv-api:0.1.0
```

- `mvn -q package -DskipTests` compila y empaqueta `target/inv-api.jar`. La app no tiene pruebas que
  merezcan el tiempo del lab.
- `docker build --platform linux/amd64` construye la imagen **para `amd64`**, la arquitectura de los
  nodos de Container Apps, aunque tu motor sea `arm64`: Docker elige la variante `amd64` del índice de
  la imagen base. El JAR es bytecode y no depende de la arquitectura.
- `-t invlabacr472913.azurecr.io/inv-api:0.1.0` etiqueta con el host del registry y una **versión
  fija**. Nunca `latest`: una revisión es inmutable y su imagen también debe serlo.
- `az acr login` obtiene un token de Entra ID para el registry y lo entrega a Docker como credencial.
  No usa ninguna contraseña del registry.

```text
[PENDIENTE DE CORRIDA] "Login Succeeded" y el push con el digest de la imagen subida.
```

---

## 7. 🧱 La primera revisión

```bash
az containerapp create \
  --name inv-api \
  --resource-group inv-lab-rg \
  --environment inv-lab-env \
  --image invlabacr472913.azurecr.io/inv-api:0.1.0 \
  --user-assigned "$API_ID" \
  --registry-server invlabacr472913.azurecr.io \
  --registry-identity "$API_ID" \
  --ingress external \
  --target-port 8080 \
  --cpu 0.5 --memory 1.0Gi \
  --min-replicas 0 --max-replicas 2 \
  --revision-suffix v1 \
  --env-vars AZURE_CLIENT_ID="$API_CLIENT_ID" \
  --tags project=inv-lab env=lab \
  --query "properties.configuration.ingress.fqdn" --output tsv
```

Los flags que [`04` §5](04-computo-y-contenedores.md#5--container-apps) no explicó:

- `--registry-identity "$API_ID"` recibe el **resource ID** de la identidad con la que la plataforma
  tira la imagen. Tiene `AcrPull` desde la sección 5.
- `--cpu 0.5 --memory 1.0Gi` es una de las combinaciones admitidas en Consumption (la memoria va
  ligada a la CPU). 1 GiB es lo razonable para una JVM pequeña.
- `--max-replicas 2` pone un techo al gasto y a la sorpresa.
- `--revision-suffix v1` nombra la revisión `inv-api--v1` en vez de con un sufijo aleatorio: las
  secciones siguientes la llaman por su nombre.
- `--env-vars AZURE_CLIENT_ID=...` deja en el contenedor el `clientId` de `inv-api-id`, que es lo que
  `DefaultAzureCredential` usará en [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) para elegir esa identidad.

```text
[PENDIENTE DE CORRIDA] El FQDN de la app: inv-api.<palabras>-<hash>.eastus2.azurecontainerapps.io.
```

Pruébala. La primera petición puede tardar: la app arranca desde cero réplicas.

```bash
FQDN=$(az containerapp show --name inv-api --resource-group inv-lab-rg \
  --query properties.configuration.ingress.fqdn --output tsv)
curl -s "https://$FQDN/api/info"; echo
az containerapp revision list --name inv-api --resource-group inv-lab-rg \
  --query "[].{name:name, active:properties.active, traffic:properties.trafficWeight, health:properties.healthState}" --output table
```

```text
[PENDIENTE DE CORRIDA] {"version":"0.1.0","revision":"inv-api--v1","partnerKeyLoaded":false}
y una fila: inv-api--v1, active True, traffic 100, health Healthy.
```

El certificado HTTPS de ese FQDN lo emite y lo renueva la plataforma sin costo. Es la razón por la que
el lab no pone Front Door ni Application Gateway delante ([`L00` §4](l00-idea-lab-practico.md#4--el-catálogo-completo-de-exclusiones)).

---

## 8. 🩺 Una revisión que no arranca: la imagen `arm64`

La app está en modo **single** (el defecto): solo una revisión activa. Ahora despliega una imagen
construida para la arquitectura equivocada, como sale por defecto de un Mac con Apple silicon. El lab
la fuerza con `--platform linux/arm64` para que el fallo se reproduzca en cualquier máquina:

```bash
docker build --platform linux/arm64 -t invlabacr472913.azurecr.io/inv-api:0.1.0-arm64 .
docker image inspect invlabacr472913.azurecr.io/inv-api:0.1.0-arm64 --format '{{.Os}}/{{.Architecture}}'
docker push invlabacr472913.azurecr.io/inv-api:0.1.0-arm64

az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.1.0-arm64 --revision-suffix arm --output none
```

- `docker image inspect --format '{{.Os}}/{{.Architecture}}'` es **el** comando de diagnóstico de este
  fallo: dice para qué plataforma es la imagen, sin arrancarla.
- `az containerapp update --image ... --revision-suffix arm` cambia la imagen, un cambio de ámbito de
  revisión: crea `inv-api--arm`.

```text
[PENDIENTE DE CORRIDA] linux/arm64. El update termina, pero la revisión inv-api--arm no llega a
estar lista.
```

Mira qué dice la plataforma:

```bash
az containerapp revision list --name inv-api --resource-group inv-lab-rg \
  --query "[].{name:name, active:properties.active, traffic:properties.trafficWeight, running:properties.runningState, health:properties.healthState}" --output table
az containerapp logs show --name inv-api --resource-group inv-lab-rg \
  --revision inv-api--arm --type system --tail 20 --format text
curl -s "https://$FQDN/api/info"; echo
```

- `az containerapp logs show --type system` muestra los **eventos de la plataforma** (tirar la imagen,
  crear el contenedor, probes), no la salida de tu app, que es `--type console`.

```text
[PENDIENTE DE CORRIDA] inv-api--arm con running state de fallo y health Unhealthy (o sin
réplicas sanas); inv-api--v1 sigue con traffic 100. En los logs de sistema, el error de la
plataforma al tirar o arrancar la imagen (sin variante para linux/amd64, o "exec format error").
Y el curl sigue respondiendo version 0.1.0 desde inv-api--v1.
```

Dos lecciones:

- **El modo single protege del cambio roto.** La revisión nueva no recibe tráfico hasta estar lista; si
  nunca lo está, el tráfico se queda en la anterior ([`04` §6](04-computo-y-contenedores.md#6--revisiones-y-reparto-de-tráfico)).
  Nadie vio el fallo desde fuera.
- **La causa no está en el código.** El mismo JAR, empaquetado para otra arquitectura, no arranca. El
  arreglo es el `--platform linux/amd64` de la sección 6, no un cambio en la app.

Desactiva la revisión rota; queda en el historial, sin cobrar:

```bash
az containerapp revision deactivate --name inv-api --resource-group inv-lab-rg --revision inv-api--arm
```

---

## 9. 🩺 Un cambio que rompe todas las revisiones: el puerto

El modo single protege de los cambios **de revisión**. Los de **aplicación** —ingress, secretos,
registry— se aplican a todas las revisiones a la vez, sin crear una nueva. Pruébalo con el más típico,
declarar un puerto en el que el contenedor no escucha:

```bash
az containerapp ingress update --name inv-api --resource-group inv-lab-rg --target-port 80 --output none
curl -s -o /dev/null -w '%{http_code}\n' "https://$FQDN/api/info"
az containerapp logs show --name inv-api --resource-group inv-lab-rg --revision inv-api--v1 \
  --type system --tail 20 --format text
```

- `ingress update --target-port 80` le dice a la plataforma que el contenedor escucha en el 80. Spring
  Boot sigue en el 8080.

```text
[PENDIENTE DE CORRIDA] Un código de error del ingress (502, 503 o 504, según el momento) en vez
de 200, y en los logs de sistema las probes fallando contra el puerto 80.
```

Las probes por defecto de una app con ingress son **TCP contra el target port**
([documentación de health probes](https://learn.microsoft.com/en-us/azure/container-apps/health-probes)):
con el puerto equivocado, la plataforma no encuentra nada escuchando, deja de mandar tráfico a las
réplicas y las acaba reiniciando. Y esta vez **no hay revisión anterior que te salve**: el ingress es de
la app, no de la revisión.

```bash
az containerapp ingress update --name inv-api --resource-group inv-lab-rg --target-port 8080 --output none
curl -s "https://$FQDN/api/info"; echo
```

```text
[PENDIENTE DE CORRIDA] {"version":"0.1.0","revision":"inv-api--v1","partnerKeyLoaded":false},
quizá tras unos segundos de espera.
```

> 🧠 **Modelo mental.** `properties.template` es la revisión: imagen, variables, recursos, escala. Un
> error ahí lo absorbe el modo single. `properties.configuration` es la app: ingress, secretos,
> registries, tráfico. Un error ahí rompe todas las revisiones a la vez, y es donde un despliegue con
> prisa hace más daño.

---

## 10. 🧱 El secreto de Key Vault, sin una línea de código

En [`L02` §11](l02-entra-id-rbac-y-managed-identities.md#11--key-vault-con-azure-rbac) le diste a
`inv-api-id` el rol `Key Vault Secrets User` sobre el vault, pero no había dónde ejercerlo. Ahora sí:
la plataforma lee el secreto con esa identidad, como [`11` §7](11-secretos-cifrado-y-key-vault.md#7--consumir-secretos-desde-la-aplicación)
describe.

```bash
az containerapp secret set --name inv-api --resource-group inv-lab-rg \
  --secrets "partner-api-key=keyvaultref:https://inv-lab-kv-472913.vault.azure.net/secrets/partner-api-key,identityref:$API_ID"

az containerapp update --name inv-api --resource-group inv-lab-rg \
  --revision-suffix v2 --set-env-vars PARTNER_API_KEY=secretref:partner-api-key --output none
```

- `secret set` con `keyvaultref:<uri>,identityref:<id>` declara un secreto **de la app** cuyo valor
  vive en Key Vault. La URI va **sin versión**: Container Apps recoge una versión nueva en hasta 30
  minutos. El nombre del secreto en la app no puede pasar de 20 caracteres.
- Es un cambio de **aplicación**: no crea revisión, y un contenedor en ejecución no lo ve.
- `update --set-env-vars PARTNER_API_KEY=secretref:partner-api-key` crea la variable de entorno a
  partir del secreto. Es un cambio de **revisión**: crea `inv-api--v2`, que arranca ya con el valor.

```bash
curl -s "https://$FQDN/api/info"; echo
az containerapp secret list --name inv-api --resource-group inv-lab-rg --output table
```

```text
[PENDIENTE DE CORRIDA] {"version":"0.1.0","revision":"inv-api--v2","partnerKeyLoaded":true} y la
lista de secretos con partner-api-key, su keyVaultUrl y su identity, sin valor.
```

Ese `true` cierra el bucle de [`L02`](l02-entra-id-rbac-y-managed-identities.md): **la managed identity leyó el secreto**, en un host de Azure, sin
que ninguna credencial pasara por tu terminal ni por la configuración de la app.

> 🩺 **Diagnóstico.** Si la revisión `v2` no arranca y los logs de sistema hablan del secreto, las dos
> causas habituales son la identidad (el `identityref` no es el resource ID de una identidad asignada a
> la app, o le falta `Key Vault Secrets User`) y la red del vault. El vault del lab tiene acceso
> público, así que queda la primera: `az role assignment list --assignee "$API_PID" --all`.

---

## 11. ⚖ Canary con revisiones múltiples

Un canary manda **un porcentaje pequeño** del tráfico a la versión nueva y lo sube mientras las métricas
acompañan ([`16` §7](16-orquestacion-y-cicd.md#7--estrategias-de-despliegue)). En Container Apps
necesita el modo **multiple**:

```bash
az containerapp revision set-mode --name inv-api --resource-group inv-lab-rg --mode multiple
```

La versión nueva: cambia `<version>0.1.0</version>` por `0.2.0` en el `pom.xml`, y construye y sube:

```bash
mvn -q package -DskipTests
docker build --platform linux/amd64 -t invlabacr472913.azurecr.io/inv-api:0.2.0 .
docker push invlabacr472913.azurecr.io/inv-api:0.2.0

az containerapp update --name inv-api --resource-group inv-lab-rg \
  --image invlabacr472913.azurecr.io/inv-api:0.2.0 --revision-suffix v3 --output none

az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v2=90 inv-api--v3=10
```

- En modo multiple, la revisión nueva **no recibe tráfico** al crearse: queda activa y esperando. Es
  exactamente lo contrario del modo single.
- `ingress traffic set --revision-weight` reparte por nombre de revisión; los pesos suman 100.

Mide el reparto con cien peticiones:

```bash
for i in $(seq 1 100); do curl -s "https://$FQDN/api/info" | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])"; done | sort | uniq -c
```

```text
[PENDIENTE DE CORRIDA] Unas 90 respuestas 0.1.0 y unas 10 respuestas 0.2.0. El reparto es
aproximado, no exacto.
```

Sube el canary al 100 % y desactiva la versión anterior:

```bash
az containerapp ingress traffic set --name inv-api --resource-group inv-lab-rg \
  --revision-weight inv-api--v2=0 inv-api--v3=100
az containerapp revision deactivate --name inv-api --resource-group inv-lab-rg --revision inv-api--v2
```

- Una revisión inactiva no cobra y se conserva (hasta 100) para un rollback: reactivarla y devolverle el
  tráfico es un comando.

> ⚠️ **En modo multiple, el siguiente `az containerapp update` crea una revisión sin tráfico.** Si
> olvidas el `traffic set`, has "desplegado" una versión que nadie recibe. Es el error más común al
> pasar de single a multiple, y la razón por la que un pipeline de canary termina siempre con la
> asignación de pesos.

---

## 12. 🧪 Escala a cero, y el cold start de la JVM

Deja de llamar a la app unos minutos: el cooldown antes de bajar a cero es de 300 segundos
([`04` §7](04-computo-y-contenedores.md#7--escalado-con-keda-y-escala-a-cero)).

```bash
az containerapp replica list --name inv-api --resource-group inv-lab-rg --revision inv-api--v3 \
  --query "length(@)"
```

- `replica list` cuenta las réplicas de una revisión. `length(@)` devuelve el número.

```text
[PENDIENTE DE CORRIDA] 1 mientras hay tráfico reciente; 0 pasados unos cinco minutos sin peticiones.
```

Con cero réplicas, mide la primera petición y la segunda:

```bash
curl -s -o /dev/null -w 'primera: %{time_total}s\n' "https://$FQDN/api/info"
curl -s -o /dev/null -w 'segunda: %{time_total}s\n' "https://$FQDN/api/info"
```

- `-w '%{time_total}'` imprime el tiempo total de la petición, sin el cuerpo.

```text
[PENDIENTE DE CORRIDA] La primera, varios segundos (arranque del contenedor y de Spring Boot);
la segunda, decenas de milisegundos. Anota los dos números: son tu cold start real.
```

Esa diferencia es el precio de la escala a cero con la JVM. Las tres salidas, cada una con su costo:
`--min-replicas 1` (sin cold start, pero la réplica cobra siempre y consume el free grant en unos
cuatro días), acelerar el arranque de la app, o aceptar la latencia de la primera petición.

---

## 13. 🧪 Teardown, y lo que queda encendido

| Recurso | ¿Cobra? | Estado al terminar | Quién lo destruye |
|---|---|---|---|
| `invlabacr472913` y sus imágenes | **$0.1666 al día** | Vivo, a propósito | [`L09`](l09-costos-y-destruccion-verificada.md) |
| `inv-lab-env` | No (Consumption) | Vivo | Con el grupo, en [`L09`](l09-costos-y-destruccion-verificada.md) |
| `inv-api` (revisión `v3` activa, a cero) | Solo con réplicas, dentro del free grant | Viva | Con el grupo, en [`L09`](l09-costos-y-destruccion-verificada.md) |
| Revisiones `v1`, `arm`, `v2` | No | Inactivas | Con la app |
| `inv-lab-law` | Ingesta por encima de 5 GB/mes | Vivo; [`L08`](l08-observabilidad-kql-y-auditoria.md) lo usa | [`L09`](l09-costos-y-destruccion-verificada.md), con `--force` |
| Role assignment `AcrPull` | No | Vivo | Con el registry |

Verificación de que la app no quedó con réplicas encendidas:

```bash
az containerapp show --name inv-api --resource-group inv-lab-rg \
  --query "{mode:properties.configuration.activeRevisionsMode, min:properties.template.scale.minReplicas, latest:properties.latestRevisionName}"
```

```text
[PENDIENTE DE CORRIDA] mode Multiple, min 0 y latest inv-api--v3.
```

> 💰 **Si vas a pausar la serie más de unos días**, el registry es lo único que cobra solo por existir:
> unos $5 al mes. Puedes adelantar su borrado con `az acr delete --name invlabacr472913 --yes` y
> recrearlo al volver, sabiendo que cobra el día completo cada vez que existe.

---

## 📋 Checklist de salida

- [ ] `docker image inspect` de `inv-api:0.1.0` devuelve `linux/amd64`, y el de `0.1.0-arm64`, `linux/arm64`.
- [ ] `az acr show --name invlabacr472913 --query adminUserEnabled` devuelve `false`.
- [ ] `inv-api-id` tiene `AcrPull` sobre el registry y la app tira sus imágenes con esa identidad.
- [ ] Viste la revisión `arm` fallar sin que el tráfico dejara `v1`.
- [ ] Viste el puerto equivocado romper la app entera, y lo devolviste a 8080.
- [ ] `/api/info` devolvió `partnerKeyLoaded: true` desde una revisión con el secreto de Key Vault.
- [ ] Mediste el reparto 90/10 del canary y dejaste `v3` con el 100 %.
- [ ] Anotaste el cold start de la primera petición tras escalar a cero.

## 🏁 La señal de que quedó bien

`az containerapp revision list --name inv-api --resource-group inv-lab-rg --query "[?properties.active].name"`
devuelve solo `inv-api--v3`, `curl https://$FQDN/api/info` responde la versión `0.2.0` con el secreto
cargado, `az containerapp replica list` baja a 0 tras cinco minutos sin tráfico, y ninguna credencial
del registry ni de Key Vault está guardada en la app.

---

## 🧠 Preguntas rápidas

1. ¿Por qué el lab crea el Log Analytics workspace antes que el environment?
2. ¿Qué es el `customerId` de un workspace y en qué se diferencia de su resource ID?
3. ¿Por qué el registry cuesta lo mismo si existe diez minutos que si existe un día?
4. ¿Qué hacen `--admin-enabled false` y `--role-assignment-mode rbac` en `az acr create`, y qué pasaría con `AcrPull` en modo `rbac-abac`?
5. ¿Por qué la imagen base se fija por digest y no por la etiqueta `21-distroless`?
6. ¿Qué decide la arquitectura de una imagen construida sin `--platform`, y con qué comando la compruebas?
7. ¿Por qué la revisión `arm` no dejó a los usuarios sin servicio y el cambio de puerto sí?
8. ¿Qué diferencia hay entre los logs `--type system` y `--type console` de una app?
9. ¿Qué son las probes por defecto de una app con ingress y por qué fallan con el target port equivocado?
10. ¿Por qué `az containerapp secret set` no basta para que la app vea el secreto?
11. ¿Qué dos requisitos tiene una Key Vault reference para que la plataforma lea el secreto?
12. ¿Qué pasa con el tráfico al crear una revisión nueva en modo multiple, y qué error provoca eso?
13. ¿Cuánto tarda una app en bajar a cero réplicas y qué costo tiene evitar el cold start?
14. ¿Qué sigue cobrando al terminar este lab y por qué no se borra todavía?

---

## 📚 Referencias oficiales

- Environments de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/environment
- Referencia de `az containerapp env`: https://learn.microsoft.com/en-us/cli/azure/containerapp/env
- Referencia de `az containerapp`: https://learn.microsoft.com/en-us/cli/azure/containerapp
- Revisiones: https://learn.microsoft.com/en-us/azure/container-apps/revisions
- Reparto de tráfico: https://learn.microsoft.com/en-us/azure/container-apps/traffic-splitting
- Escalado: https://learn.microsoft.com/en-us/azure/container-apps/scale-app
- Health probes: https://learn.microsoft.com/en-us/azure/container-apps/health-probes
- Variables de entorno integradas: https://learn.microsoft.com/en-us/azure/container-apps/environment-variables
- Secretos y Key Vault references: https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets
- Managed identities para tirar imágenes: https://learn.microsoft.com/en-us/azure/container-apps/managed-identity-image-pull
- Logs de la aplicación y del sistema: https://learn.microsoft.com/en-us/azure/container-apps/logging
- Facturación de Container Apps: https://learn.microsoft.com/en-us/azure/container-apps/billing
- Referencia de `az acr`: https://learn.microsoft.com/en-us/cli/azure/acr
- Roles de Container Registry: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-rbac-built-in-roles-overview
- Permisos por repositorio con ABAC en Container Registry: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-rbac-abac-repository-permissions
- Imágenes de contenedor del Microsoft Build of OpenJDK: https://learn.microsoft.com/en-us/java/openjdk/containers
- Crear un Log Analytics workspace: https://learn.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace
- Precios de Container Apps: https://azure.microsoft.com/en-us/pricing/details/container-apps/
- Precios de Container Registry: https://azure.microsoft.com/en-us/pricing/details/container-registry/

### Herramientas de terceros (opcional)

No forman parte del material de referencia del curso; se listan porque el lab las usa en local.

- Spring Boot, notas de la versión 4.0: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes
- Docker: construir para varias plataformas: https://docs.docker.com/build/building/multi-platform/
