# 🛠️ Fase 00 — Ambiente, editores y el mapa del ecosistema

> Python para desarrolladores Java senior · Fase 0 de 18 · Bloque A
> Depende de: ninguna · Habilita: Fase 01
> Registro de esta fase: — (todavía no escribimos software; montamos el taller)
> Proyecto que avanza: ninguno
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Al terminar esta fase tienes un intérprete del que sabes **cuál es y de dónde salió**, un
entorno virtual que entiendes por dentro en vez de invocarlo de memoria, un editor que depura
de verdad, y el mapa del ecosistema de Python dibujado encima del que ya conoces.

Eso no es "el setup". Es la primera lección de criterio del curso, y lo es porque en Python la
pregunta *¿qué intérprete está corriendo esto?* no tiene una respuesta obvia, y el 80% de los
"no me funciona" de tu primer mes van a ser exactamente esa pregunta mal contestada. En Java
esa pregunta se contesta sola: el proyecto declara su JDK, el IDE lo administra, y si hay dos
JDK instalados el problema se manifiesta con un error de versión de clase que dice literalmente
qué pasó. Acá no. Acá el síntoma es un `ModuleNotFoundError` de algo que acabas de instalar.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Sabes cuántos Python hay en tu máquina, cuál responde a `python`, cuál a `python3`, y por
      qué no son necesariamente el mismo.
- [ ] Tienes Python **3.14.7** instalado sin haber tocado el intérprete del sistema, y lo puedes
      demostrar con `sys.executable`.
- [ ] Creas, activas, inspeccionas y destruyes un entorno virtual sin consultar nada, y puedes
      explicar qué hay adentro: un directorio, unos enlaces y un `PATH` reordenado.
- [ ] `ruff` corre sobre tu código y tu editor lo aplica al guardar.
- [ ] VS Code depura un script con puntos de quiebre, o PyCharm lo hace, o los dos.
- [ ] El repositorio del curso existe, con su `.gitignore`, y tiene su primer commit.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- `pyproject.toml`, paquetes, `src/` y todo lo que huela a proyecto → **Fase 07**. Hasta
  entonces esto es un taller con archivos sueltos, y es a propósito.
- `uv`, `pip-tools`, conda y el resto del panorama de gestores → **Fase 07**, donde se comparan
  midiendo, no narrando. Hoy `pip` y `venv` a mano, que es lo que está debajo de todos ellos.
- Tipado verificado y pruebas → **Fase 08**. Vas a escribir anotaciones antes, pero nadie las
  verifica todavía.
- Contenedores → **Fase 17**, y solo lo justo para medir arranque en frío y costo. Este curso no
  tiene fase de contenedores y lo dice en `0-ESTRUCTURA-CURSO.md`.
- Instalar cualquier biblioteca de terceros para resolver un problema. Esa es la regla del
  bloque y tiene su propia sección más abajo.

Y algo que se difiere **fuera del curso**: la gestión de múltiples versiones del intérprete con
`pyenv`, `mise` o el gestor de tu sistema. Se nombra en §4 porque vas a tropezarte con ella, y
no se enseña porque el curso fija una versión y la usa entera. Cuando llegues a una empresa con
cuatro proyectos en tres versiones distintas, la herramienta se aprende en una tarde; el
criterio de esta fase es lo que no se aprende en una tarde.

---

## 🧠 4. Concepto mínimo

### El problema: en Python, "el intérprete" no existe

En tu mundo hay un JDK activo, quizá dos, y un `JAVA_HOME` que dice cuál. El build lo declara,
el IDE lo respeta, y cuando alguien se equivoca el error es ruidoso y específico.

En una máquina de desarrollo con Python, en cambio, es perfectamente normal tener cinco
intérpretes: el del sistema operativo —que en Linux y macOS existe porque el propio sistema lo
usa para sus cosas—, el que instaló Homebrew como dependencia de otro paquete, el que instalaste
tú desde python.org, el que trajo Docker Desktop, y el que vive dentro de cada entorno virtual
de cada proyecto. Ninguno sabe de los otros. `python` es simplemente el primero que aparece en
tu `PATH`, y tu `PATH` lo han ido escribiendo, a lo largo de los años, todos los instaladores
que corriste.

De ahí sale la regla que vale para todo lo que sigue:

> 🧭 **La pregunta no es "¿tengo Python instalado?" sino "¿cuál Python va a ejecutar esto?"**
> Y tiene una sola forma confiable de contestarse, que no es `python --version`:
>
> ```bash
> python -c "import sys; print(sys.executable)"
> ```

`--version` te dice qué versión es, que es la pregunta fácil. `sys.executable` te dice **cuál
binario es**, que es la que importa cuando `pip install` puso el paquete en un sitio y tu script
lo busca en otro.

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** *"El IDE me resuelve el entorno."*

Es un reflejo razonable y en tu mundo es verdad. Abres un proyecto Maven en IntelliJ, el IDE lee
el `pom.xml`, ve el `maven.compiler.release`, descarga el JDK si hace falta, indexa las
dependencias desde `~/.m2` y a los diez segundos tienes autocompletado. El proyecto **declara**
su entorno, y el IDE lo **materializa**.

Lo que produce ese reflejo aquí: abres la carpeta en VS Code, escribes un script, le das a
ejecutar, y funciona. Instalas algo con `pip install`, lo importas, y ahora no funciona. O peor:
funciona en la terminal y no en el editor, o al revés. Y no hay ningún mensaje que mencione la
palabra "entorno".

**Por qué falla:** porque en Python el proyecto no declara nada que el editor pueda materializar.
El orden de causalidad es el inverso. **Tú** creas un entorno, **tú** le dices al editor que
apunte a ese intérprete, y el editor —que no tiene forma de saberlo por su cuenta— te cree. VS
Code tiene un selector de intérprete en la barra de estado precisamente porque esa decisión no
puede tomarla él.

**Qué se escribe en su lugar:** el hábito de crear el entorno **antes** de abrir el editor, y de
verificar con `sys.executable` cuando algo no cuadra. Son diez segundos y resuelven la mayoría
de los incidentes de tu primer mes. Concretamente:

```bash
# ❌ El reflejo: abrir el editor, escribir código, y que el entorno aparezca.
code .

# ✅ El orden correcto, y es el orden de siempre a partir de hoy:
python3.14 -m venv .venv          # primero el entorno
source .venv/bin/activate          # después se activa
python -c "import sys; print(sys.executable)"   # y se verifica cuál quedó
code .                             # y al final el editor, que ya encuentra qué apuntar
```

Hay un segundo reflejo, más sutil, que conviene desactivar el mismo día: **`pip install` no es
`mvn dependency:add`.** En Maven, agregar una dependencia modifica el `pom.xml`, que es el
documento que define el proyecto y que está en git. `pip install requests` **no escribe nada en
ningún archivo**: instala en el entorno activo y se acabó. Si no lo anotas tú, en algún lado,
esa dependencia solo existe en tu máquina. Toda la miseria del empaquetado de Python de la
última década sale de esa frase, y la Fase 07 es donde la resolvemos de verdad.

### Esto sí funciona igual

Vale la pena decirlo porque el párrafo anterior deja mal sabor: **casi todo tu oficio se
transfiere intacto**, y lo que estás aprendiendo hoy es un dialecto, no una profesión nueva.

El aislamiento por proyecto es la misma idea que ya practicas, solo que con otra
implementación: un entorno virtual es lo que en tu mundo consigues con el classpath del proyecto
más el repositorio local. La diferencia es **dónde vive el aislamiento** —ahí, un repositorio
compartido con artefactos versionados; acá, un directorio por proyecto con copias— y que aquí
es responsabilidad tuya crearlo.

El depurador es el depurador de siempre: puntos de quiebre, condicionales, inspección de
variables, pila de llamadas, *step into* y *step over*, y expresiones evaluadas en el contexto
del frame. No hay nada que reaprender. Lo único que cambia es que el depurador necesita saber
cuál intérprete usar, que es otra vez la misma pregunta.

