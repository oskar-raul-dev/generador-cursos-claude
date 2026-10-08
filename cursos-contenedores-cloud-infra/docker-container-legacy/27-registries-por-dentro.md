# 🧱 Parte II · Fase 27 — Registries por dentro: manifests, digests y blobs

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F12](12-capas-cache-y-contexto.md)** (capas y digests) y **[F21](21-arquitecturas-y-emulacion.md)** (image index)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — Docker 29.6.2 con image store de containerd, sobre macOS Apple Silicon. **Todos los digests de esta fase son reales y salen de los comandos que la acompañan**
> **Estado de la imagen al terminar:** sin cambios — esta fase disecciona, la siguiente publica
> **Objetivo:** entender qué es exactamente un registry, qué son manifests, indexes, descriptors y blobs, y por qué un digest es identidad de contenido y un tag no

---

## 1. 🧭 Dónde estamos

[F12](12-capas-cache-y-contexto.md) te dijo que un tag es un puntero y un digest es identidad de contenido. [F21](21-arquitecturas-y-emulacion.md) te enseñó que un
tag puede apuntar a varias imágenes a la vez. Las dos afirmaciones eran ciertas y ninguna
explicaba el mecanismo.

Esta fase abre el registry. Y sigue el criterio que la propuesta del curso fija: **un registry
se entiende con uno solo bien diseccionado** — manifest, index, descriptor, blob, digest—. Los
cinco productos comerciales son cobertura de catálogo y viven en apéndices.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué es un registry y en qué se diferencia de un repositorio Git.
- Descomponer un nombre de imagen completo y saber qué valores se ocultan por defecto.
- Nombrar las cuatro estructuras del formato OCI y decir qué contiene cada una.
- Explicar por qué hay **cuatro digests distintos** y cuál usar para cada cosa.
- Hacer `pull` por digest y entender qué garantiza.
- Inspeccionar una imagen remota **sin descargarla**.

---

## 3. 🚧 Qué NO entra todavía

- **Publicar de verdad**: tags, autenticación, Docker Hub, multi-plataforma → **[F28](28-publicar-la-imagen.md)**.
- **SBOM, provenance y firma** → **[F29](29-supply-chain-sbom-firma.md)**.
- **GHCR y GitLab** → **[a11](a11-ghcr-y-gitlab.md)**; **Harbor** → **[a12](a12-harbor.md)**; **air-gapped** → **[a13](a13-air-gapped.md)**; **CI** →
  **[a14](a14-ci-github-actions.md)**.

---

## 4. 🏪 Qué es un registry

**Un registry no es un repositorio Git.** La confusión es frecuente y lleva a esperar cosas que
no existen.

| | Git | Registry |
|---|---|---|
| Qué guarda | historial de cambios de texto | **artefactos binarios** ya construidos |
| Unidad | commit | **blob** direccionado por contenido |
| Historia | completa, con ramas y merges | **ninguna**: no hay "commit anterior" |
| Diffs | sí, es su razón de ser | no: las capas son diffs, pero el registry no los calcula |
| Identidad | hash del commit | hash del contenido, el **digest** |

Un registry es, esencialmente, **un almacén de blobs con un índice**. Guarda trozos de datos
identificados por su hash, y unos documentos JSON que dicen cómo se combinan.

### 4.1 Registry, repository y tag

Los tres se confunden constantemente:

```text
docker.io / biblioteca / debian / eol : buster
    │           │                      │
  REGISTRY   NAMESPACE + REPOSITORY   TAG
  el servidor  el "nombre" del proyecto  una versión con nombre
```

Un **registry** aloja muchos **repositories**, y cada repository tiene muchos **tags** —y muchas
imágenes sin tag, a las que solo se llega por digest—.

### 4.2 Registry frente a almacén local

```text
REGISTRY              ALMACÉN LOCAL
remoto, compartido    tu máquina, tuyo
docker push / pull    docker build / images
formato OCI           formato del motor (F24 §9)
```

Son cosas distintas, y por eso `docker images` no muestra lo que hay en un registry, y por eso
[F24](24-docker-y-podman-arquitectura.md) §9 explicaba que Docker y Podman tienen almacenes que no se ven entre sí.

### 4.3 El nombre completo, y lo que se oculta

```bash
docker pull debian/eol:buster
```

Ese comando corto esconde tres cosas:

```text
lo que escribes    →  debian/eol:buster
lo que significa   →  docker.io/debian/eol:buster
                      │         │
                      │         └── namespace/repository
                      └── el registry por defecto
```

Y con imágenes oficiales el atajo es aún mayor:

```text
docker pull debian          →  docker.io/library/debian:latest
                                          │       │
                                          │       └── tag por defecto
                                          └── namespace por defecto de las oficiales
```

> ⚠️ **Tres valores por defecto invisibles: registry, namespace y tag.** En un laboratorio no
> importa; en un `Dockerfile` de un proyecto real sí, porque `FROM node` y
> `FROM docker.io/library/node:latest` son lo mismo hoy y podrían no serlo con otra
> configuración de registry por defecto. **Escribe el nombre completo cuando importe.**

---

## 5. 🧩 Las cuatro estructuras del formato OCI

Aquí está el mecanismo. Una imagen no es un archivo: es un pequeño grafo.

```mermaid
flowchart LR
    I["IMAGE INDEX<br/>opcional: solo si es multi-plataforma"]
    I -- "para amd64" --> MA["MANIFEST (amd64)"]
    I -- "para arm64" --> MR["MANIFEST (arm64)"]
    MA -- "config" --> CB["CONFIG BLOB<br/>Env, Cmd, Entrypoint, arquitectura…"]
    MA -- "layers" --> L1["LAYER BLOB 1<br/>un tar.gz con un diff de filesystem"]
    MA -- "layers" --> L2["LAYER BLOB 2"]
    MA -- "layers" --> L3["LAYER BLOB 3"]
    MR --> O["… sus propios blobs"]
```

**Blob** — un trozo de datos opaco, identificado por el hash de su contenido. Las capas son
blobs y el config también.

**Descriptor** — la pieza que conecta todo. Es un objeto pequeño con tres campos:

```json
{
  "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
  "digest": "sha256:2dbcb4dd7920eeb6aedc75d4f8b42b4f5ae95d69a784e2f9ae627e9fff357dbd",
  "size": 49667821
}
```

Qué tipo de cosa es, cuál es su hash, y cuánto ocupa. Ese no es un ejemplo inventado: es el
descriptor de **la única capa** de `debian/eol:buster` en `amd64`, y lo vas a ver salir de tu
terminal dentro de dos párrafos. **Todo el grafo está hecho de descriptores**, y es lo que
permite verificar cada pieza al descargarla.

**Manifest** — el documento que describe **una** imagen para **una** plataforma: un descriptor
al config y una lista de descriptores a las capas.

**Image index** — el documento que agrupa varios manifests, uno por plataforma. Es lo que [F21](21-arquitecturas-y-emulacion.md) §5
llamaba "un tag, varias imágenes".

### 5.1 Míralo de verdad

Nada de esto hay que creérselo. El index de nuestra imagen base está a un comando de distancia:

```bash
docker manifest inspect debian/eol:buster
```

```text
{
   "schemaVersion": 2,
   "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
   "manifests": [
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 428,
         "digest": "sha256:b498ff6ee3df44fe36e0d8496c552d967c72f7026216aa656a1b9c46b6d2aef1",
         "platform": {
            "architecture": "amd64",
            "os": "linux"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 428,
         "digest": "sha256:194625c3e4b9a790148e499756217fcc56761adb376ad6c6003f9db82c1344ea",
         "platform": {
            "architecture": "arm64",
            "os": "linux",
            "variant": "v8"
         }
      },
      ... y seis plataformas más: arm/v5, arm/v7, 386, mips64le, ppc64le y s390x
   ]
}
```

Ocho entradas, ocho digests distintos, **un solo tag**. Fíjate en el `size: 428`: eso es lo que
ocupa el *documento* manifest de amd64, no la imagen. El index es un índice; las capas están en
otro sitio.

Ahora baja un nivel. Coge el digest de `amd64` y pídelo:

```bash
docker manifest inspect \
  debian/eol@sha256:b498ff6ee3df44fe36e0d8496c552d967c72f7026216aa656a1b9c46b6d2aef1
```

```text
{
	"schemaVersion": 2,
	"mediaType": "application/vnd.docker.distribution.manifest.v2+json",
	"config": {
		"mediaType": "application/vnd.docker.container.image.v1+json",
		"size": 570,
		"digest": "sha256:cac7535a050e7f654c4e064be6f41943743ac6d9de9f75c49eb0d013cf280268"
	},
	"layers": [
		{
			"mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
			"size": 49667821,
			"digest": "sha256:2dbcb4dd7920eeb6aedc75d4f8b42b4f5ae95d69a784e2f9ae627e9fff357dbd"
		}
	]
}
```

