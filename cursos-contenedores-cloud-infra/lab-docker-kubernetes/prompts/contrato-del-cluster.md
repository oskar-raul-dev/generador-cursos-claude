# 📜 Contrato del cluster
## Laboratorio de contenedores y Kubernetes local

> **Qué es este documento:** los nombres técnicos que ninguna fase puede cambiar: la estructura de
> `src/lab/`, los servicios, los puertos, las rutas de plataforma, los namespaces, los hosts, las
> labels, los perfiles, las tareas del Taskfile y la matriz de generación. **Es de lectura
> obligatoria antes de tocar cualquier cosa bajo `src/lab/`.**
> **Precedencia:** debajo del [alcance](alcance-del-proyecto.md) y de la
> [guía](guia-de-estilo-y-convenciones.md), por encima de las propuestas, las plantillas y los
> prompts. Si una fase necesita un nombre que no está aquí, **lo agrega aquí primero**.
> **Fecha:** 30/09/2026, actualizado el 03/10/2026 con la verificación de laboratorio (P11) y con D34
> (los dos contenedores de `catalog`): ya no queda nada marcado ⏳. Las versiones y los números viven en `a01`.

---

## 1. 🧭 Las tres reglas del contrato

1. **Un contrato de plataforma uniforme.** Los cuatro servicios cumplen exactamente la misma
   interfaz hacia el cluster: el mismo puerto, las mismas rutas de salud, la misma ruta de métricas,
   la misma forma de log. **Cómo lo consigue cada runtime es el contenido del curso**; que lo
   consiga no se negocia.
2. **El contrato de dominio se congela en la Fase 02.** Desde ahí, los endpoints que todavía no
   existen están marcados como pendientes en el OpenAPI, y ninguna fase cambia una forma de
   payload sin cambiar primero el contrato y la suite.
3. **Una capacidad no llega antes que su fase.** Si el código de un servicio expone `/metrics`
   antes de la Fase 17, el código está mal, aunque funcione.

---

## 2. 📁 La estructura de `src/lab/`

Un solo proyecto, que crece fase a fase y se etiqueta con `fase-NN-<slug>`.

