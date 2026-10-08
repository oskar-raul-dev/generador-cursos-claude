# 📒 pk05 — Poetry y PDM

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Antes de `uv`, la respuesta de la comunidad a "quiero un `pom.xml` para Python" fue **Poetry**: un proyecto declarado en `pyproject.toml`, dependencias con
rangos, un `poetry.lock` con todo fijado, entornos manejados por la herramienta y la publicación a PyPI con un comando. **PDM** llegó después con la misma idea y
un apego más estricto a los estándares de empaquetado (PEP 621 desde el principio). Muchos proyectos que este perfil va a heredar —la herramienta de la franquicia
de Zipaquirá, por ejemplo— están en Poetry.

El camino base no las midió. Esta sección agrega esos números, con el mismo encargo y las mismas condiciones del benchmark §07 del curso (FastAPI, SQLAlchemy,
`httpx`, `pytest` y `uvicorn`; caché aislada y vacía, y una segunda pasada en caliente), y con `uv` medido en la misma corrida como referencia, para que la
comparación sea en la misma máquina.

---

## 🧠 2. El modelo

| | Poetry 2.5.1 | PDM 2.29.2 | `uv` 0.12.23 |
|---|---|---|---|
| Declaración | `pyproject.toml` (PEP 621 desde la 2.0) | `pyproject.toml` (PEP 621) | `pyproject.toml` (PEP 621) |
| *Lock* | `poetry.lock` | `pdm.lock` | `uv.lock` (universal) |
| Instala el intérprete | No | Sí (`pdm python install`) | Sí |
| Escrito en | Python | Python | Rust |
| Publicar a PyPI | `poetry publish` | `pdm publish` | `uv publish` |
| Lo que lo distingue | La más usada en proyectos heredados | Estándares estrictos, *plugins* | Velocidad y alcance |

### Esto sí funciona igual

El modelo es el de Maven o Gradle con su *lock*: un archivo que declara qué quiere el proyecto, otro que fija qué se resolvió, y una herramienta que instala desde
el segundo. Quien entiende `pom.xml` y el `gradle.lockfile` entiende Poetry en una tarde.

---

## 💻 3. El ejemplo que corre

`medir_gestores.sh` —el mismo encargo con las tres herramientas, cada una con su caché aislada—:

```bash
set -euo pipefail
DEPS="fastapi sqlalchemy httpx pytest uvicorn"
now() { date +%s.%N; }
measure() {                    # $1 nombre, $2 comando de instalación en frío, $3 comando de reinstalación en caliente
  local start mid
  start=$(now); eval "$2" >/dev/null 2>&1; mid=$(now)
  eval "$3" >/dev/null 2>&1
  printf '%-7s fría %6.1f s · caliente %5.1f s · entorno %s\n' "$1" \
    "$(awk "BEGIN{print $mid - $start}")" "$(awk "BEGIN{print $(now) - $mid}")" "$(du -sh "$4" | cut -f1)"
}

mkdir -p p-poetry && cd p-poetry
poetry init -n --python ">=3.14,<3.15" >/dev/null && poetry config virtualenvs.in-project true --local
export POETRY_CACHE_DIR=/tmp/cache-poetry
measure poetry "poetry add $DEPS" "rm -rf .venv && poetry install --no-root" .venv
cd ..

mkdir -p p-pdm && cd p-pdm
pdm init -n --python 3.14 >/dev/null 2>&1 || true
export PDM_CACHE_DIR=/tmp/cache-pdm
measure pdm "pdm add $DEPS" "rm -rf .venv && pdm install" .venv
cd ..

mkdir -p p-uv && cd p-uv
uv init --quiet --no-workspace . && export UV_CACHE_DIR=/tmp/cache-uv
measure uv "uv add $DEPS" "rm -rf .venv && uv sync" .venv
```

```bash
pip install poetry pdm uv
bash medir_gestores.sh
```

Salida (Python 3.14.7, 05/10/2026) (los segundos son de la máquina y de la red; la caché fría incluye las descargas):

```text
poetry  fría    5.2 s · caliente   1.0 s · entorno 45M
pdm     fría   12.1 s · caliente   2.9 s · entorno 38M
uv      fría    1.0 s · caliente   0.1 s · entorno 38M
```

El mismo encargo, en la misma máquina y la misma red. `uv` agregó las cinco dependencias con la caché vacía en un segundo y recreó el entorno desde el *lock* en una
décima: **cinco veces más rápido que Poetry en frío y diez en caliente**, doce y veintinueve veces más que PDM. Poetry, que tiene fama de lento, le ganó a PDM con
holgura. Los entornos ocupan casi lo mismo: lo que se instala es lo mismo. (La cifra en frío de `uv` es mayor que la de `BENCHMARKS.md` §07 —0,4 s— porque es otra
máquina y otra red; por eso las tres se midieron juntas.)

**Detalles con intención**

- **"Fría" es agregar las dependencias con la caché vacía**: resolver, descargar, bloquear e instalar. **"Caliente"** es borrar el entorno y recrearlo desde el *lock*,
  con la caché llena: lo que pasa en cada máquina nueva y en el CI con caché.
