# 🧪 Las pruebas de la producción de lab-docker-kubernetes

> **Qué es:** el código con el que se verificó el curso `cursos-contenedores-cloud-infra/lab-docker-kubernetes`
> mientras se escribía (P11 y las tandas T0–T16, del 03 al 05/10/2026). Son los scripts, Dockerfile,
> manifiestos y cargas de k6 que vivían en los scratchpads de las sesiones (`/private/tmp/…`, que el
> sistema borra) y los borradores de P11 que quedaron en el `prompts/` del curso.
> **Qué no es:** el laboratorio del curso. Ese es `src/lab/` dentro del curso, y casi todo lo de aquí
> se corre **contra** él.
> **Vigencia:** rescatado el 2026-10-06, copiado sin ejecutar nada.

Los resultados de estas pruebas no están aquí: viven en el curso, en
`prompts/verificacion-de-laboratorio/hallazgos.md` (H1–H270), los logs de
`prompts/verificacion-de-laboratorio/logs/` (P11 en la raíz, cada tanda en `logs/tN/`),
`BENCHMARKS.md` y `src/lab/bench/*/results/`. Este directorio guarda **cómo se obtuvieron**.

---

## 🗂️ Qué hay y de qué sesión salió

| Carpeta | Sesión de origen | Tandas | Fases que verifica |
|---|---|---|---|
| `01-p11-t0-t2/borrador-p11/` | copia de `prompts/verificacion-de-laboratorio/borrador/` del curso | P11 | prerrequisitos, kind, Envoy Gateway, registry, B-00, G0 de `pricing` |
| `01-p11-t0-t2/scratchpad/` | `6c5ff4c5…` (03/10, 00:23–04:52 hora local) | P11, T0–T2 | F00–F02, a16, modelo de tags |
| `02-t3-t5/` | `c9879aea…` (03/10 16:19 → 03/10 23:10) | T3–T5 | F03–F12 (B-04, B-05, B-07, B-12) |
| `03-t6-t10/` | `1c1220f7…` (03/10 23:13 → 04/10 21:44) | T6–T10 | F13–F23 (B-16, B-23, observabilidad, mTLS) |
| `04-t11-t16/` | `ac682bf5…` (04/10 22:33 → 05/10 08:39) | T11–T16 | F24–F27, apéndices 🔥 a06–a15 |
| `05-limpieza/` | `19969a6c…` (05/10) | limpieza final | inventario de imágenes antes y después |

**Lo que se dejó fuera a propósito:**

- **Binarios y artefactos:** `.tar` de `docker save`, `.jar` (el agente de OpenTelemetry y las librerías
  de Spring que se inspeccionaron), el binario de `ko`, las imágenes de `a07/out/`, `target/` y los `venv`.
  Todo se regenera.
- **Salidas pesadas:** los JSON de `dive`, los volcados de la API (`inv.json`, `pr.json`), las capturas de
  Grafana y los logs de las compilaciones nativas de a08.
- **Secretos:** los `.env` y el `postgres.env.bak` (contraseñas de prueba generadas), y la copia `pf/lab/`
  del proyecto final, que era un clon de `src/lab/` con su `.secrets/` (claves TLS incluidas).
- **Borradores de prosa:** los `fNN-ej.md` (ejercicios) y los `incNN.md` (incidentes), que ya están en el
  curso. Las notas `sNN.md`, `orden.md` e `ignore.md` **sí** están: registran el resultado de los
  experimentos de la F04.
- **Los comandos sueltos:** muchas pruebas se corrieron como comandos directos en la terminal de la
  sesión, sin script. Esas no tienen archivo; su salida está en los logs del curso y su conclusión en
  `hallazgos.md`.

> ⚠️ **Las rutas se corrigieron al copiar.** Los scripts tenían escrita la ruta del scratchpad viejo
> (`/private/tmp/claude-501/…/<sesión>/scratchpad`). Ahora apuntan a la carpeta equivalente de este
> directorio. Las rutas al curso (`…/lab-docker-kubernetes/src/lab`) siguen absolutas: si el repositorio
> se mueve, hay que corregirlas con un `grep -rl`.

