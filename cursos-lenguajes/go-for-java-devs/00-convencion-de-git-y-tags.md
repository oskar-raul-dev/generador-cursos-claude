# 🏷️ Convención de git y tags

> Go para desarrolladores Java senior · la plataforma Meridian
> Documento transversal. Las dieciocho fases lo enlazan desde su bloque 🏷️.
> **Cuándo se lee:** antes de la [Fase 00](00-instalacion-ambiente-y-tooling.md), y cada vez que el
> bloque 🏷️ de cierre de una fase te mande aquí.
> **Vigencia:** 2026-10-07.

Este documento fija cómo se organiza el historial del repositorio del curso. No es
burocracia: el historial **es un entregable**. El `git diff` entre dos tags de este
curso es material didáctico —el de la Fase 08 es, literalmente, el documento más
instructivo que vas a escribir— y eso solo funciona si los tags y los commits
significan algo.

> 🔑 **La frase para memorizar:** un tag es un puntero a un commit. No ocupa espacio, no agrega
> overhead y se borra con `git tag -d`. La pregunta no es "¿vale la pena etiquetar esto?", es "¿por
> qué no?".

---

## 📁 1. El repositorio

Un solo repositorio, el monorepo de Meridian que nace en la Fase 00:

```text
meridian/
  go.work                  desde la Fase 08
  Makefile
  compose.yaml
  .golangci.yml
  docs/                    los documentos que el curso produce
  labs/                    los 46 mini proyectos
  services/                los cuatro servicios + storeagent + shared
  reference/
    clearinghouse-spring/  el gemelo Java, entregado hecho (Fase 16)
```

**Una sola rama principal**, `main`. El curso es lineal y las ramas no aportan
nada, con una excepción declarada en §5.

No hace falta remoto. Si lo tienes, recuerda que **los tags no viajan solos**:
`git push --tags`.

---

## 💬 2. Mensajes de commit

### 2.1 La forma

```text
fase NN: <qué hace este commit>

<cuerpo opcional: por qué, no qué>
```

```text
fase 09: mover la cola de entregas a PostgreSQL con SKIP LOCKED

Paga la deuda 💸 del time.Timer por entrega declarada en la Fase 06.
La reclamación es atómica y varias instancias no se pisan.
```

**Los commits de ejercicio llevan su número:**

```text
fase 06 ej24: medir goroutines vivas con un millón de filas
fase 13 ej19: medir el tamaño de fragmento contra el tiempo total
```

**Y los mini proyectos, su nombre:**

```text
fase 01 lab/text-toolkit: comparar cinco formas de concatenar
```

### 2.2 Las reglas

- **Imperativo y en minúscula**: *"mover"*, no *"movido"* ni *"Mover"*.
- **Una línea de asunto por debajo de 72 caracteres.**
- **El cuerpo explica el porqué**, no el qué —el qué está en el diff—.
- **Un commit por lección o por ejercicio**, nunca por archivo ni por día.
- **Cada commit compila y pasa la suite.** Si no, el `git bisect` de la Fase 08 no
  sirve para nada, y esa fase lo usa de verdad.

### 2.3 Las anotaciones del curso en el cuerpo

Cuando un commit toca uno de los marcadores del curso, se dice:

```text
fase 14: validar URLs contra SSRF en el dialer

Paga la deuda 💸 declarada en la Fase 02 §6.8. Doce fases.
La validación va en DialContext y no en la URL, porque validar la URL
no protege contra DNS rebinding.
```

```text
fase 08: rechazar Repository[T] genérico

Documentado en docs/rechazos.md con su condición de revisión.
Las consultas reales (ListPendingBefore, ClaimNextBatch) no caben.
```

---

## 🏷️ 3. Tags

### 3.1 Tags de fase

**`fase-NN`**, uno por fase, anotado, al cerrarla con su checklist en verde:

```bash
git tag -a fase-09 -m "F9 cerrada: OpsReport y EventRelay sobre PostgreSQL con goose; pool configurado y justificado; SKIP LOCKED para la cola; paginación por cursor; storeagent con SQLite en WAL; B-13 a B-16 medidos"
```