El linter y el formateador son lo que ya conoces de Checkstyle y Spotless, con una diferencia a
favor: `ruff` hace las dos cosas, corre en milisegundos, y su configuración por defecto es
buena. No vas a pasar una tarde discutiendo reglas.

Y el hábito de fijar versiones, de no depender del estado de tu máquina y de que la máquina de
otro produzca el mismo resultado es exactamente el mismo hábito. Lo que cambia es que Python te
da menos ayuda para cumplirlo, y por eso el curso lo insiste más.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `pom.xml` / `build.gradle` | `pyproject.toml` | No orquesta un build ni tiene ciclo de vida: declara metadatos y dependencias, y alguien más tiene que leerlo. Además no existe hasta la Fase 07 |
| Maven Central | PyPI | No hay *namespace* por organización: el nombre es de quien lo registró primero, y `pip install requets` instala lo que alguien haya subido con ese nombre |
| `~/.m2/repository` | el entorno virtual del proyecto | Allá un caché compartido con artefactos versionados; acá una copia por proyecto. Borrar `~/.m2` cuesta una descarga; borrar `.venv` cuesta un `pip install` y a veces una compilación |
| `JAVA_HOME` | `sys.executable` | `JAVA_HOME` lo declaras tú y el mundo lo respeta; `sys.executable` es un hecho consumado que lees después |
| `mvn test` | `pytest` | No hay ciclo de vida estándar que lo invoque: es un programa que corres, y si nadie lo corre, nadie lo corre |
| `mvn clean` | borrar `.venv` y `__pycache__` | No hay `clean` porque no hay build; lo que se ensucia son cachés, y se borran a mano |
| JAR ejecutable | varias respuestas, y ninguna es *la* respuesta | Es la parte más pobre del ecosistema, y es tan relevante para tu trabajo real que tiene dos fases: la 07 y la 09 |
| Checkstyle + Spotless | `ruff` | Una sola herramienta para linting y formato, y sin una tarde de configuración |
| `-Xmx`, flags de la JVM | casi nada | No hay equivalente y casi nunca hace falta: el intérprete no reserva un heap por adelantado |

> 📝 **Nota de ecosistema — por qué `pyproject.toml` llegó tarde y qué reemplazó.** Hasta 2016
> el archivo que describía un paquete era `setup.py`: un **script de Python que se ejecutaba**
> para averiguar qué era el paquete. Funcionaba, y tenía el defecto obvio de que para saber qué
> dependencias tenía algo había que correr código arbitrario de un desconocido. PEP 518 y PEP
> 621 lo reemplazaron por un archivo declarativo en TOML, y hoy `pyproject.toml` es el estándar
> real. Vas a encontrar `setup.py` en cualquier proyecto con más de cinco años, vas a encontrar
> `setup.cfg` como paso intermedio, y los dos siguen funcionando. Si te toca mantener uno, no
> está roto: está viejo.

### La regla del Bloque A

> 🧭 **Hasta la Fase 07 no instalas nada.**

Siete fases —el Bloque A entero— se escriben con biblioteca estándar pura. Ni una dependencia,
ni siquiera para parsear una fecha, ni siquiera para leer un CSV. Cuando un ejercicio parezca
necesitar una biblioteca, casi siempre no la necesita, y encontrar qué trae la caja es el
ejercicio.

Las razones no son de purismo. La primera es que **no sabes cuánto viene en la caja**, y no hay
forma de que lo sepas: vienes de un ecosistema donde agregar una dependencia es gratis —una
línea en el `pom.xml` que alguien más resolvió, un artefacto firmado en un repositorio
corporativo— y esa gratuidad no existe acá. La segunda es que cada dependencia que le metes a
una herramienta es algo que Patricia va a tener que instalar en su portátil, y la Fase 09 es
donde eso se vuelve un problema tuyo y no de un equipo de infraestructura. Y la tercera es la
que se mide en la Fase 02: importar cuesta tiempo de arranque, y una herramienta que un cron
invoca cuatrocientas veces paga ese costo cuatrocientas veces.

> ⚠️ **La regla es sobre lo que tu código importa, no sobre tus herramientas.** `ruff` se instala
> hoy y se usa en las dieciocho fases. La diferencia es que `ruff` no aparece en ningún `import`
> de tu programa: si mañana desaparece de tu máquina, tu código sigue corriendo. Esa distinción
> —dependencia de ejecución contra herramienta de desarrollo— es exactamente la que el
> `pyproject.toml` de la Fase 07 va a tener que expresar, y por eso conviene tenerla clara desde
> hoy.

### Las dos cosas que `pip` no hace, y que tú esperas que haga

Las nombro ahora, **no las resuelvo**, y las vas a arrastrar incómodamente durante seis fases.
Eso es deliberado: la Fase 07 no funciona como lección si llegas sin haber sentido el dolor.

**`pip freeze` no es un lockfile.** Viniendo de un árbol de dependencias resuelto, con
`mvn dependency:tree` mostrándote quién trajo a quién, lo que esperas de `pip freeze` es la
declaración reproducible de tu proyecto. No lo es. Es una **foto plana de lo que quedó
instalado** en el entorno: no distingue lo que pediste tú de lo que vino arrastrado, no guarda
por qué está cada cosa, no registra hashes, y si instalaste algo hace tres meses y luego
cambiaste de opinión, ahí sigue. Reinstalar desde un `requirements.txt` producido por
`pip freeze` reproduce **ese** estado, con la basura incluida, y solo en una máquina parecida a
la tuya.

**`pip` no te da un intérprete.** Gestiona paquetes *dentro* de un Python que ya tienes. No
puede instalarte Python 3.14 si tienes 3.11, no sabe que tu proyecto necesita 3.14, y no te va a
avisar. En tu mundo el `pom.xml` declara la versión del lenguaje y el build falla si no se
cumple; acá el equivalente es un párrafo en el README que alguien lee o no.

Anótalas. En la Fase 07 vamos a pagar por resolverlas y vas a poder juzgar si valió la pena.

### Qué es exactamente un entorno virtual

Nada mágico, y conviene desmitificarlo ahora porque la mitad de los errores de entorno se
resuelven solos cuando sabes qué hay adentro.

Un entorno virtual es **un directorio** con tres cosas: un binario de Python (o un enlace
simbólico a uno), un archivo de texto que dice de dónde salió ese binario, y un directorio
`site-packages` vacío donde `pip` va a poner lo que instales. Activarlo no hace nada esotérico:
**pone ese directorio de primero en tu `PATH`** y define un par de variables. Eso es todo.

De ahí se derivan tres consecuencias prácticas, y las tres te van a ahorrar tiempo:

- **No tienes que activarlo.** Ejecutar `.venv/bin/python script.py` funciona idéntico, sin
  activar nada, porque el intérprete sabe dónde está y encuentra su `site-packages` solo. Es lo
  que hacen los cron y los `Dockerfile`, y es lo que hace tu editor.
- **No es portable.** Adentro hay rutas absolutas de tu máquina. Copiar `.venv` a otra máquina no
  falla con un error claro: falla raro. Por eso está en el `.gitignore` desde el primer commit.
- **Es desechable.** Borrarlo y volverlo a crear es la primera reparación que hay que intentar,
  cuesta segundos, y no pierdes nada — siempre que tengas anotado qué había adentro, que es
  justo el problema del párrafo anterior.

---

## 💻 5. El taller, paso a paso

Todo lo que sigue corre en **Windows 11, Linux amd64 y macOS Apple Silicon**. Donde la
instrucción difiera, van las tres, en ese orden.

### 5.1 El intérprete

