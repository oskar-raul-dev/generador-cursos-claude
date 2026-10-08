# 🧭 Parte II · Fase 26 — Portabilidad entre motores: scripts, IDEs y la matriz de decisión

> **Curso:** Docker Legacy Node
> **Imagen:** `legacy-node-toolchain`
> **Baseline:** Debian 10 Buster (`debian/eol:buster`) · `linux/amd64`
> **Script que nace aquí:** `scripts/engine.sh`
> **Requisitos:** **[F24](24-docker-y-podman-arquitectura.md)** (arquitecturas) y **[F25](25-rootless-y-user-namespaces.md)** (rootless)
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **⚠️ Alcance de la verificación (6 de septiembre de 2026):** el barrido de verificación ejecutada del curso se corrió sobre **Docker 29.6.2** y no sobre Podman, que no estaba instalado en la máquina de referencia. **Los comandos `podman` de esta fase están contrastados contra la documentación oficial de Podman, no ejecutados**, y así se declaran por lo que pide la guía del curso: si no está verificado, se dice. Si los corres y algo no coincide, tu terminal tiene razón y este documento no.
> **Estado de la imagen al terminar:** sin cambios — cierra el bloque de motores
> **Código de esta fase:** [`src/26-portabilidad-entre-motores/`](src/26-portabilidad-entre-motores/)
> **Objetivo:** escribir scripts que funcionen en los dos motores sin volverse ilegibles, entender por qué el IDE puede fallar cuando la CLI funciona, y llegar a una matriz de decisión con tradeoffs en lugar de un podio

---

## 1. 🧭 Dónde estamos

[F24](24-docker-y-podman-arquitectura.md) comparó las arquitecturas y [F25](25-rootless-y-user-namespaces.md) el modelo de privilegios. Falta lo que usas todos los días:
**¿cómo escribo un laboratorio que funcione con los dos, y cuándo elijo cada uno?**

Esta fase cierra el bloque de motores y es la más práctica de los tres.

---

## 2. 🎯 Objetivos de esta fase

Al terminar deberías poder:

- Explicar las capas que hay entre tu comando y el contenedor en cada plataforma.
- Medir rendimiento entre motores sin sacar conclusiones que los datos no sostienen.
- Escribir scripts portables **sin caer en el mínimo común denominador miserable**.
- Diagnosticar el caso "la CLI funciona pero el IDE no".
- Validar el mismo fixture en los dos motores y comparar con evidencia.
- Aplicar una matriz de decisión que dé una recomendación, no un empate.

---

## 3. 🚧 Qué NO entra todavía

- **Registries y publicación**, que es donde los dos motores vuelven a converger → **[F27](27-registries-por-dentro.md)** y
  **[F28](28-publicar-la-imagen.md)**.
- **Colima y Lima** → **[a07](a07-colima-y-lima.md)**; **Windows y WSL2** → **[a08](a08-windows-y-powershell.md)**.
- **Compose** en los dos → **[a10](a10-docker-compose.md)**.

---

## 4. 🧅 Las capas, por plataforma

Antes de medir nada hay que saber **qué** estás midiendo, porque el motor casi nunca es la única
capa.

### 4.1 Linux nativo — la comparación limpia

```text
tu comando  →  motor  →  kernel del host  →  contenedor
```

Sin virtualización de por medio. Es donde una comparación entre Docker y Podman mide de verdad
los motores.

### 4.2 macOS — dos capas más

```mermaid
flowchart TD
    C["tu comando (macOS)"] --> VM["VM Linux del motor<br/>Docker Desktop, Podman Machine o Colima"]
    VM --> K["kernel Linux"]
    VM --> FS["file sharing<br/>virtiofs, gRPC-FUSE… los bind mounts pasan por aquí"]
    VM --> CT["contenedor"]
```

**Los bind mounts cruzan la frontera macOS ↔ VM**, y ese cruce es el cuello de botella real de
casi todo lo lento en un Mac. No es el motor: es el sistema de compartición de archivos.

### 4.3 Windows

Parecido, con WSL2 como capa de virtualización. El detalle está en **[a08](a08-windows-y-powershell.md)**, y la conclusión
importante es la misma: **un proyecto en el sistema de archivos de Windows, montado en un
contenedor de WSL2, cruza una frontera cara**. Tenerlo dentro de WSL2 cambia mucho las cosas.

