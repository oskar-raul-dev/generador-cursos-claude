# 🛠️ Fase 00 — Ambiente, tooling y el comando `go`

> Go para desarrolladores Java senior · Fase 0 de 17 · **5 horas**
> Época: **previa** — se instalan las dos, y se explica por qué hay dos
> Depende de: ninguna · Habilita: Fase 01
> Proyectos que avanzan: ninguno todavía; nace el monorepo de Meridian
> Mini proyectos: `hello-go`, `build-info`, `crossbuild`

---

## 🎯 1. Propósito

Esta es la única fase del curso sin una línea de código de negocio, y no es
opcional: **la mitad de la frustración de alguien que llega a Go desde Java no
viene del lenguaje, viene del toolchain**. Vienes de un mundo donde el IDE
resuelve las dependencias, el `pom.xml` declara el build y "compilar" es un botón.
Go te entrega un único binario llamado `go` que hace todo eso y espera que lo
manejes desde la terminal.

Al terminar esta fase tienes la máquina lista, el monorepo de Meridian creado, y
—más importante— sabes qué hace cada subcomando de `go`, qué archivos genera y
dónde deja las cosas. Eso es lo que te permite leer un repositorio ajeno el lunes
sin preguntarle a nadie dónde está el equivalente del `mvn clean install`.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `go version` responde con la versión moderna del curso y `go1.13 version`
      responde con `go1.13`.
- [ ] `go env GOROOT GOPATH GOMODCACHE GOBIN` devuelve rutas que reconoces y
      puedes explicar.
- [ ] El monorepo `meridian/` existe con un módulo por servicio, `labs/`, el
      `Makefile` y el `compose.yaml`.
- [ ] `make up` levanta PostgreSQL, MongoDB y Valkey; `make down` los apaga sin
      dejar volúmenes huérfanos.
- [ ] `labs/hello-go` compila, corre y ya te dio tu primer
      `declared and not used`.
- [ ] `labs/build-info` imprime versión, commit y fecha inyectados con
      `-ldflags`.
- [ ] `labs/crossbuild` produce cinco binarios para cinco plataformas con un solo
      comando, y sabes cuánto pesa cada uno.
- [ ] `golangci-lint run ./...` corre en verde sobre el monorepo vacío.
- [ ] Tu editor —VS Code o GoLand— formatea al guardar, salta a definición y
      corre un test con un clic.

---

## 🚫 3. Qué NO entra todavía

- Sintaxis del lenguaje → Fase 01. Aquí escribimos exactamente tres programas y
  ninguno pasa de veinte líneas.
- `go.work` y los *workspaces* → Fase 08 🕰️ (Go 1.18). Duele, porque el monorepo
  con cuatro módulos independientes es justo el caso que `go.work` resuelve, pero
  el Bloque A es 1.13 y hasta entonces los módulos se manejan sueltos.
- `go tool` con dependencias de herramientas declaradas en el `go.mod` → Fase 08
  🕰️ (Go 1.24). Hasta entonces las herramientas se instalan con `go install`.
- Tests → Fase 04. Aquí solo verificamos que `go test ./...` corre y dice "no test
  files", que ya es información.
- Docker más allá de `compose up` → Fase 14, donde construimos la imagen del
  servicio de verdad.

---

## 🧠 4. Concepto mínimo

### Un binario en vez de un ecosistema

En Java tienes un JDK (que instalas con SDKMAN o a mano), un gestor de
dependencias y build (Maven o Gradle), un formateador (Spotless), un analizador
estático (Checkstyle, SpotBugs, Error Prone) y un runner de tests (Surefire). Son
cinco decisiones, cinco configuraciones y cinco versiones que mantener alineadas.

En Go hay un binario: `go`. Compila, resuelve dependencias, corre tests, formatea,
analiza, genera documentación, instala herramientas y compila para otra
plataforma. No hay un `pom.xml` con doscientas líneas de plugins, porque la mayor
parte de lo que esos plugins hacen ya está dentro del comando.

```bash
go version
# go version go1.25.1 darwin/arm64
```

Esa línea te dice tres cosas: la versión, el sistema operativo y la arquitectura
para la que ese toolchain compila **por defecto**. Guárdatela, porque en cuanto
lleguemos a la compilación cruzada vas a cambiar las dos últimas a voluntad.

### Por qué instalamos dos versiones

El Bloque A del curso (Fases 00–07) se escribe en **Go 1.13**, y no por nostalgia.
Sin genéricos no hay dónde esconder un diseño perezoso; sin `log/slog` se ve qué
es realmente un log estructurado; y sin el `ServeMux` moderno hay que escribir el
enrutado HTTP a mano una vez, que es la única forma de entender qué hace Spring
MVC por debajo de `@GetMapping`.

El problema es que **el compilador moderno acepta casi todo el código de 1.13 y no
te avisa cuando usas una API posterior**. Si solo tienes el toolchain moderno
instalado, la disciplina de época es voluntad pura. Con `go1.13` instalado de
verdad, el compilador te la impone:

```bash
go install golang.org/dl/go1.13@latest
go1.13 download
go1.13 version
# go version go1.13 darwin/amd64
```

> 📝 **Nota de época.** `go1.13` no trae binario nativo para Apple Silicon: el
> soporte `darwin/arm64` llegó en Go 1.16. En un Mac M-series el binario de 1.13
> corre bajo Rosetta 2 y funciona perfectamente para lo que hace el curso. Si
> Rosetta no está instalada, `softwareupdate --install-rosetta` la deja lista.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"lo primero es elegir el gestor de dependencias y el layout del
proyecto"*. En Java es un reflejo correcto y caro de cambiar después: Maven o
Gradle, multi-módulo o no, `src/main/java` y su espejo en `src/test/java`, el BOM
de Spring, el plugin de compilador con su `<release>`. Media hora de decisiones
antes de escribir la primera clase.

**Qué pasa si lo aplicas aquí:** que buscas el equivalente, encuentras cuatro
blogs con cuatro layouts distintos —casi todos derivados de un repositorio
llamado `golang-standards/project-layout` que no es un estándar de nada— y
terminas creando `pkg/`, `api/`, `configs/`, `scripts/` y `deployments/` vacíos
para un servicio que todavía no existe.

**Qué pensar en su lugar:** en Go el gestor de dependencias viene decidido (son
los módulos, y no hay alternativa) y **el layout emerge del código**. Un módulo
nuevo es literalmente esto:

```bash
mkdir -p services/opsreport && cd services/opsreport
go mod init github.com/meridian/opsreport
```

Dos líneas, un archivo de tres líneas, cero directorios vacíos. Los paquetes
aparecen cuando hay algo que poner dentro. Esa es la primera diferencia cultural
del curso y vas a tropezar con ella varias veces: **en Go, la estructura es un
resultado, no un punto de partida.**

### 🩻 Esto sí funciona igual

Más de lo que parece, y conviene decirlo para que no desconfíes de todo:

- **El versionado semántico es el mismo** y el `go.sum` cumple exactamente el
  papel del `pom.xml.sha1` más el lockfile: fija el hash de lo que descargaste
  para que nadie te cambie un artefacto bajo los pies. Se commitea, como el
  `gradle.lockfile`.
- **Hay un caché local de dependencias**, `GOMODCACHE`, que es el `~/.m2` de toda
  la vida. Se puede borrar entero y se vuelve a llenar solo.
- **Hay un proxy de módulos**, `proxy.golang.org`, que hace el papel de Maven
  Central. Y se puede apuntar a uno privado con `GOPRIVATE` y `GOPROXY`, igual
  que apuntas Maven a Nexus o Artifactory.
- **La compilación es determinista y cacheada.** `go build` dos veces seguidas no
  recompila nada, como el *incremental build* de Gradle.
- **El linter se configura con un YAML en la raíz** y se corre en CI. Checkstyle
  te suena; `golangci-lint` se usa igual.

---

## 🛠️ 5. CLI de la fase

Esta sección existe en las dieciocho fases y es el eje transversal de línea de
comandos del curso. Aquí es especialmente larga porque es *toda* la fase.

