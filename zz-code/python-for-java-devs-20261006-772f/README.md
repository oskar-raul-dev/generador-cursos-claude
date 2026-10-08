# 🧪 python-for-java-devs-20261006-772f · cómo correr estas pruebas

> **Curso:** python-for-java-devs · **Tanda:** rescate posterior al cierre · **Creado:** 2026-10-06
> **Propósito:** rescatar de las transcripciones de las sesiones el código de prueba de la producción
> del curso, con instrucciones para replicarlo.
> **Qué no es:** el código del curso. Ese vive en `cursos-algoritmos-lenguajes/python-for-java-devs/src/`
> (fases 01–06, 13–14, `iaNN` y `dsNN`) y en los bloques de las secciones `opNNN`; buena parte de lo de
> aquí se corre **contra** él.
> **Vigencia:** rescatado el 2026-10-06 sin ejecutar nada. Los resultados de estas pruebas no están
> aquí: están en el curso (`BENCHMARKS.md`, las tablas 📏 de cada fase y las salidas rotuladas de la
> carta). Este directorio guarda **cómo se obtuvieron**.

Las sesiones de septiembre escribieron sus pruebas en `/tmp/claude-501/…` y en el scratchpad, que el
sistema ya borró. Lo único que sobrevive son las **transcripciones** de esas sesiones
(`~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/<sesión>.jsonl`): cada
archivo creado con `Write` o con `cat > archivo <<EOF` está ahí completo, y cada comando con su salida.
`rescatar.sh` reconstruye todo desde ellas (lo hace `../regenerar-rescates.py` con la lista de `../rescates.tsv`).

---

## 1. 🎯 Qué se prueba y para qué

| Carpeta | Sesión | Fecha | Qué alimenta |
|---|---|---|---|
| `01-base-b74cbeda/` | `b74cbeda…` | 13/09, 00:54–05:24 UTC | Camino base, F00–F17: las 18 entradas del Bloque A–C de `BENCHMARKS.md` |
| `02-ia-bd47dbaf/` | `bd47dbaf…` | 13/09, 05:24–21:59 UTC | Track `ia01`–`ia08`: las pruebas de `src/iaNN/` y los generadores de datos |
| `03-ds-2859734a/` | `2859734a…` | 13/09 19:41 → 14/09 13:35 UTC | Track `ds01`–`ds09`: las entradas `dsNN` de `BENCHMARKS.md` |
| `04-carta-5c52573d/` | `5c52573d…` | 05/10, 14:59–21:57 UTC | Carta opcional `op001`–`op156`: las salidas rotuladas «Salida (Python 3.14.7, 05/10/2026)» |
| `05-carta-codigo/` | — | copia del 06/10 | El código que la carta escribió en `salidas/` de su directorio, que no se versiona |

**Camino base (`01-base-b74cbeda/archivos/_tmp/claude-501/`)**, una carpeta por fase:

| Carpeta | Fase | Qué mide |
|---|---|---|
| `coldstart/` | F00 · B-00 | arranque en frío de CPython contra la JVM (`Hello.java`, `bench.py`) |
| `memb.py`, `memb2.py` | F01 · B-01 | pertenencia en `list`, `set` y `dict` |
| `f02/` | F02 · B-02 ⭐ | lista intermedia contra tubería perezosa sobre 500.000 citas (`generar_citas.py`, `bench.py` —el arnés—, `medir_f02.py`) |
| `f03/` | F03 · B-03 | la ceremonia y el costo de un registro (`estilo_java.py`, `estilo_python.py`, `medir_registros.py`) |
| `f04/` | F04 · B-04 | EAFP contra LBYL |
| `f05/` | F05 · B-05 ⭐ | el costo de crear un proceso, contra un binario firmador simulado |
| `f06/` | F06 · B-06 | releer los CSV sucios contra un índice en `sqlite3` |
| `mgr/` | F07 · B-07 ⭐ | pip-tools, uv y conda sobre el mismo `reqs.in` (`drive.py`, `drive_uv.py`, `run_pip.sh`, `env.yml`) |
| `f08/` | F08 · B-08 | mypy y Hypothesis sobre el reparto (`test_reparto.py` encuentra el error de `float`) |
| `f07/` | F09 · B-09 ⭐ | las cuatro formas de entregar: paquete `aur`, PEP 723 (`cierre.py`) y PyInstaller |
| `f10/` | F10 · B-10 | el costo de validar con Pydantic en la frontera de FastAPI |
| `f11/` | F11 · B-11 | SQL directo, Core y ORM, y el N+1 (Postgres) |
| `f12/`, `f12b/` | F12 · B-12 | el mismo CRUD en Django (`f12`) y en FastAPI + Jinja (`f12b`) |
| `f13/` | F13 · B-13 | pérdidas y duplicados con y sin defensas, contra `socio_falible.py` |
| `f14/` | F14 · B-14 ⭐ | el GIL en las dos cargas, la doble reserva y el `threading.Lock` inútil entre procesos (Postgres) |
| `f15/` | F15 · B-15 | el fallo de la hora cinco del cierre nocturno |
| `f16/` | F16 · B-16 | el costo del registro y el perfil del cierre (`perfilar.py`, Postgres) |
| `f17/` | F17 · B-17 🏁 | el duelo FastAPI contra Spring Boot 3.5.16: `agenda-java/` (Maven), `duelo.py`, `medir_resto.py`, `medir_contenedor.py` |

