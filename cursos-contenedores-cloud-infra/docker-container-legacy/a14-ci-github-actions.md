# 🤖 Apéndice a14 — CI con GitHub Actions: automatizar después de dominar el camino manual

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F20](20-validacion-sistematica-y-evidencia.md) §11 · [F28](28-publicar-la-imagen.md) §7 · [a11](a11-ghcr-y-gitlab.md) §1.2
> **Requisitos:** **[F11](11-validar-tu-proyecto.md)** (el protocolo), **F20** (evidencia) y **F28** (publicar)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Código de este apéndice:** [`src/a14-ci-github-actions/`](src/a14-ci-github-actions/)
> **Qué encontrarás:** el pipeline que construye, valida y publica el toolchain — con las tres cosas que un CI de este curso tiene que hacer bien y casi ningún ejemplo hace

**Automatizar después de entender.** Es la regla que el curso repite desde [F09](09-montar-tu-proyecto.md), y este apéndice
es su aplicación final: cada paso del workflow es algo que ya has ejecutado a mano.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué debe hacer un CI de este curso?" | [§1](#1--los-tres-trabajos-y-el-orden-que-importa) |
| "Dame el workflow" | [§2](#2--el-workflow-completo) |
| "¿Qué hace mal casi todo el mundo?" | [§3](#3-️-las-tres-cosas-que-casi-nadie-hace-bien) ⚠️ |
| "¿Y multi-plataforma?" | [§4](#4-️-multi-plataforma-en-ci) |

---

## 1. 🎯 Los tres trabajos, y el orden que importa

```text
1. BUILD      construir la imagen · verificar que construye desde cero
2. VALIDATE   ejecutar el protocolo de F11 sobre los fixtures · guardar la evidencia
3. PUBLISH    solo si 1 y 2 pasaron · con tags, metadata y attestations
```

> 🧭 **Publicar sin validar es el error de diseño más común en un pipeline.** Si el job de
> publicación no depende del de validación, acabas con imágenes publicadas que nadie comprobó — y
> con un `latest` que apunta a algo roto.

---

## 2. 📄 El workflow completo

📄 **`.github/workflows/toolchain.yml`**

```yaml
name: toolchain

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:

env:
  IMAGE_NAME: ghcr.io/${{ github.repository }}/legacy-node-toolchain

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      # construye SIN caché: comprueba que el repositorio está completo (F12 §11)
      - name: Build desde cero
        run: |
          docker buildx build \
            --platform linux/amd64 \
            --no-cache \
            --build-arg IMAGE_VERSION="${GITHUB_REF_NAME}" \
            --build-arg VCS_REF="${GITHUB_SHA::7}" \
            --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --load \
            -t legacy-node-toolchain:ci \
            .

      - name: Guardar la imagen para los jobs siguientes
        run: docker save legacy-node-toolchain:ci | gzip > /tmp/image.tar.gz

      - uses: actions/upload-artifact@v4
        with:
          name: image
          path: /tmp/image.tar.gz
          retention-days: 1

  validate:
    needs: build
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false                      # ⚠️ queremos la matriz ENTERA, no la primera rota
      matrix:
        node: ['10.24.1', '12.22.12', '14.21.3', '16.20.2']
        fixture: ['00-node-smoke', '10-vue2-min', '30-react16-min']
    steps:
      - uses: actions/checkout@v4

      - uses: actions/download-artifact@v4
        with: { name: image, path: /tmp }

      - run: gunzip -c /tmp/image.tar.gz | docker load

      - name: Volumen limpio por combinación
        run: |
          VOL="ci-${{ matrix.fixture }}-node${{ matrix.node }}-amd64"
          docker volume rm "$VOL" 2>/dev/null || true
          docker volume create "$VOL"
          echo "VOL=$VOL" >> "$GITHUB_ENV"

      - name: Protocolo de validación
        run: |
          set -o pipefail                   # ← §3.1
          run_step() {
            local etapa="$1"; shift
            docker run --rm --platform linux/amd64 \
              -e "NODE_VERSION=${{ matrix.node }}" \
              --mount "type=bind,src=$PWD/src/11-validar-tu-proyecto/${{ matrix.fixture }},dst=/workspace" \
              --mount "type=volume,src=${VOL},dst=/workspace/node_modules" \
              legacy-node-toolchain:ci "$@" 2>&1 | tee "evidencia/${etapa}.log"
            local code=${PIPESTATUS[0]}     # ← §3.1: el de docker, no el de tee
            echo "${etapa}=${code}" >> evidencia/exit-codes.txt
            return $code
          }

          mkdir -p evidencia
          run_step install npm ci || echo "install falló"
          run_step build npm run build || echo "build falló"
          cat evidencia/exit-codes.txt

      - uses: actions/upload-artifact@v4
        if: always()                        # ← §3.2: la evidencia del fallo es la que importa
        with:
          name: evidencia-${{ matrix.fixture }}-node${{ matrix.node }}
          path: evidencia/

  publish:
    needs: [build, validate]                # ← solo si las DOS pasaron
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      id-token: write                       # ← para la firma keyless de F29 §7
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-qemu-action@v3    # emulación para construir arm64
      - uses: docker/setup-buildx-action@v3

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.IMAGE_NAME }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha,prefix=git-

      - name: Build y push multi-plataforma
        id: push
        uses: docker/build-push-action@v6
        with:
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          sbom: true                        # F29 §4.5
          provenance: mode=max              # F29 §6

      - name: Firmar por digest
        run: cosign sign --yes "${IMAGE_NAME}@${{ steps.push.outputs.digest }}"
```

---

## 3. ⚠️ Las tres cosas que casi nadie hace bien

### 3.1 El exit code de la tubería

```yaml
run: npm ci 2>&1 | tee install.log        # ⛔ registra el código de TEE
```

Es el problema de [F20](20-validacion-sistematica-y-evidencia.md) §6.3, y en un CI es peor que en tu terminal: **un pipeline verde sobre un
paso que falló**. Nadie lo mira, porque está verde.

```bash
set -o pipefail                    # y/o
code=${PIPESTATUS[0]}
```

> 🩺 **El ejercicio 23 de [F20](20-validacion-sistematica-y-evidencia.md) te pedía auditar un CI ajeno buscando esto.** Hay muchísimos, y el
> síntoma es que "a veces el pipeline no detecta fallos".

### 3.2 `if: always()` en la subida de evidencia

Sin esa línea, cuando un paso falla el job se detiene y **la evidencia no se sube** — justo la
del caso que necesitabas investigar.

```yaml
- uses: actions/upload-artifact@v4
  if: always()
```

Es la regla de [F30](30-troubleshooting-metodo-y-herramientas.md) §4 aplicada al CI: **recoger la evidencia antes de nada**, y aquí "antes de
nada" significa "aunque haya fallado".

### 3.3 `fail-fast: false` en la matriz

Por defecto, GitHub cancela toda la matriz cuando una combinación falla. Para un pipeline
normal está bien; **para la matriz de compatibilidad de [F20](20-validacion-sistematica-y-evidencia.md) §7 la destruye**: quieres saber cuáles
de las doce combinaciones funcionan, no solo que una no.

```yaml
strategy:
  fail-fast: false
```

---

## 4. 🏗️ Multi-plataforma en CI

`docker/setup-qemu-action` instala los manejadores de `binfmt_misc` de [F21](21-arquitecturas-y-emulacion.md) §7.3 en el runner, y
con eso `buildx` puede construir arm64 sobre un runner amd64.

**El coste:** construir emulado es lento, y compilar addons nativos emulados, mucho más. Para el
toolchain del curso —que descarga binarios en lugar de compilar— es asumible.

> 💡 **La alternativa cuando duele:** runners nativos de cada arquitectura, construyendo en
> paralelo y uniendo los manifests al final con `docker buildx imagetools create`. Es más rápido
> y más complejo; empieza por QEMU y cambia solo si mides que compensa.

---

## 5. 🧭 Guía rápida: cuándo usar qué

| Tu situación | Recomendación |
|---|---|
| Validar en cada push | jobs `build` + `validate`, sin `publish` |
| Publicar solo releases | `publish` con `if: startsWith(github.ref, 'refs/tags/v')` |
| Matriz de compatibilidad | `strategy.matrix` con **`fail-fast: false`** |
| Registry | **GHCR** con `secrets.GITHUB_TOKEN` — [a11](a11-ghcr-y-gitlab.md) §1.2 |
| Firma sin gestionar claves | **Cosign keyless** con `id-token: write` |
| El pipeline falla por `toomanyrequests` | autentícate en Docker Hub, o usa un espejo — [F31](31-catalogo-de-fallos-i.md) §6.6 |
| Estás empezando | **un job que construya y valide.** Publicar puede esperar |

---

## 6. ⚠️ Errores comunes

**El pipeline está verde y el paso falló.** §3.1.

**No hay logs del fallo.** Falta `if: always()`. §3.2.

**La matriz se cancela en la primera combinación.** `fail-fast: false`. §3.3.

**`denied` al publicar en GHCR.** Falta `permissions: packages: write`, o el namespace tiene
mayúsculas — [a11](a11-ghcr-y-gitlab.md) §1.4.

**`cosign sign` falla con un error de OIDC.** Falta `id-token: write`.

**Funciona en local y falla en el runner.** El runner es amd64 y limpio: probablemente es [F12](12-capas-cache-y-contexto.md)
§11 —tu build dependía de la caché— o [F17](17-usuarios-permisos-y-volumenes.md) §5.1 —permisos que en macOS no veías—.

**El build tarda muchísimo con `--no-cache`.** Es el precio de comprobar que construye desde
cero, y merece la pena. Si duele, sepáralo a un job programado en lugar de en cada push.

---

## 🧪 Ejercicios (5)

### 🟢 Ejercicio 1 — El pipeline mínimo

Monta los jobs `build` y `validate` con un solo fixture y una sola versión de Node.

### 🟡 Ejercicio 2 — La matriz completa

Amplía a las cuatro generaciones y tres fixtures, con `fail-fast: false`.

**Pregunta:** ¿cuántas combinaciones pasan? Compara con la matriz que hiciste a mano en [F20](20-validacion-sistematica-y-evidencia.md) §7.

### 🟡 Ejercicio 3 — Provoca el falso verde

Quita `pipefail` y `PIPESTATUS`, haz que un paso falle, y mira el resultado del job.

**Objetivo:** ver un pipeline verde sobre un fallo real. Después arréglalo.

### 🟠 Ejercicio 4 — La evidencia del fallo

Quita `if: always()`, provoca un fallo, e intenta descargar los logs.

**Objetivo:** comprobar que no están, y entender por qué esa línea es la más importante del
workflow.

### 🔴 Ejercicio 5 — El pipeline de tu proyecto

Adapta el workflow a tu proyecto legacy real, con su matriz de generaciones viables.

**Objetivo:** que produzca el `VALIDATION-REPORT.md` de [F11](11-validar-tu-proyecto.md) como artefacto descargable, y que
**cualquiera del equipo pueda ver en qué generaciones funciona el proyecto sin ejecutar nada**.
Eso es lo que convierte el trabajo de F11 en algo que se mantiene solo.

---

## 📚 Referencias

- GitHub Actions: https://docs.github.com/actions
- `docker/build-push-action`: https://github.com/docker/build-push-action
- `docker/metadata-action`: https://github.com/docker/metadata-action
- `docker/setup-qemu-action`: https://github.com/docker/setup-qemu-action
- Matrices: https://docs.github.com/actions/using-jobs/using-a-matrix-for-your-jobs
- Publicar en GHCR desde Actions: https://docs.github.com/actions/publishing-packages/publishing-docker-images
- Cosign en Actions: https://docs.sigstore.dev/cosign/signing/overview/

> ⚠️ **Las versiones de las actions cambian.** Las `@v3`/`@v4`/`@v6` de este apéndice son las
> vigentes el 3 de septiembre de 2026; comprueba antes de copiar.

**Vuelve a:** [F11](11-validar-tu-proyecto.md) · [F20 §11](20-validacion-sistematica-y-evidencia.md) · [F28](28-publicar-la-imagen.md) · [a11](a11-ghcr-y-gitlab.md)