> 🧭 **No atribuyas todo al motor.** Antes de concluir "Podman es más lento que Docker",
> pregúntate si estás comparando motores o estás comparando dos VM con configuraciones
> distintas y dos sistemas de compartición distintos.

### 4.4 Inspecciona tus capas

```bash
# Docker Desktop
docker info --format '{{.OperatingSystem}} · {{.KernelVersion}} · {{.NCPU}} CPU · {{.MemTotal}}'

# Podman Machine
podman machine inspect | jq '.[0] | {Name, Resources, Rootful}'
podman info --format '{{.Host.OS}} · {{.Host.Kernel}}'

# Colima
colima status
```

---

## 5. 📏 Rendimiento: qué se puede medir y qué no

Las reglas de [F23](23-estudios-de-caso-multiplataforma.md) §5.1 valen igual, con dos añadidos propios de esta comparación.

### 5.1 Lo que sí puedes medir

**En tu máquina, con tu configuración:** tiempo de build en frío y en caliente, tiempo de
arranque, y el I/O de un `npm ci` sobre bind mount y sobre volumen.

### 5.2 Lo que NO puedes afirmar con un portátil

- Que un motor sea "más rápido" en general.
- Que el resultado se traslade a otro hardware, a otra versión, o a Linux si mediste en macOS.
- Que la diferencia venga del motor y no de la VM.

> ⚠️ **Y la comparación más injusta y más frecuente:** medir Docker Desktop con una VM de 8 CPU
> y 16 GB contra un Podman Machine recién instalado con los valores por defecto. Iguala los
> recursos primero — §4.4 te dice cuáles tiene cada uno.

### 5.3 El benchmark mínimo reproducible

```bash
# COLD BUILD — sin caché, mide el trabajo completo
docker builder prune -af >/dev/null 2>&1
/usr/bin/time -p docker build --no-cache --platform linux/amd64 -t bench:docker .

podman rmi -a -f >/dev/null 2>&1
/usr/bin/time -p podman build --no-cache --platform linux/amd64 -t bench:podman .

# WARM BUILD — con caché, mide lo que haces veinte veces al día
/usr/bin/time -p docker build --platform linux/amd64 -t bench:docker .
/usr/bin/time -p podman build --platform linux/amd64 -t bench:podman .

# ARRANQUE
/usr/bin/time -p docker run --rm bench:docker node -e ''
/usr/bin/time -p podman run --rm bench:podman node -e ''

# I/O: el mismo npm ci, en volumen y en bind mount
```

**Y declara el contexto siempre**, como en [F23](23-estudios-de-caso-multiplataforma.md): hardware, sistema, versiones de los dos motores,
recursos de cada VM, y mecanismo de traducción si estás emulando.

> 🧠 **El número que decide, otra vez, no es el factor bruto.** Es cuánto te cuesta el ciclo
> real de un día de trabajo. Un cold build 30 segundos más lento no importa si lo haces una vez
> por semana.

---

## 6. 🧰 Scripts portables sin el mínimo común denominador

El error tentador es escribir scripts que solo usen lo que los dos motores comparten. El
resultado es un laboratorio que no aprovecha nada de ninguno.

**La estrategia mejor:** una capa fina de abstracción que **detecte** el motor y aplique las
diferencias donde de verdad las hay.

📄 **`scripts/engine.sh`**

```bash
#!/usr/bin/env bash
# Capa fina sobre docker/podman: detecta el motor y expone sus diferencias
# como variables, en lugar de esconderlas tras una abstracción gruesa.

set -euo pipefail

# ENGINE puede forzarse desde fuera: ENGINE=podman ./scripts/run-dev.sh
ENGINE="${ENGINE:-}"

if [[ -z "${ENGINE}" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then
        ENGINE=podman
    else
        echo "ERROR: no encuentro un motor de contenedores utilizable." >&2
        echo "Instala Docker o Podman, o exporta ENGINE=<motor>." >&2
        exit 69
    fi
fi

# Las diferencias reales, expuestas como variables en vez de ocultas
case "${ENGINE}" in
    docker)
        HOST_ALIAS='host.docker.internal'
        VOLUME_OPTS=''            # Docker no necesita :U ni :z
        ;;
    podman)
        HOST_ALIAS='host.containers.internal'
        # :U ajusta el ownership del volumen (F17 §7); solo tiene sentido en Podman
        VOLUME_OPTS=',U'
        ;;
    *)
        echo "ERROR: motor no soportado: ${ENGINE}" >&2
        exit 64
        ;;
esac

export ENGINE HOST_ALIAS VOLUME_OPTS

engine() { command "${ENGINE}" "$@"; }
```