**Windows 11.** Instala desde [python.org](https://www.python.org/downloads/) con el instalador
oficial, marcando *Add python.exe to PATH*. Lo que de verdad importa es que ese instalador
también deja **el lanzador `py`**, que es lo mejor que tiene Python en Windows y no tiene
equivalente en las otras plataformas:

```powershell
py -0            # lista TODOS los Python instalados y marca cuál es el predeterminado
py -V            # versión del predeterminado
py -3.14 -V      # ejecuta uno concreto, sin importar el PATH
```

`py -0` es la respuesta directa a la pregunta de esta fase. Úsalo antes de depurar cualquier
cosa rara.

**Linux amd64.** Tu distribución ya trae un `python3` y **no lo toques**: el sistema lo usa para
sus propias herramientas, y hay distribuciones que se rompen de verdad si le instalas paquetes
encima. Para tener 3.14.7 sin pelear con el sistema, instala el paquete de una fuente que
convive con él —en Debian y Ubuntu, el PPA de *deadsnakes*; en Fedora, los paquetes
`python3.14` del repositorio oficial— o compila desde fuente si tu política lo exige. Después:

```bash
python3.14 -V
which -a python3   # todos los python3 del PATH, en orden de prioridad
```

> ⚠️ **Si al correr `pip install` fuera de un entorno virtual te aparece
> `error: externally-managed-environment`, no es un error: es el sistema defendiéndose** (PEP
> 668). Te está diciendo que ese intérprete lo administra el gestor de paquetes de la
> distribución. La respuesta correcta es crear un entorno virtual, nunca `--break-system-packages`,
> que hace exactamente lo que su nombre dice.

**macOS Apple Silicon.** Igual que en Linux: hay un `/usr/bin/python3` del sistema que no se
toca. Instala desde python.org o con Homebrew (`brew install python@3.14`), y verifica cuál
quedó de primero:

```bash
python3 -V
which -a python3
```

En las tres plataformas, la verificación que cierra el asunto es la misma:

```bash
python3.14 -c "import sys; print(sys.version); print(sys.executable)"
```

Si eso imprime 3.14.7 y una ruta que reconoces, el intérprete está listo.

> 📝 **Nota de ecosistema — qué es 3.14.7 y por qué el piso es 3.13.** Python publica una versión
> menor al año, con dos años de correcciones y tres más de parches de seguridad. El curso fija
> **3.14.7** porque es la que estaba vigente al escribirlo y porque todo lo que vamos a usar
> —`match`, `ExceptionGroup`, `tomllib`, los genéricos del PEP 695, el intérprete sin GIL— está
> ahí. El piso soportado es **3.13.15**: si tu empresa está en 3.13, el curso entero funciona
> salvo lo que se marque explícitamente. Por debajo de 3.13 no: la mitad de los ejemplos usan
> cosas que no existían.

### 5.2 El entorno virtual, a mano

Crea el directorio del curso, y adentro el entorno:

```bash
# Windows
mkdir aurea-curso
cd aurea-curso
py -3.14 -m venv .venv

# Linux y macOS
mkdir aurea-curso
cd aurea-curso
python3.14 -m venv .venv
```

Fíjate en la forma del comando, que es una convención que vas a ver todo el curso:
`python -m <módulo>` ejecuta un módulo de la biblioteca estándar como si fuera un programa.
`venv` no es un ejecutable aparte: es un módulo que viene en la caja.

Activarlo depende de tu shell, y aquí es donde más gente se equivoca:

```powershell
# Windows, PowerShell
.venv\Scripts\Activate.ps1

# Windows, cmd.exe
.venv\Scripts\activate.bat
```

```bash
# Linux y macOS, bash o zsh
source .venv/bin/activate

# fish
source .venv/bin/activate.fish
```

> ⚠️ **En PowerShell, la primera vez, es probable que te rechace el script por política de
> ejecución.** No es un problema de Python. Se resuelve con
> `Set-ExecutionPolicy -ExecutionScope CurrentUser -ExecutionPolicy RemoteSigned` — o se evita
> del todo no activando nunca y llamando a `.venv\Scripts\python.exe` directo, que es lo que
> hacen tus tareas programadas de todos modos.

Sabes que está activo porque el prompt cambia y porque:

```bash
python -c "import sys; print(sys.executable)"
# .../aurea-curso/.venv/bin/python   ← la ruta apunta adentro del proyecto
```

**Mira qué hay adentro.** Esto es la parte que no se salta:

```bash
cat .venv/pyvenv.cfg
```

```ini
home = /opt/homebrew/opt/python@3.14/bin
include-system-site-packages = false
version = 3.14.7
executable = /opt/homebrew/Cellar/python@3.14/3.14.7/.../bin/python3.14
command = /opt/homebrew/bin/python3.14 -m venv /Users/tu/aurea-curso/.venv
```

Cinco líneas de texto plano. `home` dice de qué intérprete salió,
`include-system-site-packages = false` es lo que produce el aislamiento, y `command` deja el
comando exacto con el que se creó — que es lo primero que vas a mirar dentro de seis meses
cuando un entorno se comporte raro. **Eso es un entorno virtual**: este archivo, un enlace al
binario, y un `site-packages` vacío.

**Detalles con intención**

- **Se llama `.venv` y no `venv` ni `env`.** Con punto, porque es infraestructura y no material
  del proyecto; y `.venv` concretamente porque es lo que VS Code, PyCharm y `uv` buscan por
  defecto. La convención te ahorra configuración.
- **Va dentro del proyecto, no en un directorio central.** Es lo contrario de `~/.m2`, y es
  deliberado: el aislamiento por directorio es todo el mecanismo.
- **Un entorno por proyecto.** No uno para el curso entero y otro para el trabajo. Cuestan
  segundos y megabytes.

### 5.3 `pip`, y la primera herramienta

Con el entorno activo:

```bash
python -m pip install --upgrade pip     # deja pip en 26.2.1
python -m pip install ruff==0.16.7      # la versión exacta, no la última
```

> 💡 **Usa `python -m pip` y no `pip` a secas.** Son lo mismo cuando todo está bien, y cuando
> algo está mal `python -m pip` instala inequívocamente en el intérprete que acabas de ejecutar,
> mientras que `pip` es un binario del `PATH` que puede pertenecer a otro entorno. Es el hábito
> que te va a evitar el clásico *"lo instalé y no lo encuentra"*.

Y ahora mira lo que ya sabes que va a pasar:

```bash
python -m pip list
# Package Version
# ------- -------
# pip     26.2.1
# ruff    0.16.7

python -m pip freeze > requirements.txt
cat requirements.txt
# ruff==0.16.7
```

Un archivo con una línea. Funciona, y es lo que vas a usar durante seis fases. Observa lo que
**no** tiene: no dice con qué versión de Python se produjo, no distingue que `ruff` es una
herramienta y no una dependencia de tu programa, no tiene hashes, y si mañana instalas algo para
probar y se te olvida desinstalarlo, entra ahí sin avisar. Anótalo en la lista de agravios:
se cobra en la Fase 07.

### 5.4 `ruff`, desde el primer archivo

Crea `hello.py` con algo deliberadamente mal formateado:

```python
import   sys
def main( ):
    # El primer script del curso solo contesta la pregunta de la fase.
    print( "intérprete:",sys.executable )
    print("versión:",sys.version )
main()
```

Y córrelo:

```bash
ruff format hello.py    # formatea, sin preguntar
ruff check hello.py     # revisa, y sugiere
```

`ruff format` deja el archivo con el estilo canónico de la comunidad —el mismo que popularizó
`black`— y `ruff check` te dice qué está mal más allá del formato. Los dos corren en
milisegundos sobre proyectos enteros, que es la razón por la que desplazaron a la generación
anterior de herramientas.

La configuración vive en `ruff.toml`, en la raíz del curso:

```toml
# Configuración de ruff para todo el curso.
# Todavía no existe pyproject.toml (llega en la Fase 07); cuando exista,
# esto se muda ahí bajo [tool.ruff] y este archivo desaparece.

target-version = "py314"
line-length = 100

[lint]
# El conjunto por defecto (E, F) más tres familias que este perfil agradece:
#   I  → ordena los imports, que es lo que hacía tu IDE en Java
#   UP → avisa cuando escribes una forma antigua que 3.14 ya no necesita
#   B  → bugbear: trampas reales, incluido el argumento por defecto mutable de la Fase 01
select = ["E", "F", "I", "UP", "B"]
```

> 📝 **Nota de ecosistema.** Durante una década, el estándar fueron `flake8` para linting,
> `isort` para imports y `black` para formato: tres herramientas, tres configuraciones, y un
> minuto largo en proyectos grandes. `ruff` hace las tres en un binario escrito en Rust, y por
> eso la migración fue tan rápida. Vas a encontrar los tres viejos vivos en muchos repositorios,
> y no están rotos — pero si empiezas algo hoy, empieza con `ruff`.

**Prueba de fuego**

```bash
ruff check hello.py && python hello.py
```

Tiene que imprimir una ruta que termine en `.venv`. Si imprime `/usr/bin/python3` o
`C:\Python313\python.exe`, **el entorno no está activo o estás ejecutando el archivo con otro
intérprete** — y probablemente sea tu editor el que lo hace, no la terminal. Ese es exactamente
el incidente que esta fase te enseña a leer.

### 5.5 El repositorio

```bash
git init
```

Crea el `.gitignore` de Python —el contenido está en
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md), y la primera línea es
`.venv/`—, y haz el primer commit:

