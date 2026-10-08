# 🚪 Fase 07 ⭐ — Cuándo deja de ser un script

> Python para desarrolladores Java senior · Fase 7 de 18 · Bloque B
> Depende de: Fase 06 · Habilita: Fase 08
> Registro de esta fase: **script → herramienta** (la frontera, cruzándose)
> Proyecto que avanza: **el CLI migra** — `aur_cli.py` se vuelve el paquete `aur`
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Esta es la fase de la tesis del curso, y el encargo es doble: **reconocer que el script cruzó la
línea**, y **migrarlo sin reescribirlo**.

Las dos mitades importan. La primera es criterio y es lo que te vas a llevar: saber nombrar las
señales concretas de que un archivo dejó de ser un archivo, en vez de decidirlo por intuición o
por costumbre. La segunda es oficio: hacer la migración como un refactor —moviendo lo que ya
funciona, con el repositorio como testigo— y no como una reescritura, que es lo que casi todo el
mundo hace y es donde se pierden las seis fases anteriores.

Si esta fase funciona, dentro de tres años vas a estar en una discusión sobre si algo "merece un
proyecto" y vas a tener las señales en la punta de la lengua.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes enumerar las cinco señales de cruce y decir, para el código que tengas delante,
      cuáles se cumplen y cuáles no.
- [ ] `aur` existe como paquete: layout `src/`, `pyproject.toml`, y `aur resumen --sede centro`
      funciona desde cualquier directorio de la máquina.
- [ ] La migración está en la historia de git como una secuencia de movimientos, no como un
      commit que borra todo y crea todo.
- [ ] Sabes explicar, sin leerlo, qué hace `[project.scripts]` y por qué el ejecutable aparece en
      el `PATH` del entorno.
- [ ] Tienes un lockfile de verdad y puedes decir en qué se diferencia de un `pip freeze`.
- [ ] `uv` es el gestor del curso a partir de aquí, y puedes justificar esa elección —y la
      exclusión de conda— con la tabla de la sección 6 delante.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Tipos verificados y pruebas** → Fase 08. Vas a declarar `[dependency-groups]` con `pytest`
  adentro y a no escribir ninguna prueba todavía. Es incómodo a propósito: la estructura llega
  antes que su contenido, una sola vez, y esa es exactamente la excepción que esta fase justifica.
- **Entregarle esto a Patricia** → Fase 09 ⭐, que es la que cierra el Bloque B. Hoy la
  herramienta corre en **tu** máquina y en la de alguien que sabe usar una terminal.
- **Publicar en PyPI** → fuera del camino base, track `pk`. Se nombra en §5.6 y se cierra ahí.
- **El panorama completo de gestores** —Poetry, PDM, Hatch, `mamba`, `pixi`— → track `pk`. Aquí
  entran exactamente tres, y entran medidos.
- **Contenedores** → Fase 17, y solo lo justo para medir. No son la respuesta al problema de esta
  fase, y la 09 lo demuestra con números.

---

## 🧠 4. Concepto mínimo

### Las cinco señales

Llevas seis fases construyendo un archivo. Hoy `aur_cli.py` tiene unas cuatrocientas líneas,
cuatro comandos, lee cuatro formatos y escribe en SQLite. Y la pregunta no es si es feo —no lo
es— sino si **sigue siendo un script**.

No es una pregunta de tamaño. Hay scripts de mil líneas perfectamente sanos y proyectos de
doscientas que debieron nacer proyecto. Las señales son otras, y son cinco:

**Uno: lo usa más de una persona.** Mientras el único usuario eres tú, el costo de instalarlo es
cero: ya está en tu disco, ya tienes el intérprete, ya sabes cómo se invoca. En el momento en que
una segunda persona lo necesita, aparecen tres preguntas que el archivo suelto no sabe
contestar: qué versión tiene, qué necesita para correr, y cómo se actualiza.

**Dos: tiene más de un punto de entrada.** `aur_cli.py` empezó con un comando y hoy tiene cuatro.
Un `if/elif` de cuatro ramas todavía se lee; de ocho, no. Y cuando el proceso nocturno de la Fase
15 quiera **importar** la validación en vez de invocar el proceso, un archivo con el trabajo
colgando de `if __name__ == "__main__":` ya no alcanza.

**Tres: alguien pidió una opción que no encaja.** Es la señal más útil porque llega sola. Patricia
pide poder correr el resumen "de todas las sedes menos Zipaquirá", y de repente la interfaz
crece, y crece en un sitio donde ya hay tres banderas que se contradicen entre sí.

**Cuatro: probarlo duele.** Hoy la única forma de comprobar que el cálculo de comisiones está bien
es correr el archivo entero contra un CSV de ejemplo y mirar la salida. Eso no es una prueba, es
una demostración. Y en el momento en que quieras probar una función sin arrastrar el resto, el
archivo suelto se te va a resistir.

**Cinco: ya no sabes qué necesita para correr.** Es la señal que el Bloque A te dejó sentir a
propósito. Hoy `aur` no tiene dependencias —esa fue la regla— pero tiene una que nadie declaró:
**la versión del intérprete**. Si Patricia lo abre con el Python 3.9 que le instaló el sobrino,
no falla con un mensaje útil: falla con un `SyntaxError` en una línea cualquiera.

> 🧭 **La regla, para llevar:** un script deja de ser un script cuando alguien que no eres tú
> tiene que ejecutarlo, cambiarlo o probarlo. Las cinco señales son maneras de que eso te pase.

Cuéntalas sobre `aur`: se cumplen las cinco. Por eso esta fase es aquí y no en la 03.

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo, y es el más caro del curso entero:** *empezar por el proyecto*.

En tu mundo, el primer gesto de cualquier cosa nueva es `mvn archetype:generate` o un
*New Project* en IntelliJ. Sale un árbol completo: `src/main/java`, `src/test/java`, el `pom.xml`
con su `groupId`, el plugin del compilador, el directorio de recursos. Y eso está **bien** allá,
por una razón concreta que conviene decir en voz alta en vez de despacharla: en Java **no existe
el registro script**. No hay forma de escribir catorce líneas que resuelvan un problema sin
declarar una clase, un método `main` y un empaquetado. La ceremonia es el piso del lenguaje, así
que empezar por ella no cuesta nada — ya la ibas a pagar.

En Python el piso es otro, y por eso el mismo gesto sí cuesta. Un proyecto creado el día uno te
obliga a decidir el nombre del paquete antes de saber qué hace, a mantener una estructura de
directorios con un archivo dentro, y —lo peor— a ejecutar tu propio código a través de una capa
de instalación mientras todavía estás averiguando qué quieres que haga.

