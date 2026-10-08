# ⚡ pk03 — uv

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 3 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El camino base eligió `uv` como gestor del curso, y la decisión salió de una tabla medida (`BENCHMARKS.md` §07): **0,4 s** para instalar el entorno con caché
fría contra 11,1 s de `pip` + `pip-tools` y 43 s de Miniforge, 27 MB contra 74 y 211, **dos pasos** de Patricia contra seis. Esta sección no repite esos números.
Mira las dos cosas que la tabla no muestra y que deciden si `uv` es la herramienta de una casa: **qué es su *lock*** —y por qué es distinto de un `requirements.txt`
compilado— y **cuánto cuesta adoptar una herramienta tan joven**, que cambia de versión todas las semanas.

`uv` (de Astral, los de `ruff`) reemplaza a `pip`, `pip-tools`, `venv`, `pipx` y `pyenv` con un solo binario escrito en Rust: maneja el intérprete, el entorno, el
*lock*, las herramientas de línea de comandos y los *scripts* con dependencias en línea (PEP 723). Es la herramienta que más rápido se adoptó en la historia de
Python, y eso tiene un precio que también se puede medir.

---

## 🧠 2. El modelo

| Comando | Qué hace | Lo que reemplaza |
|---|---|---|
| `uv init`, `uv add httpx` | Proyecto con `pyproject.toml` y dependencia agregada | Editar a mano + `pip install` |
| `uv lock` | `uv.lock`: **un *lock* universal**, válido para todas las plataformas y versiones de Python declaradas | `pip-compile` por plataforma |
| `uv sync --frozen` | Deja el entorno idéntico al *lock*, sin resolver nada | `pip-sync` |
| `uv run script.py` | Corre con el entorno al día; con PEP 723, crea uno efímero | `source .venv/bin/activate` |
| `uv python install 3.14` | Instala el intérprete | `pyenv` |
| `uv tool install ruff` | Herramienta aislada en su propio entorno | `pipx` |
| `uv export` | El *lock* como `requirements.txt` con *hashes* | — |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien viene de Maven y Gradle desconfía de una herramienta de dos años que reemplaza todo: en la JVM, la herramienta de construcción es una
decisión de diez años. Es un buen instinto, y la sección lo mide en vez de descartarlo; lo que se equivoca es en suponer que la alternativa es más estable: el
ecosistema de empaquetado de Python **antes** de `uv` era cinco herramientas que no se ponían de acuerdo.

---

## 💻 3. El ejemplo que corre

```bash
pip install uv          # o el instalador de Astral; en la casa, una versión fija
```

`probar_uv.sh`:

```bash
set -euo pipefail
uv --version
uv init --quiet --no-workspace aurea-agente && cd aurea-agente
uv add --quiet httpx psycopg[binary]
echo "paquetes en el lock: $(grep -c '^\[\[package\]\]' uv.lock)"
echo "plataformas distintas en las ruedas de psycopg-binary: $(grep -o 'psycopg_binary-[^"]*\.whl' uv.lock | grep -oE '(manylinux|musllinux|macosx|win)[^.]*' | sed 's/_[0-9].*//' | sort -u | tr '\n' ' ')"
uv export --quiet --format requirements-txt --no-hashes | grep -E '^(httpx|psycopg)'
rm -rf .venv && uv sync --frozen --quiet && .venv/bin/python -c "import httpx, psycopg; print('sync desde el lock: OK')"
```

`ritmo.py` —el costo de lo joven: cuántas versiones publicó `uv` en los últimos 90 días—:

```python
"""Cuántas versiones publicó un paquete en los últimos 90 días, según PyPI."""

import datetime as dt
import json
import sys
import urllib.request

today = dt.datetime(2026, 10, 5, tzinfo=dt.UTC)
for package in sys.argv[1:]:
    data = json.load(urllib.request.urlopen(f"https://pypi.org/pypi/{package}/json", timeout=20))
    dates = [min(dt.datetime.fromisoformat(f["upload_time_iso_8601"]) for f in files)
             for files in data["releases"].values() if files]
    recent = [d for d in dates if (today - d).days <= 90]
    print(f"{package:<10} {len(recent):>3} versiones en 90 días · última: {data['info']['version']}")
```

```bash
bash probar_uv.sh
python3 ritmo.py uv pip poetry pdm
```

Salida (Python 3.14.7, 05/10/2026):

```text
uv 0.12.23 (aarch64-unknown-linux-gnu)
paquetes en el lock: 11
plataformas distintas en las ruedas de psycopg-binary: macosx manylinux manylinux2014_ppc64le manylinux2014_x86 musllinux win_amd64
httpx==0.28.1
psycopg==3.3.6
psycopg-binary==3.3.6 ; implementation_name != 'pypy'
sync desde el lock: OK
uv          31 versiones en 90 días · última: 0.12.23
pip          2 versiones en 90 días · última: 26.2.1
poetry       4 versiones en 90 días · última: 2.5.1
pdm          5 versiones en 90 días · última: 2.29.2
```

Dos dependencias pedidas, once paquetes en el *lock*, y en él las ruedas de `psycopg-binary` para macOS, Linux (glibc y musl, varias arquitecturas) y Windows: el mismo
archivo sirve en el portátil y en el servidor. `uv export` lo devuelve como `requirements.txt`, con el marcador que dice que `psycopg-binary` no aplica en PyPy. Y la
cifra que la tabla del camino base no tenía: **`uv` publicó 31 versiones en 90 días**, una cada tres días; `pip`, dos. Es un proyecto vivísimo, y una herramienta
que hay que fijar.

**Detalles con intención**

