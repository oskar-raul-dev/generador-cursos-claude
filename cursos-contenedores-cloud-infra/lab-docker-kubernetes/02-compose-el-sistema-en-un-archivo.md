# 🧩 Fase 02 — Compose: el patrimonio y el sistema nuevo, en un archivo y con un contrato

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 02 de 27 · Parte 0 — Prolegómenos · **media**
> **Plataformas:** Windows 11 con WSL 2 · macOS Apple Silicon · Linux amd64
> **Motor de referencia:** Docker · 🦭 `podman compose` no es un compose propio: delega en otro programa
> **Servicios que toca:** el patrimonio y los cinco nuevos · **Paso de generación:** G0 🌊
> **Depende de:** Fase 01 · **Habilita:** [Fase 03](03-el-contenedor-por-dentro.md)
> **Incidentes que reserva:** ninguno
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64, con Docker y con Podman · Windows 11 y Linux: no verificados por el autor
> **Objetivo:** levantar con dos tareas el patrimonio y los cinco servicios del paso G0 en un solo proyecto de compose, y que la suite de conformidad del paso pase contra ellos.

---

## 🧭 1. Dónde estamos

La [Fase 01](01-primer-contenedor-y-dockerfile.md) dejó una imagen, la de la Braqui, y una red armada a mano con tres `docker run` que hubo
que escribir en orden. Para una pieza alcanza. El patrimonio son cuatro —Contingencia, su base, el
portal y la Braqui con su aviso de traslados—, y el sistema nuevo suma cinco. Escribir nueve `docker
run` cada mañana no es una opción, y recordar en qué orden, tampoco.

Valentina lo resolvió como lo resuelve casi todo el mundo: **un archivo**. Primero metió ahí el
patrimonio, tal como está, para que cualquiera en La Rebotica pudiera levantarlo con un comando y
ver lo que la cooperativa ya tiene antes de construir nada. Después convocó a los cuatro equipos a
una reunión que duró más de lo previsto, porque el sistema nuevo no iba a arrancar con código:
**iba a arrancar con un contrato**. Cada servicio, su OpenAPI; cada operación, el paso en que llega;
y desde esa reunión, nadie cambia la forma de un payload sin cambiar primero el contrato.

La discusión más larga fue la del catálogo. Daniela, que lleva el portal desde que era pasante y es
la que menos paciencia tiene con la sincronización nocturna (historia §2), defendió que el catálogo
nuevo fuera de su equipo y saliera del portal, no del Siga: *"El catálogo que ve el cliente es el
nuestro. Lo que el Siga tiene es la lista de lo que compra la cooperativa."* Así quedó: `catalog` es
del equipo del portal, en su stack, y su contrato es el primero que se escribió.

Esta fase hace lo mismo que esa semana de La Rebotica: el patrimonio en un archivo, el contrato
acordado y congelado, y **el esqueleto de los cinco servicios** corriendo al lado, validado por una
suite. Es la primera vez del curso que un servicio es válido porque pasa una suite, y no porque
alguien lo escribió de una forma concreta.

---

## 🎯 2. Objetivos de esta fase

1. Levantar el patrimonio con `task legacy:up` y leer su `compose.yaml` servicio por servicio.
2. Generar los cinco servicios del paso G0 con los prompts de [a03](a03-contratos-y-prompts-de-generacion.md)
   y levantarlos con `task compose:up`, al lado del patrimonio.
3. Correr `task conformance -- G0` y que pasen los cinco archivos de la suite.
4. Comprobar desde adentro de la red que los servicios se encuentran por su nombre.
5. Saber operar el proyecto: ver, leer, entrar, detener y borrar, sin bajar lo que no querías bajar.

---

## 🚫 3. Qué NO entra todavía

- Dónde se rompe el modelo de compose → [Fase 06](06-del-compose-al-cluster.md). Aquí compose se usa y se disfruta.
- Que los servicios guarden algo → [Fase 09](09-los-cuatro-servicios-dentro.md) (la Oleada 1).
- Que un servicio llame a otro por trabajo de negocio → [Fase 16](16-escalado-y-rollout.md) (la Oleada 2).
- Por qué las imágenes de G0 pesan lo que pesan, y cómo se empaqueta en serio → [Fase 04](04-empaquetar-los-cuatro-runtimes.md).
- Las sondas de salud de compose para los servicios nuevos → [Fase 15](15-salud-y-recursos.md), cuando la readiness sea real.

---

## 🧩 4. El sistema entero en un archivo

### 4.1 Primero el patrimonio

El archivo es `src/lab/compose/compose.yaml`, y hoy tiene tres partes: los cinco servicios nuevos,
el patrimonio en el **perfil** `legacy`, y dos herramientas en sus propios perfiles. Empiezo por el
patrimonio, porque es lo que hay:

```bash
task legacy:up
```