```bash
# Muestra la configuración efectiva del toolchain. Sin argumentos lista todo;
# con nombres de variable, solo esas. Es el primer comando que corres cuando
# algo no compila y no entiendes por qué.
go env
go env GOROOT GOPATH GOMODCACHE GOBIN GOFLAGS

# Escribe una variable de forma persistente en el archivo de configuración del
# usuario (~/.config/go/env). No toca tu shell ni tu ~/.zshrc.
go env -w GOBIN="$HOME/go/bin"

# Crea el go.mod del módulo. El argumento es la RUTA DE IMPORTACIÓN del módulo,
# no un nombre bonito: es lo que otros escribirán en su import.
go mod init github.com/meridian/opsreport

# Compila el paquete y deja el binario en el directorio actual. Con -o eliges
# nombre y destino. Sin -o en un paquete no-main, solo verifica que compila y
# no escribe nada.
go build ./...
go build -o bin/opsreport ./cmd/opsreport

# Compila a un binario temporal y lo ejecuta. Para desarrollo; nunca para
# producción, porque recompila cada vez.
go run ./cmd/opsreport

# Corre los tests del paquete y sus subdirectorios. ./... es el patrón que
# significa "este paquete y todo lo que cuelga de él".
go test ./...

# Analizador estático que trae el toolchain. Detecta el subconjunto de errores
# que son casi siempre bugs: Printf con verbo equivocado, métodos que no
# implementan la interfaz que parecen implementar, locks copiados por valor.
go vet ./...

# Formatea. No tiene opciones de estilo porque no hay estilo personal en Go.
# -l lista los archivos que cambiarían, -w los reescribe.
gofmt -l .
go fmt ./...

# Resuelve dependencias: añade lo que el código importa, quita lo que ya no.
# Es el comando que corres cuando el compilador dice "no required module
# provides package".
go mod tidy

# Descarga al caché local sin compilar. Útil en el Dockerfile, para que la capa
# de dependencias se cachee aparte del código.
go mod download

# Muestra el grafo de por qué una dependencia está en tu proyecto. El
# equivalente exacto de `mvn dependency:tree`, pero para una sola dependencia.
go mod why github.com/jackc/pgx/v5
go mod graph

# Documentación desde la terminal, sin navegador. Sobre un paquete de la stdlib
# o sobre el tuyo.
go doc strings.Builder
go doc ./internal/workitem WorkItem

# Lista paquetes o módulos con formato configurable. Es la herramienta de
# scripting del toolchain y casi nadie la usa; en la Fase 08 nos salvará la vida.
go list ./...
go list -m all
go list -f '{{.ImportPath}} {{.Imports}}' ./...

# Instala un binario de un módulo en $GOBIN, sin tocar el go.mod de tu proyecto.
# El @version es obligatorio desde Go 1.16 y es una buena decisión de diseño.
go install golang.org/x/tools/cmd/goimports@latest

# Borra cachés. -testcache es el que más vas a usar: obliga a que los tests
# vuelvan a correr aunque nada haya cambiado.
go clean -testcache
go clean -modcache   # cuidado: rebaja varios cientos de megas y hay que redescargar

# Ejecuta las directivas //go:generate del código. No corre en el build: es un
# comando aparte y deliberado.
go generate ./...

# Compilación cruzada. Dos variables de entorno y ya está: sin toolchain extra,
# sin contenedor, sin plugin.
GOOS=linux GOARCH=amd64 go build -o bin/opsreport-linux-amd64 ./cmd/opsreport

# Lista todas las combinaciones de plataforma que el toolchain soporta.
go tool dist list
```

> 💡 **El `./...` que hay que interiorizar.** Casi todos los subcomandos aceptan
> un patrón de paquetes. `.` es el paquete del directorio actual; `./...` es ese
> y todos los de abajo; `all` son todos los del módulo más sus dependencias. El
> 90% de los comandos del curso terminan en `./...`.

---

## 💻 6. Construcción guiada

### 6.1 Instalación de los dos toolchains

**macOS (Apple Silicon o Intel).** La forma que menos sorpresas da es el
instalador oficial de https://go.dev/dl/, porque deja `GOROOT` en
`/usr/local/go` y añade `/usr/local/go/bin` al `PATH` del sistema. Con Homebrew
también funciona (`brew install go`) y algunas cosas quedan en otra ruta; si eliges
ese camino, no mezcles los dos.

```bash
go version
# go version go1.25.1 darwin/arm64
```

**Linux.** Descarga el tarball, y **borra la instalación anterior antes de
descomprimir**, que es el error clásico:

```bash
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin   # añádelo a ~/.bashrc o ~/.zshrc
```

**Windows 11.** El MSI de la página oficial ajusta el `PATH` solo. Desde
PowerShell todo lo demás del curso funciona igual; donde el comando difiera de
verdad lo vas a ver en el mismo bloque, así:

```powershell
# PowerShell: variables de entorno para una sola invocación
$env:GOOS="linux"; $env:GOARCH="amd64"; go build -o bin/opsreport-linux-amd64 ./cmd/opsreport
```

**Y ahora la de 1.13**, que es la que hace posible el Bloque A:

```bash
go install golang.org/dl/go1.13@latest
go1.13 download
go1.13 version
# go version go1.13 darwin/amd64
```

Lo que acaba de pasar merece un párrafo, porque enseña cómo funciona `go install`:
descargaste un módulo cuyo único contenido es un programa de treinta líneas que,
al ejecutarlo con `download`, se baja el SDK de 1.13 completo a `~/sdk/go1.13` y
se deja a sí mismo como un ejecutable llamado `go1.13` en `$GOBIN`. A partir de
ahí, `go1.13 build` es exactamente `go build` con el toolchain de 2019.

> 🧪 **Prueba de fuego.** Corre esto y mira la diferencia:
>
> ```bash
> go env GOROOT
> go1.13 env GOROOT
> ```
>
> El primero apunta a `/usr/local/go`, el segundo a `~/sdk/go1.13`. Son dos
> compiladores, dos librerías estándar y dos cachés de build distintos conviviendo
> sin pisarse. **La mentira que te va a contar la pantalla:** `go version` en el
> directorio del Bloque A seguirá diciendo la versión moderna, porque la versión
> del comando no tiene nada que ver con la directiva `go` del `go.mod`. Para el
> Bloque A, el comando que cuenta es `go1.13`.

### 6.2 Las variables de entorno, y por qué casi ninguna te importa

Este bloque existe porque vas a encontrar blogs de 2017 llenos de instrucciones
sobre `GOPATH` que hoy son ruido. Vamos una por una:

```bash
go env GOROOT GOPATH GOBIN GOMODCACHE GOFLAGS GOPROXY GOPRIVATE GONOSUMDB
```

- **`GOROOT`** — dónde vive el toolchain. **No la toques nunca.** El instalador la
  deja bien y la única razón para cambiarla es tener varias versiones a mano, que
  es justo lo que `go1.13` resuelve sin tocarla.
- **`GOPATH`** — por defecto `~/go`. Antes de los módulos (Go 1.11, obligatorios
  desde 1.16) **era el único sitio donde podía vivir tu código**, y el origen de
  la mitad de la mala fama del tooling de Go. Hoy solo contiene dos subdirectorios
  que importan: `pkg/mod` (el caché) y `bin` (los binarios instalados). **Tu
  código puede vivir donde quieras.**
- **`GOBIN`** — dónde deja `go install` los binarios. Si está vacía, usa
  `$GOPATH/bin`. **Añádela al `PATH`**, porque si no, `golangci-lint` y
  compañía no van a estar disponibles:
  ```bash
  export PATH="$PATH:$(go env GOPATH)/bin"
  ```
- **`GOMODCACHE`** — el `~/.m2`. Por defecto `$GOPATH/pkg/mod`. Es de solo
  lectura para tu usuario a propósito; si intentas editar una dependencia ahí,
  el sistema de archivos te dirá que no, y eso es una feature.
- **`GOFLAGS`** — banderas que se añaden a *todos* los comandos. Útil y peligrosa;
  `GOFLAGS=-mod=mod` explica el 5% de los "en mi máquina sí funciona".