Ahí está el grafo entero de nuestra imagen base, y cabe en pantalla: **un config blob de 570
bytes y una única capa de 49.667.821**. Los ~47 MiB comprimidos de esa capa son el rootfs de
Debian 10 completo, y por eso la imagen "pesa 182 MB" descomprimida y se descarga en menos.

Cada `digest` que ves es un `sha256:` que **identifica el contenido**. Si el contenido cambia
un bit, el digest cambia entero — y por eso es verificable.

> 📝 **Nota de época.** Los `mediaType` dicen `docker.distribution` y no `oci`, porque esta
> imagen se publicó con el formato de manifest de Docker v2 en lugar del de OCI. Son formatos
> hermanos, campo por campo casi idénticos, y los registries entienden los dos. No te
> desconcierte: el modelo que acabas de leer es el mismo.

---

## 6. 🔐 Cuatro digests, no uno

Es la parte que más confunde: **no existe "el digest" de una imagen**. Existen varios, en
niveles distintos del grafo.

| Digest | De qué es hash | Para qué sirve |
|---|---|---|
| **Layer digest** | de cada blob de capa | verificar cada descarga; compartir capas entre imágenes |
| **Config digest** | del blob de configuración | históricamente, el **Image ID** local |
| **Manifest digest** | del documento manifest | identifica **una** imagen de **una** plataforma |
| **Index digest** | del documento index | identifica **el conjunto** multi-plataforma |

Los cuatro de nuestra imagen base, sacados de los comandos de §5.1 y de uno más que ahora
verás, son estos:

```text
index     sha256:3207f48cbea2d8c398c1ecd43ba351c8cad5b2a3676cd365f5e144d51ff39650
manifest  sha256:b498ff6ee3df44fe36e0d8496c552d967c72f7026216aa656a1b9c46b6d2aef1   (amd64)
config    sha256:cac7535a050e7f654c4e064be6f41943743ac6d9de9f75c49eb0d013cf280268
layer     sha256:2dbcb4dd7920eeb6aedc75d4f8b42b4f5ae95d69a784e2f9ae627e9fff357dbd
```

Cuatro hashes, cuatro cosas distintas, una sola imagen. Ninguno se parece a otro, y esa es
exactamente la lección: **no existe "el digest" de `debian/eol:buster`**; existe el digest de
*qué* de `debian/eol:buster`.

### 6.1 Y por eso el `IMAGE ID` local no coincide con el digest del registry

No es un bug ni una inconsistencia: **son hashes de cosas distintas**. Es la confusión número
uno de esta fase. Compruébalo sobre la imagen base, que ya tienes descargada:

```bash
docker image inspect debian/eol:buster --format 'Id          : {{.Id}}'
docker image inspect debian/eol:buster --format 'RepoDigests : {{.RepoDigests}}'
docker image inspect debian/eol:buster | jq '.[0].Descriptor'
```

```text
Id          : sha256:3207f48cbea2d8c398c1ecd43ba351c8cad5b2a3676cd365f5e144d51ff39650
RepoDigests : [debian/eol@sha256:3207f48cbea2d8c398c1ecd43ba351c8cad5b2a3676cd365f5e144d51ff39650]
{
  "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
  "digest": "sha256:3207f48cbea2d8c398c1ecd43ba351c8cad5b2a3676cd365f5e144d51ff39650",
  "size": 1845
}
```

Y aquí hay que ser honesto con lo que la máquina dice, porque **contradice lo que casi toda la
documentación repite**: ese `Id` no es el config digest (`cac7535a…`). Es el **index digest**,
y el propio `Descriptor` lo delata con su `mediaType: …manifest.list.v2+json`.

📝 **Qué pasó aquí.** La regla clásica —`Image ID` = config digest— es cierta para el
almacenamiento *antiguo* de Docker, el de los graph drivers. Las versiones recientes de Docker
Desktop traen por defecto el **image store de containerd**, que guarda la imagen tal como viene
del registry: como un grafo con su index arriba. Con ese almacén, `Id` y `RepoDigests` pasan a
ser lo mismo, y lo que muestran es el digest de más arriba del grafo.