---

## 🧭 Las reglas antes de correr cualquier cosa

Son las mismas que se siguieron en la producción (memoria `feedback-pruebas-en-contenedor`):

1. **Inventario inicial de Docker en un log**, para borrar al final solo lo creado:
   ```bash
   mkdir -p salidas
   docker ps -aq --no-trunc > salidas/contenedores-antes.txt
   docker images -q --no-trunc | sort -u > salidas/imagenes-antes.txt
   docker volume ls -q > salidas/volumenes-antes.txt
   docker network ls -q > salidas/redes-antes.txt
   ```
   Los archivos `ids-antes.txt`, `img-*.txt`, `vol-*.txt`, `c0`/`c1`, `i0`/`i1`, `n0`/`n1` y `v0`/`v1`
   son los inventarios que se tomaron entonces (antes y después).
2. **Todo lleva la etiqueta `curso=lab-docker-kubernetes`**, y se borra solo por esa etiqueta o por ID
   comparado con el inventario. Nada de `docker system prune`, `image prune` ni `builder prune` sin filtro.
3. **Ningún puerto por defecto publicado.** Los scripts usan `127.0.0.1` y puertos altos (18180, 18406,
   38411…) o la puerta del cluster (`127.0.0.1:8080`/`8443`, el `extraPortMappings` de kind).
4. **Docker Desktop a 4 GiB mientras se mide**, como el lector de referencia: se agrega
   `"MemoryMiB": 4096` a `~/Library/Group Containers/group.com.docker/settings-store.json` con Docker
   detenido y se quita al terminar. `02-t3-t5/settings-store.backup.json` y
   `03-t6-t10/settings-store.backup.json` son los respaldos que se tomaron antes de cambiarlo.
5. **Con 4 GiB no se enciende todo a la vez:** trazas, Prometheus, Grafana y el agente de Java ahogan la
   VM. Se enciende lo que la prueba necesita (`task obs:on|off`, `task bus:on|off`, `task chaos:on|off`).
6. **El Kubernetes de Docker Desktop debe estar apagado.** En T8 estaba encendido sin saberlo y se comió
   764 MiB de la VM (H155).

---

## 🛠️ Prerrequisitos

Las versiones exactas están en `a01-el-laboratorio.md` del curso. Lo mínimo para correr todo:

- **Siempre:** Docker Desktop (o Podman con su máquina de 4 GiB), `kind`, `kubectl`, `helm` 4 con el
  plugin `helm-diff`, `task`, `hurl`, `k6`, `curl`, Python 3.12+ y el `src/lab/` del curso.
- **Solo F04:** `dive`.
- **Solo F07:** `k3d`, `minikube`.
- **Para `dom.py`, `dom-perfil.py`, `cdp.py` y `shot.py`:** Google Chrome en su ruta de macOS.
- **Para `renew.py`:** `pip install cryptography`. **Para `k9s_drive.py`/`k9s_rw.py`:** `pip install pyte`
  y `k9s`.
- **Apéndices:** `docker buildx` (a06), `ko`, `buildah` y `kaniko` como contenedores (a07), la imagen
  de GraalVM CE 25 (a08), `istioctl` (a10), el repositorio de Helm de Headlamp (a14).

**Convención de todos los scripts:** salvo que el script haga su propio `cd`, se corren **desde
`src/lab/` del curso**, porque llaman a `task …` y usan rutas como `deploy/manifests/…`:

```bash
cd cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab
bash ../../../../zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f10b.sh 2>&1 | tee /tmp/f10b.log
```

T3–T5 corren en el cluster **`minimo`** (`kind-minimo`), y desde T6 en el cluster **`lab`** (`kind-lab`,
tres nodos). Muchos scripts fijan el contexto con `--context`; los que no lo fijan usan el contexto activo.

---

## 1️⃣ P11 y T0–T2 · `01-p11-t0-t2/`

**El orden de P11** (verificación del ambiente, hallazgos H1–H24, logs `00-…` a `54-…`):

