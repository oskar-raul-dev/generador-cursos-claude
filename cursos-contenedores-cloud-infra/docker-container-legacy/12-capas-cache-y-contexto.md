# 🧬 Parte II · Fase 12 — Capas, caché y contexto: el build por dentro

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** la Parte I hecha. Esta fase abre lo que [F07](07-build-de-la-imagen.md) usó sin explicar del todo
> **Fecha de verificación ejecutada:** 6 de septiembre de 2026 — las salidas de `CACHED` de §4.3 están corridas sobre Docker 29.6.2 con BuildKit
> **Estado de la imagen al terminar:** sin cambios. Lo que cambia es cuánto entiendes de cómo se produjo
> **Objetivo:** dejar de tratar la caché como magia negra — saber por qué un paso se reutiliza, qué es realmente una capa, y en qué se diferencian un tag, un ID y un digest

---

## 1. 🧭 Dónde estamos

Bienvenido a la Parte II. La Parte I te dejó un entorno que funciona; esta parte abre cada
comodidad que te dio hecha, y empieza por la que más se usa sin entender: **el build**.

[F07](07-build-de-la-imagen.md) te enseñó a construir. Te dijo que había una caché, que las capas existían y que el
orden importaba — y te mandó aquí a por el mecanismo. Aquí está.

```text
F07 (Parte I)                      F12 (esta fase)
─────────────                      ───────────────
"construye con este comando"       por qué el paso 4 dice CACHED
"el orden importa"                 qué regla exacta lo decide
"hay capas"                        qué es una capa y qué contiene
"usa tags, no latest"              tag ≠ image ID ≠ digest
```

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder explicar:

- Qué pregunta responde la caché y con qué regla decide reutilizar o reconstruir.
- Por qué un `cache miss` invalida **todo lo que viene después**, y qué estrategia se
  deriva de eso.
- Qué invalida exactamente cada instrucción: `RUN`, `COPY`, `ADD`, `ARG`.
- Qué es una capa en el modelo OCI, y por qué una imagen es más que una pila de capas.
- La diferencia entre **tag**, **image ID** y **digest**, y cuál de los tres es identidad
  real.
- Hasta dónde llega la reproducibilidad de este laboratorio, sin vender humo.

---

## 3. 🚧 Qué NO entra todavía

- **Cómo se montan las capas en runtime** —`lowerdir`, `upperdir`, whiteouts, y la
  demostración con números de por qué borrar un archivo agranda la imagen— → **[F13](13-overlayfs-y-copy-on-write.md)**, que
  es la continuación directa de §6.
- **La construcción multiplataforma** con Buildx y QEMU → **[F21](21-arquitecturas-y-emulacion.md)**.
- **Registries, manifests y cómo viajan los digests** → **[F27](27-registries-por-dentro.md)**.
- **Reproducibilidad de la cadena de suministro**: SBOM, provenance, firma → **[F29](29-supply-chain-sbom-firma.md)**.
- El **catálogo de fallos de build** → **[F31](31-catalogo-de-fallos-i.md)**.

---

## 4. ⚡ La caché: qué pregunta responde

Sin caché, cada build de un Dockerfile de cincuenta pasos repetiría los cincuenta aunque no
hubiera cambiado nada. Sería absurdo, así que el builder guarda resultados y ante cada
instrucción se pregunta:

> **¿Ya tengo un resultado válido para este paso, con estas mismas entradas?**

Si sí, **cache hit**: reutiliza. Si no, **cache miss**: reconstruye.

La parte que importa es qué cuenta como "estas mismas entradas", porque no es igual para
todas las instrucciones.

### 4.1 La regla que lo explica casi todo

El builder recorre las instrucciones **en orden**, y en cuanto una falla el resto cae con
ella:

```text
paso 1 → cache hit
paso 2 → cache hit
paso 3 → cache MISS      ← aquí cambió algo
paso 4 → reconstruir     ← aunque su instrucción sea idéntica
paso 5 → reconstruir
paso 6 → reconstruir
```

**Un paso reconstruido cambia el estado sobre el que trabajan los siguientes**, así que sus
resultados guardados dejan de ser válidos aunque su instrucción no haya cambiado ni una
coma. De ahí sale la estrategia de §5.

### 4.2 Qué invalida cada instrucción

| Instrucción | Se invalida cuando… | Detalle que sorprende |
|---|---|---|
| `FROM` | cambia la imagen base resuelta | con un tag móvil puede cambiar bajo tus pies; con `--pull` se comprueba siempre |
| `RUN` | **cambia el texto del comando** | y **solo** eso. El builder no sabe que `apt-get update` traería paquetes nuevos hoy |
| `COPY` / `ADD` | cambia el **contenido** de los archivos copiados | por contenido, no por fecha de modificación |
| `ARG` | cambia su valor, y solo si la instrucción lo usa | invalida desde el punto donde se declara |
| `ENV`, `LABEL`, `WORKDIR` | cambia su valor | son metadatos: baratos de reconstruir |

