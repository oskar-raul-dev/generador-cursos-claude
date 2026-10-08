# 🔐 Parte II · Fase 25 — Rootless y user namespaces: qué significa "root" de verdad

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Requisitos:** **[F17](17-usuarios-permisos-y-volumenes.md)** (usuarios y permisos) y **[F24](24-docker-y-podman-arquitectura.md)** (los dos motores)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **⚠️ Alcance de la verificación (6 de septiembre de 2026):** el barrido de verificación ejecutada del curso se corrió sobre **Docker 29.6.2** y no sobre Podman, que no estaba instalado en la máquina de referencia. **Los comandos `podman` de esta fase están contrastados contra la documentación oficial de Podman, no ejecutados**, y así se declaran por lo que pide la guía del curso: si no está verificado, se dice. Si los corres y algo no coincide, tu terminal tiene razón y este documento no.
> **Estado de la imagen al terminar:** sin cambios
> **Objetivo:** entender qué es un user namespace, por qué "root dentro del contenedor" es una frase imprecisa, y qué gana y qué cuesta cada modelo — con un threat model honesto

---

## 1. 🧭 Dónde estamos

[F17](17-usuarios-permisos-y-volumenes.md) te enseñó el problema de los permisos y te dio tres estrategias. [F24](24-docker-y-podman-arquitectura.md) te dijo que Podman
rootless cambia la ecuación entera y te mandó aquí.

Esta fase explica el mecanismo que lo hace posible —el **user namespace**—, y responde la
pregunta que el curso lleva evitando desde [F01](01-decisiones-debian-zonas-node.md) §4.5: **¿qué riesgo estoy asumiendo de verdad
con este laboratorio?**

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar por qué *"root dentro del contenedor"* no dice nada por sí solo.
- Leer `/etc/subuid` y `/proc/self/uid_map` y saber qué significan.
- Distinguir los **cuatro modelos**: Docker rootful, `userns-remap`, Docker rootless y Podman
  rootless.
- Entender por qué en rootless no puedes publicar el puerto 80 sin más.
- Distinguir `--user` de `--userns`, que no son lo mismo.
- Construir un **threat model honesto** para este laboratorio, sin alarmismo y sin negación.

---

## 3. 🚧 Qué NO entra todavía

- **La comparación práctica de rendimiento y portabilidad** entre modelos → **[F26](26-portabilidad-entre-motores.md)**.
- **Firmar imágenes y la cadena de suministro** → **[F29](29-supply-chain-sbom-firma.md)**.
- **Endurecer una imagen para producción** → fuera de alcance, y [F01](01-decisiones-debian-zonas-node.md) §4.5 explica por qué.

---

## 4. 👑 "Root dentro del contenedor" no dice nada

Es la frase que más se repite y la que menos informa, porque describe **una** de las dos cosas
que importan y calla la otra.

```text
la pregunta que se responde:   ¿qué UID tiene el proceso DENTRO del contenedor?
la pregunta que importa:       ¿a qué UID corresponde eso FUERA?
```

Las dos combinaciones que existen:

```mermaid
flowchart TD
    subgraph RF["MODELO ROOTFUL"]
        F1["uid 0 dentro"] -- "sin traducción" --> F2["uid 0 fuera = root del host"]
        F2 -.- F3["si escapa: es root en tu máquina"]
    end
    subgraph RL["MODELO ROOTLESS"]
        L1["uid 0 dentro"] -- "user namespace" --> L2["uid 1000 fuera = tu usuario"]
        L2 -.- L3["si escapa: eres tú, ni más ni menos"]
    end
```

**El mismo `id` dentro del contenedor, dos consecuencias radicalmente distintas.** De ahí que
la frase por sí sola no sirva para decidir nada.

---

## 5. 🧬 El mecanismo: `/etc/subuid` y el mapeo

Un **user namespace** permite que un rango de UID del host se presente como otro rango dentro
del namespace. La configuración vive en dos archivos del sistema:

```bash
cat /etc/subuid
cat /etc/subgid
```
```text
oskar:100000:65536
```

Se lee: *"al usuario `oskar` se le asignan 65.536 UID subordinados, empezando en el 100000"*.
Son UID que no corresponden a ninguna persona real y que el sistema le presta para que los
reparta dentro de sus namespaces.

**El mapeo típico de Podman rootless:**

```text
DENTRO del contenedor        FUERA, en el host
uid 0     (root)      ────▶  uid 1000   (tú)
uid 1     …           ────▶  uid 100000
uid 2                 ────▶  uid 100001
…                            …
uid 65536             ────▶  uid 165535
```