**Qué se escribe en su lugar:** el orden se invierte. El archivo primero, la estructura cuando el
archivo la pida. Y esto **no es pereza ni una preferencia estética**: es que la estructura
correcta se deduce del código que ya existe, y adivinarla antes sale mal. Mira el paquete que
vamos a construir en §5 —`reading`, `summary`, `fees`, `storage`— y pregúntate honestamente si
lo habrías dividido así en la Fase 01. Nadie lo habría hecho: `fees` no existía, `storage` no
existía, y `reading` parecía una línea.

#### El reflejo hermano: *"`requirements.txt` es mi `pom.xml`"*

No lo es, y en tres cosas distintas:

**No resuelve.** El `pom.xml` declara lo que quieres y Maven calcula el árbol completo, con sus
reglas de mediación de versiones. Un `requirements.txt` producido por `pip freeze` es el
**resultado** de una instalación, no la declaración de una intención. Perdió la información de
qué pediste tú y qué vino arrastrado, y esa información no se puede recuperar mirando el archivo.

**No fija el intérprete.** `<maven.compiler.release>21</maven.compiler.release>` hace fallar el
build en la máquina equivocada. Un `requirements.txt` no tiene dónde decir "esto necesita 3.14", y
la instalación en un 3.9 procede alegremente hasta que revienta en ejecución.

**No es reproducible.** Dos `pip install -r requirements.txt` en dos máquinas, o en la misma
máquina con dos semanas de diferencia, pueden producir árboles distintos: basta con que una
dependencia transitiva publique una versión nueva. Es exactamente el problema que en tu mundo
resolvieron los repositorios corporativos y las versiones fijadas, y aquí lo resuelve un
lockfile.

> ⚠️ **Y el matiz honesto, porque este perfil lo va a notar:** Maven tampoco es perfectamente
> reproducible —los rangos de versiones y los `SNAPSHOT` existen— pero su piso es mucho más alto.
> La diferencia real es que allá lo reproducible es lo normal y aquí hay que pedirlo
> explícitamente.

### Esto sí funciona igual

**La idea de un artefacto con nombre, versión y metadatos** es la misma, y `pyproject.toml` se lee
como un `pom.xml` sin las ochenta líneas de plugins. Nombre, versión, descripción, dependencias,
punto de entrada.

**La separación entre dependencias de ejecución y de desarrollo** existe igual y significa lo
mismo: lo que tu programa necesita para correr contra lo que tú necesitas para trabajar en él.
`[dependency-groups]` es el `<scope>test</scope>` de toda la vida.

**El versionado semántico** funciona idéntico, y las mismas discusiones sobre cuándo subir la
menor te esperan aquí.

**Y el criterio para dividir en módulos es tu criterio de siempre**: cohesión, una razón para
cambiar, y no dividir por dividir. Lo único que cambia es que aquí un módulo es un archivo y no
hace falta una clase para justificarlo.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `pom.xml` | `pyproject.toml` | No orquesta el build ni tiene ciclo de vida: lo lee quien lo lea. No hay `mvn package` universal |
| `<dependencies>` | `[project] dependencies` | Declara rangos; **no** fija. Fijar es trabajo del lockfile |
| `<scope>test</scope>` | `[dependency-groups] dev` | Los grupos son libres: puedes tener `dev`, `docs` y `bench` sin un vocabulario cerrado |
| `<maven.compiler.release>` | `requires-python` | Sí se verifica al instalar, y es la única defensa contra el Python 3.9 del sobrino |
| `src/main/java` | `src/aur/` | El `src/` de Python existe por otra razón: que no puedas importar tu paquete sin instalarlo. §5.2 |
| `groupId` + `artifactId` | solo `name` | Sin *namespace*: el nombre es global y de quien lo registró primero en PyPI |
| JAR ejecutable + `Main-Class` | `[project.scripts]` | No produce un artefacto autocontenido: genera un lanzador dentro del entorno |
| `~/.m2/repository` | la caché del gestor | La caché no es el entorno: el entorno es una copia (o un enlace duro) por proyecto |
| `mvn dependency:tree` | `uv tree` / `pipdeptree` | Sale del lockfile o del entorno instalado, no de una resolución declarativa |
| `mvn versions:display-dependency-updates` | `uv lock --upgrade` | No hay reporte: hay reresolución, y el diff del lock es el reporte |

> 📝 **Nota de ecosistema — por qué hay tantos gestores.** Entre 2018 y 2024 el ecosistema tuvo
> Pipenv, Poetry, PDM, Hatch, `pip-tools`, conda y `pipx`, todos resolviendo pedazos distintos
> del mismo problema y ninguno todos. Eso no fue caos gratuito: fue que los estándares —PEP 517,
> 518, 621, 735— llegaron **después** de las herramientas, y cada una se inventó su propio
> archivo mientras tanto. Hoy el estándar existe y la mayoría convergió en `pyproject.toml`, lo
> cual significa que **cambiar de gestor es mucho más barato que antes**: el mismo archivo lo
> entienden todos. El panorama completo vive en el track `pk`; aquí entran los tres que
> representan modelos distintos.

### Los tres pedazos que vas a montar

**`pyproject.toml`** es la declaración del artefacto, y tiene tres secciones que importan hoy:
`[project]` con los metadatos y las dependencias, `[project.scripts]` con los ejecutables, y
`[build-system]` diciendo qué programa sabe empaquetar esto. Esa última es la que sorprende: en
Python el empaquetador es una dependencia más, elegible, y no una parte del lenguaje.

**El layout `src/`** parece burocracia y resuelve un problema real. Si tu paquete está en la raíz
del repositorio, el directorio actual está en `sys.path` y `import aur` funciona **sin haberlo
instalado**. Suena cómodo y es una trampa: significa que nunca pruebas lo que vas a entregar,
sino los archivos crudos. Con el paquete dentro de `src/`, `import aur` solo funciona si está
instalado, así que lo que corres es siempre lo que se instala. Es la misma disciplina que en Java
te da gratis el hecho de que ejecutes contra `target/classes` y no contra el editor.

**Los *entry points*** son cómo `aur` acaba en tu `PATH`. `[project.scripts] aur = "aur.cli:main"`
le dice al instalador que genere un lanzador llamado `aur` dentro del entorno, que llama a la
función `main` del módulo `aur.cli`. El equivalente exacto del `Main-Class` del manifiesto, con
la diferencia de que puede haber varios y de que el lanzador vive en el entorno, no en un
archivo que puedas mandar por correo. **Esa diferencia es la Fase 09 entera.**