```bash
git add .gitignore ruff.toml hello.py requirements.txt
git commit -m "fase 00: taller montado, ruff configurado"
git status    # tiene que estar limpio, y .venv/ no debe aparecer
```

Si `.venv/` aparece en `git status`, arréglalo ahora: son doscientos megabytes de rutas
absolutas de tu máquina camino a tu historia, y sacarlos después es más molesto que ponerlos
bien hoy.

### 5.6 VS Code, el editor principal

**Cuatro extensiones. No catorce.** Las listas de "50 extensiones imprescindibles" son ruido;
esto es lo que hace falta y lo que el curso asume instalado:

| Extensión | Identificador | Para qué |
|---|---|---|
| Python | `ms-python.python` | Selector de intérprete, ejecución, entornos, descubrimiento de pruebas |
| Pylance | `ms-python.vscode-pylance` | El servidor de lenguaje: autocompletado, navegación, tipos |
| Python Debugger | `ms-python.debugpy` | El depurador |
| Ruff | `charliermarsh.ruff` | Linting y formato con la misma herramienta de la terminal |

Las cuatro se instalan solas al aceptar el paquete recomendado de la primera, pero conviene
saber cuál es cuál cuando algo falle: si no autocompleta, es Pylance; si no para en el punto de
quiebre, es debugpy; si no formatea al guardar, es Ruff.

**Lo primero que se hace al abrir la carpeta**, y es lo que resuelve el 80% de los problemas de
esta fase: `Ctrl+Shift+P` (`Cmd+Shift+P` en macOS) → **Python: Select Interpreter** → el que
está dentro de `.venv`. La barra de estado de abajo tiene que mostrarlo. Si muestra otro, todo
lo demás va a comportarse raro.

Crea `.vscode/settings.json`:

```jsonc
{
  // El intérprete del proyecto. Con esta línea, cualquiera que clone el repositorio
  // apunta al entorno correcto sin tener que saber que existe el selector.
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",

  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      // Ordena los imports al guardar, que es lo que hacía tu IDE en Java.
      "source.organizeImports.ruff": "explicit"
    }
  },

  // Descubrimiento de pruebas. No hay pruebas hasta la Fase 08; queda listo desde ahora.
  "python.testing.pytestEnabled": true,
  "python.testing.pytestArgs": ["tests"]
}
```

> ⚠️ **En Windows, esa ruta es `${workspaceFolder}/.venv/Scripts/python.exe`.** Es el único
> ajuste de esta fase que no es igual en las tres plataformas, y es la razón por la que el
> archivo suele terminar en `.gitignore` en equipos mixtos. En un equipo de una persona, déjalo
> versionado.