`patch9.py` no es una prueba: editó `prompts/alcance-del-proyecto.md`.

**Track `ia` y `ds`:** el código de prueba se escribió directamente en `src/iaNN-…/` y `src/dsNN-…/` del
curso, y ahí sigue (cada uno con su `README.md` de corrida). Lo que se rescata aquí es **cómo se corrió**
(`bitacora.md`, `comandos.sh`), las verificaciones sueltas (`scripts/`) y las cuatro sondas de `ds02`
que vivieron en `/tmp` (`03-ds-2859734a/archivos/_tmp/`: `probe.py`, `smoke_ds02.py`, `dtypes_ds02.py`,
`cow_ds02.py`). El `shared.py` de `03-ds-2859734a/archivos/…/src/ds09-servir-el-modelo/` es la primera
versión del módulo que la sesión renombró a `upstream.py` («Rename the module and re-export»). Las
mediciones `ia` quedaron **sin ejecutar**, salvo una fila (lo declara `BENCHMARKS.md` § «Complementos
`ia` — pendientes de ejecutar»); sus pruebas unitarias sí corrieron.

**Carta:** el arnés vive en el directorio de la sesión, `../python-for-java-devs-20261005-f516/`
(`humo.py`, `humo_servicio.py`, `probado.py`, `carta.py`, `plan.py`, `verificar_urls.py`), y cada
sección escribió su código en `../python-for-java-devs-20261005-f516/salidas/<id>/`. Aquí está la
última corrida de cada sección (`04-carta-5c52573d/humo-por-seccion.sh`, 136 secciones), los archivos
que la sesión escribió y ya no existen en disco (`04-carta-5c52573d/archivos/`, 16: las variantes
`ema_nb`, `ema_pb` y `ema_rs` de `ff05`, sondas de `so01`, `so02`, `or04`, `sy07`…) y la copia
versionada de `salidas/` (`05-carta-codigo/`, 273 archivos).

### Qué hay en cada carpeta rescatada

- `comandos.sh` — **todos** los comandos Bash de la sesión, en orden, con su hora y su descripción. Es
  una bitácora, no un script: no se corre entero.
- `bitacora.md` — solo los comandos que ejecutaron código (docker, uv, pytest, `python3 x.py`…) con los
  primeros 1.500 caracteres de su salida. Es la referencia de §7.
- `scripts/NNN-HHMM-verifica.{py,sh}` — cada script en línea (`python3 - <<'PY'`) y cada comando Bash de
  varias líneas que **no** escribe archivos, con su `.salida.txt`: lo que la sesión vio al correrlo. Los
  que editaban la prosa se omiten (siguen en `comandos.sh`).
  La clasificación es por patrón (`write_text`, `sed -i`, `open(…, 'w')`…): puede fallar en un caso raro.
