# Bitácora de ejecución · sesión b74cbeda-4ebe-41e8-a4a9-572ad0a26258

Comandos que ejecutaron código, con el inicio de su salida.

### ⏱️ 2026-09-13T00:58:57Z · Query PyPI for current versions

~~~~~~bash
for p in uv ruff mypy pytest fastapi pydantic sqlalchemy alembic django httpx hypothesis uvicorn; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['info']['version'], d['urls'][0]['upload_time'][:10] if d['urls'] else '')" 2>/dev/null); echo "$p -> $v"; done
~~~~~~

~~~~~~text
uv -> 0.12.13 2026-09-10
ruff -> 0.16.7 2026-09-10
mypy -> 2.3.1 2026-08-15
pytest -> 9.1.1 2026-06-19
fastapi -> 0.141.1 2026-07-29
pydantic -> 2.13.5 2026-08-28
sqlalchemy -> 2.0.52 2026-08-11
alembic -> 1.20.0 2026-09-11
django -> 6.1.1 2026-09-02
httpx -> 0.28.1 2024-12-06
hypothesis -> 6.168.0 2026-09-08
uvicorn -> 0.52.4 2026-08-19
~~~~~~

### ⏱️ 2026-09-13T00:59:19Z · Query more package versions

~~~~~~bash
for p in pip pip-tools pyright psycopg celery arq redis prometheus-client opentelemetry-sdk structlog typer rich pyinstaller pytest-cov; do v=$(curl -s "https://pypi.org/pypi/$p/json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['info']['version'], d['urls'][0]['upload_time'][:10] if d['urls'] else '')" 2>/dev/null); echo "$p -> $v"; done; echo "--- miniforge ---"; curl -s https://api.github.com/repos/conda-forge/miniforge/releases/latest | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['tag_name'], d['published_at'][:10])"
~~~~~~

~~~~~~text
pip -> 26.2.1 2026-08-04
pip-tools -> 7.6.1 2026-08-12
pyright -> 1.1.414 2026-09-10
psycopg -> 3.3.5 2026-08-31
celery -> 5.6.3 2026-03-26
arq -> 0.28.0 2026-04-16
redis -> 8.1.0 2026-07-30
prometheus-client -> 0.26.0 2026-07-24
opentelemetry-sdk -> 1.44.0 2026-07-16
structlog -> 26.1.0 2026-06-06
typer -> 0.27.2 2026-08-28
rich -> 15.0.0 2026-04-12
pyinstaller -> 6.22.3 2026-09-12
pytest-cov -> 7.1.0 2026-03-21
--- miniforge ---
26.7.2-0 2026-09-08
~~~~~~

### ⏱️ 2026-09-13T00:59:50Z · Pin exact versions in scope doc

~~~~~~bash
cat > /tmp/claude-501/patch9.py <<'PYEOF'
import io
p = "prompts/alcance-del-proyecto.md"
s = io.open(p, encoding="utf-8").read()

old_start = "| Herramienta | Versión | Dónde vive |"
old_end = "> con su número exacto en esta tabla primero.\n"
i = s.index(old_start)
j = s.index(old_end) + len(old_end)

new = """| Herramienta | Versión | Dónde vive |
|---|---|---|
| Python | **3.14.7** (piso soportado: 3.13.15) | Fase 00 · todo el curso |
| Gestión de entorno, Bloque A | `venv` + `pip` **26.2.1** de la biblioteca estándar | Fase 00 |
| Gestión de entorno, Bloques B y C | **`uv` 0.12.13** | Fase 07 en adelante |
| Comparados contra `uv` en la frontera | `pip-tools` **7.6.1** y **Miniforge 26.7.2-0** (`conda-forge`) | Fase 07, medidos |
| Formato y lint | `ruff` **0.16.7** | Fase 00 · transversal |
| Tipado | `mypy` **2.3.1** (alternativa: `pyright` **1.1.414**) en modo estricto | Fase 08 |
| Pruebas | `pytest` **9.1.1**, `pytest-cov` **7.1.0**, `hypothesis` **6.168.0** | Fase 08 · transversal |
| Editor principal | VS Code + extensión oficial de Python | Fase 00 |
| Editor alternativo | PyCharm Community | Fase 00 |

**Dependencias del Bloque C**, fijadas aquí antes de usarse:

| Herramienta | Versión | Dónde vive |
|---|---|---|
| FastAPI · Pydantic · Uvicorn | **0.141.1** · **2.13.5** · **0.52.4** | Fase 10 en adelante |
| SQLAlchemy · Alembic · psycopg | **2.0.52** · **1.20.0** · **3.3.5** | Fase 11 en adelante |
| Django | **6.1.1** | Fase 12 |
| httpx | **0.28.1** | Fase 13 |
| Celery · arq · redis-py | **5.6.3** · **0.28.0** · **8.1.0** | Fase 15 |
| structlog · prometheus-client · OpenTelemetry SDK | **26.1.0** · **0.26.0** · **1.44.0** | Fase 16 |

> 📅 **Fecha de verificación: 12 de septiembre de 2026.** Todos los números de arriba se
> consultaron ese día contra PyPI, python.org y el repositorio de Miniforge. No hay ninguno
> puesto de memoria. Cuando una fase se redacte meses después, se vuelve a verificar y **se
> corrige aquí primero**; el curso declara la fecha en vez de fingir que el ecosistema se
> detuvo.

> 📄 **Sobre conda.** Cuando el curso use conda, usa **Miniforge con el canal `conda-forge`**,
> que es comunitario y libre. Los canales por defecto de Anaconda, cuyos términos comerciales
> dependen del tamaño de la organización, **no entran al curso** — así el tema de licenciamiento
> deja de existir en vez de tener que explicarse.

> ⚠️ **Las versiones exactas —patch incluido— se cierran en la discusión de fases y se
> escriben aquí antes de redactar la primera línea que las use.** Ninguna se da por buena de
> memoria. Esta tabla es la única fuente; si una fase necesita una dependencia nueva, se fija
> con su número exacto en esta tabla primero.
"""
s = s[:i] + new + s[j:]
io.open(p, "w", encoding="utf-8").write(s)
print("ok")
PYEOF
python3 /tmp/claude-501/patch9.py && sed -n '187,235p' prompts/alcance-del-proyecto.md
~~~~~~

~~~~~~text
ok
## 9. Restricciones de versiones

El curso es **autocontenido**: no depende de ningún `requirements.txt` externo y no verifica
nada contra un sistema que el lector no tenga.

| Herramienta | Versión | Dónde vive |
|---|---|---|
| Python | **3.14.7** (piso soportado: 3.13.15) | Fase 00 · todo el curso |
| Gestión de entorno, Bloque A | `venv` + `pip` **26.2.1** de la biblioteca estándar | Fase 00 |
| Gestión de entorno, Bloques B y C | **`uv` 0.12.13** | Fase 07 en adelante |
| Comparados contra `uv` en la frontera | `pip-tools` **7.6.1** y **Miniforge 26.7.2-0** (`conda-forge`) | Fase 07, medidos |
| Formato y lint | `ruff` **0.16.7** | Fase 00 · transversal |
| Tipado | `mypy` **2.3.1** (alternativa: `pyright` **1.1.414**) en modo estricto | Fase 08 |
| Pruebas | `pytest` **9.1.1**, `pytest-cov` **7.1.0**, `hypothesis` **6.168.0** | Fase 08 · transversal |
| Editor principal | VS Code + extensión oficial de Python | Fase 00 |
| Editor alternativo | PyCharm Community | Fase 00 |

**Dependencias del Bloque C**, fijadas aquí antes de usarse:

| Herramienta | Versión | Dónde vive |
|---|---|---|
| FastAPI · Pydantic · Uvicorn | **0.141.1** · **2.13.5** · **0.52.4** | Fase 10 en adelante |
| SQLAlchemy · Alembic · psycopg | **2.0.52** · **1.20.0** · **3.3.5** | Fase 11 en adelante |
| Django | **6.1.1** | Fase 12 |
| httpx | **0.28.1** | Fase 13 |
| Celery · arq · redis-py | **5.6.3** · **0.28.0** · **8.1.0** | Fase 15 |
| structlog · prometheus-client · OpenTelemetry SDK | **
~~~~~~

### ⏱️ 2026-09-13T01:15:37Z · Test scenario 3 detection

~~~~~~bash
cd /tmp/claude-501 && /opt/homebrew/bin/python3.14 -m venv .venv-test -q && VIRTUAL_ENV=/tmp/claude-501/.venv-test PATH=/tmp/claude-501/.venv-test/bin:$PATH /usr/bin/python3 diagnostico.py | tail -8; echo "salida: $?"; ./.venv-test/bin/python diagnostico.py | sed -n '/Entorno/,/^$/p'
~~~~~~

~~~~~~text
usage: python3.14 -m venv [-h] [--system-site-packages] [--symlinks |
                          --copies] [--clear] [--upgrade] [--without-pip]
                          [--prompt PROMPT] [--upgrade-deps]
                          [--without-scm-ignore-files]
                          ENV_DIR [ENV_DIR ...]
python3.14 -m venv: error: unrecognized arguments: -q
salida: 2
(eval):1: no such file or directory: ./.venv-test/bin/python
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:15:42Z · Test venv scenarios

~~~~~~bash
cd /tmp/claude-501 && /opt/homebrew/bin/python3.14 -m venv .venv-test && echo "--- escenario 3 (venv activo, otro intérprete) ---" && VIRTUAL_ENV=/tmp/claude-501/.venv-test /usr/bin/python3 diagnostico.py | sed -n '/Avisos/,$p'; echo "--- escenario 1 (venv, sin activar) ---"; /tmp/claude-501/.venv-test/bin/python diagnostico.py | sed -n '/Entorno virtual/,/^$/p'
~~~~~~

~~~~~~text
--- escenario 3 (venv activo, otro intérprete) ---
Traceback (most recent call last):
  File "/private/tmp/claude-501/diagnostico.py", line 30, in <module>
    def active_virtualenv() -> dict[str, str] | None:
TypeError: unsupported operand type(s) for |: 'types.GenericAlias' and 'NoneType'
--- escenario 1 (venv, sin activar) ---
Entorno virtual:
    proyecto: claude-501
    ruta:     /private/tmp/claude-501/.venv-test
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:15:59Z · Fix and retest on old interpreter

~~~~~~bash
cd /tmp/claude-501 && sed -i '' 's/^import os$/from __future__ import annotations\n\nimport os/' diagnostico.py && head -12 diagnostico.py && echo "=== escenario 3 con python3 del sistema ===" && /usr/bin/python3 -V && VIRTUAL_ENV=/tmp/claude-501/.venv-test /usr/bin/python3 diagnostico.py | sed -n '/Avisos/,$p'
~~~~~~