1. Regenerar la CA del registry, porque la clave no se guardó (solo están los `.crt` y `san.ext`):
   ```bash
   cd 01-p11-t0-t2/borrador-p11/registry/certs
   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 30 \
     -subj "/CN=lab-ca" -keyout ca.key -out ca.crt
   openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=lab-registry" \
     -keyout registry.key -out registry.csr
   openssl x509 -req -in registry.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 30 \
     -extfile san.ext -out registry.crt
   ```
2. Construir la imagen de prueba (`img/Dockerfile`, un `agnhost` con otra etiqueta) como `lab/pricing:p11` y
   cargarla con `kind load docker-image`.
3. `ENGINE=docker ./levantar.sh minimo` (o `lab`, o `carga`): crea el cluster con `kind/cluster-<perfil>.yaml`,
   pone la CA en cada nodo, instala Envoy Gateway 1.9.2 y aplica `envoyproxy-nodeport.yaml` y
   `gateway-prueba.yaml`. Con Podman: `ENGINE=podman`.
4. `python3 medir.py "docker minimo base"` mide la memoria por namespace (B-00). Para las variantes con
   datos y observabilidad, `kubectl apply -f data.yaml` u `obs.yaml` y otra vez `medir.py`.
5. `g0/`: el prototipo G0 de `pricing` con su `compose.yaml` y su suite `pricing.g0.hurl` (H20).
6. `lab/`: el primer Taskfile con `seed:generate` (Faker `es_CO`, H19).

`a03-prompts-g0.md`, `a16-prompts.md`, `g0/prompt-g0-pricing.md` y `scratchpad/prompts.txt` son los
prompts con los que se generaron los servicios G0 y el patrimonio (Contingencia, portal, Braqui).

**`scratchpad/` (T1–T2):**

| Archivo | Qué prueba |
|---|---|
| `ep/Dockerfile` | F01: `ENTRYPOINT` + `CMD` sobre la imagen de la Braqui |
| `npm/package.json` | el `package.json` del despachador de la Braqui, para probar `npm ci` |
| `tasktest/Taskfile.yml` | cómo pasa `CLI_ARGS` el Taskfile (`task t -- -v`) |
| `tags/`, `gitcheck/` | el modelo de tags: repo propio del lector contra los tags `inc/` del curso |
| `auth-vacio.json` | `config.json` de Docker vacío, para el pull anónimo de Podman (log 53) |

---

## 2️⃣ T3–T5 · `02-t3-t5/` (F03–F12)

