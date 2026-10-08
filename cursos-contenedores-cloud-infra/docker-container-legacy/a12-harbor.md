# 🏢 Apéndice a12 — Harbor: cuando el registry deja de ser un sitio donde haces push

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra el bucle de:** [F28](28-publicar-la-imagen.md) §5 — *"para cualquier otra cosa hace falta TLS y credenciales; a12 trata el caso empresarial"*
> **Requisitos:** **[F27](27-registries-por-dentro.md)** y **F28**
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **Qué encontrarás:** qué añade un registry empresarial sobre el `registry:2` de F28, y —lo más útil para este curso— qué pasa cuando le pones un escáner de vulnerabilidades a una imagen legacy

Harbor es el registry que probablemente tenga tu empresa. Este apéndice no es un manual de
Harbor: es **qué problemas resuelve que el registry local no resuelve**, y qué implica cada uno
para un laboratorio legacy.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué añade sobre un `registry:2`?" | [§1](#1--las-seis-cosas-que-añade) |
| "¿Cómo se organiza?" | [§2](#2--proyectos-el-concepto-que-lo-ordena-todo) |
| "¿Qué pasa si escanea mi imagen legacy?" | [§3](#3--el-escaneo-y-tu-imagen-legacy) ⚠️ |
| "¿Cómo replico entre registries?" | [§4](#4--replicación) |

---

## 1. 🧱 Las seis cosas que añade

Un `registry:2` guarda y sirve blobs. Harbor añade lo que una empresa necesita alrededor:

| | Qué resuelve |
|---|---|
| **Proyectos y permisos** | quién puede leer y escribir qué, con roles e integración LDAP/OIDC |
| **Cuotas** | límite de almacenamiento por proyecto, para que uno no llene el disco de todos |
| **Escaneo de vulnerabilidades** | Trivy integrado, escaneando en cada push — §3 |
| **Políticas de retención** | reglas declarativas: conserva los N últimos, borra lo anterior a X |
| **Replicación** | copiar imágenes entre registries según reglas — §4 |
| **Firma y políticas de admisión** | exigir que una imagen esté firmada o escaneada para poder descargarse |

**Lo que no cambia:** el formato, el protocolo y los comandos. Sigue siendo un registry OCI y tu
`docker push` es idéntico — [F27](27-registries-por-dentro.md) §7.

---

## 2. 📁 Proyectos: el concepto que lo ordena todo

En Harbor todo cuelga de un **proyecto**, que es el nivel donde se configuran permisos, cuotas,
escaneo y retención.

```text
harbor.empresa.com / plataforma / legacy-node-toolchain : 1.0.0
        │                │                 │
    REGISTRY         PROYECTO         REPOSITORIO
```

```bash
echo "$HARBOR_TOKEN" | docker login harbor.empresa.com -u tu-usuario --password-stdin
docker tag legacy-node-toolchain:1.0.0 harbor.empresa.com/plataforma/legacy-node-toolchain:1.0.0
docker push harbor.empresa.com/plataforma/legacy-node-toolchain:1.0.0
```

**Y una decisión que conviene tomar pronto**, si vas a publicar cosas de este curso: un proyecto
propio para el laboratorio legacy, separado de lo que va a producción. Por lo de §3.

---

## 3. 🚨 El escaneo, y tu imagen legacy

**Esta es la sección que importa de verdad**, porque es donde este apéndice se cruza con la
naturaleza del curso.

Harbor escanea cada imagen al publicarse. Y tu toolchain —Debian 10 EOL, Node 10 EOL,
dependencias de 2018 sin parchear— **va a producir una lista larga de CVE**, exactamente como
avisó [F29](29-supply-chain-sbom-firma.md) §5.

```text
legacy-node-toolchain:1.0.0
  Critical: XX    High: XXX    Medium: XXX    Low: XXX
```

### 3.1 Y el problema operativo que eso crea

Harbor puede configurarse para **impedir descargar imágenes con vulnerabilidades por encima de
un umbral**. Es una política razonable para producción y, aplicada a este laboratorio, **impide
que nadie use la imagen** — incluido tú.

**Las tres salidas, con su honestidad:**

| Salida | Qué implica |
|---|---|
| **Un proyecto aparte, sin política de bloqueo** | ✅ lo correcto: el laboratorio no es producción, y la política de producción no le aplica |
| **Excepciones por CVE** | funciona y es trabajo continuo; cada escaneo trae nuevas |
| **Bajar el umbral globalmente** | ⛔ **no**: degradas la política de todo por un caso |

> 🧭 **La conversación que hay que tener con quien administra Harbor**, y conviene llevarla
> preparada: *"esta imagen es un toolchain de desarrollo para mantener proyectos EOL. Sus
> vulnerabilidades son inherentes al stack que reproduce y están documentadas. No se despliega,
> no expone servicios y no maneja datos. Necesita un proyecto con política propia, no una
> excepción en la política general."*
>
> Es exactamente el veredicto que [F29](29-supply-chain-sbom-firma.md) §5.1 te enseñó a escribir, y aquí es donde se usa.

### 3.2 Y lo que el escaneo sí te da

No todo es fricción. Un escaneo periódico responde la pregunta de [F29](29-supply-chain-sbom-firma.md) §4.1 —*"¿tengo yo eso?"*—
automáticamente, y sobre un catálogo entero. Para un equipo con veinte imágenes legacy, eso vale.

---

## 4. 🔁 Replicación

Harbor puede copiar imágenes entre registries según reglas: desde Docker Hub hacia dentro, entre
instancias, o hacia fuera.

**Los dos usos que importan para este curso:**

**Espejo de Docker Hub.** Resuelve el `toomanyrequests` de [F31](31-catalogo-de-fallos-i.md) §6.6 y te desacopla de que una
imagen pública desaparezca — que es el riesgo de [F14](14-abi-libc-y-prebuilds.md) §7.1 aplicado a las imágenes base.

**Air-gapped.** Replicar hacia una instancia sin Internet es la versión industrial de lo que
**[a13](a13-air-gapped.md)** hace a mano con `save` y `load`.

> 💡 **Y una alternativa ligera:** `skopeo copy` —[F27](27-registries-por-dentro.md) §8— hace lo mismo entre dos registries sin
> pasar por tu disco y sin necesitar Harbor. Para un caso puntual es más simple.

---

## 5. 🧭 Guía rápida: cuándo usar qué

| Tu situación | Registry |
|---|---|
| Aprendes, o pruebas | **registry local** — [F28](28-publicar-la-imagen.md) §5 |
| Proyecto personal en GitHub o GitLab | **GHCR** o **GitLab** — **[a11](a11-ghcr-y-gitlab.md)** |
| Empresa con control de acceso, cuotas y auditoría | **Harbor** |
| Necesitas un espejo de Docker Hub | **Harbor**, o un `registry:2` en modo proxy |
| Copiar una imagen entre dos registries, puntualmente | **`skopeo copy`**, sin instalar nada |
| Publicas una imagen legacy en un Harbor corporativo | **proyecto aparte**, y la conversación de §3.1 |

---

## 6. ⚠️ Errores comunes

**`x509: certificate signed by unknown authority`.** Harbor con certificado interno. Hay que
añadir la CA de la empresa al motor — y **no** declararlo como registry inseguro, que es el
atajo tentador.

**`denied` con credenciales correctas.** No tienes rol de escritura en ese proyecto, o el
proyecto no existe: Harbor **no lo crea al hacer push**, a diferencia de otros registries.

**El push funciona y nadie puede descargar.** La política de vulnerabilidades. §3.1.

**El proyecto se quedó sin cuota.** Es una cuota de Harbor, no de disco. Revisa la política de
retención.

**Las imágenes desaparecen solas.** Una regla de retención está haciendo su trabajo. Comprueba
cuál antes de asumir que algo se rompió.

---

## 🧪 Ejercicios (4)

> 🧭 Estos ejercicios necesitan una instancia de Harbor. Si no tienes una, se puede levantar
> local con su instalador — o léelos como preparación para el día que te toque.

### 🟢 Ejercicio 1 — Publica en un proyecto

Crea un proyecto, publica el toolchain y explora los tags y digests en la interfaz.

**Pregunta:** ¿el digest coincide con el que te dio el `push`? Debería — [F27](27-registries-por-dentro.md) §6.

### 🟡 Ejercicio 2 — El escaneo, de frente

Deja que Harbor escanee tu imagen legacy y lee el informe.

**Objetivo:** anotar los números y compararlos con los que te dio Trivy en [F29](29-supply-chain-sbom-firma.md) §5.

### 🟡 Ejercicio 3 — Una política de retención

Publica cinco versiones y configura una regla que conserve solo las tres últimas.

**Pregunta:** ¿qué pasó con las otras dos? ¿Se liberó espacio de inmediato?

### 🔴 Ejercicio 4 — La conversación de §3.1

Escribe la propuesta que le llevarías a quien administra el Harbor de tu empresa para publicar
esta imagen.

**Objetivo:** que reconozca por qué existe la política general, explique por qué este caso es
distinto **con evidencia**, y proponga la configuración concreta —no una excepción genérica—.
Es el mismo ejercicio de honestidad que [F29](29-supply-chain-sbom-firma.md) §5.1, ahora con un interlocutor real.

---

## 📚 Referencias

- Harbor: https://goharbor.io/docs/
- Instalación: https://goharbor.io/docs/latest/install-config/
- Escaneo de vulnerabilidades: https://goharbor.io/docs/latest/administration/vulnerability-scanning/
- Políticas de retención: https://goharbor.io/docs/latest/working-with-projects/working-with-images/create-tag-retention-rules/
- Replicación: https://goharbor.io/docs/latest/administration/configuring-replication/

**Vuelve a:** [F28 §5](28-publicar-la-imagen.md) · [F29 §5](29-supply-chain-sbom-firma.md) · [a11](a11-ghcr-y-gitlab.md)
