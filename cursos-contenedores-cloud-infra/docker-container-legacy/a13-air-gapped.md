# 📴 Apéndice a13 — Distribución offline y entornos air-gapped

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F14](14-abi-libc-y-prebuilds.md) §7.1 — *"el lockfile no puede congelar Internet"* · [F28](28-publicar-la-imagen.md) §9 · [a04](a04-checksums-gpg-y-archivos.md) §4
> **Requisitos:** **[F27](27-registries-por-dentro.md)** (digests) y **F28** (publicar)
> **Fecha de revisión de documentación externa:** 6 de septiembre de 2026 — `docker save`/`load` y sus equivalentes en Podman
> **Qué encontrarás:** cómo mover una imagen a una máquina sin Internet, cómo sobrevivir al proxy corporativo que hay en medio (§4), y —lo más importante para el legacy— cómo dejar de depender de que un servidor de 2018 siga vivo

Es el apéndice más corto y resuelve el problema más grande que el curso ha dejado abierto: **tus
builds dependen de servidores que no controlas**. `nodejs.org/dist`, `archive.debian.org`, el
registry de npm y el bucket de S3 de quien mantenía `node-sass` en 2018.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Cómo llevo una imagen a una máquina sin Internet?" | [§1](#1--mover-una-imagen-save-y-load) |
| "¿Cómo verifico que llegó bien?" | [§2](#2--verificar-en-destino) |
| "¿Cómo dejo de depender de servidores ajenos?" | [§3](#3--vendorizar-el-nivel-4-de-a04) |
| "Tengo Internet, pero pasa por el proxy de la empresa" | [§4](#4--el-escalón-anterior-el-proxy-corporativo) |

---

## 1. 📦 Mover una imagen: `save` y `load`

```bash
# origen
docker save legacy-node-toolchain:1.0.0 | gzip > toolchain-1.0.0.tar.gz
sha256sum toolchain-1.0.0.tar.gz > toolchain-1.0.0.tar.gz.sha256

# transporte: USB, disco, correo interno, lo que sea

# destino
sha256sum -c toolchain-1.0.0.tar.gz.sha256    # ⚠️ ANTES de cargar
gunzip -c toolchain-1.0.0.tar.gz | docker load
```

**El checksum no es opcional aquí.** Es el mismo razonamiento de [a04](a04-checksums-gpg-y-archivos.md) §1.2: en un transporte
físico, la corrupción es más probable que en una descarga HTTPS, y un tar corrupto produce un
error de `load` mucho peor que un checksum que no cuadra.

**Y con Podman es idéntico**, con la salvedad de [F24](24-docker-y-podman-arquitectura.md) §9: son almacenes distintos.

```bash
podman save --format oci-archive -o toolchain.tar legacy-node-toolchain:1.0.0
podman load -i toolchain.tar
```

### 1.1 Varias imágenes a la vez

```bash
docker save -o lab.tar \
  legacy-node-toolchain:1.0.0 \
  legacy-node-toolchain:diagnostic \
  selenium/standalone-chrome:4.1.4
```

**Las capas compartidas se guardan una sola vez** —es el mismo mecanismo de deduplicación de
[F28](28-publicar-la-imagen.md) §5.2—, así que tres imágenes con la misma base pesan bastante menos que la suma.

### 1.2 Sin motor de por medio: Skopeo

```bash
# origen: del registry a un directorio, sin docker
skopeo copy docker://registro/imagen:1.0.0 dir:/tmp/imagen-1.0.0

# destino: del directorio al registry interno
skopeo copy dir:/tmp/imagen-1.0.0 docker://registro-interno/imagen:1.0.0
```

> 💡 **Skopeo no necesita un motor corriendo** —[F27](27-registries-por-dentro.md) §8—, así que funciona en una máquina de
> transporte donde no quieres instalar Docker. Y `--all` copia todas las plataformas del index,
> no solo la tuya.

---

## 2. ✅ Verificar en destino

Que la imagen cargue no significa que sea la misma. **El digest es lo que lo demuestra** — [F27](27-registries-por-dentro.md)
§6.

```bash
# en origen, ANTES de exportar
docker image inspect legacy-node-toolchain:1.0.0 --format '{{.Id}}'

# en destino, tras cargar
docker image inspect legacy-node-toolchain:1.0.0 --format '{{.Id}}'
```

Los dos `Id` —la identidad local de la imagen, [F27](27-registries-por-dentro.md) §6.1— tienen que coincidir. Si no, algo cambió por el
camino.

**Y la verificación que de verdad cierra el círculo:** ejecuta el protocolo de validación de [F11](11-validar-tu-proyecto.md)
**sobre la imagen cargada en destino**, no sobre la de origen. Es el mismo criterio del boss
fight de [F28](28-publicar-la-imagen.md): son artefactos distintos hasta que demuestras que no.

---

## 3. 📥 Vendorizar: el nivel 4 de [a04](a04-checksums-gpg-y-archivos.md)

Aquí está lo que resuelve el problema de fondo. Mover una imagen es fácil; **lo difícil es
poder reconstruirla dentro de tres años**.

### 3.1 Qué vendorizar, en orden de riesgo

| | Riesgo si desaparece | Cómo |
|---|---|---|
| **Prebuilds de addons nativos** | 🔴 alto: buckets de terceros de 2018 | guarda el `.tar.gz` y apunta la instalación a él |
| **Los tarballs de Node** | 🟡 medio: `nodejs.org/dist` es estable, y no eterno | guárdalos con su `SHASUMS256.txt` |
| **Paquetes `.deb`** | 🟡 medio: `archive.debian.org` es archivo, no mirror | `apt-get download` o un espejo |
| **El árbol de npm** | 🟠 medio-alto: versiones se despublican | `npm pack` de cada una, o un registry espejo |
| **La imagen base** | 🟢 bajo si la tienes guardada | `docker save` |

### 3.2 El artefacto de partida

La forma más simple y más honesta de vendorizar el laboratorio entero:

```text
laboratorio-legacy-1.0.0/
├── imagenes/
│   ├── toolchain-1.0.0.tar.gz + .sha256
│   └── selenium-4.1.4.tar.gz  + .sha256
├── artefactos/
│   ├── node-v10.24.1-linux-x64.tar.xz + SHASUMS256.txt
│   └── prebuilds/node-sass-4.14.1-linux-x64-64.node
├── proyecto/
│   ├── el repositorio completo
│   └── node_modules.tar.gz      ← instalado y verificado en el baseline
├── DIGESTS.txt                  ← los digests de todo, F27 §6
└── README-restaurar.md          ← los comandos exactos, en orden
```

> 🧭 **El `README-restaurar.md` es el entregable que hace útil todo lo demás.** Un directorio con
> tarballs y sin instrucciones es un problema para quien lo encuentre dentro de tres años.
> Escríbelo como el apartado "Reproducir" del `VALIDATION-REPORT.md` de [F11](11-validar-tu-proyecto.md): los comandos
> exactos, en orden, y qué debería ver en cada uno.

### 3.3 El coste, dicho claro

**Espacio:** un laboratorio completo con imágenes, artefactos y `node_modules` está en el orden
de varios gigabytes.

**Mantenimiento:** cada vez que el proyecto cambie una dependencia, el paquete queda
desactualizado. Es un artefacto de release, no un espejo vivo.

**Y no cubre todo:** si el proyecto necesita algo que no anticipaste —un paquete de Debian que
falta, un binario más—, en una máquina sin Internet no hay salida.

> 🧭 **Por eso vendorizar es el nivel 4 de [a04](a04-checksums-gpg-y-archivos.md) §4 y no el baseline.** Se hace cuando el riesgo
> lo justifica: una entrega a un cliente, un entorno regulado, o un proyecto que tienes que
> poder revivir dentro de años. Para el día a día, HTTPS más checksum es la relación correcta.

---

## 4. 🏢 El escalón anterior: el proxy corporativo

Air-gapped es el extremo del espectro. El caso común —y el que más builds rompe— es el de
enmedio: **sí tienes Internet, pero pasa por un proxy de la empresa que abre el TLS, lo
inspecciona y lo vuelve a firmar con su propio certificado raíz.** Para tu contenedor eso no es
un proxy: es un desconocido suplantando a `registry.npmjs.org`, y hace bien en rechazarlo.

Los síntomas están catalogados en [F31](31-catalogo-de-fallos-i.md) §7.5 y §7.6 —`ETIMEDOUT`, `unable to get local
issuer certificate`, `SELF_SIGNED_CERT_IN_CHAIN`—, y allí también está el anti-patrón que
aparece siempre: apagar la verificación con `strict-ssl false` o `NODE_TLS_REJECT_UNAUTHORIZED=0`.
Aquí está lo que hay que hacer en su lugar.

### 4.1 Confiar en el certificado, que son dos almacenes y no uno

El detalle que descarrila a todo el mundo: **Node no usa el almacén de certificados del
sistema.** Lleva su propia lista compilada dentro del binario. Así que instalar el certificado
"bien" arregla `apt`, `curl`, `wget` y `git`, y deja `npm install` fallando exactamente igual —
con lo que parece que no funcionó, y se acaba en el anti-patrón.

Hay que hacer las dos cosas:

```dockerfile
# el certificado raíz de tu empresa, junto al Dockerfile
COPY empresa-root-ca.crt /usr/local/share/ca-certificates/empresa-root-ca.crt

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 1) el almacén del sistema: apt, curl, wget, git
# 2) y el de Node, que es aparte y no hereda del anterior
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
```

`update-ca-certificates` toma lo que dejaste en `/usr/local/share/ca-certificates/` y lo funde
en el bundle `/etc/ssl/certs/ca-certificates.crt`. `NODE_EXTRA_CA_CERTS` le dice a Node que
**añada** ese bundle al suyo, sin sustituirlo.

Con npm 6 —el del baseline— conviene además ser explícito, porque su cliente HTTP tiene su
propia configuración:

```bash
npm config set cafile /etc/ssl/certs/ca-certificates.crt
git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt
```

### 4.2 El proxy en sí, y por qué va en `ARG` y no en `ENV`

El certificado y el proxy son dos problemas distintos: uno es *en quién confías* y el otro es
*por dónde sales*. Para lo segundo, Docker predefine `http_proxy`, `https_proxy` y `no_proxy`
como argumentos de build, y esa es la forma correcta:

```bash
docker build \
  --build-arg http_proxy="$http_proxy" \
  --build-arg https_proxy="$https_proxy" \
  --build-arg no_proxy="localhost,127.0.0.1,.empresa.local" \
  -t legacy-node-toolchain:proxy .
```

APT no lee esas variables por sí solo dentro de todas las configuraciones, así que si te falla
solo `apt-get`, dale lo suyo:

```dockerfile
RUN printf 'Acquire::http::Proxy "%s";\nAcquire::https::Proxy "%s";\n' \
      "$http_proxy" "$https_proxy" > /etc/apt/apt.conf.d/01proxy
```

> ⚠️ **Y por eso `ARG` y no `ENV`.** Un `ENV http_proxy=...` se queda **dentro de la imagen**:
> el día que alguien la use desde casa o desde el CI, cada salida a Internet intentará ir a un
> proxy que desde ahí no existe, y el fallo no mencionará al proxy por ninguna parte. Con
> `--build-arg` la variable vive durante el build y no viaja en la imagen.

> 🧭 **Antes de publicar esa imagen, dos cosas.** El certificado raíz identifica a tu empresa y
> no tiene por qué acabar en un registry público — para eso está el registry interno de
> **[a12](a12-harbor.md)**. Y si vas a firmar o inventariar la imagen, ese `.crt` es una entrada más del SBOM
> de [F29](29-supply-chain-sbom-firma.md): metiste una raíz de confianza en la caja, y conviene que se vea.

### 4.3 Por qué esto vive en el apéndice del air-gap

Porque es el mismo problema con distinta intensidad, y las soluciones se encadenan: si el proxy
rompe tus builds a diario, el siguiente escalón no es pelearte mejor con él, es **dejar de
cruzarlo** — un espejo de registry, y si el riesgo lo justifica, la vendorización de §3. Ahí
está el gradiente completo de este apéndice: confiar en el intermediario, evitarlo, o no
necesitar la red.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Herramienta |
|---|---|
| Llevar una imagen a otra máquina, puntualmente | `docker save` / `load` |
| Copiar entre dos registries | `skopeo copy` — no toca tu disco |
| Máquina de transporte sin motor instalado | **Skopeo** |
| Entorno air-gapped permanente | **registry interno** + replicación (**[a12](a12-harbor.md)**) |
| Tienes que poder revivir esto dentro de tres años | **vendoriza** — §3 |
| Solo te preocupa el `toomanyrequests` de Docker Hub | un espejo, no un paquete offline |
| Tienes red, pero el proxy de la empresa inspecciona el TLS | **certificado en los dos almacenes**, §4.1 — y el proxy en `ARG`, §4.2 |

---

## 🧪 Ejercicios (4)

### 🟢 Ejercicio 1 — Exporta e importa

Guarda tu toolchain, bórralo del almacén local y vuelve a cargarlo.

**Objetivo:** comprobar que el `Id` coincide antes y después — §2.

### 🟡 Ejercicio 2 — Tres imágenes en un tar

Exporta tres imágenes que compartan base y compara el tamaño del tar con la suma de las tres.

**Pregunta:** ¿cuánto ahorró la deduplicación?

### 🟡 Ejercicio 3 — Sin motor, con Skopeo

Copia una imagen de un registry a un directorio y de ahí a otro registry, con `skopeo copy`.

**Pregunta:** ¿apareció en `docker images` en algún momento? ¿Por qué importa eso en una máquina
de transporte?

### 🔴 Ejercicio 4 — El paquete completo

Construye el artefacto de §3.2 para tu proyecto legacy, con su `README-restaurar.md`.

**Objetivo:** que otra persona, **en una máquina sin Internet**, pueda llegar a un `npm test`
verde siguiendo solo tu README. Pruébalo de verdad: desconecta la red y sigue tus propias
instrucciones. Casi siempre falta algo, y encontrarlo es el ejercicio.

---

## 📚 Referencias

- `docker save`: https://docs.docker.com/reference/cli/docker-image-save/
- `docker load`: https://docs.docker.com/reference/cli/docker-image-load/
- `podman save` y formatos: https://docs.podman.io/en/latest/markdown/podman-save.1.html
- Skopeo: https://github.com/containers/skopeo
- `npm pack`: https://docs.npmjs.com/cli/v6/commands/npm-pack

**Vuelve a:** [F14 §7.1](14-abi-libc-y-prebuilds.md) · [F28 §9](28-publicar-la-imagen.md) · [a04 §4](a04-checksums-gpg-y-archivos.md) · [a12 §4](a12-harbor.md)
