# 🏗️ Fase 04 — Empaquetar los cuatro runtimes: un patrón, cuatro facturas

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 04 de 27 · Parte I — El modelo y el salto · **densa** ⭐
> **Perfil:** compose, sin cluster · `medicion` para 📏 · **Observabilidad encendida:** ninguna
> **Motor de referencia:** Docker · 🦭 no diverge en los Dockerfile; la medición con Podman es de la [Fase 05](05-los-dos-motores.md)
> **Servicios que toca:** los cinco · **Paso de generación:** ninguno (cambian las imágenes, no el código)
> **Depende de:** [Fase 03](03-el-contenedor-por-dentro.md) · **Habilita:** [Fase 05](05-los-dos-motores.md)
> **Incidentes que reserva:** ninguno · **Medición:** B-04
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md)
> **Fecha de verificación ejecutada:** 03/10/2026 · macOS arm64
> **Objetivo:** reescribir los cinco Dockerfile como multi-stage, medir con `task measure -- B-04` cuánto cuesta empaquetar cada runtime, y que la suite G0 siga pasando con las imágenes nuevas.

---

## 🧭 1. Dónde estamos

La [Fase 03](03-el-contenedor-por-dentro.md) terminó con una cuenta incómoda: la imagen de `pricing` pesa 507 MB para correr un
binario de 8,6. Las otras cuatro tienen el mismo defecto con otro tamaño, porque los cinco Dockerfile
de G0 son de una sola etapa a propósito: se construye y se corre en la misma imagen, con el
compilador, el gestor de paquetes y la caché adentro, y como `root`. Para el esqueleto alcanzaba.
Para un cluster que va a cargar cada imagen en cada nodo, no.

La reunión en la que esto dejó de ser un detalle técnico fue la de presupuesto. Martha Lucía, la
vicepresidenta financiera, tenía delante la cuenta de Java por empleado (historia §4) y una sola
pregunta para Valentina:

> *"Esa imagen de `inventory`, la de Java, ¿nos mete en la cuenta de las 4.200 personas?"*

Germán contestó antes que Valentina, con la carpeta de las ofertas en la mano: la imagen base de
`inventory` es **Eclipse Temurin**, la distribución de OpenJDK de la fundación Eclipse, no el Java de
Oracle; y Microsoft, en su oferta, trae su propia distribución de OpenJDK con soporte (historia
§5.4). Qué distribución firma la cooperativa es una decisión de licencias y de soporte que este curso
no toma. Lo que sí le toca al curso es lo que vino después: *"Bueno. ¿Y cuánto pesa, cuánto tarda en
construirse, y cuánto en arrancar? Porque eso también es plata."*

Esta fase responde las tres preguntas para los cuatro runtimes, con el arnés de medición que el
resto del curso va a copiar. **El patrón es uno —construir en una etapa, correr en otra— y cada
runtime lo paga distinto.** Esa es la tesis, y la tabla de la sección 8 la sostiene.

---

## 🎯 2. Objetivos de esta fase

1. Reescribir el Dockerfile de `pricing` como multi-stage sobre una base sin shell, y explicar cada
   línea.
2. Llevar el patrón a `inventory`, `catalog`, `replenish` y `storefront`, contando solo lo que no es
   mecánico en cada uno.
3. Elegir cada imagen base con su porqué: musl o glibc, con shell o sin él, y qué se depura sin él.
4. Medir con `task measure -- B-04` el tamaño, el build en frío, el build con caché y el tiempo
   hasta el primer 200 de los cinco, con dispersión.
5. Reconocer cuándo un tag miente, y comprobar en treinta segundos qué imagen corre de verdad.

---

## 🚫 3. Qué NO entra todavía

- Imágenes para otra arquitectura y builds multiplataforma → [a06](a06-arquitecturas-y-multiplataforma.md).
- Construir sin Docker (Buildah, Kaniko, los constructores por lenguaje) → [a07](a07-imagenes-sin-docker.md).
- La JVM nativa y el AOT cache de Java → [a08](a08-la-jvm-nativa.md) y la [Fase 15](15-salud-y-recursos.md).
- Publicar en un registry, y el registry propio con su CA → [Fase 19](19-tls-y-certificados.md).
- Firmar imágenes, SBOM y la cadena de suministro: fuera del curso.

---

## 🧨 4. El problema, en el laboratorio

Los cinco Dockerfile de G0 construyen y corren en la misma imagen. Medidas con las mismas dos
herramientas que usa el arnés de la sección 8 —lo que ocupa descomprimida según `dive`, y lo que
pesa el archivo de `docker save`, que es lo que viaja—:

| Imagen de G0 (una etapa) | Descomprimida | Viaja | Corre como |
|---|---|---|---|
| `pricing` | 348,3 MB | 99 MB | `root` |
| `inventory` | 529,8 MB | 224 MB | `root` |
| `catalog` | 161,3 MB | 57 MB | `root` |
| `replenish` | 285,0 MB | 113 MB | `root` |
| `storefront` | 303,5 MB | 116 MB | `root` |

Seiscientos nueve megas que viajan, para cinco servicios que devuelven JSON fijo. Cada uno lleva su
compilador o su gestor de paquetes: `pricing`, el de Go; `inventory`, el JDK y el repositorio local
de Maven; `catalog`, Composer; `replenish`, TypeScript y el CLI de Nest; `storefront`, Node entero
para servir archivos estáticos. Y los cinco corren como `root`.

En compose no se nota: las imágenes se construyen en tu máquina y nunca viajan. **En la [Fase 08](08-el-primer-despliegue.md) sí
viajan**: cada imagen se carga en el nodo del cluster, y en la [Fase 16](16-escalado-y-rollout.md), con tres nodos, en cada uno.
Lo que hoy es espacio en disco mañana es tiempo de despliegue. Y el `root` es el `Permission denied`
de la [Fase 03](03-el-contenedor-por-dentro.md) esperando a que alguien lo arregle tarde.

---

## 🧩 5. El multi-stage, con `pricing`

### 5.1 Dos etapas: la que construye y la que corre

La idea entera cabe en una frase: **lo que se necesita para construir no es lo que se necesita para
correr**. Un Dockerfile multi-stage tiene varios `FROM`, cada uno empieza una imagen nueva y vacía, y
solo la última es la que se publica. Las anteriores existen para producir archivos que la última
copia con `COPY --from`. El de `pricing`, completo:

