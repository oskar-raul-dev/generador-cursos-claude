# L00 — La idea del laboratorio

> **Objetivo:** dejar claro qué se construye en la serie práctica, qué queda fuera, por
> qué, y cuál es el contrato de la máquina. Es el encuadre de `L01`–`L09`: se lee una vez
> y se consulta después.
> **Asume:** [`01`](01-spring-boot-y-el-ecosistema.md)–[`07`](07-configuracion-externalizada.md), o al menos [`06`](06-arranque-y-autoconfiguracion.md).
> **Costo:** **$0.00**. Todo corre en `localhost`.
> **Duración:** 30 minutos de lectura. No se ejecuta nada.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · tags de imagen verificados ese día.

**Salto rápido:** [Qué construyes](#1--qué-construyes) ·
[La doctrina de reparto](#2--la-doctrina-de-reparto) ·
[Catálogo de exclusiones](#3--el-catálogo-de-exclusiones-una-por-una) ·
[Requisitos](#4--requisitos-de-la-máquina) ·
[El `docker-compose.yml`](#6--el-docker-composeyml-de-la-serie) ·
[Nombres fijos](#7--nombres-fijos-de-la-serie) ·
[Orden de los labs](#8--el-orden-y-qué-deja-cada-lab) ·
[Limpieza](#9--cómo-se-limpia-todo) ·
[Preguntas rápidas](#-preguntas-rápidas)

---

## 1. 🧭 Qué construyes

Un solo servicio Spring Boot, **`inv-api`**, que crece lab a lab hasta convertirse en algo
que se parece bastante a un microservicio de banca: expone una API REST, persiste en
Postgres dentro de transacciones, consulta a un proveedor externo con timeouts y circuit
breaker, cachea en Redis, publica métricas y trazas, se protege con JWT y ejecuta un
proceso batch reiniciable.

El dominio es deliberadamente aburrido —movimientos de inventario— y cabe en tres clases.
**El dominio no es el tema. El framework sí.** Cada lab existe para que veas fallar un
mecanismo concreto y aprendas a reconocer su síntoma.

> **🧠 Modelo mental de la serie.** No estás construyendo una aplicación: estás montando
> un **banco de pruebas** donde romper cosas a propósito. Si terminas un lab sin haber
> visto ningún stack trace, te lo saltaste mal.

---

## 2. 🧱 La doctrina de reparto

Los cursos de nube de este repositorio tienen una regla de alcance económica: *en la nube
se practica solo lo que únicamente existe en la nube*, porque cada recurso factura. Aquí
no hay factura, así que la regla que ocupa su lugar es pedagógica:

> **Al laboratorio va lo que solo se entiende viéndolo fallar en runtime.**
> Lo que se entiende leyendo se queda en el capítulo.

Un tema entra en la serie si cumple al menos una de estas cuatro condiciones:

| Condición | Ejemplo del curso |
|---|---|
| El fallo es **silencioso** y solo se ve ejecutando | el `@Transactional` que no hace rollback (`L04`) |
| El síntoma está en un **log o un stack trace** que hay que aprender a leer | pool de Hikari agotado, `LazyInitializationException` (`L04`) |
| Depende de **infraestructura real** que un mock no reproduce | latencia del proveedor, TTL de Redis (`L05`, `L06`) |
| Es una **costura** entre tu código y el contenedor | orden de filtros, informe de condiciones (`L01`, `L03`) |

Y lo que no cumple ninguna se queda en el capítulo. La precedencia de propiedades de `07`
se explica con una tabla y se demuestra en `L02` en diez minutos; no hace falta un lab
entero. La diferencia entre `@Primary` y `@Qualifier` de `03` no necesita ejecutarse en
absoluto.

---

## 3. ⚖ El catálogo de exclusiones, una por una

Una exclusión sin justificación se lee como un hueco del temario. Estas son todas, con su
motivo y con dónde se practica en su lugar.

| Excluido | Por qué | Dónde sí |
|---|---|---|
| **Kafka y mensajería** | La parte difícil no es el `@KafkaListener`: son las garantías de entrega, el orden y la idempotencia, que son diseño | `repaso-entrevistas/arquitectura/01-bases/02-eventos/` |
| **Kubernetes** | Otro laboratorio entero. Aquí solo distrae del framework | `repaso-entrevistas/cloud/01-aws/`, `repaso-entrevistas/cloud/02-gcp/` |
| **Frontend** | Cero aporte a un perfil backend, y duplica el tiempo de cada lab | — |
| **Spring Cloud** (Config, Gateway, discovery) | Capa de plataforma, no de framework; envejece rápido y se pregunta poco | — |
| **R2DBC** | Se explica en `11` con su veredicto. Practicarlo exigiría un segundo modelo de datos para una tecnología que probablemente no vas a usar | capítulo `11` |
| **GraalVM native** más allá de una compilación | Un build native tarda minutos y enseña sobre la herramienta, no sobre Spring | 🔥 opcional de `L09` |
| **Un IdP real en la nube** | Keycloak local da exactamente el mismo aprendizaje: `issuer-uri`, JWKS, claims | [`L08`](l08-security-y-batch.md) con Keycloak |
| **Bases de datos en clúster** | Réplicas y sharding son diseño de datos, no de Spring | `repaso-entrevistas/arquitectura/01-bases/03-datos/` |
| **WebSocket y STOMP** | El fallo que enseña —suscripciones perdidas entre réplicas, afinidad, latidos contra el balanceador— exige dos instancias, un balanceador y un navegador, los tres fuera de la serie; el mecanismo se entiende leyendo | capítulo [`14`](14-tiempo-real-sse-y-websocket.md); `SseEmitter` sí se toca, en el 🔥 de [`L03`](l03-api-rest-filtros-y-errores.md) |

> **📝 La exclusión que más sorprende es Kafka**, porque en banca está en todas partes. El
> argumento es que levantar un broker y escribir un `@KafkaListener` se aprende en una
> tarde; lo que cuesta —exactly-once, reproceso, outbox, orden por partición— no se
> aprende con un contenedor local, se aprende razonando sobre el diseño. Por eso vive en
> el corpus de arquitectura y no aquí.

---

## 4. 🧱 Requisitos de la máquina

```bash
java -version          # necesitas 21
docker --version       # y que el daemon esté corriendo
docker compose version # v2: es "docker compose", no "docker-compose"
curl --version
jq --version
```

- **JDK 21 (Temurin)** es el baseline del curso y el que fija §5.2 de la guía. Con 17 la mayor
  parte de la serie funciona, pero los virtual threads no existen ahí: son materia del capítulo
  [`12`](12-reactivo-bloqueante-y-virtual-threads.md) y de los 🔥 opcionales de `L05` y `L06`, y
  esos se quedan sin ejecutar.
- **Docker Compose v2** viene integrado en el Docker moderno y se invoca como subcomando
  (`docker compose`), no con guion. Si tu máquina solo tiene `docker-compose` v1, algunos
  comandos de la serie —los `--profile`— no funcionan igual.
- **`jq`** se usa constantemente para leer las respuestas de Actuator. No es opcional en la
  práctica.
- **Maven no hace falta instalarlo**: el proyecto trae el wrapper (`./mvnw`), que descarga
  la versión correcta la primera vez.

**Espacio y memoria.** La serie completa ocupa del orden de **2 GB** entre imágenes y
volúmenes, y con todo levantado a la vez consume alrededor de **2 GB de RAM**. Nunca hace
falta todo a la vez: cada lab levanta solo su perfil.

---

## 5. 🧱 El sistema completo

```text
                          ┌─────────────────┐
   curl ──► inv-api ──────► inv-supplier    │  WireMock: latencia y fallos a demanda
    :8080  │  │  │  │      └─────────────────┘
           │  │  │  └─────► Keycloak :8180    emite el JWT que inv-api valida
           │  │  └────────► Redis :6379       caché distribuida y lock
           │  └───────────► Mongo :27017      proyección de consulta
           └──────────────► Postgres :5432    inventario, eventos y tablas de Batch

   inv-api :8081 (Actuator) ──► Prometheus :9090 ──► Grafana :3000
```

Ningún lab necesita todas las cajas. `L01` y `L02` no levantan ninguna.

---

## 6. 🧱 El `docker-compose.yml` de la serie

Este fichero se escribe una vez, en `L01`, y no cambia en toda la serie: **también el
servicio de la propia aplicación está aquí desde el primer día**, apagado detrás de su perfil
hasta que [`L09`](l09-empaquetado-imagen-y-limpieza.md) construye su imagen. Aquí está entero, con su explicación; cada lab dice qué
perfil levanta. Lo único que alguien toca después son **valores**, nunca la estructura: `L09`
cambia una variable de entorno o un plazo para comparar comportamientos y los deja como estaban.

```yaml
name: inv-lab            # fija el nombre del proyecto: todos los recursos llevan este prefijo

services:

  postgres:
    image: postgres:17.11-alpine
    profiles: ["db"]
    environment:
      POSTGRES_DB: inv_lab
      POSTGRES_USER: inv_lab
      POSTGRES_PASSWORD: inv_lab
    ports: ["5432:5432"]
    volumes: ["postgres-data:/var/lib/postgresql/data"]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U inv_lab -d inv_lab"]
      interval: 5s
      retries: 10

  redis:
    image: redis:8.6.6-alpine
    profiles: ["cache"]
    ports: ["6379:6379"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      retries: 10

  mongo:
    image: mongo:8.0.32-noble
    profiles: ["nosql"]
    ports: ["27017:27017"]
    volumes: ["mongo-data:/data/db"]

  wiremock:
    image: wiremock/wiremock:3.13.2-alpine
    profiles: ["ext"]
    command: ["--verbose", "--global-response-templating"]
    ports: ["8090:8080"]
    volumes: ["./wiremock:/home/wiremock"]

  prometheus:
    image: prom/prometheus:v3.13.3
    profiles: ["obs"]
    ports: ["9090:9090"]
    volumes: ["./observability:/etc/prometheus:ro"]
    extra_hosts: ["host.docker.internal:host-gateway"]

  grafana:
    image: grafana/grafana:13.0.9
    profiles: ["obs"]
    environment:
      GF_SECURITY_ADMIN_PASSWORD: inv_lab
      GF_AUTH_ANONYMOUS_ENABLED: "true"
    ports: ["3000:3000"]

  keycloak:
    image: quay.io/keycloak/keycloak:26.7.4
    profiles: ["sec"]
    command: ["start-dev", "--import-realm"]
    environment:
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: admin
    ports: ["8180:8080"]
    volumes: ["./keycloak:/opt/keycloak/data/import"]

  inv-api:
    image: inv-api:0.0.1-dockerfile     # la construye L09; hasta entonces este servicio no se levanta
    profiles: ["app"]
    ports: ["8080:8080", "8081:8081"]
    environment:
      SPRING_PROFILES_ACTIVE: local
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/inv_lab
      SPRING_DATA_REDIS_HOST: redis
      INV_SUPPLIER_BASEURL: http://wiremock:8080
      INV_JWT_JWKSETURI: http://keycloak:8080/realms/inv/protocol/openid-connect/certs
      JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    stop_grace_period: 45s

volumes:
  postgres-data:
  mongo-data:
```

Lo que hay que entender de este fichero, línea por línea:

- **`name: inv-lab`** fija el nombre del proyecto de Compose. Sin él, Compose usa el nombre
  del directorio, y entonces los contenedores y volúmenes se llaman distinto según dónde
  hayas clonado. Con el nombre fijo, `docker compose -p inv-lab down -v` funciona desde
  cualquier sitio y la limpieza de `L09` es determinista.
- **`profiles:`** hace que **ningún servicio arranque por defecto**. `docker compose up -d`
  sin perfil no levanta nada, y eso sorprende la primera vez — es deliberado: cada lab
  declara lo suyo con `docker compose --profile db up -d` y no cargas siete contenedores
  para probar un endpoint.
- **Los tags son exactos y están verificados** el 17 de septiembre de 2026. Ningún
  `:latest`: un `latest` convierte tu lab en irreproducible el día que el mantenedor
  publique una versión con otro comportamiento, y eso es justo lo que el curso enseña a no
  hacer.
- **`healthcheck`** en Postgres y Redis: `pg_isready` y `redis-cli ping` responden cuando
  el servicio acepta conexiones, no cuando el contenedor arrancó. La diferencia son unos
  segundos en los que tu aplicación fallaría al conectar, y es la causa de la mitad de los
  "en mi máquina no arranca" con Compose.
- **Las credenciales son triviales a propósito** (`inv_lab` / `inv_lab`). Es un Postgres en
  `localhost` que muere con un comando. Simular rigor con una contraseña de veinte
  caracteres en un lab local no enseña nada; lo que sí enseña es saber **por qué** esto
  sería inaceptable a un centímetro de tu máquina, y eso se discute en `07` y en [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md).
- **`ports: ["8090:8080"]`** en WireMock: dentro del contenedor escucha en 8080, y se
  publica en 8090 para no chocar con `inv-api`. Keycloak hace lo mismo con 8180.
- **Los volúmenes con nombre** (`postgres-data`, `mongo-data`) sobreviven a
  `docker compose down`. Solo mueren con `-v`. Esa distinción es la fuente número uno de
  "datos que reaparecen" y se practica en cada lab que toque datos.
- **Los `bind mounts`** (`./wiremock`, `./observability`, `./keycloak`) son directorios de
  tu repositorio: lo que edites ahí lo ve el contenedor sin reconstruir nada. **Los tres se
  montan como directorio, nunca como fichero suelto**, y la razón es concreta: si el origen
  no existe cuando el servicio arranca, Docker lo crea **como directorio**. Montar
  `./observability/prometheus.yml` te dejaría un *directorio* llamado `prometheus.yml` y un
  Prometheus que no arranca; montando `./observability` el peor caso es un directorio vacío,
  que es un error legible. Cada lab crea el suyo con `mkdir -p` antes del `up` — `L05` el de
  WireMock, `L07` el de observabilidad.
- **`./observability` monta el directorio entero en `/etc/prometheus`** porque Prometheus
  necesita ver ahí **dos** ficheros, la configuración (`prometheus.yml`, su ruta por defecto
  dentro de la imagen) y las reglas de alerta (`alerts.yml`). Los escribe `L07`; el resto de
  la serie no los necesita y el perfil `obs` no se levanta hasta entonces.
- **`extra_hosts: ["host.docker.internal:host-gateway"]`** hace que ese nombre resuelva a la
  IP del gateway de Docker, que es por donde un contenedor alcanza a tu máquina anfitriona.
  Hace falta porque `inv-api` corre como `java -jar` **fuera** de Docker hasta `L09`, y
  Prometheus tiene que raspar su puerto de management. En Docker Desktop el nombre ya resuelve
  solo y la línea no cambia nada; en Docker Engine sobre Linux no existe de fábrica y sin ella
  el scrape falla. Se escribe para todos en vez de partir el lab en dos caminos.

El servicio `inv-api` es el único que **no puedes levantar todavía**, y también se escribe hoy
para que el fichero no cambie nunca. Línea por línea:

- **`image: inv-api:0.0.1-dockerfile` nombra una imagen que aún no existe** en tu máquina: la
  construye el `Dockerfile` de `L09`. Declararla antes no rompe nada y esto se comprueba, no se
  supone: `docker compose config` valida el YAML **sin resolver imágenes**, y levantar cualquier
  otro perfil (`--profile db up -d`, por ejemplo) tampoco la mira, porque Compose solo baja las
  imágenes de los servicios que el perfil activo selecciona. El error de `pull access denied`
  aparece **únicamente** si pides el perfil `app` antes de construirla.
- **`image:` y no `build:`**, a propósito: encadenar el build de Maven y el de Docker dentro de
  `up` esconde los dos pasos que `L09` enseña a mirar. Aquí la imagen se construye antes, con su
  nombre y su tag, y Compose se limita a ejecutarla.
- **`profiles: ["app"]`** es lo que mantiene todo lo anterior intacto: sin ese perfil en la línea
  de comandos, para `L01`–`L08` este bloque es texto en un fichero.
- **`ports: ["8080:8080", "8081:8081"]`** publica la aplicación y Actuator en los puertos de
  siempre, para que los `curl` de los ocho labs anteriores sigan valiendo cuando el proceso pase a
  vivir dentro de Docker. Hasta `L09` esos puertos los ocupa tu `java -jar`, que corre fuera.
- **Las seis variables de `environment` son la configuración por entorno**, y son la razón de que
  el mismo jar sirva dentro y fuera de Docker: `localhost` deja de existir dentro del contenedor y
  cada URL pasa al nombre del servicio (`postgres`, `redis`, `wiremock`, `keycloak`). Los nombres
  en mayúsculas son el *relaxed binding* de `07` y se explican uno a uno en `L09` §6.
- **`depends_on` con `condition: service_healthy`** espera al `healthcheck` de Postgres y de Redis,
  no a que el contenedor exista — es el mismo "en mi máquina no arranca" de más arriba, resuelto.
  WireMock y Keycloak no están en la lista porque no declaran `healthcheck`, y un
  `condition: service_started` sobre ellos daría una garantía falsa.
- **Ese `depends_on` cruza perfiles, y tiene una consecuencia práctica**: el perfil `app` por sí
  solo deja el proyecto incompleto y Compose lo rechaza con `service "inv-api" depends on
  undefined service "postgres"`. Por eso `L09` levanta `--profile db --profile cache --profile app`
  en la misma línea, y no `--profile app` a secas.
- **`stop_grace_period: 45s`** es el plazo entre el `SIGTERM` y el `SIGKILL`. El default son 10
  segundos, menos que los 30 de `spring.lifecycle.timeout-per-shutdown-phase`: sin esta línea,
  Docker mataría el proceso a mitad del apagado ordenado que se practica en `L09` §7.

> **⏱️ Costo en runtime.** $0.00 en dinero, pero no es gratis en recursos: Postgres pide
> unos 150 MB de RAM, Keycloak alrededor de 500 MB, y Grafana con Prometheus otros 300 MB.
> Levantar los siete perfiles a la vez en una máquina de 8 GB con un IDE abierto se nota.
> Por eso los perfiles existen.

---

## 7. 🧱 Nombres fijos de la serie

No se inventan valores nuevos. Si un lab necesita otro, lo declara y explica por qué.

| Elemento | Valor |
|---|---|
| Artifact / servicio | `inv-api` |
| `groupId` / paquete base | `com.invlab` / `com.invlab.invapi` |
| Proveedor externo simulado | `inv-supplier` (WireMock) |
| Proyecto de Compose | `inv-lab` |
| Perfiles de Spring | `local` (default del lab), `test`, `prod` |
| Puertos | app `8080`, Actuator `8081`, WireMock `8090`, Keycloak `8180` |
| Postgres | base / usuario / password `inv_lab` |
| Tablas | `inventory_item`, `inventory_event` |
| Colección de Mongo | `inventory_snapshot` |
| Caché / prefijo de Redis | `inventory-items` / `inv:` |
| Job de Batch | `inventory-reconciliation-job` |
| Dominio de ejemplo | `invlab.example` |
| Usuario de ejemplo | `analyst@invlab.example` |

---

## 8. 🧱 El orden, y qué deja cada lab

Los labs son **acumulativos**: cada uno parte del estado en que lo dejó el anterior.

| Lab | Qué añade a `inv-api` | Perfiles de Compose al terminar |
|---|---|---|
| [`L01`](l01-esqueleto-cli-y-autoconfiguracion.md) | El proyecto, el arranque, el informe de condiciones | ninguno |
| [`L02`](l02-configuracion-y-profiles.md) | Configuración tipada, profiles, secretos | ninguno |
| [`L03`](l03-api-rest-filtros-y-errores.md) | API REST, validación, errores, filtros | ninguno |
| [`L04`](l04-datos-y-transacciones.md) | Persistencia, Flyway, transacciones | `db` |
| [`L05`](l05-clientes-y-resiliencia.md) | Cliente del proveedor, timeouts, resiliencia | `db`, `ext` |
| [`L06`](l06-cache-y-asincronia.md) | Caché, asincronía, segunda instancia | `db`, `ext`, `cache` |
| [`L07`](l07-actuator-metricas-y-trazas.md) | Métricas, dashboards, trazas | `db`, `ext`, `cache`, `obs` |
| [`L08`](l08-security-y-batch.md) | Seguridad JWT y proceso batch | `db`, `ext`, `cache`, `obs`, `sec` |
| [`L09`](l09-empaquetado-imagen-y-limpieza.md) | Empaquetado, imagen, apagado ordenado y limpieza | los cinco anteriores más `app`; **ninguno** tras la limpieza |

La columna es **acumulativa** y por eso crece: levantar un perfil no baja los anteriores, así
que `L08` termina con cinco contenedores encima. El perfil `nosql` no aparece en ninguna fila
porque Mongo solo se levanta en el 🔥 opcional de `L04`, fuera del hilo principal, y se baja
ahí mismo.

Cada lab abre con el comando que **verifica** que vienes del estado correcto. Si falla, te
dice a cuál volver. La serie entera son entre **22 y 26 horas** de trabajo real, sumando las
duraciones que declara cada lab en su cabecera. Tres de ellos —`L07`, `L08` y `L09`— pasan de
tres horas y conviene partirlos en dos sesiones: los tres tienen un corte natural, porque su
segunda mitad arranca con un mecanismo nuevo y no con la continuación del anterior.

---

## 9. 🧪 Cómo se limpia todo

Esto va aquí, al principio, y no al final de la serie: si abandonas a la mitad, esta es la
sección que necesitas.

```bash
docker compose -p inv-lab down -v --remove-orphans
docker volume ls | grep inv-lab
docker ps -a | grep inv-lab
```

- **`down -v`** para los contenedores, borra la red **y borra los volúmenes con nombre**.
  Sin `-v`, `postgres-data` sobrevive y al volver a levantar encuentras los datos de hace
  tres semanas — que es exactamente el "pero si yo borré eso" clásico.
- **`--remove-orphans`** elimina contenedores de perfiles que ya no están declarados. Sin
  él, un servicio que quitaste del fichero se queda corriendo, invisible para
  `docker compose ps`.
- **`-p inv-lab`** apunta al proyecto por nombre, así que funciona aunque no estés en el
  directorio del `docker-compose.yml`.
- **Los dos comandos de verificación** son la parte que no se salta: la limpieza no se da
  por buena porque el primer comando no diera error, se da por buena porque los listados
  salen vacíos. Es la misma disciplina que los cursos de nube aplican a la factura.

Lo que **no** borra eso, y hay que saberlo: las imágenes descargadas (`docker image prune`
si quieres el espacio), el caché de Maven en `~/.m2` y el directorio `target/` del
proyecto.

---

## 🧠 Preguntas rápidas

1. Enuncia la regla que decide qué entra en el laboratorio y qué se queda en el capítulo.
2. Da dos ejemplos de mecanismos del curso que **no** necesitan lab, y di por qué.
3. ¿Por qué el curso excluye Kafka a pesar de que en banca está en todas partes?
4. ¿Por qué se excluye R2DBC del lab pero no del temario?
5. `docker compose up -d` no levanta nada en este proyecto. ¿Por qué, y cómo se levanta
   Postgres?
6. ¿Qué aporta `name: inv-lab` en el `docker-compose.yml` y qué se rompe sin él?
7. ¿Por qué ningún tag de imagen es `:latest`, si es un lab local que no cuesta dinero?
8. ¿Qué diferencia hay entre `docker compose down` y `docker compose down -v`, y cuál es
   el síntoma de olvidar la segunda?
9. ¿Para qué sirve el `healthcheck` de Postgres si el contenedor ya arrancó?
10. ¿Por qué WireMock se publica en el puerto 8090 y Keycloak en el 8180?
11. Las credenciales del lab son `inv_lab`/`inv_lab`. ¿Es eso una mala práctica? Justifica
    la respuesta en los dos sentidos.
12. Después de `down -v`, ¿qué queda todavía ocupando disco en tu máquina?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Docker Compose support: https://docs.spring.io/spring-boot/3.5/reference/features/dev-services.html
- Spring Boot 3.5 — Estructura del código: https://docs.spring.io/spring-boot/3.5/reference/using/structuring-your-code.html

### Documentación de terceros

- Docker Compose — especificación del fichero: https://docs.docker.com/reference/compose-file/
- Docker Compose — perfiles: https://docs.docker.com/compose/how-tos/profiles/
- WireMock — documentación: https://wiremock.org/docs/
- Keycloak — guía de servidor: https://www.keycloak.org/guides
