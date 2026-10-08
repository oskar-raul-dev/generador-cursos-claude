# 📦 pk01 — El modelo real de un entorno

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 1 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El camino base eligió **un** gestor, `uv`, con números (`BENCHMARKS.md` §07), y siguió adelante. Este track es el mapa del terreno que el camino base
atravesó sin mirar a los lados: `pip` con `venv`, conda, Poetry, PDM, el empaquetado y la entrega. Antes de comparar herramientas hace falta saber qué
está resolviendo cada una, y para eso hay que mirar qué **es** un entorno de Python por dentro.

Este perfil viene de Maven y Gradle, donde no hay "entornos": el *classpath* se arma en cada ejecución desde un repositorio local compartido. En Python
cada proyecto tiene su propia carpeta con sus propias copias de los paquetes, y los gestores se diferencian en cómo la arman. La sección abre esa
carpeta, y muestra que la mitad del misterio —"activar el entorno"— es una variable de entorno.

---

## 🧠 2. El modelo

| Pieza | Qué es | Dónde se ve |
|---|---|---|
| Intérprete base | El Python instalado en el sistema | `sys.base_prefix` |
| Entorno virtual | Una carpeta con un enlace al intérprete y su propio `site-packages` | `sys.prefix`, `pyvenv.cfg` |
| `site-packages` | Donde se instalan los paquetes del entorno | `site.getsitepackages()` |
| `sys.path` | La lista de lugares donde Python busca un `import`, en orden | `python -c "import sys; print(sys.path)"` |
| "Activar" | Poner `venv/bin` primero en el `PATH` de la terminal | `echo $PATH` |

Y lo que resuelve un gestor, de lo más básico a lo más ambicioso:

| Lo que resuelve | `venv` + `pip` | `pip-tools` | `uv`, Poetry, PDM | conda |
|---|---|---|---|---|
| Aislar los paquetes del proyecto | Sí | Sí | Sí | Sí |
| Resolver versiones compatibles | Al instalar | **Y fijarlas** en un archivo | Y fijarlas en un *lock* | Y fijarlas |
| Instalar el intérprete | No | No | `uv` sí; Poetry y PDM no | **Sí** |
| Paquetes que no son de Python (compiladores, CUDA, GDAL) | No | No | No | **Sí** |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto busca el equivalente al `~/.m2`: un repositorio compartido del que cada proyecto toma lo que necesita. En Python, cada entorno tiene **sus propias
copias** instaladas; el caché de descargas se comparte (y `uv` comparte además los archivos con enlaces), pero lo que importa el intérprete vive en la carpeta
del entorno. Borrar el entorno y recrearlo es una operación normal, no un desastre.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `entorno.py`:

```python
"""Abrir un entorno virtual: qué hay adentro, qué hace 'activar', y cuánto cuesta crearlo."""

import os
import pathlib
import shutil
import subprocess
import sys
import time

ENV = pathlib.Path("demo-venv")
shutil.rmtree(ENV, ignore_errors=True)

for with_pip in (False, True):
    shutil.rmtree(ENV, ignore_errors=True)
    start = time.perf_counter()
    cmd = [sys.executable, "-m", "venv", str(ENV)] + ([] if with_pip else ["--without-pip"])
    subprocess.run(cmd, check=True)
    print(f"crear el entorno {'con' if with_pip else 'sin'} pip: {time.perf_counter() - start:.2f} s")

print("pyvenv.cfg:", (ENV / "pyvenv.cfg").read_text().strip().splitlines())
print("bin/python es un enlace a:", os.readlink(ENV / "bin" / "python"))

probe = "import sys, site; print(sys.prefix != sys.base_prefix, site.getsitepackages()[0])"
inside = subprocess.run([ENV / "bin" / "python", "-c", probe], capture_output=True, text=True).stdout.split()
print("python del entorno, sin 'activar': ¿en un entorno?", inside[0], "· site-packages:", inside[1])

# 'Activar' es esto: el PATH con el bin del entorno primero.
env_path = {**os.environ, "PATH": f"{ENV.resolve() / 'bin'}:{os.environ['PATH']}"}
which = subprocess.run(["sh", "-c", "command -v python"], env=env_path, capture_output=True, text=True).stdout.strip()
print("con el PATH 'activado', 'python' es:", which)

size = sum(f.stat().st_size for f in ENV.rglob("*") if f.is_file() and not f.is_symlink()) / 1e6
print(f"tamaño del entorno con pip: {size:.1f} MB")
```

```bash
python3 entorno.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
crear el entorno sin pip: 0.14 s
crear el entorno con pip: 1.93 s
pyvenv.cfg: ['home = /usr/local/bin', 'include-system-site-packages = false', 'version = 3.14.7', 'executable = /usr/local/bin/python3.14', 'command = /usr/local/bin/python -m venv /tmp/t/demo-venv']
bin/python es un enlace a: /usr/local/bin/python
python del entorno, sin 'activar': ¿en un entorno? True · site-packages: /tmp/t/demo-venv/lib/python3.14/site-packages
con el PATH 'activado', 'python' es: /tmp/t/demo-venv/bin/python
tamaño del entorno con pip: 11.5 MB
```

Crear la carpeta del entorno toma 0,14 s; instalarle `pip` adentro, casi dos segundos más, y la mayor parte de sus 11,5 MB. El `pyvenv.cfg` dice dónde
está el Python base y con qué comando se creó; `bin/python` es un enlace a ese Python. Llamado directamente, sin activar nada, ya sabe que está en un entorno.
Y "activar" resultó ser lo que se esperaba: con el `bin` del entorno primero en el `PATH`, la palabra `python` encuentra el del entorno.

