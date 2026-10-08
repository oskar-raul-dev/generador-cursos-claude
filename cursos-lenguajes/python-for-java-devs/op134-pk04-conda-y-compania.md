# 🐍 pk04 — conda, mamba y Miniforge

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 4 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El análisis geográfico de Áurea —qué pacientes viven a menos de cinco kilómetros de cada sede (`gi`)— necesita GDAL, una biblioteca en C++ con decenas de
dependencias del sistema. `pip install gdal` en una máquina limpia falla al compilar, porque PyPI distribuye paquetes de Python, y GDAL es, sobre todo, una
biblioteca que no es de Python. Es **el problema binario**, y es la razón de existir de **conda**.

conda es un gestor de paquetes **de cualquier lenguaje**: instala Python, pero también GDAL, CUDA, compiladores de Fortran y R, cada uno con sus bibliotecas
compiladas para la plataforma. El camino base midió que para el stack de una API conda no hace falta (`BENCHMARKS.md` §07: 43 s y 211 MB contra 0,4 s y 27 MB de
`uv`). Esta sección muestra el caso donde sí hace falta, y ordena la confusión de nombres: **conda** (el gestor), **mamba** (su resolvedor rápido, hoy integrado),
**Anaconda** (una distribución comercial) y **Miniforge** (la distribución mínima que usa solo el canal comunitario `conda-forge`).

---

## 🧠 2. El modelo

| Nombre | Qué es | Para qué |
|---|---|---|
| **conda** | El gestor: entornos y paquetes de cualquier lenguaje | Lo que se ejecuta |
| **mamba / libmamba** | Un resolvedor de dependencias en C++; desde 2023 es el resolvedor por defecto de conda | Que resolver no tarde minutos |
| **conda-forge** | El canal comunitario: miles de paquetes compilados para cada plataforma | De dónde vienen los paquetes |
| **Miniforge** | Distribución mínima: conda + mamba + `conda-forge` como único canal | **La forma recomendada de instalar conda** |
| **Anaconda** | Distribución comercial con el canal `defaults`, con términos de uso comercial | Empresas con licencia |

| | `pip` / `uv` (PyPI) | conda (`conda-forge`) |
|---|---|---|
| Paquetes de Python puros | Sí | Sí |
| Ruedas con código compilado | Sí, si el autor las publica | Sí |
| **Bibliotecas que no son de Python** (GDAL, CUDA, `libpq`) | **No** | **Sí** |
| Instala el intérprete | `uv` sí | Sí |
| Velocidad y tamaño | Rápido, liviano | Más lento, más pesado (medido en el camino base) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, las dependencias nativas son raras: casi todo es *bytecode*, y cuando no, viene dentro del *jar*. El instinto supone que un paquete de PyPI "trae todo".
Muchos sí (ruedas compiladas), pero los que envuelven bibliotecas grandes de C o C++ a veces solo publican el código fuente y esperan que la biblioteca ya esté en
el sistema. conda resuelve exactamente eso, y por eso domina en ciencia de datos y geografía.

---

## 💻 3. El ejemplo que corre

`binario.sh`, primero en la imagen de Python, después en la de Miniforge:

```bash
#!/bin/sh
# 1) pip contra GDAL en una máquina limpia
if command -v pip >/dev/null && ! command -v conda >/dev/null; then
  pip install --no-cache-dir gdal 2>&1 | grep -m1 "gdal-config" || echo "pip: instaló"
fi
# 2) conda (Miniforge) con GDAL desde conda-forge
if command -v conda >/dev/null; then
  conda --version
  start=$(date +%s)
  conda create --quiet --yes --name geo python=3.13 gdal >/dev/null
  echo "conda create con gdal: $(( $(date +%s) - start )) s"
  conda run --name geo python -c "from osgeo import gdal; print('GDAL', gdal.__version__)"
  echo "tamaño del entorno: $(du -sh /opt/conda/envs/geo | cut -f1)"
  echo "paquetes en el entorno: $(conda list --name geo | grep -vc '^#')"
fi
```

```bash
docker run --rm -v "$PWD:/w" python:3.14.7 sh /w/binario.sh
docker run --rm -v "$PWD:/w" condaforge/miniforge3:26.7.2-0 sh /w/binario.sh
```

Salida (Python 3.14.7 y Miniforge 26.7.2-0, 05/10/2026):

```text
      FileNotFoundError: [Errno 2] No such file or directory: 'gdal-config'
conda 26.7.2
conda create con gdal: 23 s
GDAL 3.13.3
tamaño del entorno: 517M
paquetes en el entorno: 81
```

En la imagen de Python, `pip` no llegó ni a compilar: el instalador de GDAL busca `gdal-config`, que viene con las bibliotecas de desarrollo del sistema, y no
está. En Miniforge, `conda` creó el entorno en 23 segundos con GDAL 3.13.3 funcionando —el `import` de `osgeo` lo confirma— y el costo que se paga por eso:
**81 paquetes y 517 MB**, porque cada biblioteca de C que GDAL necesita viene adentro, compilada. Es el problema binario resuelto a la manera de conda: traer
todo, para no depender de nada del sistema.

**Detalles con intención**