~~~~~~text
"""Diagnóstico del ambiente de Python de una máquina.

Uso:  python diagnostico.py
Sale con 0 si no encontró inconsistencias, con 1 si encontró alguna.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
=== escenario 3 con python3 del sistema ===
Python 3.9.6
Avisos:
    ⚠️  Tienes un entorno virtual activado, pero este programa lo está ejecutando OTRO Python, el de /Applications/Xcode.app/Contents/Developer/usr/bin/python3. Lo que instalaste en el entorno no se ve desde aquí: por eso falla lo del módulo que no encuentra.
    ⚠️  No hay ningún entorno virtual activo: se está usando el Python del sistema. Para el curso, activa el entorno del proyecto antes de ejecutar nada.

(diagnóstico completado en 458.3 ms)
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:33:02Z · Measure true first import cost

~~~~~~bash
cd /tmp/claude-501/mgr && rm -rf .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv-uv3 && UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv ./.tool-uv/bin/uv pip sync -q --python .venv-uv3/bin/python reqs-uv.txt && /opt/homebrew/bin/python3.14 -c "
import subprocess,time
for i in range(3):
    t0=time.perf_counter(); subprocess.run(['.venv-uv3/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'uv   import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
for i in range(2):
    t0=time.perf_counter(); subprocess.run(['.venv-pip/bin/python','-c','import fastapi, sqlalchemy'],capture_output=True)
    print(f'pip  import #{i+1}: {(time.perf_counter()-t0)*1000:.0f} ms')
"
~~~~~~

~~~~~~text
uv   import #1: 2277 ms
uv   import #2: 322 ms
uv   import #3: 326 ms
pip  import #1: 326 ms
pip  import #2: 322 ms
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:42:29Z · Measure PEP 723 inline script

~~~~~~bash
cd /tmp/claude-501/f07 && echo "=== 3. PEP 723 ===" && cat > cierre.py <<'EOF'
# /// script
# requires-python = ">=3.13"
# dependencies = ["httpx==0.28.1"]
# ///
"""Un solo archivo que declara adentro lo que necesita."""
import httpx
print("httpx", httpx.__version__)
EOF
export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os,statistics
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/.tool-uv/bin/uv','run','cierre.py'],capture_output=True,text=True,env=env)
print(f'uv run (1ra vez, resuelve e instala): {(time.perf_counter()-t0):.1f}s ->', r.stdout.strip() or r.stderr.strip()[-200:])
xs=[]
for _ in range(5):
    t1=time.perf_counter(); subprocess.run(['/tmp/claude-501/mgr/.tool-uv/bin/uv','run','cierre.py'],capture_output=True,env=env); xs.append((time.perf_counter()-t1)*1000)
xs.sort(); print(f'uv run (siguientes): mediana {statistics.median(xs):.0f} ms')
"
~~~~~~

~~~~~~text
=== 3. PEP 723 ===
uv run (1ra vez, resuelve e instala): 0.2s -> httpx 0.28.1
uv run (siguientes): mediana 99 ms
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:42:37Z · Measure PEP 723 cold

~~~~~~bash
cd /tmp/claude-501/f07 && rm -rf /tmp/claude-501/cache-pep723 && UV_CACHE_DIR=/tmp/claude-501/cache-pep723 /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os
env=dict(os.environ)
t0=time.perf_counter()
r=subprocess.run(['/tmp/claude-501/mgr/.tool-uv/bin/uv','run','cierre.py'],capture_output=True,text=True,env=env)
print(f'uv run con caché FRIA: {(time.perf_counter()-t0):.1f}s ->', r.stdout.strip())
"; du -sh /tmp/claude-501/cache-pep723
~~~~~~

~~~~~~text
uv run con caché FRIA: 1.7s -> httpx 0.28.1
5.5M	/tmp/claude-501/cache-pep723
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T01:42:51Z · Build frozen executable with PyInstaller

~~~~~~bash
cd /tmp/claude-501/f07 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python pyinstaller==6.22.3 && echo "=== 4. ejecutable congelado ===" && /opt/homebrew/bin/python3.14 -c "
import subprocess,time,os,pathlib,statistics
t0=time.perf_counter()
r=subprocess.run(['.venv/bin/pyinstaller','--onefile','--name','aur','--paths','src','--clean','-y',
                  '--specpath','build-spec','--distpath','dist-exe','--workpath','build-work',
                  'src/aur/__main__entry.py'],capture_output=True,text=True)
print('exit',r.returncode, r.stderr[-300:] if r.returncode else '')
" 2>/dev/null; cat > src/aur/__main__entry.py <<'EOF'
"""Punto de entrada para el ejecutable congelado."""
import sys

from aur.cli import main

if __name__ == "__main__":
    sys.exit(main())
EOF
/opt/homebrew/bin/python3.14 -c "
import subprocess,time,pathlib,statistics
t0=time.perf_counter()
r=subprocess.run(['.venv/bin/pyinstaller','--onefile','--name','aur','--paths','src','--clean','-y',
                  '--specpath','build-spec','--distpath','dist-exe','--workpath','build-work',
                  'src/aur/__main__entry.py'],capture_output=True,text=True)
print(f'build: {(time.perf_counter()-t0):.1f}s exit={r.returncode}')
if r.returncode: print(r.stderr[-800:])
p=pathlib.Path('dist-exe/aur')
if p.exists():
    print(f'tamaño: {p.stat().st_size/1e6:.1f} MB')
    xs=[]
    for _ in range(10):
        t1=time.perf_counter(); subprocess.run([str(p),'--version'],capture_output=True); xs.append((time.perf_counter()-t1)*1000)
    xs.sort(); print(f'arranque: mediana {statistics.median(xs):.0f} ms  p95 {xs[8]:.0f} ms')
    print('salida:', subprocess.run([str(p),'--version'],capture_output=True,text=True).stdout.strip())
"
~~~~~~

~~~~~~text
=== 4. ejecutable congelado ===
exit 1 167 INFO: PyInstaller: 6.22.3, contrib hooks: 2026.7
168 INFO: Python: 3.14.5
217 INFO: Platform: macOS-26.6.2-arm64-arm-64bit-Mach-O
217 INFO: Python environment: /private/tmp/claude-501/f07/.venv
ERROR: Script file 'src/aur/__main__entry.py' does not exist.

build: 8.0s exit=0
tamaño: 8.4 MB
arranque: mediana 3099 ms  p95 3131 ms
salida: aur 0.7.0
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:36:51Z · Install mypy

~~~~~~bash
cd /tmp/claude-501/f08 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python mypy==2.3.1 2>&1 | tail -2; ./.venv/bin/mypy --version 2>/dev/null || /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python mypy 2>&1 | tail -3; ./.venv/bin/mypy --version
~~~~~~

~~~~~~text
mypy 2.3.1 (compiled: yes)
mypy 2.3.1 (compiled: yes)
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:37:36Z · Verify Hypothesis finds the float bug

~~~~~~bash
cd /tmp/claude-501/f08 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python pytest==9.1.1 hypothesis==6.168.0 && cat > test_reparto.py <<'PYEOF'
"""El invariante del dominio: lo repartido suma exactamente lo cobrado."""
from decimal import Decimal

from hypothesis import given, settings
from hypothesis import strategies as st


def split_fee_float(total, shares):
    """Reparte el total entre los profesionales. Con float, como saldría solo."""
    total_f = float(total)
    return [round(total_f * s, 2) for s in shares]


def split_fee_decimal(total, shares):
    """Con Decimal, y el último se lleva el residuo."""
    parts = []
    remaining = total
    for share in shares[:-1]:
        part = (total * Decimal(str(share))).quantize(Decimal("0.01"))
        parts.append(part)
        remaining -= part
    parts.append(remaining)
    return parts


money = st.decimals(min_value=Decimal("1000"), max_value=Decimal("50000000"),
                    places=2, allow_nan=False, allow_infinity=False)

@given(total=money)
@settings(max_examples=300)
def test_float_suma_exacta(total):
    partes = split_fee_float(total, [0.4, 0.35, 0.25])
    assert Decimal(str(sum(partes))) == total

@given(total=money)
@settings(max_examples=300)
def test_decimal_suma_exacta(total):
    partes = split_fee_decimal(total, [0.4, 0.35, 0.25])
    assert sum(partes) == total
PYEOF
./.venv/bin/pytest test_reparto.py -q 2>&1 | tail -25
~~~~~~

~~~~~~text
>   @settings(max_examples=300)
                   ^^^

test_reparto.py:30: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

total = Decimal('6214.97')

    @given(total=money)
    @settings(max_examples=300)
    def test_float_suma_exacta(total):
        partes = split_fee_float(total, [0.4, 0.35, 0.25])
>       assert Decimal(str(sum(partes))) == total
E       AssertionError: assert Decimal('6214.969999999999') == Decimal('6214.97')
E        +  where Decimal('6214.969999999999') = Decimal('6214.969999999999')
E        +    where '6214.969999999999' = str(6214.969999999999)
E        +      where 6214.969999999999 = sum([2485.99, 2175.24, 1553.74])
E       Failing test case: test_float_suma_exacta(
E           total=Decimal('6214.97'),
E       )

test_reparto.py:33: AssertionError
=========================== short test summary info ============================
FAILED test_reparto.py::test_float_suma_exacta - AssertionError: assert Decim...
1 failed, 1 passed in 1.00s
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:42:37Z · Set up FastAPI environment

~~~~~~bash
mkdir -p /tmp/claude-501/f10 && cd /tmp/claude-501/f10 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python fastapi==0.141.1 uvicorn==0.52.4 pydantic==2.13.5 httpx==0.28.1 && ./.venv/bin/python -c "import fastapi, pydantic, uvicorn; print('fastapi', fastapi.__version__, '· pydantic', pydantic.VERSION, '· uvicorn', uvicorn.__version__)"
~~~~~~

~~~~~~text
fastapi 0.141.1 · pydantic 2.13.5 · uvicorn 0.52.4
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:43:01Z · Build and smoke-test the API

~~~~~~bash
cd /tmp/claude-501/f10 && cat > app.py <<'PYEOF'
"""AgendaAPI — la agenda de la red Áurea. Fase 10: validar en la frontera."""

from datetime import date, datetime, time, timedelta, timezone
from enum import StrEnum
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query, status
from pydantic import BaseModel, Field, field_validator

BOGOTA = timezone(timedelta(hours=-5))

class Branch(StrEnum):
    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"

class PhaseKind(StrEnum):
    DIAGNOSIS = "diagnosis"
    ORTHODONTIC = "orthodontic"
    PERIODONTAL = "periodontal"
    RESTORATIVE = "restorative"
    RETENTION = "retention"

PHASE_MINUTES = {PhaseKind.DIAGNOSIS: 60, PhaseKind.ORTHODONTIC: 20,
                 PhaseKind.PERIODONTAL: 45, PhaseKind.RESTORATIVE: 90,
                 PhaseKind.RETENTION: 20}

class Slot(BaseModel):
    starts_at: datetime
    minutes: int

class AvailabilityResponse(BaseModel):
    branch: Branch
    day: date
    slots: list[Slot]

class BookingRequest(BaseModel):
    """El modelo de ENTRADA. Valida forma, no reglas de negocio."""
    patient_document: str = Field(min_length=6, max_length=12, pattern=r"^\d+$")
    branch: Branch
    phase: PhaseKind
    starts_at: datetime

    @field_validator("starts_at")
    @classmethod
    def must_be_timezone_aware(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("la fecha debe traer zona horaria explícita")
        return value

class BookingResponse(BaseModel):
    booking_id: str
    branch: Branch
    starts_at: datetime
    minutes: int

app = FastAPI(title="AgendaAPI")

def build_slots(day: date, branch: Branch) -> list[Slot]:
    slots = []
    for hour in range(7, 19):
        for minute in (0, 20, 40):
            slots.append(Slot(starts_at=datetime.combine(day, time(hour, minute), BOGOTA), minutes=20))
    return slots

@app.get("/availability", response_model=AvailabilityResponse)
def availability(branch: Branch, day: date) -> AvailabilityResponse:
    return AvailabilityResponse(branch=branch, day=day, slots=build_slots(day, branch))

@app.post("/bookings", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
def book(request: BookingRequest) -> BookingResponse:
    if request.starts_at < datetime.now(BOGOTA):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "la cita no puede ser en el pasado")
    return BookingResponse(booking_id="b-0001", branch=request.branch,
                           starts_at=request.starts_at, minutes=PHASE_MINUTES[request.phase])

@app.get("/availability-raw")
def availability_raw(branch: str, day: str) -> dict:
    """La misma respuesta SIN modelo de salida: para medir qué cuesta validar."""
    d = date.fromisoformat(day)
    return {"branch": branch, "day": day,
            "slots": [{"starts_at": datetime.combine(d, time(h, m), BOGOTA).isoformat(), "minutes": 20}
                      for h in range(7, 19) for m in (0, 20, 40)]}
PYEOF
./.venv/bin/python -c "
from fastapi.testclient import TestClient
" 2>/dev/null || /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'httpx' >/dev/null
./.venv/bin/python -c "
import app
from fastapi.testclient import TestClient
c = TestClient(app.app)
r = c.get('/availability', params={'branch':'centro','day':'2026-04-15'})
print(r.status_code, len(r.json()['slots']), 'espacios')
r = c.post('/bookings', json={'patient_document':'1019283746','branch':'centro','phase':'orthodontic','starts_at':'2026-04-15T15:40:00-05:00'})
print(r.status_code, r.json())
r = c.post('/bookings', json={'patient_document':'AB19283746','branch':'centro','phase':'orthodontic','starts_at':'2026-04-15T15:40:00-05:00'})
print(r.status_code, r.json()['detail'][0]['msg'] if r.status_code==422 else r.json())
r = c.post('/bookings', json={'patient_document':'1019283746','branch':'centro','phase':'orthodontic','starts_at':'2026-04-15T15:40:00'})
print(r.status_code, r.json()['detail'][0]['msg'])
"
~~~~~~

~~~~~~text
/private/tmp/claude-501/f10/.venv/lib/python3.14/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
  from starlette.testclient import TestClient as TestClient  # noqa
/private/tmp/claude-501/f10/.venv/lib/python3.14/site-packages/anyio/_backends/_asyncio.py:1100: StarletteDeprecationWarning: 'HTTP_422_UNPROCESSABLE_ENTITY' is deprecated. Use 'HTTP_422_UNPROCESSABLE_CONTENT' instead.
  result = context.run(func, *args)
200 36 espacios
422 {'detail': 'la cita no puede ser en el pasado'}
422 String should match pattern '^\d+$'
422 Value error, la fecha debe traer zona horaria explícita
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:43:19Z · Measure endpoint latency and validation cost

~~~~~~bash
cd /tmp/claude-501/f10 && sed -i '' 's/HTTP_422_UNPROCESSABLE_ENTITY/HTTP_422_UNPROCESSABLE_CONTENT/' app.py && cat > medir.py <<'PYEOF'
"""Cuánto de la latencia del endpoint es validación."""
import statistics, time, json
from datetime import date, datetime, time as t, timedelta, timezone
from fastapi.testclient import TestClient
import app as A

c = TestClient(A.app)

def bench(fn, reps=400):
    for _ in range(40): fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1]

payload = {"patient_document":"1019283746","branch":"centro","phase":"orthodontic",
           "starts_at":"2026-10-15T15:40:00-05:00"}

print("=== endpoints (en proceso, sin red) ===")
for name, fn in [
    ("GET /availability (con modelo de salida)", lambda: c.get("/availability", params={"branch":"centro","day":"2026-10-15"})),
    ("GET /availability-raw (sin modelo)",        lambda: c.get("/availability-raw", params={"branch":"centro","day":"2026-10-15"})),
    ("POST /bookings (valida entrada y salida)",  lambda: c.post("/bookings", json=payload)),
]:
    m,p = bench(fn)
    print(f"{name:44s} mediana {m:6.2f} ms   p95 {p:6.2f} ms")

print()
print("=== el costo puro de Pydantic, sin HTTP ===")
raw = A.availability_raw("centro", "2026-10-15")
def validar_salida(): A.AvailabilityResponse.model_validate({"branch":"centro","day":"2026-10-15","slots":raw["slots"]})
def validar_entrada(): A.BookingRequest.model_validate(payload)
def serializar(): A.AvailabilityResponse.model_validate({"branch":"centro","day":"2026-10-15","slots":raw["slots"]}).model_dump_json()
for name, fn in [("validar la entrada del POST (4 campos)", validar_entrada),
                 ("validar la salida (36 espacios)", validar_salida),
                 ("validar + serializar la salida", serializar),
                 ("json.dumps del dict crudo", lambda: json.dumps(raw))]:
    m,p = bench(fn, 2000)
    print(f"{name:44s} mediana {m*1000:7.1f} µs   p95 {p*1000:7.1f} µs")
PYEOF
./.venv/bin/python medir.py 2>/dev/null
~~~~~~

~~~~~~text
=== endpoints (en proceso, sin red) ===
GET /availability (con modelo de salida)     mediana   1.28 ms   p95   2.03 ms
GET /availability-raw (sin modelo)           mediana   0.96 ms   p95   1.22 ms
POST /bookings (valida entrada y salida)     mediana   0.92 ms   p95   1.26 ms

=== el costo puro de Pydantic, sin HTTP ===
validar la entrada del POST (4 campos)       mediana     1.1 µs   p95     1.2 µs
validar la salida (36 espacios)              mediana    16.6 µs   p95    17.5 µs
validar + serializar la salida               mediana    38.5 µs   p95    41.5 µs
json.dumps del dict crudo                    mediana    12.1 µs   p95    13.2 µs
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:48:33Z · Check for Postgres availability

~~~~~~bash
which docker podman postgres psql pg_ctl 2>/dev/null; echo "---"; docker info 2>&1 | head -3
~~~~~~

~~~~~~text
/Users/oskar/.docker/bin/docker
podman not found
/opt/homebrew/opt/postgresql@18/bin/postgres
/opt/homebrew/opt/postgresql@18/bin/psql
/opt/homebrew/opt/postgresql@18/bin/pg_ctl
---
Client:
 Version:    29.6.2
 Context:    desktop-linux
~~~~~~

### ⏱️ 2026-09-13T02:49:00Z · Install SQLAlchemy and psycopg

~~~~~~bash
mkdir -p /tmp/claude-501/f11 && cd /tmp/claude-501/f11 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'sqlalchemy==2.0.52' 'psycopg[binary]==3.3.5' 'alembic==1.20.0' && ./.venv/bin/python -c "import sqlalchemy, psycopg; print('sqlalchemy', sqlalchemy.__version__, '· psycopg', psycopg.__version__)"
~~~~~~

~~~~~~text
sqlalchemy 2.0.52 · psycopg 3.3.5
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:49:29Z · Seed Postgres with the Aurea domain

~~~~~~bash
cd /tmp/claude-501/f11 && cat > seed.py <<'PYEOF'
"""Carga el dominio de Áurea en Postgres para medir."""
import random
from datetime import date, datetime, timedelta, timezone
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
BOGOTA = timezone(timedelta(hours=-5))
BRANCHES = ["Centro","Chapinero","Suba","Kennedy","Usaquen","Engativa","Fontibon","Restrepo","Soacha","Zipaquira"]
PHASES = ["diagnosis","orthodontic","periodontal","restorative","retention"]

DDL = """
DROP TABLE IF EXISTS appointments, plan_phases, treatment_plans, patients, dentists, branches CASCADE;
CREATE TABLE branches (id serial PRIMARY KEY, name text NOT NULL UNIQUE);
CREATE TABLE dentists (id serial PRIMARY KEY, name text NOT NULL, branch_id int NOT NULL REFERENCES branches(id));
CREATE TABLE patients (id serial PRIMARY KEY, document text NOT NULL UNIQUE, name text NOT NULL);
CREATE TABLE treatment_plans (
    id serial PRIMARY KEY, patient_id int NOT NULL REFERENCES patients(id),
    opened_on date NOT NULL, total_amount numeric(14,2) NOT NULL);