**El UID 0 del contenedor se mapea a tu usuario.** Todo lo demás, al rango prestado. Y por eso
un proceso "root" dentro del contenedor no puede hacer nada en el host que tú no pudieras hacer.

Míralo desde dentro:

```bash
podman run --rm legacy-node-toolchain:phase15 cat /proc/self/uid_map
```
```text
         0       1000          1
         1     100000      65536
```

Tres columnas: **UID dentro**, **UID fuera**, **cuántos**. La primera línea dice que el 0 de
dentro es el 1000 de fuera, uno solo. La segunda mapea el resto del rango.

Compáralo con Docker rootful:

```bash
docker run --rm legacy-node-toolchain:phase15 cat /proc/self/uid_map
```
```text
         0          0 4294967295
```

**Identidad.** El 0 de dentro es el 0 de fuera. No hay traducción, y eso es exactamente lo que
significa "rootful".

> 🧠 **Ese archivo de tres números es la fase entera.** Cuando quieras saber en qué modelo
> estás, no preguntes al producto: pregunta a `/proc/self/uid_map`.

---

## 6. 🗺️ Los cuatro modelos

### 6.1 Docker rootful — el clásico

El `dockerd` corre como root y los contenedores heredan sus privilegios sin traducción. Es lo
que usa la mayoría, incluido este curso por defecto.

**Consecuencias:** los archivos salen con dueño `root` ([F17](17-usuarios-permisos-y-volumenes.md) §5), el socket equivale a acceso
root ([F24](24-docker-y-podman-arquitectura.md) §4.1), y una fuga del contenedor es una fuga a root.

### 6.2 Docker con `userns-remap`

Docker soporta activar user namespaces en el daemon:

```json
// /etc/docker/daemon.json
{ "userns-remap": "default" }
```

El daemon sigue siendo root, pero **los contenedores se mapean a un rango subordinado**. Mejora
el aislamiento y trae incomodidades: los volúmenes existentes dejan de tener los permisos
correctos, y algunas funciones se restringen.

### 6.3 Docker rootless

Un modo en el que el propio daemon corre como usuario sin privilegios. Funciona y es un modo
**aparte** que hay que instalar y configurar deliberadamente, con sus limitaciones.

### 6.4 Podman rootless

Aquí no es un modo especial: **es lo natural**. Por el modelo fork-exec de [F24](24-docker-y-podman-arquitectura.md) §5.1, el
contenedor es hijo tuyo y corre con tu usuario, con el mapeo de §5 aplicado.

```text
Docker rootful      🔴 sin traducción · el modelo por defecto
Docker userns-remap 🟡 traducción, daemon sigue root · configuración manual
Docker rootless     🟢 daemon sin privilegios · modo aparte
Podman rootless     🟢 el modo por defecto · nada que configurar
```

### 6.5 "Mi contenedor desapareció cuando usé sudo"

Un desconcierto clásico de Podman que ahora tiene explicación:

```bash
podman run -d --name mio alpine sleep 300
podman ps            # ahí está
sudo podman ps       # vacío 😱
```

**No desapareció.** `sudo podman` es **otro almacén y otro conjunto de namespaces**: el de root.
Podman rootless guarda todo en `~/.local/share/containers/`, y root tiene el suyo en
`/var/lib/containers/`.

> 🧭 **La regla:** con Podman, no mezcles `sudo`. Elige rootless o rootful y sé consistente, o
> vas a tener dos laboratorios paralelos sin saberlo.

---

## 7. 🧩 `--user` no es `--userns`

Se confunden y hacen cosas distintas:

| | Qué cambia | Ejemplo |
|---|---|---|
| **`--user`** | el **UID del proceso dentro** del contenedor | `--user 1000:1000` |
| **`--userns`** | **cómo se mapean** los UID del namespace al host | `--userns=keep-id` |

**`--user`** es lo de [F17](17-usuarios-permisos-y-volumenes.md) §6: el proceso corre con otro UID **dentro**. El mapeo al host no
cambia.

**`--userns=keep-id`** de Podman hace algo distinto y muy útil: mapea **tu UID del host al mismo
número dentro** del contenedor.

```bash
podman run --rm --userns=keep-id legacy-node-toolchain:phase15 id
```
```text
uid=1000(oskar) gid=1000(oskar)
```

Con eso, los archivos que crees en un bind mount tienen tu dueño en los dos lados, sin `chown`,
sin preparar volúmenes y sin `-e HOME`. Es la respuesta más limpia al problema de [F17](17-usuarios-permisos-y-volumenes.md).

