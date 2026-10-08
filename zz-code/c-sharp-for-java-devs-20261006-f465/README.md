# 🧪 c-sharp-for-java-devs-20261006-f465 · cómo correr estas pruebas

> **Curso:** c-sharp-for-java-devs · **Tanda:** rescate posterior al cierre · **Creado:** 2026-10-06
> **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción
> del curso, con instrucciones para replicarlo.
> **Vigencia:** rescatado el 2026-10-06 sin ejecutar nada.

> ⚠️ **Lo primero: en la producción de este curso no se ejecutó código C#.** Ninguna de las tres
> sesiones (12–13/09/2026) corrió `dotnet`, Docker ni un benchmark: el curso se escribió en macOS y está
> planeado para Windows. Las filas de `BENCHMARKS.md` llevan ⏳ («escrita y sin ejecutar») y sus
> veredictos dicen *expectativa, sin ejecutar*. El proyecto `src/modern/Cordillera.Bench` y sus pruebas
> se escribieron, pero nunca se compilaron. **Lo único que se probó fue el corpus**: la coherencia de
> las 25 fases. Eso es lo que se rescata aquí.

El rescate se hace con `zz-instrucciones/herramientas/rescatar-transcripcion.py`, la herramienta del repositorio para
reconstruir de una transcripción lo que una sesión escribió y corrió; los tres directorios del rescate
de `cursos-algoritmos-lenguajes` la llaman a través de `../regenerar-rescates.py`, que lee `../rescates.tsv`.

---

## 1. 🎯 Qué se prueba y para qué

| Carpeta | Sesión | Fecha (UTC) | Qué se verificó |
|---|---|---|---|
| `01-preparacion-3a759429/` | `3a759429…` | 12/09 23:03 → 13/09 00:52 | Nada ejecutable: alcance, guía y los 25 prompts de fase. Solo `archivos/_tmp/fases_{a,b,c,e}.md`, borradores de los prompts que la sesión armó en `/tmp` |
| `02-redaccion-aadc4f68/` | `aadc4f68…` | 13/09 00:59 → 18:21 | Redacción de F00–F24: caracteres invisibles o cirílicos en la prosa (`001`–`003`), y al cierre las cuatro auditorías de fases, ejercicios, bloques recurrentes y enlaces (`005`–`008`) |
| `03-revision-03630220/` | `03630220…` | 13/09 18:22 → 21:35 | Revisión de continuidad: cadena «Depende de · Habilita» 00→24, índice de `BENCHMARKS.md` sin huecos, referencias a otros cursos, versiones, ejercicios por banda (20–25), comandos `git diff` de deuda, estilo declarado contra `0-ESTRUCTURA-CURSO.md` |

Esas comprobaciones son las que hoy hace `prompts/verificar-corpus.py` del curso (errores `EJERCICIOS`,
avisos `BANDA`, `SECCION` y `DIAGRAMA`, más las validaciones base de enlaces y anclas). Los scripts de
aquí son su prehistoria: sirven para ver **qué se revisó** el 13/09 y cómo, no para reemplazarlo.

### Qué hay en cada carpeta

- `comandos.sh` — todos los comandos Bash de la sesión, en orden, con su hora y su descripción. Es una
  bitácora: no se corre entera.
- `scripts/NNN-HHMM-verifica.{py,sh}` — las verificaciones: cada `python3 - <<'PY'` y cada comando Bash
  de varias líneas que no escribe archivos, con su `.salida.txt`: lo que la sesión vio al correrlo. Se
  omitieron los 135 scripts que editaban la prosa (siguen en `comandos.sh`). El primer comentario de
  cada uno dice la sesión, la hora y la descripción.
- `bitacora.md` — los comandos que el detector tomó por ejecución, con el inicio de su salida. En este
  curso **todos son búsquedas** (`grep` cuyos patrones mencionan «docker»): ninguno ejecutó código.
- `archivos/` y `archivos.tsv` — solo en `01-`: los cuatro borradores de `/tmp`.

### Las herramientas del rescate

| Archivo | Qué hace |
|---|---|
| `zz-instrucciones/herramientas/rescatar-transcripcion.py` | Reconstruye de una transcripción los archivos (aplicando sus `Edit`), los scripts en línea, `comandos.sh` y `bitacora.md`; con `--inventario`, lista lo que tocó cada sesión. Solo lee; no ejecuta nada de lo que extrae |
| `../rescates.tsv` y `../regenerar-rescates.py` | La lista de sesiones y opciones de todos los rescates, y el script que los rehace desde cero (o los compara con `--comprobar`) |
| `rescatar.sh` | Envoltorio: `../regenerar-rescates.py --dir` este directorio |

## 2. 🛠️ Prerrequisitos

- **Para reconstruir:** Python 3 (biblioteca estándar) y las transcripciones en
  `~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/`.
- **Para correr las verificaciones:** Python 3 y bash, sobre el curso
  (`cursos-algoritmos-lenguajes/c-sharp-for-java-devs/`). No hay dependencias.