```text
src/lab/
├── Taskfile.yml                 punto de entrada único (§7)
├── kind/
│   ├── cluster-minimo.yaml      un nodo · cluster `minimo`, contexto `kind-minimo`
│   └── cluster-lab.yaml         control-plane + 2 workers · cluster `lab`, contexto `kind-lab`
├── contracts/
│   ├── openapi/                 catalog.yaml · inventory.yaml · replenish.yaml · pricing.yaml
│   ├── proto/pricing/v1/        pricing.proto (desde la Fase 23)
│   ├── docs/                    Swagger UI en compose, para leer los OpenAPI
│   └── conformance/             suite Hurl, un archivo por servicio y paso; compose.env y cluster.env
├── services/
│   ├── catalog/                 PHP · Laravel · Dockerfile (PHP-FPM) · nginx.conf · CLAUDE.md
│   ├── inventory/               Java · Spring Boot · Dockerfile · Dockerfile.aot (🔥 F15) · CLAUDE.md;
│   │                            relay/ (Go, F26): el publicador del outbox, que el sidecar corre desde la misma imagen
│   ├── replenish/               Node · NestJS · Dockerfile · CLAUDE.md
│   ├── pricing/                 Go · Dockerfile · CLAUDE.md
│   └── storefront/              React · Vite · Dockerfile · CLAUDE.md
├── compose/compose.yaml         Partes 0 y I
├── deploy/manifests/            YAML plano, Fases 08 a 12: namespace.yaml, neighbors.yaml y una carpeta por servicio
├── deploy/incidents/            los manifiestos rotos que usa task inc:break, y la carga de k6 de los que la piden (14)
├── deploy/legacy/               el patrimonio en el namespace legacy (F10); el Secret del portal desde F11; la Braqui,
│                                el PVC de traslados y el CronJob del aviso desde F12 (antes-de-la-fase-12/, el cron de a16)
├── deploy/strangler/            la ruta 80/20 y el Job que migra los precios de Contingencia (F10)
├── deploy/qa/                   el ambiente de QA de la F11: la misma imagen del storefront, otra configuración
├── deploy/jobs/                 los Job de migración (uno por servicio) y el del seed (F12); experimentos/, los que no son del sistema
├── deploy/kustomize/            el perfil lab de pricing con Kustomize, solo para comparar (F14)
├── charts/platform/             umbrella chart desde la Fase 13: release `lab` en `apps`; values.yaml y values-<perfil>.yaml;
│                                charts/lab-common (librería) y un subchart por servicio; migraciones y seed como hooks;
│                                values.schema.json y values-tenant-b.yaml desde F14; prometheus y grafana desde F17, loki y fluent-bit desde F18,
│                                con sus objetos en observability (el tablero, en charts/grafana/dashboards/)
├── platform/                    gateway · cert-manager · observability · data (postgres; valkey y nats desde F25, que aplica
│                                task bus:on) · tenants (apps-b, F14)
│                                · metrics-server (F16, el manifiesto de la release con la imagen por digest)
│                                · observability/namespace.yaml (F17: el namespace; las piezas son del chart)
│                                · cert-manager/ (F19: valores con digests, el ClusterIssuer lab-ca, el Certificate de la
│                                  puerta y el Bundle de trust-manager) · registry/hosts.toml (F19, el registry propio)
├── chaos/                       el generador de caos (Go, solo biblioteca estándar), Fase 22; su subchart, charts/platform/charts/chaos
├── legacy/                      el patrimonio de arranque, apéndice a16 (tanda T1b)
│   ├── contingencia/            el código del Siga en Eclipse GlassFish, SOAP + Postgres propio
│   ├── portal/                  Laravel (PPVW), con su SQLite y el job nocturno de catálogo
│   └── braqui/                  Node, sondeando las tablas de despachos de Contingencia;
│                                y el script de traslados por archivo (Python + cron, D30)
├── scripts/                     scripts de Python del laboratorio (D31), un requirements.txt por directorio
│   ├── engine/                  el motor activo: status, use y stop (reemplaza al .ps1 de Windows, T1)
│   ├── measure/                 el arnés de task measure (B-00 desde T1; B-04, B-05 y B-07 después)
│   ├── incidents/               task inc:break e inc:fix (F08)
│   ├── data/                    las credenciales de Postgres (F12): .secrets/postgres.env y los Secret de cada base
│   ├── chart/                   compare.py: el chart renderizado contra el YAML plano (F13)
│   ├── obs/                     switch.py: los interruptores de observabilidad en .observability.json (F17); trace.py: una traza de Tempo como árbol de tiempos (F23)
│   ├── conformance/             logs.py: la mitad de la suite de G7 que lee el log de los cuatro (F18)
│   ├── tls/                     certs.py: la CA del laboratorio y los certificados que firma, con cryptography (F19)
│   ├── chaos/                   chaos.py: las fallas del generador en caliente, con los perfiles de ciudad (F22)
│   └── seed/                    datos sintéticos con Faker; a01 lo presenta y la F12 lo corre como Job (load.py, Dockerfile)
├── bench/                       manifiestos de medición y resultados crudos (bench/b00/ desde T1; bench/b16/rate.js, el k6 de B-16;
│                                bench/trafico/la-vecina.js, el tráfico de fondo de los tableros, F17)
├── .secrets/                    los valores de los Secret (F11): se escriben a mano en cada máquina; no se versiona
├── .engine.env                  el motor activo (LAB_ENGINE=docker|podman); no se versiona
└── .observability.json          los interruptores encendidos en esta máquina (task obs:on, F17); no se versiona
```

**Los prompts de generación no viven aquí**: se publican en `a03`. Lo que vive en cada servicio es
su `CLAUDE.md`, corto (menos de 150 líneas), con el stack, los comandos, las convenciones y el
contrato del servicio con los pasos futuros marcados como pendientes.

---

## 3. 🧱 Los servicios y su interfaz de plataforma

| Servicio | Puerto HTTP | Puerto extra | Imagen | Rol |
|---|---|---|---|---|
| `catalog` | 8080 | — | `lab/catalog` | maestro de productos y categorías |
| `inventory` | 8080 | — | `lab/inventory` | stock por tienda y movimientos; orquestador de la saga |
| `replenish` | 8080 | — | `lab/replenish` | órdenes de reposición; consumidor de eventos |
| `pricing` | 8080 | 9090 (gRPC, desde F23) | `lab/pricing` | precio vigente por producto y tienda |
| `storefront` | 8080 | — | `lab/storefront` | frontend estático servido por nginx sin privilegios |

