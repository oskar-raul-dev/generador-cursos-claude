# 🚀 Parte II · Fase 28 — Publicar la imagen: tags, registry local y autenticación

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64` y `linux/arm64`
> **Requisitos:** **[F27](27-registries-por-dentro.md)** (registries por dentro) y **[F21](21-arquitecturas-y-emulacion.md)** (multi-plataforma)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Estado de la imagen al terminar:** publicada, con metadata OCI y una convención de tags defendible
> **Objetivo:** publicar de verdad — empezando por un registry local, con tags que signifiquen algo y sin filtrar credenciales por el camino

---

## 1. 🧭 Dónde estamos

[F27](27-registries-por-dentro.md) abrió el registry. Esta fase lo usa.

Y sigue el orden que el curso aplica siempre: **primero local, después Internet**. Un registry
en tu máquina te deja ver el disco, romper cosas y entender qué pasa en un `push`, sin
credenciales de por medio y sin publicar nada por error.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Diseñar una **convención de tags** que distinga versión de imagen de versión de contenido.
- Levantar un registry local, publicar en él y ver la deduplicación con tus ojos.
- Autenticarte sin dejar credenciales en el historial ni en la imagen.
- Publicar en Docker Hub y publicar **multi-plataforma**.
- Añadir metadata OCI que haga la imagen auto-descriptiva.
- Tener una política de retención y saber hacer un rollback de verdad.

---

## 3. 🚧 Qué NO entra todavía

- **SBOM, provenance y firma** → **[F29](29-supply-chain-sbom-firma.md)**, que es la continuación directa.
- **GHCR y GitLab Registry** → **[a11](a11-ghcr-y-gitlab.md)**; **Harbor** → **[a12](a12-harbor.md)**.
- **Distribución sin Internet** → **[a13](a13-air-gapped.md)**; **automatizar con CI** → **[a14](a14-ci-github-actions.md)**.

---

## 4. 🏷️ Tags: nombres humanos con criterio

Un tag es un **nombre humano** para un digest, y [F27](27-registries-por-dentro.md) §6.2 ya dejó claro que es mutable. Lo que
falta es qué nombres poner.

### 4.1 `latest` no significa lo que la gente cree

```text
❌ "la versión más reciente"
✅ "el tag que se asume cuando no escribes ninguno"
```

Es un tag corriente, sin ningún poder especial, y **no se actualiza solo**. Si publicas
`:v2.0.0` y no reapuntas `:latest`, `latest` sigue señalando lo de antes.

> ⚠️ **Por qué el curso no lo usa en el tronco:** un `FROM imagen` sin tag es una dependencia
> que puede cambiar bajo tus pies sin que nada en tu repositorio lo refleje. Publicar `:latest`
> está bien como conveniencia; **depender** de él, no.

### 4.2 La imagen tiene su propia versión

Es la distinción que más gente se salta: **la versión de tu imagen no es la versión de Node ni
la de tu proyecto**. Es la versión del **toolchain**, y merece su propio SemVer.

| Cambio | Nivel | Ejemplo en nuestro laboratorio |
|---|---|---|
| Rompe a quien la usaba | **MAJOR** | quitar una generación de Node; cambiar `/workspace`; subir de Debian |
| Añade sin romper | **MINOR** | añadir Node 8; añadir las librerías de [F15](15-laboratorios-dependencias-nativas.md) |
| Corrige sin cambiar interfaz | **PATCH** | arreglar un script; añadir un paquete que faltaba |

### 4.3 La familia de tags de una release

```text
legacy-node-toolchain:1.4.2      ← exacto, el que fijas en un pipeline
legacy-node-toolchain:1.4        ← se mueve con cada patch de la 1.4
legacy-node-toolchain:1          ← se mueve con cada minor de la 1
legacy-node-toolchain:latest     ← conveniencia, no dependencia
```

**Y los tags operativos**, que no son releases y sirven para trazar:

```text
legacy-node-toolchain:node10           ← qué generación trae por defecto
legacy-node-toolchain:phase15          ← pedagógicos, los de este curso
legacy-node-toolchain:git-a1b2c3d      ← el commit exacto que la construyó
```

> 🧭 **El tag de commit es el más útil de todos en un equipo.** Cuando alguien pregunte "¿qué
> hay dentro de esta imagen?", `git-a1b2c3d` responde con precisión y `latest` no responde nada.

> ⚠️ **Y un tag exacto no es un digest exacto.** `:1.4.2` **debería** ser inmutable, y eso es
> una **política** de tu equipo, no una garantía de OCI: el registry te deja reapuntarlo. Si
> necesitas garantía, es el digest — [F27](27-registries-por-dentro.md) §6.2.

---

## 5. 🏠 Registry local: empezar sin tocar Internet

```bash
docker volume create registry-data

