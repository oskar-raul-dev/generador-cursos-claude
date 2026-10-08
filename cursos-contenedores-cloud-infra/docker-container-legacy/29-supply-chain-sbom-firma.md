# ✍️ Parte II · Fase 29 — Supply chain: SBOM, provenance y firma

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F27](27-registries-por-dentro.md)** (digests) y **[F28](28-publicar-la-imagen.md)** (publicar)
> **Fecha de revisión de documentación externa:** 3 de septiembre de 2026
> **Estado de la imagen al terminar:** publicada, con inventario, procedencia y firma
> **Objetivo:** responder tres preguntas distintas sobre una imagen —qué contiene, cómo se construyó y quién lo dice— sin que se conviertan en sopa de siglas

---

## 1. 🧭 Dónde estamos

[F28](28-publicar-la-imagen.md) publicó la imagen. Y publicar abre tres preguntas que antes no existían, porque ahora hay
alguien al otro lado que va a descargarla:

```text
¿QUÉ contiene?         →  SBOM
¿CÓMO se construyó?    →  provenance
¿QUIÉN lo dice?        →  firma
```

Son tres cosas distintas, se producen con herramientas distintas, y confundirlas es lo que
convierte este tema en una sopa de siglas que no ayuda a nadie. Esta fase las separa.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar qué es un SBOM y —más importante— **qué no es**.
- Generar el inventario de tu imagen y consultarlo.
- Distinguir SBOM de provenance, y saber qué pregunta responde cada uno.
- Firmar una imagen y verificar una firma, entendiendo qué garantiza y qué no.
- Interpretar un informe de vulnerabilidades de una imagen legacy **sin entrar en pánico y sin
  ignorarlo**.

---

## 3. 🚧 Qué NO entra todavía

- **Automatizarlo todo en CI** → **[a14](a14-ci-github-actions.md)**.
- **Políticas de admisión** —rechazar imágenes sin firma— → fuera de alcance: es terreno de
  Kubernetes.
- **Distribución sin Internet** → **[a13](a13-air-gapped.md)**.

---

## 4. 📜 SBOM: qué contiene la caja

**SBOM** es *Software Bill of Materials*: un **inventario** de lo que hay dentro de un
artefacto. Para nuestra imagen, eso son los paquetes Debian, los módulos de npm, los binarios de
Node, y de dónde salió cada uno.

### 4.1 Lo que un SBOM NO es

> ⚠️ **Un SBOM no es un escáner de vulnerabilidades.** Es una **lista de ingredientes**, no un
> análisis de salud. Dice *"esta imagen contiene `openssl 1.1.1d`"*; no dice si esa versión tiene
> CVE conocidos.
>
> Lo que sí permite es responder la pregunta que importa el día que aparece una vulnerabilidad
> nueva: **"¿tengo yo eso?"** — sin volver a escanear nada y sin adivinar.

### 4.2 Los dos formatos

**SPDX** —un estándar de la Linux Foundation, muy usado en cumplimiento y licencias— y
**CycloneDX** —de OWASP, más orientado a seguridad—. Los dos son válidos y las herramientas
producen los dos; elegir depende de quién vaya a leerlo.

### 4.3 Generarlo con Syft

**Syft** es una herramienta independiente que analiza una imagen y produce el inventario. El
curso la elige por ser standalone: no depende de tu motor ni de tu pipeline.

```bash
# el resumen legible
syft legacy-node-toolchain:1.0.0

# SPDX en JSON
syft legacy-node-toolchain:1.0.0 -o spdx-json > sbom-spdx.json

# CycloneDX
syft legacy-node-toolchain:1.0.0 -o cyclonedx-json > sbom-cdx.json
```

Y consultarlo es donde se vuelve útil:

```bash
# cuántos paquetes hay, por ecosistema
jq -r '.packages[].externalRefs[]?.referenceLocator' sbom-spdx.json \
  | grep -oP '^pkg:\w+' | sort | uniq -c | sort -rn

# ¿está openssl y en qué versión?
jq -r '.packages[] | select(.name=="openssl") | "\(.name) \(.versionInfo)"' sbom-spdx.json

# todos los paquetes de Debian
jq -r '.packages[] | select(.externalRefs[]?.referenceLocator | test("pkg:deb")) | .name' sbom-spdx.json | head -20
```