**`catalog` son dos contenedores (D34, Fase 04):** `lab/catalog` corre PHP-FPM con la aplicación y
escucha FastCGI solo en `127.0.0.1:9000`; delante va la imagen oficial de nginx sin privilegios con
`services/catalog/nginx.conf`, en el 8080. Comparten la red: en compose, el servicio `catalog-nginx`
con `network_mode: service:catalog`; desde la Fase 09, dos contenedores del mismo pod (`php-fpm` y
`nginx`). Para el resto del sistema, `catalog` sigue siendo un servicio en el 8080.

**Por qué todos en 8080:** ningún contenedor del curso necesita un puerto privilegiado, y un puerto
uniforme hace que la diferencia entre servicios esté donde importa. El puerto se lee de la variable
`PORT` y 8080 es su valor por defecto.

**Rutas de plataforma, iguales en los cuatro backends:**

| Ruta | Desde | Qué responde |
|---|---|---|
| `GET /health/live` | F02 | 200 si el proceso puede atender; **nunca** consulta dependencias |
| `GET /health/ready` | F02 trivial, F15 real | 200 solo si el servicio puede atender tráfico de verdad |
| `GET /metrics` | F17 | formato de exposición de Prometheus |

`inventory` cumple estas rutas remapeando Actuator, y eso se dice en la fase que lo hace: el
contrato es uniforme aunque el framework tenga su propia convención.

**Variables de entorno comunes:** `PORT`, `LOG_LEVEL`, `DATA_DIR` (la carpeta del SQLite de G1, `/var/lib/<svc>` por defecto; F09–F11), `DATABASE_URL` (desde F12: `postgres://<svc>:<clave>@postgres.data.svc.cluster.local:5432/<svc>`, del `Secret` `<svc>-db`; sin ella, el SQLite de `DATA_DIR`, que sigue siendo el de compose), las URL de los
vecinos como `CATALOG_URL`, `PRICING_URL`, `REPLENISH_URL` (desde F09, usadas desde F16),
`EVENT_BUS` (`valkey` o `nats`) con `NATS_URL` o `VALKEY_URL` (desde F25, en `inventory` y `replenish`, que el chart escribe con `global.bus`), y las de OpenTelemetry estándar (`OTEL_*`, desde F23).
`storefront` recibe `API_BASE_URL` y `BRAND_NAME`, y la Fase 11 existe para mostrar por qué no alcanza
con eso: desde G2 los lee nginx **al arrancar** y los sirve en `/config.json`; antes se horneaban al
compilar y el contenedor los ignoraba.
`pricing` recibe `REGULATED_CAP_ENABLED` y la ruta de la tabla de topes regulados, que viven en un
`ConfigMap` desde la Fase 11 (D23).

**Logs:** a stdout, nunca a archivo. Texto libre hasta la Fase 18; desde ahí, **una línea JSON por
evento** con al menos `timestamp`, `level`, `service`, `message` y, desde la Fase 23, `traceId`.

**Apagado:** desde la Fase 16, al recibir `SIGTERM` el servicio deja de aceptar conexiones nuevas,
termina las que tiene en vuelo y sale en menos de `terminationGracePeriodSeconds`.

---

## 4. 🧭 Namespaces, hosts y labels

**Namespaces:**

| Namespace | Qué vive ahí | Desde |
|---|---|---|
| `apps` | los cuatro servicios y `storefront` | F09 (en F08, `pricing` vive en `default` a propósito) |
| `data` | Postgres, Valkey, NATS | F12 / Parte IV |
| `gateway` | Envoy Gateway y el `Gateway` compartido | F10 |
| `observability` | Prometheus, Grafana, Loki, Fluent Bit, Tempo | F17 |
| `cert-manager` | cert-manager y trust-manager | F19 |
| `legacy` | el patrimonio: Contingencia, su Postgres, el portal y la Braqui | F10 (antes, en compose) |
| `apps-b` | la segunda cadena: el mismo chart como release `tenant-b`, con su archivo de valores | F14, F15 y F20 (D24); apagada en `minimo` |