> 🧠 **El `RUN` es el que engaña.** El builder compara **la cadena de texto**, no el
> resultado. Un `RUN apt-get update && apt-get install -y curl` idéntico se reutiliza
> indefinidamente, aunque el repositorio tenga paquetes nuevos desde hace meses. En un
> laboratorio legacy eso es casi siempre lo que quieres — reproducibilidad — pero conviene
> saberlo, porque es la causa del clásico *"actualicé y no se actualizó nada"*.

Y sobre `COPY`, un matiz que sorprende al revés: **el `mtime` no siempre rompe la caché**.
BuildKit compara el contenido, así que tocar un archivo sin modificarlo no invalida nada.

### 4.3 Las dos reglas, medidas

Esto no hay que creérselo tampoco. Con un Dockerfile de cinco pasos y un `COPY` en medio:

```dockerfile
FROM debian/eol:buster
RUN echo "paso 1" > /p1
RUN echo "paso 2" > /p2
COPY app.txt /app.txt
RUN echo "paso 3" > /p3
```

Construye una vez para poblar la caché, después haz `touch app.txt` —solo la fecha, mismo
contenido— y vuelve a construir:

```text
#6 [2/5] RUN echo "paso 1" > /p1
#6 CACHED
#7 [4/5] COPY app.txt /app.txt
#7 CACHED
#8 [3/5] RUN echo "paso 2" > /p2
#8 CACHED
#9 [5/5] RUN echo "paso 3" > /p3
#9 CACHED
```

Los cinco pasos reutilizados: **el `mtime` no cuenta**. Ahora cambia de verdad el contenido del
archivo y repite:

```text
#6 [2/5] RUN echo "paso 1" > /p1
#6 CACHED
#7 [3/5] RUN echo "paso 2" > /p2
#7 CACHED
#8 [4/5] COPY app.txt /app.txt
#9 [5/5] RUN echo "paso 3" > /p3
```

Ahí están las dos reglas de esta sección en cuatro líneas. El `COPY` pierde su `CACHED`,
porque el contenido cambió. Y el `RUN echo "paso 3"` lo pierde también **aunque su texto sea
idéntico letra por letra**, porque va después: es la cascada de §4.1, ocurriendo delante de ti.

> 💡 **Dos detalles de lectura de esa salida, que despistan la primera vez.** Los números `#6`,
> `#7`… son identificadores internos de BuildKit y **no siguen el orden del Dockerfile**;
> fíjate en los `[n/5]`, que sí. Y en la primera pasada verás el `[4/5] COPY` resolverse antes
> que el `[3/5] RUN`: BuildKit paraleliza lo que puede, y leer el contexto no depende de que
> el `RUN` anterior haya terminado. La cascada de invalidación sigue siendo estrictamente en
> orden; lo que se adelanta es el trabajo, no la decisión.

El ejercicio 7 te pide reproducirlo tú.

---

## 5. 🗂️ El orden del Dockerfile es una estrategia

De §4.1 sale una consecuencia práctica. Compara:

```dockerfile
# ❌ lo volátil primero
COPY archivo-que-cambia-cada-5-minutos /tmp/
RUN instalar-500-paquetes
```

```dockerfile
# ✅ lo caro y estable primero
RUN instalar-500-paquetes
COPY archivo-que-cambia-cada-5-minutos /tmp/
```

En el primero, cada cambio del archivo te obliga a reinstalar quinientos paquetes que no
tienen nada que ver con él.

> 🧭 **La regla:** coloca antes las operaciones **caras y estables**, y después las entradas
> **volátiles**. No es una ley matemática —a veces la semántica no lo permite— pero es la
> heurística que más tiempo ahorra.

**Nuestro Dockerfile ya se beneficia de esto**, y no por casualidad: el `RUN` de APT y la
descarga de los cuatro Node —lo más caro, minutos— van antes que el `COPY` de los scripts,
que son lo que más se toca mientras desarrollas.

### 5.1 Las banderas que la desactivan, y cuándo usarlas

```bash
docker build --no-cache ...    # ignora la caché entera
docker build --pull ...        # vuelve a resolver el FROM
```

**`--no-cache`** es un martillo. Sirve para comprobar que tu Dockerfile construye desde cero
—que es distinto de que construya— y para descartar la caché como causa de un fallo. No es
la solución a "no veo mi cambio": eso significa que tu modelo de qué invalida qué está mal,
y arreglarlo vale más que reconstruir a ciegas cada vez.