- **`GOPROXY`** — por defecto `https://proxy.golang.org,direct`. Es el Maven
  Central de Go. En una empresa con repositorio privado apuntas esto a Athens o
  a Artifactory.
- **`GOPRIVATE`** — patrones de módulos que no deben pasar por el proxy ni por la
  base de datos de sumas de verificación. En un monorepo corporativo,
  `GOPRIVATE=github.com/tuempresa/*`.

📖 Si vienes de Java: `GOROOT` es `JAVA_HOME`, `GOMODCACHE` es `~/.m2/repository`,
`GOPROXY` es la sección `<mirrors>` del `settings.xml`, y `GOPATH` es un fósil
que sobrevive como raíz del caché.

### 6.3 Mini proyecto: `hello-go`

Todo curso tiene su "hola mundo" y este dura seis minutos, pero esconde la primera
lección cultural de Go. Crea el monorepo y el primer laboratorio:

```bash
mkdir -p ~/dev/meridian/labs/hello-go
cd ~/dev/meridian/labs/hello-go
go mod init github.com/meridian/labs/hello-go
```

```go
// labs/hello-go/main.go
package main

import "fmt"

func main() {
	// El primer programa del curso no dice "hola mundo": dice de qué plataforma
	// somos, que es el dato que vamos a necesitar dentro de veinte minutos.
	fmt.Println("Meridian platform tooling check")
}
```

```bash
go run .
# Meridian platform tooling check
```

Ahora **rómpelo a propósito**. Añade un import que no uses:

```go
import (
	"fmt"
	"os"
)
```

```bash
go build .
# ./main.go:5:2: "os" imported and not used
```

🧨 **Rompe a propósito.** Eso no es un warning: **es un error de compilación**.
El programa no existe. Lo mismo pasa con una variable declarada y no usada:

```go
func main() {
	count := 42
	fmt.Println("Meridian platform tooling check")
}
// ./main.go:6:2: count declared and not used
```

Viniendo de Java —donde un import sobrante es, como mucho, un subrayado gris del
IDE— esto se siente agresivo la primera semana. La justificación del equipo de Go
es de mantenimiento a largo plazo: un import muerto es código muerto, y el código
muerto se acumula. La consecuencia práctica es que **todo repositorio Go que
compila está libre de imports huérfanos**, sin plugin, sin regla de Checkstyle y
sin discusión en la revisión de código.

> 💡 La solución diaria no es borrar a mano: es que el editor corra `goimports` al
> guardar, que añade lo que falta y quita lo que sobra. Lo configuramos en §6.7.

### 6.4 Mini proyecto: `build-info`

El equivalente del `MANIFEST.MF` con `Implementation-Version`, o de las
propiedades que el `spring-boot-maven-plugin` inyecta para que Actuator las
publique en `/actuator/info`. En Go se hace con `-ldflags -X`, y es una de esas
cosas que parecen magia negra hasta que la ves una vez.

```bash
mkdir -p ~/dev/meridian/labs/build-info && cd ~/dev/meridian/labs/build-info
go mod init github.com/meridian/labs/buildinfo
```

```go
// labs/build-info/main.go
package main

import (
	"fmt"
	"runtime"
)

// Estas tres variables se sobrescriben en tiempo de enlazado con -ldflags -X.
// Tienen que ser variables de paquete tipo string: el enlazador no sabe
// escribir constantes ni tipos numéricos.
var (
	version   = "dev"
	commit    = "none"
	buildDate = "unknown"
)

func main() {
	fmt.Printf("opsreport %s (commit %s, built %s)\n", version, commit, buildDate)
	fmt.Printf("go %s · %s/%s\n", runtime.Version(), runtime.GOOS, runtime.GOARCH)
}
```

```bash
go build -o bin/buildinfo .
./bin/buildinfo
# opsreport dev (commit none, built unknown)
# go go1.25.1 · darwin/arm64
```

Ahora con los valores reales inyectados desde git:

```bash
go build -ldflags "\
  -X main.version=0.1.0 \
  -X main.commit=$(git rev-parse --short HEAD) \
  -X main.buildDate=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -o bin/buildinfo .

./bin/buildinfo
# opsreport 0.1.0 (commit 4f2a19c, built 2026-09-11T14:03:22Z)
```

La ruta `main.version` es literal: **paquete punto variable**. Si la variable
viviera en `internal/build`, sería `-X github.com/meridian/opsreport/internal/build.Version`.
Equivocarse en esa ruta no da error: simplemente no inyecta nada y te quedas con
`dev`, que es el fallo más común y el más difícil de ver.

Y la bandera que acompaña siempre a esta en producción:

```bash
go build -ldflags "-s -w" -o bin/buildinfo .
```

`-s` quita la tabla de símbolos, `-w` la información de DWARF para depuración. El
binario adelgaza de forma notable y a cambio pierdes los nombres en los volcados
de pila y la posibilidad de depurar con `dlv` sobre ese binario. En la Fase 14,
cuando construyamos la imagen de contenedor, tomaremos esa decisión con criterio.

> 🧪 **Prueba de fuego.** Compila las dos versiones y compáralas:
> ```bash
> go build -o bin/big . && go build -ldflags "-s -w" -o bin/small .
> ls -lh bin/big bin/small
> ```
> Anota los dos tamaños: son el primer dato que vas a llevar al duelo de la Fase
> 16. **La mentira de la pantalla:** no compares un binario de `go build` con un
> JAR. El JAR no trae la JVM; el binario de Go trae el runtime, el recolector de
> basura y toda la stdlib que usaste. La comparación honesta es binario contra
> JAR **más** la imagen base con el JRE, y esa la haremos en la Fase 14 (B-21).

### 6.5 Mini proyecto: `crossbuild`

Este es el argumento más corto a favor de Go que existe, y por eso va tan
temprano. Un script, cinco plataformas, ningún contenedor, ningún toolchain
extra.

```bash
mkdir -p ~/dev/meridian/labs/crossbuild && cd ~/dev/meridian/labs/crossbuild
go mod init github.com/meridian/labs/crossbuild
```

Reutilizamos el `main.go` de `build-info` (cópialo tal cual: imprime plataforma,
que es justo lo que queremos verificar) y añadimos el script:

```bash
#!/usr/bin/env bash
# labs/crossbuild/build-all.sh
# Compila el mismo paquete para cinco plataformas. Sin Docker, sin toolchain
# cruzado, sin plugin: dos variables de entorno por objetivo.
set -euo pipefail

APP="crossbuild"
LDFLAGS="-s -w -X main.version=0.1.0"

targets=(
  "darwin/arm64"
  "darwin/amd64"
  "linux/amd64"
  "linux/arm64"
  "windows/amd64"
)

rm -rf bin && mkdir -p bin

for target in "${targets[@]}"; do
  os="${target%/*}"
  arch="${target#*/}"
  out="bin/${APP}-${os}-${arch}"
  [ "$os" = "windows" ] && out="${out}.exe"

  echo "==> ${os}/${arch}"
  GOOS="$os" GOARCH="$arch" CGO_ENABLED=0 go build -ldflags "$LDFLAGS" -o "$out" .
done

ls -lh bin/
```

```bash
chmod +x build-all.sh
time ./build-all.sh
```

> 📐 **Cómo se mide.** Esta es la entrada **B-01** de `BENCHMARKS.md`:
> *compilación cruzada — mismo binario, cinco plataformas, tiempo total y tamaño
> de cada uno*. La hipótesis, las condiciones y el comando exacto están allí;
> corre `./build-all.sh` en tu máquina y anota tus números en la tabla, porque el
> tiempo de compilación depende del hardware y no sirve copiar el de otro.

Dos detalles del script que no son decorativos:

**`CGO_ENABLED=0`.** Sin él, `go build` para otra plataforma falla en cuanto
alguna dependencia use cgo, porque haría falta un compilador de C cruzado. Con él,
el binario es **estático**: no depende de la `libc` del sistema destino, y por eso
puede correr en una imagen `scratch`. Esta variable es el 80% de por qué las
imágenes de contenedor de Go son tan pequeñas, y volverá en la Fase 14.