```dockerfile
# ── Etapa de build: el compilador de Go, que no viaja a la imagen final ──
# golang:1.27.1-alpine
FROM golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 AS build
WORKDIR /src
# Primero el módulo: si mañana hay dependencias, esta capa se reutiliza mientras go.mod no cambie.
COPY go.mod ./
RUN go mod download
COPY main.go ./
# Binario estático (sin cgo: no necesita la libc de ninguna base), sin rutas locales ni símbolos de depuración.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/pricing .

# ── Etapa final: solo el binario ──
# gcr.io/distroless/static-debian13:nonroot — sin shell ni gestor de paquetes; usuario 65532.
FROM gcr.io/distroless/static-debian13@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
COPY --from=build /out/pricing /pricing
EXPOSE 8080
CMD ["/pricing"]
```

**Detalles con intención.** Las dos bases van por digest, con el tag legible en el comentario, y las
dos salen de [a01](a01-el-laboratorio.md#-versiones-fijadas). `CGO_ENABLED=0` es la línea que
permite todo lo demás: sin ella, Go enlaza con la libc de la etapa de build y el binario no corre en
una base que no la tenga (5.4). `-ldflags="-s -w"` le quita al binario la tabla de símbolos, que
solo sirve para depurar con un depurador que nadie va a correr dentro del contenedor. Y la base
final es **distroless**: los archivos mínimos de una distribución Debian —certificados, zona horaria,
`/etc/passwd` con un usuario sin privilegios— y nada más.

```text
$ docker images lab/pricing
IMAGE                ID             DISK USAGE   CONTENT SIZE   EXTRA
lab/pricing:latest   f25bc8c6fe3c       15.3MB         3.43MB
```

De 507 MB a 15,3, sin cambiar una línea de Go. La suite G0 pasa igual, porque la suite no sabe ni
le importa cómo está empaquetado el servicio:

```text
$ task conformance -- G0
Success /suite/pricing.g0.hurl (6 request(s) in 2 ms)
…
Succeeded files:   5 (100.0%)
```

> 📝 **Dos tamaños, dos preguntas.** `CONTENT SIZE` es lo que viaja comprimido por la red o en un
> archivo de `docker save`; `DISK USAGE`, con el almacén de containerd de Docker Desktop, suma lo
> comprimido y lo descomprimido. La medición de la sección 8 usa dos números que no dependen del
> motor: lo que ocupa la imagen descomprimida, según `dive`, y lo que pesa el archivo de `save`, que
> es lo que la [Fase 08](08-el-primer-despliegue.md) va a cargar en el nodo del cluster.

### 5.2 La base sin shell, y cómo se depura sin ella

Distroless tiene un precio, y se paga la primera vez que algo falla:

```text
$ docker exec lab-pricing-1 sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

No hay `sh`, ni `ls`, ni `wget`, ni `id`. Tampoco hay nada que un atacante pueda usar una vez
adentro, y esa es la otra mitad del trato. La forma de depurar es **traer las herramientas en otro
contenedor que comparta los namespaces del que falla** (la [Fase 03](03-el-contenedor-por-dentro.md) los nombró): el mismo proceso a la
vista, la misma red.

```text
$ docker run --rm --pid=container:lab-pricing-1 --network=container:lab-pricing-1 lab/replenish \
    sh -c 'ps -o pid,user,args; wget -qO- localhost:8080/health/live'
PID   USER     COMMAND
    1 65532    /pricing
   17 node     sh -c ps -o pid,user,args; wget -qO- localhost:8080/health/live
   24 node     ps -o pid,user,args
{"status":"live"}
```

`pricing` aparece como el proceso 1, corriendo como el usuario 65532, y `localhost:8080` es su
puerto, porque la red es la misma. Es exactamente lo que hace `kubectl debug` con un contenedor
efímero en la [Fase 21](21-diagnostico.md): la herramienta cambia, el mecanismo no.

### 5.3 El orden de las instrucciones es la caché

Cada instrucción produce una capa, y el motor reutiliza una capa si la instrucción y todo lo que
copia son iguales a la vez anterior. **La primera instrucción que cambia invalida todas las que
siguen.** Por eso el Dockerfile copia primero lo que cambia poco (`go.mod`, `pom.xml`,
`package-lock.json`, `composer.lock`) y descarga las dependencias, y después copia el código.

La prueba con `replenish`. El Dockerfile del curso copia `package.json` y `package-lock.json`, corre
`npm ci`, y después copia el código. Una variante que copia todo primero (`COPY . .` antes de `npm
ci`) es más corta y "hace lo mismo". Después de cambiar una línea de
`src/replenishment-orders.controller.ts`, tres builds con caché de cada uno:

| Dockerfile de `replenish` | Build con caché, tres corridas |
|---|---|
| dependencias primero (el del curso) | 2,1 – 2,4 s (B-04) |
| `COPY . .` primero | 10,16 – 11,44 s |

Cuatro a cinco veces más, en cada cambio de código, porque cada cambio vuelve a instalar las
dependencias. En `pricing` el orden no salva nada, y la medición lo dice sin piedad: su build con
caché (5,6 s) cuesta casi lo mismo que el frío (5,8 s), porque `pricing` no tiene dependencias que
proteger y lo que tarda es el `go build` mismo, que empieza de cero cada vez. Eso se arregla con
otra herramienta, una caché de compilación montada en el build, y es el ejercicio 15.

**El `.dockerignore` es la otra mitad de la caché.** Lo que entra al contexto del build entra a la
comparación de `COPY . .`, y un archivo que no hace falta invalida la capa igual que uno que sí. Los
`.dockerignore` del curso excluyen el `Dockerfile` y el `CLAUDE.md` de cada servicio por eso: se
editan a menudo y no los necesita ninguna etapa. La prueba, otra vez con `replenish`, agregando una
línea al `CLAUDE.md` y construyendo:

| `.dockerignore` de `replenish` | Build después de tocar `CLAUDE.md` (tres corridas) |
|---|---|
| con `CLAUDE.md` excluido | 0,27 – 0,40 s: todo sale de la caché |
| sin esa línea | 2,07 – 2,24 s: se recompila TypeScript |

Y el `.dockerignore` de `catalog` excluye `.env`: el archivo de configuración local, con secretos, que
el portal de 2019 sí hornea en su imagen ([a16](a16-el-patrimonio.md)). Lo que no entra al contexto
no puede quedar en ninguna capa.

### 5.4 musl o glibc: la base no es un detalle

`pricing` corre sobre distroless porque su binario es estático: no necesita ninguna biblioteca del
sistema. Los otros runtimes sí, y ahí aparece la diferencia que más confunde: **Alpine usa musl como
biblioteca de C, y Debian y Ubuntu usan glibc**. Un binario compilado para una no corre en la otra,
y el error no lo dice. Copio el `java` de la imagen de Temurin (Ubuntu) a una imagen de Node (Alpine):

```text
$ docker run --rm lab-f04/java-en-alpine /opt/java/bin/java -version
/usr/local/bin/docker-entrypoint.sh: exec: line 11: /opt/java/bin/java: not found
$ docker run --rm lab-f04/java-en-alpine ls -l /opt/java/bin/java
-rwxr-xr-x    1 root     root         70784 Aug 18 20:24 /opt/java/bin/java
```

*"not found"* para un archivo que está ahí. Lo que no se encuentra es el cargador de glibc que el
binario pide, y `ldd` lo muestra en cada imagen:

```text
$ docker run --rm --entrypoint ldd lab/inventory /opt/java/openjdk/bin/java
	libc.so.6 => /usr/lib/aarch64-linux-gnu/libc.so.6 (0x0000ffff97c50000)
	/lib/ld-linux-aarch64.so.1 (0x0000ffff97e90000)
	…
$ docker run --rm lab/replenish ldd /usr/local/bin/node
	/lib/ld-musl-aarch64.so.1 (0xffff92fb0000)
	libc.musl-aarch64.so.1 => /lib/ld-musl-aarch64.so.1 (0xffff92fb0000)
	…
```

Es la versión concreta de la nota del toolchain de la [Fase 01](01-primer-contenedor-y-dockerfile.md): hoy ninguna imagen del laboratorio
compila nada nativo, y el día que una dependencia traiga un binario precompilado para glibc y la
base sea Alpine, el síntoma será este *"not found"*. Para el curso, la regla es elegir la base por lo
que el runtime necesita, y declararlo en el comentario del `FROM`.

> 🩻 **Esto sí funciona igual.** Docker y Podman construyen el mismo Dockerfile multi-stage sin
> cambiar una línea, y la imagen resultante corre en los dos ([Fase 03](03-el-contenedor-por-dentro.md)). El formato es OCI; el
> Dockerfile, también lo entiende Buildah, que es lo que usa Podman por debajo.

**El patrón a memorizar.** Construye en una etapa con todo lo que haga falta; corre en otra con lo
mínimo, como un usuario sin privilegios y con el proceso en forma JSON. Copia primero lo que cambia
poco. Y elige la base por la biblioteca de C que necesita lo que vas a correr.

---

## 🔁 6. Los otros tres: donde no es mecánico

El patrón se replica en los otros cuatro (los cinco Dockerfile completos están en
`src/lab/services/<svc>/Dockerfile`). Lo que no es mecánico, por runtime:

### 6.1 `inventory`: del JDK al JRE, y el jar por capas

Java se compila con el JDK y corre con el JRE, y las dos son imágenes distintas de Temurin. Lo que no
es mecánico es el jar: Spring Boot produce un solo archivo con la aplicación y sus dependencias
adentro, y un jar único es **una capa** que cambia en cada commit. Spring Boot sabe partirlo:

```dockerfile
RUN java -Djarmode=tools -jar target/inventory-0.0.1-SNAPSHOT.jar extract --layers --destination /out
…
# De lo que menos cambia a lo que más: las dependencias casi nunca, la aplicación en cada commit.
COPY --from=build /out/dependencies/ ./
COPY --from=build /out/spring-boot-loader/ ./
COPY --from=build /out/snapshot-dependencies/ ./
COPY --from=build /out/application/ ./
```

```text
$ docker history lab/inventory --format '{{.Size}}\t{{.CreatedBy}}' | head -8
0B	CMD ["java" "-jar" "inventory-0.0.1-SNAPSHOT…
0B	EXPOSE [8080/tcp]
0B	USER inventory
16.4kB	COPY /out/application/ ./ # buildkit
4.1kB	COPY /out/snapshot-dependencies/ ./ # buildk…
4.1kB	COPY /out/spring-boot-loader/ ./ # buildkit
19.8MB	COPY /out/dependencies/ ./ # buildkit
8.19kB	WORKDIR /app
```

Las dependencias son 19,8 MB; **lo que cambia en cada commit son 16 KB**. Cuando la [Fase 08](08-el-primer-despliegue.md) cargue la
imagen nueva en el nodo, o la [Fase 19](19-tls-y-certificados.md) la empuje al registry, solo viaja la capa que cambió. El resto
de la imagen es el JRE (190 MB descomprimido) y Ubuntu (160 MB), y no se va a ninguna parte: es el
piso de Java en esta base. Bajarlo es otra conversación ([a08](a08-la-jvm-nativa.md)).

El usuario es propio, con uid fijo, porque la imagen de Temurin no trae uno sin privilegios:

```dockerfile
RUN useradd --system --uid 10001 --no-create-home inventory
USER inventory
```

### 6.2 `catalog`: dos procesos que no caben en un contenedor

PHP-FPM no habla HTTP: habla FastCGI, y necesita un servidor web delante. Meter nginx y FPM en la
misma imagen exige un proceso 1 que arranque y vigile a los dos, que es exactamente lo que la [Fase 03](03-el-contenedor-por-dentro.md)
mostró que sale mal. El laboratorio los separa en **dos contenedores que comparten la red**:
`lab/catalog` es FPM con la aplicación, escuchando solo en `127.0.0.1:9000`, y delante va la imagen
oficial de nginx sin privilegios con un archivo de configuración del repositorio:

```nginx
server {
    listen 8080;
    # Un API sin archivos estáticos: cada petición la contesta Laravel.
    location / {
        # 127.0.0.1 porque FPM comparte la red con este contenedor.
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME /app/public/index.php;
        fastcgi_param SCRIPT_NAME /index.php;
    }
}
```

En compose, la red compartida es una clave:

```yaml
  catalog:
    build: ../services/catalog
    image: lab/catalog
  catalog-nginx:
    # nginxinc/nginx-unprivileged:1.30.5-alpine
    image: nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
    # Comparte la red de catalog, como dos contenedores de un pod.
    network_mode: service:catalog
    volumes:
      - ../services/catalog/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

`network_mode: service:catalog` mete a nginx en el namespace de red de FPM: `catalog:8080` es nginx,
y para nginx, FPM está en `127.0.0.1`. Guarda esa clave, porque es la definición de un pod, y la
[Fase 06](06-del-compose-al-cluster.md) la va a usar para explicarlo. Lo demás de `catalog` también cambió: el proceso 1 es el
maestro de FPM, como `www-data`, y la imagen base declara `STOPSIGNAL SIGQUIT`, así que `docker stop`
ahora sale en 0,09 segundos con código 0 y un `exiting, bye-bye!` en el log, donde la [Fase 03](03-el-contenedor-por-dentro.md) medía
diez segundos y un 137. Y una cifra para la [Fase 16](16-escalado-y-rollout.md): el pool de FPM de la imagen base arranca con
`pm.max_children = 5`. **Cinco peticiones a la vez por contenedor**, ni una más; es el modelo de un
proceso por petición, y es por qué el escalado de PHP se comporta distinto.

### 6.3 `replenish`: tres etapas, porque Node no compila a un binario

TypeScript se compila a JavaScript, pero el JavaScript necesita `node_modules` para correr, y las
dependencias de desarrollo (el compilador de Nest, TypeScript, los tipos) no hacen falta en
producción. Por eso son tres etapas: una que compila con todo, una que instala solo las dependencias
de producción (`npm ci --omit=dev`), y la final, que toma `dist/` de la primera y `node_modules` de
la segunda, y corre como `node`. Un detalle que no es obvio: `package.json` tiene que
viajar a la imagen final, porque declara `"type": "module"` y sin él Node no sabe cargar `dist/`.

Lo que **no** cambió: `replenish` sigue tardando diez segundos en detenerse y muriendo con 137,
porque el proceso 1 sigue siendo un Node que no atiende `SIGTERM`. Es deuda de la [Fase 16](16-escalado-y-rollout.md), y el
Dockerfile no la puede pagar.

### 6.4 `storefront`: el frontend que deja de ser un proceso de Node

El `storefront` de G0 se servía con `vite preview`, que es un servidor de desarrollo. El definitivo
compila con Node en una etapa y **sirve los archivos con nginx** en la final:

```dockerfile
# nginxinc/nginx-unprivileged:1.30.5-alpine
FROM nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
COPY --from=build /app/dist /usr/share/nginx/html
```

Node no viaja: la imagen final no tiene ni una línea de JavaScript que se ejecute en el servidor. La
salud son dos archivos (`public/health/live` y `public/health/ready`), y nginx sin privilegios
escucha en el 8080 como el usuario 101. Lo que queda horneado en `dist/` en el momento del build
—incluida la dirección del API— es el problema de la [Fase 11](11-configuracion-y-secretos.md).

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

El instinto, en su mejor versión: *"con `build:` en el compose, la imagen es un detalle: lo que
importa es que levante. Y si hay que optimizar, lo pesado es lo lento: la imagen que pesa veinte
veces más tarda veinte veces más en todo."* Lo primero era verdad mientras las imágenes no salían de
tu máquina. Lo segundo es la intuición que la medición tenía que poner a prueba, y esta es la apuesta
que escribí antes de correrla:

> 🪞 **Apuesta antes de ejecutar.** Con el multi-stage definitivo, la imagen de `pricing` queda por
> debajo de 20 MB y la de `inventory` por encima de 200 MB: más de diez veces. En build en frío,
> `inventory` tarda más de cinco veces lo que `pricing`. Con caché y un cambio solo en el código, los
> cuatro backends bajan a menos de un cuarto de su build en frío. Hasta el primer 200, `pricing`
> contesta en menos de medio segundo e `inventory` en más de dos: más de veinte veces.
>
> **Resultado: ganada en tamaño y en build en frío, perdida en caché y en arranque.** `inventory`
> pesa 45 veces lo que `pricing` descomprimida y tarda 15 veces más en frío. Con caché, solo
> `inventory` bajó de un cuarto (al 3 %); `replenish` quedó en el 31 %, `catalog` en el 49 % y
> `pricing` en el 97 %. Y `inventory` contestó su primer 200 en 1,16 segundos: siete veces lo de
> `pricing`, no veinte.

Lo que la apuesta perdida enseña: **el peso de la imagen no predice ni el build con caché ni el
arranque**. El build con caché depende de qué paso queda después del cambio (un `go build` entero,
un `composer dump-autoload`, o solo copiar 16 KB). Y el arranque de un servicio de G0, que no hace
nada, depende más del runtime que de los megas; la [Fase 15](15-salud-y-recursos.md) va a ver qué pasa con `inventory` cuando
arranque con algo que hacer.

---

## 📏 8. La medición: B-04

> 📏 **Medición B-04 · El costo de empaquetar cada runtime** · sin cluster, con las imágenes base ya
> descargadas · Docker Desktop 4.92.0 (Engine 29.8.0), máquina virtual de 4 GiB y 8 CPU · MacBook
> Pro M1 Pro, 32 GB, macOS arm64 · 5 corridas de cada build y 10 arranques · verificado el 03/10/2026
>
> | | descomprimida | viaja | build en frío | build con caché | primer 200 |
> |---|---|---|---|---|---|
> | `pricing` (Go) | 8,5 MB | 3,5 MB | 5,8 s (5,7–7,0) | 5,6 s (5,5–5,7) | 0,16 s (0,15–0,18) |
> | `inventory` (Java) | 383,9 MB | 136,2 MB | 88,8 s (87,8–95,4) | 2,7 s (2,6–3,9) | 1,16 s (1,14–1,26) |
> | `catalog` (PHP-FPM) | 125,2 MB | 43,6 MB | 7,5 s (7,4–8,6) | 3,7 s (3,6–4,2) | 0,43 s (0,41–0,54) |
> | `replenish` (Node) | 175,7 MB | 64,2 MB | 7,0 s (6,9–7,3) | 2,2 s (2,1–2,4) | 0,46 s (0,44–0,48) |
> | `storefront` (nginx) | 54,3 MB | 23,2 MB | 5,2 s (5,0–5,2) | 2,0 s (2,0–2,0) | 0,19 s (0,16–0,20) |
>
> Mediana, con mínimo y máximo. *Descomprimida*, según `dive`; *viaja*, el archivo de `docker save`.
> *Build con caché*: después de cambiar una línea de código. *Primer 200*: desde `docker run` hasta
> la primera respuesta 200 de la ruta de G0, sondeando desde el host. `catalog` mide FPM y su nginx.
> Reproducir: `task measure -- B-04`

**Lo que la tabla dice, en proporciones.** `inventory` pesa 45 veces lo que `pricing` y lo que viaja
pesa 39 veces; ninguno de los otros tres pasa de 21. En build en frío, `inventory` tarda 15 veces lo
que `pricing`, y los otros tres apenas un 20–30 % más que el piloto: el build en frío de Java es,
casi todo, Maven bajando dependencias. Con un cambio de código, en cambio, `inventory` es el más
rápido de los cuatro backends en proporción a su frío (3 %), gracias al jar por capas; `pricing`, el
más lento (97 %). Y en el arranque, el piso de todos es lo que tarda el motor en crear el contenedor:
`pricing` y `storefront` están ahí, y `inventory`, con un G0 que no hace nada, ya cuesta siete veces
más.

Y contra el punto de partida de G0: lo que viaja bajó de 609 MB a 270,7 MB para los cinco, y en
proporciones distintas por runtime. `pricing` quedó en un 3,5 % de lo que era; `storefront`, en un
20 %; `inventory`, en un 61 %, porque Java en esta base tiene un piso, el JRE y Ubuntu, que ningún
multi-stage quita.

**Cómo se midió mal la primera vez.** La primera corrida completa de B-04 dio builds con caché de
0,4 segundos para los cinco, y casi me la creo. El arnés agregaba siempre el mismo comentario al
código antes de construir; desde la segunda corrida, el motor ya tenía esa capa exacta y la medición
era de la caché, no del build. Lo delataba la dispersión: el mínimo de `inventory` era 0,3 y el
máximo 2,8, que era la única corrida verdadera. El arnés de hoy escribe un comentario distinto cada
vez, y las cinco corridas de cada servicio cuentan. **Una medición con un máximo diez veces la
mediana no es una medición: es una pista.**

---

## ⚰️ 9. Autopsia: *"pero si yo desplegué el arreglo"*

**La decisión, con su mejor argumento.** Sale la circular de precios, el equipo de `pricing` cambia
el precio, construye la imagen con el mismo tag de siempre y reinicia el contenedor. *"El tag es el
mismo, la imagen la acabo de construir, y reiniciar es lo que siempre se hace para que un servicio
tome los cambios."* En un servidor de aplicaciones, desplegar y reiniciar es exactamente eso.

**Por qué era razonable.** En un servidor, reiniciar vuelve a leer el archivo desplegado. Y un tag
que se reescribe (`latest`, o el nombre del servicio sin tag) es lo que usa compose por defecto: en
este curso, `image: lab/pricing`.

**Qué pasa después, con número.** Lo reproduje con una copia de `pricing` cuyo precio fijo pasa de
12.900 a 13.500:

```text
$ curl -s 'http://127.0.0.1:18406/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
$ docker build -q -t lab-f04/pricing:circular .          # con el precio nuevo
sha256:562384ce29032fd791e6bef18be6e6faf7d0228de5d4a6f7c67ae6e5015e5019
$ docker restart pricing-circular
$ curl -s 'http://127.0.0.1:18406/prices/SKU-0003?store=DRO-007'
{"currency":"COP","price":12900,"sku":"SKU-0003","store":"DRO-007"}
```

El precio viejo, después de "desplegar el arreglo". **`restart` reinicia el mismo contenedor, y un
contenedor está atado a la imagen con la que se creó**, no al tag. El tag se movió; el contenedor,
no. La comprobación de treinta segundos es comparar los dos identificadores:

```text
$ docker inspect pricing-circular --format '{{.Image}}'
sha256:e7db1c8409cd284b3a7bc055c9c917493403db7c507c7cb16de92b11f31ddb1c
$ docker image inspect lab-f04/pricing:circular --format '{{.Id}}'
sha256:562384ce29032fd791e6bef18be6e6faf7d0228de5d4a6f7c67ae6e5015e5019
$ docker ps --filter name=pricing-circular --format '{{.Names}}  {{.Image}}  {{.Status}}'
pricing-circular  e7db1c8409cd  Up 1 second
```

Docker incluso lo dice a su manera: la columna `IMAGE` ya no muestra el tag sino un identificador
corto, porque el tag apunta a otra cosa. Es fácil no verlo.

**Cuánto cuesta salir, con número.** Recrear en vez de reiniciar: `docker rm -f` y `docker run`, o
`docker compose up -d`, que compara la imagen y recrea el contenedor si cambió. El precio pasó a
`13500` y el identificador del contenedor, a `562384ce…`. Un comando distinto.

**Qué lo habría cambiado.** Una pregunta antes de decir "ya está desplegado": *¿qué imagen corre
este contenedor, por digest?* Y la decisión de fondo que el curso ya tomó para las bases: **nombrar
las imágenes por su contenido, no por un nombre que se puede mover**. Las bases van por digest desde
la [Fase 01](01-primer-contenedor-y-dockerfile.md); las imágenes propias van a ir igual en los manifiestos de la [Fase 08](08-el-primer-despliegue.md), por la misma
razón. En el cluster, el mismo reflejo —confiar en el nombre y no en lo que hay detrás— tiene su incidente: el
[05 del cuaderno](cuaderno-incidentes.md#-incidente-05--el-pod-espera-una-imagen-que-el-cluster-nunca-vio), un tag
nuevo que el nodo nunca recibió.

**Antes y después, con números:** después de construir el precio nuevo, `restart` siguió contestando
12.900 con la imagen `e7db1c84…`; recrear el contenedor contestó 13.500 con la `562384ce…`.

---

## 📖 10. Traducción

El Dockerfile no tiene equivalente en Kubernetes, y conviene saberlo desde ahora: **el cluster no
construye**. Recibe imágenes hechas, por nombre y, en este curso, por digest.

| En compose | En Kubernetes | Lo que cambia |
|---|---|---|
| `build:` | *sin equivalente* | la imagen se construye antes y se carga al nodo ([Fase 08](08-el-primer-despliegue.md)) o se publica en un registry ([Fase 19](19-tls-y-certificados.md)) |
| `image: lab/pricing` (tag implícito `latest`) | `image:` con digest | un tag puede cambiar de contenido; un digest no |
| `network_mode: service:catalog` | dos contenedores en un pod | en compose es una excepción; en Kubernetes, la unidad ([Fase 09](09-los-cuatro-servicios-dentro.md)) |

🌩️ En la nube, las imágenes viven en el registry del proveedor (el de OCI, el de Azure), y cada nodo
descarga lo que viaja: el número de la columna "viaja" de B-04, por nodo y por versión. El
[diccionario completo](a05-diccionarios.md#-compose--kubernetes) está en `a05`.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

El multi-stage tiene costos, y conviene ponerlos sobre la mesa. **Una base sin shell** obliga a
depurar desde otro contenedor, y la primera vez que algo falla un domingo eso es una barrera. **Tres
etapas para Node** son tres sitios donde equivocarse (el `package.json` que tiene que viajar). Y **el piso de
Java no se negocia con Dockerfile**: 383,9 MB y 88,8 segundos de build en frío, contra 8,5 MB y 5,8
segundos de Go, con el mismo patrón y el mismo cuidado.

Si la imagen nunca sale de tu máquina —un ambiente de desarrollo en compose, una herramienta que
corres tú—, la imagen de una etapa de G0 alcanza y es más fácil de leer. El multi-stage paga cuando
la imagen **viaja**: a un nodo, a un registry, a otra máquina. En este curso viaja desde la [Fase 08](08-el-primer-despliegue.md),
y por eso esta fase va aquí.

**La pregunta del curso, para esta fase:** el contenedor te dio un formato que empaqueta cualquier
runtime con el mismo patrón, y una caché que premia el orden. El orquestador, todavía nada. **Te tocó
a ti** elegir cada base, el usuario, el orden de las instrucciones, qué no entra al contexto, y saber
qué imagen corre de verdad.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`exec … not found` con un archivo que existe.** Síntoma: `/opt/java/bin/java: not found`, y `ls`
lo muestra. Causa: el binario pide una biblioteca de C (glibc) que la base no tiene (musl), o al
revés. Comprobación 🩺: `ldd <binario>` en la imagen donde se construyó. Salida: la base correcta, o
un binario estático.

**`exec: "sh": executable file not found`.** Síntoma: no puedes entrar a `pricing`. Causa: distroless
no tiene shell, a propósito. Salida: un contenedor de depuración con `--pid=container:…` y
`--network=container:…` (5.2).

**nginx de `catalog` contesta 502.** Síntoma:

```text
$ curl -s -i http://127.0.0.1:18405/products | head -1
HTTP/1.1 502 Bad Gateway
$ docker logs f04-nginx 2>&1 | grep error | tail -1
2026/10/03 22:22:28 [error] 21#21: *1 connect() failed (111: Connection refused) while connecting to upstream, client: 172.17.0.1, server: , request: "GET /products HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "127.0.0.1:18405"
```

Causa: nginx y FPM no comparten la red, y `127.0.0.1:9000` es el propio nginx. Comprobación 🩺:
`docker inspect <nginx> --format '{{.HostConfig.NetworkMode}}'`. Salida: `network_mode:
service:catalog` en compose; un solo pod en la [Fase 09](09-los-cuatro-servicios-dentro.md).

**El build vuelve a bajar todas las dependencias por un cambio de código.** Síntoma: el build con
caché tarda casi lo mismo que el frío. Causa: el código se copia antes que el manifiesto de
dependencias, o un archivo que no hace falta (`CLAUDE.md`) entra al contexto. Comprobación 🩺:
`docker build --progress=plain` y buscar el primer paso que no dice `CACHED`. Salida: reordenar, y
`.dockerignore`.

---

## 📋 14. Checklist de validación

```text
[ ] los cinco Dockerfile son multi-stage, con las bases por digest y un usuario sin privilegios
[ ] task compose:up levanta seis contenedores (catalog son dos) y task conformance -- G0 pasa
[ ] docker exec lab-pricing-1 sh falla, y sabes depurar pricing desde otro contenedor
[ ] el java de Temurin no corre en Alpine, y ldd te dice por qué
[ ] el orden de las instrucciones y el .dockerignore, comprobados con un cambio de código y uno de CLAUDE.md
[ ] task measure -- B-04 corre y deja sus crudos en bench/b04/results/
[ ] reiniciar un contenedor no toma la imagen nueva; recrearlo, sí; y sabes comprobarlo por su ID
```

---

## 🧪 15. Ejercicios (24)

Un tercio son de medición o de diagnóstico, y la mitad usa un servicio que no es `pricing`. Antes de
cada 🟠 y 🔴, escribe la predicción.

## 🟢 Fácil — construir y leer (1–7)

### 🟢 Ejercicio 1 — Los cinco, de nuevo
Construye las cinco imágenes y corre la suite G0 contra ellas.

**Criterio:** `task compose:up` y `task conformance -- G0` terminan con `Succeeded files: 5 (100.0%)`.

<details><summary>Solución</summary>

`task compose:down`, `task compose:up` (que corre `task build:all` primero) y `task conformance -- G0`.
</details>

### 🟢 Ejercicio 2 — Las etapas de `replenish`
Cuenta las etapas del Dockerfile de `replenish` y di qué copia la final de cada una.

**Criterio:** tres etapas, y la final copia `node_modules` de `deps` y `dist/` de `build`.

<details><summary>Solución</summary>

`grep -n "^FROM\|COPY --from" services/replenish/Dockerfile`.
</details>

### 🟢 Ejercicio 3 — ¿Quién corre?
Muestra con qué usuario corre cada una de las cinco imágenes.

**Criterio:** `inventory` (10001), `catalog` (`www-data`), `replenish` (`node`), `storefront`
(`nginx`) y `pricing` (65532), cada uno con su comando.

<details><summary>Solución</summary>

`docker run --rm --entrypoint id lab/<svc>` para las cuatro que tienen `id`; para `pricing`, que no
tiene, `docker image inspect lab/pricing --format '{{.Config.User}}'`.
</details>

### 🟢 Ejercicio 4 — `dive` sobre `inventory`
Abre `lab/inventory` con `dive` y encuentra la capa de la aplicación.

**Criterio:** la capa de `COPY /out/application/` y su tamaño, en KB.

<details><summary>Solución</summary>

`dive lab/inventory`, y bajar por la lista de capas hasta la última `COPY`.
</details>

### 🟢 Ejercicio 5 — Sin shell
Intenta entrar a `pricing` con `sh`, y después mira su proceso desde un contenedor que comparta sus
namespaces.

**Criterio:** el error `executable file not found` y, en el segundo, `/pricing` como proceso 1.

<details><summary>Solución</summary>

`docker exec lab-pricing-1 sh`, y el `docker run --pid=container:… --network=container:…` de 5.2.
</details>

### 🟢 Ejercicio 6 — `catalog` son dos
Muestra los dos contenedores de `catalog` y comprueba que comparten la red.

**Criterio:** `docker compose -f compose/compose.yaml ps` lista `catalog` y `catalog-nginx`, y
`docker inspect lab-catalog-nginx-1 --format '{{.HostConfig.NetworkMode}}'` apunta al de `catalog`.

<details><summary>Solución</summary>

Los dos comandos del criterio; el segundo devuelve `container:<id>` con el identificador del de FPM.
</details>

### 🟢 Ejercicio 7 — Una corrida del arnés
Corre B-04 para un solo servicio, con una corrida de cada cosa.

**Criterio:** `task measure -- B-04 --service storefront --runs 1 --startup-runs 1` imprime su fila, y
el crudo queda en `bench/b04/results/`.

<details><summary>Solución</summary>

El comando del criterio. Borra el crudo si no lo vas a publicar.
</details>

## 🟡 Intermedio — el patrón en otro sitio (8–14)

### 🟡 Ejercicio 8 — El orden, en `inventory`
Mueve `COPY src src` antes de `RUN ./mvnw … dependency:go-offline` en una copia del Dockerfile, y
mide el build con caché después de cambiar una línea de `StockController.java`.

**Criterio:** los dos tiempos, con el orden del curso y con el tuyo, tres veces cada uno.

<details><summary>Solución</summary>

Con el código antes, cada cambio vuelve a bajar todas las dependencias de Maven: el tiempo con caché
se acerca al de frío. Mide con `time docker build -t lab-ej/inventory -f <tu Dockerfile> services/inventory`.
</details>

### 🟡 Ejercicio 9 — El `.dockerignore` de `catalog`
Explica cada línea del `.dockerignore` de `catalog` y qué pasaría sin la de `.env`.

**Criterio:** una frase por línea, y la de `.env` relacionada con el portal de [a16](a16-el-patrimonio.md).

<details><summary>Solución</summary>

`vendor` lo genera Composer dentro del build; `Dockerfile` y `CLAUDE.md` no hacen falta y, si
entraran, cada cambio en ellos invalidaría la caché; `.env` es configuración local con secretos, que
el portal de 2019 hornea en su imagen (es la maña que cobra la [Fase 11](11-configuracion-y-secretos.md)).
</details>

### 🟡 Ejercicio 10 — nginx sin la red compartida
Levanta FPM y nginx de `catalog` en dos contenedores **sin** compartir la red, y pide `/products`.

**Criterio:** el 502 y la línea `connect() failed` del log de nginx.

<details><summary>Solución</summary>

Los dos `docker run` de la sección 13, sin `--network container:…`. nginx busca FPM en su propio
`127.0.0.1`, y ahí no hay nadie.
</details>

### 🟡 Ejercicio 11 — El jar en una sola capa
Construye una variante de `inventory` que copie el jar entero en vez de las cuatro carpetas, y
compara la capa que cambia al tocar una línea de código.

**Criterio:** el tamaño de la capa que cambia en las dos variantes (con `docker history`).

<details><summary>Solución</summary>

Con el jar entero, la capa que cambia pesa lo que las dependencias más la aplicación (unos 20 MB);
con las capas de Spring Boot, unos KB.
</details>

### 🟡 Ejercicio 12 — `storefront` sin Node
Demuestra que la imagen final de `storefront` no tiene Node.

**Criterio:** `docker run --rm --entrypoint sh lab/storefront -c 'which node || echo no hay node'`
dice `no hay node`, y `ls /usr/share/nginx/html` muestra `index.html` y `assets/`.

<details><summary>Solución</summary>

Los comandos del criterio.
</details>

### 🟡 Ejercicio 13 — El `stop` de las imágenes nuevas
Vuelve a medir la tabla de `stop` de la [Fase 03](03-el-contenedor-por-dentro.md) con las imágenes nuevas.

**Criterio:** la tabla de los cinco, con `catalog` y `storefront` por debajo de un segundo y código 0,
y `replenish` todavía en 137.

<details><summary>Solución</summary>

`time docker stop -t 10 lab-<svc>-1` y `docker inspect … --format '{{.State.ExitCode}}'`. `catalog`
y `storefront` salen con `SIGQUIT` (el `STOPSIGNAL` de sus bases) y cierran con cortesía.
</details>

### 🟡 Ejercicio 14 — Un tag que miente
Reproduce la autopsia de la sección 9 con `replenish`: dos builds con el mismo tag, `restart` en
medio, y la comparación de los dos identificadores.

**Criterio:** `docker inspect <contenedor> --format '{{.Image}}'` y `docker image inspect <tag>
--format '{{.Id}}'` dan distinto después del `restart`, e igual después de recrear.

<details><summary>Solución</summary>

Cambia el `G0` fijo de una orden en una copia del servicio, y sigue los pasos de la sección 9.
</details>

## 🟠 Difícil — medir, comparar, decidir (15–20)

### 🟠 Ejercicio 15 — La caché de Go que no se reutiliza
Agrega al `go build` de `pricing` una caché de compilación con `RUN --mount=type=cache,target=/root/.cache/go-build`
y mide el build con caché. **Predice** cuánto baja.

**Criterio:** tu predicción, y cinco corridas del build con caché antes y después.

**Rúbrica:** las mediciones con mediana; y por qué esa caché **no** se borra con `--no-cache`, lo que
obliga a medir el build en frío de otra manera (y a no mezclar los dos números en B-04).

### 🟠 Ejercicio 16 — `replenish` sobre glibc
Cambia la base de las tres etapas de `replenish` por una de Debian (`node:24-slim`, fijada por
digest) y mide tamaño y primer 200 con el arnés. **Predice** la diferencia.

**Criterio:** la predicción, y las dos filas de B-04 para `replenish`.

**Rúbrica:** la fila nueva; la proporción contra la de Alpine; y qué ganarías con glibc que no se ve
en esta tabla (compatibilidad con binarios precompilados, 5.4).

### 🟠 Ejercicio 17 — El piso de Java
Construye `inventory` sobre el JDK en la etapa final (en vez del JRE) y compara tamaños.
**Predice** la diferencia en MB.

**Criterio:** los dos tamaños (descomprimido y lo que viaja), con la predicción escrita antes.

**Rúbrica:** las cifras; la proporción; y qué pierdes al quitar el JDK (herramientas como `jcmd` para
diagnosticar la JVM viva, que la [Fase 15](15-salud-y-recursos.md) va a echar de menos).

### 🟠 Ejercicio 18 — ¿Dónde se va el build en frío?
Separa el build en frío de `inventory` por etapa con `docker build --no-cache --progress=plain`.

**Criterio:** la duración de cada paso, y cuál es la mayor.

**Rúbrica:** los tiempos por paso; la conclusión (descargar dependencias de Maven o compilar); y qué
decisión del Dockerfile protege ese paso de repetirse.

### 🟠 Ejercicio 19 — Un servicio sin multi-stage, medido
Mide con el arnés la imagen de G0 de `catalog` (el Dockerfile de una etapa, en la historia de git o
reescrito) y compárala con la definitiva.

**Criterio:** dos filas de B-04 para `catalog`.

**Rúbrica:** las dos filas; y una frase honesta sobre qué cambió más, el tamaño o el arranque, y por
qué.

### 🟠 Ejercicio 20 — El digest de una base
Encuentra el digest actual del tag `golang:1.27.1-alpine` en Docker Hub y compáralo con el del
Dockerfile.

**Criterio:** `docker buildx imagetools inspect golang:1.27.1-alpine` y el digest del `FROM`, iguales
o distintos.

**Rúbrica:** el resultado; si son distintos, qué cambió (la base se reconstruyó con parches); y por
qué el curso prefiere enterarse de eso al actualizar [a01](a01-el-laboratorio.md) y no en un build
cualquiera.

## 🔴 Muy difícil — el empaquetado roto (21–24)

### 🔴 Ejercicio 21 — Un binario que no corre
Construye `pricing` con `CGO_ENABLED=1` (instala `gcc` y `musl-dev` en la etapa de build) y córrelo
sobre distroless. **Predice** el error.

**Criterio:** la predicción, el error literal, y el `ldd` del binario en la etapa de build.

**Rúbrica:** el síntoma (*not found* o equivalente) frente a la causa (el cargador de musl que no
está); y las dos salidas posibles: volver a `CGO_ENABLED=0` o cambiar de base.

### 🔴 Ejercicio 22 — PHP y nginx en una imagen
Construye una variante de `catalog` con nginx y FPM en la misma imagen, arrancados por un script, y
mata FPM desde adentro.

**Criterio:** con FPM muerto, el contenedor sigue `Up` y `/products` responde 502.

**Rúbrica:** el Dockerfile y el script; la evidencia; y por qué esto es la razón de D34: con dos
contenedores, la muerte de FPM es la muerte de un contenedor, y el motor la ve.

### 🔴 Ejercicio 23 — La tabla en tu máquina
Corre B-04 completa en tu máquina y agrégala a `BENCHMARKS.md` como entrada tuya, debajo de la del
autor.

**Criterio:** la entrada con los seis datos (hipótesis, qué, motor, máquina, dispersión, cómo
reproducir).

**Rúbrica:** la entrada; las proporciones comparadas con las publicadas; y si alguna proporción se
invierte, una hipótesis de por qué.

### 🔴 Ejercicio 24 — ¿Cuánto cuesta un commit?
Calcula cuántos bytes viajan a un nodo por un cambio de una línea en cada servicio.

**Criterio:** por servicio, el tamaño de las capas que cambian después de tocar una línea del
código.

**Rúbrica:** el método (`docker history` antes y después, o `dive`); la tabla de cinco filas; y la
conclusión sobre qué servicio paga más por commit y qué decisión de su Dockerfile lo explica.

---

## 📚 16. Referencias

**Documentación oficial** (sin versión fija salvo donde se indica)

- Docker, *Multi-stage builds*: https://docs.docker.com/build/building/multi-stage/
- Docker, *Optimize cache usage in builds*: https://docs.docker.com/build/cache/optimize/ — el orden
  de las instrucciones y las cachés de montaje del ejercicio 15.
- Docker, *Build context* y `.dockerignore`: https://docs.docker.com/build/concepts/context/
- Distroless: https://github.com/GoogleContainerTools/distroless — qué trae cada variante y por qué
  `nonroot`.
- Spring Boot, *Efficient container images* (jar por capas y `jarmode=tools`):
  https://docs.spring.io/spring-boot/reference/packaging/container-images/efficient-images.html
- La imagen oficial de PHP, la sección de FPM y su configuración: https://hub.docker.com/_/php
- nginx sin privilegios: https://github.com/nginx/docker-nginx-unprivileged
- Eclipse Temurin: https://adoptium.net/temurin/ — la distribución de OpenJDK de la imagen de
  `inventory`.

**Libros**

- Brendan Burns, Joe Beda, Kelsey Hightower y Lachlan Evenson, *Kubernetes: Up and Running*, 3.ª
  edición (2022), el capítulo de imágenes de contenedor: capas, multi-stage y por qué el tamaño
  importa en un cluster.

**Orden de lectura sugerido:** antes, la página de multi-stage (cinco minutos); durante, la de caché,
con el Dockerfile de `inventory` delante; después, la de Spring Boot sobre imágenes eficientes, que
es la mejor explicación del jar por capas.

> ⚠️ Las URL y los contenidos cambian, y las de Docker no fijan versión.

---

## 🏁 17. Resultado de la fase

```text
LAS IMÁGENES AL CERRAR LA FASE 04 (compose, red lab_default)

  servicio     base final                     corre como   viaja      proceso 1
  pricing      distroless static (sin shell)  65532          3,5 MB   /pricing
  inventory    Temurin 25 JRE (Ubuntu)        inventory    136,2 MB   java -jar
  catalog      PHP 8.5 FPM (Alpine)           www-data      43,6 MB   php-fpm   + catalog-nginx (nginx 1.30)
  replenish    Node 24 (Alpine)               node          64,2 MB   node      💸 F16
  storefront   nginx 1.30 (Alpine)            nginx         23,2 MB   nginx

  task conformance -- G0  →  5 archivos, 0 fallidos · task measure -- B-04  →  BENCHMARKS.md
```

> **La señal de que quedó bien:** *"Sé cuánto pesa, cuánto tarda y con qué usuario corre cada
> imagen, y puedo decir qué imagen corre un contenedor sin creerle al tag."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite G0 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-04-empaquetar-los-cuatro-runtimes -m "F04 cerrada: cinco Dockerfile multi-stage con bases por digest y usuario sin privilegios; catalog en dos contenedores (FPM y nginx); task build:all; task measure -- B-04 con sus crudos; suite G0 pasando"
> ```
>
> Commits de la fase con prefijo `f04:`, los de ejercicio `f04 ej17: …` ([convención de git](00-convencion-de-git-y-tags.md)).

---

## 📌 Pendientes sugeridos

- **F09, G1 de `pricing`:** el SQLite tiene que ser un driver en Go puro; con cgo, el binario deja de
  ser estático y no corre en distroless (5.4). Anotado en el `CLAUDE.md` del servicio.
- **F08 y F09:** la imagen de nginx de `catalog` también hay que cargarla en el nodo, y los
  manifiestos tienen que nombrar las imágenes propias por digest (sección 9).
- **F15:** nginx arranca un *worker* por CPU visible (ocho en esta máquina virtual): con límites de
  CPU, conviene fijarlo. Y `pm.max_children = 5` de FPM es parte de la conversación del HPA (F16).