| Script | Fase | Qué prueba | Cómo se corre |
|---|---|---|---|
| `*.Dockerfile.g0` | F04 | los cinco Dockerfile de una etapa, guardados antes de reescribirlos | los usa `f04-experimentos.sh` |
| `f04-experimentos.sh` | F04 | tamaños de G0 con `dive` y `docker save`, orden de instrucciones, `.dockerignore` | desde cualquier sitio (hace `cd` al lab) |
| `f04-autopsia.sh` | F04 | la autopsia de reconstruir y reiniciar sin recrear el contenedor (`pricing-circular`) | ídem |
| `orden/`, `ignore/` + `orden.md`, `ignore.md` | F04 | `COPY . .` antes de `npm ci`, y un `CLAUDE.md` que invalida la caché | `docker build` de cada carpeta, tres veces |
| `shellform/` | F03 | forma shell contra exec: quién es PID 1 y si llega el `SIGTERM` | `docker build -f Dockerfile.X` y `docker stop` |
| `musl/`, `permisos/` | F03–F04 | JRE de glibc sobre Alpine; volumen montado con dueño equivocado | `docker build` y `docker run` |
| `circular/`, `pricing-g0/` | F04 | el `pricing` con multi-stage, copia aislada | `docker build` |
| `f06/*.yaml` | F06 | `depends_on` con y sin `service_healthy`, `restart: always` con sonda rota | `docker compose -f f06/X.yaml up` |
| `k3d-sin-traefik.py`, `b07-dd.py` | F07 | B-07: memoria de k3d sin Traefik; Kubernetes de Docker Desktop encendido y apagado | `python3` desde `src/lab` (b07-dd **toca el settings-store**: respaldar antes) |
| `b00-servicios-cluster.py` | F08 | B-00 con los servicios desplegados, tres corridas | `python3` (hace `cd` al lab) |
| `f08b.sh` … `f08e.sh`, `f08c.py`, `f08m*/`, `pod-suelto.yaml`, `kube/` | F08 | DNS y `Service`, incidentes 05–06, selectores, ReplicaSet huérfano, `generation`, tiempo de reemplazo de un pod | desde `src/lab`, cluster `minimo` |
| `f09*.sh`, `f09movs.py`, `f09race.py` | F09 | los cuatro servicios dentro, el pod de dos contenedores de `catalog`, incidente 07, movimientos de `inventory` (D33), la carrera de readiness | ídem |
| `f10a.sh` … `f10d.sh`, `envoyproxy-local.yaml`, `catalog-httproute.bak.yaml` | F10 | `LoadBalancer` con cloud-provider-kind, Gateway API, incidente 08, `externalTrafficPolicy` en el perfil `lab` | ídem (`f10d` pasa de `minimo` a `lab`) |
| `f11-*.sh`, `f11-variantes.yaml`, `dom.py`, `dom-perfil.py`, `dom.sh` | F11 | ConfigMap montado contra variable de entorno (incidente 09), Secret (incidente 10), QA con la misma imagen, la caché del navegador | ídem; los `dom*` necesitan Chrome |
| `f12-*.sh`, `soap.sh`, `concurrencia.py`, `strangler.py` | F12 | Postgres en `data`, orden migración-rollout, la existencia fantasma con dos réplicas, traslados de la Braqui por archivo, strangler de precios | ídem; `soap.sh` llama a Contingencia desde su pod |

Las notas `s4.md` … `s17.md` y `sref.md` son los fragmentos con las cifras de B-04/B-05 tal como
salieron. Sirven para comparar una corrida nueva.

---

## 3️⃣ T6–T10 · `03-t6-t10/` (F13–F23)

Herramientas de medición reutilizables (se citan entre sí):

| Script | Qué hace |
|---|---|
| `mem.py <nodo> <ns>` | memoria (working set) de cada contenedor de un namespace, con `crictl` en el nodo |
| `snap.sh <etiqueta>` | foto de memoria de `apps` y `observability` en los tres nodos del cluster `lab` |
| `promq.py '<expr>'` / `logq.py '<LogQL>' [min]` | consulta a Prometheus y a Loki por la puerta (`Host: prometheus.localhost` / `grafana.localhost`) |
| `probe.py` / `probe2.py <url> <s>` | una petición cada 100 ms, con las ventanas sin 200 (cortes en rollouts) |
| `mediana.sh <url>` | 60 lecturas: mediana, p90 y máximo |
| `ready.py <contexto>` | segundos desde que se crea cada pod hasta que está Ready |
| `r.sh` | `source r.sh`; `r <comando>` imprime el comando y su salida, para pegar en la lección |

Las pruebas por fase:

| Archivo | Fase | Qué prueba |
|---|---|---|
| `dup.py`, `lines.py`, `render.yaml`, `manifest.txt`, `apps-b.yaml.bak`, `mem-tenant.sh` | F13–F14 | duplicación entre manifiestos antes de Helm, líneas del chart, el render de referencia y la memoria de la segunda cadena (`tenant-b`) |
| `load.js`, `inv-load.js`, `cat-load.js`, `pri-load.js` | F15 | memoria bajo carga, la autopsia del OOMKilled de `inventory`, incidente 14 |
| `components.yaml`, `hpa_run.py`, `rate.js`, `race.py`, `until.py` | F16 | metrics-server, el HPA bajo carga constante, errores durante un rollout (B-16), la carrera de `inventory`, cuándo se ve un ConfigMap nuevo |
| `b00obs.sh`, `card.sh`, `tempo/tempo.yaml`, `observability.txt`, `obs.bak.json` | F17–F18 | B-00 con observabilidad, la autopsia de cardinalidad en Prometheus, Tempo |
| `renew.py`, `alpn.json`, `ventas.js`, `api.js`, `reach.js`, `debug-uid.json` | F19–F20 | la renovación del certificado sin cortes, ALPN, la venta con y sin mTLS, leer un Secret con el token del pod, la `NetworkPolicy` vista desde adentro |
| `cdp.py`, `shot.py` | F17, F21 | clic en la página y capturas con Chrome sin interfaz |
| `cb.py`, `skus.js`, `conns.sh`, `traza.py`, `prices.out`, `k6*.out` | F22–F23 | el circuito de `catalog` bajo caos, 2.000 SKU por la puerta, conexiones HTTP/2 por réplica (B-23), una traza de Tempo |