Y su uso:

```bash
source scripts/engine.sh

engine volume create "${MODULES_VOLUME}"
engine run -d --name "${CONTAINER_NAME}" \
    --mount "type=volume,src=${MODULES_VOLUME},dst=/workspace/node_modules${VOLUME_OPTS}" \
    --add-host "${HOST_ALIAS}=host-gateway" \
    ...
```

**Detalles con intención:**

- **`ENGINE` se puede forzar desde fuera**, para poder comparar los dos sin editar nada — que
  es justo lo que pide §8.
- **La detección comprueba que Docker *responde***, no solo que el binario existe. Un `docker`
  instalado con el daemon parado es el falso positivo más común.
- **Las diferencias se exponen como variables**, no se esconden. Quien lea el script ve que hay
  un `VOLUME_OPTS` y puede preguntarse por qué — que es mejor que una abstracción que "lo
  arregla".
- **Falla con códigos distintos** según sea "no hay motor" o "motor desconocido".

> 🧭 **La regla:** abstrae **después** de conocer las diferencias, y abstrae **poco**. Un
> wrapper que oculta que Podman necesita `:U` no te ha ahorrado el problema: te ha quitado la
> pista para cuando falle.

---

## 7. 🟦 Cuando la CLI funciona y el IDE no

Un escenario frecuente y desconcertante: `podman run` funciona perfectamente desde la terminal,
y VS Code no abre el Dev Container.

**La causa casi siempre es la misma:** las herramientas no hablan con namespaces, **hablan con
un socket compatible con la API de Docker**. Si ese socket no está, la herramienta no encuentra
nada — aunque tu motor esté impecable.

```bash
# levanta el servicio de Podman (F24 §5.4)
systemctl --user start podman.socket
systemctl --user enable podman.socket

# y apunta el cliente ahí
export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/podman/podman.sock"
docker ps    # el cliente de Docker hablando con Podman
```

En VS Code, la configuración equivalente es indicarle qué socket usar.

### 7.1 El diagnóstico, en orden

```mermaid
flowchart TD
    Q1{"1 · ¿funciona el motor desde la terminal?<br/>podman run --rm alpine echo ok"}
    Q1 -- "no" --> R1["el problema es el motor, no el IDE"]
    Q1 -- "sí" --> Q2{"2 · ¿existe el socket compatible?<br/>ls -la $XDG_RUNTIME_DIR/podman/podman.sock"}
    Q2 -- "no" --> R2["§7, levántalo"]
    Q2 -- "sí" --> Q3{"3 · ¿el cliente de Docker lo alcanza?<br/>DOCKER_HOST=... docker ps"}
    Q3 -- "no" --> R3["permisos o ruta del socket"]
    Q3 -- "sí" --> R4["4 · ahora sí, es configuración del IDE<br/>mira su log de Dev Containers"]
```

> 🧭 **La regla que evita perder tardes: compatibilidad del IDE ≠ compatibilidad del motor.**
> Son dos cosas distintas y se diagnostican por separado. Es la misma idea de [F10](10-vscode-y-debugging.md) §8 —*"¿falla
> también desde la terminal?"*—, aplicada un nivel más abajo.

Y una advertencia honesta: el soporte de los IDEs para Podman **ha mejorado mucho y sigue
cambiando**. Lo que no funcionaba hace un año puede funcionar hoy. Verifica antes de concluir.

---

## 8. 🧪 Valida el mismo fixture en los dos

La evidencia que cierra el bloque:

```bash
source scripts/engine.sh

for eng in docker podman; do
  command -v "$eng" >/dev/null 2>&1 || continue
  vol="crossengine-vue2-node10-amd64-${eng}"      # ⚠️ un volumen POR MOTOR
  "$eng" volume rm "$vol" >/dev/null 2>&1 || true
  "$eng" volume create "$vol" >/dev/null

  printf '%-8s ' "$eng"
  "$eng" run --rm --platform linux/amd64 \
    -e NODE_VERSION=10.24.1 \
    --mount "type=bind,src=$PWD/src/11-validar-tu-proyecto/10-vue2-min,dst=/workspace" \
    --mount "type=volume,src=${vol},dst=/workspace/node_modules" \
    legacy-node-toolchain:phase15 \
    bash -c 'npm ci >/dev/null 2>&1 && printf "ci=✅ " || printf "ci=❌ "
             npm run build >/dev/null 2>&1 && printf "build=✅\n" || printf "build=❌\n"'
done
```