---

## 8. 🚪 Lo que rootless te quita

No todo son ventajas, y la honestidad es parte del contenido.

### 8.1 Puertos privilegiados

En Linux, los puertos por debajo del 1024 requieren privilegios. En rootless no los tienes:

```bash
podman run -p 80:80 nginx      # ❌ permission denied
podman run -p 8080:80 nginx    # ✅
```

Para el laboratorio da igual —3000, 4200, 8080 y 9229 están todos por encima—, y para servir en
el 80 hay que ajustar `net.ipv4.ip_unprivileged_port_start` o poner algo delante.

### 8.2 Cgroups y límites

Rootless necesita **cgroups v2** con delegación configurada para poder aplicar `--memory` y
`--cpus`. En sistemas modernos suele estar; en otros, esos límites se ignoran en silencio — que
es peor que fallar.

```bash
podman info --format '{{.Host.CgroupsVersion}} · {{.Host.CgroupControllers}}'
```

### 8.3 La red cuesta algo

Sin privilegios no puedes crear interfaces de red del kernel, así que rootless usa
**`slirp4netns`** o **`pasta`**, que implementan la red en espacio de usuario. Funciona, y el
rendimiento no es el mismo — **[F26](26-portabilidad-entre-motores.md)** lo mide.

### 8.4 Capabilities bajo user namespace

Las *capabilities* que un proceso tiene dentro del namespace son reales **dentro de él**, y no
se traducen a poderes fuera. `CAP_NET_ADMIN` dentro del contenedor te deja configurar **su**
red, no la del host.

Es exactamente lo que quieres, y explica por qué algunas herramientas que "necesitan root"
funcionan en rootless sin problema: solo necesitaban root **dentro**.

---

## 9. 🛡️ Threat model honesto

Un apartado sin alarmismo y sin negación, porque los dos extremos son inútiles.

### 9.1 "Podman es seguro porque no tiene daemon" es demasiado simple

Es cierto que elimina un servicio privilegiado permanente y con eso un vector real. **Y no
convierte un contenedor en una caja fuerte.** Los namespaces son aislamiento, no una frontera de
seguridad como la de una VM, y una vulnerabilidad del kernel las atraviesa.

### 9.2 Lo que cada modelo te da

| | Si un proceso escapa del contenedor… |
|---|---|
| **Docker rootful** | es **root en tu host**. Radio de daño: total |
| **Docker userns-remap** | es un UID subordinado. Radio: limitado |
| **Docker rootless** | eres tú. Radio: tus archivos |
| **Podman rootless** | eres tú. Radio: tus archivos |

**"Eres tú" no es "no pasa nada".** Tu usuario tiene acceso a tu código, tus claves SSH, tus
tokens y tu historial de shell. Es mucho menos que root, y es bastante.

### 9.3 `--privileged` lo anula todo

```bash
docker run --privileged ...
```

Desactiva casi todas las protecciones: capabilities completas, acceso a dispositivos, sin
restricciones de seccomp. **Un contenedor privilegiado rootful es, a efectos prácticos, root en
el host.**

> ⚰️ **Anti-patrón con nombre propio.** `--privileged` como respuesta a un error de permisos es
> el `chmod -R 777` de los contenedores: funciona, no entiendes por qué fallaba, y has abierto
> algo mucho más grande de lo que necesitabas. Casi siempre lo que hacía falta era **una**
> capability concreta:
>
> ```bash
> docker run --cap-add=SYS_PTRACE ...    # en lugar de --privileged
> ```
>
> **[F30](30-troubleshooting-metodo-y-herramientas.md)** lo trata entre los anti-patrones de diagnóstico.

### 9.4 Y el threat model de este laboratorio

Concretamente, para lo que estamos haciendo:

**Lo que sí es un riesgo real:** estás ejecutando código de dependencias npm de 2018, sin
parches, con scripts de `postinstall` que se ejecutan automáticamente. Ese es el vector, y no es
teórico.

**Lo que lo acota:** el laboratorio es local, no expone servicios a Internet, y no maneja datos
de producción.

**Lo que reduciría el radio:** rootless, no montar el socket, no usar `--privileged`, y no meter
secretos en la imagen.