**La lista de objetivos no es infinita, pero casi.** `go tool dist list` te
devuelve las combinaciones soportadas; son más de cuarenta. Compilar para un
Raspberry Pi desde un Mac es `GOOS=linux GOARCH=arm GOARM=7`.

🩻 **Esto sí funciona igual:** el bytecode de Java también es portable, y en eso
Java lleva veinticinco años de ventaja conceptual. La diferencia no es la
portabilidad, es **qué tiene que haber instalado en el destino**: un JAR necesita
una JVM compatible; este binario no necesita nada. Los dos modelos son
defendibles y el intercambio se mide en la Fase 16.

### 6.6 El monorepo de Meridian

Este es el entregable real de la fase. El layout con el que vamos a vivir las
diecisiete fases siguientes:

```text
meridian/
  go.work.example          🕰️ el go.work llega en la Fase 08; aquí solo se anuncia
  Makefile
  compose.yaml
  .golangci.yml
  .editorconfig
  .gitignore
  labs/                    Los 28 mini proyectos, un módulo por lab
    hello-go/
    build-info/
    crossbuild/
  services/
    opsreport/             Nace en la Fase 01
    eventrelay/            Nace en la Fase 02
    atlassync/             Nace en la Fase 10
    clearinghouse/         Nace en la Fase 09
    storeagent/            Nace en la Fase 09
  reference/
    clearinghouse-spring/  El gemelo Java, entregado hecho, se usa en la Fase 16
```

> 🧭 **Regla del proyecto.** Un módulo por servicio, no un módulo para todo. La
> razón es que cada servicio va a tener dependencias distintas —EventRelay no
> necesita el driver de Mongo, AtlasSync no necesita el de SQLite— y con un solo
> `go.mod` todos cargan con todas. Es la misma discusión del multi-módulo de Maven
> y se resuelve igual: módulos separados cuando los ciclos de vida y las
> dependencias difieren de verdad.

El `.gitignore` mínimo:

```gitignore
bin/
*.out
*.test
cover.out
.env
```

Lo que **sí** se commitea y a un dev de Java le sorprende: el `go.sum` (siempre) y
el `vendor/` (solo si decides vendorizar, que en este curso no lo haremos).

Y el `.editorconfig`, que es de las pocas cosas que unifican VS Code y GoLand sin
pelea:

```ini
# .editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.go]
indent_style = tab
indent_size = 4

[*.{md,yaml,yml,json}]
indent_style = space
indent_size = 2
```

**Go se indenta con tabuladores.** No es negociable, no es configurable y
`gofmt` lo impone. Si vienes de un equipo con guerra de espacios, disfruta: esa
discusión acaba de terminar para siempre.

### 6.7 El `Makefile`

En Go el `Makefile` ocupa el sitio del `pom.xml`, pero con una diferencia
importante: **no construye nada, solo recuerda comandos**. La construcción la hace
`go build`; el `Makefile` existe para que nadie tenga que acordarse de las siete
banderas de `go test`.

```makefile
# Makefile
# Nota: en Make, cada línea de receta empieza con un TABULADOR, no espacios.

GO         ?= go
GO113      ?= go1.13
COVER_FILE ?= cover.out
COVER_MIN  ?= 80

.PHONY: help fmt vet lint test test-race cover up down clean

help: ## Lista los objetivos disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

fmt: ## Formatea todo el repositorio
	$(GO) fmt ./...

vet: ## Análisis estático del toolchain
	$(GO) vet ./...

lint: ## golangci-lint con la configuración del curso
	golangci-lint run ./...

test: ## Suite rápida
	$(GO) test ./...

test-race: ## Suite con el detector de carreras
	$(GO) test -race ./...

cover: ## Cobertura con umbral
	$(GO) test -race -covermode=atomic -coverprofile=$(COVER_FILE) ./...
	$(GO) tool cover -func=$(COVER_FILE) | tail -n 1

up: ## Levanta PostgreSQL, MongoDB y Valkey
	docker compose up -d

down: ## Apaga la infraestructura y borra sus volúmenes
	docker compose down -v

clean: ## Borra binarios y artefactos de cobertura
	rm -rf bin $(COVER_FILE)
```

> 💸 **Deuda técnica intencional.** Este `Makefile` tiene rutas fijas, no valida
> ninguna entrada y el objetivo `cover` imprime el total pero **no falla si está
> por debajo del umbral**. Es exactamente el nivel de descuido con el que empieza
> todo proyecto real. **Se paga en la Fase 14**, cuando la configuración se toma
> en serio y el umbral entra en CI de verdad.

### 6.8 El `compose.yaml`

Los servicios de infraestructura **no se instalan en tu máquina**. Viven aquí,
apagados, esperando a la fase que los necesite: PostgreSQL en la 09, MongoDB en
la 11, Valkey en la 12.

```yaml
# compose.yaml
# Infraestructura local de la plataforma Meridian. Nada de esto se instala en el
# anfitrión: se levanta con `make up` y se tira con `make down`.
services:
  postgres:
    image: postgres:16-alpine
    container_name: meridian-postgres
    environment:
      POSTGRES_USER: meridian
      POSTGRES_PASSWORD: meridian
      POSTGRES_DB: meridian
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      # pg_isready devuelve 0 solo cuando el servidor acepta conexiones; sin esto,
      # los tests arrancan contra un puerto abierto pero un servidor a medio subir.
      test: ["CMD-SHELL", "pg_isready -U meridian -d meridian"]
      interval: 2s
      timeout: 3s
      retries: 15

  mongo:
    image: mongo:7
    container_name: meridian-mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--quiet", "--eval", "db.adminCommand('ping')"]
      interval: 2s
      timeout: 3s
      retries: 15

  valkey:
    image: valkey/valkey:8-alpine
    container_name: meridian-valkey
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 2s
      timeout: 3s
      retries: 15

  # Mongo en conjunto de réplicas de un solo nodo. NO arranca con `make up`:
  # vive tras un perfil porque solo lo necesita un ejercicio de la Fase 11, el de
  # transacciones multi-documento. El `mongo` de arriba es una instancia suelta y
  # se queda así a propósito: ese ejercicio pide demostrar que la transacción
  # FALLA contra una instancia suelta antes de hacerla funcionar aquí.
  mongo-rs:
    image: mongo:7
    container_name: meridian-mongo-rs
    profiles: ["rs"]
    command: ["mongod", "--replSet", "rs0", "--bind_ip_all"]
    ports:
      - "27018:27017"
    volumes:
      - mongo-rs-data:/data/db
    healthcheck:
      # Se inicia solo la primera vez: rs.status() falla mientras no haya conjunto,
      # y entonces rs.initiate() lo crea. Idempotente, que es lo que quieres en un
      # healthcheck.
      test: >
        mongosh --quiet --eval
        "try { rs.status().ok } catch (e) { rs.initiate({_id:'rs0',members:[{_id:0,host:'localhost:27017'}]}).ok }"
      interval: 2s
      timeout: 5s
      retries: 30

volumes:
  postgres-data:
  mongo-data:
  mongo-rs-data:
```

```bash
make up
docker compose ps
make down
```

**Y el conjunto de réplicas, solo cuando un ejercicio lo pida:**

```bash
docker compose --profile rs up -d mongo-rs
# Cadena de conexión: mongodb://localhost:27018/?replicaSet=rs0&directConnection=true
docker compose --profile rs down
```

> 📝 **Por qué dos Mongo y no uno con `--replSet`.** Un conjunto de réplicas de un
> nodo soporta todo lo que soporta una instancia suelta, así que sería más simple
> dejar solo el segundo. Pero entonces el curso nunca vería el error que da una
> transacción multi-documento contra una topología que no la admite —que es poco
> obvio y que **todo el mundo se come una vez en producción**—. El ejercicio 20 de
> la Fase 11 lo provoca a propósito. Dos contenedores, y uno apagado por defecto,
> es el precio de poder enseñarlo.