---

## 💻 5. El refactor, movimiento por movimiento

> 🧭 **La regla de esta sección, y es lo que separa esta fase de un tutorial de empaquetado:
> nada se reescribe.** Cada paso es `git mv`, cortar y pegar, o agregar un archivo nuevo. Si al
> terminar tienes código que no reconoces de las seis fases anteriores, te reescribiste el
> proyecto y perdiste la lección.

### 5.1 Primer movimiento: el esqueleto, sin tocar el código

```bash
mkdir -p src/aur
git mv aur_cli.py src/aur/cli.py
touch src/aur/__init__.py
git add src/aur/__init__.py
git commit -m "fase 07: el script se muda a src/aur/cli.py, sin cambios de contenido"
```

Un commit que solo mueve. Es a propósito: dentro de tres fases, `git log --follow
src/aur/cli.py` va a mostrarte la historia completa desde la Fase 01, y eso solo funciona si el
movimiento y los cambios van en commits separados.

El `__init__.py` es lo que convierte un directorio en un paquete importable:

```python
"""aur — la caja de herramientas de Patricia.

Consolida los exports de las diez sedes, valida antes de generar, y produce
los archivos que exige la normatividad colombiana.
"""

__version__ = "0.7.0"
```

> 💡 **La versión empieza en `0.7.0` y no en `1.0.0`.** El menor es la fase que la produjo, que
> es una convención de este curso y no del ecosistema — pero sirve para lo de siempre: `aur
> --version` te dice contra qué material estás mirando. El `0` mayor dice lo que dice en todas
> partes: esto todavía puede romper su interfaz.

### 5.2 Segundo movimiento: partir el archivo

Cuatrocientas líneas con cuatro responsabilidades claras. Se parten siguiendo lo que el código ya
separó solo, y el criterio es el de siempre: **una razón para cambiar cada una**.

```text
src/aur/
├── __init__.py     versión y docstring
├── cli.py          argparse y los comandos. Lo único que sabe que existe una terminal
├── reading.py      leer los exports: csv, encodings, el BOM. Lo que la Fase 06 arregló
├── summary.py      el resumen del mes: el cálculo puro, sin E/S
├── fees.py         el motor de comisiones de la Fase 03
├── storage.py      el histórico en sqlite3
└── errors.py       los errores del dominio de la Fase 04
```

El corte no es arbitrario y conviene poder defenderlo: `reading` cambia cuando cambia el formato
de Odontovía; `summary` y `fees` cambian cuando cambia una regla de negocio; `storage` cambia
cuando cambia el esquema; `cli` cambia cuando Patricia pide otra opción. Cuatro razones distintas,
cuatro archivos.

**Lo que queda en `cli.py`**, después de mover, es solo la interfaz:

```python
"""Punto de entrada de la herramienta. Lo único que sabe que existe una terminal."""

import argparse
import sys
from pathlib import Path

from aur import __version__
from aur.errors import AurError
from aur.reading import read_rows
from aur.summary import render, summarize


def build_parser() -> argparse.ArgumentParser:
    """El parser de la Fase 05, movido tal cual."""
    parser = argparse.ArgumentParser(
        prog="aur",
        description="Cierre de mes de la red Áurea.",
    )
    parser.add_argument("--version", action="version", version=f"aur {__version__}")

    commands = parser.add_subparsers(dest="command", required=True)

    summary_cmd = commands.add_parser("resumen", help="Resumen del mes de una sede.")
    summary_cmd.add_argument("--sede", required=True, help="Nombre de la sede, en minúsculas.")
    summary_cmd.add_argument("--mes", required=True, help="Mes en formato AAAA-MM.")
    summary_cmd.add_argument("--datos", type=Path, default=Path("data"),
                             help="Directorio con los exports. Por defecto, ./data")
    return parser


def main(argv: list[str] | None = None) -> int:
    """Punto de entrada del ejecutable `aur`.

    Devuelve el código de salida en vez de llamar a sys.exit: así se puede probar
    llamándola como función, que es la mitad de lo que gana el proyecto al dejar
    de ser un script. La Fase 08 lo aprovecha.
    """
    args = build_parser().parse_args(argv)

    try:
        path = args.datos / f"{args.sede}-{args.mes}.csv"
        print(render(summarize(read_rows(path)), path))
    except AurError as error:
        # Los errores del dominio salen con su mensaje, sin traza: la traza es
        # para nosotros, no para quien corre la herramienta.
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    # Se conserva para que `python -m aur.cli` siga funcionando mientras dure
    # la migración. Cuando el ejecutable esté instalado, sobra — y la Fase 09
    # decide si se queda.
    sys.exit(main())
```

**Detalles con intención**

- **`main` devuelve un entero en vez de llamar a `sys.exit`.** Es el cambio más pequeño de la
  fase y el que más valor tiene: una función que devuelve un código se puede llamar desde una
  prueba; una que mata el proceso, no. Es literalmente la señal cuatro —*probarlo duele*—
  resuelta con una línea.
- **Los imports son absolutos** (`from aur.reading import read_rows`), no relativos. Los dos
  funcionan; los absolutos se leen mejor y sobreviven a mover archivos.
- **`cli.py` no calcula nada.** Si en algún momento necesitas importar `cli` para hacer un
  cálculo, el corte quedó mal.

### 5.3 Tercer movimiento: `pyproject.toml`

```toml
[project]
name = "aur"
version = "0.7.0"
description = "La caja de herramientas de Patricia: cierre de mes de la red Áurea."
readme = "README.md"
# La defensa contra el Python 3.9 del sobrino: pip y uv se niegan a instalar
# esto en un intérprete que no cumpla, con un mensaje que sí se entiende.
requires-python = ">=3.13"

# Vacío, y es el resultado de siete fases de disciplina: el Bloque A no
# necesitó una sola dependencia de terceros. Cuando la Fase 10 agregue FastAPI,
# va aquí — y va con su rango, no con su versión exacta.
dependencies = []

[project.scripts]
# Genera el lanzador `aur` dentro del entorno. Equivale al Main-Class del
# manifiesto de un JAR, con la diferencia de que vive en el entorno instalado.
aur = "aur.cli:main"

[dependency-groups]
# Lo que hace falta para trabajar en esto, no para ejecutarlo. La Fase 08 las usa.
dev = ["pytest==9.1.1", "pytest-cov==7.1.0", "ruff==0.16.7", "mypy==2.3.1"]

[build-system]
# Quién sabe convertir este directorio en un paquete instalable. En Python el
# empaquetador es una dependencia elegible, no parte del lenguaje — por eso hay
# que nombrarlo, y por eso va con su piso de versión como todo lo demás.
requires = ["hatchling>=1.32"]
build-backend = "hatchling.build"

[tool.ruff]
# La configuración que vivía en ruff.toml desde la Fase 00 se muda aquí:
# un archivo menos en la raíz, y todo lo del proyecto en un solo lugar.
target-version = "py314"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B"]
```

