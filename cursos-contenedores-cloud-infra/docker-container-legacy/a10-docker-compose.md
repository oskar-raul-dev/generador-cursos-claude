# 🐙 Apéndice a10 — Docker Compose, después de entender `docker run`

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F00](00-problema-y-contrato.md) §9 — *"Compose podrá aparecer después, cuando realmente simplifique escenarios multi-contenedor"*
> **Requisitos:** **[F09](09-montar-tu-proyecto.md)** (montajes), **[F16](16-pid1-senales-y-ciclo-de-vida.md)** (ciclo de vida) y **[F18](18-networking-de-contenedores.md)** (redes). Sin las tres, esto es una caja negra
> **Código de este apéndice:** [`src/a10-docker-compose/`](src/a10-docker-compose/)
> **Qué encontrarás:** Compose traducido línea por línea desde los comandos que ya sabes, y el escenario donde de verdad gana: Selenium en su propio contenedor

[F00](00-problema-y-contrato.md) prometió que Compose llegaría **cuando simplificara algo de verdad**, y llevas treinta y
cinco fases sin él. Este apéndice cierra ese bucle, y lo hace con la regla del curso: **cada
línea del YAML se corresponde con algo que ya sabes hacer a mano**.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué es Compose y qué no es?" | [§1](#1--qué-es-y-qué-no-es) |
| "¿Cómo se traduce mi `docker run`?" | [§2](#2--traducción-línea-por-línea) |
| "¿Cuál es el caso donde gana?" | [§3](#3-️-el-escenario-que-lo-justifica-selenium) |
| "¿Y con Podman?" | [§4](#4--compose-con-podman) |
| "¿Cuándo NO usarlo?" | [§5](#5--guía-rápida-cuándo-usar-qué) |

---

## 1. 🧩 Qué es, y qué no es

**Compose es un archivo YAML que describe uno o varios contenedores y sus relaciones**, más un
comando que los levanta y los para juntos.

> 🧭 **Y lo que NO es:** no es un motor, no es una tecnología nueva, y no hace nada que no
> pudieras hacer con `docker run`, `docker network create` y `docker volume create`. Es
> **notación**, y ahí está su valor: convierte cuatro comandos largos y frágiles en un archivo
> versionado que otra persona puede leer.

Por eso el curso lo deja para el final. Si llegaste aquí, cada clave del YAML te va a resultar
familiar, y cuando algo falle vas a saber traducirlo hacia atrás — que es exactamente lo que no
puede hacer quien empezó por aquí.

---

## 2. 🔄 Traducción línea por línea

Este es tu toolbox de [F09](09-montar-tu-proyecto.md), escrito en YAML:

📄 **`compose.yaml`**

```yaml
services:
  toolchain:
    image: legacy-node-toolchain:phase15        # docker run <imagen>
    container_name: legacy-node-dev             # --name
    platform: linux/amd64                       # --platform
    working_dir: /workspace                     # -w
    environment:
      NODE_VERSION: "10.24.1"                   # -e
    volumes:
      - type: bind                              # --mount type=bind
        source: .
        target: /workspace
      - type: volume                            # --mount type=volume
        source: node-modules
        target: /workspace/node_modules
    ports:
      - "127.0.0.1:3000:3000"                   # -p
      - "127.0.0.1:9229:9229"                   # el inspector, F10
    init: true                                  # --init, F16 §8
    command: sleep infinity                     # el comando, F09 §7

volumes:
  node-modules:                                 # docker volume create
    name: legacy-vue2-node10-amd64-modules      # la convención de F22 §7
```

```bash
docker compose up -d          # crear y arrancar
docker compose exec toolchain bash
docker compose exec toolchain npm ci
docker compose logs -f toolchain
docker compose down           # parar y eliminar
docker compose down -v        # ⚠️ y BORRAR los volúmenes
```

**Detalles con intención:**

- **`platform` está declarado**, por el baseline de [F01](01-decisiones-debian-zonas-node.md). Compose no lo adivina.
- **`init: true`** por lo de [F16](16-pid1-senales-y-ciclo-de-vida.md) §8, que en un contenedor de desarrollo que lanza herramientas de
  build tiene sentido.
- **El volumen lleva `name:` explícito** con la convención de [F22](22-apple-silicon-y-hosts.md) §7. Sin él, Compose le pone un
  prefijo con el nombre del proyecto y pierdes el control de la convención — que es justo la que
  evita la contaminación entre arquitecturas.
- **Los puertos en `127.0.0.1:`**, por [F18](18-networking-de-contenedores.md) §6.

> ⚠️ **`docker compose down -v` borra los volúmenes.** Es un comando de una letra de distancia
> del inofensivo, y se lleva tu `node_modules` por delante. Es la razón principal por la que este
> apéndice llega después de que entiendas qué hay dentro de un volumen.

### 2.1 Lo que Compose sí te da

Tres cosas que a mano cuestan:

**Una red de usuario automática.** Compose crea una red para el proyecto y conecta todos los
servicios: el DNS por nombre de [F18](18-networking-de-contenedores.md) §7 funciona sin que lo pidas.

**Orden y dependencias**, con `depends_on`.

**Un archivo versionado**, que es documentación ejecutable del entorno — el mismo argumento del
`devcontainer.json` de [F19](19-dev-containers.md).

---

## 3. 🕸️ El escenario que lo justifica: Selenium

Aquí es donde Compose deja de ser notación y empieza a ahorrar trabajo de verdad. Es el caso que
[F00](00-problema-y-contrato.md) anticipó y que **[a09](a09-browsers-legacy.md) §4** describe a mano.

📄 **`compose.e2e.yaml`**

```yaml
services:
  toolchain:
    image: legacy-node-toolchain:phase15
    platform: linux/amd64
    working_dir: /workspace
    environment:
      NODE_VERSION: "10.24.1"
      SELENIUM_REMOTE_URL: "http://selenium:4444/wd/hub"   # ← por nombre, F18 §7
    volumes:
      - type: bind
        source: .
        target: /workspace
      - type: volume
        source: node-modules
        target: /workspace/node_modules
    depends_on:
      selenium:
        condition: service_healthy                          # espera a que esté LISTO
    command: npm run test:e2e

  selenium:
    image: selenium/standalone-chrome:4.1.4                 # versión fijada, a09 §4
    shm_size: "2gb"                                         # --shm-size, a09 §4
    ports:
      - "127.0.0.1:4444:4444"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4444/wd/hub/status"]
      interval: 5s
      timeout: 3s
      retries: 20

volumes:
  node-modules:
    name: legacy-e2e-node10-amd64-modules
```

```bash
docker compose -f compose.e2e.yaml up --abort-on-container-exit
docker compose -f compose.e2e.yaml down
```

**Y aquí está lo que Compose aporta y a mano cuesta:**

**`depends_on` con `condition: service_healthy`.** A mano, tu suite arranca antes de que Selenium
esté listo y falla con un error de conexión desconcertante. La alternativa manual es un bucle de
espera en un script; aquí son tres líneas.

**La red, sin crearla.** El `selenium` del `SELENIUM_REMOTE_URL` resuelve porque están en la
misma red de proyecto.

**Un solo comando levanta y tumba los dos.** Con `--abort-on-container-exit`, cuando la suite
termina, el navegador se para también.

> 🧭 **Este es el caso.** Un contenedor solo no justifica Compose; dos contenedores con
> dependencia de arranque, sí. Y ahora sabes exactamente qué está haciendo por debajo, que era la
> condición.

---

## 4. 🦭 Compose con Podman

Dos caminos, y ninguno es idéntico:

**`podman-compose`** es una implementación aparte, en Python, con cobertura parcial de la
especificación. Funciona para casos como los de este apéndice y puede tropezar con opciones
avanzadas.

**El servicio de Podman más el Compose de Docker** —[F24](24-docker-y-podman-arquitectura.md) §5.4—:

```bash
systemctl --user start podman.socket
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
docker compose up -d
```

Esta segunda suele dar menos sorpresas, porque usa el Compose de verdad contra un socket
compatible.

> ⚠️ **`shm_size` y algunas opciones de red se comportan distinto en Podman.** Comprueba en lugar
> de asumir — es la regla del curso desde [F00](00-problema-y-contrato.md) §5.1.

---

## 5. 🧭 Guía rápida: cuándo usar qué

| Tu situación | Recomendación |
|---|---|
| **Un** contenedor de desarrollo | **`docker run` o el `run-dev.sh` de [F09](09-montar-tu-proyecto.md).** Compose no aporta |
| Dos o más contenedores que dependen entre sí | **Compose**: es su caso |
| E2E con Selenium o similares | **Compose**, §3 |
| Quieres documentar el entorno para el equipo | Compose **o** el `devcontainer.json` de [F19](19-dev-containers.md) |
| Estás aprendiendo cómo funciona esto | **`docker run`**, siempre. Compose esconde justo lo que quieres ver |
| Tu proyecto ya trae un `docker-compose.yml` de 2019 | tradúcelo a comandos para entenderlo, después decide |

> 🧭 **Y el consejo que resume el apéndice:** si te encuentras un `compose.yaml` heredado y algo
> no funciona, **traduce el servicio problemático a un `docker run` a mano**. Ahí es donde ves lo
> que Compose estaba haciendo, y es la técnica que este curso te ha estado preparando para usar.

---

## 🧪 Ejercicios (6)

### 🟢 Ejercicio 1 — Traduce tu toolbox

Convierte tu `run-dev.sh` de [F09](09-montar-tu-proyecto.md) al `compose.yaml` de §2 y comprueba que hace lo mismo.

### 🟢 Ejercicio 2 — Al revés

Toma el `compose.yaml` de §2 y escribe los `docker run`, `docker volume create` y
`docker network create` equivalentes.

**Objetivo:** demostrar que no hay magia. Si alguna línea no sabes traducirla, ahí tienes lo que
te falta.

### 🟡 Ejercicio 3 — El escenario de Selenium

Monta el `compose.e2e.yaml` de §3 con una suite mínima que abra una página.

### 🟡 Ejercicio 4 — Sin `healthcheck`

Quita el `depends_on` con condición y vuelve a ejecutar la suite.

**Pregunta:** ¿falla? ¿Con qué error? Ahí está lo que Compose te estaba resolviendo.

### 🟠 Ejercicio 5 — `down -v`, con cuidado

En un proyecto de prueba, ejecuta `docker compose down` y después `down -v`, mirando
`docker volume ls` entre medias.

**Objetivo:** ver la diferencia y no volver a escribir `-v` por costumbre.

### 🟠 Ejercicio 6 — Un Compose heredado

Busca un `docker-compose.yml` de un proyecto de 2018–2019 en GitHub y audítalo: ¿qué versión de
sintaxis usa? ¿Fija las imágenes? ¿Monta el socket de Docker? ¿Qué haría distinto hoy?

**Objetivo:** una lista de observaciones con su consecuencia, como el ejercicio 23 de [F02](02-dockerfile-esencial.md).

---

## 📚 Referencias

- Compose: https://docs.docker.com/compose/
- La especificación, que es abierta: https://compose-spec.io
- Referencia del archivo: https://docs.docker.com/reference/compose-file/
- `depends_on` y condiciones: https://docs.docker.com/reference/compose-file/services/#depends_on
- `podman-compose`: https://github.com/containers/podman-compose

> ⚠️ **La clave `version:` del principio del archivo está obsoleta** desde hace varias versiones
> y hoy produce un aviso. Los `docker-compose.yml` de 2019 la llevan siempre; puedes quitarla sin
> más.

**Vuelve a:** [F00 §9](00-problema-y-contrato.md) · [F09](09-montar-tu-proyecto.md) · [a09 §4](a09-browsers-legacy.md)