Y `.vscode/launch.json`, que es lo que convierte el editor en un depurador:

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Archivo actual",
      "type": "debugpy",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      // Con esto el depurador entra también en el código de la biblioteca estándar.
      // Suena a exceso y en la Fase 04 vas a agradecerlo.
      "justMyCode": false
    },
    {
      "name": "CLI con argumentos",
      "type": "debugpy",
      "request": "launch",
      "program": "${workspaceFolder}/aur_cli.py",
      "args": ["--help"],
      "console": "integratedTerminal"
    }
  ]
}
```

La segunda configuración apunta a un archivo que todavía no existe: `aur_cli.py` nace en la Fase
01. Déjala escrita — vas a depurarlo con argumentos muchas veces, y las seis fases siguientes
asumen que puedes hacerlo.

**Prueba de fuego del editor:** pon un punto de quiebre en la línea del `print` de `hello.py`,
arranca con F5, y en la consola de depuración escribe `sys.executable`. Si el depurador para y
la expresión evalúa a la ruta del `.venv`, el editor está bien montado. Si para pero evalúa a
otra ruta, seleccionaste mal el intérprete.

### 5.7 PyCharm, la alternativa completa

Si vienes de IntelliJ y quieres seguir en casa, PyCharm es el mismo IDE con otro lenguaje
adelante: los atajos, la navegación, las refactorizaciones y el depurador son los que ya tienes
en los dedos.

> ⚠️ **Lo que el curso llamó "PyCharm Community" ya no se llama así.** Desde 2025.3 JetBrains
> unificó las dos ediciones en **un solo producto llamado PyCharm**, con una capa gratuita y una
> suscripción Pro; la Community Edition dejó de publicarse. La versión vigente al escribir esto
> es **2026.2.2**, del 7 de septiembre de 2026. Donde el material diga *PyCharm Community*, lee
> *la capa gratuita del PyCharm unificado*: para el Bloque A y buena parte del curso alcanza de
> sobra.

El mapa desde IntelliJ, que es lo único que de verdad hace falta:

| En IntelliJ | En PyCharm |
|---|---|
| *Project SDK* | *Python Interpreter*, en Settings → Project → Python Interpreter |
| Módulo Maven | el directorio del proyecto, sin más |
| *Run Configuration* de una clase `main` | *Run Configuration* de tipo *Python*, apuntando al archivo |
| Ejecutar tests con el ícono al lado del método | igual, con `pytest` como corredor (Fase 08) |
| Reformatear con `Ctrl+Alt+L` | igual, y se configura para que invoque a `ruff` |

Al abrir el proyecto, PyCharm detecta `.venv` y ofrece usarlo — acéptalo, y verifica en Settings
que el intérprete apunte ahí. Es la misma verificación de VS Code con otra ventana.

**Y lo que la capa gratuita no trae**, dicho ahora para que no lo descubras en la Fase 11 con el
proyecto a medias: soporte específico de frameworks web (las plantillas de Django, el árbol de
endpoints de FastAPI), las herramientas de base de datos y el cliente SQL integrado, el cliente
HTTP, el desarrollo remoto con intérpretes por SSH o dentro de Docker, y el perfilador. Nada de
eso es imprescindible para el curso —el Bloque C usa `psql`, `curl` y el perfilador de la
biblioteca estándar, que es lo que la Fase 16 enseña de todas formas—, pero conviene saberlo
antes de elegir editor. JetBrains mueve esa línea cada tanto: si la decisión te importa,
verifícala en su página de comparación antes de pagar nada.

---

## 📏 6. Medición — cuánto cuesta arrancar

**Hipótesis.** El arranque en frío de Python es sensiblemente menor que el de la JVM, y esa
diferencia es irrelevante para un servicio que arranca una vez al día y significativa para una
herramienta que un cron invoca cientos de veces. El costo real del arranque de Python no está en
el intérprete: está en lo que importas.

**Condiciones.** macOS 26.6 · Apple Silicon, 8 núcleos · CPython **3.14.5** (el intérprete
disponible en la máquina de referencia; la versión que fija el curso es 3.14.7, y la diferencia
de patch no afecta este número) · OpenJDK 17.0.16 (Zulu) · 30 repeticiones por caso, más 3 de
calentamiento descartadas · se mide el tiempo de pared de crear el proceso, ejecutarlo y
recogerlo, con reloj monótono · se reportan mediana, percentil 95 y mínimo.

**Competidores.** Un *hola mundo* en Java compilado, ejecutado con `java -cp . Hello`, y el
mismo con `-XX:TieredStopAtLevel=1 -Xshare:auto` —las dos banderas que cualquiera que pelee con
arranque en frío en la JVM pondría primero, y que hacen la comparación defendible—. Del lado de
Python, tres casos: el intérprete vacío, el intérprete con `-S` (que omite `site`, el módulo que
prepara `sys.path`), y el intérprete importando lo que un script real del Bloque A importa.

**Resultado.**

| Caso | Mediana | p95 | Mínimo |
|---|---|---|---|
| `python -c "pass"` | 25.0 ms | 26.3 ms | 23.6 ms |
| `python -S -c "pass"` | 17.8 ms | 18.7 ms | 15.8 ms |
| `python -c "import json, csv, pathlib, argparse"` | 31.6 ms | 33.5 ms | 30.2 ms |
| `java -cp . Hello` | 42.0 ms | 52.1 ms | 34.3 ms |
| `java -XX:TieredStopAtLevel=1 -Xshare:auto Hello` | 39.9 ms | 41.5 ms | 37.1 ms |

> ⚖️ **Veredicto.** Python arranca en **1.7× menos tiempo** que la JVM en esta máquina, y la
> diferencia absoluta son **17 milisegundos**. Léelo dos veces, porque las dos mitades importan.
>
> Diecisiete milisegundos no deciden absolutamente nada en un servicio que arranca una vez al
> día: ahí lo que decide es el arranque del framework completo, que medimos en la Fase 17 y
> donde los números son otros. Para una herramienta que un cron invoca 400 veces al día, la
> diferencia acumulada son 7 segundos diarios — que tampoco deciden nada. **El umbral donde esto
> empieza a importar de verdad está en el orden de las decenas de miles de invocaciones**, o
> cuando el arranque compite con el trabajo: si tu proceso tarda 30 ms en hacer lo suyo,
> duplicar eso con el arranque sí cambia la conversación.
>
> Lo que sí decide algo está en la tercera fila: **cuatro imports de la biblioteca estándar
> cuestan 6.6 ms, un 26% sobre el arranque vacío.** Ahí está la lección aprovechable de esta
> medición, y es la que sostiene la regla del Bloque A: las dependencias no se pagan solo al
> instalarlas, se pagan en cada invocación. Un script que importa media docena de bibliotecas
> pesadas puede tardar más en arrancar que en trabajar, y eso se mide, no se supone.
>
> **Y el empate que hay que nombrar:** con las banderas de arranque puestas, la JVM baja su p95
> de 52 a 41 ms y su dispersión casi desaparece. Bien configurada, no es el monstruo lento del
> chiste. Comparar contra `java` a secas habría inflado la ventaja de Python un 25%.

**Lo que no se midió**, y se declara: esto es una sola plataforma. No hay números de Windows 11
ni de Linux amd64, donde el sistema de archivos y el antivirus cambian el resultado —en Windows,
bastante—. Tampoco se midió consumo de memoria ni el arranque de un framework. El ejercicio 22
te pide producir el número de **tu** plataforma, que es el que de verdad te sirve.

---

## 🧱 7. Miniproyecto — *El diagnóstico de ambiente*

**El encargo**

Es tu tercera semana en Áurea. Julián te escribe un sábado: *"Patricia dice que el script que le
mandaste no le corre, que le sale un error de un módulo. A mí me corre. Yuli dice que a ella le
corría y dejó de correrle desde que el sobrino le instaló no sé qué. ¿Podemos tener algo que yo
le pueda pedir que corra y me diga qué tiene esa máquina, en vez de que me manden fotos de la
pantalla?"*

Escribe esa herramienta: un solo archivo `.py`, sin dependencias, que alguien no técnico pueda
ejecutar con doble clic o con un comando que quepa en un mensaje de WhatsApp, y que produzca un
diagnóstico legible de la situación de Python en esa máquina.

**Por qué duele**

Porque *"cuál es el Python de esta máquina"* no tiene una sola respuesta, y tu script tiene que
reportar las varias que hay sin mentir: el que lo está ejecutando, los que están en el `PATH`,
el que responde a `python` y el que responde a `python3`, si hay un entorno virtual activo y de
qué proyecto, y si el que ejecuta el script es el mismo que el `pip` que está de primero en el
`PATH`. Esa última comparación es la que explica el error de Patricia, y es la que un script
ingenuo no hace.

**Datos de entrada**

Ninguno: la entrada es la máquina. Pero el diagnóstico tiene que ser correcto en al menos estos
tres escenarios, que puedes montar tú mismo para probarlo:

1. Ejecutado **con el entorno del curso activo** — debe reportar el `.venv`, su proyecto y su
   `pyvenv.cfg`.
2. Ejecutado **sin ningún entorno activo**, con el intérprete del sistema.
3. Ejecutado con el entorno activo pero **invocando explícitamente otro intérprete**
   (`/usr/bin/python3 diagnostico.py` con el `.venv` activo). Este es el caso sucio, es el que
   produce los errores más confusos de la vida real, y un diagnóstico que no lo detecta no
   sirve.
4. Ejecutado con **un intérprete viejo** — el `python3` del sistema, que en muchos macOS todavía
   es un 3.9. Es el escenario real del encargo: la máquina de Patricia es justamente la que no
   tiene 3.14, y una herramienta de diagnóstico que exige la versión que viene a diagnosticar no
   diagnostica nada.

**Criterios de aceptación**

- [ ] Corre con `python diagnostico.py` en las tres plataformas sin modificarse, y sin importar
      nada que no venga en la biblioteca estándar.
- [ ] **Corre también en un intérprete viejo** (3.9 en adelante) sin reventar al arrancar. Es el
      único código de todo el curso con ese requisito, y el encargo es la razón.
- [ ] Reporta, como mínimo: versión e implementación, ruta real del ejecutable, plataforma y
      arquitectura, si hay entorno virtual activo y cuál, los primeros tres directorios de
      `sys.path`, y todos los `python`/`python3` encontrados en el `PATH` con su versión.
- [ ] **Detecta y reporta explícitamente el escenario 3** con un mensaje en español que un no
      ingeniero entienda, del estilo *"estás ejecutando un Python distinto al del entorno
      activo"*.
- [ ] La salida cabe en una pantalla y se puede pegar en un chat sin que se deforme.
- [ ] Termina con código de salida `0` si no detectó nada raro y `1` si detectó alguna
      inconsistencia — porque dentro de tres fases esto lo va a invocar otro script.
- [ ] **Medición:** reporta cuánto tardó el diagnóstico completo, en milisegundos, medido con
      reloj monótono. Ese número es el que va en el mensaje del tag.

**Restricciones de registro**

> Esto es un **script**. Un archivo, biblioteca estándar pura, sin clases, sin capas, sin
> `Diagnostico`, `EnvironmentInspector` ni `ReportBuilder`. Funciones sueltas a nivel de módulo
> y el trabajo bajo `if __name__ == "__main__":`. Si te descubres escribiendo una jerarquía para
> "que quede extensible", ese es precisamente el reflejo que el Bloque A ataca — y nota que aún
> no hemos visto clases: la Fase 03 las introduce, y para entonces vas a tener otro criterio
> sobre cuándo valen la pena.

**La trampa**

Vas a resolver *"qué Python hay en el PATH"* buscando el ejecutable y preguntándole su versión.
Funciona. Y en Windows va a fallar de dos maneras distintas que no vas a anticipar: por los
*app execution aliases* de la Microsoft Store, que son archivos de cero bytes que se hacen pasar
por `python.exe` y abren la tienda cuando los ejecutas, y porque `.exe` no está solo — hay que
mirar `PATHEXT`. Tu diagnóstico tiene que sobrevivir a eso sin colgarse.

Y hay una segunda, más sutil: ejecutar cada candidato para preguntarle su versión significa
**lanzar procesos**, y si uno se cuelga, tu herramienta se cuelga con él en la máquina de
Patricia un viernes a las seis.

Y una tercera, que es la más irónica de las tres: vas a escribir el diagnóstico con la sintaxis
de 3.14 porque es la que tienes delante, y va a reventar **en el arranque** —antes de imprimir
una sola línea útil— en la máquina vieja que venía a diagnosticar. El mensaje que reciba
Patricia va a ser un `TypeError` sobre un operador `|`. Arreglarlo es una línea; encontrarla es
el ejercicio.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Divide el problema en dos mitades que no se parecen: lo que puedes saber **desde adentro** del
proceso que corre —quién soy, dónde estoy, qué tengo en `sys.path`— y lo que solo se sabe
**mirando afuera** —qué otros intérpretes hay—. La primera mitad es leer atributos; la segunda
es recorrer directorios y, con cuidado, ejecutar procesos.

El escenario 3 se detecta comparando dos cosas que normalmente coinciden y ahí no: quién te
está ejecutando, y qué dice el entorno que debería estar ejecutándote.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Todo está en la caja: [`sys`](https://docs.python.org/3.14/library/sys.html) para `executable`,
`version_info`, `path` y `prefix`/`base_prefix`;
[`platform`](https://docs.python.org/3.14/library/platform.html) para sistema y arquitectura;
[`os.environ`](https://docs.python.org/3.14/library/os.html#os.environ) para `PATH` y
`VIRTUAL_ENV`; [`shutil.which`](https://docs.python.org/3.14/library/shutil.html#shutil.which),
que ya resuelve `PATHEXT` por ti; y
[`subprocess.run`](https://docs.python.org/3.14/library/subprocess.html#subprocess.run), que
acepta un argumento que evita el cuelgue de la trampa.

`sys.prefix` frente a `sys.base_prefix` es la comparación que contesta *"¿estoy dentro de un
entorno virtual?"*, y está documentada exactamente así.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def current_interpreter() -> dict[str, str]:
    """Lo que se sabe desde adentro: quién me ejecuta y con qué configuración."""

def active_virtualenv() -> dict[str, str] | None:
    """El entorno activo según el propio proceso y según las variables de entorno."""

def interpreters_on_path() -> list[dict[str, str]]:
    """Todos los python/python3 alcanzables, con su versión. No se cuelga."""

def find_inconsistencies(current, venv, on_path) -> list[str]:
    """Los mensajes en español para Patricia. Lista vacía = todo en orden."""

def render(...) -> str:
    """Una pantalla, pegable en un chat."""
```
</details>