> ⚠️ **Un volumen por motor, y esto no es opcional.** [F24](24-docker-y-podman-arquitectura.md) §9 lo dijo: los almacenes son
> distintos, pero un bind mount al mismo directorio del host sí es compartido. Reutilizar el
> mismo `node_modules` entre motores durante una comparación contamina el resultado de una forma
> que **no da error** — simplemente mides otra cosa.

---

## 9. ⚖️ La matriz de decisión

Tradeoffs, no podio. Cada fila es una situación real.

| Tu situación | Recomendación | Por qué |
|---|---|---|
| Empiezas y no tienes preferencia | **Docker Desktop** | más documentación, más tutoriales, menos fricción |
| Licencia de Docker Desktop es un problema | **Podman Desktop** o **Colima** | los dos corren este laboratorio entero |
| Te importa el modelo de privilegios | **Podman rootless** | [F25](25-rootless-y-user-namespaces.md) §9.2, y es el mejor argumento del curso |
| Linux nativo y quieres lo más simple | **Podman** | rootless natural, sin daemon que gestionar |
| Tu equipo usa Dev Containers a diario | **Docker**, o Podman con el socket comprobado | §7 |
| Dependes de Compose intensivamente | **Docker** | integración nativa, cobertura completa |
| Necesitas pods o vas hacia Kubernetes | **Podman** | [F24](24-docker-y-podman-arquitectura.md) §10.1 |
| Tu CI ya usa uno de los dos | **el mismo en local** | reduce las diferencias que tendrás que diagnosticar |
| Ejecutas código legacy sin auditar | **Podman rootless** | reduce el radio de daño de verdad |
| Ya tienes todo funcionando con uno | **quédate** | migrar cuesta (F24, ejercicio 24) y el beneficio tiene que justificarlo |

> 🧭 **La recomendación honesta del curso**, y no es un empate: **si no tienes una razón
> concreta para cambiar, usa el que ya usas.** Los dos corren este laboratorio entero. Y si
> vas a elegir de cero, mira las filas 3 y 9: son las dos donde la diferencia es sustantiva y
> no de comodidad.

---

## 10. ⚠️ Errores comunes y diagnóstico

**"Podman es más lento".** ¿Igualaste los recursos de las VM? §5.2.

**Un script funciona con uno y falla con otro.** La tabla de [F24](24-docker-y-podman-arquitectura.md) §8 y el `engine.sh` de §6.

**El IDE no ve Podman.** §7, y el diagnóstico de §7.1.

**`:U` falla con Docker.** Es una opción de Podman. Por eso `VOLUME_OPTS` está vacío en Docker.

**La comparación da resultados raros.** Volumen compartido entre motores. §8.

**`docker` existe pero `docker info` falla.** El daemon está parado. Es lo que la detección de
§6 comprueba.

**Todo va lento en macOS con los dos motores.** No es el motor: es el cruce del bind mount.
§4.2, y `node_modules` en volumen —[F09](09-montar-tu-proyecto.md)— es la mitigación que el curso ya aplicaba.

---

## 11. 📋 Checklist de validación

```text
[ ] Sabes qué capas hay entre tu comando y el contenedor en tu plataforma
[ ] Igualaste los recursos de las VM antes de medir
[ ] Mediste cold build, warm build y arranque en los dos
[ ] Declaraste el contexto de cada medición
[ ] scripts/engine.sh detecta el motor y expone las diferencias
[ ] Puedes forzar ENGINE desde fuera para comparar
[ ] Sabes levantar el socket compatible de Podman
[ ] Recorriste el diagnóstico de §7.1 al menos una vez
[ ] Validaste el mismo fixture en los dos, con volúmenes separados
[ ] Recorriste la matriz de §9 y llegaste a una recomendación para tu caso
```

---

## 12. 🧪 Ejercicios de la Fase 26 (20)

## 🟢 Fácil — medir tu propia pila (1–5)

### 🟢 Ejercicio 1 — Tus capas

Ejecuta los comandos de §4.4 para el motor que uses.

**Pregunta:** ¿cuántos CPU y cuánta RAM tiene tu VM? ¿Es lo que esperabas?

### 🟢 Ejercicio 2 — Iguala los recursos

Si tienes los dos motores, configura sus VM con los mismos recursos.