> 🩺 **El uso real, y por qué vale la pena.** Aparece una vulnerabilidad grave en una librería un
> martes por la mañana. Con SBOM guardado de cada imagen publicada, la pregunta *"¿cuáles de
> nuestras 40 imágenes la tienen?"* es un `jq` sobre 40 archivos. Sin SBOM, son 40 escaneos.

### 4.4 Compara dos arquitecturas

Un uso que cierra el bloque anterior:

```bash
syft legacy-node-toolchain:1.0.0 --platform linux/amd64 -o json | jq -r '.artifacts[].name' | sort > sbom-amd64.txt
syft legacy-node-toolchain:1.0.0 --platform linux/arm64 -o json | jq -r '.artifacts[].name' | sort > sbom-arm64.txt
diff sbom-amd64.txt sbom-arm64.txt
```

**Deberían ser casi idénticos.** Si difieren mucho, algo en tu Dockerfile depende de la
arquitectura de una forma que no controlas — y es exactamente lo que [F21](21-arquitecturas-y-emulacion.md) §6.1 te enseñó a
buscar.

### 4.5 SBOM como attestation de BuildKit

BuildKit puede generar el SBOM **durante el build** y adjuntarlo a la imagen:

```bash
docker buildx build --sbom=true --provenance=true \
  --platform linux/amd64 -t tu-usuario/legacy-node-toolchain:1.0.0 --push .
```

**La diferencia con escanear después no es menor.** Un SBOM generado durante el build sabe qué
se instaló y desde dónde; uno generado escaneando el resultado **infiere** lo que encuentra. El
primero es más fiel y el segundo funciona sobre cualquier imagen, incluidas las ajenas.

> 🧭 **En este curso usamos los dos:** Syft para poder analizar imágenes que no construimos
> nosotros, y las attestations de BuildKit para las nuestras.

### 4.6 📝 Nota de época

Nada de esto era práctica común en 2017–2020. SPDX existía y era terreno de cumplimiento de
licencias; CycloneDX es de 2019; Syft y las attestations de BuildKit son posteriores. **Un
proyecto de tu época no tenía SBOM**, y eso no es un descuido de sus autores.

Lo que sí puedes hacer hoy es **producirlo tú**, y eso convierte una imagen legacy opaca en una
auditable. Es de las pocas cosas de este curso que mejoran el original en lugar de reproducirlo.

---

## 5. 🚨 Vulnerabilidades: nuestra imagen va a hacer ruido

Escanear es distinto de inventariar, y conviene hacerlo sabiendo qué esperar.

```bash
trivy image legacy-node-toolchain:1.0.0
trivy image --severity HIGH,CRITICAL legacy-node-toolchain:1.0.0
trivy sbom sbom-spdx.json         # también escanea un SBOM ya generado
```

> ⚠️ **Prepárate: va a salir una lista larga.** Debian 10 está fuera de soporte desde 2024,
> Node 10 desde 2021, y las dependencias de 2018 llevan años sin parchear. **Es lo esperado y
> no es un fallo del laboratorio**: es la condición que [F01](01-decisiones-debian-zonas-node.md) §4.5 declaró desde el principio.

### 5.1 Cómo leerlo sin pánico y sin negación

Los dos extremos son inútiles: ignorar el informe, y bloquear el trabajo por él.

**Una vulnerabilidad conocida no es un exploit automático.** Para que importe hacen falta tres
cosas a la vez: que el componente vulnerable **esté**, que se **ejecute** en tu flujo, y que
haya una **vía de entrada** hasta él.

```text
CVE en una librería gráfica que solo usa Chromium,
en un laboratorio local que no expone servicios,
sin datos de producción
        → riesgo real: bajo

CVE en una dependencia npm que se ejecuta durante npm install,
con scripts de postinstall que no auditaste
        → riesgo real: ese es el vector, y es el que F25 §9.4 señaló
```

**Lo que sí hay que hacer con el informe:**

- **Guardarlo con la release**, como parte de la evidencia. No para arreglarlo: para saber qué
  aceptaste.
- **Declarar el contexto de uso** en el reporte: local, sin exposición, sin datos reales.
- **Y no publicar la imagen como "segura para producción"**, que es lo que [F01](01-decisiones-debian-zonas-node.md) lleva veintiocho
  fases diciendo.

> 🧭 **La frase honesta para el reporte:** *"esta imagen contiene N vulnerabilidades conocidas,
> inherentes a un stack EOL. Es aceptable para desarrollo y mantenimiento local, y no para
> exposición a red."* Eso es un veredicto. *"No hay problemas"* sería mentira, y *"no se puede
> usar"* sería falso.

