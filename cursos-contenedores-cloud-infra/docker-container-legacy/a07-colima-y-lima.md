# 🏔️ Apéndice a07 — Colima y Lima

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F00](00-problema-y-contrato.md) §5 · [F22](22-apple-silicon-y-hosts.md) §6.3 · [F26](26-portabilidad-entre-motores.md) §4.2
> **Requisitos:** F22 (Apple Silicon) y F26 (portabilidad entre motores)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **Qué encontrarás:** qué son exactamente Lima y Colima, por qué son la ruta más interesante en Apple Silicon para quien quiere control, y cómo arrancar una VM x86-64 completa cuando la emulación no basta

El curso menciona Colima desde [F00](00-problema-y-contrato.md) como uno de los cuatro motores soportados. Este apéndice
explica **qué hay debajo**, que resulta ser bastante más configurable que las alternativas.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Qué es Lima y qué es Colima?" | [§1](#1--lima-y-colima-quién-hace-qué) |
| "¿Cómo lo arranco para este curso?" | [§2](#2-️-arrancar-para-el-laboratorio) |
| "¿Cómo elijo la arquitectura de la VM?" | [§3](#3-️-la-decisión-que-solo-colima-te-deja-tomar) |
| "¿Y el rendimiento de los bind mounts?" | [§4](#4--virtiofs-y-el-cruce-de-la-frontera) |
| "¿Merece la pena frente a Docker Desktop?" | [§5](#5--guía-rápida-cuándo-usar-qué) |

---

## 1. 🧅 Lima y Colima: quién hace qué

Son dos piezas y se confunden constantemente.

**Lima** —*Linux on Mac*— gestiona máquinas virtuales Linux en macOS. Es la capa de abajo:
arranca la VM, la conecta a tu red y comparte directorios con el host. Puede usar el framework de
virtualización de Apple o QEMU.

**Colima** —*Containers on Lima*— usa Lima por debajo y añade lo que falta: un runtime de
contenedores dentro de la VM y la integración para que tu CLI de Docker le hable.

```mermaid
flowchart TD
    T["tu terminal (macOS)"] -- "docker / nerdctl" --> C["Colima<br/>configura el runtime y expone el socket"]
    C --> L["Lima<br/>gestiona la VM"] --> VM["VM Linux<br/>vz de Apple, o QEMU"]
    VM --> R["containerd o Docker Engine"] --> CT["tus contenedores"]
```

> 🧭 **Por qué esta separación importa.** Docker Desktop y Podman Desktop también arrancan una
> VM, y no te dejan configurarla a este nivel. Con Colima **la VM es tuya**: eliges su
> arquitectura, su hipervisor, su sistema de compartición de archivos y sus recursos, en un
> comando.

---

## 2. ▶️ Arrancar para el laboratorio

```bash
brew install colima docker docker-buildx

# una VM cómoda para este curso
colima start --cpu 4 --memory 8 --disk 60 --vm-type vz --mount-type virtiofs

colima status
docker version --format '{{.Server.Version}} · {{.Server.Arch}}'
```

**Las cuatro opciones que importan:**

| | Qué hace |
|---|---|
| `--cpu` / `--memory` / `--disk` | los recursos de la VM. **Igualarlos es lo que hace justa una comparación** — [F26](26-portabilidad-entre-motores.md) §5.2 |
| `--vm-type vz` | el framework de virtualización de Apple, más rápido que QEMU en Apple Silicon |
| `--mount-type virtiofs` | el sistema de compartición de archivos rápido. §4 |
| `--arch` | la arquitectura de la VM. §3 |

Y comprueba que el laboratorio corre:

```bash
docker run --rm --platform linux/amd64 legacy-node-toolchain:phase15 \
  bash -c 'uname -m; node --version'
```

### 2.1 Perfiles: varias VM a la vez

```bash
colima start --profile arm   --arch aarch64 --cpu 4 --memory 8
colima start --profile intel --arch x86_64  --cpu 4 --memory 8

colima list
docker context ls                      # Colima crea un contexto por perfil
docker context use colima-intel
```

**Esto es lo que ningún otro motor te da tan fácil:** dos VM de arquitecturas distintas
conviviendo, y cambiar entre ellas con `docker context use`. Para los ejercicios de [F23](23-estudios-de-caso-multiplataforma.md) es
justo lo que hace falta.

---

## 3. 🏗️ La decisión que solo Colima te deja tomar

Aquí está el valor real de este apéndice. [F22](22-apple-silicon-y-hosts.md) §4 listaba cinco rutas en Apple Silicon, y la
cuarta —**una VM x86-64 completa**— es la que Colima hace práctica:

```bash
colima start --profile intel --arch x86_64 --vm-type qemu --cpu 4 --memory 8
```

```mermaid
flowchart TD
    M["Mac ARM64"] --> Q["QEMU emula una MÁQUINA x86-64 completa<br/>emulación de máquina, F21 §7.2 caso A"]
    Q --> K["kernel Linux x86-64"] --> C["contenedores amd64<br/>NATIVOS dentro de esa VM"]
```

**Y la diferencia con la ruta 2 es sutil e importante.** En la ruta 2 el kernel es ARM64 y QEMU
traduce cada proceso amd64 —caso B—. Aquí el kernel **es** x86-64 y los contenedores corren
nativos dentro de él; lo que se emula es la máquina entera.

| | Ruta 2: contenedor amd64 emulado | Ruta 4: VM x86-64 completa |
|---|---|---|
| Kernel | ARM64 nativo | x86-64 emulado |
| Qué se traduce | cada proceso amd64 | toda la máquina |
| Arranque de la VM | rápido | **lento** |
| Contenedores dentro | traducidos | nativos para esa VM |
| Cuándo | por defecto | cuando la ruta 2 falla de forma inexplicable |

> 🧭 **Cuándo justifica su coste.** Cuando sospechas que la traducción por proceso es la causa de
> un fallo raro —[F21](21-arquitecturas-y-emulacion.md) §10 lo menciona— y quieres descartarla. Un kernel x86-64 de verdad elimina
> esa variable, y eso convierte "creo que es la emulación" en algo comprobable.

---

## 4. 📁 `virtiofs` y el cruce de la frontera

[F26](26-portabilidad-entre-motores.md) §4.2 identificó el cuello de botella real en macOS: **los bind mounts cruzan de macOS a la
VM**, y ese cruce cuesta. Colima te deja elegir cómo:

| `--mount-type` | Notas |
|---|---|
| `virtiofs` | el más rápido; requiere `--vm-type vz` |
| `sshfs` | el clásico, más lento y muy compatible |
| `9p` | intermedio |

```bash
colima start --vm-type vz --mount-type virtiofs
```

**Y la mitigación que el curso ya aplicaba desde [F01](01-decisiones-debian-zonas-node.md):** `node_modules` en un named volume vive
**dentro** de la VM y no cruza la frontera. Es la razón por la que un `npm ci` en volumen es
tan distinto de uno en bind mount, y aquí puedes medirlo cambiando `--mount-type` entre
arranques.

---

## 5. 🧭 Guía rápida: cuándo usar qué

| Tu situación | Elige |
|---|---|
| Quieres que funcione y no pensar | **Docker Desktop** |
| La licencia de Docker Desktop es un problema | **Colima**, o Podman Desktop |
| Quieres controlar CPU, RAM, hipervisor y compartición | **Colima** |
| Necesitas dos arquitecturas a la vez | **Colima con perfiles** — §2.1 |
| Sospechas de la traducción por proceso | **Colima con `--arch x86_64`** — §3 |
| Solo quieres una VM Linux, sin contenedores | **Lima a secas** |
| Estás midiendo rendimiento entre motores | **Colima**, porque puedes igualar las VM |

> 🧭 **La recomendación honesta:** si Docker Desktop te funciona y la licencia no es un problema,
> quédate. Colima es para quien quiere **control** —o para quien lo necesita, que es el caso de
> §3—, y ese control se paga en configuración que hay que entender.

---

## 6. ⚠️ Errores comunes

**`docker` no encuentra el daemon tras `colima start`.** Falta el contexto:
`docker context use colima`.

**`--mount-type virtiofs` falla.** Requiere `--vm-type vz`, y este requiere una versión reciente
de macOS.

**El disco de la VM se llena.** Es el disco de Colima, no el de tu Mac — [F31](31-catalogo-de-fallos-i.md) §4.4.
`colima start --disk` lo dimensiona **al crear**; ampliarlo después exige recrear.

**Todo va lentísimo con `--arch x86_64`.** Es lo esperado: emulación de máquina completa. §3.

**Los cambios de configuración no se aplican.** `colima stop && colima start` con las opciones
nuevas; algunas exigen `colima delete` y volver a crear.

---

## 🧪 Ejercicios (5)

### 🟢 Ejercicio 1 — Arranca y valida

Instala Colima, arranca con las opciones de §2 y ejecuta el laboratorio.

### 🟢 Ejercicio 2 — Inspecciona la VM

Ejecuta `colima status`, `colima list` y `docker context ls`.

**Pregunta:** ¿qué recursos tiene? ¿Coinciden con lo que pediste?

### 🟡 Ejercicio 3 — Dos perfiles

Crea los dos perfiles de §2.1 y alterna con `docker context use`.

**Objetivo:** comprobar `uname -m` en cada uno y tener el escenario de los ejercicios de [F23](23-estudios-de-caso-multiplataforma.md).

### 🟡 Ejercicio 4 — `virtiofs` medido

Ejecuta `npm ci` sobre bind mount con `virtiofs` y con `sshfs`, cronometrando.

**Pregunta:** ¿cuánta diferencia? ¿Y sobre named volume, cambia algo?

### 🟠 Ejercicio 5 — La VM x86-64 completa

Arranca el perfil de §3 y compara con la ruta 2: tiempo de arranque de la VM, tiempo de un
`npm ci`, y `uname -m` del kernel.

**Pregunta:** ¿en qué caso concreto compensaría este coste? Relaciónalo con [F21](21-arquitecturas-y-emulacion.md) §10.

---

## 📚 Referencias

- Colima: https://github.com/abiosoft/colima
- Colima FAQ: https://github.com/abiosoft/colima/blob/main/docs/FAQ.md
- Lima: https://lima-vm.io
- Apple Virtualization Framework: https://developer.apple.com/documentation/virtualization
- virtiofs: https://virtio-fs.gitlab.io

> ⚠️ **Colima y Lima evolucionan rápido**, y las opciones de `colima start` cambian entre
> versiones. Comprueba con `colima start --help` antes de copiar un comando de aquí o de
> cualquier sitio. Enlaces revisados el 3 de septiembre de 2026.

**Vuelve a:** [F22 §6.3](22-apple-silicon-y-hosts.md) · [F26 §4](26-portabilidad-entre-motores.md)