**Objetivo:** dejar la comparación en condiciones antes de medir nada.

### 🟢 Ejercicio 3 — Cold build en los dos

Ejecuta los dos cold builds de §5.3, cronometrando.

**Pregunta:** ¿cuánta diferencia hay? ¿Es la que esperabas?

### 🟢 Ejercicio 4 — Warm build

Repite sin limpiar la caché.

**Pregunta:** ¿cambió el orden? ¿Cuál de los dos números representa mejor tu día a día?

### 🟢 Ejercicio 5 — El arranque

Mide el arranque de un contenedor en los dos, cinco veces cada uno.

**Objetivo:** ver la variación entre corridas antes de sacar conclusiones de una sola.

## 🟡 Intermedio — escribir scripts portables (6–12)

### 🟡 Ejercicio 6 — El socket de Podman

Levanta `podman.socket` y ejecuta `docker ps` apuntando ahí.

**Objetivo:** ver al cliente de Docker hablando con Podman.

### 🟡 Ejercicio 7 — `engine.sh`

Escribe el script de §6 y úsalo para ejecutar un contenedor con cada motor.

### 🟡 Ejercicio 8 — Porta tu `run-dev.sh`

Adapta el script de [F09](09-montar-tu-proyecto.md) para que use `engine.sh`.

**Objetivo:** que `ENGINE=podman ./scripts/run-dev.sh` funcione sin editar nada más.

### 🟡 Ejercicio 9 — El bind mount, medido

Mide `npm ci` con `node_modules` en volumen y en bind mount, en tu plataforma, con los dos
motores.

**Pregunta:** ¿cuál de las dos variables pesa más: el motor o el tipo de montaje? Ahí está §4.2
con números.

### 🟡 Ejercicio 10 — Valida en los dos

Ejecuta el bucle de §8 sobre dos fixtures.

**Objetivo:** la evidencia cruzada, con volúmenes separados.

### 🟡 Ejercicio 11 — Dev Containers con Podman

Configura VS Code para abrir tu Dev Container con Podman.

**Objetivo:** que funcione, o llegar hasta el paso del diagnóstico de §7.1 donde se atasca.

### 🟡 Ejercicio 12 — Un script que falla bien

Modifica `engine.sh` para que, si no encuentra motor, el mensaje diga qué instalar según la
plataforma.

**Objetivo:** un error que ayude, que es la diferencia entre un script propio y uno prestado.

## 🟠 Difícil — cuando la portabilidad se rompe (13–17)

### 🟠 Ejercicio 13 — Contamina la comparación

Repite el ejercicio 10 **compartiendo** el volumen entre motores.

**Pregunta:** ¿cambió algún resultado? ¿Te habrías dado cuenta si no lo supieras?

### 🟠 Ejercicio 14 — El diagnóstico completo

Rompe deliberadamente el paso 2 de §7.1 —para el socket— y recorre el diagnóstico entero.

### 🟠 Ejercicio 15 — El script del mínimo común denominador

Escribe la versión "portable" mala del laboratorio: solo lo que los dos comparten, sin
`engine.sh`.

**Pregunta:** ¿qué tuviste que renunciar? ¿Cuántas funcionalidades del laboratorio se perdieron?
Compáralo con la estrategia de §6.

### 🟠 Ejercicio 16 — Windows o Linux

Si tienes acceso a otra plataforma, ejecuta el laboratorio ahí y compara con la tuya.

**Objetivo:** encontrar las diferencias que no son del motor sino de la plataforma — §4.

### 🟠 Ejercicio 17 — El IDE que sí, la CLI que no

Construye el escenario inverso a §7: la CLI falla y el IDE parece funcionar.

**Pregunta:** ¿es posible? ¿Qué estaría usando el IDE? Es más raro y ocurre.

## 🔴 Muy difícil — informe y decisión (18–20)

### 🔴 Ejercicio 18 — La comparación injusta

Diseña deliberadamente una comparación que haga parecer a un motor mucho más lento que el otro,
**sin mentir en ningún número**.

**Objetivo:** entender cómo se producen las comparaciones sesgadas que circulan, para
reconocerlas. Después, corrígela.

### 🔴 Ejercicio 19 — Decide dónde va cada diferencia

Revisa las nueve diferencias de la tabla de [F24](24-docker-y-podman-arquitectura.md) §8 y decide, una a una, si van en `engine.sh`,
en el script que las usa, o en la documentación para que la persona decida.