> 🧪 **Prueba de fuego.** `make up && docker compose ps` tiene que mostrar los tres
> servicios en estado `healthy`, no solo `running`. **La mentira de la pantalla:**
> `running` significa que el proceso arrancó, no que acepte conexiones. Esa
> diferencia —que aquí es una curiosidad— es exactamente la diferencia entre
> `/health` y `/ready` que vamos a discutir en serio en la Fase 14.

### 6.9 `golangci-lint` y la configuración del curso

```bash
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
golangci-lint version
```

```yaml
# .golangci.yml
version: "2"

linters:
  enable:
    - errcheck      # errores devueltos y no comprobados: el linter más importante del curso
    - govet         # el vet del toolchain
    - staticcheck   # el analizador más profundo del ecosistema
    - ineffassign   # asignaciones cuyo valor nunca se lee
    - unused        # identificadores sin uso
    - misspell      # erratas en comentarios e identificadores
    - bodyclose     # response.Body sin cerrar: la fuga de la Fase 10
    - noctx         # peticiones HTTP sin context: la regla de la Fase 07
    - errorlint     # comparaciones de error con == en vez de errors.Is
    - rowserrcheck  # rows.Err() sin comprobar tras recorrer un sql.Rows: la Fase 09
    - sqlclosecheck # sql.Rows y sql.Stmt sin cerrar: la otra mitad del mismo bug

  settings:
    errcheck:
      # Comprobar también los errores que se ignoran con la asignación en blanco.
      check-blank: true

issues:
  # Cero tolerancia: si un linter dice algo, se arregla o se justifica con
  # //nolint y su motivo escrito al lado.
  max-issues-per-linter: 0
  max-same-issues: 0
```

De esta lista, dos merecen un comentario. **`errcheck`** es el que más va a
protestar al principio y el que más valor da: en Go se puede ignorar un error
escribiendo `_`, y ese es el agujero real que las excepciones comprobadas de Java
no tienen (lo discutimos en serio en la Fase 03). **`bodyclose`** y **`noctx`**
todavía no tienen nada que revisar, porque no hay clientes HTTP, pero los dejamos
puestos desde ahora para que cuando llegue el código, el linter ya esté vigilando.

Lo mismo vale para **`rowserrcheck`** y **`sqlclosecheck`**, que no verán una
línea de SQL hasta la Fase 09. Se quedan aquí porque los dos errores que detectan
—recorrer un `sql.Rows` y no mirar `rows.Err()` al salir del bucle, y dejar el
`Rows` sin cerrar— **no fallan el test: devuelven menos filas en silencio y filtran
conexiones del pool**. Son el tipo de bug que en Java no existe porque el
`try-with-resources` y las excepciones lo cubren, y en Go se te cuela entero hasta
producción. Que el linter esté puesto desde el primer día evita tener que ir a
buscarlos después.

### 6.10 El editor: VS Code

> ⚠️ **Esta subsección envejece más rápido que el resto del curso.** Los menús y
> los nombres de las opciones cambian. Lo que no cambia es **qué herramienta hace
> qué**, y eso es lo que tienes que llevarte; si un menú se movió, búscalo por el
> nombre de la herramienta.

**Una sola extensión: `golang.go`**, la oficial. Ignora las que prometen snippets,
temas de gopher o "Go Enhanced": no hacen falta y compiten con la oficial. Al
abrir el primer `.go`, la extensión te ofrecerá instalar las herramientas que
necesita. Di que sí, y entérate de qué acabas de instalar:

- **`gopls`** — el *language server* oficial. Es quien da autocompletado, saltar a
  definición, renombrar, ver referencias y los errores en vivo. **Es el
  equivalente del motor de análisis de IntelliJ**, y es lo único imprescindible.
- **`dlv`** — el depurador. Sin él, el botón de depurar no hace nada.
- **`staticcheck`** — el analizador estático. El mismo que `golangci-lint`
  ejecuta; aquí corre en vivo mientras escribes.
- **`goimports`** — formateo que además ordena y completa los imports.

El `settings.json` mínimo del curso:

```jsonc
{
  // Formatear y organizar imports al guardar. Esto resuelve el 90% de los
  // "imported and not used" antes de que los veas.
  "editor.formatOnSave": true,
  "[go]": {
    "editor.defaultFormatter": "golang.go",
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },

  // goimports en vez de gofmt: mismo formato, además arregla los imports.
  "go.formatTool": "goimports",

  // Que el linter del editor sea el mismo que el de CI. Nada peor que un editor
  // verde y un CI rojo.
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "workspace",

  // go vet al guardar, sobre todo el paquete.
  "go.vetOnSave": "workspace",

  // Banderas por defecto de los tests lanzados desde el editor.
  "go.testFlags": ["-race", "-count=1"],

  // Pistas de tipo en línea; útiles mientras el modelo de valores todavía no es
  // reflejo. Se pueden apagar cuando estorben.
  "gopls": {
    "ui.semanticTokens": true,
    "ui.diagnostic.staticcheck": true
  }
}
```

Y la configuración de depuración, que es lo que te va a faltar el primer día que
algo no cuadre:

```jsonc
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug opsreport",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}/services/opsreport/cmd/opsreport",
      "env": { "MERIDIAN_HTTP_ADDR": ":8080" }
    },
    {
      "name": "Debug test actual",
      "type": "go",
      "request": "launch",
      "mode": "test",
      "program": "${fileDirname}"
    }
  ]
}
```

> 💡 **`-count=1` en `go.testFlags` no es decorativo.** Go cachea los resultados
> de los tests: si nada cambió, `go test` reimprime el resultado anterior con un
> `(cached)` al lado. En CI está bien; mientras depuras un test intermitente es
> una tortura. `-count=1` desactiva ese caché.

### 6.11 El editor: GoLand

Si vienes de IntelliJ, GoLand es el camino de menor resistencia y trae de fábrica
casi todo lo que en VS Code hay que montar: `gopls` no hace falta porque GoLand
tiene su propio motor de análisis, el depurador está integrado, el perfilador
también, y el ejecutor de tests entiende tests de tabla y te los muestra como un
árbol de subtests, que es genuinamente mejor que la salida de terminal.

Lo que sí conviene ajustar:

- **File watcher de `gofmt`** — Settings → Tools → File Watchers → `go fmt`. En
  la práctica basta con activar *Actions on Save → Reformat code* y *Optimize
  imports*.
- **`golangci-lint` como inspección externa** — Settings → Go → Linters, apuntando
  al `.golangci.yml` del repositorio. Es la forma de que el editor y el CI digan
  lo mismo.
- **Plugins que sí valen la pena:** `.env files support` (para la configuración de
  la Fase 14), `Database Tools` (viene en la versión completa; ahorra salir a
  `psql` en la Fase 09) y `Makefile Language` para que el `Makefile` no se vea
  como texto plano.
- **Lo que no hace falta:** ningún plugin de "Go templates avanzados", ningún
  tema, ningún generador de getters — que en Go además sería un ☕.

📖 **Traducción rápida para quien viene de IntelliJ:** *Reformat code* es `gofmt`,
*Optimize imports* es `goimports`, *Run configuration* es una invocación de
`go test -run`, y *External libraries* en el árbol del proyecto es tu
`GOMODCACHE`.

### 6.12 Módulos: `go.mod`, `go.sum` y el grafo

Ya creaste tres módulos sin mirar lo que generaban. Mira ahora:

```bash
cat labs/hello-go/go.mod
```

```text
module github.com/meridian/labs/hello-go

go 1.25
```

Tres líneas. El `pom.xml` más corto que has visto tenía veinte. La diferencia no
es cosmética: **el `go.mod` no declara cómo se construye el proyecto, solo qué
depende de qué**. La construcción es siempre la misma y la sabe el comando `go`.

La directiva `go 1.25` **no es "la versión con la que compilé"**: es la versión
mínima del lenguaje que este módulo requiere, y afecta a la semántica. Es el
equivalente exacto del `<release>17</release>` del compilador de Maven. Y es la
directiva que, en el Bloque A, va a decir `go 1.13` — que es lo que hace que
nuestra disciplina de época sea verificable y no un pacto de honor.

Añade una dependencia real para ver el resto del mecanismo:

```bash
cd labs/hello-go
go get github.com/google/uuid@v1.6.0
cat go.mod
cat go.sum
```