**`--pull`** solo afecta al `FROM`. Es lo que quieres cuando sospechas que la base cambió, y
lo que **no** quieres en este laboratorio: `debian/eol:buster` no debería moverse, y si se
mueve, quieres enterarte, no absorberlo en silencio.

Y para limpiar de verdad:

```bash
docker builder prune          # borra caché de build no usada
```

> ⚠️ **`docker system prune -a --volumes` como primer reflejo es un anti-patrón.** Borra
> imágenes, contenedores, redes **y volúmenes** — incluidos los `node_modules` de todos tus
> proyectos, que tardarán en reinstalarse. Y borra la evidencia que necesitabas para
> diagnosticar. **[F30](30-troubleshooting-metodo-y-herramientas.md)** lo trata entre los anti-patrones con nombre propio.

---

## 6. 🧱 Qué es una capa, de verdad

El modelo mental de "una imagen es una pila de capas" es útil y está incompleto. En el
modelo OCI una imagen es:

```mermaid
flowchart TD
    M["manifest"] --> C["config<br/>metadatos: Env, Entrypoint, Cmd, WorkingDir, Labels, arquitectura"]
    M --> L["layers[]<br/>los cambios de filesystem, cada uno un blob comprimido"]
```

La imagen es una **estructura compuesta**, no un tarball gigante. El manifest apunta a un
config y a una lista de capas; cada capa es un blob independiente con su propio digest, que
es lo que permite compartirlas entre imágenes.

Míralo en tu propia imagen:

```bash
docker image inspect legacy-node-toolchain:phase09 \
  --format '{{len .RootFS.Layers}} capas'
docker image inspect legacy-node-toolchain:phase09 \
  --format '{{json .Config}}' | jq 'keys'
docker image history legacy-node-toolchain:phase09
```

`docker image history` es la herramienta que conecta las dos vistas: te dice qué instrucción
produjo cada capa y cuánto pesa.

### 6.1 Capas como changesets, y la pregunta que abre [F13](13-overlayfs-y-copy-on-write.md)

Cada capa es un **conjunto de cambios** respecto a la anterior:

```mermaid
flowchart TD
    B["base"] --> C1["capa 1: agrega A"] --> C2["capa 2: agrega B"] --> C3["capa 3: elimina A"]
```

El filesystem final no muestra `A`. Pero **los bytes que llegaron en la capa 1 no
desaparecieron del blob de la capa 1**: siguen ahí, y siguen viajando con la imagen. La capa
3 solo anota que `A` no debe verse.

De ahí salen dos consecuencias que llevas arrastrando desde [F03](03-apt-y-utilidades.md):

- **Borrar en una capa posterior no reduce el tamaño.** Es la razón de que APT, los tarballs
  de Node y su limpieza vayan en un solo `RUN`.
- **Un secreto borrado sigue en la imagen.** Si copiaste un `.env` y lo borraste después,
  ahí está. El ejercicio 16 de [F07](07-build-de-la-imagen.md) te hizo crear exactamente ese caso.

Y deja abierta la pregunta complementaria: si las capas son diffs guardados por separado y
de solo lectura, **¿cómo termina el proceso viendo un único `/` en el que además puede
escribir?**

La respuesta es **OverlayFS**, y tiene fase propia: **[F13](13-overlayfs-y-copy-on-write.md)** las monta a mano, caza un
whiteout en el disco y mide con números por qué un `rm` en una capa posterior no adelgaza la
imagen. Esta fase te deja justo en la puerta.

---

## 7. 🏷️ Tag, image ID y digest: tres identidades

Se confunden constantemente y son cosas distintas.

```text
legacy-node-toolchain:phase09      ← TAG: un nombre humano, mutable
sha256:8180022ddefd…  (Image ID)   ← identifica la imagen en TU máquina
sha256:3207f48cbea2…  (Digest)     ← identidad de contenido, la misma en todas partes
```

Esos dos hashes no son de adorno: el primero es el de la imagen del laboratorio construida el
día que se escribió esta fase, y el segundo el de `debian/eol:buster`.

**El tag es un puntero, no una identidad.** Varios tags pueden apuntar a la misma imagen, y
un tag puede reapuntarse a otra sin avisar:

```bash
docker tag legacy-node-toolchain:phase09 legacy-node-toolchain:probando
docker image ls   # dos filas, un solo IMAGE ID
```

Eso es lo que quiere decir [F02](02-dockerfile-esencial.md) con que `latest` no tiene poderes místicos: es un tag
corriente, con el único rasgo de ser el que se asume cuando no pones ninguno. No significa
"la última", ni "la buena", ni "la estable".