---

## 6. 🧾 Provenance: cómo se construyó

**Provenance** responde una pregunta distinta a la del SBOM:

```text
SBOM        →  ¿QUÉ hay dentro?          lista de ingredientes
provenance  →  ¿CÓMO llegó a existir?    quién la construyó, desde qué fuente, con qué
```

Un documento de provenance registra el material de entrada —el repositorio, el commit—, el
constructor —qué sistema y qué versión—, los parámetros del build y cuándo ocurrió.

```bash
docker buildx build --provenance=mode=max \
  --platform linux/amd64 -t tu-usuario/legacy-node-toolchain:1.0.0 --push .

# consultarla
docker buildx imagetools inspect tu-usuario/legacy-node-toolchain:1.0.0 \
  --format '{{json .Provenance}}' | jq
```

**Por qué importa.** Con provenance, la pregunta *"¿esta imagen salió de nuestro repositorio o
alguien la publicó desde su portátil?"* tiene respuesta verificable. Sin ella, la única respuesta
es la confianza.

> 🧭 **La relación con los labels de [F28](28-publicar-la-imagen.md) §8.** `org.opencontainers.image.revision` dice el
> commit, y es un label que **cualquiera puede escribir a mano**. La provenance la genera el
> constructor y va firmada. Uno es documentación, el otro es evidencia.

---

## 7. 🔏 Firma: quién lo dice

Ni el SBOM ni la provenance dicen **quién** los afirma. Eso lo hace la firma.

**Cosign**, del proyecto Sigstore, es la herramienta estándar hoy.

```bash
# firmar (por digest — F27 §6.2: firmar un tag no significa nada)
cosign sign tu-usuario/legacy-node-toolchain@sha256:...

# verificar
cosign verify tu-usuario/legacy-node-toolchain@sha256:... \
  --certificate-identity-regexp '.*' --certificate-oidc-issuer-regexp '.*'
```

**Lo que hace posible el modelo *keyless* de Sigstore**, que es lo que ha hecho práctica esta
tecnología: en lugar de gestionar claves privadas eternamente, se firma con una identidad OIDC
—tu cuenta de GitHub, por ejemplo— y se usa un certificado de vida corta. La firma queda
registrada en un log público de transparencia, **Rekor**, que hace las firmas auditables.

### 7.1 Qué garantiza una firma, y qué no

> 🧭 **Garantiza:** que la imagen con **ese digest** fue firmada por **esa identidad** y que no
> ha sido modificada desde entonces.
>
> **No garantiza:** que la imagen sea segura, que no tenga vulnerabilidades, que el código sea
> correcto, ni que quien firmó tuviera buenas intenciones.

**Es una afirmación de origen e integridad, no de calidad.** Exactamente la misma distinción que
[F03](03-apt-y-utilidades.md) §5.4 hizo con las firmas de APT: *"firma válida significa origen e integridad, nunca
ausencia de CVE"*. La idea es la misma y ahora la aplicas tú.

---

## 8. 🧩 Que no se vuelva sopa de siglas

La tabla que ordena la fase entera:

| Mecanismo | Pregunta | Herramienta | Garantiza |
|---|---|---|---|
| **Checksum** | ¿bajé el archivo correcto? | `sha256sum` ([F06](06-instalacion-node.md)) | integridad de una descarga |
| **Digest** | ¿es esta imagen exacta? | el registry ([F27](27-registries-por-dentro.md)) | identidad de contenido |
| **SBOM** | ¿qué hay dentro? | Syft, BuildKit | inventario — **no** seguridad |
| **Escaneo** | ¿hay CVE conocidos? | Trivy, Grype | vulnerabilidades **conocidas hoy** |
| **Provenance** | ¿cómo se construyó? | BuildKit | origen del build |
| **Firma** | ¿quién lo afirma? | Cosign | origen e integridad — **no** calidad |

```text
LO QUE SE VERIFICA SOLO           LO QUE NECESITA CONFIANZA
checksum · digest                 quién firmó
son matemática pura               qué proceso produjo la provenance
                                  si el SBOM es completo
```

> 🧠 **El modelo mental:** los tres primeros responden **qué**; los tres últimos responden
> **quién** y **cómo**. Ninguno responde *"¿esto es seguro?"*, porque esa pregunta no tiene
> respuesta automática — depende del contexto de uso, y ese lo pones tú.

---

## 9. ⚠️ Errores comunes y diagnóstico