- **`pip install gdal`** descarga el código fuente y necesita `gdal-config` (de las bibliotecas de desarrollo de GDAL del sistema) para compilar. Sin ellas, falla
  antes de empezar.
- **`conda create ... gdal`** instala GDAL, sus decenas de bibliotecas de C (PROJ, GEOS, libtiff, sqlite…) y los enlaces de Python, compilados para la plataforma.
  Nada de eso pasa por el sistema operativo.
- **`python=3.13`** y no 3.14: conda-forge necesita tiempo para compilar todo el ecosistema para cada versión nueva de Python, y GDAL puede no estar todavía para la
  más reciente. Es otra cara del problema binario.
- **`conda run`** ejecuta dentro del entorno sin activarlo, como el `python` del entorno en `pk01`.

---

## ⚠️ 4. Lo que se rompe

**Mezclar `pip` y conda en el mismo entorno.** `pip install` dentro de un entorno de conda instala por encima de lo que conda maneja, y conda no se entera: la próxima
actualización puede romper el entorno. Si hace falta un paquete que solo está en PyPI, se instala con `pip` **al final**, y se recrea el entorno desde cero cuando
cambia algo.

**El canal `defaults` sin leer los términos.** La distribución Anaconda y su canal `defaults` tienen términos de uso comercial que pueden exigir licencia según el
tamaño de la organización. Miniforge usa solo `conda-forge` y evita la pregunta; en una empresa, se decide y se escribe qué canal se usa.

**Entornos de conda sin *lock*.** `environment.yml` con versiones sueltas tiene el mismo problema que un `requirements.txt` sin compilar (`pk02`). `conda-lock` genera
el *lock* por plataforma.

**conda para todo.** Usar conda en un proyecto que solo tiene dependencias de PyPI paga cuarenta segundos y doscientos megas por nada (`BENCHMARKS.md` §07).

---

## ⚖️ 5. Cuándo NO usarlo

**Para el stack de una API web.** FastAPI, SQLAlchemy, `httpx`: todo tiene ruedas en PyPI. `uv`.

**En un contenedor donde el sistema operativo da la biblioteca.** `apt-get install libgdal-dev` y `pip install gdal==<la versión del sistema>` también funciona, con la
versión de GDAL que trae la distribución.

**Si nadie en la casa conoce conda.** Es otra herramienta, con su propio modelo de canales, entornos y resolución.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo en las dos imágenes. **Criterio:** el error de `pip` y lo que instaló conda.
2. Lista los canales configurados en Miniforge (`conda config --show channels`). **Criterio:** solo `conda-forge`.
3. Exporta el entorno con `conda env export --name geo`. **Criterio:** encuentras GDAL y PROJ con sus versiones.

**🟡 Intermedio (4–6)**

4. Instala GDAL con `apt-get` y `pip` en la imagen de Python (la versión del sistema). **Criterio:** funciona, y comparas la versión con la de conda.
5. Genera un *lock* con `conda-lock` para Linux y macOS. **Criterio:** el archivo y cuántos paquetes fija por plataforma.
6. Instala con `pip` un paquete que no está en conda-forge dentro del entorno, al final. **Criterio:** funciona, y explicas qué pasaría si después actualizas con conda.

**🟠 Difícil (7–9)**

7. Haz un `Dockerfile` con Miniforge y GDAL, con el entorno creado desde un *lock*. **Criterio:** el tamaño de la imagen.
8. Usa `pixi` (el gestor de proyectos sobre conda-forge) para el mismo entorno. **Criterio:** qué cambia en la experiencia frente a `conda`.
9. Intenta crear el entorno con `python=3.14` y GDAL. **Criterio:** si conda-forge ya lo tiene, y qué versión de Python elige si no.

**🔴 Muy difícil (10)**

10. Decide cómo se instala el análisis geográfico de Áurea. **Criterio:** una página. *Rúbrica:* (a) conda, `apt` + `pip`, o un contenedor oficial de GDAL; (b) la versión de
    GDAL y de Python de cada opción; (c) cómo se fija el entorno; (d) qué pasa con el resto del proyecto, que usa `uv`.

---

## 📚 7. Referencias

**Documentación oficial**

- Miniforge: https://github.com/conda-forge/miniforge
- conda-forge: https://conda-forge.org/docs/
- `conda-lock`: https://conda.github.io/conda-lock/

**Orden de lectura sugerido:** el README de Miniforge (qué es y por qué existe); después la documentación de conda-forge sobre cómo se publican los paquetes.

---

## 🚀 8. Cierre

conda resuelve el problema binario: instala bibliotecas que no son de Python, compiladas para la plataforma, junto con el intérprete. Miniforge es la forma de instalarlo
con el canal comunitario y sin preguntas de licencia. Para un stack que vive en PyPI, `uv` es más liviano y más rápido; para GDAL, CUDA o compiladores, conda gana.

**La señal de que quedó bien:** *"El análisis geográfico instala GDAL desde un lock de conda, y el resto del proyecto sigue con `uv`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-04 -m "op pk04 cerrada: el problema binario y conda-forge con Miniforge"
> ```
>
> Los commits llevan su prefijo (`op pk04: …`) y los de ejercicio su número
> (`op pk04 ej07: …`).