> 🧭 **La conclusión honesta:** este laboratorio es aceptable para desarrollo y mantenimiento
> local, que es exactamente lo que [F00](00-problema-y-contrato.md) y [F01](01-decisiones-debian-zonas-node.md) declararon. Si vas a ejecutar código legacy que no
> auditaste, **rootless reduce de verdad lo que puede pasar** — y es el mejor argumento práctico
> para Podman de todo el curso.

---

## 10. 🧪 Demuéstralo en tu máquina

```bash
# ¿en qué modelo estoy?
docker run --rm alpine cat /proc/self/uid_map
podman run --rm alpine cat /proc/self/uid_map

# ¿qué rango tengo prestado?
grep "^$(whoami):" /etc/subuid /etc/subgid

# el archivo que sale al host
podman run --rm --userns=keep-id \
  --mount type=bind,src="$PWD",dst=/w \
  alpine touch /w/keepid.txt
ls -ln keepid.txt

podman run --rm \
  --mount type=bind,src="$PWD",dst=/w \
  alpine touch /w/rootless.txt
ls -ln rootless.txt
```

Compara los dueños de los dos archivos. Ahí está §7 en dos líneas de `ls`.

---

## 11. ⚠️ Errores comunes y diagnóstico

**"Mis contenedores desaparecieron."** Mezclaste `sudo podman` con `podman`. §6.5.

**`permission denied` publicando el puerto 80.** Rootless. §8.1.

**`--memory` no tiene efecto.** Cgroups sin delegación. §8.2.

**Los archivos salen con un UID rarísimo, como 100000.** Es el rango subordinado: escribiste
como un UID que no es el 0 dentro del namespace. `--userns=keep-id` lo resuelve.

**Con `keep-id`, `apt-get` falla dentro.** Coherente: ya no eres root dentro, eres tú. Es [F17](17-usuarios-permisos-y-volumenes.md)
§6.3 otra vez.

**Docker rootless no arranca.** Necesita configuración específica y `/etc/subuid`. Comprueba que
tu usuario tiene rango asignado.

**"Puse `--privileged` y funcionó."** Averigua qué capability faltaba de verdad. §9.3.

---

## 12. 📋 Checklist de validación

```text
[ ] Leíste /etc/subuid y sabes qué rango tienes
[ ] /proc/self/uid_map en Docker muestra la identidad 0→0
[ ] /proc/self/uid_map en Podman rootless muestra el mapeo
[ ] Sabes distinguir los cuatro modelos de §6
[ ] Distingues --user de --userns
[ ] --userns=keep-id produce archivos con tu dueño en el host
[ ] Sabes qué te quita rootless: puertos, cgroups, red
[ ] Puedes explicar el radio de daño de cada modelo
[ ] Sabes por qué --privileged es un anti-patrón y cuál es la alternativa
```

---

## 13. 🧪 Ejercicios de la Fase 25 (20)

## 🟢 Fácil — ver el mapeo (1–5)

### 🟢 Ejercicio 1 — Tu rango subordinado

Lee `/etc/subuid` y `/etc/subgid`.

**Pregunta:** ¿cuántos UID te presta el sistema y desde cuál?

### 🟢 Ejercicio 2 — Los dos `uid_map`

Ejecuta los dos comandos de §10 y compara.

**Objetivo:** ver la identidad en Docker y el mapeo en Podman. Es la fase entera en dos salidas.

### 🟢 Ejercicio 3 — El mismo `id`, dos mundos

Ejecuta `id` en un contenedor Docker rootful y en uno Podman rootless.

**Pregunta:** ¿son iguales? ¿Significan lo mismo?

### 🟢 Ejercicio 4 — Los dos archivos

Ejecuta la comparación de archivos de §10.

**Objetivo:** ver los dos dueños distintos con `ls -ln`.

### 🟢 Ejercicio 5 — `keep-id` en acción

Ejecuta `podman run --rm --userns=keep-id ... id`.

**Pregunta:** ¿qué UID tienes dentro ahora? ¿Y qué pasa con `whoami`?

## 🟡 Intermedio — trabajar en rootless (6–12)

### 🟡 Ejercicio 6 — El puerto 80

Intenta `podman run -p 80:80` en rootless.

**Objetivo:** ver el error y comprobar que el 8080 sí funciona.

### 🟡 Ejercicio 7 — `sudo podman` es otro mundo

Arranca un contenedor con `podman` y búscalo con `sudo podman ps`.

**Objetivo:** reproducir §6.5 y no volver a asustarte.

### 🟡 Ejercicio 8 — El laboratorio con `keep-id`

Ejecuta el toolbox completo de [F09](09-montar-tu-proyecto.md) con Podman y `--userns=keep-id`.