**Detalles con intención**

- **`pyvenv.cfg`** es lo que convierte una carpeta en un entorno: le dice al intérprete dónde está el Python base (`home`) y si puede ver los paquetes del
  sistema. Sin ese archivo, `bin/python` sería el Python del sistema con otro nombre.
- **El `python` del entorno funciona sin activar**: `demo-venv/bin/python script.py` usa el entorno. En un cron, en systemd o en un `Dockerfile`, se llama así,
  sin `source activate`.
- **"Activar" solo cambia el `PATH`** (y el *prompt*). Por eso un script de shell que hace `source venv/bin/activate` y después llama a otro script con un
  `#!/usr/bin/python` explícito no usa el entorno.
- **Crear un entorno sin pip** es casi instantáneo; lo que tarda es instalar pip adentro. Es una de las razones por las que `uv` crea entornos mucho más rápido
  (`pk03`).

---

## ⚠️ 4. Lo que se rompe

**Mover o renombrar la carpeta del entorno.** Los *scripts* de `bin/` tienen la ruta absoluta del intérprete en su primera línea (`#!`). Un entorno movido de
carpeta tiene `pip` y los comandos rotos. Los entornos no se mueven: se recrean.

**Copiar el entorno a otra máquina.** El enlace apunta al Python de la máquina original, y los paquetes compilados son para su sistema y su arquitectura.
Lo que viaja es la lista de dependencias fijadas, no la carpeta.

**`pip install` sin entorno.** Instala en el Python del sistema, que en Debian y Ubuntu modernos está protegido (PEP 668) y falla con `externally-managed-environment`.
La respuesta es un entorno, no `--break-system-packages`.

**Dos Python en el `PATH`.** `python` y `pip` pueden ser de intérpretes distintos. `python -m pip` siempre usa el `pip` del `python` que se llamó.

---

## ⚖️ 5. Cuándo NO usar un entorno virtual

**Dentro de un contenedor de un solo propósito.** El contenedor ya aísla; un entorno adentro es una capa más. Muchos equipos igual lo usan, para que el
`Dockerfile` y la máquina del desarrollador funcionen igual; es una decisión, no una obligación.

**Para un script sin dependencias.** La biblioteca estándar no necesita entorno.

**Para herramientas de línea de comandos.** Las herramientas (`ruff`, `httpie`) se instalan cada una en su entorno con `uv tool` o `pipx` (`pk07`), no en el
entorno del proyecto.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas cada línea de `pyvenv.cfg`.
2. Abre `demo-venv/bin/pip` con un editor. **Criterio:** encuentras la ruta absoluta del intérprete en la primera línea.
3. Imprime `sys.path` desde el entorno y desde el sistema. **Criterio:** señalas la diferencia.

**🟡 Intermedio (4–6)**

4. Mueve `demo-venv` a otra carpeta y corre `pip --version` desde ahí. **Criterio:** el error exacto, y por qué `python -m pip` sí funciona.
5. Crea un entorno con `--system-site-packages` e importa un paquete del sistema. **Criterio:** describes cuándo eso es útil y cuándo peligroso.
6. Intenta `pip install` con el Python del sistema en Debian o Ubuntu. **Criterio:** el error de PEP 668 y qué propone.

**🟠 Difícil (7–9)**

7. Escribe un `sitecustomize.py` en el entorno que imprima algo al arrancar. **Criterio:** se ejecuta con cada `python` del entorno y explicas para qué se usa.
8. Mide el tiempo de crear 10 entornos con `venv` y con `uv venv`. **Criterio:** la tabla, y de dónde sale la diferencia.
9. Usa `PYTHONPATH` para hacer que un entorno vea un paquete de otro. **Criterio:** funciona, y explicas por qué casi nunca es buena idea.

**🔴 Muy difícil (10)**

10. Explica a tu equipo Java cómo funciona un entorno de Python con un dibujo. **Criterio:** un diagrama y una página. *Rúbrica:* (a) intérprete, entorno y
    `site-packages`; (b) qué hace activar y qué no; (c) la comparación con el *classpath* y `~/.m2`; (d) qué viaja entre máquinas y qué no.

---

## 📚 7. Referencias

**Documentación oficial**

- `venv`: https://docs.python.org/3/library/venv.html
- `site` y `sys.path`: https://docs.python.org/3/library/site.html
- PEP 668, entornos administrados externamente: https://peps.python.org/pep-0668/

**Orden de lectura sugerido:** la sección "How venvs work" de la documentación de `venv`; después la PEP 668, que explica el error que todos encuentran.

---

## 🚀 8. Cierre

Un entorno virtual es una carpeta con un `pyvenv.cfg`, un enlace al intérprete y su propio `site-packages`. Activarlo solo cambia el `PATH`; el `python` del
entorno funciona sin activar. Los entornos no se mueven ni se copian: se recrean desde la lista de dependencias fijadas, que es lo que cada gestor resuelve a
su manera.

**La señal de que quedó bien:** *"El cron llama a `/opt/aurea/.venv/bin/python` directo, y nadie vuelve a preguntar por qué no ve los paquetes."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-01 -m "op pk01 cerrada: qué es un entorno por dentro y qué hace activar"
> ```
>
> Los commits llevan su prefijo (`op pk01: …`) y los de ejercicio su número
> (`op pk01 ej07: …`).