docker run -d \
  --name registry-local \
  -p 127.0.0.1:5000:5000 \
  --mount type=volume,src=registry-data,dst=/var/lib/registry \
  registry:2
```

**Detalles con intención:**

- **`127.0.0.1:` en la publicación**, por lo de [F18](18-networking-de-contenedores.md) §6: un registry sin autenticación abierto a
  tu red es una mala idea gratuita.
- **Un volumen para los datos**, porque si no, [F13](13-overlayfs-y-copy-on-write.md) te dice qué pasa al borrar el contenedor.

```bash
curl -s http://localhost:5000/v2/ && echo "registry vivo ✅"
```

### 5.1 Etiquetar y publicar

```bash
docker tag legacy-node-toolchain:phase15 localhost:5000/legacy-node-toolchain:1.0.0
docker push localhost:5000/legacy-node-toolchain:1.0.0
```

La salida es el protocolo de [F27](27-registries-por-dentro.md) §7 en acción:

```text
The push refers to repository [localhost:5000/legacy-node-toolchain]
a1b2c3d4e5f6: Pushed
b2c3d4e5f6a1: Pushed
...
1.0.0: digest: sha256:9f8e7d... size: 1571
```

**Ese `digest:` del final es el manifest digest**, y es el que tienes que guardar si algún día
quieres volver exactamente aquí.

### 5.2 La deduplicación, con tus ojos

```bash
# publica una segunda versión que solo cambie una capa alta
docker tag legacy-node-toolchain:phase15 localhost:5000/legacy-node-toolchain:1.0.1
docker push localhost:5000/legacy-node-toolchain:1.0.1
```
```text
a1b2c3d4e5f6: Layer already exists
b2c3d4e5f6a1: Layer already exists
...
```

**Nada se subió dos veces.** Las capas están direccionadas por contenido —[F27](27-registries-por-dentro.md) §5— así que el
registry ya las tenía. Es el mismo mecanismo que hace un `pull` instantáneo.

### 5.3 Y compruébalo en el disco

```bash
docker exec registry-local find /var/lib/registry -maxdepth 6 -type d | head -20
```

Vas a ver la estructura de [F27](27-registries-por-dentro.md): un directorio de `blobs` nombrado por hash, y otro de
`repositories` con los manifests y los tags. **Un registry es un directorio de archivos con un
índice.**

### 5.4 Un `pull` de verdad

```bash
docker rmi localhost:5000/legacy-node-toolchain:1.0.0 legacy-node-toolchain:phase15
docker pull localhost:5000/legacy-node-toolchain:1.0.0
docker run --rm localhost:5000/legacy-node-toolchain:1.0.0 node --version
```

Borrar la copia local **antes** del pull es lo que hace honesta la prueba: si no, el pull no
descarga nada y no demuestras nada.

> ⚠️ **HTTP plano no es diseño de producción.** Este registry local no tiene TLS ni
> autenticación, y funciona porque el motor confía en `localhost`. Para cualquier otra cosa hace
> falta TLS y credenciales — **[a12](a12-harbor.md)** trata el caso empresarial.

**Con Podman es equivalente**, con la salvedad de [F24](24-docker-y-podman-arquitectura.md) §9: son almacenes distintos, así que la
imagen tienes que construirla o traerla con Podman.

---

## 6. 🔑 Autenticación sin filtrar credenciales

```bash
docker login registro.ejemplo.com
```

Lo que hace: pide credenciales, obtiene un token del registry, y **guarda algo** en
`~/.docker/config.json`.

```bash
cat ~/.docker/config.json | jq
```

Y aquí está el detalle incómodo:

```json
{ "auths": { "registro.ejemplo.com": { "auth": "dXN1YXJpbzpjb250cmFzZcOxYQ==" } } }
```

> 🚨 **Ese `auth` es Base64, no cifrado.** `echo '...' | base64 -d` devuelve `usuario:contraseña`
> en claro. Un `config.json` sin credential helper es un archivo con tus credenciales legibles.

**Las tres reglas que evitan los problemas frecuentes:**

**Nunca la contraseña en la línea de comandos.** Queda en el historial del shell y en la lista de
procesos:

```bash
docker login -u usuario -p 'mi-contraseña'          # ⛔ nunca
echo "$REGISTRY_TOKEN" | docker login -u usuario --password-stdin registro.ejemplo.com   # ✅
```

**Usa tokens, no tu contraseña.** Docker Hub y los demás permiten *access tokens* con permisos
acotados y revocables. Tu contraseña abre también la configuración de la cuenta.

**Configura un credential helper** —`osxkeychain`, `secretservice`, `wincred`— para que las
credenciales vivan en el llavero del sistema y no en un JSON.

> ⚠️ **Y la que arruina la fase entera:** una credencial que entra en la imagen **se queda en
> ella**, aunque la borres en la capa siguiente. Es [F13](13-overlayfs-y-copy-on-write.md) §12, y es el motivo de que
> `~/.docker/config.json` esté en tu `.dockerignore` desde [F07](07-build-de-la-imagen.md).

---

## 7. 🐳 Docker Hub, y publicar multi-plataforma

```bash
echo "$DOCKERHUB_TOKEN" | docker login -u tu-usuario --password-stdin

