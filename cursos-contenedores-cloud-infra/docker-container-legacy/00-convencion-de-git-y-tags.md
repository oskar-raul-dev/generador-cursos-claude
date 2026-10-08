# 🏷️ Convención de git: commits y tags de progreso
## Docker Legacy Node

Cómo versionas lo que construyes mientras haces el curso. Es corta a propósito: no es un proyecto de
empresa, no hay releases ni equipo, y una estrategia de ramas elaborada sobraría. Son tres cosas —un
repo para el laboratorio, commits con un prefijo y un tag por fase cerrada— más un uso que en este
curso rinde mucho: **el tag de git y la etiqueta de la imagen se llaman igual**, así que siempre sabes
qué Dockerfile produjo qué imagen.

> **Cuándo se lee:** antes de la [Fase 02](02-dockerfile-esencial.md), donde nace el laboratorio, y
> cada vez que cierres una fase.
> **Vigencia:** 2026-10-07.

> 🔑 **La frase para memorizar:** un tag es un puntero a un commit. No ocupa espacio, no agrega
> overhead y se borra con `git tag -d`. La pregunta no es "¿vale la pena etiquetar esto?", es "¿por
> qué no?".

---

## 📦 1. Un repo para el laboratorio, no para tu proyecto

El laboratorio nace en la [Fase 02](02-dockerfile-esencial.md) como `legacy-node-toolchain-lab/`, con
`dockerfiles/` y el `.dockerignore`; ahí haces `git init`. Tu proyecto legacy —el de 2018 que vienes a
resucitar— **ya tiene su propio repositorio y se queda como está**: el contenedor contiene el
toolchain, no el proyecto, y el curso no te pide commitear nada dentro de él para que funcione.

**Dos repos, no uno**, por la misma razón que ordena el curso: si el toolchain viviera dentro del
repositorio del proyecto, cada cambio de imagen ensuciaría la historia de un código que no tocaste, y
el día que el proyecto se migre de verdad no podrías separar una cosa de la otra.

**Lo que queda fuera desde el primer commit**: `node_modules/` de los fixtures, las salidas de build y
cualquier `.tar` de imagen que exportes. Las imágenes no se versionan en git: se reconstruyen desde el
Dockerfile, y para eso está el tag. Un secreto que entra al repo —un token de registry, por ejemplo—
ya no sale, aunque lo borres en el commit siguiente.

No hace falta remoto. Si lo tienes, recuerda que **los tags no viajan solos**: `git push --tags`.

---

## 💬 2. Los mensajes de commit

Un prefijo, y ya. El prefijo es el código de la fase, `f03`, o del apéndice, `a10`:

```bash
git commit -m "f03: utilidades de diagnóstico en una sola capa de apt"
git commit -m "f03 ej12: limpieza de listas de apt medida con docker history"
git commit -m "a10: compose con el proyecto montado y el puerto del dev server"
```

Los ejercicios llevan además su número (`ej12`), y así queda claro qué es contenido de la fase y qué
es práctica tuya. Eso te deja dos búsquedas útiles:

```bash
git log --oneline --grep '^f03'        # todo lo de la Fase 3
git log --oneline --grep '^f03 ej'     # solo los ejercicios de la Fase 3
```

Commitea seguido y con mensajes cortos. Nadie va a revisar tu historia, pero tú vas a volver a ella
cuando un ejercicio de diagnóstico te deje la imagen irreconocible.

### Los apéndices

**Los apéndices no cierran con tag**, y no es un olvido: un tag marca un cambio en el repositorio, y
un apéndice explica lo que ya está ahí.

> 💡 **Si un apéndice te deja archivos versionados** —el compose de [a10](a10-docker-compose.md), el
> workflow de [a14](a14-ci-github-actions.md)— y quieres poder volver a ese punto, `apendice-a10` o
> `apendice-a14` existen como opción tuya. Ningún apéndice te lo va a pedir.

---

## 🏷️ 3. Un tag por fase cerrada

**Cuando cierras una fase —con su "📋 Checklist de validación" en verde— haces commit y creas el
tag.** Uno por fase, y no hace falta más.

El tag se llama **`fase-` + el mismo slug del archivo `.md`**, así no hay que recordar nada: el
archivo que estás leyendo te dice cómo se llama su tag.

```text
03-apt-y-utilidades.md          →   fase-03-apt-y-utilidades
07-build-de-la-imagen.md        →   fase-07-build-de-la-imagen
15-laboratorios-dependencias-nativas.md   →   fase-15-laboratorios-dependencias-nativas
```