- `archivos/` y `archivos.tsv` — los archivos reconstruidos (con sus `Edit` posteriores aplicados) que
  ya no están en disco, o que están fuera del curso y cambiaron. La ruta dentro de `archivos/` es la
  original relativa al repositorio (o la absoluta sin la `/` inicial), con un `_` delante de cada
  carpeta que el `.gitignore` excluye: `/tmp/claude-501/f02/` queda en `archivos/_tmp/claude-501/f02/` y
  `…-f516/salidas/ff05/` en `archivos/zz-code/…-f516/_salidas/ff05/`, para que git los versione.
  `archivos.tsv` guarda la ruta original y el estado: `no-existe` o `existe-distinto`.

## 2. 🛠️ Prerrequisitos

**Para reconstruir** (`rescatar.sh`): Python 3 de la biblioteca estándar y las transcripciones en
`~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/`. El rescatador es
`zz-instrucciones/herramientas/rescatar-transcripcion.py`, la herramienta del repositorio.

**Para volver a correr el camino base**, lo que usó la sesión del 13/09 (máquina de `BENCHMARKS.md`
§ «El entorno de referencia»: macOS 26.6, Apple Silicon, 8 núcleos):

- CPython **3.14.5** en `/opt/homebrew/bin/python3.14`; `/usr/bin/python3` del sistema para el escenario 3
  del diagnóstico de F00.
- **uv** instalado en `mgr/.tool-uv/` con su caché en `mgr/cache-uv` (lo crea `mgr/`; las demás fases
  hacen `uv venv --python /opt/homebrew/bin/python3.14 .venv` y `uv pip install` con las versiones
  exactas de `prompts/alcance-del-proyecto.md` §9: fastapi 0.141.1, uvicorn 0.52.4, pydantic 2.13.5,
  sqlalchemy 2.0.52, psycopg[binary] 3.3.5, alembic 1.20.0, django 6.1.1, httpx 0.28.1, pytest 9.1.1,
  hypothesis 6.168.0, mypy 2.3.1, pyinstaller 6.22.3, structlog 26.1.0, opentelemetry-sdk 1.44.0,
  prometheus-client 0.26.0).
- **PostgreSQL 18.0** de Homebrew (`/opt/homebrew/opt/postgresql@18/bin`), con `initdb -U aurea
  --auth=trust` y la base `agenda`, para F11, F14 y F16.
- **Java 21.0.8 Zulu** en `~/.sdkman/candidates/java/21.0.8-zulu` y Maven, para F17; **OpenJDK 17.0.16**
  para F00.
- Docker, solo para `f17/medir_contenedor.py`.

**Track `ds`:** uv con `uv run --python 3.14 --with …` y las versiones fijadas en cada `src/dsNN/README.md`
(numpy 2.5.3, pandas 3.0.5, polars 1.44.2, duckdb 1.5.5, pyarrow 25.0.1, matplotlib 3.11.2, plotly 7.0.0,
altair 6.2.2, papermill 2.7.0, jupyterlab 4.6.3, marimo 0.24.2, scikit-learn 1.9.1, torch 2.14.0,
skl2onnx 1.20.0, onnxruntime 1.30.0, onnx 1.22.0).

**Carta:** Docker con `python:3.14.7` (127 corridas), `python:3.14.7-slim`, `debian:trixie-slim`,
`condaforge/miniforge3:26.7.2-0`, `valkey/valkey:9.0.6-alpine`, `axllent/mailpit:v1.31.4`,
`greenmail/standalone:2.1.14` y las imágenes locales `pfjd-sede:humo` y `pfjd-sftp:humo` que construyen
`au04` y `co05`. Las imágenes que se bajaron están anotadas en
`../python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt`.

## 3. 🧭 Reglas antes de correr

> ⚠️ **El camino base y los tracks `ia`/`ds` se probaron en el host**, el 13/09, antes de que existiera
> la regla de contenedores: Python, Postgres y la JVM corrían en la máquina, Postgres en el puerto
> 55432 por socket Unix y los servidores del duelo en 8124 y 8125. **Hoy se corren en contenedor.**
> La carta (05/10) ya se probó así.