**La seguridad de cada cadena (desde F20)**, en el chart: `global.podSecurity.enabled` (sin root y con el número de
usuario, sin capacidades, raíz de solo lectura con `emptyDir` en `/tmp`, seccomp `RuntimeDefault`, sin el token de la
API) y `global.networkPolicy.enabled` (`default-deny`, `allow-dns`, `allow-ingress` desde la misma cadena, `gateway` y
`observability` al 8080, `allow-egress` a la misma cadena y a Postgres). En `data`, `platform/data/postgres/
networkpolicy.yaml` deja entrar al 5432 solo desde `apps`, `apps-b` y `data`, y Postgres corre como 999.

**Releases de Helm (desde F13):** `lab` en `apps` (el sistema, `task deploy`) y `tenant-b` en `apps-b`
(la segunda cadena, F14). Los `Secret` de las bases, el namespace, Postgres, la puerta y el patrimonio
quedan fuera del chart.

**Hosts**, todos bajo `.localhost`, que resuelve a la máquina local sin tocar `/etc/hosts` en la
mayoría de los clientes (la excepción, y qué hacer con ella, es contenido de la Fase 10):

`storefront.localhost` · `api.localhost` (ruteo por prefijo a los cuatro backends) ·
`grafana.localhost` · `prometheus.localhost` · y los de la segunda cadena (F14):
`storefront.tenant-b.localhost` · `api.tenant-b.localhost`. Dos cadenas en la misma puerta no pueden
compartir host: las rutas empatadas las resuelve Gateway API a favor de la más vieja.

**Puertos del host:** 8080 para HTTP y 8443 para HTTPS, nunca 80 ni 443, porque Podman sin
privilegios no los puede publicar. **Cómo llega ese puerto al `Gateway`** (verificado en P11, con
los dos motores): el nodo control-plane de los dos clusters mapea `127.0.0.1:8080 → 30080` y
`127.0.0.1:8443 → 30443` con `extraPortMappings`, y un `EnvoyProxy` referenciado desde la
`GatewayClass` fija el `Service` del proxy como `NodePort` en esos dos puertos y con
`externalTrafficPolicy: Cluster`, para que en el perfil `lab` responda aunque el proxy viva en un
worker. cloud-provider-kind se descartó como camino por defecto: en macOS la IP del `LoadBalancer`
no llega al host, y su mapeo de puertos publica uno efímero en cada creación.

**Puertos del host en compose**, todos en `127.0.0.1`: 8081 para el portal del patrimonio y 8090
para Swagger UI; los servicios nuevos no publican puerto en compose y se prueban desde la red de
compose (`a03`).

**Los dos archivos de kind** llevan desde el principio, además, el `containerdConfigPatches` que
activa `config_path = "/etc/containerd/certs.d"`: es lo que deja confiar en el registry propio en
la Fase 19 sin recrear el cluster, y no cambia nada antes.

**Labels**, las recomendadas por Kubernetes y ninguna inventada:

```yaml
app.kubernetes.io/name: pricing          # el servicio
app.kubernetes.io/part-of: lab           # el sistema
app.kubernetes.io/component: backend     # backend · frontend · database · bus · observability
app.kubernetes.io/version: "{{tag}}"     # el tag legible; la imagen se fija por digest
```

Los selectores de `Service` y `Deployment` usan **solo** `app.kubernetes.io/name`. Un selector con
más labels es la causa de uno de los incidentes del cuaderno.

---

## 5. 📦 Los perfiles de despliegue

No son cosmética: son parte del arnés de medición y del presupuesto de memoria.

| Perfil | Cluster | Qué corre | Réplicas | Dónde se usa |
|---|---|---|---|---|
| `minimo` | kind de un nodo | servicios y Postgres; todo lo demás apagado | 1 | Partes 0–II, salvo las excepciones |
| `lab` | control-plane + 2 workers | lo que la fase encienda | las de la fase | F07 (topología), F16, F18, Partes III y IV |
| `medicion` | el que declare la medición | **solo** lo medido y su generador de carga | las de la medición | cada 📏 |

**Los interruptores**, que desde la Fase 13 son valores del umbrella chart y antes son archivos que
se aplican o no:

```yaml
observability:
  metrics:    { enabled: false }   # Prometheus (metrics-server va aparte: lo necesita el HPA)
  dashboards: { enabled: false }   # Grafana
  logs:       { enabled: false }   # Loki + Fluent Bit
  traces:     { enabled: false }   # Tempo; con global.traces.enabled, los servicios exportan (F23)
bus:
  valkey: { enabled: false }
  nats:   { enabled: false }
```