**Pregunta:** ¿tuviste que preparar el volumen como en [F17](17-usuarios-permisos-y-volumenes.md) §6.2? ¿Y declarar `HOME`?

### 🟡 Ejercicio 9 — `--user` contra `--userns`

Ejecuta el mismo comando con `--user 1000:1000` y con `--userns=keep-id`, y compara `id` y el
dueño de un archivo creado.

**Objetivo:** ver que resuelven cosas distintas.

### 🟡 Ejercicio 10 — Cgroups

Ejecuta `podman info` de §8.2 y prueba `--memory=64m` con un proceso que consuma memoria.

**Pregunta:** ¿se aplicó el límite? Si no, ¿te avisó de algo?

### 🟡 Ejercicio 11 — La red rootless

Averigua qué implementación de red usa tu Podman rootless.

**Pregunta:** ¿`slirp4netns` o `pasta`? Prueba una descarga grande y compárala con Docker.

### 🟡 Ejercicio 12 — Valida un fixture en rootless

Ejecuta el protocolo de [F11](11-validar-tu-proyecto.md) con Podman rootless y `keep-id`.

**Pregunta:** ¿mismo resultado? ¿Qué paso se comportó distinto?

## 🟠 Difícil — privilegios y capabilities (13–16)

### 🟠 Ejercicio 13 — Capabilities

Ejecuta `podman run --rm alpine capsh --print` o `grep Cap /proc/self/status` en los dos
motores.

**Pregunta:** ¿qué capabilities tienes en cada uno? ¿Significan lo mismo?

### 🟠 Ejercicio 14 — `--cap-add` en lugar de `--privileged`

Encuentra un comando que falle sin privilegios y hazlo funcionar con **una sola** capability.

**Objetivo:** practicar la alternativa de §9.3 en un caso real.

### 🟠 Ejercicio 15 — El UID de 100000

Provoca deliberadamente un archivo con un UID del rango subordinado y explica cómo llegó ahí.

**Objetivo:** entender el mapeo lo bastante como para predecir el número, no solo verlo.

### 🟠 Ejercicio 16 — El radio de daño

En una máquina de pruebas, arranca un contenedor con `--privileged` en Docker rootful y monta el
`/` del host. Repite con Podman rootless.

**Objetivo:** ver la diferencia de §9.2 con tus manos. **No lo hagas en una máquina que te
importe.**

## 🔴 Muy difícil — threat model y decisión (17–20)

### 🔴 Ejercicio 17 — Qué se rompe con `userns-remap`

Si tienes un Linux de pruebas, activa `userns-remap` en Docker y comprueba qué pasa con los
volúmenes que ya tenías.

**Objetivo:** entender por qué no se activa a la ligera en una máquina con trabajo dentro.

### 🔴 Ejercicio 18 — El script que asume root

Escribe un script que funcione en Docker rootful y falle en rootless por una razón de §8, y
después arréglalo para que funcione en los dos.

### 🔴 Ejercicio 19 — Traduce las tres estrategias de [F17](17-usuarios-permisos-y-volumenes.md)

Vuelve a la tabla de [F17](17-usuarios-permisos-y-volumenes.md) §9 —root, `--user`, usuario en la imagen— y añádele una cuarta columna:
qué pasa con cada una **bajo Podman rootless**.

**Objetivo:** descubrir que dos de las tres pierden gran parte de su sentido, y decir cuál
sobrevive y por qué. Es la fase reescribiendo una decisión anterior con información nueva, que
es lo que hace la Parte II.

### 🔴 Ejercicio 20 — El threat model de tu laboratorio

Escribe el threat model de §9.4 para **tu** proyecto concreto: qué código no auditado ejecutas,
qué tiene acceso tu usuario, y qué reduciría el radio.

**Objetivo:** que sea específico y accionable. "Es un laboratorio local" no es un threat model;
"ejecuto 340 dependencias transitivas de 2018 con scripts de postinstall, y mi usuario tiene mis
claves SSH" sí lo es.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — Docker rootless

Instala Docker en modo rootless y compara su `uid_map` con el de Podman rootless.

**Pregunta:** ¿son equivalentes? ¿Qué te costó configurarlo?

### 🔥 Ejercicio 22 — Lee `user_namespaces(7)`

Léelo entero, ahora que tienes contexto.

**Objetivo:** encontrar los dos detalles del mecanismo que esta fase simplificó, y decidir si la
simplificación era razonable.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: la máquina rootless donde casi todo funciona