**Cómo se entrega**

Un archivo, `diagnostico.py`, en la raíz del repositorio del curso:

```bash
python diagnostico.py          # diagnóstico normal
python diagnostico.py ; echo $?   # y el código de salida (en PowerShell: $LASTEXITCODE)
```

```bash
git add diagnostico.py
git commit -m "fase 00 mini: diagnóstico de ambiente"
git tag -a mini-00 -m "Mini F0: diagnóstico de ambiente · <tu número> ms, N intérpretes hallados"
```

<details><summary>💡 Solución de referencia — ábrela después de intentarlo</summary>

```python
"""Diagnóstico del ambiente de Python de una máquina.

Uso:  python diagnostico.py
Sale con 0 si no encontró inconsistencias, con 1 si encontró alguna.
"""

# Esta línea es la que permite que el diagnóstico corra en el Python viejo de la máquina
# ajena: sin ella, una anotación como `dict[str, str] | None` se evalúa al importar el
# módulo y revienta en cualquier intérprete anterior a 3.10. Con ella, las anotaciones
# quedan como texto y nadie las mira en tiempo de ejecución.
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Nombres que vale la pena buscar en el PATH. shutil.which se encarga de .exe y PATHEXT.
CANDIDATE_NAMES = ["python", "python3", "python3.14", "python3.13", "py"]


def current_interpreter() -> dict[str, str]:
    """Lo que el proceso sabe de sí mismo. Nada de esto puede fallar ni tardar."""
    return {
        "versión": sys.version.split()[0],
        "implementación": sys.implementation.name,
        "ejecutable": sys.executable or "(desconocido)",
        "plataforma": f"{sys.platform} · {os.uname().machine if hasattr(os, 'uname') else os.environ.get('PROCESSOR_ARCHITECTURE', '?')}",
        "prefijo": sys.prefix,
        "prefijo base": sys.base_prefix,
    }


def active_virtualenv() -> dict[str, str] | None:
    """Devuelve el entorno virtual activo, o None si se está corriendo en el intérprete base.

    La comprobación canónica es prefix != base_prefix: dentro de un entorno virtual, prefix
    apunta al .venv y base_prefix al intérprete del que salió.
    """
    if sys.prefix == sys.base_prefix:
        return None

    venv_dir = Path(sys.prefix)
    info = {"ruta": str(venv_dir), "proyecto": venv_dir.parent.name}

    # pyvenv.cfg es texto plano y responde de qué intérprete salió este entorno.
    config = venv_dir / "pyvenv.cfg"
    if config.exists():
        for line in config.read_text(encoding="utf-8").splitlines():
            if line.startswith(("home", "version")):
                key, _, value = line.partition("=")
                info[key.strip()] = value.strip()
    return info


def interpreters_on_path() -> list[dict[str, str]]:
    """Todos los intérpretes alcanzables desde el PATH, con su versión.

    Cada candidato se ejecuta en un proceso aparte, con timeout: un alias de la Microsoft
    Store o un binario roto no pueden colgar el diagnóstico en la máquina de otra persona.
    """
    found: list[dict[str, str]] = []
    seen: set[str] = set()

    for name in CANDIDATE_NAMES:
        path = shutil.which(name)
        if path is None or path in seen:
            continue
        seen.add(path)

        # Los alias de ejecución de Windows son archivos de cero bytes que abren la tienda.
        try:
            if os.path.getsize(path) == 0:
                found.append({"nombre": name, "ruta": path, "versión": "alias de la Microsoft Store (ignóralo)"})
                continue
        except OSError:
            pass

        try:
            result = subprocess.run(
                [path, "-c", "import sys; print(sys.version.split()[0])"],
                capture_output=True,
                text=True,
                timeout=5,  # la trampa: sin esto, un binario colgado cuelga la herramienta
            )
            version = result.stdout.strip() or f"no respondió (código {result.returncode})"
        except subprocess.TimeoutExpired:
            version = "no respondió en 5 s"
        except OSError as error:
            version = f"no se pudo ejecutar: {error}"

        found.append({"nombre": name, "ruta": path, "versión": version})

    return found


def find_inconsistencies(
    current: dict[str, str],
    venv: dict[str, str] | None,
    on_path: list[dict[str, str]],
) -> list[str]:
    """Los avisos, en español y dirigidos a alguien que no es ingeniero."""
    warnings: list[str] = []

    declared = os.environ.get("VIRTUAL_ENV")
    if declared and venv is None:
        warnings.append(
            "Tienes un entorno virtual activado, pero este programa lo está ejecutando OTRO "
            f"Python, el de {current['ejecutable']}. Lo que instalaste en el entorno no se ve "
            "desde aquí: por eso falla lo del módulo que no encuentra."
        )
    elif declared and venv and Path(declared).resolve() != Path(venv["ruta"]).resolve():
        warnings.append(
            f"El entorno activado ({declared}) no es el mismo que está en uso ({venv['ruta']})."
        )

    if venv is None:
        warnings.append(
            "No hay ningún entorno virtual activo: se está usando el Python del sistema. "
            "Para el curso, activa el entorno del proyecto antes de ejecutar nada."
        )

    if not any(item["versión"].startswith("3.14") for item in on_path):
        warnings.append("No se encontró ningún Python 3.14 en el PATH de esta máquina.")

    return warnings


def render(current, venv, on_path, warnings, elapsed_ms: float) -> str:
    """Una pantalla, pegable en un chat sin que se deforme."""
    lines = ["=== Diagnóstico de Python ===", ""]
    lines += [f"{key:>14}: {value}" for key, value in current.items()]

    lines += ["", "Entorno virtual:"]
    if venv is None:
        lines.append("    ninguno activo (Python del sistema)")
    else:
        lines += [f"    proyecto: {venv['proyecto']}", f"    ruta:     {venv['ruta']}"]

    lines += ["", "Intérpretes en el PATH:"]
    lines += [f"    {item['nombre']:<12} {item['versión']:<12} {item['ruta']}" for item in on_path]

    lines += ["", "Primeros directorios de búsqueda de módulos:"]
    lines += [f"    {entry or '(directorio actual)'}" for entry in sys.path[:3]]

    lines += ["", "Avisos:"]
    lines += [f"    ⚠️  {w}" for w in warnings] if warnings else ["    ninguno: todo en orden."]

    lines += ["", f"(diagnóstico completado en {elapsed_ms:.1f} ms)"]
    return "\n".join(lines)


if __name__ == "__main__":
    started = time.perf_counter()

    current = current_interpreter()
    venv = active_virtualenv()
    on_path = interpreters_on_path()
    warnings = find_inconsistencies(current, venv, on_path)

    elapsed_ms = (time.perf_counter() - started) * 1000
    print(render(current, venv, on_path, warnings, elapsed_ms))

    # Código de salida con significado: dentro de tres fases, otro script va a invocar esto.
    sys.exit(1 if warnings else 0)
```

