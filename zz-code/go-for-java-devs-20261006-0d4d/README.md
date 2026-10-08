# 🧪 go-for-java-devs-20261006-0d4d · cómo correr estas pruebas

> **Curso:** go-for-java-devs · **Tanda:** rescate posterior al cierre · **Creado:** 2026-10-06
> **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción
> del curso, con instrucciones para replicarlo.
> **Vigencia:** rescatado el 2026-10-06 sin ejecutar nada.

> ⚠️ **Lo primero: en la producción de este curso no se ejecutó código Go.** Ninguna sesión corrió
> `go`, Docker ni un benchmark; las salidas de las fases son ilustrativas y así lo declaran
> `0-ESTRUCTURA-CURSO.md` §6 y el README del curso (decisión confirmada por Oskar el 05/10/2026). El
> curso tampoco tiene `src/`. **Lo único que se probó fue el corpus**: la coherencia de las 18 fases.
> Eso es lo que se rescata aquí.

El rescate se hace con `zz-instrucciones/herramientas/rescatar-transcripcion.py`; las sesiones y opciones de este
curso están en `../rescates.tsv`, y `rescatar.sh` las rehace con `../regenerar-rescates.py`.

---

## 1. 🎯 Qué se prueba y para qué

| Carpeta | Sesión | Fecha (UTC) | Qué se verificó |
|---|---|---|---|
| `01-preparacion-918474ae/` | `918474ae…` | 12/09, 02:51–03:36 | Nada: planificación del curso (Go 1.13 → versiones superiores, cuatro proyectos). Solo `comandos.sh` |
| `02-redaccion-b1c17b96/` | `b1c17b96…` | 12/09, 03:37–20:21 | La validación de continuidad tras redactar las fases (`001`–`027`, 14:15–14:30): numeración de secciones, ejercicios declarados contra reales, secciones obligatorias 🪞 🩻 📖 ⚖️ 🧨, enlaces y IDs de benchmark, marcadores 💸 con su fase de pago, disciplina de época del Bloque A, vallas de código pares, cadena de «siguiente fase», tags de proyecto, y la revalidación tras agregar los retos difíciles |
| `03-revision-c9051874/` | `c9051874…` | 13/09, 19:46–20:30 | La revisión de cierre: rutas externas y referencias a `prompts/`, enlaces relativos, ejercicios por fase, plantilla de secciones, asignación de benchmarks, miniproyectos declarados, horas y tags, deuda 💸, pendientes editoriales abiertos |

**Lo que no es del curso en `02-`:** de las 19:21 UTC en adelante (`028`–`039`) la sesión trabajó en otra
cosa: la propuesta `propuestas-cursos/propuesta-java-arquitectura/`, la lectura de
`propuesta-lab-docker`, `PLAN-REFRESCAMIENTO.md` y la reorganización del repositorio. Se dejan por
fidelidad a la sesión, no porque prueben el curso de Go.

**Ojo con las rutas de `02-`:** el 12/09 el curso vivía en la raíz del repositorio
(`courses-ia-generated/go-for-java-devs/`); hoy está en `cursos-algoritmos-lenguajes/go-for-java-devs/`.

### Qué hay en cada carpeta

- `comandos.sh` — todos los comandos Bash de la sesión, en orden, con su hora y su descripción. Es una
  bitácora: no se corre entera.
- `scripts/NNN-HHMM-verifica.{py,sh}` — las verificaciones: cada `python3 - <<'PY'` y cada comando Bash
  de varias líneas que no escribe archivos, con su `.salida.txt` (lo que la sesión vio). Se omitieron los
  44 scripts que editaban la prosa (siguen en `comandos.sh`). La clasificación es por patrón: `03/018`
  («Introduce goleak in phase 08») quedó como verificación porque esa versión solo imprimía; la
  escritura vino en el comando siguiente.
- `bitacora.md` — los comandos que el detector tomó por ejecución, con el inicio de su salida. En este
  curso **todos son búsquedas o lecturas** cuyo texto menciona «docker»: ninguno ejecutó código.

## 2. 🛠️ Prerrequisitos