**El image ID identifica la imagen en tu máquina.** Es un digest —de qué exactamente depende
de cómo guarde las imágenes tu Docker, y eso lo desmenuza [F27](27-registries-por-dentro.md)
§6.1 con las cuatro identidades del formato OCI en la mano—. Lo que aquí importa es su
comportamiento: si construyes dos veces sin cambios, obtienes el mismo ID; si cambias un
`LABEL`, cambia.

> 💸 **Deuda declarada, y con fecha de pago.** Vas a leer en muchos sitios —y hasta hace poco
> en esta misma fase— que el image ID *es* el digest del objeto de configuración. Con el
> almacenamiento clásico de Docker era cierto; con el image store de containerd que traen las
> versiones recientes, ya no. La corrección completa, medida contra la máquina, está en
> **[F27](27-registries-por-dentro.md) §6.1**. Por ahora quédate con "identifica la imagen
> localmente" y no le pongas apellido.

**El digest es la identidad de contenido en un registry.** Es lo que te permite decir "esta
imagen exacta" sin depender de que nadie mueva un tag:

```bash
docker image inspect legacy-node-toolchain:phase09 --format '{{.Id}}'
docker image ls --digests
```

```dockerfile
FROM debian/eol:buster@sha256:<digest>     # inmutable de verdad
FROM debian/eol:buster                     # lo que usamos: legible, y confía en el tag
```

> 🧭 **Por qué el curso no pinnea la base por digest.** Es una **deuda 💸 declarada**: el
> digest hace el Dockerfile ilegible y `debian/eol:buster` es un tag de archivo que no
> debería moverse. Para un laboratorio local, el nombre legible gana. Para una imagen que
> publicas o que sostiene un pipeline, el digest gana — y ahí lo trata **[F27](27-registries-por-dentro.md)**.

---

## 8. 🎛️ Build args, en profundidad

[F02](02-dockerfile-esencial.md) presentó `ARG`; [F06](06-instalacion-node.md) lo usó para las cuatro versiones de Node. Aquí van las tres cosas
que hay que saber cuando parametrizas de verdad.

**El alcance es acotado.** Un `ARG` declarado antes del primer `FROM` solo vive ahí; para
usarlo después hay que volver a declararlo dentro de la etapa. Es la causa del clásico "mi
build arg llega vacío".

**Invalida la caché desde donde se usa.** Cambiar `DEFAULT_NODE_VERSION` no obliga a
redescargar los tarballs si esa variable se usa después del `RUN` que los baja — que es
justo cómo está ordenado el Dockerfile de [F06](06-instalacion-node.md). Compruébalo con el ejercicio 9.

**Y quedan registrados en la imagen.** Es lo importante:

```bash
docker image history --no-trunc legacy-node-toolchain:phase09 | grep -i arg
```

> 🚨 **Por eso un `ARG` no sirve para secretos.** El valor con el que construiste queda en el
> historial de la imagen y viaja con ella al registry. Lo mismo vale para `ENV`, que además
> es legible con un `docker inspect` cualquiera. La forma correcta —los *build secrets* de
> BuildKit, que se montan durante un `RUN` y no dejan rastro— es de **[F29](29-supply-chain-sbom-firma.md)**.

---

## 9. 📐 Reproducibilidad: hasta dónde llegamos

Un apartado honesto, porque es fácil prometer de más.

**Lo que este laboratorio sí garantiza:**

- La misma imagen base, por tag de archivo que no se mueve.
- Las mismas cuatro versiones de Node, verificadas por SHA-256 dentro del build.
- Los mismos paquetes de Debian, servidos desde un archivo histórico congelado.
- El mismo `package-lock.json` para las dependencias de tu proyecto.

**Lo que NO garantiza, y conviene decirlo:**

- **Bit a bit no.** Dos builds del mismo Dockerfile producen imágenes con timestamps
  distintos, y por tanto digests distintos. La reproducibilidad *determinista* exige fijar
  `SOURCE_DATE_EPOCH` y bastante más.
- **Las fuentes externas pueden desaparecer.** `nodejs.org/dist` y `archive.debian.org`
  siguen en pie hoy. Si mañana no, tu build "reproducible" se murió y no te avisó. **[a13](a13-air-gapped.md)**
  y **[F29](29-supply-chain-sbom-firma.md)** tratan qué hacer con eso.
- **`apt-get install` sin versión exacta resuelve lo que haya.** En un archivo congelado eso
  es estable en la práctica; no es una garantía.
- **Los paquetes de npm no fijados en el lock** —dependencias opcionales, scripts de
  instalación que descargan— pueden variar.

> 🧠 **El nivel que sí alcanzamos** tiene nombre: *repetible*, no *reproducible bit a bit*.
> Si borro la imagen y reconstruyo mañana en otra máquina, obtengo un entorno
> **funcionalmente idéntico**. Es lo que necesita un laboratorio de mantenimiento, y es
> mucho más de lo que tenías al empezar el curso.

