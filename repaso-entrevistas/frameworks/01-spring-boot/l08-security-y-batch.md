# L08 — Security y Batch

> **Objetivo:** que `inv-api` deje de fiarse de quien llama y deje de perder trabajo cuando algo
> se cae. Al terminar vas a poder demostrar con un comando **por qué** una petición salió 401 y
> otra salió 403 —con la línea de log que lo dice, no con una suposición— y vas a haber reanudado
> un job de Batch caído a la mitad enseñando en las tablas del `JobRepository` desde dónde retomó.
> **Asume:** [`20`](20-spring-security-el-mecanismo.md), [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md)
> y [`22`](22-spring-batch.md) leídos enteros. Este lab **no repite su teoría: la pone a correr**.
> Si no puedes dibujar de memoria la cadena de filtros de
> [`20` §2](20-spring-security-el-mecanismo.md#2--security-es-un-solo-filtro-y-por-dentro-son-veinte)
> ni decir qué es una `JobInstance` frente a una `JobExecution`
> ([`22` §2](22-spring-batch.md#2--el-modelo-seis-sustantivos-y-ninguno-sobra)), vuelve ahí: las
> secciones 4 y 10 no se entienden sin eso.
> **Prerrequisitos:** [`L07`](l07-actuator-metricas-y-trazas.md) hecho. `inv-api` tiene Postgres con
> Flyway y JPA de [`L04`](l04-datos-y-transacciones.md), el `SupplierGateway` resiliente de
> [`L05`](l05-clientes-y-resiliencia.md), la caché en Redis y el `@Async` con `MdcTaskDecorator` de
> [`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás), y
> el Actuator del 8081 con Prometheus, Grafana y el `traceId` de
> [`L07` §10](l07-actuator-metricas-y-trazas.md#10--micrometer-tracing-el-traceid-de-punta-a-punta).
> **Costo:** **$0.00**. Seis contenedores en `localhost` y una JVM (dos durante la sección 10).
> **Duración:** entre 200 y 240 minutos. Las secciones 4, 5 y 10 son el corazón del lab.
> **Qué deja levantado:** los perfiles `db`, `ext`, `cache` y `obs` que ya venían, más el perfil
> `sec` (`inv-lab-keycloak-1`). `L09` asume los cinco arriba.
> **Qué toca:** el `pom.xml`, `application.yml`, una migración de Flyway nueva, el directorio
> `keycloak/` del repositorio, el directorio `data/`, y siete clases nuevas bajo
> `com.invlab.invapi.security` y `com.invlab.invapi.batch`.
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Spring Security 6.5.11 · Spring Batch 5.2.6 (los tres por el BOM de Boot, verificado contra el
> `spring-boot-dependencies-3.5.16.pom` de Maven Central) · Keycloak 26.7.4 · Java 21.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[Keycloak y el realm](#2--keycloak-en-compose-el-realm-el-token-y-cómo-se-baja) ·
[Resource server y el 401 mudo](#3--inv-api-como-resource-server-y-el-401-que-no-explica-nada) ·
[401 frente a 403 con evidencia](#4--401-frente-a-403-la-evidencia-se-escribe-no-se-supone) ·
[El converter de claims](#5-️-el-converter-el-403-con-el-token-correcto) ·
[Method security](#6--method-security-y-la-self-invocation-por-cuarta-vez) ·
[El `SecurityContext` y el `@Async`](#7-️-el-securitycontext-que-no-cruza-al-async) ·
[Asegurar Actuator](#8--asegurar-actuator-con-endpointrequesttoanyendpoint) ·
[El job con chunk](#9--batch-el-esquema-que-nadie-crea-y-el-job-con-chunk) ·
[Caído y reanudado](#10--caído-a-la-mitad-y-reanudado-las-tablas-antes-y-después) ·
[Checklist](#11--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

Siete labs después, `inv-api` sabe persistir, resistir, cachear y contarse. Lo que no sabe es
**quién** le está hablando: cualquiera que alcance el 8080 puede ajustar el inventario, y
cualquiera que alcance el 8081 puede leerse `/actuator/env` entero, que es donde viven la URL de
tu base y el nombre de tus dependencias. `L07` cerró diciéndolo en voz alta y dejándolo abierto.

Y hay un segundo agujero, más callado. Todo lo que `inv-api` hace hoy dura milisegundos. En banca
la mitad del trabajo dura horas, corre de noche y **se cae**; cuando eso pasa, la pregunta no es
"¿reintentamos?" sino "¿desde dónde, y qué quedó escrito?".

El cambio de músculo de hoy son dos criterios de verdad nuevos:

```text
L04  →  ¿grabó?              → lo dices con un SELECT
L05  →  ¿salió a la red?     → lo dices con el journal de WireMock
L06  →  ¿ejecutó el método?  → lo dices con un contador en memoria
L07  →  ¿cómo se comporta?   → lo dices con una serie de tiempo y una traza
L08  →  ¿por qué rechazó?    → lo dices con el log que escribiste tú, no con el código HTTP
     →  ¿por dónde iba?      → lo dices con BATCH_STEP_EXECUTION, no con el fichero de entrada
```

Los dos tienen la misma forma, y por eso comparten lab: **un 403 sin log y un job sin
`JobRepository` son el mismo problema**, un sistema que tomó una decisión y no dejó rastro de por
qué. El resto del lab es escribir ese rastro.

Primero confirma que vienes del estado correcto:

```bash
docker compose -p inv-lab ps
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'health      -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'env         -> %{http_code}\n' localhost:8081/actuator/env
curl -s -o /dev/null -w 'valuation   -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'prometheus  -> %{http_code}\n' localhost:8081/actuator/prometheus
psql 'postgresql://inv_lab:inv_lab@localhost:5432/inv_lab' -c '\dt'
```

```text
health      -> 200
env         -> 200
valuation   -> 200
prometheus  -> 200
```

- **`docker compose -p inv-lab ps` tiene que listar cinco contenedores**: `inv-lab-postgres-1` en
  `(healthy)`, y `inv-lab-wiremock-1`, `inv-lab-redis-1`, `inv-lab-prometheus-1` e
  `inv-lab-grafana-1` en `Up`. Si falta alguno,
  `docker compose -p inv-lab --profile db --profile ext --profile cache --profile obs up -d` los
  devuelve. Si además falta el item `ABC-000123`, hiciste `down -v` entre sesiones y toca recrearlo
  con el `POST /api/items` de `L03`.
- **`env -> 200` es el hallazgo, no la confirmación.** Ese `200` es el agujero que la sección 8
  cierra: hoy `/actuator/env` publica el `spring.datasource.url`, la lista de beans de
  configuración y el `issuer-uri` que vas a escribir dentro de un rato, a quien alcance el puerto.
  Míralo ahora para que el `401` de la sección 8 signifique algo.
- **`psql` es la herramienta de `L04` y hoy vuelve**: `\dt` tiene que listar `inventory_item`,
  `inventory_event` y `flyway_schema_history`. Si `psql` no está en tu máquina,
  `docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c '\dt'` hace lo mismo desde
  dentro del contenedor y es el comando que se usa en el resto del lab para no depender de tu
  instalación.
- **`./mvnw -q clean package` sin `-DskipTests`**, como siempre: hoy se tocan siete clases y el
  `application.yml`, y los tests de `L03` son la red que avisa si algo de lo de antes se rompió.
  Cuando Spring Security entre en el classpath, además, **esos tests van a empezar a fallar por una
  razón legítima**, y arreglarlos es parte del trabajo (sección 3).

**Lo que vas a construir hoy, en orden, y el porqué del orden.** Primero el emisor de identidad,
porque sin tokens no hay nada que validar (sección 2). Después `inv-api` como resource server, que
son literalmente dos propiedades y una cadena, y que produce un 401 **mudo** (sección 3). El
corazón viene justo después: hacer que el 401 y el 403 dejen evidencia (sección 4) y usar esa
evidencia para diagnosticar el 403 que da un token perfectamente válido (sección 5), que es el
error de mapeo que se lleva la mitad de las horas de la primera integración con Keycloak. Con la
identidad ya resuelta, tres consecuencias: la autorización por método y su proxy (sección 6), el
contexto que no cruza al `@Async` y que `L06` dejó nombrado sin poder ejecutarlo (sección 7), y
Actuator cerrado con una cadena propia (sección 8). La segunda mitad es Batch: el esquema y el job
(sección 9) y la caída con su reanudación (sección 10), que es el criterio de terminado del lab.

> **📝 Lo que este lab deja fuera a propósito, y dónde se practica en su lugar.**
> **El flujo authorization code con PKCE** no se ejecuta: necesita un navegador, un redirect URI y
> un client que no eres tú, y lo que enseñaría —que el humano se autentica contra el IdP y el
> client recibe el código— es exactamente lo que
> [`21` §2](21-identidad-federada-oauth2-oidc-y-jwt.md#2--oidc-encima-de-oauth2-y-los-dos-tokens-que-no-se-confunden)
> explica sin necesidad de ejecutarlo. Para conseguir tokens desde la terminal este lab activa
> *direct access grants* en el cliente de Keycloak, que es el password grant que ese mismo capítulo
> llama muerto; se hace con los ojos abiertos y está justificado en la sección 2.
> **`inv-api` como OAuth2 client** —pedir un token con `client_credentials` y propagarlo a
> `inv-supplier`— se queda fuera: WireMock no valida nada, así que el ejercicio sería mandar una
> cabecera a un servidor que no la mira. El mecanismo está en
> [`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio)
> y hay un 🔥 que lo monta contra el propio Keycloak.
> **Token opaco con introspección, mTLS y la rotación de claves** se explican en `21` y no se
> ejecutan: los tres piden infraestructura que no enseña Spring, sino operación.
> **El particionado y el escalado de Batch** se quedan en
> [`22` §9](22-spring-batch.md#9--flujo-y-paralelismo-cuatro-formas-y-lo-que-cada-una-cobra): con
> sesenta mil líneas en un Postgres local, ocho hilos no enseñan nada que un hilo no enseñe.
> **`JobLauncherTestUtils` y los slices de test con seguridad** van a
> [`24`](24-testing.md) y a un ejercicio 🟠 de este lab.
> **El catálogo de anotaciones** —donde `@PreAuthorize`, `@EnableMethodSecurity` y `@StepScope`
> tienen su ficha— es el apéndice [`A02` §15](a02-catalogo-de-anotaciones.md#15--seguridad). El teardown de todo esto lo hace
> [`L09` §8](l09-empaquetado-imagen-y-limpieza.md#8--la-limpieza-verificada), al final de la serie.

---

## 2. 🧱 Keycloak en Compose: el realm, el token y cómo se baja

`inv-api` necesita tokens que alguien haya firmado, y ese alguien no puedes ser tú: todo el §5 de
[`21`](21-identidad-federada-oauth2-oidc-y-jwt.md#5--firma-simétrica-asimétrica-y-el-jwk-set-endpoint)
va de que el resource server **verifica** con una clave pública y no **emite** con una privada. Así
que hace falta un authorization server de verdad.

Y ya está declarado. El `docker-compose.yml` que
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie) fijó para toda la serie
trae el servicio `keycloak` con su perfil `sec`, su tag exacto y su bind mount; este lab **no lo
inventa, lo levanta**. Repasa qué dice ese bloque antes de arrancarlo:

```yaml
  keycloak:
    image: quay.io/keycloak/keycloak:26.7.4
    profiles: ["sec"]
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: admin
    ports: ["8180:8080"]
    volumes: ["./keycloak:/opt/keycloak/data/import"]
```

- **`quay.io/keycloak/keycloak:26.7.4`** es el tag fijado y verificado en `L00`. No hay `latest`
  por la razón de siempre, y aquí pesa más que en otros servicios: entre versiones mayores Keycloak
  cambia el formato de export del realm y los nombres de variables de entorno, así que un `latest`
  convertiría el fichero de la sección siguiente en irreproducible sin aviso.
- **`start-dev`** arranca el modo de desarrollo: HTTP sin TLS, base de datos H2 embebida y caché
  local. **Es exactamente lo que no se hace en producción**, y por eso hay un `start` sin `-dev`
  que exige `KC_DB`, hostname y certificados. Aquí sirve porque lo único que necesitamos del IdP es
  que firme tokens y publique su JWK Set.
- **`--import-realm`** le dice que, al arrancar, lea todos los ficheros `*.json` de
  `/opt/keycloak/data/import` y cree los realms que describan. Es lo que convierte "configúralo a
  mano en la consola web" en un fichero versionado, que es la diferencia entre un lab reproducible
  y una captura de pantalla.
- **`KC_BOOTSTRAP_ADMIN_*`** crean el administrador inicial del realm `master`. Ese par
  `admin`/`admin` es trivial a propósito y con el mismo argumento que el `inv_lab`/`inv_lab` de
  Postgres: es un contenedor en `localhost` que muere con un comando. Lo que hay que saber decir es
  **por qué** eso sería inaceptable a un centímetro de tu máquina, no simular rigor con veinte
  caracteres.
- **`8180:8080`** publica en 8180 porque dentro del contenedor Keycloak escucha en 8080 y ese
  puerto ya es de `inv-api`. Toda URL del IdP en este lab empieza por `http://localhost:8180`.

### El realm, en un fichero

El directorio del bind mount no existe todavía y Docker lo crearía vacío, así que lo creas tú con
el fichero dentro. Es un **import parcial**: Keycloak no exige el export completo de un realm, le
basta con los objetos que declares.

El `cd ..` del bloque no es tipográfico: vienes de `inv-api/` desde la sección 1, y `./keycloak` se
resuelve **relativo al directorio del `docker-compose.yml`**, que vive en la raíz del repositorio
desde [`L01` §14](l01-esqueleto-cli-y-autoconfiguracion.md#14--el-docker-composeyml-se-escribe-aquí-y-no-se-levanta).
Creado dentro del proyecto, Keycloak arrancaría con un `/opt/keycloak/data/import` vacío —Docker
crea el origen ausente **como directorio**—, el realm `inv` no existiría y el
`.well-known/openid-configuration` de dentro de un momento devolvería `404` sin decir una palabra
sobre directorios. Es el mismo `cd ..` de [`L04` §2](l04-datos-y-transacciones.md),
[`L05` §2](l05-clientes-y-resiliencia.md) y [`L07` §7](l07-actuator-metricas-y-trazas.md).

```bash
cd ..                      # a la raíz del repo, donde vive el docker-compose.yml
mkdir -p keycloak
cat > keycloak/inv-realm.json <<'JSON'
{
  "realm": "inv",
  "enabled": true,
  "accessTokenLifespan": 900,
  "roles": {
    "realm": [
      { "name": "analyst", "description": "consulta y ajusta inventario" },
      { "name": "ops",     "description": "opera la plataforma: Actuator y jobs" }
    ]
  },
  "clientScopes": [
    {
      "name": "inventory.read",
      "protocol": "openid-connect",
      "attributes": { "include.in.token.scope": "true", "display.on.consent.screen": "false" }
    },
    {
      "name": "inventory.write",
      "protocol": "openid-connect",
      "attributes": { "include.in.token.scope": "true", "display.on.consent.screen": "false" }
    }
  ],
  "clients": [
    {
      "clientId": "inv-api",
      "enabled": true,
      "bearerOnly": true
    },
    {
      "clientId": "inv-cli",
      "enabled": true,
      "publicClient": true,
      "standardFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "defaultClientScopes": ["openid", "profile", "email", "roles", "inventory.read"],
      "optionalClientScopes": ["inventory.write"],
      "protocolMappers": [
        {
          "name": "inv-api-audience",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-audience-mapper",
          "config": {
            "included.client.audience": "inv-api",
            "access.token.claim": "true",
            "id.token.claim": "false"
          }
        }
      ]
    }
  ],
  "users": [
    {
      "username": "analyst@invlab.example",
      "enabled": true,
      "emailVerified": true,
      "credentials": [{ "type": "password", "value": "analyst", "temporary": false }],
      "realmRoles": ["analyst"]
    },
    {
      "username": "ops@invlab.example",
      "enabled": true,
      "emailVerified": true,
      "credentials": [{ "type": "password", "value": "ops", "temporary": false }],
      "realmRoles": ["ops"]
    },
    {
      "username": "guest@invlab.example",
      "enabled": true,
      "emailVerified": true,
      "credentials": [{ "type": "password", "value": "guest", "temporary": false }],
      "realmRoles": []
    }
  ]
}
JSON
```

- **`"realm": "inv"`** fija el emisor: el `iss` de todo token de este realm será
  `http://localhost:8180/realms/inv`, y esa cadena se compara **carácter a carácter** con tu
  `issuer-uri`. Una barra de más al final es el 401 más tonto de todos y está en el 🩺 de
  [`21` §6](21-identidad-federada-oauth2-oidc-y-jwt.md#6--inv-api-como-resource-server-dos-propiedades-y-un-matcher).
- **`accessTokenLifespan: 900`** son quince minutos, la ventana de la que habla
  [`21` §9](21-identidad-federada-oauth2-oidc-y-jwt.md#9-️-el-token-no-es-una-sesión-revocar-caducar-y-qué-no-meter-dentro).
  Lo pones explícito para que el ejercicio de la sección 4 —ver caducar un token— no dependa del
  default del día.
- **Los dos roles de realm son los de `20`**: `analyst` es quien usa el inventario y `ops` quien
  mira Actuator. Llegan al token dentro de `realm_access.roles`, **anidados**, y esa anidación es
  todo el contenido de la sección 5.
- **Los dos `clientScopes`** existen para que el token traiga `scope: "... inventory.read"` y el
  converter por defecto lo convierta en la authority `SCOPE_inventory.read`. `inventory.read` va en
  `defaultClientScopes` —viaja siempre— y `inventory.write` en `optionalClientScopes`, así que solo
  aparece si lo pides explícitamente con `scope=inventory.write` al pedir el token. **Esa asimetría
  es deliberada y es una trampa montada a propósito:** un scope por defecto lo lleva *cualquiera* que
  pida un token con este cliente, tenga los roles que tenga, y la sección 5 te va a cobrar haberlo
  olvidado. Un scope se configura en el client; un rol, en la persona.
- **`inv-api` se declara `bearerOnly`**: es un cliente que nunca inicia un login, solo recibe
  tokens. No necesita secreto ni redirect URI, y existe en el realm por dos razones —para que el
  mapper de audiencia pueda nombrarlo y para que el realm se lea como lo que es—.
- **`inv-cli` es `publicClient` con `directAccessGrantsEnabled`**, y aquí está la decisión
  incómoda: eso es el *password grant* que
  [`21` §2](21-identidad-federada-oauth2-oidc-y-jwt.md#2--oidc-encima-de-oauth2-y-los-dos-tokens-que-no-se-confunden)
  declara muerto, porque obliga al client a manejar la contraseña del usuario. Se activa **solo**
  para poder pedir tokens con `curl` sin navegador, `standardFlowEnabled` está en `false` para que
  quede claro que este cliente no hace login de verdad, y en un sistema real esta línea sería un
  hallazgo de auditoría. Un lab que lo usa sin decirlo enseña un vicio; uno que lo usa diciendo por
  qué enseña dos cosas.
- **El `oidc-audience-mapper` no es opcional, y es la trampa número uno de integrar Spring con
  Keycloak.** Por defecto Keycloak emite tokens cuyo `aud` es `account`, no tu servicio: si activas
  la propiedad `...jwt.audiences=inv-api` sin este mapper, **todos** tus tokens son rechazados con
  un 401 perfectamente legítimo. Este mapper añade `inv-api` al `aud` del access token, y solo del
  access token (`id.token.claim: false`), porque el `id_token` es del client.
- **Las contraseñas `analyst`/`ops`/`guest`** son triviales por la misma razón que las de Postgres
  y están escritas aquí porque el realm entero muere con el contenedor. **No hay ningún secreto
  real en este fichero**, y por eso puede estar versionado; el día que lo hubiera, iría donde dice
  [`07` §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos).
- **`guest@invlab.example` no tiene ningún rol**, y no es un descuido: es el usuario con el que se
  fabrica un 403 de verdad —autenticado y sin permiso— en la sección 4.

### Arrancarlo, y comprobar que el descubrimiento funciona

```bash
docker compose -p inv-lab --profile sec up -d
sleep 25
docker compose -p inv-lab ps keycloak
curl -s http://localhost:8180/realms/inv/.well-known/openid-configuration | jq -r '.issuer, .jwks_uri, .token_endpoint'
```

```text
http://localhost:8180/realms/inv
http://localhost:8180/realms/inv/protocol/openid-connect/certs
http://localhost:8180/realms/inv/protocol/openid-connect/token
```

- **`--profile sec`** levanta únicamente Keycloak: el resto de perfiles ya está arriba y Compose no
  los toca. Levantar un perfil no baja los demás, y ese es el punto de que existan.
- **`sleep 25` no es superstición.** Keycloak importa el realm y construye su base H2 en el primer
  arranque, y eso tarda entre quince y treinta segundos en una máquina normal. El servicio **no
  tiene `healthcheck` en el Compose de la serie**, así que aquí la espera la pones tú; si el `curl`
  falla con `Connection refused`, todavía está importando —`docker compose -p inv-lab logs keycloak
  | tail -20` te lo dice— y repetir el comando es la respuesta correcta.
- **Las tres URLs de la salida son las únicas fijas de esta sección**, y son las tres que importan:
  el `issuer` es lo que vas a copiar en `application.yml`, el `jwks_uri` es de donde tu aplicación
  va a bajarse las claves públicas, y el `token_endpoint` es a donde pides tokens. Que el
  descubrimiento responda significa que el realm se importó; si devuelve un `404`, el fichero JSON
  tenía un error de sintaxis y Keycloak arrancó con el realm `master` a secas.

⏱️ **Costo en runtime.** Keycloak es el contenedor más caro del laboratorio: alrededor de 500 MB de
RAM en reposo, contra los 150 MB de Postgres. Con los cinco perfiles arriba, un IDE y la JVM de
`inv-api`, una máquina de 8 GB empieza a notarlo. Si vas justo, `docker compose -p inv-lab --profile
obs stop` deja Prometheus y Grafana parados sin borrar nada y devuelve 300 MB — hoy no los
necesitas hasta el ejercicio 12.

### El teardown de Keycloak, y qué se pierde

Se escribe aquí, junto al recurso, no al final del lab:

```bash
docker compose -p inv-lab --profile sec down
docker compose -p inv-lab ps -a | grep -c keycloak
```

- **`down` con el perfil `sec` para y borra el contenedor de Keycloak**, y el `grep -c` devuelve
  `0` cuando de verdad murió. Ojo con el detalle de Compose: `down` sin `--profile` **no toca los
  servicios de un perfil que no esté activo**, así que el comando lleva el perfil escrito.
- **Lo que se pierde al bajarlo es el realm entero, y eso es una buena noticia.** El servicio
  `keycloak` no declara ningún volumen con nombre en el Compose de `L00`: su base H2 vive dentro
  del contenedor y muere con él. El fichero `keycloak/inv-realm.json` sí sobrevive, porque es un
  bind mount a tu repositorio, así que el siguiente `up` reconstruye exactamente el mismo realm.
  **Ese es justo el motivo de configurarlo con `--import-realm` y no por la consola web**: lo que
  hagas en la consola se va con el contenedor.
- **Lo que no se pierde son los tokens que ya emitió**, y merece pensarlo dos segundos porque es
  el §9 de `21` hecho contenedor: un token firmado hace cinco minutos sigue siendo un JWT válido en
  su forma, pero `inv-api` ya no puede verificarlo —no hay JWK Set al que llamar— y lo que obtienes
  es un 401. Bajar el IdP no revoca nada; impide validar, que es distinto.
- **Tu aplicación no se entera hasta la siguiente petición.** `inv-api` cachea el JWK Set en
  memoria, así que con Keycloak parado los tokens que ya tenía cacheada la clave **siguen
  validándose** hasta que aparezca un `kid` desconocido. Es un experimento de tres comandos y está
  en el ejercicio 13.

---

## 3. 🧱 `inv-api` como resource server, y el 401 que no explica nada

Ahora hay quien firma. Falta que `inv-api` deje de aceptar a cualquiera, y eso son **una
dependencia, dos propiedades y una cadena** — la configuración más barata de todo el curso en
relación a lo que cambia.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-test</artifactId>
    <scope>test</scope>
</dependency>
```

- **Sin `<version>` en ninguna de las dos**, porque las dos entran por el BOM de Boot 3.5.16, que
  fija Spring Security en **6.5.11** (comprobado en el `spring-boot-dependencies-3.5.16.pom` de
  Maven Central, propiedad `spring-security.version`). Escribir la versión a mano aquí es cómo se
  rompe el siguiente upgrade de Boot.
- **`-oauth2-resource-server` arrastra `spring-boot-starter-security` como transitiva**, así que no
  hace falta declarar los dos. Lo que añade por encima es el `NimbusJwtDecoder`, el
  `BearerTokenAuthenticationFilter` y la autoconfiguración que lee las propiedades de abajo.
- **`-resource-server` valida tokens; `-client` los pide**, y confundirlos produce un arranque que
  exige un `client-id` que no tienes
  ([`21` §6](21-identidad-federada-oauth2-oidc-y-jwt.md#6--inv-api-como-resource-server-dos-propiedades-y-un-matcher)).
  Hoy `inv-api` solo recibe.
- **`spring-security-test` en scope `test`** trae `@WithMockUser`, el post-processor
  `springSecurity()` y `jwt()` para `MockMvc`. Va ahora y no al final porque los tests de `L03` van
  a romperse en cuanto Security entre en el classpath, y el arreglo lo necesita.

Las propiedades, en el bloque del perfil `local` del `application.yml`:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8180/realms/inv
          audiences: inv-api
```

- **`issuer-uri` hace dos cosas de una vez**, y por eso se prefiere a `jwk-set-uri`: dispara el
  descubrimiento OIDC en el arranque —de donde salen el `jwks_uri` y el algoritmo— **y** configura
  el `JwtIssuerValidator` con esa misma cadena. El precio es el de
  [`21` §5](21-identidad-federada-oauth2-oidc-y-jwt.md#5--firma-simétrica-asimétrica-y-el-jwk-set-endpoint):
  si Keycloak no está arriba, `inv-api` **no arranca**. Es un precio que conviene pagar en el lab,
  porque el fallo es ruidoso y no silencioso.
- **La cadena tiene que ser idéntica al `issuer` del descubrimiento**, que acabas de imprimir en la
  sección 2. Sin barra final, con `http` y no `https`, y con `localhost:8180`. La comparación es de
  strings, no de URLs normalizadas.
- **`audiences: inv-api`** activa el quinto paso de
  [`21` §4](21-identidad-federada-oauth2-oidc-y-jwt.md#4--qué-valida-un-resource-server-y-en-qué-orden),
  el que no viene por defecto. Es la propiedad que hace que un token emitido por el mismo Keycloak
  para otro servicio **no** entre aquí, y es la que obliga al `oidc-audience-mapper` de la sección 2.
  Quítala y el lab funciona igual; quítala en producción y compartes resource server con el resto
  del realm.

Y la cadena, en una clase nueva:

```java
// src/main/java/com/invlab/invapi/security/SecurityConfig.java
@Configuration
@EnableWebSecurity
class SecurityConfig {

    @Bean
    @Order(1)
    SecurityFilterChain apiChain(HttpSecurity http) throws Exception {
        http
            .securityMatcher("/api/**")                       // esta cadena solo ve /api/**
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.GET, "/api/items/**").hasAuthority("SCOPE_inventory.read")
                .requestMatchers(HttpMethod.POST, "/api/items/**").hasRole("ANALYST")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
            .csrf(csrf -> csrf.disable())                     // API stateless con Bearer: 19 §11
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
        return http.build();
    }
}
```

- **`@EnableWebSecurity` es redundante con el starter en el classpath y se escribe igual**, para
  que quien abra la clase no tenga que recordar qué activa Boot solo. Lo que sí cambia de verdad es
  **declarar el bean**: en cuanto existe un `SecurityFilterChain` propio, Boot deja de crear el
  suyo, ese que pedía login para todo con la contraseña aleatoria del arranque
  ([`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean)).
- **`securityMatcher("/api/**")` decide qué entra a esta cadena y `requestMatchers` qué se exige a
  lo que entró.** Es la distinción de `20` §3, y hoy tiene una consecuencia que vas a ver en cinco
  minutos: **el 8081 de Actuator no matchea ninguna cadena**, así que sale sin ninguna regla
  aplicada. No es un olvido, es la sección 8.
- **`hasAuthority("SCOPE_inventory.read")` lleva el prefijo escrito** porque así llegan los scopes
  del converter por defecto, y **`hasRole("ANALYST")` no lo lleva** porque `hasRole` añade `ROLE_`
  por su cuenta y compara contra `ROLE_ANALYST`
  ([`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_)). Las dos
  reglas están escritas a propósito con los dos estilos: la primera va a funcionar de entrada y la
  segunda va a dar 403 con el usuario correcto. Ese contraste es la sección 5 — donde además vas a
  descubrir que la primera, la que funciona, es **demasiado floja** por un motivo que no tiene nada
  que ver con el converter.
- **`.oauth2ResourceServer(...jwt(...))`** es lo que registra el `BearerTokenAuthenticationFilter`
  en la cadena. **Sin esta línea las dos propiedades no hacen absolutamente nada**: la
  autoconfiguración construye el decoder, pero quien lee la cabecera `Authorization` es este filtro,
  y a la cadena la declaras tú.
- **`csrf.disable()` está justificado, no es un atajo**: la credencial viaja en una cabecera
  `Authorization` que el navegador no adjunta solo, que es la condición exacta del ataque
  ([`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api)).
  Con cookie de sesión, esta línea sería el agujero.
- **`STATELESS`** hace que Security no cree ni consulte `HttpSession`: cada petición se autentica
  desde cero validando la firma, que es lo barato en este modelo y lo que mide el ⏱️ de
  [`21` §5](21-identidad-federada-oauth2-oidc-y-jwt.md#5--firma-simétrica-asimétrica-y-el-jwk-set-endpoint).

### Un token, y qué lleva dentro

```bash
get_token() {
  curl -s -X POST http://localhost:8180/realms/inv/protocol/openid-connect/token \
    -d 'client_id=inv-cli' -d 'grant_type=password' \
    -d "username=$1" -d "password=$2" -d "scope=openid ${3:-}" | jq -r .access_token
}
ANALYST=$(get_token analyst@invlab.example analyst 'inventory.write')
GUEST=$(get_token guest@invlab.example guest)
echo "${#ANALYST} caracteres"
```

- **`grant_type=password`** es el direct access grant que la sección 2 activó y justificó. En un
  cliente `publicClient` no hace falta `client_secret`, que es lo que permite que esta función
  quepa en cinco líneas y no lleve ningún secreto dentro.
- **`scope=openid inventory.write`** pide el scope opcional además del default. Sin el `openid` no
  estarías hablando OIDC y Keycloak no incluiría los claims de identidad; sin `inventory.write`, el
  token del analista solo trae `inventory.read`.
- **`${3:-}` deja el tercer argumento opcional**, y por eso `GUEST` sale sin scopes extra: el
  invitado va a servir para fabricar un 403 limpio.
- **La longitud del token ronda el millar de caracteres** y cambia en cada emisión, así que el
  `echo` está para que veas el orden de magnitud —no es un identificador corto— y para confirmar
  que `jq` no devolvió `null`. Si devuelve `4 caracteres`, la respuesta fue un error y
  `curl ... | jq .` sin el `-r .access_token` te dice cuál.

Ahora ábrelo. Un JWT **no está cifrado** y eso se demuestra sin ninguna clave:

```bash
decode() { echo "$1" | cut -d. -f"$2" | tr '_-' '/+' | base64 -d 2>/dev/null | jq .; }
decode "$ANALYST" 1
decode "$ANALYST" 2
```

- **`cut -d. -f1` y `-f2`** toman el header y el payload; la tercera parte es la firma y es binario,
  no JSON. **`tr '_-' '/+'`** convierte Base64URL a Base64 estándar, que es lo que entiende `base64
  -d`; el `2>/dev/null` calla la queja por el relleno ausente, que `base64` tolera.
- **Que esto funcione sin ninguna credencial es la demostración de que la firma protege la
  integridad y no la confidencialidad** — la sobregeneralización número uno de
  [`21` §3](21-identidad-federada-oauth2-oidc-y-jwt.md#3--el-jwt-por-dentro-tres-partes-y-solo-una-está-protegida).
  Cualquiera que vea pasar ese token lee todo lo que metiste dentro.

Lo que sale tiene esta forma. **Los valores concretos cambian en cada emisión** —el `sub` es un UUID
nuevo por realm importado, los tiempos son de tu reloj y el `kid` lo genera Keycloak al arrancar—,
así que aquí va la forma con los claims que importan y no una salida fija:

```json
// header
{ "alg": "RS256", "typ": "JWT", "kid": "<43 caracteres Base64URL>" }
// payload, recortado a los claims que este lab usa
{
  "iss": "http://localhost:8180/realms/inv",
  "aud": ["inv-api", "account"],
  "sub": "<uuid>",
  "exp": <epoch+900>, "iat": <epoch>,
  "typ": "Bearer",
  "azp": "inv-cli",
  "scope": "openid inventory.read inventory.write email profile",
  "realm_access": { "roles": ["analyst", "default-roles-inv", "offline_access", "uma_authorization"] },
  "preferred_username": "analyst@invlab.example"
}
```

- **`aud` trae `inv-api` gracias al mapper**, y también `account`, que es el que Keycloak pone por
  su cuenta. La propiedad `audiences` de Boot exige que el valor que configuraste **esté entre** los
  del claim, no que sea el único.
- **`scope` es una cadena separada por espacios**, no una lista. El `JwtGrantedAuthoritiesConverter`
  por defecto la parte y prefija cada trozo con `SCOPE_`: de ahí salen `SCOPE_inventory.read` y
  `SCOPE_inventory.write`, que son las authorities que tu primera regla usa.
- **`realm_access.roles` es un objeto con una lista dentro**, y ahí está el problema de la sección
  5: ningún converter por defecto entra en un claim anidado. Fíjate además en la compañía —
  `default-roles-inv`, `offline_access`, `uma_authorization`—: son roles que Keycloak asigna a todo
  el mundo, así que "tener roles" y "tener permisos" no son lo mismo ni aquí.
- **`azp`** es el client que pidió el token, y **`typ": "Bearer"`** confirma que es un access token
  y no un `id_token`: si algún día ves `"typ": "ID"` en lo que te mandan, es el documento dirigido
  al client del que avisa
  [`21` §2](21-identidad-federada-oauth2-oidc-y-jwt.md#2--oidc-encima-de-oauth2-y-los-dos-tokens-que-no-se-confunden).
- **Aquí no hay ninguna firma escrita**, ni recortada ni de ejemplo, y es deliberado: un token
  completo en un documento es una credencial en un documento, aunque haya caducado. Lo mismo vale
  para tu log ([`21` §9](21-identidad-federada-oauth2-oidc-y-jwt.md#9-️-el-token-no-es-una-sesión-revocar-caducar-y-qué-no-meter-dentro)).

### Tres peticiones y tres respuestas

**Predice antes de ejecutar.** El token de `ANALYST` trae `inventory.read`, `inventory.write` y el
rol `analyst`. ¿Qué te van a devolver el `GET` sin token, el `GET` con token y el `POST` con el
mismo token: `200`, `401` o `403`?

```bash
cd inv-api                 # de vuelta al proyecto: el bloque de Keycloak te dejó en la raíz
kill %1
./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'GET  sin token  -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'GET  con token  -> %{http_code}\n' -H "Authorization: Bearer $ANALYST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'POST con token  -> %{http_code}\n' -X POST -H "Authorization: Bearer $ANALYST" \
  -H 'Content-Type: application/json' -d '{"delta":1,"reason":"recepcion"}' \
  localhost:8080/api/items/ABC-000123/events
curl -s -o /dev/null -w 'actuator/env    -> %{http_code}\n' localhost:8081/actuator/env
grep -c 'ERROR\|Denied\|Unauthorized' app.log
```

```text
GET  sin token  -> 401
GET  con token  -> 200
POST con token  -> 403
actuator/env    -> 200
0
```

- **El `cd inv-api` deshace el `cd ..` del realm**, y la regla vale para el resto del lab: el
  `docker-compose.yml` y los bind mounts (`keycloak/`) viven en la raíz del repositorio, mientras
  que el build, el `data/` de la sección 8 y la aplicación viven en `inv-api/`. Los `ps`, `stop`,
  `restart` y `down` con `-p inv-lab` funcionan desde cualquiera de los dos, porque Compose los
  resuelve por las etiquetas de los contenedores; el `up` no, y por eso lleva su `cd ..` al lado.
- **`-DskipTests` aparece por primera vez en la serie, y es una deuda que se paga en esta misma
  sección.** Los tests de `MockMvc` de `L03` fallan ahora mismo con `401`, y con razón: la cadena
  que acabas de declarar también corre en los tests. Arreglarlos es lo último de la sección.
- **El `401` del primer `curl` es correcto y esperado.** No mandaste credencial, el
  `BearerTokenAuthenticationFilter` no encontró nada que autenticar, el `AuthorizationFilter`
  denegó, y el `ExceptionTranslationFilter` decidió que a alguien no autenticado se le piden
  credenciales ([`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe)).
- **El `403` del `POST` es el interesante, porque el token es perfecto.** Está firmado, no ha
  caducado, el `iss` es el tuyo y el `aud` te incluye. Estás autenticado. Lo que falla es la
  autorización: la regla pide `ROLE_ANALYST` y tus authorities no lo traen, porque el rol vive
  anidado en `realm_access` y nadie lo sacó de ahí.
- **`actuator/env -> 200` no cambió.** Security está en el classpath, la cadena existe, y el 8081
  sigue abierto de par en par: su URL no matchea `securityMatcher("/api/**")`, ninguna otra cadena
  la reclama, y una petición que no matchea ninguna cadena **pasa sin filtros de seguridad**. Es
  literalmente lo que avisa `20` §3 y es lo que arregla la sección 8.
- **Y el `0` del `grep` es el hallazgo de verdad**, el que justifica la sección siguiente: acabas de
  rechazar dos peticiones por dos motivos distintos y tu aplicación **no escribió una sola línea
  sobre ello**. Los dos cuerpos de respuesta llegan vacíos, el log está limpio, y si esto fuera un
  ticket de soporte a las tres de la tarde, no tendrías nada.

Antes de seguir, los tests. [`L03` §9](l03-api-rest-filtros-y-errores.md#9--mockmvc-sobre-todo-lo-anterior) probaba los endpoints con `MockMvc` y ahora reciben `401`:

```java
// en InventoryControllerTest, sobre el método que ya existía
@Test
void devuelveElItemCuandoElTokenTraeElScope() throws Exception {
    mockMvc.perform(get("/api/items/ABC-000123")
                   .with(jwt().authorities(new SimpleGrantedAuthority("SCOPE_inventory.read"))))
           .andExpect(status().isOk());
}
```

- **`jwt()` es de `SecurityMockMvcRequestPostProcessors`** y construye un `JwtAuthenticationToken`
  ya validado: no hay Keycloak, no hay red y no hay firma que comprobar. Es lo correcto — levantar
  un IdP por test prueba el IdP, no tus reglas
  ([`20` §12](20-spring-security-el-mecanismo.md#12--probarlo-sin-levantar-un-proveedor-de-identidad)).
- **`.authorities(...)` sustituye a las que sacaría el converter**, así que el test comprueba tu
  regla de autorización y no tu mapeo de claims. Para probar el mapeo hace falta
  `jwt().jwt(j -> j.claim("realm_access", ...))`, que es el ejercicio 11.
- **Sin `@AutoConfigureMockMvc` la cadena de filtros no se registra en `MockMvc`** y los tests
  pasarían porque Security nunca corrió: el falso verde más peligroso del capítulo `20`. Los tests
  de `L03` ya lo llevan, así que aquí basta con añadir el post-processor.
- **A partir de ahora `./mvnw -q clean package` vuelve a correr los tests**, y el `-DskipTests` no
  se repite en el resto del lab.

---

## 4. 🩺 401 frente a 403: la evidencia se escribe, no se supone

Tienes un 401 y un 403 y ni una línea de log. Este es **el criterio de terminado de la primera
mitad del lab**, y la diferencia entre saberse la tabla de `20` §9 y poder usarla.

Empieza por lo barato, que además es lo que harías en producción sin desplegar nada: subir el nivel
del logger de Security con el endpoint `loggers` de
[`L07` §4](l07-actuator-metricas-y-trazas.md#4--loggers-subir-el-nivel-sin-reiniciar-y-encontrar-el-problema).

```bash
curl -s -X POST localhost:8081/actuator/loggers/org.springframework.security \
  -H 'Content-Type: application/json' -d '{"configuredLevel":"DEBUG"}' -w '%{http_code}\n'
: > app.log
curl -s -o /dev/null -H "Authorization: Bearer $GUEST" localhost:8080/api/items/ABC-000123/valuation
grep -c 'o.s.security' app.log
```

- **`204` es la respuesta correcta del `POST` a `loggers`**, y el `Content-Type` no es opcional: sin
  él responde `415`, que es la comprobación que dejó el checklist de `L07`.
- **`: > app.log` vacía el fichero sin borrarlo**, que importa porque la JVM lo tiene abierto:
  `rm` lo dejaría escribiendo en un inodo huérfano y verías el log congelado.
- **El `grep -c` devuelve un número de dos cifras**, no una línea concreta, y ese es el punto. En
  `DEBUG`, Security imprime por petición qué cadena eligió, por qué filtros pasó, qué
  `Authentication` construyó y qué decidió el `AuthorizationManager`. **Es mucho ruido y es la
  herramienta correcta para un diagnóstico puntual**, no para dejarlo puesto: cada petición paga
  esas líneas ⏱️ y el log de un servicio con tráfico se vuelve ilegible en minutos.

Lo que buscas en ese ruido son dos cosas concretas, y conviene saber sus nombres antes de mirar:

```text
petición SIN token      → no hay Authentication, o hay uno anónimo
                        → AccessDeniedException dentro del AuthorizationFilter
                        → ExceptionTranslationFilter ve "no autenticado" → AuthenticationEntryPoint
                        → 401 + cabecera WWW-Authenticate: Bearer

petición CON token y sin la authority
                        → hay un JwtAuthenticationToken autenticado
                        → AccessDeniedException dentro del AuthorizationFilter
                        → ExceptionTranslationFilter ve "ya autenticado" → AccessDeniedHandler
                        → 403 y cuerpo vacío
```

- **La excepción es la misma en los dos casos**, y eso es lo que a casi todo el mundo se le escapa
  en la entrevista: quien decide el código no es quien lanza, es el `ExceptionTranslationFilter`
  mirando si ya había identidad.
- **La cabecera `WWW-Authenticate` la escribe el `BearerTokenAuthenticationEntryPoint`**, y en la
  respuesta sin token llega escueta —solo el esquema—, mientras que en la de un token inválido
  lleva además `error`, `error_description` y `error_uri` apuntando a la sección 3.1 del RFC 6750.
  **El texto exacto de esa descripción lo genera el decoder y cambia con la causa**, así que aquí va
  descrito y no copiado: lo describo en prosa precisamente porque no puedo garantizar la cadena
  literal, y escribir una inventada sería peor que no escribirla.

### Los dos beans que convierten el silencio en evidencia

El `DEBUG` sirve para hoy. Lo que quieres permanente es que **tu** aplicación diga por qué rechazó,
en tu formato y con tu `requestId` delante. Son los dos beans que
[`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe) nombra:

```java
// src/main/java/com/invlab/invapi/security/LoggingAuthenticationEntryPoint.java
class LoggingAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private static final Logger log = LoggerFactory.getLogger(LoggingAuthenticationEntryPoint.class);
    private final AuthenticationEntryPoint delegate = new BearerTokenAuthenticationEntryPoint();

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException exception) throws IOException {
        // 401: no sabemos quién eres. Nunca se escribe el token, solo por qué no valió
        log.warn("401 en {} {} -> {}: {}", request.getMethod(), request.getRequestURI(),
                exception.getClass().getSimpleName(), exception.getMessage());
        delegate.commence(request, response, exception);       // conserva el WWW-Authenticate
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter().write("""
                {"type":"about:blank","title":"Unauthorized","status":401,\
                "detail":"falta un token válido","instance":"%s"}""".formatted(request.getRequestURI()));
    }
}
```

```java
// src/main/java/com/invlab/invapi/security/LoggingAccessDeniedHandler.java
class LoggingAccessDeniedHandler implements AccessDeniedHandler {

    private static final Logger log = LoggerFactory.getLogger(LoggingAccessDeniedHandler.class);

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
                       AccessDeniedException exception) throws IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        // 403: sabemos quién eres. Lo único que falta en el log es CON QUÉ authorities llegaste
        log.warn("403 en {} {} -> principal={} authorities={}", request.getMethod(),
                request.getRequestURI(),
                auth == null ? "null" : auth.getName(),
                auth == null ? "[]" : auth.getAuthorities());
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter().write("""
                {"type":"about:blank","title":"Forbidden","status":403,\
                "detail":"faltan permisos para esta operación","instance":"%s"}""".formatted(request.getRequestURI()));
    }
}
```

```java
// en SecurityConfig.apiChain, antes del .csrf(...)
.exceptionHandling(ex -> ex
        .authenticationEntryPoint(new LoggingAuthenticationEntryPoint())
        .accessDeniedHandler(new LoggingAccessDeniedHandler()))
```

- **`AuthenticationEntryPoint` y `AccessDeniedHandler` son dos interfaces distintas con un método
  cada una**, y esa asimetría es la tabla de `20` §9 hecha código: la primera recibe una
  `AuthenticationException` y la segunda una `AccessDeniedException`. No hay forma de confundirlas
  ni de que una atienda el caso de la otra.
- **El entry point delega en `BearerTokenAuthenticationEntryPoint` en vez de sustituirlo.** Esa
  cabecera `WWW-Authenticate` es parte del contrato de OAuth2 con el client: si la pisas, el que
  llama deja de poder distinguir "falta token" de "token caducado" y pierde la señal para
  refrescarlo. Añadir un log y un cuerpo está bien; quitar la cabecera, no.
- **El `handler` imprime las authorities y ahí está el 90 % del valor de esta sección.** Un 403
  tiene diez causas ([`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe))
  y todas se distinguen mirando **con qué llegó el usuario** frente a **qué pedía la regla**. Esa
  línea convierte una tarde de hipótesis en treinta segundos.
- **En el log nunca entra el token**, ni entero ni recortado. Lo que se escribe es el `principal` y
  la lista de authorities, que es lo que necesitas y no es una credencial. Un access token en un
  fichero de log es una credencial en un fichero de log, aunque caduque en quince minutos.
- **`ProblemDetail` escrito a mano y no con `ProblemDetail.forStatus(...)`**, porque aquí estás
  **dentro de un filtro**: no hay `HttpMessageConverter`, no hay `DispatcherServlet` y no hay
  `@ControllerAdvice` al que devolverle un objeto. Es exactamente la asimetría de
  [`10` §4](10-diseno-de-api-validacion-errores-e-hipermedia.md#4--manejo-centralizado-y-lo-que-se-le-escapa)
  vista desde el otro lado, y la razón por la que el `@RestControllerAdvice` de `L03` no ha visto
  ninguno de estos dos errores.
- **Se instancian con `new` y no como beans**, porque solo los usa esta cadena y declararlos como
  beans los pondría al alcance de cualquier otra configuración que los recogiera por tipo. El día
  que la segunda cadena de la sección 8 quiera el mismo tratamiento, se extrae un bean y se
  inyecta — no antes.

**Predice antes de ejecutar.** Vas a repetir las tres peticiones de la sección 3 con los dos beans
puestos. ¿Cuántas líneas `WARN` va a haber en `app.log`, y cuál de las tres peticiones **no** va a
producir ninguna?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -H 'X-Request-Id: sin-token' localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -H 'X-Request-Id: con-token' -H "Authorization: Bearer $ANALYST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -H 'X-Request-Id: sin-rol' -X POST -H "Authorization: Bearer $ANALYST" \
  -H 'Content-Type: application/json' -d '{"delta":1,"reason":"recepcion"}' \
  localhost:8080/api/items/ABC-000123/events
grep 'WARN' app.log
```

Estas dos líneas sí son literales, porque el formato lo escribiste tú hace tres bloques —lo único
variable es el nombre del hilo de Tomcat y la lista de scopes que traiga tu token:

```text
 WARN [sin-token] --- [nio-8080-exec-1] c.i.i.s.LoggingAuthenticationEntryPoint : 401 en GET /api/items/ABC-000123/valuation -> InsufficientAuthenticationException: Full authentication is required to access this resource
 WARN [sin-rol] --- [nio-8080-exec-3] c.i.i.s.LoggingAccessDeniedHandler : 403 en POST /api/items/ABC-000123/events -> principal=<uuid del sub> authorities=[SCOPE_openid, SCOPE_inventory.read, SCOPE_inventory.write, SCOPE_email, SCOPE_profile]
```

- **`[sin-token]` y `[sin-rol]` son el `requestId` del filtro de `L03`**, y que aparezcan aquí no es
  casualidad: ese filtro se registra con un orden **menor** que el `-100` de Security
  ([`20` §2](20-spring-security-el-mecanismo.md#2--security-es-un-solo-filtro-y-por-dentro-son-veinte)),
  así que corre **antes** y el MDC ya está poblado cuando Security rechaza. Un filtro de correlación
  registrado después de Security no etiquetaría ninguno de estos dos rechazos, que son justamente
  los que vas a tener que rastrear.
- **La petición `con-token` no produce ninguna línea**, y por eso la predicción tenía trampa: los
  beans solo se invocan cuando algo se deniega.
- **`InsufficientAuthenticationException`** es la subclase de `AuthenticationException` que el
  `ExceptionTranslationFilter` fabrica cuando traduce una denegación de alguien no autenticado. Su
  mensaje —*Full authentication is required to access this resource*— es de los pocos literales de
  Spring Security que conviene reconocer de memoria: **significa "no traías credencial", nunca
  "tu credencial es mala"**.
- **Y la segunda línea contesta el 403 sola.** El `principal` es el `sub`, un UUID —ya volveremos
  sobre eso en la sección 5—, y las authorities son **cinco scopes y ni un solo rol**. La regla
  pedía `ROLE_ANALYST`. El token traía `realm_access.roles: ["analyst", ...]`. Nadie hizo el viaje
  de uno a otro. Eso es todo el diagnóstico, y salió de una línea de log en vez de una tarde.

> **🩺 El orden en que se mira un 403, y ahora tienes la herramienta para los tres pasos.** Primero,
> **qué authorities llegaron** —esta línea—. Segundo, **qué pedía la regla** —tu `SecurityConfig`—.
> Tercero, si las dos coinciden y sigue fallando, **qué cadena matcheó**, que es el `DEBUG` de
> Security y casi siempre revela que la URL entró por otra cadena.

Deja el logger como estaba antes de seguir, que si no la sección 10 va a ser ilegible:

```bash
curl -s -X POST localhost:8081/actuator/loggers/org.springframework.security \
  -H 'Content-Type: application/json' -d '{"configuredLevel":null}' -w '%{http_code}\n'
```

- **`{"configuredLevel":null}`** devuelve el logger a su nivel heredado, y es lo que distingue
  subirlo de dejarlo clavado. Un `GET` al mismo endpoint confirma que `configuredLevel` desapareció
  y solo queda `effectiveLevel`.

---

## 5. ⚠️ El converter: el 403 con el token correcto

El diagnóstico ya está hecho: el token trae el rol y las authorities no. Falta entender **por qué el
default no puede resolverlo** y escribir las quince líneas que lo resuelven.

`JwtAuthenticationProvider` usa por defecto un `JwtGrantedAuthoritiesConverter` que hace una sola
cosa: lee el claim `scope` —o `scp`—, lo parte por espacios y prefija cada trozo con `SCOPE_`. Con
un IdP que emite scopes planos, eso alcanza y no escribes nada. Con Keycloak no alcanza, y la razón
es estructural:

```text
scope: "openid inventory.read inventory.write"        ← claim plano, de primer nivel
       → el default lo lee → SCOPE_openid, SCOPE_inventory.read, SCOPE_inventory.write   ✅

realm_access: { "roles": ["analyst", ...] }           ← objeto con una lista dentro
       → ningún converter por defecto entra ahí                                           ❌
```

- **La propiedad `spring.security.oauth2.resourceserver.jwt.authorities-claim-name` no salva esto**,
  y es lo primero que casi todo el mundo intenta: esa propiedad cambia **qué claim de primer nivel**
  se lee, no sabe bajar un nivel. Apuntarla a `realm_access` le da un `Map`, no una lista de
  strings, y el resultado es una authority sola con el `toString()` del mapa dentro o ninguna.
- **Tampoco lo salva tocar Keycloak.** Podrías añadir un protocol mapper que aplane los roles a un
  claim de primer nivel, y es una opción legítima; el problema es que entonces tu servicio depende
  de cómo esté configurado el realm de cada entorno, y lo que falla en preproducción no falla en
  desarrollo. **Mapear en el resource server es lo que se sostiene**, porque el código viaja con el
  servicio.

```java
// src/main/java/com/invlab/invapi/security/JwtConverterConfig.java
@Configuration
class JwtConverterConfig {

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtGrantedAuthoritiesConverter scopes = new JwtGrantedAuthoritiesConverter();   // SCOPE_*
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
        converter.setPrincipalClaimName("preferred_username");     // en el log, en vez del sub
        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            // SUMAR, nunca reemplazar: las reglas escritas contra SCOPE_ siguen vivas
            Collection<GrantedAuthority> authorities = new ArrayList<>(scopes.convert(jwt));
            Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
            if (realmAccess != null && realmAccess.get("roles") instanceof Collection<?> roles) {
                // Keycloak los emite en minúscula y sin prefijo; hasRole() espera ROLE_MAYÚSCULA
                roles.forEach(r -> authorities.add(
                        new SimpleGrantedAuthority("ROLE_" + r.toString().toUpperCase(Locale.ROOT))));
            }
            return authorities;
        });
        return converter;
    }
}
```

- **Declararlo como `@Bean` es todo el cableado.** La autoconfiguración de Boot busca un
  `JwtAuthenticationConverter` en el contexto y se lo pasa al `JwtAuthenticationProvider`: no hay que
  tocar la cadena ni registrar nada a mano. Si el bean no aparece en el contexto —porque la clase
  quedó fuera del escaneo de componentes—, el síntoma es exactamente el 403 de antes, sin ningún
  aviso de que tu converter no se está usando.
- **`new ArrayList<>(scopes.convert(jwt))` es la línea que más se olvida**, y su ausencia es un
  incidente: si devuelves solo los roles, **pierdes todos los `SCOPE_`** y todas las reglas escritas
  contra ellos —la primera de tu cadena, sin ir más lejos— empiezan a dar 403 sin que nada lo
  relacione con este fichero.
- **El prefijo `ROLE_` se pone aquí, a mano, y es una decisión, no un trámite.** La alternativa es
  no ponerlo y escribir `hasAuthority("analyst")` en las reglas. Las dos funcionan; lo que no
  funciona es mezclarlas, que es el 403 silencioso de
  [`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_). El curso
  pone el prefijo porque `hasRole` es lo que vas a encontrar escrito en cualquier código de banca.
- **Y las mayúsculas cuentan exactamente igual que el prefijo**, que es la mitad del bug que casi
  nadie ve a la primera. Keycloak emite `analyst` en minúscula; `hasRole("ANALYST")` compara contra
  el literal `ROLE_ANALYST`, así que una authority `ROLE_analyst` produce **el mismo 403, igual de
  mudo** que no haber prefijado nada. De ahí el `toUpperCase(Locale.ROOT)`, y el locale va explícito
  porque en la configuración regional turca la `i` se convierte en `ı` y `ROLE_ANALYST` dejaría de
  salir en una máquina y sí en otra. La alternativa honesta es escribir la regla tal y como llega el
  token —`hasAuthority("ROLE_analyst")`—; lo que no vale es mezclar los dos criterios.
- **`instanceof Collection<?> roles` es un pattern match de Java 21**, y está en vez de un cast
  ciego por una razón concreta: el día que el realm cambie ese claim de forma, un cast revienta con
  `ClassCastException` **en cada petición** y tumba el servicio entero; el pattern match degrada a
  "sin roles", que produce un 403 rastreable con la línea de log de la sección 4.
- **`setPrincipalClaimName("preferred_username")`** cambia lo que devuelve `Authentication#getName()`
  y con ello lo que tu `LoggingAccessDeniedHandler` imprime: el UUID ilegible pasa a ser
  `analyst@invlab.example`. El matiz que hay que saber decir en una entrevista es que
  **`preferred_username` no es estable** —un usuario puede renombrarse, y entonces dos filas de
  auditoría con nombres distintos son la misma persona—: para correlacionar se guarda el `sub`, para
  leer se muestra el otro. Aquí el destino es un log de diagnóstico, así que gana la legibilidad.
- **Quién ejecuta esto y en qué hilo:** el converter corre dentro del `BearerTokenAuthenticationFilter`,
  en el hilo del request, **una vez por petición** y después de que la firma se haya verificado. No
  hay proxy de por medio: no es una anotación declarativa, es una lambda que alguien llama.

**Predice antes de ejecutar.** Con el converter puesto, el analista tiene `ROLE_ANALYST` y el
invitado no tiene ningún rol de negocio. Escribe los tres códigos antes de mirar: el `POST` del
analista, el `GET` del invitado y el `POST` del invitado. **Uno de los tres no es el que esperas**,
y esa sorpresa es el contenido de la segunda mitad de la sección.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'POST analyst -> %{http_code}\n' -X POST -H "Authorization: Bearer $ANALYST" \
  -H 'Content-Type: application/json' -d '{"delta":1,"reason":"recepcion"}' \
  localhost:8080/api/items/ABC-000123/events
curl -s -o /dev/null -w 'GET  guest   -> %{http_code}\n' -H "Authorization: Bearer $GUEST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'POST guest   -> %{http_code}\n' -X POST -H "Authorization: Bearer $GUEST" \
  -H 'Content-Type: application/json' -d '{"delta":1,"reason":"recepcion"}' \
  localhost:8080/api/items/ABC-000123/events
grep 'WARN' app.log | tail -2
```

```text
POST analyst -> 200
GET  guest   -> 200
POST guest   -> 403
```

- **El `POST` del analista pasa a `200` sin tocar la cadena ni Keycloak**, solo con el bean nuevo.
  Ese es el experimento: la regla `hasRole("ANALYST")` no cambió, lo que cambió es lo que llega al
  `AuthorizationManager`.
- **El `403` del invitado en el `POST` es el control**, y sin él el experimento no prueba nada: si
  hubieras arreglado el converter y todo el mundo pasara, habrías desactivado la autorización en vez
  de arreglar el mapeo. Su línea `WARN` ahora se lee sola, porque el `principal` dejó de ser un
  UUID: dice `principal=guest@invlab.example` y una lista de authorities donde están `SCOPE_openid`,
  `SCOPE_email`, `SCOPE_profile`, `SCOPE_inventory.read` y los `ROLE_` que Keycloak da a todo el
  mundo (`ROLE_DEFAULT-ROLES-INV`, `ROLE_OFFLINE_ACCESS`, `ROLE_UMA_AUTHORIZATION`) —y ningún
  `ROLE_ANALYST`.
- **Y el `200` del `GET` del invitado es el hallazgo de la sección**, el que no estaba en el guion.
  Predecías un `403` y llega un `200`: el invitado, que no tiene ningún rol, acaba de leer la
  valoración de un item.

### El scope no es un permiso de la persona

No hay ningún bug que arreglar: la regla hace exactamente lo que dice. `GET /api/items/**` exige
`SCOPE_inventory.read`, y el invitado **la trae**, igual que el analista. Vuelve a mirar el realm de
la sección 2 y verás por qué:

```text
inv-cli.defaultClientScopes = [openid, profile, email, roles, inventory.read]
       → Keycloak lo mete en el token de CUALQUIERA que pida uno con este cliente
       → el converter por defecto lo convierte en SCOPE_inventory.read
       → la regla lo acepta, sin mirar quién es la persona
```

- **Un scope describe qué está autorizada a pedir la aplicación; un rol describe qué puede hacer la
  persona.** Es la distinción que
  [`21` §1](21-identidad-federada-oauth2-oidc-y-jwt.md#1--el-problema-la-credencial-que-no-puede-viajar)
  plantea con los cuatro roles de OAuth2 y que aquí se toca con el dedo: `inventory.read` está
  configurado **en el client**, no en el usuario, así que confundir las dos cosas es regalarle a
  todo el realm lo que creías haber dado a un rol.
- **Que un scope viaje por defecto no es un fallo de Keycloak**, es su modelo: los
  `defaultClientScopes` existen precisamente para lo que el client necesita siempre. Lo que está
  mal es haber escrito una regla de negocio contra uno de ellos.
- **Y el `SCOPE_` sigue sirviendo**, no se tira: es el techo de lo que ese client puede llegar a
  hacer. La regla correcta pide **las dos cosas** —que el client tenga el scope **y** que la persona
  tenga el rol—, y Spring Security la escribe componiendo dos `AuthorizationManager`:

```java
// en SecurityConfig.apiChain, sustituyendo la regla de GET /api/items/**
.requestMatchers(HttpMethod.GET, "/api/items/**")
        .access(AuthorizationManagers.allOf(
                AuthorityAuthorizationManager.hasAuthority("SCOPE_inventory.read"),
                AuthorityAuthorizationManager.hasRole("ANALYST")))
```

- **`.access(...)` es la puerta de atrás de `authorizeHttpRequests`**: donde `hasRole` y
  `hasAuthority` son atajos que construyen un `AuthorizationManager` por ti, `access` te deja pasar
  el tuyo. Es lo que se usa cuando la decisión no cabe en un atajo.
- **`AuthorizationManagers.allOf(...)` concede solo si conceden todos** —hay un `anyOf` para lo
  contrario—, y cada `AuthorityAuthorizationManager` es exactamente el que fabricaban los atajos:
  `hasRole("ANALYST")` sigue añadiendo el prefijo y comparando contra `ROLE_ANALYST`, con las
  mayúsculas que el converter acaba de normalizar.
- **La alternativa es un `@PreAuthorize` con SpEL** —`hasAuthority('SCOPE_inventory.read') and
  hasRole('ANALYST')`—, y es perfectamente válida; en la cadena, componer managers evita meter una
  expresión que solo se valida en tiempo de ejecución dentro de la configuración de seguridad.
- **Y el test de `MockMvc` de la sección 3 se pone rojo**, que es exactamente para lo que está: pasa
  un `jwt()` con `SCOPE_inventory.read` a secas y la regla ahora pide dos cosas. Añádele
  `new SimpleGrantedAuthority("ROLE_ANALYST")` al `authorities(...)` y vuelve al verde. Un cambio de
  regla de autorización que **no** rompe ningún test es un cambio que nadie estaba vigilando.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'GET  analyst -> %{http_code}\n' -H "Authorization: Bearer $ANALYST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'GET  guest   -> %{http_code}\n' -H "Authorization: Bearer $GUEST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'POST guest   -> %{http_code}\n' -X POST -H "Authorization: Bearer $GUEST" \
  -H 'Content-Type: application/json' -d '{"delta":1,"reason":"recepcion"}' \
  localhost:8080/api/items/ABC-000123/events
grep 'WARN' app.log | tail -2
```

```text
GET  analyst -> 200
GET  guest   -> 403
POST guest   -> 403
```

- **Ahora sí hay un control limpio**: el analista lee y ajusta, el invitado no hace ninguna de las
  dos, y las dos denegaciones dejan su línea con las authorities que llegaron.
- **El invitado sigue teniendo `SCOPE_inventory.read` en esa línea**, y conviene releerla con eso en
  mente: la evidencia del log te dice que el scope estaba y que el rol no, que es precisamente la
  distinción que acabas de aprender a leer.

> **⚠️ Un `403` que se arregla ampliando la regla casi nunca estaba arreglado, y un `200` que
> sorprende casi siempre es una regla mal escrita.** La tentación al llegar al 403 del `POST` era
> cambiar `hasRole("ANALYST")` por `authenticated()` y seguir: funciona, y le abre el ajuste de
> inventario a cualquiera con un token del realm. La tentación al llegar al `200` del `GET` es no
> hacer nada, porque nadie se queja. Las dos veces la pregunta correcta es la misma, la de la
> sección 4 —**qué trajo el usuario frente a qué pedía la regla**— y las dos veces la respuesta
> estaba en un sitio distinto: en el mapeo la primera, en la regla la segunda.

---

## 6. 🧱 Method security, y la self-invocation por cuarta vez

La autorización por URL protege rutas. No protege **métodos**, y esa diferencia deja de ser
académica en cuanto un servicio se llama desde dos sitios: un endpoint nuevo, un `@Scheduled`, un
job de Batch. La regla tiene que vivir donde vive el dato.

```java
// en InventoryValuationService, sobre el método que L06 cacheaba
@PreAuthorize("hasRole('ANALYST')")            // por rol, con la lección de la sección 5 aprendida
@Cacheable(cacheNames = "inventory-items", sync = true)
public Valuation valuation(String sku) { /* lo de L06, sin cambios */ }
```

```java
// src/main/java/com/invlab/invapi/config/MethodSecurityConfig.java
@Configuration
@EnableMethodSecurity            // el starter NO lo activa solo
class MethodSecurityConfig { }
```

- **`@EnableMethodSecurity` hay que escribirlo.** Sin esta anotación, `@PreAuthorize` es un
  comentario decorado: no falla el arranque, no avisa, y el método corre para todo el mundo. En
  Security 6 ya trae `prePostEnabled = true`, así que no hay que pasarle nada, y **sustituye a
  `@EnableGlobalMethodSecurity`**, que se retiró.
- **Esto es el proxy de [`05`](05-proxies-y-aop.md) otra vez, con otro sombrero.** El interceptor de
  method security corre en el hilo del llamante, **dentro** del `DispatcherServlet` —a diferencia
  del `AuthorizationFilter`, que corre antes—, y lee el mismo `SecurityContextHolder`. Que corra
  dentro es lo que explica que un `@ExceptionHandler(AccessDeniedException.class)` sí pueda
  atraparlo, y que corra sobre un proxy es lo que explica todo lo que viene ahora.
- **El orden con `@Cacheable` importa y no es obvio.** Los dos son interceptores sobre el mismo
  proxy, y `@PreAuthorize` se evalúa **antes** que la caché: eso es lo que quieres, porque lo
  contrario sería servir desde caché un dato cuya autorización nunca se comprobó. La razón es que el
  interceptor de autorización tiene un orden más bajo que el de caché, y no hay que confiar en la
  casualidad: `AuthorizationInterceptorsOrder` lo fija explícitamente.

### El endpoint de informe, y el agujero

Añades un endpoint que valora varios SKU de golpe. La regla de URL para él es la más floja posible
—basta con estar autenticado— porque el permiso fino ya lo pone el método:

```java
// en SecurityConfig.apiChain, ANTES de la regla de GET /api/items/**
.requestMatchers(HttpMethod.GET, "/api/reports/**").authenticated()
```

```java
// src/main/java/com/invlab/invapi/inventory/ValuationReportController.java
@RestController
@RequestMapping(path = "/api/reports", produces = MediaType.APPLICATION_JSON_VALUE)
class ValuationReportController {

    private final InventoryValuationService valuations;

    ValuationReportController(InventoryValuationService valuations) {
        this.valuations = valuations;
    }

    @GetMapping("/valuations")
    List<Valuation> report(@RequestParam List<String> sku) {
        return valuations.valuations(sku);     // el método nuevo de abajo
    }
}
```

```java
// en InventoryValuationService, junto al método anterior. SIN anotación de seguridad
public List<Valuation> valuations(List<String> skus) {
    // llamada interna: this.valuation(...), no el proxy
    return skus.stream().map(this::valuation).toList();
}
```

- **La regla de `/api/reports/**` va escrita antes** que la de `/api/items/**` por el orden de
  evaluación de `authorizeHttpRequests`: gana la primera que matchea. Aquí no se solapan, pero la
  costumbre de declarar de lo específico a lo general es lo que evita el día en que sí se solapen.
- **`valuations(...)` no lleva `@PreAuthorize` a propósito**, y ese es el diseño que el lab quiere
  poner a prueba: quien lo escribió pensó *"no hace falta, el método que hace el trabajo ya está
  protegido"*. Es la frase exacta que produce el agujero.
- **`this::valuation` es una referencia a método sobre `this`**, es decir, sobre el objeto real y no
  sobre el proxy. Escrito como `skus.stream().map(sku -> valuation(sku))` sería igual de invisible.

**Predice antes de ejecutar.** El invitado no tiene `ROLE_ANALYST` y su `GET` directo a
`/api/items/ABC-000123/valuation` acaba de dar `403`. ¿Qué le va a devolver el informe, que llama al
mismo método?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'valuation directo -> %{http_code}\n' -H "Authorization: Bearer $GUEST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'informe           -> %{http_code}\n' -H "Authorization: Bearer $GUEST" \
  'localhost:8080/api/reports/valuations?sku=ABC-000123'
```

```text
valuation directo -> 403
informe           -> 200
```

- **Ese `200` es un fallo de seguridad, no un fallo de configuración**, y esa es la diferencia con
  las tres veces anteriores que este curso mostró self-invocation. En `L04` lo que se perdía era un
  rollback; en `L06`, una entrada de caché y un hilo. Aquí lo que se pierde es **una comprobación
  que nunca ocurrió**, y no hay ninguna excepción, ningún log y ningún test que lo note: el endpoint
  responde `200` con los datos dentro.
- **El mecanismo es idéntico al de siempre y por eso el curso lo repite**: el contenedor te entregó
  un proxy, `report()` llamó a `valuations(...)` **a través del proxy** —es otro bean—, pero
  `valuations(...)` llamó a `valuation(...)` **sobre `this`**, y el interceptor de autorización vive
  en el proxy, no en el objeto ([`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)).
- **Y hay un segundo efecto que conviene notar**: por la misma razón, `@Cacheable` tampoco se aplicó
  en esa ruta. El informe consultó la base tantas veces como SKU le pasaste, y el contador de
  `L06` lo demuestra — es el ejercicio 6.

La corrección es la de siempre: **el fan-out sale del bean**.

```java
// src/main/java/com/invlab/invapi/inventory/ValuationReportService.java
@Service
class ValuationReportService {

    private final InventoryValuationService valuations;   // otro bean: hay proxy en medio

    ValuationReportService(InventoryValuationService valuations) {
        this.valuations = valuations;
    }

    List<Valuation> report(List<String> skus) {
        return skus.stream().map(valuations::valuation).toList();
    }
}
```

- **Se inyecta el bean y se llama a través de él**, que es lo mismo que decir "a través del proxy".
  El controller pasa a depender de `ValuationReportService` y el método `valuations(...)` de
  `InventoryValuationService` desaparece.
- **La alternativa que vas a ver escrita es inyectarse a sí mismo** —`@Lazy InventoryValuationService
  self`— y llamar `self.valuation(sku)`. Funciona y es fea: el código dice "me llamo a mí mismo por
  la puerta de la calle" y no explica por qué. Sirve cuando partir la clase no es viable; cuando lo
  es, se parte.
- **Lo que no arregla nada es poner `@PreAuthorize` también en `valuations(...)`.** Taparía este
  caso y dejaría vivo el siguiente: la regla seguiría dependiendo de que nadie añada un tercer
  método que llame a `valuation(...)` desde dentro.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'informe guest   -> %{http_code}\n' -H "Authorization: Bearer $GUEST" \
  'localhost:8080/api/reports/valuations?sku=ABC-000123'
curl -s -o /dev/null -w 'informe analyst -> %{http_code}\n' -H "Authorization: Bearer $ANALYST" \
  'localhost:8080/api/reports/valuations?sku=ABC-000123'
grep 'WARN' app.log | tail -1
```

```text
informe guest   -> 403
informe analyst -> 200
```

- **El `403` del invitado sale ahora por method security, no por la URL**, y eso cambia quién lo
  produce: la excepción es una `AuthorizationDeniedException` —subclase de `AccessDeniedException`
  desde Security 6.3— lanzada por el interceptor **dentro** del `DispatcherServlet`. Sube por la
  pila, ningún `@ExceptionHandler` la reclama, llega al `ExceptionTranslationFilter` y acaba en tu
  `LoggingAccessDeniedHandler`, que escribe la misma línea `WARN` de siempre. **El camino es
  distinto y el resultado es idéntico**, que es justo la asimetría que
  [`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe) describe.
- **El analista pasa porque su token trae el rol `analyst`**, que el converter convirtió en
  `ROLE_ANALYST` y es lo que pide el `@PreAuthorize`. Fíjate en que la regla de método es **por rol
  y no por scope**, y no por casualidad: un `hasAuthority('SCOPE_inventory.read')` aquí dejaría
  pasar al invitado por lo mismo que la sección 5 acaba de enseñar, y el agujero de arriba ni
  siquiera se notaría. Si añadieras un `@ExceptionHandler(AccessDeniedException.class)` a tu
  `@RestControllerAdvice`, **esta** denegación la atraparía él y Security no llegaría a verla,
  mientras que la de la sección 4 seguiría saliendo por el handler. Dos sitios para la misma
  excepción según dónde se lanzó: conviene decidirlo, no descubrirlo.

---

## 7. ⚠️ El `SecurityContext` que no cruza al `@Async`

[`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás)
terminó con una promesa a medias. Allí perdiste el `requestId` al saltar de hilo, lo arreglaste con
un `TaskDecorator`, y el texto decía que **el mismo mecanismo se lleva otras dos cosas** —el
`SecurityContext` y el `RequestContextHolder`—, sin poder demostrarlo porque Spring Security no
estaba en el classpath. Hoy sí está, y el `warmUp` asíncrono llama a un método que acabas de
proteger con `@PreAuthorize`. Se ejecuta ahora.

Añade una línea al método asíncrono para que diga con quién cree que está corriendo:

```java
// en InventoryValuationFacade, dentro de warmUp
@Async("inventoryExecutor")
void warmUp(String sku) {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    log.info("recalentando {} con authentication={}", sku, auth == null ? "null" : auth.getName());
    valuations.valuation(sku);              // ahora lleva @PreAuthorize
}
```

- **`SecurityContextHolder.getContext()` nunca devuelve `null`**, y ese es el matiz que hace falta
  para leer bien lo que viene: si el `ThreadLocal` está vacío, el holder devuelve un
  `SecurityContext` **nuevo y vacío**, cuyo `getAuthentication()` sí es `null`. Por eso la guarda va
  sobre `auth` y no sobre el contexto, y por eso el síntoma nunca es un `NullPointerException` en
  esta línea.
- **`auth.getName()` es lo único que se registra**, no el objeto entero: un `Authentication` de JWT
  lleva dentro el token completo, y su `toString()` acabaría escribiendo una credencial en el log.

**Predice antes de ejecutar.** El `POST` llega con el token del analista, que trae el rol `analyst`
y por tanto la authority `ROLE_ANALYST` que pide el `@PreAuthorize` recién puesto. La respuesta del
`POST` sale antes de que el hilo del pool haga nada. ¿Qué va a decir esa línea, y qué va a pasar con
la llamada a `valuation(...)`?

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
docker exec -i inv-lab-redis-1 redis-cli FLUSHALL
curl -s -o /dev/null -w 'POST -> %{http_code}\n' -X POST -H "Authorization: Bearer $ANALYST" \
  -H 'X-Request-Id: async-01' -H 'Content-Type: application/json' \
  -d '{"delta":2,"reason":"recepcion"}' localhost:8080/api/items/ABC-000123/events
sleep 2
grep 'async-01' app.log
grep -A1 'AuthenticationCredentialsNotFoundException' app.log | head -2
```

- **`FLUSHALL` vacía la caché de `L06`** antes del experimento: con la valoración cacheada, el
  `@Cacheable` devolvería el valor sin llegar al interceptor de seguridad y el fallo no aparecería.
  Es el orden de interceptores de la sección 6 jugando en tu contra — y una buena lección sobre por
  qué un fallo de autorización puede ser intermitente.

El `POST` responde `200` —nadie espera al hilo del pool—, y en el log salen la línea que escribiste
tú y una traza que no. La primera es literal:

```text
 INFO [async-01] --- [   inv-task-1] c.i.i.InventoryValuationFacade : recalentando ABC-000123 con authentication=null
```

La segunda la escribe el manejador por defecto de excepciones asíncronas de Spring, con nivel
`ERROR`, y **su formato completo depende de tu configuración de logging**, así que aquí va la
primera línea de la excepción, que es lo que hay que reconocer, y el resto descrito en prosa: son
cuarenta y tantos frames de proxy y de `ThreadPoolExecutor` sin ninguna línea tuya hasta el final.

```text
org.springframework.security.authentication.AuthenticationCredentialsNotFoundException: An Authentication object was not found in the SecurityContext
```

- **`authentication=null` es la prueba directa y no hay que interpretarla.** El `requestId` sí
  viajó —ahí está `[async-01]` en la línea del hilo `inv-task-1`, gracias al `MdcTaskDecorator` de
  `L06`—, y aun así la identidad no. **Copiar el MDC propaga los textos que se imprimen, no los
  contextos**, que es exactamente la trampa fina que `L07` §10 ya te mostró con el contexto de
  observación. Tres contextos distintos, tres mecanismos de propagación distintos.
- **La excepción no es la que espera casi todo el mundo.** `20` §6 describe el síntoma como *una
  `AccessDeniedException` con un usuario que sí tenía el rol*, y eso es lo que ves cuando el
  contexto **llega con menos authorities** de las que hacen falta. Cuando el contexto no llega en
  absoluto, el interceptor no tiene a quién evaluar y lanza antes:
  `AuthenticationCredentialsNotFoundException`, que desciende de `AuthenticationException` y no de
  `AccessDeniedException`. **Las dos son el mismo bug con dos caras**, y saber cuál estás viendo te
  dice si el problema es el salto de hilo o el mapeo de authorities.
- **Nadie se entera, y esa es la parte cara.** `warmUp` devuelve `void`, así que la excepción no
  tiene a dónde ir: se la come el `SimpleAsyncUncaughtExceptionHandler`, que la registra y sigue.
  El `POST` respondió `200`, el cliente está contento, y la caché se quedó sin recalentar. Si en vez
  de un recalentamiento esto fuera un apunte contable, el `void` sería el bug y no la seguridad
  ([`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás)).
- **`MODE_INHERITABLETHREADLOCAL` no es la salida.** Hereda el contexto a los hilos **hijos**, y los
  de un pool no son hijos de nadie: los creó el pool al arrancar, mucho antes de tu petición
  ([`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas)).

### Propagarlo: decorar el pool por fuera

`L06` lo dejó anunciado con estas palabras —*`DelegatingSecurityContextAsyncTaskExecutor`, que
decora al pool por fuera en vez de sustituir el decorador*—. Esto es eso:

```java
// AsyncConfig, reescrito: el pool se construye igual y se envuelve al devolverlo
@Bean("inventoryExecutor")
AsyncTaskExecutor inventoryExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
    executor.setCorePoolSize(4);
    executor.setMaxPoolSize(8);
    executor.setQueueCapacity(50);
    executor.setThreadNamePrefix("inv-task-");
    executor.setWaitForTasksToCompleteOnShutdown(true);
    executor.setAwaitTerminationSeconds(20);
    executor.setTaskDecorator(new CompositeTaskDecorator(List.of(
            new ContextPropagatingTaskDecorator(),     // traceId y spanId como contexto (L07 §10)
            new MdcTaskDecorator())));                 // requestId, que no conoce nadie más
    executor.initialize();
    // y el SecurityContext, por fuera de todo lo anterior
    return new DelegatingSecurityContextAsyncTaskExecutor(executor);
}
```

- **El nombre del bean no cambia**, y eso es lo que hace que `@Async("inventoryExecutor")` siga
  apuntando aquí sin tocar el método anotado. El tipo declarado sube de `TaskExecutor` a
  `AsyncTaskExecutor` porque es lo que exige el decorador de Security — y porque `@Async` necesita
  un `AsyncTaskExecutor` de todas formas para las tareas que devuelven `Future`.
- **`DelegatingSecurityContextAsyncTaskExecutor` envuelve, no sustituye.** Recibe cada `Runnable` en
  el hilo que **envía** la tarea, copia el `SecurityContext` que hay en ese instante, y en el hilo
  que la **ejecuta** lo instala antes de correr y lo limpia después. Es el mismo patrón de tu
  `MdcTaskDecorator`, escrito por Spring Security para otro `ThreadLocal`.
- **Por qué va por fuera y no como un tercer `TaskDecorator`:** un executor admite **un** solo
  `TaskDecorator`, ya ocupado por el `CompositeTaskDecorator` de `L07`. Podrías meter un decorador
  propio de seguridad dentro del composite y funcionaría; usar el de Security es preferible porque
  **limpia el contexto en un `finally`** y maneja el caso del contexto vacío, que son las dos cosas
  que se olvidan al escribirlo a mano.
- **El orden de la composición importa y no es arbitrario.** El decorador de seguridad, al estar más
  afuera, instala el `SecurityContext` **antes** de que corran los otros dos y lo limpia **después**:
  si el `ContextPropagatingTaskDecorator` abriera una observación que consultara la identidad, la
  encontraría puesta. Al revés, la observación arrancaría sin usuario.
- **Propagar es copiar, no compartir.** Es importante aquí porque el `FilterChainProxy` limpia el
  `SecurityContextHolder` del hilo de Tomcat en un `finally` en cuanto la respuesta sale
  ([`20` §2](20-spring-security-el-mecanismo.md#2--security-es-un-solo-filtro-y-por-dentro-son-veinte)):
  si esto compartiera la referencia, tu tarea se quedaría sin identidad justo cuando el `POST`
  responde. Copia, así que no.

⏱️ **Costo en runtime.** Una copia de referencia por tarea enviada, medida en nanosegundos: esto no
es un gasto, es un `try/finally`. Lo caro es lo contrario — un fallo de autorización intermitente
que solo aparece cuando la caché está fría, que es lo que acabas de reproducir a mano con un
`FLUSHALL`.

```bash
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
docker exec -i inv-lab-redis-1 redis-cli FLUSHALL
curl -s -o /dev/null -X POST -H "Authorization: Bearer $ANALYST" \
  -H 'X-Request-Id: async-02' -H 'Content-Type: application/json' \
  -d '{"delta":2,"reason":"recepcion"}' localhost:8080/api/items/ABC-000123/events
sleep 2
grep 'async-02' app.log
grep -c 'AuthenticationCredentialsNotFoundException' app.log
```

```text
 INFO [async-02] --- [nio-8080-exec-2] c.i.i.InventoryController       : ...
 INFO [async-02] --- [   inv-task-2] c.i.i.InventoryValuationFacade  : recalentando ABC-000123 con authentication=analyst@invlab.example
 INFO [async-02] --- [   inv-task-2] c.i.i.InventoryValuationService : valoración de ABC-000123 calculada contra la base
 0
```

- **`authentication=analyst@invlab.example`**, y no el UUID, porque el `setPrincipalClaimName` de la
  sección 5 también gobierna aquí: es el mismo `Authentication` copiado, no uno reconstruido.
- **La tercera línea es la que cierra el círculo**: `valuation(...)` se ejecutó, con su
  `@PreAuthorize` evaluado y aprobado, en un hilo `inv-task-` — es decir, method security funcionó
  fuera del hilo del request, que es de lo que iba todo esto.
- **El `0` del último `grep` es el criterio de terminado de la sección**, y es mejor prueba que las
  tres líneas juntas: la excepción que provocaste a propósito ya no aparece en ninguna parte del
  fichero.
- **El número del hilo puede ser otro en tu máquina** —`inv-task-1`, `nio-8080-exec-5`—, como
  siempre. Lo que no puede cambiar es que los tres corchetes coincidan y que la segunda línea no
  diga `null`.

---

## 8. 🧱 Asegurar Actuator con `EndpointRequest.toAnyEndpoint()`

Llevas cinco secciones viendo `actuator/env -> 200`. Esta es la tercera capa de defensa que
[`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura)
delegó y que [`L07` §2](l07-actuator-metricas-y-trazas.md#2--exposición-con-criterio-y-el-8081-que-ya-tenías)
dejó nombrada sin poder ejecutar. Las dos primeras ya están puestas —exponer poco, y ligar el
conector a `127.0.0.1`—; esta exige un rol.

```java
// en SecurityConfig, ANTES del bean apiChain
@Bean
@Order(0)
SecurityFilterChain actuatorChain(HttpSecurity http) throws Exception {
    http
        .securityMatcher(EndpointRequest.toAnyEndpoint()
                .excluding(HealthEndpoint.class, PrometheusScrapeEndpoint.class))
        .authorizeHttpRequests(auth -> auth.anyRequest().hasRole("OPS"))
        .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()))
        .csrf(csrf -> csrf.disable())
        .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
    return http.build();
}
```

- **`EndpointRequest.toAnyEndpoint()` resuelve las rutas reales en tiempo de ejecución**, y por eso
  no se escribe `/actuator/**` a mano: respeta `management.endpoints.web.base-path`, respeta el
  puerto separado del 8081 y sigue siendo correcto el día que alguien mueva el base path. Un
  matcher literal se queda obsoleto en silencio, que es la peor forma de quedarse obsoleto en
  seguridad.
- **`@Order(0)` la pone delante de `apiChain`**, que es `@Order(1)`. `FilterChainProxy` elige **la
  primera cadena que matchea** y no evalúa las demás; como esta solo matchea endpoints de Actuator y
  la otra solo `/api/**`, hoy no se solapan, pero el orden explícito es lo que evita que un cambio
  futuro deje una de las dos muerta.
- **`hasRole("OPS")` funciona gracias al converter de la sección 5**, y conviene notarlo: sin el
  prefijo `ROLE_` que añadiste allí, esta regla daría 403 a `ops@invlab.example` con su rol puesto.
  Las dos secciones están encadenadas.
- **`oauth2ResourceServer` otra vez, y no `httpBasic`.** `20` §10 propone Basic porque a Actuator lo
  consume una herramienta y una sesión no le aporta nada; aquí se usa JWT por coherencia —no hay
  ningún `UserDetailsService` en este proyecto y no vamos a inventar un almacén de usuarios para
  tres endpoints— y porque permite que el mismo Keycloak gobierne quién opera la plataforma. **Cada
  cadena declara su propia autenticación**: que la de `/api/**` use JWT no se lo regala a esta.
- **`HealthEndpoint` queda fuera** porque es lo que sondea un balanceador o un orquestador, que no
  tiene token. Lo correcto en producción es abrir **solo los grupos de probes**
  —`/actuator/health/liveness` y `/actuator/health/readiness`— y dejar el `health` detallado dentro,
  porque con `show-details` distinto de `never` publica el estado de tus dependencias a quien
  pregunte; en el lab `show-details: always` viene de `L01` y se queda por comodidad, sabiendo que
  es una decisión de laboratorio.
- **`PrometheusScrapeEndpoint` también queda fuera, y esta exclusión sí es una concesión.** El
  Prometheus de `L07` raspa cada quince segundos y no tiene forma de conseguir un token: si cierras
  ese endpoint, el target se cae y el tablero se vacía. Las salidas reales son tres —dar al scraper
  un client de `client_credentials`, poner un Basic propio para él, o dejar el endpoint accesible
  solo desde la red de observabilidad—, y la tercera es la que usa casi todo el mundo, que es lo que
  el `address: 127.0.0.1` de `L07` ya hace en esta máquina. Se excluye y se dice por qué en vez de
  romper el lab anterior sin explicación.

**Predice antes de ejecutar.** Tres peticiones al 8081: `/actuator/env` sin token, `/actuator/env`
con el token del analista, y `/actuator/health`. ¿`401`, `403` o `200`?

```bash
OPS=$(get_token ops@invlab.example ops)
kill %1
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 12
curl -s -o /dev/null -w 'env sin token   -> %{http_code}\n' localhost:8081/actuator/env
curl -s -o /dev/null -w 'env analyst     -> %{http_code}\n' -H "Authorization: Bearer $ANALYST" localhost:8081/actuator/env
curl -s -o /dev/null -w 'env ops         -> %{http_code}\n' -H "Authorization: Bearer $OPS" localhost:8081/actuator/env
curl -s -o /dev/null -w 'health          -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'prometheus      -> %{http_code}\n' localhost:8081/actuator/prometheus
curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'
```

```text
env sin token   -> 401
env analyst     -> 403
env ops         -> 200
health          -> 200
prometheus      -> 200
1
```

- **Los tres primeros son la tabla de `20` §9 en tres líneas**, y ahora con los dos beans de la
  sección 4 detrás… salvo que no: esta cadena **no** los declara, así que el `401` y el `403` del
  8081 salen otra vez con el cuerpo vacío y sin log. Es deliberado, es visible, y convertirlo en
  un par de beans compartidos por las dos cadenas es el ejercicio 9.
- **`health -> 200` y `prometheus -> 200`** son las dos exclusiones funcionando, y el `1` del último
  comando lo confirma desde el otro lado: Prometheus sigue raspando y el target de `L07` sigue
  arriba. Si ese valor hubiera salido `0`, la métrica `up` te habría dicho en un comando lo que un
  tablero vacío tarda media hora en insinuar.
- **`env analyst -> 403` es la prueba de que las dos cadenas son independientes.** El mismo token
  que abre `/api/items/**` no abre Actuator, porque cada cadena tiene sus reglas y el rol `analyst`
  no es `ops`. Separar operación de negocio en dos roles distintos es lo normal en banca, y aquí se
  ve que sale gratis.
- **Vuelve a mirar `/actuator/env` con el token de `ops` y busca `spring.datasource.url`**: sigue
  ahí, y ahora lo lee solo quien opera la plataforma. Esa es toda la diferencia que compraste con
  doce líneas.

---

## 9. 🧱 Batch: el esquema que nadie crea y el job con chunk

Cambia la mitad del lab y cambia el problema. Hasta aquí todo duraba milisegundos; ahora entra el
fichero de las dos de la mañana de
[`22` §1](22-spring-batch.md#1--el-problema-el-fichero-de-las-dos-de-la-mañana): sesenta mil líneas
que hay que conciliar antes de que abra la sucursal, y que se van a caer a la mitad.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-batch</artifactId>
</dependency>
```

- **Sin `<version>`**: el BOM de Boot 3.5.16 fija Spring Batch en **5.2.6** (propiedad
  `spring-batch.version` del `spring-boot-dependencies-3.5.16.pom`, comprobado en Maven Central).
  Importa saber el número exacto porque el fichero de esquema que vas a extraer en un momento vive
  dentro del jar de esa versión.
- **El starter trae `spring-batch-core` y `spring-boot-starter-jdbc`**, que ya tenías por `L04`. Lo
  que no trae es una base de datos: Spring Batch **exige** una real, aunque sea en memoria, porque
  todo su estado son filas.

### Las tablas, en Flyway y no en Boot

[`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco) lo avisa y aquí se
cobra: `spring.batch.jdbc.initialize-schema` vale `embedded` por defecto, o sea **se crean solas en
H2 y no se crean en tu Postgres**. En serio el esquema va versionado, como el resto, con la Flyway
de [`L04` §2](l04-datos-y-transacciones.md#2--postgres-en-compose-flyway-y-el-teardown).

Y los scripts no hay que escribirlos: vienen dentro del jar.

```bash
unzip -p ~/.m2/repository/org/springframework/batch/spring-batch-core/5.2.6/spring-batch-core-5.2.6.jar \
  org/springframework/batch/core/schema-postgresql.sql \
  > src/main/resources/db/migration/V2__batch_metadata.sql
head -3 src/main/resources/db/migration/V2__batch_metadata.sql
grep -c 'CREATE TABLE' src/main/resources/db/migration/V2__batch_metadata.sql
```

```text
-- Autogenerated: do not edit this file
6
```

- **`unzip -p` escribe a la salida estándar** sin descomprimir nada en disco, que es lo que permite
  redirigir directo al fichero de migración. El jar está en tu `~/.m2` desde el `package` anterior:
  si no está, un `./mvnw -q dependency:resolve` lo baja.
- **Hay un script por motor** —`schema-postgresql.sql`, `schema-h2.sql`, `schema-oracle.sql` y una
  docena más— y no son intercambiables: cambian los tipos, las secuencias y los `CLOB`. Copiar el de
  H2 a Postgres es un error de arranque con un mensaje que no menciona Batch por ninguna parte.
- **`6` es el número de tablas** que `22` §4 enumera, y verlo aquí es la confirmación de que el
  fichero es el correcto. El script crea además **tres secuencias** —`BATCH_JOB_SEQ`,
  `BATCH_JOB_EXECUTION_SEQ` y `BATCH_STEP_EXECUTION_SEQ`—, que es de donde salen los identificadores
  y que la mayoría de los resúmenes de internet olvida mencionar.
- **`V2__` asume que tu proyecto viene de `L04` con una sola migración.** Si hiciste los ejercicios
  de aquel lab que añadían `V2__add_inventory_item_category.sql` y `V3__`, este fichero es `V4__`:
  Flyway ordena por versión, y repetir un número es un fallo de arranque inmediato.
- **`-- Autogenerated: do not edit this file` es un aviso que conviene respetar** aunque el fichero
  esté ahora en tu repositorio. Si el día de mañana subes de línea de Spring Batch, el esquema puede
  cambiar y lo que toca es **añadir una migración nueva** con el delta, nunca editar esta.

La tabla de destino del job va en la misma migración:

```bash
cat >> src/main/resources/db/migration/V2__batch_metadata.sql <<'SQL'

CREATE TABLE inventory_reconciliation (
    id             BIGSERIAL    PRIMARY KEY,
    business_date  DATE         NOT NULL,
    sku            VARCHAR(10)  NOT NULL,
    delta          INTEGER      NOT NULL,
    source_line    INTEGER      NOT NULL,
    CONSTRAINT uq_inventory_reconciliation UNIQUE (business_date, sku, source_line)
);
SQL
```

> **⚠️ Una tabla nueva fuera del baseline, y se declara.** §5.3 de la guía de estilo fija
> `inventory_item` e `inventory_event` como las tablas de la serie. `inventory_reconciliation` es
> una tercera, y existe porque el job escribe **el resultado de conciliar un fichero con una fecha
> contable**, que no es un evento de inventario: meterlo en `inventory_event` obligaría a una
> clave foránea contra `inventory_item` por cada línea del fichero —una consulta por ítem dentro
> del chunk, justo lo que [`22` §8](22-spring-batch.md#8-️-el-writer-falla-a-la-mitad-del-chunk-el-puente-con-16)
> prohíbe— y mezclaría dos ciclos de vida distintos.

- **La restricción `UNIQUE (business_date, sku, source_line)` es la pieza central de la sección 10**,
  no un adorno de modelado. Es la **clave natural** de la que habla
  [`22` §6](22-spring-batch.md#6--restart-qué-se-reanuda-y-qué-tiene-que-cumplir-tu-reader): al
  reanudar, el chunk en vuelo **se vuelve a leer y a escribir siempre**, y sin esta restricción cada
  reanudación duplicaría hasta quinientas filas en silencio.
- **`source_line` es el número de línea del fichero de origen**, y viaja dentro del propio fichero.
  Es lo que permite que la clave natural exista: sin él, dos movimientos idénticos del mismo SKU en
  el mismo día serían indistinguibles y el `ON CONFLICT` de dentro de un momento borraría uno bueno.

### El fichero de entrada

```bash
mkdir -p data
generar() {
  { echo 'line;sku;delta;reason'
    awk -v n="$1" -v bad="$2" 'BEGIN {
        for (i = 1; i <= n; i++) {
            d = (i % 7) - 3;                  # entre -3 y 3
            if (d == 0) d = 4;                # nunca 0: el processor filtraría esa línea
            if (i == bad) d = 999999;         # el registro envenenado, si se pide
            printf "%d;ABC-%06d;%d;reconciliacion\n", i, (i % 50) + 1, d
        } }'
  } > "data/movements-$3.csv"
}
generar 10000 0 2026-09-17      # limpio
generar 60000 30001 2026-09-18  # con una línea envenenada en el ítem 30 001
wc -l data/movements-*.csv
```

```text
   10001 data/movements-2026-09-17.csv
   60001 data/movements-2026-09-18.csv
  120002 total
```

- **`wc -l` cuenta una línea más que ítems en los dos ficheros**, y es la cabecera. Ese desfase de
  uno es el origen de la mitad de los errores de `linesToSkip`, y verlo aquí ahorra el susto de
  encontrarse `sku` con el valor literal `"sku"` en la primera fila de la tabla.
- **`ABC-%06d` sobre `(i % 50) + 1`** genera cincuenta SKU que se repiten, que es lo que hace
  interesante la clave natural: el mismo SKU aparece mil doscientas veces en el fichero grande, y lo
  que la hace única es la línea.
- **`if (d == 0) d = 4`** evita el cero a propósito: el processor de abajo devuelve `null` para los
  ítems que hay que descartar, y con ceros en el fichero los contadores de la sección 10 dejarían de
  cuadrar. Hacer que ese camino se ejecute es el ejercicio 14.
- **La línea 30 001 del fichero grande lleva un `delta` de 999 999**, y es la bomba: el processor la
  va a rechazar. Está en un número redondo por una razón que la sección 10 aprovecha — con chunks de
  500, el ítem 30 001 es **el primero del chunk 61**, así que el último commit limpio cae justo en
  30 000 y los contadores salen redondos.

### El job, pieza a pieza

```java
// src/main/java/com/invlab/invapi/batch/MovementLine.java
record MovementLine(int line, String sku, int delta, String reason) { }

// src/main/java/com/invlab/invapi/batch/ReconciliationRow.java
record ReconciliationRow(LocalDate businessDate, String sku, int delta, int sourceLine) { }
```

```java
// src/main/java/com/invlab/invapi/batch/MovementProcessor.java
class MovementProcessor implements ItemProcessor<MovementLine, ReconciliationRow> {

    private final LocalDate businessDate;

    MovementProcessor(LocalDate businessDate) {
        this.businessDate = businessDate;
    }

    @Override
    public ReconciliationRow process(MovementLine item) {
        if (Math.abs(item.delta()) > 1000) {
            // no es un dato malo tolerable: es un fichero corrupto, y el lote tiene que parar
            throw new IllegalArgumentException(
                    "delta fuera de rango en la línea " + item.line() + ": " + item.delta());
        }
        if (item.delta() == 0) {
            return null;                  // devolver null FILTRA el ítem: no es un error
        }
        return new ReconciliationRow(businessDate, item.sku(), item.delta(), item.line());
    }
}
```

- **Devolver `null` filtra y lanzar aborta**, y son los dos únicos resultados que un `ItemProcessor`
  puede dar además del ítem transformado. El filtrado suma en `FILTER_COUNT` y no es un fallo; la
  excepción, sin `faultTolerant()`, mata el step
  ([`22` §7](22-spring-batch.md#7--skip-y-retry-cuando-un-registro-malo-no-puede-tumbar-el-lote)).
- **Aquí no hay `faultTolerant()` a propósito**, y la decisión se justifica: un `delta` de casi un
  millón no es una línea mal formateada que se pueda descartar, es un fichero que llegó mal. `22` §7
  lo dice con todas las letras —*el `skipLimit` lo firma quien entiende el dato*—, y este dato dice
  que hay que parar. Descartarlo y seguir es el ejercicio 15, con su `SkipListener` obligatorio.
- **El `businessDate` entra por constructor y no por `@Value`** porque esta clase no es un bean: la
  construye la configuración de abajo, dentro del scope del step. Un objeto que recibe lo que
  necesita por constructor se prueba con un `new` y sin contenedor.

```java
// src/main/java/com/invlab/invapi/batch/ReconciliationJobConfig.java
@Configuration
class ReconciliationJobConfig {

    @Bean
    @StepScope
    FlatFileItemReader<MovementLine> movementReader(
            @Value("${inv.batch.input-file}") Resource input) {
        return new FlatFileItemReaderBuilder<MovementLine>()
                .name("movementReader")            // la clave con la que guarda su posición
                .resource(input)
                .linesToSkip(1)                    // la cabecera
                .delimited().delimiter(";")
                .names("line", "sku", "delta", "reason")
                .targetType(MovementLine.class)
                .build();
    }

    @Bean
    @StepScope
    MovementProcessor movementProcessor(
            @Value("#{jobParameters['business.date']}") String businessDate) {
        return new MovementProcessor(LocalDate.parse(businessDate));
    }

    @Bean
    JdbcBatchItemWriter<ReconciliationRow> reconciliationWriter(DataSource dataSource) {
        return new JdbcBatchItemWriterBuilder<ReconciliationRow>()
                .dataSource(dataSource)
                .sql("""
                     INSERT INTO inventory_reconciliation (business_date, sku, delta, source_line)
                     VALUES (:businessDate, :sku, :delta, :sourceLine)
                     ON CONFLICT ON CONSTRAINT uq_inventory_reconciliation DO NOTHING
                     """)
                .itemSqlParameterSourceProvider(row -> new MapSqlParameterSource()
                        .addValue("businessDate", row.businessDate())
                        .addValue("sku", row.sku())
                        .addValue("delta", row.delta())
                        .addValue("sourceLine", row.sourceLine()))
                .build();
    }

    @Bean
    Step reconcileStep(JobRepository jobRepository, PlatformTransactionManager transactionManager,
                       FlatFileItemReader<MovementLine> movementReader,
                       MovementProcessor movementProcessor,
                       JdbcBatchItemWriter<ReconciliationRow> reconciliationWriter) {
        return new StepBuilder("reconcile-step", jobRepository)
                .<MovementLine, ReconciliationRow>chunk(500, transactionManager)
                .reader(movementReader).processor(movementProcessor).writer(reconciliationWriter)
                .build();
    }

    @Bean
    Job inventoryReconciliationJob(JobRepository jobRepository, Step reconcileStep) {
        return new JobBuilder("inventory-reconciliation-job", jobRepository)
                .start(reconcileStep)
                .build();
    }
}
```

- **No hay `@EnableBatchProcessing` en ninguna parte, y es deliberado.** En una aplicación Boot esa
  anotación **desactiva la autoconfiguración** de Batch, incluida la creación del `JobRepository` y
  la lectura de las propiedades `spring.batch.*`. Es la trampa número uno al copiar ejemplos de la
  documentación de Spring Batch a secas, que sí la lleva porque no asume Boot
  ([`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco)).
- **`@StepScope` en el reader y el processor es lo que permite el `#{jobParameters[...]}`.** Esa
  expresión se resuelve **tarde**, cuando el step arranca y los parámetros existen; sin el scope, el
  bean se crearía al levantar el contexto, cuando todavía no hay ninguna ejecución, y la expresión
  no tendría contra qué resolverse.
- **Los tres beans declaran su tipo concreto —`FlatFileItemReader<...>`,
  `MovementProcessor`, `JdbcBatchItemWriter<...>`— y no la interfaz**, y esto es una trampa real de
  `@StepScope`: el scope crea un proxy por subclase del **tipo que declara el método**, y si lo que
  declaras es una interfaz el cableado se complica o directamente falla. Declarar el tipo concreto
  cuesta nada y evita una tarde.
- **`.name("movementReader")` no es cosmético**: es la clave con la que el reader guarda su posición
  en el `ExecutionContext` del step. **Sin nombre, un reader con estado no se reanuda**, y ese es el
  requisito que `22` §6 llama *la condición que casi nadie menciona en una entrevista*. La sección
  10 entera depende de esta línea.
- **`.targetType(MovementLine.class)` con un `record`** hace que Spring Batch 5 use un
  `RecordFieldSetMapper`, que mapea por **el orden y el nombre de los componentes** del record
  contra los `names(...)` de arriba. Con una clase normal usaría el `BeanWrapperFieldSetMapper`, que
  necesita setters — otra razón para los `record` de §5.1 de la guía.
- **`chunk(500, transactionManager)` declara dos cosas de golpe**: el commit interval —cuántos ítems
  entran en una transacción— y **quién la abre**, que es el `PlatformTransactionManager` de
  [`16` §2](16-transacciones.md#2--el-modelo-y-quién-lo-invoca). En este proyecto ese bean es el
  `JpaTransactionManager` que autoconfiguró `L04`, y funciona porque comparte el mismo `DataSource`
  que el writer JDBC: si hubiera dos `DataSource`, el `JobRepository` y tu escritura podrían acabar
  en transacciones distintas, que es de donde sale `@BatchDataSource`.
- **`ON CONFLICT ON CONSTRAINT ... DO NOTHING` es la idempotencia del writer**, y está aquí por lo
  que `22` §6 llama con precisión *reanudable no es idempotente*: Spring Batch garantiza no volver a
  **contar** lo confirmado, no que tu `INSERT` sea seguro de repetir. El último chunk se repite
  siempre. Esta cláusula es la que convierte "se repite" en "no pasa nada".
- **`itemSqlParameterSourceProvider` explícito en vez de `.beanMapped()`**, porque `beanMapped`
  busca getters al estilo JavaBean (`getSku()`) y un `record` expone `sku()`. Escribir el mapeo a
  mano son cuatro líneas y deja a la vista qué columna recibe qué.
- **`new StepBuilder(nombre, jobRepository)` y `new JobBuilder(...)` son la API de Spring Batch 5**:
  las viejas `StepBuilderFactory` y `JobBuilderFactory` se eliminaron en la 5.0, así que cualquier
  ejemplo anterior a 2023 **no compila** contra este proyecto. Es un buen filtro de entrevista y la
  razón de que el `JobRepository` se pase al builder en vez de heredarse.
- **Quién ejecuta qué, y en qué hilo:** todo el job corre en **un solo hilo**, el que lo lanzó. El
  `SimpleJobLauncher` por defecto es síncrono, el step no tiene `TaskExecutor`, y por lo tanto no
  hay ningún paralelismo que discutir hoy
  ([`22` §9](22-spring-batch.md#9--flujo-y-paralelismo-cuatro-formas-y-lo-que-cada-una-cobra)).

Y las propiedades. En el bloque del perfil `local`, y un perfil `batch` nuevo:

```yaml
inv:
  batch:
    input-file: file:data/movements-2026-09-17.csv

spring:
  batch:
    jdbc:
      initialize-schema: never      # el esquema lo pone Flyway, no Boot
    job:
      enabled: false                # esto es una API, no un contenedor de una sola corrida

---
spring:
  config:
    activate:
      on-profile: batch
  main:
    web-application-type: none      # arranca, corre el job y muere
  batch:
    job:
      enabled: true
```

- **`initialize-schema: never`** apaga al inicializador de Boot. Con Flyway creando las tablas y
  Boot intentando crearlas también, el arranque falla con un error de objeto duplicado que no
  menciona a ninguno de los dos por su nombre.
- **`spring.batch.job.enabled: false` en `local` es lo que impide la sorpresa de
  [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)**: con un solo bean `Job` en el
  contexto, el `JobLauncherApplicationRunner` lo ejecuta **al arrancar**. Perfecto para un
  contenedor que arranca, corre y muere; una sorpresa muy cara en una API que además sirve tráfico.
  Tu `inv-api` en marcha no va a lanzar nada.
- **El perfil `batch` invierte esas dos decisiones y añade una tercera**:
  `web-application-type: none` arranca el contexto **sin servidor**, así que no pelea por el 8080 ni
  por el 8081 con la instancia que tienes corriendo. Es el modelo de ejecución de un job de verdad y
  de paso te ahorra parar la API para probarlo.
- **`file:data/...` lleva prefijo de `Resource`** y no es opcional: sin él, Spring resuelve la ruta
  como classpath y obtienes un `FileNotFoundException` al abrir el step, no al arrancar.

### La primera corrida, y las tablas que aparecen

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=local,batch \
  --inv.batch.input-file=file:data/movements-2026-09-17.csv \
  business.date=2026-09-17
echo "salida del proceso: $?"
```

- **`--spring.profiles.active=local,batch`** activa los dos: el `local` trae la base y la seguridad
  de siempre, el `batch` convierte el arranque en una corrida. Los dos guiones son obligatorios
  aquí, porque es una propiedad del `Environment`.
- **`business.date=2026-09-17` va SIN los dos guiones**, y esa diferencia de dos caracteres es un
  error que cuesta una ventana nocturna: **lo que lleva `--` es una propiedad y el job no la ve**;
  lo que va suelto lo recoge el `JobLauncherApplicationRunner` como `JobParameter`
  ([`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)). Si lo escribes con `--`, el
  job arranca **sin parámetros**, y el `#{jobParameters['business.date']}` del processor revienta.
- **Desde la línea de comandos todos los parámetros llegan como `String`** y todos son
  identificadores. Para tiparlos o marcarlos como no identificadores existe la sintaxis
  `nombre=valor,tipo,identifying` —`input.file=data/x.csv,java.lang.String,false`—; aquí el fichero
  viaja como propiedad y no como parámetro, y por eso el `LocalDate.parse` está en el processor.
- **`$?` vale `0` cuando el job termina en `COMPLETED`** y distinto de cero si falla, porque Boot
  traduce el `ExitStatus` del job al código de salida del proceso. Es lo que mira el planificador
  de la noche, y es la razón por la que un job no debe tragarse sus excepciones.

Ahora las tablas. Esta es la parte que hay que saber hacer de memoria en una entrevista:

```bash
PSQL="docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -x -c"
$PSQL "SELECT job_instance_id, job_name FROM batch_job_instance"
$PSQL "SELECT job_execution_id, job_instance_id, status, exit_code FROM batch_job_execution"
$PSQL "SELECT parameter_name, parameter_value, identifying FROM batch_job_execution_params"
$PSQL "SELECT step_name, status, read_count, filter_count, write_count, commit_count, rollback_count
       FROM batch_step_execution"
$PSQL "SELECT count(*) FROM inventory_reconciliation WHERE business_date = '2026-09-17'"
```

- **`-x` pone `psql` en salida expandida**, una columna por línea. Con catorce columnas y un
  terminal de ochenta caracteres es la diferencia entre leer y adivinar.
- **Los nombres de tabla van en minúsculas** aunque el script los creara en mayúsculas: Postgres
  pliega a minúsculas todo identificador sin comillas, y eso incluye lo que creó Flyway.

Lo que tienes que ver, con los valores que la aritmética predice para diez mil ítems y chunks de
quinientos —una sola instancia, una sola ejecución, un solo step:

```text
batch_job_instance      →  1 fila,  job_name = inventory-reconciliation-job
batch_job_execution     →  1 fila,  status = COMPLETED,  exit_code = COMPLETED
batch_job_execution_params → 1 fila, business.date / 2026-09-17 / identifying = Y
batch_step_execution    →  1 fila,  step_name = reconcile-step,  status = COMPLETED
                                    read_count = 10000   filter_count = 0
                                    write_count = 10000  commit_count = 21  rollback_count = 0
inventory_reconciliation → 10000 filas
```

- **`commit_count = 21` y no 20**, y ese "uno de más" desconcierta la primera vez: son los veinte
  chunks completos más el commit final con el que el step cierra cuando el reader devuelve `null`.
  Si tu número es 20 o 21 según la versión, lo que importa es la relación, no la cifra.
- **`identifying = Y` es la columna que decide la identidad de la instancia.** `business.date` está
  marcado como identificador, así que **`JobInstance` = `inventory-reconciliation-job` +
  `business.date=2026-09-17`**, que es la ecuación de
  [`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces).
  Todo lo de la sección siguiente cuelga de esta fila.
- **`read_count == write_count` porque nada se filtró ni se descartó.** En cuanto uno de los dos
  contadores se separe del otro, la pregunta es cuál de los tres motivos fue: filtrado, descartado o
  perdido.
- **Y el `SELECT count(*)` es el criterio de verdad de `L04` aplicado a Batch**: el estado del job
  lo dice `BATCH_STEP_EXECUTION`, pero lo que quedó escrito lo dice tu tabla. Los dos números tienen
  que coincidir, y cuando no coinciden es cuando empieza lo interesante.

⏱️ **Costo en runtime del `JobRepository`.** Cada commit de chunk son varios `UPDATE` de metadatos
además de tus `INSERT`: con `chunk(500)` son veintiún ciclos de contabilidad para diez mil filas;
con `chunk(1)` serían **diez mil transacciones y diez mil `UPDATE` de `BATCH_STEP_EXECUTION`**, y la
contabilidad pasaría a costar más que el trabajo. Es el argumento de `22` §8 con números delante.

---

## 10. 🩺 Caído a la mitad y reanudado: las tablas antes y después

Diez mil líneas limpias no enseñan nada que no supieras. Lo que hay que poder contar en una
entrevista es lo otro: **se cayó a las 02:41 con la mitad hecha, y ahora qué**. Vamos a provocarlo.

**Predice antes de ejecutar.** El fichero grande tiene sesenta mil ítems y la línea 30 001 está
envenenada. Con chunks de quinientos y sin `faultTolerant()`: ¿cuántas filas van a quedar en
`inventory_reconciliation` cuando el proceso muera, y qué va a decir `read_count`?

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=local,batch \
  --inv.batch.input-file=file:data/movements-2026-09-18.csv \
  business.date=2026-09-18
echo "salida del proceso: $?"
```

El proceso muere con código distinto de cero. En el log aparece la excepción que lanzó tu processor
—`java.lang.IllegalArgumentException: delta fuera de rango en la línea 30001: 999999`, que es el
mensaje que escribiste tú y por eso puede ir literal— envuelta en la traza que Spring Batch imprime
al marcar el step como `FAILED`. **El resto de esa traza no va aquí porque no puedo garantizarla
palabra por palabra**: son frames de `ChunkOrientedTasklet`, del `RepeatTemplate` y del
`TaskletStep`, y lo que hay que reconocer es la primera línea y el hecho de que **la excepción de
tu código llega arriba sin que nadie la traduzca**.

Ahora la foto de después:

```bash
$PSQL "SELECT job_execution_id, job_instance_id, status, exit_code FROM batch_job_execution
       ORDER BY job_execution_id"
$PSQL "SELECT step_execution_id, step_name, status, read_count, write_count, commit_count, rollback_count
       FROM batch_step_execution ORDER BY step_execution_id"
$PSQL "SELECT count(*) FROM inventory_reconciliation WHERE business_date = '2026-09-18'"
$PSQL "SELECT short_context FROM batch_step_execution_context
       WHERE step_execution_id = (SELECT max(step_execution_id) FROM batch_step_execution)"
```

Esto es lo que predice la aritmética, y es lo que tienes que ver —el `exit_code` y el
`exit_message` traen el nombre de la excepción, y los identificadores dependen de cuántas veces
hayas corrido el job antes:

```text
batch_job_execution      →  2 filas:  la de 2026-09-17 COMPLETED
                                      la de 2026-09-18 FAILED
batch_step_execution     →  la fila de 2026-09-18:  status = FAILED
                                      read_count = 30000    write_count = 30000
                                      commit_count = 60     rollback_count = 1
inventory_reconciliation →  30000 filas con business_date = 2026-09-18
batch_step_execution_context → {"movementReader.read.count": 30000, ...}
```

- **`write_count = 30000` y no 30 500**, y ahí está la mitad de la lección: el chunk 61 leyó sus
  quinientos ítems, el processor explotó en el primero, **la transacción del chunk hizo rollback
  entera** y con ella se fueron las escrituras y los contadores. Lo confirmado antes no se movió:
  sesenta chunks, sesenta commits, treinta mil filas.
- **`rollback_count = 1`** es el chunk que se perdió. Uno, no sesenta y uno: los anteriores estaban
  confirmados en transacciones propias, que es todo el argumento de
  [`22` §8](22-spring-batch.md#8-️-el-writer-falla-a-la-mitad-del-chunk-el-puente-con-16) y la razón
  de que el tamaño del chunk sea *cuánto trabajo estás dispuesto a repetir*.
- **`read_count = 30000` aunque el reader llegó a leer hasta el 30 500.** Los contadores viven en la
  misma transacción que los datos, así que retrocedieron con ellos. Es exactamente lo que quieres:
  **el `JobRepository` nunca dice haber leído algo que no quedó escrito**.
- **`short_context` es la respuesta literal a "¿por dónde iba?"**, y es la fila que hay que saber
  nombrar en una entrevista. Es un JSON con el estado que cada `ItemStream` guardó, y la clave
  `movementReader.read.count` lleva el nombre que le pusiste al reader con `.name(...)` en la
  sección 9. **Si no le hubieras puesto nombre, esa clave no existiría y no habría reanudación
  posible** — se ve aquí, en una fila de una tabla, y no en un párrafo de la reference.
- **El `SELECT count(*)` cierra el círculo:** treinta mil filas escritas, treinta mil contadas.
  Cuando esos dos números no coinciden es cuando toca sospechar del writer.

### Arreglar el dato y reanudar

En producción el paso intermedio es el que se lleva las horas: alguien tiene que decidir qué se hace
con la línea mala. Aquí la corriges y ya:

```bash
sed -i.bak '30002s/;999999;/;5;/' data/movements-2026-09-18.csv
sed -n '30002p' data/movements-2026-09-18.csv
```

```text
30001;ABC-000002;5;reconciliacion
```

- **Línea 30 002 del fichero para el ítem 30 001**, otra vez el desfase de la cabecera. Es el mismo
  "más uno" de `wc -l` y es la causa más común de corregir la línea equivocada bajo presión.
- **`sed -i.bak` deja una copia** por si la corrección fue peor que el problema, que en una ventana
  nocturna es cortesía elemental hacia tu yo de dentro de diez minutos.

Y ahora la reanudación, que es **exactamente el mismo comando de antes**:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=local,batch \
  --inv.batch.input-file=file:data/movements-2026-09-18.csv \
  business.date=2026-09-18
echo "salida del proceso: $?"
```

- **No hay ningún comando de reanudación, y ese es el punto.** Relanzar la **misma instancia**
  —mismo job, mismos parámetros identificadores— cuya última ejecución falló **es** reanudar. Spring
  Batch crea un `JobExecution` nuevo sobre la `JobInstance` existente, salta los steps que quedaron
  en `COMPLETED` y le pasa al step caído el `ExecutionContext` que guardó.
- **Si en vez de esto hubieras añadido un `run.id` con la hora** para "poder relanzar cuando
  quiera", cada intento sería una instancia nueva: el job volvería a empezar por la línea 1, volvería
  a insertar treinta mil filas y **el `ON CONFLICT` sería lo único que te salvaría de duplicarlas**.
  Es el antipatrón de [`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces),
  y aquí se ve lo que cuesta.

La foto de después, con los mismos cuatro `SELECT`:

```text
batch_job_instance       →  sigue habiendo 2 filas: una por fecha contable. NO se creó ninguna
batch_job_execution      →  3 filas: 2026-09-17 COMPLETED
                                     2026-09-18 FAILED     (el primer intento)
                                     2026-09-18 COMPLETED  (el segundo, misma job_instance_id)
batch_step_execution     →  la fila nueva:  status = COMPLETED
                                     read_count = 30000    write_count = 30000
                                     commit_count = 61     rollback_count = 0
inventory_reconciliation →  60000 filas con business_date = 2026-09-18
```

- **La fila de `batch_job_instance` no se duplicó, y es la evidencia central del lab.** Dos
  `JobExecution` colgando de una `JobInstance`: eso es un reintento de la misma corrida lógica, y no
  dos corridas. Compáralo con la columna `job_instance_id` de las tres ejecuciones y tendrás la
  distinción de [`22` §2](22-spring-batch.md#2--el-modelo-seis-sustantivos-y-ninguno-sobra) delante
  de los ojos.
- **`read_count = 30000` en la ejecución nueva, no 60 000.** El step no volvió a leer el fichero
  desde el principio: el `FlatFileItemReader` recuperó `movementReader.read.count = 30000` del
  `ExecutionContext` al abrirse y **se saltó esas treinta mil líneas**. Los contadores de un
  `StepExecution` son de **ese intento**, nunca acumulados — sumar los dos da los sesenta mil.
- **`inventory_reconciliation` tiene ahora exactamente 60 000 filas**, ni una más. El chunk 61 se
  reprocesó entero, sus quinientos ítems se volvieron a leer y a escribir, y no hubo duplicados por
  una razón sencilla: el rollback del primer intento se había llevado también sus escrituras. **El
  `ON CONFLICT` no llegó a hacer nada aquí, y aun así tiene que estar**: protege el caso en que
  datos y metadatos no viajen en la misma transacción —un writer que llame a un servicio externo, un
  `faultTolerant()` reprocesando ítem a ítem, o el proceso muerto a `kill -9` entre el commit de tu
  escritura y el del `JobRepository`—. Reanudable no es idempotente; la idempotencia la pones tú.
- **`commit_count = 61`** son los sesenta chunks restantes más el cierre, la misma cuenta de la
  sección 9 sobre un fichero más corto.

### Lanzarlo una tercera vez

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=local,batch \
  --inv.batch.input-file=file:data/movements-2026-09-18.csv \
  business.date=2026-09-18
echo "salida del proceso: $?"
$PSQL "SELECT count(*) FROM inventory_reconciliation WHERE business_date = '2026-09-18'"
```

El proceso vuelve a morir con código distinto de cero, y la excepción es
`org.springframework.batch.core.repository.JobInstanceAlreadyCompleteException` —el nombre de la
clase es lo que hay que reconocer; su mensaje explica que esa instancia ya terminó y que los
parámetros tienen que ser distintos, y va descrito en vez de copiado porque no puedo garantizar la
cadena exacta—. El `count(*)` sigue diciendo 60 000.

- **Ese fallo es la funcionalidad, no un bug.** Es lo que convierte "correr el job dos veces por
  error" en un rechazo en lugar de un doble cargo, y sale de la ecuación de la identidad: el job ya
  terminó con éxito para `business.date=2026-09-18`.
- **Cambiar la fecha crea otra instancia** y el job vuelve a correr entero, que es lo correcto: otra
  fecha contable es otro trabajo.
- **Y si el proceso hubiera muerto de un `kill -9`** en vez de fallar limpiamente, la fila de
  `batch_job_execution` se habría quedado en `STARTED` para siempre —nadie pudo escribir el
  `FAILED`— y el relanzado daría `JobExecutionAlreadyRunningException`. **Ese es el caso que de
  verdad duele a las tres de la mañana**, y su salida no es un comando de Spring sino una decisión
  de operación: comprobar que el proceso está muerto de verdad y marcar la ejecución como abandonada.
  Reprodúcelo en el ejercicio 16 antes de que te pase en serio.

> **🧠 Lo que hay que poder decir en voz alta.** *"Se cayó en el chunk 61 de 120. Lo confirmado
> —treinta mil filas— estaba escrito y contado; el chunk en vuelo se revirtió entero. Relancé con
> los mismos parámetros identificadores, el reader retomó desde la línea 30 000 que había guardado
> en su `ExecutionContext`, y la segunda ejecución colgó de la misma `JobInstance`. Lo comprobé en
> `BATCH_STEP_EXECUTION` y contando filas en la tabla de destino."* Si puedes decir eso señalando
> dos `SELECT`, este lab cumplió.

---

## 11. 📋 Checklist de salida

- [ ] `docker compose -p inv-lab ps` lista seis contenedores: Postgres `(healthy)`, y WireMock, Redis, Prometheus, Grafana y Keycloak en `Up`.
- [ ] `curl -s http://localhost:8180/realms/inv/.well-known/openid-configuration | jq -r .issuer` devuelve `http://localhost:8180/realms/inv`.
- [ ] `get_token analyst@invlab.example analyst` devuelve un token de más de 500 caracteres, y `decode "$ANALYST" 2 | jq -r '.aud | join(",")'` incluye `inv-api`.
- [ ] Un `GET` a `/api/items/ABC-000123/valuation` responde `401` sin token, `200` con el del analista y `403` con el del invitado.
- [ ] Cada `401` y cada `403` de `/api/**` deja una línea `WARN` en `app.log` con el `requestId`, el método, la URI y —en el 403— el principal y sus authorities.
- [ ] `grep 'principal=' app.log | tail -1` muestra `analyst@invlab.example` o `guest@invlab.example`, nunca un UUID: el converter está activo.
- [ ] `curl 'localhost:8080/api/reports/valuations?sku=ABC-000123'` con el token del invitado responde `403`, no `200`.
- [ ] Tras un `FLUSHALL` de Redis y un `POST` con token, `grep 'recalentando' app.log | tail -1` dice `authentication=analyst@invlab.example` y `grep -c AuthenticationCredentialsNotFoundException app.log` devuelve `0`.
- [ ] `/actuator/env` responde `401` sin token, `403` con el del analista y `200` con el de `ops`; `/actuator/health` y `/actuator/prometheus` siguen en `200`.
- [ ] `curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'` sigue devolviendo `1`.
- [ ] `psql ... -c '\dt'` lista las seis tablas `batch_*` más `inventory_reconciliation`, y `spring.batch.jdbc.initialize-schema` vale `never`.
- [ ] `SELECT count(*) FROM batch_job_instance` devuelve `2` y `SELECT count(*) FROM batch_job_execution` devuelve `3`: dos fechas contables, tres intentos.
- [ ] Las dos `batch_step_execution` de `2026-09-18` suman `read_count = 60000`, y `SELECT count(*) FROM inventory_reconciliation WHERE business_date = '2026-09-18'` devuelve exactamente `60000`.
- [ ] `SELECT short_context FROM batch_step_execution_context` contiene la clave `movementReader.read.count`.
- [ ] Relanzar el job con `business.date=2026-09-18` falla con `JobInstanceAlreadyCompleteException` y no escribe ninguna fila nueva.
- [ ] `./mvnw -q clean package` pasa en verde **sin `-DskipTests`**, con los tests de `L03` adaptados al post-processor `jwt()`.
- [ ] `curl -s localhost:8081/actuator/loggers/org.springframework.security -H "Authorization: Bearer $OPS" | jq -r .configuredLevel` devuelve `null`: no dejaste el `DEBUG` clavado.

---

## 🧠 Preguntas rápidas

1. Una petición sin token y otra con un token válido pero sin la authority acaban las dos en una
   `AccessDeniedException` dentro del mismo filtro. ¿Quién decide que una salga `401` y la otra
   `403`, y con qué criterio exacto?
2. Tu `@RestControllerAdvice` devuelve `ProblemDetail` para todo y los `401` de `/api/**` llegan con
   el cuerpo vacío. Explica por qué y nombra los dos beans que lo arreglan.
3. El log dice `authorities=[SCOPE_openid, SCOPE_inventory.read, ROLE_OFFLINE_ACCESS]` y la regla
   pide `hasRole("ANALYST")`. Escribe en una línea qué falta y en qué fichero.
4. ¿Por qué `spring.security.oauth2.resourceserver.jwt.authorities-claim-name` **no** resuelve el
   mapeo de los roles de Keycloak, y qué sí lo resuelve?
5. Activaste `jwt.audiences=inv-api` y **todos** los tokens pasaron a dar `401`. ¿Qué falta, y en
   cuál de los dos lados —Keycloak o `inv-api`— se arregla?
6. `/api/reports/valuations` devuelve `200` a un usuario al que `/api/items/{sku}/valuation` le
   devuelve `403`, y las dos rutas llaman al mismo método anotado. ¿Qué pasó, y por qué no aparece
   ninguna excepción en el log?
7. Un método `@Async` falla con `AuthenticationCredentialsNotFoundException` y otro, en el mismo
   pool, con `AccessDeniedException`. ¿Qué distingue los dos casos y qué te dice cada uno sobre
   dónde está el problema?
8. El `MdcTaskDecorator` propagó el `requestId` al hilo del pool y aun así el `SecurityContext` no
   llegó. Explica por qué copiar el MDC no bastaba y qué decora `DelegatingSecurityContextAsyncTaskExecutor`.
9. ¿Por qué `EndpointRequest.toAnyEndpoint()` y no un `requestMatchers("/actuator/**")`? Da la razón
   técnica, no la estética.
10. Cerraste Actuator con una cadena propia y el tablero de Grafana se quedó vacío. ¿Qué endpoint lo
    causó, qué métrica te lo dice en un comando, y cuáles son las tres salidas posibles?
11. "Si el job falla, se vuelve a correr desde el principio": corrige la afirmación con precisión y
    di qué fila de qué tabla contiene la respuesta a "¿por dónde iba?".
12. Tu step falló procesando el ítem 30 001 con chunks de 500. Di cuántas filas quedaron escritas,
    cuánto vale `read_count`, cuánto `rollback_count`, y por qué esos tres números tienen que ser
    coherentes entre sí.
13. Reanudaste el job y `read_count` de la ejecución nueva vale 30 000, no 60 000. ¿Qué significa ese
    número y qué línea de la configuración del reader es la que hace posible el reanudado?
14. El job terminó bien y alguien lo relanza con los mismos parámetros. ¿Qué excepción recibe, y en
    qué se convertiría ese rechazo si el equipo añadiera un parámetro `run.id` con la hora?
15. Tu writer inserta con `ON CONFLICT DO NOTHING` y el chunk que falló hizo rollback limpio, así
    que no había nada que duplicar. Nombra entonces los casos en los que esa cláusula sí te salva.

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–5)

#### 🟢 Ejercicio 1 — un rol más, y su regla

Añade al realm un rol `auditor` y un usuario `auditor@invlab.example` que solo lo tenga a él; vuelve
a levantar Keycloak con `--profile sec down` y `up -d` —desde la raíz del repositorio, que es
donde está el `docker-compose.yml`— para que reimporte. Haz que `auditor` pueda
hacer `GET /api/reports/**` y no `POST /api/items/**`, y comprueba los cuatro cruces de usuario y
método con `curl -w '%{http_code}'`.
**Objetivo:** ver que el realm es un fichero versionado y, sobre todo, descubrir que **no basta con
tocar la regla de URL**: el informe está protegido también por el `@PreAuthorize` de la sección 6, y
hasta que no lo mires vas a tener un `403` que la cadena no explica.

#### 🟢 Ejercicio 2 — el token que caduca

Baja `accessTokenLifespan` a `60` en el realm, reimporta, pide un token, espera setenta segundos y
repite la petición. Guarda la respuesta con `curl -i` y compara la cabecera `WWW-Authenticate` con
la de una petición sin token.
**Pregunta:** ¿qué campos aparecen en la cabecera del token caducado que no estaban en la del token
ausente, y por qué esa diferencia le importa al client?

#### 🟢 Ejercicio 3 — la audiencia que no estaba

Quita el `oidc-audience-mapper` del realm, reimporta, pide un token nuevo y repite un `GET` que hoy
funciona. Después decodifica el token y mira su `aud`.
**Objetivo:** reconocer de un vistazo el `401` que produce un token perfectamente firmado cuyo `aud`
no te incluye, que es el primer muro de toda integración con Keycloak.

#### 🟢 Ejercicio 4 — leer el token de `ops`

Decodifica el payload del token de `ops@invlab.example` y compáralo con el del analista: lista qué
claims cambian y cuáles son idénticos. Comprueba con `jq` que `realm_access.roles` contiene `ops` y
no `analyst`.
**Objetivo:** distinguir de memoria qué parte del token describe a la persona, qué parte describe al
client y qué parte la pone el IdP para todo el mundo.

#### 🟢 Ejercicio 5 — otra fecha contable

Lanza el job con `business.date=2026-09-19` sobre el fichero limpio de diez mil líneas y cuenta las
filas de `batch_job_instance` antes y después.
**Pregunta:** ¿por qué esta corrida sí empieza desde la línea 1 si la del 18 se reanudó desde la
30 000, con el mismo job y el mismo reader?

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (6–10)

#### 🟡 Ejercicio 6 — lo que la self-invocation también se llevó

Vuelve a la versión rota del informe —el fan-out dentro de `InventoryValuationService`— y pide un
informe de cinco SKU con el token del analista, con la caché vacía y mirando el contador
`inventory.repository.calls` de `L06` antes y después.
**Objetivo:** comprobar que la self-invocation no solo se saltó `@PreAuthorize`, sino también
`@Cacheable`, y poder explicar por qué es el mismo mecanismo y no dos bugs.

#### 🟡 Ejercicio 7 — `@PostAuthorize` y por qué incomoda

Sustituye el `@PreAuthorize` de `valuation(...)` por un `@PostAuthorize` que exija que el resultado
tenga una valoración por debajo de un umbral, y observa el tiempo de respuesta y el contador del
repositorio en una llamada denegada.
**Pregunta:** ¿qué trabajo se hizo antes de denegar, y en qué tipo de método convertiría eso una
comprobación de seguridad en un problema de verdad?

#### 🟡 Ejercicio 8 — la perilla del chunk

Corre el job del fichero grande con `chunk(50)` y con `chunk(5000)` sobre dos fechas contables
distintas, y anota `commit_count`, la duración del proceso y el `rollback_count` cuando provocas el
mismo fallo en cada caso.
**Objetivo:** poder defender un tamaño de chunk con dos números —trabajo repetido y coste de
contabilidad— en vez de con "mil porque sí".

#### 🟡 Ejercicio 9 — la evidencia también en Actuator

Extrae `LoggingAuthenticationEntryPoint` y `LoggingAccessDeniedHandler` a beans e inyéctalos también
en `actuatorChain`. Comprueba que un `403` en `/actuator/env` deja ahora la misma línea `WARN` que
uno en `/api/**`.
**Objetivo:** ver que una cadena no hereda nada de otra, y que "está configurado" solo vale para la
cadena donde lo escribiste.

#### 🟡 Ejercicio 10 — `hasRole` contra `hasAuthority`

Cambia `hasRole("ANALYST")` por `hasAuthority("ANALYST")` sin tocar el converter, repite el `POST`,
y prueba después `hasAuthority("ROLE_ANALYST")` y `hasAuthority("ROLE_analyst")`. Por último quita el
`toUpperCase(Locale.ROOT)` del converter y vuelve a pasar las cuatro.
**Pregunta:** ¿cuáles de las cuatro formas funcionan con el converter puesto, cuáles sin él, y qué
dos transformaciones distintas —no una— tiene que hacer el converter para que `hasRole("ANALYST")`
sea cierto?

### 🟠 Difícil — combinar, diagnosticar o decidir  (11–14)

#### 🟠 Ejercicio 11 — un test que prueba el converter, no la regla

Escribe un test de `MockMvc` que use `jwt().jwt(j -> j.claim("realm_access", Map.of("roles",
List.of("analyst"))))` **sin** pasar `authorities`, de forma que el test falle si alguien borra el
`JwtAuthenticationConverter`. Comprueba que falla borrándolo de verdad.
**Objetivo:** distinguir un test que prueba tu regla de autorización de uno que prueba tu mapeo de
claims, y saber cuál de los dos te habría ahorrado la sección 5.

#### 🟠 Ejercicio 12 — el job en el tablero

Expón las métricas `spring.batch.job`, `spring.batch.step` y `spring.batch.item.read` en
`/actuator/prometheus` —recuerda que el job corre en **otra** JVM sin servidor web— y añade al
tablero de `L07` un panel con la duración de la última ejecución.
**Pregunta:** ¿qué tienes que cambiar en el perfil `batch` para que Prometheus pueda raspar un
proceso que vive treinta segundos, y por qué eso convierte el modelo *pull* en un problema?

#### 🟠 Ejercicio 13 — el JWK Set en la memoria

Con la aplicación arriba y tokens funcionando, para Keycloak con
`docker compose -p inv-lab --profile sec stop`. Repite una petición con un token que ya usaste y
otra con un token pedido justo antes de parar el IdP; después reinicia Keycloak, pide un token nuevo
y repite.
**Objetivo:** explicar con evidencia por qué bajar el IdP no invalida los tokens de golpe, qué
depende de la caché del JWK Set y en qué momento exacto tu servicio deja de poder validar.

#### 🟠 Ejercicio 14 — el ítem que se filtra

Genera un fichero donde una de cada diez líneas tenga `delta` cero, córrelo y mira `read_count`,
`filter_count` y `write_count`. Después cuenta las filas de `inventory_reconciliation`.
**Pregunta:** ¿cuál de los tres contadores coincide con el número de filas, y por qué un
`filter_count` alto puede ser una alerta de negocio aunque el job termine en `COMPLETED`?

### 🔴 Muy difícil — abierto o adversarial  (15–16)

#### 🔴 Ejercicio 15 — descartar sin perder

Genera un fichero con **cuarenta** líneas corruptas repartidas y haz el step `faultTolerant()` con
`skip(IllegalArgumentException.class)` y `skipLimit(50)`, más un `SkipListener` que escriba cada
descarte en una tabla `inventory_reconciliation_rejected` que crearás con una migración. Después
sube las corruptas a sesenta y observa qué pasa.
**Objetivo:** demostrar con dos `SELECT` que un `skipLimit` sin listener es pérdida de datos con
permiso escrito, y saber decir cuál es el descarte exacto que hace fallar el step.

#### 🔴 Ejercicio 16 — el job que se quedó `STARTED`

Lanza el job del fichero grande y mátalo con `kill -9` a mitad de camino. Mira el `status` de la
`batch_job_execution`, intenta relanzarlo con los mismos parámetros y documenta la excepción.
Después investiga en la reference qué ofrece el `JobOperator` para esta situación y decide —y
justifica por escrito— qué harías tú a las tres de la mañana antes de tocar nada.
**Pregunta:** ¿por qué este caso es peor que el `FAILED` limpio de la sección 10, y qué garantía de
Spring Batch deja de valer aquí?

### 🔥 Opcionales y ampliaciones

- **`inv-api` como OAuth2 client.** Declara un cliente `inv-api-client` confidencial con
  `serviceAccountsEnabled`, configura `spring.security.oauth2.client.registration.*` con
  `client_credentials` y monta el `OAuth2ClientHttpRequestInterceptor` de
  [`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio)
  sobre el `RestClient` del `SupplierGateway`. Comprueba en el journal de WireMock que la cabecera
  `Authorization` sale, y decodifica ese token: no tiene `sub` de humano.
- **El `requestId` como contexto de verdad.** Registra un `ThreadLocalAccessor` en el
  `ContextRegistry` de Micrometer para el `requestId` y borra el `MdcTaskDecorator`: si lo haces
  bien, `ContextPropagatingTaskDecorator` lo propaga solo y el `CompositeTaskDecorator` se queda con
  dos elementos en vez de tres.
- **Token opaco con introspección.** Cambia el realm para que emita tokens opacos, configura
  `spring.security.oauth2.resourceserver.opaquetoken.introspection-uri` y mide con
  `/actuator/metrics` cuánto cuesta una llamada al IdP por petición frente a verificar una firma.

### 💀 Boss fight — lanzar el job desde la API, con identidad y con rastro

Hoy el job se lanza desde la línea de comandos y la seguridad vive en otro sitio. Júntalo todo en un
solo encargo, que cruza las cinco secciones del lab:

Escribe un endpoint `POST /api/admin/jobs/reconciliation` que reciba la fecha contable en el cuerpo
y lance `inventory-reconciliation-job`, con estas condiciones, todas verificables:

1. La ruta está protegida por una regla de URL **y** por un `@PreAuthorize` en el servicio, las dos
   exigiendo `ROLE_OPS`; un token de `analyst` recibe `403` con su línea `WARN` y sus authorities.
2. El lanzamiento es **asíncrono** sobre `inventoryExecutor`, y el endpoint devuelve `202 Accepted`
   con el `jobExecutionId` en el cuerpo, no el resultado del job.
3. En el hilo del pool, el `SecurityContext` y el `traceId` siguen presentes: el log del job lleva
   el `requestId`, el `traceId` de `L07` y el `preferred_username` de quien lo lanzó.
4. Lanzarlo dos veces con la misma fecha no duplica nada: el segundo intento responde `409 Conflict`
   traduciendo la excepción de Spring Batch en un `ProblemDetail`, y `batch_job_instance` no crece.
5. El `jobExecutionId` que devolviste permite consultar el estado con un `SELECT`, y una fecha ya
   completada se distingue de una en curso sin mirar el log.

**Se entrega** el controller, el servicio, las reglas de seguridad y un guion `bash` que demuestre
los cinco puntos con `curl` y `psql`, sin abrir el IDE.
**Objetivo:** que las dos mitades del lab dejen de ser dos temas. Un job de banca lo lanza una
persona con nombre y apellidos, y la pregunta "¿quién relanzó la conciliación del día 18?" tiene que
tener respuesta en una fila, no en una conversación.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps` lista seis contenedores. Un `GET` sin token devuelve `401`, el mismo
`GET` con el token del invitado devuelve `403`, y **las dos cosas dejan una línea en `app.log` que
dice cuál fue y por qué** — con el `requestId` delante y, en el 403, con la lista exacta de
authorities que llegaron. `/actuator/env` solo se abre con el token de `ops` mientras Prometheus
sigue raspando. Y en Postgres hay dos `batch_job_instance`, tres `batch_job_execution`, y sesenta
mil filas exactas en `inventory_reconciliation` para el 18 de septiembre, escritas en dos intentos
de los cuales el segundo empezó en la línea 30 000.

Y lo que de verdad cuenta, que son las cuatro cosas que hoy pasaron de creencia a hecho comprobado.
**La primera:** un 401 y un 403 no se distinguen por el código, se distinguen por lo que escribes al
producirlos — y sin esos dos beans, el 403 más caro de tu carrera va a llegar con el cuerpo vacío y
el log limpio. **La segunda:** el token puede ser perfecto y la autorización fallar igual, porque
entre el claim y la authority hay un converter que alguien tiene que escribir, y el default no sabe
bajar un nivel. **La tercera:** la self-invocation, que en `L04` costaba un rollback y en `L06` una
entrada de caché, aquí cuesta una comprobación de permisos que nunca ocurrió y que responde `200` —
es la misma trampa con la consecuencia más cara de las tres. **La cuarta:** un proceso que escribe
su propio estado se reanuda y uno que no, no; y eso no es una propiedad del framework, es una tabla
con una fila donde dice `movementReader.read.count`.

Si dudas de alguna de las cuatro, el criterio de verdad de este lab no es que la aplicación
responda: son los dos pares de comandos que lo comprueban. Para la seguridad, `curl -w '%{http_code}'`
junto a `grep WARN app.log`. Para Batch, `SELECT ... FROM batch_step_execution` junto a
`SELECT count(*)` sobre la tabla de destino. Un sistema que rechaza sin decir por qué y un job que se
cae sin decir por dónde iba son el mismo problema, y hoy los dos tienen respuesta en una fila.

Los perfiles `db`, `ext`, `cache`, `obs` y `sec` se quedan arriba, y con ellos el laboratorio está
completo: es todo lo que la serie va a levantar. El lab que cierra la serie empaqueta `inv-api` en
una imagen, lo mete dentro del propio Compose, demuestra el `graceful shutdown` con una petición en
vuelo y **destruye todo esto de forma verificada**, con el boss fight final encima. Ese lab todavía
no está escrito, así que va sin enlace; hasta entonces, `docker compose -p inv-lab down` para lo que
levantaste sin borrar los volúmenes, y el `-v` que sí los borra espera ahí.

---

## 📚 Referencias oficiales

- Spring Security 6.5 — Arquitectura: `FilterChainProxy`, `ExceptionTranslationFilter` y quién escribe el 401 o el 403: https://docs.spring.io/spring-security/reference/6.5/servlet/architecture.html
- Spring Security 6.5 — Configuración Java y múltiples `SecurityFilterChain` con `securityMatcher`: https://docs.spring.io/spring-security/reference/6.5/servlet/configuration/java.html
- Spring Security 6.5 — `authorizeHttpRequests`, `hasRole` y el prefijo `ROLE_`: https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/authorize-http-requests.html
- Spring Security 6.5 — Method security: `@PreAuthorize`, `@PostAuthorize` y el orden de los interceptores: https://docs.spring.io/spring-security/reference/6.5/servlet/authorization/method-security.html
- Spring Security 6.5 — Resource Server con JWT: validadores, `audiences` y `JwtAuthenticationConverter`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/jwt.html
- Spring Security 6.5 — Bearer tokens y la cabecera `WWW-Authenticate`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/bearer-tokens.html
- Spring Security 6.5 — Propagar el `SecurityContext` a otros hilos (`DelegatingSecurityContextAsyncTaskExecutor`): https://docs.spring.io/spring-security/reference/6.5/features/integrations/concurrency.html
- Spring Boot 3.5 — Autoconfiguración de Spring Security y del resource server: https://docs.spring.io/spring-boot/3.5/reference/web/spring-security.html
- Spring Boot 3.5 — Endpoints de Actuator y su aseguramiento: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Javadoc de `EndpointRequest` (`toAnyEndpoint`, `excluding`): https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/actuate/autoconfigure/security/servlet/EndpointRequest.html
- Spring Boot 3.5 — Aplicaciones batch: arranque, parámetros de línea de comandos y `@BatchDataSource`: https://docs.spring.io/spring-boot/3.5/how-to/batch.html
- Spring Boot 3.5 — Índice de propiedades (`spring.security.oauth2.*`, `spring.batch.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Batch 5.2 — El lenguaje de dominio: `JobInstance`, `JobExecution`, `ExecutionContext`: https://docs.spring.io/spring-batch/reference/5.2/domain.html
- Spring Batch 5.2 — Configurar un step chunk-oriented con los builders de la 5.x: https://docs.spring.io/spring-batch/reference/5.2/step/chunk-oriented-processing/configuring.html
- Spring Batch 5.2 — Reinicio de un step (`allowStartIfComplete`, `startLimit`) y qué se reanuda: https://docs.spring.io/spring-batch/reference/5.2/step/chunk-oriented-processing/restart.html
- Spring Batch 5.2 — Configurar y lanzar un `Job`, y los `JobParameters`: https://docs.spring.io/spring-batch/reference/5.2/job.html
- Spring Batch 5.2 — Lectores y escritores de ficheros planos (`FlatFileItemReader`, `LineMapper`): https://docs.spring.io/spring-batch/reference/5.2/readers-and-writers/flat-files.html
- Spring Batch 5.2 — Esquema de metadatos: las seis tablas y el flag `IDENTIFYING`: https://docs.spring.io/spring-batch/reference/5.2/schema-appendix.html
- Spring Batch 5.2 — Testing de jobs y steps (`JobLauncherTestUtils`): https://docs.spring.io/spring-batch/reference/5.2/testing.html

### Documentación de terceros

- Keycloak — importar y exportar realms (`--import-realm` y el formato del fichero): https://www.keycloak.org/server/importExport
- Keycloak — arrancar el servidor en un contenedor y el modo `start-dev`: https://www.keycloak.org/getting-started/getting-started-docker
- Keycloak — asegurar aplicaciones con OpenID Connect: https://www.keycloak.org/securing-apps/oidc-layers
- RFC 6750 — Bearer Token Usage: la cabecera `WWW-Authenticate` y sus códigos de error: https://www.rfc-editor.org/rfc/rfc6750.html
- RFC 7519 — JSON Web Token: los claims `iss`, `aud`, `exp` y `sub`: https://www.rfc-editor.org/rfc/rfc7519.html