Y el `ruff.toml` de la Fase 00 se borra en el mismo commit. Es el primer archivo que el proyecto
**absorbe**, y no va a ser el último: en la Fase 08 le va a pasar lo mismo a la configuración de
`pytest` y la del verificador de tipos.

> 📝 **Nota de ecosistema — `[dependency-groups]` es nuevo de verdad.** Lo estandarizó PEP 735
> en 2024. Antes, cada herramienta tenía su propia manera de decir "esto es de desarrollo":
> `[tool.poetry.group.dev]`, un `requirements-dev.txt` suelto, o —lo más común y lo peor— un
> *extra* opcional llamado `dev`, que abusaba de un mecanismo pensado para otra cosa. Vas a
> encontrar las tres formas en proyectos vivos. Ninguna está rota; la nueva es la que todas las
> herramientas entienden igual.

### 5.4 Cuarto movimiento: instalar y comprobar

```bash
uv sync
```

Un comando. Lee el `pyproject.toml`, crea `.venv` si no existe, **baja el intérprete si tu
máquina no tiene uno que cumpla `requires-python`**, resuelve, instala el grupo `dev`, instala
`aur` en modo editable, y escribe `uv.lock`.

```bash
.venv/bin/aur --version
# aur 0.7.0

.venv/bin/aur resumen --sede centro --mes 2026-03
# procedimientos: 598 · pacientes: 299 · total: $146.175.000
```

**Prueba de fuego, y es la que de verdad comprueba que cruzaste la línea:**

```bash
cd /tmp                      # sal del directorio del proyecto
/ruta/al/proyecto/.venv/bin/aur --version
```

Si eso imprime la versión, tu herramienta ya no depende de dónde estés parado. El script de la
Fase 01 no podía hacer eso: necesitaba que el archivo estuviera ahí. **Esa es la frontera,
ejecutada.**

Y la mentira que te va a contar la salida si miras el lugar equivocado: `aur` funciona desde
cualquier directorio, pero **sigue buscando `./data`**, así que ejecutarlo desde `/tmp` va a
fallar por el archivo, no por el paquete. Que el error sea ese y no un `ModuleNotFoundError` es
justamente la señal de que la instalación quedó bien.

### 5.5 El lockfile, que es el punto

```bash
head -20 uv.lock
```

Lo que tiene y `pip freeze` no: **la versión de Python para la que se resolvió**, la distinción
entre lo que pediste y lo que vino arrastrado, los hashes de cada artefacto, y el conjunto de
plataformas para las que la resolución es válida. Eso es lo que hace que la instalación en la
máquina de otro produzca exactamente lo mismo que en la tuya.

> 🧭 **Se versiona el lock de una aplicación o una herramienta; no se versiona el de una
> biblioteca.** Tu herramienta quiere reproducibilidad exacta. Una biblioteca que fija sus
> dependencias le impone sus decisiones a todo el que la use, y eso en el ecosistema de Python se
> considera mala educación — con razón. `aur` es una herramienta: el lock va a git.

**El patrón a memorizar**

> `pyproject.toml` declara lo que quieres; el lock registra lo que resultó. El primero lo escribes
> tú y admite rangos; el segundo lo escribe la herramienta y no se edita a mano. Confundirlos es
> el origen del 90% de los "en mi máquina funciona" de este ecosistema.

### 5.6 Lo que esta fase no te da, y hay que decirlo

Tienes una herramienta instalable **en un entorno**. Eso resuelve tu máquina y la de cualquiera
que tenga `uv` y una terminal.

No resuelve a Patricia. Ella no tiene `uv`, no tiene terminal abierta nunca, y su portátil es de
la sede. Todo lo que construiste hoy es la condición necesaria de la Fase 09, y no la respuesta.

Tampoco entra **publicar en un índice de paquetes**: subirlo a PyPI, o montar uno interno para
Áurea, es del track `pk`. Se nombra para que sepas que existe y porque la pregunta llega sola al
ver `[project] name`, y se cierra aquí: el camino base no publica nada.

---

## 📏 6. Medición — los tres gestores sobre el mismo encargo

Esta es la medición que ordena la fase, y la que decide el gestor del resto del curso.

**Hipótesis.** Para el stack de este curso, `uv` domina a `pip` + `pip-tools` en tiempo sin perder
nada, y conda resuelve un problema que este curso no tiene. La columna que decide no es ninguna de
las de tiempo: es cuántos pasos tiene que dar Patricia.

**Condiciones.** macOS 26.6 · Apple Silicon, 8 núcleos · el mismo encargo para los tres:
instalar `fastapi==0.141.1`, `sqlalchemy==2.0.52`, `httpx==0.28.1`, `pytest==9.1.1` y
`uvicorn==0.52.4` sobre Python 3.14 — las dependencias reales del Bloque C, elegidas para que la
medición prediga el curso y no un caso de juguete. **Caché aislada y vacía para cada
herramienta** (`PIP_CACHE_DIR`, `UV_CACHE_DIR`, `CONDA_PKGS_DIRS`), y después una segunda pasada
con la caché ya poblada. Versiones: pip 26.2.1 con pip-tools 7.6.1, `uv` 0.12.13, Miniforge
26.7.2-0 con canal `conda-forge` únicamente. Cada número es una corrida, no una mediana de
muchas: las diferencias son de un orden de magnitud y no hacen falta percentiles para verlas —
donde no lo fueran, se dice.

**Competidores.** Los tres representan **modelos distintos**, no tres marcas: `pip` + `pip-tools`
es el estándar que está en todas partes y que tu empresa probablemente tenga; `uv` es el
resolvedor rápido que además gestiona intérpretes; Miniforge es el gestor que instala también
software que no es Python. Los tres están configurados como los configuraría alguien que los
conoce: `pip-tools` con su `.in` y su `.txt` —no un `pip freeze`, que sería un espantapájaros— y
conda con un `environment.yml` con canal declarado.

**Resultado.**