1. **Inventario inicial**, para borrar al final solo lo creado:
   ```bash
   cd zz-code/python-for-java-devs-20261006-772f
   mkdir -p salidas
   docker ps -aq --no-trunc > salidas/contenedores-antes.txt
   docker images -q --no-trunc | sort -u > salidas/imagenes-antes.txt
   docker volume ls -q > salidas/volumenes-antes.txt
   docker network ls -q > salidas/redes-antes.txt
   ```
2. **Todo con la etiqueta `curso=python-for-java-devs`**, y se borra solo por esa etiqueta. Nada de
   `docker system prune` ni `image prune` sin filtro.
3. **Ningún puerto por defecto publicado.** Postgres va en una red propia o en `127.0.0.1::5432` (puerto
   aleatorio), nunca en 5432.
4. **Las sondas se corren desde `salidas/`**, nunca desde `archivos/`: los rescatados se dejan como
   salieron de la transcripción.

## 4. ▶️ Cómo se corre

### Reconstruir el rescate

```bash
cd zz-code/python-for-java-devs-20261006-772f
./rescatar.sh               # rehace desde cero 01- a 04-, humo-por-seccion.sh y 05-carta-codigo/; no ejecuta nada
./rescatar.sh --comprobar   # lo regenera aparte y compara, sin tocar nada
```

`rescatar.sh` borra solo lo que `../rescates.tsv` declara generado y lo rehace; `extraer_humo.py` y
`copiar_codigo_carta.sh` son dos de sus pasos (este último acepta `DEST=` para escribir en otro lugar).
`copiar_codigo_carta.sh` copia código y archivos de build (`.py`, `.pyx`, `.c`, `.cpp`, `.rs`, `.toml`,
`.sql`, `Dockerfile`…) y deja fuera salidas, llaves, binarios, el `.c` que genera Cython, `jv03/graalpy`,
`mutants/`, `.venv/` y el `airflow-home/` que escribe Airflow.

### Camino base, en contenedor

```bash
cd zz-code/python-for-java-devs-20261006-772f
docker network create --label curso=python-for-java-devs pfjd-base
docker run -d --name pfjd-pg --label curso=python-for-java-devs --network pfjd-base \
  -e POSTGRES_USER=aurea -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=agenda postgres:18.0
PG_HOST_RUN=pfjd-pg PG_PORT_RUN=5432 ./preparar_base.sh      # copia a salidas/claude-501 y reescribe rutas
BASE="$PWD/salidas/claude-501"
```

`preparar_base.sh` copia `01-base-b74cbeda/archivos/_tmp/claude-501/` a `salidas/claude-501/` y cambia
`/tmp/claude-501` por esa ruta y la conexión `host=/tmp/claude-501 port=55432` por
`host=$PG_HOST_RUN port=$PG_PORT_RUN` (por omisión `127.0.0.1` y `55432`). Una fase se corre así,
montando su carpeta (ejemplo: F02):

```bash
docker run --rm --label curso=python-for-java-devs --network pfjd-base -v "$BASE":/w -w /w/f02 \
  python:3.14.7 sh -c 'python generar_citas.py && python medir_f02.py'
```

Las fases con dependencias las instalan antes de correr, con las versiones de §2
(`pip install -q --root-user-action=ignore fastapi==0.141.1 …`). La secuencia exacta de cada fase
—qué se instaló, en qué orden se generaron los datos y qué script midió— está en
`01-base-b74cbeda/bitacora.md`, buscando la fase por su carpeta (`/f11`, `/f14`…). Tres casos no caben
en el contenedor tal cual:

- **F00 y F17** miden arranque en frío y memoria de la JVM y de CPython **en el host**; dentro de una VM de
  Docker las cifras cambian. Para reproducir las de `BENCHMARKS.md` hay que correrlas en el host, como
  entonces, con `JAVA` y `PY` apuntando a los binarios del host (`f17/duelo.py`, líneas 6–8).
- **F07** mide los gestores de entorno contra la caché de uv y de pip: `mgr/drive_uv.py` necesita
  `mgr/.tool-uv/`, un venv con `uv==0.12.13` que se crea con
  `python3.14 -m venv .tool-uv && ./.tool-uv/bin/python -m pip install -q uv==0.12.13` (en `comandos.sh`,
  el mismo comando que escribe `drive_uv.py`).