---

## 10. 🦭 El build en Podman

Podman construye con **Buildah**, no con BuildKit. Para lo que hace este curso el Dockerfile
es el mismo y el resultado equivalente, pero hay cuatro diferencias que conviene tener
localizadas:

- **`podman build` acepta un contexto sin `-f` igual que Docker**, pero su resolución de
  rutas relativas tiene matices propios.
- **`podman buildx build`** existe como capa de compatibilidad y no es idéntico a Buildx.
- **La política de `pull`** por defecto difiere: Podman tiende a comprobar más.
- **La implementación de caché no es la misma**, así que no esperes que un `CACHED` de
  Docker se traduzca paso a paso.

**[F24](24-docker-y-podman-arquitectura.md)** compara los dos constructores en serio. La regla de este curso sigue vigente: si no
está verificado en Podman, se dice que no está verificado.

---

## 11. ⚠️ Errores comunes y diagnóstico

**"Cambié el Dockerfile y no se aplica."** Casi nunca es un bug de la caché: es que tu
cambio está **después** del paso que crees. `--progress=plain` te dice exactamente qué pasos
dijeron `CACHED`.

**"`apt-get update` no trae paquetes nuevos."** Correcto y esperado: el `RUN` es idéntico, se
reutiliza. §4.2.

**"Borré el archivo pero la imagen pesa igual."** §6.1, y su demostración con números está en
**[F13](13-overlayfs-y-copy-on-write.md)**.

**"Mi build arg llega vacío."** Alcance de `ARG` — §8.

**"El build funciona con caché y falla con `--no-cache`."** Tu Dockerfile depende de algo que
la caché conservaba y que ya no está en el repositorio. Es el ejercicio 17 de [F07](07-build-de-la-imagen.md) y es un
hallazgo serio: significa que tu build **no** construye desde cero.

**"Dos máquinas producen imágenes con digests distintos."** Normal — §9. Compara el
comportamiento, no el hash.

---

## 12. 📋 Checklist de validación

```text
[ ] Puedes predecir qué pasos se invalidan ante cinco cambios distintos, y aciertas
[ ] docker image history muestra qué instrucción produjo cada capa y su tamaño
[ ] Sabes cuántas capas tiene tu imagen y cuál es la más grande
[ ] Puedes explicar por qué un RUN idéntico no se reconstruye aunque el repo cambie
[ ] Distingues tag, image ID y digest, y sabes cuál es identidad real
[ ] Dos tags apuntando a la misma imagen: comprobado con docker image ls
[ ] Sabes por qué un ARG no sirve para secretos, y lo has visto en el history
[ ] Puedes decir qué reproducibilidad promete este laboratorio y cuál no
[ ] docker builder prune ejecutado a conciencia, no como reflejo
```

---

## 13. 🧪 Ejercicios de la Fase 12 (25)

## 🟢 Fácil — observar la caché (1–6)

### 🟢 Ejercicio 1 — Dos builds seguidos

Construye el canónico dos veces sin tocar nada, cronometrando las dos.

**Pregunta:** ¿qué pasos no dijeron `CACHED` en el segundo, y por qué esos y no otros?

### 🟢 Ejercicio 2 — Cuenta las capas

Ejecuta `docker image inspect --format '{{len .RootFS.Layers}}'` y `docker image history`.

**Pregunta:** ¿coincide el número de capas con el número de instrucciones? ¿Por qué no?

### 🟢 Ejercicio 3 — La capa más grande

Ordena la salida de `docker image history` por tamaño.

**Pregunta:** ¿cuál es la más grande y te sorprende? Relaciónalo con lo que hace ese `RUN`.

### 🟢 Ejercicio 4 — Tres tags, una imagen

Etiqueta la misma imagen tres veces y mira `docker image ls`.

**Objetivo:** ver tres filas con un solo `IMAGE ID` e interiorizar que el tag es un puntero.

### 🟢 Ejercicio 5 — Cambia un `LABEL`

Modifica solo la descripción del `LABEL` y reconstruye.

**Pregunta:** ¿cambió el `IMAGE ID`? ¿Se reconstruyó algo más?

### 🟢 Ejercicio 6 — `--no-cache` y el reloj

Construye con `--no-cache` y compara el tiempo con el ejercicio 1.

**Objetivo:** poner número a lo que la caché te ahorra cada día.

## 🟡 Intermedio — usar la caché con criterio (7–14)

### 🟡 Ejercicio 7 — El `mtime` no basta

Haz `touch` sobre `scripts/select-node` sin modificar su contenido y reconstruye.

**Pregunta:** ¿se invalidó el `COPY`? ¿Qué te dice eso sobre qué compara el builder?

### 🟡 Ejercicio 8 — Predice cinco invalidaciones