| | `pip` + `pip-tools` | **`uv`** | Miniforge |
|---|---|---|---|
| Resolver, caché fría | 3.4 s | **0.8 s** | *incluido abajo* |
| Instalar, caché fría | 11.1 s | **0.4 s** | 43.0 s *(entorno completo)* |
| Resolver, caché caliente | 3.1 s | **0.03 s** | — |
| Recrear el entorno, caché caliente | 7.4 s | **0.1 s** | 12.5 s |
| Entorno en disco | 74 MB | **27 MB** | 211 MB |
| Caché en disco | 12 MB | 33 MB | 66 MB |
| Paquetes en el lock | 22 | 22 | 22 (vía `pip`) |
| ¿Instala el intérprete? | **no** | sí, 3.2 s / 25 MB | sí, incluido |
| Costo de tener la herramienta | ya viene con Python | un instalador | 80 MB de descarga, 17.6 s, **422 MB** de base |
| Primer `import fastapi` | **0.33 s** | 2.28 s | 2.54 s |
| Segundo `import` en adelante | 0.32 s | 0.32 s | 0.29 s |
| **Pasos que da Patricia** | **6** | **2** | **4** |

La última fila es un conteo, no un tiempo, y se cuenta así:

- **`pip` + `pip-tools`:** buscar el instalador de Python correcto, instalarlo acertando la
  versión y marcando la casilla del `PATH`, abrir una terminal, crear el entorno, activarlo
  —distinto en PowerShell que en `cmd`—, e instalar. **Seis pasos, y el primero es el que falla:
  ella no sabe cuál versión.**
- **`uv`:** instalar `uv`, y `uv sync`. **Dos.** El intérprete correcto lo baja la herramienta
  porque el `pyproject.toml` lo declara.
- **Miniforge:** descargar 80 MB, instalar, abrir el *Miniforge Prompt* —una terminal nueva que
  ella no ha visto—, y crear el entorno. **Cuatro**, y uno de ellos le cambia el `PATH` de su
  máquina.

> ⚖️ **Veredicto.** **El gestor del curso de aquí en adelante es `uv`**, y la decisión no se toma
> por los 0.4 segundos: se toma por las dos filas de abajo. `uv` instala el intérprete que el
> proyecto declara, lo cual convierte el problema de Patricia de seis pasos en dos y elimina la
> única causa de fallo que ella no puede diagnosticar.
>
> **Dónde pierde `uv`, y es un número que casi nadie publica:** el primer `import` cuesta **2.28
> s contra 0.33 s**. No es magia ni un defecto de resolución — es que `uv` no precompila el
> bytecode al instalar y `pip` sí, así que la primera ejecución paga la compilación completa. Se
> arregla con `uv pip sync --compile-bytecode`, y hay que saberlo: en un contenedor que arranca
> en frío, o en la primera vez que Patricia abre la herramienta un viernes a las siete, dos
> segundos de silencio se sienten. Las ejecuciones siguientes empatan: 0.32 s contra 0.32 s.
>
> **Y sobre conda, sin rodeos: para este stack no hace falta.** Las cinco dependencias del Bloque
> C son wheels de PyPI que instalan sin compilar nada, así que la ventaja real de conda —traer
> bibliotecas compiladas que no son Python— no se ejerce ni una sola vez en el camino base.
> Adoptarlo costaría 422 MB de base, 43 segundos de creación de entorno, y enseñar canales,
> `environment.yml` y la convivencia incómoda de `conda install` con `pip install`, todo para
> comprar un problema que el curso no tiene. **Su modelo es el correcto cuando el paquete que
> necesitas no es Python** —NumPy compilado contra una BLAS concreta, PyTorch con CUDA, GDAL— y
> eso llega en el track de datos e IA, donde `conda-forge` pasa a ser el gestor por defecto de
> ese track. Ahí la tabla se invierte y el curso lo va a decir con la misma claridad.
>
> **El umbral donde cambia la respuesta**, que es lo que convierte esto en criterio: si tu
> proyecto necesita **una sola** biblioteca que no sea Python y que no tenga wheel para tu
> plataforma, conda deja de ser exceso y pasa a ser lo correcto. Y si tu empresa te prohíbe
> instalar herramientas nuevas —que pasa, y más de lo que se cree—, `pip` + `pip-tools` hace el
> trabajo con dos archivos y un paso más; la Fase 00 te enseñó `pip` y `venv` a mano justamente
> para que ese escenario no te deje sin salida.

**Lo que no se midió, y se declara:** una sola plataforma y una sola corrida por caso; no se midió
en Windows, donde el antivirus cambia los números de instalación de forma notoria y donde
`uv` tiene más ventaja porque escribe menos archivos. No se midió el consumo de memoria de los
resolvedores. No se midió el caso que más le convendría a conda —una dependencia binaria sin
wheel—, porque el camino base no tiene ninguna: eso lo mide el track de datos, y hasta entonces
el veredicto de arriba vale **solo para este stack** y así está escrito.

> ⚠️ **`uv` es joven y se mueve rápido.** Versión fijada: **0.12.13**, verificada el **12 de
> septiembre de 2026**, y así queda fijada en todo el curso. El curso no finge lo
> contrario, y la mitigación ya está puesta desde la Fase 00: sabes hacer esto a mano con `pip` y
> `venv`. Si `uv` desaparece mañana, pierdes velocidad, no el oficio.

---

## 🧱 7. Miniproyecto — *El entorno de Patricia*

**El encargo**

Patricia te escribe el jueves: *"Listo, ya me convenciste, quiero usar tu programa para el cierre
de marzo. Pero te aviso lo que tengo, para que no me digas después: el portátil es de la sede, no
soy administradora —para instalar algo tengo que llamar a Édgar y él contesta cuando puede—, y
hace como dos años vino un muchacho a arreglar la impresora y me instaló un Python para algo. No
sé cuál. ¿Sirve?"*

Resuelve el problema completo: dejar `aur` corriendo en ese portátil, **con las tres opciones de
la sección 6**, y escribir la recomendación con la tabla delante.

**Por qué duele**

Porque el problema no es técnico, es de restricciones ajenas, y las tres opciones fallan en
lugares distintos: una necesita que ella acierte una versión que no sabe cuál es, otra necesita
un permiso que no tiene, y la tercera le cambia la configuración de su máquina. Y porque la
opción que a ti te resulta obviamente mejor —porque la mediste y ganó por un orden de magnitud—
puede no serlo cuando el que la ejecuta no eres tú.

**Datos de entrada**

El portátil de Patricia no existe, así que lo simulas, y simularlo bien es medio miniproyecto:

- **Un Python viejo de origen desconocido.** Instala o localiza un intérprete anterior a 3.13 en
  tu máquina y úsalo como "el que le instaló el muchacho". Tiene que ser el primero del `PATH`
  en tu escenario de prueba.
- **Sin permisos de administrador.** Todo lo que hagas tiene que caber en el directorio del
  usuario. Si una opción exige `sudo` o el instalador pide elevación, eso **es** el resultado de
  la medición para esa opción, y se anota.
- **Windows.** Si no trabajas en Windows, declara esa limitación por escrito y razona la columna
  de Windows con la documentación oficial en la mano en vez de inventarla. Media fase del curso
  se cae cuando alguien asume `/tmp` y barras inclinadas.
- El proyecto `aur` tal como quedó en §5, y los datos de `data/`.

**Criterios de aceptación**

- [ ] Las **tres** opciones quedan ejecutadas de verdad, no descritas: `pip` + `pip-tools`, `uv`,
      y Miniforge. Cada una en un directorio limpio y con su caché aislada.
- [ ] Por cada opción, la secuencia **literal** de pasos que daría Patricia, en el orden en que
      los daría, incluyendo lo que tiene que decidir ella y lo que le sale mal si decide
      distinto.
- [ ] Una tabla con tus propios números: tiempo de instalación total desde cero, tamaño total en
      disco —entorno más herramienta más intérprete—, y pasos.
- [ ] **La recomendación escrita, de media página**, con la opción elegida, la que descartaste
      que más te costó descartar, y **la condición concreta que te haría cambiar de opinión**.
- [ ] Al menos un párrafo sobre qué pasa con la **versión siguiente**: cuando arregles un error
      dentro de tres semanas, ¿qué hace Patricia? Si tu opción no tiene respuesta a eso, dilo —
      es un hallazgo legítimo y la Fase 09 lo retoma.
- [ ] **Medición:** el tiempo total, desde una máquina sin nada hasta `aur --version` imprimiendo,
      para la opción que recomiendas. Ese número va en el mensaje del tag.

**Restricciones de registro**

> Esto es una **herramienta**, y ya estás del otro lado de la frontera: `pyproject.toml`, layout
> `src/`, lockfile versionado, dependencias declaradas. La restricción aquí va en la dirección
> contraria a la del Bloque A: **no resuelvas esto con un script**. Si te descubres escribiendo
> un `.bat` que copia archivos a la máquina de Patricia, acabas de reinventar la instalación sin
> ninguna de sus garantías, y la Fase 09 te va a cobrar cada una de las que falten.

**La trampa**

La opción que gana en tu máquina no es necesariamente la que menos pasos le pide a ella, y vas a
tener que elegir entre esas dos cosas con un número delante.

Y hay una segunda, que solo aparece si de verdad ejecutas las tres: **una de ellas te va a
funcionar en tu máquina por una razón que no se cumple en la de Patricia** — algo que ya tenías
instalado, una variable de entorno que llevas años arrastrando, o el intérprete correcto que ya
estaba ahí. Encontrar cuál es, y cómo lo descubriste, vale más que la tabla entera.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

No midas las tres opciones en tu entorno de trabajo: cada una en un directorio limpio y con su
caché propia, o los números no significan nada. Ya tienes la técnica de la sección 6.

Para "sin permisos de administrador", la pregunta que hay que hacerle a cada opción es la misma:
*¿dónde escribe esto, exactamente?* Las tres tienen una forma de instalarse en el directorio del
usuario, y las tres lo documentan.

