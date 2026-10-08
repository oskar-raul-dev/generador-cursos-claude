# 📎 Apéndice a01 — El laboratorio
## Laboratorio de contenedores y Kubernetes local

> **Curso:** Laboratorio de contenedores y Kubernetes local · De laboratorio
> **Usado por:** todas las fases · **Versiones cubiertas:** las de este documento, que es el único sitio del curso donde vive una versión
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64 (MacBook Pro M1 Pro, 32 GB) · Windows 11 y Linux: no verificados por el autor; se confirman al hacer el curso

**Esto no se lee de corrido.** Se entra buscando una versión, una tarea o un número de memoria, y se
sale. Es el plano del laboratorio: qué versión de cada pieza, qué hace cada tarea del Taskfile y qué
comando corre debajo, cómo se elige el motor, cuánta memoria pide cada perfil y cómo corren los
scripts.

**Qué queda fuera:** instalar las herramientas, que es la [Fase 00](00-el-ambiente.md); explicar qué hace cada una, que
es la fase que la estrena; y enseñar Python o `venv`.

---

## Índice

- [Versiones fijadas](#-versiones-fijadas)
- [El Taskfile, tarea por tarea](#️-el-taskfile-tarea-por-tarea)
- [El motor activo](#-el-motor-activo)
- [Los perfiles y sus interruptores](#-los-perfiles-y-sus-interruptores)
- [La memoria que ocupa cada perfil](#-la-memoria-que-ocupa-cada-perfil)
- [Los scripts](#-los-scripts)
- [La CA del laboratorio en el llavero](#-la-ca-del-laboratorio-en-el-llavero)
- [Cuándo usar qué](#-cuándo-usar-qué)
- [Advertencias](#️-advertencias)
- [Referencias](#-referencias)
- [Ejercicios](#-ejercicios-8)

---

## 📌 Versiones fijadas

**La regla (D17):** cada pieza en su última versión LTS y, donde no hay línea LTS, en su última
estable, a la fecha de verificación. Con una condición que no estaba escrita y que la verificación
hizo explícita: **la última estable que soportan todas las piezas juntas**. Por eso el nodo de
Kubernetes va en 1.36 y no en 1.37: el controlador de Gateway del curso todavía no soporta la 1.37.
Las imágenes se fijan por digest; el tag es el nombre legible.

### En tu máquina

| Herramienta | Versión | Notas |
|---|---|---|
| Docker Desktop · Docker Engine | 4.92.0 · 29.8.0 | |
| Podman · Podman Desktop | 6.1.3 · 1.29.3 | en macOS, con el instalador oficial; máquina con libkrun |
| kind | 0.33.0 | |
| kubectl | 1.36 o 1.37 | cualquiera de las dos sirve con el nodo 1.36 ([a02](a02-problemas-del-ambiente.md#kubectl-no-es-el-que-instalaste)) |
| Helm · helm-diff | 4.3.0 · 3.15.15 | helm-diff firmado, con `--keyring` ([a02](a02-problemas-del-ambiente.md#helm-no-instala-helm-diff-pubringgpg-no-such-file-or-directory)) |
| Task (go-task) | 3.54.0 | |
| k9s | 0.51.0 | |
| Hurl | 8.0.1 | |
| k6 | 2.3.0 | |
| hyperfine | 1.20.0 | |
| dive | 0.13.1 | |
| Python | 3.12 o superior | el `venv` hereda la del sistema; el seed se verificó con 3.13.4 |
| openssl | 3.6.4 | |
| k3d | 5.9.0 | **solo [Fase 07](07-el-cluster-local.md)**; levanta k3s v1.35.5+k3s1 por defecto |
| minikube | 1.39.0 | **solo [Fase 07](07-el-cluster-local.md)**; levanta Kubernetes v1.37.0 por defecto |
| Kubernetes de Docker Desktop | 1.36.1, modo kind | **solo [Fase 07](07-el-cluster-local.md)**; se enciende en la configuración de Docker Desktop |
| BuildKit (el de Docker Desktop) | 0.33.0 | **solo [a06](a06-arquitecturas-y-multiplataforma.md)**: el almacén de imágenes de containerd y Rosetta para amd64 vienen encendidos; verificado el 05/10/2026 |
| Buildah | 1.43.4 | **solo [a07](a07-imagenes-sin-docker.md)**, en un contenedor: `quay.io/buildah/stable@sha256:fcbe1d59ab8eeef2fcf73a7b1fced65a55f49fdef878ac9570cca4ab24b41779` (`v1.43.4`) |
| Kaniko (el fork mantenido) | 1.25.19 | **solo [a07](a07-imagenes-sin-docker.md)**: `registry.gitlab.com/gitlab-ci-utils/container-images/kaniko@sha256:7795cec509a50a71378cc2c365f55c555ee3a05834d8eb1cd2552df5e66d44d8` (`v1.25.19-debug`); el original de Google está archivado |
| ko · Jib (`jib-maven-plugin`) | 0.19.1 · 3.5.2 | **solo [a07](a07-imagenes-sin-docker.md)**: ko con `go install` dentro de la imagen de Go de `pricing`; Jib por Maven, sin instalar nada |
| GraalVM CE (`native-image`) | 25.0.2 | **solo [a08](a08-la-jvm-nativa.md)**, para construir: `ghcr.io/graalvm/native-image-community@sha256:0d936f32bb8acb5bc60c41b33e05f064d7a6aaf36b726538296c54949bd4a3c0` (`25`); la base de la imagen nativa, `gcr.io/distroless/base-debian13@sha256:a0d70d6a97cd697d9362bc2aae4a6560dd65817e365d0043b07325a97975dc91` (`nonroot`); la compilación pide entre 5,3 y 6,0 GB |

### En el cluster

| Pieza | Versión | Referencia |
|---|---|---|
| Nodo de Kubernetes | 1.36.4 | `kindest/node@sha256:099e049362a1526b2db71494e1947aae99bd16290d7c895f2b7ea312e3cbfaed` |
| Envoy Gateway | 1.9.2 | chart `oci://docker.io/envoyproxy/gateway-helm`; trae Gateway API **1.6.1**, canal experimental |
| metrics-server | 0.9.0 | `registry.k8s.io/metrics-server/metrics-server@sha256:d9862115e7c7881280d3d75ca26bda8ffc0fc213315979575bf23ce9826205c0`; el manifiesto de la release, en `platform/metrics-server/`, con `--kubelet-insecure-tls` en kind |
| cert-manager · trust-manager | 1.21.2 · 0.25.0 | charts `oci://quay.io/jetstack/charts/…`, con cada imagen fijada por digest en `platform/cert-manager/*-values.yaml` (F19) |
| Prometheus | 3.13.4 (**LTS**) | `prom/prometheus@sha256:87861b8cf91579109319ebc300f3f1060e6da9c05d6ae8ad15a20c879e84e32e` |
| Grafana | 13.2.3 | `grafana/grafana@sha256:b28bae15e219c998fb0e0424ed724930cc61b1f61fb404d47c862f9a23f9e572` |
| Loki | 3.7.8 | `grafana/loki@sha256:1107dd5274e0ada47e42472b7a7e71f3b2a2fe878878108f3e2f9e51528f0193` |
| Fluent Bit | 5.1.3 | `fluent/fluent-bit@sha256:c5542543523c9678398dd78d927c05e8425ec15b038f226b67b3b019b1a70845` |
| Tempo | 3.1.0 | `grafana/tempo@sha256:3076b8dcdfb32fd6bc5ccef85e7b7313e6199b9cb84366257fc17ecb696db5fd` |
| PostgreSQL | 18.6 | `postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722` |
| Valkey | 9.1.2 | `valkey/valkey@sha256:48332870af354a799964c0012ae1194a0bf2bf894eb508f945810596dc2d8d11` (`9.1.2-alpine`, desde la [Fase 25](25-la-coreografia.md); B-00 se midió con la variante Debian, `…@sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd`) |
| NATS Server | 2.15.0 | `nats@sha256:ac8f88a6494bffc2c2a5289a0ca61cb28a9145c11ba5677cf24265d07f46d8d4` (`2.15.0-alpine`, desde la [Fase 25](25-la-coreografia.md): con shell, para leer `/jsz` con `wget` dentro del pod; B-00 se midió con la de *scratch*, `…@sha256:cd3fcd4ecdda44e3a66728a5334af0a959bc3979b32810e033d1c547241cd0f4`) |
| Istio ([a10](a10-service-mesh.md)) | 1.31.1 | charts `base`, `istiod`, `cni` y `ztunnel` de `https://blob.istio.io/istio-release/charts` (el repositorio de `storage.googleapis.com` no tiene la 1.31.1); imágenes `istio/pilot` y `istio/install-cni` `1.31.1-distroless` e `istio/ztunnel` `1.31.1`, las que fija el chart; verificado el 05/10/2026 |
| Argo CD ([a11](a11-gitops-de-lectura.md)) | 3.5.3 | el manifiesto `https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.3/manifests/install.yaml`, con `--server-side`; imágenes `quay.io/argoproj/argocd:v3.5.3`, `ghcr.io/dexidp/dex:v2.45.1` y `redis:8.2.3-alpine`, las del manifiesto; Flux 2.9.6, nombrado y no instalado; verificado el 05/10/2026 |
| Headlamp ([a14](a14-las-gui.md)) | 0.45.0 | chart `headlamp/headlamp` 0.45.0 de `https://kubernetes-sigs.github.io/headlamp/`; imagen `ghcr.io/headlamp-k8s/headlamp@sha256:db3f0e0fc58d358d41daa3fe7fc852437552c7ee873c3645470f7b86a8e0db49` (`v0.45.0`); verificado el 05/10/2026 |
| nats-box ([a15](a15-statefulset-de-varios-miembros.md)) | 0.20.0 (CLI `nats` 0.5.0) | `natsio/nats-box@sha256:be25666441c3aee65193aba33d60ff2f06ede7ee9eba58864324b33d7eb94fea` (`0.20.0-nonroot`); el NATS de tres miembros usa la misma imagen del servidor de arriba; verificado el 05/10/2026 |
| cloud-provider-kind (F10) | 0.12.0 | `registry.k8s.io/cloud-provider-kind/cloud-controller-manager@sha256:1b97632e5dfec8f83c7e970cf18cedb9e6b707e272011d712cabf6ab59d323c9`; solo con Docker |
| Registry propio (F19) | 3 | `registry@sha256:ddf754342cfc8acc51a56d5d0ab6af06826461864460636d8bd5c546dab2a7b8` |
| Contenedor efímero de depuración (F21) | busybox 1.37 | `busybox@sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e`; para `jcmd`, la imagen del JDK de `inventory` |
| Swagger UI | 5.33.1 | `swaggerapi/swagger-ui:v5.33.1`, fuera del cluster |

### Para construir los servicios

| Runtime | Versión | Imagen |
|---|---|---|
| Go (`pricing`) | 1.27.1 | `golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414` (`1.27.1-alpine`) |
| — su base | distroless | `gcr.io/distroless/static-debian13@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3` (`nonroot`) |
| Java (`inventory`) | 25.0.4 (**LTS**) | `eclipse-temurin@sha256:8c0a84ea11c8f6ed52600fc19f1040121f2a162998e9f50a5faebbbad9172dcc` (`25-jdk`) · `…@sha256:fcd7fd7b387f94bb2ac461478a7436ad8e349924c374ea8313919624dceae636` (`25-jre`) |
| Spring Boot | 4.1.1 | |
| PHP (`catalog`) | 8.5.11 | `php@sha256:fa01fb1645cd0fc566a5f146b099adace33b906571f972f71f2182a7c12d1cd7` (`8.5-fpm-alpine`) · `php@sha256:93684051146ec037620855feb77f278090bde45ddc030801cd3f2a7685bc4deb` (`8.5.11-cli-alpine`) |
| Laravel · Composer | 13 · 2.10.3 | `composer@sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac` |
| Node.js (`replenish`, `storefront`) | 24.21.0 (**LTS**) | `node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1` (`24.21.0-alpine`) |
| NestJS · React · Vite | 12.1 · 19.3 · 8.3 | |
| SQLite de G1 ([Fase 09](09-los-cuatro-servicios-dentro.md)) | `modernc.org/sqlite` 1.60.1 (Go puro) · `sqlite-jdbc` 3.53.2.1 · `node:sqlite` de Node · `pdo_sqlite` de la imagen de PHP | los cuatro sin compilar nada en la imagen; el de Java trae su biblioteca nativa para glibc |
| Postgres de G3 ([Fase 12](12-estado-y-almacenamiento.md)) | `github.com/jackc/pgx/v5` 5.11.0 (Go puro) · `org.postgresql:postgresql` 42.7.13 (la de Spring Boot) · `pdo_pgsql` (compilada en la imagen con las cabeceras de libpq) · `pg` 8.23.1 | solo `catalog` compila algo, y borra las cabeceras al terminar |
| Pruebas de `pricing` ([Fase 12](12-estado-y-almacenamiento.md), B-12) | `testcontainers-go` 0.44.0, con su módulo `postgres` · Ryuk 0.14.0 | `testcontainers/ryuk@sha256:7c1a8a9a47c780ed0f983770a662f80deb115d95cce3e2daa3d12115b8cd28f0`, que Testcontainers baja solo; con Docker, verificado; con Podman, no |
| `/metrics` de G6 ([Fase 17](17-metricas-y-dashboards.md)) | `github.com/prometheus/client_golang` 1.24.1 · Actuator y `micrometer-registry-prometheus` (los de Spring Boot) · `promphp/prometheus_client_php` 2.15.1 con APCu 5.1.28 (PECL) · `@prometheus-io/client` 0.16.1 | `prom-client` 15.1.3 quedó deprecado a favor de `@prometheus-io/client`; APCu se compila en la imagen de `catalog` |
| La CA y los certificados del laboratorio ([Fase 19](19-tls-y-certificados.md)) | `cryptography` 50.0.2 (Python, en `scripts/tls/`) | sin `openssl` en la máquina; las claves quedan en `.secrets/tls/` |
| La resiliencia de G9 ([Fase 22](22-resiliencia-y-caos.md)) | `resilience4j-circuitbreaker`, `-retry` y `-micrometer` 2.3.0 | el núcleo, sin la integración con Spring |
| gRPC de G10 ([Fase 23](23-grpc-y-el-balanceo.md)) | `google.golang.org/grpc` 1.84.0 · `protoc-gen-go` 1.36.12 · `protoc-gen-go-grpc` 1.6.1 · `grpc-netty-shaded`, `-protobuf` y `-stub` 1.84.0 · `protobuf-java` 4.36.2 · `protobuf-maven-plugin` 0.6.1 (con `protoc` 4.36.2 y `os-maven-plugin` 1.7.1) | el código de Go se genera con `task proto` dentro de `golang:1.27.1-alpine`, con el `protoc` de Alpine (6.31.1, el que dice la cabecera de `pricingv1/`); el de Java, en el build de Maven |
| Las trazas de G10 ([Fase 23](23-grpc-y-el-balanceo.md)) | OpenTelemetry para Go 1.44.0 (con `otelhttp` y `otelgrpc` 0.69.0) · el agente de Java 2.32.0, con `opentelemetry-api` 1.62.0 (la de Spring Boot) en `inventory` · `@opentelemetry/auto-instrumentations-node` 0.80.0 con `@opentelemetry/api` 1.9.0 · la extensión `opentelemetry` 1.4.2 (PECL) con `open-telemetry/sdk` 1.15.0, `exporter-otlp` 1.4.0 y `opentelemetry-auto-laravel` 1.9.1 | el agente de Java se baja en el build con `--checksum=sha256:f787eb6c7f3d18e69a431e108a15278d25ee37f83d68b678f621e063f3988f82` |
| El bus de G12 y G13 ([Fase 25](25-la-coreografia.md), [Fase 26](26-idempotencia-y-outbox.md)) | `io.valkey:valkey-java` 5.5.0 (la continuación de Jedis) · `iovalkey` 0.4.0 (la de ioredis) · `@nats-io/transport-node` y `@nats-io/jetstream` 3.4.0 · `io.nats:jnats` 2.26.3, solo en G12 · el publicador del outbox, `github.com/nats-io/nats.go` 1.54.0 y `pgx` 5.11.0 | el publicador se compila en el Dockerfile de `inventory` con la misma imagen de Go de `pricing` |
| nginx sin privilegios (`storefront`, y delante de `catalog`) | 1.30.5 (línea **estable**) | `nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e` (`1.30.5-alpine`; verificado el 03/10/2026, en la [Fase 04](04-empaquetar-los-cuatro-runtimes.md)) |

### Para el patrimonio (`a16`)

| Pieza | Versión | Imagen |
|---|---|---|
| Eclipse GlassFish | 8.0.4, con JDK 21 | `ghcr.io/eclipse-ee4j/glassfish@sha256:29269d033eb2b1dbdd11fef0a0b119106792e6d8a963da395066da676a2f5faa` |
| Maven (build de Contingencia) | 3.10.0, JDK 21 | `maven@sha256:1f4555322b25bc65c1ae2b87d0558047754ef766abf9bd8a0df8bd342d136eb5` |
| Hibernate ORM · driver de Postgres | 7.4.11 · 42.7.13 | dentro del WAR · en `glassfish/lib`, con checksum |
| Python (aviso de traslados) | 3.14.8 | `python@sha256:8acac70227ce3b34da9453120c375cc5b66cd0b062d4dc6bc74286f81a3819e1` (`3.14.8-alpine`) |

> 📝 **nginx va en su línea estable**, la 1.30, y no en la principal (1.31.6 el 03/10/2026), que es a
> la que apunta el tag `alpine` de la imagen: D17 pide la estable donde no hay LTS.

> 📝 Todas las imágenes de las tablas tienen variante `linux/arm64` nativa: nada del laboratorio
> corre bajo emulación en Apple Silicon. Los digests son del índice multiplataforma, así que valen
> igual en una máquina amd64.

---

## ⌨️ El Taskfile, tarea por tarea

`src/lab/Taskfile.yml` es el punto de entrada único. Cada tarea es corta a propósito, y aquí está
lo que corre debajo, para que puedas prescindir del Taskfile cuando quieras. Están todas; `task --list` las
muestra con su descripción.

| Tarea | Qué corre debajo |
|---|---|
| `task engine:status` | `python3 scripts/engine/engine.py status` |
| `task engine:use -- podman` | `python3 scripts/engine/engine.py use podman` |
| `task engine:stop -- docker` | `python3 scripts/engine/engine.py stop docker` |
| `task cluster:up -- minimo` | `kind create cluster --config kind/cluster-minimo.yaml` y `kubectl wait --for=condition=Ready nodes --all` |
| `task cluster:down -- minimo` | `kind delete cluster --name minimo` |
| `task cluster:list` | `kind get clusters` |
| `task images:load -- minimo` | Docker: `kind load docker-image lab/<svc> --name minimo`; Podman: `podman save` y `kind load image-archive`, para los cinco ([Fase 05](05-los-dos-motores.md)) |
| `task build -- pricing` | `<motor> build -t lab/pricing services/pricing` |
| `task build:all` | lo mismo para los cinco, en el orden de la matriz |
| `task compose:up` | `task build:all` y `<motor> compose -f compose/compose.yaml up -d` con los cinco servicios y el nginx de `catalog` |
| `task compose:down` | `<motor> compose -f compose/compose.yaml rm --stop --force` de esos mismos seis |
| `task conformance -- G0` | `<motor> compose -f compose/compose.yaml --profile conformance run --rm conformance`, con el paso en `STEP` |
| `task contracts:docs` | `<motor> compose -f compose/compose.yaml --profile docs up -d contracts-docs` |
| `task legacy:up` | `<motor> build` de las cuatro imágenes del patrimonio y `<motor> compose -f compose/compose.yaml --profile legacy up -d` |
| `task legacy:down` | `<motor> compose -f compose/compose.yaml --profile legacy down` (con `-- -v`, también borra los datos) |
| `task seed:generate` | crea `scripts/seed/.venv` si hace falta y corre `.venv/bin/python generate.py` |
| `task measure -- B-00` | `python3 scripts/measure/measure.py B-00 --engine <motor>` |
| `task measure -- B-05` | `python3 scripts/measure/measure.py B-05 --engine <motor>`, con el otro motor apagado ([Fase 05](05-los-dos-motores.md)) |
| `task measure -- B-04` | `python3 scripts/measure/measure.py B-04 --engine <motor>`: build en frío y con caché, tamaño y primer 200 de cada servicio ([Fase 04](04-empaquetar-los-cuatro-runtimes.md)) |
| `task measure -- B-07` | `python3 scripts/measure/measure.py B-07 --engine <motor> --tool kind\|k3d\|minikube` ([Fase 07](07-el-cluster-local.md)) |
| `task measure -- B-12` | `python3 scripts/measure/measure.py B-12 --engine <motor>`: `task test:pricing` contra SQLite y contra Postgres ([Fase 12](12-estado-y-almacenamiento.md)) |
| `task deploy -- minimo` | desde la [Fase 13](13-helm-el-paquete.md): `kubectl apply -f deploy/manifests/namespace.yaml`, `task seed:image` y `helm upgrade --install lab charts/platform -n apps -f charts/platform/values-minimo.yaml --set <svc>.image.tag=…` (los de `STEP_TAGS`) `--wait`, y desde la [Fase 14](14-helm-en-operacion.md) `--rollback-on-failure --history-max 10`; con `FORCE=true`, además `--force-conflicts`. Hasta la [Fase 12](12-estado-y-almacenamiento.md) era `task migrate` y `kubectl apply -R -f deploy/manifests/` |
| `task deploy -- lab` · `task deploy -- medicion` | lo mismo con `values-lab.yaml` o `values-medicion.yaml`; `medicion` va al cluster `minimo` salvo `CLUSTER=lab` ([Fase 13](13-helm-el-paquete.md)) |
| `task deploy TENANT=tenant-b -- minimo` | el mismo `helm upgrade --install`, como release `tenant-b` en `apps-b`, con `-f charts/platform/values-tenant-b.yaml` encima del perfil ([Fase 14](14-helm-en-operacion.md)) |
| `task deploy:diff -- minimo` | `helm diff upgrade` con los mismos argumentos que `task deploy`, y `--three-way-merge --context 2` ([Fase 14](14-helm-en-operacion.md)) |
| `task platform:postgres TENANT=tenant-b -- minimo` | `kubectl apply -f platform/tenants/apps-b.yaml`, los `Secret` de `credentials.py --tenant tenant-b`, y el SQL de `--sql` por `psql` dentro de `postgres-0` ([Fase 14](14-helm-en-operacion.md)) |
| `task platform:metrics -- lab` | `kubectl apply -f platform/metrics-server/components.yaml` y un `patch` que agrega `--kubelet-insecure-tls` ([Fase 16](16-escalado-y-rollout.md), incidente 17) |
| `task measure -- B-16 --runs 3 --rate 300` | `python3 scripts/measure/measure.py B-16 …`: k6 a tasa constante (`bench/b16/rate.js`) contra cada backend con 1, 2 y 3 réplicas, en el cluster `lab` con el perfil `medicion` ([Fase 16](16-escalado-y-rollout.md)) |
| `task chart:compare` | `helm template` con el perfil `minimo`, pasado por `scripts/chart/compare.py` (con su `.venv`), contra `deploy/manifests/` y `deploy/jobs/` ([Fase 13](13-helm-el-paquete.md)) |
| `task conformance TARGET=cluster -- G1` | la misma suite, en un pod de `apps`, con los archivos en un `ConfigMap` ([Fase 09](09-los-cuatro-servicios-dentro.md)); desde la [Fase 13](13-helm-el-paquete.md), sin `-i`: espera a que el pod termine, lee sus logs y sale con su código (con un paso corto, `kubectl run -i` perdía la salida) |
| `task inc:break -- 05` · `task inc:fix -- 05` | `python3 scripts/incidents/inc.py break\|fix 05`: el cambio mínimo que provoca un incidente, y su reparación ([Fase 08](08-el-primer-despliegue.md)); con `PROFILE=lab` (y `CLUSTER=`), en otro cluster que `minimo` |
| `task platform:gateway -- minimo` | `helm upgrade --install eg oci://docker.io/envoyproxy/gateway-helm …` y `kubectl apply -f platform/gateway/` ([Fase 10](10-la-entrada-al-sistema.md)) |
| `task legacy:up TARGET=cluster` | carga las imágenes del patrimonio en el nodo, crea los `ConfigMap` y el `Secret` del portal, y `kubectl apply -f deploy/legacy/` ([Fase 10](10-la-entrada-al-sistema.md)) |
| `task platform:postgres -- minimo` | las credenciales con `scripts/data/credentials.py`, y `kubectl apply -f platform/data/postgres/` ([Fase 12](12-estado-y-almacenamiento.md)) |
| `task migrate -- minimo` | por servicio: `kubectl delete job`, `kubectl apply -f deploy/jobs/<svc>-migrate.yaml` y `kubectl wait --for=condition=complete` ([Fase 12](12-estado-y-almacenamiento.md); desde la 13 son hooks del chart) |
| `task seed:image -- minimo` | construye `lab/seed:g3` y la carga en el nodo ([Fase 13](13-helm-el-paquete.md)) |
| `task seed:job -- minimo` | `task seed:image` y corre `deploy/jobs/seed.yaml` como `Job` suelto ([Fase 12](12-estado-y-almacenamiento.md); desde la 13 lo corre el chart al instalar) |
| `task test:pricing [DB=postgres]` | `go test` de `pricing` en un contenedor de `golang`; con Postgres, con el socket del motor para Testcontainers ([Fase 12](12-estado-y-almacenamiento.md)) |
| `task obs:on -- metrics\|dashboards\|logs\|traces\|all` · `task obs:off -- …` | `python3 scripts/obs/switch.py on\|off <pieza>`, que escribe `.observability.json`, y `task deploy` con el perfil `lab` (o `PROFILE=`) ([Fase 17](17-metricas-y-dashboards.md); logs en la [18](18-logs.md), trazas en la [23](23-grpc-y-el-balanceo.md)) |
| `task obs:status` | `python3 scripts/obs/switch.py show`: qué piezas y qué bus están encendidos en esta máquina |
| `task obs:trace -- <trace_id>` | `python3 scripts/obs/trace.py <trace_id>`: la traza de Tempo como árbol de tiempos ([Fase 23](23-grpc-y-el-balanceo.md)) |
| `task tls:ca` | `scripts/tls/.venv/bin/python scripts/tls/certs.py ca`: la CA del laboratorio en `.secrets/tls/`, una vez ([Fase 19](19-tls-y-certificados.md)) |
| `task tls:gateway -- lab` | `certs.py leaf gateway --dns …` y `kubectl create secret tls lab-tls` en `gateway`: el certificado de la puerta a mano, antes de cert-manager ([Fase 19](19-tls-y-certificados.md)) |
| `task platform:certs -- lab` | `task tls:ca`, `helm upgrade --install` de cert-manager y de trust-manager (`oci://quay.io/jetstack/charts/…`), el `Secret` `lab-ca`, `kubectl apply` de `issuer.yaml` y `bundle.yaml`, y la espera del `Certificate` `lab-tls` ([Fase 19](19-tls-y-certificados.md)) |
| `task registry:up` · `task registry:down` | `certs.py leaf registry` y `<motor> run -d --name lab-registry --network kind -p 127.0.0.1:5001:5000` con el certificado montado; `<motor> rm -f lab-registry` ([Fase 19](19-tls-y-certificados.md)) |
| `task registry:push -- pricing` | `<motor> tag` y `<motor> push localhost:5001/lab/pricing:<tag de STEP_TAGS>` |
| `task registry:trust -- lab` · `task registry:untrust -- lab` | por cada nodo: copia la CA y `platform/registry/hosts.toml` a `/etc/containerd/certs.d/lab-registry:5000/`, o la borra (el estado del incidente 24) |
| `task chaos:on` · `task chaos:off` | `<motor> build -t lab/chaos:f22 chaos`, `kind load`, `scripts/obs/switch.py chaos on catalog` y `task deploy CLUSTER=lab -- minimo`; al apagar, `switch.py chaos off` y el mismo `task deploy` ([Fase 22](22-resiliencia-y-caos.md)) |
| `task chaos:set -- latencyMs=5000 latencyPercent=100` | `python3 scripts/chaos/chaos.py set …` (o `clear`, `show`, `perfil sogamoso-con-lluvia`): cambia las fallas en caliente, sin redesplegar |
| `task proto` | `protoc` con `protoc-gen-go` y `protoc-gen-go-grpc` en un contenedor de `golang`: genera `services/pricing/pricingv1/` desde `contracts/proto/` ([Fase 23](23-grpc-y-el-balanceo.md)) |
| `task measure -- B-23 --runs 3 --rate 20` | `python3 scripts/measure/measure.py B-23 …`: cómo se reparten las llamadas gRPC entre réplicas, por modo de balanceo ([Fase 23](23-grpc-y-el-balanceo.md)) |
| `task chaos:on TARGET=replenish` | el generador de caos de la [Fase 22](22-resiliencia-y-caos.md) entre `inventory` y `replenish` en vez de `catalog`: `scripts/obs/switch.py chaos on replenish` y `task deploy` ([Fase 24](24-la-saga-orquestada.md)) |
| `task bus:on -- nats` · `task bus:off -- nats` | `kubectl apply -f platform/data/nats/` (o `valkey/`), `scripts/obs/switch.py bus on nats` y `task deploy`; al apagar, al revés, y el PVC de NATS queda ([Fase 25](25-la-coreografia.md)) |

Todas las de cluster pasan el motor a kind con `KIND_EXPERIMENTAL_PROVIDER`, que el Taskfile fija
en cada llamada. La primera vez se ve así:

```text
$ task cluster:up -- minimo
task: [cluster:up] kind create cluster --config kind/cluster-minimo.yaml
using docker due to KIND_EXPERIMENTAL_PROVIDER
Creating cluster "minimo" ...
 ✓ Ensuring node image (kindest/node:v1.36.4) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-minimo"
task: [cluster:up] kubectl --context kind-minimo wait --for=condition=Ready nodes --all --timeout=180s
node/minimo-control-plane condition met
```

Un perfil que no existe se rechaza antes de llamar a kind:

```text
$ task cluster:up -- maximo
task: Perfil desconocido: maximo. Usa minimo o lab.
task: Failed to run task "cluster:up": task: precondition not met
```

**Los dos archivos de kind** (`kind/cluster-minimo.yaml` y `kind/cluster-lab.yaml`) tienen tres
decisiones que conviene conocer antes de la fase que las usa:

- **El nodo por digest**, en la versión de la tabla de arriba.
- **`extraPortMappings`** de `127.0.0.1:8080` y `127.0.0.1:8443` del host a los puertos 30080 y 30443
  del nodo: es por donde entra el tráfico al `Gateway` desde la [Fase 10](10-la-entrada-al-sistema.md). Solo en `127.0.0.1`, y en
  puertos sin privilegios, porque Podman sin root no puede publicar el 80 ni el 443.
- **`containerdConfigPatches`** con `config_path = "/etc/containerd/certs.d"`: no cambia nada hasta
  la [Fase 19](19-tls-y-certificados.md), y tenerlo desde el principio evita recrear el cluster cuando llegue el registry propio.

---

## 🐳 El motor activo

El laboratorio trabaja con un motor a la vez, y lo guarda en `src/lab/.engine.env` (que no se
versiona): una sola línea, `LAB_ENGINE=docker` o `LAB_ENGINE=podman`. El Taskfile lo lee con
`dotenv`, y sin ese archivo asume Docker, que es el camino principal del curso.

`scripts/engine/engine.py` reemplaza al script de PowerShell del material preliminar, y por una
razón de fondo: un script no puede cambiar las variables de entorno de la terminal que lo llamó en
macOS ni en Linux. Así que no toca `DOCKER_HOST`, `CONTAINER_HOST` ni `KIND_EXPERIMENTAL_PROVIDER`
globales; deja el motor en el archivo, y cada tarea se lo pasa a quien lo necesita. Hace tres
cosas:

- **`status`** pregunta a cada motor si **responde** (`docker info`, `podman info`), no lo que dice
  su interfaz, y muestra la memoria de su máquina virtual y el estado de la máquina de Podman.
  Termina con error si el motor activo no responde.
- **`use`** arranca el motor si no responde (`docker desktop start`, `podman machine start`),
  espera a que conteste y lo deja activo. Si el otro también está encendido, avisa: conviven, pero
  suman memoria, y un cluster de cada uno no puede publicar a la vez el puerto 8080.
- **`stop`** lo detiene y comprueba que de verdad se detuvo.

```text
$ task engine:use -- podman
task: [engine:use] python3 scripts/engine/engine.py use podman
Motor activo: podman.
Aviso: docker también está encendido. Conviven, pero suman memoria, y un cluster de cada uno no puede publicar a la vez el puerto 8080. Si no lo usas: task engine:stop -- docker
$ task engine:status
task: [engine:status] python3 scripts/engine/engine.py status
Motor activo del laboratorio: podman  (.engine.env)
  ✅ docker responde, versión 29.8.0 · memoria de la VM 3.8 GiB
  ✅ podman responde, versión 6.1.3 · memoria de la VM 3.8 GiB
           máquina: running
```

Con Podman activo, `task cluster:up -- minimo` dice `using podman due to KIND_EXPERIMENTAL_PROVIDER`
y crea el mismo cluster, sin que cambies nada más.

> ⚠️ **Windows y Linux: no verificado por el autor.** En Linux con Docker Engine (sin Docker Desktop),
> `use` y `stop` llaman a `systemctl`; en Linux, Podman no tiene máquina virtual y `status` lo dice.

---

## 📦 Los perfiles y sus interruptores

| Perfil | Cluster | Qué corre | Dónde se usa |
|---|---|---|---|
| `minimo` | kind de un nodo | los servicios y Postgres; todo lo demás apagado | Partes 0–II, salvo las excepciones |
| `lab` | control-plane y dos workers | lo que la fase encienda | F07, F16, F18, Partes III y IV |
| `medicion` | el que declare la medición | solo lo medido y su generador de carga | cada 📏 |
| `legacy` | ninguno: compose | el patrimonio, hasta que entra al cluster en la [Fase 10](10-la-entrada-al-sistema.md) | `a16`, F02 a F10 |

Los interruptores de la observabilidad y del bus de mensajes son valores del chart desde la
[Fase 13](13-helm-el-paquete.md) (`observability.*.enabled` y `bus.*.enabled`, en `charts/platform/values.yaml`), y cada perfil
es un archivo de valores (`values-<perfil>.yaml`). Todos empiezan apagados.

---

## 📏 La memoria que ocupa cada perfil

**B-00 es la medición de preparación del curso**: cuánta memoria de la máquina virtual de cada motor
ocupa cada perfil, para que sepas cuánta darle. Se publica en tres entregas: la infraestructura (esta
tabla), el patrimonio (abajo) y los cinco servicios, que se suman con la [Fase 02](02-compose-el-sistema-en-un-archivo.md).

> 📏 **Medición B-00 · La memoria de cada perfil, sin los servicios** · perfiles `minimo`, `lab` y
> `legacy` · Docker Desktop 4.92.0 (Engine 29.8.0) y Podman 6.1.3, **los dos con 4 GiB de máquina
> virtual** · kind 0.33.0, nodo 1.36.4 · MacBook Pro M1 Pro, 32 GB, macOS 26.7.1 · 3 corridas por
> celda, cada una con el cluster creado desde cero · verificado el 03/10/2026
>
> **Qué se midió:** la memoria usada de la máquina virtual (`MemTotal − MemAvailable`, leída desde
> el nodo, que comparte su `/proc/meminfo`), en MiB, 60 s después de que todo está listo. "Todo
> encendido" es el cluster con el controlador de Gateway, metrics-server, Postgres, Valkey, NATS,
> Prometheus, Grafana, Loki con Fluent Bit, Tempo, cert-manager y trust-manager.
>
> | Momento | Docker `minimo` | Podman `minimo` | Docker `lab` | Podman `lab` |
> |---|---|---|---|---|
> | máquina virtual disponible | 3.916 | 3.886 | 3.916 | 3.886 |
> | cluster recién creado | 1.163 (1.124–1.210) | 1.172 (1.171–1.259) | 1.329 (1.326–1.333) | 1.348 (1.331–1.353) |
> | + Gateway y metrics-server | 1.562 (1.538–1.608) | 1.558 (1.511–1.718) | 1.794 (1.771–1.808) | 1.826 (1.801–1.832) |
> | todo encendido | 2.339 (2.275–2.385) | 2.278 (2.275–2.330) | 2.400 (2.373–2.478) | 2.476 (2.456–2.527) |
> | creación del cluster (s) | 29 (27–30) | 31 (31–35) | 37 (33–38) | 37 (36–43) |
>
> Mediana, con mínimo y máximo entre paréntesis. Reproducir: `task measure -- B-00 --profile minimo`
> (o `lab`) con el motor activo.

**Lo que dice la tabla.** Con la misma memoria asignada, **los dos motores ocupan lo mismo**: la
diferencia entre ellos es menor que la dispersión de cada uno. Los dos workers del perfil `lab`
suman poco en reposo (unos 170 MiB con el cluster vacío). Y con todo encendido queda alrededor del
40 % de la máquina libre, que es el lugar de los servicios.

**Qué pieza pesa cuánto**, en el perfil `minimo` con todo encendido, sumando el *working set* de
sus contenedores (mediana de tres corridas, en MiB):

| Pieza | Docker | Podman |
|---|---|---|
| plano de control, kindnet, CoreDNS, kube-proxy y metrics-server (`kube-system`) | 913 | 969 |
| observabilidad completa | 552 | 467 |
| cert-manager y trust-manager | 125 | 98 |
| Envoy Gateway, controlador y proxy | 93 | 79 |
| Postgres, Valkey y NATS | 46 | 38 |

**Grafana es, solo, la pieza más cara de la observabilidad**: en la verificación de laboratorio
ocupó 359 MiB en reposo, once veces lo que ocupó Prometheus. Es la primera que conviene apagar si
la máquina aprieta. Y el servidor de API crece con cada CRD que se instala: con las de Gateway API
ya ocupaba 575 MiB, la pieza más grande del cluster.

> 📏 **El perfil `legacy` (el patrimonio en compose, sin cluster)** · mismas condiciones · 3
> corridas
>
> | | Docker | Podman |
> |---|---|---|
> | máquina virtual antes de levantarlo | 754 (727–760) | 647 (623–656) |
> | con el patrimonio en reposo | 1.531 (1.520–1.565) | 1.364 (1.356–1.384) |
> | **lo que suma** | **804 (766–805)** | **709 (708–761)** |
> | de eso, Contingencia (GlassFish) | 684 (676–685) | 644 (629–645) |
> | hasta que Contingencia despliega (s) | 43 (43–44) | 38 (38–38) |
>
> Reproducir: `task measure -- B-00 --profile legacy`, con las imágenes ya construidas
> (`task legacy:up` una vez).

> 📏 **Los cinco servicios del paso G0, en compose** (la tercera entrega, de la [Fase 02](02-compose-el-sistema-en-un-archivo.md)) · mismas
> condiciones · 3 corridas · listos cuando su suite de conformidad pasa
>
> | | Docker | Podman |
> |---|---|---|
> | **lo que suman los cinco** | **446 (444–461)** | **421 (398–424)** |
> | `inventory` (Java) | 236 (231–244) | 212 (212–217) |
> | `storefront` (Node, `vite preview`) | 92 (91–94) | 90 (90–92) |
> | `catalog` (PHP) | 56 (56–56) | 56 (56–56) |
> | `replenish` (Node) | 41 (41–42) | 43 (43–44) |
> | `pricing` (Go) | 7 (5–7) | 2 (2–2) |
> | hasta que la suite pasa (s) | 9 (9–9) | 7 (7–7) |
>
> Reproducir: `task measure -- B-00 --profile servicios`, con las imágenes ya construidas
> (`task compose:up` una vez).

Son los servicios de G0, que no hacen nada: la memoria de un servicio con datos y carga es otra
cosa, y la miden las fases que la cambian. Pero la proporción ya dice algo que la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) va a
cobrar: **`inventory` ocupa en reposo más de treinta veces lo que ocupa `pricing`**.

**Cuánta memoria darle a la máquina virtual: 4 GiB, a cualquiera de los dos motores.** Con 4 GiB
entra cualquier perfil sin los servicios, con margen. **La máquina de Podman viene con 2 GiB por
defecto, y con eso no alcanza**: con toda la observabilidad encendida, el servidor de API deja de
contestar ([a02](a02-problemas-del-ambiente.md#el-cluster-deja-de-contestar-tls-handshake-timeout)).
Docker Desktop, en esta máquina, venía con 7,9 GB.

> 📏 **Los cinco servicios de G1, dentro del cluster `minimo`** (la cuarta entrega, de la
> [Fase 09](09-los-cuatro-servicios-dentro.md)) · Docker Desktop 4.92.0, máquina virtual de 4 GiB ·
> mismas condiciones · 3 corridas, cada una con el cluster creado desde cero, 60 s de reposo
>
> | | MiB |
> |---|---|
> | lo que suman los cinco (namespace `apps`, *working set*) | 319 (304–373) |
> | lo que sube la máquina virtual con ellos | 295 (279–337) |
>
> La máquina virtual de esta medición ya venía trabajando, y por eso su punto de partida (1.904–1.960
> MiB con el cluster solo) no es comparable con el de la primera tabla; la diferencia sí lo es.
> Reproducir: crear `minimo`, medir, `task images:load` y `task deploy`, y medir otra vez.
>
> ⚠️ **Con el patrimonio y Postgres encima, 4 GiB quedan justos.** En la verificación de la
> [Fase 12](12-estado-y-almacenamiento.md), con los cinco servicios, el patrimonio en `legacy`, Postgres,
> el ambiente de QA de la [Fase 11](11-configuracion-y-secretos.md) y dos réplicas de `inventory`, el kernel del nodo mató tres veces a
> Contingencia (`OOMKilled`, sin límites declarados: la primera en morir). Sin QA y con una réplica, la
> memoria disponible del nodo quedó cerca de 1 GiB. No es una medición de B-00: es lo que pasó.

> 📏 **La segunda cadena (`tenant-b` en `apps-b`), encima del sistema** (la quinta entrega, de la
> [Fase 14](14-helm-en-operacion.md)) · perfil `minimo` con el release `lab` y Postgres corriendo, sin patrimonio ni
> observabilidad · Docker Desktop 4.92.0, máquina virtual de 4 GiB · 3 corridas: desinstalar, 60 s,
> leer; `task deploy TENANT=tenant-b -- minimo`, 60 s, leer · verificado el 03/10/2026
>
> | | MiB |
> |---|---|
> | lo que sube la máquina virtual con la segunda cadena | 212 (191–227) |
> | máquina virtual usada con las dos cadenas | 2.831–2.901 |
>
> Reproducir: `task platform:postgres TENANT=tenant-b -- minimo` una vez, y medir `MemTotal −
> MemAvailable` del nodo antes y después de instalarla.

> 📏 **La observabilidad, pieza por pieza** (la sexta entrega, de la [Fase 17](17-metricas-y-dashboards.md)) · cluster `lab`
> con los valores de `minimo` · Docker Desktop, máquina virtual de 4 GiB **con el Kubernetes de Docker
> Desktop encendido** · 3 ciclos de apagar y encender, cada lectura 60 s después · *working set* en MiB
>
> | | recién encendida | a los 20 min, con tráfico de fondo |
> |---|---|---|
> | Prometheus, sola | 44 (43–73) | — |
> | Prometheus, con Grafana | 58 (52–90) | 99 |
> | Grafana | 252 (248–254) | 231 |
> | Loki ([Fase 18](18-logs.md)) | 117 | 91, a los 10 min de tráfico |
> | Fluent Bit, por nodo de trabajo | 6 | 6 |
>
> Reproducir: `task obs:off -- all` y `task obs:on` con cada pieza. Loki y Fluent Bit, una sola corrida.

Esta entrega no tiene la columna de las demás (lo que sube la máquina virtual): con el Kubernetes de
Docker Desktop ocupando 764 MiB, la máquina estaba en swap y la memoria usada no se movía al encender nada.
**Pendiente:** repetirla sin él.

**¿Y en un portátil de 8 GB?** Lo medido alcanza para decir esto, y no más: la infraestructura de
`minimo` con todo encendido usa unos 2,3 GiB de una máquina virtual de 4, y los cinco servicios de G0
usan unos 0,4 GiB en compose. Sumarlos no es medirlos juntos; `minimo` con los servicios dentro del
cluster está en la tabla de arriba: unos 0,3 GiB más. Un portátil de 8 GB puede darle 4 GiB a la máquina
virtual; si con eso el sistema operativo y el navegador quedan cómodos, no lo medí.

| Plataforma | `minimo`, todo encendido | `lab`, todo encendido | `legacy` |
|---|---|---|---|
| macOS arm64 (verificado) | 2.278–2.339 MiB | 2.400–2.476 MiB | 709–804 MiB |
| Windows 11 con WSL 2 | *sin medir* | *sin medir* | *sin medir* |
| Linux amd64 | *sin medir* | *sin medir* | *sin medir* |

Las dos últimas filas se llenan al hacer el curso: corre `task measure -- B-00` y agrega tu máquina
debajo, sin reemplazar la del autor.

> 📏 **El bus en reposo** ([Fase 25](25-la-coreografia.md), [Fase 26](26-idempotencia-y-outbox.md)) · `kubectl top pod -n data`
> en el cluster `lab`, una lectura por pieza · Docker Desktop con su memoria por defecto (no los 4 GiB de B-00) · 04/10/2026
>
> | Pieza | Memoria |
> |---|---|
> | Valkey (`9.1.2-alpine`, sin persistencia) | 10 MiB |
> | NATS con JetStream (`2.15.0-alpine`, un servidor) | 12 MiB |
> | el *sidecar* `outbox-relay` de `inventory` | pide 16 MiB, límite de 64 MiB |
>
> Una lectura, no tres: es el orden de magnitud, para saber que el bus no es lo que aprieta la máquina. Lo que la
> aprieta con carga son las trazas: en la [Fase 26](26-idempotencia-y-outbox.md), Tempo llegó a 6,5 núcleos con ráfagas de 13.000 peticiones.

---

## 🐍 Los scripts

Los scripts del laboratorio están en Python, **uno solo para los tres sistemas** en lugar de un
`.sh` y un `.ps1` que se desincronizan en la primera corrección. Viven en
`src/lab/scripts/<sección>/`, y cada directorio que tiene dependencias lleva su `requirements.txt`.
Los que solo usan la biblioteca estándar (`engine/`, `measure/`) no necesitan entorno virtual.

La tarea que invoca un script con dependencias crea el `.venv` del directorio si no existe y las
instala; la segunda vez ve que está al día y no repite nada. **La única diferencia entre sistemas**
que tienes que conocer es dónde queda el intérprete del entorno, y el Taskfile la resuelve con una
variable:

```yaml
PYTHON: '{{if eq OS "windows"}}python{{else}}python3{{end}}'
VENV_PY: '{{if eq OS "windows"}}.venv\Scripts\python.exe{{else}}.venv/bin/python{{end}}'
```

**El ejemplo: el seed.** `scripts/seed/` siembra droguerías y productos sintéticos con Faker en
`es_CO`, con una semilla fija para que dos máquinas generen lo mismo. Un `requirements.txt` de una
línea (`faker==40.40.0`), un script de una treintena de líneas y su tarea. Es el mismo que la Fase
12 empaqueta y corre como `Job`.

**El segundo: el comparador del chart.** `scripts/chart/` tiene `compare.py`, que lee YAML con PyYAML
(`PyYAML==6.0.3`, verificado el 03/10/2026) y compara el chart renderizado con el YAML plano; lo corre
`task chart:compare` desde la [Fase 13](13-helm-el-paquete.md).

```text
$ task seed:generate -- --stores 3
task: [venv] python3 -m venv .venv
task: [venv] .venv/bin/python -m pip install --quiet --disable-pip-version-check -r requirements.txt
task: [seed:generate] .venv/bin/python generate.py --stores 3
{
  "stores": [
    {
      "id": "DRO-001",
      "city": "Piedecuesta",
      "address": "Calle 3X # 5-5",
      "manager": "Eduardo Zambrano Ordóñez"
    },
…
```

La segunda corrida dice `task: Task "venv" is up to date` y tarda 0,19 s en lugar de 3,6 s.

> ⚠️ **Windows y Linux: no verificado por el autor; se confirma al hacer el curso.** En Windows, el
> intérprete del sistema suele llamarse `python` y no `python3`, y el del entorno queda en
> `.venv\Scripts\python.exe`; el Taskfile ya los distingue.

---

## 🔐 La CA del laboratorio en el llavero

La [Fase 19](19-tls-y-certificados.md) crea la CA del laboratorio con `scripts/tls/certs.py ca` y la deja
en `src/lab/.secrets/tls/ca.crt`, con su clave al lado. El curso la usa siempre de forma explícita
(`curl --cacert`, `openssl s_client -CAfile`), y no hace falta más. Esta sección es para el que quiere que
el navegador abra `https://api.localhost:8443` sin aviso, y para deshacerlo después.

> ⚠️ **Lo que estás autorizando.** Una CA raíz de confianza puede firmar un certificado para *cualquier*
> sitio, no solo para `*.localhost`, y su clave privada está sin cifrar en `.secrets/tls/ca.key`. Quien
> tenga ese archivo puede hacerse pasar por tu banco ante tu navegador. Instálala mientras haces las fases
> que la usan y quítala al terminar. La restricción `-p ssl` de abajo impide que firme código o correo,
> pero no le pone límite a los dominios.

### macOS

La forma recomendada usa el llavero de *tu* usuario (`login`) y la confianza de usuario. No pide `sudo`
ni toca a los demás usuarios de la máquina: macOS muestra un diálogo y pide tu contraseña. Los comandos
se corren desde `src/lab/`.

**1. El estado antes.** `security verify-cert` valida un certificado con la confianza del sistema, la
misma que usan Safari y Chrome:

```text
$ security verify-cert -c .secrets/tls/gateway.crt -p ssl -s api.localhost
Cert Verify Result: CSSMERR_TP_NOT_TRUSTED
```

Si le das la CA como ancla, la cadena se valida, y eso confirma que lo único que falta es la confianza:

```text
$ security verify-cert -c .secrets/tls/gateway.crt -r .secrets/tls/ca.crt -p ssl -s api.localhost
...certificate verification successful.
```

**2. Instalar.** Este comando agrega el certificado al llavero `login` y lo marca como raíz de confianza
para TLS:

```bash
security add-trusted-cert -r trustRoot -p ssl \
  -k ~/Library/Keychains/login.keychain-db .secrets/tls/ca.crt
```

**3. Comprobar.** El primer `verify-cert` del paso 1, que no lleva `-r`, ahora pasa:

```text
$ security verify-cert -c .secrets/tls/gateway.crt -p ssl -s api.localhost
...certificate verification successful.
---
No extended validation result found
Certificate Transparency (CT) status: not verified
Unable to find at least 2 signed certificate timestamps (SCTs) from approved logs
```

Las tres líneas de abajo son informativas. La transparencia de certificados se exige a las CA públicas,
no a una CA privada que tú agregaste. `dump-trust-settings` confirma que la confianza quedó limitada a TLS:

```text
$ security dump-trust-settings | grep -A4 'La Rebotica'
Cert 0: La Rebotica · CA del laboratorio
   Number of trust settings : 1
   Trust Setting 0:
      Policy OID            : SSL
```

En el navegador, `https://api.localhost:8443/pricing/prices?store=DRO-007`
abre sin aviso. Si Chrome tenía la pestaña abierta, reinícialo: guarda la decisión anterior. En la app
**Acceso a Llaveros**, el certificado aparece en `login` → *Certificados* como «La Rebotica · CA del
laboratorio», con el sello azul de confianza.

**4. Quitar.** Primero se quita la confianza y después el certificado. La huella SHA-1 identifica *esta*
CA y no otra con un nombre parecido (la «otra» del incidente 19, por ejemplo):

```bash
security remove-trusted-cert .secrets/tls/ca.crt
SHA1=$(openssl x509 -in .secrets/tls/ca.crt -noout -fingerprint -sha1 | cut -d= -f2 | tr -d :)
security delete-certificate -Z "$SHA1" ~/Library/Keychains/login.keychain-db
```

`delete-certificate -t` hace las dos cosas en un solo paso: borra el certificado y su confianza de
usuario. Para confirmar que la CA ya no está, vuelve a correr el `verify-cert` del paso 1, que tiene que
regresar a `CSSMERR_TP_NOT_TRUSTED`, y busca el certificado en el llavero:

```bash
security find-certificate -a -c "La Rebotica" ~/Library/Keychains/login.keychain-db   # sin salida
```

**Si ya no tienes el `ca.crt` que instalaste**, porque regeneraste la CA con `--force` o borraste
`.secrets/`, el archivo nuevo no coincide con el del llavero. En ese caso, saca la huella del certificado
instalado y bórralo con su confianza:

```bash
security find-certificate -a -c "La Rebotica" -Z ~/Library/Keychains/login.keychain-db | grep SHA-1
security delete-certificate -t -Z <la huella SHA-1> ~/Library/Keychains/login.keychain-db
```

**Para todos los usuarios de la máquina** se usa la confianza de administrador y el llavero del sistema.
Pide `sudo`:

```bash
sudo security add-trusted-cert -d -r trustRoot -p ssl -k /Library/Keychains/System.keychain .secrets/tls/ca.crt
# y para quitarla
sudo security remove-trusted-cert -d .secrets/tls/ca.crt
sudo security delete-certificate -Z "$SHA1" /Library/Keychains/System.keychain
```

`remove-trusted-cert` quita la confianza, **no el certificado**: sin el `delete-certificate`, la CA se
queda en el llavero sin confianza, como un resto que confunde la próxima vez.

**Lo que no lee el llavero.** El `curl` de Homebrew usa el almacén de OpenSSL, así que para él el curso
sigue con `--cacert`. Firefox tiene su propio almacén: para que use el del sistema, pon
`security.enterprise_roots.enabled` en `true` en `about:config`.

> ⚠️ **Lo verificado, y lo que no.** El 05/10/2026, en la máquina del autor (macOS arm64), se ejecutaron
> los pasos 1 a 3 con el llavero `login`: los dos `verify-cert`, la instalación (con el diálogo de
> contraseña), el `verify-cert` que pasa y el `dump-trust-settings`. La prueba en el navegador no se
> hizo, porque no había cluster corriendo. Quitar la CA, la variante para todos los usuarios y el caso
> sin el `ca.crt` original tampoco se ejecutaron: esos comandos vienen de `man security`.

### Linux y Windows

| Sistema | Instalar | Quitar |
|---|---|---|
| Linux (Debian/Ubuntu) | `sudo cp .secrets/tls/ca.crt /usr/local/share/ca-certificates/la-rebotica.crt && sudo update-ca-certificates` | `sudo rm /usr/local/share/ca-certificates/la-rebotica.crt && sudo update-ca-certificates --fresh` |
| Windows | `certutil -addstore -f Root .secrets\tls\ca.crt` (como administrador) | `certutil -delstore Root "La Rebotica · CA del laboratorio"` |

> ⚠️ **No verificado por el autor; se confirma al hacer el curso.** En Linux, Chrome y Firefox no leen
> `/usr/local/share/ca-certificates`: usan su propio almacén NSS.

---

## 🧭 Cuándo usar qué

| Necesitas… | Usa | Por qué |
|---|---|---|
| saber si el ambiente está bien | `task engine:status` | pregunta al motor, no a su interfaz |
| cambiar de motor | `task engine:use -- <motor>` | deja el motor en un archivo que lee el Taskfile |
| un cluster para la fase | `task cluster:up -- <perfil>` | el perfil que declara el encabezado de la fase |
| el patrimonio corriendo | `task legacy:up` | construye y levanta las cuatro piezas en compose |
| datos de prueba | `task seed:generate` | semilla fija: mismos datos en toda máquina |
| repetir una medición | `task measure -- <id>` | mismo arnés que la publicada |
| que el navegador confíe en el HTTPS del laboratorio | la CA en el llavero | y quitarla al terminar: firma para cualquier sitio |

---

## ⚠️ Advertencias

- **Ninguna versión vive fuera de este documento.** Si una fase muestra un número de versión, es
  una cita de aquí o una salida de terminal fechada.
- **Las versiones envejecen.** Si al hacer el curso una ya no se consigue, usa la siguiente de la
  misma línea y anótalo; si cambia de línea mayor, la fase que la usa puede necesitar ajustes.
- **No corras un cluster de cada motor a la vez**: los dos quieren `127.0.0.1:8080`, y el segundo no
  arranca.
- **La máquina virtual de cada motor necesita 4 GiB** (la tabla de memoria dice por qué). La de
  Podman viene con 2 por defecto.
- **Apaga el Kubernetes propio de Docker Desktop** (Settings → Kubernetes) si no lo usas: corre en la
  misma máquina virtual, con su nodo, su registry y su balanceador, y en la verificación de la
  [Fase 17](17-metricas-y-dashboards.md) ocupaba 764 MiB de los 4 GiB. Con el perfil `lab` y la observabilidad
  encendida, esa diferencia fue la que dejó a la máquina sin memoria. Si lo usas, súmale esa memoria.

---

## 📚 Referencias

- kind, *Configuration*: https://kind.sigs.k8s.io/docs/user/configuration/ — `extraPortMappings` y
  `containerdConfigPatches`.
- kind 0.33.0, notas de la versión, con los digests de cada imagen de nodo:
  https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0
- Envoy Gateway, *Compatibility Matrix*: https://gateway.envoyproxy.io/news/releases/matrix/ — por qué
  el nodo va en 1.36.
- Kubernetes, *Version Skew Policy*: https://kubernetes.io/releases/version-skew-policy/
- Task, *Guide*: https://taskfile.dev/docs/guide/ — `dotenv`, `vars`, `preconditions` y `sources`.
- Python, *venv*: https://docs.python.org/3/library/venv.html
- Faker, *Locale es_CO*: https://faker.readthedocs.io/en/master/locales/es_CO.html

> ⚠️ Las URL y los contenidos cambian; las de kind y Envoy Gateway apuntan a su versión, las demás
> no.

---

## 🧪 Ejercicios (8)

Cortos y de consulta. Ninguno instala nada: eso es la [Fase 00](00-el-ambiente.md).

**🟢 Fácil (1–3)**

### 🟢 Ejercicio 1 — ¿Está bien el ambiente?
Corre la primera línea de cualquier diagnóstico.

**Criterio:** `task engine:status` termina sin error y la línea de tu motor activo empieza con ✅.

<details><summary>Solución</summary>

`task engine:status`. Si termina con error, la última línea te dice qué correr; si no, mira
[a02](a02-problemas-del-ambiente.md).
</details>

### 🟢 Ejercicio 2 — El cluster de un nodo, y fuera
Crea el cluster `minimo`, compruébalo y bórralo.

**Criterio:** `kubectl --context kind-minimo get nodes` muestra un nodo `Ready` con `VERSION v1.36.4`, y
después de borrarlo `task cluster:list` no lo lista.

<details><summary>Solución</summary>

`task cluster:up -- minimo`, `kubectl --context kind-minimo get nodes`, `task cluster:down -- minimo`.
</details>

### 🟢 Ejercicio 3 — Sin el Taskfile
Crea el mismo cluster sin usar `task`, con el comando que corre debajo.

**Criterio:** el cluster que creaste es igual al del ejercicio 2 (`kubectl get nodes` con la misma
versión), y escribiste el comando exacto que usaste.

<details><summary>Solución</summary>

`KIND_EXPERIMENTAL_PROVIDER=docker kind create cluster --config kind/cluster-minimo.yaml`, desde
`src/lab/`. En PowerShell, `$env:KIND_EXPERIMENTAL_PROVIDER = "docker"` antes del `kind`.
</details>

**🟡 Intermedio (4–5)**

### 🟡 Ejercicio 4 — El mismo cluster con el otro motor
Activa Podman, crea `minimo`, y comprueba con qué motor quedó.

**Criterio:** `podman ps` lista `minimo-control-plane`, `docker ps` no, y `.engine.env` dice
`LAB_ENGINE=podman`.

<details><summary>Solución</summary>

`task engine:use -- podman` y `task cluster:up -- minimo`. Vuelve a Docker al terminar con
`task cluster:down -- minimo` y `task engine:use -- docker`.
</details>

### 🟡 Ejercicio 5 — La semilla manda
Genera los datos dos veces con la misma semilla y una vez con otra.

**Criterio:** las dos corridas con `--seed 2026` son idénticas (`diff` vacío) y distintas de la de la
semilla por defecto.

<details><summary>Solución</summary>

`task seed:generate -- --seed 2026 > a.json`, lo mismo a `b.json`, `diff a.json b.json`, y una vez
sin `--seed`. La semilla fija es lo que deja que dos máquinas tengan los mismos datos.
</details>

**🟠 Difícil (6–7)**

### 🟠 Ejercicio 6 — ¿Sigue vigente este documento?
Comprueba el digest de dos imágenes de las tablas contra el registry.

**Criterio:** para `postgres:18.6` y `kindest/node:v1.36.4`, tu bitácora tiene el digest que da el
registry hoy, la fecha, y si coincide con el de este apéndice.

**Rúbrica:** el comando (`docker buildx imagetools inspect <imagen> --format '{{json .Manifest.Digest}}'`),
las dos salidas, y qué harías si un digest cambió con el mismo tag (pista: nada en el laboratorio
cambia hasta que tú cambias el digest, y esa es la razón de fijarlo).

### 🟠 Ejercicio 7 — Tu propia fila de B-00
Mide el perfil `minimo` en tu máquina, una corrida.

**Criterio:** tienes el resumen de `task measure -- B-00 --runs 1`, y una línea que compara la
**proporción** entre "todo encendido" y "cluster recién creado" con la de la tabla (en la del autor,
alrededor de 2).

**Rúbrica:** el resumen literal, tu máquina declarada (CPU, memoria, plataforma, memoria de la VM) y
la comparación sobre la proporción, no sobre el absoluto.

**🔴 Muy difícil (8)**

### 🔴 Ejercicio 8 — ¿Cuánto es lo mínimo?
Busca la máquina virtual más chica en la que el perfil `minimo` con todo encendido sigue
contestando. **Escribe tu apuesta antes**, en MiB.

**Criterio:** tienes la apuesta, al menos dos mediciones con memorias distintas (una que responde y
una que no), y el síntoma literal de la que no.

**Rúbrica:** la apuesta escrita antes; cada intento con su memoria asignada y su resultado; el
síntoma de la que colapsó; y qué apagarías primero para bajar más (la tabla de piezas lo sugiere).

---

> 🏷️ **Este apéndice deja archivos en el repositorio**: `src/lab/Taskfile.yml`, `src/lab/kind/` y
> `src/lab/scripts/`. Con el Taskfile corriendo en tu máquina, el commit se etiqueta
> `apendice-a01-laboratorio` (ver la [convención de git](00-convencion-de-git-y-tags.md)).