**"Genero SBOM, luego estoy seguro."** No. §4.1.

**El escaneo devuelve 400 vulnerabilidades y el equipo se bloquea.** Es lo esperado en un stack
EOL. §5.1, y la salida es documentar el contexto, no arreglar lo inarreglable.

**`cosign verify` falla en una imagen que firmaste.** ¿Firmaste el tag o el digest? Si firmaste
el tag y este se movió, la firma ya no corresponde. §7.

**El SBOM de amd64 y arm64 difieren mucho.** Algo de tu Dockerfile depende de la arquitectura.
§4.4.

**`--sbom=true` no produce nada.** Necesitas Buildx con un constructor capaz, y `--push` o un
exportador que soporte attestations.

**"La imagen tiene el label con el commit, así que sé de dónde salió."** Ese label lo escribe
quien construye, a mano. §6.

---

## 10. 📋 Checklist de validación

```text
[ ] Generaste el SBOM de tu imagen en SPDX y CycloneDX
[ ] Consultaste el SBOM con jq y encontraste un paquete concreto
[ ] Comparaste el SBOM de las dos arquitecturas
[ ] Sabes explicar por qué un SBOM no es un escáner
[ ] Escaneaste la imagen y guardaste el informe con la release
[ ] Tu reporte declara el contexto de uso, no solo el número de CVE
[ ] Generaste provenance con BuildKit y la consultaste
[ ] Distingues el label de revision de la provenance firmada
[ ] Firmaste una imagen POR DIGEST y verificaste la firma
[ ] Puedes explicar los seis mecanismos de §8 sin confundirlos
```

---

## 11. 🧪 Ejercicios de la Fase 29 (22)

## 🟢 Fácil — inventariar (1–5)

### 🟢 Ejercicio 1 — Tu primer SBOM

Genera el SBOM de `legacy-node-toolchain` con Syft y mira el resumen.

**Pregunta:** ¿cuántos paquetes tiene? ¿Te sorprende el número?

### 🟢 Ejercicio 2 — Por ecosistema

Ejecuta el primer `jq` de §4.3.

**Pregunta:** ¿cuántos son `deb`, cuántos `npm`, cuántos de otro tipo?

### 🟢 Ejercicio 3 — Busca un paquete

Averigua qué versión de `openssl`, `git` y `curl` hay en tu imagen, usando solo el SBOM.

**Objetivo:** responder sin arrancar un contenedor.

### 🟢 Ejercicio 4 — Los dos formatos

Genera SPDX y CycloneDX y compara su tamaño y estructura.

**Pregunta:** ¿cuál te resulta más fácil de consultar con `jq`?

### 🟢 Ejercicio 5 — Solo lo grave

Filtra por `HIGH,CRITICAL`.

**Pregunta:** ¿cuántas quedan? ¿Cuántas están en componentes que tu flujo ejecuta de verdad?

## 🟡 Intermedio — firmar y atestiguar (6–11)

### 🟡 Ejercicio 6 — Escanea

Ejecuta Trivy sobre tu imagen.

**Objetivo:** ver el número real y no asustarte. §5.

### 🟡 Ejercicio 7 — Provenance

Construye con `--provenance=mode=max` y consúltala.

**Objetivo:** encontrar el commit y el constructor dentro del documento.

### 🟡 Ejercicio 8 — Dos arquitecturas, un diff

Ejecuta la comparación de §4.4.

**Pregunta:** ¿cuántos paquetes difieren? ¿Los que difieren tienen sentido?

### 🟡 Ejercicio 9 — Attestations en el registry

Publica con `--sbom=true --provenance=true` y localiza las attestations en el registry con
`imagetools inspect`.

**Objetivo:** ver que viajan **con** la imagen y no en un archivo aparte.

### 🟡 Ejercicio 10 — Build contra escaneo

Compara el SBOM generado por BuildKit con el que produce Syft escaneando el resultado.

**Pregunta:** ¿difieren? ¿Cuál tiene más información y por qué? §4.5.

### 🟡 Ejercicio 11 — Firma y verifica

Firma tu imagen del registry local con Cosign y verifica la firma.

**Objetivo:** el ciclo completo, aunque sea con una clave local.

## 🟠 Difícil — cuando la garantía no garantiza (12–19)

### 🟠 Ejercicio 12 — Firma un tag que se mueve

Firma por tag, reapunta el tag a otra imagen, y verifica.

**Objetivo:** ver por qué §7 insiste en firmar por digest.