Antes de ejecutar nada, **predice** qué pasos se invalidan al: (a) añadir un paquete al `RUN`
de APT; (b) cambiar el `WORKDIR`; (c) editar `scripts/docker-entrypoint.sh`; (d) cambiar
`NODE10_VERSION`; (e) cambiar el `LABEL` de la línea 5. Después compruébalo.

**Objetivo:** el ejercicio central de la fase. Cada fallo de predicción es un hueco en tu
modelo mental, y el (e) es el que más gente falla.

### 🟡 Ejercicio 9 — `ARG` y el orden

Cambia `DEFAULT_NODE_VERSION` y reconstruye. Después cambia `NODE10_VERSION` y reconstruye.

**Pregunta:** ¿por qué uno redescarga los tarballs y el otro no? ¿Podrías reordenar el
Dockerfile para que ninguno de los dos lo hiciera?

### 🟡 Ejercicio 10 — El `ARG` en el `history`

Construye con `--build-arg DEFAULT_NODE_VERSION=16.20.2` y busca ese valor con
`docker image history --no-trunc`.

**Objetivo:** ver el valor con tus ojos y entender por qué §8 dice lo que dice.

### 🟡 Ejercicio 11 — Digest de la base

Averigua el digest actual de `debian/eol:buster` con `docker image inspect` y construye una
variante que lo pinnee en el `FROM`.

**Pregunta:** ¿qué ganaste y qué perdiste en legibilidad? ¿Cuándo compensa?

### 🟡 Ejercicio 12 — Dos builds, dos digests

Construye la misma imagen dos veces con `--no-cache` y compara sus `IMAGE ID`.

**Pregunta:** ¿son iguales? Si no, ¿qué lo impide? Ahí tienes §9 en una línea.

### 🟡 Ejercicio 13 — `docker builder prune`

Mira el espacio que ocupa tu caché de build con `docker system df`, limpia y vuelve a mirar.

**Pregunta:** ¿cuánto liberaste? ¿Y cuánto vas a tardar en el próximo build?

### 🟡 Ejercicio 14 — Lee el `history` sin truncar

`docker image history` por defecto recorta los comandos justo donde empieza lo interesante.
Quítale la mordaza:

```bash
docker image history --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' \
  legacy-node-toolchain:phase12 | head -20
```

**Objetivo:** emparejar cada línea con su instrucción del `Dockerfile` canónico y separar las
que pesan `0B` de las que pesan de verdad.

**Pregunta:** ¿cuántas líneas de `0B` hay y a qué instrucciones corresponden? Ahora la parte
que importa para el resto de la fase: si esas instrucciones no añaden bytes, **¿por qué
aparecen como capas y por qué invalidan la caché de lo que viene detrás?**

## 🟠 Difícil — medir y diagnosticar (15–21)

### 🟠 Ejercicio 15 — Reordena para ganar caché

Mueve el `COPY scripts/` al principio del Dockerfile, antes del `RUN` de APT, y reconstruye
editando un script.

**Objetivo:** medir cuánto tiempo cuesta el orden malo, con el cronómetro y no con la
intuición.

### 🟠 Ejercicio 16 — El build que solo funciona cacheado

Construye el canónico. Borra `scripts/select-node` del disco. Reconstruye con caché, y
después con `--no-cache`.

**Pregunta:** ¿por qué el primero funcionó? ¿Qué te dice eso sobre usar un build verde como
prueba de que el repositorio está completo? Es un fallo real y frecuente en CI.

### 🟠 Ejercicio 17 — Caché forense

Alguien te dice que su imagen "tiene una versión vieja de un script". Sin acceso a su
Dockerfile, usando solo `docker image history --no-trunc` y `docker image inspect`, determina
qué instrucciones se ejecutaron y en qué orden.

**Objetivo:** entrenar la lectura inversa de una imagen ajena.

### 🟠 Ejercicio 18 — El archivo fantasma

Construye una imagen que cree un archivo de 200 MB en una capa y lo borre en la siguiente.
Mide con `docker image ls` y con `docker image history`.

**Pregunta:** ¿cuánto pesa la imagen? ¿Dónde están esos 200 MB? Guarda los números: **[F13](13-overlayfs-y-copy-on-write.md)**
los explica y los mide otra vez con el mecanismo a la vista.

### 🟠 Ejercicio 19 — Podman contra Docker

Construye el canónico con los dos motores y compara número de capas, tamaño y el
comportamiento de la caché al reconstruir.

**Pregunta:** ¿qué coincide y qué no? Anota las diferencias: **[F24](24-docker-y-podman-arquitectura.md)** las explica.

### 🟠 Ejercicio 20 — La caché que no es tuya: `--cache-from`