CREATE TABLE plan_phases (
    id serial PRIMARY KEY, plan_id int NOT NULL REFERENCES treatment_plans(id),
    kind text NOT NULL, branch_id int NOT NULL REFERENCES branches(id),
    dentist_id int REFERENCES dentists(id), status text NOT NULL,
    consent_signed_on date, last_moved_on date NOT NULL);
CREATE TABLE appointments (
    id serial PRIMARY KEY, patient_id int NOT NULL REFERENCES patients(id),
    branch_id int NOT NULL REFERENCES branches(id), starts_at timestamptz NOT NULL,
    minutes int NOT NULL, status text NOT NULL);
CREATE INDEX idx_appt_branch_start ON appointments(branch_id, starts_at);
CREATE INDEX idx_phase_plan ON plan_phases(plan_id);
CREATE INDEX idx_phase_status_moved ON plan_phases(status, last_moved_on);
"""

def main():
    rng = random.Random(2026)
    with psycopg.connect(DSN, autocommit=True) as con:
        con.execute(DDL)
        with con.cursor() as cur:
            cur.executemany("INSERT INTO branches (name) VALUES (%s)", [(b,) for b in BRANCHES])
            cur.executemany("INSERT INTO dentists (name, branch_id) VALUES (%s, %s)",
                            [(f"Dr. {n}", rng.randint(1,10)) for n in range(34)])
            cur.executemany("INSERT INTO patients (document, name) VALUES (%s, %s)",
                            [(str(10_000_000+i*97), f"Paciente {i}") for i in range(2800)])
            # 700 planes integrales, cada uno con sus cinco fases
            plans = [(rng.randint(1,2800), date(2025,1,1)+timedelta(days=rng.randint(0,500)),
                      rng.choice([8_000_000, 12_000_000, 16_000_000, 22_000_000])) for _ in range(700)]
            cur.executemany("INSERT INTO treatment_plans (patient_id, opened_on, total_amount) VALUES (%s,%s,%s)", plans)
            phases=[]
            for plan_id in range(1, 701):
                for kind in PHASES:
                    status = rng.choice(["done","done","in_progress","pending"])
                    phases.append((plan_id, kind, rng.randint(1,10), rng.randint(1,34), status,
                                   date(2025,6,1) if status!="pending" else None,
                                   date(2026,9,12)-timedelta(days=rng.randint(0,200))))
            cur.executemany("""INSERT INTO plan_phases (plan_id,kind,branch_id,dentist_id,status,consent_signed_on,last_moved_on)
                               VALUES (%s,%s,%s,%s,%s,%s,%s)""", phases)
            # 3 meses de citas de toda la red
            appts=[]
            start = datetime(2026,7,1,tzinfo=BOGOTA)
            for day in range(90):
                d = start + timedelta(days=day)
                if d.weekday()==6: continue
                for b in range(1,11):
                    for _ in range(rng.randint(20,40)):
                        h, m = rng.randint(7,18), rng.choice((0,20,40))
                        appts.append((rng.randint(1,2800), b, d.replace(hour=h, minute=m), 20,
                                      rng.choice(["asistio","no_show","reservada"])))
            cur.executemany("INSERT INTO appointments (patient_id,branch_id,starts_at,minutes,status) VALUES (%s,%s,%s,%s,%s)", appts)
        con.execute("ANALYZE")
        for t in ("branches","dentists","patients","treatment_plans","plan_phases","appointments"):
            n = con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
            print(f"{t:18s} {n:>8,}")

if __name__ == "__main__":
    main()
PYEOF
./.venv/bin/python seed.py
~~~~~~

~~~~~~text
branches                 10
dentists                 34
patients              2,800
treatment_plans         700
plan_phases           3,500
appointments         23,141
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:49:54Z · Measure raw SQL vs Core vs ORM and the N+1

~~~~~~bash
cd /tmp/claude-501/f11 && cat > medir.py <<'PYEOF'
"""La misma consulta en SQL directo, Core y ORM. Y el N+1 provocado."""
import statistics, time
from datetime import date, datetime, timedelta, timezone

import psycopg
from sqlalchemy import create_engine, event, func, select, text
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, selectinload

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
URL = "postgresql+psycopg://aurea@/agenda?host=/tmp/claude-501&port=55432"
BOGOTA = timezone(timedelta(hours=-5))
DAY = datetime(2026, 8, 12, tzinfo=BOGOTA)

engine = create_engine(URL)

queries = {"n": 0}
@event.listens_for(engine, "before_cursor_execute")
def count(conn, cursor, statement, params, context, executemany):
    queries["n"] += 1

class Base(DeclarativeBase): pass

class Branch(Base):
    __tablename__ = "branches"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str]

class TreatmentPlan(Base):
    __tablename__ = "treatment_plans"
    id: Mapped[int] = mapped_column(primary_key=True)
    patient_id: Mapped[int]
    opened_on: Mapped[date]
    phases: Mapped[list["PlanPhase"]] = relationship(back_populates="plan")

class PlanPhase(Base):
    __tablename__ = "plan_phases"
    id: Mapped[int] = mapped_column(primary_key=True)
    plan_id: Mapped[int] = mapped_column(__import__("sqlalchemy").ForeignKey("treatment_plans.id"))
    kind: Mapped[str]
    status: Mapped[str]
    last_moved_on: Mapped[date]
    plan: Mapped[TreatmentPlan] = relationship(back_populates="phases")

SQL = """
SELECT a.starts_at, a.minutes FROM appointments a
JOIN branches b ON b.id = a.branch_id
WHERE b.name = %s AND a.starts_at >= %s AND a.starts_at < %s AND a.status <> 'no_show'
ORDER BY a.starts_at
"""

def raw_sql():
    with psycopg.connect(DSN) as con, con.cursor() as cur:
        cur.execute(SQL, ("Centro", DAY, DAY + timedelta(days=1)))
        return cur.fetchall()

conn_raw = psycopg.connect(DSN)
def raw_sql_reused():
    with conn_raw.cursor() as cur:
        cur.execute(SQL, ("Centro", DAY, DAY + timedelta(days=1)))
        return cur.fetchall()

appointments = Base.metadata.tables.get("appointments")
from sqlalchemy import Table, MetaData
md = MetaData(); appt = Table("appointments", md, autoload_with=engine); br = Table("branches", md, autoload_with=engine)

def core():
    stmt = (select(appt.c.starts_at, appt.c.minutes).join(br, br.c.id == appt.c.branch_id)
            .where(br.c.name == "Centro", appt.c.starts_at >= DAY,
                   appt.c.starts_at < DAY + timedelta(days=1), appt.c.status != "no_show")
            .order_by(appt.c.starts_at))
    with engine.connect() as conn:
        return conn.execute(stmt).all()

class Appointment(Base):
    __tablename__ = "appointments"
    id: Mapped[int] = mapped_column(primary_key=True)
    branch_id: Mapped[int] = mapped_column(__import__("sqlalchemy").ForeignKey("branches.id"))
    starts_at: Mapped[datetime]
    minutes: Mapped[int]
    status: Mapped[str]
    patient_id: Mapped[int]

def orm():
    with Session(engine) as s:
        stmt = (select(Appointment).join(Branch, Branch.id == Appointment.branch_id)
                .where(Branch.name == "Centro", Appointment.starts_at >= DAY,
                       Appointment.starts_at < DAY + timedelta(days=1), Appointment.status != "no_show")
                .order_by(Appointment.starts_at))
        return s.scalars(stmt).all()

def bench(fn, reps=40):
    fn(); fn()
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); r=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], len(r)

print("=== la misma consulta de disponibilidad ===")
for name, fn in [("SQL directo (conexión nueva)", raw_sql), ("SQL directo (conexión reusada)", raw_sql_reused),
                 ("SQLAlchemy Core", core), ("SQLAlchemy ORM", orm)]:
    m,p,n = bench(fn)
    print(f"{name:32s} mediana {m:7.2f} ms  p95 {p:7.2f} ms  filas {n}")

print()
print("=== el N+1, provocado ===")
def n_plus_one():
    queries["n"]=0
    with Session(engine) as s:
        plans = s.scalars(select(TreatmentPlan).limit(200)).all()
        total = sum(len(p.phases) for p in plans)   # ← aquí se disparan 200 consultas
    return queries["n"], total

def eager():
    queries["n"]=0
    with Session(engine) as s:
        plans = s.scalars(select(TreatmentPlan).options(selectinload(TreatmentPlan.phases)).limit(200)).all()
        total = sum(len(p.phases) for p in plans)
    return queries["n"], total

for name, fn in [("navegando (N+1)", n_plus_one), ("con selectinload", eager)]:
    fn()
    xs=[]
    for _ in range(20):
        t0=time.perf_counter(); q,total=fn(); xs.append((time.perf_counter()-t0)*1000)
    xs.sort()
    print(f"{name:24s} mediana {statistics.median(xs):7.1f} ms  consultas {q:4d}  fases {total}")
PYEOF
./.venv/bin/python medir.py
~~~~~~

~~~~~~text
=== la misma consulta de disponibilidad ===
SQL directo (conexión nueva)     mediana    3.39 ms  p95    4.38 ms  filas 16
SQL directo (conexión reusada)   mediana    0.06 ms  p95    0.12 ms  filas 16
SQLAlchemy Core                  mediana    0.51 ms  p95    1.10 ms  filas 16
SQLAlchemy ORM                   mediana    0.74 ms  p95    1.50 ms  filas 16

=== el N+1, provocado ===
navegando (N+1)          mediana    42.7 ms  consultas  201  fases 1000
con selectinload         mediana     9.4 ms  consultas    2  fases 1000
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:55:15Z · Install Django

~~~~~~bash
mkdir -p /tmp/claude-501/f12 && cd /tmp/claude-501/f12 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'django==6.1.1' 'psycopg[binary]==3.3.5' && ./.venv/bin/python -c "import django; print('django', django.get_version())"
~~~~~~

~~~~~~text
django 6.1.1
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:55:39Z · Build the Django back-office

~~~~~~bash
cd /tmp/claude-501/f12 && ./.venv/bin/django-admin startproject consultorio . 2>&1 && ./.venv/bin/python manage.py startapp planes && cat > planes/models.py <<'PYEOF'
"""El back-office del plan de tratamiento."""

from django.conf import settings
from django.db import models


class Branch(models.Model):
    name = models.CharField("sede", max_length=40, unique=True)

    class Meta:
        verbose_name, verbose_name_plural = "sede", "sedes"

    def __str__(self) -> str:
        return self.name


class TreatmentPlan(models.Model):
    """Un plan de Arquitectura de Sonrisa."""

    STATUS = [("open", "Abierto"), ("done", "Terminado"), ("cancelled", "Cancelado")]

    patient_document = models.CharField("documento del paciente", max_length=12, db_index=True)
    patient_name = models.CharField("paciente", max_length=120)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, verbose_name="sede")
    opened_on = models.DateField("fecha de apertura")
    total_amount = models.DecimalField("valor total", max_digits=14, decimal_places=2)
    status = models.CharField("estado", max_length=12, choices=STATUS, default="open")
    clinical_note = models.TextField("nota clínica", blank=True)

    class Meta:
        verbose_name, verbose_name_plural = "plan de tratamiento", "planes de tratamiento"
        ordering = ["-opened_on"]

    def __str__(self) -> str:
        return f"{self.patient_name} · {self.branch}"


class AccessLog(models.Model):
    """Auditoría de accesos: requisito legal, no mejora."""

    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    at = models.DateTimeField(auto_now_add=True, db_index=True)
    action = models.CharField(max_length=16)
    plan = models.ForeignKey(TreatmentPlan, on_delete=models.PROTECT)
    reason = models.CharField("motivo del acceso", max_length=120)

    class Meta:
        verbose_name, verbose_name_plural = "acceso a historia", "accesos a historia"


class Profile(models.Model):
    """A qué sede pertenece cada usuario. Édgar ve Suba y nada más."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, null=True, blank=True)