Debajo, el Taskfile construye las cuatro imágenes del patrimonio con el motor activo y corre:

```text
task: [legacy:up] docker compose -f compose/compose.yaml --profile legacy up -d contingencia-db contingencia portal braqui braqui-traslados
 Container lab-contingencia-db-1 Started
 Container lab-contingencia-db-1 Waiting
 Container lab-contingencia-db-1 Healthy
 Container lab-braqui-traslados-1 Started
 Container lab-contingencia-1 Started
 Container lab-braqui-1 Started
 Container lab-portal-1 Started
```

Lo que hacía falta escribir a mano en la [Fase 01](01-primer-contenedor-y-dockerfile.md) ahora está declarado. La base de Contingencia,
comentada donde el archivo elige algo:

```yaml
  contingencia-db:
    profiles: [legacy]
    # postgres:18.6
    image: postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722
    environment:
      TZ: America/Bogota
      POSTGRES_DB: contingencia
      POSTGRES_USER: contingencia
      POSTGRES_PASSWORD: contingencia-lab   # solo de laboratorio
    volumes:
      - contingencia-data:/var/lib/postgresql
      # El esquema, el procedimiento del préstamo y los datos iniciales, la primera vez.
      - ../legacy/contingencia/db:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "contingencia", "-d", "contingencia"]
      interval: 5s
      retries: 20
```

Y Contingencia, que se construye en vez de descargarse y que espera a su base:

```yaml
  contingencia:
    profiles: [legacy]
    build: ../legacy/contingencia
    image: lab/legacy-contingencia
    environment:
      DB_HOST: contingencia-db
      …
    volumes:
      - traslados:/var/lib/contingencia/traslados
    depends_on:
      contingencia-db: {condition: service_healthy}
```

Cada clave del archivo es un pedazo de un `docker run` de la [Fase 01](01-primer-contenedor-y-dockerfile.md):

| En compose | En `docker run` | Lo que hace |
|---|---|---|
| `image:` | el último argumento | qué imagen correr |
| `build:` | `docker build` antes | de qué carpeta construirla si no existe |
| `environment:` | `-e` | variables de entorno |
| `volumes:` | `-v` | carpetas del host o volúmenes con nombre |
| `ports:` | `-p` | lo que se publica en el host |
| `depends_on:` | el orden en que escribías los `run` | qué arranca antes |
| `profiles:` | — | qué servicios se encienden solo si pides su perfil |
| la red | `docker network create` y `--network` | compose crea una por proyecto, `lab_default`, y mete ahí a todos |

**`image` y `build` juntos** quieren decir: construye desde esa carpeta y llámala con ese nombre. Si
la imagen ya existe, `up` no la reconstruye; por eso el Taskfile construye explícitamente antes
(4.8 explica por qué eso importa con Podman).

> ⚠️ **`depends_on` espera a que el otro arranque, no a que esté listo.** La base tiene `healthcheck`,
> así que Contingencia espera a que Postgres conteste. Pero el portal depende de Contingencia sin
> condición, y GlassFish tarda unos cuarenta segundos en desplegar después de que su contenedor
> arranca. Si sincronizas el catálogo apenas termina `legacy:up`:
>
> ```text
> $ docker exec lab-portal-1 php artisan catalog:sync
>
> In SyncCatalog.php line 18:
>   SOAP-ERROR: Parsing WSDL: Couldn't load from 'http://contingencia:8080/PriceService/PriceService?wsdl' : failed to load "http://contingencia:8080/PriceService/PriceService?wsdl": No such file or directory
> ```
>
> Un minuto después, el mismo comando dice `8 productos sincronizados desde Contingencia`. "Arrancó"
> y "puede atender" no son lo mismo; el curso vuelve a esa diferencia en la [Fase 15](15-salud-y-recursos.md), con otro
> nombre.

Qué hace cada pieza del patrimonio, y qué mañas trae a propósito, está en [a16](a16-el-patrimonio.md).
El portal es el único que publica un puerto: `http://localhost:8081`.

### 4.2 El contrato, antes que el código

El sistema nuevo empieza por cuatro archivos que no se ejecutan: los contratos de `pricing`,
`inventory`, `catalog` y `replenish`, en `src/lab/contracts/openapi/`, en OpenAPI 3.1. Lo que los
distingue de un OpenAPI cualquiera es una clave por operación:

```yaml
  /prices/{sku}:
    get:
      summary: El precio vigente de un producto en una droguería. En G0 devuelve un precio fijo.
      x-lab-paso: G0
    put:
      summary: Fija el precio de un producto en una droguería. Pendiente hasta G1 (Fase 09).
      x-lab-paso: G1
```

**`x-lab-paso` dice en qué paso de la matriz de generación llega cada operación.** El contrato de
hoy ya tiene la venta (G5, [Fase 16](16-escalado-y-rollout.md)), el préstamo como saga (G11, [Fase 24](24-la-saga-orquestada.md)) y la clave de idempotencia
(G13, [Fase 26](26-idempotencia-y-outbox.md)): sabes desde ahora adónde va el sistema. Lo que todavía no existe responde 404, y la
suite lo comprueba.