- **F17** compila `agenda-java/` con `mvn -q -B package -DskipTests` y levanta los dos servidores en 8124
  y 8125; en el host, comprobar antes que están libres (`lsof -ti:8124,8125`).

### Track `ia` y `ds`

Las pruebas están en el curso. Desde cada `src/dsNN-…/` la sesión corrió, con uv en el host:

```bash
CURSO=cursos-algoritmos-lenguajes/python-for-java-devs
cd "$CURSO/src/ds03-polars-y-el-modelo-lazy"
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' \
  --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q
```

Hoy, en contenedor, montando la carpeta de la sección:

```bash
docker run --rm --label curso=python-for-java-devs -v "$PWD":/w -w /w python:3.14.7 \
  sh -c "pip install -q --root-user-action=ignore pytest 'numpy==2.5.3' 'pandas==3.0.5' 'polars==1.44.2' 'duckdb==1.5.5' && python -m pytest -q"
```

Las dependencias de cada sección están en su `README.md` («Correr las cosas»); `ds08` instala siempre
torch **con** scikit-learn, porque torch solo aborta en macOS por el doble runtime de OpenMP (lo explica
su README), y `ia05` necesita `PYTHONPATH` con las secciones de las que importa. Las corridas exactas:
`03-ds-2859734a/bitacora.md` y `02-ia-bd47dbaf/bitacora.md`.

### Carta

```bash
cd zz-code/python-for-java-devs-20261005-f516
python3 humo.py op030-qa01-la-piramide-para-uno.md qa01 'pyproject.toml=[tool.pytest.ini_options]' …
```

`humo.py <sección.md> <id> <archivo=inicio>… [--pip paq==v …] [--cmd "…"]` extrae del Markdown de la
sección los bloques que empiezan con cada `<inicio>` (o el que sigue a la línea `` `archivo`: `` cuando
`<inicio>` es `@archivo`), los escribe en `salidas/<id>/` y corre `--cmd` en `python:3.14.7` con `--rm` y
la etiqueta. `humo_servicio.py` hace lo mismo con servicios (`--svc alias=imagen`) en una red propia, sin
puertos publicados, y los borra al final pase lo que pase. `probado.py <sección.md>` cambia el encabezado
y los rótulos de la sección a «probado». El comando completo de cada sección está en
`04-carta-5c52573d/humo-por-seccion.sh`; las secciones que se probaron con un `docker run` directo, sin
el arnés, están en `04-carta-5c52573d/bitacora.md`.

## 5. 📏 Cómo se mide

- **Arnés del camino base:** `f02/bench.py`, solo biblioteca estándar: reloj monótono, repeticiones,
  pico de memoria con `tracemalloc` y declaración del entorno. Las fases posteriores lo copian
  (`cp /tmp/claude-501/f02/bench.py .`). El estadístico publicado es la **mediana**
  (`statistics.median`, 22 usos), con más repeticiones cuanto más barata es la prueba: 3 a 7 en las
  pesadas, 15 en F01, 30 en el arranque en frío de F00, 40 en F11 y 400 llamadas en F10.
- **Mediciones rehechas, y por qué** (están en `bitacora.md`): F16 midió primero el volumen de registro
  con el archivo abierto («Measure logging cost and volume correctly», y `medir_obs2.py`, `medir_obs3.py`);
  F17 rehízo el arranque en frío dos veces; la segunda agregó una comprobación de que 8124 y 8125
  estaban libres («el puerto está ocupado: la medición mentiría»), para no medir un servidor que
  siguiera vivo de la corrida anterior.
- **Track `ds`:** cada `bench_*.py` de `src/dsNN/` declara sus tamaños y repeticiones; ds03 mide además
  el arranque del intérprete con la importación de cada motor, cada uno en su entorno aislado, porque
  DuckDB carga pandas cuando está instalado y eso inflaba su arranque en frío.
- **Carta:** no mide; prueba que el código corre y fija la salida que la sección publica.
- **Debilidad declarada** (`BENCHMARKS.md`): todo se midió con 8 núcleos y el dominio tiene 2.

## 6. 🧮 Los intermedios que amasan la salida

