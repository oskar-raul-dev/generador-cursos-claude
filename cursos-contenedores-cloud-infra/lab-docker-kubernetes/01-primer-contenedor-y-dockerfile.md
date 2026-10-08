# 📦 Fase 01 — Tu primer contenedor, y tu primer Dockerfile: la Braqui, tal como vino

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 01 de 27 · Parte 0 — Prolegómenos · **media**
> **Plataformas:** Windows 11 con WSL 2 · macOS Apple Silicon · Linux amd64
> **Motor de referencia:** Docker · 🦭 los verbos son los mismos en Podman; diverge el tiempo de `stop` y el nombre de las imágenes locales
> **Servicios que toca:** la Braqui, del patrimonio · **Paso de generación:** —
> **Depende de:** Fase 00 · **Habilita:** Fase 02
> **Incidentes que reserva:** ninguno
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a02](a02-problemas-del-ambiente.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64 · Windows 11 y Linux: no verificados por el autor
> **Objetivo:** empaquetar la Braqui con un Dockerfile de una sola etapa escrito línea por línea, correrla contra su base de datos con los verbos del día a día, y saber explicar con un experimento la diferencia entre `CMD` y `ENTRYPOINT`.

---

## 🧭 1. Dónde estamos

La [Fase 00](00-el-ambiente.md) dejó dos motores instalados y una pregunta que responde ✅: `task engine:status`. No hay
un solo contenedor corriendo. Esta fase pone el primero.

Valentina pasó la semana anterior peleando con el portátil corporativo —la virtualización, el motor,
el certificado del proxy—, y el equipo de la Braqui, que trabaja en Mac, la miró sin entender de qué
se quejaba (historia §6). Cuando por fin `docker info` le contestó, eligió el primer sistema para
meter en un contenedor con un criterio práctico: **el más simple de empaquetar**. Contingencia
necesita un servidor de aplicaciones y una base; el portal, PHP con sus extensiones; **la Braqui es
Node y un solo proceso**. Es código que existe, que corre en producción desde 2020 y que llegó con
la empresa que la cooperativa compró en plena pandemia (historia §1.9). No es un ejemplo hecho para
la fase: tiene sus mañas, y esta fase no las arregla. La empaqueta.

Lo que vas a hacer es lo mismo que hizo Valentina: escribir el Dockerfile de la Braqui línea por
línea, correrla, verla caerse, darle su base de datos, entrar, detenerla, y entender qué pasó en
cada paso. El código está en `src/lab/legacy/braqui/`, y cómo está hecho, en
[a16](a16-el-patrimonio.md#️-la-braqui). `pricing`, el primer servicio nuevo, todavía no existe:
nace en la [Fase 02](02-compose-el-sistema-en-un-archivo.md).

---

## 🎯 2. Objetivos de esta fase

1. Construir la imagen `lab/legacy-braqui` desde un Dockerfile de una sola etapa, y poder explicar
   para qué está cada instrucción.
2. Correr la Braqui contra el Postgres de Contingencia en una red propia, con su variable de entorno
   y un puerto publicado, y comprobar que asigna motos.
3. Usar los verbos del día a día —`run`, `ps`, `logs`, `exec`, `stop`, `rm`— y leer lo que cada uno
   responde.
4. Demostrar con un experimento la diferencia entre `CMD` y `ENTRYPOINT`.
5. Saber cuánto disco ocupan tus imágenes y cómo recuperarlo sin borrar lo que no es tuyo.

---

## 🚫 3. Qué NO entra todavía

- Las capas, el formato OCI y qué es una imagen por dentro → [Fase 03](03-el-contenedor-por-dentro.md).
- Por qué la Braqui tardó en detenerse y murió con 137 → [Fase 03](03-el-contenedor-por-dentro.md) (el PID 1) y [Fase 16](16-escalado-y-rollout.md) (el apagado
  limpio).
- El multi-stage, la caché de capas en serio y la elección de la imagen base → [Fase 04](04-empaquetar-los-cuatro-runtimes.md), que reescribe
  este Dockerfile.
- Levantar varias piezas con un archivo → [Fase 02](02-compose-el-sistema-en-un-archivo.md).
- Arreglar las mañas de la Braqui → las fases que las cobran ([a16](a16-el-patrimonio.md#-las-mañas-a-propósito)).

---

## 📦 4. El primer contenedor, y el primer Dockerfile

### 4.1 Tres sustantivos

Antes del primer comando, tres palabras que se confunden siempre y que el resto del curso usa con
precisión:

- **La imagen** es un paquete inmutable: un sistema de archivos y la instrucción de qué ejecutar. Se
  construye una vez y se reutiliza. No corre: se instancia.
- **El contenedor** es un proceso corriendo a partir de una imagen, con su propio sistema de archivos
  encima, su red y sus variables. Se crea, corre, se detiene y se borra; la imagen queda.
- **El tag** es un nombre legible y movible para una imagen: `node:24.21.0-alpine` hoy apunta a una
  imagen y mañana puede apuntar a otra. **El digest** (`node@sha256:ebfe2f…`) es el nombre que no se
  mueve: identifica el contenido exacto. Por eso el curso fija las imágenes por digest y deja el tag
  en un comentario.

> 🧠 **Modelo mental.** La imagen es la clase; el contenedor, el objeto. Se rompe en un punto que
> importa: un objeto se destruye y no deja rastro, y un contenedor detenido sigue existiendo, con su
> sistema de archivos, hasta que lo borras. Lo vas a ver en 4.3.

### 4.2 El Dockerfile de la Braqui, línea por línea

Este es el Dockerfile completo. Está en `src/lab/legacy/braqui/Dockerfile`, y si ya corriste
`task legacy:up`, la imagen que construyó salió de aquí.

```dockerfile
# node:24.21.0-alpine — la imagen base, fijada por su digest.
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1

# Todo lo que sigue pasa en /app dentro de la imagen.
WORKDIR /app

# Primero las dependencias: si el código cambia y ellas no, Docker reutiliza esta parte.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Después el código.
COPY dispatcher.js ./

# El puerto en el que escucha, si nadie dice otra cosa.
ENV PORT=8080
# Documentación para quien lea la imagen: no publica nada por sí solo.
EXPOSE 8080

# El proceso del contenedor. Se puede reemplazar al hacer docker run.
CMD ["node", "dispatcher.js"]
```

**Detalles con intención.** `FROM` por digest: si mañana alguien vuelve a publicar
`node:24.21.0-alpine` con otro contenido, esta imagen no cambia. `COPY` en dos tiempos, primero el
`package.json` y después el código: es la única optimización de esta fase, y la [Fase 04](04-empaquetar-los-cuatro-runtimes.md) explica por
qué funciona. `npm ci` y no `npm install`: instala exactamente lo del `package-lock.json`, o falla.
`ENV PORT=8080` es un valor por defecto que `docker run -e` puede cambiar. Y **`EXPOSE` no publica
nada**: es una nota para quien lea la imagen; el puerto se publica al correr el contenedor, con `-p`.

Se construye desde `src/lab/`:

```text
$ docker build --no-cache -t lab/legacy-braqui legacy/braqui
#5 [1/5] FROM docker.io/library/node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1
#6 [2/5] WORKDIR /app
#7 [3/5] COPY package.json package-lock.json ./
#8 [4/5] RUN npm ci --omit=dev
#8 1.317 added 14 packages, and audited 15 packages in 1s
#8 DONE 1.4s
#9 [5/5] COPY dispatcher.js ./
#10 naming to docker.io/lab/legacy-braqui:latest done
$ docker images lab/legacy-braqui
IMAGE                      ID             DISK USAGE   CONTENT SIZE   EXTRA
lab/legacy-braqui:latest   d71083af6247        242MB         62.8MB
```

Dos segundos, casi todo `npm ci`: la imagen base ya estaba descargada. Fíjate en el nombre que le
puso Docker: `docker.io/lab/legacy-braqui:latest`. Le diste `lab/legacy-braqui` y completó el
registry (`docker.io`) y el tag (`latest`). Esa normalización va a importar en la [Fase 08](08-el-primer-despliegue.md).

> 📝 **La nota del toolchain, y es propia de este curso.** Con las versiones actuales de los cuatro
> runtimes, **ninguna imagen del laboratorio necesita un compilador**: Node trae binarios
> precompilados, las extensiones de PHP vienen en las imágenes oficiales (o se compilan con lo que
> la imagen ya trae), Java no compila nada nativo y Go compila estático en su propia etapa. La
> Braqui lo confirma: sus 14 paquetes son JavaScript puro. **Deja de ser verdad** cuando una
> dependencia no publica binario para tu arquitectura (el síntoma es un `npm ci` que de pronto
> necesita `python3` y `make`), cuando una extensión de PHP no está empaquetada, o cuando una
> dependencia nativa se compiló contra glibc y tu base es Alpine, que usa musl (el síntoma es un
> `Error loading shared library` al arrancar).

### 4.3 El primer `docker run`, y la primera caída

```text
$ docker run -d --name braqui lab/legacy-braqui
402990700fb648365cd774291e082bf097cf9efa1770514a8c62fda29cabbf14
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

`-d` lo deja corriendo en segundo plano y devuelve su id. Y `docker ps`, que lista los contenedores
**corriendo**, no muestra nada. Algo pasó en esos tres segundos, y lo cuenta `logs`:

```text
$ docker logs braqui
Braqui despachando cada 30 s
/app/node_modules/pg-pool/index.js:45
    Error.captureStackTrace(err)
          ^

AggregateError [ECONNREFUSED]:
    at /app/node_modules/pg-pool/index.js:45:11
    at async assignPending (/app/dispatcher.js:11:18) {
  code: 'ECONNREFUSED',
  [errors]: [
    Error: connect ECONNREFUSED ::1:5432
    …
    Error: connect ECONNREFUSED 127.0.0.1:5432
    …
Node.js v24.21.0
```

La Braqui buscó su base en `localhost:5432`, que es el valor por defecto del cliente de Postgres
cuando no hay `DATABASE_URL`, no la encontró, y se cayó. **No reintenta**: la conexión está fuera
del `try` del sondeo, así que un error ahí termina el proceso. Es una maña del código de 2023, y en
producción la tapaba un supervisor que la levantaba de nuevo. Aquí no hay nadie que la levante:

```text
$ docker ps -a --filter name=braqui
CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS                     PORTS     NAMES
402990700fb6   lab/legacy-braqui   "docker-entrypoint.s…"   9 seconds ago   Exited (1) 8 seconds ago             braqui
$ docker inspect braqui --format '{{.State.Status}} exit={{.State.ExitCode}} reinicios={{.RestartCount}}'
exited exit=1 reinicios=0
$ docker rm braqui
braqui
```

`docker ps -a` muestra también los detenidos: el contenedor existe, con estado `Exited (1)`, y existe
hasta que lo borras con `rm`. Esa es la parte del modelo mental de 4.1 que se rompe.

### 4.4 Una red y una base

La Braqui necesita la base de Contingencia, porque desde 2023 lee y escribe sus tablas. La levanto
en un contenedor, en una **red propia**, con los datos iniciales de Contingencia montados desde el
disco:

```bash
docker network create rebotica
docker run -d --name contingencia-db --network rebotica \
  -e POSTGRES_DB=contingencia -e POSTGRES_USER=contingencia -e POSTGRES_PASSWORD=contingencia-lab \
  -v "$PWD/legacy/contingencia/db":/docker-entrypoint-initdb.d:ro \
  -v contingencia-datos:/var/lib/postgresql \
  postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722
```

```powershell
docker run -d --name contingencia-db --network rebotica `
  -e POSTGRES_DB=contingencia -e POSTGRES_USER=contingencia -e POSTGRES_PASSWORD=contingencia-lab `
  -v "${PWD}/legacy/contingencia/db:/docker-entrypoint-initdb.d:ro" `
  -v contingencia-datos:/var/lib/postgresql `
  postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722
```

*(El bloque de PowerShell: no verificado por el autor.)* Hay dos `-v`, y son de dos tipos distintos.
El primero monta **una carpeta de tu disco** dentro del contenedor, en solo lectura (`:ro`): la
imagen de Postgres ejecuta los `.sql` que encuentre ahí la primera vez que arranca. El segundo es un
**volumen con nombre**, `contingencia-datos`, que el motor administra: ahí quedan los datos, y
sobreviven al contenedor (4.7).

Ahora la Braqui, en la misma red, con su `DATABASE_URL` y un puerto publicado:

```text
$ docker run -d --name braqui --network rebotica \
    -e DATABASE_URL=postgres://contingencia:contingencia-lab@contingencia-db:5432/contingencia \
    -p 127.0.0.1::8080 lab/legacy-braqui
57dc60dad23d3c2180f64c9c5c70a219158cf58fdf0d16872407a43307a2a6ab
$ docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS         PORTS                       NAMES
57dc60dad23d   lab/legacy-braqui   "docker-entrypoint.s…"   3 seconds ago   Up 3 seconds   127.0.0.1:53624->8080/tcp   braqui
68fc85c6ddc0   5a5a84b19854        "docker-entrypoint.s…"   6 seconds ago   Up 6 seconds   5432/tcp                    contingencia-db
```

Tres cosas para leer en esa tabla. **La Braqui llama a la base `contingencia-db`**, el nombre del
contenedor: en una red creada por ti, el motor resuelve los nombres de los contenedores. **`-p
127.0.0.1::8080`** publica el puerto 8080 del contenedor en un puerto libre del host, elegido por el
motor, y solo en `127.0.0.1`: nadie más en tu red puede entrar. **Postgres no publica nada** (`5432/tcp`
sin flecha): la Braqui llega a él por la red interna, y tu máquina no necesita verlo.

```text
$ docker port braqui
8080/tcp -> 127.0.0.1:53624
$ curl -s http://127.0.0.1:53624/dispatches
[{"id":"3","storeId":"DRO-008","address":"Avenida Pradilla # 9-15, Chía","rider":"Camilo Quintero",…},…]
$ docker logs braqui
Braqui despachando cada 30 s
despacho 1 (DRO-001, Calle 48 # 33-21, Cabecera) asignado a Jhon Fredy Ardila
despacho 2 (DRO-007, Carrera 13 # 57-40, Chapinero) asignado a Yeison Patiño
despacho 3 (DRO-008, Avenida Pradilla # 9-15, Chía) asignado a Camilo Quintero
```

La Braqui ya despacha: leyó los tres domicilios pendientes de la tabla `dispatch` de Contingencia y
les asignó moto.

> ⚠️ **`-p 8080:8080`, sin dirección, publica en todas las interfaces**: cualquiera en tu red Wi‑Fi
> llega al contenedor. En el laboratorio siempre se publica en `127.0.0.1`, y en la oficina de una
> cooperativa con política de seguridad, conviene que sea un hábito.

### 4.5 Entrar

```text
$ docker exec braqui sh -c "ps; ls /app"
PID   USER     TIME  COMMAND
    1 root      0:00 {MainThread} node dispatcher.js
   18 root      0:00 sh -c ps; ls /app
   24 root      0:00 ps
dispatcher.js
node_modules
package-lock.json
package.json
$ docker exec braqui wget -qO- localhost:8080/nada
wget: server returned error: HTTP/1.1 404 Not Found
```

`exec` corre un comando **dentro** de un contenedor que ya está corriendo, sin crear otro. Con `-it`
y `sh` te da una terminal adentro. Y lo que muestra `ps` adentro vale la pena mirarlo con calma:
**`node dispatcher.js` es el proceso 1**, el único del contenedor, y **corre como `root`**. Las dos
cosas tienen consecuencias, y las cobran la [Fase 03](03-el-contenedor-por-dentro.md) y la [Fase 20](20-seguridad-del-pod-y-de-la-red.md). La siguiente sección muestra la
primera.

### 4.6 Detener

```text
$ time docker stop braqui
braqui
docker stop braqui  0.01s user 0.01s system 0% cpu 3.159 total
$ docker inspect braqui --format '{{.State.ExitCode}}'
137
```

`docker stop` le manda `SIGTERM` al proceso 1, espera, y si el proceso no termina, le manda
`SIGKILL`. El código 137 dice cuál de las dos terminó el trabajo: 128 + 9, la señal 9, `SIGKILL`. **La
Braqui no se detuvo: la mataron.** Node como proceso 1 no atiende `SIGTERM` por defecto, y la Braqui
no instala ningún manejador. En una moto real eso es un despacho que se asignó en la base y nunca se
le avisó a nadie; aquí, por ahora, es una nota. El porqué del proceso 1 es la [Fase 03](03-el-contenedor-por-dentro.md), y el apagado
limpio, la [Fase 16](16-escalado-y-rollout.md).

> 🦭 **Cuánto espera, depende del motor, y no coincide con la documentación.** La documentación de
> Docker dice que el motor espera 10 segundos antes del `SIGKILL`. Con Docker Desktop, en la versión
> de [a01](a01-el-laboratorio.md), medí **3,1 a 3,2 segundos**, cuatro veces; con `docker stop -t 10`,
> 10,16. Podman, con el mismo proceso, esperó **10,2 segundos**. Los dos terminaron en 137. Si tu
> aplicación necesita más tiempo para cerrar, no confíes en el valor por defecto de ninguno: pásalo
> con `-t`, o con `--stop-timeout` al crear el contenedor.

### 4.7 Volúmenes: lo que sobrevive

El Postgres de 4.4 guardó sus datos en el volumen `contingencia-datos`. Para ver qué significa, borro
el contenedor de la base —no el volumen— y lo creo de nuevo con el mismo comando:

```text
$ docker rm -f contingencia-db
contingencia-db
$ docker volume ls --filter name=contingencia-datos
DRIVER    VOLUME NAME
local     contingencia-datos
$ docker run -d --name contingencia-db … (el mismo comando de 4.4)
$ docker logs contingencia-db | grep -i skipping
PostgreSQL Database directory appears to contain a database; Skipping initialization
$ docker exec contingencia-db psql -U contingencia -d contingencia -c "select id, status, rider_id from dispatch"
 id |  status  | rider_id
----+----------+----------
  1 | ASSIGNED |        1
  2 | ASSIGNED |        2
  3 | ASSIGNED |        3
(3 rows)
```

El contenedor es desechable; **el volumen, no**. Postgres encontró sus datos, se saltó los `.sql`
iniciales, y los despachos que la Braqui asignó siguen asignados. Las dos formas de montar, en una
línea cada una:

- **Carpeta del host** (`-v "$PWD/…":/ruta`): para darle al contenedor archivos que tú editas. Si
  borras la carpeta, se fue.
- **Volumen con nombre** (`-v nombre:/ruta`): para que el contenedor guarde datos que tienen que
  sobrevivirlo. Vive en la máquina virtual del motor, y se borra con `docker volume rm`.

### 4.8 `CMD` contra `ENTRYPOINT`

Casi nadie lo explica bien, porque casi siempre "funciona". La diferencia es una sola: **`CMD` es lo
que el contenedor ejecuta si no le dices otra cosa; `ENTRYPOINT` es el programa, y lo que le digas se
le pasa como argumentos.**

La imagen de la Braqui tiene las dos, y la mitad no la escribiste tú:

```text
$ docker image inspect lab/legacy-braqui --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
["docker-entrypoint.sh"] ["node","dispatcher.js"]
```

El `ENTRYPOINT` viene de la imagen base de Node: un script que, entre otras cosas, ejecuta lo que
reciba. Por eso la columna `COMMAND` de `docker ps` decía `docker-entrypoint.s…`. Con `CMD`, lo que
pongas después del nombre de la imagen **reemplaza** el `CMD`:

```text
$ docker run --rm lab/legacy-braqui node --version
v24.21.0
$ docker run --rm lab/legacy-braqui echo "hola desde la Braqui"
hola desde la Braqui
```

Ahora una variante, solo para el experimento: `ENTRYPOINT ["node"]` y `CMD ["dispatcher.js"]`.

```text
$ docker image inspect braqui-entrypoint --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
["node"] ["dispatcher.js"]
$ docker run --rm braqui-entrypoint --version
v24.21.0
$ docker run --rm braqui-entrypoint node --version
node:internal/modules/cjs/loader:1568
  throw err;
  ^

Error: Cannot find module '/app/node'
```

Con `ENTRYPOINT ["node"]`, lo que escribes después de la imagen se le **agrega** a `node`. `--version`
funciona porque queda `node --version`. Pero `node --version` queda `node node --version`, y Node
busca un archivo llamado `node` en `/app`. Para cambiar el programa mismo hay que decirlo con otra
opción:

```text
$ docker run --rm --entrypoint sh braqui-entrypoint -c "node --version"
v24.21.0
```

**El patrón a memorizar.** `ENTRYPOINT` cuando la imagen **es** un programa y quien la corre solo le
pasa argumentos (una herramienta de línea de comandos, por ejemplo); `CMD` cuando la imagen corre un
servicio que alguien puede querer reemplazar al depurar. La Braqui usa `CMD` sobre el `ENTRYPOINT` de
la base, y eso le permite a la [Fase 03](03-el-contenedor-por-dentro.md) entrar con `docker run … sh`. Y una regla que la [Fase 03](03-el-contenedor-por-dentro.md) va a
justificar: siempre la forma JSON (`["node", "dispatcher.js"]`) y nunca la de texto (`node
dispatcher.js`), porque la de texto mete un `sh` como proceso 1.

### 4.9 De dónde salen las imágenes

`FROM node@sha256:…` le pidió la imagen base a un **registry**: Docker Hub, si el nombre no dice
otro (`docker.io` es lo que Docker completa). Hay más, y en este curso aparecen varios: `ghcr.io` (la
imagen de GlassFish), `gcr.io` (la de distroless), `registry.k8s.io` (las de Kubernetes), y en la
[Fase 19](19-tls-y-certificados.md), uno propio.

**Por qué tu descarga falló a la tercera.** Docker Hub limita las descargas: **100 cada 6 horas** por
dirección IP si no te autenticas, **200** a un usuario personal autenticado. En una oficina detrás de
una sola IP pública, cien descargas se van en una mañana de tres personas construyendo imágenes, y
el error llega a quien estaba de turno. La salida es autenticarse (`docker login`) o usar un registry
espejo; el curso fija sus imágenes por digest, y una imagen ya descargada no cuenta como descarga
nueva. *(No reproduje el límite; los números son los de la documentación de Docker Hub.)*

Y la otra razón por la que una descarga falla en una empresa —un proxy que inspecciona TLS— es el
[incidente 27](cuaderno-incidentes.md#-incidente-27--en-el-portátil-de-la-empresa-no-baja-ninguna-imagen).

> 🦭 **Los nombres de las imágenes locales no son iguales.** Docker completa `lab/legacy-braqui` como
> `docker.io/lab/legacy-braqui`; Podman, como `localhost/lab/legacy-braqui`. Si en Podman pides
> `docker.io/lab/legacy-braqui`, la busca en Docker Hub y responde `requested access to the resource
> is denied`. La [Fase 05](05-los-dos-motores.md) cuenta por qué, y la [Fase 08](08-el-primer-despliegue.md) por qué importa.

### 4.10 La limpieza del disco

Es el problema operativo más común de quien empieza, y llega sin avisar: un día el build falla con
*no space left on device*. Primero se mira, después se limpia:

```text
$ podman system df
TYPE           TOTAL       ACTIVE      SIZE        RECLAIMABLE
Images         117         0           5.437GB     5.437GB (100%)
Containers     0           0           0B          0B (0%)
Local Volumes  2           0           54.17MB     54.17MB (100%)
$ podman image prune -f
$ podman system df
TYPE           TOTAL       ACTIVE      SIZE        RECLAIMABLE
Images         78          0           4.809GB     4.809GB (100%)
$ podman system prune -a -f
Deleted Networks
kind
Total reclaimed space: 20.07GB
$ podman system df
TYPE           TOTAL       ACTIVE      SIZE        RECLAIMABLE
Images         0           0           0B          0B (0%)
Containers     0           0           0B          0B (0%)
Local Volumes  2           0           54.17MB     54.17MB (100%)
```

`image prune` borra solo las imágenes **colgantes** —las que perdieron su nombre cuando reconstruiste
con el mismo tag—, que fueron 39. `system prune -a` borra **todo lo que no está en uso**: imágenes,
redes y caché de build. Fíjate en que recuperó 20 GB, cuatro veces lo que `system df` contaba como
imágenes; la diferencia es caché de construcción y capas que la tabla no muestra. Los volúmenes no se
tocaron: para eso hace falta `--volumes`, y **ese es el que borra datos**.

> ⚠️ **Lo corrí en Podman, y no en Docker, a propósito.** En el Docker de mi máquina hay trabajo de
> otros proyectos, y `docker system prune -a` lo habría borrado sin preguntar. En una máquina
> compartida, limpia lo tuyo por nombre (`docker rm`, `docker image rm`, `docker volume rm`) y deja
> los `prune` para cuando sabes que todo lo que hay es desechable. Los comandos son idénticos en los
> dos motores.

Lo de esta fase se limpia así, por nombre:

```text
$ docker rm -f braqui contingencia-db && docker network rm rebotica && docker volume rm contingencia-datos
braqui
contingencia-db
rebotica
contingencia-datos
```

---

## 🩻 5. Lo que ya sabías y sigue valiendo

> 🩻 **Esto sí funciona igual en Podman.** Todos los verbos de esta fase —`build`, `run`, `ps`,
> `logs`, `exec`, `stop`, `rm`, `network`, `volume`, `system df`— son los mismos, con las mismas
> opciones. Cambia el nombre del programa y dos detalles que la fase marca con 🦭.

Y de tu trabajo de siempre:

- **Un contenedor es un proceso.** `ps`, las señales, el código de salida y la salida estándar
  funcionan como en cualquier proceso Linux. Lo que cambia es lo que el proceso ve a su alrededor.
- **Las variables de entorno siguen siendo variables de entorno.** `-e DATABASE_URL=…` es lo mismo que
  exportarla antes de correr el programa.
- **Los logs son la salida estándar.** Si tu programa escribe en la consola, `docker logs` lo tiene.
  Si escribe en un archivo, no: el curso lo cobra en la [Fase 18](18-logs.md).
- **`npm ci` es `npm ci`.** El Dockerfile no inventa ninguna forma nueva de instalar dependencias:
  corre los mismos comandos que ya corres, en un sistema limpio.

---

## 🩺 6. Incidentes y errores comunes

Esta fase no reserva incidentes. Estos son los errores que salieron al hacerla, con su salida:

**El contenedor se cae y `docker ps` no lo muestra.** Síntoma: `docker ps` vacío justo después de un
`run -d`. Comprobación: `docker ps -a` lo muestra `Exited (1)`, y `docker logs <nombre>` dice por qué.
En la Braqui fue `connect ECONNREFUSED 127.0.0.1:5432`: no había base y el código no reintenta.

**El `ENTRYPOINT` que se come el comando.** Síntoma: `Error: Cannot find module '/app/node'` al correr
`docker run <imagen> node --version`. Causa: la imagen tiene `ENTRYPOINT ["node"]` y lo que escribes
se le agrega. Comprobación: `docker image inspect <imagen> --format '{{json .Config.Entrypoint}}'`.
Salida: `--entrypoint`, o no repetir el programa.

**El puerto que ya está ocupado.** Síntoma, al crear un contenedor o un cluster que publica un puerto
fijo: `listen tcp 127.0.0.1:8080: bind: address already in use`. Comprobación: `docker ps` (y, con
dos motores, `podman ps`) para ver quién lo tiene. Salida: publicar en otro puerto, o en uno elegido
por el motor (`-p 127.0.0.1::8080`).

**La imagen que Podman no encuentra.** Síntoma: `requested access to the resource is denied` al
correr una imagen que construiste. Causa: Podman la guardó como `localhost/…` y le pediste
`docker.io/…`. Comprobación: `podman images`. Salida: usar el nombre que muestra `podman images`.

---

## 📋 7. Checklist de validación

```text
[ ] docker build -t lab/legacy-braqui legacy/braqui termina, y docker images la lista
[ ] docker run -d sin DATABASE_URL deja un contenedor Exited (1), y docker logs dice ECONNREFUSED
[ ] con la red rebotica y contingencia-db, docker logs braqui muestra despachos asignados
[ ] docker port braqui muestra un puerto en 127.0.0.1, y curl a /dispatches responde JSON
[ ] docker exec braqui sh -c ps muestra node dispatcher.js como PID 1
[ ] docker stop braqui termina con código 137, y sabes decir por qué
[ ] después de recrear contingencia-db, los despachos siguen ASSIGNED
[ ] sabes explicar con un experimento qué pasa con docker run <imagen> node --version según CMD o ENTRYPOINT
[ ] limpiaste por nombre lo que creaste en la fase
```

---

## 🧪 8. Ejercicios (20)

Un tercio es de diagnóstico: un contenedor que se cae, una imagen que no se encuentra, un puerto
ocupado. Y al menos uno usa otra pieza del patrimonio, porque la Braqui es el caso fácil.

## 🟢 Fácil — los verbos del día a día (1–6)

### 🟢 Ejercicio 1 — Construye la Braqui
Construye la imagen de la Braqui sin caché.

**Criterio:** `docker images lab/legacy-braqui` la lista, y el build mostró los cinco pasos
(`[1/5]` a `[5/5]`).

<details><summary>Solución</summary>

Desde `src/lab/`: `docker build --no-cache -t lab/legacy-braqui legacy/braqui`.
</details>

### 🟢 Ejercicio 2 — Vela caerse
Corre la Braqui sin base y encuentra por qué se cae.

**Criterio:** `docker ps -a --filter name=braqui` la muestra `Exited (1)`, y copiaste de `docker logs`
la línea con `ECONNREFUSED`.

<details><summary>Solución</summary>

`docker run -d --name braqui lab/legacy-braqui`, `docker ps -a --filter name=braqui`, `docker logs
braqui`, y `docker rm braqui` al terminar.
</details>

### 🟢 Ejercicio 3 — Dale su base
Levanta la red, la base de Contingencia y la Braqui, como en 4.4.

**Criterio:** `docker logs braqui` muestra los tres despachos asignados, y `docker port braqui` un
puerto en `127.0.0.1`.

<details><summary>Solución</summary>

Los tres comandos de 4.4: `docker network create rebotica`, el `run` de `contingencia-db` y el de
`braqui` con `DATABASE_URL` y `-p 127.0.0.1::8080`.
</details>

### 🟢 Ejercicio 4 — Pregúntale a la Braqui
Consulta los últimos despachos de la Braqui desde tu máquina y desde adentro del contenedor.

**Criterio:** `curl` al puerto publicado y `docker exec braqui wget -qO- localhost:8080/dispatches`
devuelven el mismo JSON.

<details><summary>Solución</summary>

El puerto sale de `docker port braqui 8080`. Adentro, el puerto es siempre 8080: el publicado solo
existe en tu máquina.
</details>

### 🟢 Ejercicio 5 — Los mismos verbos con Podman
Repite los ejercicios 1 y 3 con Podman.

**Criterio:** `podman logs braqui` muestra despachos asignados, y escribiste el único cambio que
tuviste que hacer en los comandos.

<details><summary>Solución</summary>

Cambiar `docker` por `podman`. La imagen queda como `localhost/lab/legacy-braqui`, y `podman run …
lab/legacy-braqui` la encuentra igual.
</details>

### 🟢 Ejercicio 6 — Limpia por nombre
Borra todo lo que creaste en la fase sin usar ningún `prune`.

**Criterio:** `docker ps -a`, `docker network ls` y `docker volume ls` ya no muestran `braqui`,
`contingencia-db`, `rebotica` ni `contingencia-datos`.

<details><summary>Solución</summary>

`docker rm -f braqui contingencia-db`, `docker network rm rebotica`, `docker volume rm
contingencia-datos`.
</details>

## 🟡 Intermedio — volúmenes, puertos y nombres (7–12)

### 🟡 Ejercicio 7 — La base de otra pieza
Corre solo el Postgres de Contingencia y consulta, desde adentro, cuántos productos y cuántas
droguerías tiene.

**Criterio:** `docker exec contingencia-db psql -U contingencia -d contingencia -c "select count(*)
from product"` devuelve 8, y el de `store`, 8.

<details><summary>Solución</summary>

El `run` de 4.4 y dos `psql` con `docker exec`. Los datos son los de `legacy/contingencia/db/`.
</details>

### 🟡 Ejercicio 8 — ¿Sobrevive sin volumen?
Repite el experimento de 4.7, pero creando la base **sin** el volumen con nombre.

**Criterio:** después de recrear el contenedor, el log dice que inicializó la base (no `Skipping
initialization`) y los despachos vuelven a `PENDING`.

<details><summary>Solución</summary>

Sin `-v contingencia-datos:…`, los datos viven en el sistema de archivos del contenedor y se van con
él. La imagen de Postgres declara un volumen anónimo, pero un `docker run` nuevo crea otro.
</details>

### 🟡 Ejercicio 9 — `CMD` reemplazado
Usa la imagen de la Braqui para ver qué versión de npm trae, sin cambiar el Dockerfile.

**Criterio:** la salida es una versión de npm, obtenida con un solo `docker run --rm`.

<details><summary>Solución</summary>

`docker run --rm lab/legacy-braqui npm --version`. Lo que va después de la imagen reemplaza el `CMD`.
</details>

### 🟡 Ejercicio 10 — El puerto ocupado
Corre dos Braquis que publiquen el mismo puerto fijo del host (por ejemplo, `-p 127.0.0.1:8085:8080`)
y lee el error.

**Criterio:** copiaste el `bind: address already in use` del segundo, y lo arreglaste sin detener el
primero.

<details><summary>Solución</summary>

El segundo con otro puerto, o con `-p 127.0.0.1::8080` para que el motor elija uno libre.
</details>

### 🟡 Ejercicio 11 — `EXPOSE` no publica
Corre la Braqui sin `-p` y comprueba si llegas a ella desde tu máquina.

**Criterio:** `docker port braqui` no muestra nada, y explicaste en una línea qué hace entonces el
`EXPOSE 8080` del Dockerfile.

<details><summary>Solución</summary>

Nada que se vea desde afuera: es documentación de la imagen. El puerto se publica con `-p` al correr.
</details>

### 🟡 Ejercicio 12 — El nombre que Podman no encuentra
Con la Braqui construida en Podman, pídele a Podman que corra `docker.io/lab/legacy-braqui`.

**Criterio:** copiaste `requested access to the resource is denied`, y el comando que sí funciona.

<details><summary>Solución</summary>

`podman images` muestra `localhost/lab/legacy-braqui`. Con ese nombre, o con `lab/legacy-braqui`, corre.
</details>

## 🟠 Difícil — señales, imágenes y dependencias (13–17)

### 🟠 Ejercicio 13 — ¿Cuánto espera `stop`?
Mide cuánto tarda `stop` con la Braqui en tu motor, con el valor por defecto y con `-t 10`. **Apuesta
antes** los dos números.

**Criterio:** tienes la apuesta y cinco mediciones de cada caso, con su código de salida.

**Rúbrica:** la apuesta escrita antes; las mediciones con mediana; el código 137 explicado; y la
comparación con lo que dice la documentación de tu motor.

### 🟠 Ejercicio 14 — Rompe la Braqui con una variable
Corre la Braqui con un `DATABASE_URL` que apunte a una base que no existe dentro del servidor (por
ejemplo, `/no_existe`). **Predice** si se cae o sigue corriendo.

**Criterio:** la predicción escrita, y la línea del log que la confirma o la desmiente.

**Rúbrica:** la predicción; el síntoma literal; y la explicación de por qué este error y el de 4.3 se
comportan igual o distinto (dónde está el `try` en `dispatcher.js`).

### 🟠 Ejercicio 15 — La Braqui reemplazable
Escribe una variante del Dockerfile en la que `docker run <imagen> --inspect` arranque la Braqui con
el depurador de Node, sin dejar de poder correr `sh`.

**Criterio:** `docker run <imagen>` arranca la Braqui, `docker run <imagen> --inspect` también (con
el aviso del depurador en el log), y `docker run --entrypoint sh <imagen> -c "node --version"`
funciona.

**Rúbrica:** el Dockerfile con su `ENTRYPOINT` y su `CMD`; las tres salidas; y una frase sobre qué
perdiste frente al de la fase.

### 🟠 Ejercicio 16 — Lo que de verdad ocupa
Compara lo que `docker images` dice de la imagen de la Braqui con lo que suman sus partes.

**Criterio:** tienes `DISK USAGE` y `CONTENT SIZE` de la imagen, el tamaño de la imagen base de Node,
y una explicación de la diferencia entre las dos columnas.

**Rúbrica:** los tres números; la explicación (lo comprimido frente a lo desempaquetado, y lo que la
Braqui agregó encima de la base); y qué parte esperas que achique la [Fase 04](04-empaquetar-los-cuatro-runtimes.md).

### 🟠 Ejercicio 17 — El toolchain que deja de alcanzar
Agrega a una copia de la Braqui una dependencia con código nativo (por ejemplo, `bcrypt`) y
construye. **Predice** si el build pasa en una base Alpine.

**Criterio:** la predicción escrita, y la salida del build (que pase, o el error).

**Rúbrica:** la predicción; el síntoma literal si falló (y si aparece `python3` o `make`, por qué);
qué agregarías a la imagen para que pase, y cuánto pesa después.

## 🔴 Muy difícil — más allá de la Braqui (18–20)

### 🔴 Ejercicio 18 — La Braqui que no se cae
Sin tocar `dispatcher.js`, consigue que el contenedor de la Braqui sobreviva a que la base no esté
cuando arranca.

**Criterio:** con la base apagada al arrancar, la Braqui termina asignando motos cuando la base
aparece, sin que tú vuelvas a correr nada.

**Rúbrica:** el mecanismo elegido (una política de reinicio, `--restart`, u otro); la evidencia
(`docker ps -a` con los reinicios y el log con las asignaciones); y por qué esto tapa el síntoma y no
arregla la maña.

### 🔴 Ejercicio 19 — Docker Desktop contra la documentación
Encuentra de dónde sale el tiempo de espera de `stop` en tu Docker, y documéntalo.

**Criterio:** tienes la medición, el valor de `docker inspect <contenedor> --format
'{{.Config.StopTimeout}}'`, y lo que encontraste en la configuración del motor o en su documentación.

**Rúbrica:** la medición con dispersión; la búsqueda (configuración del motor, documentación,
versión); y una conclusión honesta, aunque sea "no lo encontré".

### 🔴 Ejercicio 20 — Una imagen para el portal
Construye la imagen del portal (`legacy/portal/`) y córrela sin Contingencia. **Predice** qué ves en
`http://localhost:<puerto>/` y qué pasa con `php artisan catalog:sync`.

**Criterio:** tus dos predicciones escritas; la página del portal en el navegador; y la salida de
`catalog:sync` sin Contingencia.

**Rúbrica:** las predicciones; las dos salidas literales; y por qué el portal, a diferencia de la
Braqui, arranca sin su dependencia (cuándo la usa cada uno).

---

## 📚 9. Referencias

**Documentación oficial** (sin versión fija)

- Docker, *Dockerfile reference*: https://docs.docker.com/reference/dockerfile/ — `CMD`,
  `ENTRYPOINT`, `EXPOSE` y su relación.
- Docker, `docker container stop`: https://docs.docker.com/reference/cli/docker/container/stop/ —
  el tiempo de espera documentado.
- Docker, *Volumes*: https://docs.docker.com/engine/storage/volumes/ · *Bind mounts*:
  https://docs.docker.com/engine/storage/bind-mounts/
- Docker Hub, *Usage and limits*: https://docs.docker.com/docker-hub/usage/
- Docker, *Prune unused objects*: https://docs.docker.com/engine/manage-resources/pruning/
- La imagen oficial de Postgres, y su `docker-entrypoint-initdb.d`: https://hub.docker.com/_/postgres

**Libros**

- Burns, Beda, Hightower y Evenson, *Kubernetes: Up and Running*, 3.ª edición (2022), capítulo 2
  sobre contenedores, si quieres el modelo mental desde el otro lado.

**Orden de lectura sugerido:** antes, nada; durante, la referencia del Dockerfile abierta en
`CMD`/`ENTRYPOINT`; después, la página de *pruning*, antes de la primera vez que te quedes sin
disco.

> ⚠️ Las URL y los contenidos cambian, y las de Docker no fijan versión.

---

## 🏁 10. Resultado de la fase

```text
LO QUE QUEDA AL CERRAR LA FASE 01

  la imagen lab/legacy-braqui (242 MB), construida desde un Dockerfile de una etapa
  nada corriendo: la red, la base y el volumen de la fase se borraron por nombre
  y tres preguntas abiertas, con fase de destino:
    ¿por qué murió con 137?           → Fase 03 y Fase 16
    ¿por qué pesa 242 MB?             → Fase 04
    ¿por qué corre como root?         → Fase 20
```

> **La señal de que quedó bien:** *"Le muestro a alguien `docker run --rm lab/legacy-braqui node
> --version` y la variante con `ENTRYPOINT`, y sabe predecir qué hace cada una antes de que yo
> presione Enter."*

> 🏷️ **Tag:** `fase-01-primer-contenedor-y-dockerfile` · prefijo de commit `f01:` ([convención de git](00-convencion-de-git-y-tags.md))