- **La caché de cada herramienta se aísla** (`POETRY_CACHE_DIR`, `PDM_CACHE_DIR`, `UV_CACHE_DIR`) para que ninguna aproveche lo que descargó otra.
- **`virtualenvs.in-project true`** hace que Poetry cree el entorno en `.venv` del proyecto, como las otras dos; por defecto lo crea en una carpeta propia, y medir su
  tamaño sería otra cosa.
- **Las tres corren en el mismo contenedor y la misma red**: los números se comparan entre sí; contra los del camino base (otra máquina), solo el orden.

---

## ⚠️ 4. Lo que se rompe

**Poetry 1 en un proyecto heredado.** Antes de la 2.0, Poetry usaba su propia sección `[tool.poetry.dependencies]` en vez del estándar `[project]`, y muchos
proyectos siguen así. Poetry 2 los lee, pero las herramientas que esperan PEP 621 (`uv`, `pip install .` en algunos casos) no ven las dependencias. Se migra la
sección.

**El entorno fuera del proyecto.** Poetry, por defecto, crea los entornos en una carpeta suya (`~/.cache/pypoetry/virtualenvs`). El IDE, el `Dockerfile` y el cron que
buscan `.venv` no lo encuentran. `virtualenvs.in-project true` lo evita.

**Mezclar herramientas en un proyecto.** Un `poetry.lock` y un `uv.lock` en el mismo repositorio son dos verdades. Se elige una por proyecto.

---

## ⚖️ 5. Cuándo NO usarlas

**Poetry o PDM en un proyecto nuevo, si se puede `uv`.** Hacen lo mismo con menos velocidad (la tabla de arriba) y sin el *lock* universal (`pk03`).

**Migrar un proyecto que funciona en Poetry.** Si el equipo lo conoce y el CI es estable, el ahorro de segundos no paga la migración.

**PDM si nadie lo conoce.** Es técnicamente sólido y menos común: el próximo que herede el proyecto probablemente conozca Poetry o `uv`.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre la medición. **Criterio:** la tabla, y cuántas veces más rápido es `uv` en frío y en caliente que cada una.
2. Abre el `poetry.lock`, el `pdm.lock` y el `uv.lock`. **Criterio:** describes qué guarda cada uno de cada paquete.
3. Exporta el *lock* de Poetry a `requirements.txt` (`poetry export`, con su *plugin*). **Criterio:** el archivo y si trae *hashes*.

**🟡 Intermedio (4–6)**

4. Repite la medición tres veces y reporta la mediana. **Criterio:** cuánto varía cada herramienta entre corridas.
5. Migra un `pyproject.toml` de Poetry 1 (`[tool.poetry.dependencies]`) a PEP 621. **Criterio:** `uv sync` lo instala sin cambios.
6. Agrega grupos de dependencias (desarrollo, pruebas) en Poetry y en `uv`. **Criterio:** instalas solo producción con cada uno.

**🟠 Difícil (7–9)**

7. Migra la herramienta de la franquicia (o un proyecto Poetry tuyo) a `uv` y compara las versiones resueltas. **Criterio:** la lista de diferencias y por qué.
8. Mide el CI de un proyecto con Poetry y con `uv`, con caché. **Criterio:** los dos tiempos del paso de instalación.
9. Publica un paquete de prueba en TestPyPI con `poetry publish` y con `uv publish`. **Criterio:** los dos aparecen.

**🔴 Muy difícil (10)**

10. Decide qué hacer con los proyectos en Poetry de Áurea y la franquicia. **Criterio:** una página. *Rúbrica:* (a) cuáles se migran y cuáles no, con su razón; (b) los
    números de tu medición; (c) el costo de la migración; (d) qué herramienta para los proyectos nuevos.

---

## 📚 7. Referencias

**Documentación oficial**

- Poetry: https://python-poetry.org/docs/
- PDM: https://pdm-project.org/latest/
- PEP 621, metadatos en `pyproject.toml`: https://peps.python.org/pep-0621/

**Orden de lectura sugerido:** la PEP 621 (corta, y es el formato común de las tres); después la guía de migración a Poetry 2.

---

## 🚀 8. Cierre

Poetry y PDM son el modelo de Maven en Python: proyecto declarado, *lock* propio, entornos manejados. Funcionan y siguen vivos; medidos con el mismo encargo, son más
lentos que `uv`, y su lugar hoy es el de los proyectos que ya las usan. Un proyecto, una herramienta, y el `pyproject.toml` en el formato estándar.

**La señal de que quedó bien:** *"Los proyectos heredados siguen en Poetry con su `pyproject.toml` migrado a PEP 621, y los nuevos nacen en `uv`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-05 -m "op pk05 cerrada: Poetry y PDM medidos con el encargo del curso"
> ```
>
> Los commits llevan su prefijo (`op pk05: …`) y los de ejercicio su número
> (`op pk05 ej07: …`).