> 🩺 **Cómo saber cuál tienes.** `docker info --format '{{.DriverStatus}}'`. Si responde algo
> con `io.containerd.snapshotter`, estás en el almacén nuevo y verás lo de arriba. Si responde
> `overlay2` a secas, estás en el clásico y tu `Image ID` sí será el config digest.

Lo llamativo es que ocurre **también con una imagen tuya de una sola plataforma**. Sobre la
imagen del laboratorio, recién construida y sin publicar en ningún sitio:

```text
Id          : sha256:8180022ddefd161895041d79457e080dc30ae79cccbd8bb933b1dd359a3da38a
Descriptor  : { "mediaType": "application/vnd.oci.image.index.v1+json",
                "digest":    "sha256:8180022ddefd…", "size": 856 }
```

BuildKit envuelve en un index **hasta la imagen de una sola arquitectura**. Un index de una
entrada sigue siendo un index. 😉

> 🧠 **El modelo mental que sobrevive a los cambios de almacén.** No memorices "el Image ID es
> el config digest". Memoriza el grafo —index → manifest → config + capas— y luego **pregúntale
> a `.Descriptor` de qué nivel te está hablando tu Docker**. El grafo es del formato OCI y no
> cambia; qué nivel te enseña la herramienta, sí.

### 6.2 Tag frente a digest, otra vez y en serio

```bash
docker pull debian/eol:buster                    # por TAG    → mutable
docker pull debian/eol@sha256:3207f48cbea2...    # por DIGEST → inmutable
```

**Un tag puede reapuntarse.** Quien controla el repositorio puede hacer que `:buster` apunte
mañana a otra imagen, y tu `docker pull` traería algo distinto sin avisar.

**Un digest no.** Si te devuelven contenido con ese hash, es exactamente el mismo contenido. Y
si no lo es, la verificación falla.

```dockerfile
FROM debian/eol:buster                     # legible · confía en el tag
FROM debian/eol@sha256:3207f48cbea2…       # inmutable · ilegible
```

> 🧭 **Cuándo usar cada uno**, cerrando la deuda 💸 que [F12](12-capas-cache-y-contexto.md) §7 declaró: **tag** en un
> laboratorio local donde la legibilidad gana y el tag es de archivo. **Digest** en cualquier
> cosa que publiques, en un pipeline, o cuando necesites poder demostrar qué se construyó
> exactamente. La práctica habitual es fijar por digest y dejar el tag en un comentario al
> lado.

### 6.3 Rollback de verdad

```bash
# guarda el digest de lo que funcionaba
docker inspect --format '{{index .RepoDigests 0}}' miapp:v1.2.3

# y vuelve a él cuando haga falta
docker pull registro.ejemplo/miapp@sha256:...
```

> ⚠️ **"Reconstruir la misma versión" NO es rollback.** Reconstruir desde el mismo commit
> produce una imagen **funcionalmente parecida** y no idéntica: cambian timestamps, y las
> fuentes externas —paquetes, tarballs, el registry de npm— pueden haber cambiado. Es [F12](12-capas-cache-y-contexto.md) §9
> otra vez. **El único rollback real es volver al digest.**

---

## 7. 🚚 El protocolo: OCI Distribution

La tercera especificación de OCI define **cómo se habla con un registry**, y es más simple de lo
que parece: una API HTTP con unos pocos endpoints.

```text
GET  /v2/                                       ← ¿hablas OCI? ¿necesito autenticarme?
GET  /v2/<repo>/manifests/<tag-o-digest>        ← dame el manifest o el index
GET  /v2/<repo>/blobs/<digest>                  ← dame este blob
PUT  /v2/<repo>/manifests/<tag>                 ← publica este manifest
POST /v2/<repo>/blobs/uploads/                  ← empieza a subir un blob
```

**Qué hace un `docker pull`, paso a paso:**

```text
1. GET /v2/                      → ¿autenticación?
2. GET .../manifests/buster      → recibe el INDEX
3. elige la entrada de su plataforma
4. GET .../manifests/<digest>    → recibe el MANIFEST de esa plataforma
5. GET .../blobs/<config>        → recibe el config
6. GET .../blobs/<capa>          → una petición por capa que NO tenga ya
7. verifica cada blob contra su digest
```

**El paso 6 explica por qué un `pull` a veces es instantáneo:** si ya tienes esas capas de otra
imagen, no se descargan. Las capas se comparten entre imágenes **porque están direccionadas por
contenido**, y eso es una consecuencia directa del diseño.