Los `*.out` son salidas cortas de k6 y de las sondas, guardadas para comparar.

---

## 4️⃣ T11–T16 · `04-t11-t16/` (F24–F27 y apéndices)

| Archivo | Fase | Qué prueba | Cómo se corre |
|---|---|---|---|
| `loan.py`, `batch.py` | F24 | un préstamo (saga RESERVE→DISPATCH→CHARGE) y N préstamos con sus estados | `python3 loan.py`, con `task bus:on` |
| `latencia.py <since>`, `ventas.py`, `rafaga.py` | F25–F26 | latencia del aviso por el bus, duplicados tras un reinicio, la ráfaga que cruza las dos bases (outbox) | contra el cluster `lab` |
| `salidas.sh` | F27 | las salidas de `kubectl` del proyecto final | contexto `kind-lab` |
| `a06/`, `arranque.sh` | a06 | build multiplataforma con `--platform=$BUILDPLATFORM` y el arranque bajo emulación | `docker buildx build --platform linux/amd64,linux/arm64 -f a06/Dockerfile.pricing <servicio>`; `sh arranque.sh <img> linux/amd64 /health/live` |
| `a07/inventory/` | a07 | `inventory` construido sin Docker: buildah, kaniko, ko (el `relay/` en Go) y Jib | ver a07 en el curso |
| `a08/inventory/Dockerfile.native`, `a08/medir.sh` | a08 | `inventory` nativo con GraalVM: listo, memoria en reposo y tras 1.000 peticiones, tres corridas | `bash a08/medir.sh nativo lab/inventory:a08-native` |
| `a09/` | a09 | el storefront con SSR contra el estático (`pagina.js`, `MODE=static\|ssr`) | `kubectl apply -f a09/ssr.yaml`; `k6 run -e MODE=ssr a09/pagina.js` |
| `a13/` | a13 | respaldo y restauración: un cluster con carpeta del host montada | `kind create cluster --config a13/kind-a13.yaml` (el `hostPath` ya apunta a `a13/respaldos/`) |
| `a14.sh`, `a14b.sh`, `k9s_*.py/json`, `k9s_screens.txt` | a04, a14 | Headlamp por Helm; k9s manejado en un pseudo-terminal, con sus pantallas | `python3 k9s_drive.py k9s_steps.json` |
| `nats-ha-ordered.yaml`, `a15-*.sh`, `t.sh` | a15 | NATS JetStream de tres miembros: deduplicación, failover (`delete`/`kill9`) y quórum | desde la raíz del curso; `bash a15-failover.sh <etiqueta> delete f-` |
| `chk.sh`, `urls.txt`, `urlres.txt` | T15 | las URL de las referencias, una por una | `xargs -n1 sh chk.sh < urls.txt` |

---

## 🧹 Al terminar

1. `task cluster:down -- minimo` / `-- lab` y los clusters temporales (`kind delete cluster --name a13`,
   `k3d cluster delete b07`). Después de borrar un cluster temporal, `kubectl config use-context kind-lab`.
2. Los contenedores, imágenes, volúmenes y redes **creados por la corrida**, por la etiqueta
   `curso=lab-docker-kubernetes` o comparando con el inventario de `salidas/`.
3. Los repositorios de Helm agregados por un apéndice (`helm repo remove headlamp`…).
4. Docker Desktop: quitar `MemoryMiB` del settings-store y reiniciarlo.
5. La CA del registry y de la puerta, si se instaló en el llavero (paso 4 de a01).