```text
module github.com/meridian/labs/hello-go

go 1.25

require github.com/google/uuid v1.6.0
```

El `go.sum` tiene ahora dos líneas por dependencia: el hash del módulo y el hash
de su `go.mod`. **Se commitea siempre.** Es la garantía de que lo que descargue tu
compañero es byte a byte lo que descargaste tú, y el equivalente funcional de un
lockfile con verificación criptográfica.

Ahora quítala, porque no la usamos:

```bash
go mod tidy
cat go.mod   # el require desapareció solo
```

**`go mod tidy` es el comando que más vas a correr del subsistema de módulos.**
Lee tu código, añade lo que importas y quita lo que no. No hay equivalente exacto
en Maven: allí las dependencias son declarativas y se quedan hasta que alguien las
borra a mano; aquí el grafo se deriva del código.

Y el comando que salva reuniones enteras, el `mvn dependency:tree` de Go:

```bash
go mod why github.com/google/uuid
go mod graph | head
go list -m all
```

> 🧭 **Regla del proyecto.** `go mod tidy` corre antes de cada commit, igual que
> `gofmt`. Un `go.mod` con dependencias que ya nadie importa es deuda silenciosa
> y `tidy` la borra gratis.

### 6.13 Dejarlo todo en verde

El cierre de la fase es verificable de una sola pasada:

```bash
cd ~/dev/meridian
make fmt vet lint test
make up && docker compose ps && make down
```

`make test` va a decir `?  ...  [no test files]` en todos los paquetes. Eso está
bien: es la Fase 00 y todavía no hay nada que probar. En la Fase 04 esa salida
cambia para siempre.

---

## ⚰️ 7. Autopsia y errores comunes

En esta fase no hay autopsia de antipatrón —empiezan en la Fase 02, cuando ya hay
diseño que criticar—, pero sí los cuatro errores que consumen la primera tarde de
casi todo el mundo.

### Errores comunes

**1. `command not found: golangci-lint` después de instalarlo.**
*Síntoma:* `go install` termina sin error y el binario no existe.
*Causa:* `$(go env GOPATH)/bin` no está en el `PATH`. `go install` dejó el binario
donde debía; tu shell no lo busca ahí.
*Fix mínimo:* `export PATH="$PATH:$(go env GOPATH)/bin"` en tu `~/.zshrc`.

**2. `go: cannot find main module`.**
*Síntoma:* cualquier comando `go` falla en un directorio que parece correcto.
*Causa:* estás fuera de un módulo — no hay `go.mod` ni en ese directorio ni en
ninguno por encima.
*Fix mínimo:* `go mod init <ruta>` si es un proyecto nuevo, o `cd` al directorio
correcto. **No** ejecutes `go mod init` dentro de otro módulo: los módulos anidados
son una fuente de confusión que no compensa.

**3. `package X is not in GOROOT`.**
*Síntoma:* un import que existe y está bien escrito no resuelve.
*Causa:* casi siempre falta el `require` en el `go.mod`, no un problema de
`GOROOT` a pesar de lo que dice el mensaje.
*Fix mínimo:* `go mod tidy`.

**4. El editor formatea distinto que el CI.**
*Síntoma:* el PR cambia treinta archivos que no tocaste.
*Causa:* el editor usa un formateador distinto al de `make fmt`, o un
`golangci-lint` de otra versión.
*Fix mínimo:* `go.formatTool: "goimports"` en el editor y la misma versión del
linter en `Makefile` y en CI. En la Fase 14 lo fijamos con un hook de pre-commit.

### 🧨 Rompe a propósito

Ya rompiste el `hello-go` con un import sobrante. Rompe ahora la época, que es la
disciplina central del Bloque A:

```bash
mkdir -p /tmp/epoch-test && cd /tmp/epoch-test
go mod init epochtest
```

```go
// main.go — usa slices.Sort, que llegó en Go 1.21
package main

import (
	"fmt"
	"slices"
)

func main() {
	priorities := []int{5, 2, 9, 1}
	slices.Sort(priorities)
	fmt.Println(priorities)
}
```

```bash
go build .      # compila sin problema
go1.13 build .  # falla
```

Con el toolchain moderno: compila y funciona. Con `go1.13`:

```text
main.go:5:2: cannot find package "slices" in any of:
	/Users/tu/sdk/go1.13/src/slices (from $GOROOT)
	/Users/tu/go/src/slices (from $GOPATH)
```

**Esa es la red de seguridad del Bloque A.** El compilador moderno te habría
dejado escribir `slices.Sort` en la Fase 01 sin decir nada, y habrías roto la
regla de época sin enterarte. Por eso `go1.13` está instalado y por eso los
módulos del Bloque A dicen `go 1.13` en su `go.mod`.

---

## 🧪 8. Ejercicios (20)

**🟢 Fácil (1–6)**

1. Ejecuta `go env` completo y escribe, en tu propio archivo de notas, qué hace
   cada una de estas seis: `GOROOT`, `GOPATH`, `GOBIN`, `GOMODCACHE`, `GOPROXY`,
   `GOFLAGS`. *Criterio de éxito:* para cada una, una frase que diga qué pasaría
   si estuviera mal puesta.
2. Instala `go1.13` y comprueba que `go1.13 env GOROOT` apunta a `~/sdk/go1.13`.
   *Criterio:* `go version` y `go1.13 version` devuelven versiones distintas desde
   el mismo directorio.
3. Crea el módulo `labs/hello-go` y consigue los dos errores de compilación del
   curso: un import sin usar y una variable declarada y no usada. *Criterio:*
   pegas los dos mensajes exactos en tus notas.
4. Corre `go doc strings.Builder` y `go doc -all strings.Builder`. *Criterio:*
   explicas en dos líneas la diferencia entre las dos salidas y cuándo usarías
   cada una.
5. Levanta la infraestructura con `make up` y verifica que los tres servicios
   llegan a `healthy`. Después `make down`. *Criterio:* `docker volume ls` no
   deja volúmenes `meridian-*` huérfanos.
6. Configura tu editor para que formatee y organice imports al guardar.
   *Criterio:* pegas código con imports desordenados y sin usar, guardas, y queda
   limpio sin que toques nada.

**🟡 Intermedio (7–14)**

7. Compila `build-info` inyectando versión, commit corto y fecha UTC con
   `-ldflags -X`. *Criterio:* el binario imprime los tres valores reales, no los
   de por defecto.
8. Ahora equivócate a propósito en la ruta de la variable (`-X version=...` en vez
   de `-X main.version=...`). *Criterio:* explicas por qué no hay error y el
   binario sigue diciendo `dev`, y cómo detectarías esto en un pipeline.
9. Compara `go build` contra `go build -ldflags "-s -w"` sobre el mismo paquete.
   *Criterio:* anotas los dos tamaños y explicas qué perdiste a cambio.
10. Escribe `build-all.sh` y produce los cinco binarios de `crossbuild`.
    *Criterio:* `file bin/*` identifica correctamente cinco plataformas distintas,
    y anotas el tiempo total de la corrida en la tabla de B-01.
11. Compila para una plataforma que no esté en la lista de cinco —por ejemplo
    `linux/arm` con `GOARM=7`, o `freebsd/amd64`—. *Criterio:* `go tool dist list`
    confirma que existe y el binario se genera.
12. Compila `crossbuild` con `CGO_ENABLED=1` para `linux/amd64` desde macOS.
    *Criterio:* reproduces el fallo, explicas la causa en una frase, y dices por
    qué `CGO_ENABLED=0` lo resuelve.
13. Añade `github.com/google/uuid` al módulo `hello-go`, úsalo, y después bórralo
    del código. *Criterio:* `go mod tidy` limpia el `require` solo, y explicas por
    qué Maven no puede hacer eso.
14. Usa `go list -f` para listar todos los paquetes del monorepo con su ruta de
    importación y su directorio. *Criterio:* un solo comando produce la lista
    completa. *(Pista: `go list -f '{{.ImportPath}} -> {{.Dir}}' ./...`)*

**🟠 Difícil (15–18)**

