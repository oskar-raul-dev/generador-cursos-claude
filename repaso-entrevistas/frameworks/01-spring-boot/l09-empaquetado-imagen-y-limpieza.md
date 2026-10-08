# L09 — Empaquetado, imagen y limpieza verificada

> **Objetivo:** que `inv-api` deje de ser un `java -jar` que corre en tu terminal y pase a ser
> una imagen que arranca dentro del mismo Compose que todo lo demás, configurada solo con
> variables de entorno; y que al terminar puedas demostrar —con un contador que devuelve `0`,
> no con una sensación— que tu máquina quedó exactamente como estaba antes de `L01`.
> **Asume:** [`01` §6](01-spring-boot-y-el-ecosistema.md#6--el-jar-ejecutable-y-el-plugin-de-maven)
> y [`23`](23-actuator-y-observabilidad.md) leídos, y [`07`](07-configuracion-externalizada.md)
> fresco. Este lab no repite su teoría: la ejecuta. Si no puedes decir de memoria por qué
> `Main-Class` no es tu clase, vuelve a `01` antes de la sección 2: hoy vas a abrir ese jar.
> **Prerrequisitos:** [`L08`](l08-security-y-batch.md) hecho. `inv-api` valida JWT de Keycloak,
> escribe una línea `WARN` por cada 401 y cada 403, tiene Actuator cerrado con
> `EndpointRequest.toAnyEndpoint()`, el job `inventory-reconciliation-job` con sus tablas
> `batch_*`, y los cinco perfiles de Compose (`db`, `ext`, `cache`, `obs`, `sec`) arriba.
> **Costo:** **$0.00**. Seis contenedores en `localhost`, y al final del lab ninguno.
> **Duración:** entre 170 y 210 minutos. Las secciones 5 y 7 son el corazón del lab; la 8 es
> el criterio de terminado y no se salta.
> **Qué toca:** el `pom.xml`, `application.yml`, un `Dockerfile` nuevo, el `.dockerignore`,
> `observability/prometheus.yml` y una clase nueva bajo `com.invlab.invapi.security`. El
> `docker-compose.yml` de [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie)
> **no se amplía**: el servicio `inv-api` está declarado ahí desde `L01`, y hoy solo se levanta su
> perfil y se cambian dos valores en experimentos que se revierten.
> **Qué deja levantado:** **nada**. Este lab termina con la máquina limpia y lo demuestra.
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Java 21 · Temurin 21.0.12_8 y Paketo `builder-noble-java-tiny` 0.0.190 (tags verificados ese
> día contra el registro de imágenes) · Docker Compose v2.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[Las capas del jar](#2--dentro-del-jar-las-capas-y-el-jarmode-de-herramientas) ·
[El `Dockerfile` multi-stage](#3--el-dockerfile-multi-stage-y-la-capa-que-se-reconstruye-entera) ·
[Buildpacks](#4--buildpacks-frente-al-dockerfile-escrito-a-mano) ·
[`inv-api` dentro de Compose](#5-️-inv-api-dentro-de-compose-cuatro-localhost-que-dejan-de-existir) ·
[Un artefacto, dos entornos](#6--el-mismo-artefacto-en-dos-entornos-variables-de-entorno-y-el-perfil-prod) ·
[Graceful shutdown](#7--graceful-shutdown-con-una-petición-en-vuelo) ·
[La limpieza verificada](#8--la-limpieza-verificada) ·
[Checklist](#9--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

Ocho labs después, `inv-api` hace todo lo que un servicio de banca tiene que hacer. Y sigue
arrancando igual que el primer día: un `java -jar` lanzado a mano desde tu terminal, contra un
`application.yml` donde la palabra `localhost` aparece cuatro veces, con la salida en un
`app.log` que solo existe en tu directorio.

Eso funciona mientras el que arranca el proceso eres tú. En el momento en que el que arranca el
proceso es un orquestador, tres cosas que hoy no te duelen empiezan a doler:

```text
tú arrancas               → el orquestador arranca
  java -jar target/…        una imagen con un tag, que alguien más construyó
  localhost:5432            un nombre de servicio en otra red
  Ctrl-C                    un SIGTERM, y treinta segundos para morir bien
  editas application.yml    no puedes: el fichero está dentro de la imagen
```

El cambio de músculo de hoy es el último de la serie, y es el que convierte todo lo anterior en
algo desplegable:

```text
L04  →  ¿grabó?               → lo dices con un SELECT
L05  →  ¿salió a la red?      → lo dices con el journal de WireMock
L06  →  ¿ejecutó el método?   → lo dices con un contador en memoria
L07  →  ¿cómo se comporta?    → lo dices con una serie de tiempo y una traza
L08  →  ¿por qué rechazó?     → lo dices con el log que escribiste tú
L09  →  ¿qué se llevó puesto? → lo dices con un contador que devuelve 0
```

Primero confirma que vienes del estado correcto. `get_token` es la función de shell que
definiste en [`L08` §2](l08-security-y-batch.md#2--keycloak-en-compose-el-realm-el-token-y-cómo-se-baja);
si abriste una terminal nueva, vuelve ahí a redefinirla.

```bash
docker compose -p inv-lab ps --format '{{.Name}}\t{{.State}}'
cd inv-api
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar > app.log 2>&1 &
sleep 15
ANALYST=$(get_token analyst@invlab.example analyst)
curl -s -o /dev/null -w 'health      -> %{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w 'valuation   -> %{http_code}\n' -H "Authorization: Bearer $ANALYST" \
  localhost:8080/api/items/ABC-000123/valuation
curl -s -o /dev/null -w 'sin token   -> %{http_code}\n' localhost:8080/api/items/ABC-000123/valuation
curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'
```

```text
health      -> 200
valuation   -> 200
sin token   -> 401
1
```

- **`docker compose -p inv-lab ps` tiene que listar seis contenedores**: `inv-lab-postgres-1`,
  `inv-lab-wiremock-1`, `inv-lab-redis-1`, `inv-lab-prometheus-1`, `inv-lab-grafana-1` e
  `inv-lab-keycloak-1`. Si falta alguno,
  `docker compose -p inv-lab --profile db --profile ext --profile cache --profile obs --profile sec up -d`
  los devuelve. Si falta el item `ABC-000123`, hiciste `down -v` entre sesiones y toca recrearlo
  con el `POST /api/items` de [`L03`](l03-api-rest-filtros-y-errores.md).
- **`--format '{{.Name}}\t{{.State}}'`** recorta la tabla de `ps` a lo único que importa aquí y
  hace la comprobación legible de un vistazo. La tabla completa es más ancha que la terminal.
- **`up{job="inv-api"}` valiendo `1`** confirma que Prometheus todavía alcanza tu JVM por
  `host.docker.internal:8081`. Anótalo: **esa línea es la primera que vas a romper hoy**, y en la
  sección 5 vas a arreglarla apuntando a un nombre de servicio en vez de al gateway de Docker.
- **`./mvnw -q clean package` sin `-DskipTests`**, como siempre. Hoy el `pom.xml` cambia y el
  artefacto que sale de ahí es la entrada de todo lo demás: si el build no está verde, la imagen
  que construyas empaqueta código que no pasa sus propias pruebas.

**Lo que vas a hacer hoy, en orden, y el porqué del orden.** Primero abrir el jar y mirar sus
capas (sección 2), porque sin entender el `layers.idx` el `Dockerfile` de la sección 3 es copiar
y pegar. Después las dos formas de construir la imagen —a mano y con buildpacks— y la comparación
entre ellas (secciones 3 y 4). Con la imagen en la mano, el cambio real del lab: meter `inv-api`
**dentro** de Compose y pagar el precio de haber escrito `localhost` en la configuración
(sección 5), lo que a su vez obliga a configurar por variables de entorno y cierra el bucle que
[`L02`](l02-configuracion-y-profiles.md) dejó abierto (sección 6). Después el apagado: un
`SIGTERM` con una petición en vuelo (sección 7). Y al final la limpieza, que en este lab **no es
el epílogo sino el criterio de terminado** (sección 8).

> **📝 Lo que este lab deja fuera a propósito, y dónde se practica en su lugar.**
> **Kubernetes** no aparece: el `readinessState` y el `livenessState` que
> [`L07` §3](l07-actuator-metricas-y-trazas.md#3--health-groups-y-un-indicator-que-se-pone-rojo-a-demanda)
> dejó configurados son exactamente lo que un `Deployment` consume, y montar un clúster para ver
> dos `curl` distintos enseña sobre `kubectl`, no sobre Spring. La orquestación vive en
> `repaso-entrevistas/cloud/01-aws/` y `repaso-entrevistas/cloud/02-gcp/`.
> **La compilación native de GraalVM** se queda en un 🔥 opcional con su advertencia de tiempo:
> un build native tarda minutos, se cae por reflexión no registrada y lo que enseña es la
> herramienta. `L00` lo declaró como exclusión y aquí se cumple.
> **Publicar la imagen en un registro** no se hace: hace falta una cuenta, y `docker push` no
> enseña nada de Spring. El comando queda nombrado en un ejercicio 🔥.
> **Las anotaciones que aquí se usan** —`@Configuration`, `@Bean` y `@Value`— tienen su ficha en
> [`A02`](a02-catalogo-de-anotaciones.md), que es material de consulta y no de ejecución: este lab
> no las vuelve a explicar. La **simulación de entrevista**
> ([`25`](25-simulacion-de-entrevista.md)) tampoco entra aquí: es el cierre del curso entero,
> se hace cuando los diez labs ya están hechos y no cabe dentro de uno.

---

## 2. 🧱 Dentro del jar: las capas y el jarmode de herramientas

El problema es concreto y se mide en segundos de despliegue. Tu jar pesa decenas de megabytes y
el 98 % de eso son dependencias que no cambian entre commits. Si la imagen mete el jar entero en
una sola capa, **cada cambio de una línea de tu código reconstruye y retransmite esos decenas de
megabytes**. Con diez despliegues al día eso es tiempo de pipeline y ancho de banda tirados por
un fichero `.class` de dos kilobytes.

Boot ya viene preparado para esto, y no hay que activarlo. Mira primero el jar por fuera:

```bash
unzip -l target/inv-api-0.0.1-SNAPSHOT.jar | grep -E 'layers.idx|MANIFEST|BOOT-INF/(classes|lib)/$'
unzip -p target/inv-api-0.0.1-SNAPSHOT.jar META-INF/MANIFEST.MF | grep -E 'Class|Version'
```

- **`unzip -l` lista el contenido sin extraer nada**, que es lo que quieres cuando solo vas a
  comprobar que un fichero está. El `grep` recorta a las cuatro entradas que interesan.
- **`unzip -p` vuelca un fichero del zip a la salida estándar**, sin crear nada en disco. Es la
  forma de leer el `MANIFEST.MF` sin ensuciar el directorio, y el `MANIFEST` es donde `01` decía
  que vive la sorpresa: `Main-Class` apunta al `JarLauncher` de Boot, y `Start-Class` a tu
  `InvApiApplication`.
- **`BOOT-INF/lib/`** es el directorio de jars anidados. Ahí está el peso.
- **`BOOT-INF/layers.idx`** es el fichero que hace posible todo lo demás: un índice que dice qué
  entrada del jar pertenece a qué capa. **Lo escribe el `spring-boot-maven-plugin` por defecto**
  desde Boot 2.4; no hay que configurar nada para tenerlo, y hace falta configurar algo
  (`<layers><enabled>false</enabled></layers>`) para no tenerlo.

Ahora el jar por dentro, con la herramienta que Boot mete en el propio artefacto:

```bash
java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

```text
Usage:
  java -Djarmode=tools -jar my-app.jar

Available commands:
  extract      Extract the contents from the jar
  list-layers  List layers from the jar that can be extracted
  help         Help about any command
```

- **`-Djarmode=tools` no arranca tu aplicación.** Es una propiedad de sistema que el launcher de
  Boot lee **antes** de invocar tu `Start-Class`: si está presente, ejecuta el modo pedido y sale.
  Es el mismo jar, el mismo `java -jar`, y hace algo completamente distinto.
- **El jar de herramientas viaja dentro de tu artefacto.** El plugin añade
  `spring-boot-jarmode-tools` porque el parámetro `includeTools` vale `true` por defecto. Si un
  día no encuentras este modo, es que alguien lo puso en `false` para ahorrar unos kilobytes.
- **📝 El nombre del modo cambió.** Hasta Spring Boot 3.2 esto era `-Djarmode=layertools` y el
  artefacto se llamaba `spring-boot-jarmode-layertools`. En 3.3 se sustituyó por
  `-Djarmode=tools`, que hace lo mismo y además sabe extraer en el layout eficiente. Todo lo que
  encuentres escrito antes de 2024 usa el nombre viejo; en el baseline 3.5.16 el que funciona es
  `tools`.

Y las capas:

```bash
java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar list-layers
```

```text
dependencies
spring-boot-loader
snapshot-dependencies
application
```

- **El orden no es alfabético ni casual: es de menos volátil a más volátil**, y esa es toda la
  idea. Docker cachea capas por prefijo: si una capa cambia, **esa y todas las siguientes** se
  reconstruyen. Poner las dependencias primero significa que cambiar tu código invalida solo la
  última.
- **`dependencies`** son los jars de terceros cuya versión **no** contiene `SNAPSHOT`. En
  `inv-api` eso es Spring Boot, Hibernate, Hikari, Jackson, Lettuce, Resilience4j y el resto: la
  parte grande, y la que cambia cuando tocas el `pom.xml`, no cuando tocas una clase.
- **`spring-boot-loader`** son las clases del `JarLauncher`. Son pocos KB y solo cambian al
  cambiar de versión de Boot.
- **`snapshot-dependencies`** son las dependencias con `SNAPSHOT` en la versión. Van en su propia
  capa porque son inestables por definición: hoy `inv-api` no tiene ninguna, y la capa sale
  vacía. Que exista vacía no molesta y evita reordenar el `Dockerfile` el día que aparezca una.
- **`application`** es tu código y tus recursos: `BOOT-INF/classes/`, con tu `application.yml`
  dentro. Es la capa que cambia en cada commit y por eso va la última.

> **🧠 Modelo mental.** Las capas del jar no son una optimización de Spring: son **un contrato
> con el caché de Docker**. El `layers.idx` existe para que un `Dockerfile` pueda escribir cuatro
> `COPY` en el orden correcto. Sin `Dockerfile` por medio, las capas no te ahorran ni un byte.

### Reproducir el fallo: el modo que no existe sobre el jar equivocado

Maven deja dos jars en `target/`. Prueba el otro y predice qué pasa antes de ejecutar:

```bash
ls -1 target/*.jar*
java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar.original list-layers
```

```text
no main manifest attribute, in target/inv-api-0.0.1-SNAPSHOT.jar.original
```

- **`.jar.original` es el jar que produjo Maven antes de que `repackage` lo tocara**: tus clases
  y nada más, sin dependencias, sin launcher y sin `Main-Class` en el manifiesto. `01` lo nombró;
  aquí lo tocas.
- **El mensaje no menciona `jarmode` para nada**, y esa es la lección: no falló el modo de
  herramientas, falló `java -jar` antes de llegar a él. Cuando veas `no main manifest attribute`
  en un pipeline, la pregunta no es "¿por qué no arranca Spring?" sino "¿qué jar estoy lanzando?".
- **El error clásico que esto produce** es un `Dockerfile` con `COPY target/*.jar app.jar`: el
  comodín casa con **los dos** ficheros, el orden depende del shell, y un día la imagen se lleva
  el `.original`. Por eso el `Dockerfile` de la sección 3 copia un nombre exacto.

### El teardown de esta sección

No hay recursos que destruir todavía: `unzip -l`, `unzip -p` y `-Djarmode=tools` sin `extract`
**no escriben nada en disco**. Lo único que existe es `target/`, que ya estaba, y que muere con:

```bash
./mvnw -q clean
ls target 2>&1
```

```text
ls: target: No such file or directory
```

- **`./mvnw clean` borra `target/` entero**, incluidos los dos jars. No toca `~/.m2`, que es el
  caché de dependencias descargadas y sobrevive a todo: eso se trata en la sección 8.
- **`2>&1` redirige el error estándar a la salida estándar** para que el mensaje de `ls` se vea
  en la misma corriente que el resto. Sin eso, en un guion el mensaje se pierde.

Vuelve a empaquetar antes de seguir, que la sección 3 necesita el jar:

```bash
./mvnw -q clean package
```

---

## 3. 🧱 El Dockerfile multi-stage, y la capa que se reconstruye entera

Ahora el error, a propósito y antes de la solución. El `Dockerfile` ingenuo —el que está escrito
en la mitad de los repositorios— mete el fat jar en una sola capa:

```dockerfile
# inv-api/Dockerfile.naive — el que NO vas a dejar. Existe para medir el daño.
FROM eclipse-temurin:21.0.12_8-jre-noble
WORKDIR /application
COPY target/inv-api-0.0.1-SNAPSHOT.jar application.jar
ENTRYPOINT ["java", "-jar", "application.jar"]
```

- **`eclipse-temurin:21.0.12_8-jre-noble`** es el JDK del baseline con tag exacto, verificado
  contra el registro de imágenes el 19 de septiembre de 2026. `jre` y no `jdk` porque en runtime
  no hace falta el compilador; `noble` es la base Ubuntu 24.04 de esa imagen. **Ningún `latest`**,
  por la razón de [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie): un
  `latest` convierte tu despliegue en irreproducible el día que el mantenedor publique otra cosa.
- **`WORKDIR /application`** crea y entra en el directorio; sin él, el `COPY` aterriza en `/` y el
  `ENTRYPOINT` tiene que llevar rutas absolutas.
- **`COPY target/inv-api-0.0.1-SNAPSHOT.jar`** nombra el fichero exacto y no `target/*.jar`,
  precisamente por el `.jar.original` de la sección 2.
- **`ENTRYPOINT` en forma de lista (*exec form*)** y no como cadena. Esto no es estilo: en forma
  de cadena, Docker lanza `/bin/sh -c "java -jar …"` y **el PID 1 es el shell**, que no reenvía el
  `SIGTERM` a la JVM. Toda la sección 7 dejaría de funcionar. Es el error de empaquetado más caro
  del capítulo y se paga en apagados brutales, no en un mensaje de error.

Constrúyela y mide lo que cuesta cambiar una línea:

```bash
docker build -f Dockerfile.naive -t inv-api:0.0.1-naive .
sed -i.bak 's/inventario/inventario /' src/main/java/com/invlab/invapi/InvApiApplication.java
./mvnw -q clean package -DskipTests
time docker build -f Dockerfile.naive -t inv-api:0.0.1-naive .
```

- **`-f Dockerfile.naive`** elige el fichero; sin `-f`, Docker busca uno llamado `Dockerfile`.
- **`-t inv-api:0.0.1-naive`** pone nombre y tag. El tag describe **cómo** se construyó, que es lo
  que vas a comparar en la sección 4.
- **El `.` final es el contexto de build**, no el `Dockerfile`: es el directorio que Docker
  empaqueta y envía al daemon. Todo lo que haya ahí viaja, incluido `target/`, `app.log` y
  `.git/` si no lo excluyes — de ahí el `.dockerignore` de más abajo.
- **`sed -i.bak`** edita en sitio y deja una copia `.bak`; en macOS el sufijo es obligatorio y en
  GNU/Linux funciona igual. El cambio es un espacio dentro de un comentario: **la mínima
  modificación posible de tu código**, para que lo que mida el build sea la estructura de capas y
  no tu edición.
- **`time`** delante del build es la medición. **Su resultado no es determinista**: depende de tu
  disco, de tu CPU y de si el daemon tiene la capa base caliente. No copies un número de aquí;
  quédate con la comparación entre este build y el de la versión por capas.

Lo que vas a ver, descrito y no transcrito porque varía por máquina: el segundo build **no
reutiliza** la capa del `COPY`, porque el jar cambió de checksum, y vuelve a escribir el artefacto
entero. `docker history` lo enseña sin ambigüedad:

```bash
docker history --format '{{.Size}}\t{{.CreatedBy}}' inv-api:0.0.1-naive | head -5
```

- **`docker history` lista las capas de una imagen con su tamaño**, de la más reciente a la más
  antigua. En la imagen ingenua hay **una sola capa tuya** y se lleva todo el peso del jar.
- **`--format`** recorta a las dos columnas que contestan la pregunta. Sin él, la tabla incluye
  identificadores y comentarios que estorban.
- **El número concreto depende de tus dependencias** y por eso no está escrito aquí. Lo que sí es
  estable es la forma: una capa gorda, y nada más.

### La versión por capas

Ahora el `Dockerfile` que sí queda, en dos etapas:

```dockerfile
# inv-api/Dockerfile
# Etapa 1: extraer el jar en su layout por capas
FROM eclipse-temurin:21.0.12_8-jre-noble AS builder
WORKDIR /builder
ARG JAR_FILE=target/inv-api-0.0.1-SNAPSHOT.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

# Etapa 2: la imagen que se despliega
FROM eclipse-temurin:21.0.12_8-jre-noble
WORKDIR /application
# una capa de Docker por cada capa del jar, de menos volátil a más volátil
COPY --from=builder /builder/extracted/dependencies/ ./
COPY --from=builder /builder/extracted/spring-boot-loader/ ./
COPY --from=builder /builder/extracted/snapshot-dependencies/ ./
COPY --from=builder /builder/extracted/application/ ./
ENTRYPOINT ["java", "-jar", "application.jar"]
```

- **`AS builder` nombra la primera etapa.** Todo lo que pase ahí —el jar completo, el proceso de
  extracción, los ficheros intermedios— **no llega a la imagen final**: la segunda etapa empieza de
  cero desde la imagen base y solo se lleva lo que copies explícitamente con `--from`.
- **`ARG JAR_FILE`** declara una variable de build con valor por defecto, que se puede sustituir
  con `docker build --build-arg JAR_FILE=otra/ruta.jar`. Es lo que hace el fichero reutilizable
  entre Maven y Gradle sin editarlo.
- **`extract --layers --destination extracted`** es el mismo `jarmode` de la sección 2, ahora
  haciendo trabajo: escribe un directorio por capa bajo `extracted/`, con exactamente las entradas
  que el `layers.idx` le asigna.
- **Los cuatro `COPY --from=builder` son cuatro capas de Docker**, y van **en el orden que imprimió
  `list-layers`**. Invertirlos compila igual y destruye el beneficio entero: la capa volátil
  quedaría abajo e invalidaría las tres de arriba en cada cambio.
- **El `application.jar` de la etapa 2 no es el fat jar.** Es un jar pequeñito que contiene tus
  clases y un `Class-Path` en el manifiesto apuntando a `lib/`, que es lo que dejó la capa
  `dependencies`. Por eso el `ENTRYPOINT` sigue siendo `java -jar application.jar` y por eso
  arranca algo más rápido que el fat jar: el `JarLauncher` ya no tiene que abrir jars anidados
  (⏱️, el costo que [`01` §6](01-spring-boot-y-el-ecosistema.md#6--el-jar-ejecutable-y-el-plugin-de-maven)
  nombró).
- **No hay `USER`**, y eso es deuda declarada: la imagen corre como `root`. El ejercicio 🟠 12 lo
  arregla, y la sección 4 muestra que los buildpacks lo hacen solos.

Y el `.dockerignore`, que no es opcional:

```text
# inv-api/.dockerignore
.git
.mvn/wrapper/maven-wrapper.jar
app.log
app-*.log
data/
target/*
!target/inv-api-0.0.1-SNAPSHOT.jar
```

- **El contexto de build se envía entero al daemon antes de ejecutar la primera instrucción.** Sin
  `.dockerignore`, eso incluye `.git/`, tus logs y el directorio `data/` con el fichero de sesenta
  mil líneas de `L08`. Son segundos y megabytes en cada build, y sobre todo es superficie: lo que
  entra en el contexto puede acabar en una capa por accidente.
- **`target/*` seguido de `!target/inv-api-0.0.1-SNAPSHOT.jar`** excluye todo el directorio de
  build y vuelve a incluir **solo** el artefacto que el `Dockerfile` necesita. El `!` es una
  reinclusión y el orden importa: al revés no hace nada.
- **`app.log` fuera** por higiene y por privacidad: desde `L08` ese fichero contiene tokens
  decodificados y nombres de usuario.

Mide la diferencia con el mismo experimento:

```bash
docker build -t inv-api:0.0.1-dockerfile .
sed -i.bak 's/inventario /inventario/' src/main/java/com/invlab/invapi/InvApiApplication.java
./mvnw -q clean package
time docker build -t inv-api:0.0.1-dockerfile .
docker history --format '{{.Size}}\t{{.CreatedBy}}' inv-api:0.0.1-dockerfile | head -6
```

Predice antes de mirar: ¿cuántas de las cuatro capas se reconstruyen?

- **Se reconstruye una**, la de `application`. Las otras tres salen del caché y Docker lo dice en
  la salida del build con `CACHED` delante del paso. Ese `CACHED` es el dato: no el tiempo, que
  varía, sino cuántos pasos lo llevan.
- **El tiempo baja**, y cuánto depende de tu máquina y del tamaño de tus dependencias. El comando
  que lo mide es el `time` de arriba, ejecutado dos veces sobre las dos imágenes; el número no se
  escribe en el documento porque no sería el tuyo.
- **`docker history` ahora muestra cuatro capas tuyas** en vez de una, y el peso está concentrado
  en la primera. Esa es la forma que buscabas.

Deja el código como estaba antes de seguir:

```bash
rm -f src/main/java/com/invlab/invapi/InvApiApplication.java.bak
git diff --stat src/main/java/com/invlab/invapi/InvApiApplication.java
```

- **`git diff --stat` tiene que salir vacío**: los dos `sed` eran inversos y se cancelan. Si sale
  algo, revierte con `git checkout --` sobre ese fichero antes de continuar.

### El teardown de las imágenes de esta sección

Escrito aquí y no en la sección 8, como manda la serie: cada recurso dice cómo muere junto a donde
nace.

```bash
docker image rm inv-api:0.0.1-naive
docker images -q inv-api:0.0.1-naive | wc -l | tr -d ' '
```

```text
0
```

- **`docker image rm` borra el tag y, si era el último que apuntaba a esa imagen, la imagen.** Si
  hubiera un contenedor usándola, fallaría con `image is being used by running container`, y eso
  es una protección, no un estorbo.
- **`docker images -q … | wc -l` es la verificación**, y devuelve `0` porque `-q` imprime solo
  identificadores y no hay ninguno. **Contar es mejor que mirar**: un listado vacío se confunde con
  un listado que no se imprimió, y un `0` no.
- **`tr -d ' '`** quita los espacios con los que `wc` alinea su salida en macOS, para que la
  comparación sea exactamente `0`.
- **`inv-api:0.0.1-dockerfile` se queda**, porque la sección 5 la va a usar. Su borrado está en la
  sección 8.

---

## 4. ⚖ Buildpacks frente al Dockerfile escrito a mano

Escribir un `Dockerfile` bueno cuesta lo que acabas de ver: capas ordenadas, `.dockerignore`,
forma exec, usuario no root, tag fijo de la base. Multiplícalo por cuarenta servicios y por los
tres años que nadie lo va a revisar. La alternativa es no escribirlo: dejar que una herramienta
lo derive del artefacto.

```xml
<!-- inv-api/pom.xml, dentro de <build><plugins> -->
<plugin>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-maven-plugin</artifactId>
  <configuration>
    <image>
      <name>inv-api:0.0.1-buildpack</name>
      <!-- el default del plugin es paketobuildpacks/builder-noble-java-tiny:latest -->
      <builder>paketobuildpacks/builder-noble-java-tiny:0.0.190</builder>
      <env>
        <BP_JVM_VERSION>21</BP_JVM_VERSION>
      </env>
    </image>
  </configuration>
</plugin>
```

- **El plugin ya estaba en tu `pom.xml` desde `L01`**; lo que se añade es el bloque
  `<configuration><image>`. No hay que declarar versión: la trae el parent de Boot
  ([`01` §5](01-spring-boot-y-el-ecosistema.md#5--el-bom-por-qué-tu-pomxml-no-tiene-versiones)).
- **`<name>` fija el nombre y el tag de la imagen resultante.** Sin él, el plugin usa
  `docker.io/library/${project.artifactId}:${project.version}`, o sea `inv-api:0.0.1-SNAPSHOT`.
  Aquí se nombra distinto para poder comparar las dos imágenes lado a lado.
- **`<builder>` es la línea importante de este bloque y existe por una razón del curso.** El
  builder por defecto de Boot 3.5 es `paketobuildpacks/builder-noble-java-tiny:latest` —lo dice la
  documentación del plugin— y el curso prohíbe `latest` en cualquier tag. Fijarlo en `0.0.190`
  —tag verificado en el registro el 19 de septiembre de 2026— convierte un build reproducible en
  un build reproducible **de verdad**: dos ejecuciones separadas por seis meses producen la misma
  imagen base.
- **`BP_JVM_VERSION` es una variable que leen los buildpacks de Paketo**, no Spring: le dice al
  buildpack de JVM qué versión instalar. Sin ella, el buildpack la deduce del bytecode del jar y
  suele acertar; escribirla la convierte en una decisión y no en una inferencia.
- **Esto no toca el `repackage`**: el goal `build-image` empaqueta el jar ejecutable por su cuenta
  si hace falta. No hay que encadenar nada.

```bash
docker info > /dev/null 2>&1 && echo 'daemon OK'
./mvnw -q spring-boot:build-image -DskipTests
docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' inv-api
```

- **`spring-boot:build-image` necesita un daemon de Docker** y habla con él por el socket local;
  la primera línea lo comprueba antes de esperar tres minutos para descubrir que no estaba. Si el
  daemon no responde, el goal falla con `Connection to the Docker daemon ... failed`.
- **`-DskipTests` aquí sí**, y es la única vez del lab: los tests ya pasaron en la sección 1 y
  volver a correrlos solo alarga una operación que ya es la más lenta del documento.
- **La primera ejecución descarga el builder y el run image** —varios cientos de megabytes— y
  tarda **minutos**. Las siguientes reutilizan el caché de capas de CNB y bajan mucho. Ese salto
  entre la primera y la segunda vez sorprende a todo el mundo ⏱️.
- **`docker images --format` imprime nombre y tamaño de las dos imágenes**, que es la comparación
  que pedía la ficha de este lab. **Los dos números no se escriben aquí**: dependen de tu versión
  del builder, de tus dependencias y de la arquitectura de tu máquina. El comando es el dato; el
  número es tuyo.

Lo que la salida del build sí te dice, y conviene leer en vez de saltarse: el buildpack de Paketo
detecta que hay un jar de Spring Boot, **lee tu `layers.idx` y monta las mismas cuatro capas** que
tu `Dockerfile` escribió a mano. No es magia distinta: es la misma idea, automatizada.

| Criterio | `Dockerfile` a mano | `spring-boot:build-image` |
|---|---|---|
| Quién mantiene la base y sus parches | tú, en cada CVE del JRE | el builder, al subir su versión |
| Usuario no root | lo escribes tú (`USER`) | viene puesto de fábrica |
| Control fino (`apt`, ficheros extra, certificados) | total | limitado a variables `BP_*` |
| Reproducibilidad | la que te den tus tags | la del builder, si lo fijas |

**El veredicto, que en un capítulo comparativo no es opcional.** Con buildpacks por defecto se
acierta más de lo que se acierta escribiendo `Dockerfile` a mano, y por eso es la opción sensata
para una plantilla de cuarenta servicios iguales. Se escribe `Dockerfile` cuando la imagen
necesita algo que el builder no expone —un paquete del sistema, un certificado corporativo, una
base endurecida que impone tu banco— o cuando la política de seguridad exige que puedas auditar
cada línea de lo que entra. **Lo que no es un argumento válido es "el Dockerfile es más rápido":**
mídelo con los dos comandos de arriba antes de decirlo en una entrevista.

> **⚠️ La sobregeneralización de este lab.** "Los buildpacks generan imágenes más pequeñas." No
> necesariamente, y depende del builder: `tiny` no lleva ni shell ni gestor de paquetes, `base` sí.
> Lo que los buildpacks generan de forma consistente no es *más pequeño*, es **más correcto**:
> usuario no root, capas ordenadas, metadatos de procedencia y un JRE al día. La respuesta precisa
> es esa, y el tamaño se mide, no se afirma.

### El teardown de esta sección

```bash
docker image rm inv-api:0.0.1-buildpack
docker images -q inv-api:0.0.1-buildpack | wc -l | tr -d ' '
```

```text
0
```

- **La imagen de buildpacks se borra ya** porque el resto del lab usa la del `Dockerfile`: así no
  arrastras dos imágenes grandes durante tres secciones.
- **Lo que este borrado *no* se lleva** es el builder descargado ni el caché de capas de CNB, que
  son volúmenes con nombre creados por el proceso de build. Eso está en la sección 8 y es
  exactamente el tipo de resto que hace que "ya limpié" sea falso.

---

## 5. ⚠️ `inv-api` dentro de Compose: cuatro `localhost` que dejan de existir

Aquí está el cambio real del lab. Hasta ahora `inv-api` corría **fuera** de Docker y hablaba con
seis contenedores publicados en puertos de tu máquina. Todo lo que hay en tu `application.yml`
está escrito desde ese punto de vista, y ese punto de vista se acaba en el momento en que el
proceso entra en la red de Compose.

El servicio ya estaba declarado en el Compose de
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie), en el perfil `app`, con
la imagen `inv-api:0.0.1-dockerfile` fijada, `depends_on` sobre los `healthcheck` de Postgres y
Redis, `stop_grace_period: 45s` y las seis variables de entorno. **El `docker-compose.yml` no se
toca en este lab**: lo que faltaba era la imagen que ese `image:` nombra, y la acabas de construir
en la sección 3. Hoy, por primera vez en la serie, se levanta el perfil.

```yaml
  # docker-compose.yml, tal como se escribió en L01 — no se toca
  inv-api:
    image: inv-api:0.0.1-dockerfile     # la que construyó la sección 3
    profiles: ["app"]
    ports: ["8080:8080", "8081:8081"]
    environment:                        # las seis, una a una, en la sección 6
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
```

- **`image:` y no `build:`**, a propósito. Compose sabe construir, pero encadenar el build de
  Maven con el de Docker dentro de `up` esconde justo lo que la sección 3 enseñó. Aquí la imagen
  se construye antes, con su nombre y su tag, y Compose solo la ejecuta.
- **`profiles: ["app"]`** mantiene la regla de la serie: ningún servicio arranca por defecto. Es
  también lo que ha permitido que este bloque llevara ocho labs en el fichero sin estorbar, con
  una imagen que hasta hoy no existía en tu máquina.
- **`ports: ["8080:8080", "8081:8081"]`** publica la aplicación y Actuator en los mismos puertos
  de siempre, para que todos los `curl` de los ocho labs anteriores sigan funcionando desde tu
  terminal sin cambiar ni una línea. Asegúrate de que **no te queda un `java -jar` corriendo**: los
  ocuparía y el contenedor no podría publicarlos.
- **`depends_on` con `condition: service_healthy`** espera al `healthcheck` de Postgres y de Redis,
  no a que el contenedor exista. La diferencia son los segundos en que Postgres está arrancando y
  ya acepta el proceso pero no la conexión — el "en mi máquina no arranca" de
  [`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie). WireMock y Keycloak no
  están en la lista porque no declaran `healthcheck`; poner `condition: service_started` sobre
  ellos daría una falsa sensación de garantía.
- **Ese `depends_on` cruza perfiles, y por eso `--profile app` a secas no vale.** Si lo pides solo,
  Postgres y Redis no entran en el proyecto y Compose lo rechaza antes de arrancar nada con
  `service "inv-api" depends on undefined service "postgres": invalid compose project`. Todos los
  `up` de hoy van con los tres perfiles: `--profile db --profile cache --profile app`.
- **`stop_grace_period: 45s`** es el plazo que Compose da entre el `SIGTERM` y el `SIGKILL`. **El
  default son 10 segundos** y es menos que el `spring.lifecycle.timeout-per-shutdown-phase` de
  Spring, que son 30: sin esta línea, Docker mataría el proceso a mitad del apagado ordenado. La
  sección 7 vive de este número.

### Verlo fallar primero: la imagen a solas, sin la red de Compose

Antes de levantarlo como toca, arranca la imagen sola. Sin la red del proyecto, lo único que tiene
para configurarse es el `application.yml` que viaja **dentro** del jar, y ese fichero está escrito
desde el punto de vista de tu máquina:

```bash
docker run --rm inv-api:0.0.1-dockerfile 2>&1 | grep -E 'PSQLException|HikariPool|APPLICATION FAILED' | head -5
```

- **`docker run` y no `docker compose`**: el contenedor arranca fuera del proyecto `inv-lab`, sin
  red compartida y sin ninguna variable de entorno, que es justo el aislamiento que hace visible el
  problema.
- **`--rm` lo borra al salir**, y va a salir solo: el fallo ocurre al crear el pool, durante el
  arranque, así que el proceso termina sin que tengas que pararlo.
- **`2>&1` antes del `grep`** porque el arranque de Spring escribe el error por la salida estándar
  y el stack trace por la de error; sin la redirección te pierdes la mitad.

Predice antes de mirar: ¿en qué falla primero, en la base o en el token?

```text
com.zaxxer.hikari.pool.HikariPool : HikariPool-1 - Exception during pool initialization.
org.postgresql.util.PSQLException: Connection to localhost:5432 refused. Check that the hostname and port are correct and that the postmaster is accepting TCP/IP connections.
```

- **`Connection to localhost:5432 refused` es la primera línea que importa**, y dice exactamente
  la verdad: dentro del contenedor, `localhost` es **el contenedor**, no tu máquina. En
  `127.0.0.1:5432` de ese namespace de red no hay nada y nunca lo hubo.
- **Hikari lo envuelve en `Exception during pool initialization`** porque el fallo ocurre al crear
  el pool en el arranque, no al atender una petición. Es el mismo `HikariPool-1` de
  [`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool), con otra causa:
  allí el pool estaba agotado, aquí no llegó a existir.
- **El log del contenedor sustituye a `app.log`** desde este momento. El fichero que llevas
  mirando ocho labs ya no se escribe en tu directorio: la salida estándar del contenedor es el log,
  y es así como se lee un servicio en cualquier orquestador. Con el servicio ya dentro del proyecto
  se lee con `docker compose -p inv-lab logs inv-api`; añade `-f` para seguirlo y `--tail 50` para
  ver solo el final.

Y no es un `localhost` solo, son cuatro. Búscalos, porque tres de ellos son exactamente los que
el `environment` del Compose viene pisando desde `L00` —la sección 6 los explica uno a uno— y el
cuarto no se arregla así:

```bash
grep -n 'localhost' src/main/resources/application.yml
```

| Propiedad | Valor de `L04`–`L08` | Qué es dentro de Compose |
|---|---|---|
| `spring.datasource.url` | `jdbc:postgresql://localhost:5432/inv_lab` | `postgres:5432` |
| `spring.data.redis.host` | `localhost` | `redis` |
| `inv.supplier.base-url` | `http://localhost:8090` | `http://wiremock:8080` |
| `…resourceserver.jwt.issuer-uri` | `http://localhost:8180/realms/inv` | **no se traduce; ver abajo** |

- **Los tres primeros son sustituciones directas**: el nombre del servicio de Compose resuelve por
  DNS dentro de la red del proyecto, igual que `http://prometheus:9090` en el origen de datos de
  Grafana de [`L07` §8](l07-actuator-metricas-y-trazas.md#8--grafana-y-el-tablero-de-las-cuatro-señales).
- **Ojo con el puerto de WireMock.** Desde tu máquina era `8090` porque el Compose publica
  `8090:8080`; **dentro de la red, el puerto es el de dentro**, `8080`. Los puertos publicados no
  existen entre contenedores, y confundirlos da un `Connection refused` que parece un problema de
  nombre y no lo es.

### El `issuer-uri` que no se puede traducir, y por qué

El cuarto no se arregla cambiando el valor, y la razón es bonita. El claim `iss` de un token de
Keycloak es **la URL por la que se pidió el token**. Tú los pides desde la terminal con
`get_token`, que va a `localhost:8180`, así que todos tus tokens dicen
`"iss": "http://localhost:8180/realms/inv"`. Dentro del contenedor, esa URL no lleva a ninguna
parte; y si pones `http://keycloak:8080/realms/inv`, el validador de emisor rechaza tus tokens por
no coincidir carácter a carácter — el 401 que
[`L08` §3](l08-security-y-batch.md#3--inv-api-como-resource-server-y-el-401-que-no-explica-nada)
ya te hizo sufrir una vez.

```text
lo que hay que VALIDAR   → http://localhost:8180/realms/inv   (el iss del token)
lo que hay que ALCANZAR  → http://keycloak:8080/realms/inv    (el JWKS, por la red de Compose)
issuer-uri hace las dos cosas a la vez  → por eso aquí no sirve
```

La salida es separar las dos responsabilidades a mano, que es la forma canónica de este problema:

```java
// src/main/java/com/invlab/invapi/security/JwtDecoderConfig.java
@Configuration
class JwtDecoderConfig {

    @Bean
    JwtDecoder jwtDecoder(
            @Value("${inv.jwt.jwk-set-uri}") String jwkSetUri,
            @Value("${inv.jwt.issuer}") String issuer) {

        NimbusJwtDecoder decoder = NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build();

        // el validador por defecto (exp, nbf) más el emisor y la audiencia que L08 exigía
        OAuth2TokenValidator<Jwt> validator = new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(issuer),
                new JwtClaimValidator<List<String>>("aud", aud -> aud != null && aud.contains("inv-api")));

        decoder.setJwtValidator(validator);
        return decoder;
    }
}
```

- **Declarar un `JwtDecoder` propio desactiva el autoconfigurado**, porque la autoconfiguración de
  Boot para el resource server está marcada con `@ConditionalOnMissingBean`. Es el mecanismo de
  [`06`](06-arranque-y-autoconfiguracion.md) otra vez: tu bean gana sin que tengas que excluir nada.
- **`NimbusJwtDecoder.withJwkSetUri(...)` no hace descubrimiento OIDC.** Va directo al JWKS y por
  eso puede apuntar a un nombre de servicio interno; el precio es que tú te encargas de los
  validadores, que es justo lo que queremos aquí.
- **`JwtValidators.createDefaultWithIssuer(issuer)`** compone el validador de tiempo (`exp`, `nbf`)
  con un `JwtIssuerValidator` sobre la cadena que le pases. Esa cadena es la de `localhost:8180`, y
  ahí está la separación.
- **`JwtClaimValidator` sobre `aud`** reemplaza a la propiedad `jwt.audiences` de `L08`, que solo
  la lee la autoconfiguración. Si lo olvidas, pierdes silenciosamente la comprobación de audiencia
  y ningún test te lo dice: es el riesgo de sustituir un bean autoconfigurado.
- **`@Value` y no `@ConfigurationProperties`** aquí, por la regla de
  [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties): son dos
  valores sueltos consumidos en un solo sitio, no un grupo con identidad propia.
- **Las dos propiedades nuevas viven bajo `inv.jwt.`**, prefijo tuyo, porque ya no son las de
  Spring. Las de `spring.security.oauth2.resourceserver.jwt.*` **se borran del `application.yml`**:
  dejarlas sería configuración muerta que el próximo lector va a creerse.

```yaml
# application.yml, bloque común: los valores de tu máquina, que siguen siendo los de siempre
inv:
  jwt:
    issuer: http://localhost:8180/realms/inv
    jwk-set-uri: http://localhost:8180/realms/inv/protocol/openid-connect/certs
```

- **Los defaults siguen siendo los de correr fuera de Docker**, para que `./mvnw test` y un
  `java -jar` desde tu terminal sigan funcionando exactamente igual que en `L08`. Lo que cambia
  dentro del contenedor se inyecta por variable de entorno en la sección 6, sin tocar el fichero.

### El sexto `localhost`, el que está en Prometheus

`observability/prometheus.yml` apunta a `host.docker.internal:8081` porque `inv-api` vivía fuera.
Ya no.

```yaml
# observability/prometheus.yml — solo cambia el target y la etiqueta
    static_configs:
      - targets: ["inv-api:8081"]
        labels:
          instance: inv-api-compose
```

- **`inv-api:8081` es el nombre del servicio**, y funciona porque Prometheus y `inv-api` comparten
  la red del proyecto `inv-lab`. El `extra_hosts` con `host.docker.internal` que el Compose declara
  para Prometheus se queda ahí sin molestar: ya no lo usa nadie.
- **`instance: inv-api-compose`** distingue esta serie de la `inv-api-a` que quedó en el histórico
  de `L07`. Sin cambiarla, las dos etapas del lab se mezclarían en el mismo gráfico y un hueco
  parecería una caída.
- **`management.server.address` tiene que valer `0.0.0.0`** —lo puso
  [`L07` §7](l07-actuator-metricas-y-trazas.md#7--prometheus-en-compose-y-el-target-que-no-responde)
  en el perfil `local`— y ahora la razón es más fuerte: dentro de un contenedor, ligar al loopback
  no solo deja fuera al scrape, deja fuera **también a tu `curl` desde la máquina**, porque el
  reenvío del puerto publicado llega por la interfaz del contenedor. Es la misma propiedad, con una
  consecuencia peor.

```bash
./mvnw -q clean package && docker build -t inv-api:0.0.1-dockerfile .
docker compose -p inv-lab --profile db --profile cache --profile app up -d
docker compose -p inv-lab restart prometheus
sleep 20
curl -s localhost:9090/api/v1/targets | jq -c '.data.activeTargets[] | {health, scrapeUrl}'
```

```text
{"health":"up","scrapeUrl":"http://inv-api:8081/actuator/prometheus"}
```

- **Se reconstruye la imagen antes de levantarla** porque `JwtDecoderConfig` es código nuevo: la
  que construyó la sección 3 no lo trae, y una imagen vieja con un `application.yml` viejo es el
  clásico "pero si ya lo arreglé".
- **Los tres perfiles en la misma línea** (`db`, `cache`, `app`) por el `depends_on` que cruza
  perfiles; `obs` ya lo tenías arriba desde la sección 1, y los perfiles se suman, no se
  reemplazan.
- **`restart` y no `up -d`** para Prometheus: lee su configuración al arrancar y el fichero llega
  por bind mount, así que no hace falta reconstruir nada.
- **`sleep 20` da al menos un `scrape_interval` completo**, igual que en `L07`. Preguntar antes es
  cómo se fabrica un "no funciona" que sí funcionaba.

### El teardown de esta sección

```bash
docker compose -p inv-lab stop inv-api
docker compose -p inv-lab rm -f inv-api
docker compose -p inv-lab ps -a | grep -c inv-api
```

- **`stop` y `rm` sobre el nombre del servicio, y no `down`.** `down` actúa sobre **el proyecto
  entero**, no sobre el perfil que le pases: `--profile app down` se llevaría por delante Postgres,
  Redis y todo lo que tengas arriba, y la sección 6 los necesita. Nombrar el servicio es la forma de
  parar solo `inv-api`.
- **`rm -f` después del `stop`** porque `stop` deja el contenedor parado pero existente, con su capa
  de escritura ocupando disco; es justo el `Exited` que la sección 8 va a ir a buscar.
- **El `grep -c` tiene que devolver `0`**: la comprobación es que el listado no lo menciona, no que
  el comando anterior no diera error.
- **El contenedor de `inv-api` no tiene volúmenes**, así que aquí no hay estado que sobreviva: todo
  lo que guarda está en Postgres y en Redis, que son otros servicios.
- **`ps -q --status running | wc -l`** cuenta contenedores corriendo y es la verificación. El
  número que devuelve depende de cuántos perfiles tengas arriba en ese momento; lo que tiene que
  ser cierto es que **`inv-api` ya no aparece** en `docker compose -p inv-lab ps`.
- **La restauración de `prometheus.yml`** no hace falta: el fichero se queda apuntando a
  `inv-api:8081`, que es el estado correcto a partir de hoy, y el directorio entero se borra en la
  sección 8.

---

## 6. 🧱 El mismo artefacto en dos entornos: variables de entorno y el perfil `prod`

Ya sabes qué valores hay que cambiar. La pregunta que cierra el bucle de
[`L02`](l02-configuracion-y-profiles.md) es **dónde** se cambian, y la respuesta no es "en el
`application.yml`": ese fichero está dentro de la imagen, y tocarlo obliga a reconstruir y a
volver a pasar por todo el pipeline de aprobación. Lo que se cambia por entorno son variables de
entorno, que es la fuente que `07` pone por encima de los ficheros del artefacto.

```yaml
  inv-api:
    image: inv-api:0.0.1-dockerfile
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
```

- **La traducción de nombres es el *relaxed binding* de
  [`07` §5](07-configuracion-externalizada.md#5--relaxed-binding)**, y aquí se ve por qué existe:
  un entorno de Unix no admite puntos ni guiones en el nombre de una variable. La regla es
  mecánica: **mayúsculas, el punto pasa a `_`, y el guion desaparece**. Así
  `spring.datasource.url` → `SPRING_DATASOURCE_URL` y `inv.supplier.base-url` →
  `INV_SUPPLIER_BASEURL`.
- **`INV_SUPPLIER_BASEURL` sin guion bajo entre `BASE` y `URL`** es el error que se comete siempre.
  `INV_SUPPLIER_BASE_URL` también liga, porque el binding relajado acepta ambas formas, pero
  conviene aprender la canónica: el guion **se borra**, no se convierte en nada más.
- **`INV_JWT_JWKSETURI` es la única propiedad cuyo valor apunta al nombre interno**, y es
  exactamente la separación de la sección 5: el emisor que se valida sigue siendo el de `localhost`
  y llega del `application.yml`; el JWKS que se descarga cambia por entorno y llega de aquí.
- **`SPRING_PROFILES_ACTIVE: local`** se escribe aunque sea el default del lab, porque una
  configuración que depende de un default implícito es una que nadie puede leer en la revisión.
- **`JAVA_TOOL_OPTIONS` la lee la JVM, no Spring.** `MaxRAMPercentage=75` le dice al heap que
  crezca hasta el 75 % de la memoria **del contenedor**, no de tu máquina; sin ella, la JVM usa su
  default —la cuarta parte— y desperdicia lo que le asignaste ⏱️. Es la variable que más se olvida
  al contenerizar y se paga en `OutOfMemoryError` o en memoria pagada y no usada.
- **⚠️ Ningún secreto va aquí.** Estas cuatro son URLs y nombres de host. La contraseña de Postgres
  sigue llegando como en `L02`, y en un entorno real llegaría de un gestor de secretos montado como
  fichero con `spring.config.import`. Una variable de entorno es visible en `docker inspect`, en el
  `/proc` del contenedor y en `/actuator/env` si se te olvida cerrarlo.

Levanta y comprueba de dónde salió cada valor, que es el `/actuator/env` de
[`L02` §11](l02-configuracion-y-profiles.md#11--auditar-de-dónde-salió-cada-valor) con la fuente
nueva:

```bash
./mvnw -q clean package && docker build -t inv-api:0.0.1-dockerfile .
docker compose -p inv-lab --profile db --profile cache --profile app up -d
sleep 25
OPS=$(get_token ops@invlab.example ops)
curl -s -H "Authorization: Bearer $OPS" \
  'localhost:8081/actuator/env/spring.datasource.url' | jq -c '.propertySources[0]'
```

```text
{"name":"systemEnvironment","property":{"value":"jdbc:postgresql://postgres:5432/inv_lab","origin":"System Environment Property \"SPRING_DATASOURCE_URL\""}}
```

- **`propertySources[0]` es la fuente que ganó**, porque el endpoint las devuelve en orden de
  precedencia. Que salga `systemEnvironment` y no `applicationConfig` es la demostración de que la
  variable de entorno pisa al fichero del artefacto, que es toda la tesis de esta sección.
- **`origin` nombra la variable exacta**, y ese campo es el que convierte una discusión de media
  hora en una respuesta de diez segundos cuando alguien jura que el fichero dice otra cosa.
- **Hace falta el token de `ops`** porque `L08` cerró Actuator. Si responde `403`, te trajiste el
  token del analista.

### El perfil `prod` simulado

El baseline declara tres perfiles y hasta hoy `prod` era una promesa. Aquí se cumple, con lo mínimo
que lo hace útil:

```yaml
# src/main/resources/application-prod.yml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
logging:
  structured:
    format:
      console: ecs
management:
  endpoints:
    web:
      exposure:
        include: health,info,prometheus
  endpoint:
    health:
      show-details: never
```

- **`ddl-auto: validate`** ya estaba en el bloque común desde
  [`L04`](l04-datos-y-transacciones.md); se repite aquí a propósito, porque es la propiedad cuyo
  valor accidental en producción cuesta una tabla. Repetir una garantía en el perfil que más
  importa no es duplicación, es defensa en profundidad.
- **`logging.structured.format.console: ecs` cambia el log a JSON de una línea por evento**, en el
  formato Elastic Common Schema. **📝 Es una capacidad nativa desde Spring Boot 3.4**: antes había
  que añadir `logstash-logback-encoder` y un `logback-spring.xml`. Los otros dos formatos que trae
  de fábrica son `gelf` y `logstash`.
- **Por qué JSON y no el log bonito:** un log de varias líneas por evento —un stack trace— es
  imposible de correlacionar en un agregador. Con un evento por línea, el `traceId` de
  [`L07` §10](l07-actuator-metricas-y-trazas.md#10--micrometer-tracing-el-traceid-de-punta-a-punta)
  se convierte en un campo consultable en vez de en una cadena que hay que buscar con expresiones
  regulares.
- **`exposure.include` recortado a tres endpoints** y `show-details: never`: en `local` querías ver
  el detalle del health, en `prod` ese detalle publica el estado de tus dependencias a quien
  pregunte. Actuator sigue cerrado por Security desde `L08`; esto es la segunda capa.

```bash
# ...tras cambiar SPRING_PROFILES_ACTIVE a "local,prod" en el docker-compose.yml
docker compose -p inv-lab --profile db --profile cache --profile app up -d
docker compose -p inv-lab logs inv-api --tail 3
```

- **`up -d` sin `down` delante** es suficiente: Compose compara la configuración declarada del
  servicio con la del contenedor vivo y **lo recrea** cuando difieren. Un `down` aquí pararía el
  proyecto entero, Postgres incluido, para cambiar una variable de un solo servicio.
- **Este es el único fichero que el lab edita**, y es una edición de **valor**, no de estructura:
  cambias una variable, miras qué pasa y la dejas como estaba. El `docker-compose.yml` sigue siendo
  el de `L00` §6 cuando termines.
- **`local,prod` y no `prod` a secas**, y el orden importa: como demostró
  [`L02` §8](l02-configuracion-y-profiles.md#8--profiles-local-test-y-el-experimento-de-los-dos-a-la-vez),
  **gana el último**. Con `prod` al final, sus valores pisan a los de `local` y el resto de la
  configuración del lab —las URLs internas, el `management.server.address`— se conserva.
- **Las tres últimas líneas del log tienen que ser JSON**: un objeto por línea, con `@timestamp`,
  `log.level` y `message` entre sus campos. Si siguen saliendo con colores y columnas, el perfil no
  se activó, y lo confirma la línea `The following 2 profiles are active` del arranque.
- **`--tail 3`** limita la salida: sin él, `logs` vuelca todo el arranque.
- **La misma imagen, sin recompilar, en dos entornos.** Ese es el punto entero de la sección y la
  respuesta a "¿por qué no metes la configuración en el jar?". Vuelve a dejar
  `SPRING_PROFILES_ACTIVE: local` antes de la sección 7, para que el log vuelva a ser legible
  mientras miras un apagado.

---

## 7. 🩺 Graceful shutdown con una petición en vuelo

El problema, dicho con números de banca: tu servicio recibe un `SIGTERM` porque el orquestador está
desplegando la versión nueva. En ese instante hay diecisiete peticiones a medio atender, y tres de
ellas están dentro de un `@Transactional` que ya hizo el `INSERT` y todavía no el commit. Si el
proceso muere ahí, el cliente recibe un error de transporte —sin código HTTP, así que ni siquiera
sabe si su movimiento se registró— y tú tienes tres transacciones abortadas sin nada que las
explique.

Primero, la sobregeneralización, porque es de las que se dicen en entrevista con toda seguridad:

> Nunca respondas: *"hay que poner `server.shutdown=graceful` para que Spring Boot cierre bien"*.

**En el baseline 3.5.16 ese es el valor por defecto** —verificado en el índice de propiedades de
3.5— junto con `spring.lifecycle.timeout-per-shutdown-phase` en `30s`. En Spring Boot 2.7 el
default de `server.shutdown` sí era `immediate`, y de ahí viene la respuesta clásica. La versión
precisa es esta:

```text
server.shutdown                              graceful  (default en 3.5; era immediate en 2.7)
spring.lifecycle.timeout-per-shutdown-phase        30s  (cuánto se espera a las peticiones vivas)
stop_grace_period de Compose                       10s  (default: MENOS que los 30 de Spring)
```

- **Los dos primeros los pone Spring, el tercero lo pone quien te ejecuta**, y el que manda es el
  más corto. Ese desajuste es el bug real de esta sección: la configuración de Spring está
  perfecta y el apagado ordenado no ocurre igual, porque a los diez segundos llega un `SIGKILL`
  que no se negocia. Por eso el servicio declaró `stop_grace_period: 45s`.

### Reproducirlo: apagar mientras llega una petición lenta

`inv-supplier` sabe tardar desde [`L05`](l05-clientes-y-resiliencia.md): el `sku` `SLW-000002`
responde en unos dos segundos. Necesitas un poco más de margen, así que sube el stub y el
`read-timeout` un momento:

```bash
curl -s -X POST localhost:8090/__admin/mappings/reset > /dev/null
ANALYST=$(get_token analyst@invlab.example analyst)
(curl -s -o /tmp/inflight.txt -w 'en vuelo -> %{http_code} en %{time_total}s\n' \
   -H "Authorization: Bearer $ANALYST" \
   'localhost:8080/api/items/SLW-000002/quote' &) ; sleep 1
docker compose -p inv-lab stop inv-api
```

- **El paréntesis con `&` al final lanza el `curl` en segundo plano** y devuelve el control
  inmediatamente; el `sleep 1` da tiempo a que la petición llegue a Tomcat y esté **dentro** del
  controller cuando llegue la señal. Ese segundo es todo el experimento: sin él, o no ha llegado o
  ya terminó.
- **`docker compose stop` envía `SIGTERM` al PID 1 del contenedor** y espera el
  `stop_grace_period`. Es la misma señal que manda Kubernetes al empezar a terminar un pod, y por
  eso este experimento se parece a un despliegue de verdad y no a un `Ctrl-C`.
- **`-w '%{http_code} en %{time_total}s'`** imprime el código y el tiempo total. **Un `000` en
  `%{http_code}` significa que no hubo respuesta HTTP**: la conexión se cortó antes. Es el valor
  que quieres reconocer.
- **`/tmp/inflight.txt`** recoge el cuerpo para poder mirarlo después; el fichero vive en el
  temporal del sistema y no ensucia el repositorio.

Ahora mira el log del apagado:

```bash
docker compose -p inv-lab logs inv-api --tail 20 | grep -iE 'shutdown|graceful'
```

```text
o.s.b.w.e.t.GracefulShutdown : Commencing graceful shutdown. Waiting for active requests to complete
o.s.b.w.e.t.GracefulShutdown : Graceful shutdown complete
```

- **`Commencing graceful shutdown` la escribe `GracefulShutdown` de Tomcat**, no tu código, y marca
  el instante en que **Tomcat deja de aceptar conexiones nuevas a nivel de red** y deja terminar a
  las vivas. Reconocer esas dos líneas es la mitad del valor de la sección.
- **`Graceful shutdown complete` significa que las peticiones activas acabaron solas**, dentro del
  plazo. Si el plazo se agota, la línea que aparece en su lugar es
  `Graceful shutdown aborted with one or more requests still active`, y esa es la que te dice que
  tu timeout es más corto que tu petición más lenta.
- **Quién ejecuta esto y en qué hilo**, que es la pregunta que el curso hace en cada mecanismo: lo
  dispara el *shutdown hook* que `SpringApplication` registra en el arranque, corriendo en un hilo
  propio de la JVM; desde ahí se cierra el `ApplicationContext`, y el cierre para los beans
  `SmartLifecycle` empezando por la fase más temprana, que es donde vive el servidor web. No hay
  proxy por medio: es ciclo de vida del contexto, no AOP.

Y el `curl` que estaba en vuelo terminó con un `200` y su tiempo completo, porque Tomcat lo dejó
acabar. Compáralo con el otro camino.

### La variante brutal, para tener con qué comparar

```bash
# en el docker-compose.yml, temporalmente:
#   environment: SERVER_SHUTDOWN: immediate
docker compose -p inv-lab --profile db --profile cache --profile app up -d && sleep 25
(curl -s -o /dev/null -w 'en vuelo -> %{http_code} en %{time_total}s\n' \
   -H "Authorization: Bearer $ANALYST" \
   'localhost:8080/api/items/SLW-000002/quote' &) ; sleep 1
docker compose -p inv-lab stop inv-api
```

- **`SERVER_SHUTDOWN: immediate` es `server.shutdown` por variable de entorno**, otra vez el
  binding relajado de la sección 6. Se pone aquí y no en el `application.yml` precisamente para
  demostrar que se puede cambiar el comportamiento de apagado **sin reconstruir la imagen**.
- **El `curl` no devuelve `200`.** Devuelve `000` y termina con un error de transporte —`curl: (52)
  Empty reply from server` o `curl: (18) transfer closed with N bytes remaining`, según en qué
  punto exacto se cortó el socket—. **Cuál de los dos te toca no es determinista** y depende del
  instante de la señal; el dato que sí es estable es el `000`, que significa "no hubo respuesta
  HTTP".
- **El log ya no trae `Commencing graceful shutdown`.** No hay espera, no hay drenado: el contexto
  se cierra y el conector se lleva por delante lo que estuviera dentro.

> **⚠️ El apagado ordenado no es una promesa de consistencia.** Drena peticiones HTTP; no espera a
> tus `@Async` en vuelo, ni a un job de Batch a la mitad, ni a un `@Scheduled` que acaba de
> empezar. Para el pool del `@Async` de [`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás)
> hace falta además `spring.task.execution.shutdown.await-termination: true` con su
> `await-termination-period`. Responder "con graceful shutdown no se pierde nada" en una entrevista
> de banca es la respuesta equivocada: se pierde todo lo que no sea una petición HTTP viva.

### El tercer plazo, el que no es tuyo

Baja `stop_grace_period` a `5s` y repite el primer experimento con el apagado ordenado activado.

- **El resultado es el peor de los tres**, y es el que más se da en producción: Spring empieza el
  drenado ordenado, escribe `Commencing graceful shutdown`, y a los cinco segundos el `SIGKILL` de
  Docker mata el proceso a media frase. El cliente recibe el mismo `000` que con `immediate`, y el
  log **miente**: dice que empezó a apagarse bien y no dice que lo mataron.
- **La regla para llevarse a una entrevista:** `stop_grace_period` (o `terminationGracePeriodSeconds`
  en Kubernetes) tiene que ser **mayor** que `spring.lifecycle.timeout-per-shutdown-phase`, y ese a
  su vez mayor que tu petición más lenta. Tres números en tres ficheros distintos, mantenidos por
  tres equipos distintos: por eso falla tanto.

Deja `stop_grace_period: 45s` y quita `SERVER_SHUTDOWN` antes de seguir.

### El teardown de esta sección

```bash
rm -f /tmp/inflight.txt
docker compose -p inv-lab --profile db --profile cache --profile app up -d
sleep 25
curl -s -o /dev/null -w 'health -> %{http_code}\n' localhost:8081/actuator/health
```

```text
health -> 200
```

- **El único resto en disco era `/tmp/inflight.txt`**, que se borra en la primera línea.
- **El servicio vuelve a levantarse** porque la sección 8 necesita el sistema completo arriba para
  poder demostrar que lo destruye.

---

## 8. 🧪 La limpieza verificada

Esta sección es el criterio de terminado del lab y de la serie entera. La regla es la de
[`L00` §9](l00-idea-lab-practico.md#9--cómo-se-limpia-todo), llevada hasta el final: **la limpieza
no se da por buena porque el comando de borrado no diera error, se da por buena porque el comando
de comprobación devuelve `0`.**

Mira primero lo que hay, para saber qué estás destruyendo:

```bash
docker compose -p inv-lab ps -a --format '{{.Name}}\t{{.State}}'
docker volume ls -f name=inv-lab --format '{{.Name}}'
docker network ls -f name=inv-lab --format '{{.Name}}'
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^inv-api:'
```

- **`ps -a` incluye los contenedores parados**, que es donde se esconde lo que `ps` a secas no
  lista. Un contenedor `Exited` sigue ocupando disco con su capa de escritura.
- **`-f name=inv-lab` filtra por prefijo de nombre**, y funciona porque `name: inv-lab` en el
  Compose hace que todos los recursos lo lleven delante. Ese fue el motivo de ponerlo, escrito en
  `L00` y cobrado aquí.
- **Las tres primeras órdenes tienen que listar algo ahora**: seis o siete contenedores, el
  volumen `inv-lab_postgres-data` —más `inv-lab_mongo-data` **solo si** hiciste el 🔥 opcional de
  Mongo de [`L04`](l04-datos-y-transacciones.md), que es el único punto de la serie que levanta
  el perfil `nosql`— y la red `inv-lab_default`.

### El borrado, y su verificación inmediata

```bash
docker compose -p inv-lab down -v --remove-orphans
docker compose -p inv-lab ps -aq | wc -l | tr -d ' '
docker volume ls -q -f name=inv-lab | wc -l | tr -d ' '
docker network ls -q -f name=inv-lab | wc -l | tr -d ' '
```

```text
0
0
0
```

- **`down -v` para los contenedores, borra la red y borra los volúmenes con nombre.** Sin `-v`,
  `inv-lab_postgres-data` sobrevive con las sesenta mil filas de `L08` dentro, y el día que
  vuelvas a levantar el lab te encuentras datos de hace tres semanas preguntándote de dónde
  salieron.
- **`--remove-orphans` elimina contenedores de servicios que ya no están declarados.** Si probaste
  la segunda instancia de [`L06` §5](l06-cache-y-asincronia.md#5-️-dos-instancias-dos-cachés-dos-verdades)
  y la dejaste a medias, está aquí.
- **`-p inv-lab` apunta al proyecto por nombre** y por eso funciona desde cualquier directorio, sin
  necesidad de tener el `docker-compose.yml` delante.
- **Las tres verificaciones devuelven `0` y son el corazón de la sección.** `-q` imprime solo
  identificadores, `wc -l` los cuenta, y `tr -d ' '` normaliza el espaciado de macOS. **Un `0` es
  una afirmación; un listado vacío es una ambigüedad** —puede ser que el comando ni se ejecutara—.
  Esa diferencia es toda la disciplina que esta sección enseña.

### Lo que `down -v` no se lleva, una cosa por vez

Y aquí está el motivo de que la sección exista. `down -v` deja vivo todo esto:

```bash
# 1. las imágenes que construiste hoy
docker image rm inv-api:0.0.1-dockerfile
docker images -q --filter 'reference=inv-api' | wc -l | tr -d ' '
```

```text
0
```

- **Una imagen no es un contenedor**, y `down` opera sobre contenedores. Las dos imágenes de las
  secciones 3 y 4 ya se borraron ahí; esta es la tercera, la que usó Compose.
- **`--filter 'reference=inv-api'`** casa cualquier tag de ese repositorio, así que si te quedó
  alguna variante de un ejercicio, también la cuenta. Si el resultado no es `0`, el propio listado
  sin `-q` te dice cuál quedó.

```bash
# 2. las imágenes base y de la serie, que sí ocupan de verdad
docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' \
  | grep -E 'postgres|redis|mongo|wiremock|prometheus|grafana|keycloak|temurin|paketo'
docker image rm postgres:17.11-alpine redis:8.6.6-alpine \
  wiremock/wiremock:3.13.2-alpine prom/prometheus:v3.13.3 grafana/grafana:13.0.9 \
  quay.io/keycloak/keycloak:26.7.4 eclipse-temurin:21.0.12_8-jre-noble \
  paketobuildpacks/builder-noble-java-tiny:0.0.190
docker image ls -q --filter 'reference=*/*keycloak*' | wc -l | tr -d ' '
```

- **Se borran por nombre y tag exactos, no con `prune`.** Un `docker image prune -a` borraría
  también las imágenes de otros proyectos tuyos que no tengan un contenedor corriendo, y eso es
  destruir el trabajo de otro con un comando pensado para limpiar el propio. **Nombrar lo que se
  borra es parte de la disciplina.**
- **El primer comando lista antes de borrar** para que veas el espacio del que estamos hablando —
  del orden de un par de gigabytes entre las ocho, aunque **la cifra exacta depende de tu
  arquitectura y de las capas compartidas** y por eso no está escrita aquí.
- **`mongo:8.0.32-noble` no está en el borrado, y el `grep` de arriba sí lo busca.** El hilo
  principal de la serie nunca baja esa imagen: el perfil `nosql` solo se levanta en el 🔥 opcional
  de [`L04`](l04-datos-y-transacciones.md). Si lo hiciste, el primer comando te la va a listar y
  entonces la añades a mano al `docker image rm`; si no, no está y pedir su borrado haría fallar
  el comando entero con `No such image`.
- **`docker image rm` puede fallar con `image is referenced in multiple repositories`** si el
  builder de Paketo dejó tags intermedios. No es un error tuyo: se resuelve añadiendo esos tags a
  la lista, y el mensaje los nombra.
- **Si no vas a repetir la serie, bórralas. Si vas a repetirla la semana que viene, no**: volver a
  descargarlas son varios minutos. Esta es una decisión, no una regla, y el lab la deja escrita
  para que sea consciente.

```bash
# 3. el caché de build de Docker y el del builder de CNB
docker buildx prune -f
docker volume ls -q -f name=pack-cache | wc -l | tr -d ' '
docker volume rm $(docker volume ls -q -f name=pack-cache) 2>/dev/null
docker volume ls -q -f name=pack-cache | wc -l | tr -d ' '
```

```text
0
```

- **`docker buildx prune -f` borra el caché de capas intermedias del build**, que es lo que hace que
  el segundo `docker build` sea rápido. Puede ser el mayor consumidor de disco de toda la serie y
  **no aparece en `docker images`**, que es exactamente por lo que la gente cree que limpió y no.
  `-f` evita la confirmación interactiva.
- **`pack-cache-…` son los volúmenes que crea el buildpack** para su caché de capas y su workspace.
  Sobreviven a todo lo anterior porque no pertenecen al proyecto `inv-lab`: los creó el plugin de
  Maven, no Compose. Si no corriste la sección 4, el primer conteo ya devuelve `0` y el `rm` no
  hace nada.
- **`2>/dev/null` en el `rm`** silencia el error de `docker volume rm` sin argumentos, que es lo
  que pasa cuando la lista viene vacía. La verificación siguiente es la que manda.

```bash
# 4. lo que está en tu disco y no en Docker
ls -d wiremock observability keycloak data 2>/dev/null
rm -rf wiremock observability keycloak data
ls -d wiremock observability keycloak data 2>/dev/null | wc -l | tr -d ' '
```

```text
0
```

- **Los tres primeros son los bind mounts de la serie**: `wiremock/` con los stubs de `L05`,
  `observability/` con el `prometheus.yml` y el `alerts.yml` de `L07`, y `keycloak/` con el realm
  de `L08`. Son directorios de tu repositorio y Docker no los toca nunca: `down -v` borra volúmenes
  con nombre, no bind mounts.
- **`data/` lo creó `L08`** con el fichero de sesenta mil movimientos.
- **⚠️ Piensa antes de ejecutar este bloque.** Si esos directorios están versionados en tu
  repositorio, `rm -rf` los borra del árbol de trabajo y `git status` te lo va a decir; con un
  `git checkout -- .` vuelven. Si **no** están versionados —que es lo probable si seguiste los labs
  sin hacer commit—, este borrado es definitivo y tendrás que volver a generarlos con los comandos
  de `L05`, `L07` y `L08`. La limpieza es destructiva por definición; lo que no es aceptable es que
  sea destructiva **por sorpresa**.

```bash
# 5. el proyecto Java
./mvnw -q clean
ls -d target 2>/dev/null | wc -l | tr -d ' '
du -sh ~/.m2/repository 2>/dev/null
```

```text
0
```

- **`./mvnw clean` se lleva `target/`** con los jars, las clases y el `extracted/` si probaste el
  `jarmode` a mano.
- **`~/.m2/repository` no se borra y el comando solo lo mide**, a propósito. Es el caché de
  dependencias de Maven, es compartido con todos tus proyectos y borrarlo obliga a redescargar
  Spring Boot entero la próxima vez. **Su tamaño depende de todo lo que hayas compilado en tu vida**
  y por eso aquí solo hay un `du`, no un número.
- **`app.log`, `app-a.log` y `app-b.log`** de los labs anteriores están en el `.dockerignore` pero
  no en el `.gitignore` necesariamente: `rm -f app*.log` los quita, y merece la pena porque desde
  `L08` contienen tokens.

### El comando que demuestra que la máquina quedó como estaba

Uno solo, que responde la pregunta entera:

```bash
echo "contenedores: $(docker compose -p inv-lab ps -aq | wc -l | tr -d ' ')"
echo "volúmenes:    $(docker volume ls -q -f name=inv-lab | wc -l | tr -d ' ')"
echo "redes:        $(docker network ls -q -f name=inv-lab | wc -l | tr -d ' ')"
echo "imágenes:     $(docker images -q --filter 'reference=inv-api' | wc -l | tr -d ' ')"
echo "puertos:      $(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -cE ':(8080|8081|8090|8180|5432|6379|9090|3000) ')"
echo "directorios:  $(ls -d wiremock observability keycloak data target 2>/dev/null | wc -l | tr -d ' ')"
```

```text
contenedores: 0
volúmenes:    0
redes:        0
imágenes:     0
puertos:      0
directorios:  0
```

- **Seis contadores y seis ceros.** Es el criterio de terminado de este lab, y el que el plan de
  producción del curso fija para toda la serie: *`docker compose down -v` deja la máquina como
  estaba, demostrado con un comando*.
- **`lsof -nP -iTCP -sTCP:LISTEN`** lista los sockets en escucha; `-n` evita resolver nombres de
  host y `-P` evita traducir números de puerto a nombres de servicio, que es lo que hace la salida
  predecible. El `grep -c` cuenta cuántos de los ocho puertos de la serie siguen ocupados.
- **Si `puertos` no da `0`**, tienes un `java -jar` tuyo vivo de una sección anterior. `jobs` lo
  lista en la terminal donde lo lanzaste y `kill %1` lo termina; si cerraste esa terminal,
  `pkill -f inv-api-0.0.1-SNAPSHOT.jar` lo encuentra por línea de comandos.
- **Este bloque es reutilizable tal cual.** Guárdalo como `verificar-limpieza.sh`: es el guion que
  se corre al final de cualquier sesión de la serie, no solo hoy.

---

## 9. 📋 Checklist de salida

- [ ] `unzip -l target/inv-api-0.0.1-SNAPSHOT.jar | grep -c layers.idx` devuelve `1`.
- [ ] `java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar list-layers` imprime cuatro líneas en el orden `dependencies`, `spring-boot-loader`, `snapshot-dependencies`, `application`.
- [ ] `java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar.original list-layers` falla con `no main manifest attribute`.
- [ ] El `Dockerfile` tiene dos etapas, cuatro `COPY --from=builder` en el orden de las capas y un `ENTRYPOINT` en forma de lista.
- [ ] Existe `.dockerignore` con `.git`, `app.log` y `data/`, y `docker build` con el código sin tocar reporta `CACHED` en los tres primeros `COPY`.
- [ ] `docker history inv-api:0.0.1-dockerfile` muestra cuatro capas propias, no una.
- [ ] `grep -c 'builder-noble-java-tiny:0.0.190' pom.xml` devuelve `1` y no aparece ningún `latest` en el `pom.xml`.
- [ ] `docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' inv-api` deja por escrito los tamaños de las dos imágenes construidas, medidos en tu máquina.
- [ ] `grep -c localhost src/main/resources/application.yml` devuelve como mucho `2`, y los que quedan son `inv.jwt.issuer` y `inv.jwt.jwk-set-uri`.
- [ ] Con `inv-api` en Compose, un `GET /api/items/ABC-000123/valuation` sin token responde `401` y con el token del analista responde `200`.
- [ ] `curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[].scrapeUrl'` dice `http://inv-api:8081/actuator/prometheus` y el target está en `up`.
- [ ] `/actuator/env/spring.datasource.url` con el token de `ops` devuelve `systemEnvironment` como primera fuente y el `origin` nombra `SPRING_DATASOURCE_URL`.
- [ ] Con `SPRING_PROFILES_ACTIVE: local,prod`, las líneas del log son objetos JSON de una sola línea.
- [ ] Con el apagado ordenado, el `curl` en vuelo termina en `200` y el log trae `Commencing graceful shutdown` y `Graceful shutdown complete`.
- [ ] Con `SERVER_SHUTDOWN: immediate`, ese mismo `curl` termina en `000` y el log no trae ninguna de las dos líneas.
- [ ] `stop_grace_period` del servicio `inv-api` es mayor que `spring.lifecycle.timeout-per-shutdown-phase`.
- [ ] Los seis contadores de la sección 8 devuelven `0`, cada uno en su línea.
- [ ] `jobs` no lista ningún `java -jar` y `git status` no muestra ficheros generados sin querer.

---

## 🧠 Preguntas rápidas

1. ¿Qué contiene exactamente `BOOT-INF/layers.idx`, quién lo escribe y qué se rompe si alguien
   pone `<layers><enabled>false</enabled></layers>` en el `pom.xml`?
2. Enumera las cuatro capas por defecto en su orden y explica por qué ese orden y no el inverso.
   ¿Qué pasa si inviertes los cuatro `COPY` del `Dockerfile`?
3. `java -Djarmode=tools -jar app.jar` no arranca tu aplicación. ¿Quién lee esa propiedad, en qué
   momento del arranque, y por qué el mismo comando sin ella sí arranca Spring?
4. Lanzas `java -jar` y recibes `no main manifest attribute`. Di las dos causas más probables en
   un proyecto de Boot y cómo distingues una de la otra en un comando.
5. `ENTRYPOINT ["java", "-jar", "app.jar"]` frente a `ENTRYPOINT java -jar app.jar`: explica qué
   cambia en el proceso PID 1 y qué sección de este lab deja de funcionar con la segunda forma.
6. "Los buildpacks generan imágenes más pequeñas que un `Dockerfile`." Corrige la frase con la
   versión precisa y di qué es lo que sí garantizan de forma consistente.
7. El builder por defecto de `spring-boot:build-image` en Boot 3.5 termina en `:latest`. ¿Por qué
   el curso lo fija, y qué se pierde exactamente al no fijarlo?
8. Tu contenedor muere en el arranque con `Connection to localhost:5432 refused`. Explica por qué
   `localhost` es una respuesta correcta desde tu terminal e incorrecta dentro del contenedor.
9. WireMock se publica como `8090:8080`. ¿Qué puerto pone `inv-api` en su `base-url` cuando corre
   fuera de Compose y cuál cuando corre dentro? Escribe la regla general.
10. `issuer-uri` no se puede traducir a un nombre de servicio interno. Explica por qué, y describe
    la solución con sus dos mitades: qué se valida y qué se alcanza.
11. Escribe el nombre de la variable de entorno que liga con `inv.supplier.base-url` y enuncia las
    tres reglas de conversión que usaste.
12. `server.shutdown=graceful` es el default en el baseline del curso. Di desde qué versión, cuál
    era el valor anterior, y por qué la respuesta "hay que activarlo" sigue apareciendo en
    entrevistas.
13. Tienes `spring.lifecycle.timeout-per-shutdown-phase: 30s` y `stop_grace_period: 10s`. Describe
    qué ve el cliente, qué dice el log, y por qué ese caso es peor que no tener apagado ordenado.
14. ¿Qué drena el graceful shutdown y qué **no** drena? Nombra las tres cosas que se quedan fuera
    y la propiedad que rescata una de ellas.
15. Después de `docker compose -p inv-lab down -v --remove-orphans`, enumera las cinco clases de
    recurso que siguen ocupando disco en tu máquina y el comando que mide o borra cada una.

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor o en otro punto  (1–5)

#### 🟢 Ejercicio 1 — extraer el jar a mano y arrancarlo desde ahí

Corre `java -Djarmode=tools -jar target/inv-api-0.0.1-SNAPSHOT.jar extract --destination unpacked`
y arranca con `java -jar unpacked/inv-api-0.0.1-SNAPSHOT.jar`. Comprueba con `ls unpacked/lib | wc -l`
cuántos jars hay sueltos y que la aplicación responde en `8080` igual que antes. Borra `unpacked/`
al terminar y verifica con `ls -d unpacked 2>/dev/null | wc -l`.
**Objetivo:** ver que el layout extraído no es "el jar descomprimido" sino un jar pequeño más un
`lib/`, y que arranca sin el `JarLauncher` por medio.

#### 🟢 Ejercicio 2 — el `.dockerignore` que no funciona

Quita la línea `!target/inv-api-0.0.1-SNAPSHOT.jar` del `.dockerignore` y vuelve a construir.
Anota el mensaje exacto del fallo y en qué instrucción del `Dockerfile` ocurre.
**Pregunta:** ¿el error habla del `.dockerignore` en algún momento, y cómo llegarías a él si no
supieras lo que acabas de hacer?

#### 🟢 Ejercicio 3 — otra base, mismo `Dockerfile`

Cambia las dos líneas `FROM` a `eclipse-temurin:21.0.12_8-jre-alpine` —tag verificado en el
registro— y reconstruye. Compara los tamaños con
`docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' inv-api` y arranca el contenedor para
comprobar que sigue respondiendo.
**Objetivo:** medir en tu máquina lo que cuesta la elección de base, en vez de repetir la cifra que
alguien dijo en una charla.

#### 🟢 Ejercicio 4 — un quinto `localhost`

Antes de leer la tabla de la sección 5, escribe tú la lista de propiedades de `application.yml` que
contienen `localhost` con `grep -n localhost src/main/resources/application.yml`, y clasifica cada
una en "se traduce a nombre de servicio" o "no se traduce". Justifica las que no.
**Objetivo:** que la traducción deje de ser una receta y pase a ser una pregunta que sabes hacerte
sobre cualquier propiedad.

#### 🟢 Ejercicio 5 — el health del contenedor

Añade un `healthcheck` al servicio `inv-api` que consulte `/actuator/health/readiness` en el 8081 y
comprueba con `docker compose -p inv-lab ps` que pasa de `starting` a `healthy`. Para WireMock con
`docker compose -p inv-lab stop wiremock` y observa qué hace el estado.
**Pregunta:** ¿por qué `readiness` y no `health` a secas, según lo que `L07` puso en cada grupo?

### 🟡 Intermedio — aplicarlo a otra clase, otro endpoint u otra propiedad  (6–10)

#### 🟡 Ejercicio 6 — una capa propia para tu código de dominio

Escribe un `layers.xml` que saque las clases de `com.invlab.invapi.batch` a una capa propia llamada
`batch`, declárala en el `pom.xml` y comprueba con `list-layers` que ahora hay cinco. Añade su
`COPY` al `Dockerfile` en la posición correcta.
**Objetivo:** entender que las capas son configuración y no una constante del framework, y decidir
tú dónde va la frontera entre lo volátil y lo estable.

#### 🟡 Ejercicio 7 — el perfil `prod` de verdad

Haz que el perfil `prod` además ponga `management.server.address` en `127.0.0.1` y comprueba qué
le pasa al scrape de Prometheus cuando `inv-api` corre dentro de Compose con `local,prod`.
Documenta el diagnóstico con `curl -s localhost:9090/api/v1/targets`.
**Pregunta:** ¿cuál de las dos configuraciones —la del lab o la de este ejercicio— es la correcta
en Kubernetes, y por qué el lab no puede usarla?

#### 🟡 Ejercicio 8 — el log estructurado, consultado

Con `local,prod` activos, saca el `traceId` de una petición con
`docker compose -p inv-lab logs inv-api | jq -r 'select(.message|test("valuation")) | .["trace_id"]'`
y úsalo para filtrar todas las líneas de esa petición.
**Objetivo:** comprobar que un log JSON no es cosmética: convierte `grep` en una consulta con
campos, que es lo que hace un agregador.

#### 🟡 Ejercicio 9 — `JAVA_TOOL_OPTIONS` medido

Levanta `inv-api` con `mem_limit: 512m` en Compose, primero sin `JAVA_TOOL_OPTIONS` y después con
`-XX:MaxRAMPercentage=75`. Compara `jvm_memory_max_bytes{area="heap"}` en
`/actuator/prometheus` en los dos casos.
**Objetivo:** ver con una métrica que la JVM sí respeta el límite del contenedor y que el default
deja memoria sin usar. ⏱️

#### 🟡 Ejercicio 10 — apagar con el job corriendo

Lanza `inventory-reconciliation-job` de `L08` y manda `docker compose -p inv-lab stop inv-api` a
mitad de la ejecución. Mira `batch_step_execution` y di en qué estado quedó.
**Pregunta:** ¿el graceful shutdown esperó al job? ¿Qué dice eso sobre qué protege exactamente, y
qué tendrías que añadir para que lo esperase?

### 🟠 Difícil — combinar, diagnosticar o decidir  (11–14)

#### 🟠 Ejercicio 11 — el `Dockerfile` con las capas invertidas

Escribe una variante con los cuatro `COPY` en orden inverso, construye, cambia una línea de código,
reconstruye y cuenta cuántos pasos salen `CACHED` en cada versión. Anota los dos tiempos con `time`.
**Objetivo:** convertir "el orden importa" en dos números medidos en tu máquina, que es lo que se
puede defender en una revisión de arquitectura.

#### 🟠 Ejercicio 12 — usuario no root, y lo que rompe

Añade al `Dockerfile` un usuario sin privilegios y haz que la aplicación corra como él. Descubre
qué se rompe primero —permisos sobre `/application`, el fichero de entrada de Batch en `data/`— y
arréglalo. Comprueba con `docker exec inv-lab-inv-api-1 id`.
**Objetivo:** llegar al mismo resultado que los buildpacks dan de fábrica y entender por qué no es
una línea, sino tres decisiones.

#### 🟠 Ejercicio 13 — el token que deja de valer

Con `inv-api` dentro de Compose, cambia `INV_JWT_JWKSETURI` para que apunte a
`http://localhost:8180/...` y levanta. Diagnostica el fallo desde el log y di si el error es de
arranque o de la primera petición, y por qué.
**Objetivo:** distinguir un fallo de alcanzabilidad de red de un fallo de validación de emisor, que
dan códigos HTTP parecidos y tienen causas opuestas.

#### 🟠 Ejercicio 14 — el plazo de apagado, calibrado

Sube el retardo de `SLW-000002` en WireMock a 40 segundos y ajusta
`spring.lifecycle.timeout-per-shutdown-phase` y `stop_grace_period` para que una petición en vuelo
llegue a terminar. Demuestra con el log que aparece `Graceful shutdown complete` y no
`Graceful shutdown aborted with one or more requests still active`.
**Pregunta:** ¿cuál de los dos plazos subiste primero, y qué habría pasado subiendo solo el otro?

### 🔴 Muy difícil — abierto o adversarial  (15–16)

#### 🔴 Ejercicio 15 — la imagen que alguien te entrega rota

Te dan este `Dockerfile` y la queja es "los despliegues tardan cuatro minutos y al reiniciar se
pierden peticiones":

```dockerfile
FROM eclipse-temurin:21-jdk
ADD target/ /app/
WORKDIR /app
ENV SPRING_PROFILES_ACTIVE=prod
CMD java -jar $(ls *.jar | head -1)
```

Encuentra **los cinco problemas** —uno de ellos es el del apagado— y entrega la versión corregida
con una línea de justificación por cambio.
**Objetivo:** que cada defecto que encuentres se pueda amarrar a una sección concreta de este lab,
no a una intuición estética.

#### 🔴 Ejercicio 16 — limpiar la máquina de otro

Escribe `verificar-limpieza.sh` de forma que devuelva código de salida `0` cuando todo esté limpio
y distinto de `0` nombrando en la salida qué recurso sobró. Pruébalo con el sistema arriba (tiene
que fallar), después de `down -v` (tiene que fallar por las imágenes) y al final (tiene que pasar).
**Pregunta:** ¿por qué un guion que solo imprime contadores es peor que uno que devuelve código de
salida, si a simple vista dicen lo mismo?

### 🔥 Opcionales y ampliaciones

- **Compilación native con GraalVM.** `./mvnw -Pnative spring-boot:build-image` construye una
  imagen native con buildpacks. **Tarda del orden de varios minutos y consume varios GB de RAM**;
  el arranque resultante se mide en milisegundos en vez de en segundos. Mide las dos cosas —tiempo
  de build y tiempo de arranque— y decide con tus números si compensa para un servicio de banca que
  se despliega dos veces por semana. `L00` declaró esto como exclusión del lab base; aquí está su
  puerta.
- **Procesamiento AOT sobre la JVM.** `./mvnw -Pnative spring-boot:process-aot` sin llegar a
  compilar native genera el código AOT y `java -Dspring.aot.enabled=true -jar` lo usa. Es la mitad
  del beneficio por una fracción del costo.
- **Publicar la imagen.** `docker tag` y `docker push` a un registro propio, más
  `<publish>true</publish>` en el bloque `<image>` del plugin. Requiere credenciales, así que el lab
  no lo ejecuta.
- **Class Data Sharing.** Un *training run* con `-XX:ArchiveClassesAtExit` y
  `-Dspring.context.exit=onRefresh` dentro del `Dockerfile` recorta el arranque sin cambiar el
  código. Mide antes y después con la línea `Started InvApiApplication in ... seconds` del log.

### 💀 Boss fight — la serie entera, desde cero y hasta cero, sin abrir el IDE

Este no cierra el lab: cierra los nueve. Empiezas con la máquina limpia —los seis contadores de la
sección 8 en `0`— y terminas igual, y en medio tiene que pasar todo.

Escribe **un solo guion de bash**, `full-lab.sh`, que haga esto y falle con código distinto de `0`
en el primer paso que no se cumpla:

1. **Construye y levanta.** Empaqueta con `./mvnw clean package` —sin `-DskipTests`—, construye la
   imagen por capas y levanta los seis perfiles más `app`, esperando por `healthcheck` y no por
   `sleep` fijo.
2. **Recorre el curso con nueve aserciones**, una por lab, cada una comprobada con un comando y no
   con la vista: el informe de condiciones de `L01`; la precedencia de una variable de entorno sobre
   el fichero de `L02`; un `422` con `ProblemDetail` de `L03`; un rollback que **sí** ocurre de
   `L04`; el circuito abierto de `L05` en `/actuator/circuitbreakers`; dos `GET` con un solo acceso
   al repositorio de `L06`; `up{job="inv-api"}` valiendo `1` de `L07`; el trío `401`/`403`/`200` con
   su línea de log de `L08`; y el `Graceful shutdown complete` de hoy.
3. **Diagnostica tres fallos inyectados.** Antes de arrancar, el guion aplica tres sabotajes y los
   documenta en su salida: un puerto de servicio equivocado en una variable de entorno, un `COPY`
   del `Dockerfile` fuera de orden, y un `stop_grace_period` más corto que el timeout de Spring.
   Para cada uno tiene que imprimir **el síntoma exacto** que lo delata —el mensaje de error, el
   paso que deja de salir `CACHED`, el código `000` del cliente— antes de corregirlo y seguir.
4. **Destruye y demuestra.** Termina con `docker compose -p inv-lab down -v --remove-orphans`, el
   borrado de la imagen y de los directorios generados, y los seis contadores en `0` impresos en la
   salida. Si alguno no es `0`, sale con error y dice cuál.
5. **Sin IDE y sin intervención.** El guion se ejecuta entero con `bash full-lab.sh` y no pide nada
   por teclado. Lo único que puede recibir de fuera es la contraseña de los usuarios de Keycloak,
   por variable de entorno.

**Se entrega** el guion y una salida completa de una ejecución con éxito.
**Objetivo:** que la serie deje de ser nueve documentos y pase a ser una capacidad: levantar un
servicio Spring Boot completo, demostrar que cada mecanismo hace lo que promete, diagnosticar tres
fallos por su síntoma y devolver la máquina al estado en que la encontraste. Si puedes correr este
guion delante de alguien, puedes contar cualquiera de los nueve labs en una entrevista.

---

## 🏁 La señal de que quedó bien

`docker compose -p inv-lab ps -aq | wc -l` devuelve `0`. Y también los volúmenes, las redes, las
imágenes de `inv-api`, los puertos en escucha y los directorios generados: seis contadores, seis
ceros, impresos por un guion que puedes volver a correr mañana. Antes de eso, `inv-api` arrancó
como un servicio más dentro del mismo Compose que Postgres, Redis, WireMock, Prometheus, Grafana y
Keycloak, configurado enteramente por variables de entorno, y aguantó un `SIGTERM` con una petición
en vuelo dejando `Graceful shutdown complete` en el log en vez de un cliente sin respuesta.

Y lo que de verdad cuenta, que son las cuatro cosas que hoy pasaron de creencia a hecho comprobado.
**La primera:** el jar de Boot no es una caja negra — tiene un índice de capas que puedes listar, un
modo de herramientas que puedes ejecutar y un orden que puedes defender, y todo eso existe para que
un `Dockerfile` pueda escribir cuatro `COPY` que el caché de Docker entienda. **La segunda:** la
palabra `localhost` en un fichero de configuración no es un valor, es una suposición sobre dónde
corre el proceso; el día que esa suposición cambia, se rompen cuatro cosas a la vez y ninguna lo
dice con esas palabras. **La tercera:** el apagado ordenado no lo garantiza Spring solo, lo
garantizan tres plazos en tres ficheros distintos, y el que manda es el más corto — que además casi
nunca es el tuyo. **La cuarta, y es la que da nombre a la sección 8:** una limpieza sin verificación
no es una limpieza, es una intención; `down -v` no se lleva las imágenes, ni el caché de build, ni
los volúmenes del buildpack, ni los directorios de tu repositorio, y solo un contador que devuelve
`0` distingue "está limpio" de "creo que está limpio".

Si dudas de alguna de las cuatro, el criterio de verdad de este lab no es que la aplicación
responda: es que **deje de responder cuando tú lo decides y no quede rastro de ella**. Para el
empaquetado, `list-layers` junto a `docker history`. Para el arranque en Compose,
`/actuator/env` con su campo `origin` junto al target de Prometheus. Para el apagado, el
`%{http_code}` del cliente junto a las dos líneas de `GracefulShutdown`. Y para la limpieza, seis
contadores en cero.

Con esto la serie práctica está completa. `inv-api` nació en `L01` como un esqueleto que solo sabía
imprimir su informe de condiciones y termina aquí como una imagen que un orquestador puede arrancar,
observar y apagar sin perder una petición. Lo que queda del curso es de papel y de memoria: el
catálogo de anotaciones, la simulación de entrevista y la migración a 4.x. El laboratorio ya cumplió
su trabajo, y la prueba de que cumplió es que tu máquina no se acuerda de él.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — El formato del jar ejecutable y los jars anidados: https://docs.spring.io/spring-boot/3.5/specification/executable-jar/nested-jars.html
- Spring Boot 3.5 — Despliegues eficientes: extraer el jar con `-Djarmode=tools`: https://docs.spring.io/spring-boot/3.5/reference/packaging/efficient.html
- Spring Boot 3.5 — Imágenes de contenedor eficientes y capas: https://docs.spring.io/spring-boot/3.5/reference/packaging/container-images/index.html
- Spring Boot 3.5 — `Dockerfile` con `jarmode` y multi-stage: https://docs.spring.io/spring-boot/3.5/reference/packaging/container-images/dockerfiles.html
- Spring Boot 3.5 — Cloud Native Buildpacks: https://docs.spring.io/spring-boot/3.5/reference/packaging/container-images/cloud-native-buildpacks.html
- Spring Boot 3.5 — Maven plugin, empaquetado y configuración de capas (`layers`, `includeTools`): https://docs.spring.io/spring-boot/3.5/maven-plugin/packaging.html
- Spring Boot 3.5 — Maven plugin, `build-image`: el builder por defecto y las variables `BP_*`: https://docs.spring.io/spring-boot/3.5/maven-plugin/build-image.html
- Spring Boot 3.5 — Graceful shutdown y `spring.lifecycle.timeout-per-shutdown-phase`: https://docs.spring.io/spring-boot/3.5/reference/web/graceful-shutdown.html
- Spring Boot 3.5 — Javadoc de `Shutdown` (`GRACEFUL` e `IMMEDIATE`): https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/web/server/Shutdown.html
- Spring Boot 3.5 — Configuración externalizada y el binding relajado de variables de entorno: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html
- Spring Boot 3.5 — Profiles: https://docs.spring.io/spring-boot/3.5/reference/features/profiles.html
- Spring Boot 3.5 — Logging estructurado (`logging.structured.format.console`): https://docs.spring.io/spring-boot/3.5/reference/features/logging.html
- Spring Boot 3.5 — Índice de propiedades (`server.shutdown`, `spring.lifecycle.*`, `logging.structured.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Boot 3.5 — Class Data Sharing: https://docs.spring.io/spring-boot/3.5/reference/packaging/class-data-sharing.html
- Spring Boot 3.5 — Procesamiento AOT sobre la JVM: https://docs.spring.io/spring-boot/3.5/reference/packaging/aot.html
- Spring Boot 3.5 — Imágenes native de GraalVM: https://docs.spring.io/spring-boot/3.5/reference/packaging/native-image/introducing-graalvm-native-images.html
- Spring Boot 3.5 — Endpoints de Actuator y su exposición: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Security 6.5 — Resource Server con JWT: `NimbusJwtDecoder`, validadores y `jwk-set-uri`: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/jwt.html

### Documentación de terceros

- Docker — referencia del `Dockerfile` (`COPY`, `ARG`, `ENTRYPOINT`, formas exec y shell): https://docs.docker.com/reference/dockerfile/
- Docker — builds multi-stage: https://docs.docker.com/build/building/multi-stage/
- Docker — referencia del fichero de Compose (servicios, `depends_on`, `stop_grace_period`): https://docs.docker.com/reference/compose-file/services/
- Docker — perfiles de Compose: https://docs.docker.com/compose/how-tos/profiles/
- Docker — `docker compose down` y la bandera `-v`: https://docs.docker.com/reference/cli/docker/compose/down/
- Docker — `docker image prune`: https://docs.docker.com/reference/cli/docker/image/prune/
- Docker — `docker volume prune`: https://docs.docker.com/reference/cli/docker/volume/prune/
- Docker — `docker buildx prune` (el caché de build que `down -v` no toca): https://docs.docker.com/reference/cli/docker/buildx/prune/
- Docker — `docker stop` y la secuencia `SIGTERM` → `SIGKILL`: https://docs.docker.com/reference/cli/docker/container/stop/
- Cloud Native Buildpacks — conceptos para desarrolladores de aplicaciones: https://buildpacks.io/docs/for-app-developers/concepts/
- Paketo Buildpacks — configurar una aplicación Java (`BP_JVM_VERSION` y compañía): https://paketo.io/docs/howto/java/