Anotado (`git tag -a`), porque así guarda fecha y mensaje. El mensaje no se inventa: es el bloque
"🏁 Resultado de la fase", con lo que efectivamente quedó.

```bash
git tag -a fase-07-build-de-la-imagen -m "F7 cerrada: Dockerfile canónico en la raíz,
build sin -f, legacy-node-toolchain:phase07 construida para linux/amd64."
```

Si al escribir el mensaje descubres que un ítem del checklist no está, no está la fase. El tag es
honesto o no sirve para nada.

**El tag de git y la etiqueta de la imagen son el mismo punto.** Cada fase que construye etiqueta su
imagen `legacy-node-toolchain:phaseNN`; el tag `fase-NN-…` es el commit con el Dockerfile que la
produjo. Si una imagen se comporta distinto de como lo hacía ayer, la primera pregunta es *"¿qué hay
adentro?"*, y la respuesta es `git show fase-NN-…`. Cuando la [Fase 28](28-publicar-la-imagen.md)
publique versiones (`1.0.0`, `1.0.1`), la versión publicada nombra el commit del mismo modo.

> 💡 **Las fases sin Dockerfile nuevo también se etiquetan.** Las de la Parte II que solo miden o
> diagnostican dejan notas, scripts y mediciones en el repo; si la fase cambió algo, hay algo que
> marcar.

> ⚠️ **Volver a un tag te deja en `detached HEAD`.** Es normal: `git checkout fase-05-python-y-node-gyp`
> te pone a mirar ese estado sin estar en ninguna rama. Si vas a escribir desde ahí, crea una rama
> primero (`git switch -c wip/fase-05-intento-2`), con prefijo: una rama y un tag que se llaman igual
> vuelven ambiguo cualquier `git checkout`.

---

## 🧪 4. Tags de ejercicio *(opcionales, pero baratos)*

Los tags de fase son obligatorios; los de ejercicio son tuyos. Van en un espacio de nombres aparte
para que `git tag -l 'fase-*'` siga siendo un índice limpio:

```bash
git tag ej/f14/18          # Fase 14, ejercicio 18
git tag ej/a01/3           # apéndice a01, ejercicio 3
```

Dos casos donde valen la pena de verdad. Los **ejercicios de diagnóstico** —el catálogo de fallos de
las fases [31](31-catalogo-de-fallos-i.md) y [32](32-catalogo-de-fallos-ii.md), y el forense de la
[33](33-forense-y-boss-fight.md)— piden dos tags:

```bash
git tag ej/f31/12-roto     # el fallo reproducido, antes de tocar nada
git tag ej/f31/12-fix      # el fix aplicado y verificado
git diff ej/f31/12-roto ej/f31/12-fix
```

Ese `diff` es la corrección aislada del ruido. Y los **ejercicios de medición**, donde el número va en
el mensaje del tag y queda pegado al Dockerfile que lo produjo:

```bash
git tag -a ej/f12/20 -m "Contexto de build: <N> MB sin .dockerignore, <M> MB con él."
```

> ⚠️ **Un cuidado, uno solo.** No crees nunca un tag llamado literalmente `ej/f14`. Git guarda los
> refs como archivos: si existe `refs/tags/ej/f14`, no puede existir además el directorio
> `refs/tags/ej/f14/`, y `git tag ej/f14/18` falla con un error confuso.

---

## 📈 5. Los comandos que hacen que esto sirva

```bash
git tag -l 'fase-*'                                      # ¿dónde estoy?
git for-each-ref --sort=creatordate \
  --format='%(creatordate:short)  %(refname:short)' 'refs/tags/fase-*'   # cuándo cerré cada fase
git diff fase-04-toolchain-de-compilacion..fase-05-python-y-node-gyp --stat   # qué costó una fase
git checkout fase-06-instalacion-node -- dockerfiles/    # recuperar los Dockerfiles de una fase
git tag -n99 -l 'ej/f12/*'                               # tus mediciones de una fase
```

---

## ✅ 6. Checklist de cierre de fase

- [ ] El "📋 Checklist de validación" de la fase, en verde y verificado a mano.
- [ ] La imagen de la fase construida con su etiqueta `legacy-node-toolchain:phaseNN`, si la fase
      construye.
- [ ] `git status` limpio: todo lo de la fase está commiteado.
- [ ] `git tag -a fase-NN-slug -m "…"` creado, con el resultado de la fase en el mensaje.

> **La señal de que quedó bien:** "vuelvo después de tres semanas, corro `git tag -l 'fase-*'`, y sé
> exactamente dónde me quedé, qué imagen corresponde a cada fase y qué sigue — sin releer una sola
> línea del curso".