**La decisión de diseño que se tomó.** Detectar el entorno virtual con
`sys.prefix != sys.base_prefix` en vez de con `VIRTUAL_ENV`. El otro camino es defendible y más
obvio —la variable existe justo para eso—, pero solo la escribe el activador: si alguien ejecuta
`.venv/bin/python` sin activar, `VIRTUAL_ENV` no existe y el diagnóstico mentiría diciendo que
no hay entorno. Usar las dos fuentes y **comparar** es lo que permite detectar el escenario 3,
que era el encargo real.

**La trampa, entera.** Sin `timeout=5`, `subprocess.run` espera indefinidamente. En una máquina
con Windows y un alias de la Microsoft Store, el proceso hijo se queda esperando una interacción
que nadie va a dar, y tu herramienta queda colgada sin mensaje. El comprobante de tamaño cero
evita la mayoría de esos casos; el timeout cubre el resto, incluidos montajes de red lentos y
antivirus que inspeccionan cada proceso nuevo. Es la primera aparición de una idea que la Fase
05 convierte en tema: **lanzar un proceso hijo es delegar el control, y siempre hay que poder
recuperarlo.**

Y la tercera trampa se paga con `from __future__ import annotations` en la primera línea. Sin
ella, el archivo no llega a ejecutarse en un intérprete anterior a 3.10: las anotaciones de las
firmas se evalúan al importar el módulo, `dict[str, str] | None` no existe allí, y el usuario
recibe un `TypeError` en vez de un diagnóstico. Probado: con esa línea, el mismo archivo corre
en 3.9 y detecta correctamente el escenario 3. Es el único sitio del curso donde se escribe
código defensivo para atrás, y se justifica porque la herramienta existe para correr en la
máquina que no controlas.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— esto
tendría `pyproject.toml`, un *entry point* llamado `aur-doctor`, tipos verificados y pruebas con
un `PATH` falso; y la salida sería JSON además de texto, para que otro programa la consuma. Como
aplicación no tendría sentido: un diagnóstico que hay que desplegar para poder correrlo no
diagnostica nada.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Averigua cuántos intérpretes de Python hay en tu máquina y de dónde salió cada uno. En
   Windows usa `py -0`; en Linux y macOS, `which -a python3` y `which -a python`. Escribe la
   lista en un archivo `entorno.md` del repositorio, con una línea por intérprete diciendo quién
   lo instaló.
2. Crea un entorno virtual en un directorio temporal, imprime su `pyvenv.cfg` y explica en dos
   frases qué dice cada línea. Bórralo después.
3. Sin activar ningún entorno, ejecuta `hello.py` con el intérprete del `.venv` llamándolo por
   su ruta completa. Explica por qué funciona.
4. Instala `ruff` en dos entornos distintos con versiones diferentes (`0.16.7` y la última) y
   demuestra con `sys.executable` y `ruff --version` que no se pisan.
5. Rompe el formato de `hello.py` a propósito —espacios raros, imports desordenados, líneas de
   130 caracteres— y arréglalo con `ruff format` y `ruff check --fix`. Mira el `git diff` y
   anota qué hizo cada uno de los dos comandos.
6. Configura tu editor para que formatee al guardar y demuéstralo: escribe una línea mal
   formateada, guarda, y verifica que cambió sin que corrieras nada en la terminal.

**🟡 Intermedio (7–14)**

7. `python -c "import sys; print(sys.path)"` dentro y fuera del entorno virtual. Explica qué
   entradas cambian y cuáles no. Después repite con un archivo (`python ver_path.py`) y explica
   por qué la primera entrada es distinta en los dos casos.
8. Consulta la documentación de `venv` y averigua qué hacen `--system-site-packages` y
   `--upgrade-deps`. Crea un entorno con cada uno y demuestra con un comando qué cambió.
9. Instala una biblioteca con dependencias transitivas (por ejemplo `rich`), corre `pip freeze`
   y explica cuál de esas líneas pediste tú y cuál vino arrastrada. Ahora responde: con solo ese
   archivo, ¿cómo sabrías cuál es cuál dentro de un año? Esa es la queja de la Fase 07.
10. Averigua qué hace `pip install -e .` y por qué no lo puedes usar todavía. Una frase por
    razón.
11. Configura `ruff` para que además avise sobre argumentos por defecto mutables y comprobaciones
    con `== None`. Encuentra la regla en la documentación y déjala en `ruff.toml` con un
    comentario que diga qué atrapa.
12. Escribe una configuración de depuración en `launch.json` que ejecute `hello.py` con dos
    argumentos y una variable de entorno definida, y demuestra desde el depurador que el script
    los recibe.
13. Compara el tamaño en disco de tu `.venv` recién creado contra el de `~/.m2` de tu máquina de
    trabajo. Explica en tres frases por qué la comparación es injusta y qué se compara de verdad.
14. Ejecuta `python -X importtime -c "import json, csv, argparse"` y lee la salida. ¿Cuál de los
    tres cuesta más y por qué? Relaciona el resultado con la medición de la sección 6.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Alguien te reporta que `pip install requests` funcionó pero
    `import requests` falla con `ModuleNotFoundError`. Reproduce el escenario a propósito en tu
    máquina, en al menos dos formas distintas de provocarlo, y escribe para cada una el comando
    exacto que lo diagnostica en un paso.
16. **Diagnóstico.** Un compañero dice que su editor no autocompleta nada de lo que instala. Lista
    las tres causas más probables en orden de frecuencia, y para cada una el comando o la pantalla
    que la confirma o la descarta.
17. **Medición.** Mide cuánto tarda `python -c "pass"` contra `python -S -c "pass"` en tu máquina,
    con al menos 20 repeticiones, y reporta mediana y p95. Averigua en la documentación qué hace
    `-S` y explica a qué se debe la diferencia.
18. **Medición.** Cronometra crear un entorno virtual con `python -m venv` contra crearlo con
    `--without-pip`. Explica la diferencia y en qué escenario real —piensa en un contenedor o en
    un CI— esa diferencia deja de ser anecdótica.