Puedes hablar con el protocolo a mano:

```bash
# el registry público de Docker Hub necesita un token, incluso para lo público
token=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/debian:pull" | jq -r .token)

curl -s -H "Authorization: Bearer $token" \
     -H "Accept: application/vnd.oci.image.index.v1+json" \
     https://registry-1.docker.io/v2/library/debian/manifests/bookworm | jq '.manifests[].platform'
```

> 💡 **Hacerlo una vez a mano cambia cómo lees el resto.** Un registry deja de ser un servicio
> misterioso y pasa a ser lo que es: un servidor HTTP que devuelve JSON y archivos.

---

## 8. 🕵️ Inspección remota sin descargar: Skopeo

`docker manifest inspect` sirve para lo básico. **Skopeo** es la herramienta que hace esto en
serio, y su gracia es que **no necesita un motor de contenedores corriendo**.

```bash
# qué plataformas tiene, sin descargar nada
skopeo inspect --raw docker://docker.io/debian/eol:buster | jq '.manifests[].platform'

# la configuración de una imagen concreta
skopeo inspect docker://docker.io/debian/eol:buster | jq '{Digest, Architecture, Os, Created, Labels}'

# qué tags tiene un repositorio
skopeo list-tags docker://docker.io/debian/eol | jq '.Tags[:20]'

# copiar entre registries sin pasar por tu disco
skopeo copy docker://origen/imagen:tag docker://destino/imagen:tag
```

**Por qué importa para este curso:**

- **Averiguar si una imagen tiene tu arquitectura antes de descargar 1 GB.**
- **Ver la fecha de creación y los labels** de una imagen ajena antes de confiar en ella.
- **Copiar entre registries** sin `pull` y `push`, que en air-gapped es la diferencia entre
  posible e imposible — **[a13](a13-air-gapped.md)**.

---

## 9. ⚠️ Errores comunes y diagnóstico

**"El `IMAGE ID` no coincide con el digest del registry."** Son hashes de cosas distintas. §6.

**`manifest unknown`.** Ese tag no existe en ese repositorio, o el nombre está incompleto. §4.3.

**`docker pull` trae una imagen distinta a la de ayer, con el mismo tag.** El tag se reapuntó.
Es exactamente lo que §6.1 previene.

**`no matching manifest for linux/arm64`.** Esa imagen no publicó tu plataforma. Compruébalo con
Skopeo antes de intentar el pull.

**"Publiqué y `docker images` no muestra el digest."** El `RepoDigest` aparece tras el push, no
tras el build.

**`unauthorized` al inspeccionar algo público.** Docker Hub exige token incluso para lo público.
§7.

**Un `pull` tarda muchísimo y otro es instantáneo.** Capas compartidas. §7, paso 6.

---

## 10. 📋 Checklist de validación

```text
[ ] Puedes descomponer un nombre completo y decir los tres valores por defecto
[ ] Sabes qué son blob, descriptor, manifest e index
[ ] Explicaste por qué hay cuatro digests y para qué sirve cada uno
[ ] Sabes por qué el IMAGE ID no coincide con el digest del registry
[ ] Hiciste un pull por digest
[ ] Hablaste con el protocolo Distribution usando curl
[ ] Inspeccionaste una imagen remota con Skopeo sin descargarla
[ ] Sabes por qué reconstruir no es rollback
```

---

## 11. 🧪 Ejercicios de la Fase 27 (24)

## 🟢 Fácil — el vocabulario del registry (1–6)

### 🟢 Ejercicio 1 — Descompón cinco nombres

Escribe el nombre completo de: `debian`, `node:10`, `debian/eol:buster`,
`ghcr.io/usuario/app:v1` y `localhost:5000/miapp`.

**Objetivo:** identificar registry, namespace, repository y tag en cada uno, y qué se rellenó por
defecto.

### 🟢 Ejercicio 2 — El index

Ejecuta el primer comando de §5.1 sobre tres imágenes distintas.

**Pregunta:** ¿todas tienen index? ¿Qué pasa con una que solo tenga una plataforma?

### 🟢 Ejercicio 3 — Los descriptores

Con `jq`, extrae los tres campos de un descriptor de una capa.

**Objetivo:** ver `mediaType`, `digest` y `size` en una salida real.

### 🟢 Ejercicio 4 — Pull por digest