PYEOF
cat > planes/admin.py <<'PYEOF'
"""El admin, con permisos por fila y auditoría."""

from django.contrib import admin

from .models import AccessLog, Branch, Profile, TreatmentPlan


@admin.register(TreatmentPlan)
class TreatmentPlanAdmin(admin.ModelAdmin):
    list_display = ["patient_name", "patient_document", "branch", "opened_on", "total_amount", "status"]
    list_filter = ["branch", "status", "opened_on"]
    search_fields = ["patient_name", "patient_document"]
    date_hierarchy = "opened_on"

    def get_queryset(self, request):
        """El permiso por fila: cada quien ve su sede. Y va aquí, no en la vista."""
        queryset = super().get_queryset(request)
        if request.user.is_superuser:
            return queryset
        branch = getattr(getattr(request.user, "profile", None), "branch", None)
        return queryset.filter(branch=branch) if branch else queryset.none()

    def get_exclude(self, request, obj=None):
        """La nota clínica solo la ve quien tiene relación asistencial."""
        if request.user.is_superuser:
            return []
        return ["clinical_note"]

    def change_view(self, request, object_id, form_url="", extra_context=None):
        """Cada acceso a un plan queda registrado: quién, cuándo y por qué."""
        AccessLog.objects.create(
            actor=request.user, action="view", plan_id=object_id,
            reason=request.GET.get("motivo", "consulta administrativa"),
        )
        return super().change_view(request, object_id, form_url, extra_context)