15. Añade al `Makefile` un objetivo `build-all` que compile los cinco binarios de
    cualquier servicio, recibiendo el nombre como variable (`make build-all
    SVC=opsreport`). *Criterio:* funciona para un servicio que todavía no existe
    y falla con un mensaje claro en vez de un error críptico de `go build`.
16. Reproduce el experimento de época del 🧨: escribe un programa que use una API
    posterior a 1.13, comprueba que compila con el toolchain moderno y falla con
    `go1.13`. Después haz lo mismo con `errors.Is`, que **sí** es de 1.13.
    *Criterio:* explicas por qué el segundo compila en las dos y qué te dice eso
    sobre cómo leer las notas de versión.
17. Configura `GOPRIVATE` y `GOPROXY` para un dominio corporativo ficticio
    (`git.meridian.internal/*`) y explica, con `go env`, qué cambia exactamente en
    la resolución de ese módulo. *Criterio:* dices qué pasaría con el `go.sum` de
    un módulo privado si no configuraras `GOPRIVATE`.
18. Borra el caché de módulos (`go clean -modcache`) y mide cuánto tarda en
    reconstruirse con `go mod download` en el monorepo. *Criterio:* anotas los dos
    tiempos y comparas conceptualmente con borrar `~/.m2` — ¿qué se recupera más
    rápido y por qué?

**🔴 Muy difícil (19–20)**

19. **Escribe la ficha de instalación de Meridian.** Un `docs/onboarding.md` que
    lleve a un dev de Java desde una máquina limpia hasta `make up && make test`
    en verde, en los tres sistemas operativos, con los comandos exactos.
    *Rúbrica:* (a) funciona en macOS, Linux y Windows sin pasos "obvios" omitidos;
    (b) explica **por qué** se instalan dos toolchains, no solo cómo; (c) incluye
    los cuatro errores comunes de §7 con su fix; (d) marca explícitamente qué
    partes van a envejecer —versiones, menús de IDE— y cómo verificarlas.
20. **Auditoría del toolchain.** Escribe un script `scripts/doctor.sh` que
    verifique el ambiente y devuelva código de salida distinto de cero si algo
    falta: los dos toolchains, `golangci-lint` en el `PATH`, Docker corriendo,
    `GOBIN` dentro del `PATH`, y la versión mínima de Go moderno. *Rúbrica:* (a)
    cada comprobación imprime qué falta y cómo arreglarlo, no solo "FAIL"; (b) el
    script es idempotente y no modifica nada; (c) distingue entre "falta" y "está
    pero con versión incorrecta"; (d) funciona con `set -euo pipefail` activo.

**🔥 Opcionales**

- Monta el mismo ambiente en un contenedor de desarrollo (Dev Container o
  `docker run` con el volumen montado) y compara el tiempo de compilación en frío
  contra el nativo. Anótalo: en la Fase 16 vamos a discutir cuánto vale el tiempo
  de build.
- Explora `go tool dist list -json` y produce una tabla de plataformas soportadas
  agrupadas por sistema operativo. Es una excusa perfecta para practicar `go list`
  y `jq`.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base. Están aquí para quien quiera cerrar la fase del
> todo: cubren lo que el temario dejó fuera a propósito y cada uno produce algo que
> se lleva al trabajo.

**D1 — La compilación reproducible.**
Consigue que el mismo commit produzca un binario **byte a byte idéntico** desde dos
directorios distintos y, si puedes, desde dos máquinas.
*Rúbrica:* (a) `sha256sum` de los dos binarios coincide; (b) explicas qué papel
juega `-trimpath` y qué metadatos inyecta `-buildvcs`; (c) identificas **todo** lo
que rompe la reproducibilidad —rutas absolutas, marcas de tiempo, variables de
entorno, la versión exacta del toolchain— y cómo lo neutralizas; (d) documentas por
qué esto importa en una cadena de suministro de software y qué lo hace más fácil en
Go que en Java.

**D2 — El toolchain sin red.**
Compila el monorepo completo en una máquina **sin acceso a internet**, partiendo de
un caché de módulos precargado.
*Rúbrica:* (a) funciona con la red desconectada de verdad, no simulada; (b)
comparas las dos estrategias —`GOMODCACHE` precargado frente a `go mod vendor`— con
sus ventajas y su coste en el repositorio; (c) explicas qué hacen `GOFLAGS=-mod=vendor`
y `GONOSUMDB`/`GOFLAGS=-mod=mod` en ese escenario; (d) escribes el procedimiento
para un entorno regulado donde la máquina de compilación no sale a internet, que es
un requisito real en banca y en administración pública.

**D3 — La auditoría del comando `go`.**
Produce una tabla de qué escribe cada subcomando y dónde.
*Rúbrica:* (a) cubres `build`, `test`, `install`, `mod download`, `generate` y
`clean`; (b) para cada uno, qué directorios toca —caché de build, `GOMODCACHE`,
`GOBIN`, temporales— y cuánto ocupa; (c) lo verificas de verdad con `go build -x`,
`go env`, y `fs_usage` (macOS) o `strace` (Linux), no de memoria; (d) calculas
cuánto espacio en disco consume el toolchain tras un mes de trabajo y qué se puede
limpiar sin perder nada.

---

## 📚 9. Referencias

### Documentación oficial

- **Descargas e instalación** — https://go.dev/dl/ y https://go.dev/doc/install
- **Gestión de varias versiones** — https://go.dev/doc/manage-install
  (es donde se documenta el truco de `golang.org/dl/go1.13`)
- **Referencia del comando `go`** — https://go.dev/doc/cmd y
  https://pkg.go.dev/cmd/go
- **Referencia de módulos** — https://go.dev/ref/mod (denso, pero es *la* fuente
  sobre `go.mod`, `go.sum`, el proxy y la resolución de versiones)
- **Tutorial de módulos** — https://go.dev/doc/tutorial/create-module
- **Variables de entorno del toolchain** — https://pkg.go.dev/cmd/go#hdr-Environment_variables
- **Compilación cruzada y plataformas soportadas** — https://go.dev/wiki/MinimumRequirements
- **Notas de todas las versiones** — https://go.dev/doc/devel/release
  (la vas a consultar de verdad en la Fase 08; ábrela ya y mira el formato)
- **`gopls`** — https://github.com/golang/tools/blob/master/gopls/README.md
- **`golangci-lint`** — https://golangci-lint.run/
- **Delve (`dlv`)** — https://github.com/go-delve/delve/tree/master/Documentation
- **Docker Compose** — https://docs.docker.com/compose/

> ⚠️ Casi toda la documentación oficial está escrita para la versión vigente. Las
> páginas sobre módulos y sobre el comando `go` describen comportamientos que en
> 1.13 eran distintos o no existían —`go install pkg@version`, por ejemplo, llegó
> en 1.16—. Cuando el Bloque A y la documentación no coincidan, manda lo que diga
> `go1.13 help`.

### Libros

- **The Go Programming Language** — Alan Donovan y Brian Kernighan. El capítulo
  introductorio cubre el toolchain de su época; está fechado, pero la explicación
  del modelo de compilación sigue siendo la mejor escrita.
- **Learning Go** — Jon Bodner. Su primer capítulo es, con diferencia, el mejor
  tratamiento moderno de "cómo se monta el ambiente y por qué así".

*(Los títulos y ediciones pueden haber cambiado; el curso no cita ISBN ni páginas
a propósito.)*

### Artículos y charlas

- **Go Modules: v2 and Beyond** — blog oficial de Go, https://go.dev/blog/v2-go-modules
- **Using Go Modules** (serie de cinco partes) — https://go.dev/blog/using-go-modules
- **Go Wiki: Modules** — https://go.dev/wiki/Modules
- **Publishing Go Modules** — https://go.dev/blog/publishing-go-modules
- **Sobre `GOPATH` y por qué ya no importa** — https://go.dev/blog/migrating-to-go-modules

### Video

- **Canal oficial de Go** en YouTube — busca las sesiones de "Go tooling" de las
  GopherCon.
- **JetBrains Go** — su serie sobre GoLand cubre el depurador y el perfilador
  integrados mejor que la documentación escrita.