Haz `pull` de una imagen por tag, anota su digest, y vuelve a hacerlo por digest.

**Pregunta:** ¿descargó algo la segunda vez? ¿Por qué?

### 🟢 Ejercicio 5 — Los tags de un repositorio

Ejecuta `skopeo list-tags` sobre `debian/eol`.

**Pregunta:** ¿cuántas releases EOL hay publicadas? ¿Está Stretch?

### 🟢 Ejercicio 6 — Qué almacén tiene tu Docker

§6.1 dice que el `IMAGE ID` significa cosas distintas según cómo guarde las imágenes tu motor,
y que hay una forma de saberlo. Úsala:

```bash
docker info --format '{{.Driver}} · {{.DriverStatus}}'
docker image inspect debian/eol:buster | jq '.[0].Descriptor.mediaType'
```

**Objetivo:** decir cuál de los dos almacenes tienes y qué `mediaType` te devuelve el
descriptor: un `manifest.list` o `image.index` significa almacén de containerd; un
`image.v1+json` significa el clásico.

**Pregunta:** con esa respuesta en la mano, mira el `Id` de tres imágenes tuyas y di, para cada
una, **de qué documento es hash**. Y la comprobación que cierra el círculo: ¿coincide alguno de
esos `Id` con alguno de los cuatro digests que §6 lista para `debian/eol:buster`? Si sí, di
cuál y por qué es ese y no otro.

## 🟡 Intermedio — hablar con el registry (7–14)

### 🟡 Ejercicio 7 — Los cuatro digests

Localiza los cuatro de §6 para una imagen que tengas publicada o para una pública.

**Objetivo:** la tabla comprobada, con los hashes reales delante.

### 🟡 Ejercicio 8 — Skopeo sin descargar

Instala Skopeo e inspecciona tres imágenes grandes sin hacer `pull`.

**Pregunta:** ¿cuánto habrías descargado para averiguar lo mismo con `docker pull`?

### 🟡 Ejercicio 9 — Habla con el registry a mano

Ejecuta la secuencia de `curl` de §7.

**Objetivo:** obtener un index en JSON sin usar la CLI de Docker.

### 🟡 Ejercicio 10 — Baja un blob

Continuando el ejercicio 9, descarga un blob de capa con `curl` y comprueba su hash con
`sha256sum`.

**Objetivo:** verificar tú mismo lo que el motor verifica en cada `pull`.

### 🟡 Ejercicio 11 — Capas compartidas

Descarga dos imágenes que compartan base y observa las líneas de `Already exists`.

**Pregunta:** ¿cuántas capas se descargaron de verdad la segunda vez?

### 🟡 Ejercicio 12 — Un registry local

Arranca `registry:2` en un contenedor, publica tu imagen y explora su API con `curl`.

**Objetivo:** ver los endpoints de §7 contra un registry tuyo, donde puedes mirar el disco.

### 🟡 Ejercicio 13 — Mira el disco del registry

Con el registry local corriendo, entra en su contenedor y explora dónde guarda los blobs.

**Objetivo:** ver que un registry es, literalmente, un directorio de archivos nombrados por su
hash.

### 🟡 Ejercicio 14 — El `Content-Type` decide qué te dan

El registry no adivina si quieres el index o un manifest concreto: se lo dices tú en la
cabecera `Accept`. Compruébalo pidiendo lo mismo de dos formas:

```bash
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:debian/eol:pull" | jq -r .token)

# sin Accept explícito
curl -sI -H "Authorization: Bearer $TOKEN" \
  https://registry-1.docker.io/v2/debian/eol/manifests/buster | grep -i content-type

# pidiendo el index
curl -sI -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" \
  https://registry-1.docker.io/v2/debian/eol/manifests/buster | grep -i 'content-type\|docker-content-digest'
```

**Pregunta:** ¿qué te devuelve cada uno? Fíjate en la cabecera `Docker-Content-Digest`: compárala
con el index digest de §6. ¿Coincide?

**Objetivo:** entender que **el mismo tag devuelve documentos distintos según lo que pidas**, y
que por eso un cliente viejo que no sabe pedir listas recibe un manifest suelto. Es
retrocompatibilidad, y explica por qué el formato tiene dos `mediaType` para lo mismo.

## 🟠 Difícil — verificar y diagnosticar (15–20)

### 🟠 Ejercicio 15 — Pin por digest

Cambia el `FROM` del canónico para fijar `debian/eol:buster` por digest y construye.