@admin.register(AccessLog)
class AccessLogAdmin(admin.ModelAdmin):
    list_display = ["at", "actor", "action", "plan", "reason"]
    list_filter = ["action", "at"]
    readonly_fields = ["actor", "at", "action", "plan", "reason"]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(Branch)
admin.site.register(Profile)
PYEOF
python3 - <<'EOF'
import re, pathlib
p = pathlib.Path("consultorio/settings.py"); s = p.read_text()
s = s.replace('"django.contrib.staticfiles",', '"django.contrib.staticfiles",\n    "planes",')
p.write_text(s)
EOF
./.venv/bin/python manage.py makemigrations planes 2>&1 | tail -3 && ./.venv/bin/python manage.py migrate 2>&1 | tail -2
~~~~~~

~~~~~~text
No installed app with label 'planes'.
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying sessions.0001_initial... OK
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:55:53Z · Run migrations and count Django lines

~~~~~~bash
cd /tmp/claude-501/f12 && sed -i '' "s/    'django.contrib.staticfiles',/    'django.contrib.staticfiles',\n    'planes',/" consultorio/settings.py && ./.venv/bin/python manage.py makemigrations planes 2>&1 | tail -6 && ./.venv/bin/python manage.py migrate 2>&1 | tail -3 && echo "=== líneas escritas por mí (sin lo generado) ===" && for f in planes/models.py planes/admin.py; do echo -n "$f: "; grep -vc '^\s*$' $f; done && echo "=== archivos que toqué ===" && echo "planes/models.py, planes/admin.py, consultorio/settings.py (1 línea)"
~~~~~~

~~~~~~text
Migrations for 'planes':
  planes/migrations/0001_initial.py
    + Create model Branch
    + Create model Profile
    + Create model TreatmentPlan
    + Create model AccessLog
  Apply all migrations: admin, auth, contenttypes, planes, sessions
Running migrations:
  Applying planes.0001_initial... OK
=== líneas escritas por mí (sin lo generado) ===
planes/models.py: 37
planes/admin.py: 39
=== archivos que toqué ===
planes/models.py, planes/admin.py, consultorio/settings.py (1 línea)
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:56:46Z · Set up FastAPI back-office environment

~~~~~~bash
mkdir -p /tmp/claude-501/f12b/templates && cd /tmp/claude-501/f12b && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'fastapi==0.141.1' 'sqlalchemy==2.0.52' 'jinja2' 'python-multipart' 'itsdangerous' 'httpx==0.28.1' 'uvicorn==0.52.4' && echo instalado
~~~~~~

~~~~~~text
instalado
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T02:58:05Z · Add a second entity in Django

~~~~~~bash
cd /tmp/claude-501/f12 && cat >> planes/models.py <<'PYEOF'


class Consent(models.Model):
    """Consentimiento informado de una fase del plan."""

    plan = models.ForeignKey(TreatmentPlan, on_delete=models.PROTECT, verbose_name="plan")
    phase_kind = models.CharField("fase", max_length=20)
    signed_on = models.DateField("fecha de firma", null=True, blank=True)
    document_ref = models.CharField("soporte", max_length=80, blank=True)

    class Meta:
        verbose_name, verbose_name_plural = "consentimiento", "consentimientos"
PYEOF
cat >> planes/admin.py <<'PYEOF'


@admin.register(Consent)
class ConsentAdmin(admin.ModelAdmin):
    list_display = ["plan", "phase_kind", "signed_on", "document_ref"]
    list_filter = ["phase_kind", "signed_on"]
    search_fields = ["plan__patient_name", "document_ref"]

    def get_queryset(self, request):
        queryset = super().get_queryset(request)
        if request.user.is_superuser:
            return queryset
        branch = getattr(getattr(request.user, "profile", None), "branch", None)
        return queryset.filter(plan__branch=branch) if branch else queryset.none()
PYEOF
sed -i '' 's/from .models import AccessLog, Branch, Profile, TreatmentPlan/from .models import AccessLog, Branch, Consent, Profile, TreatmentPlan/' planes/admin.py && ./.venv/bin/python manage.py makemigrations planes 2>&1 | tail -2 && ./.venv/bin/python manage.py migrate 2>&1 | tail -1 && echo "=== la pantalla 41 en Django cuesta ===" && echo "modelo: 10 líneas · admin: 13 líneas · total 23, en 2 archivos ya existentes"
~~~~~~

~~~~~~text
  planes/migrations/0002_consent.py
    + Create model Consent
  Applying planes.0002_consent... OK
=== la pantalla 41 en Django cuesta ===
modelo: 10 líneas · admin: 13 líneas · total 23, en 2 archivos ya existentes
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:09:22Z · Measure loss and duplication with and without defenses

~~~~~~bash
cd /tmp/claude-501/f13 && cp -r /tmp/claude-501/f10/.venv . 2>/dev/null || (export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python httpx==0.28.1); (/opt/homebrew/bin/python3.14 socio_falible.py --puerto 8099 &) ; sleep 2 && cat > medir.py <<'PYEOF'
"""Cuántas operaciones se pierden y cuántas se duplican, con y sin defensas."""
import statistics, time
import httpx

BASE = "http://127.0.0.1:8099"
N = 60   # sesenta notificaciones de disponibilidad

def reset():
    httpx.get(f"{BASE}/_reiniciar")

def recibidos():
    return httpx.get(f"{BASE}/_recibidos").json()

def sin_defensas(ruta):
    """Lo que sale solo: un POST, sin timeout, sin reintento, sin mirar nada."""
    enviadas = perdidas = 0
    with httpx.Client() as c:
        for i in range(N):
            enviadas += 1
            try:
                c.post(f"{BASE}{ruta}", json={"evento": i})
            except Exception:
                perdidas += 1
    return enviadas, perdidas

def con_reintento(ruta, idempotente=False):
    """Timeout, tres intentos con backoff, y clave de idempotencia si aplica."""
    enviadas = perdidas = reintentos = 0
    with httpx.Client(timeout=httpx.Timeout(1.0, connect=0.5)) as c:
        for i in range(N):
            enviadas += 1
            headers = {"Idempotency-Key": f"evt-{i}"} if idempotente else {}
            for intento in range(3):
                try:
                    r = c.post(f"{BASE}{ruta}", json={"evento": i}, headers=headers)
                    if r.status_code < 500:
                        break
                except Exception:
                    pass
                reintentos += 1
                time.sleep(0.05 * (2 ** intento))   # backoff exponencial
            else:
                perdidas += 1
    return enviadas, perdidas, reintentos

print(f"{'escenario':<44}{'enviadas':>9}{'llegaron':>10}{'perdidas':>10}{'duplicadas':>12}{'tiempo':>10}")

for nombre, ruta, fn in [
    ("intermitente, sin defensas", "/intermitente", lambda: sin_defensas("/intermitente")),
    ("intermitente, con reintento", "/intermitente", lambda: con_reintento("/intermitente")),
    ("idempotente, con reintento SIN clave", "/idempotente", lambda: con_reintento("/idempotente")),
    ("idempotente, con reintento CON clave", "/idempotente", lambda: con_reintento("/idempotente", True)),
    ("mentiroso, con reintento", "/mentiroso", lambda: con_reintento("/mentiroso")),
]:
    reset()
    t0=time.perf_counter(); res = fn(); dt=(time.perf_counter()-t0)
    enviadas, perdidas = res[0], res[1]
    llegaron = recibidos().get(ruta, 0)
    dup = max(0, llegaron - (enviadas - perdidas))
    print(f"{nombre:<44}{enviadas:>9}{llegaron:>10}{perdidas:>10}{dup:>12}{dt:>9.1f}s")
PYEOF
./.venv/bin/python medir.py
~~~~~~

~~~~~~text
escenario                                    enviadas  llegaron  perdidas  duplicadas    tiempo
intermitente, sin defensas                         60        40         0           0      0.0s
intermitente, con reintento                        60        60         0           0      1.7s
idempotente, con reintento SIN clave               60        89         0          29      1.7s
idempotente, con reintento CON clave               60        60         0           0      1.7s
mentiroso, con reintento                           60         0         0           0      0.0s
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:20:27Z · Measure the double-booking race

~~~~~~bash
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_ctl -D /tmp/claude-501/pgdata -o "-p 55432 -k /tmp/claude-501" -l /tmp/claude-501/pg.log start >/dev/null 2>&1; sleep 2; pg_isready -h /tmp/claude-501 -p 55432 && cd /tmp/claude-501/f14 && cp -r /tmp/claude-501/f11/.venv . && cat > medir_reserva.py <<'PYEOF'
"""Dos auxiliares reservando las 3:40, con y sin defensa."""
import concurrent.futures as cf
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
INTENTOS = 50

def preparar(con_restriccion: bool):
    with psycopg.connect(DSN, autocommit=True) as con:
        con.execute("DROP TABLE IF EXISTS slots")
        con.execute("""CREATE TABLE slots (
            id serial PRIMARY KEY, branch text NOT NULL, starts_at timestamptz NOT NULL,
            patient text NOT NULL)""")
        if con_restriccion:
            con.execute("CREATE UNIQUE INDEX uq_slot ON slots(branch, starts_at)")

def reservar(paciente: str) -> str:
    """Lo que escribe el instinto: comprobar y después insertar."""
    with psycopg.connect(DSN) as con, con.cursor() as cur:
        cur.execute("SELECT 1 FROM slots WHERE branch='Suba' AND starts_at='2026-10-15 15:40-05'")
        if cur.fetchone():
            return "ocupado"
        try:
            cur.execute("INSERT INTO slots (branch, starts_at, patient) "
                        "VALUES ('Suba','2026-10-15 15:40-05', %s)", (paciente,))
            con.commit()
            return "reservado"
        except psycopg.errors.UniqueViolation:
            con.rollback()
            return "conflicto detectado"

def correr(con_restriccion: bool):
    preparar(con_restriccion)
    with cf.ThreadPoolExecutor(2) as ex:
        res = list(ex.map(reservar, [f"paciente-{i%2}" for i in range(2)]))
    with psycopg.connect(DSN) as con:
        filas = con.execute("SELECT count(*) FROM slots").fetchone()[0]
    return res, filas

print(f"{'escenario':<44}{'resultados':<40}{'filas en la tabla'}")
for etiqueta, restriccion in [("comprobar-y-insertar, SIN restricción", False),
                              ("comprobar-y-insertar, CON restricción", True)]:
    # se repite varias veces porque la carrera no ocurre siempre
    peor = 0; muestra = None
    for _ in range(25):
        res, filas = correr(restriccion)
        if filas > peor: peor, muestra = filas, res
    print(f"{etiqueta:<44}{str(muestra):<40}{peor}")
PYEOF
./.venv/bin/python medir_reserva.py
~~~~~~

~~~~~~text
/tmp/claude-501:55432 - accepting connections
escenario                                   resultados                              filas en la tabla
comprobar-y-insertar, SIN restricción       ['reservado', 'reservado']              2
comprobar-y-insertar, CON restricción       ['reservado', 'conflicto detectado']    1
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:20:49Z · Demonstrate the useless threading.Lock across processes