docker tag legacy-node-toolchain:phase15 tu-usuario/legacy-node-toolchain:1.0.0
docker push tu-usuario/legacy-node-toolchain:1.0.0
```

### 7.1 Las dos arquitecturas, en un tag

Aquí es donde [F21](21-arquitecturas-y-emulacion.md) §6.2 se completa. Buildx **sí** puede publicar las dos a la vez, porque el
registry sí sabe guardar un index:

```bash
docker buildx create --name multiarch --use 2>/dev/null || docker buildx use multiarch

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --file dockerfiles/08-multiarch.Dockerfile \
  --tag tu-usuario/legacy-node-toolchain:1.0.0 \
  --push \
  .
```

**`--push` en lugar de `--load`.** Era exactamente el problema de [F21](21-arquitecturas-y-emulacion.md): dos plataformas no caben
en tu almacén local bajo un tag, y sí caben en un registry.

Y se verifica con lo de [F27](27-registries-por-dentro.md):

```bash
docker manifest inspect tu-usuario/legacy-node-toolchain:1.0.0 | jq '.manifests[].platform'
```
```text
{ "architecture": "amd64", "os": "linux" }
{ "architecture": "arm64", "os": "linux" }
```

---

## 8. 🏷️ Metadata OCI: que la imagen sepa quién es

[F02](02-dockerfile-esencial.md) §7.9 introdujo `LABEL` y dijo que las claves `org.opencontainers.image.*` son un estándar.
Aquí se usan de verdad.

```dockerfile
LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/tu-usuario/legacy-node-toolchain"
LABEL org.opencontainers.image.documentation="https://github.com/tu-usuario/legacy-node-toolchain#readme"

# estos tres cambian en cada build: van como ARG
ARG IMAGE_VERSION=dev
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
```

```bash
docker build \
  --build-arg IMAGE_VERSION=1.0.0 \
  --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --platform linux/amd64 \
  -t legacy-node-toolchain:1.0.0 .
```

```bash
docker image inspect legacy-node-toolchain:1.0.0 \
  --format '{{json .Config.Labels}}' | jq