- **Para compilar el código del curso** (lo que nunca se hizo): SDK de .NET **10.0.401** según
  `src/global.json` (`rollForward: latestPatch`), `net10.0`.

## 3. 🧭 Reglas antes de correr

- Las verificaciones solo leen el curso: no hace falta inventario de Docker.
- **Los scripts se corren contra una copia**, no contra el curso: varios hacen `cd` relativo y algunos
  llevan rutas absolutas del repositorio. Y el curso cambió desde el 13/09 (F00 se renombró a
  `00-instalacion-…`, los diagramas pasaron a Mermaid el 05/10): un script que hoy falla puede estar
  señalando un cambio, no un error.
- Si se compila el código del curso, en contenedor y con la etiqueta `curso=c-sharp-for-java-devs`.

## 4. ▶️ Cómo se corre

```bash
cd zz-code/c-sharp-for-java-devs-20261006-f465
./rescatar.sh               # rehace desde cero las carpetas generadas (lee ../rescates.tsv); no ejecuta nada
./rescatar.sh --comprobar   # las regenera aparte y compara, sin tocar nada
python3 ../../zz-instrucciones/herramientas/rescatar-transcripcion.py --inventario \
  aadc4f68-f121-46e6-ade7-a28037b0fe0c --bash        # el inventario de una sesión
```

Las verificaciones se corren **desde la raíz del curso**, que es donde las corrió la sesión (usan
`glob('[0-9][0-9]-*.md')`, `BENCHMARKS.md`, `prompts/`):

```bash
AQUI="$PWD/zz-code/c-sharp-for-java-devs-20261006-f465"
CURSO=cursos-algoritmos-lenguajes/c-sharp-for-java-devs
cd "$CURSO"
python3 "$AQUI/03-revision-03630220/scripts/003-1910-verifica.py"   # cadena Depende/Habilita 00→24
python3 "$AQUI/03-revision-03630220/scripts/004-1910-verifica.py"   # BENCHMARKS sin huecos
bash    "$AQUI/03-revision-03630220/scripts/020-2126-verifica.sh"   # la batería final de la revisión
```

La verificación vigente del curso, la que reemplaza todo esto:

```bash
cd cursos-algoritmos-lenguajes/c-sharp-for-java-devs
python3 -B prompts/verificar-corpus.py
python3 -B ../../zz-instrucciones/herramientas/verificador_base.py . --perfil=courses-ia
```

## 5. 📏 Cómo se mide

No aplica: en este curso no se midió nada. Las 24 entradas de `BENCHMARKS.md` traen hipótesis,
condiciones, comando y una *expectativa* de veredicto; sus cifras están en ⏳. El arnés que debería
medirlas es `src/modern/Cordillera.Bench` (`BenchRunner`, `BenchStats`, `MachineProfile`), escrito en la
sesión `aadc4f68` y sin compilar.

## 6. 🧮 Los intermedios que amasan la salida

No aplica: no hay cifras publicadas que amasar. Las tablas de auditoría que imprimen los scripts
(fase, secciones, ejercicios declarados contra reales…) se leyeron en la terminal y sus correcciones
se hicieron a mano o con los scripts `edita` de `comandos.sh`.

## 7. ✅ Qué se espera ver

La salida de referencia de cada script es su `.salida.txt`, la que la sesión vio el 13/09/2026. Los de
`03-revision-03630220` imprimen `✅` por comprobación y `❌` con el detalle cuando algo falla; las dos
baterías de cierre terminan en **«TODO EN VERDE»**: `015-2006-verifica` (ocho comprobaciones, 20:06 UTC) y
`020-2126-verifica` (21:26 UTC). `009-1913-verifica` muestra `❌ 0 rotos` en enlaces: es un defecto de
presentación de ese script (pinta ❌ aunque el conteo sea cero), y el `015` lo corrigió. Hoy, contra el
curso cambiado, la referencia es que `prompts/verificar-corpus.py` termine con 0 errores.

## 8. 📂 Salidas

- `salidas/inventario-cs.txt`, `salidas/inv-<sesión>.txt`, `salidas/sesiones.txt` — el inventario de las
  23 sesiones que mencionan los cursos de `cursos-algoritmos-lenguajes`, con el que se decidió qué
  rescatar. Se rehace con `rescatar-transcripcion.py --inventario <sesión>… --bash`.
- Nada se copió al curso.

## 9. 🧹 Limpieza

Nada que limpiar: las verificaciones no crean contenedores ni archivos. `salidas/` se borra entera sin
pérdida.

## 10. 🚫 Qué se dejó fuera

- **Los 135 scripts que editaban la prosa** durante la redacción y la revisión: están completos en
  `comandos.sh`.
- **El código del curso** (`src/legacy`, `src/modern`, `src/fases`): vive en el curso.
- **Otras sesiones:** `07a07e01` (12/09, actualizó `CLAUDE.md` y preparó a la vez `prompts/` de C# y
  Python; no tiene código de prueba) y `5c52573d` (05/10, la revisión contra `zz-instrucciones/` y la
  migración a Mermaid, cuyo código está en `../c-sharp-for-java-devs-20261005-f6c7/`).