- **Para reconstruir:** Python 3 (biblioteca estándar) y las transcripciones en
  `~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/`.
- **Para correr las verificaciones:** Python 3, bash, `grep` y `awk`, sobre el curso. Sin dependencias.

## 3. 🧭 Reglas antes de correr

- Las verificaciones solo leen el curso: no hace falta inventario de Docker.
- **Se corren desde la raíz del curso**, que es donde las corrió la sesión (`glob('*.md')`,
  `prompts/*.md`, `[0-9][0-9]-*.md`).
- El curso cambió desde septiembre: el 13/09 se movió la historia a `00-historia-de-la-empresa-meridian.md`
  y el 05/10 siete diagramas pasaron a Mermaid y se agregó la guía §14. Un script que hoy falla puede
  estar señalando ese cambio, no un error.

## 4. ▶️ Cómo se corre

```bash
cd zz-code/go-for-java-devs-20261006-0d4d
./rescatar.sh               # rehace desde cero las carpetas generadas (lee ../rescates.tsv); no ejecuta nada
./rescatar.sh --comprobar   # las regenera aparte y compara, sin tocar nada
```

Una verificación, contra el curso de hoy:

```bash
AQUI="$PWD/zz-code/go-for-java-devs-20261006-0d4d"
cd cursos-algoritmos-lenguajes/go-for-java-devs
python3 "$AQUI/03-revision-c9051874/scripts/002-1953-verifica.py"    # enlaces relativos
python3 "$AQUI/03-revision-c9051874/scripts/021-2013-verifica.py"    # el barrido final
bash    "$AQUI/02-redaccion-b1c17b96/scripts/026-1429-verifica.sh"   # la revalidación del 12/09
```

La verificación vigente del curso, la que reemplaza todo esto:

```bash
cd cursos-algoritmos-lenguajes/go-for-java-devs
python3 -B prompts/verificar-corpus.py
python3 -B ../../zz-instrucciones/herramientas/verificador_base.py . --perfil=courses-ia
```

## 5. 📏 Cómo se mide

No aplica: en este curso no se midió nada. Las entradas `B-` de `BENCHMARKS.md` (29 al 13/09) traen hipótesis y
condiciones; sus cifras son ilustrativas, como las salidas de las fases.

## 6. 🧮 Los intermedios que amasan la salida

No aplica: no hay cifras publicadas que amasar.

## 7. ✅ Qué se espera ver

La salida de referencia de cada script es su `.salida.txt`, la del 12 o 13/09/2026. Las dos de cierre:

- `02-redaccion-b1c17b96/scripts/026-1429-verifica.salida.txt` — `OK 18/18` en numeración y en las
  secciones obligatorias, vallas de código pares y ningún enlace roto.
- `03-revision-c9051874/scripts/021-2013-verifica.salida.txt` — plantilla de 10 secciones 18/18, **460
  ejercicios**, 29 entradas B, cero referencias externas y cero enlaces rotos, con tres pendientes
  editoriales abiertos a propósito (F14 «Decidir antes de publicar», F15, y el *hook* de pre-commit 💸
  sin pagar de F17).

Hoy, contra el curso cambiado, la referencia es que `prompts/verificar-corpus.py` termine con 0 errores.

## 8. 📂 Salidas

Nada se escribe en `salidas/`. Nada se copió al curso.

## 9. 🧹 Limpieza

Nada que limpiar: las verificaciones no crean contenedores ni archivos.

## 10. 🚫 Qué se dejó fuera

- **Los 44 scripts que editaban la prosa**: están completos en `comandos.sh`.
- **Sesiones sin código de prueba:** `111eaacc` (reescritura de `CLAUDE.md`), `238280b7` (propuesta de
  Rust), `99f6b041` (historia de Meridian), `a0c9cadf` y `dbc11096` (ideas de proyectos).
- **La revisión del 05/10** contra `zz-instrucciones/` y la migración a Mermaid: su código está en
  `../go-for-java-devs-20261005-ab98/` (`buscar_diagramas.py`, `migrar_diagramas.py`).