```

> 🧭 **Por qué merece la pena.** Dentro de un año, alguien va a encontrarse esta imagen en un
> registry y va a preguntarse de dónde salió. `org.opencontainers.image.source` y
> `.revision` responden en un comando. Es documentación que viaja **dentro** del artefacto, y no
> se pierde.

> ⚠️ **Los labels son públicos.** Cualquiera que descargue la imagen los lee. No metas URLs
> internas ni nombres de sistemas que no quieras publicar.

---

## 9. 🗄️ Retención y rollback

**Publicar es fácil; acumular es automático.** Sin política, un registry se llena de tags que
nadie sabe si se pueden borrar.

Una política sencilla y defendible:

```text
tags de release (1.4.2)      → se conservan indefinidamente. Son el rollback
tags de rama (main, dev)     → se reapuntan; no se acumulan
tags de commit (git-a1b2c3d) → se conservan N meses, después se limpian
tags pedagógicos (phase15)   → mientras el curso los use
```

**Y el rollback, otra vez, es por digest** — [F27](27-registries-por-dentro.md) §6.3:

```bash
# guarda esto CUANDO funciona, no cuando falla
docker inspect --format '{{index .RepoDigests 0}}' tu-usuario/legacy-node-toolchain:1.0.0

# y vuelve
docker pull tu-usuario/legacy-node-toolchain@sha256:...
```

> 🧭 **La costumbre que salva:** registra el digest de cada imagen que despliegues o valides, en
> el `VALIDATION-REPORT.md` de [F11](11-validar-tu-proyecto.md) o donde corresponda. El día que lo necesites, el tag ya se
> habrá movido.

**Borrar de verdad** es más complicado de lo que parece: borrar un tag no libera espacio, porque
los blobs siguen ahí referenciados por otros manifests. Hace falta *garbage collection* del
registry, y en los gestionados lo hace el proveedor con sus propias reglas.

---

## 10. ⚠️ Errores comunes y diagnóstico

**`denied: requested access to the resource is denied`.** No estás autenticado, el nombre del
repositorio no coincide con tu usuario, o el token no tiene permiso de escritura.

**`unauthorized` tras un `docker login` correcto.** El token expiró, o hiciste login en un
registry distinto al del tag.

**`http: server gave HTTP response to HTTPS client`.** Registry local sin TLS al que el motor
intenta llegar por HTTPS. Con `localhost` no pasa; con una IP hay que declararlo como registry
inseguro — y pensárselo.

**`buildx --push` falla y `--load` funciona.** Falta autenticación, o el tag no incluye el
registry destino.

**Publiqué las dos plataformas y `docker pull` trae solo una.** Correcto: el cliente elige la
suya. [F21](21-arquitecturas-y-emulacion.md) §5.

**El registry local perdió todo al reiniciar.** Faltaba el volumen. §5.

**`config.json` tiene mis credenciales en claro.** Sí. §6, y por eso el credential helper.

---

## 11. 📋 Checklist de validación

```text
[ ] Tienes una convención de tags escrita, con release y operativos
[ ] Sabes por qué latest no significa "la más reciente"
[ ] El registry local corre, con volumen y publicado en 127.0.0.1
[ ] Publicaste y viste el manifest digest en la salida del push
[ ] Viste "Layer already exists" en un segundo push
[ ] Exploraste el disco del registry y reconociste blobs y repositories
[ ] Borraste la copia local e hiciste un pull real
[ ] Sabes qué hay dentro de ~/.docker/config.json
[ ] Nunca pusiste una contraseña en la línea de comandos
[ ] Publicaste las dos arquitecturas con --push y lo verificaste
[ ] La imagen lleva metadata OCI con source, revision y created
[ ] Guardaste el digest de la imagen publicada
```

---

## 12. 🧪 Ejercicios de la Fase 28 (20)

## 🟢 Fácil — publicar por primera vez (1–6)

### 🟢 Ejercicio 1 — Levanta el registry

Monta el registry de §5 y comprueba que responde.

### 🟢 Ejercicio 2 — Primer push

Etiqueta y publica la imagen del curso.

**Objetivo:** localizar el manifest digest en la salida y guardarlo.

### 🟢 Ejercicio 3 — La deduplicación

Publica una segunda etiqueta de la misma imagen.

**Pregunta:** ¿cuántas capas se subieron? ¿Por qué?

### 🟢 Ejercicio 4 — El disco del registry

Explora `/var/lib/registry` dentro del contenedor.

**Objetivo:** reconocer la estructura de [F27](27-registries-por-dentro.md) §5 en archivos reales.

### 🟢 Ejercicio 5 — Pull real

Borra las copias locales y haz `pull` desde tu registry.

**Objetivo:** ver la descarga de verdad, no un `Already exists`.

### 🟢 Ejercicio 6 — `latest` no se mueve solo

Publica `:1.0.0`, después `:2.0.0`, y comprueba a dónde apunta `:latest`.

**Objetivo:** confirmar §4.1 con un experimento en veinte segundos.

## 🟡 Intermedio — tags, metadata y credenciales (7–12)

### 🟡 Ejercicio 7 — La familia de tags

Publica la misma imagen con los cuatro tags de §4.3 y comprueba los digests.

**Pregunta:** ¿cuánto espacio ocupan los cuatro en el registry?

### 🟡 Ejercicio 8 — Metadata OCI

Añade los labels de §8 y construye con los tres `ARG`.

**Objetivo:** que `docker image inspect` muestre el commit exacto que la produjo.

### 🟡 Ejercicio 9 — Multi-plataforma

Publica las dos arquitecturas con `--push` en tu registry local y verifica el index.

**Objetivo:** cerrar la promesa que [F21](21-arquitecturas-y-emulacion.md) §6.2 dejó abierta.

### 🟡 Ejercicio 10 — Autenticación local

Configura autenticación básica en tu registry con `htpasswd` y prueba `login` y `push`.

**Objetivo:** ver el flujo completo sin exponerte a un registry público.

### 🟡 Ejercicio 11 — `--password-stdin`

Haz login de las dos formas y compara tu historial de shell con `history | tail`.

**Objetivo:** ver la credencial en el historial en un caso y no en el otro.

### 🟡 Ejercicio 12 — Podman publica igual

Repite el ejercicio 2 con Podman contra el mismo registry local.

**Pregunta:** ¿tuviste que construir de nuevo? Relaciónalo con [F24](24-docker-y-podman-arquitectura.md) §9.

## 🟠 Difícil — cuando el push falla o miente (13–17)

### 🟠 Ejercicio 13 — Mira tu `config.json`

Tras el login, decodifica el campo `auth` con `base64 -d`.

**Objetivo:** ver tus credenciales en claro y entender por qué hace falta el helper.

### 🟠 Ejercicio 14 — Un tag que se mueve

Publica `:1.4.2`, anota su digest, publica otra imagen con el **mismo** tag y comprueba.

**Pregunta:** ¿sigue accesible la primera por digest? ¿Qué política evitaría esto?

### 🟠 Ejercicio 15 — El push que no llega

Provoca los tres errores de §10 —`denied`, `unauthorized` y el de HTTP/HTTPS— y anota qué los
distingue.

### 🟠 Ejercicio 16 — El secreto publicado

Construye una imagen que copie un archivo con credenciales, bórralo en la capa siguiente, y
publícala en tu registry local. Después **extrae la credencial** desde el registry.

**Objetivo:** demostrar el aviso de §6 con evidencia. Es la primera mitad del boss fight de
[F13](13-overlayfs-y-copy-on-write.md), ahora con el registry de por medio.

### 🟠 Ejercicio 17 — Rollback real

Publica tres versiones, "descubre" que la tercera está rota, y vuelve a la buena **por digest**.

**Pregunta:** ¿podrías haberlo hecho solo con tags? ¿Qué información habrías necesitado guardar
antes?

## 🔴 Muy difícil — convención de versiones (18–20)

### 🔴 Ejercicio 18 — El espacio que no se libera

Publica varias versiones, borra tags, y mide el espacio del volumen del registry.

**Pregunta:** ¿bajó? ¿Qué hace falta para que baje de verdad? §9.

### 🔴 Ejercicio 19 — Decide qué versión es un MAJOR

Coge la tabla de §4.2 y aplícala al historial real de tu toolchain: repasa qué has cambiado
desde [F02](02-dockerfile-esencial.md) hasta [F15](15-laboratorios-dependencias-nativas.md) y asigna a cada cambio su nivel de SemVer.

**Objetivo:** llegar a qué versión tendría hoy la imagen si hubieras versionado desde el
principio, y justificar los MAJOR. Vas a descubrir que algunos cambios que parecían menores
—mover `/workspace`, quitar `select-node` de runtime— rompían a quien ya la usaba.

### 🔴 Ejercicio 20 — La convención de tags de tu equipo

Diseña la convención completa: release, operativos, ramas y commits, con su política de
retención.

**Objetivo:** que responda tres preguntas — *"¿qué tag pongo en el pipeline?"*, *"¿cómo sé qué
hay dentro de esta imagen?"* y *"¿cuánto tiempo conservamos esto?"* — y que cada respuesta tenga
su porqué.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Credential helper

Configura el helper de tu sistema y comprueba que `config.json` deja de tener el `auth`.

### 🔥 Ejercicio 22 — Un registry con TLS

Genera un certificado y levanta el registry local con HTTPS.

**Objetivo:** entender qué configuración hace falta de verdad y por qué `localhost` se libraba.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: la publicación completa

Publica el toolchain como una release de verdad: las dos arquitecturas, con SemVer y su familia
de tags, metadata OCI completa, en un registry con autenticación, y con la validación de [F11](11-validar-tu-proyecto.md)
ejecutada **sobre la imagen descargada del registry** y no sobre la local.

**Objetivo:** la entrega es la imagen publicada, el `VALIDATION-REPORT.md` que la acompaña con
su digest anotado, y el documento de release que diga: qué cambió, qué tags existen, cómo se
hace rollback y qué credenciales hicieron falta —**sin incluir ninguna**—. La parte que más se
olvida es validar **lo publicado** en lugar de lo local: son artefactos distintos hasta que
demuestras que no.

---

## 13. 📚 Referencias

**Publicación**
- `docker push`: https://docs.docker.com/reference/cli/docker-image-push/
- `docker login`: https://docs.docker.com/reference/cli/docker-login/
- Credential helpers: https://github.com/docker/docker-credential-helpers
- Buildx y `--push`: https://docs.docker.com/build/building/multi-platform/

**Registry**
- Distribution, el registry de referencia: https://distribution.github.io/distribution/
- Configuración y garbage collection: https://distribution.github.io/distribution/about/garbage-collection/

**Metadata**
- Anotaciones OCI estándar: https://github.com/opencontainers/image-spec/blob/main/annotations.md

**Docker Hub**
- Access tokens: https://docs.docker.com/security/for-developers/access-tokens/

> ⚠️ **Los límites de descarga y las políticas de Docker Hub cambian.** Si un `pull` empieza a
> fallar por límite de tasa en un CI, no es tu configuración: es la política del servicio.
> Enlaces revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** los credential helpers antes del ejercicio 13, y la garbage
collection antes del 18.

---

## 14. 🏁 Resultado de la fase

```text
TAGS            latest = el tag por defecto, nada más
                la imagen tiene su PROPIO SemVer, distinto del de Node y del proyecto
                release: 1.4.2 · 1.4 · 1 · latest
                operativos: node10 · phase15 · git-a1b2c3d
                tag exacto ≠ digest exacto: es política, no garantía

REGISTRY LOCAL  registry:2 con volumen, publicado en 127.0.0.1
                el push muestra el manifest digest — guárdalo
                "Layer already exists" = deduplicación por contenido
                y en disco: blobs por hash + repositories

CREDENCIALES    config.json guarda Base64, no cifrado
                nunca -p en la línea de comandos → --password-stdin
                tokens en vez de contraseña · credential helper
                y lo que entra en una capa, se queda (F13)

MULTI-PLATAFORMA  buildx --platform a,b --push
                  --push sí, --load no: dos imágenes no caben bajo un tag local

METADATA OCI    source · revision · created · version
                documentación que viaja dentro del artefacto

RETENCIÓN       releases para siempre · ramas se reapuntan · commits caducan
                el rollback es por digest, y hay que guardarlo ANTES
```

> **La señal de que quedó bien:** *"puedo señalar una imagen publicada y decir de qué commit
> salió, qué arquitecturas trae y cómo volver a ella dentro de un año — sin preguntarle a
> nadie."*

En **[F29](29-supply-chain-sbom-firma.md)** cerramos el bloque de publicación con la pregunta que queda: **¿qué metiste
exactamente en esa caja, y cómo lo demuestras?** SBOM, provenance y firma.