19. Escribe un script de stdlib pura que, dado un directorio, encuentre todos los entornos
    virtuales que haya debajo, reporte el tamaño de cada uno y la fecha del último uso. Ejecútalo
    contra tu carpeta de proyectos y mira cuántos gigabytes tienes en entornos muertos.
20. **De registro.** Julián te pide "algo que avise cuando una sede no mandó su archivo del mes".
    Decide si eso es un script, una herramienta o una aplicación. Justifica con el costo de las
    otras dos opciones, en términos de quién lo ejecuta, quién lo mantiene y qué pasa cuando
    falle un domingo. Media página, y guárdala: en la Fase 15 la vas a releer.
21. **De registro.** Tu diagnóstico de ambiente del miniproyecto lo empiezan a usar tres personas
    y Julián pide "que salga también en un Excel". Enumera qué tendría que cambiar para que
    dejara de ser un script, y decide si ese pedido lo justifica. La respuesta correcta puede ser
    que no.

**🔴 Muy difícil (22–25)**

22. **Medición, tu plataforma.** Reproduce la medición de la sección 6 en tu máquina, con tus
    versiones, incluyendo el caso de Java con y sin las banderas de arranque. Publica tus cinco
    filas declarando el entorno completo. Si tu resultado contradice el veredicto, escribe por
    qué crees que pasa: el curso publica lo que salió, y este es el primer sitio donde te toca
    hacer lo mismo.
23. **Adversarial.** Construye deliberadamente el entorno más confuso que puedas —un `.venv`
    creado desde otro `.venv`, un `PATH` con tres Python en desorden, un `VIRTUAL_ENV` apuntando
    a un directorio que ya borraste— y comprueba si tu `diagnostico.py` del miniproyecto lo
    reporta con claridad. Arregla lo que no cubra.
24. **Defiende una decisión.** El equipo de sistemas de una empresa donde trabajaste prohibía los
    entornos virtuales e instalaba todo en el Python del sistema "para que todos tengan lo
    mismo". Escribe el argumento a favor de esa política —existe, y es más fuerte de lo que
    parece— y después el argumento en contra con los datos de esta fase. Cierra diciendo qué
    harías tú y a partir de qué tamaño de equipo cambia tu respuesta.
25. **Adversarial.** Averigua qué es un *typosquat* en PyPI y por qué la tabla de §4 dice que no
    hay *namespace* por organización. Escribe el procedimiento de tres pasos que vas a seguir
    —tú, que eres el único ingeniero de Áurea— antes de instalar cualquier paquete que no
    conozcas. Guárdalo en `entorno.md`: la Fase 16 vuelve sobre esto con la cadena de suministro.

**🔥 Opcionales**

- Averigua qué son `pyenv` y `mise`, instala uno, y ten dos versiones de Python conviviendo.
  Decide si te sirve o si te sobra, sabiendo que el curso fija una sola versión.
- Lee la salida completa de `python -X importtime` para un script que importe `json`, `csv`,
  `sqlite3` y `subprocess` a la vez, y dibuja el árbol de qué importa a qué.
- Compara la extensión Python de VS Code con la de PyCharm en una tarea concreta: renombrar una
  función usada en tres archivos. Cronométralo. No hay respuesta correcta, pero el resultado te
  va a sorprender en una dirección.

---

## 📚 9. Referencias

**Documentación oficial**

- [`venv` — Creación de entornos virtuales](https://docs.python.org/3.14/library/venv.html) — la
  página que explica qué es un entorno y qué contiene `pyvenv.cfg`. Fija 3.14 en el selector de
  versión, arriba a la izquierda: por defecto sirve la estable del día.
- [`sys` — Parámetros y funciones del sistema](https://docs.python.org/3.14/library/sys.html) —
  `executable`, `prefix`, `base_prefix`, `path`, `implementation`.
- [`shutil.which`](https://docs.python.org/3.14/library/shutil.html#shutil.which) — la búsqueda
  en el `PATH` bien hecha, con `PATHEXT` incluido.
- [Usar Python en Windows](https://docs.python.org/3.14/using/windows.html) — el lanzador `py`,
  los alias de ejecución de la Microsoft Store, y las rutas de instalación.
- [Guía de usuario de `pip`](https://pip.pypa.io/en/stable/user_guide/) — en particular la
  sección de *requirements files*, que es donde se ve mejor lo que `pip freeze` no es.
- [Documentación de `ruff`](https://docs.astral.sh/ruff/) — reglas, configuración y el
  equivalente de cada regla de `flake8`.
- [Python en VS Code](https://code.visualstudio.com/docs/python/python-tutorial) — selector de
  intérprete, depuración y pruebas.
- [Unified PyCharm](https://www.jetbrains.com/help/pycharm/unified-pycharm.html) — qué cambió al
  fusionarse las ediciones, y qué queda en la capa gratuita.

**PEPs** (cuando explican el porqué de una decisión, no como adorno)

- [PEP 405 — Entornos virtuales](https://peps.python.org/pep-0405/) — el diseño original: por qué
  un directorio con un `pyvenv.cfg` y no un mecanismo del intérprete.
- [PEP 668 — Marcar los entornos gestionados externamente](https://peps.python.org/pep-0668/) —
  la razón del `externally-managed-environment` de Linux.
- [PEP 518](https://peps.python.org/pep-0518/) y [PEP 621](https://peps.python.org/pep-0621/) —
  de dónde salió `pyproject.toml` y qué vino a reemplazar. Los vas a necesitar en la Fase 07.

**Video y apoyo**

- Los *release highlights* de la versión 3.14 en el blog de python.org, para ver qué trajo la
  versión que fijamos. Los títulos y las URL cambian; verifícalos antes de citarlos.

**Orden de lectura sugerido.** Antes de escribir código: la página de `venv` completa —son diez
minutos y responden el 80% de esta fase—. Durante: `sys` y `shutil.which`, consultados a medida
que el miniproyecto los pida. Después: el PEP 405, que se entiende mucho mejor cuando ya
inspeccionaste un `pyvenv.cfg` con tus propias manos.

> ⚠️ Las URL, los títulos y los contenidos cambian. Verifica antes de citar, y no des por buena
> ninguna versión que no hayas visto en el selector de la propia página.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Tienes un taller: un intérprete que sabes cuál es, un entorno que entiendes por dentro, un
editor que depura, un linter que corre al guardar y un repositorio con su primer commit. Y algo
menos visible pero más importante: tienes **el hábito de preguntar cuál intérprete**, que es el
que va a resolver solo la mayoría de los incidentes de tus próximas semanas.

También te llevas dos agravios anotados y sin resolver —`pip freeze` no es un lockfile, `pip` no
te da un intérprete— que vas a arrastrar durante seis fases. No se te olviden: la Fase 07 los
cobra, y la lección de esa fase no funciona si llegas sin haberlos sentido.

La **Fase 01** empieza a escribir código, y empieza por donde este perfil arrastra los errores
más silenciosos: el modelo de datos. Qué es un valor, qué es una referencia, quién es mutable y
qué significa que dos cosas sean "iguales". Ahí nace el CLI de Patricia como un archivo de
cuarenta líneas —y nace deliberadamente mal, con una deuda 💸 declarada que se paga en la Fase
06—.

> **La señal de que quedó bien:** cuando algo falle, tu primera reacción no va a ser buscar el
> error en internet — va a ser preguntar *"¿cuál Python está corriendo esto?"*, y en el 80% de
> los casos vas a tener razón.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-00 -m "F0 cerrada:
> - Python 3.14.7 instalado sin tocar el intérprete del sistema
> - entorno virtual creado, activado e inspeccionado por dentro
> - ruff corriendo en terminal y al guardar en el editor
> - editor depurando con puntos de quiebre contra el intérprete del .venv
> - repositorio creado con su .gitignore y su primer commit
> - diagnostico.py corriendo y detectando el intérprete equivocado"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 00: …`), los de ejercicio su número
> (`fase 00 ej12: …`) y el miniproyecto el suyo (`fase 00 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-00`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