Te entregan una máquina con Podman rootless donde el laboratorio del curso **casi** funciona, y
un compañero que se rindió después de dos horas. Estos son los cuatro síntomas que apuntó, en
sus palabras:

```text
1. "los archivos que crea el contenedor salen con dueño 100000 y no puedo borrarlos"
2. "el dev server publica en el 3000 pero el 80 me lo rechaza"
3. "--memory=512m no hace nada, el proceso se come toda la RAM"
4. "el mismo contenedor no aparece si uso sudo podman ps"
```

**Objetivo:** los cuatro son **comportamientos esperados de rootless**, no averías, y cada uno
sale de una sección distinta de esta fase. Para cada uno tienes que entregar tres cosas: la
**comprobación** que lo confirma —`/proc/self/uid_map`, `/etc/subuid`, `podman info` sobre
cgroups, o el almacén por usuario—, la **explicación mecánica** de por qué ocurre, y la
**solución o la renuncia**, distinguiendo cuál es cuál. Porque dos de los cuatro se resuelven y
los otros dos se aceptan, y confundirlos es lo que hizo perder dos horas a tu compañero.

Después la parte que lo convierte en boss. Deja el laboratorio de
[F09](09-montar-tu-proyecto.md) **funcionando entero** sobre esa máquina rootless: `npm ci`,
`test`, `build` y el dev server accesible desde el host, con los archivos del bind mount
editables desde tu editor sin `sudo`. Documenta cada opción que tuviste que añadir al
`podman run` respecto del `docker run` equivalente, y **por qué**.

**Pregunta de cierre:** con el laboratorio ya corriendo, responde a lo que tu compañero
preguntaba de fondo: ¿mereció la pena? Contesta con las dos columnas de §9.4 —lo que ganaste en
el threat model y lo que pagaste en fricción— y con una recomendación que no sea "depende".
Ahora ya no la estás escribiendo desde la teoría: la escribes desde una máquina que funciona.

---

## 14. 📚 Referencias

**User namespaces**
- `user_namespaces(7)`: https://manpages.debian.org/buster/manpages/user_namespaces.7.en.html
- `subuid(5)` y `subgid(5)`: https://manpages.debian.org/buster/passwd/subuid.5.en.html

**Rootless**
- Podman rootless: https://docs.podman.io/en/latest/markdown/podman.1.html#rootless-mode
- Tutorial rootless de Podman: https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md
- Docker rootless: https://docs.docker.com/engine/security/rootless/
- Docker `userns-remap`: https://docs.docker.com/engine/security/userns-remap/

**Seguridad**
- Seguridad de Docker: https://docs.docker.com/engine/security/
- Capabilities: https://manpages.debian.org/buster/manpages/capabilities.7.en.html
- seccomp en Docker: https://docs.docker.com/engine/security/seccomp/

> ⚠️ **`user_namespaces(7)` es densa y ahora sí es el momento.** Con lo de esta fase en la
> cabeza, sus ejemplos dejan de ser abstractos.

**Orden de lectura sugerido:** el tutorial de rootless de Podman primero, que es práctico; el
manpage cuando quieras el detalle.

---

## 15. 🏁 Resultado de la fase

```text
LA PREGUNTA     no es "¿soy root dentro?" sino "¿a qué UID corresponde eso fuera?"
                y la respuesta está en /proc/self/uid_map

EL MECANISMO    /etc/subuid presta un rango de UID subordinados
                el user namespace mapea 0 dentro → tu UID fuera
                Docker rootful:  0 → 0, identidad, sin traducción

CUATRO MODELOS  Docker rootful · userns-remap · Docker rootless · Podman rootless

--user ≠ --userns   el primero cambia el UID DENTRO
                    el segundo cambia el MAPEO al host
                    keep-id resuelve el problema de F17 sin chown ni HOME

LO QUE CUESTA   puertos <1024 · cgroups con delegación · red en espacio de usuario

THREAT MODEL    rootful:  si escapa, es root en tu host
                rootless: si escapa, eres tú — que es mucho menos, y es bastante
                --privileged lo anula todo: usa --cap-add
                el vector real de este curso son las dependencias de 2018 sin auditar
```

> **La señal de que quedó bien:** *"cuando alguien dice que su contenedor corre como root, le
> pregunto por su `uid_map` — porque esa frase, sola, no me dice si debería preocuparme."*

En **[F26](26-portabilidad-entre-motores.md)** cerramos el bloque de motores con lo práctico: rendimiento medido, scripts que
funcionan en los dos, y la matriz de decisión final.
