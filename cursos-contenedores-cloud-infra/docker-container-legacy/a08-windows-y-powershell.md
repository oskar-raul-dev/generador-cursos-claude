# 🪟 Apéndice a08 — Windows 11, WSL2 y PowerShell

> **Curso:** Docker Legacy Node · **Apéndice opcional**
> **Cierra los bucles de:** [F09](09-montar-tu-proyecto.md) §6 · [F18](18-networking-de-contenedores.md) §7.1 · [F22](22-apple-silicon-y-hosts.md) §3
> **Requisitos:** la Parte I hecha. Aquí van las diferencias de tu plataforma
> **Fecha de revisión de comportamiento de productos:** 3 de septiembre de 2026
> **Qué encontrarás:** cómo se traducen los comandos del curso a PowerShell, dónde tiene que vivir tu proyecto para que esto no sea lento, y las tres diferencias de Windows que producen fallos que no verás en ningún otro sitio

Los ejemplos del curso están escritos para Bash y Zsh. En Windows la mayoría funcionan igual
dentro de WSL2, y unos pocos cambian. Este apéndice es esa lista.

---

## 🧭 Índice de salto rápido

| Si tu pregunta es… | Ve a |
|---|---|
| "¿Dónde pongo mi proyecto?" | [§1](#1--la-decisión-que-más-importa-dónde-vive-tu-proyecto) |
| "¿Cómo escribo las rutas en PowerShell?" | [§2](#2--rutas-y-quoting-en-powershell) |
| "¿Qué comandos del curso cambian?" | [§3](#3--la-tabla-de-traducción) |
| "Mi script falla con un error rarísimo" | [§4](#4--las-tres-trampas-de-windows) |

---

## 1. 🥇 La decisión que más importa: dónde vive tu proyecto

Antes que ningún comando, esto. **Es la diferencia entre un laboratorio ágil y uno lentísimo.**

```mermaid
flowchart TD
    subgraph MAL["❌ el proyecto en el filesystem de WINDOWS"]
        W["C:\Users\tu-usuario\proyectos\legacy-app"] -- "cada acceso desde el contenedor<br/>cruza una frontera cara" --> W2["WSL2 → Docker → contenedor"]
    end
    subgraph BIEN["✅ el proyecto en el filesystem de LINUX"]
        L["\\wsl$\Ubuntu\home\tu-usuario\proyectos\legacy-app<br/>o, desde dentro de WSL2: /home/tu-usuario/proyectos/legacy-app"] -- "sin cruce" --> L2["Docker → contenedor"]
    end
```

> 🧭 **La regla, y no admite matices: si trabajas con WSL2, tu proyecto vive dentro de WSL2.**
> Un `npm ci` sobre un proyecto en `C:\` puede tardar **cinco o diez veces más** que el mismo
> proyecto dentro de la distribución de WSL2. No es Docker: es el cruce de sistema de archivos,
> que es la versión Windows del problema de [F26](26-portabilidad-entre-motores.md) §4.2.

Y de ahí sale la recomendación práctica del apéndice:

> 🧭 **Trabaja dentro de WSL2 y usa Bash.** Abre la terminal de tu distribución, clona ahí, y
> **todos los comandos del curso funcionan tal cual**. Este apéndice pasa a ser innecesario, que
> es la mejor recomendación que puede darte.

Lo que sigue es para cuando no puedes o no quieres hacer eso.

---

## 2. 📁 Rutas y quoting en PowerShell

### 2.1 El directorio actual

```bash
# Bash / Zsh
--mount type=bind,src="$PWD",dst=/workspace
```

```powershell
# PowerShell
--mount type=bind,src="${PWD}",dst=/workspace
```

Las llaves no son decorativas: sin ellas, PowerShell puede interpretar mal la coma que sigue.

### 2.2 Rutas absolutas

```powershell
# funcionan las dos, y la segunda evita problemas de escape
--mount type=bind,src="C:\Users\tu\proyecto",dst=/workspace
--mount type=bind,src="C:/Users/tu/proyecto",dst=/workspace
```

> 💡 **Usa barras normales.** Windows las acepta, y te ahorras contar contrabarras.

### 2.3 Continuación de línea

Es el cambio que más se nota al copiar comandos del curso:

```bash
docker run \
  --rm \
  imagen
```

```powershell
docker run `
  --rm `
  imagen
```

**La contrabarra de Bash es una comilla invertida en PowerShell.** Si copias un comando del
curso tal cual, PowerShell lo va a partir mal.

> 💡 **El atajo que evita todo esto:** escribe el comando en una sola línea, o mételo en un
> script `.ps1`. Un comando largo de una línea es feo y funciona.

### 2.4 Variables

```bash
export NODE_VERSION=14.21.3
echo "$NODE_VERSION"
```

```powershell
$env:NODE_VERSION = "14.21.3"
Write-Output $env:NODE_VERSION
```

Y para pasarla a un contenedor, la sintaxis de Docker no cambia:

```powershell
docker run --rm -e "NODE_VERSION=14.21.3" legacy-node-toolchain:phase15 node --version
```

---

## 3. 🔄 La tabla de traducción

Los comandos del curso que cambian:

| Bash / Zsh | PowerShell |
|---|---|
| `$PWD` | `${PWD}` |
| `\` al final de línea | `` ` `` al final de línea |
| `export VAR=valor` | `$env:VAR = "valor"` |
| `echo "$VAR"` | `Write-Output $env:VAR` |
| `$(comando)` | `$(comando)` — igual |
| `cmd 2>&1 \| tee f.log` | `cmd 2>&1 \| Tee-Object f.log` |
| `${PIPESTATUS[0]}` | **no existe** — §4.3 |
| `id -u` | no aplica: Windows no tiene UID POSIX |
| `chmod +x` | no aplica dentro del filesystem de Windows |

**Y lo que NO cambia**, que es casi todo: `docker build`, `docker run`, `docker exec`,
`docker logs`, `--mount`, `-e`, `-p`, los nombres de imágenes, tags y volúmenes.

### 3.1 `run-dev.ps1`

El equivalente del script de [F09](09-montar-tu-proyecto.md) §7.1:

```powershell
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

# parametrizable desde fuera, como la versión Bash
$Image          = if ($env:IMAGE)          { $env:IMAGE }          else { 'legacy-node-toolchain:phase15' }
$ContainerName  = if ($env:CONTAINER_NAME) { $env:CONTAINER_NAME } else { 'legacy-node-dev' }
$NodeVersion    = if ($env:NODE_VERSION)   { $env:NODE_VERSION }   else { '10.24.1' }
$ProjectDir     = if ($env:PROJECT_DIR)    { $env:PROJECT_DIR }    else { $PWD.Path }
$ModulesVolume  = if ($env:MODULES_VOLUME) { $env:MODULES_VOLUME } else { 'legacy-node10-amd64-modules' }

# si el contenedor ya existe lo reutilizamos
docker container inspect $ContainerName *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Output "El contenedor $ContainerName ya existe. Iniciándolo si está detenido..."
    docker start $ContainerName | Out-Null
} else {
    docker volume inspect $ModulesVolume *> $null
    if ($LASTEXITCODE -ne 0) { docker volume create $ModulesVolume | Out-Null }

    Write-Output "Creando $ContainerName con Node $NodeVersion..."
    docker run -d `
        --name $ContainerName `
        --platform linux/amd64 `
        -e "NODE_VERSION=$NodeVersion" `
        --mount "type=bind,src=$ProjectDir,dst=/workspace" `
        --mount "type=volume,src=$ModulesVolume,dst=/workspace/node_modules" `
        $Image `
        sleep infinity | Out-Null
}

Write-Output ""
Write-Output "Container: $ContainerName"
Write-Output "Node:      $(docker exec $ContainerName node --version)"
Write-Output "npm:       $(docker exec $ContainerName npm --version)"
Write-Output ""
Write-Output "Entrar con:"
Write-Output "  docker exec -it $ContainerName bash"
```

**Detalles con intención:**

- **`$ErrorActionPreference = 'Stop'`** es el equivalente de `set -e`. Sin él, PowerShell sigue
  adelante tras un error.
- **`$LASTEXITCODE`** para los códigos de salida de programas externos: `$?` en PowerShell es
  booleano y no equivale al de Bash.
- **`*> $null`** silencia todos los flujos, que son más de dos.

---

## 4. 🪤 Las tres trampas de Windows

### 4.1 Finales de línea CRLF

**La más frecuente y la más desconcertante**, y ya apareció en [F32](32-catalogo-de-fallos-ii.md) §8.8:

```text
bash: ./scripts/mi-script.sh: /usr/bin/env: bad interpreter: No such file or directory
```

El archivo existe. Lo que no existe es un intérprete llamado `bash\r`.

```bash
file scripts/*.sh | grep CRLF
```

**La solución estructural**, en el repositorio:

```gitattributes
# .gitattributes
* text=auto eol=lf
*.sh   text eol=lf
*.ps1  text eol=crlf
Dockerfile text eol=lf
```

> 🧭 **Con eso, Git normaliza al hacer checkout** y el problema deja de existir para todo el
> equipo. Sin él, cada persona con Windows lo reintroduce cada vez que clona.

### 4.2 El bit de ejecución

El filesystem de Windows no tiene permisos POSIX, así que `chmod +x` no significa nada ahí. Un
script copiado desde `C:\` a la imagen puede llegar sin permiso de ejecución.

**La solución** es la que el curso ya aplica desde [F06](06-instalacion-node.md) §8: `chmod 0755` en el `Dockerfile`
después del `COPY`. Y en el repositorio, Git sí versiona el bit:

```bash
git update-index --chmod=+x scripts/mi-script.sh
```

### 4.3 `PIPESTATUS` no existe

[F20](20-validacion-sistematica-y-evidencia.md) §6.3 te enseñó a capturar el código de salida correcto de una tubería. **PowerShell no tiene
`PIPESTATUS`**, y `$LASTEXITCODE` te da el del último comando — el mismo problema que `$?` en
Bash.

**Las dos salidas:**

```powershell
# opción A: no uses tubería
docker exec $c npm ci *> install.log
$exitCode = $LASTEXITCODE

# opción B: captura primero, escribe después
$salida = docker exec $c npm ci 2>&1
$exitCode = $LASTEXITCODE
$salida | Out-File install.log
```

> ⚠️ **Es una diferencia real de tu protocolo de validación.** Si copias el paso 6 de [F11](11-validar-tu-proyecto.md) tal
> cual a PowerShell, vas a registrar éxitos falsos.

---

## 🧭 Guía rápida: cuándo usar qué

| Tu situación | Recomendación |
|---|---|
| Tienes WSL2 | **Trabaja dentro, con Bash.** Todo el curso funciona sin traducir |
| Tienes que usar PowerShell | §2 y §3, y el `.ps1` de §3.1 |
| Tu proyecto está en `C:\` y va lento | **Múevelo dentro de WSL2** — §1 |
| Un script falla con `bad interpreter` | CRLF — §4.1 |
| Tu equipo mezcla Windows y Linux | **`.gitattributes` desde el primer día** |
| Escribes un script de validación | ojo con `PIPESTATUS` — §4.3 |

---

## 🧪 Ejercicios (5)

### 🟢 Ejercicio 1 — Mide el cruce

Ejecuta `npm ci` sobre un proyecto en `C:\` y sobre el mismo dentro de WSL2, cronometrando.

**Pregunta:** ¿cuál es el factor en tu máquina? Es el argumento de §1 con tu número.

### 🟢 Ejercicio 2 — Traduce cinco comandos

Toma cinco comandos multilínea del curso y escríbelos en PowerShell.

### 🟡 Ejercicio 3 — `run-dev.ps1`

Adapta el script de §3.1 a tu proyecto y úsalo.

### 🟡 Ejercicio 4 — Provoca el CRLF

Crea un script con finales de línea CRLF y ejecútalo en el contenedor.

**Objetivo:** ver el `bad interpreter` y resolverlo con `.gitattributes`, no solo con
`dos2unix`.

### 🟠 Ejercicio 5 — El exit code correcto

Escribe en PowerShell el paso 6 del protocolo de [F11](11-validar-tu-proyecto.md) —tests, lint y build con su log y su código
de salida— sin caer en el problema de §4.3.

**Objetivo:** comprobarlo con un comando que falle y con uno que funcione.

---

## 📚 Referencias

- WSL2: https://learn.microsoft.com/windows/wsl/
- Rendimiento del sistema de archivos en WSL: https://learn.microsoft.com/windows/wsl/filesystems
- Docker Desktop con WSL2: https://docs.docker.com/desktop/features/wsl/
- PowerShell — variables de entorno: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_environment_variables
- PowerShell — redirección: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_redirection
- `gitattributes(5)`: https://git-scm.com/docs/gitattributes

**Vuelve a:** [F09](09-montar-tu-proyecto.md) · [F18 §7.1](18-networking-de-contenedores.md) · [F32 §8.8](32-catalogo-de-fallos-ii.md)