**El presupuesto de memoria** de cada pieza (`requests` y `limits`) y la memoria del host por perfil
se publican en `a01` (B-00), en tres entregas: la infraestructura en T1, el perfil `legacy` en T1b y
los servicios en T2. Ningún otro documento cita un número. La orden de magnitud medida en P11 decide
una sola cosa de este contrato: **la máquina virtual de cada motor necesita 4 GiB**; la de Podman por
defecto (2 GiB) colapsa con la observabilidad encendida. **Y el Kubernetes propio de Docker Desktop, apagado**:
en la verificación de la F17 ocupaba 764 MiB de esos 4 GiB, y con el perfil `lab` y la observabilidad
encendida la máquina se quedó sin memoria.

---

## 6. 🌊 La matriz de generación

Cada celda es un prompt publicado en `a03`, con el contrato de ese paso y el comando de la suite
que lo valida. `pricing` va primero en cada fila (es el piloto) y **los otros tres lo siguen**.

| Paso | Fase | Qué agrega | Servicios |
|---|---|---|---|
| **G0 · Esqueleto** 🌊 | F02 | `/health/live`, `/health/ready` triviales y un endpoint con JSON fijo | los cinco |
| **G1 · Almacén propio** 🌊 | F09 | SQLite dentro del pod, lectura y escritura básicas, sin llamar a nadie | los cuatro backends; `storefront` lista productos |
| **G2 · Configuración en arranque** | F11 | `storefront` lee su configuración al arrancar, no al compilar | `storefront` |
| **G3 · Postgres** | F12 | `DATABASE_URL`, migraciones idempotentes ejecutables como `Job` | los cuatro backends |
| **G4 · Readiness real** | F15 | la sonda de readiness comprueba lo que el servicio necesita para atender: su base, en un segundo, y ningún vecino | los cuatro backends |
| **G5 · El flujo de venta** 🌊 | F16 | venta completa y apagado limpio ante `SIGTERM`; aviso a `replenish` sin esperar respuesta | los cuatro backends y `storefront` |
| **G6 · Métricas** | F17 | `/metrics` con las métricas RED del servicio | los cuatro backends |
| **G7 · Logs estructurados** | F18 | una línea JSON por evento a stdout (`time`, `level`, `service`, `msg`); la de cada petición, con `method`, `uri`, `path`, `status`, `duration_ms` y el `request_id` de `X-Request-Id`, que `inventory` reenvía | los cuatro backends |
| **G8 · Cliente mTLS** | F19 | `inventory` presenta certificado a `pricing` y verifica el suyo: `pricing` abre un 8443 con mTLS (el 8080 sigue en HTTP), los certificados los emite cert-manager y la CA la reparte trust-manager; `global.mtls.enabled`, encendido desde F19; la dirección `https` de `pricing` va solo en el `Deployment` de `inventory`, nunca en el `ConfigMap` de vecinos (F20) | `inventory`, `pricing` |
| **G9 · Resiliencia** | F22 | timeouts, reintentos con backoff y circuit breaker en las llamadas salientes (`Guard.java`, Resilience4j; el `POST` a `replenish` sin reintentos) | `inventory` |
| **G10 · gRPC y trazas** | F23 | `pricing` sirve `GetPrice` por gRPC en el 9090, con el mismo mTLS del 8443, e `inventory` lo pide por ahí en la venta (`global.grpc.enabled`; `global.grpc.balancing`: `client` por defecto, con el `Service` *headless* `pricing-grpc` y `round_robin`; `service`, el normal, para comparar; `global.grpc.maxConnectionAge`, 10 s por defecto, para que `pricing` corte las conexiones viejas y el cliente vea las réplicas nuevas); los cuatro abren spans y propagan el `traceparent` con OpenTelemetry a Tempo (`global.traces.enabled`, que escribe `task obs:on -- traces`; apagado, el SDK no exporta) | los cuatro backends |
| **G11 · Saga orquestada** | F24 | el préstamo (`POST /loans`) como saga en `inventory`: `RESERVE`, `DISPATCH` y `CHARGE` (el cobro al final, como pivote) y `RECEIVE`; compensaciones `LOAN_RELEASED` y la cancelación con `SAGA_COMPENSATION`; estado en `loans` y `loan_steps`, y un barrido cada 30 s que retoma lo que quedó a medias | `inventory`, `replenish` |
| **G12 · Coreografía** | F25 | el aviso de la venta como el evento `lab.inventory.stock-low` (`x-lab-events`): `inventory` publica, `replenish` consume; por Valkey pub/sub o por NATS JetStream (stream `LAB_EVENTS`, consumidor durable `replenish-stock-low`, ack después del trabajo), según `EVENT_BUS`; la orden guarda `sourceEventId` | `inventory`, `replenish` |
| **G13 · Idempotencia y outbox** | F26 | `Idempotency-Key` en ventas, préstamos y órdenes (índice único parcial; otro cuerpo, 422); `processed_events` en `replenish`; con NATS, el evento en la tabla `outbox` en la transacción de la venta, publicado por el sidecar nativo `outbox-relay` con `Nats-Msg-Id`; la saga reintenta el despacho con la clave y la busca al compensar; la cancelación idempotente | `inventory`, `replenish` |