**Objetivo:** llegar a que **no todas** deben abstraerse. Justifica al menos dos que dejes
visibles a propósito, con el criterio de §6: una abstracción que oculta una pista es peor que la
diferencia.

### 🔴 Ejercicio 20 — El informe de motor para tu equipo

Con tus mediciones y la matriz de §9, escribe la recomendación de motor para tu equipo.

**Objetivo:** una decisión con condiciones, no un "depende". Y con la fila de la matriz que la
justifica señalada explícitamente.

## 🔥 Opcionales

### 🔥 Ejercicio 21 — `DOCKER_HOST` a un host remoto

Configura `DOCKER_HOST` apuntando a un motor de otra máquina por SSH y ejecuta el laboratorio.

**Pregunta:** ¿qué se rompe? Los bind mounts, seguro. ¿Por qué?

### 🔥 Ejercicio 22 — Mide `virtiofs` contra la alternativa

En Docker Desktop, cambia el sistema de compartición de archivos si tu versión lo permite y
repite el ejercicio 9.

**Objetivo:** poner número a §4.2 y confirmar que el cuello de botella no era el motor.

## 💀 Boss fight

### 💀 Ejercicio 23 — Boss fight: el laboratorio que corre en todo

Toma el laboratorio completo —imagen, scripts, `devcontainer.json`, protocolo de validación— y
haz que funcione en **las cuatro combinaciones**: Docker en Linux, Docker en macOS, Podman
rootless en Linux, Podman en macOS.

**Objetivo:** la entrega es el conjunto de scripts, la lista de diferencias que tuviste que
manejar —y dónde las manejaste, porque esconderlas todas en `engine.sh` no siempre es lo
correcto—, y la **matriz de verificación**: por cada combinación, qué comprobaste y con qué
comando. Termina con lo más honesto: **qué combinación quedó peor y por qué decidiste
aceptarlo**. Un laboratorio que funciona en cuatro entornos siempre tiene un favorito, y decir
cuál es vale más que fingir que no lo tiene.

---

## 13. 📚 Referencias

**Motores y plataformas**
- Docker Desktop: https://docs.docker.com/desktop/
- Podman Machine: https://docs.podman.io/en/latest/markdown/podman-machine.1.html
- Podman Desktop: https://podman-desktop.io/docs
- Colima: https://github.com/abiosoft/colima
- El servicio de Podman compatible con la API: https://docs.podman.io/en/latest/markdown/podman-system-service.1.html

**IDEs**
- Dev Containers y otros motores: https://code.visualstudio.com/docs/devcontainers/containers
- WebStorm y Docker: https://www.jetbrains.com/help/webstorm/docker.html

**Medición**
- `time(1)`: https://manpages.debian.org/buster/time/time.1.en.html

> ⚠️ **Es, con [F22](22-apple-silicon-y-hosts.md), la fase que más rápido envejece.** El soporte de los IDEs para Podman
> mejora cada versión y los sistemas de compartición de archivos cambian. **Verifica antes de
> concluir que algo no funciona.** Enlaces revisados el 3 de septiembre de 2026.

**Orden de lectura sugerido:** la documentación de tu motor y de tu plataforma; el servicio de
Podman antes del ejercicio 6.

---

## 14. 🏁 Resultado de la fase

```text
LAS CAPAS       Linux nativo   comando → motor → kernel → contenedor
                macOS/Windows  + VM + file sharing ← el cuello de botella real

MEDIR           iguala los recursos de las VM ANTES de comparar
                cold build · warm build · arranque · I/O
                y declara el contexto, siempre

PORTABILIDAD    engine.sh: detecta el motor y EXPONE las diferencias
                abstrae poco, y después de conocerlas
                el mínimo común denominador es peor que dos ramas honestas

IDE ≠ MOTOR     las herramientas hablan con un socket, no con namespaces
                diagnóstico en cuatro pasos: motor → socket → cliente → IDE

MATRIZ          tradeoffs, no podio
                si no tienes una razón concreta, usa el que ya usas
                las dos razones sustantivas: privilegios y pods
```

> **La señal de que quedó bien:** *"puedo ejecutar el laboratorio completo con los dos motores
> cambiando una variable de entorno — y cuando algo difiere, sé si es del motor, de la VM o del
> sistema de archivos."*

En **[F27](27-registries-por-dentro.md)** dejamos los motores y entramos en el último bloque técnico: qué es un registry por
dentro, y qué significa de verdad que una imagen tenga un digest.