No hay filtros externos: los scripts de medición imprimen la tabla ya con la mediana y las unidades
finales, y esa tabla se copió a la sección 📏 de la fase y a `BENCHMARKS.md`. Los pasos que sí
intervienen, todos en `comandos.sh`:

- los `python3 - <<'PY'` que reescribieron la tabla de una fase con la cifra nueva (marcados `edita`, por
  eso no están en `scripts/`);
- los `grep`/`awk` de comprobación que cruzan las cifras citadas entre fases, `BENCHMARKS.md` e
  `INSTINTOS.md` (en `scripts/`, por ejemplo `03-ds-2859734a/scripts/104-0246-verifica.sh`, «Cross-check
  figures cited between sections»);
- en la carta, `probado.py`, que solo cambia rótulos; la salida pegada en la sección es la de la corrida.

## 7. ✅ Qué se espera ver

La referencia de cada prueba es su salida en `bitacora.md` (o en el `.salida.txt` de su script), con la
fecha y la hora de la corrida. Las cifras publicadas son las de `BENCHMARKS.md` (camino base:
12–13/09/2026; `ds`: 13–14/09/2026) y las salidas rotuladas «Salida (Python 3.14.7, 05/10/2026)» de cada
sección de la carta. Una corrida nueva coincide si conserva **la relación entre las opciones**, no el
valor absoluto (lo dice `BENCHMARKS.md`).

## 8. 📂 Salidas

- `salidas/claude-501/` — la copia ejecutable del camino base que hace `preparar_base.sh`. Se regenera
  corriéndolo otra vez.
- `salidas/contenedores-antes.txt` y compañía — el inventario de §3.
- Nada se copió al curso desde este rescate: lo que sirvió ya estaba publicado.

## 9. 🧹 Limpieza

```bash
docker ps -aq --filter label=curso=python-for-java-devs | xargs -r docker rm -f
docker network ls -q --filter label=curso=python-for-java-devs | xargs -r docker network rm
docker images -q --no-trunc | sort -u > salidas/imagenes-despues.txt
comm -13 salidas/imagenes-antes.txt salidas/imagenes-despues.txt     # solo estas son nuestras
rm -rf salidas/claude-501
```

Las imágenes nuevas se borran una por una, por ID, después de mirar la lista de `comm`.

## 10. 🚫 Qué se dejó fuera

- **Los entornos y artefactos:** `.venv/`, `mgr/.tool-uv/`, las cachés de uv y pip, el directorio de datos
  de Postgres (`pgdata`), el `target/` y el `.jar` de `agenda-java`, el ejecutable de PyInstaller y los
  datos generados (`f02/data/citas-2026-Q1.csv` y `f06/data/cierre/*.csv`). Se regeneran con los
  comandos de `bitacora.md`.
- **Los archivos que la sesión creó con comandos y no con `Write` ni `cat >`:** el proyecto Django de
  `f12/` lo generó `django-admin startproject` (solo `planes/models.py` y `planes/admin.py` son
  rescatables) y `diagnostico.py` de F00 lo escribió un `python3 - <<'EOF'` que tomó el bloque de
  Python más largo de la fase 00 (hoy `00-instalacion-ambiente-editores-y-ecosistema.md`); se rehace
  igual, con el comando de `comandos.sh` «Run the reference solution».
- **Los scripts que editaban la prosa** (`edita` en la clasificación): están en `comandos.sh`.
- **En `05-carta-codigo/`:** los binarios de `jv03/` (`jython.jar`, `graalpy/`), las `.so` de `ff02` y
  `ff05`, las bases `.db`, las imágenes y PDF de `ar0N`, las llaves `.pem`/`.pub` de `se0N` y las salidas
  `.log`, `.csv` y `.json`. Se regeneran corriendo la sección con su comando de `humo-por-seccion.sh`.
- **Las sesiones sin código de prueba:** `07a07e01` (CLAUDE.md y `prompts/`), `a0c9cadf` y `99f6b041`
  (historias), `dbc11096` (propuestas), `84b31996` (limpieza de `prompts/`). Se pueden rescatar igual con
  `rescatar-transcripcion.py` si hiciera falta su bitácora.