Lo que salió de la reunión de los cuatro equipos, en una tabla. Cada servicio tiene un dueño, y cada
dueño eligió el stack que sabía operar (historia §2):

| Servicio | Equipo | Stack | Sale de |
|---|---|---|---|
| `pricing` | plataforma, el de Valentina | Go | el `PriceService` de Contingencia |
| `inventory` | el Núcleo, que mantiene el Siga | Java con Spring Boot | el `StockService` de Contingencia y su procedimiento del préstamo |
| `catalog` | el del portal, el de Daniela | PHP con Laravel | el catálogo propio del portal |
| `replenish` | el de la Braqui | Node con NestJS | la Braqui, despegada de las tablas del Siga |
| `storefront` | el del portal | React | la página del portal |

**Desde esta fase, el contrato está congelado.** Cambiar la forma de un payload exige cambiar
primero el OpenAPI, después la suite y al final el código, en ese orden. Es la regla que acordaron
los cuatro equipos, y la que hace posible regenerar un servicio sin miedo.

Para leer los contratos con una página, `task contracts:docs` levanta Swagger UI en un contenedor,
en `http://localhost:8090`. Es una herramienta para leer: la fuente de verdad sigue siendo el YAML.

### 4.3 🌊 La Oleada 0: el esqueleto

Los cinco servicios nuevos se **generan** con los prompts del paso G0, publicados en
[a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g0): un marco común y uno por
servicio, con `pricing` primero porque es el piloto. Cada prompt le pasa al asistente el contrato,
la suite y el código del patrimonio del que sale el servicio, y le dice con todas las letras lo que
**no** debe tener todavía: base de datos, llamadas a otros servicios, `/metrics`, logs en JSON,
manejo de señales.

Lo que G0 pide de cada uno es poco, a propósito: `/health/live` y `/health/ready` triviales, y **un
endpoint que devuelve JSON fijo**. `pricing` contesta siempre 12.900 pesos; `inventory`, siempre 24
unidades; `catalog`, siempre los mismos dos productos. El `storefront` es una página con el nombre de
la casa. Los cinco en `compose.yaml`, sin perfil, para que se enciendan por defecto:

```yaml
  pricing:
    build: ../services/pricing
    image: lab/pricing
  inventory:
    build: ../services/inventory
    image: lab/inventory
  # … catalog y replenish, igual
  storefront:
    build: ../services/storefront
    image: lab/storefront
    ports:
      - "127.0.0.1:8082:8080"   # el único servicio nuevo que se mira con el navegador
```

```text
$ task compose:up
task: [compose:up] docker build -q -t lab/pricing services/pricing
task: [compose:up] docker build -q -t lab/inventory services/inventory
task: [compose:up] docker build -q -t lab/catalog services/catalog
task: [compose:up] docker build -q -t lab/replenish services/replenish
task: [compose:up] docker build -q -t lab/storefront services/storefront
task: [compose:up] docker compose -f compose/compose.yaml up -d
 Container lab-catalog-1 Started
 Container lab-storefront-1 Started
 Container lab-inventory-1 Started
 Container lab-pricing-1 Started
 Container lab-replenish-1 Started
```

Ningún servicio nuevo publica puerto salvo el `storefront`: `http://localhost:8082` muestra la página
de Droguerías La Vecina. Los otros cuatro se prueban desde adentro, que es la sección siguiente.

### 4.4 La suite de conformidad

```text
$ task conformance -- G0
task: [conformance] docker compose -f compose/compose.yaml --profile conformance run --rm conformance
Success /suite/pricing.g0.hurl (6 request(s) in 2 ms)
Success /suite/storefront.g0.hurl (2 request(s) in 9 ms)
Success /suite/replenish.g0.hurl (5 request(s) in 14 ms)
Success /suite/inventory.g0.hurl (5 request(s) in 134 ms)
Success /suite/catalog.g0.hurl (5 request(s) in 163 ms)
--------------------------------------------------------------------------------
Executed files:    5
Executed requests: 23 (132.2/s)
Succeeded files:   5 (100.0%)
Failed files:      0 (0.0%)
```

**Prueba de fuego.** Esa salida es la definición de "G0 está hecho". La suite está escrita en Hurl,
un archivo por servicio y por paso, y corre en un contenedor **dentro de la red del proyecto**: llama
a `http://pricing:8080` como lo llamaría cualquier otro servicio, sin que nadie publique un puerto
para dejarse probar. Un caso, para ver la forma:

```hurl
GET {{pricing}}/prices/SKU-0003?store=DRO-007
HTTP 200
[Asserts]
jsonpath "$.sku" == "SKU-0003"
jsonpath "$.price" isInteger
jsonpath "$.currency" == "COP"

GET {{pricing}}/metrics
HTTP 404
```