- **Google for Developers** — charlas sobre `gopls` y el ecosistema de análisis.

> ⚠️ Buena parte del video sobre tooling de Go es anterior a los módulos (2018) y
> habla de `GOPATH` y de `dep` como si fueran el presente. Mira la fecha antes de
> copiar un flujo de trabajo.

### Orden de lectura sugerido

**Antes de escribir código:** la página de instalación y `go.dev/doc/manage-install`.
Con eso arrancas.
**Durante:** `go help <subcomando>` para cualquier duda concreta —es más rápido y
más exacto que buscar en Google—, y la referencia de módulos solo cuando algo no
resuelva.
**Después, y esto sí en calma:** la serie *Using Go Modules* completa y el primer
capítulo de *Learning Go*. Los dos te van a ahorrar tiempo en la Fase 08.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

El toolchain de Go es simple porque es opinado, y eso tiene un precio real que
conviene decir antes de que lo descubras solo:

- **Si necesitas un build con pasos de verdad** —generación de código a partir de
  un esquema, empaquetado de assets de frontend, firma de artefactos, publicación
  en varios repositorios—, `go build` no lo hace y el `Makefile` se te va a quedar
  corto. Maven y Gradle existen porque ese problema es real. La respuesta de la
  comunidad Go es `go generate` más scripts, y es genuinamente más pobre que un
  plugin de Maven bien escrito.
- **Si tu organización tiene un repositorio de artefactos con políticas
  estrictas** —escaneo de licencias, aprobación de dependencias, mirrors
  internos—, el ecosistema de Go tiene menos herramienta hecha que el de Java.
  `GOPROXY` y `GOPRIVATE` resuelven lo básico; auditoría de licencias a nivel
  Nexus IQ, no.
- **Si tu equipo depende de la configuración compartida del IDE** —plantillas de
  código, inspecciones a medida, *code style* por proyecto—, IntelliJ lleva años
  de ventaja. En Go esa necesidad casi desaparece porque `gofmt` no es
  configurable, pero si lo que quieres es imponer convenciones de arquitectura,
  ArchUnit no tiene equivalente maduro.
- **Y si de verdad necesitas varias versiones de Go por proyecto en la misma
  máquina con cambio automático**, no hay nada tan pulido como SDKMAN o jenv. La
  directiva `toolchain` (Go 1.21+) ayuda, `golang.org/dl/goX.Y` ayuda, pero es más
  artesanal.

Nada de esto quita que para el 90% de los servicios backend el intercambio salga
rentable. Solo que el 10% restante existe.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| JDK + `JAVA_HOME` | toolchain + `GOROOT` | `GOROOT` no se toca nunca; varias versiones se manejan con binarios `goX.Y`, no con una variable |
| SDKMAN / jenv | `golang.org/dl/goX.Y` + directiva `toolchain` | No hay cambio automático por proyecto; el `go.mod` declara el mínimo, no selecciona el binario |
| `pom.xml` / `build.gradle` | `go.mod` | El `go.mod` **no describe el build**, solo dependencias y versión del lenguaje. El build es fijo |
| `mvn clean install` | `go build ./...` | No hay fase `install` a un repositorio local: el caché de build es interno y no se publica |
| `~/.m2/repository` | `GOMODCACHE` | De solo lectura a propósito; no puedes "instalar" una versión parcheada a mano |
| Maven Central | `proxy.golang.org` | El proxy sirve módulos **inmutables** y verificados contra `sum.golang.org`; no hay `SNAPSHOT` |
| `SNAPSHOT` | *(no existe)* | Se usa un pseudo-versión derivada del commit (`v0.0.0-20260911140322-4f2a19c`) |
| `<mirrors>` del `settings.xml` | `GOPROXY` | Una variable de entorno en vez de un XML de usuario |
| `dependency:tree` | `go mod graph` / `go mod why` | `go mod why` responde *por qué* está, que es la pregunta que realmente haces |
| `MANIFEST.MF` con versión | `-ldflags -X` | Se inyecta en el enlazado, no se lee de un archivo; si te equivocas en la ruta, falla en silencio |
| Checkstyle + Spotless | `gofmt` + `golangci-lint` | `gofmt` no es configurable. La discusión de estilo desaparece |
| Surefire | `go test` | Integrado en el toolchain; el caché de resultados no tiene equivalente en Maven |
| `mvnw` (wrapper) | *(no existe)* | No hace falta: el toolchain no tiene plugins que versionar. La directiva `toolchain` cubre el caso |
| classpath | rutas de importación resueltas en compilación | No hay carga dinámica ni conflicto de versiones en tiempo de ejecución; el binario ya trae todo |
| Multi-módulo Maven | un `go.mod` por servicio | Sin POM padre; la coordinación entre módulos llega con `go.work` en la Fase 08 |

### Qué sigue

La Fase 01 empieza con el lenguaje, y empieza por donde más bugs produce en gente
que llega desde Java: **el modelo de valores**. Arrays, slices y mapas con la
memoria delante, porque un slice no es un `ArrayList` por más que se le parezca, y
esa diferencia produce bugs que pasan los tests y explotan en producción. Y nace
OpsReport: el tipo `WorkItem`, sus estados y su validación, todo en memoria y en
un solo paquete.

Antes de seguir, deja este directorio en verde. La Fase 01 asume que
`make fmt vet lint test` pasa y que `go1.13` responde.

### La señal de que quedó bien

> *"Abro una terminal en un repositorio Go que nunca vi, escribo `go mod why` y
> `go list ./...`, y en dos minutos sé qué construye, de qué depende y cómo se
> prueba — sin abrir el IDE."*

Si todavía necesitas el IDE para saber qué hace un proyecto, vuelve a §5 y corre
los comandos uno por uno sobre el monorepo. Es media hora y se amortiza en la
primera semana.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `make fmt vet lint test` en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-00 -m "F0 cerrada: dos toolchains instalados; monorepo Meridian con labs y services; Makefile y compose.yaml; golangci-lint en verde; hello-go, build-info y crossbuild funcionando"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 00: …`) y los de ejercicio su
> número (`fase 00 ej17: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **Hook de pre-commit** con `gofmt`, `go vet` y `go mod tidy` — aparece
  nombrado aquí pero se implementa de verdad en la **Fase 14**, junto con el
  umbral de cobertura en CI.
- **`go.work`** — anunciado en §3 y en el layout como `go.work.example`. Se crea
  en la **Fase 08**; comprobar allí que el ejemplo del layout coincide con el
  archivo real.
- **Pipeline de CI completo** (GitHub Actions con matriz de plataformas) — no
  entra en ninguna fase actualmente. Candidato a **ejercicio 🔥 de la Fase 14**.
- **Comparación de tiempo de build en frío Go vs. Maven** — mencionada de pasada
  en el ejercicio 🔥. Destino natural: **B-24**, como una fila más del duelo de la
  Fase 16.
- **Dev Containers** — solo como ejercicio 🔥. Si alguna vez se quiere de verdad,
  su sitio es la Fase 14.

## ☕ Reflejos para `INSTINTOS.md`

- **"Primero el layout de directorios"** — crear `pkg/`, `api/`, `configs/`
  vacíos por parecerse a un estándar que no existe. Coste: directorios muertos que
  nadie limpia y una falsa sensación de arquitectura. Antídoto: el layout emerge;
  un paquete existe cuando tiene contenido.
- **"Buscar el equivalente del `pom.xml` para configurar el build"** — el `go.mod`
  no es eso y buscarle plugins lleva a `Makefile`s de doscientas líneas.
- **"Instalar cinco extensiones del editor antes de escribir la primera línea"** —
  en Go la oficial basta y las demás compiten con `gopls`.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-01 — Compilación cruzada: mismo binario, cinco plataformas, tiempo y
  tamaño.** Hipótesis, condiciones y comandos ya escritos; la tabla de resultados
  la completa quien corre el curso, en su máquina. Enlazada desde §6.5.
- Anotado para la Fase 14: el tamaño del binario con y sin `-s -w` (§6.4,
  ejercicio 9) alimenta **B-21** como línea base antes de meter la imagen de
  contenedor.