### 🟠 Ejercicio 13 — El label mentiroso

Construye una imagen con `org.opencontainers.image.revision` apuntando a un commit **que no
existe**.

**Objetivo:** comprobar que nadie te lo impide, y entender la diferencia de §6 entre
documentación y evidencia.

### 🟠 Ejercicio 14 — Escanea un SBOM guardado

Guarda el SBOM de hoy, y dentro de unos días ejecuta `trivy sbom` sobre él.

**Pregunta:** ¿aparecieron CVE nuevos sin que la imagen cambiara? Eso es exactamente para lo que
sirve guardar el SBOM.

### 🟠 Ejercicio 15 — El martes de la vulnerabilidad

Simula el escenario de §4.3: dado un paquete concreto, averigua cuáles de tus imágenes
publicadas lo contienen, usando solo SBOM guardados.

**Objetivo:** medir cuánto tardas. Compara con lo que tardarías escaneando cada imagen.

### 🟠 Ejercicio 16 — Clasifica veinte CVE

Toma veinte del informe de tu imagen y clasifícalos con los tres criterios de §5.1: está, se
ejecuta, hay vía de entrada.

**Objetivo:** llegar a una lista corta de los que de verdad importan en tu contexto. Suele ser
sorprendentemente corta.

### 🟠 Ejercicio 17 — La firma que no verifica

Provoca tres fallos de verificación distintos: imagen modificada, tag movido, e identidad
equivocada.

**Objetivo:** distinguir los tres errores, porque significan cosas muy distintas.

### 🟠 Ejercicio 18 — El SBOM que no coincide con la imagen

Un SBOM es una afirmación sobre una imagen, y como toda afirmación puede ser falsa. Provócalo:
genera el SBOM de una imagen, **modifícala** —añade un paquete con un `RUN apt-get install`—, y
verifica el SBOM viejo contra la imagen nueva.

**Objetivo:** demostrar que nada te avisa. El archivo sigue siendo un JSON válido, Trivy sigue
leyéndolo, y describe una imagen que ya no existe. Después encuentra las **dos** formas de
detectarlo: comparando el digest que el propio SBOM registra con el de la imagen, y
regenerándolo y haciendo `diff`.

**Pregunta:** ¿registra tu SBOM el digest de la imagen que describe? Compruébalo —no todos los
formatos ni todas las herramientas lo hacen igual—. Y la de fondo, que es la lección de la
fase: un SBOM **suelto** en un directorio no garantiza nada; una **attestation** firmada y
adjunta a la imagen sí. Explica con este experimento en la mano por qué la diferencia no es
burocrática, y qué ataque concreto impide la segunda que la primera no.

### 🟠 Ejercicio 19 — Tres escaneos, tres respuestas distintas

Ejecuta el escáner sobre la **misma** imagen de tres formas: contra la imagen, contra un SBOM
generado por Syft, y contra el SBOM que produjo BuildKit durante el build. Compara los tres
informes.

**Objetivo:** los recuentos no van a coincidir. Para cada diferencia, averiguar **por qué**: un
paquete que Syft infiere y BuildKit no registra, un `node_modules` que uno ve y el otro no,
una base de datos de vulnerabilidades actualizada entre dos ejecuciones.

**Pregunta:** ¿cuál de los tres es "el correcto"? La respuesta es que ninguno, y la útil es
otra: **¿cuál usarías para cada pregunta?** Para *"¿esta imagen tiene la CVE del martes?"*, para
*"¿qué instaló exactamente este build?"* y para *"¿qué había en la imagen que publicamos hace
seis meses?"*, la herramienta correcta es distinta en cada caso. Justifica las tres, y di cuál
de las tres preguntas **no** puedes responder si no guardaste nada en su momento.

## 🔴 Muy difícil — criterio sin siglas (20–22)

### 🔴 Ejercicio 20 — Audita una imagen ajena

Elige una imagen pública popular y averigua: ¿tiene SBOM? ¿provenance? ¿firma? ¿Qué contiene?

**Objetivo:** un informe de cinco líneas, y la conclusión honesta de cuánto sabes realmente de
lo que estabas a punto de usar.

### 🔴 Ejercicio 21 — Explica los seis mecanismos sin siglas

Escribe la explicación de la tabla de §8 para alguien que no ha hecho el curso, sin usar las
siglas SBOM, CVE, SLSA ni OIDC.