El último caso es el más importante de la suite: **`/metrics` tiene que dar 404**. Si el código
generado trae métricas, el paso está mal, aunque todo lo demás funcione: una capacidad no llega
antes que su fase. Y si un servicio no pasa, el método de [a03](a03-contratos-y-prompts-de-generacion.md#️-cuando-el-código-generado-no-pasa)
dice qué hacer: corregir el prompt y regenerar, no arreglar el código a mano.

**Cuando no pasa.** La primera vez que corrí la suite de G0, falló un archivo de cinco:

```text
error: Assert status code
  --> /suite/storefront.g0.hurl:5:6
   |
   | GET {{storefront}}/
 5 | HTTP 200
   |      ^^^ actual value is <403>
```

El `storefront` se servía con `vite preview`, que rechaza los nombres de host que no conoce, y
dentro de la red compose lo llama `storefront`. El código no tenía ningún error que un humano
hubiera visto leyéndolo: era una opción de configuración del servidor de vista previa. Se corrigió
**el prompt** —ahora pide `preview.allowedHosts` y dice por qué—, se regeneró, y la suite pasó. Si el
arreglo se hubiera hecho a mano en el código, el próximo que regenerara el servicio se habría
encontrado el mismo 403.

**El patrón a memorizar.** Un servicio es válido porque pasa la suite de su paso, y por eso puedes
regenerarlo, reescribirlo en otro lenguaje o escribirlo a mano: la suite lo juzga igual.

### 4.5 Una red, y los nombres

Compose creó una red para el proyecto, `lab_default`, y puso ahí a los diez contenedores. En esa red,
**cada servicio se llama por su nombre**:

```text
$ docker compose -f compose/compose.yaml exec replenish wget -qO- 'http://pricing:8080/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
$ docker compose -f compose/compose.yaml exec replenish wget -qO- http://contingencia:8080/contingencia/status
{"mode":"ACTIVE","rule":"el central no contesta"}
```

`replenish` encontró a `pricing` y a Contingencia sin saber en qué dirección IP estaba ninguno. Es la
**forma** del sistema que esta fase quería mostrar: procesos separados, una red, resolución por
nombre. En G0 ningún servicio llama a otro por trabajo de negocio —eso es la [Fase 16](16-escalado-y-rollout.md)—, pero el camino
ya existe.

```text
$ docker compose -f compose/compose.yaml --profile legacy ps
SERVICE            IMAGE                         STATUS                    PORTS
braqui             lab/legacy-braqui             Up 27 seconds             8080/tcp
braqui-traslados   lab/legacy-braqui-traslados   Up 27 seconds
catalog            lab/catalog                   Up 22 seconds             8080/tcp
contingencia       lab/legacy-contingencia       Up 27 seconds             3700/tcp, 3820/tcp, 3920/tcp, 4848/tcp, 6666/tcp, 8080/tcp, 8181/tcp, 8686/tcp, 9009/tcp
contingencia-db    postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722   Up 33 seconds (healthy)   5432/tcp
inventory          lab/inventory                 Up 21 seconds             8080/tcp
portal             lab/legacy-portal             Up 27 seconds             127.0.0.1:8081->8080/tcp
pricing            lab/pricing                   Up 21 seconds             8080/tcp
replenish          lab/replenish                 Up 21 seconds             8080/tcp
storefront         lab/storefront                Up 22 seconds             127.0.0.1:8082->8080/tcp
```

Diez contenedores, dos puertos en el host. La lista de puertos de Contingencia es la que declara la
imagen de GlassFish con `EXPOSE`, y no publica ninguno: la misma lección de la [Fase 01](01-primer-contenedor-y-dockerfile.md).

### 4.6 Operar el proyecto

Los verbos de la [Fase 01](01-primer-contenedor-y-dockerfile.md) tienen su versión de compose, que actúa sobre servicios en vez de sobre
contenedores:

```bash
docker compose -f compose/compose.yaml ps                    # lo que corre del proyecto
docker compose -f compose/compose.yaml logs pricing          # los logs de un servicio (-f para seguirlos)
docker compose -f compose/compose.yaml exec replenish sh     # entrar a uno
docker compose -f compose/compose.yaml stop inventory        # detener uno, sin borrarlo
docker compose -f compose/compose.yaml up -d                 # dejar todo como dice el archivo
```

```text
$ docker compose -f compose/compose.yaml logs pricing
pricing-1  | 2026/10/03 09:42:50 pricing escuchando en :8080
pricing-1  | 2026/10/03 09:43:11 GET /prices/SKU-0003 200
```

`up -d` es **idempotente**: si todo ya está como dice el archivo, no hace nada; si algo cambió o se
cayó, lo corrige. Es la primera vez que ves esa idea, y la vas a ver crecer: en la Parte II es todo
el modelo de Kubernetes.

**Apagar sin apagar de más.** `docker compose down` baja **todo el proyecto**, el patrimonio incluido,
y con `-v` borra sus volúmenes. Por eso las tareas del laboratorio nombran sus servicios:

| Tarea | Debajo |
|---|---|
| `task compose:down` | `docker compose -f compose/compose.yaml rm --stop --force pricing inventory catalog replenish storefront` |
| `task legacy:down` | lo mismo con los cinco servicios del patrimonio |
| `task legacy:down -- -v` | además, `docker volume rm lab_contingencia-data lab_traslados lab_braqui-estado` |

> ⚠️ **Un perfil activo también enciende los servicios sin perfil.** `docker compose --profile legacy
> up -d` levanta el patrimonio **y** los cinco servicios nuevos, porque los servicios sin perfil
> están siempre activos. Me lo encontré escribiendo `task legacy:up`: en un repositorio donde todavía
> no existen los servicios nuevos, habría intentado construirlos. Por eso la tarea dice qué servicios
> quiere.

### 4.7 Por qué el sistema todavía no hace nada interesante

Lo que corre ahora devuelve datos poco interesantes: un precio que nunca cambia, una existencia que
nunca baja, un catálogo de dos productos. **Y eso es correcto.** El sistema se construye en tres
oleadas horizontales, cada una sobre los cinco servicios a la vez, y cada una aterriza en la fase que
la necesita:

```text
LAS TRES OLEADAS

  Fase 02  🌊 Oleada 0 · el esqueleto        salud y JSON fijo: la forma del sistema
  Fase 09  🌊 Oleada 1 · el almacén propio   cada servicio guarda lo suyo, sin cruzarse
  Fase 16  🌊 Oleada 2 · el flujo que cruza  la venta completa: el primer servicio que llama a otro
```

Durante las próximas fases, lo que aprendes es la plataforma —el contenedor por dentro, las
imágenes, los motores, el cluster—, y un dominio con lógica solo agregaría superficie donde
equivocarse. Cuando la [Fase 08](08-el-primer-despliegue.md) despliegue `pricing` en Kubernetes, te va a convenir que lo único que
pueda fallar sea Kubernetes.

### 4.8 🦭 `docker compose` y `podman compose` no son el mismo programa

`podman compose` no es un compose propio: es un comando que **delega** en el primer proveedor que
encuentra. Con Docker Desktop instalado, ese proveedor es el compose de Docker, y lo dice:

```text
>>>> Executing external compose provider "/Users/oskar/.docker/bin/docker-compose". Please see podman-compose(1) for how to disable this message. <<<<
```

Casi siempre da igual: el mismo `compose.yaml` levanta lo mismo, y la suite G0 pasó con Podman igual
que con Docker. La diferencia aparece donde duele menos esperarla. Cuando ese compose de Docker
**construye** contra Podman, le pasa las credenciales de Docker Hub guardadas por Docker, y si no le
sirven a Podman, el build falla bajando la imagen base
([a02](a02-problemas-del-ambiente.md#podman-compose-falla-con-invalid-usernamepassword)). Por eso el
Taskfile construye con el motor activo (`podman build`) antes del `compose up`, y compose solo
arranca.

Hay más de una implementación de compose —la de Docker, `podman-compose` en Python, la integrada en
otras herramientas—, y no todas soportan las mismas claves del mismo modo. Conviene saberlo hoy,
con un archivo que funciona en las dos, antes de que la diferencia aparezca en uno que no.

---

## 🩻 5. Lo que ya sabías y sigue valiendo

Compose es una herramienta buena para lo que es, y esta fase la usa con gusto:

- **Un archivo declara un sistema**, y cualquiera lo levanta con un comando. Es lo que ya hacías, y
  sigue siendo la mejor forma de tener un ambiente de desarrollo repetible.
- **Los nombres de servicio como direcciones** funcionan igual que siempre.
- **Las variables de entorno, los volúmenes y los puertos** son los mismos conceptos de la [Fase 01](01-primer-contenedor-y-dockerfile.md),
  escritos en YAML.
- **Para un sistema que corre en una máquina, compose alcanza.** Dónde deja de alcanzar, y con qué
  número, es la [Fase 06](06-del-compose-al-cluster.md). Hasta entonces, no le busques defectos.

---

## 🩺 6. Incidentes y errores comunes

Esta fase no reserva incidentes. Los errores que salieron al hacerla:

**El portal no puede sincronizar recién levantado.** Síntoma: `SOAP-ERROR: Parsing WSDL: Couldn't load
from 'http://contingencia:8080/PriceService/PriceService?wsdl'`. Causa: `depends_on` sin condición
espera a que Contingencia arranque, no a que GlassFish despliegue. Comprobación: `docker logs
lab-contingencia-1 | grep "successfully deployed"`. Salida: esperar a esa línea, o darle a
Contingencia un `healthcheck` y al portal un `condition: service_healthy`.

**El storefront responde 403 dentro de la red.** Síntoma, en la suite: `HTTP 200 … actual value is
<403>`. Causa: `vite preview` rechaza los nombres de host que no conoce, y compose lo llama
`storefront`. Comprobación: `docker compose exec replenish wget -S -qO- http://storefront:8080/`.
Salida: `preview.allowedHosts` en `vite.config.ts`, que ya está en el prompt de G0.

**Un perfil levanta más de lo que pediste.** Síntoma: `--profile legacy up -d` arranca también los
servicios nuevos, o falla construyendo uno que todavía no existe. Causa: los servicios sin perfil
siempre están activos. Salida: nombrar los servicios en el `up`, como hacen las tareas.

**El mismo proyecto en los dos motores.** Síntoma: `listen tcp 127.0.0.1:8081: bind: address already
in use` al levantar el patrimonio con Podman y con Docker a la vez. Causa: los dos quieren el puerto
del portal. Salida: un motor activo a la vez (`task engine:use`).

---

## 📋 7. Checklist de validación

```text
[ ] task legacy:up levanta los cinco servicios del patrimonio, y contingencia-db queda (healthy)
[ ] http://localhost:8081 muestra el portal, y catalog:sync trae 8 productos (después del despliegue)
[ ] los cinco servicios de G0 están generados con los prompts de a03, con su CLAUDE.md
[ ] task compose:up los construye y los levanta; http://localhost:8082 muestra el storefront
[ ] task conformance -- G0: 5 archivos, 0 fallidos
[ ] desde replenish, http://pricing:8080 y http://contingencia:8080 responden por nombre
[ ] task compose:down baja solo los servicios nuevos, y el patrimonio sigue corriendo
[ ] task contracts:docs muestra los cuatro contratos en http://localhost:8090
```

---

## 🧪 8. Ejercicios (20)

Un tercio son de diagnóstico, y varios usan el patrimonio y no `pricing`. Los que tocan la suite son
los más importantes: es la herramienta que vas a usar en cada paso de aquí en adelante.

## 🟢 Fácil — levantar y probar (1–6)

### 🟢 Ejercicio 1 — El patrimonio, con un comando
Levanta el patrimonio y espera a que Contingencia esté desplegada.

**Criterio:** `docker compose -f compose/compose.yaml --profile legacy ps` muestra los cinco servicios
del patrimonio, y `docker logs lab-contingencia-1` tiene la línea `contingencia was successfully
deployed`.

<details><summary>Solución</summary>

`task legacy:up` y `docker logs lab-contingencia-1 2>&1 | grep "successfully deployed"`.
</details>

### 🟢 Ejercicio 2 — El catálogo del portal
Sincroniza el catálogo del portal y míralo en el navegador.

**Criterio:** `http://localhost:8081` muestra ocho productos con la hora de la sincronización.

<details><summary>Solución</summary>

`docker exec lab-portal-1 php artisan catalog:sync`, una vez que Contingencia desplegó.
</details>

### 🟢 Ejercicio 3 — La Oleada 0
Levanta los cinco servicios nuevos y corre su suite.

**Criterio:** `task conformance -- G0` termina con `Succeeded files: 5 (100.0%)`.

<details><summary>Solución</summary>

`task compose:up` y `task conformance -- G0`.
</details>

### 🟢 Ejercicio 4 — Los contratos con una página
Abre Swagger UI y encuentra en qué paso llega `POST /sales` de `inventory`.

**Criterio:** `http://localhost:8090` muestra los cuatro contratos, y tu respuesta es G5 ([Fase 16](16-escalado-y-rollout.md)).

<details><summary>Solución</summary>

`task contracts:docs`; en la página, `inventory` → `POST /sales`. También está en el YAML, en
`x-lab-paso`.
</details>

### 🟢 Ejercicio 5 — Por su nombre
Desde `replenish`, pídele a `inventory` la existencia de `SKU-0003` en `DRO-007`.

**Criterio:** la respuesta es `{"store":"DRO-007","sku":"SKU-0003","quantity":24,"reorderThreshold":8}`.

<details><summary>Solución</summary>

`docker compose -f compose/compose.yaml exec replenish wget -qO- http://inventory:8080/stock/DRO-007/SKU-0003`.
</details>

### 🟢 Ejercicio 6 — Los logs de uno
Corre la suite y mira qué peticiones recibió `catalog`.

**Criterio:** `docker compose -f compose/compose.yaml logs catalog` muestra una línea por cada petición
de `catalog.g0.hurl`, incluida la de `/metrics` con 404.

<details><summary>Solución</summary>

`task conformance -- G0` y `docker compose -f compose/compose.yaml logs catalog`.
</details>

## 🟡 Intermedio — operar el proyecto (7–12)

### 🟡 Ejercicio 7 — `depends_on` no es "listo"
Baja el patrimonio con sus datos, súbelo, y corre la sincronización del catálogo apenas termine
`legacy:up`.

**Criterio:** copiaste el `SOAP-ERROR: Parsing WSDL` y, un minuto después, la sincronización exitosa.

<details><summary>Solución</summary>

`task legacy:down -- -v`, `task legacy:up`, `docker exec lab-portal-1 php artisan catalog:sync`
enseguida, y otra vez después de la línea de despliegue.
</details>

### 🟡 Ejercicio 8 — Detén uno y mira la suite
Detén `inventory` y corre la suite.

**Criterio:** la suite falla solo en `inventory.g0.hurl`, y copiaste el error de conexión.

<details><summary>Solución</summary>

`docker compose -f compose/compose.yaml stop inventory` y `task conformance -- G0`. Para volver,
`docker compose -f compose/compose.yaml up -d`.
</details>

### 🟡 Ejercicio 9 — `up -d` corrige
Borra el contenedor de `pricing` a mano y corre `up -d` del proyecto.

**Criterio:** `docker compose ps` vuelve a mostrar `pricing`, y la salida de `up -d` dice que solo
creó ese.

<details><summary>Solución</summary>

`docker rm -f lab-pricing-1` y `docker compose -f compose/compose.yaml up -d`.
</details>

### 🟡 Ejercicio 10 — Bajar sin bajar de más
Baja los servicios nuevos dejando corriendo el patrimonio.

**Criterio:** después de `task compose:down`, `docker compose -f compose/compose.yaml --profile legacy
ps` muestra los cinco del patrimonio y ninguno nuevo.

<details><summary>Solución</summary>

`task compose:down`. Con `docker compose down` se habría bajado todo.
</details>

### 🟡 Ejercicio 11 — Un traslado entre el patrimonio
Pide un préstamo a Contingencia por SOAP desde un servicio nuevo de la misma red, y síguelo hasta la
Braqui.

**Criterio:** en menos de siete minutos, `braqui_transfer` tiene tu préstamo, y el `curl` (o `wget`)
salió desde un contenedor de la red `lab_default`.

<details><summary>Solución</summary>

El sobre de `requestLoan` de [a16](a16-el-patrimonio.md#-contingencia), enviado desde un contenedor en
la red del proyecto. Es la primera vez que algo del sistema nuevo le habla al patrimonio; en G0 nadie
lo hace por trabajo, pero la red ya lo permite.
</details>

### 🟡 Ejercicio 12 — El mismo archivo con Podman
Levanta el sistema y corre la suite con Podman como motor activo.

**Criterio:** `task conformance -- G0` pasa con Podman, y copiaste la línea `Executing external
compose provider`.

<details><summary>Solución</summary>

`task compose:down` y `task legacy:down` con Docker; `task engine:use -- podman`; `task compose:up` y
`task conformance -- G0`.
</details>

## 🟠 Difícil — el contrato y la suite (13–17)

### 🟠 Ejercicio 13 — Una capacidad antes de tiempo
Agrega a `pricing` un `/metrics` que responda 200 con cualquier texto, reconstruye y corre la suite.
**Predice** qué archivo falla y en qué línea.

**Criterio:** la predicción escrita, y la salida de la suite con el fallo en `pricing.g0.hurl`.

**Rúbrica:** la predicción; el fallo literal; y por qué la suite trata como error algo que
"funciona". Deshaz el cambio al terminar.

### 🟠 Ejercicio 14 — Rompe el contrato a propósito
Cambia en `pricing` el nombre del campo `price` por `amount` (el nombre que usa Contingencia) y corre
la suite.

**Criterio:** la suite falla en las aserciones de `$.price`, y escribiste en qué orden se habría hecho
este cambio si fuera legítimo.

**Rúbrica:** la salida; el orden (contrato, suite, prompt, código); y quién tendría que estar de
acuerdo en la reunión de los cuatro equipos.

### 🟠 Ejercicio 15 — Regenera un servicio
Borra `services/replenish/` y regenéralo con el prompt G0 de [a03](a03-contratos-y-prompts-de-generacion.md),
con el asistente que uses.

**Criterio:** `task conformance -- G0` pasa con el `replenish` regenerado, y su `CLAUDE.md` tiene la
tabla del contrato paso a paso.

**Rúbrica:** el asistente usado; cuántas iteraciones hicieron falta; qué tuviste que agregar al prompt
(si algo); y si el código nuevo trae algo que G0 no pide, aunque la suite pase.

### 🟠 Ejercicio 16 — Una sonda para Contingencia
Dale a Contingencia un `healthcheck` que espere al despliegue de GlassFish, y al portal una
dependencia con `condition: service_healthy`.

**Criterio:** después de `task legacy:down -- -v` y `task legacy:up`, la sincronización del catálogo
funciona en el primer intento.

**Rúbrica:** el `healthcheck` elegido (qué comprueba y con qué herramienta de la imagen); el tiempo que
tarda `legacy:up` ahora; y lo que perdiste (un `up` más lento). No lo dejes en el archivo: la [Fase 15](15-salud-y-recursos.md)
decide cómo se hace.

### 🟠 Ejercicio 17 — Los perfiles por dentro
Corre `docker compose --profile legacy config --services` y `docker compose config --services`, y
explica la diferencia.

**Criterio:** tienes las dos listas, y una frase que explica por qué la primera incluye los servicios
nuevos.

**Rúbrica:** las dos salidas literales; la regla (los servicios sin perfil siempre están activos); y
cómo la usa el Taskfile.

## 🔴 Muy difícil — el sistema a mano (18–20)

### 🔴 Ejercicio 18 — Un sexto servicio, por contrato
Escribe el contrato, la suite G0 y el prompt de un servicio nuevo que no existe en el curso
(por ejemplo, `club`, el programa de afiliados), y genéralo.

**Criterio:** `contracts/openapi/club.yaml` válido, `club.g0.hurl` pasando contra compose, y el
servicio sin nada que G0 no pida.

**Rúbrica:** el contrato con sus pasos marcados; la suite con el caso de lo que no debe existir; el
prompt; y la salida de la suite. Bórralo al terminar: el curso tiene cinco servicios.

### 🔴 Ejercicio 19 — ¿Quién llama a quién?
Sin leer el código, averigua si algún servicio nuevo le habla a otro en G0.

**Criterio:** tienes evidencia de los logs de los cinco servicios mientras corre la suite, y una
conclusión.

**Rúbrica:** el método (los logs de cada servicio, o una captura de tráfico en la red); la evidencia;
y la conclusión: en G0, cada servicio solo recibe las peticiones de la suite.

### 🔴 Ejercicio 20 — El patrimonio sin compose
Levanta el patrimonio completo sin compose, solo con `docker run`, a partir del `compose.yaml`.

**Criterio:** el portal sincroniza el catálogo y la Braqui asigna motos, y tienes los comandos en un
archivo.

**Rúbrica:** los comandos (una red, tres volúmenes, cinco `run`, en orden); cómo resolviste la
espera de la base sin `depends_on`; y cuántas líneas te costó lo que compose dice en setenta y cuatro.

---

## 📚 9. Referencias

**Documentación oficial** (sin versión fija)

- Docker, *Compose file reference*: https://docs.docker.com/reference/compose-file/ — `services`,
  `build`, `depends_on`, `profiles`, `healthcheck`.
- Docker, *Using profiles with Compose*: https://docs.docker.com/compose/how-tos/profiles/ — los
  servicios sin perfil siempre activos.
- Docker, *Control startup order*: https://docs.docker.com/compose/how-tos/startup-order/ — por qué
  `depends_on` no espera a que el otro esté listo.
- Podman, `podman compose`: https://docs.podman.io/en/latest/markdown/podman-compose.1.html — el
  proveedor externo.
- OpenAPI 3.1.1: https://spec.openapis.org/oas/v3.1.1.html · Hurl: https://hurl.dev/docs/manual.html

**Libros**

- Sam Newman, *Building Microservices*, 2.ª edición (2021), los capítulos sobre comunicación y
  contratos entre servicios, para la idea de que el contrato es lo que se acuerda entre equipos.

**Orden de lectura sugerido:** antes, [a03](a03-contratos-y-prompts-de-generacion.md) hasta "La
suite de conformidad"; durante, la referencia del archivo de compose; después, la página de
`startup-order`, que es la mejor explicación del primer error de esta fase.

> ⚠️ Las URL y los contenidos cambian, y las de Docker y Podman no fijan versión.

---

## 🏁 10. Resultado de la fase

```text
EL SISTEMA AL CERRAR LA FASE 02 (un proyecto de compose, red lab_default)

  patrimonio (perfil legacy)                     sistema nuevo, paso G0
  ─────────────────────────                      ───────────────────────
  contingencia-db (healthy)                      pricing      JSON fijo
  contingencia   SOAP + lote                     inventory    JSON fijo
  portal         127.0.0.1:8081                  catalog      JSON fijo
  braqui         sondeo cada 30 s                replenish    JSON fijo
  braqui-traslados  cron cada 5 min              storefront   127.0.0.1:8082

  task conformance -- G0  →  5 archivos, 23 peticiones, 0 fallidos
```

> **La señal de que quedó bien:** *"Borro un servicio, lo regenero con su prompt, y sé que está bien
> porque la suite pasa, no porque se parezca al anterior."*

> 🏷️ **Tag:** `fase-02-compose-el-sistema-en-un-archivo` · prefijo de commit `f02:` ([convención de git](00-convencion-de-git-y-tags.md))