**Pregunta:** ¿qué ganaste? ¿Cómo lo mantendrías legible? Compáralo con la práctica del
comentario al lado.

### 🟠 Ejercicio 16 — Copia entre registries

Con dos registries locales, copia una imagen de uno a otro con `skopeo copy`.

**Pregunta:** ¿pasó por tu almacén local? Compruébalo con `docker images`.

### 🟠 Ejercicio 17 — El tag que se movió

Con tu registry local, publica una imagen como `:v1`, publica otra distinta con el mismo tag, y
comprueba qué pasa con el digest anterior.

**Pregunta:** ¿sigue accesible por digest? ¿Qué implica eso para un rollback y para [F13](13-overlayfs-y-copy-on-write.md) §12?

### 🟠 Ejercicio 18 — Reconstruir no es rollback

Construye una imagen, publícala, y reconstruye desde el mismo Dockerfile sin cambios.

**Pregunta:** ¿mismo digest? Si no, ¿qué cambió? Es [F12](12-capas-cache-y-contexto.md) §9 con la prueba del registry.

### 🟠 Ejercicio 19 — La imagen sin tu plataforma

Encuentra una imagen pública sin `linux/arm64` e intenta usarla en ARM.

**Objetivo:** obtener el `no matching manifest`, y haber podido predecirlo con Skopeo antes.

### 🟠 Ejercicio 20 — Verifica un digest a mano

"El digest es el hash del contenido" es una afirmación comprobable. Compruébala. Descarga un
manifest crudo y calcula tú su SHA-256:

```bash
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:debian/eol:pull" | jq -r .token)
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  https://registry-1.docker.io/v2/debian/eol/manifests/sha256:b498ff6ee3df44fe36e0d8496c552d967c72f7026216aa656a1b9c46b6d2aef1 \
  -o manifest.json
sha256sum manifest.json
```

**Objetivo:** que tu `sha256sum` dé exactamente `b498ff6e…`. Si no da, **no reformatees el
JSON**: ahí está la lección.

**Pregunta:** pasa el archivo por `jq .` y vuelve a calcular el hash. ¿Cambió? Explica por qué,
y qué implica eso para cualquier herramienta que "solo" reindente un manifest antes de
guardarlo. El digest es del **byte exacto**, no del JSON conceptual, y esa distinción es la que
hace que la verificación funcione.

## 🔴 Muy difícil — política de identidad (21–24)

### 🔴 Ejercicio 21 — Audita una imagen ajena

Elige una imagen popular y, **sin descargarla**, averigua: plataformas, fecha de creación,
labels, número de capas y tamaño total.

**Objetivo:** un informe de cinco líneas usando solo Skopeo. Es lo que harías antes de meter una
imagen ajena en tu pipeline.

### 🔴 Ejercicio 22 — Explica los cuatro digests sin la tabla

Escribe la explicación que le darías a alguien que pregunta por qué `docker images` muestra un
hash y el registry muestra otro.

**Objetivo:** que quepa en un párrafo, que no use la palabra "hash" más de dos veces, y que
termine diciendo **cuál de los dos debe guardar** si quiere poder volver a esa imagen exacta.

### 🔴 Ejercicio 23 — La política de pinning de tu equipo

Decide cómo vais a referenciar imágenes: en el `Dockerfile`, en Compose, en el CI y en la
documentación.

**Objetivo:** una política con su justificación por contexto, que reconozca el coste de
legibilidad del digest y diga cómo lo mitigáis. "Siempre digest" y "siempre tag" son las dos
respuestas fáciles y las dos son malas.

### 🔴 Ejercicio 24 — El pin por digest, hasta el final

§6.2 dice que la práctica habitual es fijar por digest y dejar el tag en un comentario.
Hazlo de verdad en el laboratorio y vive con las consecuencias.

**Objetivo:** cambiar el `FROM` del `Dockerfile` canónico a
`FROM debian/eol@sha256:3207f48c…` con el tag en un comentario al lado, construir, y comprobar
que la imagen sale idéntica. Después responde a las tres preguntas que el pin abre y que nadie
cuenta:

**(1)** El digest que fijas, ¿es el del index o el de una plataforma? Prueba los dos y mira qué
pasa al construir con `--platform linux/arm64` en cada caso. Uno de los dos rompe la
construcción multi-plataforma: di cuál y por qué.
**(2)** ¿Cómo se actualiza? Escribe el procedimiento —el comando que averigua el digest nuevo y
cómo sabrías que hay uno nuevo—, porque un pin sin procedimiento de actualización es un pin
que nadie tocará en tres años.
**(3)** ¿Qué pierdes? Enséñale el `Dockerfile` a alguien y pídele que diga de qué distribución
parte.

**Pregunta de cierre:** con las tres respuestas, decide si el curso debería pinnear por digest
o quedarse como está, y **defiéndelo** contra la 💸 que [F12](12-capas-cache-y-contexto.md) §7
declaró. Cualquiera de las dos respuestas vale si trae los tres puntos detrás.

## 🔥 Opcionales

### 🔥 Ejercicio 25 — Lee la Distribution Spec

Lee la especificación y localiza el endpoint de subida por partes.

**Pregunta:** ¿por qué un `push` de una capa de 500 MB no es una sola petición?

### 🔥 Ejercicio 26 — Un `pull` implementado a mano

Escribe un script que, dado un nombre de imagen, descargue su manifest y todas sus capas con
`curl`, verificando cada digest.

**Objetivo:** implementar el §7 entero. Cuando funcione, un `docker pull` deja de ser una caja
negra para siempre.

## 💀 Boss fight

### 💀 Ejercicio 27 — Boss fight: la imagen que cambió debajo

Un pipeline que funcionaba lleva dos semanas fallando de forma intermitente. Nadie ha tocado el
`Dockerfile`. La imagen base se referencia por tag.

**Objetivo:** demostrar con evidencia del registry que la base cambió: encontrar el digest que se
usaba antes, el que se usa ahora, y **qué difiere entre los dos** —usando Skopeo y las
herramientas de esta fase, sin descargar las dos imágenes enteras si puedes evitarlo—. Después,
propón la corrección **y** la comprobación que habría detectado esto el primer día. La parte que
convence al equipo no es el arreglo: es poder mostrar los dos digests con sus fechas.

---

## 12. 📚 Referencias

**OCI**
- Distribution Specification: https://github.com/opencontainers/distribution-spec/blob/main/spec.md
- Image Specification: https://github.com/opencontainers/image-spec
- Descriptor: https://github.com/opencontainers/image-spec/blob/main/descriptor.md
- Manifest: https://github.com/opencontainers/image-spec/blob/main/manifest.md
- Image Index: https://github.com/opencontainers/image-spec/blob/main/image-index.md

**Herramientas**
- Skopeo: https://github.com/containers/skopeo
- `docker manifest`: https://docs.docker.com/reference/cli/docker-manifest/
- Registry de referencia: https://distribution.github.io/distribution/

> ⚠️ **Las especificaciones OCI son inusualmente legibles.** No son un manual de producto: son
> documentos cortos que describen estructuras de datos. La de *Descriptor* cabe en dos pantallas
> y explica la mitad de esta fase.

**Orden de lectura sugerido:** *Descriptor* primero, después *Manifest*, después *Image Index*.
En ese orden se construye el grafo de §5 solo.

---

## 13. 🏁 Resultado de la fase

```text
UN REGISTRY     no es Git: es un almacén de blobs con un índice
                sin historia, sin diffs, con identidad por contenido
                registry / namespace / repository : tag — tres defaults invisibles

EL GRAFO OCI    INDEX → MANIFEST(es) → CONFIG BLOB + LAYER BLOBS
                todo unido por DESCRIPTORES: mediaType + digest + size

CUATRO DIGESTS  layer   verificar cada blob y compartirlo entre imágenes
                config  el IMAGE ID que ves en docker images
                manifest identifica UNA imagen de UNA plataforma
                index   identifica el conjunto multi-plataforma
                → por eso el IMAGE ID no coincide con el digest del registry

TAG ≠ DIGEST    el tag se reapunta; el digest no
                y reconstruir NO es rollback: volver al digest sí

EL PROTOCOLO    HTTP con cinco endpoints
                un pull baja solo las capas que no tienes
                Skopeo inspecciona y copia sin descargar
```

> **La señal de que quedó bien:** *"cuando alguien dice 'la imagen es la misma', pregunto por el
> digest — y sé cuál de los cuatro me tiene que dar."*

En **[F28](28-publicar-la-imagen.md)** usamos todo esto para publicar de verdad: tags con criterio, registry local,
autenticación sin filtrar credenciales, y publicación multi-plataforma.