**Siempre anotados (`-a`), nunca ligeros.** Un tag anotado guarda autor, fecha y
mensaje; uno ligero es solo un puntero, y el mensaje del tag es donde vive el
resumen de la fase.

**El mensaje es el checklist de la sección 2 de la fase, en una línea por ítem.**
Eso convierte `git tag -n99 -l 'fase-*'` en el índice del curso:

```bash
git tag -n99 -l 'fase-*'
```

> ⚠️ **Volver a un tag te deja en `detached HEAD`.** Es normal: `git checkout fase-09`
> te pone a mirar ese estado sin estar en ninguna rama. Para volver, `git switch main`;
> y si necesitas escribir desde ahí, eso ya es el caso de §5: una rama con nombre
> propio que no se fusiona.

### 3.2 Tags de proyecto

Cada servicio marca sus hitos con su propio prefijo, **para poder leer la
evolución de un servicio sin el ruido de los otros tres**:

```bash
git tag -a opsreport/v0.5 -m "OpsReport: API REST completa en memoria"
git tag -a eventrelay/v0.9 -m "EventRelay: entrega HTTP resiliente y firmada"
git tag -a atlassync/v0.2  -m "AtlasSync: persistencia documental en MongoDB"
git tag -a clearinghouse/v0.5 -m "ClearingHouse: cierre por lotes reanudable"
```

```bash
git log --oneline --decorate $(git tag -l 'opsreport/*' | head -1)..HEAD -- services/opsreport/
```

**La numeración es `v0.N` durante el curso** y sube cuando el servicio avanza de
verdad, no en cada fase que lo toca de refilón. `v1.0` se reserva para el capstone.

### 3.3 Tags de hito

Cinco tags que marcan puntos del curso que no son fases:

| Tag | Cuándo | Para qué |
|---|---|---|
| `bloque-a-completo` | cierre de la Fase 07 | **el punto de partida de la migración**; la Fase 08 lo usa dos veces |
| `plataforma/v1.0-rc1` | cierre de la Fase 14 | los cuatro servicios en estado de producción |
| `plataforma/v1.0-rc2` | cierre de la Fase 15 | banco de pruebas listo para el duelo |
| `duelo/v1.0` | cierre de la Fase 16 | el duelo medido, con sus condiciones |
| `meridian/v1.0` + `curso-completo` | cierre de la Fase 17 | la plataforma completa |

> 🧭 **`bloque-a-completo` es el más importante de los cinco.** Es lo que hace
> posible el comando que la Fase 08 declara como su mejor entregable:
> ```bash
> git diff bloque-a-completo fase-08 --stat
> git diff bloque-a-completo fase-08 -- services/opsreport/internal/httpapi/
> ```

### 3.4 Los espacios de nombres, y por qué importan

Los prefijos mantienen los listados limpios:

```bash
git tag -l 'fase-*'            # el índice del curso: 18 tags
git tag -l 'opsreport/*'       # la historia de un servicio
git tag -l '*/v1.0'            # los hitos de versión
```

---

## 🔀 4. Lo que NO se hace

- **No se reescribe el historial publicado.** Nada de `rebase -i` ni `push --force`
  sobre lo que ya tiene un tag de fase: los `git diff` entre tags dejarían de ser
  reproducibles.
- **No se hacen commits de "wip" ni de "arreglos varios".** Si algo no está listo,
  no se commitea.
- **No se mezclan migración y refactorización en el mismo commit.** Es la regla
  central de la Fase 08 y la causa de su autopsia.
- **No se commitean:** `bin/`, `cover.out`, `.env`, `go.work.sum`, los perfiles de
  `pprof`, ni los resultados de benchmark que no vayan a `BENCHMARKS.md`.