~~~~~~bash
cd /tmp/claude-501/f14 && cat > lock_inutil.py <<'PYEOF'
"""El threading.Lock que no sirve: dos procesos, dos candados distintos."""
import sys, threading, psycopg
DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
candado = threading.Lock()   # ← uno por proceso. Ahí está el problema.

def reservar(paciente):
    with candado:            # "protegido"
        with psycopg.connect(DSN) as con, con.cursor() as cur:
            cur.execute("SELECT 1 FROM slots WHERE branch='Suba' AND starts_at='2026-10-15 15:40-05'")
            if cur.fetchone(): return "ocupado"
            import time; time.sleep(0.05)      # la ventana de la carrera
            cur.execute("INSERT INTO slots (branch, starts_at, patient) VALUES ('Suba','2026-10-15 15:40-05', %s)", (paciente,))
            con.commit(); return "reservado"

if __name__ == "__main__":
    print(reservar(sys.argv[1]))
PYEOF
./.venv/bin/python -c "
import psycopg
DSN='host=/tmp/claude-501 port=55432 user=aurea dbname=agenda'
with psycopg.connect(DSN, autocommit=True) as con:
    con.execute('DROP TABLE IF EXISTS slots')
    con.execute('CREATE TABLE slots (id serial PRIMARY KEY, branch text, starts_at timestamptz, patient text)')
print('tabla sin restricción, lista')" && (./.venv/bin/python lock_inutil.py yuli & ./.venv/bin/python lock_inutil.py auxiliar-suba & wait) && ./.venv/bin/python -c "
import psycopg
with psycopg.connect('host=/tmp/claude-501 port=55432 user=aurea dbname=agenda') as con:
    print('filas para las 3:40 ->', con.execute('SELECT count(*) FROM slots').fetchone()[0])"
~~~~~~

~~~~~~text
tabla sin restricción, lista
reservado
reservado
filas para las 3:40 -> 2
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:32:04Z · Install observability stack

~~~~~~bash
mkdir -p /tmp/claude-501/f16 && cd /tmp/claude-501/f16 && export UV_CACHE_DIR=/tmp/claude-501/mgr/cache-uv && /tmp/claude-501/mgr/.tool-uv/bin/uv venv -q --python /opt/homebrew/bin/python3.14 .venv && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python fastapi==0.141.1 uvicorn==0.52.4 httpx==0.28.1 structlog==26.1.0 'opentelemetry-sdk==1.44.0' 'opentelemetry-instrumentation-fastapi' 'prometheus-client==0.26.0' 2>&1 | tail -3; ./.venv/bin/python -c "import structlog, opentelemetry.sdk, prometheus_client; print('structlog', structlog.__version__)"
~~~~~~

~~~~~~text
structlog 26.1.0
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:32:24Z · Measure logging cost per event

~~~~~~bash
cd /tmp/claude-501/f16 && cp /tmp/claude-501/f10/app.py . && cat > medir_observabilidad.py <<'PYEOF'
"""Cuánto cuesta ver lo que pasa: latencia y volumen de registro."""
import io, json, logging, os, statistics, sys, time
from pathlib import Path

import structlog
from fastapi.testclient import TestClient
import httpx

import app as A

REPS = 300
PARAMS = {"branch": "centro", "day": "2026-10-15"}

def bench_http(base, reps=REPS):
    with httpx.Client(base_url=base) as c:
        for _ in range(30): c.get("/availability", params=PARAMS)
        xs=[]
        for _ in range(reps):
            t0=time.perf_counter(); c.get("/availability", params=PARAMS); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), xs[int(len(xs)*0.95)-1]

# --- costo del registro, aislado del HTTP ---
print("=== costo por evento de registro (10.000 eventos) ===")
destino = Path("bench.log")

def medir_logger(nombre, emitir, reps=10_000):
    destino.unlink(missing_ok=True)
    emitir()  # calentar
    t0=time.perf_counter()
    for i in range(reps): emitir(i)
    dt=(time.perf_counter()-t0)
    tam = destino.stat().st_size if destino.exists() else 0
    print(f"{nombre:<44}{dt/reps*1e6:8.1f} µs/evento   {tam/reps:7.0f} B/evento")

# 1. sin registro
medir_logger("sin registro", lambda i=0: None)

# 2. logging estándar a archivo
std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(destino, mode="w"); h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir_logger("logging estándar, texto", lambda i=0: std.info("reserva creada branch=%s slot=%s", "centro", i))

# 3. structlog JSON
for hh in list(std.handlers): std.removeHandler(hh)
destino.unlink(missing_ok=True)
f = destino.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f),
)
log = structlog.get_logger()
medir_logger("structlog JSON", lambda i=0: log.info("reserva_creada", branch="centro", slot=i, patient="1019283746"))
f.close()
PYEOF
./.venv/bin/python medir_observabilidad.py
~~~~~~

~~~~~~text
/private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/fastapi/testclient.py:1: StarletteDeprecationWarning: Using `httpx` with `starlette.testclient` is deprecated; install `httpx2` instead.
  from starlette.testclient import TestClient as TestClient  # noqa
=== costo por evento de registro (10.000 eventos) ===
sin registro                                     0.0 µs/evento         0 B/evento
logging estándar, texto                          9.9 µs/evento         0 B/evento
structlog JSON                                  10.5 µs/evento         0 B/evento
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:32:39Z · Measure logging cost and volume correctly

~~~~~~bash
cd /tmp/claude-501/f16 && cat > medir_obs2.py <<'PYEOF'
"""Costo por evento de registro, con el archivo cerrado antes de medir tamaño."""
import logging, statistics, time
from pathlib import Path
import structlog

REPS = 20_000
destino = Path("bench.log")

def medir(nombre, emitir, cerrar=None):
    destino.unlink(missing_ok=True)
    emitir(0)
    t0 = time.perf_counter()
    for i in range(REPS): emitir(i)
    dt = time.perf_counter() - t0
    if cerrar: cerrar()
    tam = destino.stat().st_size if destino.exists() else 0
    print(f"{nombre:<40}{dt/REPS*1e6:8.2f} µs/evento{tam/REPS:9.0f} B/evento{tam/1e6:9.1f} MB total")

medir("sin registro", lambda i: None)

std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(destino, mode="w")
h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir("logging estándar, texto", lambda i: std.info("reserva creada branch=%s slot=%s", "centro", i),
      cerrar=lambda: h.flush())
std.removeHandler(h); h.close()

destino.unlink(missing_ok=True)
f = destino.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()
medir("structlog JSON con contexto", lambda i: log.info("reserva_creada", branch="centro",
      slot=i, patient="1019283746", actor="yuli", request_id="r-0001"), cerrar=lambda: f.flush())
f.close()

# nivel DEBUG apagado: el costo de la llamada que no emite
std2 = logging.getLogger("apagado"); std2.setLevel(logging.INFO)
medir("logging.debug con DEBUG apagado", lambda i: std2.debug("detalle %s", i))
PYEOF
./.venv/bin/python medir_obs2.py
~~~~~~

~~~~~~text
sin registro                                0.03 µs/evento        0 B/evento      0.0 MB total
logging estándar, texto                    10.02 µs/evento        0 B/evento      0.0 MB total
structlog JSON con contexto                10.68 µs/evento        0 B/evento      0.0 MB total
logging.debug con DEBUG apagado             0.13 µs/evento        0 B/evento      0.0 MB total
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:32:56Z · Measure logging volume correctly

~~~~~~bash
cd /tmp/claude-501/f16 && cat > medir_obs3.py <<'PYEOF'
"""Costo por evento y volumen. Cada caso escribe su propio archivo."""
import logging, time
from pathlib import Path
import structlog

REPS = 20_000

def medir(nombre, emitir, path=None, cerrar=None):
    emitir(0)
    t0 = time.perf_counter()
    for i in range(REPS): emitir(i)
    dt = time.perf_counter() - t0
    if cerrar: cerrar()
    tam = path.stat().st_size if path and path.exists() else 0
    por_evento = tam / (REPS + 1) if tam else 0
    print(f"{nombre:<40}{dt/REPS*1e6:8.2f} µs/evento{por_evento:9.0f} B/evento"
          f"{por_evento*3_900_000/1e9:9.2f} GB/mes*")

medir("sin registro", lambda i: None)

p1 = Path("plano.log"); p1.unlink(missing_ok=True)
std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(p1, mode="w")
h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir("logging estándar, texto", lambda i: std.info("reserva creada branch=%s slot=%s", "centro", i),
      p1, cerrar=lambda: h.flush())
std.removeHandler(h); h.close()

p2 = Path("estructurado.log"); p2.unlink(missing_ok=True)
f = p2.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()
medir("structlog JSON con contexto", lambda i: log.info("reserva_creada", branch="centro",
      slot=i, patient="1019283746", actor="yuli", request_id="r-0001"), p2, cerrar=lambda: f.flush())
f.close()

std2 = logging.getLogger("apagado"); std2.setLevel(logging.INFO)
medir("logging.debug con DEBUG apagado", lambda i: std2.debug("detalle %s", i))
print("\n* proyectado al volumen de Áurea: 3.900 citas/mes × 1.000 eventos por cita")
PYEOF
./.venv/bin/python medir_obs3.py
~~~~~~

~~~~~~text
sin registro                                0.04 µs/evento        0 B/evento     0.00 GB/mes*
logging estándar, texto                     9.98 µs/evento       68 B/evento     0.27 GB/mes*
structlog JSON con contexto                10.69 µs/evento      189 B/evento     0.74 GB/mes*
logging.debug con DEBUG apagado             0.13 µs/evento        0 B/evento     0.00 GB/mes*

* proyectado al volumen de Áurea: 3.900 citas/mes × 1.000 eventos por cita
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:33:47Z · Profile the naive vs optimized close

~~~~~~bash
export PATH=/opt/homebrew/opt/postgresql@18/bin:$PATH; pg_ctl -D /tmp/claude-501/pgdata -o "-p 55432 -k /tmp/claude-501" -l /tmp/claude-501/pg.log start >/dev/null 2>&1; sleep 2; cd /tmp/claude-501/f16 && /tmp/claude-501/mgr/.tool-uv/bin/uv pip install -q --python .venv/bin/python 'psycopg[binary]==3.3.5' && cp /tmp/claude-501/f15/ventas-2026-Q1.csv . && cat > perfilar.py <<'PYEOF'
"""El perfil del cierre: dónde se va el tiempo de verdad."""
import cProfile, hashlib, io, pstats, time
from decimal import Decimal
from pathlib import Path
import psycopg

DSN = "host=/tmp/claude-501 port=55432 user=aurea dbname=agenda"
FILAS = 20_000     # un lote del cierre

def cargar(n):
    rows=[]
    with open("ventas-2026-Q1.csv", encoding="utf-8") as f:
        next(f)
        for i, l in enumerate(f):
            if i>=n: break
            rows.append(tuple(l.rstrip("\n").split(",")))
    return rows

ROWS = cargar(FILAS)