Y para simular el Python viejo, lo que cuenta no es cuál instales sino **que sea el primero del
`PATH`**, porque ese es el escenario real. Tu `diagnostico.py` de la Fase 00 sirve para
comprobar que lo montaste bien.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [Instalación de `uv`](https://docs.astral.sh/uv/getting-started/installation/) — mira en
  particular la instalación sin privilegios y `uv tool install`, que es el mecanismo que la Fase
  09 va a usar.
- [Guía de `pip-tools`](https://pip-tools.readthedocs.io/) — el flujo `.in` → `.txt`, y
  `--generate-hashes`, que es lo que acerca ese `.txt` a un lock de verdad.
- [Miniforge](https://github.com/conda-forge/miniforge) — la instalación en modo `-b` (sin
  preguntas) y con `-p` (prefijo elegido), que es la que no toca nada fuera del directorio.
- Y `requires-python` en la [especificación de
  `pyproject.toml`](https://packaging.python.org/en/latest/specifications/pyproject-toml/): es lo
  que hace que dos de las tres opciones fallen **temprano y con un mensaje legible** en lugar de
  tarde y con un `SyntaxError`.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

El entregable no es código, es un documento — pero conviene que el documento lo produzca un
script, porque vas a repetir las tres instalaciones más de una vez:

```python
def prepare(option: str) -> Path:
    """Directorio limpio y caché aislada para una de las tres opciones."""

def install(option: str, workdir: Path) -> dict[str, float]:
    """Ejecuta la instalación completa y devuelve tiempos y tamaños."""

def steps(option: str) -> list[str]:
    """Los pasos de Patricia, escritos. Esto lo redactas tú; no se mide solo."""

def render_table(results: dict) -> str:
    """La tabla, en markdown, lista para pegar en el informe."""
```

Y el informe se llama `INFORME-ENTORNO-PATRICIA.md`, en la raíz del repositorio.
</details>

**Cómo se entrega**

```bash
python medir_entornos.py            # produce la tabla
$EDITOR INFORME-ENTORNO-PATRICIA.md  # la recomendación, escrita por ti
```

```bash
git add medir_entornos.py INFORME-ENTORNO-PATRICIA.md
git commit -m "fase 07 mini: el entorno de Patricia, las tres opciones medidas"
git tag -a mini-07 -m "Mini F7: entorno de Patricia · <opción> en <N> s desde cero, <M> pasos"
```

<details><summary>💡 Solución de referencia — la forma del informe, no el informe</summary>

Este miniproyecto **se evalúa por la justificación, no por el empaquetado**, así que la solución
de referencia no es un archivo: es el estándar contra el que se compara el tuyo.

**La decisión que se tomó, y por qué.** `uv`, por la fila de los pasos y no por la del tiempo.
La razón concreta es que `requires-python = ">=3.13"` más `uv sync` eliminan **la única decisión
que Patricia no puede tomar bien**: cuál versión de Python instalar. Las otras dos opciones se la
devuelven —`pip` explícitamente, conda envuelta en un `environment.yml` que ella no va a leer— y
esa decisión es la que produce el 100% de los fallos que terminan en una llamada telefónica.

**El otro camino defendible, reconocido.** `pip` + `pip-tools` gana en dos escenarios reales y
hay que decirlo: si Édgar no autoriza instalar `uv` —una herramienta nueva, de una empresa que él
no conoce, en un portátil de la sede— entonces `uv` simplemente no es una opción, y todo el
análisis anterior sobra. Y si la máquina resulta tener ya un 3.13 o 3.14 correcto, los seis pasos
se vuelven tres y la diferencia se encoge mucho. Una recomendación que no contempla el veto de
Édgar está incompleta.

**La trampa, explicada entera.** Casi todo el mundo mide la instalación **en su propia máquina de
desarrollo**, donde ya hay un intérprete correcto, una caché poblada y un `PATH` trabajado
durante años. Ahí las tres opciones parecen razonables y la diferencia se reduce a segundos. El
escenario de Patricia elimina esas tres ventajas a la vez, y solo entonces se ve que lo que
separa a las opciones no es la velocidad sino **cuántas decisiones le delegan al usuario**. Si tu
informe concluyó "son parecidas", casi seguro mediste en tu entorno y no en el de ella.

**Qué se habría hecho distinto si el registro fuera otro.** Si `aur` siguiera siendo un script de
un archivo sin dependencias, la respuesta correcta sería mandarle el `.py` por correo y decirle
que lo abra con doble clic — y habría funcionado, siempre que el Python del muchacho fuera
suficientemente nuevo. Si fuera una aplicación con servidor y base de datos, nada de esto
aplicaría: se desplegaría en algún lado y Patricia abriría un navegador. **Las tres respuestas
son correctas para su registro**, y elegir mal el registro es lo que hace que este problema
parezca difícil.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Agrega un segundo ejecutable en `[project.scripts]` llamado `aur-doctor` que apunte al
   diagnóstico de ambiente de la Fase 00. Reinstala y demuestra que los dos aparecen en
   `.venv/bin`.
2. Sube la versión a `0.7.1`, reinstala, y demuestra con `aur --version` que el cambio viajó.
   Explica en una línea por qué hizo falta reinstalar (o por qué no).
3. Mueve la configuración de `ruff` de `ruff.toml` a `pyproject.toml` y borra el archivo viejo en
   el mismo commit. Comprueba que `ruff check` sigue aplicando las mismas reglas.
4. Cambia `requires-python` a `">=3.99"` e intenta instalar. Copia el mensaje de error exacto.
   Esa es la defensa contra el Python del sobrino: míralo funcionar una vez.
5. Corre `uv tree` y compara la salida con `mvn dependency:tree` de cualquier proyecto tuyo.
   Anota dos diferencias de fondo, no de formato.
6. Borra `.venv` entero y reconstruye con `uv sync`. Cronométralo. Ese número es el costo real de
   equivocarte con un entorno a partir de hoy.

**🟡 Intermedio (7–14)**

7. Agrega `httpx` como dependencia con un rango (`>=0.28,<0.29`), corre `uv lock`, y lee el diff
   del lockfile. Explica qué se agregó además de `httpx` y de dónde salió.
8. Consulta la documentación de `hatchling` y averigua cómo incluir un archivo de datos —por
   ejemplo, `tarifas.toml`— dentro del paquete instalado. Demuéstralo instalando y leyendo ese
   archivo desde código.
9. Averigua qué hace `uv pip compile --generate-hashes` en `pip-tools` y qué garantiza que no
   garantiza un `requirements.txt` normal. Aplícalo y mira el archivo.
10. Mueve el paquete de `src/aur/` a `aur/` en la raíz, reinstala, y encuentra el caso concreto en
    que `import aur` funciona sin estar instalado. Después devuélvelo a `src/` y explica en tres
    líneas qué protegía ese directorio.
11. Crea un segundo *entry point* que ejecute el mismo `main` con un prefijo de argumentos fijo
    (por ejemplo `aur-centro`). Decide si eso es buena idea y justifica la respuesta.
12. Con `uv run`, ejecuta un comando sin activar el entorno. Explica qué hace exactamente y en qué
    se parece y en qué no a `mvn exec:java`.
13. Lee la especificación de `pyproject.toml` y agrega `classifiers`, `license` y `authors` bien
    formados. Averigua cuál de los tres tiene un formato que cambió recientemente y qué lo
    reemplazó.
14. Rompe el paquete a propósito: renombra `summary.py` sin actualizar el import en `cli.py`.
    Ejecuta y lee el error. Después hazlo al revés —renombra la función y no el archivo— y
    compara los dos mensajes. ¿Cuál de los dos habría atrapado el verificador de tipos de la Fase
    08?

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un compañero dice que `aur` "le funciona en la terminal pero no desde el
    cron". Reproduce el escenario —una tarea que invoca `aur` sin el entorno activo— y da las dos
    formas correctas de resolverlo. Explica cuál escogerías para el proceso nocturno de la Fase
    15 y por qué.
16. **Diagnóstico.** Instalas el proyecto, cambias una línea de `summary.py`, ejecutas, y el
    cambio no aparece. Enumera las tres causas posibles en orden de frecuencia y el comando que
    confirma cada una. (Pista: una de ellas se llama instalación editable y otra tiene que ver con
    el archivo de bytecode.)
17. **Medición.** Reproduce la tabla de la sección 6 en tu máquina con las tres opciones. Si tu
    resultado contradice el veredicto, escribe por qué crees que pasa antes de dudar de tu
    medición — y después dúdalo también.
18. **Medición.** Mide el efecto de `--compile-bytecode` en `uv`: primer import con y sin él, y
    tiempo de instalación con y sin él. Decide si lo dejarías activado para el proyecto de Áurea y
    justifica con los dos números.
19. **Medición.** Cronometra `uv sync` en un entorno limpio con y sin red, usando solo la caché.
    Averigua qué bandera fuerza el modo sin red y para qué escenario real de Áurea sirve.
20. **De registro.** Julián pide "un botón en el escritorio para que Patricia corra el cierre".
    Decide el registro de esa solicitud: ¿sigue siendo la herramienta que acabas de empaquetar,
    o es otra cosa? Justifica con el costo de las alternativas, y guarda la respuesta: la Fase 09
    la va a contestar con números.
21. **De registro.** Tienes un script de veinte líneas que lee el cuaderno fotografiado de
    Zipaquirá y produce un CSV. Lo corres tú, una vez al mes, y funciona. Aplícale las cinco
    señales de §4 una por una y decide si merece cruzar la frontera. **La respuesta esperada es
    que no**, y el ejercicio es escribir por qué con las cinco señales en la mano.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue que la instalación de `aur` falle en una máquina limpia por una
    razón que el `pyproject.toml` no declara. Hay al menos dos caminos: algo que tu código asume
    del sistema operativo y algo que asume del sistema de archivos. Documenta el fallo y arregla
    la declaración.
23. **Defiende una decisión.** El curso eligió `uv` y descartó conda para el camino base. Escribe
    el argumento **a favor de conda** tan fuerte como puedas —existe, y no es débil— y después
    responde con los datos de la sección 6. Termina nombrando el escenario concreto en el que tu
    propio argumento a favor gana, y verifica si Áurea lo tiene.
24. **Adversarial.** Toma el lockfile, cambia a mano el hash de un paquete, e intenta instalar.
    Después borra una dependencia transitiva del lock y vuelve a intentar. Documenta los dos
    comportamientos y explica qué protección te acabas de demostrar a ti mismo.
25. **Diseño.** La Fase 15 va a importar `aur` desde el proceso nocturno:
    `from aur.summary import summarize`. Mira el corte de módulos de §5.2 y decide si aguanta ese
    uso o si hay algo que hoy está en el lugar equivocado —por ejemplo, algo de `cli.py` que el
    batch va a necesitar—. Si encuentras el problema, arréglalo ahora; si no lo encuentras,
    escribe por qué crees que no existe. La Fase 15 te dará la razón o no.

**🔥 Opcionales**

- Empaqueta `aur` como *wheel* (`uv build`) y mira qué hay adentro descomprimiéndolo. Es un ZIP;
  compáralo con el contenido de un JAR que tengas a mano.
- Averigua qué es un *editable install* a nivel de archivos: busca en `site-packages` qué dejó la
  instalación de `aur` y entiende cómo `import aur` encuentra tu `src/`.
- Prueba Poetry o PDM sobre el mismo `pyproject.toml` y mira cuánto funciona sin cambios. Es la
  mejor forma de comprobar lo que dice la nota de ecosistema sobre la convergencia del estándar.

---

## 📚 9. Referencias

**Documentación oficial**

- [Especificación de `pyproject.toml`](https://packaging.python.org/en/latest/specifications/pyproject-toml/)
  — la referencia normativa de cada clave. Es la que hay que citar cuando alguien discuta.
- [Guía de empaquetado de Python](https://packaging.python.org/en/latest/tutorials/packaging-projects/)
  — el recorrido completo, con los backends alternativos.
- [Documentación de `uv`](https://docs.astral.sh/uv/) — proyectos, lockfile, gestión de
  intérpretes y `uv tool`. Fijado en 0.12.13: la documentación describe la última, y esta
  herramienta cambia rápido.
- [`hatchling`](https://hatch.pypa.io/latest/config/build/) — el backend que usa este curso; la
  sección de inclusión de archivos es la que necesita el ejercicio 8.
- [`pip-tools`](https://pip-tools.readthedocs.io/) — el flujo `.in` → `.txt`, y `--generate-hashes`.
- [Miniforge](https://github.com/conda-forge/miniforge) — instalación y uso del canal
  `conda-forge`.

**PEPs** (aquí sí explican el porqué, y se nota)

- [PEP 517](https://peps.python.org/pep-0517/) y [PEP 518](https://peps.python.org/pep-0518/) —
  por qué el empaquetador es una dependencia elegible y no parte del lenguaje. Es la decisión que
  explica casi todo lo raro del ecosistema.
- [PEP 621](https://peps.python.org/pep-0621/) — los metadatos en `[project]`, que unificaron lo
  que cada herramienta hacía a su manera.
- [PEP 735](https://peps.python.org/pep-0735/) — `[dependency-groups]`, y qué problema tenían los
  *extras* que se usaban para esto.
- [PEP 508](https://peps.python.org/pep-0508/) — la sintaxis de un requisito, incluidos los
  marcadores de entorno que vas a ver en el lockfile.

**Orden de lectura sugerido.** Antes de escribir: la especificación de `pyproject.toml`, saltando
lo que no uses hoy. Durante: la documentación de `uv` sobre proyectos y lockfile. Después: el PEP
517, que es corto y explica por qué este ecosistema tiene tantas herramientas — se disfruta mucho
más cuando ya montaste el archivo a mano.

> ⚠️ URLs, títulos y contenidos cambian, y en esta fase más que en ninguna: `uv` publica versiones
> cada pocas semanas. Verifica contra la versión fijada en esta fase antes de
> dar nada por bueno.

---

## 🚀 10. Cierre y conexión con la siguiente fase

`aur` cruzó la frontera. Tiene nombre, versión, metadatos, un ejecutable que funciona desde
cualquier directorio, un lockfile que hace que la instalación de otra máquina produzca lo mismo
que la tuya, y —lo más importante— **una historia de git que muestra que llegó ahí moviendo lo que
ya funcionaba**, no reescribiéndolo.

Y tienes el criterio, que es lo que de verdad te llevas: las cinco señales, y la disciplina de
contarlas antes de decidir. Te va a servir bastante más seguido de lo que crees, y casi siempre
para decir que **no**: la mayoría de los scripts no cruzan la línea y no deben cruzarla.

La **Fase 08** le pone al proyecto las dos redes que en Java venían de fábrica y que aquí hay que
instalar a mano: el verificador de tipos y la suite de pruebas. Es la única fase del curso que
empieza con una medición incómoda —activar el verificador sobre el código que **tú** escribiste
en el Bloque A y contar cuántos errores reales aparecen— y esa medición es la más convincente del
curso precisamente porque no hay contra quién discutirla. Ahora se puede hacer, además, porque
`main` devuelve un entero y los módulos se importan por separado: la estructura de hoy es lo que
hace posible probar mañana.

> **La señal de que quedó bien:** ya no vas a preguntarte *"¿esto debería ser un proyecto?"*. Vas
> a contar las cinco señales, y en la mayoría de los casos vas a responder que no y seguir con tu
> archivo tranquilo.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-07 -m "F7 cerrada:
> - las cinco señales de cruce, contadas sobre el propio CLI
> - aur es un paquete: layout src/, pyproject.toml y ejecutable en el PATH del entorno
> - la migración quedó en git como movimientos, no como reescritura
> - uv.lock versionado, y la diferencia con pip freeze entendida
> - los tres gestores medidos sobre el mismo encargo, con veredicto escrito
> - el entorno de Patricia resuelto de las tres formas y recomendado con números"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 07: …`), los de ejercicio su número
> (`fase 07 ej12: …`) y el miniproyecto el suyo (`fase 07 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-07`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