- **Sí se commitean**, aunque sorprenda a quien viene de Java: `go.sum` (siempre),
  `go.work` (es un monorepo de aplicaciones, §6.2 de la Fase 08), los archivos
  golden de `testdata/`, el corpus del fuzzer (`testdata/fuzz/`) y las respuestas
  grabadas de las APIs externas.

---

## 🌿 5. La única rama del curso

La Fase 16 necesita las dos implementaciones de ClearingHouse corriendo a la vez.
El gemelo Java vive en `reference/clearinghouse-spring/` **en `main`**, no en una
rama: es material del curso, no una alternativa.

La excepción es el ejercicio 26 de la Fase 08 —el servicio bilingüe—, que sí
necesita dos ramas comparables:

```bash
git switch -c epoca/go113 bloque-a-completo
git switch main
```

Esa rama **no se fusiona** y existe solo para el experimento.

---

## 🧪 6. Comprobaciones antes de cada commit

Lo que `make ci` ejecuta, y lo que el hook de pre-commit debería ejecutar:

```bash
gofmt -l .                      # vacío
go vet ./...
golangci-lint run ./...
go mod tidy                     # y sin cambios en go.mod
go test -race ./...
```

**En el Bloque A (Fases 00–07), con `go1.13`:**

```bash
go1.13 vet ./...
go1.13 test -race ./...
```

> ⚠️ **La disciplina de época también es de git.** Un commit del Bloque A cuyo
> `go.mod` diga algo distinto de `go 1.13`, o que compile solo con el toolchain
> moderno, rompe la premisa del bloque. El `go.mod` es parte del diff y se revisa.

---

## 📋 7. Referencia rápida

```bash
# Cerrar una fase
make ci && git status                       # todo limpio
git tag -a fase-NN -m "FN cerrada: <checklist en una línea por ítem>"
git tag -a <servicio>/v0.N -m "<qué avanzó>"

# El índice del curso
git tag -n99 -l 'fase-*'

# La historia de un servicio, sin ruido
git log --oneline --decorate -- services/opsreport/

# El diff de la migración (el entregable de la Fase 08)
git diff bloque-a-completo fase-08 --stat

# Encontrar cuándo se rompió algo
git bisect start fase-09 fase-08
git bisect run make ci

# Qué fase introdujo una línea
git log -S 'SKIP LOCKED' --oneline

# El grafo completo, al terminar
git log --oneline --graph --decorate --tags
```

**El cierre de fase, en cinco líneas:**

- [ ] El checklist de la sección 2 de la fase, en verde y verificado a mano.
- [ ] `make ci` limpio (y, en el Bloque A, también con `go1.13`).
- [ ] `git status` limpio: todo lo de la fase está commiteado.
- [ ] `git tag -a fase-NN -m "…"` creado, con el checklist en el mensaje.
- [ ] Los tags de proyecto (`<servicio>/v0.N`) de los servicios que avanzaron en la fase.

> **La señal de que quedó bien:** "vuelvo después de tres semanas, corro
> `git tag -n99 -l 'fase-*'`, y sé exactamente dónde me quedé y qué sigue — sin releer
> una sola línea del curso".

---

## 📖 8. Diccionario Java ⇄ Go de esta convención

| Java / Maven | Aquí | Diferencia |
|---|---|---|
| `mvn release:prepare` + tag | `git tag -a` a mano | Sin plugin: el tag es una decisión explícita |
| `SNAPSHOT` | *(no existe)* | Los módulos de Go son inmutables; se usa pseudo-versión del commit |
| Versión en el `pom.xml` | `-ldflags -X main.version` | Se inyecta en el enlazado (Fase 00) |
| `git-flow` con `develop` y `release/*` | **solo `main`** | El curso es lineal; las ramas no aportan |
| Tag por módulo en un multi-módulo | `servicio/vX.Y` | Mismo patrón; en Go es además cómo se versionan los submódulos |
| `.gitignore` con `target/` | `bin/`, `cover.out` | Menos artefactos que ignorar |
| `pom.xml.sha1` / `gradle.lockfile` | `go.sum` | Se commitea igual, y con verificación criptográfica |