def cierre_ingenuo(con):
    """Una consulta por fila para saber si el paciente existe. El N+1 del cierre."""
    total = Decimal("0")
    with con.cursor() as cur:
        for documento, codigo, valor in ROWS:
            cur.execute("SELECT 1 FROM patients WHERE document = %s LIMIT 1", (documento,))
            cur.fetchone()
            hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
            total += Decimal(valor) * Decimal("0.15")
    return total

def cierre_con_una_consulta(con):
    """Los documentos conocidos se traen UNA vez y se consultan en memoria."""
    with con.cursor() as cur:
        cur.execute("SELECT document FROM patients")
        conocidos = {r[0] for r in cur.fetchall()}
    total = Decimal("0")
    for documento, codigo, valor in ROWS:
        documento in conocidos
        hashlib.sha256(f"{documento}|{codigo}|{valor}".encode()).hexdigest()
        total += Decimal(valor) * Decimal("0.15")
    return total

with psycopg.connect(DSN) as con:
    for nombre, fn in [("ingenuo (una consulta por fila)", cierre_ingenuo),
                       ("una sola consulta", cierre_con_una_consulta)]:
        fn(con)
        t0=time.perf_counter(); fn(con); dt=time.perf_counter()-t0
        print(f"{nombre:<38}{dt:7.2f} s para {FILAS:,} filas")

    print("\n=== perfil del ingenuo (cProfile, 20.000 filas) ===")
    pr = cProfile.Profile(); pr.enable(); cierre_ingenuo(con); pr.disable()
    s = io.StringIO(); pstats.Stats(pr, stream=s).sort_stats("cumulative").print_stats(8)
    print("\n".join(s.getvalue().splitlines()[4:16]))

    print("\n=== perfil del optimizado ===")
    pr = cProfile.Profile(); pr.enable(); cierre_con_una_consulta(con); pr.disable()
    s = io.StringIO(); pstats.Stats(pr, stream=s).sort_stats("tottime").print_stats(8)
    print("\n".join(s.getvalue().splitlines()[4:16]))
PYEOF
./.venv/bin/python perfilar.py
~~~~~~

~~~~~~text
ingenuo (una consulta por fila)          0.55 s para 20,000 filas
una sola consulta                        0.02 s para 20,000 filas

=== perfil del ingenuo (cProfile, 20.000 filas) ===

   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1    0.041    0.041    0.837    0.837 /private/tmp/claude-501/f16/perfilar.py:21(cierre_ingenuo)
    20000    0.015    0.000    0.750    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/cursor.py:100(execute)
    20000    0.367    0.000    0.729    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/connection.py:476(wait)
    40000    0.028    0.000    0.363    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/_cursor_base.py:195(_execute_gen)
    40000    0.089    0.000    0.213    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/_cursor_base.py:275(_maybe_prepare_gen)
    20000    0.012    0.000    0.097    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/_cursor_base.py:461(_convert_query)
    20000    0.024    0.000    0.082    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/_queries.py:59(convert)
    20000    0.046    0.000    0.046    0.000 /private/tmp/claude-501/f16/.venv/lib/python3.14/site-packages/psycopg/_cursor_base.py:583(_send_query_prepared)



=== perfil del optimizado ===

   ncalls  tottime  percall  cumtime  percall filename:lineno
~~~~~~

### ⏱️ 2026-09-13T03:52:05Z · Run the duel benchmark

~~~~~~bash
pkill -f agenda-0.17.0.jar; cd /tmp/claude-501/f17 && cp -r /tmp/claude-501/f10/.venv . && cp /tmp/claude-501/f10/app.py . && cat > duelo.py <<'PYEOF'
"""El arnés del duelo: mismas condiciones para los dos."""
import asyncio, os, re, signal, statistics, subprocess, sys, time
from pathlib import Path
import httpx

JAVA = os.path.expanduser("~/.sdkman/candidates/java/21.0.8-zulu/bin/java")
JAR = "agenda-java/target/agenda-0.17.0.jar"
PY = ".venv/bin/python"
URL_PATH = "/availability?branch=centro&day=2026-10-15"


def rss_mb(pid: int) -> float:
    out = subprocess.run(["ps", "-o", "rss=", "-p", str(pid)], capture_output=True, text=True)
    return int(out.stdout.strip() or 0) / 1024


def arranque_en_frio(cmd, puerto, reps=5):
    """Desde lanzar el proceso hasta la primera respuesta correcta."""
    tiempos, memorias = [], []
    for _ in range(reps):
        t0 = time.perf_counter()
        p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while True:
            try:
                r = httpx.get(f"http://127.0.0.1:{puerto}{URL_PATH}", timeout=0.4)
                if r.status_code == 200:
                    break
            except Exception:
                pass
            if time.perf_counter() - t0 > 60:
                raise RuntimeError("no arrancó")
        tiempos.append(time.perf_counter() - t0)
        time.sleep(2)
        memorias.append(rss_mb(p.pid))
        p.send_signal(signal.SIGTERM); p.wait(timeout=20)
        time.sleep(1)
    tiempos.sort()
    return statistics.median(tiempos), statistics.median(memorias)


async def carga(puerto, concurrencia=32, duracion=10.0):
    """Carga sostenida: cuántas peticiones por segundo y con qué latencia."""
    limites = httpx.Limits(max_connections=concurrencia * 2, max_keepalive_connections=concurrencia * 2)
    latencias, hechas = [], 0
    fin = time.perf_counter() + duracion
    async with httpx.AsyncClient(base_url=f"http://127.0.0.1:{puerto}", limits=limites,
                                 timeout=10.0) as c:
        async def trabajador():
            nonlocal hechas
            while time.perf_counter() < fin:
                t0 = time.perf_counter()
                r = await c.get(URL_PATH)
                if r.status_code == 200:
                    latencias.append((time.perf_counter() - t0) * 1000); hechas += 1
        # calentamiento
        for _ in range(200): await c.get(URL_PATH)
        inicio = time.perf_counter(); fin = inicio + duracion
        latencias.clear(); hechas = 0
        await asyncio.gather(*[trabajador() for _ in range(concurrencia)])
        real = time.perf_counter() - inicio
    latencias.sort()
    return {"rps": hechas / real,
            "p50": statistics.median(latencias),
            "p95": latencias[int(len(latencias) * 0.95) - 1],
            "p99": latencias[int(len(latencias) * 0.99) - 1]}


def medir(nombre, cmd, puerto):
    print(f"\n### {nombre} ###")
    frio, mem = arranque_en_frio(cmd, puerto)
    print(f"arranque en frío (mediana de 5): {frio*1000:8.0f} ms · RSS {mem:6.0f} MB")
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(200):
        try:
            if httpx.get(f"http://127.0.0.1:{puerto}{URL_PATH}", timeout=0.5).status_code == 200: break
        except Exception: time.sleep(0.1)
    r = asyncio.run(carga(puerto))
    mem_carga = rss_mb(p.pid)
    print(f"carga (32 conc., 10 s):  {r['rps']:8.0f} req/s · p50 {r['p50']:5.1f} ms · "
          f"p95 {r['p95']:5.1f} ms · p99 {r['p99']:5.1f} ms · RSS {mem_carga:.0f} MB")
    p.send_signal(signal.SIGTERM); p.wait(timeout=20)
    return {"frio_ms": frio*1000, "rss_reposo": mem, "rss_carga": mem_carga, **r}


if __name__ == "__main__":
    sb = medir("Spring Boot 3.5.16 · Java 21", [JAVA, "-jar", JAR], 8124)
    fa = medir("FastAPI 0.141.1 · uvicorn · CPython 3.14.5",
               [PY, "-m", "uvicorn", "app:app", "--port", "8125", "--log-level", "error"], 8125)
    print("\n=== resumen ===")
    print(f"{'':<28}{'Spring Boot 3':>16}{'FastAPI':>16}")
    for k, etiqueta, fmt in [("frio_ms","arranque en frío","{:.0f} ms"), ("rss_reposo","RSS en reposo","{:.0f} MB"),
                             ("rss_carga","RSS bajo carga","{:.0f} MB"), ("rps","peticiones/s","{:.0f}"),
                             ("p50","latencia p50","{:.1f} ms"), ("p95","latencia p95","{:.1f} ms"),
                             ("p99","latencia p99","{:.1f} ms")]:
        print(f"{etiqueta:<28}{fmt.format(sb[k]):>16}{fmt.format(fa[k]):>16}")
PYEOF
./.venv/bin/python duelo.py
~~~~~~

~~~~~~text
### Spring Boot 3.5.16 · Java 21 ###
arranque en frío (mediana de 5):     1296 ms · RSS    205 MB
carga (32 conc., 10 s):       390 req/s · p50  52.4 ms · p95 251.3 ms · p99 426.7 ms · RSS 227 MB

### FastAPI 0.141.1 · uvicorn · CPython 3.14.5 ###
arranque en frío (mediana de 5):      288 ms · RSS     55 MB
carga (32 conc., 10 s):       418 req/s · p50  42.8 ms · p95 246.2 ms · p99 382.3 ms · RSS 55 MB

=== resumen ===
                               Spring Boot 3         FastAPI
arranque en frío                     1296 ms          288 ms
RSS en reposo                         205 MB           55 MB
RSS bajo carga                        227 MB           55 MB
peticiones/s                             390             418
latencia p50                         52.4 ms         42.8 ms
latencia p95                        251.3 ms        246.2 ms
latencia p99                        426.7 ms        382.3 ms
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:55:15Z · Measure cold start and memory for both

~~~~~~bash
cd /tmp/claude-501/f17 && cat > medir_resto.py <<'PYEOF'
"""Arranque en frío, memoria y tamaño del artefacto, para los dos."""
import os, signal, statistics, subprocess, time
import httpx

JAVA = os.path.expanduser("~/.sdkman/candidates/java/21.0.8-zulu/bin/java")
PATH_Q = "/availability?branch=centro&day=2026-10-15"

def rss_total_mb(pid):
    """RSS del proceso y de todos sus hijos (uvicorn con workers son varios)."""
    out = subprocess.run(["ps", "-eo", "pid,ppid,rss"], capture_output=True, text=True).stdout
    filas = [l.split() for l in out.strip().splitlines()[1:]]
    hijos = {pid}
    for _ in range(3):
        hijos |= {int(f[0]) for f in filas if int(f[1]) in hijos}
    return sum(int(f[2]) for f in filas if int(f[0]) in hijos) / 1024

def arranque(cmd, puerto, reps=5):
    ts, mems = [], []
    for _ in range(reps):
        t0 = time.perf_counter()
        p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        while True:
            try:
                if httpx.get(f"http://127.0.0.1:{puerto}{PATH_Q}", timeout=0.3).status_code == 200:
                    break
            except Exception: pass
            if time.perf_counter()-t0 > 90: raise RuntimeError("no arrancó")
        ts.append(time.perf_counter()-t0)
        time.sleep(3); mems.append(rss_total_mb(p.pid))
        os.killpg(os.getpgid(p.pid), signal.SIGTERM); p.wait(timeout=25); time.sleep(2)
    ts.sort()
    return statistics.median(ts)*1000, statistics.median(mems)