- **El *lock* universal**: `uv.lock` lista las ruedas de `psycopg-binary` para Linux, macOS y Windows a la vez. Un `requirements.txt` de `pip-compile` se compila en una
  plataforma y es para esa plataforma (`pk02`). Con un *lock* universal, el portátil del ingeniero (macOS) y el servidor de la sede (Linux) instalan desde el mismo
  archivo.
- **`uv sync --frozen`** instala exactamente el *lock* y falla si el `pyproject.toml` cambió sin volver a bloquear. Es la forma que va en el CI y en el `Dockerfile`.
- **`uv export`** sale a `requirements.txt`: la puerta de salida si un día hay que volver a `pip`. Que exista es parte de lo que hace aceptable adoptar `uv`.
- **El ritmo de versiones** se mide contra PyPI, no se supone. Un ritmo alto es buena señal de mantenimiento y una obligación: hay que fijar la versión de `uv` en el CI
  y actualizarla a propósito.

---

## ⚠️ 4. Lo que se rompe

**`uv` sin versión fija en el CI.** Con versiones cada pocos días, el CI que instala "la última" cambia de comportamiento sin que nadie cambie nada. Se fija (`pip install
uv==…`, o la imagen oficial con etiqueta) y se actualiza con un *pull request*.

**El primer `import` lento.** Medido en el camino base: 2,28 s contra 0,33 s de `pip`, porque `uv` no compila el *bytecode* al instalar. En un servicio que arranca seguido
(una función, un contenedor que escala), se usa `--compile-bytecode` o `UV_COMPILE_BYTECODE=1`.

**El formato de `uv.lock` es de `uv`.** Ninguna otra herramienta lo lee. La salida es `uv export`, y conviene saber que existe antes de necesitarla.

**`uv pip` como si fuera `pip`.** La interfaz `uv pip install` imita a `pip`, pero no es idéntica en todos los rincones (resolución, opciones raras). En un proyecto con
`uv`, se usa `uv add` y `uv sync`, no la imitación.

---

## ⚖️ 5. Cuándo NO usarlo

**En el servidor donde no se puede instalar nada.** `pip` + `pip-tools` (`pk02`), con el `requirements.txt` que `uv export` genera en el CI.

**Para paquetes que no son de Python.** `uv` instala paquetes de PyPI; CUDA, GDAL o un compilador de Fortran siguen siendo trabajo de conda (`pk04`).

**Si la casa ya estandarizó Poetry y funciona.** El ahorro de segundos no paga una migración de veinte proyectos; los proyectos nuevos pueden decidir distinto (`pk08`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas las plataformas del *lock* y el ritmo de versiones de cada herramienta.
2. Escribe un *script* con dependencias en línea (PEP 723) y córrelo con `uv run`. **Criterio:** funciona sin crear un proyecto.
3. Agrega `pytest` como dependencia de desarrollo (`uv add --dev`). **Criterio:** aparece en otro grupo del `pyproject.toml` y no en `uv export --no-dev`.

**🟡 Intermedio (4–6)**

4. Cambia el `pyproject.toml` a mano sin volver a bloquear y corre `uv sync --frozen`. **Criterio:** el error que da y por qué es lo que quieres en el CI.
5. Mide el primer `import` con y sin `--compile-bytecode`. **Criterio:** los dos tiempos.
6. Usa `uv python install 3.13` y crea un entorno con esa versión. **Criterio:** el proyecto corre en 3.13 sin tocar el Python del sistema.

**🟠 Difícil (7–9)**

7. Arma un `Dockerfile` con la imagen oficial de `uv` en una etapa y `uv sync --frozen --no-dev` en la caché de construcción. **Criterio:** la imagen final sin `uv` y su
   tamaño.
8. Declara en `pyproject.toml` que el proyecto soporta Python 3.12 a 3.14 y mira cómo cambia `uv.lock`. **Criterio:** los marcadores de resolución que aparecen.
9. Migra un proyecto de `pip-tools` a `uv` y verifica que las versiones resueltas coinciden. **Criterio:** la lista de diferencias, si las hay.

**🔴 Muy difícil (10)**

10. Escribe la propuesta de adoptar `uv` en una casa con veinte proyectos en `pip-tools`. **Criterio:** una página. *Rúbrica:* (a) lo que gana cada proyecto, con los números de
    `BENCHMARKS.md`; (b) el costo de la juventud: versiones, cambios, la salida con `uv export`; (c) el plan de migración; (d) qué proyectos no migrarían.

---

## 📚 7. Referencias

**Documentación oficial**

- `uv`: https://docs.astral.sh/uv/
- `uv`, el *lock* universal: https://docs.astral.sh/uv/concepts/resolution/#universal-resolution
- PEP 723, metadatos de *scripts* en línea: https://peps.python.org/pep-0723/

**Orden de lectura sugerido:** la página de resolución universal (explica qué hay en `uv.lock`); después la guía de proyectos de `uv`.

---

## 🚀 8. Cierre

`uv` es más rápido (medido en el camino base) y además hace distinto lo importante: un *lock* universal que sirve igual en macOS y en el servidor Linux, el
intérprete incluido, y una salida a `requirements.txt` por si hay que volver. El costo de su juventud es un ritmo de versiones alto, que se maneja fijando la
versión y actualizando a propósito.

**La señal de que quedó bien:** *"El portátil del ingeniero y el servidor de la sede instalan desde el mismo `uv.lock`, y la versión de `uv` del CI cambia solo
cuando alguien la cambia."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-03 -m "op pk03 cerrada: el lock universal de uv y el costo medido de su juventud"
> ```
>
> Los commits llevan su prefijo (`op pk03: …`) y los de ejercicio su número
> (`op pk03 ej07: …`).
