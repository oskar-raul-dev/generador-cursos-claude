# 🐙 Apéndice a11 — GHCR y GitLab Container Registry

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F28](28-publicar-la-imagen.md) §7
> **Requisitos:** **[F27](27-registries-por-dentro.md)** (registries por dentro) y **F28** (publicar)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **Qué encontrarás:** los dos registries gestionados que probablemente ya tienes sin saberlo, con sus flujos de autenticación —que es lo único que cambia respecto a F28

[F28](28-publicar-la-imagen.md) publicó en un registry local y en Docker Hub. **El mecanismo es idéntico en cualquier
registry** —es OCI, [F27](27-registries-por-dentro.md) §7— y lo que cambia es el nombre, el flujo de autenticación y las
políticas. Este apéndice cubre los dos más probables.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "Mi código está en GitHub" | [§1](#1--ghcr-github-container-registry) |
| "Mi código está en GitLab" | [§2](#2--gitlab-container-registry) |
| "¿Cuál elijo?" | [§3](#3--guía-rápida-cuándo-usar-qué) |

---

## 1. 🐈 GHCR: GitHub Container Registry

**La ventaja principal:** si tu código está en GitHub, ya tienes registry. El repositorio de la
imagen se asocia al del código, y la procedencia de [F29](29-supply-chain-sbom-firma.md) §6 deja de ser una promesa.

### 1.1 El nombre

```text
ghcr.io / tu-usuario-u-organizacion / legacy-node-toolchain : 1.0.0
   │              │                            │
 REGISTRY      NAMESPACE                   REPOSITORY
```

**El namespace es tu usuario u organización de GitHub**, en minúsculas — y ese detalle produce
un `denied` desconcertante si tu usuario tiene mayúsculas.

### 1.2 Autenticación

**Desde tu máquina**, con un *personal access token* con permiso `write:packages`:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u tu-usuario --password-stdin
```

**Desde GitHub Actions**, y aquí está la comodidad real: hay un token automático por ejecución,
sin secretos que gestionar.

```yaml
permissions:
  contents: read
  packages: write

steps:
  - uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}      # ← automático, no lo creas tú
```

> 🧭 **`secrets.GITHUB_TOKEN` no es un secreto que configuras:** GitHub lo genera por ejecución
> y lo revoca al terminar. Es el mejor argumento de GHCR y el que **[a14](a14-ci-github-actions.md)** aprovecha.

### 1.3 Publicar

```bash
docker tag legacy-node-toolchain:1.0.0 ghcr.io/tu-usuario/legacy-node-toolchain:1.0.0
docker push ghcr.io/tu-usuario/legacy-node-toolchain:1.0.0

# multi-plataforma, como en F28 §7.1
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/tu-usuario/legacy-node-toolchain:1.0.0 --push .
```

### 1.4 Lo que hay que saber

**Los paquetes nacen privados.** Hay que hacerlos públicos explícitamente desde la interfaz, o
quien intente descargarlos verá un `denied` que parece de autenticación y es de visibilidad.

**La vinculación con el repositorio** se declara con el label de [F28](28-publicar-la-imagen.md) §8:

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/tu-usuario/tu-repo"
```

Con él, el paquete aparece asociado al repositorio en la interfaz de GitHub, y hereda su
visibilidad.

**Y soporta las attestations de [F29](29-supply-chain-sbom-firma.md)** —SBOM, provenance y firma con la identidad OIDC de
Actions—, que es el escenario donde el modelo keyless de Sigstore brilla: firmas sin gestionar
una sola clave.

---

## 2. 🦊 GitLab Container Registry

**La ventaja principal:** está integrado en cada proyecto de GitLab, y el registry hereda los
permisos del repositorio sin configurar nada.

### 2.1 El nombre

```text
registry.gitlab.com / grupo / proyecto / imagen : 1.0.0
```

**El namespace es la ruta del proyecto**, y puede tener subgrupos —`grupo/subgrupo/proyecto`—.
En una instancia autogestionada, el registry es el dominio de tu GitLab.

### 2.2 Autenticación

**Desde tu máquina**, con un *deploy token* o un *personal access token* con `write_registry`:

```bash
echo "$GITLAB_TOKEN" | docker login registry.gitlab.com -u tu-usuario --password-stdin
```

**Desde GitLab CI**, con variables predefinidas que ya existen en cada job:

```yaml
build:
  image: docker:24
  services: [docker:24-dind]
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    - docker build -t "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA" .
    - docker push "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA"
```

**Las cuatro variables** —`CI_REGISTRY`, `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD` y
`CI_REGISTRY_IMAGE`— las inyecta GitLab, y `CI_JOB_TOKEN` vive solo lo que dura el job.

> 💡 **`CI_COMMIT_SHORT_SHA` como tag** es exactamente el tag de commit que recomienda [F28](28-publicar-la-imagen.md) §4.3,
> y aquí sale gratis.

### 2.3 Lo que hay que saber

**Un registry por proyecto**, con su interfaz para explorar tags y digests. Cómodo cuando cada
proyecto publica lo suyo, incómodo si quieres un catálogo central.

**Políticas de limpieza configurables** desde la interfaz: conservar los N últimos tags, borrar
los que coincidan con un patrón, o los más antiguos que X. Es la política de retención de [F28](28-publicar-la-imagen.md) §9
implementada por el producto.

**El garbage collection lo ejecuta la instancia**, no tú. En GitLab.com es automático; en una
instalación propia, alguien tiene que programarlo — y es la razón de que un registry
autogestionado crezca sin parar.

---

## 3. 🧭 Guía rápida: cuándo usar qué

| Tu situación | Registry |
|---|---|
| Tu código está en GitHub | **GHCR**: token automático en Actions, procedencia por construcción |
| Tu código está en GitLab | **GitLab Registry**: variables de CI ya inyectadas |
| Quieres máxima difusión pública | **Docker Hub** — [F28](28-publicar-la-imagen.md) §7 |
| Quieres control total y estás en una empresa | **Harbor** — **[a12](a12-harbor.md)** |
| Estás aprendiendo o probando | **registry local** — F28 §5 |
| Tu equipo mezcla varios | **elige uno como fuente de verdad** y replica desde ahí con `skopeo copy` |

> 🧭 **Lo que no cambia entre los cuatro**, y es el punto del apéndice: el formato de imagen, el
> protocolo, los digests, los manifests y el `docker push`. **Lo que cambia es el nombre y cómo
> te autenticas.** Si [F27](27-registries-por-dentro.md) y [F28](28-publicar-la-imagen.md) están claras, cualquier registry nuevo se aprende en diez
> minutos.

---

## 4. ⚠️ Errores comunes

**`denied` en GHCR con las credenciales correctas.** El paquete es privado, o tu usuario tiene
mayúsculas y el namespace las quiere en minúsculas.

**El paquete de GHCR no aparece en el repositorio.** Falta el label
`org.opencontainers.image.source` — §1.4.

**`unauthorized` en GitLab CI.** Estás usando un token personal donde deberías usar
`$CI_REGISTRY_PASSWORD`, o el job perdió su `CI_JOB_TOKEN`.

**El registry de GitLab crece sin parar.** Falta la política de limpieza, o falta el garbage
collection en una instancia autogestionada — §2.3.

**Funciona en local y falla en CI.** Casi siempre es el nombre del namespace: en CI, `$CI_REGISTRY_IMAGE`
ya lo construye por ti.

---

## 🧪 Ejercicios (5)

### 🟢 Ejercicio 1 — Publica en GHCR

Autentícate desde tu máquina y publica el toolchain.

**Pregunta:** ¿aparece asociado al repositorio? Si no, ¿qué label falta?

### 🟢 Ejercicio 2 — Hazlo público y verifícalo

Cambia la visibilidad y descarga la imagen desde una sesión sin autenticar.

### 🟡 Ejercicio 3 — Multi-plataforma en un registry gestionado

Publica las dos arquitecturas con `--push` y verifica el index con `docker manifest inspect`.

### 🟡 Ejercicio 4 — El tag de commit

Configura un job de CI que publique con el SHA corto como tag.

**Objetivo:** que puedas responder "¿qué hay dentro de esta imagen?" mirando su tag — [F28](28-publicar-la-imagen.md) §4.3.

### 🟠 Ejercicio 5 — Compara los tres

Publica la misma imagen en un registry local, en GHCR y en Docker Hub.

**Objetivo:** una tabla con lo que cambió en cada uno —nombre, autenticación, visibilidad por
defecto, políticas— y la confirmación de que el digest del manifest es **el mismo en los tres**.
Eso último es lo que demuestra que OCI funciona.

---

## 📚 Referencias

- GHCR: https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- Vincular un paquete a un repositorio: https://docs.github.com/packages/learn-github-packages/connecting-a-repository-to-a-package
- `docker/login-action`: https://github.com/docker/login-action
- GitLab Container Registry: https://docs.gitlab.com/ee/user/packages/container_registry/
- Variables predefinidas de GitLab CI: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
- Políticas de limpieza: https://docs.gitlab.com/ee/user/packages/container_registry/reduce_container_registry_storage.html

**Vuelve a:** [F28 §7](28-publicar-la-imagen.md) · sigue en [a14](a14-ci-github-actions.md)