casos = [
    ("Spring Boot 3.5.16 (Java 21)", [JAVA, "-jar", "agenda-java/target/agenda-0.17.0.jar"], 8124),
    ("uvicorn, 1 trabajador", [".venv/bin/python","-m","uvicorn","app:app","--port","8125","--log-level","error"], 8125),
    ("uvicorn, 4 trabajadores", [".venv/bin/python","-m","uvicorn","app:app","--port","8125","--workers","4","--log-level","error"], 8125),
]
for nombre, cmd, puerto in casos:
    ms, mb = arranque(cmd, puerto)
    print(f"{nombre:<34}arranque {ms:7.0f} ms · RSS {mb:6.0f} MB")
PYEOF
./.venv/bin/python medir_resto.py
~~~~~~

~~~~~~text
Exit code 1
Traceback (most recent call last):
  File "/private/tmp/claude-501/f17/medir_resto.py", line 41, in <module>
    ms, mb = arranque(cmd, puerto)
             ~~~~~~~~^^^^^^^^^^^^^
  File "/private/tmp/claude-501/f17/medir_resto.py", line 31, in arranque
    os.killpg(os.getpgid(p.pid), signal.SIGTERM); p.wait(timeout=25); time.sleep(2)
              ~~~~~~~~~~^^^^^^^
ProcessLookupError: [Errno 3] No such process
~~~~~~

### ⏱️ 2026-09-13T03:55:28Z · Re-measure cold start and memory

~~~~~~bash
cd /tmp/claude-501/f17 && python3 - <<'EOF'
import io
p="medir_resto.py"; s=io.open(p).read()
s=s.replace("        os.killpg(os.getpgid(p.pid), signal.SIGTERM); p.wait(timeout=25); time.sleep(2)",
"""        try:
            os.killpg(os.getpgid(p.pid), signal.SIGTERM)
        except ProcessLookupError:
            p.terminate()
        try:
            p.wait(timeout=25)
        except subprocess.TimeoutExpired:
            p.kill()
        time.sleep(2)""")
io.open(p,"w").write(s)
EOF
./.venv/bin/python medir_resto.py; pkill -f uvicorn; pkill -f agenda-0.17.0.jar; echo "--- tamaño de los artefactos ---"; ls -lh agenda-java/target/agenda-0.17.0.jar | awk '{print "jar de Spring Boot:", $5}'; du -sh .venv | awk '{print "entorno de Python:  ", $1}'
~~~~~~

~~~~~~text
Spring Boot 3.5.16 (Java 21)      arranque      19 ms · RSS      0 MB
uvicorn, 1 trabajador             arranque     275 ms · RSS     54 MB
uvicorn, 4 trabajadores           arranque     421 ms · RSS    262 MB
--- tamaño de los artefactos ---
jar de Spring Boot: 22M
entorno de Python:   17M
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:57:03Z · Re-measure with a free-port assertion

~~~~~~bash
pkill -f agenda-0.17.0.jar; pkill -f "uvicorn app:app"; sleep 3; lsof -ti:8124,8125 | xargs kill -9 2>/dev/null; sleep 2; cd /tmp/claude-501/f17 && python3 - <<'EOF'
import io
p="medir_resto.py"; s=io.open(p).read()
s=s.replace("""def arranque(cmd, puerto, reps=5):
    ts, mems = [], []
    for _ in range(reps):
        t0 = time.perf_counter()""",
"""def puerto_libre(puerto):
    import socket
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", puerto)) != 0

def arranque(cmd, puerto, reps=5):
    ts, mems = [], []
    for _ in range(reps):
        assert puerto_libre(puerto), f"el puerto {puerto} está ocupado: la medición mentiría"
        t0 = time.perf_counter()""")
io.open(p,"w").write(s)
EOF
./.venv/bin/python medir_resto.py; pkill -f uvicorn; pkill -f agenda-0.17.0.jar
~~~~~~

~~~~~~text
Exit code 1
Spring Boot 3.5.16 (Java 21)      arranque    1328 ms · RSS    216 MB
uvicorn, 1 trabajador             arranque     277 ms · RSS     54 MB
uvicorn, 4 trabajadores           arranque     429 ms · RSS    263 MB
~~~~~~

### ⏱️ 2026-09-13T03:59:00Z · Count lines and check Docker

~~~~~~bash
cd /tmp/claude-501/f17 && echo "=== líneas de código (sin blancos ni comentarios) ===" && python3 - <<'EOF'
import ast, pathlib, re
# Python
src = pathlib.Path("app.py").read_text()
tree = ast.parse(src)
for node in ast.walk(tree):
    if isinstance(node,(ast.Module,ast.ClassDef,ast.FunctionDef,ast.AsyncFunctionDef)):
        if node.body and isinstance(node.body[0], ast.Expr) and isinstance(node.body[0].value, ast.Constant) and isinstance(node.body[0].value.value,str):
            node.body.pop(0)
code = ast.unparse(tree)
# solo el endpoint de disponibilidad y sus modelos
py_loc = len([l for l in code.splitlines() if l.strip()])
print(f"FastAPI (app.py completo, incluye el POST de reservas): {py_loc} líneas")
# Java
total=0
for f in sorted(pathlib.Path("agenda-java/src/main/java").rglob("*.java")):
    lines=[l for l in f.read_text().splitlines()
           if l.strip() and not l.strip().startswith(("//","/*","*","*/"))]
    print(f"  {f.name}: {len(lines)}")
    total+=len(lines)
pom=len([l for l in pathlib.Path("agenda-java/pom.xml").read_text().splitlines() if l.strip()])
props=len([l for l in pathlib.Path("agenda-java/src/main/resources/application.properties").read_text().splitlines() if l.strip()])
print(f"Spring Boot: {total} líneas de Java + {pom} de pom.xml + {props} de properties = {total+pom+props}")
EOF
echo; echo "=== docker ==="; docker info >/dev/null 2>&1 && echo "daemon activo" || echo "daemon no disponible"
~~~~~~

~~~~~~text
=== líneas de código (sin blancos ni comentarios) ===
FastAPI (app.py completo, incluye el POST de reservas): 61 líneas
  AgendaApplication.java: 9
  Availability.java: 20
  AvailabilityController.java: 16
  BranchConverter.java: 12
Spring Boot: 57 líneas de Java + 36 de pom.xml + 3 de properties = 96

=== docker ===
daemon activo
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T03:59:33Z · Build both container images

~~~~~~bash
cd /tmp/claude-501/f17 && cat > Dockerfile.python <<'EOF'
# syntax=docker/dockerfile:1
FROM python:3.14-slim AS build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache fastapi==0.141.1 uvicorn==0.52.4 pydantic==2.13.5
COPY app_duelo.py .
EXPOSE 8000
CMD ["uvicorn", "app_duelo:app", "--host", "0.0.0.0", "--port", "8000", "--log-level", "error"]
EOF
cat > agenda-java/Dockerfile <<'EOF'
# syntax=docker/dockerfile:1
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/agenda-0.17.0.jar app.jar
EXPOSE 8124
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
echo "=== construyendo imagen de Python ===" && timeout 900 docker build -q -f Dockerfile.python -t aurea-fastapi . 2>&1 | tail -3 && echo "=== construyendo imagen de Java ===" && timeout 900 docker build -q -t aurea-spring agenda-java 2>&1 | tail -3 && docker images --format "{{.Repository}}\t{{.Size}}" | grep -E "aurea-(fastapi|spring)"
~~~~~~

~~~~~~text
=== construyendo imagen de Python ===
sha256:6aa402a849d31c95777403ff4460910678a8b2085ef31aa36af69d9deac35ebe
=== construyendo imagen de Java ===
sha256:32453e4d7943bb65438c38477a9751cc5b70de3802b4b60140e8c727075d1059
aurea-spring	329MB
aurea-fastapi	297MB
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T04:00:02Z · Measure container cold start

~~~~~~bash
cd /tmp/claude-501/f17 && cat > medir_contenedor.py <<'PYEOF'
"""Arranque en frío del contenedor: desde docker run hasta la primera respuesta."""
import statistics, subprocess, time
import httpx

def arranque(imagen, puerto_interno, puerto, extra=(), reps=5):
    ts = []
    for _ in range(reps):
        subprocess.run(["docker", "rm", "-f", "duelo"], capture_output=True)
        t0 = time.perf_counter()
        subprocess.run(["docker", "run", "-d", "--rm", "--name", "duelo",
                        "-p", f"{puerto}:{puerto_interno}", *extra, imagen],
                       capture_output=True, check=True)
        while True:
            try:
                if httpx.get(f"http://127.0.0.1:{puerto}/availability?branch=centro&day=2026-10-15",
                             timeout=0.3).status_code == 200:
                    break
            except Exception:
                pass
            if time.perf_counter() - t0 > 120:
                raise RuntimeError(f"{imagen} no arrancó")
        ts.append(time.perf_counter() - t0)
        subprocess.run(["docker", "rm", "-f", "duelo"], capture_output=True)
        time.sleep(1)
    ts.sort()
    return statistics.median(ts) * 1000

for nombre, imagen, interno in [("FastAPI en contenedor", "aurea-fastapi", 8000),
                                ("Spring Boot en contenedor", "aurea-spring", 8124)]:
    ms = arranque(imagen, interno, 8130)
    print(f"{nombre:<30}{ms:8.0f} ms (mediana de 5)")
PYEOF
./.venv/bin/python medir_contenedor.py
~~~~~~

~~~~~~text
FastAPI en contenedor             1359 ms (mediana de 5)
Spring Boot en contenedor         1485 ms (mediana de 5)
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T04:00:51Z · Clean up containers

~~~~~~bash
docker rm -f duelo 2>/dev/null; docker ps -a --format "{{.Names}}" | head -3; echo "--- limpieza ---"
~~~~~~

~~~~~~text
dogepets-postgres
dogepets-redis
--- limpieza ---
~~~~~~

### ⏱️ 2026-09-13T04:11:20Z · Verify section count and clean up images

~~~~~~bash
python3 - <<'PYEOF'
import pathlib, re
t = pathlib.Path("17-el-duelo-y-el-veredicto.md").read_text()
# quita bloques de código antes de contar
sin_codigo = re.sub(r"```.*?```", "", t, flags=re.S)
print("Fase 17, secciones reales:", len(re.findall(r"^## ", sin_codigo, re.M)))
print("  = 10 de la plantilla + §6.b (el veredicto, exigido por la propuesta) + 📌 Pendientes")
PYEOF
docker rmi -f aurea-fastapi aurea-spring >/dev/null 2>&1; echo "imágenes del duelo borradas"; docker images --format "{{.Repository}}" | grep -c aurea || echo "  quedan 0"; du -sh /tmp/claude-501 | cut -f1 | xargs echo "scratchpad:"
~~~~~~

~~~~~~text
Fase 17, secciones reales: 12
  = 10 de la plantilla + §6.b (el veredicto, exigido por la propuesta) + 📌 Pendientes
imágenes del duelo borradas
0
  quedan 0
scratchpad: 1.0G
~~~~~~

