# 🔬 Parte II — Laboratorio: contenedores por dentro

> **Curso:** Docker Legacy Node
> **Fases:** [F12](12-capas-cache-y-contexto.md) a [F35](35-referencias.md) · ~116.000 palabras · 595 ejercicios · ~83 horas estimadas
> **Requisitos previos:** la Parte I hecha, con la imagen construida y un proyecto corriendo
> **Al terminar:** criterio para diagnosticar solo, sin buscar el síntoma exacto en Internet
> **Índice general:** [`0-programa-del-curso.md`](0-programa-del-curso.md)

---

## 🎯 Qué promete esta parte

La Parte I te dio un entorno que funciona. Esta parte te da **la capacidad de arreglarlo
cuando deje de funcionar**, que no es lo mismo y se nota exactamente el día que algo se
rompe de una forma que ningún tutorial anticipó.

La diferencia entre las dos, dicha sin adornos:

```text
Parte I  →  "npm ci funciona dentro del contenedor."
Parte II →  "npm ci falla con este error, y sé si el problema está en la
             imagen, en el volumen, en el motor, en la arquitectura o en el
             proyecto — y sé qué comando lo confirma."
```

Eso es **arqueología técnica**, y es la identidad de este curso. No formamos ingenieros
de plataforma; formamos gente capaz de leer un `Dockerfile` ajeno de 2018 y entender por
qué está así.

---

## 🧠 Cómo está organizada

No es una lista de temas sueltos. Son cinco bloques, y cada uno abre una caja que la
Parte I te dio cerrada.

### 🧬 Cómo se construye y se almacena una imagen — [F12](12-capas-cache-y-contexto.md) a [F15](15-laboratorios-dependencias-nativas.md)

[F12](12-capas-cache-y-contexto.md) abre la caché y las capas de verdad. **[F13](13-overlayfs-y-copy-on-write.md)** las monta: `lowerdir`, `upperdir`,
whiteouts, y la respuesta a por qué borrar un archivo en la capa siguiente **agranda** la
imagen en vez de encogerla. [F14](14-abi-libc-y-prebuilds.md) y [F15](15-laboratorios-dependencias-nativas.md) bajan al nivel binario: ABI, `NODE_MODULE_VERSION`,
glibc frente a musl, y los cuatro dragones clásicos —`node-sass`, `canvas`, `sqlite3`,
Puppeteer— con su autopsia completa.

### 🧟 Qué es realmente un contenedor en ejecución — [F16](16-pid1-senales-y-ciclo-de-vida.md) a [F20](20-validacion-sistematica-y-evidencia.md)

PID namespaces y por qué el proceso 1 tiene reglas distintas a cualquier otro. UID, GID y
los archivos que vuelven con dueño equivocado. Networking y por qué el contenedor no vive
en tu `localhost`. Dev Containers como lo que son: una capa de comodidad sobre lo que ya
sabes hacer a mano. Y [F20](20-validacion-sistematica-y-evidencia.md), la validación sistemática, que convierte "parece que funciona"
en evidencia con logs.

### 🧠 Arquitecturas y emulación — [F21](21-arquitecturas-y-emulacion.md) a [F23](23-estudios-de-caso-multiplataforma.md)

Qué es una arquitectura de CPU sin ponerse a diseñar silicio, cómo un tag contiene varias
imágenes, y cómo tu Mac ARM ejecuta un binario x86 sin que se lo pidas. Aquí se cierra el
argumento que abre el curso entero: la traducción siempre ocurre en algún sitio, y el
trabajo es **elegir dónde y quién la administra**.

### 🐳 Motores, registries y cadena de suministro — [F24](24-docker-y-podman-arquitectura.md) a [F29](29-supply-chain-sbom-firma.md)

Docker y Podman comparados sin hacer fútbol: cliente/daemon frente a fork-exec, y qué
gana y qué cuesta cada modelo. Después, qué es exactamente un registry por dentro
—manifests, indexes, descriptors, blobs— y qué significa firmar una imagen.

### 🕵️ Diagnóstico y el examen — [F30](30-troubleshooting-metodo-y-herramientas.md) a [F35](35-referencias.md)

El método antes que el catálogo: síntoma ≠ causa, hipótesis falsables, **una variable a
la vez**, reproducir antes de reparar. Después los dos catálogos de fallos, el forense
avanzado con su 💀 Boss Fight, y **[F34](34-proyecto-final.md)**, el proyecto final: un repositorio de 2019 sin
README, sin `.nvmrc` y sin nadie a quien preguntarle.

---

## 🩻 Lo que ya sabes y aquí no cambia

Esta parte no reescribe la Parte I. La imagen es la misma, los nombres son los mismos y
el baseline no se mueve: Debian 10 `debian/eol:buster`, Node 10.24.1 / 12.22.12 / 14.21.3
/ 16.20.2, npm 6.14.12, `linux/amd64` de referencia.

Lo que cambia es la profundidad con la que miras lo que ya construiste. Varias fases
empiezan literalmente con un comando que ya ejecutaste en la Parte I, y la pregunta:
*"¿qué pasó realmente cuando corriste esto?"*.

---

## ⚠️ Cómo trabajar esta parte

**Predice antes de ejecutar.** A partir de aquí, muchos ejercicios te piden anticipar el
resultado y después comparar. Es incómodo a propósito: es donde se descubren los modelos
mentales rotos, y un modelo roto que no se descubre reaparece a las tres fases disfrazado
de bug incomprensible.

**Rompe cosas.** Esta parte tiene más laboratorios destructivos que la primera. Contamina
un volumen, construye para la arquitectura equivocada, borra un archivo en la capa
siguiente y mide la imagen. Todo sobre fixtures, nunca sobre tu proyecto real.

**Los anti-patrones se nombran sin piedad.** `chmod -R 777`, `--privileged`, borrar el
`package-lock.json`, `docker system prune -a --volumes` como primer reflejo, o reinstalar
Docker esperando que la fe resuelva el problema. Los vas a ver identificados y con su
costo medido.

**No se lee de corrido.** Salvo que quieras, claro. Las cinco agrupaciones de arriba son
razonablemente independientes: si vienes por ABI puedes ir a [F14](14-abi-libc-y-prebuilds.md) sin haber leído [F27](27-registries-por-dentro.md), y
las dependencias reales están declaradas en el encabezado de cada fase.

---

## 🏆 El final

**[F34](34-proyecto-final.md) es el examen.** Te entregan un repositorio de 2019 sin instrucciones y tienes que
producir la imagen, el `VALIDATION-REPORT.md`, el veredicto de compatibilidad razonado y
—esto importa tanto como lo demás— **la lista honesta de lo que no pudiste resolver, con
su porqué**.

No es un apéndice ni un extra: es fase numerada y cuenta en el calendario, porque es el
punto donde demuestras que el curso sirvió de algo.

---

## 🏁 La señal de que quedó bien

> "Me dan un error que no había visto nunca y, en vez de buscarlo literal en Internet,
> sé en qué capa mirar, qué hipótesis probar primero y qué comando la confirma o la
> descarta. Y cuando no puedo arreglarlo, sé decir exactamente por qué."