**El patrimonio es insumo de la matriz.** Desde G0, el prompt de cada servicio nuevo recibe el
código del que se extrae: `pricing` y `inventory`, de Contingencia; `catalog`, del portal;
`replenish`, de la Braqui. El contrato y la suite siguen siendo los que deciden qué es válido.

**La suite de conformidad crece con la matriz**: cada paso agrega sus casos Hurl, y un paso está
hecho cuando `task conformance -- <paso>` pasa contra compose (Partes 0–I) o contra el cluster
(desde la Parte II).

---

## 7. ⌨️ Las tareas del Taskfile

Los nombres son contrato: las fases los citan tal cual. Cada tarea es corta y legible, porque el
lector tiene que poder abrirla y ver qué `kubectl` o qué `helm` corre debajo.

| Tarea | Qué hace | Desde |
|---|---|---|
| `task engine:status` | qué motor está activo y si responde | F00 |
| `task engine:use -- <motor>` / `engine:stop -- <motor>` | activa un motor (y lo arranca) o lo detiene | F00 |
| `task build -- <svc>` / `task build:all` | construye la imagen con el motor activo; desde la F23, con el contexto de build `proto` (`contracts/proto`) | F01 / F04 |
| `task compose:up` / `compose:down` | el sistema en compose | F02 |
| `task legacy:up` / `legacy:down` | enciende o apaga el patrimonio (perfil de compose y, desde F10, namespace `legacy`) | F02 |
| `task conformance -- <paso>` | corre la suite Hurl del paso contra compose; con `TARGET=cluster`, en un pod de `apps` | F02 / F09 |
| `task contracts:docs` | levanta Swagger UI en un contenedor con los cuatro OpenAPI, en `localhost:8090` | F02 |
| `task cluster:up -- minimo\|lab` / `cluster:down` / `cluster:list` | crea, borra o lista los clusters kind del motor activo | F07 |
| `task seed:generate` | datos sintéticos con Faker (`a01`) | F12 |
| `task images:load` | carga las imágenes al cluster: `kind load docker-image` con Docker; `podman save` + `kind load image-archive` con Podman, que construye como `docker.io/lab/<svc>` para que el nodo vea el mismo nombre | F08 |
| `task deploy -- <perfil>` | aplica manifiestos (F08–F12) o instala el chart (desde F13): `helm upgrade --install lab charts/platform -n apps -f values-<perfil>.yaml`, con los tags de `STEP_TAGS`; `CLUSTER=` elige otro cluster (`medicion` va a `minimo` por defecto) y `FORCE=true` agrega `--force-conflicts` | F08 |
| `task deploy TENANT=tenant-b -- <perfil>` | la segunda cadena: release `tenant-b` en `apps-b`, con `values-tenant-b.yaml` encima del perfil | F14 |
| `task deploy:diff -- <perfil>` | `helm diff upgrade --three-way-merge` con los argumentos de `task deploy` (acepta `TENANT`) | F14 |
| `task platform:postgres TENANT=tenant-b -- <perfil>` | namespace `apps-b`, sus `Secret` y las bases `<svc>_tenant_b` en el Postgres que ya corre | F14 |
| `task platform:metrics -- <perfil>` | metrics-server, con `--kubelet-insecure-tls` en kind | F16 |
| `task chart:compare` | el chart renderizado con el perfil `minimo`, comparado objeto por objeto con `deploy/manifests/` y `deploy/jobs/` | F13 |
| `task seed:image -- <perfil>` | construye la imagen del seed y la carga en el nodo (la usa `task deploy`) | F13 |
| `task obs:on -- <pieza>` / `obs:off` / `obs:status` | enciende o apaga una pieza de observabilidad (`metrics`, `dashboards`, `logs`, `traces` o `all`) y redespliega con `PROFILE` (`lab` por defecto); el estado queda en `.observability.json`, que `task deploy` suma a los valores del release `lab` | F17 |
| `task obs:trace -- <trace_id>` | una traza de Tempo como árbol de tiempos, por `port-forward` a su API (`scripts/obs/trace.py`) | F23 |
| `task tls:ca` / `tls:gateway -- <perfil>` | la CA del laboratorio en `.secrets/tls/`; el certificado de la puerta como `Secret` `lab-tls` | F19 |
| `task platform:certs -- <perfil>` | cert-manager y trust-manager, la CA como emisor (`ClusterIssuer lab-ca`), el `Certificate` de la puerta y el `Bundle` de la CA; requisito de `task deploy` desde F19 | F19 |
| `task registry:up` / `down` / `push -- <svc>` / `trust -- <perfil>` / `untrust -- <perfil>` | el registry propio con la CA (`lab-registry`, `127.0.0.1:5001`), y la confianza del containerd de cada nodo | F19 |
| `task chaos:on` / `chaos:off` / `chaos:set -- <falla=valor…> \| perfil <ciudad> \| show \| clear` | el generador de caos entre `inventory` y `catalog` (`global.chaos.enabled`, guardado con los interruptores en `.observability.json`), y sus fallas en caliente; con `TARGET=replenish`, entre `inventory` y `replenish` (`global.chaos.target`, F24) | F22 |
| `task bus:on -- valkey\|nats` / `bus:off -- valkey\|nats` | aplica el bus en `data` (`platform/data/<bus>/`), escribe `bus.<bus>` y `global.bus.<bus>` en `.observability.json` y redespliega; con NATS, `inventory` lleva el sidecar `outbox-relay` (F26) | F25 |
| `task proto` | regenera el código de Go de `contracts/proto/` dentro de un contenedor de Go (`protoc` y los dos generadores en las versiones de `a01`); el de Java lo genera el build de Maven, con `--build-context proto=contracts/proto` | F23 |
| `task measure -- <id>` | corre una medición del `BENCHMARKS.md` y deja el crudo en `bench/` | F04 |
| `task inc:break -- <ID>` / `inc:fix -- <ID>` | lleva el laboratorio al estado roto de un incidente, o lo repara | F08 |