Hasta aquí la caché ha vivido en tu máquina. En un CI no hay tal cosa: cada job arranca
limpio. La solución es exportar la caché a algún sitio y volver a importarla. Simula las dos
máquinas en una sola:

```bash
# "máquina A": construye y exporta la caché a un directorio
docker buildx build --platform linux/amd64 \
  --cache-to type=local,dest=/tmp/bkcache,mode=max \
  -t legacy-node-toolchain:cache-a --load .

# "máquina B": borra la caché local y reconstruye importando la de A
docker builder prune -af
docker buildx build --platform linux/amd64 \
  --cache-from type=local,src=/tmp/bkcache \
  -t legacy-node-toolchain:cache-b --load .
```

**Pregunta:** ¿cuánto tardó el segundo build y qué pasos dijeron `CACHED`? Compara con lo que
tardaría desde cero. Y la pregunta de diseño: `mode=max` exporta también las capas
intermedias y ocupa mucho más — mide los dos con `du -sh /tmp/bkcache` y di en qué caso
compensa cada uno.

**Objetivo:** entender que la caché es un artefacto transportable, y no una propiedad mágica
de tu portátil.

### 🟠 Ejercicio 21 — Pesa y limpia la caché de build

La caché de BuildKit crece hasta ocupar decenas de gigas sin que nadie se entere, porque no
aparece en `docker image ls`. Mírala de frente:

```bash
docker system df -v | head -20
docker buildx du --verbose | tail -20
```

**Objetivo:** decir cuánto ocupan las imágenes, los contenedores, los volúmenes y **la caché
de build** por separado, y cuánto de eso es reclamable.

**Pregunta:** ahora ejecuta `docker builder prune` —sin `-a`— y vuelve a medir. ¿Qué borró y
qué no? Reconstruye el canónico y cronometra: ¿perdiste la caché útil o solo la basura?
Guarda la diferencia entre `prune` y `prune -a`, porque el segundo es de los comandos que se
ejecutan una vez y se lamentan durante veinte minutos.

## 🔴 Muy difícil — reproducibilidad y criterio (22–25)

### 🔴 Ejercicio 22 — Optimiza sin romper nada

Reordena el `Dockerfile` canónico para minimizar el tiempo de reconstrucción en el escenario
más frecuente —editas un script— **sin cambiar lo que la imagen contiene**.

**Objetivo:** demostrarlo con dos mediciones, antes y después. Y decir qué escenario
empeoraste a cambio, porque toda reordenación mejora un caso y empeora otro.

### 🔴 Ejercicio 23 — Escribe la promesa de reproducibilidad

Redacta el párrafo que le entregarías a tu equipo respondiendo: *"si construimos esta imagen
dentro de un año, ¿obtenemos lo mismo?"*.

**Objetivo:** que sea honesto, específico y accionable. Tiene que decir qué está garantizado,
qué no, **qué fuentes externas son el punto débil** y qué haríais para reducir esa
dependencia. Si tu párrafo dice "sí, es reproducible", vuelve a §9.

### 🔴 Ejercicio 24 — Dos máquinas, la misma imagen, ¿el mismo digest?

§9 promete reproducibilidad "hasta cierto punto". Este ejercicio te hace encontrar el punto.
Construye el canónico dos veces con `--no-cache`, con el mayor intervalo que puedas entre las
dos —ideal si es en dos máquinas o en dos días distintos— y compáralas capa por capa:

```bash
docker image inspect legacy-node-toolchain:r1 --format '{{json .RootFS.Layers}}' | jq -r '.[]' > r1.txt
docker image inspect legacy-node-toolchain:r2 --format '{{json .RootFS.Layers}}' | jq -r '.[]' > r2.txt
diff r1.txt r2.txt
```

**Objetivo:** para **cada** capa que difiera, nombrar la causa concreta —no "cosas del
build"—: qué archivo cambió y por qué. Las candidatas están todas en la fase: timestamps,
índices de APT descargados en momentos distintos, el orden de un `tar`, un tarball de
`nodejs.org` que se sirvió desde otro mirror.

**Pregunta de cierre:** de las diferencias que encontraste, ¿cuáles podrías eliminar y a qué
precio? Escribe la lista ordenada por relación coste/beneficio, y termina diciendo si merece
la pena para **este** laboratorio. La respuesta honesta puede ser que no.

### 🔴 Ejercicio 25 — La caché que sigue publicando el bug

Un escenario real, y de los que cuestan un incidente. Tu pipeline construye la imagen cada
noche con este `Dockerfile`:

```dockerfile
FROM debian/eol:buster
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

Se publica un parche de seguridad para `curl`. Pasan las noches y la imagen que sale del
pipeline **sigue trayendo la versión vulnerable**, aunque el build dice `Successfully built`
todas las noches y nadie tocó el `Dockerfile`.

**Objetivo:** explicar el mecanismo exacto con §4.2 en la mano —qué compara el builder para
ese `RUN` y qué **no** compara—, y demostrarlo: construye, cambia algo aguas arriba que el
builder no pueda ver, reconstruye y enseña el `CACHED`.

Después propón **tres** soluciones y evalúa cada una: `--no-cache` siempre, `--pull` más una
invalidación deliberada, y fijar la versión exacta del paquete. Para cada una di qué cuesta en
tiempo de build, qué cuesta en reproducibilidad y en qué escenario es la correcta.

**Pregunta de cierre:** en **este** curso, cuyo objetivo es que la imagen sea idéntica dentro
de dos años, ¿cuál eliges y qué estás aceptando a cambio? Es la tensión entre las dos virtudes
que §9 no puede resolver a la vez.

## 🔥 Opcionales

### 🔥 Ejercicio 26 — `SOURCE_DATE_EPOCH`

Investiga qué es y construye dos veces fijándolo.

**Pregunta:** ¿obtuviste el mismo digest? ¿Qué más habría que fijar para conseguirlo?

### 🔥 Ejercicio 27 — Cache mounts de BuildKit

Investiga `RUN --mount=type=cache` y aplícalo a la descarga de los tarballs de Node.

**Pregunta:** ¿acelera el build limpio? ¿Qué renuncia haces a cambio, y por qué el baseline
del curso no lo usa?

## 💀 Boss fight

### 💀 Ejercicio 28 — Boss fight: el build de doce minutos que debería durar veinte segundos

Heredas un Dockerfile que reconstruye el toolchain entero cada vez que alguien toca una línea
del proyecto. El equipo lo acepta como inevitable. No lo es.

**Objetivo:** convertirlo en un caso con antes y después medidos. Tienes que: (1) **medir** el
build actual en frío y en caliente, con `--progress=plain`, y señalar la primera capa que se
invalida en cada iteración; (2) explicar con §5 por qué esa capa está donde está y qué regla
la desordenó; (3) reordenarlo y volver a medir, dando los dos tiempos y el número de capas
reutilizadas; (4) demostrar con `docker history` que la imagen final es **equivalente** —mismo
software— aunque su lista de capas sea distinta, y explicar por qué el image ID sí cambia
(§7); (5) añadir un `ARG` de los de §8 y demostrar que cambiarlo invalida exactamente desde
donde esperas y ni una capa antes.

**Pregunta:** después de tu reordenación, ¿cuál es el cambio más barato que un desarrollador
puede hacer, y cuál el más caro? Da los dos tiempos y di si esa asimetría es la correcta para
el trabajo diario del equipo.

---

## 14. 📚 Referencias

**Build y caché**
- Caché de build: https://docs.docker.com/build/cache/
- Invalidación y buenas prácticas: https://docs.docker.com/build/cache/invalidation/
- BuildKit: https://docs.docker.com/build/buildkit/
- Multi-stage builds: https://docs.docker.com/build/building/multi-stage/

**Formato de imagen**
- Especificación OCI de imagen: https://specs.opencontainers.org/image-spec/
- Manifest: https://github.com/opencontainers/image-spec/blob/main/manifest.md
- Config: https://github.com/opencontainers/image-spec/blob/main/config.md

**Comandos**
- `docker image history`: https://docs.docker.com/reference/cli/docker-image-history/
- `docker builder prune`: https://docs.docker.com/reference/cli/docker-builder-prune/

**Orden de lectura sugerido:** la página de invalidación de caché mientras haces el ejercicio
8, y la especificación OCI del manifest justo antes de **[F27](27-registries-por-dentro.md)**, que es donde se vuelve
imprescindible.

---

## 15. 🏁 Resultado de la fase

```text
LA IMAGEN     sin cambios

SABES         qué pregunta responde la caché y con qué regla decide
              qué invalida cada instrucción — y que RUN compara texto, no resultado
              por qué un miss arrastra todo lo posterior, y qué orden se deriva
              qué es una capa en el modelo OCI: manifest + config + blobs
              que borrar en una capa posterior no reduce el tamaño
              tag ≠ image ID ≠ digest, y cuál es identidad real
              hasta dónde llega la reproducibilidad de este laboratorio

PENDIENTE     cómo se montan esas capas juntas en runtime  → F13, la fase siguiente
```

> **La señal de que quedó bien:** *"antes de reconstruir, sé qué pasos van a decir `CACHED`
> — y cuando me equivoco, sé por qué."*

En **[F13](13-overlayfs-y-copy-on-write.md)** bajamos un nivel más: OverlayFS, el union filesystem que monta las capas juntas y
que explica, con números medidos, por qué borrar un archivo puede **agrandar** la imagen.