**Objetivo:** que quede claro qué pregunta responde cada mecanismo y —lo que más se confunde—
cuáles se verifican solos y cuáles necesitan que confíes en alguien. Si tienes que usar una
sigla, defínela en la misma frase.

### 🔴 Ejercicio 22 — El párrafo de seguridad de tu reporte

Escribe la sección de seguridad del `VALIDATION-REPORT.md` de tu proyecto.

**Objetivo:** que diga el número de CVE, el contexto de uso, qué riesgos aceptas explícitamente
y cuáles mitigarías si el contexto cambiara. Ni "no hay problemas" ni "no se puede usar".

## 🔥 Opcionales

### 🔥 Ejercicio 23 — Rekor

Busca en el log de transparencia de Sigstore la entrada de una firma pública.

**Objetivo:** ver qué es un log de transparencia y por qué hace auditables las firmas.

### 🔥 Ejercicio 24 — SBOM de tu proyecto, no de la imagen

Genera el SBOM del `node_modules` de tu proyecto legacy.

**Pregunta:** ¿cuántas dependencias transitivas tienes? Compáralo con las que declara tu
`package.json`. La diferencia suele ser de dos órdenes de magnitud.

## 💀 Boss fight

### 💀 Ejercicio 25 — Boss fight: la cadena completa

Produce una release del toolchain con la cadena entera: construida con provenance, con SBOM
adjunto, escaneada con el informe guardado, firmada por digest, publicada multi-plataforma, y
con un documento que permita a **otra persona verificar todo** sin confiar en ti.

**Objetivo:** la entrega es el conjunto de comandos de verificación que un tercero ejecutaría, en
orden, y qué debería obtener en cada uno. Y termina con lo más difícil de escribir: **qué queda
sin garantizar aun habiendo hecho todo esto**. Porque queda bastante —§8—, y decirlo es lo que
separa la seguridad real del teatro de seguridad.

---

## 12. 📚 Referencias

**SBOM**
- Syft: https://github.com/anchore/syft
- SPDX: https://spdx.dev
- CycloneDX: https://cyclonedx.org
- SBOM en BuildKit: https://docs.docker.com/build/metadata/attestations/sbom/

**Escaneo**
- Trivy: https://trivy.dev
- Grype: https://github.com/anchore/grype

**Provenance y firma**
- Attestations de BuildKit: https://docs.docker.com/build/metadata/attestations/
- SLSA, el marco de referencia: https://slsa.dev
- Sigstore: https://www.sigstore.dev · Cosign: https://docs.sigstore.dev/cosign/overview/
- Rekor: https://docs.sigstore.dev/logging/overview/

> ⚠️ **Es el área del curso que más rápido evoluciona.** Los formatos son razonablemente
> estables; las herramientas y sus comandos cambian varias veces al año, y el modelo keyless de
> Sigstore es reciente. Verifica la sintaxis exacta antes de meterla en un pipeline. Enlaces
> revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la documentación de Syft primero, que es la más práctica; SLSA
solo si te interesa el marco conceptual completo.

---

## 13. 🏁 Resultado de la fase

```text
TRES PREGUNTAS  ¿qué contiene?  → SBOM        (Syft, BuildKit)
                ¿cómo se hizo?  → provenance  (BuildKit)
                ¿quién lo dice? → firma       (Cosign, Sigstore)

SBOM            inventario, NO escáner
                SPDX o CycloneDX
                su valor real: responder "¿tengo yo eso?" sin volver a escanear
                📝 no existía en 2018 — producirlo hoy mejora el original

ESCANEO         esta imagen VA a hacer ruido, y es lo esperado
                CVE conocido ≠ exploit: está + se ejecuta + hay vía de entrada
                documenta el contexto, no lo ignores ni te bloquees

PROVENANCE      el label revision lo escribe cualquiera
                la provenance la genera el constructor y va firmada

FIRMA           por DIGEST, nunca por tag
                garantiza origen e integridad — NO calidad ni ausencia de CVE
                la misma distinción que las firmas de APT en F03
```

> **La señal de que quedó bien:** *"puedo entregar una imagen legacy con su inventario, su
> procedencia y su firma — y explicar en una frase qué garantiza cada una de las tres y qué
> sigue sin garantizar ninguna."*

En **[F30](30-troubleshooting-metodo-y-herramientas.md)** cambiamos al último bloque del curso: el método de diagnóstico. Porque hasta aquí has
aprendido cómo funciona todo, y ahora toca qué hacer cuando no funciona.