---

## 8. 🏷️ Git

- **Tags de fase:** `fase-NN-<slug>`, anotados, con el checklist de cierre en el mensaje.
- **Commits:** `fNN: …`; los de ejercicio, `fNN ejMM: …`.
- **Incidentes:** el par `inc/<ID>/<slug>-roto` e `inc/<ID>/<slug>-fix`, con el ID que el cuaderno ya
  tiene reservado y nunca uno inventado. El `git diff` entre los dos **es** la corrección, aislada
  del ruido de la fase.
- **Apéndices:** sin tag, salvo `a01`, `a03` y `a16`, que dejan archivos versionados
  (`apendice-a01-laboratorio`, `apendice-a03-contratos`, `apendice-a16-patrimonio`).

---

## 9. 📌 Pendientes de este documento

- ✅ Controlador de Gateway API: **Envoy Gateway** (D12). La verificación mide su memoria en reposo
  y su conformidad con la versión de Gateway API fijada.
- ✅ El puerto del host al `Gateway`: `extraPortMappings` + `NodePort` fijo (§4), verificado en macOS
  arm64 con los dos motores. Windows 11 y Linux, no verificados.
- ✅ kindnet aplica `NetworkPolicy` en la versión fijada de kind: la Fase 20 no instala otro CNI.
- ✅ Presupuesto de memoria: vive en `a01` (§5), que lo completa en T1, T1b y T2.
- ✅ **La empresa no toca este contrato**: los identificadores son funcionales a propósito. El
  nombre visible —"Droguerías La Vecina" en el `storefront`, y la marca de la segunda cadena en
  `apps-b`— va en los valores de configuración, nunca en un identificador.

Los tres se cerraron ejecutando, en la verificación de laboratorio (P11, 03/10/2026). Ninguno cambió
un nombre de este contrato: cambiaron valores, y se sumaron los nombres de los dos clusters.
